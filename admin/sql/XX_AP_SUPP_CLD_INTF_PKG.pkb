SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace 
PACKAGE body XX_AP_SUPP_CLD_INTF_PKG
  -- +==========================================================================+
  -- |                  Office Depot - Project Simplify                         |
  -- |                  Office Depot                                            |
  -- +==========================================================================+
  -- | Name             : XX_AP_SUPP_CLD_INTF_PKG                               |
  -- | Description      : This Program will do validations and load vendors to  |
  -- |                    iface table from staging table This process is defined|
  -- |                    for Cloud to EBS Supplier Interface. And also does    |
  -- |                    the post updates                                      |
  -- |                                                                          |
  -- |Change Record:                                                            |
  -- |===============                                                           |
  -- |Version    Date          Author            Remarks                        |
  -- |=======    ==========    =============     ===============================|
  -- |  1.0    14-MAY-2019     Priyam Parmar     Initial code                   |
  -- |  1.1    21-JUN-2019     Dinesh Nagapuri   Added Business Classification  |
  -- |                                           and Custom DFF     
  ---|  1.2    25-JUN-2019     Priyam Parmar     Added Telex update for Supplier Site (RMS)
  ---|  1.3    27-JUN-2019     Priyam Parmar     Removed Bank staging table from 1.2 update
  -- |==========================================================================+
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
    p_force   IN BOOLEAN DEFAULT false)
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  IF (gc_debug  = 'Y' OR p_force) THEN
    lc_message :=p_message;
    fnd_file.put_line(fnd_file.log,lc_message);
    -- Fnd_File.Put_Line(Fnd_File.out,Lc_Message);
    IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
      dbms_output.put_line(lc_message);
    END IF;
  END IF;
EXCEPTION
WHEN OTHERS THEN
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
--| Name          : reset_stage_tables                                          |
--| Description   : This procedure will delete all records from below 2 staging tables|
--|                 XX_AP_SUPPLIER_STG and  XX_AP_SUPP_SITE_CONTACT_STG        |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE reset_stage_tables(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2 )
IS
  l_ret_code      NUMBER;
  l_return_status VARCHAR2 (100);
  l_err_buff      VARCHAR2 (4000);
