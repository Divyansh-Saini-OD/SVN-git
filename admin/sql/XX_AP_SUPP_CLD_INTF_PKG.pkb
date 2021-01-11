create or replace PACKAGE BODY XX_AP_SUPP_CLD_INTF_PKG
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
-- |  2.2    09-AUG-2019     Havish Kasina     Added columns address_line3 and address line4 in|
-- |                                           load_supplier_sites and update_supplier_sites   |
-- |                                           Added rfq_only_site_flag in the load supp sites |
-- |                                           Added settle days in the Custom Tolerance       |
-- |                                           Added a new condition to exclude RTV sites to   |
-- |                                           create custom tolerance                         |
-- |  2.3    09-AUG-2019     Havish Kasina     Added supplier_notif_method                     |
-- |  2.4    12-AUG-2019     Havish Kasina     Added gl info in update_supplier_site           |
-- |  2.5    12-AUG-2019     Havish Kasina     Update_status procedure is added                |
-- |  2.6    14-AUG-2019     Havish Kasina     a.Added BANK_CHARGE_BEARER in the load_supp_site|
-- |                                           b.Terms_id added in both update_supp_sites and  |
-- |                                             load_supp_sites                               |
-- |  2.7    16-AUG-2019     Havish Kasina     Added Debug Messages                            |
-- |  2.8    19-AUG-2019     Havish Kasina     Modified Custom Tolerance procedure             |
-- |  2.9    12-SEP-2019     Havish Kasina     a. Added Tolerance and FOB mapping              |
-- |                                           b. Added logic to handle Immediate pay term     |
-- |                                           c. Added end_date_active in the insert script   |
-- |                                              for table ap_suppliers_int                   |
-- |                                           d. Added inactive_date in the insert script for |
-- |                                              table ap_supplier_sites_int                  |
-- |  3.0    19-SEP-2019     Havish Kasina     a. Added hold_reason field in ap_suppliers_int  |
-- |                                              table                                        |
-- |                                           b. Added hz_party_site_v2pub.update_party_site  |
-- |                                              api to inactivate the party site when suppli-|
-- |                                              er site gets inactive                        |
-- |  3.1    23-SEP-2019     Havish Kasina     a. Added a new procedure to create and update   |
-- |                                              the address contact for the Sites            |
-- |  3.2    05-OCT-2019     Paddy Sanjeevi    Modified to use api to create the  Supplier     |
-- |                                           Contact and Update the Supplier Contact         |
-- |  3.3    08-OCT-2019     Havish Kasina     Added a new column in the Supplier Site custom  |
-- |                                           table to populate the email address in the site |
-- |                                           level communication                             |
-- |  3.4    09-OCT-2019     Havish Kasina     If the site exists then:                        |
-- |                                            a. If the site status is Active, Do not update |
-- |                                               the Legacy supplier number in EBS           |
-- |                                            b. If the site status is Inactive, then update |
-- |                                               the Legacy supplier number in EBS to what is|
-- |                                               coming from SCM (which will be blank)       |
-- |                                           If the site does not exist then:                |
-- |                                            a. Create the site in EBS without the Legacy   |
-- |                                               number ( This is because, in EBS today, new |
-- |                                               sites do not have Legacy Suppler number)    |
-- | 3.5     23-OCT-2019    Paddy Sanjeevi     Added xx_tolerance_trait procedure              |
-- | 3.6     26-OCT-2019    Paddy Sanjeevi     Added to update payment method at site level    |
-- | 3.7     23-Jan-2020    Shanti Sethuraj    Modified for jira NAIT-118785                   |
-- | 3.8     23-Jan-2020    Shanti Sethuraj    Modified for jira NAIT-118444	               |
-- | 3.9     06-Feb-2020    Shanti Sethuraj    Modified for jira NAIT-112927                   |
-- | 4.0     03-Mar-2020    Shanti Sethuraj    Modified for jira NAIT-118027                   |
-- | 4.1     07-Sep-2020    Shanti Sethuraj    Modified for jira NAIT-118338                   |
-- | 4.2     21-SEP-2020    Shanti Sethuraj    Added code for jira NAIT-126909                 |
-- | 4.3     05-Jan-2021    Komal Mishra       Modified for jira NAIT-154376                   |
-- | 4.4     05-Jan-2021	Gitanjali Singh	   Modified for jira NAIT-127517				   |
-- |										   a)Added column (Status, end_Date_active) details|
-- |										   b)Added AND condition to get details if Business|
-- |										   Classification is active or not				   |
-- | 										   c)handle condition if status is inactive then   |
-- |                                           updating EBS base table and else condition      |
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
-- | FUNCTION   : isNumeric                                            |
-- |                                                                   |
-- | DESCRIPTION: Checks if only Numeric in a string                   |
-- |                                                                   |
-- |                                                                   |
-- | RETURNS    : Boolean (if numeric exists or not)                   |
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
--+==============================================================================+
--| Name          : get_cc_id                                                    |
--| Description   : This procedure will get code_combiantion_id from ebs to cld  |
--|                                                                              |
--| Parameters    :                                                              |
--|                                                                              |
--| Returns       : N/A                                                          |
--|                                                                              |
--+==============================================================================+
FUNCTION get_cc_id(p_segments VARCHAR2)
  RETURN NUMBER
IS
  v_target       VARCHAR2(100);
  v_ccid         NUMBER;
BEGIN
  BEGIN
    IF p_segments IS NOT NULL
	THEN
      v_target    :=NULL;

	  SELECT LTRIM(RTRIM(tv.target_value1))
        INTO v_target
        FROM xx_fin_translatevalues tv,
             xx_fin_translatedefinition td
       WHERE tv.translate_id  = td.translate_id
         AND translation_name = 'XX_GL_CLD2EBS_MAPPING'
	     AND SYSDATE BETWEEN NVL(tv.start_date_active,SYSDATE) AND NVL(tv.end_date_active,SYSDATE + 1)
         AND SYSDATE BETWEEN NVL(td.start_date_active,SYSDATE) AND NVL(td.end_date_active,SYSDATE + 1)
	     AND tv.source_value1 = p_segments
         AND tv.enabled_flag = 'Y'
         AND td.enabled_flag = 'Y';

      print_debug_msg(p_message=> 'New EBs Code Combination ID is '||v_target , p_force=>true);

      BEGIN
        SELECT code_combination_id
          INTO v_ccid
          FROM gl_code_combinations_kfv
         WHERE concatenated_segments=v_target
		   AND enabled_flag = 'Y';
      EXCEPTION
      WHEN OTHERS
	  THEN
        v_ccid :=NULL;
        print_debug_msg(p_message=> 'CCID does not exist in EBS for  '||v_target , p_force=>true);
      END ;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    v_ccid :=NULL;
  END;
  RETURN v_ccid;
END get_cc_id;

-- +===================================================================+
-- | FUNCTION   : xx_get_terms                                         |
-- |                                                                   |
-- | DESCRIPTION: To get the EBS payment terms for Cloud Payment terms |
-- |                                                                   |
-- +===================================================================+
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

/* Added as per Version 2.6 by Havish Kasina */
--+============================================================================+
--| Name          : get_terms_id                                               |
--| Description   : This procedure will get the terms id                       |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE get_terms_id(p_terms_name   IN  VARCHAR2,
                       o_terms_id     OUT NUMBER)
AS
BEGIN
    SELECT term_id
	  INTO o_terms_id
      FROM ap_terms_vl
     WHERE name       = p_terms_name
       AND enabled_flag = 'Y'
       AND TRUNC(SYSDATE) BETWEEN TRUNC(NVL(start_date_active, SYSDATE-1)) AND TRUNC(NVL(end_date_active, SYSDATE+1));
EXCEPTION
WHEN OTHERS
THEN
    o_terms_id := NULL;
END;
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
--| Description   : This Function will process Custom Supplier Tolerance       |
--|                                                                            |
--|                                                                            |
--| Parameters    : p_vendor_id,p_vendor_site_id                               |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
FUNCTION xx_custom_tolerance
  (
    p_vendor_id             IN NUMBER,
    p_vendor_site_id        IN NUMBER,
    p_org_id                IN NUMBER,
	p_insert_flag           IN VARCHAR2,
	p_favourable_price_pct  IN NUMBER,
	p_max_price_amt         IN NUMBER,
	p_min_chargeback_amt    IN NUMBER,
	p_max_freight_amt       IN NUMBER,
	p_dist_var_neg_amt      IN NUMBER,
	p_dist_var_pos_amt      IN NUMBER
  )
  RETURN VARCHAR2
IS
BEGIN
  IF p_insert_flag = 'Y'
  THEN
     INSERT INTO xx_ap_custom_tolerances
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
              NVL(p_favourable_price_pct,30),
              NVL(p_max_price_amt,50),
              NVL(p_min_chargeback_amt,2),
            --  NVL(p_max_freight_amt,0),  -- commented by Shanti for NAIT-118785
			  p_max_freight_amt,              -- Added by Shanti for NAIT-118785
              NVL(p_dist_var_neg_amt,1),
              NVL(p_dist_var_pos_amt,1),
              fnd_global.user_id,
              SYSDATE,
              fnd_global.user_id,
              SYSDATE
            );
  ELSE
      UPDATE xx_ap_custom_tolerances
	     SET favourable_price_pct = NVL(p_favourable_price_pct,30),
		     max_price_amt        = NVL(p_max_price_amt,50),
		     min_chargeback_amt   = NVL(p_min_chargeback_amt,2),
		   --  max_freight_amt      = NVL(p_max_freight_amt,0),    -- commented by Shanti for NAIT-118785
		     max_freight_amt      = p_max_freight_amt,     -- Added by Shanti for NAIT-118785
		     dist_var_neg_amt     = NVL(p_dist_var_neg_amt,1),
		     dist_var_pos_amt     = NVL(p_dist_var_pos_amt,1),
		     last_updated_by      = fnd_global.user_id,
		     last_update_date     = SYSDATE
	   WHERE supplier_id = p_vendor_id
	     AND supplier_site_id = p_vendor_site_id
		 AND org_id = p_org_id;

  END IF;
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
  ln_enable_flag    VARCHAR2(100); --added by Shanti for jira NAIT-126909
BEGIN
  WHILE lc_sup_trait IS NOT NULL
  LOOP
    lc_description    :=NULL;
    lc_enable_flag    :=NULL;
    lc_sup_trait_id   :=NULL;
	ln_enable_flag    :=NULL; --added by Shanti for jira NAIT-126909
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
	  	      --Below code added by Shanti for jira NAIT-126909
      IF ln_mat_count >0 THEN
        BEGIN
          SELECT enable_flag
          INTO ln_enable_flag
          FROM xx_ap_sup_traits_matrix
          WHERE supplier    = p_sup_number
          AND sup_trait_id  = ln_sup_trait_id;
          IF ln_enable_flag ='N' THEN
		  fnd_file.put_line(fnd_file.log,'Supplier trait matrix active in Cloud but in EBS'||' Supplier '||p_sup_number||' Sup_trait_id '||ln_sup_trait_id|| 'Status is '||ln_enable_flag);
		   UPDATE xx_ap_sup_traits_matrix
            SET enable_flag   ='Y',
              last_update_date=SYSDATE,
              last_updated_by =fnd_global.user_id
            WHERE sup_trait_id=ln_sup_trait_id
            AND supplier      =p_sup_number;
            COMMIT;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          print_debug_msg(p_message =>'When others, while retriving data for xx_ap_sup_traits_matrix:'||p_sup_number, p_force=>false);
        END;
      END IF;
      ---end of Shanti code for jira NAIT-126909

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
		 sup.vendor_id,
     nvl(bus.status,'A') status,			-- version 4.4
		 bus.END_DATE_ACTIVE	--  version 4.4 
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
  ln_cls_id	   NUMBER;
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
       AND lookup_code         = cur.classification
       and STATUS  = 'A';        ---- version 4.4 
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
      --- start version 4.4
      -- Fetch classfication_id of the current BCLS
      SELECT CLASSIFICATION_ID      		
        INTO ln_cls_id
        FROM pos_bus_class_attr
       WHERE 1                 = 1
         AND party_id            = cur.party_id
         AND vendor_id           = cur.vendor_id
         AND lookup_code         = cur.classification
         and STATUS  = 'A'; 
     IF cur.status = 'I' ---or cur.END_DATE_ACTIVE is not null
     THEN
     -- updating business classification table if the BCLS got inactive in cloud
		  UPDATE POS_BUS_CLASS_ATTR 
			   SET status = 'I', END_DATE_ACTIVE = SYSDATE, 
			       LAST_UPDATE_DATE = SYSDATE, LAST_UPDATED_BY = fnd_global.user_id 
		   WHERE CLASSIFICATION_ID = ln_cls_id 
			   AND party_id = cur.party_id
			 ;
		   --- updating staging table	as processed 
	    UPDATE xx_ap_cld_supp_bcls_stg
         SET bcls_process_Flag=7,
             error_flag         ='N',
             error_msg          =NULL, 
             vendor_id          =cur.vendor_id,
             process_flag       ='Y'
       WHERE rowid          = cur.drowid;
	     COMMIT;		 
     ELSE
     --- end version 4.4
      UPDATE xx_ap_cld_supp_bcls_stg
         SET bcls_process_Flag=7,
             error_flag         ='N',
             error_msg          =NULL,
             vendor_id          =cur.vendor_id,
             process_flag       ='Y'
       WHERE rowid          = cur.drowid;
       COMMIT;
    END IF;
   END IF; 
  END LOOP;
  print_debug_msg(p_message => 'End processing Business Classification ', p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message =>'When others in process bus class :'||SQLERRM, p_force => false);
END process_bus_class;

--+=============================================================================+
--| Name          : xx_process_supp_trait                                       |
--| Description   : This procedure will Create supplier traits                  |
--|                                                                             |
--| Parameters    : gn_request_id                                               |
--|                                                                             |
--| Returns       : N/A                                                         |
--|                                                                             |
--+=============================================================================+
PROCEDURE xx_tolerance_trait(gn_request_id IN NUMBER)
IS
  CURSOR C1
  IS
    SELECT dff.rowid drowid,
           dff.supplier_number ,
           dff.supplier_name ,
           dff.vendor_site_code,
           dff.sup_trait,
	       dff.favourable_price_pct ,
	       dff.max_price_amt ,
	       dff.min_chargeback_amt ,
	       dff.max_freight_amt  ,
	       dff.dist_var_neg_amt ,
	       dff.dist_var_pos_amt ,
           site.vendor_id ,
           site.vendor_site_id,
           site.org_id,
	       site.attribute8
      FROM xx_ap_cld_site_dff_stg dff,
           xx_ap_cld_supp_sites_stg site
     WHERE 1                     =1
       AND dff.request_id          = gn_request_id
       AND site.vendor_site_code=dff.vendor_site_code
	   AND site.supplier_number=dff.supplier_number
       AND site.site_process_flag IN (7,8)
       AND site.request_id         = dff.request_id
       AND site.vendor_id         IS NOT NULL
       AND site.vendor_site_id    IS NOT NULL
       AND EXISTS (SELECT 1
				     FROM ap_supplier_sites_all
				    WHERE vendor_id      = site.vendor_id
				      AND vendor_site_id = site.vendor_site_id
				  );

  v_trait_flag            VARCHAR2(1);
  lc_error_msg            VARCHAR2(2000);
  lc_vendor_site_code_alt VARCHAR2(100);
  ln_tol_count			  NUMBER;
  v_tol_flag              VARCHAR2(1);
BEGIN
  print_debug_msg(p_message => 'Begin Supplier Trait and Custom Tolerance Processing ', p_force => true);
  FOR cur IN C1
  LOOP
    lc_vendor_site_code_alt:=NULL;
    BEGIN
      SELECT vendor_site_code_alt
        INTO lc_vendor_site_code_alt
        FROM ap_supplier_sites_all
       WHERE vendor_site_id = cur.vendor_site_id;
    EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message => 'Error in Deriving Kff Values for site : '||cur.vendor_site_code||','|| SQLERRM ,p_force =>false);
    END;
	IF lc_vendor_site_code_alt IS NOT NULL THEN
       IF cur.sup_trait IS NOT NULL THEN
          v_trait_flag   := xx_custom_sup_traits(cur.sup_trait,NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id ) );
       END IF;

	   	   	   --shanti code starts for jira NAIT-126909
	   begin
    UPDATE xx_ap_sup_traits_matrix
    SET enable_flag   ='N',
      last_update_date=SYSDATE,
      last_updated_by =fnd_global.user_id
    WHERE supplier    = NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id )
    AND sup_trait_id IN
      (SELECT DISTINCT xxstp.sup_trait_id
      FROM xx_ap_sup_traits xxstp ,
        xx_ap_sup_traits_matrix xxaptm
      WHERE xxstp.sup_trait NOT IN
        (SELECT regexp_substr(nvl(cur.sup_trait,'0'),'[^-]+', 1, level)
        FROM dual
          CONNECT BY regexp_substr(nvl(cur.sup_trait,'0'), '[^-]+', 1, level) IS NOT NULL
        )
      AND xxaptm.supplier     =NVL(TO_NUMBER(LTRIM(lc_vendor_site_code_alt,'0')),cur.vendor_site_id )
      AND xxaptm.sup_trait_id =xxstp.sup_trait_id
      AND xxaptm.enable_flag  ='Y'
      );
	  EXCEPTION
    WHEN OTHERS THEN
      print_debug_msg(p_message => 'Error in disabling sup_trait for lc_vendor_site_code_alt: '||lc_vendor_site_code_alt||','|| SQLERRM ,p_force =>false);
    END;
    COMMIT;
	--end of shanti code for jira NAIT-126909

	END IF;

    --===============================================================
    -- Processing Custom Tolerance    --
    --===============================================================
	IF (cur.attribute8 LIKE 'TR%' AND cur.attribute8 NOT LIKE '%RTV%' ) THEN   -- Added as per Version 2.2

        SELECT COUNT(1)
          INTO ln_tol_count
          FROM xx_ap_custom_tolerances
         WHERE 1              =1
           AND supplier_id      = cur.vendor_id
           AND supplier_site_id = cur.vendor_site_id ;
        print_debug_msg(p_message => 'Custom Tolerance for the vendor : '||cur.supplier_number||', Site : '||cur.vendor_site_code, p_force => false);

        IF ln_tol_count = 0 THEN

            v_tol_flag   := xx_custom_tolerance(cur.vendor_id,
			                                    cur.vendor_site_id,
												cur.org_id,
												'Y',
												TO_NUMBER(cur.favourable_price_pct) ,
												TO_NUMBER(cur.max_price_amt) ,
												TO_NUMBER(cur.min_chargeback_amt) ,
												TO_NUMBER(cur.max_freight_amt) ,
												TO_NUMBER(cur.dist_var_neg_amt) ,
												TO_NUMBER(cur.dist_var_pos_amt)
												);
		ELSE
		    v_tol_flag   := xx_custom_tolerance(cur.vendor_id,
			                                    cur.vendor_site_id,
												cur.org_id,
												'N',
												TO_NUMBER(cur.favourable_price_pct) ,
												TO_NUMBER(cur.max_price_amt) ,
												TO_NUMBER(cur.min_chargeback_amt) ,
												TO_NUMBER(cur.max_freight_amt) ,
												TO_NUMBER(cur.dist_var_neg_amt) ,
												TO_NUMBER(cur.dist_var_pos_amt)
												);
        END IF;
        COMMIT;
	END IF;
  END LOOP;
  COMMIT;
  print_debug_msg(p_message => 'Begin Custom Tolerance Processing ', p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message => 'Error in processing xx_tolerance_trait '||SQLERRM, p_force => true);
END xx_tolerance_trait;

--+=============================================================================+
--| Name          : xx_supp_dff                                                 |
--| Description   : This procedure will Create Custom DFF Attributes to 3 groups|
--|     Also it will create Custom Tolerance, Supplier Traits                   |
--|                                                                             |
--| Parameters    : gn_request_id                                               |
--|                                                                             |
--| Returns       : N/A                                                         |
--|                                                                             |
--+=============================================================================+
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
	       dff.favourable_price_pct ,
	       dff.max_price_amt ,
	       dff.min_chargeback_amt ,
	       dff.max_freight_amt  ,
	       dff.dist_var_neg_amt ,
	       dff.dist_var_pos_amt ,
           site.create_flag ,
           site.vendor_id ,
           site.vendor_site_id,
           site.org_id,
	       site.attribute8
      FROM xx_ap_cld_site_dff_stg dff,
           xx_ap_cld_supp_sites_stg site
     WHERE 1                     =1
       AND dff.request_id          = gn_request_id
       AND site.vendor_site_code=dff.vendor_site_code
	   AND site.supplier_number=dff.supplier_number
       AND site.site_process_flag IN (7,8)
       AND site.request_id         = dff.request_id
       AND site.vendor_id         IS NOT NULL
       AND site.vendor_site_id    IS NOT NULL
	   AND dff_process_flag <> 3 --NAIT-154376--
       AND EXISTS (SELECT 1
				     FROM ap_supplier_sites_all
				    WHERE vendor_id      = site.vendor_id
				      AND vendor_site_id = site.vendor_site_id
				  );
  v_kff_id                NUMBER;
  ln_tol_count            NUMBER;
  ln_kff_count            NUMBER;
  lc_attribute10          VARCHAR2(100);
  lc_attribute11          VARCHAR2(100);
  lc_attribute12          VARCHAR2(100);
  v_error_flag            VARCHAR2(1);
  lc_error_msg            VARCHAR2(2000);
  lc_vendor_site_code_alt VARCHAR2(100);
