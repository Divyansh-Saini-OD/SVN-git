CREATE OR REPLACE PACKAGE BODY APPS.XX_GL_INTF_NA_STG_PKG
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:   XX_GL_INTERFACE_NA_STG                                                            |
-- |  Description:  Called BPEL Processes to insert into XX_GL_INTERFACE_NA_STG                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_XX_GL_INTF_NA_STG                                                            |
-- |  Description: This procedure will insert records into XX_GL_INTERFACE_NA_STG table         |
-- =============================================================================================|
PROCEDURE INSERT_XX_GL_INTF_NA_STG(
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	  	         ,p_xx_gl_intf_na_stg_list_t	IN  XX_GL_INTF_NA_STG_LIST_T
			)


IS

v_error_flag	VARCHAR2(1):='N';

BEGIN

  FOR i IN 1..p_xx_gl_intf_na_stg_list_t.COUNT LOOP 
      
    BEGIN
      INSERT 
        INTO xxfin.XX_GL_INTERFACE_NA_STG
	   (      STATUS                                    	    
		, SET_OF_BOOKS_ID                                    
		, ACCOUNTING_DATE                            	    
		, CURRENCY_CODE                              	    
		, DATE_CREATED                               	    
		, CREATED_BY                                         
		, ACTUAL_FLAG                                       
		, USER_JE_CATEGORY_NAME                              
		, USER_JE_SOURCE_NAME                                
		, CURRENCY_CONVERSION_DATE                           
		, ENCUMBRANCE_TYPE_ID                                
		, BUDGET_VERSION_ID                                  
		, USER_CURRENCY_CONVERSION_TYPE                      
		, CURRENCY_CONVERSION_RATE                           
		, AVERAGE_JOURNAL_FLAG                            
		, ORIGINATING_BAL_SEG_VALUE                          
		, SEGMENT1                                           
		, SEGMENT2                                           
		, SEGMENT3                                           
		, SEGMENT4                                           
		, SEGMENT5                                           
		, SEGMENT6                                           
		, SEGMENT7                                           
		, SEGMENT8                                           
		, SEGMENT9                                           
		, SEGMENT10                                          
		, SEGMENT11                                          
		, SEGMENT12                                          
		, SEGMENT13                                          
		, SEGMENT14                                          
		, SEGMENT15                                          
		, SEGMENT16                                          
		, SEGMENT17                                          
		, SEGMENT18                                          
		, SEGMENT19                                          
		, SEGMENT20                                          
		, SEGMENT21                                          
		, SEGMENT22                                          
		, SEGMENT23                                          
		, SEGMENT24                                          
		, SEGMENT25                                          
		, SEGMENT26                                          
		, SEGMENT27                                          
		, SEGMENT28                                          
		, SEGMENT29                                          
		, SEGMENT30                                          
		, ENTERED_DR                                         
		, ENTERED_CR                                         
		, ACCOUNTED_DR                                       
		, ACCOUNTED_CR                                       
		, TRANSACTION_DATE                                   
		, REFERENCE1                                         
		, REFERENCE2                                         
		, REFERENCE3                                         
		, REFERENCE4                                         
		, REFERENCE5                                         
		, REFERENCE6                                         
		, REFERENCE7                                         
		, REFERENCE8                                         
		, REFERENCE9                                         
		, REFERENCE10                                        
		, REFERENCE11                                        
		, REFERENCE12                                        
		, REFERENCE13                                        
		, REFERENCE14                                        
		, REFERENCE15                                        
		, REFERENCE16                                        
		, REFERENCE17                                        
		, REFERENCE18                                        
		, REFERENCE19                                        
		, REFERENCE20                                        
		, REFERENCE21                                        
		, REFERENCE22                                        
		, REFERENCE23                                        
		, REFERENCE24                                        
		, REFERENCE25                                        
		, REFERENCE26                                        
		, REFERENCE27                                        
		, REFERENCE28                                        
		, REFERENCE29                                        
		, REFERENCE30                                        
		, JE_BATCH_ID                                        
		, PERIOD_NAME                                        
		, JE_HEADER_ID                                       
		, JE_LINE_NUM                                        
		, CHART_OF_ACCOUNTS_ID                               
		, FUNCTIONAL_CURRENCY_CODE                           
		, CODE_COMBINATION_ID                                
		, DATE_CREATED_IN_GL                                 
		, WARNING_CODE                                       
		, STATUS_DESCRIPTION                                 
		, STAT_AMOUNT                                        
		, GROUP_ID                                           
		, REQUEST_ID                                         
		, SUBLEDGER_DOC_SEQUENCE_ID                          
		, SUBLEDGER_DOC_SEQUENCE_VALUE                       
		, ATTRIBUTE1                                         
		, ATTRIBUTE2                                         
		, GL_SL_LINK_ID                                      
		, GL_SL_LINK_TABLE                                   
		, ATTRIBUTE3                                         
		, ATTRIBUTE4                                         
		, ATTRIBUTE5                                         
		, ATTRIBUTE6                                         
		, ATTRIBUTE7                                         
		, ATTRIBUTE8                                         
		, ATTRIBUTE9                                         
		, ATTRIBUTE10                                        
		, ATTRIBUTE11                                        
		, ATTRIBUTE12                                        
		, ATTRIBUTE13                                        
		, ATTRIBUTE14                                        
		, ATTRIBUTE15                                        
		, ATTRIBUTE16                                        
		, ATTRIBUTE17                                        
		, ATTRIBUTE18                                        
		, ATTRIBUTE19                                        
		, ATTRIBUTE20                                        
		, CONTEXT                                            
		, CONTEXT2                                           
		, INVOICE_DATE                                       
		, TAX_CODE                                           
		, INVOICE_IDENTIFIER                                 
		, INVOICE_AMOUNT                                     
		, CONTEXT3                                           
		, USSGL_TRANSACTION_CODE                             
		, DESCR_FLEX_ERROR_MESSAGE                           
		, JGZZ_RECON_REF                                     
		, REFERENCE_DATE                                     
		, LEGACY_SEGMENT1                                    
		, LEGACY_SEGMENT2                                    
		, LEGACY_SEGMENT3                                    
		, LEGACY_SEGMENT4                                    
		, LEGACY_SEGMENT5                                    
		, LEGACY_SEGMENT6                                    
		, LEGACY_SEGMENT7                                    
		, DERIVED_VAL                                        
		, DERIVED_SOB                                        
		, BALANCED                                           

	   )
    VALUES
          (       p_xx_gl_intf_na_stg_list_t(i).STATUS                                    	    
		, p_xx_gl_intf_na_stg_list_t(i).SET_OF_BOOKS_ID                                    
		, p_xx_gl_intf_na_stg_list_t(i).ACCOUNTING_DATE                            	    
		, p_xx_gl_intf_na_stg_list_t(i).CURRENCY_CODE                              	    
		, p_xx_gl_intf_na_stg_list_t(i).DATE_CREATED                               	    
		, p_xx_gl_intf_na_stg_list_t(i).CREATED_BY                                         
		, p_xx_gl_intf_na_stg_list_t(i).ACTUAL_FLAG                                       
		, p_xx_gl_intf_na_stg_list_t(i).USER_JE_CATEGORY_NAME                              
		, p_xx_gl_intf_na_stg_list_t(i).USER_JE_SOURCE_NAME                                
		, p_xx_gl_intf_na_stg_list_t(i).CURRENCY_CONVERSION_DATE                           
		, p_xx_gl_intf_na_stg_list_t(i).ENCUMBRANCE_TYPE_ID                                
		, p_xx_gl_intf_na_stg_list_t(i).BUDGET_VERSION_ID                                  
		, p_xx_gl_intf_na_stg_list_t(i).USER_CURRENCY_CONVERSION_TYPE                      
		, p_xx_gl_intf_na_stg_list_t(i).CURRENCY_CONVERSION_RATE                           
		, p_xx_gl_intf_na_stg_list_t(i).AVERAGE_JOURNAL_FLAG                            
		, p_xx_gl_intf_na_stg_list_t(i).ORIGINATING_BAL_SEG_VALUE                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT1                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT2                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT3                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT4                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT5                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT6                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT7                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT8                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT9                                           
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT10                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT11                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT12                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT13                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT14                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT15                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT16                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT17                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT18                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT19                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT20                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT21                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT22                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT23                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT24                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT25                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT26                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT27                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT28                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT29                                          
		, p_xx_gl_intf_na_stg_list_t(i).SEGMENT30                                          
		, p_xx_gl_intf_na_stg_list_t(i).ENTERED_DR                                         
		, p_xx_gl_intf_na_stg_list_t(i).ENTERED_CR                                         
		, p_xx_gl_intf_na_stg_list_t(i).ACCOUNTED_DR                                       
		, p_xx_gl_intf_na_stg_list_t(i).ACCOUNTED_CR                                       
		, p_xx_gl_intf_na_stg_list_t(i).TRANSACTION_DATE                                   
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE1                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE2                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE3                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE4                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE5                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE6                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE7                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE8                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE9                                         
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE10                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE11                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE12                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE13                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE14                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE15                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE16                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE17                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE18                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE19                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE20                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE21                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE22                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE23                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE24                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE25                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE26                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE27                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE28                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE29                                        
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE30                                        
		, p_xx_gl_intf_na_stg_list_t(i).JE_BATCH_ID                                        
		, p_xx_gl_intf_na_stg_list_t(i).PERIOD_NAME                                        
		, p_xx_gl_intf_na_stg_list_t(i).JE_HEADER_ID                                       
		, p_xx_gl_intf_na_stg_list_t(i).JE_LINE_NUM                                        
		, p_xx_gl_intf_na_stg_list_t(i).CHART_OF_ACCOUNTS_ID                               
		, p_xx_gl_intf_na_stg_list_t(i).FUNCTIONAL_CURRENCY_CODE                           
		, p_xx_gl_intf_na_stg_list_t(i).CODE_COMBINATION_ID                                
		, p_xx_gl_intf_na_stg_list_t(i).DATE_CREATED_IN_GL                                 
		, p_xx_gl_intf_na_stg_list_t(i).WARNING_CODE                                       
		, p_xx_gl_intf_na_stg_list_t(i).STATUS_DESCRIPTION                                 
		, p_xx_gl_intf_na_stg_list_t(i).STAT_AMOUNT                                        
		, p_xx_gl_intf_na_stg_list_t(i).GROUP_ID                                           
		, p_xx_gl_intf_na_stg_list_t(i).REQUEST_ID                                         
		, p_xx_gl_intf_na_stg_list_t(i).SUBLEDGER_DOC_SEQUENCE_ID                          
		, p_xx_gl_intf_na_stg_list_t(i).SUBLEDGER_DOC_SEQUENCE_VALUE                       
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE1                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE2                                         
		, p_xx_gl_intf_na_stg_list_t(i).GL_SL_LINK_ID                                      
		, p_xx_gl_intf_na_stg_list_t(i).GL_SL_LINK_TABLE                                   
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE3                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE4                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE5                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE6                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE7                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE8                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE9                                         
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE10                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE11                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE12                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE13                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE14                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE15                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE16                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE17                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE18                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE19                                        
		, p_xx_gl_intf_na_stg_list_t(i).ATTRIBUTE20                                        
		, p_xx_gl_intf_na_stg_list_t(i).CONTEXT                                            
		, p_xx_gl_intf_na_stg_list_t(i).CONTEXT2                                           
		, p_xx_gl_intf_na_stg_list_t(i).INVOICE_DATE                                       
		, p_xx_gl_intf_na_stg_list_t(i).TAX_CODE                                           
		, p_xx_gl_intf_na_stg_list_t(i).INVOICE_IDENTIFIER                                 
		, p_xx_gl_intf_na_stg_list_t(i).INVOICE_AMOUNT                                     
		, p_xx_gl_intf_na_stg_list_t(i).CONTEXT3                                           
		, p_xx_gl_intf_na_stg_list_t(i).USSGL_TRANSACTION_CODE                             
		, p_xx_gl_intf_na_stg_list_t(i).DESCR_FLEX_ERROR_MESSAGE                           
		, p_xx_gl_intf_na_stg_list_t(i).JGZZ_RECON_REF                                     
		, p_xx_gl_intf_na_stg_list_t(i).REFERENCE_DATE                                     
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT1                                    
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT2                                    
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT3                                    
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT4                                    
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT5                                    
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT6                                    
		, p_xx_gl_intf_na_stg_list_t(i).LEGACY_SEGMENT7                                    
		, p_xx_gl_intf_na_stg_list_t(i).DERIVED_VAL                                        
		, p_xx_gl_intf_na_stg_list_t(i).DERIVED_SOB                                        
		, p_xx_gl_intf_na_stg_list_t(i).BALANCED                                           
	   );
    EXCEPTION
      WHEN others THEN
	v_error_flag:='Y';
    END;
  END LOOP; 
  IF v_error_flag='Y' THEN
     ROLLBACK;
     p_errbuff:='Error while inserting records for XX_GL_INTERFACE_NA_STG table';
     p_retcode:=2;
  ELSE
     COMMIT;
     p_errbuff:=NULL;
     p_retcode:=0;
  END IF;
EXCEPTION
  WHEN others THEN
    p_errbuff:='EXception When others :'|| sqlerrm;
    p_retcode:=sqlcode;
END INSERT_XX_GL_INTF_NA_STG;

END XX_GL_INTF_NA_STG_PKG;
/
