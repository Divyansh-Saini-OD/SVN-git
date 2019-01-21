SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - ODN AR Conversion                        |
-- |                                                                       |
-- +=======================================================================+
-- | Name             :  XX_ODN_CUST_CONV_INDEX                        |
-- | Description      :  Create index on XXOD_OMX_CNV_AR_CUST_STG          |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date           Author             Remarks                     |
-- |-------  ----------- -----------------  -------------------------------|
-- |Draft1a  20-JAN-18   Punit Gupta        Initial Draft Version          |
-- +=======================================================================+

-- -------------------------------------------------
-- Creating Index xx_odn_cust_record_id & XX_N1
-- -------------------------------------------------

create unique index XXFIN.xx_odn_cust_record_id on XXFIN.XXOD_OMX_CNV_AR_CUST_STG(record_id);

create unique index XXFIN.XX_N1 on XXFIN.XXOD_OMX_CNV_AR_CUST_STG(record_id,odn_cust_num);

EXIT;


