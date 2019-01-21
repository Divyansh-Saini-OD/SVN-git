SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_INT_EBS_AP_PAY_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

/********************************************************************************************************************
*   Name:        XX_AP_C2FO_INT_EBS_AP_PAY_PKG
*   PURPOSE:     
*   REVISIONS:
*   Ver          Date             Author                        Company           Description
*   ---------    ----------       ---------------               ----------        -----------------------------------
*   1.0          9/2/2018          Antonio Morales              OD                OD Initial Customized Version
*********************************************************************************************************************/
 
CREATE OR REPLACE PACKAGE BODY XX_AP_C2FO_INT_EBS_AP_PAY_PKG IS
    --+=====================================================================================================+
    --    FUNCTION pay_term_early_due_date, Starts Here.
    --+=====================================================================================================+
 FUNCTION pay_term_early_due_date ( p_org_id           IN NUMBER,
                                    p_invoice_id    IN NUMBER) RETURN VARCHAR2 IS

    l_due_date               DATE;
    l_discount_date          DATE;
    l_second_discount_date   DATE;
    l_third_discount_date    DATE;
    r_due_date               VARCHAR2(10);
    l_payment_num            NUMBER;

BEGIN
    -- Modified for performance
    BEGIN 
        SELECT MIN(apsa.payment_num)
          INTO l_payment_num
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
             WHEN OTHERS THEN
                  l_payment_num := 1;           
    END;
    -- Modified for performance
    BEGIN 
        SELECT apsa.discount_date,
               apsa.second_discount_date,
               apsa.third_discount_date,
               apsa.due_date
          INTO l_discount_date,
               l_second_discount_date,
               l_third_discount_date,
               l_due_date
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_num =l_payment_num
           AND apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
             WHEN OTHERS THEN
                  r_due_date := null;

    END;

		-- OfficeDepot still uses the discount due_date though the date passed SYSDATE
        --IF        l_discount_date IS NOT NULL AND SYSDATE < l_discount_date THEN
		IF        l_discount_date IS NOT NULL THEN
                    r_due_date :=  TO_CHAR(l_discount_date,'YYYY-MM-DD');                    
        ELSIF     l_second_discount_date IS NOT NULL AND SYSDATE < l_second_discount_date THEN
                    r_due_date := TO_CHAR(l_second_discount_date,'YYYY-MM-DD');                    
        ELSIF     l_third_discount_date IS NOT NULL AND SYSDATE < l_third_discount_date THEN
                    r_due_date := TO_CHAR(l_third_discount_date,'YYYY-MM-DD');                
        ELSE
                r_due_date := TO_CHAR(l_due_date,'YYYY-MM-DD');                
        END IF;

        RETURN     r_due_date;

END pay_term_early_due_date;

    --+=====================================================================================================+
    --    FUNCTION pay_term_early_due_date, Ends Here.
    --+=====================================================================================================+

    --+=====================================================================================================+
    --    FUNCTION amt_or_amt_netvat_after_disc, Starts Here.
    --+=====================================================================================================+

 FUNCTION amt_or_amt_netvat_after_disc ( p_org_id        IN NUMBER,
                                         p_invoice_id    IN NUMBER) RETURN NUMBER IS

    l_inv_lines_item_amount         NUMBER;
    l_due_inv_amount                NUMBER;
    r_discount_amount               NUMBER;
    l_discount_amount_available     NUMBER;
    l_second_disc_amt_available     NUMBER;
    l_third_disc_amt_available      NUMBER;
    l_due_date                      DATE;
    l_discount_date                 DATE;
    l_second_discount_date          DATE;
    l_third_discount_date           DATE;
    r_due_date                      DATE;
    l_payment_num                   NUMBER;

