SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_TWE_ISO_USETAX_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Internal Sales Order Usetax Report                  |
-- | RICE ID     : R0504                                               |
-- | Description : To populate the  xx_twe_iso_usetax_tmp temporary    |
-- |               table.                                              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author            Remarks                  |
-- |=======  ==========   ===============  =======================     |
-- | 1.0     09-Jan-09     Ganga Devi R     Initial version            |
-- | 1.1     12-JAN-09     Aravind A        Performance changes        |
-- | 1.2     10-Mar-09     Ganga Devi R     Added for the defect#13672 |
-- | 1.3     08-Apr-09     Subbu Pillai     Added for the Defect 13828 |
-- | 1.4    14-May-09      Aravind A        Added for the Defect 15183 |
-- | 1.5    29-JUL-09      Usha R           Added the tuned query for  |
-- |                                         defect #1617 
-- | 1.6    10-AUG-09      Usha R           Added for the defect #1302 |
-- |                                         R-1.02                    |
-- | 1.7    18-SEP-09      Rani Asaithambi  Added for the defect #2428 |
-- |                                        R1.1                       |
-- | 1.8  03-SEP-2010    Ritch Hartman     Defect 7765 - GL Archive    | 
-- |                                        APPS.* - schema name remove|
-- | 1.9   11-Jun-13	 Kiran Kumar R	  Included R12 Retrofit Changes|
-- | 1.10  31-Oct-17     Nagendra C       Included code for adding po  |
-- |                                      tax lines                    |
-- +===================================================================+

