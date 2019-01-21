-- +===========================================================================+
-- |                          Office Depot                                     |
-- +===========================================================================+
-- | Name        : XXFIN.XX_CE_MPL_SETTLEMENT_STG                              |
-- | Description : Script to create synonym for XX_CE_MPL_SETTLEMENT_STG table |
-- | RICE ID     : I3091_CM Marketplace Inbound Interface                      |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version      Date           Author            Remarks                      |
-- |=======    ==========     =============       ======================       |
-- |  1.0      09-MAR-2015    Suresh P           Initial Version              |
-- +===========================================================================+


SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
WHENEVER SQLERROR CONTINUE

--+=====================================================================+
--+               GRANT TABLE XXFIN.XX_CE_MPL_SETTLEMENT_STG           +
--+=====================================================================+

GRANT SELECT ON xxfin.XX_CE_MPL_SETTLEMENT_STG TO XXDATA_STAGE_ROLE;

SHOW ERROR
