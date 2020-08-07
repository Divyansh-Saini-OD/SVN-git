create or replace 
PACKAGE      XX_AR_EBL_IND_EPDF_PKG
 AS
 
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : XX_AR_EBL_IND_EPDF_PKG                                              |
-- | Description : This Package contains the common functions for Individual eBilling. |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 07-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+

-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : MULTI_THREAD_IND                                                    |
-- | Description : This Procedure is used to multi thread the transactions to be       |
-- |               printed through Individual eBilling.                                |
-- |Parameters   :                                                                     |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 07-APR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE MULTI_THREAD_IND ( x_error_buff                 OUT VARCHAR2
                                ,x_ret_code                   OUT NUMBER
                                ,p_batch_size                 IN  NUMBER
                                ,p_thread_count               IN  NUMBER
                                ,p_debug_flag                 IN  VARCHAR2
                                ,p_del_mthd                   IN  VARCHAR2
                                ,p_doc_type                   IN  VARCHAR2
                                ,p_cycle_date                 IN  VARCHAR2
                                );
PROCEDURE xx_insert_req_td(
    p_in_req_id    NUMBER ,
    p_in_prg_name  VARCHAR2,
    p_in_file_name VARCHAR2,
    p_in_dml_op    VARCHAR2 ) ;
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                       WIPRO Technologies                                          |
-- +===================================================================================+
-- | Name        : SUBMIT_EPDF_MAIN                                                    |
-- | Description : This Procedure is used to submit the exact IND ePDF pgm and the     |
-- |               bursting program.                                                   |
-- | Parameters   :                                                                    |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date          Author                 Remarks                             |
-- |=======   ==========   =============           ====================================|
-- |DRAFT 1.0 14-MAR-2010  Gokila Tamilselvam      Initial draft version               |
-- +===================================================================================+
    PROCEDURE SUBMIT_EPDF_MAIN ( x_error_buff                 OUT VARCHAR2
                                ,x_retcode                    OUT NUMBER
                                ,p_batch_id                   IN  NUMBER
                                ,p_debug_flag                 IN  VARCHAR2
                                ,p_del_meth                   IN  VARCHAR2
                                ,p_doc_type                   IN  VARCHAR2
                                ,p_cycle_date                 IN  VARCHAR2
                                );

 END XX_AR_EBL_IND_EPDF_PKG;
/
SHOW ERRORS;
EXIT;
 