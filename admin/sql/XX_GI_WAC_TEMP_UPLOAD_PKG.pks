CREATE OR REPLACE PACKAGE XX_GI_WAC_TEMP_UPLOAD_PKG  AUTHID CURRENT_USER AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  Oracle NAIO                                                   |
-- +================================================================================+
-- | Name       : XX_GI_WAC_TEMP_UPLOAD_PKG                                         |
-- |                                                                                |
-- | Description: This package  is used to upload the template file from Linux to   |
-- |              fnd_lobs table                                                    |                        |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date           Author           Remarks                               |
-- |=======   ============   =============    ======================================|
-- |DRAFT 1A  23-JUL-07      Mithun D S       Initial draft version                 |
-- +================================================================================+

PROCEDURE UPLOAD_TEMPLATE (
                             x_errbuf     OUT VARCHAR2 -- Standard Out variable
                            ,x_retcode    OUT NUMBER   -- Standard Out variable
                          );


END  XX_GI_WAC_TEMP_UPLOAD_PKG;
/
SHOW ERROR;
EXIT;