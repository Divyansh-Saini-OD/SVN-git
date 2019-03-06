CREATE OR REPLACE
PACKAGE "XX_CS_DISPUTE_SR_PKG" AS

PROCEDURE MAIN_PROC(P_DISPUTE_ID    IN NUMBER,
                    P_TRX_ID        IN NUMBER,
                    P_TRX_NUMBER    IN VARCHAR2,
                    P_PROBLEM_CODE  IN VARCHAR2,
                    P_DESCRIPTION   IN VARCHAR2,
                    P_NOTES         IN VARCHAR2,
                    P_USER_NAME     IN VARCHAR2,
                    P_CUSTOMER_ID   IN NUMBER,
                    X_REQUEST_NUM   IN OUT NOCOPY NUMBER,
                    X_RETURN_MSG    IN OUT NOCOPY VARCHAR2);

PROCEDURE CREATE_SR ( P_DISPUTE_ID     IN NUMBER,
                      P_TRX_ID         IN NUMBER,
                      P_TRX_NUMBER     IN VARCHAR2,
                      P_PROBLEM_CODE   IN VARCHAR2,
                      P_DESCRIPTION    IN VARCHAR2,
                      P_NOTES          IN VARCHAR2,
                      P_USER_ID        IN NUMBER,
                      P_SALES_REP_ID   IN NUMBER,
                      P_ORDER_NUM      IN VARCHAR2,
                      P_WAREHOUSE_NUM  IN VARCHAR2,
                      P_CUSTOMER_ID    IN NUMBER,
                      X_REQUEST_NUM    IN OUT NOCOPY VARCHAR2,
                      X_REQUEST_ID     IN OUT NOCOPY VARCHAR2,
                      X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                      X_MSG_DATA       IN OUT NOCOPY VARCHAR2);

PROCEDURE UPDATE_SR (P_REQUEST_ID     IN NUMBER,
                     P_NOTES          IN VARCHAR2,
                     X_RETURN_STATUS  IN OUT NOCOPY VARCHAR2,
                     X_MSG_DATA       IN OUT NOCOPY VARCHAR2);
 

END;
/
EXIT;