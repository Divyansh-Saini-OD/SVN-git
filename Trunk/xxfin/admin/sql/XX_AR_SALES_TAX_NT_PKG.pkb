 SET SHOW OFF
 SET VERIFY OFF
 SET ECHO OFF
 SET TAB OFF
 SET FEEDBACK OFF
 SET TERM ON

 PROMPT Creating Package Body XX_AR_SALES_TAX_AMT_PKG
 PROMPT Program exits if the creation is not successful
 WHENEVER SQLERROR CONTINUE

 CREATE OR REPLACE
 PACKAGE BODY XX_AR_SALES_TAX_AMT_PKG
 AS

 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name        : Extract Program for Sales and Tax Collected Amount  |
 -- |               for Non-Office supply items.                        |
 -- | Description :                                                     |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       31-DEC-2007  Hemalatha.S          Initial version        |
 -- |                       Wipro Technologies                          |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : NT_SALES_TAX_AMT                                    |
 -- | Description : Extracts the sales and tax collected on non-office  |
 -- |               supply items and copies on to a data file.          |
 -- |                                                                   |
 -- | Parameters  : x_error_buff, x_ret_code,p_state,p_store,p_company  |
 -- |              ,p_date_of_revenue_recog,p_gsc_code,p_file_path      |
 -- |              ,p_dest_file_path,p_file_extension                   |
 -- |                                                                   |
 -- | Returns     : Return Code                                         |
 -- |               Error Message                                       |
 -- +===================================================================+

   PROCEDURE NT_SALES_TAX_AMT(
                              x_error_buff             OUT      VARCHAR2
                             ,x_ret_code               OUT      NUMBER
                             ,p_state                  IN       hz_locations.state%TYPE
                             ,p_store                  IN       hr_locations.location_code%TYPE
                             ,p_legal_entity           IN       VARCHAR2
                             ,p_date_of_revenue_recog  IN       DATE
                             ,p_gsc_code               IN       mtl_system_items_b.attribute1%TYPE
                             ,p_delimiter              IN       VARCHAR2
                             ,p_file_path              IN       VARCHAR2
                             ,p_dest_file_path         IN       VARCHAR2
                             ,p_file_name              IN       VARCHAR2
                             ,p_file_extension         IN       VARCHAR2
                             )
   AS

   lc_timestamp         VARCHAR2(30);
   lc_file_name         VARCHAR2(100);
   lc_source_file_path  VARCHAR2(500);
   lc_source_file_name  VARCHAR2(1000);
   lc_dest_file_name    VARCHAR2(1000);
   lt_file              UTL_FILE.FILE_TYPE;
   ln_buffer            BINARY_INTEGER := 32767;
   ln_req_id            NUMBER(10);
   lc_tax_amount        ra_customer_trx_lines.extended_amount%TYPE;
   ar_sal_tax_rec_type  ar_sal_tax_rec;
   ln_req_id_ftp              NUMBER(10);


