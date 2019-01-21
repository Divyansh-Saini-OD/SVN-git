create or replace
PACKAGE BODY XX_CDH_SYNC_AOPS_ORCL_REP_PKG AS
   /*
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                					               |
-- +===================================================================+
-- | Name        :  XX_CDH_SYNC_AOPS_ORCL_REP_PKG.pks              |
-- | Description :  Package for XX_CDH_SYNC_AOPS_ORCL_REP_PKG      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==============================================|
-- |DRAFT 1a  16-Feb-2009 Yusuf Ali	        Initial draft version                          |
-- |          19-May-2009 Yusuf Ali         Changed status code to error when more than 1  |
-- |                                        rcs,role,grp found                             |
-- |          29-Mar-2012 Deepak V			When a ship-to is re-activated in AOPS, AOPS   |
-- |switches the sales-rep assigned to the sales-rep for primary-site. The SyncAOPS_RepID  |
-- |process updates the sales rep in the current assignment table. if a ship-to is already |
-- |assigned to a Sales-Rep, even if the site is inactive in CDH, and we get a trigger from|
-- |AOPS to switch the sales-rep, this should not be allowed.      (QC-16860)              |
-- | 1.2      7-Jun-2016  Shubashree R      QC38032 Removed schema references for R12.2 GSCC compliance|
-- +=======================================================================================+
*/

