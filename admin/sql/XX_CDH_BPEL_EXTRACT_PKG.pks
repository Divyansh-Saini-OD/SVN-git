SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_CDH_BPEL_EXTRACT_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        :  XX_CDH_BPEL_EXTRACT_PKG.pks                        |
-- | Description :  To Control BPEL Extrat Start/Stop During EBIZ      |
-- |                DownTimes.                                         |
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

  PROCEDURE bpel_extract_main (
    x_errbuf             OUT NOCOPY VARCHAR2,
    x_retcode            OUT NOCOPY VARCHAR2
  );

END XX_CDH_BPEL_EXTRACT_PKG;
/
SHOW ERRORS;