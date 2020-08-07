SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY XX_AP_UI_VIEW_PKG

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY APPS.XX_AP_UI_VIEW_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_AP_UI_VIEW_PKG.pks                                    |
-- | Description :  Plsql package for UI Views                               |
-- | RICE ID     :  E3522_OD Trade Match Foundation                          |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       18-Oct-2017 Paddy Sanjeevi     Initial version                 |
-- |1.1       25-Oct-2017 Naveen Patha       Modified  source<>US_OD_DROPSHIP|
-- |1.2       14-Nov-2017 Naveen Patha       Added NVL for Attribute6        |
-- |1.3       03-Jan-2018 Paddy Sanjeevi     Added to restrict held invoices |
-- |1.4       01-Feb-2018 Paddy Sanjeevi     Added org_id parameter          |
-- |1.5       06-Feb-2018 Naveen Patha       Removed date condition          |
-- +=========================================================================+
AS

-- +======================================================================+
-- | Name        :  xx_empvnd_set                                         |
-- | Description :  To set package spec variables                         |
-- |                                                                      |
-- | Parameters  :  p_org_id,p_vendor_id,p_vendor_site_id,p_employee_no   |
-- |                                                                      |
-- | RETURNs     :                                                        |
-- |                                                                      |
-- +======================================================================+
PROCEDURE xx_empvnd_set(p_org IN NUMBER,p_vendor IN NUMBER, p_vendor_site IN NUMBER, p_employee IN VARCHAR2)
IS
BEGIN

  p_org_id:=p_org;
  p_vendor_id:=p_vendor;
  p_vendor_site_id:=p_vendor_site;
  p_employee_no:=p_employee;

END xx_empvnd_set;

FUNCTION get_org RETURN NUMBER
IS
BEGIN
  RETURN p_org_id;
END get_org;  

FUNCTION get_p_vendor RETURN NUMBER
IS
BEGIN
 RETURN p_vendor_id;
END get_p_vendor;

FUNCTION get_p_vendor_site RETURN NUMBER
IS
BEGIN
  RETURN p_vendor_site_id;
END get_p_vendor_site;

FUNCTION get_p_employee RETURN VARCHAR2
IS
BEGIN
  RETURN p_employee_no;
END get_p_employee;


-- +======================================================================+
-- | Name        :  xx_ap_ui_emp_summ_f                                   |
-- | Description :  To get Vendor Assistant Moot Summary data             |
-- |                                                                      |
-- | Parameters  :  None                                                  |
-- |                                                                      |
-- | RETURNs     :                                                        |
-- |                                                                      |
-- +======================================================================+
FUNCTION xx_ap_ui_emp_summ_f RETURN xx_ap_ui_emp_summ_t pipelined is
    type emp_sum_rec is record
    (
        vendor_assistant varchar2(100),
        employee_id                varchar2(20),
        total_inv_count            number,
        total_inv_amount        number,
        total_line_amount        number,
        total_moot_count        number,
        total_moot_inv_amount    number,
        total_moot_line_amount    number,
        total_nrf_count            number,
        total_nrf_amount        number
    );  
     l_emp_sum_rec emp_sum_rec;
  v_idslist         xx_ap_ui_empsumrec_type_t:=xx_ap_ui_empsumrec_type_t();
  type refcur is ref cursor;
  l_refcursor         refcur  ;     
  ln_org_id			 NUMBER;
  
CURSOR C1(p_org_id NUMBER) IS
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1) */           
          a.invoice_id,           
          a.terms_id,           
          a.vendor_id,           
          a.vendor_site_id,           
          a.org_id,           
          'TOTAL' hold_type,                    
          a.invoice_amount inv_amount,                    
          0 line_total ,                    
          1 inv_count,           
          b.attribute6           
    FROM  ap_supplier_sites_all b,           
          ap_invoices_all a ,                 
           (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */   
              distinct aph.invoice_id           
          FROM ap_holds_all aph           
         WHERE 1=1 --aph.creation_date > '01-JAN-11'            
           AND NVL(aph.status_flag,'S')= 'S'  
           AND aph.release_lookup_code is null  
        ) h           
   WHERE a.invoice_id=h.invoice_id           
     AND a.org_id+0=p_org_id
     AND a.invoice_num not like '%ODDBUIA%'      
     AND NVL(a.validation_request_id,1)<>-9999999999
     AND a.source<>'US_OD_DROPSHIP'                         
     --AND a.creation_date>'01-JAN-11'           
     AND b.vendor_site_id=a.vendor_site_id  
     AND exists (SELECT 'x'   
                   FROM xx_fin_translatevalues tv,                                                                    
                        xx_fin_translatedefinition td                    
                  WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                    AND tv.translate_id  = td.translate_id                                                                    
                    AND tv.enabled_flag = 'Y'                                                                    
                    AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                    AND tv.target_value1 = b.attribute8||''
                )      
     AND EXISTS (select 'x'                    
                   from ap_payment_schedules_all apsa                    
                  where apsa.invoice_id=a.invoice_id                    
                    AND NVL(apsa.discount_date,due_date) < SYSDATE+8           
                )             
     AND EXISTS (SELECT 'x'           
                   FROM xx_fin_translatevalues tv           
                       ,xx_fin_translatedefinition td           
                  WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'           
                    AND tv.TRANSLATE_ID  = td.TRANSLATE_ID           
                    AND tv.enabled_flag='Y'           
                    AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)           
                    AND tv.target_value1=a.source
                )             
  AND EXISTS (SELECT  'x'                                                          
                FROM mtl_system_items_b msi,                                                          
                     po_lines_all pl                                                          
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                          
                 AND msi.inventory_item_id = pl.item_id                                                              
                 AND to_char(msi.organization_id) = '441'           
                 and msi.segment1=NVL(NULL,msi.segment1)             
                 );
