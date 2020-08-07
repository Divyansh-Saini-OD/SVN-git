create or replace
PACKAGE BODY XX_AR_BILL_EXCEPTIONS_PKG
AS

gn_org_id NUMBER := FND_PROFILE.VALUE('ORG_ID'); --Added for the defect#13420
TYPE lt_cust_bill_exp IS TABLE OF XX_AR_BILL_EXCEPT_BILL%ROWTYPE INDEX BY BINARY_INTEGER;
cust_bill_exp  lt_cust_bill_exp;

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_BILL_EXCEPTIONS_PKG                                    |
-- | RICE ID :  R0539                                                    |
-- | Description :This package is to validate billing exceptions         |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  15-FEB-09      Jennifer Jegam         Initial version      |
-- |1.1       28-FEB-09     Kantharaja           Changes for             |
-- |                        Velayutham           the defect#13420        |
-- |1.2       10-MAR-09     Manovinayak          Made performance changes|
-- |                        Ayyappan             for the defect#13420    |
-- |1.3       23-MAR-09     Agnes                Made performance changes|
-- |                          Poornima           for the defect#13420    |
-- |1.4       02-JUL-09     Agnes                Made performance changes|
-- |                          Poornima           for the defect#445      |
-- |1.5       02-MAR-10     Tamil Vendhan L      Modified for R1.3 CR 738|
-- |                                             Defect 2766             |
-- |1.6       01-JUN-2010   Ranjith Thangasamy   For DEfect 2811         |
-- |1.7       13-OCT-2010   Sneha Anand          Modified for Defect 6733|
-- |                                             invalid cust DOC ID     |
-- |                                             Exception error         |
-- |1.7       26-OCT-2010   Sneha Anand          Modified for Defect 6733|
-- |                                             to remove Start date and|
-- |1.8       03-JUL-2012   Archana N.           Added the outer join    |
-- |                                             defect# 17888           |
-- |1.9       19-OCT-2015   Havish Kasina        Removed the schema names| 
-- |                                             in the existing code    |
-- +=====================================================================+

gd_effec_date      DATE := TRUNC(SYSDATE);           -- Added for R1.3 CR 738 Defect 2766

PROCEDURE XX_AR_BILL_MAIN_PROC(
                                x_err_buff           OUT VARCHAR2 --Added for the defect#13420
                               ,x_ret_code           OUT NUMBER   --Added for the defect#13420
--                               ,p_cust_id_from       IN  NUMBER   --Added for the defect#13420
--                               ,p_cust_id_to         IN  NUMBER   --Added for the defect#13420
                               ,p_request_id         IN  NUMBER   --Added for the defect#13420
--                               ,p_last_upd_date_from IN  DATE   --Commented for the defect#13420
--                               ,p_last_upd_date_to   IN  DATE   --Commented for the defect#13420
                              )
AS

--Variable Declaration

lc_payment_count           NUMBER;
lc_indicator_count         NUMBER;
lc_paydoc_count            NUMBER;
lc_spl_count               NUMBER;
lc_custdoc_count           NUMBER;
lc_address_count           NUMBER;
lc_billto_count            NUMBER;
lc_billdocs_doctype        VARCHAR2(40);
lc_billdocs_docid          NUMBER;
lc_billdocs_delivery_meth  VARCHAR2(10);
lc_code                    VARCHAR2(10);
lc_cust_prev               NUMBER;
lc_bill_count              NUMBER;
ln_child_req_id            NUMBER;

CURSOR lcu_ar_main(--p_cust_id_from        NUMBER  --Commented for the defect#13420
                  --,p_cust_id_to          NUMBER  --Commented for the defect#13420
                   p_req_id              NUMBER
--                  ,p_last_upd_date_from  DATE    --Commented for the defect#13420
--                  ,p_last_upd_date_to    DATE    --Commented for the defect#13420
                  )
IS
SELECT   HP.party_name                             CUSTOMER_NAME
        ,HCA.account_number                        CUSTOMER_NUMBER
        ,HCA.orig_system_reference                 LEGACY_NUMBER
        ,RT.name                                   PAYMENT_TERM
        ,HCA.cust_account_id                       CUSTOMER_ID
        ,RT.term_id                                TERM_ID
        ,HCP.cons_inv_flag                         CONS_INV_FLAG
        ,HCA.attribute18                           ATTRIBUTE18
        ,XCAEB.c_ext_attr2                         BILLDOCS_PAYDOC_IND
        ,XCAEB.c_ext_attr14                        BILLDOCS_PAYMENT_TERM
        ,XCAEB.c_ext_attr4                         BILLDOCS_SPECIAL_HANDLING
        ,XCAEB.c_ext_attr1                         BILLDOCS_DOC_TYPE
        ,TRUNC(SUBSTR(XCAEB.n_ext_attr1 ,1,1))     BILLDOCS_DOC_ID
        ,XCAEB.c_ext_attr3                         DELIVERY_METHOD
        ,XCAEB.c_ext_attr2                         PAYDOC_INDICATOR
        ,XCAEB.n_ext_attr2                         BILLDOCS_CUST_ID
        ,NULL                                      CUSTOMER_SITE
        ,XCAEB.c_ext_attr13                        BILLDOCS_COMBO_TYPE
        ,XCAEB.c_ext_attr7                         DIRECT_FLAG
        ,XCAEB.attr_group_id
  FROM   hz_parties             HP
        --,hz_cust_accounts       HCA    --Commented for the defect#13420
        ,hz_customer_profiles   HCP
        ,ra_terms               RT
        ,xx_cdh_cust_acct_ext_b XCAEB
        ,xx_ar_bill_cust_acct   HCA
  WHERE  1=1
  AND    HCA.party_id             = HP.party_id
  AND    HCA.cust_account_id      = HCP.cust_account_id
  AND    RT.term_id               = HCP.standard_terms
  AND    XCAEB.cust_account_id(+) = HCA.cust_account_id
  AND    HCP.site_use_id            IS NULL
--  AND    UPPER(HCA.attribute18)     IN ('CONTRACT','DIRECT') --Commented for the defect#13420
--  AND    UPPER(HCA.status)        = 'A'                      --Commented for the defect#13420
--  AND    UPPER(RT.NAME)          <> 'IMMEDIATE'              --Commented for the defect#13420
  AND    XCAEB.attr_group_id (+)  = 166
  AND    HCA.request_id           = p_req_id
  AND XCAEB.c_ext_attr16 (+) = 'COMPLETE'  -- Added for defect 2811 --outer join added for defect# 17888
--  AND    HCA.cust_account_id        BETWEEN p_cust_id_from       AND p_cust_id_to       --Commented for the defect#13420
--  AND    HCA.last_update_date       BETWEEN p_last_upd_date_from AND p_last_upd_date_to;--Commented for the defect#13420
-- Added the below conditions for R1.3 CR 738 Defect 2766
  AND    gd_effec_date >= XCAEB.d_ext_attr1(+)
  AND    gd_effec_date <= NVL(XCAEB.d_ext_attr2(+),gd_effec_date);
-- End of changes for R1.3 CR 738 Defect 2766

BEGIN
       lc_cust_prev := 0;
       ln_child_req_id := FND_GLOBAL.conc_request_id;

