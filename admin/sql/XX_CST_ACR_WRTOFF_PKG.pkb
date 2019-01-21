create or replace package body XX_CST_ACR_WRTOFF_PKG AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CST_ACR_WRTOFF_PKG.pkb                                |
-- | Description :  Receiver Write Off    Package                            |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       01-AUG-2017 Sridhar G.         Initial version                 |
-- |1.1       11-Oct-2017 Paddy Sanjeevi     Modified p_reason_id to code    |
-- |1.2       06-DEC-2017 Havish Kasina      Added p_vendor_site_id          |
-- |1.3       11-Jan-2018 Paddy Sanjeevi     p_rcv_date_from date to varchar2|
-- |1.4       18-Jan-2018 Paddy Sanjeevi     Added xx_purge_stg              |
-- |1.5       31-Jan-2018 Paddy Sanjeevi     Removed invoice check process   | 
-- +=========================================================================+

G_PKG_NAME     constant varchar2(30) := 'CST_Accrual_Rec_PVT';
G_LOG_HEADER    constant varchar2(40) := 'cst.plsql.CST_Accrual_Rec_PVT';
G_LOG_LEVEL    constant number       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

-- +======================================================================+
-- | Name             : Xx_purge_stg                                      |
-- | Description      : delete the processed records from staging table   |
-- | Params           : N/A                                               |
-- +======================================================================+  
PROCEDURE xx_purge_stg
IS

CURSOR C_del
IS
SELECT DISTINCT
       request_id
  FROM xx_ap_rcvwrite_off_stg	   
 WHERE creation_date<sysdate-7;

BEGIN
  FOR cur IN c_del LOOP
    DELETE
	  FROM xx_ap_rcvwrite_off_stg
     WHERE request_id=cur.request_id;	  
    COMMIT;
  END LOOP;
EXCEPTION
  WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.log,'Error in Purge :'||SQLERRM);
END xx_purge_stg;

-- +======================================================================+
-- | Name             : Xx_process_writeoff                               |
-- | Description      :                                                   |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      01-Aug-2017  Sridhar G        Initial Version               |
-- +======================================================================+  
PROCEDURE Xx_process_writeoff(x_errbuf          OUT NOCOPY     VARCHAR2,
                        x_retcode         OUT NOCOPY     NUMBER,
                        P_OU_ID number,
                        P_ACCRUAL_ACCT_ID number,
                        P_bal_seg_fr varchar2,
                        P_bal_Seg_to varchar2,
                        P_vendor_id number,
                        P_vendor_site_id number, -- -- Added as per Version 1.2 by Havish K
                        P_rcv_date_from varchar2,
                        P_rcv_date_to varchar2,
                        P_item_id number,
                        P_po_num varchar2,
                        p_po_line_closed_flag varchar2,
                        P_po_line_no varchar2,
                        P_shipment_no varchar2,
                        P_dist_no varchar2,
                        P_destination_type varchar2,
                        p_reason_code in varchar2,
                        p_po_type in varchar2,
                        P_min_age number,
                        P_max_age number,
                        P_min_bal number,
                        P_max_bal number,
                        P_process_mode varchar2
                        ) IS
Cursor c1 is
    select *
    from cst_reconciliation_summary 
    where write_off_select_flag='Y';

Gn_request_id NUMBER:=fnd_global.conc_request_id;
l_reason_id NUMBER;
l_count NUMBER;
l_err_num NUMBER;
l_err_code VARCHAR2(20);
l_err_msg VARCHAR2(100);                
l_sob_id number;
p_reason_id NUMBER;

BEGIN                     

  BEGIN
    SELECT reason_id 
      INTO p_reason_id
      FROM mtl_transaction_reasons
     WHERE reason_name=p_reason_code;
  EXCEPTION
    WHEN others THEN
      p_reason_id:=NULL;    
  END;


/*Calling the procedure xx_set_txns*/
xx_set_txns(p_ou_id,
            P_ACCRUAL_ACCT_ID,
            P_bal_seg_fr,
            P_bal_Seg_to,
            P_vendor_id,
            P_vendor_site_id, -- -- Added as per Version 1.2 by Havish K
            P_rcv_date_from,
            P_rcv_date_to,
            P_item_id,
            P_po_num,
            p_po_line_closed_flag,
            P_po_line_no,
            P_shipment_no,
            P_dist_no,
            P_destination_type,
            P_min_age,
            P_max_age,
            P_min_bal,
            P_max_bal,
            P_process_mode,
            Gn_request_id,
            p_reason_id,
            p_po_type
            );

IF p_process_mode='FINAL' THEN
    FOR x in C1 
    LOOP
      begin
        select set_of_books_id into l_sob_id 
          from po_distributions_all pda
         where pda.po_distribution_id = x.po_distribution_id;
            
        exception
            when others then
                FND_FILE.PUT_LINE(FND_FILE.log,'l_sob_id: '||SQLERRM||' : '||x.po_distribution_id);
        end;
       
        insert_appo_data_all(
                            SYSDATE,
                            p_reason_id,
                            'TEST1',
                            l_sob_id,
                            x.operating_unit_id,
                            l_count,
                            l_err_num,
                            l_err_code,
                            l_err_msg
                            );
        
    END LOOP
    COMMIT;
END IF;

