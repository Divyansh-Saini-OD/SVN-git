--SET VERIFY OFF;
--SET SHOW OFF;
--SET ECHO OFF;
--SET TAB OFF;
--SET FEEDBACK OFF;
--WHENEVER SQLERROR CONTINUE;
--WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :    xx_ar_update_payment_terms.sql
-- | 
-- | Description  : This script is update the billing cycle  |
-- | on the payment terms 
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author               Remarks                 |
-- |=======   ==========  =============        ======================= |
-- |1.0       24-OCT-13   Arun Gannarapu   Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+



--SET TERM ON-
--PROMPT start the script
--SET TERM OFF

   
Update ra_terms_b
set billing_cycle_id = (select billing_cycle_id from  AR_CONS_BILL_CYCLES_TL
where cycle_name = 'DL00000000N045' )
where term_id = (select term_id from ra_Terms_tl where name = 'NET 45');
/

Commit ;
/


Update ra_terms_b
set billing_cycle_id = (select billing_cycle_id from  AR_CONS_BILL_CYCLES_TL
where cycle_name = 'DL00000000N075' )
where term_id = (select term_id from ra_Terms_tl where name = 'NET 75');
/

Commit;
--SET TERM ON
--PROMPT Payment terms updated successfully
--SET TERM OFF