FOR lr_ar_main IN lcu_ar_main(
                              --p_cust_id_from  --Added for the defect#13420
                              --,p_cust_id_to    --Added for the defect#13420
                              --p_last_upd_date_from  --Commented for the defect#13420
                              --,p_last_upd_date_to   --Commented for the defect#13420
                              ln_child_req_id        --Added for the defect#13420
                             )
   LOOP
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Prev at begin ' || lc_cust_prev);
     IF lc_cust_prev <> lr_ar_main.Customer_id THEN

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Customer_id: '||lr_ar_main.Customer_id );

         XX_AR_BILL_COMBO_PROC(lr_ar_main.Customer_id
                               ,lr_ar_main.Customer_Number
                               ,lr_ar_main.Customer_Name
                               ,lr_ar_main.Legacy_Number
                               ,lr_ar_main.Delivery_Method
                               ,lr_ar_main.Paydoc_Indicator
                               ,lr_ar_main.billdocs_cust_id
                               ,lr_ar_main.Customer_Site
                               ,p_request_id);              --Added for the defect#13420

              XX_AR_BILL_SITE_PROC(lr_ar_main.Customer_id
                                   ,lr_ar_main.Customer_Number
                                   ,lr_ar_main.Customer_Name
                                   ,lr_ar_main.Legacy_Number
                                   ,lr_ar_main.Delivery_Method
                                   ,lr_ar_main.Paydoc_Indicator
                                   ,lr_ar_main.billdocs_cust_id
                                   ,lr_ar_main.Customer_Site
                                   ,p_request_id);              --Added for the defect#13420
         
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Combo Call' );

              XX_AR_INFODOC_FREQ_PROC(lr_ar_main.Customer_id
                                      ,lr_ar_main.Customer_Number
                                      ,lr_ar_main.Customer_Name
                                      ,lr_ar_main.Legacy_Number
                                      ,lr_ar_main.Delivery_Method
                                      ,lr_ar_main.Paydoc_Indicator
                                      ,lr_ar_main.billdocs_cust_id
                                      ,lr_ar_main.Customer_Site
                                      ,p_request_id
                                      );              --Added for the defect#13420

            --Missing Paydoc error
            IF (lr_ar_main.attribute18 = 'CONTRACT') THEN
               BEGIN
                  SELECT count(*)
                  INTO lc_bill_count
                  --FROM xx_cdh_a_ext_billdocs_v XCAEB   --Commented for the defect#13420
                  FROM xx_cdh_cust_acct_ext_b  XCAEB     --Added for the defect#13420
                  WHERE 1=1
                  AND XCAEB.cust_Account_id     = lr_ar_main.Customer_id --Removed (+) for the defect#13420
                  AND XCAEB.attr_group_id       = 166                    --Added for the defect#13420
                --AND XCAEB.billdocs_paydoc_ind = 'Y'                    --Commented for the defect#13420
                  AND XCAEB.c_ext_attr2         = 'Y'                    --Added for the defect#13420
                --  GROUP BY lr_ar_main.Customer_id;
                  -- Added for R1.3 CR 738 Defect 2766
                  AND    gd_effec_date >= XCAEB.d_ext_attr1
                  AND    (XCAEB.d_ext_attr2 IS NULL 
                          OR
                          gd_effec_date <= XCAEB.d_ext_attr2)
                  -- End of changes for R1.3 CR 738 Defect 2766
                  AND XCAEB.c_ext_attr16  = 'COMPLETE';   -- Added for CR 586 - Defect 2811

                  IF (lc_bill_count <1 ) THEN
                  lc_code := '50';
                  XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                         ,lr_ar_main.Customer_Number
                                         ,lr_ar_main.Customer_Name
                                         ,lr_ar_main.Legacy_Number
                                         ,lr_ar_main.Delivery_Method
                                         ,lr_ar_main.Paydoc_Indicator
                                         ,lr_ar_main.billdocs_cust_id
                                         ,lr_ar_main.Customer_Site
                                         ,lc_code
                                         ,p_request_id);              --Added for the defect#13420


                  END IF;
               EXCEPTION
                  WHEN  OTHERS THEN
                     FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM || 'Exception in missing paydoc');
               END;

               END IF;

      END IF;


 -- Payment Term Mismatch
      IF lr_ar_main.Billdocs_payment_term <> lr_ar_main.Payment_Term AND lr_ar_main.Billdocs_paydoc_ind = 'Y'  THEN
         lc_code := '10';
         XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                ,lr_ar_main.Customer_Number
                                ,lr_ar_main.Customer_Name
                                ,lr_ar_main.Legacy_Number
                                ,lr_ar_main.Delivery_Method
                                ,lr_ar_main.Paydoc_Indicator
                                ,lr_ar_main.billdocs_cust_id
                                ,lr_ar_main.Customer_Site
                                ,lc_code
                                ,p_request_id);              --Added for the defect#13420

      ELSE

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Payment Mismatch not exisits' );

      END IF;


-- Consolidated Bill Flag Mismatch

      IF  (lr_ar_main.Billdocs_paydoc_ind = 'Y' AND  lr_ar_main.Cons_inv_flag ='Y' ) THEN
           IF lr_ar_main.Billdocs_doc_type <> 'Consolidated Bill' THEN
         lc_code := '20';
         XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                  ,lr_ar_main.Customer_Number
                  ,lr_ar_main.Customer_Name
                  ,lr_ar_main.Legacy_Number
                  ,lr_ar_main.Delivery_Method
                  ,lr_ar_main.Paydoc_Indicator
                  ,lr_ar_main.billdocs_cust_id
                  ,lr_ar_main.Customer_Site
                  ,lc_code
                  ,p_request_id);              --Added for the defect#13420
           END IF;
      ELSIF  (lr_ar_main.Billdocs_paydoc_ind = 'Y' AND  lr_ar_main.Cons_inv_flag ='N' ) THEN
             IF lr_ar_main.Billdocs_doc_type = 'Consolidated Bill' THEN
         lc_code := '20';
         XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                  ,lr_ar_main.Customer_Number
                  ,lr_ar_main.Customer_Name
                  ,lr_ar_main.Legacy_Number
                  ,lr_ar_main.Delivery_Method
                  ,lr_ar_main.Paydoc_Indicator
                  ,lr_ar_main.billdocs_cust_id
                  ,lr_ar_main.Customer_Site
                  ,lc_code
                                                ,p_request_id);              --Added for the defect#13420
           END IF;
      ELSE

         FND_FILE.PUT_LINE(FND_FILE.LOG,' Consolidated Bill Mismatch not exisits');

       END IF;

   -- MBS Doc Sequence Id vs Invoice Type Mismatch Error

       IF lr_ar_main.Billdocs_doc_type = 'Invoice' and lr_ar_main.Billdocs_doc_id <> 1 THEN
          lc_code := '30';
          XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                  ,lr_ar_main.Customer_Number
                  ,lr_ar_main.Customer_Name
                  ,lr_ar_main.Legacy_Number
                  ,lr_ar_main.Delivery_Method
                  ,lr_ar_main.Paydoc_Indicator
                  ,lr_ar_main.billdocs_cust_id
                  ,lr_ar_main.Customer_Site
                  ,lc_code
                                                ,p_request_id);              --Added for the defect#13420
              FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and invoice type mismatch:');
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and invoice type no mismatch:');
      END IF;

      IF lr_ar_main.Billdocs_doc_type = 'Consolidated Bill' and lr_ar_main.Billdocs_doc_id <> 2 THEN
         lc_code := '30';
            XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                   ,lr_ar_main.Customer_Number
                                   ,lr_ar_main.Customer_Name
                                   ,lr_ar_main.Legacy_Number
                                   ,lr_ar_main.Delivery_Method
                                   ,lr_ar_main.Paydoc_Indicator
                                   ,lr_ar_main.billdocs_cust_id
                                   ,lr_ar_main.Customer_Site
                                   ,lc_code
                                   ,p_request_id);              --Added for the defect#13420
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and invoice type mismatch:');
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and invoice type no mismatch:');

      END IF;

-- MBS Doc Sequence Id vs Delivery Method Mismatch

      IF (lr_ar_main.Delivery_Method = 'ELEC' and lr_ar_main.Billdocs_doc_id <> 2) THEN
         lc_code := '40';
         XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                ,lr_ar_main.Customer_Number
                                ,lr_ar_main.Customer_Name
                                ,lr_ar_main.Legacy_Number
                                ,lr_ar_main.Delivery_Method
                                ,lr_ar_main.Paydoc_Indicator
                                ,lr_ar_main.billdocs_cust_id
                                ,lr_ar_main.Customer_Site
                                ,lc_code
                                ,p_request_id);              --Added for the defect#13420
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and method mismatch:');
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and method no mismatch:');
      END IF;


      IF (lr_ar_main.Delivery_Method = 'EDI' and lr_ar_main.Billdocs_doc_id <> 1) THEN
         lc_code := '40';
         XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                ,lr_ar_main.Customer_Number
                                ,lr_ar_main.Customer_Name
                                ,lr_ar_main.Legacy_Number
                                ,lr_ar_main.Delivery_Method
                                ,lr_ar_main.Paydoc_Indicator
                                ,lr_ar_main.billdocs_cust_id
                                ,lr_ar_main.Customer_Site
                                ,lc_code
                                ,p_request_id);              --Added for the defect#13420
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and method mismatch:');
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'MBS and method no mismatch:');

      END IF;


--Mismatch in Spl Handling


      IF (lr_ar_main.Billdocs_special_handling IS NOT NULL) THEN
        IF lr_ar_main.Billdocs_special_handling NOT IN('DONT','BJAA','SPEC','VOCH','INFO') THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,' Spl Handling Mismatch exists');
         lc_code := '120';
         XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                ,lr_ar_main.Customer_Number
                                ,lr_ar_main.Customer_Name
                                ,lr_ar_main.Legacy_Number
                                ,lr_ar_main.Delivery_Method
                                ,lr_ar_main.Paydoc_Indicator
                                ,lr_ar_main.billdocs_cust_id
                                ,lr_ar_main.Customer_Site
                                ,lc_code
                                ,p_request_id);              --Added for the defect#13420
         END IF;
                END IF;

-- Invalid Combo Type

