SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CRM_HRCRM_GL_DATE_SYNC_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       :  XX_CRM_HRCRM_GL_DATE_SYNC_PKG                                    |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 11-SEP-2008 Sarah Maria Justina        Initial draft version           |
-- +================================================================================+

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
                  ) ;
END XX_CRM_HRCRM_GL_DATE_SYNC_PKG;
/

SHOW ERRORS
EXIT;
