SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_SFA_PERZ_GEN_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_SFA_PERZ_GEN_PKG                                               |
-- |                                                                                |
-- | Description:                                                                   |
-- |Subversion Info:
-- |$HeadURL$
-- |$Rev    : $
-- |$Date   : $
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============        =====================================|
-- |DRAFT 1A 26-MAR-2008 Sarah Maria Justina   Initial draft version                |
-- |1.0      09-APR-2008 Sarah Maria Justina   Baselined                            |
-- |1.1      09-APR-2008 Sarah Maria Justina   Removed dependency on XX_CN_UTIL_PKG |
-- |1.2      09-APR-2008 Sarah Maria Justina   Fixed Issue with Saved Search getting|
-- |                                           created for CRM resource who has     |
-- |                                           no Group assigned                    |
-- |1.3      09-APR-2008 Sarah Maria Justina   Dependency on HR to derive           |
-- |                                           salespeople for each DSM is now fixed|
-- |                                           to look at CRM setup alone.          |
-- |1.4      18-APR-2008 Sarah Maria Justina   Rolled back version 1.3 as we require|
-- |                                           the HR Dependency                    |
-- |1.5      11-JAN-2010 Annapoorani Rajaguru  Defect 2264 Adding Prospect/Customer |
-- |                                           Column to the search pages		|
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
   G_MODULE_NAME   CONSTANT VARCHAR2 (50)           := 'SFA';
   G_NOTIFY        CONSTANT VARCHAR2 (1)            := 'Y';
   G_ERROR_STATUS  CONSTANT VARCHAR2 (10)           := 'ACTIVE';
   G_MAJOR         CONSTANT VARCHAR2 (15)           := 'MAJOR';
   G_MINOR         CONSTANT VARCHAR2 (15)           := 'MINOR';
   G_PROG_TYPE     CONSTANT VARCHAR2(100)           := 'E1307H_SiteLevel_Attributes_(User_Personalizations)';   
   G_GRP_MBR_TYPE  CONSTANT VARCHAR2(24)            := 'RS_GROUP_MEMBER';
   G_ROLE_TYPE     CONSTANT VARCHAR2(24)            := 'SALES';
   G_NO            CONSTANT VARCHAR2 (1)            := 'N';
   G_YES           CONSTANT VARCHAR2 (1)            := 'Y';   
   G_MGR_TYPE      CONSTANT VARCHAR2 (8)            := 'DSM'; 
----------------------------
--Declaring Global Variables
----------------------------
   gn_failed_mgrs            NUMBER                 := 0;
   EX_MULTIPLE_GRPS_WITH_RES EXCEPTION;
   EX_CRM_FND_USER_UNSYNC    EXCEPTION;
