SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_SFA_OPPTY_RPT_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_SFA_OPPTY_RPT_PKG                                              |
-- |                                                                                |
-- | Description:  This procedure prints all the Opportunities in the system.       |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A  09-FEB-2010 Sarah Maria Justina        Initial draft version          |
-- |DRAFT 1   19-APR-2010 Nabarun                    Added IMU%                     |
-- |DRAFT 1.1 28-APR-2010 Nabarun                    Modified the approach to derive|
-- |                                                 the DSM/RSD/VP name            |
-- |DRAFT 2   11-NOV-2010 Devi Viswanathan           Fix for defect 8062.           |
-- |DRAFT 3   07-JAN-2011 Parameswaran S N           Fix for defect 9280            |
-- |DRAFT 4   24-JAN-2011 Parameswaran S N           Fix for defect 9794            |
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
----------------------------
--Declaring Global Constants
----------------------------
   G_MODULE_NAME   CONSTANT VARCHAR2 (50)           := 'SFA';
   G_NOTIFY        CONSTANT VARCHAR2 (1)            := 'Y';
   G_ERROR_STATUS  CONSTANT VARCHAR2 (10)           := 'ACTIVE';
   G_MAJOR         CONSTANT VARCHAR2 (15)           := 'MAJOR';
   G_MINOR         CONSTANT VARCHAR2 (15)           := 'MINOR';
   G_PROG_TYPE     CONSTANT VARCHAR2(100)           := 'OD: SFA All Opportunities Report';
   G_NO            CONSTANT VARCHAR2 (1)            := 'N';
   G_YES           CONSTANT VARCHAR2 (1)            := 'Y';

----------------------------
--Declaring Global Variables
----------------------------


-- +====================================================================+
-- | Name        :  DISPLAY_LOG                                         |
-- | Description :  This procedure is invoked to print in the Log       |
-- |                file                                                |
-- | Parameters  :  p_message IN VARCHAR2                               |
-- +====================================================================+

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

-- +========================================================================+
-- | Name        :  Get_DSM_RSD_VP                                          |
-- |                                                                        |
-- | Description :  This function will derive the DSM , RSD or VP Name      |
-- |                 for the resource Group  .                              |
-- |                                                                        |
-- | Parameters  :                                                          |
-- |                p_group_id  IN NUMBER                                   |
-- | RETURN  Varchar2                                                       |
-- +========================================================================+
FUNCTION Get_DSM_RSD_VP (
                          p_group_id       IN NUMBER
                         ,p_name           IN VARCHAR2
                         ,p_asgn_source_id IN NUMBER
                        )
RETURN VARCHAR2
AS

  lc_sqlerrm  VARCHAR2(500);
  lc_name     VARCHAR2(2500);


