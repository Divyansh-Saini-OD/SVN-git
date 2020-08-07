SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_EXTRACT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY  XX_AP_C2FO_EXTRACT_PKG AS
/****************************************************************************************************************
*   Name:        XXC2FO_EXTRACT_PKG
*   PURPOSE:     This package was created for the C2O Extract Process
*   @author      Joshua Wilson - C2FO
*   @version     12.1.3.1.0
*   @comments    
*
*   REVISIONS:
*   Ver          Date         Author                    Company           Description
*   ---------    ----------   ---------------           ----------        ---------------------------------------------------
*   12.1.3.1.0   5/01/15      Joshua Wilson             C2FO              1. Created this package.
*   12.1.3.1.0   8/29/2018    Nageswara Rao Chennupati  C2FO              2. Modified the package as per the new requirements.
*   1.0          9/2/2018     Antonio Morales           OD                OD Initial Customized Version     
*                                                                         Use a temp table to improve performance
*                                                                         of reports
*****************************************************************************************************************************/

  /***************************************************************/
 /* PROCEDURE GENERATE_EXTRACT                                   */
 /* Procedure to extract all files                               */
 /****************************************************************/
    PROCEDURE GENERATE_EXTRACT(
                          errbuf                OUT  VARCHAR2, 
                          retcode               OUT  NUMBER,
                          p_procdate             IN  VARCHAR2,
                          p_file_prefix          IN  VARCHAR2,
                          p_operating_unit       IN  NUMBER,
                          p_supp_num_from        IN  VARCHAR2,
                          p_supp_num_to          IN  VARCHAR2,
                          p_invoice_num_from     IN  VARCHAR2,
                          p_invoice_num_to       IN  VARCHAR2,
                          p_invoice_date_from    IN  VARCHAR2,
                          p_invoice_date_to      IN  VARCHAR2,
                          p_pay_due_date_from    IN  VARCHAR2,
                          p_pay_due_date_to      IN  VARCHAR2,
                          p_po_data_extract      IN  VARCHAR2,
                          p_po_date_from         IN  VARCHAR2,
                          p_po_date_to           IN  VARCHAR2  )  IS

        v_filename                         VARCHAR2(50);
        v_output                           utl_file.file_type;    

        lc_date_format            CONSTANT VARCHAR2(20) := 'RRRR/MM/DD';
        ld_procdate                        DATE := to_date(p_procdate,'yyyy-mm-dd hh24:mi:ss');
        v_inv_count                        NUMBER := 0;
        v_org_count                        NUMBER := 0;
        v_user_count                       NUMBER := 0;
        v_count                            NUMBER := 0;
        v_po_count                         NUMBER := 0;
        l_validated_po_date_from           VARCHAR2(11) := TO_CHAR(add_months(SYSDATE,-120),lc_date_format);
        l_validated_po_date_to             VARCHAR2(11) := TO_CHAR(SYSDATE,lc_date_format);


        CURSOR C_INV_DATA IS
        SELECT *
          FROM XX_AP_C2FO_INVOICE_V
         WHERE EBS_ORG_ID = p_operating_unit;
--            AND EBS_SUPPLIER_NUMBER BETWEEN NVL(p_supp_num_from, EBS_SUPPLIER_NUMBER)   AND NVL(p_supp_num_to, EBS_SUPPLIER_NUMBER)
--            AND EBS_INVOICE_NUM     BETWEEN NVL(p_invoice_num_from, EBS_INVOICE_NUM)    AND NVL(p_invoice_num_to, EBS_INVOICE_NUM)
--            AND TO_DATE(TRANSACTION_DATE, 'YYYY-MM-DD')    BETWEEN NVL(to_date(p_invoice_date_from, 'RRRR/MM/DD HH24:MI:SS'), TO_DATE(TRANSACTION_DATE,'YYYY-MM-DD'))  
--            AND NVL(to_date(p_invoice_date_to, 'RRRR/MM/DD HH24:MI:SS'), TO_DATE(TRANSACTION_DATE,'YYYY-MM-DD'))
--            AND TO_DATE(PAYMENT_DUE_DATE, 'YYYY-MM-DD')    BETWEEN NVL(to_date(p_pay_due_date_from, 'RRRR/MM/DD HH24:MI:SS'), TO_DATE(PAYMENT_DUE_DATE,'YYYY-MM-DD'))  
--            AND NVL(to_date(p_pay_due_date_to, 'RRRR/MM/DD HH24:MI:SS'), TO_DATE(PAYMENT_DUE_DATE,'YYYY-MM-DD'))
--            AND substr(invoice_id,instr(invoice_id,'|')+1) BETWEEN NVL(p_invoice_num_from, substr(invoice_id,instr(invoice_id,'|')+1)) AND NVL(p_invoice_num_to, substr(invoice_id,instr(invoice_id,'|')+1))


        TYPE CINV_DATA_REC IS TABLE OF C_INV_DATA%ROWTYPE;
        C_INV_DATA_REC CINV_DATA_REC;


        CURSOR C_INV_DATA_T IS
        SELECT *
          FROM xx_ap_c2fo_gt_invoice_view;

        TYPE CINV_DATA_REC_T IS TABLE OF C_INV_DATA_T%ROWTYPE;
        C_INV_DATA_REC_T CINV_DATA_REC_T;

        CURSOR C_ORG_DATA IS
        SELECT *
          FROM XX_AP_C2FO_ORGANIZATION_V
         WHERE company_id IN (SELECT company_id 
                                FROM xx_ap_c2fo_gt_invoice_view);

        CURSOR C_USER_DATA IS
        SELECT *
          FROM XX_AP_C2FO_USER_V
         WHERE company_id IN (SELECT company_id 
                                FROM xx_ap_c2fo_gt_invoice_view);

-----PO PART5-------------------------                           

        CURSOR C_PO_DATA IS
          SELECT *
          FROM XX_AP_C2FO_OP_PO_DETAILS_ND_V
          WHERE EBS_ORG_ID = NVL(p_operating_unit, EBS_ORG_ID)
            --AND TO_DATE(CREATE_DATE, 'YYYY-MM-DD') BETWEEN l_validated_po_date_from AND l_validated_po_date_to;
            AND TO_DATE(CREATE_DATE, 'YYYY-MM-DD')    BETWEEN NVL(to_date(p_po_date_from, 'RRRR/MM/DD HH24:MI:SS'), TO_DATE(l_validated_po_date_from,'YYYY-MM-DD'))  
                                                          AND NVL(to_date(p_po_date_to, 'RRRR/MM/DD HH24:MI:SS'), TO_DATE(l_validated_po_date_to,'YYYY-MM-DD'));
