SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  XX_AR_EBL_IND_INVOICES_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE XX_AR_EBL_IND_INVOICES_PKG
 AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  XX_AR_EBL_INDIVIDUAL_INVOICES  E2059(CR 586)  |
-- | Description      :  This Package is used to fetch all the Distinct|
-- |                     Customer Ids and assign batch Id for the given|
-- |                     Batch size and call the Child Programs        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 11-MAR-2010  Vinaykumar S   Initial draft version(CR 586)|
-- +===================================================================+

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  GET_CUST_DETAILS                              |
-- | Description      :  This Procedure is used to Extract all the     |
-- |                     Customer Ids  and call the Batching and       |
-- |                     Submit Child Programs                         |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 11-MAR-2010  Vinaykumar S   Initial draft version(CR 586)|
-- +===================================================================+

PROCEDURE get_cust_details(x_errbuf OUT VARCHAR2
                           , x_retcode OUT VARCHAR2
                           , p_as_of_date IN VARCHAR2
                           , p_batch_size IN NUMBER
                           , p_thread_count IN NUMBER
                           , p_debug_flag IN VARCHAR2
                           );

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  EXTRACT_DATA                                  |
-- | Description      :  This Procedure is used to Extract all the     |
-- |                     Customer Details and insert the  header       |
-- |                     and line details into the respective tables   |
-- |                     and archive the data into their respective    |
-- |                     History tables                                |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |DRAFT 1.0 11-MAR-2010  Vinaykumar S   Initial draft version(CR 586)|
-- +===================================================================+

PROCEDURE extract_data(x_errbuf OUT VARCHAR2
                       , x_retcode OUT VARCHAR2
                       , p_batch_id IN NUMBER
                       , p_as_of_date IN VARCHAR2
                       , p_debug_flag IN VARCHAR2
                        );
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  insert_lines                                  |
-- | Description      :  This Procedure is used to Extract all the line|
-- |                     Level Data                                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
-- +===================================================================+
PROCEDURE insert_lines (p_cust_trx_id IN NUMBER
                           , p_trx_type IN VARCHAR2
                           , p_cust_doc_id IN NUMBER
                           , p_parent_cust_doc_id IN NUMBER
                           , p_dept_code in VARCHAR2
                           , p_batch_id NUMBER
                           , p_organization_id IN NUMBER
                           , p_order_source_code VARCHAR2
                           );
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  populate_trans_details                        |
-- | Description      :  This Procedure is used to populate file and   |
-- |                     transmission Data                             |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
-- +===================================================================+                           
PROCEDURE populate_trans_details (p_batch_id NUMBER);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  populate_file_name                            |
-- | Description      :  This Procedure is used to populate file names |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
-- +===================================================================+
procedure populate_file_name(p_batch_id in number);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  INSERT_TRANSMISSION_DETAILS                   |
-- | Description      :  This Procedure is used to insert transmission |
-- |                     Details                                       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
-- +===================================================================+

PROCEDURE INSERT_TRANSMISSION_DETAILS (p_batch_id IN NUMBER);
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  INSERT_ERROR_FILE                             |
-- | Description      :  This Procedure is used to insert erro file    |
-- |                     Details                                       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
-- +===================================================================+
PROCEDURE INSERT_ERROR_FILE;
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                          Wipro-Office Depot                       |
-- +===================================================================+
-- | Name             :  INSERT_ERROR_FILE                             |
-- | Description      :  This Procedure is used to insert erro file    |
-- |                     Details                                       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author           Remarks                    |
-- |=======   ==========   =============    ======================     |
-- |1.0       26-MAY-2010  Ranjith Thangasamy                          |
-- +===================================================================+
PROCEDURE INSERT_ZERO_BYTE_FILE;
   -- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : get_cust_id                                                         |
-- | Description : returns the cust_acct_id for the given cust_doc_id                  |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
-- +===================================================================================+     
   FUNCTION get_cust_id(p_cust_doc_id NUMBER)
   RETURN NUMBER; 
                          
END XX_AR_EBL_IND_INVOICES_PKG;
/
SHOW ERRORS;
