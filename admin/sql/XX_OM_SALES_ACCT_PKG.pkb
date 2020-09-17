CREATE OR REPLACE PACKAGE BODY APPS.xx_om_sales_acct_pkg
AS
-- +==========================================================================================================+
-- |                  Office Depot - Project Simplify                                                         |
-- |                Office Depot                                                                              |
-- +==========================================================================================================|
-- | Name  : XX_OM_SALES_ACCT_PKG (XXOMWSACTB.pkb)                                                            |
-- | Rice ID: I1272                                                                                           |
-- | Description  : This package contains procedures related to the                                           |
-- | HVOP Sales Accounting Data processing. It includes pulling custom                                        |
-- | data from interface tables, processing Payments, Creating TAX                                            |
-- | records and pulling return tenders data from interface tables                                            |
-- |                                                                                                          |
-- |Change Record:                                                                                            |
-- |===============                                                                                           |
-- |Version    Date          Author            Remarks                                                        |
-- |=======    ==========    =============     ===============================================================|
-- |1.0        06-APR-2007   Manish Chavan     Initial version                                                |
-- |                                                                                                          |
-- |2.0        07-FEB-2011   Bapuji Nanapaneni Modified the code to                                           |
-- |                                           insert into xx_ar_order_                                       |
-- |                                           receipt_dtl table and stop                                     |
-- |                                           creation of AR Receipts for                                    |
-- |                                           SDR project Rel11.2                                            |
-- |3.0        11-JUN-2011   Bapuji N          Defect 12032                                                   |
-- |4.0        16-JUN-2011   Bapuji N          Defect 12139                                                   |
-- |5.0        28-JUL-2011   Bapuji N         11.4 rel added SR_number col                                    |
-- |6.0        27-JUL-2012   Bapuji N         Added SAVE EXCEPTION.                                           |
-- |7.0        09-AUG-2012   Bapuji N         Added CUST_PREF_EMAIL Defect                                    |
-- |                                           #19771                                                         |
-- |8.0        26-OCT-2012   Bapuji N         Added ATR Flag for service                                      |
-- |                                          ord validation                                                  |
-- |9.0        25-JAN-2013   Bapuji N         Added Device Serial Num                                         |
-- |10.0       10-APR-2013   Bapuji N         Added PAYPAL to set remit                                       |
-- |                                          flag to 'Y'QC DEFECT # 23070                                    |
-- |11.0       24-MAY-2013   Bapuji N         Amazon changes app_id                                           |
-- |12.0       12-JUL-2013   Bapuji N         Retrofit for 12i                                                |
-- |13.o      28-Aug-2013  Edson M          Added new encryption solution                                     |
-- | -------------  Retrofitting ---------------------------------------- ------------------------------------|
-- |14.0       24-AUG-2013   Raj J            MPS Toner Retail                                                |
-- |15.0       23-JAN-2014    Edson           Fixed per defect 27602                                          |
-- |16.0       04-Feb-2013  Edson M.         Changes for Defect 27883                                         |
-- |17.0       20-MAR-2014  Edson M.          Defect 29007                                                    |
-- |18.0       14-JUL-2014  Suresh Ponnambalam OMX Gift Card Consolidation                                    |
-- |19.0       02-JAN-2014  Avinash B          Changes for AMZ MPL                                            |
-- |20.0       17-MAR-2015  Saritha Mummaneni  Changes for Defect# 33817                                      |
-- |21.0       16-APR-2015  Arun Gannarapu     Made changes for Tonization project                            |
-- |                                           defect 34103                                                   |
-- |22.0       23-JUL-2015  Arun Gannarapu     Made changes to default N for                                  |
-- |                                           tokenization fields 35134                                      |
-- |23.0       08-Aug-2015  Arun Gannarapu     Made changes to fix defect 35383                               |
-- |24.0       25-SEP-2015  Arun Gannarapu     Made changes for Line level tax Defect 35944                   |
-- |25.0       12-DEC-2015  Rakesh Polepalli   Made changes for Defect 36125                                  |
-- |26.0       02-Feb-2016  Arun Gannarapu     Made changes for defect 37172                                  |
-- |27.0       03-MAR-2016  Arun Gannarapu     Made changes to fix defect 37178 -performance issue for 12c    |
-- |28.0       13-Jun-2016  Arun Gannarapu     Made changes for Kitting defect 37676                          |
-- |29.0       07-DEC-2016  Surendra Oruganti  Made changes to fix defect 38223 -Bad data in settlement file  |
-- |30.0       02-MAY-2018  Suresh Naragam     Made Changes for eBay Market Place(MPL)                        |
-- |31.0       08-JUN-2018  Vijay Machavarapu  Made changes to fix defect 44321 on remit flag for AMAZON_4S   |
-- |32.0       02-JUL-2018  Shalu George       Made changes for Walmart, Rakuten and NewEgg Market Place(MPL) | 
-- |33.0       07-JUL-2018  Suresh Naragam     Made Changes to check the payment methods from translations    |
-- |34.0       14-Nov-2018  Arun Gannarapu     Made changes for Bill Complete                                 |
-- |35.0       05-SEP-2019  Arun Gannarapu     Made changes to add return auth code for card on file          |
-- |36.0       07-MAY-2020  Shalu George       Added to get authorized amount for partially reversed orders   |
-- |37.0       10-SEP-2020  Shalu George       Added column item_description for Elynxx orders                |
-- +==========================================================================================================+
    g_pkg_name  CONSTANT VARCHAR2(30) := 'XX_OM_SALES_ACCT_PKG';

    FUNCTION get_rem_bank_acct_id(
        p_receipt_method_id  IN  NUMBER,
        p_curr_code          IN  VARCHAR2)
        RETURN NUMBER;

    PROCEDURE get_payment_data(
        p_header_id      IN      NUMBER,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE preprocess_payments(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE apply_hold(
        p_header_id      IN             NUMBER,
        p_hold_id        IN             NUMBER,
        p_msg_count      IN OUT NOCOPY  NUMBER,
        p_msg_data       IN OUT NOCOPY  VARCHAR2,
        x_return_status  OUT NOCOPY     VARCHAR2);

    PROCEDURE create_sales_credits(
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE get_custom_attributes(
        p_header_id      IN      NUMBER,
        p_mode           IN      VARCHAR2,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE create_tax_records(
        p_header_id      IN      NUMBER,
        p_mode           IN      VARCHAR2,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE get_return_tenders(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2);

    PROCEDURE update_line_attributes(
        p_header_id  IN  NUMBER,
        p_mode       IN  VARCHAR2,
        p_batch_id   IN  NUMBER);
		
	FUNCTION check_cc_code(
	         p_cc_code   IN  fnd_lookup_values.meaning%TYPE)
    RETURN BOOLEAN;
	
	FUNCTION check_return_cc_code(
	         p_cc_code   IN  fnd_lookup_values.meaning%TYPE)
    RETURN BOOLEAN;

    PROCEDURE set_msg_context(
        p_entity_code            IN  VARCHAR2,
        p_header_id              IN  VARCHAR2 DEFAULT NULL,
        p_orig_sys_document_ref  IN  VARCHAR2 DEFAULT NULL)
    IS
-- +====================================================================+
-- | Name  : set_msg_context                                            |
-- | Description      : This Procedure will set message context         |
-- |                    the messages will be inserted into oe_processing|
-- |                    _msgs                                           |
-- |                                                                    |
-- | Parameters:        p_entity_code IN entity i.e. HEADER,LINE ETC    |
-- |                    p_header_id   IN Header Id                      |
-- +====================================================================+
    BEGIN
        oe_msg_pub.set_msg_context(p_entity_code                     => p_entity_code,
                                   p_entity_ref                      => NULL,
                                   p_entity_id                       => NULL,
                                   p_header_id                       => p_header_id,
                                   p_line_id                         => NULL,
                                   p_order_source_id                 => NULL,
                                   p_orig_sys_document_ref           => p_orig_sys_document_ref,
                                   p_orig_sys_document_line_ref      => NULL,
                                   p_orig_sys_shipment_ref           => NULL,
                                   p_change_sequence                 => NULL,
                                   p_source_document_type_id         => NULL,
                                   p_source_document_id              => NULL,
                                   p_source_document_line_id         => NULL,
                                   p_attribute_code                  => NULL,
                                   p_constraint_id                   => NULL);
    END set_msg_context;

-- +===================================================================+
-- | Name  : PROCESS_BULK                                              |
-- | Description  : This Procedure will be used to process data in     |
-- |                BULK mode -> Orders being imported by HVOP         |
-- |                                                                   |
-- | Parameters :  p_header_id    IN  -> Current Order in the workflow |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE process_bulk(
        p_header_id  IN  NUMBER)
    IS
        ln_header_id             NUMBER;
        ln_batch_id              NUMBER;
        lc_return_status         VARCHAR2(30)                 := 'S';
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(100);
        lc_mode                  VARCHAR2(10);
        lc_tax_failure_flag      VARCHAR2(1);
        lc_kff_failure_flag      VARCHAR2(1);
        lc_scredit_failure_flag  VARCHAR2(1);
        lc_payment_failure_flag  VARCHAR2(1);
        ln_debug_level  CONSTANT NUMBER                       := oe_debug_pub.g_debug_level;
        lc_order_source          oe_order_sources.NAME%TYPE;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering Process Bulk :');
        END IF;

        -- Get the Batch_Id so that we process all records in a batch at a time.
        SELECT batch_id
        INTO   ln_batch_id
        FROM   oe_order_headers
        WHERE  header_id = p_header_id;

        oe_debug_pub.ADD(   'Batch_id is :'
                         || ln_batch_id);

        IF NOT g_hvop_payment_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_payment_processed(ln_batch_id) := NULL;
        END IF;

        IF NOT g_hvop_tax_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_tax_processed(ln_batch_id) := NULL;
        END IF;

        IF NOT g_hvop_scredit_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_scredit_processed(ln_batch_id) := NULL;
        END IF;

        IF NOT g_hvop_kff_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_kff_processed(ln_batch_id) := NULL;
        END IF;

        IF NOT g_hvop_rcp_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_rcp_processed(ln_batch_id) := NULL;
        END IF;

        IF NOT g_hvop_rcp_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_rcp_processed(ln_batch_id) := NULL;
        END IF;

        IF NOT g_hvop_ref_rec_processed.EXISTS(ln_batch_id)
        THEN
            g_hvop_ref_rec_processed(ln_batch_id) := NULL;
        END IF;

        IF     g_hvop_payment_processed(ln_batch_id) = 'Y'
           AND g_hvop_tax_processed(ln_batch_id) = 'Y'
           AND g_hvop_scredit_processed(ln_batch_id) = 'Y'
           AND g_hvop_kff_processed(ln_batch_id) = 'Y'
           AND g_hvop_rcp_processed(ln_batch_id) = 'Y'
           AND g_hvop_ref_rec_processed(ln_batch_id) = 'Y'
        THEN
            GOTO post_process;
        END IF;

        oe_debug_pub.ADD(   ' After Batch_id is :'
                         || ln_batch_id);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Create_Tax_Records '
                             || ln_batch_id);
        END IF;

        IF g_hvop_tax_processed(ln_batch_id) IS NULL
        THEN
            create_tax_records(p_header_id          => p_header_id,
                               p_mode               => 'HVOP',
                               p_batch_id           => ln_batch_id,
                               x_return_status      => lc_return_status);
            oe_debug_pub.ADD(' After Creating TAX Records :');

            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                oe_debug_pub.ADD(   'Failed to create Tax Records :'
                                 || ln_batch_id);
                g_hvop_tax_processed(ln_batch_id) := 'E';
            ELSE
                g_hvop_tax_processed(ln_batch_id) := 'Y';
            END IF;
        END IF;

        -- Put the order on hold if the processing failed.
        IF g_hvop_tax_processed(ln_batch_id) = 'E'
        THEN
            IF g_tax_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_tax_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Tax Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_tax_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Get_Custom_Attributes '
                             || ln_batch_id);
        END IF;

        IF g_hvop_kff_processed(ln_batch_id) IS NULL
        THEN
            get_custom_attributes(p_header_id          => p_header_id,
                                  p_mode               => 'HVOP',
                                  p_batch_id           => ln_batch_id,
                                  x_return_status      => lc_return_status);
            oe_debug_pub.ADD(   ' After Creating CUST DATA  :'
                             || ln_batch_id);

            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                oe_debug_pub.ADD(   'Failed to create CUST data :'
                                 || ln_batch_id);
                g_hvop_kff_processed(ln_batch_id) := 'E';
            ELSE
                g_hvop_kff_processed(ln_batch_id) := 'Y';
            END IF;
        END IF;

        -- Put the order on hold if the processing failed.
        IF g_hvop_kff_processed(ln_batch_id) = 'E'
        THEN
            IF g_kff_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_kff_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: KFF Data Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_kff_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Create_Sales_Credits '
                             || ln_batch_id);
        END IF;

        IF g_hvop_scredit_processed(ln_batch_id) IS NULL
        THEN
            create_sales_credits(p_batch_id           => ln_batch_id,
                                 x_return_status      => lc_return_status);
            oe_debug_pub.ADD(   ' After Sales Credit  :'
                             || ln_batch_id);

            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                oe_debug_pub.ADD(   'Failed to create Sales Credits '
                                 || ln_batch_id);
                g_hvop_scredit_processed(ln_batch_id) := 'E';
            ELSE
                g_hvop_scredit_processed(ln_batch_id) := 'Y';
            END IF;
        END IF;

        -- Put the order on hold if the processing failed.
        IF g_hvop_scredit_processed(ln_batch_id) = 'E'
        THEN
            IF g_scredit_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_scredit_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Sales Credit Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_scredit_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Update_Line_Attributes '
                             || ln_batch_id);
        END IF;

        -- Update attributes on all lines of the batch
        update_line_attributes(p_header_id      => p_header_id,
                               p_mode           => 'HVOP',
                               p_batch_id       => ln_batch_id);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Process_PAyment '
                             || ln_batch_id);
        END IF;

        -- Process Payments for all orders in the batch
        IF g_hvop_payment_processed(ln_batch_id) IS NULL
        THEN
            lc_return_status := fnd_api.g_ret_sts_success;
            get_payment_data(p_header_id          => ln_header_id,
                             p_batch_id           => ln_batch_id,
                             x_return_status      => lc_return_status);
            oe_debug_pub.ADD(   ' After Creating Payments  :'
                             || ln_batch_id);

            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                oe_debug_pub.ADD(   'Failed to Get Payment Data '
                                 || ln_batch_id);
                g_hvop_payment_processed(ln_batch_id) := 'E';
            ELSE
                g_hvop_payment_processed(ln_batch_id) := 'Y';
            END IF;
        END IF;

        -- Put the order on hold if the processing failed.
        IF g_hvop_payment_processed(ln_batch_id) = 'E' AND lc_return_status <> fnd_api.g_ret_sts_success
        THEN
            IF g_payment_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_payment_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Payment Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_payment_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        IF g_hvop_rcp_processed(ln_batch_id) IS NULL
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Calling receipt_detail procedure :::');
            insert_into_recpt_tbl(p_header_id          => p_header_id,
                                  p_batch_id           => ln_batch_id,
                                  p_mode               => 'HVOP',
                                  x_return_status      => lc_return_status);

            -- Need to added hold if unable to insert record into xx_ar_order_receipt_dtl table.
            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                     'Failed to load data to xx_ar_receipt tbl '
                                  || ln_batch_id);
                oe_debug_pub.ADD(   'Failed to load data to xx_ar_receipt tbl '
                                 || ln_batch_id);
                g_hvop_rcp_processed(ln_batch_id) := 'E';
            ELSE
                g_hvop_rcp_processed(ln_batch_id) := 'Y';
            END IF;

            IF g_hvop_rcp_processed(ln_batch_id) = 'E'
            THEN
                IF g_ord_rec_hold IS NULL
                THEN
                    SELECT hold_id
                    INTO   g_ord_rec_hold
                    FROM   oe_hold_definitions
                    WHERE  NAME = 'OD: Receipt Processing Failure';
                END IF;

                apply_hold(p_header_id          => p_header_id,
                           p_hold_id            => g_ord_rec_hold,
                           p_msg_count          => ln_msg_count,
                           p_msg_data           => lc_msg_data,
                           x_return_status      => lc_return_status);
            END IF;

            oe_debug_pub.ADD(   ' After Creating Order receipt DATA  :'
                             || ln_batch_id);
            fnd_file.put_line(fnd_file.LOG,
                                 'Calling settlement api in HVOP mode :::'
                              || ln_batch_id);
            load_to_settlement(p_header_id          => p_header_id,
                               p_mode               => 'HVOP',
                               p_batch_id           => ln_batch_id,
                               x_return_status      => lc_return_status);
            fnd_file.put_line(fnd_file.LOG,
                                 'Calling inventory_misc_issue procedure in HVOP mode :::'
                              || ln_batch_id);
            inventory_misc_issue(p_header_id          => p_header_id,
                                 p_mode               => 'HVOP',
                                 p_batch_id           => ln_batch_id,
                                 x_return_status      => lc_return_status);
        END IF;

        <<post_process>>
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'At the end of PROCESS_BULK '
                             || ln_batch_id);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Failed In Process_Bulk - In Others :'
                             || ln_batch_id);

            -- Put the order on Generic hold
            IF g_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: SA Processing Failure';
            END IF;

            ln_msg_count := 1;
            lc_msg_data := 'Generic Processing Failure in XX_OM_SALES_ACCT_PKG.Process_Bulk';
            apply_hold(p_header_id          => ln_header_id,
                       p_hold_id            => g_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
    END process_bulk;

-- +===================================================================+
-- | Name  : PROCESS_NORMAL                                            |
-- | Description  : This Procedure will be used to process data in     |
-- |                SOI mode -> Orders being imported by SOI           |
-- |                                                                   |
-- | Parameters :  p_header_id    IN  -> Current Order in the workflow |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
    PROCEDURE process_normal(
        p_header_id  IN  NUMBER)
    IS
        ln_header_id             NUMBER;
        ln_batch_id              NUMBER;
        lc_return_status         VARCHAR2(30)   := 'S';
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(2000);
        lc_mode                  VARCHAR2(10);
        lc_tax_failure_flag      VARCHAR2(1);
        lc_kff_failure_flag      VARCHAR2(1);
        lc_scredit_failure_flag  VARCHAR2(1);
        lc_payment_failure_flag  VARCHAR2(1);
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        lc_order_source          VARCHAR2(50);
    BEGIN
        -- Set the message Context
        set_msg_context(p_entity_code      => 'HEADER',
                        p_header_id        => p_header_id);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Create TAX Records :'
                             || p_header_id);
        END IF;

        -- Need to happen for all Sales Accounting orders
        create_tax_records(p_header_id          => p_header_id,
                           p_mode               => 'NORMAL',
                           p_batch_id           => NULL,
                           x_return_status      => lc_return_status);

        IF lc_return_status <> fnd_api.g_ret_sts_success
        THEN
            oe_debug_pub.ADD(   'Failed to create Tax Records :'
                             || ln_header_id);
            lc_tax_failure_flag := 'Y';

            IF g_tax_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_tax_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Tax Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_tax_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        -- Need to happen for all Sales Accounting orders
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Get_Custom_Attributes :'
                             || p_header_id);
        END IF;

        get_custom_attributes(p_header_id          => p_header_id,
                              p_mode               => 'NORMAL',
                              p_batch_id           => NULL,
                              x_return_status      => lc_return_status);

        IF lc_return_status <> fnd_api.g_ret_sts_success
        THEN
            oe_debug_pub.ADD(   'Failed to create DFF/KFF data :'
                             || ln_header_id);

            IF g_kff_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_kff_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: KFF Data Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_kff_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        -- Need to get Return Tender Info from iface tables
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Get_Return_Tenders :'
                             || p_header_id);
        END IF;

        get_return_tenders(p_header_id          => p_header_id,
                           x_return_status      => lc_return_status);

        IF lc_return_status <> fnd_api.g_ret_sts_success
        THEN
            oe_debug_pub.ADD(   'Failed to create return tender data :'
                             || ln_header_id);

            IF g_ret_tenders_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_ret_tenders_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Return Tender Data Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_ret_tenders_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Update_Line_Attributes :'
                             || p_header_id);
        END IF;

        -- Update the Line attributes on all lines of the order
        update_line_attributes(p_header_id      => p_header_id,
                               p_mode           => 'NORMAL',
                               p_batch_id       => NULL);

        -- We will create the prepayment receipt in this API so that out of box receipt creation is
        -- not used.
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Preprocess_Payment :'
                             || p_header_id);
        END IF;

        preprocess_payments(p_header_id          => p_header_id,
                            x_return_status      => lc_return_status);

        IF lc_return_status <> fnd_api.g_ret_sts_success
        THEN
            oe_debug_pub.ADD(   'Failed in Preprocess_payments :'
                             || ln_header_id);

            IF g_payment_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_payment_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Payment Processing Failure';
            END IF;

            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_payment_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
        END IF;

        IF p_header_id IS NOT NULL
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'Calling receipt_detail procedure :::');
            insert_into_recpt_tbl(p_header_id          => p_header_id,
                                  p_batch_id           => NULL,
                                  p_mode               => 'NORMAL',
                                  x_return_status      => lc_return_status);
            fnd_file.put_line(fnd_file.LOG,
                                 'lc_return_status :::'
                              || lc_return_status);

            -- Need to added hold if unable to insert record into xx_ar_order_receipt_dtl table.
            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                oe_debug_pub.ADD(   'Failed in insert_into_recpt_tbl :'
                                 || p_header_id);

                SELECT hold_id
                INTO   g_ord_rec_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: Receipt Processing Failure';

                apply_hold(p_header_id          => p_header_id,
                           p_hold_id            => g_ord_rec_hold,
                           p_msg_count          => ln_msg_count,
                           p_msg_data           => lc_msg_data,
                           x_return_status      => lc_return_status);
            ELSE
                oe_debug_pub.ADD(   'Calling load_to_settlement Proc in normal mode:'
                                 || p_header_id);
                load_to_settlement(p_header_id          => p_header_id,
                                   p_mode               => 'NORMAL',
                                   p_batch_id           => NULL,
                                   x_return_status      => lc_return_status);
            END IF;

            lc_order_source := get_order_source(p_header_id);

            IF lc_order_source = 'POE'
            THEN
                fnd_file.put_line(fnd_file.LOG,
                                  'Calling Refund receipt_detail procedure :::');
                insert_ret_into_recpt_tbl(p_header_id          => p_header_id,
                                          x_return_status      => lc_return_status);
                fnd_file.put_line(fnd_file.LOG,
                                     'lc_return_status :::'
                                  || lc_return_status);

                -- Need to added hold if unable to insert record into xx_ar_order_receipt_dtl table.
                IF lc_return_status <> fnd_api.g_ret_sts_success
                THEN
                    oe_debug_pub.ADD(   'Failed in insert_ret_into_recpt_tbl :'
                                     || p_header_id);

                    SELECT hold_id
                    INTO   g_ord_ref_rec_hold
                    FROM   oe_hold_definitions
                    WHERE  NAME = 'OD: Receipt Processing Failure';

                    apply_hold(p_header_id          => p_header_id,
                               p_hold_id            => g_ord_ref_rec_hold,
                               p_msg_count          => ln_msg_count,
                               p_msg_data           => lc_msg_data,
                               x_return_status      => lc_return_status);
                ELSE
                    oe_debug_pub.ADD(   'Calling load_to_settlement Proc in normal mode:'
                                     || p_header_id);
                    load_to_settlement(p_header_id          => p_header_id,
                                       p_mode               => 'NORMAL',
                                       p_batch_id           => NULL,
                                       x_return_status      => lc_return_status);
                END IF;
            END IF;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXCalling Inventory Misc Issue in Normal mode for :'
                             || p_header_id);
        END IF;

        inventory_misc_issue(p_header_id          => p_header_id,
                             p_mode               => 'NORMAL',
                             p_batch_id           => NULL,
                             x_return_status      => lc_return_status);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'At the end of PROCESS_NORMAL :'
                             || p_header_id);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD(   'Failed In Process_Normal - In Others :'
                             || ln_batch_id);

            -- Put the order on Generic hold
            IF g_processing_hold IS NULL
            THEN
                SELECT hold_id
                INTO   g_processing_hold
                FROM   oe_hold_definitions
                WHERE  NAME = 'OD: SA Processing Failure';
            END IF;

            ln_msg_count := 1;
            lc_msg_data := 'Generic Processing Failure in XX_OM_SALES_ACCT_PKG.Process_Normal';
            apply_hold(p_header_id          => p_header_id,
                       p_hold_id            => g_processing_hold,
                       p_msg_count          => ln_msg_count,
                       p_msg_data           => lc_msg_data,
                       x_return_status      => lc_return_status);
    END process_normal;