CURSOR C2(p_org_id NUMBER) IS
select invoice_id, terms_id,vendor_id,vendor_site_id,org_id, hold_type, inv_amount, line_total, inv_count,attribute6           
from (           
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1)  */           
    a.invoice_id,a.terms_id,             
    a.vendor_id,a.vendor_site_id,           
    a.org_id,                               
    'MOOT' hold_type,                                 
    a.invoice_amount inv_amount,                                 
    sum(l.amount) line_total,                                 
    1 inv_count,                                 
    count(1) line_count,           
    b.attribute6               
    FROM  ap_supplier_sites_all b,           
          ap_invoice_lines_all l,                               
          ap_invoices_all a,              
          (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */   
                distinct aph.invoice_id,aph.line_location_id           
             FROM ap_holds_all  aph          
            WHERE 1=1 --aph.creation_date > '01-JAN-11'            
              AND NVL(aph.status_flag,'S')= 'S'           
              AND aph.hold_lookup_code != 'OD NO Receipt'                     
              AND aph.release_lookup_code is null 
          ) h                     
  WHERE a.invoice_id=h.invoice_id      
    AND a.org_id+0=p_org_id
    AND a.invoice_num not like '%ODDBUIA%'  
    AND NVL(a.validation_request_id,1)<>-9999999999
    AND a.source<>'US_OD_DROPSHIP'                             
    AND h.line_location_id = l.po_line_location_id             
    --AND a.creation_date>'01-JAN-11'           
    AND l.invoice_id           =a.invoice_id                                 
    AND l.line_type_lookup_code='ITEM'                      
    AND b.vendor_site_id=a.vendor_site_id           
    AND exists (SELECT 'x'   
                  FROM xx_fin_translatevalues tv,                                                                    
                       xx_fin_translatedefinition td                    
                 WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                   AND tv.translate_id  = td.translate_id                                                                    
                   AND tv.enabled_flag = 'Y'                                                                    
                   AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                   AND tv.target_value1 = b.attribute8||''
                )   
    AND exists (select 'x'                                 
              from ap_payment_schedules_all apsa                                 
              where apsa.invoice_id=a.invoice_id                                 
              AND NVL(apsa.discount_date,due_date) < SYSDATE+8           
              )                                 
    AND not exists (select 'x'                                  
                    from ap_holds_all aha                                 
                    where aha.invoice_id = a.invoice_id                                 
                    AND aha.hold_lookup_code = 'OD NO Receipt'             
                    AND NVL(aha.status_flag,'S')= 'S' 
                    AND aha.release_lookup_code is null 
                )           
    AND EXISTS (SELECT 'x'           
                         FROM xx_fin_translatevalues tv           
                             ,xx_fin_translatedefinition td           
                        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'           
                          AND tv.TRANSLATE_ID  = td.TRANSLATE_ID           
                          AND tv.enabled_flag='Y'           
                          AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)           
                          AND tv.target_value1=a.source
                      )             
  AND EXISTS (SELECT  'x'                                                          
                FROM mtl_system_items_b msi,                                                          
                     po_lines_all pl                                                          
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                          
                 AND msi.inventory_item_id = pl.item_id                                                              
                 AND to_char(msi.organization_id) = '441'           
                 and msi.segment1=NVL(NULL,msi.segment1)             
              )                                   
         GROUP BY            
                  a.invoice_id,a.terms_id,           
                  a.vendor_id,a.vendor_site_id,a.org_id,                                      
                  a.invoice_amount,b.attribute6           
);            
CURSOR C21(p_org_id NUMBER) IS
select invoice_id, terms_id,vendor_id,vendor_site_id,org_id, hold_type, inv_amount, line_total, inv_count,attribute6           
from (           
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1)  */           
    a.invoice_id,a.terms_id,             
    a.vendor_id,a.vendor_site_id,           
    a.org_id,                               
    'MOOT' hold_type,                                 
    a.invoice_amount inv_amount,                                 
    0 line_total,                                 
    1 inv_count,                                 
    count(1) line_count,           
    b.attribute6               
    FROM  ap_supplier_sites_all b,           
          ap_invoices_all a,              
          (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */   
                distinct aph.invoice_id
             FROM ap_holds_all  aph          
            WHERE 1=1 --aph.creation_date > '01-JAN-11'            
              AND NVL(aph.status_flag,'S')= 'S'           
              AND aph.hold_lookup_code != 'OD NO Receipt'                     
              AND aph.line_location_id IS NULL
              AND aph.release_lookup_code is null 
              AND NOT EXISTS (SELECT /* INDEX(ah AP_HOLDS_N1) */
                                      'x'
                                FROM ap_holds_all ah
                               WHERE invoice_id=aph.invoice_id
                                 AND line_location_id IS NOT NULL
                                 AND hold_lookup_code != 'OD NO Receipt'                     
                                 AND release_lookup_code IS NULL
                             )
          ) h                     
  WHERE a.invoice_id=h.invoice_id      
    AND a.org_id+0=p_org_id
    AND a.invoice_num not like '%ODDBUIA%'      
    AND a.source<>'US_OD_DROPSHIP'            
    AND NVL(a.validation_request_id,1)<>-9999999999    
    --AND a.creation_date>'01-JAN-11'           
    AND b.vendor_site_id=a.vendor_site_id      
    AND exists (SELECT 'x'   
                  FROM xx_fin_translatevalues tv,                                                                    
                       xx_fin_translatedefinition td                    
                 WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                   AND tv.translate_id  = td.translate_id                                                                    
                   AND tv.enabled_flag = 'Y'                                                                    
                   AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                   AND tv.target_value1 = b.attribute8||''
                )   
    AND exists (select 'x'                                 
              from ap_payment_schedules_all apsa                                 
              where apsa.invoice_id=a.invoice_id                                 
              AND NVL(apsa.discount_date,due_date) < SYSDATE+8           
              )                                 
    AND not exists (select 'x'                                  
                    from ap_holds_all aha                                 
                    where aha.invoice_id = a.invoice_id                                 
                    AND aha.hold_lookup_code = 'OD NO Receipt'             
                    AND NVL(aha.status_flag,'S')= 'S' 
                    AND aha.release_lookup_code is null 
                )           
    AND EXISTS (SELECT 'x'           
                         FROM xx_fin_translatevalues tv           
                             ,xx_fin_translatedefinition td           
                        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'           
                          AND tv.TRANSLATE_ID  = td.TRANSLATE_ID           
                          AND tv.enabled_flag='Y'           
                          AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)           
                          AND tv.target_value1=a.source
                      )             
  AND EXISTS (SELECT  'x'                                                          
                FROM mtl_system_items_b msi,                                                          
                     po_lines_all pl                                                          
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                          
                 AND msi.inventory_item_id = pl.item_id                                                              
                 AND to_char(msi.organization_id) = '441'           
                 and msi.segment1=NVL(NULL,msi.segment1)             
              )                                   
         GROUP BY            
                  a.invoice_id,a.terms_id,           
                  a.vendor_id,a.vendor_site_id,a.org_id,                                      
                  a.invoice_amount,b.attribute6           
);



