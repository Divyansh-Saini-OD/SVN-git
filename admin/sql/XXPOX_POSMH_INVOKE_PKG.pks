create or replace PACKAGE   XXPOX_POSMH_INVOKE_PKG AS
-- +========================================================================================+
-- |                           Office Depot - Project Simplify                          	|
-- +========================================================================================+
-- |Package Name : XXPO_POSMH_INVOKE_PKG                                  		    		|
-- |Purpose      : This package contains the functions required                				|
-- |               to get the values in XXPOXPOSMH_XML and  							    |
-- |			   and call XML Bursting.                   		                		|
-- |                                                                           				|
-- |                                                                           				|
-- |Change History                                                             				|
-- |                                                                          				|
-- |Ver   Date          Author                     Description                        		|
-- |---   -----------   -----------------          ------------------------------------		|
-- |1.0   19-OCT-2017  Jimmy "JimGymGem" Nguyen    For Defect 43410. Tis package is to call |
-- |                                               XXPOXPOSMH_XML and then trigger          |
-- |                                               XML bursting in XXPOXPOSMHBURST.         |
-- |                                                        								|
-- +========================================================================================+

    p_req_id NUMBER;
    l_req_id NUMBER;
    s_req_id NUMBER;
    lb_boolean BOOLEAN;
    PROCEDURE invoke_xml_request (
        errorbuff             OUT VARCHAR2,
        retcode               OUT VARCHAR2,
        p_title               IN VARCHAR2,
        p_buyer_name          IN VARCHAR2,
        p_vendor_from         IN VARCHAR2,
        p_vendor_to           IN VARCHAR2,
        p_invoice_date_from   IN VARCHAR2,
        p_invoice_date_to     IN VARCHAR2,
        p_struct_num          IN VARCHAR2,
        p_category_from       IN VARCHAR2,
        p_category_to         IN VARCHAR2,
        p_item_from           IN VARCHAR2,
        p_item_to             IN VARCHAR2,
        p_price_hold          IN VARCHAR2,
        p_qty_ord_hold        IN VARCHAR2,
        p_qty_rec_hold        IN VARCHAR2,
        p_quality_hold        IN VARCHAR2,
        p_qty_precision       IN NUMBER,
        debugflag             IN VARCHAR2
    );

    end xxpox_posmh_invoke_pkg;
	/