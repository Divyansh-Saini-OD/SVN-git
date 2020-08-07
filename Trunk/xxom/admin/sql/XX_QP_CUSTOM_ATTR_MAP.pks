create or replace PACKAGE "XX_QP_CUSTOM_ATTR_MAP" AS

--+====================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name       :    XX_QP_CUSTOM_ATTR_MAP.pks                         |
-- | Description:    Map custom attributes to custom PTE               |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 27-APR-07    Raj Jagarlamudi  Initial draft version       |
-- |                                                                   |
-- +===================================================================+

-- Attribute Map List details for coupon issues 
 /*=======================================================================+
 | Qualifier_Attribute31  - Channel.
 | Qualifier_Attribute34  - Customer Type 
 | Qualifier_Attribute35  - Department
 | Qualifier_Attribute36 -  Class
 *=======================================================================*/

/***********************************************************************
/*  Get OD Ship Country 
/***********************************************************************/

  FUNCTION get_om_ship_to_country(p_ship_to_org_id IN NUMBER)
  RETURN VARCHAR2;

/***********************************************************************
/*  Get OD Order Ship To State code
/***********************************************************************/
  FUNCTION get_om_ship_to_state(p_ship_to_org_id IN NUMBER)
  RETURN VARCHAR2;

/***********************************************************************
/*  Get OD customer category code
/***********************************************************************/

  FUNCTION get_cust_category(p_sold_to_org_id IN NUMBER)
  RETURN VARCHAR2;

/***********************************************************************
/*  Get OD customer revenue code DFF
/***********************************************************************/

  FUNCTION get_cust_revenue_code(p_ship_to_org_id IN NUMBER)
  RETURN VARCHAR2;

/***********************************************************************
/*  Get OD Order Ship To ZIP code
/***********************************************************************/
  FUNCTION get_om_ship_to_zip(p_ship_to_org_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************
/*  Get OD Order Ship metod code
/***********************************************************************/
  FUNCTION get_om_ship_method(p_order_header_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************
/*  Get Disocunted order amount
/***********************************************************************/
  FUNCTION  get_om_order_amt (p_header_id IN NUMBER)
  RETURN NUMBER;
/******************************************************************************
/*  Get Discounted item amount
/******************************************************************************/
  FUNCTION get_disc_item_amount (p_ordered_qty IN NUMBER,p_pricing_qty IN NUMBER) 
  RETURN VARCHAR2;
/***********************************************************************
/*  Get Discounted item Cost
/***********************************************************************/
  FUNCTION get_item_cost(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************
/*  Get Item Manufacuturer Name
/***********************************************************************/
  FUNCTION get_item_manufacturer(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************
/*  Get Item Vendor Name
/***********************************************************************/
  FUNCTION get_item_vendor(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************
/*  Get OD Item Brand Name
/***********************************************************************/
  FUNCTION get_item_OD_brand(p_inventory_item_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************
/*  Get OD Item Type
/***********************************************************************/
  FUNCTION get_item_type(p_inventory_item_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************************
/*  Get OD List Price
/***********************************************************************************/
  FUNCTION get_list_price(p_list_header_id IN NUMBER, p_inventory_item_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************************
/*  Get OD Item Cost
/***********************************************************************************/
  FUNCTION get_OD_cost(p_inventory_item_id IN NUMBER, p_organization_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************************
/*  Get OD Order Source
/***********************************************************************************/
  FUNCTION get_order_source(p_order_source_id IN NUMBER)
  RETURN VARCHAR2;
/***********************************************************************/
/*    Get OD department 
/***********************************************************************/
  FUNCTION GET_DEPT (p_inv_item_id IN NUMBER) 
  RETURN VARCHAR2;
/***********************************************************************/
/*    Get OD department class
/***********************************************************************/
  FUNCTION GET_CLASS (p_inv_item_id IN NUMBER) 
  RETURN VARCHAR2;
/***********************************************************************
/*  Get OD customer Account Type 
/***********************************************************************/
  FUNCTION get_customer_type(p_sold_to_org_id IN NUMBER) 
  RETURN VARCHAR2;
/***********************************************************************
/*  Get Pricing Group 
/***********************************************************************/
   FUNCTION GET_PRICING_GROUP (p_inv_item_id IN NUMBER) 
  RETURN VARCHAR2;

END;
