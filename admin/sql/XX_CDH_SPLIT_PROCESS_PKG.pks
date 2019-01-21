CREATE OR REPLACE PACKAGE APPS.XX_CDH_SPLIT_PROCESS_PKG 
AS
-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_CDH_SPLIT_PROCESS_PKG.pks                              |
-- | Description :  C0702: MOD 5 Party Split Sync Process                     |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author             Remarks                         |
-- |========  ===========  =================  ================================|
-- |1.0       13-JUL-2015  Havish Kasina      Initial version                 |
-- +==========================================================================+

PROCEDURE relink_party_sites ( p_party_id        IN            NUMBER,
                               p_party_sites_obj IN            XX_CDH_PARTY_SITE_OBJ_TYPE,
							                 x_party_id        OUT           NUMBER,
                               x_return_status   OUT NOCOPY    VARCHAR2,
                               x_error_message   OUT NOCOPY    VARCHAR2);
END XX_CDH_SPLIT_PROCESS_PKG;
/
SHOW ERRORS;