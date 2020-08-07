CREATE OR REPLACE
PACKAGE BODY xx_gi_comn_utils_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                  Office Depot                                     |
-- +===================================================================+
-- | Name  :  xx_gi_comn_utils_pkg                                     |
-- | Description      : This package contains library of common        |
-- |                    procedures AND functions used                  |
-- |                    Various Custom Office Depot Procedures         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- |1.0      16-JUL-2007  Rama Dwibhashyam Baselined after testing     |
-- +===================================================================+

-- +===================================================================+
-- | Name  :  write_log                                                |
-- | Description      : This procedure writes the log for the conc     |
-- |                    program                                        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  --
  PROCEDURE write_log (p_text_in IN VARCHAR2)
  IS
  BEGIN
    --
    IF LTRIM (p_text_in) IS NULL
    THEN
      Fnd_File.put_line (Fnd_File.LOG, p_text_in);
    ELSE
      IF pvg_debug_option = 'Y'
      THEN
        Fnd_File.put_line (Fnd_File.LOG, sqlpoint || p_text_in);
      ELSE
        Fnd_File.put_line (Fnd_File.LOG, p_text_in);
      END IF;
    END IF;
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      log_exception ('write_log');
      RAISE;
  --
  END write_log;
-- +===================================================================+
-- | Name  :  write_out                                                |
-- | Description      : This procedure writes the output for the conc  |
-- |                    program                                        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  PROCEDURE write_out (p_text_in IN VARCHAR2)
  IS
  BEGIN
    --
    Fnd_File.put_line (Fnd_File.output, p_text_in);
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      log_exception ('write_out');
      RAISE;
  --
  END write_out;
-- +===================================================================+
-- | Name  :  write_debug                                              |
-- | Description      : This procedure writes the debug for the conc   |
-- |                    program                                        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  PROCEDURE write_debug (p_msg_in IN VARCHAR2)
  IS
  BEGIN
    --
    IF pvg_debug_option = 'Y'
    THEN
      Fnd_File.put_line (Fnd_File.LOG, sqlpoint || p_msg_in);
    END IF;
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      log_exception ('write_debug');
      RAISE;
  --
  END write_debug;

-- +===================================================================+
-- | Name  :  write_line                                               |
-- | Description      : This Function is used for creating line        |
-- |                    using p_char_in of length p_len_in             |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
PROCEDURE write_line (p_char_in VARCHAR2, p_len_in NUMBER)
  IS
    --
  BEGIN
    --
    Fnd_File.put_line (Fnd_File.LOG, RPAD (p_char_in, p_len_in, p_char_in));
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      log_exception ('write_line');
      RAISE;
  --
END write_line;

-- +===================================================================+
-- | Name  :  sqlpoint                                                 |
-- | Description      : This function used in the debugging and log    |
-- |                    program                                        |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
FUNCTION sqlpoint
  RETURN VARCHAR2 IS
    --
  BEGIN
    --
    RETURN 'SQLPoint: ' || RPAD (pvg_sql_point, 5, ' ') || ' - ';
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      write_line ('*', 70);
      write_log ('When Others Exception occured in xx_gi_comn_utils_pkg.sqlpoint');
      write_log ('This Exception was raised by following error:' || SQLERRM);
      write_line ('*', 70);
      --
      RAISE;
  --
  END sqlpoint;
-- +===================================================================+
-- | Name  :  log_exception                                            |
-- | Description      : This procedure is used for logging Error       |
-- |                    raised by When OthersException of              |
-- |                    calling object                                 |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  PROCEDURE log_exception (p_object_name_in IN VARCHAR2)
  IS
  BEGIN
    --
    IF pvg_exception_handled = 'Y'
    THEN
      --
      -- Exception Message is already logged
      RETURN;
      --
    ELSE
      --
      -- Flag this variable, so subsequent WHEN-OTHERS handlers don't write
      -- the follwing message to Log repeatedly
      pvg_exception_handled := 'Y';
      --
      write_line ('*', 70);
      write_log (sqlpoint);
      write_log ('When Others exception occured in ' || p_object_name_in || '.');
      write_log ('This exception was raised by following error:');
      write_log (SQLERRM);
      write_line ('*', 70);
      --
      --
      write_out (RPAD ('*', 70, '*'));
      write_out (sqlpoint);
      write_out ('When Others exception occured in ' || p_object_name_in || '.');
      write_out ('This exception was raised by following error:');
      write_out (SQLERRM);
      write_out (RPAD ('*', 70, '*'));
      --
    END IF;
    --
  EXCEPTION
    --
    WHEN OTHERS THEN
      --
      write_line ('*', 70);
      write_log ('When Others Exception occured in' ||
                 'xx_gi_comn_utils_pkg.log_exception');
      write_log ('This Exception was raised by following error:' || SQLERRM);
      write_line ('*', 70);
      --
      RAISE;
  --
  END log_exception;
