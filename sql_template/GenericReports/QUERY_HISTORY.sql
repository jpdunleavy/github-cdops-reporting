--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset QUERY_HISTORY:1 runOnChange:true stripComments:true
--labels: "QUERY_HISTORY or GENERIC"

DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL;

CREATE TRANSIENT TABLE IF NOT EXISTS CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE (
	SH_KEY BINARY(20) CONSTRAINT UKEY_1 UNIQUE,
	ACCOUNT_LOCATOR VARCHAR(16777216),
	REGION_NAME VARCHAR(16777216),
	QUERY_ID VARCHAR(16777216),
	QUERY_TEXT VARCHAR(16777216),
	DATABASE_ID NUMBER(38,0),
	DATABASE_NAME VARCHAR(16777216),
	SCHEMA_ID NUMBER(38,0),
	SCHEMA_NAME VARCHAR(16777216),
	QUERY_TYPE VARCHAR(16777216),
	SESSION_ID NUMBER(38,0),
	USER_NAME VARCHAR(16777216),
	ROLE_NAME VARCHAR(16777216),
	WAREHOUSE_ID NUMBER(38,0),
	WAREHOUSE_NAME VARCHAR(16777216),
	WAREHOUSE_SIZE VARCHAR(16777216),
	WAREHOUSE_TYPE VARCHAR(16777216),
	CLUSTER_NUMBER NUMBER(38,0),
	QUERY_TAG VARCHAR(16777216),
	EXECUTION_STATUS VARCHAR(16777216),
	ERROR_CODE VARCHAR(16777216),
	ERROR_MESSAGE VARCHAR(16777216),
	START_TIME TIMESTAMP_LTZ(6),
	END_TIME TIMESTAMP_LTZ(6),
	TOTAL_ELAPSED_TIME NUMBER(38,0),
	BYTES_SCANNED NUMBER(38,0),
	PERCENTAGE_SCANNED_FROM_CACHE FLOAT,
	BYTES_WRITTEN NUMBER(38,0),
	BYTES_WRITTEN_TO_RESULT NUMBER(38,0),
	BYTES_READ_FROM_RESULT NUMBER(38,0),
	ROWS_PRODUCED NUMBER(38,0),
	ROWS_INSERTED NUMBER(38,0),
	ROWS_UPDATED NUMBER(38,0),
	ROWS_DELETED NUMBER(38,0),
	ROWS_UNLOADED NUMBER(38,0),
	BYTES_DELETED NUMBER(38,0),
	PARTITIONS_SCANNED NUMBER(38,0),
	PARTITIONS_TOTAL NUMBER(38,0),
	BYTES_SPILLED_TO_LOCAL_STORAGE NUMBER(38,0),
	BYTES_SPILLED_TO_REMOTE_STORAGE NUMBER(38,0),
	BYTES_SENT_OVER_THE_NETWORK NUMBER(38,0),
	COMPILATION_TIME NUMBER(38,0),
	EXECUTION_TIME NUMBER(38,0),
	QUEUED_PROVISIONING_TIME NUMBER(38,0),
	QUEUED_REPAIR_TIME NUMBER(38,0),
	QUEUED_OVERLOAD_TIME NUMBER(38,0),
	TRANSACTION_BLOCKED_TIME NUMBER(38,0),
	OUTBOUND_DATA_TRANSFER_CLOUD VARCHAR(16777216),
	OUTBOUND_DATA_TRANSFER_REGION VARCHAR(16777216),
	OUTBOUND_DATA_TRANSFER_BYTES NUMBER(38,0),
	INBOUND_DATA_TRANSFER_CLOUD VARCHAR(16777216),
	INBOUND_DATA_TRANSFER_REGION VARCHAR(16777216),
	INBOUND_DATA_TRANSFER_BYTES NUMBER(38,0),
	LIST_EXTERNAL_FILES_TIME NUMBER(38,0),
	CREDITS_USED_CLOUD_SERVICES FLOAT,
	RELEASE_VERSION VARCHAR(16777216),
	EXTERNAL_FUNCTION_TOTAL_INVOCATIONS NUMBER(38,0),
	EXTERNAL_FUNCTION_TOTAL_SENT_ROWS NUMBER(38,0),
	EXTERNAL_FUNCTION_TOTAL_RECEIVED_ROWS NUMBER(38,0),
	EXTERNAL_FUNCTION_TOTAL_SENT_BYTES NUMBER(38,0),
	EXTERNAL_FUNCTION_TOTAL_RECEIVED_BYTES NUMBER(38,0),
	QUERY_LOAD_PERCENT NUMBER(38,0),
    ORGANIZATION_NAME  VARCHAR(16777216),
    CONSTRAINT PKEY_1 PRIMARY KEY (ACCOUNT_LOCATOR,REGION_NAME,QUERY_ID) NOT ENFORCED
);

