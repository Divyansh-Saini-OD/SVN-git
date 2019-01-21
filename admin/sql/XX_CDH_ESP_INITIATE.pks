SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CDH_ESP_INITIATE AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_ESP_INITIATE.pks                           |
-- | Description :  Job To Initiate CDH ESP Schedule                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |=======   ==========  =============      ==========================|
-- |1.0      24-Nov-2008  Indra Varada       Initial version           |
-- +===================================================================+
  
PROCEDURE MAIN(
              x_errbuf          OUT NOCOPY VARCHAR2
            , x_retcode         OUT NOCOPY VARCHAR2
            , p_chkpoint_name  IN         VARCHAR2
              );

END XX_CDH_ESP_INITIATE;
/
SHOW ERRORS;
EXIT;
