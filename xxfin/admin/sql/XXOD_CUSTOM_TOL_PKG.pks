create or replace package XXOD_CUSTOM_TOL_PKG as
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XXOD_CUSTOM_TOL_PKG.pks                             	 |
-- | Description :  Package for updating Tolerance Information in the custom |
-- |                table													 |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |1.0       01-AUG-2017 Sridhar G.	     Initial version                 |
-- +=========================================================================+

PROCEDURE UPDATE_TOLERANCE_DATA(P_VENDOR_ID IN NUMBER);
end XXOD_CUSTOM_TOL_PKG;
/
