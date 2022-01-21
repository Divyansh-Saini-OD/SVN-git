CREATE OR REPLACE PACKAGE BODY APPS.XX_AR_DEFAULT_COLLECTOR_PKG
AS

-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       WIPRO Technologies                            |
-- +=====================================================================+
-- | Name : XX_AR_DEFAULT_COLLECTOR_PKG                                  |
-- | RICE ID :  R0528                                                    |
-- | Description :This package is the executable of the wrapper program  |
-- |              that used for submitting the OD: AR Default Collector  |
-- |              report with the desirable format of the user, and the  |
-- |              default format is EXCEL and also does the necessary    |
-- |              validations and processing needed for the report R0528 |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  02-JAN-09      Jennifer Jegam         Initial version      |
-- | 1.1      10-FEB-09      Kantharaja          Fixed for defect 11568  |
-- | 1.2      06-SEP-13      Anantha Reddy      Replaced equivalent table|	
-- |					 columns names as per R12 upgrade|                  		
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_AR_DEFAULT_COLLECTOR_PROC                                |
-- | Description : The procedure will submit the OD: AR Default          |
-- |               Collector report in the specified format              |
-- | Parameters :  p_collectorid, p_termid                               |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_DEFAULT_COLLECTOR_PROC(
                                   x_err_buff      OUT VARCHAR2
                                  ,x_ret_code      OUT NUMBER
				          ,p_collectorid   IN  NUMBER
				          ,p_termid        IN  NUMBER
                                      )
AS

  -- Local Variable declaration
   ln_request_id        NUMBER(15);
   lb_layout            BOOLEAN;
   lb_req_status        BOOLEAN;
   lc_status_code       VARCHAR2(10);
   lc_phase             VARCHAR2(50);
   lc_status            VARCHAR2(50);
   lc_devphase          VARCHAR2(50);
   lc_devstatus         VARCHAR2(50);
   lc_message           VARCHAR2(50);
   lb_print_option      BOOLEAN;

BEGIN

  lb_print_option := FND_REQUEST.SET_PRINT_OPTIONS(
                                                       printer           => 'XPTR'
                                                      ,copies            => 1
                                                     );



  lb_layout := fnd_request.add_layout(
                                             'XXFIN'
                                            ,'XXARDEFCOL'
                                            ,'en'
                                            ,'US'
                                            ,'EXCEL'
                                     );

  ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                              'XXFIN'
                                             ,'XXARDEFCOL'
                                             ,NULL
                                             ,NULL
                                             ,FALSE
					               ,p_collectorid
				                     ,p_termid
                                              );

COMMIT;

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

IF ln_request_id <> 0   THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report has been submitted and the request id is: '||ln_request_id);

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

ELSE FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The report did not get submitted');

END IF;

END XX_AR_DEFAULT_COLLECTOR_PROC;


-- +=====================================================================+
-- | Name :  XX_AR_DEF_COL_INSERT_PROCEDURE                              |
-- | Description : The procedure will do the necessary processing and    |
-- |               validations needed for the report R0528               |
-- |                                                                     |
-- | Parameters :  p_collectorid, p_termid                               |
-- | Returns :  x_err_buff,x_ret_code                                    |
-- +=====================================================================+

PROCEDURE XX_AR_DEF_COL_INSERT_PROCEDURE (
                                          p_collectorid     IN NUMBER
				                  ,p_termid          IN NUMBER
				                 )
AS

-- Local Variable Declaration
lc_currency                 VARCHAR2(20);
lc_profile_class_id         NUMBER;
lc_cust_account_profile_id  NUMBER;
lc_profile_class            VARCHAR2(100);
lc_credit_limit             NUMBER;
lc_bill_to_site_id          NUMBER;
lc_sales_date               DATE;
lc_acct_amt                 NUMBER;
LC_TOTAL_DUE                NUMBER;
lc_flag                     VARCHAR2(10) :='Y';

-- Cursor Declaration

CURSOR lcu_ar_def IS
SELECT  HCAS.cust_Acct_site_id
       ,hcsu.site_use_id Site_use_id
       ,HCP_SITE.cust_Account_profile_id profile_value
       ,HCP_SITE.collector_id
       ,HCA.account_number Customer_Number
       ,HP.party_name Customer_Name
       ,HCA.orig_system_reference Legacy_Customer_Number
       ,HCSU.location Customer_Bill_To
       ,HL.state Billing_State
       ,AL.meaning Customer_Category
       ,HCA.sales_channel_code Sales_Channel
       ,NVL(HCA1.Account_Number,' ') Sugg_Reln
FROM
       hz_cust_accounts                 HCA
     , hz_cust_Acct_sites               HCAS
     , hz_cust_site_uses                HCSU
     , hz_customer_profiles             HCP_SITE
     , hz_parties                       HP
     , hz_cust_accounts                 HCA1
     , hz_locations                     HL
     , ar_lookups                       AL
     , hz_party_sites                   HPS
     , hz_hierarchy_nodes               HZN
WHERE  1=1
--AND HCA.cust_Account_id = HCP_DEF.cust_account_id
--AND HCP_DEF.site_use_id IS NULL
AND HCAS.cust_account_id = HCA.cust_Account_id
AND HCAS.cust_acct_site_id = HCSU.cust_Acct_site_id
AND HCP_SITE.site_use_id= HCSU.site_use_id
AND (HCP_SITE.standard_terms <> p_termid
     OR HCP_SITE.standard_terms IS NULL)
