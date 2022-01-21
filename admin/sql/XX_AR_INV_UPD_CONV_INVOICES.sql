SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- |                       WIPRO Technologies                                           |
-- +====================================================================================+
-- | Name :      XX_AR_INV_UPD_CONV_INVOICES.sql                                        |
-- | Description : Update converted Invoices from getting picked by Billing Programs    |
-- |                documents . This script should be run as Part of post conversion step|                                                          |
-- |                                                                                    |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date          Author              Remarks                                 |
-- |=======   ==========   =============        ========================================|
-- |1.0       29-JAN-2009  MOHANAKRISHNAN        Initial version                        |
-- +====================================================================================+

PROMPT updating table ra_customer_trx_all

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
DECLARE
   ln_batch_id NUMBER;

CURSOR lcu_batch_source
IS
 SELECT org_id,
         batch_source_id
   FROM ra_batch_sources_all 
   WHERE NAME ='CONVERSION_OD' ; 

BEGIN

FOR lcu_batch_source_rec in lcu_batch_source
LOOP
-- Updating converted Invoices.

 UPDATE /*+ index(RCT XX_AR_CUSTOMER_TRX_N4) */ ra_customer_trx_all RCT
        SET RCT.attribute15 = 'P',
	    RCT.PRINTING_OPTION ='NOT'
        WHERE RCT.batch_source_id = lcu_batch_source_rec.batch_source_id 
	AND   org_id = lcu_batch_source_rec.org_id 
	AND  RCT.attribute15 IS NULL ;
DBMS_OUTPUT.PUT_LINE ( 'UPDATING ORG ID '||lcu_batch_source_rec.org_id ||'Batch source id '||lcu_batch_source_rec.batch_source_id ||' count:  '||SQL%ROWCOUNT );
END LOOP;
COMMIT;

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE (SQLERRM);
END;
/