--------------------------------------------------------
--  DDL for Type XX_CRM_EBILL_CONTACT_OBJ
-------------------------------------------------------
CREATE OR REPLACE TYPE BODY XX_CRM_EBILL_CONTACT_OBJ AS
  STATIC FUNCTION create_object(
    P_RESP_TYPE                    VARCHAR2 := NULL,
    P_CONTACT_POINT_ID             NUMBER   := NULL,
    P_SALUTATION                   VARCHAR2 := NULL,
    P_PARTY_ID                     NUMBER   := NULL,
    P_FIRST_NAME                   VARCHAR2 := NULL,
    P_LAST_NAME                    VARCHAR2 := NULL,
    P_JOB_TITLE                    VARCHAR2 := NULL,
    P_CONTACT_POINT_TYPE           VARCHAR2 := NULL,
    P_EMAIL_ADDRESS                VARCHAR2 := NULL,
    P_PHONE_LN_TYPE                VARCHAR2 := NULL,
    P_PHONE_LN_TYPE_DESC           VARCHAR2 := NULL,
    P_PHONE_COUNTRY_CODE           VARCHAR2 := NULL,
    P_PHONE_AREA_CODE              VARCHAR2 := NULL,
    P_PHONE_NUMBER                 VARCHAR2 := NULL,
    P_EXTENSION                    VARCHAR2 := NULL,
    P_PRIMARY_CONTACT_POINT        VARCHAR2 := NULL,
    P_PREFERRED_FLAG               VARCHAR2 := NULL
  ) RETURN XX_CRM_EBILL_CONTACT_OBJ AS
  BEGIN
    RETURN XX_CRM_EBILL_CONTACT_OBJ(
      RESP_TYPE                => P_RESP_TYPE,                 
      CONTACT_POINT_ID         => P_CONTACT_POINT_ID,         
      SALUTATION               => P_SALUTATION,            
      PARTY_ID                 => P_PARTY_ID,              
      FIRST_NAME               => P_FIRST_NAME,            
      LAST_NAME                => P_LAST_NAME,             
      JOB_TITLE                => P_JOB_TITLE,            
      CONTACT_POINT_TYPE       => P_CONTACT_POINT_TYPE,   
      EMAIL_ADDRESS            => P_EMAIL_ADDRESS,        
      PHONE_LN_TYPE            => P_PHONE_LN_TYPE,        
      PHONE_LN_TYPE_DESC       => P_PHONE_LN_TYPE_DESC,   
      PHONE_COUNTRY_CODE       => P_PHONE_COUNTRY_CODE,   
      PHONE_AREA_CODE          => P_PHONE_AREA_CODE,      
      PHONE_NUMBER             => P_PHONE_NUMBER,         
      EXTENSION                => P_EXTENSION,            
      PRIMARY_CONTACT_POINT    => P_PRIMARY_CONTACT_POINT,
      PREFERRED_FLAG           => P_PREFERRED_FLAG       
    );
  END create_object;
END; 
/
