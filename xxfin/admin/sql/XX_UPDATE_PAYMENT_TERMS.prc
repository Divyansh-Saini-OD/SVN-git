-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to update the payment terms of unprocessed accounts            |	
-- |                                                                          |  
-- |Table    :    ar_cons_inv_all                                             |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          04-OCT-2017   Punit Gupta             Regression Test        |

INSERT INTO XX_AR_EBL_CONS_HDR_MAIN
SELECT * from XX_AR_EBL_CONS_HDR_HIST
WHERE cust_doc_id = 121588788 
AND file_id = 3980804
AND CONS_INV_ID = 8402674;

INSERT INTO XX_AR_EBL_CONS_DTL_MAIN
SELECT * from XX_AR_EBL_CONS_DTL_HIST
WHERE cust_doc_id = 121588788
AND CONS_INV_ID = 8402674;

COMMIT;

DELETE FROM XX_AR_EBL_CONS_HDR_HIST
WHERE cust_doc_id = 121588788 
AND file_id = 3980804
AND CONS_INV_ID = 8402674;

DELETE FROM XX_AR_EBL_CONS_DTL_HIST
WHERE cust_doc_id = 121588788 
AND CONS_INV_ID = 8402674;

UPDATE XX_AR_EBL_FILE
SET STATUS = 'MANIP_READY'
WHERE file_id = 3980804;

UPDATE XX_AR_EBL_CONS_HDR_MAIN
SET STATUS = 'MANIP_READY'
WHERE file_id = 3980804;

DELETE FROM xx_ar_ebl_xls_stg
WHERE cust_doc_id = 121588788;

COMMIT;  

SHOW ERRORS;

EXIT;