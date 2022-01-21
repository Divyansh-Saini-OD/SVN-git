 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating PACKAGE BODY XX_AP_DATA_REV_AUDIT_PKG
 PROMPT Program exits IF the creation IS NOT SUCCESSFUL
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE PACKAGE BODY XX_AP_DATA_REV_AUDIT_PKG
 AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name : AP Data For Reverse Audit                                  |
-- | Rice ID : R1091                                                   |
-- | Description :AP detail to aid with conduction reverse             |
-- |             audits regarding sales tax payments                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   ===============      =======================|
-- |1.0       10-JAN-2008  Sowmya M S           Initial version        |
-- |                                                                   |
-- |1.1       29-JAN-2008  Sowmya.M.S           Fixed for the          |
-- |                                            Defect No : 3720       |
-- |                                                                   |
-- |1.2       27-OCT-2015  Harvinder Rakhra     Retrofit R12.2 Removed |
-- |                                            Schema Prefix          |
-- +===================================================================+

   gc_file_name         VARCHAR2(100);
   gt_file              UTL_FILE.FILE_TYPE;

-- +===================================================================+
-- | Name       : DATA_REV_AUDIT                                       |
-- | Parameters :p_state,p_gl_account,p_location,p_legal entity,       |
-- |             p_from_date,p_to_date,p_vendor_name,p_delimiter,      |
-- |             p_file_path,p_dest_file_path,p_file_name,             |
-- |             p_file_extension                                      |
-- |                                                                   |
-- | Returns    : Return Code                                          |
-- |              Error Message                                        |
-- +===================================================================+

 PROCEDURE DATA_REV_AUDIT(
                             x_error_buff      OUT  VARCHAR2
                            ,x_ret_code        OUT  NUMBER
                            ,p_state           IN   VARCHAR2
                            ,p_gl_account      IN   VARCHAR2
                            ,p_location        IN   VARCHAR2
                            ,p_legal_entity    IN   VARCHAR2
                            ,p_from_date       IN   VARCHAR2
                            ,p_to_date         IN   VARCHAR2
                            ,p_vendor_name     IN   VARCHAR2
                            ,p_delimiter       IN   VARCHAR2
                            ,p_file_path       IN   VARCHAR2
                            ,p_dest_file_path  IN   VARCHAR2
                            ,p_file_name       IN   VARCHAR2
                            ,p_file_extension  IN   VARCHAR2
                            )

    AS
    EX_USER_CA_ORG_ID             EXCEPTION;
    lc_file_path                  VARCHAR2(500);
    lc_timestamp                  VARCHAR2(100);
    lc_source_file_path           VARCHAR2(100);
    lc_dest_file_path             VARCHAR2(100);
    lc_source_file_name           VARCHAR2(1000);
    lc_dest_file_name             VARCHAR2(1000);
    ln_req_id                     NUMBER;
    ln_amount_paid                ap_invoice_distributions_all.amount%TYPE := 0;
    ln_accrued_tax                NUMBER := 0;
    ln_tax_paid                   NUMBER := 0;
    ln_parent_invoice_id          NUMBER;
    lc_target_value1_1            xx_fin_translatevalues.target_value1% TYPE;
    lc_target_value1_2            xx_fin_translatevalues.target_value1% TYPE;
    lc_target_value1_3            xx_fin_translatevalues.target_value1% TYPE;
    lc_target_value1_4            xx_fin_translatevalues.target_value1% TYPE;
    lc_value1                     VARCHAR2(50); 
    lc_value2                     VARCHAR2(50);
    lc_value3                     VARCHAR2(50);
    lc_value4                     VARCHAR2(50);
    lc_flag                       VARCHAR2(1) := 'N';
    lc_department                 xx_fin_translatevalues.target_value1%TYPE;
    ld_check_date                 DATE;
    lc_ap_reference_id            VARCHAR2(50) := 0;
    lc_ca_org_id                  NUMBER;
    lc_invoicenum_tax             VARCHAR2(50);
    lc_valconcat                  VARCHAR2(5000);
    ln_req_id_ftp                 NUMBER(10);


        CURSOR c_ap_invoice_header (lc_department xx_fin_translatevalues.target_value1%TYPE) IS
          SELECT AI.source                         INVOICE_SOURCE
                 ,PV.segment1                      SUPPLIER_ID
                 ,AI.voucher_num                   VOUCHER_NUM
                 ,GCC.segment1                     LEGAL_ENTITY
                 ,AI.invoice_num                   INVOICE_NUM
                 ,AI.invoice_date                  INVOICE_DATE
                 ,AI.description                   PAYMENT_CHECK_DESCRIPTION
                 ,PV.vendor_name                   SUPPLIER_NAME
                 ,PVS.address_line1                FIRST_LINE
                 ,PVS.address_line2                SECOND_LINE
                 ,PVS.address_line3                THIRD_LINE
                 ,PVS.address_line4                FOURTH_LINE
                 ,PVS.city                         SUPPLIER_CITY
                 ,PVS.state                        SUPPLIER_STATE
                 ,PVS.zip                          SUPPLIER_ZIP_CODE
                 ,AI.payment_status_flag           STATUS_FLAG
                 ,AID.attribute8                   ACCURED_TAX
                 ,AID.invoice_distribution_id      INVOICE_DIST_ID
                 ,AI.invoice_id                    INVOICE_ID
                 --Metrics
                 ,NVL (AI.amount_paid, 0)          AMOUNT_PAID
                 ,NVL (AI.invoice_amount, 0)       GROSS_AMOUNT
                 , AI.org_id                       ORG_ID
                 ,GCC.segment3                     ACCT_NO
                 ,GCC.segment2                     DEPARTMENT
                 ,GCC.segment4                     OPERATING_UNIT
                 ,GCC.segment6                     SALES_CHANNEL
          FROM ap_invoices AI
               ,ap_invoice_distributions AID
               ,po_vendor_sites PVS
               ,gl_code_combinations GCC
               ,po_vendors PV
               ,fnd_flex_values              ffvv
               ,fnd_flex_value_sets          ffvs
          WHERE AI.invoice_id = AID.invoice_id
          AND AI.vendor_id = PV.vendor_id
          AND PVS.vendor_id = PV.vendor_id
          AND AI.vendor_site_id  = PVS.vendor_site_id
          AND AID.dist_code_combination_id  = GCC.code_combination_id
          AND AI.invoice_num NOT IN (SELECT invoice_num
                                     FROM ap_invoices
                                     WHERE invoice_num LIKE '%_TAX'
                                     AND invoice_type_lookup_code = 'CREDIT')
         AND AI.vendor_id =PV.vendor_id
         AND AID.line_type_lookup_code != 'TAX'
         AND ffvv.flex_value_set_id  = ffvs.flex_value_set_id         --  For Defect No : 3720
         AND ffvs.flex_value_set_name = lc_department                 --  For Defect No : 3720
         AND gcc.segment4                  = ffvv.flex_value
          -- IN Parameters
         AND ffvv.attribute4 = p_state
         AND GCC.segment3 = NVL(p_gl_account,GCC.segment3)
         AND GCC.segment4 = NVL(p_location,GCC.segment4)
         AND GCC.segment1 = NVL(p_legal_entity,GCC.segment1)
         AND AI.invoice_date BETWEEN to_date(p_from_date,'YYYY/MM/DD HH24:MI:SS') AND to_date(p_to_date,'YYYY/MM/DD HH24:MI:SS') 

         AND PV.vendor_name = NVL(p_vendor_name,PV.vendor_name);

         BEGIN
                --To get the File Path
                BEGIN
                    SELECT directory_path
                    INTO lc_source_file_path
                    FROM dba_directories
                    WHERE directory_name = p_file_path;
                EXCEPTION
                    WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the File Path : '
                                             || SQLERRM);
                END;

                --To get the Timestamp for Filename
                lc_timestamp:=to_char(sysdate,'DDMONYYYYHHMMSS');
                 
                --Filename
                gc_file_name := p_file_name||lc_timestamp||'.'||p_file_extension;

                -- To get the Flex value set names
                BEGIN
                   SELECT XFT.Target_Value1
                           ,XFT.Target_Value2
                           ,XFT.Target_Value3
                           ,XFT.Target_Value4
                       INTO lc_target_value1_1
                         ,lc_target_value1_2
                         ,lc_target_value1_3
                         ,lc_target_value1_4
                    FROM xx_fin_translatedefinition XFTD
                         ,xx_fin_translatevalues XFT 
                    WHERE  XFTD.translate_id = XFT.translate_id 
                    AND XFTD.translation_name = 'XX_AP_GLVALUESETS'
                    AND XFT.enabled_flag = 'Y';
                EXCEPTION
                    WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Felx value name set : '
                                         || SQLERRM);
                END;

               lc_ca_org_id := 0;
                BEGIN
                    SELECT HOU.organization_id
                    INTO lc_ca_org_id
                    FROM xx_fin_translatedefinition  XFTD
                         ,xx_fin_translatevalues     XFTV
                         ,hr_organization_units      HOU
                    WHERE  translation_name = 'OD_COUNTRY_DEFAULTS'
                    AND    XFTV.translate_id = XFTD.translate_id
                    AND    XFTV.source_value1  = 'CA'
                    AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
                    AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
                    AND    XFTV.enabled_flag = 'Y'
                    AND    XFTD.enabled_flag = 'Y'
                    AND    XFTV.target_value2=HOU.name;
                EXCEPTION
                    WHEN OTHERS   THEN
                        RAISE EX_USER_CA_ORG_ID;
                END;
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'ORG ID :'|| lc_ca_org_id);

                lc_valconcat:= ('INVOICE_SOURCE'
                                || p_delimiter ||'SUPPLIER_ID'
                                || p_delimiter ||'VOUCHER_NUM'
                                || p_delimiter ||'LEGAL_ENTITY'
                                || p_delimiter ||'OPERATING_UNIT_ID'
                                || p_delimiter ||'OD_DEPT'
                                || p_delimiter ||'GL_SALES_CHANNEL'
                                || p_delimiter ||'GL_ACCOUNT'
                                || p_delimiter ||'INVOICE_NUM'
                                || p_delimiter ||'INVOICE_DATE'
                                || p_delimiter ||'PAYMENT_CHECK_DESC'
                                || p_delimiter ||'SUPPLIER_NAME'
                                || p_delimiter ||'FIRST_LINE'
                                || p_delimiter ||'SECOND_LINE'
                                || p_delimiter ||'THIRD_LINE'
                                || p_delimiter ||'FOURTH_LINE'
                                || p_delimiter ||'SUPPLIER_CITY'
                                || p_delimiter ||'SUPPLIER_STATE'
                                || p_delimiter ||'SUPPLIER_ZIP_CODE'
                                || p_delimiter ||'AP_REFERENCE_ID'
                                || p_delimiter ||'PAYMENT_DATE'
                                || p_delimiter ||'AMOUNT_PAID'
                                || p_delimiter ||'TAX_AMOUNT'
                                || p_delimiter ||'GROSS_AMOUNT_PAID'
                                || p_delimiter ||'TAX_AMOUNT_PAID'
                                || p_delimiter ||'ACCRUED_TAX');
                --Calling the procedure to write header to the file
                DATA_REV_AUDIT_WRITE_FILE(lc_valconcat,p_file_path,lc_flag);
                lc_valconcat:= 0;

                FOR lcu_ap_invoice_header_rec IN c_ap_invoice_header (lc_target_value1_1)
                LOOP
                    ln_amount_paid := 0;
                    ln_accrued_tax := 0;
                    ln_tax_paid    := 0;

                    -- To get the description for Sales channel
                    BEGIN
                        SELECT ffvv.description
                        INTO lc_value2
                        FROM fnd_flex_values_vl            FFVV
                             ,fnd_flex_value_sets          FFVS
                        WHERE FFVV.flex_value_set_id = FFVS.flex_value_set_id
                        AND FFVV.flex_value =  lcu_ap_invoice_header_rec.SALES_CHANNEL
                        AND FFVS.flex_value_set_name = lc_target_value1_2;
                    EXCEPTION
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching description for Sales channel : '
                                               || SQLERRM);
                    END;

                    --To get the Tax Amount (Sales Tax )
                    BEGIN
                        SELECT SUM(AID.amount)
                        INTO ln_amount_paid
                        FROM ap_invoice_distributions    AID
                        WHERE AID.invoice_id  = lcu_ap_invoice_header_rec.INVOICE_ID
                        AND AID.line_type_lookup_code = 'TAX';
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN 
                        ln_amount_paid:=0;
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Tax amount : '
                                          || SQLERRM);
                    END;

                    ld_check_date := '';
                    lc_ap_reference_id := 0;

                    --To get the Check date for paid invoices
                    BEGIN
                        SELECT check_date
                               ,DECODE (AIP.invoice_payment_type
                                        ,'PREPAY', lcu_ap_invoice_header_rec.INVOICE_NUM
                                        ,AC.check_number
                                       )
                        INTO ld_check_date
                             ,lc_ap_reference_id
                        FROM ap_invoice_payments AIP
                             ,ap_checks AC 
                        WHERE AIP.invoice_id =lcu_ap_invoice_header_rec.INVOICE_ID
                        AND AC.check_id =  AIP.check_id 
                        AND AC.status_lookup_code  NOT IN ('OVERFLOW'
                                                           ,'SET UP'
                                                           ,'SPOILED'
                                                           ,'STOP INITIATED'
                                                           ,'UNCONFIRMED SET UP'
                                                           ,'VOIDED');
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            ld_check_date := '';
                            lc_ap_reference_id := 0;
                        WHEN OTHERS THEN
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching Check Date : '
                                            || SQLERRM);
                    END;

                    --For Fully paid Invoices
                   IF(lcu_ap_invoice_header_rec.STATUS_FLAG = 'Y') THEN
                       --Accrued Tax
                       ln_accrued_tax:= 0;
                       -- Tax Amount Paid
                       ln_tax_paid := ln_amount_paid;
                   END IF;
                  lc_invoicenum_tax :=lcu_ap_invoice_header_rec.INVOICE_NUM||'_TAX';
                       --To check for Credit memos
                       BEGIN
                          SELECT COUNT(AI.invoice_id)
                          INTO   ln_parent_invoice_id
                          FROM   ap_invoices           AI
                          WHERE  AI.invoice_num  LIKE lc_invoicenum_tax;
                       EXCEPTION
                           WHEN OTHERS THEN
                           FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Parent invoice id : '
                                               || SQLERRM);
                       END;
                       --Credit memos
                       IF ln_parent_invoice_id >0 THEN
                           --Tax Amount Paid
                           ln_tax_paid:= 0;
                           --Accrued Tax           For Defect No : 3720
                           IF (( lcu_ap_invoice_header_rec.ORG_ID = lc_ca_org_id ) AND (lc_ca_org_id!= 0)) THEN
                               lc_invoicenum_tax := 0;
                               lc_invoicenum_tax :=lcu_ap_invoice_header_rec.INVOICE_NUM||'_TAX';
                               BEGIN
                                   SELECT  SUM(AID.amount)
                                   INTO ln_accrued_tax
                                   FROM ap_invoice_distributions    AID
                                        ,ap_invoices                 AI
                                        ,ap_tax_codes                ATC
                                   WHERE AI.invoice_id = AID.Invoice_id
                                   AND AI.invoice_num = lc_invoicenum_tax 
                                   AND AID.line_type_lookup_code    = 'TAX'
                                   AND ATC.tax_id=AID.tax_code_id 
                                   AND ATC.name like 'PST%'
                                   AND AID.amount >0;
                               EXCEPTION
                                   WHEN OTHERS   THEN
                                   FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while fetching the Accrued Tax for CAD :'
                                                       || SQLERRM );
                               END;
                           ELSE
                               ln_accrued_tax :=lcu_ap_invoice_header_rec.ACCURED_TAX;
                           END IF;
                       ELSE
                           --Tax Amount Paid
                           ln_tax_paid := (lcu_ap_invoice_header_rec.AMOUNT_PAID * ln_amount_paid) / lcu_ap_invoice_header_rec.GROSS_AMOUNT;
                           -- Accrued Tax
                           ln_accrued_tax:= 0;
                       END IF;

                  lc_valconcat:= ( lcu_ap_invoice_header_rec.INVOICE_SOURCE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.SUPPLIER_ID || 
                                 p_delimiter || lcu_ap_invoice_header_rec.VOUCHER_NUM ||
                                 p_delimiter || lcu_ap_invoice_header_rec.LEGAL_ENTITY ||
                                 p_delimiter || lcu_ap_invoice_header_rec.OPERATING_UNIT ||
                                 p_delimiter || lcu_ap_invoice_header_rec.DEPARTMENT ||
                                 p_delimiter || lc_value2 ||
                                 p_delimiter || lcu_ap_invoice_header_rec.ACCT_NO ||
                                 p_delimiter || lcu_ap_invoice_header_rec.INVOICE_NUM ||
                                 p_delimiter || lcu_ap_invoice_header_rec.INVOICE_DATE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.PAYMENT_CHECK_DESCRIPTION ||
                                 p_delimiter || lcu_ap_invoice_header_rec.SUPPLIER_NAME ||
                                 p_delimiter || lcu_ap_invoice_header_rec.FIRST_LINE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.SECOND_LINE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.THIRD_LINE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.FOURTH_LINE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.SUPPLIER_CITY ||
                                 p_delimiter || lcu_ap_invoice_header_rec.SUPPLIER_STATE ||
                                 p_delimiter || lcu_ap_invoice_header_rec.SUPPLIER_ZIP_CODE ||
                                 p_delimiter || lc_ap_reference_id ||
                                 p_delimiter || ld_check_date ||
                                 p_delimiter || lcu_ap_invoice_header_rec.AMOUNT_PAID ||
                                 p_delimiter || ln_amount_paid ||
                                 p_delimiter || lcu_ap_invoice_header_rec.GROSS_AMOUNT ||
                                 p_delimiter || ln_tax_paid ||
                                 p_delimiter || ln_accrued_tax );

                  --Calling the procedure to write data to the file
                  DATA_REV_AUDIT_WRITE_FILE(lc_valconcat,p_file_path,lc_flag);

                END LOOP;

                --Flag set to close the file
                lc_flag :='Y';
                lc_valconcat :=0;
                  DATA_REV_AUDIT_WRITE_FILE(lc_valconcat,p_file_path,lc_flag);

