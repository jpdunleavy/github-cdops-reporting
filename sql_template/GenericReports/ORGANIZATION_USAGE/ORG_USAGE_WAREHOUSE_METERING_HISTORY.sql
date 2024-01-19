--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset ORG_USAGE_WAREHOUSE_METERING_HISTORY:1 runOnChange:true stripComments:true
--labels: "ORG_USAGE_WAREHOUSE_METERING_HISTORY or GENERIC"


create TRANSIENT TABLE IF NOT EXISTS CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE (
	SH_KEY BINARY(20),
	ORGANIZATION_NAME VARCHAR(16777216),
	ACCOUNT_LOCATOR VARCHAR(16777216),
	REGION VARCHAR(16777216),
    ACCOUNT_NAME VARCHAR(16777216),
	SERVICE_TYPE VARCHAR(25),
    START_TIME TIMESTAMP_LTZ(9),
    END_TIME TIMESTAMP_LTZ(9),
    WAREHOUSE_ID NUMBER(38,0),
    WAREHOUSE_NAME VARCHAR(16777216),
    CREDITS_USED NUMBER(38,9),
    CREDITS_USED_COMPUTE NUMBER(38,9),
    CREDITS_USED_CLOUD_SERVICES NUMBER(38,9)
);


ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY SUSPEND;

CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY()
  returns string not null
  language javascript
  as
  '
    const sql_begin_trans = snowflake.createStatement({ sqlText:`BEGIN TRANSACTION;`});
    const sql_commit_trans = snowflake.createStatement({ sqlText:`COMMIT;`});

    const sql_temp_table = snowflake.createStatement({ sqlText:
    `
    CREATE OR REPLACE TEMPORARY TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE_TEMP AS
        SELECT
         sha1_binary( concat(
                                  \'|\', ifnull( organization_name, \'~\' )
                                  ,\'|\', ifnull( account_name, \'~\' )
                                  ,\'|\', ifnull( account_locator, \'~\' )
                                  ,\'|\', ifnull( warehouse_id, -9 )
                      )
                     )   SH_KEY,
                              ORGANIZATION_NAME,ACCOUNT_NAME,ACCOUNT_LOCATOR,REGION,
                                 START_TIME,END_TIME,WAREHOUSE_ID,WAREHOUSE_NAME,CREDITS_USED,CREDITS_USED_COMPUTE,CREDITS_USED_CLOUD_SERVICES,SERVICE_TYPE
                           from
                               (
                                 SELECT ORGANIZATION_NAME,ACCOUNT_NAME,ACCOUNT_LOCATOR,REGION,
                                 START_TIME,END_TIME,WAREHOUSE_ID,WAREHOUSE_NAME,CREDITS_USED,CREDITS_USED_COMPUTE,CREDITS_USED_CLOUD_SERVICES,SERVICE_TYPE
                                 FROM
                                 snowflake.organization_usage.WAREHOUSE_METERING_HISTORY
                                ) WMH
                           where
                    START_TIME >= (select NVL(MAX(START_TIME),(SELECT MIN(START_TIME)::DATE AS DATE FROM snowflake.organization_usage.WAREHOUSE_METERING_HISTORY)) from CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE);
    `
    });

    const sql_merge_table = snowflake.createStatement({ sqlText:
    `
        MERGE INTO CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE T USING CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE_TEMP S
        ON (T.SH_KEY = S.SH_KEY)
        WHEN NOT MATCHED THEN
        INSERT (SH_KEY,ORGANIZATION_NAME,ACCOUNT_NAME,ACCOUNT_LOCATOR,REGION,START_TIME,END_TIME,WAREHOUSE_ID,WAREHOUSE_NAME,CREDITS_USED,CREDITS_USED_COMPUTE,CREDITS_USED_CLOUD_SERVICES,SERVICE_TYPE)
        VALUES (S.SH_KEY,S.ORGANIZATION_NAME,S.ACCOUNT_NAME,S.ACCOUNT_LOCATOR,S.REGION,S.START_TIME,S.END_TIME,S.WAREHOUSE_ID,S.WAREHOUSE_NAME,S.CREDITS_USED,S.CREDITS_USED_COMPUTE,S.CREDITS_USED_CLOUD_SERVICES,S.SERVICE_TYPE);
    `
    });

    const sql_delete_table = snowflake.createStatement({ sqlText:
    `
        DELETE FROM CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE
        WHERE START_TIME <= (select dateadd(day,-var_value,current_date) from table(get_var(\'DAYS_TO_RETAIN\',\'VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE\',CURRENT_ACCOUNT(),CURRENT_REGION())))
        AND ACCOUNT_LOCATOR = CURRENT_ACCOUNT();
    `
    });

    try{
        sql_begin_trans.execute();
        sql_temp_table.execute();
        sql_merge_table.execute();
        sql_delete_table.execute();

    }
    catch(err){
   const error = `Failed: Code: ${err.code}\\n  State: ${err.state}\\n  Message: ${err.message}\\n Stack Trace:\\n   ${err.stackTraceTxt}`;
   throw error;
               }
    finally{
        sql_commit_trans.execute();
    }
    return "Success";
  ';