--------------------------------------Cursor to fetch the DATA-----------------------------------

   CURSOR c_sales_tax
   IS
   SELECT GSC_CODE
         ,INVENTORY_LOCATION
         ,CUSTOMER_SHIP_TO_STATE
         ,DATE_OF_REVENUE_RECOG
         ,SUM(GROSS_AMOUNT)      GROSS_SALES
         ,SUM(TAX_AMT)           TAX_AMOUNT
   FROM   (SELECT MSIB.attribute1                                       GSC_CODE
                 ,SUBSTR(HL.location_code,1,6)                          INVENTORY_LOCATION
                 ,HZLOC.state                                           CUSTOMER_SHIP_TO_STATE
                 ,TO_CHAR(RCTGL.gl_posted_date,'MM/RRRR')               DATE_OF_REVENUE_RECOG
                 ,NVL(RCTL.extended_amount, RCTL.gross_extended_amount) GROSS_AMOUNT
                 ,SUM(NVL(RCTL2.extended_amount,0))                     TAX_AMT
                 ,RCTL.customer_trx_line_id                             LINE_ID
           FROM   ra_customer_trx                RCT
                 ,ra_customer_trx_lines          RCTL 
                 ,ra_customer_trx_lines          RCTL2
                 ,hz_cust_accounts               HCA
                 ,hz_parties                     HP
                 ,hz_cust_site_uses              HCS
                 ,hz_cust_acct_sites             HCAS
                 ,hz_party_sites                 HPS
                 ,hr_organization_units          HOU
                 ,xx_fin_translatevalues         XFTV
                 ,xx_fin_translatedefinition     XFTD
                 ,mtl_category_sets              MCSB
                 ,mtl_categories                 MC
                 ,mtl_item_categories            MIC
                 ,mtl_system_items_tl            MSIBTL
                 ,mtl_parameters                 MTP
                 ,gl_code_combinations           GCC
                 ,ra_cust_trx_line_gl_dist       RCTGL
                 ,hz_locations                   HZLOC
                 ,hr_locations                   HL
                 ,mtl_system_items_b             MSIB
           WHERE  RCT.ship_to_customer_id      = HCA.cust_account_id
           AND    HCA.party_id                 = HP.party_id
           AND    RCT.ship_to_site_use_id      = HCS.site_use_id
           AND    HCS.cust_acct_site_id        = HCAS.cust_acct_site_id 
           AND    HCAS.party_site_id           = HPS.party_site_id
           AND    HPS.location_id              = HZLOC.location_id
           AND    RCTL.warehouse_id            = HOU.organization_id
           AND    HOU.location_id              = HL.location_id
           AND    RCT.customer_trx_id          = RCTL.customer_trx_id
           AND    RCTL.customer_trx_line_id    = RCTGL.customer_trx_line_id
           AND    RCTL.warehouse_id            = MTP.organization_id
           AND    RCTL.inventory_item_id       = MSIB.inventory_item_id
           AND    MSIB.attribute1              = XFTV.source_value1
           AND    XFTD.translate_id            = XFTV.translate_id
           AND    XFTD.translation_name        = 'TWE_NON_OFFICE_SUPPLIES'
           AND    MTP.organization_id          = MSIB.organization_id
           AND    MSIB.organization_id         = MSIBTL.organization_id
           AND    MSIB.inventory_item_id       = MSIBTL.inventory_item_id
           AND    MSIBTL.LANGUAGE              = USERENV('LANG')
           AND    MIC.inventory_item_id        = MSIBTL.inventory_item_id
           AND    MIC.organization_id          = MSIBTL.organization_id
           AND    MIC.category_id              = MC.category_id
           AND    MIC.category_set_id          = MCSB.category_set_id
           AND    MCSB.category_set_name       = 'Inventory'
           AND    RCTGL.code_combination_id    = GCC.code_combination_id 
           AND    RCT.complete_flag            = 'Y'
           AND    RCTL.customer_trx_line_id    = RCTL2.link_to_cust_trx_line_id(+)
           AND    MSIB.attribute1              = NVL(p_gsc_code,MSIB.attribute1)
           AND   (p_date_of_revenue_recog IS NULL OR TO_CHAR(RCTGL.gl_posted_date,'DD-MON-YYYY')
                                          = TO_CHAR(p_date_of_revenue_recog,'DD-MON-YYYY'))
           AND    SUBSTR(HL.location_code,1,6) = NVL(p_store,SUBSTR(HL.location_code,1,6))
           AND    HZLOC.state                  = NVL(p_state,HZLOC.state)
           AND    GCC.segment1                 = NVL(p_legal_entity,GCC.segment1)
           GROUP BY MSIB.attribute1
                   ,SUBSTR(HL.location_code,1,6)
                   ,HZLOC.state
                   ,RCTGL.gl_posted_date
                   ,NVL(RCTL.extended_amount, RCTL.gross_extended_amount)
                   ,RCTL.customer_trx_line_id
          )
   GROUP BY GSC_CODE
           ,INVENTORY_LOCATION
           ,CUSTOMER_SHIP_TO_STATE
           ,DATE_OF_REVENUE_RECOG;

   BEGIN

--------------------------------------------Fetching Timestamp for File Name--------------------------------------

      SELECT TO_CHAR(SYSDATE,'DDMONYYYYHHMMSS')
      INTO   lc_timestamp
      FROM   dual;

-----------------------------------------Fetching the Directory Path from the table-------------------------------
      BEGIN

         SELECT directory_path
         INTO   lc_source_file_path
         FROM   dba_directories
         WHERE  directory_name = p_file_path;

      EXCEPTION
       WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while fetching the Directory Path. '
                                            || SQLERRM);

      END;

      lc_file_name := p_file_name || lc_timestamp || '.' || p_file_extension;

      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The AR Sales and Tax details Extract File Name : ' || lc_file_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The Created File Path               : ' || p_file_path);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'The Destination File Path           : ' || p_dest_file_path);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'*************************************************************');

----------------------------------Opening the File-----------------------------------------------

      BEGIN
         lt_file := UTL_FILE.fopen(p_file_path, lc_file_name,'w',ln_buffer);
      EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while Opening the file. '|| SQLERRM);
      END;

