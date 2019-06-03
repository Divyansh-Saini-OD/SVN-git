CREATE OR REPLACE PACKAGE APPS.XX_POS_OID_PKG AUTHID CURRENT_USER IS
/*======================================================================
-- +===================================================================+
-- |                  Office Depot - iSupplier-Project                 |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_POS_OID_PKG                                      |
-- | Description:  This package is Created for the PBCGS iSupplier     |
-- |               registration worflow process to create a staging    |
-- |               table from FND_USER to OID via XX_XXSEC_POS_OID_USER|
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      12-Feb-2008  Ian Bassaragh    Created The Package         |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/

V_PACKAGE_NAME CONSTANT ALL_OBJECTS.OBJECT_NAME%TYPE := 'XX_POS_OID_PKG';

/*----------------------------------------

  public PROCEDURE XX_CREATE_OID_STAGE

     Workflow activity function. Copy FND_USER to OID staging.
    

     No item attribute values are set:

      
  PARAMS:
    WF Standard API.

  RETURN:
    WF Standard API.

----------------------------------------*/


PROCEDURE XX_CREATE_OID_STAGE(
  itemtype IN VARCHAR2
, itemkey IN VARCHAR2
, actid IN NUMBER
, funcmode IN VARCHAR2
, resultout OUT NOCOPY VARCHAR2
);


END   XX_POS_OID_PKG;
/