-----PO PART5-------------------------                  


    BEGIN
----------------------

        --Loop through data and write to file
        OPEN C_INV_DATA;

        LOOP

        FETCH C_INV_DATA
         BULK COLLECT
         INTO C_INV_DATA_REC LIMIT 10000;

        EXIT WHEN C_INV_DATA_REC.COUNT = 0;
        v_count := v_count + C_INV_DATA_REC.COUNT;

        FORALL ind IN C_INV_DATA_REC.FIRST .. C_INV_DATA_REC.LAST
            INSERT /*+ append */
             INTO xx_ap_c2fo_gt_invoice_view
                  (company_id,
                  division_id,
                  invoice_id,
                  amount,
                  currency,
                  payment_due_date,
                  transaction_type,
                  transaction_date,
                  voucher_id,
                  payment_term,
                  payment_method,
                  adj_invoice_id,
                  adjustment_reason_code,
                  description,
                  vat_amount,
                  amount_grossvat,
                  amount_netvat,
                  vat_to_be_discounted,
                  buyer_name,
                  buyer_address,
                  buyer_tax_id,
                  local_currency_key,
                  local_currency_rate,
                  local_currency_org_inv_amt,
                  local_currency_original_vat,
                  market_type,
                  po_id,
                  ebs_org_id,
                  ebs_vendor_id,
                  ebs_supplier_number,
                  ebs_vendor_site_id,
                  ebs_vendor_site_code,
                  ebs_invoice_id,
                  ebs_invoice_num,
                  ebs_pay_group,
                  ebs_pay_priority,
                  ebs_sup_pay_priority,
                  ebs_site_pay_priority,
                  ebs_voucher_num,
                  ebs_cash_discount_amount,
                  ebs_inv_amt_before_cash_disc
                  )
            VALUES
                 (c_inv_data_rec(ind).company_id,
                  c_inv_data_rec(ind).division_id,
                  c_inv_data_rec(ind).invoice_id,
                  c_inv_data_rec(ind).amount,
                  c_inv_data_rec(ind).currency,
                  c_inv_data_rec(ind).payment_due_date,
                  c_inv_data_rec(ind).transaction_type,
                  c_inv_data_rec(ind).transaction_date,
                  c_inv_data_rec(ind).voucher_id,
                  c_inv_data_rec(ind).payment_term,
                  c_inv_data_rec(ind).payment_method,
                  c_inv_data_rec(ind).adj_invoice_id,
                  c_inv_data_rec(ind).adjustment_reason_code,
                  c_inv_data_rec(ind).description,
                  c_inv_data_rec(ind).vat_amount,
                  c_inv_data_rec(ind).amount_grossvat,
                  c_inv_data_rec(ind).amount_netvat,
                  c_inv_data_rec(ind).vat_to_be_discounted,
                  c_inv_data_rec(ind).buyer_name,
                  c_inv_data_rec(ind).buyer_address,
                  c_inv_data_rec(ind).buyer_tax_id,
                  c_inv_data_rec(ind).local_currency_key,
                  c_inv_data_rec(ind).local_currency_rate,
                  c_inv_data_rec(ind).local_currency_org_inv_amt,
                  c_inv_data_rec(ind).local_currency_original_vat,
                  c_inv_data_rec(ind).market_type,
                  c_inv_data_rec(ind).po_id,
                  c_inv_data_rec(ind).ebs_org_id,
                  c_inv_data_rec(ind).ebs_vendor_id,
                  c_inv_data_rec(ind).ebs_supplier_number,
                  c_inv_data_rec(ind).ebs_vendor_site_id,
                  c_inv_data_rec(ind).ebs_vendor_site_code,
                  c_inv_data_rec(ind).ebs_invoice_id,
                  c_inv_data_rec(ind).ebs_invoice_num,
                  c_inv_data_rec(ind).ebs_pay_group,
                  c_inv_data_rec(ind).ebs_pay_priority,
                  c_inv_data_rec(ind).ebs_sup_pay_priority,
                  c_inv_data_rec(ind).ebs_site_pay_priority,
                  c_inv_data_rec(ind).ebs_voucher_num,
                  c_inv_data_rec(ind).ebs_cash_discount_amount,
                  c_inv_data_rec(ind).ebs_inv_amt_before_cash_disc
                 );

            COMMIT;

      END LOOP;

      COMMIT;

      close c_inv_data;

      FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Extract Process Started');
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

      FND_FILE.PUT_LINE(FND_FILE.LOG, '********** Input Parameters **********');
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_procdate:          '||p_procdate);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_file_prefix:       '||p_file_prefix);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_operating_unit:    '||p_operating_unit);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_supp_num_from:     '||p_supp_num_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_supp_num_to:       '||p_supp_num_to);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_invoice_num_from:  '||p_invoice_num_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_invoice_num_to:    '||p_invoice_num_to);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_invoice_date_from: '||p_invoice_date_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_invoice_date_to:   '||p_invoice_date_to);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_pay_due_date_from: '||p_pay_due_date_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_pay_due_date_to:   '||p_pay_due_date_to);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'p_po_data_extract:     '||p_po_data_extract);
      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');

      FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Output Directory:   '||C_DIRECTORY);


      --BEGIN INVOICE EXTRACT
      BEGIN
        v_filename := LOWER(p_file_prefix||'_invoice_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv');

        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creating File:   '||v_filename);

        v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"COMPANY_ID'||'",'||
              '"DIVISION_ID'||'",'||
              '"INVOICE_ID'||'",'||
              '"AMOUNT'||'",'||
              '"CURRENCY'||'",'||
              '"PAYMENT_DUE_DATE'||'",'||
              '"TRANSACTION_TYPE'||'",'||
              '"TRANSACTION_DATE'||'",'||
              '"VOUCHER_ID'||'",'||
              '"PAYMENT_TERM'||'",'||
              '"PAYMENT_METHOD'||'",'||
              '"ADJ_INVOICE_ID'||'",'||
              '"ADJUSTMENT_REASON_CODE'||'",'||
              '"DESCRIPTION'||'",'||
              '"VAT_AMOUNT'||'",'||
              '"AMOUNT_GROSSVAT'||'",'||
              '"AMOUNT_NETVAT'||'",'||
              '"VAT_TO_BE_DISCOUNTED'||'",'||
              '"BUYER_NAME'||'",'||
              '"BUYER_ADDRESS'||'",'||
              '"BUYER_TAX_ID'||'",'||
              '"LOCAL_CURRENCY_KEY'||'",'||
              '"LOCAL_CURRENCY_RATE'||'",'||
              '"LOCAL_CURRENCY_ORIGINAL_INVOICE_AMOUNT'||'",'||
              '"LOCAL_CURRENCY_ORIGINAL_VAT'||'",'||
              '"MARKET_TYPE'||'",'||
              '"PO_ID'||'",'||
              --'"TRANSACTION_STATUS'||'",'||
              '"EBS_ORG_ID'||'",'||
              --'"EBS_OU_NAME'||'",'||
              '"EBS_VENDOR_ID'||'",'||
              '"EBS_SUPPLIER_NUMBER'||'",'||
              '"EBS_VENDOR_SITE_ID'||'",'||
              '"EBS_VENDOR_SITE_CODE'||'",'||
              '"EBS_INVOICE_ID'||'",'||
              '"EBS_INVOICE_NUM'||'",'||
              '"EBS_PAY_GROUP'||'",'||
              '"EBS_PAY_PRIORITY'||'",'||
              '"EBS_SUP_PAY_PRIORITY'||'",'||
              '"EBS_SITE_PAY_PRIORITY'||'",'||
              '"EBS_VOUCHER_NUM'||'",'||
              '"EBS_CASH_DISCOUNT_AMOUNT'||'",'||
              '"EBS_INV_AMT_BEFORE_CASH_DISC'||'"'));


        --Loop through data and write to file
        OPEN C_INV_DATA_T;

        LOOP

        FETCH C_INV_DATA_T
         BULK COLLECT
         INTO C_INV_DATA_REC_T LIMIT 100000;

        EXIT WHEN C_INV_DATA_REC_T.COUNT = 0;

        FOR ind IN C_INV_DATA_REC_T.FIRST .. C_INV_DATA_REC_T.LAST
        LOOP 

            v_inv_count := v_inv_count + 1;

            UTL_FILE.PUT_LINE(v_output, 
              '"'||C_INV_DATA_REC_T(ind).COMPANY_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).DIVISION_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).INVOICE_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).AMOUNT||'",'||
              '"'||C_INV_DATA_REC_T(ind).CURRENCY||'",'||
              '"'||C_INV_DATA_REC_T(ind).PAYMENT_DUE_DATE||'",'||
              '"'||C_INV_DATA_REC_T(ind).TRANSACTION_TYPE||'",'||
              '"'||C_INV_DATA_REC_T(ind).TRANSACTION_DATE||'",'||
              '"'||C_INV_DATA_REC_T(ind).VOUCHER_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).PAYMENT_TERM||'",'||
              '"'||C_INV_DATA_REC_T(ind).PAYMENT_METHOD||'",'||
              '"'||C_INV_DATA_REC_T(ind).ADJ_INVOICE_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).ADJUSTMENT_REASON_CODE||'",'||
              '"'||C_INV_DATA_REC_T(ind).DESCRIPTION||'",'||              
              '"'||C_INV_DATA_REC_T(ind).VAT_AMOUNT||'",'||
              '"'||C_INV_DATA_REC_T(ind).AMOUNT_GROSSVAT||'",'||
              '"'||C_INV_DATA_REC_T(ind).AMOUNT_NETVAT||'",'||
              '"'||C_INV_DATA_REC_T(ind).VAT_TO_BE_DISCOUNTED||'",'||
              '"'||C_INV_DATA_REC_T(ind).BUYER_NAME||'",'||
              '"'||C_INV_DATA_REC_T(ind).BUYER_ADDRESS||'",'||
              '"'||C_INV_DATA_REC_T(ind).BUYER_TAX_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).LOCAL_CURRENCY_KEY||'",'||
              '"'||C_INV_DATA_REC_T(ind).LOCAL_CURRENCY_RATE||'",'||
              '"'||C_INV_DATA_REC_T(ind).LOCAL_CURRENCY_ORG_INV_AMT||'",'||
              '"'||C_INV_DATA_REC_T(ind).LOCAL_CURRENCY_ORIGINAL_VAT||'",'||
              '"'||C_INV_DATA_REC_T(ind).MARKET_TYPE||'",'||
              '"'||C_INV_DATA_REC_T(ind).PO_ID||'",'||
              --'"'|| C_INV_DATA_REC(ind).TRANSACTION_STATUS||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_ORG_ID||'",'||
              --'"'||C_INV_DATA_REC(ind).EBS_OU_NAME||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_VENDOR_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_SUPPLIER_NUMBER||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_VENDOR_SITE_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_VENDOR_SITE_CODE||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_INVOICE_ID||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_INVOICE_NUM||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_PAY_GROUP||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_PAY_PRIORITY||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_SUP_PAY_PRIORITY||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_SITE_PAY_PRIORITY||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_VOUCHER_NUM||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_CASH_DISCOUNT_AMOUNT||'",'||
              '"'||C_INV_DATA_REC_T(ind).EBS_INV_AMT_BEFORE_CASH_DISC||'"');

         END LOOP;

        END LOOP;
  
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Count:   '||v_inv_count);

        UTL_FILE.FCLOSE(v_output); 

        CLOSE C_INV_DATA_T;

       EXCEPTION
         WHEN utl_file.invalid_path THEN
            raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');
        END;

      --BEGIN ORGANIZATION EXTRACT
      BEGIN
        v_filename := LOWER(p_file_prefix||'_organization_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv');

        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creating File:   '||v_filename);

        v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"COMPANY_ID'||'",'||
              '"COMPANY_NAME'||'",'||
              '"ADDRESS_1'||'",'||
              '"ADDRESS_2'||'",'||
              '"CITY'||'",'||
              '"STATE'||'",'||
              '"POSTAL_CODE'||'",'||
              '"COUNTRY'||'",'||
              '"RESERVE_PERCENTAGE'||'",'||
              '"RESERVE_AMOUNT'||'",'||
              '"RESERVE_INVOICE_PRIORITY'||'",'||
              '"RESERVE_BEFORE_ADJUSTMENTS'||'",'||
              '"TAX_ID'||'"'));


        --Loop through data and write to file
        FOR C_ORG_DATA_REC IN C_ORG_DATA LOOP

            v_org_count := v_org_count + 1;

            UTL_FILE.PUT_LINE(v_output, 
              '"'||C_ORG_DATA_REC.COMPANY_ID||'",'||
              '"'||C_ORG_DATA_REC.COMPANY_NAME||'",'||
              '"'||C_ORG_DATA_REC.ADDRESS_1||'",'||
              '"'||C_ORG_DATA_REC.ADDRESS_2||'",'||
              '"'||C_ORG_DATA_REC.CITY||'",'||
              '"'||C_ORG_DATA_REC.STATE||'",'||
              '"'||C_ORG_DATA_REC.POSTAL_CODE||'",'||
              '"'||C_ORG_DATA_REC.COUNTRY||'",'||
              '"'||C_ORG_DATA_REC.RESERVE_PERCENTAGE||'",'||
              '"'||C_ORG_DATA_REC.RESERVE_AMOUNT||'",'||
              '"'|| C_ORG_DATA_REC.RESERVE_INVOICE_PRIORITY||'",'||
              '"'|| C_ORG_DATA_REC.RESERVE_BEFORE_ADJUSTMENTS||'",'||
              '"'||C_ORG_DATA_REC.TAX_ID||'"');

         END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Count:   '||v_org_count);

        UTL_FILE.FCLOSE(v_output); 

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');      
      END;

      --BEGIN USER EXTRACT
      BEGIN
        v_filename :=  LOWER(p_file_prefix||'_user_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv');

        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creating File:   '||v_filename);

        v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"COMPANY_ID'||'",'||
              '"DIVISION_ID'||'",'||
              '"EMAIL_ADDRESS'||'",'||
              '"FIRST_NAME'||'",'||
              '"LAST_NAME'||'",'||
              '"TITLE'||'",'||
              '"PHONE_NUMBER'||'",'||
              '"ADDRESS_1'||'",'||
              '"ADDRESS_2'||'",'||
              '"CITY'||'",'||
              '"STATE'||'",'||
              '"POSTAL_CODE'||'",'||
              '"COUNTRY'||'"'));

        --Loop through data and write to file
        FOR C_USER_DATA_REC IN C_USER_DATA LOOP

            v_user_count := v_user_count + 1;

            UTL_FILE.PUT_LINE(v_output, 
              '"'||C_USER_DATA_REC.COMPANY_ID||'",'||
              '"'||C_USER_DATA_REC.DIVISION_ID||'",'||
              '"'||C_USER_DATA_REC.EMAIL_ADDRESS||'",'||
              '"'||C_USER_DATA_REC.FIRST_NAME||'",'||
              '"'||C_USER_DATA_REC.LAST_NAME||'",'||
              '"'||C_USER_DATA_REC.TITLE||'",'||
              '"'||C_USER_DATA_REC.PHONE_NUMBER||'",'||
              '"'||C_USER_DATA_REC.ADDRESS_1||'",'||
              '"'||C_USER_DATA_REC.ADDRESS_2||'",'||
              '"'||C_USER_DATA_REC.CITY||'",'||
              '"'||C_USER_DATA_REC.STATE||'",'||
              '"'||C_USER_DATA_REC.POSTAL_CODE||'",'||
              '"'||C_USER_DATA_REC.COUNTRY||'"');
         END LOOP;

         FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Count:   '||v_user_count);

        UTL_FILE.FCLOSE(v_output); 

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');      
      END;

