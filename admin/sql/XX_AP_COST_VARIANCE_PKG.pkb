create or replace 
PACKAGE BODY      XX_AP_COST_VARIANCE_PKG
IS
-- +=====================================================================================================+
-- |                              Office Depot                                                           |
-- +=====================================================================================================+
-- | Name        :  XX_AP_COST_VARIANCE_PKG                                                              |
-- |                                                                                                     |
-- | Description :  This Package is to get all the new invoice lines which are having price variance and |
-- |                insert into the custom table                                                         |
-- | Rice ID     :  E3523                                                                                |
-- |Change Record:                                                                                       |
-- |===============                                                                                      |
-- |Version   Date         Author           Remarks                                                      |
-- |=======   ==========   =============    ======================                                       |
-- | 1.0      11-Jul-2017  Havish Kasina    Initial Version                                              |
-- | 1.1      11-OCT-2017  Uday Jadhav      Modified for concurrent program call                         |
-- | 1.2      23-Jan-2018  Paddy Sanjeevi   Modified to get the vendor product num                       |
-- | 1.3      25-Jan-2018  Naveen Patha     Answer date modified as trunc(Answer_date)                   |
-- | 1.4      18-Apr-2018  Ragni Gupta      Modified xx_cost_variance procedure for defect # NAIT-37786  |
-- | 1.5      29-Oct-2018  Jitendra Atale   Modified fetch_data procedure for defect # NAIT-25721        |
-- +=====================================================================================================+
g_proc              VARCHAR2(80)    := NULL;
g_debug             VARCHAR2(1)     := 'N';
gc_success          VARCHAR2(100)   := 'SUCCESS';
gc_failure          VARCHAR2(100)   := 'FAILURE';

-- +======================================================================+
-- | Name             : log_debug_msg                                     |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version               |
-- +======================================================================+

