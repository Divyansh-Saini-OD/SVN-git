create or replace 
PACKAGE BODY      xx_om_hvop_error_process
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_HVOP_ERROR_PROCESS                                        |
-- | Description      : This Program will update request id and error flag   |
-- |                    and required field to get orders processed           |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 25-AUG-2010 Bapuji Nanapaneni Initial draft version              |
-- |DRAFT1B 09-AUG-2011 Bapuji Nanapaneni Modifed to pick up BACK ORDER ORD  |
-- |                                      to unapply and apply for dep order |
-- |DRAFT1C 06-FEB-2012 Oracle AMS Team   Modified to pick POS orders to     |
-- |                      apply and unapply for deposit order                |
-- |DRAFT1D 29-AUG-2013 Saritha Mummaneni Modified code to update errored    |
-- |                                      deposits with customer info        |
-- |                      by including xx_om_legacy_dep_dtls                 |
-- |                                      As per Defect #24713               |
-- |        18-MAR-2014 Edson Morales     Modified for R12 Bypass
-- |DRAFT1E 25-SEP-2014 AMS-SCM Team      Modified for QC 31475              |
-- |DRAFT1F 02-NOV-2015 Vasu Raparla     Removed Schema References for 12.2  |
-- |DRAFT1G 18-NOV-2015 Sai Kiran -SCM Team      Modified for QC 36473       |
-- |DRAFT1H 25-AUG-2017 Venkata Battu      Modified for Defect#42629         |
-- |DRAFT1I 25-AUG-2017 Venkata Battu      Modified for Defect#43138 
-- |DRAFT1I 10-OCT-2019 Shalu George      Modified for Account type error    |   
-- +=========================================================================+
PROCEDURE ship_to_activate
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : SHIP_TO_ACTIVATE                                                |
-- | Description      : This Procedure will look for SHIP_TO and Bill_TO site status.|
-- |                    IF it is active it will update error_flag, request_id|
-- |                   and invoice to org id in case of missing bill to information
-- |                   so order import picks up when submitted
-- |DRAFT1E 25-SEP-2014 AMS-SCM Team      Modified for QC 31475               |
-- |                                                                         |
-- +=========================================================================+

-- code modification for QC 31475(No Bill To Address found: the API will fetch the orders stuck for missing bill to and update the invoice to org id once the account site is active and will make it eligible for Order Import )


l_invoice_to_org_id NUMBER;

CURSOR c_order IS
SELECT orig_sys_document_REf,sold_to_org_id,h.order_source_id
  FROM  oe_headers_iface_all h,oe_processing_msgs_vl m
 WHERE  h.orig_sys_document_ref = m.original_sys_document_ref
   AND H.Order_Source_Id   = M.Order_Source_Id
   AND h.error_flag = 'Y'
   AND m.message_text LIKE '%10000021%';




BEGIN
  FOR c1_order  IN c_order

   LOOP
     BEGIN
      fnd_file.put_line(fnd_file.OUTPUT,'Start of Bill To Validation ');

        SELECT hcu.site_use_id
          INTO l_invoice_to_org_id
          FROM   HZ_CUST_ACCT_SITES_ALL HCS,hz_cust_site_uses_all hcu
         WHERE hcs.cust_account_id = c1_order.sold_to_org_id
           AND hcs.status = 'A'
           AND hcu.site_use_code = 'BILL_TO'
           AND hcs.orig_system_reference LIKE '%00001%'
           AND hcs.cust_acct_site_id = hcu.cust_acct_site_id;


    UPDATE oe_lines_iface_all h
             SET  invoice_to_org_id = l_invoice_to_org_id
     WHERE orig_sys_document_ref= c1_order.orig_sys_document_ref
	 and order_source_id = c1_order.order_source_id;

      UPDATE oe_headers_iface_all h
            SET error_flag = NULL,
                request_id = NULL,
       invoice_to_org_id = l_invoice_to_org_id
    WHERE orig_sys_document_ref= c1_order.orig_sys_document_ref
	and order_source_id = c1_order.order_source_id;

        fnd_file.put_line(fnd_file.OUTPUT,'Total number of Orders updated for missing Bill To::'|| SQL%ROWCOUNT);
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.OUTPUT,
                              'NO Orders to be processed for Missing Bill To');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED IN "BillTo_Validation" :'
                              || SQLERRM);
 END;
 END LOOP;

--end of code modification for QC 31475
       fnd_file.put_line(fnd_file.output,'Start of SHIP_TO OR BILL_TO ACTIVE ');

     UPDATE oe_headers_iface_all h
        SET error_flag = NULL,
            request_id = NULL
      WHERE  EXISTS(
                   SELECT 1
                   FROM   oe_headers_iface_all oh, hz_cust_site_uses_all ha, oe_processing_msgs_vl op
                   WHERE  h.orig_sys_document_ref = op.original_sys_document_ref
                   AND    h.order_source_id = op.order_source_id
                   AND    h.ship_to_org_id = ha.site_use_id
                   AND    ha.status = 'A'
                   AND    NVL(h.error_flag,
                              'N') = 'Y'
                   AND    (   op.MESSAGE_TEXT = 'Validation failed for the field - Ship To'
                           OR op.MESSAGE_TEXT = 'Validation failed for the field - Bill To')
                   AND    NVL(error_flag,
                              'N') = 'Y'
                   AND    oh.orig_sys_document_ref = h.orig_sys_document_ref
                   AND    oh.order_source_id = h.order_source_id);

        fnd_file.put_line(fnd_file.output,
                             'Total number of Orders updated for SHIP_TO Inactive::'
                          || SQL%ROWCOUNT);
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NO Orders to be processed for Error Inactive SHIP_TO');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,'WHEN OTHERS RAISED IN "SHIP_TO_ACTIVATE" :'|| SQLERRM);

    END ship_to_activate;

    PROCEDURE customer_activate
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : CUSTOMER_ACTIVATE                                               |
-- | Description      : This Procedure will look for Customer status.IF it is|
-- |                    active  it will update error_flag and request_id and will update
-- | orders with customer information in case of missing customer error,     |
-- |                    so order import picks up when submitted              |
-- |                                                                         |
-- +=========================================================================+