-----PO -------------------------      
-----PO -------------------------      

-----PO PART1-------------------------    

--BEGIN PO EXTRACT

      IF     p_po_data_extract = 'YES' THEN
      BEGIN

        v_filename := LOWER(p_file_prefix||'_po_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv');

        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creating File:   '||v_filename);

        v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"COMPANY_ID'||'",'||
              '"DIVISION_ID'||'",'||
              '"PO_ID'||'",'||
              '"AMOUNT'||'",'||
              '"CURRENCY'||'",'||
              '"CREATE_DATE'||'",'||
              '"APPROVED_DATE'||'",'||
              '"SHIP_DATE'||'",'||
              '"SHIP_ORIG_COUNTRY'||'",'||
              '"SHIP_ORIG_STATE'||'",'||
              '"ESTIMATED_ARRIVAL_DATE'||'",'||
              '"ACTUAL_ARRIVAL_DATE'||'",'||
              '"SUPPLIER_COUNTRY'||'",'||
              '"COMPANY_CODE'||'",'||
              '"WAREHOUSE_CODE'||'",'||
              '"EBS_ORG_ID'||'",'||
              '"EBS_PONUMBER'||'",'||
              '"EBS_PO_HEADER_ID'||'",'||
              '"EBS_SUPPLIER'||'",'||
              '"EBS_SUPPLIER_NUMBER'||'",'||
              '"EBS_VENDOR_ID'||'",'||
              '"EBS_SUPPLIERSITE'||'",'||
              '"EBS_VENDOR_SITE_ID'||'",'||
              '"EBS_POTYPE'||'",'||
              '"EBS_PODATE'||'",'||
              '"EBS_BILLTO_LOC'||'",'||
              '"EBS_BUYER'||'",'||
              '"EBS_AUTHORIZATION_STATUS'||'",'||
              '"EBS_TERMS'||'",'||
              '"EBS_CLOSED_CODE'||'",'||          
              '"EBS_SHIP_TO_LOCATION_ID'||'"'));

        --Loop through data and write to file
        FOR C_PO_DATA_REC IN C_PO_DATA LOOP

            v_po_count := v_po_count + 1;

            UTL_FILE.PUT_LINE(v_output, 
              '"'||C_PO_DATA_REC.COMPANY_ID||'",'||
              '"'||C_PO_DATA_REC.DIVISION_ID||'",'||
              '"'||C_PO_DATA_REC.PO_ID||'",'||
              '"'||C_PO_DATA_REC.AMOUNT||'",'||
              '"'||C_PO_DATA_REC.CURRENCY||'",'||
              '"'||C_PO_DATA_REC.CREATE_DATE||'",'||
              '"'||C_PO_DATA_REC.APPROVED_DATE||'",'||
              '"'||C_PO_DATA_REC.SHIP_DATE||'",'||
              '"'||C_PO_DATA_REC.SHIP_ORIG_COUNTRY||'",'||
              '"'||C_PO_DATA_REC.SHIP_ORIG_STATE||'",'||
              '"'||C_PO_DATA_REC.ESTIMATED_ARRIVAL_DATE||'",'||
              '"'||C_PO_DATA_REC.ACTUAL_ARRIVAL_DATE||'",'||
              '"'||C_PO_DATA_REC.SUPPLIER_COUNTRY||'",'||
              '"'||C_PO_DATA_REC.COMPANY_CODE||'",'||
              '"'||C_PO_DATA_REC.WAREHOUSE_CODE||'",'||
              '"'||C_PO_DATA_REC.EBS_ORG_ID||'",'||
              '"'||C_PO_DATA_REC.EBS_PONUMBER||'",'||
              '"'||C_PO_DATA_REC.EBS_PO_HEADER_ID||'",'||
              '"'||C_PO_DATA_REC.EBS_SUPPLIER||'",'||
              '"'||C_PO_DATA_REC.EBS_SUPPLIER_NUMBER||'",'||
              '"'||C_PO_DATA_REC.EBS_VENDOR_ID||'",'||
              '"'||C_PO_DATA_REC.EBS_SUPPLIERSITE||'",'||
              '"'||C_PO_DATA_REC.EBS_VENDOR_SITE_ID||'",'||
              '"'||C_PO_DATA_REC.EBS_POTYPE||'",'||    
              '"'||C_PO_DATA_REC.EBS_PODATE||'",'||
              '"'||C_PO_DATA_REC.EBS_BILLTO_LOC||'",'||
              '"'||C_PO_DATA_REC.EBS_BUYER||'",'||
              '"'||C_PO_DATA_REC.EBS_AUTHORIZATION_STATUS||'",'||    
              '"'||C_PO_DATA_REC.EBS_TERMS||'",'||
              '"'||C_PO_DATA_REC.EBS_CLOSED_CODE||'",'||
              '"'||C_PO_DATA_REC.EBS_SHIP_TO_LOCATION_ID||'"');

         END LOOP;


        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Count:   '||v_po_count);

        UTL_FILE.FCLOSE(v_output); 

       EXCEPTION
         WHEN utl_file.invalid_path THEN
            raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');
        END;
        END IF;

