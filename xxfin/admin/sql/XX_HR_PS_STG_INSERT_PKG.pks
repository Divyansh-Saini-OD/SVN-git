create or replace
PACKAGE  XX_HR_PS_STG_INSERT_PKG   
AS

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
-- |               p_ins_stg_flag = 'Y'.                                                        |
-- |===========================================================================================|
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
                                  ,p_retcode           OUT VARCHAR2);
 
END  XX_HR_PS_STG_INSERT_PKG;

/