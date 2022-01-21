SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_OM_HVOP_DEPOSIT_CONC_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |                                    
-- |                                                                   |
-- |                Office Depot                                       |
-- |                                                                   |
-- +===================================================================+
-- | Name  : XX_OM_HVOP_DEPOSIT_CONC_PKG                               |
-- |                                                                   |
-- | Description      : Package Specification                          |
-- |                                                                   |
-- |Change Record:                                                     |
-- |                                                                   |
-- |===============                                                    |
-- |                                                                   |
-- |Version    Date          Author           Remarks                  |
-- |                                                                   |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   06-MAR-2007   Visalakshi          Initial draft version |                     
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
------------------------------------------------------------------------
-- DATA TYPES (RECORD/TABLE TYPES)
------------------------------------------------------------------------
g_org_id    CONSTANT NUMBER := FND_PROFILE.VALUE('ORG_ID');
g_request_id            NUMBER;
g_pay_method_code      XX_OM_SACCT_CONC_PKG.g_pay_method_code%type;
g_cc_code              XX_OM_SACCT_CONC_PKG.g_cc_code%type;
--g_store_id             store_id_type;
g_payment_term         XX_OM_SACCT_CONC_PKG.g_payment_term%type;
g_order_source         VARCHAR2(10);
g_transaction_number   oe_headers_iface_all.orig_sys_document_ref%TYPE;
g_header_count         NUMBER := 0;
g_header_tot_amount    NUMBER := 0;
g_payment_count        NUMBER := 0;
g_payment_tot_amt      NUMBER := 0;
g_header_counter       NUMBER := 0;
g_currency_code        oe_headers_iface_all.TRANSACTIONAL_CURR_CODE%TYPE;
g_location_no          xx_om_legacy_deposits.STORE_LOCATION%TYPE;
g_error_count          NUMBER;
g_process_date         DATE;
g_file_name            VARCHAR2(80);

-----------------------------------------------------------------
-- HEADER RECORD
-----------------------------------------------------------------
/* Global Record  Declaration for Header */
G_header_rec  XX_OM_SACCT_CONC_PKG.G_Header_Rec%type;

-----------------------------------------------------------------
-- SP Order Dtl RECORD
-----------------------------------------------------------------
/* SP Order Dtl Global Record Declaration */
G_SP_ord_dtl_rec  xx_om_sacct_conc_pkg.g_legacy_dep_dtls_rec%type;

/* Record Type Declaration */

-----------------------------------------------------------------
-- PAYMENTS RECORD
-----------------------------------------------------------------
/* Payment Global Record Declaration */
G_payment_rec  xx_om_sacct_conc_pkg.G_payment_rec%type;

/* Record Type Declaration */

TYPE order_rec_type IS RECORD (
      record_type        VARCHAR2(5)
    , file_line          VARCHAR2(1000)
    );

G_rec_type order_rec_type;

TYPE order_tbl_type IS TABLE OF order_rec_type INDEX BY BINARY_INTEGER;

/* RECORD TYPE DECLARATION FOR HEADER INFO TO CHILD */

PROCEDURE Process_Deposit( x_retcode           OUT NOCOPY  NUMBER
                         , x_errbuf            OUT NOCOPY  VARCHAR2
                         , p_debug_level       IN          NUMBER
                         , p_filename          IN          VARCHAR2
                         );

PROCEDURE process_header( p_order_rec   IN order_rec_type
                        , p_credit_flag OUT VARCHAR2
                        );

PROCEDURE process_sp_order_details(p_order_rec IN order_rec_type);

PROCEDURE process_payment(p_order_rec IN order_rec_type);

PROCEDURE Process_Current_Deposit( p_order_tbl   IN order_tbl_type
                                 , p_at_trailer  IN BOOLEAN
                                 );
PROCEDURE insert_data;

PROCEDURE SET_MSG_CONTEXT( p_entity_code IN VARCHAR2
                         , p_line_ref IN VARCHAR2 DEFAULT NULL
                         );

G_CREATED_BY_MODULE   CONSTANT VARCHAR2(30) := 'XXOM_HVOP_ADD';

PROCEDURE Process_Trailer( p_order_rec IN order_rec_type);

PROCEDURE apply_payment_to_prepay( p_orig_sys_document_ref     IN VARCHAR2
                                 , x_return_status            OUT VARCHAR2
                                 );

END XX_OM_HVOP_DEPOSIT_CONC_PKG;
/

SHOW ERRORS PACKAGE  XX_OM_HVOP_DEPOSIT_CONC_PKG;
EXIT;