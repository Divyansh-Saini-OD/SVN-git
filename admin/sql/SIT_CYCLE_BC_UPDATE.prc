
UPDATE Xx_Om_Header_Attributes_All
SET Bill_Comp_Flag    = 'N'
WHERE bill_comp_flag <> 'N'
AND header_id        IN
  (SELECT attribute14
  FROM ra_customer_trx_all
  WHERE creation_date      > sysdate - 20
  AND bill_to_customer_id           IN (33595139, 34912541, 24638, 233948, 33059690)
  ); 
  
  
COMMIT;   

SHOW ERRORS;

EXIT;