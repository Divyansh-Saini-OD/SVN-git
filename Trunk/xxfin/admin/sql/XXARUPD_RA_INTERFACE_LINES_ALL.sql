-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
---|  Application    :   AR                                                   |
---|                                                                          |
---|  Name           :   XXARUPDRA_INTERFACE_LINES_ALL.sql                    |
---|                                                                          |
---|  Description    :   This script updates tax_code, vat_tax_id and         |
---|                     cust_trx_type_id of RA_INTERFACE_LINES_ALL table.    |
---|                     For 0$ Tax Change - Defect# 2569.                    |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author               Remarks                      |
-- |=======   ==========    ================     =============================|
-- | V1.0     04-FEB-2010   Hemalatha S          For Defect 2569              |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

UPDATE AR.ra_interface_lines_all
SET    tax_code   = NULL
      ,vat_tax_id = NULL
      ,cust_trx_type_id = DECODE(cust_trx_type_id,1000,(SELECT cust_trx_type_id
                                                        FROM   AR.ra_cust_trx_types_all 
                                                        WHERE  name = 'US_SA CREDIT MEMO_OD'
                                                        )
                                                 ,1001,(SELECT cust_trx_type_id 
                                                        FROM   AR.ra_cust_trx_types_all 
                                                        WHERE  name = 'US_SA INVOICE_OD'
                                                        )
                                                 ,1002,(SELECT cust_trx_type_id 
                                                        FROM   AR.ra_cust_trx_types_all 
                                                        WHERE  name = 'CA_SA CREDIT MEMO_OD'
                                                        )
                                                 ,1003,(SELECT cust_trx_type_id 
                                                        FROM   AR.ra_cust_trx_types_all 
                                                        WHERE  name = 'CA_SA INVOICE_OD'
                                                        )
                                 );
COMMIT;

SHOW ERROR