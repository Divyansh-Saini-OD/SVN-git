SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_ap_supp_cld_intf_pkg
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name             : XX_AP_SUPP_CLD_INTF_PKG                                                |
-- | Description      : This Program will do validations and load vendors to interface tables  |
-- |                    from staging table This process is defined for Cloud to EBS Supplier   |
-- |                    Interface. And also does the post updates                              |
-- |                                                                                           |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version    Date          Author            Remarks                                         |
-- |=======    ==========    =============     ================================================|
-- |  1.0    14-MAY-2019     Priyam Parmar     Initial code                                    |
-- |  1.1    21-JUN-2019     Dinesh Nagapuri   Added Business Classification and custom DFF    |
-- |  1.2    25-JUN-2019     Priyam Parmar     Added Telex update for Supplier Site (RMS)      |
---|  1.3    27-JUN-2019     Priyam Parmar     Removed Bank staging table from 1.2 update      |
-- |  1.4    05-JUL-2019     Paddy Sanjeevi    Fix the flags and fine tuned                    |
-- |  1.5    07-JUL-2019     Paddy Sanjeevi    Added for tolerance                             |
-- |  1.6    11-JUL-2019     Havish Kasina     Added for Services Tolerance                    |
-- |  1.7    27-JUL-2019     Paddy Sanjeevi    Added for import error messages                 |
-- |  1.8    31-JUL-2019     Havish Kasina     Added FND_API.G_MISS_CHAR if any attribute value|
-- |                                           is NULL for all Update APIs                     |
-- |  1.9    01-AUG-2019     Havish Kasina     Added DUNS_NUMBER in update_supplier_sites      |
-- |                                           procedure                                       |
-- |  2.0    02-AUG-2019     Havish Kasina     Added a condition to check the Tolerance exists |
-- |                                           for Trade Suppliers. Removed the Phone Area code|
-- |                                           and Fax code validations in Supplier Sites and  |
-- |                                           Contacts                                        |
-- |  2.1    07-AUG-2019     Havish Kasina     Receiving Changes added                         | 
-- |===========================================================================================+
AS
  /*********************************************************************
  * Procedure used to log based on gb_debug value or if p_force is TRUE.
  * Will log to dbms_output if request id is not set,
  * else will log to concurrent program log file.  Will prepend
  * timestamp to each message logged.  This is useful for determining
  * elapse times.
  *********************************************************************/
