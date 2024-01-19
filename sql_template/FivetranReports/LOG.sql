--liquibase formatted sql
--preconditions onFail:HALT onError:HALT

--changeset FIVETRAN_LOG:1 runOnChange:true stripComments:true
--labels: "FIVETRAN_LOG or GENERIC"

CREATE OR REPLACE VIEW   CDOPS_STATESTORE.REPORTING_EXT.VW_FIVETRAN_LOG as
SELECT *
  FROM FIVETRAN_TERRAFORM_LAB_DB.FIVETRAN_LOG.LOG;


-- rollback DROP VIEW IF EXISTS CDOPS_STATESTORE.REPORTING_EXT.VW_FIVETRAN_LOG;