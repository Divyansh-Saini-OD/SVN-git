create or replace PACKAGE XX_FIN_IREC_CC_TOKEN_PKG
-- +===========================================================================+
-- |                  Office Depot - Office Max Integration Project            |
-- +===========================================================================+
-- | Name        : XX_FIN_IREC_CC_TOKEN_PKG                                    |
-- | RICE        : E1294                                                       |
-- |                                                                           |
-- | Description :                                                             |
-- | This package helps is to execute AJB request call and retrieve token      |
-- | from Response.                                                            |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author            Remarks                             |
-- |======== =========== =============     ====================================|
-- |DRAFT 1  20-MAY-2015 Sreedhar Mohan    Initial draft version               |
-- |1.1      20-JUL-2020 Divyansh Saini    Added procedure for ECOMM           |
-- |                                       tokenization for NAIT-129669        |
-- +===========================================================================+
IS
    PROCEDURE GET_TOKEN (
         P_ERROR_MSG            IN OUT NOCOPY VARCHAR2
        ,P_ERROR_CODE           IN OUT NOCOPY VARCHAR2
        ,P_OapfAction           IN VARCHAR2 DEFAULT NULL
        ,P_OapfTransactionId    IN VARCHAR2 DEFAULT NULL
        ,P_OapfNlsLang          IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtInstrID       IN VARCHAR2
        ,P_OapfPmtFactorFlag    IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtInstrExp      IN DATE
        ,P_OapfOrgType          IN VARCHAR2 DEFAULT NULL
        ,P_OapfTrxnRef          IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtInstrDBID     IN VARCHAR2 DEFAULT NULL
        ,P_OapfPmtChannelCode   IN VARCHAR2 DEFAULT NULL
        ,P_OapfAuthType         IN VARCHAR2 DEFAULT NULL
        ,P_OapfTrxnmid          IN VARCHAR2 DEFAULT NULL
        ,P_OapfStoreId          IN VARCHAR2 DEFAULT NULL
        ,P_OapfPrice            IN VARCHAR2 DEFAULT NULL
        ,P_OapfOrderId          IN VARCHAR2 DEFAULT NULL
        ,P_OapfCurr             IN VARCHAR2 DEFAULT NULL
        ,P_OapfRetry            IN VARCHAR2 DEFAULT NULL
        ,P_OapfCVV2             IN VARCHAR2 DEFAULT NULL
        ,X_TOKEN               OUT VARCHAR2
        ,X_TOKEN_FLAG          OUT VARCHAR2
    );
/*========================================================================
 | PUBLIC function GET_TOKEN_ECOMM
 |
 | DESCRIPTION
 |      Get token values from Ecomm webservice.
 |      ----------------------------------------
 |
 | PSEUDO CODE/LOGIC
 |
 | PARAMETERS
 |      p_account_number   IN      varchar2
 |      p_expiration_date   IN      varchar2
 |
 | RETURNS
 |      x_token
 |      x_token_flag
 |      x_error_msg
 |      x_error_code
 |
 | KNOWN ISSUES
 |
 |
 |
 | NOTES
 |
 |
 |
 | MODIFICATION HISTORY
 | Date                  Author            Description of Changes
 | 22-JUL-2020           Divyansh Saini      Created
 |
 *=======================================================================*/
PROCEDURE GET_TOKEN_ECOMM(p_account_number   IN              VARCHAR2,
                       p_expiration_date  IN              VARCHAR2,
                       x_token             OUT NOCOPY      VARCHAR2,
                       x_token_flag            OUT NOCOPY      VARCHAR2,
                       x_error_msg            IN OUT NOCOPY VARCHAR2,
                       x_error_code           IN OUT NOCOPY VARCHAR2
);
end XX_FIN_IREC_CC_TOKEN_PKG;
/