IF p_process_mode='FINAL' THEN
    Update XX_AP_RCVWRITE_OFF_STG a 
    set process_flag=7 
    where request_id=gn_request_id
    and not exists (select 'x'
                    from cst_reconciliation_summary
                    where operating_unit_id =a.org_id
                    and po_distribution_id=a.po_distribution_id
                    and write_off_select_flag||'' = 'Y');  -- to be 
                
                
    Update XX_AP_RCVWRITE_OFF_STG a 
    set process_flag=6 
    where request_id=gn_request_id
    and exists (select 'x'
                from cst_reconciliation_summary
           where operating_unit_id =a.org_id
             and po_distribution_id=a.po_distribution_id
                       and write_off_select_flag||'' = 'Y'
               );
    FND_FILE.PUT_LINE(FND_FILE.log,'Updated the table XX_AP_RCVWRITE_OFF_STG as Process Mode is RUN!');           
ELSE
    Update XX_AP_RCVWRITE_OFF_STG a 
    set process_flag=7 
    where request_id=gn_request_id
    and process_flag=4;
END IF;
   
   COMMIT;
   
   FND_FILE.PUT_LINE(FND_FILE.log,'Submitting the report!');
   submit_rcv_write_off_report(gn_request_id, p_process_mode);
   xx_purge_stg;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in Xx_process_writeoff: '||SQLERRM);
        FND_FILE.PUT_LINE(FND_FILE.log,'Error in Xx_process_writeoff: '||SQLERRM);
END Xx_process_writeoff;

 
-- +======================================================================+
-- | Name             : submit_rcv_write_off_report                       |
-- | Description      : Submit's the Receiver write-off report and        |
-- |                     will be called from Xx_process_writeoff           |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      01-Aug-2017  Sridhar G        Initial Version               |
-- +======================================================================+ 
PROCEDURE submit_rcv_write_off_report(P_request_id IN NUMBER, p_process_mode in Varchar2) IS
ln_request_id number:=NULL;
lb_layout     BOOLEAN:= NULL;
BEGIN
    lb_layout := FND_REQUEST.ADD_LAYOUT('XXFIN',
                                         'XXAPRCVWRTOFFREP',
                                         'en',
                                         'US',
                                         'EXCEL');
    IF lb_layout 
    THEN
        fnd_file.put_line (fnd_file.LOG, 'successfully added the layout:');
    ELSE
        fnd_file.put_line (fnd_file.LOG, 'unsuccessfully added the layout:');
    END IF;

    BEGIN            
    ln_request_id := fnd_request.submit_request (
                    application   => 'XXFIN',     -- Application short name
                    program       => 'XXAPRCVWRTOFFREP', --- conc program short name
                    description   => NULL,
                    start_time    => SYSDATE,
                    sub_request   => NULL,
                    argument1     => P_request_id,
                    argument2     => p_process_mode
                    );
    exception          
    WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.LOG, 'Error ln_request_id: '||ln_request_id);
    END;                    
                            
EXCEPTION
WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.log,'Error in Xx_process_writeoff: '||SQLERRM);                        
END submit_rcv_write_off_report;


-- +======================================================================+
-- | Name             : Xx_set_txns                                          |
-- | Description      : Will be called from Xx_process_writeoff           |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      01-Aug-2017  Sridhar G        Initial Version               |
-- +======================================================================+ 
PROCEDURE Xx_set_txns(p_ou_id in Number,
                    P_ACCRUAL_ACCT_ID number,
                    P_bal_seg_fr in varchar2,
                    P_bal_Seg_to in varchar2,
                    P_vendor_id in number,
                    P_vendor_site_id in number, -- -- Added as per Version 1.2 by Havish K
                    P_rcv_date_from in varchar2,
                    P_rcv_date_to in varchar2,
                    P_item_id in number,
                    P_po_num in varchar2,
                    p_po_line_closed_flag in varchar2,
                    P_po_line_no in varchar2,
                    P_shipment_no in varchar2,
                    P_dist_no in varchar2,
                    P_destination_type in varchar2,
                    P_min_age in number,
                    P_max_age in number,
                    P_min_bal in number,
                    P_max_bal in number,
                    P_process_mode in varchar2,
                    P_request_id number,
                    p_reason_id in number,
                    p_po_type in varchar2
                    ) IS
