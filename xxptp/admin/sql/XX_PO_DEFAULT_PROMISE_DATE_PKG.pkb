SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY XX_PO_DEFAULT_PROMISE_DATE_PKG
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XX_PO_DEFAULT_PROMISE_DATE_PKG                                       |
-- | Description      : Package Body containing function CALC_PROMISE_DATE                   |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   26-MAY-2007      Madhusudan Aray   Initial draft version                      |
-- |DRAFT 1B   04-JUN-2007      Madhusudan Aray   Updated after RCCL                         |
-- |1.0        13-JUN-2007      Vikas Raina       Baselined                                  |
-- |1.1        18-JUL-2007      Santosh Borude    Updated to remove TO_DATE function for date|
-- |1.2        10-AUG-2007      Siddharth Singh   Added OR clause to first IF condition for  |
-- |                                              revision greater than 0.                   |
-- |                                              Update as per the Prioritization list for  |
-- |                                              Purchasing RICE change:                    |
-- |                                              Added a condition in the starting IF       |
-- |                                              conditions of the CALC_PROMISE_DATE package|
-- |                                              function to check for the promise date for |
-- |                                              the PO with revision other than 0. So when |
-- |                                              the promise date is blank, then the program|
-- |                                              needs to default the promise date.         |
-- |1.3       24-SEP-2007      Seemant Gour     1)Removed check for PO_type from the package |
-- |                                              as it has been done while calling from     |
-- |                                              CUSTOM.pll                                 |
-- |                                            2)Replaced with NULL instead for raising     |
-- |                                              custom exception from the SQL's and also   |
-- |                                              removed the custom exception from the code |
-- |                                            3)Changed the Return to hardcoded the        |
-- |                                              timestamp to 23:59:00 in the return        |
-- |                                              statement.                                 |
-- |1.4       12-NOV-2007      Seemant Gour     1)Removed check for PO revision and now      |
-- |                                              irrespective of the revision number, the   |
-- |                                              user entered date will be compared with the|
-- |                                              new store open date and the greater will be|
-- |                                              defaulted.                                 |
-- +=========================================================================================+

AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : CALC_PROMISE_DATE                                                    |
-- | Description      : This function is used to derive the promise date.                    |
-- | Parameters       : p_item                                                               |
-- |                    p_supplier                                                           |
-- |                    p_po_type                                                            |
-- |                    p_revision_num                                                       |
-- |                    p_order_date                                                         |
-- |                    p_promise_date                                                       |
-- |                    p_ship_to_location_id                                                |
-- |                    x_error_status (0 - Success; 1 - Error in leadtime rtn; 2 - Error in |
-- |                                    calc promise date routine)                           |
-- +=========================================================================================+
   FUNCTION  CALC_PROMISE_DATE (  p_item                IN  NUMBER --Change as per Vesion 1.1
                                 ,p_supplier            IN  NUMBER
                                 ,p_po_type             IN  VARCHAR2
                                 ,p_revision_num        IN  NUMBER
                                 ,p_order_date          IN  VARCHAR2
                                 ,p_promise_date        IN  VARCHAR2
                                 ,p_ship_to_location_id IN  NUMBER
                                 ,p_ship_to_org_id      IN  NUMBER
                                 ,x_error_status        OUT NUMBER )

    RETURN DATE 
    IS

        -- Local Variable declaration
        ld_attr3_date         DATE := NULL; -- Date to identify existing or new store.
        ld_calc_promise_date  DATE := NULL;
        ld_exp_receipt_date   DATE := NULL ;
        ln_organization_id    hr_all_organization_units.organization_id%TYPE := NULL;
        
        -- Exception declaration
        EX_CALCPROMDTE        EXCEPTION ;


    BEGIN
       
         -- Initialize error status to 0
         x_error_status := 0 ;

               BEGIN

                   SELECT TO_DATE(haou.attribute3,'DD-MON-RR')
                          ,haou.organization_id
                   INTO   ld_attr3_date
                          ,ln_organization_id
                   FROM   hr_all_organization_units  haou
                   WHERE  organization_id = p_ship_to_org_id
                   AND    SYSDATE BETWEEN NVL(haou.date_from,SYSDATE-1) AND NVL(haou.date_to,SYSDATE+1)
                   AND    ROWNUM = 1;

               EXCEPTION
                   WHEN OTHERS THEN   --Change as per Vesion 1.1
                        NULL;
               END;

               -- Check for status of store if it is already open or new store.
               BEGIN

                   SELECT TO_DATE(store_dir_rcv_date,'DD-MON-RR')
                   INTO   ld_exp_receipt_date
                   FROM   xxmer_new_store_reloc_param
                   WHERE  loc_id = ln_organization_id ;

               EXCEPTION
                  WHEN OTHERS THEN  --Change as per Vesion 1.1
                       NULL;
               END ;

               IF p_promise_date IS NULL THEN   -- When Promise date is NULL

                   /*Call the lead-time routine(XX_PO_CALCPROMDTE_PKG) for promise date.*/
                   BEGIN
                      XX_PO_CALCPROMDTE_PKG.XX_PO_CALCPROMDTE_PKG( p_order_dt => (TO_DATE(p_order_date,'DD-MON-RR HH24:MI:SS'))
                                                                 , p_supplier => p_supplier
                                                                 , p_location => ln_organization_id
                                                                 , p_item     => p_item
                                                                 , p_prom_dt  => ld_calc_promise_date
                                                                 );
                       IF ld_calc_promise_date IS NULL THEN
                          RAISE EX_CALCPROMDTE;
                       END IF;

                   EXCEPTION
                       WHEN OTHERS THEN
                            RAISE EX_CALCPROMDTE;
                   END;

                   /* Check for a new store */
                   IF ((ld_attr3_date IS NOT NULL) or (ld_attr3_date > TRUNC(SYSDATE))) THEN  --Change as per Vesion 1.1
                     
                      -- When promise date is greater than expected receipt date
                      IF ld_exp_receipt_date IS NULL THEN --Change as per Vesion 1.1
                         RETURN (TO_DATE(TO_CHAR(ld_calc_promise_date,'DD-MON-RR')|| ' 23:59:00','DD-MON-RR HH24:MI:SS'));
                      ELSIF ld_calc_promise_date > ld_exp_receipt_date THEN
                         RETURN (TO_DATE(TO_CHAR(ld_calc_promise_date,'DD-MON-RR')|| ' 23:59:00','DD-MON-RR HH24:MI:SS'));
                      ELSE
                         RETURN (TO_DATE(TO_CHAR(ld_exp_receipt_date,'DD-MON-RR')|| ' 23:59:00','DD-MON-RR HH24:MI:SS'));
                      END IF;
                   
                   -- For existing store
                   ELSE
                      RETURN (TO_DATE(TO_CHAR(ld_calc_promise_date,'DD-MON-RR')|| ' 23:59:00','DD-MON-RR HH24:MI:SS'));
                   END IF;
               
               ELSE  -- When Promise date is entered by User
                  
                  /* For User entered date */
                  IF ((ld_attr3_date IS NOT NULL) or (ld_attr3_date > TRUNC(SYSDATE))) THEN  --Change as per Vesion 1.1
                     
                     IF ld_exp_receipt_date IS NULL THEN
                        RETURN (TO_DATE(p_promise_date,'DD-MON-RR HH24:MI:SS'));
                     ELSIF TRUNC(TO_DATE(p_promise_date,'DD-MON-RR HH24:MI:SS')) > TRUNC(ld_exp_receipt_date) THEN
                        RETURN (TO_DATE(p_promise_date,'DD-MON-RR HH24:MI:SS'));
                     ELSE
                        RETURN (TO_DATE(TO_CHAR(ld_exp_receipt_date,'DD-MON-RR')|| ' 23:59:00','DD-MON-RR HH24:MI:SS'));
                     END IF;
                  
                  ELSE
                     RETURN (TO_DATE(p_promise_date,'DD-MON-RR HH24:MI:SS'));
                  END IF;
               
               END IF;

    EXCEPTION
       WHEN EX_CALCPROMDTE THEN
             x_error_status := 1 ;
             RETURN (TO_DATE(p_promise_date,'DD-MON-RR HH24:MI:SS'));
       WHEN OTHERS THEN
          -- x_error_status := 2 ;--Change as per Vesion 1.1
             RAISE;
    END CALC_PROMISE_DATE;
    
END XX_PO_DEFAULT_PROMISE_DATE_PKG;
/

SHOW ERRORS;

EXIT;