BEGIN
  UPDATE xx_ap_cld_site_dff_stg dff
     SET dff_process_flag=3,
		 process_flag='Y',
		 error_flag='Y',
		 error_msg='Custom DFF not processed due to Site Error'
   WHERE request_id=gn_request_id
     AND EXISTS (SELECT 'x'
			       FROM xx_ap_cld_supp_sites_stg
				  WHERE request_id=dff.request_id
				    AND supplier_number=dff.supplier_number
					AND vendor_site_code=dff.vendor_site_code
					AND site_process_flag<>7
			    );
  COMMIT;

  --START NAIT-154376--
  BEGIN
  print_debug_msg(p_message => ' Updating: Custom DFF not processed due to Null Delivery Policy', p_force => true);
  
    UPDATE xx_ap_cld_site_dff_stg dff
    SET dff_process_flag=3,
      process_flag      ='Y',
      error_flag        ='Y',
      error_msg         ='Custom DFF not processed due to Null Delivery Policy'
    WHERE request_id    =gn_request_id
    AND EXISTS
      (SELECT 'x'
      FROM xx_ap_cld_supp_sites_stg
      WHERE request_id    =dff.request_id
      AND supplier_number =dff.supplier_number
      AND vendor_site_code=dff.vendor_site_code
      AND dff.vendor_site_code LIKE '%RTV%'
      AND dff.delivery_policy IS NULL
      ); 
  
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    print_debug_msg(p_message => ' Error while updating xx_ap_cld_site_dff_stg for Null Delivery Policy', p_force => true);
  END;
  ---END NAIT-154376----
  FOR cur IN C1
  LOOP
    print_debug_msg(p_message => 'Processing Custom DFF for the site : '||cur.vendor_site_code,p_force =>false);
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

    IF ln_kff_count = 0
	THEN
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
            segment17 ,
			segment11
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
            cur.deduct_from_invoice_flag,
			cur.eft_settle_days  -- Added as per Version 2.2
          );
        UPDATE ap_supplier_sites_all
           SET attribute10     =v_kff_id
         WHERE vendor_site_id=cur.vendor_site_id;
      EXCEPTION
      WHEN OTHERS
	  THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS PI PACK Custom DFF';
      END;
      print_debug_msg(p_message => ' Inserting group 2 KFF ', p_force => true);
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
      WHEN OTHERS
	  THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS Special Terms Custom DFF';
      END;
      print_debug_msg(p_message => ' Inserting group 3 KFF ', p_force => true);
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
      WHEN OTHERS
	  THEN
        v_error_flag :='Y';
        lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS RTV Custom DFF';
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
          segment17         = cur.deduct_from_invoice_flag,
		  segment11         = cur.eft_settle_days  -- Added as per Version 2.2
        WHERE vs_kff_id     = lc_attribute10
        AND structure_id    = 101;
        IF SQL%ROWCOUNT     =0 THEN
          v_error_Flag     :='Y';
          lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS PI PACK Custom DFF';
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
              segment17 ,
			  segment11
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
              cur.deduct_from_invoice_flag,
			  cur.eft_settle_days  -- Added as per Version 2.2
            );
          UPDATE ap_supplier_sites_all
             SET attribute10     =v_kff_id
           WHERE vendor_site_id=cur.vendor_site_id;
        EXCEPTION
        WHEN OTHERS THEN
          v_error_flag :='Y';
          lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS PI PACK Custom DFF';
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
           lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS Special Terms DFF';
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
			lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS Special Terms Custom DFF';
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
           lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS RTV Custom DFF';
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
             SET attribute12     = v_kff_id
           WHERE vendor_site_id= cur.vendor_site_id;
        EXCEPTION
          WHEN OTHERS THEN
            v_error_flag :='Y';
            lc_error_msg := lc_error_msg||SUBSTR(SQLERRM,1,50)||', Error in processing RMS RTV Custom DFF';
        END;
      END IF;

      UPDATE xx_ap_cld_site_dff_stg
         SET dff_process_Flag   = DECODE(v_error_Flag,'Y',6,'N',7),
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
  lc_terms_name                     VARCHAR2(50):= 'N90'; -- Added as per Version 2.6
  ln_terms_id                       NUMBER;               -- Added as per Version 2.6

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

	-- To get the Terms Details -- Added as per Version 2.6
	get_terms_id(p_terms_name  => lc_terms_name,
                 o_terms_id    => ln_terms_id);

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
		  lr_vendor_rec.terms_id                     :=ln_terms_id; -- Added as per Version 2.6
		  lr_vendor_rec.JGZZ_FISCAL_CODE             := c_sup.num_1099;  -- added by Shanti for Taxpayer_id update NAIT-118338

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
		   ap_vendor_pub_pkg.update_vendor_public(  p_api_version => v_api_version,
											p_init_msg_list => v_init_msg_list,
											p_commit => v_commit,
											p_validation_level => v_validation_level,
											x_return_status => x_return_status,
											x_msg_count => x_msg_count,
											x_msg_data => x_msg_data,
											p_vendor_rec => lr_vendor_rec,
											p_vendor_id => lr_existing_vendor_rec.vendor_id
										 );
         --- modified the API from ap_vendor_pub_pkg.update_vendor to ap_vendor_pub_pkg.update_vendor_public by Shanti for NAIT-118338
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
--| Name          : update_supplier_sites                                      |
--| Description   : This procedure will update supplier Site details using API |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE update_supplier_sites( x_ret_code 	 OUT NUMBER ,
								 x_return_status OUT VARCHAR2 ,
								 x_err_buf 		 OUT VARCHAR2
							   )
IS
  p_api_version      		       NUMBER;
  p_init_msg_list    		       VARCHAR2(200);
  p_commit           		       VARCHAR2(200);
  p_validation_level 		       NUMBER;
  x_msg_count        		       NUMBER;
  x_msg_data         		       VARCHAR2(200);
  l_msg              		       VARCHAR2(2000);
  l_process_flag     		       VARCHAR2(10);
  lr_vendor_site_rec 		       ap_vendor_pub_pkg.r_vendor_site_rec_type;
  lr_existing_vendor_site_rec      ap_supplier_sites_all%rowtype;
  p_calling_prog   		       	   VARCHAR2(200);
  l_program_step   		       	   VARCHAR2 (100) := '';
  ln_msg_index_num 		       	   NUMBER;
  v_acct_pay                       NUMBER;
  v_prepay_cde                     NUMBER;
  l_service_tolerance_name         VARCHAR2(100);
  l_qty_tolerance_name             VARCHAR2(100);
  lc_fob_value                     VARCHAR2(100);
  l_party_site_rec                 hz_party_site_v2pub.PARTY_SITE_REC_TYPE;
  ln_obj_num                       NUMBER;
  lc_return_status                 VARCHAR2(1);
  ln_msg_count                     NUMBER;
  lc_msg_data                      VARCHAR2(2000);
  ln_user_id                       NUMBER;
  ln_responsibility_id             NUMBER;
  ln_responsibility_appl_id        NUMBER;
  lr_location_rec                  hz_location_v2pub.location_rec_type;
  p_object_version_number          NUMBER;
  p_object_version_number1         NUMBER;
  p_party_site_use_rec             hz_party_site_v2pub.party_site_use_rec_type;

CURSOR c_supplier_site
IS
SELECT *
  FROM xx_ap_cld_supp_sites_stg xas
 WHERE xas.create_flag     ='N'
   AND xas.site_process_flag =gn_process_status_validated
   AND xas.request_id        = gn_request_id;

 CURSOR c_get_tolerance_name(c_cloud_tolerance VARCHAR2)
 IS
    SELECT LTRIM(RTRIM(tv.target_value1))
      FROM xx_fin_translatevalues tv,
           xx_fin_translatedefinition td
     WHERE tv.translate_id  = td.translate_id
       AND translation_name = 'XX_AP_CLOUD_TOLERANCES'
	   AND SYSDATE BETWEEN NVL(tv.start_date_active,SYSDATE) AND NVL(tv.end_date_active,SYSDATE + 1)
       AND SYSDATE BETWEEN NVL(td.start_date_active,SYSDATE) AND NVL(td.end_date_active,SYSDATE + 1)
	   AND tv.source_value1 = c_cloud_tolerance
       AND tv.enabled_flag = 'Y'
       AND td.enabled_flag = 'Y';

 CURSOR c_get_party_site_use(c_party_site_id NUMBER)
 IS
   SELECT party_site_id,
          party_site_use_id,
          object_version_number,
		  site_use_type
     FROM hz_party_site_uses
    WHERE party_site_id = c_party_site_id;