/*Cursor c1 to get all the records from cst_reconciliation_summary based on the parameters*/
cursor c1_rec is
select /*+ LEADING(cst) */
			sup.segment1,
       sup.vendor_name,
       site.attribute8 site_category,
	   site.vendor_site_code,
       cst.operating_unit_id,
       ou.name,
       ph.segment1 po_num,
       pol.line_num po_line_num,
       poll.shipment_num,
       pod.po_distribution_id,
       pod.distribution_num po_dist_num,
       cst.po_balance,
       cst.ap_balance,
       cst.write_off_balance wo_balance,
       cst.last_receipt_date,
       cst.last_invoice_dist_date,
       msi.segment1 item,
       msi.description item_desc,
       cst.destination_type_code,
        gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7 accr_acct,
        trunc(sysdate - decode(fnd_profile.value('CST_ACCRUAL_AGE_IN_DAYS'),1,nvl(last_receipt_date,LAST_INVOICE_DIST_DATE),greatest(nvl(last_receipt_date,LAST_INVOICE_DIST_DATE), nvl(LAST_INVOICE_DIST_DATE, last_receipt_date))
        )) age_in_days  
    from hr_operating_units ou,
         mtl_system_items_b msi,
         gl_code_combinations gcc,  
         ap_supplier_sites_all site,
         ap_suppliers sup,
         po_headers_all ph,
         po_lines_all pol,
         po_line_locations_all poll,
         po_distributions_all pod,
         cst_reconciliation_summary cst
    where 1=1
    and last_receipt_date between to_date(to_char(p_rcv_date_from)||' 00:00:00','DD-MON-RR HH24:MI:SS') 
                             AND to_date(to_char(p_rcv_date_to)||' 23:59:59','DD-MON-RR HH24:MI:SS') 
    and cst.po_distribution_id=pod.po_distribution_id
    and cst.operating_unit_id=pod.org_id
    and cst.vendor_id=sup.vendor_id
    and poll.line_location_id=pod.line_location_id
    and poll.org_id=pod.org_id
    and pol.po_line_id=poll.po_line_id
    and ph.po_header_id=pol.po_header_id 
    and sup.vendor_id=nvl(p_vendor_id,sup.vendor_id)
    and site.vendor_site_id = nvl(p_vendor_site_id,site.vendor_site_id) -- Added as per Version 1.2 by Havish K
    and site.vendor_id=ph.vendor_id
    and site.vendor_site_id=ph.vendor_site_id
    and exists (SELECT 'x'       
         FROM xx_fin_translatevalues tv,                                                                        
              xx_fin_translatedefinition td                        
        WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                         
          AND tv.translate_id  = td.translate_id                                                                        
          AND tv.enabled_flag = 'Y'                                                                        
          AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)       
          AND tv.target_value1 = site.attribute8)
    and cst.inventory_item_id=nvl(p_item_id,cst.inventory_item_id)
    -- and cst.accrual_account_id=nvl(p_accrual_acct_id,cst.accrual_account_id) -- Commented as per Version 1.2
    and cst.operating_unit_id=nvl(p_ou_id,cst.operating_unit_id)
    and cst.destination_type_code=nvl(p_destination_type,cst.destination_type_code)
    and pod.distribution_num=nvl(p_dist_no,pod.distribution_num)  
    and poll.shipment_num=nvl(p_shipment_no,poll.shipment_num)
    and pol.line_num=nvl(p_po_line_no,pol.line_num)
    and (   (p_po_line_closed_flag = 'Y' and pol.closed_code in ('CLOSED','FINALLY CLOSED')) 
         or (p_po_line_closed_flag = 'N' and pol.closed_code not in ('CLOSED','FINALLY CLOSED'))
         or (p_po_line_closed_flag is null and pol.closed_code = pol.closed_code)
		) -- Added as per Version 1.2
    and ph.segment1||''=nvl(p_po_num,ph.segment1) 
    and gcc.code_combination_id=cst.accrual_account_id
    and gcc.segment1 between nvl(p_bal_seg_fr,gcc.segment1) and nvl(p_bal_seg_to,gcc.segment1)
    and (p_min_bal IS NULL OR ((cst.po_balance + cst.ap_balance + cst.write_off_balance) >= p_min_bal))
    and (p_max_bal IS NULL or ((cst.po_balance + cst.ap_balance + cst.write_off_balance) <= p_max_bal))	
    and msi.inventory_item_id=cst.inventory_item_id
    and msi.organization_id+0=441
    and ou.organization_id=cst.operating_unit_id
    and ph.attribute_category = nvl(p_po_type,ph.attribute_category);
    
    cursor c2_po is
    select /*+ LEADING(ph) */
	   sup.segment1,
       sup.vendor_name,
       site.attribute8 site_category,
	   site.vendor_site_code,
       cst.operating_unit_id,
       ou.name,
       ph.segment1 po_num,
       pol.line_num po_line_num,
       poll.shipment_num,
       pod.po_distribution_id,
       pod.distribution_num po_dist_num,
       cst.po_balance,
       cst.ap_balance,
       cst.write_off_balance wo_balance,
       cst.last_receipt_date,
       cst.last_invoice_dist_date,
       msi.segment1 item,
       msi.description item_desc,
       cst.destination_type_code,
        gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7 accr_acct,
        trunc(sysdate - decode(fnd_profile.value('CST_ACCRUAL_AGE_IN_DAYS'),1,nvl(last_receipt_date,LAST_INVOICE_DIST_DATE),greatest(nvl(last_receipt_date,LAST_INVOICE_DIST_DATE), nvl(LAST_INVOICE_DIST_DATE, last_receipt_date))
        )) age_in_days  
    from hr_operating_units ou,
       mtl_system_items_b msi,
       gl_code_combinations gcc, 
       ap_supplier_sites_all site,
       ap_suppliers sup,
       cst_reconciliation_summary cst,
	   po_distributions_all pod,
	   po_line_locations_all poll,
	   po_lines_all pol,
	   po_headers_all ph
    where 1=1
	and ph.segment1=nvl(p_po_num,ph.segment1)
	and ph.vendor_id=nvl(p_vendor_id,ph.vendor_id)
	and pol.po_header_id=ph.po_header_id
	and poll.po_line_id=pol.po_line_id
    and pod.line_location_id=poll.line_location_id
	and pod.org_id=poll.org_id	
	and cst.operating_unit_id=pod.org_id
	and cst.po_distribution_id=pod.po_distribution_id
    and cst.vendor_id+0=ph.vendor_id
    and sup.vendor_id=ph.vendor_id
    and site.vendor_site_id = nvl(p_vendor_site_id,site.vendor_site_id) -- Added as per Version 1.2 by Havish K
    and site.vendor_site_id=ph.vendor_site_id
    and exists (SELECT 'x'       
         FROM xx_fin_translatevalues tv,                                                                        
              xx_fin_translatedefinition td                        
        WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                         
          AND tv.translate_id  = td.translate_id                                                                        
          AND tv.enabled_flag = 'Y'                                                                        
          AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)       
          AND tv.target_value1 = site.attribute8)
    and cst.inventory_item_id=nvl(p_item_id,cst.inventory_item_id)
    and cst.operating_unit_id=nvl(p_ou_id,cst.operating_unit_id)
    and cst.destination_type_code=nvl(p_destination_type,cst.destination_type_code)
    and pod.distribution_num=nvl(p_dist_no,pod.distribution_num)  
    and poll.shipment_num=nvl(p_shipment_no,poll.shipment_num)
    and pol.line_num=nvl(p_po_line_no,pol.line_num)
    and (   (p_po_line_closed_flag = 'Y' and pol.closed_code in ('CLOSED','FINALLY CLOSED'))
         or (p_po_line_closed_flag = 'N' and pol.closed_code not in ('CLOSED','FINALLY CLOSED'))
         or (p_po_line_closed_flag is null and pol.closed_code = pol.closed_code)) -- Added as per Version 1.2
    and gcc.code_combination_id=cst.accrual_account_id
    and gcc.segment1 between nvl(p_bal_seg_fr,gcc.segment1) and nvl(p_bal_seg_to,gcc.segment1)
    and (cst.po_balance + cst.ap_balance + cst.write_off_balance) between nvl(p_min_bal,(cst.po_balance + cst.ap_balance + cst.write_off_balance))
        and nvl(p_max_bal,(cst.po_balance + cst.ap_balance + cst.write_off_balance))
	and trunc(cst.last_receipt_date) between trunc(nvl(to_date(p_rcv_date_from),cst.last_receipt_date))
                 and     trunc(nvl(to_date(p_rcv_date_to),cst.last_receipt_date))
    and msi.inventory_item_id=cst.inventory_item_id
    and msi.organization_id+0=441
    and ou.organization_id=cst.operating_unit_id
    and ph.attribute_category = nvl(p_po_type,ph.attribute_category);
    
    cursor c3_po is
    select /*+ LEADING(pot) */
    sup.segment1,
       sup.vendor_name,
       site.attribute8 site_category,
	   site.vendor_site_code,
       cst.operating_unit_id,
       ou.name,
       ph.segment1 po_num,
       pol.line_num po_line_num,
       poll.shipment_num,
       pod.po_distribution_id,
       pod.distribution_num po_dist_num,
       cst.po_balance,
       cst.ap_balance,
       cst.write_off_balance wo_balance,
       cst.last_receipt_date,
       cst.last_invoice_dist_date,
       msi.segment1 item,
       msi.description item_desc,
       cst.destination_type_code,
        gcc.segment1||'.'||gcc.segment2||'.'||gcc.segment3||'.'||gcc.segment4||'.'||gcc.segment5||'.'||gcc.segment6||'.'||gcc.segment7 accr_acct,
        trunc(sysdate - decode(fnd_profile.value('CST_ACCRUAL_AGE_IN_DAYS'),1,nvl(last_receipt_date,LAST_INVOICE_DIST_DATE),greatest(nvl(last_receipt_date,LAST_INVOICE_DIST_DATE), nvl(LAST_INVOICE_DIST_DATE, last_receipt_date))
        )) age_in_days  
    from hr_operating_units ou,
       mtl_system_items_b msi,
       gl_code_combinations gcc, 
       ap_supplier_sites_all site,
       ap_suppliers sup,
       cst_reconciliation_summary cst,
	   po_distributions_all pod,
	   po_line_locations_all poll,
	   po_lines_all pol,
	   po_headers_all ph,
     (SELECT a.po_header_id,c.po_distribution_id
        from po_distributions_all c,
            po_headers_all a 
          where a.attribute_category = nvl(p_po_type,a.attribute_category)
          and a.segment1=nvl(p_po_num,a.segment1) 
		  and a.vendor_id=nvl(p_vendor_id,a.vendor_id)
		  and a.vendor_site_id=NVL(p_vendor_site_id,a.vendor_site_id)
          and c.po_header_id=a.po_header_id
          and exists (select 'x'
                from cst_Reconciliation_summary
               where po_distribution_id=c.po_distribution_id))  pot
    where 1=1
    and ph.po_header_id=pot.po_header_id
	and pol.po_header_id=ph.po_header_id
	and poll.po_line_id=pol.po_line_id
    and pod.line_location_id=poll.line_location_id
    and pod.po_distribution_id=pot.po_distribution_id	
	and pod.org_id=poll.org_id
	and cst.operating_unit_id=pod.org_id
	and cst.po_distribution_id=pod.po_distribution_id
    and cst.vendor_id+0=ph.vendor_id
    and sup.vendor_id=ph.vendor_id
    and site.vendor_site_id = nvl(p_vendor_site_id,site.vendor_site_id) -- Added as per Version 1.2 by Havish K
    and site.vendor_site_id=ph.vendor_site_id
    and exists (SELECT 'x'       
         FROM xx_fin_translatevalues tv,                                                                        
              xx_fin_translatedefinition td                        
        WHERE td.translation_name = 'XX_AP_TRADE_CATEGORIES'                                                                         
          AND tv.translate_id  = td.translate_id                                                                        
          AND tv.enabled_flag = 'Y'                                                                        
          AND sysdate between tv.start_date_active and nvl(tv.end_date_active,sysdate)       
          AND tv.target_value1 = site.attribute8)
    and cst.inventory_item_id=nvl(p_item_id,cst.inventory_item_id)
    and cst.operating_unit_id=nvl(p_ou_id,cst.operating_unit_id)
    and cst.destination_type_code=nvl(p_destination_type,cst.destination_type_code)
    and pod.distribution_num=nvl(p_dist_no,pod.distribution_num)  
    and poll.shipment_num=nvl(p_shipment_no,poll.shipment_num)
    and pol.line_num=nvl(p_po_line_no,pol.line_num)
    and (   (p_po_line_closed_flag = 'Y' and pol.closed_code in ('CLOSED','FINALLY CLOSED')) 
         or (p_po_line_closed_flag = 'N' and pol.closed_code not in ('CLOSED','FINALLY CLOSED'))
         or (p_po_line_closed_flag is null and pol.closed_code = pol.closed_code)
		) -- Added as per Version 1.2
    and gcc.code_combination_id=cst.accrual_account_id
    and gcc.segment1 between nvl(p_bal_seg_fr,gcc.segment1) and nvl(p_bal_seg_to,gcc.segment1)
    and (p_min_bal IS NULL OR ((cst.po_balance + cst.ap_balance + cst.write_off_balance) >= p_min_bal))
    and (p_max_bal IS NULL or ((cst.po_balance + cst.ap_balance + cst.write_off_balance) <= p_max_bal))	
    and msi.inventory_item_id=cst.inventory_item_id
    and msi.organization_id+0=441
    and ou.organization_id=cst.operating_unit_id
	and TRUNC(NVL(cst.last_receipt_date,SYSDATE)) BETWEEN (CASE WHEN p_rcv_date_from IS NOT NULL THEN TO_DATE(p_rcv_date_from)
                                                               ELSE TRUNC(NVL(cst.last_receipt_date,SYSDATE))
                                                           END) 
                                                          AND 
                                                          (CASE WHEN p_rcv_date_to IS NOT NULL THEN TO_DATE(p_rcv_date_to)
                                                               ELSE TRUNC(NVL(cst.last_receipt_date,SYSDATE))
                                                          END);  	
    