create or replace PACKAGE BODY XX_TWE_ISO_USETAX_PKG
AS

  gn_limit NUMBER:=40000;
  
     --/**************************************************************
  --* This function returns the current time
  --***************************************************************/
  FUNCTION time_now
          RETURN VARCHAR2
  IS
   lc_time_string VARCHAR2(40);
  BEGIN
    SELECT TO_CHAR(SYSDATE, 'DD-MON-RRRR HH24:MI:SS')
    INTO   lc_time_string
    FROM   DUAL;

    RETURN(lc_time_string);
  END time_now;
  
  -- +===============================================================================================+
  -- | Name  : log_msg                                                                               |
  -- | Description     : This procedure used to log the messages in concurrent program log           |
  -- |    pi_log_flag            IN -- Debug Flag                                                    |
  -- |    pi_string              IN -- Message as String                                             |
  -- +================================================================================================+
  PROCEDURE log_msg(
                    pi_log_flag IN BOOLEAN DEFAULT FALSE,
                    pi_string   IN VARCHAR2
                    )
  IS
  BEGIN
    IF (pi_log_flag)
    THEN
      fnd_file.put_line(fnd_file.LOG, time_now || ' : ' || pi_string);
      dbms_output.put_line(time_now || ' : ' || pi_string);
    END IF;
  END log_msg;
  
   -- +===============================================================================================+
    -- | Name  : get_translation_info                                                                  |
    -- | Description     : This function returns the transaltion info                                  |
    -- |                                                                                               |
    -- |                                                                    |
    -- | Parameters      :                                                  |
    -- +================================================================================================+

      FUNCTION get_translation_info(gl_translation_name   IN  xx_fin_translatedefinition.translation_name%TYPE,
                                    gl_source_record      IN  xx_fin_translatevalues.source_value1%TYPE,
                                    gl_translation_info   OUT xx_fin_translatevalues%ROWTYPE,
                                    gl_error_msg          OUT VARCHAR2)
      RETURN VARCHAR2
      IS
      BEGIN
        gl_error_msg        := NULL;
        gl_translation_info := NULL;
    
        SELECT xftv.*
        INTO gl_translation_info
        FROM xx_fin_translatedefinition xft,
             xx_fin_translatevalues xftv
        WHERE xft.translate_id    = xftv.translate_id
        AND xft.enabled_flag      = 'Y'
        AND xftv.enabled_flag     = 'Y'
        AND xft.translation_name  = gl_translation_name
        AND xftv.source_value1    = gl_source_record; --'CONFIG_DETAILS';
    
        RETURN 'Success';
       EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
           gl_error_msg := 'No Translation info found for '||gl_translation_name;
           log_msg(TRUE, gl_error_msg);
           RETURN 'Failure';
         WHEN OTHERS
         THEN
           gl_error_msg := 'Error while getting the trans info '|| substr(SQLERRM,1,2000);
           log_msg(TRUE, gl_error_msg);
           RETURN 'Failure';
      END get_translation_info; 
      
   -- +===============================================================================================+
    -- | Name  : XX_TWE_PO_USETAX_PRC                                                                  |
    -- | Description     : This procedure used to return the PO tax data                               |
    -- |                                                                                               |
    -- |                                                                    |
    -- | Parameters      :                                                  |
    -- +================================================================================================+      
          
  PROCEDURE XX_TWE_PO_USETAX_PRC( P_SOB_ID          IN NUMBER,
                                  P_PERIOD_NUM_FROM IN NUMBER,
                                  P_PERIOD_NUM_TO   IN NUMBER)
  IS
  
   TYPE l_po_ustax IS TABLE OF xx_twe_iso_usetax_tmp%ROWTYPE 
                                INDEX BY BINARY_INTEGER;
   
   lc_trans_name                xx_fin_translatedefinition.translation_name%TYPE := 'XXPO_TO_GL_TAX_CONFIG';
   lt_po_ustax                  l_po_ustax;
   l_rec_cnt                    NUMBER:=0;
   lc_return_status             VARCHAR2(300);
   lc_translation_info          xx_fin_translatevalues%ROWTYPE;
   lc_error_message             VARCHAR2(2000);
   e_process_exception          EXCEPTION;
    
    CURSOR c_gl_po_tax_jrnals(p_src_name IN VARCHAR2,
                              p_cat_name IN VARCHAR2)
    IS SELECT distinct glh.date_created transaction_date,
              gcc.segment1 company,
              gcc.concatenated_segments gl_account_number,
              glh.name gl_journal_name,
              glh.default_effective_date gl_accounting_date,
              Trim(Substr(gll.description,Instr(gll.description,'#',1)+1)) po_number
        FROM 
            gl_je_headers glh,
            gl_je_lines gll,
            gl_period_statuses gps,
            gl_je_sources gjs,
            gl_je_categories gjc,
            gl_code_combinations_kfv gcc
        WHERE glh.je_header_id              =  gll.Je_Header_Id     
              AND gps.ledger_id             =  P_SOB_ID                                                  
              AND gps.application_id        =  101
              AND gps.effective_period_num  BETWEEN p_period_num_from and p_period_num_to
              AND gjs.user_je_source_name   = p_src_name
              AND gjc.user_je_category_name = p_cat_name
              AND glh.ledger_id             = gps.ledger_id                                               
              AND glh.period_name           = gps.period_name
              AND gcc.code_combination_id   = gll.code_combination_id
              AND glh.je_source             = gjs.je_source_name 
              AND glh.je_category           = gjc.je_category_name;
        
      CURSOR c_po_tax_lines(
                            p_po_number IN VARCHAR2
                            )
      IS
         SELECT pla.line_num,
               SUM(zl.tax_amt) tax_amount,
               (pla.unit_price*pla.quantity) Line_Amount,
                pla.unit_price Item_Cost,
                mic.segment1 unspc_code,
                pla.item_description,
                hrl.region_2 ship_to_state,
                hrl.town_or_city ship_to_city,
                ood.organization_name ship_to_location,
                decode(hrl.country,'US',hrl.region_1,'CA',null,null) ship_to_county
         FROM   po_headers_all pha,
                po_lines_all pla,
                po_line_locations_all plla,
                po_distributions_all pda,
                hr_locations_all hrl,
                org_organization_definitions ood,
                mtl_categories mic,
                zx_lines zl
         WHERE  pha.po_header_id             =   pla.po_header_id
            AND pla.po_line_id               =   plla.po_line_id
            AND plla.line_location_id        =   pda.line_location_id
            AND plla.ship_to_location_id     =   hrl.location_id
            AND pla.category_id              =   mic.category_id
            AND pha.segment1                 =   p_po_number
            AND plla.ship_to_organization_id =   ood.organization_id
            AND zl.trx_id                    =   pha.po_header_id
            AND zl.trx_line_id               =   plla.line_location_id
			AND NVL(pla.cancel_flag,'XX')    <>  'Y'
            AND NVL(plla.cancel_flag,'XX')   <>  'Y'
            AND NVL(zl.cancel_flag,'XX')     <>  'Y'
            AND NVL(zl.tax_amt,0)             >   0
     GROUP BY pha.segment1,pla.line_num,(pla.unit_price*pla.quantity),pla.unit_price,
              mic.segment1,pla.item_description,pla.item_description,hrl.region_2,hrl.town_or_city,
              ood.organization_name,decode(hrl.country,'US',hrl.region_1,'CA',null,null); 

  BEGIN
    
     log_msg(true, 'Getting the Translation Values ..');   
  
     lc_return_status := get_translation_info(gl_translation_name => lc_trans_name,
                                              gl_source_record    => 'CONFIG_DETAILS',
                                              gl_translation_info => lc_translation_info,
                                              gl_error_msg        => lc_error_message);
    -- Validating the Error message     
     IF lc_error_message IS NOT NULL
     THEN
        RAISE e_process_exception ;
     END IF;                                               
     
     log_msg(true,'JE Source name:'||lc_translation_info.target_value3);
     
     log_msg(true,'JE Category name:'||lc_translation_info.target_value4);
     
     log_msg(true, 'Begining the po tax rec cursor ..');  
     
     FOR c_jrnl_rec IN c_gl_po_tax_jrnals(lc_translation_info.target_value3,
                                          lc_translation_info.target_value4)
     LOOP
        log_msg(true, 'Processing the PO:'||c_jrnl_rec.po_number);
        
          
          FOR c_po_rec IN c_po_tax_lines(c_jrnl_rec.po_number)
          LOOP
             BEGIN
                 l_rec_cnt:=l_rec_cnt+1;        
                 lt_po_ustax(l_rec_cnt).transaction_date    :=c_jrnl_rec.transaction_date;
                 lt_po_ustax(l_rec_cnt).company             :=c_jrnl_rec.company;
                 lt_po_ustax(l_rec_cnt).gl_account_number   :=c_jrnl_rec.gl_account_number;
                 lt_po_ustax(l_rec_cnt).gl_journal_name     :=c_jrnl_rec.gl_journal_name;
                 lt_po_ustax(l_rec_cnt).gl_accounting_date  :=c_jrnl_rec.gl_accounting_date;
                 lt_po_ustax(l_rec_cnt).order_number        :=TO_NUMBER(c_jrnl_rec.po_number);
                 lt_po_ustax(l_rec_cnt).line_number         :=c_po_rec.line_num;
                 lt_po_ustax(l_rec_cnt).tax_amount          :=c_po_rec.tax_amount;
                 lt_po_ustax(l_rec_cnt).line_amount         :=c_po_rec.Line_Amount;
                 lt_po_ustax(l_rec_cnt).item_cost           :=c_po_rec.Item_Cost;
                 lt_po_ustax(l_rec_cnt).unspc_code          :=c_po_rec.unspc_code;
                 lt_po_ustax(l_rec_cnt).item_description    :=c_po_rec.item_description;
                 lt_po_ustax(l_rec_cnt).ship_to_state       :=c_po_rec.ship_to_state;
                 lt_po_ustax(l_rec_cnt).ship_to_city        :=c_po_rec.ship_to_city;
                 lt_po_ustax(l_rec_cnt).ship_to_location    :=c_po_rec.ship_to_location;
                 lt_po_ustax(l_rec_cnt).ship_to_county      :=c_po_rec.ship_to_county;
             EXCEPTION
             WHEN OTHERS 
             THEN
               log_msg(true,'Exception:'||substr(sqlerrm,1,200)||' for the PO:'||c_jrnl_rec.po_number);
             END;  
          END LOOP;
          
     END LOOP;
     
     
     log_msg(true,'Number of records inserted into po tax table type is:'||l_rec_cnt);
     
     log_msg(true,'Bulk inserting the PO tax records');
     
     BEGIN
       -- Bulk inserting records into table  
         FORALL ctr in lt_po_ustax.first..lt_po_ustax.last
           INSERT INTO xx_twe_iso_usetax_tmp
           VALUES lt_po_ustax(ctr);        
     EXCEPTION
     WHEN OTHERS
     THEN
       log_msg(true,'Exception while doing bulk insert into table xx_twe_iso_usetax_tmp:'||substr(sqlerrm,1,200));
     END;
 EXCEPTION    
 WHEN e_process_exception 
 THEN
    log_msg(true, lc_error_message);  
 WHEN OTHERS 
 THEN
    log_msg(true,'Exception raised in xx_twe_po_usetax_prc:'||SUBSTR(SQLERRM,1,250));   
 END XX_TWE_PO_USETAX_PRC;
  
  PROCEDURE XX_TWE_ISO_USETAX_PRC(P_SOB_ID IN NUMBER,
  P_PERIOD_NUM_FROM IN NUMBER,
  P_PERIOD_NUM_TO IN NUMBER)
  IS
    TYPE l_iso_ustax IS TABLE OF xx_twe_iso_usetax_tmp%ROWTYPE;
    lt_iso_ustax  l_iso_ustax;
    CURSOR lcu_data IS
    --Added the tuned query for defect #1617
      SELECT
            glh.date_created transaction_date
           ,gcc.segment1 company
           ,nvl(ship_loc.state,   ship_loc.province) ship_to_state
           ,(ool.tax_value) tax_amount
           ,ooh.order_number
           ,ool.line_number Line_Number
           ,ool.unit_selling_price * ool.ordered_quantity     Line_Amount
           ,ool.unit_selling_price Item_Cost
           ,mic.segment1 UNSPC_Code
           ,prl.item_description
           ,gcc.concatenated_segments gl_account_number--Added for Defect 1302 R-1.02
           ,glh.name gl_journal_name--Added for Defect 1302 R-1.02
           ,glh.default_effective_date gl_accounting_date--Added for Defect 1302 R-1.02
           ,ship_loc.city ship_to_city--Added for Defect 1302 R-1.02
           ,ood.organization_name ship_to_location --Added for Defect 1302 R-1.02
       ,decode(ship_loc.country,'US',ship_loc.county,'CA',null,null) ship_to_county          --Added for Defect 2428 R-1.1


       FROM gl_period_statuses gps,
            gl_je_headers glh,
            oe_order_lines_all ool,
            po_req_distributions dist,
            po_requisition_lines prl,
            po_requisition_headers prh,
            oe_order_headers_all ooh, ---Added the ALL Table for the Defect 15183
            hz_cust_site_uses_all ship_csu,
            hz_cust_acct_sites_all ship_cas,
            hz_party_sites ship_ps,
            hz_locations ship_loc,
            gl_code_combinations_kfv gcc, --Added for Defect 1302 R-1.02
            mtl_categories mic,
            org_organization_definitions ood ----Added for Defect 1302 R-1.02


      WHERE 1 = 1
