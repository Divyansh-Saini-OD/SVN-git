-- +===========================================================================+
-- |                  Office Depot - ALT Subcriptions Project                  |
-- |                                                                           |
-- +===========================================================================+
-- | File Name   : XX_OD_OKS_ALT_SKU_TBL_SYN.sql                               |
-- | Object Name : XXFIN.XX_OD_OKS_ALT_SKU_TBL#                                |
-- | Description : Synonym for XXFIN.XX_OD_OKS_ALT_SKU_TBL# View script        |                                                             
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      10-FEB-2020 Kayeed Ahmed  Initial draft version                   |
-- +===========================================================================+
DROP SYNONYM APPS.XX_OD_OKS_ALT_SKU_TBL;

CREATE OR REPLACE SYNONYM APPS.XX_OD_OKS_ALT_SKU_TBL FOR XXFIN.XX_OD_OKS_ALT_SKU_TBL#;

set linesize 200
select owner,object_name,object_type,status from all_objects where object_name like 'XX_OD_OKS_ALT_SKU_TBL%';

SHOW ERRORS;
EXIT;