-- +=====================================================================+
-- | Name  : PULL_DATA                                                   |
-- | Description  : This Procedure will be called by the custom workflow |
-- | activity that will be invoked for each order header.                |
-- |                                                                     |
-- | Parameters :  itemtype  IN  -> 'OEOH'                               |
-- |               itemtype  IN  -> header_id                            |
-- |               actid     IN  -> activity id                          |
-- |               funcmode  IN  -> workflow running mode                |
-- |               resultout OUT -> Activity Result                      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE pull_data(
        itemtype   IN      VARCHAR2,
        itemkey    IN      VARCHAR2,
        actid      IN      NUMBER,
        funcmode   IN      VARCHAR2,
        resultout  IN OUT  VARCHAR2)
    IS
        ln_header_id             NUMBER;
        ln_batch_id              NUMBER;
        lc_return_status         VARCHAR2(30)   := 'S';
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(2000);
        lc_tax_failure_flag      VARCHAR2(1);
        lc_kff_failure_flag      VARCHAR2(1);
        lc_scredit_failure_flag  VARCHAR2(1);
        lc_payment_failure_flag  VARCHAR2(1);
        ln_payment               NUMBER;
        ln_refund                NUMBER;
        lc_order_source          VARCHAR2(30);
        ln_order_receipt_id      NUMBER;
        lc_pay_type              VARCHAR2(30);
    BEGIN
        --
        -- RUN mode - normal process execution
        --
        IF (funcmode = 'RUN')
        THEN
            oe_standard_wf.set_msg_context(actid);
            ln_header_id := TO_NUMBER(itemkey);

            IF oe_bulk_wf_util.g_header_index IS NOT NULL
            THEN
                --IF XX_OM_SACCT_CONC_PKG.G_MODE = 'SAS_IMPORT' THEN
                oe_debug_pub.ADD('Calling Process Bulk');
                process_bulk(p_header_id      => ln_header_id);
            ELSE
                oe_debug_pub.ADD('Calling Process Normal');
                process_normal(p_header_id      => ln_header_id);
            END IF;

            resultout := 'COMPLETE';
            oe_standard_wf.clear_msg_context;
        END IF;                                                                                    -- End for 'RUN' mode

        --
        -- CANCEL mode - activity 'compensation'
        --
        -- This is an event point is called with the effect of the activity must
        -- be undone, for example when a process is reset to an earlier point
        -- due to a loop back.
        --
        IF (funcmode = 'CANCEL')
        THEN
            -- your cancel code goes here
            NULL;
            -- no result needed
            resultout := 'COMPLETE';
            RETURN;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            -- The line below records this function call in the error system
            -- in the case of an exception.
            wf_core.CONTEXT('XX_OM_SALES_ACCT_PKG',
                            'Pull_Data',
                            itemtype,
                            itemkey,
                            TO_CHAR(actid),
                            funcmode);
            -- start data fix project
            oe_standard_wf.add_error_activity_msg(p_actid         => actid,
                                                  p_itemtype      => itemtype,
                                                  p_itemkey       => itemkey);
            oe_standard_wf.save_messages;
            oe_standard_wf.clear_msg_context;
            -- end data fix project
            RAISE;
    END pull_data;

-- +=====================================================================+
-- | Name  : Get_Payment_Data                                            |
-- | Description  : This Procedure will look at interface data and will  |
-- | creat PAYMENT records in oe_payments table. This will be called only|
-- | in HVOP mode where payment import is not supported                  |
-- |                                                                     |
-- | Parameters :  p_header_id  IN  -> header_id of the current order    |
-- |               p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE get_payment_data(
        p_header_id      IN      NUMBER,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        ln_request_id            NUMBER;

        CURSOR c_payments
        IS
            SELECT   h.header_id,
                     i.payment_type_code,
                     i.credit_card_code,
                     i.credit_card_number,
                     i.attribute4 credit_card_num_enc,
                     i.attribute5 IDENTIFIER,
                     i.credit_card_holder_name,
                     i.credit_card_expiration_date,
                     i.credit_card_approval_code,
                     i.credit_card_approval_date,
                     i.check_number,
                     i.prepaid_amount,
                     i.payment_amount,
                     i.orig_sys_payment_ref,
                     i.payment_number,
                     i.receipt_method_id,
                     h.transactional_curr_code,
                     h.sold_to_org_id,
                     h.invoice_to_org_id,
                     i.payment_set_id,
                     h.order_number,
                     i.CONTEXT,
                     i.attribute6,
                     i.attribute7,
                     i.attribute8,
                     i.attribute9,
                     i.attribute10,
                     i.attribute11,
                     i.attribute12,
                     i.attribute13,
                     NULL,
                     i.attribute15,
                     h.ship_from_org_id,
                     ha.paid_at_store_id,
                     h.orig_sys_document_ref,
                     (SELECT actual_shipment_date
                      FROM   oe_order_lines_all b
                      WHERE  h.header_id = b.header_id AND ROWNUM = 1),
                     i.payment_number,
                     i.trxn_extension_id,
                     i.attribute3,
                     i.attribute14,
                     i.attribute2,
                     i.attribute1
            FROM     oe_payments_interface i,
                     oe_order_headers h,
                     oe_payment_types_vl pt,
                     xx_om_header_attributes_all ha
            WHERE    h.batch_id = p_batch_id
            AND         h.orig_sys_document_ref
                     || '-BYPASS' = i.orig_sys_document_ref
            AND      h.order_source_id = i.order_source_id
            AND      i.payment_type_code = pt.payment_type_code
            AND      h.header_id = ha.header_id
            ORDER BY h.header_id,
                     i.payment_number;

        lc_payment_rec           xx_om_sacct_conc_pkg.payment_rec_type;
        ln_debug_level  CONSTANT NUMBER                                := oe_debug_pub.g_debug_level;
        lc_return_status         VARCHAR2(1);
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(2000);
        j                        BINARY_INTEGER;
    BEGIN
        x_return_status := fnd_api.g_ret_sts_success;
        ln_request_id := oe_bulk_order_pvt.g_request_id;

        OPEN c_payments;

        FETCH c_payments
        BULK COLLECT INTO lc_payment_rec.header_id,
               lc_payment_rec.payment_type_code,
               lc_payment_rec.credit_card_code,
               lc_payment_rec.credit_card_number,
               lc_payment_rec.credit_card_number_enc,
               lc_payment_rec.IDENTIFIER,
               lc_payment_rec.credit_card_holder_name,
               lc_payment_rec.credit_card_expiration_date,
               lc_payment_rec.credit_card_approval_code,
               lc_payment_rec.credit_card_approval_date,
               lc_payment_rec.check_number,
               lc_payment_rec.prepaid_amount,
               lc_payment_rec.payment_amount,
               lc_payment_rec.orig_sys_payment_ref,
               lc_payment_rec.payment_number,
               lc_payment_rec.receipt_method_id,
               lc_payment_rec.order_curr_code,
               lc_payment_rec.sold_to_org_id,
               lc_payment_rec.invoice_to_org_id,
               lc_payment_rec.payment_set_id,
               lc_payment_rec.order_number,
               lc_payment_rec.CONTEXT,
               lc_payment_rec.attribute6,
               lc_payment_rec.attribute7,
               lc_payment_rec.attribute8,
               lc_payment_rec.attribute9,
               lc_payment_rec.attribute10,
               lc_payment_rec.attribute11,
               lc_payment_rec.attribute12,
               lc_payment_rec.attribute13,
               lc_payment_rec.tangible_id,
               lc_payment_rec.attribute15,
               lc_payment_rec.ship_from_org_id,
               lc_payment_rec.paid_at_store_id,
               lc_payment_rec.orig_sys_document_ref,
               lc_payment_rec.receipt_date,
               lc_payment_rec.payment_number,
               lc_payment_rec.trxn_extension_id,
               lc_payment_rec.attribute3,
               lc_payment_rec.attribute14,
               lc_payment_rec.attribute2,
               lc_payment_rec.attribute1;

        CLOSE c_payments;

        IF lc_payment_rec.header_id.COUNT = 0
        THEN
            -- No records created for Account Billing
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'No Payment records found :'
                                 || p_batch_id);
            END IF;

            RETURN;
        END IF;

        create_receipt_payment(p_payment_rec        => lc_payment_rec,
                               p_request_id         => ln_request_id,
                               p_run_mode           => 'HVOP',
                               x_return_status      => lc_return_status);
        x_return_status := lc_return_status;
    EXCEPTION
        WHEN OTHERS
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('OTHERS ERROR , Get_Payment_Data');
                oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                        1,
                                        240));
            END IF;

            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_msg_pub.add_exc_msg(g_pkg_name,
                                   'Get_Payment_Data',
                                   SUBSTR(SQLERRM,
                                          1,
                                          240));
    END get_payment_data;

-- +=====================================================================+
-- | Name  : Create_Receipt_payment                                      |
-- | Description  : This Procedure will creat PAYMENT records in         |
-- | oe_payments table. It will also create receipt against it           |
-- | in HVOP mode where payment import is not supported                  |
-- |                                                                     |
-- | Parameters :  p_payment_rec  IN OUT NOCOPY -> Payment Records       |
-- |               p_request_id   IN  -> request_id of the run           |
-- |               p_run_mode     IN  -> 'HVOP' or 'SOI'                 |
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE create_receipt_payment(
        p_payment_rec    IN OUT NOCOPY  xx_om_sacct_conc_pkg.payment_rec_type,
        p_request_id     IN             NUMBER,
        p_run_mode       IN             VARCHAR2,
        x_return_status  OUT            VARCHAR2)
    IS
        ln_debug_level        CONSTANT NUMBER                                             := oe_debug_pub.g_debug_level;
        lc_return_status               VARCHAR2(1);
        ln_msg_count                   NUMBER;
        lc_msg_data                    VARCHAR2(2000);
        ln_cr_id                       NUMBER;
        ln_rec_appl_id                 NUMBER;
        ln_remittance_bank_account_id  NUMBER;
        ln_payment_server_order_num    NUMBER;
        ln_sec_application_ref_id      NUMBER;
        lc_pay_response_error_code     VARCHAR2(80);
        j                              BINARY_INTEGER;
        k                              BINARY_INTEGER;
        l_error_headers                err_tbl_type;
        l_success_header               t_num;
        lc_msg_text                    VARCHAR2(10000);
        ln_hold_id                     NUMBER;
        ln_app_ref_id                  NUMBER;
        lc_approval_code               VARCHAR2(120);
        lc_app_ref_num                 VARCHAR2(80);
        ln_receipt_number              ar_cash_receipts.receipt_number%TYPE;
        ln_cash_receipt_id             ar_cash_receipts.cash_receipt_id%TYPE;
        lc_print_debug                 VARCHAR2(1)                                          := fnd_api.g_false;
        l_attribute_rec                ar_receipt_api_pub.attribute_rec_type;
        ln_curr_pay_set_id             NUMBER;
        ln_trxn_extension_id           NUMBER;
        lc_receipt_comments            ar_cash_receipts.comments%TYPE;
        lc_customer_receipt_reference  ar_cash_receipts.customer_receipt_reference%TYPE;
        lc_app_customer_reference      ar_receivable_applications.customer_reference%TYPE;
        lc_app_comments                ar_receivable_applications.comments%TYPE;
        l_app_attribute_rec            ar_receipt_api_pub.attribute_rec_type;
        l_auth_attr_rec                xx_ar_cash_receipts_ext%ROWTYPE;
        lc_invoicing_on                VARCHAR2(1)                     := oe_sys_parameters.VALUE('XX_OM_INVOICING_ON');
        ln_start_time                  NUMBER                                               := 0;
        ln_end_time                    NUMBER                                               := 0;
        l_date                         VARCHAR2(50);
        lc_order_source                oe_order_sources.NAME%TYPE;
        ln_payerrors                   NUMBER;
    BEGIN
        x_return_status := fnd_api.g_ret_sts_success;

        -- For each of the payment record fetched we will need to create
        -- pre-payment receipt in AR.
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Entering Create_Receipt_payment ');
            oe_debug_pub.ADD(   'No of Payment record :'
                             || p_payment_rec.header_id.COUNT);
            lc_print_debug := 'T';
        END IF;

        j := 0;

        FOR i IN 1 .. p_payment_rec.header_id.COUNT
        LOOP
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Before calling AR Create_Prepayment: '
                                 || p_payment_rec.header_id(i),
                                 3);
            END IF;

            lc_return_status := fnd_api.g_ret_sts_success;

            -- Set the Error Global
            IF NOT l_error_headers.EXISTS(p_payment_rec.header_id(i))
            THEN
                l_error_headers(p_payment_rec.header_id(i)) := 'S';
            END IF;

            --Modifed by NB for  for R11.2 to stop creation of receipts for all POE orders
            IF p_payment_rec.header_id(i) IS NOT NULL
            THEN
                lc_order_source := get_order_source(p_payment_rec.header_id(i));

                IF lc_order_source = 'POE'
                THEN
                    GOTO skip_receipt;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD('POS Order No need to create Receipt.');
                    END IF;
                END IF;
            END IF;

            -- Check if the Payment record is a Deposit record. Or the invoicing is OFF then no need to create a receipt
            IF    p_payment_rec.payment_set_id(i) IS NOT NULL
               OR lc_invoicing_on <> 'Y'
               OR NVL(l_error_headers(p_payment_rec.header_id(i)),
                      'Y') = 'E'
            THEN
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'No need to create receipt as paid by deposit :'
                                     || p_payment_rec.header_id(i));
                END IF;

                GOTO skip_receipt;
            END IF;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'The Error global is set to :'
                                 || l_error_headers(p_payment_rec.header_id(i)));
                oe_debug_pub.ADD(   'Current Header ID :'
                                 || p_payment_rec.header_id(i));
                oe_debug_pub.ADD(   'old Header ID :'
                                 || ln_app_ref_id);
                oe_debug_pub.ADD(   'Current Payment Set ID :'
                                 || p_payment_rec.payment_set_id(i));
                oe_debug_pub.ADD(   'old Payment Set ID :'
                                 || ln_curr_pay_set_id);
            END IF;

            --set savepoint
            IF ln_app_ref_id <> p_payment_rec.header_id(i) OR ln_app_ref_id IS NULL
            THEN
                SAVEPOINT save_header;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Savepoint Set is set for header_id: '
                                     || p_payment_rec.header_id(i));
                END IF;
            END IF;

            -- If calling for multiple payments for a single order, make sure that the payment_set_id is
            -- same for all payment records of that order.
            IF ln_app_ref_id IS NOT NULL AND ln_app_ref_id = p_payment_rec.header_id(i)
               AND ln_curr_pay_set_id IS NOT NULL
            THEN
                p_payment_rec.payment_set_id(i) := ln_curr_pay_set_id;
            END IF;

            ln_msg_count := NULL;
            lc_msg_data := NULL;
            ln_app_ref_id := p_payment_rec.header_id(i);
            lc_app_ref_num := p_payment_rec.order_number(i);
            ln_receipt_number := NULL;
            lc_receipt_comments := NULL;
            lc_customer_receipt_reference := NULL;
            l_attribute_rec := NULL;
            lc_app_customer_reference := NULL;
            lc_app_comments := NULL;
            l_app_attribute_rec := NULL;

            SELECT hsecs
            INTO   ln_start_time
            FROM   v$timer;

            BEGIN
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'p_payment_rec.header_id :'
                                     || p_payment_rec.header_id(i));
                    oe_debug_pub.ADD(   'Approval Code :'
                                     || p_payment_rec.credit_card_approval_code(i));
                    oe_debug_pub.ADD(   'Order Number  :'
                                     || p_payment_rec.order_number(i));
                    oe_debug_pub.ADD(   'Payment Amount  :'
                                     || p_payment_rec.payment_amount(i));
                    oe_debug_pub.ADD(   'Receipt Method  :'
                                     || p_payment_rec.receipt_method_id(i));
                    oe_debug_pub.ADD(   'Sold To  :'
                                     || p_payment_rec.sold_to_org_id(i));
                    oe_debug_pub.ADD(   'Bill To  :'
                                     || p_payment_rec.invoice_to_org_id(i));
                    oe_debug_pub.ADD(   'Currency  :'
                                     || p_payment_rec.order_curr_code(i));
                    oe_debug_pub.ADD(   'Debit Card Approval Ref  :'
                                     || p_payment_rec.attribute12(i));
                    oe_debug_pub.ADD('Calling Set Receipt Attributes  ');

                    SELECT TO_CHAR(SYSDATE,
                                   'DD-MON-YYYY HH24:MI:SS')
                    INTO   l_date
                    FROM   DUAL;

                    oe_debug_pub.ADD(   'Time before calling receipt api :'
                                     || l_date);
                END IF;

                xx_ar_prepayments_pkg.set_receipt_attr_references
                                                      (p_receipt_context                 => 'SALES_ACCT',
                                                       p_orig_sys_document_ref           => p_payment_rec.orig_sys_document_ref
                                                                                                                      (i),
                                                       p_receipt_method_id               => p_payment_rec.receipt_method_id
                                                                                                                      (i),
                                                       p_payment_type_code               => p_payment_rec.payment_type_code
                                                                                                                      (i),
                                                       p_check_number                    => p_payment_rec.check_number
                                                                                                                      (i),
                                                       p_paid_at_store_id                => p_payment_rec.paid_at_store_id
                                                                                                                      (i),
                                                       p_ship_from_org_id                => p_payment_rec.ship_from_org_id
                                                                                                                      (i),
                                                       p_cc_auth_manual                  => p_payment_rec.attribute6(i),
                                                       p_cc_auth_ps2000                  => p_payment_rec.attribute8(i),
                                                       p_merchant_number                 => p_payment_rec.attribute7(i),
                                                       p_od_payment_type                 => p_payment_rec.attribute11(i),
                                                       p_debit_card_approval_ref         => p_payment_rec.attribute12(i),
                                                       p_cc_mask_number                  => p_payment_rec.attribute10(i),
                                                       p_payment_amount                  => p_payment_rec.payment_amount
                                                                                                                      (i),
                                                       p_called_from                     => 'HVOP',
                                                       p_print_debug                     => lc_print_debug,
                                                       p_additional_auth_codes           => p_payment_rec.attribute13(i),
                                                       x_receipt_number                  => ln_receipt_number,
                                                       x_receipt_comments                => lc_receipt_comments,
                                                       x_customer_receipt_reference      => lc_customer_receipt_reference,
                                                       x_attribute_rec                   => l_attribute_rec,
                                                       x_app_customer_reference          => lc_app_customer_reference,
                                                       x_app_comments                    => lc_app_comments,
                                                       x_app_attribute_rec               => l_app_attribute_rec,
                                                       x_receipt_ext_attributes          => l_auth_attr_rec);

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(' After Calling Set Receipt Attributes  ');
                END IF;

                xx_ar_prepayments_pkg.create_prepayment(p_api_version                       => 1.0,
                                                        p_init_msg_list                     => fnd_api.g_false,
                                                        p_commit                            => fnd_api.g_false,
                                                        p_validation_level                  => fnd_api.g_valid_level_full,
                                                        x_return_status                     => lc_return_status,
                                                        x_msg_count                         => ln_msg_count,
                                                        x_msg_data                          => lc_msg_data,
                                                        p_print_debug                       => lc_print_debug,
                                                        p_receipt_method_id                 => p_payment_rec.receipt_method_id
                                                                                                                      (i),
                                                        p_payment_type_code                 => NULL,
                                                        p_currency_code                     => p_payment_rec.order_curr_code
                                                                                                                      (i),
                                                        p_amount                            => p_payment_rec.payment_amount
                                                                                                                      (i),
                                                        p_payment_number                    => p_payment_rec.payment_number
                                                                                                                      (i),
                                                        p_sas_sale_date                     => p_payment_rec.receipt_date
                                                                                                                      (i),
                                                        p_receipt_date                      => NULL,
                                                        p_gl_date                           => NULL,
                                                        p_customer_id                       => p_payment_rec.sold_to_org_id
                                                                                                                      (i),
                                                        p_customer_site_use_id              => p_payment_rec.invoice_to_org_id
                                                                                                                      (i),
                                                        p_customer_receipt_reference        => lc_customer_receipt_reference,
                                                        p_remittance_bank_account_id        => NULL,
                                                        p_called_from                       => 'HVOP',
                                                        p_attribute_rec                     => l_attribute_rec,
                                                        p_receipt_comments                  => lc_receipt_comments,
                                                        p_application_ref_type              => 'OM',
                                                        p_application_ref_id                => ln_app_ref_id,
                                                        p_application_ref_num               => lc_app_ref_num,
                                                        p_secondary_application_ref_id      => ln_sec_application_ref_id,
                                                        p_apply_date                        => NULL,
                                                        p_apply_gl_date                     => NULL,
                                                        p_amount_applied                    => NULL,
                                                        p_app_attribute_rec                 => l_app_attribute_rec,
                                                        p_app_comments                      => lc_app_comments,
                                                        x_payment_set_id                    => p_payment_rec.payment_set_id
                                                                                                                      (i),
                                                        x_cash_receipt_id                   => ln_cr_id,
                                                        x_receipt_number                    => ln_receipt_number,
                                                        p_receipt_ext_attributes            => l_auth_attr_rec);
                --p_app_customer_reference            => lc_app_customer_reference,
                --p_credit_card_code                  => p_payment_rec.credit_card_code(i),
                --p_credit_card_number                => p_payment_rec.credit_card_number(i),
                --p_credit_card_holder_name           => p_payment_rec.credit_card_holder_name(i),
                --p_credit_card_expiration_date       => p_payment_rec.credit_card_expiration_date(i),
                --p_credit_card_approval_code         => p_payment_rec.credit_card_approval_code(i),
                --p_credit_card_approval_date         => p_payment_rec.credit_card_approval_date
                --x_payment_server_order_num          => p_payment_rec.tangible_id(i),
                --x_payment_response_error_code       => lc_pay_response_error_code);
                --p_trxn_extension_id                 => ln_trxn_extension_id,
                --p_credit_card_number_enc            => p_payment_rec.credit_card_number_enc(i),
                --p_identifier                        => p_payment_rec.IDENTIFIER(i));
                p_payment_rec.attribute15(i) := ln_cr_id;
                p_payment_rec.trxn_extension_id(i) := ln_trxn_extension_id;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'AFTER AR CREATE_PREPAYMENT: '
                                     || p_payment_rec.header_id(i),
                                     1);
                    oe_debug_pub.ADD(   'CASH_RECEIPT_ID IS: '
                                     || ln_cr_id,
                                     1);
                    oe_debug_pub.ADD(   'p_payment_rec.attribute15 IS: '
                                     || p_payment_rec.attribute15(i),
                                     1);
                    oe_debug_pub.ADD(   'PAYMENT_SET_ID IS: '
                                     || p_payment_rec.payment_set_id(i),
                                     1);
                    oe_debug_pub.ADD(   'Payment_response_error_code IS: '
                                     || lc_pay_response_error_code,
                                     1);
                    oe_debug_pub.ADD(   'Tangible Id is: '
                                     || p_payment_rec.tangible_id(i),
                                     1);
                    --oe_debug_pub.add(  'ln_trxn_extension_id: '||p_payment_rec.trxn_extension_id(i) , 1 ) ;
                    oe_debug_pub.ADD(   'STATUS IS: '
                                     || lc_return_status,
                                     1);
                    oe_debug_pub.ADD(   'Error Message IS: '
                                     || lc_msg_data,
                                     1);

                    SELECT TO_CHAR(SYSDATE,
                                   'DD-MON-YYYY HH24:MI:SS')
                    INTO   l_date
                    FROM   DUAL;

                    oe_debug_pub.ADD(   'Time After calling receipt api :'
                                     || l_date);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    -- For Any Error, we will still need to create records in oe_payment table.
                    -- So catch all raised exceptions and still create records.
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD('In Others for AR_PREPAYMENTS.create_prepayment ',
                                         1);
                    END IF;

                    lc_return_status := fnd_api.g_ret_sts_error;
            END;

            SELECT hsecs
            INTO   ln_end_time
            FROM   v$timer;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Time spent in receipt creation for '
                                 || p_payment_rec.orig_sys_document_ref(i)
                                 || ' IS '
                                 || (  (  ln_end_time
                                        - ln_start_time)
                                     / 100));
            END IF;

            g_create_receipt_time :=   g_create_receipt_time
                                     + (  (  ln_end_time
                                           - ln_start_time)
                                        / 100);

            -- For errors
            IF lc_return_status <> fnd_api.g_ret_sts_success
            THEN
                -- Set the message Context
                set_msg_context(p_entity_code                => 'HEADER',
                                p_header_id                  => p_payment_rec.header_id(i),
                                p_orig_sys_document_ref      => p_payment_rec.orig_sys_document_ref(i));
                ROLLBACK TO save_header;

                FOR k IN REVERSE 1 .. i
                LOOP
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'payment reverse count :'
                                         || i);
                        oe_debug_pub.ADD(   'Reverse ln_app_ref_id :'
                                         || ln_app_ref_id);
                        oe_debug_pub.ADD(   'Reverse Header Id :'
                                         || p_payment_rec.header_id(i));
                        oe_debug_pub.ADD(   'Reverse Payment Number :'
                                         || p_payment_rec.payment_number(i));
                    END IF;

                    IF ln_app_ref_id = p_payment_rec.header_id(k)
                    THEN
                        p_payment_rec.payment_set_id(k) := NULL;
                        p_payment_rec.tangible_id(k) := NULL;

                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD(   'reverse payment_set_id :'
                                             || p_payment_rec.payment_set_id(k));
                            oe_debug_pub.ADD(   'reverse tangible_id :'
                                             || p_payment_rec.tangible_id(k));
                        END IF;
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'Rollback created for header_id :'
                                     || p_payment_rec.header_id(i));
                END IF;

                IF ln_msg_count = 1
                THEN
                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'Error message after calling Create_Prepayment API: '
                                         || lc_msg_data,
                                         3);
                    END IF;

                    oe_msg_pub.add_text(p_message_text      => lc_msg_data);
                ELSIF(fnd_msg_pub.count_msg > 0)
                THEN
                    arp_util.enable_debug;
                    lc_msg_data := NULL;

                    FOR i IN 1 .. fnd_msg_pub.count_msg
                    LOOP
                        lc_msg_text := fnd_msg_pub.get(i,
                                                       'F');

                        IF   LENGTH(lc_msg_data)
                           + LENGTH(lc_msg_text) < 2000
                        THEN
                            lc_msg_data :=    lc_msg_data
                                           || lc_msg_text;
                        END IF;

                        IF lc_msg_text IS NOT NULL
                        THEN
                            IF ln_debug_level > 0
                            THEN
                                oe_debug_pub.ADD(lc_msg_text,
                                                 3);
                            END IF;

                            oe_msg_pub.add_text(p_message_text      => lc_msg_text);
                        END IF;
                    END LOOP;
                END IF;

                -- Apply hold if it doesn't exist already.
                IF NOT NVL(l_error_headers(p_payment_rec.header_id(i)),
                           'Y') = 'E'
                THEN
                    IF lc_pay_response_error_code IN('IBY_0001', 'IBY_0008')
                    THEN
                        -- need to apply epayment server failure hold
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD('applying epayment server failure hold.',
                                             3);
                        END IF;

                        ln_hold_id := 15;
                    ELSE
                        -- for any other payment_response_error_code,  apply epayment
                        -- failure hold (seeded hold id is 14).
                        IF ln_debug_level > 0
                        THEN
                            oe_debug_pub.ADD('Applying epayment failure hold.',
                                             3);
                        END IF;

                        ln_hold_id := 14;
                    END IF;                                               -- end of checking lc_pay_response_error_code.

                    apply_hold(p_header_id          => p_payment_rec.header_id(i),
                               p_hold_id            => ln_hold_id,
                               p_msg_count          => ln_msg_count,
                               p_msg_data           => lc_msg_data,
                               x_return_status      => lc_return_status);

                    IF lc_return_status <> fnd_api.g_ret_sts_success
                    THEN
                        x_return_status := fnd_api.g_ret_sts_error;
                        oe_debug_pub.ADD(   'Failed to apply epayment failure hold.'
                                         || p_payment_rec.header_id(i),
                                         3);
                    END IF;
                END IF;                                                        -- Apply hold if it doesn't exist already

                -- Add Error Processing here.
                l_error_headers(p_payment_rec.header_id(i)) := 'E';
            END IF;                                                                                        -- For errors

            ln_curr_pay_set_id := p_payment_rec.payment_set_id(i);

            <<skip_receipt>>
            IF l_error_headers(p_payment_rec.header_id(i)) <> 'E'
            THEN
                j :=   j
                     + 1;
                l_success_header(j) := p_payment_rec.header_id(i);

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   ' Deposit success record count '
                                     || j);
                END IF;
            END IF;
        END LOOP;

        -- FOR ALL Orders with successful Pre-Payment records update Lines
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   ' Success_header count is :'
                             || l_success_header.COUNT);
        END IF;

        IF l_success_header.COUNT > 0
        THEN
            BEGIN
                FORALL i IN l_success_header.FIRST .. l_success_header.LAST
                    UPDATE oe_order_lines
                    SET invoice_interface_status_code = 'PREPAID'
                    WHERE  header_id = l_success_header(i) AND NVL(invoice_interface_status_code,
                                                                   'N') <> 'PREPAID';
            EXCEPTION
                WHEN OTHERS
                THEN
                    x_return_status := fnd_api.g_ret_sts_error;
                    oe_debug_pub.ADD('Failed to Update INVOICE_INTERFACE_STATUS_CODE ',
                                     3);
            END;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(' Creating Payment Records in HVOP mode ');
        END IF;

        BEGIN
            FORALL i IN 1 .. p_payment_rec.header_id.COUNT SAVE EXCEPTIONS
                INSERT INTO oe_payments
                            (payment_level_code,
                             header_id,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             request_id,
                             payment_type_code,
                             credit_card_code,
                             --credit_card_number, R12
                             credit_card_holder_name,
                             credit_card_expiration_date,
                             prepaid_amount,
                             payment_set_id,
                             receipt_method_id,
                             payment_collection_event,
                             credit_card_approval_code,
                             credit_card_approval_date,
                             check_number,
                             payment_amount,
                             payment_number,
                             lock_control,
                             orig_sys_payment_ref,
                             CONTEXT,
                             attribute6,
                             attribute7,
                             attribute8,
                             attribute9,
                             attribute10,
                             attribute11,
                             attribute12,
                             attribute13,
                             attribute15,
                             tangible_id,
                             trxn_extension_id,
                             attribute4,
                             attribute5,
                             attribute3,
                             attribute14,
                             attribute2,
                             attribute1)
                     VALUES ('ORDER',
                             p_payment_rec.header_id(i),
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             p_request_id,
                             p_payment_rec.payment_type_code(i),
                             p_payment_rec.credit_card_code(i),
                             --p_payment_rec.credit_card_number(i), R12
                             p_payment_rec.credit_card_holder_name(i),
                             p_payment_rec.credit_card_expiration_date(i),
                             p_payment_rec.payment_amount(i),
                             p_payment_rec.payment_set_id(i),
                             p_payment_rec.receipt_method_id(i),
                             'PREPAY',
                             p_payment_rec.credit_card_approval_code(i),
                             p_payment_rec.credit_card_approval_date(i),
                             p_payment_rec.check_number(i),
                             p_payment_rec.payment_amount(i),
                             p_payment_rec.payment_number(i),
                             1,
                             p_payment_rec.orig_sys_payment_ref(i),
                             p_payment_rec.CONTEXT(i),
                             p_payment_rec.attribute6(i),
                             p_payment_rec.attribute7(i),
                             p_payment_rec.attribute8(i),
                             p_payment_rec.attribute9(i),
                             p_payment_rec.attribute10(i),
                             p_payment_rec.attribute11(i),
                             p_payment_rec.attribute12(i),
                             p_payment_rec.attribute13(i),
                             p_payment_rec.attribute15(i),
                             p_payment_rec.tangible_id(i),
                             p_payment_rec.trxn_extension_id(i),
                             p_payment_rec.credit_card_number_enc(i),
                             p_payment_rec.IDENTIFIER(i),
                             p_payment_rec.attribute3(i),
                             p_payment_rec.attribute14(i),
                             p_payment_rec.attribute2(i),
                             p_payment_rec.attribute1(i)
                             );

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(' After Creating Payment Records ' || sql%rowcount);
            END IF;
        EXCEPTION
            WHEN OTHERS
            THEN
                oe_debug_pub.ADD('OTHERS ERROR While Payment Insert , Create_Receipt_payment');
                ln_payerrors := SQL%BULK_EXCEPTIONS.COUNT;
                oe_debug_pub.ADD(   'Number Of Errors During Bulk Processing: '
                                 || ln_payerrors);

                FOR i IN 1 .. ln_payerrors
                LOOP
                    oe_debug_pub.ADD(   'Error: '
                                     || i
                                     || ', iteration '
                                     || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX
                                     || ' is '
                                     || SQLERRM(  0
                                                - SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                END LOOP;
        END;
    EXCEPTION
        WHEN OTHERS
        THEN
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('OTHERS ERROR , Create_Receipt_payment');
                oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                        1,
                                        240));
            END IF;

            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_msg_pub.add_exc_msg(g_pkg_name,
                                   'Create_Receipt_payment',
                                   SUBSTR(SQLERRM,
                                          1,
                                          240));
    END create_receipt_payment;