--    IF ((lr_ar_main.Billdocs_combo_type IS NOT NULL) AND (lr_ar_main.Billdocs_combo_type not in ('DR','CR','RB'))) THEN  --Commented for the defect#13420

                IF ((lr_ar_main.Billdocs_combo_type IS NOT NULL) AND (lr_ar_main.Billdocs_combo_type NOT IN ('DB','CR'))) THEN       --Added for the defect#13420

                     lc_code := '70';
                     XX_AR_BILL_INSERT_PROC(lr_ar_main.Customer_id
                                            ,lr_ar_main.Customer_Number
                                            ,lr_ar_main.Customer_Name
                                            ,lr_ar_main.Legacy_Number
                                            ,lr_ar_main.Delivery_Method
                                            ,lr_ar_main.Paydoc_Indicator
                                            ,lr_ar_main.billdocs_cust_id
                                            ,lr_ar_main.Customer_Site
                                            ,lc_code
                                            ,p_request_id);              --Added for the defect#13420
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Combo Type:');

                ELSE
                     FND_FILE.PUT_LINE(FND_FILE.LOG,'No Invalid Combo Type:');
                END IF;

--Added for the defect#13420
--Combo type should be null for Info Docs
                IF (lr_ar_main.billdocs_paydoc_ind = 'N' AND lr_ar_main.billdocs_combo_type IS NOT NULL) THEN


                        lc_code := '160';

                        XX_AR_BILL_INSERT_PROC(
                                               lr_ar_main.Customer_id
                                              ,lr_ar_main.Customer_Number
                                              ,lr_ar_main.Customer_Name
                                              ,lr_ar_main.Legacy_Number
                                              ,lr_ar_main.Delivery_Method
                                              ,lr_ar_main.Paydoc_Indicator
                                              ,lr_ar_main.billdocs_cust_id
                                              ,lr_ar_main.Customer_Site
                                              ,lc_code
                                              ,p_request_id
                                              );

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Info Docs having Combo Type:');

                ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Info Docs did not have a Combo Type:');

                END IF;

--Added for the defect#13420
                IF (lr_ar_main.billdocs_paydoc_ind = 'Y' AND lr_ar_main.billdocs_combo_type IS NOT NULL) THEN

                    IF (lr_ar_main.Billdocs_special_handling IS NOT NULL) THEN


                        lc_code := '170';

                        XX_AR_BILL_INSERT_PROC(
                                               lr_ar_main.Customer_id
                                              ,lr_ar_main.Customer_Number
                                              ,lr_ar_main.Customer_Name
                                              ,lr_ar_main.Legacy_Number
                                              ,lr_ar_main.Delivery_Method
                                              ,lr_ar_main.Paydoc_Indicator
                                              ,lr_ar_main.billdocs_cust_id
                                              ,lr_ar_main.Customer_Site
                                              ,lc_code
                                              ,p_request_id
                                              );

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Combo Pay Docs having Special Handling codes Populated:');

                    ELSE

                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Combo Pay Docs Not having Special Handling Codes Populated');

                    END IF;

                END IF;

                 IF (lr_ar_main.direct_flag = 'N')  AND (lr_ar_main.billdocs_Paydoc_ind = 'Y') THEN
                    XX_AR_BILL_INDIRECT_PROC(lr_ar_main.Customer_id
                                             ,lr_ar_main.Customer_Number
                                             ,lr_ar_main.Customer_Name
                                             ,lr_ar_main.Legacy_Number
                                             ,lr_ar_main.Delivery_Method
                                             ,lr_ar_main.Paydoc_Indicator
                                             ,lr_ar_main.billdocs_cust_id
                                             ,lr_ar_main.Customer_Site
                                             ,p_request_id);  --Added for the defect#13420
                 END IF;

       lc_cust_prev := lr_ar_main.Customer_id;
   END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.LOG,'Outside cursor loop' );
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Inserting into XX_AR_BILL_EXCEPT_BILL table(FORALL) COUNT '||cust_bill_exp.COUNT );
        FORALL ctr IN cust_bill_exp.FIRST..cust_bill_exp.LAST
        INSERT INTO XX_AR_BILL_EXCEPT_BILL
        VALUES cust_bill_exp(ctr);
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Table Insertion Completed');
  EXCEPTION
   WHEN  others THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM || 'Exception in main procedure');
  END XX_AR_BILL_MAIN_PROC;

--Incorrect Info Doc frequency Error

PROCEDURE XX_AR_INFODOC_FREQ_PROC(p_customerid       NUMBER
                                 ,p_cust_number      VARCHAR2
                                 ,p_cust_name        VARCHAR2
                                 ,p_legacy_number    VARCHAR2
                                 ,p_delivery_method  VARCHAR2
                                 ,p_paydoc_ind       VARCHAR2
                                 ,p_cust_doc_id      NUMBER
                                 ,p_send_to_addr     VARCHAR2
                                 ,p_request_id       NUMBER
                                 )       --Added for the defect#13420
AS

-- Variable Declaration
lc_code NUMBER;

--Commented the below Cursor for the defect#13420
/*
-- Cursor Declaration

CURSOR lcu_ar_freq
IS
SELECT   XCAEB.billdocs_payment_term Payment_term_paydoc
   ,XCAEB1.billdocs_payment_term Payment_term_infodoc
   ,XCAEB.cust_account_id
   ,DECODE(RT.attribute1,'MNTH','40','SEMI','30','WEEK','20','WDAY', '15','DAILY','10') RT_paydoc
   ,DECODE(RT1.attribute1,'MNTH','40','SEMI','30','WEEK','20','WDAY', '15','DAILY','10') RT_infodoc
   ,XCAEB1.billdocs_cust_doc_id Info_cust_doc_id
   ,XCAEB1.billdocs_delivery_meth Info_delivery_meth
   ,RT.attribute2 Reportday_paydoc
   ,RT1.attribute2 Reportday_infodoc
FROM     xx_cdh_a_ext_billdocs_v XCAEB
   ,xx_cdh_a_ext_billdocs_v XCAEB1
   ,ra_terms RT
   ,ra_terms RT1
WHERE    1=1
AND XCAEB.cust_account_id = p_customerid
AND XCAEB1.cust_account_id = p_customerid
AND XCAEB.billdocs_doc_type = 'Consolidated Bill'
AND XCAEB1.billdocs_doc_type = 'Consolidated Bill'
AND XCAEB.billdocs_payment_term = RT.name
AND XCAEB1.billdocs_payment_term = RT1.name
AND XCAEB.billdocs_paydoc_ind = 'Y'
AND XCAEB1.billdocs_paydoc_ind = 'N';
*/

--Added the below cursor for the defect#13420
CURSOR lcu_ar_freq
IS
SELECT XCAEB.c_ext_attr14     PAYMENT_TERM_PAYDOC
      ,XCAEB1.c_ext_attr14    PAYMENT_TERM_INFODOC
      ,XCAEB.cust_account_id
      ,DECODE(RT.attribute1
             ,'MNTH'
             ,'40'
             ,'SEMI'
             ,'30'
             ,'WEEK'
             ,'20'
             ,'WDAY'
             ,'15'
             ,'DAILY'
             ,'10'
             )                RT_PAYDOC
      ,DECODE(RT1.attribute1
             ,'MNTH'
             ,'40'
             ,'SEMI'
             ,'30'
             ,'WEEK'
             ,'20'
             ,'WDAY'
             ,'15'
             ,'DAILY'
             ,'10'
             )                RT_INFODOC
      ,XCAEB1.n_ext_attr2     INFO_CUST_DOC_ID
      ,XCAEB1.c_ext_attr3     INFO_DELIVERY_METH
      ,RT.attribute2          REPORTDAY_PAYDOC
      ,RT1.attribute2         REPORTDAY_INFODOC
FROM   xx_cdh_cust_acct_ext_b XCAEB
      ,xx_cdh_cust_acct_ext_b XCAEB1
      ,ra_terms               RT
      ,ra_terms               RT1
WHERE  1=1
AND    XCAEB.cust_account_id  = p_customerid
AND    XCAEB1.cust_account_id = p_customerid
AND    XCAEB.c_ext_attr1      = 'Consolidated Bill'
AND    XCAEB1.c_ext_attr1     = 'Consolidated Bill'
AND    XCAEB.c_ext_attr14     = RT.name
AND    XCAEB1.c_ext_attr14    = RT1.name
AND    XCAEB.c_ext_attr2      = 'Y'
AND    XCAEB1.c_ext_attr2     = 'N'
AND    XCAEB.attr_group_id    = 166
AND    XCAEB1.attr_group_id   = 166
-- Added the below conditions for R1.3 CR 738 Defect 2766
AND    gd_effec_date >= XCAEB.d_ext_attr1
AND    (XCAEB.d_ext_attr2 IS NULL 
        OR
        gd_effec_date <= XCAEB.d_ext_attr2)
AND    gd_effec_date >= XCAEB1.d_ext_attr1
AND    (XCAEB1.d_ext_attr2 IS NULL 
        OR
        gd_effec_date <= XCAEB1.d_ext_attr2)
-- End of changes for R1.3 CR 738 Defect 2766
AND   XCAEB.c_ext_attr16  = 'COMPLETE'   -- Added for CR 586 - Defect 2811
AND   XCAEB1.c_ext_attr16  = 'COMPLETE';-- Added for CR 586 - Defect 2811