----------------------------------------------
--Cursor to get the Direct Reports of the DSM
----------------------------------------------  
      CURSOR gcu_get_manager_directs(p_person_id IN NUMBER,p_group_id IN NUMBER) 
      IS
	   SELECT    f.resource_id
		   , f.resource_name 
	     FROM 	
	   (SELECT   PAAF.person_id        PERSON_ID
		   , level		  lvl
		   , r.resource_id
		   , r.resource_name
	      FROM   (SELECT *
		       FROM per_all_assignments_f p
		      WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PAAF
		   , (SELECT *
			FROM per_all_people_f p
		       WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PAPF
		   ,  per_person_types         PPT
		   , (SELECT *
		       FROM per_person_type_usages_f p
		      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
		   , jtf_rs_resource_extns_vl r
	     WHERE        PAAF.person_id               = PAPF.person_id
	       AND        PAPF.person_id               = PPTU.person_id
	       AND        PPT. person_type_id          = PPTU.person_type_id
	       AND        PPT.system_person_type       = 'EMP'
	       AND        PAAF.business_group_id       = 0
	       AND        PAPF.business_group_id       = 0
	       AND        PPT .business_group_id       = 0
	       AND        r.source_id                  = PAAF.person_id
	CONNECT BY 
	     PRIOR        PAAF.person_id               = PAAF.supervisor_id
	START WITH        PAAF.person_id               = p_person_id) f
	     WHERE lvl=2
	       AND EXISTS (SELECT   RO.MEMBER_FLAG    
	     		     FROM   JTF_RS_ROLE_RELATIONS 	RR 
	     			  , JTF_RS_ROLES_B 		RO 
	     			  , JTF_RS_RESOURCE_EXTNS 	R
	     			  , JTF_RS_GROUP_MBR_ROLE_VL GR
	     			  , JTF_RS_GROUP_USAGES 	U
	     			  , JTF_RS_GROUP_MEMBERS 	jgm
	     		    WHERE r.source_id=f.person_id 
	     		      AND rr.role_resource_type = G_GRP_MBR_TYPE 
	     		      AND rr.start_date_active <= sysdate 
	     		      AND (rr.end_date_active >= sysdate or rr.end_date_active is null) 
	     		      AND rr.role_id = ro.role_id 
	     		      AND ro.role_type_code = G_ROLE_TYPE 
	     		      AND gr.resource_id=r.resource_id 
	     		      AND gr.role_id=ro.role_id 
	     		      AND u.group_id=gr.group_id 
	     		      AND u.usage=G_ROLE_TYPE
	     		      AND rr.delete_flag=G_NO 
	     		      AND rr.role_resource_id = jgm.group_member_id
	     		      AND r.resource_id = jgm.resource_id 
	     		      AND jgm.delete_flag=G_NO 
			      AND ro.member_flag=G_YES
			      AND gr.group_id=p_group_id);
-----------------------------------------------------------------
--Cursor to get the Manager and Proxy Administrator User Details.
-----------------------------------------------------------------	     
      CURSOR gcu_get_mgr_adm_details(p_person_id IN NUMBER,p_group_id IN NUMBER) 
      IS
	   SELECT   
	     u.user_id 
	   , u.user_name
	   , r.resource_name
	     FROM   per_all_people_f p
	   , jtf_rs_resource_extns_vl r
	   , fnd_user u
	    WHERE   person_id     = p_person_id 
	      AND   p.person_id   = r.source_id
	      AND   u.user_id     = r.user_id
	   UNION ALL
	   SELECT   
	     u.user_id
	   , u.user_name 
	   , r.resource_name
	     FROM   jtf_rs_resource_extns_vl r
	   , fnd_user u 
	    WHERE   u.user_id=r.user_id 
	    AND     resource_id in 
		 (SELECT distinct resource_id 
		    FROM JTF_RS_GROUP_MBR_ROLE_VL 
		   WHERE group_id=p_group_id 
		     AND sysdate >= start_date_active 
		     AND sysdate <= nvl(end_date_active,sysdate) 
		     AND admin_flag=G_YES);
--------------------------------------------------------------------------------
--Cursor to obtain the RESOURCE_NAME for the Person ID passed for Error Logging
--------------------------------------------------------------------------------   
      CURSOR gcu_get_res_details(p_person_id IN NUMBER) 
      IS
           SELECT resource_name
	     FROM jtf_rs_resource_extns_vl
	    WHERE source_id=p_person_id;
	    
------------------------------------------------------
--Cursor to obtain the Group for the Person ID passed.
------------------------------------------------------
      CURSOR gcu_get_group_details(p_person_id IN NUMBER) 
      IS
           SELECT   jgm.GROUP_ID
	     FROM   JTF_RS_ROLE_RELATIONS 	RR 
		  , JTF_RS_ROLES_B 		RO 
		  , JTF_RS_RESOURCE_EXTNS 	R
		  , JTF_RS_GROUP_MBR_ROLE_VL    GR
		  , JTF_RS_GROUP_USAGES 	U
		  , JTF_RS_GROUP_MEMBERS 	jgm
	    WHERE r.source_id=p_person_id
	      AND rr.role_resource_type = G_GRP_MBR_TYPE 
	      AND rr.start_date_active <= sysdate 
	      AND (rr.end_date_active >= sysdate or rr.end_date_active is null) 
	      AND rr.role_id = ro.role_id 
	      AND ro.role_type_code = G_ROLE_TYPE 
	      AND gr.resource_id=r.resource_id 
	      AND gr.role_id=ro.role_id 
	      AND u.group_id=gr.group_id 
	      AND u.usage=G_ROLE_TYPE
	      AND rr.delete_flag=G_NO 
	      AND rr.role_resource_id = jgm.group_member_id
	      AND r.resource_id = jgm.resource_id 
	      AND jgm.delete_flag=G_NO 
	      AND ro.manager_flag=G_YES
	      AND ro.attribute14=G_MGR_TYPE;	    
	    
-- +===================================================================+
-- | Name        :  DISPLAY_LOG                                        |
-- | Description :  This procedure is invoked to print in the log file |
-- | Parameters  :  p_message IN VARCHAR2                              |
-- |                p_optional IN NUMBER                               |
-- +===================================================================+
 
   PROCEDURE display_log (p_message IN VARCHAR2)
   IS
   
   BEGIN
   
      FND_FILE.put_line (FND_FILE.LOG, p_message);
      
   END display_log;

-- +====================================================================+
-- | Name        :  DISPLAY_OUT                                         |
-- | Description :  This procedure is invoked to print in the Output    |
-- |                file                                                |
-- | Parameters  :  p_message IN VARCHAR2                               |
-- +====================================================================+

   PROCEDURE display_out (p_message IN VARCHAR2)
   IS
   
   BEGIN
   
      FND_FILE.put_line (FND_FILE.output, p_message);
      
   END display_out; 
-- +========================================================================+
-- | Name        :  LOG_ERROR                                               |
-- |                                                                        |
-- | Description :  This wrapper procedure calls the custom common error api|
-- |                 with relevant parameters.                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_prog_name IN VARCHAR2                                 |
-- |                p_exception IN VARCHAR2                                 |
-- |                p_message   IN VARCHAR2                                 |
-- |                p_code      IN NUMBER                                   |
-- |                                                                        |
-- +========================================================================+
   PROCEDURE log_error (
                         p_prog_name   IN   VARCHAR2,
                         p_prog_type   IN   VARCHAR2,
                         p_prog_id     IN   NUMBER,
                         p_exception   IN   VARCHAR2,
                         p_message     IN   VARCHAR2,
                         p_code        IN   NUMBER,
                         p_err_code    IN   VARCHAR2
                       )
   IS
   
   lc_severity   VARCHAR2 (15) := NULL;
      
   BEGIN
      IF p_code = -1
      THEN
         lc_severity := G_MAJOR;
         
      ELSIF p_code = 1
      THEN
         lc_severity := G_MINOR;
         
      END IF;

      xx_com_error_log_pub.log_error (p_program_type                => p_prog_type,
                                      p_program_name                => p_prog_name,
                                      p_program_id                  => p_prog_id, 
                                      p_module_name                 => G_MODULE_NAME,
                                      p_error_location              => p_exception,
                                      p_error_message_code          => p_err_code,
                                      p_error_message               => p_message,
                                      p_error_message_severity      => lc_severity,
                                      p_notify_flag                 => G_NOTIFY,
                                      p_error_status                => G_ERROR_STATUS
                                     );
   END log_error;   
-- +===========================================================================================================+
-- | Name        :  generate_lead_xml
-- | Description :  This procedure is used to generate the User Personalization XML File for Leads.
-- |                The DSM Person_ID is passed to generate_lead_xml() and XML is generated for this DSM and 
-- |                all the Proxy Administrators in the DSM group
-- | Parameters  :  p_person_id     IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
-- |                p_lead_status   IN   as_statuses_b.status_code%TYPE,
-- |                lf_err_file     IN   utl_file.file_type,
-- |                x_file_list_tbl OUT  xx_file_list_tbl_type,
-- |                x_rep_count    OUT  NUMBER
-- +===========================================================================================================+
   PROCEDURE generate_lead_xml (
    p_person_id     IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
    p_lead_status   IN   as_statuses_b.status_code%TYPE,
    lf_err_file     IN   utl_file.file_type,
    x_file_list_tbl OUT  xx_file_list_tbl_type,
    x_rep_count    OUT  NUMBER
   )
   IS	      
       
      ln_count                      NUMBER                          := 1;
      ln_group_id                   JTF_RS_GROUPS_B.GROUP_ID%TYPE;
      ln_group_count                NUMBER                          := 0;
      ln_mgr_adm_count              NUMBER                          := 0;
      ln_message_code               NUMBER;  
      
      lc_xml_string                 VARCHAR2 (32727)                := NULL;
      lc_xml_salesrep_string        VARCHAR2 (32727)                := NULL;
      lc_filename                   VARCHAR2 (48);
      lc_user_id                    VARCHAR2 (40); 
      lc_yes_or_no                  VARCHAR2 (1);
      lc_resource_name              JTF_RS_RESOURCE_EXTNS_VL.RESOURCE_NAME%TYPE;
      lc_message_data               VARCHAR2 (4000);
      lc_errmsg                     VARCHAR2 (4000); 
      lc_is_user_data_found         VARCHAR2(1)                     := 'N';
      
      lf_file                       utl_file.file_type;
   BEGIN
      BEGIN
----------------------------------------------------------------------
--Obtain the RESOURCE_NAME for the Person ID passed for Error Logging
---------------------------------------------------------------------- 
      open gcu_get_res_details(p_person_id);
      fetch gcu_get_res_details into lc_resource_name;
      close gcu_get_res_details;
---------------------------------------------
--Obtain the Group for the Person ID passed.
--------------------------------------------- 
      open gcu_get_group_details(p_person_id);
      fetch gcu_get_group_details into ln_group_id;
      IF (gcu_get_group_details%ROWCOUNT >1) THEN
        RAISE EX_MULTIPLE_GRPS_WITH_RES; 
      END IF;
      close gcu_get_group_details;
      END;
      
      IF(p_lead_status='NEW'         OR 
         p_lead_status='IN_PROGRESS' OR 
         p_lead_status='ON-HOLD') THEN
        lc_yes_or_no             :='Y';
      ELSE 
        lc_yes_or_no             :='N';
      END IF;
      ----------------------------------------------------------------------
      --Running the "Manager and Proxy Administrator User Details" Cursor
      ----------------------------------------------------------------------
      for l_get_mgr_adm_details_rec in gcu_get_mgr_adm_details(p_person_id,ln_group_id)
      LOOP
         lc_is_user_data_found   := 'Y';
         lc_xml_string           := NULL;
         lc_xml_salesrep_string  := NULL;
         lc_xml_string           :=
                                   '<?xml version = ''1.0'' encoding = ''UTF-8''?>'
                                 ||'<customization xmlns="http://xmlns.oracle.com/jrad" version="9.0.5.4.89_560" xml:lang="en-US" customizes="/oracle/apps/asn/lead/webui/LeadUwqPG" developerMode="false" xmlns:user="http://xmlns.oracle.com/jrad/user" user:username="'
                                 ||l_get_mgr_adm_details_rec.user_name
                                 ||'" package="/oracle/apps/asn/lead/webui/customizations/user/'
                                 ||l_get_mgr_adm_details_rec.user_id
                                 ||'"><views>';
         lc_user_id              := TO_CHAR(l_get_mgr_adm_details_rec.user_id);
         ln_count                := 1;
         lc_filename             := lc_user_id|| '.xml';
         lf_file 	              := UTL_FILE.FOPEN(location        => 'CRM_FILE_LOCATION',
                                                        filename        => lc_filename,
                                                        open_mode       => 'W',
                                                        max_linesize    => 32767);
            
         utl_file.put_line       (lf_file, 
      	                          lc_xml_string); 
      	----------------------------------------------------------------------
        --Running the "DSM Direct Reports" Cursor
        ----------------------------------------------------------------------   
      	for l_manager_directs_rec in gcu_get_manager_directs(p_person_id,ln_group_id)
      	LOOP
      	   BEGIN
      	   lc_xml_salesrep_string:='<view id="view'
      				 ||ln_count
      				 ||'" description="" element="ASNLeadQryRN.ASNLeadLstRN" name="'
      				 ||l_manager_directs_rec.resource_name||'"><modifications>'
      				 ||'<modify element="ASNLeadQryRN.ASNLeadLstRN" blockSize="10"><queryCriteria>'
      				 ||'<criterion element="ASNLeadQryRN.ASNLeadLstStatus" operator="is" operand="'
      				 ||p_lead_status||','
      				 ||lc_yes_or_no ||'"/>'
      				 ||'<criterion element="ASNLeadQryRN.ASNLeadLstSlsRscId" operator="is" operand="'
      				 ||l_manager_directs_rec.resource_id||'"/>'
      				 ||'<criterion element="ASNLeadQryRN.ASNLeadLstStsCtg" operator="is" operand="Y"/>'
      				 ||'<criterion element="ASNLeadQryRN.ASNLeadLstSlsRscNm" operator="is" operand="'
      				 ||l_manager_directs_rec.resource_name||'" joinCondition="and"/>'
      				 ||'</queryCriteria></modify>';
           utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 

      	   lc_xml_salesrep_string:='<move element="ASNLeadQryRN.ASNLeadLstCustNm" after="ASNLeadQryRN.ASNLeadLstNm"/>'
				 ||'<move element="ASNLeadQryRN.ProsCust" after="ASNLeadQryRN.ASNLeadLstCustNm"/>' 
         ||'<move element="ASNLeadQryRN.ASNLeadLstCustAddr" after="ASNLeadQryRN.ProsCust"/>'
         ||'<move element="ASNLeadQryRN.ASNLeadLstCustCntry" after="ASNLeadQryRN.ASNLeadLstCustAddr"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctNm" after="ASNLeadQryRN.ASNLeadLstCustCntry"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstRank" after="ASNLeadQryRN.ASNLeadLstCtctNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstStatus" after="ASNLeadQryRN.ASNLeadLstRank"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstAge" after="ASNLeadQryRN.ASNLeadLstStatus"/>'
				 ||'<move element="ASNLeadQryRN.ASNleadLstRspChnl" after="ASNLeadQryRN.ASNLeadLstAge"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCnvToOppty" after="ASNLeadQryRN.ASNleadLstRspChnl"/>' ;
	   utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);
   -- QC 2264 Annapoorani Begin                               
      	   lc_xml_salesrep_string:='<move element="ASNLeadQryRN.ASNLeadLstOwId" after="ASNLeadQryRN.ASNLeadLstCnvToOppty"/>';
	   utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);                                  
   -- QC 2264 Annapoorani End 
      	   lc_xml_salesrep_string:='<move element="ASNLeadQryRN.ASNLeadLstSlsRscId" after="ASNLeadQryRN.ASNLeadLstOwId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstSlsGrpId" after="ASNLeadQryRN.ASNLeadLstSlsRscId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstPrdtCtgId" after="ASNLeadQryRN.ASNLeadLstSlsGrpId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstSrcId" after="ASNLeadQryRN.ASNLeadLstPrdtCtgId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstPrdtInvItmId" after="ASNLeadQryRN.ASNLeadLstSrcId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstPrdtInvOrgId" after="ASNLeadQryRN.ASNLeadLstPrdtInvItmId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstStsCtg" after="ASNLeadQryRN.ASNLeadLstPrdtInvOrgId"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctFstNm" after="ASNLeadQryRN.ASNLeadLstStsCtg"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctLstNm" after="ASNLeadQryRN.ASNLeadLstCtctFstNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstSlsRscNm" after="ASNLeadQryRN.ASNLeadLstCtctLstNm"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="ASNLeadQryRN.ASNLeadLstPrdtCtgNm" after="ASNLeadQryRN.ASNLeadLstSlsRscNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstSlsGrpNm" after="ASNLeadQryRN.ASNLeadLstPrdtCtgNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctJob" after="ASNLeadQryRN.ASNLeadLstSlsGrpNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctPhone" after="ASNLeadQryRN.ASNLeadLstCtctJob"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstSrcNm" after="ASNLeadQryRN.ASNLeadLstCtctPhone"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctLclTm" after="ASNLeadQryRN.ASNLeadLstSrcNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctLclTmZn" after="ASNLeadQryRN.ASNLeadLstCtctLclTm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctCity" after="ASNLeadQryRN.ASNLeadLstCtctLclTmZn"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctProv" after="ASNLeadQryRN.ASNLeadLstCtctCity"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctState" after="ASNLeadQryRN.ASNLeadLstCtctProv"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="ASNLeadQryRN.ASNLeadLstCtctCntry" after="ASNLeadQryRN.ASNLeadLstCtctState"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctZip" after="ASNLeadQryRN.ASNLeadLstCtctCntry"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctEmail" after="ASNLeadQryRN.ASNLeadLstCtctZip"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctAddr" after="ASNLeadQryRN.ASNLeadLstCtctEmail"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstNbr" after="ASNLeadQryRN.ASNLeadLstCtctAddr"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstLastUpdDate" after="ASNLeadQryRN.ASNLeadLstNbr"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCrteDate" after="ASNLeadQryRN.ASNLeadLstLastUpdDate"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCurrNm" after="ASNLeadQryRN.ASNLeadLstCrteDate"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstMeth" after="ASNLeadQryRN.ASNLeadLstCurrNm"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstStg" after="ASNLeadQryRN.ASNLeadLstMeth"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="ASNLeadQryRN.ASNLeadLstChnl" after="ASNLeadQryRN.ASNLeadLstStg"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstClsRsn" after="ASNLeadQryRN.ASNLeadLstChnl"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCrteBy" after="ASNLeadQryRN.ASNLeadLstClsRsn"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstUpdBy" after="ASNLeadQryRN.ASNLeadLstCrteBy"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstBdgtAmt" after="ASNLeadQryRN.ASNLeadLstUpdBy"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCtctRole" after="ASNLeadQryRN.ASNLeadLstBdgtAmt"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCustCity" after="ASNLeadQryRN.ASNLeadLstCtctRole"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCustState" after="ASNLeadQryRN.ASNLeadLstCustCity"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCustProv" after="ASNLeadQryRN.ASNLeadLstCustState"/>'
				 ||'<move element="ASNLeadQryRN.ASNLeadLstCustZip" after="ASNLeadQryRN.ASNLeadLstCustProv"/>'
                                 ||'<move element="ASNLeadQryRN.ASNLeadLstSrcSystem" after="ASNLeadQryRN.ASNLeadLstCustZip"/>'
      				 ||'</modifications></view>';
           utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
           ln_count              := ln_count +1;

           utl_file.put_line     (lf_err_file,
                                  RPAD (l_get_mgr_adm_details_rec.resource_name, 36)
                                 || CHR(9)
                                 || RPAD (l_manager_directs_rec.resource_name, 104)
                                 || CHR(9)
                                 || RPAD ('Success', 24));          
      	   END;
        END LOOP;
        x_rep_count             := ln_count - 1;
        lc_xml_string            := '</views></customization>';
        utl_file.put_line        (lf_file, 
      	                          lc_xml_string); 
        utl_file.fclose          (lf_file);
        x_file_list_tbl          (ln_mgr_adm_count)
                                 := lc_filename;
        ln_mgr_adm_count         := ln_mgr_adm_count + 1;
        IF(x_rep_count=0) THEN
           utl_file.put_line     (lf_err_file,
                                  RPAD (l_get_mgr_adm_details_rec.resource_name, 36)
                                 || CHR(9)
                                 || RPAD ('No Salespeople assigned. Empty XML Generated.', 104)
                                 || CHR(9)
                                 || RPAD ('Success', 24));        
        END IF;
      END LOOP;
      IF(lc_is_user_data_found='N') THEN
      	RAISE EX_CRM_FND_USER_UNSYNC;
      END IF; 
   EXCEPTION
      WHEN EX_MULTIPLE_GRPS_WITH_RES
      THEN
         ROLLBACK;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_SFA_0101_MULT_GRPS_FOR_RES');
         fnd_message.set_token   ('RESOURCE_NAME', lc_resource_name);         
         lc_message_data         := fnd_message.get;
         log_error
                                 (p_prog_name      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_LEAD_XML',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_LEAD_XML',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_SFA_0101_MULT_GRPS_FOR_RES'
                                 );
         lc_errmsg               := 'Procedure: GENERATE_LEAD_XML: ' || lc_message_data;
         lc_message_data         := substr(lc_message_data,1,instr(lc_message_data,':')-1);
         utl_file.put_line       (lf_err_file,
                                  RPAD (lc_resource_name, 36)
                                 || CHR(9)
                                 || RPAD (lc_message_data, 104)
                                 || CHR(9)
                                 || RPAD ('Failure', 24)); 
         gn_failed_mgrs          := gn_failed_mgrs + 1;
         WHEN EX_CRM_FND_USER_UNSYNC
         THEN
         ROLLBACK;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_SFA_0102_CRM_FND_UNSYNC');
         fnd_message.set_token   ('RESOURCE_NAME', lc_resource_name);         
         lc_message_data         := fnd_message.get;
         log_error
                                 (p_prog_name      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_LEAD_XML',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_LEAD_XML',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_SFA_0102_CRM_FND_UNSYNC'
                                 );
         lc_errmsg               := 'Procedure: GENERATE_LEAD_XML: ' || lc_message_data;
         lc_message_data         := substr(lc_message_data,1,instr(lc_message_data,':')-1);
         utl_file.put_line       (lf_err_file,
                                  RPAD (lc_resource_name, 36)
                                 || CHR(9)
                                 || RPAD (lc_message_data, 104)
                                 || CHR(9)
                                 || RPAD ('Failure', 24)); 
         gn_failed_mgrs          := gn_failed_mgrs + 1;                        
   END generate_lead_xml;
   
-- +===========================================================================================================+
-- | Name        :  generate_oppty_xml
-- | Description :  This procedure is used to generate the User Personalization XML File for Opportunities.
-- |                The DSM Person_ID is passed to generate_oppty_xml() and XML is generated for this DSM and 
-- |                all the Proxy Administrators in the DSM group
-- | Parameters  :  p_person_id     IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
-- |                p_oppty_status  IN   as_statuses_b.status_code%TYPE,
-- |                lf_err_file     IN   utl_file.file_type,
-- |                x_file_list_tbl OUT  xx_file_list_tbl_type,
-- |                x_rep_count    OUT  NUMBER
-- +===========================================================================================================+   
   
   PROCEDURE generate_oppty_xml (
    p_person_id     IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
    p_oppty_status  IN   as_statuses_b.status_code%TYPE,
    lf_err_file     IN   utl_file.file_type,    
    x_file_list_tbl OUT  xx_file_list_tbl_type,
    x_rep_count    OUT  NUMBER    
    )
   IS
       
      ln_count                      NUMBER                          := 1;
      ln_group_id                   JTF_RS_GROUPS_B.GROUP_ID%TYPE;
      ln_group_count                NUMBER                          := 0;      
      ln_mgr_adm_count              NUMBER                          := 0;
      ln_message_code               NUMBER; 
      
      lc_xml_string                 VARCHAR2 (32727)                := NULL;
      lc_xml_salesrep_string        VARCHAR2 (32727)                := NULL;
      lc_resource_name              JTF_RS_RESOURCE_EXTNS_VL.RESOURCE_NAME%TYPE;      
      lc_filename                   VARCHAR2 (48);
      lc_user_id                    VARCHAR2 (40);
      lc_message_data               VARCHAR2 (4000);
      lc_errmsg                     VARCHAR2 (4000); 
      lc_is_user_data_found         VARCHAR2 (1)                    := 'N';      
	
      lf_file                       utl_file.file_type;
   BEGIN
      BEGIN
----------------------------------------------------------------------
--Obtain the RESOURCE_NAME for the Person ID passed for Error Logging
---------------------------------------------------------------------- 
      open gcu_get_res_details(p_person_id);
      fetch gcu_get_res_details into lc_resource_name;
      close gcu_get_res_details;
---------------------------------------------
--Obtain the Group for the Person ID passed.
--------------------------------------------- 
      open gcu_get_group_details(p_person_id);
      fetch gcu_get_group_details into ln_group_id;
      IF (gcu_get_group_details%ROWCOUNT >1) THEN
        RAISE EX_MULTIPLE_GRPS_WITH_RES; 
      END IF;
      close gcu_get_group_details;
      END;
      ----------------------------------------------------------------------
      --Running the "Manager and Proxy Administrator User Details" Cursor
      ----------------------------------------------------------------------      
      for l_get_mgr_adm_details_rec in gcu_get_mgr_adm_details(p_person_id,ln_group_id)
      LOOP
         lc_is_user_data_found   := 'Y';      
         lc_xml_string 		 := NULL;
         lc_xml_salesrep_string  := NULL;
         lc_xml_string           :='<?xml version = ''1.0'' encoding = ''UTF-8''?>'
                                 ||'<customization xmlns="http://xmlns.oracle.com/jrad" version="9.0.5.4.89_560" xml:lang="en-US" customizes="/oracle/apps/asn/opportunity/webui/OpptyUwqPG" developerMode="false" xmlns:user="http://xmlns.oracle.com/jrad/user" user:username="'
                                 ||l_get_mgr_adm_details_rec.user_name
                                 ||'" package="/oracle/apps/asn/opportunity/webui/customizations/user/'
                                 ||l_get_mgr_adm_details_rec.user_id
                                 ||'"><views>';
         lc_user_id              := TO_CHAR(l_get_mgr_adm_details_rec.user_id);
         ln_count                := 1;
      
         lc_filename             := lc_user_id|| '.xml';
         lf_file 	         := UTL_FILE.FOPEN(location        => 'CRM_FILE_LOCATION',
                                                   filename        => lc_filename,
                                                   open_mode       => 'W',
                                                   max_linesize    => 32767);
      
         utl_file.put_line       (lf_file, 
      	                          lc_xml_string);
      	----------------------------------------------------------------------
        --Running the "DSM Direct Reports" Cursor
        ----------------------------------------------------------------------       	                          
        for l_manager_directs_rec in gcu_get_manager_directs(p_person_id,ln_group_id)
        LOOP
      	   BEGIN
      	   lc_xml_salesrep_string:='<view id="view'
      				 ||ln_count
      				 ||'" description="" element="ASNOpptySrchStack.ASNOpptyLstTb" name="'
      				 ||l_manager_directs_rec.resource_name||'"><modifications>'
      				 ||'<modify element="ASNOpptySrchStack.ASNOpptyLstTb" blockSize="10"><queryCriteria>'
      				 ||'<criterion element="ASNOpptySrchStack.ASNOpptyLstStatus" operator="is" operand="'
      				 ||p_oppty_status||'"/>'
      				 ||'<criterion element="ASNOpptySrchStack.ASNOpptyLstSlsRepId" operator="is" operand="'
      				 ||l_manager_directs_rec.resource_id||'"/>'
      				 ||'<criterion element="ASNOpptySrchStack.ASNOpptyLstStCatgCode" operator="is" operand="Y"/>'
      				 ||'<criterion element="ASNOpptySrchStack.ASNOpptyLstRscNm" operator="is" operand="'
      				 ||l_manager_directs_rec.resource_name||'" joinCondition="and"/>'
      				 ||'</queryCriteria></modify>';
           utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);
      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstCustNm" after="ASNOpptySrchStack.ASNOpptyLstNm"/>'
         ||'<move element="ASNOpptySrchStack.ProsCust" after="ASNOpptySrchStack.ASNOpptyLstCustNm"/>' 
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCustCnty" after="ASNOpptySrchStack.ProsCust"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstAmt" after="ASNOpptySrchStack.ASNOpptyLstCustCnty"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCurr" after="ASNOpptySrchStack.ASNOpptyLstAmt"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstStatus" after="ASNOpptySrchStack.ASNOpptyLstCurr"/>'         
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstDate" after="ASNOpptySrchStack.ASNOpptyLstStatus"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCtctFirstNm" after="ASNOpptySrchStack.ASNOpptyLstDate"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCtctLastNm" after="ASNOpptySrchStack.ASNOpptyLstCtctFirstNm"/>';
				 
	   utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);
   -- QC 2264 Annapoorani Begin                               
      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstFrcstAmt" after="ASNOpptySrchStack.ASNOpptyLstCtctLastNm"/>';
	   utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);                                  
   -- QC 2264 Annapoorani End                                   

      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstCntryCode" after="ASNOpptySrchStack.ASNOpptyLstFrcstAmt"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstPartnerNm" after="ASNOpptySrchStack.ASNOpptyLstCntryCode"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstPartnerId" after="ASNOpptySrchStack.ASNOpptyLstPartnerNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstContribNm" after="ASNOpptySrchStack.ASNOpptyLstPartnerId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstContribId" after="ASNOpptySrchStack.ASNOpptyLstContribNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstFrcstOwnNm" after="ASNOpptySrchStack.ASNOpptyLstContribId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstFrcstOwnId" after="ASNOpptySrchStack.ASNOpptyLstFrcstOwnNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstRefCode" after="ASNOpptySrchStack.ASNOpptyLstFrcstOwnId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstAssgnStatCode" after="ASNOpptySrchStack.ASNOpptyLstRefCode"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstSlsRepId" after="ASNOpptySrchStack.ASNOpptyLstAssgnStatCode"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstSlsGrpNm" after="ASNOpptySrchStack.ASNOpptyLstSlsRepId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstSlsGrpId" after="ASNOpptySrchStack.ASNOpptyLstSlsGrpNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstClsRsnCode" after="ASNOpptySrchStack.ASNOpptyLstSlsGrpId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstFrcst" after="ASNOpptySrchStack.ASNOpptyLstClsRsnCode"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstStCatgCode" after="ASNOpptySrchStack.ASNOpptyLstFrcst"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstMeth" after="ASNOpptySrchStack.ASNOpptyLstStCatgCode"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstPrdNm" after="ASNOpptySrchStack.ASNOpptyLstMeth"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstPrdCatgId" after="ASNOpptySrchStack.ASNOpptyLstPrdNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstInvItem" after="ASNOpptySrchStack.ASNOpptyLstPrdCatgId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstOrgId" after="ASNOpptySrchStack.ASNOpptyLstInvItem"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstRscNm" after="ASNOpptySrchStack.ASNOpptyLstOrgId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstRscId" after="ASNOpptySrchStack.ASNOpptyLstRscNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstStageId" after="ASNOpptySrchStack.ASNOpptyLstRscId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstSrc" after="ASNOpptySrchStack.ASNOpptyLstStageId"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstDateRange" after="ASNOpptySrchStack.ASNOpptyLstSrc"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstStage" after="ASNOpptySrchStack.ASNOpptyLstDateRange"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstWinProb" after="ASNOpptySrchStack.ASNOpptyLstStage"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstNbr" after="ASNOpptySrchStack.ASNOpptyLstWinProb"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstLastUpdDate" after="ASNOpptySrchStack.ASNOpptyLstNbr"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCrtedDate" after="ASNOpptySrchStack.ASNOpptyLstLastUpdDate"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstCtctNm" after="ASNOpptySrchStack.ASNOpptyLstCrtedDate"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstJob" after="ASNOpptySrchStack.ASNOpptyLstCtctNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstPhone" after="ASNOpptySrchStack.ASNOpptyLstJob"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstEmail" after="ASNOpptySrchStack.ASNOpptyLstPhone"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCity" after="ASNOpptySrchStack.ASNOpptyLstEmail"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstProv" after="ASNOpptySrchStack.ASNOpptyLstCity"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCnty" after="ASNOpptySrchStack.ASNOpptyLstProv"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstState" after="ASNOpptySrchStack.ASNOpptyLstCnty"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstZip" after="ASNOpptySrchStack.ASNOpptyLstState"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstAddr" after="ASNOpptySrchStack.ASNOpptyLstZip"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string);      	
      	
      	   lc_xml_salesrep_string:='<move element="ASNOpptySrchStack.ASNOpptyLstSourcNm" after="ASNOpptySrchStack.ASNOpptyLstAddr"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstChnl" after="ASNOpptySrchStack.ASNOpptyLstSourcNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstRespChan" after="ASNOpptySrchStack.ASNOpptyLstChnl"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCustState" after="ASNOpptySrchStack.ASNOpptyLstRespChan"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCustCity" after="ASNOpptySrchStack.ASNOpptyLstCustState"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCustProv" after="ASNOpptySrchStack.ASNOpptyLstCustCity"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCustZip" after="ASNOpptySrchStack.ASNOpptyLstCustProv"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstUpdatedBy" after="ASNOpptySrchStack.ASNOpptyLstCustZip"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstCreatedBy" after="ASNOpptySrchStack.ASNOpptyLstUpdatedBy"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstDispFrcstAmt" after="ASNOpptySrchStack.ASNOpptyLstCreatedBy"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstMethNm" after="ASNOpptySrchStack.ASNOpptyLstDispFrcstAmt"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstClsRsnNm" after="ASNOpptySrchStack.ASNOpptyLstMethNm"/>'
				 ||'<move element="ASNOpptySrchStack.ASNOpptyLstAssgnStat" after="ASNOpptySrchStack.ASNOpptyLstClsRsnNm"/>'
                                 ||'<move element="ASNOpptySrchStack.ASNOpptyLstDispRef" after="ASNOpptySrchStack.ASNOpptyLstAssgnStat"/>'
      				 ||'</modifications></view>';
           utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
           ln_count              := ln_count +1;
           utl_file.put_line     (lf_err_file,
                                  RPAD (l_get_mgr_adm_details_rec.resource_name, 36)
                                 || CHR(9)
                                 || RPAD (l_manager_directs_rec.resource_name, 104)
                                 || CHR(9)
                                 || RPAD ('Success', 24));              
      	   END;
        END LOOP;
        x_rep_count             := ln_count - 1;
        lc_xml_string            := '</views></customization>';
        utl_file.put_line        (lf_file, 
      	                          lc_xml_string); 
        utl_file.fclose          (lf_file);
        x_file_list_tbl          (ln_mgr_adm_count)
                                 := lc_filename;
        ln_mgr_adm_count         := ln_mgr_adm_count + 1; 
        IF(x_rep_count=0) THEN
           utl_file.put_line     (lf_err_file,
                                  RPAD (l_get_mgr_adm_details_rec.resource_name, 36)
                                 || CHR(9)
                                 || RPAD ('No Salespeople assigned. Empty XML Generated.', 104)
                                 || CHR(9)
                                 || RPAD ('Success', 24));        
        END IF;        
      END LOOP;
      IF(lc_is_user_data_found='N') THEN
      	RAISE EX_CRM_FND_USER_UNSYNC;
      END IF;       
   EXCEPTION
      WHEN EX_MULTIPLE_GRPS_WITH_RES
      THEN
         ROLLBACK;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_SFA_0101_MULT_GRPS_FOR_RES');
         fnd_message.set_token   ('RESOURCE_NAME', lc_resource_name);         
         lc_message_data         := fnd_message.get;
         log_error
                                 (p_prog_name      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_OPPTY_XML',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_OPPTY_XML',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_SFA_0101_MULT_GRPS_FOR_RES'
                                 );
         lc_errmsg               := 'Procedure: GENERATE_OPPTY_XML: ' || lc_message_data;
         lc_message_data         := substr(lc_message_data,1,instr(lc_message_data,':')-1);
         utl_file.put_line       (lf_err_file,
                                  RPAD (lc_resource_name, 36)
                                 || CHR(9)
                                 || RPAD (lc_message_data, 104)
                                 || CHR(9)
                                 || RPAD ('Failure', 24));   
         gn_failed_mgrs          := gn_failed_mgrs + 1;                        
         WHEN EX_CRM_FND_USER_UNSYNC
         THEN
         ROLLBACK;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_SFA_0102_CRM_FND_UNSYNC');
         fnd_message.set_token   ('RESOURCE_NAME', lc_resource_name);         
         lc_message_data         := fnd_message.get;
         log_error
                                 (p_prog_name      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_OPPTY_XML',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_OPPTY_XML',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_SFA_0102_CRM_FND_UNSYNC'
                                 );
         lc_errmsg               := 'Procedure: GENERATE_OPPTY_XML: ' || lc_message_data;
         lc_message_data         := substr(lc_message_data,1,instr(lc_message_data,':')-1);
         utl_file.put_line       (lf_err_file,
                                  RPAD (lc_resource_name, 36)
                                 || CHR(9)
                                 || RPAD (lc_message_data, 104)
                                 || CHR(9)
                                 || RPAD ('Failure', 24));
         gn_failed_mgrs          := gn_failed_mgrs + 1;                        
   END generate_oppty_xml;  
   
