create or replace
PACKAGE BODY XX_HR_PS_STG_INSERT_PKG AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_HR_PS_STG_INSERT_PKG                                                            |
-- |  Description:  Insert into XX_HR_PS_STG and XX_HR_PS_STG_TRIGGER.  Part of I0097 upgrade   |
-- |                to hosted Peoplesoft HR.                                                    |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         05/31/2012   Joe Klein        Initial version                                  |
-- | 1.1         08/21/2012   Paddy Sanjeevi   Removed trunc in xx_hr_ps_stg_trigger insert     |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_PROC                                                                         |
-- |  Description: This procedure will insert into both the XX_HR_PS_STG and                    |
-- |               XX_HR_PS_STG_TRIGGER tables.  If a row already exists, an update will be     |
-- |               performed instead.  The "every 4 hour" SOA process will call this api        |
-- |               without passing values for p_ins_trig_flag and p_ins_stg_flag.  This will    |
-- |               insert/update both tables.  The "weekly" batch conc pgm for syncing entire   |
-- |               EBS HR will insert only to XX_HR_PS_STG and not insert to                    |
-- |               XX_HR_PS_STG_TRIGGER, hence will call api with p_ins_trig_flag = 'N' and     |
-- |               p_ins_stg_flag = 'Y'.
-- =============================================================================================|
PROCEDURE INSERT_PROC             (p_emplid             IN VARCHAR2
                                  ,p_badge_nbr          IN VARCHAR2  DEFAULT NULL
                                  ,p_first_name	        IN VARCHAR2
                                  ,p_middle_name        IN VARCHAR2
                                  ,p_last_name          IN VARCHAR2  DEFAULT NULL
                                  ,p_second_last_name	  IN VARCHAR2
                                  ,p_name_prefix        IN VARCHAR2
                                  ,p_name_suffix        IN VARCHAR2
                                  ,p_od_addeffdt        IN DATE      DEFAULT NULL
                                  ,p_sex                IN VARCHAR2  DEFAULT NULL
                                  ,p_address1           IN VARCHAR2  DEFAULT NULL
                                  ,p_address2	          IN VARCHAR2  DEFAULT NULL
                                  ,p_address3	          IN VARCHAR2  DEFAULT NULL
                                  ,p_city	              IN VARCHAR2  DEFAULT NULL
                                  ,p_postal	            IN VARCHAR2  DEFAULT NULL
                                  ,p_county	            IN VARCHAR2  DEFAULT NULL
                                  ,p_state              IN VARCHAR2  DEFAULT NULL
                                  ,p_country            IN VARCHAR2  DEFAULT NULL
                                  ,p_per_org            IN VARCHAR2
                                  ,p_empl_status        IN VARCHAR2
                                  ,p_od_jobeffdt        IN DATE
                                  ,p_hire_dt            IN DATE      DEFAULT NULL
                                  ,p_action	            IN VARCHAR2
                                  ,p_setid_jobcode      IN VARCHAR2
                                  ,p_jobcode            IN VARCHAR2
                                  ,p_business_unit      IN VARCHAR2
                                  ,p_setid_location     IN VARCHAR2
                                  ,p_location	          IN VARCHAR2
                                  ,p_company            IN VARCHAR2
                                  ,p_setid_dept         IN VARCHAR2
                                  ,p_deptid             IN VARCHAR2
                                  ,p_reg_region         IN VARCHAR2
                                  ,p_last_date_worked   IN DATE      DEFAULT NULL
                                  ,p_grade              IN VARCHAR2
                                  ,p_sal_admin_plan     IN VARCHAR2
                                  ,p_supervisor_id      IN VARCHAR2
                                  ,p_manager_level      IN VARCHAR2
                                  ,p_job_entry_dt       IN DATE      DEFAULT NULL
                                  ,p_job_function       IN VARCHAR2
                                  ,p_descr              IN VARCHAR2
                                  ,p_emailid            IN VARCHAR2  DEFAULT NULL
                                  ,p_vendor_id          IN VARCHAR2
                                  ,p_od_phone_busn      IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_busn_fg	IN VARCHAR2  DEFAULT NULL
                                  ,p_od_phone_fax       IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_fax_fg  IN VARCHAR2  DEFAULT NULL
                                  ,p_od_phone_faxp      IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_faxp_fg	IN VARCHAR2  DEFAULT NULL
                                  ,p_od_phone_main      IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_main_fg	IN VARCHAR2  DEFAULT NULL
                                  ,p_od_phone_mobb      IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_mobb_fg	IN VARCHAR2  DEFAULT NULL
                                  ,p_od_phone_mobp      IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_mobp_fg	IN VARCHAR2  DEFAULT NULL
                                  ,p_od_phone_pgr1      IN VARCHAR2  DEFAULT NULL
                                  ,p_pref_phone_pgr1_fg	IN VARCHAR2  DEFAULT NULL
                                  ,p_ins_trig_flag      IN VARCHAR2  DEFAULT 'Y'
                                  ,p_ins_stg_flag     	IN VARCHAR2  DEFAULT 'Y'
                                  ,p_errbuff           OUT VARCHAR2
                                  ,p_retcode           OUT VARCHAR2)
    AS
       l_exists_stg       NUMBER;
       l_exists_trig      NUMBER;
    BEGIN
       
       SELECT COUNT(*) INTO l_exists_stg
         FROM xx_hr_ps_stg
        WHERE emplid = p_emplid
          AND ROWNUM = 1;
       
       IF p_ins_stg_flag = 'Y' THEN
          IF l_exists_stg = 1 THEN
             -- Update
             BEGIN
                UPDATE xx_hr_ps_stg SET 
                  emplid                 = p_emplid 
                 ,badge_nbr              = p_badge_nbr
                 ,first_name             = p_first_name
                 ,middle_name            = p_middle_name
                 ,last_name              = p_last_name
                 ,second_last_name       = p_second_last_name
                 ,name_prefix            = p_name_prefix
                 ,name_suffix            = p_name_suffix
                 ,od_addeffdt            = p_od_addeffdt
                 ,sex                    = p_sex
                 ,address1               = p_address1
                 ,address2               = p_address2
                 ,address3               = p_address3
                 ,city                   = p_city
                 ,postal                 = p_postal
                 ,county                 = p_county
                 ,state                  = p_state
                 ,country                = p_country
                 ,per_org                = p_per_org
                 ,empl_status            = p_empl_status
                 ,od_jobeffdt            = p_od_jobeffdt
                 ,hire_dt                = p_hire_dt
                 ,action                 = p_action
                 ,setid_jobcode          = p_setid_jobcode
                 ,jobcode                = p_jobcode
                 ,business_unit          = p_business_unit
                 ,setid_location         = p_setid_location
                 ,location               = p_location
                 ,company                = p_company
                 ,setid_dept             = p_setid_dept
                 ,deptid                 = p_deptid
                 ,reg_region             = p_reg_region
                 ,last_date_worked       = p_last_date_worked
                 ,grade                  = p_grade
                 ,sal_admin_plan         = p_sal_admin_plan
                 ,supervisor_id          = p_supervisor_id
                 ,manager_level          = p_manager_level
                 ,job_entry_dt           = p_job_entry_dt
                 ,job_function           = p_job_function
                 ,descr                  = p_descr
                 ,emailid                = p_emailid
                 ,vendor_id              = p_vendor_id
                 ,od_phone_busn	         = p_od_phone_busn
                 ,pref_phone_busn_fg     = p_pref_phone_busn_fg
                 ,od_phone_fax           = p_od_phone_fax
                 ,pref_phone_fax_fg      = p_pref_phone_fax_fg
                 ,od_phone_faxp          = p_od_phone_faxp
                 ,pref_phone_faxp_fg     = p_pref_phone_faxp_fg
                 ,od_phone_main          = p_od_phone_main
                 ,pref_phone_main_fg     = p_pref_phone_main_fg
                 ,od_phone_mobb          = p_od_phone_mobb
                 ,pref_phone_mobb_fg     = p_pref_phone_mobb_fg
                 ,od_phone_mobp          = p_od_phone_mobp
                 ,pref_phone_mobp_fg     = p_pref_phone_mobp_fg
                 ,od_phone_pgr1          = p_od_phone_pgr1
                 ,pref_phone_pgr1_fg     = p_pref_phone_pgr1_fg
                WHERE emplid = p_emplid;
             EXCEPTION
                WHEN OTHERS THEN
                   p_errbuff := SQLERRM || ' --> update to table XX_HR_PS_STG ' || ' for emplid = ' || p_emplid;
                   p_retcode := SQLCODE;
             END;
          ELSE
             -- Insert
             BEGIN
                INSERT INTO xx_hr_ps_stg
                  (emplid 
                  ,badge_nbr
                  ,first_name
                  ,middle_name
                  ,last_name
                  ,second_last_name
                  ,name_prefix
                  ,name_suffix
                  ,od_addeffdt
                  ,sex
                  ,address1
                  ,address2
                  ,address3
                  ,city
                  ,postal
                  ,county
                  ,state
                  ,country
                  ,per_org
                  ,empl_status
                  ,od_jobeffdt
                  ,hire_dt
                  ,action
                  ,setid_jobcode
                  ,jobcode
                  ,business_unit
                  ,setid_location
                  ,location
                  ,company
                  ,setid_dept
                  ,deptid
                  ,reg_region
                  ,last_date_worked
                  ,grade
                  ,sal_admin_plan
                  ,supervisor_id
                  ,manager_level
                  ,job_entry_dt
                  ,job_function
                  ,descr
                  ,emailid
                  ,vendor_id
                  ,od_phone_busn
                  ,pref_phone_busn_fg
                  ,od_phone_fax
                  ,pref_phone_fax_fg
                  ,od_phone_faxp
                  ,pref_phone_faxp_fg
                  ,od_phone_main
                  ,pref_phone_main_fg
                  ,od_phone_mobb
                  ,pref_phone_mobb_fg
                  ,od_phone_mobp
                  ,pref_phone_mobp_fg
                  ,od_phone_pgr1
                  ,pref_phone_pgr1_fg
                  )
                VALUES (p_emplid 
                  ,p_badge_nbr
                  ,p_first_name
                  ,p_middle_name
                  ,p_last_name
                  ,p_second_last_name
                  ,p_name_prefix
                  ,p_name_suffix
                  ,p_od_addeffdt
                  ,p_sex
                  ,p_address1
                  ,p_address2
                  ,p_address3
                  ,p_city
                  ,p_postal
                  ,p_county
                  ,p_state
                  ,p_country
                  ,p_per_org
                  ,p_empl_status
                  ,p_od_jobeffdt
                  ,p_hire_dt
                  ,p_action
                  ,p_setid_jobcode
                  ,p_jobcode
                  ,p_business_unit
                  ,p_setid_location
                  ,p_location
                  ,p_company
                  ,p_setid_dept
                  ,p_deptid
                  ,p_reg_region
                  ,p_last_date_worked
                  ,p_grade
                  ,p_sal_admin_plan
                  ,p_supervisor_id
                  ,p_manager_level
                  ,p_job_entry_dt
                  ,p_job_function
                  ,p_descr
                  ,p_emailid
                  ,p_vendor_id
                  ,p_od_phone_busn
                  ,p_pref_phone_busn_fg
                  ,p_od_phone_fax
                  ,p_pref_phone_fax_fg
                  ,p_od_phone_faxp
                  ,p_pref_phone_faxp_fg
                  ,p_od_phone_main
                  ,p_pref_phone_main_fg
                  ,p_od_phone_mobb
                  ,p_pref_phone_mobb_fg
                  ,p_od_phone_mobp
                  ,p_pref_phone_mobp_fg
                  ,p_od_phone_pgr1
                  ,p_pref_phone_pgr1_fg
                  );
              EXCEPTION
                 WHEN OTHERS THEN
                    p_errbuff := SQLERRM || ' --> insert to table XX_HR_PS_STG ' || ' for emplid = ' || p_emplid;
                    p_retcode := SQLCODE;
              END;
          END IF;
       END IF;
       
       SELECT COUNT(*) INTO l_exists_trig
         FROM xx_hr_ps_stg_trigger
        WHERE emplid = p_emplid
          AND process_status = 'N'
          AND ROWNUM = 1;
       
       IF p_ins_trig_flag = 'Y' THEN
          IF l_exists_trig = 1 THEN
             -- Update
             BEGIN
                UPDATE xx_hr_ps_stg_trigger SET 
                     od_trans_dt            = TRUNC(sysdate) 
                    ,process_date           = NULL
                 WHERE emplid = p_emplid
                   AND process_status = 'N';
              EXCEPTION
                 WHEN OTHERS THEN
                    p_errbuff := SQLERRM || ' --> update to table XX_HR_PS_STG_TRIGGER ' || ' for emplid = ' || p_emplid;
                    p_retcode := SQLCODE;
             END;
          ELSE
             -- Insert
             BEGIN
                INSERT INTO xx_hr_ps_stg_trigger
                        (emplid 
                        ,od_trans_dt
                        ,process_status
                        ,process_date
                        )
                VALUES  (p_emplid 
                        ,sysdate
                        ,'N'
                        ,NULL
                        );
             EXCEPTION
                WHEN OTHERS THEN
                   p_errbuff := SQLERRM || ' --> insert to table XX_HR_PS_STG_TRIGGER ' || ' for emplid = ' || p_emplid;
                   p_retcode := SQLCODE;
             END;
          END IF;
       END IF ;
       
       COMMIT;

    END INSERT_PROC;

  
END XX_HR_PS_STG_INSERT_PKG;

/