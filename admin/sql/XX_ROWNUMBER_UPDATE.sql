-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the in-process/completed custdocs with Rownumber 1   |	
-- |                                                                          |  
-- |Table    :    XX_CDH_EBL_TEMPL_DTL_TXT                                    |
-- |Description : For Requirement#41307                                       |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          25-SEP-2017   Punit Gupta             Requirement#41307      |
-- +==========================================================================+

UPDATE XX_CDH_EBL_TEMPL_DTL_TXT 
SET ROWNUMBER = 1 
WHERE CUST_DOC_ID in
(
SELECT distinct XCEB.n_ext_attr2 
FROM apps.xx_cdh_cust_acct_ext_b XCEB,apps.XX_CDH_EBL_TEMPL_DTL_TXT XCEDT
WHERE UPPER(XCEB.c_ext_attr3) = 'ETXT' -- DELIVERY_METHOD
AND UPPER(XCEB.c_ext_attr1) = 'CONSOLIDATED BILL' -- DOC_TYPE
AND XCEB.c_ext_attr16 IN ('IN_PROCESS','COMPLETE') --CUST DOC STATUS CODE
AND XCEB.n_ext_attr2 = XCEDT.cust_doc_id
AND XCEDT.ROWNUMBER IS NULL
);

COMMIT;
		   
SHOW ERRORS;

EXIT;