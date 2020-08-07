SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT CREATING PACKAGE XX_AP_PAYMENT_BATCH_PKG

PROMPT PROGRAM EXITS IF THE CREATION IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE XX_AP_PAYMENT_BATCH_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_AP_PAYMENT_BATCH_PKG                            |
-- | Description      :    Package for AP Open Invoice Conversion             |
-- |                                                                          |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version     Date         Author                 Remarks                   |
-- |=======   ===========  ================    ========================       |
-- | 1.0       02-APR-2007  Sarat Uppalapati     Initial                      |
-- | 1.0       25-JUN-2007  Sarat Uppalapati     Added Parameters             |
-- | 1.0       19-JUl-2007  Sarat Uppalapati     Added SCR Logic              |
-- | 1.0       06-SEP-2007  Sarat Uppalapati     Added additional Parameters  |
-- |                                             based on "CR 223"            |
-- | 1.0       24-SEP-2007  Sarat Uppalapati     Added additional code for    |
-- |                                             CR 221                       |
-- | 1.4       06-MAR-2008  Sarat Uppalapati     Defect 5224                  |
-- | 1.5       07-AUG-2008  Sandeep Pandhare     Defect 9428                  |
-- | 1.6       16-OCT-2008  Sandeep Pandhare     Defect 11961                 |
-- | 1.7       28-Sep-2009  Gokila Tamilselvam   Defect#1431 R1.1. Added      |
-- |                                             XXAPDMREP procedure.         |
-- | 1.8       06-Jul-2010  Priyanka Nagesh      Added AP_TDM_FORMAT          |
-- |                                             Procedure to Submit the      |
-- |                                             OD: AP Format APDM Report    |
-- |                                             for TDM for the APDM Reports |
-- |                                             for CR 542 Defect 3327       |
-- +==========================================================================+

    PROCEDURE BATCH_PROCESS  ( p_errbuf   IN OUT    VARCHAR2
                              ,p_retcode  IN OUT    NUMBER
                              ,p_batch_name        VARCHAR2
                              ,p_bank_name         VARCHAR2
                              ,p_bank_branch       VARCHAR2
                              ,p_bank_account_name VARCHAR2
                              ,p_document          VARCHAR2
                              ,p_pay_method        VARCHAR2
                              ,p_doc_order         VARCHAR2
                              ,p_pay_group         VARCHAR2
                              ,p_pay_thu_dt        VARCHAR2 -- CR 223
                              ,p_check_date        VARCHAR2 -- CR 223
                              ,p_batch_skip        VARCHAR2 -- CR 223
                              /* Begin new parameters */
                              ,p_select_invoices   VARCHAR2
                              ,p_build_payments    VARCHAR2
                              ,p_format_payments   VARCHAR2
                              ,p_format_program_name VARCHAR2
                              ,p_confirm_payment_batch  VARCHAR2
                              ,p_email_id          VARCHAR2
                              ,p_output_format     VARCHAR2
                              /* End  new parameters */
                              );

    /* CR 221 Begin Coding */
    PROCEDURE CONFIRM_BATCH_PROCESS ( p_errbuf   IN OUT    VARCHAR2
                                     ,p_retcode IN OUT    NUMBER
                                     ,p_payment_method    VARCHAR2 -- Defect5224
                                     ,p_confirm_payment_batch  VARCHAR2
                                    );
    /* CR 221 End Coding */

    /* Defect 9428 Begin Coding */
    PROCEDURE CANCEL_PAYMENT_BATCH ( p_checkrun_name   VARCHAR2
                                   );
    /* Defect 9428 End Coding */

   --  Defect 11961
    PROCEDURE HOLD_BATCH_PROCESSES ( p_errbuf   IN OUT    VARCHAR2
                                    ,p_retcode IN OUT    NUMBER
                                    );
    -- Added for Defect# 1431 R1.1
    PROCEDURE SUBMIT_APDM_REPORTS  ( x_error_buff         OUT VARCHAR2
                                    ,x_ret_code           OUT NUMBER
                                    );

--*****************************************
---Procedure Added for CR 542 Defect 3327--
--*****************************************
    PROCEDURE AP_TDM_FORMAT        (x_ret_code           OUT NUMBER
                                   );

END XX_AP_PAYMENT_BATCH_PKG;

/

SHOW ERROR