-- +===================================================================+
-- | Name  : get_gi_trx_type_id                                        |
-- | Description      : This Function will be used to fetch oracle EBS |
-- |                    Inv transaction type id.                       |
-- | Parameters :       legacy trx                                     |
-- |                    legacy trx type                                |
-- |                    trx action                                     |
-- | Returns :          transaction type id                            |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
 PROCEDURE get_gi_trx_type_id ( p_legacy_trx  IN VARCHAR2
                               ,p_legacy_trx_type IN VARCHAR2
                               ,p_trx_action  IN VARCHAR2
                               ,x_trx_type_id OUT NUMBER
                               ,x_return_status OUT NOCOPY VARCHAR2
                               ,x_error_message OUT NOCOPY VARCHAR2
                         ) 
IS
    --
    ln_trx_type_id  NUMBER;
    --
BEGIN
    --
    SELECT transaction_type_id
      INTO ln_trx_type_id
      FROM mtl_transaction_types
     WHERE 1=1
       AND upper(attribute1) = upper(p_legacy_trx)
       AND instr(upper(attribute2),upper(p_legacy_trx_type)) > 0
       AND upper(attribute3) = upper(p_trx_action) ;

    x_trx_type_id   := ln_trx_type_id;
    x_return_status := 'S';
    x_error_message := NULL ;
    
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      x_trx_type_id   := -1 ;
      x_return_status := 'E';
      x_error_message := 'No Transaction Type ID Found' ;
      
   WHEN TOO_MANY_ROWS THEN
      x_trx_type_id   := -1 ;
      x_return_status := 'E';
      x_error_message := 'Too Many Transaction Type ID Found' ;
   WHEN OTHERS THEN
      x_trx_type_id   := -1 ;
      x_return_status := 'U';
      x_error_message := 'Unexpected Error in get_gi_trx_type_id procedure'||sqlerrm ;
END get_gi_trx_type_id;
  -- +===================================================================+
-- | Name  : get_gi_reason_id                                          |
-- | Description      : This Function will be used to fetch oracle EBS |
-- |                    Inv transaction Reason id.                     |
-- | Parameters :       legacy trx type                                |
-- | Returns :          Reason id                                      |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
PROCEDURE get_gi_reason_id (p_legacy_trx_type  IN VARCHAR2
                           ,x_reason_id OUT NUMBER
                           ,x_return_status OUT NOCOPY VARCHAR2
                           ,x_error_message OUT NOCOPY VARCHAR2
                         )
IS
    --
    ln_reason_id  NUMBER;
    --
BEGIN
   --
   SELECT reason_id
     INTO ln_reason_id
     FROM mtl_transaction_reasons
    WHERE 1=1
      AND instr(upper(attribute1),upper(p_legacy_trx_type)) > 0 ;

   x_reason_id     := ln_reason_id;
   x_return_status := 'S' ;
   x_error_message := NULL ;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    x_reason_id     := -1 ;
    x_return_status := 'E' ;
    x_error_message := 'No Reason ID Found' ;
    WHEN TOO_MANY_ROWS THEN
    x_reason_id     := -1 ;
    x_return_status := 'E' ;
    x_error_message := 'To Many Reason ID Found' ;
    WHEN OTHERS THEN
    x_reason_id     := -1 ;
    x_return_status := 'U' ;
    x_error_message := 'Unexpected Error in get_gi_reason_id'||SQLERRM ;
