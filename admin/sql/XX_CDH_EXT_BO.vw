--------------------------------------------------------
--  DDL for Type XX_CDH_EXT_BO
-------------------------------------------------------

  CREATE OR REPLACE TYPE xx_cdh_ext_bo AS OBJECT(
    orig_system                 VARCHAR2(30),
    orig_system_reference       VARCHAR2(255),  
    account_status              VARCHAR2(1),
    attr_group_type             VARCHAR2(30),
    attr_group_name             VARCHAR2(30),
    attributes_data_table       EGO_USER_ATTR_DATA_TABLE,
  STATIC FUNCTION create_object(
    p_orig_system            IN VARCHAR2 := NULL,
    p_orig_system_reference  IN VARCHAR2 := NULL,
    p_account_status         IN VARCHAR2 := NULL,
    p_attr_group_type        IN VARCHAR2 := NULL,
    p_attr_group_name        IN VARCHAR2 := NULL,
    p_attributes_data_table  IN EGO_USER_ATTR_DATA_TABLE := NULL
  ) RETURN xx_cdh_ext_bo
);
/
SHOW ERRORS;
CREATE OR REPLACE TYPE BODY xx_cdh_ext_bo AS
  STATIC FUNCTION create_object(
    p_orig_system             IN VARCHAR2 := NULL,
    p_orig_system_reference   IN VARCHAR2 := NULL,
    p_account_status          IN VARCHAR2 := NULL,
    p_attr_group_type         IN VARCHAR2 := NULL,
    p_attr_group_name         IN VARCHAR2 := NULL,
    p_attributes_data_table   IN EGO_USER_ATTR_DATA_TABLE := NULL
  ) RETURN xx_cdh_ext_bo AS
  BEGIN
    RETURN xx_cdh_ext_bo(
      orig_system            => p_orig_system,          
      orig_system_reference  => p_orig_system_reference,
      account_status         => p_account_status,       
      attr_group_type        => p_attr_group_type,      
      attr_group_name        => p_attr_group_name,     
      attributes_data_table  => p_attributes_data_table  
    );
  END create_object;
END;
/
SHOW ERRORS;