PROCEDURE print_debug_msg(
    p_message IN VARCHAR2,
    p_force   IN BOOLEAN DEFAULT false )
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_message :=p_message;
    fnd_file.put_line(fnd_file.log,lc_message);
    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      DBMS_OUTPUT.PUT_LINE(lc_message);
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
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  lc_message :=p_message;
  fnd_file.put_line(fnd_file.output, lc_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    dbms_output.put_line(lc_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
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
PROCEDURE insert_error(
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
  print_debug_msg ( 'Error in insert_error: ' || sqlerrm);
END insert_error;
--+============================================================================+
--| Name          : set_step                                                   |
--| Description   : This procedure will Set Step                               |
--|                                                                            |
--| Parameters    : p_step_name           IN   VARCHAR2                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE set_step(
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
FUNCTION isalpha(
    p_string IN VARCHAR2)
  RETURN BOOLEAN
IS
  v_string     VARCHAR2(4000);
  v_out_string VARCHAR2(4000) := NULL;
BEGIN
  v_string := ltrim(rtrim(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isAlpha() - p_string '||p_string ,p_force=> false);
    SELECT LENGTH(trim(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ' ')))
    INTO v_out_string
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
    RETURN false;
  ELSE
    RETURN true;
  END IF;
END isalpha;
-- +===================================================================+
-- | FUNCTION   : isNumeric                                       |
-- |                                                                   |
-- | DESCRIPTION: Checks if only Numeric in a string              |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if numeric exists or not)             |
-- +===================================================================+
FUNCTION isnumeric(
    p_string IN VARCHAR2)
  RETURN BOOLEAN
IS
  v_string     VARCHAR2(4000);
  v_out_string VARCHAR2(4000) := NULL;
BEGIN
  v_string := ltrim(rtrim(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isNumeric() - p_string '||p_string ,p_force=> false);
    SELECT LENGTH(trim(TRANSLATE(v_string, '0123456789', ' ')))
    INTO v_out_string
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
    RETURN false;
  ELSE
    RETURN true;
  END IF;
END isnumeric;
-- +===================================================================+
-- | FUNCTION   : isAlphaNumeric                                       |
-- |                                                                   |
-- | DESCRIPTION: Checks if only AlphaNumeric in a string              |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if alpha numeric exists or not)             |
-- +===================================================================+
FUNCTION isalphanumeric(
    p_string IN VARCHAR2)
  RETURN BOOLEAN
IS
  v_string     VARCHAR2(4000);
  v_out_string VARCHAR2(4000) := NULL;
BEGIN
  v_string := ltrim(rtrim(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isAlphaNumeric() - p_string '||p_string ,p_force=> false);
    SELECT LENGTH(trim(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' ')))
    INTO v_out_string
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
    RETURN false;
  ELSE
    RETURN true;
  END IF;
END isalphanumeric;
-- +===================================================================+
-- | FUNCTION   : isPostalCode                                         |
-- |                                                                   |
-- | DESCRIPTION: Checks if only numeric and hypen(0) in a string      |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if only numeric and hypen(0) exists or not) |
-- +===================================================================+
FUNCTION ispostalcode(
    p_string IN VARCHAR2)
  RETURN BOOLEAN
IS
  v_string     VARCHAR2(4000);
  v_out_string VARCHAR2(4000) := NULL;
BEGIN
  v_string := ltrim(rtrim(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' isPostalCode() - p_string '||p_string ,p_force=> false);
    SELECT LENGTH(trim(TRANSLATE(v_string, '0123456789-', ' ')))
    INTO v_out_string
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
    RETURN false;
  ELSE
    RETURN true;
  END IF;
END ispostalcode;
-- +===================================================================+
-- | FUNCTION   : find_special_chars                                   |
-- |                                                                   |
-- | DESCRIPTION: Checks if special chars exist in a string            |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Varchar (if junck character exists or not)           |
-- +===================================================================+
FUNCTION find_special_chars(
    p_string IN VARCHAR2)
  RETURN VARCHAR2
IS
  v_string     VARCHAR2(4000);
  v_char       VARCHAR2(1);
  v_out_string VARCHAR2(4000) := NULL;
BEGIN
  v_string := ltrim(rtrim(upper(p_string)));
  BEGIN
    print_debug_msg(p_message=> ' find_special_chars() - p_string '||p_string ,p_force=> false);
    SELECT LENGTH(trim(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&-', ' ')))
    INTO v_out_string
    FROM dual;
  EXCEPTION
  WHEN OTHERS THEN
    v_out_string:=NULL;
  END;
  IF v_out_string IS NOT NULL THEN
    RETURN 'JUNK_CHARS_EXIST';
  ELSE
    RETURN v_string;
  END IF;
END find_special_chars;
--+============================================================================+
--| Name          : get_cld_to_ebs_map                                           |
--| Description   : This procedure will get code_combiantion_id from ebs to cld  |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
FUNCTION get_cld_to_ebs_map(
    p_segments VARCHAR2)
  RETURN NUMBER
IS
  CURSOR c_concat
  IS
    SELECT regexp_substr(p_segments, '[^.]+', 1, 1) entity,
      regexp_substr(p_segments, '[^.]+', 1, 2) lob,
      regexp_substr(p_segments, '[^.]+', 1, 3) cost_center,
      regexp_substr(p_segments, '[^.]+', 1, 4) account,
      regexp_substr(p_segments, '[^.]+', 1, 5) location,
      regexp_substr(p_segments, '[^.]+', 1, 6) intercompany,
      '000000' future
    FROM dual;
  v_target       VARCHAR2(100);
  v_entity       VARCHAR2(50);
  v_cost_center  VARCHAR2(50);
  v_account      VARCHAR2(50);
  v_location     VARCHAR2(50);
  v_intercompany VARCHAR2(50);
  v_lob          VARCHAR2(50);
  v_future       VARCHAR2(50);
  v_ccid         NUMBER;
BEGIN
  BEGIN
    IF p_segments IS NOT NULL THEN
      v_target    :=NULL;
      FOR i IN c_concat
      LOOP
        BEGIN
          SELECT target
          INTO v_entity
          FROM xx_gl_cld2ebs_mapping
          WHERE source=i.entity
          AND type    ='ENTITY';
        EXCEPTION
        WHEN OTHERS THEN
          -- v_entity:=i.entity;
          v_entity:=-1;
        END;
        BEGIN
          SELECT target
          INTO v_cost_center
          FROM xx_gl_cld2ebs_mapping
          WHERE source=i.cost_center
          AND type    ='COST_CENTER';
        EXCEPTION
        WHEN OTHERS THEN
          -- v_cost_center:=i.cost_center;
          v_cost_center:=-1;
        END;
        BEGIN
          SELECT target
          INTO v_account
          FROM xx_gl_cld2ebs_mapping
          WHERE source=i.account
          AND type    ='ACCOUNT';
        EXCEPTION
        WHEN OTHERS THEN
          -- v_account:=i.account;
          v_account:=-1;
        END;
        BEGIN
          SELECT target
          INTO v_location
          FROM xx_gl_cld2ebs_mapping
          WHERE source=i.location
          AND type    ='LOCATION';
        EXCEPTION
        WHEN OTHERS THEN
          -- v_location:=i.location;
          v_location:=-1;
        END;
        BEGIN
          SELECT target
          INTO v_lob
          FROM xx_gl_cld2ebs_mapping
          WHERE source=i.lob
          AND type    ='LOB';
        EXCEPTION
        WHEN OTHERS THEN
          --v_lob:=i.lob;
          v_lob:=-1;
        END;
        BEGIN
          SELECT target
          INTO v_intercompany
          FROM xx_gl_cld2ebs_mapping
          WHERE source=i.intercompany
          AND type    ='ENTITY';
        EXCEPTION
        WHEN OTHERS THEN
          --v_lob:=i.lob;
          v_intercompany:=-1;
        END;
        v_future:=i.future;
      END LOOP;
      v_target:=v_entity||'.'||v_cost_center||'.'||v_account||'.'||v_location||'.'||v_intercompany||'.'||v_lob||'.'||v_future;
      print_debug_msg(p_message=> 'New EBs Code Combination ID is '||v_target , p_force=>true);
      BEGIN
        SELECT code_combination_id
        INTO v_ccid
        FROM gl_code_combinations_kfv
        WHERE concatenated_segments=v_target;
      EXCEPTION
      WHEN OTHERS THEN
        v_ccid :=NULL;
        print_debug_msg(p_message=> 'CCID doesnot exists in EBS for  '||v_target , p_force=>true);
      END ;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_ccid :=NULL;
  END;
  RETURN v_ccid;
END get_cld_to_ebs_map;

/* Added as per Version 2.1 by Havish Kasina */
--+============================================================================+
--| Name          : get_receiving_details                                      |
--| Description   : This procedure will get the receiving details from the     |
--|                 Cloud Supplier Sites Staging table                         |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE get_receiving_details(p_supplier_num                    IN  VARCHAR2,
                                o_inspection_required_flag        OUT VARCHAR2,	    
								o_receipt_required_flag           OUT VARCHAR2,	        
								o_qty_rcv_tolerance               OUT NUMBER,	            
								o_qty_rcv_exception_code          OUT VARCHAR2,    
								o_enforce_ship_to_loc_code        OUT VARCHAR2, 
								o_days_early_receipt_allowed      OUT NUMBER, 
								o_days_late_receipt_allowed       OUT NUMBER,	    
								o_receipt_days_exception_code     OUT VARCHAR2,	
								o_receiving_routing_id            OUT NUMBER,        
								o_allow_substitute_rcpts_flag     OUT VARCHAR2,
								o_allow_unordered_rcpts_flag      OUT VARCHAR2
                               )
IS 

BEGIN
    
  SELECT inspection_required_flag,	     
         receipt_required_flag,	         
         TO_NUMBER(qty_rcv_tolerance),	             
         qty_rcv_exception_code,     
         enforce_ship_to_location_code, 
         TO_NUMBER(days_early_receipt_allowed), 
         TO_NUMBER(days_late_receipt_allowed),	     
         receipt_days_exception_code,	 
         TO_NUMBER(receiving_routing_id),	         
         allow_substitute_receipts_flag,
         allow_unordered_receipts_flag
    INTO o_inspection_required_flag,      		 
         o_receipt_required_flag,          
         o_qty_rcv_tolerance,              
         o_qty_rcv_exception_code,         
         o_enforce_ship_to_loc_code, 
         o_days_early_receipt_allowed,     
         o_days_late_receipt_allowed,      
         o_receipt_days_exception_code,   
         o_receiving_routing_id,           
         o_allow_substitute_rcpts_flag,
         o_allow_unordered_rcpts_flag 
    FROM xx_ap_cld_supp_sites_stg
   WHERE request_id        = gn_request_id
     AND purchasing_site_flag = 'Y'
	 AND supplier_number = p_supplier_num
     AND rownum < 2;
EXCEPTION
WHEN OTHERS
THEN
   o_inspection_required_flag       := NULL;
   o_receipt_required_flag          := NULL;
   o_qty_rcv_tolerance              := NULL;   
   o_qty_rcv_exception_code         := NULL;
   o_enforce_ship_to_loc_code       := NULL;
   o_days_early_receipt_allowed     := NULL;   
   o_days_late_receipt_allowed      := NULL;  
   o_receipt_days_exception_code    := NULL;
   o_receiving_routing_id           := NULL; 
   o_allow_substitute_rcpts_flag    := NULL;
   o_allow_unordered_rcpts_flag     := NULL;
END get_receiving_details;

--+============================================================================+
--| Name          : insert_bus_class                                           |
--| Description   : This Function will insert Business Classifications         |
--|                                                                            |
--| Parameters    : p_party_id,p_bus_code,p_attribute,p_vendor_id              |
--|                                                                            |
--| Returns       : N/A                                                        |
--+============================================================================+
FUNCTION insert_bus_class(
    p_party_id  IN NUMBER ,
    p_bus_code  IN VARCHAR2 ,
    p_attribute IN VARCHAR2 ,
    p_vendor_id IN NUMBER )
  RETURN VARCHAR2
IS
  v_class_id NUMBER;
BEGIN
  SELECT POS_BUS_CLASS_ATTR_S.nextval 
    INTO v_class_id 
	FROM DUAL;
  INSERT
  INTO pos_bus_class_attr
    (
      classification_id ,
      party_id ,
      lookup_type ,
      lookup_code ,
      start_date_active ,
      status ,
      ext_attr_1 ,
      class_status ,
      created_by ,
      creation_date ,
      last_updated_by ,
      last_update_date ,
      vendor_id
    )
    VALUES
    (
      v_class_id ,
      p_party_id ,
      'POS_BUSINESS_CLASSIFICATIONS' ,
      p_bus_code ,
      SYSDATE ,
      'A' ,
      p_attribute ,
      'APPROVED' ,
      fnd_global.user_id ,
      SYSDATE ,
      fnd_global.user_id ,
      SYSDATE ,
      p_vendor_id
    );
  RETURN('Y');
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Error in while inserting business classification :'||TO_CHAR(p_vendor_id)||','||p_bus_code||','||SQLERRM);
  RETURN('N');
END insert_bus_class;
--+============================================================================+
--| Name          : xx_custom_tolerance                                        |
--| Description   : This FUnction will process Custom Supplier Tolerance    |
--|                      |
--|                                                                            |
--| Parameters    : p_vendor_id,p_vendor_site_id                               |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
FUNCTION xx_custom_tolerance
  (
    p_vendor_id      IN NUMBER,
    p_vendor_site_id IN NUMBER,
    p_org_id         IN NUMBER
  )
  RETURN VARCHAR2
IS
BEGIN
  INSERT
  INTO xx_ap_custom_tolerances
    (
      supplier_id,
      supplier_site_id,
      org_id,
      favourable_price_pct,
      max_price_amt,
      min_chargeback_amt,
      max_freight_amt,
      dist_var_neg_amt,
      dist_var_pos_amt,
      created_by,
      creation_date,
      last_updated_by,
      last_update_date
    )
    VALUES
    (
      p_vendor_id,
      p_vendor_site_id,
      p_org_id,
      30,
      50,
      2,
      0,
      1,
      1,
      fnd_global.user_id,
      SYSDATE,
      fnd_global.user_id,
      SYSDATE
    );
  RETURN('Y');
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'When others in xx_custom_tolerance :'||SQLERRM);
  RETURN('N');
END xx_custom_tolerance;
--+============================================================================+
--| Name          : xx_custom_sup_traits                                       |
--| Description   : This FUnction will process Supplier Traits for Supplier    |
--|                                                                            |
--|                                                                            |
--| Parameters    : p_sup_trait,p_sup_number                                   |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
FUNCTION xx_custom_sup_traits
  (
    p_sup_trait  IN VARCHAR2,
    p_sup_number IN NUMBER
  )
  RETURN VARCHAR2
IS
  lc_sup_trait      VARCHAR2(4000) := p_sup_trait || '-';
  lc_sup_tair_value VARCHAR2(100);
  ln_place          NUMBER;
  ln_sup_trait_id   NUMBER;
  ln_mat_count      NUMBER;
  lc_description    VARCHAR2(100);
  lc_enable_flag    VARCHAR2(100);
  lc_sup_trait_id   VARCHAR2(100);
  lc_master_sup_ind VARCHAR2(100);
BEGIN
  WHILE lc_sup_trait IS NOT NULL
  LOOP
    lc_description    :=NULL;
    lc_enable_flag    :=NULL;
    lc_sup_trait_id   :=NULL;
    lc_master_sup_ind :=NULL;
    ln_sup_trait_id   :=0;
    ln_mat_count      :=0;
    ln_place          := instr(lc_sup_trait,'-');             -- find the first separator
    lc_sup_tair_value := SUBSTR(lc_sup_trait,1,ln_place - 1); -- extract item
    BEGIN
      SELECT description,
        enable_flag,
        sup_trait_id,
        master_sup_ind
      INTO lc_description,
        lc_enable_flag,
        ln_sup_trait_id,
        lc_master_sup_ind
      FROM xx_ap_sup_traits
      WHERE sup_trait =lc_sup_tair_value;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      SELECT MAX(sup_trait_id) INTO ln_sup_trait_id FROM xx_ap_sup_traits;
      ln_sup_trait_id := ln_sup_trait_id+5;
      BEGIN
        INSERT
        INTO xx_ap_sup_traits
          (
            sup_trait,
            description,
            master_sup_ind,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by,
            last_update_login,
            enable_flag,
            sup_trait_id
          )
          VALUES
          (
            lc_sup_tair_value,
            lc_sup_tair_value,
            'N',
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            fnd_global.user_id,
            fnd_global.user_id,
            'Y',
            ln_sup_trait_id
          );
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message =>'When others, while inserting in xx_ap_sup_traits :'||SQLERRM, p_force =>false);
      END;
    WHEN OTHERS THEN
      print_debug_msg(p_message =>'When others, while retriving data for the Trait :'||p_sup_trait, p_force=>false);
    END;
    IF ln_sup_trait_id > 0 THEN
       SELECT COUNT(1)
         INTO ln_mat_count
         FROM xx_ap_sup_traits_matrix
        WHERE supplier   = p_sup_number
          AND sup_trait_id = ln_sup_trait_id;
       IF ln_mat_count  =0 THEN
        BEGIN
          INSERT
          INTO xx_ap_sup_traits_matrix
            (
              supplier,
              creation_date,
              created_by,
              last_update_date,
              last_updated_by,
              last_update_login,
              enable_flag,
              sup_trait_id
            )
            VALUES
            (
              p_sup_number,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              fnd_global.user_id,
              'Y',
              ln_sup_trait_id
            );
        EXCEPTION
          WHEN OTHERS THEN
            print_debug_msg(p_message =>'When others, while inserting in xx_ap_sup_traits_matrix, for the Trait :'||p_sup_trait, p_force=>false);
        END;
      END IF;
      lc_sup_trait := SUBSTR(lc_sup_trait,ln_place + 1); -- chop list
    END IF;                                              --IF ln_sup_trait_id > 0 THEN
  END LOOP;
  RETURN('Y');
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Main When others in xx_custom_sup_traits :'||SQLERRM);
  RETURN('N');
END xx_custom_sup_traits;
--+============================================================================+
--| Name          : process_bus_class                                          |
--| Description   : This procedure will Create Business Classification      |
--|     for Supplier              |
--|                                                                            |
--| Parameters    : gn_request_id                                   |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE process_bus_class
  (
    gn_request_id IN NUMBER
  )
IS
  CURSOR C1
  IS
  SELECT bus.rowid drowid,
         bus.supplier_name,
		 bus.classification,
  	     bus.supplier_number,
		 bus.subclassification,
		 bus.bcls_process_Flag,
		 sup.party_id,
		 sup.vendor_id
    FROM ap_suppliers sup,
         xx_ap_cld_suppliers_stg stg,
         xx_ap_cld_supp_bcls_stg bus
   WHERE 1                    =1
     AND bus.process_Flag       ='P'
     AND bus.bcls_process_flag  =2
     AND bus.request_id         = gn_request_id
     AND stg.request_id         = bus.request_id
     AND bus.supplier_number    = stg.segment1
     AND stg.supp_process_flag IN (7,8)
     AND sup.segment1           =stg.segment1;

  v_buss_flag  VARCHAR2(1);
  v_error_Flag VARCHAR2(1);
  ln_vendor_id NUMBER;
  ln_party_id  NUMBER;
  ln_cus_count NUMBER;
  lc_error_msg VARCHAR2(2000);
BEGIN
  print_debug_msg(p_message => 'Begin processing Business Classification ', p_force => true);
  FOR cur IN C1
  LOOP
    v_error_Flag    := NULL;
    g_ins_bus_class := 'N';
    ln_vendor_id    := NULL;
    ln_party_id     := NULL;
    v_buss_Flag     := NULL;
    ln_cus_count    := 0;

    SELECT COUNT(1)
      INTO ln_cus_count
      FROM pos_bus_class_attr
     WHERE 1                 = 1
       AND party_id            = cur.party_id
       AND vendor_id           = cur.vendor_id
       AND lookup_code         = cur.classification;
    IF cur.classification  IS NOT NULL AND ln_cus_count =0 THEN
       IF cur.classification ='FOB' OR cur.classification = 'MINORITY_OWNED' THEN
          print_debug_msg(p_message => 'Inserting into Business Classification for the Vendor '||cur.supplier_name||', classification : '||cur.classification , p_force => false);
          v_buss_Flag:= insert_bus_class(cur.party_id,cur.classification,cur.subclassification,cur.vendor_id);
       ELSE
          print_debug_msg(p_message => 'Inserting into BUS Class for the Vendor '||cur.supplier_name||', classification : '||cur.classification , p_force => false);
          v_buss_Flag:= insert_bus_class(cur.party_id,cur.classification,NULL,cur.vendor_id);
       END IF;

       UPDATE xx_ap_cld_supp_bcls_stg
          SET bcls_process_Flag=DECODE(v_buss_flag,'Y',7,'N',3),
              error_flag         =DECODE(v_buss_flag,'Y','N','N','Y'),
              error_msg          =DECODE(v_buss_flag,'Y',NULL,'N','Error while processing bus_class'),
              vendor_id          =cur.vendor_id,
              process_flag       ='Y'
        WHERE rowid          = cur.drowid;
       COMMIT;
    ELSIF cur.classification IS NOT NULL AND ln_cus_count >0 THEN
      UPDATE xx_ap_cld_supp_bcls_stg
         SET bcls_process_Flag=7,
             error_flag         ='N',
             error_msg          =NULL,
             vendor_id          =cur.vendor_id,
             process_flag       ='Y'
       WHERE rowid          = cur.drowid;
       COMMIT;
    END IF;
  END LOOP;
  print_debug_msg(p_message => 'End processing Business Classification ', p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message =>'When others in process bus class :'||SQLERRM, p_force => false);
END process_bus_class;
--+============================================================================+
--| Name          : xx_supp_dff                                               |
--| Description   : This procedure will Create Custom DFF Attributes to 3 groups|
--|     Also it will create Custom Tolerance, Supplier Traits    |
--|                                                                            |
--| Parameters    : gn_request_id                                   |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE xx_supp_dff(
    gn_request_id IN NUMBER)
IS
  CURSOR C1
  IS
    SELECT dff.rowid drowid,
      dff.supplier_number ,
      dff.supplier_name ,
      dff.vendor_site_code ,
      dff.edi_distribution_code ,
      dff.delivery_policy,
      dff.sup_trait ,
      dff.back_order_flag ,
      dff.od_date_signed ,
      dff.vendor_date_signed ,
      dff.eft_settle_days ,
      dff.min_prepaid_code ,
      dff.supplier_ship_to ,
      dff.deduct_from_invoice_flag ,
      dff.rtv_freight_payment_method ,
      dff.payment_frequency ,
      dff.rtv_instructions ,
      dff.addl_rtv_instructions ,
      dff.rga_marked_flag ,
      dff.remove_price_sticker_flag ,
      dff.contact_supplier_for_rga_flag ,
      dff.destroy_flag ,
      dff.serial_num_required_flag ,
      dff.permanent_rga ,
      dff.lead_time ,
      dff.vendor_min_amount ,
      dff.master_vendor_id ,
      dff.rtv_option ,
      dff.destroy_allow_amount ,
      dff.min_return_qty ,
      dff.min_return_amount ,
      dff.damage_destroy_limit ,
      dff.rtv_related_site ,
      dff.dff_process_flag ,
      site.create_flag ,
      site.vendor_id ,
      site.vendor_site_id,
      site.org_id,
	  site.attribute8   -- Added as per Version 2.0
    FROM xx_ap_cld_site_dff_stg dff,
         xx_ap_cld_supp_sites_stg site
    WHERE 1                     =1
    AND dff.process_Flag        = 'P'
    AND dff.dff_process_Flag    = 2
    AND dff.request_id          = gn_request_id
    AND dff.vendor_site_code    = site.vendor_site_code
    AND site.site_process_flag IN (7,8)
    AND site.request_id         = dff.request_id
    AND site.vendor_id         IS NOT NULL
    AND site.vendor_site_id    IS NOT NULL
    AND EXISTS
      (SELECT 1
      FROM ap_supplier_sites_all
      WHERE 1            =1
      AND vendor_id      = site.vendor_id
      AND vendor_site_id = site.vendor_site_id
      );
  v_kff_id                NUMBER;
  ln_tol_count            NUMBER;
  ln_kff_count            NUMBER;
  lc_attribute10          VARCHAR2(100);
  lc_attribute11          VARCHAR2(100);
  lc_attribute12          VARCHAR2(100);
  v_error_flag            VARCHAR2(1);
  v_trait_flag            VARCHAR2(1);
  v_tol_flag              VARCHAR2(1);
  lc_error_msg            VARCHAR2(2000);
  lc_vendor_site_code_alt VARCHAR2(100);
BEGIN
  FOR cur IN C1
  LOOP
    v_error_Flag            :='N';
    lc_attribute11          :=NULL;
    lc_attribute12          :=NULL;
    lc_attribute10          :=NULL;
    ln_tol_count            :=NULL;
    ln_kff_count            :=NULL;
    lc_error_msg            :=NULL;
    lc_vendor_site_code_alt := NULL;
    BEGIN
      SELECT attribute10 ,
        attribute11 ,
        attribute12 ,
        vendor_site_code_alt
      INTO lc_attribute10,
        lc_attribute11,
        lc_attribute12,
        lc_vendor_site_code_alt
      FROM ap_supplier_sites_all
      WHERE vendor_site_id = cur.vendor_site_id;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message => 'Error in Deriving Kff Values for site : '||cur.vendor_site_code||','|| SQLERRM ,p_force =>false);
    END;
    SELECT COUNT(1)
    INTO ln_kff_count
    FROM xx_po_vendor_sites_kff
    WHERE vs_kff_id IN (lc_attribute10,lc_attribute11,lc_attribute12);
    print_debug_msg(p_message => 'Vendor Site KFF Record Count : '||ln_kff_count , p_force => true);
    IF ln_kff_count = 0 THEN
      print_debug_msg(p_message => ' Inserting group 1 KFF ', p_force => true);
      BEGIN
        SELECT xx_po_vendor_sites_kff_s.NEXTVAL 
		 INTO v_kff_id 
		 FROM DUAL;
        INSERT
        INTO xx_po_vendor_sites_kff
          (
            vs_kff_id ,
            structure_id ,
            enabled_flag ,
            summary_flag ,
            start_date_active ,
            created_by ,
            creation_date ,
            last_updated_by ,
            last_update_date ,
            segment1 ,
            segment2 ,
            segment3,
            segment4 ,
            segment5 ,
            segment6 ,
            segment13 ,
            segment15 ,
            segment16 ,
            segment17
          )
          VALUES
          (
            v_kff_id ,
            101,
            'Y',
            'N',
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            cur.lead_time,
            cur.back_order_flag,
            cur.delivery_policy,
            cur.min_prepaid_code,
            cur.vendor_min_amount,
            cur.supplier_ship_to,
            cur.master_vendor_id,
            TO_CHAR(TO_DATE(cur.od_date_signed,'YYYY/MM/DD'),'DD-MON-RR'),
            TO_CHAR(TO_DATE(cur.vendor_date_signed,'YYYY/MM/DD'),'DD-MON-RR'),
            cur.deduct_from_invoice_flag
          );
        UPDATE ap_supplier_sites_all
        SET attribute10     =v_kff_id
        WHERE vendor_site_id=cur.vendor_site_id;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 101:';
      END;
      print_debug_msg(p_message => ' Inserting group 2 KFF ', p_force => true);
      BEGIN
        SELECT xx_po_vendor_sites_kff_s.NEXTVAL INTO v_kff_id FROM DUAL;
        INSERT
        INTO xx_po_vendor_sites_kff
          (
            vs_kff_id ,
            structure_id ,
            enabled_flag ,
            summary_flag ,
            start_date_active ,
            created_by ,
            creation_date ,
            last_updated_by ,
            last_update_date ,
            segment37
          )
          VALUES
          (
            v_kff_id,
            50350,
            'Y',
            'N',
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            cur.edi_distribution_code
          );
        UPDATE ap_supplier_sites_all
        SET attribute11     =v_kff_id
        WHERE vendor_site_id=cur.vendor_site_id;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 50350:';
      END;
      print_debug_msg(p_message => ' Inserting group 3 KFF ', p_force => true);
      BEGIN
        SELECT xx_po_vendor_sites_kff_s.NEXTVAL INTO v_kff_id FROM DUAL;
        INSERT
        INTO xx_po_vendor_sites_kff
          (
            vs_kff_id ,
            structure_id ,
            enabled_flag ,
            summary_flag ,
            start_date_active ,
            created_by ,
            creation_date ,
            last_updated_by ,
            last_update_date ,
            segment40 ,
            segment41 ,
            segment42 ,
            segment43 ,
            segment44 ,
            segment45 ,
            segment46 ,
            segment47 ,
            segment48 ,
            segment49 ,
            segment50 ,
            segment51 ,
            segment52 ,
            segment53 ,
            segment54,
            segment58
          )
          VALUES
          (
            v_kff_id,
            50351,
            'Y',
            'N',
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            fnd_global.user_id,
            SYSDATE,
            cur.rtv_option,
            cur.rtv_freight_payment_method,
            cur.permanent_rga,
            cur.destroy_allow_amount,
            cur.payment_frequency,
            cur.min_return_qty,
            cur.min_return_amount,
            cur.damage_destroy_limit,
            cur.rtv_instructions,
            cur.addl_rtv_instructions,
            cur.rga_marked_flag,
            cur.remove_price_sticker_flag,
            cur.contact_supplier_for_rga_flag,
            cur.destroy_flag,
            cur.serial_num_required_flag,
            cur.rtv_related_site
          );
        UPDATE ap_supplier_sites_all
        SET attribute12     =v_kff_id
        WHERE vendor_site_id=cur.vendor_site_id;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 50351:';
      END;
      print_debug_msg(p_message => 'After insert, Updating flags in xx_ap_cld_site_dff_stg ', p_force => true);
      UPDATE xx_ap_cld_site_dff_stg
      SET dff_process_Flag = DECODE(v_error_Flag,'Y',6,'N',7),
        error_msg          = DECODE(v_error_Flag,'Y',lc_error_msg,'N',NULL),
        error_flag         = DECODE(v_error_Flag,'Y','Y','N','N'),
        vendor_id          = cur.vendor_id,
        vendor_site_id     = cur.vendor_site_id,
        process_Flag       = 'Y'
      WHERE rowid          =cur.drowid;
      --===============================================================
      -- Inserting into Custom Supplier Traits    --
      --===============================================================
      print_debug_msg(p_message => ' Calling Cupplier Traits for Trait : '||cur.sup_trait||', Site : '||cur.vendor_site_code, p_force =>false);
      IF cur.sup_trait IS NOT NULL THEN
        v_trait_flag   := xx_custom_sup_traits(cur.sup_trait,NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id ) );
      END IF;
      --===============================================================
      -- Processing Custom Tolerance    --
      --===============================================================
	  IF cur.attribute8 LIKE 'TR%' THEN   -- Added as per Version 2.0
         SELECT COUNT(1)
         INTO ln_tol_count
         FROM xx_ap_custom_tolerances
         WHERE 1              =1
         AND supplier_id      = cur.vendor_id
         AND supplier_site_id = cur.vendor_site_id ;
         print_debug_msg(p_message => 'Custom Tolerance for the vendor : '||cur.supplier_number||', Site : '||cur.vendor_site_code, p_force => false);
         IF ln_tol_count = 0 THEN
            v_tol_flag   := xx_custom_tolerance(cur.vendor_id, cur.vendor_site_id,cur.org_id);
         END IF;
         COMMIT;
	  END IF;
    ELSIF ln_kff_count   >0 AND ( lc_attribute10 IS NOT NULL OR lc_attribute11 IS NOT NULL OR lc_attribute12 IS NOT NULL) THEN
      IF lc_attribute10 IS NOT NULL THEN
        UPDATE xx_po_vendor_sites_kff
        SET last_updated_by = fnd_global.user_id,
          last_update_date  = SYSDATE,
          segment1          = cur.lead_time,
          segment2          = cur.back_order_flag,
          segment3          = cur.delivery_policy,
          segment4          = cur.min_prepaid_code,
          segment5          = cur.vendor_min_amount,
          segment6          = cur.supplier_ship_to,
          segment13         = cur.master_vendor_id,
          segment15         = TO_CHAR(TO_DATE(cur.od_date_signed,'YYYY/MM/DD'),'DD-MON-RR'),
          segment16         = TO_CHAR(TO_DATE(cur.vendor_date_signed,'YYYY/MM/DD'),'DD-MON-RR'),
          segment17         = cur.deduct_from_invoice_flag
        WHERE vs_kff_id     = lc_attribute10
        AND structure_id    = 101;
        IF SQL%ROWCOUNT     =0 THEN
          v_error_Flag     :='Y';
          lc_error_msg     :=lc_error_msg||' No Record exists for the structure_id 101';
        END IF;
      ELSIF lc_attribute10 IS NULL THEN
        BEGIN
          SELECT xx_po_vendor_sites_kff_s.NEXTVAL INTO v_kff_id FROM DUAL;
          INSERT
          INTO xx_po_vendor_sites_kff
            (
              vs_kff_id ,
              structure_id ,
              enabled_flag ,
              summary_flag ,
              start_date_active ,
              created_by ,
              creation_date ,
              last_updated_by ,
              last_update_date ,
              segment1 ,
              segment2 ,
              segment3,
              segment4 ,
              segment5 ,
              segment6 ,
              segment13 ,
              segment15 ,
              segment16 ,
              segment17
            )
            VALUES
            (
              v_kff_id ,
              101,
              'Y',
              'N',
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              cur.lead_time,
              cur.back_order_flag,
              cur.delivery_policy,
              cur.min_prepaid_code,
              cur.vendor_min_amount,
              cur.supplier_ship_to,
              cur.master_vendor_id,
              TO_CHAR(TO_DATE(cur.od_date_signed,'YYYY/MM/DD'),'DD-MON-RR'),
              TO_CHAR(TO_DATE(cur.vendor_date_signed,'YYYY/MM/DD'),'DD-MON-RR'),
              cur.deduct_from_invoice_flag
            );
          UPDATE ap_supplier_sites_all
             SET attribute10     =v_kff_id
           WHERE vendor_site_id=cur.vendor_site_id;
        EXCEPTION
        WHEN OTHERS THEN
          v_error_flag :='Y';
          lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 101:';
        END;
      END IF;
      IF lc_attribute11 IS NOT NULL THEN
         UPDATE xx_po_vendor_sites_kff
            SET last_updated_by = fnd_global.user_id,
                last_update_date  = SYSDATE,
                segment37         = cur.edi_distribution_code
          WHERE vs_kff_id     = lc_attribute11
            AND structure_id    = 50350;
         IF SQL%ROWCOUNT     =0 THEN
           v_error_Flag     :='Y';
           lc_error_msg     :=lc_error_msg||' No Record exists for the structure_id 50350';
         END IF;
      ELSIF lc_attribute11 IS NULL THEN
        BEGIN
          SELECT xx_po_vendor_sites_kff_s.NEXTVAL INTO v_kff_id FROM DUAL;
          INSERT
          INTO xx_po_vendor_sites_kff
            (
              vs_kff_id ,
              structure_id ,
              enabled_flag ,
              summary_flag ,
              start_date_active ,
              created_by ,
              creation_date ,
              last_updated_by ,
              last_update_date ,
              segment37
            )
            VALUES
            (
              v_kff_id,
              50350,
              'Y',
              'N',
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              cur.edi_distribution_code
            );
          UPDATE ap_supplier_sites_all
             SET attribute11     =v_kff_id
           WHERE vendor_site_id=cur.vendor_site_id;
        EXCEPTION
          WHEN OTHERS THEN
            v_error_flag :='Y';
            lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 50350:';
        END;
      END IF;
      IF lc_attribute12 IS NOT NULL THEN
        UPDATE xx_po_vendor_sites_kff
 		   SET last_updated_by = fnd_global.user_id,
			   last_update_date  = SYSDATE,
			   segment37         = cur.edi_distribution_code,
			   segment40         = cur.rtv_option,
			   segment41         = cur.rtv_freight_payment_method,
			   segment42         = cur.permanent_rga,
			   segment43         = cur.destroy_allow_amount,
			   segment44         = cur.payment_frequency,
			   segment45         = cur.min_return_qty,
			   segment46         = cur.min_return_amount,
			   segment47         = cur.damage_destroy_limit,
			   segment48         = cur.rtv_instructions,
			   segment49         = cur.addl_rtv_instructions,
			   segment50         = cur.rga_marked_flag,
			   segment51         = cur.remove_price_sticker_flag,
			   segment52         = cur.contact_supplier_for_rga_flag,
			   segment53         = cur.destroy_flag,
			   segment54         = cur.serial_num_required_flag,
			   segment58         = cur.rtv_related_site
         WHERE vs_kff_id     = lc_attribute12
           AND structure_id    = 50351;
        IF SQL%ROWCOUNT     =0 THEN
           v_error_Flag     :='Y';
           lc_error_msg     :=lc_error_msg||' No Record exists for the structure_id 50351';
        END IF;
      ELSIF lc_attribute12 IS NULL THEN
        BEGIN
          SELECT xx_po_vendor_sites_kff_s.NEXTVAL INTO v_kff_id FROM DUAL;
          INSERT
          INTO xx_po_vendor_sites_kff
            (
              vs_kff_id ,
              structure_id ,
              enabled_flag ,
              summary_flag ,
              start_date_active ,
              created_by ,
              creation_date ,
              last_updated_by ,
              last_update_date ,
              segment40 ,
              segment41 ,
              segment42 ,
              segment43 ,
              segment44 ,
              segment45 ,
              segment46 ,
              segment47 ,
              segment48 ,
              segment49 ,
              segment50 ,
              segment51 ,
              segment52 ,
              segment53 ,
              segment54,
              segment58
            )
            VALUES
            (
              v_kff_id,
              50351,
              'Y',
              'N',
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE,
              cur.rtv_option,
              cur.rtv_freight_payment_method,
              cur.permanent_rga,
              cur.destroy_allow_amount,
              cur.payment_frequency,
              cur.min_return_qty,
              cur.min_return_amount,
              cur.damage_destroy_limit,
              cur.rtv_instructions,
              cur.addl_rtv_instructions,
              cur.rga_marked_flag,
              cur.remove_price_sticker_flag,
              cur.contact_supplier_for_rga_flag,
              cur.destroy_flag,
              cur.serial_num_required_flag,
              cur.rtv_related_site
            );
          UPDATE ap_supplier_sites_all
             SET attribute12     =v_kff_id
           WHERE vendor_site_id=cur.vendor_site_id;
        EXCEPTION
          WHEN OTHERS THEN
            v_error_flag :='Y';
            lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 50351:';
        END;
      END IF;
      --===============================================================
      -- Inserting into Custom Supplier Traits    --
      --===============================================================
      print_debug_msg(p_message => ' Calling Cupplier Traits for Trait : '||cur.sup_trait||' cur.supplier_number : '||cur.supplier_number, p_force => true);
      v_trait_flag := xx_custom_sup_traits(cur.sup_trait,NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id ) );
      UPDATE xx_ap_cld_site_dff_stg
         SET dff_process_Flag = DECODE(v_error_Flag,'Y',6,'N',7),
             error_msg          = DECODE(v_error_Flag,'Y',lc_error_msg,'N',NULL),
             error_flag         = DECODE(v_error_Flag,'Y','Y','N','N'),
             vendor_id          = cur.vendor_id,
             vendor_site_id     = cur.vendor_site_id,
             process_Flag       = 'Y'
       WHERE rowid          =cur.drowid;
      COMMIT;
    END IF;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message => 'Error in processing xx_supp_dff '||SQLERRM, p_force => true);
END xx_supp_dff;
--+============================================================================+
--| Name          : update_supplier                                           |
--| Description   : This procedure will update supplier details using API  |
--|                                                                            |
--| Parameters    : p_vendor_is                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE update_supplier(
						   x_ret_code OUT NUMBER ,
						   x_return_status OUT VARCHAR2 ,
						   x_err_buf OUT VARCHAR2 
						 )
IS
CURSOR c_supplier
IS
SELECT *
  FROM xx_ap_cld_suppliers_stg xas
 WHERE xas.create_flag     ='N'---Update
   AND xas.supp_process_flag =gn_process_status_validated
   AND xas.REQUEST_ID        = fnd_global.conc_request_id;

  lr_vendor_rec ap_vendor_pub_pkg.r_vendor_rec_type;
  lr_existing_vendor_rec ap_suppliers%rowtype;
  v_api_version                     NUMBER;
  v_init_msg_list                   VARCHAR2(200);
  v_commit                          VARCHAR2(200);
  v_validation_level                NUMBER;
  l_msg                             VARCHAR2(200);
  l_program_step                    VARCHAR2 (100) := '';
  x_msg_count                       NUMBER;
  x_msg_data                        VARCHAR2(200);
  l_process_flag                    VARCHAR2(10);
  lc_inspection_required_flag	    VARCHAR2(200);
  lc_receipt_required_flag	        VARCHAR2(200);
  ln_qty_rcv_tolerance	            NUMBER;
  lc_qty_rcv_exception_code	        VARCHAR2(200);
  lc_enforce_ship_to_loc_code	    VARCHAR2(200);
  ln_days_early_receipt_allowed	    NUMBER;
  ln_days_late_receipt_allowed	    NUMBER;
  lc_receipt_days_exception_code	VARCHAR2(200);
  ln_receiving_routing_id	        NUMBER;
  lc_allow_substitute_rcpts_flag	VARCHAR2(200);
  lc_allow_unordered_rcpts_flag	    VARCHAR2(200);

BEGIN
  /*Intializing Values**/

  v_api_version      := 1.0;
  v_init_msg_list    := fnd_api.g_true;
  v_commit           := fnd_api.g_true;
  v_validation_level := fnd_api.g_valid_level_full;
  l_program_step     := 'START';

  FOR c_sup IN c_supplier
  LOOP
    lc_inspection_required_flag	     := NULL;    
    lc_receipt_required_flag	     := NULL;     
    ln_qty_rcv_tolerance	         := NULL;         
    lc_qty_rcv_exception_code	     := NULL;     
    lc_enforce_ship_to_loc_code      := NULL;	
    ln_days_early_receipt_allowed	 := NULL;   
    ln_days_late_receipt_allowed	 := NULL;  
    lc_receipt_days_exception_code	 := NULL;
    ln_receiving_routing_id	         := NULL; 
    lc_allow_substitute_rcpts_flag	 := NULL;
    lc_allow_unordered_rcpts_flag	 := NULL;
	
    BEGIN
      SELECT *
        INTO lr_existing_vendor_rec
        FROM ap_suppliers asa
       WHERE asa.segment1 =c_sup.segment1;
    EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message=> l_program_step||': Unable to derive the supplier  information for vendor id ' ||lr_existing_vendor_rec.vendor_id , p_force=>true);
    END;
    IF lr_existing_vendor_rec.vendor_id IS NOT NULL THEN
          print_debug_msg(p_message=> 'Updating Supplier # :'|| c_sup.segment1, p_force=>true);
		  lr_vendor_rec.vendor_id                    := lr_existing_vendor_rec.vendor_id;
		  lr_vendor_rec.vendor_type_lookup_code      :=UPPER(NVL(c_sup.vendor_type_lookup_code, FND_API.G_MISS_CHAR));
		  lr_vendor_rec.organization_type_lookup_code:=UPPER(NVL(c_sup.organization_type, FND_API.G_MISS_CHAR));
		  lr_vendor_rec.end_date_active              :=NVL(TO_DATE(c_sup.end_date_active,'YYYY/MM/DD'),FND_API.G_MISS_DATE);
		  lr_vendor_rec.one_time_flag                :=NVL(c_sup.one_time_flag, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.min_order_amount             :=NVL(c_sup.min_order_amount,FND_API.G_MISS_NUM);
		  lr_vendor_rec.customer_num                 :=NVL(c_sup.customer_num, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.federal_reportable_flag      :=NVL(c_sup.federal_reportable_flag, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.type_1099                    :=NVL(c_sup.type_1099, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.state_reportable_flag        :=NVL(c_sup.state_reportable_flag, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.tax_reporting_name           :=NVL(c_sup.tax_reporting_name, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.name_control                 :=NVL(c_sup.name_control, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.tax_verification_date        :=NVL(TO_DATE(c_sup.tax_verification_date,'YYYY/MM/DD'),FND_API.G_MISS_DATE);
		  lr_vendor_rec.allow_awt_flag               :=NVL(c_sup.allow_awt_flag, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.vat_code                     :=c_sup.vat_code;
		  lr_vendor_rec.vat_registration_num         :=c_sup.vat_registration_num;
		  lr_vendor_rec.attribute_category           :=NVL(c_sup.attribute_category, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute3                   :=NVL(c_sup.attribute3, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute2                   :=NVL(c_sup.attribute2, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute4                   :=NVL(c_sup.attribute4, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute5                   :=NVL(c_sup.attribute5, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute6                   :=NVL(c_sup.attribute6, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute7                   :=NVL(c_sup.attribute7, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute8                   :=NVL(c_sup.attribute8, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute9                   :=NVL(c_sup.attribute9, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute10                  :=NVL(c_sup.attribute10, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute11                  :=NVL(c_sup.attribute11, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute12                  :=NVL(c_sup.attribute12, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute13                  :=NVL(c_sup.attribute13, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute14                  :=NVL(c_sup.attribute14, FND_API.G_MISS_CHAR);
		  lr_vendor_rec.attribute15                  :=NVL(c_sup.attribute15, FND_API.G_MISS_CHAR);
		  
		  /* Added as per Version 2.1 by Havish Kasina */
		  --==============================================================================
		  -- To get the Receiving details from the Supplier Sites Staging table
		  --==============================================================================
		  print_debug_msg(p_message=> l_program_step||': Fetching the Receiving Information for the Supplier ' ||c_sup.segment1 , p_force=>true);

		  get_receiving_details(p_supplier_num                 => c_sup.segment1 ,
                                o_inspection_required_flag     => lc_inspection_required_flag	   , 
								o_receipt_required_flag        => lc_receipt_required_flag	       ,     
								o_qty_rcv_tolerance            => ln_qty_rcv_tolerance	           ,         
								o_qty_rcv_exception_code       => lc_qty_rcv_exception_code	       ,     
								o_enforce_ship_to_loc_code     => lc_enforce_ship_to_loc_code      ,	 
								o_days_early_receipt_allowed   => ln_days_early_receipt_allowed	   ,
								o_days_late_receipt_allowed    => ln_days_late_receipt_allowed	   , 
								o_receipt_days_exception_code  => lc_receipt_days_exception_code   ,
								o_receiving_routing_id         => ln_receiving_routing_id          ,	     
								o_allow_substitute_rcpts_flag  => lc_allow_substitute_rcpts_flag   ,
								o_allow_unordered_rcpts_flag   => lc_allow_unordered_rcpts_flag	 
                               );
							   
		  UPDATE xx_ap_cld_suppliers_stg
             SET inspection_required_flag       =  lc_inspection_required_flag,	     
                 receipt_required_flag          =  lc_receipt_required_flag,	         
                 qty_rcv_tolerance              =  ln_qty_rcv_tolerance,	             
                 qty_rcv_exception_code         =  lc_qty_rcv_exception_code,     
                 enforce_ship_to_location_code  =  lc_enforce_ship_to_loc_code, 
                 days_early_receipt_allowed     =  ln_days_early_receipt_allowed, 
                 days_late_receipt_allowed      =  ln_days_late_receipt_allowed,	     
                 receipt_days_exception_code    =  lc_receipt_days_exception_code,	 
                 receiving_routing_id           =  ln_receiving_routing_id,	         
                 allow_substitute_receipts_flag =  lc_allow_substitute_rcpts_flag,
                 allow_unordered_receipts_flag  =  lc_allow_unordered_rcpts_flag,	       		 
                 last_updated_by     = g_user_id,
                 last_update_date    = SYSDATE
           WHERE 1 = 1
             AND segment1          = c_sup.segment1
             AND request_id        = gn_request_id;
			 
		   print_debug_msg(p_message=> l_program_step||': Successfully loaded the Receiving Information to the xx_ap_cld_suppliers_stgStaging Table ', p_force=>true);
		  
		  IF lc_inspection_required_flag IS NOT NULL OR 
		     lc_receipt_required_flag    IS NOT NULL OR     
			 ln_qty_rcv_tolerance IS NOT NULL OR	        
			 lc_qty_rcv_exception_code   IS NOT NULL OR    
			 lc_enforce_ship_to_loc_code IS NOT NULL OR
			 ln_days_early_receipt_allowed IS NOT NULL OR 
			 ln_days_late_receipt_allowed IS NOT NULL OR	
			 lc_receipt_days_exception_code IS NOT NULL OR	
			 ln_receiving_routing_id IS NOT NULL OR        
			 lc_allow_substitute_rcpts_flag IS NOT NULL OR
			 lc_allow_unordered_rcpts_flag IS NOT NULL	
		  THEN
		      lr_vendor_rec.inspection_required_flag        :=  lc_inspection_required_flag;    
			  lr_vendor_rec.receipt_required_flag           :=  lc_receipt_required_flag;	    
			  lr_vendor_rec.qty_rcv_tolerance               :=  ln_qty_rcv_tolerance;	        
			  lr_vendor_rec.qty_rcv_exception_code          :=  lc_qty_rcv_exception_code;    
			  lr_vendor_rec.enforce_ship_to_location_code   :=  lc_enforce_ship_to_loc_code; 
			  lr_vendor_rec.days_early_receipt_allowed      :=  ln_days_early_receipt_allowed;
			  lr_vendor_rec.days_late_receipt_allowed       :=  ln_days_late_receipt_allowed;
			  lr_vendor_rec.receipt_days_exception_code     :=  lc_receipt_days_exception_code;	
			  lr_vendor_rec.receiving_routing_id            :=  ln_receiving_routing_id;	        
			  lr_vendor_rec.allow_substitute_receipts_flag  :=  lc_allow_substitute_rcpts_flag;
			  lr_vendor_rec.allow_unordered_receipts_flag   :=  lc_allow_unordered_rcpts_flag;
          END IF;			  
			
          /* End of Changes Added for Version 2.1 by Havish Kasina */			
			 		  
		  fnd_msg_pub.initialize; --to make msg_count 0
		  x_return_status:=NULL;
		  x_msg_count    :=NULL;
		  x_msg_data     :=NULL;
		  -------------------------------------------------Calling API
		  ap_vendor_pub_pkg.update_vendor(  p_api_version => v_api_version, 
											p_init_msg_list => v_init_msg_list, 
											p_commit => v_commit, 
											p_validation_level => v_validation_level, 
											x_return_status => x_return_status, 
											x_msg_count => x_msg_count, 
											x_msg_data => x_msg_data, 
											p_vendor_rec => lr_vendor_rec, 
											p_vendor_id => lr_existing_vendor_rec.vendor_id 
										 );
      
		  print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS = ' || x_return_status, p_force=>true);
          print_debug_msg(p_message=> l_program_step||'X_MSG_COUNT = ' || x_msg_count, p_force=>true);
          print_debug_msg(p_message=> l_program_step||'X_MSG_DATA = ' || x_msg_data , p_force=>true);
      
	      IF (x_return_status <> fnd_api.g_ret_sts_success) THEN
        
			FOR i IN 1 .. fnd_msg_pub.count_msg
			LOOP
			  l_msg := fnd_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false);
              print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
            END LOOP;
            l_process_flag:='E';
          ELSE
            print_debug_msg(p_message=> l_program_step||'The API call ended with SUCESSS status', p_force=>true);
			l_process_flag:='Y';
			l_msg         :='';
		  END IF;
		  -----------------------Update the status if API successfully updated the record.
      
		  UPDATE xx_ap_cld_suppliers_stg xas
			 SET xas.supp_process_flag   =DECODE (l_process_flag,'Y',gn_process_status_imported,'E',gn_process_status_imp_fail),---6
				 xas.error_flag          =DECODE( l_process_flag,'N',NULL,'E','Y'),		
				 xas.error_msg           =l_msg
		   WHERE xas.supp_process_flag   =gn_process_status_validated	
			 AND xas.request_id          = gn_request_id
			 AND xas.segment1            =c_sup.segment1;
		  COMMIT;
    END IF; --lr_existing_vendor_rec.vendor_id IS NOT NULL THEN
  END LOOP;
  print_debug_msg(p_message=> 'After Update Supplier Call ', p_force=>true);
EXCEPTION
  WHEN OTHERS THEN
    x_ret_code      := 1;
    x_return_status := 'E';
    x_err_buf       := 'In exception for procedure update_Supplier' ;
    print_debug_msg(p_message=> l_program_step||'The API call procedure ended in Exception', p_force=>true);
END update_supplier;

--+============================================================================+
--| Name          : udpate_records for Supplier SIte                                          |
--| Description   : This procedure will update supplier Site details using API  |
--|                                                                            |
--| Parameters    : p_vendor_is                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE update_supplier_sites( x_ret_code 	 OUT NUMBER ,
								 x_return_status OUT VARCHAR2 ,
								 x_err_buf 		 OUT VARCHAR2
							   )
IS
  p_api_version      		NUMBER;
  p_init_msg_list    		VARCHAR2(200);
  p_commit           		VARCHAR2(200);
  p_validation_level 		NUMBER;
  x_msg_count        		NUMBER;
  x_msg_data         		VARCHAR2(200);
  l_msg              		VARCHAR2(2000);
  l_process_flag     		VARCHAR2(10);
  lr_vendor_site_rec 		ap_vendor_pub_pkg.r_vendor_site_rec_type;
  lr_existing_vendor_site_rec ap_supplier_sites_all%rowtype;
  p_calling_prog   			VARCHAR2(200);
  l_program_step   			VARCHAR2 (100) := '';
  ln_msg_index_num 			NUMBER;

CURSOR c_supplier_site
IS
SELECT *
  FROM xx_ap_cld_supp_sites_stg xas
 WHERE xas.create_flag     ='N'
   AND xas.site_process_flag =gn_process_status_validated
   AND xas.request_id        = gn_request_id;
BEGIN
  -- Assign Basic Values
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';
  
  FOR c_sup_site IN c_supplier_site
  LOOP
    BEGIN
      SELECT *
        INTO lr_existing_vendor_site_rec
        FROM ap_supplier_sites_all assa
       WHERE assa.vendor_site_code = c_sup_site.vendor_site_code
         AND assa.vendor_id          =c_sup_site.vendor_id
         AND assa.org_id             =c_sup_site.org_id;
    EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message=> l_program_step||'Unable to derive the supplier site information for site id:' || lr_existing_vendor_site_rec.vendor_site_id, p_force=>true);
    END;

    -- Assign Vendor Site Details
    lr_vendor_site_rec.vendor_site_id               := lr_existing_vendor_site_rec.vendor_site_id;
    lr_vendor_site_rec.last_update_date             := SYSDATE;
    lr_vendor_site_rec.vendor_id                    := lr_existing_vendor_site_rec.vendor_id;
    lr_vendor_site_rec.org_id                       := lr_existing_vendor_site_rec.org_id;
    lr_vendor_site_rec.rfq_only_site_flag           :=NVL(c_sup_site.rfq_only_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.purchasing_site_flag         :=NVL(c_sup_site.purchasing_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pcard_site_flag              :=NVL(c_sup_site.pcard_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_site_flag                :=NVL(c_sup_site.pay_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.primary_pay_site_flag        :=NVL(c_sup_site.primary_pay_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.fax_area_code                :=NVL(c_sup_site.fax_area_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.fax                          :=NVL(c_sup_site.fax, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.inactive_date                :=NVL(TO_DATE(c_sup_site.inactive_date,'YYYY/MM/DD'),FND_API.G_MISS_DATE); 
    lr_vendor_site_rec.customer_num                 :=NVL(c_sup_site.customer_num, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.ship_via_lookup_code         :=NVL(c_sup_site.ship_via_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.freight_terms_lookup_code    :=NVL(c_sup_site.freight_terms_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.fob_lookup_code              :=NVL(c_sup_site.fob_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.terms_date_basis             :=NVL(c_sup_site.terms_date_basis, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_group_lookup_code        :=NVL(c_sup_site.pay_group_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.payment_priority             :=NVL(c_sup_site.payment_priority,FND_API.G_MISS_NUM);
    lr_vendor_site_rec.terms_id                     :=NVL(c_sup_site.terms_id,FND_API.G_MISS_NUM);
    lr_vendor_site_rec.invoice_amount_limit         :=NVL(c_sup_site.invoice_amount_limit,FND_API.G_MISS_NUM);
    lr_vendor_site_rec.pay_date_basis_lookup_code   :=NVL(c_sup_site.pay_date_basis_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.always_take_disc_flag        :=NVL(c_sup_site.always_take_disc_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.invoice_currency_code        :=NVL(c_sup_site.invoice_currency_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.payment_currency_code        :=NVL(c_sup_site.payment_currency_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_all_payments_flag       :=NVL(c_sup_site.hold_all_payments_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_future_payments_flag    :=NVL(c_sup_site.hold_future_payments_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_unmatched_invoices_flag :=NVL(c_sup_site.hold_unmatched_invoices_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_reason                  :=NVL(c_sup_site.hold_reason, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_reason                  :=NVL(c_sup_site.purchasing_hold_reason, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.tax_reporting_site_flag      :=NVL(c_sup_site.tax_reporting_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.exclude_freight_from_discount:=NVL(c_sup_site.exclude_freight_from_discount, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_on_code                  :=NVL(c_sup_site.pay_on_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_on_receipt_summary_code  :=NVL(c_sup_site.pay_on_receipt_summary_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.match_option                 :=NVL(c_sup_site.match_option, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.country_of_origin_code       :=NVL(c_sup_site.country_of_origin_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.create_debit_memo_flag       :=NVL(c_sup_site.create_debit_memo_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.supplier_notif_method        :=NVL(c_sup_site.supplier_notif_method, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.email_address                :=NVL(c_sup_site.email_address, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.tolerance_name               :=NVL(c_sup_site.tolerance_name, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.services_tolerance_name      :=NVL(c_sup_site.service_tolerance, FND_API.G_MISS_CHAR); -- Added as per Version 1.6
    lr_vendor_site_rec.gapless_inv_num_flag         :=NVL(c_sup_site.gapless_inv_num_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.selling_company_identifier   :=NVL(c_sup_site.selling_company_identifier, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.bank_charge_bearer           :=NVL(c_sup_site.bank_charge_bearer, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.vat_code                     :=NVL(c_sup_site.vat_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.vat_registration_num         :=NVL(c_sup_site.vat_registration_num, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.remit_advice_delivery_method :=NVL(c_sup_site.remit_advice_delivery_method, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.remittance_email             :=NVL(c_sup_site.remittance_email, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute_category           :=NVL(c_sup_site.attribute_category, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute1                   :=NVL(c_sup_site.attribute1, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute2                   :=NVL(c_sup_site.attribute2, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute3                   :=NVL(c_sup_site.attribute3, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute4                   :=NVL(c_sup_site.attribute4, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute5                   :=NVL(c_sup_site.attribute5, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute6                   :=NVL(c_sup_site.attribute6, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute7                   :=NVL(c_sup_site.attribute7, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute8                   :=NVL(c_sup_site.attribute8, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute9                   :=NVL(c_sup_site.attribute9, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute13                  :=NVL(c_sup_site.attribute13, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute14                  :=NVL(c_sup_site.attribute14, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.phone                        :=NVL(c_sup_site.phone_number, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.area_code                    :=NVL(c_sup_site.phone_area_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.province                     :=NVL(c_sup_site.province, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.state                        :=NVL(c_sup_site.state, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.city                         :=NVL(c_sup_site.city, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.address_line2                :=NVL(c_sup_site.address_line2, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.address_line1                :=NVL(c_sup_site.address_line1, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.country                      :=NVL(c_sup_site.country, FND_API.G_MISS_CHAR);
	lr_vendor_site_rec.duns_number                  :=NVL(c_sup_site.attribute5, FND_API.G_MISS_CHAR); -- Added as per Version 1.9 by Havish Kasina

    fnd_msg_pub.initialize; --to make msg_count 0
    x_return_status:=NULL;
    x_msg_count    :=NULL;
    x_msg_data     :=NULL;
    -------------------------Calling Site API
    ap_vendor_pub_pkg.update_vendor_site_public(p_api_version => p_api_version, 
	                                            p_init_msg_list => p_init_msg_list,
												p_commit => p_commit, 
												p_validation_level => p_validation_level,
												x_return_status => x_return_status, 
												x_msg_count => x_msg_count, 
												x_msg_data => x_msg_data, 
												p_vendor_site_rec => lr_vendor_site_rec, 
												p_vendor_site_id => lr_vendor_site_rec.vendor_site_id, 
												p_calling_prog => p_calling_prog 
											   );
    COMMIT;

    print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS = ' || x_return_status, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
    print_debug_msg(p_message=> l_program_step||'X_MSG_COUNT = ' || x_msg_count, p_force=>true);
    IF x_msg_count > 0 THEN
       print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
       print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
       FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
       LOOP
         fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
         print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
      END LOOP;
      l_process_flag:='E';
    ELSE
      print_debug_msg(p_message=> l_program_step||'The API call ended with SUCESSS status', p_force=>true);
      l_process_flag:='Y';
      l_msg         :='';
    END IF;
    print_debug_msg(p_message=> l_program_step||'l_process_flag '||l_process_flag, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'c_sup_site.supplier_name '||c_sup_site.supplier_name, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'fnd_global.conc_request_id '||fnd_global.conc_request_id, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'c_sup_site.vendor_site_code '||c_sup_site.vendor_site_code, p_force=>true);
    BEGIN
      UPDATE xx_ap_cld_supp_sites_stg xas
         SET xas.site_process_flag   =DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),---6 ,---6
             xas.error_flag          =DECODE(l_process_flag,'Y',NULL,'E','Y'),
             xas.error_msg           =l_msg,
             process_flag            =l_process_flag
       WHERE xas.site_process_flag   =gn_process_status_validated
         AND xas.request_id          = gn_request_id
         AND xas.supplier_number     = c_sup_site.supplier_number
         AND xas.vendor_site_code    = c_sup_site.vendor_site_code
         AND xas.org_id              =c_sup_site.org_id;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message=> l_program_step||'In Exception to update records', p_force=>true);
    END ;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    x_ret_code      := 1;
    x_return_status := 'E';
    x_err_buf       := 'In exception for procedure update_Supplier' ;
END update_supplier_sites;
--+============================================================================+
--| Name          :Update_supplier_contact for Supplier                                     |
--| Description   : This procedure will update supplier conatct details using API  |
--|                                                                            |
--| Parameters    :x_ret_code OUT NUMBER ,
--|                 x_return_status OUT VARCHAR2 ,
--|                 x_err_buf OUT VARCHAR2                           |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE update_supplier_contact( x_ret_code 		OUT NUMBER ,
								   x_return_status 	OUT VARCHAR2 ,
								   x_err_buf 		OUT VARCHAR2 
								 )
IS
  p_api_version      		NUMBER;
  p_validation_level 		NUMBER;
  x_msg_count        		NUMBER;
  ln_msg_index_num   		NUMBER;
  p_init_msg_list    		VARCHAR2(200);
  p_commit           		VARCHAR2(200);
  x_msg_data         		VARCHAR2(200);
  p_calling_prog     		VARCHAR2(200);
  l_program_step     		VARCHAR2 (100) := '';
  l_msg              		VARCHAR2(2000);
  l_process_flag     		VARCHAR2(10);
  l_email_address 			hz_contact_points.email_address%TYPE;
  l_phone_number 			hz_contact_points.phone_number%TYPE;
  l_fax_number 				hz_contact_points.phone_number%TYPE;
  l_phone_area_code 		hz_contact_points.phone_area_code%TYPE;
  l_fax_area_code 			hz_contact_points.phone_area_code%TYPE;
  lv_vendor_contact_rec 	ap_vendor_pub_pkg.r_vendor_contact_rec_type;
  lv_contact_title_rec 		hz_party_contact_v2pub.org_contact_rec_type;
  
CURSOR c_cont
IS
SELECT *
  FROM xx_ap_cld_supp_contact_stg xas
 WHERE xas.create_flag        = 'N'
   AND xas.contact_process_flag = gn_process_status_validated
   AND xas.request_id           = gn_request_id
   AND cont_target              ='EBS';
  
CURSOR c_contact_infor(v_vendor_id NUMBER, v_vendor_site_id NUMBER, v_first_name VARCHAR2, v_last_name VARCHAR2)
IS
SELECT DISTINCT 
	   hpr.party_id,
       asu.segment1 supp_num ,
       asu.vendor_name ,
       hpc.party_name contact_name ,
       hpr.primary_phone_country_code cnt_cntry ,
       hpr.primary_phone_area_code cnt_area ,
       hpr.primary_phone_number phone_number ,
       assa.vendor_site_code ,
       assa.vendor_site_id ,
       asco.vendor_contact_id,
       hpc.person_first_name first_name,
       hpc.person_last_name last_name
  FROM hz_relationships hr ,
       ap_suppliers asu ,
       ap_supplier_sites_all assa ,
       ap_supplier_contacts asco ,
       hz_org_contacts hoc ,
       hz_parties hpc ,
       hz_parties hpr
 WHERE hoc.party_relationship_id = hr.relationship_id
   AND hr.subject_id               = asu.party_id
   AND hr.relationship_code        = 'CONTACT'
   AND hr.object_table_name        = 'HZ_PARTIES'
   AND asu.vendor_id               = assa.vendor_id
   AND hr.object_id                = hpc.party_id
   AND hr.party_id                 = hpr.party_id
   AND asco.relationship_id        = hoc.party_relationship_id
   AND assa.party_site_id          = asco.org_party_site_id
   AND hpr.party_type              = 'PARTY_RELATIONSHIP'
   AND asu.vendor_id               = v_vendor_id
   AND assa.vendor_site_id         = v_vendor_site_id
   AND hpc.person_first_name       = v_first_name
   AND hpc.person_last_name        = v_last_name;

CURSOR c_cont_title (v_vendor_id NUMBER, v_vendor_site_id NUMBER, v_first_name VARCHAR2, v_last_name VARCHAR2)
IS
SELECT DISTINCT hoc.org_contact_id,
       hoc.job_title,
       hoc.object_version_number cont_object_version_number,
       hr.object_version_number rel_object_version_number,
       hpc.object_version_number party_object_version_number
  FROM hz_relationships hr ,
       ap_suppliers asu ,
       ap_supplier_sites_all assa ,
       ap_supplier_contacts asco ,
       hz_org_contacts hoc ,
       hz_parties hpc ,
       hz_parties hpr
 WHERE hoc.party_relationship_id = hr.relationship_id
   AND hr.subject_id               = asu.party_id
   AND hr.relationship_code        = 'CONTACT'
   AND hr.object_table_name        = 'HZ_PARTIES'
   AND asu.vendor_id               = assa.vendor_id
   AND hr.object_id                = hpc.party_id
   AND hr.party_id                 = hpr.party_id
   AND asco.relationship_id        = hoc.party_relationship_id
   AND assa.party_site_id          = asco.org_party_site_id
   AND hpr.party_type              ='PARTY_RELATIONSHIP'
   AND asu.vendor_id               = v_vendor_id
   AND assa.vendor_site_id         = v_vendor_site_id
   AND hpc.person_first_name       = v_first_name
   AND hpc.person_last_name        = v_last_name;
BEGIN
  -- Initialize apps session
  -- Assign Basic Values
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';
  FOR r_cont IN c_cont
  LOOP
    FOR r_cont_info IN c_contact_infor(r_cont.vendor_id , r_cont.vendor_site_id , r_cont.first_name, r_cont.last_name )
    LOOP
      BEGIN
        SELECT phone_number,
               phone_area_code
          INTO l_phone_number,
               l_phone_area_code
          FROM hz_contact_points hpcp
         WHERE phone_line_type  = 'GEN'
           AND contact_point_type = 'PHONE'
           AND hpcp.owner_table_id= r_cont_info.party_id;
      EXCEPTION
        WHEN OTHERS 
		THEN
          l_phone_number    := NULL;
          l_phone_area_code := NULL;
      END;
      BEGIN
        SELECT phone_number,
               phone_area_code
          INTO l_fax_number,
               l_fax_area_code
          FROM hz_contact_points hpcp
         WHERE phone_line_type  ='FAX'
           AND contact_point_type ='PHONE'
           AND hpcp.owner_table_id=r_cont_info.party_id;
      EXCEPTION
        WHEN OTHERS 
		THEN
          l_fax_number    := NULL;
          l_fax_area_code := NULL;
      END;
      BEGIN
        SELECT email_address
          INTO l_email_address
          FROM hz_contact_points hpcp
         WHERE 1                 = 1
           AND contact_point_type  = 'EMAIL'
           AND hpcp.owner_table_id = r_cont_info.party_id;
      EXCEPTION
        WHEN OTHERS 
		THEN
          l_email_address := NULL;
      END;
      IF NVL(l_phone_number,'X')                <> NVL(r_cont.phone,'X') OR NVL(l_email_address,'X') <> NVL(r_cont.email_address,'X') OR NVL(l_fax_number,'X') <> NVL(r_cont.fax,'X') OR NVL(l_phone_area_code,'X') <> NVL(r_cont.area_code,'X') OR NVL(l_fax_area_code,'X') <> NVL(r_cont.fax_area_code,'X') THEN
        lv_vendor_contact_rec.vendor_contact_id := r_cont_info.vendor_contact_id;
        lv_vendor_contact_rec.phone             := NVL(r_cont.phone,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.email_address     := NVL(r_cont.email_address,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.fax_phone         := NVL(r_cont.fax,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.fax_area_code     := NVL(r_cont.fax_area_code,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.area_code         := NVL(r_cont.area_code,FND_API.G_MISS_CHAR);
        fnd_msg_pub.initialize; --to make msg_count 0
        x_return_status := NULL;
        x_msg_count     := NULL;
        x_msg_data      := NULL;
        
		ap_vendor_pub_pkg.update_vendor_contact_public (p_api_version => 1.0, 
														p_init_msg_list => fnd_api.g_false, 
														p_commit => fnd_api.g_false, 
														p_validation_level => fnd_api.g_valid_level_full, 
														p_vendor_contact_rec => lv_vendor_contact_rec, 
														x_return_status => x_return_status, 
														x_msg_count => x_msg_count, 
														x_msg_data => x_msg_data 
													   );
        
		COMMIT;
        print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS ap_vendor_pub_pkg = ' || x_return_status, p_force => TRUE);
        print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ap_vendor_pub_pkg ' || fnd_api.g_ret_sts_success , p_force => TRUE);
        print_debug_msg(p_message=> l_program_step||'X_MSG_COUNT ap_vendor_pub_pkg = ' || x_msg_count, p_force => TRUE);
        
		IF x_return_status <>'S' AND x_msg_count > 0 THEN
          print_debug_msg(p_message=> l_program_step||'x_return_status ap_vendor_pub_pkg' || x_return_status , p_force => TRUE);
          print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ap_vendor_pub_pkg ' || fnd_api.g_ret_sts_success , p_force => TRUE);
          FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
          LOOP
            fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num);
            print_debug_msg(p_message=> l_program_step||'The API call failed with error ap_vendor_pub_pkg ' || l_msg , p_force => TRUE);
          END LOOP;
          l_process_flag:='E';
          ------Update for Tiebacking
        ELSE
          print_debug_msg(p_message=> l_program_step||'The API call ap_vendor_pub_pkg ended with SUCESSS status', p_force => TRUE);
          l_process_flag := 'Y';
          l_msg          := '';
          -----------------------Update the status if API successfully updated the record.
        END IF;
      END IF;
    END LOOP;
    FOR r_cont_title IN c_cont_title (r_cont.vendor_id , r_cont.vendor_site_id ,r_cont.first_name,r_cont.last_name )
    LOOP
      ------------------------Contact title API call
      IF NVL(r_cont_title.job_title,'X')    <> NVL(r_cont.title,'X') THEN
        lv_contact_title_rec.org_contact_id := r_cont_title.org_contact_id;
        lv_contact_title_rec.job_title      := NVL(r_cont.title, FND_API.G_MISS_CHAR);
        fnd_msg_pub.initialize; --to make msg_count 0
        x_return_status := NULL;
        x_msg_count     := NULL;
        x_msg_data      := NULL;
        hz_party_contact_v2pub.update_org_contact ( p_init_msg_list => fnd_api.g_false, 
													p_org_contact_rec => lv_contact_title_rec, 
													p_cont_object_version_number => r_cont_title.cont_object_version_number, 
													p_rel_object_version_number => r_cont_title.rel_object_version_number,
													p_party_object_version_number=>r_cont_title.party_object_version_number, 
													x_return_status => x_return_status, 
													x_msg_count => x_msg_count, 
													x_msg_data => x_msg_data 
												  );
        COMMIT;
        print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS HZ_PARTY_CONTACT_V2PUB = ' || x_return_status, p_force => TRUE);
        print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success HZ_PARTY_CONTACT_V2PUB ' || fnd_api.g_ret_sts_success , p_force => TRUE);
        print_debug_msg(p_message=> l_program_step||'X_MSG_COUNT HZ_PARTY_CONTACT_V2PUB = ' || x_msg_count, p_force => TRUE);
        IF x_return_status <>'S' AND x_msg_count > 0 THEN
          print_debug_msg(p_message=> l_program_step||'x_return_status  HZ_PARTY_CONTACT_V2PUB' || x_return_status , p_force => TRUE);
          print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success HZ_PARTY_CONTACT_V2PUB ' || fnd_api.g_ret_sts_success , p_force => TRUE);
          FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
          LOOP
            fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
            print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force => TRUE);
          END LOOP;
          l_process_flag:='E';
          ------Update for Tiebacking
        ELSE
          print_debug_msg(p_message=> l_program_step||'The API call HZ_PARTY_CONTACT_V2PUB ended with SUCESSS status', p_force => TRUE);
          l_process_flag:='Y';
          l_msg         :='';
          -----------------------Update the status if API successfully updated the record.
        END IF;
      END IF;
    END LOOP;
    BEGIN
      UPDATE xx_ap_cld_supp_contact_stg xas
         SET xas.contact_process_flag   = DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),
             xas.error_flag               = DECODE( l_process_flag,'Y',NULL,'E','Y'),
             xas.error_msg                = l_msg,
             process_flag                 = l_process_flag
       WHERE xas.contact_process_flag = gn_process_status_validated
         AND xas.request_id             = gn_request_id
         AND xas.supplier_number        = r_cont.supplier_number
         AND TRIM(xas.first_name)       = TRIM(r_cont.first_name)
         AND TRIM(xas.last_name)        = TRIM(r_cont.last_name)
         AND TRIM(xas.vendor_site_code) = TRIM(r_cont.vendor_site_code);
      COMMIT;
    EXCEPTION
      WHEN OTHERS 
	  THEN
        print_debug_msg(p_message=> l_program_step||'In Exception to update records'||SQLERRM, p_force => TRUE);
    END ;
  END LOOP;
EXCEPTION
  WHEN OTHERS 
  THEN
    fnd_file.put_line(fnd_file.LOG,SQLCODE||','||SQLERRM);
END update_supplier_contact;
--+============================================================================+
--| Name          : Attach_bank_assignments                                    |
--| Description   : This procedure will attach_bank_assignments using API      |
--|                                                                            |
--| Parameters    : x_ret_code OUT NUMBER ,                                    |
--|                 x_return_status OUT VARCHAR2 ,                             |
--|                 x_err_buf OUT VARCHAR2                                     |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE attach_bank_assignments(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2)
IS
  x_bank_branch_rec iby_ext_bankacct_pub.extbankacct_rec_type;
  p_assignment_attribs iby_fndcpt_setup_pub.pmtinstrassignment_rec_type;
  p_payee iby_disbursement_setup_pub.payeecontext_rec_type;
  lr_ext_bank_acct_dtl iby_ext_bank_accounts%rowtype;
  p_api_version          NUMBER;
  p_init_msg_list        VARCHAR2(200);
  p_commit               VARCHAR2(200);
  p_validation_level     NUMBER;
  x_msg_count            NUMBER;
  x_msg_data             VARCHAR2(200);
  p_calling_prog         VARCHAR2(200);
  l_program_step         VARCHAR2 (100) := '';
  ln_msg_index_num       NUMBER;
  l_msg                  VARCHAR2(2000);
  l_process_flag         VARCHAR2(10);
  lv_supp_site_id        VARCHAR2(100);
  lv_supp_party_site_id  VARCHAR2(100);
  lv_acct_owner_party_id VARCHAR2(100);
  lv_org_id              NUMBER;
  x_assign_id            NUMBER;
  l_account_id           NUMBER;
  x_response iby_fndcpt_common_pub.result_rec_type;
  l_assign_id           NUMBER;
  l_joint_acct_owner_id NUMBER;
  CURSOR c_sup_bank
  IS
    SELECT *
    FROM xx_ap_cld_supp_bnkact_stg xas
    WHERE 1                     =1
    AND xas.create_flag         ='Y'
    AND xas.bnkact_process_flag =gn_process_status_validated
    AND xas.request_id          = gn_request_id;
  ----
BEGIN
  -- Initialize apps session
  -- Assign Basic Values
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';
  print_debug_msg(p_message=> l_program_step||'Attach Bank Assignment' , p_force=>true);
  FOR r_sup_bank IN c_sup_bank
  LOOP
    print_debug_msg(p_message=> l_program_step||'Inside Cursor', p_force=>true);
    BEGIN
      SELECT assa.vendor_site_id,
        assa.party_site_id,
        aps.party_id,
        assa.org_id
      INTO lv_supp_site_id,
        lv_supp_party_site_id,
        lv_acct_owner_party_id,
        lv_org_id
      FROM ap_suppliers aps,
        ap_supplier_sites_all assa
      WHERE aps.vendor_id     = assa.vendor_id
      AND aps.vendor_id       =r_sup_bank.vendor_id
      AND assa.vendor_site_id = r_sup_bank.vendor_site_id;
      ---  AND assa.vendor_site_code = r_sup_bank.vendor_site_code;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||'Error- Get supp_site_id and supp_party_site_id' || SQLCODE || sqlerrm, p_force=>true);
    END;
    IF r_sup_bank.account_id >0 AND r_sup_bank.instrument_uses_id IS NULL THEN
      ----------------------Assigning Attributes
      p_payee.supplier_site_id := lv_supp_site_id;
      p_payee.party_id         := lv_acct_owner_party_id;
      p_payee.party_site_id    := lv_supp_party_site_id;
      p_payee.payment_function := 'PAYABLES_DISB';
      p_payee.org_id           := lv_org_id;
      p_payee.org_type         := 'OPERATING_UNIT';
      -- Assignment Values
      p_assignment_attribs.instrument.instrument_type := 'BANKACCOUNT';
      l_account_id                                    :=r_sup_bank.account_id;
      print_debug_msg(p_message=> l_program_step||'L_ACCOUNT_ID '||l_account_id, p_force=>true);
      p_assignment_attribs.instrument.instrument_id:=r_sup_bank.account_id;
      -- External Bank Account ID
      p_assignment_attribs.priority   := 1;
      p_assignment_attribs.start_date := sysdate;
      ------------------Calling API to check Joint Owner exists or no
      fnd_msg_pub.initialize; --to make msg_count 0
      x_return_status:=NULL;
      x_msg_count    :=NULL;
      x_msg_data     :=NULL;
      x_response     :=NULL;
      iby_ext_bankacct_pub.check_bank_acct_owner ( p_api_version =>p_api_version, p_init_msg_list=>p_init_msg_list, p_bank_acct_id=>r_sup_bank.account_id, p_acct_owner_party_id =>lv_acct_owner_party_id, x_return_status=>x_return_status, x_msg_count=>x_msg_count, x_msg_data=>x_msg_data, x_response=>x_response );
      IF x_return_status <>'S' THEN --------------No join owner exists
        fnd_msg_pub.initialize;                 --to make msg_count 0
        x_return_status:=NULL;
        x_msg_count    :=NULL;
        x_msg_data     :=NULL;
        x_response     :=NULL;
        -------------------------Calling Joint Account Owner API
        iby_ext_bankacct_pub.add_joint_account_owner ( p_api_version =>p_api_version, p_init_msg_list=>p_init_msg_list, p_bank_account_id=>r_sup_bank.account_id, p_acct_owner_party_id =>lv_acct_owner_party_id, x_joint_acct_owner_id=>l_joint_acct_owner_id, x_return_status=>x_return_status, x_msg_count=>x_msg_count, x_msg_data=>x_msg_data, x_response=>x_response );
        print_debug_msg(p_message=> l_program_step||'L_JOINT_ACCT_OWNER_ID = ' || l_joint_acct_owner_id, p_force=>true);
        print_debug_msg(p_message=> l_program_step||' ADD_JOINT_ACCOUNT_OWNER X_RETURN_STATUS = ' || x_return_status, p_force=>true);
        print_debug_msg(p_message=> l_program_step||'ADD_JOINT_ACCOUNT_OWNER fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
        print_debug_msg(p_message=> l_program_step||'ADD_JOINT_ACCOUNT_OWNER X_MSG_COUNT = ' || x_msg_count, p_force=>true);
      END IF;
      fnd_msg_pub.initialize; --to make msg_count 0
      x_return_status:=NULL;
      x_msg_count    :=NULL;
      x_msg_data     :=NULL;
      x_response     :=NULL;
      --------------------Call the API for istr assignemtn
      iby_disbursement_setup_pub.set_payee_instr_assignment (p_api_version => p_api_version, p_init_msg_list => p_init_msg_list, p_commit => p_commit, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data, p_payee => p_payee, p_assignment_attribs => p_assignment_attribs, x_assign_id => l_assign_id, x_response => x_response );
      COMMIT;
      print_debug_msg(p_message=> l_program_step||' SET_PAYEE_INSTR_ASSIGNMENT X_ASSIGN_ID = ' || l_assign_id, p_force=>true);
      print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT X_RETURN_STATUS = ' || x_return_status, p_force=>true);
      print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
      print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT X_MSG_COUNT = ' || x_msg_count, p_force=>true);
      IF x_return_status = 'E' THEN
        print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
        print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
        FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
        LOOP
          fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
          print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
        END LOOP;
        l_process_flag:='E';
      ELSE
        print_debug_msg(p_message=> l_program_step||'The API call ended with SUCESSS status' , p_force=>true);
        l_process_flag:='Y';
        l_msg         :='';
      END IF;
    END IF;--R_SUP_BANK.account_id IS NOT NULL AND R_SUP_BANK.INSTRUMENT_USES_ID IS NULL
    ------------------------------When Account ID is null create new Account and instrumnets
    IF r_sup_bank.account_id               IS NULL OR r_sup_bank.account_id=-1 THEN
      x_bank_branch_rec.currency           :=r_sup_bank.currency_code;
      x_bank_branch_rec.branch_id          :=r_sup_bank.branch_id;
      x_bank_branch_rec.bank_id            :=r_sup_bank.bank_id;
      x_bank_branch_rec.acct_owner_party_id:=lv_acct_owner_party_id;
      x_bank_branch_rec.country_code       :=r_sup_bank.country_code;
      x_bank_branch_rec.bank_account_name  := r_sup_bank.bank_account_name;
      x_bank_branch_rec.bank_account_num   :=r_sup_bank.bank_account_num;
      fnd_msg_pub.initialize; --to make msg_count 0
      x_return_status:=NULL;
      x_msg_count    :=NULL;
      x_msg_data     :=NULL;
      x_response     :=NULL;
      iby_ext_bankacct_pub.create_ext_bank_acct ( p_api_version => 1.0, p_init_msg_list => fnd_api.g_true, p_ext_bank_acct_rec => x_bank_branch_rec, p_association_level => 'SS', p_supplier_site_id => lv_supp_site_id, p_party_site_id => lv_supp_party_site_id, p_org_id => lv_org_id, p_org_type => 'OPERATING_UNIT', x_acct_id => l_account_id, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data =>x_msg_data, x_response => x_response );
      print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct l_account_id = ' || l_account_id, p_force=>true);
      print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct X_RETURN_STATUS = ' || x_return_status, p_force=>true);
      print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
      print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct X_MSG_COUNT = ' || x_msg_count, p_force=>true);
      COMMIT;
      IF x_return_status = 'E' THEN
        print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct x_return_status ' || x_return_status , p_force=>true);
        print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
        FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
        LOOP
          fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
          print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
        END LOOP;
        l_process_flag:='E';
      ELSE
        print_debug_msg(p_message=> l_program_step||'The API call ended with SUCESSS status' , p_force=>true);
        l_process_flag:='Y';
        l_msg         :='';
      END IF;
    END IF; ---IF R_SUP_BANK.account_id
    BEGIN
      UPDATE xx_ap_cld_supp_bnkact_stg xas
      SET xas.bnkact_process_flag    =DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),---6
        xas.error_flag               =DECODE( l_process_flag,'Y',NULL,'E','Y'),
        xas.error_msg                = l_msg,
        xas.account_id               =l_account_id,
        process_flag                 =l_process_flag
      WHERE xas.bnkact_process_flag  =gn_process_status_validated
      AND xas.request_id             =gn_request_id
      AND xas.supplier_num           =r_sup_bank.supplier_num
      AND trim(xas.vendor_site_code) =trim(r_sup_bank.vendor_site_code)
      AND bank_account_num           =r_sup_bank.bank_account_num
      AND bank_name                  =r_sup_bank.bank_name
      AND branch_name                =r_sup_bank.branch_name;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||'In Exception to update records', p_force=>true);
    END ;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,SQLCODE||','||sqlerrm);
END attach_bank_assignments;
--+===============================================================================+
--| Name          : validate_Supplier_records                                     |
--| Description   : This procedure will validate supplier records in staging table|
--|                                                                               |
--| Parameters    : x_ret_code OUT NUMBER ,                                       |
--|                 x_return_status OUT VARCHAR2 ,                                |
--|                 x_err_buf OUT VARCHAR2                                        |
--|                                                                               |
--| Returns       : N/A                                                           |
--|                                                                               |
--+===============================================================================+
PROCEDURE validate_supplier_records(
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
TYPE l_sup_tab
IS
  TABLE OF XX_AP_CLD_SUPPLIERS_STG%rowtype INDEX BY binary_integer;
  l_supplier_type l_sup_tab;
  --=================================================================
  -- Cursor Declarations for Suppliers
  --=================================================================
  CURSOR c_supplier
  IS
    SELECT xas.*
    FROM xx_ap_cld_suppliers_stg xas
    WHERE xas.supp_process_flag IN (gn_process_status_inprocess)
    AND xas.request_id           = gn_request_id;
  --======-=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Staging tabl
  --=======================================================================
  CURSOR c_dup_supplier_chk_stg
  IS
    SELECT TRIM(UPPER(xas.supplier_name)),
      COUNT(1)
    FROM xx_ap_cld_suppliers_stg xas
    WHERE xas.supp_process_flag IN (gn_process_status_inprocess)
    AND xas.request_id           = gn_request_id
    GROUP BY TRIM(UPPER(xas.supplier_name))
    HAVING COUNT(1) >= 2;
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Interface table
  --=================================================================
  CURSOR c_dup_supplier_chk_int(c_supplier_name VARCHAR2,c_segment1 VARCHAR2)
  IS
    SELECT xasi.vendor_name,
      xasi.segment1,
      xasi.num_1099
    FROM AP_SUPPLIERS_INT XASI
    WHERE xasi.status      ='NEW'
    AND UPPER(vendor_name) = UPPER(c_supplier_name)
    AND xasi.segment1      =c_segment1;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================
  CURSOR c_dup_supplier_chk (c_supplier_name VARCHAR2,c_segment1 VARCHAR2)
  IS
    SELECT asa.vendor_name,
      asa.segment1,
      asa.num_1099,
      asa.vendor_id,
      hp.party_id,
      hp.object_version_number
    FROM ap_suppliers asa,
      hz_parties hp
    WHERE asa.vendor_name = c_supplier_name
    AND asa.segment1      =c_segment1
    AND hp.party_id       = asa.party_id;
  --==========================================================================================
  -- Cursor Declarations for Supplier Type
  --==========================================================================================
  CURSOR c_sup_type_code (c_supplier_type VARCHAR2)
  IS
    SELECT lookup_code
    FROM fnd_lookup_values
    WHERE lookup_type = 'VENDOR TYPE'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active, SYSDATE+1))
    AND lookup_code=c_supplier_type;
  --==========================================================================================
  -- Cursor Declarations for Income Tax Type
  --==========================================================================================
  CURSOR c_income_tax_type (c_income_tax_type VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM ap_income_tax_types
    WHERE income_tax_type                     = c_income_tax_type
    AND TRUNC(NVL(inactive_date, SYSDATE+1)) >= TRUNC(SYSDATE);
  --==========================================================================================
  -- Cursor Declarations for Country Code
  --==========================================================================================
  CURSOR c_get_country_code (c_country VARCHAR2)
  IS
    SELECT territory_code
    FROM fnd_territories_tl
    WHERE territory_code = c_country
    AND language         = USERENV('LANG');
  --==========================================================================================
  -- Cursor Declarations for Operating Unit
  --==========================================================================================
  CURSOR c_operating_unit (c_oper_unit VARCHAR2)
  IS
    SELECT organization_id
    FROM hr_operating_units
    WHERE name = c_oper_unit
    AND SYSDATE BETWEEN TRUNC(date_from) AND TRUNC(NVL(date_to,SYSDATE+1));
  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value
  --==========================================================================================
  CURSOR c_get_fnd_lookup_code (c_lookup_type VARCHAR2, c_lookup_meaning VARCHAR2)
  IS
    SELECT lookup_code
    FROM fnd_lookup_values
    WHERE lookup_type = c_lookup_type
    AND lookup_code   = c_lookup_meaning
    AND source_lang   = 'US'
    AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active, SYSDATE-1)) AND TRUNC(NVL(end_date_active, SYSDATE+1));
  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value count giving lookup code
  --==========================================================================================
  CURSOR c_get_fnd_lookup_code_cnt (c_lookup_type VARCHAR2, c_lookup_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM fnd_lookup_values
    WHERE lookup_type = c_lookup_type
    AND lookup_code   = c_lookup_code
    AND Enabled_flag  ='Y';
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_sup_idx       NUMBER         := 0;
  l_procedure     VARCHAR2 (30)  := 'validate_Supplier_records';
  l_program_step  VARCHAR2 (100) := '';
  l_ret_code      NUMBER;
  l_return_status VARCHAR2 (100);
  l_err_buff      VARCHAR2 (4000);
  l_error_message VARCHAR2(4000) := '';
  l_sup_name ap_suppliers.vendor_name%type;
  l_segment1 ap_suppliers.segment1%type;
  l_tax_payer_id ap_suppliers.num_1099%type;
  l_vendor_id  NUMBER;
  l_party_id   NUMBER;
  l_obj_ver_no NUMBER;
  l_sup_type_code ap_suppliers.vendor_type_lookup_code%type;
  l_org_id NUMBER;
  l_org_type_code fnd_lookup_values.lookup_code%type;
  l_organization_type VARCHAR2(50);
  l_stg_sup_name ap_suppliers.vendor_name%type;
  l_stg_sup_dup_cnt NUMBER := 0;
  l_int_sup_name ap_suppliers.vendor_name%type;
  l_int_tax_payer_id NUMBER := 0;
  l_int_segment1 ap_suppliers.segment1%type;
BEGIN
  print_debug_msg(p_message=> 'Begin validate Supplier Records',p_force=> true);
  print_debug_msg(p_message=> 'Assigning Defaults' ,p_force=> false);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag := 'N';
  l_error_message      := NULL;
  gc_error_msg         := '';
  l_ret_code           := 0;
  l_return_status      := 'S';
  l_err_buff           := NULL;
  print_debug_msg(p_message=> 'Opening Supplier Cursor' ,p_force=>false);
  print_debug_msg(p_message=> 'Doing the Duplicate Supplier Check in Staging table' , p_force=> false);
  OPEN c_dup_supplier_chk_stg;
  LOOP
    FETCH c_dup_supplier_chk_stg INTO l_stg_sup_name, l_stg_sup_dup_cnt;
    EXIT
  WHEN c_dup_supplier_chk_stg%notfound;
    print_debug_msg(p_message=> l_program_step||' : ERROR: '||l_stg_sup_dup_cnt||' records exist for Supplier Name '||l_stg_sup_name||' in the staging table' ,p_force=> false);
    UPDATE xx_ap_cld_suppliers_stg
    SET supp_process_flag = gn_process_status_error ,
      error_flag          = gc_process_error_flag ,
      error_msg           = l_stg_sup_dup_cnt
      ||' records exist for Supplier Name '
      ||l_stg_sup_name
      ||' in the staging table.'
    WHERE TRIM(UPPER(supplier_name)) = l_stg_sup_name
    AND supp_process_flag            = gn_process_status_inprocess
    AND request_id                   = gn_request_id;
  END LOOP;
  CLOSE c_dup_supplier_chk_stg;
  --==============================================================
  -- Start validation for each supplier
  --===========================================================
  OPEN c_supplier;
  LOOP
    FETCH c_supplier bulk collect INTO l_supplier_type;
    IF l_supplier_type.count > 0 THEN
      FOR l_sup_idx IN l_supplier_type.first .. l_supplier_type.last
      LOOP
        print_debug_msg(p_message=> 'Validating Supplier : '||l_supplier_type(l_sup_idx).supplier_name,p_force=> false);
        --==============================================================
        -- Initialize the Variable to N for Each Supplier
        --==============================================================
        gc_error_status_flag := 'N';
        gc_step              := 'SUPPLIER';
        l_error_message      := NULL;
        gc_error_msg         := '';
        l_sup_type_code      := NULL;
        l_segment1           :=NULL;
        l_tax_payer_id       := NULL;
        l_vendor_id          := NULL;
        l_party_id           := NULL;
        l_obj_ver_no         := NULL;

        --=============================================================================
        -- Validating the Supplier Site - Organization Type
        --=============================================================================
        print_debug_msg(p_message=> gc_step||' Organization type value is '||l_supplier_type(l_sup_idx).organization_type ,p_force=> false);
        l_org_type_code     := NULL;
        l_organization_type := l_supplier_type(l_sup_idx).organization_type;
        OPEN c_get_fnd_lookup_code('ORGANIZATION TYPE', l_organization_type);
        FETCH c_get_fnd_lookup_code INTO l_org_type_code;
        CLOSE c_get_fnd_lookup_code;
        IF l_org_type_code     IS NULL THEN
          gc_error_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: ORGANIZATION_TYPE:'||l_organization_type||': XXOD_ORGANIZATION_TYPE_INVALID: Organization Type does not exist in the system.' ,p_force=> false);
          insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type(l_sup_idx).supplier_name ,p_error_code => 'XXOD_ORGANIZATION_TYPE_INVALID' ,p_error_message => 'Organization Type '||l_organization_type||' does not exist in the system' ,p_stage_col1 => 'ORGANIZATION_TYPE' ,p_stage_val1 => l_organization_type ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' Organization Type Code of Organization Type - '||l_supplier_type(l_sup_idx).organization_type||' is '||l_org_type_code ,p_force=> false);
          l_supplier_type(l_sup_idx).organization_type := l_org_type_code;
        END IF; -- IF l_org_type_code IS NULL
        --==============================================================
        -- Validating the SUPPLIER NAME
        --==============================================================
        IF l_supplier_type (l_sup_idx).supplier_name IS NULL THEN
          gc_error_status_flag                       := 'Y';
          print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier Name Cannot be NULL for the record '||l_sup_idx ,p_force=> false);
          insert_error(P_PROGRAM_STEP => GC_STEP ,P_PRIMARY_KEY => L_SUPPLIER_TYPE (L_SUP_IDX).SUPPLIER_NAME ,P_ERROR_CODE => 'XXOD_SUPPLIER_NAME_NULL' ,P_ERROR_MESSAGE => 'Supplier Name Cannot be NULL' ,P_STAGE_COL1 => 'SUPPLIER_NAME' ,P_STAGE_VAL1 => L_SUPPLIER_TYPE (L_SUP_IDX).SUPPLIER_NAME ,P_STAGE_COL2 => 'VENDOR_NAME' ,P_STAGE_VAL2 => NULL ,P_TABLE_NAME => G_SUP_TABLE );
          l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
          l_supplier_type (l_sup_idx).ERROR_FLAG        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).ERROR_MSG         := 'Supplier Name Cannot be NULL for the record '||l_sup_idx;
          -- Skip the validation of this iteration/this supplier
          CONTINUE;
        END IF;
        IF ((find_special_chars(l_supplier_type(l_sup_idx).supplier_name) = 'JUNK_CHARS_EXIST')) THEN
          gc_error_status_flag                                           := 'Y';
          print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier Name'||l_supplier_type(l_sup_idx).supplier_name||' cannot contain junk characters and length must be less than 31' ,p_force=> false);
          insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).supplier_name ,p_error_code => 'XXOD_SUPPLIER_NAME_INVALID' ,p_error_message => 'Supplier Name'||l_supplier_type(l_sup_idx).supplier_name||' cannot contain junk characters and length must be less than 32' ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_supplier_type (l_sup_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
        END IF;
        --==============================================================
        -- Validating the SUPPLIER number
        --==============================================================
        IF l_supplier_type (l_sup_idx).segment1 IS NULL THEN
          gc_error_status_flag                  := 'Y';
          print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier number Cannot be NULL for the record '||l_sup_idx ,p_force=> true);
          INSERT_ERROR (P_PROGRAM_STEP => GC_STEP ,P_PRIMARY_KEY => L_SUPPLIER_TYPE (L_SUP_IDX).SEGMENT1 ,P_ERROR_CODE => 'XXOD_SUPPLIER_NAME_NULL' ,P_ERROR_MESSAGE => 'Supplier Name Cannot be NULL' ,P_STAGE_COL1 => 'SUPPLIER_NAME' ,P_STAGE_VAL1 => L_SUPPLIER_TYPE (L_SUP_IDX).SEGMENT1 ,P_STAGE_COL2 => 'VENDOR_NAME' ,P_STAGE_VAL2 => NULL ,P_TABLE_NAME => G_SUP_TABLE );
          l_supplier_type (l_sup_idx).supp_PROCESS_FLAG := gn_process_status_error;
          l_supplier_type (l_sup_idx).ERROR_FLAG        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).ERROR_MSG         := 'Supplier number Cannot be NULL for the record '||l_sup_idx;
          -- Skip the validation of this iteration/this supplier
          CONTINUE;
        END IF;
        --==============================================================
        -- Validating the Supplier - Tax Payer ID
        --==============================================================
        IF l_supplier_type(l_sup_idx).num_1099                                                                      IS NOT NULL THEN
          IF ( NOT (isnumeric(l_supplier_type(l_sup_idx).num_1099)) OR (LENGTH(l_supplier_type(l_sup_idx).num_1099) <> 9)) THEN
            gc_error_status_flag                                                                                    := 'Y';
            print_debug_msg(p_message=> l_program_step||' : ERROR: '||l_supplier_type (l_sup_idx).num_1099||' - Tax Payer Id should be numeric and must have 9 digits ' ,p_force=> false);
            insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).supplier_name ,p_error_code => 'XXOD_TAX_PAYER_ID_INVALID' ,p_error_message => 'Tax Payer Id should be numeric and must have 9 digits' ,p_stage_col1 => 'TAX_PAYER_ID' ,p_stage_val1 => l_supplier_type (l_sup_idx).num_1099 ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
          END IF;
        END IF; -- IF l_supplier_type(l_sup_idx).TAX_PAYER_ID IS NOT NULL
        --====================================================================
        -- If duplicate vendor name exist in staging table
        --====================================================================
        l_sup_name := NULL;
        OPEN c_dup_supplier_chk(trim(upper(l_supplier_type (l_sup_idx).supplier_name)),trim(l_supplier_type (l_sup_idx).segment1));
        FETCH c_dup_supplier_chk
        INTO l_sup_name,
          l_segment1,
          l_tax_payer_id,
          l_vendor_id,
          l_party_id,
          l_obj_ver_no;
        IF l_sup_name IS NULL THEN
          print_debug_msg(p_message=> l_program_step||' : Supplier Name '||l_supplier_type (l_sup_idx).supplier_name||' in system does not exist. So, create it after checking interface table.' ,p_force=> false);
          l_int_sup_name := NULL;
          l_int_segment1 :=NULL;
          OPEN c_dup_supplier_chk_int(trim(upper(l_supplier_type (l_sup_idx).supplier_name)),l_supplier_type (l_sup_idx).segment1);
          FETCH c_dup_supplier_chk_int
          INTO l_int_sup_name,
            l_int_segment1,
            l_int_tax_payer_id;
          CLOSE c_dup_supplier_chk_int;
          IF l_int_sup_name                         IS NULL THEN
            l_supplier_type (l_sup_idx).CREATE_FLAG := 'Y';
            print_debug_msg(p_message=> l_program_step||' : Supplier Name '||l_supplier_type (l_sup_idx).supplier_name||' in interface does not exist. So, create it.' ,p_force=> false);
          ELSE
            gc_error_status_flag := 'Y';
            print_debug_msg(p_message=> l_program_step||' : ERROR: XXOD_SUP_EXISTS_IN_INT : Suppiler '||l_supplier_type (l_sup_idx).supplier_name||' already exist in Interface table with segment1 as '||l_int_segment1||' .' ,p_force=> true);
            insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).supplier_name ,p_error_code => 'XXOD_SUP_EXISTS_IN_INT' ,p_error_message => 'Suppiler '||l_supplier_type (l_sup_idx).supplier_name||' already exist in Interface table with tax payer id as '||l_int_segment1||' .' ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_supplier_type (l_sup_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
          END IF;
        ELSIF ( (l_sup_name                              =l_supplier_type (l_sup_idx).supplier_name)) THEN
          l_supplier_type (l_sup_idx).CREATE_FLAG       := 'N';--Update
          l_supplier_type (l_sup_idx).supp_process_flag := gn_process_status_validated;
          l_supplier_type (l_sup_idx).vendor_id         := l_vendor_id;
          l_supplier_type (l_sup_idx).party_id          := l_party_id;
          l_supplier_type (l_sup_idx).object_version_no := l_obj_ver_no;
          print_debug_msg(p_message=> l_program_step||' : Imported Segment1 - '||l_supplier_type (l_sup_idx).segment1 ||' and System segment is  equal, so update this Supplier.' ,p_force=> false);
          print_debug_msg(p_message=> l_program_step||' l_supplier_type (l_sup_idx).CREATE_FLAG - '||l_supplier_type (l_sup_idx).CREATE_FLAG ,p_force=> false);
          print_debug_msg(p_message=> l_program_step||' l_vendor_id - '||l_vendor_id ,p_force=> false);
          print_debug_msg(p_message=> l_program_step||' l_party_id - '||l_party_id ,p_force=> false);
          print_debug_msg(p_message=> l_program_step||' l_obj_ver_no - '||l_obj_ver_no ,p_force=> false);
        END IF; -- l_sup_name IS NULL
        CLOSE c_dup_supplier_chk;
        --====================================================================
        -- Validating the Supplier - Supplier Type  . Derive if it is not NULL
        --====================================================================
        l_sup_type_code                                        := NULL;
        IF l_supplier_type (l_sup_idx).vendor_type_lookup_code IS NULL THEN
          gc_error_status_flag                                 := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: SUPPLIER_TYPE:'||l_supplier_type (l_sup_idx).vendor_type_lookup_code||': XXOD_SUPPLIER_TYPE_NULL:Supplier Type cannot be NULL' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).SUPPLIER_NAME ,p_error_code => 'XXOD_SUPPLIER_TYPE_NULL' ,p_error_message => 'Supplier Type cannot be NULL' ,p_stage_col1 => 'SUPPLIER_TYPE' ,p_stage_val1 => l_supplier_type (l_sup_idx).vendor_type_lookup_code ,p_stage_col2 => 'VENDOR_NAME' ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
        ELSE -- Derive the Supplier Type Code
          l_sup_type_code := NULL;
          OPEN c_sup_type_code(l_supplier_type (l_sup_idx).vendor_type_lookup_code);
          FETCH c_sup_type_code INTO l_sup_type_code;
          CLOSE c_sup_type_code;
          IF l_sup_type_code     IS NULL THEN
            gc_error_status_flag := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: SUPPLIER_TYPE:'||l_supplier_type (l_sup_idx).vendor_type_lookup_code||': XXOD_SUPP_TYPE_INVALID: Supplier Type does not exist in System' ,p_force=> false);
            insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).SUPPLIER_NAME ,p_error_code => 'XXOD_SUPP_TYPE_INVALID' ,p_error_message => 'Supplier Type does not exist in System' ,p_stage_col1 => 'SUPPLIER_TYPE' ,p_stage_val1 => l_supplier_type (l_sup_idx).vendor_type_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
          ELSE
            l_supplier_type (l_sup_idx).vendor_type_lookup_code := l_sup_type_code;
          END IF; -- IF l_sup_type_code IS NULL
        END IF;   -- IF l_supplier_type (l_sup_idx).SUPPLIER_TYPE IS NULL
        --====================================================================
        -- Validating the Supplier - Customer Number
        --====================================================================
        IF (l_supplier_type(l_sup_idx).customer_num IS NOT NULL) THEN
          print_debug_msg(p_message=> gc_step||'Validating the Supplier - Customer Number ' ,p_force=> false);
          IF (NOT (isnumeric(l_supplier_type(l_sup_idx).customer_num))) THEN
            gc_error_status_flag := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: CUSTOMER_NUM:'||l_supplier_type (l_sup_idx).customer_num||': XXOD_CUSTOMER_NUM_INVALID: Customer Number should be Numeric' ,p_force=> true);
            insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).SUPPLIER_NAME ,p_error_code => 'XXOD_CUSTOMER_NUM_INVALID' ,p_error_message => 'Customer Number should be Numeric' ,p_stage_col1 => 'CUSTOMER_NUM' ,p_stage_val1 => l_supplier_type (l_sup_idx).customer_num ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
          END IF; -- IF (NOT (isNumeric(l_sup_site_type.CUSTOMER_NUM)))
        END IF;   -- IF (l_supplier_type(l_sup_idx).CUSTOMER_NUM IS NOT NULL)
        --====================================================================
        -- Validating the Supplier - Default the values
        --====================================================================
        IF l_supplier_type (l_sup_idx).one_time_flag IS NULL THEN
          l_supplier_type (l_sup_idx).one_time_flag  := 'N';
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).ONE_TIME_FLAG  '||l_supplier_type (l_sup_idx).one_time_flag ,p_force=> false);
        END IF;
        IF l_supplier_type (l_sup_idx).federal_reportable_flag IS NULL THEN
          l_supplier_type (l_sup_idx).federal_reportable_flag  := 'N';
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).FEDERAL_REPORTABLE_FLAG  '||l_supplier_type (l_sup_idx).federal_reportable_flag ,p_force=> false);
        END IF;
        IF l_supplier_type (l_sup_idx).state_reportable_flag IS NULL THEN
          l_supplier_type (l_sup_idx).state_reportable_flag  := 'N';
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).STATE_REPORTABLE_FLAG  '||l_supplier_type (l_sup_idx).state_reportable_flag ,p_force=> false);
        END IF;
        print_debug_msg(p_message=> gc_step||'gc_error_status_flag' ||gc_error_status_flag ,p_force=> true);
        IF gc_error_status_flag = 'Y' THEN
          print_debug_msg(p_message=> gc_step||'gc_error_status_flag :' ||gc_error_status_flag ,p_force=> false);
          l_supplier_type (l_sup_idx).supp_process_flag := gn_process_status_error;
          l_supplier_type (l_sup_idx).error_flag        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).error_msg         := gc_error_msg;
          print_debug_msg(p_message=> gc_step||' : Validation of Supplier '||l_supplier_type (l_sup_idx).supplier_name|| ' is failure' ,p_force=> false);
          print_debug_msg(p_message=> l_program_step||': ------------ Data Validation Failed Supplier('||l_supplier_type(l_sup_idx).supplier_name||') -------------------------' ,p_force=> false);
        ELSE
          print_debug_msg(p_message=> gc_step||'gn_process_status_validated ' ||gn_process_status_validated ,p_force=> true);
          l_supplier_type (l_sup_idx).supp_process_flag := gn_process_status_validated;
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).process_flag ' ||l_supplier_type (l_sup_idx).process_flag ,p_force=> false);
          print_debug_msg(p_message=> gc_step||' : validation of supplier '||l_supplier_type (l_sup_idx).supplier_name|| ' is success' ,p_force=> false);
          print_debug_msg(p_message=> l_program_step||': ------------ Data Validation Success Supplier('||l_supplier_type(l_sup_idx).supplier_name||') -------------------------' ,p_force=> false);
        END IF;
        --============================================================================
        -- For Doing the Bulk Update
        --============================================================================
        BEGIN
          UPDATE xx_ap_cld_suppliers_stg
          SET supp_process_flag = l_supplier_type (l_sup_idx).supp_process_flag ,
            vendor_id           = l_supplier_type (l_sup_idx).vendor_id ,
            party_id            = l_supplier_type (l_sup_idx).party_id ,
            object_version_no   = l_supplier_type (l_sup_idx).object_version_no ,
            create_flag         = l_supplier_type (l_sup_idx).create_flag ,
            last_update_date    = SYSDATE,
            last_updated_by     = g_user_id,
            error_flag          = l_supplier_type(l_sup_idx).error_flag ,
            error_msg           = l_supplier_type(l_sup_idx).error_msg
          WHERE 1               =1
          AND segment1          = l_supplier_type (l_sup_idx).segment1
          AND request_id        = gn_request_id;
        EXCEPTION
        WHEN OTHERS THEN
          print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier, status update - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500) ,p_force=> false);
        END;
      END LOOP; -- For (l_supplier_type.FIRST .. l_supplier_type.LAST)
    END IF;     -- l_supplier_type.COUNT > 0
    EXIT
  WHEN c_supplier%notfound;
  END LOOP; -- c_supplier loop
  CLOSE c_supplier;
  l_supplier_type.DELETE;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  print_debug_msg(p_message=> 'End Validate Supplier Records',p_force => true);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_supplier_records;

FUNCTION xx_get_terms(p_cloud_terms IN VARCHAR2)
RETURN VARCHAR2
IS
v_terms VARCHAR2(50);
BEGIN
  SELECT LTRIM(RTRIM(tv.target_value1))
    INTO v_terms
    FROM xx_fin_translatevalues tv,
         xx_fin_translatedefinition td
   WHERE tv.translate_id  = td.translate_id
     AND translation_name = 'XX_AP_CLOUD_PAYMENT_TERMS'  
	 AND SYSDATE BETWEEN NVL(tv.start_date_active,SYSDATE) AND NVL(tv.end_date_active,SYSDATE + 1)
     AND SYSDATE BETWEEN NVL(td.start_date_active,SYSDATE) AND NVL(td.end_date_active,SYSDATE + 1)
	 AND tv.source_value1 = p_cloud_terms
     AND tv.enabled_flag = 'Y'
     AND td.enabled_flag = 'Y';
  RETURN(v_terms);
EXCEPTION
  WHEN others THEN
    RETURN('X');
END;

--+============================================================================+
--| Name          : validate_supplie_site_reocords                                           |
--| Description   : This procedure will validate  supplier sites details using valdiation  |
--|                                                                            |
--| Parameters    : p_vendor_is                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE validate_supplier_site_records(
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2 )
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
TYPE l_sup_site_and_add_tab
IS
  TABLE OF XX_AP_CLD_SUPP_SITES_STG%rowtype INDEX BY binary_integer;
  l_sup_site_and_add l_sup_site_and_add_tab;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================
  CURSOR c_supplier_site--- (c_supplier_name VARCHAR2)
  IS
    SELECT XASC.*,
      apsup.vendor_id supp_id
    FROM xx_ap_cld_supp_sites_stg xasc,
      ap_suppliers apsup
    WHERE xasc.site_process_flag IN (gn_process_status_inprocess)
    AND xasc.request_id           = gn_request_id
    AND UPPER(apsup.vendor_name)  =UPPER(xasc.supplier_name)
    AND apsup.segment1            =xasc.supplier_number ;
  --==========================================================================================
  -- Cursor Declarations for Country Code
  --==========================================================================================
  CURSOR c_get_country_code (c_country VARCHAR2)
  IS
    SELECT territory_code
    FROM fnd_territories_tl
    WHERE territory_code = c_country;
  --==========================================================================================
  -- Cursor Declarations for Supplier Site existence
  --==========================================================================================
  CURSOR c_sup_site_exist(c_supp_id NUMBER ,c_vendor_site_code VARCHAR2,c_org_id VARCHAR2)
  IS
    SELECT vendor_site_id
    FROM ap_supplier_sites_all assa
    WHERE 1              =1
    AND vendor_site_code = c_vendor_site_code
    AND TO_CHAR(org_id)  =c_org_id
    AND assa.vendor_id   =c_supp_id;
  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value count giving lookup code
  --==========================================================================================
  CURSOR c_get_fnd_lookup_code_cnt (c_lookup_type VARCHAR2, c_lookup_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM fnd_lookup_values
    WHERE lookup_type = c_lookup_type
    AND lookup_code   = c_lookup_code
    AND enabled_flag  ='Y';
  --==========================================================================================
  -- Cursor Declarations to get Bill To Location Id
  --==========================================================================================
  CURSOR c_bill_to_location (c_bill_to_loc_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM hr_locations_all
    WHERE location_code   = UPPER(c_bill_to_loc_code)
    AND bill_to_site_flag = 'Y'
    AND (inactive_date   IS NULL
    OR inactive_date     >= sysdate);
  --==========================================================================================
  -- Cursor Declarations to get Ship To Location Id
  --==========================================================================================
  CURSOR c_ship_to_location (c_ship_to_loc_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM hr_locations_all
    WHERE location_code   = UPPER(c_ship_to_loc_code)
    AND ship_to_site_flag = 'Y'
    AND (inactive_date   IS NULL
    OR inactive_date     >= sysdate);
  --==========================================================================================
  -- Cursor Declarations to check the existence of Payment Method
  --==========================================================================================
  CURSOR c_pay_method_exist (c_pay_method VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM iby_payment_methods_b
    WHERE payment_method_code = c_pay_method
    AND (inactive_date       IS NULL
    OR inactive_date         >= sysdate);
  --==========================================================================================
  -- Cursor Declarations to get Tolerance Id
  --==========================================================================================
  CURSOR c_get_tolerance (c_tolerance_name VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM ap_tolerance_templates
    WHERE tolerance_name = c_tolerance_name;
  --==========================================================================================
  -- Cursor Declarations to check the currency code existence
  --==========================================================================================
  CURSOR c_inv_curr_code_exist (c_currency_code VARCHAR2)
  IS
    SELECT COUNT(1) FROM fnd_currencies_vl WHERE currency_code = c_currency_code;
  --==========================================================================================
  -- Cursor Declarations to get Term ID
  --==========================================================================================
  CURSOR c_get_term_id (c_term_name VARCHAR2)
  IS
    SELECT term_id
      FROM ap_terms_vl
     WHERE name       = c_term_name
       AND enabled_flag = 'Y'
       AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active, SYSDATE-1)) AND TRUNC(NVL(end_date_active, SYSDATE+1));
  --==================================================================================================
  -- Cursor Declarations to check the existence of the Tax Reporting Site for the existed supplier
  --==================================================================================================
  CURSOR c_tax_rep_site_exist (c_vendor_id NUMBER)
  IS
    SELECT COUNT(1)
    FROM ap_supplier_sites_all
    WHERE vendor_id             = c_vendor_id
    AND tax_reporting_site_flag = 'Y';
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Staging table
  --=================================================================
  CURSOR c_dup_supplier_chk_stg
  IS
    SELECT TRIM(UPPER(xas.supplier_name)),
      xas.vendor_site_code,
      xas.org_id,
      COUNT(1)
    FROM xx_ap_cld_supp_sites_stg xas
    WHERE xas.site_process_flag IN (gn_process_status_inprocess)
    AND xas.request_id           =gn_request_id
    GROUP BY TRIM(UPPER(xas.supplier_name)),
      xas.vendor_site_code,
      xas.org_id
    HAVING COUNT(1) >= 2;
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers site in Interface table
  --=================================================================
  CURSOR c_dup_supplier_chk_int(c_vendor_site_code VARCHAR2,c_vendor_id NUMBER,c_org_id VARCHAR2)
  IS
    SELECT xasi.vendor_site_code
    FROM ap_supplier_sites_int xasi
    WHERE xasi.status           ='NEW'
    AND UPPER(VENDOR_SITE_CODE) = UPPER(C_VENDOR_SITE_CODE)
    AND XASI.VENDOR_ID          =C_VENDOR_ID
    AND TO_CHAR(xasi.org_id)    =c_org_id;
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_sup_idx pls_integer      := 0;
  l_sup_site_idx pls_integer := 0;
  l_procedure         VARCHAR2 (30)  := 'validate_Supplier_Site_records';
  l_program_step      VARCHAR2 (100) := '';
  l_ret_code          NUMBER;
  l_return_status     VARCHAR2 (100);
  l_err_buff          VARCHAR2 (4000);
  l_error_message     VARCHAR2(4000) := '';
  l_site_country_code VARCHAR2(15);
  l_sup_name ap_suppliers.vendor_name%type;
  l_segment1 ap_suppliers.segment1%type;
  l_vendor_id       NUMBER;
  l_party_id        NUMBER;
  l_obj_ver_no      NUMBER;
  l_sup_create_flag VARCHAR2(10) := '';
  l_payment_method iby_payment_methods_b.payment_method_code%type;
  l_pay_method_cnt NUMBER;
  l_tolerance_name ap_tolerance_templates.tolerance_name%type;
  l_deduct_bank_chrg          VARCHAR2(5);
  l_payment_priority          NUMBER;
  l_pay_group                 VARCHAR2(50);
  l_terms_date_basis          VARCHAR2(30);
  l_always_disc_flag          VARCHAR2(5);
  l_site_upd_cnt              NUMBER;
  l_ship_to_cnt               NUMBER :=0;
  l_bill_to_cnt               NUMBER :=0;
  l_terms_cnt                 NUMBER :=0;
  l_tolerance_cnt             NUMBER :=0;
  l_fob_code_cnt              NUMBER ;
  l_freight_terms_code_cnt    NUMBER;
  l_pay_group_code_cnt        NUMBER;
  l_terms_date_basis_code_cnt NUMBER;
  ln_cnt                      NUMBER;
  ln_vendor_site_id           NUMBER;
  l_service_tolerance_name ap_tolerance_templates.tolerance_name%type;
  l_service_tolerance_cnt      NUMBER :=0;
  ln_terms_id				   NUMBER;
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': assigning defaults' ,p_force=>true);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  BEGIN
    UPDATE xx_ap_cld_supp_sites_stg xasc
    SET site_process_flag  = gn_process_status_error ,
      process_flag         = 'Y',
      error_flag           =gc_process_error_flag,
      error_msg            ='No Supplier Exists'
    WHERE site_process_flag=gn_process_status_inprocess
    AND request_id         =gn_request_id
    AND NOT EXISTS
      (SELECT 1
      FROM ap_suppliers apsup
      WHERE UPPER(apsup.vendor_name)=UPPER(xasc.supplier_name)
      AND apsup.segment1            =xasc.supplier_number
      );
    l_site_upd_cnt   := SQL%ROWCOUNT;
    IF l_site_upd_cnt >0 THEN
      print_debug_msg(p_message => 'no supplier exists for this site', p_force => false);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Supplier Site for no Supplier - '|| l_err_buff , p_force => true);
  END;
  --==============================================================
  -- Check and Update the staging table for the Duplicate sites
  --==============================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate Sites', p_force => false);
    l_site_upd_cnt := 0;
    UPDATE XX_AP_CLD_SUPP_SITES_STG xassc1
    SET xassc1.site_process_flag = gn_process_status_error ,
      XASSC1.ERROR_FLAG          = GC_PROCESS_ERROR_FLAG ,
      xassc1.ERROR_MSG           = ERROR_MSG
      ||',ERROR: Duplicate Site in Staging Table'
    WHERE xassc1.site_process_flag = gn_process_status_inprocess
    AND xassc1.REQUEST_ID          = gn_request_id
    AND 2                         <=
      (SELECT COUNT(1)
      FROM XX_AP_CLD_SUPP_SITES_STG xassc2
      WHERE XASSC2.SITE_PROCESS_FLAG          IN (GN_PROCESS_STATUS_INPROCESS)
      AND xassc2.REQUEST_ID                    = gn_request_id
      AND trim(upper(xassc2.supplier_name))    = trim(upper(xassc1.supplier_name))
      AND trim(upper(xassc2.supplier_number))  = trim(upper(xassc1.supplier_number))
      AND TRIM(UPPER(XASSC2.VENDOR_SITE_CODE)) = TRIM(UPPER(XASSC1.VENDOR_SITE_CODE))
      AND xassc2.org_id                        =xassc1.org_id
      );
    l_site_upd_cnt   := sql%rowcount;
    IF l_site_upd_cnt >0 THEN
      print_debug_msg(p_message => 'check and updated '||l_site_upd_cnt||' records as error in the staging table for the duplicate sites', p_force => false);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate Site in Staging table - '|| l_err_buff , p_force => true);
  END;
  --====================================================================
  -- Call the Vendor Site ValidationsStart of Vendor Site Loop Validations
  --====================================================================
  print_debug_msg(p_message=> 'Validation of Supplier Site started' ,p_force=> true);
  FOR l_sup_site_type IN c_supplier_site
  LOOP
    l_sup_site_idx := l_sup_site_idx + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_site_idx - '||l_sup_site_idx ,p_force=> true);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'SITE';
    gc_error_msg              := '';
	ln_terms_id				  :=NULL;
    ln_vendor_site_id         := NULL;
    --l_int_vend_code           :=NULL;
    SELECT COUNT(1)
    INTO ln_cnt
    FROM ap_supplier_sites_int xasi
    WHERE xasi.status            ='NEW'
    AND UPPER(vendor_site_code)  = TRIM(UPPER(l_sup_site_type.vendor_site_code))
    AND xasi.vendor_id           =l_sup_site_type.supp_id
    AND TO_CHAR(xasi.org_id)     =L_SUP_SITE_TYPE.ORG_ID;
    IF ln_cnt                   <>0 THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> l_program_step||' : ERROR: XXOD_SUP_SITE_EXISTS_IN_INT : Suppiler ' ||l_sup_site_type.supplier_name||' already exist in Interface table .' ,p_force=> true);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SUP_EXISTS_IN_INT' , p_error_message => 'Vendor Site Exists in interface' , p_stage_col1 => 'ADDRESS_LINE1' ,p_stage_val1 => l_sup_site_type.supplier_name ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  Address Line 1
    --==============================================================================================================
    IF l_sup_site_type.address_line1 IS NULL THEN
      gc_error_site_status_flag      := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: ADDRESS_LINE1:'||l_sup_site_type.address_line1||': XXOD_SITE_ADDR_LINE1_NULL:Vendor Site Address Line 1 cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_LINE1_NULL' ,p_error_message => 'Vendor Site Address Line 1 cannot be NULL' ,p_stage_col1 => 'ADDRESS_LINE1' ,p_stage_val1 => l_sup_site_type.address_line1 ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  City
    --==============================================================================================================
    IF l_sup_site_type.city     IS NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: CITY:'||l_sup_site_type.city||': XXOD_SITE_ADDR_CITY_NULL:Vendor Site Address Details City cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_CITY_NULL' ,p_error_message => 'Vendor Site Address Details City cannot be NULL' ,p_stage_col1 => 'CITY' ,p_stage_val1 => l_sup_site_type.city ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Country
    --==============================================================================================================
    l_site_country_code := NULL;
    OPEN c_get_country_code(NVL(l_sup_site_type.country,gc_site_country_code));
    FETCH c_get_country_code INTO l_site_country_code;
    CLOSE c_get_country_code;
    print_debug_msg(p_message=> gc_step||' l_site_country_code '||l_site_country_code ,p_force=> false);
    IF l_site_country_code                        IS NOT NULL THEN
      l_sup_site_and_add (l_sup_site_idx).country := l_site_country_code;
    ELSE
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: COUNTRY:'||l_sup_site_type.country||': Site Country is Invalid' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.country ,p_error_code => 'XXOD_SITE_COUNTRY_INVALID' ,p_error_message => 'Vendor Site Country is Invalid' ,p_stage_col1 => 'COUNTRY' ,p_stage_val1 => l_sup_site_type.country ,p_table_name => g_sup_site_cont_table );
    END IF; -- IF l_site_country_code IS NOT NULL
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  State for US Country     and Province for Canada
    --==============================================================================================================
    ---- commented and to be confirmed once data starts flowing
    IF l_site_country_code         = 'US' THEN
      IF l_sup_site_type.state    IS NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: STATE:'||l_sup_site_type.state||': XXOD_SITE_ADDR_STATE_NULL:Vendor Site Address Details State cannot be NULL' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_STATE_NULL' ,p_error_message => 'Vendor Site Address Details State cannot be NULL' ,p_stage_col1 => 'STATE' ,p_stage_val1 => l_sup_site_type.state ,p_table_name => g_sup_site_cont_table );
      ELSIF l_sup_site_type.province IS NOT NULL THEN
        gc_error_site_status_flag    := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_PROVINCE_INVALID: PROVINCE:'||l_sup_site_type.province||': should be NULL for the country '||l_sup_site_type.country ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_PROVINCE_INVALID' ,p_error_message => 'Vendor Site Address Details - Province - should be NULL for the country '||l_sup_site_type.country ,p_stage_col1 => 'PROVINCE' ,p_stage_val1 => l_sup_site_type.province ,p_table_name => g_sup_site_cont_table );
      END IF; -- IF l_sup_site_type.STATE IS NULL   -- ??? Do we need to validate the State Code in Oracle Seeded table
    ELSIF l_site_country_code      = 'CA' THEN
      IF l_sup_site_type.province IS NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: PROVINCE:'||l_sup_site_type.province||': XXOD_SITE_ADDR_PROVINCE_NULL:Vendor Site Address Details - Province - cannot be NULL' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_PROVINCE_NULL' ,p_error_message => 'Vendor Site Address Details - Province - cannot be NULL' ,p_stage_col1 => 'PROVINCE' ,p_stage_val1 => l_sup_site_type.province ,p_table_name => g_sup_site_cont_table );
      ELSIF l_sup_site_type.state IS NOT NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_STATE_INVALID: STATE:'||l_sup_site_type.state||': should be NULL for the country '||l_sup_site_type.country ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_STATE_INVALID' ,p_error_message => 'Vendor Site Address Details - State - should be NULL for the country '||l_sup_site_type.country ,p_stage_col1 => 'STATE' ,p_stage_val1 => l_sup_site_type.state ,p_table_name => g_sup_site_cont_table );
      END IF; -- IF l_sup_site_type.PROVINCE IS NULL      -- ??? Do we need to validate the State Code in Oracle Seeded table
    ELSE
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: thrown already - COUNTRY:'||l_sup_site_type.country||': XXOD_SITE_COUNTRY_INVALID :Vendor Site Country is Invalid' ,p_force=> false);
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Operating Unit
    --==============================================================================================================
    ---Added by priyam as Org id is mandatory column for Site as well
    IF l_sup_site_type.org_id   IS NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: OPERATING_UNIT:'||l_sup_site_type.org_id||' is null',p_force=> true);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_OPERATING_UNIT_NULL' ,p_error_message => 'Operating Unit cannot be NULL' ,p_stage_col1 => 'ORG ID' ,p_stage_val1 => l_sup_site_type.org_id ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
    END IF;
    print_debug_msg(p_message=> gc_step||' After basic validation of site - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    l_sup_create_flag           :='';
    IF gc_error_site_status_flag = 'N' THEN
      print_debug_msg(p_message=> gc_step||' Supplier_name : '||UPPER(l_sup_site_type.supplier_name) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' Supplier No   : '||UPPER(l_sup_site_type.supplier_number) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' Supplier Site : '||UPPER(l_sup_site_type.vendor_site_code) ,p_force=> false);
      OPEN c_sup_site_exist(l_sup_site_type.supp_id,l_sup_site_type.vendor_site_code,l_sup_site_type.org_id);
      FETCH c_sup_site_exist INTO ln_vendor_site_id;
      CLOSE c_sup_site_exist;
      IF ln_vendor_site_id                                IS NOT NULL THEN
        l_sup_create_flag                                 :='N';--update the supplier
        l_sup_site_type.create_flag                       :=l_sup_create_flag;
        l_sup_site_and_add (l_sup_site_idx).vendor_site_id:=ln_vendor_site_id;
      ELSE
        l_sup_create_flag          := 'Y';
        l_sup_site_type.create_flag:=l_sup_create_flag;
      END IF; -- IF l_sup_site_exist_cnt > 0 THEN
    ELSE     ---  IF  gc_error_site_status_flag = 'N' THEN
      l_sup_create_flag          := '';
      gc_error_site_status_flag  := 'Y';
      l_sup_site_type.create_flag:=l_sup_create_flag;
    END IF;
    print_debug_msg(p_message=> gc_step||' After supplier site existence check - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    print_debug_msg(p_message=> gc_step||' After supplier site existence check - l_sup_create_flag is '||l_sup_create_flag ,p_force=> false);
    set_step('Supplier Site Existence Check Completed');
    IF gc_error_site_status_flag = 'N' THEN
      --==============================================================================================================
      -- Validating the Supplier Site - PostalCode Rename Psotal to Area
      --==============================================================================================================
      IF l_sup_site_type.postal_code IS NULL THEN
        gc_error_site_status_flag    := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.postal_code ||': XXOD_SITE_ADDR_POSTAL_CODE_NULL: Vendor Site Address Details - Postal Code - cannot be NULL' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_POSTAL_CODE_NULL' ,p_error_message => 'Vendor Site Address Details - Postal Code - cannot be NULL' ,p_stage_col1 => 'POSTAL_CODE' ,p_stage_val1 => l_sup_site_type.postal_code ,p_table_name => g_sup_site_cont_table );
      ELSE
        IF l_site_country_code = 'US' THEN
          IF (NOT (ispostalcode(l_sup_site_type.postal_code )) OR (LENGTH(l_sup_site_type.postal_code) > 10 )) THEN
            gc_error_site_status_flag                                                                 := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.postal_code ||': XXOD_SITE_ADDR_POSTAL_CODE_INVA: For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10' ,p_force=> false);
            insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_POSTAL_CODE_INVA' ,p_error_message => 'For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10' ,p_stage_col1 => 'POSTAL_CODE' ,p_stage_val1 => l_sup_site_type.postal_code ,p_table_name => g_sup_site_cont_table );
          END IF; -- IF (NOT (isPostalCode(l_sup_site_type.POSTAL_CODE))
        ELSIF l_site_country_code = 'CA' THEN
          IF (NOT (isalphanumeric(l_sup_site_type.postal_code ))) THEN
            gc_error_site_status_flag := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.postal_code||': XXOD_SITE_ADDR_POSTAL_CODE_INVA: For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only alphanumeric ' ,p_force=> false);
            insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_POSTAL_CODE_INVA' ,p_error_message => 'For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only alphanumeric' ,p_stage_col1 => 'POSTAL_CODE' ,p_stage_val1 => l_sup_site_type.postal_code ,p_table_name => g_sup_site_cont_table );
          END IF; -- IF l_sup_site_type.PROVINCE IS NULL      -- ??? Do we need to validate the State Code in Oracle Seeded table
        ELSE
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: thrown already - COUNTRY:'||l_sup_site_type.country||': XXOD_SITE_COUNTRY_INVALID :Vendor Site Country is Invalid' ,p_force=> false);
        END IF; -- IF IF l_sup_site_type.COUNTRY_CODE = 'US'
      END IF;   -- IF l_sup_site_type.POSTAL_CODE IS NULL
      --=============================================================================
      -- Validating the Supplier Site - Ship to Location Code
      --=============================================================================
      IF l_sup_site_type.ship_to_location IS NOT NULL THEN
        l_ship_to_cnt                     := 0;
        OPEN c_ship_to_location(l_sup_site_type.ship_to_location);
        FETCH c_ship_to_location INTO l_ship_to_cnt;
        CLOSE c_ship_to_location;
        IF l_ship_to_cnt             =0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: SHIP_TO_LOCATION:'||l_sup_site_type.ship_to_location||': XXOD_SHIP_TO_LOCATION_INVALID2: Ship to Location does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SHIP_TO_LOCATION_INVALID2' ,p_error_message => 'Ship to Location '||l_sup_site_type.ship_to_location||' does not exist in the system' ,p_stage_col1 => 'SHIP_TO_LOCATION' ,p_stage_val1 => l_sup_site_type.ship_to_location ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' Ship to Location Id is available' ,p_force=> false);
        END IF; -- IF l_ship_to_location_id IS NULL
      END IF;
      --=============================================================================
      -- Validating the Supplier Site - bill to Location Code
      --=============================================================================
      IF l_sup_site_type.bill_to_location IS NOT NULL THEN
        l_bill_to_cnt                     := 0;
        OPEN c_bill_to_location(l_sup_site_type.bill_to_location);
        FETCH c_bill_to_location INTO l_bill_to_cnt;
        CLOSE c_bill_to_location;
        IF l_bill_to_cnt             =0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: BILL_TO_LOCATION:'||l_sup_site_type.bill_to_location||': XXOD_BILL_TO_LOCATION_INVALID2: Bill to Location does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_BILL_TO_LOCATION_INVALID2' ,p_error_message => 'Bill to Location '||l_sup_site_type.bill_to_location||' does not exist in the system' ,p_stage_col1 => 'SHIP_TO_LOCATION' ,p_stage_val1 => l_sup_site_type.bill_to_location ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' Bill to Location Id is avilable ' ,p_force=> false);
        END IF; -- IF l_ship_to_location_id IS NULL
      END IF;
      --=============================================================================
      -- Validating Terms 
      --=============================================================================
      IF l_sup_site_type.terms_name IS NOT NULL THEN	  
	      OPEN c_get_term_id(xx_get_terms(l_sup_site_type.terms_name));
         FETCH c_get_term_id INTO ln_terms_id;
         CLOSE c_get_term_id;
         IF NVL(ln_terms_id,0) = 0
		 THEN
            gc_error_site_status_flag := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: TERMS :'||l_sup_site_type.terms_name||': Terms does not exist in the system.' ,p_force=> true);
            insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.vendor_site_code,
						  p_error_code => 'XXOD_TERMS_INVALID',
						  p_error_message => 'Terms :'||l_sup_site_type.terms_name||' does not exist in the system' ,
						  p_stage_col1 => 'TERMS' ,p_stage_val1 => l_sup_site_type.terms_name,p_stage_col2 => NULL ,
						  p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
         ELSE 
            print_debug_msg(p_message=> gc_step||' Terms is available ' ,p_force=> false);
         END IF; 
      END IF;
	  
      --=============================================================================
      -- Validating the Supplier Site - FOB Lookup value
      --=============================================================================
      l_fob_code_cnt                     := NULL;
      IF l_sup_site_type.fob_lookup_code IS NOT NULL THEN -- Derive the FOB Code
        l_fob_code_cnt                   := 0;
        OPEN c_get_fnd_lookup_code_cnt('FOB', l_sup_site_type.fob_lookup_code);
        FETCH c_get_fnd_lookup_code_cnt INTO l_fob_code_cnt;
        CLOSE c_get_fnd_lookup_code_cnt;
        IF l_fob_code_cnt            =0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FOB:' ||l_sup_site_type.fob_lookup_code||': XXOD_FOB_INVALID: FOB does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_FOB_INVALID' , p_error_message => 'FOB '||l_sup_site_type.fob_lookup_code||' does not exist in the system' , p_stage_col1 => 'FOB' ,p_stage_val1 => l_sup_site_type.fob_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' FOB Code of FOB - ' ||l_sup_site_type.fob_lookup_code,p_force=> false);
        END IF; -- IF l_fob_code IS NULL
      END IF;   -- IF l_sup_site_type.FOB IS NOT NULL
      --=============================================================================
      -- Validating the Supplier Site - FREIGHT_TERMS Lookup value
      --=============================================================================
      l_freight_terms_code_cnt                     := 0;
      IF l_sup_site_type.freight_terms_lookup_code IS NOT NULL THEN -- Derive the FREIGHT_TERMS Code
        l_freight_terms_code_cnt                   := 0;
        OPEN c_get_fnd_lookup_code_cnt('FREIGHT TERMS', l_sup_site_type.freight_terms_lookup_code);
        FETCH c_get_fnd_lookup_code_cnt INTO l_freight_terms_code_cnt;
        CLOSE c_get_fnd_lookup_code_cnt;
        IF l_freight_terms_code_cnt  =0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FREIGHT_TERMS:'||l_sup_site_type.freight_terms_lookup_code||': XXOD_FREIGHT_TERMS_INVALID: FREIGHT TERMS does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name , p_error_code => 'XXOD_FREIGHT_TERMS_INVALID' ,p_error_message => 'FREIGHT TERMS ' ||l_sup_site_type.freight_terms_lookup_code||' does not exist in the system' ,p_stage_col1 => 'Freight Terms' , p_stage_val1 => l_sup_site_type.freight_terms_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' FREIGHT TERMS Code of FREIGHT TERMS - ' ||l_sup_site_type.freight_terms_lookup_code ,p_force=> false);
        END IF; -- IF l_freight_terms_code IS NULL
      END IF;   -- IF l_sup_site_type.FREIGHT_TERMS IS NOT NULL
      --==============================================================================================================
      -- Validating the Supplier Site - Payment Method Check again priyam
      --==============================================================================================================
      IF l_sup_site_type.payment_method_lookup_code IS NULL THEN
        l_payment_method                            := 'CHECK';
        print_debug_msg(p_message=> gc_step||' Default value set for l_payment_method is '||l_payment_method ,p_force=> false);
      ELSE -- Check the existence of Payment Method
        l_pay_method_cnt := 0;
        OPEN c_pay_method_exist(l_sup_site_type.payment_method_lookup_code);
        FETCH c_pay_method_exist INTO l_pay_method_cnt;
        CLOSE c_pay_method_exist;
        IF l_pay_method_cnt          = 0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PAYMENT_METHOD:'||l_sup_site_type.payment_method_lookup_code||': XXOD_PAYMENT_METHOD_INVALID: Payment Method does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_PAYMENT_METHOD_INVALID' ,p_error_message => 'Payment Method does not exist in the system' ,p_stage_col1 => 'PAYMENT_METHOD' ,p_stage_val1 => l_sup_site_type.payment_method_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' PAYMENT_METHOD:'||l_sup_site_type.payment_method_lookup_code||' exist in the system.' ,p_force=> false);
          l_payment_method := l_sup_site_type.payment_method_lookup_code;
        END IF; -- IF l_pay_method_cnt < 1
      END IF;   -- IF l_sup_site_type.PAYMENT_METHOD IS NULL

       --=============================================================================
      -- Validating the Supplier Site - Service Tolerance
      --=============================================================================
      IF l_sup_site_type.service_tolerance IS NULL THEN
         l_service_tolerance_name                := 'US_OD_TOLERANCES_Default';
      ELSE
         l_service_tolerance_name := l_sup_site_type.service_tolerance;
      END IF;
      l_service_tolerance_cnt := 0;
  
       OPEN c_get_tolerance(l_service_tolerance_name);
      FETCH c_get_tolerance INTO l_service_tolerance_cnt;
      CLOSE c_get_tolerance;
      IF l_service_tolerance_cnt          =0 THEN
         gc_error_site_status_flag := 'Y';
         print_debug_msg(p_message=> gc_step||' ERROR: Service Tolerance :'||l_sup_site_type.service_tolerance||': XXOD_SERVICE_TOLERANCE_INVALID: Service Tolerance does not exist in the system.' ,p_force=> true);
         insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SERVICE_TOLERANCE_INVALID' ,p_error_message => 'Service Tolerance '||l_sup_site_type.service_tolerance||' does not exist in the system' ,p_stage_col1 => 'SERVICE_TOLERANCE' ,p_stage_val1 => l_sup_site_type.service_tolerance ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
      ELSE
         print_debug_msg(p_message=> gc_step||' Service Tolerance Id is available' ,p_force=> false);
      END IF; -- IF l_service_tolerance_id IS NULL
      --=============================================================================
      -- Validating the Supplier Site - Invoice Tolerance
      --=============================================================================
      IF l_sup_site_type.tolerance_name IS NULL THEN
        l_tolerance_name                := 'US_OD_TOLERANCES_Default';
      ELSE
        l_tolerance_name := l_sup_site_type.tolerance_name;
      END IF;
      l_tolerance_cnt := 0;
      OPEN c_get_tolerance(l_tolerance_name);
      FETCH c_get_tolerance INTO l_tolerance_cnt;
      CLOSE c_get_tolerance;
      IF l_tolerance_cnt           =0 THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: INVOICE_TOLERANCE:'||l_sup_site_type.tolerance_name||': XXOD_INV_TOLERANCE_INVALID: Invoice Tolerance does not exist in the system.' ,p_force=> true);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_INV_TOLERANCE_INVALID' ,p_error_message => 'Invoice Tolerance '||l_sup_site_type.tolerance_name||' does not exist in the system' ,p_stage_col1 => 'INVOICE_TOLERANCE' ,p_stage_val1 => l_sup_site_type.tolerance_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
      ELSE
        print_debug_msg(p_message=> gc_step||' Invoice Tolerance Id is available' ,p_force=> false);
      END IF; -- IF l_tolerance_id IS NULL
      --=============================================================================
      -- Defaulting the Supplier Site - Payment Priority
      --=============================================================================
      IF l_sup_site_type.payment_priority IS NULL THEN
        l_payment_priority                := 99;
      ELSE
        l_payment_priority := l_sup_site_type.payment_priority;
      END IF;
      --==============================================================================================================
      -- Validating the Supplier Site - Pay Group
      --==============================================================================================================
      IF l_sup_site_type.pay_group_lookup_code IS NOT NULL THEN
        l_pay_group                            := l_sup_site_type.pay_group_lookup_code;
        l_pay_group_code_cnt                   := 0;
        OPEN c_get_fnd_lookup_code_cnt('PAY GROUP', l_pay_group);
        FETCH c_get_fnd_lookup_code_cnt INTO l_pay_group_code_cnt;
        CLOSE c_get_fnd_lookup_code_cnt;
        IF l_pay_group_code_cnt      = 0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PAY_GROUP:'||l_sup_site_type.pay_group_lookup_code||': XXOD_PAY_GROUP_INVALID: Pay Group does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_PAY_GROUP_INVALID' ,p_error_message => 'Pay Group '||l_sup_site_type.pay_group_lookup_code||' does not exist in the system' ,p_stage_col1 => 'PAY_GROUP' ,p_stage_val1 => l_sup_site_type.pay_group_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        END IF;
      END IF; -- IF l_pay_group_code IS NULL
      --=============================================================================
      -- Defaulting the Supplier Site - Deduct Bank Charge
      --=============================================================================
      IF l_sup_site_type.bank_charge_deduction_type IS NULL THEN
        l_deduct_bank_chrg                          := 'D';
      ELSE
        l_deduct_bank_chrg := l_sup_site_type.bank_charge_deduction_type;
      END IF;
      --==============================================================================================================
      -- Validating the Supplier Site - Terms Date Basis TERMS_DATE_BASIS => use the value what is received
      --==============================================================================================================
      l_terms_date_basis                  := NULL;
      IF l_sup_site_type.terms_date_basis IS NOT NULL THEN
        l_terms_date_basis                :=l_sup_site_type.terms_date_basis;
        l_terms_date_basis_code_cnt       := NULL;
        OPEN c_get_fnd_lookup_code_cnt('TERMS DATE BASIS', l_terms_date_basis);
        FETCH c_get_fnd_lookup_code_cnt INTO l_terms_date_basis_code_cnt;
        CLOSE c_get_fnd_lookup_code_cnt;
        IF l_terms_date_basis_code_cnt = 0 THEN
          gc_error_site_status_flag   := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: TERMS_DATE_BASIS:'||l_sup_site_type.terms_date_basis||': XXOD_TERMS_DATE_BASIS_INVALID: Terms Date Basis does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_TERMS_DATE_BASIS_INVALID' ,p_error_message => 'Terms Date Basis value '||l_sup_site_type.terms_date_basis||' does not exist in the system' ,p_stage_col1 => 'TERMS_DATE_BASIS' ,p_stage_val1 => l_sup_site_type.terms_date_basis ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        END IF; -- IF l_terms_date_basis_code IS NULL
      END IF;   -- IF l_sup_site_type.TERMS_DATE_BASIS is not NULL THEN
      --=============================================================================
      -- Defaulting the Supplier Site - Always Take Discount Flag
      --=============================================================================
      IF l_sup_site_type.always_take_disc_flag IS NULL THEN
        l_always_disc_flag                     := 'Y';
      ELSE
        l_always_disc_flag := l_sup_site_type.always_take_disc_flag;
      END IF;
      l_sup_site_and_add(l_sup_site_idx).create_flag :=l_sup_create_flag;
    END IF; -- IF  gc_error_site_status_flag = 'N' -- After Supplier Site Existence Check Completed
    l_sup_site_and_add(l_sup_site_idx).supplier_name       := l_sup_site_type.supplier_name;
    l_sup_site_and_add(l_sup_site_idx).supplier_number     := l_sup_site_type.supplier_number;
    l_sup_site_and_add(l_sup_site_idx).vendor_site_code    := l_sup_site_type.vendor_site_code;
    l_sup_site_and_add(l_sup_site_idx).vendor_id           := l_sup_site_type.supp_id;
    l_sup_site_and_add(l_sup_site_idx).terms_id            := ln_terms_id;	
    IF gc_error_site_status_flag                            = 'Y' THEN
      l_sup_site_and_add(l_sup_site_idx).site_process_flag := gn_process_status_error;
      l_sup_site_and_add(l_sup_site_idx).error_flag        := gc_process_error_flag;
      l_sup_site_and_add(l_sup_site_idx).error_msg         := gc_error_msg;
    ELSE
      l_sup_site_and_add (l_sup_site_idx).site_process_flag := gn_process_status_validated;
      print_debug_msg(p_message=> gc_step||' ELSE l_sup_site_idx).STG_PROCESS_FLAG ' || l_sup_site_and_add(l_sup_site_idx).site_process_flag);
    END IF;
  END LOOP; --  FOR l_sup_site_type IN c_supplier_site
  --============================================================================
  -- For Doing the Bulk Update
  --============================================================================
  print_debug_msg(p_message=> 'Do Bulk Update for all Site Records ' ,p_force=> true);
  print_debug_msg(p_message=> 'l_sup_site_and_add.COUNT '||l_sup_site_and_add.count ,p_force=> true);
  IF l_sup_site_and_add.count > 0 THEN
    BEGIN
      print_debug_msg(p_message=> l_program_step||'gn_request_id ' ||gn_request_id ,p_force=> true);
      FORALL l_idxs IN l_sup_site_and_add.FIRST .. l_sup_site_and_add.LAST
      UPDATE xx_ap_cld_supp_sites_stg
      SET site_process_flag = l_sup_site_and_add(l_idxs).site_process_flag ,
        error_flag          = l_sup_site_and_add(l_idxs).error_flag ,
        error_msg           = l_sup_site_and_add(l_idxs).error_msg,
        create_flag         =l_sup_site_and_add(l_idxs).create_flag,
        last_updated_by     =g_user_id,
        last_update_date    =SYSDATE,
        process_flag        ='P',
        vendor_id           =l_sup_site_and_add(l_idxs).vendor_id,
        vendor_site_id      =l_sup_site_and_add (l_idxs).vendor_site_id,
		terms_id	        =l_sup_site_and_add (l_idxs).terms_id
      WHERE 1               =1
      AND vendor_site_code  =l_sup_site_and_add(l_idxs).vendor_site_code
      AND supplier_number   = l_sup_site_and_add(l_idxs).supplier_number
      AND request_id        = gn_request_id;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    END;
  END IF; -- IF l_sup_site_and_add.COUNT > 0
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_Site_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_supplier_site_records;
--+============================================================================+
--| Name          : Validate_supp_contact_records                                           |
--| Description   : This procedure will Validate Supplier Contact records  |
--|                                                                            |
--| Parameters    : p_vendor_is                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE validate_supp_contact_records(
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2 )
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
TYPE l_sup_cont_tab
IS
  TABLE OF xx_ap_cld_supp_contact_stg%ROWTYPE INDEX BY BINARY_INTEGER;
  l_sup_cont l_sup_cont_tab;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================
  CURSOR c_supplier_contact
  IS
    SELECT xasc.*,
      assi.vendor_id supp_id,
      apsup.vendor_site_id supp_site_id
    FROM xx_ap_cld_supp_contact_stg xasc,
      ap_supplier_sites_all apsup,
      ap_suppliers assi
    WHERE 1                       = 1
    AND apsup.vendor_site_code    = xasc.vendor_site_code
    AND apsup.vendor_id           = assi.vendor_id
    AND assi.segment1             = xasc.supplier_number
    AND xasc.contact_process_flag = gn_process_status_inprocess
    AND xasc.request_id           = gn_request_id
    AND cont_target               = 'EBS';
  --=========================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Interface table
  --=========================================================================
  CURSOR c_dup_supplier_chk_int(c_first_name VARCHAR2, c_last_name VARCHAR2, c_vendor_id NUMBER, c_vendor_site_id NUMBER )
  IS
    SELECT xasi.first_name,
      xasi.last_name
    FROM ap_sup_site_contact_int xasi
    WHERE xasi.status      = 'NEW'
    AND UPPER(first_name)  = UPPER(c_first_name)
    AND UPPER(last_name)   = UPPER(c_last_name)
    AND xasi.vendor_id     = c_vendor_id
    AND xasi.vendor_site_id= c_vendor_site_id;
  --==========================================================================================
  -- Cursor Declarations for Supplier Site existence
  --==========================================================================================
  -- CURSOR c_sup_contact_exist (c_supplier_name VARCHAR2 ,c_vendor_site_code VARCHAR2,c_first_name VARCHAR2,c_last_name VARCHAR2 )
  CURSOR c_sup_contact_exist (c_vendor_ID NUMBER , c_vendor_site_id NUMBER, c_first_name VARCHAR2, c_last_name VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM ap_suppliers asp ,
      ap_supplier_sites_all ass ,
      ap_supplier_contacts apsc ,
      hz_parties person ,
      hz_parties pty_rel,
      hr_operating_units hou
    WHERE ass.vendor_id                      = asp.vendor_id
    AND apsc.per_party_id                    = person.party_id
    AND apsc.rel_party_id                    = pty_rel.party_id
    AND ass.org_id                           = hou.organization_id
    AND apsc.org_party_site_id               = ass.party_site_id
    AND ass.vendor_id                        = c_vendor_id
    AND ass.vendor_site_id                   = c_vendor_site_id
    AND TRIM(UPPER(person.person_first_name))= TRIM(UPPER(c_first_name))
    AND TRIM(UPPER(person.person_last_name)) = TRIM(UPPER(c_last_name));
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_sup_cont_idx       NUMBER        := 0;
  l_procedure          VARCHAR2(30)  := 'validate_Supp_contact_records';
  l_program_step       VARCHAR2(100) := '';
  l_sup_create_flag    VARCHAR2(10)  := '';
  l_error_message      VARCHAR2(4000):= '';
  l_site_upd_cnt       NUMBER;
  l_ret_code           NUMBER;
  l_sup_cont_exist_cnt NUMBER;
  l_return_status      VARCHAR2(100);
  l_err_buff           VARCHAR2(4000);
  l_int_first_name     VARCHAR2(500);
  l_int_last_name      VARCHAR2(500);
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults' ,p_force=>TRUE);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  print_debug_msg(p_message=> l_program_step||': Opening Supplier Conatct Cursor' ,p_force=>TRUE);
  --==============================================================
  -- Check and Update the staging table for the Duplicate sites
  --==============================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate Contact', p_force => FALSE);
    l_site_upd_cnt := 0;
    UPDATE xx_ap_cld_supp_contact_stg xassc1
    SET xassc1.contact_process_flag  = gn_process_status_error ,
      xassc1.ERROR_FLAG              = gc_process_error_flag ,
      xassc1.ERROR_MSG               = 'ERROR: Duplicate Contact in Staging Table'
    WHERE xassc1.contact_process_flag= gn_process_status_inprocess
    AND xassc1.REQUEST_ID            = gn_request_id
    AND xassc1.cont_target           ='EBS'
    AND 2                           <=
      (SELECT COUNT(1)
      FROM xx_ap_cld_supp_contact_stg xassc2
      WHERE xassc2.contact_process_flag       IN (gn_process_status_inprocess)
      AND xassc2.cont_target                   = 'EBS'
      AND xassc2.request_id                    = gn_request_id
      AND TRIM(UPPER(xassc2.first_name))       = TRIM(UPPER(xassc1.first_name))
      AND TRIM(UPPER(xassc2.last_name))        = TRIM(UPPER(xassc1.last_name))
      AND TRIM(UPPER(xassc2.vendor_site_code)) = TRIM(UPPER(xassc1.vendor_site_code))
      AND xassc2.supplier_number               = xassc1.supplier_number
      ) ;
    l_site_upd_cnt   := SQL%ROWCOUNT;
    IF l_site_upd_cnt > 0 THEN
      print_debug_msg(p_message => 'Check and updated '||l_site_upd_cnt||' records as error in the staging table for the Duplicate Conatct', p_force => FALSE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate Contact in Staging table - '|| l_err_buff , p_force => TRUE);
    x_ret_code      := '1';
    x_return_status := 'E';
    x_err_buf       := l_err_buff;
    RETURN;
  END;
  --=====================================================================================
  -- Check and Update the contact Process Flag to '7' if all contact values are NULL
  --=====================================================================================
  ----Commneted by Priyam as this check will go at contact level
  BEGIN
    ---print_debug_msg(p_message => 'Check and Update the contact Process Flag to 7 if all contact values are NULL', p_force => false);
    l_site_upd_cnt := 0;
    UPDATE xx_ap_cld_supp_contact_stg xassc
    SET xassc.contact_process_flag = gn_process_status_error ,
      xassc.error_flag             = gc_process_error_flag ,
      xassc.error_msg              = error_msg
      ||',All Contact Values are null'
    WHERE xassc.contact_process_flag IN (gn_process_status_inprocess)
    AND xassc.request_id              = gn_request_id
    AND xassc.cont_target             = 'EBS'
    AND xassc.first_name             IS NULL
    AND xassc.last_name              IS NULL
    AND xassc.area_code              IS NULL
    AND xassc.contact_name_alt       IS NULL
    AND xassc.email_address          IS NULL
    AND xassc.phone                  IS NULL
    AND xassc.fax_area_code          IS NULL
    AND xassc.fax                    IS NULL;
    l_site_upd_cnt                   := SQL%ROWCOUNT;
    IF l_site_upd_cnt                 > 0 THEN
      print_debug_msg(p_message => 'Checked and Updated the contact Process Flag to Error for '||l_site_upd_cnt||' records as all contact values are NULL for eligible site', p_force => FALSE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
    print_debug_msg(p_message => 'ERROR-EXCEPTION: Updating when all contacts are NULL in Staging table - '|| l_err_buff , p_force => TRUE);
    x_ret_code      := '1';
    x_return_status := 'E';
    x_err_buf       := l_err_buff;
    RETURN;
  END;
  --====================================================================
  -- Call the Vendor Site Validations
  --====================================================================
  set_step( 'Start of Vendor Site conatct Loop Validations : ' || gc_error_status_flag);
  --commented by Priyam
  FOR l_sup_site_cont_type IN c_supplier_contact
  LOOP
    print_debug_msg(p_message=> gc_step||' : Validation of Supplier Site started' ,p_force=> TRUE);
    l_sup_cont_idx := l_sup_cont_idx + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_cont_idx - '||l_sup_cont_idx ,p_force=> TRUE);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'SITE_CONT';
    gc_error_msg              := '';
    OPEN c_dup_supplier_chk_int( TRIM(UPPER(l_sup_site_cont_type.first_name)), TRIM(UPPER(l_sup_site_cont_type.last_name)), l_sup_site_cont_type.supp_id, l_sup_site_cont_type.supp_site_id );
    FETCH c_dup_supplier_chk_int INTO l_int_first_name, l_int_last_name;
    CLOSE c_dup_supplier_chk_int;
    IF l_int_first_name         IS NOT NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message => l_program_step||' : ERROR: XXOD_SUP_EXISTS_IN_INT : Suppiler '|| l_sup_site_cont_type.supplier_name ||' already exist in   Interface table with ' , p_force => TRUE);
      insert_error ( p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_SUP_EXISTS_IN_INT' , p_error_message => 'Suppiler ' ||l_sup_site_cont_type.supplier_name||' already exist in Interface table ' ||' .' , p_stage_col1 => 'SUPPLIER_NAME' , p_stage_val1 => l_sup_site_cont_type.supplier_name , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
    END IF;
    --====================================================================
    -- Note Required
    --====================================================================
    IF l_sup_site_cont_type.first_name IS NULL THEN
      gc_error_site_status_flag        := 'Y';
      print_debug_msg(p_message => gc_step||' ERROR: FIRST_NAME:'||l_sup_site_cont_type.first_name|| ': XXOD_FIRST_NAME_NULL:FIRST_NAME cannot be NULL', p_force => FALSE);
      insert_error ( p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_FIRST_NAME_NULL' , p_error_message => 'First Name cannot be NULL' , p_stage_col1 => 'LAST_NAME_PREFIX' , p_stage_val1 => l_sup_site_cont_type.first_name , p_table_name => g_sup_cont_table );
    END IF;
    IF l_sup_site_cont_type.last_name IS NULL THEN
      gc_error_site_status_flag       := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: LAST_NAME:'||l_sup_site_cont_type.first_name|| ': XXOD_LAST_NAME_NULL:LAST_NAME cannot be NULL' , p_force=> FALSE);
      insert_error (p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_LAST_NAME_NULL' , p_error_message => 'Last Name cannot be NULL' , p_stage_col1 => 'LAST_NAME_PREFIX' , p_stage_val1 => l_sup_site_cont_type.last_name , p_table_name => g_sup_cont_table );
    END IF;
    print_debug_msg(p_message=> gc_step||' After basic validation of Contact - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> FALSE);
    l_sup_CREATE_FLAG           :='';
    IF gc_error_site_status_flag = 'N' THEN
      print_debug_msg(p_message=> gc_step||' l_sup_site_cont_type.update_flag is '||l_sup_site_cont_type.CREATE_FLAG , p_force => FALSE);
      print_debug_msg(p_message=> gc_step||' l_sup_site_cont_type.supplier_name is '||UPPER(l_sup_site_cont_type.supplier_name) , p_force => FALSE);
      print_debug_msg(p_message=> gc_step||' l_sup_site_cont_type.supplier_number is '||UPPER(l_sup_site_cont_type.supplier_number) , p_force => FALSE);
      print_debug_msg(p_message=> gc_step||' l_sup_site_cont_type.vendor_site_code is '||UPPER(l_sup_site_cont_type.vendor_site_code) , p_force => FALSE);
      l_sup_cont_exist_cnt := 0;
      OPEN c_sup_contact_exist( l_sup_site_cont_type.supp_id, l_sup_site_cont_type.supp_site_id, l_sup_site_cont_type.first_name, l_sup_site_cont_type.last_name );
      FETCH c_sup_contact_exist INTO l_sup_cont_exist_cnt;
      CLOSE c_sup_contact_exist;
      IF l_sup_cont_exist_cnt             > 0 THEN
        l_sup_create_flag                := 'n';--update the supplier
        l_sup_site_cont_type.create_flag := l_sup_create_flag;
      ELSE
        l_sup_create_flag                := 'Y';
        l_sup_site_cont_type.create_flag := l_sup_create_flag;
      END IF;
    ELSE
      l_sup_CREATE_FLAG               := '';
      gc_error_site_status_flag       := 'Y';
      l_sup_site_cont_type.create_flag:= l_sup_create_flag;
    END IF; -- gc_error_site_status_flag = 'N'
    print_debug_msg(p_message=> gc_step||' After supplier site existence check - gc_error_site_status_flag is '||gc_error_site_status_flag , p_force => FALSE);
    print_debug_msg(p_message=> gc_step||' After supplier site existence check - l_sup_create_flag is '||l_sup_CREATE_FLAG , p_force => FALSE);
    set_step('Supplier Contact Existence Check Completed');
	/*  -- Commented as per Version 2.0
	
    IF gc_error_site_status_flag = 'N' THEN -- After Supplier Site Existence Check Completed
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Phone area code
      --===============================================================================================
      IF l_sup_site_cont_type.area_code                                                                IS NOT NULL THEN
        IF (NOT (isnumeric(l_sup_site_cont_type.area_code)) OR (LENGTH(l_sup_site_cont_type.area_code) <> 3 )) THEN
          gc_error_site_status_flag                                                                    := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PHONE_AREA_CODE:'||l_sup_site_cont_type.area_code||': XXOD_PHONE_AREA_CODE_INVALID: Phone Area Code ' ||l_sup_site_cont_type.area_code||' should be numeric and 3 digits.' , p_force => TRUE);
          insert_error (p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_PHONE_AREA_CODE_INVALID' , p_error_message => 'Phone Area Code '||l_sup_site_cont_type.area_code||' should be numeric and 3 digits.' , p_stage_col1 => 'PHONE_AREA_CODE' , p_stage_val1 => l_sup_site_cont_type.area_code , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.PHONE_AREA_CODE))
      END IF;   -- IF l_sup_site_type.PHONE_AREA_CODE IS NOT NULL
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Phone Number
      --===============================================================================================
      IF l_sup_site_cont_type.phone IS NOT NULL THEN
        IF (LENGTH(l_sup_site_cont_type.phone) NOT IN (7,8) ) THEN -- Phone Number length is 7 and 1 digit count for '-'
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PHONE_NUMBER:'||l_sup_site_cont_type.phone||': XXOD_PHONE_NUMBER_INVALID: Phone Number ' ||l_sup_site_cont_type.phone||' should be 7 digits.' , p_force => TRUE);
          insert_error (p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_PHONE_NUMBER_INVALID' , p_error_message => 'Phone Number '||l_sup_site_cont_type.phone||' should be 7 digits.' , p_stage_col1 => 'PHONE_NUMBER' , p_stage_val1 => l_sup_site_cont_type.phone , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.PHONE_NUMBER))
      END IF;   -- IF l_sup_site_type.PHONE_NUMBER IS NOT NULL
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Fax area code
      --===============================================================================================
      IF l_sup_site_cont_type.fax_area_code                                                                    IS NOT NULL THEN
        IF (NOT (isnumeric(l_sup_site_cont_type.fax_area_code)) OR (LENGTH(l_sup_site_cont_type.fax_area_code) <> 3 )) THEN
          gc_error_site_status_flag                                                                            := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FAX_AREA_CODE:'||l_sup_site_cont_type.fax_area_code||': XXOD_FAX_AREA_CODE_INVALID: Fax Area Code ' ||l_sup_site_cont_type.fax_area_code||' should be numeric and 3 digits.' , p_force=> true);
          insert_error (p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_FAX_AREA_CODE_INVALID' , p_error_message => 'Fax Area Code '||l_sup_site_cont_type.fax_area_code||' should be numeric and 3 digits.' , p_stage_col1 => 'FAX_AREA_CODE' , p_stage_val1 => l_sup_site_cont_type.fax_area_code , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.FAX_AREA_CODE))
      END IF;   -- IF l_sup_site_type.FAX_AREA_CODE IS NOT NULL
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Fax Number/FAX updated by Priyam
      --===============================================================================================
      IF l_sup_site_cont_type.fax IS NOT NULL THEN
        IF (LENGTH(l_sup_site_cont_type.fax) NOT IN (7,8) ) THEN -- Fax Number length is 7 and 1 digit count for '-'
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FAX_NUMBER:'||l_sup_site_cont_type.fax||': XXOD_FAX_NUMBER_INVALID: Fax Number ' ||l_sup_site_cont_type.fax||' should be 7 digits.' , p_force=> true);
          insert_error ( p_program_step => gc_step , p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_FAX_NUMBER_INVALID' , p_error_message => 'Fax Number '||l_sup_site_cont_type.fax||' should be 7 digits.' , p_stage_col1 => 'FAX_NUMBER' , p_stage_val1 => l_sup_site_cont_type.fax , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.FAX_NUMBER))
      END IF;   -- IF l_sup_site_type.FAX_NUMBER IS NOT NULL
    END IF;     -- IF  gc_error_site_status_flag = 'N' -- After Supplier Contact Existence Check Completed
	*/ -- 
    ------------------------Assigning values
    l_sup_cont(l_sup_cont_idx).create_flag            :=l_sup_create_flag;
    l_sup_cont(l_sup_cont_idx).vendor_site_code       :=l_sup_site_cont_type.vendor_site_code;
    l_sup_cont(l_sup_cont_idx).supplier_name          :=l_sup_site_cont_type.supplier_name;
    l_sup_cont(l_sup_cont_idx).vendor_id              :=l_sup_site_cont_type.supp_id;
    l_sup_cont(l_sup_cont_idx).vendor_site_id         :=l_sup_site_cont_type.supp_site_id;
    l_sup_cont(l_sup_cont_idx).supplier_number        :=l_sup_site_cont_type.supplier_number;
    l_sup_cont(l_sup_cont_idx).first_name             :=l_sup_site_cont_type.first_name;
    l_sup_cont(l_sup_cont_idx).last_name              :=l_sup_site_cont_type.last_name;
    IF gc_error_site_status_flag                       = 'Y' THEN
      l_sup_cont(l_sup_cont_idx).contact_process_flag := gn_process_status_error;
      l_sup_cont(l_sup_cont_idx).error_flag           := gc_process_error_flag;
      l_sup_cont(l_sup_cont_idx).error_msg            := gc_error_msg;
      l_sup_site_cont_type.error_msg                  := l_sup_site_cont_type.error_msg||' Contact ERROR : '||gc_error_msg||';';
      print_debug_msg(p_message=> gc_step||' IF l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
    ELSE
      l_sup_cont(l_sup_cont_idx).contact_process_flag := gn_process_status_validated;
      print_debug_msg(p_message=> gc_step||' ELSE l l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
    END IF;
    print_debug_msg(p_message=> gc_step||' ELSE l l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
  END LOOP; --  FOR l_sup_site_type IN c_supplier_contact
  --- print_debug_msg(p_message=> gc_step ||' List of the contact failed prefixes is '||l_error_prefix_list , p_force => TRUE);
  l_program_step := '';
  print_debug_msg(p_message=> l_program_step||': Do Bulk Update for all Contact Records ' , p_force => TRUE);
  print_debug_msg(p_message=> l_program_step||'l_sup_cont.COUNT '||l_sup_cont.COUNT , p_force => TRUE);
  IF l_sup_cont.COUNT > 0 THEN
    BEGIN
      print_debug_msg(p_message=> l_program_step||'gn_request_id ' ||gn_request_id , p_force => TRUE);
      FORALL l_idxs IN l_sup_cont.FIRST .. l_sup_cont.LAST
      UPDATE xx_ap_cld_supp_contact_stg
      SET contact_process_flag          = l_sup_cont(l_idxs).contact_process_flag,
        error_flag                      = l_sup_cont(l_idxs).error_flag ,
        error_msg                       = l_sup_cont(l_idxs).error_msg,
        create_flag                     = l_sup_cont(l_idxs).create_flag,
        last_updated_by                 = g_user_id,
        last_update_date                = SYSDATE,
        vendor_id                       = l_sup_cont(l_idxs).vendor_id,
        vendor_site_id                  = l_sup_cont(l_idxs).vendor_site_id
      WHERE supplier_number             = l_sup_cont(l_idxs).supplier_number
      AND TRIM(UPPER(first_name))       = TRIM(UPPER(l_sup_cont(l_idxs).first_name))
      AND TRIM(UPPER(last_name))        = TRIM(UPPER(l_sup_cont(l_idxs).last_name))
      AND TRIM(UPPER(vendor_site_code)) = TRIM(UPPER(l_sup_cont(l_idxs).vendor_site_code))
      AND request_id                    = gn_request_id
      AND cont_target                   ='EBS';
      COMMIT;
    EXCEPTION
    WHEN no_data_found THEN
      l_error_message := 'When No Data Found during the bulk update of Contact staging table';
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE_CONT' , p_primary_key => NULL , p_error_code => 'XXOD_BULK_UPD_Contact' , p_error_message => 'When No Data Found during the bulk update of site staging table' , p_stage_col1 => NULL , p_stage_val1 => NULL , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> TRUE);
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (SQLERRM ,1 ,3800 );
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE_CONT' , p_primary_key => NULL , p_error_code => 'XXOD_BULK_UPD_SITE' , p_error_message => 'When Others Exception during the bulk update of site staging table' , p_stage_col1 => NULL , p_stage_val1 => NULL , p_stage_col2 => NULL , p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message , p_force => TRUE);
    END;
  END IF;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => TRUE);
  print_debug_msg(p_message => '----------------------', p_force => TRUE);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => TRUE);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_Contact_records() API - '|| l_err_buff , p_force => TRUE);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_supp_contact_records;
--+============================================================================+
--| Name          : Update_bank_assignment_date                                |
--| Description   : This procedure will Update_bank_acct_date using API        |
--|                                                                            |
--| Parameters    : x_ret_code OUT NUMBER ,                                    |
--|                 x_return_status OUT VARCHAR2 ,                             |
--|                 x_err_buf OUT VARCHAR2                                     |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE Update_bank_assignment_date(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2)
IS
  x_bank_branch_rec iby_ext_bankacct_pub.extbankacct_rec_type;
  p_assignment_attribs iby_fndcpt_setup_pub.pmtinstrassignment_rec_type;
  p_payee iby_disbursement_setup_pub.payeecontext_rec_type;
  lr_ext_bank_acct_dtl iby_ext_bank_accounts%rowtype;
  p_api_version          NUMBER;
  p_init_msg_list        VARCHAR2(200);
  p_commit               VARCHAR2(200);
  p_validation_level     NUMBER;
  x_msg_count            NUMBER;
  x_msg_data             VARCHAR2(200);
  p_calling_prog         VARCHAR2(200);
  l_program_step         VARCHAR2 (100) := '';
  ln_msg_index_num       NUMBER;
  l_msg                  VARCHAR2(2000);
  l_process_flag         VARCHAR2(10);
  lv_supp_site_id        VARCHAR2(100);
  lv_supp_party_site_id  VARCHAR2(100);
  lv_acct_owner_party_id VARCHAR2(100);
  lv_org_id              NUMBER;
  x_assign_id            NUMBER;
  -- l_fax_area_code hz_contact_points.phone_area_code%type;
  l_account_id NUMBER;
  x_response iby_fndcpt_common_pub.result_rec_type;
  l_assign_id           NUMBER;
  l_joint_acct_owner_id NUMBER;
  CURSOR c_sup_bank
  IS
    SELECT *
    FROM xx_ap_cld_supp_bnkact_stg xas
    WHERE 1                     =1
    AND xas.create_flag         ='N'
    AND xas.bnkact_process_flag =gn_process_status_validated
    AND xas.request_id          = gn_request_id;
  ----
BEGIN
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';
  print_debug_msg(p_message=> l_program_step||'Update Bank Assignment Dates' , p_force=>true);
  FOR r_sup_bank IN c_sup_bank
  LOOP
    print_debug_msg(p_message=> l_program_step||'Inside Cursor', p_force=>true);
    BEGIN
      SELECT assa.vendor_site_id,
        assa.party_site_id,
        aps.party_id,
        assa.org_id
      INTO lv_supp_site_id,
        lv_supp_party_site_id,
        lv_acct_owner_party_id,
        lv_org_id
      FROM ap_suppliers aps,
        ap_supplier_sites_all assa
      WHERE aps.vendor_id     = assa.vendor_id
      AND aps.vendor_id       =r_sup_bank.vendor_id
      AND assa.vendor_site_id = r_sup_bank.vendor_site_id;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||'Error- Get supp_site_id and supp_party_site_id' || SQLCODE || sqlerrm, p_force=>true);
    END;
    p_payee.supplier_site_id := lv_supp_site_id;
    p_payee.party_id         := lv_acct_owner_party_id;
    p_payee.party_site_id    := lv_supp_party_site_id;
    p_payee.payment_function := 'PAYABLES_DISB';
    p_payee.org_id           := lv_org_id;
    p_payee.org_type         := 'OPERATING_UNIT';
    -- Assignment Values
    p_assignment_attribs.instrument.instrument_type := 'BANKACCOUNT';
    l_account_id                                    :=r_sup_bank.account_id;
    print_debug_msg(p_message=> l_program_step||'L_ACCOUNT_ID '||l_account_id, p_force=>true);
    p_assignment_attribs.instrument.instrument_id:=l_account_id;
    p_assignment_attribs.Assignment_Id           :=r_sup_bank.instrument_uses_id;
    p_assignment_attribs.priority                := 1;
    p_assignment_attribs.start_date              := TO_DATE(r_sup_bank.start_date,'YYYY/MM/DD');
    p_assignment_attribs.end_date                := TO_DATE(r_sup_bank.end_date,'YYYY/MM/DD');
    fnd_msg_pub.initialize; --to make msg_count 0
    x_return_status:=NULL;
    x_msg_count    :=NULL;
    x_msg_data     :=NULL;
    x_response     :=NULL;
    --------------------Call the API for istr assignemtn
    iby_disbursement_setup_pub.set_payee_instr_assignment (p_api_version => p_api_version, p_init_msg_list => p_init_msg_list, p_commit => p_commit, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data, p_payee => p_payee, p_assignment_attribs => p_assignment_attribs, x_assign_id => l_assign_id, x_response => x_response );
    COMMIT;
    print_debug_msg(p_message=> l_program_step||' SET_PAYEE_INSTR_ASSIGNMENT END_DATE X_ASSIGN_ID = ' || l_assign_id, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT END_DATE X_RETURN_STATUS = ' || x_return_status, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT END_DATE fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
    print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT END_DATE X_MSG_COUNT = ' || x_msg_count, p_force=>true);
    IF x_return_status = 'E' THEN
      print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
      print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
      FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
      LOOP
        fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
        print_debug_msg(p_message=> l_program_step||'The API SET_PAYEE_INSTR_ASSIGNMENT END_DATE call failed with error ' || l_msg , p_force=>true);
      END LOOP;
      l_process_flag:='E';
    ELSE
      print_debug_msg(p_message=> l_program_step||'The API SET_PAYEE_INSTR_ASSIGNMENT END_DATE call ended with SUCESSS status' , p_force=>true);
      l_process_flag:='Y';
      l_msg         :='';
    END IF;
    BEGIN
      UPDATE xx_ap_cld_supp_bnkact_stg xas
      SET xas.bnkact_process_flag    =DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),---6
        xas.error_flag               =DECODE( l_process_flag,'Y',NULL,'E','Y'),
        xas.error_msg                = l_msg,
        xas.account_id               =l_account_id,
        process_flag                 ='Y'
      WHERE xas.bnkact_process_flag  =gn_process_status_validated
      AND xas.request_id             = gn_request_id
      AND xas.supplier_num           =r_sup_bank.supplier_num
      AND TRIM(xas.vendor_site_code) =TRIM(r_sup_bank.vendor_site_code)
      AND bank_account_num           =r_sup_bank.bank_account_num
      AND bank_name                  =r_sup_bank.bank_name
      AND branch_name                =r_sup_bank.branch_name;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||'In Exception to update Bank Assignment records', p_force=>true);
    END ;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,SQLCODE||','||sqlerrm);
END Update_bank_assignment_date;
--+============================================================================+
--| Name          : validate_bank_records                                      |
--| Description   : This procedure will validate Supplier Bank Records         |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE validate_bank_records(
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2 )
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
TYPE l_sup_bank_tab
IS
  TABLE OF XX_AP_CLD_SUPP_BNKACT_STG%rowtype INDEX BY binary_integer;
  l_sup_bank l_sup_bank_tab;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================
  CURSOR c_supplier_bank
  IS
    SELECT xasc.*,
      apsup.vendor_id supp_id,
      apsup.vendor_site_code supp_site_code,
      apsup.vendor_site_id supp_site_id,
      apsup.party_site_id party_site_id
    FROM ap_suppliers assi,
      ap_supplier_sites_all apsup,
      xx_ap_cld_supp_bnkact_stg xasc
    WHERE xasc.request_id         = gn_request_id
    AND xasc.bnkact_process_flag IN (gn_process_status_inprocess)
    AND apsup.vendor_site_code    =xasc.vendor_site_code
    AND assi.vendor_id            =apsup.vendor_id
    AND assi.segment1             =xasc.supplier_num;
  CURSOR c_bank_branch(p_bank_name VARCHAR2, p_country VARCHAR2,p_branch VARCHAR2)
  IS
    SELECT b.bank_party_id,
      b.branch_party_id
    FROM ce_bank_branches_v b,
      hz_parties a
    WHERE a.party_name    =p_bank_name
    AND b.bank_party_id   =a.party_id
    AND b.bank_branch_name=p_branch
    AND b.country         =p_country
    AND SYSDATE BETWEEN b.start_date AND NVL(end_date,sysdate+1);
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_sup_bank_idx       NUMBER         := 0;
  l_procedure          VARCHAR2 (30)  := 'validate_bank_records';
  l_program_step       VARCHAR2 (100) := '';
  l_ret_code           NUMBER;
  l_return_status      VARCHAR2 (100);
  l_err_buff           VARCHAR2 (4000);
  l_error_message      VARCHAR2(4000) := '';
  l_site_cnt_for_bank  NUMBER;
  l_bank_upd_cnt       NUMBER       :=0;
  l_bank_create_flag   VARCHAR2(10) := '';
  l_sup_bank_id        NUMBER;
  l_sup_bank_branch_id NUMBER;
  l_bank_account_id    NUMBER;
  l_instrument_id      NUMBER;
  ---l_bank_acct_end_date   date;
  l_bank_acct_start_date VARCHAR2(50);
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> 'Begin Validate Bank Records Procedure ',p_force=>true);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  --====================================================================
  -- Check and Update the staging table for the Duplicate bank accounts
  --====================================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate bank', p_force => false);
    l_bank_upd_cnt := 0;
    UPDATE xx_ap_cld_supp_bnkact_stg xassc1
    SET xassc1.bnkact_process_flag   = gn_process_status_error ,
      xassc1.error_flag              = gc_process_error_flag ,
      xassc1.error_msg               = 'error: duplicate bank assignment in staging table'
    WHERE xassc1.bnkact_process_flag = gn_process_status_inprocess
    AND xassc1.REQUEST_ID            = gn_request_id
    AND 2                           <=
      (SELECT COUNT(1)
      FROM xx_ap_cld_supp_bnkact_stg xassc2
      WHERE xassc2.bnkact_process_flag        IN (gn_process_status_inprocess)
      AND xassc2.request_id                    = gn_request_id
      AND TRIM(UPPER(xassc2.supplier_num))     = TRIM(UPPER(xassc1.supplier_num))
      AND TRIM(UPPER(xassc2.vendor_site_code)) = TRIM(UPPER(xassc1.vendor_site_code))
      AND TRIM(UPPER(xassc2.bank_name))        = TRIM(UPPER(xassc1.bank_name))
      AND TRIM(UPPER(xassc2.branch_name))      = TRIM(UPPER(xassc1.branch_name))
      AND xassc2.bank_account_num              = xassc1.bank_account_num
      );
    l_bank_upd_cnt := sql%rowcount;
    print_debug_msg(p_message => 'Check and updated '||l_bank_upd_cnt||' records as error in the staging table for the Duplicate Bank', p_force => false);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate bank assignment in Staging table - '|| l_err_buff , p_force => false);
  END;
  --=====================================================================================
  -- Check and Update the Bank process flag to '7' if all Bank Information are NULL
  --=====================================================================================
  BEGIN
    l_bank_upd_cnt := 0;
    UPDATE xx_ap_cld_supp_bnkact_stg xassc
    SET xassc.bnkact_process_flag = gn_process_status_error ,
      xassc.error_flag            = gc_process_error_flag ,
      xassc.error_msg             = error_msg
      ||',bank or branch information is null'
    WHERE xassc.bnkact_process_flag IN (gn_process_status_inprocess)
    AND xassc.request_id             = gn_request_id
    AND ( xassc.bank_name           IS NULL
    OR xassc.branch_name            IS NULL ) ;
    l_bank_upd_cnt                  := sql%rowcount;
    print_debug_msg(p_message => 'After Bank or branch information is null', p_force => false);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR-EXCEPTION: Bank or branch information is null - '|| l_err_buff , p_force => false);
  END;
  --====================================================================
  -- Call the Bank Account Validations
  --====================================================================
  l_site_cnt_for_bank := 0;
  FOR l_sup_bank_type IN c_supplier_bank
  LOOP
    print_debug_msg(p_message=> gc_step||' : Validation of Bank Assignment started' ,p_force=> false);
    l_sup_bank_idx      := l_sup_bank_idx      + 1;
    l_site_cnt_for_bank := l_site_cnt_for_bank + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_bank_idx - '||l_sup_bank_idx ,p_force=> false);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'BANK_ASSI';
    gc_error_msg              := '';
    --====================================================================
    -- Checking Required Columns validation
    --====================================================================
    IF l_sup_bank_type.supplier_name IS NULL THEN
      gc_error_site_status_flag      := 'Y';
      gc_error_msg                   :=gc_error_msg||' Supplier Name is NULL';
      print_debug_msg(p_message=> gc_step||' ERROR: supplier_name:' ||l_sup_bank_type.supplier_name|| ': XXOD_supplier_NAME_NULL:FIRST_NAME cannot be NULL', p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_bank_type.supplier_name , p_error_code => 'XXOD_supplier_NAME_NULL' ,p_error_message => 'supplier_name cannot be NULL' , p_stage_col1 => 'XXOD_supplier_NAME_NULL' ,p_stage_val1 => l_sup_bank_type.supplier_name , p_table_name => g_sup_bank_table );
    END IF;
    IF l_sup_bank_type.supplier_num IS NULL THEN
      gc_error_site_status_flag     := 'Y';
      gc_error_msg                  :=gc_error_msg||', Supplier Number is NULL';
      print_debug_msg(p_message=> gc_step||' ERROR: supplier_num:' ||l_sup_bank_type.supplier_num|| ': XXOD_supplier_num_NULL:LAST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_bank_type.supplier_num ,p_error_code => 'XXOD_supplier_num_NULL' , p_error_message => 'supplier Num cannot be NULL' ,p_stage_col1 => 'XXOD_supplier_num_NULL' , p_stage_val1 => l_sup_bank_type.supplier_num ,p_table_name => g_sup_bank_table );
    END IF;
    IF l_sup_bank_type.vendor_site_code IS NULL THEN
      gc_error_site_status_flag         := 'Y';
      gc_error_msg                      :=gc_error_msg||', Vendor Site Code is NULL';
      print_debug_msg(p_message=> gc_step||' ERROR: vendor_site_code:' ||l_sup_bank_type.vendor_site_code|| ': XXOD_vendor_site_code_NULL:LAST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_bank_type.vendor_site_code ,p_error_code => 'XXOD_vendor_site_code_NULL' , p_error_message => 'vendor_site_code cannot be NULL' ,p_stage_col1 => 'XXOD_vendor_site_code_NULL' , p_stage_val1 => l_sup_bank_type.vendor_site_code ,p_table_name => g_sup_bank_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  Address Line 2
    --==============================================================================================================
    print_debug_msg(p_message=> gc_step||' After basic validation of Contact - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    l_bank_CREATE_FLAG          :='';
    IF gc_error_site_status_flag = 'N' THEN
      print_debug_msg(p_message=> gc_step||' l_sup_bank_type.update_flag is '||l_sup_bank_type.CREATE_FLAG ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_bank_type.vendor_site_code) is '||upper(l_sup_bank_type.vendor_site_code) ,p_force=> false);
      OPEN c_bank_branch(l_sup_bank_type.bank_name, l_sup_bank_type.country_code,l_sup_bank_type.branch_name);
      FETCH c_bank_branch INTO l_sup_bank_id,l_sup_bank_branch_id;
      CLOSE c_bank_branch;
      IF ( l_sup_bank_id          IS NULL OR l_sup_bank_branch_id IS NULL ) THEN
        gc_error_site_status_flag := 'Y';
        gc_error_msg              :=gc_error_msg||', Bank OR Branch does not exists';
        INSERT_ERROR (P_PROGRAM_STEP => GC_STEP , P_PRIMARY_KEY => L_SUP_BANK_TYPE.BANK_NAME , P_ERROR_CODE => 'XXOD_BANK_NULL' , P_ERROR_MESSAGE => 'Bank Information is null ' ||L_SUP_BANK_TYPE.BANK_NAME,P_STAGE_COL1 => 'XXOD_BANK_NULL' , P_STAGE_VAL1 => L_SUP_BANK_TYPE.BANK_NAME , P_TABLE_NAME => G_SUP_BANK_TABLE );
      ELSE
        l_sup_bank_type.bank_id   :=l_sup_bank_id;
        l_sup_bank_type.branch_id :=l_sup_bank_branch_id;
        l_instrument_id           :=NULL;
        l_bank_acct_start_date    :=NULL;
        l_bank_account_id         :=NULL;
        BEGIN
          SELECT ext_bank_account_id
          INTO l_bank_account_id
          FROM iby_ext_bank_accounts
          WHERE bank_id       =l_sup_bank_id
          AND branch_id       =l_sup_bank_branch_id
          AND bank_account_num=l_sup_bank_type.bank_account_num
          AND SYSDATE BETWEEN NVL(start_date,SYSDATE-1) AND NVL(end_date,SYSDATE+1);
          l_sup_bank_type.account_id :=l_bank_account_id;
        EXCEPTION
        WHEN OTHERS THEN
          l_bank_account_id           :=-1;
          l_bank_create_flag          :='Y';--Insert for Bank
          l_sup_bank_type.create_flag :=l_bank_create_flag;
        END;
        IF l_bank_account_id > 0 THEN
          BEGIN
            SELECT uses.instrument_payment_use_id,
              TO_CHAR(uses.start_date,'YYYY/MM/DD')
            INTO l_instrument_id,
              l_bank_acct_start_date
            FROM iby_pmt_instr_uses_all uses,
              iby_external_payees_all payee,
              iby_ext_bank_accounts accts,
              hz_parties bank,
              hz_organization_profiles bankprofile,
              ce_bank_branches_v branch
            WHERE bank.party_name      =l_sup_bank_type.bank_name
            AND uses.instrument_type   = 'BANKACCOUNT'
            AND payee.ext_payee_id     = uses.ext_pmt_party_id
            AND payee.payment_function = 'PAYABLES_DISB'
            AND payee.party_site_id    = l_sup_bank_type.party_site_id
            AND uses.instrument_id     = accts.ext_bank_account_id
            AND SYSDATE BETWEEN NVL(accts.start_date,SYSDATE) AND NVL(accts.end_date,SYSDATE)
            AND accts.bank_id            = bank.party_id(+)
            AND accts.bank_id            = bankprofile.party_id(+)
            AND accts.branch_id          = branch.branch_party_id(+)
            AND accts.bank_account_name  =l_sup_bank_type.bank_account_name
            AND branch.bank_branch_name  =l_sup_bank_type.branch_name
            AND accts.ext_bank_account_id=l_bank_account_id
            AND SYSDATE BETWEEN TRUNC (bankprofile.effective_start_date(+)) AND NVL(TRUNC(bankprofile.effective_end_date(+)),sysdate+ 1);
          EXCEPTION
          WHEN OTHERS THEN
            l_instrument_id             :=NULL;
            l_bank_create_flag          :='Y';--Insert for Bank
            l_sup_bank_type.create_flag :=l_bank_create_flag;
          END;
          l_sup_bank_type.instrument_uses_id :=l_instrument_id;
        END IF;
      END IF;
      IF l_instrument_id    > 0 AND l_sup_bank_type.end_date IS NOT NULL THEN
        l_bank_create_flag :='N';--Update for Bank assignment end Date
      ELSE
        l_bank_acct_start_date:=l_sup_bank_type.start_date;
      END IF;
      print_debug_msg(p_message=> gc_step||' After Bank Validation, Error Status Flag is : '||gc_error_site_status_flag ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' After Bank Validation, Bank Create  Flag is : '||l_bank_CREATE_FLAG ,p_force=> false);
      ------------------------Assigning values
      l_sup_bank(l_sup_bank_idx).create_flag        :=l_bank_create_flag;
      l_sup_bank(l_sup_bank_idx).start_date         :=l_bank_acct_start_date;
      l_sup_bank(l_sup_bank_idx).vendor_site_code   :=l_sup_bank_type.vendor_site_code;
      l_sup_bank(l_sup_bank_idx).supplier_name      :=l_sup_bank_type.supplier_name;
      l_sup_bank(l_sup_bank_idx).supplier_num       :=l_sup_bank_type.supplier_num;
      l_sup_bank(l_sup_bank_idx).bank_name          :=l_sup_bank_type.bank_name;
      l_sup_bank(l_sup_bank_idx).branch_name        :=l_sup_bank_type.branch_name;
      l_sup_bank(l_sup_bank_idx).vendor_id          :=l_sup_bank_type.supp_id;
      l_sup_bank(l_sup_bank_idx).vendor_site_id     :=l_sup_bank_type.supp_site_id;
      l_sup_bank(l_sup_bank_idx).bank_account_num   :=l_sup_bank_type.bank_account_num;
      l_sup_bank(l_sup_bank_idx).instrument_uses_id :=l_instrument_id;
      l_sup_bank(l_sup_bank_idx).bank_id            :=l_sup_bank_id;
      l_sup_bank(l_sup_bank_idx).branch_id          :=l_sup_bank_branch_id;
      l_sup_bank(l_sup_bank_idx).account_id         :=l_bank_account_id;
    END IF;
    IF gc_error_site_status_flag                      = 'Y' THEN
      l_sup_bank(l_sup_bank_idx).bnkact_process_flag := gn_process_status_error;
      l_sup_bank(l_sup_bank_idx).ERROR_FLAG          := gc_process_error_flag;
      l_sup_bank(l_sup_bank_idx).ERROR_MSG           := gc_error_msg;
    ELSE
      l_sup_bank(l_sup_bank_idx).bnkact_process_flag := gn_process_status_validated;
      print_debug_msg(p_message=> 'Process Flag ' ||gn_process_status_validated, p_force=> false);
      print_debug_msg(p_message=> 'Bank Status Flag : '|| l_sup_bank(l_sup_bank_idx).bnkact_process_flag,p_force=> false);
    END IF;
  END LOOP;
  print_debug_msg(p_message=> 'Do Bulk Update for all BANK Records ' ,p_force=> false);
  print_debug_msg(p_message=> 'l_sup_bank.COUNT : '|| l_sup_bank.count ,p_force=> false);
  IF l_sup_bank.count > 0 THEN
    BEGIN
      FORALL l_idxs IN l_sup_bank.FIRST .. l_sup_bank.LAST
      UPDATE xx_ap_cld_supp_bnkact_stg
      SET bnkact_process_flag          = l_sup_bank(l_idxs).bnkact_process_flag ,
        error_flag                     = l_sup_bank(l_idxs).error_flag ,
        error_msg                      = l_sup_bank(l_idxs).error_msg,
        create_flag                    =l_sup_bank(l_idxs).create_flag,
        last_updated_by                =g_user_id,
        last_update_date               =SYSDATE,
        vendor_id                      =l_sup_bank(l_idxs).vendor_id,
        vendor_site_id                 =l_sup_bank(l_idxs).vendor_site_id,
        instrument_uses_id             =l_sup_bank(l_idxs).instrument_uses_id,
        bank_id                        =l_sup_bank(l_idxs).bank_id,
        branch_id                      =l_sup_bank(l_idxs).branch_id,
        account_id                     =l_sup_bank(l_idxs).account_id ,
        start_date                     =l_sup_bank(l_idxs).start_date
      WHERE 1                          =1
      AND TRIM(UPPER(vendor_site_code))=TRIM(UPPER(l_sup_bank(l_idxs).vendor_site_code))
      AND UPPER(supplier_num)          =UPPER(l_sup_bank(l_idxs).supplier_num)
      AND UPPER(bank_name)             =UPPER(l_sup_bank(l_idxs).bank_name)
      AND UPPER(BRANCH_NAME)           =UPPER(l_sup_bank(l_idxs).branch_name)
      AND bank_account_num             =l_sup_bank(l_idxs).bank_account_num
      AND request_id                   =gn_request_id;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of Bank staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      insert_error (p_program_step => 'SITE_BANK' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of bank staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_bank_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> false);
    END;
  END IF;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_bank_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_bank_records;
--+============================================================================+
--| Name          : load_Supplier_Interface                                        |
--| Description   : This procedure will load the vendors into interface table  |
--|                   for the validated records in staging table               |
--|                                                                            |
--| Parameters    : N/A                                                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE load_supplier_interface( x_ret_code OUT NUMBER ,
								   x_return_status OUT VARCHAR2 ,
								   x_err_buf OUT VARCHAR2 
								 )
IS
  --=========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for processing
  --=========================================================================================
TYPE l_sup_tab
IS
  TABLE OF XX_AP_CLD_SUPPLIERS_STG%rowtype INDEX BY binary_integer;
  --=================================================================
  -- Declaring Local variables
  --=================================================================
  l_supplier_type l_sup_tab;
  l_vendor_intf_id                       NUMBER DEFAULT 0;
  l_error_message                        VARCHAR2 (2000) DEFAULT NULL;
  l_procedure                            VARCHAR2 (30) := 'load_Supplier_Interface';
  l_sup_processed_recs                   NUMBER        := 0;
  l_sup_unprocessed_recs                 NUMBER        := 0;
  l_ret_code                             NUMBER;
  l_return_status                        VARCHAR2 (100);
  l_err_buff                             VARCHAR2 (4000);
  l_sup_val_load_cnt                     NUMBER := 0;
  l_user_id                              NUMBER := fnd_global.user_id;
  l_resp_id                              NUMBER := fnd_global.resp_id;
  l_resp_appl_id                         NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id                          NUMBER;
  l_phas_out                             VARCHAR2 (60);
  l_status_out                           VARCHAR2 (60);
  l_dev_phase_out                        VARCHAR2 (60);
  l_dev_status_out                       VARCHAR2 (60);
  l_message_out                          VARCHAR2 (200);
  l_bflag                                BOOLEAN;
  lc_inspection_required_flag	         VARCHAR2(200);
  lc_receipt_required_flag	             VARCHAR2(200);
  ln_qty_rcv_tolerance	                 NUMBER;
  lc_qty_rcv_exception_code	             VARCHAR2(200);
  lc_enforce_ship_to_loc_code	         VARCHAR2(200);
  ln_days_early_receipt_allowed	         NUMBER;
  ln_days_late_receipt_allowed	         NUMBER;
  lc_receipt_days_exception_code	     VARCHAR2(200);
  ln_receiving_routing_id	             NUMBER;
  lc_allow_substitute_rcpts_flag	     VARCHAR2(200);
  lc_allow_unordered_rcpts_flag	         VARCHAR2(200);
  --==============================================================================
  -- Cursor Declarations for Suppliers
  --==============================================================================
  CURSOR c_supplier
  IS
    SELECT xas.*
    FROM xx_ap_cld_suppliers_stg xas
    WHERE xas.supp_process_flag = gn_process_status_validated
    AND xas.request_id          = gn_request_id
    AND xas.create_flag         = 'Y';

	l_process_status_flag VARCHAR2(1);
	
  CURSOR c_error
  IS
  SELECT a.rowid drowid,
         c.reject_lookup_code
    FROM ap_supplier_int_rejections c,
         ap_suppliers_int b,
         xx_ap_cld_suppliers_stg a 
   WHERE a.request_id=gn_request_id
     AND a.supp_process_flag=gn_process_status_validated
     AND a.create_flag='Y'
     AND b.vendor_interface_id=a.vendor_interface_id
	 AND b.status='REJECTED'
     AND c.parent_id=b.vendor_interface_id
     AND c.parent_table='AP_SUPPLIERS_INT';
  
BEGIN
  print_debug_msg(p_message=> gc_step||' load_Supplier_Interface() - BEGIN' ,p_force=> false);
  --==============================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==============================================================================
  l_process_status_flag := 'N';
  l_error_message       := NULL;
  l_ret_code            := 0;
  l_return_status       := 'S';
  l_err_buff            := NULL;
  OPEN c_supplier;
  LOOP
    FETCH c_supplier bulk collect INTO l_supplier_type;
    IF l_supplier_type.count > 0 THEN
      print_debug_msg(p_message=> gc_step||' l_supplier_type records processing.' ,p_force=> false);
      FOR l_idx IN l_supplier_type.first .. l_supplier_type.last
      LOOP
	    lc_inspection_required_flag	     := NULL;    
        lc_receipt_required_flag	     := NULL;     
        ln_qty_rcv_tolerance	         := NULL;         
        lc_qty_rcv_exception_code	     := NULL;     
        lc_enforce_ship_to_loc_code      := NULL;	
        ln_days_early_receipt_allowed	 := NULL;   
        ln_days_late_receipt_allowed	 := NULL;  
        lc_receipt_days_exception_code	 := NULL;
        ln_receiving_routing_id	         := NULL; 
        lc_allow_substitute_rcpts_flag	 := NULL;
        lc_allow_unordered_rcpts_flag	 := NULL;
        --==============================================================================
        -- Initialize the Variable to N for Each Supplier
        --==============================================================================
        l_process_status_flag := 'N';
        l_error_message       := NULL;
        gc_step               := 'SUPINTF';
        print_debug_msg(p_message=> gc_step||' Create Flag of the supplier '||l_supplier_type (l_idx).supplier_name||' is - '||l_supplier_type (l_idx).create_flag ,p_force=> false);
        IF l_supplier_type (l_idx).create_flag = 'Y' THEN
          --==============================================================================================
          -- Calling the Vendor Interface Id for Passing it to Interface Table - Supplier Does Not Exists
          --==============================================================================================
          SELECT ap_suppliers_int_s.nextval
          INTO l_vendor_intf_id
          FROM dual;
		  /* Added as per Version 2.1 by Havish Kasina */
		  --==============================================================================
		  -- To get the Receiving details from the Supplier Sites Staging table
		  --==============================================================================
		  print_debug_msg(p_message=> 'Fetching the Receiving Information for the Supplier ' ||l_supplier_type (l_idx).segment1 , p_force=>true);

		  get_receiving_details(p_supplier_num                 => l_supplier_type (l_idx).segment1 ,
                                o_inspection_required_flag     => lc_inspection_required_flag	   , 
								o_receipt_required_flag        => lc_receipt_required_flag	       ,     
								o_qty_rcv_tolerance            => ln_qty_rcv_tolerance	           ,         
								o_qty_rcv_exception_code       => lc_qty_rcv_exception_code	       ,     
								o_enforce_ship_to_loc_code     => lc_enforce_ship_to_loc_code      ,	 
								o_days_early_receipt_allowed   => ln_days_early_receipt_allowed	   ,
								o_days_late_receipt_allowed    => ln_days_late_receipt_allowed	   , 
								o_receipt_days_exception_code  => lc_receipt_days_exception_code   ,
								o_receiving_routing_id         => ln_receiving_routing_id          ,	     
								o_allow_substitute_rcpts_flag  => lc_allow_substitute_rcpts_flag   ,
								o_allow_unordered_rcpts_flag   => lc_allow_unordered_rcpts_flag	 
                               );
							   
		  UPDATE xx_ap_cld_suppliers_stg
             SET inspection_required_flag       =  lc_inspection_required_flag,	     
                 receipt_required_flag          =  lc_receipt_required_flag,	         
                 qty_rcv_tolerance              =  ln_qty_rcv_tolerance,	             
                 qty_rcv_exception_code         =  lc_qty_rcv_exception_code,     
                 enforce_ship_to_location_code  =  lc_enforce_ship_to_loc_code, 
                 days_early_receipt_allowed     =  ln_days_early_receipt_allowed, 
                 days_late_receipt_allowed      =  ln_days_late_receipt_allowed,	     
                 receipt_days_exception_code    =  lc_receipt_days_exception_code,	 
                 receiving_routing_id           =  ln_receiving_routing_id,	         
                 allow_substitute_receipts_flag =  lc_allow_substitute_rcpts_flag,
                 allow_unordered_receipts_flag  =  lc_allow_unordered_rcpts_flag,	       		 
                 last_updated_by     = g_user_id,
                 last_update_date    = SYSDATE
           WHERE 1 = 1
             AND segment1          = l_supplier_type (l_idx).segment1
             AND request_id        = gn_request_id;
			 
		  print_debug_msg(p_message=>'Successfully loaded the Receiving Information into xx_ap_cld_suppliers_stg staging table', p_force=>true);

		  /* End of Changes Added for Version 2.1 by Havish Kasina */
          --==============================================================================
          -- Calling the Insertion of Data into standard interface table
          --==============================================================================
          IF l_process_status_flag = 'N' THEN
            print_debug_msg(p_message=> gc_step||' - Before inserting record into ap_suppliers_int with interface id -'||l_vendor_intf_id ,p_force=> false);
            BEGIN
              INSERT
              INTO ap_suppliers_int
                (
                  vendor_interface_id ,
                  status ,
                  vendor_name ,
                  segment1 ,
                  vendor_type_lookup_code ,
                  one_time_flag ,
                  min_order_amount ,
                  customer_num ,
                  standard_industry_class ,
                  num_1099 ,
                  federal_reportable_flag ,
                  type_1099 ,
                  state_reportable_flag ,
                  tax_reporting_name ,
                  name_control ,
                  tax_verification_date ,
                  allow_awt_flag ,
                  auto_tax_calc_override ,
                  vat_code ,
                  vat_registration_num ,
                  attribute_category ,
                  attribute3 ,
                  attribute2 ,
                  attribute4 ,
                  attribute5 ,
                  attribute6 ,
                  attribute7 ,
                  attribute8 ,
                  attribute9 ,
                  attribute10 ,
                  attribute11 ,
                  attribute12 ,
                  attribute13 ,
                  attribute14 ,
                  attribute15 ,
                  start_date_active ,
                  created_by ,
                  creation_date ,
                  last_update_date ,
                  last_updated_by,
                  organization_type_lookup_code,  
				  inspection_required_flag,           -- Added as per Version 2.1 by Havish Kasina
				  receipt_required_flag ,             -- Added as per Version 2.1 by Havish Kasina
				  qty_rcv_tolerance,                  -- Added as per Version 2.1 by Havish Kasina
				  qty_rcv_exception_code ,            -- Added as per Version 2.1 by Havish Kasina
				  enforce_ship_to_location_code ,     -- Added as per Version 2.1 by Havish Kasina
				  days_early_receipt_allowed ,        -- Added as per Version 2.1 by Havish Kasina
				  days_late_receipt_allowed ,         -- Added as per Version 2.1 by Havish Kasina
				  receipt_days_exception_code ,       -- Added as per Version 2.1 by Havish Kasina
				  receiving_routing_id ,              -- Added as per Version 2.1 by Havish Kasina
				  allow_substitute_receipts_flag,     -- Added as per Version 2.1 by Havish Kasina
				  allow_unordered_receipts_flag       -- Added as per Version 2.1 by Havish Kasina
                )
                VALUES
                (
                  l_vendor_intf_id ,
                  g_process_status_new ,
                  l_supplier_type (l_idx).supplier_name ,
                  l_supplier_type (l_idx).segment1 ,
                  l_supplier_type (l_idx).vendor_type_lookup_code ,
                  l_supplier_type (l_idx).one_time_flag ,
                  l_supplier_type (l_idx).min_order_amount ,
                  l_supplier_type (l_idx).customer_num ,
                  l_supplier_type (l_idx).standard_industry_class ,
                  l_supplier_type (l_idx).num_1099,
                  l_supplier_type (l_idx).federal_reportable_flag ,
                  l_supplier_type (l_idx).type_1099 ,
                  l_supplier_type (l_idx).state_reportable_flag ,
                  l_supplier_type (l_idx).tax_reporting_name ,
                  l_supplier_type (l_idx).name_control ,
                  TO_DATE(l_supplier_type (l_idx).tax_verification_date,'YYYY/MM/DD'),
                  l_supplier_type (l_idx).allow_awt_flag ,
                  l_supplier_type (l_idx).auto_tax_calc_override ,
                  l_supplier_type (l_idx).vat_code ,
                  l_supplier_type (l_idx).vat_registration_num ,
                  l_supplier_type (l_idx).attribute_category ,
                  l_supplier_type (l_idx).attribute3 ,
                  l_supplier_type (l_idx).attribute2 ,
                  l_supplier_type (l_idx).attribute4 ,
                  l_supplier_type (l_idx).attribute5 ,
                  l_supplier_type (l_idx).attribute6 ,
                  l_supplier_type (l_idx).attribute7 ,
                  l_supplier_type (l_idx).attribute8 ,
                  l_supplier_type (l_idx).attribute9 ,
                  l_supplier_type (l_idx).attribute10 ,
                  l_supplier_type (l_idx).attribute11 ,
                  l_supplier_type (l_idx).attribute12 ,
                  l_supplier_type (l_idx).attribute13 ,
                  l_supplier_type (l_idx).attribute14 ,
                  l_supplier_type (l_idx).attribute15 ,
                  SYSDATE ,
                  g_user_id ,
                  SYSDATE ,
                  SYSDATE ,
                  g_user_id,
                  l_supplier_type (l_idx).organization_type,
				  lc_inspection_required_flag,	   --Added as per Version 2.1 by Havish Kasina
				  lc_receipt_required_flag,	       --Added as per Version 2.1 by Havish Kasina
				  ln_qty_rcv_tolerance,	           --Added as per Version 2.1 by Havish Kasina
				  lc_qty_rcv_exception_code,       --Added as per Version 2.1 by Havish Kasina
				  lc_enforce_ship_to_loc_code,     --Added as per Version 2.1 by Havish Kasina
				  ln_days_early_receipt_allowed,   --Added as per Version 2.1 by Havish Kasina
				  ln_days_late_receipt_allowed,	   --Added as per Version 2.1 by Havish Kasina
				  lc_receipt_days_exception_code,  --Added as per Version 2.1 by Havish Kasina
				  ln_receiving_routing_id,	       --Added as per Version 2.1 by Havish Kasina
				  lc_allow_substitute_rcpts_flag,  --Added as per Version 2.1 by Havish Kasina
				  lc_allow_unordered_rcpts_flag	   --Added as per Version 2.1 by Havish Kasina
                );
              print_debug_msg(p_message=> 'After successfully inserted the record for the supplier -'||l_supplier_type (l_idx).supplier_name ,p_force=> false);
            EXCEPTION
            WHEN OTHERS THEN
              l_process_status_flag := 'Y';
              l_error_message       := SQLCODE || ' - '|| sqlerrm;
              print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_type (l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message ,p_force=> true);
              insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_idx).supplier_name ,p_error_code => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,2000) ,p_error_message => 'Error while Inserting Records in Inteface Table'|| SQLCODE || ' - '||l_error_message ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_supplier_type (l_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
            END;
            IF l_process_status_flag                       = 'N' THEN
              l_supplier_type (l_idx).supp_process_flag   := gn_process_status_loaded;
              l_sup_processed_recs                        := l_sup_processed_recs + 1;
              l_supplier_type (l_idx).vendor_interface_id :=l_vendor_intf_id;---added
              set_step ('Sup Stg Status P');
            ELSIF l_process_status_flag                  = 'Y' THEN
              l_supplier_type (l_idx).supp_process_flag := gn_process_status_error;
              l_supplier_type (l_idx).ERROR_FLAG        := gc_process_error_flag;
              l_supplier_type (l_idx).ERROR_MSG         := gc_error_msg;
              l_sup_unprocessed_recs                    := l_sup_unprocessed_recs + 1;
              set_step ('Sup Stg Status E');
            END IF;
          END IF; -- l_process_status_flag := 'N'
        END IF;   -- IF l_supplier_type (l_idx).create_flag = 'Y'
      END LOOP;   -- l_supplier_type.FIRST .. l_supplier_type.LAST
    END IF;       -- l_supplier_type.COUNT > 0
    --==============================================================================
    -- For Doing the Bulk Update
    --=============================================================================
    IF l_supplier_type.COUNT > 0 THEN
      set_step ('Supplier Staging Count');
      BEGIN
        FORALL l_idxs IN l_supplier_type.FIRST .. l_supplier_type.LAST
        UPDATE xx_ap_cld_suppliers_stg
        SET supp_process_flag = l_supplier_type (l_idxs).supp_process_flag,
          last_updated_by     =g_user_id,
          last_update_date    =SYSDATE,
          process_flag        ='Y',
          vendor_interface_id =l_supplier_type (l_idxs).vendor_interface_id
        WHERE supplier_name   = l_supplier_type (l_idxs).supplier_name
        AND segment1          =l_supplier_type (l_idxs).segment1
        AND request_id        = gn_request_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_process_status_flag := 'Y';
        l_error_message       := 'When Others Exception ' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3850 );
      END;
    END IF; -- l_supplier_type.COUNT For Bulk Update of Supplier
    EXIT
  WHEN c_supplier%notfound;
  END LOOP; -- For Open c_supplier
  CLOSE c_supplier;
  l_supplier_type.DELETE;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;

  SELECT COUNT(1)
    INTO l_sup_val_load_cnt
    FROM xx_ap_cld_suppliers_stg
   WHERE request_id     = gn_request_id
     AND create_flag      = 'Y'
     AND supp_process_flag=5;
  print_out_msg(p_message => 'Before starting import program total Supplier eligible count '|| l_sup_val_load_cnt);
  
  IF l_sup_val_load_cnt >0 THEN
     print_out_msg(p_message => '-------------------Starting Supplier Import Program-------------------------------------------------------------------------');
     fnd_global.apps_initialize ( user_id => l_user_id ,resp_id => l_resp_id ,resp_appl_id => l_resp_appl_id );
     l_rept_req_id := fnd_request.submit_request(application => 'SQLAP' , 
												 program => 'APXSUIMP' , 
												 description => '' , 
												 start_time => SYSDATE , 
												 sub_request => false , 
												 argument1 => 'NEW' , 
												 argument2 => 1000 , 
												 argument3 => 'N' , 
												 argument4 => 'N' , 
												 argument5 => 'N' 
												);
     COMMIT;
     IF l_rept_req_id != 0 THEN
        print_debug_msg(p_message => 'Standard Supplier Import is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
        l_dev_phase_out := 'Start';
        l_bflag         :=fnd_concurrent.wait_for_request(l_rept_req_id,5,0,l_phas_out,
														  l_status_out , l_dev_phase_out,l_dev_status_out,
														  l_message_out 
														 );
        BEGIN
          UPDATE xx_ap_cld_suppliers_stg stg
             SET supp_process_flag = gn_process_status_imported,
                 process_flag        ='Y'
           WHERE 1               =1
             AND EXISTS ( SELECT 1
						    FROM ap_suppliers_int aint
 						   WHERE aint.vendor_name      = stg.supplier_name
						     AND aint.segment1           =stg.segment1
						     AND aint.vendor_interface_id=stg.vendor_interface_id
						     AND aint.status             ='PROCESSED'
						)
             AND request_id = gn_request_id;
          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            print_debug_msg(p_message => ' Error in update after import', p_force => true);
        END ;
        BEGIN
          UPDATE XX_AP_CLD_SUPPLIERS_STG stg
             SET supp_process_flag = gn_process_status_imp_fail,
                 process_flag        ='Y',
                 error_flag          ='E',
                 error_msg           =error_msg||',Import Error'
           WHERE request_id = gn_request_id
             AND EXISTS ( SELECT 1
							FROM ap_suppliers_int aint
					       WHERE aint.vendor_name      = stg.supplier_name
						     AND aint.segment1           =STG.SEGMENT1
							 AND aint.vendor_interface_id=stg.vendor_interface_id
							 AND aint.status             = 'REJECTED'
						)
             AND request_id = gn_request_id;
          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            print_debug_msg(p_message => ' Error in update after import', p_force => true);
        END ;
        UPDATE xx_ap_cld_suppliers_stg a
           SET (vendor_id,party_id)=(SELECT vendor_id,party_id 
									   FROM ap_suppliers 
									  WHERE segment1=a.segment1
									)
         WHERE request_id=gn_request_id
           AND create_flag ='Y';
        COMMIT;
		FOR cur IN c_error LOOP
          UPDATE XX_AP_CLD_SUPPLIERS_STG stg
             SET supp_process_flag = gn_process_status_imp_fail,
                 process_flag        ='Y',
                 error_flag          ='E',
                 error_msg           =error_msg||','||cur.reject_lookup_code
           WHERE rowid=cur.drowid;		
		END LOOP;
		COMMIT;
     END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    gc_error_status_flag := 'Y';
    l_error_message      := gc_step||'EXCEPTION: (' || g_package_name || '.' || l_procedure || '-' || gc_step || ') ' || sqlerrm;
    print_debug_msg(p_message=> l_error_message ,p_force=> true);
    x_ret_code      := 1;
    x_return_status := 'E';
    x_err_buf       := l_error_message;
END load_supplier_interface;
--+============================================================================+
--| Name          : load_Supplier_Site_Interface                                        |
--| Description   : This procedure will load the vendors Sitee into interface table  |
--|                   for the validated records in staging table               |
--|                                                                            |
--| Parameters    : N/A                                                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE load_supplier_site_interface(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2 )
IS
  --=========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for processing
  --=========================================================================================
TYPE l_sup_site_add_tab
IS
  TABLE OF XX_AP_CLD_SUPP_SITES_STG%rowtype INDEX BY binary_integer;
  --=================================================================
  -- Declaring Local variables
  --=================================================================
  l_sup_site_type l_sup_site_add_tab;
  l_vendor_site_intf_id      NUMBER DEFAULT 0;
  l_error_message            VARCHAR2 (2000) DEFAULT NULL;
  l_procedure                VARCHAR2 (30) := 'load_Supplier_Site_Interface';
  l_supsite_processed_recs   NUMBER        := 0;
  l_supsite_unprocessed_recs NUMBER        := 0;
  l_ret_code                 NUMBER;
  l_return_status            VARCHAR2 (100);
  l_err_buff                 VARCHAR2 (4000);
  l_supsite_val_load_cnt     NUMBER := 0;
  l_user_id                  NUMBER := fnd_global.user_id;
  l_resp_id                  NUMBER := fnd_global.resp_id;
  l_resp_appl_id             NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id              NUMBER;
  l_phas_out                 VARCHAR2 (60);
  l_status_out               VARCHAR2 (60);
  l_dev_phase_out            VARCHAR2 (60);
  l_dev_status_out           VARCHAR2 (60);
  l_message_out              VARCHAR2 (200);
  l_bflag                    BOOLEAN;
  --==============================================================================
  -- Cursor Declarations for Supplier Sites
  --==============================================================================
  CURSOR c_supplier_site
  IS
    SELECT xsup_site.*
      FROM xx_ap_cld_supp_sites_stg xsup_site
     WHERE xsup_site.site_process_flag = gn_process_status_validated
       AND xsup_site.request_id          = gn_request_id
       AND create_flag                   ='Y';

  CURSOR c_error
  IS
  SELECT a.rowid drowid,
         c.reject_lookup_code
    FROM ap_supplier_int_rejections c,
         ap_supplier_sites_int b,
         xx_ap_cld_supp_sites_stg a 
   WHERE a.request_id=gn_request_id
     AND a.site_process_flag = gn_process_status_validated
     AND a.create_flag='Y'
     AND b.vendor_site_interface_id=a.vendor_site_interface_id
	 AND b.status='REJECTED'
     AND c.parent_id=b.vendor_site_interface_id
     AND c.parent_table='AP_SUPPLIER_SITES_INT';
	
  l_process_site_error_flag VARCHAR2(1) DEFAULT 'N';
  l_vendor_id               NUMBER;
  l_vendor_site_id          NUMBER;
  l_party_site_id           NUMBER;
  l_party_id                NUMBER;
  l_vendor_site_code        VARCHAR2(50);
  v_acct_pay                NUMBER;
  v_prepay_cde              NUMBER;
BEGIN
  print_debug_msg(p_message=> gc_step||' load_Supplier_Site_Interface() - BEGIN' ,p_force=> false);
  --==============================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==============================================================================
  l_process_site_error_flag := 'N';
  l_error_message           := NULL;
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  --==============================================================================
  -- Calling the Vendor Site Cursor for inserting into standard interface table
  --==============================================================================
  OPEN c_supplier_site;
  LOOP
    FETCH c_supplier_site bulk collect INTO l_sup_site_type;
    IF l_sup_site_type.count > 0 THEN
      print_debug_msg(p_message=> gc_step||' l_supplier_type records processing.' ,p_force=> false);
      FOR l_idx IN l_sup_site_type.first .. l_sup_site_type.last
      LOOP
        l_process_site_error_flag  := 'N';
        l_vendor_site_code         := '';
        IF l_process_site_error_flag='N' THEN
          --==============================================================================
          -- Calling the Vendor Site Interface Id for Passing it to Interface Table
          --==============================================================================
          SELECT ap_supplier_sites_int_s.nextval
          INTO l_vendor_site_intf_id
          FROM sys.dual;
          v_acct_pay  :=get_cld_to_ebs_map(l_sup_site_type(l_idx).accts_pay_concat_gl_segments);
          v_prepay_cde:=get_cld_to_ebs_map(l_sup_site_type(l_idx). PREPAY_CODE_GL_SEGMENTS);
          BEGIN
            INSERT
            INTO ap_supplier_sites_int
              (
                vendor_id ,
                vendor_site_interface_id ,
                vendor_site_code ,
                address_line1 ,
                address_line2 ,
                address_line4 ,
                city ,
                state ,
                zip ,
                country ,
                province ,
                phone ,
                fax ,
                fax_area_code ,
                area_code ,
                tax_reporting_site_flag ,
                terms_id ,
                invoice_currency_code ,
                payment_currency_code ,
                accts_pay_code_combination_id ,
                prepay_code_combination_id,
                terms_date_basis ,
                purchasing_site_flag ,
                pay_site_flag ,
                org_id ,
                status ,
                freight_terms_lookup_code ,
                fob_lookup_code ,
                pay_group_lookup_code ,
                payment_priority ,
                pay_date_basis_lookup_code ,
                always_take_disc_flag ,
                hold_all_payments_flag ,
                match_option ,
                email_address ,
                primary_pay_site_flag ,
                tolerance_name,
                services_tolerance_name,
                bill_to_location_code ,
                ship_to_location_code ,
                created_by ,
                creation_date ,
                last_update_date ,
                last_updated_by ,
                payment_method_lookup_code,
                attribute_category ,
                attribute1,
                attribute2,
                attribute3 ,
                attribute4 ,
                attribute5 ,
                attribute6 ,
                ATTRIBUTE7 ,
                attribute8 ,
                attribute9 ,
                attribute10 ,
                attribute11 ,
                attribute12 ,
                ATTRIBUTE13 ,
                attribute14 ,
                attribute15,
                vendor_site_code_alt,
				duns_number -- Added as per Version 1.9
              )
              VALUES
              (
                l_sup_site_type(l_idx).vendor_id,      ---l_supplier_type (l_idx).vendor_id ,
                l_vendor_site_intf_id ,                 --l_vendor_site_intf_id
                l_sup_site_type(l_idx).vendor_site_code,--address_line1 ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).address_line1))) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).address_line2))) ,
                l_sup_site_type(l_idx).vendor_site_code,-- TO_CHAR(l_sup_site_type(l_idx).site_number) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).city))) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).state))) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).postal_code))) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).country))) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).province))) ,
                trim(l_sup_site_type(l_idx).phone_number) ,
                trim(l_sup_site_type(l_idx).fax) ,
                l_sup_site_type(l_idx).fax_area_code ,
                l_sup_site_type(l_idx).phone_area_code ,
                l_sup_site_type(l_idx).tax_reporting_site_flag,--income_tax_rep_site
                l_sup_site_type(l_idx).terms_id,
                l_sup_site_type(l_idx).invoice_currency_code, --invoice_currency ,
                l_sup_site_type(l_idx).payment_currency_code, --,payment_currency ,
                v_acct_pay,
                v_prepay_cde,
                l_sup_site_type(l_idx).terms_date_basis,--terms_date_basis_code ,
                l_sup_site_type(l_idx).purchasing_site_flag ,
                l_sup_site_type(l_idx).pay_site_flag ,
                TO_NUMBER(l_sup_site_type(l_idx).org_id),
                g_process_status_new,
                l_sup_site_type(l_idx).freight_terms_lookup_code,--freight_terms ,
                l_sup_site_type(l_idx).fob_lookup_code,          --fob ,
                l_sup_site_type(l_idx).pay_group_lookup_code,    --pay_group_code ,
                TO_NUMBER(l_sup_site_type(l_idx).payment_priority),
                l_sup_site_type(l_idx).pay_date_basis_lookup_code ,
                l_sup_site_type(l_idx).always_take_disc_flag ,
                l_sup_site_type(l_idx).hold_all_payments_flag,--hold_from_payment
                l_sup_site_type(l_idx).match_option,          --invoice_match_option ,
                l_sup_site_type(l_idx).email_address ,
                l_sup_site_type(l_idx).primary_pay_site_flag--primary_pay_flag
                ,
                l_sup_site_type(l_idx).tolerance_name,
                l_sup_site_type(l_idx).service_tolerance,
                UPPER(l_sup_site_type(l_idx).bill_to_location),
                UPPER(l_sup_site_type(l_idx).ship_to_location),
                g_user_id ,
                sysdate ,
                sysdate ,
                g_user_id ,
                l_sup_site_type(l_idx).payment_method_lookup_code,
                l_sup_site_type(l_idx).attribute_category ,
                l_sup_site_type(l_idx).attribute1,
                l_sup_site_type(l_idx).attribute2,
                l_sup_site_type(l_idx).attribute3 ,
                l_sup_site_type(l_idx).attribute4 ,
                l_sup_site_type(l_idx).attribute5 ,
                l_sup_site_type(l_idx).attribute6 ,
                l_sup_site_type(l_idx).ATTRIBUTE7 ,
                l_sup_site_type(l_idx).attribute8 ,
                l_sup_site_type(l_idx).attribute9 ,
                NULL ,
                NULL ,
                NULL ,
                l_sup_site_type(l_idx).ATTRIBUTE13 ,
                l_sup_site_type(l_idx).attribute14 ,
                L_SUP_SITE_TYPE(L_IDX).ATTRIBUTE15,
                l_sup_site_type(l_idx).vendor_site_code_alt,
                l_sup_site_type(l_idx).attribute5  -- Added as per Version 1.9
              );
          EXCEPTION
          WHEN OTHERS THEN
            l_process_site_error_flag := 'Y';
            l_error_message           := SQLCODE || ' - '|| sqlerrm;
            print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:' ||l_sup_site_type(l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '|| l_error_message ,p_force=> true);
            insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type(l_idx).supplier_name ,p_error_code => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,2000) , p_error_message => 'Error while Inserting Records in Site Inteface Table'|| SQLCODE || ' - '||l_error_message ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_sup_site_type(l_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
          END;
          set_step ( 'Supplier Site Interface Before Assigning' ||'-' || l_process_site_error_flag);
          set_step ('Supplier Site Interface After Assigning ' ||l_process_site_error_flag);
          IF l_process_site_error_flag                 = 'N' THEN
            l_sup_site_type (l_idx).site_process_flag := gn_process_status_loaded;
            print_debug_msg(p_message=> gc_step||' l_sup_site (lp_loopcnt).stg_PROCESS_FLAG' ||l_sup_site_type (l_idx).site_process_flag ,p_force=> true);
            l_supsite_processed_recs                        := l_supsite_processed_recs + 1;
            l_sup_site_type (l_idx).vendor_site_interface_id:=l_vendor_site_intf_id;
          ELSIF l_process_site_error_flag                    = 'Y' THEN
            l_sup_site_type (l_idx).site_process_flag       := gn_process_status_error;
            l_sup_site_type (l_idx).ERROR_FLAG              := gc_process_error_flag;
            l_sup_site_type (l_idx).ERROR_MSG               := gc_error_msg;
            l_supsite_unprocessed_recs                      := l_supsite_unprocessed_recs + 1;
          END IF;
        END IF;---Error Flag=N
      END LOOP;
    END IF;
    --==============================================================================
    -- For Doing the Bulk Update
    --=============================================================================
    IF l_sup_site_type.count > 0 THEN
      BEGIN
        FORALL l_idxss IN l_sup_site_type.FIRST .. l_sup_site_type.LAST
        UPDATE XX_AP_CLD_SUPP_SITES_STG
        SET site_process_flag     = l_sup_site_type (l_idxss).site_process_flag,
          LAST_UPDATED_BY         =g_user_id,
          LAST_UPDATE_DATE        =sysdate,
          ERROR_MSG               =L_SUP_SITE_TYPE (L_IDXSS).ERROR_MSG,
          ERROR_FLAG              = L_SUP_SITE_TYPE (L_IDXSS).ERROR_FLAG,
          vendor_site_interface_id=l_sup_site_type (l_idxss).vendor_site_interface_id
        WHERE 1                   =1--supplier_name  = l_sup_site_type (l_idxss).supplier_name
        AND supplier_number       = l_sup_site_type (l_idxss).supplier_number
        AND vendor_site_code      = l_sup_site_type (l_idxss).vendor_site_code
        AND org_id                =l_sup_site_type (l_idxss).org_id
        AND REQUEST_ID            = gn_request_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_process_site_error_flag := 'Y';
        l_error_message           := 'When Others Exception ' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3850 );
      END;
      COMMIT;
    END IF; -- l_sup_site_type(l_idx).COUNT For Bulk Update of Sites
    EXIT
  WHEN c_supplier_site%notfound;
  END LOOP; -- For Open c_supplier
  CLOSE c_supplier_site;
  l_sup_site_type.DELETE;
  COMMIT;
  SELECT COUNT(1)
  INTO l_supsite_val_load_cnt
  FROM xx_ap_cld_supp_sites_stg
  WHERE request_id          = gn_request_id
  AND create_flag           ='Y'
  AND site_process_flag     =5;
  IF l_supsite_val_load_cnt >0 THEN
    print_out_msg(p_message => '-------------------Starting Supplier Site Import Program-------------------------------------------------------------------------');
    fnd_global.apps_initialize ( user_id => l_user_id ,resp_id => l_resp_id ,resp_appl_id => l_resp_appl_id );
    l_rept_req_id := fnd_request.submit_request (application => 'SQLAP' , 
	                                             program => 'APXSSIMP' , 
												 description => '' , 
												 start_time => SYSDATE , 
												 sub_request => FALSE , 
												 argument1 => '', 
												 argument2 => 'NEW' , 
												 argument3 => 1000 , 
												 argument4 => 'N' , 
												 argument5 => 'N', 
												 argument6 => 'N' );
    COMMIT;
    IF l_rept_req_id != 0 THEN
      print_debug_msg(p_message => 'Standard Supplier  Import APXSSIMP  is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
      L_BFLAG := fnd_concurrent.wait_for_request (l_rept_req_id ,5 ,0 ,l_phas_out ,l_status_out , l_dev_phase_out ,l_dev_status_out ,l_message_out );
      BEGIN
        UPDATE XX_AP_CLD_SUPP_SITES_STG stg
        SET site_process_flag = gn_process_status_imported,
          PROCESS_FLAG        ='Y',
          vendor_site_id      =
          (SELECT VENDOR_SITE_ID
          FROM AP_SUPPLIER_SITES_ALL B
          WHERE STG.VENDOR_ID     =B.VENDOR_ID
          AND STG.VENDOR_SITE_CODE=B.VENDOR_SITE_CODE
          AND B.ORG_ID            =STG.ORG_ID
          AND rownum             <=2
          )
        WHERE 1=1---REQUEST_ID = gn_request_id
        AND EXISTS
          (SELECT 1
          FROM ap_supplier_sites_int aint
          WHERE AINT.VENDOR_SITE_CODE      = STG.VENDOR_SITE_CODE
          AND AINT.VENDOR_ID               =STG.VENDOR_ID
          AND aint.org_id                  =stg.org_id
          AND aint.status                  ='PROCESSED'
          AND aint.vendor_site_interface_id=stg.vendor_site_interface_id
          )
        AND REQUEST_ID = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
	  FOR cur IN c_error LOOP
        UPDATE XX_AP_CLD_SUPP_SITES_STG stg
           SET site_process_flag = gn_process_status_imp_fail,
               process_flag        ='Y',
               error_flag          ='E',
               error_msg           =error_msg||','||cur.reject_lookup_code
	     WHERE rowid=cur.drowid;				   
	  END LOOP;
      COMMIT;	  
    END IF;
  END IF;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
EXCEPTION
WHEN OTHERS THEN
  gc_error_status_flag := 'Y';
  l_error_message      := gc_step||'EXCEPTION: (' || g_package_name || '.' || l_procedure || '-' || gc_step || ') ' || sqlerrm;
  print_debug_msg(p_message=> l_error_message ,p_force=> true);
  x_ret_code      := 1;
  x_return_status := 'E';
  x_err_buf       := l_error_message;
END load_supplier_site_interface;
--+============================================================================+
--| Name          : load_Supplier_cont_Interface                                        |
--| Description   : This procedure will load the vendors Sitee contact into interface table  |
--|                   for the validated records in staging table               |
--|                                                                            |
--| Parameters    : N/A                                                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE load_supplier_cont_interface(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2 )
IS
  --=========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for processing
  --=========================================================================================
TYPE l_sup_cont_tab
IS
  TABLE OF XX_AP_CLD_SUPP_CONTACT_STG%rowtype INDEX BY binary_integer;
  --=================================================================
  -- Declaring Local variables
  --=================================================================
  l_supplier_cont_type l_sup_cont_tab;
  l_error_message          VARCHAR2 (2000) DEFAULT NULL;
  l_procedure              VARCHAR2 (30) := 'load_Supplier_cont_Interface';
  l_sup_processed_recs     NUMBER        := 0;
  l_sup_unprocessed_recs   NUMBER        := 0;
  l_ret_code               NUMBER;
  l_return_status          VARCHAR2 (100);
  l_err_buff               VARCHAR2 (4000);
  l_user_id                NUMBER := fnd_global.user_id;
  l_resp_id                NUMBER := fnd_global.resp_id;
  l_resp_appl_id           NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id            NUMBER;
  l_phas_out               VARCHAR2 (60);
  l_status_out             VARCHAR2 (60);
  l_dev_phase_out          VARCHAR2 (60);
  l_dev_status_out         VARCHAR2 (60);
  l_message_out            VARCHAR2 (200);
  l_bflag                  BOOLEAN;
  l_vendor_contact_intf_id NUMBER;
  l_sup_val_load_cnt       NUMBER := 0;
  --==============================================================================
  -- Cursor Declarations for Suppliers
  --==============================================================================
  CURSOR c_supplier_contacts
  IS
    SELECT xas.*
    FROM xx_ap_cld_supp_contact_stg xas
    WHERE xas.contact_process_flag= gn_process_status_validated
    AND xas.request_id            = gn_request_id
    AND create_flag               ='Y'
    AND cont_target               ='EBS';
	
  CURSOR c_error 
  IS   
  SELECT a.rowid drowid,
         c.reject_lookup_code
    FROM ap_supplier_int_rejections c,
         ap_sup_site_contact_int b,
         xx_ap_cld_supp_contact_stg a 
   WHERE a.request_id=gn_request_id
     AND a.contact_process_flag = gn_process_status_validated
     AND a.create_flag='Y'
     AND b.vendor_contact_interface_id=a.vendor_contact_interface_id
	 AND b.status='REJECTED'
     AND c.parent_id=b.vendor_contact_interface_id
     AND c.parent_table='AP_SUPP_SITE_CONTACT_INT';
	
  l_sup_rec_exists          NUMBER (10) DEFAULT 0;
  l_cont_process_error_flag VARCHAR2(1);
  l_vendor_id               NUMBER;
  l_party_id                NUMBER;
  l_vendor_site_id          NUMBER;
  l_org_id                  NUMBER;
  l_party_site_id           NUMBER;
BEGIN
  print_debug_msg(p_message=> gc_step||' load_Supplier_cont_Interface() - BEGIN' ,p_force=> false);
  set_step ('Start of Process Records Using API');
  --==============================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==============================================================================
  l_cont_process_error_flag := 'N';
  l_sup_rec_exists          := 0;
  l_error_message           := NULL;
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  OPEN c_supplier_contacts;
  LOOP
    FETCH c_supplier_contacts bulk collect INTO l_supplier_cont_type;
    IF l_supplier_cont_type.count > 0 THEN
      FOR l_idx IN l_supplier_cont_type.first .. l_supplier_cont_type.last
      LOOP
        --==============================================================================
        -- Initialize the Variable to N for Each Supplier
        --==============================================================================
        l_cont_process_error_flag := 'N';
        l_error_message           := NULL;
        gc_step                   := 'SUPCONT';
        l_sup_rec_exists          := 0;
        l_vendor_id               := NULL;
        l_party_id                := NULL;
        print_debug_msg(p_message=> gc_step||' create flag of the supplier '||l_supplier_cont_type (l_idx).supplier_name||' is - '||l_supplier_cont_type (l_idx).create_flag ,p_force=> false);
        IF l_supplier_cont_type (l_idx).CREATE_FLAG = 'Y' THEN
          BEGIN
            SELECT vendor_id,
              vendor_site_id,
              org_id,
              party_site_id
            INTO l_vendor_id,
              l_vendor_site_id,
              l_org_id,
              l_party_site_id
            FROM ap_supplier_sites_all
            WHERE vendor_site_id= l_supplier_cont_type (l_idx).vendor_site_id;
          EXCEPTION
          WHEN OTHERS THEN
            l_cont_process_error_flag:='Y';
          END;
          SELECT ap_sup_site_contact_int_s.nextval
          INTO l_vendor_contact_intf_id
          FROM sys.dual;
          --==============================================================================
          -- Calling the Insertion of Data into standard interface table
          --==============================================================================
          IF l_cont_process_error_flag = 'N' THEN
            print_debug_msg(p_message=> gc_step||' - Before inserting record into AP_SUP_SITE_CONTACT_INT with vendor id -'|| l_vendor_id ,p_force=> false);
            BEGIN
              INSERT
              INTO ap_sup_site_contact_int
                (
                  vendor_id ,
                  vendor_site_id ,
                  vendor_contact_interface_id ,
                  party_site_id ,
                  org_id ,
                  status ,
                  first_name ,
                  last_name ,
                  contact_name_alt ,
                  email_address ,
                  area_code ,
                  phone ,
                  fax_area_code ,
                  fax,
                  created_by ,
                  creation_date ,
                  last_update_date ,
                  last_updated_by,
                  title
                )
                VALUES
                (
                  l_vendor_id ,
                  l_vendor_site_id ,
                  l_vendor_contact_intf_id,
                  l_party_site_id,-- l_supplier_cont_type (l_idx).party_site_id ,
                  l_org_id,      --- l_supplier_cont_type (l_idx).org_id ,
                  'NEW' ,
                  upper( l_supplier_cont_type (l_idx).first_name) ,
                  upper( l_supplier_cont_type (l_idx).last_name) ,
                  l_supplier_cont_type (l_idx).contact_name_alt ,
                  l_supplier_cont_type (l_idx).email_address ,
                  l_supplier_cont_type (l_idx).area_code,
                  -- ||TO_CHAR(xx_ap_suppliers_phone_extn_s.nextval) ,
                  l_supplier_cont_type (l_idx).phone ,
                  l_supplier_cont_type (l_idx).fax_area_code ,
                  l_supplier_cont_type (l_idx).fax,
                  g_user_id ,
                  sysdate ,
                  sysdate ,
                  g_user_id,
                  l_supplier_cont_type (l_idx).title
                );
              print_debug_msg(p_message=> 'After successfully inserted the record for the supplier -' ||l_supplier_cont_type (l_idx).supplier_name ,p_force=> false);
            EXCEPTION
            WHEN OTHERS THEN
              l_cont_process_error_flag := 'Y';
              l_error_message           := SQLCODE || ' - '|| sqlerrm;
              print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_cont_type (l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message ,p_force=> true);
              insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_cont_type (l_idx).supplier_name ,p_error_code => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,2000) ,p_error_message => 'Error while Inserting Records in Inteface Table'|| SQLCODE || ' - '||l_error_message ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_supplier_cont_type (l_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
            END;
            IF l_cont_process_error_flag                               = 'N' THEN
              l_supplier_cont_type (l_idx).contact_process_flag       := gn_process_status_loaded;
              l_sup_processed_recs                                    := l_sup_processed_recs + 1;
              l_supplier_cont_type (l_idx).vendor_contact_interface_id:=l_vendor_contact_intf_id;
            ELSIF l_cont_process_error_flag                            = 'Y' THEN
              l_supplier_cont_type (l_idx).contact_process_flag       := gn_process_status_error;
              l_supplier_cont_type (l_idx).ERROR_FLAG                 := gc_process_error_flag;
              l_supplier_cont_type (l_idx).ERROR_MSG                  := gc_error_msg;
              l_sup_unprocessed_recs                                  := l_sup_unprocessed_recs + 1;
            END IF;
          END IF; -- l_process_status_flag := 'N'
        END IF;   -- IF l_supplier_cont_type (l_idx).create_flag = 'Y'
      END LOOP;   -- l_supplier_cont_type.FIRST .. l_supplier_cont_type.LAST
    END IF;       -- l_supplier_cont_type.COUNT > 0
    --==============================================================================
    -- For Doing the Bulk Update
    --=============================================================================
    IF l_supplier_cont_type.count > 0 THEN
      BEGIN
        forall l_idxs IN l_supplier_cont_type.first .. l_supplier_cont_type.last
        UPDATE xx_ap_cld_supp_contact_stg
        SET contact_process_flag      = l_supplier_cont_type (l_idxs).contact_process_flag,
          last_updated_by             =g_user_id,
          last_update_date            =SYSDATE,
          error_msg                   = l_supplier_cont_type (l_idxs).error_msg,
          error_flag                  = l_supplier_cont_type (l_idxs).error_flag,
          vendor_contact_interface_id =l_supplier_cont_type (l_idxs).vendor_contact_interface_id
        WHERE 1                       =1
        AND vendor_site_code          = l_supplier_cont_type (l_idxs).vendor_site_code
        AND supplier_number           = l_supplier_cont_type (l_idxs).supplier_number
        AND first_name                = l_supplier_cont_type (l_idxs).first_name
        AND last_name                 = l_supplier_cont_type (l_idxs).last_name
        AND request_id                = gn_request_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_cont_process_error_flag := 'Y';
        l_error_message           := 'When Others Exception ' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3850 );
      END;
    END IF; -- l_supplier_cont_type.COUNT For Bulk Update of Supplier
    EXIT
  WHEN c_supplier_contacts%notfound;
  END LOOP; -- For Open c_supplier
  CLOSE c_supplier_contacts;
  l_supplier_cont_type.DELETE;
  SELECT COUNT(1)
  INTO l_sup_val_load_cnt
  FROM xx_ap_cld_supp_contact_stg
  WHERE request_id        = gn_request_id
  AND cont_target         ='EBS'
  AND create_flag         ='Y'
  AND contact_process_flag=5;
  IF l_sup_val_load_cnt   >0 THEN
    print_out_msg(p_message => '-------------------Starting Supplier Contact Import Program-------------------------------------------------------------------------');
    fnd_global.apps_initialize ( user_id => l_user_id ,resp_id => l_resp_id ,resp_appl_id => l_resp_appl_id );
    l_rept_req_id := fnd_request.submit_request (application => 'SQLAP' ,
	                                             program => 'APXSCIMP', 
												 description => '' , 
												 start_time => sysdate , 
												 sub_request => false ,
												 argument1 => 'NEW' , 
												 argument2 => 1000 ,
												 argument3 => 'N' , 
												 argument4 => 'N' ,
												 argument5 => 'N' );
    COMMIT;
    IF l_rept_req_id != 0 THEN
      print_debug_msg(p_message => 'Standard Supplier contact Import APXSCIMP  is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
      l_bflag := fnd_concurrent.wait_for_request (l_rept_req_id ,5 ,0 ,l_phas_out ,l_status_out , l_dev_phase_out ,l_dev_status_out ,l_message_out );
      BEGIN
        UPDATE xx_ap_cld_supp_contact_stg stg
        SET contact_process_flag= gn_process_status_imported,
          process_flag          ='Y'
        WHERE request_id        = gn_request_id
        AND EXISTS
          (SELECT 1
          FROM ap_sup_site_contact_int aint
          WHERE UPPER(aint.last_name)         = UPPER(stg.last_name)
          AND UPPER(AINT.FIRST_NAME)          = UPPER(STG.FIRST_NAME)
          AND aint.vendor_id                  =stg.vendor_id
          AND aint.vendor_site_id             =stg.vendor_site_id
          AND aint.status                     ='PROCESSED'
          AND aint.vendor_contact_interface_id=stg.vendor_contact_interface_id
          )
        AND stg.cont_target ='EBS'
        AND REQUEST_ID      = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
	  BEGIN
	    FOR cur IN c_error LOOP
		  UPDATE xx_ap_cld_supp_contact_stg stg
             SET contact_process_flag= gn_process_status_imp_fail,
                 process_flag          ='Y',
                 error_flag            ='E',
				 error_msg             = error_msg||','||cur.reject_lookup_code
           WHERE rowid=cur.drowid;				 
		END LOOP;
	    COMMIT;
	  END;
    END IF;
  END IF;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
EXCEPTION
WHEN OTHERS THEN
  gc_error_status_flag := 'Y';
  l_error_message      := gc_step||'EXCEPTION: (' || g_package_name || '.' || l_procedure || '-' || gc_step || ') ' || sqlerrm;
  print_debug_msg(p_message=> l_error_message ,p_force=> true);
  x_ret_code      := 1;
  x_return_status := 'E';
  x_err_buf       := l_error_message;
END load_supplier_cont_interface;
--+============================================================================+
--| Name          : main_prc_supplier                                          |
--| Description   : This procedure will be called from the concurrent program  |
--|                 for Suppliers Interface                                    |
--| Parameters    :                                                            |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--+============================================================================+
PROCEDURE main_prc_supplier(
    x_errbuf OUT NOCOPY  VARCHAR2 ,
    x_retcode OUT NOCOPY NUMBER )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  
BEGIN
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- validate_supplier_records    --
  --===============================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Invoking the procedure validate_supplier_records()' , p_force => true);
  validate_supplier_records( x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()' , p_force => true);

  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Invoking the procedure update_suppliers()' , p_force => true);
  update_supplier( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_vendor()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);

  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_supplier_interface()' , p_force => true);
  load_supplier_interface(x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_vendors()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier;

--+============================================================================+
--| Name          : main_prc_supplier_site                                     |
--| Description   : This procedure will be called from the concurrent program  |
--|                 for Suppliers Site Interface                               |
--| Parameters    :
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--+============================================================================+
PROCEDURE main_prc_supplier_site( x_errbuf OUT nocopy  VARCHAR2 ,
								  x_retcode OUT nocopy NUMBER 
								)
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
BEGIN
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- Validate the Supplier Site Records   --
  --===============================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Invoking the procedure validate_supplier_site_records()' , p_force => true);
  validate_supplier_site_records(x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_supplier_site_records()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  
  print_debug_msg(p_message => 'Invoking the procedure load update_suppliers_sites()' , p_force => true);
  update_supplier_sites( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_supplier_sites()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  
  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_supplier_site_interface()' , p_force => true);
  load_supplier_site_interface( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_supplier_site_interface()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_site() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier_site;
--+============================================================================+
--| Name          : main_prc_supplier_Contact                                  |
--| Description   : This procedure will be called from the concurrent program  |
--|                 for Suppliers Site Contact Interface                       |
--| Parameters    :                                                            |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main_prc_supplier_contact(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
BEGIN
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- Validate the Supplier Site Records   --
  --===============================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Invoking the procedure validate_Supp_contact_records()' , p_force => true);
  validate_supp_contact_records( x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_supp_contact_records()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  --===========================================================================
  -- Udpate the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load update_suppliers_contact()' , p_force => true);
  update_supplier_contact( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_supplier_contact()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_Supplier_cont_interface()' , p_force => true);
  load_supplier_cont_interface( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_Supplier_cont_interface()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    X_ERRBUF  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_Contact() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END main_prc_supplier_contact;
--+============================================================================+
--| Name          : main_prc_supplier_bank                                     |
--| Description   : This procedure will be called from the concurrent program  |
--|                 for main_prc_supplier_bank                                 |
--| Parameters    :                                                            |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--+============================================================================+
PROCEDURE main_prc_supplier_bank( x_errbuf OUT nocopy  VARCHAR2 ,
								  x_retcode OUT nocopy NUMBER 
								)
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
BEGIN
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;

  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Invoking the procedure validate_bank_records()' , p_force => true);
  validate_bank_records(x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completion of validate_bank_records' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);

  print_debug_msg(p_message => 'Invoking the procedure Update_bank_assignment_date()' , p_force => true);
  update_bank_assignment_date( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  Print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completion of Update_bank_assignment_date' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);

  print_debug_msg(p_message => 'Invoking the procedure attach_bank_assignments()' , p_force => true);
  attach_bank_assignments( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completion of attach_bank_assignments' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_bank() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier_bank;
--+============================================================================+
--| Name          : update_supplier_telex                                      |
--| Description   : This procedure will set telex in ap_supplier_sites_all     |
--|                 to interface to RMS legacy systems                         |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE Update_supplier_telex( x_errbuf OUT VARCHAR2 ,
								 x_retcode OUT NUMBER 
							   )
IS
CURSOR c_sup
IS
SELECT site.vendor_site_id 
  FROM xx_ap_cld_supp_bcls_stg bcls,
       xx_ap_cld_supp_contact_stg cont,
       xx_ap_cld_site_dff_stg dff,
       xx_ap_cld_supp_sites_stg site,
       xx_ap_cld_suppliers_stg stg
 WHERE 1=1
   AND stg.request_id           =gn_request_id
   AND stg.supp_process_flag    ='7'
   AND site.request_id          =stg.request_id
   AND site.supplier_number     =stg.segment1
   AND site.site_process_flag   ='7'      
   AND dff.request_id(+)           =site.request_id
   AND dff.vendor_site_code(+)     =site.vendor_site_code
   AND dff.supplier_number(+)      =stg.segment1
   AND dff.dff_process_flag(+)      ='7'   
   AND cont.request_id(+)          =site.request_id
   AND cont.supplier_number(+)     =site.supplier_number
   AND cont.vendor_site_code(+)    =site.vendor_site_code
   AND cont.contact_process_flag(+) ='7'
   AND bcls.request_id(+)          =stg.request_id
   AND bcls.supplier_number(+)     =stg.segment1
   AND bcls.bcls_process_flag(+)   ='7';
BEGIN
  FOR cur IN c_sup
  LOOP
    UPDATE ap_supplier_sites_all
       SET telex           ='510093'
     WHERE vendor_site_id=cur.vendor_site_id;
    COMMIT;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.Update_supplier_telex() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END update_supplier_telex;
-- +============================================================================+
-- | Procedure Name : display_status                                            |
-- |                                                                            |
-- | Description    : Procedure to display interface process status             |
-- |                                                                            |
-- |                                                                            |
-- | Parameters     : N/A                                                       |
-- +============================================================================+
PROCEDURE display_status
IS
--==============================================================================
-- Cursor Declarations to get table statistics of Supplier Staging
--==============================================================================
CURSOR c_sup_stats
IS
SELECT SUM(DECODE(supp_process_flag,2,1,0)) inprocess ,
       SUM(DECODE(supp_process_flag,6,1,0)) import_failed ,
       SUM(DECODE(supp_process_flag,3,1,0)) val_failed ,
       SUM(DECODE(supp_process_flag,7,1,0)) import_success
  FROM xx_ap_cld_suppliers_stg
 WHERE REQUEST_ID = gn_request_id;

CURSOR c_site_stats
IS
SELECT SUM(DECODE(site_process_flag,2,1,0)) inprocess ,
       SUM(DECODE(site_process_flag,6,1,0)) import_failed ,
       SUM(DECODE(site_process_flag,3,1,0)) val_failed ,
       SUM(DECODE(site_process_flag,7,1,0)) import_success
  FROM xx_ap_cld_supp_sites_stg
 WHERE request_id = gn_request_id;
 
CURSOR c_cont_stats
IS
SELECT SUM(DECODE(contact_process_flag,2,1,0)) inprocess ,
       SUM(DECODE(contact_process_flag,6,1,0)) import_failed ,
       SUM(DECODE(contact_process_flag,3,1,0)) val_failed ,
       SUM(DECODE(contact_process_flag,7,1,0)) import_success
  FROM xx_ap_cld_supp_contact_stg
 WHERE request_id = gn_request_id;
 
CURSOR c_bank_stats
IS
SELECT SUM(DECODE(bnkact_process_flag,2,1,0)) inprocess ,
       SUM(DECODE(bnkact_process_flag,6,1,0)) import_failed ,
       SUM(DECODE(bnkact_process_flag,3,1,0)) val_failed ,
       SUM(DECODE(bnkact_process_flag,7,1,0)) import_success
  FROM xx_ap_cld_supp_bnkact_stg
 WHERE request_id = gn_request_id;
BEGIN
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  FOR cur IN c_sup_stats
  LOOP
    print_debug_msg(p_message => 'SUPPLIER - Records Not picked for Validation : '|| TO_CHAR(cur.inprocess), p_force => true);
    print_debug_msg(p_message => 'SUPPLIER - Records Validation Failed         : '|| TO_CHAR(cur.val_failed), p_force => true);
    print_debug_msg(p_message => 'SUPPLIER - Records Import Failed             : '|| TO_CHAR(cur.import_failed), p_force => true);
    print_debug_msg(p_message => 'SUPPLIER - Records Import Success            : '|| TO_CHAR(cur.import_success), p_force => true);
  END LOOP;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  FOR cur IN c_site_stats
  LOOP
    print_debug_msg(p_message => 'Site     - Records Not picked for Validation : '|| TO_CHAR(cur.inprocess), p_force => true);
    print_debug_msg(p_message => 'Site     - Records Validation Failed         : '|| TO_CHAR(cur.val_failed), p_force => true);
    print_debug_msg(p_message => 'Site     - Records Import Failed             : '|| TO_CHAR(cur.import_failed), p_force => true);
    print_debug_msg(p_message => 'Site     - Records Import Success            : '|| TO_CHAR(cur.import_success), p_force => true);
  END LOOP;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  FOR cur IN c_cont_stats
  LOOP
    print_debug_msg(p_message => 'Contact  - Records Not picked for Validation : '|| TO_CHAR(cur.inprocess), p_force => true);
    print_debug_msg(p_message => 'Contact  - Records Validation Failed         : '|| TO_CHAR(cur.val_failed), p_force => true);
    print_debug_msg(p_message => 'Contact  - Records Import Failed             : '|| TO_CHAR(cur.import_failed), p_force => true);
    print_debug_msg(p_message => 'Contact  - Records Import Success            : '|| TO_CHAR(cur.import_success), p_force => true);
  END LOOP;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  FOR cur IN c_bank_stats
  LOOP
    print_debug_msg(p_message => 'Bank     - Records Not picked for Validation : '|| TO_CHAR(cur.inprocess), p_force => true);
    print_debug_msg(p_message => 'Bank     - Records Validation Failed         : '|| TO_CHAR(cur.val_failed), p_force => true);
    print_debug_msg(p_message => 'Bank     - Records Import Failed             : '|| TO_CHAR(cur.import_failed), p_force => true);
    print_debug_msg(p_message => 'Bank     - Records Import Success            : '|| TO_CHAR(cur.import_success), p_force => true);
  END LOOP;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
EXCEPTION
 WHEN OTHERS THEN
   print_debug_msg(p_message => 'When others in display status : '|| SQLERRM, p_force => true);
END display_status;
-- +============================================================================+
-- | Procedure Name : xx_ap_supp_cld_intf                                       |
-- |                                                                            |
-- | Description    : Main procedure for Supplier Interface                     |
-- |                                                                            |
-- |                                                                            |
-- | Parameters     : x_errbuf                   OUT      VARCHAR2              |
-- |                  x_retcode                  IN       VARCHAR2              |
-- |                  p_debug_level              IN       VARCHAR2              |
-- +============================================================================+
PROCEDURE xx_ap_supp_cld_intf(
    x_errbuf OUT NOCOPY  VARCHAR2,
    x_retcode OUT NOCOPY NUMBER,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure      VARCHAR2 (30) := 'xx_ap_supp_cld_intf';
  l_ret_code       NUMBER;
  l_err_buff       VARCHAR2 (4000);
  ln_request_id    NUMBER;
  lb_complete      BOOLEAN;
  lc_phase         VARCHAR2 (100);
  lc_status        VARCHAR2 (100);
  lc_dev_phase     VARCHAR2 (100);
  lc_dev_status    VARCHAR2 (100);
  lc_message       VARCHAR2 (100);
  lb_layout        BOOLEAN;
BEGIN
  --================================================================
  --Initializing Global variables
  --================================================================
  gn_request_id := fnd_global.conc_request_id;
  g_user_id     := fnd_global.user_id;
  g_login_id    := fnd_global.login_id;
  gc_debug      := p_debug_level;
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_err_buff      := NULL;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);  
  --===============================================================
  --Updating Request Id into Supplier Staging table     --
  --===============================================================
  UPDATE xx_ap_cld_suppliers_stg
  SET supp_process_flag   = gn_process_status_inprocess ,
    request_id            = gn_request_id ,
    process_flag          = 'P'
  WHERE supp_process_flag = '1'
  AND process_flag        ='N'
  AND request_id         IS NULL;
  IF SQL%NOTFOUND THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPPLIERS_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
  ELSIF SQL%FOUND THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPPLIERS_STG are '||sql%rowcount , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are '||sql%rowcount);
  END IF;
  --===============================================================
  --Updating Request Id into Supplier Site Staging table     --
  --===============================================================
  UPDATE xx_ap_cld_supp_sites_stg xasc
  SET site_process_flag   = gn_process_status_inprocess ,
    request_id            = gn_request_id ,
    process_flag          = 'P'
  WHERE site_process_flag ='1'
  AND process_flag        ='N'
  AND request_id         IS NULL;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);    
  IF SQL%NOTFOUND THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_SITES_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are 0');
  ELSIF SQL%FOUND THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_SITES_STG are '||sql%rowcount , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are '||sql%rowcount);
  END IF;
  --===============================================================
  --Updating Request Id into Supplier Contact Staging table     --
  --===============================================================
  UPDATE xx_ap_cld_supp_contact_stg
  SET contact_process_flag   = gn_process_status_inprocess ,
    request_id               = gn_request_id ,
    process_flag             = 'P'
  WHERE contact_process_flag ='1'
  AND process_flag           ='N'
  AND request_id            IS NULL
  AND cont_target            ='EBS';
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);    
  IF SQL%NOTFOUND THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_CONTACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Contact records ready for validate and load are 0');
  ELSIF SQL%FOUND THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_CONTACT_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of Contact records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  --===================================================================
  --Updating Request Id into Supplier Bank Account Staging table     --
  --===================================================================
  UPDATE xx_ap_cld_supp_bnkact_stg
  SET bnkact_process_flag   = gn_process_status_inprocess ,
    request_id              = gn_request_id ,
    process_flag            = 'P'
  WHERE bnkact_process_flag = '1'
  AND process_flag          ='N'
  AND request_id           IS NULL;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);    
  IF SQL%NOTFOUND THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPP_BNKACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Bank records ready for validate and load are 0');
  ELSIF SQL%FOUND THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BNKACT_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of Bank records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  --===============================================================
  --Updating Request Id into Supplier Site DFF Staging table     --
  --===============================================================
  UPDATE xx_ap_cld_site_dff_stg
  SET dff_process_flag   = gn_process_status_inprocess ,
    request_id           = gn_request_id ,
    process_flag         = 'P'
  WHERE dff_process_flag = '1'
  AND process_flag       ='N'
  AND request_id        IS NULL;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);    
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SITE_DFF_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of DFF ready for validate and load are 0');
  ELSIF SQL%FOUND THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SITE_DFF_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of DFF ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  --===============================================================================
  --Updating Request Id into Supplier Business Classification  Staging table     --
  --===============================================================================
  UPDATE xx_ap_cld_supp_bcls_stg
  SET bcls_process_flag   = gn_process_status_inprocess ,
    request_id            = gn_request_id ,
    process_flag          = 'P'
  WHERE bcls_process_flag = '1'
  AND process_flag        ='N'
  AND request_id         IS NULL;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);    
  IF SQL%NOTFOUND THEN
    print_debug_msg(p_message => 'No records exist to process in the table xx_ap_cld_supp_bcls_stg.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Classification records ready for validate and load are 0');
  ELSIF SQL%FOUND THEN
    print_debug_msg(p_message => 'Records to be processed from the table xx_ap_cld_supp_bcls_stg are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of Classification records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling Supplier Wrapper' , p_force => true);
  main_prc_supplier( X_ERRBUF =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(P_MESSAGE => 'Exiting Supplier Wrapper' , p_force => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling Business Classification' , p_force => true);
  process_bus_class(gn_request_id);
  print_debug_msg(P_MESSAGE => 'Exiting Business Classification' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling Supplier Site Wrapper' , p_force => true);
  main_prc_supplier_site( x_errbuf =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(p_message => 'Exiting  Supplier Site Wrapper' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling  Supplier Contact Wrapper' , p_force => true);
  main_prc_supplier_contact( x_errbuf =>l_err_buff , x_retcode=> l_ret_code );
  print_debug_msg(p_message => 'Exiting  Supplier Contact Wrapper' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling  Supplier Bank Wrapper' , p_force => true);
  main_prc_supplier_bank( x_errbuf =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(p_message => 'Exiting Supplier Bank  Wrapper' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling Custom DFF Process' , p_force => true);
  xx_supp_dff(gn_request_id);
  print_debug_msg(p_message => 'exiting custom dff process' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling  Update_supplier_telex' , p_force => true);
  update_supplier_telex(x_errbuf =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(p_message => 'Exiting Update_supplier_telex' , p_force => true);
  print_debug_msg(p_message => 'Submitting the Report Program to generate the Excel File', p_force => true);

  lb_layout     := fnd_request.add_layout('XXFIN', 'XXAPCLDINTR', 'en', 'US', 'EXCEL' );
  ln_request_id := fnd_request.submit_request ( application => 'XXFIN', 
												program => 'XXAPCLDINTR', 
												description => NULL, 
												start_time => SYSDATE, 
												sub_request => FALSE, 
												argument1 => gn_request_id 
											  );
  IF ln_request_id > 0 THEN
     COMMIT;
     print_debug_msg(p_message => 'Able to submit the Report Program', p_force => true);
  ELSE
     print_debug_msg(p_message => 'Failed to submit the Report Program to generate the output file - ' || SQLERRM , p_force => true);
  END IF;
  print_debug_msg(p_message => 'While Waiting Report Request to Finish');

  -- wait for request to finish

  lb_complete :=fnd_concurrent.wait_for_request ( request_id => ln_request_id, 
												  interval => 15, 
												  max_wait => 0, 
												  phase => lc_phase, 
												  status => lc_status, 
												  dev_phase => lc_dev_phase, 
												  dev_status => lc_dev_status, 
												  message => lc_message  
                                                );
  display_status;
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'Exception in xx_ap_supp_cld_intf_pkg.xx_ap_supp_cld_intf - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END xx_ap_supp_cld_intf;
END xx_ap_supp_cld_intf_pkg;
/
SHOW ERROR;