-- +=====================================================================+
-- | Name  : Get_rem_bank_acct_id                                        |
-- | Description  : This function will return bank account id for a given|
-- | receipt method id.                                                  |
-- |                                                                     |
-- | Parameters :  p_receipt_method_id  IN                               |
-- |               p_curr_code     IN  -> currency code for the order    |
-- |                                                                     |
-- | Return     :  bank_account_id                                       |
-- +=====================================================================+
    FUNCTION get_rem_bank_acct_id(
        p_receipt_method_id  IN  NUMBER,
        p_curr_code          IN  VARCHAR2)
        RETURN NUMBER
    IS
        lc_key  VARCHAR2(50);
    BEGIN
        lc_key :=    p_curr_code
                  || '-'
                  || p_receipt_method_id;

        IF g_bank_account_id(lc_key) IS NULL
        THEN
            SELECT cba.bank_account_id
            INTO   g_bank_account_id(lc_key)
            FROM   ar_receipt_methods rm,
                   ar_receipt_method_accounts_all rma,
                   ar_receipt_classes rc,
                   ce_bank_acct_uses_all aba,
                   ce_bank_accounts cba
            WHERE  rm.receipt_method_id = p_receipt_method_id
            AND    rm.receipt_method_id = rma.receipt_method_id
            AND    rc.receipt_class_id = rm.receipt_class_id
            AND    rc.creation_method_code = 'AUTOMATIC'
            AND    remit_bank_acct_use_id = aba.bank_acct_use_id
            AND    aba.bank_account_id = cba.bank_account_id
            AND    cba.currency_code = DECODE(cba.receipt_multi_currency_flag,
                                              'Y', cba.currency_code,
                                              p_curr_code)
            AND    rma.primary_flag = 'Y';
        END IF;

        RETURN g_bank_account_id(lc_key);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_rem_bank_acct_id;

-- +=====================================================================+
-- | Name  : Apply_Hold                                                  |
-- | Description  : This procedure will be used to put the order on hold |
-- | if it fails in any of the DATA_PULL processing                      |
-- |                                                                     |
-- | Parameters :  p_header_id   IN                                      |
-- |               p_hold_id     IN  -> Hold Id of the hold tobe used    |
-- |               p_msg_count   IN  -> message count                    |
-- |               p_msg_data    IN  -> Any messages added before        |
-- |               x_return_status OUT  -> Return status                 |
-- |                                       'S' -> success                |
-- |                                       'E' -> expected error         |
-- |                                       'U' -> Unexpected error       |
-- +=====================================================================+
    PROCEDURE apply_hold(
        p_header_id      IN             NUMBER,
        p_hold_id        IN             NUMBER,
        p_msg_count      IN OUT NOCOPY  NUMBER,
        p_msg_data       IN OUT NOCOPY  VARCHAR2,
        x_return_status  OUT NOCOPY     VARCHAR2)
    IS
        lc_hold_exists           VARCHAR2(1)                       := 'N';
        ln_msg_count             NUMBER                            := 0;
        lc_msg_data              VARCHAR2(2000);
        lc_return_status         VARCHAR2(30);
        l_hold_source_rec        oe_holds_pvt.hold_source_rec_type;
--
        ln_debug_level  CONSTANT NUMBER                            := oe_debug_pub.g_debug_level;
--
    BEGIN
        x_return_status := fnd_api.g_ret_sts_success;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('XXOMSACTB: IN APPLY PREPAYMENT HOLDS',
                             3);
            oe_debug_pub.ADD(   'HEADER ID : '
                             || p_header_id,
                             3);
            oe_debug_pub.ADD(   'Hold Comment is : '
                             || p_msg_data);
        END IF;

        -- Apply Prepayment Hold on Header
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXOMSACTB: APPLYING HOLD ON HEADER ID : '
                             || p_header_id,
                             3);
        END IF;

        l_hold_source_rec.hold_id := p_hold_id;                                                        -- Requested Hold
        l_hold_source_rec.hold_entity_code := 'O';                                                         -- Order Hold
        l_hold_source_rec.hold_entity_id := p_header_id;                                                 -- Order Header
        l_hold_source_rec.hold_comment := SUBSTR(p_msg_data,
                                                 1,
                                                 2000);
        oe_holds_pub.apply_holds(p_api_version           => 1.0,
                                 p_validation_level      => fnd_api.g_valid_level_none,
                                 p_hold_source_rec       => l_hold_source_rec,
                                 x_msg_count             => ln_msg_count,
                                 x_msg_data              => lc_msg_data,
                                 x_return_status         => lc_return_status);

        IF lc_return_status = fnd_api.g_ret_sts_success
        THEN
            IF p_hold_id = 14
            THEN
                fnd_message.set_name('ONT',
                                     'ONT_PAYMENT_FAILURE_HOLD');
                oe_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD('XXOMSACTB: payment failure hold has been applied on order.',
                                     3);
                END IF;
            ELSIF p_hold_id = 15
            THEN
                fnd_message.set_name('ONT',
                                     'ONT_PAYMENT_SERVER_FAIL_HOLD');
                oe_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD('XXOMSACTB: payment server failure hold has been applied on order.',
                                     3);
                END IF;
            ELSE
                fnd_message.set_name('XXOM',
                                     'XX_OM_SA_PROCESS_HOLD_APPLIED');
                fnd_message.set_token('ATTRIBUTE1',
                                      p_header_id);
                oe_msg_pub.ADD;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD('OD Sales Accounting Processing Hold Applied.',
                                     3);
                END IF;
            END IF;
        ELSIF lc_return_status = fnd_api.g_ret_sts_error
        THEN
            RAISE fnd_api.g_exc_error;
        ELSIF lc_return_status = fnd_api.g_ret_sts_unexp_error
        THEN
            RAISE fnd_api.g_exc_unexpected_error;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'XXOMSACTB: APPLIED PREPAYMENT HOLD ON HEADER ID:'
                             || p_header_id,
                             3);
        END IF;
    EXCEPTION
        WHEN fnd_api.g_exc_error
        THEN
            x_return_status := fnd_api.g_ret_sts_error;
            oe_msg_pub.count_and_get(p_count      => ln_msg_count,
                                     p_data       => lc_msg_data);
        WHEN fnd_api.g_exc_unexpected_error
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_msg_pub.count_and_get(p_count      => ln_msg_count,
                                     p_data       => lc_msg_data);
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;

            IF fnd_msg_pub.check_msg_level(fnd_msg_pub.g_msg_lvl_unexp_error)
            THEN
                fnd_msg_pub.add_exc_msg(g_pkg_name,
                                        'Apply_Hold');
            END IF;

            oe_msg_pub.count_and_get(p_count      => ln_msg_count,
                                     p_data       => lc_msg_data);
    END apply_hold;

-- +=====================================================================+
-- | Name  : Create_Sales_Credits                                        |
-- | Description  : May not be needed...                                 |                                                                   
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE create_sales_credits(
        p_header_id      IN      NUMBER,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        l_scredit_rec            scredit_rec_type;
        l_new_scredit_rec        scredit_rec_type;
        ln_debug_level  CONSTANT NUMBER                               := oe_debug_pub.g_debug_level;

        CURSOR c_salesrep
        IS
            SELECT   h.salesrep_id,
                     h.header_id,
                     a.party_id,
                     ca.party_site_id,
                     'N'
            FROM     oe_order_headers_all h,
                     hz_cust_accounts a,
                     hz_cust_site_uses_all s,
                     hz_cust_acct_sites_all ca
            WHERE    h.batch_id = p_batch_id
            AND      h.salesrep_id <> -3
            AND      h.sold_to_org_id = a.cust_account_id
            AND      h.ship_to_org_id = s.site_use_id
            AND      s.cust_acct_site_id = ca.cust_acct_site_id
            ORDER BY h.header_id;

        l_trans_rec_type         jtf_terr_lookup_pub.trans_rec_type;
        lc_return_status         VARCHAR2(10);
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(255);
        l_winners_tbl            jtf_terr_lookup_pub.winners_tbl_type;
        ln_salesrep_id           NUMBER;
        ln_org_id                NUMBER                               := TO_NUMBER(fnd_profile.VALUE('ORG_ID'));
        j                        BINARY_INTEGER;
    BEGIN
        x_return_status := fnd_api.g_ret_sts_success;
        oe_debug_pub.ADD(   'Entering Sales Credit Processing '
                         || p_batch_id);

        -- Check if a Valid Sales Rep exists for the orders.
        OPEN c_salesrep;

        FETCH c_salesrep
        BULK COLLECT INTO l_scredit_rec.salesrep_id,
               l_scredit_rec.header_id,
               l_scredit_rec.party_id,
               l_scredit_rec.party_site_id,
               l_scredit_rec.match_flag;

        CLOSE c_salesrep;

        -- If no orders with valid salesrep then skip
        IF l_scredit_rec.header_id.COUNT = 0
        THEN
            oe_debug_pub.ADD(   'No Sales Credit to process '
                             || p_batch_id);
            RETURN;
        END IF;

        IF g_sales_credit_type_id IS NULL
        THEN
            BEGIN
                SELECT sales_credit_type_id
                INTO   g_sales_credit_type_id
                FROM   oe_sales_credit_types
                WHERE  NAME = 'Non-quota Sales Credit';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    g_sales_credit_type_id := NULL;
            END;
        END IF;

        -- Call the JTF_TERR_LOOKUP_PUB.Get_Winners API to get the salesreps.
        j := 0;                                                                         -- Counter for l_new_scredit_rec

        FOR i IN 1 .. l_scredit_rec.header_id.COUNT
        LOOP
            -- This 'use_type will provide more resource details in l_winners_tbl
            -- Other valid values
            -- 'LOOKUP' gives basic territory and resource details
            -- 'TERRITORY' gives more details of the territory definition
            l_trans_rec_type.use_type := 'RESOURCE';
            -- This is the transactional data you should provide from each order/line.
            l_trans_rec_type.squal_num01 := l_scredit_rec.party_id(i);
            l_trans_rec_type.squal_num02 := l_scredit_rec.party_site_id(i);
            -- For sales and telesales/account set these two values for
            -- p_source_id = -1001 and p_trans_id = -1002
            -- We should be focusing on Sales and Telesales for Accounts
            -- in the context of HVOP
            oe_debug_pub.ADD('Calling Get Winners ');
            oe_debug_pub.ADD(   'Party_id '
                             || l_scredit_rec.party_id(i));
            oe_debug_pub.ADD(   'Party Site Id '
                             || l_scredit_rec.party_site_id(i));
            jtf_terr_lookup_pub.get_winners(p_api_version_number      => 1.0,
                                            p_init_msg_list           => fnd_api.g_false,
                                            p_trans_rec               => l_trans_rec_type,
                                            p_source_id               => -1001,
                                            p_trans_id                => -1002,
                                            p_resource_type           => fnd_api.g_miss_char,
                                            p_role                    => fnd_api.g_miss_char,
                                            x_return_status           => lc_return_status,
                                            x_msg_count               => ln_msg_count,
                                            x_msg_data                => lc_msg_data,
                                            x_winners_tbl             => l_winners_tbl);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'For header_id : '
                                 || l_scredit_rec.header_id(i));
                oe_debug_pub.ADD(   'No of salesreps returned by Get_Winners : '
                                 || l_winners_tbl.COUNT);
            END IF;

            -- If no winners found then set the match_flag on l_scredit_rec
            IF l_winners_tbl.COUNT = 0
            THEN
                oe_debug_pub.ADD(   'Setting the match flag for index :'
                                 || i);
                l_scredit_rec.match_flag(i) := 'Y';
            END IF;

            FOR i IN 1 .. l_winners_tbl.COUNT
            LOOP
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   ' Get_Winners Result '
                                     || l_winners_tbl(i).resource_name);
                END IF;

                ln_salesrep_id := NULL;

                SELECT salesrep_id
                INTO   ln_salesrep_id
                FROM   jtf_rs_salesreps jrs
                WHERE  jrs.resource_id = l_winners_tbl(i).resource_id AND org_id = ln_org_id AND ROWNUM = 1;

                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   ' Winner Salesrep id is '
                                     || ln_salesrep_id);
                END IF;

                IF l_scredit_rec.salesrep_id(i) <> ln_salesrep_id
                THEN
                    oe_debug_pub.ADD(' Winner Salesrep id Is New');
                    j :=   j
                         + 1;
                    l_new_scredit_rec.salesrep_id(j) := ln_salesrep_id;
                    l_new_scredit_rec.header_id(j) := l_scredit_rec.header_id(i);
                ELSE
                    oe_debug_pub.ADD(' Winner Salesrep id Matches the one on header');
                    l_scredit_rec.match_flag(i) := 'Y';
                END IF;
            END LOOP;
        END LOOP;

        -- Delete the records for which no match was found
        oe_debug_pub.ADD('Deleting sales credit records for not found');
        FORALL i IN 1 .. l_scredit_rec.salesrep_id.COUNT
            DELETE FROM oe_sales_credits
            WHERE       header_id = l_scredit_rec.header_id(i)
            AND         salesrep_id = l_scredit_rec.salesrep_id(i)
            AND         l_scredit_rec.match_flag(i) = 'N';
        -- If the API returns the same Salesrep as the one on order or returns
        -- none then no need to create new sales credit records.
        -- Update the records for non-quote sales credit type.
        oe_debug_pub.ADD(' Updating sales credit type ');
        FORALL i IN 1 .. l_scredit_rec.salesrep_id.COUNT
            UPDATE oe_sales_credits
            SET sales_credit_type_id = g_sales_credit_type_id
            WHERE  header_id = l_scredit_rec.header_id(i)
            AND    salesrep_id = l_scredit_rec.salesrep_id(i)
            AND    l_scredit_rec.match_flag(i) = 'Y';

        IF l_new_scredit_rec.salesrep_id.COUNT > 0
        THEN
            -- Create new entries for the extra SalesReps..
            oe_debug_pub.ADD('Creating new sales credit records for New');
            FORALL i IN 1 .. l_new_scredit_rec.salesrep_id.COUNT
                INSERT INTO oe_sales_credits
                            (sales_credit_id,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             header_id,
                             salesrep_id,
                             PERCENT,
                             sales_credit_type_id,
                             sales_group_id,
                             lock_control)
                     VALUES (oe_sales_credits_s.NEXTVAL,
                             SYSDATE,
                             fnd_global.user_id,
                             SYSDATE,
                             fnd_global.user_id,
                             l_scredit_rec.header_id(i),
                             l_scredit_rec.salesrep_id(i),
                             100,
                             g_sales_credit_type_id,
                             -1,
                             1);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_debug_pub.ADD('OTHERS ERROR , Create_Sales_Credits');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END create_sales_credits;

