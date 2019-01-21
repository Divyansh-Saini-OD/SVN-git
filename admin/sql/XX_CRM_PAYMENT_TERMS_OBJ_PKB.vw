--------------------------------------------------------
--  DDL for Type XX_CRM_PAYMENT_TERMS_OBJ
-------------------------------------------------------
CREATE OR REPLACE TYPE BODY XX_CRM_PAYMENT_TERMS_OBJ AS
  STATIC FUNCTION create_object(
    P_AB_BILLING_FLAG              VARCHAR2 := NULL,
    P_PAYMENT_TERM                 VARCHAR2 := NULL,
    P_PAYTERM_FREQUENCY            VARCHAR2 := NULL,
    P_PAYTERM_REPORTING_DAY        VARCHAR2 := NULL,
    P_PAYTERM_PERCENTAGE           VARCHAR2 := NULL,
    P_BILLDOCS_DOC_TYPE            VARCHAR2 := NULL,
    P_BILLDOCS_DELIVERY_METH       VARCHAR2 := NULL,
    P_BILLDOCS_SPECIAL_HANDLING    VARCHAR2 := NULL,
    P_BILLDOCS_SIG_REQ             VARCHAR2 := NULL,
    P_BILLDOCS_DIRECT_FLAG         VARCHAR2 := NULL,
    P_BILLDOCS_AUTO_REPRINT        VARCHAR2 := NULL,
    P_BILLDOCS_COMMENTS1           VARCHAR2 := NULL,
    P_BILLDOCS_COMMENTS2           VARCHAR2 := NULL,
    P_BILLDOCS_COMMENTS3           VARCHAR2 := NULL,
    P_BILLDOCS_COMMENTS4           VARCHAR2 := NULL,
    P_BILLDOCS_MAIL_ATTENTION      VARCHAR2 := NULL,
    P_BILLDOCS_EFF_FROM_DATE       DATE     := NULL,
    P_BILLDOCS_EFF_TO_DATE         DATE     := NULL,
    P_LOCATION_ID                  NUMBER   := NULL,
    P_ADDRESS1                     VARCHAR2 := NULL,
    P_ADDRESS2                     VARCHAR2 := NULL,
    P_CITY                         VARCHAR2 := NULL,
    P_POSTAL_CODE                  VARCHAR2 := NULL,
    P_STATE                        VARCHAR2 := NULL,
    P_PROVINCE                     VARCHAR2 := NULL,
    P_COUNTY                       VARCHAR2 := NULL,
    P_COUNTRY                      VARCHAR2 := NULL
  ) RETURN XX_CRM_PAYMENT_TERMS_OBJ AS
  BEGIN
    RETURN XX_CRM_PAYMENT_TERMS_OBJ(
      AB_BILLING_FLAG              => P_AB_BILLING_FLAG,               
      PAYMENT_TERM                 => P_PAYMENT_TERM,                 
      PAYTERM_FREQUENCY            => P_PAYTERM_FREQUENCY,         
      PAYTERM_REPORTING_DAY        => P_PAYTERM_REPORTING_DAY,     
      PAYTERM_PERCENTAGE           => P_PAYTERM_PERCENTAGE,        
      BILLDOCS_DOC_TYPE            => P_BILLDOCS_DOC_TYPE,         
      BILLDOCS_DELIVERY_METH       => P_BILLDOCS_DELIVERY_METH,   
      BILLDOCS_SPECIAL_HANDLING    => P_BILLDOCS_SPECIAL_HANDLING,
      BILLDOCS_SIG_REQ             => P_BILLDOCS_SIG_REQ,         
      BILLDOCS_DIRECT_FLAG         => P_BILLDOCS_DIRECT_FLAG,     
      BILLDOCS_AUTO_REPRINT        => P_BILLDOCS_AUTO_REPRINT,    
      BILLDOCS_COMMENTS1           => P_BILLDOCS_COMMENTS1,       
      BILLDOCS_COMMENTS2           => P_BILLDOCS_COMMENTS2,       
      BILLDOCS_COMMENTS3           => P_BILLDOCS_COMMENTS3,       
      BILLDOCS_COMMENTS4           => P_BILLDOCS_COMMENTS4,       
      BILLDOCS_MAIL_ATTENTION      => P_BILLDOCS_MAIL_ATTENTION,  
      BILLDOCS_EFF_FROM_DATE       => P_BILLDOCS_EFF_FROM_DATE,   
      BILLDOCS_EFF_TO_DATE         => P_BILLDOCS_EFF_TO_DATE,    
      LOCATION_ID                  => P_LOCATION_ID,              
      ADDRESS1                     => P_ADDRESS1,                 
      ADDRESS2                     => P_ADDRESS2,                 
      CITY                         => P_CITY,                     
      POSTAL_CODE                  => P_POSTAL_CODE,              
      STATE                        => P_STATE,                    
      PROVINCE                     => P_PROVINCE,                 
      COUNTY                       => P_COUNTY,                   
      COUNTRY                      => P_COUNTRY                  
    );
  END create_object;
END; 
/