BEGIN
  FOR lr_ar_freq IN lcu_ar_freq
   LOOP
      IF lr_ar_freq.RT_paydoc > lr_ar_freq.RT_infodoc THEN
         lc_code := '130';
         XX_AR_BILL_INSERT_PROC(p_customerid
                               ,p_cust_number
                               ,p_cust_name
                               ,p_legacy_number
                               ,lr_ar_freq.Info_delivery_meth
                               ,'N'
                               ,lr_ar_freq.Info_cust_doc_id
                               ,NULL
                               ,lc_code
                               ,p_request_id);              --Added for the defect#13420
      END IF;

      IF ((lr_ar_freq.RT_paydoc = lr_ar_freq.RT_infodoc )
          AND (lr_ar_freq.Reportday_paydoc <> lr_ar_freq.Reportday_infodoc)) THEN
         lc_code := '130';
         XX_AR_BILL_INSERT_PROC(p_customerid
                               ,p_cust_number
                               ,p_cust_name
                               ,p_legacy_number
                               ,lr_ar_freq.Info_delivery_meth
                               ,p_paydoc_ind
                               ,lr_ar_freq.Info_cust_doc_id
                               ,NULL
                               ,lc_code
                               ,p_request_id);              --Added for the defect#13420

      END IF;

   END LOOP;
EXCEPTION
   WHEN  OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM || 'Exception in info doc procedure');
END XX_AR_INFODOC_FREQ_PROC;

--Missing Bill to site for Indirect Paydoc Procedure

PROCEDURE XX_AR_BILL_INDIRECT_PROC(p_customerid           NUMBER
                                   ,p_cust_number         VARCHAR2
                                   ,p_cust_name           VARCHAR2
                                   ,p_legacy_number       VARCHAR2
                                   ,p_delivery_method     VARCHAR2
                                   ,p_paydoc_ind          VARCHAR2
                                   ,p_cust_doc_id         NUMBER
                                   ,p_send_to_addr        VARCHAR2
                                   ,p_request_id          NUMBER)   --Added for the defect#13420
AS

--Variable Declaration
lc_code NUMBER;
lc_billto_count NUMBER;

CURSOR lcu_ar_indirect IS
 SELECT hcas.orig_system_reference LOCATION
        , count(*)
 FROM hz_cust_site_uses HCSU
       ,hz_cust_acct_sites HCAS
 WHERE 1= 1
 AND HCAS.cust_account_id = p_customerid
 AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
 AND HCSU.site_use_code = 'SHIP_TO'
 AND HCSU.bill_to_site_use_id is null
 AND  HCSU.status = 'A'
 AND   HCAS.status = 'A'
 GROUP BY hcas.orig_system_reference
 HAVING COUNT(*) > 0;

BEGIN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'Indirect Paydoc');
--dbms_output.put_line('Indirect proc call');
  
  
      lc_code := '110';
      FOR lr_ar_indirect IN lcu_ar_indirect
      LOOP
      XX_AR_BILL_INSERT_PROC(p_customerid
                             ,p_cust_number
                             ,p_cust_name
                             ,p_legacy_number
                             ,p_delivery_method
                             ,p_paydoc_ind
                             ,p_cust_doc_id
                             ,lr_ar_indirect.LOCATION
                             ,lc_code
                             ,p_request_id);  
                             --Added for the defect#13420
END LOOP;
    
  EXCEPTION
   WHEN  OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM || 'Exception in Bill to site check');
  END XX_AR_BILL_INDIRECT_PROC;


-- Site Procedure
PROCEDURE XX_AR_BILL_SITE_PROC(p_customerid         NUMBER
                               ,p_cust_number       VARCHAR2
                               ,p_cust_name         VARCHAR2
                               ,p_legacy_number     VARCHAR2
                               ,p_delivery_method   VARCHAR2
                               ,p_paydoc_ind        VARCHAR2
                               ,p_cust_doc_id       NUMBER
                               ,p_send_to_addr      VARCHAR2
                               ,p_request_id        NUMBER)  --Added for the defect#13420


AS
-- Variable Declaration
lc_custdoc_count NUMBER;
lc_address_count  NUMBER;
lc_code VARCHAR2(30);

--Commented the CURSOR for the defect#13420
/*
--Cursor Declaration
CURSOR lcu_ar_site
IS
SELECT
   XCAEB.billdocs_cust_doc_id Billdocs_Cust_doc_id
   ,XCAEB.cust_account_id Cust_Account_id
   ,XCAEB.billdocs_paydoc_ind  Paydoc_ind
   , XCAEB.billdocs_delivery_meth delivery_mehtod
   ,XCASEB.billdocs_cust_doc_id Site_Billdocs_Cust_doc_id
   ,XCASEB.billdocs_send_to_addr Send_to_addr
   ,HL.orig_system_reference OSR
FROM   xx_cdh_a_ext_billdocs_v XCAEB
   ,xx_cdh_as_ext_billdocs_v XCASEB
   ,hz_locations HL
   ,hz_cust_acct_sites HCAS
WHERE 1=1
AND HCAS.cust_account_id = p_customerid
AND XCASEB.cust_acct_Site_id = HCAS.cust_acct_site_id
AND XCASEB.billdocs_cust_doc_id = XCAEB.Billdocs_Cust_doc_id(+)
AND XCASEB.billdocs_send_to_addr = HL.orig_system_reference(+);
*/

--Added the CURSOR for the Defect#13420
CURSOR lcu_ar_site_address
IS
SELECT XCASEB.billdocs_cust_doc_id  BILLDOCS_CUST_DOC_ID
      ,HCAs.cust_account_id        CUST_ACCOUNT_ID
      ,hcas.cust_acct_site_id
      ,NULL           PAYDOC_IND
      ,NULL           DELIVERY_METHOD
      ,XCASEB.billdocs_cust_doc_id  SITE_BILLDOCS_CUST_DOC_ID
      ,XCASEB.billdocs_send_to_addr SEND_TO_ADDR
      ,HCAS1.orig_system_reference     OSR
      ,HCAS.orig_system_reference     site_location
FROM   xx_cdh_as_ext_billdocs_v  XCASEB
      ,hz_cust_acct_sites        HCAS
      ,hz_cust_acct_sites        HCAS1
WHERE 1=1
AND HCAS.cust_account_id         = p_customerid         
AND XCASEB.cust_acct_Site_id     = HCAS.cust_acct_site_id    
AND HCAS.status                  = 'A'
AND XCASEB.billdocs_send_to_addr = HCAS1.orig_system_reference(+)
AND HCAS1.orig_system_reference    IS NULL
AND XCASEB.billdocs_active_flag  = 'Y';                        -- Added for R1.3 CR 738 Defect 2766

CURSOR lcu_ar_site_id 
IS 
SELECT HCAS.cust_account_id        CUST_ACCOUNT_ID
      ,NULL                         PAYDOC_IND
      ,NULL                         DELIVERY_METHOD
      ,XCASEB.billdocs_cust_doc_id  SITE_BILLDOCS_CUST_DOC_ID
      ,XCASEB.billdocs_send_to_addr SEND_TO_ADDR
      ,HL.orig_system_reference     site_location 
FROM  xx_cdh_as_ext_billdocs_v  XCASEB
      ,hz_cust_acct_sites        HCAS
       ,hz_party_sites          HPS
      ,hz_locations             HL
WHERE 1=1
AND HCAS.cust_account_id         = p_customerid
AND XCASEB.cust_acct_Site_id     = HCAS.cust_acct_site_id
AND  hcas.party_site_Id =  hps.party_site_id
AND HCAS.status                  = 'A'
and hl.location_id = hps.location_id
AND  billdocs_cust_doc_id NOT IN ( SELECT n_ext_attr2
                                   FROM xx_cdh_cust_acct_ext_b
                                   WHERE cust_account_id      = p_customerid
                                   AND attr_group_id (+)      = 166
                                   -- Start of changes for Defect 6733 to comment the Start and End date condition on 26-OCT-10
                                   -- Added the below conditions for R1.3 CR 738 Defect 2766
                                 /*AND    gd_effec_date >= d_ext_attr1
                                   AND    (d_ext_attr2 IS NULL 
                                           OR
                                           gd_effec_date <= d_ext_attr2)*/
                                   -- End of changes for R1.3 CR 738 Defect 2766
                                   -- End of changes for Defect 6733 to comment the Start and End date condition on 26-OCT-10
     --Start of changes for Defect 6733 on 13-Oct-10
/*AND XCASEB.billdocs_active_flag  = 'Y'            -- Added for R1.3 CR 738 Defect 2766
);*/
)
AND XCASEB.billdocs_active_flag  = 'Y';
     --End of changes for Defect 6733 on 13-Oct-10

BEGIN
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Site' );

 FOR lr_ar_site_id in lcu_ar_site_id
   LOOP
      FND_FILE.PUT_LINE(FND_FILE.LOG,'id:' || lr_ar_site_id.Site_Billdocs_Cust_doc_id);
