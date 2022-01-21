create or replace package XX_CST_ACR_WRTOFF_PKG AUTHID CURRENT_USER AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CST_ACR_WRTOFF_PKG.pks                             	 |
-- | Description :  Receiver Write Off	Package                              |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       01-AUG-2017 Sridhar G.	     Initial version                 |
-- |1.1       11-Oct-2017 Paddy Sanjeevi     Modified p_reason_id to code    |
-- |1.2       06-DEC-2017 Havish Kasina      Added p_vendor_site_id          |
-- |1.3       11-Jan-2018 Paddy Sanjeevi     p_rcv_date_from date to varchar2|
-- +=========================================================================+


-- +=====================================================================+
-- | Name  : Xx_process_writeoff                                         |
-- | Description     : Main Procedure Xx_process_writeoff which is          |
-- |                   called from the Concurrent Program                   |
-- |                                                                        |
-- | Parameters      : P_OU_ID                                             |
-- |                    P_ACCRUAL_ACCT_ID                                   |
-- |                    P_bal_seg_fr                                       |
-- |                    P_bal_Seg_to                                       |
-- |                    P_vendor_id                                       |
-- |                    P_vendor_site_id                                 |
-- |                    P_rcv_date_from                                   |
-- |                    P_rcv_date_to date                                  |
-- |                    P_item_id                                          |
-- |                    P_po_num                                           |
-- |                    P_po_line_no                                       |
-- |                    P_shipment_no                                       |
-- |                    P_dist_no                                           |
-- |                    P_destination_type                               |
-- |                    P_process_mode                                   |
-- |                    p_reason_id                                        |
-- |                    p_po_type                                           |
-- |                    P_min_age                                           |
-- |                    P_max_age                                           |
-- |                    P_min_bal                                           |
-- |                    P_max_bal                                           |
-- |                                                                       |
-- +=====================================================================+ 
PROCEDURE Xx_process_writeoff(x_errbuf          OUT NOCOPY     VARCHAR2,
                        x_retcode         OUT NOCOPY     NUMBER,
                        P_OU_ID number,
                        P_ACCRUAL_ACCT_ID number,
                        P_bal_seg_fr varchar2,
                        P_bal_Seg_to varchar2,
                        P_vendor_id number,
                        P_vendor_site_id number,
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
                        ); 

                        
-- +=====================================================================+
-- | Name  : submit_rcv_write_off_report                                 |
-- | Description     :                                                       |
-- |                                                                          |
-- |                                                                        |
-- | Parameters      : P_request_id                                         |
-- |                    p_process_mode                                   |
-- +=====================================================================+
PROCEDURE submit_rcv_write_off_report(P_request_id IN NUMBER, 
                                    p_process_mode in Varchar2);        

-- +=====================================================================+
-- | Name  : Xx_set_txns                                                 |
-- | Description     :                                                       |
-- |                                                                          |
-- |                                                                        |
-- | Parameters      :  p_ou_id                                             |    
-- |                    P_ACCRUAL_ACCT_ID                                   |
-- |                    P_bal_seg_fr                                       |
-- |                    P_bal_Seg_to                                       |
-- |                    P_vendor_id                                       |
-- |                    P_vendor_site_id                                 |
-- |                    P_rcv_date_from                                   |
-- |                    P_rcv_date_to date                                  |
-- |                    P_item_id                                          |
-- |                    P_po_num                                           |
-- |                    P_po_line_no                                       |
-- |                    P_shipment_no                                       |
-- |                    P_dist_no                                           |
-- |                    P_destination_type                               |
-- |                    P_min_age                                           |
-- |                    P_max_age                                           |
-- |                    P_min_bal                                           |
-- |                    P_max_bal                                           |
-- |                    P_process_mode                                   |
-- |                    P_request_id                                        |
-- |                    p_reason_id                                        |
-- |                    p_po_type                                           |
-- +=====================================================================+                                    
PROCEDURE Xx_set_txns(p_ou_id in Number,
                        P_ACCRUAL_ACCT_ID number,
                        P_bal_seg_fr in varchar2,
                        P_bal_Seg_to in varchar2,
                        P_vendor_id in number,
                        P_vendor_site_id number,
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
                        );             

-- +=====================================================================+
-- | Name  : insert_appo_data_all                                         |
-- | Description     :                                                       |
-- |                                                                          |
-- |                                                                        |
-- | Parameters      :  p_wo_date                                         |    
-- |                    p_rea_id                                            |
-- |                    p_comments                                       |
-- |                    p_sob_id                                            |
-- |                    p_ou_id                                            |
-- |                    x_count                                            |
-- |                    x_err_num date                                       |
-- |                    x_err_code                                          |
-- |                    x_err_msg                                           |
-- +=====================================================================+                            
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
/
SHOW ERRORS;
