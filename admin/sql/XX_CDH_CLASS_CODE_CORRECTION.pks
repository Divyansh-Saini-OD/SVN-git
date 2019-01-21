SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_CLASS_CODE_CORRECTION AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_CLASS_CODE_CORRECTION.pks                   |
-- | Description :  CDH Class Codes Correction                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  28-Aug-2008 Indra Varada       Initial draft version     |
-- +===================================================================+


PROCEDURE code_assignments_correction (
       x_errbuf                 OUT VARCHAR2,
       x_retcode                OUT VARCHAR2,
       p_start_date             IN  VARCHAR2,
       p_end_date               IN VARCHAR2
  );

END XX_CDH_CLASS_CODE_CORRECTION;
/
SHOW ERRORS;