BEGIN

        fnd_file.put_line(fnd_file.output,
                          'Start of CUSTOMER ACTIVE');

        UPDATE oe_headers_iface_all h
        SET error_flag = NULL,
            request_id = NULL
        WHERE  EXISTS(
                   SELECT 1
                   FROM   hz_cust_accounts ha, oe_processing_msgs_vl op
                   WHERE  h.orig_sys_document_ref = op.original_sys_document_ref
                   AND    h.order_source_id = op.order_source_id
                   AND    h.sold_to_org_id = ha.cust_account_id
                   AND    ha.status = 'A'
                   AND    NVL(h.error_flag,
                              'N') = 'Y'
                   AND    op.MESSAGE_TEXT IN
                              ('Validation failed for the field -End Customer',
                               'Validation failed for the field -Customer',
                               'Validation failed for the field - Customer') )
        AND    NVL(error_flag,
                   'N') = 'Y';

        COMMIT;
        fnd_file.put_line(fnd_file.output,
                             'Total number of Orders updated for Customer Inactive::'
                          || SQL%ROWCOUNT);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NO Orders to be processed for Error Inactive Customers');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED IN "CUSTOMER_ACTIVE" :'
                              || SQLERRM);


    END customer_activate;

    PROCEDURE item_validation
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : ITEM_VALIDATION                                                 |
-- | Description      : This Procedure will look for Item status.IF it exists|
-- |                    and assigned to warehouse it will update error_flag  |
-- |                    and request_id so order import picks up when         |
-- |                    submitted                                            |
-- +=========================================================================+

        /* Variable Declaration */
        ln_item_id                NUMBER;
        ln_orig_sys_document_ref  VARCHAR2(80);
        ln_count                  NUMBER       := 0;

        CURSOR c_ord_val
        IS
            SELECT DISTINCT h.orig_sys_document_ref,
                            h.order_source_id
            FROM            oe_headers_iface_all h, oe_processing_msgs_vl m
            WHERE           h.orig_sys_document_ref = m.original_sys_document_ref
            AND             h.order_source_id = m.order_source_id
            AND             NVL(h.error_flag,
                                'N') = 'Y'
            AND             m.MESSAGE_TEXT LIKE '10000017%'
            ORDER BY        1;

        CURSOR c_line_level(
            p_orig_sys   IN  VARCHAR2,
            p_source_id  IN  NUMBER)
        IS
            SELECT l.orig_sys_line_ref,
                   l.ship_from_org_id,
                   l.inventory_item
            FROM   oe_headers_iface_all h, oe_lines_iface_all l, oe_processing_msgs_vl m
            WHERE  h.orig_sys_document_ref = l.orig_sys_document_ref
            AND    h.order_source_id = l.order_source_id
            AND    m.original_sys_document_ref = l.orig_sys_document_ref
            AND    m.order_source_id = l.order_source_id
            AND    m.original_sys_document_line_ref = l.orig_sys_line_ref
            AND    h.orig_sys_document_ref = p_orig_sys
            AND    h.order_source_id = p_source_id;

        CURSOR c_item_val(
            p_item        IN  VARCHAR2,
            p_inv_org_id  IN  NUMBER)
        IS
            SELECT COUNT(inventory_item_id) item_id
            FROM   mtl_system_items_b
            WHERE  segment1 = p_item
            AND    organization_id = p_inv_org_id;
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Start of Item Validation ');

        /*Find all orders with message code 10000017 */
        FOR r_ord_val IN c_ord_val
        LOOP
            BEGIN
                SAVEPOINT sp1;
                ln_orig_sys_document_ref := r_ord_val.orig_sys_document_ref;
                fnd_file.put_line
                              (fnd_file.output,
                               'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ');
                fnd_file.put_line(fnd_file.output,
                                     'Working on Item Validation, Order Number:::'
                                  || r_ord_val.orig_sys_document_ref);
                fnd_file.put_line
                               (fnd_file.output,
                                'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ');

                /*Find all lines for an orders with message code 10000018 */
                FOR r_line_level IN c_line_level(r_ord_val.orig_sys_document_ref,
                                                 r_ord_val.order_source_id)
                LOOP
                    /*Validate item is assigned or not */
                    FOR r_item_val IN c_item_val(r_line_level.inventory_item,
                                                 r_line_level.ship_from_org_id)
                    LOOP
                        IF r_item_val.item_id = 0
                        THEN
                            fnd_file.put_line(fnd_file.output,
                                                 'Item do not exists or not assigned to warehouse for order : '
                                              || ln_orig_sys_document_ref);
                            RAISE NO_DATA_FOUND;
                        END IF;
                    END LOOP;
                END LOOP;

                /* update order for items that are validated */
                fnd_file.put_line(fnd_file.output,
                                     'Update Order Number : '
                                  || r_ord_val.orig_sys_document_ref);

                UPDATE oe_headers_iface_all
                SET error_flag = NULL,
                    request_id = NULL
                WHERE  orig_sys_document_ref = r_ord_val.orig_sys_document_ref
                AND    order_source_id = r_ord_val.order_source_id;



                ln_count :=   ln_count
                            + SQL%ROWCOUNT;

               --DRAFT1G Changes made to program as part of defect#36473 Start--
                UPDATE oe_lines_iface_all
                SET error_flag = NULL,
                    request_id = NULL
                WHERE  orig_sys_document_ref = r_ord_val.orig_sys_document_ref
                AND    order_source_id = r_ord_val.order_source_id;
                --DRAFT1G Changes made to program as part of defect#36473 End--
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    fnd_file.put_line(fnd_file.output,
                                         'At least one item do not exists or not assigned to warehouse for order : '
                                      || r_ord_val.orig_sys_document_ref);
                    ROLLBACK TO sp1;
            END;
        END LOOP;

        fnd_file.put_line(fnd_file.output,
                             'No Of Orders Updated '
                          || ln_count);
        COMMIT;
        fnd_file.put_line(fnd_file.output,
                          'End of Item Validation');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NO Orders to be processed for Error Item Validation');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED IN "ITEM_VALIDATION" :'
                              || SQLERRM);
    END item_validation;

    PROCEDURE item_assignment
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : ITEM_ASSIGNMENT                                                 |
-- | Description      : This Procedure will look for Item assignment if found|
-- |                    it will update error_flag and request_id so order    |
-- |                    import picks up when submitted                       |
-- |                                                                         |
-- +=========================================================================+

        /* Variable Declaration */
        ln_item_id                NUMBER;
        ln_orig_sys_document_ref  VARCHAR2(80);
        ln_count                  NUMBER       := 0;

        CURSOR c_item_ass_val
        IS
            SELECT DISTINCT h.orig_sys_document_ref,
                            h.order_source_id
            FROM            oe_headers_iface_all h, oe_processing_msgs_vl m
            WHERE           h.orig_sys_document_ref = m.original_sys_document_ref
            AND             h.order_source_id = m.order_source_id
            AND             NVL(h.error_flag,
                                'N') = 'Y'
            AND             m.MESSAGE_TEXT LIKE '10000018%'
            ORDER BY        1;

        CURSOR c_line_level(
            p_orig_sys   IN  VARCHAR2,
            p_source_id  IN  NUMBER)
        IS
            SELECT l.orig_sys_line_ref,
                   l.ship_from_org_id,
                   l.inventory_item_id
            FROM   oe_headers_iface_all h, oe_lines_iface_all l, oe_processing_msgs_vl m
            WHERE  h.orig_sys_document_ref = l.orig_sys_document_ref
            AND    h.order_source_id = l.order_source_id
            AND    m.original_sys_document_ref = l.orig_sys_document_ref
            AND    m.order_source_id = l.order_source_id
            AND    m.original_sys_document_line_ref = l.orig_sys_line_ref
            AND    h.orig_sys_document_ref = p_orig_sys
            AND    h.order_source_id = p_source_id;

        CURSOR c_item_val(
            p_item_id     IN  NUMBER,
            p_inv_org_id  IN  NUMBER)
        IS
            SELECT COUNT(inventory_item_id) item_id
            FROM   mtl_system_items_b
            WHERE  inventory_item_id = p_item_id
            AND    organization_id = p_inv_org_id;
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Start of Item Assignment Validation ');

        /*Find all orders with message code 10000018 */
        FOR r_item_ass_val IN c_item_ass_val
        LOOP
            BEGIN
                SAVEPOINT sp1;
                ln_orig_sys_document_ref := r_item_ass_val.orig_sys_document_ref;
                fnd_file.put_line
                              (fnd_file.output,
                               'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ');
                fnd_file.put_line(fnd_file.output,
                                     'Working on Item Assignment Validation, Order Number:::'
                                  || r_item_ass_val.orig_sys_document_ref);
                fnd_file.put_line
                               (fnd_file.output,
                                'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ');

                /*Find all lines for an orders with message code 10000018 */
                FOR r_line_level IN c_line_level(r_item_ass_val.orig_sys_document_ref,
                                                 r_item_ass_val.order_source_id)
                LOOP
                    /*Validate item is assigned or not */
                    FOR r_item_val IN c_item_val(r_line_level.inventory_item_id,
                                                 r_line_level.ship_from_org_id)
                    LOOP
                        IF r_item_val.item_id = 0
                        THEN
                            fnd_file.put_line(fnd_file.output,
                                                 'Item Not assigned for order : '
                                              || ln_orig_sys_document_ref);
                            RAISE NO_DATA_FOUND;
                        END IF;
                    END LOOP;
                END LOOP;

                /* update order where item is been assigned */
                fnd_file.put_line(fnd_file.output,
                                     'Update Order Number : '
                                  || r_item_ass_val.orig_sys_document_ref);

                UPDATE oe_headers_iface_all
                SET error_flag = NULL,
                    request_id = NULL
                WHERE  orig_sys_document_ref = r_item_ass_val.orig_sys_document_ref
                AND    order_source_id = r_item_ass_val.order_source_id;


                ln_count :=   ln_count
                            + SQL%ROWCOUNT;


                --DRAFT1G Changes made to program as part of defect#36473 Start--
                UPDATE oe_lines_iface_all
                SET error_flag = NULL,
                    request_id = NULL
                WHERE  orig_sys_document_ref = r_item_ass_val.orig_sys_document_ref
                AND    order_source_id = r_item_ass_val.order_source_id;
                --DRAFT1G Changes made to program as part of defect#36473 End--

            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    fnd_file.put_line(fnd_file.output,
                                         'At least one item is not assigned for order : '
                                      || r_item_ass_val.orig_sys_document_ref);
                    ROLLBACK TO sp1;
            END;
        END LOOP;

        fnd_file.put_line(fnd_file.output,
                             'No Of Orders Updated '
                          || ln_count);
        COMMIT;
        fnd_file.put_line(fnd_file.output,
                          'End of Item Assignment Validation');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NO Orders to be processed for Error Item Assignment');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED IN "ITEM_ASSIGNMENT" :'
                              || SQLERRM);
    END item_assignment;

    PROCEDURE customer_validation
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : CUSTOMER_VALIDATION                                             |
-- | Description      : This Procedure will derive cutomer id, ship to , bill|
-- |                    to, term id,CC name and attributes required and      |
-- |                    update request_id and error_flag so order import     |
-- |                    picks up when submitted
--| DRAFT1E 25-SEP-2014 AMS-SCM Team      Modified for QC 31475              |
-- +=========================================================================+
        ln_min_request_id      NUMBER;
        ln_max_request_id      NUMBER;
        ln_sold_to_org_id      NUMBER;
        lc_sold_to_org         VARCHAR2(240);
        lc_return_status       VARCHAR2(1);
        ln_ship_to_org_id      NUMBER;
        lc_ship_to_org         VARCHAR2(240);
        lc_ship_to_sequence    VARCHAR2(20);
        ln_invoice_to_org_id   NUMBER;
        ln_sold_to_contact_id  NUMBER;
        lc_sold_to_contact     VARCHAR2(240);
        lc_ship_to_geocode     VARCHAR2(30);
        lc_orig_cust_name      VARCHAR2(80);
        lc_ship_to_ref         VARCHAR2(80);
        ln_payment_term_id     NUMBER;
        lc_orig_system         VARCHAR2(10);
        lc_order_source        VARCHAR2(1);
        ln_org_id              NUMBER;
        lc_ship_to_address1    VARCHAR2(240);
        lc_ship_to_address2    VARCHAR2(240);
        lc_ship_to_city        VARCHAR2(240);
        lc_ship_to_state       VARCHAR2(240);
        lc_ship_to_country     VARCHAR2(240);
        lc_ship_to_zip         VARCHAR2(240);
        lc_customer_po_number  VARCHAR2(240);
        lc_release_no          VARCHAR2(240);
        lc_cust_dept_no        VARCHAR2(240);
        lc_desk_top_no         VARCHAR2(240);
        l_temp_var             VARCHAR2(2000) := NULL;
        ln_count               BINARY_INTEGER;

        CURSOR c_customer(
            p_min_request_id  IN  NUMBER,
            p_max_request_id  IN  NUMBER)
        IS
            SELECT h.orig_sys_document_ref,
                   h.order_source_id,
                   f.lookup_code order_source,
                   h.ordered_date,
                   h.order_category,
                   h.sold_to_org,
                   h.sold_to_org_id,
                   h.ship_to_org_id,
                   h.ship_to_org,
                   h.invoice_to_org_id,
                   h.sold_to_contact,
                   h.sold_to_contact_id,
                   h.payment_term_id,
                   x.ship_to_sequence,
                   x.ship_to_address1,
                   x.ship_to_address2,
                   x.ship_to_city,
                   x.ship_to_state,
                   x.ship_to_country,
                   x.ship_to_zip,
                   x.orig_cust_name,
                   h.customer_po_number,
                   x.release_no,
                   x.cust_dept_no,
                   x.desk_top_no,
                   x.ship_to_geocode,
                   h.org_id
            FROM   oe_headers_iface_all h, xx_om_headers_attr_iface_all x, fnd_lookup_values f
            WHERE  h.request_id BETWEEN p_min_request_id AND p_max_request_id
            AND    (   h.sold_to_org_id IS NULL
                    OR h.ship_to_org_id IS NULL
                    OR h.invoice_to_org_id IS NULL
                    OR h.payment_term_id IS NULL)
            AND    h.orig_sys_document_ref = x.orig_sys_document_ref
            AND    h.order_source_id = x.order_source_id
            AND    h.order_source_id = f.attribute6
            AND    f.lookup_type = 'OD_ORDER_SOURCE'