PROCEDURE syncRepID(    p_rep_id               IN       	VARCHAR2,
			p_party_osr            IN       	VARCHAR2,
			p_party_id             IN       	VARCHAR2,
			p_party_site_osr       IN       	VARCHAR2,
			p_party_site_id        IN       	VARCHAR2,
			p_account_os           IN       	VARCHAR2,
			p_action               IN       	VARCHAR2,
			x_return_status        OUT NOCOPY       VARCHAR2,
                        x_status_code          OUT NOCOPY       VARCHAR2,
			x_error_message	       OUT NOCOPY       VARCHAR2) IS
  

  lc_rep_id 		                VARCHAR(50);
  lc_derived_rep_id     		VARCHAR(50);
  ln_party_site_id	                NUMBER;
  ln_resource_id        		NUMBER;
  ln_role_id            		NUMBER;
  ln_group_id           		NUMBER;
  lc_error_code				VARCHAR(50);
  lc_error_message      		VARCHAR(2000);
  ln_assignment_count			NUMBER;
  lc_account_os                         VARCHAR(50);
  lc_account_id				NUMBER;
  ln_user_id                            NUMBER;
  
  ROW_NOT_UPDATED                       EXCEPTION;

  CURSOR l_derive_rep_id_cur IS
    SELECT SP_ID_NEW
    FROM xxtps_sp_mapping
    WHERE SP_ID_ORIG = lc_rep_id;
    
  CURSOR c_term_id ( p_dervied_rep_id VARCHAR) IS
    SELECT  rsc.resource_id, rol.role_id, grp.group_id
    FROM    jtf_rs_resource_extns_vl rsc,             
            jtf_rs_group_members     mem,
            jtf_rs_groups_vl         grp,
            jtf_rs_role_relations    rr,
            jtf_rs_roles_vl          rol
    where rsc.resource_id       = mem.resource_id   
    AND mem.group_id          = grp.group_id
    AND mem.group_member_id   = rr.role_resource_id
    AND rr.role_id            = rol.role_id
    AND rr.role_resource_type = 'RS_GROUP_MEMBER'
    AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)
    AND nvl(mem.delete_flag,'N') <> 'Y'
    AND nvl(rr.delete_flag,'N')  <> 'Y'
    AND rr.attribute15        = NVL(p_dervied_rep_id,p_rep_id)
    AND rr.end_date_active    is not null
    AND rr.end_date_active    <= trunc(sysdate)
    order by rr.end_date_active desc, rr.last_update_date desc, rr.role_relate_id desc;


  BEGIN
  
    SAVEPOINT SYNC_REP_ID;
  
    x_return_status := 'S';
    lc_rep_id       := p_rep_id;
    ln_party_site_id := p_party_site_id;
    lc_account_os := p_account_os;
 
    --Derive Oracle id from AOPS rep ID
    
    OPEN l_derive_rep_id_cur;
    FETCH l_derive_rep_id_cur INTO lc_derived_rep_id;
    CLOSE l_derive_rep_id_cur;
    
    BEGIN
    
	    SELECT        rsc.resource_id, rol.role_id, grp.group_id 
            INTO          ln_resource_id, ln_role_id, ln_group_id
	    FROM  
		jtf_rs_resource_extns_vl rsc,             
		jtf_rs_group_members     mem,             
		jtf_rs_groups_vl         grp,             
		jtf_rs_role_relations    rr,             
		jtf_rs_roles_vl          rol       
		where rsc.resource_id      = mem.resource_id        
		AND mem.group_id          = grp.group_id        
		AND mem.group_member_id   = rr.role_resource_id        
		AND rr.role_id            = rol.role_id        
		AND rr.role_resource_type = 'RS_GROUP_MEMBER'        
		AND (rol.role_type_code   IN ('SALES', 'TELESALES') or rol.row_id is null)        
		AND nvl(mem.delete_flag,'N') <> 'Y'        
		AND nvl(rr.delete_flag,'N')  <> 'Y'        
		AND trunc(sysdate) between nvl(rsc.start_date_active, sysdate-1)                               
		AND nvl(rsc.end_date_active,   sysdate+1)        
		AND trunc(sysdate) between nvl(rr.start_date_active, sysdate-1)                               
		AND nvl(rr.end_date_active,   sysdate+1)        
		AND trunc(sysdate) between nvl(grp.start_date_active, sysdate-1)                               
		AND nvl(grp.end_date_active,   sysdate+1)        
		AND rr.attribute15 = NVL(lc_derived_rep_id,p_rep_id);
                
    
    EXCEPTION
	WHEN TOO_MANY_ROWS THEN
             ROLLBACK TO SYNC_REP_ID;
	     x_return_status := 'E';
             x_status_code   := 'ERROR';
             x_error_message := 'More than 1 combination of group, role, and resource record was found .  Rep ID for this exception is '|| 
			         NVL(lc_derived_rep_id,p_rep_id);
	     RETURN;
        WHEN NO_DATA_FOUND THEN             
             OPEN   c_term_id(lc_derived_rep_id);
             FETCH  c_term_id INTO ln_resource_id, ln_role_id, ln_group_id;
             
             IF c_term_id%NOTFOUND THEN
                ROLLBACK TO SYNC_REP_ID;
                x_return_status := 'E';
                x_status_code   := 'ERROR';
                x_error_message := 'Either resource, role, or group ID was not found.  Rep ID for this exception is ' || 
			         NVL(lc_derived_rep_id,p_rep_id);
                close c_term_id;
                RETURN;
             END IF;
                          
            close c_term_id;
         
    END; -- resource, role, group ID


    BEGIN

        SELECT count(*) INTO ln_assignment_count from 
          XX_TM_NAM_TERR_DEFN         TERR,        
          XX_TM_NAM_TERR_ENTITY_DTLS  TERR_ENT,        
          XX_TM_NAM_TERR_RSC_DTLS TERR_RSC     
	WHERE   entity_type ='PARTY_SITE'  
          and TERR.NAMED_ACCT_TERR_ID = TERR_ENT.NAMED_ACCT_TERR_ID  
          AND TERR.NAMED_ACCT_TERR_ID = TERR_RSC.NAMED_ACCT_TERR_ID  
		  -- The below code is blocked to make sure that if a ship to is already assgined
		  -- it is not again picked up by AOPS Sync prog. for re-assignment if the ship to is being re-activated in AOPS. (QC-16860)
          --AND SYSDATE between NVL(TERR.START_DATE_ACTIVE,SYSDATE-1)  
          --and nvl(TERR.END_DATE_ACTIVE,SYSDATE+1)  
          --AND SYSDATE between NVL(TERR_ENT.START_DATE_ACTIVE,SYSDATE-1) 
          --and nvl(TERR_ENT.END_DATE_ACTIVE,SYSDATE+1)  
          --AND SYSDATE between NVL(TERR_RSC.START_DATE_ACTIVE,SYSDATE-1) 
          --and nvl(TERR_RSC.END_DATE_ACTIVE,SYSDATE+1)  
          --AND NVL(TERR.status,'A') = 'A' 
          --AND NVL(TERR_ENT.status,'A') = 'A' 
          --AND    NVL(TERR_RSC.status,'A') = 'A' 
          and 
          entity_id = ln_party_site_id
          AND    
          EXISTS (SELECT 1
                  FROM   jtf_rs_roles_b     JRLV,
                         jtf_rs_roles_b     JTRLV
                  WHERE JRLV.role_id        = ln_role_id
                  AND   JRLV.attribute15    = JTRLV.attribute15
                  AND   JTRLV.role_id  =  TERR_RSC.resource_role_id);

	    IF (ln_assignment_count > 0) THEN
                     ROLLBACK TO SYNC_REP_ID;
		     x_return_status := 'E';
                     x_status_code   := 'WARNING';
		     x_error_message := 'Existing assignment was found in Oracle for AOPS rep ID.  The Rep ID that could not be assigned is ' || 
					 NVL(lc_derived_rep_id,p_rep_id);
                                         
		     RETURN;

	    END IF;

    END;

   BEGIN
        
	XX_JTF_RS_NAMED_ACC_TERR_PUB.CREATE_TERRITORY(
                  P_API_VERSION_NUMBER => 1.0,
                  P_NAMED_ACCT_TERR_ID => NULL,
                  P_NAMED_ACCT_TERR_NAME => NULL,
                  P_NAMED_ACCT_TERR_DESC => NULL,
                  P_STATUS => 'A',
                  P_START_DATE_ACTIVE => NULL,
                  P_END_DATE_ACTIVE => NULL,
                  P_FULL_ACCESS_FLAG => NULL,
                  P_SOURCE_TERR_ID => NULL,
                  P_RESOURCE_ID => ln_resource_id,
                  P_ROLE_ID => ln_role_id,
                  P_GROUP_ID => ln_group_id,
                  P_ENTITY_TYPE => 'PARTY_SITE',
                  P_ENTITY_ID => ln_party_site_id,
                  P_SOURCE_ENTITY_ID => NULL,
                  P_SOURCE_SYSTEM => lc_account_os,
                  p_allow_inactive_resource => 'Y',
                  p_set_extracted_status => 'Y',
                  P_COMMIT => FALSE,
                  X_ERROR_CODE => lc_error_code,
                  X_ERROR_MESSAGE => lc_error_message
	  );  

	IF (lc_error_code != 'S') THEN
		ROLLBACK TO SYNC_REP_ID;
                x_return_status := 'E';
                x_status_code   := 'ERROR';
		x_error_message := 'Territory assignment not created.  Rep ID for this exception is ' || NVL(lc_derived_rep_id,p_rep_id) ||
					'.  The following error occurred: ' || lc_error_message;  
		RETURN;
	
		COMMIT;
                
		x_return_status := 'S';
                RETURN;
	
	END IF;
   EXCEPTION
    WHEN ROW_NOT_UPDATED THEN
        ROLLBACK TO SYNC_REP_ID;
        x_return_status := 'E';
        x_status_code   := 'ERROR';
        x_error_message := 'Territory Manager tables for 405 outbound interface not updated.  Rep ID for this exception is ' || NVL(lc_derived_rep_id,p_rep_id);
        RETURN;
   END;

  EXCEPTION
  WHEN others THEN
    ROLLBACK TO SYNC_REP_ID;
    x_return_status := 'E';
    x_status_code   := 'ERROR';
    x_error_message := SUBSTR(sqlerrm,   1,   200);
  END syncRepID;  -- end syncRepID stored procedure

END XX_CDH_SYNC_AOPS_ORCL_REP_PKG;  --end XX_CDH_SYNC_AOPS_ORCL_REP_PKG package
/

SHOW ERRORS;