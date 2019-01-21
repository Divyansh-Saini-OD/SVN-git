SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=====================================================================+
-- |                  Office Depot - CR-798				 |
-- +=====================================================================+
-- | Name        : XXCRM_REMITTO_ONETIME_SCRIPT.pks                      |
-- | Description : This procedure is One time Script to update           |
-- |		   Remit to sale channel.                                |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version     Date           Author               Remarks              |
-- |=======    ==========      ================     =====================|
-- |1.0        08/07/11       Devendra Petkar        Initial version     |
-- +=====================================================================+
create or replace package XXCRM_REMITTO_ONETIME_SCRIPT
IS

   PROCEDURE main (
      x_errbuf            OUT NOCOPY      VARCHAR2,
      x_retcode           OUT NOCOPY      NUMBER,
      p_commit            IN              VARCHAR2 DEFAULT 'N',
      p_processing_flag   IN              VARCHAR2 DEFAULT ''
   );
end XXCRM_REMITTO_ONETIME_SCRIPT;
/
SHOW ERRORS;

EXIT;