--   AND NVL(x.od_order_type,'1')  'X'
            AND    h.error_flag = 'Y';
    BEGIN
        SELECT MIN(request_id),
               MAX(request_id)
        INTO   ln_min_request_id,
               ln_max_request_id
        FROM   oe_headers_iface_all
        WHERE  order_type_id != 1002
        AND    NVL(error_flag,
                   'N') = 'Y';

        IF    ln_min_request_id IS NULL
           OR ln_max_request_id IS NULL
        THEN
            fnd_file.put_line(fnd_file.output,
                              'No errors to be processed');
        ELSE
            ln_count := 0;

            FOR r_customer IN c_customer(ln_min_request_id,
                                         ln_max_request_id)
            LOOP
                BEGIN
                    -- Establish the save point
                    SAVEPOINT sp1;
                    fnd_file.put_line
                              (fnd_file.output,
                               '                                                                                      ');
                    fnd_file.put_line
                               (fnd_file.output,
                                'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ');
                    fnd_file.put_line(fnd_file.output,
                                         'Working on Order ::: '
                                      || r_customer.orig_sys_document_ref);
                    fnd_file.put_line
                               (fnd_file.output,
                                'ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo ');
                    lc_sold_to_org := r_customer.sold_to_org;
                    ln_sold_to_org_id := r_customer.sold_to_org_id;
                    ln_ship_to_org_id := r_customer.ship_to_org_id;
                    lc_ship_to_org := r_customer.ship_to_org;
                    ln_invoice_to_org_id := r_customer.invoice_to_org_id;
                    lc_sold_to_contact := r_customer.sold_to_contact;
                    ln_sold_to_contact_id := r_customer.sold_to_contact_id;
                    ln_payment_term_id := r_customer.payment_term_id;
                    lc_ship_to_sequence := r_customer.ship_to_sequence;
                    lc_ship_to_address1 := r_customer.ship_to_address1;
                    lc_ship_to_address2 := r_customer.ship_to_address2;
                    lc_ship_to_city := r_customer.ship_to_city;
                    lc_ship_to_state := r_customer.ship_to_state;
                    lc_ship_to_country := r_customer.ship_to_country;
                    lc_ship_to_zip := r_customer.ship_to_zip;
                    lc_orig_cust_name := r_customer.orig_cust_name;
                    lc_customer_po_number := r_customer.customer_po_number;
                    lc_release_no := r_customer.release_no;
                    lc_cust_dept_no := r_customer.cust_dept_no;
                    lc_desk_top_no := r_customer.desk_top_no;
                    lc_ship_to_geocode := r_customer.ship_to_geocode;

                    IF ln_sold_to_org_id IS NULL
                    THEN
                        IF r_customer.order_source = 'P'
                        THEN
                            lc_orig_system := 'RMS';

                            IF lc_sold_to_org IS NULL
                            THEN
                                lc_sold_to_org :=
                                       LPAD(SUBSTR(r_customer.orig_sys_document_ref,
                                                   1,
                                                   4),
                                            6,
                                            '0')
                                    || xx_om_sacct_conc_pkg.get_store_country
                                                                 (TO_NUMBER(SUBSTR(r_customer.orig_sys_document_ref,
                                                                                   1,
                                                                                   4) ) );
                            END IF;
                        ELSE
                            lc_orig_system := 'A0';
                        END IF;

                        BEGIN
                            SELECT owner_table_id
                            INTO   ln_sold_to_org_id
                            FROM   hz_orig_sys_references osr
                            WHERE  osr.orig_system = lc_orig_system
                            AND    osr.owner_table_name = 'HZ_CUST_ACCOUNTS'
                            AND    osr.orig_system_reference = lc_sold_to_org
                            AND    osr.status = 'A';
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                fnd_file.put_line(fnd_file.output,
                                                     'Could not find the SoldToOrgId for :'
                                                  || lc_sold_to_org
                                                  || SQLERRM);
                                RAISE NO_DATA_FOUND;
                        END;

                        IF ln_sold_to_org_id IS NOT NULL
                        THEN
                            lc_sold_to_org := NULL;
                        END IF;
                    END IF;

                    fnd_file.put_line(fnd_file.output,
                                         'SoldToOrg  :'
                                      || lc_sold_to_org);
                    fnd_file.put_line(fnd_file.output,
                                         'SoldToOrgId  :'
                                      || ln_sold_to_org_id);
                    fnd_file.put_line(fnd_file.output,
                                         'ShipToOrg  :'
                                      || lc_ship_to_org);
                    fnd_file.put_line(fnd_file.output,
                                         'Ship_to_org_id : '
                                      || ln_ship_to_org_id);

                    IF ln_payment_term_id IS NULL
                    THEN
                        ln_payment_term_id := xx_om_sacct_conc_pkg.payment_term(ln_sold_to_org_id);
                        DBMS_OUTPUT.put_line(   'Payment Term ID :'
                                             || ln_payment_term_id);
                    END IF;

                    IF ln_payment_term_id IS NULL
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'Could not find the payment term for :'
                                          || ln_sold_to_org_id);
                        RAISE NO_DATA_FOUND;
                    END IF;

                    IF lc_orig_cust_name IS NULL
                    THEN
                        SELECT party_name
                        INTO   lc_orig_cust_name
                        FROM   hz_parties p, hz_cust_accounts a
                        WHERE  a.cust_account_id = ln_sold_to_org_id
                        AND    a.party_id = p.party_id;

                        fnd_file.put_line(fnd_file.output,
                                             'Party Name is :'
                                          || lc_orig_cust_name);
                    END IF;

                    IF    ln_ship_to_org_id IS NULL
                       OR ln_invoice_to_org_id IS NULL
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'Ship_to_org_id 2 : '
                                          || ln_ship_to_org_id);

                        IF    r_customer.order_source = 'P'
                           OR (    r_customer.order_source IN('S', 'U')
                               AND r_customer.ship_to_sequence IS NULL)
                        THEN
                            xx_om_sacct_conc_pkg.get_def_shipto(p_cust_account_id =>      ln_sold_to_org_id,
                                                                     x_ship_to_org_id =>       ln_ship_to_org_id);
                            fnd_file.put_line(fnd_file.output,
                                                 'Ship_To_Org_ID is :'
                                              || ln_ship_to_org_id);
                            xx_om_sacct_conc_pkg.get_def_billto(p_cust_account_id =>      ln_sold_to_org_id,
                                                                     x_bill_to_org_id =>       ln_invoice_to_org_id);
                            fnd_file.put_line(fnd_file.output,
                                                 'Invoice_To_Org_ID is :'
                                              || ln_invoice_to_org_id);
                        ELSE
                            fnd_file.put_line(fnd_file.output,
                                                 'Ship_to_org_id 3: '
                                              || ln_ship_to_org_id);

                            IF ln_ship_to_org_id IS NULL
                            THEN
                                xx_om_sacct_conc_pkg.derive_ship_to
                                                          (p_orig_sys_document_ref =>      r_customer.orig_sys_document_ref,
                                                           p_sold_to_org_id =>             ln_sold_to_org_id,
                                                           p_order_source_id =>            r_customer.order_source_id,
                                                           p_orig_sys_ship_ref =>          lc_ship_to_org,
                                                           p_ordered_date =>               r_customer.ordered_date,
                                                           p_address_line1 =>              lc_ship_to_address1,
                                                           p_address_line2 =>              lc_ship_to_address2,
                                                           p_city =>                       lc_ship_to_city,
                                                           p_state =>                      lc_ship_to_state,
                                                           p_country =>                    lc_ship_to_country,
                                                           p_province =>                   '',
                                                           p_postal_code =>                lc_ship_to_zip,
                                                           p_order_source =>               '',
                                                           x_ship_to_org_id =>             ln_ship_to_org_id,
                                                           x_invoice_to_org_id =>          ln_invoice_to_org_id,
                                                           x_ship_to_geocode =>            lc_ship_to_geocode);
                            END IF;

                            IF ln_ship_to_org_id IS NULL
                            THEN
                                SELECT owner_table_id
                                INTO   ln_ship_to_org_id
                                FROM   hz_orig_sys_references osr,
                                       hz_cust_site_uses_all site_use,
                                       hz_locations loc,
                                       hz_party_sites site,
                                       hz_cust_acct_sites_all acct_site
                                WHERE  osr.orig_system = 'A0'
                                AND    osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'
                                AND    osr.orig_system_reference =    lc_ship_to_org
                                                                   || '-SHIP_TO'
                                AND    osr.status = 'A'
                                AND    osr.owner_table_id = site_use.site_use_id
                                AND    site_use.site_use_code = 'SHIP_TO'
                                AND    site_use.org_id = ln_org_id
                                AND    site_use.cust_acct_site_id = acct_site.cust_acct_site_id
                                AND    acct_site.party_site_id = site.party_site_id
                                AND    site.location_id = loc.location_id;
                            END IF;

                            fnd_file.put_line(fnd_file.output,
                                                 'AOPS Ship_To is :'
                                              || ln_ship_to_org_id);

                            IF ln_invoice_to_org_id IS NULL
                            THEN
                                 /*   xx_om_sacct_conc_pkg.Get_Def_BillTo( p_cust_account_id => ln_sold_to_org_id
                                                                       , x_bill_to_org_id  => ln_invoice_to_org_id
                                                                      );
                                */
                                SELECT site_use.site_use_id
                                INTO   ln_invoice_to_org_id
                                FROM   hz_cust_accounts acct,
                                       hz_cust_site_uses_all site_use,
                                       hz_cust_acct_sites_all addr
                                WHERE  acct.cust_account_id = ln_sold_to_org_id
                                AND    acct.cust_account_id = addr.cust_account_id
                                AND    addr.cust_acct_site_id = site_use.cust_acct_site_id
                                AND    site_use.site_use_code = 'BILL_TO'
                                AND    site_use.primary_flag = 'Y'
                                AND    site_use.status = 'A'
                                AND    site_use.org_id = ln_org_id;
                            END IF;

                            fnd_file.put_line(fnd_file.output,
                                                 'AOPS Bill_To is :'
                                              || ln_invoice_to_org_id);
                        END IF;
                    END IF;

                    IF    ln_ship_to_org_id IS NULL
                       OR ln_invoice_to_org_id IS NULL
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                          'Either ShipTo is NULL or BillTo is null');
                        RAISE NO_DATA_FOUND;
                    ELSE
                        lc_ship_to_org := NULL;
                    END IF;

                    IF     lc_sold_to_contact IS NOT NULL
                       AND ln_sold_to_contact_id IS NULL
                       AND r_customer.order_source <> 'P'
                    THEN
                        BEGIN
                            SELECT owner_table_id
                            INTO   ln_sold_to_contact_id
                            FROM   hz_orig_sys_references osr
                            WHERE  osr.orig_system = 'A0'
                            AND    osr.owner_table_name = 'HZ_CUST_ACCOUNT_ROLES'
                            AND    osr.orig_system_reference = lc_sold_to_contact
                            AND    osr.status = 'A';
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                fnd_file.put_line(fnd_file.LOG,
                                                     'Could not find the SoldToContact for :'
                                                  || lc_sold_to_contact
                                                  || SQLERRM);
                        END;

                        fnd_file.put_line(fnd_file.output,
                                             'Sold To Contact Id is :'
                                          || ln_sold_to_contact_id);

                        IF ln_sold_to_contact_id IS NOT NULL
                        THEN
                            lc_sold_to_contact := NULL;
                        END IF;
                    END IF;

                    -- For SPC and PRO card orders, get the Soft Header Info and Actual ShipTo address
                    IF     r_customer.order_source IN('S', 'U')
                       AND ln_sold_to_org_id IS NOT NULL
                       AND ln_ship_to_org_id IS NOT NULL
                    THEN
                        BEGIN
                            -- Get the ShipTo address
                            SELECT address1,
                                   address2,
                                   city,
                                   NVL(state,
                                       province),
                                   country,
                                   postal_code
                            INTO   lc_ship_to_address1,
                                   lc_ship_to_address2,
                                   lc_ship_to_city,
                                   lc_ship_to_state,
                                   lc_ship_to_country,
                                   lc_ship_to_zip
                            FROM   hz_cust_site_uses_all a,
                                   hz_cust_acct_sites_all b,
                                   hz_party_sites c,
                                   hz_locations d
                            WHERE  a.site_use_id = ln_ship_to_org_id
                            AND    b.cust_account_id = ln_sold_to_org_id
                            AND    b.cust_acct_site_id = a.cust_acct_site_id
                            AND    b.party_site_id = c.party_site_id
                            AND    c.location_id = d.location_id;

                            DBMS_OUTPUT.put_line(   'Data Found for Ship_To Address '
                                                 || SQL%ROWCOUNT);
                        EXCEPTION
                            WHEN OTHERS
                            THEN
                                fnd_file.put_line(fnd_file.LOG,
                                                     'In Others :'
                                                  || SQLERRM);
                                fnd_file.put_line
                                                (fnd_file.LOG,
                                                    'Failed to get either the soft header or shipto address for order :'
                                                 || r_customer.orig_sys_document_ref);
                                RAISE NO_DATA_FOUND;
                        END;
                    END IF;

                    IF     ln_sold_to_org_id IS NOT NULL
                       AND ln_ship_to_org_id IS NOT NULL
                       AND ln_invoice_to_org_id IS NOT NULL
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'Updating interface data for order :'
                                          || r_customer.orig_sys_document_ref);

                        UPDATE oe_payments_iface_all
                        SET sold_to_org_id = ln_sold_to_org_id,
                            credit_card_holder_name = lc_orig_cust_name
                        WHERE  orig_sys_document_ref = r_customer.orig_sys_document_ref
                        AND    order_source_id = r_customer.order_source_id;

                        UPDATE xx_om_ret_tenders_iface_all
                        SET sold_to_org_id = ln_sold_to_org_id,
                            credit_card_holder_name = lc_orig_cust_name
                        WHERE  orig_sys_document_ref = r_customer.orig_sys_document_ref
                        AND    order_source_id = r_customer.order_source_id;

                        UPDATE oe_lines_iface_all
                        SET sold_to_org_id = ln_sold_to_org_id,
                            ship_to_org_id = ln_ship_to_org_id,
                            invoice_to_org_id = ln_invoice_to_org_id,
                            payment_term_id = ln_payment_term_id
                        WHERE  orig_sys_document_ref = r_customer.orig_sys_document_ref
                        AND    order_source_id = r_customer.order_source_id;

                        UPDATE oe_headers_iface_all
                        SET sold_to_org_id = ln_sold_to_org_id,
                            sold_to_org = lc_sold_to_org,
                            ship_to_org_id = ln_ship_to_org_id,
                            ship_to_org = lc_ship_to_org,
                            invoice_to_org_id = ln_invoice_to_org_id,
                            sold_to_contact_id = ln_sold_to_contact_id,
                            sold_to_contact = lc_sold_to_contact,
                            payment_term_id = ln_payment_term_id,
                            error_flag = NULL,
                            request_id = NULL,
                            customer_po_number = lc_customer_po_number
                        WHERE  orig_sys_document_ref = r_customer.orig_sys_document_ref
                        AND    order_source_id = r_customer.order_source_id;

                        UPDATE xx_om_headers_attr_iface_all
                        SET ship_to_geocode = lc_ship_to_geocode,
                            ship_to_address1 = lc_ship_to_address1,
                            ship_to_address2 = lc_ship_to_address2,
                            ship_to_city = lc_ship_to_city,
                            ship_to_state = lc_ship_to_state,
                            ship_to_country = lc_ship_to_country,
                            ship_to_zip = lc_ship_to_zip
                        -- , orig_cust_name = lc_orig_cust_name
                        -- , release_no = lc_release_no
                        -- , cust_dept_no = lc_cust_dept_no
                        -- , desk_top_no = lc_desk_top_no
                        WHERE  orig_sys_document_ref = r_customer.orig_sys_document_ref
                        AND    order_source_id = r_customer.order_source_id;

                        -- set the order counter
                        ln_count :=   ln_count
                                    + 1;
                    END IF;
                EXCEPTION
                    WHEN PROGRAM_ERROR
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'Failed to process order :'
                                          || r_customer.orig_sys_document_ref);
                        ROLLBACK TO sp1;
                    WHEN NO_DATA_FOUND
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'In No Data Found for process order :'
                                          || r_customer.orig_sys_document_ref);
                        ROLLBACK TO sp1;
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'Unexpected error in processing order :'
                                          || r_customer.orig_sys_document_ref);
                        fnd_file.put_line(fnd_file.LOG,
                                             'SQLERRM::'
                                          || SQLERRM);
                        ROLLBACK TO sp1;
                END;
            END LOOP;
        END IF;

        -- Commit the changes
        COMMIT;