-----PO PART1-------------------------          

      --BEGIN CONTROL FILE
      BEGIN
        v_filename :=  LOWER(p_file_prefix||'_control_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv');

        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creating File:   '||v_filename);

        v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"FILE_NAME'||'",'||
              '"ROW_COUNT'||'"'));  

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"'||p_file_prefix||'_invoice_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv')||'",'||
              '"'||v_inv_count||'"');

            UTL_FILE.PUT_LINE(v_output, 
              LOWER('"'||p_file_prefix||'_organization_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv')||'",'||
              '"'||v_org_count||'"');

            UTL_FILE.PUT_LINE(v_output,  
              LOWER('"'||p_file_prefix||'_user_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv')||'",'||
              '"'||v_user_count||'"');

                -----PO PART2-------------------------    
            IF     p_po_data_extract = 'YES' THEN                
            UTL_FILE.PUT_LINE(v_output,  
              LOWER('"'||p_file_prefix||'_po_'||TO_CHAR(TRUNC(ld_procdate),'YYYYMMDD')||'.csv')||'",'||
              '"'||v_po_count||'"');
            END IF;              
                -----PO PART2-------------------------

            IF     p_po_data_extract = 'YES' THEN                

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Count:   4');
            ELSE
            FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Count:   3');
            END IF;

        UTL_FILE.FCLOSE(v_output); 

     FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
     FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Extract Process Completed');

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');      
      END;

    END GENERATE_EXTRACT;

 /***************************************************************/
 /* PROCEDURE INVOICE_EXTRACT                                   */
 /* Procedure to extract invoice data                           */
 /* OBSOLETE DO NOT USE (Kept for backwards compatibility)      */
 /***************************************************************/
    PROCEDURE INVOICE_EXTRACT(
                          errbuf            OUT   VARCHAR2, 
                          retcode           OUT   NUMBER
                                    )
     IS
        v_filename      VARCHAR2(50);
        v_output        utl_file.file_type;


        CURSOR C_VIEW_META IS
          SELECT COLUMN_NAME
          FROM ALL_TAB_COLUMNS
          WHERE TABLE_NAME = 'XXC2FO_INVOICE'
          ORDER BY COLUMN_ID;

        CURSOR C_VIEW_DATA IS
          SELECT *
          FROM XX_AP_C2FO_INVOICE_V;

     BEGIN

      v_filename := 'buyer_invoice_'||TO_CHAR(TRUNC(sysdate),'YYYYMMDD')||'.csv';

      v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

      --Loop through columns and write to file
