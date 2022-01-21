CREATE OR REPLACE PACKAGE BODY APPS.XX_CE_AJB_INSERT_STG_PKG   
AS

-- +============================================================================================+
-- |  Office Depot - Project Simplify                                                           |
-- |                                                                                            |
-- +============================================================================================+
-- |  Name:  XX_CE_AJB_INSERT_STG_PKG                                                           |
-- |  Description:  Called BPEL Processes to insert into XX_CE_AJB996, XX_CE_AJB998,            |
-- |	            XX_CE_AJB999, XX_AR_MAIL_CHECK_HOLDS tables                                 |
-- |                                                                                            |
-- |  Change Record:                                                                            |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.0         03-NOV-2012  Paddy Sanjeevi   Initial version                                  |
-- | 1.1         22-Jan-2013  Paddy Sanjeevi   Defect 21958 (Hardcoded NEW for status_1310      |
-- +============================================================================================+
 
-- +============================================================================================+
-- |  Name: INSERT_MAIL_CHECK_HOLDS                                                             |
-- |  Description: This procedure will insert records into XX_AR_MAIL_CHECK_HOLDS table         |
-- =============================================================================================|
PROCEDURE INSERT_AJB996 (
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	    	         ,p_ce_ajb996_list_t		IN  XX_CE_AJB996_LIST_T
			)
IS
v_error_flag VARCHAR2(1):='N';
v_error_message VARCHAR2(4000);
v_mesg		VARCHAR2(2000);
BEGIN

  FOR i IN 1..p_ce_ajb996_list_t.COUNT LOOP 

    BEGIN
      INSERT
        INTO XX_CE_AJB996
	  ( record_type                 
	   ,vset_file                                          
	   ,sdate                                              
	   ,action_code                                
	   ,attribute1                                         
	   ,provider_type                              
	   ,attribute2                                         
           ,store_num                                  
	   ,terminal_num                            
	   ,trx_type                                   
	   ,attribute3                                         
	   ,attribute4                                         
	   ,card_num                                           
	   ,attribute5                                         
	   ,attribute6                                         
	   ,trx_amount                                
 	   ,invoice_num                                        
	   ,country_code                             
	   ,currency_code                           
	   ,attribute7                                         
	   ,attribute8                                         
	   ,attribute9                                         
	   ,attribute10                                        
	   ,attribute11                                        
	   ,attribute12                                        
	   ,attribute13                                        
	   ,attribute14                                        
	   ,attribute15                                        
	   ,attribute16                                        
	   ,attribute17                                        
	   ,attribute18                                        
	   ,attribute19                                        
	   ,attribute20                                        
	   ,receipt_num                              
	   ,attribute21                                        
	   ,attribute22                                        
	   ,auth_num                                           
	   ,attribute23                                        
	   ,attribute24                                        
	   ,attribute25                                        
	   ,attribute26                                        
	   ,attribute27                                        
	   ,attribute28                                        
	   ,attribute29                                        
	   ,attribute30                                        
	   ,bank_rec_id                                        
	   ,attribute31                                        
	   ,attribute32                                        
	   ,trx_date                                   
	   ,attribute33                                        
	   ,attribute34                                        
	   ,attribute35                                        
	   ,processor_id                               
	   ,master_noauth_fee                           
	   ,chbk_rate                                         
	   ,chbk_amt                                         
	   ,chbk_action_code                                   
	   ,chbk_action_date                                   
	   ,chbk_ref_num                                       
	   ,ret_ref_num                                        
	   ,other_rate1                                      
	   ,other_rate2                                      
	   ,creation_date                                      
	   ,created_by                                         
	   ,last_update_date                               
	   ,last_updated_by                                
	   ,attribute36                                        
	   ,attribute37                                        
	   ,attribute38                                        
	   ,attribute39                                        
	   ,attribute40                                        
	   ,attribute41                                        
	   ,attribute42                                        
	   ,attribute43                                        
	   ,status                                             
	   ,status_1310                                   
	   ,status_1295                                   
	   ,chbk_alpha_code                          
	   ,chbk_numeric_code                     
	   ,sequence_id_996                          
	   ,org_id                                           
	   ,ipay_batch_num                                     
	   ,ajb_file_name                              
	   ,recon_date                                   
	   ,ar_cash_receipt_id                      
	   ,recon_header_id                         
	   ,territory_code                             
	   ,currency 
 	  )                                     
    VALUES
	  ( p_ce_ajb996_list_t(i).record_type                 
	   ,p_ce_ajb996_list_t(i).vset_file                                          
	   ,p_ce_ajb996_list_t(i).sdate                                              
	   ,p_ce_ajb996_list_t(i).action_code                                
	   ,p_ce_ajb996_list_t(i).attribute1                                         
	   ,p_ce_ajb996_list_t(i).provider_type                              
	   ,p_ce_ajb996_list_t(i).attribute2                                         
           ,p_ce_ajb996_list_t(i).store_num                                  
	   ,p_ce_ajb996_list_t(i).terminal_num                            
	   ,p_ce_ajb996_list_t(i).trx_type                                   
	   ,p_ce_ajb996_list_t(i).attribute3                                         
	   ,p_ce_ajb996_list_t(i).attribute4                                         
	   ,p_ce_ajb996_list_t(i).card_num                                           
	   ,p_ce_ajb996_list_t(i).attribute5                                         
	   ,p_ce_ajb996_list_t(i).attribute6                                         
	   ,p_ce_ajb996_list_t(i).trx_amount                                
 	   ,p_ce_ajb996_list_t(i).invoice_num                                        
	   ,p_ce_ajb996_list_t(i).country_code                             
	   ,p_ce_ajb996_list_t(i).currency_code                           
	   ,p_ce_ajb996_list_t(i).attribute7                                         
	   ,p_ce_ajb996_list_t(i).attribute8                                         
	   ,p_ce_ajb996_list_t(i).attribute9                                         
	   ,p_ce_ajb996_list_t(i).attribute10                                        
	   ,p_ce_ajb996_list_t(i).attribute11                                        
	   ,p_ce_ajb996_list_t(i).attribute12                                        
	   ,p_ce_ajb996_list_t(i).attribute13                                        
	   ,p_ce_ajb996_list_t(i).attribute14                                        
	   ,p_ce_ajb996_list_t(i).attribute15                                        
	   ,p_ce_ajb996_list_t(i).attribute16                                        
	   ,p_ce_ajb996_list_t(i).attribute17                                        
	   ,p_ce_ajb996_list_t(i).attribute18                                        
	   ,p_ce_ajb996_list_t(i).attribute19                                        
	   ,p_ce_ajb996_list_t(i).attribute20                                        
	   ,p_ce_ajb996_list_t(i).receipt_num                              
	   ,p_ce_ajb996_list_t(i).attribute21                                        
	   ,p_ce_ajb996_list_t(i).attribute22                                        
	   ,p_ce_ajb996_list_t(i).auth_num                                           
	   ,p_ce_ajb996_list_t(i).attribute23                                        
	   ,p_ce_ajb996_list_t(i).attribute24                                        
	   ,p_ce_ajb996_list_t(i).attribute25                                        
	   ,p_ce_ajb996_list_t(i).attribute26                                        
	   ,p_ce_ajb996_list_t(i).attribute27                                        
	   ,p_ce_ajb996_list_t(i).attribute28                                        
	   ,p_ce_ajb996_list_t(i).attribute29                                        
	   ,p_ce_ajb996_list_t(i).attribute30                                        
	   ,p_ce_ajb996_list_t(i).bank_rec_id                                        
	   ,p_ce_ajb996_list_t(i).attribute31                                        
	   ,p_ce_ajb996_list_t(i).attribute32                                        
	   ,p_ce_ajb996_list_t(i).trx_date                                   
	   ,p_ce_ajb996_list_t(i).attribute33                                        
	   ,p_ce_ajb996_list_t(i).attribute34                                        
	   ,p_ce_ajb996_list_t(i).attribute35                                        
	   ,p_ce_ajb996_list_t(i).processor_id                               
	   ,p_ce_ajb996_list_t(i).master_noauth_fee                           
	   ,p_ce_ajb996_list_t(i).chbk_rate                                         
	   ,p_ce_ajb996_list_t(i).chbk_amt                                         
	   ,p_ce_ajb996_list_t(i).chbk_action_code                                   
	   ,p_ce_ajb996_list_t(i).chbk_action_date                                   
	   ,p_ce_ajb996_list_t(i).chbk_ref_num                                       
	   ,p_ce_ajb996_list_t(i).ret_ref_num                                        
	   ,p_ce_ajb996_list_t(i).other_rate1                                      
	   ,p_ce_ajb996_list_t(i).other_rate2                                      
	   ,p_ce_ajb996_list_t(i).creation_date                                      
	   ,p_ce_ajb996_list_t(i).created_by                                         
	   ,p_ce_ajb996_list_t(i).last_update_date                               
	   ,p_ce_ajb996_list_t(i).last_updated_by                                
	   ,p_ce_ajb996_list_t(i).attribute36                                        
	   ,p_ce_ajb996_list_t(i).attribute37                                        
	   ,p_ce_ajb996_list_t(i).attribute38                                        
	   ,p_ce_ajb996_list_t(i).attribute39                                        
	   ,p_ce_ajb996_list_t(i).attribute40                                        
	   ,p_ce_ajb996_list_t(i).attribute41                                        
	   ,p_ce_ajb996_list_t(i).attribute42                                        
	   ,p_ce_ajb996_list_t(i).attribute43                                        
	   ,p_ce_ajb996_list_t(i).status                                             
	   ,'NEW'                                   
	   ,p_ce_ajb996_list_t(i).status_1295                                   
	   ,p_ce_ajb996_list_t(i).chbk_alpha_code                          
	   ,p_ce_ajb996_list_t(i).chbk_numeric_code                     
	   ,p_ce_ajb996_list_t(i).sequence_id_996                          
	   ,p_ce_ajb996_list_t(i).org_id                                           
	   ,p_ce_ajb996_list_t(i).ipay_batch_num                                     
	   ,p_ce_ajb996_list_t(i).ajb_file_name                              
	   ,p_ce_ajb996_list_t(i).recon_date                                   
	   ,p_ce_ajb996_list_t(i).ar_cash_receipt_id                      
	   ,p_ce_ajb996_list_t(i).recon_header_id                         
	   ,p_ce_ajb996_list_t(i).territory_code                             
	   ,p_ce_ajb996_list_t(i).currency 
 	  );                                     
    EXCEPTION
      WHEN others THEN
	v_error_flag:='Y';
	v_mesg:=SUBSTR(SQLERRM,1,1000);
	IF LENGTH(v_error_message)<3000 THEN
  	   v_error_message:=v_error_message||v_mesg;
	END IF;
    END;
  END LOOP;
  COMMIT;
  IF v_error_flag='Y' THEN
     p_errbuff:='Error while inserting ce_AJB996 :'||v_error_message;
     p_retcode:='2';
  ELSE
     p_errbuff:=NULL;
     p_retcode:='0';
  END IF;
EXCEPTION
  WHEN others THEN
    p_errbuff:='EXception When others :'|| sqlerrm ||v_error_message;
    p_retcode:='2';
END INSERT_AJB996;


PROCEDURE INSERT_AJB998 (
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
  	    	         ,p_ce_ajb998_list_t		IN  XX_CE_AJB998_LIST_T
			)
IS
v_error_flag VARCHAR2(1):='N';
v_error_message VARCHAR2(4000);
v_mesg		VARCHAR2(2000);

BEGIN

  FOR i IN 1..p_ce_ajb998_list_t.COUNT LOOP 

    BEGIN
      INSERT
        INTO XX_CE_AJB998
	    ( record_type                 
	     ,vset_file                                          
   	     ,sdate                                              
	     ,action_code                                
   	     ,attribute1                                         
	     ,provider_type                             
	     ,attribute2                                         
	     ,store_num                                 
	     ,terminal_num                                       
	     ,trx_type                                  
	     ,attribute3                                         
	     ,attribute4                                         
	     ,card_num                                           
	     ,attribute5                                         
	     ,attribute6                                         
	     ,trx_amount                                 
	     ,invoice_num                                        
	     ,country_code                              
	     ,currency_code                             
	     ,attribute7                                         
	     ,attribute8                                         
	     ,attribute9                                         
	     ,attribute10                                        
	     ,attribute11                                        
	     ,attribute12                                        
	     ,attribute13                                        
	     ,attribute14                                        
	     ,attribute15                                        
	     ,attribute16                                        
	     ,attribute17                                        
	     ,attribute18                                        
	     ,attribute19                                        
	     ,attribute20                                        
	     ,receipt_num                               
	     ,attribute21                                        
	     ,attribute22                                        
	     ,auth_num                                           
	     ,attribute23                                        
	     ,attribute24                                        
	     ,attribute25                                        
	     ,attribute26                                        
	     ,attribute27                                        
	     ,attribute28                                        
	     ,attribute29                                        
	     ,attribute30                                        
	     ,bank_rec_id                                        
	     ,attribute31                                        
	     ,attribute32                                        
	     ,trx_date                                   
	     ,attribute33                                        
	     ,attribute34                                        
	     ,attribute35                                        
	     ,processor_id                              
	     ,network_fee                                        
	     ,adj_fee                                            
	     ,adj_date                                           
	     ,adj_reason_code                                    
	     ,adj_reason_desc                                    
	     ,rej_reason_code                                    
	     ,rej_reason_desc                                    
	     ,other_fee1                                         
	     ,other_fee2                                         
	     ,fund_percent                                       
	     ,ref_num                                            
	     ,dis_amt                                            
	     ,dis_rate                                           
	     ,service_rate                                       
	     ,other_rate1                                        
	     ,other_rate2                                        
	     ,creation_date                                      
	     ,created_by                                         
	     ,last_update_date                                   
 	     ,last_updated_by                                    
	     ,attribute36                                        
	     ,attribute37                                        
	     ,attribute38                                        
 	     ,attribute39                                        
	     ,attribute40                                        
	     ,attribute41                                        
	     ,attribute42                                        
	     ,attribute43                                        
	     ,status                                             
	     ,status_1310                                        
	     ,status_1295                                        
	     ,sequence_id_998                            
	     ,org_id                                             
	     ,ipay_batch_num                                     
	    ,ajb_file_name                                      
           )
      VALUES
	    ( p_ce_ajb998_list_t(i).record_type                 
	     ,p_ce_ajb998_list_t(i).vset_file                                          
   	     ,p_ce_ajb998_list_t(i).sdate                                              
	     ,p_ce_ajb998_list_t(i).action_code                                
   	     ,p_ce_ajb998_list_t(i).attribute1                                         
	     ,p_ce_ajb998_list_t(i).provider_type                             
	     ,p_ce_ajb998_list_t(i).attribute2                                         
	     ,p_ce_ajb998_list_t(i).store_num                                 
	     ,p_ce_ajb998_list_t(i).terminal_num                                       
	     ,p_ce_ajb998_list_t(i).trx_type                                  
	     ,p_ce_ajb998_list_t(i).attribute3                                         
	     ,p_ce_ajb998_list_t(i).attribute4                                         
	     ,p_ce_ajb998_list_t(i).card_num                                           
	     ,p_ce_ajb998_list_t(i).attribute5                                         
	     ,p_ce_ajb998_list_t(i).attribute6                                         
	     ,p_ce_ajb998_list_t(i).trx_amount                                 
	     ,p_ce_ajb998_list_t(i).invoice_num                                        
	     ,p_ce_ajb998_list_t(i).country_code                              
	     ,p_ce_ajb998_list_t(i).currency_code                             
	     ,p_ce_ajb998_list_t(i).attribute7                                         
	     ,p_ce_ajb998_list_t(i).attribute8                                         
	     ,p_ce_ajb998_list_t(i).attribute9                                         
	     ,p_ce_ajb998_list_t(i).attribute10                                        
	     ,p_ce_ajb998_list_t(i).attribute11                                        
	     ,p_ce_ajb998_list_t(i).attribute12                                        
	     ,p_ce_ajb998_list_t(i).attribute13                                        
	     ,p_ce_ajb998_list_t(i).attribute14                                        
	     ,p_ce_ajb998_list_t(i).attribute15                                        
	     ,p_ce_ajb998_list_t(i).attribute16                                        
	     ,p_ce_ajb998_list_t(i).attribute17                                        
	     ,p_ce_ajb998_list_t(i).attribute18                                        
	     ,p_ce_ajb998_list_t(i).attribute19                                        
	     ,p_ce_ajb998_list_t(i).attribute20                                        
	     ,p_ce_ajb998_list_t(i).receipt_num                               
	     ,p_ce_ajb998_list_t(i).attribute21                                        
	     ,p_ce_ajb998_list_t(i).attribute22                                        
	     ,p_ce_ajb998_list_t(i).auth_num                                           
	     ,p_ce_ajb998_list_t(i).attribute23                                        
	     ,p_ce_ajb998_list_t(i).attribute24                                        
	     ,p_ce_ajb998_list_t(i).attribute25                                        
	     ,p_ce_ajb998_list_t(i).attribute26                                        
	     ,p_ce_ajb998_list_t(i).attribute27                                        
	     ,p_ce_ajb998_list_t(i).attribute28                                        
	     ,p_ce_ajb998_list_t(i).attribute29                                        
	     ,p_ce_ajb998_list_t(i).attribute30                                        
	     ,p_ce_ajb998_list_t(i).bank_rec_id                                        
	     ,p_ce_ajb998_list_t(i).attribute31                                        
	     ,p_ce_ajb998_list_t(i).attribute32                                        
	     ,p_ce_ajb998_list_t(i).trx_date                                   
	     ,p_ce_ajb998_list_t(i).attribute33                                        
	     ,p_ce_ajb998_list_t(i).attribute34                                        
	     ,p_ce_ajb998_list_t(i).attribute35                                        
	     ,p_ce_ajb998_list_t(i).processor_id                              
	     ,p_ce_ajb998_list_t(i).network_fee                                        
	     ,p_ce_ajb998_list_t(i).adj_fee                                            
	     ,p_ce_ajb998_list_t(i).adj_date                                           
	     ,p_ce_ajb998_list_t(i).adj_reason_code                                    
	     ,p_ce_ajb998_list_t(i).adj_reason_desc                                    
	     ,p_ce_ajb998_list_t(i).rej_reason_code                                    
	     ,p_ce_ajb998_list_t(i).rej_reason_desc                                    
	     ,p_ce_ajb998_list_t(i).other_fee1                                         
	     ,p_ce_ajb998_list_t(i).other_fee2                                         
	     ,p_ce_ajb998_list_t(i).fund_percent                                       
	     ,p_ce_ajb998_list_t(i).ref_num                                            
	     ,p_ce_ajb998_list_t(i).dis_amt                                            
	     ,p_ce_ajb998_list_t(i).dis_rate                                           
	     ,p_ce_ajb998_list_t(i).service_rate                                       
	     ,p_ce_ajb998_list_t(i).other_rate1                                        
	     ,p_ce_ajb998_list_t(i).other_rate2                                        
	     ,p_ce_ajb998_list_t(i).creation_date                                      
	     ,p_ce_ajb998_list_t(i).created_by                                         
	     ,p_ce_ajb998_list_t(i).last_update_date                                   
 	     ,p_ce_ajb998_list_t(i).last_updated_by                                    
	     ,p_ce_ajb998_list_t(i).attribute36                                        
	     ,p_ce_ajb998_list_t(i).attribute37                                        
	     ,p_ce_ajb998_list_t(i).attribute38                                        
 	     ,p_ce_ajb998_list_t(i).attribute39                                        
	     ,p_ce_ajb998_list_t(i).attribute40                                        
	     ,p_ce_ajb998_list_t(i).attribute41                                        
	     ,p_ce_ajb998_list_t(i).attribute42                                        
	     ,p_ce_ajb998_list_t(i).attribute43                                        
	     ,p_ce_ajb998_list_t(i).status                                             
	     ,'NEW'                                        
	     ,p_ce_ajb998_list_t(i).status_1295                                        
	     ,p_ce_ajb998_list_t(i).sequence_id_998                            
	     ,p_ce_ajb998_list_t(i).org_id                                             
	     ,p_ce_ajb998_list_t(i).ipay_batch_num                                     
 	     ,p_ce_ajb998_list_t(i).ajb_file_name                                      
            );
    EXCEPTION
      WHEN others THEN
	v_error_flag:='Y';
	v_mesg:=SUBSTR(SQLERRM,1,1000);
	IF LENGTH(v_error_message)<3000 THEN
  	   v_error_message:=v_error_message||v_mesg;
	END IF;
    END;
  END LOOP;
  COMMIT;
  IF v_error_flag='Y' THEN
     p_errbuff:='Error while inserting ce_AJB998'||v_error_message;
     p_retcode:='2';
  ELSE
     p_errbuff:=NULL;
     p_retcode:='0';
  END IF;
EXCEPTION
  WHEN others THEN
    p_errbuff:='EXception When others :'|| sqlerrm||v_error_message;
    p_retcode:='2';
END INSERT_AJB998;


PROCEDURE INSERT_AJB999 (
                          p_errbuff           		OUT VARCHAR2
                         ,p_retcode           		OUT VARCHAR2
			 ,p_ce_ajb999_list_t 		IN  XX_CE_AJB999_LIST_T
		        )
IS

v_error_flag VARCHAR2(1):='N';
v_error_message VARCHAR2(4000);
v_mesg		VARCHAR2(2000);

BEGIN

  FOR i IN 1..p_ce_ajb999_list_t.COUNT LOOP 

    BEGIN
      INSERT
        INTO XX_CE_AJB999
	   ( record_type                 
	    ,store_num                   
	    ,provider_type               
	    ,submission_date             
	    ,country_code                
	    ,currency_code               
	    ,processor_id                
	    ,bank_rec_id                 
	    ,cardtype                    
	    ,net_sales                   
	    ,net_reject_amt              
	    ,chargeback_amt              
	    ,discount_amt                
	    ,net_deposit_amt             
	    ,creation_date               
	    ,created_by                  
	    ,last_update_date            
	    ,last_updated_by             
	    ,attribute1                  
	    ,attribute2                  
	    ,attribute3                  
	    ,attribute4                  
	    ,attribute5                  
	    ,attribute6                  
	    ,attribute7                  
	    ,attribute8                  
	    ,attribute9                  
	    ,attribute10                 
	    ,attribute11                 
	    ,attribute12                 
	    ,attribute13                 
	    ,attribute14                 
	    ,attribute15                 
	    ,status                      
	    ,status_1310                  
	    ,status_1295                 
	    ,monthly_discount_amt        
 	    ,monthly_assessment_fee      
	    ,deposit_hold_amt            
	    ,deposit_release_amt         
	    ,service_fee                 
	    ,adj_fee                     
	    ,cost_funds_amt              
	    ,cost_funds_alpha_code       
	    ,cost_funds_num_code         
	    ,reserved_amt                
	    ,reserved_amt_alpha_code     
	    ,reserved_amt_num_code       
	    ,sequence_id_999             
	    ,org_id                      
	    ,ajb_file_name               
  	   )
      VALUES
	  ( p_ce_ajb999_list_t(i).record_type                 
	   ,p_ce_ajb999_list_t(i).store_num                   
	   ,p_ce_ajb999_list_t(i).provider_type               
	   ,p_ce_ajb999_list_t(i).submission_date             
	   ,p_ce_ajb999_list_t(i).country_code                
	   ,p_ce_ajb999_list_t(i).currency_code               
	   ,p_ce_ajb999_list_t(i).processor_id                
	   ,p_ce_ajb999_list_t(i).bank_rec_id                 
	   ,p_ce_ajb999_list_t(i).cardtype                    
	   ,p_ce_ajb999_list_t(i).net_sales                   
	   ,p_ce_ajb999_list_t(i).net_reject_amt              
	   ,p_ce_ajb999_list_t(i).chargeback_amt              
	   ,p_ce_ajb999_list_t(i).discount_amt                
	   ,p_ce_ajb999_list_t(i).net_deposit_amt             
	   ,p_ce_ajb999_list_t(i).creation_date               
	   ,p_ce_ajb999_list_t(i).created_by                  
	   ,p_ce_ajb999_list_t(i).last_update_date            
	   ,p_ce_ajb999_list_t(i).last_updated_by             
	   ,p_ce_ajb999_list_t(i).attribute1                  
	   ,p_ce_ajb999_list_t(i).attribute2                  
	   ,p_ce_ajb999_list_t(i).attribute3                  
	   ,p_ce_ajb999_list_t(i).attribute4                  
	   ,p_ce_ajb999_list_t(i).attribute5                  
	   ,p_ce_ajb999_list_t(i).attribute6                  
	   ,p_ce_ajb999_list_t(i).attribute7                  
	   ,p_ce_ajb999_list_t(i).attribute8                  
	   ,p_ce_ajb999_list_t(i).attribute9                  
	   ,p_ce_ajb999_list_t(i).attribute10                 
	   ,p_ce_ajb999_list_t(i).attribute11                 
	   ,p_ce_ajb999_list_t(i).attribute12                 
	   ,p_ce_ajb999_list_t(i).attribute13                 
	   ,p_ce_ajb999_list_t(i).attribute14                 
	   ,p_ce_ajb999_list_t(i).attribute15                 
	   ,p_ce_ajb999_list_t(i).status                      
	   ,'NEW'
	   ,p_ce_ajb999_list_t(i).status_1295                 
	   ,p_ce_ajb999_list_t(i).monthly_discount_amt        
 	   ,p_ce_ajb999_list_t(i).monthly_assessment_fee      
	   ,p_ce_ajb999_list_t(i).deposit_hold_amt            
	   ,p_ce_ajb999_list_t(i).deposit_release_amt         
	   ,p_ce_ajb999_list_t(i).service_fee                 
	   ,p_ce_ajb999_list_t(i).adj_fee                     
	   ,p_ce_ajb999_list_t(i).cost_funds_amt              
	   ,p_ce_ajb999_list_t(i).cost_funds_alpha_code       
	   ,p_ce_ajb999_list_t(i).cost_funds_num_code         
	   ,p_ce_ajb999_list_t(i).reserved_amt                
	   ,p_ce_ajb999_list_t(i).reserved_amt_alpha_code     
	   ,p_ce_ajb999_list_t(i).reserved_amt_num_code       
	   ,p_ce_ajb999_list_t(i).sequence_id_999             
	   ,p_ce_ajb999_list_t(i).org_id                      
	   ,p_ce_ajb999_list_t(i).ajb_file_name               
	  );
    EXCEPTION
      WHEN others THEN
	v_error_flag:='Y';
	v_mesg:=SUBSTR(SQLERRM,1,1000);
	IF LENGTH(v_error_message)<3000 THEN
  	   v_error_message:=v_error_message||v_mesg;
	END IF;
    END;
  END LOOP;
  COMMIT;
  IF v_error_flag='Y' THEN
     p_errbuff:='Error while inserting ce_AJB999'||v_error_message;
     p_retcode:='2';
  ELSE
     p_errbuff:=NULL;
     p_retcode:='0';
  END IF;
EXCEPTION
  WHEN others THEN
    p_errbuff:='EXception When others :'|| sqlerrm||v_error_message;
    p_retcode:='2';
END INSERT_AJB999;


PROCEDURE INSERT_MAIL_CHECK_HOLDS (
                                   p_errbuff           		OUT VARCHAR2
                                  ,p_retcode           		OUT VARCHAR2
				  ,p_mail_check_holds_T IN  XX_AR_MAIL_CHECK_HOLDS_LIST_T
				 )
IS

v_error_flag	VARCHAR2(1):='N';
v_error_message VARCHAR2(4000);
v_mesg		VARCHAR2(2000);

BEGIN

  FOR i IN 1..p_mail_check_holds_T.COUNT LOOP 
      
    BEGIN
      INSERT 
        INTO XX_AR_MAIL_CHECK_HOLDS
	   ( ref_mailcheck_id                                   
	    ,pos_transaction_number                             
	    ,aops_order_number                                  
            ,check_amount                                       
            ,customer_id                                        
            ,store_customer_name                                
            ,address_line_1                                     
            ,address_line_2                                     
            ,address_line_3                                     
            ,address_line_4                                     
            ,city                                               
            ,state_province                                     
            ,postal_code                                        
            ,country                                            
            ,phone_number                                       
            ,phone_extension                                    
            ,hold_status                                        
            ,delete_status                                      
            ,creation_date                                  
            ,created_by                                         
            ,last_update_date                          
            ,last_update_by                               
            ,last_update_login                        
            ,program_application_id            
            ,program_id                                        
            ,program_update_date                
            ,request_id                                         
            ,process_code                                       
            ,ap_vendor_id                                       
            ,ap_invoice_id                                      
            ,ar_cash_receipt_id                        
            ,ar_customer_trx_id                                 
	   )
    VALUES
	   ( p_mail_check_holds_T(i).ref_mailcheck_id                                   
	    ,p_mail_check_holds_T(i).pos_transaction_number                             
	    ,p_mail_check_holds_T(i).aops_order_number                                  
            ,p_mail_check_holds_T(i).check_amount                                       
            ,p_mail_check_holds_T(i).customer_id                                        
            ,p_mail_check_holds_T(i).store_customer_name                                
            ,p_mail_check_holds_T(i).address_line_1                                     
            ,p_mail_check_holds_T(i).address_line_2                                     
            ,p_mail_check_holds_T(i).address_line_3                                     
            ,p_mail_check_holds_T(i).address_line_4                                     
            ,p_mail_check_holds_T(i).city                                               
            ,p_mail_check_holds_T(i).state_province                                     
            ,p_mail_check_holds_T(i).postal_code                                        
            ,p_mail_check_holds_T(i).country                                            
            ,p_mail_check_holds_T(i).phone_number                                       
            ,p_mail_check_holds_T(i).phone_extension                                    
            ,p_mail_check_holds_T(i).hold_status                                        
            ,p_mail_check_holds_T(i).delete_status                                      
            ,p_mail_check_holds_T(i).creation_date
            ,p_mail_check_holds_T(i).created_by                                         
            ,p_mail_check_holds_T(i).last_update_date                          
            ,p_mail_check_holds_T(i).last_update_by                               
            ,p_mail_check_holds_T(i).last_update_login                        
            ,p_mail_check_holds_T(i).program_application_id            
            ,p_mail_check_holds_T(i).program_id                                        
            ,p_mail_check_holds_T(i).program_update_date                
            ,p_mail_check_holds_T(i).request_id                                         
            ,p_mail_check_holds_T(i).process_code                                       
            ,p_mail_check_holds_T(i).ap_vendor_id                                       
            ,p_mail_check_holds_T(i).ap_invoice_id                                      
            ,p_mail_check_holds_T(i).ar_cash_receipt_id                        
            ,p_mail_check_holds_T(i).ar_customer_trx_id                                 
	   );
    EXCEPTION
      WHEN others THEN
	v_error_flag:='Y';
	v_mesg:=SUBSTR(SQLERRM,1,1000);
	IF LENGTH(v_error_message)<3000 THEN
  	   v_error_message:=v_error_message||v_mesg;
	END IF;
    END;
  END LOOP; 
  IF v_error_flag='Y' THEN
     ROLLBACK;
     p_errbuff:='Error while inserting records for Mail check holds'||v_error_message;
     p_retcode:=2;
  ELSE
     COMMIT;
     p_errbuff:=NULL;
     p_retcode:=0;
  END IF;
EXCEPTION
  WHEN others THEN
    p_errbuff:='EXception When others :'|| sqlerrm||v_error_message;
    p_retcode:=sqlcode;
END INSERT_MAIL_CHECK_HOLDS;

END  XX_CE_AJB_INSERT_STG_PKG;
/
