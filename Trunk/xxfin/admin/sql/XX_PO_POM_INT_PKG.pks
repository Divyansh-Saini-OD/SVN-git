create or replace package XX_PO_POM_INT_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name	 :  XX_PO_POM_INT_PKG                                                           |
-- |  RICE ID 	 :  I2193_PO to EBS Interface     			                        |
-- |  Description:         								        |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         04/10/2017   Avinash Baddam   Initial version                                  |
-- | 1.1         01/08/2018   Havish Kasina      Modified the add_po_line procedure             |
-- +============================================================================================+
TYPE varchar2_table IS TABLE OF VARCHAR2(32767) INDEX BY BINARY_INTEGER;

PROCEDURE log_exception (p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
		         ,p_error_msg          IN  VARCHAR2);

PROCEDURE parse(p_delimstring IN  VARCHAR2
               ,p_table       OUT varchar2_table
               ,p_nfields     OUT INTEGER
               ,p_delim       IN  VARCHAR2 DEFAULT '|'
               ,p_error_msg   OUT VARCHAR2
               ,p_retcode     OUT VARCHAR2);
               
PROCEDURE load_staging(p_errbuf       OUT  VARCHAR2
                      ,p_retcode      OUT  VARCHAR2
                      ,p_filepath          VARCHAR2
                      ,p_file_name 	   VARCHAR2
                      ,p_debug             VARCHAR2);
                      
PROCEDURE update_child(p_errbuf         OUT  VARCHAR2
                       ,p_retcode       OUT  VARCHAR2
                       ,p_batch_id           NUMBER
                       ,p_debug              VARCHAR2);                        
                      
PROCEDURE interface_child(p_errbuf       OUT  VARCHAR2
                         ,p_retcode      OUT  VARCHAR2
                         ,p_batch_id          NUMBER
                      	 ,p_debug             VARCHAR2);
                      	  
PROCEDURE interface_master(p_errbuf       OUT  VARCHAR2
                          ,p_retcode      OUT  VARCHAR2
                      	  ,p_child_threads     NUMBER
                      	  ,p_retry_errors      VARCHAR2
						  ,p_retry_int_errors  VARCHAR2
                      	  ,p_debug             VARCHAR2); 
						  
 PROCEDURE add_po_line     (p_batch_id          NUMBER
                           ,p_po_number         VARCHAR2
                           ,p_item_id           NUMBER
                      	   ,p_quantity          NUMBER
                      	   ,p_price             NUMBER
						   ,p_receipt_req_flag  VARCHAR2
						   ,p_uom_code          VARCHAR2
                      	   ,p_line_num   OUT    NUMBER
						   ,p_return_status OUT VARCHAR2
						   ,p_error_message OUT  VARCHAR2);

/**************************************************************************
 *									  *
 * 	Is it Trade PO or Not             *
 *  This procedure will be used in Workflow  POAPPRV to skip the PO Approval *
 *  when updating the Trade POs		  *
 * 									  *
 **************************************************************************/

PROCEDURE is_trade_po(itemtype IN VARCHAR2,
		   		itemkey  IN VARCHAR2,
		   		actid    IN NUMBER,
		   		FUNCMODE IN VARCHAR2,
		   		RESULT   OUT NOCOPY VARCHAR2);		

PROCEDURE valid_and_mark_missed_po_int(p_source IN VARCHAR2
                            ,p_source_record_id  IN VARCHAR2
                            ,p_po_number    IN VARCHAR2
                            ,p_po_line_num  IN VARCHAR2
                            ,p_result       OUT NOCOPY VARCHAR2); 

PROCEDURE validate_missing_po(
            p_errbuf OUT VARCHAR2 ,
            p_retcode OUT VARCHAR2);                      	  
END XX_PO_POM_INT_PKG;
/