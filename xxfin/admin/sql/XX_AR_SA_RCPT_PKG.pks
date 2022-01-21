CREATE OR REPLACE PACKAGE APPS.XX_AR_SA_RCPT_PKG AS   
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       |  
-- +============================================================================================+ 
-- |  Name:  XX_AR_SA_RCPT_PKG                                                                  | 
-- |  Rice ID: I1025                                                                            |
-- |  Description:  This package creates and applies cash receipts for legacy deposits and      |
-- |                refund tenders made in OM.                                                  |
-- |                                                                                            | 
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         10-Jun-2007  B.Looman         Initial version                                  | 
-- | 1.1         05-Nov-2008  Anitha D         Fix for Defect 12289                             | 
-- | 1.2         07-JUN-2013  Bapuji Nanapaneni Added changes for 12i UPGRADE                   |
-- +============================================================================================+


-- Possible values for Concurrent Program Parameter: "Which Process"
GC_PROCESS_ALL             CONSTANT VARCHAR2(100)   := 'All';
GC_PROCESS_CREATE_DEPOSITS CONSTANT VARCHAR2(100)   := 'Create Deposit Receipts';
GC_PROCESS_RESUBMIT_DPSTS  CONSTANT VARCHAR2(100)   := 'Resubmit Deposit Reversals';
GC_PROCESS_CREATE_REFUNDS  CONSTANT VARCHAR2(100)   := 'Create Refund Receipts';
GC_PROCESS_APPLY_REFUNDS   CONSTANT VARCHAR2(100)   := 'Apply Refund Receipts';

         
-- +============================================================================================+ 
-- |  Name: SET_DEBUG                                                                           | 
-- |  Description: This procedure turns on/off the debug mode.                                  |
-- |                                                                                            | 
-- |  Parameters:  p_debug - Debug Mode: TRUE=On, FALSE=Off                                     |
-- |                                                                                            | 
-- |  Returns:     N/A                                                                          |
-- +============================================================================================+
PROCEDURE set_debug
( p_debug      IN      BOOLEAN       DEFAULT TRUE );


-- +============================================================================================+ 
-- |  Name: CREATE_DEPOSIT_RECEIPTS                                                             | 
-- |  Description: This procedure creates AR Receipts for all the pending deposit payments in   | 
-- |               the table XX_OM_LEGACY_DEPOSITS.  it creates an AR receipt with the          | 
-- |               prepayment application with references to the legacy order number.           |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - only create deposit receipts interfaced from this date         |
-- |               p_to_date   - only create deposit receipts interfaced to this date           |
-- |               p_request_id - Request Id of the custom table records to process             |
-- |                                   (defaults to NULL)                                       |
-- |               p_orig_sys_document_ref - Legacy Order Num to run only one specific record   |
-- |                                   (defaults to NULL)                                       |
-- |               p_only_deposit_reversals - Only submit of deposit reversals (manual fixes)   |
-- |                                   (defaults to "N")                                        |
-- |               p_child_process_id - Process Id for child thread                             |
-- |                                                                                            | 
-- |  Returns:     None                                                                         |
-- +============================================================================================+
PROCEDURE create_deposit_receipts
( p_org_id                 IN      NUMBER,
  p_from_date              IN      DATE,
  p_to_date                IN      DATE,
  p_request_id             IN      NUMBER      DEFAULT NULL,
  p_orig_sys_document_ref  IN      VARCHAR2    DEFAULT NULL,
  p_only_deposit_reversals IN      VARCHAR2    DEFAULT 'N',
  p_child_process_id       IN      VARCHAR2    DEFAULT NULL );