TYPE rcv_wroff is TABLE OF c1_rec%ROWTYPE INDEX BY PLS_INTEGER;
   
/*Cursor c2 to get all the records from xx_ap_rcvwrite_off _stg where request_id=p_request_id and process_flag=1;*/
CURSOR c2 
IS
SELECT *
  FROM xx_ap_rcvwrite_off_stg 
 WHERE request_id=p_request_id 
   AND process_flag=1;
  
l_reason_id   		NUMBER;
l_invalid_po_dist 	VARCHAR2(1);
l_validate_flag 	NUMBER;
reason_code 		VARCHAR2(20);
l_rcv_wroff_tab 	RCV_WROFF;

BEGIN
  IF (    P_vendor_id IS NOT NULL  
       OR P_vendor_site_id IS NOT NULL
	   OR p_po_num IS NOT NULL
	   OR p_po_type IS NOT NULL 
	   
	 )  THEN
 
     OPEN c3_po;  
     FETCH c3_po
     BULK COLLECT INTO l_rcv_wroff_tab;
	 
  ELSIF (p_rcv_date_from IS NOT NULL OR P_rcv_date_to IS NOT NULL) THEN
 
     OPEN c1_rec;  
     FETCH c1_rec
     BULK COLLECT INTO l_rcv_wroff_tab; 
	 
  END IF;
                     
  IF l_rcv_wroff_tab.COUNT > 0  THEN
     FOR i IN l_rcv_wroff_tab.FIRST .. l_rcv_wroff_tab.LAST
     LOOP
       BEGIN           
         INSERT
           INTO XX_AP_RCVWRITE_OFF_STG
                  (
                    org_id,
                    ou_name,
                    vendor_no,
                    vendor_name,
                    site_category,
                    po_number,
                    po_line_num,
                    po_shipment_no,
                    po_distribution_id,
                    po_dist_num,
                    po_balance,
                    ap_balance,
                    wo_balance
                    --, total_balance
                    ,
                    age_in_days,
                    accrual_acct,
                    destination_type ,
                    item,
                    item_desc,
                    process_flag,
                    request_id,
					vendor_site_code
                  )
         VALUES
                  (
                    l_rcv_wroff_tab(i).operating_unit_id,
                    l_rcv_wroff_tab(i).name,
                    l_rcv_wroff_tab(i).segment1,
                    l_rcv_wroff_tab(i).vendor_name,
                    l_rcv_wroff_tab(i).site_category,
                    l_rcv_wroff_tab(i).po_num,
                    l_rcv_wroff_tab(i).po_line_num,
                    l_rcv_wroff_tab(i).shipment_num,
                    l_rcv_wroff_tab(i).po_distribution_id ,
                    l_rcv_wroff_tab(i).po_dist_num,
                    l_rcv_wroff_tab(i).po_balance,
                    l_rcv_wroff_tab(i).ap_balance,
                    l_rcv_wroff_tab(i).wo_balance ,
                    l_rcv_wroff_tab(i).age_in_days,
                    l_rcv_wroff_tab(i).accr_acct,
                    l_rcv_wroff_tab(i).destination_type_code,
                    l_rcv_wroff_tab(i).item,
                    l_rcv_wroff_tab(i).item_desc,
                    1,
                    p_request_id,
					l_rcv_wroff_tab(i).vendor_site_code
                  );
       EXCEPTION
	     WHEN others THEN
		   NULL;
       END;	   
     END LOOP;
  END IF; 
  IF (c2_po%ISOPEN) THEN
      CLOSE c2_po;
  END IF;
    
  IF (c1_rec%ISOPEN) THEN
     CLOSE c1_rec;
  END IF; 
	
  IF (c3_po%ISOPEN) THEN
     CLOSE c3_po;
  END IF;
 
  COMMIT;
    
  FOR Y in C2 LOOP
    L_invalid_po_dist:='N';

    L_validate_flag:=4;	
    /*Based on p_min_age and p_max_age paramters, set process_Flag=3 in the staging table if age_in_days are not in range*/
    If p_min_age IS NOT NULL THEN
       IF y.age_in_days >= p_min_age THEN
          L_validate_flag := 4;
	   ELSE
	      L_validate_flag := 3;
       END IF;
    END IF;
    IF p_max_age IS NOT NULL THEN 
       IF y.age_in_days <= p_max_age THEN 
          L_validate_flag := 4;
       ELSE
          L_validate_flag := 3;	   
       END IF;
    END IF;

    IF Y.site_category='TR-IMP' AND p_min_age IS NOT NULL THEN
       IF Y.age_in_days >= p_min_age THEN
            L_validate_flag:=4;               
       ELSE
            L_validate_flag :=3;               
       END IF;
    END IF;
        
    l_reason_id := p_reason_id;
        
    UPDATE xx_ap_rcvwrite_off_stg 
       SET process_Flag=L_validate_flag,
           reason_id=l_reason_id
     WHERE po_distribution_id = Y.po_distribution_id
	   AND request_id+0 = Y.request_id;

    END LOOP;  

    COMMIT;
    
    IF p_process_mode='FINAL' THEN        

       UPDATE cst_reconciliation_summary 
          SET write_off_select_flag = 'Y'
        WHERE operating_unit_id=p_ou_id 
          AND po_distribution_id IN (SELECT po_distribution_id 
                                       FROM xx_ap_rcvwrite_off_stg 
                                      WHERE request_id=p_request_id
                                        AND process_Flag=4);    
        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in Xx_set_txns: '||SQLERRM);
        FND_FILE.PUT_LINE(FND_FILE.log,'Error in Xx_set_txns: '||SQLERRM);
