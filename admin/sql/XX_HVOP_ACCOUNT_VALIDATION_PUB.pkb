create or replace
PACKAGE BODY XX_HVOP_ACCOUNT_VALIDATION_PUB
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- +====================================================================================================+
-- | Name        : XX_HVOP_ACCOUNT_VALIDATION_PUB                                                       |
-- | Description : Package body for inserting status into custom table to identify if account and       |
-- |               account site exist or not                                                            |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       11-Jun-2008 Yusuf Ali	     Initial draft version.      			 	|
-- |2.0       06-Oct-2008 Yusuf Ali          Added functionality for performing lookup and insert into  |                                                                                                    |
-- |                                         audit table.                                               |
-- +====================================================================================================+
*/


  g_pkg_name                     CONSTANT VARCHAR2(30) := 'XX_HVOP_ACCOUNT_VALIDATION_PUB';
  g_module                       CONSTANT VARCHAR2(30) := 'CRM';
  g_request_id                   fnd_concurrent_requests.request_id%TYPE := fnd_global.conc_request_id();

   


PROCEDURE check_entity        ( P_CHECK_ENTITY             IN 		    HVOP_CHECK_ACCT_OBJ_TBL
			      , X_MESSAGES	           OUT NOCOPY       HVOP_ACCT_RESULT_OBJ_TBL
                              , X_MSG_DATA                 OUT NOCOPY       VARCHAR2
                              , X_RETURN_STATUS            OUT NOCOPY       VARCHAR2
                              )

AS

      le_api_error           EXCEPTION;

      ln_owner_table_id      hz_orig_sys_references.owner_table_id%TYPE;
      
      lc_osr                 VARCHAR2(30);
      lc_store_osr           VARCHAR2(30);
      
      lc_store_osr_table     VARCHAR2(30);
      lc_table_name          VARCHAR2(30);
      
      lc_return_status       VARCHAR2(1);
      ln_msg_count           NUMBER;
      lc_msg_data            VARCHAR2(2000);
      l_counter              NUMBER := 1;    
      
      L_HVOP_CHECK_ACCT_OBJ_TBL       HVOP_CHECK_ACCT_OBJ_TBL := HVOP_CHECK_ACCT_OBJ_TBL(); 
      L_store_osr_results_obj_TBL     store_osr_results_obj_TBL := store_osr_results_obj_TBL();
      L_OSR_RECORD                    xx_validate_crm_osr.T_OSR_TABLE;
      L_hvop_acct_result_obj_TBL      hvop_acct_result_obj_TBL := hvop_acct_result_obj_TBL();
      
 
BEGIN

      FOR i in 1..P_CHECK_ENTITY.COUNT
      LOOP
      
          lc_osr        := P_CHECK_ENTITY(i).OSR;          
          lc_table_name := P_CHECK_ENTITY(i).TABLE_NAME;
          
          L_OSR_RECORD(1).OSR        := lc_osr;
          L_OSR_RECORD(1).TABLE_NAME := lc_table_name;
    
          XX_VALIDATE_CRM_OSR.get_entity_id(p_orig_system => 'A0'
                                           , p_osr_record => L_OSR_RECORD
                                           , x_owner_table_id => ln_owner_table_id
                                           , x_no_osr => lc_store_osr
                                           , x_no_osr_table => lc_store_osr_table
                                           , x_return_status => lc_return_status
                                           , x_msg_count => ln_msg_count
                                           , x_msg_data => lc_msg_data);	
           
          IF lc_return_status != 'S'    
          THEN
             lc_return_status := 'R';  --Need to send for re-extract
          ELSE
             lc_return_status := 'P';  --Already processed, do not send for re-extract
          END IF;
          
          L_store_osr_results_obj_TBL.EXTEND;   
          L_store_osr_results_obj_TBL(i) := store_osr_results_obj (
                                                    lc_osr
                                                  , lc_table_name
                                                  , lc_return_status
                                                  , 'BO_API'
                                                  , SYSDATE); 
          
          
          IF lc_return_status NOT LIKE 'P' THEN
                L_hvop_acct_result_obj_TBL.EXTEND;
                L_hvop_acct_result_obj_TBL(l_counter) := hvop_acct_result_obj(lc_store_osr
                                                                     ,lc_store_osr_table);
                                                                     
                l_counter := l_counter + 1;
          END IF;
            		
      END LOOP;	
      
      
      FORALL i IN 1..L_store_osr_results_obj_TBL.COUNT
               INSERT INTO XXCOMN.XX_HVOP_ACCOUNT_VALIDATION
 	                        ( ORIG_SYSTEM_REFERENCE
				, OWNER_TABLE_NAME
				, STATUS          
				, CREATED_BY      
				, CREATION_DATE
                           )
                    VALUES (      TREAT(L_store_osr_results_obj_TBL(i) AS store_osr_results_obj).OSR
                                , TREAT(L_store_osr_results_obj_TBL(i) AS store_osr_results_obj).OSR_TABLE 
				, TREAT(L_store_osr_results_obj_TBL(i) AS store_osr_results_obj).RETURN_STATUS          
				, 'BO_API'      
				, SYSDATE   
				);
                     
      X_MESSAGES      := L_hvop_acct_result_obj_TBL;
      X_RETURN_STATUS := 'S';

 EXCEPTION
     WHEN le_api_error THEN
         x_return_status := FND_API.G_RET_STS_ERROR;
	 fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.insert_validated_data');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_data := fnd_message.get();
         
     WHEN OTHERS THEN
         x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.insert_validated_data');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         x_msg_data := fnd_message.get();
         
END check_entity;


END XX_HVOP_ACCOUNT_VALIDATION_PUB;


/

SHOW ERRORS;