-- +===========================================================================================================+
-- | Name        :  generate_cust_xml
-- | Description :  This procedure is used to generate the User Personalization XML File for Customers.
-- |                The DSM Person_ID is passed to generate_oppty_xml() and XML is generated for this DSM and 
-- |                all the Proxy Administrators in the DSM group
-- | Parameters  :  p_person_id     IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
-- |                lf_err_file     IN   utl_file.file_type,
-- |                x_file_list_tbl OUT  xx_file_list_tbl_type,
-- |                x_rep_count    OUT  NUMBER
-- +===========================================================================================================+   
   
   PROCEDURE generate_cust_xml (
    p_person_id     IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
    lf_err_file     IN   utl_file.file_type,    
    x_file_list_tbl OUT  xx_file_list_tbl_type,
    x_rep_count    OUT  NUMBER        
    )
   IS
       
      ln_count                      NUMBER                          := 1;
      ln_group_id                   JTF_RS_GROUPS_B.GROUP_ID%TYPE;
      ln_group_count                NUMBER                          := 0;      
      ln_mgr_adm_count              NUMBER                          := 0;
      ln_message_code               NUMBER;       
	
      lc_xml_string                 VARCHAR2 (32727)                := NULL;
      lc_xml_salesrep_string        VARCHAR2 (32727)                := NULL;
      lc_resource_name              JTF_RS_RESOURCE_EXTNS_VL.RESOURCE_NAME%TYPE;      
      lc_filename                   VARCHAR2 (48);
      lc_user_id                    VARCHAR2 (40);
      lc_message_data               VARCHAR2 (4000);
      lc_errmsg                     VARCHAR2 (4000);       
      lc_is_user_data_found         VARCHAR2 (1)                    := 'N';         
	
      lf_file                       utl_file.file_type;
   BEGIN
      BEGIN
