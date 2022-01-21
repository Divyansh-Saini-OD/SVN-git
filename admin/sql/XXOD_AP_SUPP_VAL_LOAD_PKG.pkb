SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON                              
PROMPT Creating Package Body XXOD_AP_SUPP_VAL_LOAD_PKG
Prompt Program Exits If The Creation Is Not Successful
WHENEVER SQLERROR CONTINUE
create or replace 
PACKAGE BODY XXOD_AP_SUPP_VAL_LOAD_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XXOD_AP_SUPP_VAL_LOAD_PKG                        |
-- | Description      : This Program will do validations and load vendors to iface table from   |
-- |                    stagging table. And also does the post updates       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    14-JAN-2015   Madhu Bolli       Initial code                  |
-- |    1.1    14-JAN-2015   Amar Modium       Initial code                  |
-- |    1.2    02-Feb-2015   Madhu Bolli       Fixed the issues resulted in SIT |
-- |    1.3    06-Feb-2015   Paddy Sanjeevi    Added payment_method          |
-- |    1.4    10-Feb-2015   Paddy Sanjeevi    Modified for contacts         |
-- |    1.5    19-Feb-2015   Madhu Bolli       Corrected territory of add_layout() |
-- |    1.6    19-Feb-2015   Madhu Bolli       Corrected the population of attribute13 |
-- |    1.7    05-Mar-2015   Madhu Bolli       Corrected the length validation of SupplierName|
-- |                                             ,Addresss_line1 and Address_line2|
-- |    1.8    16-Nov-2016   Madhu Bolli       GSCC schema fix               |  
-- +=========================================================================+
AS

/*********************************************************************
    * Procedure used to log based on gb_debug value or if p_force is TRUE.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program log file.  Will prepend
    * timestamp to each message logged.  This is useful for determining
    * elapse times.
    *********************************************************************/
    PROCEDURE print_debug_msg(
        P_Message  In  Varchar2,
        p_force    IN  BOOLEAN DEFAULT FALSE)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    Begin

    
        IF (gc_debug = 'Y' OR p_force)
        Then
        Lc_Message :=P_Message;
        Fnd_File.Put_Line(Fnd_File.log,Lc_Message);
        -- Fnd_File.Put_Line(Fnd_File.out,Lc_Message);

     

            IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
            Then
                 DBMS_OUTPUT.put_line(lc_message);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_debug_msg;

/*********************************************************************
    * Procedure used to out the text to the concurrent program.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program output file.     
    *********************************************************************/
    PROCEDURE print_out_msg(
        P_Message  In  Varchar2)
    IS
        lc_message  VARCHAR2(4000) := NULL;
    Begin
        Lc_Message :=P_Message;
        Fnd_File.Put_Line(Fnd_File.output, Lc_Message);

        IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
        Then
            DBMS_OUTPUT.put_line(lc_message);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_out_msg;    

-- +============================================================================+
-- | Procedure Name : insert_error                                              |
-- |                                                                            |
-- | Description    : This procedure inserts error into the staging tables      |
-- |                                                                            |
-- |                                                                            |
-- | Parameters     : p_program_step             IN       VARCHAR2              |
-- |                  p_primary_key              IN       VARCHAR2              |
-- |                  p_error_code               IN       VARCHAR2              |
-- |                  p_error_message            IN       VARCHAR2              |
-- |                  p_stage_col1               IN       VARCHAR2              |
-- |                  p_stage_val1               IN       VARCHAR2              |
-- |                  p_stage_col2               IN       VARCHAR2              |
-- |                  p_stage_val2               IN       VARCHAR2              |
-- |                  p_stage_col3               IN       VARCHAR2              |
-- |                  p_stage_val3               IN       VARCHAR2              |
-- |                  p_stage_col4               IN       VARCHAR2              |
-- |                  p_stage_val4               IN       VARCHAR2              |
-- |                  p_stage_col5               IN       VARCHAR2              |
-- |                  p_stage_val5               IN       VARCHAR2              |
-- |                  p_table_name               IN       VARCHAR2              |
-- |                                                                            |
-- | Returns        : N/A                                                       |
-- |                                                                            |
-- +============================================================================+
PROCEDURE insert_error
  (
    p_program_step  IN VARCHAR2 ,
    p_primary_key   IN VARCHAR2 DEFAULT NULL ,
    p_error_code    IN VARCHAR2 ,
    p_error_message IN VARCHAR2 DEFAULT NULL ,
    p_stage_col1    IN VARCHAR2 ,
    p_stage_val1    IN VARCHAR2 ,
    p_stage_col2    IN VARCHAR2 DEFAULT NULL ,
    p_stage_val2    IN VARCHAR2 DEFAULT NULL ,
    p_stage_col3    IN VARCHAR2 DEFAULT NULL ,
    p_stage_val3    IN VARCHAR2 DEFAULT NULL ,
    p_stage_col4    IN VARCHAR2 DEFAULT NULL ,
    p_stage_val4    IN VARCHAR2 DEFAULT NULL ,
    p_stage_col5    IN VARCHAR2 DEFAULT NULL ,
    p_stage_val5    IN VARCHAR2 DEFAULT NULL ,
    p_table_name    IN VARCHAR2 )
                    IS
BEGIN
  --g_error_cnt := g_error_cnt + 1;
  gc_error_msg := gc_error_msg||' '||p_stage_col1||':'||p_stage_val1||':'||p_error_code||';';
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg ( 'Error in insert_error: ' || SQLERRM);
END insert_error;

  --+============================================================================+
  --| Name          : reset_stage_tables                                          |
  --| Description   : This procedure will delete all records from below 2 staging tables|
  --|                 XX_AP_SUPPLIER_STG and  XX_AP_SUPP_SITE_CONTACT_STG        |
  --|                                                                            |
  --| Parameters    :                                                            |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+
    PROCEDURE reset_stage_tables(x_ret_code OUT NUMBER
            ,x_return_status   OUT VARCHAR2
            ,x_err_buf OUT VARCHAR2
          )
    IS
      l_ret_code                    NUMBER;
      l_return_status                  VARCHAR2 (100);
      l_err_buff                    VARCHAR2 (4000);    
    BEGIN    
      print_debug_msg(p_message => 'BEGIN procedure reset_stage_tables()', p_force => true);
      
      l_ret_code   := 0;
      l_return_status := 'S';
      l_err_buff   := NULL;
      
      --===========================================================================
          -- Delete the records from Supplier staging table 'XX_AP_SUPPLIER_STG'
      --===========================================================================      
      BEGIN                                                               
      
        delete from XX_AP_SUPPLIER_STG;
        
         IF sql%notfound THEN
             print_debug_msg(p_message => 'No records deleted from table XX_AP_SUPPLIER_STG.'
                          , p_force => true);
         ELSIF sql%found THEN
            print_debug_msg(p_message => 'No. of records deleted from table XX_AP_SUPPLIER_STG is '||sql%rowcount
                          , p_force => true);
         END IF;      
      
      EXCEPTION
        WHEN OTHERS THEN
          l_ret_code   := 1;
          l_return_status := 'E';
          l_err_buff   := 'Exception when deleting Supplier Staging records'||SQLCODE||' - '||substr(SQLERRM, 1, 3500);
          
          return;              
      END;
      
      --==================================================================================
      -- Delete the records from Supplier Site staging table 'XX_AP_SUPP_SITE_CONTACT_STG'
      --==================================================================================        
      BEGIN
      
        delete from XX_AP_SUPP_SITE_CONTACT_STG;
        
         IF sql%notfound THEN
             print_debug_msg(p_message => 'No records deleted from table XX_AP_SUPP_SITE_CONTACT_STG.'
                          , p_force => true);
         ELSIF sql%found THEN
            print_debug_msg(p_message => 'No. of records deleted from table XX_AP_SUPP_SITE_CONTACT_STG is '||sql%rowcount
                          , p_force => true);
         END IF;
       
       EXCEPTION
       WHEN OTHERS THEN
          l_ret_code   := 1;
          l_return_status := 'E';
          l_err_buff   := 'Exception when deleting Supplier Site Staging records'||SQLCODE||' - '||substr(SQLERRM, 1, 3500);
          
          return;              
       END; 
       
       x_ret_code := l_ret_code;
       x_return_status := l_return_status;
       x_err_buf := l_err_buff;          
      
      print_debug_msg(p_message => 'END procedure reset_stage_tables()', p_force => true);

    END reset_stage_tables;

  
  --+============================================================================+
  --| Name          : set_step                                                   |
  --| Description   : This procedure will Set Step                               |
  --|                                                                            |
  --| Parameters    : p_step_name           IN   VARCHAR2                        |
  --|                                                                            |
  --| Returns       : N/A                                                        |
  --|                                                                            |
  --+============================================================================+
PROCEDURE set_step
  (
    p_step_name IN VARCHAR2 )
                IS
BEGIN
  print_debug_msg(p_message => p_step_name, p_force => true);
  gc_step := p_step_name;
END set_step;


-- +===================================================================+
-- | FUNCTION   : isAlpha                                              |
-- |                                                                   |
-- | DESCRIPTION: Checks if only Alpha in a string                     |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if junck character exists or not)           |
-- +===================================================================+
FUNCTION isAlpha(p_string IN VARCHAR2) RETURN BOOLEAN IS
  v_string         VARCHAR2(4000);
  v_out_string     VARCHAR2(4000) := NULL;

Begin
  v_string := LTRIM(RTRIM(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isAlpha() - p_string '||p_string
                                  ,p_force=> FALSE);
    SELECT LENGTH(TRIM(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ' ')))
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN FALSE;
  ELSE
     RETURN TRUE;
  END IF;

End isAlpha;

-- +===================================================================+
-- | FUNCTION   : isNumeric                                       |
-- |                                                                   |
-- | DESCRIPTION: Checks if only Numeric in a string              |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if numeric exists or not)             |
-- +===================================================================+
FUNCTION isNumeric(p_string IN VARCHAR2) RETURN BOOLEAN IS
  v_string         VARCHAR2(4000);
  v_out_string     VARCHAR2(4000) := NULL;

Begin
  v_string := LTRIM(RTRIM(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isNumeric() - p_string '||p_string
                                  ,p_force=> FALSE);
    SELECT LENGTH(TRIM(TRANSLATE(v_string, '0123456789', ' ')))
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN FALSE;
  ELSE
     RETURN TRUE;
  END IF;

End isNumeric;

-- +===================================================================+
-- | FUNCTION   : isAlphaNumeric                                       |
-- |                                                                   |
-- | DESCRIPTION: Checks if only AlphaNumeric in a string              |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if alpha numeric exists or not)             |
-- +===================================================================+
FUNCTION isAlphaNumeric(p_string IN VARCHAR2) RETURN BOOLEAN IS
  v_string         VARCHAR2(4000);
  v_out_string     VARCHAR2(4000) := NULL;

Begin
  v_string := LTRIM(RTRIM(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isAlphaNumeric() - p_string '||p_string
                                  ,p_force=> FALSE);
    SELECT LENGTH(TRIM(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' ')))
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN FALSE;
  ELSE
     RETURN TRUE;
  END IF;

End isAlphaNumeric;

-- +===================================================================+
-- | FUNCTION   : isPostalCode                                         |
-- |                                                                   |
-- | DESCRIPTION: Checks if only numeric and hypen(0) in a string      |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if only numeric and hypen(0) exists or not) |
-- +===================================================================+
FUNCTION isPostalCode(p_string IN VARCHAR2) RETURN BOOLEAN IS
  v_string         VARCHAR2(4000);
  v_out_string     VARCHAR2(4000) := NULL;

Begin
  v_string := LTRIM(RTRIM(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isPostalCode() - p_string '||p_string
                                  ,p_force=> FALSE);
    SELECT LENGTH(TRIM(TRANSLATE(v_string, '0123456789-', ' ')))
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN FALSE;
  ELSE
     RETURN TRUE;
  END IF;

End isPostalCode;

-- +===================================================================+
-- | FUNCTION   : find_special_chars                                   |
-- |                                                                   |
-- | DESCRIPTION: Checks if special chars exist in a string            |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Varchar (if junck character exists or not)           |
-- +===================================================================+

FUNCTION find_special_chars(p_string IN VARCHAR2) RETURN VARCHAR2 IS
  v_string         VARCHAR2(4000);
  v_char           VARCHAR2(1);
  v_out_string     VARCHAR2(4000) := NULL;

Begin
  v_string := LTRIM(RTRIM(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' find_special_chars() - p_string '||p_string
                                  ,p_force=> FALSE);
    SELECT LENGTH(TRIM(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' ')))
      INTO v_out_string
      FROM DUAL;
  EXCEPTION
    WHEN others THEN
      v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
     RETURN 'JUNK_CHARS_EXIST';
  ELSE
     RETURN v_string;
  END IF;

End Find_Special_Chars;

--+============================================================================+
--| Name          : validate_records                                           |
--| Description   : This procedure will Validate records in Staging tables     |
--|                                                                            |
--| Parameters    : x_val_records   OUT NUMBER                                 |
--|                 x_inval_records OUT NUMBER                                 |
--|                 x_return_status  OUT VARCHAR2                               |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE validate_records
  (
    x_val_records OUT NOCOPY   NUMBER ,
    x_inval_records OUT NOCOPY NUMBER ,
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)    
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
TYPE l_sup_tab
IS
  TABLE OF XX_AP_SUPPLIER_STG%ROWTYPE INDEX BY BINARY_INTEGER;
TYPE l_sup_site_and_contact_tab
IS
  TABLE OF XX_AP_SUPP_SITE_CONTACT_STG%ROWTYPE INDEX BY BINARY_INTEGER;
  
  l_supplier_type l_sup_tab;
  l_sup_site_and_contact l_sup_site_and_contact_tab;
  
  --=================================================================
  -- Cursor Declarations for Suppliers
  --=================================================================
  CURSOR c_supplier
  IS
     SELECT xas.*
       FROM XX_AP_SUPPLIER_STG xas
      WHERE xas.SUPP_PROCESS_FLAG IN (gn_process_status_inprocess)
        AND xas.request_id = fnd_global.conc_request_id;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================

  CURSOR c_supplier_site (c_supplier_name VARCHAR2) 
  IS
      SELECT xasc.*
      FROM XX_AP_SUPP_SITE_CONTACT_STG xasc
      WHERE xasc.SUPP_SITE_PROCESS_FLAG IN (gn_process_status_inprocess)
        AND xasc.request_id = fnd_global.conc_request_id
        AND TRIM(UPPER(xasc.SUPPLIER_NAME)) = c_supplier_name;

  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Staging table
  --=================================================================
  CURSOR c_dup_supplier_chk_stg
  IS
     SELECT TRIM(UPPER(xas.SUPPLIER_NAME)), COUNT(1)
       FROM XX_AP_SUPPLIER_STG xas
      WHERE xas.SUPP_PROCESS_FLAG IN (gn_process_status_inprocess)
        AND xas.request_id = fnd_global.conc_request_id
      GROUP BY TRIM(UPPER(xas.SUPPLIER_NAME))
       HAVING COUNT(1) >= 2;    

  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Interface table
  --=================================================================
  CURSOR c_dup_supplier_chk_int(c_supplier_name VARCHAR2)
  IS
     SELECT xasi.vendor_name, xasi.NUM_1099
       FROM AP_SUPPLIERS_INT xasi
      WHERE xasi.STATUS IN ('NEW')
        AND UPPER(vendor_name) = c_supplier_name;           

  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================

  CURSOR c_dup_supplier_chk (c_supplier_name VARCHAR2) 
  IS
      SELECT asa.vendor_name, asa.NUM_1099, asa.vendor_id, hp.party_id, hp.object_version_number
      FROM AP_SUPPLIERS asa, hz_parties hp
      WHERE asa.vendor_name = c_supplier_name
        AND hp.party_id = asa.party_id;


  --==========================================================================================
  -- Cursor Declarations for Supplier Type
  --==========================================================================================

  CURSOR c_sup_type_code (c_supplier_type VARCHAR2) 
  IS
      SELECT lookup_code
      FROM FND_LOOKUP_VALUES
      WHERE lookup_type = 'VENDOR TYPE'        
        AND trunc(sysdate) between trunc(start_date_active) and trunc(NVL(end_date_active, sysdate+1))
        AND meaning = c_supplier_type;              

  --==========================================================================================
  -- Cursor Declarations for Income Tax Type
  --==========================================================================================

  CURSOR c_income_tax_type (c_income_tax_type VARCHAR2) 
  IS
      SELECT count(1)
      FROM AP_INCOME_TAX_TYPES
      WHERE income_tax_type = c_income_tax_type        
        AND trunc(NVL(inactive_date, SYSDATE+1)) >= trunc(SYSDATE);

  --==========================================================================================
  -- Cursor Declarations for Country Code
  --==========================================================================================

  CURSOR c_get_country_code (c_country VARCHAR2) 
  IS
    SELECT territory_code
    FROM fnd_territories_tl
    WHERE territory_short_name = c_country
      AND LANGUAGE = USERENV ('LANG');

  --==========================================================================================
  -- Cursor Declarations for Operating Unit
  --==========================================================================================

  CURSOR c_operating_unit (c_oper_unit VARCHAR2) 
  IS
      SELECT organization_id
      FROM hr_operating_units
      WHERE name = c_oper_unit        
        AND sysdate between trunc(DATE_FROM) and trunc(NVL(DATE_TO,SYSDATE+1));

  --==========================================================================================
  -- Cursor Declarations for Supplier Site existence
  --==========================================================================================

  CURSOR c_sup_site_exist (c_vendor_id NUMBER
                          ,c_vendor_site_code VARCHAR2
                          ,c_address_line1 VARCHAR2
                          ,c_address_line2 VARCHAR2
                          ,c_city VARCHAR2
                          ,c_state VARCHAR2
                          ,c_province VARCHAR2
                          ,c_site_category VARCHAR2) 
  IS
    SELECT count(1) 
    FROM AP_SUPPLIER_SITES_ALL assa
    WHERE assa.vendor_id = c_vendor_id
      AND vendor_site_code like c_vendor_site_code
      AND ADDRESS_LINE1 = c_address_line1
      AND (ADDRESS_LINE2 IS NULL or ADDRESS_LINE2 = c_address_line2)
      AND CITY = c_city
      AND (STATE IS NULL or STATE = c_state)
      AND (PROVINCE IS NULL or PROVINCE = c_province)
      AND ATTRIBUTE8 = c_site_category; 

      
  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value
  --==========================================================================================

  CURSOR c_get_fnd_lookup_code (c_lookup_type VARCHAR2, c_lookup_meaning VARCHAR2, c_application_id NUMBER) 
  IS
      SELECT lookup_code
      FROM FND_LOOKUP_VALUES
      WHERE lookup_type = c_lookup_type        
        AND meaning = c_lookup_meaning
        AND SOURCE_LANG = 'US'
        AND view_application_id = c_application_id
        AND trunc(sysdate) between trunc(NVL(start_date_active, sysdate-1)) and trunc(NVL(end_date_active, sysdate+1));    

  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value count giving lookup code
  --==========================================================================================

  CURSOR c_get_fnd_lookup_code_cnt (c_lookup_type VARCHAR2, c_lookup_code VARCHAR2) 
  IS
      SELECT count(1)
      FROM FND_LOOKUP_VALUES
      WHERE lookup_type = c_lookup_type        
        AND lookup_code = c_lookup_code
        AND trunc(sysdate) between trunc(start_date_active) and trunc(NVL(end_date_active, sysdate+1));                         
                      
  --==========================================================================================
  -- Cursor Declarations to get Liability Account CCID
  --==========================================================================================

  CURSOR c_get_liability_acc (c_cons_segments VARCHAR2) 
  IS
      SELECT Code_Combination_Id, gcc.segment3 
      FROM gl_code_combinations gcc
      WHERE Gcc.Segment1||'.'||Gcc.Segment2||'.'||Gcc.Segment3||'.'||Gcc.Segment4||'.'||Gcc.Segment5||'.'||Gcc.Segment6||'.'||Gcc.Segment7 = c_cons_segments 
        AND gcc.enabled_flag='Y'
        AND gcc.ACCOUNT_TYPE = 'L';          

  --==========================================================================================
  -- Cursor Declarations to get Bill To Location Id
  --==========================================================================================

  CURSOR c_bill_to_location (c_bill_to_loc_code VARCHAR2) 
  IS
      SELECT LOCATION_ID
      FROM HR_LOCATIONS_ALL
      WHERE LOCATION_CODE = c_bill_to_loc_code
        AND BILL_TO_SITE_FLAG = 'Y'
        AND INACTIVE_DATE IS NULL or INACTIVE_DATE >= SYSDATE; 

  --==========================================================================================
  -- Cursor Declarations to get Ship To Location Id
  --==========================================================================================

  CURSOR c_ship_to_location (c_ship_to_loc_code VARCHAR2) 
  IS
      SELECT LOCATION_ID
      FROM HR_LOCATIONS_ALL
      WHERE LOCATION_CODE = c_ship_to_loc_code
        AND SHIP_TO_SITE_FLAG = 'Y'
        AND INACTIVE_DATE IS NULL or INACTIVE_DATE >= SYSDATE;                         

  --==========================================================================================
  -- Cursor Declarations to check the existence of Payment Method
  --==========================================================================================

  CURSOR c_pay_method_exist (c_pay_method VARCHAR2) 
  IS
      SELECT count(1) 
      FROM IBY_PAYMENT_METHODS_B
      WHERE payment_method_code = c_pay_method
        AND INACTIVE_DATE IS NULL or INACTIVE_DATE >= SYSDATE; 
      
  --==========================================================================================
  -- Cursor Declarations to get Tolerance Id
  --==========================================================================================

  CURSOR c_get_tolerance (c_tolerance_name VARCHAR2) 
  IS
      SELECT TOLERANCE_ID
      FROM AP_TOLERANCE_TEMPLATES
      WHERE TOLERANCE_NAME = c_tolerance_name; 
  
  --==========================================================================================
  -- Cursor Declarations to check the currency code existence
  --==========================================================================================

  CURSOR c_inv_curr_code_exist (c_currency_code VARCHAR2) 
  IS
      SELECT count(1)
      FROM fnd_currencies_vl
      WHERE currency_code = c_currency_code;

  --==========================================================================================
  -- Cursor Declarations to get Term ID
  --==========================================================================================

  CURSOR c_get_term_id (c_term_name VARCHAR2) 
  IS
      SELECT  TERM_ID
      FROM AP_TERMS_VL
      WHERE NAME = c_term_name
        AND ENABLED_FLAG = 'Y'
        AND trunc(sysdate) between trunc(NVL(start_date_active, SYSDATE-1)) and trunc(NVL(end_date_active, sysdate+1));     

  --==================================================================================================
  -- Cursor Declarations to check the existence of the Tax Reporting Site for the existed supplier
  --==================================================================================================

  CURSOR c_tax_rep_site_exist (c_vendor_id NUMBER) 
  IS
      SELECT  COUNT(1)
      FROM AP_SUPPLIER_SITES_ALL
      WHERE VENDOR_ID = c_vendor_id
        AND TAX_REPORTING_SITE_FLAG = 'Y';       

--==============================================================================
-- Cursor Declarations to get table statistics of Supplier Staging
--==============================================================================
      CURSOR c_sup_stats
      IS
          SELECT SUM(DECODE(SUPP_PROCESS_FLAG,2,1,0))    -- Eligible to Validate and Load
            ,SUM(DECODE(SUPP_PROCESS_FLAG,4,1,0))    -- Successfully Validated and Loaded
            ,SUM(DECODE(SUPP_PROCESS_FLAG,3,1,0))    -- Validated and Errored out
            ,SUM(DECODE(SUPP_PROCESS_FLAG,35,1,0))   -- Successfully Validated but not loaded
            ,SUM(DECODE(SUPP_PROCESS_FLAG,1,1,0))    -- Ready for Process
          FROM  XX_AP_SUPPLIER_STG
          WHERE  request_id = fnd_global.conc_request_id;

--==============================================================================
-- Cursor Declarations to get table statistics of Supplier Site Staging
--==============================================================================
      CURSOR c_sup_site_stats
      IS
          SELECT SUM(DECODE(SUPP_SITE_PROCESS_FLAG,2,1,0))    -- Eligible to Validate and Load
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,4,1,0))    -- Successfully Validated and Loaded
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,3,1,0))    -- Validated and Errored out
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,35,1,0))   -- Successfully Validated but not loaded
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,1,1,0))    -- Ready for Process
          FROM  XX_AP_SUPP_SITE_CONTACT_STG
          WHERE  request_id = fnd_global.conc_request_id;         

  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_msg_count   NUMBER        := 0;
  l_trans_count NUMBER        := 0;
  l_inval_records PLS_INTEGER := 0;
  l_val_records PLS_INTEGER   := 0;
  l_sup_idx PLS_INTEGER       := 0;
  l_sup_site_idx PLS_INTEGER  := 0;
  l_sup_cont_idx PLS_INTEGER  := 0;
  l_procedure     VARCHAR2 (30)   := 'VALIDATE_RECORDS';
  l_program_step  VARCHAR2 (100) := '';

  l_ret_code                    NUMBER;
  l_return_status               VARCHAR2 (100);
  l_err_buff                    VARCHAR2 (4000);
  l_sup_fail_site_depend        VARCHAR2(2000);   
  
  l_error_message VARCHAR2(4000) := '';
  
  l_site_country_code     VARCHAR2(15);
  l_sup_name        AP_SUPPLIERS.VENDOR_NAME%TYPE;  
  l_tax_payer_id        AP_SUPPLIERS.NUM_1099%TYPE;
  l_vendor_exist_flag     VARCHAR2(1) := 'N';
  l_vendor_id             NUMBER;
  l_party_id              NUMBER;
  l_obj_ver_no            NUMBER;
  
  l_sup_type_code AP_SUPPLIERS.vendor_type_lookup_code%TYPE;
  l_income_tax_type_cnt    NUMBER;
  l_org_id                 NUMBER;
  l_org_id_cnt             NUMBER;
  l_sup_site_exist_cnt     NUMBER;
  l_sup_site_create_flag   VARCHAR2(1) := 'N';
  l_site_code              VARCHAR2(40);
  l_address_purpose        VARCHAR2(10);
  l_terms_id               NUMBER;
  l_purchasing_site_flag   VARCHAR2(1);
  l_pay_site_flag          VARCHAR2(1);
  l_payment_method         IBY_PAYMENT_METHODS_B.PAYMENT_METHOD_CODE%TYPE;
  l_pay_group_code         AP_SUPPLIERS.PAY_GROUP_LOOKUP_CODE%TYPE;
  l_ship_to_location_id    NUMBER;
  l_bill_to_location_id    NUMBER;
  l_ccid                   NUMBER;
  l_cont_phone_num         VARCHAR2(20);
  l_org_type_code          FND_LOOKUP_VALUES.LOOKUP_CODE%TYPE;
  l_gcc_segment3           gl_code_combinations.segment3%TYPE;
  l_fob_code               FND_LOOKUP_VALUES.LOOKUP_CODE%TYPE;
  l_freight_terms_code     FND_LOOKUP_VALUES.LOOKUP_CODE%TYPE;
  l_pay_method_cnt         NUMBER;
  l_tolerance_id           NUMBER;
  l_tolerance_name         AP_TOLERANCE_TEMPLATES.TOLERANCE_NAME%TYPE;
  l_deduct_bank_chrg       VARCHAR2(5);
  l_inv_match_option       VARCHAR2(25);
  l_inv_cur_code           fnd_currencies_vl.currency_code%TYPE;
  l_inv_curr_code_cnt      NUMBER;
  l_pay_cur_code           fnd_currencies_vl.currency_code%TYPE;           
  l_payment_priority       NUMBER;
  l_pay_group              VARCHAR2(50);
  l_terms_code             AP_TERMS_VL.NAME%TYPE;
  l_terms_date_basis       VARCHAR2(30);
  l_terms_date_basis_code  FND_LOOKUP_VALUES.LOOKUP_CODE%TYPE;
  l_pay_date_basis         VARCHAR2(30);
  l_pay_date_basis_code    FND_LOOKUP_VALUES.LOOKUP_CODE%TYPE;
  l_always_disc_flag       VARCHAR2(5);
  l_primary_pay_flag       VARCHAR2(1);
  l_tax_rep_exist_cnt      NUMBER;
  l_update_it_rep_site     VARCHAR2(1);
  l_income_tax_rep_site_flag VARCHAR2(1);
  l_sup_site_fail          VARCHAR2(1);
  l_error_prefix           VARCHAR2(10);
  l_error_prefix_list      VARCHAR2(600);
  l_organization_type      VARCHAR2(50);

  l_site_cnt_for_sup        NUMBER;
  l_upd_cnt                 NUMBER := 0;
  l_stg_sup_name            AP_SUPPLIERS.VENDOR_NAME%TYPE;
  l_stg_sup_dup_cnt         NUMBER := 0;

  l_int_sup_name            AP_SUPPLIERS.VENDOR_NAME%TYPE;
  l_int_tax_payer_id        NUMBER := 0;
  l_upd_count               NUMBER;
  l_site_upd_cnt            NUMBER;

  l_ap_application_id       NUMBER := 200;
  l_po_application_id       NUMBER := 201;  
    
  -- Below variables used to validate Supplier Site Custom DFF
   v_DELIVERY_POLICY            VARCHAR2(50);                         
   v_MIN_PREPAID_CODE             VARCHAR2(50);         
   v_SUPPLIER_SHIP_TO             VARCHAR2(50);         
   v_INVENTORY_TYPE_CODE          VARCHAR2(50);         
   v_VERTICAL_MRKT_INDICATOR      VARCHAR2(50);         
   v_NEW_STORE_TERMS              VARCHAR2(50);         
   v_SEASONAL_TERMS               VARCHAR2(50);         
   v_EDI_852                      VARCHAR2(50);                 
   v_EDI_DISTRIBUTION             VARCHAR2(50);                 
   v_RTV_OPTION                   VARCHAR2(50);         
   v_RTV_FRT_PMT_METHOD           VARCHAR2(50);                 
   v_PAYMENT_FREQUENCY            VARCHAR2(50);                 
   v_OBSOLETE_ITEM                VARCHAR2(50);                 
   v_error_message              VARCHAR2(2000);
   v_error_flag                 VARCHAR2(1);     
  
      l_sup_eligible_cnt    NUMBER := 0;
      l_sup_val_load_cnt    NUMBER := 0;
      l_sup_error_cnt       NUMBER := 0;
      l_sup_val_not_load_cnt NUMBER := 0;
      l_sup_ready_process   NUMBER := 0;
      l_supsite_eligible_cnt NUMBER := 0;
      l_supsite_val_load_cnt NUMBER := 0;
      l_supsite_error_cnt    NUMBER := 0;
      l_supsite_val_not_load_cnt NUMBER := 0;
      l_supsite_ready_process   NUMBER := 0;    
  