-- Code Modification for Qc 31475(Failed to Derive Customer Data with an incomplete ship to org(the API will update the stuck order with sold_to_org_id,ship_to_org_id
--and invoice_to_org_id and will make the order eligible for ORDER IMPORT))
-- so order import picks up the orders when submitted
 /* Variable Declaration */
DECLARE
l_invoice_to_org_id NUMBER;
l_sold_to_org_id    NUMBER;
l_ship_to_org_id    NUMBER;

CURSOR c_order IS
SELECT orig_sys_document_REf
       ,h.order_source_id
       ,sold_to_org
  FROM oe_headers_iface_all h,oe_processing_msgs_vl m
 WHERE sold_to_org_id IS NULL
   AND ship_to_org_id IS NULL
   AND invoice_to_org_id IS NULL
   and h.orig_sys_document_ref = m.original_sys_document_ref
   AND H.Order_Source_Id   = M.Order_Source_Id
   AND h.error_flag = 'Y'
   AND m.message_text LIKE '%10000010%';


BEGIN
FOR c1_order  IN c_order

LOOP
BEGIN
      fnd_file.put_line(fnd_file.OUTPUT,'Start of Missing customer Validation');


SELECT hcs.cust_account_id,hcu.site_use_id
  INTO l_sold_to_org_id,l_ship_to_org_id
  FROM   HZ_CUST_ACCT_SITES_ALL HCS,hz_cust_site_uses_all hcu
 WHERE hcs.orig_system_reference  = c1_order.sold_to_org
   AND hcs.status = 'A'
   AND hcu.site_use_code = 'SHIP_TO'
   AND hcs.cust_acct_site_id = hcu.cust_acct_site_id;


SELECT hcu.site_use_id
  INTO l_invoice_to_org_id
  FROM   HZ_CUST_ACCT_SITES_ALL HCS,hz_cust_site_uses_all hcu
 WHERE hcs.orig_system_reference = c1_order.sold_to_org
   AND hcs.status = 'A'
   AND hcu.site_use_code = 'BILL_TO'
   AND hcs.cust_acct_site_id = hcu.cust_acct_site_id;

   UPDATE oe_lines_iface_all
   SET sold_to_org_id = l_sold_to_org_id,
       ship_to_org_id =  l_ship_to_org_id,
       invoice_to_org_id = l_invoice_to_org_id
WHERE orig_sys_document_Ref = C1_order.orig_sys_document_Ref
and order_source_id = C1_order.order_source_id;

UPDATE oe_headers_iface_all
   SET sold_to_org_id = l_sold_to_org_id,
       ship_to_org_id = l_ship_to_org_id,
       invoice_to_org_id = l_invoice_to_org_id,
       ship_to_org = NULL,
       sold_to_org = NULL,
       error_flag  = NULL,
       request_id  = NULL
WHERE orig_sys_document_Ref = C1_order.orig_sys_document_Ref
and order_source_id = C1_order.order_source_id;



        fnd_file.put_line(fnd_file.OUTPUT,'Total number of Orders updated for Missing customer Validation::'|| SQL%ROWCOUNT);
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.OUTPUT,
                              'NO Orders to be processed for Missing customer Validation');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED IN "Missing customer Validation" :'
                              || SQLERRM);
 END;
 END LOOP;
 END;
--end of code modification for 31475
    END customer_validation;

    PROCEDURE deposit_customer_validation
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : DEPOSIT_CUSTOMER_VALIDATION                                     |
-- | Description      : This Procedure will derive customer id CC name and   |
-- |                    update error_flag so i1025 program pick up when      |
-- |                    submitted                                            |
-- |DRAFT1D 29-AUG-2013 Saritha Mummaneni   Modified code to update errored  |
-- |                                        deposits with customer           |
-- |                                        information
-- |DRAFT1E 25-SEP-2014 AMS SCM Team        Modified code to update Deposit's|
-- |                                       Error Flag as N when customer     |
-- |                                       information exist                 |
-- +=========================================================================+



--code modification for QC 31475(Deposit Validation: the API will update the deposits' error flag to N which have customer information but stuck in NEW status)


l_invoice_to_org_id NUMBER;

	CURSOR c_Dep IS
	select d.transaction_number,d.order_source_id
	from xx_om_legacy_Deposits d,xx_om_legacy_Dep_Dtls dd
	where d.transaction_number = dd.transaction_number
	and d.i1025_status = 'NEW'
	and d.error_flag = 'Y'
	and d.sold_to_org_id is not null
	and d.credit_card_holder_name is not null;




BEGIN
FOR c1_Dep  IN c_dep

   LOOP
BEGIN
      fnd_file.put_line(fnd_file.OUTPUT,'Start of Deposit Validation');

     update xx_om_legacy_Deposits
  set error_flag = 'N'
  where transaction_number = c1_Dep.transaction_number
  and order_source_id = c1_Dep.order_source_id;

        fnd_file.put_line(fnd_file.OUTPUT,'Total number of Deposits updated with error flag::'|| SQL%ROWCOUNT);
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.OUTPUT,
                              'NO deposits to be processed ');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED IN "Deposit Validation" :'
                              || SQLERRM);
 END;
 END LOOP;

