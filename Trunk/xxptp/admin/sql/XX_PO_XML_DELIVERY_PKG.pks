SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      ON;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_PO_XML_DELIVERY_PKG AUTHID CURRENT_USER AS
/* $Header: /home/cvs/repository/Office_Depot/SRC/P2P/E0408_PO_XMLG_Modifications/3.\040Source\040Code\040&\040Install\040Files/XX_PO_XML_DELIVERY_PKG_PKG.pks,v 1.1 2007/09/10 11:06:48 sgaur Exp $ */

 /*=======================================================================+
 | FILENAME
 |   POXWXMLS.pls
 |
 | DESCRIPTION
 |   PL/SQL spec for package: PO_XML_DELIVERY
 |
 | NOTES
 | MODIFIED    Created jbalakri (05/03/2001)
 *=====================================================================*/
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/Office Depot/Consulting Organization             |
-- +===================================================================+
-- | Name       : XX_PO_XML_DELIVERY_PKG.pks                           |
-- | Description: This package is a customised copy of the standard    |
-- | package PO_XML_DELIVERY. In this package set_delivery_data proc.  |
-- | is customized to check for generic vendor_id and vendor_site_id   |
-- | instead for individual vendor associated with a purchase order.   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 12-MAR-2007  Seemant Gour     Initial draft version       |
-- |DRAFT 1b 28-APR-2007  Vikas Raina      Updated after review        |
-- |1.0      03-MAY-2007  Seemant Gour     Baseline for Release        |
-- |2.0      27-AUG-2007  Seemant Gour     Updated due to the change   |
-- |                                       that came in due to the patch 5737143 |
-- |2.1      08-NOV-2007  Seemant Gour     Changed the package name to |
-- |                                       XX_PO_XML_DELIVERY_PKG as per|
-- |                                       standards.                  |
-- +===================================================================+


PROCEDURE call_txn_delivery (  itemtype        IN VARCHAR2,
                               itemkey         IN VARCHAR2,
                               actid           IN NUMBER,
                               funcmode        IN VARCHAR2,
                               resultout       OUT NOCOPY VARCHAR2);
PROCEDURE set_delivery_data    (  itemtype        IN VARCHAR2,
                               itemkey         IN VARCHAR2,
                               actid           IN NUMBER,
                               funcmode        IN VARCHAR2,
                               resultout       OUT NOCOPY VARCHAR2);
PROCEDURE is_partner_setup  (  itemtype        IN VARCHAR2,
                               itemkey         IN VARCHAR2,
                               actid           IN NUMBER,
                               funcmode        IN VARCHAR2,
                               resultout       OUT NOCOPY VARCHAR2);
/* XML Delivery Project, FPG+ */
PROCEDURE is_xml_chosen     (  itemtype        IN VARCHAR2,
                               itemkey         IN VARCHAR2,
                               actid           IN NUMBER,
                               funcmode        IN VARCHAR2,
                               resultout       OUT NOCOPY VARCHAR2);
/* XML Delivery Project, FPG+ */
PROCEDURE xml_time_stamp	(	p_header_id IN VARCHAR2,
                                                p_release_id VARCHAR2,
								p_org_id IN NUMBER,
								p_txn_type IN VARCHAR2,
								p_document_type IN VARCHAR2);
/* XML Delivery Project, FPG+ */
PROCEDURE get_line_requestor(	p_header_id IN VARCHAR2,
								p_line_id IN VARCHAR2,
								p_release_num IN NUMBER,
								p_document_type IN VARCHAR2,
								p_revision_num IN VARCHAR2,
								p_requestor OUT NOCOPY VARCHAR2);
/* XML Delivery Project, FPG+ */
PROCEDURE get_xml_send_date(	p_header_id IN VARCHAR2,
								p_release_id IN VARCHAR2,
								p_document_type IN VARCHAR2,
								out_date OUT NOCOPY DATE);
/* XML Delivery Project, FPG+ */
FUNCTION get_max_line_revision(
				p_header_id VARCHAR2,
				p_line_id VARCHAR2,
				p_line_revision_num NUMBER,
				p_revision_num NUMBER)
				RETURN NUMBER;

/* XML Delivery Project, FPG+ */
FUNCTION get_max_location_revision(	p_header_id VARCHAR2,
									p_line_id VARCHAR2,
									p_location_id VARCHAR2,
									p_location_revision_num NUMBER,
									p_revision_num NUMBER)
									RETURN NUMBER;


PROCEDURE get_card_info( p_header_id IN VARCHAR2,
		         p_document_type IN VARCHAR2,
		         p_release_id IN VARCHAR2,
			 p_card_num OUT NOCOPY VARCHAR2,
		         p_card_name OUT NOCOPY VARCHAR2,
			 p_card_exp_date OUT NOCOPY DATE,
			 p_card_brand OUT NOCOPY VARCHAR2);

