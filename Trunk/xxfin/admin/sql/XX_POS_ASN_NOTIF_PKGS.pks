create or replace PACKAGE POS_ASN_NOTIF AUTHID CURRENT_USER AS
/* $Header: POSASNNS.pls 115.3.11510.5 2006/06/01 23:51:33 hvadlamu ship $*/


PROCEDURE GENERATE_NOTIF (
        p_shipment_num    IN VARCHAR2,
	p_notif_type	  IN VARCHAR2,
	p_vendor_id	  IN NUMBER,
	p_vendor_site_id  IN NUMBER,
	p_user_id	  IN INTEGER,
	p_invoker	  IN VARCHAR2 default null
);

-- +===================================================================+
-- | Name  : GET_ASN_REQSTR                                            |
-- | Description      : This Function will be used to get the requestor|
-- |                    ids for a given po_header_id.                  |
-- |                                                                   |
-- | Parameters :       p_item_type, p_item_key, p_act_id,             |
-- |                    funcmode                                       |
-- |                                                                   |
-- | Returns :          x_result                                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE GET_ASN_REQSTR(
			 p_item_type IN VARCHAR2,
			 p_item_key  IN VARCHAR2,
			 p_actid       IN NUMBER,
                         funcmode    IN  VARCHAR2,
                         x_result      OUT NOCOPY VARCHAR2);
-- +===================================================================+
-- | Name  : SET_NEXT_REQSTR                                           |
-- | Description      : This Function will be used to fetch requestor  |
-- |                    name.                                          |
-- |                                                                   |
-- | Parameters :       p_item_type, p_item_key, p_act_id,             |
-- |                    funcmode                                       |
-- |                                                                   |
-- | Returns :          x_result                                       |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE SET_NEXT_REQSTR(
                         p_item_type IN VARCHAR2,
                         p_item_key  IN VARCHAR2,
                         p_actid       IN NUMBER,
                         funcmode    IN  VARCHAR2,
                         x_result      OUT NOCOPY VARCHAR2);
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

PROCEDURE GENERATE_ASN_SUBJECT (
                         p_itemkey   IN VARCHAR2,
                         display_type  IN VARCHAR2,
   			 document      IN OUT nocopy VARCHAR2,
   			 document_type IN OUT nocopy VARCHAR2);


PROCEDURE GENERATE_ASN_BODY(p_ship_num_buyer_id IN VARCHAR2,
                            display_type   in      Varchar2,
                            document in OUT NOCOPY clob,
                            document_type  in OUT NOCOPY  varchar2);

 
END POS_ASN_NOTIF;
/