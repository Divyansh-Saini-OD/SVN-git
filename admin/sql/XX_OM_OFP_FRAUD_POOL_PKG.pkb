SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_OM_OFP_FRAUD_POOL_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       OD Staff                                    |
-- +===================================================================+
-- | Name  :  xx_om_ofp_fraud_pool_pkg                                 |
-- | Description:  Following actions done through this package         |
-- |                    1. Release hold on the order                   |
-- |                    2. Cancel the hold on an order                 |
-- |                    3. Update hold information on an order         |
-- |               The action required will depend on the ACTION passed|
-- |               by the front end pools program.                     |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 29-Sep-2007  Dedra Maloy      Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

   --variable holding the error details
   ------------------------------------
   lc_exception_hdr             xx_om_global_exceptions.exception_header%TYPE;
   lc_error_code                xx_om_global_exceptions.error_code%TYPE;
   lc_error_desc                xx_om_global_exceptions.description%TYPE;
   lc_entity_ref                xx_om_global_exceptions.entity_ref%TYPE;
   lc_entity_ref_id             xx_om_global_exceptions.entity_ref_id%TYPE;
   ln_exception_occured         NUMBER;
   lc_return_status             VARCHAR2(1)   := NULL;

   PROCEDURE fraud_log_exceptions
                     ( p_error_code        IN  VARCHAR2    
                      ,p_error_description IN  VARCHAR2    
                      ,p_entity_ref        IN  VARCHAR2    
                      ,p_entity_ref_id     IN  PLS_INTEGER 
                     )
   -- +===================================================================+
   -- | Name  : fraud_log_exceptions                                      |
   -- | Description: This procedure will be responsible to store all      |
   -- |              the exceptions occured during the procees using      |
   -- |              global custom exception handling framework           |
   -- |                                                                   |
   -- | Parameters:  IN:                                                  |
   -- |     P_Error_Code        --Custom error code                       |
   -- |     P_Error_Description --Custom Error Description                |
   -- |     p_exception_header  --Errors occured under the exception      |
   -- |                           'NO_DATA_FOUND / OTHERS'                |
   -- |     p_entity_ref        --'Hold id'                               |
   -- |     p_entity_ref_id     --'Value of the Hold Id'                  |
   -- |                                                                   |
   -- +===================================================================+
   IS

      --Variables holding the values from the global exception framework package
      --------------------------------------------------------------------------
      x_errbuf                    VARCHAR2(1000);
      x_retcode                   VARCHAR2(40);  
      
      BEGIN
          lrec_exception_obj_type.p_exception_header  := 'OTHERS';
          lrec_exception_obj_type.p_track_code        := 'OTC';
          lrec_exception_obj_type.p_solution_domain   := 'Order Management';
          lrec_exception_obj_type.p_function          := 'DataCollectionandRetrievalForPools';

          lrec_exception_obj_type.p_error_code        := p_error_code;
          lrec_exception_obj_type.p_error_description := p_error_description;
          lrec_exception_obj_type.p_entity_ref        := p_entity_ref;
          lrec_exception_obj_type.p_entity_ref_id     := p_entity_ref_id;

          Xx_Om_Global_Exception_Pkg.insert_exception
                                     (  lrec_exception_obj_type
                                       ,x_errbuf
                                       ,x_retcode
                                     );
   END fraud_log_exceptions; --Proceudre

   -- +===================================================================+
   -- | Name  : Fraud_Pool                                                |
   -- | Description: This procedure is called by the front end pool       |
   -- |              processing programs for fraud.  The actions          |
   -- |              'Approve', 'Cancel', and 'Hold' will update the      |
   -- |              order and XX_OM_POOL_RECORDS_ALL appropriately       |
   -- | Parameters:  IN:                                                  |
   -- |     p_pool_id           --pool id sent from front end 'OFP'       |
   -- |     p_order_header_id   --order from the front end needing action |
   -- |     p_hold_id           --type of hold sent by the front end      |
   -- |     p_action            --'Approve','Cancel','Hold'               |
   -- |     p_CSR               --Identifies the CSR performing the action|
   -- | Parameters OUT                                                    |
   -- |     x_retcode           --return the status to the front end      |
   -- |                           'S' is success                          |
   -- |                           'E' is error                            |
   -- |                           'U' is unexpected error                 |
   -- |     x_err_buff          --return error information                |
   -- +===================================================================+
   PROCEDURE Fraud_Pool   ( p_pool_id            IN VARCHAR2
                           ,p_order_header_id    IN NUMBER
                           ,p_release_comments   IN VARCHAR2
                           ,p_hold_id            IN NUMBER
                           ,p_action             IN VARCHAR2
                           ,p_csr_id             IN NUMBER
                           ,p_context            IN VARCHAR2
                           ,x_ret_code           OUT NOCOPY VARCHAR2
                           ,x_err_buff           OUT NOCOPY VARCHAR2
                          )
    IS
      --Variables to hold API status
      lc_msg_data                  VARCHAR2(2000) := NULL;
      lc_retcode                   VARCHAR2(40)   := 'S';
      ln_msg_count                 PLS_INTEGER    := 0;
      
      lc_hold_entity_code          VARCHAR2(30)     := 'O';
      ln_hold_entity_id            NUMBER           := p_order_header_id;
      lc_org_id                    VARCHAR2 (240);
      lc_entity_name               VARCHAR2 (30)    := 'Order';
      ln_order_line_id             Oe_Order_Lines_All.Line_Id%TYPE;
      
      BEGIN
         --Accepts the input values from the Fraud Prevention Pools program.
         --Query to find out the hold_entity_code, entity_name, entity_ID and
         --org_id,needed these column value to pass the values to the API’s
         BEGIN 
               SELECT 
                      OHSA.hold_entity_code
                     ,OHSA.hold_entity_id
                     ,OOH.org_id
               INTO
                      lc_hold_entity_code
                     ,ln_hold_entity_id
                     ,lc_org_id
               FROM
                      oe_order_headers_all OOH 
           	    -- ,oe_order_lines_all OOL 
	             ,oe_order_holds_all OOHA 
	             ,oe_hold_sources_all OHSA 
	             ,oe_hold_definitions OHD 
               WHERE 
                 --     OOH.header_id = OOL.header_id 
                  OOH.header_id = OOHA.header_id 
                  AND OOHA.hold_source_id=OHSA.hold_source_id 
                  AND OHSA.hold_id=OHD.hold_id 
                  AND OHD.name in 
                     ('OD FRAUD PENDING  CREDIT REVIEW','OD FRAUD AFTER  CREDIT REVIEW')
                  AND OOH.header_id = p_order_header_id;
                    -- (In case of entity_type = 'Order');
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 ln_exception_occured := 1;
	         Fnd_Message.SET_NAME('XXOM','XX_OM_POOL_NO_HLDSRC');
	         lc_error_code     := 'XX_OM_600001_POOL_NO_HLDSRC-01';
	         lc_error_desc        := Fnd_Message.GET;
	         lc_entity_ref        := 'Hold Id';
                 lc_entity_ref_id     := p_hold_id;
                 lc_retcode           := 'E';
            WHEN OTHERS THEN
                 ln_exception_occured := 1;
	         Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
	         Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
	         Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	         lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-01';
	         lc_error_desc        := Fnd_Message.GET;
	         lc_entity_ref        := 'Hold Id';                                                                                                                     
                 lc_entity_ref_id     := p_hold_id;                     
                 lc_retcode           := 'U';
         END;
         IF lc_retcode = 'S' THEN
         IF p_action = 'APPROVE' THEN
         --release the hold from the order
            BEGIN
               XX_OM_POOL_ACTIONS_PKG.RELEASE_HOLDS
                                ( 
                                   p_hold_id          => p_hold_id
	                          ,p_order_header_id  => p_order_header_id
                                  ,p_order_line_id    => ln_order_line_id                                              
	                          ,p_release_comments => p_release_comments 
	                          ,p_hold_entity_code => lc_hold_entity_code
                                  ,x_return_status    => lc_return_status   
                                  ,x_msg_count        => ln_msg_count    
                                  ,x_msg_data         => lc_msg_data                                                    
                                 );
               IF  TRIM(UPPER(lc_return_status)) <> 
                   TRIM(UPPER(Fnd_Api.G_RET_STS_SUCCESS)) THEN
                   lc_return_status      := 'E';
               ELSE
                  --if hold release is successful, then delete the record from 
                  --table XX_OM_POOL_RECORDS_ALL                  
                  lc_return_status      := 'S';
                  BEGIN
                     XX_OM_POOL_ACTIONS_PKG.DELETE_RECORD
                                (  p_entity_name  => lc_entity_name
	                          ,p_entity_id    => to_char(ln_hold_entity_id) 
	                          ,p_pool_id      => p_pool_id--(Pass the Input Parameter)
                                  ,p_org_id       => lc_org_id 
 		                  ,x_status       => lc_return_status
		                  ,x_message      => lc_msg_data
                                );
                        --if delete from XX_OM_POOL_RECORDS_ALL is successful-commit
                        --then update the ACCEPTED_COUNT
                     IF TRIM(UPPER(lc_return_status)) <> 
                        TRIM(UPPER(Fnd_Api.G_RET_STS_SUCCESS)) THEN
                        lc_return_status  := 'E';
                     ELSE   
                        lc_return_status  := 'S';
                        BEGIN
                        --+==================================================+   
                        --THIS PROCEDURE HAS NOT BEEN DEVELOPED YET                    
                        --update the accepted count column of fraud data XX_OM_
                        --FRAUD_RULE table from RICEID I1286
	                   --XX_OM_FRAUD_CHECK_PKG.UPDATE_ACCEPTED_COUNT
                           --                    ( 
                           --                       p_order_header_id   --(Pass the Input Parameter)
	                   --                      ,p_pool_id           --(Pass the Input Parameter)
                           --                    )
                           --IF TRIM(UPPER(lc_return_status)) <> 
                           --   TRIM(UPPER(Fnd_Api.G_RET_STS_SUCCESS)) THEN
                           --   lc_return_status  := 'E';
                           --ELSE   
                           --   lc_return_status  := 'S';
                                COMMIT;
                           --END IF;
                        --EXCEPTION
                           --WHEN OTHERS THEN
	                      --Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
	                      --Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
	                      --Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	                      --lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	                      --lc_error_desc        := Fnd_Message.GET;
	                      --lc_entity_ref        := 'Hold Id';                                                                                                                     
                              --lc_entity_ref_id     := p_hold_id;                     
                              --lc_return_status     := 'U';                
                              --dbms_output.put_line('Others inside update count proc after call to api');
                          END;
                     END IF;   
                     EXCEPTION
                     WHEN OTHERS THEN
                        Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
	                Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
	                Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	                lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	                lc_error_desc        := Fnd_Message.GET;
	                lc_entity_ref        := 'Hold Id';                                                                                                                     
                        lc_entity_ref_id     := p_hold_id;                     
                        lc_retcode           := 'U';                
                        dbms_output.put_line('Others inside delete after call to api');                         
                     END;
                  END IF;                
               EXCEPTION
               WHEN OTHERS THEN
                  Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
	          Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
	          Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	          lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	          lc_error_desc        := Fnd_Message.GET;
	          lc_entity_ref        := 'Hold Id';                                                                                                                     
                  lc_entity_ref_id     := p_hold_id;                     
                  lc_retcode           := 'U';                
                  dbms_output.put_line('Others inside approve proc after call to api');                                           
               END;
            ELSIF p_action = 'CANCEL' THEN
               BEGIN
               -- +===================================================================+        
               --THIS PROCEUDRE HAS NOT BEEN DEVELOPED YET
               --First call the API to cancel the order 
               --(: I1198_OrderUpdateCancelProcess)
               --CHECK FOR ERROR          
               --if the cancel is successful, then delete the corresponding
               --record from the pool table XX_OM_POOL_RECORD.
               -- +===================================================================+        
                  --IF TRIM(UPPER(lc_return_status)) <> 
                     --TRIM(UPPER(Fnd_Api.G_RET_STS_SUCCESS)) THEN
                     -- lc_return_status  := 'E';
                  --ELSE   
                     -- lc_return_status  := 'S';               
                       BEGIN
                          XX_OM_POOL_ACTIONS_PKG.DELETE_RECORD
                                        ( 
	                                   p_entity_name => lc_entity_name
	                                  ,p_entity_id    => to_char(ln_hold_entity_id) 
	                                  ,p_pool_id     => p_pool_id
                                          ,p_org_id      => lc_org_id          
 	                                  ,x_status      => lc_return_status
		                          ,x_message     => lc_msg_data
                                        );
                          IF TRIM(UPPER(lc_return_status)) <> 
                             TRIM(UPPER(Fnd_Api.G_RET_STS_SUCCESS)) THEN
                             lc_return_status  := 'E';
                          ELSE
                             --if delete from XX_OM_POOL_RECORDS_ALL is successful-commit                          
                             lc_return_status  := 'S';
                             COMMIT;
                          END IF;
                       EXCEPTION
                       WHEN OTHERS THEN
                          Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
	                  Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
	                  Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	                  lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	                  lc_error_desc        := Fnd_Message.GET;
	                  lc_entity_ref        := 'Hold Id';                                                                                                                     
                          lc_entity_ref_id     := p_hold_id;                     
                          lc_retcode           := 'U';                
                          dbms_output.put_line('Others inside delete proc after call to api');                  
                       END;
                    --END IF;
                 EXCEPTION
                 WHEN OTHERS THEN
                    Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
                    Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
                    Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	            lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	            lc_error_desc        := Fnd_Message.GET;
	            lc_entity_ref        := 'Hold Id';                                                                                                                     
                    lc_entity_ref_id     := p_hold_id;                     
                    lc_retcode           := 'U';                
                    dbms_output.put_line('Others inside cancel proc after call to api');                  
               END;
            --to apply hold on the orders and look at the pool table
            --XX_OM_POOL_RECORDS_ALL for the corresponding record and will   
            --update the CSR’s username in REVIEWER Column of the table.
            ELSIF p_action = 'HOLD' THEN
               BEGIN
	          XX_OM_POOL_ACTIONS_PKG.HOLD_CSR
                                (     
                                   p_entity_name   => lc_entity_name 
	                          ,p_entity_id     => ln_hold_entity_id
                                  ,p_pool_id       => p_pool_id                   
	                          ,p_org_id        => lc_org_id
                                  ,p_csr_id        => p_csr_id         
                                  ,x_status        => lc_return_status            
                                  ,x_message       => lc_msg_data
                                );
                  --if the hold update is successful, commit but do not delete
                  --the corresponding record from the pool table XX_OM_POOL_RECORDS.                                   
                  IF  TRIM(UPPER(lc_return_status)) <> 
                      TRIM(UPPER(Fnd_Api.G_RET_STS_SUCCESS)) THEN
                      lc_return_status  := 'E';
                  ELSE   
                      lc_return_status  := 'S';
                      COMMIT;
                  END IF;                 
               EXCEPTION
               WHEN OTHERS THEN
                  Fnd_Message.SET_NAME('XXOM','XX_OM_UNEXPECTED_ERR');
                  Fnd_Message.SET_TOKEN('ERROR_CODE', SQLCODE);
                  Fnd_Message.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
 	          lc_error_code        := 'XX_OM_600002_UNEXPECTED_ERR-02';
	          lc_error_desc        := Fnd_Message.GET;
	          lc_entity_ref        := 'Hold Id';                                                                                                                     
                  lc_entity_ref_id     := p_hold_id;                     
                  lc_retcode           := 'U';                
                  dbms_output.put_line('Others inside hold proc after call to api');
               END;  
            END IF;  --Action
            END IF;  --return code from select
            --In case of errors while performing any of the above process
            --the exception handling custom API will be invoked 
            --(XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION) by passing the
            --required parameters             
            IF lc_return_status <> 'S' THEN
               lc_entity_ref := 'Entity Id';
               fraud_log_exceptions( lc_error_code       
                                    ,lc_error_desc      
                                    ,lc_entity_ref       
                                    ,lc_entity_ref_id    
                                   );
            END IF;
            
      END Fraud_Pool; --Proceudre
      
END XX_OM_OFP_FRAUD_POOL_PKG; --Package
/
EXIT