PROCEDURE log_debug_msg ( p_debug_msg          IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.LOGIN_ID;
 ln_user_id           FND_USER.USER_ID%TYPE            := FND_GLOBAL.USER_ID;
 lc_user_name         FND_USER.USER_NAME%TYPE          := FND_GLOBAL.USER_NAME;

BEGIN
  
  IF (g_debug = 'Y') THEN
    XX_COM_ERROR_LOG_PUB.log_error
      (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXFIN'
        ,p_program_type            => 'LOG'             
        ,p_attribute15             => 'XX_AP_COST_VARIANCE_PKG'      
        ,p_attribute16             => g_proc
        ,p_program_id              => 0                    
        ,p_module_name             => 'AP'      
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
    FND_FILE.PUT_LINE(FND_FILE.log, p_debug_msg);
  END IF;
END log_debug_msg;
-- +======================================================================+
-- | Name             : log_error                                         |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      07-Jul-2017  Havish Kasina    Initial Version               |
-- +======================================================================+

PROCEDURE log_error ( p_error_msg  IN  VARCHAR2 )
IS
 ln_login             FND_USER.LAST_UPDATE_LOGIN%TYPE  := FND_GLOBAL.LOGIN_ID;
 ln_user_id           FND_USER.USER_ID%TYPE  := FND_GLOBAL.USER_ID;
 lc_user_name         FND_USER.USER_NAME%TYPE  := FND_GLOBAL.USER_NAME;
 
BEGIN
  
  XX_COM_ERROR_LOG_PUB.log_error
      (
       p_return_code             => FND_API.G_RET_STS_SUCCESS
      ,p_msg_count               => 1
      ,p_application_name        => 'XXFIN'
      ,p_program_type            => 'ERROR'             
      ,p_attribute15             => 'XX_AP_COST_VARIANCE_PKG'      
      ,p_attribute16             => g_proc
      ,p_program_id              => 0                    
      ,p_module_name             => 'AP'      
      ,p_error_message           => p_error_msg
      ,p_error_message_severity  => 'MAJOR'
      ,p_error_status            => 'ACTIVE'
      ,p_created_by              => ln_user_id
      ,p_last_updated_by         => ln_user_id
      ,p_last_update_login       => ln_login
      );
  FND_FILE.PUT_LINE(FND_FILE.LOG, p_error_msg);    

END log_error;

-- +=====================================================================+
-- | Name  : update_stg_table                                            |
-- | Description     : The update stg table updates the records into     |
-- |                   xx_ap_cost_variance from xx_ap_cost_var_stg       |
-- | Parameters      : p_answer_code                                     |
-- |                   p_answer_date                                     |
-- |                   p_system_update_date                              |
-- |                   p_cost_effective_date                             |
-- |                   p_memo_comments                                   |
-- |                   p_pay_other_cost                                  |                       
-- +=====================================================================+

PROCEDURE update_stg_table(  p_answer_code           IN   VARCHAR2,  
                             p_answer_date           IN   DATE,
                             p_system_update_date    IN   DATE,
                             p_cost_effective_date   IN   DATE,
                             p_memo_comments         IN   VARCHAR2,   
                             p_pay_other_cost        IN   NUMBER,
                             p_sku                   IN   VARCHAR2,
                             p_po_line_id            IN   NUMBER,
                             x_return_status         OUT  VARCHAR2
                          )                             
AS
BEGIN   
    x_return_status := null;
    
    UPDATE xx_ap_cost_variance
       SET answer_code = p_answer_code,
           answer_date = p_answer_date,
           system_update_date = p_system_update_date,
           cost_effective_date = p_cost_effective_date,
           memo_comments = p_memo_comments,
           pay_other_cost = p_pay_other_cost
     WHERE 1 = 1 
       AND sku = p_sku
       AND po_line_id = p_po_line_id;
    fnd_file.put_line(fnd_file.log , SQL%ROWCOUNT ||' Row(s) updated in xx_ap_cost_variance for the PO Line ID :'||p_po_line_id||' and SKU :'||p_sku);
    COMMIT;
    x_return_status := gc_success;
EXCEPTION
    WHEN OTHERS
    THEN
      x_return_status := gc_failure;
      fnd_file.put_line(fnd_file.log ,'Error while updating into Staging table xx_ap_cost_variance '||substr(sqlerrm,1,100));
END update_stg_table;

  -- +===================================================================+
  -- | Name  : fetch_data                                                |
  -- | Description     : The fetch_data procedure will fetch data from   |
  -- |                   WEBADI to XX_AP_COST_VAR_STG table              |
  -- |                                                                   |
  -- | Parameters      : p_sku                                             |
  -- |                   p_sku_description                               |
  -- |                   p_vendor_no                                     |
  -- |                   p_vendor_name                                   |
  -- |                   p_po_cost                                          |
  -- |                   p_invoice_price                                 |
  -- |                   p_invoice_num                                   |
  -- |                   p_po_num                                        |
  -- |                   p_po_date                                       |
  -- |                   p_po_line_number                                |
  -- |                   p_answer_code                                   |
  -- |                   p_memo_comments                                 |
  -- |                   p_cost_effective_date                           |
  -- |                   p_pay_other_cost                                |
  -- +===================================================================+                                   
PROCEDURE fetch_data(p_sku                        IN  VARCHAR2,
                     p_sku_description           IN  VARCHAR2,
                     p_vendor_no                  IN  VARCHAR2,
                     p_vendor_name                 IN  VARCHAR2,
                     p_po_cost                     IN  NUMBER,
                     p_invoice_price            IN  NUMBER,
                     p_invoice_num              IN  VARCHAR2,
                     p_po_num                   IN  VARCHAR2,
                     p_po_date                  IN  DATE,
                     p_po_line_number           IN  NUMBER,
                     p_answer_code              IN  VARCHAR2,
                     p_memo_comments            IN  VARCHAR2,
                     p_cost_effective_date      IN  DATE,
                     p_pay_other_cost           IN  NUMBER
                    ) 
IS
  ln_inv_count NUMBER :=0;
  lv_err_msg   VARCHAR2(1000);
BEGIN 
  g_proc :='FETCH_DATA';
  SELECT COUNT(1)
  INTO ln_inv_count
  FROM ap_invoices_all aia
  WHERE aia.INVOICE_NUM = p_invoice_num
  AND 'APPROVED'        = ap_invoices_pkg.get_approval_status(aia.invoice_id, aia.invoice_amount, aia.payment_status_flag, aia.invoice_type_lookup_code ) ;
  IF ln_inv_count      != 0 THEN
    lv_err_msg         := 'Invoice was validated, Answer cannot be updated. Please contact VA';
    fnd_message.set_name('BNE','Validation_ERROR');
    fnd_message.set_token('Validation_ERROR',lv_err_msg);
  ELSE
   INSERT INTO XX_AP_COST_VAR_STG(sku,                 
                                  sku_description,   
                                  vendor_no ,         
                                  vendor_name ,      
                                  po_cost,               
                                  invoice_price,     
                                  invoice_num ,       
                                  po_num,             
                                  po_date,            
                                  po_line_number ,        
                                  answer_code,        
                                  memo_comments ,     
                                  cost_effective_date,
                                  pay_other_cost,     
                                  answer_date,
                                  system_update_date,
                                  process_flag, 
                                  creation_date,          
                                  created_by,        
                                  last_update_date,          
                                  last_updated_by
                                 )
                          VALUES (p_sku,                 
                                  p_sku_description,   
                                  p_vendor_no,          
                                  p_vendor_name,        
                                  p_po_cost,               
                                  p_invoice_price,      
                                  p_invoice_num,        
                                  p_po_num,             
                                  p_po_date,            
                                  p_po_line_number,         
                                  p_answer_code,        
                                  p_memo_comments,      
                                  p_cost_effective_date,
                                  p_pay_other_cost,
                                  TRUNC(SYSDATE),
                                  SYSDATE,
                                  'N',
                                  SYSDATE,
                                  fnd_global.user_id,
                                  SYSDATE,
                                  fnd_global.user_id
                                  );
   COMMIT;
   END IF;   
EXCEPTION 
WHEN OTHERS 
THEN        
    log_error('Error Inserting Data into XX_AP_COST_VAR_STG '||SUBSTR(SQLERRM,1,50));
    Raise_Application_Error (-20343, 'Error inserting the data..'||SQLERRM);
END fetch_data ;

  -- +===================================================================+
  -- | Name  : extract                                                   |
  -- | Description     : The extract procedure is the main               |
  -- |                   procedure that will extract all the unprocessed |
  -- |                   records from XX_AP_COST_VAR_STG                 |
  -- | Parameters      : x_retcode           OUT                         |
  -- |                   x_errbuf            OUT                         |
  -- +===================================================================+                     
PROCEDURE extract(x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER) 
IS
CURSOR cur_extract(p_process_flag  IN VARCHAR2,
                     p_user_id     IN NUMBER) 
IS 
SELECT *
  FROM xx_ap_cost_var_stg
 WHERE 1 =1
   AND process_flag     = NVL(p_process_flag,process_flag)
   AND created_by       = p_user_id
   AND creation_date    >= sysdate -1 ; 
   --------------------------------
   -- Local Variable Declaration --
   -------------------------------- 
  lc_err_flag           VARCHAR2(1);
  ln_user_id            fnd_user.user_id%TYPE;
  lc_user_name          fnd_user.user_name%TYPE;
  lc_debug_flag         VARCHAR2(1) := NULL;
  lc_upd_ret_status     VARCHAR2(20);
  ln_po_line_id         NUMBER;

BEGIN
    g_proc :='EXTRACT';
    x_retcode :=0;
    lc_upd_ret_status := null;
    ln_user_id := NULL;
    lc_user_name := NULL;
    
    lc_debug_flag := 'Y';

    IF (lc_debug_flag = 'Y') THEN
         g_debug := 'Y';
    ELSE
         g_debug := 'N';
    END IF; 
    
    ln_user_id := fnd_global.user_id;
    
    SELECT user_name
      INTO lc_user_name
      FROM fnd_user
     WHERE user_id = ln_user_id;

    FND_FILE.PUT_LINE(FND_FILE.LOG ,'User Name :'|| lc_user_name);

    FOR rec IN cur_extract(p_process_flag  => 'N',
                           p_user_id       => ln_user_id) 
    LOOP

    lc_upd_ret_status := NULL;
    lc_err_flag       := 'N';
    
    -- To get the PO Line id
    
    IF rec.po_line_number IS NULL
    THEN
        BEGIN
          ln_po_line_id := NULL;
          SELECT pla.po_line_id
            INTO ln_po_line_id
            FROM po_headers_all pha,
                 po_lines_all pla,
                 ap_supplier_sites_all assa,
                 mtl_system_items_b msi,
                 hr_locations hl
            WHERE 1 =1
            AND msi.segment1 = rec.sku
            AND TRUNC(pha.creation_date) =  TRUNC(rec.po_date)   
            AND LPAD(NVL(assa.attribute9,NVL(assa.vendor_site_code_alt,assa.vendor_site_id)),10,'0') = LPAD(rec.vendor_no,10,'0')
            AND msi.organization_id = hl.inventory_organization_id
            AND pha.ship_to_location_id = hl.location_id
            AND msi.inventory_item_id = pla.item_id
            AND assa.vendor_id   =  pha.vendor_id
            AND pha.po_header_id =  pla.po_header_id;
            
        FND_FILE.PUT_LINE(FND_FILE.LOG ,'PO Line ID :'||ln_po_line_id ||' for the SKU :'||rec.sku||', PO Date :'||TRUNC(rec.po_date)||' and Vendor Number :'||TO_NUMBER(rec.vendor_no));
        
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG ,'No PO Line ID for the SKU :'||rec.sku||', PO Date :'||TRUNC(rec.po_date)||' and Vendor Number :'||TO_NUMBER(rec.vendor_no)); 
           WHEN OTHERS
           THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG ,'Unable to get the PO Line ID for the SKU :'||rec.sku||', PO Date :'||TRUNC(rec.po_date)||' and Vendor Number :'||TO_NUMBER(rec.vendor_no));    
        END;
    ELSE
       BEGIN
         ln_po_line_id := NULL;
         SELECT pla.po_line_id
           INTO ln_po_line_id
            FROM po_headers_all pha,
                 po_lines_all pla
           WHERE pha.po_header_id =  pla.po_header_id
             AND pha.segment1 = rec.po_num
             AND pla.line_num = rec.po_line_number;
       EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG ,'No PO Line ID for the PO Number :'||rec.po_num||'and the PO Line Number: '||rec.po_line_number); 
           WHEN OTHERS
           THEN
             FND_FILE.PUT_LINE(FND_FILE.LOG ,'Unable to get the PO Line ID for the PO Number :'||rec.po_num||'and the PO Line Number: '||rec.po_line_number);     
        END;    
    END IF;
    
    FND_FILE.PUT_LINE(FND_FILE.LOG ,'Updating staging Table for Success ');
    update_stg_table(  p_answer_code           =>  rec.answer_code,
                       p_answer_date           =>  rec.answer_date,
                       p_system_update_date    =>  rec.system_update_date,
                       p_cost_effective_date   =>  rec.cost_effective_date,
                       p_memo_comments         =>  rec.memo_comments,
                       p_pay_other_cost        =>  rec.pay_other_cost,
                       p_sku                   =>  rec.sku,
                       p_po_line_id            =>  ln_po_line_id,
                       x_return_status         =>  lc_upd_ret_status
                    );                            
                    
    IF  lc_upd_ret_status = gc_success
    THEN
       IF rec.po_line_NUMBER IS NULL
       THEN
           UPDATE xx_ap_cost_var_stg
              SET process_flag  = 'Y'
            WHERE created_by = ln_user_id
              AND process_flag  = 'N'
              AND po_date = TRUNC(rec.po_date)
              AND LPAD(vendor_no,10,'0') = LPAD(rec.vendor_no,10,'0')
              AND sku = rec.sku;
       ELSE 
           UPDATE xx_ap_cost_var_stg
              SET process_flag  = 'Y'
            WHERE created_by = ln_user_id
              AND process_flag  = 'N'
              AND sku = rec.sku
              AND po_line_number = rec.po_line_number;
       END IF;
              
           FND_FILE.PUT_LINE(FND_FILE.LOG ,SQL%ROWCOUNT||' records Updated for user : '|| ln_user_id|| ', PO Number :'|| rec.po_num||' and SKU :'||rec.sku);
    END IF;
    
    COMMIT;
    END LOOP; 

EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Cost Variance answers creation - Process Ended in Error....'||SQLERRM);
      x_retcode := 2;
END extract;

PROCEDURE Submit_cost_var_report is
  ln_request_id             NUMBER:= NULL;
  lb_complete               BOOLEAN := NULL;
  lc_phase                  VARCHAR2 (100):= NULL;
  lc_status                 VARCHAR2 (100):= NULL;
  lc_dev_phase              VARCHAR2 (100):= NULL;
  lc_dev_status             VARCHAR2 (100):= NULL;
  lc_message                VARCHAR2 (100):= NULL;
  ln_request                NUMBER:= NULL;
 
  lb_layout                 BOOLEAN:= NULL;

 
BEGIN
    lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXAPCOSVAR',
                 'en',
                 'US',
                 'EXCEL');
            IF lb_layout THEN
                 FND_FILE.PUT_LINE (FND_FILE.LOG, 'successfully added the layout:');
            ELSE
                 FND_FILE.PUT_LINE (FND_FILE.LOG, 'unsuccessfully added the layout:');
            END IF;
            
      BEGIN
           ln_request_id :=
                         fnd_request.submit_request (
                            application   => 'XXFIN',     -- Application short name
                            program       => 'XXAPCOSVAR', --- conc program short name
                            description   => NULL,
                            start_time    => SYSDATE,
                            sub_request   => NULL
                            );    
              FND_FILE.PUT_LINE (FND_FILE.LOG, 'ln_request_id: '||ln_request_id);
      EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE (FND_FILE.LOG, 'Error ln_request_id: '||ln_request_id);
      END;        
       
       IF ln_request_id > 0
        THEN   
            commit;
            fnd_file.put_line (fnd_file.LOG, 'While Waiting Report Request to Finish');
            
            lb_complete :=fnd_concurrent.wait_for_request (
                     request_id   => ln_request_id,
                     interval     => 1, --interval Number of seconds to wait between checks
                     max_wait     => 0, --Maximum number of seconds to wait for the request completion
                     phase        => lc_phase,
                     status       => lc_status,
                     dev_phase    => lc_dev_phase,
                     dev_status   => lc_dev_status,
                     message      => lc_message); 
            
            BEGIN                 
              ln_request :=fnd_request.submit_request('XDO',
                                                      'XDOBURSTREP',
                                                      NULL,
                                                      NULL,
                                                      FALSE,
                                                      'N',
                                                      ln_request_id,
                                                      'Yes'
                                                      ); 
            COMMIT;                
            EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log, 'OTHERS exception while submitting the Bursting Program: ' || SQLERRM);
            END;
      END IF;   
      
EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error submitting the Cost Variance Report....'||SQLERRM);
END Submit_cost_var_report; 

PROCEDURE xx_cost_variance(
                  x_errbuf          OUT NOCOPY     VARCHAR2,
                  x_retcode         OUT NOCOPY     NUMBER) IS
CURSOR c1 
IS
select org_id,invoice_id,invoice_num,invoice_date,line_number,po_header_id,po_number,po_date,po_type,
       po_line_id,line_num,attribute3,location,vendor_id,vendor_site_id,vendor_no,vendor_name,site,
       sku,sku_description,dept,dept_name,quantity,po_price,invoice_price,variance_amt,
       vend_asst_code,vendor_assistant,inv_status,vendor_product_num
FROM (
SELECT a.vendor_name,ai.invoice_id,ai.org_id,
        b.attribute6 vend_asst_code,
         (SELECT tv.target_value2 
            FROM xx_fin_translatevalues tv,                                                   
                 xx_fin_translatedefinition td   
           WHERE td.translation_name = 'XX_AP_VENDOR_ASSISTANTS'                                                    
             AND tv.translate_id  = td.translate_id                                                   
             AND tv.target_value1 = b.attribute6||''                                                   
             AND tv.enabled_flag = 'Y'                                                   
             AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)) vendor_assistant,
       a.segment1 vendor_no,
       b.vendor_site_code site,
       ai.invoice_num,
       ai.invoice_date, 
       il.line_number,
       il.attribute3,
       ph.segment1 po_number,
       ph.creation_date po_date,
       ph.attribute_category po_type,
       ltrim(SUBSTR(hrl.location_code,1,6),'0') location,
       pl.line_num,pl.po_line_id,pl.quantity,pl.unit_price po_price,il.unit_price invoice_price,
       pl.vendor_product_num,
       (il.unit_price-pl.unit_price) variance_amt,
       msi.segment1 sku,msi.description sku_description,ffv.flex_value||'-'||ffv.description dept_name,
       ph.po_header_id,ai.vendor_id,ai.vendor_site_id,ffv.flex_value dept,
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          ) inv_status       
  FROM  
        fnd_flex_values_vl ffv
       ,fnd_flex_value_sets ff 
       ,mtl_categories_b mcat
       ,mtl_system_items_b msi
       ,po_lines_all pl
       ,hr_locations_all hrl  
       ,po_headers_all ph
       ,ap_supplier_sites_all b
       ,ap_suppliers a
       ,ap_invoice_lines_all il       
       ,ap_invoices_all ai
 WHERE ai.creation_date  BETWEEN to_date(to_char(sysdate)||' 00:00:00','DD-MON-RR HH24:MI:SS') 
                             AND to_date(to_char(sysdate)||' 23:59:59','DD-MON-RR HH24:MI:SS')
   AND il.invoice_id=ai.invoice_id
   AND il.line_type_lookup_code='ITEM'
   AND a.vendor_id=ai.vendor_id
   AND b.vendor_id=a.vendor_id
   AND b.vendor_site_id=ai.vendor_site_id
   AND ph.po_header_id=NVL(ai.po_header_id,ai.quick_po_header_id)  
   AND hrl.location_id = ph.ship_to_location_id  
   AND (pl.unit_price-il.unit_price)<>0    
   --Changes started for defect # NAIT-37786: Modified below conditions, by Ragni Gupta on 04-May-2018
   AND pl.quantity >= 1
   --Changes ended for defect # NAIT-37786: Modified above conditions, by Ragni Gupta on 04-May-2018   
   AND pl.po_header_id=ph.po_header_id
   AND pl.line_type_id=1
   AND pl.po_line_id=il.po_line_id
   AND msi.inventory_item_id=pl.item_id
   AND msi.organization_id+0=441
   AND mcat.category_id=pl.category_id
   AND ff.flex_value_set_name='XX_GI_DEPARTMENT_VS'
   AND ffv.flex_value_set_id=ff.flex_value_set_id
   AND ffv.flex_value=mcat.segment3
   AND ai.source NOT IN ('US_OD_DCI_TRADE','UD_OD_TDM')
   AND ai.invoice_num not like '%ODDBUIA%'
   AND EXISTS (SELECT 'x'
                 FROM  xx_fin_translatevalues tv
                      ,xx_fin_translatedefinition td
                WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'
                  AND tv.TRANSLATE_ID  = td.TRANSLATE_ID
                  AND tv.enabled_flag='Y'
                  AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)
                  AND tv.target_value1=ai.source
              )      
   AND NOT EXISTS (SELECT 'X'
                     FROM xx_ap_cost_variance
                    WHERE po_line_id=pl.po_line_id
                    and inv_line_num=il.line_number
                    and invoice_num=ai.invoice_num
                   )      
