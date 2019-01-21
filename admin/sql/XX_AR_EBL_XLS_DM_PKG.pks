CREATE OR REPLACE PACKAGE XX_AR_EBL_XLS_DM_PKG
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBIL_XLS_MASTER_PROG                                          |
-- | Description : This Procedure is used for multithreading the exls data into        |
-- |               batches and to submit the child procedure XX_AR_EBL_XLS_CHILD_PROG  |
-- |               for every batch                                                     |
-- |Parameters   :  p_debug_flag                                                       |
-- |               ,p_batch_size                                                       |
-- |               ,p_thread_cnt                                                       |
-- |               ,p_doc_type                                                         |
-- |               ,p_cycle_date                                                       |
-- |               ,p_delivery_method                                                  |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-APR-2010  Parameswaran SN         Initial draft version               |
-- +===================================================================================+
    PROCEDURE XX_AR_EBL_XLS_MASTER_PROG ( x_error_buff         OUT VARCHAR2
                                         ,x_ret_code           OUT NUMBER
                                         ,p_debug_flag         IN  VARCHAR2
                                         ,p_batch_size         IN  NUMBER
                                         ,p_thread_cnt         IN  NUMBER
                                         ,p_doc_type           IN  VARCHAR2   -- ( IND/CONS)
                                         ,p_cycle_date         IN  VARCHAR2
                                         ,p_delivery_method    IN  VARCHAR2   --20-MAY-2010
                                         );
 -- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_XLS_CHILD_PROG                                            |
-- | Description : This Procedure is used for framing the dynamic query to fetch data  |
-- |               from the stagging table and to poplate the xls stagging table       |
-- |Parameters   : p_batch_id                                                          |
-- |             , p_doc_type                                                          |
-- |             , p_debug_flag                                                         |
-- |             , p_cycle_date                                                         |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 15-APR-2010  Bhuvaneswary S          Initial draft version               |
-- +===================================================================================+
    PROCEDURE XX_AR_EBL_XLS_CHILD_PROG( x_error_buff      OUT VARCHAR2
                                       ,x_ret_code        OUT NUMBER
                                       ,p_batch_id        IN  NUMBER
                                       ,p_doc_type        IN  VARCHAR2
                                       ,p_debug_flag      IN  VARCHAR2
                                       ,p_cycle_date      IN  VARCHAR2
                                       );
-- +=============================================================================+
-- |                         Office Depot - Project Simplify                     |
-- |                                WIPRO Technologies                           |
-- +=============================================================================+
-- | Name        : XX_AR_EBL_XLS_CHILD_NON_DT                                    |
-- | Description : This Procedure is used to insert special columns into the XLS |
-- |               stagging table in the order that the user selects from CDH    |
-- |               for a NON-DT record type                                      |
-- |                                                                             |
-- | Parameters  :  p_cust_doc_id                                                |
-- |               ,p_field_id                                                   |
-- |               ,p_insert                                                     |
-- |               ,p_select                                                     |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |Version   Date          Author                  Remarks                      |
-- |=======   ==========   =============           ==============================|
-- |DRAFT 1.0 20-APR-2010  Parameswaran S N         Initial draft version        |
-- |      1.1 19-Dec-2017  Aniket J    CG          Changes for Requirement#22772    |
-- +=============================================================================+
    PROCEDURE XX_AR_EBL_XLS_CHILD_NON_DT ( p_cust_doc_id    IN  NUMBER
                                          ,p_ebatchid       IN  NUMBER
                                          ,p_file_id        IN  NUMBER
                                          ,p_insert         IN  VARCHAR2
                                          ,p_select         IN  VARCHAR2
                                          ,p_seq_nondt      IN  VARCHAR2
                                          ,p_doc_type       IN  VARCHAR2--(CONS/IND)
                                          ,p_debug_flag     IN  VARCHAR2
                                          ,p_insert_status  OUT VARCHAR2
                                          ,p_cycle_date     IN  DATE
                                          ,p_cmb_splt_whr   IN VARCHAR2  --Added by Aniket CG #22772 on 15 Dec 2017
                                          );
-- +==================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : GET_DECODE_NDT                                                      |
-- | Description : This function is used to concatenate the header coumns for which a  |
-- |               non dt record has to be populated in a way as used in the code      |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 27-APR-2010  Bhuvaneswary S          Initial draft version               |
-- +===================================================================================+
    FUNCTION get_decode_ndt (p_debug_flag IN VARCHAR2)
    RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_conc_field_name                                                 |
-- | Description : This function is used to build the sql columns with concatenated    |
-- |               field names as per setup defined in the concatenation tab           |
-- |Parameters   : cust_doc_id, concatenated_field_id                                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_conc_field_names (p_cust_doc_id IN NUMBER 
                                  ,p_conc_field_id IN NUMBER
                                  ,p_debug_flag IN VARCHAR2
                                  )
    RETURN VARCHAR2;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- +===================================================================================+
-- | Name        : get_split_field_names                                               |
-- | Description : This function is used to build the sql columns as per setup         |
-- |               defined in the split tab                                            |
-- |Parameters   : cust_doc_id, base_field_id, count                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 12-DEC-2015  Suresh N                Initial draft version               |
-- +===================================================================================+
    FUNCTION get_split_field_names (p_cust_doc_id IN NUMBER 
                                    ,p_base_field_id IN NUMBER 
                                    ,p_count IN NUMBER
                                    ,p_debug_flag IN VARCHAR2)
    RETURN VARCHAR2;
 END XX_AR_EBL_XLS_DM_PKG;
/
SHOW ERRORS;
EXIT;