BEGIN
  -- Assign Basic Values
  print_debug_msg(p_message=> 'Begin Update Supplier Site Procedure', p_force=>true);
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';

  FOR c_sup_site IN c_supplier_site
  LOOP
    print_debug_msg(p_message=> 'Update API call for the Site : '|| c_sup_site.vendor_site_code, p_force=>true);
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

	l_service_tolerance_name  := NULL;
	l_qty_tolerance_name      := NULL;
	lc_fob_value              := NULL;

	v_acct_pay  := get_cc_id(c_sup_site.accts_pay_concat_gl_segments);
    v_prepay_cde:= get_cc_id(c_sup_site.prepay_code_gl_segments);

	-- To get the Service Tolerance
	OPEN c_get_tolerance_name(c_sup_site.service_tolerance);
	FETCH c_get_tolerance_name INTO l_service_tolerance_name;
    CLOSE c_get_tolerance_name;

	-- To get the Quantity Tolerance
	OPEN c_get_tolerance_name(c_sup_site.tolerance_name);
	FETCH c_get_tolerance_name INTO l_qty_tolerance_name;
    CLOSE c_get_tolerance_name;

	-- To get the FOB Code
	IF c_sup_site.fob_lookup_code = 'ORIGIN'
	THEN
	     lc_fob_value := 'SHIPPING';
	ELSIF c_sup_site.fob_lookup_code = 'DESTINATION'
	THEN
	     lc_fob_value := 'RECEIVING';
	ELSE
	     lc_fob_value := c_sup_site.fob_lookup_code;
	END IF;

	/* Added as per Version 3.4 */
	-- To get the legacy Supplier Number
	/*IF lr_vendor_site_rec.inactive_date IS NOT NULL
	THEN
	    lr_vendor_site_rec.attribute9   :=  NVL(c_sup_site.attribute9, FND_API.G_MISS_CHAR);
	END IF;*/   -- commented by Shanti for jira NAIT-118027

    -- Assign Vendor Site Details
    lr_vendor_site_rec.vendor_site_id                 := lr_existing_vendor_site_rec.vendor_site_id;
    lr_vendor_site_rec.last_update_date               := SYSDATE;
    lr_vendor_site_rec.vendor_id                      := lr_existing_vendor_site_rec.vendor_id;
    lr_vendor_site_rec.org_id                         := lr_existing_vendor_site_rec.org_id;
    lr_vendor_site_rec.rfq_only_site_flag             :=NVL(c_sup_site.rfq_only_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.purchasing_site_flag           :=NVL(c_sup_site.purchasing_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pcard_site_flag                :=NVL(c_sup_site.pcard_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_site_flag                  :=NVL(c_sup_site.pay_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.primary_pay_site_flag          :=NVL(c_sup_site.primary_pay_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.fax_area_code                  :=NVL(c_sup_site.fax_area_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.fax                            :=NVL(c_sup_site.fax, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.inactive_date                  :=NVL(TO_DATE(c_sup_site.inactive_date,'YYYY/MM/DD'),FND_API.G_MISS_DATE);
    lr_vendor_site_rec.customer_num                   :=NVL(c_sup_site.customer_num, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.ship_via_lookup_code           :=NVL(c_sup_site.ship_via_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.freight_terms_lookup_code      :=NVL(c_sup_site.freight_terms_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.fob_lookup_code                :=NVL(lc_fob_value, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.terms_date_basis               :=NVL(c_sup_site.terms_date_basis, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_group_lookup_code          :=NVL(c_sup_site.pay_group_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.payment_priority               :=NVL(TO_NUMBER(c_sup_site.payment_priority),99);
    lr_vendor_site_rec.terms_id                       :=NVL(c_sup_site.terms_id,FND_API.G_MISS_NUM);
    lr_vendor_site_rec.invoice_amount_limit           :=NVL(c_sup_site.invoice_amount_limit,FND_API.G_MISS_NUM);
    lr_vendor_site_rec.pay_date_basis_lookup_code     :=NVL(c_sup_site.pay_date_basis_lookup_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.always_take_disc_flag          :=NVL(c_sup_site.always_take_disc_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.invoice_currency_code          :=NVL(c_sup_site.invoice_currency_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.payment_currency_code          :=NVL(c_sup_site.payment_currency_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_all_payments_flag         :=NVL(c_sup_site.hold_all_payments_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_future_payments_flag      :=NVL(c_sup_site.hold_future_payments_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_unmatched_invoices_flag   :=NVL(c_sup_site.hold_unmatched_invoices_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.hold_reason                    :=NVL(c_sup_site.hold_reason, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.tax_reporting_site_flag        :=NVL(c_sup_site.tax_reporting_site_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.exclude_freight_from_discount  :=NVL(c_sup_site.exclude_freight_from_discount, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_on_code                    :=NVL(c_sup_site.pay_on_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.pay_on_receipt_summary_code    :=NVL(c_sup_site.pay_on_receipt_summary_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.match_option                   :=NVL(c_sup_site.match_option, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.country_of_origin_code         :=NVL(c_sup_site.country_of_origin_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.create_debit_memo_flag         :=NVL(c_sup_site.create_debit_memo_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.supplier_notif_method          :=NVL(c_sup_site.supplier_notif_method, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.email_address                  :=NVL(c_sup_site.site_email_address, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.tolerance_name                 :=NVL(l_qty_tolerance_name, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.services_tolerance_name        :=NVL(l_service_tolerance_name, FND_API.G_MISS_CHAR); -- Added as per Version 1.6
    lr_vendor_site_rec.gapless_inv_num_flag           :=NVL(c_sup_site.gapless_inv_num_flag, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.selling_company_identifier     :=NVL(c_sup_site.selling_company_identifier, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.bank_charge_bearer             :=NVL(c_sup_site.bank_charge_bearer,'D');
    lr_vendor_site_rec.vat_code                       :=NVL(c_sup_site.vat_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.vat_registration_num           :=NVL(c_sup_site.vat_registration_num, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.remit_advice_delivery_method   :=NVL(c_sup_site.remit_advice_delivery_method, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.remittance_email               :=NVL(c_sup_site.remittance_email, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute_category             :=NVL(c_sup_site.attribute_category, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute1                     :=NVL(c_sup_site.attribute1, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute2                     :=NVL(c_sup_site.attribute2, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute3                     :=NVL(c_sup_site.attribute3, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute4                     :=NVL(c_sup_site.attribute4, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute5                     :=NVL(c_sup_site.attribute5, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute6                     :=NVL(c_sup_site.attribute6, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute7                     :=NVL(c_sup_site.attribute7, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute8                     :=NVL(c_sup_site.attribute8, FND_API.G_MISS_CHAR);
    -- lr_vendor_site_rec.attribute9                     :=NVL(c_sup_site.attribute9, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute13                    :=NVL(c_sup_site.attribute13, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.attribute14                    :=NVL(c_sup_site.attribute14, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.phone                          :=NVL(c_sup_site.phone_number, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.area_code                      :=NVL(c_sup_site.phone_area_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.province                       :=NVL(c_sup_site.province, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.state                          :=NVL(c_sup_site.state, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.city                           :=NVL(c_sup_site.city, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.zip                            :=NVL(c_sup_site.postal_code, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.address_line2                  :=NVL(c_sup_site.address_line2, FND_API.G_MISS_CHAR);
    lr_vendor_site_rec.address_line1                  :=NVL(c_sup_site.address_line1, FND_API.G_MISS_CHAR);
	lr_vendor_site_rec.address_line3                  :=NVL(c_sup_site.address_line3, FND_API.G_MISS_CHAR);  -- Added as per Version 2.2
    lr_vendor_site_rec.address_line4                  :=NVL(c_sup_site.address_line4, FND_API.G_MISS_CHAR);  -- Added as per Version 2.2
	lr_vendor_site_rec.county                         :=NVL(c_sup_site.county, FND_API.G_MISS_CHAR);         -- Added as per Version 2.2
    lr_vendor_site_rec.country                        :=NVL(c_sup_site.country, FND_API.G_MISS_CHAR);
	lr_vendor_site_rec.duns_number                    :=NVL(c_sup_site.attribute5, FND_API.G_MISS_CHAR); -- Added as per Version 1.9 by Havish Kasina
	lr_vendor_site_rec.accts_pay_code_combination_id  :=v_acct_pay;   -- Added as per Version 2.4 by Havish Kasina
    lr_vendor_site_rec.prepay_code_combination_id     :=v_prepay_cde; -- Added as per Version 2.4 by Havish Kasina
	lr_vendor_site_rec.language                       := 'US';

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

    print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

    IF x_msg_count > 0 THEN
       FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
       LOOP
         fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
         print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
      END LOOP;
      l_process_flag:='E';
    ELSE
      l_process_flag:='Y';
      l_msg         :='';
    END IF;
    print_debug_msg(p_message=> l_program_step||'l_process_flag '||l_process_flag, p_force=>true);
	print_debug_msg(p_message=> l_program_step||'lr_vendor_site_rec.inactive_date '||lr_vendor_site_rec.inactive_date, p_force=>true);

	/* Added as per Version 3.0 */
	-- Update the Party Site
	BEGIN
        SELECT user_id,
               responsibility_id,
               responsibility_application_id
          INTO ln_user_id,
               ln_responsibility_id,
               ln_responsibility_appl_id
          FROM fnd_user_resp_groups
         WHERE user_id=(SELECT user_id
                          FROM fnd_user
                         WHERE user_name='ODCDH')
           AND responsibility_id=(SELECT responsibility_id
                                    FROM FND_RESPONSIBILITY
                                   WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');   -- need to confirm
    EXCEPTION
         WHEN OTHERS
        THEN
			print_debug_msg(p_message=> l_program_step||'Exception in WHEN OTHERS for SET_CONTEXT_ERROR: '||SQLERRM, p_force=>true);
    END;

	print_debug_msg(p_message=> l_program_step||'To fetch the Party Site Information', p_force=>true);
	BEGIN
	  SELECT party_site_id,
			 party_site_number,
			 object_version_number,
             location_id
		INTO l_party_site_rec.party_site_id,
		     l_party_site_rec.party_site_number,
             ln_obj_num,
             lr_location_rec.location_id
        FROM hz_party_sites A
       WHERE 1 =1
         AND party_site_id = lr_existing_vendor_site_rec.party_site_id;

	EXCEPTION
	  WHEN OTHERS
	  THEN
	      print_debug_msg(p_message=> l_program_step||'Unable to derive the party site information for site id:' || lr_existing_vendor_site_rec.vendor_site_id, p_force=>true);
    END;

  --  IF TRIM(c_sup_site.inactive_date) IS NOT NULL    -- commented by Shanti for jira NAIT-118444
	 IF TRIM(c_sup_site.inactive_date) IS NOT NULL AND to_date(c_sup_site.inactive_date,'yyyy/mm/dd')<=sysdate   ---- Added by Shanti for jira NAIT-118444
	THEN
	    l_party_site_rec.status := 'I';
	ELSE
	    l_party_site_rec.status := 'A';
    END IF;

	FND_GLOBAL.apps_initialize( ln_user_id,
                                ln_responsibility_id,
                                ln_responsibility_appl_id
                              );
	lc_return_status := NULL;
	ln_msg_count     := NULL;
	lc_msg_data      := NULL;
	-------------------------Calling Party Site API
	    print_debug_msg(p_message=> l_program_step||' Start of Calling Update Party Site API', p_force=>true);
		hz_party_site_v2pub.update_party_site( p_init_msg_list         =>  fnd_api.g_false
                                             , p_party_site_rec        =>  l_party_site_rec
                                             , p_object_version_number =>  ln_obj_num
                                             , x_return_status         =>  lc_return_status
                                             , x_msg_count             =>  ln_msg_count
                                             , x_msg_data              =>  lc_msg_data
                                             ) ;
		COMMIT;
		print_debug_msg(p_message=> l_program_step||' End of Calling Update Party Site API', p_force=>true);

		IF lc_return_status = fnd_api.g_ret_sts_success
        THEN
           print_debug_msg(p_message=> l_program_step||'Update of Party Site is Successful ', p_force=>true);

		   SELECT object_version_number
		     INTO p_object_version_number
             FROM hz_locations A
            WHERE 1 =1
              AND location_id = lr_location_rec.location_id;

		   lr_location_rec.country          :=   NVL(c_sup_site.country, FND_API.G_MISS_CHAR);
           lr_location_rec.address1         :=   NVL(c_sup_site.address_line1, FND_API.G_MISS_CHAR);
           lr_location_rec.address2         :=   NVL(c_sup_site.address_line2, FND_API.G_MISS_CHAR);
           lr_location_rec.address3         :=   NVL(c_sup_site.address_line3, FND_API.G_MISS_CHAR);
           lr_location_rec.address4         :=   NVL(c_sup_site.address_line4, FND_API.G_MISS_CHAR);
           lr_location_rec.city             :=   NVL(c_sup_site.city, FND_API.G_MISS_CHAR);
           lr_location_rec.postal_code      :=   NVL(c_sup_site.postal_code, FND_API.G_MISS_CHAR);
           lr_location_rec.state            :=   NVL(c_sup_site.state, FND_API.G_MISS_CHAR);
           lr_location_rec.province         :=   NVL(c_sup_site.province, FND_API.G_MISS_CHAR);
           lr_location_rec.county           :=   NVL(c_sup_site.county, FND_API.G_MISS_CHAR);
		   lr_location_rec.language         :=   'US';
		   x_return_status                  :=   NULL;
           x_msg_count                      :=   NULL;
           x_msg_data                       :=   NULL;
		   print_debug_msg(p_message=> l_program_step||' Start of Calling update_location API', p_force=>true);
		   hz_location_v2pub.update_location(p_init_msg_list              => fnd_api.g_true,
                                             p_location_rec               => lr_location_rec,
                                             p_object_version_number      => p_object_version_number,
                                             x_return_status              => x_return_status,
                                             x_msg_count                  => x_msg_count,
                                             x_msg_data                   => x_msg_data
                                            );

		   COMMIT;
		   print_debug_msg(p_message=> l_program_step||' End of Calling update_location API', p_force=>true);

		   IF x_return_status <> 'S'
		   THEN
		       print_debug_msg(p_message=> 'Update of Location got failed:'||x_msg_data, p_force=>true);
               FOR i IN 1 .. x_msg_count
               LOOP
                   x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                   print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
               END LOOP;
		   ELSE
		       -- Update the Party Site Use to Active when

			   IF TRIM(c_sup_site.inactive_date) IS NULL
			   THEN
			      -- To get thte Party Site Use information for the Party Site ID
				  FOR c_party_use IN c_get_party_site_use(lr_existing_vendor_site_rec.party_site_id)
				  LOOP
				      p_party_site_use_rec.party_site_id     := c_party_use.party_site_id;
					  p_party_site_use_rec.party_site_use_id := c_party_use.party_site_use_id;
					  p_object_version_number1               := c_party_use.object_version_number;
					  p_party_site_use_rec.status            := 'A';

					  print_debug_msg(p_message=> l_program_step||' p_party_site_use_rec.party_site_id :'||p_party_site_use_rec.party_site_id, p_force=>true);
					  print_debug_msg(p_message=> l_program_step||' p_party_site_use_rec.party_site_use_id :'||p_party_site_use_rec.party_site_use_id, p_force=>true);
					  print_debug_msg(p_message=> l_program_step||' p_object_version_number1 :'|| p_object_version_number1, p_force=>true);
					  print_debug_msg(p_message=> l_program_step||' site_use_type :'|| c_party_use.site_use_type, p_force=>true);

                      print_debug_msg(p_message=> ' Start of Calling Update Party Site Use API', p_force=>true);
                      hz_party_site_v2pub.update_party_site_use( p_init_msg_list            =>  FND_API.G_FALSE,
                                                                 p_party_site_use_rec       =>  p_party_site_use_rec,
                                                                 p_object_version_number    =>  p_object_version_number1,
                                                                 x_return_status            =>  x_return_status,
                                                                 x_msg_count                =>  x_msg_count,
                                                                 x_msg_data                 =>  x_msg_data
                                                               );
				      print_debug_msg(p_message=> ' End of Calling Update Party Site Use API', p_force=>true);
                      COMMIT;
                      print_debug_msg(p_message=> 'x_return_status = ' ||SUBSTR(x_return_status, 1, 255));
                      print_debug_msg(p_message=> 'x_msg_count = ' ||TO_CHAR(x_msg_count));
                      print_debug_msg(p_message=> 'x_msg_data = ' ||SUBSTR(x_msg_data, 1, 255));

                      IF x_msg_count > 1
                      THEN
                          FOR i IN 1 .. x_msg_count
                          LOOP
                             x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                             print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                          END LOOP;
                      END IF;
				  END LOOP; -- c_party_use
			   END IF;  --  IF TRIM(c_sup_site.inactive_date) IS NULL

           END IF;

        ELSE
           print_debug_msg(p_message=> l_program_step||'Update of Party Site got failed:'||lc_msg_data, p_force=>true);
           IF ln_msg_count > 0
            THEN
                print_debug_msg(p_message=> l_program_step||'Error while updating .. ', p_force=>true);
                FOR i IN 1..ln_msg_count
                LOOP
                    lc_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                    print_debug_msg(p_message=>  i|| ') '|| lc_msg_data, p_force=>true);
                END LOOP;
           END IF;
        END IF;
    print_debug_msg(p_message=> l_program_step||'Update Party Site Return Status:' || lc_return_status, p_force=>true);

    BEGIN
      UPDATE xx_ap_cld_supp_sites_stg xas
         SET xas.site_process_flag   =DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),
             xas.error_flag          =DECODE(l_process_flag,'Y',NULL,'E','Y'),
             xas.error_msg           =l_msg,
             process_flag            ='Y'
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
--+==============================================================================+
--| Name          :Update_supplier_contact for Supplier                          |
--| Description   : This procedure will update supplier conatct details using API|
--|                                                                              |
--| Parameters    : x_ret_code OUT NUMBER ,                                      |
--|                 x_return_status OUT VARCHAR2 ,                               |
--|                 x_err_buf OUT VARCHAR2                                       |
--|                                                                              |
--| Returns       : N/A                                                          |
--|                                                                              |
--+==============================================================================+
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
  l_msg              		VARCHAR2(2000);
  lc_error_mesg			    VARCHAR2(2000);
  l_process_flag     		VARCHAR2(1);
  l_email_address 			hz_contact_points.email_address%TYPE;
  l_phone_number 			hz_contact_points.phone_number%TYPE;
  l_fax_number 				hz_contact_points.phone_number%TYPE;
  l_phone_area_code 		hz_contact_points.phone_area_code%TYPE;
  l_fax_area_code 			hz_contact_points.phone_area_code%TYPE;
  lv_vendor_contact_rec 	ap_vendor_pub_pkg.r_vendor_contact_rec_type;
  lv_contact_title_rec 		hz_party_contact_v2pub.org_contact_rec_type;
  lc_error_status1		    VARCHAR2(1):='N';
  lc_error_status2		    VARCHAR2(1):='N';
  ln_user_id                NUMBER;
  ln_responsibility_id      NUMBER;
  ln_responsibility_appl_id NUMBER;

CURSOR c_cont
IS
SELECT *
  FROM xx_ap_cld_supp_contact_stg xas
 WHERE xas.create_flag        = 'N'
   AND xas.contact_process_flag = gn_process_status_validated
   AND xas.request_id           = gn_request_id
   AND cont_target              ='EBS';

CURSOR c_contact_infor(v_vendor_id NUMBER, v_vendor_site_id NUMBER) --, v_first_name VARCHAR2, v_last_name VARCHAR2)
IS
SELECT DISTINCT
	   hpr.party_id,
       asu.segment1 supp_num ,
       asu.vendor_name ,
	   asu.vendor_id,
       hpc.party_name contact_name ,
       hpr.primary_phone_country_code cnt_cntry ,
       hpr.primary_phone_area_code cnt_area ,
       hpr.primary_phone_number phone_number ,
       assa.vendor_site_code ,
       assa.vendor_site_id ,
       asco.vendor_contact_id,
       hpc.person_first_name hz_first_name,
       hpc.person_last_name hz_last_name ,
	   asco.per_party_id ,
       asco.relationship_id	,
       asco.rel_party_id ,
       asco.party_site_id  ,
       asco.org_contact_id ,
       asco.org_party_site_id
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
   AND assa.vendor_site_id         = v_vendor_site_id;
   --AND hpc.person_first_name       = v_first_name
   --AND hpc.person_last_name        = v_last_name;

CURSOR c_cont_title (v_vendor_id NUMBER, v_vendor_site_id NUMBER) --, v_first_name VARCHAR2, v_last_name VARCHAR2)
IS
SELECT DISTINCT hoc.org_contact_id,
       hoc.job_title,
       hoc.object_version_number cont_object_version_number,
       hr.object_version_number rel_object_version_number,
       hpc.object_version_number party_object_version_number,
	   assa.party_site_id
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
   AND assa.vendor_site_id         = v_vendor_site_id;
   --AND hpc.person_first_name       = v_first_name
   --AND hpc.person_last_name        = v_last_name;
BEGIN
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;

  BEGIN
      SELECT user_id,
             responsibility_id,
             responsibility_application_id
       INTO  ln_user_id,
             ln_responsibility_id,
             ln_responsibility_appl_id
       FROM  fnd_user_resp_groups
      WHERE user_id=(SELECT user_id
                       FROM fnd_user
                      WHERE user_name='ODCDH')
                        AND responsibility_id=(SELECT responsibility_id
                                                 FROM FND_RESPONSIBILITY
                                                WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
       FND_GLOBAL.apps_initialize(ln_user_id,
                                  ln_responsibility_id,
                                  ln_responsibility_appl_id
                                 );
  END;

  FOR r_cont IN c_cont
  LOOP
    lc_error_status1:='N';
    lc_error_status2:='N';
	lc_error_mesg:=NULL;
    print_debug_msg(p_message=> 'Vendor Site/First/Last Name  : '|| r_cont.vendor_site_code||'/'||r_cont.first_name||'/'||r_cont.last_name,
					p_force=>true);
    FOR r_cont_info IN c_contact_infor(r_cont.vendor_id , r_cont.vendor_site_id) -- , r_cont.first_name, r_cont.last_name )
    LOOP
	  l_phone_number    := NULL;
      l_phone_area_code := NULL;
	  l_fax_number      := NULL;
	  l_fax_area_code   := NULL;
	  l_email_address   := NULL;
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
      IF    NVL(l_phone_number,'X') <> NVL(r_cont.phone,'X')
  	     OR NVL(l_email_address,'X') <> NVL(r_cont.email_address,'X')
		 OR NVL(l_fax_number,'X') <> NVL(r_cont.fax,'X')
		 OR NVL(l_phone_area_code,'X') <> NVL(r_cont.area_code,'X')
		 OR NVL(l_fax_area_code,'X') <> NVL(r_cont.fax_area_code,'X')
		 OR NVL(r_cont_info.hz_first_name,'X') <> NVL(r_cont.first_name,'X')
		 OR NVL(r_cont_info.hz_last_name,'X') <> NVL(r_cont.last_name,'X')
	  THEN
	    lv_vendor_contact_rec.vendor_id         := r_cont.vendor_id;
		lv_vendor_contact_rec.vendor_site_id    := r_cont.vendor_site_id;
		lv_vendor_contact_rec.vendor_site_code  := r_cont.vendor_site_code;
        lv_vendor_contact_rec.vendor_contact_id := r_cont_info.vendor_contact_id;
		lv_vendor_contact_rec.person_first_name	:= r_cont.first_name;
		lv_vendor_contact_rec.person_last_name	:= r_cont.last_name;
        lv_vendor_contact_rec.phone             := NVL(r_cont.phone,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.email_address     := NVL(r_cont.email_address,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.fax_phone         := NVL(r_cont.fax,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.fax_area_code     := NVL(r_cont.fax_area_code,FND_API.G_MISS_CHAR);
        lv_vendor_contact_rec.area_code         := NVL(r_cont.area_code,FND_API.G_MISS_CHAR);
		-- lv_vendor_contact_rec.inactive_date     := NVL(TO_DATE(r_cont.inactive_date,'YYYY/MM/DD'),FND_API.G_MISS_DATE);
		lv_vendor_contact_rec.per_party_id      := r_cont_info.per_party_id;
        lv_vendor_contact_rec.relationship_id   := r_cont_info.relationship_id;
        lv_vendor_contact_rec.rel_party_id      := r_cont_info.rel_party_id;
        lv_vendor_contact_rec.party_site_id     := r_cont_info.party_site_id;
		lv_vendor_contact_rec.org_contact_id    := r_cont_info.org_contact_id;
		lv_vendor_contact_rec.org_party_site_id := r_cont_info.org_party_site_id;
		lv_vendor_contact_rec.person_first_name := r_cont.first_name;
        lv_vendor_contact_rec.person_last_name  := r_cont.last_name;

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
        print_debug_msg(p_message=> 'ap_vendor_pub_pkg.update_vendor_contact_public status :' || x_return_status , p_force => TRUE);
		IF x_return_status <>'S' AND x_msg_count > 0 THEN
		   lc_error_status1:='Y';
           FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
           LOOP
            fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num);
			lc_error_mesg:=lc_error_mesg||','||l_msg;
            print_debug_msg(p_message=> 'The ap_vendor_pub_pkg.update_vendor_contact_public status call failed with error: ' || l_msg , p_force => TRUE);
           END LOOP;
        ELSE
          l_msg          := '';
        END IF;
      END IF;
    END LOOP;

	print_debug_msg(p_message=>'Starting Calling c_cont_title',p_force=>TRUE);

	FOR r_cont_title IN c_cont_title (r_cont.vendor_id , r_cont.vendor_site_id) -- ,r_cont.first_name,r_cont.last_name )
    LOOP

      IF NVL(r_cont_title.job_title,'X')    <> NVL(r_cont.title,'X')
	  THEN
	    -- lv_contact_title_rec.party_site_id  := r_cont_title.party_site_id;
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
        print_debug_msg(p_message=> 'hz_party_contact_v2pub.update_org_contact, status :' || x_return_status, p_force => TRUE);

  	    IF x_return_status <>'S' AND x_msg_count > 0 THEN
		   lc_error_status2:='Y';
           FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
           LOOP
             fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
			 lc_error_mesg:=lc_error_mesg||','||l_msg;
             print_debug_msg(p_message=> 'The API call failed with error ' || l_msg , p_force => TRUE);
           END LOOP;
        ELSE
          l_msg         :='';
        END IF;
      END IF;
    END LOOP;

	l_process_flag:=NULL;
	IF lc_error_status1='N' and lc_error_status2='N' THEN
	   l_process_flag:='Y';
	ELSE
	   l_process_flag:='E';
	END IF;
    print_debug_msg(p_message=>'Process status : '||l_process_flag, p_force => TRUE);

    BEGIN
      UPDATE xx_ap_cld_supp_contact_stg xas
         SET xas.contact_process_flag   = DECODE (l_process_flag,'Y',gn_process_status_imported ,'E',gn_process_status_imp_fail),
             xas.error_flag             = DECODE( l_process_flag,'Y',NULL,'E','Y'),
             xas.error_msg              = lc_error_mesg,
             process_flag               = 'Y'
       WHERE xas.contact_process_flag   = gn_process_status_validated
         AND xas.request_id             = gn_request_id
         AND xas.supplier_number        = r_cont.supplier_number
         AND TRIM(xas.first_name)       = TRIM(r_cont.first_name)
         AND TRIM(xas.last_name)        = TRIM(r_cont.last_name)
         AND TRIM(xas.vendor_site_code) = TRIM(r_cont.vendor_site_code);
      COMMIT;
    EXCEPTION
      WHEN OTHERS
	  THEN
        print_debug_msg(p_message=> 'In Exception to update records'||SQLERRM, p_force => TRUE);
    END ;
  END LOOP;
EXCEPTION
  WHEN OTHERS
  THEN
    fnd_file.put_line(fnd_file.LOG,SQLCODE||','||SQLERRM);
END update_supplier_contact;
--+============================================================================+
--| Name          : update_address_contact                                     |
--| Description   : This procedure will update address contact point using API |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--+============================================================================+
PROCEDURE update_address_contact( x_ret_code 	     OUT NUMBER ,
								  x_return_status    OUT VARCHAR2 ,
								  x_err_buf 		 OUT VARCHAR2
							    )
IS
  p_api_version      		       NUMBER;
  p_init_msg_list    		       VARCHAR2(200);
  p_commit           		       VARCHAR2(200);
  p_validation_level 		       NUMBER;
  l_msg              		       VARCHAR2(2000);
  l_process_flag     		       VARCHAR2(10);
  lr_existing_vendor_site_rec      ap_supplier_sites_all%rowtype;
  p_calling_prog   		       	   VARCHAR2(200);
  l_program_step   		       	   VARCHAR2 (100) := '';
  ln_msg_index_num 		       	   NUMBER;
  lr_contact_point_rec             hz_contact_point_v2pub.contact_point_rec_type;
  lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
  lr_email_rec                     hz_contact_point_v2pub.email_rec_type;
  lr_phone_rec                     hz_contact_point_v2pub.phone_rec_type;
  lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
  lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
  x_msg_count                      NUMBER;
  x_msg_data                       VARCHAR2(2000);
  ln_user_id                       NUMBER;
  ln_responsibility_id             NUMBER;
  ln_responsibility_appl_id        NUMBER;
  ln_object_version_number         NUMBER :=1;
  x_contact_point_id               NUMBER;

  CURSOR c_supplier_site
  IS
    SELECT *
      FROM xx_ap_cld_supp_sites_stg xas
     WHERE 1 =1
       AND xas.site_process_flag = gn_process_status_imported
       AND xas.request_id        = gn_request_id
       AND (   xas.fax_area_code IS NOT NULL
	        OR xas.fax IS NOT NULL
			OR xas.email_address IS NOT NULL
	        OR xas.phone_number IS NOT NULL
	        OR xas.phone_area_code IS NOT NULL);

  CURSOR c_contact_details(c_party_site_id NUMBER)
  IS
    SELECT hps.party_site_id,
           phone.object_version_number phone_obj_version,
           email.object_version_number email_obj_version,
           fax.object_version_number fax_obj_version,
           phone.contact_point_id phone_cont_point_id,
           email.contact_point_id email_cont_point_id,
           fax.contact_point_id fax_cont_point_id,
           hps.party_site_name      AS address_name,
           hzl.address1             AS loc_address1,
           hzl.address2             AS loc_address2,
           hzl.address3             AS loc_address3,
           hzl.city                 AS loc_city,
           hzl.county               AS loc_county,
           hzl.state                AS loc_state,
           hzl.province             AS loc_province,
           hzl.postal_code          AS loc_postal_code,
           hzl.country              AS loc_country,
           fvl.territory_short_name AS country_name ,
           hzl.address4             AS loc_address4,
           email.email_address,
           email.contact_point_type AS email_contact_point_type,
           phone.raw_phone_number AS phone_number,
           phone.contact_point_type AS phone_contact_point_type,
           fax.raw_phone_number   AS fax_number,
           fax.contact_point_type AS fax_contact_point_type
      FROM hz_party_sites hps,
           hz_locations hzl,
           fnd_territories_vl fvl,
           hz_contact_points email,
           hz_contact_points phone,
           hz_contact_points fax
     WHERE 1 = 1
       -- AND hps.status     = 'A'
       AND hps.party_site_id = c_party_site_id
       AND hzl.country                 = fvl.territory_code
       AND email.owner_table_id(+)     = hps.party_site_id
       AND email.owner_table_name(+)   = 'HZ_PARTY_SITES'
       AND email.status(+)             = 'A'
       AND email.contact_point_type(+) = 'EMAIL'
       AND email.primary_flag(+)       = 'Y'
       AND phone.owner_table_id(+)     = hps.party_site_id
       AND phone.owner_table_name(+)   = 'HZ_PARTY_SITES'
       AND phone.status(+)             = 'A'
       AND phone.contact_point_type(+) = 'PHONE'
       AND phone.phone_line_type (+)   = 'GEN'
       AND phone.primary_flag(+)       = 'Y'
       AND fax.owner_table_id(+)       = hps.party_site_id
       AND fax.owner_table_name(+)     = 'HZ_PARTY_SITES'
       AND fax.status(+)               = 'A'
       AND fax.contact_point_type(+)   = 'PHONE'
       AND fax.phone_line_type (+)     = 'FAX'
       AND hps.location_id             = hzl.location_id;

BEGIN
  -- Assign Basic Values
  print_debug_msg(p_message=> 'Begin Update Supplier Site Address Contact Procedure', p_force=>true);
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';

  BEGIN
       SELECT user_id,
              responsibility_id,
              responsibility_application_id
         INTO ln_user_id,
              ln_responsibility_id,
              ln_responsibility_appl_id
         FROM fnd_user_resp_groups
        WHERE user_id=(SELECT user_id
                         FROM fnd_user
                        WHERE user_name = 'ODCDH')
          AND responsibility_id=(SELECT responsibility_id
                                   FROM fnd_responsibility
                                  WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
  EXCEPTION
       WHEN OTHERS
       THEN
			print_debug_msg(p_message=> l_program_step||'Exception in WHEN OTHERS for SET_CONTEXT_ERROR: '||SQLERRM, p_force=>true);
  END;

  fnd_global.apps_initialize( ln_user_id,
                              ln_responsibility_id,
                              ln_responsibility_appl_id
                            );
  fnd_global.set_nls_context('AMERICAN');

  FOR c_sup_site IN c_supplier_site
  LOOP
    print_debug_msg(p_message=> 'Address Contact for the Site : '|| c_sup_site.vendor_site_code, p_force=>true);
	print_debug_msg(p_message=> 'Email Address : '|| c_sup_site.email_address, p_force=>true);
	print_debug_msg(p_message=> 'Phone Area Code : '|| c_sup_site.phone_area_code, p_force=>true);
	print_debug_msg(p_message=> 'Phone Number : '|| c_sup_site.phone_number, p_force=>true);
	print_debug_msg(p_message=> 'Fax Area Code : '|| c_sup_site.fax_area_code, p_force=>true);
	print_debug_msg(p_message=> 'Fax Number : '|| c_sup_site.fax, p_force=>true);
    BEGIN
      SELECT *
        INTO lr_existing_vendor_site_rec
        FROM ap_supplier_sites_all assa
       WHERE assa.vendor_site_code = c_sup_site.vendor_site_code;

    EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message=> l_program_step||'Unable to derive the supplier site information for site id:' || lr_existing_vendor_site_rec.vendor_site_id, p_force=>true);
    END;

	FOR c_sup_contact IN c_contact_details(lr_existing_vendor_site_rec.party_site_id)
	LOOP
	    print_debug_msg(p_message=> 'lr_existing_vendor_site_rec.party_site_id : '|| lr_existing_vendor_site_rec.party_site_id, p_force=>true);
		-- Initializing the Mandatory API parameters
	    -- Update Email Address
	    IF c_sup_site.email_address IS NOT NULL
	    THEN
			print_debug_msg(p_message=> 'c_sup_site.email_address: '|| c_sup_site.email_address, p_force=>true);
		    IF c_sup_contact.email_cont_point_id IS NOT NULL
			THEN
			    print_debug_msg(p_message=> 'Update the EMAIL Address Contact for the Site: '|| c_sup_site.vendor_site_code, p_force=>true);
	            lr_contact_point_rec := NULL;
		        lr_phone_rec := NULL;
		        lr_email_rec := NULL;
	            lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	            lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
	            lr_contact_point_rec.contact_point_id       := c_sup_contact.email_cont_point_id;
		        lr_contact_point_rec.contact_point_type     := 'EMAIL';
		        lr_email_rec.email_address                  := c_sup_site.email_address;
				ln_object_version_number                    := c_sup_contact.email_obj_version;
    	        fnd_msg_pub.initialize;
		        x_return_status    := NULL;
                x_msg_count        := NULL;
                x_msg_data         := NULL;
                -------------------------Calling Address Contact API

		        hz_contact_point_v2pub.update_contact_point ( p_init_msg_list => fnd_api.g_false,
		                                                      p_contact_point_rec => lr_contact_point_rec,
													          p_edi_rec => lr_edi_rec,
													          p_email_rec => lr_email_rec,
													          p_phone_rec => lr_phone_rec,
                                                              p_telex_rec => lr_telex_rec,
													          p_web_rec => lr_web_rec,
                                                              p_object_version_number => ln_object_version_number,
                                                              x_return_status => x_return_status,
													          x_msg_count => x_msg_count,
													          x_msg_data => x_msg_data );

                print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		        IF x_return_status = 'S'
		        THEN
                   COMMIT;
                   print_debug_msg(p_message=> 'Update of EMAIL Contact Point is Successful ', p_force=>true);
                   print_debug_msg(p_message=> 'Output information ....', p_force=>true);
                ELSE
                   print_debug_msg(p_message=> 'Update of EMAIL Contact Point got failed:'||x_msg_data, p_force=>true);
                   ROLLBACK;
                   FOR i IN 1 .. x_msg_count
                   LOOP
                      x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                      print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                   END LOOP;
                END IF;
			ELSE
			    print_debug_msg(p_message=> 'Creation of the EMAIL Address Contact for the Site: '|| c_sup_site.vendor_site_code, p_force=>true);
			    lr_contact_point_rec := NULL;
		        lr_phone_rec := NULL;
		        lr_email_rec := NULL;
	            lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	            lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
                lr_contact_point_rec.created_by_module      := 'AP_SUPPLIERS_API';
	            lr_contact_point_rec.primary_flag           := 'Y';
		        lr_contact_point_rec.contact_point_type     := 'EMAIL';
		        lr_email_rec.email_address                  := c_sup_site.email_address;
    	        fnd_msg_pub.initialize;
                x_contact_point_id := NULL;
		        x_return_status    := NULL;
                x_msg_count        := NULL;
                x_msg_data         := NULL;
                -------------------------Calling Address Contact API

		        hz_contact_point_v2pub.create_contact_point ( p_init_msg_list => fnd_api.g_false,
		                                                      p_contact_point_rec => lr_contact_point_rec,
													          p_edi_rec => lr_edi_rec,
													          p_email_rec => lr_email_rec,
													          p_phone_rec => lr_phone_rec,
                                                              p_telex_rec => lr_telex_rec,
													          p_web_rec => lr_web_rec,
													          x_contact_point_id => x_contact_point_id,
													          x_return_status => x_return_status,
													          x_msg_count => x_msg_count,
													          x_msg_data => x_msg_data );

                print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		        IF x_return_status = 'S'
		        THEN
                   COMMIT;
                   print_debug_msg(p_message=> 'Creation of EMAIL Contact Point is Successful ', p_force=>true);
                   print_debug_msg(p_message=> 'Output information ....', p_force=>true);
                   print_debug_msg(p_message=> 'x_contact_point_id = '||x_contact_point_id, p_force=>true);
                ELSE
                   print_debug_msg(p_message=> 'Creation of Contact Point got failed:'||x_msg_data, p_force=>true);
                   ROLLBACK;
                   FOR i IN 1 .. x_msg_count
                   LOOP
                      x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                      print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                      END LOOP;
                END IF;
			END IF; -- c_sup_contact.email_cont_point_id IS NOT NULL
		END IF; -- c_sup_site.email_address IS NOT NULL
            -- Update PHONE Address
        IF c_sup_site.phone_number IS NOT NULL
	    THEN
		    print_debug_msg(p_message=> 'c_sup_site.phone_number: '|| c_sup_site.phone_number, p_force=>true);
		    IF c_sup_contact.phone_cont_point_id IS NOT NULL
			THEN
			    print_debug_msg(p_message=> 'Update the PHONE Address Contact for the Site: '|| c_sup_site.vendor_site_code, p_force=>true);
	            lr_contact_point_rec := NULL;
		        lr_phone_rec := NULL;
		        lr_email_rec := NULL;
		        lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	            lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
	            lr_contact_point_rec.contact_point_id       := c_sup_contact.phone_cont_point_id;
		        lr_contact_point_rec.contact_point_type     := 'PHONE';
		        lr_phone_rec.phone_area_code                := c_sup_site.phone_area_code;
                lr_phone_rec.phone_number                   := c_sup_site.phone_number;
                lr_phone_rec.phone_line_type                := 'GEN';
				ln_object_version_number                    := c_sup_contact.phone_obj_version;
    	        fnd_msg_pub.initialize;
		        x_return_status    := NULL;
                x_msg_count        := NULL;
                x_msg_data         := NULL;
                -------------------------Calling Address Contact API

		        hz_contact_point_v2pub.update_contact_point ( p_init_msg_list => fnd_api.g_false,
		                                                      p_contact_point_rec => lr_contact_point_rec,
													          p_edi_rec => lr_edi_rec,
													          p_email_rec => lr_email_rec,
													          p_phone_rec => lr_phone_rec,
                                                              p_telex_rec => lr_telex_rec,
													          p_web_rec => lr_web_rec,
                                                              p_object_version_number => ln_object_version_number,
                                                              x_return_status => x_return_status,
													          x_msg_count =>x_msg_count,
													          x_msg_data => x_msg_data );

                print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		        IF x_return_status = 'S'
		        THEN
                    COMMIT;
                    print_debug_msg(p_message=> 'Update of PHONE Contact Point is Successful ', p_force=>true);
                    print_debug_msg(p_message=> 'Output information ....', p_force=>true);
                ELSE
                    print_debug_msg(p_message=> 'Update of PHONE Contact Point got failed:'||x_msg_data, p_force=>true);
                    ROLLBACK;
                    FOR i IN 1 .. x_msg_count
                    LOOP
                       x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                       print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                    END LOOP;
                END IF;
			ELSE
			    print_debug_msg(p_message=> 'Creation of the PHONE Address Contact for the Site: '|| c_sup_site.vendor_site_code, p_force=>true);
			    lr_contact_point_rec := NULL;
		        lr_phone_rec := NULL;
		        lr_email_rec := NULL;
		        lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	            lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
                lr_contact_point_rec.created_by_module      := 'AP_SUPPLIERS_API';
	            lr_contact_point_rec.primary_flag           := 'Y';
		        lr_contact_point_rec.contact_point_type     := 'PHONE';
		        lr_phone_rec.phone_area_code                := c_sup_site.phone_area_code;
                lr_phone_rec.phone_number                   := c_sup_site.phone_number;
                lr_phone_rec.phone_line_type                := 'GEN';
    	        fnd_msg_pub.initialize;
                x_contact_point_id := NULL;
		        x_return_status    := NULL;
                x_msg_count        := NULL;
                x_msg_data         := NULL;
                -------------------------Calling Address Contact API

		        hz_contact_point_v2pub.create_contact_point ( p_init_msg_list => fnd_api.g_false,
		                                                      p_contact_point_rec => lr_contact_point_rec,
													          p_edi_rec => lr_edi_rec,
													          p_email_rec => lr_email_rec,
													          p_phone_rec => lr_phone_rec,
                                                              p_telex_rec => lr_telex_rec,
													          p_web_rec => lr_web_rec,
													          x_contact_point_id => x_contact_point_id,
													          x_return_status => x_return_status,
													          x_msg_count => x_msg_count,
													          x_msg_data => x_msg_data );

                print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		        IF x_return_status = 'S'
		        THEN
                   COMMIT;
                   print_debug_msg(p_message=> 'Creation of PHONE Contact Point is Successful ', p_force=>true);
                   print_debug_msg(p_message=> 'Output information ....', p_force=>true);
                   print_debug_msg(p_message=> 'x_contact_point_id = '||x_contact_point_id, p_force=>true);
                ELSE
                   print_debug_msg(p_message=> 'Creation of Contact Point got failed:'||x_msg_data, p_force=>true);
                   ROLLBACK;
                   FOR i IN 1 .. x_msg_count
                   LOOP
                      x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                      print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                      END LOOP;
                END IF;
			END IF; -- c_sup_contact.phone_cont_point_id IS NOT NULL
		END IF; -- c_sup_site.phone_number IS NOT NULL
		-- Update FAX Address
	    IF c_sup_site.fax IS NOT NULL
	    THEN
		    print_debug_msg(p_message=> 'c_sup_site.fax: '|| c_sup_site.fax, p_force=>true);
		    IF c_sup_contact.fax_cont_point_id IS NOT NULL
			THEN
			    print_debug_msg(p_message=> 'Update the FAX Address Contact for the Site: '|| c_sup_site.vendor_site_code, p_force=>true);
	            lr_contact_point_rec := NULL;
		        lr_phone_rec := NULL;
		        lr_email_rec := NULL;
		        lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	            lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
	            lr_contact_point_rec.contact_point_id       := c_sup_contact.fax_cont_point_id;
		        lr_contact_point_rec.contact_point_type     := 'PHONE';
		        lr_phone_rec.phone_area_code                := c_sup_site.fax_area_code;
                lr_phone_rec.phone_number                   := c_sup_site.fax;
                lr_phone_rec.phone_line_type                := 'FAX';
				ln_object_version_number                    := c_sup_contact.fax_obj_version;
    	        fnd_msg_pub.initialize;
		        x_return_status    := NULL;
                x_msg_count        := NULL;
                x_msg_data         := NULL;
                -------------------------Calling Address Contact API

		        hz_contact_point_v2pub.update_contact_point ( p_init_msg_list => fnd_api.g_false,
		                                                      p_contact_point_rec => lr_contact_point_rec,
													          p_edi_rec => lr_edi_rec,
													          p_email_rec => lr_email_rec,
													          p_phone_rec => lr_phone_rec,
                                                              p_telex_rec => lr_telex_rec,
													          p_web_rec => lr_web_rec,
                                                              p_object_version_number => ln_object_version_number,
                                                              x_return_status => x_return_status,
													          x_msg_count =>x_msg_count,
													          x_msg_data => x_msg_data );

                print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		        IF x_return_status = 'S'
		        THEN
                   COMMIT;
                   print_debug_msg(p_message=> 'Update of FAX Contact Point is Successful ', p_force=>true);
                   print_debug_msg(p_message=> 'Output information ....', p_force=>true);
                ELSE
                   print_debug_msg(p_message=> 'Update of FAX Contact Point got failed:'||x_msg_data, p_force=>true);
                   ROLLBACK;
                   FOR i IN 1 .. x_msg_count
                   LOOP
                      x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                      print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                      END LOOP;
                END IF;
			ELSE
			    print_debug_msg(p_message=> 'Creation of the FAX Address Contact for the Site: '|| c_sup_site.vendor_site_code, p_force=>true);
			    lr_contact_point_rec := NULL;
		        lr_phone_rec := NULL;
		        lr_email_rec := NULL;
	            lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	            lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
                lr_contact_point_rec.created_by_module      := 'AP_SUPPLIERS_API';
	            lr_contact_point_rec.primary_flag           := 'N';
		        lr_contact_point_rec.contact_point_type     := 'PHONE';
		        lr_phone_rec.phone_area_code                := c_sup_site.fax_area_code;
                lr_phone_rec.phone_number                   := c_sup_site.fax;
                lr_phone_rec.phone_line_type                := 'FAX';
    	        fnd_msg_pub.initialize;
                x_contact_point_id := NULL;
		        x_return_status:= NULL;
                x_msg_count    := NULL;
                x_msg_data     := NULL;
                -------------------------Calling Address Contact API

		        hz_contact_point_v2pub.create_contact_point ( p_init_msg_list => fnd_api.g_false,
		                                                      p_contact_point_rec => lr_contact_point_rec,
													          p_edi_rec => lr_edi_rec,
													          p_email_rec => lr_email_rec,
													          p_phone_rec => lr_phone_rec,
                                                              p_telex_rec => lr_telex_rec,
													          p_web_rec => lr_web_rec,
													          x_contact_point_id => x_contact_point_id,
													          x_return_status => x_return_status,
													          x_msg_count => x_msg_count,
													          x_msg_data => x_msg_data );

                print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		        IF x_return_status = 'S'
		        THEN
                   COMMIT;
                   print_debug_msg(p_message=> 'Creation of FAX Contact Point is Successful ', p_force=>true);
                   print_debug_msg(p_message=> 'Output information ....', p_force=>true);
                   print_debug_msg(p_message=> 'x_contact_point_id = '||x_contact_point_id, p_force=>true);
                ELSE
                   print_debug_msg(p_message=> 'Creation of Contact Point got failed:'||x_msg_data, p_force=>true);
                   ROLLBACK;
                   FOR i IN 1 .. x_msg_count
                   LOOP
                      x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
                      print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
                      END LOOP;
                END IF;
			END IF; -- c_sup_contact.fax_cont_point_id IS NOT NULL
		END IF; -- c_sup_site.fax IS NOT NULL
	END LOOP; -- c_contact_details
  END LOOP; -- c_supplier_site
EXCEPTION
  WHEN OTHERS THEN
    x_ret_code      := 1;
    x_return_status := 'E';
    x_err_buf       := 'In exception for procedure update_address_contact' ;
END update_address_contact;
--+============================================================================+
--| Name          : update_remittance_email                                    |
--| Description   : This procedure will update the remittance email in the IBY |
--|                 External Party Payment Methods Table                       |
--| Parameters    : x_ret_code OUT NUMBER ,                                    |
--|                 x_return_status OUT VARCHAR2 ,                             |
--|                 x_err_buf OUT VARCHAR2                                     |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE update_remittance_email( x_ret_code 	     OUT NUMBER ,
								   x_return_status   OUT VARCHAR2 ,
								   x_err_buf 		 OUT VARCHAR2
							     )
IS
   x_msg_count                     NUMBER := 0;
   x_msg_data                      VARCHAR2 (200) := NULL;
   l_payee_upd_status              iby_disbursement_setup_pub.ext_payee_update_tab_type;
   p_external_payee_tab_type       iby_disbursement_setup_pub.external_payee_tab_type;
   p_ext_payee_id_tab_type         iby_disbursement_setup_pub.ext_payee_id_tab_type;
   p_ext_payee_id_rec              iby_disbursement_setup_pub.ext_payee_id_rec_type;
   l_ext_payee_rec                 iby_disbursement_setup_pub.external_payee_rec_type;
   i                               NUMBER := 0;
   ln_user_id                      NUMBER;
   ln_responsibility_id            NUMBER;
   ln_responsibility_appl_id       NUMBER;

   CURSOR get_stg_remit_email
   IS
     SELECT *
       FROM XX_AP_CLD_SUPP_SITES_STG
      WHERE 1 =1
        AND request_id  = gn_request_id
        AND site_process_flag  = 7;

   CURSOR c_site_remit_email(p_vendor_id    NUMBER,
                             p_vend_site_id NUMBER)
   IS
      SELECT  ieppm.payment_method_code,
              iepa.payee_party_id,
              assa.vendor_site_id,
              iepa.ext_payee_id,
              assa.org_id,
              iepa.supplier_site_id,
              assa.party_site_id,
			  iepa.remit_advice_email
        FROM  ap_supplier_sites_all assa,
              ap_suppliers sup,
              iby_external_payees_all iepa,
              iby_ext_party_pmt_mthds ieppm,
              hr_operating_units ou
        WHERE sup.vendor_id = assa.vendor_id
          -- AND assa.pay_site_flag = 'Y'
          AND assa.vendor_site_id = iepa.supplier_site_id
          AND iepa.ext_payee_id = ieppm.ext_pmt_party_id(+)
          AND assa.org_id = ou.organization_id
          AND assa.vendor_site_id = p_vend_site_id
          AND assa.vendor_id = p_vendor_id;

BEGIN
   print_debug_msg('To Update the Remittance Email' ,p_force=> true);
   print_debug_msg('update_remittance_email() - BEGIN' ,p_force=> true);
   BEGIN
        SELECT user_id,
               responsibility_id,
               responsibility_application_id
          INTO ln_user_id,
               ln_responsibility_id,
               ln_responsibility_appl_id
          FROM fnd_user_resp_groups
         WHERE user_id=(SELECT user_id
                          FROM fnd_user
                         WHERE user_name='ODCDH')
           AND responsibility_id=(SELECT responsibility_id
                                    FROM fnd_responsibility
                                   WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
   EXCEPTION
   WHEN OTHERS
   THEN
	   print_debug_msg('Exception in WHEN OTHERS for SET_CONTEXT_ERROR: '||SQLERRM,p_force=> true);
   END;

   fnd_global.apps_initialize (user_id        => ln_user_id,
                               resp_id        => ln_responsibility_id,
                               resp_appl_id   => ln_responsibility_appl_id);

   print_debug_msg('Call get_remit_email cursor to get IBY External Party Payment Methods details',p_force=> true);
   FOR cur IN get_stg_remit_email
   LOOP
     print_debug_msg('Processing the Vendor Site :'||cur.vendor_site_code ,p_force=> true);
	 print_debug_msg('Call c_site_remit_email cursor to get the Remittance Email Details from Staging Table',p_force=> true);
	 FOR cr IN c_site_remit_email(cur.vendor_id,
	                              cur.vendor_site_id)
     LOOP
	    print_debug_msg('Remit Advice Email From the IBY External Party Table :'||cr.remit_advice_email ,p_force=> true);
		print_debug_msg('Remittance Email from the Staging Table :'||cur.remittance_email ,p_force=> true);

		print_debug_msg('Remit Advice Email and Remittance Email are not Same',p_force=> true);
        p_external_payee_tab_type (i).exclusive_pay_flag := cur.pay_alone_flag;   --Modified by Shanti for jira NAIT-112927
        p_external_payee_tab_type (i).payee_party_id := cr.payee_party_id;
        p_external_payee_tab_type (i).payment_function := 'PAYABLES_DISB';
        p_external_payee_tab_type (i).payer_org_id := cr.org_id;
        p_external_payee_tab_type (i).payer_org_type := 'OPERATING_UNIT';
        p_external_payee_tab_type (i).supplier_site_id := cr.supplier_site_id;
        p_external_payee_tab_type (i).Payee_Party_Site_Id := cr.party_site_id;
        p_external_payee_tab_type (i).Remit_advice_delivery_method:='EMAIL';
        p_external_payee_tab_type (i).Remit_advice_email:=cur.remittance_email;
        p_ext_payee_id_tab_type (i).ext_payee_id := cr.ext_payee_id;
        p_external_payee_tab_type (i).Default_Pmt_method:=cur.payment_method_lookup_code;
           iby_disbursement_setup_pub.update_external_payee (p_api_version            => 1.0,
			                                                 p_init_msg_list          => 'T',
			                                                 p_ext_payee_tab          => p_external_payee_tab_type,
			                                                 p_ext_payee_id_tab       => p_ext_payee_id_tab_type,
			                                                 x_return_status          => x_return_status,
			                                                 x_msg_count              => x_msg_count,
			                                                 x_msg_data               => x_msg_data,
			                                                 x_ext_payee_status_tab   => l_payee_upd_status
		                                                    );

        COMMIT;
        IF x_return_status = 'E'
		THEN
            FOR k IN l_payee_upd_status.FIRST .. l_payee_upd_status.LAST
            LOOP
               print_debug_msg('Error Message : '|| l_payee_upd_status(k).payee_update_msg,p_force=> true);
            END LOOP;
        END IF; -- x_return_status = 'E'

 	    i := 0;
	 END LOOP; -- c_site_remit_email
   END LOOP; -- get_stg_remit_email
EXCEPTION
  WHEN OTHERS
  THEN
      x_ret_code      := 1;
      x_return_status := 'E';
      x_err_buf       := 'In exception for procedure update_remittance_email' ;
END update_remittance_email;
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
    AND xas.request_id          = gn_request_id
  ORDER BY primary_flag DESC;
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
    lv_supp_site_id        := NULL;
    lv_supp_party_site_id  := NULL;
    lv_acct_owner_party_id := NULL;
    lv_org_id              := NULL;
    p_assignment_attribs.priority := NULL;
    print_debug_msg(p_message=> l_program_step||'Inside Cursor', p_force=>true);
	print_debug_msg(p_message=> l_program_step||'Vendor Site Code : '||r_sup_bank.vendor_site_code, p_force=>true);
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
    WHEN OTHERS
	THEN
	    lv_supp_site_id        := NULL;
        lv_supp_party_site_id  := NULL;
        lv_acct_owner_party_id := NULL;
        lv_org_id              := NULL;
        print_debug_msg(p_message=> l_program_step||'Error- Get supp_site_id and supp_party_site_id' || SQLCODE || sqlerrm, p_force=>true);
    END;
    IF r_sup_bank.account_id >0 AND r_sup_bank.instrument_uses_id IS NULL
	THEN
	  print_debug_msg(p_message=> l_program_step||'Account ID exists and Instrument Uses ID is NULL', p_force=>true);
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
      -- p_assignment_attribs.priority   := 1;
	  print_debug_msg(p_message=> l_program_step||'Primary Flag :'||r_sup_bank.primary_flag, p_force=>true);
	  IF r_sup_bank.primary_flag = 'Y'
	  THEN
	      p_assignment_attribs.priority := 1;
	  END IF;
      p_assignment_attribs.start_date := sysdate;
	  print_debug_msg(p_message=> l_program_step||'Priority :'||p_assignment_attribs.priority, p_force=>true);
	  print_debug_msg(p_message=> l_program_step||'Start Date :'||TO_CHAR(p_assignment_attribs.start_date,'DD-MON-YYYY'), p_force=>true);

      ------------------Calling API to check Joint Owner exists or no
      fnd_msg_pub.initialize; --to make msg_count 0
      x_return_status:=NULL;
      x_msg_count    :=NULL;
      x_msg_data     :=NULL;
      x_response     :=NULL;
	  print_debug_msg(p_message=> l_program_step||'Start of Calling API to check Joint Owner exists or not', p_force=>true);
      iby_ext_bankacct_pub.check_bank_acct_owner ( p_api_version =>p_api_version,
	                                               p_init_msg_list=>p_init_msg_list,
												   p_bank_acct_id=>r_sup_bank.account_id,
												   p_acct_owner_party_id =>lv_acct_owner_party_id,
												   x_return_status=>x_return_status,
												   x_msg_count=>x_msg_count,
												   x_msg_data=>x_msg_data,
												   x_response=>x_response );
	  print_debug_msg(p_message=> l_program_step||'End of Calling API to check Joint Owner exists or not', p_force=>true);
      IF x_return_status <>'S'
	  THEN --------------No join owner exists
	    print_debug_msg(p_message=> l_program_step||'No join owner exists', p_force=>true);
        print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
        FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
        LOOP
            fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
            print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
        END LOOP;
        fnd_msg_pub.initialize;                 --to make msg_count 0
        x_return_status:=NULL;
        x_msg_count    :=NULL;
        x_msg_data     :=NULL;
        x_response     :=NULL;
        -------------------------Calling Joint Account Owner API
		print_debug_msg(p_message=> l_program_step||'Start of Calling Joint Account Owner API', p_force=>true);
        iby_ext_bankacct_pub.add_joint_account_owner ( p_api_version =>p_api_version,
		                                               p_init_msg_list=>p_init_msg_list,
													   p_bank_account_id=>r_sup_bank.account_id,
													   p_acct_owner_party_id =>lv_acct_owner_party_id,
													   x_joint_acct_owner_id=>l_joint_acct_owner_id,
													   x_return_status=>x_return_status,
													   x_msg_count=>x_msg_count,
													   x_msg_data=>x_msg_data,
													   x_response=>x_response );
		print_debug_msg(p_message=> l_program_step||'End of Calling Joint Account Owner API', p_force=>true);
		IF x_return_status <>'S'
	    THEN
	        print_debug_msg(p_message=> l_program_step||'Unable to Add Joint Account Owner', p_force=>true);
            FOR i IN 1 .. x_msg_count--fnd_msg_pub.count_msg
            LOOP
               fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num );
               print_debug_msg(p_message=> l_program_step||'The API call failed with error ' || l_msg , p_force=>true);
            END LOOP;
		END IF;
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
      --------------------Call the API for instr assignment
      iby_disbursement_setup_pub.set_payee_instr_assignment (p_api_version => p_api_version,
	                                                         p_init_msg_list => p_init_msg_list,
															 p_commit => p_commit,
															 x_return_status => x_return_status,
															 x_msg_count => x_msg_count,
															 x_msg_data => x_msg_data,
															 p_payee => p_payee,
															 p_assignment_attribs => p_assignment_attribs,
															 x_assign_id => l_assign_id,
															 x_response => x_response );
      COMMIT;
      print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT X_ASSIGN_ID = ' || l_assign_id, p_force=>true);
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
    IF r_sup_bank.account_id               IS NULL OR r_sup_bank.account_id=-1
	THEN
      x_bank_branch_rec.currency           :=NVL(r_sup_bank.currency_code,'USD');
      x_bank_branch_rec.branch_id          :=r_sup_bank.branch_id;
      x_bank_branch_rec.bank_id            :=r_sup_bank.bank_id;
      x_bank_branch_rec.acct_owner_party_id:=lv_acct_owner_party_id;
      x_bank_branch_rec.country_code       :=r_sup_bank.country_code;
      x_bank_branch_rec.bank_account_name  := r_sup_bank.bank_account_name;
      x_bank_branch_rec.bank_account_num   :=r_sup_bank.bank_account_num;
      x_bank_branch_rec.acct_type          := 'Supplier';

      fnd_msg_pub.initialize; --to make msg_count 0
      x_return_status:=NULL;
      x_msg_count    :=NULL;
      x_msg_data     :=NULL;
      x_response     :=NULL;
      iby_ext_bankacct_pub.create_ext_bank_acct ( p_api_version => 1.0,
	                                              p_init_msg_list => fnd_api.g_true,
												  p_ext_bank_acct_rec => x_bank_branch_rec,
												  p_association_level => 'SS',
												  p_supplier_site_id => lv_supp_site_id,
												  p_party_site_id => lv_supp_party_site_id,
												  p_org_id => lv_org_id,
												  p_org_type => 'OPERATING_UNIT',
												  x_acct_id => l_account_id,
												  x_return_status => x_return_status,
												  x_msg_count => x_msg_count,
												  x_msg_data =>x_msg_data,
												  x_response => x_response );
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
          print_debug_msg(p_message=> gc_step||'Organization Type : '||l_organization_type||' does not exist in the system' ,p_force=> false);
		  gc_error_msg:='Organization Type : '||l_organization_type||' does not exist in the system';
        ELSE
          print_debug_msg(p_message=> gc_step||' Organization Type Code of Organization Type - '||l_supplier_type(l_sup_idx).organization_type||' is '||l_org_type_code ,p_force=> false);
          l_supplier_type(l_sup_idx).organization_type := l_org_type_code;
        END IF; -- IF l_org_type_code IS NULL
        --==============================================================
        -- Validating the SUPPLIER NAME
        --==============================================================
        IF l_supplier_type (l_sup_idx).supplier_name IS NULL THEN
          gc_error_status_flag                       := 'Y';
          print_debug_msg(p_message=> l_program_step||' Supplier Name Cannot be BLANK' ,p_force=> false);
		  gc_error_msg:=gc_error_msg||' , Supplier Name is BLANK ';
          l_supplier_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_process_status_error;
          l_supplier_type (l_sup_idx).ERROR_FLAG        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).ERROR_MSG         := 'Supplier Name Cannot be BLANK';
          -- Skip the validation of this iteration/this supplier
          CONTINUE;
        END IF;
        IF ((find_special_chars(l_supplier_type(l_sup_idx).supplier_name) = 'JUNK_CHARS_EXIST')) THEN
          gc_error_status_flag                                           := 'Y';
   	      gc_error_msg:=gc_error_msg||' , Supplier Name has junk characters';
          print_debug_msg(p_message=> l_program_step||' Supplier Name'||l_supplier_type(l_sup_idx).supplier_name||' has junk characters' ,p_force=> false);
        END IF;
        --==============================================================
        -- Validating the SUPPLIER number
        --==============================================================
        IF l_supplier_type (l_sup_idx).segment1 IS NULL THEN
          gc_error_status_flag                  := 'Y';
          print_debug_msg(p_message=> l_program_step||' Supplier number Cannot be BLANK'||l_sup_idx ,p_force=> true);
		  gc_error_msg:=gc_error_msg||' , Supplier Number is BLANK ';
          l_supplier_type (l_sup_idx).supp_PROCESS_FLAG := gn_process_status_error;
          l_supplier_type (l_sup_idx).ERROR_FLAG        := gc_process_error_flag;
          l_supplier_type (l_sup_idx).ERROR_MSG         := 'Supplier number Cannot be BLANK'||l_sup_idx;
          -- Skip the validation of this iteration/this supplier
          CONTINUE;
        END IF;
        --==============================================================
        -- Validating the Supplier - Tax Payer ID
        --==============================================================
        IF l_supplier_type(l_sup_idx).num_1099 IS NOT NULL THEN
          IF ( NOT (isnumeric(l_supplier_type(l_sup_idx).num_1099)) OR (LENGTH(l_supplier_type(l_sup_idx).num_1099) <> 9)) THEN
            gc_error_status_flag:= 'Y';
            print_debug_msg(p_message=> l_program_step||' ,'||l_supplier_type (l_sup_idx).num_1099||' - Tax Payer Id should be numeric and must have 9 digits ' ,p_force=> false);
			gc_error_msg:=gc_error_msg||' , Tax Payer Id should be numeric and must have 9 digits';
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
          print_debug_msg(p_message=> l_program_step||' Supplier Name '||l_supplier_type (l_sup_idx).supplier_name||' does not exist. So, create it after checking interface table.' ,p_force=> false);
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
            print_debug_msg(p_message=> l_program_step||' Supplier Name '||l_supplier_type (l_sup_idx).supplier_name||' in interface does not exist. So, create it.' ,p_force=> false);
          ELSE
            gc_error_status_flag := 'Y';
            print_debug_msg(p_message=> l_program_step||' Supplier '||l_supplier_type (l_sup_idx).supplier_name||' already exists in Interface table with segment1 as '||l_int_segment1||' .' ,p_force=> true);
			gc_error_msg:=gc_error_msg||' ,	Supplier '||l_supplier_type (l_sup_idx).supplier_name||' already exists in the Interface table : '||l_int_segment1;
          END IF;
        ELSIF ( (l_sup_name                              =l_supplier_type (l_sup_idx).supplier_name)) THEN
          l_supplier_type (l_sup_idx).CREATE_FLAG       := 'N';--Update
          l_supplier_type (l_sup_idx).supp_process_flag := gn_process_status_validated;
          l_supplier_type (l_sup_idx).vendor_id         := l_vendor_id;
          l_supplier_type (l_sup_idx).party_id          := l_party_id;
          l_supplier_type (l_sup_idx).object_version_no := l_obj_ver_no;
          print_debug_msg(p_message=> l_program_step||' : Imported Segment1 - '||l_supplier_type (l_sup_idx).segment1 ||' and System segment are equal, so update this Supplier.' ,p_force=> false);
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
          print_debug_msg(p_message=> gc_step||l_supplier_type (l_sup_idx).vendor_type_lookup_code||' Supplier Type cannot be BLANK' ,p_force=> true);
		  gc_error_msg:=gc_error_msg||' , Supplier Type is BLANK';
        ELSE -- Derive the Supplier Type Code
          l_sup_type_code := NULL;
          OPEN c_sup_type_code(l_supplier_type (l_sup_idx).vendor_type_lookup_code);
          FETCH c_sup_type_code INTO l_sup_type_code;
          CLOSE c_sup_type_code;
          IF l_sup_type_code IS NULL THEN
            gc_error_status_flag := 'Y';
            print_debug_msg(p_message=> gc_step||l_supplier_type (l_sup_idx).vendor_type_lookup_code||'Invalid Supplier Type' ,p_force=> false);
			gc_error_msg:=gc_error_msg||' , '||l_supplier_type (l_sup_idx).vendor_type_lookup_code||' Invalid Supplier Type';
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
            print_debug_msg(p_message=> gc_step||l_supplier_type (l_sup_idx).customer_num||' Customer Number should be Numeric' ,p_force=> true);
			gc_error_msg:=gc_error_msg||' , '||l_supplier_type (l_sup_idx).customer_num||' Customer Number should be Numeric';
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

--+============================================================================+
--| Name          : validate_supplie_site_records                              |
--| Description   : This procedure will validate  supplier sites details using |
--|                 valdiation                                                 |
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
  -- Cursor Declarations to get the Site Email Address
  --==========================================================================================
  CURSOR c_sup_site_email (c_supplier_number  VARCHAR2,
                           c_vendor_site_code VARCHAR2)
  IS
    SELECT site_email_address
      FROM xx_ap_cld_site_dff_stg
     WHERE 1 = 1
       AND request_id       = gn_request_id
       AND TRIM(supplier_number) = TRIM(c_supplier_number)
       AND TRIM(vendor_site_code) = TRIM(c_vendor_site_code) ;
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
  --=================================================================
  -- Cursor Declarations for Tolerance mapping from Cloud to EBS
  --=================================================================
  CURSOR c_get_tolerance_name(c_cloud_tolerance VARCHAR2)
  IS
    SELECT LTRIM(RTRIM(tv.target_value1))
      FROM xx_fin_translatevalues tv,
           xx_fin_translatedefinition td
     WHERE tv.translate_id  = td.translate_id
       AND translation_name = 'XX_AP_CLOUD_TOLERANCES'
	   AND SYSDATE BETWEEN NVL(tv.start_date_active,SYSDATE) AND NVL(tv.end_date_active,SYSDATE + 1)
       AND SYSDATE BETWEEN NVL(td.start_date_active,SYSDATE) AND NVL(td.end_date_active,SYSDATE + 1)
	   AND tv.source_value1 = c_cloud_tolerance
       AND tv.enabled_flag = 'Y'
       AND td.enabled_flag = 'Y';
  --=================================================================
  -- Cursor Declarations for FOB mapping from Cloud to EBS
  --=================================================================
  CURSOR c_get_fob_value(c_cloud_fob VARCHAR2)
  IS
    SELECT LTRIM(RTRIM(tv.target_value1))
      FROM xx_fin_translatevalues tv,
           xx_fin_translatedefinition td
     WHERE tv.translate_id  = td.translate_id
       AND translation_name = 'XX_AP_CLOUD_FOB_VALUES'
	   AND SYSDATE BETWEEN NVL(tv.start_date_active,SYSDATE) AND NVL(tv.end_date_active,SYSDATE + 1)
       AND SYSDATE BETWEEN NVL(td.start_date_active,SYSDATE) AND NVL(td.end_date_active,SYSDATE + 1)
	   AND tv.source_value1 = c_cloud_fob
       AND tv.enabled_flag = 'Y'
       AND td.enabled_flag = 'Y';

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
  l_service_tolerance_cnt     NUMBER :=0;
  ln_terms_id				  NUMBER;
  lc_fob_value                VARCHAR2(100);
  lc_site_email_address       VARCHAR2(100):= NULL;
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
           error_msg            ='Supplier No / Supplier Name does not exists in AP Suppliers'
     WHERE site_process_flag=gn_process_status_inprocess
       AND request_id         =gn_request_id
       AND NOT EXISTS  (SELECT 1
						  FROM ap_suppliers apsup
						 WHERE UPPER(apsup.vendor_name)=UPPER(xasc.supplier_name)
						   AND apsup.segment1            =xasc.supplier_number
					   );
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
           xassc1.ERROR_MSG           = ERROR_MSG||',ERROR: Duplicate Site in Staging Table',
		   xassc1.process_flag		  = 'Y'
    WHERE xassc1.site_process_flag = gn_process_status_inprocess
      AND xassc1.REQUEST_ID          = gn_request_id
      AND 2 <= (SELECT COUNT(1)
				  FROM XX_AP_CLD_SUPP_SITES_STG xassc2
				 WHERE XASSC2.SITE_PROCESS_FLAG          IN (GN_PROCESS_STATUS_INPROCESS)
				   AND xassc2.REQUEST_ID                    = gn_request_id
				   AND trim(upper(xassc2.supplier_name))    = trim(upper(xassc1.supplier_name))
				   AND trim(upper(xassc2.supplier_number))  = trim(upper(xassc1.supplier_number))
				   AND TRIM(UPPER(XASSC2.VENDOR_SITE_CODE)) = TRIM(UPPER(XASSC1.VENDOR_SITE_CODE))
				   AND xassc2.org_id                        =xassc1.org_id
			   );
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
    gc_error_site_status_flag := 'N';
    gc_step                   := 'SITE';
    gc_error_msg              := '';
	ln_terms_id				  :=NULL;
    ln_vendor_site_id         := NULL;

    print_debug_msg(p_message=>'Supplier No/Name/Site : '||UPPER(l_sup_site_type.supplier_number)||'/'||
														   UPPER(l_sup_site_type.supplier_name)||'/'||
														   UPPER(l_sup_site_type.vendor_site_code),
					p_force=> false
				   );
    SELECT COUNT(1)
      INTO ln_cnt
      FROM ap_supplier_sites_int xasi
     WHERE xasi.status            ='NEW'
       AND UPPER(vendor_site_code)  = TRIM(UPPER(l_sup_site_type.vendor_site_code))
       AND xasi.vendor_id           =l_sup_site_type.supp_id
       AND TO_CHAR(xasi.org_id)     =L_SUP_SITE_TYPE.ORG_ID;
    IF ln_cnt <>0 THEN
       gc_error_site_status_flag := 'Y';
       print_debug_msg(p_message=> 'Supplier Site ' ||l_sup_site_type.vendor_site_code ||' already exist in Interface table' ,p_force=> true);
	   gc_error_msg:='Supplier Site ' ||l_sup_site_type.vendor_site_code ||' already exist in Interface table';
    END IF;
	--==============================================================================================================
    -- Get the Site Email Address
    --==============================================================================================================
    lc_site_email_address := NULL;
    OPEN  c_sup_site_email(l_sup_site_type.supplier_number,l_sup_site_type.vendor_site_code);
    FETCH c_sup_site_email INTO lc_site_email_address;
    CLOSE c_sup_site_email;
    print_debug_msg(p_message=>'Supplier Site Email Address : '||lc_site_email_address ,p_force=> false);

	l_sup_site_and_add (l_sup_site_idx).site_email_address := lc_site_email_address;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  Address Line 1
    --==============================================================================================================
    IF l_sup_site_type.address_line1 IS NULL THEN
      gc_error_site_status_flag      := 'Y';
      print_debug_msg(p_message=> 'Vendor Site Address Line 1 is BLANK' ,p_force=> false);
	  gc_error_msg:=gc_error_msg||' , Vendor Site Address Line 1 is BLANK';
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  City
    --==============================================================================================================
    IF l_sup_site_type.city     IS NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> 'Vendor Site Address City is BLANK' ,p_force=> false);
      gc_error_msg:=gc_error_msg||' , Vendor Site Address City is BLANK';
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Country
    --==============================================================================================================
    l_site_country_code := NULL;
    OPEN c_get_country_code(NVL(l_sup_site_type.country,gc_site_country_code));
    FETCH c_get_country_code INTO l_site_country_code;
    CLOSE c_get_country_code;
    print_debug_msg(p_message=>'Country code : '||l_site_country_code ,p_force=> false);
    IF l_site_country_code                        IS NOT NULL THEN
      l_sup_site_and_add (l_sup_site_idx).country := l_site_country_code;
    ELSE
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> l_sup_site_type.country||'Invalid Country' ,p_force=> false);
      gc_error_msg:=gc_error_msg||' ,Invalid Country';
    END IF; -- IF l_site_country_code IS NOT NULL
    --==============================================================================================================
    -- Validating the Supplier Site - Address Details -  State for US Country     and Province for Canada
    --==============================================================================================================
    ---- commented and to be confirmed once data starts flowing
    IF l_site_country_code         = 'US' THEN
      IF l_sup_site_type.state    IS NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> 'Vendor Site Address State is BLANK' ,p_force=> false);
		gc_error_msg:=gc_error_msg||' ,Vendor Site Address State is BLANK';
      ELSIF l_sup_site_type.province IS NOT NULL THEN
        gc_error_site_status_flag    := 'Y';
        print_debug_msg(p_message=> 'Vendor Site US Address has value for PROVINCE' ,p_force=> false);
        gc_error_msg:=gc_error_msg||' , Vendor Site US Address has value for PROVINCE';
      END IF; -- IF l_sup_site_type.STATE IS NULL   -- ??? Do we need to validate the State Code in Oracle Seeded table
    ELSIF l_site_country_code      = 'CA' THEN
      IF l_sup_site_type.province IS NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> 'Vendor Site CA Address Province is BLANK',p_force=> false);
        gc_error_msg:=gc_error_msg||' ,Vendor Site CA Address Province is BLANK';
      ELSIF l_sup_site_type.state IS NOT NULL THEN
        gc_error_site_status_flag := 'Y';
        print_debug_msg(p_message=> 'Vendor Site CA Address has value for STATE',p_force=> false);
        gc_error_msg:=gc_error_msg||' ,Vendor Site CA Address has value for STATE';
      END IF; -- IF l_sup_site_type.PROVINCE IS NULL
    ELSE
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> 'Invalid Country ',p_force=> false);
    END IF;
    --==============================================================================================================
    -- Validating the Supplier Site - Operating Unit
    --==============================================================================================================
    ---Added by priyam as Org id is mandatory column for Site as well
    IF l_sup_site_type.org_id   IS NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message=> 'Org Id : '|| l_sup_site_type.org_id||' is BLANK',p_force=> true);
      gc_error_msg:=gc_error_msg||' , Org ID is BLANK';
    END IF;
    l_sup_create_flag           :=NULL;
    IF gc_error_site_status_flag = 'N' THEN
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
    print_debug_msg(p_message=> 'After supplier site existence check Error Status/Create Flag : '||gc_error_site_status_flag||'/'||
							     l_sup_create_flag,
					p_force=> false
				   );
    --==============================================================================================================
    -- Validating the Supplier Site - PostalCode Rename Postal to Area
    --==============================================================================================================
    IF l_sup_site_type.postal_code IS NULL THEN
        gc_error_site_status_flag    := 'Y';
        print_debug_msg(p_message=> 'Postal Code is BLANK' ,p_force=> false);
        gc_error_msg:=gc_error_msg||' , Postal Code is BLANK';
    ELSE
        IF l_site_country_code = 'US' THEN
          IF (NOT (ispostalcode(l_sup_site_type.postal_code )) OR (LENGTH(l_sup_site_type.postal_code) > 10 )) THEN
            gc_error_site_status_flag:= 'Y';
            print_debug_msg(p_message=> l_sup_site_type.postal_code ||' Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10' ,p_force=> false);
			gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.postal_code ||' Postal Code - should contain only numeric and hypen(-) and length must be maximum upto 10';
          END IF; -- IF (NOT (isPostalCode(l_sup_site_type.POSTAL_CODE))
        ELSIF l_site_country_code = 'CA' THEN
          IF (NOT (isalphanumeric(l_sup_site_type.postal_code ))) THEN
            gc_error_site_status_flag := 'Y';
            print_debug_msg(p_message=> l_sup_site_type.postal_code||' Postal Code - should contain only alphanumeric ' ,p_force=> false);
            gc_error_msg:=gc_error_msg||' , '|| l_sup_site_type.postal_code||' Postal Code - should contain only alphanumeric';
          END IF; -- IF l_sup_site_type.PROVINCE IS NULL      -- ??? Do we need to validate the State Code in Oracle Seeded table
        ELSE
          gc_error_site_status_flag := 'Y';
          print_debug_msg(p_message=> l_sup_site_type.country||' Vendor Site Country is Invalid' ,p_force=> false);
        END IF; -- IF IF l_sup_site_type.COUNTRY_CODE = 'US'
    END IF;   -- IF l_sup_site_type.POSTAL_CODE IS NULL

      --=============================================================================
      -- Validating the Supplier Site Category
      --=============================================================================

      IF l_sup_site_type.attribute8 IS NULL THEN
         gc_error_site_status_flag := 'Y';
         print_debug_msg(p_message=> 'Site Category is BLANK' ,p_force=> true);
   	     gc_error_msg:=gc_error_msg||' , Site Category is BLANK';
      END IF;

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
          print_debug_msg(p_message=> l_sup_site_type.ship_to_location||' Invalid Ship to Location' ,p_force=> true);
		  gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.ship_to_location||' Invalid Ship to Location';
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
          print_debug_msg(p_message=> l_sup_site_type.bill_to_location||' Invalid Bill to Location' ,p_force=> true);
		  gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.bill_to_location||' Invalid Bill to Location';
        END IF; -- IF l_ship_to_location_id IS NULL
      END IF;
      --=============================================================================
      -- Validating Terms
      --=============================================================================

	  IF l_sup_site_type.terms_name IS NOT NULL
	  THEN
	       OPEN c_get_term_id(xx_get_terms(l_sup_site_type.terms_name));
           FETCH c_get_term_id INTO ln_terms_id;
           CLOSE c_get_term_id;

         IF NVL(ln_terms_id,0) = 0
		 THEN
            gc_error_site_status_flag := 'Y';
            print_debug_msg(p_message=> l_sup_site_type.terms_name||' Invalid  Terms' ,p_force=> true);
			gc_error_msg:=gc_error_msg||' ,'|| l_sup_site_type.terms_name||' Invalid  Terms';
         END IF;
      END IF;

      --=============================================================================
      -- Validating the Supplier Site - FOB Lookup value
      --=============================================================================
      l_fob_code_cnt                     := NULL;
      IF l_sup_site_type.fob_lookup_code IS NOT NULL
	  THEN -- Derive the FOB Code
         l_fob_code_cnt                   := 0;

	     IF l_sup_site_type.fob_lookup_code = 'ORIGIN'
		   THEN
		       lc_fob_value := 'SHIPPING';
		 ELSIF l_sup_site_type.fob_lookup_code = 'DESTINATION'
		   THEN
		       lc_fob_value := 'RECEIVING';
		 ELSE
		       lc_fob_value := l_sup_site_type.fob_lookup_code;
		 END IF;

         OPEN c_get_fnd_lookup_code_cnt('FOB', lc_fob_value);
         FETCH c_get_fnd_lookup_code_cnt INTO l_fob_code_cnt;
         CLOSE c_get_fnd_lookup_code_cnt;
         IF l_fob_code_cnt            =0
		 THEN
            gc_error_site_status_flag := 'Y';
            print_debug_msg(p_message=> l_sup_site_type.fob_lookup_code||' Invalid FOB ' ,p_force=> true);
		    gc_error_msg:=gc_error_msg||' ,'|| l_sup_site_type.fob_lookup_code||' Invalid FOB';
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
          print_debug_msg(p_message=> l_sup_site_type.freight_terms_lookup_code||' Invalid Freight Terms' ,p_force=> true);
		  gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.freight_terms_lookup_code||' Invalid Freight Terms';
        END IF; -- IF l_freight_terms_code IS NULL
      END IF;   -- IF l_sup_site_type.FREIGHT_TERMS IS NOT NULL
      --==============================================================================================================
      -- Validating the Supplier Site - Payment Method Check again priyam
      --==============================================================================================================
      IF l_sup_site_type.payment_method_lookup_code IS NOT NULL THEN
         l_pay_method_cnt := 0;
          OPEN c_pay_method_exist(l_sup_site_type.payment_method_lookup_code);
         FETCH c_pay_method_exist INTO l_pay_method_cnt;
         CLOSE c_pay_method_exist;
         IF l_pay_method_cnt          = 0 THEN
            gc_error_site_status_flag := 'Y';
            print_debug_msg(p_message=> l_sup_site_type.payment_method_lookup_code||' Invalid Payment Method' ,p_force=> true);
		    gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.payment_method_lookup_code||' Invalid Payment Method';
         END IF; -- IF l_pay_method_cnt < 1
      END IF;   -- IF l_sup_site_type.PAYMENT_METHOD IS NULL

       --=============================================================================
      -- Validating the Supplier Site - Service Tolerance
      --=============================================================================
      IF l_sup_site_type.service_tolerance IS NOT NULL
	  THEN
        l_service_tolerance_cnt := 0;

		OPEN c_get_tolerance_name(l_sup_site_type.service_tolerance);
		FETCH c_get_tolerance_name INTO l_service_tolerance_name;
        CLOSE c_get_tolerance_name;

        OPEN c_get_tolerance(l_service_tolerance_name);
        FETCH c_get_tolerance INTO l_service_tolerance_cnt;
        CLOSE c_get_tolerance;
        IF l_service_tolerance_cnt = 0
		THEN
           gc_error_site_status_flag := 'Y';
           print_debug_msg(p_message=>  l_sup_site_type.service_tolerance||' Invalid Service Tolerance' ,p_force=> true);
		   gc_error_msg:=gc_error_msg||' ,'||  l_sup_site_type.service_tolerance|| ' Invalid Service Tolerance';
        END IF; -- IF l_service_tolerance_id IS NULL
	  END IF;
      --=============================================================================
      -- Validating the Supplier Site - Invoice Tolerance
      --=============================================================================
      IF l_sup_site_type.tolerance_name IS NOT NULL
	  THEN
        l_tolerance_cnt := 0;

		OPEN c_get_tolerance_name(l_sup_site_type.tolerance_name);
		FETCH c_get_tolerance_name INTO l_tolerance_name;
        CLOSE c_get_tolerance_name;

        OPEN c_get_tolerance(l_tolerance_name);
        FETCH c_get_tolerance INTO l_tolerance_cnt;
        CLOSE c_get_tolerance;
        IF l_tolerance_cnt =0
		THEN
           gc_error_site_status_flag := 'Y';
           print_debug_msg(p_message=>  l_sup_site_type.tolerance_name||' Invalid Quantity Tolerance' ,p_force=> true);
		   gc_error_msg:=gc_error_msg||' ,'|| l_sup_site_type.tolerance_name||' Invalid Quantity Tolerance';
        END IF; -- IF l_tolerance_id IS NULL
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
          print_debug_msg(p_message=> l_sup_site_type.pay_group_lookup_code||' Invalid Paygroup' ,p_force=> true);
		  gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.pay_group_lookup_code||' Invalid Paygroup';
        END IF;
      END IF; -- IF l_pay_group_code IS NULL

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
          print_debug_msg(p_message=> l_sup_site_type.terms_date_basis||' Invalid Terms Date Basis' ,p_force=> true);
          gc_error_msg:=gc_error_msg||' ,'||l_sup_site_type.terms_date_basis||' Invalid Terms Date Basis';
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
    END IF;
	print_debug_msg(p_message=> 'After validation, Site Process Flag : ' || l_sup_site_and_add(l_sup_site_idx).site_process_flag);

  END LOOP; --  FOR l_sup_site_type IN c_supplier_site
  --============================================================================
  -- For Doing the Bulk Update
  --============================================================================

  print_debug_msg(p_message=> 'Bulk Update Site Records : '||l_sup_site_and_add.count ,p_force=> true);

  IF l_sup_site_and_add.count > 0 THEN
    BEGIN
      FORALL l_idxs IN l_sup_site_and_add.FIRST .. l_sup_site_and_add.LAST
      UPDATE xx_ap_cld_supp_sites_stg
      SET site_process_flag = l_sup_site_and_add(l_idxs).site_process_flag ,
        error_flag          = l_sup_site_and_add(l_idxs).error_flag ,
        error_msg           = l_sup_site_and_add(l_idxs).error_msg,
        create_flag         =l_sup_site_and_add(l_idxs).create_flag,
        last_updated_by     =g_user_id,
        last_update_date    =SYSDATE,
        vendor_id           =l_sup_site_and_add(l_idxs).vendor_id,
        vendor_site_id      =l_sup_site_and_add (l_idxs).vendor_site_id,
		terms_id	        =l_sup_site_and_add (l_idxs).terms_id ,
		site_email_address  = l_sup_site_and_add (l_idxs).site_email_address
      WHERE 1               =1
      AND vendor_site_code  =l_sup_site_and_add(l_idxs).vendor_site_code
      AND supplier_number   = l_sup_site_and_add(l_idxs).supplier_number
      AND request_id        = gn_request_id;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
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
/*  Since API will be used for creation of contact
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
*/
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
    AND ass.vendor_site_id                   = c_vendor_site_id;
    --AND TRIM(UPPER(person.person_first_name))= TRIM(UPPER(c_first_name))
    --AND TRIM(UPPER(person.person_last_name)) = TRIM(UPPER(c_last_name));
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
      xassc1.ERROR_MSG               = 'ERROR: Duplicate Contact in Staging Table',
	  xassc1.process_flag            = 'Y'
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
      xassc.error_msg              = error_msg||',All Contact Values are null',
	  xassc.process_flag           = 'Y'
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
  --=======================================================
  -- Check if Supplier Sites does not exist in the System
  --=======================================================
  BEGIN
  l_site_upd_cnt := 0;
  UPDATE xx_ap_cld_supp_contact_stg A
     SET A.contact_process_flag   = 3 ,
         A.error_flag             = 'Y' ,
         A.error_msg              = error_msg||',Supplier Site does not exist in the System',
	     A.process_flag		      = 'Y'
   WHERE REQUEST_ID = gn_request_id
     AND contact_process_flag = gn_process_status_inprocess
     AND NOT EXISTS ( SELECT 1
                        FROM AP_SUPPLIER_SITES_ALL SS,
                             AP_SUPPLIERS S
                       WHERE S.SEGMENT1 = A.SUPPLIER_NUMBER
                         AND SS.VENDOR_ID = S.VENDOR_ID
                         AND SS.VENDOR_SITE_CODE = A.VENDOR_SITE_CODE);
   l_site_upd_cnt                   := SQL%ROWCOUNT;
   IF l_site_upd_cnt > 0 THEN
      print_debug_msg(p_message => 'Updated the contact Process Flag to Error for '||l_site_upd_cnt||' records as Supplier Site does not exist', p_force => FALSE);
    END IF;
  END;
  COMMIT;
  --====================================================================
  -- Call the Vendor Site Validations
  --====================================================================
  print_debug_msg(p_message=> 'Validation of Contact started' ,p_force=> TRUE);
  FOR l_sup_site_cont_type IN c_supplier_contact
  LOOP
    l_sup_cont_idx := l_sup_cont_idx + 1;
    gc_error_site_status_flag := 'N';
    gc_step                   := 'SITE_CONT';
	gc_error_msg		      := NULL;
    gc_error_msg              := '';
	l_sup_create_flag         :=NULL;

    print_debug_msg(p_message=> 'Supplier/Site/Contact : '||l_sup_site_cont_type.supplier_number||'/'||
							     UPPER(l_sup_site_cont_type.supplier_name)||'/'||
								 l_sup_site_cont_type.vendor_site_code||'/'||
								 l_sup_site_cont_type.first_name||'/'||l_sup_site_cont_type.last_name
					, p_force => FALSE
				   );
    /*
    OPEN c_dup_supplier_chk_int( TRIM(UPPER(l_sup_site_cont_type.first_name)), TRIM(UPPER(l_sup_site_cont_type.last_name)), l_sup_site_cont_type.supp_id, l_sup_site_cont_type.supp_site_id );
    FETCH c_dup_supplier_chk_int INTO l_int_first_name, l_int_last_name;
    CLOSE c_dup_supplier_chk_int;
    IF l_int_first_name         IS NOT NULL THEN
      gc_error_site_status_flag := 'Y';
      print_debug_msg(p_message => 'Contact already exist in the Interface table' , p_force => TRUE);
	  gc_error_msg:='Contact already exist in the Interface table';
    END IF;
	*/
    --====================================================================
    -- Note Required
    --====================================================================
    IF l_sup_site_cont_type.first_name IS NULL THEN
      gc_error_site_status_flag        := 'Y';
      print_debug_msg(p_message => 'Contact First Name is BLANK', p_force => FALSE);
      gc_error_msg:=gc_error_msg||' , Contact First Name is BLANK';
    END IF;
    IF l_sup_site_cont_type.last_name IS NULL THEN
      gc_error_site_status_flag       := 'Y';
      print_debug_msg(p_message=> 'Contact Last Name is BLANK' , p_force=> FALSE);
      gc_error_msg:=gc_error_msg||' , Contact Last Name is BLANK';
    END IF;
    IF gc_error_site_status_flag = 'N' THEN
      l_sup_cont_exist_cnt := 0;
      OPEN c_sup_contact_exist( l_sup_site_cont_type.supp_id, l_sup_site_cont_type.supp_site_id, l_sup_site_cont_type.first_name, l_sup_site_cont_type.last_name );
      FETCH c_sup_contact_exist INTO l_sup_cont_exist_cnt;
      CLOSE c_sup_contact_exist;
      IF l_sup_cont_exist_cnt             > 0 THEN
         l_sup_create_flag := 'N';
      ELSE
         l_sup_create_flag := 'Y';
      END IF;
    END IF; -- gc_error_site_status_flag = 'N'
    print_debug_msg(p_message=>'Supplier site existence check status/Create Flag :'||gc_error_site_status_flag||'/'||l_sup_CREATE_FLAG
				    , p_force => FALSE);
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
    ELSE
      l_sup_cont(l_sup_cont_idx).contact_process_flag := gn_process_status_validated;
    END IF;
    print_debug_msg(p_message=>'Contact Process / Error Flag :'||l_sup_cont(l_sup_cont_idx).contact_process_flag||'/'||gc_error_site_status_flag);
  END LOOP; --  FOR l_sup_site_type IN c_supplier_contact

  print_debug_msg(p_message=> 'Bulk Update for all Contact Records :'|| l_sup_cont.COUNT , p_force => TRUE);

  IF l_sup_cont.COUNT > 0 THEN
    BEGIN
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
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> TRUE);
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of site staging table' || SQLCODE || ' - ' || SUBSTR (SQLERRM ,1 ,3800 );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message , p_force => TRUE);
    END;
  END IF;
  x_ret_code      := l_ret_code;
  x_return_status := l_return_status;
  x_err_buf       := l_err_buff;
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
    AND xas.request_id          = gn_request_id
	ORDER BY primary_flag DESC;
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
    lv_supp_site_id          := NULL;
    lv_supp_party_site_id    := NULL;
    lv_acct_owner_party_id   := NULL;
    lv_org_id                := NULL;
    p_assignment_attribs.priority := NULL;
    print_debug_msg(p_message=> l_program_step||'Inside Cursor', p_force=>true);
	print_debug_msg(p_message=> l_program_step||'Vendor Site : '||r_sup_bank.vendor_site_code, p_force=>true);
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
    WHEN OTHERS
	THEN
	     lv_supp_site_id          := NULL;
	     lv_supp_party_site_id    := NULL;
	     lv_acct_owner_party_id   := NULL;
	     lv_org_id                := NULL;
         print_debug_msg(p_message=> l_program_step||'Error- Get supp_site_id and supp_party_site_id' || SQLCODE || sqlerrm, p_force=>true);
    END;

	IF lv_supp_site_id IS NOT NULL
	THEN
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
        -- p_assignment_attribs.priority                := 1;
	    IF r_sup_bank.primary_flag = 'Y'
	    THEN
	          p_assignment_attribs.priority := 1;
	    END IF;
        p_assignment_attribs.start_date              := TO_DATE(r_sup_bank.start_date,'YYYY/MM/DD');
        IF r_sup_bank.end_date IS NOT NULL
	    THEN
	        p_assignment_attribs.end_date            := TO_DATE(r_sup_bank.end_date,'YYYY/MM/DD');
	    ELSE
	        p_assignment_attribs.end_date            := TO_DATE('4712/12/31','YYYY/MM/DD');
	    END IF;

        print_debug_msg(p_message=> l_program_step||'Primary Flag : '||r_sup_bank.primary_flag, p_force=>true);
	    print_debug_msg(p_message=> l_program_step||'Start Date : '||p_assignment_attribs.start_date, p_force=>true);
	    print_debug_msg(p_message=> l_program_step||'End Date : '||p_assignment_attribs.end_date, p_force=>true);
	    print_debug_msg(p_message=> l_program_step||'Priority : '||p_assignment_attribs.priority, p_force=>true);
        fnd_msg_pub.initialize; --to make msg_count 0
        x_return_status:=NULL;
        x_msg_count    :=NULL;
        x_msg_data     :=NULL;
        x_response     :=NULL;
        --------------------Call the API for instr assignment
	    print_debug_msg(p_message=> l_program_step||'Start of calling API Instr Assignment', p_force=>true);
        iby_disbursement_setup_pub.set_payee_instr_assignment (p_api_version => p_api_version,
	                                                           p_init_msg_list => p_init_msg_list,
														       p_commit => p_commit,
														       x_return_status => x_return_status,
														       x_msg_count => x_msg_count,
														       x_msg_data => x_msg_data,
														       p_payee => p_payee,
														       p_assignment_attribs => p_assignment_attribs,
														       x_assign_id => l_assign_id,
														       x_response => x_response );
        COMMIT;
	    print_debug_msg(p_message=> l_program_step||'End of calling API Instr Assignment', p_force=>true);
        print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT END_DATE X_ASSIGN_ID = ' || l_assign_id, p_force=>true);
        print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT END_DATE X_RETURN_STATUS = ' || x_return_status, p_force=>true);
        print_debug_msg(p_message=> l_program_step||'SET_PAYEE_INSTR_ASSIGNMENT END_DATE X_MSG_COUNT = ' || x_msg_count, p_force=>true);
        IF x_return_status = 'E' THEN
          print_debug_msg(p_message=> l_program_step||'x_return_status ' || x_return_status , p_force=>true);
          print_debug_msg(p_message=> l_program_step||'x_msg_data ' || x_msg_data , p_force=>true);
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
	ELSE
	    l_process_flag := 'E';
		l_msg := 'Unable to retrieve the Vendor Site Code';
	END IF; -- lv_supp_site_id IS NOT NULL
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
	-- AND b.branch_number=p_branch
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
    print_debug_msg(p_message => 'Check and udpate the staging table for the Duplicate bank', p_force => true);
    l_bank_upd_cnt := 0;
    UPDATE xx_ap_cld_supp_bnkact_stg xassc1
    SET xassc1.bnkact_process_flag   = gn_process_status_error ,
      xassc1.error_flag              = gc_process_error_flag ,
      xassc1.error_msg               = 'Duplicate bank Account'
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
    print_debug_msg(p_message => 'Check and updated '||l_bank_upd_cnt||' records as error in the staging table for the Duplicate Bank', p_force => true);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR EXCEPTION: Updating the Duplicate bank assignment in Staging table - '|| l_err_buff , p_force => true);
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
      ||' ,bank or branch information is BLANK'
    WHERE xassc.bnkact_process_flag IN (gn_process_status_inprocess)
    AND xassc.request_id             = gn_request_id
    AND ( xassc.bank_name           IS NULL
    OR xassc.branch_name            IS NULL ) ;
    l_bank_upd_cnt                  := sql%rowcount;
    print_debug_msg(p_message => 'After Bank or branch information is BLANK', p_force => true);
  EXCEPTION
  WHEN OTHERS THEN
    l_err_buff := SQLCODE || ' - '|| SUBSTR (sqlerrm,1,3500);
    print_debug_msg(p_message => 'ERROR-EXCEPTION: Bank or branch information is BLANK - '|| l_err_buff , p_force => true);
  END;
  --====================================================================
  -- Call the Bank Account Validations
  --====================================================================
  l_site_cnt_for_bank := 0;
  FOR l_sup_bank_type IN c_supplier_bank
  LOOP
    print_debug_msg(p_message=> 'Vendor Site Code :'||l_sup_bank_type.vendor_site_code , p_force=> true);
    print_debug_msg(p_message=> gc_step||' : Validation of Bank Assignment started' ,p_force=> true);
    l_sup_bank_idx      := l_sup_bank_idx      + 1;
    l_site_cnt_for_bank := l_site_cnt_for_bank + 1;
    print_debug_msg(p_message=> gc_step||' : l_sup_bank_idx - '||l_sup_bank_idx ,p_force=> true);
    gc_error_site_status_flag := 'N';
    gc_step                   := 'BANK_ASSI';
    gc_error_msg              := '';
	l_sup_bank_id             := NULL;
	l_sup_bank_branch_id      := NULL;

    --====================================================================
    -- Checking Required Columns validation
    --====================================================================
    IF l_sup_bank_type.supplier_name IS NULL
	THEN
      gc_error_site_status_flag      := 'Y';
      gc_error_msg                   :=gc_error_msg||' Supplier Name is NULL';
      print_debug_msg(p_message=> 'Supplier Name is BLANK' , p_force=> true);
      gc_error_msg:=gc_error_msg||' , Supplier Name is BLANK';
    END IF;
    IF l_sup_bank_type.supplier_num IS NULL
	THEN
      gc_error_site_status_flag     := 'Y';
      gc_error_msg                  :=gc_error_msg||', Supplier Number is BLANK';
      print_debug_msg(p_message=> 'Supplier Number is BLANK' , p_force=> true);
	END IF;

    IF l_sup_bank_type.vendor_site_code IS NULL
	THEN
      gc_error_site_status_flag         := 'Y';
      gc_error_msg                      :=gc_error_msg||', Vendor Site Code is BLANK';
	  print_debug_msg(p_message=> 'Vendor Site Code is BLANK' , p_force=> true);
    END IF;

	IF l_sup_bank_type.bank_account_name IS NULL
	THEN
      gc_error_site_status_flag         := 'Y';
      gc_error_msg                      :=gc_error_msg||', Bank Account Name is BLANK';
	  print_debug_msg(p_message=> 'Bank Account Name is BLANK' , p_force=> true);
    END IF;

	print_debug_msg(p_message=> 'Error Message :'||gc_error_msg , p_force=> true);

    --==============================================================================================================
    -- Validating the Supplier Bank - Address Details -  Address Line 2
    --==============================================================================================================
    print_debug_msg(p_message=> gc_step||' After basic validation of Contact - gc_error_site_status_flag is '||gc_error_site_status_flag ,p_force=> true);
    l_bank_create_flag          := '';
    IF gc_error_site_status_flag = 'N'
	THEN
      print_debug_msg(p_message=> gc_step||' l_sup_bank_type.update_flag is '||l_sup_bank_type.CREATE_FLAG ,p_force=> true);
      print_debug_msg(p_message=> gc_step||' upper(l_sup_bank_type.vendor_site_code) is '||upper(l_sup_bank_type.vendor_site_code) ,p_force=> true);
      OPEN c_bank_branch(l_sup_bank_type.bank_name, l_sup_bank_type.country_code,l_sup_bank_type.branch_name);
      FETCH c_bank_branch INTO l_sup_bank_id,l_sup_bank_branch_id;
      CLOSE c_bank_branch;
      IF ( l_sup_bank_id          IS NULL OR l_sup_bank_branch_id IS NULL ) THEN
        gc_error_site_status_flag := 'Y';
        gc_error_msg              :=gc_error_msg||', Bank OR Branch does not exist';
	    print_debug_msg(p_message=> 'Bank OR Branch does not exist' , p_force=> true);
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
		WHEN TOO_MANY_ROWS
		THEN
		    BEGIN
		    SELECT ext_bank_account_id
              INTO l_bank_account_id
              FROM iby_ext_bank_accounts
             WHERE bank_id       =l_sup_bank_id
               AND branch_id       =l_sup_bank_branch_id
               AND bank_account_num=l_sup_bank_type.bank_account_num
			   AND UPPER(SUBSTR(bank_account_type,1,2)) = 'SU'
               AND SYSDATE BETWEEN NVL(start_date,SYSDATE-1) AND NVL(end_date,SYSDATE+1);
               l_sup_bank_type.account_id :=l_bank_account_id;
			EXCEPTION
			WHEN OTHERS
			THEN
			    SELECT ext_bank_account_id
                  INTO l_bank_account_id
                  FROM iby_ext_bank_accounts
                 WHERE bank_id       = l_sup_bank_id
                   AND branch_id       = l_sup_bank_branch_id
                   AND bank_account_num= l_sup_bank_type.bank_account_num
				   AND (UPPER(SUBSTR(bank_account_type,1,2)) = 'SU' OR bank_account_type IS NULL)
                   AND SYSDATE BETWEEN NVL(start_date,SYSDATE-1) AND NVL(end_date,SYSDATE+1)
				   AND ROWNUM = 1;
				l_sup_bank_type.account_id :=l_bank_account_id;
			END;
        WHEN OTHERS
		THEN
          l_bank_account_id           :=-1;
          l_bank_create_flag          :='Y';--Insert for Bank
          l_sup_bank_type.create_flag :=l_bank_create_flag;
        END;

        IF NVL(l_bank_account_id,-1) > 0 THEN
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
      IF l_instrument_id    > 0
	  -- AND l_sup_bank_type.end_date IS NOT NULL
	  THEN
        l_bank_create_flag :='N';--Update for Bank assignment end Date
      ELSE
        l_bank_acct_start_date:=l_sup_bank_type.start_date;
      END IF;
      print_debug_msg(p_message=> gc_step||' After Bank Validation, Error Status Flag is : '||gc_error_site_status_flag ,p_force=> true);
      print_debug_msg(p_message=> gc_step||' After Bank Validation, Bank Create  Flag is : '||l_bank_create_flag ,p_force=> true);
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
    IF gc_error_site_status_flag                      = 'Y'
	THEN
      l_sup_bank(l_sup_bank_idx).bnkact_process_flag := gn_process_status_error;
      l_sup_bank(l_sup_bank_idx).ERROR_FLAG          := gc_process_error_flag;
      l_sup_bank(l_sup_bank_idx).ERROR_MSG           := gc_error_msg;
	  l_sup_bank(l_sup_bank_idx).vendor_id           := NULL;
      l_sup_bank(l_sup_bank_idx).vendor_site_id      := NULL;
      l_sup_bank(l_sup_bank_idx).instrument_uses_id  := NULL;
      l_sup_bank(l_sup_bank_idx).bank_id             := NULL;
      l_sup_bank(l_sup_bank_idx).branch_id           := NULL;
      l_sup_bank(l_sup_bank_idx).account_id          := NULL;

	  print_debug_msg(p_message=> 'bnkact_process_flag :'||l_sup_bank(l_sup_bank_idx).bnkact_process_flag , p_force=> true);
	  print_debug_msg(p_message=> 'error_flag :'||l_sup_bank(l_sup_bank_idx).error_flag , p_force=> true);
	  print_debug_msg(p_message=> 'error_msg :'||l_sup_bank(l_sup_bank_idx).error_msg , p_force=> true);
    ELSE
      l_sup_bank(l_sup_bank_idx).bnkact_process_flag := gn_process_status_validated;
      print_debug_msg(p_message=> 'Process Flag ' ||gn_process_status_validated, p_force=> true);
      print_debug_msg(p_message=> 'Bank Status Flag : '|| l_sup_bank(l_sup_bank_idx).bnkact_process_flag,p_force=> true);
    END IF;
  END LOOP;
  print_debug_msg(p_message=> 'Do Bulk Update for all BANK Records ' ,p_force=> true);
  print_debug_msg(p_message=> 'l_sup_bank.COUNT : '|| l_sup_bank.count ,p_force=> true);
  IF l_sup_bank.count > 0 THEN
    BEGIN
      FORALL l_idxs IN l_sup_bank.FIRST .. l_sup_bank.LAST
      UPDATE xx_ap_cld_supp_bnkact_stg
      SET bnkact_process_flag          = l_sup_bank(l_idxs).bnkact_process_flag ,
        error_flag                     = l_sup_bank(l_idxs).error_flag ,
        error_msg                      = l_sup_bank(l_idxs).error_msg,
        create_flag                    = l_sup_bank(l_idxs).create_flag,
        last_updated_by                = g_user_id,
        last_update_date               = SYSDATE,
        vendor_id                      = l_sup_bank(l_idxs).vendor_id,
        vendor_site_id                 = l_sup_bank(l_idxs).vendor_site_id,
        instrument_uses_id             = l_sup_bank(l_idxs).instrument_uses_id,
        bank_id                        = l_sup_bank(l_idxs).bank_id,
        branch_id                      = l_sup_bank(l_idxs).branch_id,
        account_id                     = l_sup_bank(l_idxs).account_id,
        start_date                     = l_sup_bank(l_idxs).start_date
      WHERE 1                          = 1
      AND TRIM(UPPER(vendor_site_code))= TRIM(UPPER(l_sup_bank(l_idxs).vendor_site_code))
      AND UPPER(supplier_num)          = UPPER(l_sup_bank(l_idxs).supplier_num)
      AND UPPER(bank_name)             = UPPER(l_sup_bank(l_idxs).bank_name)
      AND UPPER(BRANCH_NAME)           = UPPER(l_sup_bank(l_idxs).branch_name)
      AND bank_account_num             = l_sup_bank(l_idxs).bank_account_num
      AND request_id                   = gn_request_id;
      COMMIT;
    EXCEPTION
    WHEN OTHERS THEN
      l_error_message := 'When Others Exception  during the bulk update of Bank staging table' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3800 );
      insert_error (p_program_step => 'SITE_BANK' ,p_primary_key => NULL ,p_error_code => 'XXOD_BULK_UPD_SITE' ,p_error_message => 'When Others Exception during the bulk update of bank staging table' ,p_stage_col1 => NULL ,p_stage_val1 => NULL ,p_stage_col2 => NULL ,p_stage_val2 => NULL ,p_table_name => g_sup_bank_table );
      print_debug_msg(p_message=> l_program_step||': '||l_error_message ,p_force=> true);
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
--| Name          : load_Supplier_Interface                                    |
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
  lc_terms_name                          VARCHAR2(50):= 'N90'; -- Added as per Version 2.6
  ln_terms_id                            NUMBER;               -- Added as per Version 2.6
  lc_intf_ins_flag						 VARCHAR2(1):='N';
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
         d.message_text reject_lookup_code
    FROM fnd_new_messages d,
	     ap_supplier_int_rejections c,
         ap_suppliers_int b,
         xx_ap_cld_suppliers_stg a
   WHERE a.request_id=gn_request_id
     AND a.supp_process_flag=gn_process_status_validated
     AND a.create_flag='Y'
     AND b.vendor_interface_id=a.vendor_interface_id
	 AND b.status='REJECTED'
     AND c.parent_id=b.vendor_interface_id
     AND c.parent_table='AP_SUPPLIERS_INT'
	 AND d.message_name = c.reject_lookup_code;

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
		gc_error_msg 					 := NULL;
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

          /* Added as per Version 2.6 by Havish Kasina */
		  --====================
		  -- To get the terms
		  --====================
		  get_terms_id(p_terms_name  => lc_terms_name,
                       o_terms_id    => ln_terms_id);

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
				  end_date_active,
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
				  allow_unordered_receipts_flag,      -- Added as per Version 2.1 by Havish Kasina
				  terms_id                            -- Added as per Version 2.6 by Havish Kasina
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
				  NVL(TO_DATE(l_supplier_type (l_idx).end_date_active,'YYYY/MM/DD'),NULL),
                  g_user_id ,
                  SYSDATE ,
                  SYSDATE ,
                  g_user_id,
                  l_supplier_type (l_idx).organization_type,
				  lc_inspection_required_flag,	   -- Added as per Version 2.1 by Havish Kasina
				  lc_receipt_required_flag,	       -- Added as per Version 2.1 by Havish Kasina
				  ln_qty_rcv_tolerance,	           -- Added as per Version 2.1 by Havish Kasina
				  lc_qty_rcv_exception_code,       -- Added as per Version 2.1 by Havish Kasina
				  lc_enforce_ship_to_loc_code,     -- Added as per Version 2.1 by Havish Kasina
				  ln_days_early_receipt_allowed,   -- Added as per Version 2.1 by Havish Kasina
				  ln_days_late_receipt_allowed,	   -- Added as per Version 2.1 by Havish Kasina
				  lc_receipt_days_exception_code,  -- Added as per Version 2.1 by Havish Kasina
				  ln_receiving_routing_id,	       -- Added as per Version 2.1 by Havish Kasina
				  lc_allow_substitute_rcpts_flag,  -- Added as per Version 2.1 by Havish Kasina
				  lc_allow_unordered_rcpts_flag,   -- Added as per Version 2.1 by Havish Kasina
				  ln_terms_id                      -- Added as per Version 2.6 by Havish Kasina
                );
			  lc_intf_ins_flag:='Y';
              print_debug_msg(p_message=> 'After successfully inserted the record for the supplier -'||l_supplier_type (l_idx).supplier_name ,p_force=> false);
            EXCEPTION
            WHEN OTHERS THEN
              l_process_status_flag := 'Y';
              l_error_message       := SQLCODE || ' - '|| sqlerrm;
              print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'||l_supplier_type (l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '||l_error_message ,p_force=> true);
			  gc_error_msg:='Error while Inserting Records in AP Suppliers INT : '|| SQLCODE || ' - '||sqlerrm;
            END;
            IF l_process_status_flag                       = 'N' THEN
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

  IF lc_intf_ins_flag='Y' THEN
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
                 error_flag          ='Y',
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

--+=====================================================================================+
--| Name          : load_Supplier_Site_Interface                                        |
--| Description   : This procedure will load the vendors Sitee into interface table     |
--|                   for the validated records in staging table                        |
--|                                                                                     |
--| Parameters    : N/A                                                                 |
--|                                                                                     |
--| Returns       : N/A                                                                 |
--+=====================================================================================+
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

   --=================================================================
  -- Cursor Declarations for Tolerance mapping from Cloud to EBS
  --=================================================================
  CURSOR c_get_tolerance_name(c_cloud_tolerance VARCHAR2)
  IS
    SELECT LTRIM(RTRIM(tv.target_value1))
      FROM xx_fin_translatevalues tv,
           xx_fin_translatedefinition td
     WHERE tv.translate_id  = td.translate_id
       AND translation_name = 'XX_AP_CLOUD_TOLERANCES'
	   AND SYSDATE BETWEEN NVL(tv.start_date_active,SYSDATE) AND NVL(tv.end_date_active,SYSDATE + 1)
       AND SYSDATE BETWEEN NVL(td.start_date_active,SYSDATE) AND NVL(td.end_date_active,SYSDATE + 1)
	   AND tv.source_value1 = c_cloud_tolerance
       AND tv.enabled_flag = 'Y'
       AND td.enabled_flag = 'Y';

  CURSOR c_error
  IS
  SELECT a.rowid drowid,
         d.message_text reject_lookup_code
    FROM fnd_new_messages d,
	     ap_supplier_int_rejections c,
         ap_supplier_sites_int b,
         xx_ap_cld_supp_sites_stg a
   WHERE a.request_id=gn_request_id
     AND a.site_process_flag = gn_process_status_validated
     AND a.create_flag='Y'
     AND b.vendor_site_interface_id=a.vendor_site_interface_id
	 AND b.status='REJECTED'
     AND c.parent_id=b.vendor_site_interface_id
     AND c.parent_table='AP_SUPPLIER_SITES_INT'
	 AND d.message_name = c.reject_lookup_code;

  l_process_site_error_flag     VARCHAR2(1) DEFAULT 'N';
  l_vendor_id                   NUMBER;
  l_vendor_site_id              NUMBER;
  l_party_site_id               NUMBER;
  l_party_id                    NUMBER;
  l_vendor_site_code            VARCHAR2(50);
  v_acct_pay                    NUMBER;
  v_prepay_cde                  NUMBER;
  lc_intf_ins_flag			    VARCHAR2(1):='N';
  l_service_tolerance_name      VARCHAR2(100);
  l_qty_tolerance_name          VARCHAR2(100);
  lc_fob_value                  VARCHAR2(100);
BEGIN
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
		gc_error_msg			   := NULL;
		l_service_tolerance_name   := NULL;
		l_qty_tolerance_name       := NULL;
		lc_fob_value               := NULL;

        IF l_process_site_error_flag='N'
		THEN
          --==============================================================================
          -- Calling the Vendor Site Interface Id for Passing it to Interface Table
          --==============================================================================
          SELECT ap_supplier_sites_int_s.nextval
          INTO l_vendor_site_intf_id
          FROM sys.dual;
          v_acct_pay  := get_cc_id(l_sup_site_type(l_idx).accts_pay_concat_gl_segments);
          v_prepay_cde:= get_cc_id(l_sup_site_type(l_idx). prepay_code_gl_segments);

		  -- To get the Service Tolerance
		  OPEN c_get_tolerance_name(l_sup_site_type(l_idx).service_tolerance);
		  FETCH c_get_tolerance_name INTO l_service_tolerance_name;
          CLOSE c_get_tolerance_name;

		  -- To get the Quantity Tolerance
		  OPEN c_get_tolerance_name(l_sup_site_type(l_idx).tolerance_name);
		  FETCH c_get_tolerance_name INTO l_qty_tolerance_name;
          CLOSE c_get_tolerance_name;

		  -- To get the FOB Code
		  IF l_sup_site_type(l_idx).fob_lookup_code = 'ORIGIN'
		  THEN
		       lc_fob_value := 'SHIPPING';
		  ELSIF l_sup_site_type(l_idx).fob_lookup_code = 'DESTINATION'
		  THEN
		       lc_fob_value := 'RECEIVING';
		  ELSE
		       lc_fob_value := l_sup_site_type(l_idx).fob_lookup_code;
		  END IF;

          BEGIN
            INSERT
            INTO ap_supplier_sites_int
              (
                vendor_id ,
                vendor_site_interface_id ,
                vendor_site_code ,
                address_line1 ,
                address_line2 ,
				address_line3 ,   -- Added as per Version 2.2
                address_line4 ,   -- Added as per Version 2.2
				county,           -- Added as per Version 2.2
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
				rfq_only_site_flag,     -- Added as per Version 2.2
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
				supplier_notif_method,
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
                attribute7 ,
                attribute8 ,
                -- attribute9 , -- Commented for Legacy Supplier Number as per Version 3.4
                attribute10 ,
                attribute11 ,
                attribute12 ,
                attribute13 ,
                attribute14 ,
                attribute15,
                vendor_site_code_alt,
				duns_number,-- Added as per Version 1.9
				bank_charge_bearer,
				inactive_date,
				pcard_site_flag,               -- Added as per Version 3.0
				customer_num,                  -- Added as per Version 3.0
				ship_via_lookup_code,          -- Added as per Version 3.0
				invoice_amount_limit,          -- Added as per Version 3.0
				hold_future_payments_flag,     -- Added as per Version 3.0
				hold_unmatched_invoices_flag,  -- Added as per Version 3.0
				hold_reason,                   -- Added as per Version 3.0
				exclude_freight_from_discount, -- Added as per Version 3.0
				pay_on_code,                   -- Added as per Version 3.0
				pay_on_receipt_summary_code,   -- Added as per Version 3.0
				country_of_origin_code,        -- Added as per Version 3.0
				create_debit_memo_flag,        -- Added as per Version 3.0
				gapless_inv_num_flag,          -- Added as per Version 3.0
				selling_company_identifier,    -- Added as per Version 3.0
				vat_code,                      -- Added as per Version 3.0
				vat_registration_num,          -- Added as per Version 3.0
				remit_advice_delivery_method,  -- Added as per Version 3.0
				remittance_email,              -- Added as per Version 3.0
				language
              )
              VALUES
              (
                l_sup_site_type(l_idx).vendor_id,      ---l_supplier_type (l_idx).vendor_id ,
                l_vendor_site_intf_id ,                 --l_vendor_site_intf_id
                l_sup_site_type(l_idx).vendor_site_code,--address_line1 ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).address_line1))) ,
                ltrim(rtrim(upper(l_sup_site_type(l_idx).address_line2))) ,
                -- l_sup_site_type(l_idx).vendor_site_code,-- TO_CHAR(l_sup_site_type(l_idx).site_number) ,  -- Commented as per Version 2.2
				ltrim(rtrim(upper(l_sup_site_type(l_idx).address_line3))) ,  -- Added as per Version 2.2
				ltrim(rtrim(upper(l_sup_site_type(l_idx).address_line4))) ,  -- Added as per Version 2.2
				ltrim(rtrim(upper(l_sup_site_type(l_idx).county))) ,  -- Added as per Version 2.2
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
				l_sup_site_type(l_idx).rfq_only_site_flag,   -- Added as per Version 2.2
                l_sup_site_type(l_idx).pay_site_flag ,
                TO_NUMBER(l_sup_site_type(l_idx).org_id),
                g_process_status_new,
                l_sup_site_type(l_idx).freight_terms_lookup_code,--freight_terms ,
				lc_fob_value,                                    --fob ,
                l_sup_site_type(l_idx).pay_group_lookup_code,    --pay_group_code ,
                NVL(TO_NUMBER(l_sup_site_type(l_idx).payment_priority),99),
                l_sup_site_type(l_idx).pay_date_basis_lookup_code ,
                l_sup_site_type(l_idx).always_take_disc_flag ,
                l_sup_site_type(l_idx).hold_all_payments_flag,--hold_from_payment
                l_sup_site_type(l_idx).match_option,          --invoice_match_option ,
                l_sup_site_type(l_idx).site_email_address ,
				l_sup_site_type(l_idx).supplier_notif_method,  -- Added as per Version 2.3
                l_sup_site_type(l_idx).primary_pay_site_flag, --primary_pay_flag
                l_qty_tolerance_name,
                l_service_tolerance_name,
                UPPER(l_sup_site_type(l_idx).bill_to_location),
                UPPER(l_sup_site_type(l_idx).ship_to_location),
                g_user_id ,
                sysdate ,
                sysdate ,
                g_user_id ,
                NVL(l_sup_site_type(l_idx).payment_method_lookup_code,'CHECK'),
                l_sup_site_type(l_idx).attribute_category ,
                l_sup_site_type(l_idx).attribute1,
                l_sup_site_type(l_idx).attribute2,
                l_sup_site_type(l_idx).attribute3 ,
                l_sup_site_type(l_idx).attribute4 ,
                l_sup_site_type(l_idx).attribute5 ,
                l_sup_site_type(l_idx).attribute6 ,
                l_sup_site_type(l_idx).attribute7 ,
                l_sup_site_type(l_idx).attribute8 ,
                -- l_sup_site_type(l_idx).attribute9 , -- Commented for Legacy Supplier Number as per Version 3.4
                NULL ,
                NULL ,
                NULL ,
                l_sup_site_type(l_idx).attribute13 ,
                l_sup_site_type(l_idx).attribute14 ,
                L_SUP_SITE_TYPE(L_IDX).attribute15,
                l_sup_site_type(l_idx).vendor_site_code_alt,
                l_sup_site_type(l_idx).attribute5, -- Added as per Version 1.9
				NVL(l_sup_site_type(l_idx).bank_charge_bearer,'D'),
				NVL(TO_DATE(l_sup_site_type(l_idx).inactive_date,'YYYY/MM/DD'),NULL),
				l_sup_site_type(l_idx).pcard_site_flag,               -- Added as per Version 3.0
				l_sup_site_type(l_idx).customer_num,                  -- Added as per Version 3.0
				l_sup_site_type(l_idx).ship_via_lookup_code,          -- Added as per Version 3.0
				l_sup_site_type(l_idx).invoice_amount_limit,          -- Added as per Version 3.0
				l_sup_site_type(l_idx).hold_future_payments_flag,     -- Added as per Version 3.0
				l_sup_site_type(l_idx).hold_unmatched_invoices_flag,  -- Added as per Version 3.0
				l_sup_site_type(l_idx).hold_reason,                   -- Added as per Version 3.0
				l_sup_site_type(l_idx).exclude_freight_from_discount, -- Added as per Version 3.0
				l_sup_site_type(l_idx).pay_on_code,                   -- Added as per Version 3.0
				l_sup_site_type(l_idx).pay_on_receipt_summary_code,   -- Added as per Version 3.0
				l_sup_site_type(l_idx).country_of_origin_code,        -- Added as per Version 3.0
				l_sup_site_type(l_idx).create_debit_memo_flag,        -- Added as per Version 3.0
				l_sup_site_type(l_idx).gapless_inv_num_flag,          -- Added as per Version 3.0
				l_sup_site_type(l_idx).selling_company_identifier,    -- Added as per Version 3.0
				l_sup_site_type(l_idx).vat_code,                      -- Added as per Version 3.0
				l_sup_site_type(l_idx).vat_registration_num,          -- Added as per Version 3.0
				l_sup_site_type(l_idx).remit_advice_delivery_method,  -- Added as per Version 3.0
				l_sup_site_type(l_idx).remittance_email,              -- Added as per Version 3.0
				'AMERICAN'
              );
			  lc_intf_ins_flag:='Y';
          EXCEPTION
          WHEN OTHERS THEN
            l_process_site_error_flag := 'Y';
            l_error_message           := SQLCODE || ' - '|| sqlerrm;
            print_debug_msg(p_message=> gc_step||' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:' ||l_sup_site_type(l_idx).supplier_name||': XXOD_SUPPLIER_INS_ERROR:'|| SQLCODE || ' - '|| l_error_message ,p_force=> true);
			gc_error_msg:=gc_error_msg||' ,'||l_error_message;
          END;
          IF l_process_site_error_flag                 = 'N' THEN
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
        UPDATE  xx_ap_cld_supp_sites_stg
           SET  site_process_flag       = l_sup_site_type (l_idxss).site_process_flag,
                last_updated_by         = g_user_id,
				last_update_date        = sysdate,
				error_msg               = l_sup_site_type (l_idxss).error_msg,
				error_flag              = l_sup_site_type (l_idxss).error_flag,
				vendor_site_interface_id= l_sup_site_type (l_idxss).vendor_site_interface_id
         WHERE 1                   =1
           AND supplier_number       = l_sup_site_type (l_idxss).supplier_number
           AND vendor_site_code      = l_sup_site_type (l_idxss).vendor_site_code
           AND org_id                =l_sup_site_type (l_idxss).org_id
           AND request_id            = gn_request_id;
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
  IF lc_intf_ins_flag='Y' THEN
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
                process_flag        ='Y',
                vendor_site_id      = (SELECT vendor_site_id
										 FROM ap_supplier_sites_all b
										WHERE stg.vendor_id     =b.vendor_id
										  AND stg.vendor_site_code=b.vendor_site_code
										  AND b.org_id            =stg.org_id
										  AND ROWNUM             <=2
									  )
         WHERE 1=1
           AND EXISTS (SELECT 1
						 FROM ap_supplier_sites_int aint
						WHERE aint.vendor_site_code      = stg.vendor_site_code
						  AND aint.vendor_id               =stg.vendor_id
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
               error_flag          ='Y',
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
  l_error_message          	VARCHAR2 (2000) DEFAULT NULL;
  l_procedure              	VARCHAR2 (30) := 'load_Supplier_cont_Interface';
  l_ret_code               	NUMBER;
  l_return_status          	VARCHAR2 (100);
  l_err_buff               	VARCHAR2 (4000);
  l_user_id                	NUMBER ;
  l_resp_id                	NUMBER ;
  l_resp_appl_id           	NUMBER ;
  lc_error_mesg			   	VARCHAR2(2000);
  l_msg_data 				VARCHAR2(1000);
  l_vendor_contact_id 		NUMBER;
  l_per_party_id 			NUMBER;
  l_rel_party_id 			NUMBER;
  l_rel_id 					NUMBER;
  l_org_contact_id 			NUMBER;
  l_party_site_id 			NUMBER;
  ln_party_site_id 			NUMBER;

  l_vendor_contact_rec 	ap_vendor_pub_pkg.r_vendor_contact_rec_type;
  l_msg              	VARCHAR2(2000);
  ln_msg_index_num 		NUMBER;
  l_msg_count 			NUMBER;
  l_cont_process_error_flag VARCHAR2(1);
  l_vendor_id               NUMBER;
  l_vendor_site_id          NUMBER;
  l_org_id                  NUMBER;

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



BEGIN
  gc_step                   := 'SUPCONT';
  print_debug_msg(p_message=> gc_step||' load_Supplier_cont_Interface() - BEGIN' ,p_force=> false);
  set_step ('Start of Process Records Using API');
  --==============================================================================
  -- Default Process Status Flag as N means No Error Exists
  --==============================================================================

  l_error_message           := NULL;
  l_ret_code                := 0;
  l_return_status           := 'S';
  l_err_buff                := NULL;

  BEGIN
    SELECT user_id,
             responsibility_id,
             responsibility_application_id
      INTO  l_user_id,
             l_resp_id,
             l_resp_appl_id
      FROM  fnd_user_resp_groups
     WHERE user_id=(SELECT user_id
                      FROM fnd_user
                     WHERE user_name='ODCDH')
                       AND responsibility_id=(SELECT responsibility_id
                                                FROM FND_RESPONSIBILITY
                                               WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
    FND_GLOBAL.apps_initialize(l_user_id,l_resp_id,l_resp_appl_id);
  END;

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
        l_vendor_id               := NULL;
		l_vendor_site_id		  := NULL;
		ln_party_site_id		      := NULL;
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
                   ln_party_site_id
              FROM ap_supplier_sites_all
             WHERE vendor_site_id= l_supplier_cont_type (l_idx).vendor_site_id;
          EXCEPTION
            WHEN OTHERS THEN
              l_cont_process_error_flag:='Y';
          END;
          --==============================================================================
          -- Calling the API for Contact creation
          --==============================================================================
          IF l_cont_process_error_flag = 'N' THEN
             print_debug_msg(p_message=> gc_step||' - Before inserting record into AP_SUP_SITE_CONTACT_INT with vendor id -'|| l_vendor_id ,p_force=> false);

			 l_vendor_contact_rec.vendor_id			:= l_vendor_id;
			 l_vendor_contact_rec.vendor_site_id	:= l_vendor_site_id;
			 l_vendor_contact_rec.party_site_id 	:= ln_party_site_id;
			 l_vendor_contact_rec.person_first_name	:= UPPER(l_supplier_cont_type (l_idx).first_name);
			 l_vendor_contact_rec.person_middle_name:= UPPER(l_supplier_cont_type (l_idx).middle_name);
			 l_vendor_contact_rec.person_last_name	:= UPPER(l_supplier_cont_type (l_idx).last_name);
			 l_vendor_contact_rec.person_title		:= l_supplier_cont_type (l_idx).title;
			 l_vendor_contact_rec.area_code			:= l_supplier_cont_type (l_idx).area_code;
			 l_vendor_contact_rec.phone				:= l_supplier_cont_type (l_idx).phone;
			 l_vendor_contact_rec.fax_area_code		:= l_supplier_cont_type (l_idx).fax_area_code;
			 l_vendor_contact_rec.fax_phone			:= l_supplier_cont_type (l_idx).fax;
			 l_vendor_contact_rec.email_address		:= l_supplier_cont_type (l_idx).email_address;
			 l_vendor_contact_rec.org_id			:= l_org_id;

     		 fnd_msg_pub.initialize; --to make msg_count 0
             l_return_status := NULL;
             l_msg_count     := NULL;
             l_msg_data      := NULL;
			 lc_error_mesg   := NULL;

			 pos_vendor_pub_pkg.create_vendor_contact( p_vendor_contact_rec => l_vendor_contact_rec,
													   x_return_status  	=> l_return_status,
													   x_msg_count 			=> l_msg_count,
													   x_msg_data 			=> l_msg_data,
													   x_vendor_contact_id 	=> l_vendor_contact_id,
													   x_per_party_id 		=> l_per_party_id,
													   x_rel_party_id 		=> l_rel_party_id,
													   x_rel_id 			=> l_rel_id,
													   x_org_contact_id 	=> l_org_contact_id,
													   x_party_site_id 		=> l_party_site_id
													 );

             COMMIT;
             print_debug_msg(p_message=> 'pos_vendor_pub_pkg.create_vendor_contact :' || x_return_status , p_force => TRUE);

			 IF l_return_status <> 'S' AND l_msg_count > 0 THEN
			   FOR I IN 1..l_msg_count LOOP
			     fnd_msg_pub.get ( p_msg_index => i , p_encoded => 'F' , p_data => l_msg , p_msg_index_out => ln_msg_index_num);
			     lc_error_mesg:=lc_error_mesg||','||l_msg;
                 print_debug_msg(p_message=> 'pos_vendor_pub_pkg.create_vendor_contact call failed with error: ' || l_msg , p_force => TRUE);
               END LOOP;
			   l_supplier_cont_type (l_idx).error_flag                 := gc_process_error_flag;
               l_supplier_cont_type (l_idx).contact_process_flag       := 6;
               l_supplier_cont_type (l_idx).error_msg                  := lc_error_mesg;
			   l_supplier_cont_type (l_idx).process_flag			   := 'Y';

			 ELSIF l_return_status='S' THEN
               l_supplier_cont_type (l_idx).contact_process_flag       := 7;
			   l_supplier_cont_type (l_idx).process_flag			   := 'Y';
	         END IF;
          END IF; -- l_cont_process_error_flag := 'N'
        END IF;   -- IF l_supplier_cont_type (l_idx).create_flag = 'Y'
      END LOOP;   -- l_supplier_cont_type.FIRST .. l_supplier_cont_type.LAST
    END IF;       -- l_supplier_cont_type.COUNT > 0
    --==============================================================================
    -- For Doing the Bulk Update
    --=============================================================================
    IF l_supplier_cont_type.count > 0 THEN
      BEGIN
        FORALL l_idxs IN l_supplier_cont_type.first .. l_supplier_cont_type.last
          UPDATE xx_ap_cld_supp_contact_stg
             SET contact_process_flag      = l_supplier_cont_type (l_idxs).contact_process_flag,
				 last_updated_by             =g_user_id,
				 last_update_date            =SYSDATE,
				 error_msg                   = l_supplier_cont_type (l_idxs).error_msg,
				 error_flag                  = l_supplier_cont_type (l_idxs).error_flag,
				 process_flag		         = l_supplier_cont_type (l_idxs).process_flag
           WHERE 1                       =1
             AND vendor_site_code          = l_supplier_cont_type (l_idxs).vendor_site_code
             AND supplier_number           = l_supplier_cont_type (l_idxs).supplier_number
             AND first_name                = l_supplier_cont_type (l_idxs).first_name
             AND last_name                 = l_supplier_cont_type (l_idxs).last_name
             AND request_id                = gn_request_id;
      EXCEPTION
        WHEN OTHERS THEN
          l_error_message           := 'When Others Exception ' || SQLCODE || ' - ' || SUBSTR (sqlerrm ,1 ,3850 );
      END;
    END IF; -- l_supplier_cont_type.COUNT For Bulk Update of Supplier
    EXIT
  WHEN c_supplier_contacts%notfound;
  END LOOP; -- For Open c_supplier
  CLOSE c_supplier_contacts;
  l_supplier_cont_type.DELETE;
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
--| Name          : create_address_contact                                     |
--| Description   : This procedure will create the address contacts for the    |
--|                 vendor site                                                |
--| Parameters    : N/A                                                        |
--|                                                                            |
--| Returns       : N/A                                                        |
--+============================================================================+
/*
PROCEDURE create_address_contact( x_ret_code OUT NUMBER ,
                                  x_return_status OUT VARCHAR2 ,
                                  x_err_buf OUT VARCHAR2 )
IS
  --==============================
  -- Declaring Local variables
  --==============================
  p_api_version      		       NUMBER;
  p_init_msg_list    		       VARCHAR2(200);
  p_commit           		       VARCHAR2(200);
  p_validation_level 		       NUMBER;
  l_msg              		       VARCHAR2(2000);
  l_process_flag     		       VARCHAR2(10);
  lr_existing_vendor_site_rec      ap_supplier_sites_all%rowtype;
  p_calling_prog   		       	   VARCHAR2(200);
  l_program_step   		       	   VARCHAR2 (100) := '';
  ln_msg_index_num 		       	   NUMBER;
  lr_contact_point_rec             hz_contact_point_v2pub.contact_point_rec_type;
  lr_edi_rec                       hz_contact_point_v2pub.edi_rec_type;
  lr_email_rec                     hz_contact_point_v2pub.email_rec_type;
  lr_phone_rec                     hz_contact_point_v2pub.phone_rec_type;
  lr_telex_rec                     hz_contact_point_v2pub.telex_rec_type;
  lr_web_rec                       hz_contact_point_v2pub.web_rec_type;
  x_msg_count                      NUMBER;
  x_msg_data                       VARCHAR2(2000);
  ln_user_id                       NUMBER;
  ln_responsibility_id             NUMBER;
  ln_responsibility_appl_id        NUMBER;
  ln_object_version_number         NUMBER :=1;
  x_contact_point_id               NUMBER;

  --==============================================================================
  -- Cursor Declarations for Suppliers
  --==============================================================================
  CURSOR c_supplier_site
  IS
  SELECT *
    FROM xx_ap_cld_supp_sites_stg xas
   WHERE xas.create_flag     ='Y'
     AND xas.site_process_flag = gn_process_status_imported
     AND xas.request_id        = gn_request_id
	 AND xas.fax_area_code IS NOT NULL OR xas.fax IS NOT NULL OR xas.email_address IS NOT NULL OR xas.phone_number IS NOT NULL OR xas.phone_area_code IS NOT NULL;
 BEGIN
  -- Assign Basic Values
  print_debug_msg(p_message=> 'Begin Create Supplier Site Address Contact Procedure', p_force=>true);
  p_api_version      := 1.0;
  p_init_msg_list    := fnd_api.g_false;
  p_commit           := fnd_api.g_false;
  p_validation_level := fnd_api.g_valid_level_full;
  p_calling_prog     := 'XXCUSTOM';
  l_program_step     := 'START';

  BEGIN
       SELECT user_id,
              responsibility_id,
              responsibility_application_id
         INTO ln_user_id,
              ln_responsibility_id,
              ln_responsibility_appl_id
         FROM fnd_user_resp_groups
        WHERE user_id=(SELECT user_id
                         FROM fnd_user
                        WHERE user_name = 'ODCDH')
          AND responsibility_id=(SELECT responsibility_id
                                   FROM fnd_responsibility
                                  WHERE responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
  EXCEPTION
       WHEN OTHERS
       THEN
			print_debug_msg(p_message=> l_program_step||'Exception in WHEN OTHERS for SET_CONTEXT_ERROR: '||SQLERRM, p_force=>true);
  END;

  fnd_global.apps_initialize( ln_user_id,
                              ln_responsibility_id,
                              ln_responsibility_appl_id
                            );
  fnd_global.set_nls_context('AMERICAN');

  FOR c_sup_site IN c_supplier_site
  LOOP
    print_debug_msg(p_message=> 'Creation of Address Contact for the Site : '|| c_sup_site.vendor_site_code, p_force=>true);
    BEGIN
      SELECT *
        INTO lr_existing_vendor_site_rec
        FROM ap_supplier_sites_all assa
       WHERE assa.vendor_site_code = c_sup_site.vendor_site_code
         AND assa.vendor_id        = c_sup_site.vendor_id
         AND assa.org_id           = c_sup_site.org_id;
    EXCEPTION
      WHEN OTHERS THEN
        print_debug_msg(p_message=> l_program_step||'Unable to derive the supplier site information for site id:' || lr_existing_vendor_site_rec.vendor_site_id, p_force=>true);
    END;

	IF c_sup_site.email_address IS NOT NULL
	THEN
	    lr_contact_point_rec := NULL;
		lr_phone_rec := NULL;
		lr_email_rec := NULL;
	    lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	    lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
        lr_contact_point_rec.created_by_module      := 'AP_SUPPLIERS_API';
	    lr_contact_point_rec.primary_flag           := 'Y';
		lr_contact_point_rec.contact_point_type     := 'EMAIL';
		lr_email_rec.email_address                  := c_sup_site.email_address;

        x_contact_point_id := NULL;
		x_return_status    := NULL;
        x_msg_count        := NULL;
        x_msg_data         := NULL;
        -------------------------Calling Address Contact API

		hz_contact_point_v2pub.create_contact_point ( p_init_msg_list => FND_API.G_TRUE,
		                                              p_contact_point_rec => lr_contact_point_rec,
													  p_edi_rec => lr_edi_rec,
													  p_email_rec => lr_email_rec,
													  p_phone_rec => lr_phone_rec,
                                                      p_telex_rec => lr_telex_rec,
													  p_web_rec => lr_web_rec,
													  x_contact_point_id => x_contact_point_id,
													  x_return_status => x_return_status,
													  x_msg_count => x_msg_count,
													  x_msg_data => x_msg_data );

        print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		IF x_return_status = fnd_api.g_ret_sts_success
		THEN
           COMMIT;
           print_debug_msg(p_message=> 'Creation of EMAIL Contact Point is Successful ', p_force=>true);
           print_debug_msg(p_message=> 'Output information ....', p_force=>true);
           print_debug_msg(p_message=> 'x_contact_point_id = '||x_contact_point_id, p_force=>true);
        ELSE
           print_debug_msg(p_message=> 'Creation of Contact Point got failed:'||x_msg_data, p_force=>true);
           ROLLBACK;
           FOR i IN 1 .. x_msg_count
           LOOP
              x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
              print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
              END LOOP;
        END IF;
    ELSIF c_sup_site.phone_number IS NOT NULL
	THEN
	    lr_contact_point_rec := NULL;
		lr_phone_rec := NULL;
		lr_email_rec := NULL;
		lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	    lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
        lr_contact_point_rec.created_by_module      := 'AP_SUPPLIERS_API';
	    lr_contact_point_rec.primary_flag           := 'Y';
		lr_contact_point_rec.contact_point_type     := 'PHONE';
		lr_phone_rec.phone_area_code                := c_sup_site.phone_area_code;
        lr_phone_rec.phone_number                   := c_sup_site.phone_number;
        lr_phone_rec.phone_line_type                := 'GEN';

        x_contact_point_id := NULL;
		x_return_status    := NULL;
        x_msg_count        := NULL;
        x_msg_data         := NULL;
        -------------------------Calling Address Contact API

		hz_contact_point_v2pub.create_contact_point ( p_init_msg_list => FND_API.G_TRUE,
		                                              p_contact_point_rec => lr_contact_point_rec,
													  p_edi_rec => lr_edi_rec,
													  p_email_rec => lr_email_rec,
													  p_phone_rec => lr_phone_rec,
                                                      p_telex_rec => lr_telex_rec,
													  p_web_rec => lr_web_rec,
													  x_contact_point_id => x_contact_point_id,
													  x_return_status => x_return_status,
													  x_msg_count => x_msg_count,
													  x_msg_data => x_msg_data );

        print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		IF x_return_status = fnd_api.g_ret_sts_success
		THEN
           COMMIT;
           print_debug_msg(p_message=> 'Creation of PHONE Contact Point is Successful ', p_force=>true);
           print_debug_msg(p_message=> 'Output information ....', p_force=>true);
           print_debug_msg(p_message=> 'x_contact_point_id = '||x_contact_point_id, p_force=>true);
        ELSE
           print_debug_msg(p_message=> 'Creation of Contact Point got failed:'||x_msg_data, p_force=>true);
           ROLLBACK;
           FOR i IN 1 .. x_msg_count
           LOOP
              x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
              print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
              END LOOP;
        END IF;
	ELSIF c_sup_site.fax IS NOT NULL
	THEN
	    lr_contact_point_rec := NULL;
		lr_phone_rec := NULL;
		lr_email_rec := NULL;
	    lr_contact_point_rec.owner_table_id         := lr_existing_vendor_site_rec.party_site_id;
	    lr_contact_point_rec.owner_table_name       := 'HZ_PARTY_SITES';
        lr_contact_point_rec.created_by_module      := 'AP_SUPPLIERS_API';
	    lr_contact_point_rec.primary_flag           := 'N';
		lr_contact_point_rec.contact_point_type     := 'PHONE';
		lr_phone_rec.phone_area_code                := c_sup_site.fax_area_code;
        lr_phone_rec.phone_number                   := c_sup_site.fax;
        lr_phone_rec.phone_line_type                := 'FAX';

        x_contact_point_id := NULL;
		x_return_status:= NULL;
        x_msg_count    := NULL;
        x_msg_data     := NULL;
        -------------------------Calling Address Contact API

		hz_contact_point_v2pub.create_contact_point ( p_init_msg_list => FND_API.G_TRUE,
		                                              p_contact_point_rec => lr_contact_point_rec,
													  p_edi_rec => lr_edi_rec,
													  p_email_rec => lr_email_rec,
													  p_phone_rec => lr_phone_rec,
                                                      p_telex_rec => lr_telex_rec,
													  p_web_rec => lr_web_rec,
													  x_contact_point_id => x_contact_point_id,
													  x_return_status => x_return_status,
													  x_msg_count => x_msg_count,
													  x_msg_data => x_msg_data );

        print_debug_msg(p_message=> 'API Return Status / Msg Count : ' || x_return_status||' / '||x_msg_count, p_force=>true);

		IF x_return_status = fnd_api.g_ret_sts_success
		THEN
           COMMIT;
           print_debug_msg(p_message=> 'Creation of FAX Contact Point is Successful ', p_force=>true);
           print_debug_msg(p_message=> 'Output information ....', p_force=>true);
           print_debug_msg(p_message=> 'x_contact_point_id = '||x_contact_point_id, p_force=>true);
        ELSE
           print_debug_msg(p_message=> 'Creation of Contact Point got failed:'||x_msg_data, p_force=>true);
           ROLLBACK;
           FOR i IN 1 .. x_msg_count
           LOOP
              x_msg_data := fnd_msg_pub.get( p_msg_index => i, p_encoded => 'F');
              print_debug_msg(p_message=>  i|| ') '|| x_msg_data, p_force=>true);
              END LOOP;
        END IF;
	END IF;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    x_ret_code      := 1;
    x_return_status := 'E';
    x_err_buf       := 'In exception for procedure create_address_contact' ;
END create_address_contact;
*/
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

  --===========================================================================
  -- Load the validated records in staging table into interface table    --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure load_supplier_site_interface()' , p_force => true);
  load_supplier_site_interface( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure load_supplier_site_interface()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);

  print_debug_msg(p_message => 'Invoking the procedure load update_suppliers_sites()' , p_force => true);
  update_supplier_sites( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_supplier_sites()' , p_force => true);
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

  print_debug_msg(p_message => 'Invoking the procedure attach_bank_assignments()' , p_force => true);
  attach_bank_assignments( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completion of attach_bank_assignments' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);

  print_debug_msg(p_message => 'Invoking the procedure Update_bank_assignment_date()' , p_force => true);
  update_bank_assignment_date( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  Print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completion of Update_bank_assignment_date' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);

EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_supplier_bank() - '||SQLCODE||' - '||SUBSTR(sqlerrm,1,3500);
END main_prc_supplier_bank;
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
PROCEDURE main_prc_address_contact( x_errbuf OUT nocopy  VARCHAR2 ,
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

  --===========================================================================
  -- Update Address Contacts for the Supplier Sites --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure update_address_contact()' , p_force => true);
  update_address_contact( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_address_contact()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_address_contact() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END main_prc_address_contact;
--+============================================================================+
--| Name          : main_prc_remittance_email                                  |
--| Description   : This procedure will be called from the concurrent program  |
--|                 to update the remit advice email                           |
--| Parameters    :                                                            |
--| Returns       :                                                            |
--|                   x_errbuf                  OUT      VARCHAR2              |
--|                   x_retcode                 OUT      NUMBER                |
--|                                                                            |
--|                                                                            |
--+============================================================================+
PROCEDURE main_prc_remittance_email( x_errbuf OUT nocopy  VARCHAR2 ,
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

  --===========================================================================
  -- Update Address Contacts for the Supplier Sites --
  --===========================================================================
  print_debug_msg(p_message => 'Invoking the procedure update_remittance_email()' , p_force => true);
  update_remittance_email( x_ret_code => l_ret_code , x_return_status => l_return_status , x_err_buf => l_err_buff);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
  print_debug_msg(p_message => 'Completed the execution of the procedure update_remittance_email()' , p_force => true);
  print_debug_msg(p_message => '===========================================================================' , p_force => true);
EXCEPTION
  WHEN OTHERS THEN
    x_retcode := 2;
    x_errbuf  := 'Exception in XX_AP_SUPP_CLD_INTF_PKG.main_prc_remittance_email() - '||SQLCODE||' - '||SUBSTR(SQLERRM,1,3500);
END main_prc_remittance_email;

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

--+============================================================================+
--| Name          : update_status                                              |
--| Description   : This procedure will update error message for all           |
--|                 unprocessed records into EBS                               |
--|                                                                            |
--| Parameters    :                                                            |
--|                                                                            |
--| Returns       : N/A                                                        |
--|                                                                            |
--+============================================================================+
PROCEDURE update_status
IS
BEGIN
  UPDATE xx_ap_cld_supp_sites_stg ss
     SET ss.error_msg ='Site not processed due to Supplier Error',
		 ss.site_process_flag=3,
		 ss.process_flag='Y',
	     ss.error_Flag='Y'
   WHERE ss.request_id = gn_request_id
     AND ss.site_process_flag = 2
	 AND EXISTS ( SELECT 'x'
					FROM xx_ap_cld_suppliers_stg
				   WHERE request_id=ss.request_id
					 AND supp_process_flag <> 7
					 AND segment1=ss.supplier_number
			    );
  COMMIT;

  UPDATE xx_ap_cld_supp_contact_stg ct
     SET ct.error_msg = 'Contact not processed due to Site Error',
		 ct.contact_process_flag=3,
		 ct.process_flag='Y',
		 ct.error_Flag='Y'
   WHERE ct.request_id = gn_request_id
     AND ct.contact_process_flag = 2
	 AND EXISTS ( SELECT 'x'
					FROM xx_ap_cld_supp_sites_stg
				   WHERE request_id=ct.request_id
					 AND site_process_flag <> 7
					 AND supplier_number=ct.supplier_number
					 AND vendor_site_code=ct.vendor_site_code
			    );
  COMMIT;

  UPDATE xx_ap_cld_supp_bcls_stg bcls
     SET bcls.error_msg = 'Business Classification Not processed due to Supplier Error',
	     bcls.bcls_process_flag =3,
		 bcls.error_flag='Y',
		 bcls.process_flag='Y'
   WHERE bcls.request_id = gn_request_id
     AND bcls.bcls_process_flag = 2
	 AND EXISTS ( SELECT 'x'
					FROM xx_ap_cld_suppliers_stg
				   WHERE request_id=bcls.request_id
					 AND supp_process_flag <> 7
					 AND segment1=bcls.supplier_number
			    );
  COMMIT;

  UPDATE xx_ap_cld_site_dff_stg dff
     SET dff.error_msg = 'Custom DFF not processed due to Site Error',
	     dff.dff_process_flag=3,
		 dff.error_flag='Y',
		 dff.process_flag='Y'
   WHERE dff.request_id = gn_request_id
     AND dff.dff_process_Flag = 2
	 AND EXISTS ( SELECT 'x'
					FROM xx_ap_cld_supp_sites_stg
				   WHERE request_id=dff.request_id
					 AND site_process_flag<>7
					 AND vendor_site_code=dff.vendor_site_code
			    );
  COMMIT;

  UPDATE xx_ap_cld_supp_bnkact_stg bnk
     SET bnk.error_msg = 'Bank not processed due to Site Error',
	     bnk.bnkact_process_flag=3,
		 bnk.error_flag='Y',
		 bnk.process_flag='Y'
   WHERE bnk.request_id = gn_request_id
     AND bnk.bnkact_process_flag=2
	 AND EXISTS ( SELECT 'x'
					FROM xx_ap_cld_supp_sites_stg
				   WHERE request_id=bnk.request_id
					 AND site_process_flag<>7
					 AND vendor_site_code=bnk.vendor_site_code
			    );
  COMMIT;
EXCEPTION
  WHEN OTHERS
  THEN
    print_debug_msg(p_message => 'When others in Update Status : '|| SQLERRM, p_force => true);
END update_status;
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
-- +=================================================================================|
-- | Procedure Name : main_prc_staging_purge                                         |
-- | Description    : Main procedure for Supplier Interface to Purge staging tables  |
-- |                  xx_ap_cld_suppliers_stg                                        |
-- |                  xx_ap_cld_supp_sites_stg                                       |
-- |                  xx_ap_cld_supp_contact_stg                                     |
-- |                  xx_ap_cld_supp_bnkact_stg                                      |
-- |                  xx_ap_cld_supp_bcls_stg                                        |
-- |                  xx_ap_cld_site_dff_stg                                         |
-- +=================================================================================|
PROCEDURE main_prc_staging_purge
IS
BEGIN
  print_debug_msg(p_message =>'--------------------------------------------------------------------------------------------', p_force => true);
  print_debug_msg(p_message => 'Starting Purge Process', p_force => true);

  DELETE FROM xx_ap_cld_suppliers_stg
   WHERE process_flag  = 'Y'
     AND creation_date < SYSDATE-30;
  print_debug_msg(p_message =>'No. of Rows deleted in xx_ap_cld_suppliers_stg table :'||sql%rowcount,p_force => true);
  COMMIT;

  DELETE FROM xx_ap_cld_supp_sites_stg
   WHERE process_flag  = 'Y'
     AND creation_date < SYSDATE-30;
  print_debug_msg(p_message =>'No. of Rows deleted in xx_ap_cld_supp_sites_stg table :'||sql%rowcount,p_force => true);
  COMMIT;

  DELETE FROM xx_ap_cld_supp_contact_stg
   WHERE process_flag    ='Y'
     AND creation_date < SYSDATE-30;
  print_debug_msg(p_message =>'No. of Rows deleted in xx_ap_cld_supp_contact_stg table :'||sql%rowcount,p_force => true);
  COMMIT;

  DELETE FROM xx_ap_cld_supp_bnkact_stg
   WHERE process_flag    ='Y'
     AND creation_date < sysdate-30;
  print_debug_msg(p_message =>'No. of Rows deleted in xx_ap_cld_supp_bnkact_stg table :'||sql%rowcount,p_force => true);
  COMMIT;

  DELETE FROM xx_ap_cld_supp_bcls_stg
   WHERE process_flag    ='Y'
     AND creation_date < sysdate-30;
  print_debug_msg(p_message =>'No. of Rows deleted in xx_ap_cld_supp_bcls_stg table :'||sql%rowcount,p_force => true);
  COMMIT;

  DELETE FROM xx_ap_cld_site_dff_stg
   WHERE process_flag    ='Y'
     AND creation_date < sysdate-30;
  print_debug_msg(p_message =>'No. of Rows deleted in xx_ap_cld_site_dff_stg table :'||sql%rowcount,p_force => true);
  COMMIT;

  print_debug_msg(p_message =>'--------------------------------------------------------------------------------------------', p_force => true);
EXCEPTION
WHEN OTHERS
THEN
  print_debug_msg(p_message => 'Error Message - main_prc_staging_purge : '|| SQLERRM, p_force=> true);
END main_prc_staging_purge;
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
  l_procedure                  VARCHAR2 (30) := 'xx_ap_supp_cld_intf';
  l_ret_code                   NUMBER;
  l_err_buff                   VARCHAR2 (4000);
  ln_request_id                NUMBER;
  ln_request_id1               NUMBER;
  lb_complete                  BOOLEAN;
  lc_phase                     VARCHAR2 (100);
  lc_status                    VARCHAR2 (100);
  lc_dev_phase                 VARCHAR2 (100);
  lc_dev_status                VARCHAR2 (100);
  lc_message                   VARCHAR2 (100);
  lb_layout                    BOOLEAN;
  ln_user_id                   NUMBER;
  ln_responsibility_id         NUMBER;
  ln_responsibility_appl_id    NUMBER;
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

  print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPPLIERS_STG are '||SQL%ROWCOUNT , p_force => true);
  print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are '||SQL%ROWCOUNT);
  COMMIT;
  /*
  IF SQL%ROWCOUNT = 0 THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPPLIERS_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are 0');
  ELSE
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPPLIERS_STG are '||sql%rowcount , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier records ready for validate and load are '||sql%rowcount);
  END IF;
  */

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
  print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_SITES_STG are '||SQL%ROWCOUNT , p_force => true);
  print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are '||SQL%ROWCOUNT);
  COMMIT;
  /*
  IF SQL%ROWCOUNT = 0 THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_SITES_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are 0');
  ELSE
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_SITES_STG are '||sql%rowcount , p_force => true);
    print_out_msg(p_message => 'Total No. of Supplier Site records ready for validate and load are '||sql%rowcount);
  END IF;
  */
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
  print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_CONTACT_STG are '||SQL%ROWCOUNT , p_force => true);
  print_out_msg(P_MESSAGE => 'Total No. of Contact records ready for validate and load are '||SQL%ROWCOUNT);
  COMMIT;
  /*
  IF SQL%ROWCOUNT = 0 THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_SUP_CLOUD_CONTACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Contact records ready for validate and load are 0');
  ELSE
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_SUP_CLOUD_CONTACT_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of Contact records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  */
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
  print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BNKACT_STG are '||SQL%ROWCOUNT , p_force => true);
  print_out_msg(P_MESSAGE => 'Total No. of Bank records ready for validate and load are '||SQL%ROWCOUNT);
  COMMIT;
  /*
  IF SQL%ROWCOUNT = 0 THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPP_BNKACT_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Bank records ready for validate and load are 0');
  ELSE
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BNKACT_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of Bank records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  */
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
  print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SITE_DFF_STG are '||SQL%ROWCOUNT , p_force => true);
  print_out_msg(P_MESSAGE => 'Total No. of DFF ready for validate and load are '||SQL%ROWCOUNT);
  COMMIT;
  /*
  IF SQL%ROWCOUNT = 0 THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SITE_DFF_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of DFF ready for validate and load are 0');
  ELSE
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SITE_DFF_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of DFF ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  */
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
  print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BCLS_STG are '||SQL%ROWCOUNT , p_force => true);
  print_out_msg(P_MESSAGE => 'Total No. of Classification records ready for validate and load are '||SQL%ROWCOUNT);
  COMMIT;
  /*
  IF SQL%ROWCOUNT = 0 THEN
    print_debug_msg(p_message => 'No records exist to process in the table XX_AP_CLD_SUPP_BCLS_STG.' , p_force => true);
    print_out_msg(p_message => 'Total No. of Classification records ready for validate and load are 0');
  ELSE
    print_debug_msg(p_message => 'Records to be processed from the table XX_AP_CLD_SUPP_BCLS_STG are '||sql%rowcount , p_force => true);
    print_out_msg(P_MESSAGE => 'Total No. of Classification records ready for validate and load are '||SQL%ROWCOUNT);
  END IF;
  */
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

  print_debug_msg(p_message => 'Calling Custom Tolerance and Traits' , p_force => true);
  xx_tolerance_trait(gn_request_id);
  print_debug_msg(p_message => 'exiting custom Tolerance and Traits' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling Create and Update Address Contact Point Process' , p_force => true);
  main_prc_address_contact(x_errbuf =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(p_message => 'exiting Create and Update Address Contact Point Process' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling Remittance Email Procedure' , p_force => true);
  main_prc_remittance_email(x_errbuf =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(p_message => 'exiting Remittance Email Procedure' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling  Update_supplier_telex' , p_force => true);
  update_supplier_telex(x_errbuf =>l_err_buff , x_retcode=> l_ret_code);
  print_debug_msg(p_message => 'Exiting Update_supplier_telex' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  print_debug_msg(p_message => 'Calling  update_status' , p_force => true);
  update_status;
  print_debug_msg(p_message => 'Exiting update_status' , p_force => true);
  print_debug_msg(p_message => '+---------------------------------------------------------------------------+' , p_force => true);

  BEGIN
       SELECT user_id,
              responsibility_id,
              responsibility_application_id
         INTO ln_user_id,
              ln_responsibility_id,
              ln_responsibility_appl_id
         FROM fnd_user_resp_groups
        WHERE user_id=(SELECT user_id
                         FROM fnd_user
                        WHERE user_name = 'SVC_ESP_FIN')
          AND responsibility_id=(SELECT responsibility_id
                                   FROM fnd_responsibility
                                  WHERE responsibility_key = 'OD_US_BATCH_JOBS');
  EXCEPTION
       WHEN OTHERS
       THEN
			print_debug_msg(p_message=> 'Exception in WHEN OTHERS for SET_CONTEXT_ERROR: '||SQLERRM, p_force=>true);
  END;

  fnd_global.apps_initialize( ln_user_id,
                              ln_responsibility_id,
                              ln_responsibility_appl_id
                            );
  fnd_global.set_nls_context('AMERICAN');

  print_debug_msg(p_message => '                                                                             ' , p_force => true);
  print_debug_msg(p_message => 'Submitting the Report Program to generate the Excel File', p_force => true);

  lb_layout     := fnd_request.add_layout('XXFIN', 'XXAPCLDINTR', 'en', 'US', 'EXCEL' );
  ln_request_id := fnd_request.submit_request ( application => 'XXFIN',
												program => 'XXAPCLDINTR',
												description => NULL,
												start_time => SYSDATE,
												sub_request => FALSE,
												argument1 => gn_request_id
											  );
  IF ln_request_id > 0
  THEN
     COMMIT;
     print_debug_msg(p_message => 'Able to submit the Report Program', p_force => true);

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

  ELSE
     print_debug_msg(p_message => 'Failed to submit the Report Program to generate the output file - ' || SQLERRM , p_force => true);
  END IF;

  -- Process the Purge Staging Tables for the records more than 30 days
  main_prc_staging_purge;

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

 -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name  :  afterReport                                                                      |
  -- |                                                                                            |
  -- |  Description:  Common Report for XML bursting                                              |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+

FUNCTION beforeReport RETURN BOOLEAN
IS
BEGIN
   RETURN TRUE;
END beforeReport;

FUNCTION afterReport RETURN BOOLEAN
IS
  ln_request_id1        NUMBER := 0;
BEGIN
  P_CONC_REQUEST_ID := FND_GLOBAL.CONC_REQUEST_ID;
  fnd_file.put_line(fnd_file.log, 'OD: AP Cloud Supplier Interface Report Request ID: '||P_CONC_REQUEST_ID);
  IF P_CONC_REQUEST_ID > 0
  THEN
      fnd_file.put_line(fnd_file.log, 'Submitting : XML Publisher Report Bursting Program');
      ln_request_id1 := FND_REQUEST.SUBMIT_REQUEST('XDO',  -- Application short name
	                                              'XDOBURSTREP', --- conc program short name
												  NULL,
												  NULL,
												  FALSE,
												  'N',
												  P_CONC_REQUEST_ID,
												  'Y');

	  IF ln_request_id1 > 0
      THEN
         COMMIT;
	     fnd_file.put_line(fnd_file.log,'Able to submit the XML Bursting Program to email the output file');
      ELSE
         fnd_file.put_line(fnd_file.log,'Failed to submit the XML Bursting Program to email the file - ' || SQLERRM);
      END IF;
  ELSE
      fnd_file.put_line(fnd_file.log,'Failed to submit the Report Program to generate the output file - ' || SQLERRM);
  END IF;
  RETURN(TRUE);
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unable to submit burst request ' || SQLERRM);
END afterReport;

END XX_AP_SUPP_CLD_INTF_PKG;