END xx_set_txns;


-- +======================================================================+
-- | Name             : insert_appo_data_all                              |
-- | Description      : Will be called from Xx_process_writeoff           |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version   Date         Author           Remarks                       |
-- |=======   ==========   =============    ======================        |
-- | 1.0      01-Aug-2017  Sridhar G        Initial Version               |
-- +======================================================================+ 

procedure insert_appo_data_all(
                                p_wo_date in date,
                                p_rea_id in number,
                                p_comments in varchar2,
                                p_sob_id in number,
                                p_ou_id in number,
                                x_count out nocopy number,
                                x_err_num out nocopy number,
                                x_err_code out nocopy varchar2,
                                x_err_msg out nocopy varchar2) is

    l_api_version  constant number := 1.0;
    l_api_name      constant varchar2(30) := 'insert_appo_data_all';
    l_full_name      constant varchar2(60) := g_pkg_name || '.' || l_api_name;
    l_module      constant varchar2(60) := 'cst.plsql.' || l_full_name;
    l_uLog       constant boolean := fnd_log.test(fnd_log.level_unexpected, l_module);
    l_unLog        constant boolean := l_uLog and (fnd_log.level_unexpected >= g_log_level);
    l_errorLog      constant boolean := l_uLog and (fnd_log.level_error >= g_log_level);
    l_exceptionLog constant boolean := l_errorLog and (fnd_log.level_exception >= g_log_level);
    l_pLog       constant boolean := l_exceptionLog and (fnd_log.level_procedure >= g_log_level);
    l_sLog      constant boolean := l_pLog and (fnd_log.level_statement >= g_log_level);
    l_stmt_num      number;
    l_rows       number;
    l_ent_sum      number;
    l_off_id      number;
    l_erv_id      number;
    l_wo_cc      varchar2(30);
    l_wo_ct      varchar2(30);
    l_wo_cr      number;
    l_wo_cd      date;

    /* Cursor to hold all the PO distributions selected in the AP and PO form*/
    cursor c_wo(l_ou_id number) is
    SELECT po_accrual_write_offs_s.nextval l_wo_id,
    (po_balance + ap_balance + write_off_balance) l_tot_bal,
    po_distribution_id,
    accrual_account_id,
    destination_type_code,
    inventory_item_id,
    vendor_id,
    operating_unit_id,
    last_update_date,
    last_updated_by,
    last_update_login,
    creation_date,
    created_by,
    request_id,
    program_application_id,
    program_id,
    program_update_date
  FROM cst_reconciliation_summary
  WHERE operating_unit_id   = l_ou_id
  AND write_off_select_flag = 'Y';

 begin

    l_stmt_num := 5;

    if(l_pLog) then
        fnd_log.string(fnd_log.level_procedure, g_log_header || '.' || l_api_name ||
            '.begin', 'insert_appo_data_all << '
            || 'p_wo_date := ' || to_char(p_wo_date, 'YYYY/MM/DD HH24:MI:SS')
            || 'p_rea_id := ' || to_char(p_rea_id)
            || 'p_comments := ' || p_comments
            || 'p_sob_id := ' || to_char(p_sob_id)
            || 'p_ou_id := ' || to_char(p_ou_id));
    end if;

    /* Print out the parameters to the Message Stack */
    fnd_msg_pub.add_exc_msg(g_pkg_name, l_api_name, 'Write-Off Date: ' || to_char(p_wo_date, 'YYYY/MM/DD HH24:MI:SS'));
    fnd_msg_pub.add_exc_msg(g_pkg_name, l_api_name, 'Write-Off Reason: ' || to_char(p_rea_id));
    fnd_msg_pub.add_exc_msg(g_pkg_name, l_api_name, 'Comments: ' || p_comments);
    fnd_msg_pub.add_exc_msg(g_pkg_name, l_api_name, 'Set of Books: ' || to_char(p_sob_id));
    fnd_msg_pub.add_exc_msg(g_pkg_name, l_api_name, 'Operating Unit: ' || to_char(p_ou_id));

    l_stmt_num := 10;

    /* Make sure user selected PO distributions to write-off */
    select count(*)
    into   l_rows
    from   cst_reconciliation_summary
    where  operating_unit_id = p_ou_id
    and    write_off_select_flag = 'Y';