--end of code modification for QC 31475
DECLARE
        ln_from_request_id  NUMBER;
        ln_to_request_id    NUMBER;
        ln_count            NUMBER := 0;

        CURSOR c_sold_to_org(
            p_from_req_id  IN  NUMBER,
            p_to_req_id    IN  NUMBER)
        IS
            SELECT   dd.orig_sys_document_ref   -- As per Draft 1D
                                             ,
                     d.transaction_number   --- As per Draft 1D
                                         ,
                     MESSAGE_TEXT,
                     NVL(d.sold_to_org,
                         SUBSTR(MESSAGE_TEXT,
                                  INSTR(MESSAGE_TEXT,
                                        '-',
                                        1)
                                + 1,
                                17) ) sold_to_org
            FROM     xx_om_legacy_deposits d,
                     xx_om_legacy_dep_dtls dd   --- As per Draft 1D
                                                  ,
                     oe_processing_msgs m,
                     xx_om_sacct_file_history s
            WHERE    s.request_id BETWEEN p_from_req_id AND p_to_req_id
            AND      s.file_type = 'DEPOSIT'
            AND      s.file_name = d.imp_file_name
            AND      d.transaction_number = dd.transaction_number   --- As per Draft 1D
            AND      d.transaction_number = m.original_sys_document_ref
            AND      d.order_source_id = m.order_source_id
            AND      SUBSTR(m.MESSAGE_TEXT,
                            1,
                            8) IN(SUBSTR('10000019',
                                         1,
                                         8), SUBSTR('10000004',
                                                    1,
                                                    8) )
            AND      d.error_flag = 'Y'
            ORDER BY 1;

        CURSOR c_cust_name(
            p_cust  IN  VARCHAR2)
        IS
            SELECT cust_account_id,
                   party_name
            FROM   hz_cust_accounts a, hz_parties p
            WHERE  a.party_id = p.party_id
            AND    a.orig_system_reference = p_cust;
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Begin DEPOSIT_CUSTOMER_VALIDATION');

        SELECT MIN(xld.request_id),
               MAX(xld.request_id)
        INTO   ln_from_request_id,
               ln_to_request_id
        FROM   xx_om_legacy_deposits xld, oe_processing_msgs_vl opm
        WHERE  xld.transaction_number = opm.original_sys_document_ref
        AND    xld.order_source_id = opm.order_source_id
        AND    SUBSTR(opm.MESSAGE_TEXT,
                      1,
                      8) IN('10000004', '10000019')
        AND    xld.i1025_status = 'NEW'
        --  AND xld.creation_date >= SYSDATE- 14;
        AND    NVL(xld.error_flag,
                   'N') = 'Y';

        IF ln_from_request_id IS NULL
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NO Deposit Errors for Message 10000004 ');
        ELSE
            FOR r_sold_to_org IN c_sold_to_org(ln_from_request_id,
                                               ln_to_request_id)
            LOOP
                FOR r_cust_name IN c_cust_name(r_sold_to_org.sold_to_org)
                LOOP
                    fnd_file.put_line(fnd_file.output,
                                         'orig_sys_document_ref::'
                                      || r_sold_to_org.orig_sys_document_ref
                                      || ' Cust_account_id:::'
                                      || r_cust_name.cust_account_id
                                      || ' Party Name :::'
                                      || r_cust_name.party_name);

                    UPDATE xx_om_legacy_deposits
                    SET sold_to_org_id = r_cust_name.cust_account_id,
                        credit_card_holder_name = r_cust_name.party_name,
                        error_flag = 'N'
                    WHERE  transaction_number =
                               (SELECT transaction_number   --- As per Draft 1D
                                FROM   xx_om_legacy_dep_dtls
                                WHERE  transaction_number = r_sold_to_org.transaction_number
                                AND    orig_sys_document_ref = r_sold_to_org.orig_sys_document_ref)
                    --  AND error_flag            = 'Y'
                    AND    sold_to_org_id IS NULL;

                    ln_count :=   ln_count
                                + SQL%ROWCOUNT;
                END LOOP;
            END LOOP;
        END IF;

        fnd_file.put_line(fnd_file.output,
                             'NO OF DEPOSITS UPDATED::: '
                          || ln_count);
        -- Commit the changes
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'No Data Found For Deposit Errors Customer Validation:::');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS IN DEPOSIT_CUSTOMER_VALIDATION :::'
                              || SQLERRM);
    END;
    END deposit_customer_validation;

    PROCEDURE process_c_status_deposits
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : PROCESS_C_STATUS_DEPOSITS                                       |
-- | Description      : This Procedure will update i1025_status for deposits |
-- |                    where AOPS order does not have a payment or AOPS ord |
-- |                    as not yet processed to EBS                          |
-- |DRAFT1D  Saritha Mummaneni Modifed cursor logic to include               |
-- |                               xx_om_legacy_dep_dtls                     |
-- +=========================================================================+
        ln_count  NUMBER := 0;

        CURSOR c_depo_order
        IS
            SELECT dd.orig_sys_document_ref   -- As per Draft 1D
                                           ,
                   d.transaction_number   -- As per Draft 1D
                                       ,
                   d.i1025_status,
                   h.order_number,
                   d.imp_file_name,
                   d.creation_date
            FROM   xx_om_legacy_deposits d,
                   xx_om_legacy_dep_dtls dd   --- As per Draft 1D
                                                ,
                   oe_order_headers_all h
            WHERE  d.i1025_status = 'COMPLETE'
            AND    d.creation_date > '28-JUN-09'
            AND    d.transaction_number = dd.transaction_number   --- As per Draft 1D
            AND    dd.orig_sys_document_ref = h.orig_sys_document_ref(+)
            AND    h.order_number IS NULL;
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Begin PROCESS_C_STATUS_DEPOSITS');

        FOR r_depo_order IN c_depo_order
        LOOP
            --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'r_depo_order.orig_sys_document_ref = '||r_depo_order.orig_sys_document_ref);
            UPDATE xx_om_legacy_deposits
            SET i1025_status = 'NEW'
            WHERE  i1025_status = 'COMPLETE'
            AND    transaction_number =
                       (SELECT transaction_number   --- As per Draft 1D
                        FROM   xx_om_legacy_dep_dtls
                        WHERE  transaction_number = r_depo_order.transaction_number
                        AND    orig_sys_document_ref = r_depo_order.orig_sys_document_ref);

            ln_count :=   ln_count
                        + SQL%ROWCOUNT;
        END LOOP;

        fnd_file.put_line(fnd_file.output,
                             'Total Deposit Records updated!!!'
                          || ln_count);
        -- Commit the changes
        COMMIT;
        fnd_file.put_line(fnd_file.output,
                          'END OF PROCESS_C_STATUS_DEPOSITS');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NO Orders to be processed for Deposit Errors for Depsoit Satus Complete');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS IN PROCESS_C_STATUS_DEPOSITS :::'
                              || SQLERRM);
    END process_c_status_deposits;

    PROCEDURE location_in_wrong_opu
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : LOCATION_IN_WRONG_OPU                                           |
-- | Description      : This Procedure will update error_flag and request_id |
-- |                    of oe_headers_iface_all to process orders            |
-- |                                                                         |
-- |                                                                         |
-- +=========================================================================+
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Begin LOCATION_IN_WRONG_OPU');

        UPDATE oe_headers_iface_all h
        SET error_flag = NULL,
            request_id = NULL
        WHERE  NVL(h.error_flag,
                   'N') = 'Y'
        AND    EXISTS(
                   SELECT 1
                   FROM   oe_processing_msgs_vl m
                   WHERE  h.orig_sys_document_ref = m.original_sys_document_ref
                   AND    h.order_source_id = m.order_source_id
                   AND    m.MESSAGE_TEXT LIKE '10000037%');

        fnd_file.put_line(fnd_file.output,
                             'Total No of orders updated for wrong location '
                          || SQL%ROWCOUNT);
        fnd_file.put_line(fnd_file.output,
                          'END OF LOCATION_IN_WRONG_OPU');
        -- Commit the changes
        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED FOR LOCATION_IN_WRONG_OPU : '
                              || SQLERRM);
    END location_in_wrong_opu;

    PROCEDURE not_high_volume_order
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : NOT_HIGH_VOLUME_ORDER                                           |
-- | Description      : This Procedure will update  request_id of            |
-- |                    oe_headers_iface_all to process orders by Order Imp  |
-- |                                                                         |
-- |                                                                         |
-- +=========================================================================+
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Begin NOT_HIGH_VOLUME_ORDER');

        UPDATE oe_headers_iface_all h
        SET request_id = NULL
        WHERE  EXISTS(
                   SELECT 1
                   FROM   oe_processing_msgs_vl m
                   WHERE  m.original_sys_document_ref = h.orig_sys_document_ref
                   AND    m.order_source_id = h.order_source_id
                   AND    m.MESSAGE_TEXT LIKE
                                 'You cannot create return orders or return order lines using high volume order import%'
                   AND    h.request_id IS NOT NULL);

        fnd_file.put_line(fnd_file.output,
                             'Total No of orders updated for NOT_HIGH_VOLUME_ORDER '
                          || SQL%ROWCOUNT);
        fnd_file.put_line(fnd_file.output,
                          'END OF NOT_HIGH_VOLUME_ORDER');
        -- Commit the changes
        COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED FOR NOT_HIGH_VOLUME_ORDER : '
                              || SQLERRM);
    END not_high_volume_order;

    PROCEDURE off_line_deposits
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : OFF_LINE_DEPOSITS                                               |
-- | Description      : This Procedure will update customer reference num    |
-- |                    by connecting to AOPS system using DB LINK i.e. AS400|
-- |                                                                         |
-- +=========================================================================+
        CURSOR c_miss_cust_depo
        IS
            SELECT DISTINCT MESSAGE_TEXT,
                            dd.orig_sys_document_ref,
                            d.transaction_number   --- As per Draft 1D
            FROM            oe_processing_msgs_vl m,
                            xx_om_legacy_deposits d,
                            xx_om_legacy_dep_dtls dd   --- As per Draft 1D
            WHERE           d.transaction_number = m.original_sys_document_ref
            AND             d.transaction_number = dd.transaction_number   --- As per Draft 1D
            AND             d.order_source_id = m.order_source_id
            AND             NVL(d.error_flag,
                                'N') = 'Y'
            AND             d.i1025_status = 'NEW'
            AND             MESSAGE_TEXT LIKE '10000019%'
            UNION
            SELECT DISTINCT MESSAGE_TEXT,
                            dd.orig_sys_document_ref,
                            d.transaction_number   --- As per Draft 1D
            FROM            oe_processing_msgs_vl m,
                            xx_om_legacy_deposits d,
                            xx_om_legacy_dep_dtls dd   --- As per Draft 1D
            WHERE           d.transaction_number = m.original_sys_document_ref
            AND             d.transaction_number = dd.transaction_number   --- As per Draft 1D
            AND             d.order_source_id = m.order_source_id
            AND             NVL(d.error_flag,
                                'N') = 'Y'
            AND             d.i1025_status = 'NEW'
            AND             MESSAGE_TEXT LIKE '10000004%'
            AND             sold_to_org LIKE '9%'
            ORDER BY        1;

