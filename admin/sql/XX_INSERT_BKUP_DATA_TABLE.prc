-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                           Capgemini                                      |
-- +==========================================================================+
-- |SQL Script to insert data into custom tables from backup tables           |	
-- |                                                                          |  
-- |Table    : xx_ar_subscriptions , xx_ar_contracts, xx_ar_contract_lines    |
-- |Description :                                                             |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version      Date             Author               Remarks                |
-- |=======      ==========    =============           =====================  |
-- |1.0          06-AUG-2018   Punit Gupta             Report Test            |

INSERT INTO xx_ar_subscriptions
SELECT * FROM xx_ar_subscriptions_bk XASBK
WHERE XASBK.contract_id NOT IN
(300000038270051,
300000038271999,
300000038957682,
300000038957698,
300000038958585,
300000038984811,
300000055979162,
300000056239230,
300000056249261
)
/
DELETE FROM xx_ar_contracts XAC 
WHERE rowid >(SELECT MIN(rowid) FROM xx_ar_contracts XAC1
WHERE XAC1.contract_id = XAC.contract_id)
/
DELETE FROM xx_ar_contract_lines XACL WHERE rowid >(SELECT MIN(rowid) FROM xx_ar_contract_lines XACL1
WHERE XACL1.contract_id = XACL.contract_id
AND XACL1.contract_line_number = XACL.contract_line_number)
/

COMMIT;   

SHOW ERRORS;

EXIT;