-- +=====================================================================+
-- | Name  : Get_Custom_Attributes                                            |
-- | Description  : This Procedure will look at interface data and will  |
-- | creat KFF-DFF records in KFF tables. This can get called in SOI or  |
-- | in HVOP mode.                                                       |
-- |                                                                     |
-- | Parameters :  p_header_id  IN  -> header_id of the current order    |
-- |               p_mode       IN  -> BULK or NORMAL
-- |               p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE get_custom_attributes(
        p_header_id      IN      NUMBER,
        p_mode           IN      VARCHAR2,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
    BEGIN
        -- Check if the mode is BULK..
        IF p_mode = 'NORMAL'
        THEN
            oe_debug_pub.ADD('Custom Table Insert 1');

            -- This is SOI mode. Which means process one record at a time.
            -- Get Line KFF data first
            INSERT INTO xx_om_line_attributes_all
                        (line_id,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         vendor_product_code,
                         contract_details,
                         item_note,
                         line_comments,
                         taxable_flag,
                         sku_dept,
                         item_source,
                         canada_pst_tax,
                         average_cost,
                         po_cost,
                         return_act_cat_code,
                         ret_orig_order_num,
                         ret_orig_order_line_num,
                         backordered_qty,
                         ret_orig_order_date,
                         sku_list_price,
                         wholesaler_item,
                         ret_ref_header_id,
                         ret_ref_line_id,
                         release_num,
                         cost_center_dept,
                         desktop_del_addr,
                         config_code,
                         ext_top_model_line_id,
                         ext_link_to_line_id,
                         gsa_flag,
                         waca_item_ctr_num,
                         consignment_bank_code,
                         price_cd,
                         price_change_reason_cd,
                         price_prefix_cd,
                         commisionable_ind,
                         cust_dept_description,
                         unit_orig_selling_price,
                         mps_toner_retail,
                         upc_code,
                         price_type,
                         external_sku,
                         tax_rate,
                         tax_amount,
                         kit_sku,
                         kit_qty,
                         kit_vend_product_code,
                         kit_sku_dept,
                         kit_seqnum,
                         kit_parent,
						 item_description)
                SELECT li.line_id,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       vendor_product_code,
                       i.contract_details,
                       i.item_comments,
                       i.line_comments,
                       i.taxable_flag,
                       i.sku_dept,
                       i.item_source,
                       i.canada_pst,
                       i.average_cost,
                       i.po_cost,
                       i.return_act_cat_code,
                       i.ret_orig_order_num,
                       i.ret_orig_order_line_num,
                       i.back_ordered_qty,
                       i.ret_orig_order_date,
                       i.legacy_list_price,
                       i.wholesaler_item,
                       i.ret_ref_header_id,
                       i.ret_ref_line_id,
                       i.release_num,
                       i.cost_center_dept,
                       i.desktop_del_addr,
                       i.config_code,
                       i.ext_top_model_line_id,
                       i.ext_link_to_line_id,
                       i.gsa_flag,
                       i.waca_item_ctr_num,
                       i.consignment_bank_code,
                       i.price_cd,
                       i.price_change_reason_cd,
                       i.price_prefix_cd,
                       i.commisionable_ind,
                       i.cust_dept_description,
                       i.unit_orig_selling_price,
                       i.mps_toner_retail,
                       i.upc_code,
                       i.price_type,
                       i.external_sku,
                       i.tax_rate,
                       i.tax_amount,
                       i.kit_sku,
                       i.kit_qty,
                       i.kit_vend_product_code,
                       i.kit_sku_dept,
                       i.kit_seqnum,
                       i.kit_parent,
					   i.item_description
                FROM   xx_om_lines_attr_iface_all i,
                       oe_order_lines_all li
                WHERE  li.header_id = p_header_id
                AND    i.orig_sys_document_ref = li.orig_sys_document_ref
                AND    i.orig_sys_line_ref = li.orig_sys_line_ref
                AND    i.order_source_id = li.order_source_id;

            oe_debug_pub.ADD('Custom Table Update 1');

             FOR i_rec IN ( SELECT DISTINCT line_id , kit_seqnum, li.header_id
                            FROM xx_om_lines_attr_iface_all i,
                                 oe_order_lines_all li
                            WHERE li.header_id = p_header_id
                            AND   i.orig_sys_document_ref = li.orig_sys_document_ref
                            AND   i.orig_sys_line_ref = li.orig_sys_line_ref
                            AND   i.order_source_id = li.order_source_id
                            AND   i.kit_parent = 'Y' )

             LOOP
               UPDATE xx_om_line_attributes_all
               SET link_to_kit_line_id = i_rec.line_id
               WHERE line_id In ( SELECT line_id from oe_order_lines_all 
                                  WHERE header_id = i_rec.header_id )
               AND kit_seqnum = i_rec.kit_seqnum
               AND NVL(kit_parent,'N') != 'Y';

            END LOOP;

            oe_debug_pub.ADD('Custom Table Insert 3');

            INSERT INTO xx_om_header_attributes_all
                        (header_id,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         created_by_store_id,
                         paid_at_store_id,
                         spc_card_number,
                         placement_method_code,
                         delivery_code,
                         delivery_method,
                         advantage_card_number,
                         created_by_id,
                         release_number,
                         cost_center_dept,
                         desk_del_addr,
                         gift_flag,
                         comments,
                         orig_cust_name,
                         od_order_type,
                         ship_to_sequence,
                         ship_to_address1,
                         ship_to_address2,
                         ship_to_city,
                         ship_to_state,
                         ship_to_country,
                         ship_to_county,
                         ship_to_zip,
                         ship_to_name,
                         bill_to_name,
                         cust_contact_name,
                         cust_pref_phone,
                         cust_pref_phextn,
                         imp_file_name,
                         tax_rate,
                         order_total,
                         commisionable_ind,
                         order_action_code,
                         order_start_time,
                         order_end_time,
                         order_taxable_cd,
                         override_delivery_chg_cd,
                         ship_to_geocode,
                         cust_dept_description,
                         tran_number,
                         aops_geo_code,
                         tax_exempt_amount,
                         sr_number,
                         cust_pref_email,
                         atr_order_flag,
                         device_serial_num,
                         app_id,
                         external_transaction_number,
                         freight_tax_rate,
                         freight_tax_amount,
                         bill_level,
                         bill_override_flag,
                         bill_comp_flag,
                         parent_order_num,
                         cost_center_split)
                SELECT h.header_id,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       created_by_store_id,
                       paid_at_store_id,
                       spc_card_number,
                       placement_method_code,
                       delivery_code,
                       delivery_method,
                       advantage_card_number,
                       created_by_id,
                       release_no,
                       cust_dept_no,
                       desk_top_no,
                       gift_flag,
                       comments,
                       orig_cust_name,
                       od_order_type,
                       ship_to_sequence,
                       ship_to_address1,
                       ship_to_address2,
                       ship_to_city,
                       ship_to_state,
                       ship_to_country,
                       ship_to_county,
                       ship_to_zip,
                       ship_to_name,
                       bill_to_name,
                       cust_contact_name,
                       cust_pref_phone,
                       cust_pref_phextn,
                       imp_file_name,
                       tax_rate,
                       order_total,
                       commisionable_ind,
                       order_action_code,
                       order_start_time,
                       order_end_time,
                       order_taxable_cd,
                       override_delivery_chg_cd,
                       ship_to_geocode,
                       cust_dept_description,
                       tran_number,
                       aops_geo_code,
                       tax_exempt_amount,
                       sr_number,
                       cust_pref_email,
                       atr_order_flag,
                       device_serial_num,
                       app_id,
                       external_transaction_number,
                       freight_tax_rate,
                       freight_tax_amount,
                       bill_level,
                       bill_override_flag,
                       bill_comp_flag,
                       parent_order_num,
                       cost_center_split
                FROM   xx_om_headers_attr_iface_all i,
                       oe_order_headers_all h
                WHERE  h.header_id = p_header_id
                AND    i.orig_sys_document_ref = h.orig_sys_document_ref
                AND    i.order_source_id = h.order_source_id;

            oe_debug_pub.ADD('End Custom Insert ');
        ELSE
            -- This is BULK Mode and we can insert data for all of the batch
            oe_debug_pub.ADD('CUSTOM Insert 1');

            -- Get Line KFF data first
            INSERT INTO xx_om_line_attributes_all
                        (line_id,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         vendor_product_code,
                         contract_details,
                         item_note,
                         line_comments,
                         taxable_flag,
                         sku_dept,
                         item_source,
                         canada_pst_tax,
                         average_cost,
                         po_cost,
                         return_act_cat_code,
                         ret_orig_order_num,
                         ret_orig_order_line_num,
                         backordered_qty,
                         ret_orig_order_date,
                         sku_list_price,
                         wholesaler_item,
                         ret_ref_header_id,
                         ret_ref_line_id,
                         release_num,
                         cost_center_dept,
                         desktop_del_addr,
                         config_code,
                         ext_top_model_line_id,
                         ext_link_to_line_id,
                         gsa_flag,
                         waca_item_ctr_num,
                         consignment_bank_code,
                         price_cd,
                         price_change_reason_cd,
                         price_prefix_cd,
                         commisionable_ind,
                         cust_dept_description,
                         unit_orig_selling_price,
                         mps_toner_retail,
                         upc_code,
                         price_type,
                         external_sku,
                         tax_rate,
                         tax_amount,
                         kit_sku,
                         kit_qty,
                         kit_vend_product_code,
                         kit_sku_dept,
                         kit_seqnum,
                         kit_parent,
						 item_description
)
                SELECT li.line_id,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       vendor_product_code,
                       i.contract_details,
                       i.item_comments,
                       i.line_comments,
                       i.taxable_flag,
                       i.sku_dept,
                       i.item_source,
                       i.canada_pst,
                       i.average_cost,
                       i.po_cost,
                       i.return_act_cat_code,
                       i.ret_orig_order_num,
                       i.ret_orig_order_line_num,
                       i.back_ordered_qty,
                       i.ret_orig_order_date,
                       i.legacy_list_price,
                       i.wholesaler_item,
                       i.ret_ref_header_id,
                       i.ret_ref_line_id,
                       i.release_num,
                       i.cost_center_dept,
                       i.desktop_del_addr,
                       i.config_code,
                       i.ext_top_model_line_id,
                       i.ext_link_to_line_id,
                       i.gsa_flag,
                       i.waca_item_ctr_num,
                       i.consignment_bank_code,
                       i.price_cd,
                       i.price_change_reason_cd,
                       i.price_prefix_cd,
                       i.commisionable_ind,
                       i.cust_dept_description,
                       i.unit_orig_selling_price,
                       i.mps_toner_retail,
                       i.upc_code,
                       i.price_type,
                       i.external_sku,
                       i.tax_rate,
                       i.tax_amount,
                       i.kit_sku,
                       i.kit_qty,
                       i.kit_vend_product_code,
                       i.kit_sku_dept,
                       i.kit_seqnum,
                       i.kit_parent,
					   i.item_description
                FROM   xx_om_lines_attr_iface_all i,
                       oe_order_lines_all li,
                       oe_order_headers_all h
                WHERE  h.batch_id = p_batch_id
                AND    i.orig_sys_document_ref = li.orig_sys_document_ref
                AND    i.orig_sys_line_ref = li.orig_sys_line_ref
                AND    i.order_source_id = li.order_source_id
                AND    h.header_id = li.header_id;

             oe_debug_pub.ADD('Custom Table Update 2');

             FOR i_rec IN ( SELECT DISTINCT line_id , kit_seqnum, li.header_id
                            FROM xx_om_lines_attr_iface_all i,
                                 oe_order_lines_all li,
                                 oe_order_headers_all h
                            WHERE h.batch_id = p_batch_id
                            AND   i.orig_sys_document_ref = li.orig_sys_document_ref
                            AND   i.orig_sys_line_ref = li.orig_sys_line_ref
                            AND   i.order_source_id = li.order_source_id
                            AND    h.header_id = li.header_id
                            AND   i.kit_parent = 'Y' )

             LOOP
               UPDATE xx_om_line_attributes_all
               SET link_to_kit_line_id = i_rec.line_id
               WHERE line_id In ( SELECT line_id from oe_order_lines_all 
                                  WHERE header_id = i_rec.header_id )
               AND kit_seqnum  = i_rec.kit_seqnum
               AND NVL(kit_parent,'N') != 'Y';
            END LOOP;

            -- Get Header attributes data
            oe_debug_pub.ADD('CUSTOM Insert 2');

            INSERT INTO xx_om_header_attributes_all
                        (header_id,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         created_by_store_id,
                         paid_at_store_id,
                         spc_card_number,
                         placement_method_code,
                         delivery_code,
                         delivery_method,
                         advantage_card_number,
                         created_by_id,
                         release_number,
                         cost_center_dept,
                         desk_del_addr,
                         gift_flag,
                         comments,
                         orig_cust_name,
                         od_order_type,
                         ship_to_sequence,
                         ship_to_address1,
                         ship_to_address2,
                         ship_to_city,
                         ship_to_state,
                         ship_to_country,
                         ship_to_county,
                         ship_to_zip,
                         ship_to_name,
                         bill_to_name,
                         cust_contact_name,
                         cust_pref_phone,
                         cust_pref_phextn,
                         imp_file_name,
                         tax_rate,
                         order_total,
                         commisionable_ind,
                         order_action_code,
                         order_start_time,
                         order_end_time,
                         order_taxable_cd,
                         override_delivery_chg_cd,
                         ship_to_geocode,
                         cust_dept_description,
                         tran_number,
                         aops_geo_code,
                         tax_exempt_amount,
                         sr_number,
                         cust_pref_email,
                         atr_order_flag,
                         device_serial_num,
                         app_id,
                         external_transaction_number,
                         freight_tax_rate,
                         freight_tax_amount,
                         bill_level,
                         bill_override_flag,
                         bill_comp_flag,
                         parent_order_num,
                         cost_center_split)
                SELECT h.header_id,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       created_by_store_id,
                       paid_at_store_id,
                       spc_card_number,
                       placement_method_code,
                       delivery_code,
                       delivery_method,
                       advantage_card_number,
                       created_by_id,
                       release_no,
                       cust_dept_no,
                       desk_top_no,
                       gift_flag,
                       comments,
                       orig_cust_name,
                       od_order_type,
                       ship_to_sequence,
                       ship_to_address1,
                       ship_to_address2,
                       ship_to_city,
                       ship_to_state,
                       ship_to_country,
                       ship_to_county,
                       ship_to_zip,
                       ship_to_name,
                       bill_to_name,
                       cust_contact_name,
                       cust_pref_phone,
                       cust_pref_phextn,
                       imp_file_name,
                       tax_rate,
                       order_total,
                       commisionable_ind,
                       order_action_code,
                       order_start_time,
                       order_end_time,
                       order_taxable_cd,
                       override_delivery_chg_cd,
                       ship_to_geocode,
                       cust_dept_description,
                       tran_number,
                       aops_geo_code,
                       tax_exempt_amount,
                       sr_number,
                       cust_pref_email,
                       atr_order_flag,
                       device_serial_num,
                       app_id,
                       external_transaction_number,
                       freight_tax_rate,
                       freight_tax_amount,
                       bill_level,
                       bill_override_flag,
                       bill_comp_flag,
                       parent_order_num,
                       cost_center_split
                FROM   xx_om_headers_attr_iface_all i,
                       oe_order_headers_all h
                WHERE  h.batch_id = p_batch_id
                AND    i.orig_sys_document_ref = h.orig_sys_document_ref
                AND    i.order_source_id = h.order_source_id;

            oe_debug_pub.ADD('END CUSTOM Insert ');
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_debug_pub.ADD('OTHERS ERROR , Get_Custom_Attributes');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END get_custom_attributes;

-- +=====================================================================+
-- | Name  : Create_Tax_Records                                          |
-- | Description  : This Procedure will look at interface data and will  |
-- | create TAX records in oe_price_adjustments table. This can get called|
-- | in SOI or in HVOP mode.                                             |
-- |                                                                     |
-- | Parameters :  p_header_id  IN  -> header_id of the current order    |
-- |               p_mode       IN  -> BULK or NORMAL
-- |               p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE create_tax_records(
        p_header_id      IN      NUMBER,
        p_mode           IN      VARCHAR2,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
    BEGIN
        -- Check if the mode is BULK..
        IF p_mode = 'NORMAL'
        THEN
            -- For non-bulk mode create TAX record for the current order
            oe_debug_pub.ADD(   'Inside Create_Tax_Records for '
                             || p_header_id);

            INSERT INTO oe_price_adjustments
                        (price_adjustment_id,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         header_id,
                         line_id,
                         automatic_flag,
                         list_line_type_code,
                         operand,
                         arithmetic_operator,
                         tax_code,
                         adjusted_amount)
                SELECT oe_price_adjustments_s.NEXTVAL,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       l.header_id,
                       l.line_id,
                       'Y',
                       'TAX',
                       l.tax_rate,
                       'AMT',
                       i.tax_code,
                       i.tax_value
                FROM   oe_order_lines_all l,
                       oe_lines_iface_all i
                WHERE  l.header_id = p_header_id
                AND    i.tax_value > 0
                AND    l.orig_sys_document_ref = i.orig_sys_document_ref
                AND    l.orig_sys_line_ref = i.orig_sys_line_ref
                AND    l.order_source_id = i.order_source_id;

            oe_debug_pub.ADD('Inside Create_Tax_Records for 1 ');

            -- Update the TAX Value for all Lines Of the Order.
            UPDATE oe_order_lines_all l
            SET tax_value =
                    (SELECT i.tax_value
                     FROM   oe_lines_iface_all i
                     WHERE  l.line_id = i.line_id
                     AND    l.orig_sys_document_ref = i.orig_sys_document_ref
                     AND    l.orig_sys_line_ref = i.orig_sys_line_ref)
            WHERE  header_id = p_header_id;

            oe_debug_pub.ADD('Inside Create_Tax_Records for 2 ');
        ELSE
            -- For bulk mode create TAX records for all orders in the batch
            INSERT INTO oe_price_adjustments
                        (price_adjustment_id,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         header_id,
                         line_id,
                         automatic_flag,
                         list_line_type_code,
                         operand,
                         arithmetic_operator,
                         tax_code,
                         adjusted_amount)
                SELECT oe_price_adjustments_s.NEXTVAL,
                       SYSDATE,
                       fnd_global.user_id,
                       SYSDATE,
                       fnd_global.user_id,
                       l.header_id,
                       l.line_id,
                       'Y',
                       'TAX',
                       l.tax_rate,
                       'AMT',
                       l.tax_code,
                       l.tax_value
                FROM   oe_order_headers_all h,
                       oe_order_lines_all l
                WHERE  h.header_id = l.header_id AND h.batch_id = p_batch_id AND l.tax_value > 0;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_debug_pub.ADD('OTHERS ERROR , Create_Tax_Records');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END create_tax_records;

-- +=====================================================================+
-- | Name  : Create_Sales_Credits                                        |
-- | Description  : This Procedure will look at interface data and will  |
-- | create sales credit records in oe_sales_credits table. It will only  |
-- | get called in HVOP mode                                             |
-- |                                                                     |
-- | Parameters :  p_batch_id   IN  -> batch_id of the current HVOP batch|
-- |               x_return_status OUT -> Return Result 'S','E','U'      |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE create_sales_credits(
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        ln_debug_level  CONSTANT NUMBER        := oe_debug_pub.g_debug_level;
        lc_return_status         VARCHAR2(10);
        ln_msg_count             NUMBER;
        lc_msg_data              VARCHAR2(255);
        ln_salesrep_id           NUMBER;
    BEGIN
        x_return_status := fnd_api.g_ret_sts_success;
        RETURN;                                                -- No need to create sales credit records for release 1.

        INSERT INTO oe_sales_credits
                    (sales_credit_id,
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     header_id,
                     salesrep_id,
                     PERCENT,
                     sales_credit_type_id,
                     lock_control)
            SELECT oe_sales_credits_s.NEXTVAL,
                   SYSDATE,
                   fnd_global.user_id,
                   SYSDATE,
                   fnd_global.user_id,
                   h.header_id,
                   i.salesrep_id,
                   100,
                   i.sales_credit_type_id,
                   1
            FROM   oe_credits_iface_all i,
                   oe_order_headers_all h
            WHERE  i.orig_sys_document_ref = h.orig_sys_document_ref
            AND    i.order_source_id = h.order_source_id
            AND    i.sold_to_org_id = h.sold_to_org_id
            AND    h.batch_id = p_batch_id
            AND    NOT EXISTS(SELECT sales_credit_id
                              FROM   oe_sales_credits s
                              WHERE  s.header_id = h.header_id AND s.salesrep_id = i.salesrep_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_debug_pub.ADD('OTHERS ERROR , Create_Sales_Credits');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END create_sales_credits;

-- +=========================================================================+
-- | Name  : Get_Return_Tenders                                              |
-- | Description  : This Procedure will look at interface data and will      |
-- | create return tender records in XX_OM_RETURN_TENDERS_ALL table. It will |
-- | only get called in NORMAL mode                                          |
-- |                                                                         |
-- | Parameters :  p_batch_id   IN  -> batch_id of the current HVOP batch    |
-- |               x_return_status OUT -> Return Result 'S','E','U'          |
-- |                                                                         |
-- |                                                                         |
-- +=========================================================================+
    PROCEDURE get_return_tenders(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
    BEGIN
        INSERT INTO xx_om_return_tenders_all
                    (orig_sys_document_ref,
                     orig_sys_payment_ref,
                     request_id,
                     header_id,
                     payment_number,
                     payment_type_code,
                     credit_card_code,
                     credit_card_number,
                     IDENTIFIER,
                     credit_card_holder_name,
                     credit_card_expiration_date,
                     credit_amount,
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     org_id,
                     cc_auth_manual,
                     merchant_number,
                     cc_auth_ps2000,
                     allied_ind,
                     receipt_method_id,
                     cc_mask_number,
                     process_code,
                     od_payment_type,
                     i1025_status,
                     token_flag,
                     emv_card,
                     emv_terminal,
                     emv_transaction,
                     emv_offline,
                     emv_fallback,
                     emv_tvr,
                     wallet_type,
                     wallet_id,
                     credit_card_approval_code)
            SELECT h.orig_sys_document_ref,
                   i.orig_sys_payment_ref,
                   h.request_id,
                   h.header_id,
                   i.payment_number,
                   i.payment_type_code,
                   i.credit_card_code,
                   i.credit_card_number,
                   i.IDENTIFIER,
                   i.credit_card_holder_name,
                   i.credit_card_expiration_date,
                   i.credit_amount,
                   SYSDATE,
                   fnd_global.user_id,
                   SYSDATE,
                   fnd_global.user_id,
                   h.org_id,
                   i.cc_auth_manual,
                   i.merchant_number,
                   i.cc_auth_ps2000,
                   i.allied_ind,
                   i.receipt_method_id,
                   i.cc_mask_number,
                   'P',
                   i.od_payment_type,
                   CASE s.NAME
                       WHEN 'POE'
                           THEN 'POS'
                       ELSE 'NEW'
                   END,
                   i.token_flag,
                   i.emv_card,
                   i.emv_terminal,
                   i.emv_transaction,
                   i.emv_offline,
                   i.emv_fallback,
                   i.emv_tvr,
                   i.wallet_type,
                   i.wallet_id,
                   i.credit_card_approval_code
            FROM   xx_om_ret_tenders_iface_all i,
                   oe_order_headers_all h,
                   oe_order_sources s
            WHERE  h.header_id = p_header_id
            AND    h.orig_sys_document_ref = i.orig_sys_document_ref
            AND    h.order_source_id = i.order_source_id
            AND    h.sold_to_org_id = i.sold_to_org_id
            AND    h.order_source_id = s.order_source_id;
    EXCEPTION
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_unexp_error;
            oe_debug_pub.ADD('OTHERS ERROR , Get_Return_Tenders');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END get_return_tenders;

-- +=====================================================================+
-- | Name  : Update_Line_Attributes                                      |
-- | Description  : This Procedure will look at interface table and will |
-- | update OE_ORDER_LINES_ALL table with actual_shipment_date,          |
-- | schedule_ship_date and schedule_arrival_date                        |
-- | It will get called in NORMAL mode as well as in BULK mode           |
-- |                                                                     |
-- | Parameters :  p_header_id   IN  ->current header_id                 |
-- |                                                                     |
-- |                                                                     |
-- +=====================================================================+
    PROCEDURE update_line_attributes(
        p_header_id  IN  NUMBER,
        p_mode       IN  VARCHAR2,
        p_batch_id   IN  NUMBER)
    IS
    BEGIN
        IF p_mode = 'NORMAL'
        THEN
            -- Get the actual shipment date from line interface table
            UPDATE oe_order_lines_all l
            SET (l.actual_shipment_date, l.schedule_ship_date, l.schedule_arrival_date, l.ordered_item,
                 l.fulfilled_flag, l.fulfilled_quantity, l.fulfillment_date, actual_fulfillment_date, l.drop_ship_flag,
                 l.source_type_code) =
                    (SELECT li.sas_sale_date,
                            li.aops_ship_date,
                            li.calc_arrival_date,
                            l.user_item_description,
                            'Y',
                            DECODE(NVL(l.shipped_quantity,
                                       0),
                                   0, l.ordered_quantity,
                                   l.shipped_quantity),
                            li.sas_sale_date,
                            SYSDATE,
                            oli.drop_ship_flag,
                            DECODE(oli.drop_ship_flag,
                                   'Y', 'EXTERNAL',
                                   'INTERNAL')
                     FROM   xx_om_lines_attr_iface_all li,
                            oe_lines_iface_all oli
                     WHERE  l.orig_sys_document_ref = li.orig_sys_document_ref
                     AND    l.orig_sys_line_ref = li.orig_sys_line_ref
                     AND    l.order_source_id = li.order_source_id
                     AND    li.orig_sys_document_ref = oli.orig_sys_document_ref
                     AND    li.orig_sys_line_ref = oli.orig_sys_line_ref
                     AND    li.order_source_id = oli.order_source_id)
            WHERE  l.header_id = p_header_id;
        ELSE
            -- Get the actual shipment date from line interface table
            UPDATE oe_order_lines_all l
            SET (l.actual_shipment_date, l.schedule_ship_date, l.schedule_arrival_date, l.ordered_item,
                 l.fulfilled_flag, l.fulfilled_quantity, l.fulfillment_date, actual_fulfillment_date, l.drop_ship_flag,
                 l.source_type_code) =
                    (SELECT li.sas_sale_date,
                            li.aops_ship_date,
                            li.calc_arrival_date,
                            l.user_item_description,
                            'Y',
                            DECODE(NVL(l.shipped_quantity,
                                       0),
                                   0, l.ordered_quantity,
                                   l.shipped_quantity),
                            li.sas_sale_date,
                            SYSDATE,
                            oli.drop_ship_flag,
                            DECODE(oli.drop_ship_flag,
                                   'Y', 'EXTERNAL',
                                   'INTERNAL')
                     FROM   xx_om_lines_attr_iface_all li,
                            oe_lines_iface_all oli
                     WHERE  l.orig_sys_document_ref = li.orig_sys_document_ref
                     AND    l.orig_sys_line_ref = li.orig_sys_line_ref
                     AND    l.order_source_id = li.order_source_id
                     AND    li.orig_sys_document_ref = oli.orig_sys_document_ref
                     AND    li.orig_sys_line_ref = oli.orig_sys_line_ref
                     AND    li.order_source_id = oli.order_source_id)
            WHERE  l.header_id IN(SELECT header_id
                                  FROM   oe_order_headers_all
                                  WHERE  batch_id = p_batch_id);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD('OTHERS ERROR , Update_Line_Attributes');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END update_line_attributes;

    PROCEDURE preprocess_payments(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        CURSOR c_payments
        IS
            SELECT   h.header_id,
                     i.payment_type_code,
                     i.credit_card_code,
                     i.credit_card_number,
                     i.credit_card_holder_name,
                     i.credit_card_expiration_date,
                     i.credit_card_approval_code,
                     i.credit_card_approval_date,
                     i.check_number,
                     i.prepaid_amount,
                     i.payment_amount,
                     i.orig_sys_payment_ref,
                     i.payment_number,
                     i.receipt_method_id,
                     h.transactional_curr_code,
                     h.sold_to_org_id,
                     h.invoice_to_org_id,
                     i.payment_set_id,
                     h.order_number,
                     i.CONTEXT,
                     i.attribute4,
                     i.attribute5,
                     i.attribute6,
                     i.attribute7,
                     i.attribute8,
                     i.attribute9,
                     i.attribute10,
                     i.attribute11,
                     i.attribute12,
                     i.attribute13,
                     NULL,
                     i.attribute15,
                     h.ship_from_org_id,
                     ha.paid_at_store_id,
                     h.orig_sys_document_ref,
                     (SELECT actual_shipment_date
                      FROM   oe_order_lines_all b
                      WHERE  h.header_id = b.header_id AND ROWNUM = 1),
                     i.payment_number,
                     i.trxn_extension_id,
                     i.attribute3,
                     i.attribute14,
                     i.attribute2,
                     i.attribute1
            FROM     oe_payments_iface_all i,
                     oe_order_headers h,
                     xx_om_header_attributes_all ha
            WHERE    h.header_id = p_header_id
            AND         h.orig_sys_document_ref
                     || '-BYPASS' = i.orig_sys_document_ref
            AND      h.order_source_id = i.order_source_id
            AND      h.header_id = ha.header_id
            ORDER BY h.header_id,
                     i.payment_number;

        ln_debug_level  CONSTANT NUMBER                                := oe_debug_pub.g_debug_level;
        lc_return_status         VARCHAR2(1);
        i                        BINARY_INTEGER;
        l_cash_receipt_rec       ar_cash_receipts%ROWTYPE;
        lc_payment_rec           xx_om_sacct_conc_pkg.payment_rec_type;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Entering  Preprocess_payments :'
                             || p_header_id);
        END IF;

        x_return_status := fnd_api.g_ret_sts_success;

        -- Check if the order has any tender records in oe_payments and bulk load them into
        OPEN c_payments;

        FETCH c_payments
        BULK COLLECT INTO lc_payment_rec.header_id,
               lc_payment_rec.payment_type_code,
               lc_payment_rec.credit_card_code,
               lc_payment_rec.credit_card_number,
               lc_payment_rec.credit_card_holder_name,
               lc_payment_rec.credit_card_expiration_date,
               lc_payment_rec.credit_card_approval_code,
               lc_payment_rec.credit_card_approval_date,
               lc_payment_rec.check_number,
               lc_payment_rec.prepaid_amount,
               lc_payment_rec.payment_amount,
               lc_payment_rec.orig_sys_payment_ref,
               lc_payment_rec.payment_number,
               lc_payment_rec.receipt_method_id,
               lc_payment_rec.order_curr_code,
               lc_payment_rec.sold_to_org_id,
               lc_payment_rec.invoice_to_org_id,
               lc_payment_rec.payment_set_id,
               lc_payment_rec.order_number,
               lc_payment_rec.CONTEXT,
               lc_payment_rec.credit_card_number_enc,
               lc_payment_rec.IDENTIFIER,
               lc_payment_rec.attribute6,
               lc_payment_rec.attribute7,
               lc_payment_rec.attribute8,
               lc_payment_rec.attribute9,
               lc_payment_rec.attribute10,
               lc_payment_rec.attribute11,
               lc_payment_rec.attribute12,
               lc_payment_rec.attribute13,
               lc_payment_rec.tangible_id,
               lc_payment_rec.attribute15,
               lc_payment_rec.ship_from_org_id,
               lc_payment_rec.paid_at_store_id,
               lc_payment_rec.orig_sys_document_ref,
               lc_payment_rec.receipt_date,
               lc_payment_rec.payment_number,
               lc_payment_rec.trxn_extension_id,
               lc_payment_rec.attribute3,
               lc_payment_rec.attribute14,
               lc_payment_rec.attribute2,
               lc_payment_rec.attribute1;

        CLOSE c_payments;

        IF lc_payment_rec.header_id.COUNT = 0
        THEN
            -- No records created for Account Billing
            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'No Eligible Payment records found :'
                                 || p_header_id);
            END IF;

            RETURN;
        END IF;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Calling Create_Receipt_payment ');
        END IF;

        -- Create receipts for the payment records
        create_receipt_payment(p_payment_rec        => lc_payment_rec,
                               p_request_id         => NULL,
                               p_run_mode           => 'SOI',
                               x_return_status      => lc_return_status);
        x_return_status := lc_return_status;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Returning from Preprocess_payments'
                             || x_return_status);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            oe_debug_pub.ADD('OTHERS ERROR , Preprocess_payments');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
            x_return_status := 'E';
    END preprocess_payments;

--Added by NB for R11.2
-- +=====================================================================+
-- | Name  :Get_payment_type                                             |
-- | Description  : This Function will return if it is a order or return |
-- |                tender                                               |
-- |                                                                     |
-- | Parameters :p_header_id IN NUMBER                                   |
-- |                                                                     |
-- +=====================================================================+
    FUNCTION get_payment_type(
        p_header_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_payment_type  VARCHAR2(30);
        ln_p_count       NUMBER;
        ln_r_count       NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   ln_p_count
        FROM   oe_payments
        WHERE  header_id = p_header_id AND ROWNUM <= 1;

        SELECT COUNT(*)
        INTO   ln_r_count
        FROM   xx_om_return_tenders_all
        WHERE  header_id = p_header_id AND ROWNUM <= 1;

        IF ln_p_count <> 0
        THEN
            lc_payment_type := 'ORDER';
        ELSIF ln_r_count <> 0
        THEN
            lc_payment_type := 'RETURN';
        ELSE
            lc_payment_type := NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN(NULL);
            oe_debug_pub.ADD('OTHERS ERROR , Get_payment_type');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END get_payment_type;

--Added by NB for R11.2
-- +=====================================================================+
-- | Name  :Get_Order_Source                                             |
-- | Description  : This Function will return order source name          |
-- |                                                                     |
-- |                                                                     |
-- | Parameters :p_header_id IN NUMBER                                   |
-- |                                                                     |
-- +=====================================================================+
    FUNCTION get_order_source(
        p_header_id  IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_order_source  oe_order_sources.NAME%TYPE;
    BEGIN
        SELECT NAME
        INTO   lc_order_source
        FROM   oe_order_headers_all h,
               oe_order_sources s
        WHERE  s.order_source_id = h.order_source_id AND h.header_id = p_header_id;

        RETURN(lc_order_source);
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN(NULL);
            oe_debug_pub.ADD('OTHERS ERROR , Get_Order_Source');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END get_order_source;

--Added by NB for R11.2
-- +=====================================================================+
-- | Name  :format_debit_card                                            |
-- | Description  : This Function will return Transacion Number          |
-- |                                                                     |
-- |                                                                     |
-- | Parameters :p_transaction_number IN VARCHAR2                        |
-- |            :p_cc_mask_number IN VARCHAR2                            |
-- |            :p_payment_amount IN VARCHAR2                            |
-- |                                                                     |
-- +=====================================================================+
    FUNCTION format_debit_card(
        p_transaction_number  IN  VARCHAR2,
        p_cc_mask_number      IN  VARCHAR2,
        p_payment_amount      IN  NUMBER)
        RETURN VARCHAR2
    IS
        lc_segment1                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment2                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment3                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment4                 VARCHAR2(50)  DEFAULT NULL;
        lc_segment5                 VARCHAR2(50)  DEFAULT NULL;
        lc_debit_card_approval_ref  VARCHAR2(250) DEFAULT NULL;
        ln_debug_level     CONSTANT NUMBER        := oe_debug_pub.g_debug_level;
    BEGIN
        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD('Build Debit Card Approval References');
            oe_debug_pub.ADD(   'POS Trans Number: '
                             || p_transaction_number);
            oe_debug_pub.ADD(   'CC Mask Number  : '
                             || p_cc_mask_number);
            oe_debug_pub.ADD(   'Payment Amount  : '
                             || p_payment_amount);
        END IF;

        lc_segment1 := LPAD(SUBSTR(p_transaction_number,
                                   1,
                                   4),
                            6,
                            '0');
        lc_segment2 := SUBSTR(p_transaction_number,
                              5,
                              8);
        lc_segment3 := '00';
        lc_segment4 := p_cc_mask_number;
-- ==========================================================================
-- format the payment amount as required by segment 5
-- ==========================================================================
        lc_segment5 := REPLACE(TO_CHAR(ABS(p_payment_amount),
                                       'fm999999999999999999999.00'),
                               '.');

        IF (LENGTH(lc_segment5) < 4)
        THEN
            lc_segment5 := LPAD(lc_segment5,
                                4,
                                '0');
        END IF;

        lc_segment5 := SUBSTR(lc_segment5,
                              -4);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Segment 1 (Store Num)    = '
                             || lc_segment1);
            oe_debug_pub.ADD(   'Segment 2 (Trans Date)   = '
                             || lc_segment2);
            oe_debug_pub.ADD(   'Segment 3 (Register Num) = '
                             || lc_segment3);
            oe_debug_pub.ADD(   'Segment 4 (CC Mask Num)  = '
                             || lc_segment4);
            oe_debug_pub.ADD(   'Segment 5 (Payment Amt)  = '
                             || lc_segment5);
        END IF;

-- ==========================================================================
-- build the approval reference from each of the segments
-- ==========================================================================
        lc_debit_card_approval_ref :=    lc_segment1
                                      || lc_segment2
                                      || lc_segment3
                                      || lc_segment4
                                      || lc_segment5;

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'Debit Card Approval Ref = '
                             || lc_debit_card_approval_ref);
        END IF;

        RETURN lc_debit_card_approval_ref;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN(NULL);
            oe_debug_pub.ADD('OTHERS ERROR , format_debit_card');
            oe_debug_pub.ADD(SUBSTR(SQLERRM,
                                    1,
                                    240));
    END format_debit_card;

--NB FOR R11.2
-- +=====================================================================+
-- | Name  :insert_into_recpt_tbl                                        |
-- | Description  : This Procedure will insert data to custom table      |
-- |                xx_ar_order_receipt_dtl                              |
-- |                                                                     |
-- |                                                                     |
-- | Parameters :p_header_id IN NUMBER                                   |
-- |            :p_batch_id  IN NUMBER                                   |
-- |            :p_mode      IN VARCHAR2                                 |
-- |            :x_return_status OUT VARCHAR2                            |
-- +=====================================================================+
    PROCEDURE insert_into_recpt_tbl(
        p_header_id      IN      NUMBER,
        p_batch_id       IN      NUMBER,
        p_mode           IN      VARCHAR2,
        x_return_status  OUT     VARCHAR2)
    IS
        CURSOR c_order(
            p_header_id  IN  NUMBER)
        IS
            SELECT xx_ar_order_payment_id_s.NEXTVAL order_payment_id,
                   ooh.order_number order_number,
                   ooh.orig_sys_document_ref orig_sys_document_ref,
                   ooh.header_id header_id,
                   ooh.transactional_curr_code currency_code,
                   oos.NAME order_source,
                   ott.NAME order_type,
                   ooh.sold_to_org_id customer_id,
                   LPAD(aou.attribute1,
                        6,
                        '0') store_num,
                   ooh.org_id org_id,
                   ooh.request_id request_id,
                   xoh.imp_file_name imp_file_name,
                   SYSDATE creation_date,
                   ooh.created_by created_by,
                   SYSDATE last_update_date,
                   ooh.created_by last_updated_by,
                   oop.payment_number payment_number,
                   oop.orig_sys_payment_ref orig_sys_payment_ref,
                   oop.payment_type_code payment_type_code,
                   flv.meaning cc_code,
                   oop.credit_card_number cc_number,
                   oop.credit_card_holder_name cc_name,
                   oop.credit_card_expiration_date cc_exp_date,
                   oop.payment_amount payment_amount,
                   oop.receipt_method_id receipt_method_id,
                   oop.check_number check_number,
                   oop.attribute4 cc_number_enc,
                   oop.attribute5 IDENTIFIER,
                   oop.attribute6 cc_auth_manual,
                   oop.attribute7 merchant_nbr,
                   oop.attribute8 cc_auth_ps2000,
                   oop.attribute9 allied_ind,
                   oop.attribute10 cc_mask_number,
                   oop.attribute11 od_payment_type,
                   oop.attribute15 cash_receipt_id,
                   oop.payment_set_id payment_set_id,
                   'HVOP' process_code,
                   'N' remitted,
                   'N' MATCHED,
                   'OPEN' receipt_status,
                   (SELECT LPAD(attribute1,
                                6,
                                '0')
                    FROM   hr_all_organization_units a
                    WHERE  a.organization_id = NVL(xoh.paid_at_store_id,
                                                   ship_from_org_id)) ship_from,
                   oop.credit_card_approval_code credit_card_approval_code,
                   oop.credit_card_approval_date credit_card_approval_date,
                   ooh.invoice_to_org_id customer_site_billto_id,
                   (SELECT TRUNC(actual_shipment_date)
                    FROM   oe_order_lines_all b
                    WHERE  ooh.header_id = b.header_id AND ROWNUM = 1) receipt_date,
                   'SALE' sale_type,
                   oop.attribute13 additional_auth_codes,
                   xfh.process_date process_date,
                   xoh.tran_number transaction_number,
                   xoh.external_transaction_number, 		--Changes for AMZ MPL
                   NVL(LTRIM(RTRIM(oop.attribute3)),'N') token_flag,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 1,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_card,
                   LTRIM(RTRIM(SUBSTR(oop.attribute14, 3,(INSTR(oop.attribute14,'.',1,1))))) emv_terminal,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 6,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_Transaction,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 8,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_offline,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 10,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_fallback,
                   LTRIM(RTRIM(SUBSTR(oop.attribute14, 12,10))) emv_tvr,
                   LTRIM(RTRIM(SUBSTR(oop.attribute2, 1,(INSTR(oop.attribute2,'.',1,1)-1)))) wallet_type,
                   LTRIM(RTRIM(SUBSTR(oop.attribute2, 3,3))) wallet_id
            FROM   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   oe_transaction_types_tl ott,
                   xx_om_header_attributes_all xoh,
                   xx_om_sacct_file_history xfh,
                   hr_all_organization_units aou,
                   oe_payments oop,
                   fnd_lookup_values flv,
                   ra_terms rt               -- Added table as per defect#33817 ver 20.0 
            WHERE  ooh.order_source_id = oos.order_source_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    ott.LANGUAGE = USERENV('LANG')
            AND    ooh.header_id = xoh.header_id
            AND    xoh.imp_file_name = xfh.file_name
            AND    ooh.ship_from_org_id = aou.organization_id
            AND    ooh.header_id = oop.header_id
            AND    oop.attribute11 = flv.lookup_code
            AND    flv.lookup_type = 'OD_PAYMENT_TYPES'
            AND    ooh.header_id = p_header_id
            -- AND ooh.batch_id  = p_batch_id
            AND    rt.name != 'SA_DEPOSIT'           --   Added as per defect#33817 ver 20.0 
            AND    rt.term_id = ooh.payment_Term_id  --   Added join as per defect#33817 ver 20.0 
            AND    NOT EXISTS(
                      /* SELECT 1
                       FROM   xx_om_legacy_deposits dep
                       WHERE  (dep.transaction_number = ooh.orig_sys_document_ref  -- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
                        OR (SUBSTR(dep.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9)  -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
                        AND NOT EXISTS (SELECT 1                         		    -- Added condition as per defect# 33817 ver 20.0
                                                        FROM XX_AR_INTSTORECUST_OTC OTC
                                                       WHERE ooh.sold_to_org_id = OTC.cust_account_id)
                                      )
                              )                                                 
                       AND    dep.cash_receipt_id IS NOT NULL
                       AND    ROWNUM < 2*/  -- commeted per defect 37178 12c defect
                        SELECT 1
                        FROM   XX_OM_LEGACY_DEPOSITS DEP
                        WHERE  SUBSTR (DEP.ORIG_SYS_DOCUMENT_REF, 1, 9) = SUBSTR (OOH.ORIG_SYS_DOCUMENT_REF, 1, 9)
                                AND NOT EXISTS (SELECT 1
                                                FROM   XX_AR_INTSTORECUST_OTC OTC
                                                WHERE  OOH.SOLD_TO_ORG_ID = OTC.CUST_ACCOUNT_ID)
                         AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                         AND    ROWNUM < 2
                         UNION
                         SELECT 1
                         FROM   XX_OM_LEGACY_DEPOSITS DEP
                         WHERE  DEP.TRANSACTION_NUMBER = OOH.ORIG_SYS_DOCUMENT_REF
                         AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                         AND    ROWNUM < 2
                         UNION
                         SELECT 1
                         FROM   xx_om_legacy_dep_dtls DDL
                         WHERE  ( ddl.transaction_number = ooh.orig_sys_document_ref   	-- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
                                    OR   ddl.orig_sys_Document_ref = ooh.orig_sys_document_ref )	-- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
                           --SUBSTR(DDL.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9) -- Commented as per defect# 33817 ver 20.0
                           --AND    LENGTH(DDL.orig_sys_document_ref) <= 12                                -- Commented as per defect# 33817 ver 20.0
                           AND    ROWNUM < 2
                         );         
                        --     UNION                                         				    -- Commented as per defect# 33817 ver 20.0
                        --    SELECT 1								    -- Commented as per defect# 33817 ver 20.0
                        --    FROM   xx_om_legacy_dep_dtls DDL		 			    -- Commented as per defect# 33817 ver 20.0
                        --   WHERE  DDL.transaction_number = ooh.orig_sys_document_ref AND ROWNUM < 2);   -- Commented as per defect# 33817 ver 20.0
                    
        CURSOR c_batch_order(
            p_batch_id  IN  NUMBER)
        IS
            SELECT xx_ar_order_payment_id_s.NEXTVAL order_payment_id,
                   ooh.order_number order_number,
                   ooh.orig_sys_document_ref orig_sys_document_ref,
                   ooh.header_id header_id,
                   ooh.transactional_curr_code currency_code,
                   oos.NAME order_source,
                   ott.NAME order_type,
                   ooh.sold_to_org_id customer_id,
                   LPAD(aou.attribute1,
                        6,
                        '0') store_num,
                   ooh.org_id org_id,
                   ooh.request_id request_id,
                   xoh.imp_file_name imp_file_name,
                   SYSDATE creation_date,
                   ooh.created_by created_by,
                   SYSDATE last_update_date,
                   ooh.created_by last_updated_by,
                   oop.payment_number payment_number,
                   oop.orig_sys_payment_ref orig_sys_payment_ref,
                   oop.payment_type_code payment_type_code,
                   flv.meaning cc_code,
                   oop.credit_card_number cc_number,
                   oop.credit_card_holder_name cc_name,
                   oop.credit_card_expiration_date cc_exp_date,
                   oop.payment_amount payment_amount,
                   oop.receipt_method_id receipt_method_id,
                   oop.check_number check_number,
                   oop.attribute4 cc_number_enc,
                   oop.attribute5 IDENTIFIER,
                   oop.attribute6 cc_auth_manual,
                   oop.attribute7 merchant_nbr,
                   oop.attribute8 cc_auth_ps2000,
                   oop.attribute9 allied_ind,
                   oop.attribute10 cc_mask_number,
                   oop.attribute11 od_payment_type,
                   oop.attribute15 cash_receipt_id,
                   oop.payment_set_id payment_set_id,
                   'HVOP' process_code,
                   'N' remitted,
                   'N' MATCHED,
                   'OPEN' receipt_status,
                   (SELECT LPAD(attribute1,
                                6,
                                '0')
                    FROM   hr_all_organization_units a
                    WHERE  a.organization_id = NVL(xoh.paid_at_store_id,
                                                   ship_from_org_id)) ship_from,
                   NULL customer_receipt_number,
                   NULL receipt_number,
                   oop.credit_card_approval_code credit_card_approval_code,
                   oop.credit_card_approval_date credit_card_approval_date,
                   ooh.invoice_to_org_id customer_site_billto_id,
                   (SELECT TRUNC(actual_shipment_date)
                    FROM   oe_order_lines_all b
                    WHERE  ooh.header_id = b.header_id AND ROWNUM = 1) receipt_date,
                   'SALE' sale_type,
                   oop.attribute13 additional_auth_codes,
                   xfh.process_date process_date,
                   xoh.tran_number transaction_number,
                   xoh.external_transaction_number,
                   NVL(LTRIM(RTRIM(oop.attribute3)),'N') token_flag,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 1,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_card,
                   LTRIM(RTRIM(SUBSTR(oop.attribute14, 3,(INSTR(oop.attribute14,'.',1,1)))))  emv_terminal,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 6,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_Transaction,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 8,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_offline,
                   NVL(LTRIM(RTRIM(SUBSTR(oop.attribute14, 10,(INSTR(oop.attribute14,'.',1,1)-1)))),'N') emv_fallback,
                   LTRIM(RTRIM(SUBSTR(oop.attribute14, 12,10))) emv_tvr,
                   LTRIM(RTRIM(SUBSTR(oop.attribute2, 1,(INSTR(oop.attribute2,'.',1,1)-1)))) wallet_type,
                   LTRIM(RTRIM(SUBSTR(oop.attribute2, 3,3))) wallet_id
            FROM   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   oe_transaction_types_tl ott,
                   xx_om_header_attributes_all xoh,
                   xx_om_sacct_file_history xfh,
                   hr_all_organization_units aou,
                   oe_payments oop,
                   fnd_lookup_values flv,
                   ra_terms rt               -- Added table as per defect#33817 ver 20.0 
            WHERE  ooh.order_source_id = oos.order_source_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    ott.LANGUAGE = USERENV('LANG')
            AND    ooh.header_id = xoh.header_id
            AND    xoh.imp_file_name = xfh.file_name
            AND    ooh.ship_from_org_id = aou.organization_id
            AND    ooh.header_id = oop.header_id
            AND    oop.attribute11 = flv.lookup_code
            AND    flv.lookup_type = 'OD_PAYMENT_TYPES'
            -- AND ooh.header_id = p_header_id
            AND    ooh.batch_id = p_batch_id
            AND    rt.name != 'SA_DEPOSIT'           --   Added as per defect#33817 ver 20.0 
            AND    rt.term_id = ooh.payment_Term_id  --   Added join as per defect#33817 ver 20.0 
            AND    NOT EXISTS(
                      /* SELECT 1
                       FROM   xx_om_legacy_deposits dep
                       WHERE   (dep.transaction_number = ooh.orig_sys_document_ref -- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
                        OR (SUBSTR(dep.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9) -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
                        AND NOT EXISTS (SELECT 1                        	  -- Added condition as per defect# 33817 ver 20.0
                                                        FROM XX_AR_INTSTORECUST_OTC OTC
                                                       WHERE ooh.sold_to_org_id = OTC.cust_account_id)
                                      )
                              )     
                       AND    dep.cash_receipt_id IS NOT NULL
                       AND    ROWNUM < 2 */ -- commeted per defect 37178 12c defect
                       SELECT 1
                       FROM   XX_OM_LEGACY_DEPOSITS DEP
                       WHERE  SUBSTR (DEP.ORIG_SYS_DOCUMENT_REF, 1, 9) = SUBSTR (OOH.ORIG_SYS_DOCUMENT_REF, 1, 9)
                              AND NOT EXISTS (SELECT 1
                                              FROM   XX_AR_INTSTORECUST_OTC OTC
                                              WHERE  OOH.SOLD_TO_ORG_ID = OTC.CUST_ACCOUNT_ID)
                       AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                       AND    ROWNUM < 2
                       UNION
                       SELECT 1
                       FROM   XX_OM_LEGACY_DEPOSITS DEP
                       WHERE  DEP.TRANSACTION_NUMBER = OOH.ORIG_SYS_DOCUMENT_REF
                       AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                       AND    ROWNUM < 2
                       UNION
		       SELECT 1
		       FROM   xx_om_legacy_dep_dtls DDL
		       WHERE  ( ddl.transaction_number = ooh.orig_sys_document_ref   	 -- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
		        OR   ddl.orig_sys_Document_ref = ooh.orig_sys_document_ref )	 -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
		       --SUBSTR(DDL.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9) -- Commented as per defect# 33817 ver 20.0
		       --AND    LENGTH(DDL.orig_sys_document_ref) <= 12                                -- Commented as per defect# 33817 ver 20.0
		       AND    ROWNUM < 2
		            );         
		    -- UNION                                         		      -- Commented as per defect# 33817 ver 20.0
	            -- SELECT 1							      -- Commented as per defect# 33817 ver 20.0
	            -- FROM   xx_om_legacy_dep_dtls DDL		 		      -- Commented as per defect# 33817 ver 20.0
                    -- WHERE  DDL.transaction_number = ooh.orig_sys_document_ref AND ROWNUM < 2); -- Commented as per defect# 33817 ver 20.0

        TYPE batch_order_type IS TABLE OF c_batch_order%ROWTYPE;

        batch_order_array           batch_order_type;
        order_rec                   batch_order_type;
        lc_order_receipt_rec        xx_om_sacct_conc_pkg.order_receipt_type;
        ln_debug_level     CONSTANT NUMBER                                  := oe_debug_pub.g_debug_level;
        lc_customer_receipt_number  VARCHAR2(80);
        lc_tender_type              VARCHAR2(80);
        lc_receipt_number           VARCHAR2(80);
        j                           BINARY_INTEGER                          := 0;
        ln_start_time               NUMBER;
        ln_end_time                 NUMBER;
        lc_receipt_status           VARCHAR2(30);
        ld_cleared_date             DATE;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                          'Begining of insert_into_recpt_tbl Procedure');
        x_return_status := fnd_api.g_ret_sts_success;

        SELECT hsecs
        INTO   ln_start_time
        FROM   v$timer;

        IF p_mode = 'HVOP'
        THEN
            x_return_status := fnd_api.g_ret_sts_success;

            OPEN c_batch_order(p_batch_id);

            LOOP
                FETCH c_batch_order
                BULK COLLECT INTO batch_order_array LIMIT 100;

                FOR i IN 1 .. batch_order_array.COUNT
                LOOP
                    j :=   j
                         + 1;
                    /*          initialize record type                          */
                    lc_order_receipt_rec.order_payment_id(j) := NULL;
                    lc_order_receipt_rec.order_number(j) := NULL;
                    lc_order_receipt_rec.orig_sys_document_ref(j) := NULL;
                    lc_order_receipt_rec.orig_sys_payment_ref(j) := NULL;
                    lc_order_receipt_rec.payment_number(j) := NULL;
                    lc_order_receipt_rec.header_id(j) := NULL;
                    lc_order_receipt_rec.currency_code(j) := NULL;
                    lc_order_receipt_rec.order_source(j) := NULL;
                    lc_order_receipt_rec.order_type(j) := NULL;
                    lc_order_receipt_rec.cash_receipt_id(j) := NULL;
                    lc_order_receipt_rec.receipt_number(j) := NULL;
                    lc_order_receipt_rec.customer_id(j) := NULL;
                    lc_order_receipt_rec.store_number(j) := NULL;
                    lc_order_receipt_rec.payment_type_code(j) := NULL;
                    lc_order_receipt_rec.credit_card_code(j) := NULL;
                    lc_order_receipt_rec.credit_card_number(j) := NULL;
                    lc_order_receipt_rec.IDENTIFIER(j) := NULL;
                    lc_order_receipt_rec.credit_card_holder_name(j) := NULL;
                    lc_order_receipt_rec.credit_card_expiration_date(j) := NULL;
                    lc_order_receipt_rec.payment_amount(j) := NULL;
                    lc_order_receipt_rec.receipt_method_id(j) := NULL;
                    lc_order_receipt_rec.cc_auth_manual(j) := NULL;
                    lc_order_receipt_rec.merchant_number(j) := NULL;
                    lc_order_receipt_rec.cc_auth_ps2000(j) := NULL;
                    lc_order_receipt_rec.allied_ind(j) := NULL;
                    lc_order_receipt_rec.payment_set_id(j) := NULL;
                    lc_order_receipt_rec.process_code(j) := NULL;
                    lc_order_receipt_rec.cc_mask_number(j) := NULL;
                    lc_order_receipt_rec.od_payment_type(j) := NULL;
                    lc_order_receipt_rec.check_number(j) := NULL;
                    lc_order_receipt_rec.org_id(j) := NULL;
                    lc_order_receipt_rec.request_id(j) := NULL;
                    lc_order_receipt_rec.imp_file_name(j) := NULL;
                    lc_order_receipt_rec.creation_date(j) := NULL;
                    lc_order_receipt_rec.created_by(j) := NULL;
                    lc_order_receipt_rec.last_update_date(j) := NULL;
                    lc_order_receipt_rec.last_updated_by(j) := NULL;
                    lc_order_receipt_rec.last_update_login(j) := NULL;
                    lc_order_receipt_rec.remitted(j) := NULL;
                    lc_order_receipt_rec.MATCHED(j) := NULL;
                    lc_order_receipt_rec.ship_from(j) := NULL;
                    lc_order_receipt_rec.receipt_status(j) := NULL;
                    lc_order_receipt_rec.customer_receipt_reference(j) := NULL;
                    lc_order_receipt_rec.credit_card_approval_code(j) := NULL;
                    lc_order_receipt_rec.credit_card_approval_date(j) := NULL;
                    lc_order_receipt_rec.customer_site_billto_id(j) := NULL;
                    lc_order_receipt_rec.receipt_date(j) := NULL;
                    lc_order_receipt_rec.sale_type(j) := NULL;
                    lc_order_receipt_rec.additional_auth_codes(j) := NULL;
                    lc_order_receipt_rec.process_date(j) := NULL;
                    lc_order_receipt_rec.single_pay_ind(j) := NULL;
                    lc_order_receipt_rec.cleared_date(j) := NULL;
                    lc_order_receipt_rec.mpl_order_id(j) := NULL;

                    lc_order_receipt_rec.token_flag(j)  := NULL;
                    lc_order_receipt_rec.emv_card(j)    := NULL;
                    lc_order_receipt_rec.emv_terminal(j) := NULL;
                    lc_order_receipt_rec.emv_transaction(j) := NULL;
                    lc_order_receipt_rec.emv_offline(j)   := NULL;
                    lc_order_receipt_rec.emv_fallback(j)  := NULL;
                    lc_order_receipt_rec.emv_tvr(j) := NULL;
                    lc_order_receipt_rec.wallet_type(j) := NULL;
                    lc_order_receipt_rec.wallet_id(j) := NULL;

                    --dbms_output.put_line('BEGIN of LOOP BATCH PROCESS '||batch_order_array(i).order_number );
                    IF batch_order_array(i).cc_code = 'DEBIT CARD'
                    THEN
                        IF batch_order_array(i).order_source IN('SPC', 'PRO')
                        THEN
                            batch_order_array(i).customer_receipt_number :=
                                format_debit_card(batch_order_array(i).transaction_number,
                                                  batch_order_array(i).cc_mask_number,
                                                  batch_order_array(i).payment_amount);
                        ELSE
                            batch_order_array(i).customer_receipt_number :=
                                format_debit_card(batch_order_array(i).orig_sys_document_ref,
                                                  batch_order_array(i).cc_mask_number,
                                                  batch_order_array(i).payment_amount);
                        END IF;
                    ELSIF batch_order_array(i).cc_code = 'TELECHECK ECA'
                    THEN
                        IF batch_order_array(i).order_source IN('SPC', 'PRO')
                        THEN
                            batch_order_array(i).customer_receipt_number :=
                                   SUBSTR(batch_order_array(i).transaction_number,
                                          1,
                                          12)
                                || '00'
                                || SUBSTR(batch_order_array(i).orig_sys_document_ref,
                                          13);
                        ELSE
                            batch_order_array(i).customer_receipt_number :=
                                   SUBSTR(batch_order_array(i).orig_sys_document_ref,
                                          1,
                                          12)
                                || '00'
                                || SUBSTR(batch_order_array(i).orig_sys_document_ref,
                                          13);
                        END IF;
                    ELSE
                        batch_order_array(i).customer_receipt_number := batch_order_array(i).orig_sys_document_ref;
                    END IF;

                    --dbms_output.put_line('batch_order_array(i).customer_receipt_number '||batch_order_array(i).customer_receipt_number);
                    IF batch_order_array(i).cash_receipt_id IS NOT NULL
                    THEN
                        SELECT receipt_number
                        INTO   batch_order_array(i).receipt_number
                        FROM   ar_cash_receipts_all
                        WHERE  cash_receipt_id = batch_order_array(i).cash_receipt_id;
                    ELSE
                        batch_order_array(i).cash_receipt_id := -3;
                        batch_order_array(i).receipt_number := NULL;
                    END IF;

                    /*IF batch_order_array(i).cc_code IN
                           ('DEBIT CARD',
                            'TELECHECK ECA',
                            'CASH',
                            'TELECHECK PAPER',
                            'GIFT CERTIFICATE',
                            'OD MONEY CARD2',
                            'OD MONEY CARD3',
                            'PAYPAL',
                            'AMAZON',
							'AMAZON_4S', --Added for Defect# 44321
                            'EBAY',
							'WALMART',
							'RAKUTEN',
							'NEWEGG',
							'CHECK')	--For Defect# 36125
                    THEN
                        batch_order_array(i).remitted := 'Y';
                    ELSE
                        batch_order_array(i).remitted := 'N';
                    END IF;*/
					
					IF check_cc_code(batch_order_array(i).cc_code)
                    THEN
                        batch_order_array(i).remitted := 'Y';
                    ELSE
                        batch_order_array(i).remitted := 'N';
                    END IF;

                    lc_order_receipt_rec.order_payment_id(j) := batch_order_array(i).order_payment_id;
                    lc_order_receipt_rec.order_number(j) := batch_order_array(i).order_number;
                    lc_order_receipt_rec.orig_sys_document_ref(j) := batch_order_array(i).orig_sys_document_ref;
                    lc_order_receipt_rec.orig_sys_payment_ref(j) := batch_order_array(i).orig_sys_payment_ref;
                    lc_order_receipt_rec.payment_number(j) := batch_order_array(i).payment_number;
                    lc_order_receipt_rec.header_id(j) := batch_order_array(i).header_id;
                    lc_order_receipt_rec.currency_code(j) := batch_order_array(i).currency_code;
                    lc_order_receipt_rec.order_source(j) := batch_order_array(i).order_source;
                    lc_order_receipt_rec.order_type(j) := batch_order_array(i).order_type;
                    lc_order_receipt_rec.cash_receipt_id(j) := batch_order_array(i).cash_receipt_id;
                    lc_order_receipt_rec.receipt_number(j) := batch_order_array(i).receipt_number;
                    lc_order_receipt_rec.customer_id(j) := batch_order_array(i).customer_id;
                    lc_order_receipt_rec.store_number(j) := batch_order_array(i).store_num;
                    lc_order_receipt_rec.payment_type_code(j) := batch_order_array(i).payment_type_code;
                    lc_order_receipt_rec.credit_card_code(j) := batch_order_array(i).cc_code;
                    lc_order_receipt_rec.credit_card_number(j) := batch_order_array(i).cc_number_enc;
                    lc_order_receipt_rec.IDENTIFIER(j) := batch_order_array(i).IDENTIFIER;
                    lc_order_receipt_rec.credit_card_holder_name(j) := batch_order_array(i).cc_name;
                    lc_order_receipt_rec.credit_card_expiration_date(j) := batch_order_array(i).cc_exp_date;
                    lc_order_receipt_rec.payment_amount(j) := batch_order_array(i).payment_amount;
                    lc_order_receipt_rec.receipt_method_id(j) := batch_order_array(i).receipt_method_id;
                    lc_order_receipt_rec.cc_auth_manual(j) := batch_order_array(i).cc_auth_manual;
                    lc_order_receipt_rec.merchant_number(j) := batch_order_array(i).merchant_nbr;
                    lc_order_receipt_rec.cc_auth_ps2000(j) := batch_order_array(i).cc_auth_ps2000;
                    lc_order_receipt_rec.allied_ind(j) := batch_order_array(i).allied_ind;
                    lc_order_receipt_rec.payment_set_id(j) := batch_order_array(i).payment_set_id;
                    lc_order_receipt_rec.process_code(j) := batch_order_array(i).process_code;
                    lc_order_receipt_rec.cc_mask_number(j) := batch_order_array(i).cc_mask_number;
                    lc_order_receipt_rec.od_payment_type(j) := batch_order_array(i).od_payment_type;
                    lc_order_receipt_rec.check_number(j) := batch_order_array(i).check_number;
                    lc_order_receipt_rec.org_id(j) := batch_order_array(i).org_id;
                    lc_order_receipt_rec.request_id(j) := batch_order_array(i).request_id;
                    lc_order_receipt_rec.imp_file_name(j) := batch_order_array(i).imp_file_name;
                    lc_order_receipt_rec.creation_date(j) := batch_order_array(i).creation_date;
                    lc_order_receipt_rec.created_by(j) := batch_order_array(i).created_by;
                    lc_order_receipt_rec.last_update_date(j) := batch_order_array(i).last_update_date;
                    lc_order_receipt_rec.last_updated_by(j) := batch_order_array(i).last_updated_by;
                    lc_order_receipt_rec.remitted(j) := batch_order_array(i).remitted;
                    lc_order_receipt_rec.MATCHED(j) := batch_order_array(i).MATCHED;
                    lc_order_receipt_rec.ship_from(j) := batch_order_array(i).ship_from;
                    lc_order_receipt_rec.receipt_status(j) := batch_order_array(i).receipt_status;
                    lc_order_receipt_rec.customer_receipt_reference(j) := batch_order_array(i).customer_receipt_number;
                    lc_order_receipt_rec.credit_card_approval_code(j) := batch_order_array(i).credit_card_approval_code;
                    lc_order_receipt_rec.credit_card_approval_date(j) := batch_order_array(i).credit_card_approval_date;
                    lc_order_receipt_rec.customer_site_billto_id(j) := batch_order_array(i).customer_site_billto_id;
                    lc_order_receipt_rec.receipt_date(j) := batch_order_array(i).receipt_date;
                    lc_order_receipt_rec.sale_type(j) := batch_order_array(i).sale_type;
                    lc_order_receipt_rec.additional_auth_codes(j) := batch_order_array(i).additional_auth_codes;
                    lc_order_receipt_rec.process_date(j) := batch_order_array(i).process_date;
                    lc_order_receipt_rec.mpl_order_id(j) := batch_order_array(i).external_transaction_number;		--AB Changes for AMZ MPL
                    lc_order_receipt_rec.token_flag(j)   := batch_order_array(i).token_flag;
                    lc_order_receipt_rec.emv_card(j)     := batch_order_array(i).emv_card;
                    lc_order_receipt_rec.emv_terminal(j) := batch_order_array(i).emv_terminal;
                    lc_order_receipt_rec.emv_transaction(j) := batch_order_array(i).emv_transaction;
                    lc_order_receipt_rec.emv_offline(j)     := batch_order_array(i).emv_offline;
                    lc_order_receipt_rec.emv_fallback(j)    := batch_order_array(i).emv_fallback;
                    lc_order_receipt_rec.emv_tvr(j)         := batch_order_array(i).emv_tvr;
                    lc_order_receipt_rec.wallet_type(j)     := batch_order_array(i).wallet_type;
                    lc_order_receipt_rec.wallet_id(j)       := batch_order_array(i).wallet_id;

                    IF lc_order_receipt_rec.credit_card_code(j) IN
                                                       ('CASH', 'TELECHECK PAPER', 'GIFT CERTIFICATE', 'OD MONEY CARD2','OD MONEY CARD3','CHECK') 
                    THEN										--Added check for defect# 36125
                        lc_order_receipt_rec.MATCHED(j) := 'Y';
                        lc_order_receipt_rec.receipt_status(j) := 'CLEARED';
                        lc_order_receipt_rec.cleared_date(j) := SYSDATE;
                    ELSE
                        lc_order_receipt_rec.MATCHED(j) := 'N';
                        lc_order_receipt_rec.cleared_date(j) := NULL;
                    END IF;

                    IF ln_debug_level > 0
                    THEN
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.order_payment_id(j)           = '
                                         || lc_order_receipt_rec.order_payment_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.order_number(j)               = '
                                         || lc_order_receipt_rec.order_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.orig_sys_document_ref(j)      = '
                                         || lc_order_receipt_rec.orig_sys_document_ref(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.orig_sys_payment_ref(j)       = '
                                         || lc_order_receipt_rec.orig_sys_payment_ref(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.payment_number(j)             = '
                                         || lc_order_receipt_rec.payment_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.header_id(j)                  = '
                                         || lc_order_receipt_rec.header_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.currency_code(j)              = '
                                         || lc_order_receipt_rec.currency_code(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.order_source(j)               = '
                                         || lc_order_receipt_rec.order_source(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.order_type(j)                 = '
                                         || lc_order_receipt_rec.order_type(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.cash_receipt_id(j)            = '
                                         || lc_order_receipt_rec.cash_receipt_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.receipt_number(j)             = '
                                         || lc_order_receipt_rec.receipt_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.customer_id(j)                = '
                                         || lc_order_receipt_rec.customer_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.store_number(j)               = '
                                         || lc_order_receipt_rec.store_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.payment_type_code(j)          = '
                                         || lc_order_receipt_rec.payment_type_code(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.credit_card_code(j)           = '
                                         || lc_order_receipt_rec.credit_card_code(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.credit_card_number(j)         = '
                                         || lc_order_receipt_rec.credit_card_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.credit_card_holder_name(j)    = '
                                         || lc_order_receipt_rec.credit_card_holder_name(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.credit_card_expiration_date(j)= '
                                         || lc_order_receipt_rec.credit_card_expiration_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.payment_amount(j)             = '
                                         || lc_order_receipt_rec.payment_amount(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.receipt_method_id(j)          = '
                                         || lc_order_receipt_rec.receipt_method_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.cc_auth_manual(j)             = '
                                         || lc_order_receipt_rec.cc_auth_manual(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.merchant_number(j)            = '
                                         || lc_order_receipt_rec.merchant_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.cc_auth_ps2000(j)             = '
                                         || lc_order_receipt_rec.cc_auth_ps2000(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.allied_ind(j)                 = '
                                         || lc_order_receipt_rec.allied_ind(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.payment_set_id(j)             = '
                                         || lc_order_receipt_rec.payment_set_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.process_code(j)               = '
                                         || lc_order_receipt_rec.process_code(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.cc_mask_number(j)             = '
                                         || lc_order_receipt_rec.cc_mask_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.od_payment_type(j)            = '
                                         || lc_order_receipt_rec.od_payment_type(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.check_number(j)               = '
                                         || lc_order_receipt_rec.check_number(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.org_id(j)                     = '
                                         || lc_order_receipt_rec.org_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.request_id(j)                 = '
                                         || lc_order_receipt_rec.request_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.imp_file_name(j)              = '
                                         || lc_order_receipt_rec.imp_file_name(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.creation_date(j)              = '
                                         || lc_order_receipt_rec.creation_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.created_by(j)                 = '
                                         || lc_order_receipt_rec.created_by(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.last_update_date(j)           = '
                                         || lc_order_receipt_rec.last_update_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.last_updated_by(j)            = '
                                         || lc_order_receipt_rec.last_updated_by(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.remitted(j)                   = '
                                         || lc_order_receipt_rec.remitted(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.matched(j)                    = '
                                         || lc_order_receipt_rec.MATCHED(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.ship_from(j)                  = '
                                         || lc_order_receipt_rec.ship_from(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.receipt_status(j)             = '
                                         || lc_order_receipt_rec.receipt_status(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.customer_receipt_reference(j) = '
                                         || lc_order_receipt_rec.customer_receipt_reference(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.credit_card_approval_code(j)  = '
                                         || lc_order_receipt_rec.credit_card_approval_code(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.credit_card_approval_date(j)  = '
                                         || lc_order_receipt_rec.credit_card_approval_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.customer_site_billto_id(j)    = '
                                         || lc_order_receipt_rec.customer_site_billto_id(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.receipt_date(j)               = '
                                         || lc_order_receipt_rec.receipt_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.sale_type(j)                  = '
                                         || lc_order_receipt_rec.sale_type(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.additional_auth_codes(j)      = '
                                         || lc_order_receipt_rec.additional_auth_codes(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.process_date(j)               = '
                                         || lc_order_receipt_rec.process_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.cleared_date(j)               = '
                                         || lc_order_receipt_rec.cleared_date(j));
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.mpl_order_id(j)               = '   --AB Changes for AMZ MPL
                                         || lc_order_receipt_rec.mpl_order_id(j));                                         
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.token_flag  (j)               = '   
                                         || lc_order_receipt_rec.token_flag(j));                        
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.emv_card(j)                   = '   
                                         || lc_order_receipt_rec.emv_card(j));                        
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.emv_terminal(j)               = '   
                                         || lc_order_receipt_rec.emv_terminal(j));                        
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.emv_transaction(j)            = '   
                                         || lc_order_receipt_rec.emv_transaction(j));                        
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.emv_offline(j)                = '   
                                         || lc_order_receipt_rec.emv_offline(j));                        
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.emv_fallback(j)               = '   
                                         || lc_order_receipt_rec.emv_fallback(j));                        
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.emv_tvr(j)                    = '   
                                         || lc_order_receipt_rec.emv_tvr(j));           
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.wallet_type(j)                    = '   
                                         || lc_order_receipt_rec.wallet_type(j)); 
                        oe_debug_pub.ADD(   'lc_order_receipt_rec.wallet_id(j)                    = '   
                                         || lc_order_receipt_rec.wallet_id(j));           
          
                    END IF;
                END LOOP;

                EXIT WHEN c_batch_order%NOTFOUND;
            END LOOP;

            CLOSE c_batch_order;

            oe_debug_pub.ADD(   'TOTAL COUNT'
                             || TO_CHAR(lc_order_receipt_rec.order_payment_id.COUNT));

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'TOTAL COUNT'
                                 || TO_CHAR(lc_order_receipt_rec.order_payment_id.COUNT));
            END IF;

            FORALL i_ord IN lc_order_receipt_rec.order_payment_id.FIRST .. lc_order_receipt_rec.order_payment_id.LAST
                INSERT INTO xx_ar_order_receipt_dtl
                            (order_payment_id,
                             order_number,
                             orig_sys_document_ref,
                             header_id,
                             order_source,
                             order_type,
                             customer_id,
                             store_number,
                             org_id,
                             request_id,
                             imp_file_name,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             payment_number,
                             orig_sys_payment_ref,
                             payment_type_code,
                             credit_card_code,
                             credit_card_number,
                             IDENTIFIER,
                             credit_card_holder_name,
                             credit_card_expiration_date,
                             payment_amount,
                             receipt_method_id,
                             check_number,
                             cc_auth_manual,
                             merchant_number,
                             cc_auth_ps2000,
                             allied_ind,
                             cc_mask_number,
                             od_payment_type,
                             cash_receipt_id,
                             payment_set_id,
                             process_code,
                             remitted,
                             MATCHED,
                             receipt_status,
                             ship_from,
                             customer_receipt_reference,
                             receipt_number,
                             credit_card_approval_code,
                             credit_card_approval_date,
                             customer_site_billto_id,
                             receipt_date,
                             sale_type,
                             additional_auth_codes,
                             process_date,
                             currency_code,
                             single_pay_ind,
                             last_update_login,
                             cleared_date,
                             mpl_order_id,
                             token_flag,
                             emv_card,
                             emv_terminal,
                             emv_transaction,
                             emv_offline,
                             emv_fallback,
                             emv_tvr,
                             wallet_type,
                             wallet_id)
                     VALUES (lc_order_receipt_rec.order_payment_id(i_ord),
                             lc_order_receipt_rec.order_number(i_ord),
                             lc_order_receipt_rec.orig_sys_document_ref(i_ord),
                             lc_order_receipt_rec.header_id(i_ord),
                             lc_order_receipt_rec.order_source(i_ord),
                             lc_order_receipt_rec.order_type(i_ord),
                             lc_order_receipt_rec.customer_id(i_ord),
                             lc_order_receipt_rec.store_number(i_ord),
                             lc_order_receipt_rec.org_id(i_ord),
                             lc_order_receipt_rec.request_id(i_ord),
                             lc_order_receipt_rec.imp_file_name(i_ord),
                             lc_order_receipt_rec.creation_date(i_ord),
                             lc_order_receipt_rec.created_by(i_ord),
                             lc_order_receipt_rec.last_update_date(i_ord),
                             lc_order_receipt_rec.last_updated_by(i_ord),
                             lc_order_receipt_rec.payment_number(i_ord),
                             lc_order_receipt_rec.orig_sys_payment_ref(i_ord),
                             lc_order_receipt_rec.payment_type_code(i_ord),
                             lc_order_receipt_rec.credit_card_code(i_ord),
                             lc_order_receipt_rec.credit_card_number(i_ord),
                             lc_order_receipt_rec.IDENTIFIER(i_ord),
                             lc_order_receipt_rec.credit_card_holder_name(i_ord),
                             lc_order_receipt_rec.credit_card_expiration_date(i_ord),
                             lc_order_receipt_rec.payment_amount(i_ord),
                             lc_order_receipt_rec.receipt_method_id(i_ord),
                             lc_order_receipt_rec.check_number(i_ord),
                             lc_order_receipt_rec.cc_auth_manual(i_ord),
                             lc_order_receipt_rec.merchant_number(i_ord),
                             lc_order_receipt_rec.cc_auth_ps2000(i_ord),
                             lc_order_receipt_rec.allied_ind(i_ord),
                             lc_order_receipt_rec.cc_mask_number(i_ord),
                             lc_order_receipt_rec.od_payment_type(i_ord),
                             lc_order_receipt_rec.cash_receipt_id(i_ord),
                             lc_order_receipt_rec.payment_set_id(i_ord),
                             lc_order_receipt_rec.process_code(i_ord),
                             lc_order_receipt_rec.remitted(i_ord),
                             lc_order_receipt_rec.MATCHED(i_ord),
                             lc_order_receipt_rec.receipt_status(i_ord),
                             lc_order_receipt_rec.ship_from(i_ord),
                             lc_order_receipt_rec.customer_receipt_reference(i_ord),
                             lc_order_receipt_rec.receipt_number(i_ord),
                             lc_order_receipt_rec.credit_card_approval_code(i_ord),
                             lc_order_receipt_rec.credit_card_approval_date(i_ord),
                             lc_order_receipt_rec.customer_site_billto_id(i_ord),
                             lc_order_receipt_rec.receipt_date(i_ord),
                             lc_order_receipt_rec.sale_type(i_ord),
                             lc_order_receipt_rec.additional_auth_codes(i_ord),
                             lc_order_receipt_rec.process_date(i_ord),
                             lc_order_receipt_rec.currency_code(i_ord),
                             lc_order_receipt_rec.single_pay_ind(i_ord),
                             lc_order_receipt_rec.last_update_login(i_ord),
                             lc_order_receipt_rec.cleared_date(i_ord),
                             lc_order_receipt_rec.mpl_order_id(i_ord),
                             lc_order_receipt_rec.token_flag(i_ord),
                             lc_order_receipt_rec.emv_card(i_ord),
                             lc_order_receipt_rec.emv_terminal(i_ord),
                             lc_order_receipt_rec.emv_transaction(i_ord),
                             lc_order_receipt_rec.emv_offline(i_ord),
                             lc_order_receipt_rec.emv_fallback(i_ord),
                             lc_order_receipt_rec.emv_tvr(i_ord),
                             lc_order_receipt_rec.wallet_type(i_ord),
                             lc_order_receipt_rec.wallet_id(i_ord)
                             );
        END IF;

        IF p_mode = 'NORMAL'
        THEN
            x_return_status := fnd_api.g_ret_sts_success;

            FOR r_order IN c_order(p_header_id)
            LOOP
                IF r_order.cash_receipt_id IS NOT NULL
                THEN
                    SELECT receipt_number
                    INTO   lc_receipt_number
                    FROM   ar_cash_receipts_all
                    WHERE  cash_receipt_id = r_order.cash_receipt_id;
                ELSE
                    lc_receipt_number := NULL;
                    r_order.cash_receipt_id := -3;
                END IF;

                IF r_order.cc_code = 'DEBIT CARD'
                THEN
                    IF r_order.order_source IN('SPC', 'PRO')
                    THEN
                        lc_customer_receipt_number :=
                            xx_om_sales_acct_pkg.format_debit_card(r_order.transaction_number,
                                                                   r_order.cc_mask_number,
                                                                   r_order.payment_amount);
                    ELSE
                        lc_customer_receipt_number :=
                            xx_om_sales_acct_pkg.format_debit_card(r_order.orig_sys_document_ref,
                                                                   r_order.cc_mask_number,
                                                                   r_order.payment_amount);
                    END IF;
                ELSIF r_order.cc_code = 'TELECHECK ECA'
                THEN
                    IF r_order.order_source IN('SPC', 'PRO')
                    THEN
                        lc_customer_receipt_number :=
                               SUBSTR(r_order.transaction_number,
                                      1,
                                      12)
                            || '00'
                            || SUBSTR(r_order.orig_sys_document_ref,
                                      13);
                    ELSE
                        lc_customer_receipt_number :=
                               SUBSTR(r_order.orig_sys_document_ref,
                                      1,
                                      12)
                            || '00'
                            || SUBSTR(r_order.orig_sys_document_ref,
                                      13);
                    END IF;
                ELSE
                    lc_customer_receipt_number := r_order.orig_sys_document_ref;
                END IF;

                DBMS_OUTPUT.put_line(   'lc_customer_receipt_number '
                                     || lc_customer_receipt_number);

                /*IF r_order.cc_code IN
                       ('DEBIT CARD',
                        'TELECHECK ECA',
                        'CASH',
                        'TELECHECK PAPER',
                        'GIFT CERTIFICATE',
                        'OD MONEY CARD2',
						'OD MONEY CARD3',
                        'PAYPAL',
                        'AMAZON',
						'AMAZON_4S', --Added for Defect# 44321
                        'EBAY',
						'WALMART',
						'RAKUTEN',
						'NEWEGG',
						'CHECK')	--For Defect# 36125
                THEN
                    r_order.remitted := 'Y';
                ELSE
                    r_order.remitted := 'N';
                END IF;*/
				
                IF check_cc_code(r_order.cc_code)
                THEN
                  r_order.remitted := 'Y';
                ELSE
                  r_order.remitted := 'N';
                END IF;

                lc_receipt_status := r_order.receipt_status;
				
				--Added check for defect# 36125
                IF r_order.cc_code IN('CASH', 'TELECHECK PAPER', 'GIFT CERTIFICATE', 'OD MONEY CARD2', 'OD MONEY CARD3','CHECK')
                THEN
                    r_order.MATCHED := 'Y';
                    lc_receipt_status := 'CLEARED';
                    ld_cleared_date := SYSDATE;
                ELSE
                    r_order.MATCHED := 'N';
                    lc_receipt_status := 'OPEN';
                    ld_cleared_date := NULL;
                END IF;

                INSERT INTO xx_ar_order_receipt_dtl
                            (order_payment_id,
                             order_number,
                             orig_sys_document_ref,
                             header_id,
                             order_source,
                             order_type,
                             customer_id,
                             store_number,
                             org_id,
                             request_id,
                             imp_file_name,
                             creation_date,
                             created_by,
                             last_update_date,
                             last_updated_by,
                             payment_number,
                             orig_sys_payment_ref,
                             payment_type_code,
                             credit_card_code,
                             credit_card_number,
                             IDENTIFIER,
                             credit_card_holder_name,
                             credit_card_expiration_date,
                             payment_amount,
                             receipt_method_id,
                             check_number,
                             cc_auth_manual,
                             merchant_number,
                             cc_auth_ps2000,
                             allied_ind,
                             cc_mask_number,
                             od_payment_type,
                             cash_receipt_id,
                             payment_set_id,
                             process_code,
                             remitted,
                             MATCHED,
                             receipt_status,
                             ship_from,
                             customer_receipt_reference,
                             receipt_number,
                             credit_card_approval_code,
                             credit_card_approval_date,
                             customer_site_billto_id,
                             receipt_date,
                             sale_type,
                             additional_auth_codes,
                             process_date,
                             currency_code,
                             single_pay_ind,
                             last_update_login,
                             mpl_order_id,
                             token_flag,
                             emv_card,
                             emv_terminal,
                             emv_transaction,
                             emv_offline,
                             emv_fallback,
                             emv_tvr,
                             wallet_type,
                             wallet_id)
                     VALUES (r_order.order_payment_id,
                             r_order.order_number,
                             r_order.orig_sys_document_ref,
                             r_order.header_id,
                             r_order.order_source,
                             r_order.order_type,
                             r_order.customer_id,
                             r_order.store_num,
                             r_order.org_id,
                             r_order.request_id,
                             r_order.imp_file_name,
                             r_order.creation_date,
                             r_order.created_by,
                             r_order.last_update_date,
                             r_order.last_updated_by,
                             r_order.payment_number,
                             r_order.orig_sys_payment_ref,
                             r_order.payment_type_code,
                             r_order.cc_code,
                             r_order.cc_number_enc,
                             r_order.IDENTIFIER,
                             r_order.cc_name,
                             r_order.cc_exp_date,
                             r_order.payment_amount,
                             r_order.receipt_method_id,
                             r_order.check_number,
                             r_order.cc_auth_manual,
                             r_order.merchant_nbr,
                             r_order.cc_auth_ps2000,
                             r_order.allied_ind,
                             r_order.cc_mask_number,
                             r_order.od_payment_type,
                             r_order.cash_receipt_id,
                             r_order.payment_set_id,
                             r_order.process_code,
                             r_order.remitted,
                             r_order.MATCHED,
                             lc_receipt_status,
                             r_order.ship_from,
                             lc_customer_receipt_number,
                             lc_receipt_number,
                             r_order.credit_card_approval_code,
                             r_order.credit_card_approval_date,
                             r_order.customer_site_billto_id,
                             r_order.receipt_date,
                             r_order.sale_type,
                             r_order.additional_auth_codes,
                             r_order.process_date,
                             r_order.currency_code,
                             NULL,
                             NULL,
                             r_order.external_transaction_number,
                             r_order.token_flag,
                             r_order.emv_card,
                             r_order.emv_terminal,
                             r_order.emv_transaction,
                             r_order.emv_offline,
                             r_order.emv_fallback,
                             r_order.emv_tvr,
                             r_order.wallet_type,
                             r_order.wallet_id );
            END LOOP;
        END IF;

        SELECT hsecs
        INTO   ln_end_time
        FROM   v$timer;
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'Time spent in insert_into_recpt_tbl is (sec) '||((ln_end_time-ln_start_time)/100));
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'No Data Found Raised in insert_into_recpt_tbl:::');

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('No Data Found Raised in insert_into_recpt_tbl:::');
            END IF;
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_error;
            fnd_file.put_line(fnd_file.LOG,
                                 ' Others Raised in insert_into_recpt_tbl:::'
                              || SQLERRM);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Others Raised in insert_into_recpt_tbl:::'
                                 || SUBSTR(SQLERRM,
                                           1,
                                           240));
                oe_msg_pub.add_exc_msg(g_pkg_name,
                                       'insert_into_recpt_tbl',
                                       SUBSTR(SQLERRM,
                                              1,
                                              240));
            END IF;
    END insert_into_recpt_tbl;

--NB FOR R11.2
-- +=====================================================================+
-- | Name  :insert_ret_into_recpt_tbl                                    |
-- | Description  : This Procedure will insert data to custom table      |
-- |                xx_ar_order_receipt_dtl                              |
-- |                                                                     |
-- |                                                                     |
-- | Parameters :p_header_id IN NUMBER                                   |
-- |             x_return_status OUT VARCHAR2                            |
-- +=====================================================================+
    PROCEDURE insert_ret_into_recpt_tbl(
        p_header_id      IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        CURSOR c_order(
            p_header_id  IN  NUMBER)
        IS
            SELECT xx_ar_order_payment_id_s.NEXTVAL order_payment_id,
                   ooh.order_number order_number,
                   ooh.orig_sys_document_ref orig_sys_document_ref,
                   ooh.header_id header_id,
                   ooh.transactional_curr_code currency_code,
                   oos.NAME order_source,
                   ott.NAME order_type,
                   ooh.sold_to_org_id customer_id,
                   LPAD(aou.attribute1,
                        6,
                        '0') store_num,
                   ooh.org_id org_id,
                   ooh.request_id request_id,
                   xoh.imp_file_name imp_file_name,
                   SYSDATE creation_date,
                   ooh.created_by created_by,
                   SYSDATE last_update_date,
                   ooh.created_by last_updated_by,
                   oop.payment_number payment_number,
                   oop.orig_sys_payment_ref orig_sys_payment_ref,
                   oop.payment_type_code payment_type_code,
                   flv.meaning cc_code,
                   oop.credit_card_number cc_number,
                   oop.IDENTIFIER,
                   oop.credit_card_holder_name cc_name,
                   oop.credit_card_expiration_date cc_exp_date,
                   (  -1
                    * oop.credit_amount) payment_amount,
                   oop.receipt_method_id receipt_method_id,
                   oop.check_number check_number,
                   oop.cc_auth_manual cc_auth_manual,
                   oop.merchant_number merchant_nbr,
                   oop.cc_auth_ps2000 cc_auth_ps2000,
                   oop.allied_ind allied_ind,
                   oop.cc_mask_number cc_mask_number,
                   oop.od_payment_type od_payment_type,
                   oop.cash_receipt_id cash_receipt_id,
                   oop.payment_set_id payment_set_id,
                   'HVOP' process_code,
                   'N' remitted,
                   'N' MATCHED,
                   'OPEN' receipt_status,
                   (SELECT LPAD(attribute1,
                                6,
                                '0')
                    FROM   hr_all_organization_units a
                    WHERE  a.organization_id = NVL(xoh.paid_at_store_id,
                                                   ship_from_org_id)) ship_from,
                    --NULL credit_card_approval_code,
                   oop.credit_card_approval_code credit_card_approval_code,
                   NULL credit_card_approval_date,
                   ooh.invoice_to_org_id customer_site_billto_id,
                   (SELECT TRUNC(actual_shipment_date)
                    FROM   oe_order_lines_all b
                    WHERE  ooh.header_id = b.header_id AND ROWNUM = 1) receipt_date,
                   'REFUND' sale_type,
                   NULL additional_auth_codes,
                   xfh.process_date process_date,
                   xoh.tran_number transaction_number,
                   xoh.external_transaction_number,
                   oop.token_flag,
                   oop.emv_card,
                   oop.emv_terminal,
                   oop.emv_Transaction,
                   oop.emv_offline,
                   oop.emv_fallback,
                   oop.emv_tvr,
                   oop.wallet_type,
                   oop.wallet_id
            FROM   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   oe_transaction_types_tl ott,
                   xx_om_header_attributes_all xoh,
                   xx_om_sacct_file_history xfh,
                   hr_all_organization_units aou,
                   xx_om_return_tenders_all oop,
                   fnd_lookup_values flv
            WHERE  ooh.order_source_id = oos.order_source_id
            AND    ooh.order_type_id = ott.transaction_type_id
            AND    ott.LANGUAGE = USERENV('LANG')
            AND    ooh.header_id = xoh.header_id
            AND    xoh.imp_file_name = xfh.file_name
            AND    ooh.ship_from_org_id = aou.organization_id
            AND    ooh.header_id = oop.header_id
            AND    oop.od_payment_type = flv.lookup_code
            AND    flv.lookup_type = 'OD_PAYMENT_TYPES'
            AND    oos.NAME = 'POE'
            AND    ooh.header_id = p_header_id;

        ln_debug_level     CONSTANT NUMBER       := oe_debug_pub.g_debug_level;
        lc_customer_receipt_number  VARCHAR2(80);
        lc_receipt_number           VARCHAR2(80);
        ln_ord_pay_id               NUMBER;
        ln_start_time               NUMBER;
        ln_end_time                 NUMBER;
        lc_receipt_status           VARCHAR2(30);
        ld_cleared_date             DATE;
    BEGIN
        --IF p_mode = 'NORMAL' THEN
        SELECT hsecs
        INTO   ln_start_time
        FROM   v$timer;

        x_return_status := fnd_api.g_ret_sts_success;

        FOR r_order IN c_order(p_header_id)
        LOOP
            ln_ord_pay_id := r_order.order_payment_id;

            IF r_order.cash_receipt_id IS NOT NULL
            THEN
                SELECT receipt_number
                INTO   lc_receipt_number
                FROM   ar_cash_receipts_all
                WHERE  cash_receipt_id = r_order.cash_receipt_id;
            ELSE
                lc_receipt_number := NULL;
                r_order.cash_receipt_id := -3;
            END IF;

            IF r_order.cc_code = 'DEBIT CARD'
            THEN
                IF r_order.order_source IN('SPC', 'PRO')
                THEN
                    lc_customer_receipt_number :=
                        xx_om_sales_acct_pkg.format_debit_card(r_order.transaction_number,
                                                               r_order.cc_mask_number,
                                                               r_order.payment_amount);
                ELSE
                    lc_customer_receipt_number :=
                        xx_om_sales_acct_pkg.format_debit_card(r_order.orig_sys_document_ref,
                                                               r_order.cc_mask_number,
                                                               r_order.payment_amount);
                END IF;
            ELSIF r_order.cc_code = 'TELECHECK ECA'
            THEN
                IF r_order.order_source IN('SPC', 'PRO')
                THEN
                    lc_customer_receipt_number :=
                             SUBSTR(r_order.transaction_number,
                                    1,
                                    12)
                          || '00'
                          || SUBSTR(r_order.orig_sys_document_ref,
                                    13);
                ELSE
                    lc_customer_receipt_number :=
                           SUBSTR(r_order.orig_sys_document_ref,
                                  1,
                                  12)
                        || '00'
                        || SUBSTR(r_order.orig_sys_document_ref,
                                  13);
                END IF;
            ELSE
                lc_customer_receipt_number := r_order.orig_sys_document_ref;
            END IF;

            /*IF r_order.cc_code IN
                   ('DEBIT CARD',
                    'TELECHECK ECA',
                    'CASH',
                    'TELECHECK PAPER',
                    'GIFT CERTIFICATE',
                    'OD MONEY CARD2',
					'OD MONEY CARD3',
                    'PAYPAL',
                    'AMAZON',
					'AMAZON_4S', --Added for Defect# 44321
                    'EBAY',
					'WALMART',
					'RAKUTEN',
					'NEWEGG',
					'CHECK',	--For Defect# 36125
					'REFUND')	--For Defect# 36125)
            THEN
                r_order.remitted := 'Y';
            ELSE
                r_order.remitted := 'N';
            END IF;*/
            
            IF check_return_cc_code(r_order.cc_code)
            THEN
              r_order.remitted := 'Y';
            ELSE
              r_order.remitted := 'N';
            END IF;

            lc_receipt_status := r_order.receipt_status;

			--Added check, refund for defect# 36125
            IF r_order.cc_code IN('CASH', 'TELECHECK PAPER', 'GIFT CERTIFICATE', 'OD MONEY CARD2','OD MONEY CARD3','CHECK','REFUND')
            THEN
                r_order.MATCHED := 'Y';
                lc_receipt_status := 'CLEARED';
                ld_cleared_date := SYSDATE;
            ELSE
                r_order.MATCHED := 'N';
                lc_receipt_status := 'OPEN';
                ld_cleared_date := NULL;
            END IF;

            INSERT INTO xx_ar_order_receipt_dtl
                        (order_payment_id,
                         order_number,
                         orig_sys_document_ref,
                         header_id,
                         order_source,
                         order_type,
                         customer_id,
                         store_number,
                         org_id,
                         request_id,
                         imp_file_name,
                         creation_date,
                         created_by,
                         last_update_date,
                         last_updated_by,
                         payment_number,
                         orig_sys_payment_ref,
                         payment_type_code,
                         credit_card_code,
                         credit_card_number,
                         IDENTIFIER,
                         credit_card_holder_name,
                         credit_card_expiration_date,
                         payment_amount,
                         receipt_method_id,
                         check_number,
                         cc_auth_manual,
                         merchant_number,
                         cc_auth_ps2000,
                         allied_ind,
                         cc_mask_number,
                         od_payment_type,
                         cash_receipt_id,
                         payment_set_id,
                         process_code,
                         remitted,
                         MATCHED,
                         receipt_status,
                         ship_from,
                         customer_receipt_reference,
                         receipt_number,
                         credit_card_approval_code,
                         credit_card_approval_date,
                         customer_site_billto_id,
                         receipt_date,
                         sale_type,
                         additional_auth_codes,
                         process_date,
                         currency_code,
                         single_pay_ind,
                         last_update_login,
                         cleared_date,
                         mpl_order_id,
                         token_flag,
                         emv_card,
                         emv_terminal,
                         emv_transaction,
                         emv_offline,
                         emv_fallback,
                         emv_tvr,
                         wallet_type,
                         wallet_id)
                 VALUES (r_order.order_payment_id,
                         r_order.order_number,
                         r_order.orig_sys_document_ref,
                         r_order.header_id,
                         r_order.order_source,
                         r_order.order_type,
                         r_order.customer_id,
                         r_order.store_num,
                         r_order.org_id,
                         r_order.request_id,
                         r_order.imp_file_name,
                         r_order.creation_date,
                         r_order.created_by,
                         r_order.last_update_date,
                         r_order.last_updated_by,
                         r_order.payment_number,
                         r_order.orig_sys_payment_ref,
                         r_order.payment_type_code,
                         r_order.cc_code,
                         r_order.cc_number,
                         r_order.IDENTIFIER,
                         r_order.cc_name,
                         r_order.cc_exp_date,
                         r_order.payment_amount,
                         r_order.receipt_method_id,
                         r_order.check_number,
                         r_order.cc_auth_manual,
                         r_order.merchant_nbr,
                         r_order.cc_auth_ps2000,
                         r_order.allied_ind,
                         r_order.cc_mask_number,
                         r_order.od_payment_type,
                         r_order.cash_receipt_id,
                         r_order.payment_set_id,
                         r_order.process_code,
                         r_order.remitted,
                         r_order.MATCHED,
                         lc_receipt_status,
                         r_order.ship_from,
                         lc_customer_receipt_number,
                         lc_receipt_number,
                         r_order.credit_card_approval_code,
                         r_order.credit_card_approval_date,
                         r_order.customer_site_billto_id,
                         r_order.receipt_date,
                         r_order.sale_type,
                         r_order.additional_auth_codes,
                         r_order.process_date,
                         r_order.currency_code,
                         NULL,
                         NULL,
                         ld_cleared_date,
                         r_order.external_transaction_number,
                         NVL(LTRIM(RTRIM(r_order.token_flag)),'N'),
                         NVL(LTRIM(RTRIM(r_order.emv_card)),'N'),
                         LTRIM(RTRIM(r_order.emv_terminal)),
                         NVL(LTRIM(RTRIM(r_order.emv_transaction)),'N'),
                         NVL(LTRIM(RTRIM(r_order.emv_offline)),'N'),
                         NVL(LTRIM(RTRIM(r_order.emv_fallback)),'N'),
                         LTRIM(RTRIM(r_order.emv_tvr)),
                         LTRIM(RTRIM(r_order.wallet_type)),
                         LTRIM(RTRIM(r_order.wallet_id))
                         );
        END LOOP;

--END IF;
        fnd_file.put_line(fnd_file.LOG,
                             'INSERT ROW COUNT :'
                          || SQL%ROWCOUNT);

        IF ln_debug_level > 0
        THEN
            oe_debug_pub.ADD(   'INSERT ROW COUNT :'
                             || SQL%ROWCOUNT);
        END IF;

        SELECT hsecs
        INTO   ln_end_time
        FROM   v$timer;

        fnd_file.put_line(fnd_file.LOG,
                             'Time spent in insert_ret_into_recpt_tbl is (sec) '
                          || (  (  ln_end_time
                                 - ln_start_time)
                              / 100));
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'No Data Found Raised :::');

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD('No Data Found Raised in insert_ret_into_recpt_tbl:::');
            END IF;
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_error;
            fnd_file.put_line(fnd_file.LOG,
                                 'Others Raised in insert_ret_into_recpt_tbl:::'
                              || SQLERRM);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Others Raised in insert_ret_into_recpt_tbl:::'
                                 || SUBSTR(SQLERRM,
                                           1,
                                           240));
                oe_msg_pub.add_exc_msg(g_pkg_name,
                                       'insert_into_recpt_tbl',
                                       SUBSTR(SQLERRM,
                                              1,
                                              240));
            END IF;
    END insert_ret_into_recpt_tbl;

--NB FOR R11.2
-- +=====================================================================+
-- | Name  :load_to_settlement                                           |
-- | Description  : This Procedure will call xx_iby_settlement_pkg to    |
-- |                load data to settlement table                        |
-- |                                                                     |
-- |                                                                     |
-- | Parameters :p_header_id IN NUMBER                                   |
-- |             p_mode      IN VARCHAR2                                 |
-- |             p_batch_id  IN NUMBER                                   |
-- |             x_return_status OUT VARCHAR2                            |
-- +=====================================================================+
    PROCEDURE load_to_settlement(
        p_header_id      IN      NUMBER,
        p_mode           IN      VARCHAR2,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        ln_ord_pay_id            NUMBER;
        lb_sett_stage            BOOLEAN;
        lc_err_msgs              VARCHAR2(2000);
        ln_debug_level  CONSTANT NUMBER         := oe_debug_pub.g_debug_level;
        ln_start_time            NUMBER;
        ln_end_time              NUMBER;
--lc_context_area            VARCHAR2(64);
        lc_context               VARCHAR2(64);

        CURSOR c_b_ord_pay_id(
            p_batchid  IN  NUMBER)
        IS
            SELECT ord.order_payment_id,
			       ord.payment_amount                               --Added column as per defect#38223 ver 29.0
            FROM   xx_ar_order_receipt_dtl ord,
                   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   ra_terms rt               -- Added table as per defect#33817 ver 20.0 
            WHERE  ooh.header_id = ord.header_id
            AND    ooh.batch_id = p_batchid
            AND    ord.payment_type_code = 'CREDIT_CARD'
            AND    ord.credit_card_code <> 'DEBIT CARD'
            AND    ooh.order_source_id = oos.order_source_id
            AND    oos.NAME = 'POE'
            AND    rt.name != 'SA_DEPOSIT'           --   Added as per defect#33817 ver 20.0 
            AND    rt.term_id = ooh.payment_Term_id  --   Added join as per defect#33817 ver 20.0 
            AND    NOT EXISTS(
                      /* SELECT 1
                       FROM   xx_om_legacy_deposits dep
                       WHERE  (dep.transaction_number = ooh.orig_sys_document_ref   -- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
                        OR (SUBSTR(dep.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9) -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
                       AND NOT EXISTS (SELECT 1                        			         -- Added condition as per defect# 33817 ver 20.0
                                                        FROM XX_AR_INTSTORECUST_OTC OTC
                                                       WHERE ooh.sold_to_org_id = OTC.cust_account_id)
                                      )
                              )     
                       AND    dep.cash_receipt_id IS NOT NULL
                       AND    ROWNUM < 2 */
                        SELECT 1
                        FROM   XX_OM_LEGACY_DEPOSITS DEP
                        WHERE  SUBSTR (DEP.ORIG_SYS_DOCUMENT_REF, 1, 9) = SUBSTR (OOH.ORIG_SYS_DOCUMENT_REF, 1, 9)
                                AND NOT EXISTS (SELECT 1
                                                FROM   XX_AR_INTSTORECUST_OTC OTC
                                                WHERE  OOH.SOLD_TO_ORG_ID = OTC.CUST_ACCOUNT_ID)
                         AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                         AND    ROWNUM < 2
                         UNION
                         SELECT 1
                         FROM   XX_OM_LEGACY_DEPOSITS DEP
                         WHERE  DEP.TRANSACTION_NUMBER = OOH.ORIG_SYS_DOCUMENT_REF
                         AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                         AND    ROWNUM < 2
                       UNION
                       SELECT 1
                       FROM   xx_om_legacy_dep_dtls DDL
                       WHERE ( ddl.transaction_number = ooh.orig_sys_document_ref   	-- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
		        OR   ddl.orig_sys_Document_ref = ooh.orig_sys_document_ref )    -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
		       --SUBSTR(DDL.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9)   -- Commented as per defect# 33817 ver 20.0
		       --AND    LENGTH(DDL.orig_sys_document_ref) <= 12                                  -- Commented as per defect# 33817 ver 20.0
		       AND    ROWNUM < 2
		            );         

        CURSOR c_n_ord_pay_id(
            p_head_id  IN  NUMBER)
        IS
            SELECT ord.order_payment_id,
			       ord.payment_amount                               --Added column as per defect#38223 ver 29.0 
            FROM   xx_ar_order_receipt_dtl ord,
                   oe_order_headers_all ooh,
                   oe_order_sources oos,
                   ra_terms rt               -- Added table as per defect#33817 ver 20.0 
            WHERE  ooh.header_id = ord.header_id
            AND    ooh.header_id = p_head_id
            AND    ord.payment_type_code = 'CREDIT_CARD'
            AND    ord.credit_card_code <> 'DEBIT CARD'
            AND    ooh.order_source_id = oos.order_source_id
            AND    oos.NAME = 'POE'
            AND    rt.name != 'SA_DEPOSIT'           --   Added as per defect#33817 ver 20.0 
            AND    rt.term_id = ooh.payment_Term_id  --   Added join as per defect#33817 ver 20.0 
            AND    NOT EXISTS(
                      /* SELECT 1
                       FROM   xx_om_legacy_deposits dep
                       WHERE  (dep.transaction_number = ooh.orig_sys_document_ref   -- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
                        OR (SUBSTR(dep.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9) -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
                       AND NOT EXISTS (SELECT 1                        				       -- Added condition as per defect# 33817 ver 20.0
                                                        FROM XX_AR_INTSTORECUST_OTC OTC
                                                       WHERE ooh.sold_to_org_id = OTC.cust_account_id)
                                      )
                              )     
                       AND    dep.cash_receipt_id IS NOT NULL
                       AND    ROWNUM < 2 */
                        SELECT 1
                        FROM   XX_OM_LEGACY_DEPOSITS DEP
                        WHERE  SUBSTR (DEP.ORIG_SYS_DOCUMENT_REF, 1, 9) = SUBSTR (OOH.ORIG_SYS_DOCUMENT_REF, 1, 9)
                                AND NOT EXISTS (SELECT 1
                                                FROM   XX_AR_INTSTORECUST_OTC OTC
                                                WHERE  OOH.SOLD_TO_ORG_ID = OTC.CUST_ACCOUNT_ID)
                         AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                         AND    ROWNUM < 2
                         UNION
                         SELECT 1
                         FROM   XX_OM_LEGACY_DEPOSITS DEP
                         WHERE  DEP.TRANSACTION_NUMBER = OOH.ORIG_SYS_DOCUMENT_REF
                         AND    DEP.CASH_RECEIPT_ID IS NOT NULL
                         AND    ROWNUM < 2
                       UNION
                       SELECT 1
                       FROM   xx_om_legacy_dep_dtls DDL
                       WHERE  ( ddl.transaction_number = ooh.orig_sys_document_ref   	-- Eliminates Deposit records for POS (single pay) added as per defect#33817 ver 20.0 
		        OR   ddl.orig_sys_Document_ref = ooh.orig_sys_document_ref )    -- Eliminates Deposit for Non-POS order added as per defect#33817 ver 20.0 
		       --SUBSTR(DDL.orig_sys_document_ref,1,9) = SUBSTR(ooh.orig_sys_document_ref,1,9)   -- Commented as per defect# 33817 ver 20.0
		       --AND    LENGTH(DDL.orig_sys_document_ref) <= 12                                  -- Commented as per defect# 33817 ver 20.0
		       AND    ROWNUM < 2
		              );         
    BEGIN
        --dbms_application_info.read_client_info(lc_context_area);
        --lc_context_area := (SUBSTR(lc_context_area,1,55)||'AJB'||'      ');
        --dbms_application_info.set_client_info(lc_context_area);
        DBMS_SESSION.set_context(namespace      => 'XX_OM_SA_CONTEXT',
                                 ATTRIBUTE      => 'TYPE',
                                 VALUE          => 'AJB');
        lc_context := SYS_CONTEXT('XX_OM_SA_CONTEXT',
                                  'TYPE');
        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin of Program SET CONTEXT WITH VALUE :'|| lc_context_area);
        fnd_file.put_line(fnd_file.LOG,
                             'Begin of Program SET SYS_CONTEXT WITH VALUE :'
                          || lc_context);

        SELECT hsecs
        INTO   ln_start_time
        FROM   v$timer;

        x_return_status := fnd_api.g_ret_sts_success;
        oe_debug_pub.ADD('Begin load_to_settlement');
        --DBMS_OUTPUT.PUT_LINE('Begin load_to_settlement BATCH MODE :' ||  p_mode  );
        fnd_file.put_line(fnd_file.LOG,
                             'Begin load_to_settlement BATCH MODE :'
                          || p_mode);

        IF p_mode = 'HVOP'
        THEN
            FOR r_b_ord_pay_id IN c_b_ord_pay_id(p_batch_id)
            LOOP
                --FND_FILE.PUT_LINE(FND_FILE.LOG,'r_b_ord_pay_id.order_payment_id '||r_b_ord_pay_id.order_payment_id);
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'r_b_ord_pay_id.order_payment_id is : '
                                     || r_b_ord_pay_id.order_payment_id);
                END IF;
				
				IF r_b_ord_pay_id.payment_amount<>0            --Added condition as per defect#38223 ver 29.0
				THEN
				
                xx_iby_settlement_pkg.xx_stg_receipt_for_settlement
                                                                 (p_order_payment_id       => r_b_ord_pay_id.order_payment_id,
                                                                  x_settlement_staged      => lb_sett_stage,
                                                                  x_error_message          => lc_err_msgs);
																  
				ELSE
				fnd_file.put_line(fnd_file.LOG,
                                     'I entered else block '
                                  );
				UPDATE xx_ar_order_receipt_dtl                  --Added update as per defect#38223 ver 29.0
				SET remitted='I',
				    matched='Y',
					receipt_status='CLEARED' 
				WHERE order_payment_id=r_b_ord_pay_id.order_payment_id;															  

				END IF;

               
                oe_debug_pub.ADD(   'BATCH MODE :::'
                                 || lc_err_msgs);
                fnd_file.put_line(fnd_file.LOG,
                                     'lc_err_msgs '
                                  || lc_err_msgs);
            END LOOP;
        ELSE
            DBMS_OUTPUT.put_line(   'Begin load_to_settlement  :'
                                 || p_header_id
                                 || p_mode);

            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Begin load_to_settlement NON BATCH MODE :'||  p_header_id  );
            FOR r_n_ord_pay_id IN c_n_ord_pay_id(p_header_id)
            LOOP
                --DBMS_OUTPUT.PUT_LINE('lc_return_status  :'||r_n_ord_pay_id.order_payment_id);
                --FND_FILE.PUT_LINE(FND_FILE.LOG,'r_n_ord_pay_id.order_payment_id '||r_n_ord_pay_id.order_payment_id);
                IF ln_debug_level > 0
                THEN
                    oe_debug_pub.ADD(   'r_n_ord_pay_id.order_payment_id is : '
                                     || r_n_ord_pay_id.order_payment_id);
                END IF;

                IF r_n_ord_pay_id.payment_amount<>0                  --Added condition as per defect#38223 ver 29.0
				THEN
				
                xx_iby_settlement_pkg.xx_stg_receipt_for_settlement
                                                                 (p_order_payment_id       => r_n_ord_pay_id.order_payment_id,
                                                                  x_settlement_staged      => lb_sett_stage,
                                                                  x_error_message          => lc_err_msgs);
																  
				ELSE
				fnd_file.put_line(fnd_file.LOG,
                                     'I entered else block '
                                  );
				UPDATE xx_ar_order_receipt_dtl                       --Added update as per defect#38223 ver 29.0
				SET remitted='I',
				    matched='Y',
					receipt_status='CLEARED'
				WHERE order_payment_id=r_n_ord_pay_id.order_payment_id;															  

				
				END IF;
				
                fnd_file.put_line(fnd_file.LOG,
                                     'lc_err_msgs '
                                  || lc_err_msgs);
                oe_debug_pub.ADD(   'REGULAR MODE :::'
                                 || lc_err_msgs);
            END LOOP;
        END IF;

        SELECT hsecs
        INTO   ln_end_time
        FROM   v$timer;

        fnd_file.put_line(fnd_file.LOG,
                             'Time spent in load_to_settlement is (sec) '
                          || (  (  ln_end_time
                                 - ln_start_time)
                              / 100));
    --dbms_application_info.set_client_info(SUBSTR(lc_context_area,1,55)||'         ');
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'END of Program RESETTING CONTEXT BACK :'|| lc_context_area);
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'NO DATA FOUND TO LOAD INTO SETTLEMENT API:::');
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_error;
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED in load_to_settlement:::'
                              || SQLERRM);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Others Raised in insert_ret_into_recpt_tbl:::'
                                 || SUBSTR(SQLERRM,
                                           1,
                                           240));
                oe_msg_pub.add_exc_msg(g_pkg_name,
                                       'insert_into_recpt_tbl',
                                       SUBSTR(SQLERRM,
                                              1,
                                              240));
            END IF;
    END load_to_settlement;

    PROCEDURE inventory_misc_issue(
        p_header_id      IN      NUMBER,
        p_mode           IN      VARCHAR2,
        p_batch_id       IN      NUMBER,
        x_return_status  OUT     VARCHAR2)
    IS
        ln_count          NUMBER;
        lc_return_status  VARCHAR2(1);
        ln_header_id      NUMBER;
        ln_batch_id       NUMBER;
        lc_mode           VARCHAR2(30);
        ln_start_time     NUMBER       := 0;
        ln_end_time       NUMBER       := 0;
        ln_debug_level    NUMBER       := 0;
    BEGIN
        fnd_file.put_line(fnd_file.LOG,
                             'Begin load_to_settlement BATCH MODE :'
                          || p_mode);
        ln_header_id := p_header_id;
        ln_batch_id := p_batch_id;
        lc_mode := p_mode;
        lc_return_status := fnd_api.g_ret_sts_success;

        SELECT hsecs
        INTO   ln_start_time
        FROM   v$timer;

        IF lc_mode = 'HVOP'
        THEN
            SELECT COUNT(*)
            INTO   ln_count
            FROM   oe_order_headers_all h,
                   xx_om_header_attributes_all x
            WHERE  h.header_id = x.header_id AND x.sr_number IS NOT NULL AND h.batch_id = ln_batch_id;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'ln_count :::'
                                 || ln_count);
                oe_debug_pub.ADD(   'ln_header_id :::'
                                 || ln_header_id);
                oe_debug_pub.ADD(   'ln_batch_id  :::'
                                 || ln_batch_id);
            END IF;

            IF ln_count > 0
            THEN
                xx_mer_insert_mat_iface_pkg.insert_to_mat_iface(p_header_id          => ln_header_id,
                                                                p_mode               => lc_mode,
                                                                p_batch_id           => ln_batch_id,
                                                                x_return_status      => lc_return_status);
            END IF;
        ELSE
            SELECT COUNT(*)
            INTO   ln_count
            FROM   oe_order_headers_all h,
                   xx_om_header_attributes_all x
            WHERE  h.header_id = x.header_id AND x.sr_number IS NOT NULL AND h.header_id = ln_header_id;

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'ln_count :::'
                                 || ln_count);
                oe_debug_pub.ADD(   'ln_header_id :::'
                                 || ln_header_id);
                oe_debug_pub.ADD(   'ln_batch_id  :::'
                                 || ln_batch_id);
            END IF;

            IF ln_count > 0
            THEN
                xx_mer_insert_mat_iface_pkg.insert_to_mat_iface(p_header_id          => ln_header_id,
                                                                p_mode               => lc_mode,
                                                                p_batch_id           => ln_batch_id,
                                                                x_return_status      => lc_return_status);
            END IF;
        END IF;

        SELECT hsecs
        INTO   ln_end_time
        FROM   v$timer;

        fnd_file.put_line(fnd_file.LOG,
                             'Time spent in inventory_misc_issue is (sec) '
                          || (  (  ln_end_time
                                 - ln_start_time)
                              / 100));
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            fnd_file.put_line(fnd_file.LOG,
                              'NO DATA FOUND TO LOAD INTO Inventory Misc Issue API:::');
        WHEN OTHERS
        THEN
            x_return_status := fnd_api.g_ret_sts_error;
            fnd_file.put_line(fnd_file.LOG,
                                 'WHEN OTHERS RAISED in inventory_misc_issue:::'
                              || SQLERRM);

            IF ln_debug_level > 0
            THEN
                oe_debug_pub.ADD(   'Others Raised in inventory_misc_issue:::'
                                 || SUBSTR(SQLERRM,
                                           1,
                                           240));
                oe_msg_pub.add_exc_msg(g_pkg_name,
                                       'inventory_misc_issue',
                                       SUBSTR(SQLERRM,
                                              1,
                                              240));
            END IF;
    END inventory_misc_issue;
	
-- +===============================================================================================+
-- | Name  : check_cc_code                                                                         |
-- | Description     : This function to check the credit card code in translations                 |
-- | Parameters      : p_cc_code                                                                   |
-- +================================================================================================+

  FUNCTION check_cc_code(p_cc_code   IN  fnd_lookup_values.meaning%TYPE)
  RETURN BOOLEAN
  IS
    lc_error_msg       VARCHAR2(2000):= NULL;
    lc_source_value1   VARCHAR2(50) := NULL;
  BEGIN
    lc_error_msg        := NULL;

    SELECT xftv.source_value1
    INTO lc_source_value1
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
    AND sysdate BETWEEN xft.start_date_active AND NVL(xft.end_date_active,SYSDATE+1)
    AND xft.translation_name  = 'OD_ORD_PAYMENT_METHODS'
	AND xftv.source_value1    = p_cc_code;

    RETURN TRUE;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       lc_error_msg := 'No Translation value found for '||p_cc_code;
       fnd_file.put_line(fnd_file.log,lc_error_msg);
       RETURN FALSE;
     WHEN OTHERS
     THEN
       lc_error_msg := 'Error while getting the translation value for OD_ORD_PAYMENT_METHODS'|| SUBSTR(SQLERRM,1,1500);
       fnd_file.put_line(fnd_file.log,lc_error_msg);
       RETURN FALSE;
  END check_cc_code;
  
-- +===============================================================================================+
-- | Name  : check_return_cc_code                                                                  |
-- | Description     : This function to check the credit card code in translations                 |
-- | Parameters      : p_cc_code                                                                   |
-- +================================================================================================+

  FUNCTION check_return_cc_code(p_cc_code   IN  fnd_lookup_values.meaning%TYPE)
  RETURN BOOLEAN
  IS
    lc_error_msg       VARCHAR2(2000):= NULL;
    lc_source_value1   VARCHAR2(50) := NULL;
  BEGIN
    lc_error_msg        := NULL;

    SELECT xftv.source_value1
    INTO lc_source_value1
    FROM xx_fin_translatedefinition xft,
         xx_fin_translatevalues xftv
    WHERE xft.translate_id    = xftv.translate_id
    AND xft.enabled_flag      = 'Y'
    AND xftv.enabled_flag     = 'Y'
    AND sysdate BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE+1)
    AND sysdate BETWEEN xft.start_date_active AND NVL(xft.end_date_active,SYSDATE+1)
    AND xft.translation_name  = 'OD_R_ORD_PAYMENT_METHODS'
	AND xftv.source_value1    = p_cc_code;

    RETURN TRUE;
   EXCEPTION
     WHEN NO_DATA_FOUND
     THEN
       lc_error_msg := 'No Translation value found for '||p_cc_code;
       fnd_file.put_line(fnd_file.log,lc_error_msg);
       RETURN FALSE;
     WHEN OTHERS
     THEN
       lc_error_msg := 'Error while getting the translation value for OD_R_ORD_PAYMENT_METHODS'|| SUBSTR(SQLERRM,1,1500);
       fnd_file.put_line(fnd_file.log,lc_error_msg);
       RETURN FALSE;
  END check_return_cc_code;
	
END xx_om_sales_acct_pkg;
/
EXIT;