--Variable Declaration
        qry_stat               VARCHAR2(4000);
        ln_db_link_test        DATE;
        lc_db_link1            VARCHAR2(240);
        lc_db_link2            VARCHAR2(240);
        lc_customer            VARCHAR2(80);
        l_count                NUMBER         := 0;
        ld_date                DATE;

        TYPE c_dblink_check IS REF CURSOR;

        c_ref_dblink_chk_type  c_dblink_check;
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Begin OFF_LINE_DEPOSITS');

        SELECT xftv.target_value1,
               xftv.target_value2
        INTO   lc_db_link1,
               lc_db_link2
        FROM   xx_fin_translatedefinition xftd, xx_fin_translatevalues xftv
        WHERE  1 = 1
        AND    xftd.translation_name = 'XXOD_AS400_DB_LINK'
        AND    xftd.translate_id = xftv.translate_id
        AND    SYSDATE BETWEEN xftd.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1)
        AND    SYSDATE BETWEEN xftv.start_date_active AND NVL(xftd.end_date_active,
                                                                SYSDATE
                                                              + 1);

        BEGIN
            --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'lc_db_link2. '||lc_db_link2);
            qry_stat :=    'SELECT SYSDATE FROM racoondta.fco101p@'
                        || lc_db_link1
                        || ' WHERE ROWNUM < 2';

            BEGIN
                OPEN c_ref_dblink_chk_type FOR qry_stat;

                LOOP
                    FETCH c_ref_dblink_chk_type
                    INTO  ld_date;

                    EXIT WHEN c_ref_dblink_chk_type%NOTFOUND;
                END LOOP;

                CLOSE c_ref_dblink_chk_type;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    BEGIN
                        qry_stat :=    'SELECT SYSDATE FROM racoondta.fco101p@'
                                    || lc_db_link2
                                    || ' WHERE ROWNUM < 2';

                        OPEN c_ref_dblink_chk_type FOR qry_stat;

                        LOOP
                            FETCH c_ref_dblink_chk_type
                            INTO  ld_date;

                            EXIT WHEN c_ref_dblink_chk_type%NOTFOUND;
                        END LOOP;

                        CLOSE c_ref_dblink_chk_type;

                        lc_db_link1 := lc_db_link2;
                    EXCEPTION
                        WHEN NO_DATA_FOUND
                        THEN
                            fnd_file.put_line(fnd_file.output,
                                              'No ACTIVE DB LINKS FOUND TRY WHEN THEY ARE ACTIVE. ');
                            GOTO end_of_proc;
                    END;
            END;
        END;

        fnd_file.put_line(fnd_file.LOG,
                             'DB Link : '
                          || lc_db_link1);

        FOR r_miss_cust_depo IN c_miss_cust_depo
        LOOP
            BEGIN
                qry_stat :=
                       'SELECT FCO101p_customer_id FROM racoondta.fco101p@'
                    || lc_db_link1
                    || 'WHERE FCO101p_order_nbr = SUBSTR(r_miss_cust_depo.orig_sys_document_ref,1,9)';

                OPEN c_ref_dblink_chk_type FOR qry_stat;

                LOOP
                    FETCH c_ref_dblink_chk_type
                    INTO  lc_customer;

                    EXIT WHEN c_ref_dblink_chk_type%NOTFOUND;
                END LOOP;

                CLOSE c_ref_dblink_chk_type;

                IF lc_customer IS NOT NULL
                THEN
                    lc_customer :=    lc_customer
                                   || '-00001-A0';
                ELSE
                    lc_customer := NULL;
                END IF;

                UPDATE xx_om_legacy_deposits
                SET sold_to_org = lc_customer
                WHERE  1 =
                           1   --orig_sys_document_ref = r_miss_cust_depo.orig_sys_document_ref;  -- Commented as per Draft 1D
                AND    transaction_number =
                           (SELECT transaction_number   --- As per Draft 1D
                            FROM   xx_om_legacy_dep_dtls
                            WHERE  transaction_number = r_miss_cust_depo.transaction_number
                            AND    orig_sys_document_ref = r_miss_cust_depo.orig_sys_document_ref);

                l_count :=   l_count
                           + 1;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    GOTO end_of_proc;
            END;
        END LOOP;

        <<end_of_proc>>
        fnd_file.put_line(fnd_file.output,
                             'Total No of offline deposits updated : '
                          || l_count);
        fnd_file.put_line(fnd_file.output,
                          'END OF OFF_LINE_DEPOSITS');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'No OFFLINE DEPOSITS TO PROCESSED');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED FOR OFF_LINE_DEPOSITS : '
                              || SQLERRM);
    END off_line_deposits;

    PROCEDURE unapply_and_apply_rct
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : OFF_LINE_DEPOSITS                                               |
-- | Description      : This Procedure will unapply and apply receipt for    |
-- |                    orders where a deposit exists rel 11.3 ADD for SDR   |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1C 06-FEB-2012 Oracle AMS Team   Modified to pick POS orders to     |
-- |                      apply and unapply for deposit order|
-- |                                                                         |
-- +=========================================================================+
        CURSOR c_order
        IS
            SELECT   orig_sys_document_ref,
                     order_source_id
            FROM     oe_headers_iface_all h
            WHERE    EXISTS(
                         SELECT DISTINCT original_sys_document_ref
                         FROM            oe_processing_msgs_vl m
                         WHERE           MESSAGE_TEXT LIKE
                                                   '10000030: reapply_deposit_prepayment did not return Payment set id%'
                         AND             m.original_sys_document_ref = h.orig_sys_document_ref
                         AND             m.order_source_id = h.order_source_id)
            AND      EXISTS(
                         SELECT 1
                         FROM   oe_actions_iface_all a
                         WHERE  a.orig_sys_document_ref = h.orig_sys_document_ref
                         AND    a.order_source_id = h.order_source_id)
            AND      NVL(error_flag,
                         'N') = 'Y'
            --AND orig_sys_document_ref IN('562184114001', '558754570001')
            ORDER BY 1;

        CURSOR c_order_payment(
            p_order_number     VARCHAR2,
            p_order_source_id  NUMBER)
        IS
            SELECT   orig_sys_document_ref orig_sys_document_ref,
                     TO_NUMBER(attribute15) cash_receipt_id,
                     payment_set_id payment_set_id,
                     prepaid_amount prepaid_amount,
                     payment_number payment_number,
                     order_source_id order_source_id
            FROM     oe_payments_iface_all p
            WHERE    EXISTS(
                         SELECT DISTINCT original_sys_document_ref
                         FROM            oe_processing_msgs_vl m
                         WHERE           MESSAGE_TEXT LIKE '10000030%'
                         AND             m.original_sys_document_ref = p_order_number
                         AND             m.order_source_id = p.order_source_id)
            AND      orig_sys_document_ref =    p_order_number
                                             || '-BYPASS'
            AND      order_source_id = p_order_source_id
            AND      EXISTS(SELECT 1
                            FROM   oe_actions_iface_all a
                            WHERE  a.orig_sys_document_ref = p_order_number)
            ORDER BY payment_number;

        ln_header_id              NUMBER;
        ln_payment_set_id         NUMBER;
        lc_return_status          VARCHAR2(1);
        ln_msg_count              NUMBER;
        lc_msg_data               VARCHAR2(2000);
        --ln_user                  NUMBER := 29497;
        --ln_appl                  NUMBER := 222;
        --ln_resp                  NUMBER := 50517;
        ln_avail_balance          NUMBER;
        ln_deposit_amt            NUMBER;
        lc_application_ref_num    VARCHAR2(80);
        lc_orig_sys_document_ref  VARCHAR2(80);
        ln_set_id_count           NUMBER;
        ln_order_count            NUMBER         := 0;
        ln_payment_count          NUMBER         := 0;
        lc_cash_receipt_id        NUMBER         := 0;
        ln_orig_sys_doc           NUMBER         := 0;   -- As per Draft 1C
    BEGIN
        fnd_file.put_line(fnd_file.output,
                          'Beginning  of Program UNAPPLY_AND_APPLY_RCT ');

        -- FND_GLOBAL.apps_initialize(ln_user,ln_resp,ln_appl);
        FOR r_order IN c_order
        LOOP
            FOR r_ord_pay IN c_order_payment(r_order.orig_sys_document_ref,
                                             r_order.order_source_id)
            LOOP
                --  GET transaction number to pass to rec app table
                lc_application_ref_num := NULL;
                lc_orig_sys_document_ref := NULL;
                lc_cash_receipt_id := NULL;
                ln_orig_sys_doc := NULL;   -- As per Draft 1C

                BEGIN
                    fnd_file.put_line(fnd_file.output,
                                         'orig_sys_document_ref :::'
                                      || r_order.orig_sys_document_ref);

                    SELECT LENGTH(r_order.orig_sys_document_ref)
                    INTO   ln_orig_sys_doc
                    FROM   DUAL;   -- As per Draft 1C

                    IF ln_orig_sys_doc = 12
                    THEN   -- As per Draft 1C
                        SELECT d.transaction_number,
                               dd.orig_sys_document_ref,
                               d.cash_receipt_id
                        INTO   lc_application_ref_num,
                               lc_orig_sys_document_ref,
                               lc_cash_receipt_id
                        FROM   xx_om_legacy_deposits d, xx_om_legacy_dep_dtls dd
                        WHERE  d.transaction_number = dd.transaction_number
                        AND    SUBSTR(dd.orig_sys_document_ref,
                                      1,
                                      9) = SUBSTR(r_order.orig_sys_document_ref,
                                                  1,
                                                  9)
                        AND    d.prepaid_amount > 0
                        AND    d.payment_set_id IS NOT NULL
                        AND    ROWNUM < 2;
                    ELSIF ln_orig_sys_doc >= 19
                    THEN   -- As per Draft 1C
                        SELECT d.transaction_number,
                               dd.orig_sys_document_ref,
                               d.cash_receipt_id
                        INTO   lc_application_ref_num,
                               lc_orig_sys_document_ref,
                               lc_cash_receipt_id
                        FROM   xx_om_legacy_deposits d, xx_om_legacy_dep_dtls dd
                        WHERE  d.transaction_number = dd.transaction_number
                        --   AND dd.orig_sys_document_ref            = 20                      -- As per Draft 1C
                        AND    dd.orig_sys_document_ref = r_order.orig_sys_document_ref
                        AND    d.prepaid_amount > 0
                        AND    d.payment_set_id IS NOT NULL
                        AND    ROWNUM < 2;
                    END IF;

                    IF r_ord_pay.cash_receipt_id IS NULL
                    THEN
                        r_ord_pay.cash_receipt_id := lc_cash_receipt_id;
                    END IF;
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                          'No Data Found for order aganist deposit ');
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'WHEN OTHERS RAISED calling deposit '
                                          || SQLERRM);
                END;

                BEGIN
                    UPDATE ar_receivable_applications_all
                    SET application_ref_num = lc_application_ref_num
                    WHERE  cash_receipt_id = r_ord_pay.cash_receipt_id
                    AND    application_ref_num = lc_orig_sys_document_ref
                    AND    application_ref_type = 'SA';
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        fnd_file.put_line(fnd_file.output,
                                             'WHEN OTHERS RAISED while updating rec apps '
                                          || SQLERRM);
                END;

                SELECT oe_order_headers_s.NEXTVAL
                INTO   ln_header_id
                FROM   DUAL;

                --  dbms_output.put_line('order number :'|| r_ord_pay.orig_sys_document_ref);
                --  dbms_output.put_line('cash receipt id :'|| r_ord_pay.cash_receipt_id);
                --  dbms_output.put_line('payment set id :'|| r_ord_pay.prepaid_amount);
                --  dbms_output.put_line('header id :'|| ln_header_id);
                ln_payment_set_id := NULL;
                xx_ar_prepayments_pkg.reapply_deposit_prepayment(p_init_msg_list =>         fnd_api.g_false,
                                                                 p_commit =>                fnd_api.g_false,
                                                                 p_validation_level =>      fnd_api.g_valid_level_full,
                                                                 p_cash_receipt_id =>       r_ord_pay.cash_receipt_id,
                                                                 p_header_id =>             ln_header_id,
                                                                 p_order_number =>          r_order.orig_sys_document_ref,
                                                                 p_apply_amount =>          r_ord_pay.prepaid_amount,
                                                                 x_payment_set_id =>        ln_payment_set_id,
                                                                 x_return_status =>         lc_return_status,
                                                                 x_msg_count =>             ln_msg_count,
                                                                 x_msg_data =>              lc_msg_data);
                fnd_file.put_line(fnd_file.output,
                                     'lc_return_status ::'
                                  || lc_return_status);
                fnd_file.put_line(fnd_file.output,
                                     'Error Message    ::'
                                  || SUBSTR(lc_msg_data,
                                            1,
                                            2000) );

                -- dbms_output.put_line('lc_return_status :'|| lc_return_status);
                -- dbms_output.put_line('lc_msg_data :'|| Substr(lc_msg_data,1,2000));
                IF ln_payment_set_id IS NOT NULL
                THEN
                    ln_payment_count :=   ln_payment_count
                                        + 1;

                    UPDATE oe_payments_iface_all
                    SET payment_set_id = ln_payment_set_id
                    WHERE  orig_sys_document_ref = r_ord_pay.orig_sys_document_ref
                    AND    order_source_id = r_ord_pay.order_source_id
                    AND    payment_number = r_ord_pay.payment_number;
                END IF;
            END LOOP;

            SELECT COUNT(*)
            INTO   ln_set_id_count
            FROM   oe_payments_iface_all
            WHERE  orig_sys_document_ref =    r_order.orig_sys_document_ref
                                           || '-BYPASS'
            AND    order_source_id = r_order.order_source_id
            AND    payment_set_id IS NULL;

            IF ln_set_id_count = 0
            THEN
                ln_order_count :=   ln_order_count
                                  + 1;

                UPDATE oe_headers_iface_all
                SET error_flag = NULL,
                    request_id = NULL,
                    booked_flag = 'Y',
                    batch_id = NULL,
                    ineligible_for_hvop = 'Y'
                WHERE  orig_sys_document_ref = r_order.orig_sys_document_ref
                AND    order_source_id = r_order.order_source_id;

                DELETE FROM oe_actions_iface_all
                WHERE       orig_sys_document_ref = r_order.orig_sys_document_ref
                AND         order_source_id = r_order.order_source_id;
            ELSE
                fnd_file.put_line(fnd_file.output,
                                     'The receipt did not get unapplied for order ::: '
                                  || r_order.orig_sys_document_ref);
            END IF;
        END LOOP;

        COMMIT;
        fnd_file.put_line(fnd_file.output,
                             'Total Number of payment sucessfully got applied ::'
                          || ln_payment_count);
        fnd_file.put_line(fnd_file.output,
                             'Total Number of orders where error flag got updated ::'
                          || ln_order_count);
        fnd_file.put_line(fnd_file.output,
                          'End of Program ');
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.output,
                              'No Data Found Error Raised ');
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.output,
                                 'WHEN OTHERS RAISED '
                              || SQLERRM);
    END unapply_and_apply_rct;