BEGIN

  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults'
                  ,p_force=>TRUE);

  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag  := 'N';
  gc_error_site_status_flag := 'N';
  l_error_message            := NULL;
  gc_error_msg               := '';
  

  l_ret_code   := 0;
  l_return_status := 'S';
  l_err_buff   := NULL;  
  
  
  print_debug_msg(p_message=> l_program_step||': Opening Supplier Cursor'
                  ,p_force=>TRUE);    
  --====================================================================================
     -- Check and Update the Supplier staging table with error for the records where 
     -- supplier exists in Supplier Staging but no site exists in SupplierSite Staging table
  --====================================================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table if Supplier exists but no site exists in Supplier Site staging table', p_force => false);
  
    l_upd_cnt := 0;

    UPDATE XX_AP_SUPPLIER_STG xass
    SET  xass.SUPP_PROCESS_FLAG = gn_process_status_error
        ,xass.SUPP_ERROR_FLAG   = gc_process_error_flag
        ,xass.SUPP_ERROR_MSG = ' There is no Supplier Site in Staging table for this supplier'
    WHERE xass.SUPP_PROCESS_FLAG = gn_process_status_inprocess
      AND xass.request_id = fnd_global.conc_request_id
      AND NOT EXISTS  (
              SELECT 'SITE EXISTS FOR THIS SUPPLIER'          
              FROM XX_AP_SUPP_SITE_CONTACT_STG xasitestg
              WHERE xasitestg.SUPP_SITE_PROCESS_FLAG IN (gn_process_status_inprocess)
                AND xasitestg.request_id = fnd_global.conc_request_id
                AND TRIM(UPPER(NVL(xasitestg.supplier_name, -1))) = TRIM(UPPER(NVL(xass.supplier_name, -2)))
            ); 
               
      l_upd_cnt := SQL%ROWCOUNT;      
      print_debug_msg(p_message => 'Check and updated '||l_upd_cnt||' records as error in the supplier staging table as there is no site in supplier site staging table', p_force => false);           
  
  EXCEPTION
      WHEN OTHERS THEN
       l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
       print_debug_msg(p_message => 'ERROR: Updating the Staging table for Supplier Exists but no Site exits - '|| l_err_buff
                     , p_force => true);
       
       x_ret_code := '1';
       x_return_status := 'E';
       x_err_buf := l_err_buff;
       
       return;          
  END;   

    --====================================================================================
     -- Check and Update the Supplier Site staging table with error for the records where 
     -- supplier site exists in SupplierSite Staging but no Supplier exists in Supplier Staging table
  --====================================================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the SupplierSite staging table if SupplierSite exists but no Supplier exists in Supplier staging table', p_force => false);
  
    l_site_upd_cnt := 0;

    UPDATE XX_AP_SUPP_SITE_CONTACT_STG xasitestg
    SET  xasitestg.SUPP_SITE_PROCESS_FLAG = gn_process_status_error
        ,xasitestg.SUPP_SITE_ERROR_FLAG   = gc_process_error_flag
        ,xasitestg.SUPP_SITE_ERROR_MSG = 'There is no supplier exists in Supplier Staging table for this site.'
    WHERE xasitestg.SUPP_SITE_PROCESS_FLAG = gn_process_status_inprocess
      AND xasitestg.request_id = fnd_global.conc_request_id
      AND NOT EXISTS  (
              SELECT 'SUPPLIER EXISTS FOR THIS SITE'          
              FROM XX_AP_SUPPLIER_STG xass
              WHERE xass.SUPP_PROCESS_FLAG IN (gn_process_status_inprocess)
                AND xass.request_id = fnd_global.conc_request_id
                AND TRIM(UPPER(NVL(xass.supplier_name, -1))) = TRIM(UPPER(NVL(xasitestg.supplier_name, -2)))
            );
               
      l_site_upd_cnt := SQL%ROWCOUNT;      
      print_debug_msg(p_message => 'Check and updated '||l_site_upd_cnt||' records as error in the supplier site staging table as there is no supplier in supplier staging table', p_force => false);
      
  EXCEPTION
      WHEN OTHERS THEN
       l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
       print_debug_msg(p_message => 'ERROR: Updating the Supplier Site Staging table for SupplierSite Exists but no Supplier exits in Supplier Stage table - '|| l_err_buff
                     , p_force => true);
       
       x_ret_code := '1';
       x_return_status := 'E';
       x_err_buf := l_err_buff;
       
       return;          
  END;   
  
  print_debug_msg(p_message=> l_program_step||' : Doing the Duplicate Supplier Check in Staging table'
                                  ,p_force=> TRUE);
  OPEN c_dup_supplier_chk_stg;
  LOOP
    FETCH c_dup_supplier_chk_stg INTO l_stg_sup_name, l_stg_sup_dup_cnt;
    EXIT WHEN  c_dup_supplier_chk_stg%NOTFOUND;
  
    print_debug_msg(p_message=> l_program_step||' : ERROR: '||l_stg_sup_dup_cnt||' records exist for Supplier Name '||l_stg_sup_name||' in the staging table'
                                  ,p_force=> TRUE);

    l_upd_cnt := 0;                                
    UPDATE XX_AP_SUPPLIER_STG
    SET  SUPP_PROCESS_FLAG = gn_process_status_error
        ,SUPP_ERROR_FLAG   = gc_process_error_flag
        ,SUPP_ERROR_MSG = l_stg_sup_dup_cnt||' records exist for Supplier Name '||l_stg_sup_name||' in the staging table.' 
    WHERE TRIM(UPPER(supplier_name)) = l_stg_sup_name
      AND SUPP_PROCESS_FLAG = gn_process_status_inprocess
      AND request_id = gn_request_id;   
  
    l_upd_cnt := SQL%ROWCOUNT;
    
    print_debug_msg(p_message=> l_program_step||' : ERROR: Updated Error records count for Supplier Name '||l_stg_sup_name||' in the staging table is '||l_upd_cnt
                                  ,p_force=> TRUE);

    l_site_upd_cnt := 0;
    
    IF l_upd_cnt > 0 THEN
        
        print_debug_msg(p_message=> l_program_step||' : Updating Supplier Site records as Error bcoz of the duplicate Supplier Name '||l_stg_sup_name||' in the staging table'
                                  ,p_force=> TRUE);
                                  
        UPDATE XX_AP_SUPP_SITE_CONTACT_STG
        SET  SUPP_SITE_PROCESS_FLAG = gn_process_status_error
            ,SUPP_SITE_ERROR_FLAG = gc_process_error_flag
            ,SUPP_SITE_ERROR_MSG =  'ERROR: Duplicate Supplier for this Site in Staging Table' 
        WHERE TRIM(UPPER(supplier_name)) = l_stg_sup_name
          AND SUPP_SITE_PROCESS_FLAG = gn_process_status_inprocess
          AND request_id = gn_request_id;   
      
        l_site_upd_cnt := SQL%ROWCOUNT;
        
        print_debug_msg(p_message=> l_program_step||' : ERROR: Updated Error records count for Supplier Sites for the duplicate Supplier Name '||l_stg_sup_name||' in the staging table is '||l_site_upd_cnt
                                      ,p_force=> TRUE);
    END IF;
                                  
  
  END LOOP;
  CLOSE c_dup_supplier_chk_stg;
  
  --==============================================================
     -- Check and Update the staging table for the Duplicate sites
  --==============================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate Sites', p_force => false);
  
    l_site_upd_cnt := 0;
    UPDATE XX_AP_SUPP_SITE_CONTACT_STG xassc1
    set xassc1.SUPP_SITE_PROCESS_FLAG = gn_process_status_error
       ,xassc1.SUPP_SITE_ERROR_FLAG = gc_process_error_flag
       ,xassc1.SUPP_SITE_ERROR_MSG =  'ERROR: Duplicate Site in Staging Table'
    WHERE xassc1.SUPP_SITE_PROCESS_FLAG = gn_process_status_inprocess
      AND xassc1.request_id = fnd_global.conc_request_id
      AND 2 <=  (
              SELECT COUNT(1)          
              FROM XX_AP_SUPP_SITE_CONTACT_STG xassc2
              WHERE xassc2.SUPP_SITE_PROCESS_FLAG IN (gn_process_status_inprocess)
                AND xassc2.request_id = fnd_global.conc_request_id
                AND TRIM(UPPER(xassc2.supplier_name)) = TRIM(UPPER(xassc1.supplier_name))
                AND TRIM(UPPER(xassc2.address_name_prefix)) = TRIM(UPPER(xassc1.address_name_prefix))
                AND (TRIM(UPPER(xassc2.address_purpose)) = TRIM(UPPER(xassc1.address_purpose))
                   OR
                    (
                      (TRIM(UPPER(xassc2.address_purpose)) = 'BOTH' and (TRIM(UPPER(xassc1.address_purpose)) = 'PY' or TRIM(UPPER(xassc1.address_purpose)) = 'PR'))
                          OR
                      (TRIM(UPPER(xassc1.address_purpose)) = 'BOTH' and (TRIM(UPPER(xassc2.address_purpose)) = 'PY' or TRIM(UPPER(xassc2.address_purpose)) = 'PR')) 
                    )
                  )
                AND TRIM(UPPER(xassc2.ADDRESS_LINE1)) =  TRIM(UPPER(xassc1.ADDRESS_LINE1))
                AND TRIM(UPPER(NVL(xassc2.ADDRESS_LINE2, -1))) =  TRIM(UPPER(NVL(xassc1.ADDRESS_LINE2, -1)))
                AND TRIM(UPPER(xassc2.CITY)) =  TRIM(UPPER(xassc1.CITY))
                AND TRIM(UPPER(NVL(xassc2.STATE, -1))) = TRIM(UPPER(NVL(xassc1.STATE, -1)))
                AND TRIM(UPPER(NVL(xassc2.PROVINCE, -1))) = TRIM(UPPER(NVL(xassc1.PROVINCE, -1)))
                AND xassc2.site_category = xassc1.site_category
            );   
      l_site_upd_cnt := SQL%ROWCOUNT;      
      print_debug_msg(p_message => 'Check and updated '||l_site_upd_cnt||' records as error in the staging table for the Duplicate Sites', p_force => false);           
  
  EXCEPTION
      WHEN OTHERS THEN
       l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
       print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate Site in Staging table - '|| l_err_buff
                     , p_force => true);
       
       x_ret_code := '1';
       x_return_status := 'E';
       x_err_buf := l_err_buff;
       
       return;          
  END;
  
  --=====================================================================================
     -- Check and Update the contact Process Flag to '7' if all contact values are NULL
  --=====================================================================================
  BEGIN
    print_debug_msg(p_message => 'Check and Update the contact Process Flag to 7 if all contact values are NULL', p_force => false);
  
    l_site_upd_cnt := 0;
    
    UPDATE XX_AP_SUPP_SITE_CONTACT_STG xassc
    set xassc.CONT_PROCESS_FLAG = '7'
       ,xassc.CONT_ERROR_MSG =  'ALL contact values are NULL'
    WHERE xassc.SUPP_SITE_PROCESS_FLAG = gn_process_status_inprocess
      AND xassc.request_id = fnd_global.conc_request_id
      AND xassc.CONT_FIRST_NAME IS NULL   
      AND xassc.CONT_LAST_NAME IS NULL   
      AND xassc.CONT_ALTERNATE_NAME IS NULL   
      AND xassc.CONT_DEPARTMENT IS NULL   
      AND xassc.CONT_EMAIL_ADDRESS IS NULL  
      AND xassc.CONT_PHONE_AREA_CODE IS NULL   
      AND xassc.CONT_PHONE_NUMBER IS NULL   
      AND xassc.CONT_FAX_AREA_CODE IS NULL   
      AND xassc.CONT_FAX_NUMBER IS NULL   
      AND xassc.CONT_ADDRESS_NAME IS NULL;
        
      l_site_upd_cnt := SQL%ROWCOUNT;      
      print_debug_msg(p_message => 'Checked and Updated the contact Process Flag to 7 for '||l_site_upd_cnt||' records as all contact values are NULL for this site', p_force => false);         
  
  EXCEPTION
      WHEN OTHERS THEN
       l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
       print_debug_msg(p_message => 'ERROR-EXCEPTION: Updating when all contacts are NULL in Staging table - '|| l_err_buff
                     , p_force => true);
       
       x_ret_code := '1';
       x_return_status := 'E';
       x_err_buf := l_err_buff;
       
       return;          
  END;
             
  --==============================================================
    -- Start validation for each supplier
  --===========================================================              
  OPEN c_supplier;
  LOOP
    FETCH c_supplier BULK COLLECT INTO l_supplier_type;
    IF l_supplier_type.COUNT > 0 THEN
      set_step ('Start of Supplier Validations');
      FOR l_sup_idx IN l_supplier_type.FIRST .. l_supplier_type.LAST
      LOOP

        print_debug_msg(p_message=> l_program_step||': ------------ Validating Supplier('||l_supplier_type(l_sup_idx).SUPPLIER_NAME||') -------------------------' ,p_force=> TRUE);
        --==============================================================
        -- Initialize the Variable to N for Each Supplier
        --==============================================================
        gc_error_status_flag  := 'N';

        gc_step                 := 'SUPPLIER';
        l_error_message        := NULL;
        
        gc_error_msg            := '';
        l_vendor_exist_flag     := 'N';        
        l_sup_type_code         := NULL;
        l_tax_payer_id          := NULL;
        l_vendor_id             := NULL;
        l_party_id              := NULL;
        l_obj_ver_no            := NULL;
        l_sup_site_fail         := 'N';
        
        -- l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_inprocess;
        -- l_supplier_type (l_sup_idx).request_id := gn_request_id;

        
         --==============================================================
        -- Validation for Each Supplier
        --==============================================================       
        
        
            --==============================================================
            -- Validating the SUPPLIER NAME
            --==============================================================         
               IF l_supplier_type (l_sup_idx).SUPPLIER_NAME IS NULL
               THEN
                  gc_error_status_flag := 'Y';

                  print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier Name Cannot be NULL for the record '||l_sup_idx
                                  ,p_force=> TRUE);
                                                                                                 
                  insert_error (p_program_step                => gc_step
                               ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_error_code                  => 'XXOD_SUPPLIER_NAME_NULL'
                               ,p_error_message               => 'Supplier Name Cannot be NULL'
                               ,p_stage_col1                  => 'SUPPLIER_NAME'
                               ,p_stage_val1                  => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_stage_col2                  => 'VENDOR_NAME'
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_table
                               );
                  l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
                  l_supplier_type (l_sup_idx).SUPP_ERROR_FLAG   := gc_process_error_flag;
                  l_supplier_type (l_sup_idx).SUPP_ERROR_MSG    := 'Supplier Name Cannot be NULL for the record '||l_sup_idx;                                    
                  
                  -- Skip the validation of this iteration/this supplier
                  CONTINUE;
                  
               END IF;

               IF ((find_special_chars(l_supplier_type(l_sup_idx).SUPPLIER_NAME) = 'JUNK_CHARS_EXIST')
                  OR (length(l_supplier_type(l_sup_idx).SUPPLIER_NAME) > 30 )) 
               THEN
                  gc_error_status_flag := 'Y';

                  print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier Name'||l_supplier_type(l_sup_idx).SUPPLIER_NAME||' cannot contain junk characters and length must be less than 32'
                                  ,p_force=> TRUE);
                                                                                                 
                  insert_error (p_program_step                => gc_step
                               ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_error_code                  => 'XXOD_SUPPLIER_NAME_INVALID'
                               ,p_error_message               => 'Supplier Name'||l_supplier_type(l_sup_idx).SUPPLIER_NAME||' cannot contain junk characters and length must be less than 32'
                               ,p_stage_col1                  => 'SUPPLIER_NAME'
                               ,p_stage_val1                  => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_stage_col2                  => NULL
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_table
                               );
               END IF;

            --==============================================================
            -- Validating the Supplier - Tax Payer ID
            --==============================================================                  
              IF l_supplier_type(l_sup_idx).TAX_PAYER_ID IS NOT NULL THEN
                  IF ( NOT (isNumeric(l_supplier_type(l_sup_idx).TAX_PAYER_ID))
                    OR (length(l_supplier_type(l_sup_idx).TAX_PAYER_ID) <> 9))
                   THEN
                      gc_error_status_flag := 'Y';
    
                      print_debug_msg(p_message=> l_program_step||' : ERROR: '||l_supplier_type (l_sup_idx).TAX_PAYER_ID||' - Tax Payer Id should be numeric and must have 9 digits '
                                      ,p_force=> TRUE);
                                                                                                     
                      insert_error (p_program_step                => gc_step
                                   ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                   ,p_error_code                  => 'XXOD_TAX_PAYER_ID_INVALID'
                                   ,p_error_message               => 'Tax Payer Id should be numeric and must have 9 digits'
                                   ,p_stage_col1                  => 'TAX_PAYER_ID'
                                   ,p_stage_val1                  => l_supplier_type (l_sup_idx).TAX_PAYER_ID
                                   ,p_stage_col2                  => NULL
                                   ,p_stage_val2                  => NULL
                                   ,p_table_name                  => g_sup_table
                                   );
                   END IF;
               END IF;     -- IF l_supplier_type(l_sup_idx).TAX_PAYER_ID IS NOT NULL
               
                 
               --====================================================================
               -- If duplicate vendor name exist in staging table
               --====================================================================
               l_sup_name := NULL;
               OPEN c_dup_supplier_chk(TRIM(UPPER(l_supplier_type (l_sup_idx).supplier_name)));
               FETCH  c_dup_supplier_chk INTO l_sup_name, l_tax_payer_id, l_vendor_id, l_party_id, l_obj_ver_no;
               
               IF l_sup_name IS NULL         --   Supplier Matrix logic of 4c-1
               THEN

                    print_debug_msg(p_message=> l_program_step||' : Supplier Name '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' in system does not exist. So, create it after checking interface table.'
                                  ,p_force=> FALSE);               
               --   Below code for Supplier Matrix logic of 4c-9, 4c-10, 4c-11, 4c-12
               
                   l_int_sup_name := NULL;
                   l_int_tax_payer_id := NULL;
                   
                   OPEN c_dup_supplier_chk_int(TRIM(UPPER(l_supplier_type (l_sup_idx).supplier_name)));
                   FETCH c_dup_supplier_chk_int INTO l_int_sup_name, l_int_tax_payer_id;
                   CLOSE c_dup_supplier_chk_int;
                   
                   IF l_int_sup_name IS NULL THEN
                        l_supplier_type (l_sup_idx).create_flag := 'Y';
                        print_debug_msg(p_message=> l_program_step||' : Supplier Name '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' in interface does not exist. So, create it.'
                                  ,p_force=> FALSE); 
                   ELSE 
                      gc_error_status_flag := 'Y';
                      
                      print_debug_msg(p_message=> l_program_step||' : ERROR: XXOD_SUP_EXISTS_IN_INT : Suppiler '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' already exist in Interface table with tax payer id as '||l_int_tax_payer_id||' .' 
                                      ,p_force=> TRUE);
                                                
                      insert_error (p_program_step                => gc_step
                                   ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                   ,p_error_code                  => 'XXOD_SUP_EXISTS_IN_INT'
                                   ,p_error_message               => 'Suppiler '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' already exist in Interface table with tax payer id as '||l_int_tax_payer_id||' .'
                                   ,p_stage_col1                  => 'SUPPLIER_NAME'
                                   ,p_stage_val1                  => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                   ,p_stage_col2                  => NULL
                                   ,p_stage_val2                  => NULL
                                   ,p_table_name                  => g_sup_table
                                 );                                          
                   END IF;  
               ELSIF (l_tax_payer_id IS NULL AND  l_supplier_type (l_sup_idx).tax_payer_id IS NOT NULL) THEN
               
                    l_supplier_type (l_sup_idx).update_flag := 'Y';
                    l_vendor_exist_flag := 'Y';
                    l_supplier_type (l_sup_idx).vendor_id := l_vendor_id;
                    l_supplier_type (l_sup_idx).party_id := l_party_id;
                    l_supplier_type (l_sup_idx).OBJECT_VERSION_NO := l_obj_ver_no;

 
                    print_debug_msg(p_message=> l_program_step||' : Imported Tax Payer Id - '||l_supplier_type (l_sup_idx).TAX_PAYER_ID||' and System Tax Payer Id is NULL, so update TaxPayerId for this Supplier.'
                                  ,p_force=> FALSE);
                    print_debug_msg(p_message=> l_program_step||' l_supplier_type (l_sup_idx).update_flag - '||l_supplier_type (l_sup_idx).update_flag
                                  ,p_force=> FALSE); 
                    print_debug_msg(p_message=> l_program_step||' l_vendor_id - '||l_vendor_id
                                  ,p_force=> FALSE);                                   
                    print_debug_msg(p_message=> l_program_step||' l_party_id - '||l_party_id
                                  ,p_force=> FALSE);
                    print_debug_msg(p_message=> l_program_step||' l_obj_ver_no - '||l_obj_ver_no
                                  ,p_force=> FALSE);
                                  
               ELSIF ((l_tax_payer_id = l_supplier_type (l_sup_idx).tax_payer_id)    -- 4C-3, 4C-4, 4C-5
                      OR (l_tax_payer_id IS NOT NULL AND  l_supplier_type (l_sup_idx).tax_payer_id IS NULL)   -- 4C-6, 4C-7, 4C-8
                      )  
               THEN
                    l_vendor_exist_flag := 'Y';
                    l_supplier_type (l_sup_idx).vendor_id := l_vendor_id;
                    l_supplier_type (l_sup_idx).party_id := l_party_id;
                    l_supplier_type (l_sup_idx).OBJECT_VERSION_NO := l_obj_ver_no;
                                        
                    print_debug_msg(p_message=> l_program_step||' : Imported Tax Payer Id - '||l_supplier_type (l_sup_idx).TAX_PAYER_ID||' and System Tax Payer Id - '||l_tax_payer_id||' says Supplier already existed.'
                                  ,p_force=> FALSE);
                    print_debug_msg(p_message=> l_program_step||' l_vendor_id - '||l_vendor_id
                                  ,p_force=> FALSE);                                   
                    print_debug_msg(p_message=> l_program_step||' l_party_id - '||l_party_id
                                  ,p_force=> FALSE);
                    print_debug_msg(p_message=> l_program_step||' l_obj_ver_no - '||l_obj_ver_no
                                  ,p_force=> FALSE);                                                      
                               
               ELSIF  (l_tax_payer_id <> l_supplier_type (l_sup_idx).tax_payer_id)  THEN    --   Supplier Matrix logic of 4C-2
                  -- Throw the Error
                  
                  gc_error_status_flag := 'Y';
                  
                  print_debug_msg(p_message=> l_program_step||' : ERROR: Imported Tax Payer Id - '||l_supplier_type (l_sup_idx).TAX_PAYER_ID||' and System Tax Payer Id - '||l_tax_payer_id||' are different'
                                  ,p_force=> TRUE);
                                            
                  insert_error (p_program_step                => gc_step
                               ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_error_code                  => 'XXOD_TAX_PAYER_ID_DIFFER'
                               ,p_error_message               => 'Tax Payer Id in system and imported file are different for the same SUPPLIER NAME.'
                               ,p_stage_col1                  => 'TAX_PAYER_ID'
                               ,p_stage_val1                  => l_supplier_type (l_sup_idx).TAX_PAYER_ID
                               ,p_stage_col2                  => NULL
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_table
                               );
               ELSE
                  gc_error_status_flag := 'Y';
                  
                  print_debug_msg(p_message=> l_program_step||' : ERROR: Imported Tax Payer Id - '||l_supplier_type (l_sup_idx).TAX_PAYER_ID||' and System Tax Payer Id - '||l_tax_payer_id||'. This is a new case. Recheck this case.'
                                  ,p_force=> TRUE);
                                            
                  insert_error (p_program_step                => gc_step
                               ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_error_code                  => 'XXOD_TAX_PAYER_ID_NEWCASE'
                               ,p_error_message               => 'Imported Tax Payer Id - '||l_supplier_type (l_sup_idx).TAX_PAYER_ID||' and System Tax Payer Id - '||l_tax_payer_id||'. This is a new case. Recheck this case.'
                               ,p_stage_col1                  => 'TAX_PAYER_ID'
                               ,p_stage_val1                  => l_supplier_type (l_sup_idx).TAX_PAYER_ID
                               ,p_stage_col2                  => NULL
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_table
                               );               
                
               END IF;   -- l_sup_name IS NULL
               
               
                    
               CLOSE c_dup_supplier_chk; 
                
               l_update_it_rep_site := 'N';
                                     
               IF l_vendor_exist_flag = 'Y' THEN
                            
                  l_tax_rep_exist_cnt := 0;
                  
                  OPEN c_tax_rep_site_exist(l_vendor_id);
                  FETCH c_tax_rep_site_exist INTO l_tax_rep_exist_cnt;
                  CLOSE c_tax_rep_site_exist;
                            
                  print_debug_msg(p_message=> gc_step||'Income Tax Reporting Site flag exists '||l_tax_rep_exist_cnt||' times for this supplier'
                                            ,p_force=> FALSE);
                  
                  IF l_tax_rep_exist_cnt > 0 THEN
                      -- Update income_tax_rep_site = 'N' for all sites of this supplier
                      l_update_it_rep_site := 'Y';   -- This will allow to update the Income Tax Report Site flag to 'N' for all sites
                      print_debug_msg(p_message=> gc_step||'Income Tax Reporting Site flag already set for this Supplier'
                                            ,p_force=> FALSE);                               
                   END IF;                        
              END IF;

            --==============================================================
            -- Validating the Supplier - Tax Registration#
            --============================================================== 
            
              IF ( NOT isAlphaNumeric(l_supplier_type(l_sup_idx).TAX_REG_NUM))
               THEN
                  gc_error_status_flag := 'Y';
                  print_debug_msg(p_message=> gc_step||' ERROR: TAX_REG_NUM:'||l_supplier_type(l_sup_idx).TAX_REG_NUM||': XXOD_TAX_REG_NUM_INVALID:Tax Registration# should be alphanumeric'
                                  ,p_force=> TRUE);
                                                                                                 
                  insert_error (p_program_step                => gc_step
                               ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_error_code                  => 'XXOD_TAX_REG_NUM_INVALID'
                               ,p_error_message               => 'Tax Registration# should be alphanumeric'
                               ,p_stage_col1                  => 'TAX_REG_NUM'
                               ,p_stage_val1                  => l_supplier_type (l_sup_idx).TAX_REG_NUM
                               ,p_stage_col2                  => NULL
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_table
                               );
               END IF;            

            --====================================================================
            -- Validating the Supplier - Supplier Type  . Derive if it is not NULL
            --==================================================================== 
               l_sup_type_code := NULL;
               
               IF l_supplier_type (l_sup_idx).SUPPLIER_TYPE IS NULL
               THEN
                  gc_error_status_flag := 'Y';

                  print_debug_msg(p_message=> gc_step||' ERROR: SUPPLIER_TYPE:'||l_supplier_type (l_sup_idx).SUPPLIER_TYPE||': XXOD_SUPPLIER_TYPE_NULL:Supplier Type cannot be NULL'
                                  ,p_force=> TRUE);
                                                                                                 
                  insert_error (p_program_step                => gc_step
                               ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                               ,p_error_code                  => 'XXOD_SUPPLIER_TYPE_NULL'
                               ,p_error_message               => 'Supplier Type cannot be NULL'
                               ,p_stage_col1                  => 'SUPPLIER_TYPE'
                               ,p_stage_val1                  => l_supplier_type (l_sup_idx).SUPPLIER_TYPE
                               ,p_stage_col2                  => 'VENDOR_NAME'
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_table
                               );                  
               ELSE      -- Derive the Supplier Type Code
                  l_sup_type_code := NULL;
                  
                  OPEN c_sup_type_code(l_supplier_type (l_sup_idx).SUPPLIER_TYPE);
                  FETCH c_sup_type_code INTO l_sup_type_code;
                  CLOSE c_sup_type_code;
                  
                  IF l_sup_type_code IS NULL   THEN

                    gc_error_status_flag := 'Y';
                    print_debug_msg(p_message=> gc_step||' ERROR: SUPPLIER_TYPE:'||l_supplier_type (l_sup_idx).SUPPLIER_TYPE||': XXOD_SUPP_TYPE_INVALID: Supplier Type does not exist in System'
                                    ,p_force=> TRUE);
                                                                                                   
                    insert_error (p_program_step                => gc_step
                                 ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                 ,p_error_code                  => 'XXOD_SUPP_TYPE_INVALID'
                                 ,p_error_message               => 'Supplier Type does not exist in System'
                                 ,p_stage_col1                  => 'SUPPLIER_TYPE'
                                 ,p_stage_val1                  => l_supplier_type (l_sup_idx).SUPPLIER_TYPE
                                 ,p_stage_col2                  => NULL
                                 ,p_stage_val2                  => NULL
                                 ,p_table_name                  => g_sup_table
                                 ); 
                  ELSE
                      l_supplier_type (l_sup_idx).vendor_type_lookup_code := l_sup_type_code;
                    END IF;   -- IF l_sup_type_code IS NULL
                  END IF;     -- IF l_supplier_type (l_sup_idx).SUPPLIER_TYPE IS NULL

            --====================================================================
            -- Validating the Supplier - Customer Number
            --==================================================================== 
               IF (l_supplier_type(l_sup_idx).CUSTOMER_NUM IS NOT NULL) THEN
                   IF (NOT (isNumeric(l_supplier_type(l_sup_idx).CUSTOMER_NUM))) THEN
    
                        gc_error_status_flag := 'Y';
                        print_debug_msg(p_message=> gc_step||' ERROR: CUSTOMER_NUM:'||l_supplier_type (l_sup_idx).CUSTOMER_NUM||': XXOD_CUSTOMER_NUM_INVALID: Customer Number should be Numeric'
                                        ,p_force=> TRUE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_CUSTOMER_NUM_INVALID'
                                     ,p_error_message               => 'Customer Number should be Numeric'
                                     ,p_stage_col1                  => 'CUSTOMER_NUM'
                                     ,p_stage_val1                  => l_supplier_type (l_sup_idx).CUSTOMER_NUM
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     );                           
                   END IF;    -- IF (NOT (isNumeric(l_sup_site_type.CUSTOMER_NUM)))
               END IF; -- IF (l_supplier_type(l_sup_idx).CUSTOMER_NUM IS NOT NULL)
                                                 
            --====================================================================
            -- Validating the Supplier - Default the values
            --==================================================================== 
               IF l_supplier_type (l_sup_idx).ONE_TIME_FLAG IS NULL  THEN
                  l_supplier_type (l_sup_idx).ONE_TIME_FLAG := 'N';                            
               END IF;               

               IF l_supplier_type (l_sup_idx).FEDERAL_REPORTABLE_FLAG IS NULL  THEN
                  l_supplier_type (l_sup_idx).FEDERAL_REPORTABLE_FLAG := 'N';                            
               END IF; 

               IF l_supplier_type (l_sup_idx).STATE_REPORTABLE_FLAG IS NULL  THEN
                  l_supplier_type (l_sup_idx).STATE_REPORTABLE_FLAG := 'N';                            
               END IF;                                
                             
            --====================================================================
            -- Validating the Supplier - Income Tax Type
            --==================================================================== 
            
               IF l_supplier_type (l_sup_idx).FEDERAL_REPORTABLE_FLAG = 'Y'  THEN

                  IF l_supplier_type (l_sup_idx).INCOME_TAX_TYPE IS NULL
                   THEN
                      gc_error_status_flag := 'Y';
    
                      print_debug_msg(p_message=> gc_step||' ERROR: INCOME_TAX_TYPE:'||l_supplier_type (l_sup_idx).INCOME_TAX_TYPE||': XXOD_INCOME_TAX_TYPE_NULL:Income Tax Type cannot be NULL if the Federal Reportable Flag is Y.'
                                      ,p_force=> TRUE);
                                                                                                     
                      insert_error (p_program_step                => gc_step
                                   ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                   ,p_error_code                  => 'XXOD_INCOME_TAX_TYPE_NULL'
                                   ,p_error_message               => 'Income Tax Type cannot be NULL if the Federal Reportable Flag is Y'
                                   ,p_stage_col1                  => 'INCOME_TAX_TYPE'
                                   ,p_stage_val1                  => l_supplier_type (l_sup_idx).INCOME_TAX_TYPE
                                   ,p_stage_col2                  => NULL
                                   ,p_stage_val2                  => NULL
                                   ,p_table_name                  => g_sup_table
                                   );                  
                   ELSE      -- Derive the Income Tax Type Code
                      l_income_tax_type_cnt := 0;
                      
                      OPEN c_income_tax_type(l_supplier_type(l_sup_idx).INCOME_TAX_TYPE);
                      FETCH c_income_tax_type INTO l_income_tax_type_cnt;
                      CLOSE c_income_tax_type;
                      
                      IF l_income_tax_type_cnt < 1   THEN
                        gc_error_status_flag := 'Y';
                        print_debug_msg(p_message=> gc_step||' ERROR: INCOME_TAX_TYPE:'||l_supplier_type(l_sup_idx).INCOME_TAX_TYPE||': XXOD_INC_TAX_TYPE_INVALID: Income Tax Type does not exist in System'
                                        ,p_force=> TRUE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_INC_TAX_TYPE_INVALID'
                                     ,p_error_message               => 'Income Tax Type does not exist in System'
                                     ,p_stage_col1                  => 'INCOME_TAX_TYPE'
                                     ,p_stage_val1                  => l_supplier_type (l_sup_idx).INCOME_TAX_TYPE
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     ); 
                        END IF;   -- IF l_income_tax_type_code IS NULL
                      END IF;     -- IF l_supplier_type (l_sup_idx).INCOME_TAX_TYPE IS NULL                                                                             
               END IF;             
                 
              IF  gc_error_status_flag = 'Y'
               THEN                  
                  l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
                  l_supplier_type (l_sup_idx).SUPP_ERROR_FLAG   := gc_process_error_flag;
                  l_supplier_type (l_sup_idx).SUPP_ERROR_MSG    := gc_error_msg;                    
                  
                 print_debug_msg(p_message=> gc_step||' : Validation of Supplier '||l_supplier_type (l_sup_idx).supplier_name||  ' is failure'
                                        ,p_force=> TRUE);

                 print_debug_msg(p_message=> l_program_step||': ------------ Data Validation Failed Supplier('||l_supplier_type(l_sup_idx).SUPPLIER_NAME||') -------------------------' ,p_force=> TRUE);                                        
               ELSE
                  
                  l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_validated;   -- 35
                  print_debug_msg(p_message=> gc_step||' : Validation of Supplier '||l_supplier_type (l_sup_idx).supplier_name|| ' is success'
                                        ,p_force=> TRUE);
                  
                  print_debug_msg(p_message=> l_program_step||': ------------ Data Validation Success Supplier('||l_supplier_type(l_sup_idx).SUPPLIER_NAME||') -------------------------' ,p_force=> TRUE);
                                    
              END IF;
              
              
              -- IF VENDOR EXISTS THEN UPDATE THE COLUMN vendor_id, etc..,

               --====================================================================
               -- Call the Vendor Site Validations 
               --====================================================================
               set_step (   'Start of Vendor Site Loop Validations : '
                         || gc_error_status_flag);
               
               l_site_cnt_for_sup := 0; 
               l_error_prefix_list := NULL;
                              
               FOR l_sup_site_type IN c_supplier_site (TRIM(UPPER(l_supplier_type (l_sup_idx).SUPPLIER_NAME)))
               LOOP
                  print_debug_msg(p_message=> gc_step||' : Validation of Supplier Site started'
                                        ,p_force=> TRUE);
                                        
                  l_sup_site_idx :=   l_sup_site_idx + 1;
                  l_site_cnt_for_sup := l_site_cnt_for_sup + 1;
                  print_debug_msg(p_message=> gc_step||' : l_sup_site_idx - '||l_sup_site_idx
                                        ,p_force=> TRUE);
                  
                  gc_error_site_status_flag := 'N';
                  gc_step := 'SITE';
                  gc_error_msg := '';

            		  v_DELIVERY_POLICY            :=NULL;
            		  v_MIN_PREPAID_CODE           :=NULL;
            		  v_SUPPLIER_SHIP_TO           :=NULL;
            		  v_INVENTORY_TYPE_CODE        :=NULL;
            		  v_VERTICAL_MRKT_INDICATOR    :=NULL;
            	    v_NEW_STORE_TERMS            :=NULL;
            		  v_SEASONAL_TERMS             :=NULL;
            		  v_EDI_852                    :=NULL;
            		  v_EDI_DISTRIBUTION           :=NULL;
            		  v_RTV_OPTION                 :=NULL;
            		  v_RTV_FRT_PMT_METHOD         :=NULL;
            		  v_PAYMENT_FREQUENCY          :=NULL;
            		  v_OBSOLETE_ITEM              :=NULL;
  

                     --=============================================================================
                     -- Validating the Supplier Site - Reporting Name
                     --============================================================================= 
                     
                     IF l_sup_site_type.REPORTING_NAME IS NOT NULL  THEN               
                       IF ((find_special_chars(l_sup_site_type.REPORTING_NAME) = 'JUNK_CHARS_EXIST')
                          OR (length(l_sup_site_type.REPORTING_NAME) > 32 )) 
                       THEN
                          gc_error_site_status_flag := 'Y';


                                                              
                          print_debug_msg(p_message=> gc_step||' ERROR: REPORTING_NAME:'||l_sup_site_type.REPORTING_NAME||': XXOD_REPORTING_NAME_INVALID: Reporting Name cannot contain junk characters and length must be less than 32'
                                      ,p_force=> TRUE);

                                                                                                       
                          insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_REPORTING_NAME_INVALID'
                                       ,p_error_message               => 'Reporting Name '||l_sup_site_type.REPORTING_NAME||' cannot contain junk characters and length must be less than 32'
                                       ,p_stage_col1                  => 'REPORTING_NAME'
                                       ,p_stage_val1                  => l_sup_site_type.REPORTING_NAME
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       ); 
                          -- If it is first site record, then fail the Supplier also             

                          IF  l_site_cnt_for_sup = 1 THEN
                          
                              gc_error_status_flag := 'Y';
                              l_sup_fail_site_depend := l_sup_fail_site_depend||'Reporting Name of this supplier site is Invalid.';
                              
                              print_debug_msg(p_message=> gc_step||' ERROR: Supplier '||l_supplier_type(l_sup_idx).SUPPLIER_NAME||' is ERRORED due to this Reporting Name Invalid.'
                                      ,p_force=> TRUE);
                          END IF;
                          
                                                                 
                       ELSE
                          IF l_supplier_type(l_sup_idx).FEDERAL_REPORTABLE_FLAG = 'Y' THEN
                              -- Consider the value of first site record value to update in Supplier record
                              IF  l_site_cnt_for_sup = 1 THEN
                                
                                l_supplier_type(l_sup_idx).TAX_REPORTING_NAME := l_sup_site_type.REPORTING_NAME;
                                
                                print_debug_msg(p_message=> gc_step||' Assign the value - '||l_sup_site_type.REPORTING_NAME||' of Reporting Name to Supplier TAX_REPORTING_NAME.'
                                          ,p_force=> FALSE);
                              END IF;   -- IF  l_site_cnt_for_sup = 1
                          END IF;  -- IF l_supplier_type(l_sup_idx).FEDERAL_REPORTABLE_FLAG = 'Y'                                              
                       END IF;    -- IF ((find_special_chars(l_sup_site_type.REPORTING_NAME)
                     END IF;    -- IF l_sup_site_type.REPORTING_NAME IS NOT NULL
                     
                     --=============================================================================
                     -- Validating the Supplier Site - Verification Date
                     --=============================================================================
                      IF l_sup_site_type.VERFICATION_DATE IS NOT NULL and l_supplier_type(l_sup_idx).FEDERAL_REPORTABLE_FLAG = 'Y'  THEN                                           
                              -- Consider the value of first site record value to update in Supplier record
                              IF  l_site_cnt_for_sup = 1 THEN
                                l_supplier_type(l_sup_idx).TAX_VERIFICATION_DATE := l_sup_site_type.VERFICATION_DATE;
                                
                                print_debug_msg(p_message=> gc_step||' Assign the value - '||l_sup_site_type.VERFICATION_DATE||' of Verification Date to Supplier TAX_VERIFICATION_DATE.'
                                          ,p_force=> FALSE);
                              END IF;                                                                           
                       END IF;                        
                     
                     --=============================================================================
                     -- Validating the Supplier Site - Organization Type
                     --============================================================================= 
                      
                       print_debug_msg(p_message=> gc_step||' Organization type value is '||l_sup_site_type.ORGANIZATION_TYPE
                                          ,p_force=> FALSE);                      
                                          
                       IF l_sup_site_type.ORGANIZATION_TYPE IS NULL  THEN
                          l_organization_type := 'Individual';
                       ELSE
                          l_organization_type := l_sup_site_type.ORGANIZATION_TYPE;
                       END IF;
                       

                          l_org_type_code := NULL;
                          
                          OPEN c_get_fnd_lookup_code('ORGANIZATION TYPE', l_organization_type, l_po_application_id);
                          FETCH c_get_fnd_lookup_code INTO  l_org_type_code;
                          CLOSE c_get_fnd_lookup_code;
                          
                          IF l_org_type_code IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                                                                               
                            print_debug_msg(p_message=> gc_step||' ERROR: ORGANIZATION_TYPE:'||l_organization_type||': XXOD_ORGANIZATION_TYPE_INVALID: Organization Type does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_ORGANIZATION_TYPE_INVALID'
                                         ,p_error_message               => 'Organization Type '||l_organization_type||' does not exist in the system'
                                         ,p_stage_col1                  => 'ORGANIZATION_TYPE'
                                         ,p_stage_val1                  => l_organization_type
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 

                            -- If it is first site record, then fail the Supplier also 
                            IF  l_site_cnt_for_sup = 1 THEN
                            
                                gc_error_status_flag := 'Y';
                                l_sup_fail_site_depend := l_sup_fail_site_depend||';Orgainzation Type Code of this supplier site is Invalid.';
                                
                                print_debug_msg(p_message=> gc_step||' ERROR: Supplier '||l_supplier_type(l_sup_idx).SUPPLIER_NAME||' is ERRORED due to this Reporting Name Invalid.'
                                      ,p_force=> TRUE);                                
                            END IF;     
                                                                                                 
                            ELSE
                              print_debug_msg(p_message=> gc_step||' Organization Type Code of Organization Type - '||l_sup_site_type.ORGANIZATION_TYPE||' is '||l_org_type_code
                                          ,p_force=> FALSE);
                                          
                              -- Consider the value of first site record to update in Supplier record
                              IF  l_site_cnt_for_sup = 1 THEN
                                l_supplier_type(l_sup_idx).organization_type_lookup_code := l_org_type_code;
                              END IF;                               
                            END IF;   -- IF l_org_type_code IS NULL                   
             
               --====================================================================
               -- Validating the Supplier Site - Address Name Prefix
               --====================================================================
                                        
                  IF l_sup_site_type.ADDRESS_NAME_PREFIX IS NULL
                  THEN
                     gc_error_site_status_flag := 'Y';

                     print_debug_msg(p_message=> gc_step||' ERROR: ADDRESS_NAME_PREFIX:'||l_sup_site_type.ADDRESS_NAME_PREFIX||': XXOD_SITE_PREFIX_NULL:Vendor Site Prefix cannot be NULL'
                                    ,p_force=> FALSE);                     
                     insert_error (p_program_step                => gc_step
                                  ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                  ,p_error_code                  => 'XXOD_SITE_PREFIX_NULL'
                                  ,p_error_message               => 'Vendor Site Prefix cannot be NULL'
                                  ,p_stage_col1                  => 'ADDRESS_NAME_PREFIX'
                                  ,p_stage_val1                  => l_sup_site_type.ADDRESS_NAME_PREFIX
                                  ,p_table_name                  => g_sup_site_cont_table
                                  );
                  END IF; 

               --====================================================================
               -- Validating the Supplier Site - Address Purpose
               --====================================================================
                  l_purchasing_site_flag := NULL;
                  l_pay_site_flag :=  NULL;
                  IF l_sup_site_type.ADDRESS_PURPOSE IS NULL
                  THEN
                     gc_error_site_status_flag := 'Y';

                     print_debug_msg(p_message=> gc_step||' ERROR: ADDRESS_PURPOSE:'||l_sup_site_type.ADDRESS_PURPOSE||': XXOD_SITE_ADDR_PURPOSE_NULL:Vendor Site Address Purpose cannot be NULL'
                                    ,p_force=> FALSE);                     
                     insert_error (p_program_step                => gc_step
                                  ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                  ,p_error_code                  => 'XXOD_SITE_ADDR_PURPOSE_NULL'
                                  ,p_error_message               => 'Vendor Site Address Purpose cannot be NULL'
                                  ,p_stage_col1                  => 'ADDRESS_PURPOSE'
                                  ,p_stage_val1                  => l_sup_site_type.ADDRESS_PURPOSE
                                  ,p_table_name                  => g_sup_site_cont_table
                                  );

                  ELSIF UPPER(l_sup_site_type.ADDRESS_PURPOSE) = 'BOTH'   THEN
                      l_pay_site_flag := 'Y'; 
                      l_purchasing_site_flag := 'Y';
                       
                  ELSIF  UPPER(l_sup_site_type.ADDRESS_PURPOSE) = 'PY' THEN
                      l_pay_site_flag := 'Y';
                       
                  ELSIF  UPPER(l_sup_site_type.ADDRESS_PURPOSE) = 'PR' THEN
                      l_purchasing_site_flag := 'Y';
                  ELSE
                     gc_error_site_status_flag := 'Y';

                     print_debug_msg(p_message=> gc_step||' ERROR: ADDRESS_PURPOSE:'||l_sup_site_type.ADDRESS_PURPOSE||': XXOD_SITE_ADDR_PURPOSE_INVALID:Vendor Site Address Purpose is INVALID'
                                    ,p_force=> FALSE);                     
                     insert_error (p_program_step                => gc_step
                                  ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                  ,p_error_code                  => 'XXOD_SITE_ADDR_PURPOSE_INVALID'
                                  ,p_error_message               => 'Vendor Site Address Purpose is INVALID'
                                  ,p_stage_col1                  => 'ADDRESS_PURPOSE'
                                  ,p_stage_val1                  => l_sup_site_type.ADDRESS_PURPOSE
                                  ,p_table_name                  => g_sup_site_cont_table
                                  );                                    
                  END IF; 

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  Address Line 1
               --==============================================================================================================                  

                  IF l_sup_site_type.ADDRESS_LINE1 IS NULL
                  THEN
                     gc_error_site_status_flag := 'Y';

                     print_debug_msg(p_message=> gc_step||' ERROR: ADDRESS_LINE1:'||l_sup_site_type.ADDRESS_LINE1||': XXOD_SITE_ADDR_LINE1_NULL:Vendor Site Address Line 1 cannot be NULL'
                                    ,p_force=> FALSE);                     
                     insert_error (p_program_step                => gc_step
                                  ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                  ,p_error_code                  => 'XXOD_SITE_ADDR_LINE1_NULL'
                                  ,p_error_message               => 'Vendor Site Address Line 1 cannot be NULL'
                                  ,p_stage_col1                  => 'ADDRESS_LINE1'
                                  ,p_stage_val1                  => l_sup_site_type.ADDRESS_LINE1
                                  ,p_table_name                  => g_sup_site_cont_table
                                  );
                                  
                  ELSIF ((find_special_chars(l_sup_site_type.ADDRESS_LINE1) = 'JUNK_CHARS_EXIST')
                          OR (length(TRIM(l_sup_site_type.ADDRESS_LINE1)) > 38 )) 
                       THEN

                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_LINE1_INVALID: ADDRESS_LINE1:'||l_sup_site_type.ADDRESS_LINE1||' cannot contain junk characters and length must be less than 32'
                                      ,p_force=> FALSE);                     

                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_LINE1_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Line 1 cannot contain junk characters and length must be less than 32'
                                    ,p_stage_col1                  => 'ADDRESS_LINE1'
                                    ,p_stage_val1                  => l_sup_site_type.ADDRESS_LINE1
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );                                       
                  END IF; 

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  Address Line 2
               --==============================================================================================================                  

                  IF ((find_special_chars(l_sup_site_type.ADDRESS_LINE2) = 'JUNK_CHARS_EXIST')
                          OR (length(TRIM(l_sup_site_type.ADDRESS_LINE2)) > 38 )) 
                       THEN

                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_LINE2_INVALID: ADDRESS_LINE2:'||l_sup_site_type.ADDRESS_LINE2||' cannot contain junk characters and length must be less than 32'
                                      ,p_force=> FALSE);                     

                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_LINE2_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Line 2 cannot contain junk characters and length must be less than 32'
                                    ,p_stage_col1                  => 'ADDRESS_LINE2'
                                    ,p_stage_val1                  => l_sup_site_type.ADDRESS_LINE2
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );                                      
                  END IF;   

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  City
               --==============================================================================================================                  

                  IF l_sup_site_type.CITY IS NULL
                  THEN
                     gc_error_site_status_flag := 'Y';

                     print_debug_msg(p_message=> gc_step||' ERROR: CITY:'||l_sup_site_type.CITY||': XXOD_SITE_ADDR_CITY_NULL:Vendor Site Address Details City cannot be NULL'
                                    ,p_force=> FALSE);                     
                     insert_error (p_program_step                => gc_step
                                  ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                  ,p_error_code                  => 'XXOD_SITE_ADDR_CITY_NULL'
                                  ,p_error_message               => 'Vendor Site Address Details City cannot be NULL'
                                  ,p_stage_col1                  => 'CITY'
                                  ,p_stage_val1                  => l_sup_site_type.CITY
                                  ,p_table_name                  => g_sup_site_cont_table
                                  );
                                  
                  ELSIF ((find_special_chars(l_sup_site_type.CITY) = 'JUNK_CHARS_EXIST')
                          OR (length(TRIM(l_sup_site_type.CITY)) > 22 )) 
                       THEN

                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_CITY_INVALID: CITY:'||l_sup_site_type.CITY||' cannot contain junk characters and length must be less than 22'
                                      ,p_force=> FALSE);                     

                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                   => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_CITY_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Details - City - cannot contain junk characters and length must be less than 22'
                                    ,p_stage_col1                  => 'CITY'
                                    ,p_stage_val1                  => l_sup_site_type.CITY
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );                                  
                  END IF;                                                                                                          

               --==============================================================================================================
               -- Validating the Supplier Site - Country
               --============================================================================================================== 
                  l_site_country_code := NULL;                             
                  IF l_sup_site_type.COUNTRY IS NULL
                  THEN
                     l_site_country_code := gc_site_country_code;   -- US
                     l_sup_site_and_contact (l_sup_site_idx).country_code := gc_site_country_code;
                  ELSE
                     -- Derive this and assign
                     OPEN c_get_country_code(l_sup_site_type.COUNTRY);
                     FETCH c_get_country_code INTO l_site_country_code;
                     CLOSE c_get_country_code;
                     
                     IF l_site_country_code IS NOT NULL THEN
                        l_sup_site_and_contact (l_sup_site_idx).country_code := l_site_country_code;
                     ELSE
                       gc_error_site_status_flag := 'Y';
                       print_debug_msg(p_message=> gc_step||' ERROR: COUNTRY:'||l_sup_site_type.COUNTRY||': XXOD_SITE_COUNTRY_INVALID :Vendor Site Country is Invalid'
                                      ,p_force=> FALSE);                       
                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                   => l_sup_site_type.ADDRESS_NAME_PREFIX||'-'||l_sup_site_type.COUNTRY
                                    ,p_error_code                  => 'XXOD_SITE_COUNTRY_INVALID'
                                    ,p_error_message               => 'Vendor Site Country is Invalid'
                                    ,p_stage_col1                  => 'COUNTRY'
                                    ,p_stage_val1                  => l_sup_site_type.COUNTRY
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );                     
                     END IF;     -- IF l_site_country_code IS NOT NULL                    
                      
                  END IF;
                  
               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  State for US Country     and Province for Canada 
               --============================================================================================================== 

                  IF l_site_country_code = 'US' THEN
                 
                    IF l_sup_site_type.STATE IS NULL
                    THEN
                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: STATE:'||l_sup_site_type.STATE||': XXOD_SITE_ADDR_STATE_NULL:Vendor Site Address Details State cannot be NULL'
                                      ,p_force=> FALSE);                     
                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_STATE_NULL'
                                    ,p_error_message               => 'Vendor Site Address Details State cannot be NULL'
                                    ,p_stage_col1                  => 'STATE'
                                    ,p_stage_val1                  => l_sup_site_type.STATE
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );
                  ELSIF (NOT (isAlpha(l_sup_site_type.STATE))
                          OR (length(TRIM(l_sup_site_type.STATE)) <> 2 )) 
                       THEN

                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_STATE_INVALID: STATE:'||l_sup_site_type.STATE||' should contain only alpha characters and length must be equal to 2'
                                      ,p_force=> FALSE);                     

                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_STATE_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Details - STATE - should contain only alpha characters and length must be equal to 2'
                                    ,p_stage_col1                  => 'STATE'
                                    ,p_stage_val1                  => l_sup_site_type.STATE
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );    
                  ELSIF l_sup_site_type.PROVINCE IS NOT NULL THEN
                  
                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_PROVINCE_INVALID: PROVINCE:'||l_sup_site_type.PROVINCE||': should be NULL for the country '||l_sup_site_type.COUNTRY
                                      ,p_force=> FALSE);                     
                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_PROVINCE_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Details - Province - should be NULL for the country '||l_sup_site_type.COUNTRY
                                    ,p_stage_col1                  => 'PROVINCE'
                                    ,p_stage_val1                  => l_sup_site_type.PROVINCE
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );
                                           
                  END IF;   -- IF l_sup_site_type.STATE IS NULL   -- ??? Do we need to validate the State Code in Oracle Seeded table
                    
                  ELSIF l_site_country_code = 'CA' THEN
                    IF l_sup_site_type.PROVINCE IS NULL
                    THEN
                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: PROVINCE:'||l_sup_site_type.PROVINCE||': XXOD_SITE_ADDR_PROVINCE_NULL:Vendor Site Address Details - Province - cannot be NULL'
                                      ,p_force=> FALSE);                     
                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_PROVINCE_NULL'
                                    ,p_error_message               => 'Vendor Site Address Details - Province - cannot be NULL'
                                    ,p_stage_col1                  => 'PROVINCE'
                                    ,p_stage_val1                  => l_sup_site_type.PROVINCE
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );
                  ELSIF (NOT (isAlpha(l_sup_site_type.PROVINCE))
                          OR (length(TRIM(l_sup_site_type.PROVINCE)) <> 2 )) 
                       THEN

                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_PROVINCE_INVALID: PROVINCE:'||l_sup_site_type.PROVINCE||' should contain only alpha characters and length must be equal to 2'
                                      ,p_force=> FALSE);                     

                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_PROVINCE_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Details - PROVINCE - should contain only alpha characters and length must be equal to 2'
                                    ,p_stage_col1                  => 'PROVINCE'
                                    ,p_stage_val1                  => l_sup_site_type.PROVINCE
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );
                    ELSIF l_sup_site_type.STATE IS NOT NULL THEN
                  
                       gc_error_site_status_flag := 'Y';
  
                       print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_STATE_INVALID: STATE:'||l_sup_site_type.STATE||': should be NULL for the country '||l_sup_site_type.COUNTRY
                                      ,p_force=> FALSE);                     
                       insert_error (p_program_step                => gc_step
                                    ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                    ,p_error_code                  => 'XXOD_SITE_ADDR_STATE_INVALID'
                                    ,p_error_message               => 'Vendor Site Address Details - State - should be NULL for the country '||l_sup_site_type.COUNTRY
                                    ,p_stage_col1                  => 'STATE'
                                    ,p_stage_val1                  => l_sup_site_type.STATE
                                    ,p_table_name                  => g_sup_site_cont_table
                                    );                     
                    END IF;  -- IF l_sup_site_type.PROVINCE IS NULL      -- ??? Do we need to validate the State Code in Oracle Seeded table
                 ELSE                                  
                      gc_error_site_status_flag := 'Y';
                       print_debug_msg(p_message=> gc_step||' ERROR: thrown already - COUNTRY:'||l_sup_site_type.COUNTRY||': XXOD_SITE_COUNTRY_INVALID :Vendor Site Country is Invalid'
                                      ,p_force=> FALSE);
                 END IF;    -- IF IF l_sup_site_type.COUNTRY_CODE = 'US' --  IF l_sup_site_type.COUNTRY = 'United States' THEN
                 
               --==============================================================================================================
               -- Validating the Supplier Site - Operating Unit
               --============================================================================================================== 
                  l_org_id := NULL;                              
                  IF l_sup_site_type.OPERATING_UNIT IS NULL
                   THEN
                      gc_error_site_status_flag := 'Y';
    
                      print_debug_msg(p_message=> gc_step||' ERROR: OPERATING_UNIT:'||l_sup_site_type.OPERATING_UNIT||': XXOD_OPERATING_UNIT_NULL: Operating Unit cannot be NULL.'
                                      ,p_force=> TRUE);
                                                                                                     
                      insert_error (p_program_step                => gc_step
                                   ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                   ,p_error_code                  => 'XXOD_OPERATING_UNIT_NULL'
                                   ,p_error_message               => 'Operating Unit cannot be NULL'
                                   ,p_stage_col1                  => 'OPERATING_UNIT'
                                   ,p_stage_val1                  => l_sup_site_type.OPERATING_UNIT
                                   ,p_stage_col2                  => NULL
                                   ,p_stage_val2                  => NULL
                                   ,p_table_name                  => g_sup_table
                                   );                  
                   ELSE      -- Derive the Operating Unit
                      l_org_id := NULL;
                      
                      OPEN c_operating_unit(l_sup_site_type.OPERATING_UNIT);
                      FETCH c_operating_unit INTO  l_org_id;
                      CLOSE c_operating_unit;
                      
                      IF l_org_id IS NULL   THEN
                        gc_error_site_status_flag := 'Y';
                        
                        print_debug_msg(p_message=> gc_step||' ERROR: OPERATING_UNIT:'||l_sup_site_type.OPERATING_UNIT||': XXOD_OPERATING_UNIT_INVALID: Operating Unit does not exist in the system.'
                                      ,p_force=> TRUE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_OPERATING_UNIT_INVALID'
                                     ,p_error_message               => 'Operating Unit does not exist in the system'
                                     ,p_stage_col1                  => 'OPERATING_UNIT'
                                     ,p_stage_val1                  => l_sup_site_type.OPERATING_UNIT
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     ); 
                        ELSE
                          print_debug_msg(p_message=> gc_step||' Org Id of Operating Unit - '||l_sup_site_type.OPERATING_UNIT||' is '||l_org_id
                                      ,p_force=> FALSE);
                          l_sup_site_type.org_id := l_org_id;
                          
                        END IF;   -- IF l_org_id_cnt < 1
                    END IF;     -- IF l_sup_site_type.OPERATING_UNIT IS NULL 

                     --=============================================================================
                     -- Validating the Supplier Site - DFF - Supplier Site Header - Site Category 
                     --============================================================================= 
                      IF l_sup_site_type.SITE_CATEGORY IS NULL
                       THEN
                          gc_error_site_status_flag := 'Y';
        
                          print_debug_msg(p_message=> gc_step||' ERROR: SITE_CATEGORY:'||l_sup_site_type.SITE_CATEGORY||': XXOD_SITE_CATEGORY_NULL: Site Category cannot be NULL.'
                                          ,p_force=> TRUE);
                                                                                                         
                          insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_SITE_CATEGORY_NULL'
                                       ,p_error_message               => 'Site Category cannot be NULL'
                                       ,p_stage_col1                  => 'SITE_CATEGORY'
                                       ,p_stage_val1                  => l_sup_site_type.SITE_CATEGORY
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       );
                      END IF;     


                 --==============================================================================================================
                   -- Prepare the Site Code -  Prefix+%+Purpose
                   -- Validate the existed Supplier Site - Supplier Name, Site Code, Address Line1+Address Line2+City+State/Province
                 --==============================================================================================================
                    print_debug_msg(p_message=> gc_step||' After basic validation of site - gc_error_site_status_flag is '||gc_error_site_status_flag
                                                              ,p_force=> FALSE); 
                    l_sup_site_create_flag := 'N';
                    l_site_code := NULL;                                          
                    IF  gc_error_site_status_flag = 'N' THEN
                    
                      l_site_code := upper(l_sup_site_type.ADDRESS_NAME_PREFIX)||'%';
                      l_address_purpose := upper(l_sup_site_type.ADDRESS_PURPOSE);
                      
                      IF (l_address_purpose = 'PY' OR l_address_purpose = 'PR') THEN 
                            l_site_code := l_site_code||l_address_purpose;
                      END IF;
                      
                      print_debug_msg(p_message=> gc_step||' Prepared Site code - l_site_code - is '||l_site_code
                                                              ,p_force=> FALSE);                                       
                      print_debug_msg(p_message=> gc_step||' l_supplier_type(l_sup_idx).update_flag is '||l_supplier_type(l_sup_idx).update_flag
                                                              ,p_force=> FALSE);
                      print_debug_msg(p_message=> gc_step||' l_vendor_exist_flag is '||l_vendor_exist_flag
                                                              ,p_force=> FALSE);                                        
                    
                    
                        IF (l_supplier_type(l_sup_idx).update_flag = 'Y') or (l_vendor_exist_flag = 'Y') THEN

                            print_debug_msg(p_message=> gc_step||' l_supplier_type (l_sup_idx).vendor_id is '||l_supplier_type (l_sup_idx).vendor_id
                                                                    ,p_force=> FALSE);
                            print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.ADDRESS_LINE1) is '||upper(l_sup_site_type.ADDRESS_LINE1)
                                                                    ,p_force=> FALSE);
                            print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.ADDRESS_LINE2) is '||upper(l_sup_site_type.ADDRESS_LINE2)
                                                                    ,p_force=> FALSE);
                            print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.CITY) is '||upper(l_sup_site_type.CITY)
                                                                    ,p_force=> FALSE);
                            print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.STATE) is '||upper(l_sup_site_type.STATE)
                                                                    ,p_force=> FALSE);  
                            print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.PROVINCE) is '||upper(l_sup_site_type.PROVINCE)
                                                                    ,p_force=> FALSE);  
                            
                            l_sup_site_exist_cnt := 0;                                                                                                    
                            OPEN c_sup_site_exist(l_supplier_type (l_sup_idx).vendor_id
                                            ,l_site_code
                                            ,TRIM(upper(l_sup_site_type.ADDRESS_LINE1))
                                            ,TRIM(upper(l_sup_site_type.ADDRESS_LINE2))
                                            ,TRIM(upper(l_sup_site_type.CITY))
                                            ,TRIM(upper(l_sup_site_type.STATE))
                                            ,TRIM(upper(l_sup_site_type.PROVINCE))
                                            ,l_sup_site_type.SITE_CATEGORY
                                            );  
                            FETCH  c_sup_site_exist INTO l_sup_site_exist_cnt;
                            CLOSE c_sup_site_exist; 
                            
                            IF l_sup_site_exist_cnt > 0 THEN
                              gc_error_site_status_flag := 'Y';
                              
                              print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SUP_SITE_DUP : Supplier Site already existed in the system for the supplier '||l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                            ,p_force=> TRUE);
                                                                                                             
                              insert_error (p_program_step                => gc_step
                                           ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                           ,p_error_code                  => 'XXOD_SUP_SITE_DUP'
                                           ,p_error_message               => 'Supplier Site already existed in the system for the supplier '||l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                           ,p_stage_col1                  => 'SUPPLIER_NAME'
                                           ,p_stage_val1                  => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                           ,p_stage_col2                  => NULL
                                           ,p_stage_val2                  => NULL
                                           ,p_table_name                  => g_sup_table
                                           ); 
                                           
                                    
                            ELSE    -- IF l_sup_site_exist_cnt > 0 THEN
                              l_sup_site_create_flag := 'Y';
                            END IF;  -- IF l_sup_site_exist_cnt > 0 THEN
                        ELSE     -- IF (l_supplier_type(l_sup_idx).update_flag = 'Y') or (l_vendor_exist_flag = 'Y') THEN
                            l_sup_site_create_flag := 'Y';
                        END IF;   -- IF (l_supplier_type(l_sup_idx).update_flag = 'Y') or (l_vendor_exist_flag = 'Y') THEN
                    END IF;   -- IF  gc_error_site_status_flag = 'N' THEN         
                    
                    print_debug_msg(p_message=> gc_step||' After supplier site existence check - gc_error_site_status_flag is '||gc_error_site_status_flag
                                                              ,p_force=> FALSE);
                    print_debug_msg(p_message=> gc_step||' After supplier site existence check - l_sup_site_create_flag is '||l_sup_site_create_flag
                                                              ,p_force=> FALSE);
                                                              
                    set_step('Supplier Site Existence Check Completed'); 
                                       
                    IF  gc_error_site_status_flag = 'N'  THEN    -- After Supplier Site Existence Check Completed

                     --==============================================================================================================
                     -- Validating the Supplier Site - PostalCode
                     --============================================================================================================== 

                      IF l_sup_site_type.POSTAL_CODE IS NULL
                      THEN
                           gc_error_site_status_flag := 'Y';
      
                           print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.POSTAL_CODE||': XXOD_SITE_ADDR_POSTAL_CODE_NULL: Vendor Site Address Details - Postal Code - cannot be NULL'
                                          ,p_force=> FALSE);                     
                           insert_error (p_program_step                => gc_step
                                        ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                        ,p_error_code                  => 'XXOD_SITE_ADDR_POSTAL_CODE_NULL'
                                        ,p_error_message               => 'Vendor Site Address Details - Postal Code - cannot be NULL'
                                        ,p_stage_col1                  => 'POSTAL_CODE'
                                        ,p_stage_val1                  => l_sup_site_type.POSTAL_CODE
                                        ,p_table_name                  => g_sup_site_cont_table
                                        );
                      ELSE                         
                        IF l_site_country_code = 'US' THEN
                       
                          IF (NOT (isPostalCode(l_sup_site_type.POSTAL_CODE))
                                OR (length(l_sup_site_type.POSTAL_CODE) > 10 )) 
                             THEN
      
                             gc_error_site_status_flag := 'Y';
                             
                             print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.POSTAL_CODE||': XXOD_SITE_ADDR_POSTAL_CODE_INVA: For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10'
                                            ,p_force=> FALSE);                     
                             insert_error (p_program_step                => gc_step
                                          ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                          ,p_error_code                  => 'XXOD_SITE_ADDR_POSTAL_CODE_INVA'
                                          ,p_error_message               => 'For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10'
                                          ,p_stage_col1                  => 'POSTAL_CODE'
                                          ,p_stage_val1                  => l_sup_site_type.POSTAL_CODE
                                          ,p_table_name                  => g_sup_site_cont_table
                                          );                            
                                                 
                         END IF;   -- IF (NOT (isPostalCode(l_sup_site_type.POSTAL_CODE))
                          
                        ELSIF l_site_country_code = 'CA' THEN
                          IF (NOT (isAlphaNumeric(l_sup_site_type.POSTAL_CODE))) 
                               THEN
        
                             gc_error_site_status_flag := 'Y';
          
                             print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.POSTAL_CODE||': XXOD_SITE_ADDR_POSTAL_CODE_INVA: For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only alphanumeric '
                                            ,p_force=> FALSE);                     
                             insert_error (p_program_step                => gc_step
                                          ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                          ,p_error_code                  => 'XXOD_SITE_ADDR_POSTAL_CODE_INVA'
                                          ,p_error_message               => 'For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only alphanumeric'
                                          ,p_stage_col1                  => 'POSTAL_CODE'
                                          ,p_stage_val1                  => l_sup_site_type.POSTAL_CODE
                                          ,p_table_name                  => g_sup_site_cont_table
                                          );                   
                            END IF;  -- IF l_sup_site_type.PROVINCE IS NULL      -- ??? Do we need to validate the State Code in Oracle Seeded table
                        ELSE                                  
                            gc_error_site_status_flag := 'Y';
                             print_debug_msg(p_message=> gc_step||' ERROR: thrown already - COUNTRY:'||l_sup_site_type.COUNTRY||': XXOD_SITE_COUNTRY_INVALID :Vendor Site Country is Invalid'
                                            ,p_force=> FALSE);
                        END IF;    -- IF IF l_sup_site_type.COUNTRY_CODE = 'US'                    
                     END IF;   -- IF l_sup_site_type.POSTAL_CODE IS NULL    

                     
                     --=============================================================================
                     -- Validating the Supplier Site - Contact Directory - Department
                     --============================================================================= 
                      IF l_sup_site_type.CONT_DEPARTMENT IS NOT NULL and l_sup_site_type.CONT_DEPARTMENT <> 'PAYABLES'
                      THEN
                           gc_error_site_status_flag := 'Y';
                         
                           print_debug_msg(p_message=> gc_step||' ERROR: REPORTING_NAME:'||l_sup_site_type.CONT_DEPARTMENT||': XXOD_CONT_DEPARTMENT_INVALID: Department value must be PAYABLES if exists'
                                      ,p_force=> TRUE);
                                                                                                       
                           insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_CONT_DEPARTMENT_INVALID'
                                       ,p_error_message               => 'Department '||l_sup_site_type.CONT_DEPARTMENT||' must be PAYABLES if exists'
                                       ,p_stage_col1                  => 'CONT_DEPARTMENT'
                                       ,p_stage_val1                  => l_sup_site_type.CONT_DEPARTMENT
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       );                            
      
                      END IF;                       

                       --===============================================================================================
                       -- Validating the Supplier Site - Address Details - Phone area code
                       --=============================================================================================== 

                       IF l_sup_site_type.PHONE_AREA_CODE IS NOT NULL THEN
                          IF (NOT (isNumeric(l_sup_site_type.PHONE_AREA_CODE))
                            OR (length(l_sup_site_type.PHONE_AREA_CODE) <> 3 ))   THEN

                           gc_error_site_status_flag := 'Y';
                         
                           print_debug_msg(p_message=> gc_step||' ERROR: PHONE_AREA_CODE:'||l_sup_site_type.PHONE_AREA_CODE||': XXOD_PHONE_AREA_CODE_INVALID: Phone Area Code '||l_sup_site_type.PHONE_AREA_CODE||' should be numeric and 3 digits.'
                                      ,p_force=> TRUE);
                                                                                                       
                           insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_PHONE_AREA_CODE_INVALID'
                                       ,p_error_message               => 'Phone Area Code '||l_sup_site_type.PHONE_AREA_CODE||' should be numeric and 3 digits.'
                                       ,p_stage_col1                  => 'PHONE_AREA_CODE'
                                       ,p_stage_val1                  => l_sup_site_type.PHONE_AREA_CODE
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       ); 

                          END IF;    -- IF (NOT (isNumeric(l_sup_site_type.PHONE_AREA_CODE))
                        END IF;      -- IF l_sup_site_type.PHONE_AREA_CODE IS NOT NULL THEN

                       --===============================================================================================
                       -- Validating the Supplier Site - Address Details - Phone Number
                       --=============================================================================================== 
                       IF l_sup_site_type.PHONE_NUMBER IS NOT NULL THEN
                          IF (length(l_sup_site_type.PHONE_NUMBER) NOT IN (7,8) )   THEN     -- Phone Number length is 7 and 1 digit count for '-'

                           gc_error_site_status_flag := 'Y';
                         
                           print_debug_msg(p_message=> gc_step||' ERROR: PHONE_NUMBER:'||l_sup_site_type.PHONE_NUMBER||': XXOD_PHONE_NUMBER_INVALID: Phone Number '||l_sup_site_type.PHONE_NUMBER||' should be 7 digits.'
                                      ,p_force=> TRUE);
                                                                                                       
                           insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_PHONE_NUMBER_INVALID'
                                       ,p_error_message               => 'Phone Number '||l_sup_site_type.PHONE_NUMBER||' should be 7 digits.'
                                       ,p_stage_col1                  => 'PHONE_NUMBER'
                                       ,p_stage_val1                  => l_sup_site_type.PHONE_NUMBER
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       ); 

                          END IF;    -- IF (NOT (isNumeric(l_sup_site_type.PHONE_NUMBER))
                        END IF;      -- IF l_sup_site_type.PHONE_NUMBER IS NOT NULL THEN                       
                       --===============================================================================================
                       -- Validating the Supplier Site - Address Details - Fax area code
                       --=============================================================================================== 
                       IF l_sup_site_type.FAX_AREA_CODE IS NOT NULL THEN
                          IF (NOT (isNumeric(l_sup_site_type.FAX_AREA_CODE))
                            OR (length(l_sup_site_type.FAX_AREA_CODE) <> 3 ))   THEN

                           gc_error_site_status_flag := 'Y';
                         
                           print_debug_msg(p_message=> gc_step||' ERROR: FAX_AREA_CODE:'||l_sup_site_type.FAX_AREA_CODE||': XXOD_FAX_AREA_CODE_INVALID: Fax Area Code '||l_sup_site_type.FAX_AREA_CODE||' should be numeric and 3 digits.'
                                      ,p_force=> TRUE);
                                                                                                       
                           insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_FAX_AREA_CODE_INVALID'
                                       ,p_error_message               => 'Fax Area Code '||l_sup_site_type.FAX_AREA_CODE||' should be numeric and 3 digits.'
                                       ,p_stage_col1                  => 'FAX_AREA_CODE'
                                       ,p_stage_val1                  => l_sup_site_type.FAX_AREA_CODE
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       ); 

                          END IF;    -- IF (NOT (isNumeric(l_sup_site_type.FAX_AREA_CODE))
                        END IF;      -- IF l_sup_site_type.FAX_AREA_CODE IS NOT NULL THEN


                       --===============================================================================================
                       -- Validating the Supplier Site - Address Details - Fax Number
                       --===============================================================================================                        
                        IF l_sup_site_type.FAX_NUMBER IS NOT NULL THEN
                          IF (length(l_sup_site_type.FAX_NUMBER) NOT IN (7,8) )   THEN     -- Fax Number length is 7 and 1 digit count for '-'

                           gc_error_site_status_flag := 'Y';
                         
                           print_debug_msg(p_message=> gc_step||' ERROR: FAX_NUMBER:'||l_sup_site_type.FAX_NUMBER||': XXOD_FAX_NUMBER_INVALID: Fax Number '||l_sup_site_type.FAX_NUMBER||' should be 7 digits.'
                                      ,p_force=> TRUE);
                                                                                                       
                           insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_FAX_NUMBER_INVALID'
                                       ,p_error_message               => 'Fax Number '||l_sup_site_type.FAX_NUMBER||' should be 7 digits.'
                                       ,p_stage_col1                  => 'FAX_NUMBER'
                                       ,p_stage_val1                  => l_sup_site_type.FAX_NUMBER
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       ); 

                          END IF;    -- IF (NOT (isNumeric(l_sup_site_type.FAX_NUMBER))
                        END IF;      -- IF l_sup_site_type.FAX_NUMBER IS NOT NULL THEN                                               

                       --===============================================================================================
                       -- Validating the Supplier Site - CONTACT DIRECTORY - Phone area code
                       --=============================================================================================== 

                       IF l_sup_site_type.CONT_PHONE_AREA_CODE IS NOT NULL THEN
                          IF (NOT (isNumeric(l_sup_site_type.CONT_PHONE_AREA_CODE))
                            OR (length(l_sup_site_type.CONT_PHONE_AREA_CODE) <> 3 ))   THEN

                           gc_error_site_status_flag := 'Y';
                         
                           print_debug_msg(p_message=> gc_step||' ERROR: CONT_PHONE_AREA_CODE:'||l_sup_site_type.CONT_PHONE_AREA_CODE||': XXOD_CONT_PHONE_AREA_CODE_INV: Contact Directory Phone Area Code '||l_sup_site_type.CONT_PHONE_AREA_CODE||' should be numeric and 3 digits.'
                                      ,p_force=> TRUE);
                                                                                                       
                           insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_CONT_PHONE_AREA_CODE_INV'
                                       ,p_error_message               => 'Contact Directory Phone Area Code '||l_sup_site_type.CONT_PHONE_AREA_CODE||' should be numeric and 3 digits.'
                                       ,p_stage_col1                  => 'CONT_PHONE_AREA_CODE'
                                       ,p_stage_val1                  => l_sup_site_type.CONT_PHONE_AREA_CODE
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       ); 

                          END IF;    -- IF (NOT (isNumeric(l_sup_site_type.CONT_PHONE_AREA_CODE))
                        END IF;      -- IF l_sup_site_type.CONT_PHONE_AREA_CODE IS NOT NULL THEN

                       --===============================================================================================
                       -- Validating the Supplier Site - CONTACT DIRECTORY -  Last Name
                       --===============================================================================================
                       -- CONT_PROCESS_FLAG = 7 now, when all contact values are NULL
                       IF  (l_sup_site_type.CONT_PROCESS_FLAG IS NULL OR l_sup_site_type.CONT_PROCESS_FLAG <> '7') THEN
                       
                          IF (l_sup_site_type.CONT_LAST_NAME IS NULL) THEN
                             gc_error_site_status_flag := 'Y';
        
                             print_debug_msg(p_message=> gc_step||' ERROR: CONT_LAST_NAME:'||l_sup_site_type.CONT_LAST_NAME||': XXOD_SITE_CONT_LAST_NAME_NULL: Vendor Site Contact Details - Last Name - cannot be NULL'
                                            ,p_force=> FALSE);                     
                             insert_error (p_program_step                => gc_step
                                          ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                          ,p_error_code                  => 'XXOD_SITE_CONT_LAST_NAME_NULL'
                                          ,p_error_message               => 'Vendor Site Contact Details - Last Name - cannot be NULL'
                                          ,p_stage_col1                  => 'CONT_LAST_NAME'
                                          ,p_stage_val1                  => l_sup_site_type.CONT_LAST_NAME
                                          ,p_table_name                  => g_sup_site_cont_table
                                          );                          
                          END IF;                            

                         --===============================================================================================
                         -- Validating the Supplier Site - CONTACT DIRECTORY -  Phone Number and if NULL default to '9'
                         --===============================================================================================
                         
                         IF l_sup_site_type.CONT_PHONE_NUMBER IS NULL THEN
                              l_cont_phone_num := '9'; 
                         ELSE
                            IF (length(l_sup_site_type.CONT_PHONE_NUMBER) NOT IN (7,8)   -- Phone Number length is 7 and 1 digit count for '-'
                                AND l_sup_site_type.CONT_PHONE_NUMBER <> '9')  THEN    
  
                             gc_error_site_status_flag := 'Y';
                           
                             print_debug_msg(p_message=> gc_step||' ERROR: CONT_PHONE_NUMBER:'||l_sup_site_type.CONT_PHONE_NUMBER||': XXOD_CONT_PHONE_NUMBER_INVALID: Contact Directory  Phone Number '||l_sup_site_type.CONT_PHONE_NUMBER||' should be 7 digits.'
                                        ,p_force=> TRUE);
                                                                                                         
                             insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_CONT_PHONE_NUMBER_INVALID'
                                         ,p_error_message               => 'Contact Directory Phone Number '||l_sup_site_type.CONT_PHONE_NUMBER||' should be 7 digits.'
                                         ,p_stage_col1                  => 'CONT_PHONE_NUMBER'
                                         ,p_stage_val1                  => l_sup_site_type.CONT_PHONE_NUMBER
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
  
                            ELSE
                                l_cont_phone_num := l_sup_site_type.CONT_PHONE_NUMBER;
                            END IF;    -- IF (NOT (isNumeric(l_sup_site_type.CONT_PHONE_NUMBER))
                          END IF;      -- IF l_sup_site_type.CONT_PHONE_NUMBER IS NULL                       
                         --===============================================================================================
                         -- Validating the Supplier Site - CONTACT DIRECTORY - Fax area code
                         --=============================================================================================== 
                         IF l_sup_site_type.CONT_FAX_AREA_CODE IS NOT NULL THEN
                            IF (NOT (isNumeric(l_sup_site_type.CONT_FAX_AREA_CODE))
                              OR (length(l_sup_site_type.CONT_FAX_AREA_CODE) <> 3 ))   THEN
  
                             gc_error_site_status_flag := 'Y';
                           
                             print_debug_msg(p_message=> gc_step||' ERROR: CONT_FAX_AREA_CODE:'||l_sup_site_type.CONT_FAX_AREA_CODE||': XXOD_CONT_FAX_AREA_CODE_INVALID: Contact Directory Fax Area Code '||l_sup_site_type.CONT_FAX_AREA_CODE||' should be numeric and 3 digits.'
                                        ,p_force=> TRUE);
                                                                                                         
                             insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_CONT_FAX_AREA_CODE_INVALID'
                                         ,p_error_message               => 'Contact Directory Fax Area Code '||l_sup_site_type.CONT_FAX_AREA_CODE||' should be numeric and 3 digits.'
                                         ,p_stage_col1                  => 'CONT_FAX_AREA_CODE'
                                         ,p_stage_val1                  => l_sup_site_type.CONT_FAX_AREA_CODE
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
  
                            END IF;    -- IF (NOT (isNumeric(l_sup_site_type.CONT_FAX_AREA_CODE))
                          END IF;      -- IF l_sup_site_type.CONT_FAX_AREA_CODE IS NOT NULL THEN
  
  
                         --===============================================================================================
                         -- Validating the Supplier Site - CONTACT DIRECTORY - Fax Number
                         --===============================================================================================                        
                          IF l_sup_site_type.CONT_FAX_NUMBER IS NOT NULL THEN
                            IF (length(l_sup_site_type.CONT_FAX_NUMBER) NOT IN (7,8) )   THEN    -- Fax Number length is 7 and 1 digit count for '-'
  
                             gc_error_site_status_flag := 'Y';
                           
                             print_debug_msg(p_message=> gc_step||' ERROR: CONT_FAX_NUMBER:'||l_sup_site_type.CONT_FAX_NUMBER||': XXOD_CONT_FAX_NUMBER_INVALID: Contact Directory  Fax Number '||l_sup_site_type.CONT_FAX_NUMBER||' should be 7 digits.'
                                        ,p_force=> TRUE);
                                                                                                         
                             insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_CONT_FAX_NUMBER_INVALID'
                                         ,p_error_message               => ' Contact Directory Fax Number '||l_sup_site_type.CONT_FAX_NUMBER||' should be 7 digits.'
                                         ,p_stage_col1                  => 'CONT_FAX_NUMBER'
                                         ,p_stage_val1                  => l_sup_site_type.CONT_FAX_NUMBER
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
  
                            END IF;    -- IF (NOT (isNumeric(l_sup_site_type.CONT_FAX_NUMBER))
                          END IF;      -- IF l_sup_site_type.CONT_FAX_NUMBER IS NOT NULL THEN   
                     
                       END IF; -- IF  (l_sup_site_type.CONT_PROCESS_FLAG IS NULL OR l_sup_site_type.CONT_PROCESS_FLAG <> '7')                                                            

                     --=============================================================================
                     -- Validating the Supplier Site - Liability Account
                     --============================================================================= 
                      IF l_sup_site_type.LIABILITY_ACCOUNT IS NULL
                       THEN
                          gc_error_site_status_flag := 'Y';
        
                          print_debug_msg(p_message=> gc_step||' ERROR: LIABILITY_ACCOUNT:'||l_sup_site_type.LIABILITY_ACCOUNT||': XXOD_LIABILITY_ACCOUNT_NULL: Liability Account cannot be NULL.'
                                          ,p_force=> TRUE);
                                                                                                         
                          insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_LIABILITY_ACCOUNT_NULL'
                                       ,p_error_message               => 'Liability Account cannot be NULL'
                                       ,p_stage_col1                  => 'LIABILITY_ACCOUNT'
                                       ,p_stage_val1                  => l_sup_site_type.LIABILITY_ACCOUNT
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       );                  
                       ELSE      -- Derive the Liability Account CCID
                          l_ccid := NULL;
                          l_gcc_segment3 := NULL;
                          
                          OPEN c_get_liability_acc(l_sup_site_type.LIABILITY_ACCOUNT);
                          FETCH c_get_liability_acc INTO  l_ccid, l_gcc_segment3;
                          CLOSE c_get_liability_acc;
                          
                          IF l_ccid IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: LIABILITY_ACCOUNT:'||l_sup_site_type.LIABILITY_ACCOUNT||': XXOD_LIABILITY_ACCOUNT_INVALID: Liability Account does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_LIABILITY_ACCOUNT_INVALID'
                                         ,p_error_message               => 'Liability Account '||l_sup_site_type.LIABILITY_ACCOUNT||' does not exist in the system'
                                         ,p_stage_col1                  => 'LIABILITY_ACCOUNT'
                                         ,p_stage_val1                  => l_sup_site_type.LIABILITY_ACCOUNT
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
                            ELSE
                              print_debug_msg(p_message=> gc_step||' Code Combination Id of Liability Account - '||l_sup_site_type.LIABILITY_ACCOUNT||' is '||l_ccid
                                          ,p_force=> FALSE);
                              l_sup_site_type.CCID := l_ccid;
                              
                            END IF;   -- IF l_ccid < 1
                        END IF;     -- IF l_sup_site_type.LIABILITY_ACCOUNT IS NULL
                               

                     --=============================================================================
                     -- Validating the Supplier Site - Income Tax Reporting Site
                     --=============================================================================                      
                        -- Do the validation for New Suppliers and if existed Supplier doesn't have sites with tax_reporting_site_flag = 'Y'
                        
                        l_income_tax_rep_site_flag := 'N';
                        
                        IF l_update_it_rep_site = 'Y' THEN
                            l_income_tax_rep_site_flag := 'N';
                        ELSE
                            l_income_tax_rep_site_flag :=  l_sup_site_type.INCOME_TAX_REP_SITE;

                            IF (l_sup_site_type.INCOME_TAX_REP_SITE = 'Y' 
                              and  l_supplier_type(l_sup_idx).FEDERAL_REPORTABLE_FLAG <> 'Y')
                            THEN
                                gc_error_site_status_flag := 'Y';                            
                                print_debug_msg(p_message=> gc_step||' ERROR: INCOME_TAX_REP_SITE:'||l_sup_site_type.INCOME_TAX_REP_SITE||': XXOD_INCOME_TAX_REP_SITE_INVALID: Federal Reportable flag must be Y if the Income Tax Reporting Site.'
                                              ,p_force=> TRUE);
                                                                                                               
                                insert_error (p_program_step                => gc_step
                                             ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                             ,p_error_code                  => 'XXOD_INCOME_TAX_REP_SITE_INVALID'
                                             ,p_error_message               => 'Income Tax Reporting Site '||l_sup_site_type.INCOME_TAX_REP_SITE||' must be Y if Federal Reportable flag is Y.'
                                             ,p_stage_col1                  => 'INCOME_TAX_REP_SITE'
                                             ,p_stage_val1                  => l_sup_site_type.INCOME_TAX_REP_SITE
                                             ,p_stage_col2                  => NULL
                                             ,p_stage_val2                  => NULL
                                             ,p_table_name                  => g_sup_site_cont_table
                                             ); 
                            END IF;                            
                        END IF;                        

                     --=============================================================================
                     -- Validating the Supplier Site - Ship to Location Code
                     --=============================================================================
                      
                    IF l_sup_site_type.SHIP_TO_LOCATION IS NOT NULL THEN                    
                      l_ship_to_location_id := NULL;
                      OPEN c_ship_to_location(l_sup_site_type.SHIP_TO_LOCATION);
                      FETCH c_ship_to_location INTO l_ship_to_location_id;
                      CLOSE c_ship_to_location;
  
                      IF l_ship_to_location_id IS NULL  THEN
                              gc_error_site_status_flag := 'Y';
                              
                              print_debug_msg(p_message=> gc_step||' ERROR: SHIP_TO_LOCATION:'||l_sup_site_type.SHIP_TO_LOCATION||': XXOD_SHIP_TO_LOCATION_INVALID2: Ship to Location does not exist in the system.'
                                            ,p_force=> TRUE);
                                                                                                             
                              insert_error (p_program_step                => gc_step
                                           ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                           ,p_error_code                  => 'XXOD_SHIP_TO_LOCATION_INVALID2'
                                           ,p_error_message               => 'Ship to Location '||l_sup_site_type.SHIP_TO_LOCATION||' does not exist in the system'
                                           ,p_stage_col1                  => 'SHIP_TO_LOCATION'
                                           ,p_stage_val1                  => l_sup_site_type.SHIP_TO_LOCATION
                                           ,p_stage_col2                  => NULL
                                           ,p_stage_val2                  => NULL
                                           ,p_table_name                  => g_sup_site_cont_table
                                           ); 
                     ELSE
                        print_debug_msg(p_message=> gc_step||' Ship to Location Id is - '||l_sup_site_type.SHIP_TO_LOCATION||' is '||l_ship_to_location_id
                                       ,p_force=> FALSE);
                               
                     END IF;   -- IF l_ship_to_location_id IS NULL 
                   END IF;  --  IF SHIP_TO_LOCATION IS NOT NULL THEN                     
                                                            
                     --=============================================================================
                     -- Validating the Supplier Site - Bill to Location Code
                     --============================================================================= 
                     
                    IF l_gcc_segment3 in ('20101000' , '20114000') THEN
                        IF l_sup_site_type.BILL_TO_LOCATION <> 'OFFICE DEPOT TRADE PAYABLES' THEN
                            gc_error_site_status_flag := 'Y';                            
                            print_debug_msg(p_message=> gc_step||' ERROR: BILL_TO_LOCATION:'||l_sup_site_type.BILL_TO_LOCATION||': XXOD_BILL_TO_LOCATION_INVALID: Bill to Location code must be OFFICE DEPOT TRADE PAYABLES for the Trade Liability Accounts.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_BILL_TO_LOCATION_INVALID'
                                         ,p_error_message               => 'Bill To Location Code '||l_sup_site_type.BILL_TO_LOCATION||' must be OFFICE DEPOT TRADE PAYABLES for the Trade Liability Accounts.'
                                         ,p_stage_col1                  => 'BILL_TO_LOCATION'
                                         ,p_stage_val1                  => l_sup_site_type.BILL_TO_LOCATION
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
                        END IF;
                    ELSIF l_gcc_segment3 = '20204000' THEN                           
                        IF l_sup_site_type.BILL_TO_LOCATION <> 'OFFICE DEPOT NON-TRADE PAYABLES' THEN
                            gc_error_site_status_flag := 'Y';                            
                            print_debug_msg(p_message=> gc_step||' ERROR: BILL_TO_LOCATION:'||l_sup_site_type.BILL_TO_LOCATION||': XXOD_BILL_TO_LOCATION_INVALID: Bill to Location code must be OFFICE DEPOT NON-TRADE PAYABLES for the Expense Liability Accounts.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_BILL_TO_LOCATION_INVALID'
                                         ,p_error_message               => 'Bill To Location Code '||l_sup_site_type.BILL_TO_LOCATION||' must be OFFICE DEPOT NON-TRADE PAYABLES for the Expense Liability Accounts.'
                                         ,p_stage_col1                  => 'BILL_TO_LOCATION'
                                         ,p_stage_val1                  => l_sup_site_type.BILL_TO_LOCATION
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
                        END IF;                                                        
                    END IF;
                    
                    
                    IF l_gcc_segment3 in ('20101000' , '20114000', '20204000') THEN                    
                      l_bill_to_location_id := NULL;
                      OPEN c_bill_to_location(l_sup_site_type.BILL_TO_LOCATION);
                      FETCH c_bill_to_location INTO l_bill_to_location_id;
                      CLOSE c_bill_to_location;
  
                      IF l_bill_to_location_id IS NULL  THEN
                              gc_error_site_status_flag := 'Y';
                              
                              print_debug_msg(p_message=> gc_step||' ERROR: BILL_TO_LOCATION:'||l_sup_site_type.BILL_TO_LOCATION||': XXOD_BILL_TO_LOCATION_INVALID2: Bill to Location does not exist in the system.'
                                            ,p_force=> TRUE);
                                                                                                             
                              insert_error (p_program_step                => gc_step
                                           ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                           ,p_error_code                  => 'XXOD_BILL_TO_LOCATION_INVALID2'
                                           ,p_error_message               => 'Bill to Location '||l_sup_site_type.BILL_TO_LOCATION||' does not exist in the system'
                                           ,p_stage_col1                  => 'BILL_TO_LOCATION'
                                           ,p_stage_val1                  => l_sup_site_type.BILL_TO_LOCATION
                                           ,p_stage_col2                  => NULL
                                           ,p_stage_val2                  => NULL
                                           ,p_table_name                  => g_sup_site_cont_table
                                           ); 
                     ELSE
                        print_debug_msg(p_message=> gc_step||' Bill to Location Id is - '||l_sup_site_type.BILL_TO_LOCATION||' is '||l_bill_to_location_id
                                       ,p_force=> FALSE);
                               
                     END IF;   -- IF l_bill_to_location_id IS NULL 
                   END IF;  --  IF l_gcc_segment3 in ('20101000' , '20114000', '20204000')

                   --=============================================================================
                   -- Validating the Supplier Site - Create Debit Memo from RTS
                   --============================================================================= 
                       IF (NOT (l_sup_site_type.CREATE_DEB_MEMO_FRM_RTS IS NULL 
                               or l_sup_site_type.CREATE_DEB_MEMO_FRM_RTS = 'Y')
                          )  THEN  
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: CREATE_DEB_MEMO_FRM_RTS:'||l_sup_site_type.CREATE_DEB_MEMO_FRM_RTS||': XXOD_CREATE_DEB_MEMO_FRM_RTS_INV: Creat Debit Memo From RTS value must be Y or blank.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_CREATE_DEB_MEMO_FRM_RTS_INV'
                                         ,p_error_message               => 'Creat Debit Memo From RTS value '||l_sup_site_type.CREATE_DEB_MEMO_FRM_RTS||' must be Y or blank.'
                                         ,p_stage_col1                  => 'CREATE_DEB_MEMO_FRM_RTS'
                                         ,p_stage_val1                  => l_sup_site_type.CREATE_DEB_MEMO_FRM_RTS
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 

                        END IF;  
                        
                   --=============================================================================
                   -- Validating the Supplier Site - FOB Lookup value
                   --=============================================================================
                       l_fob_code := NULL; 
                       IF l_sup_site_type.FOB IS NOT NULL  THEN   -- Derive the FOB Code
                          l_fob_code := NULL;
                          
                          OPEN c_get_fnd_lookup_code('FOB', l_sup_site_type.FOB, l_po_application_id);
                          FETCH c_get_fnd_lookup_code INTO  l_fob_code;
                          CLOSE c_get_fnd_lookup_code;
                          
                          IF l_fob_code IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: FOB:'||l_sup_site_type.FOB||': XXOD_FOB_INVALID: FOB does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_FOB_INVALID'
                                         ,p_error_message               => 'FOB '||l_sup_site_type.FOB||' does not exist in the system'
                                         ,p_stage_col1                  => 'ORGANIZATION_TYPE'
                                         ,p_stage_val1                  => l_sup_site_type.FOB
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
                            ELSE
                              print_debug_msg(p_message=> gc_step||' FOB Code of FOB - '||l_sup_site_type.FOB||' is '||l_fob_code
                                          ,p_force=> FALSE);                        
                            END IF;   -- IF l_fob_code IS NULL
                        END IF;     -- IF l_sup_site_type.FOB IS NOT NULL                                       

                   --=============================================================================
                   -- Validating the Supplier Site - FREIGHT_TERMS Lookup value
                   --============================================================================= 
                   
                       l_freight_terms_code := NULL;
                       
                       IF l_sup_site_type.FREIGHT_TERMS IS NOT NULL  THEN   -- Derive the FREIGHT_TERMS Code
                          l_freight_terms_code := NULL;
                          
                          OPEN c_get_fnd_lookup_code('FREIGHT TERMS', l_sup_site_type.FREIGHT_TERMS, l_po_application_id);
                          FETCH c_get_fnd_lookup_code INTO  l_freight_terms_code;
                          CLOSE c_get_fnd_lookup_code;
                          
                          IF l_freight_terms_code IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: FREIGHT_TERMS:'||l_sup_site_type.FREIGHT_TERMS||': XXOD_FREIGHT_TERMS_INVALID: FREIGHT TERMS does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_FREIGHT_TERMS_INVALID'
                                         ,p_error_message               => 'FREIGHT TERMS '||l_sup_site_type.FREIGHT_TERMS||' does not exist in the system'
                                         ,p_stage_col1                  => 'ORGANIZATION_TYPE'
                                         ,p_stage_val1                  => l_sup_site_type.FREIGHT_TERMS
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
                            ELSE
                              print_debug_msg(p_message=> gc_step||' FREIGHT TERMS Code of FREIGHT TERMS - '||l_sup_site_type.FREIGHT_TERMS||' is '||l_freight_terms_code
                                          ,p_force=> FALSE);                        
                            END IF;   -- IF l_freight_terms_code IS NULL
                        END IF;     -- IF l_sup_site_type.FREIGHT_TERMS IS NOT NULL      


               --==============================================================================================================
               -- Validating the Supplier Site - Payment Method
               --============================================================================================================== 
                                                
                  IF l_sup_site_type.PAYMENT_METHOD IS NULL
                   THEN
                      l_payment_method := 'CHECK';
                      
                      IF l_sup_site_type.ADDRESS_NAME_PREFIX = 'TCN' THEN
                          l_payment_method := 'CLEARING';
                      END IF;
    
                      print_debug_msg(p_message=> gc_step||' Default value set for l_payment_method is '||l_payment_method
                                      ,p_force=> FALSE);
                                                                                                              
                   ELSE      -- Check the existence of Payment Method
                      l_pay_method_cnt := 0;
                      
                      OPEN c_pay_method_exist(l_sup_site_type.PAYMENT_METHOD);
                      FETCH c_pay_method_exist INTO  l_pay_method_cnt;
                      CLOSE c_pay_method_exist;
                      
                      IF l_pay_method_cnt <=  0  THEN
                        gc_error_site_status_flag := 'Y';
                        
                        print_debug_msg(p_message=> gc_step||' ERROR: PAYMENT_METHOD:'||l_sup_site_type.PAYMENT_METHOD||': XXOD_PAYMENT_METHOD_INVALID: Payment Method does not exist in the system.'
                                      ,p_force=> TRUE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_PAYMENT_METHOD_INVALID'
                                     ,p_error_message               => 'Payment Method does not exist in the system'
                                     ,p_stage_col1                  => 'PAYMENT_METHOD'
                                     ,p_stage_val1                  => l_sup_site_type.PAYMENT_METHOD
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     ); 
                        ELSE
                          print_debug_msg(p_message=> gc_step||' PAYMENT_METHOD:'||l_sup_site_type.PAYMENT_METHOD||' exist in the system.'
                                      ,p_force=> FALSE);
                          l_payment_method :=  l_sup_site_type.PAYMENT_METHOD;
                          
                        END IF;   -- IF l_pay_method_cnt < 1
                    END IF;     -- IF l_sup_site_type.PAYMENT_METHOD IS NULL

                   --=============================================================================
                   -- Validating the Supplier Site - Invoice Tolerance 
                   --============================================================================= 
                       IF l_sup_site_type.INVOICE_TOLERANCE IS NULL THEN
                          l_tolerance_name := 'US_OD_TOLERANCES_Default';
                       ELSE
                          l_tolerance_name := l_sup_site_type.INVOICE_TOLERANCE;
                       END IF;

                          l_tolerance_id := NULL;
                          
                          OPEN c_get_tolerance(l_tolerance_name);
                          FETCH c_get_tolerance INTO  l_tolerance_id;
                          CLOSE c_get_tolerance;
                          
                          IF l_tolerance_id IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: INVOICE_TOLERANCE:'||l_sup_site_type.INVOICE_TOLERANCE||': XXOD_INV_TOLERANCE_INVALID: Invoice Tolerance does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_INV_TOLERANCE_INVALID'
                                         ,p_error_message               => 'Invoice Tolerance '||l_sup_site_type.INVOICE_TOLERANCE||' does not exist in the system'
                                         ,p_stage_col1                  => 'INVOICE_TOLERANCE'
                                         ,p_stage_val1                  => l_sup_site_type.INVOICE_TOLERANCE
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 
                            ELSE
                              print_debug_msg(p_message=> gc_step||' Invoice Tolerance Id of Invoice Tolerance - '||l_sup_site_type.INVOICE_TOLERANCE||' - is '||l_tolerance_id
                                          ,p_force=> FALSE);                                                      
                            END IF;   -- IF l_tolerance_id IS NULL


               --==============================================================================================================
               -- Validating the Supplier Site - Invoice Match Option
               --============================================================================================================== 
                  l_inv_match_option := NULL;                              
                  IF l_sup_site_type.INVOICE_MATCH_OPTION IS NULL
                   THEN
                      l_inv_match_option := 'P';
                      print_debug_msg(p_message=> gc_step||' Default value set for l_inv_match_option is '||l_inv_match_option
                                      ,p_force=> FALSE);
                                                                                                              
                   ELSE      -- Derive the Invoice Match Option
                      
                      IF l_sup_site_type.INVOICE_MATCH_OPTION = 'Purchase Order' THEN
                         l_inv_match_option := 'P';                       
                      ELSIF l_sup_site_type.INVOICE_MATCH_OPTION = 'Receipt' THEN 
                         l_inv_match_option := 'R'; 
                      ELSE
                        gc_error_site_status_flag := 'Y';
                        
                        print_debug_msg(p_message=> gc_step||' ERROR: INVOICE_MATCH_OPTION:'||l_sup_site_type.INVOICE_MATCH_OPTION||': XXOD_INV_MATCH_OPT_INVALID: Invoice Match Option does not exist in the system.'
                                      ,p_force=> TRUE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_INV_MATCH_OPT_INVALID'
                                     ,p_error_message               => 'Invoice Match Option '||l_sup_site_type.INVOICE_MATCH_OPTION||' does not exist in the system'
                                     ,p_stage_col1                  => 'INVOICE_MATCH_OPTION'
                                     ,p_stage_val1                  => l_sup_site_type.INVOICE_MATCH_OPTION
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     );                                              
                      END IF;
                    END IF;     -- IF l_sup_site_type.INVOICE_MATCH_OPTION IS NULL

               --==============================================================================================================
               -- Validating the Supplier Site - Invoice Currency
               --============================================================================================================== 
                       l_inv_cur_code := NULL;                        
                       IF l_sup_site_type.INVOICE_CURRENCY IS NULL THEN
                          IF l_sup_site_type.OPERATING_UNIT = 'OU_US' THEN
                              l_inv_cur_code := 'USD';
                          ELSIF l_sup_site_type.OPERATING_UNIT = 'OU_CA' THEN
                              l_inv_cur_code := 'CAD';
                          ELSE
                             print_debug_msg(p_message=> gc_step||' We cannot suppor operating units other than OU_US and OU_CA. '
                                          ,p_force=> TRUE);
                          END IF;
                       ELSE
                          l_inv_cur_code := l_sup_site_type.INVOICE_CURRENCY;
                       END IF;

                          l_inv_curr_code_cnt := 0;
                          
                          OPEN c_inv_curr_code_exist(l_inv_cur_code);
                          FETCH c_inv_curr_code_exist INTO  l_inv_curr_code_cnt;
                          CLOSE c_inv_curr_code_exist;
                          
                          IF l_inv_curr_code_cnt <= 0  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: INVOICE_CURRENCY:'||l_sup_site_type.INVOICE_CURRENCY||': XXOD_INV_CURRENCY_INVALID: Invoice Currency does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_INV_CURRENCY_INVALID'
                                         ,p_error_message               => 'Invoice Currency '||l_sup_site_type.INVOICE_CURRENCY||' does not exist in the system'
                                         ,p_stage_col1                  => 'INVOICE_CURRENCY'
                                         ,p_stage_val1                  => l_sup_site_type.INVOICE_CURRENCY
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         );                                                      
                            END IF;   -- IF l_inv_curr_code_cnt <= 0                                                                                                        

               --==============================================================================================================
               -- Validating the Supplier Site - Payment Currency
               --============================================================================================================== 
                       l_pay_cur_code := NULL;  
                                             
                       IF l_sup_site_type.PAYMENT_CURRENCY IS NULL THEN
                          l_pay_cur_code := l_inv_cur_code;
                          print_debug_msg(p_message=> gc_step||' Defaulted the payment currency to '||l_pay_cur_code||' from Invoice currency. '
                                          ,p_force=> FALSE);
                       ELSE
                           l_pay_cur_code := l_sup_site_type.PAYMENT_CURRENCY;
                       END IF;  -- IF l_sup_site_type.PAYMENT_CURRENCY IS NULL
                                                 
                          l_inv_curr_code_cnt := 0;
                          
                          OPEN c_inv_curr_code_exist(l_pay_cur_code);
                          FETCH c_inv_curr_code_exist INTO  l_inv_curr_code_cnt;
                          CLOSE c_inv_curr_code_exist;
                          
                          IF l_inv_curr_code_cnt <= 0  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: PAYMENT_CURRENCY:'||l_sup_site_type.PAYMENT_CURRENCY||': XXOD_PAY_CURRENCY_INVALID: Invoice Currency does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_PAY_CURRENCY_INVALID'
                                         ,p_error_message               => 'Payment Currency '||l_sup_site_type.PAYMENT_CURRENCY||' does not exist in the system'
                                         ,p_stage_col1                  => 'PAYMENT_CURRENCY'
                                         ,p_stage_val1                  => l_sup_site_type.PAYMENT_CURRENCY
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         );                                                      
                            END IF;   -- IF l_inv_curr_code_cnt <= 0  

                   --=============================================================================
                   -- Validating the Supplier Site - Hold From Payment
                   --============================================================================= 
                       IF (NOT (l_sup_site_type.HOLD_FROM_PAYMENT IS NULL 
                               or l_sup_site_type.HOLD_FROM_PAYMENT = 'Y')
                          )  THEN  
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: HOLD_FROM_PAYMENT:'||l_sup_site_type.HOLD_FROM_PAYMENT||': XXOD_HOLD_FROM_PAYMENT_INV: Hold From Payment value must be Y or blank.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_HOLD_FROM_PAYMENT_INV'
                                         ,p_error_message               => 'Hold From Payment value '||l_sup_site_type.HOLD_FROM_PAYMENT||' must be Y or blank.'
                                         ,p_stage_col1                  => 'HOLD_FROM_PAYMENT'
                                         ,p_stage_val1                  => l_sup_site_type.HOLD_FROM_PAYMENT
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         ); 

                        END IF;
                   --=============================================================================
                   -- Defaulting the Supplier Site - Payment Priority
                   --============================================================================= 
                       IF l_sup_site_type.PAYMENT_PRIORITY IS NULL THEN 
                           l_payment_priority := 99;
                       ELSE
                           l_payment_priority := l_sup_site_type.PAYMENT_PRIORITY; 
                       END IF; 

               --==============================================================================================================
               -- Validating the Supplier Site - Pay Group
               --============================================================================================================== 
                       l_pay_group := NULL;  
                                             
                       IF l_sup_site_type.PAY_GROUP IS NULL THEN
                          l_pay_group := 'Expense Non-Discount Payments';
                          print_debug_msg(p_message=> gc_step||' Defaulted the payment currency to '||l_pay_group
                                          ,p_force=> FALSE);
                       ELSE
                           l_pay_group := l_sup_site_type.PAY_GROUP;
                       END IF;  -- IF l_sup_site_type.PAY_GROUP IS NULL
                                                 
                          l_pay_group_code := NULL;
                          
                          OPEN c_get_fnd_lookup_code('PAY GROUP', l_pay_group, l_po_application_id);
                          FETCH c_get_fnd_lookup_code INTO  l_pay_group_code;
                          CLOSE c_get_fnd_lookup_code;
                          
                          IF l_pay_group_code IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: PAY_GROUP:'||l_sup_site_type.PAY_GROUP||': XXOD_PAY_GROUP_INVALID: Pay Group does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_PAY_GROUP_INVALID'
                                         ,p_error_message               => 'Pay Group '||l_sup_site_type.PAY_GROUP||' does not exist in the system'
                                         ,p_stage_col1                  => 'PAY_GROUP'
                                         ,p_stage_val1                  => l_sup_site_type.PAY_GROUP
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         );                                                      
                            END IF;   -- IF l_pay_group_code IS NULL 
                   --=============================================================================
                   -- Defaulting the Supplier Site - Deduct Bank Charge
                   --============================================================================= 
                       IF l_sup_site_type.DEDUCT_FRM_BANK_CHRG IS NULL THEN 
                           l_deduct_bank_chrg := 'N';
                       ELSE
                           l_deduct_bank_chrg := l_sup_site_type.DEDUCT_FRM_BANK_CHRG; 
                       END IF; 
               --==============================================================================================================
               -- Validating the Supplier Site - Terms Code
               --============================================================================================================== 
                       l_terms_code := NULL;  
                                             
                       IF l_sup_site_type.TERMS_CODE IS NULL THEN
                          l_terms_code := 'N60';
                          print_debug_msg(p_message=> gc_step||' Defaulted the Terms Code to '||l_terms_code
                                          ,p_force=> FALSE);
                       ELSE
                           l_terms_code := l_sup_site_type.TERMS_CODE;
                       END IF;  -- IF l_sup_site_type.TERMS_CODE IS NULL
                                                 
                          l_terms_id := NULL;
                          
                          OPEN c_get_term_id(l_terms_code);
                          FETCH c_get_term_id INTO  l_terms_id;
                          CLOSE c_get_term_id;
                          
                          IF l_terms_id IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: TERMS_CODE:'||l_sup_site_type.TERMS_CODE||': XXOD_TERMS_CODE_INVALID: Terms Code does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_TERMS_CODE_INVALID'
                                         ,p_error_message               => 'Terms Code value '||l_sup_site_type.TERMS_CODE||' does not exist in the system'
                                         ,p_stage_col1                  => 'TERMS_CODE'
                                         ,p_stage_val1                  => l_sup_site_type.TERMS_CODE
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         );                                                      
                            END IF;   -- IF l_terms_id IS NULL 

               --==============================================================================================================
               -- Validating the Supplier Site - Terms Date Basis
               --============================================================================================================== 
                       l_terms_date_basis := NULL;  
                                             
                       IF l_sup_site_type.TERMS_DATE_BASIS IS NULL THEN
                          l_terms_date_basis := 'Invoice';
                          print_debug_msg(p_message=> gc_step||' Defaulted the Terms Date Basis to '||l_terms_date_basis
                                          ,p_force=> FALSE);
                       ELSE
                           l_terms_date_basis := l_sup_site_type.TERMS_DATE_BASIS;
                       END IF;  -- IF l_sup_site_type.TERMS_DATE_BASIS IS NULL
                                                 
                          l_terms_date_basis_code := NULL;
                          
                          OPEN c_get_fnd_lookup_code('TERMS DATE BASIS', l_terms_date_basis, l_ap_application_id);
                          FETCH c_get_fnd_lookup_code INTO  l_terms_date_basis_code;
                          CLOSE c_get_fnd_lookup_code;
                          
                          IF l_terms_date_basis_code IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: TERMS_DATE_BASIS:'||l_sup_site_type.TERMS_DATE_BASIS||': XXOD_TERMS_DATE_BASIS_INVALID: Terms Date Basis does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_TERMS_DATE_BASIS_INVALID'
                                         ,p_error_message               => 'Terms Date Basis value '||l_sup_site_type.TERMS_DATE_BASIS||' does not exist in the system'
                                         ,p_stage_col1                  => 'TERMS_DATE_BASIS'
                                         ,p_stage_val1                  => l_sup_site_type.TERMS_DATE_BASIS
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         );                                                      
                            END IF;   -- IF l_terms_date_basis_code IS NULL 

               --==============================================================================================================
               -- Validating the Supplier Site - Pay Date Basis
               --============================================================================================================== 
                       l_pay_date_basis := NULL;  
                                             
                       IF l_sup_site_type.PAY_DATE_BASIS IS NULL THEN
                          l_pay_date_basis := 'Discount';
                          print_debug_msg(p_message=> gc_step||' Defaulted the Pay Date Basis to '||l_pay_date_basis
                                          ,p_force=> FALSE);
                       ELSE
                           l_pay_date_basis := l_sup_site_type.PAY_DATE_BASIS;
                       END IF;  -- IF l_sup_site_type.PAY_DATE_BASIS IS NULL
                                                 
                          l_pay_date_basis_code := NULL;
                          
                          OPEN c_get_fnd_lookup_code('PAY DATE BASIS', l_pay_date_basis, l_po_application_id);
                          FETCH c_get_fnd_lookup_code INTO  l_pay_date_basis_code;
                          CLOSE c_get_fnd_lookup_code;
                          
                          IF l_pay_date_basis_code IS NULL  THEN
                            gc_error_site_status_flag := 'Y';
                            
                            print_debug_msg(p_message=> gc_step||' ERROR: PAY_DATE_BASIS:'||l_sup_site_type.PAY_DATE_BASIS||': XXOD_PAY_DATE_BASIS_INVALID: Pay Date Basis does not exist in the system.'
                                          ,p_force=> TRUE);
                                                                                                           
                            insert_error (p_program_step                => gc_step
                                         ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                         ,p_error_code                  => 'XXOD_PAY_DATE_BASIS_INVALID'
                                         ,p_error_message               => 'Pay Date Basis value '||l_sup_site_type.PAY_DATE_BASIS||' does not exist in the system'
                                         ,p_stage_col1                  => 'PAY_DATE_BASIS'
                                         ,p_stage_val1                  => l_sup_site_type.PAY_DATE_BASIS
                                         ,p_stage_col2                  => NULL
                                         ,p_stage_val2                  => NULL
                                         ,p_table_name                  => g_sup_site_cont_table
                                         );                                                      
                            END IF;   -- IF l_pay_date_basis_code IS NULL

                   --=============================================================================
                   -- Defaulting the Supplier Site - Always Take Discount Flag
                   --============================================================================= 
                       IF l_sup_site_type.ALWAYS_TAKE_DISC_FLAG IS NULL THEN 
                           l_always_disc_flag := 'Y';
                       ELSE
                           l_always_disc_flag := l_sup_site_type.ALWAYS_TAKE_DISC_FLAG; 
                       END IF; 

                   --=============================================================================
                   -- Defaulting the Supplier Site - Primary Pay Flag
                   --=============================================================================
                       IF  l_supplier_type (l_sup_idx).vendor_type_lookup_code = 'GARNISHMENT' THEN
                          l_primary_pay_flag := 'Y';
                       ELSE
                          l_primary_pay_flag := NULL;
                       END IF;
                   
                   set_step('Supplier Site Custom DFF Validation');
                   
                   --=============================================================================
                   -- Validating the Supplier Site - DFF - Supplier Site Header-  DUNS#
                   --=============================================================================
                      IF (NOT (isNumeric(l_sup_site_type.DUNS_NUM))) THEN
                        gc_error_site_status_flag := 'Y';
      
                        print_debug_msg(p_message=> l_program_step||' : ERROR: DUNS_NUM : '||l_sup_site_type.DUNS_NUM||' : XXOD_DUNS_NUM_INVALID: - Duns# must be numeric.'
                                        ,p_force=> FALSE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_DUNS_NUM_INVALID'
                                     ,p_error_message               => 'DUNS# '||l_sup_site_type.DUNS_NUM||' must be numeric.'
                                     ,p_stage_col1                  => 'DUNS_NUM'
                                     ,p_stage_val1                  => l_sup_site_type.DUNS_NUM
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_site_cont_table
                                     );
                      END IF;

                   --=============================================================================
                   -- Validating the Supplier Site - DFF - Supplier Site Header - Future Use
                   --=============================================================================
		   /*
                      IF (NOT (isNumeric(l_sup_site_type.FUTURE_USE))) THEN
                        gc_error_site_status_flag := 'Y';
      
                        print_debug_msg(p_message=> l_program_step||' : ERROR: FUTURE_USE : '||l_sup_site_type.FUTURE_USE||' : XXOD_FUTURE_USE_INVALID: - Future Use value must be numeric.'
                                        ,p_force=> FALSE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type (l_sup_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_FUTURE_USE_INVALID'
                                     ,p_error_message               => 'Future Use '||l_sup_site_type.DUNS_NUM||' must be numeric.'
                                     ,p_stage_col1                  => 'FUTURE_USE'
                                     ,p_stage_val1                  => l_sup_site_type.FUTURE_USE
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_site_cont_table
                                     );
                      END IF;  
		   */
                  --=============================================================================
                  -- Validating the Supplier Site - DFF - Developed by Paddy and appending the code here. 
                  --============================================================================= 
                   v_error_Flag := 'N';
                   v_error_message := '';
                  
                  IF l_sup_site_type.delivery_policy IS NOT NULL THEN
              
                     BEGIN
                 SELECT flex_value
                   INTO v_delivery_policy
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_DELIVERY_POLICY'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.flex_value_meaning=l_sup_site_type.delivery_policy
                          AND b.enabled_flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_delivery_policy:=NULL;
                   v_error_message:='DFF Invalid Delivery Policy';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;       
              
                  IF l_sup_site_type.min_prepaid_code IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_min_prepaid_code
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_MIN_PREPAID_CODE'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.min_prepaid_code
                          AND b.enabled_flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_min_prepaid_code:=NULL;
                   v_error_message:=v_error_message||', Invalid MinPrepaid Code';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;       
              
                  IF l_sup_site_type.supplier_ship_to IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_supplier_ship_to
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_SUPPLIER_SHIP_TO'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.flex_value_meaning=l_sup_site_type.supplier_ship_to
                          AND b.enabled_flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_supplier_ship_to:=NULL;
                   v_error_message:=v_error_message||', Invalid SupplierShipTo';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;
              
              
                  IF l_sup_site_type.inventory_type_code IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_inventory_type_code
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_INVENTORY_TYPE'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.inventory_type_code
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_inventory_type_code:=NULL;
                   v_error_message:=v_error_message||', Invalid InventoryTypeCode';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;
                               
              
                  IF l_sup_site_type.vertical_mrkt_indicator IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_vertical_mrkt_indicator
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_VERTICAL_MARKET_INDICATORS'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.vertical_mrkt_indicator
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_vertical_mrkt_indicator:=NULL;
                   v_error_message:=v_error_message||', Invalid VerticalMrktIndicator';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;             
                            
                 
                  IF l_sup_site_type.new_store_terms IS NOT NULL THEN
              
                    BEGIN
                 SELECT term_id
                   INTO v_new_store_terms
                   FROM ap_terms_vl
                  WHERE name=l_sup_site_type.new_store_terms
                          AND enabled_flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_new_store_terms:=NULL;
                   v_error_message:=v_error_message||', Invalid NewStoreTerms';
                   v_error_Flag:='Y';
                     END;
              
                  END IF; 
              
                  IF l_sup_site_type.seasonal_terms IS NOT NULL THEN
              
                    BEGIN
                 SELECT term_id
                   INTO v_seasonal_terms
                   FROM ap_terms_vl
                  WHERE name=l_sup_site_type.seasonal_terms
                          AND enabled_flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_seasonal_terms:=NULL;
                   v_error_message:=v_error_message||', Invalid SeasonalTerms';
                   v_error_Flag:='Y';
                     END;
              
                  END IF; 
                            
                  IF l_sup_site_type.edi_852 IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_edi_852
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_852_SALES' 
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.edi_852
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_edi_852:=NULL;
                   v_error_message:=v_error_message||', Invalid 852';
                   v_error_Flag:='Y';
                     END;
              
                  END IF; 
              
                  IF l_sup_site_type.edi_distribution IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_edi_distribution
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_EDI_CODES' 
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.edi_distribution
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_edi_distribution:=NULL;
                   v_error_message:=v_error_message||', Invalid EDIDistribution';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;                     
                                
                  IF l_sup_site_type.rtv_option IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_rtv_option
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_RTV_OPTIONS' 
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.rtv_option
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_rtv_option:=NULL;
                   v_error_message:=v_error_message||', Invalid RTVOption';
                   v_error_Flag:='Y';
                     END;
              
                  END IF; 
                              
                  IF l_sup_site_type.rtv_frt_pmt_method IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_rtv_frt_pmt_method
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_RTV_FREIGHT_PAYMENT' 
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.rtv_frt_pmt_method
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_rtv_frt_pmt_method:=NULL;
                   v_error_message:=v_error_message||', Invalid RTVFreight';
                   v_error_Flag:='Y';
                     END;
              
                  END IF; 
              
                  IF l_sup_site_type.payment_frequency IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_payment_frequency
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_PAYMENT_FREQUENCY'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.payment_frequency
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_payment_frequency:=NULL;
                   v_error_message:=v_error_message||', Invalid PaymentFrequency';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;       
              
                  IF l_sup_site_type.obsolete_item IS NOT NULL THEN
              
                    BEGIN
                 SELECT flex_value
                   INTO v_obsolete_item
                   FROM fnd_flex_values_vl b,
                        fnd_Flex_value_sets a
                  WHERE a.flex_value_Set_name='OD_AP_OBSOLETE_CODE'
                          AND b.flex_value_Set_id=a.flex_value_set_id
                    AND b.description=l_sup_site_type.obsolete_item
                    AND b.enabled_Flag='Y';
                     EXCEPTION
                 WHEN others THEN
                   v_obsolete_item:=NULL;
                   v_error_message:=v_error_message||', Invalid ObsoleteItem';
                   v_error_Flag:='Y';
                     END;
              
                  END IF;                   
                  IF v_error_Flag = 'Y' THEN
                      gc_error_site_status_flag := 'Y';
        
                      print_debug_msg(p_message=> gc_step||' ERROR: Supplie Site CUSTOM DFF Values: XXOD_CUSTOM_DFF_INVALID:'||v_error_message
                                          ,p_force=> TRUE);
                                                                                                         
                      insert_error (p_program_step                => gc_step
                                       ,p_primary_key                 => l_supplier_type(l_sup_idx).SUPPLIER_NAME
                                       ,p_error_code                  => 'XXOD_CUSTOM_DFF_INVALID'||v_error_message
                                       ,p_error_message               => 'Supplie Site CUSTOM DFF Values: XXOD_CUSTOM_DFF_INVALID:'||v_error_message
                                       ,p_stage_col1                  => 'CUSTOM_DFF_VALUES'
                                       ,p_stage_val1                  => ''
                                       ,p_stage_col2                  => NULL
                                       ,p_stage_val2                  => NULL
                                       ,p_table_name                  => g_sup_site_cont_table
                                       );                  
                  END IF;                                                                                                                                            

                                                                                                     
                  --====================================================================
                  --Assigning the Values to Supplier Site PL/SQL Table for Bulk Update
                  --====================================================================
                   l_sup_site_and_contact(l_sup_site_idx).country_code := l_site_country_code;
                   l_sup_site_and_contact(l_sup_site_idx).ORG_ID := l_org_id;                  
                   l_sup_site_and_contact(l_sup_site_idx).purchasing_site_flag := l_purchasing_site_flag;
                   l_sup_site_and_contact(l_sup_site_idx).pay_site_flag := l_pay_site_flag;              
                   l_sup_site_and_contact(l_sup_site_idx).CONT_PHONE_NUMBER := l_cont_phone_num;     
                   l_sup_site_and_contact(l_sup_site_idx).SHIP_TO_LOC_ID := l_ship_to_location_id;
                   l_sup_site_and_contact(l_sup_site_idx).BILL_TO_LOC_ID := l_bill_to_location_id;
                   l_sup_site_and_contact(l_sup_site_idx).CCID := l_ccid;
                   l_sup_site_and_contact(l_sup_site_idx).FOB := l_fob_code;
                   l_sup_site_and_contact(l_sup_site_idx).FREIGHT_TERMS := l_freight_terms_code;
                   l_sup_site_and_contact(l_sup_site_idx).PAYMENT_METHOD := l_payment_method;
                   l_sup_site_and_contact(l_sup_site_idx).TOLERANCE_ID := l_tolerance_id;
                   l_sup_site_and_contact(l_sup_site_idx).INVOICE_MATCH_OPTION := l_inv_match_option;
                   l_sup_site_and_contact(l_sup_site_idx).INVOICE_CURRENCY := l_inv_cur_code;
                   l_sup_site_and_contact(l_sup_site_idx).PAYMENT_CURRENCY := l_pay_cur_code;
                   l_sup_site_and_contact(l_sup_site_idx).PAYMENT_PRIORITY := l_payment_priority;
                   l_sup_site_and_contact(l_sup_site_idx).PAY_GROUP_CODE := l_pay_group_code;
                   l_sup_site_and_contact(l_sup_site_idx).DEDUCT_FRM_BANK_CHRG := l_deduct_bank_chrg;
                   l_sup_site_and_contact(l_sup_site_idx).terms_id := l_terms_id;
                   l_sup_site_and_contact(l_sup_site_idx).terms_date_basis_code :=l_terms_date_basis_code;
                   l_sup_site_and_contact(l_sup_site_idx).pay_date_basis_lookup_code :=l_pay_date_basis_code;
                   l_sup_site_and_contact(l_sup_site_idx).ALWAYS_TAKE_DISC_FLAG := l_always_disc_flag;
                   l_sup_site_and_contact(l_sup_site_idx).PRIMARY_PAY_FLAG := l_primary_pay_flag;
                   l_sup_site_and_contact(l_sup_site_idx).INCOME_TAX_REP_SITE := l_income_tax_rep_site_flag;
                   
                   l_sup_site_and_contact(l_sup_site_idx).DELIVERY_POLICY_DR := v_DELIVERY_POLICY;                       
                   l_sup_site_and_contact(l_sup_site_idx).MIN_PREPAID_CODE_DR := v_MIN_PREPAID_CODE;        
                   l_sup_site_and_contact(l_sup_site_idx).SUPPLIER_SHIP_TO_DR := v_SUPPLIER_SHIP_TO;         
                   l_sup_site_and_contact(l_sup_site_idx).INVENTORY_TYPE_CODE_DR :=v_INVENTORY_TYPE_CODE;         
                   l_sup_site_and_contact(l_sup_site_idx).VERTICAL_MRKT_IND_DR := v_VERTICAL_MRKT_INDICATOR;         
                   l_sup_site_and_contact(l_sup_site_idx).NEW_STORE_TEMRS_DR := v_NEW_STORE_TERMS;         
                   l_sup_site_and_contact(l_sup_site_idx).SEASONAL_TERMS_DR := v_SEASONAL_TERMS;         
                   l_sup_site_and_contact(l_sup_site_idx).EDI_852_DR := v_EDI_852;                 
                   l_sup_site_and_contact(l_sup_site_idx).EDI_DISTRIBUTION_DR := v_EDI_DISTRIBUTION;               
                   l_sup_site_and_contact(l_sup_site_idx).RTV_OPTION_DR := v_RTV_OPTION;           
                   l_sup_site_and_contact(l_sup_site_idx).RTV_FRT_PMT_METHOD_DR := v_RTV_FRT_PMT_METHOD;           
                   l_sup_site_and_contact(l_sup_site_idx).PAYMENT_FREQUENCY_DR := v_PAYMENT_FREQUENCY;             
                   l_sup_site_and_contact(l_sup_site_idx).OBSOLETE_ITEM_DR := v_OBSOLETE_ITEM;     
                   
                   
              END IF;  -- IF  gc_error_site_status_flag = 'N' -- After Supplier Site Existence Check Completed                   
                    
                   
                    l_sup_site_and_contact(l_sup_site_idx).supplier_name := l_sup_site_type.supplier_name;
                    l_sup_site_and_contact(l_sup_site_idx).address_name_prefix := l_sup_site_type.address_name_prefix;
                    l_sup_site_and_contact(l_sup_site_idx).address_purpose := l_sup_site_type.address_purpose;                                     
                    l_sup_site_and_contact(l_sup_site_idx).address_line1 := l_sup_site_type.address_line1;
                    l_sup_site_and_contact(l_sup_site_idx).address_line2 := l_sup_site_type.address_line2;
                    l_sup_site_and_contact(l_sup_site_idx).city := l_sup_site_type.city;
                    l_sup_site_and_contact(l_sup_site_idx).state := l_sup_site_type.state;
                    l_sup_site_and_contact(l_sup_site_idx).country := l_sup_site_type.country;
                    l_sup_site_and_contact(l_sup_site_idx).province := l_sup_site_type.province;               
                    l_sup_site_and_contact(l_sup_site_idx).site_category := l_sup_site_type.site_category;
                  
                                                  
                  IF gc_error_site_status_flag = 'Y'
                  THEN
                      l_sup_site_and_contact(l_sup_site_idx).SUPP_SITE_PROCESS_FLAG := gn_process_status_error;
                      l_sup_site_and_contact(l_sup_site_idx).SUPP_SITE_ERROR_FLAG   := gc_process_error_flag;
                      l_sup_site_and_contact(l_sup_site_idx).SUPP_SITE_ERROR_MSG    := gc_error_msg;  
                      
                      l_sup_site_fail := 'Y';
                      
                      -- Prepare below list of errored prefixes
                      IF length(l_error_prefix_list) > 0 THEN
                          l_error_prefix_list := l_error_prefix_list||',';
                      END IF;
                      l_error_prefix_list := l_error_prefix_list||''''||l_sup_site_and_contact(l_sup_site_idx).ADDRESS_NAME_PREFIX||'''';

                      print_debug_msg(p_message=> gc_step||' ---------------Data validation failed for this site with prefix '||l_sup_site_and_contact(l_sup_site_idx).ADDRESS_NAME_PREFIX||'--------------'
                                          ,p_force=> TRUE);                                            
                      
                      l_supplier_type (l_sup_idx).SUPP_ERROR_MSG := l_supplier_type (l_sup_idx).SUPP_ERROR_MSG||' SITE ERROR : '||gc_error_msg||';';                    
                  ELSE
                     l_sup_site_and_contact (l_sup_site_idx).SUPP_SITE_PROCESS_FLAG := gn_process_status_validated;                     
                     print_debug_msg(p_message=> gc_step||' ---------------Data validation is success for this site with prefix '||l_sup_site_and_contact(l_sup_site_idx).ADDRESS_NAME_PREFIX||'------------'
                                          ,p_force=> TRUE); 
                  END IF;               
               
               END LOOP;    --  FOR l_sup_site_type IN c_supplier_site
               print_debug_msg(p_message=> gc_step||' List of the site failed prefixes is '||l_error_prefix_list 
                                          ,p_force=> TRUE);                

              --====================================================================
                  -- Doing Status Update for Staging Tables
              --====================================================================               
                                                             
               -- If Supplier is failed then fail all the Sites                                                  
               IF gc_error_status_flag = 'Y'   
               THEN
                  BEGIN
                    UPDATE XX_AP_SUPPLIER_STG
                       SET SUPP_PROCESS_FLAG = gn_process_status_error
                           , SUPP_ERROR_FLAG = gc_process_error_flag
                           , SUPP_ERROR_MSG  = l_supplier_type (l_sup_idx).SUPP_ERROR_MSG||':'||l_sup_fail_site_depend
                     WHERE SUPPLIER_NAME = l_supplier_type (l_sup_idx).SUPPLIER_NAME
                       AND REQUEST_ID = gn_request_id;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for errorred supplier, status update - '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' does not exists'
                                    ,p_force=> TRUE);                         
                    WHEN OTHERS THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for errorred supplier, status update - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500)
                                    ,p_force=> TRUE);                                                   
                  END; 
                  
                  BEGIN

                    FOR counter IN REVERSE  0 .. (l_site_cnt_for_sup - 1) LOOP                                          
                      l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_PROCESS_FLAG := gn_process_status_error;
                      l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_ERROR_FLAG   := gc_process_error_flag;
                      l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_ERROR_MSG    := 'ERROR: in SUPPLIER'||l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_ERROR_MSG;                        
                     END LOOP;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for errorred supplier site, status update - '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' does not exists'
                                    ,p_force=> TRUE);                         
                    WHEN OTHERS THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for errorred supplier site, status update - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500)
                                    ,p_force=> TRUE);                                                   
                  END;                        
                  
               ELSE        --  IF gc_error_status_flag = 'Y'
               
                  BEGIN
                    UPDATE XX_AP_SUPPLIER_STG
                       SET SUPP_PROCESS_FLAG = gn_process_status_validated
                          ,SUPPLIER_NAME =  UPPER(l_supplier_type (l_sup_idx).SUPPLIER_NAME)
                          , vendor_type_lookup_code = l_supplier_type (l_sup_idx).vendor_type_lookup_code 
                          , vendor_id  = l_supplier_type (l_sup_idx).vendor_id
                          , party_id   = l_supplier_type (l_sup_idx).party_id
                          , object_version_no = l_supplier_type (l_sup_idx).object_version_no
                          , create_flag     = l_supplier_type (l_sup_idx).create_flag
                          , update_flag     = l_supplier_type (l_sup_idx).update_flag
                          , tax_reporting_name = l_supplier_type(l_sup_idx).tax_reporting_name
                          , tax_verification_date = l_supplier_type(l_sup_idx).tax_verification_date                          
                          , organization_type_lookup_code = l_supplier_type(l_sup_idx).organization_type_lookup_code
                          , one_time_flag = l_supplier_type(l_sup_idx).one_time_flag
                          , federal_reportable_flag =  l_supplier_type(l_sup_idx).federal_reportable_flag
                          , state_reportable_flag = l_supplier_type(l_sup_idx).state_reportable_flag

                     WHERE SUPPLIER_NAME = l_supplier_type (l_sup_idx).SUPPLIER_NAME
                       AND request_id = gn_request_id;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier, status update - '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' does not exists'
                                    ,p_force=> TRUE);                         
                    WHEN OTHERS THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier, status update - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500)
                                    ,p_force=> TRUE);                                                   
                  END;                     

                  
                  BEGIN
                  
                      print_debug_msg(p_message=> gc_step||' l_sup_site_fail value is '||l_sup_site_fail
                                      ,p_force=> FALSE); 
                      IF l_sup_site_fail = 'Y' THEN
                        print_debug_msg(p_message=> gc_step||' One pay site of the supplier - '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' - is failed. So, fail other sites of this prefix'
                                      ,p_force=> TRUE); 
                        -- If any one site is failed for a PREFIX then we need to set error for all sites of that PREFIX of this supplier

                         FOR out_counter IN REVERSE  0 .. (l_site_cnt_for_sup - 1) LOOP      -- This outer loop to get error site and its prefix
                         
                           print_debug_msg(p_message=> gc_step||' l_sup_site_and_contact(l_sup_site_idx - out_counter).ADDRESS_NAME_PREFIX is  '||l_sup_site_and_contact(l_sup_site_idx - out_counter).ADDRESS_NAME_PREFIX
                                            ,p_force=> TRUE); 
                                            
                           
                           IF  l_sup_site_and_contact(l_sup_site_idx - out_counter).SUPP_SITE_PROCESS_FLAG = gn_process_status_error THEN                 

                               print_debug_msg(p_message=> gc_step||' l_sup_site_and_contact(l_sup_site_idx - out_counter).ADDRESS_NAME_PREFIX is  '||l_sup_site_and_contact(l_sup_site_idx - out_counter).ADDRESS_NAME_PREFIX
                                                ,p_force=> TRUE); 
                               FOR counter IN REVERSE  0 .. (l_site_cnt_for_sup - 1) LOOP    -- This Inner loop to set the error for all sites of the above error prefix
    
                                  print_debug_msg(p_message=> gc_step||' l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_PROCESS_FLAG is '||l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_PROCESS_FLAG
                                                  ,p_force=> TRUE);
                                  print_debug_msg(p_message=> gc_step||'gn_process_status_validated is '||gn_process_status_validated
                                                ,p_force=> TRUE); 
                                  print_debug_msg(p_message=> gc_step||' l_sup_site_and_contact(l_sup_site_idx - counter).ADDRESS_NAME_PREFIX is  '||l_sup_site_and_contact(l_sup_site_idx - counter).ADDRESS_NAME_PREFIX
                                                ,p_force=> TRUE);                             
                                  IF  ((l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_PROCESS_FLAG = gn_process_status_validated)
                                        AND (l_sup_site_and_contact(l_sup_site_idx - counter).ADDRESS_NAME_PREFIX = l_sup_site_and_contact(l_sup_site_idx - out_counter).ADDRESS_NAME_PREFIX)
                                      )  THEN
                                        print_debug_msg(p_message=> gc_step||'Set the error flag to this site '
                                                ,p_force=> TRUE); 
                                        l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_PROCESS_FLAG := gn_process_status_error;
                                        l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_ERROR_FLAG   := gc_process_error_flag;
                                        l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_ERROR_MSG    := 'ADDRESS_NAME_PREFIX:Corresponding Prefix site failed';

                                  END IF;  -- IF  ((l_sup_site_and_contact(l_sup_site_idx - counter).SUPP_SITE_PROCESS_FLAG    
                                END LOOP;   -- FOR counter IN REVERSE  0
                           END IF; --   IF  l_sup_site_and_contact(l_sup_site_idx - out_counter).SUPP_SITE_PROCESS_FLAG = gn_process_status_error
                        END LOOP;
                                                        
                      END IF;   -- IF l_sup_site_fail = 'Y' THEN
                    
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier site, status update - '||l_supplier_type (l_sup_idx).SUPPLIER_NAME||' does not exists'
                                    ,p_force=> TRUE);                         
                    WHEN OTHERS THEN 
                         print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier site, status update - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500)
                                    ,p_force=> TRUE);                                                   
                  END; 
                                        
                --  l_val_records :=   l_val_records + 1;
               END IF;
                              
      END LOOP; -- For (l_supplier_type.FIRST .. l_supplier_type.LAST)
    END IF;     -- l_supplier_type.COUNT > 0
        

         --============================================================================
         -- For Doing the Bulk Update
         --============================================================================
        l_program_step := '';
        print_debug_msg(p_message=> l_program_step||': Do Bulk Update for all Site Records '
                  ,p_force=> TRUE);
                           
         IF l_sup_site_and_contact.COUNT > 0
         THEN
            BEGIN
               FORALL l_idxs IN l_sup_site_and_contact.FIRST .. l_sup_site_and_contact.LAST                                                                    
                  UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                     SET  country_code = l_sup_site_and_contact(l_idxs).country_code
                          ,ORG_ID =  l_sup_site_and_contact(l_idxs).ORG_ID                          
                          ,purchasing_site_flag = l_sup_site_and_contact(l_idxs).purchasing_site_flag
                          ,pay_site_flag = l_sup_site_and_contact(l_idxs).pay_site_flag                          
                          ,CONT_PHONE_NUMBER = l_sup_site_and_contact(l_idxs).CONT_PHONE_NUMBER
                          ,SHIP_TO_LOC_ID = l_sup_site_and_contact(l_idxs).SHIP_TO_LOC_ID
                          ,BILL_TO_LOC_ID = l_sup_site_and_contact(l_idxs).BILL_TO_LOC_ID
                          ,CCID = l_sup_site_and_contact(l_idxs).CCID
                          ,FOB = l_sup_site_and_contact(l_idxs).FOB
                          ,FREIGHT_TERMS = l_sup_site_and_contact(l_idxs).FREIGHT_TERMS                          
                          ,PAYMENT_METHOD = l_sup_site_and_contact(l_idxs).PAYMENT_METHOD
                          ,TOLERANCE_ID = l_sup_site_and_contact(l_idxs).TOLERANCE_ID
                          ,INVOICE_MATCH_OPTION = l_sup_site_and_contact(l_idxs).INVOICE_MATCH_OPTION
                          ,INVOICE_CURRENCY = l_sup_site_and_contact(l_idxs).INVOICE_CURRENCY
                          ,PAYMENT_CURRENCY = l_sup_site_and_contact(l_idxs).PAYMENT_CURRENCY
                          ,PAYMENT_PRIORITY = l_sup_site_and_contact(l_idxs).PAYMENT_PRIORITY
                          ,PAY_GROUP_CODE = l_sup_site_and_contact(l_idxs).PAY_GROUP_CODE
                          ,DEDUCT_FRM_BANK_CHRG = l_sup_site_and_contact(l_idxs).DEDUCT_FRM_BANK_CHRG
                          ,terms_id = l_sup_site_and_contact(l_idxs).terms_id
                          ,terms_date_basis_code = l_sup_site_and_contact(l_idxs).terms_date_basis_code
                          ,pay_date_basis_lookup_code = l_sup_site_and_contact(l_idxs).pay_date_basis_lookup_code
                          ,ALWAYS_TAKE_DISC_FLAG = l_sup_site_and_contact(l_idxs).ALWAYS_TAKE_DISC_FLAG
                          ,PRIMARY_PAY_FLAG = l_sup_site_and_contact(l_idxs).PRIMARY_PAY_FLAG
                          ,INCOME_TAX_REP_SITE = l_sup_site_and_contact(l_idxs).INCOME_TAX_REP_SITE
                          ,DELIVERY_POLICY_DR = l_sup_site_and_contact(l_idxs).DELIVERY_POLICY_DR                      
                          ,MIN_PREPAID_CODE_DR = l_sup_site_and_contact(l_idxs).MIN_PREPAID_CODE_DR        
                          ,SUPPLIER_SHIP_TO_DR = l_sup_site_and_contact(l_idxs).SUPPLIER_SHIP_TO_DR         
                          ,INVENTORY_TYPE_CODE_DR = l_sup_site_and_contact(l_idxs).INVENTORY_TYPE_CODE_DR
                          ,VERTICAL_MRKT_IND_DR = l_sup_site_and_contact(l_idxs).VERTICAL_MRKT_IND_DR         
                          ,NEW_STORE_TEMRS_DR = l_sup_site_and_contact(l_idxs).NEW_STORE_TEMRS_DR         
                          ,SEASONAL_TERMS_DR = l_sup_site_and_contact(l_idxs).SEASONAL_TERMS_DR         
                          ,EDI_852_DR = l_sup_site_and_contact(l_idxs).EDI_852_DR             
                          ,EDI_DISTRIBUTION_DR = l_sup_site_and_contact(l_idxs).EDI_DISTRIBUTION_DR           
                          ,RTV_OPTION_DR = l_sup_site_and_contact(l_idxs).RTV_OPTION_DR               
                          ,RTV_FRT_PMT_METHOD_DR = l_sup_site_and_contact(l_idxs).RTV_FRT_PMT_METHOD_DR               
                          ,PAYMENT_FREQUENCY_DR = l_sup_site_and_contact(l_idxs).PAYMENT_FREQUENCY_DR                 
                          ,OBSOLETE_ITEM_DR = l_sup_site_and_contact(l_idxs).OBSOLETE_ITEM_DR                                                  
                          ,SUPP_SITE_PROCESS_FLAG = l_sup_site_and_contact(l_idxs).SUPP_SITE_PROCESS_FLAG
                          ,SUPP_SITE_ERROR_FLAG = l_sup_site_and_contact(l_idxs).SUPP_SITE_ERROR_FLAG
                          ,SUPP_SITE_ERROR_MSG = l_sup_site_and_contact(l_idxs).SUPP_SITE_ERROR_MSG
                   WHERE supplier_name = l_sup_site_and_contact(l_idxs).supplier_name
                     AND address_name_prefix = l_sup_site_and_contact(l_idxs).address_name_prefix
                     AND address_purpose = l_sup_site_and_contact(l_idxs).address_purpose
                     AND address_line1 = l_sup_site_and_contact(l_idxs).address_line1
                     AND (address_line2 IS NULL or address_line2 =   l_sup_site_and_contact(l_idxs).address_line2)
                     AND (city IS NULL or city =   l_sup_site_and_contact(l_idxs).city)
                     AND (state IS NULL or state =   l_sup_site_and_contact(l_idxs).state)
                     AND (province IS NULL or province = l_sup_site_and_contact(l_idxs).province)
                     AND site_category = l_sup_site_and_contact(l_idxs).site_category
                     AND request_id = gn_request_id;                    
            EXCEPTION
               WHEN NO_DATA_FOUND THEN 
                  l_error_message :=    'When No Data Found during the bulk update of site staging table';
                               
                  --============================================================================
                  -- To Insert into Common Error Table
                  --============================================================================
                  insert_error (p_program_step                => 'SITE'
                               ,p_primary_key                   => NULL
                               ,p_error_code                  => 'XXOD_BULK_UPD_SITE'
                               ,p_error_message               => 'When No Data Found during the bulk update of site staging table'
                               ,p_stage_col1                  => NULL
                               ,p_stage_val1                  => NULL
                               ,p_stage_col2                  => NULL
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_site_cont_table
                               );  
                   print_debug_msg(p_message=> l_program_step||': '||l_error_message
                                  ,p_force=> TRUE);            
               
               WHEN OTHERS
               THEN
                  l_error_message :=    'When Others Exception  during the bulk update of site staging table'
                               || SQLCODE
                               || ' - '
                               || SUBSTR (SQLERRM
                                         ,1
                                         ,3800
                                         );
                  --============================================================================
                  -- To Insert into Common Error Table
                  --============================================================================
                  insert_error (p_program_step                => 'SITE'
                               ,p_primary_key                   => NULL
                               ,p_error_code                  => 'XXOD_BULK_UPD_SITE'
                               ,p_error_message               => 'When Others Exception during the bulk update of site staging table'
                               ,p_stage_col1                  => NULL
                               ,p_stage_val1                  => NULL
                               ,p_stage_col2                  => NULL
                               ,p_stage_val2                  => NULL
                               ,p_table_name                  => g_sup_site_cont_table
                               );
                  print_debug_msg(p_message=> l_program_step||': '||l_error_message
                                  ,p_force=> TRUE);
            END;
         END IF;    -- IF l_sup_site_and_contact.COUNT > 0
    
    EXIT  WHEN c_supplier%NOTFOUND;
  END LOOP; -- c_supplier loop
  
  CLOSE c_supplier;
  l_supplier_type.DELETE;

      -- Update the Site Stage table withe Error if the Site has 'PR' successfull and there is no 'PY' in the corresponding PREFIX for that supplier

      print_debug_msg(p_message=> l_program_step||': Check and Update the Site Staging to Error if PY not exists and PR is successfull.'
                                  ,p_force=> TRUE);
      BEGIN 
      
      l_upd_count :=  0;
              
      UPDATE XX_AP_SUPP_SITE_CONTACT_STG  xassc1
      SET xassc1.SUPP_SITE_PROCESS_FLAG = gn_process_status_error
         ,xassc1.SUPP_SITE_ERROR_FLAG = gc_process_error_flag
         ,xassc1.SUPP_SITE_ERROR_MSG  = SUPP_SITE_ERROR_MSG||'ADDRESS_PURPOSE:PR:XXOD_SITE_NO_PY;'
      WHERE NVL(xassc1.purchasing_site_flag, 'N') = 'Y'
        AND xassc1.SUPP_SITE_PROCESS_FLAG = gn_process_status_validated  -- 35
        AND xassc1.request_id = gn_request_id
        AND NVL(xassc1.pay_site_flag, 'N') <> 'Y'  -- In case of address_purpose = 'BOTH', don't retrieve that record
        AND 1 > (
                         SELECT count(1)
                         FROM XX_AP_SUPP_SITE_CONTACT_STG xassc2
                         WHERE xassc2.address_name_prefix = xassc1. address_name_prefix
                           AND NVL(xassc2.pay_site_flag, 'N') = 'Y'
                           AND xassc2.request_id = gn_request_id
                           AND xassc2.SUPP_SITE_PROCESS_FLAG =  gn_process_status_validated
                           AND xassc2.SUPPLIER_NAME = xassc1.SUPPLIER_NAME
                        );
                        
             l_upd_count :=  SQL%ROWCOUNT;
             print_debug_msg(p_message=> gc_step||' Update '||l_upd_count||' records where the PR is successful but there is no PY for that site'
                                          ,p_force=> TRUE);
                   
       EXCEPTION
         WHEN OTHERS THEN
             l_err_buff := ' ERROR: Updating the PR sites when there is no PY Site - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
             print_debug_msg(p_message=> gc_step||l_err_buff
                                          ,p_force=> TRUE);
         l_ret_code := 2;
         l_return_status := 'E';
       
       END;         
       
      l_sup_eligible_cnt := 0;
      l_sup_val_load_cnt := 0;
      l_sup_error_cnt := 0;
      l_sup_val_not_load_cnt := 0;
      l_sup_ready_process := 0;

      OPEN  c_sup_stats;
      FETCH c_sup_stats INTO l_sup_eligible_cnt, l_sup_val_load_cnt, l_sup_error_cnt, l_sup_val_not_load_cnt, l_sup_ready_process;
      CLOSE c_sup_stats;

      l_supsite_eligible_cnt := 0;
      l_supsite_val_load_cnt := 0;
      l_supsite_error_cnt := 0;
      l_supsite_val_not_load_cnt := 0;
      l_supsite_ready_process := 0;
      
      OPEN  c_sup_site_stats;
      FETCH c_sup_site_stats INTO l_supsite_eligible_cnt, l_supsite_val_load_cnt, l_supsite_error_cnt, l_supsite_val_not_load_cnt, l_supsite_ready_process;
      CLOSE c_sup_site_stats;
                      

      x_ret_code := l_ret_code;
      x_return_status := l_return_status;
      x_err_buf := l_err_buff;
      
      x_val_records :=  l_sup_val_not_load_cnt +  l_supsite_val_not_load_cnt;
      x_inval_records :=  l_sup_error_cnt +  l_supsite_error_cnt + l_sup_eligible_cnt + l_supsite_eligible_cnt;

      print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);      
      print_debug_msg(p_message => 'SUPPLIER - Records Successfully Validated are '|| l_sup_val_not_load_cnt, p_force => true);
      print_debug_msg(p_message => 'SUPPLIER - Records Validated and Errored are '|| l_sup_error_cnt, p_force => true);
      print_debug_msg(p_message => 'SUPPLIER - Records Eligible for Validation but Untouched  are '|| l_sup_eligible_cnt, p_force => true);
      print_debug_msg(p_message => '----------------------', p_force => true);
      print_debug_msg(p_message => 'SUPPLIER SITE - Records Successfully Validated are '|| l_supsite_val_not_load_cnt, p_force => true);
      print_debug_msg(p_message => 'SUPPLIER SITE - Records Validated and Errored are '|| l_supsite_error_cnt, p_force => true);
      print_debug_msg(p_message => 'SUPPLIER SITE - Records Eligible for Validation but Untouched  are '|| l_supsite_eligible_cnt, p_force => true);            
      print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
      print_debug_msg(p_message => 'Total Validated Records - x_val_records - '|| x_val_records, p_force => true);
      print_debug_msg(p_message => 'Total UnValidated Records - x_inval_records - '|| x_inval_records, p_force => true);      
      print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);  
      
      print_out_msg(p_message => '--------------------------------------------------------------------------------------------');      
      print_out_msg(p_message => 'SUPPLIER - Records Successfully Validated are '|| l_sup_val_not_load_cnt);
      print_out_msg(p_message => 'SUPPLIER - Records Validated and Errored are '|| l_sup_error_cnt);
      print_out_msg(p_message => 'SUPPLIER - Records Eligible for Validation but Untouched  are '|| l_sup_eligible_cnt);
      print_out_msg(p_message => '----------------------');
      print_out_msg(p_message => 'SUPPLIER SITE - Records Successfully Validated are '|| l_supsite_val_not_load_cnt);
      print_out_msg(p_message => 'SUPPLIER SITE - Records Validated and Errored are '|| l_supsite_error_cnt);
      print_out_msg(p_message => 'SUPPLIER SITE - Records Eligible for Validation but Untouched  are '|| l_supsite_eligible_cnt);
      print_out_msg(p_message => '--------------------------------------------------------------------------------------------');
      print_out_msg(p_message => 'Total Validated Records - x_val_records - '|| x_val_records);
      print_out_msg(p_message => 'Total UnValidated Records - x_inval_records - '|| x_inval_records);      
      print_out_msg(p_message => '--------------------------------------------------------------------------------------------');                    


      --====================================================================================
         -- Error out the Untouched Supplier records though eligible
      --====================================================================================
      
      IF l_sup_eligible_cnt > 0 THEN
        BEGIN
          print_debug_msg(p_message => 'Erroring out the Untouched Supplier records though eligible', p_force => true);
        
          l_upd_cnt := 0;
      
          UPDATE XX_AP_SUPPLIER_STG
          SET SUPP_PROCESS_FLAG = gn_process_status_error
             ,SUPP_ERROR_FLAG = gc_process_error_flag
             ,SUPP_ERROR_MSG  = SUPP_ERROR_MSG||'This process is not validated though eligible. Pls. save the log of this Concurrent Program Request#'||fnd_global.conc_request_id||'  and inform to System Administrator.'
          WHERE SUPP_PROCESS_FLAG = gn_process_status_inprocess
            AND request_id = fnd_global.conc_request_id; 
                     
            l_upd_cnt := SQL%ROWCOUNT;      
            print_debug_msg(p_message => 'Set to Error for '||l_upd_cnt||' supplier records as these are untouched though eligible.', p_force => true);
            
        EXCEPTION
            WHEN OTHERS THEN
             l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
             print_debug_msg(p_message => 'ERROR: Updating the Supplier Staging table for untouched supplier records - '|| l_err_buff
                           , p_force => true);
             
             x_ret_code := '2';
             x_return_status := 'E';
             x_err_buf := l_err_buff;
             
             return;          
        END;         
      END IF;

      --====================================================================================
         -- Error out the Untouched Supplier Site records though eligible
      --====================================================================================
      IF l_supsite_eligible_cnt > 0 THEN
        BEGIN
          print_debug_msg(p_message => 'Erroring out the Untouched Supplier Site records though eligible', p_force => true);
        
          l_site_upd_cnt := 0;
      
          UPDATE XX_AP_SUPP_SITE_CONTACT_STG
          SET SUPP_SITE_PROCESS_FLAG = gn_process_status_error
             ,SUPP_SITE_ERROR_FLAG = gc_process_error_flag
             ,SUPP_SITE_ERROR_MSG  = SUPP_SITE_ERROR_MSG||'This site is not validated though eligible. Pls. save the log of this Concurrent Program Request#'||fnd_global.conc_request_id||'  and inform to System Administrator.'
          WHERE SUPP_SITE_PROCESS_FLAG = gn_process_status_inprocess
            AND request_id = fnd_global.conc_request_id;  
                     
            l_site_upd_cnt := SQL%ROWCOUNT;      
            print_debug_msg(p_message => 'Set to Error for '||l_site_upd_cnt||' supplier site records as these are untouched though eligible.', p_force => true);
            
        EXCEPTION
            WHEN OTHERS THEN
             l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
             print_debug_msg(p_message => 'ERROR: Updating the Supplier Site Staging table for untouched supplier site records - '|| l_err_buff
                           , p_force => true);
             
             x_ret_code := '2';
             x_return_status := 'E';
             x_err_buf := l_err_buff;
             
             return;          
        END;        
      END IF;               
    
  EXCEPTION
      WHEN OTHERS THEN
       l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
       print_debug_msg(p_message => 'ERROR: Exception in validate_records() API - '|| l_err_buff
                     , p_force => true);
       
       x_ret_code := '2';
       x_return_status := 'E';
       x_err_buf := l_err_buff;
 