commit;
                -- To Call the Common file copy Program Copy to $XXFIN_DATA/ftp/out/tax audit hyperion
                lc_source_file_name  := lc_source_file_path || '/' ||gc_file_name;
                lc_dest_file_name    := p_dest_file_path   || '/' || gc_file_name;

/*              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Created File Name     : ' || lc_source_file_name);
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File Copied  Path     : ' || lc_dest_file_name);

               ln_req_id := FND_REQUEST.SUBMIT_REQUEST (
                                                        'xxfin'
                                                        ,'XXCOMFILCOPY'
                                                        ,''
                                                        ,''
                                                        ,FALSE
                                                        ,lc_source_file_name
                                                        ,lc_dest_file_name
                                                        ,NULL
                                                        ,NULL
                                                         );
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Files is to be written to ' ||  lc_dest_file_path
                                                    || '. Request id : ' || ln_req_id);
*/
       ln_req_id_ftp := FND_REQUEST.SUBMIT_REQUEST(
                                               'xxfin'
                                               ,'XXCOMFTP'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,'OD_AP_TAX_AUDIT'                      --Process Name
                                               ,gc_file_name                      --source_file_name
                                               ,gc_file_name                      --destination_file_name
                                               ,'Y'                                    -- Delete source file?
                                               ,NULL
                                              );

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The FTP Put Program is submitted '
                                     || ' Request id : ' || ln_req_id_ftp);


 EXCEPTION
    WHEN EX_USER_CA_ORG_ID THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception Raised while Fetching the Org_IG for Canada '
                                     ||'Program'|| SQLERRM );
    WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised in the procedure : '
                          || SQLERRM); 
 END DATA_REV_AUDIT;

