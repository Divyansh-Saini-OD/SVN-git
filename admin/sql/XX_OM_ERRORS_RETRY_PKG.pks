SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE XX_OM_ERRORS_RETRY_PKG

-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name  : XX_OM_ERRORs_RETRY_PKG                                          |
-- | Description      : This Program will update missing info to create      |
-- |                    inventory_item_id, ship_from_org_id,sold_to_org_id   |
-- |                    invoice_ot_org_id ahip_to_org_id in interface tbls   |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |DRAFT 1A   02-JUN-2008   Bapuji Nanapaneni Initial draft version         |
-- +=========================================================================+

AS

PROCEDURE Get_orig_sys_document_ref( 
                                     errbuf        OUT NOCOPY VARCHAR2
                                    , retcode       OUT NOCOPY NUMBER
                                    , p_request_id   IN VARCHAR2
                                    );

PROCEDURE Get_10000002 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_sold_to_org_id       OUT NOCOPY NUMBER
                       , x_invoice_to_org_id    OUT NOCOPY NUMBER
                       , x_ship_to_org_id       OUT NOCOPY NUMBER
                       , x_customer_name        OUT NOCOPY VARCHAR2
                       , x_status               OUT NOCOPY VARCHAR2
                       );

PROCEDURE GET_10000015 ( p_orig_sys_documen_ref IN VARCHAR2
                       , p_orig_sys_line_ref    IN VARCHAR2
                       , p_order_source_id      IN NUMBER
                       , p_request_id           IN NUMBER
                       , p_message_number       IN VARCHAR2
                       , x_ship_from_org_id    OUT NOCOPY NUMBER
                       , x_status              OUT NOCOPY VARCHAR2
                       );

PROCEDURE Get_10000018_17 ( p_orig_sys_documen_ref IN VARCHAR2
                          , p_orig_sys_line_ref    IN VARCHAR2
                          , p_order_source_id      IN NUMBER
                          , p_request_id           IN NUMBER
                          , p_message_number       IN VARCHAR2
                          , x_inventory_item_id   OUT NOCOPY NUMBER
                          , x_ship_from_org_id    OUT NOCOPY NUMBER
                          , x_status              OUT NOCOPY VARCHAR2
                          );

PROCEDURE Get_10000010 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_sold_to_org_id       OUT NOCOPY NUMBER
                       , x_invoice_to_org_id    OUT NOCOPY NUMBER
                       , x_ship_to_org_id       OUT NOCOPY NUMBER
                       , x_customer_name        OUT NOCOPY VARCHAR2
                       , x_sold_to_contact_id   OUT NOCOPY NUMBER
                       , x_geocode              OUT NOCOPY VARCHAR2
                       , x_payment_term_id      OUT NOCOPY NUMBER
                       , x_status               OUT NOCOPY VARCHAR2
                       );

PROCEDURE Get_10000016 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_ship_to_org_id       OUT NOCOPY NUMBER
                       , x_invoice_to_org_id    OUT NOCOPY NUMBER
                       , x_geocode              OUT NOCOPY VARCHAR2
                       , x_status               OUT NOCOPY VARCHAR2
                       ) ;

PROCEDURE Get_10000021 ( p_orig_sys_document_ref IN VARCHAR2
                       , p_request_id            IN NUMBER
                       , p_order_source_id       IN NUMBER
                       , x_invoice_to_org_id     OUT NOCOPY NUMBER
                       , x_status                OUT NOCOPY VARCHAR2
                       );

PROCEDURE Get_10000022 ( p_sold_to_org_id       IN NUMBER
                       , x_shipto_org_id       OUT NOCOPY NUMBER
                       , x_status               OUT NOCOPY VARCHAR2
                       );
                       

END XX_OM_ERRORS_RETRY_PKG;
/
SHOW ERRORS PACKAGE XX_OM_ERRORS_RETRY_PKG;
EXIT;