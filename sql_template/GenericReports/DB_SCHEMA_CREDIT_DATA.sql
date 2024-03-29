--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset DATABASE_SCHEMA_USAGE_CREDITS:1 runOnChange:true stripComments:true
--labels: "DATABASE_SCHEMA_USAGE_CREDITS or GENERIC"

DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL;

CREATE OR REPLACE TRANSIENT TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE (
	ACCOUNT_LOCATOR VARCHAR(16777216),
	REGION_NAME VARCHAR(16777216),
    ORGANIZATION_NAME VARCHAR(16777216),
    NAME VARCHAR(16777216),
	CREDITS_USED NUMBER(38,9),
	DATABASE_NAME VARCHAR(16777216),
	SCHEMA_NAME VARCHAR(16777216),
	USAGE_DATE DATE,
	PCT_CREDIT_USED_BY_QUERY NUMBER(38,6),
	CREDIT_USED_BY_QUERY NUMBER(38,12)
);

ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_CREDIT SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.CALL_SP_SNOWFLAKE_USAGE_MONTH_CREDITS_QUERYCNT SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_LOAD_USAGE_MONTH_CREDITS_QUERYCNT SUSPEND;

CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL()
  returns string not null
  language javascript
  as
  '
    const sql_begin_trans = snowflake.createStatement({ sqlText:`BEGIN TRANSACTION;`});
    const sql_commit_trans = snowflake.createStatement({ sqlText:`COMMIT;`});
    try{
      sql_begin_trans.execute();
      const my_sql_command_1  = `CREATE OR REPLACE TRANSIENT TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE_TEMP AS
                                 SELECT
                                    T.ACCOUNT_LOCATOR AS ACCOUNT_LOCATOR
                                    ,CURRENT_REGION() AS REGION_NAME
                                    ,T.VAR_VALUE AS ORGANIZATION_NAME
                                    ,WH.WAREHOUSE_NAME NAME
                                    ,WH.CREDITS_USED
                                    ,QH.DATABASE_NAME
                                    ,QH.SCHEMA_NAME
                                    ,DATE(QH.START_TIME) USAGE_DATE
                                    ,(QH.EXECUTION_TIME / SUM(IFF(QH.EXECUTION_TIME=0,1,QH.EXECUTION_TIME)) OVER (PARTITION BY WH.WAREHOUSE_NAME, WH.START_TIME, WH.END_TIME) ) * 100 AS PCT_CREDIT_USED_BY_QUERY
                                    ,((PCT_CREDIT_USED_BY_QUERY / 100) * WH.CREDITS_USED ) AS CREDIT_USED_BY_QUERY
                                 FROM
                                    CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WAREHOUSE_CREDIT_DATA_FL_TABLE WH,
                                    CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE QH,
                                    TABLE(get_var(\'ORGANIZATION\',\'GLOBAL\',CURRENT_ACCOUNT(),CURRENT_REGION())) T
                                 WHERE
                                    WH.WAREHOUSE_ID = QH.WAREHOUSE_ID AND QH.START_TIME BETWEEN WH.START_TIME AND WH.END_TIME
                                    AND QH.DATABASE_NAME IS NOT NULL AND QH.SCHEMA_NAME IS NOT NULL
                                    AND QH.START_TIME >= DATEADD(MONTH,-4,CURRENT_DATE);
                                 `

    var statement_1 = snowflake.createStatement( {sqlText: my_sql_command_1} );
    var result_set_1 = statement_1.execute();

    var my_sql_command_2 = " ALTER TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE SWAP WITH CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE_TEMP"

    var statement_2 = snowflake.createStatement( {sqlText: my_sql_command_2} );
    var result_set_2 = statement_2.execute();

    var my_sql_command_3 =   "DROP TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE_TEMP";

    var statement_3 = snowflake.createStatement( {sqlText: my_sql_command_3} );
    var result_set_3 = statement_3.execute();

    var my_sql_command = my_sql_command_1 + my_sql_command_2 + my_sql_command_3
    }
    catch(err){
        const error = `Failed: Code: ${err.code}\\n  State: ${err.state}\\n  Message: ${err.message}\\n Stack Trace:\\n   ${err.stackTraceTxt}`;
        throw error;
    }
    finally{
        sql_commit_trans.execute();
    }
    return "Success-"+ my_sql_command ;
  ';

CREATE OR REPLACE task CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL
    WAREHOUSE = ${TASK_WAREHOUSE}
    AFTER TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL
AS
    CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL();


CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL();

CREATE OR REPLACE VIEW CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL AS
  SELECT DISTINCT
    NAME,DATABASE_NAME,SCHEMA_NAME,USAGE_DATE,sum(credit_used_by_query)  as CREDIT_USED
  FROM TABLE(CDOPS_STATESTORE.REPORTING.RESOLVE_MEMBER_RESOURCE_MAPPING_UDF()) AS C, CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE WH
  WHERE
      (C.WAREHOUSE_PATTERN IS NOT NULL AND RLIKE(WH.NAME,C.WAREHOUSE_PATTERN) )
            AND (C.DATABASE_PATTERN IS NOT NULL AND RLIKE(WH.DATABASE_NAME,C.DATABASE_PATTERN))
  GROUP BY NAME,DATABASE_NAME,SCHEMA_NAME,USAGE_DATE;

--comment: Resume all dependent task tied to root task
SELECT system$task_dependents_enable('CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL');

-- rollback DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL;
-- rollback DROP TABLE "CDOPS_STATESTORE"."REPORTING"."VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE";
-- rollback DROP TASK IF EXISTS  CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL;
-- rollback DROP PROCEDURE IF EXISTS  CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL();