CURSOR C3(p_org_id NUMBER) IS
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1) */           
    a.invoice_id,a.terms_id,                 
    a.vendor_id,a.vendor_site_id,a.org_id,                           
    'NRF' hold_type,                                 
    a.invoice_amount inv_amount,                                 
    0 line_total,                                 
    1 inv_count,b.attribute6                                
  FROM  ap_supplier_sites_all b,                                
        ap_invoices_all a ,           
       (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */   
            distinct aph.invoice_id           
          FROM ap_holds_all aph            
         WHERE 1=1 --aph.creation_date > '01-JAN-11'            
           AND aph.hold_lookup_code = 'OD NO Receipt'           
           AND NVL(aph.status_flag,'S')= 'S' 
           AND aph.release_lookup_code is null 
        ) h                    
  WHERE  a.invoice_id=h.invoice_id           
     AND a.org_id+0=p_org_id
     AND a.invoice_num not like '%ODDBUIA%'   
     AND NVL(a.validation_request_id,1)<>-9999999999     
     AND a.source<>'US_OD_DROPSHIP'                              
     --AND a.creation_date>'01-JAN-11'           
     AND b.vendor_site_id=a.vendor_site_id           
     AND exists (SELECT 'x'   
                   FROM xx_fin_translatevalues tv,                                                                    
                        xx_fin_translatedefinition td                    
                  WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                    AND tv.translate_id  = td.translate_id                                                                    
                    AND tv.enabled_flag = 'Y'                                                                    
                    AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                    AND tv.target_value1 = b.attribute8||''
                )     
     AND EXISTS (select 'x'                    
                   from ap_payment_schedules_all apsa                    
                  where apsa.invoice_id=a.invoice_id                    
                    AND NVL(apsa.discount_date,due_date) < SYSDATE+8           
                )             
     AND EXISTS (SELECT 'x'           
                   FROM xx_fin_translatevalues tv           
                       ,xx_fin_translatedefinition td           
                  WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'           
                    AND tv.TRANSLATE_ID  = td.TRANSLATE_ID           
                    AND tv.enabled_flag='Y'           
                    AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)           
                    AND tv.target_value1=a.source
                )                          
     AND EXISTS (SELECT  'x'                                                          
                FROM mtl_system_items_b msi,                                                          
                     po_lines_all pl                                                          
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                          
                 AND msi.inventory_item_id = pl.item_id                                                              
                 AND to_char(msi.organization_id) = '441'           
                 and msi.segment1=NVL(NULL,msi.segment1)             
              );