BEGIN
        lc_name := NULL;

        BEGIN

          IF p_name = 'DSM' THEN

            SELECT r.source_name
            INTO   lc_name
    	    FROM apps.JTF_RS_ROLE_RELATIONS RR ,
    		 apps.JTF_RS_ROLES_B RO ,
    		 apps.JTF_RS_RESOURCE_EXTNS R ,
    		 apps.JTF_RS_GROUP_MBR_ROLE_VL GR ,
    		 apps.JTF_RS_GROUP_USAGES U ,
    		 apps.JTF_RS_GROUP_MEMBERS jgm

    	    WHERE rr.role_resource_type   = 'RS_GROUP_MEMBER'
    	    AND   rr.start_date_active   <= sysdate
    	    AND  (   rr.end_date_active  >= sysdate
    		  OR rr.end_date_active  IS NULL)
    	    AND rr.role_id              = ro.role_id
    	    AND ro.role_type_code       = 'SALES'
    	    AND gr.resource_id          = r.resource_id
    	    AND gr.role_id              = ro.role_id
    	    AND u.group_id              = gr.group_id
    	    AND u.usage                 = 'SALES'
    	    AND rr.delete_flag          = 'N'
    	    AND rr.role_resource_id     = jgm.group_member_id
    	    AND GR.group_id             = p_group_id    ---CURR_ASSN.group_id
    	    AND r.resource_id           = jgm.resource_id
    	    AND jgm.delete_flag         = 'N'
	    AND ro.attribute14          = p_name
	    AND rownum                  = 1;

          ELSIF p_name = 'RSD' THEN


             SELECT r.source_name
             INTO   lc_name
	     FROM   JTF_RS_ROLE_RELATIONS RR ,
	            JTF_RS_ROLES_B RO ,
	            JTF_RS_RESOURCE_EXTNS R ,
	            JTF_RS_GROUP_MBR_ROLE_VL GR ,
	            JTF_RS_GROUP_USAGES U ,
	            JTF_RS_GROUP_MEMBERS jgm
	     WHERE rr.role_resource_type = 'RS_GROUP_MEMBER'
	     AND rr.start_date_active   <= sysdate
	     AND (rr.end_date_active    >= sysdate
	     OR rr.end_date_active      IS NULL)
	     AND rr.role_id              = ro.role_id
	     AND ro.role_type_code       = 'SALES'
	     AND gr.resource_id          =r.resource_id
	     AND gr.role_id              =ro.role_id
	     AND u.group_id              =gr.group_id
	     AND u.usage                 ='SALES'
	     AND rr.delete_flag          ='N'
	     AND rr.role_resource_id     = jgm.group_member_id
	     AND r.resource_id           = jgm.resource_id
	     AND jgm.delete_flag         ='N'
	     AND ro.attribute14          ='RSD'
	     AND ROWNUM                  = 1
	     AND r.source_id            IN
	                                   (SELECT PAAF.person_id PERSON_ID
	                                    FROM
	                                        (SELECT *
	                                         FROM per_all_assignments_f p
	                                         WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	                                        ) PAAF ,
	                                        (SELECT *
	                                         FROM per_all_people_f p
	                                         WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	                                        ) PAPF ,
	                                        per_person_types PPT ,
	                                        (SELECT *
	                                         FROM per_person_type_usages_f p
	                                         WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	                                        ) PPTU ,
	                                        jtf_rs_resource_extns_vl r
	                                    WHERE PAAF.person_id                  = PAPF.person_id
	                                    AND PAPF.person_id                    = PPTU.person_id
	                                    AND PPT. person_type_id               = PPTU.person_type_id
	                                    AND PPT.system_person_type            = 'EMP'
	                                    AND PAAF.business_group_id            = 0
	                                    AND PAPF.business_group_id            = 0
	                                    AND PPT .business_group_id            = 0
	                                    AND r.source_id                       = PAAF.person_id
	                                    CONNECT BY PRIOR PAAF.supervisor_id = PAAF.person_id
	                                    START WITH PAAF.person_id           = p_asgn_source_id
	                                  );

	                /*
	                SELECT r.source_name
	                INTO   lc_name
	        	    FROM apps.JTF_RS_ROLE_RELATIONS RR ,
	        		 apps.JTF_RS_ROLES_B RO ,
	        		 apps.JTF_RS_RESOURCE_EXTNS R ,
	        		 apps.JTF_RS_GROUP_MBR_ROLE_VL GR ,
	        		 apps.JTF_RS_GROUP_USAGES U ,
	        		 apps.JTF_RS_GROUP_MEMBERS jgm

	        	    WHERE rr.role_resource_type   = 'RS_GROUP_MEMBER'
	        	    AND   rr.start_date_active   <= sysdate
	        	    AND  (   rr.end_date_active  >= sysdate
	        		  OR rr.end_date_active  IS NULL)
	        	    AND rr.role_id              = ro.role_id
	        	    AND ro.role_type_code       = 'SALES'
	        	    AND gr.resource_id          = r.resource_id
	        	    AND gr.role_id              = ro.role_id
	        	    AND u.group_id              = gr.group_id
	        	    AND u.usage                 = 'SALES'
	        	    AND rr.delete_flag          = 'N'
	        	    AND rr.role_resource_id     = jgm.group_member_id
	        	    AND GR.group_id             = p_group_id    ---CURR_ASSN.group_id
	        	    AND r.resource_id           = jgm.resource_id
	        	    AND jgm.delete_flag         = 'N'
	    	    AND ro.attribute14         IN ('VP','RVP')
	    	    AND rownum                  = 1;
	                */


          ELSIF p_name = 'VP' THEN

            SELECT r.source_name
            INTO   lc_name
	    FROM JTF_RS_ROLE_RELATIONS RR ,
	    	 JTF_RS_ROLES_B RO ,
	    	 JTF_RS_RESOURCE_EXTNS R ,
	    	 JTF_RS_GROUP_MBR_ROLE_VL GR ,
	    	 JTF_RS_GROUP_USAGES U ,
	    	 JTF_RS_GROUP_MEMBERS jgm
	    WHERE rr.role_resource_type = 'RS_GROUP_MEMBER'
	    AND  rr.start_date_active   <= sysdate
	    AND  (rr.end_date_active    >= sysdate
	         OR rr.end_date_active      IS NULL)
	    AND  rr.role_id              = ro.role_id
	    AND  ro.role_type_code       = 'SALES'
	    AND  gr.resource_id          =r.resource_id
	    AND  gr.role_id              =ro.role_id
	    AND  u.group_id              =gr.group_id
	    AND  u.usage                 ='SALES'
	    AND  rr.delete_flag          ='N'
	    AND  rr.role_resource_id     = jgm.group_member_id
	    AND  r.resource_id           = jgm.resource_id
	    AND  jgm.delete_flag         ='N'
	    AND  ro.attribute14         IN ('VP','RVP')
	    AND  rownum                  = 1
	    AND  r.source_id            IN
	    	                          (SELECT PAAF.person_id PERSON_ID
	    	                           FROM
	    	                               (SELECT *
	    	                                FROM per_all_assignments_f p
	    	                                WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	    	                               ) PAAF ,
	    	                               (SELECT *
	    	                                FROM per_all_people_f p
	    	                                WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	    	                               ) PAPF ,
	    	                               per_person_types PPT ,
	    	                               (SELECT *
	    	                                FROM per_person_type_usages_f p
	    	                                WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	    	                               ) PPTU ,
	    	                               jtf_rs_resource_extns_vl r
	    	                           WHERE PAAF.person_id                  = PAPF.person_id
	    	                           AND PAPF.person_id                    = PPTU.person_id
	    	                           AND PPT. person_type_id               = PPTU.person_type_id
	    	                           AND PPT.system_person_type            = 'EMP'
	    	                           AND PAAF.business_group_id            = 0
	    	                           AND PAPF.business_group_id            = 0
	    	                           AND PPT .business_group_id            = 0
	    	                           AND r.source_id                       = PAAF.person_id
	    	                           CONNECT BY PRIOR PAAF.supervisor_id   = PAAF.person_id
	    	                           START WITH PAAF.person_id             = p_asgn_source_id
	                                  );

          END IF;


	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
	    lc_name := NULL;
	    RETURN lc_name;
	  WHEN OTHERS THEN
	    lc_sqlerrm := SUBSTR(SQLERRM,1,250);
	    lc_name := 'Error in deriving: '||p_name||'  :'||lc_sqlerrm;
	END Get_DSM_RSD_VP;

        RETURN lc_name;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    lc_name := NULL;
    RETURN lc_name;
  WHEN OTHERS THEN
    lc_sqlerrm := SUBSTR(SQLERRM,1,250);
    lc_name := 'Error in deriving: '||p_name||'  :'||lc_sqlerrm;
    RETURN lc_name;