--Override CDOPS Variables
--UPDATE CDOPS_STATESTORE.REPORTING.CDOPS_VARIABLES SET VAR_VALUE='USING CRON 0 7,16,22 * * * UTC'
--WHERE
--ACCOUNT_LOCATOR=CURRENT_ACCOUNT() AND
--REGION_NAME=CURRENT_REGION() AND
--VAR_USAGE='TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL',
--VAR_NAME='TASK_SCHEDULE';

ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_CREDIT SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_WH_DB_SCHEMA_CREDIT_DATA_FL SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.CALL_SP_SNOWFLAKE_USAGE_MONTH_CREDITS_QUERYCNT SUSPEND;
ALTER TASK IF EXISTS CDOPS_STATESTORE.REPORTING.TASK_LOAD_USAGE_MONTH_CREDITS_QUERYCNT SUSPEND;

CREATE OR REPLACE PROCEDURE CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_QUERY_HISTORY_FL()
  returns string not null
  language javascript
  as
  '
    const sql_begin_trans = snowflake.createStatement({ sqlText:`BEGIN TRANSACTION;`});
    const sql_commit_trans = snowflake.createStatement({ sqlText:`COMMIT;`});
    try{
      sql_begin_trans.execute();
    var my_sql_command_1 = "CREATE OR REPLACE TEMPORARY TABLE CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE_TEMP AS " +
                            "SELECT " +
                             "sha1_binary( concat( current_region(),\'|\', T.ACCOUNT_LOCATOR,\'|\', QH.query_id) ) SH_KEY, " +
                             "T.ACCOUNT_LOCATOR AS ACCOUNT_LOCATOR,CURRENT_REGION() AS REGION_NAME,QH.query_id," +
                             "QH.query_text,QH.database_id,QH.database_name,QH.schema_id,QH.schema_name, QH.query_type,QH.session_id,QH.user_name,QH.role_name, " +
                             "QH.warehouse_id,QH.warehouse_name,QH.warehouse_size,QH.warehouse_type,QH.cluster_number,QH.query_tag,QH.execution_status,QH.error_code,QH.error_message,QH.start_time,QH.end_time,QH.total_elapsed_time,QH.bytes_scanned, " +
                             "QH.percentage_scanned_from_cache,QH.bytes_written,QH.bytes_written_to_result,QH.bytes_read_from_result,QH.rows_produced,QH.rows_inserted,QH.rows_updated,QH.rows_deleted,QH.rows_unloaded,QH.bytes_deleted,QH.partitions_scanned," +
                             "QH.partitions_total,QH.bytes_spilled_to_local_storage,QH.bytes_spilled_to_remote_storage,QH.bytes_sent_over_the_network,QH.compilation_time,QH.execution_time,QH.queued_provisioning_time,\QH.queued_repair_time,QH.queued_overload_time, " +
                             "QH.transaction_blocked_time,QH.outbound_data_transfer_cloud,QH.outbound_data_transfer_region,QH.outbound_data_transfer_bytes,QH.inbound_data_transfer_cloud,QH.inbound_data_transfer_region,QH.inbound_data_transfer_bytes,QH.list_external_files_time, " +
                             "QH.credits_used_cloud_services,QH.release_version,QH.external_function_total_invocations,QH.external_function_total_sent_rows,QH.external_function_total_received_rows,QH.external_function_total_sent_bytes,QH.external_function_total_received_bytes,QH.query_load_percent, " +
                             "T.VAR_VALUE AS ORGANIZATION_NAME " +
                             "FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY QH " +
                             ", table(get_var(\'ORGANIZATION\',\'GLOBAL\',CURRENT_ACCOUNT(),CURRENT_REGION())) T " +
                             "WHERE QH.start_time >= (SELECT NVL(MAX(START_TIME),DATEADD(MONTH,-12,CURRENT_DATE)) FROM CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE);"

    var statement_1 = snowflake.createStatement( {sqlText: my_sql_command_1} );
   var result_set_1 = statement_1.execute();

    var my_sql_command_2 = "MERGE INTO CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE T USING CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE_TEMP S " +
                           "ON (T.SH_KEY = S.SH_KEY) " +
                           "WHEN NOT MATCHED THEN " +
                           "INSERT ( " +
                                   "SH_KEY,ACCOUNT_LOCATOR,REGION_NAME,QUERY_ID" +
                                  ",QUERY_TEXT,DATABASE_ID,DATABASE_NAME,SCHEMA_ID,SCHEMA_NAME,QUERY_TYPE,SESSION_ID,USER_NAME,ROLE_NAME,WAREHOUSE_ID,WAREHOUSE_NAME,WAREHOUSE_SIZE,WAREHOUSE_TYPE " +
                                  ",CLUSTER_NUMBER,QUERY_TAG,EXECUTION_STATUS,ERROR_CODE,ERROR_MESSAGE,START_TIME,END_TIME,TOTAL_ELAPSED_TIME,BYTES_SCANNED,PERCENTAGE_SCANNED_FROM_CACHE " +
                                  ",BYTES_WRITTEN,BYTES_WRITTEN_TO_RESULT,BYTES_READ_FROM_RESULT,ROWS_PRODUCED,ROWS_INSERTED,ROWS_UPDATED,ROWS_DELETED,ROWS_UNLOADED,BYTES_DELETED " +
                                  ",PARTITIONS_SCANNED,PARTITIONS_TOTAL,BYTES_SPILLED_TO_LOCAL_STORAGE,BYTES_SPILLED_TO_REMOTE_STORAGE,BYTES_SENT_OVER_THE_NETWORK,COMPILATION_TIME,EXECUTION_TIME " +
                                  ",QUEUED_PROVISIONING_TIME,QUEUED_REPAIR_TIME,QUEUED_OVERLOAD_TIME,TRANSACTION_BLOCKED_TIME,OUTBOUND_DATA_TRANSFER_CLOUD,OUTBOUND_DATA_TRANSFER_REGION,OUTBOUND_DATA_TRANSFER_BYTES " +
                                  ",INBOUND_DATA_TRANSFER_CLOUD,INBOUND_DATA_TRANSFER_REGION,INBOUND_DATA_TRANSFER_BYTES,LIST_EXTERNAL_FILES_TIME,CREDITS_USED_CLOUD_SERVICES,RELEASE_VERSION " +
                                  ",EXTERNAL_FUNCTION_TOTAL_INVOCATIONS,EXTERNAL_FUNCTION_TOTAL_SENT_ROWS,EXTERNAL_FUNCTION_TOTAL_RECEIVED_ROWS,EXTERNAL_FUNCTION_TOTAL_SENT_BYTES " +
                                  ",EXTERNAL_FUNCTION_TOTAL_RECEIVED_BYTES,QUERY_LOAD_PERCENT,ORGANIZATION_NAME " +
                                   ") " +
                           "VALUES ( " +
                                 "S.SH_KEY,S.ACCOUNT_LOCATOR,S.REGION_NAME,S.QUERY_ID" +
                                ",S.QUERY_TEXT,S.DATABASE_ID,S.DATABASE_NAME,S.SCHEMA_ID,S.SCHEMA_NAME,S.QUERY_TYPE,S.SESSION_ID,S.USER_NAME,S.ROLE_NAME,S.WAREHOUSE_ID,S.WAREHOUSE_NAME,S.WAREHOUSE_SIZE,S.WAREHOUSE_TYPE " +
                                ",S.CLUSTER_NUMBER,S.QUERY_TAG,S.EXECUTION_STATUS,S.ERROR_CODE,S.ERROR_MESSAGE,S.START_TIME,S.END_TIME,S.TOTAL_ELAPSED_TIME,S.BYTES_SCANNED,S.PERCENTAGE_SCANNED_FROM_CACHE " +
                                ",S.BYTES_WRITTEN,S.BYTES_WRITTEN_TO_RESULT,S.BYTES_READ_FROM_RESULT,S.ROWS_PRODUCED,S.ROWS_INSERTED,S.ROWS_UPDATED,S.ROWS_DELETED,S.ROWS_UNLOADED,S.BYTES_DELETED " +
                                ",S.PARTITIONS_SCANNED,S.PARTITIONS_TOTAL,S.BYTES_SPILLED_TO_LOCAL_STORAGE,S.BYTES_SPILLED_TO_REMOTE_STORAGE,S.BYTES_SENT_OVER_THE_NETWORK,S.COMPILATION_TIME,S.EXECUTION_TIME " +
                                ",S.QUEUED_PROVISIONING_TIME,S.QUEUED_REPAIR_TIME,S.QUEUED_OVERLOAD_TIME,S.TRANSACTION_BLOCKED_TIME,S.OUTBOUND_DATA_TRANSFER_CLOUD,S.OUTBOUND_DATA_TRANSFER_REGION,S.OUTBOUND_DATA_TRANSFER_BYTES " +
                                ",S.INBOUND_DATA_TRANSFER_CLOUD,S.INBOUND_DATA_TRANSFER_REGION,S.INBOUND_DATA_TRANSFER_BYTES,S.LIST_EXTERNAL_FILES_TIME,S.CREDITS_USED_CLOUD_SERVICES,S.RELEASE_VERSION " +
                                ",S.EXTERNAL_FUNCTION_TOTAL_INVOCATIONS,S.EXTERNAL_FUNCTION_TOTAL_SENT_ROWS,S.EXTERNAL_FUNCTION_TOTAL_RECEIVED_ROWS,S.EXTERNAL_FUNCTION_TOTAL_SENT_BYTES " +
                                ",S.EXTERNAL_FUNCTION_TOTAL_RECEIVED_BYTES,S.QUERY_LOAD_PERCENT,S.ORGANIZATION_NAME " +
                                ");"

    var statement_2 = snowflake.createStatement( {sqlText: my_sql_command_2} );
    var result_set_2 = statement_2.execute();

    var my_sql_command_3 = "DELETE FROM CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE " +
                           "WHERE START_TIME <= (select dateadd(day,-var_value,current_date) from table(get_var(\'DAYS_TO_RETAIN\',\'VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE\',CURRENT_ACCOUNT(),CURRENT_REGION()))) " +
                           "AND ACCOUNT_LOCATOR = CURRENT_ACCOUNT();"

    var statement_3 = snowflake.createStatement( {sqlText: my_sql_command_3} );
    var result_set_3 = statement_3.execute();

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

SET TASK_SCHEDULE = (SELECT VAR_VALUE FROM table(get_var('TASK_SCHEDULE','TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL',CURRENT_ACCOUNT(),CURRENT_REGION())));

CREATE OR REPLACE task CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL
    WAREHOUSE = ${TASK_WAREHOUSE}
    SCHEDULE = $TASK_SCHEDULE
AS
    CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_QUERY_HISTORY_FL();

CALL CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_QUERY_HISTORY_FL();

CREATE OR REPLACE VIEW CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_QUERY_HISTORY_FL AS
  SELECT DISTINCT
    QH.*,
    TO_DATE(QH.START_TIME) AS START_DATE,
    DATEDIFF(SECOND, START_TIME, END_TIME) AS ELAPSED_TIME_IN_SEC,
    floor(EXECUTION_TIME/1000) as EXECUTION_TIME_IN_SEC
        FROM TABLE(CDOPS_STATESTORE.REPORTING.RESOLVE_MEMBER_RESOURCE_MAPPING_UDF()) AS C, CDOPS_STATESTORE.REPORTING.VW_SNOWFLAKE_QUERY_HISTORY_FL_TABLE QH
  WHERE
         (C.WAREHOUSE_PATTERN IS NOT NULL AND RLIKE(QH.WAREHOUSE_NAME,C.WAREHOUSE_PATTERN)) OR
               (C.DATABASE_PATTERN IS NOT NULL AND RLIKE(QH.DATABASE_NAME,C.DATABASE_PATTERN))
  ORDER BY QH.START_TIME DESC
  LIMIT 1000000;

--comment: Resume all dependent task tied to root task
SELECT system$task_dependents_enable('CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL');

-- rollback DROP TABLE IF EXISTS "CDOPS_STATESTORE"."REPORTING"."VW_SNOWFLAKE_QUERY_HISTORY_TABLE";
-- rollback DROP TASK IF EXISTS  CDOPS_STATESTORE.REPORTING.TASK_VW_SNOWFLAKE_QUERY_HISTORY_FL;
-- rollback DROP PROCEDURE IF EXISTS  CDOPS_STATESTORE.REPORTING.SP_VW_SNOWFLAKE_QUERY_HISTORY_FL();
-- rollback DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING_EXT.EXTENDED_TABLE_VW_SNOWFLAKE_QUERY_HISTORY_FL;