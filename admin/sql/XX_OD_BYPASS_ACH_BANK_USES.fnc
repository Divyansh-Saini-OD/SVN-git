SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +====================================================================================+
-- |                                  Office Depot                                      |
-- +====================================================================================+
-- | Name:           XX_OD_BYPASS_ACH_BANK_USES                                         |
-- | Description:    This function is designed to be used in VPD policy                 |
-- |                 XX_OD_BYPASS_ACH_BANK_USES to prevent lockbox processing from      |
-- |                 looking for bank accounts created for making ACH payments.         |
-- |                                                                                    |
-- | Modification Log:                                                                  |
-- | -----------------------------------------------------------------------------------|
-- | Version      Date          Author                  Change Description              |
-- | -----------------------------------------------------------------------------------|
-- | 1.0          20-SEP-2012   Bapuji Nanapaneni       New version                     |
-- +====================================================================================+
CREATE OR REPLACE 
FUNCTION xx_od_bypass_ach_bank_uses ( p_schema VARCHAR2
                                    , p_obj    VARCHAR2
                                    ) RETURN   VARCHAR2 AS 

    lc_add_predicate VARCHAR2(200);
  
BEGIN 
    IF SYS_CONTEXT('userenv', 'module') = 'XX_ARLPLB' 
    OR SYS_CONTEXT('userenv', 'module') = 'ARLPLB' THEN
    
        lc_add_predicate := ' NVL(attribute1,''-99999'') NOT IN (''ACH'')';    
    ELSE 
        lc_add_predicate := NULL;
    END IF;
    
    RETURN (lc_add_predicate);

EXCEPTION
    WHEN OTHERS THEN
        RETURN (NULL);

END;
/
SHOW ERRORS FUNCTION XX_OD_BYPASS_ACH_BANK_USES;
--EXIT;