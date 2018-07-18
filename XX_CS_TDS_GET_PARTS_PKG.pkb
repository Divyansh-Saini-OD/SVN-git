create or replace
PACKAGE BODY xx_cs_tds_get_parts_pkg
AS
-- +=============================================================================================+
-- |                       Oracle GSD  (India)                                                   |
-- |                        Hyderabad  India                                                     |
-- +=============================================================================================+
-- | Name         : xx_cs_tds_get_parts_pkg.pks                                                 |
-- | Description  : This package is used to validate the data passed and Interface the item      |
-- |                using API,Assign to required Inventory Organization, Add to the category,    |
-- |                Approved Supplier List and to Sourcing rule set.                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |DRAFT 1A  15-Jul-2011  Sreenivasa Tirumala  Initial draft version                            |
-- |V1.1      19-Aug-2011  Sreenivasa Tirumala  Added Sort condition to Get_Order_List Cursor.   |
-- |V1.2      22-JAN-2012  Vasu Raparla         Removed schema References for R.12.2             |                                                                                           |
-- |                                                                                             |
-- |                                                                                             |
-- +=============================================================================================+
-- Global Variables
    gn_request_number   VARCHAR2 (25);
    gn_user_id          NUMBER          := fnd_global.user_id;
    gn_login_id         NUMBER          := fnd_global.login_id;
    gn_no_of_lines      NUMBER          := 0;
    gn_sub_total        NUMBER          := 0;
    gn_total            NUMBER          := 0;
    gv_special_instr    VARCHAR2 (4000);

    -- Log Exception Procedure is a common utility procedure which would
    -- be used accross the program to log the errors.
    PROCEDURE log_exception (
        p_object_id            IN   VARCHAR2
      , p_error_location       IN   VARCHAR2
      , p_error_message_code   IN   VARCHAR2
      , p_error_msg            IN   VARCHAR2
    )
    IS
    BEGIN
        xx_com_error_log_pub.log_error (p_return_code                  => fnd_api.g_ret_sts_error
                                      , p_msg_count                    => 1
                                      , p_application_name             => 'XX_CRM'
                                      , p_program_type                 => 'Custom Messages'
                                      , p_program_name                 => 'XX_CS_TDS_GET_PARTS_PKG'
                                      , p_program_id                   => NULL
                                      , p_object_id                    => p_object_id
                                      , p_module_name                  => 'CSF_PARTS'
                                      , p_error_location               => p_error_location
                                      , p_error_message_code           => p_error_message_code
                                      , p_error_message                => p_error_msg
                                      , p_error_message_severity       => 'MAJOR'
                                      , p_error_status                 => 'ACTIVE'
                                      , p_created_by                   => gn_user_id
                                      , p_last_updated_by              => gn_user_id
                                      , p_last_update_login            => gn_login_id
                                       );
    END log_exception;

    -- Order_Details Procedure is the main procedure which would be Called from the GMILL Page
    -- to return the Customer Related Service Request Information
    PROCEDURE order_details (
        p_sr_number            IN       VARCHAR2
      , p_tds_parts_hdr_rec    IN OUT   xx_cs_tds_parts_hdr_rec
      , p_tds_parts_line_tbl   IN OUT   xx_cs_tds_parts_lines_tbl
      , x_return_status        OUT      VARCHAR2
      , x_msg_data             OUT      VARCHAR2
    )
    IS
        -- Cursor which derives the Incident ID based on the Service Request Number Passed.
        CURSOR c_incident_id
        IS
            SELECT incident_id
            FROM   cs_incidents_all_b
            WHERE  incident_number = p_sr_number
            and    exists ( select 1 from  xx_cs_tds_parts
            WHERE  request_number = cs_incidents_all_b.incident_number);

        -- Local Variables.
        ln_incident_id     NUMBER;
        lv_return_status   VARCHAR2 (1);
        lv_message_data    VARCHAR2 (4000);

    BEGIN
        -- Initialization of the Required Variables.
        gn_request_number := p_sr_number;
        x_return_status := fnd_api.g_ret_sts_success;

        ----DBMS_OUTPUT.put_line ('order_details-1:' || gn_request_number);
        OPEN c_incident_id;

        FETCH c_incident_id
        INTO  ln_incident_id;

        -- If Incident Id is not derived using the SR number provided
        -- then the procedure logs the error and sets return status to 'Error'
        IF c_incident_id%NOTFOUND
        THEN
            ----DBMS_OUTPUT.put_line ('order_details-2:');
            x_msg_data := 'No Incident Id Derived for the Request Number Provided ';
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.ORDER_DETAILS'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR2'
                         , p_error_msg                => x_msg_data
                          );
        END IF;

        CLOSE c_incident_id;

        ----DBMS_OUTPUT.put_line ('order_details-3:' || ln_incident_id);
        -- If Condition to proceed if Incident Id is derived.
        IF ln_incident_id IS NOT NULL
        THEN
            ----DBMS_OUTPUT.put_line ('order_details-4:');
            -- Firstly, based on the SR Number,All the item details
            -- would be collected and passed back to the calling program.
            get_line (gn_request_number
                    , p_tds_parts_line_tbl
                    , lv_return_status
                    , lv_message_data
                     );

            -- Based on the Return Status of GET_LINE procedure
            -- the return status of the program would be assigned.
            IF lv_return_status IS NOT NULL
            THEN
                x_return_status := lv_return_status;
                x_msg_data := lv_message_data;
            END IF;

            ----DBMS_OUTPUT.put_line ('x_return_status-get_line:' || x_return_status);
            ----DBMS_OUTPUT.put_line ('order_details-6:');
            -- Secondly Based on the Incident ID Derived, Header
            -- Level information of the Service Request would be provided.
            get_header (ln_incident_id
                      , p_tds_parts_hdr_rec
                      , lv_return_status
                      , lv_message_data
                       );

            -- Based on the Return Status of GET_HEADER procedure
            -- the return status of the program would be assigned.
            IF lv_return_status IS NOT NULL
            THEN
                x_return_status := lv_return_status;
                x_msg_data := lv_message_data;
            END IF;
        ----DBMS_OUTPUT.put_line ('x_return_status-get_header:' || x_return_status);
        ----DBMS_OUTPUT.put_line ('order_details-5:');
        END IF;

    ----DBMS_OUTPUT.put_line ('order_details-9:');
    EXCEPTION
        WHEN OTHERS
        THEN
            x_msg_data := 'Error in Order Details Procedure: ' || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.ORDER_DETAILS'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR1'
                         , p_error_msg                => x_msg_data
                          );
    ----DBMS_OUTPUT.put_line ('order_details-EXEP:');
    END order_details;

    -- GET_HEADER procedure is called from ORDER_DETAILS procedure to
    -- get Header Information of the Customer Service Request.
    PROCEDURE get_header (
        p_request_id          IN       NUMBER
      , p_tds_parts_hdr_rec   IN OUT   xx_cs_tds_parts_hdr_rec
      , x_return_status       OUT      VARCHAR2
      , x_msg_data            OUT      VARCHAR2
    )
    IS
        l_hdr_rec       xx_cs_tds_parts_hdr_rec;
        ln_status_id    NUMBER;
        ln_bill_to_id   NUMBER;
        ln_user_id      NUMBER;
    BEGIN
        ----DBMS_OUTPUT.put_line ('get_header-1:' || p_request_id);
        --p_tds_parts_hdr_rec  xx_cs_tds_parts_hdr_rec := xx_cs_tds_parts_hdr_rec();
        -- p_tds_parts_hdr_rec.EXTEND;

        -- Initialization of the 'XX_CS_TDS_PARTS_HDR_REC' Object Type.
        p_tds_parts_hdr_rec :=
            xx_cs_tds_parts_hdr_rec (NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                   , NULL
                                    );

        BEGIN
            BEGIN
                -- Fetching the Customer SR Details by passing the Incident ID.
                SELECT LPAD (cb.incident_number
                           , 13
                           , 0
                            )
                     , cb.incident_status_id
                     , cl.NAME
                     , cb.incident_attribute_11 location_id
                     , cb.incident_attribute_1 aops_order
                     , '001' suborder_no
                     , cb.creation_date
                     , cb.last_update_date
                     , cb.bill_to_site_use_id
                     , 'P' order_type
                     , cb.incident_attribute_5 contact_name
                     , cb.incident_attribute_8 contact_email
                     , cb.incident_attribute_14 contact_phone
                     , cb.incident_attribute_9
                     , cb.created_by
                     , to_char(cb.close_date,'mm/dd/yyyy')
                     , 'P' delcd
                     , 'F' OrderSourceCode
                INTO   p_tds_parts_hdr_rec.order_number
                     , ln_status_id
                     , p_tds_parts_hdr_rec.order_status
                     , p_tds_parts_hdr_rec.location_id
                     , p_tds_parts_hdr_rec.reforderno
                     , p_tds_parts_hdr_rec.refordersub
                     , p_tds_parts_hdr_rec.creation_date
                     , p_tds_parts_hdr_rec.modified_date
                     , ln_bill_to_id
                     , p_tds_parts_hdr_rec.order_type
                     , p_tds_parts_hdr_rec.contact_name
                     , p_tds_parts_hdr_rec.contact_email
                     , p_tds_parts_hdr_rec.contact_phone
                     , p_tds_parts_hdr_rec.bill_to     -- customer_po_number Added By Gaurav Agarwal
                     , ln_user_id
                     , p_tds_parts_hdr_rec.attribute1 -- delivery date
                     , p_tds_parts_hdr_rec.attribute2 -- Delivery Code   -- Needs to be confirmed.
                     , p_tds_parts_hdr_rec.order_source_code
                FROM   cs_incidents_all_b cb
                     , cs_incident_statuses_tl cl
                WHERE  cl.incident_status_id = cb.incident_status_id
                AND    cb.incident_id = p_request_id
                and    exists ( select 1 from  xx_cs_tds_parts
            WHERE  request_number = cb.incident_number);
           -- AND    nvl(sales_flag,'N') = 'Y');
            EXCEPTION
                WHEN OTHERS
                THEN
                    ----DBMS_OUTPUT.put_line ('get_header-2:' || SQLERRM );
                    x_msg_data :=
                        'Exception Raised while deriving the Request Header Details...1:'
                        || SQLERRM;
                    x_return_status := fnd_api.g_ret_sts_error;
                    log_exception (p_object_id                => gn_request_number
                                 , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_HEADER'
                                 , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR11'
                                 , p_error_msg                => x_msg_data
                                  );
            END;

            -- Columns of 'XX_CS_TDS_PARTS_HDR_REC' TYPE  are getting Assigned with Values.
            p_tds_parts_hdr_rec.order_category := 'C';
            p_tds_parts_hdr_rec.number_of_lines := gn_no_of_lines;
            p_tds_parts_hdr_rec.subtotal := gn_sub_total;
            p_tds_parts_hdr_rec.order_total := gn_total;
            p_tds_parts_hdr_rec.special_instructions := gv_special_instr;

            --DBMS_OUTPUT.put_line ('special ...');
            BEGIN
                SELECT user_name
                INTO   p_tds_parts_hdr_rec.associate_id
                FROM   fnd_user
                WHERE  user_id = ln_user_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    p_tds_parts_hdr_rec.associate_id := NULL;
            END;
        ----DBMS_OUTPUT.put_line ('get_header-2:' || p_request_id);
        EXCEPTION
            WHEN OTHERS
            THEN
                ----DBMS_OUTPUT.put_line ('get_header-EXEP1:');
                x_msg_data :=
                      'Exception Raised while deriving the Incident Header Details:...2' || SQLERRM;
                x_return_status := fnd_api.g_ret_sts_error;
                log_exception (p_object_id                => gn_request_number
                             , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_HEADER'
                             , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR3'
                             , p_error_msg                => x_msg_data
                              );
        END;

        BEGIN
            ----DBMS_OUTPUT.put_line ('get_header-3:');
            SELECT NAME
            INTO   p_tds_parts_hdr_rec.location_name
            FROM   hr_all_organization_units
            WHERE  attribute1 = p_tds_parts_hdr_rec.location_id;
        EXCEPTION
            WHEN OTHERS
            THEN
                ----DBMS_OUTPUT.put_line ('get_header-EXEP2:');
                p_tds_parts_hdr_rec.location_id := NULL;
                -- x_msg_data := 'Exception Raised while deriving the Location Name:' || SQLERRM;
                --  x_return_status := fnd_api.g_ret_sts_error;
                log_exception (p_object_id                => gn_request_number
                             , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_HEADER'
                             , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR4'
                             , p_error_msg                => x_msg_data
                              );
        END;

        BEGIN
            IF ln_status_id = 2
            THEN
                ----DBMS_OUTPUT.put_line ('get_header-4:' || ln_status_id);
                SELECT payment_type_code
                     , credit_card_code
                     , DECODE (payment_type_code
                             , 'CREDIT_CARD', credit_card_number
                             , check_number
                              ) num
                     , credit_card_expiration_date
                     , credit_card_approval_code
                INTO   p_tds_parts_hdr_rec.tendertyp
                     , p_tds_parts_hdr_rec.cccid
                     , p_tds_parts_hdr_rec.tndacctnbr
                     , p_tds_parts_hdr_rec.exp_date
                     , p_tds_parts_hdr_rec.avscode
                FROM   oe_payments
                WHERE  header_id = (SELECT header_id
                                    FROM   xx_om_header_attributes_all
                                    WHERE  sr_number = gn_request_number and rownum =1 );
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                ----DBMS_OUTPUT.put_line ('get_header-EXEC3:');
                x_msg_data := 'Exception Raised while deriving Request Payment Details:' || SQLERRM;
                x_return_status := fnd_api.g_ret_sts_error;
                log_exception (p_object_id                => gn_request_number
                             , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_HEADER'
                             , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR5'
                             , p_error_msg                => x_msg_data
                              );
        END;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_msg_data := 'Exception Raised In Get Headers Procedure:' || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_HEADER'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR6'
                         , p_error_msg                => x_msg_data
                          );
    END get_header;

    -- 'GET_LINE' procedure would be called from 'ORDER_DETAILS' procedure to get the
    -- in detail information of the Customer Service Request.
    PROCEDURE get_line (
        p_sr_number            IN       VARCHAR2
      , p_tds_parts_line_tbl   IN OUT   xx_cs_tds_parts_lines_tbl
      , x_return_status        OUT      VARCHAR2
      , x_msg_data             OUT      VARCHAR2
    )
    IS
        line_rec          xx_cs_tds_parts_lines_tbl;
        ln_count          NUMBER  := 0;
        ln_line_total     NUMBER  := 0;
        -- Cursor to get the Line Details based on the Service Request
        CURSOR c_tds_parts_lines
        IS
            SELECT store_id
                 , line_number
                 , item_number
                 , item_description
                 , rms_sku
                 , (nvl(tot_received_qty,quantity) - nvl(excess_quantity,0)) qty
                 , DECODE (nvl(core_flag,'N')
                         , 'Y', exchange_price
                         , selling_price
                          ) price
                 , uom
                 , special_instr
            FROM   xx_cs_tds_parts
            WHERE  request_number = p_sr_number
            AND    nvl(sales_flag,'N') = 'Y';
    BEGIN
        -- --DBMS_OUTPUT.put_line ('get_line-1:' || p_sr_number);
        -- Initilization of the Variables.
        gv_special_instr := NULL;
        gn_sub_total := 0;
        gn_no_of_lines := 0;
        ln_count := 0;

        -- Initilization of the Table Type
        p_tds_parts_line_tbl := xx_cs_tds_parts_lines_tbl ();

        ----DBMS_OUTPUT.put_line ('get_line-2:' || ln_count);
        FOR rec_tds_parts_lines IN c_tds_parts_lines
        LOOP
            -- Record Count of the Service Reqeust Detail Lines.
            ln_count := ln_count + 1;
            ----DBMS_OUTPUT.put_line ('get_line-2:' || ln_count);
            -- Extending the Table Type
          IF rec_tds_parts_lines.qty <> 0 then
            p_tds_parts_line_tbl.EXTEND;
            -- Initialization of the Record to fetch the Record Details
            p_tds_parts_line_tbl (ln_count) :=
                xx_cs_tds_parts_lines_rec (NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                         , NULL
                                          );
            p_tds_parts_line_tbl (ln_count).line_number := rec_tds_parts_lines.line_number;
            p_tds_parts_line_tbl (ln_count).vendor_part_number := rec_tds_parts_lines.item_number;
            p_tds_parts_line_tbl (ln_count).item_description := rec_tds_parts_lines.item_description;
            p_tds_parts_line_tbl (ln_count).sku := rec_tds_parts_lines.rms_sku;
            p_tds_parts_line_tbl (ln_count).order_qty := rec_tds_parts_lines.qty;
            p_tds_parts_line_tbl (ln_count).selling_price := rec_tds_parts_lines.price;
            p_tds_parts_line_tbl (ln_count).uom := rec_tds_parts_lines.uom;
            p_tds_parts_line_tbl (ln_count).comments := rec_tds_parts_lines.special_instr;


            -- Calculation of the Total and Sub Total of the Service Request.   -- Raj 8/30/11
            ln_line_total := rec_tds_parts_lines.price * rec_tds_parts_lines.qty;

            IF (gn_sub_total != 0)
            THEN
                gn_sub_total := gn_sub_total + ln_line_total ;
                --gn_total     := gn_total + gn_sub_total; Commneted by Gaurav
                gn_total     :=  gn_sub_total; -- Added by Gaurav
            ELSE
                gn_sub_total := ln_line_total;
                gn_total     := gn_sub_total;
            END IF;

            IF (gv_special_instr IS NOT NULL)
            THEN
                gv_special_instr := gv_special_instr || ' ' || rec_tds_parts_lines.special_instr;
            --gv_special_instr := rec_tds_parts_lines.special_instr;
            ELSE
                gv_special_instr := rec_tds_parts_lines.special_instr;
            END IF;

          end if; -- qty check
        END LOOP;

        gn_no_of_lines := ln_count;
    ----DBMS_OUTPUT.put_line ('get_line-3:' || p_sr_number);
    EXCEPTION
        WHEN OTHERS
        THEN
            x_msg_data := 'Exception Raised while getting Request Line Details:' || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_LINE'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR7'
                         , p_error_msg                => x_msg_data
                          );
    END get_line;