BEGIN
   ln_org_id:=FND_PROFILE.VALUE ('ORG_ID');
   FOR cur IN C1(ln_org_id) LOOP
     v_idslist.extend;
     v_idslist(v_idslist.LAST):=xx_ap_ui_empsumrec_type(  cur.invoice_id
                                                    ,cur.terms_id
                                                    ,cur.vendor_id
                                                    ,cur.vendor_site_id
                                                    ,cur.org_id
                                                    ,cur.hold_type
                                                    ,cur.inv_amount
                                                    ,cur.line_total
                                                    ,cur.inv_count
                                                    ,cur.attribute6
                                                  );
   END LOOP;

   FOR cur IN C2(ln_org_id) LOOP
     v_idslist.extend;
     v_idslist(v_idslist.LAST):=xx_ap_ui_empsumrec_type(  cur.invoice_id
                                                    ,cur.terms_id
                                                    ,cur.vendor_id
                                                    ,cur.vendor_site_id
                                                    ,cur.org_id
                                                    ,cur.hold_type
                                                    ,cur.inv_amount
                                                    ,cur.line_total
                                                    ,cur.inv_count
                                                    ,cur.attribute6
                                                  );
   END LOOP;

   FOR cur IN C21(ln_org_id) LOOP
     v_idslist.extend;
     v_idslist(v_idslist.LAST):=xx_ap_ui_empsumrec_type(  cur.invoice_id
                                                    ,cur.terms_id
                                                    ,cur.vendor_id
                                                    ,cur.vendor_site_id
                                                    ,cur.org_id
                                                    ,cur.hold_type
                                                    ,cur.inv_amount
                                                    ,cur.line_total
                                                    ,cur.inv_count
                                                    ,cur.attribute6
                                                  );
   END LOOP;

   FOR cur IN C3(ln_org_id) LOOP
     v_idslist.extend;
     v_idslist(v_idslist.LAST):=xx_ap_ui_empsumrec_type(  cur.invoice_id
                                                    ,cur.terms_id
                                                    ,cur.vendor_id
                                                    ,cur.vendor_site_id
                                                    ,cur.org_id
                                                    ,cur.hold_type
                                                    ,cur.inv_amount
                                                    ,cur.line_total
                                                    ,cur.inv_count
                                                    ,cur.attribute6
                                                  );
   END LOOP;

   OPEN l_refcursor FOR 
   SELECT tv.target_value2 vendor_assistant,tv.target_value1 employee_id,           
         SUM(DECODE(a.hold_type,'TOTAL',a.inv_count,0)) total_inv_count,                                  
         SUM(DECODE(a.hold_type,'TOTAL',a.inv_amount,0)) total_inv_amount,                                  
         SUM(DECODE(a.hold_type,'MOOT',a.line_total,0))+SUM(DECODE(a.hold_type,'NRF',a.inv_amount,0)) total_line_amount,                                  
         SUM(DECODE(a.hold_type,'MOOT',a.inv_count,0)) total_moot_count,                                  
         SUM(DECODE(a.hold_type,'MOOT',a.inv_amount,null)) total_moot_inv_amount,                                  
         SUM(DECODE(a.hold_type,'MOOT',a.line_total,0)) total_moot_line_amount,                                  
         nvl(SUM(DECODE(a.hold_type,'NRF',a.inv_count,0)),0) total_nrf_count,                                  
         SUM(DECODE(a.hold_type,'NRF',a.inv_amount,0)) total_nrf_amount                                  
    FROM  table(cast (v_idslist as xx_ap_ui_empsumrec_type_t)) a,                               
          xx_fin_translatevalues tv,           
          xx_fin_translatedefinition td           
   where td.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS'            
     AND tv.TRANSLATE_ID  = td.TRANSLATE_ID           
     AND tv.enabled_flag='Y'           
     AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)             
     AND tv.target_value1=NVL(a.attribute6,'Open')          
   group by a.org_id,tv.target_value1,tv.target_value2
   order by tv.target_value2;
   LOOP
     FETCH l_refcursor
     INTO  l_emp_sum_rec.vendor_assistant
          ,l_emp_sum_rec.employee_id
          ,l_emp_sum_rec.total_inv_count
          ,l_emp_sum_rec.total_inv_amount      
          ,l_emp_sum_rec.total_line_amount
          ,l_emp_sum_rec.total_moot_count  
          ,l_emp_sum_rec.total_moot_inv_amount  
          ,l_emp_sum_rec.total_moot_line_amount
          ,l_emp_sum_rec.total_nrf_count  
          ,l_emp_sum_rec.total_nrf_amount;
     EXIT WHEN l_refcursor%notfound;
              PIPE ROW (
                         xx_ap_ui_emp_summ
                           (
                                 l_emp_sum_rec.vendor_assistant
                                ,l_emp_sum_rec.employee_id
                                ,l_emp_sum_rec.total_inv_count
                                ,l_emp_sum_rec.total_inv_amount      
                                ,l_emp_sum_rec.total_line_amount
                                ,l_emp_sum_rec.total_moot_count  
                                ,l_emp_sum_rec.total_moot_inv_amount  
                                ,l_emp_sum_rec.total_moot_line_amount
                                ,l_emp_sum_rec.total_nrf_count  
                                ,l_emp_sum_rec.total_nrf_amount   
                            )
                        );
   END LOOP;
   CLOSE l_refcursor;
   RETURN;
 exception
   when no_data_needed then
    RETURN;
   when others then
    raise_application_error (-20010, 'Issue ='||sqlerrm);
END xx_ap_ui_emp_summ_f; 

-- +======================================================================+
-- | Name        :  xx_ap_ui_empvnd_summ_f                                |
-- | Description :  To get Vendor Assistant Vendor Moot Summary data      |
-- |                                                                      |
-- | Parameters  :  p_org_id,p_vendor_id,p_vendor_site_id,p_employee_no   |
-- |                                                                      |
-- | RETURNs     :                                                        |
-- |                                                                      |
-- +======================================================================+

FUNCTION xx_ap_ui_empvnd_summ_f(p_org_id IN NUMBER,p_vendor_id IN NUMBER, p_vendor_site_id IN NUMBER, p_employee_no IN VARCHAR2)
RETURN xx_ap_ui_empvnd_summ_t pipelined 
IS
  type empvnd_sum_rec is record
    (
        org_id     NUMBER,    
        vendor_assistant varchar2(100),
        employee_id                VARCHAR2(20),
        vendor_name                varchar2(100),
        supplier                varchar2(25),
        vendor_site_code        varchar2(15),
        disc                    varchar2(1),
        total_inv_count            number,
        total_inv_amount        number,
        total_line_amount        number,
        total_moot_count        number,
        total_moot_inv_amount    number,
        total_moot_line_amount    number,
        total_nrf_count            number,
        total_nrf_amount        number
    );  

  l_empvnd_sum_rec                 empvnd_sum_rec;
  v_empvndlist                     xx_ap_ui_empvndrec_type_t:=xx_ap_ui_empvndrec_type_t();
  type refcur is ref             cursor;
  l_refcursor                     refcur;     
  
