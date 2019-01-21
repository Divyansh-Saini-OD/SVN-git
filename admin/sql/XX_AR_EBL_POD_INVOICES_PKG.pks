CREATE OR REPLACE
PACKAGE XX_AR_EBL_POD_INVOICES_PKG
IS
  ---+============================================================================================+
  ---|                              Office Depot - Project Simplify                               |
  ---|                                   Capgemini Technologies                                   |
  ---+============================================================================================+
  ---|    Application     : AR                                                                    |
  ---|                                                                                            |
  ---|    Name            : XX_AR_EBL_POD_INVOICES_PKG.pks                                        |
  ---|                                                                                            |
  ---|    Description     : Extract POD information for eligible transactions                     |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|                                                                                            |
  ---|    Change Record                                                                           |
  ---|    ---------------------------------                                                       |
  ---|    Version         DATE              AUTHOR             DESCRIPTION                        |
  ---|    ------------    ----------------- ---------------    ---------------------              |
  ---|    1.0             12-Oct-2018       Aarthi             Initial Version - NAIT -           |
  ---+============================================================================================+
  --+=============================================================================================+
  ---|    Name : POD_EXTRACT                                                                      |
  ---|    Description    : The POD_EXTRACT proc will perform the following                        |
  ---|                                                                                            |
  ---|                    1. Fetch all the eligible transactions for POD                          |
  ---|                       enabled customers                                                    |
  ---|                    2. Connect to DTS system via REST Service URL and fetch                 |
  ---|                       the corresponding POD images for the eligible orders                 |
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
PROCEDURE pod_extract(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER );
  --+=============================================================================================+
  ---|    Name : POPULATE_POD_ERRORS                                                              |
  ---|    Description    : The POPULATE_POD_ERRORS proc will perform the following                |
  ---|                                                                                            |
  ---|                    1. Populate the errors for response code 200 with no POD                |
  ---|                    2. Populate the non-200 response codes with errors as appropriate       |
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
PROCEDURE populate_pod_errors(
    p_response_data   IN CLOB,
    p_response_code   IN NUMBER,
    p_error_message   IN VARCHAR2,
    p_user_exception  IN VARCHAR2,
    p_order_number    IN VARCHAR2,
    p_customer_trx_id IN NUMBER,
    p_cust_acc_name   IN VARCHAR2,
    p_transaction_id  IN VARCHAR2,
    p_request_id      IN NUMBER,
    p_user_id         IN NUMBER
	);
  --+=============================================================================================+
  ---|    Name : CONVERT_CLOB_TO_BLOB                                                             |
  ---|    Description    : The CONVERT_CLOB_TO_BLOB function will perform the following           |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
PROCEDURE convert_clob_to_blob(
    p_pod_clob_resp    IN CLOB,
	p_pod_blob        OUT BLOB,
	p_user_exception  OUT VARCHAR2
    );	
  --+=============================================================================================+
  ---|    Name : POD_EXTRACT_CHILD                                                                |
  ---|                                                                                            |
  ---|                    1. This procedure will process child programs for batches               |
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
PROCEDURE POD_EXTRACT_CHILD
  (
    x_errbuf   OUT NOCOPY  VARCHAR2,
    x_retcode  OUT NOCOPY NUMBER,
	p_batch_id IN NUMBER	 
  ) ;	
  --+=============================================================================================+
  ---|    Name : DISPLAY_INVOICE_NUMBER                                                           |
  ---|    Description    : The DISPLAY_INVOICE_NUMBER function will perform the following         |
  ---|                                                                                            |
  ---|                    1. This function will take the Invoice Number from ra_customer_trx_all  |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION display_invoice_num(
    p_customer_trx_id    IN NUMBER
	)
    RETURN VARCHAR2;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD                                                                      |
  ---|    Description    : The DISPLAY_POD function will perform the following                    |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION display_pod(
    p_customer_trx_id    IN NUMBER,
	p_cust_doc_id 	     IN NUMBER
	)
    RETURN CLOB;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD_CONSIGNEE                                                            |
  ---|    Description    : The DISPLAY_POD_CONSIGNEE function will perform the following          |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION display_pod_consignee(
    p_customer_trx_id IN NUMBER,
    p_cust_doc_id 	   IN NUMBER
	)
    RETURN VARCHAR2;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD_SHIP_STATUS                                                          |
  ---|    Description    : The DISPLAY_POD_STATUSDESC function will perform the following         |
  ---|                                                                                            |
  ---|                    1. This function will take the proofOfDelivery from JSON response       |
  ---|                       as an input and convert it into a blob image.                        |               
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION display_pod_ship_status(
    p_customer_trx_id IN NUMBER,
    p_cust_doc_id 	   IN NUMBER
	)
    RETURN VARCHAR2;
  --+=============================================================================================+
  ---|    Name : DISPLAY_POD_DELIVERY_DATE                                                        |
  ---|    Description    : The DISPLAY_POD_DELIVERY_DATE function will perform the following      |
  ---|                                                                                            |
  ---|                    1. This function will fetch the delivery date from DTL table            |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION display_pod_delivery_date(
    p_customer_trx_id IN NUMBER,
	p_cust_doc_id 	   IN NUMBER
	)
    RETURN DATE;
  --+=============================================================================================+
  ---|    Name : CHECK_POD                                                                        |
  ---|    Description    : The CHECK_POD function will perform the following                      |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the given customer is pod customer |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+
FUNCTION CHECK_POD(
    p_cust_account_id IN NUMBER )
    RETURN NUMBER;	
  --+=============================================================================================+
  ---|    Name : GET_POD_MSG                                                                      |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
FUNCTION GET_POD_MSG (
    p_cust_account_id IN NUMBER , 
    p_customer_trx_id IN NUMBER , 
	p_cust_doc_id IN NUMBER )     
    RETURN VARCHAR2;	
  --+=============================================================================================+
  ---|    Name : getbase64String                                                                  |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
FUNCTION GETBASE64STRING(
      p_blob BLOB )
    RETURN CLOB	;

  --+=============================================================================================+
  ---|    Name : CHECK_POD                                                                        |
  ---|    Description    : The MSG function will perform the following                            |
  ---|                                                                                            |
  ---|                    1. This function is to check whether the  will get message for POD      |
  ---|                       or not.                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :                                                                            |
  --+=============================================================================================+	
FUNCTION GET_PAY_DOC_FLAG (
        p_cust_doc_id IN NUMBER )     
    RETURN VARCHAR2;

--+=============================================================================================+
  ---|    Name : RESIZE_IMAGE                                                                 	  |
  ---|    Description    : The resize_image function will perform the following               	  |
  ---|                                                                                            |
  ---|                    This function is to check whether POD image larger size  and it will    |
  -- | 					 resize pod image 														  |
  ---|                       		                                                              |                 
  ---|                                                                                            |
  ---|    Parameters :   p_customer_trx_id                                                        |
  --+=============================================================================================+	
FUNCTION RESIZE_IMAGE (p_customer_trx_id IN NUMBER)
    RETURN BLOB;  
  
END XX_AR_EBL_POD_INVOICES_PKG; 
/
SHOW ERRORS;