AND HCA.party_id=HP.party_id
AND HCSU.site_use_code = 'BILL_TO'
AND AL.lookup_code(+)=HP.category_code
AND LOOKUP_TYPE(+) = 'CUSTOMER_CATEGORY'
AND HPS.party_site_id=HCAS.party_site_id
AND HPS.location_id=HL.location_id
AND (HZN.hierarchy_type ='OD_CUST_HIER'
     OR HZN.hierarchy_type IS NULL)
AND HZN.parent_object_type(+) ='ORGANIZATION'
AND HZN.child_table_name(+)='HZ_PARTIES'
AND HZN.child_object_type(+) ='ORGANIZATION'
AND HZN.parent_table_name(+)='HZ_PARTIES'
AND HP.party_id =HZN.child_id (+)
AND HCA1.party_id(+)=HZN.parent_id
AND NVL(HZN.level_number,1)=1
AND (HZN.parent_id is not null and HZN.status = 'A' OR HZN.parent_id is NULL)
AND HCP_SITE.collector_id = p_collectorid;

BEGIN

--SELECT currency_code INTO lc_currency FROM gl_sets_of_books WHERE set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID');
SELECT currency_code INTO lc_currency FROM gl_ledgers WHERE ledger_id = fnd_profile.value('GL_SET_OF_BKS_ID');--1.2-Replaced equivalent table columns as per R12 upgrade

FOR lr_ar_def IN lcu_ar_def
LOOP
BEGIN
   lc_flag := 'Y';

SELECT
    RCT.bill_to_site_use_id
   ,MIN(RCT.trx_date) Sales_Date
   ,SUM(APS.acctd_amount_due_remaining) Total_Due
INTO
   lc_bill_to_site_id
   ,lc_sales_date
   ,lc_total_due
   FROM
   ra_customer_trx RCT
   ,ar_payment_schedules APS
WHERE
   1=1
   AND APS.customer_trx_id = RCT.customer_trx_id
   AND RCT.bill_to_site_use_id = lr_ar_def.Site_use_id
   GROUP BY RCT.bill_to_site_use_id;

IF    lc_total_due = 0 then
      lc_flag := 'N';
END IF;

EXCEPTION
WHEN NO_DATA_FOUND THEN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data fetched for Transaction Query'|| ' ' || SQLERRM);
   lc_flag :='N';
   lc_bill_to_site_id :=NULL;
   lc_sales_date := NULL;
   lc_total_due := NULL;
WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Others Exception raised in Transaction query'|| ' ' || SQLERRM);
   lc_flag :='N';
   lc_bill_to_site_id :=NULL;
   lc_sales_date := NULL;
   lc_total_due := NULL;
END;

IF (lc_flag = 'Y') THEN

BEGIN
SELECT
       HCPC.profile_class_id
      ,HCPA.cust_account_profile_id
      ,HCPC.NAME Profile_Class
      ,HCPA.overall_credit_limit Credit_Limit
INTO
       lc_profile_class_id
      ,lc_cust_account_profile_id
      ,lc_profile_class
      ,lc_credit_limit
FROM
      hz_cust_profile_classes  HCPC
      ,hz_cust_profile_amts    HCPA
      ,hz_customer_profiles    HCP
      WHERE 1=1
      AND HCP.profile_class_id=HCPC.profile_class_id(+)
      AND HCP.cust_account_profile_id=HCPA.cust_account_profile_id(+)
      AND hcpa.currency_code(+)  = lc_currency
      AND hcp.cust_Account_profile_id= lr_ar_def.profile_value;

EXCEPTION
WHEN NO_DATA_FOUND THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data fetched for the Customer profile query'|| ' ' || SQLERRM);
      lc_profile_class_id := NULL;
      lc_cust_account_profile_id := NULL;
      lc_profile_class := NULL;
      lc_credit_limit :=NULL;

WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Others exception raised for Customer profile query'|| ' ' || SQLERRM);
      lc_profile_class_id := NULL;
      lc_cust_account_profile_id := NULL;
      lc_profile_class := NULL;
      lc_credit_limit :=NULL;
      END;
BEGIN
    INSERT INTO xx_ar_default_collector_temp
    VALUES (lr_ar_def.Customer_Number
          ,lr_ar_def.Customer_Name
          ,lc_profile_class
          ,lr_ar_def.Legacy_Customer_Number
          ,lr_ar_def.Customer_Bill_To
          ,lc_credit_limit
          ,lc_sales_date
          ,lc_total_due
          ,lr_ar_def.Billing_State
          ,lr_ar_def.Customer_Category
          ,lr_ar_def.Sales_Channel
          ,lr_ar_def.Sugg_Reln);

EXCEPTION
          WHEN NO_DATA_FOUND THEN
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'No data fetched for the Insert into Temporary table'|| ' ' || SQLERRM);
          WHEN OTHERS THEN
           FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Others exception raised for insert into Temporary table'|| ' ' || SQLERRM);
          END;
END IF;
END LOOP;
END XX_AR_DEF_COL_INSERT_PROCEDURE;
END XX_AR_DEFAULT_COLLECTOR_PKG;
/
