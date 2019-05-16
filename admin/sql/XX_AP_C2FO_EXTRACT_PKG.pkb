SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_C2FO_EXTRACT_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace 
PACKAGE BODY  XX_AP_C2FO_EXTRACT_PKG AS
/****************************************************************************************************************
*   Name:        XXC2FO_EXTRACT_PKG
*   PURPOSE:     This package was created for the C2O Extract Process
*   @author      Joshua Wilson - C2FO
*   @version     12.1.3.1.0XX_AP_C2FO_EXTRACT_PKG Body

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
*   1.1          5/13/2019    Arun DSouza               OD                Funding Partner Bank Extract Code
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
        V_ORG_COUNT                        NUMBER := 0;
        v_user_count                       NUMBER := 0;
        v_count                            NUMBER := 0;
        v_po_count                         NUMBER := 0;
        l_validated_po_date_from           VARCHAR2(11) := TO_CHAR(add_months(SYSDATE,-120),lc_date_format);
        L_VALIDATED_PO_DATE_TO             varchar2(11) := TO_CHAR(sysdate,LC_DATE_FORMAT);

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
-----------------------------


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
                  ebs_inv_amt_before_cash_disc,
                  ebs_invoice_due_date
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
                  c_inv_data_rec(ind).ebs_inv_amt_before_cash_disc,
                  c_inv_data_rec(ind).ebs_invoice_due_date
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
              '"EBS_INV_AMT_BEFORE_CASH_DISC'||'",'||
              '"EBS_INVOICE_DUE_DATE'||'"'              
              ));


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
              '"'||c_inv_data_rec_t(ind).ebs_cash_discount_amount||'",'||
              '"'||c_inv_data_rec_t(ind).ebs_inv_amt_before_cash_disc||'",' ||             
              '"'||c_inv_data_rec_t(ind).ebs_invoice_due_date ||'"'               
              );

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

/***********************************************/
 /* PROCEDURE REMIT BANK EXTRACT              */
 /* Procedure to extract C2FO Remit to Supplier and Original Supplier Bank Account Info for Funding Partner Award Invoices  */
 /***********************************************/
    PROCEDURE REMIT_BANK_EXTRACT(
                          errbuf            OUT   VARCHAR2,
                          retcode           OUT   NUMBER
                                    )     IS
        v_filename      varchar2(50);
        v_output        utl_file.file_type;

 -------------- P2-Funding-Partner Awd Remit Bank ---------------------------------------------

    v_awd_count                        number := 0;

 CURSOR C_AWD_FP
IS
  SELECT awd.COMPANY_ID ,
    awd.COMPANY_NAME ,
    awd.DIVISION_ID ,
    awd.FUND_TYPE ,
    awd.INVOICE_ID ,
    awd.ORIGINAL_AMOUNT ,
    awd.CURRENCY ,
    awd.ORIGINAL_DUE_DATE ,
    awd.PAY_DATE ,
    awd.TRANSACTION_TYPE ,
    awd.AWARD_NUM ,
    awd.PAYMENT_METHOD_CODE ,
    awd.EBS_SUPPLIER_NUMBER ,
    awd.EBS_VENDOR_SITE_CODE ,
    awd.EBS_INVOICE_NUM ,
    awd.EBS_ORG_ID ,
    awd.EBS_VENDOR_ID ,
    awd.EBS_VENDOR_SITE_ID ,
    awd.EBS_INVOICE_ID ,
    awd.EBS_CM_INVOICE_ID ,
    awd.AWARD_FILE_BATCH_NAME ,
    awd.AWARD_RECORD_ACTIVITIES ,
    awd.PROCESS_FLAG ,
    awd.PROCESS_STATUS ,
    awd.PROCESSED_DATE ,
    AWD.ERROR_MSG ,
    AIA.REMIT_TO_SUPPLIER_NAME ,
    AIA.REMIT_TO_SUPPLIER_ID ,
    AIA.REMIT_TO_SUPPLIER_SITE ,
    AIA.REMIT_TO_SUPPLIER_SITE_ID ,
    AIA.RELATIONSHIP_ID ,
    AIA.EXTERNAL_BANK_ACCOUNT_ID,
    AWD.SUPPLIER_BANK_ACCOUNT_ID
  FROM APPS.XX_AP_C2FO_AWARD_DATA_STAGING awd,
    APPS.AP_INVOICES_ALL AIA
  where
  --AWD.AWARD_FILE_BATCH_NAME = 'XX_AP_C2FO-20190502092236'
  AWD.PROCESS_FLAG          = 'Y'
  AND AWD.FUND_TYPE            IS NOT NULL
  AND AIA.INVOICE_ID            = AWD.EBS_INVOICE_ID
  AND award_file_batch_name     =
    (SELECT AWARD_FILE_BATCH_NAME
    FROM APPS.XX_AP_C2FO_AWARD_DATA_STAGING AWD
    where FUND_TYPE  is not null
    AND CREATION_DATE > sysdate - 20
    AND rownum        < 2
    )