-- +============================================================================================+ 
-- |  Name: CREATE_REFUND_RECEIPTS                                                              | 
-- |  Description: This procedure creates zero-dollar AR Receipts or flags the original rcpt    |
-- |               for all pending refund tenders in the table XX_OM_RETURN_TENDERS_ALL.        |
-- |               it marks the AR receipt with the references in the receipt DFFs              |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - only create refund receipts interfaced from this date          |
-- |               p_to_date   - only create refund receipts interfaced to this date            |
-- |               p_request_id - Request Id of the custom table records to process             |
-- |                                   (defaults to NULL)                                       |
-- |               p_orig_sys_document_ref - Legacy Order Num to run only one specific record   |
-- |                                   (defaults to NULL)                                       |
-- |               p_child_process_id - Process Id for child thread                             |
-- |                                                                                            | 
-- |  Returns:     None                                                                         |
-- +============================================================================================+
PROCEDURE create_refund_receipts
( p_org_id                 IN      NUMBER,
  p_from_date              IN      DATE,
  p_to_date                IN      DATE,
  p_request_id             IN      NUMBER      DEFAULT NULL,
  p_orig_sys_document_ref  IN      VARCHAR2    DEFAULT NULL,
  p_child_process_id       IN      VARCHAR2    DEFAULT NULL );


-- +============================================================================================+ 
-- |  Name: APPLY_REFUND_RECEIPTS                                                               | 
-- |  Description: This procedure fetches all the newly created credit memos that have          |
-- |               matching refund receipts.  It applies the refund (could be original receipt  |
-- |               or zero-dollar receipt), and writes-off the credit balance with the          |
-- |               corresponding receivable activity.                                           |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - only apply refund receipts interfaced from this date           |
-- |               p_to_date   - only apply refund receipts interfaced to this date             |
-- |               p_request_id - Request Id of the custom table records to process             |
-- |                                   (defaults to NULL)                                       |
-- |               p_orig_sys_document_ref - Legacy Order Num to run only one specific record   |
-- |                                   (defaults to NULL)                                       |
-- |               p_child_process_id - Process Id for child thread                             |
-- |                                                                                            | 
-- |  Returns:     None                                                                         |
-- +============================================================================================+
PROCEDURE apply_refund_receipts
( p_org_id                 IN      NUMBER,
  p_from_date              IN      DATE,
  p_to_date                IN      DATE,
  p_request_id             IN      NUMBER      DEFAULT NULL,
  p_orig_sys_document_ref  IN      VARCHAR2    DEFAULT NULL,
  p_child_process_id       IN      VARCHAR2    DEFAULT NULL );


-- +============================================================================================+ 
-- |  Name: MASTER_PROGRAM                                                                      | 
-- |  Description: This procedure is the master program that handles all the I1025 processes.   |
-- |               it is setup as a concurrent program that will be scheduled on a regular      |
-- |               basis.                                                                       |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - From Creation date for the deposit and refund records          |
-- |               p_to_date - To Creation date for the deposit and refund records              |
-- |               p_which_process - Which of the sub-process should be runned                  |
-- |                                   (defaults to "All")                                      |
-- |               p_request_id - Request Id of the custom table records to process             |
-- |                                   (defaults to NULL)                                       |
-- |               p_orig_sys_document_ref - Legacy Order Num to run only one specific record   |
-- |                                   (defaults to NULL)                                       |
-- |               p_child_process_id - Process Id for child thread                             |
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE master_program
( x_error_buffer           OUT     VARCHAR2,
  x_return_code            OUT     NUMBER,
  p_org_id                 IN      NUMBER,
  p_from_date              IN      VARCHAR2    DEFAULT NULL,
  p_to_date                IN      VARCHAR2    DEFAULT NULL,
  p_which_process          IN      VARCHAR2    DEFAULT GC_PROCESS_ALL,
  p_request_id             IN      NUMBER      DEFAULT NULL,
  p_orig_sys_document_ref  IN      VARCHAR2    DEFAULT NULL,
  p_child_process_id       IN      VARCHAR2    DEFAULT NULL );


