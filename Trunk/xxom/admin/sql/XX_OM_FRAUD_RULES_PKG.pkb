CREATE OR REPLACE 
PACKAGE BODY xx_om_fraud_rules_pkg AS


-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_FRAUD_RULES_PKG.pkb                                       |
-- | Description      : This Program will load all fraud data  from          |
-- |                    Legacy System into EBIZ                              |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==========================    |
-- |DRAFT 1A   03-SEP-07     Bapuji Nanapaneni Initial Draft Version         |
-- +=========================================================================+
  -- +===================================================================+
  -- | Name  : get_data                                                  |
  -- | Description     : To Fetch Record by Record info from flat file   |
  -- |                                                                   |
  -- | Parameters      : p_file_name         IN -> pass name of file     |
  -- |                   x_status           OUT -> x_status              |
  -- |                   x_message          OUT -> x_message             |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE get_data( 
                      x_status    OUT  NOCOPY  VARCHAR2
                    , x_message   OUT  NOCOPY  VARCHAR2
                    , p_file_name  IN          VARCHAR2
                    ) IS

    lc_input_file_handle        UTL_FILE.file_type;
    lc_file_path                VARCHAR2(100) := FND_PROFILE.VALUE('XX_OM_SAS_FILE_DIR');
    lc_curr_line                VARCHAR2(700);  --666
    lb_has_records              BOOLEAN;
    i                           BINARY_INTEGER;
    lc_ret_code                 VARCHAR2(3);
    lc_errbuf                   VARCHAR2(1000);
    lc_status                   VARCHAR2(20);
    lc_message                  VARCHAR2(2000);

  BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Name 1  : ' || p_file_name);
      BEGIN
          gc_file_name := p_file_name||'.txt';

          /* Concurrent Request Id */
          FND_PROFILE.GET('CONC_REQUEST_ID',gn_request_id);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start Procedure ');
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Path : ' || lc_file_path);
          FND_FILE.PUT_LINE(FND_FILE.LOG, 'File Name : ' || gc_file_name);

         -- Open the file
          lc_input_file_handle := UTL_FILE.fopen(lc_file_path, gc_file_name, 'R',1000);
      
      --x_status := 'S';
      EXCEPTION
          WHEN UTL_FILE.invalid_path THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file Path: ' || SQLERRM);
              RAISE FND_API.G_EXC_ERROR;
          WHEN UTL_FILE.invalid_mode THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid Mode: ' || SQLERRM);
              RAISE FND_API.G_EXC_ERROR;
          WHEN UTL_FILE.invalid_filehandle THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Invalid file handle: ' || SQLERRM);
              RAISE FND_API.G_EXC_ERROR;
          WHEN UTL_FILE.invalid_operation THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'File does not exist: ' || SQLERRM);
              RETURN;
          WHEN UTL_FILE.read_error THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Read Error: ' || SQLERRM);
              RAISE FND_API.G_EXC_ERROR;
          WHEN UTL_FILE.internal_error THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Internal Error: ' || SQLERRM);
              RAISE FND_API.G_EXC_ERROR;
          WHEN NO_DATA_FOUND THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Empty File: ' || SQLERRM);
              RETURN;
          WHEN VALUE_ERROR THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value Error: ' || SQLERRM);
              RAISE FND_API.G_EXC_ERROR;
          WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG, SQLERRM);
              UTL_FILE.fclose (lc_input_file_handle);
              RAISE FND_API.G_EXC_ERROR;
      END;

  lb_has_records := TRUE;
  i := 0;

      BEGIN
          --x_status := 'S';
          LOOP
              BEGIN
             --   x_status := 'S';
                lc_curr_line := NULL;
                    /* UTL FILE READ START */
                    UTL_FILE.GET_LINE(lc_input_file_handle,lc_curr_line);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'lc_curr_line ::'||lc_curr_line);
              EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'NO MORE RECORDS TO READ');
                      lb_has_records := FALSE;
                      EXIT;
                      --RAISE FND_API.G_RET_STS_SUCCESS;
                  WHEN OTHERS THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while reading'||sqlerrm);
                      lb_has_records := FALSE;
                      RAISE FND_API.G_EXC_ERROR;
              END;
            i := i + 1;
            lc_curr_line := substr(lc_curr_line,1,700);
            gc_line_tbl(i).curr_line := lc_curr_line;

          END LOOP;
      EXCEPTION
          WHEN OTHERS THEN
              ROLLBACK;
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process :'||substr(SQLERRM,1,80));
      END;

      BEGIN
          /* Calling Faaud Data to Stg Proc */
          fraud_data_to_stg( p_curr_line => gc_line_tbl
                           , x_status    => lc_status
                           , x_message  => lc_message
                           );

      END;
  EXCEPTION
      WHEN OTHERS THEN
          ROLLBACK;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error in Process :'||substr(SQLERRM,1,80));
  END get_data;

  -- +===================================================================+
  -- | Name  : fraud_data_to_stg                                         |
  -- | Description     : The fetch record is read column by colum and    |
  -- |                   inserted in to stagging table                   |
  -- |                                                                   |
  -- | Parameters      : p_curr_line         IN -> pass the current line |
  -- |                                             read from get data    |
  -- |                   x_status           OUT -> x_status              |
  -- |                   x_message          OUT -> x_message             |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE fraud_data_to_stg (
                                p_curr_line  IN curr_line_tbl_type
                              , x_status    OUT NOCOPY VARCHAR2
                              , x_message   OUT NOCOPY VARCHAR2
                              ) IS

    lc_cc_number_enc   oe_payments.credit_card_number%TYPE;
    lc_cc_number_dec   oe_payments.credit_card_number%TYPE;
    lc_customer_num    hz_cust_accounts.cust_account_id%TYPE;
    lc_customer_name   hz_parties.party_name%TYPE;
    lc_hash_account    VARCHAR2(100);
    lc_encrypt_key     VARCHAR2(100);
    lc_err_msg         VARCHAR2(2000);
    lc_item_class      mtl_categories_b.segment4%TYPE;

  BEGIN

      FOR k IN 1..p_curr_line.COUNT LOOP

        gn_org_id      := FND_PROFILE.VALUE('ORG_ID');

        /* sequence call for condition_id */
        SELECT xxom.xx_om_condition_id_s.NEXTVAL INTO gn_condition_id FROM DUAL;

        gc_file_line_rec.condition_id(k)             := gn_condition_id;
            BEGIN
                Initialize_record(gc_file_line_rec.condition_id.count);
            END;
  --      gn_request_id := 111;

        gc_file_line_rec.request_id(k)               := gn_request_id;
        gc_file_line_rec.ord_amt(k)                  := TRIM(SUBSTR(p_curr_line(k).curr_line, 274,12));
        gc_file_line_rec.ship_address1(k)            := TRIM(SUBSTR(p_curr_line(k).curr_line,  17,25));
        gc_file_line_rec.ship_address2(k)            := TRIM(SUBSTR(p_curr_line(k).curr_line,  42,25));
        gc_file_line_rec.ship_city(k)                := TRIM(SUBSTR(p_curr_line(k).curr_line,  67,25));
        gc_file_line_rec.ship_state(k)               := TRIM(SUBSTR(p_curr_line(k).curr_line,  92, 2));
        gc_file_line_rec.ship_zip_code(k)            := TRIM(SUBSTR(p_curr_line(k).curr_line,   6,11));
        gc_file_line_rec.ship_country(k)             := 'USA'; -- LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        lc_customer_num                              := TRIM(SUBSTR(p_curr_line(k).curr_line,  94,8));
        lc_customer_name                             := TRIM(SUBSTR(p_curr_line(k).curr_line, 102,25));
        gc_file_line_rec.email(k)                    := TRIM(SUBSTR(p_curr_line(k).curr_line, 301,100));
        --  gc_file_line_rec.email_domain(k)             := TRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        gc_file_line_rec.bill_address1(k)            := TRIM(SUBSTR(p_curr_line(k).curr_line, 179,25));
        gc_file_line_rec.bill_address2(k)            := TRIM(SUBSTR(p_curr_line(k).curr_line, 204,25));
        gc_file_line_rec.bill_city(k)                := TRIM(SUBSTR(p_curr_line(k).curr_line, 229,25));
        gc_file_line_rec.bill_state(k)               := TRIM(SUBSTR(p_curr_line(k).curr_line, 254, 2));
        gc_file_line_rec.bill_zip_code(k)            := TRIM(SUBSTR(p_curr_line(k).curr_line, 256,11));
        gc_file_line_rec.bill_country(k)             := 'USA'; --LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        --  gc_file_line_rec.customer_date_check_rtl(k)  := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        --  gc_file_line_rec.customer_date_check_con(k)  := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        gc_file_line_rec.ip_address(k)               := TRIM(SUBSTR(p_curr_line(k).curr_line, 401,25));
        --  gc_file_line_rec.item(k)                     := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        --  gc_file_line_rec.item_class(k)               := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        --  gc_file_line_rec.item_quantity(k)            := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        lc_cc_number_enc                             := TRIM(SUBSTR(p_curr_line(k).curr_line, 157,20));
        lc_hash_account                              := TRIM(SUBSTR(p_curr_line(k).curr_line, 591,20));
        lc_encrypt_key                               := TRIM(SUBSTR(p_curr_line(k).curr_line, 611,25));
        gc_file_line_rec.credit_card_type(k)         := TRIM(SUBSTR(p_curr_line(k).curr_line, 177, 2));
     --   gc_file_line_rec.account_first_6(k)          := TRIM(SUBSTR(p_curr_line(k).curr_line, 637, 6));
     --   gc_file_line_rec.account_last_4(k)           := TRIM(SUBSTR(p_curr_line(k).curr_line, 643, 4));
        gc_file_line_rec.ship_loc(k)                 := TRIM(SUBSTR(p_curr_line(k).curr_line, 286, 4));
        gc_file_line_rec.phone_num(k)                := TRIM(SUBSTR(p_curr_line(k).curr_line, 290,11));
        --  gc_file_line_rec.hold_count(k)               := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        --  gc_file_line_rec.accepted_count(k)           := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        gc_file_line_rec.del_flag(k)                 := TRIM(SUBSTR(p_curr_line(k).curr_line, 566, 1));
        --  gc_file_line_rec.appl_flag(k)                := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        --  gc_file_line_rec.condition_name(k)           := LTRIM(SUBSTR(p_curr_line(k).curr_line, 296,12));
        lc_item_class                                := TRIM(SUBSTR(p_curr_line(k).curr_line, 667,3));


        BEGIN
            /* Validate Customer Number */
            IF lc_customer_num IS NULL THEN
                gc_file_line_rec.customer_num(k) := NULL;
            ELSE
                gc_file_line_rec.customer_num(k) := customer_number(lc_customer_num);
                IF gc_file_line_rec.customer_num(k) IS NULL THEN
                   gc_file_line_rec.customer_num(k) := lc_customer_num;
                   gc_file_line_rec.error_flag(k)   := 'Y';
                       gc_entity_ref        := 'CONDITION_ID';
                       gn_entity_ref_id     := gc_file_line_rec.condition_id(k);
                       FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_CUSTACCT_DERIVATION');
                       FND_MESSAGE.SET_TOKEN('ATTRIBUTE1', gc_file_line_rec.customer_num(k) );
                       gc_error_description:= FND_MESSAGE.GET;
                       gc_error_code       := 'Fraud Rule NOT Valid';
                       gc_file_line_rec.error_description(k) := gc_error_description;
                        /* calling log_exceptions procedure to store exceptions */
                        log_exceptions;
                END IF;
            END IF;
        END;

        BEGIN
            /* Validate Customer Name */
            IF lc_customer_name IS NULL THEN
                gc_file_line_rec.customer_name(k) := NULL;
            ELSE
                gc_file_line_rec.customer_name(k) := customer_name(lc_customer_name);
                IF gc_file_line_rec.customer_name(k) IS NULL THEN
                    gc_file_line_rec.customer_name(k) := lc_customer_name;
                    gc_file_line_rec.error_flag(k) := 'Y';

                     gc_entity_ref        := 'CONDITION_ID';
                     gn_entity_ref_id     := gc_file_line_rec.condition_id(k);
                     FND_MESSAGE.SET_NAME('XXOM','XX_OM_FAIL_CUSTACCT_DERIVATION');
                     FND_MESSAGE.SET_TOKEN('ATTRIBUTE1', gc_file_line_rec.customer_name(k) );
                     gc_error_description:= FND_MESSAGE.GET;
                     gc_error_code       := 'Fraud Rule NOT Valid';
                     gc_file_line_rec.error_description(k) := gc_error_description;
                     /* calling log_exceptions procedure to store exceptions */
                     log_exceptions;
                END IF;
            END IF;
        END;

        IF lc_cc_number_enc IS NOT NULL THEN
            /* Decrypeting credit API call*/