CURSOR C1 IS
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1) */     
          a.invoice_id,     
          a.terms_id,     
          a.vendor_id,     
          a.vendor_site_id,               
          a.org_id,     
          'TOTAL' hold_type,              
          a.invoice_amount inv_amount,              
          0 line_total ,              
          1 inv_count,     
          c.vendor_name,     
          c.segment1,     
          b.vendor_site_code,     
          b.attribute6     
    FROM  ap_suppliers c,     
          ap_supplier_sites_all b,     
          ap_invoices_all a ,           
           (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */  
            distinct aph.invoice_id     
          FROM ap_holds_all aph     
         WHERE 1=1 --aph.creation_date > '01-JAN-11'      
           AND NVL(aph.status_flag,'S')= 'S' 
           AND aph.release_lookup_code is null 
        ) h     
   WHERE a.invoice_id=h.invoice_id     
     AND a.invoice_num not like '%ODDBUIA%'    
     AND NVL(a.validation_request_id,1)<>-9999999999     
     AND a.source<>'US_OD_DROPSHIP'                              
     AND a.org_id=NVL(p_org_id,a.org_id)
     --AND a.creation_date>'01-JAN-11'     
     AND b.vendor_site_id=a.vendor_site_id     
     AND b.vendor_site_id=NVL(p_vendor_site_id,b.vendor_site_id)
     AND b.vendor_id=NVL(p_vendor_id,b.vendor_id)
     AND b.attribute6=NVL(p_employee_no,b.attribute6)     
     AND c.vendor_id=b.vendor_id    
     AND exists (SELECT 'x'   
                   FROM xx_fin_translatevalues tv,                                                                    
                        xx_fin_translatedefinition td                    
                  WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                    AND tv.translate_id  = td.translate_id                                                                    
                    AND tv.enabled_flag = 'Y'                                                                    
                    AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                    AND tv.target_value1 = b.attribute8||''
                )        
     AND EXISTS (select 'x'              
                   from ap_payment_schedules_all apsa              
                  where apsa.invoice_id=a.invoice_id              
                    AND NVL(apsa.discount_date,due_date) < SYSDATE+8     
                )       
     AND EXISTS (SELECT 'x'     
                   FROM xx_fin_translatevalues tv     
                       ,xx_fin_translatedefinition td     
                  WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'     
                    AND tv.TRANSLATE_ID  = td.TRANSLATE_ID     
                    AND tv.enabled_flag='Y'     
                    AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)     
                    AND tv.target_value1=a.source
                )       
  AND EXISTS (SELECT  'x'                                                    
                FROM mtl_system_items_b msi,                                                    
                     po_lines_all pl                                                    
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                    
                 AND msi.inventory_item_id = pl.item_id                                                        
                 AND to_char(msi.organization_id) = '441'     
                 and msi.segment1=NVL(NULL,msi.segment1)       
              );

CURSOR C2 IS
select invoice_id, terms_id,vendor_id,vendor_site_id,org_id, hold_type, inv_amount, line_total, inv_count,vendor_name,     
       segment1,vendor_site_code,attribute6     
from (     
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1) */     
    a.invoice_id,a.terms_id,       
    a.vendor_id,a.vendor_site_id,     
    a.org_id,                         
    'MOOT' hold_type,                           
    a.invoice_amount inv_amount,                           
    SUM(l.amount) line_total,                           
    1 inv_count,                           
    count(1) line_count,     
    c.vendor_name,     
    c.segment1,     
    b.vendor_site_code,     
    b.attribute6     
    FROM  ap_suppliers c,     
          ap_supplier_sites_all b,     
          ap_invoice_lines_all l,                         
          ap_invoices_all a,        
          (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */  
            distinct aph.invoice_id,  aph.line_location_id     
             FROM ap_holds_all aph     
            WHERE 1=1 --aph.creation_date > '01-JAN-11'      
              AND NVL(aph.status_flag,'S')= 'S'     
              AND aph.hold_lookup_code != 'OD NO Receipt' 
              AND aph.release_lookup_code is null 
          ) h               
  WHERE a.invoice_id=h.invoice_id     
    AND a.invoice_num not like '%ODDBUIA%'    
    AND NVL(a.validation_request_id,1)<>-9999999999    
    AND a.source<>'US_OD_DROPSHIP'                             
    AND a.org_id=NVL(p_org_id,a.org_id)    
    AND l.po_line_location_id = h.line_location_id     
    --AND a.creation_date>'01-JAN-11'     
    AND l.invoice_id           =a.invoice_id      
    AND l.line_type_lookup_code='ITEM'                
    AND b.vendor_site_id=a.vendor_site_id     
    AND b.vendor_site_id=NVL(p_vendor_site_id,b.vendor_site_id)
    AND b.vendor_id=NVL(p_vendor_id,b.vendor_id)
    AND b.attribute6=NVL(p_employee_no,b.attribute6)     
    AND c.vendor_id=b.vendor_id  
    AND exists (SELECT 'x'   
                   FROM xx_fin_translatevalues tv,                                                                    
                        xx_fin_translatedefinition td                    
                  WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                    AND tv.translate_id  = td.translate_id                                                                    
                    AND tv.enabled_flag = 'Y'                                                                    
                    AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                    AND tv.target_value1 = b.attribute8||''
                )            
    AND exists (select 'x'                           
              from ap_payment_schedules_all apsa                           
              where apsa.invoice_id=a.invoice_id                           
              AND NVL(apsa.discount_date,due_date) < SYSDATE+8     
              )                           
    AND not exists (select 'x'                            
                    from ap_holds_all aha                           
                    where aha.invoice_id = a.invoice_id                           
                    AND aha.hold_lookup_code = 'OD NO Receipt'       
                    AND NVL(aha.status_flag,'S')= 'S' 
                    AND aha.release_lookup_code is null 
                )     
    AND EXISTS (SELECT 'x'     
                         FROM xx_fin_translatevalues tv     
                             ,xx_fin_translatedefinition td     
                        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'     
                          AND tv.TRANSLATE_ID  = td.TRANSLATE_ID     
                          AND tv.enabled_flag='Y'     
                          AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)     
                          AND tv.target_value1=a.source
                      )       
  AND EXISTS (SELECT  'x'                                                    
                FROM mtl_system_items_b msi,                                                    
                     po_lines_all pl                                                    
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                    
                 AND msi.inventory_item_id = pl.item_id                                                        
                 AND to_char(msi.organization_id) = '441'     
                 and msi.segment1=NVL(NULL,msi.segment1)       
              )                             
         GROUP BY      
                  a.invoice_id,a.terms_id,     
                  a.vendor_id,a.vendor_site_id,a.org_id,                                
                  a.invoice_amount,     
                    c.vendor_name,     
                  c.segment1,     
                  b.vendor_site_code,     
                  b.attribute6     
);