END validate_records;


--+============================================================================+
--| Name          : load_vendors                                        |
--| Description   : This procedure will load the vendors into interface table  |
--|                   for the validated records in staging table               |
--|                                                                            |
--| Parameters    : N/A                                                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
   PROCEDURE load_vendors(
          x_processed_records OUT NUMBER
          ,x_unprocessed_records OUT NUMBER
          ,x_ret_code OUT NUMBER
          ,x_return_status OUT VARCHAR2
          ,x_err_buf OUT VARCHAR2
      )
   IS
--=========================================================================================
-- Variables Declaration used for getting the data into PL/SQL Table for processing
--=========================================================================================
      TYPE l_sup_tab IS TABLE OF XX_AP_SUPPLIER_STG%ROWTYPE
         INDEX BY BINARY_INTEGER;

      TYPE l_sup_site_cont_tab IS TABLE OF XX_AP_SUPP_SITE_CONTACT_STG%ROWTYPE
         INDEX BY BINARY_INTEGER;


--=================================================================
-- Declaring Local variables
--=================================================================
      l_supplier_type               l_sup_tab;
      l_sup_site                    l_sup_site_cont_tab;
      l_supplier_rec                ap_vendor_pub_pkg.r_vendor_rec_type;
      l_supplier_site_rec           ap_vendor_pub_pkg.r_vendor_site_rec_type;
      l_vendor_intf_id              NUMBER DEFAULT 0;
      l_vendor_site_intf_id         NUMBER DEFAULT 0;
      l_error_message               VARCHAR2 (2000) DEFAULT NULL;
      l_procedure                   VARCHAR2 (30) := 'LOAD_VENDORS';
      l_msg_data                    VARCHAR2 (2000) := NULL;
      l_msg_count                   NUMBER := 0;
      l_trans_count                 NUMBER := 0;
      lp_loopcont                   PLS_INTEGER := 0;
      lp_loopcnt                    PLS_INTEGER := 0;
      l_exception_msg               VARCHAR2 (1000);

      l_sup_processed_recs           NUMBER := 0;
      l_sup_unprocessed_recs         NUMBER := 0;
      l_supsite_processed_recs       NUMBER := 0;
      l_supsite_unprocessed_recs     NUMBER := 0;      
      l_ret_code                    NUMBER;
      l_return_status               VARCHAR2 (100);
      l_err_buff                    VARCHAR2 (4000);   

      l_sup_eligible_cnt    NUMBER := 0;
      l_sup_val_load_cnt    NUMBER := 0;
      l_sup_error_cnt       NUMBER := 0;
      l_sup_val_not_load_cnt NUMBER := 0;
      l_sup_ready_process   NUMBER := 0;
      l_supsite_eligible_cnt NUMBER := 0;
      l_supsite_val_load_cnt NUMBER := 0;
      l_supsite_error_cnt    NUMBER := 0;
      l_supsite_val_not_load_cnt NUMBER := 0;
      l_supsite_ready_process   NUMBER := 0;      