if(l_rows > 0) then
    l_stmt_num := 15;

    for c_wo_rec in c_wo(p_ou_id) loop
    /* Insert necessary information into SLA events temp table */
        insert into xla_events_int_gt
                (
                application_id,
                ledger_id,
                entity_code,
                source_id_int_1,
                event_class_code,
                event_type_code,
                event_date,
                event_status_code,
                 --BUG#7226250
                security_id_int_2,
                transaction_date,
                 reference_date_1,
                 transaction_number
                )
        values
                (
                707,
                p_sob_id,
                'WO_ACCOUNTING_EVENTS',
                c_wo_rec.l_wo_id,
                'ACCRUAL_WRITE_OFF',
                'ACCRUAL_WRITE_OFF',
                p_wo_date,
                XLA_EVENTS_PUB_PKG.C_EVENT_UNPROCESSED,
                p_ou_id,
                p_wo_date,
                 INV_LE_TIMEZONE_PUB.get_le_day_time_for_ou(p_wo_date,p_ou_id),
                 to_char(c_wo_rec.l_wo_id)
                );

        l_stmt_num := 20;

        /*
          Insert the individual AP and/or PO transactions into
          the write-off details table
        */
        insert into cst_write_off_details
                (
                write_off_id,
                transaction_date,
                amount,
                entered_amount,
                quantity,
                currency_code,
                currency_conversion_type,
                currency_conversion_rate,
                currency_conversion_date,
                transaction_type_code,
                rcv_transaction_id,
                invoice_distribution_id,
                write_off_transaction_id,
                inventory_organization_id,
                operating_unit_id,
                 last_update_date,
                 last_updated_by,
                 last_update_login,
                 creation_date,
                 created_by,
                 request_id,
                 program_application_id,
                 program_id,
                 program_update_date,
                 ae_header_id,
                 ae_line_num
                )
            select c_wo_rec.l_wo_id,
            capr.transaction_date,
            capr.amount,
            capr.entered_amount,
            capr.quantity,
            capr.currency_code,
            capr.currency_conversion_type,
            capr.currency_conversion_rate,
            capr.currency_conversion_date,
            capr.transaction_type_code,
            capr.rcv_transaction_id,
            capr.invoice_distribution_id,
            capr.write_off_id,
            capr.inventory_organization_id,
            capr.operating_unit_id,
            sysdate,                     --last_update_date,
            FND_GLOBAL.USER_ID,          --last_updated_by,
            FND_GLOBAL.USER_ID,          --last_update_login,
            sysdate,                     --creation_date,
            FND_GLOBAL.USER_ID,          --created_by,
            FND_GLOBAL.CONC_REQUEST_ID,  --request_id,
            FND_GLOBAL.PROG_APPL_ID,     --program_application_id,
            FND_GLOBAL.CONC_PROGRAM_ID,  --program_id,
            sysdate,                     --program_update_date,
            capr.ae_header_id,
            capr.ae_line_num
            from   cst_ap_po_reconciliation  capr
            where  capr.po_distribution_id = c_wo_rec.po_distribution_id
            and    capr.accrual_account_id = c_wo_rec.accrual_account_id
            and    capr.operating_unit_id  = c_wo_rec.operating_unit_id;

        l_stmt_num := 25;

        /* Get the sum of the entered amount */
        select sum(capr.entered_amount)
        into   l_ent_sum
        from   cst_ap_po_reconciliation capr
        where  capr.po_distribution_id = c_wo_rec.po_distribution_id
        and    capr.accrual_account_id = c_wo_rec.accrual_account_id
        and    capr.operating_unit_id  = c_wo_rec.operating_unit_id;

        /* Get all the currency information and offset/erv accounts based on the PO match type */
        /* the offset account is selected as follows.If the destination type code is Expense, get the charge account
         else get the variance account from the po distribution */

        select decode(pod.destination_type_code,'EXPENSE',pod.code_combination_id,
                                                         pod.variance_account_id),
                decode(poll.match_option, 'P', pod.variance_account_id,
                        decode(pod.destination_type_code,'EXPENSE', pod.code_combination_id,-1)),
                poh.currency_code,
                poh.rate_type,
                --
                --BUG#9191539: The exchange rate date for PO:PO_RATE_DATE - For Receipt:Write Off Date
                --
                DECODE(poll.match_option, 'P',NVL(pod.rate_date,TRUNC(pod.creation_date))
                    ,NVL(p_wo_date,TRUNC(SYSDATE)))
            into   
                l_off_id,
                l_erv_id,
                l_wo_cc,
                l_wo_ct,
                l_wo_cd
        from   po_distributions_all    pod,
              po_line_locations_all   poll,
              po_headers_all          poh
        where  pod.po_distribution_id = c_wo_rec.po_distribution_id
        and    pod.org_id = p_ou_id
        and    poh.po_header_id = pod.po_header_id
        and    poll.line_location_id = pod.line_location_id;

        l_stmt_num := 26;

    /* For the case of match to receipt, when NO rate is defined, use the rate and the currency conversion date from
      the po header */

        BEGIN
            select decode(poll.match_option, 'P',NVL(pod.rate,1),
                            gl_currency_api.get_rate(poh.currency_code, gsb.currency_code,
                            trunc(p_wo_date),poh.rate_type))
                into 
                l_wo_cr
            from  po_distributions_all   pod,
                po_line_locations_all  poll,
                po_headers_all         poh,
                gl_sets_of_books       gsb
            where pod.po_distribution_id  = c_wo_rec.po_distribution_id
            and pod.org_id              = p_ou_id
            and poh.po_header_id        = pod.po_header_id
            and poll.line_location_id   = pod.line_location_id
            and gsb.set_of_books_id     = pod.set_of_books_id ;
        EXCEPTION
        WHEN gl_currency_api.NO_RATE THEN
            Select NVL(pod.rate,1),
                 NVL(pod.rate_date,TRUNC(pod.creation_date))
            into l_wo_cr,
                 l_wo_cd
            from po_distributions_all pod
            where pod.po_distribution_id = c_wo_rec.po_distribution_id
            and pod.org_id             = p_ou_id ;
        END;

        l_stmt_num := 28;

        /* Need to further determine ERV account if erv_id = -1 */

        if(((l_wo_cr is null) or (l_ent_sum is null)) and (l_erv_id is not null)) then
            l_erv_id := null;    
        elsif(l_erv_id = -1) then
            if(c_wo_rec.l_tot_bal > (l_wo_cr * l_ent_sum)) then    
                select  rate_var_gain_ccid
                into    l_erv_id
                from    financials_system_params_all
                where   org_id = p_ou_id;
        else    
            select  rate_var_loss_ccid
            into    l_erv_id
            from    financials_system_params_all
            where   org_id = p_ou_id;
        end if; /* c_wo_rec.l_tot_bal > (l_wo_cr + l_ent_sum) */
        --}
        end if; /* ((l_wo_cr is null) or (l_ent_sum is null)) and (l_erv_id is not null) */

        l_stmt_num := 30;

    /*
      Insert the PO distribution information, as well as the extra values
      recently calcuated into the write-off headers table.
    */
        insert into cst_write_offs
            (
            write_off_id,
            transaction_date,
            accrual_account_id,
            offset_account_id,
            erv_account_id,
            write_off_amount,
            entered_amount,
            currency_code,
            currency_conversion_type,
            currency_conversion_rate,
            currency_conversion_date,
            transaction_type_code,
            po_distribution_id,
            reason_id,
            comments,
            destination_type_code,
            inventory_item_id,
            vendor_id,
            operating_unit_id,
            last_update_date,
            last_updated_by,
            last_update_login,
            creation_date,
            created_by,
            request_id,
            program_application_id,
            program_id,
            program_update_date
            )
        values
            (
            c_wo_rec.l_wo_id,
            p_wo_date,
            c_wo_rec.accrual_account_id,
            l_off_id,
            l_erv_id,
            (-1) * c_wo_rec.l_tot_bal,
            (-1) * l_ent_sum,
            l_wo_cc,
            l_wo_ct,
            l_wo_cr,
            l_wo_cd,
            'WRITE OFF',
            c_wo_rec.po_distribution_id,
            p_rea_id,
            p_comments,
            c_wo_rec.destination_type_code,
            c_wo_rec.inventory_item_id,
            c_wo_rec.vendor_id,
            p_ou_id,
            sysdate,                     
            FND_GLOBAL.USER_ID,          
            FND_GLOBAL.USER_ID,          
            sysdate,                     
            FND_GLOBAL.USER_ID,          
            FND_GLOBAL.CONC_REQUEST_ID,  
            FND_GLOBAL.PROG_APPL_ID,     
            FND_GLOBAL.CONC_PROGRAM_ID,  
            sysdate                      
            );
    
    end loop; /* for c_wo_rec in c_wo(p_ou_id) */

    l_stmt_num := 35;
    /*
    First delete the individual transactions from cst_ap_po_reconciliation
    as to maintain referential integretiy.
    */
    delete from cst_ap_po_reconciliation capr
    where  exists (
        select 'X'
    from   cst_reconciliation_summary crs
    where  capr.operating_unit_id  = crs.operating_unit_id
    and    capr.po_distribution_id = crs.po_distribution_id
    and    capr.accrual_account_id = crs.accrual_account_id
    and    crs.write_off_select_flag = 'Y');

    l_stmt_num := 40;

    /*
    Once all the individual transaction have been deleted, removed the
    header information from cst_reconciliation_summary
     */
    delete from cst_reconciliation_summary
    where  operating_unit_id = p_ou_id
    and    write_off_select_flag = 'Y';

    l_stmt_num := 45;
    /*
    Call SLA's bulk events generator which uses the values previously
    inserted into SLA's event temp table
    */
    xla_events_pub_pkg.create_bulk_events(p_source_application_id => 201,
                                       p_application_id => 707,
                       p_ledger_id => p_sob_id,
                       p_entity_type_code => 'WO_ACCOUNTING_EVENTS');

    commit;

else

 x_count := -1;
 return;

end if; /* l_rows > 0 */

x_count :=  l_rows;
return;

exception
    when others then
        rollback;
        x_count := -1;
        x_err_num := SQLCODE;
        x_err_code := NULL;
        x_err_msg := 'CST_Accrual_Rec_PVT.insert_appo_data_all() ' || SQLERRM;
        fnd_message.set_name('BOM','CST_UNEXPECTED');
        fnd_message.set_token('TOKEN',SQLERRM);
        
        if(l_unLog) then
            fnd_log.message(fnd_log.level_unexpected, g_log_header || '.' || l_api_name
             || '(' || to_char(l_stmt_num) || ')', FALSE);
        end if;
        
        fnd_msg_pub.add;
        return;
end insert_appo_data_all;
end XX_CST_ACR_WRTOFF_PKG;
/
SHOW ERRORS;