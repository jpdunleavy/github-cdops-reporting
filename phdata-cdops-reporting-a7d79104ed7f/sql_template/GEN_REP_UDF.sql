--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset UDF_GENERIC_REPORTS:1 runOnChange:true stripComments:true
--labels: UDF_GENERIC_REPORTS

create or replace TRANSIENT TABLE CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES
(
  ACCOUNT_LOCATOR VARCHAR2(255),
  REGION_NAME VARCHAR2(255),
  VAR_NAME VARCHAR2(255),
  VAR_VALUE VARCHAR2(255),
  VAR_USAGE VARCHAR2(255),
  VAR_DESCRIPTION VARCHAR2(2000),
  CONSTRAINT PKEY_1 PRIMARY KEY (ACCOUNT_LOCATOR,REGION_NAME,VAR_NAME,VAR_USAGE) NOT ENFORCED
);

INSERT OVERWRITE INTO CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES VALUES
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_AUTOMATIC_CLUSTERING_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_DATABASE_STORAGE_USAGE_MONTHLY_SUMMARY_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','30','VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_MATERIALIZED_VIEW_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_WAREHOUSE_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFALKE_PIPE_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_REPLICATION_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_STORAGE_USAGE_MONTHLY_SUMMARY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_QUERY_CREDIT_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_SESSIONS_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_COPY_HISTORY_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_READERACCOUNT_QUERY_HISTORY_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_READERACCOUNT_WAREHOUSE_CREDIT_DATA_FL_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','730','VW_SNOWFLAKE_ORG_USAGE_RATE_SHEET_DAILY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_TASK_HISTORY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_SEARCH_OPTIMIZATION_HISTORY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_SERVERLESS_TASK_HISTORY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','730','VW_SNOWFLAKE_ORG_USAGE_IN_CURRENCY_DAILY_TABLE','Delete data prior to value set'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'DAYS_TO_RETAIN','365','VW_FIVETRAN_CONNECTOR_TYPE_HISTORY_TABLE','Delete data prior to value set'),
    --GLOBAL VARIABLES
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'ACCOUNT_LOCATOR','${ACCOUNT_LOCATOR}','GLOBAL','ACCOUNT Name'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'ORGANIZATION','${ORGANIZATION}','GLOBAL','ORG Name'),
    --Task Schedule
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 6 * * * UTC','CDOPS_METADATA_GATHERING','Task schedule for Budget'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_SFT_CDOPS_METADATA_GATHERING','Task schedule for Budget'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','CALL_RESOURCE_MONITOR_STATUS_CAPTURE_PROCEDURE','Task schedule for Budget'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_AUTOMATIC_CLUSTERING_CREDIT_DATA_FL','Task schedule for automatic clustering'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_COPY_HISTORY_FL','Task schedule for copy history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_LOAD_HISTORY_FL','Task schedule for load history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_DATABASE_STORAGE_USAGE_MONTHLY_SUMMARY_FL','Task schedule for database storage credit usage history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 5 * * * UTC','TASK_VW_SNOWFLAKE_GRANT_TO_ROLES','Task schedule for grant to role history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_MATERIALIZED_VIEW_CREDIT_DATA_FL','Task schedule for materialized view credit history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFALKE_PIPE_CREDIT_DATA_FL','Task schedule for snowpipe credit history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 7 * * * UTC','TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL','Task schedule for query history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_ORG_USAGE_RATE_SHEET_DAILY','Task schedule for organization rate sheet'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_READERACCOUNT_QUERY_HISTORY_FL','Task schedule for Readeraccount Query History'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_READERACCOUNT_WAREHOUSE_CREDIT_DATA_FL','Task schedule for Readeraccount Warehouse Credit'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_REPLICATION_CREDIT_DATA_FL','Task schedule for Replication Credit'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_SEARCH_OPTIMIZATION_HISTORY','Task schedule for search optimization history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_SERVERLESS_TASK_HISTORY','Task schedule for serverless task'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_SESSIONS','Task schedule for session history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_STORAGE_USAGE_MONTHLY_SUMMARY','Task schedule for storage usage history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_TABLE_STORAGE_USAGE_FL','Task schedule for table storage usage history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_TASK_HISTORY','Task schedule for task history'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_WAREHOUSE_CREDIT_DATA_FL','Task schedule for warehouse'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_ORG_USAGE_WAREHOUSE_METERING_HISTORY','Task schedule for warehouse'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_MEMBER_RESOURCE_MAPPING','Task schedule for warehouse'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 6 * * * UTC','TASK_CDOPS_ACTIVE_RESOURCES','Task schedule for active resources'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 3 * * * UTC','TASK_VW_SNOWFLAKE_ORG_USAGE_IN_CURRENCY_DAILY','Task schedule for warehouse'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 6 * * * UTC','TASK_CDOPS_OBJECT_DEPENDENCIES','Task schedule for Object Dependency'),
    (CURRENT_ACCOUNT(),CURRENT_REGION(),'TASK_SCHEDULE','USING CRON 0 6 * * * UTC', 'TASK_VW_FIVETRAN_CONNECTOR_TYPE', 'Task schedule for Fivetran connector type');
;

