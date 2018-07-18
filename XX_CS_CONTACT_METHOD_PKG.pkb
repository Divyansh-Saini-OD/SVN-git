create or replace 
PACKAGE BODY XX_CS_CONTACT_METHOD_PKG
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                         Wipro Technology                           |
-- +====================================================================+
-- | Name         : XX_CS_CONTACT_METHOD_PKG                            |
-- | Description  : This package is used to get the contact method from |
-- |                the incident id.                                    |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version  Date         Author         Remarks                        |
-- |=======  ===========  =============  ===============================|
-- | 1       18-APR-2016  Rakesh Vyas    Initial version                |
-- |                                     Created for Defect 33881       |
-- +====================================================================+

-- +====================================================================+
-- | Name       : XX_CS_GET_CONTACT_METHOD                              |
-- | Description:                                                       |
-- |                                                                    |
-- | Parameters : p_incident_id                                         |
-- |                                                                    |
-- | Returns :   l_contact_point_type                                   |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+
 
FUNCTION XX_CS_GET_CONTACT_METHOD (p_incident_id IN VARCHAR2) RETURN VARCHAR2
AS

l_contact_point_type VARCHAR2(200):=null;

BEGIN
  SELECT contact_point_type 
  INTO l_contact_point_type  
  FROM cs_hz_sr_contact_points 
  WHERE incident_id=p_incident_id;
  
RETURN l_contact_point_type;

EXCEPTION 
 WHEN OTHERS THEN
  RETURN 'NA'; 
END XX_CS_GET_CONTACT_METHOD;
END XX_CS_CONTACT_METHOD_PKG;
/