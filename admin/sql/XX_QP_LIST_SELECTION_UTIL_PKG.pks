create or replace PACKAGE XX_QP_LIST_SELECTION_UTIL_PKG AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_QP_LIST_SELECTION_UTIL_PKG                            |
-- | Description :                                                     |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 02-JAN-2008  B.Penski         Initial draft version       |
-- +===================================================================+
 
 -- PRICE LIST TYPES
G_PRICE_LIST_TYPE_CAMPAIGN CONSTANT VARCHAR2(30):='CAMPAIGN';
G_PRICE_LIST_TYPE_CZONE    CONSTANT VARCHAR2(30):='COMMERCIAL ZONE';
G_PRICE_LIST_TYPE_WZONE    CONSTANT VARCHAR2(30):='WEB ZONE';
G_PRICE_LIST_TYPE_CUSTOMER CONSTANT VARCHAR2(30):='CUSTOMER';
G_PRICE_LIST_TYPE_FREIGHT  CONSTANT VARCHAR2(30):='FREIGHT';
G_PRICE_LIST_TYPE_STORE    CONSTANT VARCHAR2(30):='STORE';
G_PRICE_LIST_TYPE_DEFAULT  CONSTANT VARCHAR2(30):='DEFAULT';
G_PRICE_LIST_TYPE_MAP      CONSTANT VARCHAR2(30):='MAP';
G_PRICE_LIST_TYPE_MSRP     CONSTANT VARCHAR2(30):='MSRP';

-- Customer specific flag
G_CUST_W_NO_SPEC_PRICE    CONSTANT VARCHAR2(3):= 'NSP';
G_CUST_W_SPEC_PRICE       CONSTANT VARCHAR2(3):= 'WSP';
G_CUST_W_BEST_CONTRACT_PR CONSTANT VARCHAR2(3):= 'BCP';
G_CUST_W_BEST_OVERALL_PR  CONSTANT VARCHAR2(3):= 'BOP';
G_CUST_W_BEST_CONT_OVER_PR CONSTANT VARCHAR2(3):= 'BCO';

-- Package public Types
TYPE XX_QP_FLOW_REC_TYPE is Record (
    flow_name           VARCHAR2(150)
  , precedence          NUMBER
  , validation_process  VARCHAR2(240)
  , process_name        VARCHAR2(240) 
  , Part_of_Best_Price  VARCHAR2(30)
  , Defines_selling_price VARCHAR2(30)
);



TYPE XX_QP_FLOW_TBL_TYPE IS TABLE OF XX_QP_FLOW_REC_TYPE;


PROCEDURE report_error( p_error_code    IN xxom.xx_om_global_exceptions.error_code%TYPE DEFAULT '9999' 
                      , p_error_message IN xxom.xx_om_global_exceptions.description%TYPE DEFAULT 'OTHERS'
                      , p_entity_ref    IN xxom.xx_om_global_exceptions.entity_ref%TYPE DEFAULT 'QP List Selection'
                      , p_entity_ref_id IN xxom.xx_om_global_exceptions.entity_ref_id%TYPE) ;
                      
PROCEDURE get_BRF(  p_web_site_key_rec   IN XX_GLB_SITEKEY_REC_TYPE
                  , p_rule_name          IN VARCHAR2
                  , p_rule_value         OUT NOCOPY VARCHAR2
                  );
                        
END XX_QP_LIST_SELECTION_UTIL_PKG;