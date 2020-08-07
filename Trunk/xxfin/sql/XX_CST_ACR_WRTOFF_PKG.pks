create or replace package      XX_CST_ACR_WRTOFF_PKG AUTHID CURRENT_USER AS
/* $Header: CSTACRHS.pls 120.1.12010000.1 2008/07/24 17:19:17 appldev ship $ */

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
						P_process_mode varchar2); /*Main Procedure which initiates the process*/

PROCEDURE submit_rcv_write_off_report(P_request_id IN NUMBER);					 
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
);			 
 procedure insert_appo_data_all(
 			    	p_wo_date in date,
			    	p_rea_id in number,
			    	p_comments in varchar2,
				p_sob_id in number,
			    	p_ou_id in number,
   		                x_count out nocopy number,
		                x_err_num out nocopy number,
	                        x_err_code out nocopy varchar2,
		                x_err_msg out nocopy varchar2);

 END XX_CST_ACR_WRTOFF_PKG;