UNION
SELECT a.vendor_name,ai.invoice_id,ai.org_id,
        b.attribute6 vend_asst_code,
         (SELECT tv.target_value2 
            FROM xx_fin_translatevalues tv,                                                   
                 xx_fin_translatedefinition td   
           WHERE td.translation_name = 'XX_AP_VENDOR_ASSISTANTS'                                                    
             AND tv.translate_id  = td.translate_id                                                   
             AND tv.target_value1 = b.attribute6||''                                                   
             AND tv.enabled_flag = 'Y'                                                   
             AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)) vendor_assistant,
       a.segment1 vendor_no,
       b.vendor_site_code site,
       ai.invoice_num,
       ai.invoice_date, 
       il.line_number,
       il.attribute3,
       ph.segment1 po_number,
       ph.creation_date po_date,
       ph.attribute_category po_type,
       ltrim(SUBSTR(hrl.location_code,1,6),'0') location,
       pl.line_num,pl.po_line_id,pl.quantity,pl.unit_price po_price,il.unit_price invoice_price,
       pl.vendor_product_num,
       (il.unit_price-pl.unit_price) variance_amt,
       msi.segment1 sku,msi.description sku_description,ffv.flex_value||'-'||ffv.description dept_name,
       ph.po_header_id,ai.vendor_id,ai.vendor_site_id,ffv.flex_value dept,
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          ) inv_status       
  FROM  
       fnd_flex_values_vl ffv
       ,fnd_flex_value_sets ff 
       ,mtl_categories_b mcat
       ,mtl_system_items_b msi
       ,po_lines_all pl
       ,hr_locations_all hrl  
       ,po_headers_all ph
       ,ap_supplier_sites_all b
       ,ap_suppliers a
         ,ap_invoice_lines_all il       
       ,ap_invoices_all ai
 WHERE 1=1
   AND il.invoice_id=ai.invoice_id
   AND il.line_type_lookup_code='ITEM'
   AND a.vendor_id=ai.vendor_id
   AND b.vendor_id=a.vendor_id
   AND b.vendor_site_id=ai.vendor_site_id
   AND ph.po_header_id=NVL(ai.po_header_id,ai.quick_po_header_id)  
   AND hrl.location_id = ph.ship_to_location_id   
   AND (pl.unit_price-il.unit_price)<>0 
  --Changes started for defect # NAIT-37786: Modified below conditions, by Ragni Gupta on 04-May-2018
     AND pl.quantity >= 1   
   --Changes ended for defect # NAIT-37786: Modified above conditions, by Ragni Gupta on 04-May-2018
   AND pl.po_header_id=ph.po_header_id
   AND pl.line_type_id=1
   AND pl.po_line_id=il.po_line_id
   AND msi.inventory_item_id=pl.item_id
   AND msi.organization_id+0=441
   AND mcat.category_id=pl.category_id
   AND ff.flex_value_set_name='XX_GI_DEPARTMENT_VS'
   AND ffv.flex_value_set_id=ff.flex_value_set_id
   AND ffv.flex_value=mcat.segment3
   AND ai.source IN ('US_OD_DCI_TRADE','UD_OD_TDM')
   AND ai.invoice_num not like '%ODDBUIA%'   
   AND il.last_update_date BETWEEN to_date(to_char(sysdate)||' 00:00:00','DD-MON-RR HH24:MI:SS') 
                            AND to_date(to_char(sysdate)||' 23:59:59','DD-MON-RR HH24:MI:SS')
   AND NOT EXISTS (SELECT 'X'
                     FROM xx_ap_cost_variance
                    WHERE po_line_id=pl.po_line_id
                    and inv_line_num=il.line_number
                    and invoice_num=ai.invoice_num
                   )         
)
WHERE 1=1 --inv_status IN ('NEEDS REAPPROVAL','APPROVED','CANCELLED')                                          
ORDER BY 3;              