BEGIN

    BEGIN 
		-- Modified for performance
        SELECT NVL((NVL(aia.invoice_amount,0)-NVL(aia.total_tax_amount,0)),0)                
          INTO l_inv_lines_item_amount                
          FROM ap_invoices_all aia
         WHERE aia.invoice_id = p_invoice_id
           AND aia.org_id+0 = p_org_id;           

        EXCEPTION
        WHEN OTHERS THEN l_inv_lines_item_amount :=0;
    END;

    BEGIN
		-- Modified for performance
        SELECT MIN(apsa.payment_num)
          INTO l_payment_num
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
             WHEN OTHERS THEN
                  l_payment_num := 1;           
    END;    
	-- Modified for performance
    BEGIN 
        SELECT apsa.discount_amount_available,
               apsa.second_disc_amt_available,
               apsa.third_disc_amt_available,
               apsa.discount_date,
               apsa.second_discount_date,
               apsa.third_discount_date,
               apsa.due_date
          INTO l_discount_amount_available,
               l_second_disc_amt_available,
               l_third_disc_amt_available,
               l_discount_date,
               l_second_discount_date,
               l_third_discount_date,
               l_due_date
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_num =l_payment_num
           AND apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
        WHEN OTHERS THEN r_discount_amount :=0;      
    END;

      --  IF l_discount_date IS NOT NULL AND SYSDATE < l_discount_date THEN
	    IF l_discount_date IS NOT NULL THEN
            r_discount_amount := l_discount_amount_available;
        ELSIF l_second_discount_date IS NOT NULL AND SYSDATE < l_second_discount_date THEN
            r_discount_amount := l_second_disc_amt_available;
        ELSIF l_third_discount_date IS NOT NULL AND SYSDATE < l_third_discount_date THEN
            r_discount_amount := l_third_disc_amt_available;
        ELSE r_discount_amount :=0;
        END IF;

        l_due_inv_amount := l_inv_lines_item_amount - r_discount_amount;

        RETURN l_due_inv_amount;
END amt_or_amt_netvat_after_disc;

    --+=====================================================================================================+
    --    FUNCTION amt_or_amt_netvat_after_disc, Ends Here.
    --+=====================================================================================================+ 

    --+=====================================================================================================+
    --    FUNCTION amount_grossvat_after_disc, Starts Here.
    --+=====================================================================================================+

 FUNCTION amount_grossvat_after_disc ( p_org_id        IN NUMBER,
                                       p_invoice_id    IN NUMBER) RETURN NUMBER IS

    l_invoice_amt                   NUMBER;
    l_due_inv_amount                NUMBER;
    r_discount_amount               NUMBER;
    l_discount_amount_available     NUMBER;
    l_second_disc_amt_available     NUMBER;
    l_third_disc_amt_available      NUMBER;
    l_due_date                      DATE;
    l_discount_date                 DATE;
    l_second_discount_date          DATE;
    l_third_discount_date           DATE;
    r_due_date                      DATE;
    l_payment_num                   NUMBER;

BEGIN

    BEGIN 
		-- Modified for performance
        SELECT NVL(aia.invoice_amount,0)     
          INTO l_invoice_amt                
          FROM ap_invoices_all aia
         WHERE aia.invoice_id = p_invoice_id
           AND aia.org_id+0 = p_org_id;           

        EXCEPTION
        WHEN OTHERS THEN l_invoice_amt :=0;
    END;


    BEGIN
		-- Modified for performance
        SELECT MIN(apsa.payment_num)
          INTO l_payment_num
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
             WHEN OTHERS THEN l_payment_num := 1;           
    END;    
	-- Modified for performance
    BEGIN 
        SELECT apsa.discount_amount_available,
               apsa.second_disc_amt_available,
               apsa.third_disc_amt_available,
               apsa.discount_date,
               apsa.second_discount_date,
               apsa.third_discount_date,
               apsa.due_date
          INTO l_discount_amount_available,
               l_second_disc_amt_available,
               l_third_disc_amt_available,
               l_discount_date,
               l_second_discount_date,
               l_third_discount_date,
               l_due_date
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_num =l_payment_num
           AND apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
        WHEN OTHERS THEN r_discount_amount :=0;      
    END;

        --IF l_discount_date IS NOT NULL AND SYSDATE < l_discount_date THEN
		IF l_discount_date IS NOT NULL THEN
            r_discount_amount := l_discount_amount_available;
        ELSIF l_second_discount_date IS NOT NULL AND SYSDATE < l_second_discount_date THEN
            r_discount_amount := l_second_disc_amt_available;
        ELSIF l_third_discount_date IS NOT NULL AND SYSDATE < l_third_discount_date THEN
            r_discount_amount := l_third_disc_amt_available;
        ELSE r_discount_amount :=0;
        END IF;

        l_due_inv_amount := l_invoice_amt - r_discount_amount;

        RETURN l_due_inv_amount;
