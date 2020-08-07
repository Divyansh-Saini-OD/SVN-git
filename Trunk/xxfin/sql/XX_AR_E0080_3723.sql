SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Running Update Script
spool  update_output.txt;
set serveroutput ON SIZE 1000000

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_CREATE_ACCT_MASTER_PKG                                 |
-- | RICE ID :  E0080                                                    |
-- | Description : Data Fix Script for existing Invoices -               |
-- |               Order Header ID not populated on AR Invoice Header.   |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version    Date            Author              Remarks               |
-- |======   ==========     =============        ======================= |
-- |Draft 1A               Wipro Technologies           Initial version  |
-- |                                                                     |
-- |1.1       09-Sep-08     Sowmya.M.S           Assigned attribute14 to |
-- |                          Wipro              '0' and included        |
-- |                                             customer_trx_id for     |
-- |                                             defect # 11872          |
-- +=====================================================================+

DECLARE

-- Variable declaration

lc_trx    ra_customer_trx_all.trx_number%TYPE := 0;
lc_count  NUMBER :=1;

CURSOR c_order_header
IS 
SELECT   OOH.order_number
        ,OOH.header_id 
        ,RCT.customer_trx_id
FROM     oe_order_headers_all OOH 
        ,ra_customer_trx_all RCT
WHERE    RCT.trx_number = TO_CHAR(OOH.order_number)   -- As invoice number and Order number as same 
AND      RCT.batch_source_id in (1001,1002)           -- Only the invoices which have batch_source SALES_ACCT
AND      RCT.org_id in (403,404)
AND      RCT.attribute14 ='0'                         -- To avoid existing attribute14 
ORDER BY OOH.order_number;

BEGIN
FOR lc_order IN c_order_header LOOP

--Commenetd for defect # 11872
--lc_trx := TO_CHAR(lc_order.order_number);

UPDATE ra_customer_trx_all RCT
SET    RCT.attribute_category = 'SALES_ACCT'
      ,RCT.attribute14 = lc_order.header_id
-- WHERE  RCT.trx_number = lc_trx                     For defect # 11872
WHERE  RCT.customer_trx_id = lc_order.customer_trx_id
AND    RCT.complete_flag = 'Y'
AND    RCT.status_trx = 'OP';

--DBMS_OUTPUT.PUT_LINE('Order number '||lc_trx);     --Commented to avoid buffer over flow
lc_count:=lc_count+1;

END LOOP;

COMMIT;

DBMS_OUTPUT.PUT_LINE('Number of Invoices Updated : '||lc_count);
EXCEPTION
WHEN NO_DATA_FOUND THEN
DBMS_OUTPUT.PUT_LINE('No invoice is found');
END;
/
SHO ERR;
spool off