PROCEDURE update_default_salesrep    -- Defect#42629         
IS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  Office Depot                                             |
-- +===========================================================================+
-- | Name  : update_default_salesrep                                           |
-- | Description      : This Procedure will look for Orders stuck in Interface |
-- |                    with Validation failed for the field -Salesperson      |
-- |                    this procedure will update default sales rep as        |
-- |                    "Depot Office"                                         | 
-- |                                                                           |   
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
ln_sales_rep  NUMBER := fnd_profile.VALUE('ONT_DEFAULT_PERSON_ID');
ln_org_id     NUMBER := FND_PROFILE.VALUE('ORG_ID');
BEGIN
        fnd_file.put_line(fnd_file.output,
                         'Begin update_default_salesrep');
        fnd_file.put_line(fnd_file.output,
                         ' Salesrep value is -  '||ln_sales_rep );				  
        fnd_file.put_line(fnd_file.output,
                         ' Org Id -  '||ln_org_id );	
    IF ln_sales_rep IS NULL
    THEN
        fnd_file.put_line(fnd_file.output,
                         'Sales rep value is null from profile option now deriving from jtf tables');
        BEGIN
            SELECT salesrep_id 
              INTO ln_sales_rep
              FROM jtf_rs_salesreps
             WHERE name    = 'Depot, Office'
               AND org_id  =  ln_org_id;
        EXCEPTION
        WHEN OTHERS
        THEN
            ln_sales_rep := NULL;
            fnd_file.put_line(fnd_file.output,
            'Exception to derive default sales rep from jtf table - '||SQLERRM);
        END;		
    END IF;
    IF ln_sales_rep IS NOT NULL
    THEN	
        
        UPDATE oe_lines_iface_all l
           SET salesrep_id = ln_sales_rep
         WHERE EXISTS( SELECT 1
                         FROM oe_processing_msgs_vl m
                             ,oe_headers_iface_all h
                        WHERE h.orig_sys_document_ref = m.original_sys_document_ref
                          AND h.order_source_id = m.order_source_id
                          AND NVL(h.error_flag,'N') = 'Y'
                          AND m.MESSAGE_TEXT LIKE 'Validation failed for the field -Salesperson%'
                          AND h.orig_sys_document_ref  = l.orig_sys_document_ref
                      );
		
        UPDATE oe_headers_iface_all h
           SET error_flag  = NULL,
               request_id  = NULL,
               salesrep_id = ln_sales_rep
         WHERE NVL(h.error_flag,'N') = 'Y'
           AND EXISTS( SELECT 1
                         FROM oe_processing_msgs_vl m
                        WHERE h.orig_sys_document_ref = m.original_sys_document_ref
                          AND h.order_source_id = m.order_source_id
                          AND m.MESSAGE_TEXT LIKE 'Validation failed for the field -Salesperson%'
                     );
        				  
        fnd_file.put_line(fnd_file.output,
                          'Total No of orders updated for Validation failed for the field -Salesperson '
                          || SQL%ROWCOUNT);
        fnd_file.put_line(fnd_file.output,
                          'END OF update_default_salesrep');
        -- Commit the changes
        COMMIT;
    ELSE
        fnd_file.put_line(fnd_file.output,
                         'Unable to derive the Sales rep');   
    END IF;	
EXCEPTION
  WHEN OTHERS
  THEN
      fnd_file.put_line(fnd_file.LOG,
                        'WHEN OTHERS RAISED FOR update_default_salesrep : '
                        || SQLERRM);
      ROLLBACK;
END update_default_salesrep;

PROCEDURE reset_order_type_records   --Defect#43138         
IS
-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- |                  Office Depot                                             |
-- +===========================================================================+
-- | Name  : reset_order_type_records                                          |
-- | Description      : This Procedure will look for Orders stuck in Interface |
-- |                    with Validation failed for the field - Order Type      |
-- |                    this procedure will reset the request_id,error_flag    |
-- |                    to process the next run                                | 
-- |                                                                           |   
-- |                                                                           |
-- |                                                                           |
-- +===========================================================================+
BEGIN
fnd_file.put_line(fnd_file.output,
                                 'Begin reset_order_type_records');
    UPDATE oe_headers_iface_all h
       SET error_flag  = NULL,
           request_id  = NULL
     WHERE NVL(h.error_flag,'N') = 'Y'
       AND EXISTS( SELECT 1
                     FROM oe_processing_msgs_vl m
                    WHERE h.orig_sys_document_ref = m.original_sys_document_ref
                      AND h.order_source_id = m.order_source_id
                      AND m.MESSAGE_TEXT LIKE 'Validation failed for the field - Order Type%');
     
        fnd_file.put_line(fnd_file.output,
                          'Total No of orders updated for Validation failed for the field - Order Type '
                          || SQL%ROWCOUNT);
        fnd_file.put_line(fnd_file.output,
                          'END OF reset_order_type_records');
        -- Commit the changes
        COMMIT;
EXCEPTION
  WHEN OTHERS
  THEN
      fnd_file.put_line(fnd_file.LOG,
                        'WHEN OTHERS RAISED FOR reset_order_type_records : '
                        ||SQLERRM);
      ROLLBACK;
END reset_order_type_records;


PROCEDURE reset_account_type_error
IS
  -- +===========================================================================+
  -- |                  Office Depot - Project Simplify                          |
  -- |                  Office Depot                                             |
  -- +===========================================================================+
  -- | Name  : reset_account_type_error                                          |
  -- | Description      : This Procedure will look for Orders stuck in Interface |
  -- |                    with Validation failed for the field - Account Type    |
  -- |                    this procedure will reset the request_id,error_flag    |
  -- |                    to process the next run                                |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+
  l_request_id            NUMBER := 0 ;
  l_reponsibility_name    xx_fin_translatevalues.target_value2%TYPE;
  l_username              xx_fin_translatevalues.target_value1%TYPE;
  l_user_id               fnd_user.user_id%TYPE;
  l_responsibility_id     fnd_responsibility_tl.responsibility_id%TYPE;
  l_application_id        fnd_responsibility_tl.application_id%TYPE;
  l_organization_id       xx_fin_translatevalues.target_value4%TYPE;