END amount_grossvat_after_disc;

    --+=====================================================================================================+
    --    FUNCTION amount_grossvat_after_disc, Ends Here.
    --+=====================================================================================================+     

    --+=====================================================================================================+
    --    FUNCTION ebs_cash_discount_amt, Starts Here.
    --+=====================================================================================================+

 FUNCTION ebs_cash_discount_amt ( p_org_id        IN NUMBER,
                                  p_invoice_id    IN NUMBER) RETURN NUMBER IS

    l_discount_amount               NUMBER;
    r_discount_amount               NUMBER;
    l_discount_amount_available     NUMBER;
    l_second_disc_amt_available     NUMBER;
    l_third_disc_amt_available      NUMBER;
    l_due_date                      DATE;
    l_discount_date                 DATE;
    l_second_discount_date          DATE;
    l_third_discount_date           DATE;
    r_due_date                      DATE;
    l_payment_num                   NUMBER;

BEGIN


    BEGIN
		-- Modified for performance
        SELECT MIN(apsa.payment_num)
          INTO l_payment_num
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
             WHEN OTHERS THEN l_payment_num := 1;           
    END;    
	-- Modified for performance
    BEGIN 
        SELECT apsa.discount_amount_available,
               apsa.second_disc_amt_available,
               apsa.third_disc_amt_available,
               apsa.discount_date,
               apsa.second_discount_date,
               apsa.third_discount_date,
               apsa.due_date
          INTO l_discount_amount_available,
               l_second_disc_amt_available,
               l_third_disc_amt_available,
               l_discount_date,
               l_second_discount_date,
               l_third_discount_date,
               l_due_date
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_num =l_payment_num
           AND apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;


        EXCEPTION
        WHEN OTHERS THEN r_discount_amount :=0;      
    END;

		--IF l_discount_date IS NOT NULL AND SYSDATE < l_discount_date THEN
        IF l_discount_date IS NOT NULL THEN
            r_discount_amount := l_discount_amount_available;
        ELSIF l_second_discount_date IS NOT NULL AND SYSDATE < l_second_discount_date THEN
            r_discount_amount := l_second_disc_amt_available;
        ELSIF l_third_discount_date IS NOT NULL AND SYSDATE < l_third_discount_date THEN
            r_discount_amount := l_third_disc_amt_available;
        ELSE r_discount_amount :=0;
        END IF;

        l_discount_amount := r_discount_amount;

        RETURN l_discount_amount;

END ebs_cash_discount_amt;

    --+=====================================================================================================+
    --    FUNCTION ebs_cash_discount_amt, Ends Here.
    --+=====================================================================================================+ 

    --+=====================================================================================================+
    --    FUNCTION local_currency_org_inv_amount, Starts Here.
    --+=====================================================================================================+

 FUNCTION local_currency_org_inv_amount ( p_org_id        IN NUMBER,
                                          p_invoice_id    IN NUMBER) RETURN NUMBER IS

    l_pay_curr_invoice_amt            NUMBER;
    l_pay_curr_inv_amt_after_disc     NUMBER;
    l_payment_cross_rate              NUMBER;    
    l_pay_curr_disc_amt               NUMBER;

    l_discount_amount                 NUMBER;
    r_discount_amount                 NUMBER;
    l_discount_amount_available       NUMBER;
    l_second_disc_amt_available       NUMBER;
    l_third_disc_amt_available        NUMBER;
    l_due_date                        DATE;
    l_discount_date                   DATE;
    l_second_discount_date            DATE;
    l_third_discount_date             DATE;
    r_due_date                        DATE;
    l_payment_num                     NUMBER;

