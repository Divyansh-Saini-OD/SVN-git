SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XXBI_OPPTY_PROD_CAT_DIM_V
AS
SELECT distinct ehpv.category_id id , ehpv.concat_cat_parentage value
FROM apps.eni_prod_den_hrchy_parents_v ehpv, xxcrm.XXBI_SALES_OPPTY_FCT_MV MV/* Modified APPS Schema to XXCRM Schema Gokila */, XXBI_GROUP_MBR_INFO_V  H
WHERE ehpv.category_id = MV.product_category_id
AND MV.resource_id = h.resource_id
union 
SELECT -1, 'None' from dual;

SHOW ERRORS;
EXIT;