CURSOR C21 IS
select invoice_id, terms_id,vendor_id,vendor_site_id,org_id, hold_type, inv_amount, line_total, inv_count,vendor_name,     
       segment1,vendor_site_code,attribute6     
from (     
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1) */     
    a.invoice_id,a.terms_id,       
    a.vendor_id,a.vendor_site_id,     
    a.org_id,                         
    'MOOT' hold_type,                           
    a.invoice_amount inv_amount,                           
    0 line_total,                           
    1 inv_count,                           
    count(1) line_count,     
    c.vendor_name,     
    c.segment1,     
    b.vendor_site_code,     
    b.attribute6     
    FROM  ap_suppliers c,     
          ap_supplier_sites_all b,     
          ap_invoices_all a,        
          (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */   
                distinct aph.invoice_id
             FROM ap_holds_all  aph          
            WHERE 1=1 --aph.creation_date > '01-JAN-11'            
              AND NVL(aph.status_flag,'S')= 'S'           
              AND aph.hold_lookup_code != 'OD NO Receipt'                     
              AND aph.line_location_id IS NULL
              AND aph.release_lookup_code is null 
              AND NOT EXISTS (SELECT /* INDEX(ah AP_HOLDS_N1) */
                                      'x'
                                FROM ap_holds_all ah
                               WHERE invoice_id=aph.invoice_id
                                 AND line_location_id IS NOT NULL
                                 AND hold_lookup_code != 'OD NO Receipt'                     
                                 AND release_lookup_code IS NULL
                             )
          ) h                     
  WHERE a.invoice_id=h.invoice_id     
    AND a.invoice_num not like '%ODDBUIA%'    
    AND NVL(a.validation_request_id,1)<>-9999999999    
    AND a.source<>'US_OD_DROPSHIP'                             
    AND a.org_id=NVL(p_org_id,a.org_id)    
    --AND a.creation_date>'01-JAN-11'     
    AND b.vendor_site_id=a.vendor_site_id     
    AND b.vendor_site_id=NVL(p_vendor_site_id,b.vendor_site_id)
    AND b.vendor_id=NVL(p_vendor_id,b.vendor_id)
    AND b.attribute6=NVL(p_employee_no,b.attribute6)     
    AND c.vendor_id=b.vendor_id  
    AND exists (SELECT 'x'   
                   FROM xx_fin_translatevalues tv,                                                                    
                        xx_fin_translatedefinition td                    
                  WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                    AND tv.translate_id  = td.translate_id                                                                    
                    AND tv.enabled_flag = 'Y'                                                                    
                    AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                    AND tv.target_value1 = b.attribute8||''
                )            
    AND exists (select 'x'                           
              from ap_payment_schedules_all apsa                           
              where apsa.invoice_id=a.invoice_id                           
              AND NVL(apsa.discount_date,due_date) < SYSDATE+8     
              )                           
    AND not exists (select 'x'                            
                    from ap_holds_all aha                           
                    where aha.invoice_id = a.invoice_id                           
                    AND aha.hold_lookup_code = 'OD NO Receipt'       
                    AND NVL(aha.status_flag,'S')= 'S' 
                    AND aha.release_lookup_code is null 
                )     
    AND EXISTS (SELECT 'x'     
                         FROM xx_fin_translatevalues tv     
                             ,xx_fin_translatedefinition td     
                        WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'     
                          AND tv.TRANSLATE_ID  = td.TRANSLATE_ID     
                          AND tv.enabled_flag='Y'     
                          AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)     
                          AND tv.target_value1=a.source
                      )       
  AND EXISTS (SELECT  'x'                                                    
                FROM mtl_system_items_b msi,                                                    
                     po_lines_all pl                                                    
               WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                    
                 AND msi.inventory_item_id = pl.item_id                                                        
                 AND to_char(msi.organization_id) = '441'     
                 and msi.segment1=NVL(NULL,msi.segment1)       
              )                             
         GROUP BY      
                  a.invoice_id,a.terms_id,     
                  a.vendor_id,a.vendor_site_id,a.org_id,                                
                  a.invoice_amount,     
                    c.vendor_name,     
                  c.segment1,     
                  b.vendor_site_code,     
                  b.attribute6     
);