ORDER BY awd.CREATION_DATE DESC; 

 CURSOR C_SUPP_BANK_ACCT (cp_vendor_id IN NUMBER, cp_vendor_site_id IN NUMBER)
  is
select
--ieb.branch_id
       ieb.bank_account_name
,      party_bank.party_name bank_name
,      ieb.bank_account_num  bank_account_number
,      party_branch.party_name bank_branch_name
,      branch_prof.bank_or_branch_number bank_routing_number
,      party_branch.address1 address_1
,      party_branch.address2 address_2
,      party_branch.address3 address_3
,      party_branch.address4 address_4
,      party_branch.city city
,      party_branch.state state
,      party_branch.postal_code 
,      party_branch.country country
--
,     party_supp.party_name supplier_name
,      aps.segment1          supplier_number
,      ass.vendor_site_code  supplier_site
,      ieb.ext_bank_account_id
from 
      hz_organization_profiles bank_prof
,      hz_organization_profiles branch_prof
,      hz_parties party_bank
,      hz_parties party_branch
,      iby_ext_bank_accounts ieb
,      iby_pmt_instr_uses_all ipi
,      iby_external_payees_all iep
,      hz_party_sites site_supp
,      hz_parties party_supp
,      ap_supplier_sites_all ass
,      ap_suppliers aps
WHERE   aps.vendor_id =  cp_vendor_id --3M
and ass.vendor_site_id = cp_vendor_site_id  -- 669118 -- 669122 
AND party_supp.party_id = aps.party_id
AND    party_supp.party_id = site_supp.party_id
and    site_supp.party_site_id = ass.party_site_id
AND    ass.vendor_id = aps.vendor_id
AND    iep.payee_party_id = party_supp.party_id
AND    iep.party_site_id = site_supp.party_site_id
AND    iep.supplier_site_id = ass.vendor_site_id
AND    iep.ext_payee_id = ipi.ext_pmt_party_id
AND    ipi.instrument_id = ieb.ext_bank_account_id
AND    IPI.payment_flow = 'DISBURSEMENTS'
AND    IEB.BANK_ID = PARTY_BANK.PARTY_ID
and    sysdate between  nvl(ieb.start_date,sysdate-1) and  nvl(ieb.end_date,sysdate + 1)
AND    ieb.branch_id = party_branch.party_id
AND    party_branch.party_id = branch_prof.party_id
and    PARTY_BANK.PARTY_ID = BANK_PROF.PARTY_ID
and    sysdate between  nvl(ipi.start_date,sysdate-1) and  nvl(ipi.end_date,sysdate + 1)
and   party_bank.status = 'A'
and   party_branch.status = 'A'
and rownum < 2;

  l_bank_acct_null_rec   C_SUPP_BANK_ACCT%ROWTYPE;
  l_supp_bank_acct_rec   c_supp_bank_acct%rowtype;


cursor c_invoice_bank_account(cp_bank_account_id Number)
is
select
--ieb.branch_id
       ieb.bank_account_name
,      party_bank.party_name bank_name
,      ieb.bank_account_num  bank_account_number
,      party_branch.party_name bank_branch_name
,      branch_prof.bank_or_branch_number bank_routing_number
,      party_branch.address1 address_1
,      party_branch.address2 address_2
,      party_branch.address3 address_3
,      party_branch.address4 address_4
,      party_branch.city city
,      party_branch.state state
,      party_branch.postal_code 
,      party_branch.country country
from 
       hz_organization_profiles bank_prof
,      hz_organization_profiles branch_prof
,      hz_parties party_bank
,      hz_parties party_branch
,      iby_ext_bank_accounts ieb
WHERE 
ieb.ext_bank_account_id =  cp_bank_account_id --440440 --726085
and    ieb.bank_id = party_bank.party_id
AND    ieb.branch_id = party_branch.party_id
AND    party_branch.party_id = branch_prof.party_id
and    party_bank.party_id = bank_prof.party_id
and   party_bank.status = 'A'
and   party_branch.status = 'A';


  l_invoice_acct_null_rec   c_invoice_bank_account%rowtype;
  l_invoice_bank_acct_rec   c_invoice_bank_account%ROWTYPE;
 