-- Invalid Cust Doc Id
    
         lc_code := '140';
         XX_AR_BILL_INSERT_PROC(p_customerid
                               ,p_cust_number
                               ,p_cust_name
                               ,p_legacy_number
                               ,lr_ar_site_id.delivery_method
                               ,lr_ar_site_id.paydoc_ind
                               ,lr_ar_site_id.Site_Billdocs_Cust_doc_id
                               ,lr_ar_site_id.site_location
                               ,lc_code
                               ,p_request_id);              --Added for the defect#13420

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Cust Doc Id Mismatch :' || lc_custdoc_count );
     END LOOP; 


--Invalid Send to Address
          
FOR lr_ar_site_address in lcu_ar_site_address
   LOOP

         lc_code := '150';
         XX_AR_BILL_INSERT_PROC(p_customerid
                               ,p_cust_number
                               ,p_cust_name
                               ,p_legacy_number
                               ,lr_ar_site_address.delivery_method
                               ,lr_ar_site_address.paydoc_ind
                               ,lr_ar_site_address.Site_Billdocs_Cust_doc_id
                               ,lr_ar_site_address.site_location
                               ,lc_code
                               ,p_request_id);              --Added for the defect#13420

    

  END LOOP;

EXCEPTION
   WHEN  OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM || 'Exception in Site Procedure');

END XX_AR_BILL_SITE_PROC;

--COMBO PROCEDURE
PROCEDURE XX_AR_BILL_COMBO_PROC(p_customerid      NUMBER
                               ,p_cust_number     VARCHAR2
                               ,p_cust_name       VARCHAR2
                               ,p_legacy_number   VARCHAR2
                               ,p_delivery_method VARCHAR2
                               ,p_paydoc_ind      VARCHAR2
                               ,p_cust_doc_id     NUMBER
                               ,p_send_to_addr    VARCHAR2
                               ,p_request_id      NUMBER)   --Added for the defect#13420


AS

--Variable Declaration
lc_combo_count NUMBER;
lc_code VARCHAR2(30);
lc_combo_docs_count NUMBER;
lc_combo_payment_count NUMBER;

-- Cursor Declaration
CURSOR lcu_ar_combo
IS
SELECT
   COUNT(XCAEB.cust_account_id) Count_Cust_Acct_id
-- ,XCAEB.billdocs_combo_type Billdocs_combo_type   --Commented for the defect#13420
        ,XCAEB.c_ext_attr13        BILLDOCS_COMBO_TYPE   --Added for the defect#13420
FROM
-- XX_CDH_A_EXT_BILLDOCS_V XCAEB    --Commented for the Defect#13420
        xx_cdh_cust_acct_ext_b  XCAEB    --Added for the defect#13420
WHERE 1=1
AND XCAEB.cust_account_id = p_customerid
--AND XCAEB.billdocs_paydoc_ind = 'Y'    --Added for the defect#13420
AND XCAEB.c_ext_attr2         = 'Y'
AND XCAEB.attr_group_id       = 166      --Added for the defect#13420
--GROUP BY XCAEB.billdocs_combo_type     --Commented for the Defect#13420
-- Added the below conditions for R1.3 CR 738 Defect 2766
AND    gd_effec_date >= XCAEB.d_ext_attr1
AND    (XCAEB.d_ext_attr2 IS NULL 
        OR
        gd_effec_date <= XCAEB.d_ext_attr2)
-- End of changes for R1.3 CR 738 Defect 2766
AND   XCAEB.c_ext_attr16  = 'COMPLETE' -- Added for defect 2811
GROUP BY XCAEB.c_ext_attr13;



BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,'Combo');


--   SELECT COUNT(distinct billdocs_payment_term)  --Commented for the defect#13420
   SELECT COUNT(DISTINCT XCAEB.c_ext_attr14)       --Added for the defect#13420
   INTO lc_combo_payment_count
   --FROM  XX_CDH_A_EXT_BILLDOCS_V XCAEB  --Commented for the defect#13420
   FROM xx_cdh_cust_acct_ext_b XCAEB      --Added for the defect#13420
   WHERE 1=1
   AND XCAEB.cust_account_id = p_customerid
--   AND XCAEB.billdocs_paydoc_ind = 'Y'  --Commented for the defect#13420
   AND XCAEB.c_ext_attr2         = 'Y'    --Added for the defect#13420
   AND XCAEB.attr_group_id       = 166
   AND  XCAEB.c_ext_attr13 IS NOT NULL   --Added for the defect#13420
-- Added the below conditions for R1.3 CR 738 Defect 2766
   AND    gd_effec_date >= XCAEB.d_ext_attr1
   AND    (XCAEB.d_ext_attr2 IS NULL 
           OR
           gd_effec_date <= XCAEB.d_ext_attr2)
-- End of changes for R1.3 CR 738 Defect 2766
   AND XCAEB.c_ext_attr16  = 'COMPLETE';   -- Added for CR 586 - Defect 2811
  -- Payment Mismatch for Combo doc
      IF lc_combo_payment_count > 1 THEN
         lc_code := '90';


--Added the INSERT for the defect#13420
                            INSERT INTO XX_AR_BILL_EXCEPT_BILL
                            SELECT XCAEB.c_ext_attr3
                                  ,p_cust_number
                                  ,p_cust_name
                                  ,p_legacy_number
                                  ,XCAEB.c_ext_attr2
                                  ,XCAEB.n_ext_attr2
                                  ,NULL
                                  ,lc_code
                                  ,gn_org_id
                                  ,p_request_id
                            FROM   xx_cdh_cust_acct_ext_b  XCAEB
                            WHERE  XCAEB.c_ext_attr2     = 'Y'
                            AND    XCAEB.attr_group_id   = 166
                            AND    XCAEB.cust_account_id = p_customerid
                            -- Added the below conditions for R1.3 CR 738 Defect 2766
                            AND    gd_effec_date >= XCAEB.d_ext_attr1
                            AND    (XCAEB.d_ext_attr2 IS NULL 
                                    OR
                                    gd_effec_date <= XCAEB.d_ext_attr2)
                            -- End of changes for R1.3 CR 738 Defect 2766
                            AND XCAEB.c_ext_attr16  = 'COMPLETE';   -- Added for CR 586 - Defect 2811

         FND_FILE.PUT_LINE(FND_FILE.LOG,'payment mismatch for  Combo:' || lc_combo_payment_count);
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'no payment mismatch for Combo:' || lc_combo_payment_count);

       END IF;


    lc_combo_docs_count := 0;


   FOR lr_ar_combo in lcu_ar_combo
   LOOP
      IF lr_ar_combo.BILLDOCS_COMBO_TYPE  IS NOT NULL THEN
        lc_combo_docs_count := lc_combo_docs_count +1;
      END IF;

   -- Multiple Non-Combo Pay Docs Error

      IF ((lr_ar_combo.Billdocs_combo_type IS NULL) AND (lr_ar_combo.Count_Cust_Acct_id > 1)) THEN
         lc_code := '60';
--Commented for the defect#13420
/*
             INSERT INTO   xx_ar_bill_exceptions_temp
             SELECT XCAEB.billdocs_delivery_meth
               ,hca.account_number
               ,hp.party_name
               ,hca.orig_system_reference
               ,billdocs_paydoc_ind
               ,XCAEB.billdocs_cust_doc_id
               ,NULL
                                   ,lc_code
                            FROM HZ_CUST_ACCOUNTS HCA
            , HZ_PARTIES  HP
            , XX_CDH_A_EXT_BILLDOCS_V XCAEB
             WHERE HCA.cust_account_id = XCAEB.cust_account_id
             AND   HP.party_id = HCA.party_id
                            AND   HCA.cust_Account_id = p_customerid
             AND   XCAEB.billdocs_paydoc_ind = 'Y'
                            AND   XCAEB.billdocs_combo_type IS NULL;
*/

--Added the Insert for the defect#13420
                            INSERT INTO XX_AR_BILL_EXCEPT_BILL
                            SELECT XCAEB.c_ext_attr3
                                  ,p_cust_number
                                  ,p_cust_name
                                  ,p_legacy_number
                                  ,XCAEB.c_ext_attr2
                                  ,XCAEB.n_ext_attr2
                                  ,NULL
                                  ,lc_code
                                  ,gn_org_id
                                  ,p_request_id
                            FROM  xx_cdh_cust_acct_ext_b  XCAEB
                            WHERE XCAEB.c_ext_attr2     = 'Y'
                            AND   XCAEB.attr_group_id   = 166
                            AND   XCAEB.c_ext_attr13      IS NULL
                            AND   XCAEB.cust_account_id = p_customerid
                            -- Added the below conditions for R1.3 CR 738 Defect 2766
                            AND    gd_effec_date >= XCAEB.d_ext_attr1
                            AND    (XCAEB.d_ext_attr2 IS NULL 
                                    OR
                                    gd_effec_date <= XCAEB.d_ext_attr2)
                            -- End of changes for R1.3 CR 738 Defect 2766
                            AND XCAEB.c_ext_attr16  = 'COMPLETE';   -- Added for CR 586 - Defect 2811

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Multiple non combo paydocs error:' || lc_combo_payment_count);

      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'no Multiple non combo paydocs error:' || lc_combo_payment_count);


      END IF;

 
      -- Duplicate Combo Check


      IF ((lr_ar_combo.Billdocs_combo_type IS NOT  NULL) AND (lr_ar_combo.Count_Cust_Acct_id > 1)) THEN

         lc_code := '100';

