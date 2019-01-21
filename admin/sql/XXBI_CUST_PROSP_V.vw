SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_ICUST_PROSP_V
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_ICUST_PROSP_V.vw                              |
-- | Description :  Inactive Customers and Prospects Fact              |
-- |                View to restrict data by sales Rep.                |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT fctmv.*,
       repsmv.user_id,
       repsmv.user_name,
       repsmv.resource_name,
       repsmv.role_name,
       repsmv.legacy_rep_id,
       repsmv.group_name,
       repsmv.source_number,
       repsmv.source_job_title,
       repsmv.mgr_resource_id,
       repsmv.mgr_role_id,
       repsmv.mgr_group_id,
       repsmv.mgr_legacy_rep_id,
       repsmv.mgr_user_id,
       repsmv.mgr_user_name,
       repsmv.mgr_resource_name,
       repsmv.mgr_source_number,
       repsmv.mgr_job_title,
       repsmv.mgr_role
FROM xxbi_customer_fct_mv fctmv, XXBI_SITE_CURR_ASSIGN_MV repsmv
WHERE repsmv.party_site_id = fctmv.party_site_id
AND repsmv.user_id = fnd_global.user_id
AND fctmv.customer_type IN ('I','P');

/
SHOW ERRORS;
EXIT;