--==============================================================================
-- Cursor Declarations for Suppliers
--==============================================================================
      CURSOR c_supplier
      IS
         SELECT xas.*              
           FROM XX_AP_SUPPLIER_STG xas
          WHERE xas.SUPP_PROCESS_FLAG = gn_process_status_validated
            AND xas.request_id = gn_request_id;

--==============================================================================
-- Cursor Declarations for Supplier Sites
--==============================================================================
      CURSOR c_supplier_site (
         c_supplier_name      IN       VARCHAR2
      )
      IS
         SELECT xsup_site.*
           FROM XX_AP_SUPP_SITE_CONTACT_STG xsup_site
          WHERE xsup_site.SUPP_SITE_PROCESS_FLAG = gn_process_status_validated
            AND xsup_site.supplier_name = c_supplier_name
            AND xsup_site.request_id = gn_request_id
            ORDER BY address_name_prefix, address_purpose desc;

--==============================================================================
-- Cursor Declarations to get table statistics of Supplier Staging
--==============================================================================
      CURSOR c_sup_stats
      IS
          SELECT SUM(DECODE(SUPP_PROCESS_FLAG,2,1,0))    -- Eligible to Validate and Load
            ,SUM(DECODE(SUPP_PROCESS_FLAG,4,1,0))    -- Successfully Validated and Loaded
            ,SUM(DECODE(SUPP_PROCESS_FLAG,3,1,0))    -- Validated and Errored out
            ,SUM(DECODE(SUPP_PROCESS_FLAG,35,1,0))   -- Successfully Validated but not loaded
            ,SUM(DECODE(SUPP_PROCESS_FLAG,1,1,0))    -- Ready for Process
          FROM  XX_AP_SUPPLIER_STG
          WHERE  request_id = fnd_global.conc_request_id;

