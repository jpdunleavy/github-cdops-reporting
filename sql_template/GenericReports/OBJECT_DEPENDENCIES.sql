--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset OBJECT_DEPENDENCIES:1 runOnChange:true stripComments:true
--labels: "OBJECT_DEPENDENCIES or GENERIC"

DROP TABLE IF EXISTS CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE;

CREATE TRANSIENT TABLE IF NOT EXISTS CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE (
	REFERENCED_DATABASE VARCHAR(16777216),
	REFERENCED_SCHEMA VARCHAR(16777216),
	REFERENCED_OBJECT_NAME VARCHAR(16777216),
	REFERENCED_OBJECT_ID NUMBER(38,0),
	REFERENCED_OBJECT_DOMAIN VARCHAR(16777216),
	REFERENCING_DATABASE VARCHAR(16777216),
	REFERENCING_SCHEMA VARCHAR(16777216),
	REFERENCING_OBJECT_NAME VARCHAR(16777216),
	REFERENCING_OBJECT_ID NUMBER(38,0),
	REFERENCING_OBJECT_DOMAIN VARCHAR(16777216),
	DEPENDENCY_TYPE VARCHAR(14)
);

--Override CDOPS Variables
--UPDATE CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES SET VAR_VALUE='USING CRON ,0 6 * * * UTC'
--WHERE
--ACCOUNT_LOCATOR=CURRENT_ACCOUNT() AND
--REGION_NAME=CURRENT_REGION() AND
--VAR_USAGE='TASK_CDOPS_OBJECT_DEPENDENCIES',
--VAR_NAME='TASK_SCHEDULE';


CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.REPORTING.SP_CDOPS_OBJECT_DEPENDENCIES()
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS '
    const swap_sql_command = `ALTER TABLE CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE SWAP WITH CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE_TMP`
    const my_sql_command = `
            CREATE OR REPLACE TRANSIENT TABLE CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE_TMP AS
            select
                T.ACCOUNT_LOCATOR AS ACCOUNT_LOCATOR
                ,CURRENT_REGION() AS REGION_NAME
                ,REFERENCED_DATABASE,REFERENCED_SCHEMA,REFERENCED_OBJECT_NAME
                ,REFERENCED_OBJECT_ID,REFERENCED_OBJECT_DOMAIN,REFERENCING_DATABASE,REFERENCING_SCHEMA
                ,REFERENCING_OBJECT_NAME,REFERENCING_OBJECT_ID,REFERENCING_OBJECT_DOMAIN,DEPENDENCY_TYPE
                ,T.VAR_VALUE AS ORGANIZATION_NAME
            from
                snowflake.account_usage.OBJECT_DEPENDENCIES D,
                table(CDOPS_STATESTORE.REPORTING.get_var(\'ORGANIZATION\',\'GLOBAL\',CURRENT_ACCOUNT(),CURRENT_REGION())) T
        `;

    try{
        snowflake.execute( {sqlText: my_sql_command} );
        snowflake.execute({sqlText: swap_sql_command} )
    }
    catch(err){
        const error = `Failed: Code: ${err.code}\\n  State: ${err.state}\\n  Message: ${err.message}\\n Stack Trace:\\n   ${err.stackTraceTxt}`;
        throw error;
    }
    return "Success- "+ swap_sql_command ;
  ';

SET TASK_SCHEDULE = (SELECT VAR_VALUE FROM table(CDOPS_STATESTORE.REPORTING.get_var('TASK_SCHEDULE','TASK_CDOPS_OBJECT_DEPENDENCIES',CURRENT_ACCOUNT(),CURRENT_REGION())));

CREATE OR REPLACE task CDOPS_STATESTORE.REPORTING.TASK_CDOPS_OBJECT_DEPENDENCIES
    WAREHOUSE = 'CDOPS_REPORT_SYSTEM_WH'
    SCHEDULE = $TASK_SCHEDULE
AS
    CALL CDOPS_STATESTORE.REPORTING.SP_CDOPS_OBJECT_DEPENDENCIES();

ALTER TASK CDOPS_STATESTORE.REPORTING.TASK_CDOPS_OBJECT_DEPENDENCIES RESUME;

CALL CDOPS_STATESTORE.REPORTING.SP_CDOPS_OBJECT_DEPENDENCIES();

CREATE OR REPLACE VIEW CDOPS_STATESTORE.REPORTING_EXT.EXT_VW_CDOPS_OBJECT_DEPENDENCIES AS
  SELECT
    *
        FROM CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE ;


-- rollback DROP TABLE IF EXISTS CDOPS_STATESTORE.REPORTING.CDOPS_OBJECT_DEPENDENCIES_TABLE;
-- rollback DROP TASK IF EXISTS  CDOPS_STATESTORE.REPORTING.TASK_CDOPS_OBJECT_DEPENDENCIES;
-- rollback DROP PROCEDURE IF EXISTS  CDOPS_STATESTORE.REPORTING.SP_CDOPS_OBJECT_DEPENDENCIES();
-- rollback DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING_EXT.EXT_VW_CDOPS_OBJECT_DEPENDENCIES;