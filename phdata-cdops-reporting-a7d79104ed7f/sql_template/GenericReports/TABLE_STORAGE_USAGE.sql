--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset TABLE_STORAGE_USAGE:1 runOnChange:true stripComments:true
--labels: "TABLE_STORAGE_USAGE or GENERIC"

DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL;

--Override CDOPS Variables
--UPDATE CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES SET VAR_VALUE='USING CRON 0 */3 * * * UTC'
--WHERE
--ACCOUNT_LOCATOR=CURRENT_ACCOUNT() AND
--REGION_NAME=CURRENT_REGION() AND
--VAR_USAGE='TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL',
--VAR_NAME='TASK_SCHEDULE';

ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL SUSPEND;

CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL()
returns string not null
language javascript
as
'
var my_sql_command = ""
var my_sql_command_1 = "CREATE OR REPLACE TRANSIENT TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL_TABLE AS " +
                        "select  "+
                            "T.ACCOUNT_LOCATOR AS ACCOUNT_LOCATOR " +
                            ",CURRENT_REGION() AS REGION_NAME " +
                            ", T.VAR_VALUE AS ORGANIZATION_NAME " +
                            ", TABLE_NAME " +
                            ", TABLE_SCHEMA AS SCHEMA " +
                            ", TABLE_CATALOG AS DATABASE_NAME " +
                            ", IS_TRANSIENT " +
                            ", (ACTIVE_BYTES / POWER(1024, 3) ) ACTIVE_BYTES_GB " +
                            ", (TIME_TRAVEL_BYTES / POWER(1024, 3)) TIME_TRAVEL_BYTES_GB " +
                            ", (FAILSAFE_BYTES / POWER(1024, 3) ) FAILSAFE_BYTES_GB " +
                            ", (RETAINED_FOR_CLONE_BYTES / POWER(1024, 3) ) RETAINED_FOR_CLONE_BYTES_GB " +
                            ", TABLE_CREATED " +
                            ", TABLE_DROPPED " +
                            ", TABLE_ENTERED_FAILSAFE " +
                            ", SCHEMA_CREATED " +
                            ", SCHEMA_DROPPED " +
                            ", CATALOG_CREATED " +
                            ", CATALOG_DROPPED " +
                        "from " +
                            "SNOWFLAKE.ACCOUNT_USAGE.TABLE_STORAGE_METRICS M, " +
                            "table(get_var(\'ORGANIZATION\',\'GLOBAL\',CURRENT_ACCOUNT(),CURRENT_REGION())) T ;"

var statement_1 = snowflake.createStatement( {sqlText: my_sql_command_1} );
var result_set_1 = statement_1.execute();

var my_sql_command = my_sql_command_1;

return my_sql_command; // Statement returned for info/debug purposes
';

SET TASK_SCHEDULE = (SELECT VAR_VALUE FROM table(get_var('TASK_SCHEDULE','TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL',CURRENT_ACCOUNT(),CURRENT_REGION())));

CREATE OR REPLACE task CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL
  WAREHOUSE = ${TASK_WAREHOUSE}
  SCHEDULE = $TASK_SCHEDULE
AS
  CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL();

ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL RESUME;

CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL();

CREATE OR REPLACE VIEW CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL AS
SELECT DISTINCT
SM.*, ACTIVE_BYTES_GB + TIME_TRAVEL_BYTES_GB + FAILSAFE_BYTES_GB + RETAINED_FOR_CLONE_BYTES_GB AS TOTAL_STORAGE_GB
      FROM TABLE(CDOPS_STATESTORE.REPORTING.RESOLVE_MEMBER_RESOURCE_MAPPING_UDF()) AS C, CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL_TABLE SM
WHERE
    RLIKE(SM.DATABASE_NAME,C.DATABASE_PATTERN)
 ORDER BY CATALOG_CREATED DESC;
-- rollback DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL;
-- rollback DROP TABLE "CDOPS_STATESTORE"."REPORTING"."VW_SNOWFLAKE_TABLE_STORAGE_USAGE_TABLE";
-- rollback DROP TASK IF EXISTS  CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL;
-- rollback DROP PROCEDURE IF EXISTS  CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL();
-- rollback DROP VIEW IF EXISTS  CDOPS_STATESTORE.REPORTING.VW_SNOWFALKE_TABLE_STORAGE_USAGE_FL;