--Commented the INSERT for the defect#13420
/*
         INSERT INTO xx_ar_bill_exceptions_temp
             SELECT XCAEB.billdocs_delivery_meth
               ,hca.account_number
               ,hp.party_name
               ,hca.orig_system_reference
               ,billdocs_paydoc_ind
               ,XCAEB.billdocs_cust_doc_id
               ,NULL
                                   ,lc_code
             FROM HZ_CUST_ACCOUNTS HCA
            , HZ_PARTIES  HP
            , XX_CDH_A_EXT_BILLDOCS_V XCAEB
             WHERE HCA.cust_account_id = XCAEB.cust_account_id
             AND   HP.party_id = HCA.party_id
                            AND   HCA.cust_Account_id = p_customerid
             AND   billdocs_paydoc_ind = 'Y'
               AND   billdocs_combo_type = lr_ar_combo.Billdocs_combo_type;
*/

--Added INSERT for the defect#13420
                            INSERT INTO XX_AR_BILL_EXCEPT_BILL
                            SELECT XCAEB.c_ext_attr3
                                   ,p_cust_number
                                   ,p_cust_name
                                   ,p_legacy_number
                                   ,XCAEB.c_ext_attr2
                                   ,XCAEB.n_ext_attr2
                                   ,NULL
                                   ,lc_code
                                   ,gn_org_id
                                   ,p_request_id
                            FROM  xx_cdh_cust_acct_ext_b   XCAEB
                            WHERE XCAEB.c_ext_attr2     = 'Y'
                            AND   XCAEB.attr_group_id   = 166
                            AND   XCAEB.c_ext_attr13    = lr_ar_combo.Billdocs_combo_type
                            AND   XCAEB.cust_account_id = p_customerid
                            -- Added the below conditions for R1.3 CR 738 Defect 2766
                            AND    gd_effec_date >= XCAEB.d_ext_attr1
                            AND    (XCAEB.d_ext_attr2 IS NULL 
                                    OR
                                    gd_effec_date <= XCAEB.d_ext_attr2)
                            -- End of changes for R1.3 CR 738 Defect 2766
                            AND XCAEB.c_ext_attr16  = 'COMPLETE';   -- Added for CR 586 - Defect 2811

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Duplicate Combo:' || lc_combo_docs_count);
     --dbms_output.put_line('Duplicate combo');
      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,' no Duplicate Combo:' || lc_combo_docs_count);
    --dbms_output.put_line(' no duplicate combo');

      END IF;

   END LOOP;

-- Invalid Number of Combo Docs

--    IF ((lc_combo_docs_count <> 3) and (lc_combo_docs_count <> 1)) THEN  --Commented for the defect#13420

--Added the IF for the defect#13420
                IF (lc_combo_docs_count <> 2 AND lc_combo_docs_count <> 0 ) THEN

         lc_code := '80';

--Commented the INSERT for the defect#13420
/*
         INSERT INTO xx_ar_bill_exceptions_temp
         SELECT XCAEB.billdocs_delivery_meth
               ,hca.account_number
               ,hp.party_name
               ,hca.orig_system_reference
               ,billdocs_paydoc_ind
               ,XCAEB.billdocs_cust_doc_id
               ,NULL
                                   ,lc_code
             FROM HZ_CUST_ACCOUNTS HCA
            , HZ_PARTIES  HP
            , XX_CDH_A_EXT_BILLDOCS_V XCAEB
             WHERE HCA.cust_account_id = XCAEB.cust_account_id
             AND   HP.party_id = HCA.party_id
                            AND   HCA.cust_Account_id = p_customerid
             AND   billdocs_paydoc_ind = 'Y';
*/

--Added the INSERT for the defect#13420
                        INSERT INTO XX_AR_BILL_EXCEPT_BILL
                        SELECT XCAEB.c_ext_attr3
                              ,p_cust_number
                              ,p_cust_name
                              ,p_legacy_number
                              ,XCAEB.c_ext_attr2
                              ,XCAEB.n_ext_attr2
                              ,NULL
                              ,lc_code
                              ,gn_org_id
                              ,p_request_id
                        FROM   xx_cdh_cust_acct_ext_b   XCAEB
                        WHERE  XCAEB.attr_group_id   = 166
                        AND    XCAEB.c_ext_attr2     = 'Y'
                        AND    XCAEB.cust_account_id = p_customerid
                        -- Added the below conditions for R1.3 CR 738 Defect 2766
                        AND    gd_effec_date >= XCAEB.d_ext_attr1
                        AND    (XCAEB.d_ext_attr2 IS NULL 
                                OR
                                gd_effec_date <= XCAEB.d_ext_attr2)
                        -- End of changes for R1.3 CR 738 Defect 2766
                        AND XCAEB.c_ext_attr16  = 'COMPLETE';   -- Added for CR 586 - Defect 2811

         FND_FILE.PUT_LINE(FND_FILE.LOG,'Invalid Number of Combo:');

      ELSE
         FND_FILE.PUT_LINE(FND_FILE.LOG,'No Invalid Number of Combo:');

      END IF;


END XX_AR_BILL_COMBO_PROC;

-- INSERT PROCEDURE
PROCEDURE XX_AR_BILL_INSERT_PROC(p_customerid       NUMBER
                                ,p_cust_number      VARCHAR2
                                ,p_cust_name        VARCHAR2
                                ,p_legacy_number    VARCHAR2
                                ,p_delivery_method  VARCHAR2
                                ,p_paydoc_ind       VARCHAR2
                                ,p_cust_doc_id      NUMBER
                                ,p_send_to_addr     VARCHAR2
                                ,p_code             VARCHAR2
                                ,p_request_id       NUMBER)  --Added for the defect#13420
AS
ln_cnt   NUMBER := 0;
BEGIN


    --INSERT INTO xx_ar_bill_exceptions_temp(DELIVERY_METHOD         --Commented for the defect#13420
    /*INSERT INTO       XX_AR_BILL_EXCEPT_BILL (DELIVERY_METHOD           --Added for the defect#13420
                  ,CUSTOMER_NUMBER
                  ,CUSTOMER_NAME
                  ,LEGACY_CUSTOMER_NUMBER
                  ,PAYDOC_INDICATOR
                  ,CUST_DOCID
                  ,Customer_Site
                  ,CODE
                                                ,ORG_ID                    --Added for the defect#13420
                                                ,REQUEST_ID)               --Added for the defect#13420
    VALUES
   (p_delivery_method
    ,p_cust_number
   ,p_cust_name
   ,p_legacy_number
   ,p_paydoc_ind
   ,p_cust_doc_id
   ,p_send_to_addr
   ,p_code
        ,gn_org_id
        ,p_request_id);              --Added for the defect#13420*/   
   ln_cnt := cust_bill_exp.COUNT;
   cust_bill_exp(ln_cnt+1) := NULL;
   cust_bill_exp(ln_cnt+1).DELIVERY_METHOD        :=  p_delivery_method;
   cust_bill_exp(ln_cnt+1).CUSTOMER_NUMBER        :=  p_cust_number;   
   cust_bill_exp(ln_cnt+1).CUSTOMER_NAME          :=  p_cust_name;      
   cust_bill_exp(ln_cnt+1).LEGACY_CUSTOMER_NUMBER :=  p_legacy_number;  
   cust_bill_exp(ln_cnt+1).PAYDOC_INDICATOR       :=  p_paydoc_ind;     
   cust_bill_exp(ln_cnt+1).CUST_DOCID             :=  p_cust_doc_id;    
   cust_bill_exp(ln_cnt+1).CUSTOMER_SITE          :=  p_send_to_addr;   
   cust_bill_exp(ln_cnt+1).CODE                   :=  p_code;          
   cust_bill_exp(ln_cnt+1).ORG_ID                 :=  gn_org_id;   
   cust_bill_exp(ln_cnt+1).REQUEST_ID             :=  p_request_id;
EXCEPTION
   WHEN  OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM || 'Exception in insert procedure');
END XX_AR_BILL_INSERT_PROC;



-- +=====================================================================+
-- | Name :  XX_AR_BILL_EXC_EXCEL_PROC                                   |
-- | Description : The procedure will submit the OD: AR Billing          |
-- |               Exceptions report in the specified format             |
-- | Parameters :  None                                                  |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

  --Commented for the defect#13420