-- +============================================================================================+ 
-- |  Name: MULTI_THREAD_MASTER                                                                 | 
-- |  Description: This procedure is the master program that handles all the I1025 processes.   |
-- |               it is setup as a concurrent program that will be scheduled on a regular      |
-- |               basis.                                                                       |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - From Creation date for the deposit and refund records          |
-- |               p_to_date - To Creation date for the deposit and refund records              |
-- |               p_which_process - Which of the sub-process should be runned                  |
-- |                                   (defaults to "All")                                      |
-- |               p_request_id_from - Start Request Id of the custom table records to process  |
-- |               p_request_id_to - End Request Id of the custom table records to process      |
-- |               p_number_of_batches - Number of Threads of AR I1025 to submit                |
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE multi_thread_master
( x_error_buffer           OUT     VARCHAR2,
  x_return_code            OUT     NUMBER,
  p_org_id                 IN      NUMBER,
  p_from_date              IN      VARCHAR2    DEFAULT NULL,
  p_to_date                IN      VARCHAR2    DEFAULT NULL,
  p_which_process          IN      VARCHAR2    DEFAULT GC_PROCESS_ALL,
  p_request_id_from        IN      NUMBER      DEFAULT NULL,
  p_request_id_to          IN      NUMBER      DEFAULT NULL,
  p_number_of_batches      IN      NUMBER      DEFAULT NULL );


-- +============================================================================================+ 
-- |  Name: PRINT_ERROR_REPORT                                                                  | 
-- |  Description: This procedure can be used to report all errored records for AR I1025.       |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - From Creation date for the deposit and refund records          |
-- |               p_to_date - To Creation date for the deposit and refund records              |
-- |               p_which_process - Which of the sub-process should be runned                  |
-- |                                   (defaults to "All")                                      |
-- |               p_request_id - Request Id of the custom table records to process             |
-- |                                   (defaults to NULL)                                       |
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE print_error_report
( x_error_buffer           OUT     VARCHAR2,
  x_return_code            OUT     NUMBER,
  p_org_id                 IN      NUMBER,
  p_from_date              IN      VARCHAR2    DEFAULT NULL,
  p_to_date                IN      VARCHAR2    DEFAULT NULL,
  p_which_process          IN      VARCHAR2    DEFAULT GC_PROCESS_ALL,
  p_request_id             IN      NUMBER      DEFAULT NULL,
  p_receipt_method_id      IN      NUMBER      DEFAULT NULL); -- Added for Defect 12289


-- +============================================================================================+ 
-- |  Name: PRINT_UNPROCESSED_REPORT                                                            | 
-- |  Description: This procedure can be used to report all unprocessed records in AR I1025.    |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |               p_from_date - From Creation date for the deposit and refund records          |
-- |               p_to_date - To Creation date for the deposit and refund records              |
-- |               p_request_id - Request Id of the custom table records to process             |
-- |                                   (defaults to NULL)                                       |
-- |                                                                                            | 
-- |  Returns:     x_error_buffer - std conc program output buffer                              |
-- |               x_return_code  - std conc program return value                               |
-- |                                (0=Success,1=Warning,2=Error)                               |
-- +============================================================================================+
PROCEDURE print_unprocessed_report
( x_error_buffer           OUT     VARCHAR2,
  x_return_code            OUT     NUMBER,
  p_org_id                 IN      NUMBER,
  p_from_date              IN      VARCHAR2    DEFAULT NULL,
  p_to_date                IN      VARCHAR2    DEFAULT NULL,
  p_request_id             IN      NUMBER      DEFAULT NULL,
  p_receipt_method_id      IN      NUMBER      DEFAULT NULL); -- Added for Defect 12289

-- +============================================================================================+ 
-- |  Name: GET_COUNTRY_CODE                                                                    | 
-- |  Description: TO DERIVE COUNTRY CODE BASED ON OPU                                          |
-- |                                                                                            | 
-- |  Parameters:  p_org_id - Operating Unit                                                    |
-- |                                                                                            | 
-- |  Returns:     VARCHAR2 - RETURN COUNTRY CODE                                               |
-- +============================================================================================+
FUNCTION get_country_code (p_org_id IN NUMBER) RETURN VARCHAR2; -- Added by NB for 12i UPGRADE
END;
/