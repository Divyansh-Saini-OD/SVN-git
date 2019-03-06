CREATE OR REPLACE PACKAGE xx_om_releasehold
AS
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_RELEASEHOLD XX_OM_RELEASEHOLD.PKS)                        |
-- | Description      : This Program is designed to release HOLDS,           |
-- |                    OD: SAS Pending deposit hold and                     |
-- |                    OD: Payment Processing Failure as an activity after  |
-- |                    Post production                                      |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version Date        Author            Remarks                            |
-- |======= =========== =============     ==========================         |
-- |DRAFT1A 20-JUL-12   Oracle AMS Team   Initial draft version              |
-- |                                                                         |
-- | 1.0    03-DEC-12   Gayathri K        Defect # 20937    Creating the     |
-- |                                                       Missing Receipts  |
-- | 1.1    15-DEC-17   Venkata Battu     Added book_order procedure         |   
-- +=========================================================================+

    -----------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
-----------------------------------------------------------------

    --Define Global variables
    g_user_id  NUMBER := fnd_global.user_id;
    g_org_id   NUMBER := fnd_global.org_id;
	g_resp_id  NUMBER := fnd_global.resp_id;
	g_resp_appl_id NUMBER := fnd_global.resp_appl_id;

-- Define Order Number Rec for the Main Cursor in XX_OM_PPF_HOLD_RELEASE
    TYPE order_number_rec IS RECORD(
        imp_file_name     xx_om_header_attributes_all.imp_file_name%TYPE,
        creation_date     oe_order_headers_all.creation_date%TYPE,
        last_update_date  oe_order_headers_all.last_update_date%TYPE,
        request_id        oe_order_headers_all.request_id%TYPE,
        batch_id          oe_order_headers_all.batch_id%TYPE,
        order_hold_id     oe_order_holds_all.order_hold_id%TYPE,
        hold_source_id    oe_order_holds_all.hold_source_id%TYPE,
        order_number      oe_order_headers_all.order_number%TYPE,
        header_id         oe_order_headers_all.header_id%TYPE,
        hold_name         oe_hold_definitions.NAME%TYPE,
        flow_status_code  oe_order_headers_all.flow_status_code%TYPE,
        payment_status    VARCHAR2(1),
        deposit_status    VARCHAR2(1),
        ab_customer       VARCHAR2(1),
        receipt_status    VARCHAR2(1)
    );

-- table with the datatype of record declared order_number_rec
    TYPE order_number_rec_tab IS TABLE OF order_number_rec
        INDEX BY PLS_INTEGER;

--List of procedures in the package
-- +=====================================================================+
-- | Name  : XX_MAIN_PROCEDURE                                           |
-- | Description     : The Main procedure to determine which Hold is to  |
-- |                   be released,OD: SAS Pending deposit hold or       |
-- |                   OD: Payment Processing Failure or both            |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_SAS_HOLD_param    IN ->Flag of Y/N              |
-- |                   p_PPF_HOLD_param    IN ->Flag of Y/N              |
-- |                   x_retcode           OUT                           |
-- |                   x_errbuf            OUT                           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
    PROCEDURE xx_main_procedure(
        x_retcode            OUT NOCOPY     NUMBER,
        x_errbuf             OUT NOCOPY     VARCHAR2,
        p_order_number_from  IN             NUMBER,
        p_order_number_to    IN             NUMBER,
        p_date_from          IN             VARCHAR2,
        p_date_to            IN             VARCHAR2,
        p_sas_hold_param     IN             VARCHAR2,
        p_ppf_hold_param     IN             VARCHAR2,
        p_debug_flag         IN             VARCHAR2 DEFAULT 'N');

-- +============================================================================+
-- | Name             :  PUT_LOG_LINE                                           |
-- | Description      :  This procedure will print log messages.                |
-- | Parameters       :  p_debug IN   -> Debug Flag - Default N.                |
-- |                  :  p_force  IN  -> Default Log - Default N                |
-- |                  :  p_buffer IN  -> Log Message.                           |
-- +============================================================================+
    PROCEDURE put_log_line(
        p_debug_flag  IN  VARCHAR2 DEFAULT 'N',
        p_force       IN  VARCHAR2 DEFAULT 'N',
        p_buffer      IN  VARCHAR2 DEFAULT ' ');

-- +=====================================================================+
-- | Name  : XX_OM_SAS_DEPO_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: SAS Pending deposit hold                      |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
    PROCEDURE xx_om_sas_depo_release(
        p_order_number_from  IN  NUMBER,
        p_order_number_to    IN  NUMBER,
        p_date_from          IN  VARCHAR2,
        p_date_to            IN  VARCHAR2,
        p_debug_flag         IN  VARCHAR2 DEFAULT 'N');

-- +=====================================================================+
-- | Name  : XX_OM_PPF_HOLD_RELEASE                                      |
-- | Description     : The Process Child is called to release holds on   |
-- |                   records stuck with hold name as                   |
-- |                   OD: Payment Processing Failure                    |
-- | Parameters      : p_order_number_from IN ->Order Number             |
-- |                   P_ORDER_NUMBER_TO   IN ->Order Number             |
-- |                   P_date_FROM         IN ->Date Range(From)         |
-- |                   p_date_to           IN ->Date Range(To)           |
-- |                   p_debug_flag        IN ->Debug flag               |
-- |                                           By default it will be N.  |
-- +=====================================================================+
    PROCEDURE xx_om_ppf_hold_release(
        p_order_number_from  IN  NUMBER,
        p_order_number_to    IN  NUMBER,
        p_date_from          IN  VARCHAR2,
        p_date_to            IN  VARCHAR2,
        p_debug_flag         IN  VARCHAR2 DEFAULT 'N');

-- +============================================================================+
-- | Name             :  XX_CREATE_MISSING_RECEIPT                              |
-- |                                                                            |
-- | Description      :  This procedure will create Prepayment Missing Receipts |
-- |                                                                            |
-- | Parameters       :  p_debug_flag       IN ->     By default it will be Y.  |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version Date        Author            Remarks             Descripition      |
-- |======= =========== =============     ================  ==============      |
-- | 1.0    03-DEC-12   Gayathri K   Defect # 20937         Creating the        |
-- |                                                          Missing Receipts  |
-- |                                                                            |
-- +============================================================================+
    PROCEDURE xx_create_missing_receipt(
        p_debug_flag  IN  VARCHAR2 DEFAULT 'Y');
-- +============================================================================+
-- | Name             :  BOOK_ORDER                                             |
-- | Description      :  This procedure will book the hold released sales order |
-- | Parameters       :  p_header_id  IN   -> Header Id                         |
-- |                  :  p_debug_flag IN   -> Debug flag                        |
-- |                                           By default it will be N          |
-- +============================================================================+	
    PROCEDURE book_order(p_header_id  IN NUMBER
                     ,p_debug_flag IN VARCHAR2 
                     );  
END xx_om_releasehold;
/