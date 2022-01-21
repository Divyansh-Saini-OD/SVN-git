CREATE OR REPLACE
package XX_OM_PURGE_IFACE_PKG as
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Office Depot                                         |
-- +=====================================================================+
-- | Name  : XX_OM_PURGE_IFACE_PKG (XXOMSPURGS.pks)                       |
-- | Description  : This package contains procedure that will purge data |
-- | from custom interface tables that out of the box import program     |
-- | doesn't purge.                                                      |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |1.0        05-MAY-2007   Manish Chavan    Initial version            |
-- |                                                                     |
-- +=====================================================================+

PROCEDURE Purge_Data(
    errbuf     OUT NOCOPY VARCHAR2
 ,  retcode    OUT NOCOPY NUMBER
);

END XX_OM_PURGE_IFACE_PKG;
