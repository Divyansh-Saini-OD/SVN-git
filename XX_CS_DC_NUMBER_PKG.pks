create or replace 
PACKAGE XX_CS_DC_NUMBER_PKG
AS
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |                                                                                   |
-- +===================================================================================+
-- | Name         : XX_CS_DC_NUMBER_PKG                                                |
-- | Description  : This package is used to get the DC Number from                     |
-- |                the incident id.                                                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version  Date         Author                        Remarks                        |
-- |=======  ===========  =============          ======================================|
-- | 1       02-JUL-2018  Venkateshwar Panduga      Initial version                    |
-- |                                                 Created for Defect 45199          |
-- +===================================================================================+

-- +===================================================================================+
-- | Name       : XX_CS_GET_DC_NUMBER                                   |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_incident_id                                         |
-- |                                                                    |
-- | Returns :   l_incident_attribute_11                                |
-- |                                                                    |
-- |                                                                    |
-- +===================================================================================+

 FUNCTION XX_CS_GET_DC_NUMBER (p_incident_id IN VARCHAR2) RETURN VARCHAR2;


END XX_CS_DC_NUMBER_PKG;
/
