SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CRM_TOPS_ASSIGNMENT_RPT 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CRM_TOPS_ASSIGNMENT_RPT.pks                     |
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
    );

END XX_CRM_TOPS_ASSIGNMENT_RPT;
/
SHOW ERRORS;