--------------End P2-Funding-Partner Awd Remit Bank---------------------------------------------

     BEGIN

-------------- P2-Funding-Partner Awd Remit Bank Loop ---------------------------------------------

      --BEGIN AWARD REMIT TO SUPPLIER  BANK  EXTRACT
 
      fnd_file.put_line(fnd_file.LOG,'--------------------AWARD REMIT TO SUPPLIER  BANK  EXTRACT---------------------------');
      FND_FILE.PUT_LINE(FND_FILE.LOG,'-------------------------------------------------------------------------------------');
 
      BEGIN
        --filename officedepot_remit_bank_yyyymmdd.csv

        v_filename := 'officedepot_remit_bank_'||TO_CHAR(TRUNC(sysdate),'YYYYMMDD')||'.csv';

        FND_FILE.PUT_LINE(FND_FILE.LOG, ' ');
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Creating File:   '||v_filename);

        v_output := UTL_FILE.FOPEN(C_DIRECTORY, v_filename, 'W');

            UTL_FILE.PUT_LINE(v_output,
              LOWER(             
              '"COMPANY_ID'             ||'",'||
              '"COMPANY_NAME'           ||'",'||
              '"invoice_id'             ||'",'||
              '"bank_account_name'      ||'",'||
              '"bank_name'              ||'",'||
              '"bank_account_number'    ||'",'||
              '"bank_branch_name'       ||'",'||
              '"bank_routing_number'    ||'",'||
              '"address_1'              ||'",'||
              '"address_2'              ||'",'||
              '"address_3'              ||'",'||
              '"address_4'              ||'",'||
              '"city'                   ||'",'||
              '"state'                  ||'",'||
              '"postal_code'            ||'",'||
              '"country'                ||'",'||
              '"remit_to_supplier_name' ||'",'||              
              '"FUND_TYPE'||'"'
              )            
             );
             
        v_awd_count := 0;
          
        --Loop through data and write to file
        FOR C_AWD_FP_REC IN C_AWD_FP LOOP

             fnd_file.put_line(fnd_file.log, 'Processing Awd Company Id : '|| c_awd_fp_rec.company_id );
             fnd_file.put_line(fnd_file.log, 'Processing Awd Invoice Id : '|| c_awd_fp_rec.invoice_id );

            v_awd_count := v_awd_count + 1;
            
            l_supp_bank_acct_rec := l_bank_acct_null_rec;
 
             fnd_file.put_line(fnd_file.log, 'Step 1' );

            
            OPEN c_supp_bank_acct(c_awd_fp_rec.ebs_vendor_id, c_awd_fp_rec.ebs_vendor_site_id);
               FETCH c_supp_bank_acct into l_supp_bank_acct_rec;
            CLOSE c_supp_bank_acct;

           IF l_supp_bank_acct_rec.bank_account_number  is null then
             fnd_file.put_line(fnd_file.log,'----------------------------------------------------------------------');
             fnd_file.put_line(fnd_file.log, 'Bank Account Not Fetched for Supplier Site : '|| c_awd_fp_rec.ebs_vendor_site_code );
             fnd_file.put_line(fnd_file.log, 'Supplier Number : '|| c_awd_fp_rec.ebs_supplier_number );
             fnd_file.put_line(fnd_file.log, 'Invoice Id : '|| c_awd_fp_rec.ebs_invoice_id );
             fnd_file.put_line(fnd_file.log, 'Invoice Num : '|| c_awd_fp_rec.ebs_invoice_num );
             fnd_file.put_line(fnd_file.log, 'Vendor Id : '|| c_awd_fp_rec.ebs_vendor_id );
             fnd_file.put_line(fnd_file.LOG, 'Vendor Site Id : '|| c_awd_fp_rec.ebs_vendor_site_id );
             fnd_file.put_line(fnd_file.log, 'Awd Company Id : '|| c_awd_fp_rec.company_id );
           END IF;


             fnd_file.put_line(fnd_file.log, 'Step 2' );
 
          l_invoice_bank_acct_rec   := l_invoice_acct_null_rec;

         IF c_awd_fp_rec.supplier_bank_account_id is NULL THEN
 
             fnd_file.put_line(fnd_file.log,'----------------------------------------------------------------------');
             fnd_file.put_line(fnd_file.log, 'Orig Supplier Bank Account Id is NULL for Invoice Num : '|| c_awd_fp_rec.ebs_invoice_num );
             fnd_file.put_line(fnd_file.log, 'AWD Invoice Id : '|| c_awd_fp_rec.ebs_invoice_id );
             fnd_file.put_line(fnd_file.log, 'Supplier Number : '|| c_awd_fp_rec.ebs_supplier_number );
             fnd_file.put_line(fnd_file.log, 'EBS Invoice Id : '|| c_awd_fp_rec.ebs_invoice_id );
             fnd_file.put_line(fnd_file.log, 'EBS Invoice Num : '|| c_awd_fp_rec.ebs_invoice_num );
             fnd_file.put_line(fnd_file.log, 'Vendor Id : '|| c_awd_fp_rec.ebs_vendor_id );
             fnd_file.put_line(fnd_file.log, 'Vendor Site Id : '|| c_awd_fp_rec.ebs_vendor_site_id );
             fnd_file.put_line(fnd_file.log, 'Vendor Site Code : '|| c_awd_fp_rec.ebs_vendor_site_code );
         ELSE       

             fnd_file.put_line(fnd_file.log, 'Step 3' );

            OPEN c_invoice_bank_account(c_awd_fp_rec.supplier_bank_account_id);
               FETCH c_invoice_bank_account into l_invoice_bank_acct_rec;
            CLOSE c_invoice_bank_account;

         END IF;

             fnd_file.put_line(fnd_file.log, 'Step 4' );
            
 
            IF c_awd_fp_rec.supplier_bank_account_id IS NOT NULL AND
                l_invoice_bank_acct_rec.bank_account_number  is null then
             fnd_file.put_line(fnd_file.LOG,'----------------------------------------------------------------------');
             fnd_file.put_line(fnd_file.log, 'Orig Invoice Ext Bank Account Not found in IEBA : '|| c_awd_fp_rec.supplier_bank_account_id );
             fnd_file.put_line(fnd_file.log, 'Supplier Number : '|| c_awd_fp_rec.ebs_supplier_number );
             fnd_file.put_line(fnd_file.log, 'EBS Invoice Id : '|| c_awd_fp_rec.ebs_invoice_id );
             fnd_file.put_line(fnd_file.LOG, 'Invoice Num : '|| c_awd_fp_rec.ebs_invoice_num );
             fnd_file.put_line(fnd_file.log, 'Awd Company Id : '|| c_awd_fp_rec.company_id );

            end if;

             fnd_file.put_line(fnd_file.log, 'Step 5' );
            
            IF l_supp_bank_acct_rec.ext_bank_account_id != c_awd_fp_rec.supplier_bank_account_id then              
                fnd_file.put_line(fnd_file.log,'----------------------------------------------------------------------');
                fnd_file.put_line(fnd_file.log, 'Bank Accounts Not Matching  : ');
                fnd_file.put_line(fnd_file.log, 'Invoice Bank Account Id : '|| c_awd_fp_rec.supplier_bank_account_id  );
                fnd_file.put_line(fnd_file.log, 'Fetched Supplier Bank Account Id : '|| l_supp_bank_acct_rec.ext_bank_account_id  );
                fnd_file.put_line(fnd_file.LOG, 'EBS Invoice Id : '|| c_awd_fp_rec.ebs_invoice_id );
                fnd_file.put_line(fnd_file.LOG, 'Invoice Num : '|| c_awd_fp_rec.ebs_invoice_num );
                fnd_file.put_line(fnd_file.LOG, 'Awd Company Id : '|| c_awd_fp_rec.company_id );
            END IF;

             fnd_file.put_line(fnd_file.log, 'Step 6' );
            
           
           IF (l_invoice_bank_acct_rec.bank_account_number is NULL
              AND l_supp_bank_acct_rec.bank_account_name IS NULL )
            THEN
                fnd_file.put_line(fnd_file.LOG,'----------------------------------------------------------------------');
                fnd_file.put_line(fnd_file.log, 'Both Bank Accounts are BLANK  : ');
                fnd_file.put_line(fnd_file.log, 'Invoice Bank Account Id : '|| c_awd_fp_rec.supplier_bank_account_id  );
                fnd_file.put_line(fnd_file.log, 'Fetched Supplier Bank Account Id : '|| l_supp_bank_acct_rec.ext_bank_account_id  );
                fnd_file.put_line(fnd_file.LOG, 'EBS Invoice Id : '|| c_awd_fp_rec.ebs_invoice_id );
                fnd_file.put_line(fnd_file.LOG, 'Invoice Num : '|| c_awd_fp_rec.ebs_invoice_num );
                fnd_file.put_line(fnd_file.LOG, 'Awd Company Id : '|| c_awd_fp_rec.company_id );             
            END IF;
        
          
            IF l_invoice_bank_acct_rec.bank_account_number IS NOT NULL THEN        

             fnd_file.put_line(fnd_file.log, 'Step 6.1' );

 
            UTL_FILE.PUT_LINE(V_OUTPUT,
              '"'||  c_awd_fp_rec.company_id                     ||'",'||
              '"'||  c_awd_fp_rec.company_name                   ||'",'||
              '"'||  c_awd_fp_rec.invoice_id                     ||'",'||
              '"'||  l_invoice_bank_acct_rec.bank_account_name   ||'",'||
              '"'||  l_invoice_bank_acct_rec.bank_name           ||'",'||
              '"'||  l_invoice_bank_acct_rec.bank_account_number ||'",'||
              '"'||  l_invoice_bank_acct_rec.bank_branch_name    ||'",'||
              '"'||  l_invoice_bank_acct_rec.bank_routing_number ||'",'||
              '"'||  l_invoice_bank_acct_rec.address_1           ||'",'||
              '"'||  l_invoice_bank_acct_rec.address_2           ||'",'||
              '"'||  l_invoice_bank_acct_rec.address_3           ||'",'||
              '"'||  l_invoice_bank_acct_rec.address_4           ||'",'||
              '"'||  l_invoice_bank_acct_rec.city                ||'",'||
              '"'||  l_invoice_bank_acct_rec.state               ||'",'||
              '"'||  l_invoice_bank_acct_rec.postal_code         ||'",'||
              '"'||  l_invoice_bank_acct_rec.country             ||'",'||
              '"'||  c_awd_fp_rec.remit_to_supplier_name         ||'",'||              
              '"'||  c_awd_fp_rec.fund_type ||'"');

            ELSE   

             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Step 6.2' );

 
             UTL_FILE.PUT_LINE(V_OUTPUT,
              '"'||  c_awd_fp_rec.company_id                  ||'",'||
              '"'||  c_awd_fp_rec.company_name                ||'",'||
              '"'||  c_awd_fp_rec.invoice_id                     ||'",'||
              '"'||  l_supp_bank_acct_rec.bank_account_name   ||'",'||
              '"'||  l_supp_bank_acct_rec.bank_name           ||'",'||
              '"'||  l_supp_bank_acct_rec.bank_account_number ||'",'||
              '"'||  l_supp_bank_acct_rec.bank_branch_name    ||'",'||
              '"'||  l_supp_bank_acct_rec.bank_routing_number ||'",'||
              '"'||  l_supp_bank_acct_rec.address_1           ||'",'||
              '"'||  l_supp_bank_acct_rec.address_2           ||'",'||
              '"'||  l_supp_bank_acct_rec.address_3           ||'",'||
              '"'||  l_supp_bank_acct_rec.address_4           ||'",'||
              '"'||  l_supp_bank_acct_rec.city                ||'",'||
              '"'||  l_supp_bank_acct_rec.state               ||'",'||
              '"'||  l_supp_bank_acct_rec.postal_code         ||'",'||
              '"'||  l_supp_bank_acct_rec.country             ||'",'||
              '"'||  c_awd_fp_rec.remit_to_supplier_name      ||'",'||              
              '"'||  c_awd_fp_rec.fund_type ||'"');
   
            END IF;
                    
             fnd_file.put_line(fnd_file.log, 'Step 7' );
  
         END LOOP;

            fnd_file.put_line(fnd_file.log, 'Step 8' );


        FND_FILE.PUT_LINE(FND_FILE.log, 'Award Invoice Remit Bank Record Count:   '|| V_AWD_COUNT);

        UTL_FILE.FCLOSE(v_output);

     EXCEPTION
       WHEN UTL_FILE.INVALID_PATH then
          raise_application_error(-20000, 'ERROR: Invalid PATH FOR Invoice Remit Bank file.');
      END;


------------- End P2-Funding-Partner---------------------------------------------



     END REMIT_BANK_EXTRACT;


END  XX_AP_C2FO_EXTRACT_PKG;

/
SHOW ERRORS