----------------------------------------------------------------------
--Obtain the RESOURCE_NAME for the Person ID passed for Error Logging
---------------------------------------------------------------------- 
      open gcu_get_res_details(p_person_id);
      fetch gcu_get_res_details into lc_resource_name;
      close gcu_get_res_details;
---------------------------------------------
--Obtain the Group for the Person ID passed.
--------------------------------------------- 
      open gcu_get_group_details(p_person_id);
      fetch gcu_get_group_details into ln_group_id;
      IF (gcu_get_group_details%ROWCOUNT >1) THEN
        RAISE EX_MULTIPLE_GRPS_WITH_RES; 
      END IF;
      close gcu_get_group_details;
      END;
      ----------------------------------------------------------------------
      --Running the "Manager and Proxy Administrator User Details" Cursor
      ----------------------------------------------------------------------      
      for l_get_mgr_adm_details_rec in gcu_get_mgr_adm_details(p_person_id,ln_group_id)
      LOOP
         lc_is_user_data_found   := 'Y';      
         lc_xml_string 		 := NULL;
         lc_xml_salesrep_string  := NULL;
         lc_xml_string           :='<?xml version = ''1.0'' encoding = ''UTF-8''?>'
                                 ||'<customization xmlns="http://xmlns.oracle.com/jrad" version="9.0.5.4.89_560" xml:lang="en-US" customizes="/od/oracle/apps/xxcrm/asn/custsrch/common/customer/webui/ODCustomerSearchPG" developerMode="false" xmlns:user="http://xmlns.oracle.com/jrad/user" user:username="'
                                 ||l_get_mgr_adm_details_rec.user_name
                                 ||'" package="/od/oracle/apps/xxcrm/asn/custsrch/common/customer/webui/customizations/user/'
                                 ||l_get_mgr_adm_details_rec.user_id
                                 ||'"><views>';
         lc_user_id              := TO_CHAR(l_get_mgr_adm_details_rec.user_id);
         ln_count                := 1;
      
         lc_filename             := lc_user_id|| '.xml';
         lf_file 	         := UTL_FILE.FOPEN(location        => 'CRM_FILE_LOCATION',
                                                   filename        => lc_filename,
                                                   open_mode       => 'W',
                                                   max_linesize    => 32767);
      
         utl_file.put_line       (lf_file, 
      	                          lc_xml_string);
      	----------------------------------------------------------------------
        --Running the "DSM Direct Reports" Cursor
        ----------------------------------------------------------------------       	                          
        for l_manager_directs_rec in gcu_get_manager_directs(p_person_id,ln_group_id)
        LOOP
      	   BEGIN
      	   lc_xml_salesrep_string:='<view id="view'
      				 ||ln_count
      				 ||'" description="" element="CustSrchResultsTb" name="'
      				 ||l_manager_directs_rec.resource_name||'"><modifications>'
      				 ||'<modify element="CustSrchResultsTb" blockSize="10"><queryCriteria>'
      				 ||'<criterion element="NoOfRows" operator="is" operand="200"/>'
      				 ||'<criterion element="ResultsFlag" operator="is" operand="SITE"/>'
      				 ||'<criterion element="ActiveFlag" operator="is" operand="ACTIVE"/>'
      				 ||'<criterion element="SalesPerson" operator="is" operand="'
      				 ||l_manager_directs_rec.resource_name||'"/>'
      				 ||'<criterion element="SalesPersonResourceId" operator="is" operand="'
      				 ||l_manager_directs_rec.resource_id||'" joinCondition="and"/>'
      				 ||'</queryCriteria></modify>';
           utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string);

      	   lc_xml_salesrep_string:='<move element="ProsCust" after="PartyNameLink"/>'
         			||'<move element="Prospect" after="ProsCust"/>'
				 ||'<move element="SiteUseType" after="Prospect"/>'
				 ||'<move element="SiteSeqNum" after="SiteUseType"/>'
				 ||'<move element="SourceSystem" after="SiteSeqNum"/>'
				 ||'<move element="KnownAs" after="SourceSystem"/>'
				 ||'<move element="AddressLink" after="KnownAs"/>'
				 ||'<move element="Country" after="AddressLink"/>'
				 ||'<move element="Pphone" after="Country"/>'
				 ||'<move element="PrimaryUrl" after="Pphone"/>';
				 
	   utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);
   -- QC 2264 Annapoorani Begin                               
      	   lc_xml_salesrep_string:='<move element="Email" after="PrimaryUrl"/>';
	   utl_file.put_line     (lf_file,
      	                          lc_xml_salesrep_string);                                  
   -- QC 2264 Annapoorani End                                   

      	   lc_xml_salesrep_string:='<move element="PrimarySalesPerson" after="Email"/>'
				 ||'<move element="CanCrossSell" after="PrimarySalesPerson"/>'
				 ||'<move element="ConctFreq" after="CanCrossSell"/>'
				 ||'<move element="WhiteCollarWrk" after="ConctFreq"/>'
				 ||'<move element="NoOfRows" after="WhiteCollarWrk"/>'
				 ||'<move element="ResultsFlag" after="NoOfRows"/>'
				 ||'<move element="ActiveFlag" after="ResultsFlag"/>'
				 ||'<move element="PartySiteId" after="ActiveFlag"/>'
				 ||'<move element="PartyId" after="PartySiteId"/>'
				 ||'<move element="PartySiteNumber" after="PartyId"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="AddressKey" after="PartySiteNumber"/>'
				 ||'<move element="PartyType" after="AddressKey"/>'
				 ||'<move element="PartyNumber" after="PartyType"/>'
				 ||'<move element="TaxReference" after="PartyNumber"/>'
				 ||'<move element="TaxPayerId" after="TaxReference"/>'
				 ||'<move element="DunsNumber" after="TaxPayerId"/>'
				 ||'<move element="KnownAs2" after="DunsNumber"/>'
				 ||'<move element="KnownAs3" after="KnownAs2"/>'
				 ||'<move element="KnownAs4" after="KnownAs3"/>'
				 ||'<move element="KnownAs5" after="KnownAs4"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="OrganizationNamePhonetic" after="KnownAs5"/>'
				 ||'<move element="PersonFirstNamePhonetic" after="OrganizationNamePhonetic"/>'
				 ||'<move element="PersonLastNamePhonetic" after="PersonFirstNamePhonetic"/>'
				 ||'<move element="LocationId" after="PersonLastNamePhonetic"/>'
				 ||'<move element="Percentage" after="LocationId"/>'
				 ||'<move element="City" after="Percentage"/>'
				 ||'<move element="State" after="City"/>'
				 ||'<move element="Province" after="State"/>'
				 ||'<move element="PostalCode" after="Province"/>'
				 ||'<move element="SicCode" after="PostalCode"/>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string); 
      	
      	   lc_xml_salesrep_string:='<move element="SicCodeType" after="SicCode"/>'
				 ||'<move element="CustomerCategory" after="SicCodeType"/>'
				 ||'<move element="SalesChannel" after="CustomerCategory"/>'
				 ||'<move element="MicrNumber" after="SalesChannel"/>'
				 ||'<move element="OdCustomerType" after="MicrNumber"/>'
				 ||'<move element="ShipToSequenceNum" after="OdCustomerType"/>'
				 ||'<move element="BillingNumber" after="ShipToSequenceNum"/>'
				 ||'<move element="Classification" after="BillingNumber"/>'
				 ||'<move element="RelationshipRole" after="Classification"/>'
				 ||'<move element="ContactName" after="RelationshipRole"/>'
				 ||'<move element="LegacyNumber" after="ContactName"/>'
				 ||'<move element="SalesPerson" after="LegacyNumber"/>'
				 ||'<move element="SalesPersonResourceId" after="SalesPerson"/>'
				 ||'<move element="ClassCodeValue" after="SalesPersonResourceId"/>'
                                 ||'<move element="ClassCategoryValue" after="ClassCodeValue"/>'
                                 ||'</modifications></view>';
	   utl_file.put_line     (lf_file, 
      	                          lc_xml_salesrep_string);      	
           ln_count              := ln_count +1;
           utl_file.put_line     (lf_err_file,
                                  RPAD (l_get_mgr_adm_details_rec.resource_name, 36)
                                 || CHR(9)
                                 || RPAD (l_manager_directs_rec.resource_name, 104)
                                 || CHR(9)
                                 || RPAD ('Success', 24));              
      	   END;
        END LOOP;
        x_rep_count             := ln_count - 1;        
        lc_xml_string            := '</views></customization>';
        utl_file.put_line        (lf_file, 
      	                          lc_xml_string); 
        utl_file.fclose          (lf_file);
        x_file_list_tbl          (ln_mgr_adm_count)
                                 := lc_filename;
        ln_mgr_adm_count         := ln_mgr_adm_count + 1; 
        IF(x_rep_count=0) THEN
           utl_file.put_line     (lf_err_file,
                                  RPAD (l_get_mgr_adm_details_rec.resource_name, 36)
                                 || CHR(9)
                                 || RPAD ('No Salespeople assigned. Empty XML Generated.', 104)
                                 || CHR(9)
                                 || RPAD ('Success', 24));        
        END IF;        
      END LOOP;
      IF(lc_is_user_data_found='N') THEN
      	RAISE EX_CRM_FND_USER_UNSYNC;
      END IF;       
   EXCEPTION
      WHEN EX_MULTIPLE_GRPS_WITH_RES
      THEN
         ROLLBACK;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_SFA_0101_MULT_GRPS_FOR_RES');
         fnd_message.set_token   ('RESOURCE_NAME', lc_resource_name);         
         lc_message_data         := fnd_message.get;
         log_error
                                 (p_prog_name      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_CUST_XML',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_CUST_XML',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_SFA_0101_MULT_GRPS_FOR_RES'
                                 );
         lc_errmsg               := 'Procedure: GENERATE_CUST_XML: ' || lc_message_data;
         lc_message_data         := substr(lc_message_data,1,instr(lc_message_data,':')-1);
         utl_file.put_line       (lf_err_file,
                                  RPAD (lc_resource_name, 36)
                                 || CHR(9)
                                 || RPAD (lc_message_data, 104)
                                 || CHR(9)
                                 || RPAD ('Failure', 24));  
         gn_failed_mgrs          := gn_failed_mgrs + 1;                        
         WHEN EX_CRM_FND_USER_UNSYNC
         THEN
         ROLLBACK;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_SFA_0102_CRM_FND_UNSYNC');
         fnd_message.set_token   ('RESOURCE_NAME', lc_resource_name);         
         lc_message_data         := fnd_message.get;
         log_error
                                 (p_prog_name      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_CUST_XML',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_PERZ_GEN_PKG.GENERATE_CUST_XML',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_SFA_0102_CRM_FND_UNSYNC'
                                 );
         lc_errmsg               := 'Procedure: GENERATE_CUST_XML: ' || lc_message_data;
         lc_message_data         := substr(lc_message_data,1,instr(lc_message_data,':')-1);
         utl_file.put_line       (lf_err_file,
                                  RPAD (lc_resource_name, 36)
                                 || CHR(9)
                                 || RPAD (lc_message_data, 104)
                                 || CHR(9)
                                 || RPAD ('Failure', 24));  
         gn_failed_mgrs          := gn_failed_mgrs + 1;                        
   END generate_cust_xml;  