CURSOR C3 IS
SELECT /*+ LEADING (h) INDEX(b AP_SUPPLIER_SITES_U1) */     
    a.invoice_id,a.terms_id,           
    a.vendor_id,a.vendor_site_id,a.org_id,                     
    'NRF' hold_type,                           
    a.invoice_amount inv_amount,                           
    0 line_total,                           
    1 inv_count ,     
          c.vendor_name,     
          c.segment1,     
          b.vendor_site_code,     
          b.attribute6     
  FROM  ap_suppliers c,     
        ap_supplier_sites_all b,     
        ap_invoices_all a ,     
       (SELECT /*+ INDEX(aph XX_AP_HOLDS_N1) */  
            distinct aph.invoice_id     
          FROM ap_holds_all aph     
         WHERE 1=1 --aph.creation_date > '01-JAN-11'      
           AND aph.hold_lookup_code = 'OD NO Receipt'     
           AND NVL(aph.status_flag,'S')= 'S' 
           AND aph.release_lookup_code is null 
        ) h              
  WHERE  a.invoice_id=h.invoice_id     
    AND a.invoice_num not like '%ODDBUIA%'  
    AND NVL(a.validation_request_id,1)<>-9999999999    
    AND a.source<>'US_OD_DROPSHIP'                             
    --AND a.creation_date>'01-JAN-11'     
    AND a.org_id=NVL(p_org_id,a.org_id)        
    AND b.vendor_site_id=a.vendor_site_id     
    AND b.vendor_site_id=NVL(p_vendor_site_id,b.vendor_site_id)
    AND b.vendor_id=NVL(p_vendor_id,b.vendor_id)
    AND b.attribute6=NVL(p_employee_no,b.attribute6)     
    AND c.vendor_id=b.vendor_id    
    AND exists (SELECT 'x'   
                   FROM xx_fin_translatevalues tv,                                                                    
                        xx_fin_translatedefinition td                    
                  WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                     
                    AND tv.translate_id  = td.translate_id                                                                    
                    AND tv.enabled_flag = 'Y'                                                                    
                    AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)   
                    AND tv.target_value1 = b.attribute8||''
                )       
     AND EXISTS (select 'x'              
                   from ap_payment_schedules_all apsa              
                  where apsa.invoice_id=a.invoice_id              
                    AND NVL(apsa.discount_date,due_date) < SYSDATE+8     
                )       
     AND EXISTS (SELECT 'x'     
                   FROM xx_fin_translatevalues tv     
                       ,xx_fin_translatedefinition td     
                  WHERE td.TRANSLATION_NAME = 'XX_AP_TR_MATCH_INVOICES'     
                    AND tv.TRANSLATE_ID  = td.TRANSLATE_ID     
                    AND tv.enabled_flag='Y'     
                    AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)     
                    AND tv.target_value1=a.source
                )                    
     AND EXISTS (SELECT  'x'                                                    
                   FROM mtl_system_items_b msi,                                                    
                        po_lines_all pl                                                    
                  WHERE pl.po_header_id = NVL(a.po_header_id,a.quick_po_header_id)                                                    
                    AND msi.inventory_item_id = pl.item_id                                                        
                    AND to_char(msi.organization_id) = '441'     
                    AND msi.segment1=NVL(NULL,msi.segment1)       
              );


