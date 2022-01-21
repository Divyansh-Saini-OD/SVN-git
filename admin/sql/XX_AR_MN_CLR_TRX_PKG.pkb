SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_AR_MN_CLR_TRX_PKG

PROMPT Program exits if the creation is not successful

WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE body XX_AR_MN_CLR_TRX_PKG AS
-- =================================================================================
--   NAME:       XX_AR_MN_CLR_TRX_PKG
--   PURPOSE:    This package is used to clear the transaction

--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  ------------------------------------
--   1.0        29/04/2011  Jay Gupta        Initial Version
--   1.1        26/05/2011  Gaurav A         code modified for defect 11742
-- =================================================================================


   PROCEDURE update_receipts(p_gt_rcpt_det tbl_rcpt_det,p_status OUT  VARCHAR2)
   IS
   BEGIN
      FOR ln_idx IN p_gt_rcpt_det.FIRST .. p_gt_rcpt_det.LAST
      LOOP
      UPDATE xx_Ce_ajb998
         SET STATUS_1295 = 'Y'
            ,LAST_UPDATE_DATE = SYSDATE
            ,LAST_UPDATED_BY = fnd_profile.VALUE ('USER_ID')
       WHERE ORDER_PAYMENT_ID = p_gt_rcpt_det(ln_idx);
                       
      UPDATE Xx_Ar_Order_Receipt_Dtl
         SET RECEIPT_STATUS = 'CLEARED'
	    ,CLEARED_DATE = SYSDATE
            ,LAST_UPDATE_DATE = SYSDATE
            ,LAST_UPDATED_BY = fnd_profile.VALUE ('USER_ID')
       WHERE ORDER_PAYMENT_ID = p_gt_rcpt_det(ln_idx);
      END LOOP;
      COMMIT;
      p_status := 'PASS';
   EXCEPTION
      WHEN OTHERS THEN 
         p_status := 'FAIL';         
   END update_receipts;
   
   PROCEDURE update_interface(p_bank_rec_id VARCHAR2, p_processor_id VARCHAR2,p_status OUT VARCHAR2)
   IS
   BEGIN

      UPDATE xx_Ce_999_Interface
         SET STATUS = 'CLEARED'
      ,CLEARED_DATE = SYSDATE
      ,LAST_UPDATE_DATE = SYSDATE
      ,LAST_UPDATED_BY = fnd_profile.VALUE ('USER_ID')
      ,Receipts_Complete = 'Y'   -- added for v1.1
                , Receipts_Processed_CTR  = 1  -- added for v1.1
       WHERE BANK_REC_ID = P_BANK_REC_ID
         AND PROCESSOR_ID = P_PROCESSOR_ID;
                       
      UPDATE xx_Ce_ajb998
         SET STATUS_1295 = 'Y'
            ,LAST_UPDATE_DATE = SYSDATE
            ,LAST_UPDATED_BY = fnd_profile.VALUE ('USER_ID')
       WHERE BANK_REC_ID = P_BANK_REC_ID
         AND PROCESSOR_ID = P_PROCESSOR_ID;
                       
      UPDATE Xx_Ar_Order_Receipt_Dtl
         SET RECEIPT_STATUS = 'CLEARED'
	    ,CLEARED_DATE = SYSDATE
            ,LAST_UPDATE_DATE = SYSDATE
            ,LAST_UPDATED_BY = fnd_profile.VALUE ('USER_ID')
       WHERE ORDER_PAYMENT_ID IN ( SELECT ORDER_PAYMENT_ID 
                                     FROM xx_Ce_ajb998 
				    WHERE BANK_REC_ID = P_BANK_REC_ID
                                      AND PROCESSOR_ID = P_PROCESSOR_ID
				   );    

      COMMIT;
      p_status := 'PASS';
   EXCEPTION
      WHEN OTHERS THEN 
         p_status := 'FAIL';            
   END update_interface;
END XX_AR_MN_CLR_TRX_PKG;
/
SHOW ERROR;
