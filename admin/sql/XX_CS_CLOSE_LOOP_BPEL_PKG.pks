create or replace
PACKAGE XX_CS_CLOSE_LOOP_BPEL_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_CLOSE_LOOP_BPEL_PKG                                |
-- |                                                                   |
-- | Description: Extension for Close the Request based on Mobile cast |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       25-Apr-08   Raj Jagarlamudi  Initial draft version       |
-- |1.1       06-Jun-08   B. Penski        Added New Short Message     |
-- +===================================================================+

PROCEDURE ENQUEUE_MESSAGE(P_XML_MESSAGE IN VARCHAR2,
                          P_RETURN_CODE IN OUT NOCOPY VARCHAR2,
                          P_RETURN_MSG  IN OUT NOCOPY VARCHAR2);


END XX_CS_CLOSE_LOOP_BPEL_PKG;
/
exit;