BEGIN

    BEGIN 
		-- Modified for performance
        SELECT NVL(aia.pay_curr_invoice_amount,0) ,
               NVL(aia.payment_cross_rate,1)         
          INTO l_pay_curr_invoice_amt,                
               l_payment_cross_rate
          FROM ap_invoices_all aia
         WHERE aia.invoice_id = p_invoice_id
           AND aia.org_id+0 = p_org_id;           

        EXCEPTION
        WHEN OTHERS THEN
             l_pay_curr_invoice_amt :=0;
             l_payment_cross_rate :=1;
    END;

    BEGIN
		-- Modified for performance
        SELECT MIN(apsa.payment_num)
          INTO l_payment_num
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;

        EXCEPTION
             WHEN OTHERS THEN l_payment_num := 1;           
    END;    
	-- Modified for performance
    BEGIN 
        SELECT apsa.discount_amount_available,
               apsa.second_disc_amt_available,
               apsa.third_disc_amt_available,
               apsa.discount_date,
               apsa.second_discount_date,
               apsa.third_discount_date,
               apsa.due_date
          INTO l_discount_amount_available,
               l_second_disc_amt_available,
               l_third_disc_amt_available,
               l_discount_date,
               l_second_discount_date,
               l_third_discount_date,
               l_due_date
          FROM ap_payment_schedules_all apsa
         WHERE apsa.payment_num =l_payment_num
           AND apsa.payment_status_flag||'' ='N'
           AND apsa.invoice_id = p_invoice_id
           AND apsa.org_id+0 = p_org_id;


        EXCEPTION
        WHEN OTHERS THEN r_discount_amount :=0;      
    END;

        --IF l_discount_date IS NOT NULL AND SYSDATE < l_discount_date THEN
		IF l_discount_date IS NOT NULL THEN
            r_discount_amount := l_discount_amount_available;
        ELSIF l_second_discount_date IS NOT NULL AND SYSDATE < l_second_discount_date THEN
            r_discount_amount := l_second_disc_amt_available;
        ELSIF l_third_discount_date IS NOT NULL AND SYSDATE < l_third_discount_date THEN
            r_discount_amount := l_third_disc_amt_available;
        ELSE r_discount_amount :=0;
        END IF;

        l_discount_amount := NVL(r_discount_amount,0);

        l_pay_curr_disc_amt := l_discount_amount*l_payment_cross_rate;

        l_pay_curr_inv_amt_after_disc := l_pay_curr_invoice_amt-l_pay_curr_disc_amt;
		
		

        RETURN l_pay_curr_inv_amt_after_disc;

END local_currency_org_inv_amount;

    --+=====================================================================================================+
    --    FUNCTION local_currency_org_inv_amount, Ends Here.
    --+=====================================================================================================+     

    --+=====================================================================================================+
    --    FUNCTION paid_invoice_id, Starts Here.
    --+=====================================================================================================+

 FUNCTION paid_invoice_id ( p_org_id            IN NUMBER,
                            p_invoice_id        IN NUMBER,
                            p_transaction_type  IN NUMBER) RETURN NUMBER IS

    l_check_id      NUMBER;
    l_invoice_id    NUMBER;

BEGIN
    -- Modified for performance
    IF p_transaction_type = 2 THEN

        BEGIN

            SELECT aipa2.check_id
              INTO l_check_id
              FROM ap_invoice_payments_all aipa2,
                   ap_invoices_all aia2 
             WHERE aia2.invoice_id=p_invoice_id
			   AND aia2.org_id=p_org_id
			   AND aia2.invoice_type_lookup_code != 'STANDARD'
			   AND aipa2.invoice_id = aia2.invoice_id
               AND aipa2.org_id = aia2.org_id;

        EXCEPTION
        WHEN OTHERS THEN l_check_id :=0;
        END;
	    -- Modified for performance
        BEGIN

            SELECT aia.invoice_id
              INTO l_invoice_id
              FROM ap_invoices_all aia,
				   ap_invoice_payments_all aipa
             WHERE aipa.check_id = l_check_id
			   AND aia.invoice_id=aipa.invoice_id
               AND aia.org_id=aipa.org_id
               AND aia.invoice_type_lookup_code = 'STANDARD';
               

        EXCEPTION
        WHEN OTHERS THEN l_invoice_id :=NULL;
        END;    

    ELSE
        l_invoice_id :=NULL;

    END IF;        

    RETURN l_invoice_id;

END paid_invoice_id;

    --+=====================================================================================================+
    --    FUNCTION paid_invoice_id, Ends Here.
    --+=====================================================================================================+     

END xx_ap_c2fo_int_ebs_ap_pay_pkg;
/

SHOW ERRORS