/*
PROCEDURE XX_AR_BILL_EXC_EXCEL_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER
              )
*/
PROCEDURE XX_AR_BILL_EXC_EXCEL_PROC(
                                    p_mast_req_id IN  NUMBER
                                   ,x_request_id  OUT NUMBER    --Added for the defect#13420
                                   ,p_format      IN  VARCHAR2  --Added for the defect#13420
                                   )
AS

  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lb_print_option      BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);

BEGIN


  lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                   printer           => 'XPTR'
                                                   ,copies           => 1
                                                  );

  lb_layout := fnd_request.add_layout(
                                      'XXFIN'
                                     ,'XXARBILEXC'
                                     ,'en'
                                     ,'US'
                                     ,p_format
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXARBILEXC'
                                             ,NULL
                                             ,NULL
--                                             ,FALSE       --Commented for the defect#13420
                                             ,TRUE          --Added for the defect#13420
                                             ,p_mast_req_id --Added for the defect#13420
                    );

x_request_id := ln_request_id;                     --Added for the defect#13420

  COMMIT;


---------------------------------------
--Comment for the defect#13420 begins
---------------------------------------
/*
  lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                      request_id  => ln_request_id
                                                     ,interval    => '2'
                                                     ,max_wait    => ''
                                                     ,phase       => lc_phase
                                                     ,status      => lc_status
                                                     ,dev_phase   => lc_devphase
                                                     ,dev_status  => lc_devstatus
                                                     ,message     => lc_message
                                                     );

  IF ln_request_id <> 0 THEN

    FND_FILE.PUT_LINE(FND_FILE.LOG,'The report has been submitted and the request id is: '||ln_request_id);

            IF lc_devstatus ='E' THEN

      x_err_buff := 'PROGRAM COMPLETED IN ERROR';
      x_ret_code := 2;

            ELSIF lc_devstatus ='G' THEN

      x_err_buff := 'PROGRAM COMPLETED IN WARNING';
      x_ret_code := 1;

            ELSE

                x_err_buff := 'PROGRAM COMPLETED NORMAL';
                x_ret_code := 0;

            END IF;

  ELSE
    FND_FILE.PUT_LINE(FND_FILE.LOG,'The report did not get submitted');

  END IF;
*/

---------------------------------------
--Comment for the defect#13420 Ends
---------------------------------------

END XX_AR_BILL_EXC_EXCEL_PROC;

-- +=====================================================================+
-- | Name        : XX_AR_BILL_EX_MASTER_PROC                             |
-- | Description : The procedure will call the child program             |
-- |               OD: AR Billing Exceptions Child using batching and    |
-- |               multi-threading                                       |
-- | Parameters  :p_batch_size,p_format_type                             |
-- | Returns     :x_err_buff,x_ret_code                                  |
-- +=====================================================================+

PROCEDURE XX_AR_BILL_EX_MASTER_PROC(
                                    x_err_buff           OUT VARCHAR2
                                   ,x_ret_code           OUT NUMBER
                                   ,p_batch_size         IN  NUMBER
                                   ,p_format_type        IN  VARCHAR2
                                   ,p_last_upd_date_from IN  VARCHAR2  --Changed the data type to varchar for 13420
                                   ,p_last_upd_date_to   IN  VARCHAR2  --Changed the data type to varchar for 13420
                                   )

AS

CURSOR lcu_cust_id(p_term_id   NUMBER
                  ,p_date_from DATE
                  ,p_date_to   DATE)
IS
SELECT HCA.cust_account_id CUST_ID
      ,HCA.party_id
      ,HCA.attribute18
      ,HCA.account_number
      ,HCA.orig_system_reference
FROM   --hz_parties              HP --Commented for the defect#13420
       hz_cust_accounts        HCA
      ,hz_customer_profiles    HCP
      ,xx_cdh_cust_acct_ext_b  XCCAB
WHERE  1=1
--AND    HCA.party_id             = HP.party_id        --Commented for the defect#13420
AND    HCA.cust_account_id      = HCP.cust_account_id
AND    XCCAB.cust_account_id (+)= HCA.cust_account_id
AND    HCP.standard_terms       <> p_term_id
AND    HCP.site_use_id            IS NULL
AND    UPPER(HCA.attribute18)     IN ('CONTRACT','DIRECT')
AND    HCA.status               = 'A'
AND    XCCAB.attr_group_id (+)  = 166
--AND    trunc(HCA.last_update_date)       BETWEEN trunc(p_date_from) AND trunc(p_date_to)     -- Commented for the defect #445
AND    HCA.last_update_date BETWEEN trunc(p_date_from) AND trunc(p_date_to)+0.99999     -- Added for the defect #445
-- Added the below conditions for R1.3 CR 738 Defect 2766
AND    gd_effec_date >= XCCAB.d_ext_attr1(+)
AND    gd_effec_date <= NVL(XCCAB.d_ext_attr2(+),gd_effec_date)
-- End of changes for R1.3 CR 738 Defect 2766
AND   XCCAB.c_ext_attr16 (+) = 'COMPLETE' -- Added for defect 2811 --added outer join for defect# 17888
UNION                                                              --Added the two unions for the defect#13420
SELECT HCA.cust_account_id CUST_ID
      ,HCA.party_id
      ,HCA.attribute18
      ,HCA.account_number
      ,HCA.orig_system_reference
FROM   hz_cust_accounts        HCA
      ,hz_customer_profiles    HCP
      ,xx_cdh_cust_acct_ext_b  XCCAB
WHERE  1=1
AND    HCA.cust_account_id      = HCP.cust_account_id
AND    XCCAB.cust_account_id (+)= HCA.cust_account_id
AND    HCP.standard_terms       <> p_term_id
AND    HCP.site_use_id            IS NULL
AND    UPPER(HCA.attribute18)     IN ('CONTRACT','DIRECT')
AND    HCA.status               = 'A'
AND    XCCAB.attr_group_id (+)  = 166
--AND    trunc(XCCAB.last_update_date)     BETWEEN trunc(p_date_from) AND trunc(p_date_to)     -- Commented for the defect #445
AND    XCCAB.last_update_date   BETWEEN trunc(p_date_from) AND trunc(p_date_to)+0.99999     -- Added for the defect #445
-- Added the below conditions for R1.3 CR 738 Defect 2766
AND    gd_effec_date >= XCCAB.d_ext_attr1(+)
AND    gd_effec_date <= NVL(XCCAB.d_ext_attr2(+),gd_effec_date)
-- End of changes for R1.3 CR 738 Defect 2766
AND   XCCAB.c_ext_attr16  = 'COMPLETE' -- Added for defect 2811
UNION
SELECT HCA.cust_account_id CUST_ID
      ,HCA.party_id
      ,HCA.attribute18
      ,HCA.account_number
      ,HCA.orig_system_reference
FROM   hz_cust_accounts        HCA
      ,hz_customer_profiles    HCP
      ,xx_cdh_cust_acct_ext_b  XCCAB
WHERE  1=1
AND    HCA.cust_account_id      = HCP.cust_account_id
AND    XCCAB.cust_account_id (+)= HCA.cust_account_id
AND    HCP.standard_terms       <> p_term_id
AND    HCP.site_use_id            IS NULL
AND    UPPER(HCA.attribute18)     IN ('CONTRACT','DIRECT')
AND    HCA.status               = 'A'
AND    XCCAB.attr_group_id (+)  = 166
--AND    trunc(HCP.last_update_date)      BETWEEN trunc(p_date_from) AND trunc(p_date_to)     -- Commented for the defect #445
AND    HCP.last_update_date   BETWEEN trunc(p_date_from) AND trunc(p_date_to)+0.99999     -- Added for the defect #445
-- Added the below conditions for R1.3 CR 738 Defect 2766
AND    gd_effec_date >= XCCAB.d_ext_attr1(+)
AND    gd_effec_date <= NVL(XCCAB.d_ext_attr2(+),gd_effec_date)
-- End of changes for R1.3 CR 738 Defect 2766
AND   XCCAB.c_ext_attr16 (+) = 'COMPLETE' -- Added for defect 2811 --added outer join for defect# 17888
ORDER BY CUST_ID;

TYPE t_cust_main  IS TABLE OF hz_cust_accounts.cust_account_id%TYPE INDEX BY BINARY_INTEGER;
TYPE t_party_main IS TABLE OF hz_cust_accounts.party_id%TYPE INDEX BY BINARY_INTEGER;
TYPE t_cust_attr  IS TABLE OF hz_cust_accounts.attribute18%TYPE INDEX BY BINARY_INTEGER;
TYPE t_cust_num   IS TABLE OF hz_cust_accounts.account_number%TYPE INDEX BY BINARY_INTEGER;
TYPE t_or_ref     IS TABLE OF hz_cust_accounts.orig_system_reference%TYPE INDEX BY BINARY_INTEGER;

