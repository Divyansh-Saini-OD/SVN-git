-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |  Providge Consulting                                                                       |
-- +============================================================================================+
-- |  Name:  xx_fin_check_digit                                                                 |
-- |  Description:  This package is used to process the Consolidated Bill and Invoices          |
-- |                to print the scanline in the payment coupon.                                |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         22-Jul-2007  Greg Dill        Initial version                                  |
-- | 1.1         03-Jun-2008  Brian J Looman   Updated check digit logic to return 0, not 10    |
-- |                                             Defect 7629                                    |
-- +============================================================================================+
CREATE OR REPLACE FUNCTION APPS.xx_fin_check_digit (p_account_number VARCHAR2,
                                               p_invoice_number VARCHAR2,
                                               p_amount         VARCHAR2) RETURN VARCHAR2 IS
  v_account_number       VARCHAR2(8) := LPAD(REPLACE(p_account_number,' ','0'),8,'0');
  v_account_number_cd    NUMBER;
  v_invoice_number       VARCHAR2(12) := LPAD(REPLACE(p_invoice_number,' ','0'),12,'0');
  v_invoice_number_cd    NUMBER;
  v_amount               VARCHAR2(11) := LPAD(REPLACE(REPLACE(p_amount,' ','0'),'-','0'),11,'0');
  v_amount_cd            NUMBER;
  v_value_out            VARCHAR2(50);
  v_final_cd             NUMBER;

  FUNCTION f_check_digit (v_string VARCHAR2) RETURN NUMBER IS
    v_sum     NUMBER := 0;
    v_weight  NUMBER;
    v_product NUMBER;
  BEGIN
    FOR i in 1..length(v_string) LOOP
      /* Set the weight based on the character space */
      If mod(i,2) = 0 Then
        v_weight := 2;
      Else
        v_weight := 1;
      End If;

      /* Calculate the weighted procduct */
      v_product := SUBSTR(v_string, i, 1) * v_weight;

      /* Add the digit or digits to the sum */
      IF LENGTH(v_product) = 1 THEN
        v_sum := v_sum + v_product;
      ELSE
        v_sum := v_sum + SUBSTR(v_product,1,1) + SUBSTR(v_product,2);
      END IF;
    END LOOP;

    /* Check digit is 10-the mod10 of the sum */
    IF (MOD(v_sum,10) = 0) THEN   -- defect 7629
      v_sum := 0;
    ELSE
      v_sum := 10-MOD(v_sum,10);
    END IF;
    
    RETURN v_sum;
  END;

BEGIN
  /* Calculate the account check digit */
  v_account_number_cd := f_check_digit(v_account_number);

  /* Calculate the invoice check digit */
  v_invoice_number_cd := f_check_digit(v_invoice_number);

  /* Set the amount check digit */
  IF p_amount > 0 THEN
    v_amount_cd := 1;
  ELSE
    v_amount_cd := 0;
  END IF;

  /* Calculate the final check digit */
  v_final_cd := f_check_digit(v_account_number||v_account_number_cd||v_invoice_number||v_invoice_number_cd||v_amount||v_amount_cd);

  /* Build and return the out value */
  v_value_out := v_account_number||v_account_number_cd||' '||v_invoice_number||v_invoice_number_cd||' '||v_amount||' '||v_amount_cd||' '||v_final_cd;
  RETURN v_value_out;
END;
/