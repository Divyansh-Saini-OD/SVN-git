-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name :APPS.CE_999_INTERFACE_V                                            |
-- | Description : Create the Cash Management (CE) Reconciliation             |
-- |               Open Interface table view.                                 |
-- |               Recompile APPS views that depend on this view.             |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     12-Jul-2007  Terry Banks          Initial version               |
-- | v1.1     29-Jul-2007  Terry Banks          Added columns for lockbox     |
-- | v1.2     23-Jan-2008  Terry Banks          Changed a column name         |
-- | v1.3     25-Sep-2013  Vivek Seethamraju    E2079 - Included BANK_TRX_CODE|
-- |                                            for CRP2 defect 25609.        |
-- | v1.4     12-Nov-2015  Suresh Ponnambalam   Defect 1867. Removed xxfin.   |
-- |                                                                          |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON

CREATE OR REPLACE VIEW CE_999_INTERFACE_V (ROW_ID,
                                           TRX_ID,
                                           BANK_ACCOUNT_ID,
                                           TRX_TYPE,
                                           TRX_TYPE_DSP,
                                           TRX_NUMBER,
                                           TRX_DATE,
                                           CURRENCY_CODE,
                                           STATUS,
                                           STATUS_DSP,
                                           EXCHANGE_RATE_TYPE,
                                           EXCHANGE_RATE_DATE,
                                           EXCHANGE_RATE,
                                           AMOUNT,
                                           CLEARED_AMOUNT,
                                           CHARGES_AMOUNT,
                                           ERROR_AMOUNT,
                                           ACCTD_AMOUNT,
                                           ACCTD_CLEARED_AMOUNT,
                                           ACCTD_CHARGES_AMOUNT,
                                           ACCTD_ERROR_AMOUNT,
                                           GL_DATE,
                                           CLEARED_DATE,
                                           RECORD_TYPE,
                                           BANK_TRX_NUMBER_ORIGINAL,
                                           BANK_TRX_CODE_ID_ORIGINAL,
                                           BANK_ACCOUNT_NUM , 
                                           LOCKBOX_DEPOSIT_DATE,
                                           LOCKBOX_BATCH,
                                           RECEIPT_METHOD_ID,
                                           STATEMENT_HEADER_ID ,
                                           STATEMENT_LINE_ID ,
                                           AJB_FILE_NUMBER, 
                                           CREATION_DATE,
                                           CREATED_BY,
                                           LAST_UPDATE_DATE,
                                           LAST_UPDATED_BY,
                                           BANK_TRX_CODE_ORIGINAL
                                          )
AS
   SELECT T.ROWID, 
       T.TRX_ID,
       T.BANK_ACCOUNT_ID,
       T.TRX_TYPE,
       T.TRX_TYPE_DSP,
       T.TRX_NUMBER,
       T.TRX_DATE,
       T.CURRENCY_CODE,
       T.STATUS,
       T.STATUS_DSP,
       T.EXCHANGE_RATE_TYPE,
       T.EXCHANGE_RATE_DATE,
       T.EXCHANGE_RATE,
       T.AMOUNT,
       T.CLEARED_AMOUNT,
       T.CHARGES_AMOUNT,
       T.ERROR_AMOUNT,
       T.ACCTD_AMOUNT,
       T.ACCTD_CLEARED_AMOUNT,
       T.ACCTD_CHARGES_AMOUNT,
       T.ACCTD_ERROR_AMOUNT,
       T.GL_DATE,
       T.CLEARED_DATE,
       T.RECORD_TYPE,
       T.BANK_TRX_NUMBER_ORIGINAL,
       T.BANK_TRX_CODE_ID_ORIGINAL,
       T.BANK_ACCOUNT_NUM ,       
       T.LOCKBOX_DEPOSIT_DATE, 
       T.LOCKBOX_BATCH,        
       T.RECEIPT_METHOD_ID,    
       T.STATEMENT_HEADER_ID,  
       T.STATEMENT_LINE_ID,    
       T.BANK_REC_ID,      
       T.CREATION_DATE,        
       T.CREATED_BY,           
       T.LAST_UPDATE_DATE,     
       T.LAST_UPDATED_BY,      
       T.BANK_TRX_CODE_ORIGINAL
     FROM XX_CE_999_INTERFACE T ;
 
ALTER VIEW APPS.CE_999_TRANSACTIONS_V COMPILE ;
 
ALTER VIEW APPS.CE_999_REVERSAL_V COMPILE ;
 
ALTER VIEW APPS.CE_999_RECONCILED_V COMPILE ;
 
SHOW ERROR