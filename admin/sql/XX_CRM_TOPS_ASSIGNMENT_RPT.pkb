SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CRM_TOPS_ASSIGNMENT_RPT

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CRM_TOPS_ASSIGNMENT_RPT.pkb                     |
-- | Description :  CRM TOPS Assignments Report - To fetch assignment  |
-- |                differences with AS400 system                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  26-Jan-2008 Indra Varada       Initial draft version     |
-- |                                                                   | 
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

  PROCEDURE tops_assignment_rpt
   (   x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_db_link_name           IN  VARCHAR2,
       p_filter_group           IN  VARCHAR2
    ) AS
  
  TYPE aops_data_rec_type IS RECORD
  (
   AOPS_SALES_PERSON_ID   VARCHAR2(50),
   AOPS_SALES_PERSON_NAME VARCHAR2(50),
   AOPS_MANAGER_ID         VARCHAR2(50),
   SITE_REFERENCE         VARCHAR2(50)
  );
  aops_data_rec           aops_data_rec_type;
  TYPE aops_data_cur_tbl IS TABLE OF aops_data_rec%TYPE INDEX BY BINARY_INTEGER;
  TYPE aops_sales_data_type     IS REF CURSOR;
  aops_sales_data               aops_sales_data_type;
  
  aops_data_cur            aops_data_cur_tbl;
  ln_bulk_limit            NUMBER := 20000;
  l_access_id              VARCHAR2(30);
  l_party_site_id          VARCHAR2(30);
  l_orig_system_reference  VARCHAR2(30);
  l_source_number          VARCHAR2(30);
  l_resource_name          VARCHAR2(60);
  l_role_name              VARCHAR2(30);
  l_group_name             VARCHAR2(30);
  l_attribute15            VARCHAR2(30);
  l_start_date_active      DATE;
  l_end_date_active        DATE;
  l_attribute14            VARCHAR2(30);
  l_cur_query              VARCHAR2(2000);
  
  BEGIN
    l_cur_query := 'SELECT TRIM(SALES_PERSON_ID)  AOPS_SALES_PERSON_ID,
       TRIM(CCU030F_SALESPERSON_NAME) AOPS_SALES_PERSON_NAME,
       TRIM(CCU030F_MANAGER_ID) AOPS_MANAGER_ID,
       TRIM(SALES_DATA.SITE_REFERENCE) SITE_REFERENCE
  FROM 
  (SELECT CASE NVL(TRIM(F9.CCU009F_SALESPERSON_ID),''X'') 
       WHEN ''X'' THEN F7.CCU007F_SALESPERSON_ID
       ELSE F9.CCU009F_SALESPERSON_ID
       END SALES_PERSON_ID,
       TRIM(CCU009F_CUSTOMER_ID || ''-'' || lpad(CCU009F_ADDRESS_SEQ,5,0) || ''-A0'') SITE_REFERENCE
  FROM RACOONDTA.CCU009F@' || p_db_link_name || ' F9,
     RACOONDTA.CCU007F@' || p_db_link_name || ' F7
  WHERE F7.CCU007F_CUSTOMER_ID = F9.CCU009F_CUSTOMER_ID) SALES_DATA,
  RACOONDTA.CCU030F@' || p_db_link_name || ' F30
  WHERE SALES_DATA.SALES_PERSON_ID = F30.CCU030F_SALESPERSON_ID(+)';
  
  fnd_file.put_line (fnd_file.log,'Cursor Query Used: ' || l_cur_query);
  fnd_file.put_line (fnd_file.output,'TOPS_SITE_ID, TOPS_SITE_REFERENCE,TOPS_RESOURCE,TOPS_ROLE,TOPS_START_DATE,TOPS_END_DATE,TOPS_GROUP,TOPS_LEGACY_ID,AOPS_LEGACY_ID,AOPS_SALES_PERSON_NAME,AOPS_MANAGER');
  OPEN aops_sales_data FOR l_cur_query;
  LOOP
    FETCH aops_sales_data BULK COLLECT INTO aops_data_cur LIMIT ln_bulk_limit;
    
    IF aops_data_cur.COUNT = 0
    THEN
       EXIT;
    END IF; 

    FOR ln_counter IN aops_data_cur.FIRST .. aops_data_cur.LAST 
    LOOP
     BEGIN
       l_access_id              := NULL;
       l_party_site_id          := NULL;
       l_orig_system_reference  := NULL;
       l_source_number          := NULL;
       l_resource_name          := NULL;
       l_role_name              := NULL;
       l_group_name             := NULL;
       l_attribute15            := NULL;
       l_start_date_active      := NULL;
       l_end_date_active        := NULL;
       l_attribute14            := NULL;
      IF aops_data_cur(ln_counter).site_reference IS NOT NULL THEN
       SELECT TERR_ENT.NAMED_ACCT_TERR_ENTITY_ID,
      	ps.party_site_id,
      	ps.orig_system_reference,
      	res.source_number,
      	res.resource_name,
      	rol.role_name,
        grp.group_name,
      	rrl.attribute15 l_id,
      	rrl.start_date_active,
      	rrl.end_date_active,
      	jrr.attribute14
     INTO l_access_id , l_party_site_id, l_orig_system_reference, l_source_number
          ,l_resource_name, l_role_name, l_group_name, l_attribute15, l_start_date_active, l_end_date_active, l_attribute14
     from	
	apps.hz_party_sites ps,
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
	TERR_ENT.ENTITY_ID=ps.party_site_id
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
	and nvl(rrl.delete_flag,'N')<> 'Y'
        and ps.orig_system_reference = aops_data_cur(ln_counter).site_reference
        and rrl.attribute15 <> aops_data_cur(ln_counter).AOPS_SALES_PERSON_ID;
        
        IF p_filter_group IS NULL OR l_attribute14 NOT LIKE p_filter_group || '%' THEN
        
          fnd_file.put_line (fnd_file.output,'"' || l_party_site_id || '"' || ',' || '"' || l_orig_system_reference || '"' || ',' || '"' || l_resource_name || '"' || ',' || '"' || l_role_name || '"' || ',' 
                   || '"' || TO_CHAR(l_start_date_active,'DD-MON-YYYY HH24:MI:SS') || '"' || ',' || '"' || TO_CHAR(l_end_date_active,'DD-MON-YYYY HH24:MI:SS') || '"' || ','|| '"' || l_group_name || '"' || ',' || '"' || l_attribute15 || '"' || ',' 
                   || '"' || aops_data_cur(ln_counter).AOPS_SALES_PERSON_ID || '"' || ',' || '"' || aops_data_cur(ln_counter).AOPS_SALES_PERSON_NAME || '"' || ',' || '"' || aops_data_cur(ln_counter).AOPS_MANAGER_ID  || '"');
        
         END IF; 
        
       END IF; 
       EXCEPTION WHEN OTHERS THEN
         NULL;
       END;
       
      END LOOP;
    END LOOP;
  END tops_assignment_rpt;

END XX_CRM_TOPS_ASSIGNMENT_RPT;
/
SHOW ERRORS;