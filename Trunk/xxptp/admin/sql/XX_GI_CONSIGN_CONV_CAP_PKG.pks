SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_GI_CONSIGN_CONV_CAP_PKG AUTHID CURRENT_USER
AS
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                  |
-- +==============================================================================+
-- |                                                                              |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version   Date        Author           Remarks                                |
-- |=======   ==========  =============    =======================================|
-- |Draft 1a  24-SEP-2007 Siddharth Singh  Initial draft version                  |
-- +==============================================================================+

--Global variables to hold Transaction Type Names
G_TRANS_TYPE_CR    CONSTANT mtl_transaction_types.transaction_type_name%TYPE :='OD Consign to Reg Avg Cost Upd';
G_TRANS_TYPE_RC    CONSTANT mtl_transaction_types.transaction_type_name%TYPE :='OD Reg to Consign Avg Cost Upd';
G_TRANS_TYPE_PO    CONSTANT mtl_transaction_types.transaction_type_name%TYPE :='OD Consign PO Cost Update';

--Global Variables to hold Change Type of Concurrent Program OD: GI Consign Change Load.
G_CHANGE_TYPE_CR  CONSTANT VARCHAR2(30) := 'Consign to Regular';
G_CHANGE_TYPE_RC  CONSTANT VARCHAR2(30) := 'Regular to Consign';
G_CHANGE_TYPE_PO  CONSTANT VARCHAR2(30) := 'Consign PO Cost Change';

PROCEDURE PROCESS_UPDATE_WAC ( x_errbuf      OUT VARCHAR2
                              ,x_retcode     OUT NUMBER
                              ,p_change_type IN  VARCHAR2
                              );




END  XX_GI_CONSIGN_CONV_CAP_PKG;
/
SHOW ERRORS;

--EXIT;