BEGIN
  print_debug_msg(p_message => 'BEGIN procedure reset_stage_tables()', p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===========================================================================
  -- Delete the records from Supplier staging table 'XX_AP_SUPPLIER_STG'
  --===========================================================================
  BEGIN
    DELETE FROM xx_ap_supplier_stg;
    IF sql%notfound THEN
      print_debug_msg(p_message => 'No records deleted from table XX_AP_SUPPLIER_STG.' , p_force => true);
    elsif sql%found THEN
      print_debug_msg(p_message => 'No. of records deleted from table XX_AP_SUPPLIER_STG is '||sql%rowcount , p_force => true);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_ret_code      := 1;
    l_return_status := 'E';
    l_err_buff      := 'Exception when deleting Supplier Staging records'||SQLCODE||' - '||SUBSTR(sqlerrm, 1, 3500);
    RETURN;
  END;
  --==================================================================================
  -- Delete the records from Supplier Site staging table 'XX_AP_SUPP_SITE_CONTACT_STG'
  --==================================================================================
  BEGIN
    DELETE FROM xx_ap_supp_site_contact_stg;
    IF sql%notfound THEN
      print_debug_msg(p_message => 'No records deleted from table XX_AP_SUPP_SITE_CONTACT_STG.' , p_force => true);
    elsif sql%found THEN
      print_debug_msg(p_message => 'No. of records deleted from table XX_AP_SUPP_SITE_CONTACT_STG is '||sql%rowcount , p_force => true);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_ret_code      := 1;
    l_return_status := 'E';
    l_err_buff      := 'Exception when deleting Supplier Site Staging records'||SQLCODE||' - '||SUBSTR(sqlerrm, 1, 3500);
    RETURN;
  END;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
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
    SELECT LENGTH(trim(TRANSLATE(v_string, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', ' ')))
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
--+============================================================================+
--| Name          : insert_bus_class                                        |
--| Description   : This FUnction will insert Business Classifications     |
--|                      |
--|                                                                            |
--| Parameters    : p_party_id,p_bus_code,p_attribute,p_vendor_id              |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
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
  SELECT POS_BUS_CLASS_ATTR_S.nextval INTO v_class_id FROM DUAL;
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
  g_ins_bus_class := 'Y'; -- -- This is used to check that if any record inserted or not.
  RETURN('Y');
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in while inserting business classification :'||TO_CHAR(p_vendor_id)||','||p_bus_code||','||SQLERRM);
  dbms_output.put_line('Error in while inserting business classification :'||TO_CHAR(p_vendor_id)||','||p_bus_code||','||SQLERRM);
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
    p_vendor_site_id IN NUMBER
  )
  RETURN VARCHAR2
IS
  v_tst      VARCHAR2(1);
  ln_user_id NUMBER :=fnd_profile.value('USER_ID');
  ln_org_id  NUMBER := fnd_profile.value('ORG_ID');
BEGIN
  INSERT
  INTO xx_ap_custom_tolerances
    (
      SUPPLIER_ID,
      SUPPLIER_SITE_ID,
      ORG_ID,
      FAVOURABLE_PRICE_PCT,
      MAX_PRICE_AMT,
      MIN_CHARGEBACK_AMT,
      MAX_FREIGHT_AMT,
      DIST_VAR_NEG_AMT,
      DIST_VAR_POS_AMT,
      CREATED_BY,
      CREATION_DATE,
      LAST_UPDATED_BY,
      LAST_UPDATE_DATE
    )
    VALUES
    (
      p_vendor_id,
      p_vendor_site_id,
      ln_org_id,
      30,
      50,
      2,
      0,
      1,
      1,
      ln_user_id,
      SYSDATE,
      ln_user_id,
      SYSDATE
    );
  RETURN('Y');
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in processing Custom Tolerance :'||SQLERRM);
  RETURN('N');
END xx_custom_tolerance;
--+============================================================================+
--| Name          : xx_custom_sup_traits                                       |
--| Description   : This FUnction will process Supplier Traits for Supplier    |
--|                      |
--|                                                                            |
--| Parameters    : p_sup_trait,p_sup_number                                |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
FUNCTION xx_custom_sup_traits
  (
    p_sup_trait IN VARCHAR2 --This is a parameter that contains a delimited list of items
    ,
    p_sup_number IN NUMBER
  )
  RETURN VARCHAR2
IS
  lc_sup_trait      VARCHAR2(4000) := p_sup_trait || '|';
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
    dbms_output.put_line('Test 1   : '||lc_sup_trait);
    ln_place := instr(lc_sup_trait,'|'); -- find the first separator
    dbms_output.put_line('Test 2   : '||ln_place);
    lc_sup_tair_value := SUBSTR(lc_sup_trait,1,ln_place - 1); -- extract item
    /*
    First check in XX_AP_SUP_TRAITS for supplier trait
    if exists  then
    check if exists in trait matrix
    if not exists then
    insert in trait matrix
    end if;
    else
    insert XX_AP_SUP_TRAITS
    insert XX_AP_SUP_TRAITS_matrix
    end if;
    */
    BEGIN
      SELECT description,
        enable_flag,
        sup_trait_id,
        master_sup_ind
      INTO lc_description,
        lc_enable_flag,
        ln_sup_trait_id,
        lc_master_sup_ind
      FROM XX_AP_SUP_TRAITS
      WHERE sup_trait =lc_sup_tair_value;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      SELECT MAX(sup_trait_id) INTO ln_sup_trait_id FROM XX_AP_SUP_TRAITS;
      ln_sup_trait_id := ln_sup_trait_id+5;
      INSERT
      INTO XX_AP_SUP_TRAITS
        (
          SUP_TRAIT,
          DESCRIPTION,
          MASTER_SUP_IND,
          CREATION_DATE,
          CREATED_BY,
          LAST_UPDATE_DATE,
          LAST_UPDATED_BY,
          LAST_UPDATE_LOGIN,
          ENABLE_FLAG,
          SUP_TRAIT_ID
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
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in processing Traits :'||SQLERRM);
    END;
    dbms_output.put_line('Test 21   : '||ln_sup_trait_id);
    BEGIN
      SELECT COUNT(*)
      INTO ln_mat_count
      FROM xx_ap_sup_traits_matrix
      WHERE supplier   = p_sup_number
      AND SUP_TRAIT_ID = ln_sup_trait_id;
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in processing Trait Matrix :'||SQLERRM);
    END;
    IF ln_mat_count =0 THEN
      BEGIN
        INSERT
        INTO XX_AP_SUP_TRAITS_MATRIX
          (
            SUPPLIER,
            CREATION_DATE,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            LAST_UPDATE_LOGIN,
            ENABLE_FLAG,
            SUP_TRAIT_ID
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
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in processing Custom Tolerance :'||SQLERRM);
      END;
    END IF;
    --your_procedure(lc_sup_tair_value);                      -- call procedure
    lc_sup_trait := SUBSTR(lc_sup_trait,ln_place + 1); -- chop list
  END LOOP;
  RETURN('Y');
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Error in processing Custom Tolerance :'||SQLERRM);
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
		 XX_AP_CLD_SUPP_BCLS_STG bus,
      XX_AP_CLD_SUPPLIERS_STG stg
    WHERE 1              =1
    AND bus.process_Flag ='P'
    AND bus.request_id   = gn_request_id
    AND stg.request_id   = bus.request_id
      --AND bus.supplier_name     = stg.supplier_name
    AND bus.supplier_number = stg.segment1
    AND stg.supp_process_flag IN (7,8)
	AND sup.segment1=stg.segment1;
  v_buss_flag  VARCHAR2(1);
  v_error_Flag VARCHAR2(1);
  ln_vendor_id NUMBER;
  ln_party_id  NUMBER;
  ln_cus_count NUMBER;
  lc_error_msg VARCHAR2(2000);
BEGIN

  FOR cur IN C1
  LOOP
    v_error_Flag    := NULL;
    g_ins_bus_class := 'N';
    ln_vendor_id    := NULL;
    ln_party_id     := NULL;
    v_buss_Flag     := NULL;
    ln_cus_count    := 0;
    print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
    print_debug_msg(p_message => 'Input Parameters' , p_force => true);
    print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
    print_debug_msg(p_message => '  ' , p_force => true);
    print_debug_msg(p_message => 'gn_request_id :                  '|| gn_request_id , p_force => true);
    /*
    BEGIN
    SELECT vendor_id, party_id  -- check with Priyam, once new supplier is created, vendor_id is populated or not
    INTO ln_vendor_id, ln_party_id
    FROM ap_suppliers
    WHERE 1         =1
    AND vendor_name = cur.supplier_name;-- 'ALL THE RAGES INC TEST' ;
    EXCEPTION
    WHEN OTHERS THEN
    v_error_flag :='Y';
    lc_error_msg := 'Error while validating against supplier';
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while validating against supplier :'||cur.supplier_name||''||SQLERRM);
    END;
    */
    BEGIN
      SELECT COUNT(*)
      INTO ln_cus_count
      FROM pos_bus_class_attr
      WHERE 1         = 1
      AND party_id    = cur.party_id
      AND vendor_id   = cur.vendor_id
      AND lookup_code = cur.classification;
      IF ln_cus_count >0 THEN
        v_error_flag :='Y';
        lc_error_msg :='Already Processed for this party and classificatoin combination';
        print_debug_msg(p_message => 'Already Processed for this party and classificatoin combination Count '||ln_cus_count|| ' for Vendor '||cur.vendor_id||' classification : '||cur.classification , p_force => true);
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      ln_cus_count :=-1;
      v_error_flag :='Y';
      lc_error_msg := 'Error while validating against business classification';
      print_debug_msg(p_message => 'Error while validating against business classification :'||cur.supplier_name||''||SQLERRM, p_force => true);
    END;
    print_debug_msg(p_message => 'Business Classification Count '||ln_cus_count|| ' for Vendor '||cur.vendor_id||' classification : '||cur.classification , p_force => true);
    -- check in pos table if this exists or not before insert
    IF cur.classification  IS NOT NULL AND ln_cus_count =0 THEN
      IF cur.classification ='FOB' OR cur.classification = 'MINORITY_OWNED' THEN
        --===============================================================
        -- Inserting into Business Classification    --
        --===============================================================
        print_debug_msg(p_message => 'Inserting into Business Classification for  '||cur.classification|| ' for Vendor '||cur.vendor_id||' classification : '||cur.classification , p_force => true);
        v_buss_Flag:= insert_bus_class(cur.party_id,cur.classification,cur.subclassification,cur.vendor_id);
      ELSE
        print_debug_msg(p_message => 'Inserting into Business Classification for  '||cur.classification|| ' for Vendor '||cur.vendor_id||' classification : '||cur.classification , p_force => true);
        v_buss_Flag:= insert_bus_class(cur.party_id,cur.classification,NULL,cur.vendor_id);
      END IF;
      IF v_buss_Flag    ='N' THEN
        v_error_flag   :='Y';
        lc_error_msg   := 'Error while processing insert_bus_class';
      ELSIF v_buss_Flag ='Y' THEN
        v_error_flag   :='N';
      END IF;
    END IF;
    -- Added this code in SIT test -- 1.1
    -- If any one record (using insert_bus_class()API above) inserted for A supplier then invoke this API..
    IF g_ins_bus_class = 'Y' AND ln_cus_count =0 THEN
      print_debug_msg(p_message => 'Invoking the API pos_supp_classification_pkg.synchronize_class_tca_to_po() to synch the Business Classifications', p_force => false);
      BEGIN
        pos_supp_classification_pkg.synchronize_class_tca_to_po(ln_party_id,ln_vendor_id);
      END;
      print_debug_msg(p_message => 'Successfully completed the execution of API pos_supp_classification_pkg.synchronize_class_tca_to_po() to synch the Business Classifications', p_force => false);
    END IF;
    IF v_error_flag='N' AND g_ins_bus_class = 'Y' THEN
      UPDATE XX_AP_CLD_SUPP_BCLS_STG
      SET bcls_process_Flag = 7,
        vendor_id           = cur.vendor_id,
        process_Flag        ='Y'
      WHERE rowid           = cur.drowid;
    ELSE
      UPDATE xx_ap_cld_supp_bcls_stg
      SET bcls_process_Flag=6,
        process_Flag       ='Y',
        error_msg          = lc_error_msg,
        vendor_id          = cur.vendor_id
      WHERE rowid          =cur.drowid;
    END IF;
    COMMIT;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  print_debug_msg(p_message =>'Error in processing business classification :', p_force => false);
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
  v_tst VARCHAR2(1);
  CURSOR C1
  IS
    SELECT dff.rowid drowid,
      dff.supplier_number ,
      dff.supplier_name ,
      dff.vendor_site_code ,
      dff.edi_distribution_code ,
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
      site.vendor_site_id
    FROM xx_ap_cld_site_dff_stg dff,
      xx_ap_cld_supp_sites_stg site
    WHERE 1                     =1
    AND dff.process_Flag        = 'P'
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
  v_error_flag            VARCHAR2(1);
  v_kff_id                NUMBER;
  ln_count                NUMBER;
  ln_vendor_id            NUMBER;
  ln_vendor_site_id       NUMBER;
  ln_tol_count            NUMBER;
  ln_bus_count            NUMBER;
  lc_attribute10          VARCHAR2(100);
  lc_attribute11          VARCHAR2(100);
  lc_attribute12          VARCHAR2(100);
  lc_error_msg            VARCHAR2(2000);
  lc_vendor_site_code_alt VARCHAR2(100);
BEGIN
  FOR cur IN C1
  LOOP
    v_error_Flag            :='N';
    lc_attribute11          :=NULL;
    lc_attribute12          :=NULL;
    lc_attribute10          :=NULL;
    ln_vendor_id            :=NULL;
    ln_vendor_site_id       :=NULL;
    ln_tol_count            :=NULL;
    ln_bus_count            :=NULL;
    lc_error_msg            :=NULL;
    lc_vendor_site_code_alt := NULL;
    print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
    print_debug_msg(p_message => 'Input Parameters' , p_force => true);
    print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
    print_debug_msg(p_message => '  ' , p_force => true);
    print_debug_msg(p_message => 'gn_request_id :                  '|| gn_request_id , p_force => true);
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
      print_debug_msg(p_message => '  Error in Deriving Kff Values for site '||cur.vendor_site_id||' SQLERRM : '||SQLERRM , p_force => true);
      v_error_flag :='Y';
      lc_error_msg := lc_error_msg||'Error while extracting supplier site : '||cur.vendor_site_code;
    END;
    print_debug_msg(p_message => '  Derived Kff Values for site '||cur.vendor_site_id , p_force => true);
    print_debug_msg(p_message => '  lc_attribute10 '||lc_attribute10 , p_force => true);
    print_debug_msg(p_message => '  lc_attribute11 '||lc_attribute11 , p_force => true);
    print_debug_msg(p_message => '  lc_attribute12 '||lc_attribute12 , p_force => true);
    BEGIN
      SELECT COUNT(*)
      INTO ln_bus_count
      FROM xx_po_vendor_sites_kff
      WHERE vs_kff_id IN (lc_attribute10,lc_attribute11,lc_attribute12);
    EXCEPTION
    WHEN OTHERS THEN
      ln_bus_count := -1;
      print_debug_msg(p_message => '  Error in Deriving KFF : '||SQLERRM , p_force => true);
      v_error_flag :='Y';
      lc_error_msg := lc_error_msg||'Error while extracting custom dff information : '||cur.vendor_site_code;
    END;
    print_debug_msg(p_message => '  Vendor Site KFF Count for attributes : '||ln_bus_count , p_force => true);
    IF ln_bus_count = 0 THEN
      print_debug_msg(p_message => ' Inserting into group 1 KFF : ', p_force => true);
      BEGIN
        SELECT XX_PO_VENDOR_SITES_KFF_S.nextval INTO v_kff_id FROM DUAL;
        INSERT
        INTO xx_po_vendor_sites_kff
          (
            VS_KFF_ID ,
            STRUCTURE_ID ,
            ENABLED_FLAG ,
            SUMMARY_FLAG ,
            START_DATE_ACTIVE ,
            CREATED_BY ,
            CREATION_DATE ,
            LAST_UPDATED_BY ,
            LAST_UPDATE_DATE ,
            SEGMENT1 ,
            SEGMENT2 ,
            SEGMENT4 ,
            SEGMENT5 ,
            SEGMENT6 ,
            SEGMENT13 ,
            SEGMENT15 ,
            SEGMENT16 ,
            SEGMENT17
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
            cur.LEAD_TIME,
            cur.BACK_ORDER_FLAG,
            cur.MIN_PREPAID_CODE,
            cur.VENDOR_MIN_AMOUNT,
            cur.SUPPLIER_SHIP_TO,
            cur.MASTER_VENDOR_ID,
            TO_CHAR(cur.OD_DATE_SIGNED,'DD-MON-YY'),
            TO_CHAR(cur.VENDOR_DATE_SIGNED,'DD-MON-YY'),
            cur.DEDUCT_FROM_INVOICE_FLAG
          );
        UPDATE ap_supplier_sites_all
        SET attribute10     =v_kff_id
        WHERE vendor_site_id=cur.vendor_site_id;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 101:';
      END;
      print_debug_msg(p_message => ' Inserting into group 2 KFF : ', p_force => true);
      BEGIN
        SELECT XX_PO_VENDOR_SITES_KFF_S.nextval INTO v_kff_id FROM DUAL;
        INSERT
        INTO xx_po_vendor_sites_kff
          (
            VS_KFF_ID ,
            STRUCTURE_ID ,
            ENABLED_FLAG ,
            SUMMARY_FLAG ,
            START_DATE_ACTIVE ,
            CREATED_BY ,
            CREATION_DATE ,
            LAST_UPDATED_BY ,
            LAST_UPDATE_DATE ,
            SEGMENT37
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
      print_debug_msg(p_message => ' Inserting into group 3 KFF : ', p_force => true);
      BEGIN
        SELECT XX_PO_VENDOR_SITES_KFF_S.nextval INTO v_kff_id FROM DUAL;
        INSERT
        INTO xx_po_vendor_sites_kff
          (
            VS_KFF_ID ,
            STRUCTURE_ID ,
            ENABLED_FLAG ,
            SUMMARY_FLAG ,
            START_DATE_ACTIVE ,
            CREATED_BY ,
            CREATION_DATE ,
            LAST_UPDATED_BY ,
            LAST_UPDATE_DATE ,
            SEGMENT40 ,
            SEGMENT41 ,
            SEGMENT42 ,
            SEGMENT43 ,
            SEGMENT44 ,
            SEGMENT45 ,
            SEGMENT46 ,
            SEGMENT47 ,
            SEGMENT48 ,
            SEGMENT49 ,
            SEGMENT50 ,
            SEGMENT51 ,
            SEGMENT52 ,
            SEGMENT53 ,
            SEGMENT54
            --, SEGMENT56
            --, SEGMENT57
            ,
            SEGMENT58
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
            cur.RTV_OPTION,
            cur.RTV_FREIGHT_PAYMENT_METHOD,
            cur.PERMANENT_RGA,
            cur.DESTROY_ALLOW_AMOUNT,
            cur.PAYMENT_FREQUENCY,
            cur.MIN_RETURN_QTY,
            cur.MIN_RETURN_AMOUNT,
            cur.DAMAGE_DESTROY_LIMIT,
            cur.RTV_INSTRUCTIONS,
            cur.ADDL_RTV_INSTRUCTIONS,
            cur.RGA_MARKED_FLAG,
            cur.REMOVE_PRICE_STICKER_FLAG,
            cur.CONTACT_SUPPLIER_FOR_RGA_FLAG,
            cur.DESTROY_FLAG,
            cur.SERIAL_NUM_REQUIRED_FLAG,
            -- cur.OBSOLETE_ALLOW_PERNTG     ,
            --cur.OBSOLETE_DAYS             ,          check this
            cur.RTV_RELATED_SITE
          );
        UPDATE ap_supplier_sites_all
        SET attribute12     =v_kff_id
        WHERE vendor_site_id=cur.vendor_site_id;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||'Error in processing Custom DFF for Structure Id 50351:';
      END;
      --===============================================================
      -- Inserting into Custom Supplier Traits    --
      --===============================================================
      print_debug_msg(p_message => ' Calling Cupplier Traits for Trait : '||cur.sup_trait||' cur.supplier_number : '||cur.supplier_number, p_force => true);
      IF cur.sup_trait IS NOT NULL THEN	  
         v_error_flag := xx_custom_sup_traits(cur.sup_trait,NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id ) );
	  END IF;
      BEGIN
        SELECT COUNT(*)
        INTO ln_tol_count
        FROM xx_ap_custom_tolerances
        WHERE 1              =1
        AND supplier_id      = cur.vendor_id
        AND supplier_site_id = cur.vendor_site_id ;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => 'Error while extracting data from tolerance '||SQLERRM, p_force => true);
        --v_error_flag:='Y';
        --lc_error_msg := 'Error while extracting data from tolerance ';
      END;
      --===============================================================
      -- Processing Custom Tolerance    --
      --===============================================================
      print_debug_msg(p_message => 'Processing Custom Tolerance for vendor_id : '||cur.vendor_id||' cur.vendor_site_id : '||cur.vendor_site_id, p_force => true);
      IF ln_tol_count = 0 THEN
        v_error_flag := xx_custom_tolerance(cur.vendor_id, cur.vendor_site_id);
      END IF;
      print_debug_msg(p_message => 'Updating records for Cloud Custom DFF ', p_force => true);
      IF v_error_Flag='Y' THEN
        UPDATE XX_AP_CLD_SITE_DFF_STG
        SET dff_process_Flag = 7,
          process_Flag       = 'Y',
          error_msg          = lc_error_msg,
          vendor_id          = cur.vendor_id,
          vendor_site_id     = cur.vendor_site_id,
          create_flag        = 'Y'
        WHERE rowid          =cur.drowid;
      ELSE
        UPDATE XX_AP_CLD_SITE_DFF_STG
        SET dff_process_Flag = 6,
          process_Flag       = 'Y',
          vendor_id          = cur.vendor_id,
          vendor_site_id     = cur.vendor_site_id,
          create_flag        = 'Y'
        WHERE rowid          =cur.drowid;
      END IF;
      COMMIT;
    ELSIF ln_bus_count >0 AND ( lc_attribute10 IS NOT NULL OR lc_attribute11 IS NOT NULL OR lc_attribute12 IS NOT NULL) THEN
      BEGIN
        IF lc_attribute10 IS NOT NULL THEN
          UPDATE xx_po_vendor_sites_kff
          SET LAST_UPDATED_BY = fnd_global.user_id,
            LAST_UPDATE_DATE  = SYSDATE,
            SEGMENT1          = cur.LEAD_TIME,
            SEGMENT2          = cur.BACK_ORDER_FLAG,
            SEGMENT4          = cur.MIN_PREPAID_CODE,
            SEGMENT5          = cur.VENDOR_MIN_AMOUNT,
            SEGMENT6          = cur.SUPPLIER_SHIP_TO,
            SEGMENT13         = cur.MASTER_VENDOR_ID,
            SEGMENT15         = TO_CHAR(cur.OD_DATE_SIGNED,'DD-MON-YY'),
            SEGMENT16         = TO_CHAR(cur.VENDOR_DATE_SIGNED,'DD-MON-YY'),
            SEGMENT17         = cur.DEDUCT_FROM_INVOICE_FLAG
          WHERE VS_KFF_ID     = lc_attribute10
          AND STRUCTURE_ID    = 101;
        ELSIF lc_attribute11 IS NOT NULL THEN
          UPDATE xx_po_vendor_sites_kff
          SET LAST_UPDATED_BY = fnd_global.user_id,
            LAST_UPDATE_DATE  = SYSDATE,
            SEGMENT37         = cur.edi_distribution_code
          WHERE VS_KFF_ID     = lc_attribute11
          AND STRUCTURE_ID    = 50350;
        ELSIF lc_attribute12 IS NOT NULL THEN
          UPDATE xx_po_vendor_sites_kff
          SET LAST_UPDATED_BY = fnd_global.user_id,
            LAST_UPDATE_DATE  = SYSDATE,
            SEGMENT37         = cur.edi_distribution_code,
            SEGMENT40         = cur.RTV_OPTION,
            SEGMENT41         = cur.RTV_FREIGHT_PAYMENT_METHOD,
            SEGMENT42         = cur.PERMANENT_RGA,
            SEGMENT43         = cur.DESTROY_ALLOW_AMOUNT,
            SEGMENT44         = cur.PAYMENT_FREQUENCY,
            SEGMENT45         = cur.MIN_RETURN_QTY,
            SEGMENT46         = cur.MIN_RETURN_AMOUNT,
            SEGMENT47         = cur.DAMAGE_DESTROY_LIMIT,
            SEGMENT48         = cur.RTV_INSTRUCTIONS,
            SEGMENT49         = cur.ADDL_RTV_INSTRUCTIONS,
            SEGMENT50         = cur.RGA_MARKED_FLAG,
            SEGMENT51         = cur.REMOVE_PRICE_STICKER_FLAG,
            SEGMENT52         = cur.CONTACT_SUPPLIER_FOR_RGA_FLAG,
            SEGMENT53         = cur.DESTROY_FLAG,
            SEGMENT54         = cur.SERIAL_NUM_REQUIRED_FLAG,
            --, SEGMENT56       = - cur.OBSOLETE_ALLOW_PERNTG,
            --, SEGMENT57       = --cur.OBSOLETE_DAYS,
            SEGMENT58      = cur.RTV_RELATED_SITE
          WHERE VS_KFF_ID  = lc_attribute12
          AND STRUCTURE_ID = 50351;
          --===============================================================
          -- Inserting into Custom Supplier Traits    --
          --===============================================================
          print_debug_msg(p_message => ' Calling Cupplier Traits for Trait : '||cur.sup_trait||' cur.supplier_number : '||cur.supplier_number, p_force => true);
          v_error_flag := xx_custom_sup_traits(cur.sup_trait,NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id ) );
        END IF;
        --END LOOP;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => 'Error in processing Custom DFF while updating'||SQLERRM, p_force => true);
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||'Error in processing Custom DFF while updating ';
      END;
      IF v_error_Flag='Y' THEN
        UPDATE XX_AP_CLD_SITE_DFF_STG
        SET dff_process_Flag=7,
          process_Flag      ='Y',
          error_msg         = lc_error_msg,
          vendor_id         = cur.vendor_id,
          vendor_site_id    = cur.vendor_site_id,
          create_flag       = 'N'
        WHERE rowid         = cur.drowid;
      ELSE
        UPDATE XX_AP_CLD_SITE_DFF_STG
        SET dff_process_Flag = 6,
          process_Flag       ='Y',
          vendor_id          = cur.vendor_id,
          vendor_site_id     = cur.vendor_site_id,
          create_flag        = 'N'
        WHERE rowid          = cur.drowid;
      END IF;
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
    x_err_buf OUT VARCHAR2)
IS
  CURSOR c_supplier
  IS
    SELECT *
    FROM XX_AP_CLD_SUPPLIERS_STG XAS
    WHERE xas.CREATE_FLAG     ='N'---Update
    AND xas.supp_process_flag =gn_process_status_validated
    AND xas.REQUEST_ID        = fnd_global.conc_request_id;
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Staging
  --==============================================================================
  CURSOR c_sup_stats
  IS
    SELECT SUM(DECODE(supp_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(supp_process_flag,8,1,0)) -- updated
      ,
      SUM(DECODE(supp_process_flag,9,1,0)) -- update failed
      ,
      SUM(DECODE(supp_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(supp_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPPLIERS_STG
    WHERE REQUEST_ID         = gn_request_id
    AND CREATE_FLAG          = 'N';
  l_sup_eligible_cnt     NUMBER := 0;
  l_sup_upd_cnt          NUMBER := 0;
  l_sup_upd_error_cnt    NUMBER := 0;
  l_sup_val_not_load_cnt NUMBER := 0;
  l_sup_ready_process    NUMBER := 0;
  lr_vendor_rec ap_vendor_pub_pkg.r_vendor_rec_type;
  lr_existing_vendor_rec ap_suppliers%rowtype;
  v_api_version      NUMBER;
  v_init_msg_list    VARCHAR2(200);
  v_commit           VARCHAR2(200);
  v_validation_level NUMBER;
  l_msg              VARCHAR2(200);
  l_program_step     VARCHAR2 (100) := '';
  x_msg_count        NUMBER;
  x_msg_data         VARCHAR2(200);
  l_process_flag     VARCHAR2(10);
BEGIN
  /*Intializing Values**/
  v_api_version      := 1.0;
  v_init_msg_list    := fnd_api.g_true;
  v_commit           := fnd_api.g_true;
  v_validation_level := fnd_api.g_valid_level_full;
  l_program_step     := 'START';
  FOR c_sup IN c_supplier
  LOOP
    BEGIN
      SELECT *
      INTO lr_existing_vendor_rec
      FROM ap_suppliers asa
      WHERE asa.vendor_name = c_sup.supplier_name;
      -- AND asa.segment1      =c_sup.segment1;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||': Unable to derive the supplier  information for vendor id ' ||lr_existing_vendor_rec.vendor_id , p_force=>true);
    END;
    lr_vendor_rec.vendor_id              := lr_existing_vendor_rec.vendor_id;
    lr_vendor_rec.vendor_type_lookup_code:=c_sup.vendor_type_lookup_code;
    lr_vendor_rec.end_date_active        :=TO_DATE(c_sup.end_date_active,'YYYY/MM/DD');
    lr_vendor_rec.one_time_flag          :=c_sup.one_time_flag;
    lr_vendor_rec.min_order_amount       :=c_sup.min_order_amount;
    lr_vendor_rec.customer_num           :=c_sup.customer_num;
    --lr_vendor_rec.STANDARD_INDUSTRY_CLASS:=c_sup.STANDARD_INDUSTRY_CLASS;
    --lr_vendor_rec.NUM_1099:=c_sup.NUM_1099;
    lr_vendor_rec.federal_reportable_flag:=c_sup.federal_reportable_flag;
    lr_vendor_rec.type_1099              :=c_sup.type_1099;
    lr_vendor_rec.state_reportable_flag  :=c_sup.state_reportable_flag;
    lr_vendor_rec.tax_reporting_name     :=c_sup.tax_reporting_name;
    lr_vendor_rec.name_control           :=c_sup.name_control;
    lr_vendor_rec.tax_verification_date  :=TO_DATE(c_sup.tax_verification_date,'YYYY/MM/DD');
    lr_vendor_rec.allow_awt_flag         :=c_sup.allow_awt_flag;
    --lr_vendor_rec.AUTO_TAX_CALC_OVERRIDE:=c_sup.AUTO_TAX_CALC_OVERRIDE;
    lr_vendor_rec.vat_code            :=c_sup.vat_code;
    lr_vendor_rec.vat_registration_num:=c_sup.vat_registration_num;
    lr_vendor_rec.attribute_category  :=c_sup.attribute_category;
    lr_vendor_rec.attribute3          :=c_sup.attribute3;
    lr_vendor_rec.attribute2          :=c_sup.attribute2;
    lr_vendor_rec.attribute4          :=c_sup.attribute4;
    lr_vendor_rec.attribute5          :=c_sup.attribute5;
    lr_vendor_rec.attribute6          :=c_sup.attribute6;
    lr_vendor_rec.attribute7          :=c_sup.attribute7;
    lr_vendor_rec.attribute8          :=c_sup.attribute8;
    lr_vendor_rec.attribute9          :=c_sup.attribute9;
    lr_vendor_rec.attribute10         :=c_sup.attribute10;
    lr_vendor_rec.attribute11         :=c_sup.attribute11;
    lr_vendor_rec.attribute12         :=c_sup.attribute12;
    lr_vendor_rec.attribute13         :=c_sup.attribute13;
    lr_vendor_rec.attribute14         :=c_sup.attribute14;
    lr_vendor_rec.attribute15         :=c_sup.attribute15;
    FND_MSG_PUB.INITIALIZE; --to make msg_count 0
    X_RETURN_STATUS:=NULL;
    X_MSG_COUNT    :=NULL;
    X_MSG_DATA     :=NULL;
    -- X_RESPONSE:=null;
    -------------------------------------------------Calling API
    AP_VENDOR_PUB_PKG.UPDATE_VENDOR(P_API_VERSION => V_API_VERSION, P_INIT_MSG_LIST => V_INIT_MSG_LIST, P_COMMIT => V_COMMIT, P_VALIDATION_LEVEL => V_VALIDATION_LEVEL, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_COUNT => X_MSG_COUNT, X_MSG_DATA => X_MSG_DATA, p_vendor_rec => lr_vendor_rec, p_vendor_id => lr_existing_vendor_rec.vendor_id);
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
      ------Update for Tiebacking
    ELSE
      print_debug_msg(p_message=> l_program_step||'The API call ended with SUCESSS status', p_force=>true);
      l_process_flag:='Y';
      l_msg         :='';
      -----------------------Update the status if API successfully updated the record.
    END IF;
    UPDATE XX_AP_CLD_SUPPLIERS_STG XAS
    SET xas.supp_process_flag =DECODE (l_process_flag,'Y',gn_process_status_imported,'E',gn_process_status_imp_fail),---6
      XAS.PROCESS_FLAG        =DECODE(l_process_flag,'Y',NULL,'E','Y'),
      XAS.ERROR_MSG           = L_MSG
      ---  , xas.error_flag=DECODE( l_process_flag,'Y',NULL,'E','Y')
      -- PROCESS_FLAG          =l_process_flag
    WHERE xas.supp_process_flag =gn_process_status_validated
    AND xas.REQUEST_ID          = gn_request_id
    AND xas.supplier_name       =c_sup.supplier_name;
    COMMIT;
  END LOOP;
  OPEN c_sup_stats;
  FETCH c_sup_stats
  INTO l_sup_eligible_cnt,
    L_SUP_UPD_CNT,
    l_sup_upd_error_cnt,
    l_sup_val_not_load_cnt,
    l_sup_ready_process;
  CLOSE c_sup_stats;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  PRINT_DEBUG_MSG(P_MESSAGE => 'SUPPLIER - Records Successfully updated are '|| L_SUP_UPD_CNT, P_FORCE => TRUE);
  print_debug_msg(p_message => 'SUPPLIER - Records Errored while Update  are '|| l_sup_upd_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER - Records Eligible for Validation but Untouched  are '|| l_sup_eligible_cnt, p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
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
PROCEDURE update_supplier_sites(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2)
IS
  p_api_version      NUMBER;
  p_init_msg_list    VARCHAR2(200);
  p_commit           VARCHAR2(200);
  p_validation_level NUMBER;
  -- x_return_status    VARCHAR2(200);
  x_msg_count    NUMBER;
  x_msg_data     VARCHAR2(200);
  l_msg          VARCHAR2(2000);
  l_process_flag VARCHAR2(10);
  lr_vendor_site_rec ap_vendor_pub_pkg.r_vendor_site_rec_type;
  lr_existing_vendor_site_rec ap_supplier_sites_all%rowtype;
  lr_location_rec hz_location_v2pub.location_rec_type;
  p_vendor_site_id NUMBER;
  p_calling_prog   VARCHAR2(200);
  l_program_step   VARCHAR2 (100) := '';
  --l_process_flag VARCHAR2(10);
  ln_msg_index_num        NUMBER;
  l_loc_upd_flag          VARCHAR2(1) :='N';
  l_object_version_number NUMBER;
  CURSOR c_supplier_site
  IS
    SELECT *
    FROM XX_AP_CLD_SUPP_SITES_STG XAS
    WHERE xas.create_flag     ='N'--update
    AND XAS.SITE_PROCESS_FLAG =GN_PROCESS_STATUS_VALIDATED
    AND xas.REQUEST_ID        = gn_request_id;
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Staging
  --==============================================================================
  CURSOR c_sup_stats
  IS
    SELECT SUM(DECODE(site_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(site_process_flag,8,1,0)) -- updated
      ,
      SUM(DECODE(site_process_flag,9,1,0)) -- update failed
      ,
      SUM(DECODE(site_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(site_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_SITES_STG
    WHERE REQUEST_ID         = gn_request_id
    AND CREATE_FLAG          = 'N';
  l_sup_eligible_cnt     NUMBER := 0;
  l_sup_upd_cnt          NUMBER := 0;
  l_sup_upd_error_cnt    NUMBER := 0;
  l_sup_val_not_load_cnt NUMBER := 0;
  l_sup_ready_process    NUMBER := 0;
BEGIN
  -- Initialize apps session
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
      WHERE ASSA.VENDOR_SITE_CODE = C_SUP_SITE.VENDOR_SITE_CODE
      AND ASSA.VENDOR_ID          =C_SUP_SITE.VENDOR_ID
      AND assa.org_id             =c_sup_site.org_id;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||'Unable to derive the supplier site information for site id:' || lr_existing_vendor_site_rec.vendor_site_id, p_force=>true);
    END;
    -- Assign Vendor Site Details
    lr_vendor_site_rec.vendor_site_id   := lr_existing_vendor_site_rec.vendor_site_id;
    lr_vendor_site_rec.last_update_date := sysdate;
    --- lr_vendor_site_rec.last_updated_by  := 1119;
    lr_vendor_site_rec.vendor_id                    := lr_existing_vendor_site_rec.vendor_id;
    lr_vendor_site_rec.org_id                       := lr_existing_vendor_site_rec.org_id;
    lr_vendor_site_rec.rfq_only_site_flag           :=c_sup_site.rfq_only_site_flag;
    lr_vendor_site_rec.purchasing_site_flag         :=c_sup_site.purchasing_site_flag;
    lr_vendor_site_rec.pcard_site_flag              :=c_sup_site.pcard_site_flag;
    lr_vendor_site_rec.pay_site_flag                :=c_sup_site.pay_site_flag;
    lr_vendor_site_rec.primary_pay_site_flag        :=c_sup_site.primary_pay_site_flag;
    lr_vendor_site_rec.fax_area_code                :=c_sup_site.fax_area_code;
    lr_vendor_site_rec.fax                          :=c_sup_site.fax;
    lr_vendor_site_rec.inactive_date                :=c_sup_site.inactive_date;
    lr_vendor_site_rec.customer_num                 :=c_sup_site.customer_num;
    lr_vendor_site_rec.ship_via_lookup_code         :=c_sup_site.ship_via_lookup_code;
    lr_vendor_site_rec.freight_terms_lookup_code    :=c_sup_site.freight_terms_lookup_code;
    lr_vendor_site_rec.fob_lookup_code              :=c_sup_site.fob_lookup_code;
    lr_vendor_site_rec.terms_date_basis             :=c_sup_site.terms_date_basis;
    lr_vendor_site_rec.pay_group_lookup_code        :=c_sup_site.pay_group_lookup_code;
    lr_vendor_site_rec.payment_priority             :=c_sup_site.payment_priority;
    lr_vendor_site_rec.terms_name                   :=c_sup_site.terms_name;
    lr_vendor_site_rec.invoice_amount_limit         :=c_sup_site.invoice_amount_limit;
    lr_vendor_site_rec.pay_date_basis_lookup_code   :=c_sup_site.pay_date_basis_lookup_code;
    lr_vendor_site_rec.always_take_disc_flag        :=c_sup_site.always_take_disc_flag;
    lr_vendor_site_rec.invoice_currency_code        :=c_sup_site.invoice_currency_code;
    lr_vendor_site_rec.payment_currency_code        :=c_sup_site.payment_currency_code;
    lr_vendor_site_rec.hold_all_payments_flag       :=c_sup_site.hold_all_payments_flag;
    lr_vendor_site_rec.hold_future_payments_flag    :=c_sup_site.hold_future_payments_flag;
    lr_vendor_site_rec.hold_unmatched_invoices_flag :=c_sup_site.hold_unmatched_invoices_flag;
    lr_vendor_site_rec.hold_reason                  :=c_sup_site.hold_reason;
    lr_vendor_site_rec.hold_reason                  :=c_sup_site.purchasing_hold_reason;
    lr_vendor_site_rec.tax_reporting_site_flag      :=c_sup_site.tax_reporting_site_flag;
    lr_vendor_site_rec.exclude_freight_from_discount:=c_sup_site.exclude_freight_from_discount;
    lr_vendor_site_rec.pay_on_code                  :=c_sup_site.pay_on_code;
    lr_vendor_site_rec.pay_on_receipt_summary_code  :=c_sup_site.pay_on_receipt_summary_code;
    lr_vendor_site_rec.match_option                 :=c_sup_site.match_option;
    lr_vendor_site_rec.country_of_origin_code       :=c_sup_site.country_of_origin_code;
    lr_vendor_site_rec.create_debit_memo_flag       :=c_sup_site.create_debit_memo_flag;
    lr_vendor_site_rec.supplier_notif_method        :=c_sup_site.supplier_notif_method;
    lr_vendor_site_rec.email_address                :=c_sup_site.email_address;
    lr_vendor_site_rec.tolerance_name               :=c_sup_site.tolerance_name;
    lr_vendor_site_rec.gapless_inv_num_flag         :=c_sup_site.gapless_inv_num_flag;
    lr_vendor_site_rec.selling_company_identifier   :=c_sup_site.selling_company_identifier;
    lr_vendor_site_rec.bank_charge_bearer           :=c_sup_site.bank_charge_bearer;
    lr_vendor_site_rec.vat_code                     :=c_sup_site.vat_code;
    lr_vendor_site_rec.vat_registration_num         :=c_sup_site.vat_registration_num;
    lr_vendor_site_rec.remit_advice_delivery_method :=c_sup_site.remit_advice_delivery_method;
    lr_vendor_site_rec.remittance_email             :=c_sup_site.remittance_email;
    lr_vendor_site_rec.attribute_category           :=c_sup_site.attribute_category;
    lr_vendor_site_rec.attribute1                   :=c_sup_site.attribute1;
    lr_vendor_site_rec.attribute2                   :=c_sup_site.attribute2;
    lr_vendor_site_rec.attribute3                   :=c_sup_site.attribute3;
    lr_vendor_site_rec.attribute4                   :=c_sup_site.attribute4;
    lr_vendor_site_rec.attribute5                   :=c_sup_site.attribute5;
    lr_vendor_site_rec.attribute6                   :=c_sup_site.attribute6;
    lr_vendor_site_rec.attribute8                   :=c_sup_site.attribute8;
    lr_vendor_site_rec.attribute9                   :=c_sup_site.attribute9;
    lr_vendor_site_rec.attribute10                  :=c_sup_site.attribute10;
    lr_vendor_site_rec.attribute11                  :=c_sup_site.attribute11;
    lr_vendor_site_rec.attribute12                  :=c_sup_site.attribute12;
    lr_vendor_site_rec.attribute14                  :=c_sup_site.attribute14;
    lr_vendor_site_rec.attribute15                  :=c_sup_site.attribute15;
    lr_vendor_site_rec.phone                        :=c_sup_site.phone_number;
    lr_vendor_site_rec.area_code                    :=c_sup_site.phone_area_code;
    lr_vendor_site_rec.province                     :=c_sup_site.province;
    lr_vendor_site_rec.state                        :=c_sup_site.state;
    lr_vendor_site_rec.city                         :=c_sup_site.city;
    lr_vendor_site_rec.address_line2                :=c_sup_site.address_line2;
    lr_vendor_site_rec.address_line1                :=c_sup_site.address_line1;
    lr_vendor_site_rec.country                      :=c_sup_site.country;
    FND_MSG_PUB.INITIALIZE; --to make msg_count 0
    X_RETURN_STATUS:=NULL;
    X_MSG_COUNT    :=NULL;
    X_MSG_DATA     :=NULL;
    --X_RESPONSE:=null;
    -------------------------Calling Site API
    ap_vendor_pub_pkg.update_vendor_site_public--UPDATE_VENDOR_SITE
    (p_api_version => p_api_version, p_init_msg_list => p_init_msg_list, p_commit => p_commit, p_validation_level => p_validation_level, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data, p_vendor_site_rec => lr_vendor_site_rec, p_vendor_site_id => lr_vendor_site_rec.vendor_site_id, p_calling_prog => p_calling_prog);
    COMMIT;
    ------------------------------------------------------------------
    print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS = ' || x_return_status, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
    print_debug_msg(p_message=> l_program_step||'X_MSG_COUNT = ' || x_msg_count, p_force=>true);
    IF x_msg_count > 0 THEN
      print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
      print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
      FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
      LOOP
        --- l_msg := fnd_msg_pub.get(p_msg_index => i, p_encoded => fnd_api.g_false);
        fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
        print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
      END LOOP;
      l_process_flag:='E';
      ------Update for Tiebacking
    ELSE
      print_debug_msg(p_message=> l_program_step||'The API call ended with SUCESSS status', p_force=>true);
      l_process_flag:='Y';
      l_msg         :='';
      -----------------------Update the status if API successfully updated the record.
    END IF;
    print_debug_msg(p_message=> l_program_step||'l_process_flag '||l_process_flag, p_force=>true);
    PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'c_sup_site.supplier_name '||C_SUP_SITE.SUPPLIER_NAME, P_FORCE=>TRUE);
    print_debug_msg(p_message=> l_program_step||'fnd_global.conc_request_id '||fnd_global.conc_request_id, p_force=>true);
    print_debug_msg(p_message=> l_program_step||'c_sup_site.vendor_site_code '||c_sup_site.vendor_site_code, p_force=>true);
    BEGIN
      UPDATE XX_AP_CLD_SUPP_SITES_STG XAS
      SET xas.site_process_flag      =DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),---6 ,---6
        XAS.ERROR_FLAG               =DECODE( L_PROCESS_FLAG,'Y',NULL,'E','Y'),
        XAS.ERROR_MSG                = L_MSG,
        PROCESS_FLAG                 =l_process_flag
      WHERE xas.site_process_flag    =gn_process_status_validated
      AND XAS.REQUEST_ID             = gn_request_id
      AND xas.supplier_name          = c_sup_site.supplier_name
      AND TRIM(XAS.VENDOR_SITE_CODE) =TRIM(C_SUP_SITE.VENDOR_SITE_CODE)
      AND XAS.org_id                 =c_sup_site.org_id;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message=> l_program_step||'In Exception to update records', p_force=>true);
    END ;
  END LOOP;
  OPEN c_sup_stats;
  FETCH c_sup_stats
  INTO l_sup_eligible_cnt,
    L_SUP_UPD_CNT,
    l_sup_upd_error_cnt,
    l_sup_val_not_load_cnt,
    l_sup_ready_process;
  CLOSE c_sup_stats;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  PRINT_DEBUG_MSG(P_MESSAGE => 'SUPPLIER SITE - Records Successfully updated are '|| L_SUP_UPD_CNT, P_FORCE => TRUE);
  print_debug_msg(p_message => 'SUPPLIER SITE- Records Errored while Update  are '|| l_sup_upd_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER - Records Eligible for Validation but Untouched  are '|| l_sup_eligible_cnt, p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
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
PROCEDURE update_supplier_contact(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2)
IS
  lv_vendor_contact_rec ap_vendor_pub_pkg.r_vendor_contact_rec_type;
  --
  p_api_version      NUMBER;
  p_init_msg_list    VARCHAR2(200);
  p_commit           VARCHAR2(200);
  p_validation_level NUMBER;
  ---x_return_status    VARCHAR2(200);
  x_msg_count      NUMBER;
  x_msg_data       VARCHAR2(200);
  p_calling_prog   VARCHAR2(200);
  l_program_step   VARCHAR2 (100) := '';
  ln_msg_index_num NUMBER;
  l_msg            VARCHAR2(2000);
  l_process_flag   VARCHAR2(10);
  l_email_address hz_contact_points.email_address%type;
  l_phone_number hz_contact_points.phone_number%type;
  l_fax_number hz_contact_points.phone_number%type;
  l_phone_area_code hz_contact_points.phone_area_code%type;
  l_fax_area_code hz_contact_points.phone_area_code%type;
  CURSOR c_cont
  IS
    SELECT *
    FROM XX_AP_CLD_SUPP_CONTACT_STG XAS
    WHERE xas.CREATE_FLAG        ='N'--update
    AND XAS.CONTACT_PROCESS_FLAG =GN_PROCESS_STATUS_VALIDATED
    AND xas.REQUEST_ID           = gn_request_id
    AND cont_target              ='EBS';
  CURSOR c_contact_infor(v_vendor_id NUMBER,v_vendor_site_id NUMBER,v_first_name VARCHAR2,v_last_name VARCHAR2)
  IS
    SELECT DISTINCT hpr.party_id,
      asu.segment1 supp_num ,
      asu.vendor_name ,
      hpc.party_name contact_name ,
      hpr.primary_phone_country_code cnt_cntry ,
      hpr.primary_phone_area_code cnt_area ,
      hpr.primary_phone_number phone_number ,
      assa.vendor_site_code ,
      assa.vendor_site_id ,
      asco.vendor_contact_id,
      ---hpcp.email_address,
      hpc.person_first_name first_name,
      hpc.person_last_name last_name---contact_id
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
    AND ASU.VENDOR_ID               =V_VENDOR_ID
    AND assa.vendor_site_id         =v_vendor_site_id
    AND hpc.person_first_name       =v_first_name
    AND hpc.person_last_name        =v_last_name;
  ----
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Staging
  --==============================================================================
  CURSOR c_sup_stats
  IS
    SELECT SUM(DECODE(contact_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(contact_process_flag,8,1,0)) -- updated
      ,
      SUM(DECODE(contact_process_flag,9,1,0)) -- update failed
      ,
      SUM(DECODE(contact_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(contact_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_CONTACT_STG
    WHERE REQUEST_ID         = gn_request_id
    AND CREATE_FLAG          ='N';
  l_sup_eligible_cnt     NUMBER := 0;
  l_sup_upd_cnt          NUMBER := 0;
  l_sup_upd_error_cnt    NUMBER := 0;
  L_SUP_VAL_NOT_LOAD_CNT NUMBER := 0;
  l_sup_ready_process    NUMBER := 0;
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
    FOR r_cont_info IN c_contact_infor(r_cont.vendor_id , r_cont.vendor_site_id ,r_cont.first_name,r_cont.last_name )
    LOOP
      BEGIN
        SELECT phone_number
        INTO l_phone_number
        FROM hz_contact_points hpcp
        WHERE phone_line_type  ='GEN'
        AND contact_point_type ='PHONE'
        AND hpcp.owner_table_id=r_cont_info.party_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_phone_number:=NULL;
      END;
      BEGIN
        SELECT phone_number
        INTO l_fax_number
        FROM hz_contact_points hpcp
        WHERE phone_line_type  ='FAX'
        AND contact_point_type ='PHONE'
        AND hpcp.owner_table_id=r_cont_info.party_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_fax_number:=NULL;
      END;
      BEGIN
        SELECT email_address
        INTO l_email_address
        FROM hz_contact_points hpcp
        WHERE 1                =1--phone_line_type='FAX'
        AND contact_point_type ='EMAIL'
        AND hpcp.owner_table_id=r_cont_info.party_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_email_address:=NULL;
      END;
      BEGIN
        SELECT phone_area_code
        INTO l_phone_area_code
        FROM hz_contact_points hpcp
        WHERE 1                =1
        AND phone_line_type    ='GEN'
        AND contact_point_type ='PHONE'
        AND hpcp.owner_table_id=r_cont_info.party_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_phone_area_code:=NULL;
      END;
      BEGIN
        SELECT phone_area_code
        INTO l_fax_area_code
        FROM hz_contact_points hpcp
        WHERE 1                =1
        AND phone_line_type    ='GEN'
        AND contact_point_type ='PHONE'
        AND hpcp.owner_table_id=r_cont_info.party_id;
      EXCEPTION
      WHEN OTHERS THEN
        l_fax_area_code:=NULL;
      END;
      IF NVL(L_PHONE_NUMBER,'X')               <> NVL(R_CONT.PHONE,'X') OR NVL(l_email_address,'X') <> NVL(r_cont.email_address,'X') OR NVL(l_fax_number,'X') <> NVL(r_cont.fax,'X') OR NVL(l_phone_area_code,'X') <> NVL(r_cont.area_code,'X') OR NVL(L_FAX_AREA_CODE,'X') <> NVL(R_CONT.FAX_AREA_CODE,'X') THEN
        lv_vendor_contact_rec.vendor_contact_id:=r_cont_info.vendor_contact_id;
        lv_vendor_contact_rec.phone            :=r_cont.phone;
        lv_vendor_contact_rec.email_address    :=r_cont.email_address;
        lv_vendor_contact_rec.fax_phone        :=r_cont.fax;
        lv_vendor_contact_rec.fax_area_code    :=r_cont.fax_area_code;
        lv_vendor_contact_rec.area_code        :=r_cont.area_code;
        FND_MSG_PUB.INITIALIZE; --to make msg_count 0
        X_RETURN_STATUS:=NULL;
        X_MSG_COUNT    :=NULL;
        X_MSG_DATA     :=NULL;
        ---X_RESPONSE:=null;
        ap_vendor_pub_pkg.update_vendor_contact_public (p_api_version => 1.0, p_init_msg_list => fnd_api.g_false, p_commit => fnd_api.g_false, p_validation_level => fnd_api.g_valid_level_full, p_vendor_contact_rec => lv_vendor_contact_rec, x_return_status => x_return_status, x_msg_count => x_msg_count, x_msg_data => x_msg_data );
        COMMIT;
        print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS = ' || x_return_status, p_force=>true);
        print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
        print_debug_msg(p_message=> l_program_step||'X_MSG_COUNT = ' || x_msg_count, p_force=>true);
        IF X_RETURN_STATUS <>'S' AND x_msg_count > 0 THEN
          print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
          print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
          FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
          LOOP
            fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
            print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
          END LOOP;
          l_process_flag:='E';
          ------Update for Tiebacking
        ELSE
          PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'The API call ended with SUCESSS status', P_FORCE=>TRUE);
          l_process_flag:='Y';
          l_msg         :='';
          -----------------------Update the status if API successfully updated the record.
        END IF;
        BEGIN
          UPDATE XX_AP_CLD_SUPP_CONTACT_STG XAS
          SET XAS.CONTACT_PROCESS_FLAG   =DECODE (L_PROCESS_FLAG,'Y',GN_PROCESS_STATUS_IMPORTED ,'E',GN_PROCESS_STATUS_IMP_FAIL),---6 ,---6
            XAS.ERROR_FLAG               =DECODE( L_PROCESS_FLAG,'Y',NULL,'E','Y'),
            xas.ERROR_MSG                = l_msg,
            PROCESS_FLAG                 =l_process_flag
          WHERE XAS.CONTACT_PROCESS_FLAG =GN_PROCESS_STATUS_VALIDATED
          AND XAS.REQUEST_ID             = gn_request_id
          AND XAS.SUPPLIER_NUMBER        =R_CONT.SUPPLIER_NUMBER
          AND TRIM(XAS.FIRST_NAME)       =TRIM(R_CONT.FIRST_NAME)
          AND trim(xas.LAST_name)        =trim(r_cont.last_name)
          AND trim(xas.vendor_site_code) =trim(r_cont.vendor_site_code);
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          print_debug_msg(p_message=> l_program_step||'In Exception to update records'||SQLERRM, p_force=>true);
        END ;
      END IF;
    END LOOP;
  END LOOP;
  OPEN c_sup_stats;
  FETCH c_sup_stats
  INTO l_sup_eligible_cnt,
    L_SUP_UPD_CNT,
    l_sup_upd_error_cnt,
    l_sup_val_not_load_cnt,
    l_sup_ready_process;
  CLOSE c_sup_stats;
  PRINT_DEBUG_MSG(P_MESSAGE => '--------------------------------------------------------------------------------------------', P_FORCE => TRUE);
  PRINT_DEBUG_MSG(P_MESSAGE => 'SUPPLIER CONTACT - Records Successfully updated are '|| L_SUP_UPD_CNT, P_FORCE => TRUE);
  print_debug_msg(p_message => 'SUPPLIER CONTACT- Records Errored while Update  are '|| l_sup_upd_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER - Records Eligible for Validation but Untouched  are '|| l_sup_eligible_cnt, p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,SQLCODE||','||sqlerrm);
END update_supplier_contact;
--+============================================================================+
--| Name          :Update_supplier_contact for Supplier                                     |
--| Description   : This procedure will update supplier conatct details using API  |
--|                                                                            |
--| Parameters    :x_ret_code OUT NUMBER ,
--|                 x_return_status OUT VARCHAR2 ,
--|                 x_err_buf OUT VARCHAR2                           |
--|                                                                            |
--| Returns       : N/A
--|
--|                                                                            |
--+============================================================================+
PROCEDURE CHECK_BANK_ACC_EXISTS(
    p_bank_id     IN NUMBER ,
    p_branch_id   IN NUMBER ,
    P_ACCT_NUMBER IN VARCHAR2,
    P_ACCT_NAME   IN VARCHAR2,
    p_currency VARCHAR2,
    p_country_code IN VARCHAR2,
    P_ACCOUNT_ID OUT NUMBER)
IS
  --lv_vendor_contact_rec ap_vendor_pub_pkg.r_vendor_contact_rec_type;
  --
  p_api_version      NUMBER;
  p_init_msg_list    VARCHAR2(200);
  p_commit           VARCHAR2(200);
  P_VALIDATION_LEVEL NUMBER;
  x_return_status    VARCHAR2(200);
  x_msg_count        NUMBER;
  x_msg_data         VARCHAR2(200);
  p_calling_prog     VARCHAR2(200);
  L_PROGRAM_STEP     VARCHAR2 (100) := '';
  --ln_msg_index_num NUMBER;
  L_MSG        VARCHAR2(2000);
  L_ACCT_ID    NUMBER;
  L_START_DATE DATE;
  L_END_DATE   DATE;
  X_RESPONSE IBY_FNDCPT_COMMON_PUB.RESULT_REC_TYPE;
  ln_msg_index_num NUMBER;
BEGIN
  -- Initialize apps session
  -- Assign Basic Values
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';
  FND_MSG_PUB.INITIALIZE; --to make msg_count 0
  X_RETURN_STATUS:=NULL;
  X_MSG_COUNT    :=NULL;
  X_MSG_DATA     :=NULL;
  X_RESPONSE     :=NULL;
  IBY_EXT_BANKACCT_PUB.CHECK_EXT_ACCT_EXIST (P_API_VERSION => 1.0, P_INIT_MSG_LIST => FND_API.G_FALSE, P_BANK_ID=>P_BANK_ID, P_BRANCH_ID=>P_BRANCH_ID, P_ACCT_NUMBER=>P_ACCT_NUMBER, P_ACCT_NAME=>P_ACCT_NAME, P_CURRENCY=>P_CURRENCY, P_COUNTRY_CODE=>P_COUNTRY_CODE, x_acct_id=>l_acct_id, X_START_DATE=>L_START_DATE, x_end_date=>l_end_date, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_COUNT => X_MSG_COUNT, X_MSG_DATA=>X_MSG_DATA, x_response=>x_response);
  COMMIT;
  print_debug_msg(p_message=> l_program_step||'X_RETURN_STATUS = ' || x_return_status, p_force=>true);
  print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
  PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'X_MSG_COUNT = ' || X_MSG_COUNT, P_FORCE=>TRUE);
  print_debug_msg(p_message=> l_program_step||'Account Id = ' || l_acct_id, p_force=>true);
  IF X_RETURN_STATUS <>'S' AND x_msg_count > 0 THEN
    print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
    print_debug_msg(p_message=> l_program_step||'fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
    FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
    LOOP
      fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
      print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
    END LOOP;
  ELSE
    PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'The API call ended with SUCESSS status', P_FORCE=>TRUE);
    --  l_process_flag:='Y';
    -- l_msg         :='';
    -----------------------Update the status if API successfully updated the record.
  END IF;
  p_account_id:=l_acct_id;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG,SQLCODE||','||SQLERRM);
  p_account_id:=NULL;
END Check_bank_acc_exists;
--+============================================================================+
--| Name          : Attach_bank_assignments                                    |
--| Description   : This procedure will attach_bank_assignments using API  |
--|                                                                            |
--| Parameters    : x_ret_code OUT NUMBER ,
--|                 x_return_status OUT VARCHAR2 ,
--|                 x_err_buf OUT VARCHAR2                           |
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
  -- l_bank_party_id iby_ext_banks_v.bank_party_id%type;
  -- l_branch_party_id iby_ext_bank_branches_v.branch_party_id%type;
  --
  p_api_version      NUMBER;
  p_init_msg_list    VARCHAR2(200);
  p_commit           VARCHAR2(200);
  p_validation_level NUMBER;
  ---x_return_status    VARCHAR2(200);
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
  l_fax_area_code hz_contact_points.phone_area_code%type;
  l_account_id NUMBER;
  X_RESPONSE IBY_FNDCPT_COMMON_PUB.RESULT_REC_TYPE;
  L_ASSIGN_ID           NUMBER;
  l_joint_acct_owner_id NUMBER;
  CURSOR c_sup_bank
  IS
    SELECT *
    FROM XX_AP_CLD_SUPP_BNKACT_STG xas
    WHERE 1                     =1
    AND xas.CREATE_FLAG         ='Y'
    AND XAS.BNKACT_PROCESS_FLAG =GN_PROCESS_STATUS_VALIDATED
    AND xas.REQUEST_ID          = gn_request_id;
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
        LV_ORG_ID
      FROM ap_suppliers aps,
        ap_supplier_sites_all assa
      WHERE aps.vendor_id     = assa.vendor_id
      AND APS.VENDOR_ID       =R_SUP_BANK.VENDOR_ID
      AND assa.vendor_site_id = r_sup_bank.vendor_site_id;
      ---  AND assa.vendor_site_code = r_sup_bank.vendor_site_code;
    EXCEPTION
    WHEN OTHERS THEN
      PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'Error- Get supp_site_id and supp_party_site_id' || SQLCODE || SQLERRM, P_FORCE=>TRUE);
    END;
    IF R_SUP_BANK.account_id IS NOT NULL AND R_SUP_BANK.INSTRUMENT_USES_ID IS NULL THEN--Joint Owner pending
      ----------------------Assigning Attributes
      p_payee.supplier_site_id := lv_supp_site_id;
      p_payee.party_id         := lv_acct_owner_party_id;
      p_payee.party_site_id    := lv_supp_party_site_id;
      p_payee.payment_function := 'PAYABLES_DISB';
      p_payee.org_id           := lv_org_id;
      p_payee.org_type         := 'OPERATING_UNIT';
      -- Assignment Values
      P_ASSIGNMENT_ATTRIBS.INSTRUMENT.INSTRUMENT_TYPE := 'BANKACCOUNT';
      L_ACCOUNT_ID                                    :=R_SUP_BANK.ACCOUNT_ID;
      print_debug_msg(p_message=> l_program_step||'L_ACCOUNT_ID '||L_ACCOUNT_ID, p_force=>true);
      p_assignment_attribs.instrument.instrument_id:=l_account_id;
      -- External Bank Account ID
      p_assignment_attribs.priority   := 1;
      P_ASSIGNMENT_ATTRIBS.START_DATE := SYSDATE;
      ------------------Calling API to check Joint Owner exists or no
      FND_MSG_PUB.INITIALIZE; --to make msg_count 0
      X_RETURN_STATUS:=NULL;
      X_MSG_COUNT    :=NULL;
      X_MSG_DATA     :=NULL;
      X_RESPONSE     :=NULL;
      IBY_EXT_BANKACCT_PUB.check_bank_acct_owner ( P_API_VERSION =>P_API_VERSION, P_INIT_MSG_LIST=>P_INIT_MSG_LIST, p_bank_acct_id=>L_ACCOUNT_ID, P_ACCT_OWNER_PARTY_ID =>LV_ACCT_OWNER_PARTY_ID,
      --  X_JOINT_ACCT_OWNER_ID=>L_JOINT_ACCT_OWNER_ID,
      X_RETURN_STATUS=>X_RETURN_STATUS, X_MSG_COUNT=>X_MSG_COUNT, X_MSG_DATA=>X_MSG_DATA, X_RESPONSE=>X_RESPONSE );
      IF X_RETURN_STATUS <>'S' THEN --------------No join owner exists
        FND_MSG_PUB.INITIALIZE;                 --to make msg_count 0
        X_RETURN_STATUS:=NULL;
        X_MSG_COUNT    :=NULL;
        X_MSG_DATA     :=NULL;
        X_RESPONSE     :=NULL;
        -------------------------Calling Joint Account Owner API
        IBY_EXT_BANKACCT_PUB.ADD_JOINT_ACCOUNT_OWNER ( P_API_VERSION =>P_API_VERSION, P_INIT_MSG_LIST=>P_INIT_MSG_LIST, P_BANK_ACCOUNT_ID=>L_ACCOUNT_ID, P_ACCT_OWNER_PARTY_ID =>LV_ACCT_OWNER_PARTY_ID, X_JOINT_ACCT_OWNER_ID=>L_JOINT_ACCT_OWNER_ID, X_RETURN_STATUS=>X_RETURN_STATUS, X_MSG_COUNT=>X_MSG_COUNT, X_MSG_DATA=>X_MSG_DATA, X_RESPONSE=>X_RESPONSE );
        PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'L_JOINT_ACCT_OWNER_ID = ' || L_JOINT_ACCT_OWNER_ID, P_FORCE=>TRUE);
        print_debug_msg(p_message=> l_program_step||' ADD_JOINT_ACCOUNT_OWNER X_RETURN_STATUS = ' || x_return_status, p_force=>true);
        PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'ADD_JOINT_ACCOUNT_OWNER fnd_api.g_ret_sts_success ' || FND_API.G_RET_STS_SUCCESS , P_FORCE=>TRUE);
        PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'ADD_JOINT_ACCOUNT_OWNER X_MSG_COUNT = ' || X_MSG_COUNT, P_FORCE=>TRUE);
      END IF;
      FND_MSG_PUB.INITIALIZE; --to make msg_count 0
      X_RETURN_STATUS:=NULL;
      X_MSG_COUNT    :=NULL;
      X_MSG_DATA     :=NULL;
      X_RESPONSE     :=NULL;
      --------------------Call the API for istr assignemtn
      IBY_DISBURSEMENT_SETUP_PUB.SET_PAYEE_INSTR_ASSIGNMENT (P_API_VERSION => P_API_VERSION, P_INIT_MSG_LIST => P_INIT_MSG_LIST, P_COMMIT => P_COMMIT, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_COUNT => X_MSG_COUNT, X_MSG_DATA => X_MSG_DATA, P_PAYEE => P_PAYEE, P_ASSIGNMENT_ATTRIBS => P_ASSIGNMENT_ATTRIBS, X_ASSIGN_ID => l_ASSIGN_ID, x_response => x_response );
      COMMIT;
      print_debug_msg(p_message=> l_program_step||' SET_PAYEE_INSTR_ASSIGNMENT X_ASSIGN_ID = ' || l_ASSIGN_ID, p_force=>true);
      print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT X_RETURN_STATUS = ' || x_return_status, p_force=>true);
      PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'SET_PAYEE_INSTR_ASSIGNMENT fnd_api.g_ret_sts_success ' || FND_API.G_RET_STS_SUCCESS , P_FORCE=>TRUE);
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
        PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'The API call ended with SUCESSS status' , P_FORCE=>TRUE);
        l_process_flag:='Y';
        L_MSG         :='';
      END IF;
    END IF;--R_SUP_BANK.account_id IS NOT NULL AND R_SUP_BANK.INSTRUMENT_USES_ID IS NULL
    ------------------------------When Account ID is null create new Account and instrumnets
    IF R_SUP_BANK.account_id IS NULL THEN
      -- L_BRANCH_PARTY_ID                    :=R_SUP_BANK.BRANCH_ID;
      -- l_bank_party_id                      :=R_SUP_BANK.bank_id;
      x_bank_branch_rec.currency           :=r_sup_bank.currency_code;
      x_bank_branch_rec.branch_id          :=R_SUP_BANK.BRANCH_ID;
      x_bank_branch_rec.bank_id            :=R_SUP_BANK.bank_id;
      x_bank_branch_rec.acct_owner_party_id:=lv_acct_owner_party_id;
      x_bank_branch_rec.country_code       :=r_sup_bank.country_code;--'US';
      x_bank_branch_rec.bank_account_name  := r_sup_bank.bank_account_name;
      X_BANK_BRANCH_REC.BANK_ACCOUNT_NUM   :=R_SUP_BANK.BANK_ACCOUNT_NUM;
      FND_MSG_PUB.INITIALIZE; --to make msg_count 0
      X_RETURN_STATUS:=NULL;
      X_MSG_COUNT    :=NULL;
      X_MSG_DATA     :=NULL;
      X_RESPONSE     :=NULL;
      IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT ( P_API_VERSION => 1.0, P_INIT_MSG_LIST => FND_API.G_TRUE, p_ext_bank_acct_rec => x_bank_branch_rec, P_ASSOCIATION_LEVEL => 'SS', p_supplier_site_id => lv_supp_site_id, P_PARTY_SITE_ID => LV_SUPP_PARTY_SITE_ID, p_org_id => lv_org_id, p_org_type => 'OPERATING_UNIT', X_ACCT_ID => L_ACCOUNT_ID, x_return_status => x_return_status, X_MSG_COUNT => X_MSG_COUNT, x_msg_data =>x_msg_data, x_response => x_response );
      PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'create_ext_bank_acct l_account_id = ' || L_ACCOUNT_ID, P_FORCE=>TRUE);
      print_debug_msg(p_message=> l_program_step||'create_ext_bank_acct X_RETURN_STATUS = ' || x_return_status, p_force=>true);
      PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'create_ext_bank_acct fnd_api.g_ret_sts_success ' || FND_API.G_RET_STS_SUCCESS , P_FORCE=>TRUE);
      PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'create_ext_bank_acct X_MSG_COUNT = ' || X_MSG_COUNT, P_FORCE=>TRUE);
      COMMIT;
      IF X_RETURN_STATUS = 'E' THEN
        print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT x_return_status ' || x_return_status , p_force=>true);
        print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT fnd_api.g_ret_sts_success ' || fnd_api.g_ret_sts_success , p_force=>true);
        FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
        LOOP
          fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
          print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
        END LOOP;
        l_process_flag:='E';
      ELSE
        PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||'The API call ended with SUCESSS status' , P_FORCE=>TRUE);
        l_process_flag:='Y';
        l_msg         :='';
      END IF;
      /*  ELSE
      l_process_flag:='E';---IF l_account_id            IS NOT NULL
      END IF;    */
      ---IF R_SUP_BANK.account_id
    END IF; ---IF R_SUP_BANK.account_id
    BEGIN
      UPDATE XX_AP_CLD_SUPP_BNKACT_STG XAS
      SET XAS.BNKACT_PROCESS_FLAG =DECODE (L_PROCESS_FLAG,'Y',GN_PROCESS_STATUS_IMPORTED ,'E',GN_PROCESS_STATUS_IMP_FAIL),---6
        xas.ERROR_FLAG            =DECODE( l_process_flag,'Y',NULL,'E','Y'),
        XAS.ERROR_MSG             = L_MSG,
        --  xas.instrument_uses_id=l_ASSIGN_ID,
        XAS.ACCOUNT_ID               =L_ACCOUNT_ID,
        process_Flag                 =l_process_flag
      WHERE XAS.BNKACT_PROCESS_FLAG  =GN_PROCESS_STATUS_VALIDATED
      AND XAS.REQUEST_ID             = GN_REQUEST_ID
      AND xas.supplier_num           =r_sup_bank.supplier_num
      AND TRIM(XAS.VENDOR_SITE_CODE) =TRIM(R_SUP_BANK.VENDOR_SITE_CODE)
      AND BANK_ACCOUNT_NUM           =R_SUP_BANK.BANK_ACCOUNT_NUM
      AND BANK_NAME                  =R_SUP_BANK.BANK_NAME
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
--+============================================================================+
--| Name          : validate_Supplier_records                                    |
--| Description   : This procedure will validate_Supplier_records using standard custom validation  |
--|                                                                            |
--| Parameters    : x_ret_code OUT NUMBER ,
--|                 x_return_status OUT VARCHAR2 ,
--|                 x_err_buf OUT VARCHAR2                           |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE validate_supplier_records(
    x_val_records OUT nocopy   NUMBER ,
    x_inval_records OUT nocopy NUMBER ,
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
type l_sup_tab
IS
  TABLE OF XX_AP_CLD_SUPPLIERS_STG%rowtype INDEX BY binary_integer;
  l_supplier_type l_sup_tab;
  --=================================================================
  -- Cursor Declarations for Suppliers
  --=================================================================
  CURSOR c_supplier
  IS
    SELECT xas.*
    FROM XX_AP_CLD_SUPPLIERS_STG xas
    WHERE XAS.SUPP_PROCESS_FLAG IN (GN_PROCESS_STATUS_INPROCESS)
    AND xas.REQUEST_ID           = gn_request_id;
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Staging table
  --=================================================================
  CURSOR c_dup_supplier_chk_stg
  IS
    SELECT trim(upper(xas.supplier_name)),
      COUNT(1)
    FROM XX_AP_CLD_SUPPLIERS_STG xas
    WHERE XAS.SUPP_PROCESS_FLAG IN (GN_PROCESS_STATUS_INPROCESS)
    AND xas.REQUEST_ID           = gn_request_id
    GROUP BY trim(upper(xas.supplier_name))
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
    AND upper(vendor_name) = upper(c_supplier_name)
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
    AND TRUNC(sysdate) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active, sysdate+1))
    AND lookup_code=c_supplier_type;
  ----   AND meaning = c_supplier_type;
  --==========================================================================================
  -- Cursor Declarations for Income Tax Type
  --==========================================================================================
  CURSOR c_income_tax_type (c_income_tax_type VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM ap_income_tax_types
    WHERE income_tax_type                     = c_income_tax_type
    AND TRUNC(NVL(inactive_date, sysdate+1)) >= TRUNC(sysdate);
  --==========================================================================================
  -- Cursor Declarations for Country Code
  --==========================================================================================
  CURSOR c_get_country_code (c_country VARCHAR2)
  IS
    SELECT territory_code
    FROM fnd_territories_tl
    WHERE territory_code = c_country
    AND language               = userenv ('LANG');
  --==========================================================================================
  -- Cursor Declarations for Operating Unit
  --==========================================================================================
  CURSOR c_operating_unit (c_oper_unit VARCHAR2)
  IS
    SELECT organization_id
    FROM hr_operating_units
    WHERE name = c_oper_unit
    AND sysdate BETWEEN TRUNC(date_from) AND TRUNC(NVL(date_to,sysdate+1));
  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value
  --==========================================================================================
  CURSOR c_get_fnd_lookup_code (c_lookup_type VARCHAR2, c_lookup_meaning VARCHAR2, c_application_id NUMBER)
  IS
    SELECT lookup_code
    FROM fnd_lookup_values
    WHERE lookup_type       = c_lookup_type
    AND meaning             = c_lookup_meaning
    AND source_lang         = 'US'
    AND view_application_id = c_application_id
    AND TRUNC(sysdate) BETWEEN TRUNC(NVL(start_date_active, sysdate-1)) AND TRUNC(NVL(end_date_active, sysdate+1));
  --==========================================================================================
  -- Cursor Declarations for any FND_LOOKUP value count giving lookup code
  --==========================================================================================
  CURSOR c_get_fnd_lookup_code_cnt (c_lookup_type VARCHAR2, c_lookup_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM fnd_lookup_values
    WHERE lookup_type = c_lookup_type
    AND lookup_code   = c_lookup_code
	and Enabled_flag='Y';
   ---- AND TRUNC(sysdate) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active, sysdate+1));
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Staging
  --==============================================================================
  CURSOR c_sup_stats
  IS
    SELECT SUM(DECODE(supp_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(supp_process_flag,6,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(supp_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(supp_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(supp_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPPLIERS_STG
    WHERE REQUEST_ID = gn_request_id;
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_msg_count   NUMBER        := 0;
  l_trans_count NUMBER        := 0;
  l_inval_records pls_integer := 0;
  l_val_records pls_integer   := 0;
  l_sup_idx pls_integer       := 0;
  l_sup_site_idx pls_integer  := 0;
  l_sup_cont_idx pls_integer  := 0;
  l_procedure            VARCHAR2 (30)   := 'validate_Supplier_records';
  l_program_step         VARCHAR2 (100)  := '';
  l_ret_code             NUMBER;
  l_return_status        VARCHAR2 (100);
  l_err_buff             VARCHAR2 (4000);
  l_sup_fail_site_depend VARCHAR2(2000);
  l_error_message        VARCHAR2(4000) := '';
  l_site_country_code    VARCHAR2(15);
  l_sup_name ap_suppliers.vendor_name%type;
  l_segment1 ap_suppliers.segment1%type;
  l_tax_payer_id ap_suppliers.num_1099%type;
  l_vendor_exist_flag VARCHAR2(1) := 'N';
  l_vendor_id         NUMBER;
  l_party_id          NUMBER;
  l_obj_ver_no        NUMBER;
  l_sup_type_code ap_suppliers.vendor_type_lookup_code%type;
  l_income_tax_type_cnt  NUMBER;
  l_org_id               NUMBER;
  l_org_id_cnt           NUMBER;
  l_sup_site_exist_cnt   NUMBER;
  l_sup_site_create_flag VARCHAR2(1) := 'N';
  l_site_code            VARCHAR2(40);
  l_address_purpose      VARCHAR2(10);
  l_terms_id             NUMBER;
  l_purchasing_site_flag VARCHAR2(1);
  l_pay_site_flag        VARCHAR2(1);
  l_payment_method iby_payment_methods_b.payment_method_code%type;
  l_pay_group_code ap_suppliers.pay_group_lookup_code%type;
  l_ship_to_location_id NUMBER;
  l_bill_to_location_id NUMBER;
  l_ccid                NUMBER;
  l_cont_phone_num      VARCHAR2(20);
  l_org_type_code fnd_lookup_values.lookup_code%type;
  l_gcc_segment3 gl_code_combinations.segment3%type;
  l_fob_code fnd_lookup_values.lookup_code%type;
  l_freight_terms_code fnd_lookup_values.lookup_code%type;
  l_pay_method_cnt NUMBER;
  l_tolerance_id   NUMBER;
  l_tolerance_name ap_tolerance_templates.tolerance_name%type;
  l_deduct_bank_chrg VARCHAR2(5);
  l_inv_match_option VARCHAR2(25);
  l_inv_cur_code fnd_currencies_vl.currency_code%type;
  l_inv_curr_code_cnt NUMBER;
  l_pay_cur_code fnd_currencies_vl.currency_code%type;
  l_payment_priority NUMBER;
  l_pay_group        VARCHAR2(50);
  l_terms_code ap_terms_vl.name%type;
  l_terms_date_basis VARCHAR2(30);
  l_terms_date_basis_code fnd_lookup_values.lookup_code%type;
  l_pay_date_basis VARCHAR2(30);
  l_pay_date_basis_code fnd_lookup_values.lookup_code%type;
  l_always_disc_flag         VARCHAR2(5);
  l_primary_pay_flag         VARCHAR2(1);
  l_tax_rep_exist_cnt        NUMBER;
  l_update_it_rep_site       VARCHAR2(1);
  l_income_tax_rep_site_flag VARCHAR2(1);
  l_sup_site_fail            VARCHAR2(1);
  l_error_prefix             VARCHAR2(10);
  l_error_prefix_list        VARCHAR2(600);
  l_organization_type        VARCHAR2(50);
  l_cnt_for_sup              NUMBER;
  l_upd_cnt                  NUMBER := 0;
  l_stg_sup_name ap_suppliers.vendor_name%type;
  l_stg_sup_dup_cnt NUMBER := 0;
  l_int_sup_name ap_suppliers.vendor_name%type;
  l_int_tax_payer_id NUMBER := 0;
  l_int_segment1 ap_suppliers.segment1%type;
  l_upd_count            NUMBER;
  l_site_upd_cnt         NUMBER;
  L_AP_APPLICATION_ID    NUMBER := 200;
  l_po_application_id    NUMBER := 201;
  v_error_message        VARCHAR2(2000);
  v_error_flag           VARCHAR2(1);
  l_sup_eligible_cnt     NUMBER := 0;
  l_sup_val_load_cnt     NUMBER := 0;
  l_sup_error_cnt        NUMBER := 0;
  l_sup_val_not_load_cnt NUMBER := 0;
  l_sup_ready_process    NUMBER := 0;
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults' ,p_force=>true);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag := 'N';
  --gc_error_site_status_flag := 'N';
  l_error_message := NULL;
  gc_error_msg    := '';
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||': Opening Supplier Cursor' ,P_FORCE=>TRUE);
  print_debug_msg(p_message=> l_program_step||' : Doing the Duplicate Supplier Check in Staging table' , p_force=> true);
  OPEN c_dup_supplier_chk_stg;
  LOOP
    FETCH c_dup_supplier_chk_stg INTO l_stg_sup_name, l_stg_sup_dup_cnt;
    EXIT
  WHEN c_dup_supplier_chk_stg%notfound;
    print_debug_msg(p_message=> l_program_step||' : ERROR: '||l_stg_sup_dup_cnt||' records exist for Supplier Name '||l_stg_sup_name||' in the staging table' ,p_force=> true);
    l_upd_cnt := 0;
    UPDATE XX_AP_CLD_SUPPLIERS_STG
    SET supp_process_flag = gn_process_status_error ,
      ERROR_FLAG          = gc_process_error_flag ,
      ERROR_MSG           = l_stg_sup_dup_cnt
      ||' records exist for Supplier Name '
      ||l_stg_sup_name
      ||' in the staging table.'
    WHERE trim(upper(supplier_name)) = l_stg_sup_name
    AND supp_process_flag            = gn_process_status_inprocess
    AND REQUEST_ID                   = gn_request_id;
  END LOOP;
  CLOSE c_dup_supplier_chk_stg;
  --==============================================================
  -- Start validation for each supplier
  --===========================================================
  OPEN c_supplier;
  LOOP
    FETCH c_supplier bulk collect INTO l_supplier_type;
    IF l_supplier_type.count > 0 THEN
      set_step ('Start of Supplier Validations');
      FOR l_sup_idx IN l_supplier_type.first .. l_supplier_type.last
      LOOP
        print_debug_msg(p_message=> l_program_step||': ------------ Validating Supplier('||l_supplier_type(l_sup_idx).supplier_name||') -------------------------' ,p_force=> true);
        --==============================================================
        -- Initialize the Variable to N for Each Supplier
        --==============================================================
        gc_error_status_flag := 'N';
        gc_step              := 'SUPPLIER';
        l_error_message      := NULL;
        gc_error_msg         := '';
        l_vendor_exist_flag  := 'N';
        l_sup_type_code      := NULL;
        l_segment1           :=NULL;
        l_tax_payer_id       := NULL;
        l_vendor_id          := NULL;
        l_party_id           := NULL;
        l_obj_ver_no         := NULL;
        l_sup_site_fail      := 'N';
        --==============================================================
        -- Validation for Each Supplier
        --==============================================================
        --=============================================================================
        -- Validating the Supplier Site - Reporting Name
        --=============================================================================
        IF l_supplier_type(l_sup_idx).tax_reporting_name                        IS NOT NULL THEN
          IF ((find_special_chars(l_supplier_type(l_sup_idx).tax_reporting_name) = 'JUNK_CHARS_EXIST') OR (LENGTH(l_supplier_type(l_sup_idx).tax_reporting_name) > 32 )) THEN
            gc_error_site_status_flag                                           := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: REPORTING_NAME:'||l_supplier_type(l_sup_idx).tax_reporting_name||': XXOD_REPORTING_NAME_INVALID: Reporting Name cannot contain junk characters and length must be less than 32' ,p_force=> true);
            insert_error (p_program_step => gc_step , p_primary_key => l_supplier_type(l_sup_idx).supplier_name ,p_error_code => 'XXOD_REPORTING_NAME_INVALID' , p_error_message => 'Reporting Name '||l_supplier_type(l_sup_idx).tax_reporting_name ||' cannot contain junk characters and length must be less than 32' , p_stage_col1 => 'REPORTING_NAME' , p_stage_val1 => l_supplier_type(l_sup_idx).tax_reporting_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL , p_table_name => g_sup_table );
          END IF;
        END IF;
        --=============================================================================
        -- Validating the Supplier Site - Organization Type
        --=============================================================================
        print_debug_msg(p_message=> gc_step||' Organization type value is '||l_supplier_type(l_sup_idx).organization_type ,p_force=> false);
        IF l_supplier_type(l_sup_idx).organization_type IS NULL THEN
          l_organization_type                           := 'Individual';
        ELSE
          l_organization_type := l_supplier_type(l_sup_idx).organization_type;
        END IF;
        l_org_type_code := NULL;
        OPEN c_get_fnd_lookup_code('ORGANIZATION TYPE', l_organization_type, l_po_application_id);
        FETCH c_get_fnd_lookup_code INTO l_org_type_code;
        CLOSE c_get_fnd_lookup_code;
        IF l_org_type_code          IS NULL THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: ORGANIZATION_TYPE:'||l_organization_type||': XXOD_ORGANIZATION_TYPE_INVALID: Organization Type does not exist in the system.' ,p_force=> true);
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
          print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier Name Cannot be NULL for the record '||l_sup_idx ,p_force=> true);
          INSERT_ERROR (P_PROGRAM_STEP => GC_STEP ,P_PRIMARY_KEY => L_SUPPLIER_TYPE (L_SUP_IDX).SUPPLIER_NAME ,P_ERROR_CODE => 'XXOD_SUPPLIER_NAME_NULL' ,P_ERROR_MESSAGE => 'Supplier Name Cannot be NULL' ,P_STAGE_COL1 => 'SUPPLIER_NAME' ,P_STAGE_VAL1 => L_SUPPLIER_TYPE (L_SUP_IDX).SUPPLIER_NAME ,P_STAGE_COL2 => 'VENDOR_NAME' ,P_STAGE_VAL2 => NULL ,P_TABLE_NAME => G_SUP_TABLE );
          l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
          l_supplier_type (l_sup_idx).ERROR_FLAG        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).ERROR_MSG         := 'Supplier Name Cannot be NULL for the record '||l_sup_idx;
          -- Skip the validation of this iteration/this supplier
          CONTINUE;
        END IF;
        IF ((find_special_chars(l_supplier_type(l_sup_idx).supplier_name) = 'JUNK_CHARS_EXIST') OR (LENGTH(l_supplier_type(l_sup_idx).supplier_name) > 30 )) THEN
          GC_ERROR_STATUS_FLAG                                           := 'Y';
          print_debug_msg(p_message=> l_program_step||' : ERROR: Supplier Name'||l_supplier_type(l_sup_idx).supplier_name||' cannot contain junk characters and length must be less than 31' ,p_force=> true);
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
        ---- Priyam to be checked later
        IF l_supplier_type(l_sup_idx).num_1099                                                                      IS NOT NULL THEN
          IF ( NOT (isnumeric(l_supplier_type(l_sup_idx).num_1099)) OR (LENGTH(l_supplier_type(l_sup_idx).num_1099) <> 9)) THEN
            gc_error_status_flag                                                                                    := 'Y';
            print_debug_msg(p_message=> l_program_step||' : ERROR: '||l_supplier_type (l_sup_idx).num_1099||' - Tax Payer Id should be numeric and must have 9 digits ' ,p_force=> true);
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
        IF l_sup_name IS NULL --   Supplier Matrix logic of 4c-1
          THEN
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
        elsif ( (l_sup_name                              =l_supplier_type (l_sup_idx).supplier_name)) THEN
          l_supplier_type (l_sup_idx).CREATE_FLAG       := 'N';--Update
          l_supplier_type (l_sup_idx).supp_process_flag := gn_process_status_validated;
          l_vendor_exist_flag                           := 'Y';
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
            print_debug_msg(p_message=> gc_step||' ERROR: SUPPLIER_TYPE:'||l_supplier_type (l_sup_idx).vendor_type_lookup_code||': XXOD_SUPP_TYPE_INVALID: Supplier Type does not exist in System' ,p_force=> true);
            insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_sup_idx).SUPPLIER_NAME ,p_error_code => 'XXOD_SUPP_TYPE_INVALID' ,p_error_message => 'Supplier Type does not exist in System' ,p_stage_col1 => 'SUPPLIER_TYPE' ,p_stage_val1 => l_supplier_type (l_sup_idx).vendor_type_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
          ELSE
            l_supplier_type (l_sup_idx).vendor_type_lookup_code := l_sup_type_code;
          END IF; -- IF l_sup_type_code IS NULL
        END IF;   -- IF l_supplier_type (l_sup_idx).SUPPLIER_TYPE IS NULL
        --====================================================================
        -- Validating the Supplier - Customer Number
        --====================================================================
        IF (l_supplier_type(l_sup_idx).customer_num IS NOT NULL) THEN
          print_debug_msg(p_message=> gc_step||'Validating the Supplier - Customer Number ' ,p_force=> true);
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
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).ONE_TIME_FLAG  '||l_supplier_type (l_sup_idx).one_time_flag ,p_force=> true);
        END IF;
        IF l_supplier_type (l_sup_idx).federal_reportable_flag IS NULL THEN
          l_supplier_type (l_sup_idx).federal_reportable_flag  := 'N';
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).FEDERAL_REPORTABLE_FLAG  '||l_supplier_type (l_sup_idx).federal_reportable_flag ,p_force=> true);
        END IF;
        IF l_supplier_type (l_sup_idx).state_reportable_flag IS NULL THEN
          l_supplier_type (l_sup_idx).state_reportable_flag  := 'N';
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).STATE_REPORTABLE_FLAG  '||l_supplier_type (l_sup_idx).state_reportable_flag ,p_force=> true);
        END IF;
        print_debug_msg(p_message=> gc_step||'gc_error_status_flag' ||gc_error_status_flag ,p_force=> true);
        IF gc_error_status_flag = 'Y' THEN
          PRINT_DEBUG_MSG(P_MESSAGE=> GC_STEP||'gc_error_status_flag' ||GC_ERROR_STATUS_FLAG ,P_FORCE=> TRUE);
          l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
          l_supplier_type (l_sup_idx).ERROR_FLAG        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).ERROR_MSG         := gc_error_msg;
          print_debug_msg(p_message=> gc_step||' : Validation of Supplier '||l_supplier_type (l_sup_idx).supplier_name|| ' is failure' ,p_force=> true);
          print_debug_msg(p_message=> l_program_step||': ------------ Data Validation Failed Supplier('||l_supplier_type(l_sup_idx).supplier_name||') -------------------------' ,p_force=> true);
        ELSE
          PRINT_DEBUG_MSG(P_MESSAGE=> GC_STEP||'gn_process_status_validated ' ||GN_PROCESS_STATUS_VALIDATED ,P_FORCE=> TRUE);
          l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_validated; -- 35
          print_debug_msg(p_message=> gc_step||'l_supplier_type (l_sup_idx).PROCESS_FLAG ' ||l_supplier_type (l_sup_idx).PROCESS_FLAG ,p_force=> true);
          print_debug_msg(p_message=> gc_step||' : Validation of Supplier '||l_supplier_type (l_sup_idx).supplier_name|| ' is success' ,p_force=> true);
          print_debug_msg(p_message=> l_program_step||': ------------ Data Validation Success Supplier('||l_supplier_type(l_sup_idx).supplier_name||') -------------------------' ,p_force=> true);
        END IF;
        --====================================================================
        -- Call the Vendor Site Validations
        --====================================================================
        set_step ( 'Start of update after validation : ' || gc_error_status_flag);
        l_cnt_for_sup       := 0;
        l_error_prefix_list := NULL;
        BEGIN
          UPDATE XX_AP_CLD_SUPPLIERS_STG
          SET supp_process_flag     = gn_process_status_validated ,
            vendor_id               = l_supplier_type (l_sup_idx).vendor_id ,
            party_id                = l_supplier_type (l_sup_idx).party_id ,
            object_version_no       = l_supplier_type (l_sup_idx).object_version_no ,
            create_flag             = l_supplier_type (l_sup_idx).create_flag ,
           organization_type       = l_supplier_type(l_sup_idx).organization_type,
            --one_time_flag           = l_supplier_type(l_sup_idx).one_time_flag ,
            --FEDERAL_REPORTABLE_FLAG = L_SUPPLIER_TYPE(L_SUP_IDX).FEDERAL_REPORTABLE_FLAG ,
            --state_reportable_flag   = l_supplier_type(l_sup_idx).state_reportable_flag,
            LAST_UPDATE_DATE        =SYSDATE,
            LAST_UPDATED_BY         =g_user_id,
            ERROR_FLAG              = l_supplier_type(l_sup_idx).ERROR_FLAG ,
            ERROR_MSG               = l_supplier_type(l_sup_idx).ERROR_MSG
            --, PROCESS_FLAG        ='P'
          WHERE 1        =1-- SUPPLIER_NAME = L_SUPPLIER_TYPE (L_SUP_IDX).SUPPLIER_NAME
          AND segment1   = l_supplier_type (l_sup_idx).segment1
          AND REQUEST_ID = gn_request_id;
        EXCEPTION
        WHEN no_data_found THEN
          print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier, status update - '||l_supplier_type (l_sup_idx).supplier_name||' does not exists' ,p_force=> true);
        WHEN OTHERS THEN
          print_debug_msg(p_message=> gc_step||' ERROR: for validated supplier, status update - When Others Exception - '|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500) ,p_force=> true);
        END;
      END LOOP; -- For (l_supplier_type.FIRST .. l_supplier_type.LAST)
    END IF;     -- l_supplier_type.COUNT > 0
    --============================================================================
    -- For Doing the Bulk Update
    --============================================================================
    EXIT
  WHEN c_supplier%notfound;
  END LOOP; -- c_supplier loop
  CLOSE c_supplier;
  l_supplier_type.delete;
  l_sup_eligible_cnt     := 0;
  l_sup_val_load_cnt     := 0;
  l_sup_error_cnt        := 0;
  l_sup_val_not_load_cnt := 0;
  l_sup_ready_process    := 0;
  OPEN c_sup_stats;
  FETCH c_sup_stats
  INTO l_sup_eligible_cnt,
    l_sup_val_load_cnt,
    l_sup_error_cnt,
    l_sup_val_not_load_cnt,
    l_sup_ready_process;
  CLOSE c_sup_stats;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  -- x_val_records   := l_sup_val_not_load_cnt ;
  -- x_inval_records := l_sup_error_cnt + l_sup_eligible_cnt;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => 'SUPPLIER - Records Successfully Validated are '|| l_sup_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER - Records Validated and Errored are '|| l_sup_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER - Records Eligible for Validation but Untouched  are '|| l_sup_eligible_cnt, p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_supplier_records;
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
    x_val_records OUT nocopy   NUMBER ,
    x_inval_records OUT nocopy NUMBER ,
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
type l_sup_site_and_add_tab
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
    FROM XX_AP_CLD_SUPP_SITES_STG xasc,
      ap_suppliers apsup
    WHERE xasc.site_process_flag IN (gn_process_status_inprocess)
    AND XASC.REQUEST_ID           = gn_request_id
    AND upper(apsup.vendor_name)  =upper(xasc.supplier_name)
    AND apsup.segment1            =xasc.supplier_number ;
  --  AND TRIM(UPPER(xasc.SUPPLIER_NAME)) = c_supplier_name;
  --==========================================================================================
  -- Cursor Declarations for Country Code
  --==========================================================================================
  CURSOR c_get_country_code (c_country VARCHAR2)
  IS
    SELECT TERRITORY_CODE
    FROM FND_TERRITORIES_TL
    WHERE TERRITORY_CODE = C_COUNTRY;
     -- AND language               = userenv ('LANG');
  --==========================================================================================
  -- Cursor Declarations for Supplier Site existence
  --==========================================================================================
  --CURSOR C_SUP_SITE_EXIST (C_SUPPLIER_NAME VARCHAR2 ,C_SUPPLIER_NUMBER VARCHAR2,C_VENDOR_SITE_CODE VARCHAR2,C_ORG_ID NUMBER )
  CURSOR c_sup_site_exist(c_supp_id NUMBER ,c_vendor_site_code VARCHAR2,c_org_id VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM ap_supplier_sites_all assa
    WHERE 1              =1
    AND VENDOR_SITE_CODE = C_VENDOR_SITE_CODE
    AND TO_CHAR(ORG_ID)  =C_ORG_ID
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
	and enabled_flag='Y';
   ---- AND TRUNC(sysdate) BETWEEN TRUNC(start_date_active) AND TRUNC(NVL(end_date_active, sysdate+1));
  --==========================================================================================
  -- Cursor Declarations to get Bill To Location Id
  --==========================================================================================
  CURSOR c_bill_to_location (c_bill_to_loc_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM hr_locations_all
    WHERE location_code   = UPPER(c_bill_to_loc_code)
    AND bill_to_site_flag = 'Y'
    AND inactive_date    IS NULL
    OR inactive_date     >= sysdate;
  --==========================================================================================
  -- Cursor Declarations to get Ship To Location Id
  --==========================================================================================
  CURSOR c_ship_to_location (c_ship_to_loc_code VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM hr_locations_all
    WHERE location_code   = UPPER(c_ship_to_loc_code)
    AND ship_to_site_flag = 'Y'
    AND inactive_date    IS NULL
    OR inactive_date     >= sysdate;
  --==========================================================================================
  -- Cursor Declarations to check the existence of Payment Method
  --==========================================================================================
  CURSOR c_pay_method_exist (c_pay_method VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM iby_payment_methods_b
    WHERE payment_method_code = c_pay_method
    AND inactive_date        IS NULL
    OR inactive_date         >= sysdate;
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
    SELECT COUNT(1)
    FROM ap_terms_vl
    WHERE name       = c_term_name
    AND enabled_flag = 'Y'
    AND TRUNC(sysdate) BETWEEN TRUNC(NVL(start_date_active, sysdate-1)) AND TRUNC(NVL(end_date_active, sysdate+1));
  --==================================================================================================
  -- Cursor Declarations to check the existence of the Tax Reporting Site for the existed supplier
  --==================================================================================================
  CURSOR c_tax_rep_site_exist (c_vendor_id NUMBER)
  IS
    SELECT COUNT(1)
    FROM ap_supplier_sites_all
    WHERE vendor_id             = c_vendor_id
    AND tax_reporting_site_flag = 'Y';
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Site Staging
  --==============================================================================
  CURSOR c_sup_site_stats
  IS
    SELECT SUM(DECODE(site_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(site_process_flag,6,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(site_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(site_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(site_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_SITES_STG
    WHERE REQUEST_ID = gn_request_id;
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Staging table
  --=================================================================
  CURSOR c_dup_supplier_chk_stg
  IS
    SELECT trim(upper(xas.supplier_name)),
      xas.vendor_site_code,
      xas.org_id,
      COUNT(1)
    FROM XX_AP_CLD_SUPP_SITES_STG xas
    WHERE XAS.SITE_PROCESS_FLAG IN (GN_PROCESS_STATUS_INPROCESS)
    AND XAS.REQUEST_ID           =gn_request_id
    GROUP BY trim(upper(xas.supplier_name)),
      xas.vendor_site_code,
      xas.org_id
    HAVING COUNT(1) >= 2;
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers site in Interface table
  --=================================================================

  CURSOR c_dup_supplier_chk_int(c_vendor_site_code VARCHAR2,c_vendor_id NUMBER,c_org_id VARCHAR2)
  IS
    SELECT xasi.vendor_site_code
      ---xasi.num_1099
    FROM AP_SUPPLIER_SITES_INT XASI
    WHERE xasi.status           ='NEW'
    AND UPPER(VENDOR_SITE_CODE) = UPPER(C_VENDOR_SITE_CODE)
    AND XASI.VENDOR_ID          =C_VENDOR_ID
    AND TO_CHAR(xasi.org_id)             =c_org_id;
  ---   AND xasi.segment1      =c_segment1;
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_msg_count   NUMBER        := 0;
  l_trans_count NUMBER        := 0;
  l_inval_records pls_integer := 0;
  l_val_records pls_integer   := 0;
  l_sup_idx pls_integer       := 0;
  l_sup_site_idx pls_integer  := 0;
  l_sup_cont_idx pls_integer  := 0;
  l_procedure            VARCHAR2 (30)   := 'validate_Supplier_Site_records';
  l_program_step         VARCHAR2 (100)  := '';
  l_ret_code             NUMBER;
  l_return_status        VARCHAR2 (100);
  l_err_buff             VARCHAR2 (4000);
  l_sup_fail_site_depend VARCHAR2(2000);
  l_error_message        VARCHAR2(4000) := '';
  l_site_country_code    VARCHAR2(15);
  l_sup_name ap_suppliers.vendor_name%type;
  l_segment1 ap_suppliers.segment1%type;
  --- l_tax_payer_id AP_SUPPLIERS.NUM_1099%TYPE;
  l_vendor_exist_flag VARCHAR2(1) := 'N';
  l_vendor_id         NUMBER;
  l_party_id          NUMBER;
  l_obj_ver_no        NUMBER;
  l_sup_type_code ap_suppliers.vendor_type_lookup_code%type;
  l_income_tax_type_cnt  NUMBER;
  l_org_id               NUMBER;
  l_org_id_cnt           NUMBER;
  l_sup_site_exist_cnt   NUMBER;
  l_sup_create_flag      VARCHAR2(10) := '';
  l_site_code            VARCHAR2(40);
  l_address_purpose      VARCHAR2(10);
  l_terms_id             NUMBER;
  l_purchasing_site_flag VARCHAR2(1);
  l_pay_site_flag        VARCHAR2(1);
  l_payment_method iby_payment_methods_b.payment_method_code%type;
  l_pay_group_code ap_suppliers.pay_group_lookup_code%type;
  l_ccid           NUMBER;
  l_cont_phone_num VARCHAR2(20);
  l_org_type_code fnd_lookup_values.lookup_code%type;
  l_gcc_segment3 gl_code_combinations.segment3%type;
  l_freight_terms_code fnd_lookup_values.lookup_code%type;
  l_pay_method_cnt NUMBER;
  l_tolerance_name ap_tolerance_templates.tolerance_name%type;
  l_deduct_bank_chrg VARCHAR2(5);
  l_inv_match_option VARCHAR2(25);
  l_inv_cur_code fnd_currencies_vl.currency_code%type;
  l_inv_curr_code_cnt NUMBER;
  l_pay_cur_code fnd_currencies_vl.currency_code%type;
  l_payment_priority         NUMBER;
  l_pay_group                VARCHAR2(50);
  l_terms_date_basis         VARCHAR2(30);
  l_always_disc_flag         VARCHAR2(5);
  l_primary_pay_flag         VARCHAR2(1);
  l_tax_rep_exist_cnt        NUMBER;
  l_update_it_rep_site       VARCHAR2(1);
  l_income_tax_rep_site_flag VARCHAR2(1);
  l_sup_site_fail            VARCHAR2(1);
  l_error_prefix             VARCHAR2(10);
  l_error_prefix_list        VARCHAR2(600);
  l_site_cnt_for_sup         NUMBER;
  l_stg_sup_name ap_suppliers.vendor_name%type;
  l_stg_sup_dup_cnt NUMBER := 0;
  l_int_sup_name ap_suppliers.vendor_name%type;
  l_int_segment1 ap_suppliers.segment1%type;
  l_upd_count                 NUMBER;
  l_site_upd_cnt              NUMBER;
  l_ap_application_id         NUMBER := 200;
  l_po_application_id         NUMBER := 201;
  v_error_message             VARCHAR2(2000);
  v_error_flag                VARCHAR2(1);
  l_sup_eligible_cnt          NUMBER := 0;
  l_sup_val_load_cnt          NUMBER := 0;
  l_sup_error_cnt             NUMBER := 0;
  l_sup_val_not_load_cnt      NUMBER := 0;
  l_sup_ready_process         NUMBER := 0;
  l_supsite_eligible_cnt      NUMBER := 0;
  l_supsite_val_load_cnt      NUMBER := 0;
  l_supsite_error_cnt         NUMBER := 0;
  l_supsite_val_not_load_cnt  NUMBER := 0;
  l_supsite_ready_process     NUMBER := 0;
  l_ship_to_cnt               NUMBER :=0;
  l_bill_to_cnt               NUMBER :=0;
  l_terms_cnt                 NUMBER :=0;
  l_tolerance_cnt             NUMBER :=0;
  l_int_vend_code             VARCHAR2(100);
  l_fob_code_cnt              NUMBER ;
  l_freight_terms_code_cnt    NUMBER;
  l_pay_group_code_cnt        NUMBER;
  l_terms_date_basis_code_cnt NUMBER;
  ln_cnt NUMBER;
BEGIN
  l_program_step := 'START';
  PRINT_DEBUG_MSG(P_MESSAGE=> L_PROGRAM_STEP||': Assigning Defaults' ,P_FORCE=>TRUE);
  PRINT_DEBUG_MSG(P_MESSAGE=>'fnd_global.conc_request_id'|| FND_GLOBAL.CONC_REQUEST_ID ,P_FORCE=>TRUE);
  print_debug_msg(p_message=>'gn_request_id'|| gn_request_id ,P_FORCE=>TRUE);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag      := 'N';
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  BEGIN
    UPDATE XX_AP_CLD_SUPP_SITES_STG XASC
    SET SITE_PROCESS_FLAG = GN_PROCESS_STATUS_ERROR ,
      --  REQUEST_ID           = gn_request_id ,
      PROCESS_FLAG         = 'Y',
      ERROR_FLAG           =gc_process_error_flag,
      ERROR_MSG            ='No Supplier Exists'
    WHERE SITE_PROCESS_FLAG=GN_PROCESS_STATUS_INPROCESS
    AND request_id         =gn_request_id
    AND NOT EXISTS
      (SELECT 1
      FROM ap_suppliers apsup
      WHERE upper(apsup.vendor_name)=upper(xasc.supplier_name)
      AND APSUP.SEGMENT1            =XASC.SUPPLIER_NUMBER
      );
    --Commented per narasimha
    /*
    UPDATE XX_AP_CLD_SUPP_SITES_STG XASC
    SET site_process_flag = gn_process_status_error ,
    PROCESS_FLAG        = 'Y',
    ERROR_FLAG          =gc_process_error_flag,
    ERROR_MSG           ='No Supplier Exists'
    WHERE request_id      =gn_request_id
    AND SITE_PROCESS_FLAG =GN_PROCESS_STATUS_INPROCESS
    AND NOT EXISTS
    (SELECT 1
    FROM ap_suppliers apsup
    WHERE upper(apsup.vendor_name)=upper(xasc.supplier_name)
    AND APSUP.SEGMENT1            =XASC.SUPPLIER_NUMBER
    );
    */
    L_SITE_UPD_CNT   := SQL%ROWCOUNT;
    IF L_SITE_UPD_CNT >0 THEN
      PRINT_DEBUG_MSG(P_MESSAGE => 'No Supplier Exists for this Site', P_FORCE => FALSE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    L_ERR_BUFF := SQLCODE || ' - '|| SUBSTR (SQLERRM,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Supplier Site for no Supplier - '|| l_err_buff , p_force => true);
    x_ret_code      := '1';
    x_return_status := 'E';
    x_err_buf       := l_err_buff;
    RETURN;
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
    IF L_SITE_UPD_CNT >0 THEN
      PRINT_DEBUG_MSG(P_MESSAGE => 'Check and updated '||L_SITE_UPD_CNT||' records as error in the staging table for the Duplicate Sites', P_FORCE => FALSE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate Site in Staging table - '|| l_err_buff , p_force => true);
    x_ret_code      := '1';
    x_return_status := 'E';
    x_err_buf       := l_err_buff;
    RETURN;
  END;
  print_debug_msg(p_message=> l_program_step||': Opening Supplier SITE Cursor' ,p_force=>true);
  --====================================================================
  -- Call the Vendor Site ValidationsStart of Vendor Site Loop Validations
  --====================================================================
  set_step ( 'Start of Vendor Site Loop Validations : ' || gc_error_status_flag);
  l_site_cnt_for_sup  := 0;
  l_error_prefix_list := NULL;
  --COmmented by Priyam
  FOR l_sup_site_type IN c_supplier_site
  LOOP
    ---print_debug_msg(p_message=> gc_step||' : Check if Supplier Exist in EBS for this Site');
    print_debug_msg(p_message=> gc_step||' : Validation of Supplier Site started' ,p_force=> true);
    l_sup_site_idx     := l_sup_site_idx     + 1;
    l_site_cnt_for_sup := l_site_cnt_for_sup + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_site_idx - '||l_sup_site_idx ,p_force=> true);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'SITE';
    gc_error_msg              := '';
    --====================================================================
    -- Not Required
    --====================================================================
    L_INT_VEND_CODE:=NULL;
	SELECT COUNT(1)
	  INTO ln_cnt
      FROM AP_SUPPLIER_SITES_INT XASI
     WHERE xasi.status           ='NEW'
       AND UPPER(VENDOR_SITE_CODE) = TRIM(UPPER(L_SUP_SITE_TYPE.VENDOR_SITE_CODE))
       AND XASI.VENDOR_ID          =L_SUP_SITE_TYPE.supp_id
       AND TO_CHAR(xasi.org_id)    =L_SUP_SITE_TYPE.ORG_ID;

    --OPEN C_DUP_SUPPLIER_CHK_INT(TRIM(UPPER(L_SUP_SITE_TYPE.VENDOR_SITE_CODE)),L_SUP_SITE_TYPE.supp_id,L_SUP_SITE_TYPE.ORG_ID);
    --FETCH c_dup_supplier_chk_int INTO l_int_vend_code;
    --   l_int_tax_payer_id;
    --CLOSE c_dup_supplier_chk_int;
    --IF l_int_vend_code     IS NOT NULL THEN
	IF ln_cnt<>0 THEN
      gc_error_status_flag := 'Y';
      print_debug_msg(p_message=> l_program_step||' : ERROR: XXOD_SUP_SITE_EXISTS_IN_INT : Suppiler ' ||l_sup_site_type.supplier_name||' already exist in Interface table with vendor_site_code as '||l_int_vend_code||' .' ,p_force=> true);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SUP_EXISTS_IN_INT' , p_error_message => 'Vendor Site Exists in interface' , p_stage_col1 => 'ADDRESS_LINE1' ,p_stage_val1 => l_sup_site_type.supplier_name ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  Address Line 1
    --==============================================================================================================
    IF l_sup_site_type.address_line1 IS NULL THEN
      gc_error_site_status_flag      := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: ADDRESS_LINE1:'||l_sup_site_type.address_line1||': XXOD_SITE_ADDR_LINE1_NULL:Vendor Site Address Line 1 cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_LINE1_NULL' ,p_error_message => 'Vendor Site Address Line 1 cannot be NULL' ,p_stage_col1 => 'ADDRESS_LINE1' ,p_stage_val1 => l_sup_site_type.address_line1 ,p_table_name => g_sup_site_cont_table );
    elsif ((find_special_chars(l_sup_site_type.address_line1) = 'JUNK_CHARS_EXIST') OR (LENGTH(trim(l_sup_site_type.address_line1)) > 38 )) THEN
      gc_error_site_status_flag                              := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_LINE1_INVALID: ADDRESS_LINE1:'||l_sup_site_type.address_line1||' cannot contain junk characters and length must be less than 32' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_LINE1_INVALID' ,p_error_message => 'Vendor Site Address Line 1 cannot contain junk characters and length must be less than 32' ,p_stage_col1 => 'ADDRESS_LINE1' ,p_stage_val1 => l_sup_site_type.address_line1 ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  Address Line 2
    --==============================================================================================================
    IF ((find_special_chars(l_sup_site_type.address_line2) = 'JUNK_CHARS_EXIST') OR (LENGTH(trim(l_sup_site_type.address_line2)) > 38 )) THEN
      gc_error_site_status_flag                           := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_LINE2_INVALID: ADDRESS_LINE2:'||l_sup_site_type.address_line2||' cannot contain junk characters and length must be less than 32' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_LINE2_INVALID' ,p_error_message => 'Vendor Site Address Line 2 cannot contain junk characters and length must be less than 32' ,p_stage_col1 => 'ADDRESS_LINE2' ,p_stage_val1 => l_sup_site_type.address_line2 ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  City
    --==============================================================================================================
    IF l_sup_site_type.city     IS NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: CITY:'||l_sup_site_type.city||': XXOD_SITE_ADDR_CITY_NULL:Vendor Site Address Details City cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_CITY_NULL' ,p_error_message => 'Vendor Site Address Details City cannot be NULL' ,p_stage_col1 => 'CITY' ,p_stage_val1 => l_sup_site_type.city ,p_table_name => g_sup_site_cont_table );
    elsif ((find_special_chars(l_sup_site_type.city) = 'JUNK_CHARS_EXIST') OR (LENGTH(trim(l_sup_site_type.city)) > 22 )) THEN
      gc_error_site_status_flag                     := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_CITY_INVALID: CITY:'||l_sup_site_type.city||' cannot contain junk characters and length must be less than 22' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_CITY_INVALID' ,p_error_message => 'Vendor Site Address Details - City - cannot contain junk characters and length must be less than 22' ,p_stage_col1 => 'CITY' ,p_stage_val1 => l_sup_site_type.city ,p_table_name => g_sup_site_cont_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Country
    --==============================================================================================================
    l_site_country_code := NULL;
    OPEN c_get_country_code(NVL(l_sup_site_type.country,gc_site_country_code));
    FETCH c_get_country_code INTO l_site_country_code;
    --   l_int_tax_payer_id;
    CLOSE c_get_country_code;
    print_debug_msg(p_message=> gc_step||' l_site_country_code '||l_site_country_code ,p_force=> false);
    IF l_site_country_code                        IS NOT NULL THEN
      l_sup_site_and_add (l_sup_site_idx).country := l_site_country_code;
    ELSE
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: COUNTRY:'||l_sup_site_type.country||': XXOD_SITE_COUNTRY_INVALID         
:Vendor Site Country is Invalid' ,p_force=> false);
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
      elsif (NOT (isalpha(l_sup_site_type.state)) OR (LENGTH(trim(l_sup_site_type.state)) <> 2 )) THEN
        gc_error_site_status_flag                                                         := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_STATE_INVALID: STATE:'||l_sup_site_type.state||' should contain only alpha characters and length must be equal to 2' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_STATE_INVALID' ,p_error_message => 'Vendor Site Address Details - STATE - should contain only alpha characters and length must be equal to 2' ,p_stage_col1 => 'STATE' ,p_stage_val1 => l_sup_site_type.state ,p_table_name => g_sup_site_cont_table );
      elsif l_sup_site_type.province IS NOT NULL THEN
        gc_error_site_status_flag    := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_PROVINCE_INVALID: PROVINCE:'||l_sup_site_type.province||': should be NULL for the country '||l_sup_site_type.country ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_PROVINCE_INVALID' ,p_error_message => 'Vendor Site Address Details - Province - should be NULL for the country '||l_sup_site_type.country ,p_stage_col1 => 'PROVINCE' ,p_stage_val1 => l_sup_site_type.province ,p_table_name => g_sup_site_cont_table );
      END IF; -- IF l_sup_site_type.STATE IS NULL   -- ??? Do we need to validate the State Code in Oracle Seeded table
    elsif l_site_country_code      = 'CA' THEN
      IF l_sup_site_type.province IS NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: PROVINCE:'||l_sup_site_type.province||': XXOD_SITE_ADDR_PROVINCE_NULL:Vendor Site Address Details - Province - cannot be NULL' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_PROVINCE_NULL' ,p_error_message => 'Vendor Site Address Details - Province - cannot be NULL' ,p_stage_col1 => 'PROVINCE' ,p_stage_val1 => l_sup_site_type.province ,p_table_name => g_sup_site_cont_table );
      elsif (NOT (isalpha(l_sup_site_type.province)) OR (LENGTH(trim(l_sup_site_type.province)) <> 2 )) THEN
        gc_error_site_status_flag                                                               := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: XXOD_SITE_ADDR_PROVINCE_INVALID: PROVINCE:'||l_sup_site_type.province||' should contain only alpha characters and length must be equal to 2' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_PROVINCE_INVALID' ,p_error_message => 'Vendor Site Address Details - PROVINCE - should contain only alpha characters and length must be equal to 2' ,p_stage_col1 => 'PROVINCE' ,p_stage_val1 => l_sup_site_type.province ,p_table_name => g_sup_site_cont_table );
      elsif l_sup_site_type.state IS NOT NULL THEN
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
      print_debug_msg(p_message=> gc_step||' ERROR: OPERATING_UNIT:'||l_sup_site_type.org_id||':              
XXOD_OPERATING_UNIT_NULL: ORG ID cannot be NULL.' ,p_force=> true);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_OPERATING_UNIT_NULL' ,p_error_message => 'Operating Unit cannot be NULL' ,p_stage_col1 => 'ORG ID' ,p_stage_val1 => l_sup_site_type.org_id ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
    END IF;
    print_debug_msg(p_message=> gc_step||' After basic validation of site - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    l_sup_create_flag           :='';
    l_site_code                 := NULL;
    IF gc_error_site_status_flag = 'N' THEN
      print_debug_msg(p_message=> gc_step||' Prepared Site code - l_site_code - is '||l_site_code ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' l_sup_site_type.update_flag is '||l_sup_site_type.create_flag ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' l_vendor_exist_flag is '||l_vendor_exist_flag ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.supplier_name) is '||upper(l_sup_site_type.supplier_name) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.supplier_number) is '||upper(l_sup_site_type.supplier_number) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_site_type.vendor_site_code) is '||upper(l_sup_site_type.vendor_site_code) ,p_force=> false);
      L_SUP_SITE_EXIST_CNT := 0;
      OPEN C_SUP_SITE_EXIST(L_SUP_SITE_TYPE.SUPP_ID,L_SUP_SITE_TYPE.VENDOR_SITE_CODE,L_SUP_SITE_TYPE.ORG_ID);
      -- OPEN C_SUP_SITE_EXIST(L_SUP_SITE_TYPE.SUPPLIER_NAME ,L_SUP_SITE_TYPE.SUPPLIER_NUMBER, l_sup_site_type.vendor_site_code,l_sup_site_type.org_id);
      FETCH c_sup_site_exist
      INTO l_sup_site_exist_cnt;
      CLOSE c_sup_site_exist;
      IF l_sup_site_exist_cnt       > 0 THEN
        l_sup_create_flag          :='N';--update the supplier
        l_sup_site_type.create_flag:=l_sup_create_flag;
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
    IF gc_error_site_status_flag = 'N' THEN -- After Supplier Site Existence Check Completed
      --==============================================================================================================
      -- Validating the Supplier Site - PostalCode Rename Psotal to Area
      --==============================================================================================================
      IF l_sup_site_type.postal_code IS NULL THEN
        gc_error_site_status_flag    := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.postal_code ||': XXOD_SITE_ADDR_POSTAL_CODE_NULL: Vendor Site Address Details - Postal Code - cannot be NULL' ,p_force=> false);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_POSTAL_CODE_NULL' ,p_error_message => 'Vendor Site Address Details - Postal Code - cannot be NULL' ,p_stage_col1 => 'POSTAL_CODE' ,p_stage_val1 => l_sup_site_type.postal_code ,p_table_name => g_sup_site_cont_table );
      ELSE
        IF l_site_country_code                                                                         = 'US' THEN
          IF (NOT (ispostalcode(l_sup_site_type.postal_code )) OR (LENGTH(l_sup_site_type.postal_code) > 10 )) THEN
            gc_error_site_status_flag                                                                 := 'Y';
            print_debug_msg(p_message=> gc_step||' ERROR: POSTAL_CODE:'||l_sup_site_type.postal_code ||': XXOD_SITE_ADDR_POSTAL_CODE_INVA: For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10' ,p_force=> false);
            insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SITE_ADDR_POSTAL_CODE_INVA' ,p_error_message => 'For country '||l_sup_site_type.country||',Vendor Site Address Details - Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10' ,p_stage_col1 => 'POSTAL_CODE' ,p_stage_val1 => l_sup_site_type.postal_code ,p_table_name => g_sup_site_cont_table );
          END IF; -- IF (NOT (isPostalCode(l_sup_site_type.POSTAL_CODE))
        elsif l_site_country_code = 'CA' THEN
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
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Phone area code
      --===============================================================================================
      IF l_sup_site_type.phone_area_code                                                                 IS NOT NULL THEN
        IF (NOT (isnumeric(l_sup_site_type.phone_area_code)) OR (LENGTH(l_sup_site_type.phone_area_code) <> 3 )) THEN
          gc_error_site_status_flag                                                                      := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PHONE_AREA_CODE:'||l_sup_site_type.phone_area_code||': XXOD_PHONE_AREA_CODE_INVALID: Phone Area Code '||l_sup_site_type.phone_area_code||' should be numeric and 3 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_PHONE_AREA_CODE_INVALID' ,p_error_message => 'Phone Area Code '||l_sup_site_type.phone_area_code||' should be numeric and 3 digits.' ,p_stage_col1 => 'PHONE_AREA_CODE' ,p_stage_val1 => l_sup_site_type.phone_area_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.PHONE_AREA_CODE))
      END IF;   -- IF l_sup_site_type.PHONE_AREA_CODE IS NOT NULL THEN
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Phone Number
      --===============================================================================================
      IF l_sup_site_type.phone_number IS NOT NULL THEN
        IF (LENGTH(l_sup_site_type.phone_number) NOT IN (7,8) ) THEN -- Phone Number length is 7 and 1 digit count for '-'
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PHONE_NUMBER:'||l_sup_site_type.phone_number||': XXOD_PHONE_NUMBER_INVALID: Phone Number '||l_sup_site_type.phone_number||' should be 7 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_PHONE_NUMBER_INVALID' ,p_error_message => 'Phone Number '||l_sup_site_type.phone_number||' should be 7 digits.' ,p_stage_col1 => 'PHONE_NUMBER' ,p_stage_val1 => l_sup_site_type.phone_number ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.PHONE_NUMBER))
      END IF;   -- IF l_sup_site_type.PHONE_NUMBER IS NOT NULL THEN
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Fax area code
      --===============================================================================================
      IF l_sup_site_type.fax_area_code                                                               IS NOT NULL THEN
        IF (NOT (isnumeric(l_sup_site_type.fax_area_code)) OR (LENGTH(l_sup_site_type.fax_area_code) <> 3 )) THEN
          gc_error_site_status_flag                                                                  := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FAX_AREA_CODE:'||l_sup_site_type.fax_area_code||': XXOD_FAX_AREA_CODE_INVALID: Fax Area Code '||l_sup_site_type.fax_area_code||' should be numeric and 3 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_FAX_AREA_CODE_INVALID' ,p_error_message => 'Fax Area Code '||l_sup_site_type.fax_area_code||' should be numeric and 3 digits.' ,p_stage_col1 => 'FAX_AREA_CODE' ,p_stage_val1 => l_sup_site_type.fax_area_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.FAX_AREA_CODE))
      END IF;   -- IF l_sup_site_type.FAX_AREA_CODE IS NOT NULL THEN
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Fax Number/FAX updated by Priyam
      --===============================================================================================
      IF l_sup_site_type.fax IS NOT NULL THEN
        IF (LENGTH(l_sup_site_type.fax) NOT IN (7,8) ) THEN -- Fax Number length is 7 and 1 digit count for '-'
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FAX_NUMBER:'||l_sup_site_type.fax||': XXOD_FAX_NUMBER_INVALID: Fax Number '||l_sup_site_type.fax||' should be 7 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_FAX_NUMBER_INVALID' ,p_error_message => 'Fax Number '||l_sup_site_type.fax||' should be 7 digits.' ,p_stage_col1 => 'FAX_NUMBER' ,p_stage_val1 => l_sup_site_type.fax ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.FAX_NUMBER))
      END IF;   -- IF l_sup_site_type.FAX_NUMBER IS NOT NULL THEN
      --=============================================================================
      -- Validating the Supplier Site - Ship to Location Code
      --=============================================================================
      IF l_sup_site_type.ship_to_location IS NOT NULL THEN
        l_ship_to_cnt                     := 0;
        OPEN c_ship_to_location(l_sup_site_type.ship_to_location);
        FETCH c_ship_to_location INTO l_ship_to_cnt;
        CLOSE c_ship_to_location;
        IF l_ship_to_cnt            =0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: SHIP_TO_LOCATION:'||l_sup_site_type.ship_to_location||': XXOD_SHIP_TO_LOCATION_INVALID2: Ship to Location does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SHIP_TO_LOCATION_INVALID2' ,p_error_message => 'Ship to Location '||l_sup_site_type.ship_to_location||' does not exist in the system' ,p_stage_col1 => 'SHIP_TO_LOCATION' ,p_stage_val1 => l_sup_site_type.ship_to_location ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' Ship to Location Id is available' ,p_force=> false);
        END IF; -- IF l_ship_to_location_id IS NULL
      END IF;
      --  IF SHIP_TO_LOCATION IS NOT NULL THEN
      --=============================================================================
      -- Validating the Supplier Site - bill to Location Code
      --=============================================================================
      IF l_sup_site_type.bill_to_location IS NOT NULL THEN
        l_bill_to_cnt                     := 0;
        OPEN c_bill_to_location(l_sup_site_type.bill_to_location);
        FETCH c_bill_to_location INTO l_bill_to_cnt;
        close c_bill_to_location;
        IF l_bill_to_cnt            =0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: SHIP_TO_LOCATION:'||l_sup_site_type.bill_to_location||': XXOD_SHIP_TO_LOCATION_INVALID2: Ship to Location does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_SHIP_TO_LOCATION_INVALID2' ,p_error_message => 'Ship to Location '||l_sup_site_type.bill_to_location||' does not exist in the system' ,p_stage_col1 => 'SHIP_TO_LOCATION' ,p_stage_val1 => l_sup_site_type.bill_to_location ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' Ship to Location Id is avilable ' ,p_force=> false);
        END IF; -- IF l_ship_to_location_id IS NULL
      END IF;
      --=============================================================================
      -- Validating the Supplier Site - FOB Lookup value
      --=============================================================================
      l_fob_code_cnt                     := NULL;
      IF l_sup_site_type.fob_lookup_code IS NOT NULL THEN -- Derive the FOB Code
        l_fob_code_cnt                   := 0;
        OPEN c_get_fnd_lookup_code_cnt('FOB', l_sup_site_type.fob_lookup_code);
        fetch c_get_fnd_lookup_code_cnt into l_fob_code_cnt;
        CLOSE c_get_fnd_lookup_code_cnt;
        IF l_fob_code_cnt=0 THEN
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
        L_FREIGHT_TERMS_CODE_CNT                   := 0;
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
        IF l_pay_method_cnt         = 0 THEN
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PAYMENT_METHOD:'||l_sup_site_type.payment_method_lookup_code||': XXOD_PAYMENT_METHOD_INVALID: Payment Method does not exist in the system.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_PAYMENT_METHOD_INVALID' ,p_error_message => 'Payment Method does not exist in the system' ,p_stage_col1 => 'PAYMENT_METHOD' ,p_stage_val1 => l_sup_site_type.payment_method_lookup_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
        ELSE
          print_debug_msg(p_message=> gc_step||' PAYMENT_METHOD:'||l_sup_site_type.payment_method_lookup_code||' exist in the system.' ,p_force=> false);
          l_payment_method := l_sup_site_type.payment_method_lookup_code;
        END IF; -- IF l_pay_method_cnt < 1
      END IF;   -- IF l_sup_site_type.PAYMENT_METHOD IS NULL
      --=============================================================================
      -- Validating the Supplier Site - Invoice Tolerance
      --=============================================================================
      IF l_sup_site_type.tolerance_name IS NULL THEN
        l_tolerance_name                := 'US_OD_TOLERANCES_Default';
      ELSE
        l_tolerance_name := l_sup_site_type.tolerance_name;
      END IF;
      l_tolerance_cnt := 0;
      -----------------------Make it a function--------------------
      OPEN c_get_tolerance(l_tolerance_name);
      FETCH c_get_tolerance INTO l_tolerance_cnt;
      CLOSE c_get_tolerance;
      IF l_tolerance_cnt          =0 THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> gc_step||' ERROR: INVOICE_TOLERANCE:'||l_sup_site_type.tolerance_name||': XXOD_INV_TOLERANCE_INVALID: Invoice Tolerance does not exist in the system.' ,p_force=> true);
        insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_type.supplier_name ,p_error_code => 'XXOD_INV_TOLERANCE_INVALID' ,p_error_message => 'Invoice Tolerance '||l_sup_site_type.tolerance_name||' does not exist in the system' ,p_stage_col1 => 'INVOICE_TOLERANCE' ,p_stage_val1 => l_sup_site_type.tolerance_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
      ELSE
        print_debug_msg(p_message=> gc_step||' Invoice Tolerance Id is available' ,p_force=> false);
      END IF; -- IF l_tolerance_id IS NULL
      --==============================================================================================================
      -- Validating the Supplier Site - Invoice Match Option
      --==============================================================================================================
    /*  l_inv_match_option              := NULL;
      IF l_sup_site_type.match_option IS NULL THEN
        l_inv_match_option            := 'P';
        print_debug_msg(p_message=> gc_step||' Default value set for l_inv_match_option is '||l_inv_match_option ,p_force=> false);
      END IF; -- IF l_sup_site_type.INVOICE_MATCH_OPTION IS NULL
      */--Commnetd after review commnets from business
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
      --====================================================================
      --Assigning the Values to Supplier Site PL/SQL Table for Bulk Update
      --====================================================================
      l_sup_site_and_add(l_sup_site_idx).country := l_site_country_code;
      print_debug_msg(p_message=> gc_step||'l_sup_site_and_add(l_sup_site_idx).country '|| l_sup_site_and_add(l_sup_site_idx).country ,p_force=> true);
      l_sup_site_and_add(l_sup_site_idx).purchasing_site_flag       := l_purchasing_site_flag;
      l_sup_site_and_add(l_sup_site_idx).create_flag                :=l_sup_create_flag;
      l_sup_site_and_add(l_sup_site_idx).pay_site_flag              := l_pay_site_flag;
      l_sup_site_and_add(l_sup_site_idx).payment_method_lookup_code := l_payment_method;
      l_sup_site_and_add(l_sup_site_idx).tolerance_name             := l_tolerance_name;
   --   l_sup_site_and_add(l_sup_site_idx).match_option               := l_inv_match_option;
      l_sup_site_and_add(l_sup_site_idx).payment_priority           := l_payment_priority;
      l_sup_site_and_add(l_sup_site_idx).pay_group_lookup_code      := l_pay_group_code;
      l_sup_site_and_add(l_sup_site_idx).bank_charge_deduction_type := l_deduct_bank_chrg;
      l_sup_site_and_add(l_sup_site_idx).terms_date_basis           :=l_terms_date_basis;
      l_sup_site_and_add(l_sup_site_idx).always_take_disc_flag      := l_always_disc_flag;
    END IF; -- IF  gc_error_site_status_flag = 'N' -- After Supplier Site Existence Check Completed
    l_sup_site_and_add(l_sup_site_idx).supplier_name    := l_sup_site_type.supplier_name;
    L_SUP_SITE_AND_ADD(L_SUP_SITE_IDX).SUPPLIER_NUMBER  := L_SUP_SITE_TYPE.SUPPLIER_NUMBER;
    l_sup_site_and_add(l_sup_site_idx).vendor_site_code := l_sup_site_type.vendor_site_code;
    print_debug_msg(p_message=> gc_step||' l_sup_site_and_add(l_sup_site_idx).supplier_name '||l_sup_site_and_add(l_sup_site_idx).supplier_name);
    print_debug_msg(p_message=> gc_step||' l_sup_site_and_add(l_sup_site_idx).supplier_number'|| l_sup_site_and_add(l_sup_site_idx).supplier_number);
    l_sup_site_and_add(l_sup_site_idx).address_line1       := l_sup_site_type.address_line1;
    l_sup_site_and_add(l_sup_site_idx).address_line2       := l_sup_site_type.address_line2;
    l_sup_site_and_add(l_sup_site_idx).city                := l_sup_site_type.city;
    l_sup_site_and_add(l_sup_site_idx).state               := l_sup_site_type.state;
    L_SUP_SITE_AND_ADD(L_SUP_SITE_IDX).PROVINCE            := L_SUP_SITE_TYPE.PROVINCE;
    l_sup_site_and_add(l_sup_site_idx).vendor_id           := l_sup_site_type.supp_id;
    IF gc_error_site_status_flag                            = 'Y' THEN
      l_sup_site_and_add(l_sup_site_idx).site_process_flag := gn_process_status_error;
      l_sup_site_and_add(l_sup_site_idx).ERROR_FLAG        := gc_process_error_flag;
      l_sup_site_and_add(l_sup_site_idx).ERROR_MSG         := gc_error_msg;
      l_sup_site_fail                                      := 'Y';
      l_sup_site_type.ERROR_MSG                            := l_sup_site_type.ERROR_MSG||' SITE ERROR : '||gc_error_msg||';';
      print_debug_msg(p_message=> gc_step||' IF l_sup_site_idx.STG_PROCESS_FLAG ' || l_sup_site_and_add(l_sup_site_idx).site_process_flag);
    ELSE
      l_sup_site_and_add (l_sup_site_idx).site_process_flag := gn_process_status_validated;
      print_debug_msg(p_message=> gc_step||' ELSE l_sup_site_idx).STG_PROCESS_FLAG ' || l_sup_site_and_add(l_sup_site_idx).site_process_flag);
    END IF;
  END LOOP; --  FOR l_sup_site_type IN c_supplier_site
  print_debug_msg(p_message=> gc_step||' List of the site failed prefixes is '||l_error_prefix_list ,p_force=> true);
  --============================================================================
  -- For Doing the Bulk Update
  --============================================================================
  l_program_step := '';
  print_debug_msg(p_message=> l_program_step||': Do Bulk Update for all Site Records ' ,p_force=> true);
  print_debug_msg(p_message=> l_program_step||'l_sup_site_and_add.COUNT '||l_sup_site_and_add.count ,p_force=> true);
  IF l_sup_site_and_add.count > 0 THEN
    BEGIN
      print_debug_msg(p_message=> l_program_step||'gn_request_id ' ||gn_request_id ,p_force=> true);
      forall l_idxs IN l_sup_site_and_add.first .. l_sup_site_and_add.last
      UPDATE XX_AP_CLD_SUPP_SITES_STG
      SET 
	    /*
		  country                  = l_sup_site_and_add(l_idxs).country,
          purchasing_site_flag       = l_sup_site_and_add(l_idxs).purchasing_site_flag ,
          pay_site_flag              = l_sup_site_and_add(l_idxs).pay_site_flag ,
          fob_lookup_code            = l_sup_site_and_add(l_idxs).fob_lookup_code ,
          freight_terms_lookup_code  = l_sup_site_and_add(l_idxs).freight_terms_lookup_code ,
          payment_method_lookup_code = l_sup_site_and_add(l_idxs).payment_method_lookup_code ,
          match_option               = l_sup_site_and_add(l_idxs).match_option ,
          payment_priority           = l_sup_site_and_add(l_idxs).payment_priority ,
          pay_group_lookup_code      = l_sup_site_and_add(l_idxs).pay_group_lookup_code ,
          bank_charge_deduction_type = l_sup_site_and_add(l_idxs).bank_charge_deduction_type ,
          terms_date_basis           = l_sup_site_and_add(l_idxs).terms_date_basis ,
          pay_date_basis_lookup_code = l_sup_site_and_add(l_idxs).pay_date_basis_lookup_code ,
          always_take_disc_flag      = l_sup_site_and_add(l_idxs).always_take_disc_flag ,
		*/  
        site_process_flag          = l_sup_site_and_add(l_idxs).site_process_flag ,
        ERROR_FLAG                 = l_sup_site_and_add(l_idxs).ERROR_FLAG ,
        ERROR_MSG                  = l_sup_site_and_add(l_idxs).ERROR_MSG,
        create_flag                =l_sup_site_and_add(l_idxs).create_flag,
        LAST_UPDATED_BY            =g_user_id,
        LAST_UPDATE_DATE           =sysdate,
        PROCESS_FLAG               ='P',
        VENDOR_ID                  =L_SUP_SITE_AND_ADD(L_IDXS).VENDOR_ID
      WHERE 1                      =1---supplier_name          = l_sup_site_and_add(l_idxs).supplier_name
      AND vendor_site_code         =l_sup_site_and_add(l_idxs).vendor_site_code
      AND supplier_number          = l_sup_site_and_add(l_idxs).supplier_number
      AND REQUEST_ID               = gn_request_id;
      COMMIT;
    EXCEPTION
    WHEN no_data_found THEN
      l_error_message := 'When No Data Found during the bulk update of site staging table';
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When No Data Found during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_site_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    END;
  END IF; -- IF l_sup_site_and_add.COUNT > 0
  l_supsite_eligible_cnt     := 0;
  l_supsite_val_load_cnt     := 0;
  l_supsite_error_cnt        := 0;
  l_supsite_val_not_load_cnt := 0;
  l_supsite_ready_process    := 0;
  OPEN c_sup_site_stats;
  FETCH c_sup_site_stats
  INTO l_supsite_eligible_cnt,
    l_supsite_val_load_cnt,
    l_supsite_error_cnt,
    l_supsite_val_not_load_cnt,
    l_supsite_ready_process;
  CLOSE c_sup_site_stats;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  -- x_val_records   := l_supsite_val_not_load_cnt;
  -- x_inval_records := l_supsite_error_cnt + l_supsite_eligible_cnt;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => 'SUPPLIER SITE - Records Successfully Validated are '|| l_supsite_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER SITE - Records Validated and Errored are '|| l_supsite_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER SITE - Records Eligible for Validation but Untouched  are '|| l_supsite_eligible_cnt, p_force => true);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
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
    x_val_records OUT nocopy   NUMBER ,
    x_inval_records OUT nocopy NUMBER ,
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
type l_sup_cont_tab
IS
  TABLE OF XX_AP_CLD_SUPP_CONTACT_STG%rowtype INDEX BY binary_integer;
  l_sup_cont l_sup_cont_tab;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================
  CURSOR c_supplier_contact--- (c_supplier_name VARCHAR2)
  IS
    SELECT XASC.*,
      ASSI.VENDOR_ID SUPP_ID,
      APSUP.VENDOR_SITE_ID SUPP_SITE_ID
    FROM XX_AP_CLD_SUPP_CONTACT_STG XASC,
      AP_SUPPLIER_SITES_ALL APSUP,
      ap_suppliers assi
    WHERE 1                      =1--upper(apsup.vendor_name)=upper(xasc.supplier_name)
    AND APSUP.VENDOR_SITE_CODE   =XASC.VENDOR_SITE_CODE
    AND APSUP.VENDOR_ID          =ASSI.VENDOR_ID
    AND ASSI.SEGMENT1            =XASC.SUPPLIER_NUMBER
    AND XASC.CONTACT_PROCESS_FLAG=GN_PROCESS_STATUS_INPROCESS
    AND xasc.REQUEST_ID          = gn_request_id
    AND cont_target              ='EBS';
  --  AND TRIM(UPPER(xasc.SUPPLIER_NAME)) = c_supplier_name;
  --=================================================================
  -- Cursor Declarations for Duplicate check of Suppliers in Interface table
  --=================================================================
  CURSOR c_dup_supplier_chk_int(c_first_name VARCHAR2,c_last_name VARCHAR2,c_vendor_id NUMBER,c_vendor_site_id NUMBER)
  IS
    SELECT xasi.first_name,
      xasi.last_name
    FROM AP_SUP_SITE_CONTACT_INT XASI
    WHERE xasi.status      ='NEW'
    AND upper(first_name)  = upper(c_first_name)
    AND UPPER(LAST_NAME)   = UPPER(C_LAST_NAME)
    AND xasi.vendor_id     =c_vendor_id
    AND xasi.vendor_site_id=c_vendor_site_id;
  --==========================================================================================
  -- Cursor Declarations for Supplier Site existence
  --==========================================================================================
  -- CURSOR c_sup_contact_exist (c_supplier_name VARCHAR2 ,c_vendor_site_code VARCHAR2,c_first_name VARCHAR2,c_last_name VARCHAR2 )
  CURSOR c_sup_contact_exist (c_vendor_ID NUMBER ,c_vendor_site_id NUMBER,c_first_name VARCHAR2,c_last_name VARCHAR2)
  IS
    SELECT COUNT(1)
    FROM ap_suppliers asp ,
      ap_supplier_sites_all ass ,
      ap_supplier_contacts apsc ,
      hz_parties person ,
      hz_parties pty_rel,
      hr_operating_units hou
    WHERE ass.vendor_id        = asp.vendor_id
    AND apsc.per_party_id      = person.party_id
    AND apsc.rel_party_id      = pty_rel.party_id
    AND ass.org_id             = hou.organization_id
    AND APSC.ORG_PARTY_SITE_ID = ASS.PARTY_SITE_ID
    AND ASS.VENDOR_ID          =C_VENDOR_ID
    AND ass.vendor_site_id     =c_vendor_site_id
      -- AND asp.vendor_name                      = c_supplier_name
      --AND ASS.VENDOR_SITE_CODE                 =C_VENDOR_SITE_CODE
    AND TRIM(UPPER(PERSON.PERSON_FIRST_NAME))=TRIM(UPPER(C_FIRST_NAME))
    AND trim(upper(person.person_last_name)) =trim(upper(c_last_name));
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Site Staging
  --==============================================================================
  CURSOR c_sup_cont_stats
  IS
    SELECT SUM(DECODE(contact_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(contact_process_flag,6,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(contact_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(contact_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(contact_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_CONTACT_STG
    WHERE REQUEST_ID = gn_request_id
    AND cont_target  ='EBS';
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_msg_count   NUMBER        := 0;
  l_trans_count NUMBER        := 0;
  l_inval_records pls_integer := 0;
  l_val_records pls_integer   := 0;
  l_sup_cont_idx pls_integer  := 0;
  l_procedure            VARCHAR2 (30)   := 'validate_Supp_contact_records';
  l_program_step         VARCHAR2 (100)  := '';
  l_ret_code             NUMBER;
  l_return_status        VARCHAR2 (100);
  l_err_buff             VARCHAR2 (4000);
  l_sup_fail_site_depend VARCHAR2(2000);
  l_error_message        VARCHAR2(4000) := '';
  ---l_site_cnt_for_sup          NUMBER;
  l_sup_cont_exist_cnt NUMBER;
  l_sup_CREATE_FLAG    VARCHAR2(10) := '';
  l_int_segment1 ap_suppliers.segment1%type;
  l_upd_count                 NUMBER;
  l_site_upd_cnt              NUMBER;
  l_error_prefix_list         VARCHAR2(600);
  v_error_message             VARCHAR2(2000);
  v_error_flag                VARCHAR2(1);
  l_sup_cont_eligible_cnt     NUMBER := 0;
  l_sup_cont_val_load_cnt     NUMBER := 0;
  l_sup_cont_error_cnt        NUMBER := 0;
  l_sup_cont_val_not_load_cnt NUMBER := 0;
  l_sup_cont_ready_process    NUMBER := 0;
  l_int_first_name            VARCHAR2(500);
  l_int_last_name             VARCHAR2(500);
  l_stg_sup_name ap_suppliers.vendor_name%type;
  l_stg_sup_dup_cnt NUMBER := 0;
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults' ,p_force=>true);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag      := 'N';
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  print_debug_msg(p_message=> l_program_step||': Opening Supplier Conatct Cursor' ,p_force=>true);
  --==============================================================
  -- Check and Update the staging table for the Duplicate sites
  --==============================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate Contact', p_force => false);
    l_site_upd_cnt := 0;
    UPDATE XX_AP_CLD_SUPP_CONTACT_STG xassc1
    SET xassc1.contact_process_flag  = gn_process_status_error ,
      xassc1.ERROR_FLAG              = gc_process_error_flag ,
      xassc1.ERROR_MSG               = 'ERROR: Duplicate Contact in Staging Table'
    WHERE XASSC1.CONTACT_PROCESS_FLAG= GN_PROCESS_STATUS_INPROCESS
    AND xassc1.REQUEST_ID            = gn_request_id
    AND xassc1.cont_target           ='EBS'
    AND 2                           <=
      (SELECT COUNT(1)
      FROM XX_AP_CLD_SUPP_CONTACT_STG xassc2
      WHERE xassc2.contact_process_flag       IN (gn_process_status_inprocess)
      AND XASSC2.CONT_TARGET                   ='EBS'
      AND xassc2.REQUEST_ID                    = gn_request_id
      AND trim(upper(xassc2.first_name))       = trim(upper(xassc1.first_name))
      AND trim(upper(xassc2.last_name))        = trim(upper(xassc1.last_name))
      AND TRIM(UPPER(XASSC2.VENDOR_SITE_CODE)) = TRIM(UPPER(XASSC1.VENDOR_SITE_CODE))
      AND XASSC2.supplier_number               =xassc1.supplier_number
      );
    L_SITE_UPD_CNT   := SQL%ROWCOUNT;
    IF l_site_upd_cnt > 0 THEN
      PRINT_DEBUG_MSG(P_MESSAGE => 'Check and updated '||L_SITE_UPD_CNT||' records as error in the staging table for the Duplicate Conatct', P_FORCE => FALSE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate Contact in Staging table - '|| l_err_buff , p_force => true);
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
    UPDATE XX_AP_CLD_SUPP_CONTACT_STG xassc
    SET xassc.contact_process_flag = gn_process_status_error ,
      XASSC.ERROR_FLAG             = GC_PROCESS_ERROR_FLAG ,
      XASSC.ERROR_MSG              = ERROR_MSG
      ||',All Contact Values are null'
    WHERE XASSC.CONTACT_PROCESS_FLAG IN (GN_PROCESS_STATUS_INPROCESS)
    AND xassc.REQUEST_ID              = gn_request_id
    AND xassc.cont_target             ='EBS'
    AND xassc.first_name             IS NULL
    AND xassc.last_name              IS NULL
    AND xassc.area_code              IS NULL
    AND xassc.contact_name_alt       IS NULL
    AND xassc.email_address          IS NULL
    AND xassc.phone                  IS NULL
    AND xassc.fax_area_code          IS NULL
    AND xassc.fax                    IS NULL;
    l_site_upd_cnt                   := sql%rowcount;
    IF L_SITE_UPD_CNT                 >0 THEN
      PRINT_DEBUG_MSG(P_MESSAGE => 'Checked and Updated the contact Process Flag to Error for '||L_SITE_UPD_CNT||' records as all contact values are NULL for eligible site', P_FORCE => FALSE);
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR-EXCEPTION: Updating when all contacts are NULL in Staging table - '|| l_err_buff , p_force => true);
    x_ret_code      := '1';
    x_return_status := 'E';
    x_err_buf       := l_err_buff;
    RETURN;
  END;
  --====================================================================
  -- Call the Vendor Site Validations
  --====================================================================
  SET_STEP ( 'Start of Vendor Site conatct Loop Validations : ' || GC_ERROR_STATUS_FLAG);
  -- l_site_cnt_for_sup  := 0;
  l_error_prefix_list := NULL;
  --COmmented by Priyam
  FOR l_sup_site_cont_type IN c_supplier_contact--- (TRIM(UPPER(l_sup_site_type.SUPPLIER_NAME)))
  LOOP
    print_debug_msg(p_message=> gc_step||' : Validation of Supplier Site started' ,p_force=> true);
    L_SUP_CONT_IDX := L_SUP_CONT_IDX + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_cont_idx - '||l_sup_cont_idx ,p_force=> true);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'SITE_CONT';
    GC_ERROR_MSG              := '';
    OPEN c_dup_supplier_chk_int(trim(upper(l_sup_site_cont_type.first_name)),trim(upper(l_sup_site_cont_type.last_name)),l_sup_site_cont_type.supp_id,l_sup_site_cont_type.supp_site_id);
    FETCH c_dup_supplier_chk_int INTO l_int_first_name, l_int_last_name;
    CLOSE c_dup_supplier_chk_int;
    IF l_int_first_name    IS NOT NULL THEN
      gc_error_status_flag := 'Y';
      print_debug_msg(p_message=> l_program_step||' : ERROR: XXOD_SUP_EXISTS_IN_INT : Suppiler '|| l_sup_site_cont_type.supplier_name||' already exist in Interface table with ' ,p_force=> true);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name ,p_error_code => 'XXOD_SUP_EXISTS_IN_INT' ,p_error_message => 'Suppiler ' ||l_sup_site_cont_type.supplier_name||' already exist in Interface table ' ||' .' ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_sup_site_cont_type.supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
    END IF;
    --====================================================================
    -- Note Required
    --====================================================================
    IF l_sup_site_cont_type.first_name IS NULL THEN
      gc_error_site_status_flag        := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: FIRST_NAME:'||l_sup_site_cont_type.first_name|| ': XXOD_FIRST_NAME_NULL:FIRST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name ,p_error_code => 'XXOD_FIRST_NAME_NULL' ,p_error_message => 'First Name cannot be NULL' ,p_stage_col1 => 'LAST_NAME_PREFIX' ,p_stage_val1 => l_sup_site_cont_type.first_name ,p_table_name => g_sup_cont_table );
    END IF;
    IF l_sup_site_cont_type.last_name IS NULL THEN
      gc_error_site_status_flag       := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: LAST_NAME:'||l_sup_site_cont_type.first_name|| ': XXOD_LAST_NAME_NULL:LAST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name ,p_error_code => 'XXOD_LAST_NAME_NULL' ,p_error_message => 'Last Name cannot be NULL' ,p_stage_col1 => 'LAST_NAME_PREFIX' ,p_stage_val1 => l_sup_site_cont_type.last_name ,p_table_name => g_sup_cont_table );
    END IF;
    print_debug_msg(p_message=> gc_step||' After basic validation of Contact - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    l_sup_CREATE_FLAG :='';
    ----l_site_code                 := NULL;
    IF gc_error_site_status_flag = 'N' THEN
      print_debug_msg(p_message=> gc_step||' l_sup_site_cont_type.update_flag is '||l_sup_site_cont_type.CREATE_FLAG ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_site_cont_type.supplier_name) is '||upper(l_sup_site_cont_type.supplier_name) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_site_cont_type.supplier_number) is '||upper(l_sup_site_cont_type.supplier_number) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_site_cont_type.vendor_site_code) is '||upper(l_sup_site_cont_type.vendor_site_code) ,p_force=> false);
      L_SUP_CONT_EXIST_CNT := 0;
      ---OPEN c_sup_contact_exist(l_sup_site_cont_type.supplier_name , l_sup_site_cont_type.vendor_site_code,
      --L_SUP_SITE_CONT_TYPE.FIRST_NAME,L_SUP_SITE_CONT_TYPE.LAST_NAME );
      OPEN c_sup_contact_exist(l_sup_site_cont_type.supp_id,l_sup_site_cont_type.supp_site_id,l_sup_site_cont_type.first_name,l_sup_site_cont_type.last_name);
      FETCH c_sup_contact_exist INTO l_sup_cont_exist_cnt;
      CLOSE c_sup_contact_exist;
      IF l_sup_cont_exist_cnt            > 0 THEN
        l_sup_CREATE_FLAG               :='N';--update the supplier
        l_sup_site_cont_type.CREATE_FLAG:=l_sup_CREATE_FLAG;
      ELSE
        l_sup_CREATE_FLAG               := 'Y';
        l_sup_site_cont_type.CREATE_FLAG:=l_sup_CREATE_FLAG;
      END IF;
    ELSE
      l_sup_CREATE_FLAG               := '';
      gc_error_site_status_flag       := 'Y';
      l_sup_site_cont_type.CREATE_FLAG:=l_sup_CREATE_FLAG;
    END IF;
    print_debug_msg(p_message=> gc_step||' After supplier site existence check - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    print_debug_msg(p_message=> gc_step||' After supplier site existence check - l_sup_create_flag is '||l_sup_CREATE_FLAG ,p_force=> false);
    set_step('Supplier Contact Existence Check Completed');
    IF gc_error_site_status_flag = 'N' THEN -- After Supplier Site Existence Check Completed
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Phone area code
      --===============================================================================================
      IF l_sup_site_cont_type.area_code                                                                IS NOT NULL THEN
        IF (NOT (isnumeric(l_sup_site_cont_type.area_code)) OR (LENGTH(l_sup_site_cont_type.area_code) <> 3 )) THEN
          gc_error_site_status_flag                                                                    := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PHONE_AREA_CODE:'||l_sup_site_cont_type.area_code||': XXOD_PHONE_AREA_CODE_INVALID: Phone Area Code '||l_sup_site_cont_type.area_code||' should be numeric and 3 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_PHONE_AREA_CODE_INVALID' ,p_error_message => 'Phone Area Code '||l_sup_site_cont_type.area_code||' should be numeric and 3 digits.' ,p_stage_col1 => 'PHONE_AREA_CODE' ,p_stage_val1 => l_sup_site_cont_type.area_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.PHONE_AREA_CODE))
      END IF;   -- IF l_sup_site_type.PHONE_AREA_CODE IS NOT NULL THEN
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Phone Number
      --===============================================================================================
      IF l_sup_site_cont_type.phone IS NOT NULL THEN
        IF (LENGTH(l_sup_site_cont_type.phone) NOT IN (7,8) ) THEN -- Phone Number length is 7 and 1 digit count for '-'
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: PHONE_NUMBER:'||l_sup_site_cont_type.phone||': XXOD_PHONE_NUMBER_INVALID: Phone Number '||l_sup_site_cont_type.phone||' should be 7 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_PHONE_NUMBER_INVALID' ,p_error_message => 'Phone Number '||l_sup_site_cont_type.phone||' should be 7 digits.' ,p_stage_col1 => 'PHONE_NUMBER' ,p_stage_val1 => l_sup_site_cont_type.phone ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.PHONE_NUMBER))
      END IF;   -- IF l_sup_site_type.PHONE_NUMBER IS NOT NULL THEN
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Fax area code
      --===============================================================================================
      IF l_sup_site_cont_type.fax_area_code                                                                    IS NOT NULL THEN
        IF (NOT (isnumeric(l_sup_site_cont_type.fax_area_code)) OR (LENGTH(l_sup_site_cont_type.fax_area_code) <> 3 )) THEN
          gc_error_site_status_flag                                                                            := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FAX_AREA_CODE:'||l_sup_site_cont_type.fax_area_code||': XXOD_FAX_AREA_CODE_INVALID: Fax Area Code '||l_sup_site_cont_type.fax_area_code||' should be numeric and 3 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_FAX_AREA_CODE_INVALID' ,p_error_message => 'Fax Area Code '||l_sup_site_cont_type.fax_area_code||' should be numeric and 3 digits.' ,p_stage_col1 => 'FAX_AREA_CODE' ,p_stage_val1 => l_sup_site_cont_type.fax_area_code ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.FAX_AREA_CODE))
      END IF;   -- IF l_sup_site_type.FAX_AREA_CODE IS NOT NULL THEN
      --===============================================================================================
      -- Validating the Supplier Site - Address Details - Fax Number/FAX updated by Priyam
      --===============================================================================================
      IF l_sup_site_cont_type.fax IS NOT NULL THEN
        IF (LENGTH(l_sup_site_cont_type.fax) NOT IN (7,8) ) THEN -- Fax Number length is 7 and 1 digit count for '-'
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> gc_step||' ERROR: FAX_NUMBER:'||l_sup_site_cont_type.fax||': XXOD_FAX_NUMBER_INVALID: Fax Number '||l_sup_site_cont_type.fax||' should be 7 digits.' ,p_force=> true);
          insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.supplier_name , p_error_code => 'XXOD_FAX_NUMBER_INVALID' ,p_error_message => 'Fax Number '||l_sup_site_cont_type.fax||' should be 7 digits.' ,p_stage_col1 => 'FAX_NUMBER' ,p_stage_val1 => l_sup_site_cont_type.fax ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
        END IF; -- IF (NOT (isNumeric(l_sup_site_type.FAX_NUMBER))
      END IF;   -- IF l_sup_site_type.FAX_NUMBER IS NOT NULL THEN
    END IF;     -- IF  gc_error_site_status_flag = 'N' -- After Supplier Contact Existence Check Completed
    ------------------------Assigning values
    l_sup_cont(l_sup_cont_idx).CREATE_FLAG            :=l_sup_CREATE_FLAG;
    l_sup_cont(l_sup_cont_idx).vendor_site_code       :=l_sup_site_cont_type.vendor_site_code;
    L_SUP_CONT(L_SUP_CONT_IDX).SUPPLIER_NAME          :=L_SUP_SITE_CONT_TYPE.SUPPLIER_NAME;
    L_SUP_CONT(L_SUP_CONT_IDX).VENDOR_ID              :=L_SUP_SITE_CONT_TYPE.SUPP_ID;
    l_sup_cont(l_sup_cont_idx).vendor_site_id         :=l_sup_site_cont_type.supp_site_id;
    L_SUP_CONT(L_SUP_CONT_IDX).SUPPLIER_NUMBER        :=L_SUP_SITE_CONT_TYPE.SUPPLIER_NUMBER;
    l_sup_cont(l_sup_cont_idx).first_name             :=l_sup_site_cont_type.first_name;
    l_sup_cont(l_sup_cont_idx).last_name              :=l_sup_site_cont_type.last_name;
    IF GC_ERROR_SITE_STATUS_FLAG                       = 'Y' THEN
      l_sup_cont(l_sup_cont_idx).contact_process_flag := gn_process_status_error;
      l_sup_cont(l_sup_cont_idx).ERROR_FLAG           := gc_process_error_flag;
      l_sup_cont(l_sup_cont_idx).ERROR_MSG            := gc_error_msg;
      ---l_sup_site_fail                                             := 'Y';
      l_sup_site_cont_type.ERROR_MSG := l_sup_site_cont_type.ERROR_MSG||' Contact ERROR : '||gc_error_msg||';';
      print_debug_msg(p_message=> gc_step||' IF l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
    ELSE
      l_sup_cont(l_sup_cont_idx).contact_process_flag:= gn_process_status_validated;
      print_debug_msg(p_message=> gc_step||' ELSE l l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
    END IF;
	print_debug_msg(p_message=> gc_step||' ELSE l l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
  END LOOP; --  FOR l_sup_site_type IN c_supplier_contact
  print_debug_msg(p_message=> gc_step ||' List of the contact failed prefixes is '||l_error_prefix_list ,p_force=> true);
  l_program_step := '';
  print_debug_msg(p_message=> l_program_step||': Do Bulk Update for all Contact Records ' ,p_force=> true);
  print_debug_msg(p_message=> l_program_step||'l_sup_cont.COUNT '||l_sup_cont.count ,p_force=> true);
  IF l_sup_cont.count > 0 THEN
    BEGIN
      print_debug_msg(p_message=> l_program_step||'gn_request_id ' ||gn_request_id ,p_force=> true);
      forall l_idxs IN l_sup_cont.first .. l_sup_cont.last
      UPDATE XX_AP_CLD_SUPP_CONTACT_STG
      SET contact_process_flag = l_sup_cont(l_idxs).contact_process_flag,
        ERROR_FLAG             = l_sup_cont(l_idxs).ERROR_FLAG ,
        ERROR_MSG              = L_SUP_CONT(L_IDXS).ERROR_MSG,
        CREATE_FLAG            =l_sup_cont(l_idxs).CREATE_FLAG,
        LAST_UPDATED_BY        =G_USER_ID,
        LAST_UPDATE_DATE       =SYSDATE,
        VENDOR_ID              =L_SUP_CONT(L_IDXS).VENDOR_ID,
        vendor_site_id         =l_sup_cont(l_idxs).vendor_site_id
        ---   PROCESS_FLAG              ='P'
      WHERE SUPPLIER_NUMBER            = L_SUP_CONT(L_IDXS).SUPPLIER_NUMBER
      AND TRIM(UPPER(FIRST_NAME))      =TRIM(UPPER(L_SUP_CONT(L_IDXS).FIRST_NAME))
      AND trim(upper(last_name))       =trim(upper(l_sup_cont(l_idxs).last_name))
      AND trim(upper(vendor_site_code))=trim(upper(l_sup_cont(l_idxs).vendor_site_code))
      AND REQUEST_ID                   = gn_request_id
      AND cont_target                  ='EBS';
      COMMIT;
    EXCEPTION
    WHEN no_data_found THEN
      l_error_message := 'When No Data Found during the bulk update of Contact staging table';
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE_CONT' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_Contact' ,p_error_message => 'When No Data Found during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE_CONT' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    END;
  END IF;
  l_sup_cont_eligible_cnt     := 0;
  l_sup_cont_val_load_cnt     := 0;
  l_sup_cont_error_cnt        := 0;
  l_sup_cont_val_not_load_cnt := 0;
  l_sup_cont_ready_process    := 0;
  OPEN c_sup_cont_stats;
  FETCH c_sup_cont_stats
  INTO l_sup_cont_eligible_cnt,
    l_sup_cont_val_load_cnt,
    l_sup_cont_error_cnt,
    l_sup_cont_val_not_load_cnt,
    l_sup_cont_ready_process;
  CLOSE c_sup_cont_stats;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  -- x_val_records   := l_sup_cont_val_not_load_cnt;
  --  x_inval_records := l_sup_cont_error_cnt + l_sup_cont_eligible_cnt;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Successfully Validated are '|| l_sup_cont_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Validated and Errored are '|| l_sup_cont_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Eligible for Validation but Untouched  are '|| l_sup_cont_eligible_cnt, p_force => true);
  PRINT_DEBUG_MSG(P_MESSAGE => '--------------------------------------------------------------------------------------------', P_FORCE => TRUE);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_Contact_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_supp_contact_records;
PROCEDURE val_supp_contact_records_cust(
    x_val_records OUT nocopy   NUMBER ,
    x_inval_records OUT nocopy NUMBER ,
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
type l_sup_cont_tab
IS
  TABLE OF XX_AP_CLD_SUPP_CONTACT_STG%rowtype INDEX BY binary_integer;
  l_sup_cont l_sup_cont_tab;
  --==========================================================================================
  -- Cursor Declarations for Supplier Contact CUSTOM
  --==========================================================================================
  CURSOR c_supplier_contact
  IS
    SELECT XASC.*,
      apsup.vendor_site_code_alt,
      apsup.vendor_id supp_id,
      apsup.vendor_site_id supp_site_id
    FROM XX_AP_CLD_SUPP_CONTACT_STG XASC,
      AP_SUPPLIER_SITES_ALL APSUP,
      ap_suppliers assi
    WHERE 1                      =1--upper(apsup.vendor_name)=upper(xasc.supplier_name)
    AND APSUP.VENDOR_SITE_CODE   =XASC.VENDOR_SITE_CODE
    AND APSUP.VENDOR_ID          =ASSI.VENDOR_ID
    AND ASSI.SEGMENT1            =XASC.SUPPLIER_NUMBER
    AND XASC.CONTACT_PROCESS_FLAG=GN_PROCESS_STATUS_INPROCESS
    AND XASC.REQUEST_ID          = GN_REQUEST_ID
    AND cont_target              ='CUSTOM';
  --------------------
  CURSOR c_add_type(c_address_type VARCHAR2)
  IS
    SELECT COUNT(1) FROM XX_AP_SUP_ADDRESS_TYPE WHERE address_type=c_address_type;
  CURSOR C_SUP_EXIST(c_address_type VARCHAR2,c_vendor_site_code_alt VARCHAR2,c_first_name VARCHAR2,c_last_name VARCHAR2)
  IS
    SELECT COUNT(1)
      ----  INTO l_max_seq
    FROM xx_ap_sup_vendor_contact
    WHERE ltrim(key_value_1,'0') =ltrim(c_vendor_site_code_alt,'0')
    AND ADDR_TYPE_ID             =C_ADDRESS_TYPE
    AND upper(contact_name)      =trim(upper(c_first_name))
      ||' '
      ||trim(upper(c_last_name));
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Site Staging
  --==============================================================================
  CURSOR c_sup_cont_stats
  IS
    SELECT SUM(DECODE(contact_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(contact_process_flag,6,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(contact_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(contact_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(contact_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_CONTACT_STG
    WHERE REQUEST_ID =gn_request_id
    AND cont_target  ='EBS';
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_msg_count   NUMBER        := 0;
  l_trans_count NUMBER        := 0;
  l_inval_records pls_integer := 0;
  l_val_records pls_integer   := 0;
  l_sup_cont_idx pls_integer  := 0;
  l_procedure            VARCHAR2 (30)   := 'val_Supp_contact_records_cust';
  l_program_step         VARCHAR2 (100)  := '';
  l_ret_code             NUMBER;
  l_return_status        VARCHAR2 (100);
  l_err_buff             VARCHAR2 (4000);
  l_sup_fail_site_depend VARCHAR2(2000);
  l_error_message        VARCHAR2(4000) := '';
  l_site_cnt_for_sup     NUMBER;
  l_sup_cont_exist_cnt   NUMBER;
  l_sup_CREATE_FLAG      VARCHAR2(10) := '';
  l_int_segment1 ap_suppliers.segment1%type;
  l_upd_count                 NUMBER;
  l_site_upd_cnt              NUMBER;
  l_error_prefix_list         VARCHAR2(600);
  v_error_message             VARCHAR2(2000);
  v_error_flag                VARCHAR2(1);
  l_sup_cont_eligible_cnt     NUMBER := 0;
  l_sup_cont_val_load_cnt     NUMBER := 0;
  l_sup_cont_error_cnt        NUMBER := 0;
  l_sup_cont_val_not_load_cnt NUMBER := 0;
  l_sup_cont_ready_process    NUMBER := 0;
  l_sup_exists_cnt            NUMBER :=0;
  l_address_type_cnt          NUMBER :=0;
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults' ,p_force=>true);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag      := 'N';
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  print_debug_msg(p_message=> l_program_step||': Opening Supplier Conatct Cursor' ,p_force=>true);
  --==============================================================
  -- Check and Update the staging table for the Duplicate sites
  --==============================================================
  --====================================================================
  -- Call the Vendor Site Validations
  --====================================================================
  set_step ( 'Start of Vendor Contact Custom  Loop Validations : ' || gc_error_status_flag);
  l_site_cnt_for_sup  := 0;
  l_error_prefix_list := NULL;
  --COmmented by Priyam
  FOR l_sup_site_cont_type IN c_supplier_contact--- (TRIM(UPPER(l_sup_site_type.SUPPLIER_NAME)))
  LOOP
    print_debug_msg(p_message=> gc_step||' : Validation of Supplier Contact Custom started' ,p_force=> true);
    l_sup_cont_idx     := l_sup_cont_idx     + 1;
    l_site_cnt_for_sup := l_site_cnt_for_sup + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_cont_idx - '||l_sup_cont_idx ,p_force=> true);
    GC_ERROR_SITE_STATUS_FLAG := 'N';
    gc_step                   := 'SITE_CONT_cust';
    gc_error_msg              := '';
    print_debug_msg(p_message=> gc_step||' : l_sup_site_cont_type.address_type '||l_sup_site_cont_type.address_type , p_force=> true);
    OPEN c_add_type(l_sup_site_cont_type.address_type);
    FETCH c_add_type INTO l_address_type_cnt;
    CLOSE c_add_type;
    IF l_address_type_cnt   = 0 THEN
      gc_error_status_flag := 'Y';
      print_debug_msg(p_message=> l_program_step||' : ERROR: XXOD_ADDRESS_TYPE : Suppiler ' || l_sup_site_cont_type.supplier_name||' already exist in Interface table with ' ,p_force=> true);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_site_cont_type.address_type ,p_error_code => 'XXOD_ADDRESS_TYPE' , p_error_message => 'Suppiler ' ||l_sup_site_cont_type.supplier_name||' address type doesnot exists ' ||' .' , p_stage_col1 => 'SUPPLIER_NAME' , p_stage_val1 => l_sup_site_cont_type.address_type , p_stage_col2 => NULL ,p_stage_val2 => NULL , p_table_name => g_sup_cont_table );
    END IF;
    print_debug_msg(p_message=> gc_step||' : l_address_type_cnt '||l_address_type_cnt , p_force=> true);
    print_debug_msg(p_message=> gc_step||' : l_sup_site_cont_type.vendor_site_code_alt '||l_sup_site_cont_type.vendor_site_code_alt , p_force=> true);
    print_debug_msg(p_message=> gc_step||' : l_sup_site_cont_type.address_type '||l_sup_site_cont_type.address_type , p_force=> true);
    OPEN C_SUP_EXIST(L_SUP_SITE_CONT_TYPE.ADDRESS_TYPE, L_SUP_SITE_CONT_TYPE.VENDOR_SITE_CODE_ALT, l_sup_site_cont_type.first_name,l_sup_site_cont_type.last_name);
    FETCH c_sup_exist INTO l_sup_exists_cnt;
    CLOSE c_sup_exist;
    IF l_sup_exists_cnt = 0 THEN
      print_debug_msg(p_message=> l_program_step||' No record exists so create it ' ,p_force=> true);
      l_sup_CREATE_FLAG:='Y';
    ELSE
      print_debug_msg(p_message=> l_program_step||' Record exists so update it ' ,p_force=> true);
      l_sup_CREATE_FLAG:='N';
    END IF;
    print_debug_msg(p_message=> gc_step||' : l_sup_exists_cnt '||l_sup_exists_cnt , p_force=> true);
    --====================================================================
    -- Note Required
    --====================================================================
    ------------------------Assigning values
    l_sup_cont(l_sup_cont_idx).CREATE_FLAG            :=l_sup_CREATE_FLAG;
    l_sup_cont(l_sup_cont_idx).vendor_site_code       :=l_sup_site_cont_type.vendor_site_code;
    l_sup_cont(l_sup_cont_idx).supplier_name          :=l_sup_site_cont_type.supplier_name;
    l_sup_cont(l_sup_cont_idx).supplier_number        :=l_sup_site_cont_type.supplier_number;
    L_SUP_CONT(L_SUP_CONT_IDX).VENDOR_ID              :=L_SUP_SITE_CONT_TYPE.SUPP_ID;
    l_sup_cont(l_sup_cont_idx).vendor_site_id         :=l_sup_site_cont_type.supp_site_id;
    l_sup_cont(l_sup_cont_idx).First_name             :=l_sup_site_cont_type.First_name;
    l_sup_cont(l_sup_cont_idx).last_name              :=l_sup_site_cont_type.last_name;
    IF gc_error_site_status_flag                       = 'Y' THEN
      l_sup_cont(l_sup_cont_idx).contact_process_flag := gn_process_status_error;
      l_sup_cont(l_sup_cont_idx).ERROR_FLAG           := gc_process_error_flag;
      l_sup_cont(l_sup_cont_idx).ERROR_MSG            := gc_error_msg;
      ---l_sup_site_fail                                             := 'Y';
      l_sup_site_cont_type.ERROR_MSG := l_sup_site_cont_type.ERROR_MSG||' Contact ERROR : '||gc_error_msg||';';
      print_debug_msg(p_message=> gc_step||' IF l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
    ELSE
      l_sup_cont(l_sup_cont_idx).contact_process_flag:= gn_process_status_validated;
      print_debug_msg(p_message=> gc_step||' ELSE l l_sup_cont(l_sup_cont_idx).contact_process_flag' || l_sup_cont(l_sup_cont_idx).contact_process_flag);
    END IF;
  END LOOP; --  FOR l_sup_site_type IN c_supplier_contact
  print_debug_msg(p_message=> gc_step ||' List of the contact failed prefixes is '||l_error_prefix_list ,p_force=> true);
  l_program_step := '';
  print_debug_msg(p_message=> l_program_step||': Do Bulk Update for all Contact Records ' ,p_force=> true);
  print_debug_msg(p_message=> l_program_step||'l_sup_cont.COUNT '||l_sup_cont.count ,p_force=> true);
  IF l_sup_cont.count > 0 THEN
    BEGIN
      print_debug_msg(p_message=> l_program_step||'gn_request_id ' ||gn_request_id ,p_force=> true);
      forall l_idxs IN l_sup_cont.first .. l_sup_cont.last
      UPDATE XX_AP_CLD_SUPP_CONTACT_STG
      SET contact_process_flag         = l_sup_cont(l_idxs).contact_process_flag,
        ERROR_FLAG                     = l_sup_cont(l_idxs).ERROR_FLAG ,
        ERROR_MSG                      = l_sup_cont(l_idxs).ERROR_MSG,
        CREATE_FLAG                    =l_sup_cont(l_idxs).CREATE_FLAG,
        LAST_UPDATED_BY                =G_USER_ID,
        LAST_UPDATE_DATE               =SYSDATE,
        VENDOR_ID                      =L_SUP_CONT(L_IDXS).VENDOR_ID,
        VENDOR_SITE_ID                 =L_SUP_CONT(L_IDXS).VENDOR_SITE_ID
      WHERE 1                          =1
      AND REQUEST_ID                   = GN_REQUEST_ID
      AND SUPPLIER_NUMBER              = L_SUP_CONT(L_IDXS).SUPPLIER_NUMBER
      AND TRIM(UPPER(FIRST_NAME))      =TRIM(UPPER(L_SUP_CONT(L_IDXS).FIRST_NAME))
      AND TRIM(UPPER(LAST_NAME))       =TRIM(UPPER(L_SUP_CONT(L_IDXS).LAST_NAME))
      AND trim(upper(vendor_site_code))=trim(upper(l_sup_cont(l_idxs).vendor_site_code))
      AND cont_target                  ='CUSTOM';
      COMMIT;
    EXCEPTION
    WHEN no_data_found THEN
      l_error_message := 'When No Data Found during the bulk update of Contact staging table';
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_Contact' ,p_error_message => 'When No Data Found during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_cont_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    END;
  END IF;
  l_sup_cont_eligible_cnt     := 0;
  l_sup_cont_val_load_cnt     := 0;
  l_sup_cont_error_cnt        := 0;
  l_sup_cont_val_not_load_cnt := 0;
  l_sup_cont_ready_process    := 0;
  OPEN c_sup_cont_stats;
  FETCH c_sup_cont_stats
  INTO l_sup_cont_eligible_cnt,
    l_sup_cont_val_load_cnt,
    l_sup_cont_error_cnt,
    l_sup_cont_val_not_load_cnt,
    l_sup_cont_ready_process;
  CLOSE c_sup_cont_stats;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  -- x_val_records   := l_sup_cont_val_not_load_cnt;
  -- x_inval_records := l_sup_cont_error_cnt + l_sup_cont_eligible_cnt;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Successfully Validated are '|| l_sup_cont_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Validated and Errored are '|| l_sup_cont_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Eligible for Validation but Untouched  are '|| l_sup_cont_eligible_cnt, p_force => true);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_Contact_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END val_supp_contact_records_cust;
--+============================================================================+
--| Name          : validate_suppsite_bank_records                                           |
--| Description   : This procedure will validate Supplier Bank Records  |
--|                                                                            |
--| Parameters    : p_vendor_is                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE validate_suppsite_bank_records(
    x_val_records OUT nocopy   NUMBER ,
    x_inval_records OUT nocopy NUMBER ,
    x_ret_code OUT NUMBER,
    x_return_status OUT VARCHAR2,
    x_err_buf OUT VARCHAR2)
IS
  --==========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
  --==========================================================================================
type l_sup_bank_tab
IS
  TABLE OF XX_AP_CLD_SUPP_BNKACT_STG%rowtype INDEX BY binary_integer;
  l_sup_bank l_sup_bank_tab;
  --==========================================================================================
  -- Cursor Declarations for Supplier Sites
  --==========================================================================================
  CURSOR c_supplier_BANK
  IS
    SELECT XASC.*,
      apsup.vendor_id supp_id,
      APSUP.VENDOR_SITE_CODE SUPP_SITE_CODE,
      apsup.vendor_site_id supp_site_id
    FROM XX_AP_CLD_SUPP_BNKACT_STG xasc,
      AP_SUPPLIER_SITES_ALL APSUP,
      ap_suppliers assi
    WHERE XASC.BNKACT_PROCESS_FLAG IN (GN_PROCESS_STATUS_INPROCESS)
    AND XASC.REQUEST_ID             = gn_request_id
    AND apsup.vendor_site_code      =xasc.vendor_site_code
    AND ASSI.VENDOR_ID              =APSUP.VENDOR_ID
    AND assi.segment1               =xasc.supplier_num;
  --  AND TRIM(UPPER(xasc.SUPPLIER_NAME)) = c_supplier_name;
  CURSOR C_BANK_EXISTS(C_BANK_NAME VARCHAR2,C_COUNTRY_CODE VARCHAR2)
  IS
    SELECT bank_party_id bank_id
    FROM IBY_EXT_BANKS_V
    WHERE BANK_NAME             =C_BANK_NAME
    AND NVL(END_DATE,SYSDATE+1) >SYSDATE
    AND home_country            =C_COUNTRY_CODE;
  CURSOR c_branch_exists(c_bank_id NUMBER,c_branch_name VARCHAR2)
  IS
    SELECT branch_party_id branch_id
    FROM IBY_EXT_BANK_BRANCHES_V
    WHERE BANK_PARTY_ID =c_bank_id
    AND bank_branch_name=c_branch_name;
  --==========================================================================================
  -- Cursor Declarations for Supplier Site existence
  --==========================================================================================
  CURSOR C_SUP_ASSIG_EXISTS( C_VENDOR_SITE_CODE VARCHAR2, C_BRANCH_NAME VARCHAR2, C_BANK_NAME VARCHAR2, C_VENDOR_ID NUMBER, c_vendor_site_id NUMBER)
  IS
    SELECT instrument.instrument_id
    FROM iby_pmt_instr_uses_all instrument,
      iby_account_owners owners,
      iby_external_payees_all payees,
      iby_ext_bank_accounts ieb,
      ap_supplier_sites_all asa,
      ap_suppliers asp,
      ce_bank_branches_v cbbv
    WHERE owners.primary_flag      = 'Y'
    AND owners.ext_bank_account_id = ieb.ext_bank_account_id
    AND owners.ext_bank_account_id = instrument.instrument_id
    AND payees.ext_payee_id        = instrument.ext_pmt_party_id
    AND payees.payee_party_id      = owners.account_owner_party_id
    AND payees.supplier_site_id    = asa.vendor_site_id
    AND asa.vendor_id              = asp.vendor_id
    AND cbbv.branch_party_id(+)    = ieb.branch_id
      --and asp.vendor_name like '%ABC Emp, Name'
      -- AND ASP.VENDOR_NAME      =C_VENDOR_NAME
      -- AND ASP.SEGMENT1         =C_SUPPLIER_NUMBER
    AND ASA.VENDOR_SITE_CODE =C_VENDOR_SITE_CODE
    AND CBBV.bank_BRANCH_NAME=C_BRANCH_NAME
    AND CBBV.BANK_NAME       =C_BANK_NAME
    AND ASP.VENDOR_ID        =C_VENDOR_ID
    AND ASA.VENDOR_SITE_ID   =C_VENDOR_SITE_ID;
  --ext_bank_account_id;
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Site Staging
  --==============================================================================
  CURSOR c_sup_cont_stats
  IS
    SELECT SUM(DECODE(site_process_flag,2,1,0)) -- Eligible to Validate and Load
      ---SuM(DECODE(STG_PROCESS_FLAG,6,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(site_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(site_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(site_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_SITES_STG
    WHERE REQUEST_ID = gn_request_id;
  --==========================================================================================
  -- Declaring Local variables
  --==========================================================================================
  l_msg_count   NUMBER        := 0;
  l_trans_count NUMBER        := 0;
  l_inval_records pls_integer := 0;
  l_val_records pls_integer   := 0;
  -- l_sup_bank_idx PLS_INTEGER       := 0;
  l_sup_bank_idx pls_integer := 0;
  --- l_sup_bank_idx PLS_INTEGER  := 0;
  l_procedure                 VARCHAR2 (30)  := 'validate_SuppSite_Bank_records';
  l_program_step              VARCHAR2 (100) := '';
  l_ret_code                  NUMBER;
  l_return_status             VARCHAR2 (100);
  l_err_buff                  VARCHAR2 (4000);
  l_sup_fail_site_depend      VARCHAR2(2000);
  l_error_message             VARCHAR2(4000) := '';
  l_site_cnt_for_bank         NUMBER;
  l_sup_bank_exist_cnt        NUMBER;
  v_error_message             VARCHAR2(2000);
  v_error_flag                VARCHAR2(1);
  l_sup_bank_eligible_cnt     NUMBER := 0;
  l_sup_bank_val_load_cnt     NUMBER := 0;
  l_sup_bank_error_cnt        NUMBER := 0;
  l_sup_bank_val_not_load_cnt NUMBER := 0;
  l_sup_bank_ready_process    NUMBER := 0;
  l_int_first_name            VARCHAR2(500);
  l_int_last_name             VARCHAR2(500);
  l_stg_sup_name ap_suppliers.vendor_name%type;
  l_stg_sup_dup_cnt    NUMBER       := 0;
  l_bank_upd_cnt       NUMBER       :=0;
  l_bank_CREATE_FLAG   VARCHAR2(10) := '';
  L_SUP_BANK_ID        NUMBER;
  L_SUP_BANK_branch_ID NUMBER;
  L_BANK_ACCOUNT_ID    NUMBER;
  l_instrument_id      NUMBER;
BEGIN
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults' ,p_force=>true);
  --==========================================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==========================================================================================
  gc_error_status_flag      := 'N';
  gc_error_site_status_flag := 'N';
  l_error_message           := NULL;
  gc_error_msg              := '';
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  print_debug_msg(p_message=> l_program_step||': Opening Supplier Conatct Cursor' ,p_force=>true);
  --==============================================================
  -- Check and Update the staging table for the Duplicate sites
  --==============================================================
  BEGIN
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate bank', p_force => false);
    l_bank_upd_cnt := 0;
    UPDATE XX_AP_CLD_SUPP_BNKACT_STG xassc1
    SET xassc1.bnkact_process_flag   = gn_process_status_error ,
      xassc1.ERROR_FLAG              = gc_process_error_flag ,
      xassc1.ERROR_MSG               = 'ERROR: Duplicate Bank assignment in Staging Table'
    WHERE XASSC1.BNKACT_PROCESS_FLAG = GN_PROCESS_STATUS_INPROCESS
    AND xassc1.REQUEST_ID            = gn_request_id
    AND 2                           <=
      (SELECT COUNT(1)
      FROM XX_AP_CLD_SUPP_BNKACT_STG xassc2
      WHERE XASSC2.BNKACT_PROCESS_FLAG        IN (GN_PROCESS_STATUS_INPROCESS)
      AND xassc2.REQUEST_ID                    = gn_request_id
      AND trim(upper(xassc2.supplier_num))     = trim(upper(xassc1.supplier_num))
      AND trim(upper(xassc2.vendor_site_code)) = trim(upper(xassc1.vendor_site_code))
      AND trim(upper(xassc2.bank_name))        = trim(upper(xassc1.bank_name))
      AND TRIM(UPPER(XASSC2.BRANCH_NAME))      = TRIM(UPPER(XASSC1.BRANCH_NAME))
      AND XASSC2.bank_account_num              = XASSC1.bank_account_num
        --  AND XASSC2.VENDOR_ID                     =XASSC1.VENDOR_ID
        --  AND XASSC2.vendor_site_id                =XASSC2.vendor_site_id
      );
    l_bank_upd_cnt := sql%rowcount;
    print_debug_msg(p_message => 'Check and updated '||l_bank_upd_cnt||' records as error in the staging table for the Duplicate Conatct', p_force => false);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate bank assignment in Staging table - '|| l_err_buff , p_force => true);
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
    l_bank_upd_cnt := 0;
    UPDATE XX_AP_CLD_SUPP_BNKACT_STG xassc
    SET xassc.bnkact_process_flag = gn_process_status_error ,
      XASSC.ERROR_FLAG            = GC_PROCESS_ERROR_FLAG ,
      xassc.ERROR_MSG             = ERROR_MSG
      ||',Bank or branch information is null'
    WHERE XASSC.BNKACT_PROCESS_FLAG IN (GN_PROCESS_STATUS_INPROCESS)
    AND xassc.REQUEST_ID             = gn_request_id
    AND xassc.bank_name             IS NULL
    OR xassc.branch_name            IS NULL ;
    l_bank_upd_cnt                  := sql%rowcount;
    print_debug_msg(p_message => 'Bank or branch information is null', p_force => false);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR-EXCEPTION: Bank or branch information is null - '|| l_err_buff , p_force => true);
    x_ret_code      := '1';
    x_return_status := 'E';
    x_err_buf       := l_err_buff;
    RETURN;
  END;
  --====================================================================
  -- Call the Vendor Site Validations
  --====================================================================
  set_step ( 'Start of Vendor Site conatct Loop Validations : ' || gc_error_status_flag);
  l_site_cnt_for_bank := 0;
  FOR l_sup_bank_type IN c_supplier_bank
  LOOP
    print_debug_msg(p_message=> gc_step||' : Validation of Supplier Site started' ,p_force=> true);
    l_sup_bank_idx      := l_sup_bank_idx      + 1;
    l_site_cnt_for_bank := l_site_cnt_for_bank + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_bank_idx - '||l_sup_bank_idx ,p_force=> true);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'BANK_ASSI_CONT';
    gc_error_msg              := '';
    --====================================================================
    -- Note Required
    --====================================================================
    IF l_sup_bank_type.supplier_name IS NULL THEN
      gc_error_site_status_flag      := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: supplier_name:' ||l_sup_bank_type.supplier_name|| ': XXOD_supplier_NAME_NULL:FIRST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_bank_type.supplier_name , p_error_code => 'XXOD_supplier_NAME_NULL' ,p_error_message => 'supplier_name cannot be NULL' , p_stage_col1 => 'XXOD_supplier_NAME_NULL' ,p_stage_val1 => l_sup_bank_type.supplier_name ,p_table_name => g_sup_bank_table );
    END IF;
    IF l_sup_bank_type.supplier_num IS NULL THEN
      gc_error_site_status_flag     := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: supplier_num:' ||l_sup_bank_type.supplier_num|| ': XXOD_supplier_num_NULL:LAST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_bank_type.supplier_num ,p_error_code => 'XXOD_supplier_num_NULL' , p_error_message => 'supplier Num cannot be NULL' ,p_stage_col1 => 'XXOD_supplier_num_NULL' , p_stage_val1 => l_sup_bank_type.supplier_num ,p_table_name => g_sup_bank_table );
    END IF;
    IF l_sup_bank_type.vendor_site_code IS NULL THEN
      gc_error_site_status_flag         := 'Y';
      print_debug_msg(p_message=> gc_step||' ERROR: vendor_site_code:' ||l_sup_bank_type.vendor_site_code|| ': XXOD_vendor_site_code_NULL:LAST_NAME cannot be NULL' ,p_force=> false);
      insert_error (p_program_step => gc_step ,p_primary_key => l_sup_bank_type.vendor_site_code ,p_error_code => 'XXOD_vendor_site_code_NULL' , p_error_message => 'vendor_site_code cannot be NULL' ,p_stage_col1 => 'XXOD_vendor_site_code_NULL' , p_stage_val1 => l_sup_bank_type.vendor_site_code ,p_table_name => g_sup_bank_table );
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  Address Line 2
    --==============================================================================================================
    print_debug_msg(p_message=> gc_step||' After basic validation of Contact - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
    l_bank_CREATE_FLAG :='';
    ----l_site_code                 := NULL;
    IF gc_error_site_status_flag = 'N' THEN
      print_debug_msg(p_message=> gc_step||' l_sup_bank_type.update_flag is '||l_sup_bank_type.CREATE_FLAG ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_bank_type.supplier_name) is '||upper(l_sup_bank_type.supplier_name) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_bank_type.supplier_number) is '||upper(l_sup_bank_type.supplier_num) ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_bank_type.vendor_site_code) is '||upper(l_sup_bank_type.vendor_site_code) ,p_force=> false);
      OPEN C_BANK_EXISTS(L_SUP_BANK_TYPE.BANK_NAME,L_SUP_BANK_TYPE.COUNTRY_CODE);
      FETCH C_BANK_EXISTS INTO L_SUP_BANK_ID;
      CLOSE C_BANK_EXISTS;
      print_debug_msg(p_message => 'L_SUP_BANK_ID '||L_SUP_BANK_ID, p_force => false);
      IF L_SUP_BANK_ID            IS NULL THEN
        gc_error_site_status_flag := 'Y';
        INSERT_ERROR (P_PROGRAM_STEP => GC_STEP , P_PRIMARY_KEY => L_SUP_BANK_TYPE.BANK_NAME , P_ERROR_CODE => 'XXOD_BANK_NULL' , P_ERROR_MESSAGE => 'Bank Information is null ' ||L_SUP_BANK_TYPE.BANK_NAME,P_STAGE_COL1 => 'XXOD_BANK_NULL' , P_STAGE_VAL1 => L_SUP_BANK_TYPE.BANK_NAME , P_TABLE_NAME => G_SUP_BANK_TABLE );
      ELSE
        L_SUP_BANK_TYPE.bank_id :=L_SUP_BANK_ID;
        OPEN C_BRANCH_EXISTS(L_SUP_BANK_ID,L_SUP_BANK_TYPE.BRANCH_NAME);
        FETCH c_branch_exists INTO L_SUP_BANK_branch_ID;
        CLOSE c_branch_exists;
        print_debug_msg(p_message => 'L_SUP_BANK_branch_ID '||L_SUP_BANK_branch_ID, p_force => false);
        IF L_SUP_BANK_branch_ID     IS NULL THEN
          gc_error_site_status_flag := 'Y';
          INSERT_ERROR (P_PROGRAM_STEP => GC_STEP , P_PRIMARY_KEY => L_SUP_BANK_TYPE.branch_name , P_ERROR_CODE => 'XXOD_BANK_BRANCH_NULL' , P_ERROR_MESSAGE => 'Bank Information is null ' ||L_SUP_BANK_TYPE.branch_name,P_STAGE_COL1 => 'XXOD_BANK_BRANCH_NULL' , P_STAGE_VAL1 => L_SUP_BANK_TYPE.branch_name , P_TABLE_NAME => G_SUP_BANK_TABLE );
        ELSE
          L_SUP_BANK_TYPE.BRANCH_ID :=L_SUP_BANK_BRANCH_ID;
          --- Call Bank Exists API
          CHECK_BANK_ACC_EXISTS( L_SUP_BANK_ID , L_SUP_BANK_BRANCH_ID , L_SUP_BANK_TYPE.bank_ACCOUNT_NUM, L_SUP_BANK_TYPE.BANK_ACCOUNT_NAME, L_SUP_BANK_TYPE.CURRENCY_CODE, L_SUP_BANK_TYPE.COUNTRY_CODE, L_BANK_ACCOUNT_ID);
          print_debug_msg(p_message => 'L_BANK_ACCOUNT_ID '||L_BANK_ACCOUNT_ID, p_force => false);
          IF L_BANK_ACCOUNT_ID         IS NOT NULL THEN
            L_SUP_BANK_TYPE.account_id :=L_BANK_ACCOUNT_ID;
            L_SUP_BANK_EXIST_CNT       := 0;
            OPEN C_SUP_ASSIG_EXISTS( L_SUP_BANK_TYPE.VENDOR_SITE_CODE, L_SUP_BANK_TYPE.BRANCH_NAME, L_SUP_BANK_TYPE.BANK_NAME, L_SUP_BANK_TYPE.SUPP_ID, L_SUP_BANK_TYPE.SUPP_SITE_ID);
            FETCH C_SUP_ASSIG_EXISTS INTO l_instrument_id;
            CLOSE C_SUP_ASSIG_EXISTS;
            print_debug_msg(p_message => 'l_instrument_id '||l_instrument_id, p_force => false);
            IF l_instrument_id           IS NULL THEN
              L_BANK_CREATE_FLAG         :='Y';--Create the Joint owner and instrument
              L_SUP_BANK_TYPE.CREATE_FLAG:=L_BANK_CREATE_FLAG;
            ELSE
              L_SUP_BANK_TYPE.CREATE_FLAG        :=NULL;
              L_SUP_BANK_TYPE.instrument_uses_id :=l_instrument_id;
            END IF;                  --l_instrument_id is null
          ELSE                      ---L_BANK_ACCOUNT_ID IS NOT NULL THEN
            L_BANK_CREATE_FLAG         :='Y';--Create the Account and Instrument
            L_SUP_BANK_TYPE.CREATE_FLAG:=L_BANK_CREATE_FLAG;
          END IF;
        END IF;---L_SUP_BANK_branch_ID is null
      END IF;  ---L_SUP_BANK_ID is null THEN
      print_debug_msg(p_message=> gc_step||' After supplier site existence check - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> false);
      print_debug_msg(p_message=> gc_step||' After supplier site existence check - l_bank_CREATE_FLAG is '||l_bank_CREATE_FLAG ,p_force=> false);
      set_step('Supplier Site Existence Check Completed');
      ------------------------Assigning values
      l_sup_bank(l_sup_bank_idx).CREATE_FLAG        :=l_bank_CREATE_FLAG;
      l_sup_bank(l_sup_bank_idx).vendor_site_code   :=l_sup_bank_type.vendor_site_code;
      l_sup_bank(l_sup_bank_idx).supplier_name      :=l_sup_bank_type.supplier_name;
      l_sup_bank(l_sup_bank_idx).supplier_num       :=l_sup_bank_type.supplier_num;
      l_sup_bank(l_sup_bank_idx).bank_name          :=l_sup_bank_type.bank_name;
      l_sup_bank(l_sup_bank_idx).branch_name        :=l_sup_bank_type.branch_name;
      L_SUP_BANK(L_SUP_BANK_IDX).VENDOR_ID          :=L_SUP_BANK_TYPE.SUPP_ID;
      L_SUP_BANK(L_SUP_BANK_IDX).VENDOR_SITE_ID     :=L_SUP_BANK_TYPE.SUPP_SITE_ID;
      L_SUP_BANK(L_SUP_BANK_IDX).BANK_ACCOUNT_NUM   :=L_SUP_BANK_TYPE.BANK_ACCOUNT_NUM;
      L_SUP_BANK(L_SUP_BANK_IDX).INSTRUMENT_USES_ID :=L_INSTRUMENT_ID;
      L_SUP_BANK(L_SUP_BANK_IDX).BANK_ID            :=L_SUP_BANK_ID;
      L_SUP_BANK(L_SUP_BANK_IDX).BRANCH_ID          :=L_SUP_BANK_BRANCH_ID;
      l_sup_bank(l_sup_bank_idx).account_id         :=L_bank_account_id;
    END IF;
    IF gc_error_site_status_flag                      = 'Y' THEN
      l_sup_bank(l_sup_bank_idx).bnkact_process_flag := gn_process_status_error;
      l_sup_bank(l_sup_bank_idx).ERROR_FLAG          := gc_process_error_flag;
      l_sup_bank(l_sup_bank_idx).ERROR_MSG           := gc_error_msg;
      ---l_sup_site_fail                                             := 'Y';
      l_sup_bank_type.ERROR_MSG := l_sup_bank_type.ERROR_MSG||' Contact ERROR : '||gc_error_msg||';';
      print_debug_msg(p_message=> gc_step||' IF l_sup_bank(l_sup_bank_idx).bnkact_process_flag ' || l_sup_bank(l_sup_bank_idx).bnkact_process_flag);
    ELSE
      l_sup_bank(l_sup_bank_idx).bnkact_process_flag := gn_process_status_validated;
      print_debug_msg(p_message=> gc_step||' ELSE l l_sup_bank(l_sup_bank_idx).bnkact_process_flag ' || l_sup_bank(l_sup_bank_idx).bnkact_process_flag);
    END IF;
  END LOOP; --  FOR l_sup_site_type IN c_supplier_contact
  L_PROGRAM_STEP := '';
  print_debug_msg(p_message=> l_program_step||': Do Bulk Update for all BANK Records ' ,p_force=> true);
  print_debug_msg(p_message=> l_program_step||'l_sup_bank.COUNT '||l_sup_bank.count ,p_force=> true);
  IF l_sup_bank.count > 0 THEN
    BEGIN
      print_debug_msg(p_message=> l_program_step||'gn_request_id ' ||gn_request_id ,p_force=> true);
      forall l_idxs IN l_sup_bank.first .. l_sup_bank.last
      UPDATE XX_AP_CLD_SUPP_BNKACT_STG
      SET bnkact_process_flag          = l_sup_bank(l_idxs).bnkact_process_flag ,
        ERROR_FLAG                     = l_sup_bank(l_idxs).ERROR_FLAG ,
        ERROR_MSG                      = l_sup_bank(l_idxs).ERROR_MSG,
        CREATE_FLAG                    =l_sup_bank(l_idxs).CREATE_FLAG,
        last_updated_by                =g_user_id,
        LAST_UPDATE_DATE               =SYSDATE,
        VENDOR_ID                      =L_SUP_BANK(L_IDXS).VENDOR_ID,
        VENDOR_SITE_ID                 =L_SUP_BANK(L_IDXS).VENDOR_SITE_ID,
        INSTRUMENT_USES_ID             =L_SUP_BANK(L_IDXS).INSTRUMENT_USES_ID,
        BANK_ID                        =L_SUP_BANK(L_IDXS).BANK_ID,
        BRANCH_ID                      =l_sup_bank(l_idxs).branch_id,
        account_id                     =l_sup_bank(l_idxs).account_id
      WHERE 1                          =1
      AND trim(upper(vendor_site_code))=trim(upper(l_sup_bank(l_idxs).vendor_site_code))
      AND upper(supplier_num)          =upper(l_sup_bank(l_idxs).supplier_num)
      AND upper(bank_name)             =upper(l_sup_bank(l_idxs).bank_name)
      AND UPPER(BRANCH_NAME)           =UPPER(L_SUP_BANK(L_IDXS).BRANCH_NAME)
      AND bank_account_num             =L_SUP_BANK(L_IDXS).bank_account_num
      AND REQUEST_ID                   = gn_request_id;
      COMMIT;
    EXCEPTION
    WHEN no_data_found THEN
      l_error_message := 'When No Data Found during the bulk update of Contact staging table';
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE_BANK' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_Contact' ,p_error_message => 'When No Data Found during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_bank_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      --============================================================================
      -- To Insert into Common Error Table
      --============================================================================
      insert_error (p_program_step => 'SITE_BANK' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of site staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_bank_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
    END;
  END IF;
  l_sup_bank_eligible_cnt     := 0;
  l_sup_bank_val_load_cnt     := 0;
  l_sup_bank_error_cnt        := 0;
  l_sup_bank_val_not_load_cnt := 0;
  l_sup_bank_ready_process    := 0;
  OPEN c_sup_cont_stats;
  FETCH c_sup_cont_stats
  INTO l_sup_bank_eligible_cnt,
    -- l_sup_bank_val_load_cnt,
    l_sup_bank_error_cnt,
    l_sup_bank_val_not_load_cnt,
    l_sup_bank_ready_process;
  CLOSE c_sup_cont_stats;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
  -- x_val_records   := l_sup_bank_val_not_load_cnt;
  -- x_inval_records := l_sup_bank_error_cnt + l_sup_bank_eligible_cnt;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Successfully Validated are '|| l_sup_bank_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Validated and Errored are '|| l_sup_bank_error_cnt, p_force => true);
  print_debug_msg(p_message => 'SUPPLIER Contact - Records Eligible for Validation but Untouched  are '|| l_sup_bank_eligible_cnt, p_force => true);
  PRINT_DEBUG_MSG(P_MESSAGE => '--------------------------------------------------------------------------------------------', P_FORCE => TRUE);
EXCEPTION
WHEN OTHERS THEN
  l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
  print_debug_msg(p_message => 'ERROR: Exception in validate_Supplier_Contact_records() API - '|| l_err_buff , p_force => true);
  x_ret_code      := '2';
  x_return_status := 'E';
  x_err_buf       := l_err_buff;
END validate_suppsite_bank_records;
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
PROCEDURE load_supplier_interface(
    x_processed_records OUT NUMBER ,
    x_unprocessed_records OUT NUMBER ,
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2 )
IS
  --=========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for processing
  --=========================================================================================
type l_sup_tab
IS
  TABLE OF XX_AP_CLD_SUPPLIERS_STG%rowtype INDEX BY binary_integer;
  --=================================================================
  -- Declaring Local variables
  --=================================================================
  l_supplier_type l_sup_tab;
  l_supplier_rec ap_vendor_pub_pkg.r_vendor_rec_type;
  l_vendor_intf_id NUMBER DEFAULT 0;
  --- l_vendor_site_intf_id NUMBER DEFAULT 0;
  l_error_message VARCHAR2 (2000) DEFAULT NULL;
  l_procedure     VARCHAR2 (30)   := 'load_Supplier_Interface';
  l_msg_data      VARCHAR2 (2000) := NULL;
  l_msg_count     NUMBER          := 0;
  l_trans_count   NUMBER          := 0;
  lp_loopcont pls_integer         := 0;
  lp_loopcnt pls_integer          := 0;
  l_exception_msg        VARCHAR2 (1000);
  l_sup_processed_recs   NUMBER := 0;
  l_sup_unprocessed_recs NUMBER := 0;
  l_ret_code             NUMBER;
  l_return_status        VARCHAR2 (100);
  l_err_buff             VARCHAR2 (4000);
  l_sup_eligible_cnt     NUMBER := 0;
  l_sup_val_load_cnt     NUMBER := 0;
  l_sup_error_cnt        NUMBER := 0;
  l_sup_val_not_load_cnt NUMBER := 0;
  l_sup_ready_process    NUMBER := 0;
  l_user_id              NUMBER := fnd_global.user_id;
  l_resp_id              NUMBER := fnd_global.resp_id;
  l_resp_appl_id         NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id          NUMBER;
  l_phas_out             VARCHAR2 (60);
  l_status_out           VARCHAR2 (60);
  l_dev_phase_out        VARCHAR2 (60);
  l_dev_status_out       VARCHAR2 (60);
  l_message_out          VARCHAR2 (200);
  l_bflag                BOOLEAN;
  --==============================================================================
  -- Cursor Declarations for Suppliers
  --==============================================================================
  CURSOR c_supplier
  IS
    SELECT xas.*
    FROM XX_AP_CLD_SUPPLIERS_STG xas
    WHERE xas.supp_process_flag = gn_process_status_validated
    AND xas.REQUEST_ID          = gn_request_id
    AND xas.CREATE_FLAG         = 'Y';-----Added by priyam for Supplier Update
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Staging
  --==============================================================================
  CURSOR c_sup_stats
  IS
    SELECT SUM(DECODE(supp_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(supp_process_flag,5,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(supp_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(supp_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(supp_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPPLIERS_STG
    WHERE REQUEST_ID = gn_request_id
    AND CREATE_FLAG  = 'Y';
  l_sup_rec_exists NUMBER (10) DEFAULT 0;
  --- l_sup_site_rec_exists      NUMBER (10) DEFAULT 0;
  l_process_status_flag VARCHAR2(1);
  l_vendor_id           NUMBER;
  l_party_id            NUMBER;
BEGIN
  print_debug_msg(p_message=> gc_step||' load_Supplier_Interface() - BEGIN' ,p_force=> false);
  --==============================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==============================================================================
  l_process_status_flag := 'N';
  l_sup_rec_exists      := 0;
  l_error_message       := NULL;
  lp_loopcnt            := 0;
  lp_loopcont           := 0;
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
        --==============================================================================
        -- Initialize the Variable to N for Each Supplier
        --==============================================================================
        l_process_status_flag := 'N';
        l_error_message       := NULL;
        gc_step               := 'SUPINTF';
        l_sup_rec_exists      := 0;
        l_vendor_id           := NULL;
        l_party_id            := NULL;
        print_debug_msg(p_message=> gc_step||' Create Flag of the supplier '||l_supplier_type (l_idx).supplier_name||' is - '||l_supplier_type (l_idx).CREATE_FLAG ,p_force=> false);
        IF l_supplier_type (l_idx).CREATE_FLAG = 'Y' THEN
          --==============================================================================================
          -- Calling the Vendor Interface Id for Passing it to Interface Table - Supplier Does Not Exists
          --==============================================================================================
          SELECT ap_suppliers_int_s.nextval
          INTO l_vendor_intf_id
          FROM dual;
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
                  organization_type_lookup_code
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
                  l_supplier_type (l_idx).num_1099 ,
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
                  sysdate ,
                  g_user_id ,
                  sysdate ,
                  sysdate ,
                  g_user_id,
                  l_supplier_type (l_idx).organization_type
                );
              set_step ( 'Supplier Interface Inserted' || l_process_status_flag);
              print_debug_msg(p_message=> gc_step||' - After successfully inserted the record for the supplier -'||l_supplier_type (l_idx).supplier_name ,p_force=> false);
            EXCEPTION
            WHEN OTHERS THEN
              -- gc_error_status_flag := 'Y';
              l_process_status_flag := 'Y';
              l_error_message       := SQLCODE || ' - '|| sqlerrm;
              print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_type (l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message ,p_force=> true);
              insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_type (l_idx).supplier_name ,p_error_code => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,2000) ,p_error_message => 'Error while Inserting Records in Inteface Table'|| SQLCODE || ' - '||l_error_message ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_supplier_type (l_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
            END;
            IF l_process_status_flag                     = 'N' THEN
              l_supplier_type (l_idx).supp_process_flag := gn_process_status_loaded;
              l_sup_processed_recs                      := l_sup_processed_recs + 1;
              set_step ('Sup Stg Status P');
            elsif l_process_status_flag                  = 'Y' THEN
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
    IF l_supplier_type.count > 0 THEN
      set_step ('Supplier Staging Count');
      BEGIN
        forall l_idxs IN l_supplier_type.first .. l_supplier_type.last
        UPDATE XX_AP_CLD_SUPPLIERS_STG
        SET supp_process_flag = l_supplier_type (l_idxs).supp_process_flag,
          LAST_UPDATED_BY     =g_user_id,
          LAST_UPDATE_DATE    =sysdate,
          PROCESS_FLAG        ='Y'
        WHERE supplier_name   = l_supplier_type (l_idxs).supplier_name
        AND segment1          =l_supplier_type (l_idxs).segment1
        AND REQUEST_ID        = gn_request_id;
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
  l_supplier_type.delete;
  x_ret_code             := l_ret_code;
  x_return_status        := l_return_status;
  x_err_buf              := l_err_buff;
  l_sup_eligible_cnt     := 0;
  l_sup_val_load_cnt     := 0;
  l_sup_error_cnt        := 0;
  l_sup_val_not_load_cnt := 0;
  l_sup_ready_process    := 0;
  OPEN c_sup_stats;
  FETCH c_sup_stats
  INTO l_sup_eligible_cnt,
    l_sup_val_load_cnt,
    l_sup_error_cnt,
    l_sup_val_not_load_cnt,
    l_sup_ready_process;
  CLOSE c_sup_stats;
  x_processed_records   := l_sup_val_load_cnt ;---+ l_supsite_val_load_cnt;
  x_unprocessed_records := l_sup_error_cnt + l_sup_val_not_load_cnt ;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated and successfully Loaded are '|| l_sup_val_load_cnt, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated and Errored are '|| l_sup_error_cnt, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER - Records Validated Successfully but not loaded are '|| l_sup_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_out_msg(p_message => '--------------------------------------------------------------------------------------------');
  print_out_msg(p_message => 'After Load Vendors - Total Processed Records are '|| x_processed_records);
  print_out_msg(p_message => 'After Load Vendors - Total UnProcessed Records are '|| x_unprocessed_records);
  print_out_msg(p_message => '--------------------------------------------------------------------------------------------');
  COMMIT;
  print_out_msg(p_message => 'Before starting import program total Supplier eligible count '|| l_sup_val_load_cnt);
  IF l_sup_val_load_cnt >0 THEN
    print_out_msg(p_message => '-------------------Starting Supplier Import Program-------------------------------------------------------------------------');
    fnd_global.apps_initialize ( user_id => l_user_id ,resp_id => l_resp_id ,resp_appl_id => l_resp_appl_id );
    L_REPT_REQ_ID := FND_REQUEST.SUBMIT_REQUEST (APPLICATION => 'SQLAP' ,PROGRAM => 'APXSUIMP' , description => '' , start_time => sysdate ,sub_request => false ,argument1 => 'NEW' ,argument2 => 1000 ,argument3 => 'N' ,argument4 => 'N' ,argument5 => 'N');
    COMMIT;
    IF l_rept_req_id != 0 THEN
      print_debug_msg(p_message => 'Standard Supplier  Import APXSUIMP  is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
      l_dev_phase_out := 'Start';
      --  WHILE upper (NVL (l_dev_phase_out, 'XX')) != 'COMPLETE'
      --  LOOP
      l_bflag := fnd_concurrent.wait_for_request (l_rept_req_id ,5 ,0 ,l_phas_out ,l_status_out ,l_dev_phase_out ,l_dev_status_out ,l_message_out );
      --   END LOOP;
      ------Check here for Tiebacking to ebs and stg
      BEGIN
        UPDATE XX_AP_CLD_SUPPLIERS_STG stg
        SET supp_process_flag = gn_process_status_imported,
          PROCESS_FLAG        ='Y'
          ------vendor id
        WHERE 1=1--REQUEST_ID  = gn_request_id
        AND EXISTS
          (SELECT 1
          FROM ap_suppliers_int aint
          WHERE aint.vendor_name = stg.supplier_name
          AND aint.segment1      =stg.segment1
          AND aint.status        ='PROCESSED'
          )
        AND REQUEST_ID = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
      -- ELSE
      -- l_error_message := 'Problem in calling Supplier Contact Open Interface Import';
      -- print_debug_msg(p_message => ' l_error_message :'||l_error_message, p_force => true);
      BEGIN
        UPDATE XX_AP_CLD_SUPPLIERS_STG stg
        SET supp_process_flag = gn_process_status_imp_fail,
          PROCESS_FLAG        ='Y',
          -- supp_process_flag='E',
          ERROR_FLAG='E',
          ERROR_MSG =ERROR_MSG
          ||',Import Error'
        WHERE REQUEST_ID = gn_request_id
        AND EXISTS
          (SELECT 1
          FROM ap_suppliers_int aint
          WHERE aint.vendor_name = stg.supplier_name
          AND AINT.SEGMENT1      =STG.SEGMENT1
          AND aint.status        = 'REJECTED'
          )
        AND REQUEST_ID = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
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
    x_processed_records OUT NUMBER ,
    x_unprocessed_records OUT NUMBER ,
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2 )
IS
  --=========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for processing
  --=========================================================================================
type l_sup_site_add_tab
IS
  TABLE OF XX_AP_CLD_SUPP_SITES_STG%rowtype INDEX BY binary_integer;
  --=================================================================
  -- Declaring Local variables
  --=================================================================
  l_sup_site_type l_sup_site_add_tab;
  l_supplier_rec ap_vendor_pub_pkg.r_vendor_rec_type;
  l_supplier_site_rec ap_vendor_pub_pkg.r_vendor_site_rec_type;
  l_vendor_intf_id           NUMBER DEFAULT 0;
  l_vendor_site_intf_id      NUMBER DEFAULT 0;
  l_error_message            VARCHAR2 (2000) DEFAULT NULL;
  l_procedure                VARCHAR2 (30)   := 'load_Supplier_Site_Interface';
  l_msg_data                 VARCHAR2 (2000) := NULL;
  l_msg_count                NUMBER          := 0;
  l_trans_count              NUMBER          := 0;
  l_exception_msg            VARCHAR2 (1000);
  l_sup_processed_recs       NUMBER := 0;
  l_sup_unprocessed_recs     NUMBER := 0;
  l_supsite_processed_recs   NUMBER := 0;
  l_supsite_unprocessed_recs NUMBER := 0;
  l_ret_code                 NUMBER;
  l_return_status            VARCHAR2 (100);
  l_err_buff                 VARCHAR2 (4000);
  l_sup_eligible_cnt         NUMBER := 0;
  l_sup_val_load_cnt         NUMBER := 0;
  l_sup_error_cnt            NUMBER := 0;
  l_sup_val_not_load_cnt     NUMBER := 0;
  l_sup_ready_process        NUMBER := 0;
  l_supsite_eligible_cnt     NUMBER := 0;
  l_supsite_val_load_cnt     NUMBER := 0;
  l_supsite_error_cnt        NUMBER := 0;
  l_supsite_val_not_load_cnt NUMBER := 0;
  l_supsite_ready_process    NUMBER := 0;
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
    FROM XX_AP_CLD_SUPP_SITES_STG xsup_site
    WHERE xsup_site.site_process_flag = gn_process_status_validated
    AND xsup_site.REQUEST_ID          = gn_request_id
    AND create_flag                   ='Y';
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Site Staging
  --==============================================================================
  CURSOR c_sup_site_stats
  IS
    SELECT SUM(DECODE(site_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(site_process_flag,5,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(site_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(site_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(site_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_SITES_STG
    WHERE REQUEST_ID = gn_request_id
    AND create_flag  ='Y';
  l_sup_rec_exists          NUMBER (10) DEFAULT 0;
  l_sup_site_rec_exists     NUMBER (10) DEFAULT 0;
  l_process_site_error_flag VARCHAR2(1) DEFAULT 'N';
  l_vendor_id               NUMBER;
  l_vendor_site_id          NUMBER;
  l_party_site_id           NUMBER;
  l_party_id                NUMBER;
  l_vendor_site_code        VARCHAR2(50);
  l_ship_to_location_id     NUMBER;
  l_bill_to_location_id     NUMBER;
  l_tolerance_id            NUMBER;
  l_tolerance_name ap_tolerance_templates.tolerance_name%type;
  l_terms_code ap_terms_vl.name%type;
  l_terms_id   NUMBER;
  v_acct_pay   NUMBER;
  v_prepay_cde NUMBER;
BEGIN
  print_debug_msg(p_message=> gc_step||' load_Supplier_Site_Interface() - BEGIN' ,p_force=> false);
  set_step ('Start of Process Records Using API');
  --==============================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==============================================================================
  l_process_site_error_flag := 'N';
  l_sup_site_rec_exists     := 0;
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
        l_process_site_error_flag := 'N';
        gc_step                   := 'SITEINTF';
        ---  lp_loopcnt                := lp_loopcnt + 1;
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
          print_debug_msg(p_message=> gc_step||' : l_vendor_site_intf_id - '||l_vendor_site_intf_id ,p_force=> true);
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
                terms_name ,
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
                --- ATTRIBUTE7 ,
                attribute8 ,
                attribute9 ,
                attribute10 ,
                attribute11 ,
                attribute12 ,
                --  ATTRIBUTE13 ,
                attribute14 ,
                attribute15,
                vendor_site_code_alt
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
                l_sup_site_type(l_idx).terms_name ,
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
                --  l_sup_site_type(l_idx).ATTRIBUTE7 ,
                l_sup_site_type(l_idx).attribute8 ,
                l_sup_site_type(l_idx).attribute9 ,
                l_sup_site_type(l_idx).attribute10 ,
                l_sup_site_type(l_idx).attribute11 ,
                l_sup_site_type(l_idx).attribute12 ,
                ---   l_sup_site_type(l_idx).ATTRIBUTE13 ,
                l_sup_site_type(l_idx).attribute14 ,
                L_SUP_SITE_TYPE(L_IDX).ATTRIBUTE15,
                l_sup_site_type(l_idx).vendor_site_code_alt
                -- ltrim(regexp_replace(l_sup_site_type(l_idx).vendor_site_code, '[^0-9]'),0)
              );
            set_step ( 'Supplier Site Interface Inserted' || l_process_site_error_flag );
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
            l_supsite_processed_recs := l_supsite_processed_recs + 1;
            set_step ('Sup Site Stg Status P');
          elsif l_process_site_error_flag              = 'Y' THEN
            l_sup_site_type (l_idx).site_process_flag := gn_process_status_error;
            l_sup_site_type (l_idx).ERROR_FLAG        := gc_process_error_flag;
            l_sup_site_type (l_idx).ERROR_MSG         := gc_error_msg;
            l_supsite_unprocessed_recs                := l_supsite_unprocessed_recs + 1;
            set_step ('Sup Site Stg Status E');
          END IF;
        END IF;---Error Flag=N
      END LOOP;
    END IF;
    --==============================================================================
    -- For Doing the Bulk Update
    --=============================================================================
    -- l_supplier_type.COUNT For Bulk Update of Supplier
    IF l_sup_site_type.count > 0 THEN
      set_step ('Supplier Site Staging Count :');
      BEGIN
        forall l_idxss IN l_sup_site_type.first .. l_sup_site_type.last
        UPDATE XX_AP_CLD_SUPP_SITES_STG
        SET site_process_flag = l_sup_site_type (l_idxss).site_process_flag,
          LAST_UPDATED_BY     =g_user_id,
          LAST_UPDATE_DATE    =sysdate,
          --PROCESS_FLAG        ='P',
          ERROR_MSG          =L_SUP_SITE_TYPE (L_IDXSS).ERROR_MSG,
          ERROR_FLAG         = L_SUP_SITE_TYPE (L_IDXSS).ERROR_FLAG
        WHERE 1              =1--supplier_name  = l_sup_site_type (l_idxss).supplier_name
        AND supplier_number  = l_sup_site_type (l_idxss).supplier_number
        AND vendor_site_code = l_sup_site_type (l_idxss).vendor_site_code
        AND org_id           =l_sup_site_type (l_idxss).org_id
        AND REQUEST_ID       = gn_request_id;
        --    END LOOP;
        --      COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        l_process_site_error_flag := 'Y';
        set_step ('Supplier Site error :');
        l_error_message := 'When Others Exception ' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3850 );
      END;
      COMMIT;
    END IF; -- l_sup_site_type(l_idx).COUNT For Bulk Update of Sites
    EXIT
  WHEN c_supplier_site%notfound;
  END LOOP; -- For Open c_supplier
  CLOSE c_supplier_site;
  l_sup_site_type.delete;
  x_return_status            := l_return_status;
  x_err_buf                  := l_err_buff;
  l_supsite_eligible_cnt     := 0;
  l_supsite_val_load_cnt     := 0;
  l_supsite_error_cnt        := 0;
  l_supsite_val_not_load_cnt := 0;
  l_supsite_ready_process    := 0;
  OPEN c_sup_site_stats;
  FETCH c_sup_site_stats
  INTO l_supsite_eligible_cnt,
    l_supsite_val_load_cnt,
    l_supsite_error_cnt,
    l_supsite_val_not_load_cnt,
    l_supsite_ready_process;
  CLOSE c_sup_site_stats;
  x_processed_records   := l_supsite_val_load_cnt;
  x_unprocessed_records := l_supsite_error_cnt + l_supsite_val_not_load_cnt;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated and successfully Loaded are '|| l_supsite_val_load_cnt, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated and Errored are '|| l_supsite_error_cnt, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER SITE - Records Validated Successfully but not loaded are '|| l_supsite_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - Total Processed Records are '|| x_processed_records, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - Total UnProcessed Records are '|| x_unprocessed_records, p_force => true);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_out_msg(p_message => '--------------------------------------------------------------------------------------------');
  COMMIT;
  IF l_supsite_val_load_cnt >0 THEN
    print_out_msg(p_message => '-------------------Starting Supplier Site Import Program-------------------------------------------------------------------------');
    fnd_global.apps_initialize ( user_id => l_user_id ,resp_id => l_resp_id ,resp_appl_id => l_resp_appl_id );
    l_rept_req_id := fnd_request.submit_request (application => 'SQLAP' ,program => 'APXSSIMP' ,description => '' , start_time => sysdate ,sub_request => false , argument1 => '',argument2 => 'NEW' ,argument3 => 1000 ,argument4 => 'N' ,argument5 => 'N',argument6 => 'N');
    --argument1 => 'NEW' ,argument2 => 1000 ,argument3 => 'N' ,argument4 => 'N' ,argument5 => 'N');
    COMMIT;
    IF l_rept_req_id != 0 THEN
      print_debug_msg(p_message => 'Standard Supplier  Import APXSSIMP  is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
      l_dev_phase_out := 'Start';
      --  WHILE upper (NVL (l_dev_phase_out, 'XX')) != 'COMPLETE'
      --  LOOP
      L_BFLAG := FND_CONCURRENT.WAIT_FOR_REQUEST (L_REPT_REQ_ID ,5 ,0 ,L_PHAS_OUT ,L_STATUS_OUT ,L_DEV_PHASE_OUT ,L_DEV_STATUS_OUT ,L_MESSAGE_OUT );
      -- END LOOP;
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
          WHERE AINT.VENDOR_SITE_CODE = STG.VENDOR_SITE_CODE
          AND AINT.VENDOR_ID          =STG.VENDOR_ID
          AND aint.org_id             =stg.org_id
          AND aint.status             ='PROCESSED'
          )
        AND REQUEST_ID = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
      ---  ELSE
      --   l_error_message := 'Problem in calling Supplier Site Contact Open Interface Import';
      --  print_debug_msg(p_message => ' l_error_message :'||l_error_message, p_force => true);
      BEGIN
        UPDATE XX_AP_CLD_SUPP_SITES_STG stg
        SET SITE_PROCESS_FLAG = gn_process_status_imp_fail,
          PROCESS_FLAG        ='Y',
          ERROR_FLAG          ='E',
          ERROR_MSG           =ERROR_MSG
          ||',Import Error'
        WHERE 1=1--REQUEST_ID = gn_request_id
        AND EXISTS
          (SELECT 1
          FROM ap_supplier_sites_int aint
          WHERE aint.vendor_site_code = stg.vendor_site_code
          AND AINT.VENDOR_ID          =STG.VENDOR_ID
          AND aint.org_id             =stg.org_id
          AND aint.status             = 'REJECTED'
          )
        AND REQUEST_ID = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
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
    x_processed_records OUT NUMBER ,
    x_unprocessed_records OUT NUMBER ,
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2 )
IS
  --=========================================================================================
  -- Variables Declaration used for getting the data into PL/SQL Table for processing
  --=========================================================================================
type l_sup_cont_tab
IS
  TABLE OF XX_AP_CLD_SUPP_CONTACT_STG%rowtype INDEX BY binary_integer;
  --=================================================================
  -- Declaring Local variables
  --=================================================================
  l_supplier_cont_type l_sup_cont_tab;
  l_error_message VARCHAR2 (2000) DEFAULT NULL;
  l_procedure     VARCHAR2 (30)   := 'load_Supplier_cont_Interface';
  l_msg_data      VARCHAR2 (2000) := NULL;
  l_msg_count     NUMBER          := 0;
  l_trans_count   NUMBER          := 0;
  lp_loopcont pls_integer         := 0;
  lp_loopcnt pls_integer          := 0;
  l_exception_msg        VARCHAR2 (1000);
  l_sup_processed_recs   NUMBER := 0;
  l_sup_unprocessed_recs NUMBER := 0;
  l_ret_code             NUMBER;
  l_return_status        VARCHAR2 (100);
  l_err_buff             VARCHAR2 (4000);
  l_sup_eligible_cnt     NUMBER := 0;
  l_sup_val_load_cnt     NUMBER := 0;
  l_sup_error_cnt        NUMBER := 0;
  l_sup_val_not_load_cnt NUMBER := 0;
  l_sup_ready_process    NUMBER := 0;
  l_user_id              NUMBER := fnd_global.user_id;
  l_resp_id              NUMBER := fnd_global.resp_id;
  l_resp_appl_id         NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id          NUMBER;
  l_phas_out             VARCHAR2 (60);
  l_status_out           VARCHAR2 (60);
  l_dev_phase_out        VARCHAR2 (60);
  l_dev_status_out       VARCHAR2 (60);
  l_message_out          VARCHAR2 (200);
  l_bflag                BOOLEAN;
  --==============================================================================
  -- Cursor Declarations for Suppliers
  --==============================================================================
  CURSOR c_supplier_contacts
  IS
    SELECT xas.*
    FROM XX_AP_CLD_SUPP_CONTACT_STG xas
    WHERE xas.contact_process_flag= gn_process_status_validated
    AND XAS.REQUEST_ID            = GN_REQUEST_ID
    AND CREATE_FLAG               ='Y'--Insert
    AND cont_target               ='EBS';
  --- AND xas.update_flag        <> 'Y';-----Added by priyam for Supplier Update
  --==============================================================================
  -- Cursor Declarations to get table statistics of Supplier Staging
  --==============================================================================
  CURSOR c_sup_stats
  IS
    SELECT SUM(DECODE(contact_process_flag,2,1,0)) -- Eligible to Validate and Load
      ,
      SUM(DECODE(contact_process_flag,5,1,0)) -- Successfully Validated and Loaded
      ,
      SUM(DECODE(contact_process_flag,3,1,0)) -- Validated and Errored out
      ,
      SUM(DECODE(contact_process_flag,4,1,0)) -- Successfully Validated but not loaded
      ,
      SUM(DECODE(contact_process_flag,1,1,0)) -- Ready for Process
    FROM XX_AP_CLD_SUPP_CONTACT_STG
    WHERE REQUEST_ID = gn_request_id
    AND CONT_TARGET  ='EBS'
    AND create_flag  ='Y';
  l_sup_rec_exists NUMBER (10) DEFAULT 0;
  --- l_sup_site_rec_exists      NUMBER (10) DEFAULT 0;
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
  lp_loopcnt                := 0;
  lp_loopcont               := 0;
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;
  OPEN c_supplier_contacts;
  LOOP
    FETCH c_supplier_contacts bulk collect INTO l_supplier_cont_type;
    IF l_supplier_cont_type.count > 0 THEN
      print_debug_msg(p_message=> gc_step||' l_supplier_cont_type records processing.' ,p_force=> false);
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
        PRINT_DEBUG_MSG(P_MESSAGE=> GC_STEP||' Create Flag of the supplier '||L_SUPPLIER_CONT_TYPE (L_IDX).SUPPLIER_NAME||' is - '||L_SUPPLIER_CONT_TYPE (L_IDX).CREATE_FLAG ,P_FORCE=> FALSE);
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
                  -- DEPARTMENT ,
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
                  ap_sup_site_contact_int_s.nextval ,
                  l_party_site_id,-- l_supplier_cont_type (l_idx).party_site_id ,
                  l_org_id,      --- l_supplier_cont_type (l_idx).org_id ,
                  'NEW' ,
                  upper( l_supplier_cont_type (l_idx).first_name) ,
                  upper( l_supplier_cont_type (l_idx).last_name) ,
                  l_supplier_cont_type (l_idx).contact_name_alt ,
                  --   l_supplier_cont_type (l_idx).cont_department ,
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
              set_step ( 'Supplier contact Interface Inserted' || l_cont_process_error_flag);
              print_debug_msg(p_message=> gc_step||' - After successfully inserted the record for the supplier -' ||l_supplier_cont_type (l_idx).supplier_name ,p_force=> false);
            EXCEPTION
            WHEN OTHERS THEN
              -- gc_error_status_flag := 'Y';
              l_cont_process_error_flag := 'Y';
              l_error_message           := SQLCODE || ' - '|| sqlerrm;
              print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_cont_type (l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message ,p_force=> true);
              insert_error (p_program_step => gc_step ,p_primary_key => l_supplier_cont_type (l_idx).supplier_name ,p_error_code => 'XXOD_SUPPLIER_INS_ERROR'|| SQLCODE || ' - '|| SUBSTR (sqlerrm,1,2000) ,p_error_message => 'Error while Inserting Records in Inteface Table'|| SQLCODE || ' - '||l_error_message ,p_stage_col1 => 'SUPPLIER_NAME' ,p_stage_val1 => l_supplier_cont_type (l_idx).supplier_name ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_table );
            END;
            IF l_cont_process_error_flag                        = 'N' THEN
              l_supplier_cont_type (l_idx).contact_process_flag:= gn_process_status_loaded;
              ---  l_supplier_cont_type (l_idx).supplier_name    := l_supplier_cont_type.supplier_name;
              l_sup_processed_recs := l_sup_processed_recs + 1;
              set_step ('Sup Stg Status P');
            elsif l_cont_process_error_flag                      = 'Y' THEN
              l_supplier_cont_type (l_idx).contact_process_flag := gn_process_status_error;
              l_supplier_cont_type (l_idx).ERROR_FLAG           := gc_process_error_flag;
              l_supplier_cont_type (l_idx).ERROR_MSG            := gc_error_msg;
              l_sup_unprocessed_recs                            := l_sup_unprocessed_recs + 1;
              set_step ('Sup Stg Status E');
            END IF;
          END IF; -- l_process_status_flag := 'N'
        END IF;   -- IF l_supplier_cont_type (l_idx).create_flag = 'Y'
      END LOOP;   -- l_supplier_cont_type.FIRST .. l_supplier_cont_type.LAST
    END IF;       -- l_supplier_cont_type.COUNT > 0
    --==============================================================================
    -- For Doing the Bulk Update
    --=============================================================================
    IF l_supplier_cont_type.count > 0 THEN
      set_step ('Supplier contact Staging Count');
      BEGIN
        forall l_idxs IN l_supplier_cont_type.first .. l_supplier_cont_type.last
        UPDATE XX_AP_CLD_SUPP_CONTACT_STG
        SET contact_process_flag = l_supplier_cont_type (l_idxs).contact_process_flag,
          LAST_UPDATED_BY        =g_user_id,
          LAST_UPDATE_DATE       =SYSDATE,
          ---   PROCESS_FLAG           ='Y',
          ERROR_MSG  = L_SUPPLIER_CONT_TYPE (L_IDXS).ERROR_MSG,
          ERROR_FLAG = L_SUPPLIER_CONT_TYPE (L_IDXS).ERROR_FLAG
        WHERE 1      =1--SUPPLIER_NAME        = L_SUPPLIER_CONT_TYPE (L_IDXS).SUPPLIER_NAME
          /* AND vendor_id            = L_SUPPLIER_CONT_TYPE (L_IDXS).vendor_id
          AND vendor_site_id       = L_SUPPLIER_CONT_TYPE (L_IDXS).vendor_site_id
          AND SUPPLIER_NUMBER      = L_SUPPLIER_CONT_TYPE (L_IDXS).SUPPLIER_NUMBER
          AND first_name           = L_SUPPLIER_CONT_TYPE (L_IDXS).first_name
          AND last_name            = L_SUPPLIER_CONT_TYPE (L_IDXS).last_name
          AND REQUEST_ID           = gn_request_id;*/
        AND vendor_site_code = L_SUPPLIER_CONT_TYPE (L_IDXS).vendor_site_code
        AND SUPPLIER_NUMBER  = L_SUPPLIER_CONT_TYPE (L_IDXS).SUPPLIER_NUMBER
        AND first_name       = L_SUPPLIER_CONT_TYPE (L_IDXS).first_name
        AND last_name        = L_SUPPLIER_CONT_TYPE (L_IDXS).last_name
        AND REQUEST_ID       = GN_REQUEST_ID;
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
  l_supplier_cont_type.delete;
  x_ret_code             := l_ret_code;
  x_return_status        := l_return_status;
  x_err_buf              := l_err_buff;
  l_sup_eligible_cnt     := 0;
  l_sup_val_load_cnt     := 0;
  l_sup_error_cnt        := 0;
  l_sup_val_not_load_cnt := 0;
  l_sup_ready_process    := 0;
  OPEN c_sup_stats;
  FETCH c_sup_stats
  INTO l_sup_eligible_cnt,
    l_sup_val_load_cnt,
    l_sup_error_cnt,
    l_sup_val_not_load_cnt,
    l_sup_ready_process;
  CLOSE c_sup_stats;
  x_processed_records   := l_sup_val_load_cnt ;---+ l_supsite_val_load_cnt;
  x_unprocessed_records := l_sup_error_cnt + l_sup_val_not_load_cnt ;
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER Contacts - Records Validated and successfully Loaded are '|| l_sup_val_load_cnt, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER  Contacts- Records Validated and Errored are '|| l_sup_error_cnt, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - SUPPLIER Contacts- Records Validated Successfully but not loaded are '|| l_sup_val_not_load_cnt, p_force => true);
  print_debug_msg(p_message => '----------------------', p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - Total Processed Records are '|| x_processed_records, p_force => true);
  print_debug_msg(p_message => 'After Load Vendors - Total UnProcessed Records are '|| x_unprocessed_records, p_force => true);
  print_debug_msg(p_message => '--------------------------------------------------------------------------------------------', p_force => true);
  print_out_msg(p_message => '--------------------------------------------------------------------------------------------');
  COMMIT;
  IF l_sup_val_load_cnt >0 THEN
    print_out_msg(p_message => '-------------------Starting Supplier Contact Import Program-------------------------------------------------------------------------');
    fnd_global.apps_initialize ( user_id => l_user_id ,resp_id => l_resp_id ,resp_appl_id => l_resp_appl_id );
    l_rept_req_id := fnd_request.submit_request (application => 'SQLAP' ,program => 'APXSCIMP' ,description => '' , start_time => sysdate ,sub_request => false ,argument1 => 'NEW' ,argument2 => 1000 ,argument3 => 'N' ,argument4 => 'N' ,argument5 => 'N');
    COMMIT;
    IF l_rept_req_id != 0 THEN
      print_debug_msg(p_message => 'Standard Supplier contact Import APXSCIMP  is submitted : l_rept_req_id :'||l_rept_req_id, p_force => true);
      l_dev_phase_out := 'Start';
      L_BFLAG         := FND_CONCURRENT.WAIT_FOR_REQUEST (L_REPT_REQ_ID ,5 ,0 ,L_PHAS_OUT ,L_STATUS_OUT ,L_DEV_PHASE_OUT ,L_DEV_STATUS_OUT ,L_MESSAGE_OUT );
      BEGIN
        UPDATE XX_AP_CLD_SUPP_CONTACT_STG stg
        SET contact_process_flag= gn_process_status_imported,
          PROCESS_FLAG          ='Y'
        WHERE REQUEST_ID        = gn_request_id
        AND EXISTS
          (SELECT 1
          FROM ap_sup_site_contact_int aint
          WHERE upper(aint.last_name) = upper(stg.last_name)
          AND UPPER(AINT.FIRST_NAME)  = UPPER(STG.FIRST_NAME)
          AND aint.vendor_id          =stg.vendor_id
          AND aint.vendor_site_id     =stg.vendor_site_id
          AND aint.status             ='PROCESSED'
          )
        AND stg.cont_target ='EBS'
        AND REQUEST_ID      = gn_request_id;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
      --   ELSE
      BEGIN
        l_error_message := 'Problem in calling Supplier Contact Open Interface Import';
        print_debug_msg(p_message => ' l_error_message :'||l_error_message, p_force => true);
        UPDATE XX_AP_CLD_SUPP_CONTACT_STG stg
        SET contact_process_flag= gn_process_status_imp_fail,
          PROCESS_FLAG          ='Y',
          ERROR_FLAG            ='E',
          ERROR_MSG             = ERROR_MSG
          ||',Import Error'
        WHERE REQUEST_ID    = gn_request_id
        AND stg.cont_target ='EBS'
        AND EXISTS
          (SELECT 1
          FROM ap_sup_site_contact_int aint
          WHERE upper(aint.last_name) = upper(stg.last_name)
          AND upper(aint.first_name)  = upper(stg.first_name)
          AND aint.vendor_id          =stg.vendor_id
          AND aint.vendor_site_id     =stg.vendor_site_id
          AND aint.status             = 'REJECTED'
          )
        AND REQUEST_ID = GN_REQUEST_ID;
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => ' Error in update after import', p_force => true);
      END ;
      ---  END IF;
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
END load_supplier_cont_interface;
--+============================================================================+
--| Name          : xx_ap_sup_insert_vend_cont                                        |
--| Description   : This procedure will records into Custom Table              |
--|                                                                            |
--| Parameters    : N/A                                                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE xx_ap_sup_insert_vend_cont(
    x_ret_code OUT NUMBER ,
    x_return_status OUT VARCHAR2 ,
    x_err_buf OUT VARCHAR2)
IS
  CURSOR c_cont_custom_ins_upd
  IS
    SELECT stg.*,
      vendor_site_code_alt
    FROM XX_AP_CLD_SUPP_CONTACT_STG stg,
      ap_supplier_sites_all assu
    WHERE STG.CONT_TARGET ='CUSTOM'
      --- AND STG.VENDOR_SITE_CODE    =ASSU.VENDOR_SITE_CODE
    AND STG.VENDOR_ID           =ASSU.VENDOR_ID
    AND stg.vendor_site_id      =assu.vendor_site_id
    AND stg.contact_process_flag= gn_process_status_validated
    AND stg.REQUEST_ID          = gn_request_id
    AND CREATE_FLAG            IN ('Y','N');
  l_module               VARCHAR2(10);
  l_addr_key             NUMBER;
  l_key_value_1          NUMBER;
  l_key_value_2          NUMBER;
  l_addr_type            NUMBER;
  l_primary_addr_ind     VARCHAR2(1);
  l_country_id           VARCHAR2(3);
  l_city                 VARCHAR2(50);
  l_state                VARCHAR2(50);
  l_od_email_ind_flg     VARCHAR2(1);
  l_od_ship_from_addr_id VARCHAR2(80);
  l_enable_flag          VARCHAR2(1);
  l_count                NUMBER;
  l_seq_count            NUMBER;
  l_max_seq              NUMBER;
  l_address_type_cnt     NUMBER;
  l_vend_cont_add_cnt    NUMBER;
BEGIN
  gc_step:='CONT_INS_UPD';
  FOR r_cont_custom IN c_cont_custom_ins_upd
  LOOP
    gc_error_status_flag       :='N';
    IF r_cont_custom.CREATE_FLAG='Y' THEN
      l_max_seq                :=0;
      SELECT NVL(MAX(seq_no),0)
      INTO l_max_seq
      FROM XX_AP_SUP_VENDOR_CONTACT
      WHERE 1                    =1-- ltrim(key_value_1,'0') =ltrim(r_cont_custom.vendor_site_code_alt,'0')
      AND LTRIM(KEY_VALUE_1,'0') = LTRIM(R_CONT_CUSTOM.VENDOR_SITE_CODE_ALT,'0')
      AND ADDR_TYPE_ID           =TO_NUMBER(R_CONT_CUSTOM.ADDRESS_TYPE);
      BEGIN
        INSERT
        INTO xx_ap_sup_vendor_contact
          (
            addr_key,
            module,
            key_value_1,
            key_value_2,
            seq_no,
            primary_addr_ind,
            add_1,
            add_2,
            add_3,
            city,
            state,
            country_id,
            post,
            contact_name,
            contact_phone,
            --- CONTACT_TELEX,
            contact_fax,
            contact_email,
            ---   oracle_vendor_site_id,
            --  OD_PHONE_NBR_EXT,
            od_phone_800_nbr,
            od_comment_1,
            od_comment_2,
            --    OD_COMMENT_3,
            --  OD_COMMENT_4,
            od_email_ind_flg,
            od_ship_from_addr_id,
            --ATTRIBUTE1,
            -- ATTRIBUTE2,
            -- ATTRIBUTE3,
            --  ATTRIBUTE4,
            --  ATTRIBUTE5,
            creation_date,
            created_by,
            last_update_date,
            last_updated_by,
            last_update_login,
            enable_flag,
            addr_type_id
          )
          VALUES
          (
            xx_ap_vendor_key_seq.nextval,
            'SUPP',                           --- r_cont_custom.module,
            r_cont_custom.vendor_site_code_alt,-- l_key_value_1,
            '',
            l_max_seq+1,
            'Y',
            r_cont_custom.add_1,
            r_cont_custom.add_2,
            r_cont_custom.add_3,
            r_cont_custom.city,
            r_cont_custom.state,
            r_cont_custom.country_id,
            R_CONT_CUSTOM.POST,
            -- r_cont_custom.contact_name_alt,
            UPPER(r_cont_custom.first_name
            ||' '
            ||r_cont_custom.last_name),
            r_cont_custom.phone,
            --   r_cont_custom.contact_telex,
            r_cont_custom.fax,
            r_cont_custom.email_address,
            -- r_cont_custom.vendor_site_id,
            ---  r_cont_custom.od_phone_nbr_ext,
            r_cont_custom.od_phone_800_nbr,
            r_cont_custom.od_comment_1,
            r_cont_custom.od_comment_2,
            --  r_cont_custom.od_comment_3,
            --  r_cont_custom.od_comment_4,
            r_cont_custom.od_email_ind_flg,
            r_cont_custom.od_ship_from_addr_id,
            -- r_cont_custom.attribute1,
            -- r_cont_custom.attribute2,
            --  r_cont_custom.attribute3,
            -- r_cont_custom.attribute4,
            --  r_cont_custom.attribute5,
            sysdate,
            g_user_id,
            sysdate,
            g_user_id,
            g_user_id,
            'Y',-- r_cont_custom.enable_flag,
            to_number(r_cont_custom.address_type)
          );
        COMMIT;
        print_debug_msg(p_message=> gc_step|| SUBSTR(' Record inserted Successfully for addr_key : ' ||xx_ap_vendor_key_seq.currval ||' and key_value_1: '||l_key_value_1||' and address_type: ' ||r_cont_custom.address_type,1,150),p_force=>true) ;
      EXCEPTION
      WHEN OTHERS THEN
        gc_error_status_flag:='Y';
        print_debug_msg(p_message=> gc_step|| SUBSTR('When Others while inserting the record for key_value_1: '||l_key_value_1 ||' .  Error code is : '||sqlerrm,1,150),p_force=>true);
      END;
    ELSE
      BEGIN
        UPDATE xx_ap_sup_vendor_contact
        SET add_1    = r_cont_custom.add_1,
          add_2      = r_cont_custom.add_2,
          add_3      =r_cont_custom.add_3,
          city       =r_cont_custom.city,
          state      = r_cont_custom.state,
          country_id = r_cont_custom.country_id,
          POST       =R_CONT_CUSTOM.POST,
          --- contact_name =r_cont_custom.contact_name_alt,
          contact_phone=r_cont_custom.phone,
          ---CONTACT_TELEX
          contact_fax     =r_cont_custom.fax,
          contact_email   =r_cont_custom.email_address,
          od_phone_800_nbr=r_cont_custom.od_phone_800_nbr,
          od_comment_1    =r_cont_custom.od_comment_1,
          od_comment_2    =r_cont_custom.od_comment_2,
          ---od_comment_3
          --OD_COMMENT_4
          od_email_ind_flg     =r_cont_custom.od_email_ind_flg,
          od_ship_from_addr_id =od_ship_from_addr_id,
          last_update_date     =sysdate,
          LAST_UPDATED_BY      =G_USER_ID
          -- SEQ_NO                   =L_MAX_SEQ+1
        WHERE addr_type_id         =to_number(r_cont_custom.address_type)
        AND LTRIM(KEY_VALUE_1,'0') = LTRIM(R_CONT_CUSTOM.VENDOR_SITE_CODE_ALT,'0')
        AND SEQ_NO                 = R_CONT_CUSTOM.seq_no;
        -----add vendor_site_code alt
        COMMIT;
      EXCEPTION
      WHEN OTHERS THEN
        gc_error_status_flag:='Y';
        print_debug_msg(p_message=> gc_step|| SUBSTR('When Others while updating  the record for key_value_1: '||r_cont_custom.vendor_site_code_alt ||' .  Error code is : '||sqlerrm,1,150),p_force=>true);
      END;
    END IF;---c_cont_custom_ins_upd.CREATE_FLAG='Y'
    IF gc_error_status_flag='N' THEN
      UPDATE XX_AP_CLD_SUPP_CONTACT_STG xas
      SET xas.contact_process_flag   =gn_process_status_imported,---6
        xas.PROCESS_FLAG             ='Y',
        xas.ERROR_MSG                = '',
        xas.CREATE_FLAG              = r_cont_custom.CREATE_FLAG
      WHERE 1                        =1--xas.contact_process_flag=gn_process_status_validated
      AND xas.REQUEST_ID             = gn_request_id
      AND xas.supplier_name          = r_cont_custom.supplier_name
      AND TRIM(XAS.VENDOR_SITE_CODE) =TRIM(R_CONT_CUSTOM.VENDOR_SITE_CODE)
      AND XAS.SUPPLIER_NUMBER        =R_CONT_CUSTOM.SUPPLIER_NUMBER
      AND TRIM(UPPER(XAS.FIRST_NAME))= TRIM(UPPER(R_CONT_CUSTOM.FIRST_NAME))
      AND trim(upper(xas.last_name)) = trim(upper(R_CONT_CUSTOM.last_name));
      COMMIT;
    ELSE
      UPDATE XX_AP_CLD_SUPP_CONTACT_STG xas
      SET XAS.CONTACT_PROCESS_FLAG=GN_PROCESS_STATUS_ERROR ,---6
        xas.PROCESS_FLAG          ='Y',
        ERROR_FLAG                ='E',
        xas.ERROR_MSG             =ERROR_MSG
        ||',Error in insert or update  '
      WHERE 1            =1--xas.contact_process_flag=gn_process_status_validated
      AND XAS.REQUEST_ID = GN_REQUEST_ID
        -- AND xas.supplier_name          = r_cont_custom.supplier_name
      AND trim(xas.vendor_site_code) =trim(r_cont_custom.vendor_site_code)
      AND xas.supplier_number        =r_cont_custom.supplier_number
      AND TRIM(UPPER(XAS.FIRST_NAME))= TRIM(UPPER(R_CONT_CUSTOM.FIRST_NAME))
      AND trim(upper(xas.last_name)) = trim(upper(R_CONT_CUSTOM.last_name));
      COMMIT;
    END IF;
  END LOOP;---gc_error_status_flag='N'
EXCEPTION
WHEN OTHERS THEN
  x_ret_code      := 1;
  x_return_status := 'E';
  x_err_buf       := 'In exception of procedure xx_ap_sup_insert_vend_cont' ||sqlerrm;
END xx_ap_sup_insert_vend_cont;
--
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
PROCEDURE main_prc_supplier(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER ,
    p_reset_flag  IN VARCHAR2 ,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure           VARCHAR2 (30) := 'main_prc_supplier';
  l_log_start_date      DATE;
  l_log_end_date        DATE;
  l_out_start_date      DATE;
  l_out_end_date        DATE;
  l_log_elapse          VARCHAR2 (100);
  l_out_elapse          VARCHAR2 (100);
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  l_val_records         NUMBER;
  l_inval_records       NUMBER;
  l_processed_records   NUMBER;
  l_unprocessed_records NUMBER;
  l_resp_id             NUMBER := fnd_global.resp_id;
  l_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id         NUMBER;
  l_phas_out            VARCHAR2 (60);
  l_status_out          VARCHAR2 (60);
  l_dev_phase_out       VARCHAR2 (60);
  l_dev_status_out      VARCHAR2 (60);
  l_message_out         VARCHAR2 (200);
  l_bflag               BOOLEAN;
  l_req_err_msg         VARCHAR2 (4000);
  lc_boolean            BOOLEAN;
BEGIN
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Start of package '|| g_package_name , p_force => true);
  print_debug_msg(p_message => 'Start Procedure   '||l_procedure , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- validate_supplier_records    --
  --===============================================================
  print_debug_msg(p_message => 'Invoking the procedure validate_records()' , p_force => true);
  validate_supplier_records( x_val_records => l_val_records ,x_inval_records => l_inval_records ,x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()' , p_force => true);
  print_debug_msg(p_message => 'l_val_records - '||l_val_records , p_force => true);
  print_debug_msg(p_message => 'l_inval_records - '||l_inval_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
  print_debug_msg(p_message => 'Invoking the procedure load update_suppliers()' , p_force => true);
  update_supplier( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_vendor()' , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_supplier_interface()' , p_force => true);
  load_supplier_interface( x_processed_records => l_processed_records , x_unprocessed_records => l_unprocessed_records , x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_vendors()' , p_force => true);
  print_debug_msg(p_message => 'l_processed_records - '|| l_processed_records , p_force => true);
  print_debug_msg(p_message => 'l_unprocessed_records - '|| l_unprocessed_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier;
--+============================================================================+
--| Name          : main_prc_supplier_site                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for Suppliers Site Interface                                 |
--| Parameters    :   p_reset_flag           IN       VARCHAR2                 |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main_prc_supplier_site(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER ,
    p_reset_flag  IN VARCHAR2 ,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure           VARCHAR2 (30) := 'main_prc_supplier_site';
  l_log_start_date      DATE;
  l_log_end_date        DATE;
  l_out_start_date      DATE;
  l_out_end_date        DATE;
  l_log_elapse          VARCHAR2 (100);
  l_out_elapse          VARCHAR2 (100);
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  l_val_records         NUMBER;
  l_inval_records       NUMBER;
  l_processed_records   NUMBER;
  l_unprocessed_records NUMBER;
  l_resp_id             NUMBER := fnd_global.resp_id;
  l_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id         NUMBER;
  l_phas_out            VARCHAR2 (60);
  l_status_out          VARCHAR2 (60);
  l_dev_phase_out       VARCHAR2 (60);
  l_dev_status_out      VARCHAR2 (60);
  l_message_out         VARCHAR2 (200);
  l_bflag               BOOLEAN;
  l_req_err_msg         VARCHAR2 (4000);
  lc_boolean            BOOLEAN;
BEGIN
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Start of package '|| g_package_name , p_force => true);
  print_debug_msg(p_message => 'Start Procedure   '||l_procedure , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- Validate the Supplier Site Records   --
  --===============================================================
  print_debug_msg(p_message => 'Invoking the procedure validate_supplier_SITE_records()' , p_force => true);
  -----------------------Start
  validate_supplier_site_records( x_val_records => l_val_records ,x_inval_records => l_inval_records ,x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  -----------------------END
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()' , p_force => true);
  print_debug_msg(p_message => 'l_val_records - '||l_val_records , p_force => true);
  print_debug_msg(p_message => 'l_inval_records - '||l_inval_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
  print_debug_msg(p_message => 'Invoking the procedure load update_suppliers_site()' , p_force => true);
  update_supplier_sites( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_supplier_site()' , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_supplier_site_interface()' , p_force => true);
  load_supplier_site_interface( x_processed_records => l_processed_records , x_unprocessed_records => l_unprocessed_records , x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_vendors()' , p_force => true);
  print_debug_msg(p_message => 'l_processed_records - '|| l_processed_records , p_force => true);
  print_debug_msg(p_message => 'l_unprocessed_records - '|| l_unprocessed_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_site() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier_site;
--+============================================================================+
--| Name          : main_prc_supplier_Contact                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for Suppliers Site Contact Interface                                 |
--| Parameters    :   p_reset_flag           IN       VARCHAR2                 |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main_prc_supplier_contact(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER ,
    p_reset_flag  IN VARCHAR2 ,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure           VARCHAR2 (30) := 'main_prc_supplier_Contact';
  l_log_start_date      DATE;
  l_log_end_date        DATE;
  l_out_start_date      DATE;
  l_out_end_date        DATE;
  l_log_elapse          VARCHAR2 (100);
  l_out_elapse          VARCHAR2 (100);
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  l_val_records         NUMBER;
  l_inval_records       NUMBER;
  l_processed_records   NUMBER;
  l_unprocessed_records NUMBER;
  l_resp_id             NUMBER := fnd_global.resp_id;
  l_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id         NUMBER;
  l_phas_out            VARCHAR2 (60);
  l_status_out          VARCHAR2 (60);
  l_dev_phase_out       VARCHAR2 (60);
  l_dev_status_out      VARCHAR2 (60);
  l_message_out         VARCHAR2 (200);
  l_bflag               BOOLEAN;
  l_req_err_msg         VARCHAR2 (4000);
  lc_boolean            BOOLEAN;
BEGIN
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Start of package '|| g_package_name , p_force => true);
  print_debug_msg(p_message => 'Start Procedure   '||l_procedure , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- Validate the Supplier Site Records   --
  --===============================================================
  print_debug_msg(p_message => 'Invoking the procedure validate_Supp_contact_records()' , p_force => true);
  -----------------------Start
  validate_supp_contact_records( x_val_records => l_val_records ,x_inval_records => l_inval_records ,x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  -----------------------END
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()' , p_force => true);
  print_debug_msg(p_message => 'l_val_records - '||l_val_records , p_force => true);
  print_debug_msg(p_message => 'l_inval_records - '||l_inval_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
  --===========================================================================
  -- Udpate the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load update_suppliers_contact()' , p_force => true);
  update_supplier_contact( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_supplier_site()' , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_Supplier_cont_interface()' , p_force => true);
  load_supplier_cont_interface( x_processed_records => l_processed_records , x_unprocessed_records => l_unprocessed_records , x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_Supplier_cont_interface()' , p_force => true);
  print_debug_msg(p_message => 'l_processed_records - '|| l_processed_records , p_force => true);
  print_debug_msg(p_message => 'l_unprocessed_records - '|| l_unprocessed_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  X_ERRBUF  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_Contact() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END main_prc_supplier_contact;
--+============================================================================+
--| Name          : main_prc_supplier_cont_cust                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for Suppliers Site Contact Custom Interface                                 |
--| Parameters    :   p_reset_flag           IN       VARCHAR2                 |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main_prc_supplier_cont_cust(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER ,
    p_reset_flag  IN VARCHAR2 ,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure           VARCHAR2 (30) := 'main_prc_supplier_Cont_cust';
  l_log_start_date      DATE;
  l_log_end_date        DATE;
  l_out_start_date      DATE;
  l_out_end_date        DATE;
  l_log_elapse          VARCHAR2 (100);
  l_out_elapse          VARCHAR2 (100);
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  l_val_records         NUMBER;
  l_inval_records       NUMBER;
  l_processed_records   NUMBER;
  l_unprocessed_records NUMBER;
  l_resp_id             NUMBER := fnd_global.resp_id;
  l_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id         NUMBER;
  l_phas_out            VARCHAR2 (60);
  l_status_out          VARCHAR2 (60);
  l_dev_phase_out       VARCHAR2 (60);
  l_dev_status_out      VARCHAR2 (60);
  l_message_out         VARCHAR2 (200);
  l_bflag               BOOLEAN;
  l_req_err_msg         VARCHAR2 (4000);
  lc_boolean            BOOLEAN;
BEGIN
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Start of package '|| g_package_name , p_force => true);
  print_debug_msg(p_message => 'Start Procedure   '||l_procedure , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- Validate the Supplier Site Records   --
  --===============================================================
  print_debug_msg(p_message => 'Invoking the procedure val_Supp_contact_records_cust()' , p_force => true);
  -----------------------Start
  val_supp_contact_records_cust( x_val_records => l_val_records ,x_inval_records => l_inval_records ,x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  -----------------------END
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()' , p_force => true);
  print_debug_msg(p_message => 'l_val_records - '||l_val_records , p_force => true);
  print_debug_msg(p_message => 'l_inval_records - '||l_inval_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
  --===========================================================================
  -- Udpate the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load xx_ap_sup_insert_vend_cont()' , p_force => true);
  xx_ap_sup_insert_vend_cont( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_supplier_site()' , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_Contact_custom() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier_cont_cust;
--+============================================================================+
--| Name          : main_prc_supplier_bank                                                       |
--| Description   : main procedure will be called from the concurrent program  |
--|                 for main_prc_supplier_bank                                 |
--| Parameters    :   p_reset_flag           IN       VARCHAR2                 |
--| Parameters    :   p_debug_level          IN       VARCHAR2                 |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main_prc_supplier_bank(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER ,
    p_reset_flag  IN VARCHAR2 ,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure           VARCHAR2 (30) := 'main_prc_supplier_bank';
  l_log_start_date      DATE;
  l_log_end_date        DATE;
  l_out_start_date      DATE;
  l_out_end_date        DATE;
  l_log_elapse          VARCHAR2 (100);
  l_out_elapse          VARCHAR2 (100);
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  l_val_records         NUMBER;
  l_inval_records       NUMBER;
  l_processed_records   NUMBER;
  l_unprocessed_records NUMBER;
  l_resp_id             NUMBER := fnd_global.resp_id;
  l_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id         NUMBER;
  l_phas_out            VARCHAR2 (60);
  l_status_out          VARCHAR2 (60);
  l_dev_phase_out       VARCHAR2 (60);
  l_dev_status_out      VARCHAR2 (60);
  l_message_out         VARCHAR2 (200);
  l_bflag               BOOLEAN;
  l_req_err_msg         VARCHAR2 (4000);
  lc_boolean            BOOLEAN;
BEGIN
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Input Parameters' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Start of package '|| g_package_name , p_force => true);
  print_debug_msg(p_message => 'Start Procedure   '||l_procedure , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  -- validate_supplier_records    --
  --===============================================================
  print_debug_msg(p_message => 'Invoking the procedure validate_records()' , p_force => true);
  validate_suppsite_bank_records( x_val_records => l_val_records ,x_inval_records => l_inval_records ,x_ret_code => l_ret_code ,x_return_status => l_return_status ,x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure validate_records()' , p_force => true);
  print_debug_msg(p_message => 'l_val_records - '||l_val_records , p_force => true);
  print_debug_msg(p_message => 'l_inval_records - '||l_inval_records , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  IF (l_ret_code IS NULL OR l_ret_code <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
  PRINT_DEBUG_MSG(P_MESSAGE => 'Invoking the procedure attach_bank_assignments()' , P_FORCE => TRUE);
  attach_bank_assignments( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_vendor()' , p_force => true);
  print_debug_msg(p_message => 'l_ret_code - '||l_ret_code , p_force => true);
  print_debug_msg(p_message => 'l_return_status - '||l_return_status , p_force => true);
  print_debug_msg(p_message => 'l_err_buff - '||l_err_buff , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_bank() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END MAIN_PRC_SUPPLIER_BANK;
----------------------Update SITE for RMS
PROCEDURE Update_supplier_telex(
    ---- X_RETURN_STATUS OUT VARCHAR2 ,
    X_ERRBUF OUT VARCHAR2 ,
    X_RETCODE OUT NUMBER )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  L_PROCEDURE    VARCHAR2 (30)  := 'Update_supplier_telex';
  l_program_step VARCHAR2 (100) := '';
  CURSOR c_sup
  IS
      
      select site.vendor_site_id 
      FROM ---XX_AP_CLD_SUPP_BCLS_STG BCLS,
        XX_AP_CLD_SITE_DFF_STG DFF,
        XX_AP_CLD_SUPP_CONTACT_STG CONT,
        XX_AP_CLD_SUPP_SITES_STG SITE,
        XX_AP_CLD_SUPPLIERS_STG STG
      WHERE 1=1---APSUP.SEGMENT1         =STG.SEGMENT1
     --- AND ASSA.VENDOR_SITE_CODE    =SITE.VENDOR_SITE_CODE
     --- AND assa.org_id              =site.org_id
      AND STG.REQUEST_ID           =GN_REQUEST_ID
      AND SITE.REQUEST_ID          =GN_REQUEST_ID
      AND CONT.REQUEST_ID          =GN_REQUEST_ID
      and dff.request_id           =gn_request_id
     -- AND bcls.request_id          =GN_REQUEST_ID
      AND SITE.SUPPLIER_NUMBER     =STG.SEGMENT1
      AND CONT.SUPPLIER_NUMBER     =SITE.SUPPLIER_NUMBER
      AND CONT.VENDOR_SITE_CODE    =SITE.VENDOR_SITE_CODE
      AND DFF.VENDOR_SITE_CODE     =SITE.VENDOR_SITE_CODE
      AND DFF.SUPPLIER_NUMBER      =STG.SEGMENT1
      and dff.vendor_site_code     =site.vendor_site_code
      --AND bcls.supplier_number     =site.supplier_number
      AND STG.SUPP_PROCESS_FLAG    ='7'
      AND SITE.SITE_PROCESS_FLAG   ='7'
      and cont.contact_process_flag='7'
      and dff.dff_process_flag     ='7';
      --AND BCLS.BCLS_PROCESS_FLAG   ='7';
      
BEGIN
  --================================================================
  --Adding parameters to the log file
  --================================================================
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  l_program_step := 'START';
  print_debug_msg(p_message=> l_program_step||': Assigning Defaults' ,p_force=>true);
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
  X_ERRBUF  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.Update_supplier_telex() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END Update_supplier_telex;
PROCEDURE XX_AP_SUPP_CLD_INTF(
    x_errbuf OUT nocopy  VARCHAR2 ,
    x_retcode OUT nocopy NUMBER ,
    ---  p_reset_flag  IN VARCHAR2 ,
    p_debug_level IN VARCHAR2 )
IS
  --================================================================
  --Declaring local variables
  --================================================================
  l_procedure           VARCHAR2 (30) := 'main_prc_supplier_test';
  l_log_start_date      DATE;
  l_log_end_date        DATE;
  l_out_start_date      DATE;
  l_out_end_date        DATE;
  l_log_elapse          VARCHAR2 (100);
  l_out_elapse          VARCHAR2 (100);
  l_ret_code            NUMBER;
  l_return_status       VARCHAR2 (100);
  l_err_buff            VARCHAR2 (4000);
  l_val_records         NUMBER;
  l_inval_records       NUMBER;
  l_processed_records   NUMBER;
  l_unprocessed_records NUMBER;
  l_resp_id             NUMBER := fnd_global.resp_id;
  l_resp_appl_id        NUMBER := fnd_global.resp_appl_id;
  l_rept_req_id         NUMBER;
  l_phas_out            VARCHAR2 (60);
  l_status_out          VARCHAR2 (60);
  l_dev_phase_out       VARCHAR2 (60);
  l_dev_status_out      VARCHAR2 (60);
  l_message_out         VARCHAR2 (200);
  l_bflag               BOOLEAN;
  l_req_err_msg         VARCHAR2 (4000);
  lc_boolean            BOOLEAN;
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
  -- print_debug_msg(p_message => 'Reset Flag :                  '|| p_reset_flag , p_force => true);
  print_debug_msg(p_message => 'Debug Flag :                  '|| p_debug_level , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Start of package '|| g_package_name , p_force => true);
  print_debug_msg(p_message => 'Start Procedure   '||l_procedure , p_force => true);
  print_debug_msg(p_message => '  ' , p_force => true);
  print_debug_msg(p_message => 'Initializing Global Variables ' , p_force => true);
  l_ret_code      := 0;
  l_return_status := 'S';
  l_err_buff      := NULL;
  --===============================================================
  --Updating Request Id into Supplier Staging table     --
  --===============================================================
  UPDATE XX_AP_CLD_SUPPLIERS_STG
  SET supp_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID            = gn_request_id ,
    PROCESS_FLAG          = 'P'
  WHERE SUPP_PROCESS_FLAG = '1'
  AND PROCESS_FLAG        ='N' ;--
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPPLIERS_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPPLIERS_STG are '||sql%rowcount , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are '||sql%rowcount);
  END IF;
  --===============================================================
  --Updating Request Id into Supplier Site Staging table     --
  --===============================================================
  UPDATE XX_AP_CLD_SUPP_SITES_STG xasc
  SET site_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID            = gn_request_id ,
    PROCESS_FLAG          = 'P'
  WHERE SITE_PROCESS_FLAG ='1'
  AND PROCESS_FLAG        ='N';
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_SITES_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_SITES_STG are '||sql%rowcount , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are '||sql%rowcount);
  END IF;
  UPDATE XX_AP_CLD_SUPP_CONTACT_STG
  SET contact_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID               = gn_request_id ,
    PROCESS_FLAG             = 'P'
  WHERE contact_process_flag ='1'
  AND PROCESS_FLAG           ='N'
  AND cont_target            ='EBS';
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_CONTACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_CONTACT_STG are '||sql%rowcount , p_force => true);
    PRINT_OUT_MSG(P_MESSAGE => 'Total No. of Supplier Site records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  UPDATE XX_AP_CLD_SUPP_CONTACT_STG
  SET contact_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID               = gn_request_id ,
    PROCESS_FLAG             = 'P'
  WHERE contact_process_flag ='1'
  AND PROCESS_FLAG           ='N'
  AND cont_target            ='CUSTOM';
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_CONTACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_CONTACT_STG are '||sql%rowcount , p_force => true);
    PRINT_OUT_MSG(P_MESSAGE => 'Total No. of Supplier Site records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  UPDATE XX_AP_CLD_SUPP_BNKACT_STG
  SET bnkact_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID              = gn_request_id ,
    process_Flag            = 'P'
  WHERE bnkact_process_flag = '1'
  AND process_Flag          ='N';
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPP_BNKACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BNKACT_STG are '||sql%rowcount , p_force => true);
    PRINT_OUT_MSG(P_MESSAGE => 'Total No. of Supplier records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  UPDATE xx_ap_cld_site_dff_stg
  SET DFF_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID           = gn_request_id ,
    process_Flag         = 'P'
  WHERE DFF_process_flag = '1'
  AND process_Flag       ='N';
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPP_BNKACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BNKACT_STG are '||sql%rowcount , p_force => true);
    PRINT_OUT_MSG(P_MESSAGE => 'Total No. of Supplier records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  UPDATE xx_ap_cld_supp_bcls_stg
  SET bcls_process_flag   = gn_process_status_inprocess ,
    REQUEST_ID            = gn_request_id ,
    process_Flag          = 'P'
  WHERE bcls_process_flag = '1'
  AND process_Flag        ='N';
  IF sql%notfound THEN
    print_debug_msg(p_message => 'No records exist to process in the table xx_ap_cld_supp_bcls_stg.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
  elsif sql%found THEN
    print_debug_msg(p_message => 'Records to be processed from the table xx_ap_cld_supp_bcls_stg are '||sql%rowcount , p_force => true);
    PRINT_OUT_MSG(P_MESSAGE => 'Total No. of Supplier records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling Supplier Wrapper' , p_force => true);
  main_prc_supplier( X_ERRBUF =>l_err_buff , X_RETCODE=> l_ret_code , P_RESET_FLAG =>'N' , p_debug_level =>'Y' );
  PRINT_DEBUG_MSG(P_MESSAGE => 'Exiting Supplier Wrapper' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling Business Classification' , p_force => true);
  process_bus_class(gn_request_id);
  PRINT_DEBUG_MSG(P_MESSAGE => 'Exiting Business Classification' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling Supplier Site Wrapper' , p_force => true);
  main_prc_supplier_site( X_ERRBUF =>l_err_buff , X_RETCODE=> l_ret_code , P_RESET_FLAG =>'N' , p_debug_level =>'Y' );
  print_debug_msg(p_message => 'Exiting  Supplier Site Wrapper' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling  Supplier Contact Wrapper' , p_force => true);
  MAIN_PRC_SUPPLIER_CONTACT( X_ERRBUF =>L_ERR_BUFF , X_RETCODE=> L_RET_CODE , P_RESET_FLAG =>'N' , P_DEBUG_LEVEL =>'Y' );
  PRINT_DEBUG_MSG(P_MESSAGE => 'Exiting  Supplier Contact Wrapper' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling Supplier Contact Custom   Wrapper' , p_force => true);
  main_prc_supplier_cont_cust( X_ERRBUF =>l_err_buff , X_RETCODE=> l_ret_code , P_RESET_FLAG =>'N' , p_debug_level =>'Y' );
  PRINT_DEBUG_MSG(P_MESSAGE => 'Exiting Supplier Contact Custom  Wrapper' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling  Supplier Bank Wrapper' , p_force => true);
  main_prc_supplier_bank( X_ERRBUF =>l_err_buff , X_RETCODE=> l_ret_code , P_RESET_FLAG =>'N' , p_debug_level =>'Y' );
  print_debug_msg(p_message => 'Exiting Supplier Bank  Wrapper' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling Custom DFF Process' , p_force => true);
  xx_supp_dff(gn_request_id);
  PRINT_DEBUG_MSG(P_MESSAGE => 'Exiting Custom DFF Process' , P_FORCE => TRUE);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);
  print_debug_msg(p_message => 'Calling  Update_supplier_telex' , p_force => true);
  UPDATE_SUPPLIER_TELEX( X_ERRBUF =>L_ERR_BUFF , X_RETCODE=> L_RET_CODE);
  print_debug_msg(p_message => 'Exiting Update_supplier_telex' , p_force => true);
  IF (L_RET_CODE IS NULL OR L_RET_CODE <> 0) THEN
    x_retcode    := l_ret_code;
    x_errbuf     := l_err_buff;
    RETURN;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  x_retcode := 2;
  X_ERRBUF  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_test() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END XX_AP_SUPP_CLD_INTF;
END XX_AP_SUPP_CLD_INTF_PKG;

/
SHOW ERROR;