END Get_DSM_RSD_VP;

-- +===========================================================================================================+
-- | Name        :  extract_main
-- | Description :  This procedure is used to extract AR Data.
-- | Parameters  :  x_errbuf       OUT   VARCHAR2,
-- |            x_retcode      OUT   NUMBER,
-- |            p_start_date         VARCHAR2,
-- |            p_end_date           VARCHAR2,
-- |                p_mode               VARCHAR2
-- +===========================================================================================================+
   PROCEDURE report_main (
      x_errbuf       OUT   VARCHAR2,
      x_retcode      OUT   NUMBER,
      p_close_date         VARCHAR2 DEFAULT NULL,
      p_create_date        VARCHAR2 DEFAULT NULL,
      p_status             VARCHAR2 DEFAULT NULL,
      p_status_cat         VARCHAR2 DEFAULT NULL
   )
   IS
      ld_create_date           DATE  := NULL;
      ld_close_date            DATE  := NULL;
      ln_trx_count             NUMBER;
      ln_message_code          NUMBER;
      lc_lead_number           NUMBER; --Added for defect# 9280
      lP_lead_number           NUMBER; --Added for defect# 9280
      lc_message_data          VARCHAR2 (4000);
      lt_oppty_tbl_type        xx_sfa_oppty_tbl_type;
      lt_oppty_dtls_type       xx_sfa_oppty_details_t;

      L_LIMIT_SIZE             CONSTANT PLS_INTEGER               := 10000;

      CURSOR lcu_opportunity
      IS
        SELECT opp.lead_id
              ,opp.lead_number
        FROM   as_leads opp,
               xx_tm_nam_terr_curr_assign_v curr_assn
        WHERE curr_assn.entity_type     = 'OPPORTUNITY'
        AND curr_assn.entity_id         = opp.lead_number ;

      --Added for defect# 9280 to pull the CUST and SHIPTO based on CUSTOMER AND PROSPECT
      CURSOR lc_pros_cust (lc_lead_number NUMBER, lp_lead_number NUMBER)
      IS
      select
            substr(HZOS.orig_system_reference,1,8) CUST,
	    substr(HZOS.orig_system_reference,10,5) SHIPTO
	    from
	    apps.as_leads_all OPP,
	    apps.HZ_PARTIES HZP,
	    apps.hz_party_sites HZPS,
	    apps.HZ_CUST_ACCT_SITES_ALL HZAS,
	    (select * from apps.HZ_ORIG_SYS_REFERENCES where owner_table_name = 'HZ_CUST_ACCT_SITES_ALL') HZOS
	    WHERE
	    OPP.customer_id = HZP.party_id
	    and OPP.address_id = HZPS.party_site_id
	    and HZAS.party_site_id = HZPS.party_site_id (+)
	    and HZOS.owner_table_id(+) = HZAS.cust_acct_site_id
	    and opp.lead_number = lc_lead_number
	    UNION
	    select
	    HZP.party_number CUST,
	    HZPS.party_site_number SHIPTO
	    from
	    apps.as_leads_all OPP,
	    apps.HZ_PARTIES HZP,
	    apps.hz_party_sites HZPS
	    WHERE
	    HZP.attribute13 = 'PROSPECT'
	    and OPP.customer_id = HZP.party_id
	    and OPP.address_id = HZPS.party_site_id
	    and opp.lead_number = lp_lead_number;

      CURSOR lcu_get_oppty_rpt(a_create_date DATE,a_close_date DATE,a_status_cat VARCHAR2,a_status VARCHAR2,a_oppty_id NUMBER)
      IS
	SELECT opp.created_by AS created_by_id,
	  opp.lead_id lead_id,
	  decode(res.category,'EMPLOYEE',res.source_number,res.user_name) employee_id,
	  res.source_name AS created_by,
	  opp.creation_date creation_date,
	  opp.lead_number AS opp_number,
	  opp.description AS opp_name,
	  opp.customer_id,
	  hp.party_name  AS party_name,
	  hp.party_number AS party_number, --Added for defect# 9794
	  hps.party_site_number AS party_site_number, --Added for defect# 9794
	  hp.attribute13 AS prospect_customer,
	  opp.address_id,
	  hz_format_pub.format_address(hl.location_id, NULL, NULL, ', ', NULL, NULL,NULL, NULL) AS address,
	  opp.source_promotion_id,
	  src.name AS source ,
	  product.total_amount,
	  --Defect-4999 , Added IMU_PERCENTAGE by Nabarun, 19-Apr-2010
	  product.imu_percentage,
	  opp.win_probability,
	  GREATEST(opp.last_update_date,NVL(XXACT.last_activity_date,opp.last_update_date)) AS last_update_date,
	  opp.decision_date AS close_date,
	  opp.status,
	  opp.close_reason,
	  contact.party_name AS opp_primary_contact,
	  product.product_category,
	  competitors.competitor_name,
          DECODE(status.win_loss_indicator,'L','Lost','W','Won','N','Neither','Neither') AS status_category,
	  decode(asgn_res.category,'EMPLOYEE',asgn_res.source_number,asgn_res.user_name)        AS salespersonempid,
	  asgn_res.source_name      AS salesperson,
	  r.role_name               AS salesrep_role,
	  g.group_name              AS salesrep_group,
	  asgn_res.source_id        AS source_id,
	  /* Added by Nabarun as on 28-Apr-2010 */
	  XX_SFA_OPPTY_RPT_PKG.Get_DSM_RSD_VP(curr_assn.group_id,'DSM',asgn_res.source_Id) dsm_name,
	  XX_SFA_OPPTY_RPT_PKG.Get_DSM_RSD_VP(curr_assn.group_id,'RSD',asgn_res.source_Id) rsd_name,
	  XX_SFA_OPPTY_RPT_PKG.Get_DSM_RSD_VP(curr_assn.group_id,'VP',asgn_res.source_Id)  vp_name
	  /* Commented by Nabarun as on 28-Apr-2010 , Fix to the error */
	  /*
	  (SELECT r.source_name
	  FROM JTF_RS_ROLE_RELATIONS RR ,
	    JTF_RS_ROLES_B RO ,
	    JTF_RS_RESOURCE_EXTNS R ,
	    JTF_RS_GROUP_MBR_ROLE_VL GR ,
	    JTF_RS_GROUP_USAGES U ,
	    JTF_RS_GROUP_MEMBERS jgm
	  WHERE rr.role_resource_type = 'RS_GROUP_MEMBER'
	  AND rr.start_date_active   <= sysdate
	  AND (rr.end_date_active    >= sysdate
	  OR rr.end_date_active      IS NULL)
	  AND rr.role_id              = ro.role_id
	  AND ro.role_type_code       = 'SALES'
	  AND gr.resource_id          =r.resource_id
	  AND gr.role_id              =ro.role_id
	  AND u.group_id              =gr.group_id
	  AND u.usage                 ='SALES'
	  AND rr.delete_flag          ='N'
	  AND rr.role_resource_id     = jgm.group_member_id
	  AND r.resource_id           = jgm.resource_id
	  AND jgm.delete_flag         ='N'
	  AND ro.attribute14          ='DSM'
	  AND r.source_id            IN
	    (SELECT PAAF.person_id PERSON_ID
	    FROM
	      (SELECT *
	      FROM per_all_assignments_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PAAF ,
	      (SELECT *
	      FROM per_all_people_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PAPF ,
	      per_person_types PPT ,
	      (SELECT *
	      FROM per_person_type_usages_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PPTU ,
	      jtf_rs_resource_extns_vl r
	    WHERE PAAF.person_id                  = PAPF.person_id
	    AND PAPF.person_id                    = PPTU.person_id
	    AND PPT. person_type_id               = PPTU.person_type_id
	    AND PPT.system_person_type            = 'EMP'
	    AND PAAF.business_group_id            = 0
	    AND PAPF.business_group_id            = 0
	    AND PPT .business_group_id            = 0
	    AND r.source_id                       = PAAF.person_id
	      CONNECT BY PRIOR PAAF.supervisor_id = PAAF.person_id
	      START WITH PAAF.person_id           = asgn_res.source_id
	    )
	  ) dsm_name,

	  (SELECT r.source_name
	  FROM JTF_RS_ROLE_RELATIONS RR ,
	    JTF_RS_ROLES_B RO ,
	    JTF_RS_RESOURCE_EXTNS R ,
	    JTF_RS_GROUP_MBR_ROLE_VL GR ,
	    JTF_RS_GROUP_USAGES U ,
	    JTF_RS_GROUP_MEMBERS jgm
	  WHERE rr.role_resource_type = 'RS_GROUP_MEMBER'
	  AND rr.start_date_active   <= sysdate
	  AND (rr.end_date_active    >= sysdate
	  OR rr.end_date_active      IS NULL)
	  AND rr.role_id              = ro.role_id
	  AND ro.role_type_code       = 'SALES'
	  AND gr.resource_id          =r.resource_id
	  AND gr.role_id              =ro.role_id
	  AND u.group_id              =gr.group_id
	  AND u.usage                 ='SALES'
	  AND rr.delete_flag          ='N'
	  AND rr.role_resource_id     = jgm.group_member_id
	  AND r.resource_id           = jgm.resource_id
	  AND jgm.delete_flag         ='N'
	  AND ro.attribute14          ='RSD'
	  AND rownum                  = 1
	  AND r.source_id            IN
	    (SELECT PAAF.person_id PERSON_ID
	    FROM
	      (SELECT *
	      FROM per_all_assignments_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PAAF ,
	      (SELECT *
	      FROM per_all_people_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PAPF ,
	      per_person_types PPT ,
	      (SELECT *
	      FROM per_person_type_usages_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PPTU ,
	      jtf_rs_resource_extns_vl r
	    WHERE PAAF.person_id                  = PAPF.person_id
	    AND PAPF.person_id                    = PPTU.person_id
	    AND PPT. person_type_id               = PPTU.person_type_id
	    AND PPT.system_person_type            = 'EMP'
	    AND PAAF.business_group_id            = 0
	    AND PAPF.business_group_id            = 0
	    AND PPT .business_group_id            = 0
	    AND r.source_id                       = PAAF.person_id
	      CONNECT BY PRIOR PAAF.supervisor_id = PAAF.person_id
	      START WITH PAAF.person_id           = asgn_res.source_id
	    )
	  ) rsd_name,

	  (SELECT r.source_name
	  FROM JTF_RS_ROLE_RELATIONS RR ,
	    JTF_RS_ROLES_B RO ,
	    JTF_RS_RESOURCE_EXTNS R ,
	    JTF_RS_GROUP_MBR_ROLE_VL GR ,
	    JTF_RS_GROUP_USAGES U ,
	    JTF_RS_GROUP_MEMBERS jgm
	  WHERE rr.role_resource_type = 'RS_GROUP_MEMBER'
	  AND rr.start_date_active   <= sysdate
	  AND (rr.end_date_active    >= sysdate
	  OR rr.end_date_active      IS NULL)
	  AND rr.role_id              = ro.role_id
	  AND ro.role_type_code       = 'SALES'
	  AND gr.resource_id          =r.resource_id
	  AND gr.role_id              =ro.role_id
	  AND u.group_id              =gr.group_id
	  AND u.usage                 ='SALES'
	  AND rr.delete_flag          ='N'
	  AND rr.role_resource_id     = jgm.group_member_id
	  AND r.resource_id           = jgm.resource_id
	  AND jgm.delete_flag         ='N'
	  AND ro.attribute14         IN ('VP','RVP')
	  AND rownum                  = 1
	  AND r.source_id            IN
	    (SELECT PAAF.person_id PERSON_ID
	    FROM
	      (SELECT *
	      FROM per_all_assignments_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PAAF ,
	      (SELECT *
	      FROM per_all_people_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PAPF ,
	      per_person_types PPT ,
	      (SELECT *
	      FROM per_person_type_usages_f p
	      WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	      ) PPTU ,
	      jtf_rs_resource_extns_vl r
	    WHERE PAAF.person_id                  = PAPF.person_id
	    AND PAPF.person_id                    = PPTU.person_id
	    AND PPT. person_type_id               = PPTU.person_type_id
	    AND PPT.system_person_type            = 'EMP'
	    AND PAAF.business_group_id            = 0
	    AND PAPF.business_group_id            = 0
	    AND PPT .business_group_id            = 0
	    AND r.source_id                       = PAAF.person_id
	      CONNECT BY PRIOR PAAF.supervisor_id = PAAF.person_id
	      START WITH PAAF.person_id           = asgn_res.source_id
	    )
	  ) vp_name
	*/
	FROM as_leads opp,
	     XXCRM.xxbi_activities XXACT,  --update Last_activity_date
	  (SELECT amscv.source_code_id AS source_promotion_id,
	    amscv.source_code          AS SourceCode,
	    amscv.name ,
	    flv.meaning AS SourceType
	  FROM
	    (SELECT SOC.SOURCE_CODE_ID,
	      SOC.SOURCE_CODE,
	      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
	      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
	      CAMPT.CAMPAIGN_NAME NAME
	    FROM AMS_SOURCE_CODES SOC,
	      AMS_CAMPAIGNS_ALL_TL campt,
	      AMS_CAMPAIGNS_ALL_B campb
	    WHERE SOC.ARC_SOURCE_CODE_FOR = 'CAMP'
	    AND SOC.ACTIVE_FLAG           = 'Y'
	    AND SOC.SOURCE_CODE_FOR_ID    = CAMPB.CAMPAIGN_ID
	    AND CAMPB.CAMPAIGN_ID         = CAMPT.CAMPAIGN_ID
	    AND CAMPB.status_code        IN ('ACTIVE','COMPLETED')
	    AND campt.language            = USERENV('LANG')
	    UNION ALL
	    SELECT SOC.SOURCE_CODE_ID,
	      SOC.SOURCE_CODE,
	      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
	      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
	      EVEHT.EVENT_HEADER_NAME
	    FROM AMS_SOURCE_CODES SOC,
	      AMS_EVENT_HEADERS_all_b EVEHB,
	      AMS_EVENT_HEADERS_ALL_TL EVEHT
	    WHERE SOC.ARC_SOURCE_CODE_FOR = 'EVEH'
	    AND SOC.ACTIVE_FLAG           = 'Y'
	    AND SOC.SOURCE_CODE_FOR_ID    = EVEHB.EVENT_HEADER_ID
	    AND EVEHB.EVENT_HEADER_ID     = EVEHT.EVENT_HEADER_ID
	    AND EVEHB.system_status_code IN ('ACTIVE','COMPLETED')
	    AND eveht.language            = USERENV('LANG')
	    UNION ALL
	    SELECT SOC.SOURCE_CODE_ID,
	      SOC.SOURCE_CODE,
	      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
	      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
	      EVEOT.EVENT_OFFER_NAME
	    FROM AMS_SOURCE_CODES SOC,
	      AMS_EVENT_OFFERS_ALL_B EVEOB,
	      AMS_EVENT_OFFERS_ALL_TL EVEOT
	    WHERE SOC.ARC_SOURCE_CODE_FOR IN ('EVEO','EONE')
	    AND SOC.ACTIVE_FLAG            = 'Y'
	    AND SOC.SOURCE_CODE_FOR_ID     = EVEOB.EVENT_OFFER_ID
	    AND EVEOB.EVENT_OFFER_ID       = EVEOT.EVENT_OFFER_ID
	    AND EVEOB.system_status_code  IN ('ACTIVE','COMPLETED')
	    AND eveot.language             = USERENV('LANG')
	    UNION ALL
	    SELECT SOC.SOURCE_CODE_ID,
	      SOC.SOURCE_CODE,
	      SOC.ARC_SOURCE_CODE_FOR SOURCE_TYPE,
	      SOC.SOURCE_CODE_FOR_ID OBJECT_ID,
	      CHLST.SCHEDULE_NAME
	    FROM AMS_SOURCE_CODES SOC,
	      ams_campaign_schedules_tl CHLST,
	      ams_campaign_schedules_b CHLSB
	    WHERE SOC.ARC_SOURCE_CODE_FOR = 'CSCH'
	    AND SOC.ACTIVE_FLAG           = 'Y'
	    AND SOC.SOURCE_CODE_FOR_ID    = CHLSB.SCHEDULE_ID
	    AND CHLSB.SCHEDULE_ID         = CHLST.SCHEDULE_ID
	    AND CHLSB.status_code        IN ('ACTIVE','COMPLETED')
	    AND CHLST.language            = USERENV('LANG')
	    ) amscv,
	    fnd_lookup_values flv
	  WHERE flv.lookup_type       = 'AMS_SYS_ARC_QUALIFIER'
	  AND flv.language            = USERENV ('LANG')
	  AND flv.view_application_id = 530
	  AND flv.lookup_code         = amscv.source_type
	  ) src,
	  jtf_rs_resource_extns_vl res,
	  hz_parties hp,
	  hz_party_sites hps,
	  hz_locations hl,
	  (SELECT per.PARTY_name,
	    OpportunityContactEO.LEAD_ID
	  FROM as_lead_contacts_all OpportunityContactEO,
	    hz_person_profiles_cpui_v HzPuiPersonProfileEO,
	    hz_org_contacts_cpui_v HzPuiOrgContactsCpuiEO,
	    hz_contact_points HzPuiContactPointPhoneEO,
	    hz_relationships hr,
	    hz_parties per
	  WHERE OpportunityContactEO.contact_party_id        = HzPuiOrgContactsCpuiEO.relationship_party_id
	  AND HzPuiOrgContactsCpuiEO.object_id               = OpportunityContactEO.customer_id
	  AND HzPuiOrgContactsCpuiEO.object_table_name       = 'HZ_PARTIES'
	  AND HzPuiOrgContactsCpuiEO.subject_id              = HzPuiPersonProfileEO.party_id
	  AND HzPuiOrgContactsCpuiEO.subject_table_name      = 'HZ_PARTIES'
	  AND OpportunityContactEO.contact_party_id          = HzPuiContactPointPhoneEO.owner_table_id(+)
	  AND HzPuiContactPointPhoneEO.owner_table_name(+)   = 'HZ_PARTIES'
	  AND HzPuiContactPointPhoneEO.primary_flag(+)       = 'Y'
	  AND HzPuiContactPointPhoneEO.contact_point_type(+) = 'PHONE'
	  AND OpportunityContactEO.contact_party_id          = hr.party_id
	  AND OpportunityContactEO.customer_id               = hr.object_id
	  AND hr.object_table_name                           = 'HZ_PARTIES'
	  AND OpportunityContactEO.primary_contact_flag      ='Y'
	  AND per.party_id                                   = HzPuiPersonProfileEO.PARTY_ID
	  ) contact,
	  ---Added the AS_LEAD_LINES_ALL.Attribute1 by Nabarun, 19-Apr-2010 , Defect 4999
	  (SELECT OpportunityLineEO.lead_id,
	    OpportunityLineEO.lead_line_id lead_line_id,
	    OpportunityLineEO.inventory_item_id,
	    NVL(msit.description,mct.description) AS product_category,
	    mskfv.concatenated_segments           AS item_number,
	    OpportunityLineEO.total_amount,
	    -- Modified for Defect 8062- Begin
	    -- COALESCE(CAST(OpportunityLineEO.Attribute1 AS NUMBER),0) AS imu_percentage
	    COALESCE(OpportunityLineEO.Attribute1,'0') imu_percentage
	    -- Modified for Defect 8062- End
	  FROM as_lead_lines_all OpportunityLineEO,
	    mtl_system_items_tl msit,
	    mtl_categories_tl mct,
	    mtl_system_items_b_kfv mskfv
	  WHERE OpportunityLineEO.inventory_item_id = msit.inventory_item_id(+)
	  AND OpportunityLineEO.organization_id     = msit.organization_id (+)
	  AND msit.language (+)                     = USERENV('LANG')
	  AND OpportunityLineEO.product_category_id = mct.category_id
	  AND mct.language                          = USERENV('LANG')
	  AND mskfv.inventory_item_id (+)           = msit.inventory_item_id
	  AND mskfv.organization_id (+)             = msit.organization_id
	  ) product,
	  (SELECT OpportunityCompProductEO.lead_competitor_prod_id,
	    OpportunityCompProductEO.lead_id,
	    OpportunityCompProductEO.lead_line_id,
	    OpportunityCompProductEO.competitor_product_id,
	    OpportunityCompProductEO.win_loss_status,
	    acpt.competitor_product_name,
	    hp.party_name competitor_name
	  FROM as_lead_comp_products OpportunityCompProductEO,
	    ams_competitor_products_tl acpt,
	    ams_competitor_products_b acpb,
	    hz_parties hp
	  WHERE OpportunityCompProductEO.competitor_product_id = acpt.competitor_product_id
	  AND acpt.competitor_product_id                       = acpb.competitor_product_id
	  AND acpt.language                                    = USERENV( 'LANG')
	  AND acpb.competitor_party_id                         = hp.party_id
	  ) competitors,
	  as_statuses_vl status,
	  XX_TM_NAM_TERR_CURR_ASSIGN_V CURR_ASSN,
	  jtf_rs_resource_extns_vl asgn_res,
	  jtf_rs_roles_vl r,
	  jtf_rs_groups_vl g
	WHERE opp.lead_id                                           = a_oppty_id
	AND   src.source_promotion_id(+)                            = opp.source_promotion_id
	AND   res.user_id                                           = opp.created_by
	AND   hp.party_id                                           = opp.customer_id
	AND   hps.party_site_id                                     = opp.address_id
	AND   hps.location_id                                       = hl.location_id
	AND   contact.LEAD_ID(+)                                    = opp.lead_id
	AND   product.lead_id(+)                                    = opp.lead_id
	AND   competitors.lead_line_id(+)                           = product.lead_line_id
	AND   status.status_code                                    = opp.status
	AND   curr_assn.entity_type                                 = 'OPPORTUNITY'
	AND   curr_assn.entity_id                                   = opp.lead_number
	AND   curr_assn.resource_id                                 = asgn_res.resource_id
	AND   curr_assn.resource_role_id                            = r.role_id
	AND   curr_assn.group_id                                    = g.group_id
	AND   TO_DATE(opp.creation_date,'DD-MON-RRRR')              = NVL(TO_DATE(a_create_date,'DD-MON-RRRR'),TO_DATE(opp.creation_date,'DD-MON-RRRR'))
	AND   TO_DATE(NVL(opp.decision_date,sysdate),'DD-MON-RRRR') = NVL(TO_DATE(a_close_date ,'DD-MON-RRRR'),TO_DATE(NVL(opp.decision_date,sysdate),'DD-MON-RRRR'))
	AND   opp.status                                            = NVL(a_status,opp.status)
	AND   status.win_loss_indicator                             = NVL(a_status_cat,status.win_loss_indicator)
	AND   opp.lead_id                                           = XXACT.source_id(+)    --update Last_activity_date
	AND   XXACT.source_type(+)                                  = 'OPPORTUNITY';     --update Last_activity_date

   BEGIN
      -------------------------------------------------------
      -- Obtaining Create and Close Dates
      -------------------------------------------------------
      IF p_create_date IS NOT NULL THEN
         ld_create_date                := fnd_date.canonical_to_date(p_create_date);
      END IF;
      IF p_close_date IS NOT NULL THEN
         ld_close_date                := fnd_date.canonical_to_date(p_close_date);
      END IF;
      -----------------------------------------------
      --Begin loop for BULK Insert
      -----------------------------------------------
      ln_trx_count := 0;
      display_out
              (
                 'Created By Employee ID'
	       || CHR(9)
	       ||'Created by Name'
	       || CHR(9)
	       ||'Created Date'
	       || CHR(9)
	       ||'Opp. No'
	       || CHR(9)
	       ||'Opportunity'
	       || CHR(9)
	       ||'Prospect/Customer'
	       || CHR(9)
	       ||'Prospect or Customer'
	       || CHR(9)
	       ||'AOPS Account ID' -- Added for defect 9280
	       || CHR(9)
	       ||'AOPS Ship To Seq ID' -- Added for defect 9280
	       || CHR(9)
	       ||'Party Number'  --Added for defect# 9794
	       || CHR(9)
	       ||'Party Site Number' --Added for defect# 9794
	       || CHR(9)
	       ||'Group' -- Added for defect 9280
	       || CHR(9)
	       ||'Address'
	       || CHR(9)
	       ||'Source'
               || CHR(9)
	       ||'Source ID' --Added for defect# 9794
	       || CHR(9)
	       ||'Amt'
	       || CHR(9)
	       --Defect-4999 , Added IMU_PERCENTAGE by Nabarun, 19-Apr-2010
	       ||'IMU%'
	       || CHR(9)
	       ||'Win Probability %'
	       || CHR(9)
	       ||'Last Update Date'
	       || CHR(9)
	       ||'Close Date'
	       || CHR(9)
	       ||'Status'
	       || CHR(9)
	       ||'Close Reason'
	       || CHR(9)
	       ||'Primary Contact'
	       || CHR(9)
	       ||'Product Name'
	       || CHR(9)
	       ||'Competitor Name'
	       || CHR(9)
	       ||'Status Category'
	       || CHR(9)
	       ||'Salesrep Emp ID'
               || CHR(9)
	       ||'Salesrep Name'
	       || CHR(9)
	       ||'Title (Role)'
	       || CHR(9)
	       ||'DSM Name'
	       || CHR(9)
	       ||'RSD Name'
	       || CHR(9)
	       ||'VP Name'
              );
     /*
      OPEN lcu_get_oppty_rpt(ld_create_date,ld_close_date,p_status_cat,p_status);
      LOOP
         -------------------------------------------------
         --Initializing table types and their indexes
         -------------------------------------------------

         lt_oppty_tbl_type.DELETE;
         FETCH lcu_get_oppty_rpt
         BULK COLLECT INTO lt_oppty_tbl_type LIMIT L_LIMIT_SIZE;

              display_log('Entered loop');
              display_log('Count:'||lt_oppty_tbl_type.COUNT);
	      --------------------------------------------------------------------
	      --Printing the Records
	      --------------------------------------------------------------------
	      IF(lt_oppty_tbl_type.COUNT > 0) THEN
	      FOR idx IN lt_oppty_tbl_type.FIRST .. lt_oppty_tbl_type.LAST
		  LOOP
		  display_out
		      (
			 lt_oppty_tbl_type(idx).employee_id
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).created_by
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).creation_date
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).opp_number
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).opp_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).party_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).prospect_customer
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).address
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).source
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).total_amount
		       || CHR(9)
		       --Defect-4999 , Added IMU_PERCENTAGE by Nabarun, 19-Apr-2010
		       ||NVL(lt_oppty_tbl_type(idx).imu_percentage,0)
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).win_probability
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).last_update_date
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).close_date
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).status
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).close_reason
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).opp_primary_contact
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).product_category
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).competitor_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).status_category
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).SALESPERSONEMPID
                       || CHR(9)
		       ||lt_oppty_tbl_type(idx).salesperson
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).salesrep_role
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).dsm_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).rsd_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).vp_name
		      );
	      END LOOP;
	      END IF;
      EXIT WHEN lcu_get_oppty_rpt%NOTFOUND;
      END LOOP;
      CLOSE lcu_get_oppty_rpt;

    */

     OPEN lcu_opportunity;
     LOOP

       lt_oppty_dtls_type.delete;

       FETCH lcu_opportunity
       BULK COLLECT INTO lt_oppty_dtls_type LIMIT L_LIMIT_SIZE;

       display_log('Entered in main loop');
       display_log('Count:'||lt_oppty_dtls_type.COUNT);


       IF(lt_oppty_dtls_type.COUNT > 0) THEN


         FOR idx IN lt_oppty_dtls_type.FIRST .. lt_oppty_dtls_type.LAST
         LOOP

	  lt_oppty_tbl_type.delete;

	  BEGIN

	    FND_FILE.put_line (FND_FILE.LOG, 'LEAD_ID: ' || lt_oppty_dtls_type(idx).lead_id);
	    OPEN lcu_get_oppty_rpt(ld_create_date,ld_close_date,p_status_cat,p_status,lt_oppty_dtls_type(idx).lead_id);
	    FETCH lcu_get_oppty_rpt
	    BULK COLLECT INTO lt_oppty_tbl_type;
	    CLOSE lcu_get_oppty_rpt;

	  EXCEPTION
	   WHEN OTHERS THEN
	      lc_message_data         := NULL;
	      ln_message_code         := -1;
	      fnd_message.set_name    ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
	      fnd_message.set_token   ('SQL_CODE', SQLCODE);
	      fnd_message.set_token   ('SQL_ERR', SQLERRM);
	      lc_message_data         := fnd_message.get;
              display_log(lc_message_data);

	      CLOSE lcu_get_oppty_rpt;

	  END;

	      IF(lt_oppty_tbl_type.COUNT > 0) THEN
	       FOR idx IN lt_oppty_tbl_type.FIRST .. lt_oppty_tbl_type.LAST
	       LOOP
	          FOR lcr_pros_cust in lc_pros_cust(lt_oppty_tbl_type(idx).opp_number,lt_oppty_tbl_type(idx).opp_number) --Added for defect# 9280
		  LOOP
		  display_out
		      (
			 lt_oppty_tbl_type(idx).employee_id
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).created_by
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).creation_date
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).opp_number
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).opp_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).party_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).prospect_customer
		       || CHR(9)
		       ||lcr_pros_cust.CUST --Added for defect# 9280
		       || CHR(9)
		       ||lcr_pros_cust.SHIPTO --Added for defect# 9280
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).party_number --Added for defect# 9794
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).party_site_number --Added for defect# 9794
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).salesrep_group --Added for defect# 9280
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).address
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).source
		       || CHR (9)
		       ||lt_oppty_tbl_type(idx).source_id --Added for defect# 9794
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).total_amount
		       || CHR(9)
		       --Defect-4999 , Added IMU_PERCENTAGE by Nabarun, 19-Apr-2010
		       ||NVL(lt_oppty_tbl_type(idx).imu_percentage,0)
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).win_probability
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).last_update_date
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).close_date
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).status
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).close_reason
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).opp_primary_contact
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).product_category
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).competitor_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).status_category
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).SALESPERSONEMPID
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).salesperson
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).salesrep_role
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).dsm_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).rsd_name
		       || CHR(9)
		       ||lt_oppty_tbl_type(idx).vp_name
		      );
                  END LOOP; 
	       END LOOP;
	      END IF;


         END LOOP;


       END IF;

       EXIT WHEN lcu_opportunity%NOTFOUND;

     END LOOP;
     CLOSE lcu_opportunity;



   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         lc_message_data         := NULL;
         ln_message_code         := -1;
         fnd_message.set_name    ('XXCRM', 'XX_OIC_0010_UNEXPECTED_ERR');
         fnd_message.set_token   ('SQL_CODE', SQLCODE);
         fnd_message.set_token   ('SQL_ERR', SQLERRM);
         lc_message_data         := fnd_message.get;
         display_log(lc_message_data);
         log_error
                                 (p_prog_name      => 'XX_SFA_OPPTY_RPT_PKG.REPORT_MAIN',
                                  p_prog_type      => G_PROG_TYPE,
                                  p_prog_id        => FND_GLOBAL.conc_request_id,
                                  p_exception      => 'XX_SFA_OPPTY_RPT_PKG.REPORT_MAIN',
                                  p_message        => lc_message_data,
                                  p_code           => ln_message_code,
                                  p_err_code       => 'XX_OIC_0010_UNEXPECTED_ERR'
                                 );

         CLOSE lcu_get_oppty_rpt;
         CLOSE lcu_opportunity;

   END report_main;
END XX_SFA_OPPTY_RPT_PKG;
/
SHOW ERRORS;