--      FOR C_VIEW_META_REC IN C_VIEW_META LOOP
--      
--        UTL_FILE.PUTF(v_output, '"'||LOWER(C_VIEW_META_REC.COLUMN_NAME)||'",');
--      
--      END LOOP;


          UTL_FILE.PUT_LINE(v_output, 
            '"COMPANY_ID'||'",'||
            '"DIVISION_ID'||'",'||
            '"INVOICE_ID'||'",'||
            '"AMOUNT'||'",'||
            '"CURRENCY'||'",'||
            '"PAYMENT_DUE_DATE'||'",'||
            '"TRANSACTION_TYPE'||'",'||
            '"TRANSACTION_DATE'||'",'||
            '"VOUCHER_ID'||'",'||
            '"PAYMENT_TERM'||'",'||
            '"PAYMENT_METHOD'||'",'||
            '"ADJ_INVOICE_ID'||'",'||
            '"ADJUSTMENT_REASON_CODE'||'",'||
            '"DESCRIPTION'||'",'||
            '"VAT_AMOUNT'||'",'||
            '"AMOUNT_GROSSVAT'||'",'||
            '"AMOUNT_NETVAT'||'",'||
            '"VAT_TO_BE_DISCOUNTED'||'",'||
            '"BUYER_NAME'||'",'||
            '"BUYER_ADDRESS'||'",'||
            '"BUYER_TAX_ID'||'",'||
            '"LOCAL_CURRENCY_KEY'||'",'||
            '"LOCAL_CURRENCY_RATE'||'",'||
            '"LOCAL_CURRENCY_ORIGINAL_INVOICE_AMOUNT'||'",'||
            '"LOCAL_CURRENCY_ORIGINAL_VAT'||'",'||
            '"MARKET_TYPE'||'",'||
            '"PO_ID'||'",'||
            --'"TRANSACTION_STATUS'||'",'||
            '"EBS_ORG_ID'||'",'||
            --'"EBS_OU_NAME'||'",'||        
            '"EBS_VENDOR_ID'||'",'||
            '"EBS_SUPPLIER_NUMBER'||'",'||
            '"EBS_VENDOR_SITE_ID'||'",'||
            '"EBS_VENDOR_SITE_CODE'||'",'||
            '"EBS_INVOICE_ID'||'",'||
            '"EBS_INVOICE_NUM'||'",'||
            '"EBS_PAY_GROUP'||'",'||
            '"EBS_PAY_PRIORITY'||'",'||
            '"EBS_SUP_PAY_PRIORITY'||'",'||
            '"EBS_SITE_PAY_PRIORITY'||'",'||
            '"EBS_VOUCHER_NUM'||'",'||
            '"EBS_CASH_DISCOUNT_AMOUNT'||'",'||
            '"EBS_INV_AMT_BEFORE_CASH_DISC'||'"');