END get_gi_reason_id;
-- +===================================================================+
-- | Name  : get_gi_reason_id                                          |
-- | Description      : This Function will be used to fetch oracle EBS |
-- |                    Inv transaction Reason id.                     |
-- | Parameters :       legacy trx type                                |
-- |                    organization id                                |
-- | Returns :          account code combination id                    |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
PROCEDURE get_gi_adj_ccid (p_legacy_trx_type  IN VARCHAR2
                          ,p_org_id  IN NUMBER
                          ,x_adj_ccid OUT NUMBER
                          ,x_return_status OUT NOCOPY VARCHAR2
                          ,x_error_message OUT NOCOPY VARCHAR2
                          )
IS
    --
    ln_adj_ccid  NUMBER;
    lv_segment1  VARCHAR2(30);
    lv_segment2  VARCHAR2(30);
    lv_segment3  VARCHAR2(30);
    lv_segment4  VARCHAR2(30);
    lv_segment5  VARCHAR2(30);
    lv_segment6  VARCHAR2(30);
    lv_segment7  VARCHAR2(30);
    lv_conc_segments VARCHAR2(100);
    lv_adj_account VARCHAR2(100);
    lv_structure_number VARCHAR2(100);
    x_error_msg varchar2(1000);
    --
  BEGIN
   --- let application id 101 for GL
        pvg_application_id := 101 ;

     ---- fnd_global.apps_initialize(1091,20434, 101);   --- user_id,responsibilty id , application_id
      fnd_global.apps_initialize(pvg_user_id,pvg_resp_id, pvg_application_id);   --- user_id,responsibilty id , application_id

      SELECT glb.chart_of_accounts_id,gcc.segment1,gcc.segment2,gcc.segment3,gcc.segment4,gcc.segment5
            ,gcc.segment6,gcc.segment7
        INTO lv_structure_number,lv_segment1,lv_segment2,lv_segment3,lv_segment4,lv_segment5
            ,lv_segment6,lv_segment7
        FROM gl_sets_of_books_v glb,
             hr_all_organization_units hou,
             hr_organization_information hoi,
             mtl_parameters mp,
             gl_code_combinations gcc
       WHERE 1=1
         AND hoi.org_information1 = to_char(glb.set_of_books_id)
         AND hou.organization_id = hoi.organization_id
         AND hoi.org_information_context = 'Accounting Information'
         AND mp.material_account = gcc.code_combination_id
         AND mp.organization_id = hou.organization_id
         AND mp.organization_id = p_org_id ;

      IF lv_segment1 IS NULL THEN
         x_adj_ccid := -1 ;
         x_return_status := 'E' ;
         x_error_message := 'The Supplied Organization setup is wrong' ;
         xx_gi_comn_utils_pkg.write_log ('The Supplied Organization setup is wrong');
      END IF;

      SELECT trim(attribute2)
        INTO lv_adj_account
        FROM mtl_transaction_reasons
       WHERE 1=1
         AND instr(upper(attribute1),upper(p_legacy_trx_type)) > 0 ;

      IF lv_adj_account IS NULL THEN
         x_adj_ccid := -1 ;
         x_return_status := 'E' ;
         x_error_message := 'The Reason Code setup is wrong' ;
         xx_gi_comn_utils_pkg.write_log ('The Reason Code setup is wrong');
      END IF;


      lv_conc_segments := lv_segment1||'.'||lv_segment2||'.'||lv_adj_account||'.'||
                          lv_segment4||'.'||lv_segment5||'.'||lv_segment6||'.'||lv_segment7 ;

      ln_adj_ccid := fnd_flex_ext.get_ccid(application_short_name => 'SQLGL',
			   		key_flex_code	         => 'GL#',
			   		structure_number	 => lv_structure_number,
			   		validation_date	         => null,
			   		concatenated_segments    => lv_conc_segments ) ;


      IF ln_adj_ccid <= 0 THEN
          x_error_msg := fnd_flex_ext.get_message ;
          xx_gi_comn_utils_pkg.write_log ('CCID Creation Error :'||x_error_msg);
          x_adj_ccid := -1 ;
          x_return_status := 'E' ;
          x_error_message := 'CCID Creation Error :'||x_error_msg ;          
      END IF;
       xx_gi_comn_utils_pkg.write_log ('Newly created CCID is :'||ln_adj_ccid);
          x_adj_ccid := ln_adj_ccid ;
          x_return_status := 'S' ;
          x_error_message := 'Newly created CCID is :'||ln_adj_ccid ;  
       

  EXCEPTION
   WHEN OTHERS THEN
          x_adj_ccid := -1 ;
          x_return_status := 'U' ;
          x_error_message := 'Unexpected Error in get_gi_adj_ccid'||SQLERRM ;
     xx_gi_comn_utils_pkg.write_log ('CCID Creation Error :'||x_error_msg);
  END get_gi_adj_ccid;
