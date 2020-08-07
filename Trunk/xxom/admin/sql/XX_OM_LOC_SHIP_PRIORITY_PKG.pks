CREATE OR REPLACE PACKAGE XX_OM_LOC_SHIP_PRIORITY_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                                                   |
-- +===================================================================+
-- | Name  : XX_OM_LOC_SHIP_PRIORITY_PKG                               |
-- | Description : Package Spec contains the function to default the   |
-- |               shipment priority for internal orders of non-trade  |
-- |               items                                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |1.0      13-Mar-2008  Matthew Craig    Initial draft version       |
-- |                                                                   |
-- +===================================================================+
AS

-- +===================================================================+
-- | Name : get_shipment_priority                                      |
-- |                                                                   |
-- | Description: This function is used to default the shipment        |
-- |              priority for an internal non-trade order line        |
-- |                                                                   |
-- | Parameters:  p_database_object_name                               |
-- |              p_attribute_code                                     |
-- |                                                                   |
-- | Returns :    shipment_priority_code                               |
-- |                                                                   |
-- +===================================================================+

FUNCTION get_shipment_priority (
    p_database_object_name  IN  VARCHAR2,
    p_attribute_code        IN  VARCHAR2
    ) 
    RETURN VARCHAR2;

END XX_OM_LOC_SHIP_PRIORITY_PKG;
/