SET TASK_SCHEDULE = (SELECT VAR_VALUE FROM table(get_var('TASK_SCHEDULE','TASK_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY',CURRENT_ACCOUNT(),CURRENT_REGION())));

CREATE OR REPLACE task CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY
    WAREHOUSE = ${TASK_WAREHOUSE}
    SCHEDULE = $TASK_SCHEDULE
AS
    CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY();

ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY RESUME;

CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY();

DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING.TABLE_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY;

CREATE OR REPLACE VIEW CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY AS
  SELECT
      DISTINCT CCD.*,
      TO_DATE(CCD.START_TIME) START_DATE,
      IFF(COMPUTE.COMPUTE_RATE IS NOT NULL, CCD.CREDITS_USED*COMPUTE.COMPUTE_RATE, 0) CREDITS_USED_EFFECTIVE_RATE,
      IFF(COMPUTE.CLOUD_COMPUTE_RATE IS NOT NULL, CCD.CREDITS_USED_CLOUD_SERVICES*COMPUTE.CLOUD_COMPUTE_RATE, 0) CREDITS_USED_CLOUD_SERVICES_EFFECTIVE_RATE,
      IFF(COMPUTE.COMPUTE_RATE IS NOT NULL, CCD.CREDITS_USED_COMPUTE*COMPUTE.COMPUTE_RATE, 0) CREDITS_USED_COMPUTE_EFFECTIVE_RATE,
      COMPUTE.CURRENCY
  FROM
      CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE CCD
      LEFT OUTER JOIN
            (
              SELECT
                  COMPUTE.ACCOUNT_LOCATOR,
                  COMPUTE.REGION,
                  COMPUTE.RATE_DATE,
                  COMPUTE.CURRENCY,
                  COMPUTE.EFFECTIVE_RATE COMPUTE_RATE,
                  CLOUD.EFFECTIVE_RATE CLOUD_COMPUTE_RATE
              FROM
                  TABLE(CDOPS_STATESTORE.REPORTING.RATE_SHEET_TIMESERIES_ALL_ACCOUNTS('compute')) COMPUTE
                      JOIN
                  TABLE(CDOPS_STATESTORE.REPORTING.RATE_SHEET_TIMESERIES_ALL_ACCOUNTS('cloud services')) CLOUD
                      ON COMPUTE.RATE_DATE=CLOUD.RATE_DATE
            ) COMPUTE
        ON CCD.START_TIME::DATE = COMPUTE.RATE_DATE AND CCD.ACCOUNT_LOCATOR = COMPUTE.ACCOUNT_LOCATOR AND CCD.REGION = COMPUTE.REGION
  WHERE
    (
      select NVL(VALUE IS NOT NULL, FALSE) AS VALUE from table(flatten(input => parse_json(current_available_roles()))) WHERE VALUE='CDOPS_REPORT_SERVICE'
      )
  ORDER BY  ACCOUNT_LOCATOR, REGION, START_TIME;

-- rollback DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY;
-- rollback DROP TABLE "CDOPS_STATESTORE"."REPORTING"."VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE";
-- rollback DROP TASK IF EXISTS  CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY;
-- rollback DROP PROCEDURE IF EXISTS  CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY();