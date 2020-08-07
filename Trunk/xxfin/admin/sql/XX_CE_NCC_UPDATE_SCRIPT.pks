-- +============================================================================================+
-- |                        Office Depot - Project Simplify                                     |
-- |                                                                                            |
-- +============================================================================================+
-- | Name         : XX_CE_NCC_UPDATE_SCRIPT.pks                                                 |
-- | Rice Id      :                                                                             | 
-- | Description  : Update all duplicate DEBIT CARD transactions with right order payment id    |  
-- | Purpose      : to clear all OPEN transactions                                              |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version    Date          Author                Remarks                                      | 
-- |=======    ==========    =================    ==============================================+
-- |DRAFT 1A   07-FEB-2012   Bapuji Nanapaneni    Initial Version                               |
-- |                                                                                            |
-- +============================================================================================+

SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CE_NCC_UPDATE_SCRIPT AS

-- +===================================================================+
-- | Name  : update_ajb998_opid                                        |
-- | Description     : extract transaction where customer ref is > 2   |
-- |                   and update xx_ce_ajb998 table with correct ord  |
-- |                   pay id                                          |
-- | Parameters      : p_recon_date_from   IN -> recon from date       |
-- |                   p_recon_date_to     IN -> recon to date         |
-- |                   p_type              IN -> ORDER/REFUND          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE update_ajb998_opid ( x_retcode          OUT NOCOPY   NUMBER
                             , x_errbuf           OUT NOCOPY   VARCHAR2
                             , p_recon_date_from   IN          VARCHAR2
                             , p_recon_date_to     IN          VARCHAR2
                             , p_type              IN          VARCHAR2 DEFAULT 'ORDER'
                             );



END XX_CE_NCC_UPDATE_SCRIPT;
/
SHOW ERRORS PACKAGE XX_CE_NCC_UPDATE_SCRIPT;
EXIT;