--      UTL_FILE.PUT_LINE(v_output,'');

      --Loop through data and write to file
      --TODO:  Make columns dynamic for data stream
      FOR C_VIEW_DATA_REC IN C_VIEW_DATA LOOP
          UTL_FILE.PUT_LINE(v_output, 
            '"'||C_VIEW_DATA_REC.COMPANY_ID||'",'||
            '"'||C_VIEW_DATA_REC.DIVISION_ID||'",'||
            '"'||C_VIEW_DATA_REC.INVOICE_ID||'",'||
            '"'||C_VIEW_DATA_REC.AMOUNT||'",'||
            '"'||C_VIEW_DATA_REC.CURRENCY||'",'||
            '"'||C_VIEW_DATA_REC.PAYMENT_DUE_DATE||'",'||
            '"'||C_VIEW_DATA_REC.TRANSACTION_TYPE||'",'||
            '"'||C_VIEW_DATA_REC.TRANSACTION_DATE||'",'||
            '"'||C_VIEW_DATA_REC.VOUCHER_ID||'",'||
            '"'||C_VIEW_DATA_REC.PAYMENT_TERM||'",'||
            '"'||C_VIEW_DATA_REC.PAYMENT_METHOD||'",'||            
            '"'||C_VIEW_DATA_REC.ADJ_INVOICE_ID||'",'||
            '"'||C_VIEW_DATA_REC.ADJUSTMENT_REASON_CODE||'",'||
            '"'||C_VIEW_DATA_REC.DESCRIPTION||'",'||
            '"'||C_VIEW_DATA_REC.VAT_AMOUNT||'",'||
            '"'||C_VIEW_DATA_REC.AMOUNT_GROSSVAT||'",'||
            '"'||C_VIEW_DATA_REC.AMOUNT_NETVAT||'",'||
            '"'||C_VIEW_DATA_REC.VAT_TO_BE_DISCOUNTED||'",'||
            '"'||C_VIEW_DATA_REC.BUYER_NAME||'",'||
            '"'||C_VIEW_DATA_REC.BUYER_ADDRESS||'",'||
            '"'||C_VIEW_DATA_REC.BUYER_TAX_ID||'",'||
            '"'||C_VIEW_DATA_REC.LOCAL_CURRENCY_KEY||'",'||
            '"'||C_VIEW_DATA_REC.LOCAL_CURRENCY_RATE||'",'||
            '"'||C_VIEW_DATA_REC.LOCAL_CURRENCY_ORG_INV_AMT||'",'||
            '"'||C_VIEW_DATA_REC.LOCAL_CURRENCY_ORIGINAL_VAT||'",'||
            '"'||C_VIEW_DATA_REC.MARKET_TYPE||'",'||
            '"'||C_VIEW_DATA_REC.PO_ID||'",'||
            --'"'||C_VIEW_DATA_REC.TRANSACTION_STATUS||'",'||
            '"'||C_VIEW_DATA_REC.EBS_ORG_ID||'",'||
            --'"'||C_VIEW_DATA_REC.EBS_OU_NAME||'",'||
            '"'||C_VIEW_DATA_REC.EBS_VENDOR_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_SUPPLIER_NUMBER||'",'||
            '"'||C_VIEW_DATA_REC.EBS_VENDOR_SITE_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_VENDOR_SITE_CODE||'",'||
            '"'||C_VIEW_DATA_REC.EBS_INVOICE_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_INVOICE_NUM||'",'||
            '"'||C_VIEW_DATA_REC.EBS_PAY_GROUP||'",'||
            '"'||C_VIEW_DATA_REC.EBS_PAY_PRIORITY||'",'||
            '"'||C_VIEW_DATA_REC.EBS_SUP_PAY_PRIORITY||'",'||
            '"'||C_VIEW_DATA_REC.EBS_SITE_PAY_PRIORITY||'",'||
            '"'||C_VIEW_DATA_REC.EBS_VOUCHER_NUM||'",'||
            '"'||C_VIEW_DATA_REC.EBS_CASH_DISCOUNT_AMOUNT||'",'||
            '"'||C_VIEW_DATA_REC.EBS_INV_AMT_BEFORE_CASH_DISC||'"');
       END LOOP;

      UTL_FILE.FCLOSE(v_output); 

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');

     END INVOICE_EXTRACT;   

 /***********************************************/
 /* PROCEDURE ORGANIZATION_EXTRACT              */
 /* Procedure to extract organization data      */
 /* OBSOLETE DO NOT USE (Kept for backwards compatibility)      */
 /***********************************************/
    PROCEDURE ORGANIZATION_EXTRACT(
                          errbuf            OUT   VARCHAR2, 
                          retcode           OUT   NUMBER
                                    )
     IS
        v_filename      VARCHAR2(50);
        v_output        utl_file.file_type;


        CURSOR C_VIEW_META IS
          SELECT COLUMN_NAME
          FROM ALL_TAB_COLUMNS
          WHERE TABLE_NAME = 'XX_AP_C2FO_ORGANIZATION_V'
          ORDER BY COLUMN_ID;

        CURSOR C_VIEW_DATA IS
          SELECT *
          FROM XX_AP_C2FO_ORGANIZATION_V;

     BEGIN

      v_filename := 'buyer_organization_'||TO_CHAR(TRUNC(sysdate),'YYYYMMDD')||'.csv';

      v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

      --Loop through columns and write to file
