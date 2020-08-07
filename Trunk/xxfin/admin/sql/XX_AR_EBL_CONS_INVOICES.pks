SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE BODY xx_ar_ebl_cons_invoices

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE

create or replace
PACKAGE xx_ar_ebl_cons_invoices   AS
---+========================================================================================================+
---|                                        Office Depot - Project Simplify                                 |
---|                             Oracle NAIO/WIPRO/Office Depot/Consulting Organization                     |
---+========================================================================================================+
---|    Application             :       AR                                                                  |
---|                                                                                                        |
---|    Name                    :       xx_ar_ebl_consolidated_invoices.pks                                         |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             10-MAR-2010       S Mercy Sharmila   Initial Version                                |
---+========================================================================================================+
       g_pkg_name            VARCHAR2(50) :='XX_AR_EBL_CONSOLIDATED_INVOICES';
       g_pks_version         NUMBER(2,1)  :='1.0';
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : cons_data_extract_main                                              |
   -- | Description : Batching program to submit multiple data extraction threads         |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- +===================================================================================+  
	PROCEDURE cons_data_extract_main( X_ERRBUFF OUT VARCHAR2
                                        ,X_RETCODE   OUT NUMBER
                                        ,PN_BATCH_SIZE       IN NUMBER
                                        ,pn_thread_count IN NUMBER
                                        ,PC_AS_OF_DATE       IN VARCHAR2
                                        ,P_DEBUG_FLAG        IN VARCHAR2
                   );
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : extract_cons_data                                                   |
   -- | Description : Procedure to extract data and populate the staging tables           |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- +===================================================================================+                     
   PROCEDURE EXTRACT_CONS_DATA (ERRBUFF         OUT      VARCHAR2
                                ,RETCODE         OUT      NUMBER
                                ,p_batch_id               NUMBER
                                ,P_As_Of_Date             VARCHAR2
                                ,p_debug_flag                  VARCHAR2
                              );
  -- +=================================================================================+
  -- |                  Office Depot - Project Simplify                                  |
  -- |                       WIPRO Technologies                                          |
  -- +===================================================================================+
  -- | Name        : insert_lines                                                      |
  -- | Description : Procedute to extract line level data                                |                                                              |
  -- |                                                                                   |
  -- |Change Record:                                                                     |
  -- |===============                                                                    |
  -- |Version   Date          Author                 Remarks                             |
  -- |=======   ==========   =============           ====================================|
  -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy      Initial draft version               |
  -- +===================================================================================+                                
   PROCEDURE insert_lines (p_cust_trx_id IN NUMBER
                           , p_trx_type IN VARCHAR2
                           , p_cons_inv_id IN NUMBER
                           , p_cust_doc_id IN NUMBER
                           , p_parent_cust_doc_id IN NUMBER
                           , p_dept_code IN VARCHAR2                           
                           , p_batch_id IN NUMBER
                           , p_organization_id IN NUMBER
                           , p_order_source_code    IN VARCHAR2
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
   -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy   Initial draft version  |
   -- +===================================================================+                           
PROCEDURE POPULATE_TRANS_DETAILS (p_batch_id NUMBER);

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
   -- |DRAFT 1.0 11-MAR-2010  Ranjith Thangasamy   Initial draft version  |
   -- +===================================================================+
PROCEDURE POPULATE_FILE_NAME(P_BATCH_ID IN NUMBER);
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
 FUNCTION get_cust_id(p_cust_doc_id NUMBER
                      ,p_attr_id NUMBER)
   RETURN NUMBER;
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : Infocopies handling logic for INV_IC scenario                       |
   -- | Description : This function will return 'Y' or 'N' depending upon whether the     |
   -- |               infocopy can be sent or not                                         |
   -- |                                                                                   |
   -- |                                                                                   |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author              Remarks                                |
   -- |=======   ==========   =============        =======================================|
   -- |1.0       01-Apr-10    Tamil Vendhan L      Initial Version                        |
   -- +===================================================================================+   
   
FUNCTION XX_AR_INFOCOPY_HANDLING (p_attr             IN VARCHAR2
                                 ,p_doc_term         IN VARCHAR2
                                 ,p_cut_off_date     IN DATE
                                 ,p_eff_start_date   IN DATE
                                 ,p_as_of_date       IN DATE
                                 )
RETURN VARCHAR2;   
PROCEDURE INSERT_ZERO_BYTE_FILE;
PROCEDURE INSERT_ERROR_FILE;
   -- +===================================================================================+
   -- |                  Office Depot - Project Simplify                                  |
   -- |                       WIPRO Technologies                                          |
   -- +===================================================================================+
   -- | Name        : INSERT_TRANSMISSION_DETAILS                                         |
   -- | Description : Program to update transmisssion and file name                       |
   -- |Parameters   :                                                                     |
   -- |                                                                                   |
   -- |Change Record:                                                                     |
   -- |===============                                                                    |
   -- |Version   Date          Author                 Remarks                             |
   -- |=======   ==========   =============           ====================================|
   -- |DRAFT 1.0              Ranjith Prabu           Initial draft version               |
   -- +===================================================================================+  
PROCEDURE INSERT_TRANSMISSION_DETAILS (P_BATCH_ID number);
 FUNCTION INV_IC_CHECK (p_trx_id IN NUMBER
                      ,p_cust_doc_id IN NUMBER
                      ,p_parent_cust_doc_id IN NUMBER
                      )
RETURN VARCHAR2 ;
END xx_ar_ebl_cons_invoices;
/
SHOW ERRORS;
