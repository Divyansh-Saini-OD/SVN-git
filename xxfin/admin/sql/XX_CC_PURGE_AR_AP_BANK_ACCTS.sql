SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +=======================================================================+
-- |               Office Depot - Credit Card Purge                         |
-- |      Oracle NAIO/Office Depot/Consulting Organization                 |
-- +=======================================================================+
-- | Name        : XX_CC_PURGE_AR_AP_BANK_ACCTS.sql                                |
-- | Description : Script to purge the Credit Card data for few CreditCardTypes |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- | DraftA  25-Feb-2015  Rajeev            Created by Rajeev              |
-- | 1.0     25-Feb-2015  Madhu Bolli       Edited to create normal script |
-- | 1.1     06-May-2016  Madhu Bolli       Removed DBMS Parallel tasks code when tuning|
-- |                                  and using gt table                   |
-- +=======================================================================+

ALTER SESSION ENABLE PARALLEL DML;

CREATE GLOBAL TEMPORARY TABLE xx_purge_ap_bank_acct_id_gt (
  BANK_ACCOUNT_ID
)
ON COMMIT PRESERVE ROWS
AS
    select /*+ parallel(32) full(aba) */ BANK_ACCOUNT_ID
    from AP.AP_BANK_ACCOUNTS_ALL aba
    where aba.ACCOUNT_TYPE   = 'EXTERNAL'
      and aba.BANK_BRANCH_ID = 1 -- CREDIT CARD ONLY
      and exists (select /*+ parallel(32) USE_HASH(CC XAIO) */ 1 
                  from AP.AP_BANK_ACCOUNT_USES_ALL CC,
                         XXFIN.XX_AR_INTSTORE_R12_TEMP XAIO
                  where cc.OWNING_PARTY_ID          = xaio.PARTY_ID
                    and cc.EXTERNAL_BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
                  );
                  
commit;

delete /*+ parallel(32) full(aba) */ AP.AP_BANK_ACCOUNTS_ALL ABA
    where exists (select /*+ parallel (32) full (abcp) */ 1 
                    from xx_purge_ap_bank_acct_id_gt abcp
                   where abcp.BANK_ACCOUNT_ID = aba.BANK_ACCOUNT_ID
			     );
				 
	commit;

delete /*+ parallel(32) full(abau) */ ap.ap_bank_account_uses_all abau
where exists (select /*+ parallel (32) full (abcp) */ 1 
                    from xx_purge_ap_bank_acct_id_gt abcp
                   where abcp.BANK_ACCOUNT_ID = abau.EXTERNAL_BANK_ACCOUNT_ID
			     );

COMMIT;
