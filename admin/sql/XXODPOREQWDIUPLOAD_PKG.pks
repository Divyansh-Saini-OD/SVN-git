CREATE OR REPLACE PACKAGE XXODPOREQWDIUPLOAD_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       Oracle Consulting                           |
-- +===================================================================+
-- | Name :      E0980 - PO Auto Requisition Import                    |
-- | Description : To automatically import the Requisitions into Oracle|
-- |               to the staging tables. This is called from WEB ADI. |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       10-Jul-2013  Satyajeet Mishra     Initial version        |
-- +===================================================================+

-- +===================================================================+
-- | Name :  get_record                                                |
-- | Description : To automatically import the Rquisitions into Oracle |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns:                                                          |
-- +===================================================================+
    PROCEDURE get_record(
		    p_requisition_type	IN  VARCHAR2
		,	p_preparer_emp_nbr	IN  VARCHAR2
		, 	p_req_description	IN  VARCHAR2
		, 	p_req_line_number	IN  VARCHAR2
		, 	p_line_type	        IN  VARCHAR2
		, 	p_item	            IN  VARCHAR2
		, 	p_category	        IN  VARCHAR2
		, 	p_item_description	IN  VARCHAR2
		, 	p_unit_of_measure	IN  VARCHAR2
		, 	p_price	            IN  VARCHAR2
		, 	p_need_by_date	    IN  VARCHAR2
		, 	p_quantity	        IN  VARCHAR2
		, 	p_organization	        IN  VARCHAR2
		, 	p_source_organization	IN  VARCHAR2
		, 	p_location	            IN  VARCHAR2
		, 	p_req_line_number_dist	IN  VARCHAR2
		, 	p_distribution_quantity	IN  VARCHAR2
		, 	p_charge_acct_segment1	IN  VARCHAR2
		, 	p_charge_acct_segment2	IN  VARCHAR2
		, 	p_charge_acct_segment3	IN  VARCHAR2
		, 	p_charge_acct_segment4	IN  VARCHAR2
		, 	p_charge_acct_segment5	IN  VARCHAR2
		, 	p_charge_acct_segment6	IN  VARCHAR2
		, 	p_charge_acct_segment7	IN  VARCHAR2
		, 	p_project	            IN  VARCHAR2
		, 	p_task	                IN  VARCHAR2
		, 	p_expenditure_type	    IN  VARCHAR2
		, 	p_expenditure_org	    IN  VARCHAR2
		, 	p_expenditure_item_date	IN  VARCHAR2
        ,   p_file_name             IN VARCHAR2		      
		);

-- +===================================================================+
-- | Name :  Submit_request                                            |
-- | Description : Submits request for custom program for validatio    |
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- | Returns:                                                          |
-- +===================================================================+
    PROCEDURE submit_request(x_message OUT VARCHAR2);
	
END XXODPOREQWDIUPLOAD_PKG;
/