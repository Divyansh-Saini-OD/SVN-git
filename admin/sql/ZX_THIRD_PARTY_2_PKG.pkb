create or replace PACKAGE BODY ZX_THIRD_PARTY_2_PKG AS
/* Global Data Types */
G_PKG_NAME              CONSTANT VARCHAR2(80) := 'ZX_THIRD_PARTY_2_PKG';
G_CURRENT_RUNTIME_LEVEL CONSTANT NUMBER       := FND_LOG.G_CURRENT_RUNTIME_LEVEL;
G_LEVEL_UNEXPECTED      CONSTANT NUMBER       := FND_LOG.LEVEL_UNEXPECTED;
G_LEVEL_ERROR           CONSTANT NUMBER       := FND_LOG.LEVEL_ERROR;
G_LEVEL_EXCEPTION       CONSTANT NUMBER       := FND_LOG.LEVEL_EXCEPTION;
G_LEVEL_EVENT           CONSTANT NUMBER       := FND_LOG.LEVEL_EVENT;
G_LEVEL_PROCEDURE       CONSTANT NUMBER       := FND_LOG.LEVEL_PROCEDURE;
G_LEVEL_STATEMENT       CONSTANT NUMBER       := FND_LOG.LEVEL_STATEMENT;
G_MODULE_NAME           CONSTANT VARCHAR2(80) := 'ZX.PLSQL.ZX_THIRD_PARTY_2_PKG.';
PROCEDURE CALCULATE_TAX( p_context_ccid IN NUMBER
, TAX_CURRENCY_TBL IN OUT NOCOPY ZX_TAX_PARTNER_PKG.tax_currencies_tbl_type
, TAX_LINES_RESULT_TBL OUT NOCOPY ZX_TAX_PARTNER_PKG.tax_lines_tbl_type
, ERROR_STATUS OUT NOCOPY VARCHAR2
, ERROR_DEBUG_MSG_TBL OUT NOCOPY ZX_TAX_PARTNER_PKG.messages_tbl_type
) IS
InvalidContextCcid Exception;
l_api_name  CONSTANT VARCHAR2(80) := 'CALCULATE_TAX';
 Begin 
IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
FND_LOG.STRING(G_LEVEL_PROCEDURE
,G_MODULE_NAME || l_api_name ||'.BEGIN'
,G_PKG_NAME||': '||l_api_name||'()+');
END IF;
/* -- NAIT-185309 commented to reterofit invalid objects
IF p_context_ccid = 17022 THEN 
Twe_taxsrvc_o2c_intl_pkg.Calculate_tax_api(TAX_CURRENCY_TBL
, TAX_LINES_RESULT_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17024 THEN 
Twe_taxsrvc_o2c_intl_pkg.Calculate_tax_api(TAX_CURRENCY_TBL
, TAX_LINES_RESULT_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17026 THEN 
Twe_taxsrvc_p2p_intl_pkg.Calculate_tax_api(TAX_CURRENCY_TBL
, TAX_LINES_RESULT_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17027 THEN 
Twe_taxsrvc_p2p_intl_pkg.Calculate_tax_api(TAX_CURRENCY_TBL
, TAX_LINES_RESULT_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSE  
Raise InvalidContextCcid; 
END IF;
*/ 
EXCEPTION 
WHEN InvalidContextccid THEN 
ERROR_STATUS := FND_API.G_RET_STS_ERROR;
FND_MESSAGE.SET_NAME('ZX','ZX_INVALID_CONTEXT_CCID');
FND_MSG_PUB.ADD;
Return; 
END CALCULATE_TAX;
PROCEDURE SYNCHRONIZE_FOR_TAX( p_context_ccid IN NUMBER
, RESULT_SYNC_TBL OUT NOCOPY ZX_TAX_PARTNER_PKG.output_sync_tax_lines_tbl_type
, ERROR_STATUS OUT NOCOPY VARCHAR2
, ERROR_DEBUG_MSG_TBL OUT NOCOPY ZX_TAX_PARTNER_PKG.messages_tbl_type
) IS
InvalidContextCcid Exception;
l_api_name  CONSTANT VARCHAR2(80) := 'SYNCHRONIZE_FOR_TAX';
 Begin 
IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
FND_LOG.STRING(G_LEVEL_PROCEDURE
,G_MODULE_NAME || l_api_name ||'.BEGIN'
,G_PKG_NAME||': '||l_api_name||'()+');
END IF;
/*-- NAIT-185309 commented to reterofit invalid objects
IF p_context_ccid = 17022 THEN 
Twe_taxsrvc_o2c_intl_pkg.Synchronize_taxware_repository(RESULT_SYNC_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17024 THEN 
Twe_taxsrvc_o2c_intl_pkg.Synchronize_taxware_repository(RESULT_SYNC_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17026 THEN 
Twe_taxsrvc_p2p_intl_pkg.Synchronize_taxware_repository(RESULT_SYNC_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17027 THEN 
Twe_taxsrvc_p2p_intl_pkg.Synchronize_taxware_repository(RESULT_SYNC_TBL
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
)
ELSE  
Raise InvalidContextCcid; 
END IF; */
EXCEPTION 
WHEN InvalidContextccid THEN 
ERROR_STATUS := FND_API.G_RET_STS_ERROR;
FND_MESSAGE.SET_NAME('ZX','ZX_INVALID_CONTEXT_CCID');
FND_MSG_PUB.ADD;
Return; 
END SYNCHRONIZE_FOR_TAX;
PROCEDURE DOCUMENT_LEVEL_CHANGES( p_context_ccid IN NUMBER
, TRANSACTION_RECORD IN ZX_TAX_PARTNER_PKG.trx_rec_type
, ERROR_STATUS OUT NOCOPY VARCHAR2
, ERROR_DEBUG_MSG_TBL OUT NOCOPY ZX_TAX_PARTNER_PKG.messages_tbl_type
) IS
InvalidContextCcid Exception;
l_api_name  CONSTANT VARCHAR2(80) := 'DOCUMENT_LEVEL_CHANGES';
 Begin 
IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
FND_LOG.STRING(G_LEVEL_PROCEDURE
,G_MODULE_NAME || l_api_name ||'.BEGIN'
,G_PKG_NAME||': '||l_api_name||'()+');
END IF;
/*-- NAIT-185309 commented to reterofit invalid objects
IF p_context_ccid = 17022 THEN 
Twe_taxsrvc_o2c_intl_pkg.Global_document_update(TRANSACTION_RECORD
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17024 THEN 
Twe_taxsrvc_o2c_intl_pkg.Global_document_update(TRANSACTION_RECORD
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17026 THEN 
Twe_taxsrvc_p2p_intl_pkg.Global_document_update(TRANSACTION_RECORD
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSIF p_context_ccid = 17027 THEN 
Twe_taxsrvc_p2p_intl_pkg.Global_document_update(TRANSACTION_RECORD
, ERROR_STATUS
, ERROR_DEBUG_MSG_TBL
);
ELSE  
Raise InvalidContextCcid; 
END IF;*/ 
EXCEPTION 
WHEN InvalidContextccid THEN 
ERROR_STATUS := FND_API.G_RET_STS_ERROR;
FND_MESSAGE.SET_NAME('ZX','ZX_INVALID_CONTEXT_CCID');
FND_MSG_PUB.ADD;
Return; 
END DOCUMENT_LEVEL_CHANGES;
PROCEDURE MAIN_ROUTER (p_srvc_type_id IN NUMBER
, p_context_ccid IN NUMBER
, p_data_transfer_code IN VARCHAR2
, x_return_status OUT NOCOPY VARCHAR2
) IS
InvalidServiceType Exception;
InvalidDataTransferMode Exception;
l_api_name  CONSTANT VARCHAR2(80) := 'MAIN_ROUTER';
  BEGIN 
IF ( G_LEVEL_PROCEDURE >= G_CURRENT_RUNTIME_LEVEL) THEN
FND_LOG.STRING(G_LEVEL_PROCEDURE
,G_MODULE_NAME || l_api_name ||'.BEGIN'
,G_PKG_NAME||': '||l_api_name||'()+');
END IF;
x_return_status := FND_API.G_RET_STS_SUCCESS;
 IF p_data_transfer_code = 'PLS' THEN 
  IF p_srvc_type_id = '1' THEN 
CALCULATE_TAX( p_context_ccid
, ZX_PTNR_SRVC_INTGRTN_PKG.G_TAX_CURRENCIES_TBL
, ZX_PTNR_SRVC_INTGRTN_PKG.G_TAX_LINES_RESULT_TBL
, ZX_PTNR_SRVC_INTGRTN_PKG.G_ERROR_STATUS
, ZX_PTNR_SRVC_INTGRTN_PKG.G_MESSAGES_TBL
);
 IF ZX_PTNR_SRVC_INTGRTN_PKG.G_ERROR_STATUS <> FND_API.G_RET_STS_SUCCESS THEN 
 x_return_status := FND_API.G_RET_STS_ERROR;
 Return ;
 END IF ;
 ELSIF p_srvc_type_id = '2' THEN 
SYNCHRONIZE_FOR_TAX( p_context_ccid
, ZX_PTNR_SRVC_INTGRTN_PKG.G_SYNC_TAX_LINES_TBL
, ZX_PTNR_SRVC_INTGRTN_PKG.G_ERROR_STATUS
, ZX_PTNR_SRVC_INTGRTN_PKG.G_MESSAGES_TBL
);
 IF ZX_PTNR_SRVC_INTGRTN_PKG.G_ERROR_STATUS <> FND_API.G_RET_STS_SUCCESS THEN 
 x_return_status := FND_API.G_RET_STS_ERROR;
 Return ;
 END IF ;
 ELSIF p_srvc_type_id = '3' THEN 
DOCUMENT_LEVEL_CHANGES( p_context_ccid
, ZX_PTNR_SRVC_INTGRTN_PKG.G_TRX_REC
, ZX_PTNR_SRVC_INTGRTN_PKG.G_ERROR_STATUS
, ZX_PTNR_SRVC_INTGRTN_PKG.G_MESSAGES_TBL
);
 IF ZX_PTNR_SRVC_INTGRTN_PKG.G_ERROR_STATUS <> FND_API.G_RET_STS_SUCCESS THEN 
 x_return_status := FND_API.G_RET_STS_ERROR;
 Return ;
 END IF ;
ELSE 
 Raise InvalidServiceType;  
END IF; 
ELSE 
Raise Invaliddatatransfermode;
END IF; 
EXCEPTION 
WHEN InvalidServiceType THEN 
FND_MESSAGE.SET_NAME('ZX','ZX_INVALID_SERVICE_TYPE');
FND_MSG_PUB.ADD; 
Return ; 
WHEN InvalidDataTransferMode THEN 
FND_MESSAGE.SET_NAME('ZX','ZX_INVALID_data_transfer_code');
FND_MSG_PUB.ADD; 
Return ; 
END main_router;
END ZX_THIRD_PARTY_2_PKG ;
/
show error;