-- procedure to get the ship_to info in cXML address format.
-- In OAG we've 3 address lines, and cXML has 1 address line.
-- This procedure calls get_shipt_info internally.

PROCEDURE get_cxml_shipto_info( p_header_id  IN NUMBER, p_line_location_id  IN NUMBER,
                           p_ship_to_location_id IN NUMBER,
                           p_ECE_TP_LOCATION_CODE OUT NOCOPY VARCHAR2,
                           p_ADDRESS_LINE OUT NOCOPY VARCHAR2, p_TOWN_OR_CITY OUT NOCOPY VARCHAR2,
			   p_COUNTRY OUT NOCOPY VARCHAR2, p_POSTAL_CODE OUT NOCOPY VARCHAR2,
			   p_STATE OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_1 OUT NOCOPY VARCHAR2,
                           p_TELEPHONE_NUMBER_2 OUT NOCOPY VARCHAR2,
                           p_TELEPHONE_NUMBER_3 OUT NOCOPY VARCHAR2,
                           p_iso_country_code OUT NOCOPY VARCHAR2);

-- procedure to get the ship_to info from hr_lcoations or hz_locations depending upon
-- the given location_id for the po_header_id is drop-ship or not.
PROCEDURE get_shipto_info( p_header_id  IN NUMBER, p_line_location_id  IN NUMBER,
                           p_ship_to_location_id IN NUMBER,
                           p_ECE_TP_LOCATION_CODE OUT NOCOPY VARCHAR2,
                           p_ADDRESS_LINE_1 OUT NOCOPY VARCHAR2, p_ADDRESS_LINE_2 OUT NOCOPY VARCHAR2,
			   p_ADDRESS_LINE_3 OUT NOCOPY VARCHAR2, p_TOWN_OR_CITY OUT NOCOPY VARCHAR2,
			   p_COUNTRY OUT NOCOPY VARCHAR2, p_POSTAL_CODE OUT NOCOPY VARCHAR2,
			   p_STATE OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_1 OUT NOCOPY VARCHAR2,
                           p_TELEPHONE_NUMBER_2 OUT NOCOPY VARCHAR2, p_TELEPHONE_NUMBER_3 OUT NOCOPY VARCHAR2);


-- Created new procedure for bug#4611474
-- the given location_id for the po_header_id is drop-ship or not.
PROCEDURE get_oag_shipto_info(
			p_header_id			IN NUMBER,
			p_line_location_id	IN NUMBER,
			p_ship_to_location_id	IN NUMBER,
			p_ECE_TP_LOCATION_CODE	OUT NOCOPY VARCHAR2,
			p_ADDRESS_LINE_1		OUT NOCOPY VARCHAR2,
			p_ADDRESS_LINE_2		OUT NOCOPY VARCHAR2,
			p_ADDRESS_LINE_3		OUT NOCOPY VARCHAR2,
			p_TOWN_OR_CITY		OUT NOCOPY VARCHAR2,
			p_COUNTRY 			OUT NOCOPY VARCHAR2,
			P_COUNTY			OUT NOCOPY VARCHAR2,
			p_POSTAL_CODE		OUT NOCOPY VARCHAR2,
			p_STATE 			OUT NOCOPY VARCHAR2,
			p_REGION			OUT NOCOPY VARCHAR2,
			p_TELEPHONE_NUMBER_1	OUT NOCOPY VARCHAR2,
			p_TELEPHONE_NUMBER_2	OUT NOCOPY VARCHAR2,
			p_TELEPHONE_NUMBER_3	OUT NOCOPY VARCHAR2);

PROCEDURE setXMLEventKey (  itemtype        IN VARCHAR2,
                          itemkey         IN VARCHAR2,
                          actid           IN NUMBER,
                          funcmode        IN VARCHAR2,
                          resultout       OUT NOCOPY VARCHAR2);



PROCEDURE setwfUserKey (  itemtype        IN VARCHAR2,
                          itemkey         IN VARCHAR2,
                          actid           IN NUMBER,
                          funcmode        IN VARCHAR2,
                          resultout       OUT NOCOPY VARCHAR2);

--sets some session values like session language
PROCEDURE initTransaction (p_header_id  IN NUMBER,
                           p_vendor_id  VARCHAR2,
                           p_vendor_site_id VARCHAR2,
                           transaction_type VARCHAR2 ,
                           transaction_subtype VARCHAR2,
                           p_release_id VARCHAR2 DEFAULT NULL, /*parameter1*/
                           p_revision_num  VARCHAR2 DEFAULT NULL, /*parameter2*/
                           p_parameter3  VARCHAR2 DEFAULT NULL,
                           p_parameter4 VARCHAR2 DEFAULT NULL,
                           p_parameter5  VARCHAR2 DEFAULT NULL);