--            XX_OD_SECURITY_KEY_PKG.DECRYPT( p_module          => 'HVOP'
--                                          , p_key_label       => lc_encrypt_key
--                                          , p_encrypted_val   => lc_cc_number_enc
--                                          , p_format          => 'EBCDIC'
--                                          , x_decrypted_val   => lc_cc_number_dec
--                                          , x_error_message   => lc_err_msg
--                                          );

            /* Encrypeting credit API call*/
--            gc_file_line_rec.account_first_6(k)      := SUBSTR(TRIM(lc_cc_number_enc), -6 ,6);
--            gc_file_line_rec.account_last_4(k)       := SUBSTR(TRIM(lc_cc_number_enc),  1 ,4);
--            gc_file_line_rec.credit_card_num(k)      := lc_cc_number_enc; --iby_cc_security_pub.secure_card_number('T', lc_cc_number_dec);
            gc_file_line_rec.credit_card_num(k)        := lc_cc_number_enc;-- iby_cc_security_pub.secure_card_number('T', lc_cc_number_enc);
            gc_file_line_rec.account_first_6(k)      := SUBSTR(TRIM(lc_cc_number_enc), -6 ,6);
            gc_file_line_rec.account_last_4(k)       := SUBSTR(TRIM(lc_cc_number_enc),  1 ,4);
        ELSE
            gc_file_line_rec.credit_card_num(k)      := NULL;
            gc_file_line_rec.account_first_6(k)      := NULL; --LTRIM(SUBSTR(gc_line_tbl(k), 636, 6));
            gc_file_line_rec.account_last_4(k)       := NULL; --LTRIM(SUBSTR(gc_line_tbl(k), 642, 4));

        END IF;

        IF gc_file_line_rec.ship_address1(k) IS NOT NULL OR
           gc_file_line_rec.bill_address1(k) IS NOT NULL OR
           gc_file_line_rec.phone_num(k)     IS NOT NULL OR
           gc_file_line_rec.credit_card_num(k) IS NOT NULL OR
           gc_file_line_rec.ship_zip_code(k) IS NOT NULL THEN

          gc_file_line_rec.appl_flag(k) :=  appl_flag(
                                                    p_ship_address  => gc_file_line_rec.ship_address1(k)
                                                  , p_bill_address  => gc_file_line_rec.bill_address1(k)
                                                  , p_phone         => gc_file_line_rec.phone_num(k)
                                                  , p_cc_number     => gc_file_line_rec.credit_card_num(k)
                                                  , p_zip_code      => gc_file_line_rec.ship_zip_code(k)
                                                  );
        ELSE
             gc_file_line_rec.appl_flag(k) := NULL;
        END IF;

        IF lc_item_class IS NOT NULL THEN
            gc_file_line_rec.item_class(k)       := get_item_class(lc_item_class);
        ELSE
            gc_file_line_rec.item_class(k) := NULL;
        END IF;

      END LOOP;

      BEGIN
          /* Calling insert_data Procedure */
          insert_data;

          BEGIN
              /* Calling fraud_data_to_base_table Procedure */
              fraud_data_to_base_table;
              COMMIT;
              BEGIN
                  purge_stagging( p_request_id => gn_request_id);
              --    clear_memory;
              EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found');
                  WHEN OTHERS THEN
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting records into xx_om_fraud_rules_stg :'||SUBSTR(SQLERRM,1,80));
              RAISE FND_API.G_EXC_ERROR;
              END;
          END;

      EXCEPTION
          WHEN NO_DATA_FOUND THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'No Data Found at insert data call');
          WHEN OTHERS THEN
               FND_FILE.PUT_LINE(FND_FILE.LOG,'OTHERS at insert data call::'||SUBSTR(SQLERRM,1,200));
      END;

  END fraud_data_to_stg;

  -- +===================================================================+
  -- | Name  : insert_data                                               |
  -- | Description     : To Insert data into xx_om_fraud_rules_stg table |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE insert_data IS

  BEGIN
    FORALL cr_rec IN gc_file_line_rec.condition_id.FIRST.. gc_file_line_rec.condition_id.LAST

       /* Insert  records from flat file to stagging */
        INSERT INTO xx_om_fraud_rules_stg
            (  org_id
            ,  condition_id
            ,  ord_amt
            ,  ship_address1
            ,  ship_address2
            ,  ship_city
            ,  ship_state
            ,  ship_zip_code
            ,  ship_country
            ,  customer_num
            ,  customer_name
            ,  email
    --        ,  email_domain
            ,  bill_address1
            ,  bill_address2
            ,  bill_city
            ,  bill_state
            ,  bill_zip_code
            ,  bill_country
            ,  ip_address
            ,  credit_card_num
            ,  credit_card_type
            ,  account_first_6
            ,  account_last_4
            ,  phone_num
            ,  created_by
            ,  creation_date
            ,  last_updated_by
            ,  last_update_date
            ,  request_id
            ,  error_flag
      --      ,  customer_date_check_rtl
      --      ,  customer_date_check_con
      --      ,  item
            ,  item_class
      --      ,  item_quantity
      --      ,  hold_count
      --      ,  accepted_count
      --      ,  del_flag
            ,  appl_flag
              ,  ship_location
              ,  error_description
            )  VALUES
            (  gn_org_id
            ,  gc_file_line_rec.condition_id(cr_rec)
            ,  gc_file_line_rec.ord_amt(cr_rec)
            ,  gc_file_line_rec.ship_address1(cr_rec)
            ,  gc_file_line_rec.ship_address2(cr_rec)
            ,  gc_file_line_rec.ship_city(cr_rec)
            ,  gc_file_line_rec.ship_state(cr_rec)
            ,  gc_file_line_rec.ship_zip_code(cr_rec)
            ,  gc_file_line_rec.ship_country(cr_rec)
            ,  gc_file_line_rec.customer_num(cr_rec)
            ,  gc_file_line_rec.customer_name(cr_rec)
            ,  gc_file_line_rec.email(cr_rec)
     --       ,  gc_file_line_rec.email_domain(cr_rec)
            ,  gc_file_line_rec.bill_address1(cr_rec)
            ,  gc_file_line_rec.bill_address2(cr_rec)
            ,  gc_file_line_rec.bill_city(cr_rec)
            ,  gc_file_line_rec.bill_state(cr_rec)
            ,  gc_file_line_rec.bill_zip_code(cr_rec)
            ,  gc_file_line_rec.bill_country(cr_rec)
            ,  gc_file_line_rec.ip_address(cr_rec)
            ,  gc_file_line_rec.credit_card_num(cr_rec)
            ,  gc_file_line_rec.credit_card_type(cr_rec)
            ,  gc_file_line_rec.account_first_6(cr_rec)
            ,  gc_file_line_rec.account_last_4(cr_rec)
            ,  gc_file_line_rec.phone_num(cr_rec)
            ,  FND_GLOBAL.USER_ID
            ,  SYSDATE
            ,  FND_GLOBAL.USER_ID
            ,  SYSDATE
            ,  gc_file_line_rec.request_id(cr_rec)
            ,  gc_file_line_rec.error_flag(cr_rec)
      --      ,  gc_file_line_rec.customer_date_check_rtl(cr_rec)
      --      ,  gc_file_line_rec.customer_date_check_con(cr_rec)
      --      ,  gc_file_line_rec.item(cr_rec)
            ,  gc_file_line_rec.item_class(cr_rec)
      --      ,  gc_file_line_rec.item_quantity(cr_rec)
      --      ,  gc_file_line_rec.hold_count(cr_rec)
      --      ,  gc_file_line_rec.accepted_count(cr_rec)
      --      ,  gc_file_line_rec.del_flag(cr_rec)
            ,  gc_file_line_rec.appl_flag(cr_rec)
              ,  gc_file_line_rec.ship_loc(cr_rec)
              ,  gc_file_line_rec.error_description(cr_rec)
            );
  COMMIT;

  EXCEPTION
      WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in inserting records into xx_om_fraud_rules_stg :'||SUBSTR(SQLERRM,1,80));
              RAISE FND_API.G_EXC_ERROR;
  END insert_data;

  -- +===================================================================+
  -- | Name  : Log_exceptions                                            |
  -- | Description     : To Log Exceptions by calling this procedure     |
  -- |                                                                   |
  -- | Parameters      : p_index                                         |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE Initialize_record(p_index BINARY_INTEGER) IS

  BEGIN

      /* Initialize gc_file_line_rec record */
      gc_file_line_rec.i_count(p_index)                  := NULL;
      gc_file_line_rec.ord_amt(p_index)                  := NULL;
      gc_file_line_rec.ship_address1(p_index)            := NULL;
      gc_file_line_rec.ship_address2(p_index)            := NULL;
      gc_file_line_rec.ship_city(p_index)                := NULL;
      gc_file_line_rec.ship_state(p_index)               := NULL;
      gc_file_line_rec.ship_zip_code(p_index)            := NULL;
      gc_file_line_rec.ship_country(p_index)             := NULL;
      gc_file_line_rec.customer_num(p_index)             := NULL;
      gc_file_line_rec.customer_name(p_index)            := NULL;
      gc_file_line_rec.email(p_index)                    := NULL;
      gc_file_line_rec.email_domain(p_index)             := NULL;
      gc_file_line_rec.bill_address1(p_index)            := NULL;
      gc_file_line_rec.bill_address2(p_index)            := NULL;
      gc_file_line_rec.bill_city(p_index)                := NULL;
      gc_file_line_rec.bill_state(p_index)               := NULL;
      gc_file_line_rec.bill_zip_code(p_index)            := NULL;
      gc_file_line_rec.bill_country(p_index)             := NULL;
      gc_file_line_rec.customer_date_check_rtl(p_index)  := NULL;
      gc_file_line_rec.customer_date_check_con(p_index)  := NULL;
      gc_file_line_rec.ip_address(p_index)               := NULL;
      gc_file_line_rec.item(p_index)                     := NULL;
      gc_file_line_rec.item_class(p_index)               := NULL;
      gc_file_line_rec.item_quantity(p_index)            := NULL;
      gc_file_line_rec.credit_card_num(p_index)          := NULL;
      gc_file_line_rec.credit_card_type(p_index)         := NULL;
      gc_file_line_rec.hash_account(p_index)             := NULL;
      gc_file_line_rec.encrypt_key(p_index)              := NULL;
      gc_file_line_rec.account_first_6(p_index)          := NULL;
      gc_file_line_rec.account_last_4(p_index)           := NULL;
      gc_file_line_rec.phone_num(p_index)                := NULL;
      gc_file_line_rec.hold_count(p_index)               := NULL;
      gc_file_line_rec.accepted_count(p_index)           := NULL;
      gc_file_line_rec.del_flag(p_index)                 := NULL;
      gc_file_line_rec.appl_flag(p_index)                := NULL;
      gc_file_line_rec.condition_name(p_index)           := NULL;
      gc_file_line_rec.ship_loc(p_index)                 := NULL;
      gc_file_line_rec.request_id(p_index)               := NULL;
      gc_file_line_rec.error_description(p_index)        := NULL;

  EXCEPTION
      WHEN OTHERS THEN
              FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed in Initialize records into xx_om_fraud_rules_stg :'||SUBSTR(SQLERRM,1,80));
              RAISE FND_API.G_EXC_ERROR;

  END Initialize_record;

  -- +===================================================================+
  -- | Name  : clear_memory                                              |
  -- | Description     : To Clear Memory in tbl type records for every   |
  -- |                    5000 records.                                  |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+
  PROCEDURE fraud_data_to_base_table IS
    BEGIN
    DBMS_OUTPUT.PUT_LINE('Calling fraud_data_to_base_table proc::');

        INSERT INTO xxom.xx_om_fraud_rules
            (  org_id
            ,  condition_id
            ,  ord_amt
            ,  ship_address1
            ,  ship_address2
            ,  ship_city
            ,  ship_state
            ,  ship_zip_code
            ,  ship_country
            ,  customer_num
            ,  customer_name
            ,  email
            ,  email_domain
            ,  bill_address1
            ,  bill_address2
            ,  bill_city
            ,  bill_state
            ,  bill_zip_code
            ,  bill_country
            ,  ip_address
            ,  credit_card_num
            ,  credit_card_type
            ,  account_first_6
            ,  account_last_4
            ,  phone_num
            ,  customer_date_check_rtl
            ,  customer_date_check_con
            ,  item
            ,  item_class
            ,  item_quantity
            ,  appl_flag
            ,  del_flag
            ,  hold_count
            ,  accepted_count
            ,  hash_account
            ,  encrypt_key
            ,  created_by
            ,  creation_date
            ,  last_updated_by
            ,  last_update_date
            ,  request_id
            ,  ship_location
            )
      SELECT   org_id
            ,  condition_id
            ,  ord_amt
            ,  ship_address1
            ,  ship_address2
            ,  ship_city
            ,  ship_state
            ,  ship_zip_code
            ,  ship_country
            ,  customer_num
            ,  customer_name
            ,  email
            ,  email_domain
            ,  bill_address1
            ,  bill_address2
            ,  bill_city
            ,  bill_state
            ,  bill_zip_code
            ,  bill_country
            ,  ip_address
            ,  credit_card_num
            ,  credit_card_type
            ,  account_first_6
            ,  account_last_4
            ,  phone_num
            ,  customer_date_check_rtl
            ,  customer_date_check_con
            ,  item
            ,  item_class
            ,  item_quantity
            ,  appl_flag
            ,  del_flag
            ,  hold_count
            ,  accepted_count
            ,  hash_account
            ,  encrypt_key
            ,  created_by
            ,  creation_date
            ,  last_updated_by
            ,  last_update_date
            ,  request_id
            ,  ship_location
       FROM    xx_om_fraud_rules_stg
       WHERE   request_id = gn_request_id;
  EXCEPTION
      WHEN OTHERS THEN
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed to insert into "XX_OM_FRAUD_RULES" :'||SUBSTR(SQLERRM,1,80));
              RAISE FND_API.G_EXC_ERROR;
  END fraud_data_to_base_table;

  -- +===================================================================+
  -- | Name  : clear_memory                                              |
  -- | Description     : To delete all rows from stg tbl with error_flag |
  -- |                   is null or 'N'.                                 |
  -- |                                                                   |
  -- | Parameters      :                                                 |
  -- |                                                                   |
  -- +===================================================================+

 PROCEDURE clear_memory IS

  BEGIN
    /* clear record cache for every 5000 records*/
    gc_file_line_rec.i_count.DELETE;
    gc_file_line_rec.ord_amt.DELETE;
    gc_file_line_rec.ship_address1.DELETE;
    gc_file_line_rec.ship_address2.DELETE;
    gc_file_line_rec.ship_city.DELETE;
    gc_file_line_rec.ship_state.DELETE;
    gc_file_line_rec.ship_zip_code.DELETE;
    gc_file_line_rec.ship_country.DELETE;
    gc_file_line_rec.customer_num.DELETE;
    gc_file_line_rec.customer_name.DELETE;
    gc_file_line_rec.email.DELETE;
    gc_file_line_rec.email_domain.DELETE;
    gc_file_line_rec.bill_address1.DELETE;
    gc_file_line_rec.bill_address2.DELETE;
    gc_file_line_rec.bill_city.DELETE;
    gc_file_line_rec.bill_state.DELETE;
    gc_file_line_rec.bill_zip_code.DELETE;
    gc_file_line_rec.bill_country.DELETE;
    gc_file_line_rec.customer_date_check_rtl.DELETE;
    gc_file_line_rec.customer_date_check_con.DELETE;
    gc_file_line_rec.ip_address.DELETE;
    gc_file_line_rec.item.DELETE;
    gc_file_line_rec.item_class.DELETE;
    gc_file_line_rec.item_quantity.DELETE;
    gc_file_line_rec.credit_card_num.DELETE;
    gc_file_line_rec.credit_card_type.DELETE;
    gc_file_line_rec.hash_account.DELETE;
    gc_file_line_rec.encrypt_key.DELETE;
    gc_file_line_rec.account_first_6.DELETE;
    gc_file_line_rec.account_last_4.DELETE;
    gc_file_line_rec.phone_num.DELETE;
    gc_file_line_rec.hold_count.DELETE;
    gc_file_line_rec.accepted_count.DELETE;
    gc_file_line_rec.del_flag.DELETE;
    gc_file_line_rec.appl_flag.DELETE;
    gc_file_line_rec.condition_name.DELETE;
    gc_file_line_rec.request_id.DELETE;
    gc_file_line_rec.ship_loc.DELETE;
    gc_file_line_rec.error_description.DELETE;

  END clear_memory;

  -- +===================================================================+
  -- | Name  : log_exceptions                                            |
  -- | Description     : To log exceptions to xx_om_global_exceptions    |
  -- |                   table                                           |
  -- |                                                                   |
  -- | Parameters     :                                                  |
  -- +===================================================================+
  PROCEDURE log_exceptions IS
    xc_errbuf                    VARCHAR2(1000);
    xc_retcode                   VARCHAR2(40);

  BEGIN
      g_exception.p_error_code        := gc_error_code;
      g_exception.p_error_description := gc_error_description;
      g_exception.p_entity_ref        := gc_entity_ref;
      g_exception.p_entity_ref_id     := gn_entity_ref_id;

      BEGIN
          /* Processing Error Messages API call */
           XX_OM_GLOBAL_EXCEPTION_PKG.insert_exception( g_exception
                                                      , xc_errbuf
                                                      , xc_retcode
                                                     );
      END;
  END log_exceptions;

  -- +===================================================================+
  -- | Name  : customer_number                                           |
  -- | Description     : To validate customer_number by passing legacy   |
  -- |                   customer_number                                 |
  -- |                                                                   |
  -- | Parameters     : p_customer_number  IN -> pass legacy customer num|
  -- |                                                                   |
  -- | Return         : customer_number                                  |
  -- +===================================================================+

  FUNCTION customer_number (p_cust_number IN hz_cust_accounts.account_number%TYPE) RETURN VARCHAR2 IS
    lc_cust_number  hz_cust_accounts.account_number%TYPE;
  BEGIN
      /* Validating customer Number */
      SELECT account_number
        INTO lc_cust_number
        FROM hz_cust_accounts
       WHERE orig_system_reference = p_cust_number;

      RETURN(lc_cust_number);
  EXCEPTION
      WHEN OTHERS THEN
          RETURN NULL;
  END customer_number;

  -- +===================================================================+
  -- | Name  : customer_name                                             |
  -- | Description     : To validate customer_name  by passing legacy    |
  -- |                   customer name                                   |
  -- |                                                                   |
  -- | Parameters     : p_customer_name  IN -> pass legacy customer name |
  -- |                                                                   |
  -- | Return         : customer_name                                    |
  -- +===================================================================+

  FUNCTION customer_name (p_cust_name IN hz_parties.party_name%TYPE) RETURN VARCHAR2 IS
    lc_cust_name  hz_parties.party_name%TYPE;
  BEGIN
     /*Validating customer Name */
      SELECT party_name
        INTO lc_cust_name
        FROM hz_parties
       WHERE UPPER(party_name) = UPPER(p_cust_name);

      RETURN(lc_cust_name);
  EXCEPTION
      WHEN OTHERS THEN
          RETURN NULL;
  END customer_name;

  -- +===================================================================+
  -- | Name  : appl_flag                                                 |
  -- | Description     : To validate if any one column is not null in all|
  -- |                   parameters passed to function and return Y or N |
  -- |                                                                   |
  -- | Parameters     : p_ship_address  IN -> pass ship_address1         |
  -- |                  p_bill_address  IN -> pass bill_address1         |
  -- |                  p_phome         IN -> pass phone Number          |
  -- |                  p_cc_number     IN -> pass credit card num       |
  -- |                  p_zip_code      IN -> pass ship zip code         |
  -- |                                                                   |
  -- | Return         : 'Y' or 'N' for appl_flag                         |
  -- +===================================================================+

  FUNCTION appl_flag
      (  p_ship_address IN xxom.xx_om_fraud_rules.ship_address1%TYPE
      ,  p_bill_address IN xxom.xx_om_fraud_rules.bill_address1%TYPE
      ,  p_phone        IN xxom.xx_om_fraud_rules.phone_num%TYPE
      ,  p_cc_number    IN xxom.xx_om_fraud_rules.credit_card_num%TYPE
      ,  p_zip_code     IN xxom.xx_om_fraud_rules.ship_zip_code%TYPE
      )  RETURN VARCHAR2 IS

  lc_app_flag   VARCHAR2(1) := 'Y';
  lc_input      VARCHAR2(240);
  BEGIN

      SELECT NVL(NVL(NVL(NVL(p_ship_address,p_bill_address),p_phone),p_cc_number),p_zip_code)
        INTO lc_input FROm DUAL;

      IF lc_input IS NOT NULL THEN
          lc_app_flag := 'Y';
      ELSE
          lc_app_flag := 'N';
      END IF;

      RETURN(lc_app_flag);

  EXCEPTION
      WHEN NO_DATA_FOUND THEN
          lc_app_flag := NULL;
              RETURN (lc_app_flag);
      WHEN OTHERS THEN
          lc_app_flag := NULL;
              RETURN(lc_app_flag);
  END appl_flag;

  -- +===================================================================+
  -- | Name  : get_item_class                                            |
  -- | Description     : To validate item_class by passing legacy item   |
  -- |                   class                                           |
  -- |                                                                   |
  -- | Parameters     : p_item_class  IN -> pass legacy item_class       |
  -- |                                                                   |
  -- | Return         : item class in oracle                             |
  -- +===================================================================+

  FUNCTION get_item_class (p_item_class IN  VARCHAR2) RETURN VARCHAR2 IS

  lc_item_class mtl_categories_b.segment4%TYPE;

  BEGIN

      SELECT DISTINCT segment4
        INTO lc_item_class
        FROM mtl_categories_b
       WHERE segment4 = p_item_class;

       RETURN(lc_item_class);
  EXCEPTION
      WHEN NO_DATA_FOUND THEN
          lc_item_class := NULL;
              RETURN (lc_item_class);
      WHEN OTHERS THEN
          lc_item_class := NULL;
              RETURN(lc_item_class);

  END get_item_class;

  -- +===================================================================+
  -- | Name  : purge_stagging                                            |
  -- | Description     : To delete all rows from stg tbl with error_flag |
  -- |                   is null or 'N'.                                 |
  -- |                                                                   |
  -- | Parameters      : p_request_id       IN -> request_id             |
  -- |                   x_status           OUT -> x_status              |
  -- |                   x_message          OUT -> x_message             |
  -- |                                                                   |
  -- +===================================================================+

  PROCEDURE purge_stagging(p_request_id IN VARCHAR2) IS
  BEGIN
     /* Purging data for all sucessful records from stagging tbl*/
      DELETE FROM xx_om_fraud_rules_stg
            WHERE request_id = p_request_id
              AND NVL(error_flag, 'N') = 'N';

  END purge_stagging;

  -- +====================================================================+
  -- | Name  : fetch_rename_file                                          |
  -- | Description     : To rename file name once the process is completed|
  -- |                                                                    |
  -- |                                                                    |
  -- | Parameters      : p_file_name        IN -> file_name               |
  -- |                   p_filepath        OUT -> file_path               |
  -- |                                                                    |
  -- +====================================================================+
  PROCEDURE fetch_rename_file
      (  p_file_name IN VARCHAR2
      ,  p_file_path IN VARCHAR2
      )  IS

  BEGIN
      /* Renaming the file name after insering records  into xx_om_fraud_rules sucessfully */
      UTL_FILE.FRENAME
          (  p_file_path
          ,  p_file_name
          ,  p_file_path
          , 'Archive_'||p_file_name
          ,  TRUE
          );
      UTL_FILE.FREMOVE
          (  p_file_path
          ,  p_file_name
          );
  EXCEPTION
      WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Failed Renaming file :'||SUBSTR(SQLERRM,1,80));
              RAISE FND_API.G_EXC_ERROR;

  END fetch_rename_file;

END xx_om_fraud_rules_pkg;
/
SHOW ERRORS PACKAGE BODY XX_OM_FRAUD_RULES_PKG;
EXIT;