-- +===================================================================+
-- | Name  : get_ebs_organization_id                                   |
-- | Description      : This Function will be used to fetch oracle EBS |
-- |                    organization id                                |
-- | Parameters :       legacy location id                             |
-- | Returns :          organization id                                |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
FUNCTION get_ebs_organization_id (p_legacy_loc_id  IN NUMBER
                                    )
RETURN NUMBER
IS
      lv_organization_id NUMBER;
BEGIN


        SELECT hou.organization_id
          INTO lv_organization_id
          FROM hr_all_organization_units hou,
               hr_organization_information hoi
         WHERE hou.organization_id = hoi.organization_id
           AND hoi.org_information_context = 'CLASS'
           AND hoi.org_information1 = 'INV'
           AND hoi.org_information2 = 'Y'
           AND hou.attribute1 = to_char(p_legacy_loc_id) ;

           RETURN (lv_organization_id) ;


  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_organization_id := null ;
         RETURN (lv_organization_id) ;
    WHEN TOO_MANY_ROWS THEN
      lv_organization_id := null ;
         RETURN (lv_organization_id) ;
    WHEN OTHERS THEN
    RAISE ;
END get_ebs_organization_id;
-- +===================================================================+
-- | Name  : get_legacy_loc_id                                         |
-- | Description      : This Function will be used to fetch legacy     |
-- |                    location id                                    |
-- | Parameters :       ebs organization id                            |
-- | Returns :          legacy loc id                                  |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  FUNCTION get_legacy_loc_id (p_ebs_org_id  IN NUMBER
                                    )
  RETURN NUMBER
  IS

    lv_legacy_loc_id NUMBER;

  BEGIN

        SELECT TO_NUMBER(hou.attribute1)
          INTO lv_legacy_loc_id
          FROM hr_all_organization_units hou,
               hr_organization_information hoi
         WHERE hou.organization_id = hoi.organization_id
           AND hoi.org_information_context = 'CLASS'
           AND hoi.org_information1 = 'INV'
           AND hoi.org_information2 = 'Y'
           AND hou.organization_id = p_ebs_org_id ;

          RETURN (lv_legacy_loc_id) ;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_legacy_loc_id := null ;
      RETURN (lv_legacy_loc_id) ;
    WHEN TOO_MANY_ROWS THEN
      lv_legacy_loc_id := null ;
      RETURN (lv_legacy_loc_id) ;
    WHEN OTHERS THEN
      RAISE ;

  END get_legacy_loc_id;
-- +===================================================================+
-- | Name  : get_inventory_item_id                                     |
-- | Description      : This Function will be used to fetch Oracle EBS |
-- |                    Inventory Item id                              |
-- | Parameters :       SKU Number                                     |
-- |                    ebs organization id                            |
-- | Returns :          oracle Inventory Item id                       |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-MAY-2007  Rama Dwibhashyam Initial draft version       |
-- +===================================================================+
  FUNCTION get_inventory_item_id (p_sku  IN VARCHAR2,
                                  p_org_id IN NUMBER
                                    )
  RETURN NUMBER
  IS
     lv_inventory_item_id NUMBER ;
  BEGIN

        SELECT inventory_item_id
          INTO lv_inventory_item_id
          FROM mtl_system_items_b
         WHERE organization_id = p_org_id
           AND segment1        = p_sku
           AND mtl_transactions_enabled_flag = 'Y';

    RETURN (lv_inventory_item_id) ;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      lv_inventory_item_id := null ;
      RETURN (lv_inventory_item_id) ;
    WHEN TOO_MANY_ROWS THEN
      lv_inventory_item_id := null ;
      RETURN (lv_inventory_item_id) ;
    WHEN OTHERS THEN
      RAISE ;

  END get_inventory_item_id ;
--

END xx_gi_comn_utils_pkg;
