create or replace
PACKAGE "XX_CS_CLOSE_LOOP_PKG" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_CLOSE_LOOP_PKG                                     |
-- |                                                                   |
-- | Description: Extension for Close the Request based on Mobile cast |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       25-Apr-08   Raj Jagarlamudi  Initial draft version       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE GET_AQ_MESSAGE (P_RETURN_CODE OUT NOCOPY NUMBER,
                          P_ERROR_MSG OUT NOCOPY VARCHAR2);

PROCEDURE UPDATE_SR_STATUS (P_ORDER_NUMBER    IN VARCHAR2,
                            P_MESSAGE         IN VARCHAR2,
                            P_STATUS_CODE     IN VARCHAR2,
                            X_RETURN_STATUS   IN OUT NOCOPY VARCHAR2,
                            X_RETURN_MSG      IN OUT NOCOPY VARCHAR2);
END;

/
EXIT;

