create or replace 
PACKAGE XX_AR_SUBSCRIPTIONS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_AR_SUBSCRIPTIONS_PKG                                                            |
  -- |                                                                                            |
  -- |  Description:  This package is to process subscription billing                             |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         11-DEC-2018  Sreedhar Mohan   Initial version                                  |
  -- +============================================================================================+
  PROCEDURE process_subscription(
      errbuff OUT VARCHAR2,
      retcode OUT VARCHAR2,
      p_contract_num IN VARCHAR2 
      ); 
      
  PROCEDURE populate_interface(
      errbuff OUT VARCHAR2 ,
      retcode OUT VARCHAR2 ,
      p_contract     IN VARCHAR2 
      );
      
  PROCEDURE import_rec_bills ( errbuff      OUT VARCHAR2
                             , retcode      OUT VARCHAR2
                             ); 
                             
  PROCEDURE import_contracts ( errbuff      OUT VARCHAR2
                             , retcode      OUT VARCHAR2
                             );
                             
  PROCEDURE process_re_authorization ( errbuff OUT VARCHAR2 
                                     , retcode OUT NUMBER
                                     );
                                     
  PROCEDURE pre_validate_service(
    errbuff      OUT     VARCHAR2,
    retcode      OUT     VARCHAR2,
    p_auth_url   IN      VARCHAR2,
    p_wallet_loc IN     VARCHAR2
    );

  FUNCTION get_customer(
      p_order_number VARCHAR2
     , p_site_usage  VARCHAR2)
    RETURN NUMBER;
    
  FUNCTION get_customer_site(
      p_order_number VARCHAR2
     , p_site_usage  VARCHAR2)
    RETURN NUMBER;
    
  ln_tax_amount NUMBER                                                := 0;
  lc_customer_type hz_cust_accounts_all.attribute18%TYPE              := NULL;
  lc_sloc hr_locations_all.location_code%TYPE                         := NULL;
  lc_sloc_type hr_lookups.meaning%TYPE                                := NULL;
  lc_oloc hr_locations_all.location_code%TYPE                         := NULL;
  lc_oloc_type hr_lookups.meaning%TYPE                                := NULL;
  lc_dept      VARCHAR2(256)                                          := NULL;
  lc_item_type VARCHAR2(256)                                          := NULL;
  lc_item_source xx_om_line_attributes_all.item_source%TYPE           := NULL;
  lc_trx_type ra_cust_trx_types_all.cust_trx_type_id%TYPE             := NULL;
  lc_source_type_code oe_order_lines_all.source_type_code%TYPE        := NULL;
  lc_consignment xx_om_line_attributes_all.consignment_bank_code%TYPE := NULL;
  
END XX_AR_SUBSCRIPTIONS_PKG;
/