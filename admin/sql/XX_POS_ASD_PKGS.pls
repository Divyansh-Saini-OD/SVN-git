create or replace PACKAGE APPS.POS_ASN_NOTIF AUTHID CURRENT_USER AS
/* $Header: POSASNNS.pls 115.3 2002/11/26 02:12:02 mji ship $*/


PROCEDURE GENERATE_NOTIF (
        p_shipment_num    IN VARCHAR2,
	p_notif_type	  IN VARCHAR2,
	p_vendor_id	  IN NUMBER,
	p_vendor_site_id  IN NUMBER,
	p_user_id	  IN INTEGER
);

PROCEDURE GET_ASN_BUYERS(
			 l_item_type IN VARCHAR2,
			 l_item_key  IN VARCHAR2,
			 actid       IN NUMBER,
                         funcmode    IN  VARCHAR2,
                         result      OUT NOCOPY VARCHAR2
);

PROCEDURE SET_NEXT_BUYER(
                         l_item_type IN VARCHAR2,
                         l_item_key  IN VARCHAR2,
                         actid       IN NUMBER,
                         funcmode    IN  VARCHAR2,
                         result      OUT NOCOPY VARCHAR2);

PROCEDURE GENERATE_ASN_BODY(p_ship_num_buyer_id IN VARCHAR2,
                            display_type   in      Varchar2,
                            document in OUT NOCOPY clob,
                            document_type  in OUT NOCOPY  varchar2);


END POS_ASN_NOTIF;
/

