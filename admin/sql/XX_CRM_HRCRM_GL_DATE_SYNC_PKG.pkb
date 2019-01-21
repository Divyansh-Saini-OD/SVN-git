SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CRM_HRCRM_GL_DATE_SYNC_PKG
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_CRM_HRCRM_GL_DATE_SYNC_PKG                                     |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============        =====================================|
-- |DRAFT 1A 11-SEP-2008 Sarah Maria Justina   Initial draft version                |
-- +================================================================================+
----------------------------
--Declaring Global Constants
----------------------------
   G_MODULE_NAME   CONSTANT VARCHAR2 (50)           := 'CRM';
   G_NOTIFY        CONSTANT VARCHAR2 (1)            := 'Y';
   G_ERROR_STATUS  CONSTANT VARCHAR2 (10)           := 'ACTIVE';
   G_MAJOR         CONSTANT VARCHAR2 (15)           := 'MAJOR';
   G_MINOR         CONSTANT VARCHAR2 (15)           := 'MINOR';
   G_PROG_TYPE     CONSTANT VARCHAR2(100)           := 'E1002_HR_CRM_Synchronization';   
   G_NO            CONSTANT VARCHAR2 (1)            := 'N';
   G_YES           CONSTANT VARCHAR2 (1)            := 'Y';   
----------------------------
--Declaring Global Variables
----------------------------
   EX_MULTIPLE_GRPS_WITH_RES EXCEPTION;
   EX_CRM_FND_USER_UNSYNC    EXCEPTION;    
	    
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
-- | Name        :  MAIN
-- | Description :  This procedure is used to sync the Manager Effectivity date of employees under a VP in HR  
-- |                with the input GL date.
-- |                This gets called from the following Conc Programs: 
-- |                OD: CRM HRCRM GL Date Syncronization Program
-- | Parameters  :  p_person_id    IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
-- |                p_gl_date      IN   DATE
-- +===========================================================================================================+  

   PROCEDURE main ( 
    x_errbuf       OUT   VARCHAR2,
    x_retcode      OUT   NUMBER,    
    p_person_id          per_all_people_f.person_id%TYPE,
    p_gl_date            VARCHAR2
                  ) 
   IS 
-----------------------------------------------------------------------
--Cursor to obtain the list of Employees under input VP for processing
-----------------------------------------------------------------------
      CURSOR lcu_get_employees 
      IS
	   SELECT    f.person_id
	            ,f.full_name
	            ,f.supervisor_id
		    ,MGR_PAAF.MANAGER_NAME
		    ,F.JOB_ASGN_DATE
		    ,F.MGR_ASGN_DATE
	            ,MGR_PAAF.SUP_JOB_ASGN_DATE
	            ,MGR_PAAF.SUP_MGR_ASGN_DATE
	     FROM 
	   (SELECT   PAAF.person_id  PERSON_ID
	            ,PAAF.supervisor_id SUPERVISOR_ID
	            ,TRUNC(TO_DATE(PAAF.ass_attribute10,'DD-MON-RR')) JOB_ASGN_DATE
                    ,TRUNC(TO_DATE(PAAF.ass_attribute9, 'DD-MON-RR')) MGR_ASGN_DATE
                    ,PAPF.FULL_NAME
	      FROM   (SELECT *
		        FROM per_all_assignments_f p
		       WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PAAF
		    ,(SELECT *
		        FROM per_all_people_f p
		       WHERE  sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PAPF
		    ,per_person_types  PPT
		    ,(SELECT *
		        FROM per_person_type_usages_f p
		       WHERE sysdate BETWEEN p.effective_start_date AND p.effective_end_date) PPTU
	      WHERE    
		       PAAF.person_id               = PAPF.person_id
		AND    PAPF.person_id               = PPTU.person_id
		AND    PPT. person_type_id          = PPTU.person_type_id
		AND    PPT.system_person_type       = 'EMP'
		AND    PAAF.business_group_id       = 0
		AND    PAPF.business_group_id       = 0
		AND    PPT .business_group_id       = 0
	 CONNECT BY 
	      PRIOR    PAAF.person_id               = PAAF.supervisor_id
	 START WITH    PAAF.person_id               = p_person_id) F,
	 (SELECT       p.person_id
	 	      ,TRUNC(TO_DATE(p.ass_attribute10,'DD-MON-RR')) SUP_JOB_ASGN_DATE
	              ,TRUNC(TO_DATE(p.ass_attribute9, 'DD-MON-RR')) SUP_MGR_ASGN_DATE
	 	      ,f.full_name as MANAGER_NAME
	    FROM       per_all_assignments_f p,per_all_people_f f
	   WHERE       sysdate BETWEEN p.effective_start_date AND p.effective_end_date
	     AND       p.person_id = f.person_id) MGR_PAAF
	 WHERE MGR_PAAF.person_id(+) = f.supervisor_id;
	 
   ld_mgr_asgn_date DATE;
   ld_gl_date DATE;
   
   BEGIN 
      display_LOG        ('Input GL Date:'||p_gl_date);
      ld_gl_date         := fnd_date.canonical_to_date(p_gl_date);
      display_LOG        ('DAte conv done');
      display_out        (RPAD (' Office Depot', 100)|| 'Date:'|| SYSDATE);
      display_out        (LPAD ('OD HR CRM GL Date Sync Process',70)|| LPAD ('Page:1', 36));
      display_out        (RPAD (' ', 230, '_'));

      display_out        ('');
      display_out        ('');
      display_out        ('');
      display_out        (   RPAD ('Employee Name', 40)
                          || CHR(9)
                          || RPAD ('Emp Job Assignment Date', 25)
                          || CHR(9)
                          || RPAD ('Manager Name', 40)
                          || CHR(9) 
                          || RPAD ('Mgr Job Assignment Date', 25)
                          || CHR(9)                          
                          || RPAD ('Emp OLD Mgr Assignment Date', 30)
                          || CHR(9)
                          || RPAD ('Emp NEW Mgr Assignment Date ', 30)
                          );
      display_out        (RPAD (' ', 230, '_'));
      FOR lt_get_employees_rec in lcu_get_employees
      LOOP
          IF(lt_get_employees_rec.SUPERVISOR_ID is NULL)
            THEN
               ld_mgr_asgn_date := GREATEST(lt_get_employees_rec.JOB_ASGN_DATE,    
                                    ld_gl_date);
          ELSE
               ld_mgr_asgn_date := GREATEST(lt_get_employees_rec.JOB_ASGN_DATE,
                                    lt_get_employees_rec.SUP_JOB_ASGN_DATE,
                                    ld_gl_date);
          END IF;      
       UPDATE per_all_assignments_f
       SET ass_attribute9 = ld_mgr_asgn_date
       WHERE person_id = lt_get_employees_rec.person_id;
      display_out        (   RPAD (lt_get_employees_rec.full_name, 40)
                          || CHR(9)
                          || RPAD (lt_get_employees_rec.JOB_ASGN_DATE, 25)
                          || CHR(9)
                          || RPAD (lt_get_employees_rec.manager_name, 40)
                          || CHR(9)
                          || RPAD (lt_get_employees_rec.SUP_JOB_ASGN_DATE, 25)
                          || CHR(9)
                          || RPAD (lt_get_employees_rec.MGR_ASGN_DATE, 30)
                          || CHR(9)
                          || RPAD (ld_mgr_asgn_date, 30)
                          );        
      END LOOP;
      display_out        (RPAD (' ', 230, '_'));
   COMMIT;
   END;
END XX_CRM_HRCRM_GL_DATE_SYNC_PKG;
/

SHOW ERRORS
EXIT;