/*************************************************************************/
    -- GET_ORDER_LIST is the Independent main procedure which would be called
    -- From the GMILL Web Page to display the List of the Orders Related to the
    -- Customer.
    PROCEDURE get_order_list (
        p_customer         IN       NUMBER
      , p_date_from        IN       DATE DEFAULT NULL
      , p_date_to          IN       DATE DEFAULT NULL
      , p_status           IN       VARCHAR2 DEFAULT NULL
      , p_sku              IN       VARCHAR2 DEFAULT NULL
      , p_direction_flag   IN       VARCHAR2 DEFAULT NULL
      , p_hdr_tbl          IN OUT   xx_cs_tds_parts_hdr_tbl
      , x_list_cnt         OUT      NUMBER
      , x_more_flag        OUT      VARCHAR2
      , x_where_flag       OUT      VARCHAR2
      , x_return_status    OUT      VARCHAR2
      , x_msg_data         OUT      VARCHAR2
    )
    IS
        -- Ref Cursor Declation
        TYPE ordcurtyp IS REF CURSOR;

        ord_cur          ordcurtyp;
        stmt_str_ord     VARCHAR2 (4000);
        ln_customer_id   NUMBER;
        ln_user_id       NUMBER;
        l_hdr_rec        xx_cs_tds_parts_get_order_rec;
    BEGIN
        BEGIN
            SELECT hzp.party_id
            INTO   ln_customer_id
            FROM   hz_parties hzp
                 , hz_cust_accounts hzc
            WHERE  hzc.party_id = hzp.party_id
            AND    hzc.orig_system_reference = LPAD (TO_CHAR (p_customer)
                                                   , 8
                                                   , 0
                                                    ) || '-' || '00001-A0';
        EXCEPTION
            WHEN OTHERS
            THEN
                x_msg_data := 'Customer Details Not found. ';
                x_return_status := fnd_api.g_ret_sts_error;
                log_exception (p_object_id                => gn_request_number
                             , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_ORDER_LIST'
                             , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR8'
                             , p_error_msg                => x_msg_data
                              );
        END;

        ----DBMS_OUTPUT.put_line('ln_customer_id:'||ln_customer_id);
        -- Variable Assignment with the SQL Query String, which would be used
        -- to get the Ref Cursor Values
        stmt_str_ord :=
               'Select lpad(cb.incident_number,13,0)
                ,cb.creation_date
                ,cb.created_by
                ,cl.name
                ,cb.incident_attribute_5 contact_name
                ,cb.incident_attribute_11 store_no
                from cs_incidents_all_b cb,cs_incident_statuses_tl cl
                where cl.incident_status_id = cb.incident_status_id
                and  exists (select 1 from xx_cs_tds_parts
                where nvl(sales_flag,''N'') = ''Y''
                and request_number = cb.incident_number)
                and cb.customer_id = '|| ln_customer_id;

        -- If p_date_from and p_date_to Variables are not null then REF CURSOR SQL Query
        -- String would be extended.
        IF p_date_from IS NOT NULL AND p_date_to IS NOT NULL
        THEN
            stmt_str_ord :=
                   stmt_str_ord
                || ' and trunc(cb.creation_date)                 between '''
                || TRUNC (p_date_from)
                || '''  and '''
                || TRUNC (p_date_to)
                || '''';
        END IF;

        -- If p_status Variables are not null then REF CURSOR SQL Query
        -- String would be extended.
        IF p_status IS NOT NULL
        THEN
            stmt_str_ord := stmt_str_ord || 'and cl.name = ''' || p_status || '''';
        END IF;

        -- If p_sku Variables are not null then REF CURSOR SQL Query
        -- String would be extended.
        IF p_sku IS NOT NULL
        THEN
            stmt_str_ord :=
                   stmt_str_ord
                || ' and cb.incident_number in  (select request_number from xx_cs_tds_parts   where rms_sku = '
                || p_sku
                || ')';
        END IF;

        stmt_str_ord := stmt_str_ord || ' order by cb.creation_date desc, cb.incident_status_id ';
        ----DBMS_OUTPUT.put_line('Testing');
        x_list_cnt := 0;
        p_hdr_tbl := xx_cs_tds_parts_hdr_tbl ();

        ----DBMS_OUTPUT.put_line('Query:'||stmt_str_ord);
        ----DBMS_OUTPUT.put_line('Length:'||length(stmt_str_ord));
        -- Open Ref Cursor using the SQL Variable used.
        OPEN ord_cur FOR stmt_str_ord;

        LOOP
            DBMS_OUTPUT.put_line ('cnt ' || x_list_cnt);
            -- Loop Count
            x_list_cnt := x_list_cnt + 1;
            -- Extending the Table Type.
            p_hdr_tbl.EXTEND;
            -- Initialization of the Record Type related to the Table.
            p_hdr_tbl (x_list_cnt) :=
                xx_cs_tds_parts_get_order_rec (NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                             , NULL
                                              );

            -- Fetching the Ref Cursor Details into the Table Type.
            FETCH ord_cur
            INTO  p_hdr_tbl (x_list_cnt).order_number
                , p_hdr_tbl (x_list_cnt).order_date
                , ln_user_id
                , p_hdr_tbl (x_list_cnt).status_code
                , p_hdr_tbl (x_list_cnt).contact_name
                , p_hdr_tbl (x_list_cnt).location_id;

            p_hdr_tbl (x_list_cnt).modify_flag := 'N';
            p_hdr_tbl (x_list_cnt).order_type := 'P';                                -- ?TDS Parts?;
            p_hdr_tbl (x_list_cnt).order_source := 'F';
            p_hdr_tbl (x_list_cnt).vendor_code := NULL;

            -- If No Details are Found Then the Cursor would be exited
            -- by explicitly deleting the Record Intilized and reducing the
            -- record count.
            IF (ord_cur%NOTFOUND)
            THEN
                --dbms_output.put_line('cnt12 '||x_list_cnt);
                p_hdr_tbl.DELETE (x_list_cnt);
                --dbms_output.put_line('cnt13 '||x_list_cnt);
                x_list_cnt := x_list_cnt - 1;
                --dbms_output.put_line('cnt14 '||x_list_cnt);
                EXIT;
            END IF;

            BEGIN
                SELECT SUM (quantity * selling_price) total
                INTO   p_hdr_tbl (x_list_cnt).total
                FROM   xx_cs_tds_parts
                WHERE  request_number = p_hdr_tbl (x_list_cnt).order_number;
            EXCEPTION
                WHEN OTHERS
                THEN
                    p_hdr_tbl (x_list_cnt).total := NULL;
            END;

            -- need to confirm from AOPS
            SELECT user_name
            INTO   p_hdr_tbl (x_list_cnt).user_name
            FROM   fnd_user
            WHERE  user_id = ln_user_id;
        /*
            IF (p_hdr_tbl (x_list_cnt).order_number IS NULL) THEN
                dbms_output.put_line('cnt1 '||x_list_cnt);
                p_hdr_tbl.delete(x_list_cnt);
                DBMS_OUTPUT.PUT_LINE('ORDER NUMBER IS NULL');
            END IF;
        */
        END LOOP;

        CLOSE ord_cur;

        IF (x_list_cnt = 0)
        THEN
            x_msg_data := 'No part orders found';
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_ORDER_LIST'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR9'
                         , p_error_msg                => x_msg_data
                          );
        END IF;
    /*
    FOR i IN p_hdr_tbl.FIRST..p_hdr_tbl.LAST
    LOOP
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')user_name      :'||p_hdr_tbl(i).user_name);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')order_number   :'||p_hdr_tbl(i).order_number);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')order_date     :'||p_hdr_tbl(i).order_date);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')modify_flag    :'||p_hdr_tbl(i).modify_flag);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')status_code    :'||p_hdr_tbl(i).status_code);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')contact_name   :'||p_hdr_tbl(i).contact_name);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')location_id    :'||p_hdr_tbl(i).location_id);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')order_type     :'||p_hdr_tbl(i).order_type);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')order_source   :'||p_hdr_tbl(i).order_source);
    --DBMS_OUTPUT.put_line('p_hdr_tbl('||i||')vendor_code    :'||p_hdr_tbl(i).vendor_code);
    END LOOP;
    */
    EXCEPTION
        WHEN OTHERS
        THEN
            x_msg_data := 'No part orders found';
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_ORDER_LIST'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR9'
                         , p_error_msg                => x_msg_data
                          );
    END get_order_list;

/***********************************************************************************************/
    -- GET_STATUS is a Independent procedure which would be called from the GMILL Page to get
    -- All the relavent STATUSES of the Customer Incidents recorded.
    PROCEDURE get_status (
        p_status_tbl      IN OUT   xx_cs_tds_parts_status_tbl
      , x_return_status   OUT      VARCHAR2
      , x_msg_data        OUT      VARCHAR2
    )
    IS
        CURSOR c_st_cur
        IS
            SELECT st.NAME NAME
            FROM   cs_sr_status_groups_tl sl
                 , cs_sr_allowed_statuses sa
                 , cs_incident_statuses_b sb
                 , cs_incident_statuses_tl st
            WHERE  st.incident_status_id = sb.incident_status_id
            AND    st.incident_status_id = sa.incident_status_id
            AND    sa.status_group_id = sl.status_group_id
            AND    sb.incident_subtype = 'INC'
            AND    sb.end_date_active IS NULL
            AND    sl.group_name = 'TDS-Onsite';

        ln_loop_count   NUMBER := 0;
    BEGIN
        p_status_tbl := xx_cs_tds_parts_status_tbl ();

        FOR c_st_rec IN c_st_cur
        LOOP
            ln_loop_count := ln_loop_count + 1;
            p_status_tbl.EXTEND;
            p_status_tbl (ln_loop_count) :=
                xx_cs_tds_parts_status_rec (NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                          , NULL
                                           );
            p_status_tbl (ln_loop_count).status := c_st_rec.NAME;
        END LOOP;
    /*
    FOR i IN p_status_tbl.FIRST..p_status_tbl.LAST
    LOOP
    --DBMS_OUTPUT.put_line('p_status_tbl('||i||')status :'||p_status_tbl(i).status);
    END LOOP;
    */
    EXCEPTION
        WHEN OTHERS
        THEN
            x_msg_data := 'Exception Raised in Get Status Procedure:' || SQLERRM;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception (p_object_id                => gn_request_number
                         , p_error_location           => 'XX_CS_TDS_GET_PARTS_PKG.GET_STATUS'
                         , p_error_message_code       => 'XX_CS_TDS_GET_PARTS_ERR10'
                         , p_error_msg                => x_msg_data
                          );
    END get_status;
END xx_cs_tds_get_parts_pkg;
/
show errors;
exit;