SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_CPY_TBL_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_CPY_TBL_PKG.pks                             |
-- | Description :  CDH Class Codes Correction                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  05-Sep-2008 Indra Varada       Initial draft version     |
-- +===================================================================+

PROCEDURE process_copy (
x_errbuf      OUT VARCHAR2,
x_retcode     OUT VARCHAR2,
p_from_table  IN  VARCHAR2,
p_to_table    IN  VARCHAR2,
p_batch_id    IN  NUMBER
);

END XX_CDH_CPY_TBL_PKG;
/
SHOW ERRORS;