-- +===========================================================================================================+
-- | Name        :  create_perz_main
-- | Description :  This procedure is used to generate the User Personalizations in ASN for Managers(DSMs) and  
-- |                Proxy Administrators.
-- |                This gets called from the following Conc Programs: 
-- |                1) OD: SFA Upload Customer Personalizations Program
-- |                2) OD: SFA Upload Opportunity Personalizations Program
-- |                3) OD: SFA Upload Lead Personalizations Program
-- | Parameters  :  p_person_id    IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
-- |                p_lead_status  IN as_statuses_b.status_code%TYPE,
-- |                p_oppty_status IN as_statuses_b.status_code%TYPE,
-- |                p_perz_type    IN VARCHAR2
-- +===========================================================================================================+  

   PROCEDURE create_perz_main (
    p_person_id    IN per_all_people_f.person_id%TYPE,
    p_lead_status  IN as_statuses_b.status_code%TYPE,
    p_oppty_status IN as_statuses_b.status_code%TYPE,
    p_perz_type    IN VARCHAR2) 
   IS 
---------------------------------------------------
--Cursor to obtain the list of DSMs for processing
---------------------------------------------------
      CURSOR lcu_get_dsm_list 
      IS
	   SELECT f.person_id 
	     FROM 
	   (SELECT  PAAF.person_id  PERSON_ID
	      FROM  (SELECT *
		       FROM per_all_assignments_f p
		      WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PAAF
		  , (SELECT *
		       FROM per_all_people_f p
		      WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PAPF
		  ,  per_person_types  PPT
		  , (SELECT *
		       FROM per_person_type_usages_f p
		      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
		  ,  jtf_rs_resource_extns_vl r
	      WHERE    PAAF.person_id               = PAPF.person_id
		AND    PAPF.person_id               = PPTU.person_id
		AND    PPT. person_type_id          = PPTU.person_type_id
		AND    PPT.system_person_type       = 'EMP'
		AND    PAAF.business_group_id       = 0
		AND    PAPF.business_group_id       = 0
		AND    PPT .business_group_id       = 0
		AND    r.source_id                  = PAAF.person_id
	 CONNECT BY 
	      PRIOR    PAAF.person_id               = PAAF.supervisor_id
	 START WITH    PAAF.person_id               = p_person_id) f
	 WHERE EXISTS (SELECT   RO.MANAGER_FLAG  
			 FROM   JTF_RS_ROLE_RELATIONS 	RR 
			      , JTF_RS_ROLES_B 		RO 
			      , JTF_RS_RESOURCE_EXTNS 	R
			      , JTF_RS_GROUP_MBR_ROLE_VL GR
			      , JTF_RS_GROUP_USAGES 	U
			      , JTF_RS_GROUP_MEMBERS 	jgm
			WHERE r.source_id=f.person_id 
			  AND rr.role_resource_type = G_GRP_MBR_TYPE 
			  AND rr.start_date_active <= sysdate 
			  AND (rr.end_date_active >= sysdate or rr.end_date_active is null) 
			  AND rr.role_id = ro.role_id 
			  AND ro.role_type_code = G_ROLE_TYPE 
			  AND gr.resource_id=r.resource_id 
			  AND gr.role_id=ro.role_id 
			  AND u.group_id=gr.group_id 
			  AND u.usage=G_ROLE_TYPE
			  AND rr.delete_flag=G_NO
			  AND rr.role_resource_id = jgm.group_member_id
			  AND r.resource_id = jgm.resource_id 
			  AND jgm.delete_flag=G_NO 
			  AND ro.manager_flag=G_YES
			  AND ro.attribute14=G_MGR_TYPE);
   lt_file_list_tbl       xx_file_list_tbl_type;
   lf_file                utl_file.file_type;
   lf_err_file            utl_file.file_type;
   lc_perz_entity         VARCHAR2(48);
   ln_mgr_adm_count       NUMBER                := 0;
   ln_rep_count           NUMBER                := 0;
   ln_saved_srch_count    NUMBER                := 0;
   BEGIN 
-------------------------------------------------------------------
--Master file that contains list of generated Personalization files
-------------------------------------------------------------------
   lf_file 	                                := UTL_FILE.FOPEN(location        => 'CRM_FILE_LOCATION',
                                                                  filename        => 'OD_SFA_PerzList.txt',
                                                                  open_mode       => 'W',
                                                                  max_linesize    => 32767);
---------------------
--Master Error file
---------------------                                                                 
   lf_err_file                                  := UTL_FILE.FOPEN(location        => 'CRM_FILE_LOCATION',
                                                                  filename        => 'OD_SFA_ErrList.txt',
                                                                  open_mode       => 'W',
                                                                  max_linesize    => 32767);
   utl_file.put_line                            (lf_err_file,
                                                 RPAD (' Office Depot', 140)|| 'Date:'|| SYSDATE);
   utl_file.put_line                            (lf_err_file,
                                                 LPAD ('OD SFA Personalization Program',110)|| LPAD ('Page:1', 36)); 
   utl_file.put_line                            (lf_err_file,
                                                 ' '); 
   utl_file.put_line                            (lf_err_file,
                                                 ' ');
   utl_file.put_line                            (lf_err_file,
                                                 ' '); 
   IF    (p_perz_type = 'LEAD') THEN
         lc_perz_entity := 'Lead';
   ELSIF (p_perz_type = 'OPPTY') THEN
         lc_perz_entity := 'Opportunity';
   ELSIF (p_perz_type = 'CUST') THEN
         lc_perz_entity := 'Customer';    
   END IF;
   utl_file.put_line                            (lf_err_file,
                                                 'Personalization Mode: ' || lc_perz_entity);  
   utl_file.put_line                            (lf_err_file,
                                                 ' ');                                                  
   utl_file.put_line                            (lf_err_file,
                                                   RPAD ('Name of the DSM/Proxy Administrator', 36)
                                                || CHR(9)
                                              	|| RPAD ('Salesperson Name', 104)
                                              	|| CHR(9)
                                              	|| RPAD ('XML Generation Status', 24)); 
   utl_file.put_line                            (lf_err_file,
                                                 RPAD (' ', 175, '_')); 
   ln_mgr_adm_count                             := 0;
   ln_saved_srch_count                          := 0;
      for l_get_dsm_rec in lcu_get_dsm_list
      LOOP
      ------------------------------------------------------------------------------------------
      --The DSM Person_ID is passed to generate_lead_xml() and XML is generated for this DSM and 
      -- all the Proxy Administrators in the DSM group
      ------------------------------------------------------------------------------------------
      IF    (p_perz_type='LEAD')  THEN
         generate_lead_xml     (p_person_id     =>   l_get_dsm_rec.person_id,
                                p_lead_status   =>   p_lead_status,
                                lf_err_file     =>   lf_err_file,
                                x_file_list_tbl =>   lt_file_list_tbl,
                                x_rep_count     =>   ln_rep_count
                                );
         IF(lt_file_list_tbl.COUNT > 0) THEN
	 FOR idx IN lt_file_list_tbl.FIRST .. lt_file_list_tbl.LAST
         LOOP
            utl_file.put_line                   (lf_file, 
      	                                         lt_file_list_tbl(idx));
         END LOOP;
         ln_mgr_adm_count                       := ln_mgr_adm_count + lt_file_list_tbl.COUNT;
         ln_saved_srch_count                    := ln_saved_srch_count + (lt_file_list_tbl.COUNT * ln_rep_count);
         END IF;
      ------------------------------------------------------------------------------------------
      --The DSM Person_ID is passed to generate_oppty_xml() and XML is generated for this DSM and 
      -- all the Proxy Administrators in the DSM group
      -------------------------------------------------------------------------------------------       
      ELSIF(p_perz_type='OPPTY') THEN
         generate_oppty_xml    (p_person_id     =>   l_get_dsm_rec.person_id,
                                p_oppty_status  =>   p_oppty_status,
                                lf_err_file     =>   lf_err_file,
                                x_file_list_tbl =>   lt_file_list_tbl,
                                x_rep_count     =>   ln_rep_count
                                ); 
         IF(lt_file_list_tbl.COUNT > 0) THEN
	 FOR idx IN lt_file_list_tbl.FIRST .. lt_file_list_tbl.LAST
         LOOP
            utl_file.put_line                   (lf_file, 
      	                                         lt_file_list_tbl(idx));
         END LOOP;
         ln_mgr_adm_count                       := ln_mgr_adm_count + lt_file_list_tbl.COUNT;
         ln_saved_srch_count                    := ln_saved_srch_count + (lt_file_list_tbl.COUNT * ln_rep_count);         
         END IF; 
      ------------------------------------------------------------------------------------------
      --The DSM Person_ID is passed to generate_cust_xml() and XML is generated for this DSM and 
      -- all the Proxy Administrators in the DSM group
      -------------------------------------------------------------------------------------------         
      ELSIF (p_perz_type='CUST') THEN
         generate_cust_xml     (p_person_id     =>   l_get_dsm_rec.person_id,
                                lf_err_file     =>   lf_err_file,
                                x_file_list_tbl =>   lt_file_list_tbl,
                                x_rep_count     =>   ln_rep_count
                                );
         IF(lt_file_list_tbl.COUNT > 0) THEN
	 FOR idx IN lt_file_list_tbl.FIRST .. lt_file_list_tbl.LAST
         LOOP
            utl_file.put_line                   (lf_file, 
      	                                         lt_file_list_tbl(idx));
         END LOOP;
         ln_mgr_adm_count                       := ln_mgr_adm_count + lt_file_list_tbl.COUNT;
         ln_saved_srch_count                    := ln_saved_srch_count + (lt_file_list_tbl.COUNT * ln_rep_count);         
         END IF;
      END IF;
      END LOOP;
   utl_file.put_line                            (lf_err_file,
                                                 'Total Number of DSMs/Proxy Administrators Identified  : ' || LPAD((ln_mgr_adm_count+gn_failed_mgrs),15));      
   utl_file.put_line                            (lf_err_file,
                                                 'Total Number of DSMs/Proxy Administrators Processed   : ' || LPAD(ln_mgr_adm_count,15)); 
   utl_file.put_line                            (lf_err_file,
                                                 'Total Number of DSMs/Proxy Administrators Failed      : ' || LPAD(gn_failed_mgrs,15));                                                 
   utl_file.put_line                            (lf_err_file,
                                                 'Total Number of Saved Searches Created                : ' || LPAD(ln_saved_srch_count,15));                                                  
   utl_file.fclose                              (lf_file);
   utl_file.fclose                              (lf_err_file);
   END;
END XX_SFA_PERZ_GEN_PKG;
/

SHOW ERRORS
EXIT;