SET VERIFY        OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_LOOKUPS_PKG                                        |
-- | Description: Case Management lookups package                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-APR-07   Raj Jagarlamudi  Initial draft version       |
-- +===================================================================+


CREATE OR REPLACE
PACKAGE XX_CS_LOOKUPS_PKG AS

PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_REQ_PRO_REC_TYPE);

PROCEDURE REQUEST_TYPES(P_USER_ID IN VARCHAR2,
                         P_RETURN_MESG  IN OUT NOCOPY VARCHAR2,
                         P_REQ_TYPE_TBL IN OUT NOCOPY XX_CS_REQUEST_TBL_TYPE);

PROCEDURE PROBLEM_CODES(P_USER_ID IN VARCHAR2,
                         P_REQUEST_ID IN NUMBER,
                         P_RETURN_MESG  IN OUT NOCOPY VARCHAR2,
                         P_PROBLEM_CODE_TBL IN OUT NOCOPY XX_CS_PROBLEMCODE_TBL_TYPE);

PROCEDURE MAP_TYPE_CODE(P_USER_ID IN VARCHAR2,
                        P_RETURN_MESG  IN OUT NOCOPY VARCHAR2,
                        P_REQ_LINES_TBL IN OUT NOCOPY XX_CS_REQ_PRO_TBL_TYPE);

PROCEDURE CHANNEL_LIST (P_RETURN_MESG IN OUT NOCOPY VARCHAR2,
                        P_CHANNEL_TBL IN OUT NOCOPY XX_CS_CHANNEL_TBL);

PROCEDURE STATUS_LIST (P_RETURN_MESG IN OUT NOCOPY VARCHAR2,
                        P_STATUS_TBL IN OUT NOCOPY XX_CS_SR_STATUS_TBL);

END XX_CS_LOOKUPS_PKG;
/

SHOW ERROR;
EXIT;
