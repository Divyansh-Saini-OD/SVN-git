create or replace package body      XX_CST_ACR_WRTOFF_PKG AS
/* $Header: CSTACRHB.pls 120.24 2010/07/28 16:33:39 hyu ship $ */

G_PKG_NAME 	constant varchar2(30) := 'CST_Accrual_Rec_PVT';
G_LOG_HEADER	constant varchar2(40) := 'cst.plsql.CST_Accrual_Rec_PVT';
G_LOG_LEVEL	constant number       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;

  -- Start of comments
 --	API name 	: Insert_Appo_Data_All
 --	Type		: Private
 --	Pre-reqs	: None.
 --	Function	: Write-off PO distributions selected in the AP and PO
 --   		          Accrual Write-Off Form in Costing tables.  Proecedue will also generate
 --   			  Write-Off events in SLA.  A single write-off event will be generated
 --   			  regardless of the number of transactions that make up the PO distribution.
 --   			  At the end, all the written-off PO distributions
 --   			  and individual AP and PO transactions are removed from
 --   			  cst_reconciliation_summary and cst_ap_po_reconciliation..
 --	Parameters	:
 --	IN		: p_wo_date	IN DATE			Required
 --				Write-Off Date
 -- 			: p_rea_id	IN NUMBER		Optional
 --				Write-Off Reason
 --			: p_comments	IN VARCHAR2		Optional
 --				Write-Off Comments
 --			: p_sob_id	IN NUMBER		Required
 --				Ledger/Set of Books
 --			: p_ou_id	IN NUMBER		Required
 --				Operating Unit Identifier
 --     OUT             : x_count      	OUT NOCOPY NUBMER	Required
 --  			        Success Indicator
 --				{x > 0} => Success
 --				-1	=> Failure
 --                     : x_err_num	OUT NOCOPY NUMBER	Required
 --                             Standard Error Parameter
 --                     : x_err_code	OUT NOCOPY VARCHAR2	Required
 --                             Standard Error Parameter
 --                     : x_err_msg	OUT NOCOPY VARCHAR2	Required
 --                             Standard Error Parameter
 --	Version	: Current version	1.0
 --		  Previous version 	1.0
 --		  Initial version 	1.0
 -- End of comments
PROCEDURE Xx_process_writeoff(x_errbuf          OUT NOCOPY     VARCHAR2,
						x_retcode         OUT NOCOPY     NUMBER,
						P_OU_ID number,
						P_ACCRUAL_ACCT_ID number,
						P_bal_seg_fr varchar2,
						P_bal_Seg_to varchar2,
						P_vendor_id number,
						P_inv_source varchar2,
						P_rcv_date_from date,
						P_rcv_date_to date,
						P_item_id number,
						P_po_num varchar2,
						P_po_line_no varchar2,
						P_shipment_no varchar2,
						P_dist_no varchar2,
						P_destination_type varchar2,
						p_reason_id in number,
            p_po_type in varchar2,
						P_min_age number,
						P_max_age number,
						P_min_bal number,
						P_max_bal number,
						P_process_mode varchar2) IS
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


BEGIN					 

FND_FILE.PUT_LINE(FND_FILE.log,'Before calling the xx_set_txns');