BEGIN
   FOR cur IN C1 LOOP
     v_empvndlist.extend;
     v_empvndlist(v_empvndlist.LAST):=xx_ap_ui_empvndrec_type(  
                                                                cur.invoice_id,     
                                                                cur.terms_id,     
                                                                cur.vendor_id,     
                                                                cur.vendor_site_id,               
                                                                cur.org_id,     
                                                                cur.hold_type,              
                                                                cur.inv_amount,              
                                                                cur.line_total ,              
                                                                cur.inv_count,     
                                                                cur.vendor_name,     
                                                                cur.segment1,     
                                                                cur.vendor_site_code,     
                                                                cur.attribute6     
                                                            );
   END LOOP;
   FOR cur IN C2 LOOP
     v_empvndlist.extend;
     v_empvndlist(v_empvndlist.LAST):=xx_ap_ui_empvndrec_type(  
                                                                cur.invoice_id,     
                                                                cur.terms_id,     
                                                                cur.vendor_id,     
                                                                cur.vendor_site_id,               
                                                                cur.org_id,     
                                                                cur.hold_type,              
                                                                cur.inv_amount,              
                                                                cur.line_total ,              
                                                                cur.inv_count,     
                                                                cur.vendor_name,     
                                                                cur.segment1,     
                                                                cur.vendor_site_code,     
                                                                cur.attribute6     
                                                            );
   END LOOP;

   FOR cur IN C21 LOOP
     v_empvndlist.extend;
     v_empvndlist(v_empvndlist.LAST):=xx_ap_ui_empvndrec_type(  
                                                                cur.invoice_id,     
                                                                cur.terms_id,     
                                                                cur.vendor_id,     
                                                                cur.vendor_site_id,               
                                                                cur.org_id,     
                                                                cur.hold_type,              
                                                                cur.inv_amount,              
                                                                cur.line_total ,              
                                                                cur.inv_count,     
                                                                cur.vendor_name,     
                                                                cur.segment1,     
                                                                cur.vendor_site_code,     
                                                                cur.attribute6     
                                                            );
   END LOOP;

   FOR cur IN C3 LOOP
     v_empvndlist.extend;
     v_empvndlist(v_empvndlist.LAST):=xx_ap_ui_empvndrec_type(  
                                                                cur.invoice_id,     
                                                                cur.terms_id,     
                                                                cur.vendor_id,     
                                                                cur.vendor_site_id,               
                                                                cur.org_id,     
                                                                cur.hold_type,              
                                                                cur.inv_amount,              
                                                                cur.line_total ,              
                                                                cur.inv_count,     
                                                                cur.vendor_name,     
                                                                cur.segment1,     
                                                                cur.vendor_site_code,     
                                                                cur.attribute6     
                                                            );
   END LOOP;
   OPEN l_refcursor FOR 
   SELECT a.org_id,tv.target_value2 vendor_assistant,     
         tv.target_value1 employee_id,a.vendor_name, a.segment1 supplier,a.vendor_site_code,                 
         DECODE(SIGN(instr(t.name,'/')),0,NULL,1,'D') disc,     
         SUM(DECODE(a.hold_type,'TOTAL',inv_count,0)) total_inv_count,                            
         SUM(DECODE(a.hold_type,'TOTAL',inv_amount,0)) total_inv_amount,                            
         SUM(DECODE(a.hold_type,'MOOT',line_total,0))+SUM(DECODE(hold_type,'NRF',inv_amount,0)) total_line_amount,                            
         SUM(DECODE(a.hold_type,'MOOT',inv_count,0)) total_moot_count,                            
         SUM(DECODE(a.hold_type,'MOOT',inv_amount,null)) total_moot_inv_amount,                            
         SUM(DECODE(a.hold_type,'MOOT',line_total,0)) total_moot_line_amount,                            
         SUM(DECODE(a.hold_type,'NRF',inv_count,0)) total_nrf_count,                            
         SUM(DECODE(a.hold_type,'NRF',inv_amount,0)) total_nrf_amount                            
    FROM table(cast (v_empvndlist as xx_ap_ui_empvndrec_type_t)) a,                               
         ap_terms t,     
         xx_fin_translatevalues tv,     
         xx_fin_translatedefinition td     
   where t.term_id=a.terms_id        
     AND tv.TRANSLATE_ID  = td.TRANSLATE_ID       
     AND SYSDATE BETWEEN tv.start_date_active and NVL(tv.end_date_active,sysdate)       
     AND tv.target_value1=NVL(a.attribute6,'Open')
     AND tv.enabled_flag='Y'     
     AND td.TRANSLATION_NAME = 'XX_AP_VENDOR_ASSISTANTS'     
   group by a.org_id,tv.target_value1,tv.target_value2,a.vendor_name, a.segment1,a.vendor_site_code,                 
         DECODE(SIGN(instr(t.name,'/')),0,NULL,1,'D');
   LOOP
     FETCH l_refcursor
     INTO  
           l_empvnd_sum_rec.org_id     
          ,l_empvnd_sum_rec.vendor_assistant
          ,l_empvnd_sum_rec.employee_id
          ,l_empvnd_sum_rec.vendor_name
          ,l_empvnd_sum_rec.supplier
          ,l_empvnd_sum_rec.vendor_site_code          
          ,l_empvnd_sum_rec.disc          
          ,l_empvnd_sum_rec.total_inv_count
          ,l_empvnd_sum_rec.total_inv_amount      
          ,l_empvnd_sum_rec.total_line_amount
          ,l_empvnd_sum_rec.total_moot_count  
          ,l_empvnd_sum_rec.total_moot_inv_amount  
          ,l_empvnd_sum_rec.total_moot_line_amount
          ,l_empvnd_sum_rec.total_nrf_count  
          ,l_empvnd_sum_rec.total_nrf_amount;
     EXIT WHEN l_refcursor%notfound;
              PIPE ROW (
                         xx_ap_ui_empvnd_summ
                           (
                                 l_empvnd_sum_rec.org_id     
                                ,l_empvnd_sum_rec.vendor_assistant
                                ,l_empvnd_sum_rec.employee_id
                                ,l_empvnd_sum_rec.vendor_name
                                ,l_empvnd_sum_rec.supplier
                                ,l_empvnd_sum_rec.vendor_site_code          
                                ,l_empvnd_sum_rec.disc          
                                ,l_empvnd_sum_rec.total_inv_count
                                ,l_empvnd_sum_rec.total_inv_amount      
                                ,l_empvnd_sum_rec.total_line_amount
                                ,l_empvnd_sum_rec.total_moot_count  
                                ,l_empvnd_sum_rec.total_moot_inv_amount  
                                ,l_empvnd_sum_rec.total_moot_line_amount
                                ,l_empvnd_sum_rec.total_nrf_count  
                                ,l_empvnd_sum_rec.total_nrf_amount
                            )
                        );
   END LOOP;
   CLOSE l_refcursor;
   RETURN;
 exception
   when no_data_needed then
    RETURN;
   when others then
    raise_application_error (-20010, 'Issue ='||sqlerrm);
END xx_ap_ui_empvnd_summ_f; 

END;
/
SHOW ERRORS;