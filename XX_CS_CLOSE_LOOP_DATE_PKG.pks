create or replace
package XX_CS_CLOSE_LOOP_DATE_PKG as
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Office Depot                                         |
-- +=====================================================================+
-- | Name  : XX_CS_CLOSE_LOOP_DATE_PKG                       |
-- | Description  : This package contains procedure that will Converte date |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |1.0        05-DEC-2009   Bala E   Initial version                    |
-- |1.1        21-DEC-2009   Bala e   Added XML_conver function          |
-- +=====================================================================+

FUNCTION XX_CS_CLOSE_LOOP_DATE_FORMAT(P_DATE VARCHAR2) RETURN DATE ;
FUNCTION CLOSE_LOOP_XML_CONVERT(LC_COMMENTS VARCHAR2) RETURN VARCHAR2;

END XX_CS_CLOSE_LOOP_DATE_PKG;
/
SHOW ERRORS PACKAGE BODY XX_CS_CLOSE_LOOP_DATE_PKG ;
EXIT;
