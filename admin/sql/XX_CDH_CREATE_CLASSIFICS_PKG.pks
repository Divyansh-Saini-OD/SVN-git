SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_CREATE_CLASSIFICS_PKG 
IS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CDH_CREATE_CLASSIFICS_PKG.pks                   |
-- | Description :  Code to populate classification data int int table |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |Draft 1a  00-Sep-2009 Sreedhar Mohan     Initial draft version     |
-- +===================================================================+

   PROCEDURE main
   (
                  p_errbuf                  OUT NOCOPY VARCHAR2,
                  p_retcode                 OUT NOCOPY VARCHAR2,
                  p_batch_id                 IN NUMBER
   );
END XX_CDH_CREATE_CLASSIFICS_PKG;
/
SHOW ERRORS;
