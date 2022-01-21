SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - ODN AR Conversion                        |
-- |                                                                       |
-- +=======================================================================+
-- | Name             :  XX_ODN_INV_STG_GATHER_STATS                       |
-- | Description      :  GATHER TABLE STATS FOR XXOD_OMX_CNV_AR_TRX_STG    |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date           Author             Remarks                     |
-- |-------  ----------- -----------------  -------------------------------|
-- |Draft1a  28-FEB-18   Punit Gupta        Initial Draft Version          |
-- +=======================================================================+

-- -------------------------------------------------
-- Gather Table STATS for XXOD_OMX_CNV_AR_TRX_STG
-- -------------------------------------------------
BEGIN
   FND_STATS.GATHER_TABLE_STATS( OWNNAME => 'XXFIN', TABNAME=> 'XXOD_OMX_CNV_AR_TRX_STG', PERCENT => 0, DEGREE => 4 );
END;

/