xx_set_txns(p_ou_id,
P_ACCRUAL_ACCT_ID,
P_bal_seg_fr,
P_bal_Seg_to,
P_vendor_id,
P_inv_source,
P_rcv_date_from,
P_rcv_date_to,
P_item_id,
P_po_num,
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
FND_FILE.PUT_LINE(FND_FILE.log,'After called the xx_set_txns');
IF p_process_mode='RUN' THEN
     FOR x in C1 
     LOOP
	  FND_FILE.PUT_LINE(FND_FILE.log,'Inside the Loop!');
      
	   begin
		  select reason_id into l_reason_id
		  from xx_ap_rcvwrite_off_stg stg
		  where stg.po_distribution_id = x.po_distribution_id
		  and request_id = Gn_request_id;
		exception
			when others then
				FND_FILE.PUT_LINE(FND_FILE.log,'l_reason_id: '||SQLERRM||' : '||x.po_distribution_id);
	   end;
	   
	   begin
			select set_of_books_id into l_sob_id 
			from po_distributions_all pda
			where pda.po_distribution_id = x.po_distribution_id;
			
	   exception
			when others then
				FND_FILE.PUT_LINE(FND_FILE.log,'l_sob_id: '||SQLERRM||' : '||x.po_distribution_id);
	   end;
	   FND_FILE.PUT_LINE(FND_FILE.log,'Before calling insert_appo_data_all !');
	   insert_appo_data_all(
 			        SYSDATE,--p_wo_date in date,
			        l_reason_id,
			    	'TEST1',
			    	l_sob_id,
			    	x.operating_unit_id,
   		            	l_count,--x_count out nocopy number,
		            	l_err_num,--x_err_num out nocopy number,
	                    	l_err_code,--x_err_code out nocopy varchar2,
		            	l_err_msg--x_err_msg out nocopy varchar2
						);
		FND_FILE.PUT_LINE(FND_FILE.log,'Before calling insert_appo_data_all !');				
     END LOOP
	 COMMIT;
   END IF;
   IF p_process_mode='RUN' THEN
	Update XX_AP_RCVWRITE_OFF_STG a 
	set process_flag=7 
	where request_id=gn_request_id
	and not exists (select 'x'
					from cst_reconciliation_summary
					where operating_unit_id =a.org_id
					and po_distribution_id=a.po_distribution_id
					and write_off_select_flag = 'Y');
					
					
	Update XX_AP_RCVWRITE_OFF_STG a 
    set process_flag=6 
	where request_id=gn_request_id
    and exists (select 'x'
	            from cst_reconciliation_summary
           where operating_unit_id =a.org_id
             and po_distribution_id=a.po_distribution_id
                       and write_off_select_flag = 'Y'
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
   submit_rcv_write_off_report(gn_request_id);
   
EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Error in Xx_process_writeoff: '||SQLERRM);
		FND_FILE.PUT_LINE(FND_FILE.log,'Error in Xx_process_writeoff: '||SQLERRM);
END Xx_process_writeoff;

 /*THis prcedure will be called from Xx_process_writeoff*/
PROCEDURE submit_rcv_write_off_report(P_request_id IN NUMBER) IS
ln_request_id number:=NULL;
lb_layout     BOOLEAN:= NULL;
BEGIN
lb_layout := FND_REQUEST.ADD_LAYOUT
                ('XXFIN',
                 'XXAPRCVWRTOFFREP',
                 'en',
                 'US',
                 'PDF');
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
						argument1    =>  P_request_id
						);
  exception          
	WHEN OTHERS THEN
			fnd_file.put_line (fnd_file.LOG, 'Error ln_request_id: '||ln_request_id);
    END;					
							
EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Error in Xx_process_writeoff: '||SQLERRM);
	FND_FILE.PUT_LINE(FND_FILE.log,'Error in Xx_process_writeoff: '||SQLERRM);						
END submit_rcv_write_off_report;
/*This procedure will be called from Xx_process_writeoff*/
PROCEDURE Xx_set_txns(p_ou_id in Number,
P_ACCRUAL_ACCT_ID number,
P_bal_seg_fr in varchar2,
P_bal_Seg_to in varchar2,
P_vendor_id in number,
P_inv_source in varchar2,
P_rcv_date_from in date,
P_rcv_date_to in date,
P_item_id in number,
P_po_num in varchar2,
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
/*Cursor c1 to get all the records from cst_reconciliation_summary based on the parameters(Ref Appendix 2 Sql 3)*/
  cursor c1 is
  select sup.segment1,
	   sup.vendor_name,
	   site.attribute8 site_category,
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
       po_headers_all ph,
       po_lines_all pol,
       po_line_locations_all poll,
       po_distributions_all pod,
	   ap_supplier_sites_all site,
       ap_suppliers sup,
       cst_reconciliation_summary cst
where 1=1
  and sup.vendor_id=cst.vendor_id
  and pod.po_distribution_id=cst.po_distribution_id
  and pod.org_id=cst.operating_unit_id
  and poll.line_location_id=pod.line_location_id
  and poll.org_id=pod.org_id
  and pol.po_line_id=poll.po_line_id
  and ph.po_header_id=pol.po_header_id
  and sup.vendor_id=nvl(p_vendor_id,sup.vendor_id)
  and site.vendor_id=ph.vendor_id
  and site.vendor_site_id=ph.vendor_site_id
  --and site.attribute8 like 'TR%'--  ‘TR%’/*Krishna requested to pickup all the Invoices instead of just Trade*/
  and cst.inventory_item_id=nvl(p_item_id,cst.inventory_item_id)
  and cst.accrual_account_id=nvl(p_accrual_acct_id,cst.accrual_account_id)
  and cst.operating_unit_id=nvl(p_ou_id,cst.operating_unit_id)
  and cst.destination_type_code=nvl(p_destination_type,cst.destination_type_code)
  and pod.distribution_num=nvl(p_dist_no,pod.distribution_num)  
  and poll.shipment_num=nvl(p_shipment_no,poll.shipment_num)
  and pol.line_num=nvl(p_po_line_no,pol.line_num)
  and ph.segment1=nvl(p_po_num,ph.segment1)
  and trunc(cst.last_receipt_date) between nvl(p_rcv_date_from,trunc(cst.last_receipt_date)) and nvl(p_rcv_date_to,trunc(cst.last_receipt_date))
  and gcc.code_combination_id=cst.accrual_account_id
  and gcc.segment1 between nvl(p_bal_seg_fr,gcc.segment1) and nvl(p_bal_seg_to,gcc.segment1)
  and (cst.po_balance + cst.ap_balance + cst.write_off_balance) between nvl(p_min_bal,(cst.po_balance + cst.ap_balance + cst.write_off_balance))
		and nvl(p_max_bal,(cst.po_balance + cst.ap_balance + cst.write_off_balance))
  and msi.inventory_item_id=cst.inventory_item_id
  and msi.organization_id+0=441
  and ou.organization_id=cst.operating_unit_id
  and ph.ATTRIBUTE_CATEGORY = nvl(p_po_type,ph.ATTRIBUTE_CATEGORY)
  and P_inv_source is null
  
  union
  
  select sup.segment1,
	   sup.vendor_name,
	   site.attribute8 site_category,
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
       po_headers_all ph,
       po_lines_all pol,
       po_line_locations_all poll,
       po_distributions_all pod,
	   ap_supplier_sites_all site,
       ap_suppliers sup,
       cst_reconciliation_summary cst
where 1=1
  and sup.vendor_id=cst.vendor_id
  and pod.po_distribution_id=cst.po_distribution_id
  and pod.org_id=cst.operating_unit_id
  and poll.line_location_id=pod.line_location_id
  and poll.org_id=pod.org_id
  and pol.po_line_id=poll.po_line_id
  and ph.po_header_id=pol.po_header_id
  and sup.vendor_id=nvl(p_vendor_id,sup.vendor_id)
  and site.vendor_id=ph.vendor_id
  and site.vendor_site_id=ph.vendor_site_id
--  and site.attribute8 like 'TR%' /*Krishna requested to pickup all the Invoices instead of just Trade*/
  and cst.inventory_item_id=nvl(p_item_id,cst.inventory_item_id)
  and cst.accrual_account_id=nvl(p_accrual_acct_id,cst.accrual_account_id)
  and cst.operating_unit_id=nvl(p_ou_id,cst.operating_unit_id)
  and cst.destination_type_code=nvl(p_destination_type,cst.destination_type_code)
  and pod.distribution_num=nvl(p_dist_no,pod.distribution_num)  
  and poll.shipment_num=nvl(p_shipment_no,poll.shipment_num)
  and pol.line_num=nvl(p_po_line_no,pol.line_num)
  and ph.segment1=nvl(p_po_num,ph.segment1)
  and trunc(cst.last_receipt_date) between nvl(p_rcv_date_from,trunc(cst.last_receipt_date)) and nvl(p_rcv_date_to,trunc(cst.last_receipt_date))
  and gcc.code_combination_id=cst.accrual_account_id
  and gcc.segment1 between nvl(p_bal_seg_fr,gcc.segment1) and nvl(p_bal_seg_to,gcc.segment1)
  and (cst.po_balance + cst.ap_balance + cst.write_off_balance) between nvl(p_min_bal,(cst.po_balance + cst.ap_balance + cst.write_off_balance))
		and nvl(p_max_bal,(cst.po_balance + cst.ap_balance + cst.write_off_balance))
  and msi.inventory_item_id=cst.inventory_item_id
  and msi.organization_id+0=441
  and ou.organization_id=cst.operating_unit_id  
  and exists (select 'x'
			    from ap_invoices_all ai,
					 ap_invoice_distributions_all f
			   where f.po_distribution_id=cst.po_distribution_id
			     and ai.invoice_id=f.invoice_id
				 and ai.source=nvl(p_inv_source,ai.source)
     		 )
  and ph.ATTRIBUTE_CATEGORY = nvl(p_po_type,ph.ATTRIBUTE_CATEGORY)
  and P_inv_source is not null;

  
  /*Cursor c2 to get all the records from xx_ap_rcvwrite_off _stg where request_id=p_request_id and process_flag=1;*/
  cursor c2 is
  select *
  from xx_ap_rcvwrite_off_stg 
  where request_id=p_request_id 
  and process_flag=1;
  /*Cursor c3 to get all invoices for the po_distribution with Validation and Accouting Status(Refer Appendix 2 Sql 1)*/
  Cursor c3 (p_distribution_id in number) is
	select distinct 
       ai.invoice_id,
       AP_INVOICES_PKG.GET_APPROVAL_STATUS(ai.invoice_id, 
                                           ai.invoice_amount,
                                           ai.payment_status_flag,
                                           ai.invoice_type_lookup_code
                                          ) invoice_status,
      AP_INVOICES_PKG.GET_POSTING_STATUS(ai.invoice_id) posting_status
 from  ap_invoices_all ai,
       ap_invoice_distributions_all f
 where f.po_distribution_id=p_distribution_id
   and ai.invoice_id=f.invoice_id;
l_reason_id   number;
l_invalid_po_dist varchar2(1);
l_validate_flag NUMBER;
reason_code varchar2(20);
BEGIN
For x in c1 
  LOOP

    Insert into XX_AP_RCVWRITE_OFF_STG(org_id, ou_name, vendor_no, vendor_name, site_category, po_number, 
	po_line_num, po_shipment_no, po_distribution_id, po_dist_num, po_balance, ap_balance, wo_balance
	--, total_balance
	, age_in_days, accrual_acct, destination_type
	, item, item_desc, process_flag, request_id) 
	
	values (x.operating_unit_id, x.name, x.segment1, x.vendor_name, x.site_category, x.po_num, 
	x.po_line_num, x.shipment_num, x.po_distribution_id
	,x.po_dist_num, x.po_balance, x.ap_balance, x.wo_balance
	, x.age_in_days, x.accr_acct, x.destination_type_code, x.item, x.item_desc, 1, p_request_id);

  END LOOP;
  commit;

FOR Y in C2 LOOP
	L_invalid_po_dist:='N';
  FND_FILE.PUT_LINE(FND_FILE.log,'step1 y.process_flag '||y.process_flag);
  /*
	FOR Z in C3(Y.po_distribution_id) LOOP
		IF Z.invoice_status<>'APPROVED' OR  Z.posting_status<>'Y' THEN
      	 L_invalid_po_dist:='Y';
    
    END IF;
	END LOOP;*/
	
	IF l_invalid_po_dist='Y' THEN   
		L_validate_flag :=3;			   
  ELSE
		L_validate_flag :=4;			   
  END IF;

  /*Based on p_min_age and p_max_age paramters, set process_Flag=3 in the staging table if age_in_days are not in range*/
	If p_min_age is not null then
		L_validate_flag := 3;
		if y.age_in_days > p_min_age then
			L_validate_flag := 4;
		end if;
	end if;
	If p_max_age is not null then 
		L_validate_flag := 3;
		if y.age_in_days < p_min_age then 
			L_validate_flag := 4;
		end if;
	end if;
  
    FND_FILE.PUT_LINE(FND_FILE.log,'step2 y.process_flag '||y.process_flag);

    IF Y.site_category='TR-IMP' THEN
       IF Y.age_in_days > 10 THEN
        L_validate_flag:=4;			   
       ELSE
		L_validate_flag :=3;			   
       END IF;
    END IF;
	
	
	/*This section needs to be updated with proper reason Codes*/
	l_reason_id := p_reason_id;
	/*
	IF Y.site_category='TR-FRONTDOOR' THEN
		reason_code := 'OD Write-off';
	ELSIF Y.site_category= 'TR-IMP' THEN 
		reason_code := 'OD Write-off';
	ELSE 
    reason_code := 'OD Write-off';
	END IF;*/
/*
	BEGIN
		SELECT reason_id into l_reason_id
		from mtl_transaction_reasons 
		where reason_name=reason_code;
	EXCEPTION
		WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Error in getting reason id: '||SQLERRM);
		FND_FILE.PUT_LINE(FND_FILE.log,'Error in getting reason id: '||SQLERRM);
	END;
	*/
    
     Update xx_ap_rcvwrite_off_stg 
	 set process_Flag=decode(l_validate_flag,4,4,3),
	 reason_id=l_reason_id
     where po_distribution_id = Y.po_distribution_id;
	 

END LOOP;  



	
	Commit;
    
	IF p_process_mode='RUN' THEN		

		Update cst_reconciliation_summary 
		set write_off_select_flag = 'Y'
		Where operating_unit_id=p_ou_id 
		and po_distribution_id in (select po_distribution_id 
									from xx_ap_rcvwrite_off_stg 
									where request_id=p_request_id
									And process_Flag=4);	
		Commit;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Error in Xx_set_txns: '||SQLERRM);
		FND_FILE.PUT_LINE(FND_FILE.log,'Error in Xx_set_txns: '||SQLERRM);
END Xx_set_txns;


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
   l_api_name	  constant varchar2(30) := 'insert_appo_data_all';
   l_full_name	  constant varchar2(60) := g_pkg_name || '.' || l_api_name;
   l_module	  constant varchar2(60) := 'cst.plsql.' || l_full_name;
   l_uLog 	  constant boolean := fnd_log.test(fnd_log.level_unexpected, l_module);
   l_unLog        constant boolean := l_uLog and (fnd_log.level_unexpected >= g_log_level);
   l_errorLog	  constant boolean := l_uLog and (fnd_log.level_error >= g_log_level);
   l_exceptionLog constant boolean := l_errorLog and (fnd_log.level_exception >= g_log_level);
   l_pLog 	  constant boolean := l_exceptionLog and (fnd_log.level_procedure >= g_log_level);
   l_sLog	  constant boolean := l_pLog and (fnd_log.level_statement >= g_log_level);
   l_stmt_num	  number;
   l_rows 	  number;
   l_ent_sum	  number;
   l_off_id	  number;
   l_erv_id	  number;
   l_wo_cc	  varchar2(30);
   l_wo_ct	  varchar2(30);
   l_wo_cr	  number;
   l_wo_cd	  date;

   /* Cursor to hold all the PO distributions selected in the AP and PO form*/
   cursor c_wo(l_ou_id number) is
   select po_accrual_write_offs_s.nextval l_wo_id,
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
   from   cst_reconciliation_summary
   where  operating_unit_id = l_ou_id
   and    write_off_select_flag = 'Y';

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
 --{
     l_stmt_num := 15;

     for c_wo_rec in c_wo(p_ou_id) loop
   --{
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
                                                         pod.variance_account_id
                    ),
  	      decode(poll.match_option, 'P', pod.variance_account_id,
 	        decode(pod.destination_type_code,'EXPENSE', pod.code_combination_id,-1)),
	      poh.currency_code,
	      poh.rate_type,
	      --
	      --BUG#9191539: The exchange rate date for PO:PO_RATE_DATE - For Receipt:Write Off Date
	      --
	      DECODE(poll.match_option, 'P',NVL(pod.rate_date,TRUNC(pod.creation_date))
                ,NVL(p_wo_date,TRUNC(SYSDATE)))
       into   l_off_id,
          l_erv_id,
          l_wo_cc,
          l_wo_ct,
	      l_wo_cd
       from   po_distributions_all    pod,
              po_line_locations_all   poll,
	          po_headers_all	      poh
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
                                              trunc(p_wo_date),poh.rate_type)
                    )
          into l_wo_cr
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
     --{
         l_erv_id := null;
     --}
       elsif(l_erv_id = -1) then
     --{
         if(c_wo_rec.l_tot_bal > (l_wo_cr * l_ent_sum)) then
       --{
           select  rate_var_gain_ccid
           into    l_erv_id
           from    financials_system_params_all
           where   org_id = p_ou_id;
       --}
         else
       --{
           select  rate_var_loss_ccid
           into    l_erv_id
           from    financials_system_params_all
           where   org_id = p_ou_id;
       --}
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
   	 sysdate,                     --last_update_date,
   	 FND_GLOBAL.USER_ID,          --last_updated_by,
   	 FND_GLOBAL.USER_ID,          --last_update_login,
   	 sysdate,                     --creation_date,
   	 FND_GLOBAL.USER_ID,          --created_by,
   	 FND_GLOBAL.CONC_REQUEST_ID,  --request_id,
   	 FND_GLOBAL.PROG_APPL_ID,     --program_application_id,
   	 FND_GLOBAL.CONC_PROGRAM_ID,  --program_id,
   	 sysdate                      --program_update_date
       );
   --}
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
 --}
   else
 --{
     x_count := -1;
     return;
 --}
   end if; /* l_rows > 0 */

   x_count :=  l_rows;
   return;

   exception
     when others then
   --{
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
   --}
 end insert_appo_data_all;
 
end XX_CST_ACR_WRTOFF_PKG;