--      FOR C_VIEW_META_REC IN C_VIEW_META LOOP
--      
--        UTL_FILE.PUTF(v_output, '"'||LOWER(C_VIEW_META_REC.COLUMN_NAME)||'",');
--      
--      END LOOP;
--      UTL_FILE.PUT_LINE(v_output,'');

          UTL_FILE.PUT_LINE(v_output, 
            '"COMPANY_ID'||'",'||
            '"COMPANY_NAME'||'",'||
            '"ADDRESS_1'||'",'||
            '"ADDRESS_2'||'",'||
            '"CITY'||'",'||
            '"STATE'||'",'||
            '"POSTAL_CODE'||'",'||
            '"COUNTRY'||'",'||
            '"RESERVE_PERCENTAGE'||'",'||
            '"RESERVE_AMOUNT'||'",'||
            '"RESERVE_INVOICE_PRIORITY'||'",'||
            '"RESERVE_BEFORE_ADJUSTMENTS'||'",'||
            '"TAX_ID'||'"');

      --Loop through data and write to file
      --TODO:  Make columns dynamic for data stream
      FOR C_VIEW_DATA_REC IN C_VIEW_DATA LOOP
          UTL_FILE.PUT_LINE(v_output, 
            '"'||C_VIEW_DATA_REC.COMPANY_ID||'",'||
            '"'||C_VIEW_DATA_REC.COMPANY_NAME||'",'||
            '"'||C_VIEW_DATA_REC.ADDRESS_1||'",'||
            '"'||C_VIEW_DATA_REC.ADDRESS_2||'",'||
            '"'||C_VIEW_DATA_REC.CITY||'",'||
            '"'||C_VIEW_DATA_REC.STATE||'",'||
            '"'||C_VIEW_DATA_REC.POSTAL_CODE||'",'||
            '"'||C_VIEW_DATA_REC.COUNTRY||'",'||
            '"'||C_VIEW_DATA_REC.RESERVE_PERCENTAGE||'",'||
            '"'||C_VIEW_DATA_REC.RESERVE_AMOUNT||'",'||
            '"'||C_VIEW_DATA_REC.RESERVE_INVOICE_PRIORITY||'",'||
            '"'||C_VIEW_DATA_REC.RESERVE_BEFORE_ADJUSTMENTS||'",'||
            '"'||C_VIEW_DATA_REC.TAX_ID||'"');
       END LOOP;

      UTL_FILE.FCLOSE(v_output); 

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');

     END ORGANIZATION_EXTRACT; 

 /***********************************************/
 /* PROCEDURE USER_EXTRACT                      */
 /* Procedure to extract user data                */
 /* OBSOLETE DO NOT USE (Kept for backwards compatibility)      */
 /***********************************************/
    PROCEDURE USER_EXTRACT(
                          errbuf            OUT   VARCHAR2, 
                          retcode           OUT   NUMBER
                                    )
     IS
             v_filename      VARCHAR2(50);
        v_output        utl_file.file_type;


        CURSOR C_VIEW_META IS
          SELECT COLUMN_NAME
          FROM ALL_TAB_COLUMNS
          WHERE TABLE_NAME = 'XX_AP_C2FO_USER_V'
          ORDER BY COLUMN_ID;

        CURSOR C_VIEW_DATA IS
          SELECT *
          FROM XX_AP_C2FO_USER_V;

     BEGIN

      v_filename := 'buyer_user_'||TO_CHAR(TRUNC(sysdate),'YYYYMMDD')||'.csv';

      v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

      --Loop through columns and write to file
--      FOR C_VIEW_META_REC IN C_VIEW_META LOOP
--      
--        UTL_FILE.PUTF(v_output, '"'||LOWER(C_VIEW_META_REC.COLUMN_NAME)||'",');
--      
--      END LOOP;
--      UTL_FILE.PUT_LINE(v_output,'');

          UTL_FILE.PUT_LINE(v_output, 
            '"COMPANY_ID'||'",'||
            '"DIVISION_ID'||'",'||
            '"EMAIL_ADDRESS'||'",'||
            '"FIRST_NAME'||'",'||
            '"LAST_NAME'||'",'||
            '"TITLE'||'",'||
            '"PHONE_NUMBER'||'",'||
            '"ADDRESS_1'||'",'||
            '"ADDRESS_2'||'",'||
            '"CITY'||'",'||
            '"STATE'||'",'||
            '"POSTAL_CODE'||'",'||
            '"COUNTRY'||'"');

      --Loop through data and write to file
      --TODO:  Make columns dynamic for data stream
      FOR C_VIEW_DATA_REC IN C_VIEW_DATA LOOP
          UTL_FILE.PUT_LINE(v_output, 
            '"'||C_VIEW_DATA_REC.COMPANY_ID||'",'||
            '"'||C_VIEW_DATA_REC.DIVISION_ID||'",'||
            '"'||C_VIEW_DATA_REC.EMAIL_ADDRESS||'",'||
            '"'||C_VIEW_DATA_REC.FIRST_NAME||'",'||
            '"'||C_VIEW_DATA_REC.LAST_NAME||'",'||
            '"'||C_VIEW_DATA_REC.TITLE||'",'||
            '"'||C_VIEW_DATA_REC.PHONE_NUMBER||'",'||
            '"'||C_VIEW_DATA_REC.ADDRESS_1||'",'||
            '"'||C_VIEW_DATA_REC.ADDRESS_2||'",'||
            '"'||C_VIEW_DATA_REC.CITY||'",'||
            '"'||C_VIEW_DATA_REC.STATE||'",'||
            '"'||C_VIEW_DATA_REC.POSTAL_CODE||'",'||
            '"'||C_VIEW_DATA_REC.COUNTRY||'"');
       END LOOP;

      UTL_FILE.FCLOSE(v_output); 

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');

     END USER_EXTRACT; 