t_cust_id   t_cust_main;
t_party_id  t_party_main;
t_attribute t_cust_attr;
t_number    t_cust_num;
t_orig_ref  t_or_ref;

--Local Variable declaration

ln_count        NUMBER := 0;
ln_upper        NUMBER;
ln_lower        NUMBER;
ln_cust_id_from NUMBER;
ln_cust_id_to   NUMBER;
ln_request_id   NUMBER;
ln_start_flag   NUMBER;
ln_term_id      NUMBER;
ln_mast_req_id  NUMBER;
ln_rep_req_id   NUMBER;
ln_err_cnt      NUMBER;
ln_wrn_cnt      NUMBER;
ln_nrm_cnt      NUMBER;

lc_phase        VARCHAR2(80);
lc_status       VARCHAR2(80);
lc_devphase     VARCHAR2(30);
lc_devstatus    VARCHAR2(30);
lc_message      VARCHAR2(240);
lc_format_type  VARCHAR2(20);

lb_layout       BOOLEAN;
lb_print_option BOOLEAN;
lb_status       BOOLEAN;

ld_date_from    DATE;
ld_date_to      DATE;


BEGIN


ln_mast_req_id := FND_GLOBAL.CONC_REQUEST_ID;
ld_date_from   := fnd_date.canonical_to_date(p_last_upd_date_from);  --Added for the defect#13420
ld_date_to     := fnd_date.canonical_to_date(p_last_upd_date_to);    --Added for the defect#13420

  BEGIN

   SELECT term_id
   INTO   ln_term_id
   FROM   ra_terms
   WHERE  UPPER(name) ='IMMEDIATE';

  EXCEPTION

   WHEN NO_DATA_FOUND THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Term IMMEDIATE does not exists');

    x_err_buff := 'Master Program ended in Error';
    x_ret_code := 2;

    RETURN;

   WHEN OTHERS THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Term IMMEDIATE does not exists');

    x_err_buff := 'Master Program ended in Error';
    x_ret_code := 2;

    RETURN;
  END;

 IF (FND_CONC_GLOBAL.REQUEST_DATA = 1) THEN

     IF (p_format_type IS NOT NULL) THEN

         lc_format_type := UPPER(LTRIM(RTRIM(p_format_type)));

         XX_AR_BILL_EXC_EXCEL_PROC(
                                   p_mast_req_id => ln_mast_req_id
                                  ,x_request_id  => ln_request_id
                                  ,p_format      => lc_format_type
                                  );

     ELSIF p_format_type IS NULL THEN

         lc_format_type := 'EXCEL';

         XX_AR_BILL_EXC_EXCEL_PROC(
                                   p_mast_req_id => ln_mast_req_id
                                  ,x_request_id  => ln_request_id
                                  ,p_format      => lc_format_type
                                  );

     END IF;

     ln_start_flag := ln_request_id ||'2';

     FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  =>'PAUSED'
                                    ,request_data => ln_start_flag
                                    );
     COMMIT;

     x_err_buff := 'RESTARTING BILLING EXCEPTIONS REPORT MASTER PROGRAM - Submitting the Report';
     x_ret_code :=0;
     RETURN;

 ELSIF (TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.REQUEST_DATA,-1),'9') = 2) THEN

        ln_rep_req_id := TO_NUMBER(SUBSTR(FND_CONC_GLOBAL.request_data,1,LENGTH(FND_CONC_GLOBAL.request_data)-1));

        BEGIN

        DELETE FROM XX_AR_BILL_EXCEPT_BILL
        WHERE request_id = ln_mast_req_id;

        DELETE FROM xx_ar_bill_cust_acct
        WHERE mast_request_id = ln_mast_req_id;

        COMMIT;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'No Records were found in the Temporary table for Deletion');

          WHEN OTHERS THEN

           FND_FILE.PUT_LINE(FND_FILE.LOG,'No Records were found in the Temporary tablefor Deletion');

        END;


        BEGIN

          SELECT SUM(CASE WHEN status_code = 'E'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'G'
                          THEN 1 ELSE 0 END)
                ,SUM(CASE WHEN status_code = 'C'
                          THEN 1 ELSE 0 END)
          INTO   ln_err_cnt
                ,ln_wrn_cnt
                ,ln_nrm_cnt
          FROM   fnd_concurrent_requests
          WHERE  priority_request_id = ln_mast_req_id;


          IF ln_err_cnt > 0 THEN

             x_err_buff := 'COMPLETION OF BILLING EXCEPTIONS REPORT MASTER PROGRAM';
             x_ret_code := 2;
             RETURN;

          ELSIF ln_wrn_cnt > 0 AND ln_err_cnt = 0 THEN

             x_err_buff := 'COMPLETION OF BILLING EXCEPTIONS REPORT MASTER PROGRAM';
             x_ret_code := 1;
             RETURN;

          ELSIF ln_err_cnt = 0 AND ln_wrn_cnt = 0 AND ln_nrm_cnt > 0 THEN

             x_err_buff := 'COMPLETION OF BILLING EXCEPTIONS REPORT MASTER PROGRAM';
             x_ret_code := 0;
             RETURN;

          END IF;

        EXCEPTION

          WHEN NO_DATA_FOUND THEN

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Child Programs where found');

             x_err_buff := 'COMPLETION OF BILLING EXCEPTIONS REPORT MASTER PROGRAM';
             x_ret_code := 0;
             RETURN;

          WHEN OTHERS THEN

           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Child Programs where found');

             x_err_buff := 'COMPLETION OF BILLING EXCEPTIONS REPORT MASTER PROGRAM';
             x_ret_code := 0;
             RETURN;

        END;

 ELSE

        OPEN lcu_cust_id(ln_term_id
                        ,ld_date_from
                        ,ld_date_to);

        LOOP

          FETCH lcu_cust_id BULK COLLECT INTO t_cust_id
                                             ,t_party_id
                                             ,t_attribute
                                             ,t_number
                                             ,t_orig_ref  LIMIT p_batch_size;

          IF (NVL(t_cust_id.FIRST,0) = 0 AND ln_count = 0) THEN

            EXIT;

          ELSIF (NVL(t_cust_id.FIRST,0) = 0 AND ln_count > 0) THEN

            EXIT;

          ELSE

            ln_lower := t_cust_id.FIRST;
            ln_upper := t_cust_id.LAST;

            FND_FILE.PUT_LINE(FND_FILE.LOG,'Upper Limit :='||ln_lower);
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Upper Limit :='||ln_upper);

--            ln_cust_id_from := t_cust_id(ln_lower);  --Commented for the defect#13420
--            ln_cust_id_to   := t_cust_id(ln_upper);  --Commented for the defect#13420

            ln_count := ln_count + 1;

            ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                        application =>'XXFIN'
                                                       ,program     =>'XXARBILLC'
                                                       ,description =>NULL
                                                       ,start_time  =>NULL
                                                       ,sub_request =>TRUE
--                                                       ,argument1   =>ln_cust_id_from    --Commented for the defect#13420
--                                                       ,argument2   =>ln_cust_id_to      --Commented for the defect#13420
                                                       ,argument1   =>ln_mast_req_id
--                                                       ,argument2   =>p_last_upd_date_from  --Commented for the defect#13420
--                                                       ,argument3   =>p_last_upd_date_to    --Commented for the defect#13420
                                                       );

--Added the BULK BOUND INSERT for the defect#13420
            FORALL ln_index IN ln_lower..ln_upper
            INSERT INTO xx_ar_bill_cust_acct
            VALUES(ln_request_id
                  ,t_cust_id(ln_index)
                  ,t_party_id(ln_index)
                  ,t_attribute(ln_index)
                  ,t_number(ln_index)
                  ,t_orig_ref(ln_index)
                  ,ln_mast_req_id
                  );

            COMMIT;

          END IF;

        END LOOP;

        CLOSE lcu_cust_id;

        IF ln_count > 0 THEN

          ln_start_flag := 1;
          FND_CONC_GLOBAL.SET_REQ_GLOBALS(conc_status  =>'PAUSED'
                                         ,request_data => ln_start_flag
                                         );
          COMMIT;

          FND_FILE.PUT_LINE(FND_FILE.LOG,'RESTARTING BILLING EXCEPTION REPORT MASTER PROGRAM');
          x_err_buff := 'Restarted Billing Exception Report Master Program';
          x_ret_code    := 0;

          RETURN;

        ELSE

          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No Customers were found for whom the Billing information was incorrectly setup');
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'So the Report has not been Submitted');

          FND_FILE.PUT_LINE(FND_FILE.LOG,'COMPLETION OF BILLING EXCEPTION REPORT MASTER PROGRAM');
          x_err_buff := 'Completion of Billing Exception Report Master Program';
          x_ret_code    := 0;

          RETURN;

        END IF;

 END IF;

END XX_AR_BILL_EX_MASTER_PROC;

END XX_AR_BILL_EXCEPTIONS_PKG;

/

SHOW ERRORS;