--    AND gps.set_of_books_id=P_SOB_ID                                               --commented by kiran on 11-JUN-2013 as per R12 Retrofit Change
      AND gps.ledger_id = P_SOB_ID                                                   --added by kiran on 11-JUN-2013 as per R12 Retrofit Change
      AND gps.application_id=101
      AND gps.effective_period_num between P_PERIOD_NUM_FROM and P_PERIOD_NUM_TO
--      and glh.set_of_books_id=gps.set_of_books_id                                  --commented by kiran on 11-JUN-2013 as per R12 Retrofit Change
      AND glh.ledger_id=gps.ledger_id                                                --added by kiran on 11-JUN-2013 as per R12 Retrofit Change
      AND glh.period_name = gps.period_name
      AND glh.je_category = '34'
      AND glh.external_reference = ool.attribute15
      AND ool.source_document_line_id = dist.requisition_line_id
      AND dist.requisition_line_id = prl.requisition_line_id
      AND prl.requisition_header_id=prh.requisition_header_id
      AND ool.header_id = ooh.header_id
      AND ooh.ORDER_SOURCE_ID=10
      and ooh.orig_sys_document_ref=prh.segment1
     --AND ooh.ship_to_org_id = ship_csu.site_use_id --- Commented for Defect 15183
     AND ool.ship_to_org_id = ship_csu.site_use_id --Added for the Defect 15183
     AND ship_csu.cust_acct_site_id = ship_cas.cust_acct_site_id
     AND ship_cas.party_site_id = ship_ps.party_site_id
     AND ship_ps.location_id = ship_loc.location_id
     AND dist.code_combination_id = gcc.code_combination_id
     AND prl.category_id = mic.category_id
     AND prl.destination_organization_id=ood.organization_id;  --Added for Defect 1302 R-1.02

  BEGIN
    OPEN lcu_data;
    LOOP
       FETCH lcu_data BULK COLLECT INTO lt_iso_ustax LIMIT gn_limit;
       FORALL ctr in lt_iso_ustax.first..lt_iso_ustax.last
       INSERT INTO xx_twe_iso_usetax_tmp
       VALUES lt_iso_ustax(ctr);
       EXIT WHEN lcu_data %NOTFOUND;
    END LOOP;
    CLOSE lcu_data;
	
	log_msg(true,'Calling the XX_TWE_PO_USETAX_PRC');
    
    -- Calling the XX_TWE_PO_USETAX_PRC
    XX_TWE_PO_USETAX_PRC( P_SOB_ID,
                          P_PERIOD_NUM_FROM,
                          P_PERIOD_NUM_TO);
	
  END XX_TWE_ISO_USETAX_PRC;
END XX_TWE_ISO_USETAX_PKG;

/
