CREATE OR REPLACE
PACKAGE XX_GI_JOB_SCHEDULE_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_job_schedule_pkg                                   |
-- | Description      : This package spec will schedule the            |
-- |                    given concurrent program                       |
-- |                                                                   | 
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+

   -- Global Variables
   pvg_run_date             DATE   := SYSDATE;
   pvg_request_id           NUMBER := Fnd_Global.conc_request_id ;
   pvg_resp_id              NUMBER := Fnd_Global.resp_id ;
   pvg_user_id              NUMBER := Fnd_Global.user_id;
   pvg_login_id             NUMBER := Fnd_Global.login_id;
   pvg_org_id               NUMBER := Fnd_Profile.value('ORG_ID');
   pvg_sob_id               NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');
   pvg_application_id       NUMBER := 401;

--
FUNCTION get_schedule_date (p_week_day IN VARCHAR2) 
RETURN DATE ;
--
PROCEDURE schedule_job (p_program_name  IN VARCHAR2,
                        p_prog_param    IN VARCHAR2,
                        p_org_type      IN VARCHAR2,
                        p_schedule_type IN VARCHAR2,
                        p_frequency     IN VARCHAR2,
                        p_week_day      IN VARCHAR2,
                        p_schedule_time IN VARCHAR2) ;                          
--
PROCEDURE main(
      x_errbuf     OUT NOCOPY VARCHAR2,
      x_retcode    OUT NUMBER,
      p_program_name  IN VARCHAR2,
      p_prog_param    IN VARCHAR2,
      p_org_type      IN VARCHAR2,
      p_schedule_type IN VARCHAR2,
      p_frequency     IN VARCHAR2,
      p_week_day      IN VARCHAR2,
      p_schedule_time IN VARCHAR2
  );
--
                          
END XX_GI_JOB_SCHEDULE_PKG;
/