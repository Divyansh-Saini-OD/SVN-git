-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE MATERIALIZED VIEW XXBI_CUST_SALES_REPS_FCT_MV
  REFRESH COMPLETE ON DEMAND
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XXBI_CUST_SALES_REPS_FCT_MV.vw                     |
-- | Description :  Customer Sales Rep Fact MV                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0       10-Mar-2009 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- +===================================================================+
AS
SELECT 
        psi.party_site_id,
        res.resource_id,
        res.user_id,
      	res.resource_name,
        rol.role_id,
      	rol.role_name,
        grp.group_id,
        grp.group_name
     from	
	apps.hz_party_sites psi,
     	apps.jtf_rs_roles_vl             jrr,
        apps.XX_TM_NAM_TERR_DEFN         TERR,
    	apps.XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,
    	apps.XX_TM_NAM_TERR_RSC_DTLS     TERR_RSC
    	,apps.jtf_rs_role_relations rrl
	,apps.jtf_rs_group_members mem 
	, apps.jtf_rs_resource_extns_vl res
	,apps.jtf_rs_roles_vl rol
	,apps.jtf_rs_groups_vl grp
     where 
	TERR_ENT.ENTITY_ID=psi.party_site_id
	and jrr.role_id= TERR_RSC.RESOURCE_ROLE_ID
        AND (nvl(jrr.role_type_code, 'SALES') IN ('SALES', 'TELESALES'))
	and entity_type ='PARTY_SITE'
	and 	TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID AND
   		TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID AND
   		SYSDATE between NVL(TERR.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR.END_DATE_ACTIVE,SYSDATE+1) AND
   		SYSDATE between NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1) AND
   		SYSDATE between NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) and nvl(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1) AND
   		NVL(TERR.status,'A') = 'A' AND
   		NVL(TERR_ENT.status,'A') = 'A' AND
   		NVL(TERR_RSC.status,'A') = 'A'
   	and  rrl.role_resource_type='RS_GROUP_MEMBER'
   	and rrl.role_id= TERR_RSC.RESOURCE_ROLE_ID
	and rrl.role_resource_id=mem.group_member_id
	and mem.resource_id=res.resource_id
	and mem.resource_id=TERR_RSC.RESOURCE_ID
	and grp.group_id=TERR_RSC.group_id
	and rrl.role_id=rol.role_id
	and rol.role_type_code='SALES'
	and grp.group_id=mem.group_id
	and nvl(mem.delete_flag,'N')<> 'Y'
	and nvl(rrl.delete_flag,'N')<> 'Y';
/
SHOW ERRORS;
EXIT;