--Initializes wf item attributes with the PO information.
PROCEDURE initialize_wf_parameters (
   itemtype  IN VARCHAR2,
   itemkey         IN VARCHAR2,
   actid           IN NUMBER,
   funcmode        IN VARCHAR2,
   resultout       OUT NOCOPY VARCHAR2);


/*
In cXML the deliverto information is provided as
 <DELIVERTO>
QUANTITY: PO_cXML_DELIVERTO_ARCH_V.QUANTITY ||
 NAME: || PO_cXML_DELIVERTO_ARCH_V.REQUESTOR ||
ADDRESS: || PO_cXML_DELIVERTO_ARCH_V.all the address tags
</DELIVERTO>
This is a helper function to concatinate all these values.
*/
PROCEDURE get_cxml_deliverto_info(p_QUANTITY  IN NUMBER, p_REQUESTOR IN VARCHAR2,
                                  p_LOCATION_CODE IN VARCHAR2, p_ADDRESS_LINE IN VARCHAR2,
                                  p_COUNTRY IN VARCHAR2, p_POSTAL_CODE IN VARCHAR2,
                                  p_TOWN_OR_CITY IN VARCHAR2, p_STATE IN VARCHAR2,
                                  p_deliverto OUT NOCOPY VARCHAR2);

--Start of the comment
--
-- End of the comment
PROCEDURE get_cxml_header_info (p_tp_id  IN  NUMBER,
                                p_tp_site_id  IN NUMBER,
                                x_from_domain  OUT NOCOPY VARCHAR2,
                                x_from_identity OUT NOCOPY VARCHAR2,
                                x_to_domain    OUT NOCOPY VARCHAR2,
                                x_to_identity  OUT NOCOPY VARCHAR2,
                                x_sender_domain OUT NOCOPY VARCHAR2,
                                x_sender_identity OUT NOCOPY VARCHAR2,
                                x_sender_sharedsecret OUT NOCOPY VARCHAR2,
                                x_user_agent  OUT NOCOPY VARCHAR2,
                                x_deployment_mode OUT NOCOPY VARCHAR2
                                );


PROCEDURE IS_XML_CHN_REQ_SOURCE(itemtype IN VARCHAR2,
			        itemkey IN VARCHAR2,
    	    		        actid IN NUMBER,
	    	        	funcmode IN VARCHAR2,
            	            	resultout OUT NOCOPY VARCHAR2);
PROCEDURE get_header_shipto_info (p_po_header_id  IN NUMBER,
                                  p_po_release_id IN NUMBER,
                                  x_partner_id  OUT NOCOPY NUMBER,
                                  x_partner_id_x OUT NOCOPY VARCHAR2,
                                  x_address_line_1 OUT NOCOPY VARCHAR2,
                                  x_address_line_2 OUT NOCOPY VARCHAR2,
                                  x_address_line_3 OUT NOCOPY VARCHAR2,
                                  x_city  OUT NOCOPY VARCHAR2,
                                  x_country  OUT NOCOPY VARCHAR2,
                                  x_county  OUT NOCOPY VARCHAR2,
                                  x_postalcode  OUT NOCOPY VARCHAR2,
                                  x_region OUT NOCOPY VARCHAR2,
                                  x_stateprovn  OUT NOCOPY VARCHAR2,
                                  x_telephone_1 OUT NOCOPY VARCHAR2,
                                  x_telephone_2 OUT NOCOPY VARCHAR2,
                                  x_telephone_3 OUT NOCOPY VARCHAR2
                                  );


PROCEDURE get_cxml_header_shipto_info (p_po_header_id  IN NUMBER,
                                  p_po_release_id IN NUMBER,
                                  x_address_line_123 OUT NOCOPY VARCHAR2,
                                  x_city  OUT NOCOPY VARCHAR2,
                                  x_country  OUT NOCOPY VARCHAR2,
                                  x_postalcode  OUT NOCOPY VARCHAR2,
                                  x_stateprovn  OUT NOCOPY VARCHAR2,
                                  x_telephone_1 OUT NOCOPY VARCHAR2,
				  	    x_deliverto OUT NOCOPY VARCHAR2
                                  );

PROCEDURE set_user_context    (  itemtype        IN VARCHAR2,
                               itemkey         IN VARCHAR2,
                               actid           IN NUMBER,
                               funcmode        IN VARCHAR2,
                               resultout       OUT NOCOPY VARCHAR2);



END  XX_PO_XML_DELIVERY_PKG;
/

EXIT;
/