-----PO PART3-------------------------    

 /***************************************************************/
 /* PROCEDURE PO_EXTRACT                                   */
 /* Procedure to extract po data                           */
 /* OBSOLETE DO NOT USE (Kept for backwards compatibility)      */
 /***************************************************************/
    PROCEDURE PO_EXTRACT(
                          errbuf            OUT   VARCHAR2, 
                          retcode           OUT   NUMBER
                                    )
     IS
        v_filename      VARCHAR2(50);
        v_output        utl_file.file_type;


        CURSOR C_VIEW_META IS
          SELECT COLUMN_NAME
          FROM ALL_TAB_COLUMNS
          WHERE TABLE_NAME = 'XX_AP_C2FO_OP_PO_DETAILS_ND_V'
          ORDER BY COLUMN_ID;

        CURSOR C_VIEW_DATA IS
          SELECT *
          FROM XX_AP_C2FO_OP_PO_DETAILS_ND_V;

     BEGIN

      v_filename := 'buyer_po_'||TO_CHAR(TRUNC(sysdate),'YYYYMMDD')||'.csv';

      v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

      --Loop through columns and write to file
--      FOR C_VIEW_META_REC IN C_VIEW_META LOOP
--      
--        UTL_FILE.PUTF(v_output, '"'||LOWER(C_VIEW_META_REC.COLUMN_NAME)||'",');
--      
--      END LOOP;


          UTL_FILE.PUT_LINE(v_output, 
            '"COMPANY_ID'||'",'||
            '"DIVISION_ID'||'",'||
            '"PO_ID'||'",'||
            '"AMOUNT'||'",'||
            '"CURRENCY'||'",'||
            '"CREATE_DATE'||'",'||
            '"APPROVED_DATE'||'",'||
            '"SHIP_DATE'||'",'||
            '"SHIP_ORIG_COUNTRY'||'",'||
            '"SHIP_ORIG_STATE'||'",'||
            '"ESTIMATED_ARRIVAL_DATE'||'",'||
            '"ACTUAL_ARRIVAL_DATE'||'",'||
            '"SUPPLIER_COUNTRY'||'",'||
            '"COMPANY_CODE'||'",'||
            '"WAREHOUSE_CODE'||'",'||
            '"EBS_ORG_ID'||'",'||
            '"EBS_PONUMBER'||'",'||
            '"EBS_PO_HEADER_ID'||'",'||
            '"EBS_SUPPLIER'||'",'||
            '"EBS_SUPPLIER_NUMBER'||'",'||
            '"EBS_VENDOR_ID'||'",'||
            '"EBS_SUPPLIERSITE'||'",'||
            '"EBS_VENDOR_SITE_ID'||'",'||
            '"EBS_POTYPE'||'",'||
            '"EBS_PODATE'||'",'||
            '"EBS_BILLTO_LOC'||'",'||
            '"EBS_BUYER'||'",'||
            '"EBS_AUTHORIZATION_STATUS'||'",'||
            '"EBS_TERMS'||'",'||
            '"EBS_CLOSED_CODE'||'",'||        
            '"EBS_SHIP_TO_LOCATION_ID'||'"');            

--      UTL_FILE.PUT_LINE(v_output,'');

      --Loop through data and write to file
      --TODO:  Make columns dynamic for data stream
      FOR C_VIEW_DATA_REC IN C_VIEW_DATA LOOP
          UTL_FILE.PUT_LINE(v_output, 
            '"'||C_VIEW_DATA_REC.COMPANY_ID||'",'||
            '"'||C_VIEW_DATA_REC.DIVISION_ID||'",'||
            '"'||C_VIEW_DATA_REC.PO_ID||'",'||
            '"'||C_VIEW_DATA_REC.AMOUNT||'",'||
            '"'||C_VIEW_DATA_REC.CURRENCY||'",'||
            '"'||C_VIEW_DATA_REC.CREATE_DATE||'",'||
            '"'||C_VIEW_DATA_REC.APPROVED_DATE||'",'||
            '"'||C_VIEW_DATA_REC.SHIP_DATE||'",'||
            '"'||C_VIEW_DATA_REC.SHIP_ORIG_COUNTRY||'",'||
            '"'||C_VIEW_DATA_REC.SHIP_ORIG_STATE||'",'||
            '"'||C_VIEW_DATA_REC.ESTIMATED_ARRIVAL_DATE||'",'||
            '"'||C_VIEW_DATA_REC.ACTUAL_ARRIVAL_DATE||'",'||
            '"'||C_VIEW_DATA_REC.SUPPLIER_COUNTRY||'",'||
            '"'||C_VIEW_DATA_REC.COMPANY_CODE||'",'||
            '"'||C_VIEW_DATA_REC.WAREHOUSE_CODE||'",'||
            '"'||C_VIEW_DATA_REC.EBS_ORG_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_PONUMBER||'",'||
            '"'||C_VIEW_DATA_REC.EBS_PO_HEADER_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_SUPPLIER||'",'||
            '"'||C_VIEW_DATA_REC.EBS_SUPPLIER_NUMBER||'",'||
            '"'||C_VIEW_DATA_REC.EBS_VENDOR_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_SUPPLIERSITE||'",'||    
            '"'||C_VIEW_DATA_REC.EBS_VENDOR_SITE_ID||'",'||
            '"'||C_VIEW_DATA_REC.EBS_POTYPE||'",'||    
            '"'||C_VIEW_DATA_REC.EBS_PODATE||'",'||
            '"'||C_VIEW_DATA_REC.EBS_BILLTO_LOC||'",'||    
            '"'||C_VIEW_DATA_REC.EBS_BUYER||'",'||
            '"'||C_VIEW_DATA_REC.EBS_AUTHORIZATION_STATUS||'",'||    
            '"'||C_VIEW_DATA_REC.EBS_TERMS||'",'||
            '"'||C_VIEW_DATA_REC.EBS_CLOSED_CODE||'",'||           
            '"'||C_VIEW_DATA_REC.EBS_SHIP_TO_LOCATION_ID||'"');
       END LOOP;

      UTL_FILE.FCLOSE(v_output); 

     EXCEPTION
       WHEN utl_file.invalid_path THEN
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR file.');

     END PO_EXTRACT;   

 /***********************************************/

-----PO PART3-------------------------         

END  XX_AP_C2FO_EXTRACT_PKG;
/

--SHOW ERRORS