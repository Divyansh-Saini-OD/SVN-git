CREATE OR REPLACE PACKAGE BODY ZX_PTNR_SRVC_INTGRTN_PKG AS
/* Global Data Types */
G_PKG_NAME              CONSTANT VARCHAR2(80) := 'ZX_PTNR_SRVC_INTGRTN_PKG';
G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED      CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR           CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION       CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT           CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE       CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT       CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
G_MODULE_NAME           CONSTANT VARCHAR2(80) := 'ZX.PLSQL.ZX_PTNR_SRVC_INTGRTN_PKG.';
PROCEDURE INVOKE_THIRD_PARTY_INTERFACE(p_api_owner_id IN Number
, p_service_type_id IN Number
, p_context_ccid IN Number
, p_data_transfer_mode IN VARCHAR2
, x_return_status OUT NOCOPY VARCHAR2) IS 
InvalidApiownId Exception; 
l_api_name  CONSTANT VARCHAR2(80) := 'INVOKE_THIRD_PARTY_INTERFACE';

  --Taxware Custom Code
  L_TAX_CALC  VARCHAR2(1);
  L_TRANS_ID  NUMBER;
  L_GT_REC_COUNT number;

 Begin
 
    IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
    FND_LOG.STRING(G_LEVEL_PROCEDURE
    ,G_MODULE_NAME || l_api_name ||'.BEGIN'
    ,G_PKG_NAME||': '||l_api_name||'()+');
    END IF;
    
  -- Begin --- Taxware code to query TransactionID and Calculated Tax and allow Tax Partner to be called.

     FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.BEGIN','TWE_P2P_OD: CALL_TAX_PARTNER_CUSTOMIZATION');
	 
	 select count(1) into L_GT_REC_COUNT from XXTWE_TAX_PARTNER_GT;
	 if L_GT_REC_COUNT>0 then
        
        BEGIN
        
            SELECT CALL_TAX_PARTNER, TRX_ID
            INTO L_TAX_CALC, L_TRANS_ID
            FROM XXTWE_TAX_PARTNER_GT--Modified to use GT Table for Defect ID #43203 
            WHERE REC_TYPE = 'TWE_PARTNER_BYPASS';
            
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.','TWE_P2P_OD: L_TAX_CALC:'||L_TAX_CALC);
            FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.','TWE_P2P_OD: L_TRANS_ID:'||L_TRANS_ID);
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            
             FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.','TWE_P2P_OD: L_TRANS_ID EXCEPTION:'|| SQLERRM);
        
            
        END;
    
    FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.END','TWE_P2P_OD: CALL_TAX_PARTNER_CUSTOMIZATION');
    --  End -- Taxware Custom Code
	else 
	L_TAX_CALC:='Y';
	 FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.END','TWE_P2P_OD: CALL_TAX_PARTNER_CUSTOMIZATION.');
	end if;
    
   IF L_TAX_CALC = 'Y' THEN --Taxware Custom Code
   
      
  --Taxware Custom Code
     FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.','TWE_P2P_OD: CALL TAX PARTNER');
  
  -- Original Code  
    IF p_api_owner_id = 2 THEN 
        ZX_Third_party_2_pkg.main_router(p_service_type_id
        , p_context_ccid
        , p_data_transfer_mode
        , x_return_status );
        
        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         Return; 
         END IF;
          
    ELSE 
    Raise InvalidApiownid ; 
    END IF;

    --Taxware Custom Code
  ELSE
  
     FND_LOG.STRING(G_LEVEL_PROCEDURE,G_MODULE_NAME ||'.'|| l_api_name ||'.','TWE_P2P_OD: DO NOT CALL TAX PARTNER');

   
  END IF; 
  --Taxware Custom Code
  
   
 END invoke_third_party_interface;
 
END ZX_PTNR_SRVC_INTGRTN_PKG ;

/