create or replace  function CDOPS_STATESTORE.REPORTING.get_var(p_var_name varchar,p_tab_name varchar,p_account_locator varchar)
  returns table (var_value varchar, account_locator varchar)
  as
  $$
    select max(var_value),max(account_locator) from CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES
        where var_name = p_var_name and var_usage = p_tab_name and account_locator = p_account_locator
  $$
  ;

create or replace  function CDOPS_STATESTORE.REPORTING.get_var(p_var_name varchar,p_var_usage varchar,p_account_locator varchar, p_region_name varchar)
  returns table (account_locator varchar, region_name varchar, var_name varchar, var_value varchar, var_usage varchar, var_description varchar)
  as
  $$
    select ACCOUNT_LOCATOR,REGION_NAME,VAR_NAME,VAR_VALUE,VAR_USAGE,VAR_DESCRIPTION from CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES
        where var_name = p_var_name and var_usage = p_var_usage and account_locator = p_account_locator and region_name = p_region_name
  $$
  ;

create or replace secure function CDOPS_STATESTORE.REPORTING.RESOLVE_MEMBER_RESOURCE_MAPPING_UDF()
  returns table (DATABASE_PATTERN varchar, WAREHOUSE_PATTERN varchar)
  as '
WITH USER_ONLY AS (
    SELECT
      DATABASE AS DATABASE_PATTERN, WAREHOUSE AS WAREHOUSE_PATTERN, ACCOUNT
    FROM
      CDOPS_STATESTORE.REPORTING.MEMBER_RESOURCE_MAPPING
    WHERE
      ACCOUNT = CURRENT_USER() AND ROLE IS NULL
  ),
  ROLE_ONLY AS (
    SELECT
      DATABASE AS DATABASE_PATTERN, WAREHOUSE AS WAREHOUSE_PATTERN, ROLE
    FROM
      CDOPS_STATESTORE.REPORTING.MEMBER_RESOURCE_MAPPING
    WHERE
      ACCOUNT IS NULL AND ROLE IN (select value from table(flatten(input => parse_json(current_available_roles()))))

    UNION

    SELECT NULL AS DATABASE_PATTERN, NULL AS WAREHOUSE_PATTERN, \'DENY\' AS ROLE
  ),
  USER_COUNT AS (
    SELECT
        UC.USER_DEFINED_COUNT,
        IFF(UC.USER_DEFINED_COUNT>0, (SELECT ACCOUNT FROM USER_ONLY WHERE ACCOUNT = CURRENT_USER() LIMIT 1 ), NULL) ACCOUNT,
        IFF(UC.USER_DEFINED_COUNT>0, (SELECT DATABASE_PATTERN FROM USER_ONLY WHERE ACCOUNT = CURRENT_USER() LIMIT 1 ), NULL) DATABASE_PATTERN,
        IFF(UC.USER_DEFINED_COUNT>0, (SELECT WAREHOUSE_PATTERN FROM USER_ONLY WHERE ACCOUNT = CURRENT_USER() LIMIT 1 ), NULL) WAREHOUSE_PATTERN
    FROM (
        SELECT COUNT(*) AS USER_DEFINED_COUNT FROM USER_ONLY
    )UC
  ),
  CTE AS (
    SELECT DISTINCT
      IFF(
        UC.USER_DEFINED_COUNT>0,
        UC.DATABASE_PATTERN,
        R.DATABASE_PATTERN
      ) AS DATABASE_PATTERN,
      IFF(
        UC.USER_DEFINED_COUNT>0,
        UC.WAREHOUSE_PATTERN,
        R.WAREHOUSE_PATTERN
      ) AS WAREHOUSE_PATTERN
    FROM  USER_COUNT UC,  ROLE_ONLY R
  )
  SELECT * FROM CTE WHERE DATABASE_PATTERN IS NOT NULL AND WAREHOUSE_PATTERN IS NOT NULL
  ';

CREATE OR REPLACE FUNCTION CDOPS_STATESTORE.REPORTING.DATERANGE(startdate string, enddate string)
RETURNS string
LANGUAGE javascript
AS
'
    const dates = [];
        currentDate = Date.parse(STARTDATE);
        addDays = function(days) {
            const date = new Date(this.valueOf());
            date.setDate(date.getDate() + days);
            return date;
        },
        formatDate = function(date) {
            const d = new Date(date);
                month = \'\' + (d.getMonth() + 1);
                day = \'\' + d.getDate();
                year = d.getFullYear();
            if (month.length < 2) month = \'0\' + month;
            if (day.length < 2) day = \'0\' + day;
            return [year, month, day].join(\'-\');
        };
    while (currentDate <= Date.parse(ENDDATE)) {
        dates.push(formatDate(currentDate));
        currentDate = addDays.call(currentDate, 1);
    }
    return "[\'"+dates.join("\',\'")+"\']";
';

-- rollback DROP TABLE IF EXISTS CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES
-- rollback DROP FUNCTION IF EXISTS CDOPS_STATESTORE.REPORTING.get_var(var_value varchar);
-- rollback DROP FUNCTION IF EXISTS CDOPS_STATESTORE.REPORTING.RESOLVE_MEMBER_RESOURCE_MAPPING_UDF();
-- rollback DROP FUNCTION IF EXISTS CDOPS_STATESTORE.REPORTING.DATERANGE(string, string);

