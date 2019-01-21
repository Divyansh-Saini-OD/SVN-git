CREATE OR REPLACE PACKAGE BODY XXODPOREQWDIUPLOAD_PKG
AS
-- +===================================================================+
-- |               Office Depot - Project Simplify                     |
-- |                   Oracle Consulting                               |
-- +===================================================================+
-- | Name :      E0980 - PO Auto Requisition Import                    |
-- | Description : To automatically import the Requisitions into Oracle|
-- |               to the staging tables. This is called from WEB ADI. |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========   =============       ======================= |
-- |1.0      10-Jul-2013  Satyajeet Mishra    Initial version          |
-- +===================================================================+
   PROCEDURE submit_request(x_message OUT VARCHAR2)
   IS
     ln_batch_id   number;
     ln_request_id NUMBER;
   BEGIN
      -- ------------------------
	  -- Deriving the batch id
	  -- ------------------------
      SELECT xx_po_req_batch_stg_s.nextval
        INTO ln_batch_id
        FROM SYS.DUAL;   
	   
      -- --------------------------------------
	  -- All new records are expected to be entered in the application with sessionid
	  -- Assign the actual batch id to all the records
	  -- --------------------------------------
	  BEGIN
        UPDATE xx_po_requisitions_stg 
		   SET batch_id = ln_batch_id
         WHERE batch_id = fnd_global.session_id;
      END;
	 
	  -- --------------------------------------
	  -- Submit the concurretn program
	  -- --------------------------------------
	  ln_request_id :=
          FND_REQUEST.SUBMIT_REQUEST 
		                       ( application   => 'XXFIN'
                                , program      => 'XX_PO_AUTO_REQ_PKG_PROCESS'
                                , start_time    => sysdate
                                , sub_request   => false
                                , argument1    => ln_batch_id
                                );
 
    
    COMMIT;
	 x_message := 'Request '||ln_request_id||'Submited';
   EXCEPTION
      WHEN OTHERS THEN
        x_message :='Error '||SQLERRM;
   END submit_request;

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
		)
IS  
  lv_error_msg varchar2(1000);
  e_exception exception;
BEGIN
  -- ---------------------------------
  -- Insert Record in the application
  -- ---------------------------------
   IF p_req_line_number is null THEN
      lv_error_msg := 'provide a valid line number';
      raise e_exception;
   END IF;
   
   INSERT INTO xx_po_requisitions_stg
         (	requisition_type
         ,	preparer_emp_nbr
         ,	 req_description
         ,	 req_line_number
         ,	 line_type
         ,	 item
         ,	 category
         ,	 item_description
         ,	 unit_of_measure
         ,	 price
         ,	 need_by_date
         ,	 quantity
         ,	 organization
         ,	 source_organization
         ,	 location
         ,	 req_line_number_dist
         ,	 distribution_quantity
         ,	 charge_account_segment1
         ,	 charge_account_segment2
         ,	 charge_account_segment3
         ,	 charge_account_segment4
         ,	 charge_account_segment5
         ,	 charge_account_segment6
         ,	 charge_account_segment7
         ,	 project
         ,	 task
         ,	 expenditure_type
         ,	 expenditure_org
         ,	 expenditure_item_date
         ,	 request_id            
         ,	 interface_source_code  
         ,	 destination_type_code  
         ,    file_name
		      ,    batch_id
          )
     VALUES
	   (  P_requisition_type
        , P_preparer_emp_nbr
        ,	 P_req_description
        ,	 P_req_line_number
        ,	 P_line_type
        ,	 P_item
        ,	 P_category
        ,	 P_item_description
        ,	 P_unit_of_measure
        ,	 p_price
        ,	 to_date(P_need_by_date)
        ,	 P_quantity
        ,	 P_organization
        ,	 P_source_organization
        ,	 P_location
        ,	 P_req_line_number_dist
        ,	 P_distribution_quantity
        ,	 P_charge_acct_segment1
        ,	 P_charge_acct_segment2
        ,	 P_charge_acct_segment3
        ,	 P_charge_acct_segment4
        ,	 P_charge_acct_segment5
        ,	 P_charge_acct_segment6
        ,	 P_charge_acct_segment7
        ,	 P_project
        ,	 P_task
        ,	 P_expenditure_type
        ,	 p_expenditure_org
        ,	 to_date(P_expenditure_item_date)
        ,	 1234
        ,	 'EXCEL'
        ,	 'EXPENSE'
        ,  p_file_name
		     ,  fnd_global.session_id
        ) ;
    COMMIT;
  EXCEPTION
    WHEN E_EXCEPTION THEN
      raise_application_error (-20001, lv_error_msg);
    WHEN OTHERS THEN
      lv_error_msg := 'Custom Error';
      raise_application_error (-20001, lv_error_msg);
END GET_RECORD;

END XXODPOREQWDIUPLOAD_PKG;
/