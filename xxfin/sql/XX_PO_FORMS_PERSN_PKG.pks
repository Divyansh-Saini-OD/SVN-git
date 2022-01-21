CREATE OR REPLACE PACKAGE APPS.XX_PO_FORMS_PERSN_PKG AUTHID CURRENT_USER
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- +=========================================================================================+
-- | Name             : XX_PO_FORMS_PERSN                                                    |
-- | Description      : Package spec for E0416 PO FORMS PERSONALIZATION                      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |1.0                          Paul DSouza                                                            |
-- +=========================================================================================+
AS

PROCEDURE UpdatePOLines(p_po_header_id  IN NUMBER, p_po_type IN VARCHAR2, p_vendor_site_id IN NUMBER);
PROCEDURE UpdatePONumber(p_po_header_id  IN NUMBER);
FUNCTION DefaultPOType(p_ship_to_location_id in number,p_vendor_id in number, p_vendor_site_id in number)
RETURN varchar2;
Function GetGSSValues(p_po_header_id in number,p_vendor_site_id in number,p_gss_attribute in varchar2)
RETURN varchar2;
Function DefaultPOSource(p_po_header_id in number)
RETURN varchar2;
END XX_PO_FORMS_PERSN_PKG;
/