--==============================================================================
-- Cursor Declarations to get table statistics of Supplier Site Staging
--==============================================================================
      CURSOR c_sup_site_stats
      IS
          SELECT SUM(DECODE(SUPP_SITE_PROCESS_FLAG,2,1,0))    -- Eligible to Validate and Load
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,4,1,0))    -- Successfully Validated and Loaded
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,3,1,0))    -- Validated and Errored out
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,35,1,0))   -- Successfully Validated but not loaded
            ,SUM(DECODE(SUPP_SITE_PROCESS_FLAG,1,1,0))    -- Ready for Process
          FROM  XX_AP_SUPP_SITE_CONTACT_STG
          WHERE  request_id = fnd_global.conc_request_id;          
            
            

      l_sup_rec_exists              NUMBER (10) DEFAULT 0;
      l_sup_site_rec_exists         NUMBER (10) DEFAULT 0;
      
      l_process_status_flag         VARCHAR2(1);
      l_process_site_status_flag    VARCHAR2(1);

      l_vendor_id                   NUMBER;
      l_vendor_site_id              NUMBER;
      l_party_site_id               NUMBER;
      l_party_id                    NUMBER;
      l_vendor_site_code            VARCHAR2(50);
   BEGIN
      print_debug_msg(p_message=> gc_step||' load_vendors() - BEGIN'
                                        ,p_force=> FALSE);
                                        
      set_step ('Start of Process Records Using API');
      --==============================================================================
      -- Default Process Status Flag as N means No Error Exists
      --==============================================================================
      l_process_status_flag := 'N';
      l_process_site_status_flag := 'N';
      l_sup_rec_exists := 0;
      l_sup_site_rec_exists := 0;
      l_error_message := NULL;
      lp_loopcnt := 0;
      lp_loopcont := 0;
      
      l_ret_code   := 0;
      l_return_status := 'S';
      l_err_buff   := NULL;      

      OPEN c_supplier;

      LOOP
         FETCH c_supplier
         BULK COLLECT INTO l_supplier_type;

         IF l_supplier_type.COUNT > 0
         THEN
            print_debug_msg(p_message=> gc_step||' l_supplier_type records processing.'
                                        ,p_force=> FALSE);
           
            FOR l_idx IN l_supplier_type.FIRST .. l_supplier_type.LAST
            LOOP
               --==============================================================================
               -- Initialize the Variable to N for Each Supplier
               --==============================================================================
               l_process_status_flag := 'N';
               l_process_site_status_flag := 'N';
               l_error_message := NULL;
               gc_step := 'SUPINTF';
               l_sup_rec_exists := 0;
               l_sup_site_rec_exists := 0;
               l_vendor_id := NULL;
               l_party_id := NULL;
               l_vendor_site_id := NULL;
               l_party_site_id := NULL;

               print_debug_msg(p_message=> gc_step||' Create Flag of the supplier '||l_supplier_type (l_idx).supplier_name||' is - '||l_supplier_type (l_idx).create_flag
                                        ,p_force=> FALSE);               

               IF l_supplier_type (l_idx).create_flag = 'Y'
               THEN
                  --==============================================================================================
                  -- Calling the Vendor Interface Id for Passing it to Interface Table - Supplier Does Not Exists
                  --==============================================================================================
                  SELECT ap_suppliers_int_s.NEXTVAL
                    INTO l_vendor_intf_id
                    FROM SYS.DUAL;

                  --==============================================================================
                  -- Calling the Insertion of Data into standard interface table
                  --==============================================================================
                  IF l_process_status_flag = 'N'
                  THEN
                     print_debug_msg(p_message=> gc_step||' - Before inserting record into ap_suppliers_int with interface id -'||l_vendor_intf_id
                                        ,p_force=> FALSE);                    
                     BEGIN
                        INSERT INTO ap_suppliers_int
                                    (vendor_interface_id
                                    ,vendor_name
                                    ,vendor_type_lookup_code
                                    ,status
                                    ,customer_num
                                    ,one_time_flag
                                    ,federal_reportable_flag
                                    ,state_reportable_flag
                                    ,type_1099
                                    ,num_1099
                                    ,vat_registration_num
                                    ,organization_type_lookup_code
                                    ,tax_reporting_name
                                    ,tax_verification_date
                                    ,start_date_active
                                    ,created_by
                                    ,creation_date
                                    ,last_update_date
                                    ,last_updated_by
                                    )
                             VALUES (l_vendor_intf_id
                                    ,TRIM(UPPER(l_supplier_type (l_idx).supplier_name))
                                    ,l_supplier_type (l_idx).vendor_type_lookup_code
                                    ,g_process_status_new
                                    ,l_supplier_type (l_idx).customer_num
                                    ,l_supplier_type (l_idx).one_time_flag
                                    ,l_supplier_type (l_idx).federal_reportable_flag
                                    ,l_supplier_type (l_idx).state_reportable_flag
                                    ,l_supplier_type (l_idx).income_tax_type
                                    ,l_supplier_type (l_idx).tax_payer_id
                                    ,l_supplier_type (l_idx).tax_reg_num
                                    ,l_supplier_type (l_idx).organization_type_lookup_code
                                    ,l_supplier_type (l_idx).tax_reporting_name
                                    ,l_supplier_type (l_idx).tax_verification_date
                                    ,SYSDATE
                                    ,g_user_id
                                    ,SYSDATE
                                    ,SYSDATE
                                    ,g_user_id
                                    );
                        
                        set_step (   'Supplier Interface Inserted'
                                  || l_process_status_flag);
                        print_debug_msg(p_message=> gc_step||' - After successfully inserted the record for the supplier -'||l_supplier_type (l_idx).supplier_name
                                        ,p_force=> FALSE);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                      -- gc_error_status_flag := 'Y';
                        
                        l_process_status_flag := 'Y';
                        
                        l_error_message := SQLCODE || ' - '|| SQLERRM;
                        print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_type (l_idx).SUPPLIER_NAME||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message
                                        ,p_force=> TRUE);
                                                                                                       
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type (l_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,2000)
                                     ,p_error_message               => 'Error while Inserting Records in Inteface Table'|| SQLCODE || ' - '||l_error_message
                                     ,p_stage_col1                  => 'SUPPLIER_NAME'
                                     ,p_stage_val1                  => l_supplier_type (l_idx).SUPPLIER_NAME
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     ); 
                     END;

                     IF l_process_status_flag = 'N'
                     THEN
                        l_supplier_type (l_idx).SUPP_PROCESS_FLAG := gn_process_status_loaded;
                        
                        l_sup_processed_recs := l_sup_processed_recs + 1;
                        set_step ('Sup Stg Status P');
                     ELSIF l_process_status_flag = 'Y'
                     THEN
                        l_supplier_type (l_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
                        l_supplier_type (l_idx).SUPP_ERROR_FLAG   := gc_process_error_flag;
                        l_supplier_type (l_idx).SUPP_ERROR_MSG    := gc_error_msg;
                        
                        l_sup_unprocessed_recs := l_sup_unprocessed_recs + 1;                        
                        set_step ('Sup Stg Status E');
                     END IF;

                     --==============================================================================
                     -- Calling the Vendor Site Cursor for inserting into standard interface table
                     --==============================================================================
                     IF l_process_status_flag = 'N'
                     THEN
                        FOR l_sup_site_type IN c_supplier_site (l_supplier_type (l_idx).supplier_name)
                        LOOP
                           l_process_site_status_flag := 'N';
                           gc_step := 'SITEINTF';
                           lp_loopcnt :=   lp_loopcnt + 1;
                           l_vendor_site_code := '';

                           --==============================================================================
                           -- Calling the Vendor Site Interface Id for Passing it to Interface Table
                           --==============================================================================
                           SELECT ap_supplier_sites_int_s.NEXTVAL
                             INTO l_vendor_site_intf_id
                             FROM SYS.DUAL;

                           l_vendor_site_code :=  upper(l_sup_site_type.address_name_prefix)||l_vendor_site_intf_id;
                           IF   upper(l_sup_site_type.address_purpose) <> 'BOTH' THEN
                              l_vendor_site_code := l_vendor_site_code||upper(l_sup_site_type.address_purpose); 
                           END IF;
                           
                           print_debug_msg(p_message=> gc_step||' : l_vendor_site_code - '||l_vendor_site_code
                                        ,p_force=> TRUE);
                                        
                           BEGIN
                              INSERT INTO ap_supplier_sites_int
                                          (vendor_interface_id
                                          ,vendor_site_interface_id
                                          ,vendor_site_code
                                          ,address_line1
                                          ,address_line2
                                          ,address_line4					  
                                          ,city
                                          ,state
                                          ,zip
                                          ,country
                                          ,province
                                          ,phone
                                          ,fax
                                          ,fax_area_code
                                          ,area_code
                                          ,tax_reporting_site_flag
                                          ,terms_id
                                          ,invoice_currency_code
                                          ,payment_currency_code
                                          ,accts_pay_code_combination_id
                                          ,terms_date_basis
                                          ,purchasing_site_flag
                                          ,pay_site_flag
                                          ,org_id
                                          ,status
                                        -- ,ship_via_lookup_code
                                          ,freight_terms_lookup_code
                                          ,fob_lookup_code
                                          ,pay_group_lookup_code
                                          ,payment_priority
                                          ,pay_date_basis_lookup_code
                                          ,always_take_disc_flag
                                          ,hold_all_payments_flag
                                          --,hold_future_payments_flag
                                          ,attribute5                                          
                                          ,attribute6
                                          ,attribute8
                                          ,attribute14                                   
                                          ,match_option
                                          ,email_address
                                          ,primary_pay_site_flag
                                          ,duns_number
                                          ,tolerance_id
                                          ,bill_to_location_id
                                          ,ship_to_location_id
                                          ,create_debit_memo_flag
                                          ,created_by
                                          ,creation_date
                                          ,last_update_date
                                          ,last_updated_by
					  ,payment_method_lookup_code
                                          )                                        
                                   VALUES (l_vendor_intf_id
                                          ,l_vendor_site_intf_id
                                          ,l_vendor_site_code
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.address_line1)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.address_line2)))
					  ,TO_CHAR(l_sup_site_type.site_number)
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.city)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.state)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.postal_code)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.country_code)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.province)))
                                          ,TRIM(l_sup_site_type.phone_number)
                                          ,TRIM(l_sup_site_type.fax_number)
                                          ,l_sup_site_type.fax_area_code
                                          ,l_sup_site_type.phone_area_code
                                          ,l_sup_site_type.income_tax_rep_site
                                          ,l_sup_site_type.terms_id
                                          ,l_sup_site_type.invoice_currency
                                          ,l_sup_site_type.payment_currency
                                          ,l_sup_site_type.ccid
                                          ,l_sup_site_type.terms_date_basis_code
                                          ,l_sup_site_type.purchasing_site_flag
                                          ,l_sup_site_type.pay_site_flag
                                          ,l_sup_site_type.org_id
                                          ,g_process_status_new
                                        --  ,l_sup_site_type.ship_via_code
                                          ,l_sup_site_type.freight_terms
                                          ,l_sup_site_type.fob
                                          ,l_sup_site_type.pay_group_code
                                          ,l_sup_site_type.payment_priority
                                          ,l_sup_site_type.pay_date_basis_lookup_code
                                          ,l_sup_site_type.always_take_disc_flag
                                          ,l_sup_site_type.hold_from_payment
                                          -- ,l_sup_site_type.hold_future_payments_flag
                                          ,l_sup_site_type.duns_num
                                          ,l_sup_site_type.future_use
                                          ,l_sup_site_type.site_category
                                          ,l_sup_site_type.reference_num
                                        --  ,l_sup_site_type.related_pay_site
                                          ,l_sup_site_type.invoice_match_option
                                          ,l_sup_site_type.email_address
                                          ,l_sup_site_type.primary_pay_flag
                                          ,l_sup_site_type.duns_num
                                          ,l_sup_site_type.tolerance_id
                                          ,l_sup_site_type.bill_to_loc_id
                                          ,l_sup_site_type.ship_to_loc_id
                                          ,l_sup_site_type.create_deb_memo_frm_rts
                                          ,g_user_id
                                          ,SYSDATE
                                          ,SYSDATE
                                          ,g_user_id
					  ,l_sup_site_type.payment_method
                                          );

                              set_step (   'Supplier Site Interface Inserted'
                                        || l_process_status_flag
                                        || '-'
                                        || l_process_site_status_flag);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                  l_process_site_status_flag := 'Y';
                                  l_error_message := SQLCODE || ' - '|| SQLERRM;
                                  print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_type (l_idx).SUPPLIER_NAME||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message
                                                  ,p_force=> TRUE);                                 

                                  insert_error (p_program_step                => gc_step
                                               ,p_primary_key                 => l_supplier_type (l_idx).SUPPLIER_NAME
                                               ,p_error_code                  => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,2000)
                                               ,p_error_message               => 'Error while Inserting Records in Site Inteface Table'|| SQLCODE || ' - '||l_error_message
                                               ,p_stage_col1                  => 'SUPPLIER_NAME'
                                               ,p_stage_val1                  => l_supplier_type (l_idx).SUPPLIER_NAME
                                               ,p_stage_col2                  => NULL
                                               ,p_stage_val2                  => NULL
                                               ,p_table_name                  => g_sup_site_cont_table
                                               );                                     
                           END;

                           set_step (   'Supplier Site Interface Before Assigning'
                                     || l_process_status_flag
                                     || '-'
                                     || l_process_site_status_flag);
                           l_sup_site (lp_loopcnt).supplier_name := l_sup_site_type.supplier_name;          
                           l_sup_site (lp_loopcnt).vendor_site_code_int := l_vendor_site_code;
                           l_sup_site (lp_loopcnt).address_name_prefix := l_sup_site_type.address_name_prefix;
                           l_sup_site (lp_loopcnt).address_purpose := l_sup_site_type.address_purpose;
                           l_sup_site (lp_loopcnt).address_line1 := l_sup_site_type.address_line1;
                           l_sup_site (lp_loopcnt).address_line2 := l_sup_site_type.address_line2;
                           l_sup_site (lp_loopcnt).city := l_sup_site_type.city;
                           l_sup_site (lp_loopcnt).state := l_sup_site_type.state;
                           l_sup_site (lp_loopcnt).postal_code := l_sup_site_type.postal_code;
                           l_sup_site (lp_loopcnt).country := l_sup_site_type.country;
                           l_sup_site (lp_loopcnt).province := l_sup_site_type.province;
                           l_sup_site (lp_loopcnt).site_category := l_sup_site_type.site_category;                                                    
                           
                           set_step (   'Supplier Site Interface After Assigning'
                                     || l_process_status_flag
                                     || '-'
                                     || l_process_site_status_flag);

                           IF l_process_site_status_flag = 'N'
                           THEN
                              l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG := gn_process_status_loaded;
                              
                              l_supsite_processed_recs := l_supsite_processed_recs + 1;
                              set_step ('Sup Site Stg Status P');
                           ELSIF l_process_site_status_flag = 'Y'
                           THEN
                              l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG := gn_process_status_error;
                              l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_FLAG   := gc_process_error_flag;
                              l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG    := gc_error_msg;
                              
                              l_supsite_unprocessed_recs := l_supsite_unprocessed_recs + 1;
                              set_step ('Sup Site Stg Status E');
                           END IF;
                        END LOOP;   -- Vendor Site Loop
                     ELSE      -- l_process_status_flag = 'N' Before Vendor Site
                        FOR l_sup_site_type IN c_supplier_site (l_supplier_type (l_idx).supplier_name)
                        LOOP
                            lp_loopcnt :=   lp_loopcnt + 1;
                            l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG := gn_process_status_error;
                            l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_FLAG   := gc_process_error_flag;
                            l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG    := 'SUPPLIER ERROR - '||gc_error_msg;  
                            
                            l_supsite_unprocessed_recs := l_supsite_unprocessed_recs + 1;
                        END LOOP;
                     
                     END IF;   -- l_process_status_flag = 'N' Before Vendor Site
                                      
                  END IF;   -- l_process_status_flag := 'N'
               ELSE     -- IF l_supplier_type (l_idx).create_flag = 'Y'
               

                  -- Setting the Processed Flag
                  --
                  --IF l_process_status_flag = 'N'
                  --THEN
                     l_supplier_type (l_idx).SUPP_PROCESS_FLAG := gn_process_status_loaded;
                     set_step ('Sup Stg Status P');
                  --ELSIF l_process_status_flag = 'Y'
                  --THEN
                  --   l_supplier_type (l_idx).status := 'ERROR';
                   --  set_step ('Sup Stg Status E');
                  --END IF;


                  --==============================================================================
                  -- Calling the Vendor Site Cursor for inserting into standard interface table
                  --==============================================================================
                  IF l_process_status_flag = 'N'
                  THEN
                     FOR l_sup_site_type IN c_supplier_site (l_supplier_type (l_idx).supplier_name)
                     LOOP
                        l_process_site_status_flag := 'N';
                        gc_step := 'SITEINTF';
                        lp_loopcnt :=   lp_loopcnt + 1;
                        l_vendor_site_code := '';
                        
                           --==============================================================================
                           -- Calling the Vendor Site Interface Id for Passing it to Interface Table
                           --==============================================================================
                           SELECT ap_supplier_sites_int_s.NEXTVAL
                             INTO l_vendor_site_intf_id
                             FROM SYS.DUAL;

                           l_vendor_site_code :=  upper(l_sup_site_type.address_name_prefix||l_vendor_site_intf_id);
                           IF   upper(l_sup_site_type.address_purpose) <> 'BOTH' THEN
                              l_vendor_site_code := l_vendor_site_code||upper(l_sup_site_type.address_purpose); 
                           END IF;
                           
                           print_debug_msg(p_message=> gc_step||' : l_vendor_site_code - '||l_vendor_site_code
                                        ,p_force=> TRUE);
                                                                     
                           BEGIN
                             INSERT INTO ap_supplier_sites_int
                                          (vendor_id
                                          ,vendor_site_interface_id
                                          ,vendor_site_code
                                          ,address_line1
                                          ,address_line2
                                          ,address_line4
                                          ,city
                                          ,state
                                          ,zip
                                          ,country
                                          ,province
                                          ,phone
                                          ,fax
                                          ,fax_area_code
                                          ,area_code
                                          ,tax_reporting_site_flag
                                          ,terms_id
                                          ,invoice_currency_code
                                          ,payment_currency_code
                                          ,accts_pay_code_combination_id
                                          ,terms_date_basis
                                          ,purchasing_site_flag
                                          ,pay_site_flag
                                          ,org_id
                                          ,status
                                        -- ,ship_via_lookup_code
                                          ,freight_terms_lookup_code
                                          ,fob_lookup_code
                                          ,pay_group_lookup_code
                                          ,payment_priority
                                          ,pay_date_basis_lookup_code
                                          ,always_take_disc_flag
                                          ,hold_all_payments_flag
                                          --,hold_future_payments_flag
                                          ,attribute5
                                          ,attribute6
                                          ,attribute8                                    
                                          ,attribute14
                                          ,match_option
                                          ,email_address
                                          ,primary_pay_site_flag
                                          ,duns_number
                                          ,tolerance_id
                                          ,bill_to_location_id
                                          ,ship_to_location_id
                                          ,create_debit_memo_flag
                                          ,created_by
                                          ,creation_date
                                          ,last_update_date
                                          ,last_updated_by
					  ,payment_method_lookup_code
                                          )                                        
                                   VALUES (l_supplier_type (l_idx).vendor_id
                                          ,l_vendor_site_intf_id
                                          ,l_vendor_site_code
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.address_line1)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.address_line2)))
					  ,TO_CHAR(l_sup_site_type.site_number)
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.city)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.state)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.postal_code)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.country_code)))
                                          ,LTRIM(RTRIM(upper(l_sup_site_type.province)))
                                          ,TRIM(l_sup_site_type.phone_number)
                                          ,TRIM(l_sup_site_type.fax_number)
                                          ,l_sup_site_type.fax_area_code
                                          ,l_sup_site_type.phone_area_code
                                          ,l_sup_site_type.income_tax_rep_site
                                          ,l_sup_site_type.terms_id
                                          ,l_sup_site_type.invoice_currency
                                          ,l_sup_site_type.payment_currency
                                          ,l_sup_site_type.ccid
                                          ,l_sup_site_type.terms_date_basis_code
                                          ,l_sup_site_type.purchasing_site_flag
                                          ,l_sup_site_type.pay_site_flag
                                          ,l_sup_site_type.org_id
                                          ,g_process_status_new
                                        --  ,l_sup_site_type.ship_via_code
                                          ,l_sup_site_type.freight_terms
                                          ,l_sup_site_type.fob
                                          ,l_sup_site_type.pay_group_code
                                          ,l_sup_site_type.payment_priority
                                          ,l_sup_site_type.pay_date_basis_lookup_code
                                          ,l_sup_site_type.always_take_disc_flag
                                          ,l_sup_site_type.hold_from_payment
                                          -- ,l_sup_site_type.hold_future_payments_flag
                                          ,l_sup_site_type.duns_num
                                          ,l_sup_site_type.future_use
                                          ,l_sup_site_type.site_category
                                          ,l_sup_site_type.reference_num
                                          ,l_sup_site_type.invoice_match_option
                                          ,l_sup_site_type.email_address
                                          ,l_sup_site_type.primary_pay_flag
                                          ,l_sup_site_type.duns_num
                                          ,l_sup_site_type.tolerance_id
                                          ,l_sup_site_type.bill_to_loc_id
                                          ,l_sup_site_type.ship_to_loc_id
                                          ,l_sup_site_type.create_deb_memo_frm_rts
                                          ,g_user_id
                                          ,SYSDATE
                                          ,SYSDATE
                                          ,g_user_id
					  ,l_sup_site_type.payment_method
                                          );

                              set_step (   'Supplier Site Interface Inserted'
                                        || l_process_status_flag
                                        || '-'
                                        || l_process_site_status_flag);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                  l_process_site_status_flag := 'Y';
                                  l_error_message := SQLCODE || ' - '|| SQLERRM;
                                  print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_type (l_idx).SUPPLIER_NAME||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message
                                                  ,p_force=> TRUE);                                 

                                  insert_error (p_program_step                => gc_step
                                               ,p_primary_key                 => l_supplier_type (l_idx).SUPPLIER_NAME
                                               ,p_error_code                  => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,2000)
                                               ,p_error_message               => 'Error while Inserting Records in Site Inteface Table'|| SQLCODE || ' - '||l_error_message
                                               ,p_stage_col1                  => 'SUPPLIER_NAME'
                                               ,p_stage_val1                  => l_supplier_type (l_idx).SUPPLIER_NAME
                                               ,p_stage_col2                  => NULL
                                               ,p_stage_val2                  => NULL
                                               ,p_table_name                  => g_sup_site_cont_table
                                               );        
                           END;

                           set_step (   'Supplier Site Interface Before Assigning'
                                     || l_process_status_flag
                                     || '-'
                                     || l_process_site_status_flag);
                                     
                           l_sup_site (lp_loopcnt).supplier_name := l_sup_site_type.supplier_name;          
                           l_sup_site (lp_loopcnt).vendor_site_code_int := l_vendor_site_code;
                           l_sup_site (lp_loopcnt).address_name_prefix := l_sup_site_type.address_name_prefix;
                           l_sup_site (lp_loopcnt).address_purpose := l_sup_site_type.address_purpose;
                           l_sup_site (lp_loopcnt).address_line1 := l_sup_site_type.address_line1;
                           l_sup_site (lp_loopcnt).address_line2 := l_sup_site_type.address_line2;
                           l_sup_site (lp_loopcnt).city := l_sup_site_type.city;
                           l_sup_site (lp_loopcnt).state := l_sup_site_type.state;
                           l_sup_site (lp_loopcnt).postal_code := l_sup_site_type.postal_code;
                           l_sup_site (lp_loopcnt).country := l_sup_site_type.country;
                           l_sup_site (lp_loopcnt).province := l_sup_site_type.province;
                           l_sup_site (lp_loopcnt).site_category := l_sup_site_type.site_category;
                           

                           set_step ('Supplier Site Interface After Assigning'
                                     || l_process_status_flag
                                     || '-'
                                     || l_process_site_status_flag);

                           IF l_process_site_status_flag = 'N'
                           THEN
                              l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG := gn_process_status_loaded;
                              
                              l_supsite_processed_recs := l_supsite_processed_recs + 1;
                              set_step ('Sup Site Stg Status P');
                           ELSIF l_process_site_status_flag = 'Y'
                           THEN
                              l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG := gn_process_status_error;
                              l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_FLAG   := gc_process_error_flag;
                              l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG    := gc_error_msg;
                              
                              l_supsite_unprocessed_recs := l_supsite_unprocessed_recs + 1;
                              set_step ('Sup Site Stg Status E');
                           END IF;

                     END LOOP;   -- Supplier Site Loop
                  END IF;   -- l_process_status_flag = 'N' Before Starting Supplier Site               
              END IF;   -- IF l_supplier_type (l_idx).create_flag = 'Y'
            END LOOP;   -- l_supplier_type.FIRST .. l_supplier_type.LAST
         END IF;   -- l_supplier_type.COUNT > 0

         --==============================================================================
         -- For Doing the Bulk Update
         --=============================================================================
         IF l_supplier_type.COUNT > 0
         THEN
            set_step ('Supplier Staging Count');

            BEGIN
               FORALL l_idxs IN l_supplier_type.FIRST .. l_supplier_type.LAST
                  UPDATE XX_AP_SUPPLIER_STG
                     SET SUPP_PROCESS_FLAG = l_supplier_type (l_idxs).SUPP_PROCESS_FLAG
                   WHERE supplier_name = l_supplier_type (l_idxs).supplier_name
                     AND request_id = gn_request_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_status_flag := 'Y';
                  l_error_message :=    'When Others Exception '
                                     || SQLCODE
                                     || ' - '
                                     || SUBSTR (SQLERRM
                                               ,1
                                               ,3850
                                               );
            END;
         END IF;   -- l_supplier_type.COUNT For Bulk Update of Supplier

         IF l_sup_site.COUNT > 0
         THEN
            set_step ('Supplier Site Staging Count :');

            BEGIN
               FORALL l_idxss IN l_sup_site.FIRST .. l_sup_site.LAST   
                  UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                     SET SUPP_SITE_PROCESS_FLAG = l_sup_site (l_idxss).SUPP_SITE_PROCESS_FLAG
                        ,vendor_site_code_int = l_sup_site (l_idxss).vendor_site_code_int
                   WHERE address_name_prefix = l_sup_site (l_idxss).address_name_prefix
                     AND address_purpose = l_sup_site (l_idxss).address_purpose
                     AND address_line1 = l_sup_site (l_idxss).address_line1
                     AND (address_line2 IS NULL or address_line2 =   l_sup_site (l_idxss).address_line2)
                     AND city =   l_sup_site (l_idxss).city
                     AND (state IS NULL or state =   l_sup_site (l_idxss).state)
                     AND (province IS NULL or province = l_sup_site (l_idxss).province)
                     AND site_category = l_sup_site (l_idxss).site_category
                     AND supplier_name = l_sup_site (l_idxss).supplier_name                    
                     AND request_id = gn_request_id;
           --    END LOOP;      
               --      COMMIT;

            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_status_flag := 'Y';
                  set_step ('Supplier Site error :');
                  l_error_message :=    'When Others Exception '
                                     || SQLCODE
                                     || ' - '
                                     || SUBSTR (SQLERRM
                                               ,1
                                               ,3850
                                               );
            END;
            COMMIT;
         END IF;   -- l_sup_site_type.COUNT For Bulk Update of Sites

         EXIT WHEN c_supplier%NOTFOUND;
      END LOOP;   -- For Open c_supplier

      CLOSE c_supplier;

      l_supplier_type.DELETE;
      
                                             

     -- x_processed_records := l_sup_processed_recs + l_supsite_processed_recs;
     -- x_unprocessed_records := l_sup_unprocessed_recs + l_supsite_unprocessed_recs;
      x_ret_code := l_ret_code;
      x_return_status := l_return_status;
      x_err_buf := l_err_buff;

      l_sup_eligible_cnt := 0;
      l_sup_val_load_cnt := 0;
      l_sup_error_cnt := 0;
      l_sup_val_not_load_cnt := 0;
      l_sup_ready_process := 0;

      OPEN  c_sup_stats;
      FETCH c_sup_stats INTO l_sup_eligible_cnt, l_sup_val_load_cnt, l_sup_error_cnt, l_sup_val_not_load_cnt, l_sup_ready_process;
      CLOSE c_sup_stats;

      l_supsite_eligible_cnt := 0;
      l_supsite_val_load_cnt := 0;
      l_supsite_error_cnt := 0;
      l_supsite_val_not_load_cnt := 0;
      l_supsite_ready_process := 0;
      
      OPEN  c_sup_site_stats;
      FETCH c_sup_site_stats INTO l_supsite_eligible_cnt, l_supsite_val_load_cnt, l_supsite_error_cnt, l_supsite_val_not_load_cnt, l_supsite_ready_process;
      CLOSE c_sup_site_stats;

      x_processed_records := l_sup_val_load_cnt + l_supsite_val_load_cnt;
      x_unprocessed_records := l_sup_error_cnt + l_supsite_error_cnt + l_sup_val_not_load_cnt + l_supsite_val_not_load_cnt;

      print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);      
      print_debug_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated and successfully Loaded are '|| l_sup_val_load_cnt, p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated and Errored are '|| l_sup_error_cnt, p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated Successfully but not loaded are '|| l_sup_val_not_load_cnt, p_force => true);
      print_debug_msg(p_message => '----------------------', p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated and successfully Loaded are '|| l_supsite_val_load_cnt, p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated and Errored are '|| l_supsite_error_cnt, p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated Successfully but not loaded are '|| l_supsite_val_not_load_cnt, p_force => true);
      print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - Total Processed Records are '|| x_processed_records, p_force => true);
      print_debug_msg(p_message => 'After Load Vendors - Total UnProcessed Records are '|| x_unprocessed_records, p_force => true);                  
      print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true); 
      
      
      print_out_msg(p_message => '--------------------------------------------------------------------------------------------');      
      print_out_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated and successfully Loaded are '|| l_sup_val_load_cnt);
      print_out_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated and Errored are '|| l_sup_error_cnt);
      print_out_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated Successfully but not loaded are '|| l_sup_val_not_load_cnt);
      print_out_msg(p_message => '----------------------');
      print_out_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated and successfully Loaded are '|| l_supsite_val_load_cnt);
      print_out_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated and Errored are '|| l_supsite_error_cnt);
      print_out_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated Successfully but not loaded are '|| l_supsite_val_not_load_cnt);
      print_out_msg(p_message => '--------------------------------------------------------------------------------------------');
      print_out_msg(p_message => 'After Load Vendors - Total Processed Records are '|| x_processed_records);
      print_out_msg(p_message => 'After Load Vendors - Total UnProcessed Records are '|| x_unprocessed_records);                  
      print_out_msg(p_message => '--------------------------------------------------------------------------------------------');        

      /**
      print_debug_msg(p_message => 'Processed Supplier Records - l_sup_processed_recs - '|| l_sup_processed_recs
                    , p_force => true);
      print_debug_msg(p_message => 'Processed Supplier Site Records - l_supsite_processed_recs - '|| l_supsite_processed_recs
                    , p_force => true);
      print_debug_msg(p_message => 'UnProcessed Supplier Records - l_sup_unprocessed_recs - '|| l_sup_unprocessed_recs
                    , p_force => true);
      print_debug_msg(p_message => 'UnProcessed Supplier Site Records - l_supsite_unprocessed_recs - '|| l_supsite_unprocessed_recs
                    , p_force => true);
      print_debug_msg(p_message => 'Total Processed Records - x_processed_records - '|| x_processed_records
                    , p_force => true);
      print_debug_msg(p_message => 'Total UnProcessed Records - x_unprocessed_records - '|| x_unprocessed_records
                    , p_force => true); 

      print_out_msg(p_message => '----------------------------------------------------------------------');
      print_out_msg(p_message => 'Processed Supplier Records are '|| l_sup_processed_recs);
      print_out_msg(p_message => 'Processed Supplier Site Records are '|| l_supsite_processed_recs);
      print_out_msg(p_message => 'UnProcessed Supplier Records are '|| l_sup_unprocessed_recs);
      print_out_msg(p_message => 'UnProcessed Supplier Site Records are '|| l_supsite_unprocessed_recs);
      print_out_msg(p_message => 'Total Processed Records are '|| x_processed_records);
      print_out_msg(p_message => 'Total UnProcessed Records are '|| x_unprocessed_records);
      print_out_msg(p_message => '----------------------------------------------------------------------');    
      **/     
      COMMIT;
      
   EXCEPTION
      WHEN OTHERS
      THEN
                        gc_error_status_flag := 'Y';
                        l_error_message := gc_step||'EXCEPTION: ('
                                                     || g_package_name
                                                     || '.'
                                                     || l_procedure
                                                     || '-'
                                                     || gc_step
                                                     || ') '
                                                     || SQLERRM;
                        print_debug_msg(p_message=> l_error_message
                                        ,p_force=> TRUE);
                        
                         /**                                                                              
                        insert_error (p_program_step                => gc_step
                                     ,p_primary_key                 => l_supplier_type (l_idx).SUPPLIER_NAME
                                     ,p_error_code                  => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (SQLERRM,1,2000)
                                     ,p_error_message               => 'Error while Inserting Records in Inteface Table'|| SQLCODE || ' - '||l_error_message
                                     ,p_stage_col1                  => 'SUPPLIER_NAME'
                                     ,p_stage_val1                  => l_supplier_type (l_idx).SUPPLIER_NAME
                                     ,p_stage_col2                  => NULL
                                     ,p_stage_val2                  => NULL
                                     ,p_table_name                  => g_sup_table
                                     );     
                         **/ 
                       x_ret_code := 1;
                       x_return_status := 'E';
                       x_err_buf := l_error_message;                                                                                                   
   END load_vendors;

    PROCEDURE xx_supp_dff
    IS
    
    v_tst varchar2(1);
    
    CURSOR C1 IS
    SELECT
          vendor_site_id
         ,rowid drowid 
         ,LEAD_TIME                           
         ,BACK_ORDER_FLAG                     
         ,delivery_policy_dr                  
         ,min_prepaid_code_dr                    
         ,VENDOR_MIN_AMT                      
         ,supplier_ship_to_dr                    
         ,inventory_type_code_dr                 
         ,vertical_mrkt_ind_dr             
         ,ALLOW_AUTO_RECEIPT                  
         ,MASTER_VENDOR_ID                    
         ,PI_PACK_YEAR                        
         ,OD_DATE_SIGNED                      
         ,VENDOR_DATE_SIGNED                  
         ,DEDUCT_FROM_INV_FLAG                
         ,COMBINE_PICK_TICKET                 
         ,NEW_STORE_FLAG                        
         ,new_store_temrs_dr                      
         ,SEASONAL_FLAG                         
         ,START_DATE                            
         ,END_DATE                              
         ,seasonal_terms_dr                        
         ,LATE_SHIP_FLAG                        
         ,EDI_850                               
         ,EDI_860                               
         ,EDI_855                               
         ,EDI_856                               
         ,EDI_846                               
         ,EDI_810                               
         ,EDI_832                               
         ,EDI_820                               
         ,EDI_861                               
         ,edi_852_dr                              
         ,edi_distribution_dr                    
         ,rtv_option_dr                         
         ,rtv_frt_pmt_method_dr                  
         ,PERMANENT_RGA                       
         ,DESTROY_ALLOW_AMT                   
         ,payment_Frequency_dr                   
         ,MIN_RETURN_QTY                      
         ,MIN_RETURN_AMOUNT                   
         ,DAMAGE_DESTROY_LIMIT                
         ,RTV_INSTRUCTIONS                    
         ,ADDNL_RTV_INSTRUCTIONS              
         ,RGA_MARKED_FLAG                     
         ,REMOVE_PRICE_STICKER_FLAG           
         ,CONTACT_SUPPLIER_FOR_RGA            
         ,DESTROY_FLAG                        
         ,SERIAL_REQUIRED_FLAG                
         ,obsolete_item_dr                      
         ,OBSOLETE_ALLOW_PERNTG               
         ,OBSOLETE_DAYS                       
         ,RTV_RELATED_SITE                    
      FROM XX_AP_SUPP_SITE_CONTACT_STG
     WHERE supp_site_Process_Flag=7
       AND NVL(dff_process_Flag,'N')='N'
       AND PROCESS_FLAG = 'I';
    
    v_error_flag        VARCHAR2(1);
    v_kff_id    NUMBER;
    BEGIN
    
      FOR cur IN C1 LOOP
    
        v_error_Flag:='N';
    
        BEGIN
    
          SELECT xxfin.XX_PO_VENDOR_SITES_KFF_S.nextval INTO v_kff_id FROM DUAL;
    
          INSERT 
            INTO xx_po_vendor_sites_kff
          (     VS_KFF_ID          ,                       
                STRUCTURE_ID       ,                       
                ENABLED_FLAG       ,                       
                SUMMARY_FLAG       ,                       
                START_DATE_ACTIVE  ,                                            
                CREATED_BY         ,                       
                CREATION_DATE      ,                       
                LAST_UPDATED_BY    ,                       
                LAST_UPDATE_DATE   ,                       
                SEGMENT1           ,                    
                SEGMENT2           ,                    
                SEGMENT3           ,                    
                SEGMENT4           ,                    
                SEGMENT5           ,                    
                SEGMENT6           ,                    
                SEGMENT7           ,                    
                SEGMENT8           ,                    
                SEGMENT9           ,                    
                SEGMENT13          ,                    
                SEGMENT14          ,                    
                SEGMENT15          ,                    
                SEGMENT16          ,                    
                SEGMENT17          ,                    
                SEGMENT19          
           )     
          VALUES  
                (       v_kff_id        ,
                        101             ,
                        'Y'             ,                    
                        'N'              ,                    
                        SYSDATE         ,
                        fnd_global.user_id ,                    
                        SYSDATE      ,                    
                        fnd_global.user_id,                    
                        SYSDATE   ,                    
                        cur.LEAD_TIME   ,                        
                        cur.BACK_ORDER_FLAG                     ,
                        cur.delivery_policy_dr                  ,
                        cur.min_prepaid_code_dr                 ,   
                        cur.VENDOR_MIN_AMT                     , 
                        cur.supplier_ship_to_dr                ,    
                        cur.inventory_type_code_dr             ,    
                        cur.vertical_mrkt_ind_dr            , 
                        cur.ALLOW_AUTO_RECEIPT   ,
                                cur.MASTER_VENDOR_ID      ,              
                        cur.PI_PACK_YEAR           ,            
                        TO_CHAR(cur.OD_DATE_SIGNED,'DD-MON-YY')  ,
                        TO_CHAR(cur.VENDOR_DATE_SIGNED,'DD-MON-YY'),                  
                        cur.DEDUCT_FROM_INV_FLAG ,               
                        cur.COMBINE_PICK_TICKET   
                );
    
        UPDATE ap_supplier_sites_all
           SET attribute10=v_kff_id
         WHERE vendor_site_id=cur.vendor_site_id;
    
        EXCEPTION
          WHEN others THEN
        v_error_flag:='Y';
        END;
    
        BEGIN
          SELECT xxfin.XX_PO_VENDOR_SITES_KFF_S.nextval INTO v_kff_id FROM DUAL;
          INSERT 
            INTO xx_po_vendor_sites_kff
          (     VS_KFF_ID          ,                       
                STRUCTURE_ID       ,                       
                ENABLED_FLAG       ,                       
                SUMMARY_FLAG       ,                       
                START_DATE_ACTIVE  ,                                            
                CREATED_BY         ,                       
                CREATION_DATE      ,                       
                LAST_UPDATED_BY    ,                       
                LAST_UPDATE_DATE   ,                       
                SEGMENT20           ,                    
                SEGMENT21          ,                    
                SEGMENT22          ,                    
                SEGMENT23          ,                    
                SEGMENT24          ,                    
                SEGMENT25          ,                    
                SEGMENT26          ,                    
                SEGMENT27          ,                    
                SEGMENT28          ,                    
                SEGMENT29          ,                    
                SEGMENT30          ,                    
                SEGMENT31          ,                    
                SEGMENT32          ,                    
                SEGMENT33          ,                    
                SEGMENT34          ,
                SEGMENT35          ,
                SEGMENT36          ,
                SEGMENT37          
           )     
          VALUES  
                (       v_kff_id        ,
                        50350           ,
                        'Y'             ,                    
                        'N'              ,                    
                        SYSDATE         ,
                        fnd_global.user_id ,                    
                        SYSDATE      ,                    
                        fnd_global.user_id,                    
                        SYSDATE   ,                    
                        cur.NEW_STORE_FLAG   ,                     
                        cur.new_store_temrs_dr,                      
                        cur.SEASONAL_FLAG     ,                    
                        cur.START_DATE        ,                    
                        cur.END_DATE          ,                    
                        cur.seasonal_terms_dr ,                       
                        cur.LATE_SHIP_FLAG    ,                    
                        cur.EDI_850           ,                    
                        cur.EDI_860           ,                    
                        cur.EDI_855           ,                    
                        cur.EDI_856           ,                    
                        cur.EDI_846           ,                    
                        cur.EDI_810     ,                       
                        cur.EDI_832      ,                         
                        cur.EDI_820      ,                         
                        cur.EDI_861      ,                         
                        cur.edi_852_dr   ,                           
                        cur.edi_distribution_dr                
                );
        UPDATE ap_supplier_sites_all
           SET attribute11=v_kff_id
         WHERE vendor_site_id=cur.vendor_site_id;
    
        EXCEPTION
          WHEN others THEN
        v_error_flag:='Y';
        END;
    
        BEGIN
          SELECT xxfin.XX_PO_VENDOR_SITES_KFF_S.nextval INTO v_kff_id FROM DUAL;
          INSERT 
            INTO xx_po_vendor_sites_kff
          (     VS_KFF_ID          ,                       
                STRUCTURE_ID       ,                       
                ENABLED_FLAG       ,                       
                SUMMARY_FLAG       ,                       
                START_DATE_ACTIVE  ,                                            
                CREATED_BY         ,                       
                CREATION_DATE      ,                       
                LAST_UPDATED_BY    ,                       
                LAST_UPDATE_DATE   ,                       
                SEGMENT40           ,                    
                SEGMENT41          ,                    
                SEGMENT42          ,                    
                SEGMENT43          ,                    
                SEGMENT44          ,                    
                SEGMENT45          ,                    
                SEGMENT46          ,                    
                SEGMENT47          ,                    
                SEGMENT48          ,                    
                SEGMENT49          ,                    
                SEGMENT50          ,                    
                SEGMENT51          ,                    
                SEGMENT52          ,                    
                SEGMENT53          ,                    
                SEGMENT54          ,
                SEGMENT55          ,
                SEGMENT56          ,
                SEGMENT57          ,
                SEGMENT58          
           )     
          VALUES  
                (       v_kff_id        ,
                        50351           ,
                        'Y'             ,                    
                        'N'              ,                    
                        SYSDATE         ,
                        fnd_global.user_id ,                    
                        SYSDATE      ,                    
                        fnd_global.user_id,                    
                        SYSDATE   ,                    
                        cur.rtv_option_dr            ,             
                        cur.rtv_frt_pmt_method_dr    ,              
                        cur.PERMANENT_RGA            ,           
                        cur.DESTROY_ALLOW_AMT        ,           
                        cur.payment_Frequency_dr     ,              
                        cur.MIN_RETURN_QTY           ,           
                        cur.MIN_RETURN_AMOUNT        ,           
                        cur.DAMAGE_DESTROY_LIMIT     ,           
                        cur.RTV_INSTRUCTIONS         ,           
                        cur.ADDNL_RTV_INSTRUCTIONS   ,           
                        cur.RGA_MARKED_FLAG           ,          
                        cur.REMOVE_PRICE_STICKER_FLAG ,          
                        cur.CONTACT_SUPPLIER_FOR_RGA  ,          
                        cur.DESTROY_FLAG              ,          
                        cur.SERIAL_REQUIRED_FLAG      ,          
                        cur.obsolete_item_dr          ,            
                        cur.OBSOLETE_ALLOW_PERNTG     ,          
                        cur.OBSOLETE_DAYS             ,          
                        cur.RTV_RELATED_SITE                    
                );
        UPDATE ap_supplier_sites_all
           SET attribute12=v_kff_id
         WHERE vendor_site_id=cur.vendor_site_id;
    
        EXCEPTION
          WHEN others THEN
        v_error_flag:='Y';
        END;
    
        IF v_error_Flag='Y' THEN
    
           UPDATE XX_AP_SUPP_SITE_CONTACT_STG
              SET dff_process_Flag='E'
            WHERE rowid=cur.drowid;
        ELSE
    
           UPDATE XX_AP_SUPP_SITE_CONTACT_STG
              SET dff_process_Flag='Y'
            WHERE rowid=cur.drowid;
        END IF;
        COMMIT; 
    
      END LOOP;
    
    END xx_supp_dff;
    
    
    FUNCTION insert_bus_class ( p_party_id IN NUMBER
                           ,p_bus_code IN VARCHAR2
                           ,p_attribute IN VARCHAR2                             
                           ,p_vendor_id IN NUMBER
                          )
    RETURN VARCHAR2
                         
    IS 
    
    v_class_id  NUMBER;
    
    BEGIN
      
     
      SELECT POS_BUS_CLASS_ATTR_S.nextval
        INTO v_class_id
        FROM DUAL;
    
      INSERT
        INTO pos_bus_class_attr
           ( classification_id
        ,party_id
        ,lookup_type
        ,lookup_code
        ,start_date_active
        ,status
        ,ext_attr_1
        ,class_status
        ,created_by
        ,creation_date
        ,last_updated_by
        ,last_update_date
        ,vendor_id
        )
      VALUES
          (  v_class_id
        ,p_party_id
        ,'POS_BUSINESS_CLASSIFICATIONS'
        ,p_bus_code
        ,SYSDATE
        ,'A'
        ,p_attribute
        ,'APPROVED'
        ,fnd_global.user_id
        ,SYSDATE
        ,fnd_global.user_id
        ,SYSDATE
        ,p_vendor_id
          );
          
        g_ins_bus_class := 'Y';  -- -- This is used to check that if any record inserted or not.
        
      RETURN('Y');
    EXCEPTION
      WHEN others THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in while inserting business classification :'||TO_CHAR(p_vendor_id)||','||p_bus_code||','||SQLERRM);
        RETURN('N');
    END insert_bus_class;
    
    PROCEDURE process_bus_class
    IS
    
    CURSOR C1 
    IS
    SELECT
       vendor_id
      ,rowid drowid
      ,party_id
      ,MBE                                  
      ,NMSDC                                
      ,WBE                                  
      ,WBENC                                
      ,VOB                                  
      ,DOD_OR_VA                            
      ,DOE                                  
      ,USBLN                                
      ,LGBT                                 
      ,NGLCC                                
      ,NIB_NISH_ABILITY_ONE                 
      ,FOREIGN_OWNED                        
      ,SB                                   
      ,SAM                                  
      ,SBA                                  
      ,SBC                                  
      ,SDBE                                 
      ,SBA8_A                               
      ,HUBZ                                 
      ,WOSB                                 
      ,WSBE                                 
      ,EDWOSB                               
      ,VOSB                                 
      ,SDVOSB                               
      ,HBCU_MI                              
      ,AND_A                                
      ,IND                                  
      ,OWNERSHIP_CLASSIFICATION             
     FROM XX_AP_SUPPLIER_STG
    WHERE SUPP_PROCESS_FLAG=7
      AND PROCESS_FLAG = 'I'
      AND NVL(BUSS_CLASS_PROCESS_FLAG,'N')='N'
      AND (    MBE IS NOT NULL
        OR NMSDC IS NOT NULL                               
        OR WBE   IS NOT NULL                              
        OR WBENC IS NOT NULL                               
        OR VOB   IS NOT NULL                                
        OR DOD_OR_VA  IS NOT NULL                          
        OR DOE   IS NOT NULL                               
        OR USBLN IS NOT NULL                              
        OR LGBT  IS NOT NULL                               
        OR NGLCC  IS NOT NULL                              
        OR NIB_NISH_ABILITY_ONE  IS NOT NULL               
        OR FOREIGN_OWNED IS NOT NULL                       
        OR SB   IS NOT NULL                                
        OR SAM  IS NOT NULL                                
        OR SBA  IS NOT NULL                                
        OR SBC  IS NOT NULL                                
        OR SDBE IS NOT NULL                                
        OR SBA8_A  IS NOT NULL                             
        OR HUBZ    IS NOT NULL                             
        OR WOSB    IS NOT NULL                             
        OR WSBE    IS NOT NULL                             
        OR EDWOSB  IS NOT NULL                             
        OR VOSB    IS NOT NULL                            
        OR SDVOSB  IS NOT NULL                             
        OR HBCU_MI IS NOT NULL                            
        OR AND_A   IS NOT NULL                             
        OR IND     IS NOT NULL                             
        OR OWNERSHIP_CLASSIFICATION  IS NOT NULL
          );  
    
    v_buss_flag VARCHAR2(1);
    v_error_Flag VARCHAR2(1);
    
    BEGIN
    
      FOR cur IN C1 LOOP
    
        v_error_Flag:='N';
        g_ins_bus_class := 'N';
     
        IF cur.mbe IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'MBE',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;    
     
        IF cur.nmsdc IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'NMSDC',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;              
    
        IF cur.wbe IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'WBE',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;              
    
        IF cur.wbenc IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'WBENC',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;              
     
        IF cur.vob IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'VOB',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;   
    
        IF cur.dod_or_va IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'DODVA',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;    
    
        IF cur.doe IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'DOE',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;  
    
    
        IF cur.usbln IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'USBLN',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
    
        IF cur.lgbt IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'LGBT',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.nglcc IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'NGLCC',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
                               
    
        IF cur.NIB_NISH_ABILITY_ONE IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'NIBNISHABLTY',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
      
        IF cur.FOREIGN_OWNED IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'FOB',cur.foreign_owned,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.sb IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SB',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.sam IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SAMGOV',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.sba IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SBA',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.sbc IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SBC',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.sdbe IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SDBE',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.SBA8_A IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SBA8A',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;               
                                    
        IF cur.hubz IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'HUBZONE',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.wosb IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'WOSB',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL;                               
    
        IF cur.wsbe IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'WSBE',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.EDWOSB IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'EDWOSB',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.vosb IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'VOSB',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
                                  
    
        IF cur.SDVOSB IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'SDVOSB',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.HBCU_MI IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'HBCUMI',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
    
        IF cur.AND_A IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'ANC',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.ind IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'IND',NULL,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
    
        v_buss_Flag:=NULL; 
    
        IF cur.OWNERSHIP_CLASSIFICATION IS NOT NULL THEN
    
           v_buss_Flag:=insert_bus_class(cur.party_id,'MINORITY_OWNED',cur.ownership_classification,cur.vendor_id);
           
           IF v_buss_Flag='N' THEN
          v_error_flag:='Y';
           END IF;
    
        END IF;   
        
        -- Added this code in SIT test -- 1.1
        -- If any one record (using insert_bus_class()API above) inserted for A supplier then invoke this API.. 
        IF g_ins_bus_class = 'Y' THEN
            print_debug_msg(p_message => 'Invoking the API pos_supp_classification_pkg.synchronize_class_tca_to_po() to synch the Business Classifications', p_force => false);
            BEGIN
                pos_supp_classification_pkg.synchronize_class_tca_to_po(cur.party_id,cur.vendor_id);          
            END;        
            print_debug_msg(p_message => 'Successfully completed the execution of API pos_supp_classification_pkg.synchronize_class_tca_to_po() to synch the Business Classifications', p_force => false);
        END IF;
   
    
        IF v_error_flag='N' THEN

     
           UPDATE XX_AP_SUPPLIER_STG
          SET BUSS_CLASS_PROCESS_FLAG='Y'
        WHERE rowid=cur.drowid;


        ELSE
    
           UPDATE XX_AP_SUPPLIER_STG
          SET BUSS_CLASS_PROCESS_FLAG='E'
        WHERE rowid=cur.drowid;
    
        END IF;
        COMMIT;
    END LOOP;
    EXCEPTION
      WHEN others THEN
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in processing business classification :'||SQLERRM);
    END process_bus_class;   
    
    
    PROCEDURE post_update_defaults
    AS
    
    ln_vendor_id            NUMBER;
    ln_party_id             NUMBER;
    ln_obj_ver_no           NUMBER;
    
    ln_vend_id              NUMBER;
    ln_vend_site_id         NUMBER;
    ln_party_site_ID        NUMBER;
    ln_location_id	    NUMBER;
    ln_org_id               NUMBER;
    lc_err_flag             VARCHAR2(1):='N';
    lc_site_err_flag        VARCHAR2(1):='N';
    l_vend_site_err_msg     VARCHAR2(2000);

    
    
    CURSOR c_supp_tab
    IS
    SELECT *
      FROM XX_AP_SUPPLIER_STG
     WHERE CREATE_FLAG = 'Y'
       AND SUPP_PROCESS_FLAG ='4'
       AND PROCESS_FLAG = 'I';
    
    CURSOR c_supp_site_tab
    IS
    SELECT * 
      FROM XX_AP_SUPP_SITE_CONTACT_STG
     WHERE SUPP_SITE_PROCESS_FLAG = 4
       AND PROCESS_FLAG = 'I';
    
    
    BEGIN
    /* Loop for CREATE_FLAG = 'Y'*/
    FOR r_supp_tab IN c_supp_tab
    LOOP
    lc_err_flag :='N';
    print_debug_msg(p_message => ' IN r_supp_tab LOOP :', p_force => true);
     BEGIN
     SELECT vendor_id,party_id
       INTO ln_vendor_id,ln_party_id
       FROM ap_suppliers
      WHERE vendor_name = r_supp_tab.supplier_name;
     EXCEPTION
     WHEN OTHERS THEN 
     lc_err_flag := 'Y';
      UPDATE XX_AP_SUPPLIER_STG
            SET SUPP_PROCESS_FLAG = 6,
                SUPP_ERROR_MSG = substr(SUPP_ERROR_MSG||' : '||r_supp_tab.supplier_name||' Not found in base tables ',1,3999)
          WHERE supplier_name = r_supp_tab.supplier_name
            AND PROCESS_FLAG = 'I';
     print_debug_msg(p_message => ' EXCEPTION in select vendor_id:'||SQLERRM, p_force => true);
     END;
     IF lc_err_flag <> 'Y'
     THEN
     BEGIN
     SELECT object_version_number 
       INTO ln_obj_ver_no
       FROM hz_parties
      WHERE party_id = ln_party_id;
     EXCEPTION
     WHEN OTHERS THEN  
     print_debug_msg(p_message => ' EXCEPTION in select object_version_number:'||SQLERRM, p_force => true);
     END;
       BEGIN
        UPDATE XX_AP_SUPPLIER_STG
           SET SUPP_PROCESS_FLAG    = 7,
               VENDOR_ID            = ln_vendor_id,
               PARTY_ID             = ln_party_id,
               OBJECT_VERSION_NO    = ln_obj_ver_no
         WHERE supplier_name = r_supp_tab.supplier_name
           AND PROCESS_FLAG = 'I';
       EXCEPTION
       WHEN OTHERS THEN 
       print_debug_msg(p_message => ' EXCEPTION in UPDATE XX_AP_SUPPLIER_STG :'||SQLERRM, p_force => true);
         UPDATE XX_AP_SUPPLIER_STG
            SET SUPP_PROCESS_FLAG = 6,
                SUPP_ERROR_MSG = substr(SUPP_ERROR_MSG||' : '||r_supp_tab.supplier_name||' Not found in base tables ',1,3999)
          WHERE supplier_name = r_supp_tab.supplier_name
            AND PROCESS_FLAG = 'I';
       END;
    END IF;

    COMMIT;
    END LOOP;
    /* END Loop for CREATE_FLAG = 'Y'*/
    
    /* LOOP for r_supp_site_tab cusrsor */
    FOR r_supp_site_tab IN c_supp_site_tab
    LOOP
      lc_site_err_flag :='N';
      ln_vend_site_id :='';
      ln_party_site_ID :='';
      ln_location_id:=NULL;
      print_debug_msg(p_message => 'IN LOOP r_supp_site_tab', p_force => true);
      BEGIN
     SELECT VENDOR_ID
       INTO ln_vend_id
       FROM ap_suppliers
      WHERE VENDOR_NAME = r_supp_site_tab.supplier_name;
     EXCEPTION
     WHEN OTHERS THEN 
      lc_site_err_flag := 'Y';
       UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                 SET SUPP_SITE_PROCESS_FLAG =6,
                     SUPP_SITE_ERROR_FLAG = 'E',
                     SUPP_SITE_ERROR_MSG = substr(SUPP_SITE_ERROR_MSG||': vendor id not found in base table :'||r_supp_site_tab.supplier_name,1,3999)
              WHERE supplier_name = r_supp_site_tab.supplier_name
                AND vendor_site_code_int = r_supp_site_tab.vendor_site_code_int
                AND PROCESS_FLAG = 'I';
                COMMIT;
     print_debug_msg(p_message => 'Error in deriving ln_vend_id'||SQLERRM, p_force => true);
     END;    
      print_debug_msg(p_message => 'ln_vend_id :'||ln_vend_id, p_force => true);
    IF lc_site_err_flag <> 'Y'
    THEN
            BEGIN
            SELECT VENDOR_SITE_ID,PARTY_SITE_ID,org_id,location_id
              INTO ln_vend_site_id,ln_party_site_ID,ln_org_id,ln_location_id
              FROM ap_supplier_sites_all
             WHERE vendor_id = ln_vend_id
               AND vendor_site_code = r_supp_site_tab.vendor_site_code_int;
            EXCEPTION
            WHEN OTHERS
            THEN
              ln_vend_site_id := '-1';
              ln_party_site_ID :='-1';
            END;
             print_debug_msg(p_message => 'ln_vend_site_id'||ln_vend_site_id, p_force => true);
             print_debug_msg(p_message => 'ln_party_site_ID'||ln_party_site_ID, p_force => true);
              IF ln_vend_site_id !=  '-1'
              THEN
                      BEGIN
                      UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                         SET VENDOR_ID      = ln_vend_id,
                             VENDOR_SITE_ID =ln_vend_site_id,
                             PARTY_SITE_ID  = ln_party_site_ID,
                             ORG_ID         = ln_org_id,
			     location_id    =ln_location_id,
                             SUPP_SITE_PROCESS_FLAG =7
                      WHERE supplier_name = r_supp_site_tab.supplier_name
                        AND vendor_site_code_int = r_supp_site_tab.vendor_site_code_int
                        AND PROCESS_FLAG = 'I';
                    EXCEPTION
                    WHEN OTHERS THEN
                     print_debug_msg(p_message => ' ERROR IN UPDATE XX_AP_SUPP_SITE_CONTACT_STG :'||SQLERRM, p_force => true);
                    END;
            ELSE
              l_vend_site_err_msg := 'vendor Site is not found for code:'||r_supp_site_tab.vendor_site_code_int||'. It seems supplier site failed in Supplier Site Open interface Import, pls. check the output of CP.';
              
              UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                 SET SUPP_SITE_PROCESS_FLAG =6,
                     SUPP_SITE_ERROR_FLAG = 'E',
                     SUPP_SITE_ERROR_MSG = substr(SUPP_SITE_ERROR_MSG||':'||l_vend_site_err_msg,1,3999)
              WHERE supplier_name = r_supp_site_tab.supplier_name
                AND vendor_site_code_int = r_supp_site_tab.vendor_site_code_int
                AND PROCESS_FLAG = 'I';
            END IF;
            COMMIT;
    END IF;
    END LOOP;
    /* END LOOP for r_supp_site_tab cusrsor */
               
    /* Update CONT_ERROR_FLAG for all ERROR sites */
                      UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                         SET CONT_PROCESS_FLAG =6,
                             CONT_ERROR_FLAG = 'E',
                             CONT_ERROR_MSG = 'ERROR: Supplier Site validation Failed'
                      WHERE SUPP_SITE_ERROR_FLAG = 'E'
                        AND SUPP_SITE_PROCESS_FLAG = 3
                        AND PROCESS_FLAG = 'I';
                     COMMIT;
    EXCEPTION
    WHEN OTHERS THEN 
    print_debug_msg(p_message => ' IN EXCEPTION post_update_defaults :'||SQLERRM, p_force => true);
    END post_update_defaults;
    
    
    PROCEDURE post_update_tax
    AS
    
    lc_return_status        VARCHAR2(2000);
    ln_msg_count            NUMBER;
    ll_msg_data             LONG;
    ln_message_int          NUMBER;
    lrec_vendor_rec         ap_vendor_pub_pkg.r_vendor_rec_type;
    lv_msg_list             VARCHAR2(2000);
    ln_profile_id           NUMBER;
    ln_obj_ver              NUMBER;
    ln_tax_apyer_id         NUMBER;
    
    CURSOR c_supp_upd_tax
    IS
    SELECT *
      FROM XX_AP_SUPPLIER_STG
     WHERE UPDATE_FLAG = 'Y'
       AND SUPP_PROCESS_FLAG ='4'
       AND PROCESS_FLAG = 'I';
    
    BEGIN
    
    /* Loop for UPDATE_FLAG = 'Y'*/
    FOR r_supp_upd_tax IN c_supp_upd_tax
    LOOP
    print_debug_msg(p_message => ' IN r_supp_upd_tax LOOP :', p_force => true);
    
      lrec_vendor_rec.vendor_id             :=r_supp_upd_tax.vendor_id;
      lrec_vendor_rec.JGZZ_FISCAL_CODE      := r_supp_upd_tax.tax_payer_id;
    
      ap_vendor_pub_pkg.update_vendor( p_api_version => 1,
                                       x_return_status => lc_return_status,
                                       x_msg_count => ln_msg_count,
                                       x_msg_data => ll_msg_data,
                                       p_vendor_rec => lrec_vendor_rec,
                                       p_vendor_id => r_supp_upd_tax.vendor_id);
      print_debug_msg(p_message => 'Vendor Update Status :'||lc_return_status, p_force => true);
      IF (lc_return_status <> 'S') THEN
        IF ln_msg_count    >= 1 THEN
          FOR v_index IN 1..ln_msg_count
          LOOP
            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => ll_msg_data, p_msg_index_out => ln_message_int );
            ll_msg_data := 'UPDATE_VENDOR '||SUBSTR(Ll_Msg_Data,1,3900);
          END LOOP;
          print_debug_msg(p_message => 'Ll_Msg_Data - '||ll_msg_data, p_force => true);
          UPDATE XX_AP_SUPPLIER_STG
            SET SUPP_PROCESS_FLAG = 6,
                SUPP_ERROR_MSG = substr(SUPP_ERROR_MSG||' : '||'ll_msg_data :'|| ll_msg_data,1,3999)
          WHERE vendor_id = r_supp_upd_tax.vendor_id
            AND PROCESS_FLAG = 'I';
        End If;
      ELSE --lc_return_status = 'S'
        lc_return_status:=NULL;
        ln_msg_count:=0;
        ll_msg_data:=NULL;
             hz_party_v2pub_jw.update_organization_8( p_init_msg_list => lv_msg_list,
                                                      p_party_object_version_number=>r_supp_upd_tax.object_version_no,
                                                      x_profile_id => ln_profile_id,
                                                      x_return_status => lc_return_status,
                                                      x_msg_count => ln_msg_count,
                                                      x_msg_data => ll_msg_data, 
                                                      p1_a44 =>r_supp_upd_tax.tax_payer_id,
                                                      p1_a139 =>r_supp_upd_tax.party_id );
              print_debug_msg(p_message => 'HZ Status : '||lc_return_status, p_force => true);
             IF (lc_return_status <> 'S') THEN
                IF ln_msg_count    >= 1 THEN
                  FOR v_index IN 1..ln_msg_count
                  LOOP
                    fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => ll_msg_data, p_msg_index_out => ln_message_int );
                    ll_msg_data := 'UPDATE_ORGANIZATION_8 '||SUBSTR(ll_msg_data,1,3900);
                   END LOOP;
                  print_debug_msg(p_message => 'Ll_Msg_Data - '||ll_msg_data, p_force => true);
                  UPDATE XX_AP_SUPPLIER_STG
                    SET SUPP_PROCESS_FLAG = 6,
                        SUPP_ERROR_MSG = substr(SUPP_ERROR_MSG||' : '||'ll_msg_data :'|| ll_msg_data,1,3999)
                  WHERE vendor_id = r_supp_upd_tax.vendor_id
                    AND PROCESS_FLAG = 'I';
                End If;
              ELSE --lc_return_status = 'S'
                lc_return_status:=NULL;
                ln_msg_count:=0;
                ll_msg_data:=NULL; 
                        ZX_PARTY_TAX_PROFILE_PKG.sync_tax_reg_num ( p_party_id      => r_supp_upd_tax.party_id,
                                                                    p_tax_reg_num   => NULL ,
                                                                    x_return_status =>lc_return_status,
                                                                    x_msg_count     => ln_msg_count,
                                                                    x_msg_data      =>ll_msg_data  );
                      print_debug_msg(p_message => 'Tax Status : '||lc_return_status, p_force => true);
                      IF (lc_return_status <> 'S') THEN
                        IF ln_msg_count    >= 1 THEN
                          FOR v_index IN 1..ln_msg_count
                          LOOP
                            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => ll_msg_data, p_msg_index_out => ln_message_int );
                            ll_msg_data := 'SYNC_TAX_REG_NUM '||SUBSTR(ll_msg_data,1,3900);
                          END LOOP;
                          print_debug_msg(p_message => 'Ll_Msg_Data - '||ll_msg_data, p_force => true);
                          UPDATE XX_AP_SUPPLIER_STG
                            SET SUPP_PROCESS_FLAG = 6,
                                SUPP_ERROR_MSG = substr(SUPP_ERROR_MSG||' : '||'ll_msg_data :'|| ll_msg_data,1,3999)
                          WHERE vendor_id = r_supp_upd_tax.vendor_id
                            AND PROCESS_FLAG = 'I';
                        End If;
                      END IF;
                       BEGIN
                        UPDATE XX_AP_SUPPLIER_STG
                           SET SUPP_PROCESS_FLAG  = 7
                         WHERE supplier_name = r_supp_upd_tax.supplier_name
                           AND PROCESS_FLAG = 'I';
                       EXCEPTION
                       WHEN OTHERS THEN 
                         print_debug_msg(p_message => ' EXCEPTION in UPDATE XX_AP_SUPPLIER_STG :'||SQLERRM, p_force => true);
                         UPDATE XX_AP_SUPPLIER_STG
                            SET SUPP_PROCESS_FLAG = 6,
                                SUPP_ERROR_MSG = substr(SUPP_ERROR_MSG||' EXCEPTION in UPDATE XX_AP_SUPPLIER_STG',1,3999)
                          WHERE supplier_name = r_supp_upd_tax.supplier_name
                            AND PROCESS_FLAG = 'I';
                       END;
                    COMMIT;
                  END IF;
          END IF;
    END LOOP;
    /* END Loop for UPDATE_FLAG = 'Y'*/
    
    EXCEPTION
    WHEN OTHERS THEN 
    print_debug_msg(p_message => ' IN EXCEPTION post_update_tax :'||SQLERRM, p_force => true);
    END post_update_tax;


    PROCEDURE post_upd_vend_site_code
    AS
    
    ln_vend_id              NUMBER;
    ln_prefix               VARCHAR2(10);
    ln_py_vend_site_id      NUMBER;
    ln_new_site_code        VARCHAR2(50);
    
    lc_return_status        VARCHAR2(2000);
    ln_msg_count            NUMBER;
    ll_msg_data             LONG;
    Ln_Vendor_Id            NUMBER;
    Ln_Vendor_site_Id       NUMBER;
    ln_message_int          NUMBER;
    l_init_msg_list         VARCHAR2 (10) := 'T';

    l_stage_error_msg        VARCHAR2(4000);
    l_api_error_message     VARCHAR2 (4000);
    l_msg_index_out         NUMBER;
    ln_party_id             NUMBER;
    l_site_obj_ver_num      NUMBER;
    ln_location_id          NUMBER;

    lrec_vendor_site_rec ap_vendor_pub_pkg.r_vendor_site_rec_type;
    l_party_site_rec      hz_party_site_v2pub.party_site_rec_type;
    
    CURSOR c_xx_site_code
    IS
    SELECT * 
      FROM XX_AP_SUPP_SITE_CONTACT_STG
     WHERE SUPP_SITE_PROCESS_FLAG = 7
       AND NVL(VENDOR_SITECD_UPD_FLAG,'X') <> 'Y'
       AND PROCESS_FLAG = 'I'
      order by vendor_id,address_name_prefix,address_purpose desc;
    BEGIN
        /*LOOP FOR r_xx_site_code */
      FOR r_xx_site_code IN c_xx_site_code
      LOOP
        IF r_xx_site_code.address_purpose ='BOTH' THEN

            ln_new_site_code := r_xx_site_code.address_name_prefix||r_xx_site_code.vendor_site_id;
            
            Lrec_Vendor_site_Rec.vendor_site_code_alt := r_xx_site_code.vendor_site_id;

        ELSIF r_xx_site_code.address_purpose ='PY'  THEN

            ln_new_site_code := r_xx_site_code.address_name_prefix||r_xx_site_code.vendor_site_id||r_xx_site_code.address_purpose;
            
            Lrec_Vendor_site_Rec.vendor_site_code_alt := r_xx_site_code.vendor_site_id;

        ELSE
            ln_py_vend_site_id:=NULL;
            BEGIN
              SELECT vendor_site_id
                INTO ln_py_vend_site_id
                FROM XX_AP_SUPP_SITE_CONTACT_STG
               WHERE vendor_id = r_xx_site_code.vendor_id
                 AND address_name_prefix=r_xx_site_code.address_name_prefix
                 AND address_purpose = 'PY'
                 AND PROCESS_FLAG = 'I';
            EXCEPTION
              WHEN OTHERS THEN
               ln_py_vend_site_id := r_xx_site_code.vendor_site_id;    
            END;  
            ln_new_site_code := r_xx_site_code.address_name_prefix||ln_py_vend_site_id||r_xx_site_code.address_purpose;
            Lrec_Vendor_site_Rec.vendor_site_code_alt := ln_py_vend_site_id;    -- Changed this in SIT test: r_xx_site_code.vendor_site_id;
        END IF;

        print_debug_msg(p_message => 'r_xx_site_code.address_purpose'||r_xx_site_code.address_purpose, p_force => true);
        print_debug_msg(p_message => 'ln_new_site_code'||ln_new_site_code, p_force => true);

        Lrec_Vendor_site_Rec.vendor_id := r_xx_site_code.vendor_id;
        Lrec_Vendor_site_Rec.vendor_site_id := r_xx_site_code.vendor_site_id;
        Lrec_Vendor_site_Rec.org_id := r_xx_site_code.org_id;
        Lrec_Vendor_site_Rec.vendor_site_code := ln_new_site_code;
        
        IF r_xx_site_code.income_tax_rep_site = 'Y' THEN 
           Lrec_Vendor_site_Rec.tax_reporting_site_flag :='Y';
        ELSE
           Lrec_Vendor_site_Rec.tax_reporting_site_flag :='N';
        END IF;
        
        -- 1.6
        IF r_xx_site_code.address_purpose = 'PR'  THEN
           Lrec_Vendor_site_Rec.attribute13 := ln_py_vend_site_id;
        ELSE
           Lrec_Vendor_site_Rec.attribute13 :='';
        END IF;
        

        
        Lrec_Vendor_site_Rec.attribute7 := r_xx_site_code.vendor_site_id;
                
        print_debug_msg(p_message => 'Call to ap_vendor_pub_pkg.update_vendor_site', p_force => true);
             ap_vendor_pub_pkg.update_vendor_site(p_api_version => 1.0,
                                                  x_return_status         => lc_return_status,
                                                  x_msg_count             => ln_msg_count,
                                                  x_msg_data              => ll_msg_data,
                                                  p_vendor_site_rec       => Lrec_Vendor_site_Rec,
                                                  p_vendor_site_id        => r_xx_site_code.vendor_site_id);
        IF (lc_return_status <> 'S') THEN
           IF ln_msg_count >= 1 THEN
              FOR v_index IN 1..ln_msg_count
              LOOP
                fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => ll_msg_data, p_msg_index_out => ln_message_int );
                Ll_Msg_Data := 'UPDATE_VENDOR_SITE '||SUBSTR(Ll_Msg_Data,1,3900);
              END LOOP;
              print_debug_msg(p_message => ' Ll_Msg_Data :'||Ll_Msg_Data, p_force => true);
            End If;
            UPDATE XX_AP_SUPP_SITE_CONTACT_STG
               SET SUPP_SITE_PROCESS_FLAG = 6,
                   SUPP_SITE_ERROR_FLAG = 'E',
                   VENDOR_SITECD_UPD_FLAG ='E', 
                   VENDOR_SITE_CODE = ln_new_site_code,
                   SUPP_SITE_ERROR_MSG = substr(SUPP_SITE_ERROR_MSG||Ll_Msg_Data,1,3999)
             WHERE vendor_site_id = r_xx_site_code.vendor_site_id
               AND PROCESS_FLAG = 'I';
             COMMIT;
        ELSE

          UPDATE ap_supplier_sites_all
	     SET address_line4=NULL
	   WHERE vendor_site_id=r_xx_site_code.vendor_site_id;
	  COMMIT;

           ln_party_id:=NULL;
           ln_location_id:=NULL;
           l_site_obj_ver_num:=NULL;

           BEGIN
             SELECT party_id,
                    location_id,
                    object_version_number
               INTO ln_party_id,
                    ln_location_id,
                    l_site_obj_ver_num
               FROM hz_party_sites
              WHERE party_site_id=r_xx_site_code.party_site_id;
           EXCEPTION
             WHEN others THEN
               ln_party_id:=NULL;
           END;

           IF ln_party_id IS NOT NULL THEN
              l_party_site_rec.party_id := ln_party_id;
              l_party_site_rec.party_site_id := r_xx_site_code.party_site_id;
              l_party_site_rec.party_site_name := ln_new_site_code;
              l_party_site_rec.location_id := ln_location_id;
                
              hz_party_site_v2pub.update_party_site
                                         (p_init_msg_list              => l_init_msg_list,
                                          p_party_site_rec             => l_party_site_rec,
                                          p_object_version_number      => l_site_obj_ver_num,
                                          x_return_status              => lc_return_status,
                                          x_msg_count                  => ln_msg_count,
                                          x_msg_data                   => ll_msg_data
                                         );

              IF lc_return_status <> 'S'  THEN
                 IF (fnd_msg_pub.count_msg > 0)  THEN
                    FOR i IN 1 .. fnd_msg_pub.count_msg
                    LOOP
                       fnd_msg_pub.get (p_msg_index          => i,
                                        p_encoded            => 'F',
                                        p_data               => ll_msg_data,
                                        p_msg_index_out      => l_msg_index_out
                                       );
                       l_api_error_message :=l_api_error_message || ' ,' || ll_msg_data;
                    END LOOP;
                 END IF;
                 l_stage_error_msg := l_stage_error_msg||'Error at API HZ_PARTY_SITE_V2PUB.update_party_site:'||SUBSTR (l_api_error_message,
                                                   1,1000);
                 UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                    SET SUPP_SITE_PROCESS_FLAG = 6,
                        SUPP_SITE_ERROR_FLAG = 'E',
                        VENDOR_SITECD_UPD_FLAG ='E', 
                        VENDOR_SITE_CODE = ln_new_site_code,
                        SUPP_SITE_ERROR_MSG = substr(SUPP_SITE_ERROR_MSG||l_stage_error_msg,1,3999)
                  WHERE vendor_site_id = r_xx_site_code.vendor_site_id
                    AND PROCESS_FLAG = 'I';
                 COMMIT;

              ELSE   

                print_debug_msg(p_message => 'update_vendor_site successfull', p_force => true);
                UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                   SET VENDOR_SITECD_UPD_FLAG = 'Y',
                       VENDOR_SITE_CODE = ln_new_site_code
                 WHERE vendor_site_id = r_xx_site_code.vendor_site_id
                   AND PROCESS_FLAG = 'I';
                COMMIT;

		UPDATE hz_locations
		   SET address4=NULL
		 WHERE location_id=ln_location_id;

		UPDATE hz_location_profiles
		   SET address4=NULL
		 WHERE location_id=ln_location_id;

		UPDATE hz_parties
		   SET address4=NULL
		 WHERE party_id=ln_party_id;
		COMMIT;

              END IF;     
           ELSE                 -- Else of ln_party_id is not null

                 UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                    SET SUPP_SITE_PROCESS_FLAG = 6,
                        SUPP_SITE_ERROR_FLAG = 'E',
                        VENDOR_SITECD_UPD_FLAG ='E', 
                        VENDOR_SITE_CODE = ln_new_site_code,
                        SUPP_SITE_ERROR_MSG = substr(SUPP_SITE_ERROR_MSG||' Unable to get party_id from hz_party_sites',1,3999)
                  WHERE vendor_site_id = r_xx_site_code.vendor_site_id
                    AND PROCESS_FLAG = 'I';
                    COMMIT;

           END IF; 
                    
        END IF;
       END LOOP;
    /* END LOOP FOR r_xx_site_code */
    EXCEPTION
    WHEN OTHERS THEN 
    print_debug_msg(p_message => ' IN EXCEPTION post_upd_vend_site_code :'||SQLERRM, p_force => true);
    END post_upd_vend_site_code;
    
    PROCEDURE post_upd_cont_load
    AS
    l_rept_req_id                 NUMBER;
    l_phas_out                    VARCHAR2 (60);
    l_status_out                  VARCHAR2 (60);
    l_dev_phase_out               VARCHAR2 (60);
    l_dev_status_out              VARCHAR2 (60);
    l_message_out                 VARCHAR2 (200);
    l_bflag                       BOOLEAN;
    l_req_err_msg                 VARCHAR2 (4000);
    l_log_msg                     VARCHAR2 (500);
    lv_err_msg                    VARCHAR2 (4000);
    l_user_id                     NUMBER := FND_GLOBAL.USER_ID;
    l_resp_id                     NUMBER := FND_GLOBAL.RESP_ID;
    l_resp_appl_id                NUMBER := FND_GLOBAL.RESP_APPL_ID;
    lv_cnt_val_count              NUMBER;
    ln_org_contact_id		  NUMBER;
    lc_transposed_no		  VARCHAR2(50);

    CURSOR c_vend_cont
    IS
    SELECT * 
      FROM XX_AP_SUPP_SITE_CONTACT_STG
     WHERE SUPP_SITE_PROCESS_FLAG = 7
       AND PROCESS_FLAG = 'I'
       AND NVL(CONT_PROCESS_FLAG, -1) <> '7';
    
    CURSOR c_validate_cnt
    IS
    SELECT * 
      FROM XX_AP_SUPP_SITE_CONTACT_STG
     WHERE CONT_PROCESS_FLAG = 4
       AND PROCESS_FLAG = 'I';
    
    CURSOR C_hzcnt(p_party_site_id NUMBER)
    IS
    SELECT HCP5.contact_point_id
      FROM hz_contact_points hcp5,
    	   AP_SUPPLIER_CONTACTS PVC,
    	   AP_SUPPLIER_SITES_ALL PVS,
    	   HZ_PARTIES HP,
    	   HZ_RELATIONSHIPS HPR,
    	   HZ_PARTY_SITES HPS,
     	   HZ_ORG_CONTACTS HOC,
    	   HZ_PARTIES HP2,
    	   AP_SUPPLIERS APS
     WHERE PVC.PER_PARTY_ID = HP.PARTY_ID
       AND pvc.org_party_site_id=p_party_site_id
       AND PVC.REL_PARTY_ID = HP2.PARTY_ID
       AND PVC.PARTY_SITE_ID = HPS.PARTY_SITE_ID
       AND PVC.ORG_CONTACT_ID = HOC.ORG_CONTACT_ID(+)
       AND PVC.RELATIONSHIP_ID = HPR.RELATIONSHIP_ID
       AND HPR.DIRECTIONAL_FLAG='F'
       AND PVS.PARTY_SITE_ID  = PVC.ORG_PARTY_SITE_ID
       AND PVS.VENDOR_ID = APS.VENDOR_ID
       AND NVL( APS.VENDOR_TYPE_LOOKUP_CODE, 'DUMMY' ) <> 'EMPLOYEE'
       AND HCP5. OWNER_TABLE_NAME = 'HZ_PARTIES'
       AND HCP5.CONTACT_POINT_TYPE = 'PHONE'
       AND HCP5.OWNER_TABLE_ID=pvc.REL_PARTY_ID;

    BEGIN
    
    print_debug_msg(p_message => ' IN BEGIN of post_upd_cont_load', p_force => true);
    FOR r_vend_cont IN c_vend_cont
    LOOP
     print_debug_msg(p_message => ' r_vend_cont.vendor_site_id :'||r_vend_cont.vendor_site_id, p_force => true);
   /**   IF r_vend_cont.cont_last_name IS NOT NULL
      THEN **/
            BEGIN
             print_debug_msg(p_message => ' Insert into AP_SUP_SITE_CONTACT_INT', p_force => true);
            INSERT INTO AP_SUP_SITE_CONTACT_INT( VENDOR_ID
                                            ,VENDOR_SITE_ID
                                            ,VENDOR_CONTACT_INTERFACE_ID
                                            ,PARTY_SITE_ID
                                            ,ORG_ID
                                            ,STATUS
                                            ,FIRST_NAME
                                            ,LAST_NAME
                                            ,CONTACT_NAME_ALT
                                            ,DEPARTMENT
                                            ,EMAIL_ADDRESS
                                            ,AREA_CODE
                                            ,PHONE
                                            ,FAX_AREA_CODE
                                            ,FAX
					    )
                                     VALUES( r_vend_cont.vendor_id
                                            ,r_vend_cont.vendor_site_id
                                            ,ap_sup_site_contact_int_s.nextval
                                            ,r_vend_cont.party_site_id
                                            ,r_vend_cont.org_id
                                            ,'NEW'
                                            ,UPPER(r_vend_cont.cont_first_name)
                                            ,UPPER(r_vend_cont.cont_last_name)
                                            ,r_vend_cont.cont_alternate_name
                                            ,r_vend_cont.cont_department
                                            ,r_vend_cont.cont_email_address
                                            ,r_vend_cont.cont_phone_area_code||TO_CHAR(XX_AP_SUPPLIERS_PHONE_EXTN_S.NEXTVAL)
                                            ,r_vend_cont.cont_phone_number
                                            ,r_vend_cont.cont_fax_area_code
                                            ,r_vend_cont.cont_fax_number
					    );
    
                           UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                              SET CONT_PROCESS_FLAG = 4
                            WHERE vendor_site_id = r_vend_cont.vendor_site_id
                              AND PROCESS_FLAG = 'I';
            EXCEPTION
            WHEN OTHERS THEN
                    lv_err_msg := substr(SQLERRM,1,3999);
                            UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                              SET CONT_PROCESS_FLAG = 6,
                                  CONT_ERROR_FLAG = 'E',
                                  CONT_ERROR_MSG =lv_err_msg
                            WHERE vendor_site_id = r_vend_cont.vendor_site_id
                              AND PROCESS_FLAG = 'I';
    
            END;
  /**    ELSE       -- Handled this validation in validate_records() API
                   UPDATE XX_AP_SUPP_SITE_CONTACT_STG
                      SET CONT_PROCESS_FLAG = 6,
                          CONT_ERROR_FLAG = 'E',
                          CONT_ERROR_MSG ='LAST NAME IS NULL for vendor_site_id :'||r_vend_cont.vendor_site_id
                    WHERE vendor_site_id = r_vend_cont.vendor_site_id
                      AND PROCESS_FLAG = 'I';
      END IF;   **/
    
    COMMIT;
    END LOOP;
          fnd_global.apps_initialize ( user_id                       => l_user_id
                                      ,resp_id                       => l_resp_id
                                      ,resp_appl_id                  => l_resp_appl_id
                                      );
    
    l_rept_req_id := fnd_request.submit_request (application                   => 'SQLAP'
                                                      ,program                       => 'APXSCIMP'
                                                      ,description                   => ''
                                                      ,start_time                    => SYSDATE
                                                      ,sub_request                   => FALSE
                                                      ,argument1                     => 'ALL'
                                                      ,argument2                     => 1000
                                                      ,argument3                     => 'N'
                                                      ,argument4                     => 'N'
                                                      ,argument5                     => 'N');
                                                       COMMIT;
            IF l_rept_req_id != 0
                THEN
                print_debug_msg(p_message => 'Standard Supplier Conact Import APXSCIMP  is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
                   l_dev_phase_out := 'Start';
    
                   WHILE UPPER (NVL (l_dev_phase_out, 'XX')) != 'COMPLETE'
                   LOOP
                      l_bflag := fnd_concurrent.wait_for_request (l_rept_req_id
                                                                      ,5
                                                                      ,50
                                                                      ,l_phas_out
                                                                      ,l_status_out
                                                                      ,l_dev_phase_out
                                                                      ,l_dev_status_out
                                                                      ,l_message_out
                                                                      );
                   END LOOP;
                ELSE
                   l_req_err_msg := 'Problem in calling Supplier Contact Open Interface Import';
                   print_debug_msg(p_message => ' l_req_err_msg :'||l_req_err_msg, p_force => true);
             END IF;
       /* LOOP for c_validate_cnt */

       FOR r_validate_cnt in c_validate_cnt LOOP

	 ln_org_contact_id:=NULL;
         lc_transposed_no :=NULL;

         BEGIN
           SELECT org_contact_id
             INTO ln_org_contact_id
             FROM ap_supplier_contacts
             WHERE org_party_site_id=r_validate_cnt.party_site_id;
         EXCEPTION
           WHEN OTHERS THEN 
            ln_org_contact_id := -1;
         END;

         IF ln_org_contact_id <> -1 THEN 
  
	    BEGIN		
   	      SELECT reverse(r_validate_cnt.cont_phone_number)||reverse(r_validate_cnt.cont_phone_area_code) 
	        INTO lc_transposed_no
  	        FROM dual;
	    EXCEPTION
	      WHEN others THEN
	        lc_transposed_no:=NULL;
	    END;

            UPDATE XX_AP_SUPP_SITE_CONTACT_STG
               SET CONT_PROCESS_FLAG = 7
             WHERE vendor_site_id = r_validate_cnt.vendor_site_id
              AND PROCESS_FLAG = 'I';

	    FOR cur IN C_hzcnt(r_validate_cnt.party_site_id) LOOP

  	        UPDATE hz_contact_points
	           SET phone_area_code=r_validate_cnt.cont_phone_area_code,
		       raw_phone_number=r_validate_cnt.cont_phone_area_code||'-'||r_validate_cnt.cont_phone_number,
		       transposed_phone_number=lc_transposed_no
  	         WHERE contact_point_id=cur.contact_point_id;

	    END LOOP;
            COMMIT;

         ELSE
            UPDATE XX_AP_SUPP_SITE_CONTACT_STG
               SET CONT_PROCESS_FLAG = 6,
                   CONT_ERROR_FLAG = 'E',
                   CONT_ERROR_MSG ='Supplier Contact Import rejected record for vendor_site_id :'||r_validate_cnt.vendor_site_id
             WHERE vendor_site_id = r_validate_cnt.vendor_site_id
               AND PROCESS_FLAG = 'I';
         END IF;
         
       END LOOP;
       COMMIT;
   
       /* END LOOP for c_validate_cnt */
     
             
    EXCEPTION
    WHEN OTHERS THEN 
    print_debug_msg(p_message => ' IN EXCEPTION post_upd_cont_load :'||SQLERRM, p_force => true);
    END post_upd_cont_load;    
   
--+============================================================================+
--| Name          : main                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for Suppliers Interface                                    |
--| Parameters    :   p_reset_flag           IN       VARCHAR2                 |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |        
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
   PROCEDURE main_prc (
      x_errbuf                   OUT NOCOPY VARCHAR2
     ,x_retcode                  OUT NOCOPY NUMBER
     ,p_reset_flag               IN       VARCHAR2
     ,p_debug_level              IN       VARCHAR2
   )
   IS
    --================================================================
    --Declaring local variables
    --================================================================
      l_procedure                   VARCHAR2 (30) := 'main_prc';
      l_log_start_date              DATE;
      l_log_end_date                DATE;
      l_out_start_date              DATE;
      l_out_end_date                DATE;
      l_log_elapse                  VARCHAR2 (100);
      l_out_elapse                  VARCHAR2 (100);
      l_ret_code                    NUMBER;
      l_return_status                  VARCHAR2 (100);
      l_err_buff                    VARCHAR2 (4000);
      l_val_records                 NUMBER;
      l_inval_records               NUMBER;
      l_processed_records                 NUMBER;
      l_unprocessed_records               NUMBER;
      l_resp_id                     NUMBER := FND_GLOBAL.RESP_ID;
      l_resp_appl_id                NUMBER := FND_GLOBAL.RESP_APPL_ID;

      l_rept_req_id                 NUMBER;
      l_phas_out                    VARCHAR2 (60);
      l_status_out                  VARCHAR2 (60);
      l_dev_phase_out               VARCHAR2 (60);
      l_dev_status_out              VARCHAR2 (60);
      l_message_out                 VARCHAR2 (200);
      l_bflag                       BOOLEAN;
      l_req_err_msg                 VARCHAR2 (4000);
      
      lc_boolean                    BOOLEAN;
                  
   
   BEGIN
   --================================================================
      --Initializing Global variables
   --================================================================
      gn_request_id := fnd_global.conc_request_id;
      g_user_id := fnd_global.user_id;
      g_login_id := fnd_global.login_id;
      gc_debug := p_debug_level;

      --================================================================
      --Adding parameters to the log file
      --================================================================
      print_debug_msg(p_message => '+---------------------------------------------------------------------------+'
                    , p_force => true);

      print_debug_msg(p_message => 'Input Parameters'
                    , p_force => true);

      print_debug_msg(p_message => '+---------------------------------------------------------------------------+'
                    , p_force => true);

      print_debug_msg(p_message => '  '
                    , p_force => true);
      
      print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag
                    , p_force => true);
                    
      print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level
                    , p_force => true);
                    
      print_debug_msg(p_message => '+---------------------------------------------------------------------------+'
                    , p_force => true);

      print_debug_msg(p_message => '  '
                    , p_force => true);
      print_debug_msg(p_message => 'Start of package '|| g_package_name
                    , p_force => true);

      print_debug_msg(p_message => 'Start Procedure   '||l_procedure
                    , p_force => true);

      print_debug_msg(p_message => '  '
                    , p_force => true);

      print_debug_msg(p_message => 'Initializing Global Variables '
                    , p_force => true);                                                                                                                                                                                                        

      l_ret_code := 0;
      l_return_status := 'S';
      l_err_buff  := NULL;


      --===================================================================
      -- If p_reset_flag = 'Y' then delete all the data in 2 staging tables
      --===================================================================
      IF p_reset_flag = 'Y' THEN
          print_debug_msg(p_message => 'Invoking the procedure reset_stage_tables()'
                        , p_force => true);      
           reset_stage_tables(
            x_ret_code  => l_ret_code
            ,x_return_status => l_return_status
            ,x_err_buf => l_err_buff);
           
           x_retcode := l_ret_code;           
           x_errbuf  := l_err_buff;
           
           return;      
      END IF;            
      
      --===============================================================
      --Updating Request Id into Supplier Staging table     -- 
      --===============================================================
         
      UPDATE XX_AP_SUPPLIER_STG
      SET SUPP_PROCESS_FLAG = gn_process_status_inprocess
          ,REQUEST_ID = gn_request_id
          ,PROCESS_FLAG = 'I' 
      WHERE SUPP_PROCESS_FLAG = '1';

       IF sql%notfound THEN
           print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUPPLIER_STG.'
                        , p_force => true);
           print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
                        
       ELSIF sql%found THEN
          print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUPPLIER_STG are '||sql%rowcount
                        , p_force => true);
          print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are '||sql%rowcount);
       END IF;  

      --===============================================================
      --Updating Request Id into Supplier Site Staging table     -- 
      --===============================================================
      
      UPDATE XX_AP_SUPP_SITE_CONTACT_STG
      SET SUPP_SITE_PROCESS_FLAG = gn_process_status_inprocess
          ,REQUEST_ID = gn_request_id
          ,PROCESS_FLAG = 'I' 
      WHERE SUPP_SITE_PROCESS_FLAG IN ('1'); 

       IF sql%notfound THEN
           print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUPP_SITE_CONTACT_STG.'
                        , p_force => true);
           print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are 0');
       ELSIF sql%found THEN
          print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUPP_SITE_CONTACT_STG are '||sql%rowcount
                        , p_force => true);
          print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are '||sql%rowcount);
       END IF; 



      --===============================================================
      -- Validate the records invoking the API  validate_records()    -- 
      --===============================================================

     print_debug_msg(p_message => 'Invoking the procedure validate_records()'
                    , p_force => true);
                                              
      validate_records(
          x_val_records => l_val_records
          ,x_inval_records => l_inval_records
          ,x_ret_code  => l_ret_code
          ,x_return_status => l_return_status
          ,x_err_buf => l_err_buff);
       
       print_debug_msg(p_message => '==========================================================================='
                    , p_force => true);   
       print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()'
                    , p_force => true);
       print_debug_msg(p_message => 'l_val_records - '||l_val_records
                    , p_force => true);
       print_debug_msg(p_message => 'l_inval_records - '||l_inval_records
                    , p_force => true);
       print_debug_msg(p_message => 'l_ret_code - '||l_ret_code
                    , p_force => true);
       print_debug_msg(p_message => 'l_return_status - '||l_return_status
                    , p_force => true);
       print_debug_msg(p_message => 'l_err_buff - '||l_err_buff
                    , p_force => true);
       print_debug_msg(p_message => '==========================================================================='
                    , p_force => true); 
                                                                                                           
       IF (l_ret_code IS NULL or l_ret_code <> 0) THEN
         x_retcode := l_ret_code;
         x_errbuf := l_err_buff; 
         
         return; 
              
       END IF;           


      --===========================================================================
      -- Load the validated records in staging table into interface table    -- 
      --===========================================================================  
      print_debug_msg(p_message => 'Invoking the procedure load_vendors()'
                    , p_force => true);
                          
      load_vendors(
          x_processed_records => l_processed_records
          ,x_unprocessed_records => l_unprocessed_records
          ,x_ret_code  => l_ret_code
          ,x_return_status => l_return_status
          ,x_err_buf => l_err_buff);
  
      print_debug_msg(p_message => '==========================================================================='
                    , p_force => true);                          
      print_debug_msg(p_message => 'Completed the execution of the procedure load_vendors()'
                    , p_force => true);
      print_debug_msg(p_message => 'l_processed_records - '|| l_processed_records
                    , p_force => true);
      print_debug_msg(p_message => 'l_unprocessed_records - '|| l_unprocessed_records
                    , p_force => true);
      print_debug_msg(p_message => 'l_ret_code - '||l_ret_code
                    , p_force => true);
      print_debug_msg(p_message => 'l_return_status - '||l_return_status
                    , p_force => true);
      print_debug_msg(p_message => 'l_err_buff - '||l_err_buff
                    , p_force => true);
      print_debug_msg(p_message => '==========================================================================='
                    , p_force => true);     

      print_debug_msg(p_message => 'Call XXSUPPIFACEERRRPT Error report after load Vendors', p_force => true);
    
      fnd_global.apps_initialize (user_id                       => g_user_id
                               ,resp_id                       => l_resp_id
                               ,resp_appl_id                  => l_resp_appl_id
                               );
      print_debug_msg(p_message => 'Error Report Process - Apps Initialized', p_force => true);
	  -- 1.5 
      lc_boolean := fnd_request.add_layout (template_appl_name      => 'XXFIN',
                                      template_code           => 'XXSUPPIFACEERRRPT',
                                      template_language       => 'en',
                                      template_territory      => 'US',
                                      output_format           => 'EXCEL'
                                      );       
      IF lc_boolean THEN                                      
          print_debug_msg(p_message => 'Error Report Process - Report Layout Added Successfully ', p_force => true);
      ELSE
          print_debug_msg(p_message => 'Error Report Process - Report Layout Addition failed', p_force => true);      
      END IF;
      
      print_debug_msg(p_message => 'Error Report Process - gn_request_id value is '||gn_request_id, p_force => true); 
           
      l_rept_req_id := fnd_request.submit_request (application                    => 'XXFIN'
                                                      ,program                       => 'XXSUPPIFACEERRRPT'
                                                      ,description                   => ''
                                                      ,start_time                    => SYSDATE
                                                      ,sub_request                   => FALSE
                                                      ,argument1                     => gn_request_id
                                                      ,argument2                     => 'V');                     
                                                      
      COMMIT;  
                                       
      print_debug_msg(p_message => 'Error Report Process - Request Submitted '||l_rept_req_id, p_force => true);
      print_out_msg(p_message => 'Error Report XXSUPPIFACEERRRPT - Request Submitted with ID - '||l_rept_req_id);                                                         

      IF l_rept_req_id != 0
      THEN
                print_debug_msg(p_message => 'Error Report XXSUPPIFACEERRRPT Submited after validation and load, Request_id :'||l_rept_req_id, p_force => true);
                print_debug_msg(p_message => 'Call fnd_concurrent.wait_FOR_request', p_force => true);
                l_dev_phase_out := 'Start';
    
                WHILE UPPER (NVL (l_dev_phase_out, 'XX')) != 'COMPLETE'
                LOOP
                   l_bflag := fnd_concurrent.wait_for_request (l_rept_req_id
                                                                   ,5
                                                                   ,50
                                                                   ,l_phas_out
                                                                   ,l_status_out
                                                                   ,l_dev_phase_out
                                                                   ,l_dev_status_out
                                                                   ,l_message_out
                                                                   );
                END LOOP;
                print_out_msg(p_message => 'Error Report XXSUPPIFACEERRRPT - Request with ID - '||l_rept_req_id||' completed successfully.');  
      ELSE
                l_req_err_msg := 'Problem in calling XXSUPPIFACEERRRPT OD: Supplier Interface Error report after validation and loading';
                print_debug_msg(p_message => 'l_req_err_msg '||l_req_err_msg, p_force => true);
      END IF;                                                                                    

                                  
      x_retcode := l_ret_code;
      x_errbuf := l_err_buff; 
      
   EXCEPTION
      WHEN OTHERS THEN
          x_retcode := 2;
          x_errbuf := 'Exception in XXOD_AP_SUPP_VAL_LOAD_PKG.main_prc() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);  
        
   END main_prc; 

   PROCEDURE post_update_main_prc(x_errbuf   OUT NOCOPY VARCHAR2
                                  ,x_retcode  OUT NOCOPY NUMBER)
    AS
    
    l_rept_req_id                 NUMBER;
    l_phas_out                    VARCHAR2 (60);
    l_status_out                  VARCHAR2 (60);
    l_dev_phase_out               VARCHAR2 (60);
    l_dev_status_out              VARCHAR2 (60);
    l_message_out                 VARCHAR2 (200);
    l_bflag                       BOOLEAN;
    l_req_err_msg                 VARCHAR2 (4000);
    l_log_msg                     VARCHAR2 (500);
    lv_err_msg                    VARCHAR2 (4000);
    l_user_id                     NUMBER := FND_GLOBAL.USER_ID;
    l_resp_id                     NUMBER := FND_GLOBAL.RESP_ID;
    l_resp_appl_id                NUMBER := FND_GLOBAL.RESP_APPL_ID;
    ln_conc_req_id                NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
    lv_cnt_val_count              NUMBER;
    lc_boolean                    BOOLEAN;
    BEGIN

    
    print_debug_msg(p_message => 'Start of POST_UPDATE_MAIN_PRC ', p_force => true);
    print_debug_msg(p_message => 'CONC REQUEST ID :'||ln_conc_req_id, p_force => true);
    print_debug_msg(p_message => 'Calling Procedure post_update_defaults ', p_force => true);

       UPDATE XX_AP_SUPPLIER_STG
          SET REQUEST_ID = ln_conc_req_id
        WHERE PROCESS_FLAG = 'I';
          

         UPDATE XX_AP_SUPP_SITE_CONTACT_STG
          SET REQUEST_ID = ln_conc_req_id
        WHERE PROCESS_FLAG = 'I';
        
        COMMIT;
    
    /*Calling  Procedure post_update_defaults to update default ID */
    post_update_defaults;
    print_debug_msg(p_message => 'Calling Procedure post_update_tax ', p_force => true);
    /*Calling  Procedure post_update_tax to update tax_payer_id */
    post_update_tax;
    print_debug_msg(p_message => 'Calling Procedure post_upd_vend_site_code ', p_force => true);
    /*Calling  Procedure post_upd_vend_site_code to update vendor_site_code*/
    post_upd_vend_site_code;
    print_debug_msg(p_message => 'Calling Procedure process_bus_class ', p_force => true);
    /*Calling  Procedure process_bus_class to load contact for the vendor site*/
    process_bus_class;
    print_debug_msg(p_message => 'Calling Procedure xx_supp_dff ', p_force => true);
    /*Calling  Procedure xx_supp_dff to load contact for the vendor site*/    
    xx_supp_dff;
    print_debug_msg(p_message => 'Calling Procedure post_upd_cont_load ', p_force => true);
    /*Calling  Procedure post_upd_cont_load to load contact for the vendor site*/
    post_upd_cont_load;
    
    print_debug_msg(p_message => 'setting the telex column ', p_force => true);
    
    BEGIN
       
        UPDATE AP_SUPPLIER_SITES_ALL assa
        set telex =  fnd_global.user_name
        where assa.vendor_site_id in (
          SELECT xasscs.vendor_site_id
          FROM  XX_AP_SUPP_SITE_CONTACT_STG xasscs
          WHERE xasscs.SUPP_SITE_PROCESS_FLAG = '7'
                AND xasscs.CONT_PROCESS_FLAG = '7'
                AND xasscs.request_id = ln_conc_req_id 
        );        
       
       print_debug_msg(p_message => 'Updated telex column - '||SQL%ROWCOUNT||' rows', p_force => true);
       
     EXCEPTION
        WHEN OTHERS THEN
         x_retcode := 2;
         x_errbuf := 'Exception in POST_UPDATE_MAIN_PRC() when updating telex column - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500); 
         print_debug_msg(p_message => 'x_errbuf  '||x_errbuf, p_force => true);
         return;
     END;
    
       UPDATE XX_AP_SUPPLIER_STG
          SET PROCESS_FLAG = 'Y',
              REQUEST_ID = ln_conc_req_id
        WHERE PROCESS_FLAG = 'I';
          

         UPDATE XX_AP_SUPP_SITE_CONTACT_STG
          SET PROCESS_FLAG = 'Y',
              REQUEST_ID = ln_conc_req_id
        WHERE PROCESS_FLAG = 'I';
        
          COMMIT;


    print_debug_msg(p_message => 'End of POST_UPDATE_MAIN_PRC ', p_force => true);
    print_debug_msg(p_message => 'Call XXSUPPIFACEERRRPT Error report', p_force => true);
    
    fnd_global.apps_initialize (user_id                       => l_user_id
                               ,resp_id                       => l_resp_id
                               ,resp_appl_id                  => l_resp_appl_id
                               );
							   
	-- 1.5
    lc_boolean:=fnd_request.add_layout (template_appl_name      => 'XXFIN',
                                    template_code           => 'XXSUPPIFACEERRRPT',
                                    template_language       => 'en',
                                    template_territory      => 'US',
                                    output_format           => 'EXCEL'
                                    );             
    l_rept_req_id := fnd_request.submit_request (application                    => 'XXFIN'
                                                      ,program                       => 'XXSUPPIFACEERRRPT'
                                                      ,description                   => ''
                                                      ,start_time                    => SYSDATE
                                                      ,sub_request                   => FALSE
                                                      ,argument1                     => ln_conc_req_id
                                                      ,argument2                     => 'F');
                                                      
            COMMIT;
            
            IF l_rept_req_id != 0
             THEN
                print_debug_msg(p_message => 'Error Report XXSUPPIFACEERRRPT Submited, Request_id :'||l_rept_req_id, p_force => true);
                print_debug_msg(p_message => 'Call fnd_concurrent.wait_FOR_request', p_force => true);
                l_dev_phase_out := 'Start';
    
                WHILE UPPER (NVL (l_dev_phase_out, 'XX')) != 'COMPLETE'
                LOOP
                   l_bflag := fnd_concurrent.wait_for_request (l_rept_req_id
                                                                   ,5
                                                                   ,50
                                                                   ,l_phas_out
                                                                   ,l_status_out
                                                                   ,l_dev_phase_out
                                                                   ,l_dev_status_out
                                                                   ,l_message_out
                                                                   );
                END LOOP;
             ELSE
                l_req_err_msg := 'Problem in calling XXSUPPIFACEERRRPT OD: Supplier Interface Error report';
                print_debug_msg(p_message => 'l_req_err_msg '||l_req_err_msg, p_force => true);
             END IF;
    EXCEPTION
    WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf := 'Exception in POST_UPDATE_MAIN_PRC() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500); 
    print_debug_msg(p_message => 'x_errbuf  '||x_errbuf, p_force => true);
    END post_update_main_prc;
   

END XXOD_AP_SUPP_VAL_LOAD_PKG;
/
SHOW ERRORS;
