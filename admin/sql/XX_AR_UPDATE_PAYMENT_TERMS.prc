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
-- | Description  : This script is update the due days and discount days |
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



SET TERM ON
PROMPT start the script
SET TERM OFF

   
DECLARE

CURSOR C1 
IS 
SELECT DISTINCT
   rt.name , rt.description , rt.attribute1 , rt.attribute2 , substr(name , -6,2) discount_days, rt.attribute3 net_days , rt.term_id 
FROM apps.HZ_CUSTOMER_PROFILES hcp,
     apps.ra_terms rt,
     apps.hz_cust_accounts hca
WHERE 1=1 --CUST_ACCOUNT_ID = 307405
AND hcp.standard_terms = rt.term_id
AND hca.cust_account_id = hcp.cust_account_id
 --AND RT.NAME = 'MTON060110N030'
AND hca.status = 'A'
AND rt.name not like 'N%'
AND rt.name not like 'IM%'
AND rt.attribute3 IS NOT NULL 
GROUP BY rt.name , rt.description , rt.attribute1 , rt.attribute2, rt.name , rt.attribute3 , rt.term_id;
 
vl_pay_terms NUMBER := 0;
vl_disc_terms NUMBER := 0;
BEGIN
  FOR C1_rec IN C1 
  LOOP
    BEGIN 
      UPDATE ra_terms_lines
      SET due_days = c1_rec.net_days, --attribute3,
          due_day_of_month = null,
          due_months_forward = null
      WHERE term_id = c1_rec.term_id;
       
      IF SQL%ROWCOUNT >0 
      THEN 
        vl_pay_terms := vl_pay_terms +1 ;
      END IF;
      
      IF c1_rec.discount_days != '00' 
      THEN
        UPDATE apps.RA_TERMS_LINES_DISCOUNTS 
        set discount_days  = c1_Rec.discount_Days,
            discount_day_of_month   = null,
            discount_months_forward = null
        WHERE term_id  = c1_rec.term_id;


        IF SQL%ROWCOUNT >0 
        THEN 
          vl_disc_terms := vl_disc_terms +1 ;
        END IF;
      END IF;
   
    EXCEPTION 
      WHEN OTHERS
      THEN 
        rollback;
       DBMS_OUTPUT.PUT_LINE('Error while updating the due days for payment term' || c1_rec.name);
    END;
    COMMIT;   

  END LOOP;
  
 dbms_output.put_line('Total Payment terms '|| vl_pay_terms|| 'Updated ');  
 dbms_output.put_line('Total disc terms '|| vl_disc_terms|| 'Updated ');
END;


SET TERM ON
PROMPT Payment terms updated successfully
SET TERM OFF

