create or replace 
PACKAGE XX_CS_CONTACT_METHOD_PKG
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
-- | Returns :   l_contact_point_type                                 |
-- |                                                                    |
-- |                                                                    |
-- +====================================================================+

 FUNCTION XX_CS_GET_CONTACT_METHOD (p_incident_id IN VARCHAR2) RETURN VARCHAR2;
 

END XX_CS_CONTACT_METHOD_PKG;
/