BEGIN
  fnd_file.put_line(fnd_file.output, 'Begin procedure reset_account_type_error');
  UPDATE oe_headers_iface_all h
  SET error_flag              = NULL,
    request_id                = NULL
  WHERE NVL(h.error_flag,'N') = 'Y'
  AND EXISTS
    (SELECT 1
    FROM oe_processing_msgs_vl m
    WHERE h.orig_sys_document_ref = m.original_sys_document_ref
    AND h.order_source_id         = m.order_source_id
    AND m.MESSAGE_TEXT LIKE 'Validation failed for the field%Account%'
    );
  fnd_file.put_line(fnd_file.output, 'Total No of orders updated for Validation failed for the field - Account Type ' || SQL%ROWCOUNT);
  fnd_file.put_line(fnd_file.output, 'END OF reset_account_type_error');
  IF SQL%ROWCOUNT >0 THEN
    fnd_file.put_line(fnd_file.LOG,'Number of rows updated:' ||SQL%ROWCOUNT);
    SELECT xftv.target_value1,
      xftv.target_value2,
      xftv.target_value4
    INTO l_username,
      l_reponsibility_name,
      l_organization_id
    FROM xx_fin_translatevalues xftv,
      xx_fin_translatedefinition xftd
    WHERE xftv.translate_id   = xftd.translate_id
    AND xftd.translation_name = 'XX_HVOP_ERROR_REPROCESS'
    AND xftv.source_value1    = 'RESET_ACCOUNT_TYPE'
    AND SYSDATE BETWEEN xftv.start_date_active AND NVL (xftv.end_date_active, SYSDATE + 1)
    AND SYSDATE BETWEEN xftd.start_date_active AND NVL (xftd.end_date_active, SYSDATE + 1)
    AND xftv.enabled_flag = 'Y'
    AND xftd.enabled_flag = 'Y';
    fnd_file.put_line(fnd_file.LOG,'Username:'||l_username);
    fnd_file.put_line(fnd_file.LOG,'Responsibility'||l_reponsibility_name);
    SELECT frt.responsibility_id,
      fu.user_id,
      frt.application_id
    INTO l_responsibility_id,
      l_user_id,
      l_application_id
    FROM fnd_user fu,
      fnd_user_resp_groups_all furga,
      fnd_responsibility_tl frt
    WHERE frt.LANGUAGE        = USERENV('LANG')
    AND frt.responsibility_id = furga.responsibility_id
    AND furga.user_id         = fu.user_id
    AND fu.user_name          = l_username
    AND responsibility_name   = l_reponsibility_name
    AND (fu.start_date       <= SYSDATE
    OR fu.start_date         IS NULL)
    AND (fu.end_date         >= SYSDATE
    OR fu.end_date           IS NULL)
    AND (furga.start_date    <= SYSDATE
    OR furga.start_date      IS NULL)
    AND (furga.end_date      >= SYSDATE
    OR furga.end_date        IS NULL);
    fnd_file.put_line(fnd_file.LOG,'Userid:'||l_user_id);
    fnd_file.put_line(fnd_file.LOG, 'Responsibility_ID'||l_responsibility_id);
    fnd_file.put_line(fnd_file.LOG, 'Responsibility_Application_ID'||l_application_id);
    fnd_file.put_line(fnd_file.LOG, 'organization_ID'||l_organization_id);
    FND_GLOBAL.APPS_INITIALIZE( user_id => l_user_id -- User ID -- SVC-ESP_OM1..
    ,resp_id => l_responsibility_id                  -- OD (US) HVOP Super User
    ,resp_appl_id => l_application_id                -- Oracle Order Management
    --,l_org_id       => l_organization_id   -- 404
    );
  END IF;
  mo_global.init('ONT');
  MO_GLOBAL.SET_POLICY_CONTEXT('S', l_organization_id);
  l_request_id:=fnd_request.submit_request ( application =>'ONT' ,program => 'OEOIMP' ,argument1 => NULL -- Operating Unit
  ,argument2 => NULL                                                                                     -- Order Source
  ,argument3 => NULL                                                                                     -- Original System Document Ref
  ,argument4 => NULL                                                                                     -- Operation Code
  ,argument5 =>'N'                                                                                       -- Validate Only?
  ,argument6 => 1                                                                                        -- Debug Level
  ,argument7 => 4                                                                                        -- Number of Order Import instances
  ,argument8 => NULL                                                                                     -- Sold To Org Id
  ,argument9 => NULL                                                                                     -- Sold To Org
  ,argument10 => NULL                                                                                    -- Change Sequence
  ,argument11 => 'Y'                                                                                     -- Enable Single Line Queue for Instances
  ,argument12 => 'N'                                                                                     -- Trim Trailing Blanks
  ,argument13 => 'Y'                                                                                     -- Process Orders With No Org Specified
  ,argument14 => l_organization_id                                                                       -- Default Operating Unit
  ,argument15 => 'Y'                                                                                     -- Validate Description Flexfields?
  );
  fnd_file.put_line(fnd_file.LOG,'Submitted RequestID='||l_request_id);
  IF l_request_id>0 THEN
    COMMIT;
  ELSE
    ROLLBACK;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.LOG, 'WHEN OTHERS RAISED FOR reset_account_type_error : ' ||SQLERRM);
  ROLLBACK;
END reset_account_type_error;


    PROCEDURE process_errors(
        errbuf                  OUT NOCOPY  VARCHAR2,
        retcode                 OUT NOCOPY  NUMBER,
        p_ship_to_activate                  VARCHAR2,
        p_customer_activate                 VARCHAR2,
        p_item_validation                   VARCHAR2,
        p_item_assignment                   VARCHAR2,
        p_depo_cust_validation              VARCHAR2,
        p_customer_validation               VARCHAR2,
        p_process_c_stat_depo               VARCHAR2,
        p_wrong_location                    VARCHAR2,
        p_nhv_order                         VARCHAR2,
        p_offline_deposits                  VARCHAR2,
        p_unapply_apply                     VARCHAR2,
        p_default_salesrep                  VARCHAR2,
        p_order_type                        VARCHAR2,
		p_process_subscription_orders       VARCHAR2)
    IS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : PROCESS_ERRORS                                                  |
-- | Description      : This Procedure will submit above procedures to       |
-- |                    validate all above error types                       |
-- |                                                                         |
-- |                                                                         |
-- +=========================================================================+
        lc_ship_to_activate            VARCHAR2(20) := 'N';
        lc_customer_activate           VARCHAR2(20) := 'N';
        lc_item_validation             VARCHAR2(20) := 'N';
        lc_item_assignment             VARCHAR2(20) := 'N';
        lc_depo_cust_validation        VARCHAR2(20) := 'N';
        lc_customer_validation         VARCHAR2(20) := 'N';
        lc_process_c_stat_depo         VARCHAR2(20) := 'N';
        lc_wrong_location              VARCHAR2(20) := 'N';
        lc_nhv_order                   VARCHAR2(20) := 'N';
        lc_offline_deposits            VARCHAR2(20) := 'N';
        lc_unapply_apply               VARCHAR2(20) := 'N';
        lc_default_salesrep            VARCHAR2(20) := 'N';
        lc_order_type                  VARCHAR2(20) := 'N'; 
		lc_process_subscription_orders VARCHAR2(20)  := 'N';
    BEGIN
        lc_ship_to_activate            := p_ship_to_activate;
        lc_customer_activate           := p_customer_activate;
        lc_item_validation             := p_item_validation;
        lc_item_assignment             := p_item_assignment;
        lc_depo_cust_validation        := p_depo_cust_validation;
        lc_customer_validation         := p_customer_validation;
        lc_process_c_stat_depo         := p_process_c_stat_depo;
        lc_wrong_location              := p_wrong_location;
        lc_nhv_order                   := p_nhv_order;
        lc_offline_deposits            := p_offline_deposits;
        lc_unapply_apply               := p_unapply_apply;
        lc_default_salesrep            := p_default_salesrep;
        lc_order_type                  := p_order_type;
        lc_process_subscription_orders := p_process_subscription_orders;
		
        IF lc_ship_to_activate = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS SHIP_TO_ACTIVATE:::');
            ship_to_activate;
        END IF;

        IF lc_customer_activate = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS CUSTOMER_ACTIVATE:::');
            customer_activate;
        END IF;

        IF lc_item_validation = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS ITEM_VALIDATION:::');
            item_validation;
        END IF;

        IF lc_item_assignment = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS ITEM_ASSIGNMENT:::');
            item_assignment;
        END IF;

        IF lc_depo_cust_validation = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS DEPOSIT_CUSTOMER_VALIDATION:::');
            deposit_customer_validation;
        END IF;

        IF lc_customer_validation = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS CUSTOMER_VALIDATION:::');
            customer_validation;
        END IF;

        IF lc_process_c_stat_depo = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'PROCESS_C_STATUS_DEPOSITS:::');
            process_c_status_deposits;
        END IF;

        IF lc_wrong_location = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'LOCATION_IN_WRONG_OPU:::');
            location_in_wrong_opu;
        END IF;

        IF lc_nhv_order = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'NOT_HIGH_VOLUME_ORDER:::');
            not_high_volume_order;
        END IF;

        IF lc_offline_deposits = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'OFF_LINE_DEPOSITS:::');
            off_line_deposits;
        END IF;

        IF lc_unapply_apply = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'UNAPPLY_AND_APPLY_RCT:::');
            unapply_and_apply_rct;
        END IF;
        
        IF lc_default_salesrep = 'Y' 
        THEN
	    fnd_file.put_line(fnd_file.output,
                              'Update Default Sales Rep:::');
	    update_default_salesrep;				  
        END IF;
        
        IF lc_order_type  = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'Rest Order Type Records:::');
            reset_order_type_records;
        END IF;
		
		IF lc_process_subscription_orders = 'Y'
        THEN
            fnd_file.put_line(fnd_file.output,
                              'Reset Account type error:::');
            reset_account_type_error;
        END IF; 
		
		IF lc_process_subscription_orders = 'Y' 
		THEN
           fnd_file.put_line(fnd_file.output, 'Reset Account type error:::');
           reset_account_type_error;
        END IF;
  
    EXCEPTION
        WHEN OTHERS
        THEN
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS IN PROCESS_ERRORS :::'
                              || SQLERRM);
    End Process_Errors;
END xx_om_hvop_error_process;
/
exit;