-------------------------------------------------------------------------------------------------------------------

-- +===================================================================+
-- | Name       : DATA_REV_AUDIT_WRITE_FILE                            |
-- |                                                                   |
-- | Parameters : p_valconcat,p_file_path,p_flag                       |
-- |                                                                   |
-- +===================================================================+

 PROCEDURE DATA_REV_AUDIT_WRITE_FILE(
                                      p_valconcat                 IN VARCHAR2
                                     ,p_file_path                 IN  VARCHAR2
                                     ,p_flag                      IN  VARCHAR2
                                     )
 AS

     ln_buffer   BINARY_INTEGER := 32767;

 BEGIN
   IF p_flag ='N' THEN
      IF UTL_FILE.is_open(gt_file) THEN
      --To write to the file
         UTL_FILE.PUT_LINE(gt_file , p_valconcat);
      ELSE
          --Opening a file
          BEGIN
              gt_file := UTL_FILE.fopen(p_file_path, gc_file_name,'w',ln_buffer);
              UTL_FILE.PUT_LINE(gt_file , p_valconcat);
          EXCEPTION
              WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the file : '|| SQLERRM);
          END;
      END IF;
   END IF;
   --To close the file
   IF p_flag = 'Y' THEN
       UTL_FILE.fclose(gt_file);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Sales and tax details have been written into the file successfully.');
   END IF;

END DATA_REV_AUDIT_WRITE_FILE;

END XX_AP_DATA_REV_AUDIT_PKG;
/
SHO ERR