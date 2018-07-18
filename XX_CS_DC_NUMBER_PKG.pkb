create or replace 
PACKAGE BODY XX_CS_DC_NUMBER_PKG
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
-- | Name       : XX_CS_DC_NUMBER_PKG                                                  |
-- | Description:                                                                      |
-- |                                                                                   |
-- | Parameters : p_incident_id                                                        |
-- |                                                                                   |
-- | Returns :   l_incident_attribute_11                                               |
-- |                                                                                   |
-- |                                                                                   |
-- +===================================================================================+

FUNCTION XX_CS_GET_DC_NUMBER (p_incident_id IN VARCHAR2) RETURN VARCHAR2
AS

l_incident_attribute_11 VARCHAR2(200):=null;

BEGIN
  SELECT incident_attribute_11
  INTO l_incident_attribute_11
  FROM cs_incidents_all_b
  WHERE incident_id=p_incident_id;

RETURN l_incident_attribute_11;

EXCEPTION
 WHEN OTHERS THEN
  RETURN 'NA';
END XX_CS_GET_DC_NUMBER;
END XX_CS_DC_NUMBER_PKG;
/