v_answer_code         VARCHAR2(100):=NULL;
v_answer_date         DATE:=NULL;
v_Variance_pct         NUMBER:=NULL;
v_rec_cnt             NUMBER:=0;
BEGIN
  
  FOR x IN c1 LOOP
    IF x.invoice_price < x.po_price THEN
      v_Answer_code := 'FAV';
      v_answer_date := TRUNC(sysdate);
    ELSIF x.attribute3 ='Y' THEN
      v_Answer_code := 'CVR';
      v_answer_date := TRUNC(sysdate);
    ELSE
      v_Answer_code := null;
      v_answer_date := null;
    END IF;

    -- Added Exception
    BEGIN            
       v_Variance_pct:=round(((x.invoice_price-x.po_price)/x.po_price)*100,2);
    EXCEPTION
      WHEN others THEN
        v_variance_pct:=0;
    END;

    BEGIN
      INSERT 
        INTO xx_ap_cost_variance (org_id,invoice_id,invoice_num,invoice_date,inv_line_num,po_header_id,po_num,po_date,po_type,
         po_line_id,line_num,location,vendor_id,vendor_no,vendor_name,VENDOR_SITE_CODE,vendor_site_id,
         sku,sku_description,dept,dept_name,quantity,po_cost,invoice_price,variance_amt,
         VENDOR_ASST,VENDOR_ASST_NAME, CREATION_DATE, LAST_UPDATE_DATE, ANSWER_CODE, ANSWER_DATE, VARIANCE_PCT, merchant_name,vpc)
      VALUES (x.org_id,x.invoice_id, x.invoice_num, x.invoice_date, x.line_number,x.po_header_id, x.po_number, x.po_date, x.po_type,
         x.po_line_id,x.line_num,x.location,x.vendor_id,x.vendor_no,x.vendor_name,x.site,x.vendor_site_id,
         x.sku,x.sku_description,x.dept,x.dept_name,x.quantity,x.po_price,x.invoice_price,x.variance_amt,
         x.vend_asst_code,x.vendor_assistant, SYSDATE, SYSDATE, v_Answer_code, v_answer_date, v_Variance_pct, XX_AP_MERCH_CONT_PKG.merch_name(x.dept),
         x.vendor_product_num);
         
         FND_FILE.PUT_LINE(FND_FILE.LOG,' invoice_id : '||x.invoice_id);
         v_rec_cnt := v_rec_cnt+1;

    EXCEPTION
      WHEN OTHERS THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while inserting the Cost Variance Data....'||SQLERRM||' invoice_id : '||x.invoice_id);
    END;     
    COMMIT;
 END LOOP;
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Submitting the Cost Variance Report...');
 
 --IF v_rec_cnt>=1 THEN
    Submit_cost_var_report;
-- END IF;
 
EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error inserting the Cost Variance Data....'||SQLERRM);
END xx_cost_variance; 

END XX_AP_COST_VARIANCE_PKG; 
/