--------------------------------------Column Headings----------------------------------------------

      UTL_FILE.PUT_LINE(
                          lt_file,'GSC Code '
                       || p_delimiter  || 'Inventory Location'
                       || p_delimiter  || 'Customer Ship To State'
                       || p_delimiter  || 'Date of Revenue Recog'
                       || p_delimiter  || 'Gross Sales'
                       || p_delimiter  || 'Tax Amount'
                       );

-------------------------------------Open Cursor---------------------------------------------------

      BEGIN

         FOR lcu_ar_sal_tax_rec IN c_sales_tax
         LOOP

            ar_sal_tax_rec_type.lr_gsc_code               := lcu_ar_sal_tax_rec.GSC_CODE;
            ar_sal_tax_rec_type.lr_inventory_location     := lcu_ar_sal_tax_rec.INVENTORY_LOCATION;
            ar_sal_tax_rec_type.lr_customer_ship_to_state := lcu_ar_sal_tax_rec.CUSTOMER_SHIP_TO_STATE;
            ar_sal_tax_rec_type.lr_date_of_revenue_recog  := lcu_ar_sal_tax_rec.DATE_OF_REVENUE_RECOG;
            ar_sal_tax_rec_type.lr_gross_sales            := lcu_ar_sal_tax_rec.GROSS_SALES;
            ar_sal_tax_rec_type.lr_tax_amount             := lcu_ar_sal_tax_rec.TAX_AMOUNT;

----------------------------------Calling the procedure to write into the file----------------------

            AR_DATA_WRITE_FILE(ar_sal_tax_rec_type,lt_file,p_delimiter);

         END LOOP;

      EXCEPTION
         WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while getting into the loop'|| SQLERRM);

      END;

----------------------------------Closing the file-------------------------------------------------

      UTL_FILE.fclose(lt_file);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The Sales and tax details have been written into the file successfully.');


--------------- Call the Common file copy Program Copy to $XXFIN_DATA/ftp/out/tax audit hyperion--------------

      lc_source_file_name  := lc_source_file_path || '/' || lc_file_name;
      lc_dest_file_name    := p_dest_file_path   || '/' || lc_file_name;

/*      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
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
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The File was Copied into ' ||  p_dest_file_path
                                     || '. Request id : ' || ln_req_id);
*/
commit;
       ln_req_id_ftp := FND_REQUEST.SUBMIT_REQUEST(
                                               'xxfin'
                                               ,'XXCOMFTP'
                                               ,''
                                               ,''
                                               ,FALSE
                                               ,'OD_AP_TAX_AUDIT'                      --Process Name
                                               ,lc_file_name                      --source_file_name
                                               ,lc_file_name                      --destination_file_name
                                               ,'Y'                                    -- Delete source file?
                                               ,NULL
                                              );

       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'The FTP Put Program is submitted '
                                     || ' Request id : ' || ln_req_id_ftp);


   EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while getting the Timestamp. '|| SQLERRM);

   END NT_SALES_TAX_AMT;

 -- +===================================================================+
 -- | Name        : AR_DATA_WRITE_FILE                                  |
 -- |                                                                   |
 -- | Parameters  : ar_sal_tax_rec_type, lt_file,p_delimiter            |
 -- +===================================================================+

   PROCEDURE AR_DATA_WRITE_FILE(ar_sal_tax_rec_type          IN  ar_sal_tax_rec
                               ,lt_file                      IN  UTL_FILE.FILE_TYPE
                               ,p_delimiter                  IN  VARCHAR2
                               )
   AS

   BEGIN
----------------------------------Writing into the file--------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Writing into the file');
      BEGIN
         UTL_FILE.PUT_LINE(lt_file
                            , ar_sal_tax_rec_type.lr_gsc_code
                           || p_delimiter   || ar_sal_tax_rec_type.lr_inventory_location     ||CHR(9)
                           || p_delimiter   || ar_sal_tax_rec_type.lr_customer_ship_to_state ||CHR(9)
                           || p_delimiter   || ar_sal_tax_rec_type.lr_date_of_revenue_recog  ||CHR(9)
                           || p_delimiter   || ar_sal_tax_rec_type.lr_gross_sales            ||CHR(9)
                           || p_delimiter   || ar_sal_tax_rec_type.lr_tax_amount             ||CHR(9)
                          );
       EXCEPTION
       WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Exception raised while writing into Text file'|| SQLERRM);
       END;

  END AR_DATA_WRITE_FILE;

END XX_AR_SALES_TAX_AMT_PKG;
/
SHOW ERROR;
