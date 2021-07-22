  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name          : XX_OE_PAYMENTS_V                                                          |
  -- |  Description   : OE Payments view based on union of EBS custom and seeded tables           |
  -- |  Change Record :                                                                           |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         14-Jul-2021  Ankit Jaiswal   Initial version                                  |
  -- +============================================================================================+

CREATE OR REPLACE VIEW XX_OE_PAYMENTS_V
AS 
    SELECT
        PAYMENT_TRX_ID	                
        ,COMMITMENT_APPLIED_AMOUNT	    
        ,COMMITMENT_INTERFACED_AMOUNT	
        ,PAYMENT_LEVEL_CODE	            
        ,HEADER_ID	                    
        ,CREATION_DATE	                
        ,CREATED_BY						
        ,LAST_UPDATE_DATE				
        ,LAST_UPDATED_BY					
        ,LINE_ID							
        ,LAST_UPDATE_LOGIN				
        ,REQUEST_ID						
        ,PROGRAM_APPLICATION_ID			
        ,PROGRAM_ID						
        ,PROGRAM_UPDATE_DATE				
        ,CONTEXT							
        ,ATTRIBUTE1						
        ,ATTRIBUTE2						
        ,ATTRIBUTE3						
        ,ATTRIBUTE4						
        ,ATTRIBUTE5						
        ,ATTRIBUTE6						
        ,ATTRIBUTE7						
        ,ATTRIBUTE8						
        ,ATTRIBUTE9						
        ,ATTRIBUTE10						
        ,ATTRIBUTE11						
        ,ATTRIBUTE12						
        ,ATTRIBUTE13						
        ,ATTRIBUTE14						
        ,ATTRIBUTE15						
        ,PAYMENT_TYPE_CODE				
        ,CREDIT_CARD_CODE				
        ,CREDIT_CARD_NUMBER				
        ,CREDIT_CARD_HOLDER_NAME			
        ,CREDIT_CARD_EXPIRATION_DATE		
        ,PREPAID_AMOUNT					
        ,PAYMENT_SET_ID					
        ,RECEIPT_METHOD_ID				
        ,PAYMENT_COLLECTION_EVENT		
        ,CREDIT_CARD_APPROVAL_CODE       
        ,CREDIT_CARD_APPROVAL_DATE       
        ,TANGIBLE_ID						
        ,CHECK_NUMBER					
        ,PAYMENT_AMOUNT					
        ,PAYMENT_NUMBER					
        ,LOCK_CONTROL					
        ,ORIG_SYS_PAYMENT_REF			
        ,DEFER_PAYMENT_PROCESSING_FLAG	
        ,PAYMENT_PERCENTAGE				
        ,TRXN_EXTENSION_ID				
        ,INST_ID							
        ,INVOICED_FLAG	
    FROM 
		XX_OE_PAYMENTS
    UNION
    SELECT 	
        PAYMENT_TRX_ID	                
        ,COMMITMENT_APPLIED_AMOUNT	    
        ,COMMITMENT_INTERFACED_AMOUNT	
        ,PAYMENT_LEVEL_CODE	            
        ,HEADER_ID	                    
        ,CREATION_DATE	                
        ,CREATED_BY						
        ,LAST_UPDATE_DATE				
        ,LAST_UPDATED_BY					
        ,LINE_ID							
        ,LAST_UPDATE_LOGIN				
        ,REQUEST_ID						
        ,PROGRAM_APPLICATION_ID			
        ,PROGRAM_ID						
        ,PROGRAM_UPDATE_DATE				
        ,CONTEXT							
        ,ATTRIBUTE1						
        ,ATTRIBUTE2						
        ,ATTRIBUTE3						
        ,ATTRIBUTE4						
        ,ATTRIBUTE5						
        ,ATTRIBUTE6						
        ,ATTRIBUTE7						
        ,ATTRIBUTE8						
        ,ATTRIBUTE9						
        ,ATTRIBUTE10						
        ,ATTRIBUTE11						
        ,ATTRIBUTE12						
        ,ATTRIBUTE13						
        ,ATTRIBUTE14						
        ,ATTRIBUTE15						
        ,PAYMENT_TYPE_CODE				
        ,CREDIT_CARD_CODE				
        ,CREDIT_CARD_NUMBER				
        ,CREDIT_CARD_HOLDER_NAME			
        ,CREDIT_CARD_EXPIRATION_DATE		
        ,PREPAID_AMOUNT					
        ,PAYMENT_SET_ID					
        ,RECEIPT_METHOD_ID				
        ,PAYMENT_COLLECTION_EVENT		
        ,CREDIT_CARD_APPROVAL_CODE       
        ,CREDIT_CARD_APPROVAL_DATE       
        ,TANGIBLE_ID						
        ,CHECK_NUMBER					
        ,PAYMENT_AMOUNT					
        ,PAYMENT_NUMBER					
        ,LOCK_CONTROL					
        ,ORIG_SYS_PAYMENT_REF			
        ,DEFER_PAYMENT_PROCESSING_FLAG	
        ,PAYMENT_PERCENTAGE				
        ,TRXN_EXTENSION_ID				
        ,INST_ID							
        ,INVOICED_FLAG	
    FROM 	
        OE_PAYMENTS	;