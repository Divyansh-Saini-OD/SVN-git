create or replace 
PACKAGE BODY XX_PO_INTERFACE_PKG
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |                  WIPRO Technologies                                            |
-- +================================================================================+
-- | Name        :  XX_PO_INTERFACE_PKG.pkb                                         |
-- | Description :  The standard package PO_INTERFACE_S.CREATE_DOCUMENT is copied   |
-- |                to XX_PO_INTERFACE_PKG.CREATE_DOCUMENT,in order to insert the   |
-- |                attribute6,attribute7,attribute_category columns of             |
-- |                PO_HEADERS_INTERFACE table into PO_HEADERS_ALL table as the std |
-- |                package does not take care of inserting the attribute columns.  |
-- |                                                                                |
-- |                                                                                |
-- |  Change Record:                                                                |
-- |===============                                                                 |
-- |Rice ID    Version   Date        Author           Remarks            	    |
-- |=======    =======   ==========  =============    ==============================|
-- |                                                                                |
-- |E0216      V1.0     10-Apr-2007  SANDEEP GORLA    First Version                 |
-- |           V2.0     26-Apr-2014  Avinash          Defect 28388-Took the R12     |
-- |						      Version and customized        |
-- +================================================================================+

AS

g_pkg_name    CONSTANT VARCHAR2(30) := 'XX_PO_INTERFACE_PKG';  --<SharedProc FPJ>
g_log_head    CONSTANT VARCHAR2(30) := 'po.plsql.XX_PO_INTERFACE_PKG.';

--<ENCUMBRANCE FPJ>
g_dest_type_code_SHOP_FLOOR      CONSTANT
   PO_DISTRIBUTIONS_ALL.destination_type_code%TYPE
   := 'SHOP FLOOR'
   ;

-- <INVCONV R12>
g_chktype_TRACKING_QTY_IND CONSTANT
   MTL_SYSTEM_ITEMS_B.TRACKING_QUANTITY_IND%TYPE
   := 'PS';

-- <Unified Catalog R12>
g_ATTR_VALUES_NULL_ID CONSTANT NUMBER := PO_ATTRIBUTE_VALUES_PVT.g_ATTR_VALUES_NULL_ID;

/* Type declaration for WHO information structure */
TYPE who_record_type IS RECORD
(user_id           number := 0,
 login_id          number := 0,
 resp_id           number := 0);

/* Type declaration for  Receiving Controls structure */
TYPE rcv_controls_type IS RECORD
(enforce_ship_to_location_code  varchar2(25):= null,
 allow_substitute_receipts_flag varchar2(1),
 receiving_routing_id           number,
 qty_rcv_tolerance              number,
 qty_rcv_exception_code         varchar2(25),
 days_early_receipt_allowed     number,
 days_late_receipt_allowed      number,
 receipt_days_exception_code    varchar2(25));

/* Type declaration for Vendor defaults structure */
TYPE vendor_defaults_type IS RECORD
(vendor_id             number := null,
 ship_to_location_id   number := null,
 bill_to_location_id   number := null,
-- Bug# 4546121:All columns that referred to the obsolete columns in po_vendors have
--              been modified to point to PO_HEADERS_ALL type.
 ship_via_lookup_code  PO_HEADERS_ALL.ship_via_lookup_code%type := null,
 fob_lookup_code       PO_HEADERS_ALL.fob_lookup_code%type := null,
 pay_on_code           varchar2(25) := null,
 freight_terms_lookup_code PO_HEADERS_ALL.freight_terms_lookup_code%type := null,
 terms_id              number := null,
 type_1099             po_vendors.type_1099%type := null,
 hold_flag             po_vendors.hold_flag%type := null,
 invoice_currency_code po_vendors.invoice_currency_code%type := null,
 receipt_required_flag po_vendors.receipt_required_flag%type := null,
 num_1099              po_vendors.num_1099%type := null,
 vat_registration_num  po_vendors.vat_registration_num%type := null, --<Bug#4723671>
 inspection_required_flag po_vendors.inspection_required_flag%type := null,
 /** bgu, Dec. 7, 98
  *  Used to default invoice match flag from financial system parameter,
  *  vendor and vendor site
  */
 invoice_match_option    po_vendors.match_option%type := null,
 shipping_control      PO_VENDOR_SITES.shipping_control%TYPE := NULL -- <INBOUND LOGISTICS FPJ>
);

/* Type declaration for Item defaults structure */
/*Bug 1391523 . Added market price to the record
to default market price while autocreating */
TYPE item_defaults_type IS RECORD
(list_price_per_unit   number:=null,
 market_price          number:=null,
 taxable_flag          varchar2(1):=null,
 unit_meas_lookup_code varchar2(25):=null,
 inspection_required_flag varchar2(1):=null,
 receipt_required_flag varchar2(1):=null,
 invoice_close_tolerance number:=null,
 receive_close_tolerance number:=null,
 secondary_uom_code varchar2(3):= null, --<INVCONV R12>
 grade_control_flag varchar2(1):=null   --<INVCONV R12>
 );

/* Type declaration for  System Parameters structure */
TYPE system_parameters_type IS RECORD
(currency_code             gl_sets_of_books.currency_code%type,
 coa_id                    number,
 po_encumbrance_flag       varchar2(1),
 req_encumbrance_flag      varchar2(1),
 sob_id                    number,
 ship_to_location_id       number,
 bill_to_location_id       number,
 fob_lookup_code           financials_system_parameters.fob_lookup_code%type,
 freight_terms_lookup_code
               financials_system_parameters.freight_terms_lookup_code%type,
 terms_id                  number,
 default_rate_type         po_system_parameters.default_rate_type%type,
 taxable_flag              varchar2(1),
 receiving_flag            varchar2(1),
 enforce_buyer_name_flag   varchar2(1),
 enforce_buyer_auth_flag   varchar2(1),
 line_type_id              number := null,
 manual_po_num_type        po_system_parameters.manual_po_num_type%type,
 po_num_code               po_system_parameters.user_defined_po_num_code%type,
 price_type_lookup_code    po_system_parameters.price_type_lookup_code%type,
 invoice_close_tolerance   number,
 receive_close_tolerance   number,
 security_structure_id     number,
 expense_accrual_code      po_system_parameters.price_type_lookup_code%type,
 inventory_organization_id number,
 rev_sort_ordering         number,
 min_rel_amount            number,
 notify_blanket_flag       varchar2(1),
 budgetary_control_flag    varchar2(1),
 user_defined_req_num_code po_system_parameters.user_defined_req_num_code%type,
 rfq_required_flag         varchar2(1),
 manual_req_num_type       po_system_parameters.manual_req_num_type%type,
 enforce_full_lot_qty  po_system_parameters.enforce_full_lot_quantities%type,
 disposition_warning_flag    varchar2(1),
 reserve_at_completion_flag  varchar2(1),
 user_defined_rcpt_num_code
                       po_system_parameters.user_defined_receipt_num_code%type,
 manual_rcpt_num_type        po_system_parameters.manual_receipt_num_type%type,
 use_positions_flag      varchar2(1),
 default_quote_warning_delay number,
 inspection_required_flag    varchar2(1),
 user_defined_quote_num_code
                       po_system_parameters.user_defined_quote_num_code%type,
 manual_quote_num_type po_system_parameters.manual_quote_num_type%type,
 user_defined_rfq_num_code
                       po_system_parameters.user_defined_rfq_num_code%type,
 manual_rfq_num_type       po_system_parameters.manual_rfq_num_type%type,
 ship_via_lookup_code  financials_system_parameters.ship_via_lookup_code%type,
 qty_rcv_tolerance number,
 period_name gl_period_statuses.period_name%type,
 acceptance_required_flag po_system_parameters.acceptance_required_flag%type);   /* Bug 7518967 : Default Acceptance Required Check ER */

--<Unified Catalog R12: Start>
TYPE po_line_id_tbl IS TABLE OF PO_LINES_ALL.po_line_id%TYPE INDEX BY PLS_INTEGER;
TYPE interface_header_id_tbl IS TABLE OF PO_ATTR_VALUES_INTERFACE.interface_header_id%TYPE INDEX BY PLS_INTEGER;
TYPE interface_line_id_tbl IS TABLE OF PO_ATTR_VALUES_INTERFACE.interface_line_id%TYPE INDEX BY PLS_INTEGER;
--<Unified Catalog R12: End>

/* ecso 5/14/97
 * Add order by unit_price to interface_cursor.
 * This is for handling the case when multiple req lines with diff prices
 * are combined into one PO line. The line_num and shipment_num
 * are the same for them.
 */

/* iali 08/26/99
   Added note_to_vendor to the interface cursor
*/

/* Cursor for retrieving information from the interface tables */
CURSOR interface_cursor(x_interface_header_id number) IS
       SELECT phi.interface_header_id interface_header_id,
              phi.interface_source_code interface_source_code,
              phi.batch_id batch_id,
              phi.process_code process_code,
              phi.action action,
              phi.document_subtype document_subtype,
              phi.document_num document_num,
              phi.po_header_id po_header_id,
              phi.release_num release_num,
              phi.agent_id agent_id,
              phi.vendor_id vendor_id,
              phi.vendor_site_id vendor_site_id,
              phi.vendor_contact_id vendor_contact_id,
	      phi.vendor_contact vendor_contact,
              phi.ship_to_location_id ship_to_location_id,
              phi.bill_to_location_id bill_to_location_id,
              phi.terms_id terms_id,
              phi.freight_carrier ship_via_lookup_code,
              phi.fob fob_lookup_code,
              phi.pay_on_code pay_on_code,
              phi.freight_terms freight_terms_lookup_code,
              phi.creation_date creation_date,
              phi.created_by created_by,
              phi.last_update_date last_update_date,
              phi.last_updated_by last_updated_by,
              phi.last_update_login last_update_login,
              phi.revision_num revision_num,
              phi.print_count print_count,
              phi.closed_code h_closed_code,
              phi.frozen_flag frozen_flag,
              phi.firm_flag h_firm_status_lookup_code,
              pli.firm_flag l_firm_status_lookup_code,
              phi.confirming_order_flag confirming_order_flag,
              phi.acceptance_required_flag acceptance_required_flag,
              phi.currency_code h_currency_code,
              phi.rate_type_code h_rate_type,
              phi.rate_date h_rate_date,
              phi.rate h_rate,
              phi.min_release_amount h_min_release_amount,
              pli.min_release_amount l_min_release_amount,
              phi.release_date release_date,
              phi.document_subtype quote_type_lookup_code,
              phi.vendor_list_header_id vendor_list_header_id,
--DPCARD{
              phi.pcard_id,
--DPCARD}
              pli.interface_line_id interface_line_id,
              pli.line_num line_num,
              pli.shipment_num shipment_num,
              pli.line_location_id line_location_id,
              pli.requisition_line_id requisition_line_id,
              pli.line_type_id line_type_id,
              pli.item_id item_id,
              pli.category_id category_id,
              pli.item_revision item_revision,
              pli.item_description item_description,
              -- <FPJ Advanced Price START>
              pli.base_unit_price base_unit_price,
              -- <FPJ Advanced Price END>
              pli.unit_price unit_price,
              pli.price_type price_type_lookup_code,
              pli.unit_of_measure unit_meas_lookup_code,
              pli.un_number_id un_number_id,
              pli.hazard_class_id hazard_class_id,
              -- pli.contract_num contract_num,   -- <GC FPJ>
              pli.contract_id contract_id,         -- <GC FPJ>
              pli.vendor_product_num vendor_product_num,
              pli.type_1099 type_1099,
              pli.need_by_date need_by_date,
              pli.quantity quantity,
              pli.amount,                                     -- <SERVICES FPJ>
              pli.negotiated_by_preparer_flag negotiated_by_preparer_flag,
              pli.closed_code l_closed_code,
              pli.transaction_reason_code transaction_reason_code,
              pli.from_header_id from_header_id,
              pli.from_line_id from_line_id,
              pli.from_line_location_id from_line_location_id,-- <SERVICES FPJ>
              pli.receipt_required_flag receipt_required_flag,
--DWR4{
              pli.tax_status_indicator,
--DWR4}
              pli.tax_code_id,
        pli.note_to_vendor,
        --togeorge 09/27/2000
        --Bug#1433282
        --added note to receiver and oke columns
        pli.note_to_receiver,
        pli.oke_contract_header_id,
        pli.oke_contract_version_id,
        pdi.oke_contract_line_id,
        pdi.oke_contract_deliverable_id,
-- adding process related columns
-- start of 1548597
              pli.secondary_unit_of_measure,
              pli.secondary_quantity,
              pli.preferred_grade,
-- end of 1548597
        --<SOURCING TO PO FPH START>
        phi.amount_agreed,          --Bug# 2288408
        phi.effective_date,         --Bug# 2288408
        phi.expiration_date,        --Bug# 2288408
              pli.committed_amount,     --Bug# 2288408
              pli.promised_date promised_date,
              pli.auction_header_id,
              pli.auction_line_number,
        pli.auction_display_number,
              pli.bid_number,
              pli.bid_line_number,
        pli.orig_from_req_flag,
            pdi.charge_account_id,
        pdi.accrual_account_id,
        pdi.variance_account_id,
        pdi.encumbered_flag,
        pdi.budget_account_id,
        --<SOURCING TO PO FPH END>
        --<RENEG BLANKET FPI START>
        phi.amount_limit,
              phi.global_agreement_flag,
              pli.ship_to_location_id line_ship_to_loc_id,
              pli.ship_to_organization_id line_ship_to_org_id,
              pli.price_discount,
              pli.effective_date line_effective_date,
              pli.expiration_date line_expiration_date,
              pli.shipment_type,
              --Bug #2715037 :Need to capture this coming from Sourcing
              pli.price_break_lookup_code,
              --<RENEG BLANKET FPI END>
        pdi.destination_type_code destination_type_code,
        pdi.deliver_to_location_id deliver_to_location_id,
        pdi.destination_organization_id destination_organization_id,
              pli.vmi_flag,   --  VMI FPH
              pli.drop_ship_flag,   --  <DropShip FPJ>
        --<CONSUME REQ DEMAND FPI>
        phi.consume_req_demand_flag,
              pli.consigned_flag,      -- CONSIGNED FPI
              phi.shipping_control,    -- <INBOUND LOGISTICS FPJ>
              pli.supplier_ref_number, --<CONFIG_ID FPJ>
              pli.job_id,                                     -- <SERVICES FPJ>
              pli.contractor_first_name,                      -- <SERVICES FPJ>
              pli.contractor_last_name,                       -- <SERVICES FPJ>
        pli.transaction_flow_header_id,                 -- <Shared Proc. FPJ>
        phi.org_id                                      -- <R12 MOAC>
              --<Complex Work R12 Start>
            , phi.style_id              style_id
            , pli.retainage_rate        retainage_rate
            , pli.max_retainage_amount  max_retainage_amount
            , pli.progress_payment_rate progress_payment_rate
            , pli.recoupment_rate       recoupment_rate
            , pli.advance_amount        advance_amount
            , NVL(pli.line_loc_populated_flag, 'N') poll_interface_pop_flag
            , NVL2(pli.advance_amount, 'Y', 'N') has_advance_flag
              --<Complex Work R12 End>
              --<Unified Catalog R12 Begin: Bug#4656615>
            , phi.created_language    created_language
            , phi.cpa_reference       cpa_reference
            , pli.ip_category_id      ip_category_id
            , pli.supplier_part_auxid supplier_part_auxid
            , pli.catalog_name        catalog_name,
              --<Unified Catalog R12 End>
             phi.attribute_category, --added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07
             phi.attribute1,         --added by Paul DSouza,29-Aug-07
             phi.attribute6,         --added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07
             phi.attribute7,         --added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07
             phi.attribute8,         --added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07
             phi.attribute9          --added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07  
         FROM po_headers_interface phi,
              po_lines_interface pli,
        	po_distributions_interface pdi
        WHERE phi.interface_header_id = pli.interface_header_id
    	  AND pli.interface_line_id = pdi.interface_line_id
          AND phi.interface_header_id = x_interface_header_id
          AND pdi.interface_distribution_id =
    		(SELECT min(pdi2.interface_distribution_id)
    		   FROM   po_distributions_interface pdi2
    		  WHERE  pdi2.interface_line_id = pli.interface_line_id)
     ORDER BY pli.line_num,
        --<RENEG BLANKET FPI>
              nvl(pli.shipment_num,0),
              pli.unit_price;

/* Global variable declarations */
who who_record_type;

vendor vendor_defaults_type;

item item_defaults_type;

params system_parameters_type;

rc rcv_controls_type;

interface interface_cursor%rowtype;
--<SOURCING TO PO FPH START>
g_sourcing_errorcode number;
g_interface_source_code varchar2(25);
--<SOURCING TO PO FPH END>

g_mode              po_headers_interface.action%type := null;
g_group_code        po_headers_interface.group_code%type := null;
g_document_subtype  po_headers_interface.document_subtype%type := null;
g_po_release_id     number := null;
g_document_type     varchar2(25) := null;
g_number_records_processed number;
g_purchasing_ou_id  PO_HEADERS_ALL.org_id%TYPE;  --<Shared Proc FPJ>
g_hdr_requesting_ou_id  PO_HEADERS_ALL.org_id%TYPE;  --<Shared Proc FPJ>
g_rate_for_req_fields NUMBER;  --<Shared Proc FPJ>
g_line_requesting_ou_id PO_REQUISITION_LINES_ALL.org_id%TYPE; --<Sourcing 11.5.10+>

/* Global variable to hold number of req lines
** in the po_lines_interface table. Thie determines
** if we copy project_id, task_id from req to rfq
*/
g_req_lines_to_process  number:=0;

-- Bug 2875346 start.
--< Bug 3210331 Start >
-- Debugging booleans used to bypass logging when turned off
g_debug_stmt  CONSTANT BOOLEAN := PO_DEBUG.is_debug_stmt_on;
g_debug_unexp CONSTANT BOOLEAN := PO_DEBUG.is_debug_unexp_on;
--< Bug 3210331 End >

g_calculate_tax_flag VARCHAR2(1); --<eTax Integration Enhancement R12>


/*===========================================================================*/
/*======================== SPECIFICATIONS (PRIVATE) =========================*/
/*===========================================================================*/

-- Private function to check if a req line has a one-time location
FUNCTION has_one_time_location(p_req_line_id IN NUMBER)
    RETURN BOOLEAN;

-- Bug 2875346 end.

/*<Bug 14608120 Autocreate GE ER>
 Private function to check whether the Req has been created from WIP.*/
FUNCTION is_wip_enabled(p_req_line_id IN NUMBER)
    RETURN BOOLEAN;

/* Private Procedure prototypes */
PROCEDURE get_system_defaults;

/* bgu, Dec. 10, 98 */
PROCEDURE get_invoice_match_option(x_vendor_id    IN number,
         x_vendor_site_id IN number,
         x_invoice_match_option OUT NOCOPY varchar2);

PROCEDURE wrapup(x_interface_header_id IN number);

PROCEDURE update_shipment(x_interface_header_id IN NUMBER,
        x_po_shipment_num IN NUMBER,
        x_po_line_num IN NUMBER,
        x_requisition_line_id IN NUMBER,
        x_po_line_id IN NUMBER,
        x_document_num IN VARCHAR2,
        x_release_num IN NUMBER,
                          x_create_new_line IN VARCHAR2,  -- GA FPI
                          x_row_id IN VARCHAR2 default null);

PROCEDURE group_interface_lines(
  x_interface_header_id IN number
, p_is_complex_work_po  IN BOOLEAN
, p_group_shipments     IN VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
);

-- <Complex Work R12>: Added p_is_complex_work_po parameter
PROCEDURE setup_interface_tables(
  x_interface_header_id  IN             NUMBER
, x_document_id          IN OUT NOCOPY  NUMBER
, p_is_complex_work_po   IN             BOOLEAN
);

-- <Complex Work R12>: Added p_is_complex_work_po parameter
PROCEDURE create_line(
  x_interface_header_id IN NUMBER
, p_is_complex_work_po  IN BOOLEAN
);

PROCEDURE create_shipment(
  x_po_line_id IN number,
  p_rate_for_req_fields IN NUMBER, -- <ACHTML R12>
  x_line_location_id IN OUT NOCOPY number,
  p_outsourced_assembly IN NUMBER --<SHIKYU R12>
);

PROCEDURE create_distributions(
  x_po_line_id IN number,
  x_line_location_id IN number,
  x_po_release_id IN number,
  p_rate_for_req_fields IN NUMBER --<ACHTML R12>
);

-- <Complex Work R12 Start>
PROCEDURE create_payitems(
  p_interface_line_id IN         NUMBER
, p_po_line_id        IN         NUMBER
, p_precision         IN         NUMBER
, p_ext_precision     IN         NUMBER
, x_line_location_id  OUT NOCOPY NUMBER
, x_line_loc_id_tbl   OUT NOCOPY po_tbl_number
);

PROCEDURE create_payitem_dists(
  p_po_line_id         IN NUMBER
, p_req_line_id        IN NUMBER
, p_interface_line_id  IN NUMBER
, p_precision          IN NUMBER
, p_ext_precision      IN NUMBER
);

PROCEDURE calibrate_last_dist_quantity (
  p_line_location_id   IN   NUMBER
);

-- <Complex Work R12 End>

PROCEDURE calibrate_last_dist_amount                           -- <BUG 3322948>
(   p_line_location_id       IN       NUMBER
);

PROCEDURE create_po(x_interface_header_id IN number,
        x_document_id IN OUT NOCOPY number
           ,p_sourcing_k_doc_type  IN VARCHAR2 DEFAULT NULL --<CONTERMS FPJ>
           ,p_conterms_exist_flag  IN VARCHAR2 DEFAULT 'N'  --<CONTERMS FPJ>
     ,p_document_creation_method IN VARCHAR2 DEFAULT NULL--<DBI FPJ>
	 ,p_group_shipments IN VARCHAR2 DEFAULT NULL  --<Bug 14608120 Autocreate GE ER>
         );

PROCEDURE create_rfq(x_interface_header_id IN number,
         x_document_id IN OUT NOCOPY number);

PROCEDURE get_shipment_num(x_need_by_date IN DATE,
         x_deliver_to_location_id IN NUMBER,
         x_destination_org_id IN NUMBER,
         x_po_line_id IN NUMBER,
         x_po_line_num IN NUMBER,
         x_requisition_line_id IN NUMBER,
               x_interface_header_id IN NUMBER,
         x_po_shipment_num IN OUT NOCOPY NUMBER,
         --togeorge 09/27/2000
         x_note_to_receiver IN varchar2,
-- start of 1548597
                           x_preferred_grade IN VARCHAR2,
-- end of 15485097
                           x_vmi_flag        IN VARCHAR2,         --  VMI FPH
                           x_consigned_flag IN VARCHAR2   ,       -- CONSIGNED FPI
                           x_drop_ship_flag IN VARCHAR2,          --  <DropShip FPJ>
                           x_create_new_line OUT NOCOPY VARCHAR2,
                           x_group_shipments IN VARCHAR2 DEFAULT NULL  -- <Bug 14608120 Autocreate GE ER>
						   ) ;     -- GA FPI

-- This procedure calculate the global attribute value based on the document
-- type, level, and id.  This is just a hook to the actual function.
-- Parameter:
-- document_type: 'STANDARD', 'BLANKET', 'PLANNED', 'RELEASES'
-- level_type: 'HEADER', 'LINE', 'SHIPMENT', 'DISTRIBUTION', 'DOCUMENT'
-- level_id: ID of the relevant level: po_header_id, po_line_id,...

procedure calculate_local(document_type varchar2,
                          level_type    varchar2,
                          level_id      number
);

--<RENEG BLANKET FPI START>
PROCEDURE create_price_break(p_po_line_id IN number,
                          x_line_location_id OUT NOCOPY number,
                  p_outsourced_assembly IN NUMBER); --<SHIKYU R12>
--<RENEG BLANKET FPI END>

FUNCTION get_ship_to_loc(p_deliver_to_loc_id IN NUMBER)
RETURN NUMBER;

--<CONFIG_ID FPJ START>

FUNCTION validate_interface_records (
  p_interface_header_id IN PO_HEADERS_INTERFACE.interface_header_id%TYPE
) RETURN BOOLEAN;

FUNCTION validate_config_id (
  p_interface_header_id IN PO_HEADERS_INTERFACE.interface_header_id%TYPE
) RETURN BOOLEAN;

--<CONFIG_ID FPJ END>

-- <Complex Work R12>: Add parameters p_table_type, p_po_line_id
PROCEDURE update_award_distributions(
  p_table_type     IN    VARCHAR2   DEFAULT 'INTERFACE'
, p_po_line_id     IN    NUMBER     DEFAULT NULL
); --<GRANTS FPJ>

--<Shared Proc FPJ START>
PROCEDURE get_rate_for_req_price(
  p_requesting_ou_id IN NUMBER, -- <ACHTML R12>
  p_purchasing_ou_id IN NUMBER, -- <ACHTML R12>
  p_po_currency_code IN VARCHAR2,
  p_rate_type        IN VARCHAR2,
  p_rate_date        IN DATE,
  x_rate             OUT NOCOPY NUMBER
);
--<Shared Proc FPJ END>

PROCEDURE do_currency_conversion                               -- <BUG 3322948>
(   p_order_type_lookup_code   IN              VARCHAR2
,   p_interface_source_code    IN              VARCHAR2
,   p_rate                     IN              NUMBER
,   p_po_currency_code         IN              VARCHAR2
,   p_requisition_line_id      IN              NUMBER
,   x_quantity                 IN OUT NOCOPY   NUMBER
,   x_unit_price               IN OUT NOCOPY   NUMBER
,   x_base_unit_price          IN OUT NOCOPY   NUMBER --bug 3401653
,   x_amount                   IN OUT NOCOPY   NUMBER
);


/*===========================================================================*/
/*============================ BODY (PUBLIC) ================================*/
/*===========================================================================*/

--<SOURCING TO PO FPH START>
PROCEDURE create_documents(x_batch_id     IN     number,
         x_document_id  IN OUT NOCOPY number,
         x_number_lines   IN OUT NOCOPY number,
         p_document_creation_method IN VARCHAR2,  --<DBI FPJ>
         p_orig_org_id                IN               NUMBER DEFAULT NULL,    -- <R12 MOAC>
		 p_group_shipments            IN               VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
) IS
  x_document_number po_headers.segment1%type;
  x_errorcode   number;
  l_progress VARCHAR2(3) := '000';                          --< Bug 3210331 >
  l_api_name VARCHAR2(30) := 'create_documents(wrapper1)';  --< Bug 3210331 >
BEGIN
  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
      PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
  END IF;

  create_documents(x_batch_id => x_batch_id,
       x_document_id => x_document_id,
       x_number_lines => x_number_lines,
       x_document_number => x_document_number,
       x_errorcode => x_errorcode,
       p_document_creation_method => p_document_creation_method, --<DBI FPJ>
                   p_orig_org_id => p_orig_org_id,                 -- <R12 MOAC>
				   p_group_shipments => p_group_shipments  --<Bug 14608120 Autocreate GE ER>
       );

  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                          p_token    => l_progress,
                          p_message  => 'error code: '||x_errorcode);
      PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     po_message_s.sql_error('CREATE_DOCUMENTS wrapper',l_progress,sqlcode);
     raise;
END create_documents;
--<SOURCING TO PO FPH END>

/*============================================================================
     Name: CREATE_DOCUMENTS
     DESC: Create/Add to document from requisition data in the PO_HEADERS,LINES
           and DISTRIBUTION interface tables.
     ARGS: IN : x_batch_id IN number
--<CONTERMS FPJ START>
           IN: p_sourcing_k_doc_type   IN   VARCHAR2 - The document type that Sourcing
                             has seeded in Contracts.
                             Deafault null
          IN: p_conterms_exist_flag   IN    VARCHAR2 - Whether the sourcing document
                              has contract template attached.
                              Deafult - N
--<CONTERMS FPJ END>
     ALGR:

   ==========================================================================*/
PROCEDURE create_documents(x_batch_id     IN     number,
         x_document_id  IN OUT NOCOPY number,
         x_number_lines   IN OUT NOCOPY number,
         --<SOURCING TO PO FPH>
         x_document_number  IN OUT NOCOPY    varchar2,
         x_errorcode      OUT NOCOPY    number
              ,p_sourcing_k_doc_type  IN VARCHAR2 --<CONTERMS FPJ>
              ,p_conterms_exist_flag  IN VARCHAR2 --<CONTERMS FPJ>
         ,p_document_creation_method IN VARCHAR2 --<DBI FPJ>
              ,p_orig_org_id                IN               NUMBER DEFAULT NULL    -- <R12 MOAC>
			  ,p_group_shipments  IN VARCHAR2  DEFAULT NULL  --<Bug 14608120 Autocreate GE ER>
     ) IS
--<Shared Proc FPJ Start>
l_api_name                  VARCHAR2(30) := 'create_documents(wrapper2)'; --< Bug 3210331 >
l_return_status             VARCHAR2(1);
l_msg_count                 NUMBER;
l_msg_data                  VARCHAR2(2000);
l_req_operating_unit_id     PO_SYSTEM_PARAMETERS_ALL.org_id%TYPE;
l_purch_operating_unit_id   PO_SYSTEM_PARAMETERS_ALL.org_id%TYPE;
l_progress VARCHAR2(3) := '000';                            --< Bug 3210331 >

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    create_documents (p_api_version             => 1.0,
                      x_return_status           => l_return_status,
                      x_msg_count               => l_msg_count,
                      x_msg_data                => l_msg_data,
                      p_batch_id                => x_batch_id,
                      p_req_operating_unit_id   => l_req_operating_unit_id,
                      p_purch_operating_unit_id => l_purch_operating_unit_id,
                      x_document_id             => x_document_id,
                      x_number_lines            => x_number_lines,
                      x_document_number         => x_document_number
                     ,p_sourcing_k_doc_type     => p_sourcing_k_doc_type--<CONTERMS FPJ>
                     ,p_conterms_exist_flag     => p_conterms_exist_flag--<CONTERMS FPJ>
                     ,p_document_creation_method => p_document_creation_method --<DBI FPJ>
                     ,p_orig_org_id              => p_orig_org_id                 -- <R12 MOAC>
					 ,p_group_shipments          => p_group_shipments  --<Bug 14608120 Autocreate GE ER>
                     );

    IF (l_return_status = FND_API.g_ret_sts_success
        AND x_number_lines >0 AND x_document_id is NOT NULL) --<Bug 3268483>
    THEN
         x_errorcode := 1;
    ELSIF g_sourcing_errorcode = 2 THEN
         x_errorcode := 2;
    ELSE
         x_errorcode := 3;
    END IF;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'error code: '||x_errorcode);
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF g_debug_unexp THEN          --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                               p_progress => l_progress);
        END IF;
        PO_MESSAGE_S.sql_error (routine    => 'CREATE_DOCUMENTS',
                                location   => l_progress,
                                error_code => SQLCODE
        );
        RAISE;

END create_documents;



-------------------------------------------------------------------------------
--Start of Comments
--Name: create_documents
--Pre-reqs:
--  None
--Modifies:
--  Transaction tables for the requested document
--Locks:
--  None.
--Function:
--  Creates/Adds To a Document. Can create Purchase Orders, Blankets, Global Agreements,
--  RFQs, Consumption Advice among others
--Parameters:
--IN:
--p_api_version
--  API standard IN parameter
--p_batch_id
--  The id that will be used to identify the rows in the interface table. The unique identifier
--  for the all the documents to be created. It will be the same as interface_header_id
--  as we always create 1 doc at a time.
--p_req_operating_unit_id
--   The Operating Unit of Requisition raising Operating Unit, or the current Operating Unit
--   of the environment if called from Oracle Sourcing 11.5.10+ and beyond
--p_purch_operating_unit_id
--   The Operating Unit where the PO is being created
--p_sourcing_k_doc_type   --<CONTERMS FPJ>
--   The document type that Sourcing has seeded in Contracts. --<CONTERMS FPJ>
--   Valid only When called from Sourcing --<CONTERMS FPJ>
--   Default value Null  --<CONTERMS FPJ>
--p_conterms_exist_flag   --<CONTERMS FPJ>
--   Whether the sourcing document has contract template attached. --<CONTERMS FPJ>
--   Valid only When called from Sourcing--<CONTERMS FPJ>
--   Default value N  --<CONTERMS FPJ>
--INOUT:
--x_document_id
--   Used as IN  for document id to ADD to N/A for sourcing.
--   Used as OUT for returning the id of the document created.
--OUT:
--x_return_status
--   The standard OUT parameter giving return status of the API call.
--x_msg_count
--   The count of number of messages added to the message list in this call
--x_msg_data
--   If the count is 1 then x_msg_data contains the message returned
--x_number_lines
--   Returns the number of interface records processed
--x_document_number
--   Returns the PO/Blanket number when for sourcing, null for existing autocreate.
--Notes:
--   None
--Testing:
--  None
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE create_documents (
    p_api_version                IN               NUMBER,
    x_return_status              OUT    NOCOPY    VARCHAR2,
    x_msg_count                  OUT    NOCOPY    NUMBER,
    x_msg_data                   OUT    NOCOPY    VARCHAR2,
    p_batch_id                   IN               NUMBER,
    p_req_operating_unit_id      IN               NUMBER,
    p_purch_operating_unit_id    IN               NUMBER,
    x_document_id                IN OUT NOCOPY    NUMBER,
    x_number_lines               OUT    NOCOPY    NUMBER,
    x_document_number            OUT    NOCOPY    VARCHAR2
   ,p_sourcing_k_doc_type        IN               VARCHAR2 --<CONTERMS FPJ>
   ,p_conterms_exist_flag        IN               VARCHAR2 --<CONTERMS FPJ>
   ,p_document_creation_method   IN               VARCHAR2 --<DBI FPJ>
   ,p_orig_org_id                IN               NUMBER DEFAULT NULL    -- <R12 MOAC>
   ,p_group_shipments            IN               VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
   ) IS

--<Shared Proc FPJ End>
    x_errorcode NUMBER;  --<temp added>
    x_interface_header_id number:= 0;
    x_unique_document_num boolean;
    x_release_number  number;   -- CONSIGNED FPI

    l_api_name    CONSTANT VARCHAR2(30) := 'create_documents';
    --<Shared Proc FPJ Start>
    l_api_version     CONSTANT NUMBER := 1.0;
    l_original_operating_unit_id    NUMBER;
    l_org_context_changed    VARCHAR2(1) := 'N';
    l_req_operating_unit_id     PO_SYSTEM_PARAMETERS_ALL.org_id%TYPE;
    l_purch_operating_unit_id   PO_SYSTEM_PARAMETERS_ALL.org_id%TYPE;

    --<Shared Proc FPJ End>
    l_progress VARCHAR2(3) := '000';            --< Bug 3210331 >

BEGIN
    --<Shared Proc FPJ Start>
      -- Standard Start of API savepoint
      SAVEPOINT create_documents_pvt;

    -- Standard call to check for call compatibility.
    IF NOT FND_API.compatible_api_call (
               p_current_version_number => l_api_version,
               p_caller_version_number  => p_api_version,
               p_api_name               => l_api_name,
               p_pkg_name               => g_pkg_name
           )
    THEN
        RAISE FND_API.g_exc_unexpected_error;
    END IF;

    l_progress := '010';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    -- Bug 4778867:If p_orig_org_id is not specified get the current
    -- Operating Unit Info from the Environment
    --<R12 MOAC START>
    IF p_orig_org_id IS NOT NULL THEN
      l_original_operating_unit_id := p_orig_org_id;
    ELSE
      l_original_operating_unit_id := po_moac_utils_pvt.get_current_org_id;
    END IF;
    --<R12 MOAC END>

    l_progress := '020';

    -- If requesting Org ID is not passed set it to  current operating unit id
    IF (p_req_operating_unit_id IS NULL) THEN
        l_req_operating_unit_id := l_original_operating_unit_id;
    ELSE
        l_req_operating_unit_id := p_req_operating_unit_id;
    END IF;

    -- If purchasing Org ID is not passed then create PO in Req raising Operating Unit
    IF (p_purch_operating_unit_id IS NULL) THEN
        l_purch_operating_unit_id := l_req_operating_unit_id;
    ELSE
        l_purch_operating_unit_id := p_purch_operating_unit_id;
    END IF;

    --Set the context of Purchasing Operating Unit
    -- <ACHTML R12 START>
    -- Modified if condition to also return true if l_purch_operating_unit_id
    -- is not null but l_req_operating_unit_id is null.
    IF (l_purch_operating_unit_id IS NOT NULL
  AND (l_req_operating_unit_id IS NULL
       OR l_purch_operating_unit_id <> l_req_operating_unit_id))
    THEN
        l_org_context_changed := 'Y';
        PO_MOAC_UTILS_PVT.set_org_context(l_purch_operating_unit_id) ;       -- <R12 MOAC>
    END IF;

    -- Initialize API return status to success
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Initialize the Operating Units
    g_purchasing_ou_id := l_purch_operating_unit_id;
    g_hdr_requesting_ou_id := l_req_operating_unit_id;

    --<Shared Proc FPJ End>

    g_number_records_processed := 0;
    g_req_lines_to_process:=0;

    l_progress:='030';

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Before select min interface header for batch_id: '||p_batch_id);
    END IF;

    /* For now a batch has only one header, so get the document header id */
       SELECT min(interface_header_id)
       INTO x_interface_header_id
       FROM po_headers_interface
       WHERE batch_id = p_batch_id;  --<Shared Proc FPJ>

    l_progress:='040';
    --<SOURCING TO PO FPH>
    /* determine whether the document to be created is a PO,PA or an RFQ */
    --<CONFIG_ID FPJ>
    --Modified the select statement to select document_subtype as well.
    SELECT document_type_code,document_subtype,nvl(interface_source_code,'NOCODE')
      INTO g_document_type,g_document_subtype,g_interface_source_code
      FROM po_headers_interface
     WHERE interface_header_id = x_interface_header_id;

     --<eTax Integration R12> Populate global variable to indicate whether
     -- tax is calculated for this document type

     IF (g_document_type = 'PO' and
        g_document_subtype in ('STANDARD', 'PLANNED', 'RELEASE')) THEN
        g_calculate_tax_flag := 'Y';
     END IF;


    l_progress := '050';
    --<SOURCING TO PO FPH START>
    --Check for the uniqueness of the document number if manual numbering.
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Document type is :'||g_document_type);
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-1 starts');
    END IF;

    if g_interface_source_code='SOURCING' then
       --Since we allowe cancellation and finally close of reqs it's possible
       --that the requistion reference sourcing passed to interface tables
       --are already cancelled or finally closed.
       --So we update the requisition line ids of such interface line
       --records before starting the process. And treat them as non req
       --backing negotiations.

       --<CONSUME REQ DEMAND FPI>
       --In FPI sourcing places the reqs back to pool at the time of splitting.
       --By the time if some one has place these reqs on another PO document
       --or sourcing doc autocreate should treat it as not backed by a req.
       --Included the where clause
       --a."prl.line_location_id is not null"
       --b."(prl.auction_header_id<>pli.auction_header_id
       --     and prl.auction_line_number<>pli.auction_line_number)" in the
       --following sql.

       l_progress:='060';
       update po_lines_interface pli
          set pli.requisition_line_id= null
        where pli.interface_header_id= x_interface_header_id
          and exists
   (select requisition_line_id
            from po_requisition_lines_all prl  --<Shared Proc FPJ>
     where prl.requisition_line_id= pli.requisition_line_id
       and (prl.line_location_id is not null
            or prl.cancel_flag='Y'
      or prl.closed_code='FINALLY CLOSED'
      or (prl.auction_header_id<>pli.auction_header_id
           and prl.auction_line_number<>pli.auction_line_number
         )
     )
   );

       l_progress := '070';
       --bug#2729465, with drawn req lines are deleted from po_requisition_lines
       --table. Hence require a separate update.
       IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
           PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                               p_token    => l_progress,
                               p_message  => 'Sourcing to PO FPH-1: before the update for withdrawn reqs');
       END IF;

       UPDATE po_lines_interface pli
          SET pli.requisition_line_id= null
        WHERE pli.interface_header_id= x_interface_header_id
          AND NOT EXISTS
   (SELECT requisition_line_id
            FROM po_requisition_lines_all prl  --<Shared Proc FPJ>
     WHERE prl.requisition_line_id= pli.requisition_line_id);

    end if;

    l_progress := '080';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-1 Ends');
    END IF;
    --<SOURCING TO PO FPH END>



    /* Enhancement Request from Proj Manufacturing ecso 10/22/97
     * Count number of req lines in the line interface table
     * This is used to determine whether we will copy
     * project/task reference from RFQ to Quote
     */
    SELECT count(*)
      INTO g_req_lines_to_process
      FROM po_lines_interface
     WHERE interface_header_id = x_interface_header_id;

    l_progress:='090';

    -- <CONFIG_ID FPJ>
    IF ( validate_interface_records(x_interface_header_id) ) THEN
      -- Only create the document if the interface records pass the validations.

      /* Call the appropriate function based on the document type */
      --<SOURCING TO PO FPH>
      --We are modifying the procedure create_po to create Blanket also.
      --So Modify the following IF clause accordingly.
      --IF(g_document_type = 'PO') THEN
      IF(g_document_type in ('PO','PA')) THEN

        l_progress := '100';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Before create_po:');
        END IF;

        create_po(x_interface_header_id, x_document_id
                 ,p_sourcing_k_doc_type --<CONTERMS FPJ>
                 ,p_conterms_exist_flag --<CONTERMS FPJ>
     ,p_document_creation_method --<DBI FPJ>
	 ,p_group_shipments  --<Bug 14608120 Autocreate GE ER>
                 );


      ELSE

        l_progress := '110';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Before create_rfq:');
        END IF;

        create_rfq(x_interface_header_id, x_document_id);

      END IF;

    END IF; -- <CONFIG_ID FPJ> validate_interface

    -- Copy the number of requisition lines processed back to
    -- the client side.
    x_number_lines := g_number_records_processed;

    l_progress:='120';
    --<SOURCING TO PO FPH>
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH -2 starts');
    END IF;

    if g_interface_source_code  in ('SOURCING','CONSUMPTION_ADVICE') then   -- CONSIGNED FPI
       if x_number_lines>0 and x_document_id is not null then
          begin
        x_errorcode :=1;  --success.
        x_return_status := FND_API.G_RET_STS_SUCCESS ; --<Shared Proc FPJ>

       /* CONSIGNED FPI start : return the release number for the release */
       IF g_document_subtype = 'RELEASE' THEN
            l_progress:= '130';
            select release_num
        into x_release_number
            from po_releases_all  --<Shared Proc FPJ>
            where po_release_id=x_document_id;

         x_document_number := interface.document_num || '-' || to_char(x_release_number);

       ELSE
            l_progress:= '140';
           select segment1
       into x_document_number
           from po_headers_all  --<Shared Proc FPJ>
           where po_header_id=x_document_id;

       END IF;
       /* CONSIGNED FPI end */

          exception
           when others then
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            wrapup(x_interface_header_id);
            --<Shared Proc FPJ Start>
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR;

            --set the org context back to original one
            IF (l_org_context_changed = 'Y') THEN
                PO_MOAC_UTILS_PVT.set_org_context(l_original_operating_unit_id) ;       -- <R12 MOAC>
            END IF;
            --<Shared Proc FPJ End>
            po_message_s.sql_error('CREATE_DOCUMENTS',l_progress,sqlcode);
            raise;
          end;
       else
         if g_sourcing_errorcode =2 then
            --this will be set to 2 when dup_val_on_idex happen in create_po.
            x_errorcode:=2;
            x_return_status := PO_INTERFACE_S.G_RET_STS_DUP_DOC_NUM ; --<Shared Proc FPJ>
         else
            --when 0 lines are created, we assume that there is some erro happened
            --which is not related to manual PO numbering.
            x_errorcode:=3;
            x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ; --<Shared Proc FPJ>
         end if;
       end if; --Num_line_checked
    --<Shared Proc FPJ START>
    else --Calls other than Sourcing and Consumption Advice
       if x_number_lines>0 and x_document_id is not null then
          x_return_status := FND_API.G_RET_STS_SUCCESS ;
          -- <ACHTML R12 START>
          -- Need to populate document number for autocreate success message
          IF g_document_subtype = 'STANDARD' THEN
            select segment1
            into x_document_number
            from po_headers_all
            where po_header_id = x_document_id;
    END IF;
          -- <ACHTML R12 END>
       else
          x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
       end if;
    end if; --check doc type
    --<Shared Proc FPJ END>

    l_progress:= '150';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-2 Ends');
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_documents: number of records processed: '||x_number_lines);
    END IF;

   /* CONSIGNED FPI Start : A consumption advice PO should always be created in an approved status.
      so update the header with 'approved' status and the shipment with the approved flag */

      IF (g_interface_source_code  = 'CONSUMPTION_ADVICE') and
         (x_errorcode = 1      )                          THEN

        IF g_document_subtype = 'STANDARD' THEN

          l_progress:= '160';
          update po_headers_all
          set authorization_status = 'APPROVED',
          approved_date = sysdate,
          approved_flag = 'Y'
          where po_header_id = x_document_id;

          update po_line_locations_all
          set approved_flag = 'Y',
              approved_date = sysdate
          where po_header_id = x_document_id ;

        ELSIF g_document_subtype = 'RELEASE'  THEN

          l_progress:= '170';
          update po_releases_all
          set authorization_status = 'APPROVED',
          approved_date = sysdate,
          approved_flag = 'Y'
          where po_release_id = x_document_id;

          update po_line_locations_all
          set approved_flag = 'Y',
              approved_date = sysdate
          where po_release_id = x_document_id ;

        END IF;

     END IF;

    /* CONSIGNED FPI END */
    l_progress:= '180';

    --<Shared Proc FPJ Start>
    --set the org context back to original one
    IF (l_org_context_changed = 'Y') THEN
        PO_MOAC_UTILS_PVT.set_org_context(l_original_operating_unit_id) ;       -- <R12 MOAC>
    END IF;
    --<Shared Proc FPJ End>

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;

EXCEPTION

  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(x_interface_header_id);

    --<Shared Proc FPJ Start>
     x_return_status := FND_API.G_RET_STS_UNEXP_ERROR ;
    --<Bug 3491323 mbhargav START>
     x_number_lines :=  g_number_records_processed;
     x_document_id := null;
     x_document_number := null;
    --<Bug 3491323 mbhargav END>

     --set the org context back to original one
     IF (l_org_context_changed = 'Y') THEN
         PO_MOAC_UTILS_PVT.set_org_context(l_original_operating_unit_id) ;       -- <R12 MOAC>
     END IF;
    --<Shared Proc FPJ End>

     po_message_s.sql_error('CREATE_DOCUMENTS',l_progress,sqlcode);

     --<Bug 3336920 mbhargav START>
     --No need to raise as we are setting the return status and error msg
     --raise;
     IF FND_MSG_PUB.check_msg_level(FND_MSG_PUB.g_msg_lvl_unexp_error) THEN
               FND_MSG_PUB.add_exc_msg(G_PKG_NAME, l_api_name,
                     SUBSTRB (SQLERRM , 1 , 200) || ' at location ' || l_progress);
     END IF;
     x_msg_data := FND_MSG_PUB.GET(p_msg_index => FND_MSG_PUB.G_LAST,
            p_encoded => 'F');
     --<Bug 3336920 mbhargav END>

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;

END create_documents;



/*===========================================================================*/
/*============================ BODY (PRIVATE) ===============================*/
/*===========================================================================*/

/* ============================================================================
     NAME: CREATE_PO
     DESC: Create/Add to PO from requisition data in the PO_HEADERS,LINES
           and DISTRIBUTION interface tables.
     ARGS: IN : x_interface_header_id IN number
--<CONTERMS FPJ START>
           IN: p_sourcing_k_doc_type   IN   VARCHAR2 - The document type that Sourcing
                             has seeded in Contracts.
                             Deafault null
          IN: p_conterms_exist_flag   IN    VARCHAR2 - Whether the sourcing document
                              has contract template attached.
                              Deafult - N
--<CONTERMS FPJ END>
     ALGR:

   ==========================================================================*/
PROCEDURE create_po(x_interface_header_id IN number,
        x_document_id IN OUT NOCOPY number
           ,p_sourcing_k_doc_type  IN VARCHAR2 --<CONTERMS FPJ>
           ,p_conterms_exist_flag  IN VARCHAR2 --<CONTERMS FPJ>
     ,p_document_creation_method IN VARCHAR2 --<DBI FPJ>
	 ,p_group_shipments IN VARCHAR2  DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
         ) IS
x_max_revision_num number := null;

-- Bug 902976, zxzhang, 10/04/99
-- Change REVISED_DATE from VarChar(25) to Date.
-- x_new_revised_date varchar2(25):= null;
x_new_revised_date Date := null;

X_line_found varchar2(1) := 'N';
x_release_num number;

x_document_num po_headers.segment1%type:=null; -- Bug 1093645

l_api_name CONSTANT VARCHAR2(30) := 'create_po';

x_org_id  number;
/*bug # 2997337 */
  x_valid_ship_to po_headers.ship_to_location_id%TYPE;
  x_valid_bill_to po_headers.bill_to_location_id%TYPE;
  x_is_valid VARCHAR(1) := 'N';
/*bug # 2997337 */

--<Bug 3054563 mbhargav START>
l_org_assign_rec   po_ga_org_assignments%ROWTYPE;
l_org_row_id       varchar2(30);
l_return_status     varchar2(1);
--<Bug 3054563 mbhargav END>

--<MRC FPJ Start>
l_msg_data VARCHAR2(2000);
l_msg_count NUMBER;
--<MRC FPJ End>

--<CONTERMS FPJ START>
l_contracts_call_exception Exception;
--For using %type, dependence on OKC tables. Consider for refactor
l_contract_doc_type    VARCHAR2(150);
--<CONTERMS FPJ END>
l_document_creation_method po_headers_all.document_creation_method%type := p_document_creation_method; --<DBI FPJ>
l_progress VARCHAR2(3) := '000';            --< Bug 3210331 >

l_terms_id                   PO_HEADERS.terms_id%TYPE;
l_fob_lookup_code            PO_HEADERS.fob_lookup_code%TYPE;
l_freight_lookup_code        PO_HEADERS.freight_terms_lookup_code%TYPE;
l_ship_via_lookup_code       PO_HEADERS_ALL.ship_via_lookup_code%TYPE;
l_vs_terms_id                   PO_HEADERS.terms_id%TYPE;
l_vs_fob_lookup_code            PO_HEADERS.fob_lookup_code%TYPE;
l_vs_freight_lookup_code        PO_HEADERS.freight_terms_lookup_code%TYPE;
l_vs_ship_via_lookup_code       PO_HEADERS_ALL.ship_via_lookup_code%TYPE;

l_is_complex_work_po         BOOLEAN := FALSE;  -- <Complex Work R12>
l_style_id                   NUMBER;            -- <Complex Work R12>
tax_document_id              NUMBER;

--<Bug :11071489 REQ_AUTOCREATE Start>--
l_parameter_list  PO_CORE_S4.p_parameter_list;
l_event_name VARCHAR2(100);
--<REQ_AUTOCREATE END>--

----10214347
l_doc_type  VARCHAR2(20);
l_keep_summary VARCHAR2(10);

--<Bug 13542989 :START>
l_default_method VARCHAR2(30);
l_email_address  PO_VENDOR_SITES_ALL.email_address%TYPE;
l_fax_number     VARCHAR2(100);
l_document_num   PO_HEADERS_ALL.segment1%TYPE;
--<Bug 13542989 :START>
l_vendor_id PO_VENDOR_SITES_ALL.vendor_id%TYPE; -- bug 14080332
l_vendor_site_id PO_VENDOR_SITES_ALL.vendor_site_id%TYPE; -- bug 14080332

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;
    --<R12 eTax Integration Start>
    SAVEPOINT TAX_CALCULATION_ERROR;

   /*Bug 4314776:Requisition import errors out with unique constraint voilation
   error on po_requsition_header_id when the create_po raises an unhandled exception.
   Establishing a savepoint here so that when an exception is raised in create_po
   procedure it will be rolled back to  this savepoint */

   savepoint create_po;    --Bug 4314776

    --<R12 eTax Integration End>
    get_system_defaults;

    -- <Complex Work R12 Start>
    SELECT phi.style_id
    INTO l_style_id
    FROM po_headers_interface phi
    WHERE phi.interface_header_id = x_interface_header_id;

    IF (l_style_id IS NOT NULL) THEN
      l_is_complex_work_po := PO_COMPLEX_WORK_PVT.is_complex_work_style(
                                p_style_id => l_style_id
                              );
    ELSE
      l_is_complex_work_po := FALSE;
    END IF;
    -- <Complex Work R12 End>

    -- populate the interface tables with data from the
    -- requisition.

    l_progress := '010';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create PO: Before setup interface table');
    END IF;

    l_progress:='020';
    -- <Complex Work R12 Start>: Pass in l_is_complex_work_po
    setup_interface_tables(
      x_interface_header_id => x_interface_header_id
    , x_document_id => x_document_id
    , p_is_complex_work_po => l_is_complex_work_po
    );
    -- <Complex Work R12 End>: Pass in l_is_complex_work_po

    -- determine which interface lines and shipments should
    -- be grouped.
    l_progress := '030';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create PO: Before Group interface lines');
    END IF;

    --<RENEG BLANKET FPI START>
    -- DO not do grouping if document is Blanket and request is coming from Sourcing
    if (g_document_type <> 'PA') then
        group_interface_lines(
          x_interface_header_id => x_interface_header_id
        , p_is_complex_work_po  => l_is_complex_work_po
		, p_group_shipments     => p_group_shipments --<Bug 14608120 Autocreate GE ER>
        );
    end if;
    --<RENEG BLANKET FPI END>

    l_progress := '040';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create PO: After Group interface lines');
    END IF;

    -- If the document type is Release, then do not continue
    -- processing if there are no lines with a line number
    -- This means that none of the requisition lines matched
    -- the blanket line.  We do not want to create the release.
    IF (g_document_subtype='RELEASE')THEN

       BEGIN

          l_progress := '050';
          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
              PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                  p_token    => l_progress,
                                  p_message  => 'Create po: Interface header id is '|| x_interface_header_id);
          END IF;

          select distinct 'Y'
          into   X_line_found
          from   po_lines_interface
          where  interface_header_id = x_interface_header_id
          and    line_num is not null;

          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
              PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                  p_token    => l_progress,
                                  p_message  => 'Create PO : Line found in po_lines_interfaces');
          END IF;

       EXCEPTION
          WHEN OTHERS THEN
              IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                  PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress);
              END IF;
              wrapup(x_interface_header_id);
              RAISE;
       END;

    END IF;

    l_progress := '060';
    OPEN interface_cursor(x_interface_header_id);

    FETCH interface_cursor INTO interface;

    IF interface_cursor%notfound THEN
      CLOSE interface_cursor;
      RETURN;
    END IF;


/* Bug 2786897: Start
   Prior the fix the following code was getting executed only when
   a new PO was created through autocreate. It should get executed
   while adding requisition lines to an existing PO also.  Hence
   shifting the following piece of code out of the 'IF' condition
   on 'g_mode'
*/

    l_progress := '070';
    IF(interface.vendor_id is not null) THEN

    /*Bug 5715411 Null out the vendor record details as it is global record type */
       vendor.ship_via_lookup_code := null;
       vendor.fob_lookup_code := null;
       vendor.freight_terms_lookup_code := null;
       vendor.terms_id := null;
       /*Bug 5715411 end */

          po_vendors_sv.get_vendor_info
                           (interface.vendor_id,
                            vendor.ship_to_location_id,
                            vendor.bill_to_location_id,
                            l_ship_via_lookup_code,
                            l_fob_lookup_code,
                            l_freight_lookup_code,
                            l_terms_id,
                            vendor.type_1099,
                            vendor.hold_flag,
                            vendor.invoice_currency_code,
                            vendor.receipt_required_flag,
                            vendor.num_1099,
                            vendor.vat_registration_num,
                            vendor.inspection_required_flag);

         IF(interface.vendor_site_id is not null) THEN
                  po_vendor_sites_sv.get_vendor_site_info
                              (interface.vendor_site_id,
                               vendor.ship_to_location_id,
                               vendor.bill_to_location_id,
                               l_vs_ship_via_lookup_code,
                               l_vs_fob_lookup_code,
                               vendor.pay_on_code,
                               l_vs_freight_lookup_code,
                               l_vs_terms_id,
                               vendor.invoice_currency_code,
                               vendor.shipping_control    -- <INBOUND LOGISTICS FPJ>
                              );

                  -- Bug 3807992 start : Do not override the following terms with null
                  -- values. If the site has values validate them. If not valid take the
                  -- values from the vendor and validate them

                  -- Validate ship via
                  if l_vs_ship_via_lookup_code is not null then
                     po_vendors_sv.val_freight_carrier(l_vs_ship_via_lookup_code,
                                                       params.inventory_organization_id,
                                                       vendor.ship_via_lookup_code);
                  end if;

                  if vendor.ship_via_lookup_code is null then
                     po_vendors_sv.val_freight_carrier(l_ship_via_lookup_code,
                                                       params.inventory_organization_id,
                                                       vendor.ship_via_lookup_code);
                  end if;

                  -- Validate fob code
                  if l_vs_fob_lookup_code is not null then
                     po_vendors_sv.val_fob(l_vs_fob_lookup_code,vendor.fob_lookup_code);
                  end if;

                  if vendor.fob_lookup_code is null then
                     po_vendors_sv.val_fob(l_fob_lookup_code,vendor.fob_lookup_code);
                  end if;

                  -- Validate freight terms
                  if l_vs_freight_lookup_code is not null then
                     po_vendors_sv.val_freight_terms(l_vs_freight_lookup_code,
                                                     vendor.freight_terms_lookup_code);
                  end if;

                  if vendor.freight_terms_lookup_code is null then
                     po_vendors_sv.val_freight_terms(l_freight_lookup_code,
                                                     vendor.freight_terms_lookup_code);
                  end if;

                  -- Validate payment terms
                  if l_vs_terms_id is not null then
                     po_terms_sv.val_ap_terms(l_vs_terms_id,vendor.terms_id);
                  end if;

                  if vendor.terms_id is null then
                     po_terms_sv.val_ap_terms(l_terms_id,vendor.terms_id);
                  end if;
                  -- Bug 3807992 end

		  -- bug 13091785
                  if interface.vendor_contact_id is null then
                     po_vendor_contacts_sv.get_vendor_contact(interface.vendor_site_id,
                                             interface.vendor_contact_id,
                                             interface.vendor_contact);
                  end if;

                  --  Bug 2816396 START
                  --  Default the pay_on_code for a Standard PO based
                  --  on the vendor site value.
                  if (vendor.pay_on_code = 'RECEIPT_AND_USE') then
                     vendor.pay_on_code := 'RECEIPT';
                  elsif (vendor.pay_on_code = 'USE') then
                     vendor.pay_on_code := null;
                  end if;
                  -- Bug 2816396 END

         END IF;
    END IF;

/* Bug 2786897: End */
    l_progress := '080';

   --<Sourcing 11.5.10+> If called from Sourcing, simply assign interface.h_rate to
   -- g_rate_for_req_fields
   --<Shared Proc FPJ START>
   IF (g_interface_source_code <> 'SOURCING'
       AND g_purchasing_ou_id <> g_hdr_requesting_ou_id
       AND interface.document_subtype = 'STANDARD')
   THEN
     get_rate_for_req_price(
       p_requesting_ou_id => g_hdr_requesting_ou_id, -- <ACHTML R12>
       p_purchasing_ou_id => g_purchasing_ou_id, -- <ACHTML R12>
       p_po_currency_code => interface.h_currency_code,
       p_rate_type        => interface.h_rate_type,
       p_rate_date        => interface.h_rate_date,
       x_rate             => g_rate_for_req_fields
     );
     IF g_rate_for_req_fields IS NULL
     THEN
       g_rate_for_req_fields := interface.h_rate;
     END IF;
   ELSE
     g_rate_for_req_fields := interface.h_rate;
   END IF;
   --<Shared Proc FPJ END>

    l_progress := '090';

    IF (g_mode = 'ADD') THEN

      -----------10214347START
        -- Only clear amendment for PO/PA
            IF ((g_document_type = 'PO') OR (g_document_type = 'PA')) THEN

              -- p_doc_type is always passed as 'PO' regardless of the subtype
              -- Should set doc_type to PA for Blanket and Contract
              IF (g_document_subtype IN ('BLANKET', 'CONTRACT')) THEN
                l_doc_type := 'PA';
              ELSE
                l_doc_type := 'PO';
              END IF; /*IF (p_doc_subtype IN ('BLANKET', 'CONTRACT'))*/

              -- Call Clear_Amendment at the time of creating new revision.
              -- o If the pervious version is approved or require-reapproval
              --   the call OKC_TERMS_VERSION_GRP.CLEAR_AMENDMENT() with
              --   p_keey_summary = 'N'
              -- o Else call OKC_TERMS_VERSION_GRP.CLEAR_AMENDMENT() with
              --   p_keey_summary = 'Y'
              BEGIN
                SELECT 'N'
                INTO   l_keep_summary
                FROM   dual
                WHERE  exists (SELECT 'approved document'
                               FROM   po_headers
                               WHERE  po_header_id = interface.po_header_id
                               AND    NVL(approved_flag, 'N') IN ('R', 'Y'));
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  l_keep_summary := 'Y';
              END;


             /* IF g_fnd_debug = 'Y' THEN
     	   IF (FND_LOG.G_CURRENT_RUNTIME_LEVEL <= FND_LOG.LEVEL_STATEMENT) THEN
     	     FND_LOG.string(FND_LOG.LEVEL_STATEMENT, c_log_head || l_api_name||'.'
     	     || l_progress, 'Call OKC_TERMS_VERSION_GRP.clear_amendment '
     	     || ' p_doc_id:' || interface.po_header_id
     	     || ' g_document_type:' || (l_doc_type ||'_'||g_document_subtype)
     	     || ' p_keep_summary:' || l_keep_summary);
     	   END IF;
     	 END IF; */

              -- Calls Contracts API to clear Amendment related columns
              OKC_TERMS_VERSION_GRP.clear_amendment(
                p_api_version   => 1.0,
                p_init_msg_list => FND_API.G_FALSE,
                p_commit        => FND_API.G_FALSE,
                x_return_status => l_return_status,
                x_msg_data      => l_msg_data,
                x_msg_count     => l_msg_count,
                p_doc_type      => (l_doc_type ||'_'||g_document_subtype),
                p_doc_id        => interface.po_header_id,
                p_keep_summary  => l_keep_summary);

            END IF; /*IF ((g_document_type = 'PO') OR (g_document_type = 'PA'))*/

	    -----------10214347END


/*Bug no 718918:sarunach
   The x_new_revised_date was added for bug no 491306 to update
   the revised_date.But it was inside the loop for standard and planned
   po's only.So the revised_date was Releases was incorrect.
   Removed those line and put it here to update the revised date for
   Standard,planned and Releases.
*/
-- Bug 902976, zxzhang, 10/04/99
-- Change REVISED_DATE from VarChar(25) to Date.
/*
          x_new_revised_date := to_char(interface.last_update_date,
                                      'DD/MM/YYYY HH24:MI');
*/
    x_new_revised_date := interface.last_update_date;

       /* Bug# 1734108
       * When a line was added to a existing PO the invoice_match_option
       * was not Calculated. This resulted in creating shipments with
       * invoice_match_option as NULL. Due to this when navigating out of
       * Shipment Window we get the Error "FRM-40202:  Field must be
       * entered"
       * Default invoice match flag in turn from vendor site, vendor and
       * Financial system in that Order.
       */
       if g_interface_source_code  <> 'CONSUMPTION_ADVICE' then   -- bug 2741985
           get_invoice_match_option(interface.vendor_id,
                 interface.vendor_site_id,
               vendor.invoice_match_option);
       end if;

       IF(interface.document_subtype = 'STANDARD' or
          interface.document_subtype = 'PLANNED') THEN

          l_progress:='100';

          /*
          ** Get the max revision that exists in the archive
          ** table for this purchase order.  We will compare
          ** this against the current revision on the PO
          ** to determine if the revision needs to be incremented.
          ** If there is not a record in the archive table,
          **  the revision will not be incremented.
          ** If the po is currently approved and the revision
          **  number in the archive table is the same as
          **  the revision on the PO, then increment the
          **  revision on the PO by one.
          */
          SELECT max(revision_num)
          INTO   x_max_revision_num
          FROM   po_headers_archive_all poha  --<Shared Proc FPJ>
          WHERE  poha.po_header_id = interface.po_header_id;

         /* Bug 493106 ecso 9/24/97
          * Revised date should be updated
          * the same time revision is incremented.
          * Database field revised_date is defined as varchar(25).
          * Use same format as in po_headers_pkg2.check_new_revision
          x_new_revised_date := to_char(interface.last_update_date,
                                       'DD-MON-YY HH24:MI');
          */

          l_progress:='110';
          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
              PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                  p_token    => l_progress,
                                  p_message  => 'Update PO_Headers Doc subtype is Std or planned');
          END IF;
--Bug 2295672 jbalakri : added 'REJECTED' case in decode statement.

          UPDATE po_headers_all  --<Shared Proc FPJ>
             SET approved_flag =
                       decode(nvl(approved_flag,'N'),'N','N','F','F','R'),
                 authorization_status =
                       decode(nvl(authorization_status,'INCOMPLETE'),
                              'INCOMPLETE','INCOMPLETE','REJECTED','REJECTED',
                              'REQUIRES REAPPROVAL'),
                 closed_code = 'OPEN',
-- Bug 1199462 Amitabh
                 closed_date = NULL,
           revision_num =  decode(x_max_revision_num, '',
          revision_num,
        decode(nvl(authorization_status,'INCOMPLETE'),
                 'APPROVED',
           decode(revision_num, x_max_revision_num,
            revision_num + 1, revision_num),
        revision_num)),
                 revised_date =  decode(x_max_revision_num, '',
                                       revised_date,
                               decode(nvl(authorization_status,'INCOMPLETE'),
                                  'APPROVED',
                                  decode(revision_num, x_max_revision_num,
                                         x_new_revised_date, revised_date),
                               revised_date)),
                 last_update_date  = interface.last_update_date,
                 last_updated_by   = interface.last_updated_by,
                 last_update_login = interface.last_update_login
           WHERE po_header_id = interface.po_header_id;

       ELSIF (interface.document_subtype = 'RELEASE') THEN

         l_progress:='120';
         IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
             PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                 p_token    => l_progress,
                                 p_message  => 'Update PO_Headers Doc subtype is Release');
         END IF;

         UPDATE po_headers_all  --<Shared Proc FPJ>
           SET closed_code = 'OPEN',
               closed_date = NULL,
               last_update_date  = interface.last_update_date,
               last_updated_by   = interface.last_updated_by ,
               last_update_login = interface.last_update_login
         WHERE po_header_id = interface.po_header_id;

        l_progress:='130';

        SELECT po_release_id
          INTO g_po_release_id
          FROM po_releases_all  --<Shared Proc FPJ>
         WHERE release_num = interface.release_num
           AND po_header_id = interface.po_header_id
           FOR UPDATE OF approved_flag;

        l_progress:='140';

  /*
  ** Get max revision num from the archive table to
  ** determine if the revision on the release needs to
  ** be incremented.
  */
        SELECT max(revision_num)
    INTO x_max_revision_num
    FROM po_releases_archive_all  --<Shared Proc FPJ>
   WHERE po_release_id = g_po_release_id;

/*Bug No.1793703:The decode statement below for updating the revision_num
                 was not complete.It was updating the revision_num with null
                 when the document added to was in 'Requires Re-approval stage'.
                 Added the revision_num at the end of the decode statement.*/

        l_progress:='150';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Update PO_Releases Doc subtype is Release');
        END IF;

        UPDATE PO_RELEASES_ALL  --<Shared Proc FPJ>
           SET last_update_date = interface.last_update_date,
               last_updated_by = interface.last_updated_by,
               last_update_login = interface.last_update_login,
         closed_code = 'OPEN',
               approved_flag = DECODE(approved_flag,
                                      'N','N','F','F',
                                      'R'),
               authorization_status = DECODE(authorization_status,
                                             'INCOMPLETE','INCOMPLETE','REJECTED','REJECTED',
                                             'REQUIRES REAPPROVAL'),
         revision_num =  decode(x_max_revision_num, '',
          revision_num,
            decode(nvl(authorization_status, 'INCOMPLETE'),
            'APPROVED',
        decode(x_max_revision_num, revision_num,
          revision_num+1, revision_num),
                                        revision_num)),
               revised_date =  decode(x_max_revision_num, '',
                                       revised_date,
                               decode(nvl(authorization_status,'INCOMPLETE'),
                                  'APPROVED',
                                  decode(revision_num, x_max_revision_num,
                                         x_new_revised_date, revised_date),
                               revised_date))
         WHERE po_release_id = g_po_release_id;

       END IF; /* of document type */

    ELSIF (g_mode = 'NEW') THEN

       l_progress:='160';

    /* bgu, Dec. 10, 98
     * Default invoice match flag in turn from Financial system default,
     * vendor, vendor site.
     */

    /* bug 2741985 :
     * for a consumption advice we do not need to get the match option from the
     *  site because we always insert a match type of 'PO' */

    if g_interface_source_code  <> 'CONSUMPTION_ADVICE' then   -- bug 2741985
       get_invoice_match_option(interface.vendor_id,
                 interface.vendor_site_id,
               vendor.invoice_match_option);
    end if;

    l_progress:='170';

    /** BUG 873209
     *  The date mask on interface.h_rate_date causes this insertion
     *  failed on tst115 database.
     */
    IF(interface.document_subtype = 'STANDARD' or
       interface.document_subtype = 'PLANNED'  or
       --<SOURCING TO PO FPH>
       --Allow to create blanket also
       interface.document_subtype = 'BLANKET'
       ) THEN
      l_progress:= '180';
      BEGIN

      if interface.global_agreement_flag = 'N' then
          interface.global_agreement_flag := null;
      end if;

      -- Bug 2690933
      if interface.global_agreement_flag = 'Y' then
            interface.h_min_release_amount := null;
      end if;

      --<SOURCING TO PO FPH>
      --The following insert is modified to take care of defaulting for sourcing
      --For more comments please refer to update po_headers_interface phi
      --in setup_interface_tables procedure.
      /* Bug 2816396
         Use the interface table value for pay_on_code when inserting into po_headers.pay_on_code
      */


/*bug #2997337
    validating the ship_to and bill_to locations to check whether they are
    active or inactive before inserting into the PO_HEADERS table. If any of them
    is found inactive then a null value is inserted in the table in the respective
    column*/

     if (g_interface_source_code = 'SOURCING') then
       x_valid_ship_to := nvl(interface.ship_to_location_id, nvl(vendor.ship_to_location_id,
                                                                     params.ship_to_location_id));
       x_valid_bill_to := nvl(interface.bill_to_location_id, nvl(vendor.bill_to_location_id,
                                                               params.bill_to_location_id));
     else
       x_valid_ship_to := nvl(vendor.ship_to_location_id, interface.ship_to_location_id);
       x_valid_bill_to := nvl(vendor.bill_to_location_id, interface.bill_to_location_id);
     end if;

     l_progress:= '190';
     --bug 4229954
     --we will validate a location based on Bill-To-Location and Ship-To-Location flags
     --of hr_locations_all along with inactive date check
     BEGIN
        select 'Y' into x_is_valid
          from hr_locations_all
          where location_id = x_valid_ship_to
          and NVL(ship_to_site_flag, 'N') = 'Y' --bug 4229954
          and NVL(trunc(inactive_date),trunc(SYSDATE)+1) > trunc(SYSDATE);

     EXCEPTION

         WHEN NO_DATA_FOUND then
             IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                 PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                     p_token    => l_progress,
                                     p_message  => 'NO_DATA_FOUND: '||SQLERRM);
             END IF;
           x_is_valid:='N';
          x_valid_ship_to := NULL;

         WHEN OTHERS  then
             IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                 PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                    p_progress => l_progress);
             END IF;
          raise;
     End;

      l_progress:= '200';
 BEGIN
          select 'Y' into x_is_valid
          from hr_locations_all
          where location_id = x_valid_bill_to
          and NVL(bill_to_site_flag, 'N') = 'Y'  --bug 4229954
          and NVL(trunc(inactive_date),trunc(SYSDATE)+1) > trunc(SYSDATE);

     EXCEPTION

         WHEN NO_DATA_FOUND then
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
            x_is_valid:='N';
            x_valid_bill_to := NULL;

         WHEN OTHERS  then
             IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                 PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                    p_progress => l_progress);
             END IF;
            raise;
     End;
  /*end of addition for bug# 2997337 */

--<DBI FPJ Start>
IF g_interface_source_code = 'CONSUMPTION_ADVICE' THEN
  -- Bug 3648268 Use lookup code instead of hardcoded value
  l_document_creation_method := 'CREATE_CONSUMPTION';
END IF;
--<DBI FPJ End>

      l_progress:= '210';
      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'Before Insert into PO_headers');
      END IF;

      INSERT INTO po_headers_all  --<Shared Proc FPJ>
            (po_header_id,
                   last_update_date,
                   last_updated_by,
                   segment1,
             created_by,
                   last_update_login,
             summary_flag,
                   enabled_flag,
                   type_lookup_code,
                   agent_id,
                   creation_date,
                   revision_num,
                   print_count,
                   closed_code,
                   frozen_flag,
                   vendor_id,
                   vendor_site_id,
       vendor_contact_id,
                   ship_to_location_id,
                   bill_to_location_id,
                   terms_id,
                   ship_via_lookup_code,
                   fob_lookup_code,
                   pay_on_code,
                   freight_terms_lookup_code,
             confirming_order_flag,
                   currency_code,
             rate_type,
                   rate_date,
                   rate,
                   acceptance_required_flag,
                   firm_status_lookup_code,
                   min_release_amount,
--DPCARD{
                   pcard_id,
--DPCARD}
             --<SOURCING TO PO FPH START>
             blanket_total_amount,--Bug# 2288408
             start_date,          --Bug# 2288408
             end_date,        --Bug# 2288408
             --<SOURCING TO PO FPH END>
       --<RENEG BLANKET FPI START>
       amount_limit,
                   global_agreement_flag,
       --<RENEG BLANKET FPI END>
       --<CONSUME REQ DEMAND FPI>
       consume_req_demand_flag,
                   consigned_consumption_flag,   -- CONSIGNED FPI
                   shipping_control,    -- <INBOUND LOGISTICS FPJ>
                   org_id  --<Shared Proc FPJ>
                  ,conterms_exist_flag     --<CONTERMS FPJ>
      ,document_creation_method --<DBI FPJ>
                 ,style_id --<R12 STYLES PHASE II>
     ,tax_attribute_update_code   --<eTax Integration R12>
            , created_language --<Unified Catalog R12: Bug#4656615>
            , cpa_reference    --<Unified Catalog R12: Bug#4656615>
		  ,attribute_category                  ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                  ,attribute1                          ---added by Paul DSouza,29-Aug-07(V2.0)
                  ,attribute6                          ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                  ,attribute7                          ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                  ,attribute8                          ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                  ,attribute9)
      VALUES (interface.po_header_id,
                    interface.last_update_date,
                    interface.last_updated_by,
                    interface.document_num,
                    interface.created_by,
                    interface.last_update_login,
              'N',
                    'Y',
                    interface.document_subtype,
                    interface.agent_id,
                    interface.creation_date,
                    interface.revision_num,
                    interface.print_count,
                    interface.h_closed_code,
                    interface.frozen_flag,
                    interface.vendor_id,
                    interface.vendor_site_id,
        interface.vendor_contact_id,
                    x_valid_ship_to,
                    x_valid_bill_to,
        decode(g_interface_source_code,'SOURCING',
          nvl(interface.terms_id,
                    nvl(vendor.terms_id,
            params.terms_id)),
                            nvl(vendor.terms_id,
                                interface.terms_id)),
        decode(g_interface_source_code,'SOURCING',
                           nvl(interface.ship_via_lookup_code,
             nvl(vendor.ship_via_lookup_code,
                 params.ship_via_lookup_code)),
                           nvl(vendor.ship_via_lookup_code,
                               interface.ship_via_lookup_code)),
        decode(g_interface_source_code,'SOURCING',
                           nvl(interface.fob_lookup_code,
             nvl(vendor.fob_lookup_code,
           params.fob_lookup_code)),
                           nvl(vendor.fob_lookup_code,
                               interface.fob_lookup_code)),
        decode(g_interface_source_code,'SOURCING',
                         nvl(interface.pay_on_code,
             vendor.pay_on_code),
                           'CONSUMPTION_ADVICE',
                           interface.pay_on_code,
                           nvl(vendor.pay_on_code,
                               interface.pay_on_code)),
        decode(g_interface_source_code,'SOURCING',
                           nvl(interface.freight_terms_lookup_code,
                               nvl(vendor.freight_terms_lookup_code,
           params.freight_terms_lookup_code)),
                           nvl(vendor.freight_terms_lookup_code,
                               interface.freight_terms_lookup_code)),
                    interface.confirming_order_flag,
                    interface.h_currency_code,
                    interface.h_rate_type,
--                    to_date(interface.h_rate_date, 'DD/MM/YYYY'),
                    interface.h_rate_date,
                    interface.h_rate,
                   decode(g_interface_source_code,'CONSUMPTION_ADVICE','N',interface.acceptance_required_flag), -- bug 13799841
                    interface.h_firm_status_lookup_code,
                    interface.h_min_release_amount,
--DPCARD{
                    interface.pcard_id,
--DPCARD}
              --<SOURCING TO PO FPH START>
              decode(g_document_type,'PA',interface.amount_agreed,null),
              decode(g_document_type,'PA',interface.effective_date,null),
              decode(g_document_type,'PA',interface.expiration_date,null),
              --<SOURCING TO PO FPH END>
        --<RENEG BLANKET FPI START>
        decode(g_document_type, 'PA', nvl(interface.amount_limit, interface.amount_agreed), null),
                    decode(interface.global_agreement_flag,'N',null,'Y','Y',null),   -- bug 2754954
        --<RENEG BLANKET FPI END>
        --<CONSUME REQ DEMAND FPI>
        interface.consume_req_demand_flag,
                    decode(g_interface_source_code,'CONSUMPTION_ADVICE', 'Y',null),
                    vendor.shipping_control,    -- <INBOUND LOGISTICS FPJ>
                    g_purchasing_ou_id  --<Shared Proc FPJ>
                   ,p_conterms_exist_flag     --<CONTERMS FPJ>
       ,l_document_creation_method --<DBI FPJ>
                   ,decode(g_interface_source_code,'CONSUMPTION_ADVICE',
                           PO_DOC_STYLE_GRP.get_standard_doc_style ,interface.style_id)  --<R12 STYLES PHASE II >
       ,nvl2(g_calculate_tax_flag, 'CREATE', null)  --<eTax Integration R12>
            , interface.created_language --<Unified Catalog R12: Bug#4656615>
            , interface.cpa_reference    --<Unified Catalog R12: Bug#4656615>
		   ,interface.attribute_category   ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                   ,interface.attribute1           ---added by Paul DSouza,OD CUSTOMIZATION,29-Aug-07(V2.0)
                   ,interface.attribute6           ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                   ,interface.attribute7           ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                   ,interface.attribute8           ---added by Sandeep Gorla,E0216,OD CUSTOMIZATION,10-Apr-07(V2.0)
                   ,interface.attribute9);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'DUP_VAL_ON_INDEX: '||SQLERRM);
            END IF;

            IF g_interface_source_code ='SOURCING' then
                g_sourcing_errorcode:=2; --duplicate document number
                RAISE;
            ELSE
                RAISE;
            END IF;
    END;

    l_progress:= '220';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'After Insert into PO_headers');
    END IF;

    /* Bug 14080332:
           Calling PO_VENDOR_SITES_SV.get_transmission_defaults only when vendor_id and
	   vendor_site_id is present on PO to avoid no_data_found exception.
    */
    SELECT vendor_id, vendor_site_id
    INTO l_vendor_id, l_vendor_site_id
    FROM po_headers_all
    WHERE po_header_id = INTERFACE.po_header_id;
    IF l_vendor_id IS NOT NULL AND
      l_vendor_site_id IS NOT NULL THEN
	--Bug#13542989: Start : Get Default document transimmision information

	PO_VENDOR_SITES_SV.get_transmission_defaults
      ( p_document_id => interface.po_header_id,
        p_document_type => g_document_type,
        p_document_subtype => interface.document_subtype,
        p_preparer_id => interface.agent_id,
        x_default_method => l_default_method,
        x_email_address => l_email_address,
        x_fax_number => l_fax_number,
        x_document_num => l_document_num
      );

	update po_headers_all
    set SUPPLIER_NOTIF_METHOD = nvl(l_default_method,'NONE'),
	EMAIL_ADDRESS         = decode(l_default_method, 'EMAIL', l_email_address, null),
	FAX                   = decode(l_default_method, 'FAX', l_fax_number, null)
    where po_header_id        =  interface.po_header_id;
    END IF;
	IF g_debug_stmt THEN
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'After Default of Suppler Notification Method');
    END IF;
	--Bug#13542989: End : Get Default document transimission information

    --Bug#5024876: Removed the dangling 'END IF' left by Bug#4886821

        -- After insert into po_headers, insert a row into org_assignments for a global agreement
           IF nvl(interface.global_agreement_flag, 'N') = 'Y' then
             l_progress:= '240';
             select org_id
             into x_org_id
             from po_headers_all
             where po_header_id = interface.po_header_id;

               --<Bug 3054563 mbhargav START>
               --Replaced the INSERT statement with call to Row Handler.
               -- call the GA org assignments table handler to insert a row
               -- for the owning org into the org assignments table
               l_org_assign_rec.po_header_id      := interface.po_header_id;
               l_org_assign_rec.organization_id   := x_org_id;
               l_org_assign_rec.purchasing_org_id := l_org_assign_rec.organization_id;
               l_org_assign_rec.enabled_flag      := 'Y';
               l_org_assign_rec.vendor_site_id    := interface.vendor_site_id;
               l_org_assign_rec.last_update_date  := interface.last_update_date;
               l_org_assign_rec.last_updated_by   := interface.last_updated_by;
               l_org_assign_rec.creation_date     := interface.creation_date;
               l_org_assign_rec.created_by        := interface.created_by;
               l_org_assign_rec.last_update_login := interface.last_update_login;

               PO_GA_ORG_ASSIGN_PVT.insert_row(p_init_msg_list  => 'T',
                                        x_return_status  => l_return_status,
                                        p_org_assign_rec => l_org_assign_rec,
                                        x_row_id         => l_org_row_id);
               --<Bug 3054563 mbhargav END>

              IF g_debug_stmt THEN
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'After inserting into Org Assignments');
              END IF;
            END IF;

      l_progress:= '250';

   --<RENEG BLANKET FPI START>
         --<BUG 2695661>
         -- The header level attachments should be copied if the call is coming from Sourcing.
         -- irrespective of doc type or subtype. Removing 'Blanket' check.
         if (g_interface_source_code ='SOURCING') then

              -- copy attachments from negotiation header to blanket header
         po_negotiations_sv2.copy_attachments('PON_AUCTION_HEADERS_ALL',
                            interface.auction_header_id,
                                null,
                                null,
                                null,
                                null,
                                'PO_HEADERS',
                                interface.po_header_id,
                                null,
                                null,
                                null,
                                null,
                                interface.created_by,
                                interface.last_update_login,
                                null,
                                null,
                                null,
                                'NEG');

              -- build and attach negotiation header notes as to supplier attachments
              -- on po/blanket header.
              po_negotiations_sv2.add_attch_dynamic('PON_AUC_SUPPLIER_HEADER_NOTES' ,
                        interface.auction_header_id,
                        interface.auction_line_number,
                        interface.bid_number,
                        interface.bid_line_number,
                        'PO_HEADERS',
                        interface.po_header_id,
                        interface.created_by,
                        interface.last_update_login ,
                        null,
                        null,
                        null);

              -- Bug# 3207840. build and attach negotiation/bid header
        -- attributes as to supplier attachment on po/blanket header
        -- from FPJ.
              po_negotiations_sv2.add_attch_dynamic('PON_BID_HEADER_ATTRIBUTES' ,
                        interface.auction_header_id,
                        NULL,
                        interface.bid_number,
                        NULL,
                        'PO_HEADERS',
                        interface.po_header_id,
                        interface.created_by,
                        interface.last_update_login ,
                        null,
                        null,
                        null);

          IF g_debug_stmt THEN
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'After copying attachments from Sourcing');
          END IF;
        end if; --attachments for header

      l_progress:= '260';
   -- the call to procedure calculate_local should happen only for doc_type PO
        -- <Bug 8513167>
        -- Call for all document types. Added BLANKET.
        if (g_document_subtype IN ('STANDARD','PLANNED','BLANKET')) then
         calculate_local(g_document_subtype, 'HEADER', interface.po_header_id);
        end if;

        IF g_debug_stmt THEN
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'After calculate_local');
        END IF;

        --<RENEG BLANKET FPI END>

      ELSIF(g_document_subtype='RELEASE')THEN

         l_progress:= '270';
         SELECT po_releases_s.nextval
           INTO g_po_release_id
           FROM sys.dual;

   /*
   ** assign the document id to get passed back to the
   ** calling module.
   */
         x_document_id := g_po_release_id;

/*Bug 1664638
  Inserting negative of g_po_release_id as release number to
  avoid unique constraint violation
*/
        l_progress:='280';

        -- Bug 3599251: Assign value to l_document_creation_method and
        -- insert it into po_releases_all instead of p_document_creation_method
        -- Bug 3648268 Use lookup code instead of hardcoded value
        IF g_interface_source_code = 'CONSUMPTION_ADVICE' THEN
           l_document_creation_method := 'CREATE_CONSUMPTION';
        END IF;

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Before insert into PO_RELEASES');
        END IF;

         INSERT INTO po_releases_all  --<Shared Proc FPJ>
             (po_release_id,
              last_update_date,
              last_updated_by,
              po_header_id,
              release_num,
              agent_id,
              release_date,
              creation_date,
              created_by,
              last_update_login,
              revision_num,
              approved_flag,
              authorization_status,
              print_count,
              release_type,
              pay_on_code,
              pcard_id,
              consigned_consumption_flag,   -- CONSIGNED FPI
              shipping_control,    -- <INBOUND LOGISTICS FPJ>
              org_id  --<Shared Proc FPJ>
        ,document_creation_method --<DBI FPJ>
        ,tax_attribute_update_code  --<eTax integration R12>
        ,acceptance_required_flag   --Bug 7518967 : Default Acceptance Required Check ER
              )
       VALUES (g_po_release_id,
               interface.last_update_date,
               interface.last_updated_by,
               interface.po_header_id,
               -g_po_release_id, --interface.release_num
               interface.agent_id,
               nvl(interface.release_date,sysdate),
               interface.creation_date,
               interface.created_by,
               interface.last_update_login,
               0,
               'N',
               'INCOMPLETE',
               0,
               'BLANKET',
               interface.pay_on_code,
               interface.pcard_id,
               decode(g_interface_source_code,'CONSUMPTION_ADVICE', 'Y',null), -- CONSIGNED FPI
               interface.shipping_control,    -- <INBOUND LOGISTICS FPJ>
               g_purchasing_ou_id  --<Shared Proc FPJ>
         ,l_document_creation_method  --<DBI FPJ> -- Bug 3599251
               ,nvl2(g_calculate_tax_flag, 'CREATE', null) --<eTax Integration R12>
               ,decode(params.acceptance_required_flag,'N','N',   /* Bug 7518967 : Default Acceptance Required Check ER: Geting the default acceptance_required_flag */
	                                               'Y','Y',
						       'D','Y',
						       'S','Y',
						       'N')
               );

        l_progress:='290';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'After insert into PO_RELEASES');
        END IF;
       -- Bug 882050: Release header level global attribute

       calculate_local('RELEASE', 'HEADER', g_po_release_id);

      END IF; /* of Standard/Planned */
    END IF; /* of NEW/ADD */ --Bug#5024876: Uncommenting the END IF commented by Bug#4886821

    l_progress:='300';
    -- <Complex Work R12 Start>
    create_line(
      x_interface_header_id => x_interface_header_id
    , p_is_complex_work_po => l_is_complex_work_po
    );
    -- <Complex Work R12 End>

    IF g_debug_stmt THEN
      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                          p_token    => l_progress,
                          p_message  => 'After create_line');
    END IF;


    LOOP

        FETCH interface_cursor INTO interface;
        EXIT WHEN interface_cursor%notfound;

        -- <Complex Work R12 Start>
        create_line(
          x_interface_header_id => x_interface_header_id
        , p_is_complex_work_po => l_is_complex_work_po
        );
        -- <Complex Work R12 End>

      IF g_debug_stmt THEN
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'After create_line (inside complex works loop)');
      END IF;

    END LOOP;

    --<Begin Bug# 5365579> After iterating through the cursor we want to reset
    --the cursor back to the first record for the rest of the procedure.
    CLOSE interface_cursor;
    OPEN interface_cursor(x_interface_header_id);
    FETCH interface_cursor INTO interface;

    IF interface_cursor%notfound THEN
      CLOSE interface_cursor;
      RETURN;
    END IF;
    --<End Bug# 5365579>

    --<Unified Catalog R12 START>
    -- Since we have the po_line_id available on po_attr_values_interface and tlp_interface
    -- we can move all records from interface to txn tables for all lines of a given blanket
    IF ((g_interface_source_code ='SOURCING') AND (g_document_subtype = 'BLANKET')) THEN
      IF g_debug_stmt THEN
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Calling PO_ATTRIBUTE_VALUES_PVT.transfer_intf_item_attribs');
      END IF;
      PO_ATTRIBUTE_VALUES_PVT.transfer_intf_item_attribs(x_interface_header_id);
    END IF;
    -- <Unified Catalog R12 END>


    IF g_debug_stmt THEN
      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                          p_token    => l_progress,
                          p_message  => 'After PO_ATTRIBUTE_VALUES_PVT.transfer_intf_item_attribs');
    END IF;

    l_progress:='310';
/* Bug 1093645:Code added to fix the deadlock issue in autocreate*/
    if (g_mode = 'NEW')  then
         IF (params.po_num_code='AUTOMATIC') AND
            --<SOURCING TO PO FPH>
      --modified the if clause to include PA
            (g_document_type in ('PO','PA'))         AND
/* Bug 1183082
   If emergency po number is mentioned then the interface document number
   will have that value and it can be alphanumeric though the po num code
   is automatic.
   In case of automatic, we populate a dummy value in segment1(in po_headers)
   which is negative of po_header_id.
   We should be populating the segment1 from unique identifier control
   table only if the segment1 is negative of po_header id and
   hence the following logic.
           (interface.document_num  = to_char((-1* x_document_id))) THEN
*/
           (interface.document_num  = to_char((-1* x_document_id))) THEN

               l_progress:= '320';

               -- bug5174177
               -- Call Centralized API to get the next po number
               x_document_num :=
                 PO_CORE_SV1.default_po_unique_identifier
                 ( p_table_name => 'PO_HEADERS',
                   p_org_id     => g_purchasing_ou_id
                 );

               IF g_debug_stmt THEN
                 PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'new po num = ' || x_document_num);
               END IF;

               l_progress := '325';

               UPDATE po_headers_all  --<Shared Proc FPJ>
                  set segment1=x_document_num
               where po_header_id=x_document_id;

          END IF;

          --<CONTERMS FPJ START>
          --Copy contract terms if sourcing doc had a template attached
          IF ((g_interface_source_code ='SOURCING')
              AND  (p_conterms_exist_flag= 'Y')) then

              l_progress:= '330';
              l_contract_doc_type:= PO_CONTERMS_UTL_GRP.GET_PO_CONTRACT_DOCTYPE(
                                  p_sub_doc_type=>g_document_subtype);

                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'Contracts template attached');
                    PO_DEBUG.debug_var (p_log_head => g_log_head||l_api_name,
                                        p_progress => l_progress,
                                        p_name     => 'x_document_id',
                                        p_value    => x_document_id);
                    PO_DEBUG.debug_var (p_log_head => g_log_head||l_api_name,
                                        p_progress => l_progress,
                                        p_name     => 'x_document_num',
                                        p_value    => x_document_num);
                    PO_DEBUG.debug_var (p_log_head => g_log_head||l_api_name,
                                        p_progress => l_progress,
                                        p_name     => 'l_contract_doc_type',
                                        p_value    => l_contract_doc_type);
                    PO_DEBUG.debug_var (p_log_head => g_log_head||l_api_name,
                                        p_progress => l_progress,
                                        p_name     => 'interface.bid_number',
                                        p_value    => interface.bid_number);
                    PO_DEBUG.debug_var (p_log_head => g_log_head||l_api_name,
                                        p_progress => l_progress,
                                        p_name     => 'p_sourcing_k_doc_type',
                                        p_value    => p_sourcing_k_doc_type);
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'before call okc_terms_copy_grp.copy_doc');
                END IF;

                l_progress:= '340';

                OKC_TERMS_COPY_GRP.copy_doc     (
                        p_api_version           => 1.0,
                        p_source_doc_type     => p_sourcing_k_doc_type,
                        p_source_doc_id         => interface.bid_number,
                        p_target_doc_type     => l_contract_doc_type,
                        p_target_doc_id         => x_document_id,
                        p_keep_version          => 'Y',
                        p_article_effective_date=> sysdate,
                        p_initialize_status_yn  => 'N',
                        p_reset_Fixed_Date_yn   => 'N',
                        p_copy_del_attachments_yn=>'Y',
                        p_copy_deliverables     => 'Y',
                        p_document_number     => x_document_num,
                        p_copy_abstract_yn    => 'Y',   -- Bug 4051316
                        x_return_status        =>  l_return_status,
                        x_msg_data             =>  l_msg_data,
                        x_msg_count            =>  l_msg_count
                        );

                l_progress:='350';
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'after call okc_terms_copy_grp.copy_doc.Return status:'||l_return_status);
                END IF;

                 IF l_return_status <> FND_API.G_RET_STS_SUCCESS then
                       RAISE l_Contracts_call_exception;
                 END IF; -- Return status from contracts

            END IF; -- if p_conterms_exist_flag and sourcing doc
            --<CONTERMS FPJ END>

     l_progress := '360';
  /* FPI GA start  Update the terms after the successful completion of PO */

     IF  (g_document_subtype = 'STANDARD') and
         (g_interface_source_code <> 'CONSUMPTION_ADVICE')  then  -- CONSIGNED FPI
       po_interface_s2.update_terms(x_document_id);
     END IF;

   /* FPI GA end */
     l_progress := '370';

/*Bug 1664638
  Since while inserting into po_releases , we inserted a negative
  number to avoid unique constraint violation, just before
  commit we are updating the correct value for release number.
*/
          IF  (g_document_subtype = 'RELEASE') then
--Added a new loop as a part of 1805397 for fixing unique
--constraint error
--jbalakri
           begin
            loop
              begin
                 l_progress := '380';
                 select nvl(max(release_num),0) + 1
                 into   x_release_num
                 from   po_releases_all por  --<Shared Proc FPJ>
                 where  por.po_header_id = interface.po_header_id;
/*Bug 1724603
  When we are creating a blanket release for the first time then
  we end up creating releases with negative release numbers
  and hence it required the following lines to be added as an
  extension to the fix in 1664638
*/

                 if (x_release_num <= 0) then   --Bug 4473796 : added '='
                     x_release_num := 1;
                 end if;

                 l_progress := '390';
                 update po_releases_all  --<Shared Proc FPJ>
                 set    release_num = x_release_num
                 where  po_releases_all.po_header_id = interface.po_header_id
                 and    release_num = -g_po_release_id;
                         exit;
               exception
                when DUP_VAL_ON_INDEX then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'DUP_VAL_ON_INDEX: '||SQLERRM);
                    END IF;
                    /* Bug 14065497: Comment the RAISE statement so that the loop continues when the DUP_VAL_ON_INDEX exception occurs */
                 -- RAISE;
                when others then
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                  RAISE;
              end;
            end loop;
--end of add for 1805397
           end;
           END IF;

    END IF;

    l_progress:='400';

    -- Bug 882050: Document level global attribute
    -- <Bug 8513167>
    -- Make the call for all document types. Added BLANKET.
    if (interface.document_subtype IN ('STANDARD','PLANNED','BLANKET')) THEN
        calculate_local(interface.document_subtype, 'DOCUMENT',
                        interface.po_header_id);
    elsif (g_document_subtype='RELEASE') THEN
        calculate_local('RELEASE', 'DOCUMENT', g_po_release_id);
    end if;

    l_progress := '410';
    --<Bug :11071489 REQ_AUTOCREATE Start>--
     l_event_name := 'oracle.apps.po.autocreate.pocreated';
     l_parameter_list(1).name := 'Interface_Header_ID' ;
     l_parameter_list(1).value := x_interface_header_id;
     po_core_s4.raise_business_event(l_event_name,l_parameter_list);
    --<REQ_AUTOCREATE end>---
    wrapup(x_interface_header_id);

    CLOSE interface_cursor;
    --
    -- <eTax Integration R12 Start>
    -- Removed multiple tax calls from procedure
    -- create_shipment and placed a single call here for calculating
    -- tax for the whole document
    --
    IF (g_document_subtype in ('STANDARD', 'PLANNED')) THEN
       l_progress := '413';
       l_return_status := NULL;
       -- Bug 5067321. For Add To, x_document_id is null, use
       -- interface.po_header_id instead
       IF (g_mode = 'ADD') THEN
         tax_document_id := interface.po_header_id;
       ELSE
         tax_document_id := x_document_id;
       END IF;

       PO_TAX_INTERFACE_PVT.calculate_tax( x_return_status     => l_return_status,
                                           p_po_header_id      => tax_document_id,
                                           p_po_release_id     => NULL,
                                           p_calling_program   => 'POXBWVRP_PO');
       IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         l_progress := '414';
         IF g_interface_source_code = 'CONSUMPTION_ADVICE' THEN
           ROLLBACK TO TAX_CALCULATION_ERROR;
           x_document_id := NULL;
           fnd_message.set_name('PO','PO_API_ERROR');
           fnd_message.set_token( TOKEN  => 'PROC_CALLER'
                                , VALUE  => 'PO_INTERFACE_S.CREATE_PO');
           fnd_message.set_token( TOKEN  => 'PROC_CALLED'
                                , VALUE  => 'PO_TAX_INTERFACE_PVT.CALCULATE_TAX');
           fnd_msg_pub.add;
           fnd_message.set_name('PO','PO_AP_TAX_ENGINE_FAILED_WARN');
           fnd_msg_pub.add;
         END IF;
       END IF;
    ELSIF (g_document_subtype = 'RELEASE') THEN
       l_progress := '416';
       l_return_status := NULL;
       -- Bug 5067321. For Add To, x_document_id is null, use
       -- interface.po_header_id instead
       IF (g_mode = 'ADD') THEN
         tax_document_id := g_po_release_id;
       ELSE
         tax_document_id := x_document_id;
       END IF;

       PO_TAX_INTERFACE_PVT.calculate_tax(x_return_status     => l_return_status,
                                          p_po_header_id      => NULL,
                                          p_po_release_id     => tax_document_id,
                                          p_calling_program   => 'POXBWVRP_PO');
       IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
         IF g_interface_source_code = 'CONSUMPTION_ADVICE' THEN
           ROLLBACK TO TAX_CALCULATION_ERROR;
           x_document_id := NULL;
           fnd_message.set_name('PO','PO_API_ERROR');
           fnd_message.set_token( TOKEN  => 'PROC_CALLER'
                                , VALUE  => 'PO_INTERFACE_S.CREATE_PO');
           fnd_message.set_token( TOKEN  => 'PROC_CALLED'
                                , VALUE  => 'PO_TAX_INTERFACE_PVT.CALCULATE_TAX');
           fnd_msg_pub.add;
           fnd_message.set_name('PO','PO_AP_TAX_ENGINE_FAILED_WARN');
           fnd_msg_pub.add;
         END IF;
         l_progress := '417';
       END IF;
    END IF;
    -- <eTax Integration R12 End>
    l_progress := '420';

    --<SOURCING TO PO FPH>
    --for sourcing transaction is controlled by the sourcing code.
    if g_interface_source_code not in ('SOURCING','CONSUMPTION_ADVICE') then

/* Bug 2534534 If no records are processed then we should not commit */
      if(g_number_records_processed > 0) then
         l_progress := '430';
         COMMIT;
      else
         l_progress := '440';
         rollback to savepoint create_po; --Bug 4314776
      end if;
    end if;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION
--<CONTERMS FPJ START>
  WHEN l_Contracts_call_exception then
       -- put error messages in log
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_po: Inside l_contracts_call_exception');
        END IF;
          Fnd_message.set_name('PO','PO_API_ERROR');
          Fnd_message.set_token( token  => 'PROC_CALLER'
                               , VALUE => 'PO_INTERFACE_S.CREATE_PO');
          Fnd_message.set_token( token  => 'PROC_CALLED'
                               , VALUE => 'OKC_TERMS_CPOY_GRP.COPY_DOC');
          FND_MSG_PUB.Add;

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            l_msg_count := FND_MSG_PUB.Count_Msg;
            FOR i IN 1..l_msg_count LOOP
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress||'_EXCEPTION_'||i,
                                    p_message  => FND_MSG_PUB.Get(p_msg_index=>i,p_encoded =>'F'));
            END LOOP;
        END IF;
     IF interface_cursor%ISOPEN then
       CLOSE interface_cursor;
     END IF;
     RAISE;
--<CONTERMS FPJ END>

/* Bug: 1137860:
   Raise exception regardless of error. This will make debuging easier */
   WHEN OTHERS THEN
    --  wrapup(x_interface_header_id);
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     po_message_s.sql_error('CREATE_PO',l_progress,sqlcode);
     if interface_cursor%isopen then
       CLOSE interface_cursor;
     end if;
     --togeorge 11/20/2001
     -- Bug 1349801
     -- Added a Rollback when a Exception was raised
     -- This Rollbacks all the Changes done when a Exception Condition was raised. This was done to avoid PO's with negative numbers getting created.
     --raise;
    --<SOURCING TO PO FPH>
    --for sourcing transaction is controlled by the sourcing code.
    if g_interface_source_code not in  ('SOURCING', 'CONSUMPTION_ADVICE') then
      ROLLBACK  to savepoint create_po;  --Bug 4314776
       wrapup(x_interface_header_id); --Bug 4314776

     end if;
     --
    raise;  --<Bug 3336920>
END create_po;

/* ============================================================================
     NAME: CREATE_LINE
     DESC: Create/Add to document line
     ARGS: IN : x_interface_header_id_id IN number
     ALGR:

   ==========================================================================*/
-- <Complex Work R12>: Added parameter p_is_complex_work_po
PROCEDURE create_line(
  x_interface_header_id IN NUMBER
, p_is_complex_work_po  IN BOOLEAN
)
IS
x_po_line_id       number;
x_po_line_type_id  number;
x_line_num         po_lines.line_num%type;
x_po_item_id       number;
x_order_type_lookup_code varchar2(25);
l_purchase_basis         PO_LINE_TYPES_B.purchase_basis%TYPE; -- <SERVICES FPJ>
x_po_item_revision po_lines.item_revision%type;
x_po_unit_meas_lookup_code po_lines.unit_meas_lookup_code%type;
x_po_unit_price    number;
x_po_transaction_reason_code po_lines.transaction_reason_code%type;
x_price_break_lookup_code    po_lines.price_break_lookup_code%type;
x_quantity         number := '';
x_requisition_header_id number := ''; /* Used for copying attachments */
--fix 8976669
--declared x_amount
x_amount number;
x_line_location_id number := null;
l_line_loc_id_tbl po_tbl_number;

l_price_break_id  PO_LINE_LOCATIONS_ALL.line_location_id%TYPE;-- <SERVICES FPJ>

x_quote_header_id number := null;
x_quote_line_id number := null;
x_match_blanket_line varchar2(1) := null;
x_unit_price  po_lines.unit_price%TYPE := null;
l_base_unit_price  po_lines.base_unit_price%TYPE := null; -- <FPJ Advanced Price>

/* obtain currency info to adjust precision */
x_precision   number :='';
x_ext_precision   number :='';
x_min_unit    number :='';
/* project/task enhancement for RFQ */
x_project_id    number :='';
x_task_id   number :='';
x_req_dist_id   number :='';
--togeorge 11/17/2000
--Bug# 1369049
--Added logic to default tax_name in po_lines
   x_tax_id                ap_tax_codes.tax_id%type;
   x_tax_type              ap_tax_codes.tax_type%type;
   x_description           ap_tax_codes.description%type;
   x_allow_tax_code_override_flag  gl_tax_option_accounts.allow_tax_code_override_flag%type;
   x_tax_name              po_lines.tax_name%type;
   x_ship_to_location_id   number:= 0;
   x_ship_to_loc_org_id    mtl_system_items.organization_id%TYPE;
   x_ship_org_code         varchar2(3);

/** <UTF8 FPI> **/
/** tpoon 9/29/2002 **/
/** Changed x_ship_org_name to use %TYPE **/
--   x_ship_org_name         varchar2(60);
   x_ship_org_name         hr_all_organization_units.name%TYPE;
--
-- bug# 3345108
-- comment out most of the changes done by bug 2219743.
-- bug# 2219743
/**
   x_secondary_qty         po_lines.secondary_quantity%type := NULL;
   x_item_number           VARCHAR2(240);
   x_process_org           VARCHAR2(1);
   x_dummy                 VARCHAR2(240);
   x_product               VARCHAR2(3) := 'GMI';
   x_opm_installed         VARCHAR2(1);
   x_retvar                BOOLEAN;
   ic_item_mst_rec IC_ITEM_MST%ROWTYPE;
   ic_item_cpg_rec IC_ITEM_CPG%ROWTYPE;
   x_order_opm_um  ic_item_mst.item_um%type := NULL;
   x_inv_org_id    mtl_system_items.organization_id%TYPE;
**/
l_api_name CONSTANT VARCHAR2(30) := 'create_line';
d_mod CONSTANT VARCHAR2(255) := g_log_head||l_api_name;
-- end of 2219743

    --<SOURCING TO PO FPH START>
    x_column1       varchar2(10);
    x_result        varchar2(7);
    update_req_pool_fail  exception;
    x_hazard_class_id   number:=null;
    x_un_number_id    number:=null;
    x_unit_of_measure   po_line_types.unit_of_measure%type:=null;
    --The following flag indicates whether copying the attachments from (all)the
    --sourcing entities need to be suppressed due to the grouping of lines.
    x_attch_suppress_flag       varchar2(1) :='N';
    --<SOURCING TO PO FPH END>

    l_db_quantity   po_lines.quantity%TYPE := null; --bug#2723479

    -- Bug 2735840 START
    l_uom_convert varchar2(2) := fnd_profile.value('PO_REQ_BPA_UOM_CONVERT');
    l_ga_uom                    PO_LINES.unit_meas_lookup_code%TYPE;
    l_quantity_in_ga_uom        PO_LINES_INTERFACE.quantity%TYPE;
    l_conversion_rate number :=1;
    -- Bug 2735840 END

    -- Bug 2875346.
    l_one_time_att_doc_id fnd_attached_documents.attached_document_id%TYPE;

    -- <SERVICES FPJ START>
    l_job_long_description  PO_REQUISITION_LINES_ALL.job_long_description%TYPE;
    l_who_rec               PO_NEGOTIATIONS_SV2.who_rec_type;

    l_return_status         VARCHAR2(1);

    l_order_type_lookup_code  PO_LINE_TYPES_B.order_type_lookup_code%TYPE;
    l_purchase_basis1         PO_LINE_TYPES_B.purchase_basis%TYPE;
    l_matching_basis          PO_LINE_TYPES_B.matching_basis%TYPE;
    l_category_id             PO_LINE_TYPES_B.category_id%TYPE;
    l_unit_meas_lookup_code   PO_LINE_TYPES_B.unit_of_measure%TYPE;
    l_unit_price              PO_LINE_TYPES_B.unit_price%TYPE;
    l_outside_operation_flag  PO_LINE_TYPES_B.outside_operation_flag%TYPE;
    l_receiving_flag          PO_LINE_TYPES_B.receiving_flag%TYPE;
    l_receive_close_tolerance PO_LINE_TYPES_B.receive_close_tolerance%TYPE;
    -- <SERVICES FPJ END>
    l_negotiated_by_preparer_flag po_lines_all.negotiated_by_preparer_flag%type; --<DBI FPJ>
    l_type_lookup_code po_headers_all.type_lookup_code%type; --<DBI FPJ>
    l_global_agreement_flag po_headers_all.global_agreement_flag%type; --<DBI FPJ>

    -- oneoff 3201308 start
    l_needby_prf  varchar2(1);
    l_shipto_prf  varchar2(1);
    l_min_shipment_num po_line_locations_all.shipment_num%TYPE;
    l_ship_to_loc po_line_locations_all.ship_to_location_id%TYPE;
    l_ship_to_org po_line_locations_all.ship_to_organization_id%TYPE;
    l_need_by_date po_line_locations_all.need_by_date%TYPE;
    -- oneoff 3201308 end

    l_contractor_status PO_REQUISITION_LINES_ALL.contractor_status%TYPE;
    --<Bug 3353109>

    l_routing_name      RCV_ROUTING_HEADERS.routing_name%TYPE; -- <BUG 3365446>

    l_progress VARCHAR2(3) := '000';                --< Bug 3210331 >
    l_manual_price_change_flag po_lines_all.manual_price_change_flag%TYPE := NULL; --bug 3495772
    l_from_type_lookup_code PO_HEADERS.type_lookup_code%type;--bug#3612701

    --<INVCONV R12 START>
    x_secondary_unit_def  MTL_UNITS_OF_MEASURE.UNIT_OF_MEASURE%TYPE;
    x_secondary_uom       MTL_UNITS_OF_MEASURE.UNIT_OF_MEASURE%TYPE;
    x_secondary_quantity_def  PO_LINES.SECONDARY_QUANTITY%TYPE;
    x_preferred_grade_def MTL_GRADES.GRADE_CODE%TYPE;
    l_quantity_temp   PO_LINES.QUANTITY%TYPE;
    --<INVCONV R12 END>

    l_requesting_ou_id    PO_REQUISITION_LINES_ALL.org_id%TYPE; -- <ACHTML R12>
    l_rate_for_req_fields GL_DAILY_RATES.conversion_rate%TYPE; -- <ACHTML R12>

    -- <Unified Catalog R12 START>
    l_po_line_id_tbl po_line_id_tbl;
    l_interface_header_id_tbl interface_header_id_tbl;
    l_interface_line_id_tbl interface_line_id_tbl;
    -- <Unified Catalog R12 END>

    l_outsourced_assembly po_line_locations_all.outsourced_assembly%type; --<SHIKYU R12>
    l_retainage_rate      PO_VENDOR_SITES_ALL.retainage_rate%type; --bug#5255878

    --<Bug:8598002 Enhanced Pricing Start:>
    l_enhanced_pricing_flag po_doc_style_headers.enhanced_pricing_flag%type;
    l_pricing_call_src VARCHAR2(5);
    --<Enhanced Pricing End>

BEGIN
        l_outsourced_assembly :=2; --<SHIKYU R12>
  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
    PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
  END IF;

  -- <ACHTML R12 START>
  -- Determine the Requesting OU from the current requisition line.
  -- If there is no backing req, take the globally determined Requesting OU.
  IF (interface.requisition_line_id IS NOT NULL)
  THEN
    BEGIN
      SELECT prl.org_id
      INTO   l_requesting_ou_id
      FROM   po_requisition_lines_all prl
      WHERE  prl.requisition_line_id = interface.requisition_line_id;
    EXCEPTION
      WHEN OTHERS
      THEN
        IF g_debug_unexp
        THEN
          PO_DEBUG.debug_exc(
            p_log_head => g_log_head||l_api_name,
            p_progress => l_progress
          );
        END IF;
        wrapup(interface.interface_header_id);
        po_message_s.sql_error('CREATE_LINE',l_progress,sqlcode);
        raise;
      END;
  ELSE
    l_requesting_ou_id := g_hdr_requesting_ou_id;
  END IF;

  -- Determine the currency conversion rate for the current line.
  -- If called from Sourcing, simply use the rate specified in the interface
  -- table.
  IF (g_interface_source_code <> 'SOURCING'
      AND g_purchasing_ou_id <> l_requesting_ou_id
      AND interface.document_subtype = 'STANDARD')
  THEN
    get_rate_for_req_price(
      p_requesting_ou_id => l_requesting_ou_id, -- IN
      p_purchasing_ou_id => g_purchasing_ou_id, -- IN
      p_po_currency_code => interface.h_currency_code, -- IN
      p_rate_type        => interface.h_rate_type, -- IN
      p_rate_date        => interface.h_rate_date, -- IN
      x_rate             => l_rate_for_req_fields -- OUT
    );
  END IF;

  IF (l_rate_for_req_fields IS NULL)
  THEN
    l_rate_for_req_fields := nvl(g_rate_for_req_fields, 1);
  END IF;
  -- <ACHTML R12 END>

   /* initialize values */
   x_quantity := interface.quantity;
   x_secondary_quantity_def := interface.secondary_quantity; -- Bug 9324837
   x_unit_of_measure := interface.unit_meas_lookup_code; -- Bug 2735840

   /* Bug 586033, lpo, 11/25/97
   ** When trying to autocreate a release from a req with multiple lines
   ** against a blanket and the blanket has lines that match only some
   ** (i.e. not all) of the req lines, interface.line_type_id will be null
   ** and the following SELECT statement would cause a NO_DATA_FOUND
   ** exception. Since the X_match_blanket_line variable hasn't been set
   ** to 'N', the exception handlier does a 'raise', causing the COMMIT
   ** statement in create_po() to be skipped. Added an if statement below
   ** so that it wouldn't raise NO_DATA_FOUND exception until the
   ** X_match_blanket_line variable is set to 'N' later in the code.
   */
   IF (interface.line_type_id IS NOT NULL) THEN  -- Bug 586033, lpo, 11/25/97
     l_progress := '010';
     SELECT order_type_lookup_code
     ,      purchase_basis                                    -- <SERVICES FPJ>
     INTO   x_order_type_lookup_code
     ,      l_purchase_basis                                  -- <SERVICES FPJ>
     FROM   po_line_types
     WHERE  line_type_id = interface.line_type_id;
   END IF;  -- Bug 586033, lpo, 11/25/97

   l_progress := '020';

   IF interface.h_currency_code IS NOT NULL THEN
        fnd_currency.get_info(interface.h_currency_code,
                            x_precision,
                            x_ext_precision,
                              x_min_unit );
   END IF;

    /*
    ** Check to see if the po line exists
    ** Note that we do not need to check if the line exists in the
    ** interface table since we are in the process of inserting
    ** lines into the po lines table on a record by record basis.
    */
    IF(g_document_subtype='STANDARD' or g_document_subtype='PLANNED' or
       g_document_type = 'RFQ'
       --<SOURCING TO PO FPH>
       --do the select for blanket also
       or g_document_subtype = 'BLANKET') THEN

      BEGIN

      l_progress := '030';
      SELECT po_line_id,
             line_type_id,
             line_num,
             item_id,
             item_revision,
             unit_meas_lookup_code,
             base_unit_price,   -- <FPJ Advanced Price>
             unit_price,
             transaction_reason_code,
             price_break_lookup_code,
             manual_price_change_flag --bug 3495772
        INTO x_po_line_id,
             x_po_line_type_id,
             x_line_num,
             x_po_item_id,
             x_po_item_revision,
             x_po_unit_meas_lookup_code,
             l_base_unit_price,   -- <FPJ Advanced Price>
             x_po_unit_price,
             x_po_transaction_reason_code,
             x_price_break_lookup_code,
             l_manual_price_change_flag --bug 3495772
        FROM PO_LINES_ALL  --<Shared Proc FPJ>
       WHERE PO_HEADER_ID = interface.po_header_id
         AND LINE_NUM = interface.line_num
         FOR UPDATE OF quantity;

       EXCEPTION
    WHEN NO_DATA_FOUND then
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
       END;

     ELSIF(g_document_subtype = 'RELEASE')THEN

      l_progress := '040';
      X_match_blanket_line := 'N';

/* Bug 2534534 Reverting the fix done in 1951084 */
--     BEGIN
      SELECT po_line_id
  INTO x_po_line_id
        FROM po_lines_all  --<Shared Proc FPJ>
       WHERE po_header_id = interface.po_header_id
         AND line_num = interface.line_num
         FOR UPDATE OF quantity;

/*      -- Bug 1951084 : added the exception handler

      EXCEPTION
    WHEN NO_DATA_FOUND then null;
       END;
*/

      X_match_blanket_line := 'Y';

     END IF;

     l_progress := '050';
     /*
     ** Bug 515985  ecso 10/9/97
     **       This procedure should be called even if line is not found
     ** when autocreating blanket releases
     */

    -- <BUG 3365446 START>
    --
    RCV_CORE_S.get_receiving_controls
    (   p_order_type_lookup_code      => x_order_type_lookup_code
    ,   p_purchase_basis              => l_purchase_basis
    ,   p_line_location_id            => NULL
    ,   p_item_id                     => interface.item_id
    ,   p_org_id                      => nvl(interface.destination_organization_id,params.inventory_organization_id)
    ,   p_vendor_id                   => interface.vendor_id
    ,   p_drop_ship_flag              => interface.drop_ship_flag
    ,   x_enforce_ship_to_loc_code    => rc.enforce_ship_to_location_code
    ,   x_allow_substitute_receipts   => rc.allow_substitute_receipts_flag
    ,   x_routing_id                  => rc.receiving_routing_id
    ,   x_routing_name                => l_routing_name
    ,   x_qty_rcv_tolerance           => rc.qty_rcv_tolerance
    ,   x_qty_rcv_exception_code      => rc.qty_rcv_exception_code
    ,   x_days_early_receipt_allowed  => rc.days_early_receipt_allowed
    ,   x_days_late_receipt_allowed   => rc.days_late_receipt_allowed
    ,   x_receipt_days_exception_code => rc.receipt_days_exception_code
    );
    -- <BUG 3365446 END>

-- bug# 3345108 defaults secondary qty /UOM and grade in SETUP_INTERFACE_TABLE.
-- no need to default it again here. comment out this logic.

/**
       --mchandak 02/11/2002
       --Bug# 2219743
       --Added logic to default secondary qnty,UOM and grade in po_lines
       --if common purchasing is installed for OPM dual item
       IF(g_document_subtype='STANDARD' or g_document_subtype='PLANNED') AND NOT GML_PO_FOR_PROCESS.check_po_for_proc
       THEN
           x_retvar := FND_INSTALLATION.get_app_info(x_product,x_opm_installed,x_dummy,x_dummy);
           BEGIN
                l_progress := '060';
                SELECT inventory_organization_id INTO x_inv_org_id
                  FROM financials_system_params_all  --<Shared Proc FPJ>
                 WHERE NVL(org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

                l_progress := '070';
                SELECT process_enabled_flag INTO x_process_org
                FROM   mtl_parameters
                WHERE  organization_id = x_inv_org_id;
           exception
           when others
           then
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                END IF;
               x_process_org := 'N';
           end;

           IF x_opm_installed = 'I' and x_process_org = 'Y' and
              interface.item_id is not null
           THEN
               BEGIN
                    l_progress := '080';
                    SELECT  segment1
                    INTO    x_item_number
                    FROM    mtl_system_items
                    WHERE
                        inventory_item_id = interface.item_id
                        AND  organization_id   = x_inv_org_id;

               EXCEPTION
               WHEN OTHERS
               THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                END IF;
                   x_item_number := NULL;
               END;

               l_progress := '090';

               GMIGUTL.GET_ITEM(x_item_number,ic_item_mst_rec,ic_item_cpg_rec);
               IF ic_item_mst_rec.item_no is not null
               THEN
                   interface.preferred_grade := ic_item_mst_rec.qc_grade;

                   IF ic_item_mst_rec.dualum_ind >= 1
                   THEN
                       interface.secondary_unit_of_measure:= po_gml_db_common.get_apps_uom_code(ic_item_mst_rec.item_um2);
                       x_order_opm_um := po_gml_db_common.get_opm_uom_code(interface.unit_meas_lookup_code);
                       po_gml_db_common.validate_quantity(
                                    ic_item_mst_rec.item_id,
                                    ic_item_mst_rec.dualum_ind,
                                    x_quantity,
                                    x_order_opm_um,
                                    ic_item_mst_rec.item_um2,
                                    x_secondary_qty);
                       interface.secondary_quantity := x_secondary_qty;
                   ELSE
                       interface.secondary_quantity := null;
                       interface.secondary_unit_of_measure := null;
                   END IF; -- ic_item_mst_rec.dualum_ind >= 1
               ELSE
                   interface.secondary_quantity := null;
                   interface.preferred_grade    := null;
                   interface.secondary_unit_of_measure := null;
               END IF; -- ic_item_mst_rec.item_no is not null
             ELSE
                   interface.secondary_quantity := null;
                   interface.preferred_grade    := null;
                   interface.secondary_unit_of_measure := null;
             END IF;
         END IF;
-- end of 2219743
**/

   l_progress := '100';

   -- Bug 2735840 START
   -- When autocreating a PO that references a GA, and the req line and
   -- GA line have different UOM's, convert to the GA's UOM if the
   -- UOM Convert profile is Yes. If UOM Convert is No, do not create
   -- this line.
   IF (interface.from_line_id IS NOT NULL)
      AND (g_document_subtype = 'STANDARD') THEN

     l_progress := '110';
     BEGIN
--bug#3612701 modified the sql to fetch type lookup code
--of the source document as well.
       SELECT pol.unit_meas_lookup_code,poh.type_lookup_code
       INTO l_ga_uom,l_from_type_lookup_code
       FROM po_lines_all pol,po_headers_all poh
       WHERE pol.po_line_id = interface.from_line_id
       and poh.po_header_id=interface.from_header_id
       and poh.po_header_id=pol.po_header_id;
--bug#3612701
     EXCEPTION
       WHEN OTHERS THEN
         IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
             PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                p_progress => l_progress);
         END IF;
         po_message_s.sql_error('CREATE_LINE',l_progress,sqlcode);
         wrapup(interface.interface_header_id);
         raise;
     END;

     l_progress := '120';
     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'req uom: '||interface.unit_meas_lookup_code||' uom: '||l_ga_uom
          ||'document type: ' || l_from_type_lookup_code);
     END IF;


     IF interface.unit_meas_lookup_code <> l_ga_uom THEN
       l_progress := '130';
--bug#3612701
       IF (nvl(l_uom_convert,'N') = 'Y' or l_from_type_lookup_code='QUOTATION') THEN
--bug#3612701
         -- Convert to the GA's UOM
         -- Bug 3793360 : use the po_uom_convert procedure and round 15
         l_conversion_rate :=  po_uom_s.po_uom_convert(interface.unit_meas_lookup_code,
                                                       l_ga_uom,
                                                       interface.item_id);

         x_quantity := round(x_quantity * l_conversion_rate , 15);
         x_unit_of_measure := l_ga_uom;
       ELSE -- UOM Convert is No, so do not create this line.
         IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
             PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: Requisition UOM is different from GA UOM, and the Convert UOM profile is No. This PO line will not be created.');
         END IF;
         RETURN;
       END IF;
     END IF; -- interface.unit_meas_lookup_code <> l_ga_uom

   END IF; -- interface.from_line_id IS NOT NULL ...
   -- Bug 2735840 END

   --<Bug:8598002 Enhanced Pricing Start: Check if pricing enhanced for the current style and set l_pricing_call_src>
   BEGIN
     SELECT NVL(SH.enhanced_pricing_flag,'N')
     INTO l_enhanced_pricing_flag
     FROM po_doc_style_headers SH
     WHERE  SH.style_id = interface.style_id;
   EXCEPTION
     WHEN OTHERS THEN
       l_enhanced_pricing_flag := 'N';
   END;

   --l_pricing_call_src is used to distinguish pricing calls from auto creation.
   --Also it is assumed that
   IF (l_enhanced_pricing_flag  = 'Y') THEN
     l_pricing_call_src := 'AUTO';
   ELSE
     l_pricing_call_src := NULL;
   END IF;
   --<Enhanced Pricing End: >

   /* if line does not exist */

   IF(x_po_line_id is NULL) THEN

       /* If item is not null get list price and taxable flag */

       l_progress:='140';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: PO line does not exist');
        END IF;


        IF(interface.item_id is not null) THEN

          item.list_price_per_unit := interface.unit_price;

          l_outsourced_assembly := po_core_s.get_outsourced_assembly(interface.item_id,
                                                interface.destination_organization_id);--<SHIKYU R12>


 /* Bug 919204 */
 /* made the receive close and invoice close tolerance to be picked up
  * from the lowest existing level by splitting the select.
  */
/* Bug 1018048
   Prior to the fix we were getting the values of receipt required
   flag and inspection required flag of the item/master org to
   default in the autocreated document and were not considering the
   values defined at item/destination organization.

  Now, we derive the values from the item/destination organization
  and if it is not defined at the  item/destination organization
  level, then we derive the values from the item/master organization.
*/

          l_progress := '150';
          begin
          SELECT msi.invoice_close_tolerance,
                 msi.receive_close_tolerance,
                 msi.inspection_required_flag,
                 msi.receipt_required_flag
            INTO item.invoice_close_tolerance,
                 item.receive_close_tolerance,
                 item.inspection_required_flag,
                 item.receipt_required_flag
            FROM mtl_system_items msi
           WHERE msi.inventory_item_id = interface.item_id
             AND msi.organization_id   = interface.destination_organization_id;

          exception
               when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    po_message_s.sql_error('Get Item/Org defaults',l_progress,sqlcode);
                    raise;
          end;

         l_progress := '160';

         begin
          SELECT decode(x_order_type_lookup_code, 'QUANTITY',
                        msi.list_price_per_unit/nvl(interface.h_rate,1),
                        1), --<Shared Proc FPJ><Bug 3808903>
                 decode(x_order_type_lookup_code, 'QUANTITY',
                        msi.market_price/nvl(interface.h_rate,1),
                        1), --<Shared Proc FPJ><Bug 3808903>
                 msi.taxable_flag,
                 msi.primary_uom_code,
                 nvl(item.inspection_required_flag,msi.inspection_required_flag),
                 nvl(item.receipt_required_flag,msi.receipt_required_flag),
                 nvl(item.invoice_close_tolerance,msi.invoice_close_tolerance),
                 nvl(item.receive_close_tolerance,msi.receive_close_tolerance),
                 decode(msi.tracking_quantity_ind,
                        g_chktype_TRACKING_QTY_IND,
                        msi.secondary_uom_code,NULL),--<INVCONV R12>
                 nvl(msi.grade_control_flag,'N') --<INVCONV R12>
            INTO item.list_price_per_unit,
                 item.market_price,
                 item.taxable_flag,
                 item.unit_meas_lookup_code,
                 item.inspection_required_flag,
                 item.receipt_required_flag,
                 item.invoice_close_tolerance,
                 item.receive_close_tolerance,
                 item.secondary_uom_code, --<INVCONV R12>
                 item.grade_control_flag  --<INVCONV R12>
            FROM mtl_system_items msi
           WHERE msi.inventory_item_id = interface.item_id
             AND msi.organization_id = params.inventory_organization_id;

         exception
               when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                 wrapup(x_interface_header_id);
                 po_message_s.sql_error('Get Item/Master org defaults',l_progress,sqlcode);
                    raise;
          end;
      ELSE  -- added by jbalakri for bug 2348729
/*  this case will reach when the item_id is null */
/* Bug#2674947 We need to initialize market_price also */
/* Bug#3545290 In case of One-time items i.e Item_id is NUll , the
               list price needed to be reinitialized.
*/
          item.market_price := '';
          item.taxable_flag := '';
          item.unit_meas_lookup_code := '';
          item.inspection_required_flag := '';
          item.receipt_required_flag := '';
          item.invoice_close_tolerance := '';
          item.receive_close_tolerance := '';
          item.list_price_per_unit := ''; --Bug 3545290
          item.secondary_uom_code := '';  --<INVCONV R12>
          item.grade_control_flag := '';  --<INVCONV R12>
      END IF; -- item id not null   Bug #2102149

      l_progress := '170';

-- Bug: 1702702 Select receipt required flag also at line type level
        begin
               SELECT nvl(item.receive_close_tolerance,receipt_close),
                      nvl(item.receipt_required_flag,receiving_flag)
               INTO item.receive_close_tolerance,
                    item.receipt_required_flag
               FROM po_line_types_v
               WHERE line_type_id = interface.line_type_id;
          exception
               when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    po_message_s.sql_error('Get Line type default',l_progress,sqlcode);
                    raise;
          end;

   l_progress := '180';

/*  Bug: 2106201 Select receipt required flag,inspection required flag
                 at vendor level before system option level to complete the
                 default logic
*/
  Begin
          select nvl(item.inspection_required_flag,
                                vendor.INSPECTION_REQUIRED_FLAG),
                  nvl(item.receipt_required_flag,
                                vendor.RECEIPT_REQUIRED_FLAG)
              into item.inspection_required_flag,
                  item.receipt_required_flag
              from po_vendors vendor
          where   vendor.vendor_id = interface.vendor_id;

      Exception
          when no_data_found then
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
          WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
              wrapup(x_interface_header_id);
              po_message_s.sql_error('Get vendor default',l_progress,sqlcode);
              raise;
      End;

   l_progress := '190';

/* Bug: 1322342 Select receipt required flag,inspection required flag
                receipt close tolerance and insp close tolerance
                also from po system parameters if not defined at above level
*/
    Begin
        select nvl(item.inspection_required_flag,
                                posp.INSPECTION_REQUIRED_FLAG),
                nvl(item.receipt_required_flag,
                                posp.RECEIVING_FLAG),
                nvl(item.invoice_close_tolerance,
                                posp.INVOICE_CLOSE_TOLERANCE),
                nvl(item.receive_close_tolerance,
                                posp.RECEIVE_CLOSE_TOLERANCE)
            into    item.inspection_required_flag,
                item.receipt_required_flag,
                item.invoice_close_tolerance,
                item.receive_close_tolerance
           FROM po_system_parameters_all posp  --<Shared Proc FPJ>
          WHERE NVL(org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

    Exception
        when no_data_found then
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
        WHEN OTHERS THEN
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            wrapup(x_interface_header_id);
            po_message_s.sql_error('Get po system default',l_progress,sqlcode);
            raise;
    End;
-- Bug: 1322342 If not defined at po system option level also then

   l_progress := '200';

        IF (item.inspection_required_flag is NULL) THEN
            item.inspection_required_flag := 'N';
        END IF;

        IF (item.receipt_required_flag is  NULL) THEN
            item.receipt_required_flag := 'N';
        END IF;
        IF (item.invoice_close_tolerance is NULL) THEN
            item.invoice_close_tolerance := '0';
        END IF;

        IF (item.receive_close_tolerance is NULL) THEN
            item.receive_close_tolerance := '0';
        END IF;

       --ELSE Bug #2102149
/* Bug 814174
   Prior to the fix, the list_price_per_unit was the same as the unit_price
   and not considering the rate factor.
   Made the changes to multiply the unit_price by the factor of rate
   for quantity based line types.
*/
          if (x_order_type_lookup_code = 'QUANTITY') then
             -- Bug 2715279. Changed interface.unit_price to item.list_price_per_unit
             -- on the RHS of the assignment
             -- Bug 3276529 change the paranthesis divide the unit price with rate
             -- and not the list price as it has already been divided in the select

      --<Shared Proc FPJ>
            item.list_price_per_unit := nvl(
              item.list_price_per_unit,
              (interface.unit_price / l_rate_for_req_fields) -- <ACHTML R12>
            );

          -- <SERVICES FPJ START>
          --
          ELSIF ( x_order_type_lookup_code = 'AMOUNT' ) THEN

              item.list_price_per_unit := 1;

          ELSE -- ( x_order_type_lookup_code IN ('FIXED PRICE','RATE') )

              item.list_price_per_unit := NULL;

          END IF;
          --
          -- <SERVICES FPJ END>

    -- Bug #2102149
    if (interface.item_id is null) then
    item.taxable_flag := '';
    item.unit_meas_lookup_code := '';
    end if;
      -- Bug #2102149

      l_progress := '210';
      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: line taxable_flag: '||item.taxable_flag);
      END IF;


        -- <Bug 3322948>
        -- Perform currency conversion on price/amount/quantity.
        XX_PO_INTERFACE_PKG.do_currency_conversion(
          p_order_type_lookup_code => x_order_type_lookup_code,
          p_interface_source_code  => g_interface_source_code,
          p_rate                   => l_rate_for_req_fields, -- <ACHTML R12>
          p_po_currency_code       => interface.h_currency_code,
          p_requisition_line_id    => interface.requisition_line_id,
          x_quantity               => x_quantity, -- IN/OUT
          x_unit_price             => interface.unit_price, -- IN/OUT
          x_base_unit_price        => interface.base_unit_price, -- IN/OUT
                                   -- <Bug 3401653>
          x_amount                 => interface.amount -- IN/OUT
        );


       /* set neg by preparer flag */
       interface.negotiated_by_preparer_flag := 'N';

        --<SOURCING TO PO FPH >Bug# 2288408
        --sourcing populates the unit price in bidder's currency, so we are
        -- not converting the currency. And sourcing does not have
  --list_price_per_unit and market price storred in their system,
  --so dont do the following for sourcing
        if g_interface_source_code <>'SOURCING' then
           IF (item.unit_meas_lookup_code=interface.unit_meas_lookup_code) THEN
              IF (item.list_price_per_unit <> '') THEN
                 IF (item.list_price_per_unit > interface.unit_price) THEN
              interface.negotiated_by_preparer_flag := 'Y';
                 END IF;
              END IF;
           END IF;
        end if;


       l_progress:='240';


       /* Enhancement Request from Proj Manufacturing
       ** ecso 10/22/97
       ** Conditions:
       ** - new RFQ
       ** - only one requisition line for the interface_header_id
       ** Action:
       ** - copy project_id  task_id from first req dist to RFQ line
       ** Future enhancement includes:
       ** - spliting req lines with multiple dist
       ** - group req lines by project/task
       */

/* Bug: 1526641 in order to propagate Project info we don't need the condition
        of req lines. It inhibits the situation when req lines are not grouped
        and Project info could propagate to the document being created. But
        certainly there is a limitation of removing this which is when there are
        two req lines and the first line does not have project info and the
        second line does then the project info does not propagate. Of course
        reason being we are not grouping lines on the basis of Project.
        But right now we are going ahead with this little enhancement.

       IF (g_document_type = 'RFQ') AND
    (nvl(g_req_lines_to_process,0) = 1)
       THEN
*/

       IF (g_document_type = 'RFQ') THEN
          l_progress := '240';

   BEGIN
     SELECT MIN(DISTRIBUTION_ID)
     INTO   x_req_dist_id
     FROM   PO_REQ_DISTRIBUTIONS_ALL  --<Shared Proc FPJ>
     WHERE  REQUISITION_LINE_ID = interface.requisition_line_id
           AND    PROJECT_ID IS NOT NULL
           AND    TASK_ID    IS NOT NULL;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
    WHEN OTHERS THEN
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            RAISE;
   END;

      -- Bug 5363922 Start
      -- Selecting Only Project ID If Task ID Null
 	          IF x_req_dist_id IS NULL THEN
 	                  BEGIN
 	                    SELECT MIN(DISTRIBUTION_ID)
 	                    INTO          x_req_dist_id
 	                    FROM          PO_REQ_DISTRIBUTIONS_ALL  --<Shared Proc FPJ>
 	                    WHERE  REQUISITION_LINE_ID = interface.requisition_line_id
 	                    AND    PROJECT_ID IS NOT NULL;
 	                  EXCEPTION
 	                   WHEN OTHERS THEN
 	                     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
 	                         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
 	                                            p_progress => l_progress);
 	                     END IF;
 	                     RAISE;
 	                  END;

 	          END IF;
  -- End Bug 5363922

     l_progress := '250';
   BEGIN
    SELECT project_id
     ,task_id
    INTO   x_project_id
     , x_task_id
    FROM   PO_REQ_DISTRIBUTIONS_ALL  --<Shared Proc FPJ>
    WHERE  DISTRIBUTION_ID = x_req_dist_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
    WHEN OTHERS THEN
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            RAISE;
   END;

       ELSE

   x_project_id := NULL;
   x_task_id := NULL;

       END IF;

      l_progress := '260';

       --<SOURCING TO PO FPH START>
       --default un_number_id,hazard_class_id from item attributes when
       --not backed by a req. Also default UOM for amount based lines for this
       --condition.
       If g_interface_source_code in ('SOURCING','CONSUMPTION_ADVICE') then -- CONSIGNED FPI
    if interface.requisition_line_id is null then
       begin
              l_progress:='270';
              select un_number_id,hazard_class_id
          into x_un_number_id,x_hazard_class_id
          from mtl_system_items
               where inventory_item_id = interface.item_id
           and organization_id   =params.inventory_organization_id;
              exception
         when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               when others then
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                    po_message_s.sql_error('Get un number,hazard class defaults'
          ,l_progress, sqlcode);
              raise;
       end;

       if x_order_type_lookup_code='AMOUNT' then
                begin
                l_progress:='280';
    select unit_of_measure
      into x_unit_of_measure
      from po_line_types
     where line_type_id= interface.line_type_id;
    exception
                 when others then
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                  po_message_s.sql_error('Get UOM for amount based lines- defaults', l_progress, sqlcode);
            raise;
          end;
       else
                x_unit_of_measure :=interface.unit_meas_lookup_code;
       end if;
          else
             x_un_number_id := interface.un_number_id;
             x_hazard_class_id := interface.hazard_class_id;
             x_unit_of_measure :=interface.unit_meas_lookup_code;
          end if;
       end if;
       --<SOURCING TO PO FPH END>

       l_progress := '290';

       IF(g_document_subtype='STANDARD' or g_document_subtype='PLANNED' or
          --<SOURCING TO PO FPH>
    --insert Blankets also
          g_document_subtype='BLANKET' or
    g_document_type = 'RFQ') THEN



         l_progress:='330';

         SELECT po_lines_s.nextval
           INTO x_po_line_id
           FROM sys.dual;

         l_progress:='340';

         /* GA FPI start */

        -- <SERVICES FPJ>
        --
        -- Call the Pricing API only when...
        --
        --    1) Autocreating a Standard PO or a BlANKET and pricing is enhanced for the style selected
        --    2) Source Document exists or the pricing is enhanced for the style selected
        --    3) Not a Consumption Advice
        --    4) Requisition Line's Contractor Status is not 'ASSIGNED'
        --       ( if the contractor status is 'ASSIGNED',
        --         then we take the price directly from the Requisition Line )
        --
        --    5) Not a complex work PO  <Complex Work R12>
        l_contractor_status := PO_SERVICES_PVT.get_contractor_status(interface.requisition_line_id);  --<Bug 3353109>
        --Bug:8598002 Enhanced Pricing: Enable pricing call for BLANKET document subtype if pricing enhanced for the style selected
        IF  (   ( g_document_subtype = 'STANDARD' OR
                (g_document_subtype = 'BLANKET' AND l_enhanced_pricing_flag = 'Y'))
            AND ( interface.from_line_id IS NOT NULL OR
                  -- <FPJ Advanced Price START>
                  interface.contract_id IS NOT NULL OR
                  l_enhanced_pricing_flag = 'Y') --Enhanced Pricing: Enable pricing call if pricing enhanced for the style selected
                  -- <FPJ Advanced Price END>
            AND ( g_interface_source_code <> 'CONSUMPTION_ADVICE' )
            AND (NOT p_is_complex_work_po) -- <Complex Work R12>
            AND ( l_contractor_status IS NULL OR l_contractor_status <> 'ASSIGNED' ) ) -- <BUG 3281227>  --<Bug 3353109>
        THEN

            l_progress := '350';
            -- <SERVICES FPJ START>
            --
            PO_SOURCING2_SV.get_break_price
            (  p_api_version    => 1.0
            ,  p_order_quantity   => x_quantity
            ,  p_ship_to_org    => interface.destination_organization_id
            ,  p_ship_to_loc    => get_ship_to_loc(interface.deliver_to_location_id)
            ,  p_po_line_id   => interface.from_line_id
            ,  p_cum_flag   => FALSE
            ,  p_need_by_date   => interface.need_by_date
            ,  p_line_location_id => NULL
            -- <FPJ Advanced Price START>
            ,  p_contract_id    => interface.contract_id
            ,  p_org_id     => g_purchasing_ou_id
            ,  p_supplier_id    => interface.vendor_id
            ,  p_supplier_site_id => interface.vendor_site_id
            ,  p_creation_date    => interface.creation_date
            ,  p_order_header_id  => interface.po_header_id
            ,  p_order_line_id    => x_po_line_id
            ,  p_line_type_id   => interface.line_type_id
            ,  p_item_revision    => interface.item_revision
            ,  p_item_id    => interface.item_id
            ,  p_category_id    => interface.category_id
            ,  p_supplier_item_num  => interface.vendor_product_num
            -- Bug 3343892, pass base_unit_price
            -- Bug 3417479, Only pass base_unit_price
            -- ,  p_in_price    => NVL(interface.base_unit_price, interface.unit_price)
            ,  p_in_price   => interface.base_unit_price
            ,  p_uom      => x_unit_of_measure
            ,  p_currency_code          => interface.h_currency_code  -- Bug 3564863
            --<Bug:8598002 Enhanced Pricing Start>
            ,  p_pricing_call_src => l_pricing_call_src
            --<Enhanced Pricing End>
            ,  x_base_unit_price  => l_base_unit_price
            -- <FPJ Advanced Price END>
            ,  x_price_break_id   => l_price_break_id
            ,  x_price      => x_unit_price
            ,  x_return_status    => l_return_status
            ,  p_req_line_price => interface.unit_price   -- Bug 7154646
            );
            -- <SERVICES FPJ END>

      -- Bug 3733202 START
      -- Treat 0 price as null price
      -- Bug 13863301
      -- Treating 0 price as null price for contract source document only
      IF (x_unit_price = 0 AND interface.from_line_id IS NULL)  THEN
        x_unit_price := NULL;
      END IF;
      -- Bug 3733202 END

            -- Bug 3417479
            x_unit_price := nvl(x_unit_price, interface.unit_price);
            l_base_unit_price := nvl(l_base_unit_price, interface.base_unit_price);

        ELSE

            x_unit_price := interface.unit_price;
            -- <FPJ Advanced Price START>
            -- Bug 3417479
            -- l_base_unit_price := nvl(interface.base_unit_price, x_unit_price);
            l_base_unit_price := interface.base_unit_price;
            -- <FPJ Advanced Price END>

        END IF;

         /* GA FPI end */
        l_progress := '360';

        -- <SERVICES FPJ START> If we are Autocreating a Standard PO,
        -- then setup the Interface tables to copy over Price Differentials.
        --<Bug 3268483>
        -- This functionality is not supported from Sourcing. One cannot
        -- create a Standard PO from Sourcing with Temp Labor lines (with price
        -- differentials).
        IF ( g_document_subtype = 'STANDARD' AND
             --<Bug 3268483>
             g_interface_source_code not in  ('SOURCING', 'CONSUMPTION_ADVICE')
           AND (NOT p_is_complex_work_po)) -- <Complex Work R12>
        THEN

            PO_PRICE_DIFFERENTIALS_PVT.setup_interface_table
            (   p_entity_type         => 'PO LINE'
            ,   p_interface_header_id => interface.interface_header_id
            ,   p_interface_line_id   => interface.interface_line_id
            ,   p_req_line_id         => interface.requisition_line_id
            ,   p_from_line_id        => interface.from_line_id
            ,   p_price_break_id      => l_price_break_id
            );
        END IF;
        --
        -- <SERVICES FPJ END>

        l_progress := '370';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: Line id: '||x_po_line_id);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: Header_id : '||interface.po_header_id);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: Line number: '||interface.line_num);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: TRX RSON CODE : '||interface.transaction_reason_code);
        END IF;

        l_progress := '380';
         -- <SERVICES FPJ START>
         -- Retrieve the values for order_type_lookup_code, purchase_basis
         -- and matching_basis
         PO_LINE_TYPES_SV.get_line_type_def(
                          interface.line_type_id,
                          l_order_type_lookup_code,
                          l_purchase_basis1,
                          l_matching_basis,
                          l_category_id,
                          l_unit_meas_lookup_code,
                          l_unit_price,
                          l_outside_operation_flag,
                          l_receiving_flag,
                          l_receive_close_tolerance);
         -- <SERVICES FPJ END>

   -- Bug 694504. frkhan 07/07/98. Removed decode for vendor_product_num
   -- so it is inserted for RFQs also.

--<DBI FPJ Start>
BEGIN
  IF g_interface_source_code='SOURCING' THEN
    l_negotiated_by_preparer_flag := 'Y';
  ELSIF interface.from_header_id is not null THEN
    l_progress := '390';
    SELECT type_lookup_code,global_agreement_flag into l_type_lookup_code,l_global_agreement_flag
    FROM po_headers_all
    WHERE po_header_id=interface.from_header_id;
    -- if the source document is global agreement.
    IF l_type_lookup_code='BLANKET' and l_global_agreement_flag='Y' THEN
      l_progress := '395';
      SELECT negotiated_by_preparer_flag into l_negotiated_by_preparer_flag
      FROM po_lines_all
      WHERE po_line_id=interface.from_line_id;
    --if the source document is quotation.
    ELSIF l_type_lookup_code='QUOTATION' THEN
      l_negotiated_by_preparer_flag := 'Y';
    -- if the source document is contract or otherwise
    -- <Bug 5177657> Changed ELSIF to ELSE
    ELSE
      l_progress := '400';
      SELECT negotiated_by_preparer_flag into l_negotiated_by_preparer_flag
      FROM po_requisition_lines_all
      WHERE requisition_line_id=interface.requisition_line_id;
    END IF;
  ELSE
    l_progress := '410';
    SELECT negotiated_by_preparer_flag into l_negotiated_by_preparer_flag
    FROM po_requisition_lines_all
    WHERE requisition_line_id=interface.requisition_line_id;
  END IF;
EXCEPTION
  WHEN others THEN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
    END IF;
    l_negotiated_by_preparer_flag:=NULL;
END;
-- <DBI FPJ End>

        l_progress := '420';

	-- Bug 9324837
	-- Added debug code.
	IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'g_document_subtype: '||g_document_subtype);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'interface.item_id : '||interface.item_id);
	    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'nterface.destination_organization_id: '||interface.destination_organization_id);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'params.inventory_organization_id : '||params.inventory_organization_id);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'item.secondary_uom_code : '||item.secondary_uom_code);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'interface.secondary_quantity : '||interface.secondary_quantity);
        END IF;

  --<INVCONV R12 START>
  -- IF secondary quantity is null and item is dual uom control , default the secondary qty.
  IF (g_document_subtype='STANDARD' OR g_document_subtype='PLANNED' OR g_document_type = 'PA')
  THEN
    IF interface.item_id is not null THEN
       IF item.secondary_uom_code IS NOT NULL THEN
          IF (interface.secondary_quantity IS NULL) THEN
           -- Bug 9324837
           -- Commented out the  OR condition to interface.secondary_quantity IS NULL
           -- as this was causing the secondary quantity to be recalculated using std conversion.
           -- OR  params.inventory_organization_id <> interface.destination_organization_id ) THEN
             PO_UOM_S.get_secondary_uom( interface.item_id,
                                         interface.destination_organization_id,
                                         x_secondary_uom,
                                         x_secondary_unit_def);

             IF g_document_type <> 'PA' THEN
                PO_UOM_S.uom_convert (x_quantity, x_unit_of_measure, interface.item_id,
                                      x_secondary_unit_def, x_secondary_quantity_def) ;

                IF interface.destination_organization_id  = params.inventory_organization_id
                THEN
                  interface.secondary_unit_of_measure := x_secondary_unit_def ;
                  interface.secondary_quantity := x_secondary_quantity_def ;
                END IF;
             ELSE
                x_secondary_quantity_def := null ;
             END IF;
          ELSE
             x_secondary_unit_def := interface.secondary_unit_of_measure;
             x_secondary_quantity_def := interface.secondary_quantity;
          END IF;
       ELSE -- IF item.secondary_uom_code IS NOT NULL
          x_secondary_unit_def := null;
          x_secondary_quantity_def := null ;
       END IF;

       IF item.grade_control_flag = 'N' and interface.preferred_grade IS NOT NULL THEN
          x_preferred_grade_def := null ;
       ELSE
          x_preferred_grade_def := interface.preferred_grade ;
       END IF;

    ELSE -- IF interface.item_id is not null
       x_secondary_unit_def := null;
       x_secondary_quantity_def := null ;
       x_preferred_grade_def    := null;
    END IF;
  ELSE
    x_secondary_unit_def := null;
    x_secondary_quantity_def := null ;
    x_preferred_grade_def    := null;
  END IF;
  --<INVCONV R12 END>

	-- Bug 9324837
	-- Added debug code.
	IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'x_secondary_unit_def : '||x_secondary_unit_def);
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'x_secondary_quantity_def : '||x_secondary_quantity_def);
        END IF;

-- bug 4887900 START
-- checking if the user has manually entered a value
-- bug#5255878
-- declared l_retainage_rate
-- bug#5262303 interface.vendor_site_id can be null
-- if the vendor/vendor_site combination is not provided
-- on the autocreate window. We should query only when
-- vendor_site_id is not null.
-- Bug 13556601 Included complex work flag to avoid copying retainage rate for other document types.
    IF(interface.vendor_site_id is not null AND p_is_complex_work_po)THEN
        SELECT retainage_rate
        into l_retainage_rate
        FROM po_vendor_sites_all
        WHERE vendor_site_id = interface.vendor_site_id;
    END IF;
-- bug 4887900 END

     -- Added note_to_vendor - iali 08/26/99
/*Bug 1391523 . Added market price to the INSERT statement */
        INSERT INTO po_lines_all  --<Shared Proc FPJ>
        (    po_line_id,
             last_update_date,
             last_updated_by,
             po_header_id,
             line_num,
             creation_date,
             created_by,
             last_update_login,
             item_id,
             job_id,                                          -- <SERVICES FPJ>
             category_id,
             item_description,
             unit_meas_lookup_code,
             list_price_per_unit,
             market_price,
             base_unit_price,             -- <FPJ Advanced Price>
             unit_price,
             quantity,
             amount,                                          -- <SERVICES FPJ>
             taxable_flag,
             type_1099,
             negotiated_by_preparer_flag,
             closed_code,
             item_revision,
             un_number_id,
             hazard_class_id,
             -- contract_num,   -- <GC FPJ>
             contract_id,        -- <GC FPJ>
             line_type_id,
             vendor_product_num,
             qty_rcv_tolerance,
             over_tolerance_error_flag,
             firm_status_lookup_code,
             min_release_amount,
             price_type_lookup_code,
             transaction_reason_code,
             from_header_id,
             from_line_id,
             from_line_location_id,                           -- <SERVICES FPJ>
             project_id,
             task_id,
             note_to_vendor,
             --togeorge 09/27/2000
             --added oke columns
             oke_contract_header_id,
             oke_contract_version_id,
             --togeorge 11/17/2000
             --Bug# 1369049
             --Added logic to default tax_name in po_lines
             tax_name,
             -- start of 1548597
             secondary_unit_of_measure,
             secondary_quantity,
             preferred_grade,
             -- end of  1548597
             --<SOURCING TO PO FPH START>
             auction_header_id,
             auction_line_number,
             auction_display_number,
             bid_number,
             bid_line_number,
             quantity_committed,    --Bug# 2288408
             committed_amount,    --Bug# 2288408
             --<SOURCING TO PO FPH END>
             --Bug #2715037
             price_break_lookup_code,
             supplier_ref_number, --<CONFIG_ID FPJ>
             org_id,  --<Shared Proc FPJ>
             start_date,                                      -- <SERVICES FPJ>
             expiration_date,                                 -- <SERVICES FPJ>
             contractor_first_name,                           -- <SERVICES FPJ>
             contractor_last_name,                            -- <SERVICES FPJ>
             order_type_lookup_code,                          -- <SERVICES FPJ>
             purchase_basis,                                  -- <SERVICES FPJ>
             matching_basis                                   -- <SERVICES FPJ>
             -- <Complex Work R12 Start>
           , retainage_rate
           , max_retainage_amount
           , progress_payment_rate
           , recoupment_rate             -- <Complex Work R12 End>
     ,tax_attribute_update_code --<eTax Integration R12>
            , ip_category_id      --Bug#4656615
            , supplier_part_auxid --Bug#4656615
            , catalog_name        --Bug#4656615
            , attribute_category -- OD CUSTOMIZATION Changed by Paul DSouza(V2.0)

      )
    VALUES (x_po_line_id,
                        interface.last_update_date,
                        interface.last_updated_by,
                        interface.po_header_id,
                        interface.line_num,
                        interface.creation_date,
                        interface.created_by,
                        interface.last_update_login,
                        interface.item_id,
                        interface.job_id,                     -- <SERVICES FPJ>
                        interface.category_id,
                        interface.item_description,
                        x_unit_of_measure, -- Bug 2735840
        --<SOURCING TO PO FPH >Bug# 2288408
        --sourcing populates the unit price in bidder's currency, so we are
        -- not converting the currency. And sourcing does not have
  --list_price_per_unit and market price stored in their system,
  --so dont do the following for sourcing
   -- Bug 3472140: Changed precisions to 15 from 5
   -- Bug 3808903: Changed rounding to use extended_precision
                        decode(g_document_type, 'RFQ', null,
      decode(g_interface_source_code,'SOURCING',null,
                             ROUND(item.list_price_per_unit,nvl(x_ext_precision,15)))),
                             ROUND(item.market_price,nvl(x_ext_precision,15)),--11806518
    --
-- Bug 1353736   use precision in rounding
/* Bug: 2000367  When there is no currency conversion involved we should not
                 round at all because it gives rise to inconsistency.
                 So removing the ext precision and blind rounding to 5 also as
                 this is already done above in case when currency conversion is
                 involved.
*/
                        l_base_unit_price  , --interface.base_unit_price, -- <FPJ Advanced Price>
                        x_unit_price  , --interface.unit_price,
                        --<SOURCING TO PO FPH>
      --quantity sould be null for a blanket
                        decode(g_document_type, 'RFQ', 1,'PA',null, x_quantity),
                        interface.amount,                     -- <SERVICES FPJ>
                        nvl(item.taxable_flag,params.taxable_flag),
                        decode(g_document_type, 'RFQ', null,
        vendor.type_1099),
                        l_negotiated_by_preparer_flag, --<DBI FPJ>
                        interface.l_closed_code,
                        interface.item_revision,
                        --<SOURCING TO PO FPH START>
                        decode(g_interface_source_code,'SOURCING',
                               x_un_number_id,interface.un_number_id),
                        decode(g_interface_source_code,'SOURCING',
             x_hazard_class_id,interface.hazard_class_id),
                        --<SOURCING TO PO FPH END>
                        -- interface.contract_num,  -- <GC FPJ>
                        /* Modified for Bug# 8446396 */
			/* Bug11802312 - Retain the document reference for a consigned PO */
                        interface.contract_id,       -- <GC FPJ>
                        interface.line_type_id,
                        interface.vendor_product_num,

	/*bug 9155693 START-->
            While autocreating RFQ from Req. receiving controls values were set to NULL
            which cause receiving controls values reamin NULL in PO, which was created
            by copying RFQ to Quotation to PO.
            Hence, setting receving control fields to defaulted values.

         decode(g_document_type, 'RFQ', null,
            rc.qty_rcv_tolerance),
         decode(g_document_type, 'RFQ', null,
            rc.qty_rcv_exception_code),
        */
                        rc.qty_rcv_tolerance,
                        rc.qty_rcv_exception_code,
         --bug 9155693 END

                        interface.l_firm_status_lookup_code,
                        interface.l_min_release_amount,
                        interface.price_type_lookup_code,
                        interface.transaction_reason_code,
                        /* Modified for Bug# 8446396 */
			/* Bug11802312 - Retain the document reference for a consigned PO */
                        nvl(interface.from_header_id,x_quote_header_id),
                        nvl(interface.from_line_id,x_quote_line_id),
                        DECODE(interface.consigned_flag,'Y',NULL,l_price_break_id),                       -- <BUG 3282527>
      x_project_id,
      x_task_id,
                        --<SOURCING TO PO FPH>
      --dont copy note to vendor for sourcing this
      --would come as attachments from sourcing.
      decode(g_interface_source_code,'SOURCING',
          null,interface.note_to_vendor),
      --interface.note_to_vendor,
      --
            --togeorge 09/27/2000
            --added oke columns
            /* Modified for Bug# 8446396 */
	    /* Bug11802312 - Retain the document reference for a consigned PO */
           interface.oke_contract_header_id,
           interface.oke_contract_version_id,
            --togeorge 11/17/2000
            --Bug# 1369049
            --Added logic to default tax_name in po_lines
      x_tax_name,
--<INVCONV R12 START>
-- don't insert secondary unit/quantity/grade from interface record.
-- start of 1548597
      x_secondary_unit_def,
      x_secondary_quantity_def,
      x_preferred_grade_def,
-- end of  1548597
--<INVCONV R12 END>
                        --<SOURCING TO PO FPH START>
                  interface.auction_header_id,
                  interface.auction_line_number,
            interface.auction_display_number,
                  interface.bid_number,
                  interface.bid_line_number,
                    decode ( g_document_type
                           , 'PA' , decode ( x_order_type_lookup_code
                                           , 'AMOUNT' , NULL
                                           , interface.quantity
                                           )
                           , NULL
                           ),
                    decode ( g_document_type
                           , 'PA' , decode ( x_order_type_lookup_code
                                           , 'QUANTITY' , NULL-- <SERVICES FPJ>
                                           , interface.committed_amount
                                           )
                           , NULL
                           ),
                        --<SOURCING TO PO FPH END>
                        --Bug #2715037
                        decode(g_interface_source_code,'SOURCING',
                              interface.price_break_lookup_code, null),
                        interface.supplier_ref_number, --<CONFIG_ID FPJ>
                        g_purchasing_ou_id,  --<Shared Proc FPJ>
                        interface.line_effective_date,        -- <SERVICES FPJ>
                        interface.line_expiration_date,       -- <SERVICES FPJ>
                        interface.contractor_first_name,      -- <SERVICES FPJ>
                        interface.contractor_last_name,       -- <SERVICES FPJ>
                        l_order_type_lookup_code,             -- <SERVICES FPJ>
                        l_purchase_basis1,                    -- <SERVICES FPJ>
                        l_matching_basis                      -- <SERVICES FPJ>
                        -- <Complex Work R12 Start>
                      , nvl(interface.retainage_rate, l_retainage_rate) -- bug 4887900 bug#5255878
                      , interface.max_retainage_amount
                      , interface.progress_payment_rate
                      , interface.recoupment_rate                 -- <Complex Work R12 End>
          ,nvl2(g_calculate_tax_flag, 'CREATE', null) --<eTax Integration R12>
            , interface.ip_category_id      --Bug#4656615
            , interface.supplier_part_auxid --Bug#4656615
            , interface.catalog_name        --Bug#4656615
            , interface.attribute_category  --OD CUSTOMIZATION Changed by Paul DSouza(V2.0)
      );

        l_progress := '430';

        -- <Unified Catalog R12 START>
        IF (g_document_subtype = 'BLANKET'  AND g_interface_source_code = 'SOURCING') THEN

          IF g_debug_stmt THEN PO_DEBUG.debug_stmt(d_mod,l_progress,'Storing values of PO_LINE_IDs for the Attribute interface records');END IF;

          l_interface_header_id_tbl(x_po_line_id) := interface.interface_header_id;
          l_interface_line_id_tbl(x_po_line_id) := interface.interface_line_id;
          l_po_line_id_tbl(x_po_line_id) := x_po_line_id;
        END IF;
        -- <Unified Catalog R12 END>


        -- <SERVICES FPJ START> Insert Price Differentials into main table
        -- from the interface table.
        --
        PO_PRICE_DIFFERENTIALS_PVT.create_from_interface
        (   p_entity_id         => x_po_line_id
        ,   p_interface_line_id => interface.interface_line_id
        );
        -- <SERVICES FPJ END>

        l_progress := '440';

/* Bug 2962568 globalization procedure shouldn't be called for Standard RFQ's
   as it is not significant for the same.
*/
            if g_document_type = 'RFQ' then
               null;
            elsif (interface.document_subtype = 'STANDARD' or
                interface.document_subtype = 'PLANNED'  or
                --<SOURCING TO PO FPH START>
                interface.document_subtype = 'BLANKET'
    ) THEN

                -- Bug 882050: Line level global attribute
                -- <Bug 8513167>
                -- Now passing document_subtype instead of 'PO'
                calculate_local(interface.document_subtype, 'LINE', x_po_line_id);

            end if;

         END IF;

   ELSE /* If line exists */

        l_progress := '450';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Line does exist: '||x_po_line_id);
        END IF;

      --<SOURCING TO PO FPH START>
      --lines are grouped, so dont copy any attachments from sourcing(copy only
      --from the req)
      IF g_interface_source_code='SOURCING' then
         x_attch_suppress_flag  :='Y';
      END IF;
      --<SOURCING TO PO FPH END>

      IF(interface.item_id is not null) THEN

   /*
    * bug 1009734 : extention of bug 919204
    * made the receive close and invoice close tolerance to be picked up
    * from the lowest existing level by splitting the select.
    * HAD TO DO THE SAME EVEN IF PO LINE ID IS NOT NULL
    * ONLY FOR INVOICE CLOSE TOLERANCE AND RECEIVE CLOSE TOLERANCE
    */

      l_progress := '460';
/* Bug# 1702702 - RSHAHI:  Start fix
    ** Need to do the same even if po line id is not null
    ** for receipt_required_flag and inspection_required_flag too
*/
         begin
          SELECT msi.invoice_close_tolerance,
                 msi.receive_close_tolerance,
                 msi.receipt_required_flag,
                 msi.inspection_required_flag
            INTO item.invoice_close_tolerance,
                 item.receive_close_tolerance,
                 item.receipt_required_flag,
                 item.inspection_required_flag
            FROM mtl_system_items msi
           WHERE msi.inventory_item_id = interface.item_id
             AND msi.organization_id   = interface.destination_organization_id;

          exception
               when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    po_message_s.sql_error('Get Item/Org defaults',l_progress,sqlcode);
                    raise;
          end;
      l_progress := '470';
-- Bug: 1702702
         begin
          SELECT nvl(item.invoice_close_tolerance,msi.invoice_close_tolerance),
                 nvl(item.receive_close_tolerance,msi.receive_close_tolerance),
                 nvl(item.receipt_required_flag,msi.receipt_required_flag),
                 nvl(item.inspection_required_flag,msi.inspection_required_flag),
                 decode(msi.tracking_quantity_ind,
                        g_chktype_TRACKING_QTY_IND,
                        msi.secondary_uom_code,NULL) --<INVCONV R12>
            INTO item.invoice_close_tolerance,
                 item.receive_close_tolerance,
                 item.receipt_required_flag,
                 item.inspection_required_flag,
                 item.secondary_uom_code --<INVCONV R12>
            FROM mtl_system_items msi
           WHERE msi.inventory_item_id = interface.item_id
             AND msi.organization_id = params.inventory_organization_id;
          exception
               when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    po_message_s.sql_error('Get Item/Master org defaults',l_progress,sqlcode);
                    raise;
          end;
      ELSE  -- added by jbalakri for bug 2348729

/* This case will reach when the item_id is null */
/* Bug#2674947 We need to initialize market_price also */
          item.market_price := '';
          item.invoice_close_tolerance := '';
          item.receive_close_tolerance := '';
          item.inspection_required_flag := '';
          item.receipt_required_flag := '';
          item.secondary_uom_code := ''; --<INVCONV R12>

      END IF; -- item id is not null Bug #2102149
      l_progress := '480';
-- Bug: 1702702
          begin
               SELECT nvl(item.receive_close_tolerance,receipt_close),
                      nvl(item.receipt_required_flag,receiving_flag)
               INTO item.receive_close_tolerance,
                    item.receipt_required_flag
               FROM po_line_types_v
               WHERE line_type_id = interface.line_type_id;
          exception
               when no_data_found then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
               WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    po_message_s.sql_error('Get Line type default',l_progress,sqlcode);
                    raise;
          end;

      l_progress := '490';

/*  Bug: 2106201 Select receipt required flag,inspection required flag
                 at vendor level before system option level to complete the
                 default logic
*/
  Begin
          select nvl(item.inspection_required_flag,
                                vendor.INSPECTION_REQUIRED_FLAG),
                  nvl(item.receipt_required_flag,
                                vendor.RECEIPT_REQUIRED_FLAG)
              into item.inspection_required_flag,
                  item.receipt_required_flag
              from po_vendors vendor
          where   vendor.vendor_id = interface.vendor_id;

      Exception
          when no_data_found then
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
          WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
              wrapup(x_interface_header_id);
              po_message_s.sql_error('Get vendor default',l_progress,sqlcode);
              raise;
      End;

      l_progress := '500';

/* Bug: 1322342 Select receipt required flag,inspection required flag
                receipt close tolerance and insp close tolerance
                also from po system parameters if not defined at above level
*/
    Begin
        select nvl(item.inspection_required_flag,
                                posp.INSPECTION_REQUIRED_FLAG),
                nvl(item.receipt_required_flag,
                                posp.RECEIVING_FLAG),
                nvl(item.invoice_close_tolerance,
                                posp.INVOICE_CLOSE_TOLERANCE),
                nvl(item.receive_close_tolerance,
                                posp.RECEIVE_CLOSE_TOLERANCE)
            into    item.inspection_required_flag,
                item.receipt_required_flag,
                item.invoice_close_tolerance,
                item.receive_close_tolerance
           FROM po_system_parameters_all posp  --<Shared Proc FPJ>
          WHERE NVL(org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

    Exception
        when no_data_found then
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
        WHEN OTHERS THEN
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            wrapup(x_interface_header_id);
            po_message_s.sql_error('Get po system default',l_progress,sqlcode);
            raise;
    End;

      l_progress := '510';
-- Bug: 1322342 If not defined at po system option level also then

        IF (item.inspection_required_flag is NULL) THEN
            item.inspection_required_flag := 'N';
        END IF;

        IF (item.receipt_required_flag is  NULL) THEN
            item.receipt_required_flag := 'N';
        END IF;
        IF (item.invoice_close_tolerance is NULL) THEN
            item.invoice_close_tolerance := '0';
        END IF;

        IF (item.receive_close_tolerance is NULL) THEN
            item.receive_close_tolerance := '0';
        END IF;

       --ELSE Bug #2102149
  /* Bug #2102149
    item.invoice_close_tolerance := '';
    item.receive_close_tolerance := '';
-- Bug: 1702702
          item.inspection_required_flag := '';
          item.receipt_required_flag := '';

       END IF;
       */

-- Bug: End fix 1702702

      IF (g_document_type = 'PO') THEN

         l_progress:='520';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: Po line exists');
        END IF;

        -- <BUG 3322948> Perform currency conversion on price/amount/quantity.
        --
        XX_PO_INTERFACE_PKG.do_currency_conversion(
          p_order_type_lookup_code => x_order_type_lookup_code,
          p_interface_source_code  => g_interface_source_code,
          p_rate                   => l_rate_for_req_fields, -- <ACHTML R12>
          p_po_currency_code       => interface.h_currency_code,
          p_requisition_line_id    => interface.requisition_line_id,
          x_quantity               => x_quantity, -- IN/OUT
          x_unit_price             => interface.unit_price, -- IN/OUT
          x_base_unit_price        => interface.base_unit_price, -- IN/OUT
                                                                 -- <Bug 3401653>
--fix 8976669
--modified parameter x_amount as in x_quantity as the procedure was not returning x_amount
          x_amount                 => x_amount -- IN/OUT
        );

      l_progress := '530';

         /* handled the null value for quantity in the following update statement.
            bug 935866 */
         -- update secondary quantity to somevalue only if old or new secondary_quantity is not null else update it
         -- to null(for discrete items) - 1548597

         --Bug:8598002
         /* GA FPI start : For a standard PO if the source document exists or if the
            enhanced pricing style is used then we call the pricing API to get the
            correct price for the parameters on the requisition */
         IF (g_document_subtype='STANDARD')
            AND nvl(l_manual_price_change_flag, 'N') <> 'Y' --bug 3495772
            AND (interface.from_line_id IS NOT NULL OR
                 -- <FPJ Advanced Price START>
                 interface.contract_id IS NOT NULL OR
                  l_enhanced_pricing_flag = 'Y') --Enhanced Pricing: Enable pricing call if pricing enhanced for the style selected
                 -- <FPJ Advanced Price END>
            AND  g_interface_source_code <> 'CONSUMPTION_ADVICE'  THEN
            /*bug#2723479 In this case, we will be updating an existing po
             *line by adding a req line to it. So we use the combined quantity
             *(existing po qty + req qty) when calling the pricing API. */
            l_progress := '540';
      begin
    select pl.quantity
        into l_db_quantity
        from po_lines_all pl  --<Shared Proc FPJ>
        where pl.po_line_id = x_po_line_id;
      exception
    when others then
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                END IF;
      end;

            l_progress := '550';
            -- Bug 3201308
            -- We get the pricing criteria from the min shipment if the grouping
            -- profiles are set such that multiple shipments get created when
            -- need by or ship to info are different on different lines.

            PO_SOURCING2_SV.get_min_shipment_num(x_po_line_id,l_min_shipment_num);

            l_progress := '560';
            BEGIN
                 select poll.ship_to_location_id,
                        poll.ship_to_organization_id,
                        poll.need_by_date
                 into   l_ship_to_loc,
                        l_ship_to_org,
                        l_need_by_date
                 from   po_line_locations_all poll
                 where  poll.po_line_id =  x_po_line_id
                 and    poll.shipment_num = l_min_shipment_num;
            EXCEPTION
                  when others then
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                    END IF;
            END;

            -- Get the profile option values to determine grouping criteria

            l_needby_prf := fnd_profile.value('PO_NEED_BY_GROUPING');
            l_shipto_prf := fnd_profile.value('PO_SHIPTO_GROUPING');

            IF nvl(l_needby_prf,'Y') = 'Y' THEN
               l_need_by_date := interface.need_by_date;
            END IF;

            l_progress := '570';

            IF nvl(l_shipto_prf,'Y') = 'Y' THEN
               l_ship_to_org :=  interface.destination_organization_id;
               l_ship_to_loc :=  get_ship_to_loc(interface.deliver_to_location_id);
            END IF;

            l_progress := '580';
            -- <FPJ Advanced Price START>
            PO_SOURCING2_SV.get_break_price
            (  p_api_version       => 1.0
            ,  p_order_quantity    => x_quantity + nvl(l_db_quantity,0)
            ,  p_ship_to_org       => l_ship_to_org           -- Bug 3201308
            ,  p_ship_to_loc       => l_ship_to_loc           -- Bug 3201308
            ,  p_po_line_id        => interface.from_line_id
            ,  p_cum_flag          => FALSE
            ,  p_need_by_date      => l_need_by_date          -- Bug 3201308
            ,  p_line_location_id  => NULL
            ,  p_contract_id       => interface.contract_id
            ,  p_org_id            => g_purchasing_ou_id
            ,  p_supplier_id       => interface.vendor_id
            ,  p_supplier_site_id  => interface.vendor_site_id
            ,  p_creation_date     => interface.creation_date
            ,  p_order_header_id   => interface.po_header_id
            ,  p_order_line_id     => x_po_line_id
            ,  p_line_type_id      => interface.line_type_id
            ,  p_item_revision     => interface.item_revision
            ,  p_item_id           => interface.item_id
            ,  p_category_id       => interface.category_id
            ,  p_supplier_item_num => interface.vendor_product_num
            -- Bug 3343892, pass base_unit_price
            -- Bug 3417479, only pass base_unit_price
            -- ,  p_in_price          => NVL(interface.base_unit_price, interface.unit_price)
            ,  p_in_price          => interface.base_unit_price
            ,  p_uom               => x_unit_of_measure
            ,  p_currency_code     => interface.h_currency_code  -- Bug 3564863
            --<Bug:8598002 Enhanced Pricing Start>
            ,  p_pricing_call_src     => l_pricing_call_src
            --<Enhanced Pricing End>
            ,  x_base_unit_price   => l_base_unit_price
            ,  x_price_break_id    => l_price_break_id
            ,  x_price             => x_unit_price
            ,  x_return_status     => l_return_status
            );
            -- <FPJ Advanced Price END>

      -- Bug 3733202 START
      -- Treat 0 price as null price
      IF (x_unit_price = 0) THEN
        x_unit_price := NULL;
      END IF;
      -- Bug 3733202 END

             -- Bug 2879460 Update the price on the PO only with the price
             -- from the pricing API and not with the interface price

            UPDATE po_lines_all
            -- Bug 3417479
            -- SET   unit_price = x_unit_price,
            --       base_unit_price = l_base_unit_price,
            SET   unit_price = nvl(x_unit_price, unit_price),
                  base_unit_price = nvl(l_base_unit_price, base_unit_price),
                  from_line_location_id = l_price_break_id      -- <BUG 3282527>
            WHERE po_line_id = x_po_line_id;

            --<Bug 3313010 mbhargav START>
            --All the shipments which have been created need to get the
            --new price as on the line for Standard POs.
            UPDATE po_line_locations_all
            -- Bug 3417479
            -- SET price_override = x_unit_price
            SET price_override = nvl(x_unit_price, price_override)
            -- Bug 4902592. Not setting tax_attribute_update_code here because
            -- it should be passed as CREATE during tax calculation
            WHERE po_line_id = x_po_line_id;
            --<Bug 3313010 mbhargav END>

         END IF;

         /* GA FPI end */

       l_progress := '590';
       --<BUG 2698737 mbhargav START>
       --This update should not happen for RELEASES as this would update the BLANKET with REQ price
       -- because x_po_line_id is the blanket line_id for 'Release'
       -- Introducing the 'If' statement for checking that its not a release
       IF (g_document_subtype <> 'RELEASE') THEN

     /** If FSP org and item combination is dual uom control, update the po lines secondary quantity
      with the default conversion based on the PO lines quantity **/

       --<INVCONV R12> update secondary quantity/uom to null

	-- Bug 9324837
        -- Added debug.
	IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >

          	PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'interface.secondary_quantity' || interface.secondary_quantity);
          	PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => ' x_quantity' || x_quantity);
           	PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'x_secondary_quantity_def' || x_secondary_quantity_def);
      	END IF;

      	 -- Bug 9324837
      	 -- Added update to secondary_quantity and commented the seconday null updates.
         UPDATE po_lines_all  --<Shared Proc FPJ>
--fix 8976669
--Added a Decode for the nvl function as quantity should not be set to 0 for Fixed Price Services
	SET quantity = Decode(x_order_type_lookup_code,'FIXED PRICE',NULL,Nvl(quantity,0)) + nvl(x_quantity,0),
	     secondary_quantity = (CASE        -- secondary uom controlled item
             			   WHEN g_chktype_TRACKING_QTY_IND = 'PS'
             			   THEN  secondary_quantity + x_secondary_quantity_def
             			   ELSE NULL
            			   END),
--Added update for amount in the line level
	     amount = Nvl(amount,0) + x_amount,
             last_update_date  = interface.last_update_date,
             last_updated_by   = interface.last_updated_by,
             last_update_login = interface.last_update_login,
             closed_code = 'OPEN',
             closed_date = NULL,
-- Bug 1199462 Amitabh
             closed_by   = NULL
             --secondary_quantity = null, --<INVCONV R12>
             --secondary_unit_of_measure = null --<INVCONV R12>
         WHERE po_line_id = x_po_line_id
         RETURNING quantity INTO l_quantity_temp; --<INVCONV R12>

         --<INVCONV R12 START>
         IF (item.secondary_uom_code IS NOT NULL
             AND l_quantity_temp > 0
             AND  x_secondary_quantity_def IS NULL ) THEN -- bug 9324837
            SELECT unit_of_measure
            INTO   x_secondary_unit_def
            FROM   mtl_units_of_measure
            WHERE  uom_code = item.secondary_uom_code ;

            PO_UOM_S.uom_convert (l_quantity_temp,
                                  x_unit_of_measure,
                                  interface.item_id,
                                  x_secondary_unit_def,
                                  x_secondary_quantity_def) ;

            UPDATE po_lines_all
            SET secondary_quantity = x_secondary_quantity_def,
                secondary_unit_of_measure = x_secondary_unit_def
            WHERE po_line_id = x_po_line_id ;

         END IF;
         --<INVCONV R12 END>

       END IF; --Release check for update
       --<BUG 2698737 mbhargav END>

      END IF;
   END IF;

     l_progress := '600';

    l_progress := '610';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Before going to create shipments');
    END IF;

   --<RENEG BLANKET FPI START>
   /* Create the shipment  or price break*/
   -- if the request is coming from Sourcing and document is Blanket
   -- then call create_price_break else call create_shipment
   IF g_document_subtype = 'BLANKET'
   THEN
     IF (g_interface_source_code = 'SOURCING'
         AND nvl(interface.shipment_type,'NONE') = 'PRICE BREAK')
     THEN
       create_price_break(x_po_line_id,
        x_line_location_id,
        l_outsourced_assembly); --<SHIKYU R12>
     END IF;
   -- <Complex Work R12 Start>
   ELSIF (p_is_complex_work_po)
   THEN

     -- x_line_location_id will be line_location_id of first actuals pay items.
     -- l_line_loc_id_tbl will return ids of all pay items created

     create_payitems(
       p_interface_line_id  => interface.interface_line_id
     , p_po_line_id         => x_po_line_id
     , p_precision          => x_precision
     , p_ext_precision      => x_ext_precision
     , x_line_location_id   => x_line_location_id
     , x_line_loc_id_tbl    => l_line_loc_id_tbl
     );

   -- <Complex Work R12 End>
   ELSE
     create_shipment(
       x_po_line_id,
       l_rate_for_req_fields, -- <ACHTML R12>
       x_line_location_id,
       l_outsourced_assembly --<SHIKYU R12>
     );
   END IF;

  /* Following Code commented as the below stated condition is included in
      FPI code above*/
   --<SOURCING TO PO FPH>
   --No need to create shipments for BLANKETS
   /*
   if g_document_subtype <>'BLANKET' then
   create_shipment(x_po_line_id,
                   x_line_location_id);
   end if;
   */
   --<RENEG BLANKET FPI END>

   l_progress:='620';

    -- <SERVICES FPJ START>
    --
    ---------------------------------------------------------------------------
    -- Req Line (TEXT) -> PO Line (Attachment) --------------------------------
    ---------------------------------------------------------------------------
    -- "Temp Labor" Lines have a Job Long Description, which resides on the
    -- Requisition Line as a LONG Text column, but needs to be copied over
    -- as an attachment on the PO Line.
    --
    IF ( l_purchase_basis = 'TEMP LABOR' ) THEN

        -- Get the Job Long Description from the Req Line.
        --
        l_job_long_description := PO_SERVICES_PVT.get_job_long_description
                                  (    p_req_line_id => interface.requisition_line_id
                                  );

        -- If Job Long Description exists, convert it to an attachment.
        --
        IF ( l_job_long_description IS NOT NULL ) THEN

            -- Initialize Standard WHO Columns.
            --
            l_who_rec.created_by := interface.created_by;
            l_who_rec.creation_date := interface.creation_date;
            l_who_rec.last_update_login := interface.last_update_login;
            l_who_rec.last_updated_by := interface.last_updated_by;
            l_who_rec.last_update_date := interface.last_update_date;

            l_progress := '630';

            -- Call Text-to-Attachment Conversion procedure
            --
            PO_NEGOTIATIONS_SV2.convert_text_to_attachment
            (   p_long_text      => l_job_long_description
            ,   p_description    => NULL
            ,   p_category_id    => 33                    -- To Supplier
            ,   p_to_entity_name => 'PO_LINES'
            ,   p_to_pk1_value   => x_po_line_id
            ,   p_who_rec        => l_who_rec
            );

        END IF; -- ( l_job_long_description IS NOT NULL )

    END IF; -- ( l_purchase_basis = 'TEMP LABOR' )
    --
    -- <SERVICES FPJ END>


/*Bug # 712445 smathur*/
/*For Releases copy attachments to PO_SHIPMENTS */

   if (g_document_subtype = 'RELEASE') and g_interface_source_code <> 'CONSUMPTION_ADVICE' then
                                                                       -- CONSIGNED FPI

   l_progress := '640';
   --  API to copy attachments from requisition line to release shipment
   fnd_attached_documents2_pkg.
       copy_attachments('REQ_LINES',
      interface.requisition_line_id,
      '',
      '',
      '',
      '',
      'PO_SHIPMENTS',
      x_line_location_id,
      '',
      '',
      '',
      '',
      interface.created_by,
      interface.last_update_login,
      '',
      '',
      '');

   l_progress:='650';

   -- Copy of the requisition header attachements to the purchase
   -- order line.
   SELECT requisition_header_id
   INTO   x_requisition_header_id
   FROM   po_requisition_lines_all  --<Shared Proc FPJ>
   WHERE  requisition_line_id = interface.requisition_line_id;

   l_progress:='660';

   fnd_attached_documents2_pkg.
      copy_attachments('REQ_HEADERS',
      x_requisition_header_id,
      '',
      '',
      '',
      '',
      'PO_SHIPMENTS',
      x_line_location_id,
      '',
      '',
      '',
      '',
      interface.created_by,
      interface.last_update_login,
      '',
      '',
      '');
    else /*smathur*/
   --  API to copy attachments from requisition line to po line
   --<SOURCING TO PO FPH>

/* Copying the attachments functionaliy needs to work as following.
   when g_interface_source_code='SOURCING'
  1.The existing fnd_attched_documents2_pkg.copy_attachments will not
    be copying any attachments.
    The new API po_negotiations_sv2.handle_sourcing_attachments would
    take care of the following.
        2.Copy all the attachments from the negotiation line/header
    as supplier type attachment to this PO line. For a blanket,
    this would suppress all the attachments copied to negotiation
    from requisition and copy only the newly created supplier type
    attachment(on the negotiation) to the blanket line.
  3.All the attachments from the Bid line/Header would be copied to this
    PO line/Blanketline as internal to PO type of attachments.
        4.Bid attributes would be converted dynamically to a supplier type of
    attachment and attached to this PO line/Blanket line.
        5.Notes from negotiation header/line and bid header/line
    would be copied to po/blanket line as supplier type attachment.
        6.Notes from bid header/line
    would be copied to po/blanket line as supplier type attachment.
*/

    if g_interface_source_code not in ('SOURCING','CONSUMPTION_ADVICE') then   -- CONSIGNED FPI
      l_progress := '670';
   fnd_attached_documents2_pkg.
       copy_attachments('REQ_LINES',
      interface.requisition_line_id,
      '',
      '',
      '',
      '',
      'PO_LINES',
      x_po_line_id,
      '',
      '',
      '',
      '',
      interface.created_by,
      interface.last_update_login,
      '',
      '',
      '');

   l_progress:='680';

   -- Copy of the requisition header attachements to the purchase
   -- order line.
   SELECT requisition_header_id
   INTO   x_requisition_header_id
   FROM   po_requisition_lines_all  --<Shared Proc FPJ>
   WHERE  requisition_line_id = interface.requisition_line_id;

   l_progress:='690';

   fnd_attached_documents2_pkg.
      copy_attachments('REQ_HEADERS',
      x_requisition_header_id,
      '',
      '',
      '',
      '',
      'PO_LINES',
      x_po_line_id,
      '',
      '',
      '',
      '',
      interface.created_by,
      interface.last_update_login,
      '',
      '',
      '');

    end if;
    end if; /*end of changes : smathur*/

    l_progress := '700';
    --<SOURCING TO PO FPH START>
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-3 starts');
    END IF;

    --copy attachments/notes from negotiation/bid to po/blanket line
    if g_interface_source_code = 'SOURCING' then
       if interface.document_subtype = 'STANDARD' then
          if interface.requisition_line_id is not null then
             x_column1:='NEGREQ';
             l_progress:='710';
         SELECT requisition_header_id
           INTO x_requisition_header_id
               FROM po_requisition_lines_all  --<Shared Proc FPJ>
              WHERE requisition_line_id =interface.requisition_line_id;
          else
             x_column1:='NEG';
          end if;
       elsif interface.document_subtype = 'BLANKET' then
          x_column1:='NEG';
       end if;
       if interface.document_subtype in ('BLANKET','STANDARD') then
          l_progress:='720';

          po_negotiations_sv2.handle_sourcing_attachments(
      interface.auction_header_id,
      interface.auction_line_number,
      interface.bid_number,
      interface.bid_line_number,
      x_requisition_header_id,
      interface.requisition_line_id,
      x_po_line_id,
      x_column1,
      x_attch_suppress_flag,
      interface.created_by,
      interface.last_update_login);

       end if;
    end if;

    l_progress := '730';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-3 Ends');
    END IF;
    --<SOURCING TO PO FPH END>

   -- Bug 2875346 start.
   -- If autocreating a SPO or PPO, and the requisition line has a one-time
   -- location, move the attachment from the PO line to the PO shipment
   IF (g_document_subtype IN ('STANDARD', 'PLANNED')) AND
      (has_one_time_location(interface.requisition_line_id))
   THEN
        -- Bug 2894378. Use BEGIN-EXCEPTION-END for exception handling to
        -- support original FPH behavior.
        BEGIN

            l_progress := '740';

            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'Before selecting one-time attachment');
            END IF;

            --SQL What: Locate the one-time location attachment currently under
            --          the PO_LINES entity by it's unique iP identifier prefix
            --SQL Why: Need the attached_document_id to move the attachment

            SELECT fad.attached_document_id
            INTO   l_one_time_att_doc_id
            FROM   fnd_attached_documents fad,
                   fnd_documents_tl fdt
            WHERE  fad.entity_name = 'PO_LINES'
            AND    fad.pk1_value = to_char(x_po_line_id)
            AND    fad.document_id = fdt.document_id
            AND    fdt.language = USERENV('LANG')
            AND    fdt.description like 'POR:%';  -- iP unique identifier

            l_progress := '750';

            -- Move the attachment from the PO line to the PO shipment
            UPDATE fnd_attached_documents
            SET    entity_name = 'PO_SHIPMENTS',
                   pk1_value = to_char(x_line_location_id),
                   pk2_value = 'ONE_TIME_LOCATION'
            WHERE  attached_document_id = l_one_time_att_doc_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- If cannot locate one-time loc attchmnt, do nothing. This
                -- supports original FPH behavior.
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'One-time loc attachment missing iP prefix, so do not try to move');
                END IF;
        END;
   END IF;
   -- Bug 2875346 end.

   -- <Complex Work R12 Start> : Copy attachments to payitems
   IF (p_is_complex_work_po) THEN

     FOR i IN 1..l_line_loc_id_tbl.COUNT
     LOOP

       IF (l_line_loc_id_tbl(i) <> x_line_location_id) THEN
         -- Bug 5411781: Check if the one time location exists
         -- only then need to copy the one time attachments.
           -- copy one-time location from first actual shipment to
           -- each payitem.
       IF (l_one_time_att_doc_id IS NOT NULL) THEN
            fnd_attached_documents2_pkg.copy_attachments(
             X_from_entity_name  => 'PO_SHIPMENTS'
           , X_from_pk1_value    => x_line_location_id
           , X_from_pk2_value    => 'ONE_TIME_LOCATION'
           , X_to_entity_name    => 'PO_SHIPMENTS'
           , X_to_pk1_value      => l_line_loc_id_tbl(i)
           , X_to_pk2_value      => 'ONE_TIME_LOCATION'
           , X_created_by        => interface.created_by
           , X_last_update_login => interface.last_update_login
           );

        END IF;
      END IF;  -- if l_line_loc_id_tbl(i) <> x_line_location_id

       -- Bug 4620207: pass more parameters
       PO_NEGOTIATIONS_SV2.copy_sourcing_payitem_atts(
         p_line_location_id    => l_line_loc_id_tbl(i)
       , p_created_by          => interface.created_by
       , p_last_update_login   => interface.last_update_login
       , p_auction_header_id   => interface.auction_header_id
       , p_auction_line_number => interface.auction_line_number
       , p_bid_number          => interface.bid_number
       , p_bid_line_number     => interface.bid_line_number
       );

     END LOOP;

   END IF;  -- is Complex Work PO

   -- <Complex Work R12 End>

   l_progress:='760';

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_line: Before update of po_requisition_lines');
    END IF;

   IF (g_document_type = 'PO') THEN
   l_progress:='770';
      UPDATE po_requisition_lines_all  --<Shared Proc FPJ>
         SET line_location_id  = x_line_location_id,
       --<CONSUME REQ DEMAND PFI START>
       reqs_in_pool_flag = NULL, --<REQINPOOL - changed value from N to NULL>
       --<CONSUME REQ DEMAND PFI END>
             last_update_date  = interface.last_update_date,
             last_updated_by   = interface.last_updated_by,
             last_update_login = interface.last_update_login
       WHERE requisition_line_id = interface.requisition_line_id;
   ELSE
      l_progress := '780';
      UPDATE po_requisition_lines_all  --<Shared Proc FPJ>
         SET on_rfq_flag = 'Y',
             last_update_date  = interface.last_update_date,
             last_updated_by   = interface.last_updated_by,
             last_update_login = interface.last_update_login
       WHERE requisition_line_id = interface.requisition_line_id;
   END IF;

   l_progress:='790';
   g_number_records_processed := g_number_records_processed + 1;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'num records processed: '||g_number_records_processed);
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;

  --<Unified Catalog R12 START>
  l_progress:='800';
  -- For intergration with Sourcing, during blanket creation from Renegotiate flow,
  -- we need to import all attributes for each line.
  -- to facilitate bulk update, we are storing the newly created po_line on
  -- po_attr_values_interface and po_attr_values_interface_tlp
  IF (g_document_subtype = 'BLANKET'  AND g_interface_source_code = 'SOURCING') THEN
    l_progress:='810';

    IF g_debug_stmt THEN PO_DEBUG.debug_stmt(d_mod,l_progress,'Updating PO_LINE_IDs in attribute interface tables: '||l_po_line_id_tbl.COUNT);END IF;

    --SQL What: Update the PO_LINE_ID on PO_ATTR_VALUES_INTERFACE table
    --SQL Why : To facilitate bulk update of attributes, later in the flow
    --SQL Join: interface_header_id, interface_line_id
    FORALL i IN INDICES OF l_po_line_id_tbl
      UPDATE PO_ATTR_VALUES_INTERFACE
        SET po_line_id = l_po_line_id_tbl(i),
            req_template_name = to_char(g_ATTR_VALUES_NULL_ID),
            req_template_line_num = to_char(g_ATTR_VALUES_NULL_ID),
            inventory_item_id = nvl(inventory_item_id, g_ATTR_VALUES_NULL_ID)
      WHERE po_attr_values_interface.interface_header_id = l_interface_header_id_tbl(i)
        AND po_attr_values_interface.interface_line_id = l_interface_line_id_tbl(i);

    IF g_debug_stmt THEN PO_DEBUG.debug_stmt(d_mod,l_progress,'Number of PO_ATTR_VALUES_INTERFACE rows updated='||SQL%rowcount);END IF;

    l_progress:='820';
    --SQL What: Update the PO_LINE_ID on PO_ATTR_VALUES_TLP_INTERFACE table
    --SQL Why : To facilitate bulk update of attributes, later in the flow
    --SQL Join: interface_header_id, interface_line_id
    FORALL i IN INDICES OF l_po_line_id_tbl
      UPDATE PO_ATTR_VALUES_TLP_INTERFACE
        SET po_line_id = l_po_line_id_tbl(i),
            req_template_name = to_char(g_ATTR_VALUES_NULL_ID),
            req_template_line_num = to_char(g_ATTR_VALUES_NULL_ID),
            inventory_item_id = nvl(inventory_item_id, g_ATTR_VALUES_NULL_ID)
      WHERE po_attr_values_tlp_interface.interface_header_id = l_interface_header_id_tbl(i)
        AND po_attr_values_tlp_interface.interface_line_id = l_interface_line_id_tbl(i);

    IF g_debug_stmt THEN PO_DEBUG.debug_stmt(d_mod,l_progress,'Number of PO_ATTR_VALUES_TLP_INTERFACE rows updated='||SQL%rowcount);END IF;
  END IF;
  --<Unified Catalog R12 END>

  IF g_debug_stmt THEN PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name); END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF (X_match_blanket_line = 'N') THEN

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line: Inside No data found : Match blanket line is N');
        END IF;
        null;
     ELSE

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_line : Inside No data found : Match blanket line is not N');
        END IF;
        po_message_s.sql_error('CREATE_LINE', l_progress,sqlcode);
        wrapup(x_interface_header_id);
        raise;

     END IF;
  --handle update_req_pool_fail exception
  --<SOURCING TO PO FPH START>
  WHEN update_req_pool_fail then
       po_message_s.sql_error('CREATE_LINE',l_progress,sqlcode);
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_documents: update_req_pool_fail exception : SQLCODE '||sqlcode);
        END IF;
       raise;

  --<SOURCING TO PO FPH END>
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(x_interface_header_id);
     po_message_s.sql_error('CREATE_LINE',l_progress,sqlcode);
     raise;

END create_line;

/* ============================================================================
     NAME: CREATE_SHIPMENT
     DESC: Create/Add to document shipment
     ARGS: IN : x_po_line_id IN number
           IN : x_line_location_id IN number
     ALGR:

   ==========================================================================*/
PROCEDURE create_shipment(
  x_po_line_id IN number,
  p_rate_for_req_fields IN NUMBER, -- <ACHTML R12>
  x_line_location_id IN OUT NOCOPY number,
  p_outsourced_assembly IN NUMBER --<SHIKYU R12>
  )
IS
x_ship_to_location_id number:= 0;
x_po_release_id number := g_po_release_id;
x_cumulative_flag boolean; /* used to get release price from PA */
x_price number;              /* used to get release price from PA */
x_price_break_type varchar2(25) := '';
x_doctype varchar2(25) := ''; /* used for call to update close state */
x_return_code varchar2(25) := ''; /* used for call to update close state */
x_item_org_taxable_flag      mtl_system_items.taxable_flag%type := NULL;
x_ship_to_org_taxable_flag   mtl_system_items.taxable_flag%type := NULL;
x_return_taxable_flag        mtl_system_items.taxable_flag%type := NULL;

/* For converting qty if line_type is not quantity based */
x_order_type_lookup_code  varchar2(25)  :='';
x_quantity      number    :=0;
l_conversion_rate number :=1;
--fix 8976669
--declared x_amount
x_amount number;
/* obtain currency info to adjust precision */
x_precision   number :='';
x_ext_precision   number :='';
x_min_unit    number :='';

/* Additional tax variables for R11 tax defaulting functionality */
x_tax_code_id                   ap_tax_codes.tax_id%type;
x_tax_type                      ap_tax_codes.tax_type%type;
x_description                   ap_tax_codes.description%type;
x_allow_tax_code_override_flag  gl_tax_option_accounts.allow_tax_code_override_flag%type;

/* Parameters for supporting OE callback for maintaining so_drop_ship_source */
x_p_api_version     number:='';
x_p_return_status   varchar2(1):='';
x_p_msg_count     number:='';
x_p_msg_data      varchar2(2000):='';
x_p_req_header_id   NUMBER:='';
x_p_req_line_id     NUMBER:='';
--x_p_interface_source_code   varchar2(25);
--x_p_interface_source_line_id  number:='';
x_p_po_header_id    number:='';
x_p_po_line_id      number:='';
x_p_line_location_id    number:='';
x_requisition_header_id   number:='';
x_p_po_release_id   number:='';

/*630638 - SVAIDYAN: Variable to get the qty in the already existing shipment */
x_ship_qty number := 0;
--FRKHAN 12/21/98
x_tax_user_override_flag  VARCHAR2(1);
--FRKHAN 1/12/99
x_country_of_origin_code  VARCHAR2(2);
x_tax_status            VARCHAR2(10);
x_tax_status_indicator          po_requisition_lines.tax_status_indicator%type;
--FRKHAN 12/2/99 BUG 1084816
l_encode VARCHAR2(2000);
x_po_uom  varchar2(25):=null;
x_temp_uom  varchar2(25):=null;
x_temp_item_id  number:=null;
x_closed_reason po_line_locations.closed_reason%TYPE;
x_uom_convert          varchar2(2) := fnd_profile.value('PO_REQ_BPA_UOM_CONVERT');

--<Bug# 3293109 START>
l_promised_date         DATE            := INTERFACE.PROMISED_DATE;
l_po_promised_def_prf   VARCHAR2(1)     := fnd_profile.value('PO_NEED_BY_PROMISE_DEFAULTING');
--<Bug# 3293109 END>

l_api_name CONSTANT VARCHAR2(30) := 'create_shipment';
l_progress VARCHAR2(3) := '000';                    --< Bug 3210331 >
l_manual_price_change_flag po_line_locations_all.manual_price_change_flag%TYPE := NULL; --bug 3495772

-- Bug 5208159
l_from_type_lookup_code po_headers_all.type_lookup_code%TYPE;

--<INVCONV R12 START>
x_shipment_uom      MTL_UNITS_OF_MEASURE.UNIT_OF_MEASURE%TYPE;
x_secondary_unit_of_measure MTL_UNITS_OF_MEASURE.UNIT_OF_MEASURE%TYPE;
x_secondary_quantity    PO_LINES.SECONDARY_QUANTITY%TYPE;
x_secondary_uom_code    MTL_UNITS_OF_MEASURE.UOM_CODE%TYPE;
--<INVCONV R12 END>

l_matching_basis    PO_LINE_TYPES.matching_basis%TYPE;  -- <Complex Work R12>
l_inspection_required_flag VARCHAR2(1);     --10403047
l_receipt_required_flag VARCHAR2(1);       --10403047

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

   x_line_location_id:=null;
   x_quantity := interface.quantity;

   x_temp_uom     := interface.unit_meas_lookup_code;
   x_temp_item_id := interface.item_id;

    l_progress := '010';

    -- <SERVICES FPJ START>
    -- <Complex Work R12>: Also get matching basis

    SELECT plt.order_type_lookup_code, plt.matching_basis
    INTO   x_order_type_lookup_code, l_matching_basis
    FROM   po_line_types plt
    WHERE  plt.line_type_id = interface.line_type_id;

    --
    -- <SERVICES FPJ END>

     IF interface.h_currency_code IS NOT NULL THEN
                fnd_currency.get_info(interface.h_currency_code,
                             x_precision,
                             x_ext_precision,
                             x_min_unit );
     END IF;

    -- bug 5208159 : Conversion of req UOM to Quotation UOM should always happen if the
    -- source document is a quote and profile 'PO: Convert Requisition UOM to Source Document UOM'
    -- should be ignored in that case
    IF g_debug_stmt THEN
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress,
                             p_message  => 'from line id :'||interface.from_line_id||'from header id:'||interface.from_header_id);
    END IF;

    IF (interface.from_line_id IS NOT NULL) AND (g_document_subtype = 'STANDARD') THEN

         l_progress := '015';

         BEGIN

           SELECT poh.type_lookup_code
           INTO   l_from_type_lookup_code
           FROM   po_headers_all poh
           WHERE poh.po_header_id=interface.from_header_id ;

           IF g_debug_stmt THEN
               PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                   p_token    => l_progress,
                                   p_message  => 'l_from_type_lookup_code :'||l_from_type_lookup_code);
           END IF;



         EXCEPTION
           WHEN OTHERS THEN
               IF g_debug_unexp THEN
                   PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                      p_progress => l_progress);
               END IF;
               po_message_s.sql_error('CREATE_LINE',l_progress,sqlcode);
               wrapup(interface.interface_header_id);
               raise;
           END;
    END IF;

    -- got the source document type, now compare it and if required do the UOM conversion

    IF g_debug_stmt THEN
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress,
                             p_message  => 'x_uom_convert:'||x_uom_convert);
    END IF;

  IF (nvl(x_uom_convert,'N') = 'Y' OR l_from_type_lookup_code = 'QUOTATION') THEN
  -- bug 5208159 : end

   IF (g_document_subtype='RELEASE')
     -- Bug 2735840 Convert UOM when autocreating a PO that references a GA
     OR ((g_document_subtype='STANDARD')
         AND (interface.from_line_id is not null)) THEN

   /* Enh : 1660036
    get the uom from the PO . This will be used for uom conversion */

    BEGIN
      IF (g_document_subtype='RELEASE') THEN -- Bug 2735840
        l_progress := '020';
        select unit_meas_lookup_code
        into x_po_uom
        from po_lines_all pol ,  --<Shared Proc FPJ>
             po_headers_all poh  --<Shared Proc FPJ>
        where pol.po_header_id = poh.po_header_id
        and pol.po_header_id = interface.po_header_id
        and pol.line_num = interface.line_num;
      -- Bug 2735840 START
      ELSE -- Autocreating a PO that references a GA
        l_progress := '030';
        SELECT unit_meas_lookup_code
        INTO x_po_uom
        FROM po_lines_all
        WHERE po_line_id = interface.from_line_id;
      END IF; -- g_document_subtype
      -- Bug 2735840 END
     EXCEPTION
     WHEN OTHERS THEN
       IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
           PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                              p_progress => l_progress);
       END IF;
       po_message_s.sql_error('CREATE_SHIPMENTS',l_progress,sqlcode);
       wrapup(interface.interface_header_id);
       raise;
    END;

  /* before inserting the quantity into the shipments table convert the quantity
      into the BPA uom if the uom's on the req and BPA are different .
      This conversion is done only if the Convert UOM  profile option is set to Yes. */

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_shipment: UOM: '||x_temp_uom);
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_shipment: item id: '||x_temp_item_id);
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_shipment: PO UOM: '||x_po_uom);
    END IF;

    l_progress := '040';

        IF  (   ( interface.unit_meas_lookup_code <> x_po_uom )
            AND ( x_order_type_lookup_code IN ('QUANTITY','AMOUNT') ) ) THEN   -- <SERVICES FPJ>


            -- Bug 3793360 : use the po_uom_convert procedure and round 15
            l_conversion_rate :=  po_uom_s.po_uom_convert(interface.unit_meas_lookup_code,
                                                       x_po_uom,
                                                       interface.item_id);

            x_quantity := round(x_quantity * l_conversion_rate , 15);
            x_shipment_uom := x_po_uom ; --<INVCONV R12>

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_shipment: Converted Qty: '||x_quantity);
        END IF;

        END IF;

    END IF;
  END IF;

    l_progress := '050';
   /*
   ** Get the ship to location id associated with the
   ** deliver to location.  This may then used to
   ** get the tax name, if the tax system parameters are
   ** set up to retrieve the tax code based on ship-to location.
   */

   x_ship_to_location_id := get_ship_to_loc(interface.deliver_to_location_id);  -- FPI

  IF(g_document_subtype='STANDARD' or g_document_subtype='PLANNED' or
  g_document_type = 'RFQ')THEN
    l_progress := '060';
    BEGIN
      SELECT poll.line_location_id,poll.secondary_unit_of_measure --<INVCONV R12>
        INTO x_line_location_id,x_secondary_unit_of_measure
        FROM po_line_locations_all poll,  --<Shared Proc FPJ>
             po_lines_all pol  --<Shared Proc FPJ>
       WHERE poll.po_header_id = interface.po_header_id
         AND poll.po_line_id = pol.po_line_id
         AND poll.shipment_num = interface.shipment_num
         AND pol.line_num = interface.line_num
         AND poll.shipment_type in ('STANDARD','PLANNED', 'RFQ');
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'NO_DATA_FOUND: '||SQLERRM);
        END IF;
     WHEN OTHERS THEN
       IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
           PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                              p_progress => l_progress);
       END IF;
       po_message_s.sql_error('CREATE_SHIPMENTS',l_progress,sqlcode);
       wrapup(interface.interface_header_id);
       raise;
    END;


  ELSIF(g_document_subtype='RELEASE')THEN
    l_progress := '070';
    BEGIN
      SELECT poll.line_location_id,
             poll.manual_price_change_flag, --bug 3495772
             poll.secondary_unit_of_measure --<INVCONV R12>
        INTO x_line_location_id,
             l_manual_price_change_flag, --bug 3495772
             x_secondary_unit_of_measure
        FROM po_line_locations_all poll,  --<Shared Proc FPJ>
             po_lines_all pol,  --<Shared Proc FPJ>
             po_releases_all por  --<Shared Proc FPJ>
       WHERE poll.po_header_id = interface.po_header_id
         AND poll.po_line_id = pol.po_line_id
         AND poll.shipment_num = interface.shipment_num
         AND pol.line_num = interface.line_num
         AND poll.po_release_id=por.po_release_id
         AND por.po_release_id=x_po_release_id;


    EXCEPTION
     WHEN NO_DATA_FOUND THEN
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'NO_DATA_FOUND: '||SQLERRM);
        END IF;
     WHEN OTHERS THEN
       IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
           PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                              p_progress => l_progress);
       END IF;
       po_message_s.sql_error('CREATE_SHIPMENTS',l_progress,sqlcode);
       wrapup(interface.interface_header_id);
       raise;
    END;
  END IF;

  l_progress:='080';

  IF(interface.document_subtype = 'RELEASE')  AND
    (g_interface_source_code  <> 'CONSUMPTION_ADVICE') THEN  -- Bug 2748933

     IF(nvl(l_manual_price_change_flag, 'N') <> 'Y') THEN -- bug 3495772

         -- Find out if the line is using cumulative or non-cumlative pricing
         SELECT decode(price_break_lookup_code, 'CUMULATIVE', 'Y', 'N')
         INTO   x_price_break_type
         FROM   po_lines_all  --<Shared Proc FPJ>
         WHERE  po_line_id = x_po_line_id;

         IF (x_price_break_type = 'Y') THEN
             x_cumulative_flag := TRUE;
         ELSE
             x_cumulative_flag := FALSE;
         END IF;

    /* 630638 - SVAIDYAN
       If the price break type is not cumulative, then
       If there exists a shipment to which this qty will be added, then the
       qty to get break price would be already existing shipment quantity +
       interface.quantity.

    */

        l_progress := '090';
        if (x_line_location_id is not null and x_cumulative_flag = FALSE) then
        begin
            select nvl(quantity, 0)
            into   x_ship_qty
            from   po_line_locations_all  --<Shared Proc FPJ>
            where  line_location_id = x_line_location_id;
        exception
            when others THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                END IF;
                x_ship_qty := 0;
        end;
        end if;

        l_progress := '100';
         x_ship_qty := x_ship_qty + x_quantity;


         /* <TIMEPHASED FPI> */
         /* Changed the parameter sysdate to interface.need_by_date */
         x_price := po_sourcing2_sv.get_break_price(
          x_ship_qty,
          interface.destination_organization_id,
                      x_ship_to_location_id,
          x_po_line_id,
                      x_cumulative_flag,
                            interface.need_by_date,
		 p_req_line_price => INTERFACE.unit_price);
/* 11689969 */ /* <TIMEPHASED FPI> */

      ELSE --manual_price_change_flag = y, bug 3495772
           x_price := NULL; --will preserve whatever price is alredy on shipment
                            -- in below update statement
      END IF;

  ELSE
     /* Bug 486563 ecso 5/13/97
      * When mulitple lines with different unit_price are combined, we need
      * to ensure that price_override field in shipments are populated with
      * the unit_price from the line, not the original one from the req.
      */
   /* Bug 2748933 */
   /* For a consumption advice we take the price as it is populated and not from the BPA */


      IF (g_interface_source_code  =  'CONSUMPTION_ADVICE') THEN
            x_price := interface.unit_price;

      ELSE

       l_progress := '110';
       begin
         SELECT unit_price
         INTO   x_price
         FROM   po_lines_all  --<Shared Proc FPJ>
         WHERE  po_line_id=x_po_line_id;
       exception
           when others then
              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                  PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                      p_token    => l_progress,
                                      p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
              END IF;
              x_price := null;
       end;

      END IF;

  END IF;

  IF(x_line_location_id is not null) THEN

     /*
     ** Update everything except closed_code
     */
     l_progress:='120';
      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'Create_shipment: shipment exist');
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'Create_shipment: Update PO line locations');
      END IF;

      /*Bug 5629398 Start: Quantity conversion for foreign currency was not happening for
        amount based lines when we try to add to existing shipment line */
        IF   ( x_order_type_lookup_code = 'QUANTITY' ) THEN
                  x_quantity := round(x_quantity,15);
        ELSIF ( x_order_type_lookup_code = 'AMOUNT' ) THEN
             -- Bug 7661419, No conversion for same currency.
	     XX_PO_INTERFACE_PKG.do_currency_conversion(
                      p_order_type_lookup_code => 'AMOUNT',
                      p_interface_source_code  => g_interface_source_code,
                      p_rate                   => p_rate_for_req_fields, -- <ACHTML R12>
                      p_po_currency_code       => interface.h_currency_code,
                      p_requisition_line_id    => interface.requisition_line_id,
                      x_quantity               => x_quantity, -- IN/OUT
                      x_unit_price             => interface.unit_price, -- IN/OUT
                      x_base_unit_price        => interface.base_unit_price, -- IN/OUT
                      x_amount                 => interface.amount -- IN/OUT
                      );
--fix 8976669
--The procedure do_currency_conversion was not called for 'FIXED PRICE', added the required call
	ELSIF ( x_order_type_lookup_code = 'FIXED PRICE') THEN
	     XX_PO_INTERFACE_PKG.do_currency_conversion(
                      p_order_type_lookup_code => 'FIXED PRICE',
                      p_interface_source_code  => g_interface_source_code,
                      p_rate                   => p_rate_for_req_fields, -- <ACHTML R12>
                      p_po_currency_code       => interface.h_currency_code,
                      p_requisition_line_id    => interface.requisition_line_id,
                      x_quantity               => x_quantity, -- IN/OUT
                      x_unit_price             => interface.unit_price, -- IN/OUT
                      x_base_unit_price        => interface.base_unit_price, -- IN/OUT
                      x_amount                 => x_amount -- IN/OUT
                      );

	END IF;
    /*Bug 5629398 End */


      --<INVCONV R12 START>
      --If item is dual uom control and secondary quantity is NULL, derive it
     IF x_secondary_unit_of_measure IS NOT NULL THEN
        IF interface.secondary_quantity IS  NULL THEN
           PO_UOM_S.uom_convert (x_quantity,
                                 nvl(x_shipment_uom, interface.unit_meas_lookup_code),
                                 interface.item_id, x_secondary_unit_of_measure ,
                                 x_secondary_quantity) ;
        ELSE
           X_secondary_quantity := interface.secondary_quantity ;
        END IF;
     ELSE
        x_secondary_quantity  := null ;
     END IF;
     --<INVCONV R12 END>

     --<INVCONV R12> replace interface.secondary_quantity with x_secondary_quantity

     UPDATE po_line_locations_all  --<Shared Proc FPJ>
  SET quantity          = quantity + x_quantity,
-- start of 1548597
            secondary_quantity = secondary_quantity + x_secondary_quantity,
-- end of 1548597
--fix 8976669
--added update of amount when shipments are created
 	    amount = nvl(amount,0) + x_amount,
            approved_flag     = DECODE(approved_flag,
                                         'N','N', 'R'),
            last_update_date  = interface.last_update_date,
            last_update_login = interface.last_update_login,
            last_updated_by   = interface.last_updated_by,
            price_override    = decode(g_document_type, 'RFQ',
          price_override, DECODE(
          nvl(x_price, -1),
                                       -1, price_override,
-- Bug 1353736 use precision in rounding
-- Bug 3472140: Changed precisions to 15
                                       ROUND(x_price, nvl(x_ext_precision,15)))),
            -- Bug 5067321. Setting tax_attribute_update_code to update for
            -- add_to cases.
            tax_attribute_update_code = NVL(tax_attribute_update_code,
                                            NVL2(g_calculate_tax_flag, 'UPDATE', null))
      WHERE line_location_id = x_line_location_id;

      /*
      ** 9/10/97 ecso
      ** OE Callback function for maintaining so_drop_ship_sources table
      */
      /* 11/18/97 ecso
      ** OE redesign. No Shipments linked to sales order will be combined
      ** Therefore, no need to do call back for update shipment
      ** Removed oe callback.
      */

      /*
      ** Prepare to call pocupdate_close: - call auto close.
      */
      IF (g_document_type = 'PO') THEN
       IF (g_mode = 'ADD') THEN
        IF (g_document_type = 'PO') THEN
         IF (g_document_subtype = 'RELEASE') THEN
            x_doctype := 'RELEASE';
              /* Bug 4016505 Start */
              IF NOT po_actions.close_po(x_po_release_id,
                    x_doctype,
                    g_document_subtype,
                    x_po_line_id,
                    x_line_location_id,
                    'CLOSE',
                    '',
                    'PO',
                    'N',
                    x_return_code,
                    'Y') then

                  po_message_s.sql_error('CLOSE_PO',l_progress,sqlcode);

               END IF;
              /* Bug 4016505 End */
         ELSE
            x_doctype := 'PO';
                          /* Bug 4016505 Start */
            IF NOT po_actions.close_po(interface.po_header_id,
                    x_doctype,
                    g_document_subtype,
                    x_po_line_id,
                    x_line_location_id,
                    'CLOSE',
                    '',
                    'PO',
                    'N',
                    x_return_code,
                    'Y') then

               po_message_s.sql_error('CLOSE_PO',l_progress,sqlcode);

            END IF;
            /* Bug 4016505 End */
         END IF;

         l_progress := '130';
         IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
             PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                 p_token    => l_progress,
                                 p_message  => 'Create shipment: Before calling Auto close');
         END IF;
        /*bug 12715744 starts: the call to po_actions.po_close is a redundant call.
	In the above if conditions it is called with the right parameters.
	This call raises an exception or closes lines from other releases depending on the ID
	that is passed
	hence commenting it.*/
        /* IF NOT po_actions.close_po(interface.po_header_id,
                    x_doctype,
                    g_document_subtype,
                    x_po_line_id,
                    x_line_location_id,
                    'CLOSE',
                    '',
                    'PO',
                    'N',
                    x_return_code,
                    'Y') then

            po_message_s.sql_error('CLOSE_PO',l_progress,sqlcode);

         END IF; bug 12715744 : ends*/

       END IF;

      END IF;

     END IF;

  ELSIF(x_line_location_id is null) THEN

      l_progress := '140';
      IF (g_document_type = 'PO') THEN
         /*
         ** Prepare to call pocupdate_close: -  call manual close
         ** for the line level.
         */
        IF (g_mode = 'ADD') THEN
           IF (g_document_subtype = 'RELEASE') THEN
              x_doctype := 'RELEASE';
              /* Bug 4016505 Start */
                IF not po_actions.close_po(x_po_release_id,
                    x_doctype,
                    g_document_subtype,
                    x_po_line_id,
                    x_line_location_id,
                    'CLOSE',
                    '',
                    'PO',
                    'N',
                    x_return_code,
                    'N') then

                   po_message_s.sql_error('CLOSE_PO',l_progress,sqlcode);
                END IF;
              /* Bug 4016505 End */
           ELSE
              x_doctype := 'PO';
              /* Bug 4016505 Start */
              IF not po_actions.close_po(interface.po_header_id,
                    x_doctype,
                    g_document_subtype,
                    x_po_line_id,
                    x_line_location_id,
                    'CLOSE',
                    '',
                    'PO',
                    'N',
                    x_return_code,
                    'N') then
               po_message_s.sql_error('CLOSE_PO',l_progress,sqlcode);
             END IF;
              /* Bug 4016505 End */
           END IF;

           l_progress := '150';
	/*bug 12715744 starts: the call to po_actions.po_close is a redundant call.
	In the above if conditions it is called with the right parameters.
	This call raises an exception or closes lines from other releses depending on the ID
	that is passed
	hence commenting it.*/
         /*IF not po_actions.close_po(interface.po_header_id,
                    x_doctype,
                    g_document_subtype,
                    x_po_line_id,
                    x_line_location_id,
                    'CLOSE',
                    '',
                    'PO',
                    'N',
                    x_return_code,
                    'N') then

              po_message_s.sql_error('CLOSE_PO',l_progress,sqlcode);

           END IF;bug 12715744 : ends*/

        END IF;

     END IF;

     l_progress:='160';
     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress,
                             p_message  => 'create shipment: Shipment does not exist');
     END IF;

     l_progress := '200';

     /* Bug 482648
      * Adjust quantity for foreign currecny
      */

        IF ( x_order_type_lookup_code = 'QUANTITY' ) THEN     -- <SERVICES FPJ>

-- added by jbalakri for bug 2372004
-- Bug 3472140: Changed precisions to 15
            x_quantity := round(x_quantity,15);

        ELSIF ( x_order_type_lookup_code = 'AMOUNT' ) THEN    -- <SERVICES FPJ>
             -- Bug 7661419, No conversion for same currency.
             XX_PO_INTERFACE_PKG.do_currency_conversion(
                      p_order_type_lookup_code => 'AMOUNT',
                      p_interface_source_code  => g_interface_source_code,
                      p_rate                   => p_rate_for_req_fields, -- <ACHTML R12>
                      p_po_currency_code       => interface.h_currency_code,
                      p_requisition_line_id    => interface.requisition_line_id,
                      x_quantity               => x_quantity, -- IN/OUT
                      x_unit_price             => interface.unit_price, -- IN/OUT
                      x_base_unit_price        => interface.base_unit_price, -- IN/OUT
                      x_amount                 => interface.amount -- IN/OUT
                      );
        END IF;

     /*
      **  Create a new shipment.
      */
     l_progress:='210';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create shipment: Create a new shipment');
    END IF;

     SELECT po_line_locations_s.nextval
       INTO x_line_location_id
       FROM sys.dual;

     -- bug: 404191
     --      Get the taxable_flag based on the following priority
     --      1. preferences (global.po_taxable_flag)
     --      2. ship_to_org (x_ship_to_org_taxable_flag)
     --      2. item-org    (po_lines.taxable_flag)
     --      3. PO default  (po_startup_values.taxable_flag)
     --
     l_progress:='220';
     x_item_org_taxable_flag :=  item.taxable_flag;


     -- Bug 3935370 START
     -- Removed the po_items_sv3.get_taxable_flag procedure because
     -- x_return_taxable_flag should be based off of tax_code_id instead.
     -- Also removed fix for bug 1651019 because it sets x_return_taxable_flag
     -- to Y if x_tax_code_id is not null, which is duplicated in this fix.
     -- Added else clause in if statment to make sure x_return_taxable_flag is
     -- set appropriately according to tax_code_id.
     -- Bug 3935370 END

     --< Bug 3334670 Start >
     IF (g_interface_source_code = 'CONSUMPTION_ADVICE') THEN

         -- tax_code_id from the interface table is used for consumption advice
         IF (NVL(interface.tax_code_id, -1) = -1) THEN
             -- FPI inventory code was populating tax_code_id = -1 in some cases
             -- for consumption advice. Never insert -1.
             interface.tax_code_id := NULL;
             x_return_taxable_flag := 'N';
         ELSE
             x_return_taxable_flag := 'Y';
         END IF;
     --< Bug 3334670 End >
     -- Bug 3935370 START
     ELSE
       IF (x_tax_code_id is not null) then
         x_return_taxable_flag := 'Y';
       ELSE
         x_return_taxable_flag := 'N';
       END IF;
     -- Bug 3935370 END
     END IF;

     l_progress:='230';

--FRKHAN 1/12/99 Get default country of origin
     po_coo_s.get_default_country_of_origin(
      interface.item_id,
      interface.destination_organization_id,
      interface.vendor_id,
      interface.vendor_site_id,
      x_country_of_origin_code);

/*Bug no 781929
  Last accept date is also inserted into po_line_locations table.
  last_accept_date = interface.need_by_date+rc.days_late_receipt_allowed.
  Purposely , null handling has not been done, since even if either
  need_by_date or days_late_received_allowed is null then the last_accept_date
  should be null.
*/

-- Bug 1353736 Call fnd_currency.get_info to get the precision
--added by jbalakri for 1805397
        IF interface.h_currency_code IS NOT NULL THEN
                   fnd_currency.get_info(interface.h_currency_code,
                                         x_precision,
                                         x_ext_precision,
                                         x_min_unit );
        end if;
--end of add for 1805397

        l_progress := '240';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create shipment: Before insert into po line locations');
        END IF;

     /* CONSIGNED FPI start : Set the closed reason for consigned */
        IF interface.consigned_flag = 'Y' THEN
           x_closed_reason := fnd_message.get_string('PO', 'PO_SUP_CONS_CLOSED_REASON');
        ELSE
           x_closed_reason := null;
        END IF;


     /* CONSIGNED FPI End */

     --<Bug# 3293109 START>
     if g_document_type <> 'RFQ'
         and l_promised_date is null
         and nvl(l_po_promised_def_prf, 'N') = 'Y' then

                l_promised_date := INTERFACE.NEED_BY_DATE;
     end if;
     --<Bug# 3293109 END>

     -- GA FPI Bug 2750604. Need to insert from_header_id and from_line_id
     -- at the shipment level from the interface tables.

     --Bug 2861408:  For consigned items ALWAYS insert 'N' for
     --receipt-required flag and inspection-required flag, and
     --insert 'P' for match_option.


    l_progress := '250';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'interface.trxn_flow_header_id='||interface.transaction_flow_header_id);
    END IF;

    --<INVCONV R12 START>
    -- If item is dual uom control and secondary quantity is NULL, derive it
    IF interface.item_id IS NOT NULL THEN
      IF interface.secondary_quantity IS NULL THEN
          PO_UOM_S.get_secondary_uom( interface.item_id,
                                         interface.destination_organization_id,
                                         x_secondary_uom_code,
                                         x_secondary_unit_of_measure);

         IF x_secondary_unit_of_measure IS NOT NULL and x_quantity > 0 THEN
           PO_UOM_S.uom_convert (x_quantity,
                                 nvl(x_shipment_uom, interface.unit_meas_lookup_code),
                                 interface.item_id,
                                 x_secondary_unit_of_measure ,
                                 x_secondary_quantity) ;
         ELSE
           X_secondary_quantity := NULL;
         END IF;
      ELSE
           X_secondary_quantity := interface.secondary_quantity;
           X_secondary_unit_of_measure := interface.secondary_unit_of_measure;
      END IF;
    ELSE
       X_secondary_quantity := null;
       X_secondary_unit_of_measure := null;
    END IF;
    --<INVCONV R12 END>

    --Bug 10403047
    begin

    select decode(g_interface_source_code,
              'CONSUMPTION_ADVICE',
              'N', -- CONSIGNED FPI
               decode(interface.consigned_flag,
                     'Y',
                     'N', --bug 2861408
                     decode(interface.drop_ship_flag,
                            'Y',
                            'N', --bug 3330748
                            decode(x_order_type_lookup_code,
                                   'FIXED PRICE',
                                   'N',
                                   'RATE',
                                   'N', --bug 3483786
                                   decode(g_document_type,
                                          'RFQ',
                                          nvl(item.inspection_required_flag,
                                              nvl(params.inspection_required_flag,
                                                  'N')),
                                          nvl(item.inspection_required_flag,
                                              nvl(vendor.inspection_required_flag,
                                                  nvl(params.inspection_required_flag,
                                                      'N')))))))),
       decode(g_interface_source_code,
              'CONSUMPTION_ADVICE',
              'N', -- CONSIGNED FPI
              decode(interface.consigned_flag,
                     'Y',
                     'N', --bug 2861408
                     decode(g_document_type,
                            'RFQ',
                            nvl(item.receipt_required_flag,
                                nvl(interface.receipt_required_flag,
                                    nvl(params.receiving_flag, 'N'))),
                            nvl(item.receipt_required_flag,
                                nvl(interface.receipt_required_flag,
                                    nvl(vendor.receipt_required_flag,
                                        nvl(params.receiving_flag, 'N')))))))
  INTO l_inspection_required_flag, l_receipt_required_flag
  FROM dual;

  EXCEPTION

  	when others THEN
  		   l_progress:='255';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Error while determing receipt required and inspection required flag for 4 way');
    END IF;
  	end;

IF l_inspection_required_flag = 'Y' AND l_receipt_required_flag = 'Y' then

  rc.receiving_routing_id := 2; --Inspection Required

end if;

    --End Bug 10403047

    --Bug11882785-Start

IF l_inspection_required_flag = 'Y' AND l_receipt_required_flag = 'N' then

  l_inspection_required_flag := 'N';

end if;

    --Bug11882785-End



     INSERT INTO po_line_locations_all  --<Shared Proc FPJ>
             (line_location_id,
              last_update_date,
              last_updated_by,
              po_header_id,
              creation_date,
              created_by,
              last_update_login,
              po_line_id,
              quantity,
              quantity_received,
              quantity_accepted,
              quantity_rejected,
              quantity_billed,
              quantity_cancelled,
              amount,                                         -- <SERVICES FPJ>
              amount_received,                                -- <SERVICES FPJ>
              amount_accepted,                                -- <SERVICES FPJ>
              amount_rejected,                                -- <SERVICES FPJ>
              amount_billed,                                  -- <SERVICES FPJ>
              amount_cancelled,                               -- <SERVICES FPJ>
              ship_to_location_id,
              need_by_date,
              promised_date,
              from_header_id,
              from_line_id,
              --togeorge 09/27/2000
        --added note to receiver column
        note_to_receiver,
              approved_flag,
              po_release_id,
              closed_code,
              closed_reason,
              price_override,
              encumbered_flag,
              shipment_type,
              shipment_num,
              inspection_required_flag,
              receipt_required_flag,
              days_early_receipt_allowed,
              days_late_receipt_allowed,
              enforce_ship_to_location_code,
              ship_to_organization_id,
              invoice_close_tolerance,
              receive_close_tolerance,
              accrue_on_receipt_flag,
              allow_substitute_receipts_flag,
              receiving_routing_id,
              qty_rcv_tolerance,
              qty_rcv_exception_code,
              receipt_days_exception_code,
        terms_id,
              ship_via_lookup_code,
        freight_terms_lookup_code,
        fob_lookup_code,
        unit_meas_lookup_code,
              last_accept_date, -- zxzhang, Mar 04
              match_option,   -- bgu, Dec. 7, 98
        country_of_origin_code, --frkhan 1/12/99
-- start of 1548597
              secondary_unit_of_measure,
              secondary_quantity,
              preferred_grade,
              secondary_quantity_received,
              secondary_quantity_accepted,
              secondary_quantity_rejected,
              secondary_quantity_cancelled,
-- end of 1548597
              vmi_flag,  -- VMI FPH
              drop_ship_flag,   --  <DropShip FPJ>
              consigned_flag,  -- CONSIGNED FPI
              transaction_flow_header_id, --<Shared Proc FPJ>
              org_id  --<Shared Proc FPJ>
              --<DBI Req Fulfillment 11.5.11 Start >
              , closed_for_receiving_date
              , closed_for_invoice_date
              --<DBI Req Fulfillment 11.5.11 End >
              -- <Complex Work R12 Start>
              , value_basis
              , matching_basis
              -- <Complex Work R12 End>
        , outsourced_assembly --<SHIKYU R12>
        ,tax_attribute_update_code --<eTax Integration R12>
        , attribute_category  --OD CUSTOMIZATION Added by Paul DSouza(V2.0)
              )
       VALUES (x_line_location_id,
               interface.last_update_date,
               interface.last_updated_by,
               interface.po_header_id,
               interface.creation_date,
               interface.created_by,
               interface.last_update_login,
               x_po_line_id,
               x_quantity, --interface.quantity,
               0,
               0,
               0,
               0,
               0,
               interface.amount,    -- amount                 -- <SERVICES FPJ>
               0,                   -- amount_received        -- <SERVICES FPJ>
               0,                   -- amount_accepted        -- <SERVICES FPJ>
               0,                   -- amount_rejected        -- <SERVICES FPJ>
               0,                   -- amount_billed          -- <SERVICES FPJ>
               0,                   -- amount_cancelled       -- <SERVICES FPJ>
               x_ship_to_location_id,
               interface.need_by_date,
               l_promised_date,     --<Bug# 3293109>
               /* Modified for Bug# 8446396 */
	       /* Bug 11802312- Retain the document reference for a consigned PO */
               interface.from_header_id,
               interface.from_line_id,
               --togeorge 09/27/2000
         --added note to receiver column
         interface.note_to_receiver,
               decode(g_document_type, 'RFQ', '', 'N'),
               decode(g_document_subtype,'RELEASE',x_po_release_id,''),
               decode(interface.consigned_flag, 'Y', 'CLOSED FOR INVOICE' ,                    -- CONSIGNED FPI
                  decode(g_interface_source_code,'CONSUMPTION_ADVICE', 'CLOSED FOR RECEIVING'  ,   -- CONSIGNED FPI
                  decode(g_document_type, 'RFQ', '', 'OPEN'))),
               x_closed_reason,                                                                  -- CONSIGNED FPI
 /* Bug: 2000367 When there is no currency conversion involved we should not
                 round at all because it gives rise to inconsistency.
                 So removing the ext precision and blind rounding to 5 also as
                 this is already done above in case when currency conversion is
                 involved.
*/
               nvl(x_price,interface.unit_price),
               decode(g_document_type, 'RFQ', '', 'N'),
               decode(g_document_type, 'RFQ', 'RFQ',
      Decode(interface.document_subtype,
                      'RELEASE','BLANKET',
                      interface.document_subtype)),
               interface.shipment_num,
 l_inspection_required_flag, -- 10403047
              l_receipt_required_flag, -- 10403047

      /*bug 9155693 START-->
            While autocreating RFQ from Req. receiving controls values were set to NULL
            which cause receiving controls values reamin NULL in PO, which was created
            by copying RFQ to Quotation to PO.
            Hence, setting receving control fields to defaulted values.

      decode(g_document_type, 'RFQ', '',
      rc.days_early_receipt_allowed),
               decode(g_document_type, 'RFQ', '',
      rc.days_late_receipt_allowed),
               decode(g_document_type, 'RFQ', '',
      rc.enforce_ship_to_location_code),
      */

                      rc.days_early_receipt_allowed,
                      rc.days_late_receipt_allowed,
                      rc.enforce_ship_to_location_code,
      -- bug 9155693 END

               interface.destination_organization_id, -- ship to org
               decode(interface.consigned_flag, 'Y', 100 , -- CONSIGNED FPI
                      (decode(g_document_type, 'RFQ', '',
                      (decode(interface.pcard_id, NULL,
                              nvl(item.invoice_close_tolerance,
                              params.invoice_close_tolerance), 100))))),
               decode(g_interface_source_code,'CONSUMPTION_ADVICE', 100 , -- CONSIGNED FPI
                     (decode(g_document_type, 'RFQ', '',
      nvl(item.receive_close_tolerance,
      params.receive_close_tolerance)))),
/** BUG 843414, bgu, Mar. 23, 1999
 *  "Accrue on Receipt" should not be allowed for P-card
 *  orders because of accounting restrictions.
 */
              decode(interface.transaction_flow_header_id, NULL,  --<Shared Proc FPJ>
               decode(interface.consigned_flag, 'Y', 'N' , -- CONSIGNED FPI
                  decode(g_document_type, 'RFQ', '',
                    DECODE( interface.pcard_id, NULL,
          DECODE(interface.destination_type_code,
                      'EXPENSE',DECODE(nvl(item.receipt_required_flag,
                                           nvl(interface.receipt_required_flag,
             nvl(vendor.receipt_required_flag,
             nvl(params.receiving_flag,'N')))),
                                        'N', 'N',
                                        DECODE(params.expense_accrual_code,
                                               'PERIOD END', 'N', 'Y')),
                      'Y'),'N'))), 'Y'),    --<Shared Proc FPJ>
               decode(g_document_type, 'RFQ','',
      rc.allow_substitute_receipts_flag),

      /*bug 9155693 START -->
            While autocreating RFQ from Req. receiving controls values were set to NULL
            which cause receiving controls values reamin NULL in PO, which was created
            by copying RFQ to Quotation to PO.
            Hence, setting receving control fields to defaulted values.

       decode(g_document_type, 'RFQ', '',
       rc.receiving_routing_id),
      */
               rc.receiving_routing_id,
      -- bug 9155693 END

               rc.qty_rcv_tolerance,
               rc.qty_rcv_exception_code,

       --bug 9155693 START
      /*decode(g_document_type, 'RFQ', '',
            rc.receipt_days_exception_code),
      */
            rc.receipt_days_exception_code,
      --bug 9155693 END

         decode(g_document_type, 'RFQ', interface.terms_id, ''),
         decode(g_document_type, 'RFQ', interface.ship_via_lookup_code,
      ''),
         decode(g_document_type, 'RFQ',
      interface.freight_terms_lookup_code, ''),
         decode(g_document_type, 'RFQ',
      interface.fob_lookup_code, ''),
         /* Bug 3913683 : we want to import the unit measure lookup code for
                          all document types and not just RFQ's so commenting out
        below decode. */
         /*   decode(g_document_type, 'RFQ',
      interface.unit_meas_lookup_code), */
      -- bug 5208159
      nvl(x_po_uom,interface.unit_meas_lookup_code),
    -- Bug 3496450. Based the defaulting on promised date going
                --     into the database rather than needby date. Put a to_date
                --     around null so that decode returns date and does not
                --     truncate time information
               decode(g_document_type,'RFQ',to_date(null),l_promised_date+rc.days_late_receipt_allowed),
               decode(g_interface_source_code,'CONSUMPTION_ADVICE', 'P' , -- CONSIGNED FPI
                      decode(interface.consigned_flag, 'Y', 'P', --bug 2861408
                             decode(g_document_type, 'RFQ', '',           --bgu, Dec. 7, 98
                  vendor.invoice_match_option)
                            )
                     ),
         x_country_of_origin_code,
--<INVCONV R12> replace interface.secondary_unit_of_measure/secondary quantity with variables.
-- also replace in the decode
-- start of 1548597
               x_secondary_unit_of_measure,
               x_secondary_quantity,
               interface.preferred_grade,
               decode(x_secondary_unit_of_measure,NULL,NULL,0),
               decode(x_secondary_unit_of_measure,NULL,NULL,0),
               decode(x_secondary_unit_of_measure,NULL,NULL,0),
               decode(x_secondary_unit_of_measure,NULL,NULL,0),
-- end of 1548597
               interface.vmi_flag ,  -- VMI FPH
               interface.drop_ship_flag,   --  <DropShip FPJ>
               interface.consigned_flag,  -- CONSIGNED FPI
               interface.transaction_flow_header_id, --<Shared Proc FPJ>
               g_purchasing_ou_id            --<Shared Proc FPJ>
               --<DBI Req Fulfillment 11.5.11 Start >
               , decode(g_interface_source_code,'CONSUMPTION_ADVICE',
                        sysdate,null)   --- Closed_for_receiving_date
               , decode(interface.consigned_flag, 'Y',
                         sysdate,null )  --- Closed_for_invoice_date
               --<DBI Req Fulfillment 11.5.11 End >
              -- <Complex Work R12 Start>
              , x_order_type_lookup_code
              , l_matching_basis
              -- <Complex Work R12 End>
        , p_outsourced_assembly --<SHIKYU R12>
        , nvl2(g_calculate_tax_flag, 'CREATE', null) --<eTax Integration R12>
        , interface.attribute_category
        );
    l_progress := '260';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create shipment: After insert into po line locations');
    END IF;

   -- Bug 882050: Shipment level global attribute
if g_document_type = 'RFQ' then
null;
-- <Bug 8513167>
-- Make the call for all document types. Added BLANKET
elsif (interface.document_subtype IN ('STANDARD','PLANNED','BLANKET')) THEN
        calculate_local(interface.document_subtype, 'SHIPMENT',
                        x_line_location_id);
   elsif (g_document_subtype='RELEASE') THEN
        calculate_local('RELEASE', 'SHIPMENT', x_line_location_id);
   end if;


    l_progress := '270';
      /*
      ** 9/10/97 ecso
      ** OE Callback function for maintaining so_drop_ship_sources table
      */
   --<SOURCING TO PO FPH>
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-4 starts');
    END IF;

   --No need to update oe tables when requisition line id is null,negotiation
   --lines would not result in a drop ship PO
   if interface.requisition_line_id is not null then
   IF (g_document_type = 'PO') THEN
  x_p_api_version     := 1.0; -- as requested by OE
  x_p_line_location_id    := x_line_location_id;

    l_progress := '280';
  BEGIN
   SELECT PO_HEADER_ID
    ,PO_LINE_ID
   INTO x_p_po_header_id
    ,x_p_po_line_id
   FROM   PO_LINE_LOCATIONS_ALL  --<Shared Proc FPJ>
   WHERE  LINE_LOCATION_ID = x_line_location_id;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
         WHEN OTHERS THEN
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                    END IF;
        END;

    l_progress := '290';
  BEGIN
     SELECT requisition_header_id
     INTO   x_p_req_header_id
     FROM   po_requisition_lines_all  --<Shared Proc FPJ>
   WHERE  requisition_line_id = interface.requisition_line_id;
        EXCEPTION
               WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
         WHEN OTHERS THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
                END IF;
        END;

  IF g_document_subtype = 'RELEASE' THEN
   x_p_po_release_id := g_po_release_id;
  ELSE
   x_p_po_release_id := '';
  END IF;

    l_progress := '300';
  oe_drop_ship_grp.update_po_info(x_p_api_version,
          x_p_return_status,
          x_p_msg_count,
          x_p_msg_data,
          x_p_req_header_id,
          interface.requisition_line_id,
          x_p_po_header_id,
          x_p_po_line_id,
          x_p_line_location_id,
          x_p_po_release_id
          );

    l_progress := '310';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-4 ends');
    END IF;
   --<SOURCING TO PO FPH End>

   END IF; /* end of OE callback for PO */
   end if;
   --
  END IF;

  l_progress := '320';

  IF (g_document_type = 'PO') THEN

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create shipment: Before calling create_distribution');
    END IF;
    create_distributions(
      x_po_line_id,
      x_line_location_id,
      x_po_release_id,
      p_rate_for_req_fields -- <ACHTML R12>
    );

  END IF;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;

EXCEPTION
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(interface.interface_header_id);
     po_message_s.sql_error('CREATE_SHIPMENTS',l_progress,sqlcode);
     raise;
END create_shipment;

/* ============================================================================
     NAME: CREATE_DISTRIBUTION
     DESC: Create document distribution
     ARGS: IN : x_requisition_line_id IN number
           IN : x_po_line_id IN number
           IN : x_Line_location_id IN number
           IN : x_po_release_id IN number
     ALGR:

   ==========================================================================*/
PROCEDURE create_distributions(
  x_po_line_id IN number,
  x_line_location_id IN number,
  x_po_release_id IN number,
  p_rate_for_req_fields IN NUMBER -- <ACHTML R12>
  )
IS
x_distribution_num number;
x_po_distribution_id number;
x_gl_date_option varchar2(25);
x_po_appl_id number;
x_gl_appl_id number;
x_sob_id    number;
/* obtain currency info to adjust precision */
x_precision         number := 2;
x_ext_precision     number := 5;
x_min_unit          number :='';
x_order_type_lookup_code varchar2(15);

x_kanban_card_id  number:='';
x_accrued_flag          varchar2(1);
x_po_uom                varchar2(25):=null;
x_uom_convert           varchar2(2) := fnd_profile.value('PO_REQ_BPA_UOM_CONVERT');
x_conversion_rate       number := 1;

-- Bug 7661419, No conversion for same currency.
x_req_rate              PO_REQUISITION_LINES_ALL.rate%TYPE;
x_req_currency_code     PO_REQUISITION_LINES_ALL.currency_code%TYPE;
x_rate                  PO_REQUISITION_LINES_ALL.rate%TYPE;
-- Bug 7661419 end
-- <SERVICES FPJ START>
--
l_uom_conversion_rate        MTL_UOM_CONVERSIONS.conversion_rate%TYPE := 1;
l_currency_conversion_rate   PO_HEADERS_ALL.rate%TYPE := 1;
--
-- <SERVICES FPJ END>

/* Bug 1030123: cursor to get all the distributions based on the line id */

l_api_name CONSTANT VARCHAR2(30) := 'create_distributions';

cursor c_dist is
  select po_distribution_id
    from po_distributions_all  --<Shared Proc FPJ>
   where line_location_id = x_line_location_id;

--<MRC FPJ Start>
l_key NUMBER;
l_return_status VARCHAR2(1);
l_msg_data VARCHAR2(2000);
l_msg_count NUMBER;
--<MRC FPJ End>

l_progress VARCHAR2(3) := '000';                    --< Bug 3210331 >


l_amount_ordered  NUMBER; --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
l_drop_ship_flag   po_line_locations.drop_ship_flag%type; --bug#3603067
-- bug 5208159
l_from_type_lookup_code po_headers_all.TYPE_LOOKUP_CODE%type;

--introduced to hold the value of drop_ship_flag for shipments
BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_distributions: po_line_id: '||x_po_line_id);
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_distributions: po_line_loc_id: '||x_line_location_id);
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_distributions: po_release_id: '||x_po_release_id);
    END IF;

    /*
    ** get previous max distribution number for this shipment
    */
    l_progress:='010';
    SELECT nvl(max(distribution_num), 0)
      INTO x_distribution_num
      FROM po_distributions_all  --<Shared Proc FPJ>
     WHERE line_location_id = x_line_location_id;

    l_progress:='020';
    fnd_profile.get('PO_AUTOCREATE_DATE',x_gl_date_option);

     /* Bug 482648 ecso 4/30/97
      * Move quantity conversion from setup_interface_tables
      * to create_distribution for consistency
      */

    l_progress := '030';
    SELECT order_type_lookup_code
    INTO   x_order_type_lookup_code
    FROM   po_line_types
    WHERE  line_type_id = interface.line_type_id;

    l_progress := '040';
    SELECT set_of_books_id
      INTO x_sob_id
      FROM financials_system_params_all  --<Shared Proc FPJ>
     WHERE NVL(org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>


    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_distributions: Order type: '||x_order_type_lookup_code);
    END IF;

    -- <BUG 3422146> Removed IF condition so that we will always get the
    -- the precision/extended precision information for the PO currency.
    --
     -- Bug 4471683: added not null check for currency
    IF interface.h_currency_code IS NOT NULL THEN
      FND_CURRENCY.get_info ( currency_code => interface.h_currency_code -- IN
                          , precision     => x_precision               -- OUT
                          , ext_precision => x_ext_precision           -- OUT
                          , min_acct_unit => x_min_unit                -- OUT
                          );
    END IF;

    l_progress := '050';

   /* R11: Enhancement to support Kanban
    * ecso 8/29/97
    * Kanban_Card_Id is copied from requisition line
    * to po_distributions
    */
  --<SOURCING TO PO FPH>
  --Even sourcing need to execute this when backed by a req.
    Begin
      SELECT KANBAN_CARD_ID
      INTO   x_kanban_card_id
      FROM   po_requisition_lines_all pol  --<Shared Proc FPJ>
      WHERE  pol.REQUISITION_LINE_ID = interface.requisition_line_id;
    Exception
         WHEN NO_DATA_FOUND THEN
     /* Not all req has kanban id */
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'NO_DATA_FOUND: '||SQLERRM);
            END IF;
         WHEN OTHERS THEN
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
           raise;
    End;

/* 661570 - svaidyan : Use nvl(x_ext_precision,5) for rounding the qty
                       if the order type lookup code is not quantity */

/** BUG 843414,  bgu, Apr. 23, 1999
 *  For Pcard PO or release, set the accrued_flag to yes, such that Receipt Accruals
 *  - Period-End Process will not accrue pcard related receipts.
 */
if(interface.pcard_id is not null) then
  x_accrued_flag := 'Y';
else
  x_accrued_flag := 'N';
end if;

    l_progress:='060';

/* 875315 - csheu: if the gl_date_option is not 'REQ GL DATE'
            then we need to make sure the period_name is not NULL
            even the period may not be opened */

/* also use fnd_application table to find the application_id */
    SELECT application_id
    INTO   x_po_appl_id
    FROM   fnd_application
    WHERE  application_short_name = 'PO';

    l_progress := '070';
    SELECT application_id
    INTO   x_gl_appl_id
    FROM   fnd_application
    WHERE  application_short_name = 'SQLGL';

/* 973348, duplicate of 966370
   The following should be done only if the po encumbrance flag is yes
*/

    if ((params.po_encumbrance_flag = 'Y') and
        (x_gl_date_option <> 'REQ GL DATE') and
        (params.period_name IS NULL)) THEN

          l_progress := '080';
          SELECT PS1.period_name
           INTO   params.period_name
           FROM   GL_PERIOD_STATUSES PS1
           ,      GL_PERIOD_STATUSES PS2
           ,      GL_SETS_OF_BOOKS GSOB
           WHERE  PS1.application_id = x_gl_appl_id
           AND    PS1.set_of_books_id = params.sob_id
           AND    PS1.adjustment_period_flag = 'N'
           AND    trunc(sysdate) BETWEEN trunc(PS1.start_date)
                                 AND     trunc(PS1.end_date)
           AND    ps1.period_year <= gsob.latest_encumbrance_year
           AND    gsob.set_of_books_id = params.sob_id
           AND    PS1.period_name = PS2.period_name
           AND    PS2.application_id = x_po_appl_id
           AND    PS2.adjustment_period_flag = 'N'
           AND    PS2.set_of_books_id = params.sob_id;
    end if;

    /** Bug 1039361
     *  bgu, Oct. 22, 1999
     *  Port Bug 1030123 in r11 to r115
     *  need to put the NEXTVAL inside the insert as there may
     *  be more than one distribution.
     */

  /* Enh : 1660036 */

  -- bug 5208159 : Conversion of req UOM to Quotation UOM should always happen if the
  -- source document is a quote and profile 'PO: Convert Requisition UOM to Source Document UOM'
  -- should be ignored in that case
  IF (interface.from_line_id IS NOT NULL) AND (g_document_subtype = 'STANDARD') THEN
      l_progress := '085';

      BEGIN

        SELECT poh.type_lookup_code
        INTO   l_from_type_lookup_code
        FROM   po_headers_all poh
        WHERE poh.po_header_id=interface.from_header_id ;

      EXCEPTION
        WHEN OTHERS THEN
            IF g_debug_unexp THEN
                 PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                    p_progress => l_progress);
            END IF;
            po_message_s.sql_error('CREATE_LINE',l_progress,sqlcode);
            wrapup(interface.interface_header_id);
            raise;
      END;
  END IF;

  IF (nvl(x_uom_convert,'N') = 'Y' OR (l_from_type_lookup_code = 'QUOTATION')) THEN
  -- bug 5208159 end

   IF (g_document_subtype='RELEASE')
     -- Bug 2735840 Convert UOM when autocreating a PO that references a GA
     OR ((g_document_subtype='STANDARD')
         AND (interface.from_line_id is not null)) THEN

   /* get the uom from the PO . This will be used for uom conversion */
    BEGIN
      IF (g_document_subtype='RELEASE') THEN -- Bug 2735840
        l_progress := '090';
        select unit_meas_lookup_code
        into x_po_uom
        from po_lines_all pol ,  --<Shared Proc FPJ>
             po_headers_all poh  --<Shared Proc FPJ>
        where pol.po_header_id = poh.po_header_id
        and pol.po_header_id = interface.po_header_id
        and pol.line_num = interface.line_num;
      -- Bug 2735840 START
      ELSE -- Autocreating a PO that references a GA
        l_progress := '100';
        SELECT unit_meas_lookup_code
        INTO x_po_uom
        FROM po_lines_all
        WHERE po_line_id = interface.from_line_id;
      END IF; -- g_document_subtype
      -- Bug 2735840 END

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Create_distributions: UOM is: '||x_po_uom);
        END IF;
     EXCEPTION
     WHEN OTHERS THEN
        IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                               p_progress => l_progress);
        END IF;
       po_message_s.sql_error('CREATE_DISTRIBUTIONS',l_progress,sqlcode);
       wrapup(interface.interface_header_id);
       raise;
    END;

    l_progress := '110';
   /* before inserting into the distributions table get the conversion rate to convert
      into the BPA uom if the uom's on the req and BPA are different .
      This conversion is done only if the Convert UOM  profile option is set to Yes. */

      if interface.unit_meas_lookup_code <> x_po_uom then

       x_conversion_rate := po_uom_s.po_uom_convert(interface.unit_meas_lookup_code,
                                              x_po_uom,
                                              interface.item_id);
      else

       x_conversion_rate := 1;

      end if;
      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'Create_distributions: Conversion rate is: '||x_conversion_rate);
      END IF;

    END IF;
  END IF;

    l_progress := '120';
  --<SOURCING TO PO FPH START>
  --Dont insert distribution record if the various account_id s are
  --not defaulted for negotiation lines which are not backed by req for sourcing
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-5 starts');
    END IF;
  if (g_interface_source_code in ('SOURCING','CONSUMPTION_ADVICE') and  -- CONSIGNED FPI
     (interface.charge_account_id is null or
      interface.accrual_account_id is null or
      interface.variance_account_id is null or
      (interface.encumbered_flag='Y' and
       interface.budget_account_id is null))) then
      null;
  else

    l_uom_conversion_rate := x_conversion_rate;               -- <SERVICES FPJ>
    -- <ACHTML R12>
    l_currency_conversion_rate := p_rate_for_req_fields; -- <SERVICES FPJ>

    l_progress := '130';

  --<SOURCING TO PO FPH END>


    l_progress := '150';
    --<GRANTS FPJ START>
    --SQL WHAT: Update po_distributions_interface table with
    --          po_distribution_id's and distribution_num

    UPDATE po_distributions_interface
    SET    po_distribution_id = po_distributions_s.NEXTVAL,
           distribution_num = x_distribution_num + rownum
    WHERE  interface_header_id = interface.interface_header_id
           AND interface_line_id = interface.interface_line_id;

    l_progress := '160';
    update_award_distributions;

    --<GRANTS FPJ END>

    l_progress := '170';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Sourcing to FPH-5 ends and insert into distributions');
    END IF;

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--bug#3603067 need to get the value of drop ship flag for the shipment
begin
    select nvl(drop_ship_flag,'N') into l_drop_ship_flag
    from po_line_locations_all where
    line_location_id=x_line_location_id;
exception
    when others then
  null;
end;
--bug#3603067

BEGIN
SELECT pdi.amount_ordered
INTO   l_amount_ordered
FROM po_distributions_interface pdi, po_line_locations_all poll
           WHERE pdi.interface_header_id = interface.interface_header_id
             AND pdi.interface_line_id = interface.interface_line_id
             AND poll.line_location_id = x_line_location_id;

PO_DEBUG.debug_var(g_log_head||l_api_name, l_progress, 'l_amount_ordered',l_amount_ordered);
PO_DEBUG.debug_var(g_log_head||l_api_name, l_progress, 'x_order_type_lookup_code',x_order_type_lookup_code);
PO_DEBUG.debug_var(g_log_head||l_api_name, l_progress, 'l_currency_conversion_rate',l_currency_conversion_rate);
PO_DEBUG.debug_var(g_log_head||l_api_name, l_progress, 'l_uom_conversion_rate',l_uom_conversion_rate);
PO_DEBUG.debug_var(g_log_head||l_api_name, l_progress, 'x_precision',x_precision);


EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;

-- Bug 7661419, No conversion for same currency.
BEGIN
SELECT PRL.currency_code,
       Nvl(PRL.rate,1)
INTO   x_req_currency_code,
       x_req_rate
FROM   po_requisition_lines_all PRL
WHERE  PRL.requisition_line_id = INTERFACE.requisition_line_id;

EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;

IF ( x_req_currency_code = INTERFACE.h_currency_code ) THEN
   x_rate:=x_req_rate;
ELSE
   x_rate:= p_rate_for_req_fields;
END IF;

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    INSERT INTO po_distributions_all  --<Shared Proc FPJ>
                (po_distribution_id,
                 last_update_date,
                 last_updated_by,
                 po_header_id,
                 creation_date,
                 created_by,
                 last_update_login,
                 po_line_id,
                 line_location_id,
                 po_release_id,
                 req_distribution_id,
                 set_of_books_id,
                 code_combination_id,
                 deliver_to_location_id,
                 deliver_to_person_id,
                 quantity_ordered,
                 quantity_delivered,
                 quantity_billed,
                 quantity_cancelled,
                 amount_ordered,                              -- <SERVICES FPJ>
                 amount_delivered,                            -- <SERVICES FPJ>
                 amount_cancelled,                            -- <SERVICES FPJ>
                 amount_billed,                               -- <SERVICES FPJ>
                 rate_date,
                 rate,
                 accrued_flag,
                 encumbered_flag,
                 gl_encumbered_date,
                 gl_encumbered_period_name,
                 distribution_num,
                 destination_type_code,
                 destination_organization_id,
                 destination_subinventory,
                 budget_account_id,
                 accrual_account_id,
                 variance_account_id,

                 --< Shared Proc FPJ Start >
                 dest_charge_account_id,
                 dest_variance_account_id,
                 --< Shared Proc FPJ End >

                 wip_entity_id,
                 wip_line_id,
                 wip_repetitive_schedule_id,
                 wip_operation_seq_num,
                 wip_resource_seq_num,
                 bom_resource_id,
                 prevent_encumbrance_flag,
                 project_id,
                 task_id,
                 end_item_unit_number,
                 expenditure_type,
                 project_accounting_context,
                 destination_context,
                 expenditure_organization_id,
                 expenditure_item_date,
                 accrue_on_receipt_flag,
                 kanban_card_id,
                 tax_recovery_override_flag,  --<eTax Integration R12>
                 recovery_rate,
                 award_id,
                 --togeorge 09/27/2000
                 --added oke columns
                 oke_contract_line_id,
                 oke_contract_deliverable_id,
                 org_id,  --<Shared Proc FPJ>
                 distribution_type,  -- <Encumbrance FPJ>
                 tax_attribute_update_code,  --<eTax Integration R12>
                 interface_distribution_ref --<ECO 5373370>
                 )
          SELECT pdi.po_distribution_id, --<GRANTS FPJ>
                 interface.last_update_date,
                 interface.last_updated_by,
                 interface.po_header_id,
                 interface.creation_date,
                 interface.created_by,
                 interface.last_update_login,
                 x_po_line_id,
                 x_line_location_id,
                 decode(g_document_subtype,'RELEASE',x_po_release_id,''),
                 pdi.req_distribution_id,
                 nvl(x_sob_id, pdi.set_of_books_id), --<Bug 3692789>
                 pdi.charge_account_id,
                 pdi.deliver_to_location_id,
     --bug#3603067 if the drop_ship_flag is 'Y' then we
     --need to pass null
                 decode(l_drop_ship_flag,'Y',NULL,pdi.deliver_to_person_id),

                 -- <SERVICES FPJ START>
                 -- Bug 3472140: Changed precisions to 15
                 decode(
                   x_order_type_lookup_code,
                   'QUANTITY',
                   round((pdi.quantity_ordered * x_conversion_rate), 15),
                   'AMOUNT',
                   round(
                     (pdi.quantity_ordered
                      * x_conversion_rate
                      / x_rate), -- <ACHTML R12> -- Bug 7661419
                     nvl(x_ext_precision, 15)
                   ),
                   NULL
                 ),
                 -- <SERVICES FPJ END>

                 0,
                 0,
                 0,

                 -- <SERVICES FPJ START>
                 decode ( x_order_type_lookup_code          -- amount_ordered
                        , 'RATE'       ,round (   ( pdi.amount_ordered
                                                  * l_uom_conversion_rate
                                                  / l_currency_conversion_rate)
                                              , x_precision )
                        , 'FIXED PRICE',round (   ( pdi.amount_ordered
                                                  / l_currency_conversion_rate)
                                              , x_precision )
                                       ,NULL
                        ),
                 0,                                         -- amount_delivered
                 0,                                         -- amount_cancelled
                 0,                                         -- amount_billed
                 -- <SERVICES FPJ END>

                 pdi.rate_date,
                 pdi.rate,
     x_accrued_flag,
                 'N'

      --<Encumbrance FPJ>
      -- If Req encumbrance is on and the profile option requests
      -- that the Req's GL date be used, use the Req's GL date.
      -- Otherwise, if PO enc is on, use SYSDATE.
      --            if PO enc is not on, use NULL.

      -- gl_encumbered_date =
      ,  NVL(  DECODE(  params.req_encumbrance_flag
                     ,  'Y', DECODE(   x_gl_date_option
                                    ,  'REQ GL DATE', pdi.gl_encumbered_date
                                    ,  NULL
                                    )
                     ,  NULL
                     )
            ,  DECODE(  params.po_encumbrance_flag
                     ,  'Y', TRUNC(SYSDATE)
                     ,  NULL
                     )
            )

      -- gl_encumbered_period_name =
      ,  NVL(  DECODE(  params.req_encumbrance_flag
                     ,  'Y', DECODE(x_gl_date_option
                                 ,  'REQ GL DATE', pdi.gl_encumbered_period_name
                                 ,  NULL
                                 )
                     ,  NULL
                     )
            ,  DECODE(  params.po_encumbrance_flag
                     ,  'Y', params.period_name
                     ,  NULL
                     )
            )

             ,   pdi.distribution_num, --<GRANTS FPJ>
                 pdi.destination_type_code,
                 pdi.destination_organization_id,
                 pdi.destination_subinventory,
                 pdi.budget_account_id,
                 pdi.accrual_account_id,
                 pdi.variance_account_id,

                 --< Shared Proc FPJ Start >
                 -- Copy the receiving accounts from the interface table to
                 -- the PO table.
                 pdi.dest_charge_account_id,
                 pdi.dest_variance_account_id,
                 --< Shared Proc FPJ End >

                 pdi.wip_entity_id,
                 pdi.wip_line_id,
                 pdi.wip_repetitive_schedule_id,
                 pdi.wip_operation_seq_num,
                 pdi.wip_resource_seq_num,
                 pdi.bom_resource_id
               --<ENCUMBRANCE FPJ>
               -- prevent_encumbrance_flag =
                /*,  DECODE(  pdi.destination_type_code
                        ,  g_dest_type_code_SHOP_FLOOR, 'Y'
                        ,  'N'
                        )   Commented for Encumbrance Project*/
                , DECODE(  pdi.destination_type_code
                        			,  g_dest_type_code_SHOP_FLOOR
                        					, decode((select entity_type
									  from wip_entities
									  where wip_entity_id= pdi.wip_entity_id),6, 'N', 'Y')
                        ,  'N'
                        )         /* Encumbrance Project - to enable encumbrance for destination type Shop Floor and WIP entity type EAM  */

               ,  pdi.project_id,
                 pdi.task_id,
                 pdi.end_item_unit_number,
                 pdi.expenditure_type,
                 pdi.project_accounting_context,
                 pdi.destination_context,
                 pdi.expenditure_organization_id,
                 pdi.expenditure_item_date,
                 decode(interface.transaction_flow_header_id, NULL, --<Shared Proc FPJ>
                        DECODE(interface.destination_type_code,
                               'EXPENSE',
                               decode(nvl(item.receipt_required_flag,
                                          nvl(interface.receipt_required_flag,
                                              nvl(vendor.receipt_required_flag,
                                                  nvl(params.receiving_flag,'N')))),
                                      'N', 'N',
                                      decode(params.expense_accrual_code,
                                             'PERIOD END', 'N', 'Y')),
                               'INVENTORY', 'Y',
                               'SHOP FLOOR', 'Y'),
                        'Y'), --<Shared Proc FPJ>
                 x_kanban_card_id,
                 pdi.tax_recovery_override_flag,  --<eTax integration R12>
                 decode(pdi.tax_recovery_override_flag, 'Y', pdi.recovery_rate, null),  --<eTax integration R12>
                 pdi.award_id,   -- OGM_0.0 changes..
                 --togeorge 09/27/2000
                 --added oke columns
                 interface.oke_contract_line_id,
                 interface.oke_contract_deliverable_id,
                 g_purchasing_ou_id,  --<Shared Proc FPJ>
                 poll.shipment_type,  -- <Encumbrance FPJ: join on poll.line_location_id added>
                 nvl2(g_calculate_tax_flag, 'CREATE', null), --<eTax integration R12>
                 pdi.interface_distribution_ref --<ECO 5373370>
            FROM po_distributions_interface pdi, po_line_locations_all poll
           WHERE pdi.interface_header_id = interface.interface_header_id
             AND pdi.interface_line_id = interface.interface_line_id
             AND poll.line_location_id = x_line_location_id;  --<Encumbrance FPJ>


    -- <BUG 3322948> Correct last distribution amount for any conversion and
    -- rounding inaccuracies to ensure that the distribution amounts add up
    -- to their corresponding shipment amount.
    --
    XX_PO_INTERFACE_PKG.calibrate_last_dist_amount(x_line_location_id);

    -- bug 8736118
    -- Correct last distribution quantity for any conversion and
    -- rounding inaccuracies to ensure that the distribution quantity add up
    -- to their corresponding shipment quantity.
    XX_PO_INTERFACE_PKG.calibrate_last_dist_quantity(x_line_location_id);

  end if;
    -- Bug 882050: Dist level global attribute

    l_progress := '210';
    /* Bug 1030123: Since there may be more than a distribution, we need to
       loop thru all the distribution based on the line id */

    begin

      open c_dist;

      loop

        fetch c_dist into x_po_distribution_id;

        exit when c_dist%NOTFOUND;

        -- <Bug 8513167>
        -- Make the call for all document types. Added BLANKET
        if (interface.document_subtype IN ('STANDARD','PLANNED','BLANKET')) THEN
           l_progress := '220';
           calculate_local(interface.document_subtype, 'DISTRIBUTION',
                           x_po_distribution_id);
        elsif (g_document_subtype='RELEASE') THEN
            l_progress := '230';
            calculate_local('RELEASE', 'DISTRIBUTION', x_po_distribution_id);
        end if;
      end loop;

      close c_dist;

    exception
      when others then
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'EXCEPTION caught; SQL Code is '||SQLCODE||'; Error is '||SQLERRM);
        END IF;
        if c_dist%ISOPEN then
          close c_dist;
        end if;
    end;

     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
     END IF;

EXCEPTION
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(interface.interface_header_id);
     po_message_s.sql_error('CREATE_DISTRIBUTIONS',l_progress,sqlcode);
     raise;
END create_distributions;


------------------------------------------------------------------<BUG 3322948>
-------------------------------------------------------------------------------
--Start of Comments
--Name: calibrate_last_dist_amount
--Pre-reqs:
--  None.
--Modifies:
--  PO_DISTRIBUTIONS_ALL.AMOUNT_ORDERED
--Locks:
--  None.
--Function:
--  This procedure is used to calibrate the amount of the last distribution
--  belonging to a particular PO Shipment. After going through UOM/currency
--  conversion and rounding, there is a chance that the sum of the distribution
--  amounts will not add up to the shipment amount, causing submission checks
--  to fail. To correct this, we will recalculate the last distribution
--  amount as the difference between the shipment amount and the sum of
--  all other distribution amounts.
--Parameters:
--IN:
--p_line_location_id
--  ID belonging to parent shipment of the distributions which need to be
--  calibrated.
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
PROCEDURE calibrate_last_dist_amount
(
    p_line_location_id   IN   NUMBER
)
IS
    l_api_name               VARCHAR2(30) := 'calibrate_last_dist_amount';
    l_log_head               VARCHAR2(100) := g_log_head || l_api_name;
    l_progress               VARCHAR2(3);

    l_sum_dist_amounts       PO_DISTRIBUTIONS_ALL.amount_ordered%TYPE;
    l_last_dist_amount       PO_DISTRIBUTIONS_ALL.amount_ordered%TYPE;
    l_last_distribution_id   PO_DISTRIBUTIONS_ALL.po_distribution_id%TYPE;
    l_shipment_amount        PO_LINE_LOCATIONS_ALL.amount%TYPE;

BEGIN

l_progress:='000'; PO_DEBUG.debug_begin(l_log_head);
l_progress:='010'; PO_DEBUG.debug_var(l_log_head,l_progress,'p_line_location_id',p_line_location_id);

    -- Retrieve Distribution Data =============================================
    --
    -- Get the sum of all distribution amounts
    -- and the ID of the last distribution.
    --
    SELECT sum(amount_ordered)
    ,      max(po_distribution_id)
    INTO   l_sum_dist_amounts
    ,      l_last_distribution_id
    FROM   po_distributions_all
    WHERE  line_location_id = p_line_location_id;

l_progress:='020'; PO_DEBUG.debug_var(l_log_head,l_progress,'l_sum_dist_amounts',l_sum_dist_amounts);
l_progress:='030'; PO_DEBUG.debug_var(l_log_head,l_progress,'l_last_distribution_id',l_last_distribution_id);


    -- Get the shipment amount ================================================
    --
    SELECT amount
    INTO   l_shipment_amount
    FROM   po_line_locations_all
    WHERE  line_location_id = p_line_location_id;

l_progress:='040'; PO_DEBUG.debug_var(l_log_head,l_progress,'l_shipment_amount',l_shipment_amount);


    -- Correct the last distribution ==========================================
    --
    -- Set it to the shipment amount minus the sum of all distribution
    -- amounts (except the last distribution).
    --
    UPDATE    po_distributions_all
    SET       amount_ordered = l_shipment_amount - (l_sum_dist_amounts - amount_ordered)
    WHERE     po_distribution_id = l_last_distribution_id
    RETURNING amount_ordered
    INTO      l_last_dist_amount;

l_progress:='050'; PO_DEBUG.debug_var(l_log_head,l_progress,'l_last_dist_amount',l_last_dist_amount);

    --=========================================================================

l_progress:='060'; PO_DEBUG.debug_end(l_log_head);

EXCEPTION

    WHEN OTHERS THEN
        PO_DEBUG.debug_exc ( p_log_head => l_log_head
                           , p_progress => l_progress);
        RAISE;

END calibrate_last_dist_amount;

-- <Complex Work R12 Start>
-------------------------------------------------------------------------------
--Start of Comments
--Name: calibrate_last_dist_quantity
--Pre-reqs:
--  None.
--Modifies:
--  PO_DISTRIBUTIONS_ALL.QUANTITY_ORDERED
--Locks:
--  None.
--Function:
--  This procedure is used to calibrate the quantity of the last distribution
--  belonging to a particular PO Shipment. After going through UOM/currency
--  conversion and rounding, there is a chance that the sum of the distribution
--  quantitiess will not add up to the shipment qty, causing submission checks
--  to fail. To correct this, we will recalculate the last distribution
--  quantity as the difference between the shipment quantity and the sum of
--  all other distribution quantities.
--Parameters:
--IN:
--p_line_location_id
--  ID belonging to parent shipment of the distributions which need to be
--  calibrated.
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
PROCEDURE calibrate_last_dist_quantity(
   p_line_location_id   IN   NUMBER
)
IS

d_module   VARCHAR2(70) := 'po.plsql.PO_INTERFACE_S.calibrate_last_dist_quantity';
d_progress NUMBER;

l_sum_dist_quantities       PO_DISTRIBUTIONS_ALL.quantity_ordered%TYPE;
l_last_dist_id              PO_DISTRIBUTIONS_ALL.po_distribution_id%TYPE;
l_last_dist_qty             PO_DISTRIBUTIONS_ALL.quantity_ordered%TYPE;
l_shipment_quantity         PO_LINE_LOCATIONS_ALL.quantity%TYPE;

BEGIN

  d_progress := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_line_location_id', p_line_location_id);
  END IF;

  d_progress := 10;

  SELECT sum(pod.quantity_ordered), max(pod.po_distribution_id)
  INTO l_sum_dist_quantities, l_last_dist_id
  FROM po_distributions_all pod
  WHERE pod.line_location_id = p_line_location_id;

  d_progress := 20;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'l_last_dist_id', l_last_dist_id);
  END IF;

  SELECT poll.quantity
  INTO l_shipment_quantity
  FROM po_line_locations_all poll
  WHERE poll.line_location_id = p_line_location_id;

  d_progress := 30;

  UPDATE po_distributions_all pod
  SET pod.quantity_ordered = l_shipment_quantity -
                              (l_sum_dist_quantities - pod.quantity_ordered)
  WHERE pod.po_distribution_id = l_last_dist_id
  RETURNING pod.quantity_ordered INTO l_last_dist_qty;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'l_last_dist_qty', l_last_dist_qty);
    PO_LOG.proc_end(d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE||SQLERRM);
    END IF;

    RAISE;

END calibrate_last_dist_quantity;
-- <Complex Work R12 End>


/* ============================================================================
     NAME: CREATE_RFQ
     DESC: Create/Add to RFQ from requisition data in the PO_HEADERS,LINES
           and DISTRIBUTION interface tables.
     ARGS: IN : x_interface_header_id IN number
     ALGR:

   ==========================================================================*/
PROCEDURE create_rfq(x_interface_header_id IN number,
         x_document_id IN OUT NOCOPY number) IS

    x_quotation_class_code varchar2(25);
    x_document_num po_headers.segment1%type:=null; -- Bug 1093645

l_api_name CONSTANT VARCHAR2(30) := 'create_documents';

--<MRC FPJ Start>
l_return_status VARCHAR2(1);
l_msg_data VARCHAR2(2000);
l_msg_count NUMBER;
--<MRC FPJ End>
l_progress VARCHAR2(3) := '000';                --< Bug 3210331 >

--<Bug :11071489 REQ_AUTOCREATE Start>--
l_parameter_list  PO_CORE_S4.p_parameter_list;
l_event_name VARCHAR2(100);
--<REQ_AUTOCREATE END>--

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    get_system_defaults;

    l_progress := '010';
    -- populate the interface tables with data from the
    -- requisition.
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_rfq: Before setup_interface_tables');
    END IF;

    -- <Complex Work R12 Start>: Pass in false for p_is_complex_work_po
    setup_interface_tables(
      x_interface_header_id => x_interface_header_id
    , x_document_id => x_document_id
    , p_is_complex_work_po => FALSE
    );
    -- <Complex Work R12 End>

    l_progress := '020';
    -- determine which interface lines and shipments should
    -- be grouped.
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_rfq: Before group_interface_lines');
    END IF;

    group_interface_lines(
      x_interface_header_id => x_interface_header_id
    , p_is_complex_work_po  => FALSE
	, p_group_shipments     => NULL --<Bug 14608120 Autocreate GE ER>
    );

    l_progress := '030';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Create_rfq: interface_hdr id '||x_interface_header_id);
    END IF;

    OPEN interface_cursor(x_interface_header_id);

    FETCH interface_cursor INTO interface;

    IF interface_cursor%notfound THEN
      CLOSE interface_cursor;
      RETURN;
    END IF;

    g_rate_for_req_fields := interface.h_rate;   -- <BUG 4895489>

    IF (g_mode = 'ADD') THEN

       l_progress := '040';
       UPDATE po_headers_all  --<Shared Proc FPJ>
          SET last_update_date  = interface.last_update_date,
              last_updated_by   = interface.last_updated_by,
              last_update_login = interface.last_update_login,
              status_lookup_code = 'I'
        WHERE po_header_id = interface.po_header_id;
    ELSE /* New */

        l_progress := '050';
  SELECT quotation_class_code
        INTO   x_quotation_class_code
        FROM   po_document_types
        WHERE  document_type_code = 'RFQ'
  and    document_subtype   = interface.quote_type_lookup_code;

        l_progress := '060';
    /** Bug 881882, bgu, Apr. 29, 1999
     *  For inserting record into po_headers view, it used
     *  to_date(interface.h_rate_date, 'DD/MM/YYYY') for column rate_date.
     *  But since the data type of interface.h_rate_date is already date,
     *  this is unneccssary and causing problem when system date mask is
     *  defined otherwise.
     */
        INSERT INTO po_headers_all  --<Shared Proc FPJ>
                  (po_header_id,
                   last_update_date,
                   last_updated_by,
                   segment1,
                   created_by,
                   last_update_login,
                   summary_flag,
                   enabled_flag,
                   type_lookup_code,
                   agent_id,
                   creation_date,
                   revision_num,
                   ship_to_location_id,
                   bill_to_location_id,
                   terms_id,
                   ship_via_lookup_code,
                   fob_lookup_code,
                   freight_terms_lookup_code,
                   status_lookup_code,
                   quotation_class_code,
                   quote_type_lookup_code,
       approval_required_flag,
       currency_code,
       rate_type,
       rate_date,
       rate,
                   org_id  --<Shared Proc FPJ>
                  ,style_id   --<R12 STYLES PHASE II >
                   )
            VALUES (interface.po_header_id,
                    interface.last_update_date,
                    interface.last_updated_by,
                    interface.document_num,
                    interface.created_by,
                    interface.last_update_login,
                    'N',
                    'Y',
                    g_document_type,
                    interface.agent_id,
                    interface.creation_date,
                    0,
                    nvl(vendor.ship_to_location_id,
                        interface.ship_to_location_id),
                    nvl(vendor.bill_to_location_id,
                        interface.bill_To_Location_Id),
                    nvl(vendor.terms_id,
                        interface.terms_id),
                    nvl(vendor.ship_via_lookup_code,
                        interface.ship_via_lookup_code),
                    nvl(vendor.fob_lookup_code,
                        interface.fob_lookup_code),
                    nvl(vendor.freight_terms_lookup_code,
                        interface.freight_terms_lookup_code),
                    'I',
                    x_quotation_class_code,
                    interface.quote_type_lookup_code,
        'N',
                    interface.h_currency_code,
                    interface.h_rate_type,
--                    to_date(interface.h_rate_date, 'DD/MM/YYYY'),
        interface.h_rate_date,              -- Bug 881882 , bgu
                    interface.h_rate,
                    g_purchasing_ou_id  --<Shared Proc FPJ>
                    ,interface.style_id   --<R12 STYLES PHASE II >
                    );

    IF(interface.vendor_list_header_id is NOT NULL)THEN

        l_progress := '080';
/* Bug 875124 :
   Using po_vendor_list_entries_v to insert into po_rfq_vendors
   as po_vendor_list_entries_v contains vendor_list with active vendors
*/
         INSERT INTO po_rfq_vendors
                     (po_header_id,
                      sequence_num,
                      last_update_date,
                      last_updated_by,
                      last_update_login,
                      creation_date,
                      created_by,
                      vendor_id,
                      vendor_site_id,
                      vendor_contact_id,
                      print_flag,
                      print_count)
               SELECT interface.po_header_id,
                      rownum,
                      interface.last_update_date,
                      interface.last_updated_by,
                      interface.last_update_login,
                      interface.creation_date,
                      interface.created_by,
                      vendor_id,
                      vendor_site_id,
                      vendor_contact_id,
                      'Y',
                      0
                 FROM po_vendor_list_entries_v
                WHERE vendor_list_header_id = interface.vendor_list_header_id;
      END IF;
    END IF;/* of New */

    /* DEBUG Create the new lines  */
    l_progress:='090';

    -- <Complex Work R12 Start>: Pass in false for p_is_complex_work_po
    create_line(
      x_interface_header_id => x_interface_header_id
    , p_is_complex_work_po => FALSE
    );
    -- <Complex Work R12 End>

    l_progress := '100';
    LOOP

        FETCH interface_cursor INTO interface;
        EXIT WHEN interface_cursor%notfound;

        -- <Complex Work R12 Start>: Pass in false for p_is_complex_work_po
        create_line(
          x_interface_header_id => x_interface_header_id
        , p_is_complex_work_po => FALSE
        );
        -- <Complex Work R12 End>

    END LOOP;

/* bug 1093645:code added to fix the deadlock issue in autocreate*/
    if (g_mode = 'NEW')  then
         IF (params.user_defined_rfq_num_code='AUTOMATIC') AND
            (g_document_type = 'RFQ') THEN

               l_progress := '110';

               -- bug5174177
               x_document_num :=
                 PO_CORE_SV1.default_po_unique_identifier
                 ( p_table_name => 'PO_HEADERS_RFQ',
                   p_org_id     => g_purchasing_ou_id
                 );

               IF g_debug_stmt THEN
                 PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'new po num = ' || x_document_num);
               END IF;

               l_progress := '130';
              UPDATE po_headers set segment1=x_document_num
              where po_header_id=x_document_id;

          END IF;
    END IF;

    l_progress := '140';
   --<Bug :11071489 REQ_AUTOCREATE Start>--
     l_event_name := 'oracle.apps.po.autocreate.rfqcreated';
     l_parameter_list(1).name := 'Interface_Header_ID' ;
     l_parameter_list(1).value := x_interface_header_id;
     po_core_s4.raise_business_event(l_event_name,l_parameter_list);
    --<REQ_AUTOCREATE end>---
    wrapup(x_interface_header_id);

    l_progress := '150';
    CLOSE interface_cursor;

    COMMIT;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;

EXCEPTION
   WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(x_interface_header_id);

     po_message_s.sql_error('CREATE_RFQ',l_progress,sqlcode);
     po_message_s.sql_show_error;
     po_message_s.clear;
     CLOSE interface_cursor;
     --togeorge 11/20/2001
     -- Bug 1349801
     -- Added a Rollback when a Exception was raised
     -- This Rollbacks all the Changes done when a Exception Condition was raised
     ROLLBACK;
END create_rfq;

/* ============================================================================
     NAME: GET_SYSTEM_DEFAULTS
     DESC: Get system defaults
     ARGS: None
     ALGR:

   ==========================================================================*/
PROCEDURE get_system_defaults IS
x_date date;
l_api_name CONSTANT VARCHAR2(30) := 'get_system_defaults';  --< Bug 3210331 >
l_progress VARCHAR2(3) := '000';                            --< Bug 3210331 >
BEGIN
     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
     END IF;

    /* Get WHO column values */
    who.user_id  := nvl(fnd_global.user_id,0);
    who.login_id := nvl(fnd_global.login_id,0);
    who.resp_id  := nvl(fnd_global.resp_id,0);

    l_progress:='010';

    /* Get system defaults */
    po_core_s.get_po_parameters(params.currency_code,
                                params.coa_id,
                                params.po_encumbrance_flag,
                                params.req_encumbrance_flag,
                                params.sob_id,
                                params.ship_to_location_id,
                                params.bill_to_location_id,
                                params.fob_lookup_code,
                                params.freight_terms_lookup_code,
                                params.terms_id,
                                params.default_rate_type,
                                params.taxable_flag,
                                params.receiving_flag,
                                params.enforce_buyer_name_flag,
                                params.enforce_buyer_auth_flag,
                                params.line_type_id,
                                params.manual_po_num_type,
                                params.po_num_code,
                                params.price_type_lookup_code,
                                params.invoice_close_tolerance,
                                params.receive_close_tolerance,
                                params.security_structure_id,
                                params.expense_accrual_code,
                                params.inventory_organization_id,
                                params.rev_sort_ordering,
                                params.min_rel_amount,
                                params.notify_blanket_flag,
                                params.budgetary_control_flag,
                                params.user_defined_req_num_code,
                                params.rfq_required_flag,
                                params.manual_req_num_type,
                                params.enforce_full_lot_qty,
                                params.disposition_warning_flag,
                                params.reserve_at_completion_flag,
                                params.user_defined_rcpt_num_code,
                                params.manual_rcpt_num_type,
              params.use_positions_flag,
              params.default_quote_warning_delay,
                params.inspection_required_flag,
                params.user_defined_quote_num_code,
                params.manual_quote_num_type,
                params.user_defined_rfq_num_code,
                params.manual_rfq_num_type,
                params.ship_via_lookup_code,
	        params.qty_rcv_tolerance,
		params.acceptance_required_flag);    /* Bug 7518967 : Default Acceptance Required Check ER */

        l_progress:='020';

        IF(params.po_encumbrance_flag = 'Y') THEN
          po_core_s.get_period_name(params.sob_id,params.period_name,x_date);
        END IF;

     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
     END IF;

EXCEPTION
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(interface.interface_header_id);
     po_message_s.sql_error('GET SYSTEM DEFAULTS',l_progress,sqlcode);
     raise;

END get_system_defaults;

/* ============================================================================
     NAME: GET_INVOICE MATCH OPTION
     DESC: Get invoice match option
     ARGS: None
     ALGR:

   ==========================================================================*/
PROCEDURE get_invoice_match_option(x_vendor_id    IN number,
         x_vendor_site_id IN number,
         x_invoice_match_option OUT NOCOPY varchar2)
 IS
l_progress VARCHAR2(3) := '000';                                --< Bug 3210331 >
l_api_name CONSTANT VARCHAR2(30) := 'get_invoice_match_option'; --< Bug 3210331 >

BEGIN
     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
     END IF;

   if (X_vendor_site_id is not null) then
     l_progress := '010';
     /* Retrieve Invoice Match Option from Vendor site*/
     SELECT match_option
     INTO   x_invoice_match_option
     FROM   po_vendor_sites_all  --<Shared Proc FPJ>
     WHERE  vendor_site_id = X_vendor_site_id;
   end if;

   if(x_invoice_match_option is NULL) then
     /* Retrieve Invoice Match Option from Vendor */
     if (X_vendor_id is not null) then
       l_progress := '020';
       SELECT match_option
       INTO   x_invoice_match_option
       FROM   po_vendors
       WHERE  vendor_id = X_vendor_id;
     end if;
   end if;

   if(x_invoice_match_option is NULL) then
     l_progress := '030';
     --6057748
     -- Get default from ap_product_setup instead of FSP.
     SELECT aps.match_option
       INTO   x_invoice_match_option
       FROM   ap_product_setup aps;

     /* Retrieve Invoice Match Option from Financial System Parameters */
/*
     SELECT fsp.match_option
       INTO x_invoice_match_option
       FROM financials_system_params_all fsp  --<Shared Proc FPJ>
      WHERE NVL(org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>*/
   end if;

     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
     END IF;
EXCEPTION
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(interface.interface_header_id);
     po_message_s.sql_error('GET INVOICE MATCH OPTION',l_progress,sqlcode);
     raise;

END get_invoice_match_option;

--< Shared Proc FPJ Start >
---------------------------------------------------------------------------
--Start of Comments
--Name: generate_shared_proc_accounts
--Pre-reqs:
--  The global variables g_document_type, g_document_subtype and params
--  should have been populated correctly.
--Modifies:
--  PO_DISTRIBUTIONS_INTERFACE table. The following columns may get
--  modified:
--       CODE_COMBINATION_ID
--       ACCRUAL_ACCOUNT_ID
--       VARIANCE_ACCOUNT_ID
--       BUDGET_ACCOUNT_ID
--       DEST_CHARGE_ACCOUNT_ID
--       DEST_VARIANCE_ACCOUNT_ID
--Locks:
--  None.
--Function:
--  Generates the accounts for shared procurement scenarios by calling
--  the PO AG workflow. After that, it updates the affected records in
--  PO_DISTRIBUTIONS_INTERFACE table with the new account ID's.
--Parameters:
--IN:
--  p_interface_header_id -- The interface header ID of the document being
--                           processed.
--OUT:
--  None
--Testing:
--End of Comments
---------------------------------------------------------------------------
PROCEDURE generate_shared_proc_accounts --(
(
  p_interface_header_id IN NUMBER
)
IS
  l_progress                  VARCHAR2(3) := '000';    --< Bug 3210331 >
  l_return_value          BOOLEAN;
  l_charge_success              BOOLEAN := TRUE;
  l_budget_success              BOOLEAN := TRUE;
  l_accrual_success             BOOLEAN := TRUE;
  l_variance_success            BOOLEAN := TRUE;
  l_charge_account_id           PO_DISTRIBUTIONS_INTERFACE.charge_account_id%TYPE;
  l_budget_account_id           PO_DISTRIBUTIONS_INTERFACE.budget_account_id%TYPE;
  l_accrual_account_id          PO_DISTRIBUTIONS_INTERFACE.accrual_account_id%TYPE;
  l_variance_account_id         PO_DISTRIBUTIONS_INTERFACE.variance_account_id%TYPE;
  l_charge_account_flex         VARCHAR2(2000);
  l_budget_account_flex         VARCHAR2(2000);
  l_accrual_account_flex  VARCHAR2(2000);
  l_variance_account_flex       VARCHAR2(2000);
  l_charge_account_desc         VARCHAR2(2000);
  l_budget_account_desc         VARCHAR2(2000);
  l_accrual_account_desc  VARCHAR2(2000);
  l_variance_account_desc       VARCHAR2(2000);
  l_wf_itemkey              VARCHAR2(80) := NULL;
  l_new_ccid_generated          BOOLEAN := FALSE;
  l_FB_ERROR_MSG          VARCHAR2(2000);

  l_return_status               VARCHAR2(1);
  l_interface_line_id           PO_LINES_INTERFACE.interface_line_id%TYPE;
  l_old_interface_line_id       PO_LINES_INTERFACE.interface_line_id%TYPE := -1;
  l_interface_distribution_id   PO_DISTRIBUTIONS_INTERFACE.interface_distribution_id%TYPE;
  l_item_category_id            PO_LINES_INTERFACE.category_id%TYPE;
  l_req_charge_account_id       PO_DISTRIBUTIONS_INTERFACE.charge_account_id%TYPE;
  l_req_variance_account_id     PO_DISTRIBUTIONS_INTERFACE.variance_account_id%TYPE;
  l_destination_organization_id PO_DISTRIBUTIONS_INTERFACE.destination_organization_id%TYPE;
  l_destination_ou_id           PO_HEADERS_ALL.org_id%TYPE;

  l_item_id       PO_LINES_INTERFACE.item_id%TYPE;
  l_category_id           PO_LINES_INTERFACE.category_id%TYPE;
  l_destination_type_code       PO_DISTRIBUTIONS_ALL.destination_type_code%TYPE;
  --l_ship_to_organization_id      NUMBER;
  l_ship_to_location_id   PO_DISTRIBUTIONS_INTERFACE.deliver_to_location_id%TYPE;
  l_deliver_to_person_id        PO_DISTRIBUTIONS_INTERFACE.deliver_to_person_id%TYPE;
  l_line_type_id          PO_LINES_INTERFACE.line_type_id%TYPE;
  l_vendor_id       PO_VENDORS.vendor_id%TYPE;
  l_agent_id      PO_HEADERS.agent_id%TYPE;
  l_expenditure_organization_id PO_DISTRIBUTIONS_INTERFACE.expenditure_organization_id%TYPE;
  l_project_id      PO_DISTRIBUTIONS_INTERFACE.project_id%TYPE;
  l_task_id       PO_DISTRIBUTIONS_INTERFACE.task_id%TYPE;
  l_bom_resource_id     PO_DISTRIBUTIONS_INTERFACE.bom_resource_id%TYPE;
  l_wip_entity_id     PO_DISTRIBUTIONS_INTERFACE.wip_entity_id%TYPE;
  l_wip_line_id           PO_DISTRIBUTIONS_INTERFACE.wip_line_id%TYPE;
  l_wip_repetitive_schedule_id  PO_DISTRIBUTIONS_INTERFACE.wip_repetitive_schedule_id%TYPE;
  l_gl_encumbered_date    PO_DISTRIBUTIONS_INTERFACE.gl_encumbered_date%TYPE;
  l_destination_subinventory    PO_DISTRIBUTIONS_ALL.destination_subinventory%TYPE;
  l_expenditure_type    PO_DISTRIBUTIONS_ALL.expenditure_type%TYPE;
  l_expenditure_item_date   PO_DISTRIBUTIONS_INTERFACE.expenditure_item_date%TYPE;
  l_wip_operation_seq_num   PO_DISTRIBUTIONS_INTERFACE.wip_operation_seq_num%TYPE;
  l_wip_resource_seq_num        PO_DISTRIBUTIONS_INTERFACE.wip_resource_seq_num%TYPE;


  --< New start_workflow parameters in FPJ End >
  l_transaction_flow_header_id  PO_LINE_LOCATIONS.transaction_flow_header_id%TYPE;
  l_dest_charge_success         BOOLEAN;
  l_dest_variance_success       BOOLEAN;
  l_dest_charge_account_id      PO_DISTRIBUTIONS_INTERFACE.dest_charge_account_id%TYPE;
  l_dest_variance_account_id    PO_DISTRIBUTIONS_INTERFACE.dest_variance_account_id%TYPE;
  l_dest_charge_account_desc    VARCHAR2(2000);
  l_dest_variance_account_desc  VARCHAR2(2000);
  l_dest_charge_account_flex    VARCHAR2(2000);
  l_dest_variance_account_flex  VARCHAR2(2000);
  --< New start_workflow parameters in FPJ End >

  -- Bug 3463242 START
  l_req_line_id                 PO_LINES_INTERFACE.requisition_line_id%TYPE;
  -- <ACHTML R12>
  l_requesting_ou_id            PO_REQUISITION_LINES_ALL.org_id%TYPE;
  l_unit_price                  PO_LINES_INTERFACE.unit_price%TYPE;
  l_base_unit_price             PO_LINES_INTERFACE.base_unit_price%TYPE;
  l_amount                      PO_LINES_INTERFACE.amount%TYPE;
  l_quantity_dummy              PO_LINES_INTERFACE.quantity%TYPE;
  l_order_type_lookup_code      PO_LINE_TYPES_B.order_type_lookup_code%TYPE;
  l_po_currency_code            PO_HEADERS_INTERFACE.currency_code%TYPE;
  l_req_header_rate_type        PO_HEADERS_INTERFACE.rate_type%TYPE;
  l_req_header_rate_date        PO_HEADERS_INTERFACE.rate_date%TYPE;
  l_req_header_rate             PO_HEADERS_INTERFACE.rate%TYPE;
  l_dist_rate                   PO_DISTRIBUTIONS_INTERFACE.rate%TYPE;
  l_rate_for_req_fields         PO_HEADERS_INTERFACE.rate%TYPE;
  l_po_func_unit_price          PO_LINES_ALL.unit_price%TYPE;
  -- Bug 3463242 END

  l_item_in_linv_pou VARCHAR2(1):= 'Y'; -- Bug 3433867

  --SQL WHAT: All those lines inserted in the PO distributions interface table
  --          that have the DOU <> POU.
  --SQL WHY:  To call AG Workflow for line that have a Transaction Flow
  --          defined between DOU and POU.
  CURSOR l_SPS_lines_csr IS
    SELECT pdi.interface_distribution_id,
           pli.interface_line_id,
           pli.category_id,
           pdi.charge_account_id,    -- to be copied onto Dest Charge Account
           pdi.variance_account_id,  -- to be copied onto Dest Variance Account
           pdi.destination_organization_id, -- DINV
           TO_NUMBER(hoi.org_information3), -- DOU
           pli.item_id,
           pli.category_id,
           pdi.destination_type_code,
           pdi.deliver_to_location_id,
           pdi.deliver_to_person_id,
           pli.line_type_id,
           phi.vendor_id,
           phi.agent_id,
           pdi.expenditure_organization_id,
           pdi.project_id,
           pdi.task_id,
           pdi.bom_resource_id,
           pdi.wip_entity_id,
           pdi.wip_line_id,
           pdi.wip_repetitive_schedule_id,
           pdi.gl_encumbered_date,
           pdi.destination_subinventory,
           pdi.expenditure_type,
           pdi.expenditure_item_date,
           pdi.wip_operation_seq_num,
           pdi.wip_resource_seq_num,
           -- Bug 3463242 START
           pli.requisition_line_id,
     -- <ACHTML R12>
     nvl(prl.org_id, g_hdr_requesting_ou_id) requesting_ou_id,
           pli.unit_price,
           pli.base_unit_price,
           pli.amount,
           NVL(plt.order_type_lookup_code,'QUANTITY'),
           phi.currency_code,
           phi.rate_type,
           phi.rate_date,
           phi.rate,
           pdi.rate
           -- Bug 3463242 END
    FROM PO_DISTRIBUTIONS_INTERFACE pdi,
         PO_LINES_INTERFACE pli,
         PO_HEADERS_INTERFACE phi,
   PO_REQUISITION_LINES_ALL prl, -- <ACHTML R12>
         MTL_PARAMETERS mp,
         HR_ORGANIZATION_INFORMATION hoi,
         PO_LINE_TYPES_B plt -- Bug 3463242
    WHERE phi.interface_header_id = p_interface_header_id
      AND pli.interface_header_id = phi.interface_header_id
      AND pli.requisition_line_id = prl.requisition_line_id(+) -- <ACHTML R12>
      AND pdi.interface_line_id = pli.interface_line_id
      AND mp.organization_id = pli.ship_to_organization_id
      AND mp.organization_id = hoi.organization_id
      AND hoi.org_information_context = 'Accounting Information'
      AND hoi.org_information3 <> TO_CHAR(g_purchasing_ou_id)  -- DOU <> POU
      AND pli.line_type_id = plt.line_type_id (+) -- Bug 3463242
    ORDER BY pli.interface_line_id;
  l_api_name VARCHAR2(100) := 'generate_shared_proc_accounts';
BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

  -- Ignore for RFQ's and Blankets
  IF ( g_document_type <> 'PO' OR
       g_document_subtype <> 'STANDARD' ) THEN

    l_progress := '010';
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Ignoring... Type='|| g_document_type|| ' SubType='||g_document_subtype);
    END IF;
    RETURN;
  END IF;

  l_progress := '020';

  OPEN l_SPS_lines_csr;

  l_progress := '030';

  LOOP
    FETCH l_SPS_lines_csr
    INTO l_interface_distribution_id,
         l_interface_line_id,
         l_item_category_id,
         l_req_charge_account_id,
         l_req_variance_account_id,
         l_destination_organization_id,
         l_destination_ou_id,
         l_item_id,
         l_category_id,
         l_destination_type_code,
         l_ship_to_location_id,
         l_deliver_to_person_id,
         l_line_type_id,
         l_vendor_id,
         l_agent_id,
         l_expenditure_organization_id,
         l_project_id,
         l_task_id,
         l_bom_resource_id,
         l_wip_entity_id,
         l_wip_line_id,
         l_wip_repetitive_schedule_id,
         l_gl_encumbered_date,
         l_destination_subinventory,
         l_expenditure_type,
         l_expenditure_item_date,
         l_wip_operation_seq_num,
         l_wip_resource_seq_num,
         -- Bug 3463242 START
         l_req_line_id,
         l_requesting_ou_id, -- <ACHTML R12>
         l_unit_price,
         l_base_unit_price,
         l_amount,
         l_order_type_lookup_code,
         l_po_currency_code,
         l_req_header_rate_type,
         l_req_header_rate_date,
         l_req_header_rate,
         l_dist_rate;
         -- Bug 3463242 END

    l_progress := '040';

    EXIT WHEN l_SPS_lines_csr%NOTFOUND;

    l_progress := '050';

    -- Get the Transaction Flow Header ID from the Inventory API.
    -- Use the wrapper API written in PO.
    PO_SHARED_PROC_PVT.check_transaction_flow(
             p_init_msg_list    => FND_API.G_TRUE,
             x_return_status    => l_return_status,  -- OUT NOCOPY VARCHAR2
             p_start_ou_id      => g_purchasing_ou_id,
             p_end_ou_id        => l_destination_ou_id,
             p_ship_to_org_id   => l_destination_organization_id,
             p_item_category_id => l_item_category_id,
             p_transaction_date => sysdate,
             x_transaction_flow_header_id => l_transaction_flow_header_id);
                                                          -- OUT NOCOPY NUMBER

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'After calling check_transaction_flow l_transaction_flow_header_id='
                                          || to_char(l_transaction_flow_header_id)|| ' l_return_status='
                                          ||l_return_status);
    END IF;

    l_progress := '060';
    IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
        APP_EXCEPTION.raise_exception(
                exception_type => 'PO_SHARED_PROC_PVT.check_transaction_flow',
                exception_code => 0,
                exception_text => 'return_status='||l_return_status);
    END IF;

    -- Bug 3433867 Start
    -- Need to validate the item in the logical inv org of the POU if a
    -- valid transaction flow exists and item id is not null

    l_progress := '065';
    IF l_transaction_flow_header_id IS NOT NULL AND l_item_id IS NOT NULL THEN
       PO_SHARED_PROC_PVT.check_item_in_linv_pou
             (x_return_status              => l_return_status,
              p_item_id                    => l_item_id,
              p_transaction_flow_header_id => l_transaction_flow_header_id,
              x_item_in_linv_pou           => l_item_in_linv_pou);
       IF l_return_status <> FND_API.g_ret_sts_success THEN
          APP_EXCEPTION.raise_exception(
                exception_type => 'PO_SHARED_PROC_PVT.check_item_in_linv_pou',
                exception_code => 0,
                exception_text => 'return_status='||l_return_status);
       ELSIF l_return_status = FND_API.g_ret_sts_success AND
             (l_item_in_linv_pou <> 'Y') THEN
          IF g_debug_stmt THEN
             PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                 p_token    => l_progress,
                                 p_message  => 'After calling check_item_in_linv_pou: Item does not exist in the
                                                logical inv org of the POU'||' l_return_status= '||l_return_status);
          END IF;
          APP_EXCEPTION.raise_exception(
                   exception_type => 'PO_SHARED_PROC_PVT.check_item_in_linv_pou',
                   exception_code => 0,
                   exception_text => 'Item does not exist in the logical inventory org of POU');
       END IF;
    END IF;
    -- Bug 3433867 End

    l_progress := '070';
    -- Call AG Workflow for SPS case
    IF (l_transaction_flow_header_id IS NOT NULL) THEN

      l_progress := '080';

      l_charge_account_id        := NULL;
      l_variance_account_id      := NULL;
      l_accrual_account_id       := NULL;
      l_budget_account_id        := NULL;
      l_dest_charge_account_id   := l_req_charge_account_id; -- Copied from Req
      l_dest_variance_account_id := l_req_variance_account_id;-- Copied from Req

      -- Bug 3463242 START
      -- Convert the unit price to the POU functional currency before passing
      -- it to the PO account generator workflow.

      IF (l_order_type_lookup_code <> 'AMOUNT') THEN

        IF g_debug_stmt THEN
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  =>
            'unit price in ROU currency: ' || l_unit_price
            || ', ROU / requisition rate: ' || l_req_header_rate );
        END IF;

        -- Obtain the rate between the ROU currency and the PO currency.
        --<Sourcing 11.5.10+> No need to do this if called from Sourcing
        IF (g_interface_source_code <> 'SOURCING'
      AND g_purchasing_ou_id <> l_requesting_ou_id) -- <ACHTML R12>
        THEN
          get_rate_for_req_price(
            p_requesting_ou_id => l_requesting_ou_id, -- <ACHTML R12>
            p_purchasing_ou_id => g_purchasing_ou_id, -- <ACHTML R12>
            p_po_currency_code => l_po_currency_code,
            p_rate_type => l_req_header_rate_type,
            p_rate_date => l_req_header_rate_date,
            x_rate => l_rate_for_req_fields
          );
          IF (l_rate_for_req_fields IS NULL)
          THEN
            l_rate_for_req_fields := l_req_header_rate;
          END IF;
        ELSE
          l_rate_for_req_fields := l_req_header_rate;
        END IF;

        -- First convert from the ROU currency to the PO currency.
        XX_PO_INTERFACE_PKG.do_currency_conversion (
          p_order_type_lookup_code => l_order_type_lookup_code,
          p_interface_source_code => g_interface_source_code,
          p_rate => NVL(l_rate_for_req_fields,1),
          p_po_currency_code => l_po_currency_code,
          p_requisition_line_id => l_req_line_id,
          x_quantity => l_quantity_dummy,
          x_unit_price => l_unit_price,
          x_base_unit_price => l_base_unit_price,
          x_amount => l_amount );

        -- Then convert from the PO currency to the POU currency.
        l_po_func_unit_price := l_unit_price * NVL(l_dist_rate,1);

      ELSE -- l_order_type_lookup_code = 'AMOUNT'
        l_po_func_unit_price := l_unit_price;
      END IF; -- l_order_type_lookup_code
      -- Bug 3463242 END

      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Calling AG WF');

        -- Bug 3463242 START
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  =>
          'unit price in PO currency: ' || l_unit_price
          || ', ROU / PO rate: ' || l_rate_for_req_fields
          || ', POU / PO rate: ' || l_dist_rate
          || ', unit price in POU currency (passed to Account Generator): ' || l_po_func_unit_price);
        -- Bug 3463242 END
      END IF;

     l_progress := '090';

      l_return_value := PO_WF_BUILD_ACCOUNT_INIT.Start_Workflow (

        g_purchasing_ou_id,           -- IN
        l_transaction_flow_header_id, -- IN
        l_dest_charge_success,        -- IN OUT
        l_dest_variance_success,      -- IN OUT
        l_dest_charge_account_id,     -- IN OUT
        l_dest_variance_account_id,   -- IN OUT
        l_dest_charge_account_desc,   -- IN OUT
        l_dest_variance_account_desc, -- IN OUT
        l_dest_charge_account_flex,   -- IN OUT
        l_dest_variance_account_flex, -- IN OUT
        l_charge_success,          l_budget_success,
      l_accrual_success,         l_variance_success,
      l_charge_account_id,         l_budget_account_id,
      l_accrual_account_id,        l_variance_account_id,
      l_charge_account_flex,         l_budget_account_flex,
      l_accrual_account_flex,        l_variance_account_flex,
      l_charge_account_desc,         l_budget_account_desc,
      l_accrual_account_desc,        l_variance_account_desc,
        params.coa_id,
        l_bom_resource_id,
        NULL, -- p_bom_cost_element_id
        l_category_id,                 l_destination_type_code,
        l_ship_to_location_id,
        l_destination_organization_id, --<Shared Proc FPJ>
        l_destination_subinventory,    l_expenditure_type,
        l_expenditure_organization_id, l_expenditure_item_date,
        l_item_id ,                    l_line_type_id,
        NULL, -- PA result billable flag
        l_agent_id,
        l_project_id,
        NULL, -- p_from_type_lookup_code
        NULL, -- p_from_header_id
        NULL, -- p_from_line_id
        l_task_id,                     l_deliver_to_person_id,
        g_document_subtype, -- l_type_lookup_code
        l_vendor_id,
        l_wip_entity_id,
        NULL, -- p_wip_entity_type
        l_wip_line_id,                 l_wip_repetitive_schedule_id,
        l_wip_operation_seq_num,       l_wip_resource_seq_num,
        nvl(params.po_encumbrance_flag, 'N'),
        l_gl_encumbered_date,

        l_wf_itemkey, l_new_ccid_generated,

        -- 15 Header attributes -- all NULL's
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        -- 15 Line attributes -- all NULL's
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        -- 15 Shipment attributes -- all NULL's
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        -- 15 Distribution attributes -- all NULL's
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        l_FB_ERROR_MSG,
        --<BUG 3407630 START>
        NULL,  --x_award_id
        NULL,  --x_vendor_site_id
        l_po_func_unit_price -- Bug 3463242
        --<BUG 3407630 END>
        );

      l_progress := '100';

      IF (l_return_value = FALSE) THEN
        APP_EXCEPTION.raise_exception(
                  exception_type => 'PO_WF_BUILD_ACCOUNT_INIT.Start_Workflow',
                  exception_code => 0,
                  exception_text => 'Start_workflow returned FALSE');
      END IF;

      l_progress := '110';

      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'After calling AG WF');
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'Before updating the interface table with trxflowhdrid l_transaction_flow_header_id='
                                            || to_char(l_transaction_flow_header_id)|| ' l_interface_line_id='
                                            ||to_char(l_interface_line_id)||' l_old_interface_line_id ='
                                            ||to_char(l_old_interface_line_id));
      END IF;

      IF l_interface_line_id <> l_old_interface_line_id THEN
         l_progress := '120';
         UPDATE po_lines_interface
            SET transaction_flow_header_id = l_transaction_flow_header_id
          WHERE interface_line_id = l_interface_line_id;

         IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
             PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                 p_token    => l_progress,
                                 p_message  => 'Transaction flow header id updated: SQL%ROWCOUNT = '||SQL%ROWCOUNT);
         END IF;

         l_old_interface_line_id := l_interface_line_id;
      END IF;

      l_progress := '130';

      -- update the distributions interface table with new account ID's
      UPDATE po_distributions_interface
      SET charge_account_id        = l_charge_account_id,
          variance_account_id      = l_variance_account_id,
          accrual_account_id       = l_accrual_account_id,
          budget_account_id        = NULL,
          dest_charge_account_id   = l_dest_charge_account_id,
          dest_variance_account_id = l_dest_variance_account_id
      WHERE interface_distribution_id = l_interface_distribution_id;

      l_progress := '140';

    END IF; -- IF (l_transaction_flow_header_id IS NOT NULL)

    l_progress := '150';

  END LOOP;

  l_progress := '160';

  CLOSE l_SPS_lines_csr;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                           p_progress => l_progress);
    END IF;
    PO_MESSAGE_S.sql_error(l_api_name, l_progress, sqlcode);
    RAISE;
END generate_shared_proc_accounts; --)
--< Shared Proc FPJ End >


------------------------------------------------------------------<BUG 3322948>
-------------------------------------------------------------------------------
--Start of Comments
--Name: do_currency_conversion
--Pre-reqs:
--  None.
--Modifies:
--  None.
--Locks:
--  None.
--Function:
--  This procedure performs currency conversion on the input quantity,
--  unit_price, or amount. Which of the previous values to convert depends
--  on the order_type_lookup_code and the interface_source_code.
--
--  If the Req line currency is the same as the new PO currency, we will take
--  the Req's currency_<unit_price/amount> directly so that conversion
--  calculations will not have to be performed again. Otherwise, we will
--  perform the conversion using the input rate.
--
--Parameters:
--IN:
--p_order_type_lookup_code
--  Value Basis of the Requisition/PO line.
--p_interface_source_code
--  Interface Source Code of the current Autocreate session.
--p_rate
--  Currency conversion rate to convert Req Currency to PO Currency.
--p_po_currency_code
--  Currency code of the to-be-created PO.
--p_requisition_line_id
--  Unique ID of the Requisition line being Autocreated.
--  (May be NULL if coming from Sourcing).
--IN OUT:
--x_quantity
--  Quantity to be converted.
--x_unit_price
--  Unit Price to be converted.
--x_base_unit_price
--  Base Unit Price to be converted.
--x_amount
--  Amount to be converted.
--Testing:
--  None.
--End of Comments
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
PROCEDURE do_currency_conversion
(
    p_order_type_lookup_code   IN              VARCHAR2
,   p_interface_source_code    IN              VARCHAR2
,   p_rate                     IN              NUMBER
,   p_po_currency_code         IN              VARCHAR2
,   p_requisition_line_id      IN              NUMBER
,   x_quantity                 IN OUT NOCOPY   NUMBER
,   x_unit_price               IN OUT NOCOPY   NUMBER
,   x_base_unit_price          IN OUT NOCOPY   NUMBER --bug 3401653
,   x_amount                   IN OUT NOCOPY   NUMBER
)
IS
    l_api_name                VARCHAR2(30) := 'do_currency_conversion';
    l_log_head                VARCHAR2(100) := g_log_head || l_api_name;
    l_progress                VARCHAR2(3);

    l_precision               FND_CURRENCIES.precision%TYPE;
    l_ext_precision           FND_CURRENCIES.extended_precision%TYPE;
    l_min_acct_unit           FND_CURRENCIES.minimum_accountable_unit%TYPE;

    l_req_currency_code       PO_REQUISITION_LINES_ALL.currency_code%TYPE;
    l_req_ou_currency_code    GL_SETS_OF_BOOKS.currency_code%TYPE; -- Bug 3794198
    l_req_unit_price          PO_REQUISITION_LINES_ALL.unit_price%TYPE;
    l_req_currency_unit_price PO_REQUISITION_LINES_ALL.currency_unit_price%TYPE;
    l_req_amount              PO_REQUISITION_LINES_ALL.amount%TYPE;
    l_req_currency_amount     PO_REQUISITION_LINES_ALL.currency_amount%TYPE;
    l_req_rate                PO_REQUISITION_LINES_ALL.rate%TYPE; -- Bug 7661419

BEGIN

l_progress:='000'; PO_DEBUG.debug_begin(l_log_head);

    -- Initialize Variables ===================================================

    -- Get the precision/extended precision for the PO Currency.
    --
    -- Bug 4471683: added not null check for currency
    IF interface.h_currency_code IS NOT NULL THEN
      FND_CURRENCY.get_info ( currency_code => p_po_currency_code
                          , precision     => l_precision
                          , ext_precision => l_ext_precision
                          , min_acct_unit => l_min_acct_unit
                          );
    END IF;

    -- Convert ================================================================

l_progress:='010'; PO_DEBUG.debug_var(l_log_head,l_progress,'p_order_type_lookup_code',p_order_type_lookup_code);

    -- For 'Amount' based lines, we need to convert the quantity since
    -- quantity acts like amount.
    --
    IF ( p_order_type_lookup_code = 'AMOUNT' ) THEN

       l_progress:='010';
       PO_DEBUG.debug_stmt(l_log_head,l_progress,'Performing currency conversion on quantity.');

--Bug 8864722: Start
    IF ( p_interface_source_code IN ('SOURCING','CONSUMPTION_ADVICE') ) THEN
          l_progress:='020';
          PO_DEBUG.debug_stmt(l_log_head,l_progress,'p_interface_source_code IN (SOURCING, CONSUMPTION ADVICE) - no currency conversion performed');

       ELSE
--Bug 8864722:End

       -- Bug 7661419, No conversion for same currency.
       SELECT PRL.currency_code,
              Nvl(PRL.rate,1)
       INTO   l_req_currency_code,
              l_req_rate
       FROM   po_requisition_lines_all PRL
       WHERE  PRL.requisition_line_id = p_requisition_line_id;

       IF ( l_req_currency_code = p_po_currency_code ) THEN
        x_quantity := round ( x_quantity/l_req_rate, nvl(l_ext_precision, 15) );
       ELSE
        x_quantity := round ( x_quantity/p_rate, nvl(l_ext_precision, 15) );
       END IF;

/*Bug 8864722:Start */
       END IF;
 /*Bug 8864722:End */



    -- For all other line types, convert the Price/Amount.
    --
    ELSE -- ( p_order_type_lookup_code IN ('QUANTITY','FIXED PRICE','RATE') )

        -- If coming from Sourcing, however, do not perform any conversion as
        -- Sourcing already populates converted value in the interface table.
        --
        IF ( p_interface_source_code IN ('SOURCING','CONSUMPTION_ADVICE') ) THEN

           l_progress:='030';
           PO_DEBUG.debug_stmt(l_log_head,l_progress,'p_interface_source_code IN (SOURCING, CONSUMPTION ADVICE) - no currency conversion performed');

        ELSE -- ( p_interface_source_code NOT IN ('SOURCING','CONSUMPTION_ADVICE') )

            -- Retrieve information from the backing Requisition Line.
            -- Bug 3794198: Join to financials_system_params_all and gl_sets_of_books to
            -- retrieve the value of l_req_ou_currency_code, the functional currency of ROU
            SELECT PRL.currency_code
            ,      GSB.currency_code
            ,      PRL.unit_price
            ,      nvl(PRL.currency_unit_price, PRL.unit_price)
            ,      PRL.amount
            ,      nvl(PRL.currency_amount, PRL.amount)
            INTO   l_req_currency_code
            ,      l_req_ou_currency_code
            ,      l_req_unit_price
            ,      l_req_currency_unit_price
            ,      l_req_amount
            ,      l_req_currency_amount
            FROM   po_requisition_lines_all PRL,
                   financials_system_params_all FSP,
                   gl_sets_of_books GSB
            WHERE  PRL.requisition_line_id = p_requisition_line_id
            AND    nvl(PRL.org_id, -99) = nvl(FSP.org_id, -99)
            AND    FSP.set_of_books_id = GSB.set_of_books_id;

            -- If the Req and PO Currency are the same, then simply take the
            -- currency_<unit_price/amount> from the Req to avoid having to
            -- perform another conversion.
            --
            -- Bug 3794198: If the ROU currency and PO Currency are the same, then
            -- simply take the unit_price/amount from the Req to avoid conversion
            --
            -- If the Req and PO Currency are different, then convert the
            -- unit_price/amount to the PO Currency using the specified rate.
            --
            IF ( l_req_currency_code = p_po_currency_code ) THEN

               l_progress:='050';
               PO_DEBUG.debug_stmt(l_log_head,l_progress,'Req and PO Currency equivalent (' || p_po_currency_code || ') - taking currency_unit_price/amount directly from the Req Line.');

                x_unit_price := l_req_currency_unit_price;
                x_amount     := l_req_currency_amount;
                -- bug 12719420
                x_base_unit_price := l_req_currency_unit_price;

            -- Bug 3794198 Start
            ELSIF (l_req_ou_currency_code = p_po_currency_code) THEN
               l_progress := '060';
               PO_DEBUG.debug_stmt(l_log_head,l_progress,'ROU Currency and PO Currency equivalent (' || p_po_currency_code || ') - taking unit_price/amount directory from the Req line');
               x_unit_price := l_req_unit_price;
               x_amount := l_req_amount;
               -- Bug 3794198 End
               -- Bug 3472140: Added NVL() around l_ext_precision
               x_base_unit_price := round(x_base_unit_price/p_rate, NVL(l_ext_precision, 15)); --bug 3401653


            ELSE

               l_progress:='070';
               PO_DEBUG.debug_stmt(l_log_head,l_progress,'Req (' || l_req_currency_code || ')/ ROU (' || l_req_ou_currency_code || ') and PO (' || p_po_currency_code || ') Currency different - performing currency conversion and rounding.');

                -- Bug 3472140: Added NVL() around l_ext_precision
                x_unit_price := round(l_req_unit_price/p_rate, NVL(l_ext_precision, 15));
                x_amount     := round(l_req_amount/p_rate, l_precision);
                -- Bug 3472140: Added NVL() around l_ext_precision
                x_base_unit_price := round(x_base_unit_price/p_rate, NVL(l_ext_precision, 15)); --bug 3401653


            END IF; -- currency_code
            -- Bug 3472140: Added NVL() around l_ext_precision
            --x_base_unit_price := round(x_base_unit_price/p_rate, NVL(l_ext_precision, 15)); --bug 3401653

        END IF; -- p_interface_source_code

    END IF; -- p_order_type_lookup_code

l_progress:='090'; PO_DEBUG.debug_end(l_log_head);

EXCEPTION

    WHEN OTHERS THEN
        PO_DEBUG.debug_exc ( p_log_head => l_log_head
                           , p_progress => l_progress);
        RAISE;

END do_currency_conversion;


/* ============================================================================
     NAME: SETUP_INTERFACE_TABLES
     DESC: Setup interface tables
     ARGS: x_interface_header_id IN number
     ALGR:

   ==========================================================================*/
-- <Complex Work R12>: Add new parameter, p_is_complex_work_po
PROCEDURE setup_interface_tables(
  x_interface_header_id  IN             NUMBER
, x_document_id          IN OUT NOCOPY  NUMBER
, p_is_complex_work_po   IN             BOOLEAN
)
IS

x_po_header_id number := null;
x_document_num po_headers.segment1%type:=null;
x_min_interface_line_id number:= null;
x_order_type_lookup_code varchar2(25) := null;
x_quotation_class_code varchar2(25) := null;
x_count_dist number;
x_item_id number := null;
x_vendor_id number := null;
x_vendor_site_id number := null;
x_rowid varchar2(25) := null;
x_organization_id number := null;
x_asl_id number := null;
x_vendor_product_num varchar2(240) := null;
x_purchasing_uom varchar2(240) := null;
x_pay_on_code varchar2(25) := null;
x_uom_convert          varchar2(2) := fnd_profile.value('PO_REQ_BPA_UOM_CONVERT');
x_old_document_num po_headers.segment1%type:=null; -- Bug 700513, lpo, 07/15/98

x_employee_id       number;
x_employee_name     varchar2(240);
x_requestor_location_id number;
x_location_code     varchar2(25);
x_employee_is_buyer boolean;
x_is_emp            boolean;
l_shipping_control  PO_RELEASES_ALL.shipping_control%TYPE;    -- <INBOUND LOGISTICS FPJ>

Cursor C is select pli.rowid,
       pli.item_id,
       phi.vendor_id,
       phi.vendor_site_id,
       pdi.destination_organization_id
      from   po_lines_interface pli,
       po_headers_interface phi,
       po_distributions_interface pdi
      where  phi.interface_header_id = x_interface_header_id
      and    phi.interface_header_id = pli.interface_header_id
      and    pdi.interface_distribution_id =
        (SELECT min(pdi2.interface_distribution_id)
         FROM   po_distributions_interface pdi2
               WHERE  pdi2.interface_line_id = pli.interface_line_id)
      and    pli.item_id is not null
      and    phi.vendor_id is not null
      and    pli.vendor_product_num is null;
--default distributions for all negotiation lines which are not backed by
--requisition lines.
Cursor C_default_distribution is
       SELECT pli.interface_header_id,
              pli.interface_line_id,
              pli.item_id,
              pli.line_type_id,
              pli.quantity,
              pli.amount,                                     -- <SERVICES FPJ>
              pli.category_id,
              pli.ship_to_location_id,
              pli.ship_to_organization_id,
              phi.vendor_id,
              phi.vendor_site_id,
              phi.agent_id,
              phi.rate,
              phi.rate_date,
              phi.document_subtype,
              pli.unit_price --<BUG 3407630>
         FROM po_lines_interface pli,
              po_headers_interface phi,
        po_line_types plt
        WHERE phi.interface_header_id = x_interface_header_id
          AND phi.interface_header_id = pli.interface_header_id
    AND pli.requisition_line_id is null
    AND plt.line_type_id = pli.line_type_id;

l_api_name CONSTANT VARCHAR2(30) := 'setup_interface_tables';
l_progress VARCHAR2(3) := '000';                --< Bug 3210331 >

-- bug# 3345108
-- secondary qty and secondary uom not getting populated for requisition lines
-- when requisition is created using IP.
-- default secondary qty and uom if
-- opm is installed.
-- destination org. is process and item is process and item is dual uom control.

-- bug# 3386353
-- Sourcing when doing overaward creates additional PO line with the extra qty.
-- If the line is OPM item with dual uom control then the shipment corresponding
-- to the extra PO line created by Sourcing does not have secondary uom and
-- secondary quantity with ship to organization as process org.
-- default secondary UOM and secondary quantity in such a case (non req backed lines)
-- the requisition line id would be null in po_lines_interface .
-- need to handle that situation in the default_opm_attributes cursor.
-- in case of non req back lines from sourcing , ship_to_organization_id is NULL.
-- so get it from distribution interface table.

-- <Complex Work R12 Start>
l_ship_to_org_id  HR_LOCATIONS_ALL.inventory_organization_id%TYPE;
-- <Complex Work R12 End>

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    UPDATE po_headers_interface
       SET process_code = 'IN PROCESS'
     WHERE interface_header_id = x_interface_header_id;

    l_progress := '010';

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Setup interface:   before select action type');
    END IF;

    l_progress := '020';
    -- Bug 700513, lpo, 07/15/98
    -- Get the document_num as well; needed for later on.

    SELECT min(action),
           min(group_code),
           min(document_num)
      INTO g_mode,
           g_group_code,
           x_old_document_num
      FROM po_headers_interface
     WHERE interface_header_id = x_interface_header_id;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Setup interface: mode is '||g_mode);
    END IF;

    /* Adding a requisition Line to a PO,Release,RFQ */
    IF(g_mode = 'ADD') THEN

       /*
       ** Find the po_header_id that matches the segment1 value that
       ** was loaded into the interface table.
       ** document_subtype in in interface table for an RFQ with be RFQ
       */

       IF (g_document_type = 'RFQ') THEN
         l_progress:='030';
         UPDATE po_headers_interface phi
            SET po_header_id =
              (SELECT ph.po_header_id
                 FROM po_headers_all ph  --<Shared Proc FPJ>
                WHERE 'RFQ' = ph.type_lookup_code
                  AND phi.document_num = ph.segment1
                  AND NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99))  --<Shared Proc FPJ>
             WHERE interface_header_id = x_interface_header_id;

       ELSE
         l_progress:='040';
         UPDATE po_headers_interface phi
            SET po_header_id =
              (SELECT ph.po_header_id
                 FROM po_headers_all ph  --<Shared Proc FPJ>
                WHERE decode(phi.document_subtype,
                             'RELEASE','BLANKET',
                             phi.document_subtype) = ph.type_lookup_code
                  AND phi.document_num = ph.segment1
                  AND NVL(org_id, -99) = NVL(g_purchasing_ou_id, -99))  --<Shared Proc FPJ>
          WHERE interface_header_id = x_interface_header_id;

            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'After update of headers interface');
            END IF;

       END IF;

       l_progress:='050';

       /*
       ** The values that we are updating in the interface table
       ** we need for defaulting to records at the lower levels.
       */

       /* Bug 482648 add currecny_code */

       /* Also get the pay_on_code from the document */

       UPDATE po_headers_interface phi
       SET (
               rate,
               rate_type_code,
               rate_date,
               currency_code) =
                 (SELECT
                         rate,
                         rate_type,
                         rate_date,
                         currency_code
                    FROM po_headers_all ph  --<Shared Proc FPJ>
                   WHERE ph.po_header_id = phi.po_header_id)
       WHERE interface_header_id = x_interface_header_id;

       IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
           PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                               p_token    => l_progress,
                               p_message  => 'After update of headers interfacei rate and etc.');
       END IF;

    /* Adding Req Line to New PO/RFQ */
    ELSIF(g_mode='NEW') THEN

      IF(g_document_subtype='STANDARD' or g_document_subtype='PLANNED'
         or g_document_type = 'RFQ'
         --<SOURCING TO PO FPH>
   or (g_document_subtype='BLANKET' and g_interface_source_code='SOURCING')) THEN
         l_progress:='060';

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'In std/planned/rfq');
        END IF;

         SELECT po_headers_s.nextval
           INTO x_po_header_id
           FROM sys.dual;


         /*
   ** Assign the document id to get passed back to the calling
   ** module.
   */
         x_document_id := x_po_header_id;

         l_progress:='070';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'After select Doc is '||x_po_header_id);
        END IF;

   /* If we are using automatic numbering, get segment1
   ** from the po_unique_identifier_control table.
   ** If we are using manual numbering, segment1
   ** should already be loaded into the po_headers_interface table.
   ** The checks to verify that a manual po number is unique
   ** is done on the client side.
   */
         /* ecso 4/23/98 emergency requisition enhancement
         ** For emergency requisitions, there is a reserved po num
         ** even though the document has not been created.
         ** Add the case where the document is NEW
         ** and there exists a document_num on po_headers_interface
         */
         --<SOURCING TO PO FPH>
   --modified the if condition to include PA
   IF (params.po_num_code='AUTOMATIC') AND
      (g_document_type in ('PO','PA')) THEN

            -- Bug 700513, lpo, 07/15/98
            -- Should check for x_old_document_num instead of
            -- interface.document_num which is not defined at this point.

            IF x_old_document_num IS NULL THEN
               x_document_num := '-'||x_po_header_id;  --Bug 1093645

/*Bug 1093645
  The following is commented as part of bug fix 958404.
  Prior to the fix we were locking the po_unique_identifier_control
  table in the beginning of the autocreate process which led to a
  deadlock situation.
  Fix has been made to assign a dummy (negative of po_header_id-The same
  logic followed in the enter po form) value now and then at the
  the end of the autocreate process lock the po_unique_identifier control
  table to fetch the next document number and assign it appropriately
  to avoid the deadlock.
*/

             END IF;

   ELSIF (params.user_defined_rfq_num_code='AUTOMATIC') AND
      (g_document_type = 'RFQ') THEN

             x_document_num := '-'||x_po_header_id;  --Bug 1093645

/*Bug 1093645
  The following is commented as part of bug fix 958404.
  Prior to the fix we were locking the po_unique_identifier_control
  table in the beginning of the autocreate process which led to a
  deadlock situation.
  Fix has been made to assign a dummy (negative of po_header_id-The same
  logic followed in the enter po form) value now and then at the
  the end of the autocreate process lock the po_unique_identifier control
  table to fetch the next document number and assign it appropriately
  to avoid the deadlock.
*/

   ELSE
              x_document_num := interface.document_num;

         END IF;

      ELSIF(g_document_subtype='RELEASE')THEN

          l_progress := '080';
          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
              PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                  p_token    => l_progress,
                                  p_message  => 'Setup: In release subtype');
          END IF;

  /* Bug 565530 ecso 10/23/97
  ** There can be multiple release records
  ** in the interface table.
  ** Add restriction by interface_header_id
  */

          SELECT ph.po_header_id,
                 ph.pay_on_code,
                 ph.shipping_control    -- <INBOUND LOGISTICS FPJ>
            INTO x_po_header_id,
                 x_pay_on_code,
                 l_shipping_control    -- <INBOUND LOGISTICS FPJ>
            FROM po_headers_all ph,  --<Shared Proc FPJ>
                 po_headers_interface phi
           WHERE phi.interface_header_id = x_interface_header_id
       AND ph.segment1 = phi.document_num
             AND ph.type_lookup_code='BLANKET'
             AND NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Setup: Header id of Blanket:  '||x_po_header_id);
        END IF;

      END IF;/* of standard/planned/release */

      l_progress:='090';

       SELECT min(interface_line_id)
        INTO x_min_interface_line_id
        FROM po_lines_interface pli,
             po_headers_interface phi
       WHERE phi.interface_header_id=pli.interface_header_id
         AND phi.interface_header_id = x_interface_header_id;

      l_progress:='100';
      --<SOURCING TO PO FPH>
      --modify the following update to default the values for the blanket also.
      --track 'PA' for the changes. Also please note that we have added deocode
      --for all the terms and conditions.Existing autocreate would not values
      --for different terms n condition columns and shipto billto columns in the
      --interface tables. But po_headers_interface table would contain values
      --for these columns when called from sourcing. So we are not defaulting
      --these values from params here but would do this in create_po procedure
      --in the order of interface,vendor,params.
      /* Bug 2816396
         Use the interface table value for pay_on_code when updating the table
      */
      IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'Sourcing to FPH-6 starts');
      END IF;

      UPDATE po_headers_interface phi
              SET (po_header_id,
                   last_update_date,
                   last_updated_by,
                   document_num,
             created_by,
                   last_update_login,
                   agent_id,
                   creation_date,
                   revision_num,
                   print_count,
                   closed_code,
                   frozen_flag,
                   vendor_id,
                   vendor_site_id,
                   ship_to_location_id,
                   bill_to_location_id,
                   terms_id,
                   freight_carrier,
                   fob,
                   pay_on_code,
                   freight_terms,
             confirming_order_flag,
                   currency_code,
             rate_type_code,
                   rate_date,
                   rate,
                   acceptance_required_flag,
                   firm_flag,
                   min_release_amount,
       document_subtype,
                   shipping_control    -- <INBOUND LOGISTICS FPJ>
                   ) =
            (SELECT x_po_header_id,
                    nvl(phi.last_update_date,sysdate),
                    nvl(phi.last_updated_by,who.user_id),
                    nvl(phi.document_num,x_document_num),
                    nvl(phi.created_by,who.user_id),
                    nvl(phi.last_update_login,who.login_id),
                    phi.agent_id ,
                    nvl(phi.creation_date,sysdate),
                    decode(g_document_type, 'PO', nvl(phi.revision_num,0),
                     'PA', nvl(phi.revision_num,0), phi.revision_num),
                    decode(g_document_type, 'PO', nvl(phi.print_count,0),
                    'PA', nvl(phi.print_count,0), phi.print_count),
                    decode(g_document_type, 'PO', nvl(phi.closed_code,'OPEN'),
                    'PA', nvl(phi.closed_code,'OPEN'), phi.closed_code),
                    decode(g_document_type, 'PO', nvl(phi.frozen_flag,'N'),
                    'PA', nvl(phi.frozen_flag,'N'), phi.frozen_flag),
                    phi.vendor_id,
                    phi.vendor_site_id,
                    decode(g_interface_source_code,'SOURCING',
         phi.ship_to_location_id,
         nvl(phi.ship_to_location_id,
        params.ship_to_location_id)),
                    decode(g_interface_source_code,'SOURCING',
         phi.bill_to_location_id,
                         nvl(phi.bill_To_Location_Id,
        params.bill_to_location_id)),
                    decode(g_interface_source_code,'SOURCING',phi.terms_id,
                           nvl(phi.terms_id,params.terms_id)),
                    decode(g_interface_source_code,'SOURCING',
               phi.freight_carrier,nvl(phi.freight_carrier,
              params.ship_via_lookup_code)),
                    decode(g_interface_source_code,'SOURCING',phi.fob,
         nvl(phi.fob,params.fob_lookup_code)),
                    decode(g_interface_source_code,'CONSUMPTION_ADVICE',phi.pay_on_code,
                           x_pay_on_code),
                    decode(g_interface_source_code,'SOURCING',phi.freight_terms,
                       nvl(phi.freight_terms,
        params.freight_terms_lookup_code)),
                    decode(g_document_type, 'PO',
      nvl(phi.confirming_order_flag,'N'),
      'PA',nvl(phi.confirming_order_flag,'N'),
      phi.confirming_order_flag),
                    phi.currency_code,
                    phi.rate_type_code,
                    --<SOURCING TO PO FPH>bug# 2430982
                    --phi.rate_date,
                    nvl(phi.rate_date,decode(g_interface_source_code,'SOURCING',decode(phi.rate_type_code,'User',sysdate),phi.rate_date)),
        --
                    phi.rate,
	-- bug 8802204: Checking the value of the acceptance_required_flag from po_headers_interface
                    decode(g_document_type, 'PO',
			nvl(phi.acceptance_required_flag,nvl(params.acceptance_required_flag,'N')),        /* Bug 7518967 : Default Acceptance Required Check ER: Geting default acceptance_required_flag */
			'PA',nvl(phi.acceptance_required_flag,nvl(params.acceptance_required_flag,'N')),
			params.acceptance_required_flag),
                    decode(g_document_type, 'PO',
      nvl(phi.firm_flag,'N'),
      'PA',nvl(phi.firm_flag,'N'),
      phi.firm_flag),
                    decode(g_document_type, 'PO',
      nvl(phi.min_release_amount,params.min_rel_amount),
      'PA',nvl(phi.min_release_amount,params.min_rel_amount),
      null),
        phi.document_subtype,
                    l_shipping_control    -- <INBOUND LOGISTICS FPJ>
               FROM po_headers_interface phi2,
                    po_lines_interface pli
              WHERE phi2.interface_header_id = phi.interface_header_id
                AND pli.interface_header_id=phi2.interface_header_id
                AND pli.interface_line_id = x_min_interface_line_id)
         WHERE interface_header_id = x_interface_header_id;

         IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
             PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                 p_token    => l_progress,
                                 p_message  => 'Sourcing to FPH-6 ends');
         END IF;

    END IF;/* of new/add */

    l_progress:='110';

    IF (g_document_subtype = 'RELEASE') THEN

       select po_header_id
       into   x_po_header_id
       from   po_headers_interface
       where  interface_header_id = x_interface_header_id;

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Setup interface:Before release update '||x_po_header_id);
        END IF;

       -- Bug 623679, lpo, 02/27/98
       -- Added a filter 'phi.interface_header_id = x_interface_header_id'
       -- for performance.
/*  Bug no:714303.
    The subquery(select stmt) was returning multiple rows
    while trying to create release using the manual option
    if there are more than one line for the same item
    in the referenced blanket agreement.
*/
/*Bug 971798
  If the blanket agrement has lines which has expired (new feauture in r11)
  ,then we should not be considering those lines while matching.
*/

    -- Added note_to_vendor - iali 08/26/99
/*Bug 1391523 . Added market price to the update  statement */

   /* Enh : 1660036 - Check the uom convert profile value. If it is set to yes
      we do not check if the Req uom is same as BPA uom. We create the release
      with the quantity and uom converted to the BPA uom */

 /* CONSIGNED FPI : For consumption PO we do not update the interface table with
   requisition values */
 IF g_interface_source_code <> 'CONSUMPTION_ADVICE' THEN

     -- Bug 2707576 - In 115.142, removed the IF statement and ELSE clause
     -- for x_uom_convert, since UOM checking is now handled in
     -- source_blanket_line.

       l_progress:='120';
       UPDATE po_lines_interface pli2
       SET (
            line_num,
            item_id,
            category_id,
            item_description,
            unit_of_measure,
            list_price_per_unit,
      market_price,
            base_unit_price,  -- <FPJ Advanced Price>
            unit_price,
            quantity,
            amount,                                           -- <SERVICES FPJ>
            taxable_flag,
            type_1099,
            negotiated_by_preparer_flag,
            closed_code,
            item_revision,
            un_number_id,
            hazard_class_id,
            -- contract_num,   -- <GC FPJ>
            line_type_id,
            vendor_product_num,
            qty_rcv_tolerance,
            over_tolerance_error_flag,
            firm_flag,
            min_release_amount,
            price_type,
            transaction_reason_code,
            line_location_id,
            need_by_date,
      --togeorge 09/27/2000
      --added note to receiver
      note_to_receiver,
            from_header_id,
            from_line_id,
      receipt_required_flag,
--DWR4{
            tax_status_indicator,
      note_to_vendor,
--DWR4}
            --togeorge 09/27/2000
      --added oke columns
      oke_contract_header_id,
      oke_contract_version_id,
-- start of bug 1548597
            secondary_unit_of_measure,
            secondary_quantity,
            preferred_grade,
-- end of bug 1548597
            drop_ship_flag,   --  <DropShip FPJ>
            vmi_flag  -- VMI FPH
      )=
       (SELECT
            nvl(pli.line_num, pol.line_num),
            nvl(pli.item_id,prl.item_id),
            nvl(pli.category_id,prl.category_id),
            nvl(pli.item_description,prl.item_description),
            nvl(pli.unit_of_measure,prl.unit_meas_lookup_code),
            pli.list_price_per_unit,
      pli.market_price,
            nvl(pli.base_unit_price,prl.base_unit_price),     -- <FPJ Advanced Price>
            nvl(pli.unit_price,prl.unit_price),
            nvl(pli.quantity,prl.quantity),
            nvl(pli.amount, prl.amount),                      -- <SERVICES FPJ>
            pli.taxable_flag,
            pli.type_1099,
            nvl(pli.negotiated_by_preparer_flag,'N'),
            nvl(pli.closed_code,'OPEN'),
            nvl(pli.item_revision,prl.item_revision),
            nvl(pli.un_number_id,prl.un_number_id),
            nvl(pli.hazard_class_id,prl.hazard_class_id),
            -- pli.contract_num,         -- <GC FPJ>
            nvl(pli.line_type_id,prl.line_type_id),
            nvl(pli.vendor_product_num,prl.suggested_vendor_product_code),
            pli.qty_rcv_tolerance,
            pli.over_tolerance_error_flag,
            nvl(pli.firm_flag,'N'),
            nvl(pli.min_release_amount,params.min_rel_amount),
            nvl(pli.price_type,params.price_type_lookup_code),
            nvl(pli.transaction_reason_code,prl.transaction_reason_code),
            pli.line_location_id,
            nvl(pli.need_by_date,prl.need_by_date),
      --togeorge 09/27/2000
      --added note to receiver
      nvl(pli.note_to_receiver,prl.note_to_receiver),
            pli.from_header_id,
            pli.from_line_id,
      nvl(pli.receipt_required_flag,plt.receiving_flag),
--DWR4{
            prl.tax_status_indicator,
      nvl(pli.note_to_vendor, prl.note_to_vendor),
--DWR4}
            --togeorge 09/27/2000
      --added oke columns
      nvl(pli.oke_contract_header_id,prl.oke_contract_header_id),
      nvl(pli.oke_contract_version_id,prl.oke_contract_version_id),
-- start of 1548597
            nvl(pli.secondary_unit_of_measure,prl.secondary_unit_of_measure),
            nvl(pli.secondary_quantity,prl.secondary_quantity),
            nvl(pli.preferred_grade,prl.preferred_grade),
-- end of 1548597
            prl.drop_ship_flag,   --  <DropShip FPJ>
            prl.vmi_flag  -- VMI FPH
       FROM po_lines_interface pli,
            po_headers_interface phi,
            po_requisition_lines_all prl,  --<Shared Proc FPJ>
            po_line_types plt,
            po_lines_all pol  --<Shared Proc FPJ>
      WHERE pli.interface_line_id = pli2.interface_line_id
        AND pli.interface_header_id = phi.interface_header_id
        AND phi.interface_header_id = x_interface_header_id
        AND pli.requisition_line_id = prl.requisition_line_id(+)
        AND plt.line_type_id = nvl(prl.line_type_id,pli.line_type_id)
  AND pol.po_header_id = x_po_header_id
-- 2082757 : new
        AND pol.line_num = po_interface_s.source_blanket_line(
                                x_po_header_id,
                                prl.requisition_line_id,
                                pli.line_num, -- Bug 2707576:
                                NVL(x_uom_convert,'N'),
                                g_purchasing_ou_id  --<Shared Proc FPJ>
                           )
       )

/* 2082757: Following logic is now coded in new function source_blanket_line
2082757 */
       WHERE pli2.interface_header_id = x_interface_header_id;

 /* CONSIGNED FPI Start */
 ELSE  -- CONSIGNED FPI
     l_progress:='130';
     -- bug 6636486 modified the below update sql to increase the performance.
     UPDATE po_lines_interface pli
      SET pli.po_header_id = x_po_header_id,
            pli.negotiated_by_preparer_flag = nvl(pli.negotiated_by_preparer_flag,'N'),
            pli.firm_flag = nvl(pli.firm_flag, 'N')
      WHERE pli.interface_header_id = x_interface_header_id;
 /*        SET (
            po_header_id,
            negotiated_by_preparer_flag,
            firm_flag
      )= */
       /*(SELECT
            x_po_header_id,
            nvl(pli.negotiated_by_preparer_flag,'N'),
            nvl(pli.firm_flag,'N')
       FROM po_lines_interface pli,
            po_headers_interface phi
      WHERE pli.interface_line_id = pli2.interface_line_id
        AND pli.interface_header_id = phi.interface_header_id
        AND phi.interface_header_id = x_interface_header_id);*/

 END IF;
 /* CONSIGNED FPI End */

       -- End of fix. Bug 623679, lpo, 02/27/98

        l_progress:='140';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Setup interface: After release update');
        END IF;

    ELSE  /* For PO/RFQ/PA */
    /*
    ** Note:  We do not multiple unit_price or quantity * rate
    ** in this statement. This logic is in the create_line stmt.
    */
    /* Bug 567402 ecso 11/15/97
    ** Get the receipt_required_flag from po_line_type table
    */

    -- Bug 623679, lpo, 02/27/98
    -- Added a filter 'phi.interface_header_id = x_interface_header_id'
    -- for performance.

    -- Bug 694504. frkhan 07/07/98. Removed decode for vendor_product_num so
    -- it is updated for RFQs also.

    -- Added note_to_vendor - iali 08/26/99
/*Bug 1391523 . Added market price to the update  statement */

    --Bug 13876074, copy supplier_part_auxid from po_lines_all line if available
    l_progress:='150';
    UPDATE po_lines_interface pli2
       SET (
            line_num,
            item_id,
            job_id,                                           -- <SERVICES FPJ>
            category_id,
            item_description,
            unit_of_measure,
            list_price_per_unit,
      market_price,
            base_unit_price,  -- <FPJ Advanced Price>
            unit_price,
            quantity,
            amount,                                           -- <SERVICES FPJ>
            taxable_flag,
            type_1099,
            negotiated_by_preparer_flag,
            closed_code,
            item_revision,
            un_number_id,
            hazard_class_id,
            -- contract_num,       -- <GC FPJ>
            line_type_id,
            vendor_product_num,
            qty_rcv_tolerance,
            over_tolerance_error_flag,
            firm_flag,
            min_release_amount,
            price_type,
            transaction_reason_code,
            line_location_id,
            need_by_date,
            ship_to_organization_id,
      note_to_receiver,
            from_header_id,
            from_line_id,
      receipt_required_flag,
            tax_status_indicator,
      note_to_vendor,
      oke_contract_header_id,
      oke_contract_version_id,
            secondary_unit_of_measure,
            secondary_quantity,
            preferred_grade,
            drop_ship_flag,   --  <DropShip FPJ>
            vmi_flag,      -- bug 2738820
            supplier_ref_number, --<CONFIG_ID FPJ>
            effective_date,                                   -- <SERVICES FPJ>
            expiration_date,                                  -- <SERVICES FPJ>
            contractor_first_name,                            -- <SERVICES FPJ>
            contractor_last_name                              -- <SERVICES FPJ>
            ,supplier_part_auxid                              --13876074
      )=
    (SELECT
            pli.line_num,
            nvl(pli.item_id,prl.item_id),
            nvl(pli.job_id, prl.job_id),                      -- <SERVICES FPJ>
            nvl(pli.category_id,prl.category_id),
            nvl(pli.item_description,prl.item_description),
            nvl(pli.unit_of_measure,prl.unit_meas_lookup_code),
            pli.list_price_per_unit,
      pli.market_price,
            nvl(pli.base_unit_price,prl.base_unit_price),     -- <FPJ Advanced Price>
            nvl(pli.unit_price,prl.unit_price),
            --<Bug 3306848 Its possible to have no backing req in which case
            --the quantity is taken from interface table.
            decode ( prl.order_type_lookup_code          -- <BUG 3275750, 3306848 START>
                   , 'FIXED PRICE' , NULL
                   , 'RATE'   ,      NULL
                   ,                 nvl(pli.quantity,prl.quantity)
                   ),                                    -- <BUG 3275750, 3306848 END>
            nvl(pli.amount, prl.amount),                      -- <SERVICES FPJ>
            pli.taxable_flag,
            pli.type_1099,
            nvl(pli.negotiated_by_preparer_flag,'N'),
            decode(g_document_type, 'PO',
    nvl(pli.closed_code,'OPEN'), null),
            nvl(pli.item_revision,prl.item_revision),
            nvl(pli.un_number_id,prl.un_number_id),
            nvl(pli.hazard_class_id,prl.hazard_class_id),
            -- pli.contract_num,       -- <GC FPJ>
            nvl(pli.line_type_id,prl.line_type_id),
            nvl(pli.vendor_product_num,prl.suggested_vendor_product_code),
            pli.qty_rcv_tolerance,
            pli.over_tolerance_error_flag,
            nvl(pli.firm_flag,'N'),
            --<SOURCING TO PO FPH>bug# 2438142 added min_release_amount for PA
            decode(g_document_type, 'PO',
    nvl(pli.min_release_amount,params.min_rel_amount),
            'PA',nvl(pli.min_release_amount,params.min_rel_amount),null),
            decode(g_document_type, 'PO',
            --Bug 14383317 start
            --nvl(pli.price_type,params.price_type_lookup_code),null),
			nvl(pol.price_type_lookup_code,params.price_type_lookup_code),null),
			--Bug 14383317 End
            nvl(pli.transaction_reason_code,prl.transaction_reason_code),
            pli.line_location_id,
            nvl(pli.need_by_date,prl.need_by_date),
            nvl(pli.ship_to_organization_id,prl.destination_organization_id),
      nvl(pli.note_to_receiver,prl.note_to_receiver),
            pli.from_header_id,
            pli.from_line_id,
      nvl(pli.receipt_required_flag,plt.receiving_flag),
            prl.tax_status_indicator,
      nvl(pli.note_to_vendor, prl.note_to_vendor),
            -- 2702892 Added the decode for consigned:
            decode(pli.consigned_flag,'Y',null,
        nvl(pli.oke_contract_header_id,prl.oke_contract_header_id)),
            decode(pli.consigned_flag,'Y',null,
        nvl(pli.oke_contract_version_id,prl.oke_contract_version_id)),
            nvl(pli.secondary_unit_of_measure,prl.secondary_unit_of_measure),
            nvl(pli.secondary_quantity,prl.secondary_quantity),
            nvl(pli.preferred_grade,prl.preferred_grade),
            prl.drop_ship_flag,   --  <DropShip FPJ>
            prl.vmi_flag,   -- bug 2738820
            prl.supplier_ref_number, --<CONFIG_ID FPJ>
            -- <SERVICES FPJ START>
            nvl(pli.effective_date, prl.assignment_start_date),
            nvl(pli.expiration_date, prl.assignment_end_date),
            nvl(pli.contractor_first_name, prl.candidate_first_name),
            nvl(pli.contractor_last_name, prl.candidate_last_name)
            -- <SERVICES FPJ END>
            ,pol.supplier_part_auxid       --13876074
       FROM po_lines_interface pli,
            po_headers_interface phi,
            po_requisition_lines_all prl,  --<Shared Proc FPJ>
            po_line_types plt
            ,po_lines_all pol              --13876074
      WHERE pli.interface_line_id = pli2.interface_line_id
        AND pli.interface_header_id = phi.interface_header_id
        AND phi.interface_header_id = x_interface_header_id
        AND pli.requisition_line_id = prl.requisition_line_id(+)
        AND pli.from_line_id = pol.po_line_id(+)    --13876074
        AND plt.line_type_id = nvl(prl.line_type_id,pli.line_type_id))
      WHERE pli2.interface_header_id = x_interface_header_id;

      -- End of fix. Bug 623679, lpo, 02/27/98

    END IF;

    l_progress:='160';

    /* RFQs do not have distributions , but we still
  do the insert.  We get the deliver to information
  from the distribution record. */


    IF (g_document_type in ('RFQ', 'PO')) THEN

        l_progress:='170';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Before insert into Distribution interface');
        END IF;

       INSERT INTO po_distributions_interface
          (interface_header_id,
           interface_line_id,
           interface_distribution_id,
           distribution_num,
           charge_account_id,
           set_of_books_id,
           quantity_ordered,
           amount_ordered,                                    -- <SERVICES FPJ>
           rate,
           rate_date,
           req_distribution_id,
           deliver_to_location_id,
           deliver_to_person_id,
           encumbered_flag,
     gl_encumbered_date,
           gl_encumbered_period_name,
           destination_type_code,
           destination_organization_id,
           destination_subinventory,
           budget_account_id,
           accrual_account_id,
           variance_account_id,

           --< Shared Proc FPJ Start >
           dest_charge_account_id,
           dest_variance_account_id,
           --< Shared Proc FPJ End >

           wip_entity_id,
           wip_line_id,
           wip_repetitive_schedule_id,
           wip_operation_seq_num,
           wip_resource_seq_num,
           bom_resource_id,
           prevent_encumbrance_flag,
           project_id,
           task_id,
           end_item_unit_number,
           expenditure_type,
           project_accounting_context,
           destination_context,
           expenditure_organization_id,
           expenditure_item_date,
--FRKHAN 12/8/98 copy recovery rate and tax amounts
          tax_recovery_override_flag, --<eTax Integration R12>
     recovery_rate,
     recoverable_tax,
     nonrecoverable_tax,
     -- OGM_0.0 change.
     award_id,
           --togeorge 09/27/2000
     --added oke columns
     oke_contract_line_id,
     oke_contract_deliverable_id
     )
       SELECT pli.interface_header_id,
           pli.interface_line_id,
           po_distributions_interface_s.nextval,
           prd.distribution_num,
           prd.code_combination_id,
           prd.set_of_books_id,
           prd.req_line_quantity,
           decode ( g_interface_source_code                    -- <BUG 3316071>
                  , 'SOURCING' , prd.req_line_amount * pli.amount/prl.amount
                  ,              prd.req_line_amount
                  ),
           phi.rate,
           phi.rate_date,
           prd.distribution_id,
           prl.deliver_to_location_id,
           prl.to_person_id,
           prd.encumbered_flag,
     prd.gl_encumbered_date,
           prd.gl_encumbered_period_name,
           prl.destination_type_code,
           prl.destination_organization_id,
           prl.destination_subinventory,
           prd.budget_account_id,
           prd.accrual_account_id,
           prd.variance_account_id,

           --< Shared Proc FPJ Start >
           -- For non SPS case (common case), set Destination Accounts to NULL
           NULL, -- dest_charge_account_id
           NULL, -- dest_variance_account_id
           --< Shared Proc FPJ End >

           prl.wip_entity_id,
           prl.wip_line_id,
           prl.wip_repetitive_schedule_id,
           prl.wip_operation_seq_num,
           prl.wip_resource_seq_num,
           prl.bom_resource_id,
           prd.prevent_encumbrance_flag,
           prd.project_id,
           prd.task_id,
           prd.end_item_unit_number,
           prd.expenditure_type,
           prd.project_accounting_context,
           prl.destination_context,
           prd.expenditure_organization_id,
           prd.expenditure_item_date,
     prd.tax_recovery_override_flag,     --<eTax Integration R12>
     prd.recovery_rate,
     prd.recoverable_tax,
     prd.nonrecoverable_tax,
     prd.award_id, -- OGM_0.0 change
           --togeorge 09/27/2000
     --added oke columns
           -- 2702892 Added the decode for consigned:
           decode(pli.consigned_flag,'Y',null,
       prd.oke_contract_line_id),
           decode(pli.consigned_flag,'Y',null,
       prd.oke_contract_deliverable_id)
         FROM po_requisition_lines_all prl,  --<Shared Proc FPJ>
           po_req_distributions_all prd,  --<Shared Proc FPJ>
           po_lines_interface pli,
           po_headers_interface phi
        WHERE prd.requisition_line_id = prl.requisition_line_id
          AND prl.requisition_line_id  = pli.requisition_line_id -- Bug:1563888
          AND pli.interface_header_id = phi.interface_header_id
          AND phi.interface_header_id = x_interface_header_id;

          SELECT count(*)
          INTO   x_count_dist
          FROM  po_distributions_interface
    WHERE interface_header_id = x_interface_header_id;

        l_progress:='180';
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Count from dist iterface is '||x_count_dist);
        END IF;

     END IF;

          --<SOURCING TO PO FPH START>
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Sourcing to FPH-7 starts');
        END IF;
    --default the distribution for non req backing negotiations.The above
    --insert only takes care of the interface lines which are backed by
    --requisitions.
    if g_interface_source_code='SOURCING' then

       IF (PO_LOG.d_stmt) THEN
         PO_LOG.stmt(g_log_head || l_api_name, 190, 'Defaulting dists interface for sourcing.');
       END IF;

          l_progress:='190';
          for i in c_default_distribution
        loop

         -- <Complex Work R12 Start>
         IF (PO_LOG.d_stmt) THEN
           PO_LOG.stmt(g_log_head || l_api_name, 190, 'i.interface_line_id', i.interface_line_id);
         END IF;


         IF (p_is_complex_work_po) THEN

           -- create complex work PO from sourcing

           IF (i.ship_to_organization_id IS NOT NULL) THEN

             l_ship_to_org_id := i.ship_to_organization_id;

           ELSE

             -- SQL WHAT: derive default ship_to_organization_id
             -- SQL WHY: the ship_to_organization is optional from sourcing
             BEGIN
               SELECT hrl.inventory_organization_id
                 INTO l_ship_to_org_id
                 FROM hr_locations_all hrl
                WHERE hrl.location_id = i.ship_to_location_id
                  AND hrl.ship_to_site_flag = 'Y';
             EXCEPTION
                WHEN no_data_found THEN
                  l_ship_to_org_id := NULL;
             END;

             l_ship_to_org_id := NVL(l_ship_to_org_id,
                                     params.inventory_organization_id);

           END IF;  -- IF i.ship_to_organization_id IS NOT NULL

           -- SQL WHAT: insert minimal data into po_distributions_interface
           -- SQL WHY: this is required because the global interface cursor
           -- joins to the distributions interface table and uses
           -- some of the following fields for defaulting purposes

           INSERT INTO po_distributions_interface(
             interface_header_id
           , interface_line_id
           , interface_distribution_id
           , destination_type_code
           , deliver_to_location_id
           , destination_organization_id
           ) VALUES (
             i.interface_header_id
           , i.interface_line_id
           , PO_DISTRIBUTIONS_INTERFACE_S.nextval
           , 'EXPENSE'
           , i.ship_to_location_id
           , l_ship_to_org_id
           );

           IF (PO_LOG.d_stmt) THEN
             PO_LOG.stmt(g_log_head || l_api_name, 190, 'Num rows inserted', SQL%ROWCOUNT);
           END IF;

         ELSE

           -- non-complex work po from sourcing

           po_negotiations_sv2.default_po_dist_interface(
              i.interface_header_id,
              i.interface_line_id,
              i.item_id,
              i.category_id,
              i.ship_to_organization_id,
              i.ship_to_location_id,
              null, --deliver_to_person_id
              params.sob_id,
              params.coa_id,
              i.line_type_id,
              i.quantity,
              i.amount,  -- <SERVICES FPJ>
              i.rate,
              i.rate_date,
              i.vendor_id,
              i.vendor_site_id,
              i.agent_id,
              nvl(params.po_encumbrance_flag, 'N'),
              NULL,
              i.document_subtype,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null,
              null, --project_accounting_context
              g_purchasing_ou_id, --< Shared Proc FPJ >
              i.unit_price  --<BUG 3407630>
              );
         END IF;  -- IF p_is_complex_work_po
         -- <Complex Work R12 End>

        end loop;
          end if;

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Sourcing to FPH-7 ends');
        END IF;
          --<SOURCING TO PO FPH END>


    /* If we do not have a supplier item number, get this
       information from the ASL */

    --<SOURCING TO PO FPH>
    --for blankets also
    IF (g_document_type in ('PO','PA')) THEN

    l_progress:='200';
  OPEN C;
  LOOP

      Fetch C into x_rowid,
         x_item_id,
         x_vendor_id,
         x_vendor_site_id,
         x_organization_id;
--added by jbalakri for 1754916
            x_asl_id:=NULL;
            x_vendor_product_num:=NULL;
            x_purchasing_uom:=NULL;
--end of add for 1754916.

        po_autosource_sv.get_asl_info(x_item_id,
     x_vendor_id,
     x_vendor_site_id,
     x_organization_id,
     x_asl_id,
     x_vendor_product_num,
     x_purchasing_uom);

      if (x_vendor_product_num is not null) then
          update po_lines_interface
          set    vendor_product_num = x_vendor_product_num
    where  rowid = x_rowid;

      end if;

      Exit when C%NOTFOUND;


  END LOOP;
  CLOSE C;

    END IF;

  l_progress:='210';
  --< Shared Proc FPJ Start >
  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                          p_token    => l_progress,
                          p_message  => 'Calling generate_shared_proc_accounts');
  END IF;

  -- <Complex Work R12 Start>: Shared proc. not supported with complex work
  IF (NOT p_is_complex_work_po) THEN
    generate_shared_proc_accounts(x_interface_header_id);
  END IF;
  -- <Complex Work R12 End>
  --< Shared Proc FPJ End >

  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
      PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     wrapup(x_interface_header_id);
     po_message_s.sql_error('SETUP INTERFACE TABLES',l_progress,sqlcode);
     raise;
END SETUP_INTERFACE_TABLES;


/* ============================================================================
     NAME: WRAPUP
     DESC: Wrapup
     ARGS: x_interface_header_id IN number
     ALGR:
   ==========================================================================*/
PROCEDURE wrapup(x_interface_header_id IN number) IS
BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||'wrapup');
    END IF;

   DELETE po_distributions_interface
   WHERE interface_header_id = x_interface_header_id;

   -- <SERVICES FPJ START>
   DELETE po_price_diff_interface
   WHERE  interface_header_id = x_interface_header_id;
   -- <SERVICES FPJ END>

   -- <Complex Work R12 Start>
   DELETE po_line_locations_interface
   WHERE interface_header_id = x_interface_header_id;
   -- <Complex Work R12 End>

   DELETE po_lines_interface
   WHERE interface_header_id = x_interface_header_id;


   DELETE po_headers_interface
   WHERE interface_header_id = x_interface_header_id;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||'wrapup');
    END IF;
END wrapup;

/* ============================================================================
     NAME: GROUP_INTERFACE_LINES
     DESC: Group interface lines
     ARGS: x_interface_header_id IN number
     ALGR:
   ==========================================================================*/
-- <Complex Work R12>: Added parameter p_is_complex_work_po

PROCEDURE group_interface_lines(
  x_interface_header_id    IN number
, p_is_complex_work_po     IN BOOLEAN
, p_group_shipments        IN VARCHAR2 DEFAULT NULL   --<Bug 14608120 Autocreate GE ER>
)
IS
x_line_num number;
x_shipment_num number;
x_document_num varchar2(30);
x_release_num number;
x_document_type_code varchar2(25);
x_document_subtype varchar2(25);
x_action varchar2(25);
x_requisition_line_id number;
x_interface_line_num number;
x_item_id number;
x_item_description varchar2(240);    -- bgu, Mar. 19, 1999
x_line_type_id number;
x_item_revision varchar2(3);
x_unit_meas_lookup_code varchar2(25);
x_transaction_reason_code varchar2(25);
x_need_by_date date;
--togeorge 09/27/2000
--added note to receiver and oke variables.
x_note_to_receiver po_requisition_lines_all.note_to_receiver%type;
x_oke_contract_header_id number;
x_oke_contract_version_id number;
x_vendor_product_num varchar2(30);  --Bug# 1763933
x_deliver_to_location_id number;
x_destination_org_id number;
x_ship_to_location_id number;
x_po_line_num number;
x_po_line_id number;
x_po_shipment_num number;
x_num_interface_lines number := 1; /* used for incrementing po line number */
x_int_shipment_num number; /* maximum shipment num in interface table */
x_int_line_num number; /* maximum line num in interface table */
-- start of 1548597
x_secondary_unit_of_measure  MTL_UNITS_OF_MEASURE.UNIT_OF_MEASURE%TYPE;
x_preferred_grade            MTL_GRADES.GRADE_CODE%TYPE; --<INVCONV R12> increased to 150
-- end of 1548597
/* Bug 1949160. x_count variable is used as counter to increment in a
    loop */
x_count number := 0;
--<SOURCING TO PO FPH START>
x_bid_number number;
x_bid_line_number number;
x_row_id  varchar2(25) := null;
--<SOURCING TO PO FPH END>

x_vmi_flag       PO_LINES_INTERFACE.VMI_FLAG%TYPE;  /* VMI FPH */
x_drop_ship_flag PO_LINES_INTERFACE.DROP_SHIP_FLAG%TYPE;  --<DropShip FPJ>

x_source_doc_id         number;   -- FPI GA
x_source_doc_line_id    number;   -- FPI GA

x_consigned_flag        VARCHAR2(1) := 'N';  --CONSIGNED FPI
x_create_new_line       VARCHAR2(1) := 'N';   --GA FPI
l_supplier_ref_number   PO_LINES_INTERFACE.supplier_ref_number%TYPE; --<CONFIG_ID FPJ>

l_contract_id PO_LINES_ALL.contract_id%TYPE;       -- <GC FPJ>

/* Bug 3201308 start */
 l_needby_prf  varchar2(1);
 l_shipto_prf  varchar2(1);
/* Bug 3201308 end */

l_api_name CONSTANT VARCHAR2(30) := 'group_interface_lines';

/*
** Order by interface_line_id.
** The front end will always load the lines in the correct order.
** The front end will load it either by (item_id, unit_price,
** need_by_date, requisition_line_id) or by the order in which
** the user selects.
** DEBUG.  For now from the front end the users will not be able to
** determine the order in which they want to lines to be placed.
** removed order by interface_line_id and replaced it with the
** above order by.
*/
/** bgu, Mar. 19, 1999
 *  BUG 853749
 *  For one time item, item description will distinguish items.
 */

/* Bug 1949160. Created a cursor to retrieve requisition line-id */
CURSOR interface_lines_temp IS
  SELECT pli.requisition_line_id
  FROM po_lines_interface pli
  WHERE pli.interface_header_id = x_interface_header_id
-- bug 4000047: start: requisition lines should be entered
-- into PO the same order they appear in the requisition
  ORDER BY pli.requisition_line_id;
-- bug 4000047: end

CURSOR interface_lines IS
   SELECT pli.action,
          pli.requisition_line_id,
          pli.line_num,
          pli.item_id,
          pli.item_description,     -- bgu, Mar. 19, 1999
          pli.line_type_id,
          pli.item_revision,
          pli.unit_of_measure,
          pli.transaction_reason_code,
          pli.need_by_date,
          pli.note_to_receiver,
          pli.oke_contract_header_id,
          pli.oke_contract_version_id,
          pli.vendor_product_num,   -- Bug# 1763933
          pld.deliver_to_location_id,
          pld.destination_organization_id,
          pli.secondary_unit_of_measure,
          pli.preferred_grade,
          pli.bid_number,
          pli.bid_line_number,
          pli.rowid,
          pli.vmi_flag,   --  VMI FPH
          pli.drop_ship_flag,   --  <DropShip FPJ>
          pli.from_header_id,   -- FPI GA
          pli.from_line_id,      -- FPI GA
          pli.consigned_flag,    -- CONSIGNED FPI
          pli.contract_id,       -- <GC FPJ>
          pli.supplier_ref_number --<CONFIG_ID FPJ>
   FROM po_lines_interface pli,
        po_distributions_interface pld
   WHERE pli.interface_header_id=x_interface_header_id
   AND   pli.interface_line_id=pld.interface_line_id
   AND   pld.interface_distribution_id =
            ( SELECT min(pdi2.interface_distribution_id)
              FROM   po_distributions_interface pdi2
              WHERE  pdi2.interface_line_id = pli.interface_line_id)
   ORDER BY pli.item_id,
            pli.item_description,
            pli.unit_price,
            pli.need_by_date,
            pli.requisition_line_id;

  l_progress VARCHAR2(3) := '000';                  --< Bug 3210331 >

  --<INVCONV R12 START>
  l_grade_control_flag  MTL_SYSTEM_ITEMS.GRADE_CONTROL_FLAG%TYPE;
  l_line_grade    MTL_GRADES.GRADE_CODE%TYPE;
  --<INVCONV R12 END>

  l_max_iface_line_num   NUMBER;        -- <Complex Work R12>


BEGIN

  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
      PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
  END IF;

  -- Bug 3201308 start
  -- Get the profile option values to determine grouping criteria
  l_needby_prf := fnd_profile.value('PO_NEED_BY_GROUPING');
  l_shipto_prf := fnd_profile.value('PO_SHIPTO_GROUPING');
  l_progress := '010';
  -- Bug 3201308 end


  SELECT phi.document_num,
         phi.document_type_code,
         phi.document_subtype,
         phi.release_num
  INTO x_document_num,
       x_document_type_code,
       x_document_subtype,
       x_release_num
  FROM po_headers_interface phi
  WHERE phi.interface_header_id = x_interface_header_id;

  IF (g_document_type = 'RFQ') THEN
    x_document_subtype := 'RFQ';
  END IF;

  l_progress := '020';
  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                          p_token    => l_progress,
                          p_message  => 'Mode is:'|| g_mode);
  END IF;

  --<SOURCING TO PO FPH>
  --modify to group blanket lines also

  IF (x_document_type_code IN ('PO', 'PA', 'RFQ')) THEN

    IF (g_group_code = 'REQUISITION') THEN

      IF (g_mode = 'NEW') THEN


        -- Create a new PO/Release with Req. lines in
        -- the same order as on the requisition.
        -- The interface table will hold the requisition line id
        -- that we need to get the req line number from.
        -- We need to update the shipment number to 1.

        l_progress := '030';


        IF ((x_document_subtype IN ('STANDARD', 'PLANNED')) OR
            (g_document_type = 'RFQ'))
        THEN

          -- Bug 3825483
          -- For Standard and Planned POs and RFQs, the line number
          -- will be the same as the req line number if the profile
          -- is set to 'Y' otherwise use sequential numbers

          IF (FND_PROFILE.VALUE('PO_USE_REQ_NUM_IN_AUTOCREATE') = 'Y') THEN

            -- use requisition numbers

            l_progress:='035';

            UPDATE po_lines_interface pli
            SET pli.shipment_num = 1,
                pli.line_num =
                   (
                     SELECT prl.line_num
                     FROM   po_requisition_lines_all prl  -- Bug 3903445
                     WHERE  prl.requisition_line_id = pli.requisition_line_id
                   )
            WHERE pli.interface_header_id = x_interface_header_id
            AND   pli.line_num is null
            AND   pli.shipment_num is null;

          ELSE

            -- use sequential numbers

            l_progress := '040';

            OPEN interface_lines_temp;
            LOOP

              x_count := x_count + 1;

              FETCH interface_lines_temp into x_requisition_line_id;
              EXIT WHEN interface_lines_temp%NOTFOUND;

              l_progress := '050';

              UPDATE po_lines_interface pli
              SET pli.line_num = x_count,
                  pli.shipment_num = 1
              WHERE pli.requisition_line_id = x_requisition_line_id
              AND   pli.interface_header_id = x_interface_header_id
              AND   pli.line_num IS NULL
              AND   pli.shipment_num IS NULL;

            END LOOP;

            CLOSE interface_lines_temp;

          END IF;  -- if fnd_profile.value(PO_USE_REQ_NUM...) = 'Y'

        ELSE

          -- Document is release case

          l_progress:='060';

          OPEN interface_lines;
          LOOP

            l_progress:='070';

            FETCH interface_lines INTO
              x_action,
              x_requisition_line_id,
              x_interface_line_num,
              x_item_id,
              x_item_description,        -- bgu, Mar. 19, 1999
              x_line_type_id,
              x_item_revision,
              x_unit_meas_lookup_code,
              x_transaction_reason_code,
              x_need_by_date,
              x_note_to_receiver,
              x_oke_contract_header_id,
              x_oke_contract_version_id,
              x_vendor_product_num,      --Bug 1763933
              x_deliver_to_location_id,
              x_destination_org_id,
              x_secondary_unit_of_measure,
              x_preferred_grade,
              x_bid_number,
              x_bid_line_number,
              x_row_id,
              x_vmi_flag,               --  VMI FPH
              x_drop_ship_flag,         --  <DropShip FPJ>
              x_source_doc_id ,         -- FPI GA
              x_source_doc_line_id,     -- FPI GA
              x_consigned_flag,         -- CONSIGNED FPI
              l_contract_id,            -- <GC FPJ>
              l_supplier_ref_number    --<CONFIG_ID FPJ>
            ;

            EXIT WHEN interface_lines%NOTFOUND;

            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_deliver_to_location_id',
                                     p_value    => x_deliver_to_location_id);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_destination_org_id',
                                     p_value    => x_destination_org_id);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_need_by_date',
                                     p_value    => x_need_by_date);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_unit_meas_lookup_code',
                                     p_value    => x_unit_meas_lookup_code);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_transaction_reason_code',
                                     p_value    => x_transaction_reason_code);
            END IF;  -- debug logging

            -- The user did not specify the line that they want the
            -- requisition line to be associated with.  We need
            -- to find a requisition line that matches it.
            -- Find a line that matches, if one does not match, skip
            -- the record.  If one does match, update the interface
            -- table with the correct line number.

            IF (x_action is NULL) THEN

              l_progress := '080';

              BEGIN

                -- bug# 2564767: don't compare secondary uom

                SELECT MIN(pli.line_num),
                       pli.po_line_id
                INTO x_po_line_num,
                     x_po_line_id
                FROM po_lines_interface pli
                WHERE pli.interface_header_id = x_interface_header_id
                AND pli.line_num IS NOT NULL
                AND pli.line_type_id = x_line_type_id
                AND NVL(pli.item_id, -1) = NVL(x_item_id, -1)
                AND NVL(pli.item_description, 'null' ) =
                                                 NVL(x_item_description,'null')
                AND (((pli.item_revision IS NULL) AND (x_item_revision IS NULL))
                      OR (pli.item_revision = x_item_revision))
                AND pli.unit_of_measure = x_unit_meas_lookup_code
                AND ( pli.transaction_reason_code IS NULL
                      OR pli.transaction_reason_code =
                           NVL(x_transaction_reason_code,
                                  pli.transaction_reason_code))

                -- togeorge 09/27/2000
                -- added conditions to compare oke contract num and rev.
                -- line num is different if contract info is diff. on the
                -- same item.
                AND   NVL(pli.oke_contract_header_id,-1) =
                                               NVL(x_oke_contract_header_id,-1)
                AND   NVL(pli.oke_contract_version_id,-1) =
                                               NVL(x_oke_contract_version_id,-1)
                GROUP BY pli.po_line_id;

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF g_debug_stmt THEN
                    PO_DEBUG.debug_stmt(
                      p_log_head => g_log_head||l_api_name,
                      p_token    => l_progress,
                      p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
                    x_po_line_num := -1;
              END;

              l_progress := '090';

              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                   PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                       p_token    => l_progress,
                                       p_message  => 'Line_num is :'|| x_po_line_num);
                   PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                       p_token    => l_progress,
                                       p_message  => 'Group_interface_lines progress is :'|| l_progress);
              END IF;  -- debug logging

              UPDATE po_lines_interface pli
              SET pli.line_num = x_po_line_num
              WHERE pli.interface_header_id = x_interface_header_id
              AND pli.requisition_line_id = x_requisition_line_id;

              x_interface_line_num := x_po_line_num;

            END IF;  -- if x_action is NULL

          END LOOP;
          CLOSE interface_lines;

          -- Bug 3825483
          -- For Releases, the shipment number will be the same as
          -- the req line number if the profile is set, otherwise
          -- sequential numbers are used

          IF (FND_PROFILE.VALUE('PO_USE_REQ_NUM_IN_AUTOCREATE')='Y') THEN

            -- use requisition numbers

            l_progress := '100';

            UPDATE po_lines_interface pli
            SET pli.shipment_num =
                  ( SELECT prl.line_num
                    FROM po_requisition_lines_all prl
                    WHERE prl.requisition_line_id = pli.requisition_line_id )
            WHERE pli.interface_header_id = x_interface_header_id
            AND pli.shipment_num IS NULL;

          ELSE

            -- use sequential numbers

            OPEN interface_lines_temp;
            LOOP

              x_count := x_count + 1;

              FETCH interface_lines_temp INTO x_requisition_line_id;
              EXIT WHEN interface_lines_temp%NOTFOUND;

              l_progress := '110';

              UPDATE po_lines_interface pli
              SET pli.shipment_num = x_count
              WHERE pli.requisition_line_id = x_requisition_line_id
              AND pli.interface_header_id = x_interface_header_id
              AND pli.shipment_num IS NULL;

            END LOOP;
            CLOSE interface_lines_temp;

          END IF;  -- if fnd_profile.value(PO_USE_REQ_NUM...) = 'Y'

        END IF;  -- release vs. non release case

      ELSE

        -- mode = 'ADD'
        -- add to a po/release with the same order as on the req.

        IF ((x_document_subtype IN ('STANDARD', 'PLANNED'))
           OR (g_document_type = 'RFQ'))
        THEN

          -- The inteface table will hold the requisition line id that we
          -- will use to get the line number.  Select the maximum line number
          -- that exists on the purchase order.  Update the line number in
          -- the interface talbe to be the req. line number + max po line num.
          -- Shipment num should be 1.

          l_progress:='120';

          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                    p_token    => l_progress,
                                    p_message  => 'Group_interface_lines: mode is :'|| g_mode);
          END IF;

          SELECT NVL(max(pl.line_num),0)
          INTO x_line_num
          FROM po_headers_all ph,
               po_lines_all pl
          WHERE pl.po_header_id = ph.po_header_id
          AND ph.segment1 = x_document_num
          AND ph.type_lookup_code =
                DECODE(g_document_type, 'RFQ', g_document_type, x_document_subtype)
          AND NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99);

          l_progress:='130';

          OPEN interface_lines_temp;
          LOOP

            l_progress := '140';
            x_count := x_count + 1;

            FETCH interface_lines_temp INTO x_requisition_line_id;
            EXIT WHEN interface_lines_temp%NOTFOUND;

            l_progress := '150';

            UPDATE po_lines_interface pli
            SET pli.line_num = x_line_num + x_count,
                pli.shipment_num = 1
            WHERE pli.requisition_line_id = x_requisition_line_id
            AND pli.interface_header_id = x_interface_header_id
            AND pli.line_num IS NULL
            AND pli.shipment_num IS NULL;

          END LOOP;
          CLOSE interface_lines_temp;

        ELSE

          -- Document is release case

          l_progress:='160';
          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                          p_token    => l_progress,
                                          p_message  => 'Before opening interface_lines cursor');
          END IF;

          OPEN interface_lines;
          LOOP

            l_progress:='170';

            FETCH interface_lines into
              x_action,
              x_requisition_line_id,
              x_interface_line_num,
              x_item_id,
              x_item_description,     -- bgu, Mar. 19, 1999
              x_line_type_id,
              x_item_revision,
              x_unit_meas_lookup_code,
              x_transaction_reason_code,
              x_need_by_date,
              x_note_to_receiver,
              x_oke_contract_header_id,
              x_oke_contract_version_id,
              x_vendor_product_num,  --Bug# 1763933
              x_deliver_to_location_id,
              x_destination_org_id,
              x_secondary_unit_of_measure,
              x_preferred_grade,
              x_bid_number,
              x_bid_line_number,
              x_row_id,
              x_vmi_flag,              -- VMI FPH
              x_drop_ship_flag,        --  <DropShip FPJ>
              x_source_doc_id ,        -- FPI GA
              x_source_doc_line_id,    -- FPI GA
              x_consigned_flag,        -- CONSIGNED FPI
              l_contract_id,           -- GC FPJ
              l_supplier_ref_number    --<CONFIG_ID FPJ>
            ;

            EXIT WHEN interface_lines%NOTFOUND;

            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_deliver_to_location_id',
                                     p_value    => x_deliver_to_location_id);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_destination_org_id',
                                     p_value    => x_destination_org_id);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_need_by_date',
                                     p_value    => x_need_by_date);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_unit_meas_lookup_code',
                                     p_value    => x_unit_meas_lookup_code);
                  PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                     p_progress => l_progress,
                                     p_name     => 'x_transaction_reason_code',
                                     p_value    => x_transaction_reason_code);
            END IF;

            -- The user did not specify the line that they want the
            -- requisition line to be associated with.  We need
            -- to find a requisition line that matches it.
            -- Find a line that matches, if one does not match, skip
            -- the record.  If one does match, update the interface
            -- table with the correct line number.

            IF (x_action is NULL) THEN

              l_progress := '180';

              BEGIN

                -- bug# 2564767: don't compare secondary uom

                SELECT MIN(pli.line_num),
                       pli.po_line_id
                INTO x_po_line_num,
                     x_po_line_id
                FROM po_lines_interface pli
                WHERE pli.interface_header_id = x_interface_header_id
                AND pli.line_num IS NOT NULL
                AND pli.line_type_id = x_line_type_id
                AND NVL(pli.item_id, -1) = NVL(x_item_id, -1)
                AND NVL(pli.item_description, 'null' ) =
                                                 NVL(x_item_description,'null')
                AND (((pli.item_revision IS NULL) AND (x_item_revision IS NULL))
                      OR (pli.item_revision = x_item_revision))
                AND pli.unit_of_measure = x_unit_meas_lookup_code
                AND ( pli.transaction_reason_code IS NULL
                      OR pli.transaction_reason_code =
                           NVL(x_transaction_reason_code,
                                  pli.transaction_reason_code))

                -- togeorge 09/27/2000
                -- added conditions to compare oke contract num and rev.
                -- line num is different if contract info is diff. on the
                -- same item.
                AND   NVL(pli.oke_contract_header_id,-1) =
                                               NVL(x_oke_contract_header_id,-1)
                AND   NVL(pli.oke_contract_version_id,-1) =
                                               NVL(x_oke_contract_version_id,-1)
                GROUP BY pli.po_line_id;

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF g_debug_stmt THEN
                    PO_DEBUG.debug_stmt(
                      p_log_head => g_log_head||l_api_name,
                      p_token    => l_progress,
                      p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                    END IF;
                    x_po_line_num := -1;
              END;

              l_progress := '190';

              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'Group_interface_lines: Line_num is :'|| x_po_line_num);
              END IF;

              UPDATE po_lines_interface pli
              SET pli.line_num = x_po_line_num
              WHERE pli.interface_header_id = x_interface_header_id
              AND pli.requisition_line_id = x_requisition_line_id;

              x_interface_line_num := x_po_line_num;

            END IF;  -- if x_action is null

          END LOOP;
          CLOSE interface_lines;

          -- Select the maxmimum shipment number that exists on the
          -- release and update the shipment number in the interface
          -- table to be the requisition line number + this max

          l_progress:='200';
          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                      PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                          p_token    => l_progress,
                                          p_message  => 'Group_interface_lines: before select max ship num');
          END IF;

          SELECT nvl(max(poll.shipment_num),0)
          INTO x_shipment_num
          FROM po_headers_all ph,
               po_line_locations_all poll,
               po_releases_all pr
          WHERE ph.po_header_id = poll.po_header_id
          AND ph.segment1 = x_document_num
          AND pr.po_header_id = ph.po_header_id
          AND pr.release_num = x_release_num
          AND ph.type_lookup_code = 'BLANKET'
          AND poll.po_release_id = pr.po_release_id
          AND NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
          AND NVL(pr.org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

          l_progress:='210';
          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                 PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                     p_token    => l_progress,
                                     p_message  => 'Group_interface_lines: after select max ship num');
          END IF;

          -- Bug 2841716 Start
          -- Prior to this fix, for Releases, the shipment number was
          -- derived by adding requisition line number to the current
          -- maximum shipment number.  Due to this shipment numbers
          -- were getting skipped. Hence commented the following update
          -- statement and now updating the po_lines_interface in a loop using
          -- a cursor.

          OPEN interface_lines_temp;
          LOOP

            x_count := x_count + 1;
            FETCH interface_lines_temp INTO x_requisition_line_id;
            EXIT WHEN interface_lines_temp%NOTFOUND;

            l_progress := '220';

            UPDATE po_lines_interface pli
            SET pli.shipment_num = x_shipment_num + x_count
            WHERE pli.requisition_line_id = x_requisition_line_id
            AND pli.interface_header_id = x_interface_header_id
            AND pli.line_num IS NOT NULL
            AND pli.shipment_num IS NULL;

          END LOOP;
          CLOSE interface_lines_temp;

          -- Bug 2841716 End

        END IF;  -- doc is not release / release

      END IF;  -- mode is NEW/ADD

    ELSE

      -- group code is DEFAULT

      IF ((x_document_subtype IN ('STANDARD', 'PLANNED', 'BLANKET')) OR
           (g_document_type = 'RFQ'))
      THEN

        l_progress := '230';

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                  PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                      p_token    => l_progress,
                                      p_message  => 'Before open interface: Grouping is default');
        END IF;

        -- <Complex Work R12 Start>
        -- Get maximum line number in interface table, to be used later

        SELECT NVL(max(pli.line_num), 0)
        INTO l_max_iface_line_num
        FROM po_lines_interface pli
        WHERE pli.interface_header_id = x_interface_header_id;

        -- <Complex Work R12 End>

        OPEN interface_lines;
        LOOP

          l_progress := '240';
          x_po_line_id := NULL;
          x_po_line_num := NULL;

          FETCH interface_lines INTO
            x_action,
            x_requisition_line_id,
            x_interface_line_num,
            x_item_id,
            x_item_description,     -- bgu, Mar. 19, 1999
            x_line_type_id,
            x_item_revision,
            x_unit_meas_lookup_code,
            x_transaction_reason_code,
            x_need_by_date,
            x_note_to_receiver,
            x_oke_contract_header_id,
            x_oke_contract_version_id,
            x_vendor_product_num, --Bug# 1763933
            x_deliver_to_location_id,
            x_destination_org_id,
            x_secondary_unit_of_measure,
            x_preferred_grade,
            x_bid_number,
            x_bid_line_number,
            x_row_id,
            x_vmi_flag,  -- VMI FPH
            x_drop_ship_flag,   --  <DropShip FPJ>
            x_source_doc_id ,        -- FPI GA
            x_source_doc_line_id ,    -- FPI GA
            x_consigned_flag,         -- CONSIGNED FPI
            l_contract_id,            -- <GC FPJ>
            l_supplier_ref_number    --<CONFIG_ID FPJ>
          ;

	  x_po_line_num := x_interface_line_num; --bug 16183038

          EXIT WHEN interface_lines%NOTFOUND;

          -- <Complex Work R12 Start>: Do not group from sourcing

          IF (p_is_complex_work_po) THEN

            -- for complex work, we do not want to group lines.
            -- for complex PO's directly from requisitions, the group code
            -- will be set to REQUISITION and so lines will not be grouped.
            -- when coming from sourcing, however, the group type is set
            -- to DEFAULT.

            -- Do not group; simply add 1 to each successive interface line

            UPDATE po_lines_interface pli
            SET pli.line_num = l_max_iface_line_num + 1
            WHERE pli.rowid = x_row_id
            AND pli.line_num IS NULL;

            IF (SQL%ROWCOUNT > 0) THEN
              l_max_iface_line_num := l_max_iface_line_num + 1;
            END IF;

          -- <Complex Work R12 End>

          ELSIF (x_action = 'NEW') THEN

            -- line number should be loaded into the interface.  In general,
            -- the shipment number should be equal to 1.  The only time it
            -- will not be is if the user attempts to place two or more
            -- req lines to the same po line and the shipments are identical.

            l_progress:='250';
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'Before get_shipment_num');
            END IF;

            get_shipment_num(
              x_need_by_date,
              x_deliver_to_location_id,
              x_destination_org_id,
              x_po_line_id,
              x_po_line_num,
              x_requisition_line_id,
              x_interface_header_id,
              x_po_shipment_num,
              x_note_to_receiver,
              x_preferred_grade,
              NULL,  -- VMI FPH
              x_consigned_flag,
              x_drop_ship_flag,     --  <DropShip FPJ>
              x_create_new_line,
			  p_group_shipments --<Bug 14608120 Autocreate GE ER>
			  );   -- FPI GA

            x_po_line_num := x_interface_line_num;

            l_progress := '260';

            update_shipment(
              x_interface_header_id,
              x_po_shipment_num,
              x_po_line_num,
              x_requisition_line_id,
              x_po_line_id,
              x_document_num,
              x_release_num,
              x_create_new_line);  -- FPI GA

          ELSIF (x_action = 'ADD') THEN

            -- user wants to add a requisition line to a particular PO line.
            -- check if a shipment exists that we can add to, otherwise
            -- get the next highest shipment number.

            l_progress:='270';
            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'x_action = '||x_action);
            END IF;

            -- Bug 594843: We need to retrieve the po_line_id for the
            -- line the user picked in the manual build process.
            -- Otherwise we will not be able the shipments
            -- Bug 599307: Added an AND condition to match_type_lookup_code
            -- Bug 1672940: Passing the value of line_num in x_po_line_num

            IF ((x_interface_line_num IS NOT NULL) AND
                  (x_document_num IS NOT NULL))
            THEN

              l_progress := '280';

              BEGIN

                SELECT pol.po_line_id,
                       pol.line_num
                INTO x_po_line_id,
                     x_po_line_num
                FROM po_lines_all pol,
                     po_headers_all poh
                WHERE poh.segment1 = x_document_num
                AND pol.line_num = x_interface_line_num
                AND poh.type_lookup_code =
                      DECODE(g_document_type, 'RFQ', g_document_type,x_document_subtype)
                AND poh.po_header_id = pol.po_header_id
                AND NVL(poh.org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

                -- Bug 2708776
                -- In the manual option when a Req. Line is added to the PO
                -- and PO has the same Item, the PO Line is matched and
                -- the line num is defaulted to the Po Line matched in the PO.
                -- If we change the line num defaulted and add a new line to
                -- the PO the shipment# was not populated when the PO was
                -- created. The is because we assume that the line_num
                -- populated will always exist in the PO, which is wrong.
                -- Handling the exception for NO_DATA_FOUND will resolve the
                -- Issue

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                                  PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                      p_token    => l_progress,
                                                      p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                  END IF;
                WHEN others THEN
                  IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                                  PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                                     p_progress => l_progress);
                  END IF;
                  RAISE;
              END;

            END IF;  -- if interface_line_num and x_document_num are not null

            l_progress := '290';

            get_shipment_num(
              x_need_by_date,
              x_deliver_to_location_id,
              x_destination_org_id,
              x_po_line_id,
              x_po_line_num,
              x_requisition_line_id,
              x_interface_header_id,
              x_po_shipment_num,
              x_note_to_receiver,
              x_preferred_grade,
              NULL,  -- VMI FPH
              x_consigned_flag,
              x_drop_ship_flag,     --  <DropShip FPJ>
              x_create_new_line,
			  p_group_shipments --<Bug 14608120 Autocreate GE ER>
			   );   -- FPI GA

            l_progress := '300';

            update_shipment(
              x_interface_header_id,
              x_po_shipment_num,
              x_po_line_num,
              x_requisition_line_id,
              x_po_line_id,
              x_document_num,
              x_release_num,
              x_create_new_line);  -- FPI GA

          ELSE

            -- action = NULL (R10 logic)

            -- Check to see if this line matches another line already on PO
            -- If the line matches, update interface line num with PO line num
            -- If the shipment matches, update interface table w/ ship. num
            -- If the the shipment does not match, update table w/ number = 1
            -- If the line does not match, get the next highest line number

            l_progress := '310';

            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'x_action = '||x_action);
            END IF;

            --<SOURCING TO PO FPH>: allow lines grouping for blankets also

            IF (g_document_type IN ('PO', 'PA')) THEN

              --<INVCONV R12 START>
              -- Item could have different grade control for FSP and ship to org.
              -- If (shipment)grade is present , compare the grade at line level
              -- only if item is grade control for the FSP org.
              IF x_preferred_grade IS NOT NULL THEN

                BEGIN
                  SELECT grade_control_flag
                  INTO l_grade_control_flag
                  FROM mtl_system_items
                  WHERE inventory_item_id = x_item_id
                  and organization_id = params.inventory_organization_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    l_grade_control_flag := 'N';
                END;

                IF l_grade_control_flag = 'Y' THEN
                  l_line_grade := x_preferred_grade ;
                ELSE
                  l_line_grade := null;
                END IF;

              ELSE

                l_line_grade := null;

              END IF;  -- x_preferred_grade is not null
              --<INVCONV R12 END>

              BEGIN

                l_progress := '320';

                -- SQL What: Querying for an existing line on the PO
                -- that matches the requisition line that we are trying to add.
                -- SQL Why: Want to group matching lines onto PO documents
                -- SQL Join: business logic for combining two lines

                SELECT  line_num
                ,       po_line_id
                INTO    x_po_line_num
                ,       x_po_line_id
                FROM    po_lines_all POL2
                ,       po_headers_all POH
                ,       po_line_types_b PLT                 -- <SERVICES FPJ>
                WHERE  POH.segment1 = x_document_num
                AND    POH.po_header_id = POL2.po_header_id
                AND    NVL(poh.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
                AND    POH.type_lookup_code = x_document_subtype
                -- <SERVICES FPJ START> Any new Service line types should
                -- cause the SELECT to fail (i.e. should not be matched).
                --
                AND    POL2.line_type_id = PLT.line_type_id
                AND    PLT.order_type_lookup_code NOT IN ('RATE','FIXED PRICE')
                --
                -- <SERVICES FPJ END>
                AND    pol2.line_num =
                           (SELECT /*+ NO_UNNEST */ MIN(line_num)
                            FROM  po_lines_all pol  --<Shared Proc FPJ>
                            WHERE pol.po_header_id = poh.po_header_id
                            AND   NVL(CANCEL_FLAG,'N') = 'N'
                            AND   LINE_TYPE_ID = x_line_type_id
                            AND   nvl(pol.ITEM_ID, -1) = nvl(x_item_id, -1) -- bgu, For one time item
                            AND   nvl(pol.ITEM_DESCRIPTION,'null') = nvl(x_item_description,'null')
                            AND
                                ( (     ITEM_REVISION IS NULL
                                    AND x_item_revision IS NULL
                                   )
                                 OR ITEM_REVISION = x_item_revision
                                 )
                            AND   UNIT_MEAS_LOOKUP_CODE =
                                    x_unit_meas_lookup_code
--<INVCONV R12 START>
-- replace x_preferred_grade to l_line_grade and removed secondary unit comparison.
                            AND
                             (
                               ( POL.PREFERRED_GRADE IS NULL
                                AND  l_line_grade IS NULL
                                ) OR
                                (  POL.PREFERRED_GRADE =
                                   l_line_grade
                                 )
                              )
--<INVCONV R12 END>
                            AND  /* FPI GA start */
                             (
                               ( pol.from_header_id IS NULL
                                AND  x_source_doc_id IS NULL
                                ) OR
                                (  pol.from_header_id =
                                   x_source_doc_id
                                 )
                              )
                            AND
                             (
                               ( pol.from_line_id IS NULL
                                AND  x_source_doc_line_id IS NULL
                                ) OR
                                (  pol.from_line_id =
                                   x_source_doc_line_id
                                 )
                              )   /* FPI GA end */
                            AND   (TRANSACTION_REASON_CODE IS NULL
                                   OR TRANSACTION_REASON_CODE =
                                   NVL(x_transaction_reason_code,
                                  TRANSACTION_REASON_CODE))
                            AND  trunc(nvl(pol.expiration_date,sysdate+1)) >= trunc(sysdate)
                            AND  nvl(pol.oke_contract_header_id,-1)=nvl(x_oke_contract_header_id,-1)
                            AND  nvl(pol.oke_contract_version_id,-1)=nvl(x_oke_contract_version_id,-1)
                            AND  nvl(pol.vendor_product_num,-1)=nvl(x_vendor_product_num,-1)
                            AND nvl(pol.bid_number,-1)=nvl(x_bid_number,-1)
                            AND nvl(pol.bid_line_number,-1)=nvl(x_bid_line_number,-1)
                            -- <GC FPJ START>
                            AND
                             (
                                ( pol.contract_id IS NULL AND
                                  l_contract_id IS NULL )
                                OR
                                ( pol.contract_id = l_contract_id )
                             )
                            -- <GC FPJ END>
                            --<CONFIG_ID FPJ START>
                            AND ((pol.supplier_ref_number IS NULL
                                  AND l_supplier_ref_number IS NULL)
                                 OR (pol.supplier_ref_number = l_supplier_ref_number))
                            --<CONFIG_ID FPJ END>
                           )
                          FOR UPDATE OF QUANTITY;

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                    p_token    => l_progress,
                                                    p_message  => 'NO_DATA_FOUND: No match to po line: Doc type = '||g_document_type);
                  END IF;
                  x_po_line_num := -1;
                WHEN OTHERS THEN
                  IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                                   p_progress => l_progress);
                  END IF;
                  wrapup(x_interface_header_id);
                  RAISE;
              END;

            ELSIF (g_document_type = 'RFQ') THEN

              l_progress := '330';

              BEGIN

                SELECT line_num,
                       po_line_id
                INTO   x_po_line_num,
                       x_po_line_id
                FROM   po_lines_all POL2,
                       po_headers_all POH
                WHERE  POH.segment1 = x_document_num
                AND POH.po_header_id = POL2.po_header_id
                AND NVL(poh.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
                AND POH.type_lookup_code = 'RFQ'
                AND pol2.line_num =
                         (
                           SELECT /*+ NO_UNNEST */ MIN(line_num)
                           FROM  PO_LINES_ALL pol
                           WHERE pol.po_header_id = poh.po_header_id
                           AND LINE_TYPE_ID = x_line_type_id
                           AND nvl(pol.ITEM_ID, -1) = nvl(x_item_id, -1)
                           AND nvl(pol.ITEM_DESCRIPTION,'null') =
                                           nvl(x_item_description,'null')
                           AND
                                ( (     ITEM_REVISION IS NULL
                                    AND x_item_revision IS NULL
                                   )
                                 OR ITEM_REVISION = x_item_revision
                                 )
                           AND nvl(pol.oke_contract_header_id,-1) =
                                     nvl(x_oke_contract_header_id,-1)
                           AND nvl(pol.oke_contract_version_id,-1) =
                                     nvl(x_oke_contract_version_id,-1)
                         )
                FOR UPDATE OF QUANTITY;

              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                    p_token    => l_progress,
                                                    p_message  => 'NO_DATA_FOUND: No match to po line: Doc type RFQ');
                  END IF;
                  x_po_line_num := -1;
                WHEN OTHERS THEN
                  IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                                   p_progress => l_progress);
                  END IF;
                  wrapup(x_interface_header_id);
                  RAISE;
              END;

            END IF;  -- PO/PA vs. RFQ

            -- Check to see if there is a line in the interface table
            -- that matches the line we are attempting to add

            IF (x_po_line_num = -1) THEN

              --<SOURCING TO PO FPH>: allow lines grouping for blankets also

              IF (g_document_type IN ('PO', 'PA')) THEN

                l_progress := '340';

                BEGIN

                  x_ship_to_location_id :=
                       get_ship_to_loc(x_deliver_to_location_id);

                  l_progress := '350';

                  -- SQL What: Querying for a requisition line in the
                  -- interface table that matches the requisition line
                  -- that we are trying to add.
                  -- SQL Why: Want to group matching lines onto PO documents.
                  -- SQL Join: business logic for combining two lines

                  SELECT min(pli.line_num)
                  INTO   x_po_line_num
                  FROM   po_lines_interface pli
                  ,      po_requisition_lines_all prl
                  ,      po_line_types_b PLT                -- <SERVICES FPJ>
                  WHERE  pli.interface_header_id = x_interface_header_id
                  AND pli.line_num is not null
                  AND prl.requisition_line_id <> x_requisition_line_id
                  AND prl.requisition_line_id = pli.requisition_line_id
                  AND pli.line_type_id = x_line_type_id

                  -- <SERVICES FPJ START> Any new Service line types should
                  -- cause the SELECT to fail (i.e. should not be matched).
                  --
                  AND PLI.line_type_id = PLT.line_type_id
                  AND PLT.order_type_lookup_code NOT IN ('RATE','FIXED PRICE')
                  --
                  -- <SERVICES FPJ END>

                  AND nvl(pli.ITEM_ID, -1) = nvl(x_item_id, -1)
                  AND nvl(pli.ITEM_DESCRIPTION,'null') =
                                        nvl(x_item_description,'null')
                  AND ((pli.ITEM_REVISION IS NULL AND x_item_revision IS NULL)
                           OR pli.ITEM_REVISION = x_item_revision)
                  AND   pli.UNIT_OF_MEASURE = x_unit_meas_lookup_code

                  --<INVCONV R12 START>
                  -- replace x_preferred_grade to l_line_grade and
                  -- removed secondary unit comparison.
                  AND (( pli.PREFERRED_GRADE IS NULL AND l_line_grade IS NULL)
                            OR (pli.PREFERRED_GRADE = l_line_grade))
                  --<INVCONV R12 END>

                  -- FPI GA start
                  AND        (
                               ( pli.from_header_id IS NULL
                                AND  x_source_doc_id IS NULL
                                ) OR
                                (  pli.from_header_id =
                                   x_source_doc_id
                                 )
                              )
                  AND
                             (
                               ( pli.from_line_id IS NULL
                                AND  x_source_doc_line_id IS NULL
                                ) OR
                                (  pli.from_line_id =
                                   x_source_doc_line_id
                                 )
                              )
                  AND( nvl(l_needby_prf,'Y') = 'N'  -- Bug 3201308
                             OR
                             (
                               ( pli.need_by_date IS NULL
                                AND  x_need_by_date IS NULL
                                ) OR
                                ( to_char(pli.need_by_date-(to_number(substr(to_char(pli.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
                              )
                              )
                  AND ( nvl(l_shipto_prf,'Y') = 'N'  -- Bug 3201308
                              OR exists (select 'x'
                                     from HR_LOCATIONS HRL
                                     where PRL.deliver_to_location_id = HRL.location_id
                                     and nvl(HRL.ship_to_location_id, HRL.location_id) = x_ship_to_location_id
                                     UNION ALL
                                     select 'x'
                                     from HZ_LOCATIONS HZ
                                     where PRL.deliver_to_location_id = HZ.location_id
                                     and HZ.location_id = x_ship_to_location_id)
                               )
                  AND( nvl(l_shipto_prf,'Y') = 'N'   -- Bug 3201308
                              OR
                             (
                               ( pli.ship_to_organization_id  IS NULL
                                AND  x_destination_org_id IS NULL
                                ) OR
                                (  pli.ship_to_organization_id =
                                   x_destination_org_id
                                 )
                              ) )
                  -- FPI GA end

                  -- CONSIGNED FPI start
                  AND        (
                               ( pli.consigned_flag IS NULL
                                AND  x_consigned_flag IS NULL
                                ) OR
                                (  pli.consigned_flag  =
                                   x_consigned_flag
                                 )
                              )
                  -- CONSIGNED FPI End

                  AND   (pli.TRANSACTION_REASON_CODE IS NULL
                                   OR pli.TRANSACTION_REASON_CODE =
                                   NVL(x_transaction_reason_code,
                                  pli.TRANSACTION_REASON_CODE))

                  AND nvl(pli.oke_contract_header_id,-1) =
                            nvl(x_oke_contract_header_id,-1)
                  AND nvl(pli.oke_contract_version_id,-1) =
                            nvl(x_oke_contract_version_id,-1)
                  AND nvl(pli.vendor_product_num,-1) =
                            nvl(x_vendor_product_num,-1)
                  AND nvl(pli.bid_number,-1) = nvl(x_bid_number,-1)
                  AND nvl(pli.bid_line_number,-1) = nvl(x_bid_line_number,-1)
                  AND nvl(pli.orig_from_req_flag,'Y') <> 'N'

                  -- <GC FPJ START>
                  AND
                             (
                               ( pli.contract_id IS NULL AND
                                 l_contract_id IS NULL )
                               OR
                               ( pli.contract_id = l_contract_id )
                             )
                  -- <GC FPJ END>

                  --<CONFIG_ID FPJ START>
                  AND   ((pli.supplier_ref_number IS NULL
                                  AND l_supplier_ref_number IS NULL)
                                 OR (pli.supplier_ref_number = l_supplier_ref_number))
                  --<CONFIG_ID FPJ END>
                  ;

                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                    p_token    => l_progress,
                                                    p_message  => 'NO_DATA_FOUND: No match to po line in Interface- Doc type = '||g_document_type);
                    END IF;
                    x_po_line_num := -1;
                  WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                                   p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    RAISE;
                END;

              ELSIF (g_document_type = 'RFQ') THEN

                BEGIN

                  l_progress := '360';

                  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                  p_token    => l_progress,
                                                  p_message  => 'Before select min line_num');
                  END IF;

                  SELECT MIN(pli.line_num)
                  INTO x_po_line_num
                  FROM po_lines_interface pli
                  WHERE pli.interface_header_id = x_interface_header_id
                  AND pli.line_num is not null
                  AND pli.line_type_id = x_line_type_id
                  AND nvl(pli.item_id, -1) = nvl(x_item_id, -1)
                  AND nvl(pli.item_description,'null') =
                               nvl(x_item_description,'null')
                  AND ((pli.item_revision IS NULL AND x_item_revision IS NULL)
                         OR (pli.item_revision = x_item_revision))
                  AND nvl(pli.oke_contract_header_id,-1) =
                                   nvl(x_oke_contract_header_id,-1)
                  AND nvl(pli.oke_contract_version_id,-1) =
                                   nvl(x_oke_contract_version_id,-1)
                  ;

                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                    p_token    => l_progress,
                                                    p_message  => 'NO_DATA_FOUND: No match to po line in Interface- Doc type RFQ');
                    END IF;
                    x_po_line_num := -1;
                  WHEN OTHERS THEN
                    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                                   p_progress => l_progress);
                    END IF;
                    wrapup(x_interface_header_id);
                    RAISE;
                END;

              END IF;  -- PO/PA vs. RFQ

            END IF;  -- if x_po_line_num = -1 (interface table)

            IF (x_po_line_num <> -1) THEN

              -- a line matches

              l_progress := '370';

              --<SOURCING TO PO FPH>
              -- We need to use get_shipment_num only for those negotiations
              -- with backing req.

              IF (x_requisition_line_id IS NOT NULL) THEN

                -- backing req line exists

                -- Since get_shipment_num will need it, we update the
                -- line number here.

                UPDATE po_lines_interface pli
                SET pli.line_num = x_po_line_num
                WHERE pli.interface_header_id = x_interface_header_id
                AND pli.requisition_line_id = x_requisition_line_id;

                l_progress := '380';

                -- if a shipment matches, get the shipment number

                get_shipment_num(
                  x_need_by_date,
                  x_deliver_to_location_id,
                  x_destination_org_id,
                  x_po_line_id,
                  x_po_line_num,
                  x_requisition_line_id,
                  x_interface_header_id,
                  x_po_shipment_num,
                  x_note_to_receiver,
                  x_preferred_grade,
                  NULL,  -- VMI FPH
                  x_consigned_flag,
                  x_drop_ship_flag,     --  <DropShip FPJ>
                  x_create_new_line,
				  p_group_shipments --<Bug 14608120 Autocreate GE ER>
				  );   -- FPI GA

                l_progress := '390';

                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'Before update_shipment');
                END IF;

                update_shipment(
                  x_interface_header_id,
                  x_po_shipment_num,
                  x_po_line_num,
                  x_requisition_line_id,
                  x_po_line_id,
                  x_document_num,
                  x_release_num,
                  x_create_new_line);  -- FPI GA

              ELSE

                -- no backing requisition line

                --< SOURCING TO PO FPH >
                --Assign max line number+1 from interface table when not backed
                --by a req and the shipment num would be 1. There can't be two
                --similar negotiation lines not backed by a req, having the
                --same bid number and bid line number. If that happens we don't
                --group them to a single line. Also no need to select from
                --po_lines table as we are not supporting add to functionality.

                l_progress := '400';

                UPDATE po_lines_interface pli2
                SET (pli2.line_num, pli2.shipment_num) =
                      (
                        SELECT (NVL(max(pli.line_num), 0) + 1), 1
                        FROM po_lines_interface pli
                        WHERE pli.interface_header_id = x_interface_header_id
                      )
                WHERE pli2.rowid = x_row_id;

              END IF;

            ELSE

              -- a matching line does not exist

              -- Get the max line number on the purchase order and
              -- update the interface line number with that number + 1.
              -- The shipment number should be 1.

              l_progress := '410';
              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                           PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                               p_token    => l_progress,
                                               p_message  => 'Group_interface_lines: Line does not exist');
              END IF;

              SELECT NVL(max(pl.line_num), 0)
              INTO x_line_num
              FROM po_headers_all ph,
                   po_lines_all pl
              WHERE pl.po_header_id = ph.po_header_id
              AND ph.segment1 = x_document_num
              AND NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99)
              AND ph.type_lookup_code =
                    DECODE(g_document_type, 'RFQ', g_document_type, x_document_subtype)
              ;

              -- Get the max line number already assigne in the interface table

              l_progress:='420';
              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                           PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                               p_token    => l_progress,
                                               p_message  => 'Before select max line_num from po_lines_interface');
              END IF;

              SELECT NVL(max(pli.line_num), 0)
              INTO x_int_line_num
              FROM po_lines_interface pli
              WHERE pli.interface_header_id = x_interface_header_id;

              IF (x_line_num >= x_int_line_num) THEN
                x_line_num := x_line_num;
              ELSE
                x_line_num := x_int_line_num;
              END IF;

              l_progress := '430';
              --<SOURCING TO PO FPH>: when req line id is null, use x_row_id

              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                       PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                           p_token    => l_progress,
                                           p_message  => 'Sourcing to FPH-8 starts');
              END IF;

              IF (x_requisition_line_id IS NOT NULL) THEN

                UPDATE po_lines_interface pli
                SET pli.line_num = x_line_num + 1,
                    pli.shipment_num = 1
                WHERE pli.interface_header_id = x_interface_header_id
                AND pli.requisition_line_id = x_requisition_line_id;

              ELSE

                -- no backing req line; use rowid

                UPDATE po_lines_interface pli
                SET pli.line_num = x_line_num + 1,
                    pli.shipment_num = 1
                WHERE pli.rowid = x_row_id;

              END IF;  -- if x_requisition_id is not null

              IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                       PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                           p_token    => l_progress,
                                           p_message  => 'Sourcing to FPH-8 ends');
              END IF;

              x_num_interface_lines := x_num_interface_lines + 1;

            END IF; -- matching line vs. no matching line

           END IF; -- Action Type Code

        END LOOP;
        CLOSE interface_lines;

      ELSE

        -- Document is release case

        l_progress:='440';

        OPEN interface_lines;
        LOOP

          l_progress:='450';

          FETCH interface_lines INTO
            x_action,
            x_requisition_line_id,
            x_interface_line_num,
            x_item_id,
            x_item_description,     -- bgu, Mar. 19, 1999
            x_line_type_id,
            x_item_revision,
            x_unit_meas_lookup_code,
            x_transaction_reason_code,
            x_need_by_date,
            x_note_to_receiver,
            x_oke_contract_header_id,
            x_oke_contract_version_id,
            x_vendor_product_num, --Bug# 1763933
            x_deliver_to_location_id,
            x_destination_org_id,
            x_secondary_unit_of_measure,
            x_preferred_grade,
            x_bid_number,
            x_bid_line_number,
            x_row_id,
            x_vmi_flag,  -- VMI FPH
            x_drop_ship_flag,   --  <DropShip FPJ>
            x_source_doc_id ,        -- FPI GA
            x_source_doc_line_id ,    -- FPI GA
            x_consigned_flag,         -- CONSIGNED FPI
            l_contract_id,            -- <GC FPJ>
            l_supplier_ref_number    --<CONFIG_ID FPJ>
          ;

          EXIT WHEN interface_lines%NOTFOUND;

          IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'After fetch interface_lines cursor');
          END IF;


          IF (x_action is NULL) THEN

            -- The user did not specify the line that they want the req line
            -- to be associated with.  We need to find a req. line that matches
            -- it.  If one does not match, skip the record.  If one does match,
            -- update the interface table with the correct line number.


            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress,
                                           p_name     => 'x_line_type_id',
                                           p_value    => x_line_type_id);
                        PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress,
                                           p_name     => 'x_item_id',
                                           p_value    => x_item_id);
                        PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress,
                                           p_name     => 'x_item_revision',
                                           p_value    => x_item_revision);
                        PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress,
                                           p_name     => 'x_unit_meas_lookup_code',
                                           p_value    => x_unit_meas_lookup_code);
                        PO_DEBUG.debug_var(p_log_head => g_log_head||l_api_name,
                                           p_progress => l_progress,
                                           p_name     => 'x_transaction_reason_code',
                                           p_value    => x_transaction_reason_code);
            END IF;

            l_progress := '460';

            BEGIN

              SELECT min(line_num)
              ,      po_line_id
              INTO   x_po_line_num
              ,      x_po_line_id
              FROM   po_lines_interface PLI
              ,      po_line_types_b    PLT                 -- <SERVICES FPJ>
              WHERE  pli.interface_header_id = x_interface_header_id
              AND    pli.line_num is not null
              AND    pli.LINE_TYPE_ID = x_line_type_id

              -- <SERVICES FPJ START> Any new Service line types should
              -- cause the SELECT to fail (i.e. should not be matched).
              --
              AND    PLI.line_type_id = PLT.line_type_id
              AND    PLT.order_type_lookup_code NOT IN ('RATE','FIXED PRICE')
              --
              -- <SERVICES FPJ END>

              AND    nvl(pli.ITEM_ID, -1) = nvl(x_item_id, -1)
              AND    nvl(pli.ITEM_DESCRIPTION,'null') =
                                     nvl(x_item_description,'null')
              AND             ( (     pli.ITEM_REVISION IS NULL
                                    AND x_item_revision IS NULL
                                   )
                                  OR pli.ITEM_REVISION = x_item_revision
                                  )
              AND    pli.UNIT_OF_MEASURE = x_unit_meas_lookup_code
              AND    (pli.TRANSACTION_REASON_CODE IS NULL
                                   OR pli.TRANSACTION_REASON_CODE =
                                   NVL(x_transaction_reason_code,
                                  pli.TRANSACTION_REASON_CODE))
              AND   nvl(pli.oke_contract_header_id,-1)=nvl(x_oke_contract_header_id,-1)
              AND   nvl(pli.oke_contract_version_id,-1)=nvl(x_oke_contract_version_id,-1)
              GROUP BY po_line_id;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                                p_token    => l_progress,
                                                p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
                x_po_line_num := -1;
            END;

            l_progress := '470';

            UPDATE po_lines_interface pli
            SET pli.line_num = x_po_line_num
            WHERE pli.interface_header_id = x_interface_header_id
            AND pli.requisition_line_id = x_requisition_line_id;

            x_interface_line_num := x_po_line_num;

            IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                              p_token    => l_progress,
                                              p_message  => 'After update of po_lines_interface line_num');
            END IF;

          ELSE

            -- The user did specify the line that they want the
            -- requisition line to come from.
            -- Note: For a one time item Blanket Release, the user must
            -- always specify the action ADD and the line number that
            -- that want to release against in the form.

            l_progress := '480';

            BEGIN

              SELECT pol.po_line_id
              INTO x_po_line_id
              FROM po_lines_all pol,
                   po_headers_all poh,
                   po_lines_interface pli
              WHERE pol.po_header_id = poh.po_header_id
              AND poh.segment1 = x_document_num
              AND NVL(poh.org_id, -99) = NVL(g_purchasing_ou_id, -99)
              AND poh.type_lookup_code = 'BLANKET' -- Bug# 1746943
              AND pol.line_num = pli.line_num
              AND pli.requisition_line_id = x_requisition_line_id;

            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                            p_token    => l_progress,
                                            p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                 END IF;
                 x_po_line_num := -1;

            END;
          END IF;  -- action code is null vs. not null

          l_progress := '490';

          -- Select the maximum shipment num that exists on the release.
          -- Update the shipment num in the interface table to be the
          -- requisition line number + this maximum shipment num


          -- if a shipment matches, get the shipment

          get_shipment_num(
             x_need_by_date,
             x_deliver_to_location_id,
             x_destination_org_id,
             x_po_line_id,
             x_interface_line_num,
             x_requisition_line_id,
             x_interface_header_id,
             x_po_shipment_num,
             x_note_to_receiver,
             x_preferred_grade,
             x_vmi_flag,  -- VMI FPH
             x_consigned_flag,
             x_drop_ship_flag,     --  <DropShip FPJ>
             x_create_new_line,
			 p_group_shipments --<Bug 14608120 Autocreate GE ER>
			 );   -- FPI GA

          update_shipment(
            x_interface_header_id,
            x_po_shipment_num,
            x_po_line_num,
            x_requisition_line_id,
            x_po_line_id,
            x_document_num,
            x_release_num,
            x_create_new_line, -- FPI GA
            x_row_id );

        END LOOP;
        CLOSE interface_lines;

      END IF;  -- If STANDARD/PLANNED/RELEASE

    END IF;  -- of same  as REQUISITION mode

  END IF;  -- of PO mode

  IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => 'Exception block: NO_DATA_FOUND: '||SQLERRM);
    END IF;
     null;
  WHEN OTHERS THEN
    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                           p_progress => l_progress||'_main');
    END IF;
     po_message_s.sql_error('GROUP INTERFACE LINES',l_progress,sqlcode);
     wrapup(x_interface_header_id);
     raise;
END group_interface_lines;


-- Bug 2875346 start.
/**
 * Private Function: has_one_time_location
 * Effects: Checks if the requisition line p_req_line_id has a one-time
 *   location.
 * Returns: TRUE if the requisition line has a one-time location
 *          FALSE otherwise
 */
FUNCTION has_one_time_location(p_req_line_id IN NUMBER)
    RETURN BOOLEAN
IS

l_api_name CONSTANT VARCHAR2(30) := 'has_one_time_location';
l_flag VARCHAR2(1);
l_progress VARCHAR2(3) := '000';                    --< Bug 3210331 >

BEGIN
    l_progress := '000';

    IF (p_req_line_id IS NOT NULL) THEN

        -- Query if this req line has a one-time location attachment, which
        -- indicates that the req line is for a one-time location.
        SELECT 'Y'
          INTO l_flag
          FROM fnd_attached_documents
         WHERE entity_name = 'REQ_LINES'
           AND pk1_value = to_char(p_req_line_id)
           AND pk2_value = 'ONE_TIME_LOCATION'
           AND rownum = 1;

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Req line '||p_req_line_id||' has one-time attachment');
        END IF;

        RETURN TRUE;

    ELSE

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Req line is null');
        END IF;
        RETURN FALSE;

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'NO_DATA_FOUND: No one-time attachment for req line '||p_req_line_id);
        END IF;
        RETURN FALSE;
    WHEN OTHERS THEN
        IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                               p_progress => l_progress);
        END IF;
        RETURN FALSE;
END has_one_time_location;
-- Bug 2875346 end.


/*
 * <Bug 14608120 Autocreate GE ER>
 * Private Function: is_wip_enabled
 * Effects: Checks if the requisition line p_req_line_id has beed created
 *          from work order.
 * Returns: TRUE if the requisition line has been created from work order
 *          FALSE otherwise.
 */

FUNCTION is_wip_enabled(p_req_line_id IN NUMBER)
    RETURN BOOLEAN
IS

l_api_name CONSTANT VARCHAR2(30) := 'is_wip_enabled';
l_flag VARCHAR2(1);
l_progress VARCHAR2(3) := '000';                    --< Bug 3210331 >

BEGIN
    l_progress := '000';

    IF (p_req_line_id IS NOT NULL) THEN

        -- Check whether the Req has been created from wip.

		SELECT 'Y'
		  INTO l_flag
		  FROM po_requisition_lines_all
		 WHERE requisition_line_id = p_req_line_id
		 AND wip_entity_id IS NOT NULL;


        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Req line '||p_req_line_id||' is wip enabled');
        END IF;

        RETURN TRUE;

    ELSE

        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'Req line is null');
        END IF;
        RETURN FALSE;

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'NO_DATA_FOUND: No wip entity for req line '||p_req_line_id);
        END IF;
        RETURN FALSE;
    WHEN OTHERS THEN
        IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                               p_progress => l_progress);
        END IF;
        RETURN FALSE;
END is_wip_enabled;

/* ============================================================================
     NAME: GET_SHIPMENT_NUM
     DESC: Get Shipment Number
     ARGS: x_interface_header_id IN number
     ALGR:
   ==========================================================================*/
PROCEDURE get_shipment_num(x_need_by_date IN DATE, x_deliver_to_location_id IN NUMBER,
         x_destination_org_id IN NUMBER,
         x_po_line_id IN NUMBER,
         x_po_line_num IN NUMBER,
         x_requisition_line_id IN NUMBER,
               x_interface_header_id IN NUMBER,
         x_po_shipment_num IN OUT NOCOPY number,
                 x_note_to_receiver IN varchar2,
                           x_preferred_grade IN VARCHAR2,      -- Bug 1548597
                           x_vmi_flag   IN  VARCHAR2 ,         -- VMI FPH
                           x_consigned_flag IN VARCHAR2,       -- CONSIGNED FPI
                           x_drop_ship_flag IN VARCHAR2,       --  <DropShip FPJ>
                           x_create_new_line OUT NOCOPY VARCHAR2,
						   x_group_shipments IN VARCHAR2 DEFAULT NULL --<Bug 14608120 Autocreate GE ER>
							) IS  -- GA FPI

 x_ship_to_location_id number;
x_receipt_required_flag varchar2(1);
x_so_line_id number:='';
x_so_line_id_from_shipment number:='';
x_so_line_id_from_req_line number:='';
x_line_location_to_check number:='';
x_req_line_to_check number:='';

--Added for Bug# 1512955
x_check_doc_sub_type  varchar2(25);

/* Bug 3201308 start */
 l_needby_prf  varchar2(1);
 l_shipto_prf  varchar2(1);
/* Bug 3201308 end */
l_api_name CONSTANT VARCHAR2(30) := 'get_shipment_num';     --< Bug 3210331 >
l_progress VARCHAR2(3) := '000';                            --< Bug 3210331 >

l_po_line_id  NUMBER;  -- bug2788115
l_group_shipments VARCHAR2(1); --<Bug 14608120 Autocreate GE ER>

BEGIN
   IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
   END IF;

   /* Bug 3201308 start */
   /* Get the profile option values to determine grouping criteria */

     l_needby_prf := fnd_profile.value('PO_NEED_BY_GROUPING');
     l_shipto_prf := fnd_profile.value('PO_SHIPTO_GROUPING');

   /* Bug 3201308 end */

   /* OE drop ship requirement
   ** Do not consolidate any shipments linked to a sales order
   ** Neither add them to existing shipments
   ** or let other shipments add to them
   */

   --<DropShip FPJ Start>
   --Removed call to oe_drop_ship_grp.req_line_is_drop_ship, instead use x_drop_ship_flag
   --Bug 7312562
   --Moving this code to the end of the procedure.
   --So that the same logic is used for Drop shipments also.
   --Ensuring that two drop shipments are not inserted into same shipment,
   --by setting x_po_shipment_num := -1;
   /*IF g_document_type = 'PO' AND x_drop_ship_flag = 'Y' THEN
     x_po_shipment_num := -1;
      x_create_new_line := 'Y';  --Bug 5568899
     return;
   END IF;*/
   --<DropShip FPJ End>

   l_progress := '010';

   -- Bug 2875346. Do not group shipments if the req has a one-time location.
   IF (has_one_time_location(x_requisition_line_id)) THEN
       x_po_shipment_num := -1;
       --Bug 7312562
       IF g_document_type = 'PO' AND x_drop_ship_flag = 'Y' THEN
          x_create_new_line := 'Y';
       END IF;
       IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'One-time location. Shipment num = -1');
       END IF;
       RETURN;
   END IF;
   -- Bug 2875346 end.

   x_ship_to_location_id := -1;
   l_progress:='020';
   x_ship_to_location_id := get_ship_to_loc(x_deliver_to_location_id);  -- FPI

   x_po_shipment_num := -1;

   IF ((g_document_subtype='STANDARD' OR g_document_subtype='PLANNED')
  AND g_document_type = 'PO') THEN

      l_progress:='030';

      /* Consigned FPI start : split the following select to determine if a new line
         is to be created or just a new shipment */

     -- Bug 3201308 : Further split the select into 3 selects to chenck
     -- matching for need by date ,ship to and rest of the information

     -- Bug 2757524 Do not execute this select if x_po_line_id is null

      IF x_po_line_id is not null THEN

      l_progress:='040';
      BEGIN

         -- SQL WHAT : compares the existing shipment values with the values from the req
         -- SQL WHY : to create a new line if the need by is different based on the profile

         SELECT PLL.shipment_num
          ,PLL.line_location_id
         INTO   x_po_shipment_num
    ,x_line_location_to_check
         FROM   PO_LINE_LOCATIONS_ALL    PLL  --<Shared Proc FPJ>
         WHERE  PLL.PO_LINE_ID = x_po_line_id
-- bug 4599140 (included the following OR condition so that the SQL works correctly
-- for null need_by_date)
         AND    (( to_char(PLL.need_by_date-(to_number(substr(to_char(PLL.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
               OR
                  (PLL.need_by_date is NULL AND x_need_by_date is NULL)
                  )
         AND    ROWNUM = 1
         FOR UPDATE OF PLL.QUANTITY;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
              x_po_shipment_num := -1;
              if nvl(l_needby_prf,'Y') = 'Y' then   -- Bug 3201308
               x_create_new_line := 'Y';
              end if;
            WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
          wrapup(x_interface_header_id);
    RAISE;

      END;
        -- Bug 3534897 : added nvl to create new line flag
        IF x_po_shipment_num <> -1 and nvl(x_create_new_line,'N') <> 'Y' THEN
          l_progress:='050';
          BEGIN

         -- SQL WHAT : compares the existing shipment values with the values from the req
         -- SQL WHY : to create a new line if ship to is different based on the value of the
         --           profile

         SELECT PLL.shipment_num
          ,PLL.line_location_id
         INTO   x_po_shipment_num
    ,x_line_location_to_check
         FROM   PO_LINE_LOCATIONS_ALL    PLL  --<Shared Proc FPJ>
         WHERE  PLL.PO_LINE_ID = x_po_line_id
         AND    PLL.SHIP_TO_LOCATION_ID = x_ship_to_location_id
         AND    PLL.SHIP_TO_ORGANIZATION_ID =
            x_destination_org_id
         AND    ROWNUM = 1
         FOR UPDATE OF PLL.QUANTITY;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
              x_po_shipment_num := -1;
              if nvl(l_shipto_prf,'Y') = 'Y' then  -- Bug 3201308
               x_create_new_line := 'Y';
              end if;
            WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
          wrapup(x_interface_header_id);
    RAISE;

          END;
        END IF;

        -- Bug 3534897 : added nvl to create new line flag
        IF x_po_shipment_num <> -1 and nvl(x_create_new_line,'N') <> 'Y' THEN
          l_progress:='060';
          BEGIN

         -- SQL WHAT : compares the exixting shipment values with the values from the req
         -- SQL WHY : to create a new line if its a drop ship line or consigned flag is
         --           different

         SELECT PLL.shipment_num
          ,PLL.line_location_id
         INTO   x_po_shipment_num
    ,x_line_location_to_check
         FROM   PO_LINE_LOCATIONS_ALL    PLL  --<Shared Proc FPJ>
         WHERE  PLL.PO_LINE_ID = x_po_line_id
         AND    nvl(PLL.drop_ship_flag, 'N') <> 'Y' --<DropShip FPJ> cannot add to Drop Ship Shipments
         AND   nvl(PLL.CONSIGNED_FLAG,'N') = nvl(x_consigned_flag,'N')
         AND    ROWNUM = 1
         FOR UPDATE OF PLL.QUANTITY;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
              x_po_shipment_num := -1;

              /* Bug 14796195
	      In case of drop shipments flow, the line level grouping
	      should happen based on the profile options value.
	      But the shipments will not be grouped. */

	      if nvl(l_needby_prf,'Y') = 'Y' or nvl(l_shipto_prf,'Y') = 'Y' then
	        x_create_new_line := 'Y';
	      end if;

	      /* Bug 14796195 */

            WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
          wrapup(x_interface_header_id);
    RAISE;

          END;
        END IF;

      END IF;  -- end of po line id not null check

      IF x_po_shipment_num <> -1 THEN
         l_progress:='070';
         BEGIN

         -- SQL WHAT : compares the exixting shipment values with the values from the req
         -- SQL WHY : if the above values match then we need to determine if we need to create
         --           a new shipment or not

         SELECT PLL.shipment_num
         INTO   x_po_shipment_num
         FROM   PO_LINE_LOCATIONS_ALL    PLL,  --<Shared Proc FPJ>
                PO_REQUISITION_LINES_ALL PRL,  --<Shared Proc FPJ>
                PO_SYSTEM_PARAMETERS_ALL     PSP  --<Shared Proc FPJ>
         WHERE  PLL.LINE_LOCATION_ID = x_line_location_to_check
         AND    PRL.REQUISITION_LINE_ID = x_requisition_line_id
   AND    rtrim(nvl(PLL.note_to_receiver,'99')) = rtrim(nvl(x_note_to_receiver,'99'))
         AND    PLL.SHIPMENT_TYPE in ('STANDARD', 'SCHEDULED',
            'BLANKET')
         AND    NVL(PLL.ENCUMBERED_FLAG,'N') = 'N'
         AND    NVL(PLL.CANCEL_FLAG,'N') = 'N'
         AND    NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99)
         AND    PLL.ACCRUE_ON_RECEIPT_FLAG =
                decode(interface.transaction_flow_header_id, NULL,  --<Shared Proc FPJ>
                 decode(prl.destination_type_code,'EXPENSE',
                     decode(psp.expense_accrual_code,'PERIOD END','N',
                            decode(nvl(item.receipt_required_flag,
                                   nvl(interface.receipt_required_flag,
                                   nvl(vendor.receipt_required_flag,
                                   nvl(params.receiving_flag,'N')))),
                            'N','N','Y')),'Y'), 'Y')  --<Shared Proc FPJ>
-- start of 1548597
         AND
               (
                ( PLL.PREFERRED_GRADE IS NULL AND  x_preferred_grade IS NULL )
                 OR
                (  PLL.PREFERRED_GRADE = x_preferred_grade )
                )
-- end of 1548597
         AND    NVL(PLL.VMI_FLAG, 'N')  =  NVL(x_vmi_flag, 'N')          --  VMI
         AND    ROWNUM = 1
         FOR UPDATE OF PLL.QUANTITY;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
              x_po_shipment_num := -1;
            WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
          wrapup(x_interface_header_id);
    RAISE;

      END;
      END IF;
      /* Consigned FPI end */

      /* OE Drop Ship
      ** Make sure not to add to  dropship related shipment.
      */
      IF x_po_shipment_num <> -1 THEN
          l_progress:='080';
   x_so_line_id_from_shipment:=
          OE_DROP_SHIP_GRP.PO_Line_Location_Is_Drop_Ship(x_line_location_to_check);
   IF x_so_line_id_from_shipment IS NOT NULL THEN
      x_po_shipment_num := -1;
         END IF;
      END IF;

   ELSIF (g_document_type = 'RFQ') THEN

      l_progress:='090';
      BEGIN

         SELECT PLL.shipment_num
         INTO   x_po_shipment_num
         FROM   PO_LINE_LOCATIONS_ALL    PLL,  --<Shared Proc FPJ>
                PO_REQUISITION_LINES_ALL PRL,  --<Shared Proc FPJ>
                PO_SYSTEM_PARAMETERS_ALL     PSP  --<Shared Proc FPJ>
         WHERE  PLL.PO_LINE_ID = x_po_line_id
         AND    PRL.REQUISITION_LINE_ID = x_requisition_line_id
         --Bug4599140 (included the following OR condition so that the SQL works correctly
         --for null need by date)
         AND    ( ( to_char(PLL.need_by_date-(to_number(substr(to_char(PLL.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
                  OR
                  (PLL.need_by_date is NULL AND x_need_by_date is NULL)
                )
   AND    rtrim(nvl(PLL.note_to_receiver,'99')) = rtrim(nvl(x_note_to_receiver,'99'))
         AND    PLL.SHIP_TO_LOCATION_ID = x_ship_to_location_id
         AND    NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
         AND    ROWNUM = 1
         FOR UPDATE OF PLL.QUANTITY;

         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
              x_po_shipment_num := -1;
            WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
       wrapup(x_interface_header_id);
       RAISE;

      END;

   ELSE /* Release */

      l_progress:='100';

      x_po_shipment_num := -1;

      BEGIN

         SELECT por.po_release_id
           INTO g_po_release_id
           FROM po_releases_all por,  --<Shared Proc FPJ>
                po_headers_interface phi
          WHERE phi.interface_header_id = x_interface_header_id
            AND phi.release_num = por.release_num
            AND phi.po_header_id = por.po_header_id
            AND NVL(por.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
            FOR UPDATE OF por.approved_flag;

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
	   --Bug5584718(we need to clear g_po_release_id)
                g_po_release_id := null;
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
           WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
       wrapup(x_interface_header_id);
       RAISE;

      END;

      l_progress := '105';

      -- bug2788115 START
      -- Derive po_line_id if only line number is provided

      IF (x_po_line_num <> -1 AND x_po_line_id IS NULL) THEN

          PO_DEBUG.debug_stmt
          ( p_log_head => g_log_head || l_api_name,
            p_token    => l_progress,
            p_message  => 'Derive po_line_id from line num ' || x_po_line_num
          );

          SELECT POL.po_line_id
          INTO   l_po_line_id
          FROM   po_headers_interface PHI,
                 po_lines_all POL
          WHERE  PHI.interface_header_id = x_interface_header_id
          AND    PHI.po_header_id = POL.po_header_id
          AND    POL.line_num = x_po_line_num;
      ELSE
          l_po_line_id := x_po_line_id;
      END IF;

      -- bug2788115 END

      l_progress:='110';
      BEGIN

    --<bug#5050294 START>
    --As per the HLD.
    --Only Requisition grouping will be available for the new Service line types.
    --That is why we cannot group req lines withe RATE OR FIXED PRICE line types
    --onto the same shipment.
    --<bug#5050294 END>

         SELECT PLL.shipment_num
               ,PLL.line_location_id
         INTO   x_po_shipment_num,
                x_line_location_to_check
         FROM   PO_LINE_LOCATIONS_ALL    PLL,  --<Shared Proc FPJ>
                PO_LINES_ALL POL, --<bug#5050294>
                PO_LINE_TYPES PLT --<bug#5050294>
         WHERE  POL.PO_LINE_ID = l_po_line_id  -- bug2788115
         AND    POL.po_line_id = PLL.po_line_id --<bug#5050294>
         AND    POL.line_type_id = PLT.line_type_id --<bug#5050294>
         AND    PLT.order_type_lookup_code NOT IN ('RATE', 'FIXED PRICE')--<bug#5050294>
         AND    PLL.po_release_id = g_po_release_id
 --Bug 4599140 (included the following OR condition so that the SQL works correctly
 --for null need by date)
         AND    ( ( to_char(PLL.need_by_date-(to_number(substr(to_char(PLL.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
                  OR
                  (PLL.need_by_date is NULL AND x_need_by_date is NULL)
               )
         AND    nvl(PLL.drop_ship_flag, 'N') <> 'Y' --<DropShip FPJ> cannot add to Drop Ship Shipments
         --togeorge 09/27/2000
   --added note to receiver
   --AND    rtrim(PLL.note_to_receiver) = rtrim(x_note_to_receiver)
   --Bug# 1867976,togeorge, 07/06/2001
   --added nvl
   AND    rtrim(nvl(PLL.note_to_receiver,'99')) = rtrim(nvl(x_note_to_receiver,'99'))
         AND    PLL.SHIP_TO_LOCATION_ID = x_ship_to_location_id
         AND    PLL.SHIP_TO_ORGANIZATION_ID =
            x_destination_org_id
         AND    PLL.SHIPMENT_TYPE in ('STANDARD', 'SCHEDULED',
            'BLANKET')
         AND    NVL(PLL.ENCUMBERED_FLAG,'N') = 'N'
         AND    NVL(PLL.CANCEL_FLAG,'N') = 'N'
-- start of 1548597
         AND
               (
                ( PLL.PREFERRED_GRADE IS NULL AND  x_preferred_grade IS NULL )
                 OR
                (  PLL.PREFERRED_GRADE = x_preferred_grade )
                )
-- end of 1548597
         AND    NVL(PLL.VMI_FLAG, 'N')  =  NVL(x_vmi_flag, 'N')          --  VMI FPH
         AND    nvl(PLL.CONSIGNED_FLAG,'N') = nvl(x_consigned_flag,'N')  -- CONSIGNED FPI
         AND    ROWNUM = 1
         FOR UPDATE OF PLL.QUANTITY;


         EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
              x_po_shipment_num := -1;
            WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
       wrapup(x_interface_header_id);
       RAISE;

      END;

      IF x_po_shipment_num <> -1 THEN
          l_progress:='120';
   x_so_line_id_from_shipment:=
          OE_DROP_SHIP_GRP.PO_Line_Location_Is_Drop_Ship(x_line_location_to_check);
   IF x_so_line_id_from_shipment IS NOT NULL THEN
      x_po_shipment_num := -1;
         END IF;
      END IF;

   END IF;

   IF (x_po_shipment_num = -1) and (g_document_type = 'PO') THEN

      /*
      ** Get the receipt required flag that
      ** will be inserted for the shipment.
      */
      l_progress:='130';

      /* Bug No. 1362044. We were not correctly considering the
    Accrue on Recepit Flag when grouping the shipments. Modified this logic .
    This part of the code gets the current Accrue on Receipt flag which will
    be compared with the other records in the interface table to see if
    they can be grouped together .
    Also added po_requisition_lines to the join to get the destination_type_code
    also added the outer join on po_vendors
    */
    /* Bug # 2224446, Autocreate was not grouping Req. lines when two req.
    with the same line details was entered. This happened when they don't
    Enter a Item in the lines block. We were not considering that the Item
    can be NULL when grouping shipment line. Used outer join on
    mtl_system_items when Checking for Item details. */

    --<bug#5050294 START>
    --As per the HLD.
    --Only Requisition grouping will be available for the new Service line types.
    --That is why we cannot group req lines withe RATE OR FIXED PRICE line types
    --onto the same shipment.
    --<bug#5050294 END>

      BEGIN
         SELECT DECODE(PRL.destination_type_code,
                      'EXPENSE',
                        decode(nvl(msi.receipt_required_flag,
                      nvl(plt.receiving_flag,
                       nvl(pov.receipt_required_flag,
                        nvl(psp.receiving_flag, 'N')))) ,'N','N',
                               decode(psp.expense_accrual_code,'PERIOD END', 'N', 'Y')),
                       'INVENTORY', 'Y',
                       'SHOP FLOOR','Y')
         INTO   x_receipt_required_flag
         FROM   po_lines_interface pli,
                po_headers_interface phi,
                    po_requisition_lines_all prl,  --<Shared Proc FPJ>
                mtl_system_items msi,
                po_line_types plt,
                po_vendors pov,
                po_system_parameters_all psp,  --<Shared Proc FPJ>
                financials_system_params_all fsp  --<Shared Proc FPJ>
         WHERE  pli.item_id = msi.inventory_item_id(+)
           AND  nvl(msi.organization_id,fsp.inventory_organization_id)=
             fsp.inventory_organization_id
           AND  pli.line_type_id = plt.line_type_id
           AND PLT.order_type_lookup_code NOT IN ('RATE', 'FIXED PRICE')--<bug#5050294>
           AND  phi.vendor_id = pov.vendor_id(+)
           AND  phi.interface_header_id =
        pli.interface_header_id
           AND  pli.interface_header_id =
                            phi.interface_header_id
           AND  prl.requisition_line_id = pli.requisition_line_id
           AND  pli.requisition_line_id =
                            x_requisition_line_id
           AND  NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
           AND  NVL(fsp.org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
           WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
           wrapup(x_interface_header_id);
     RAISE;
      END;

      l_progress:='140';

      IF (g_document_type = 'PO') THEN

        BEGIN
        /*
        ** See if a record that has just been inserted into the
        ** interface table matches the shipment you are trying to create.
        */
        /* Bug # 2224446, Added outer join on mtl_system_items */
/* Bug: 2348161.Changed the below SQL and removed the reference to the tables
                HZ_LOCATIONS and HR_LOCATIONS and also the corresponding where
                clause. Instead added a subquery to check for the location_id
                to improve the performance
*/
/* Bug 2466578. Changed the UNION to UNION ALL in the sub query to improve the
                performance.
*/

        SELECT PLI.shipment_num
         ,PLI.requisition_line_id
         INTO   x_po_shipment_num
    ,x_req_line_to_check
         FROM   PO_LINES_INTERFACE   PLI,
            PO_REQUISITION_LINES_ALL PRL,  --<Shared Proc FPJ>
                --bug 1942696 hr_location changes to reflect the new view
      MTL_SYSTEM_ITEMS     MSI ,
                PO_LINE_TYPES        PLT ,
                PO_SYSTEM_PARAMETERS_ALL PSP ,  --<Shared Proc FPJ>
                FINANCIALS_SYSTEM_PARAMS_ALL FSP,  --<Shared Proc FPJ>
                PO_VENDORS           POV,
                PO_HEADERS_INTERFACE PHI
         WHERE  PLI.LINE_NUM = x_po_line_num
     AND    PLI.shipment_num is not null
         AND    NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
         AND    NVL(fsp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
     AND    PLI.item_id = MSI.inventory_item_id(+)
         AND    nvl(MSI.organization_id,FSP.inventory_organization_id)=
                    FSP.inventory_organization_id
         AND    PLI.line_type_id = PLT.line_type_id
         AND    PHI.vendor_id  = POV.vendor_id (+)
         AND    PLI.interface_header_id =
                    PHI.interface_header_id
         AND    PRL.REQUISITION_LINE_ID <>
        x_requisition_line_id
   AND    PRL.requisition_line_id = PLI.requisition_line_id
  --Bug 4599140 (included the following OR condition so that the SQL works correctly
	--for null need by date)
         AND   ( ( to_char(PLI.need_by_date-(to_number(substr(to_char(PLI.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
                OR
                (PLI.need_by_date is NULL AND x_need_by_date is NULL)
                )
         AND    nvl(PLI.drop_ship_flag, 'N') <> 'Y' --<DropShip FPJ> cannot add to Drop Ship Shipments
         --togeorge 09/27/2000
   --added note to receiver
   --AND    rtrim(PLI.note_to_receiver) = rtrim(x_note_to_receiver)
   --Bug# 1867976,togeorge, 07/06/2001
   --added nvl
   AND    rtrim(nvl(PLI.note_to_receiver,'99')) = rtrim(nvl(x_note_to_receiver,'99'))
         --bug 1942696 hr_location changes to reflect the new view
       AND exists (select 'x'
                   from HR_LOCATIONS HRL
                   where PRL.deliver_to_location_id = HRL.location_id
                   and nvl(HRL.ship_to_location_id, HRL.location_id) = x_ship_to_location_id
                   UNION ALL
                   select 'x'
                   from HZ_LOCATIONS HZ
                   where PRL.deliver_to_location_id = HZ.location_id
                   and HZ.location_id = x_ship_to_location_id)
       AND    PRL.destination_organization_id = x_destination_org_id
     AND    DECODE(PRL.destination_type_code,
        'EXPENSE',
                      decode(nvl(msi.receipt_required_flag,
                            nvl(plt.receiving_flag,
                                 nvl(pov.receipt_required_flag,
                                  nvl(psp.receiving_flag,'N')))),'N','N',
                   decode(psp.expense_accrual_code, 'PERIOD END', 'N', 'Y')),
        'INVENTORY', 'Y',
        'SHOP FLOOR', 'Y')
          = x_receipt_required_flag
-- start of 1548597
         AND
               (
                ( PLI.PREFERRED_GRADE IS NULL AND  x_preferred_grade IS NULL )
                 OR
                ( PLI.PREFERRED_GRADE = x_preferred_grade )
                )
-- end of 1548597
         AND    NVL(PLI.VMI_FLAG, 'N')  =  NVL(x_vmi_flag, 'N')   --  VMI FPH
         AND    nvl(PLI.CONSIGNED_FLAG,'N') = nvl(x_consigned_flag,'N')  --CONSIGNED FPI
         AND    ROWNUM = 1;
/*Bug 2466578. Removed the ORDER BY Clause as we are using the ROWNUM = 1 condition and
               no need to order a single row. This is done to  improve the performance.
     ORDER BY shipment_num;
*/

     EXCEPTION
           WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
        x_po_shipment_num := -1;
           WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
       wrapup(x_interface_header_id);
       RAISE;
        END;

        /* Make sure that the potential shipment is related
        ** to drop ship
        */
        IF x_po_shipment_num <> -1 THEN
          l_progress:='150';
    x_so_line_id_from_req_line:=
            OE_DROP_SHIP_GRP.PO_Line_Location_Is_Drop_Ship(x_req_line_to_check);
    IF x_so_line_id_from_req_line IS NOT NULL THEN
       x_po_shipment_num := -1;
          END IF;
        END IF;

      ELSE
        /* not PO type */

        l_progress:='160';
        BEGIN
        /*
        ** See if a record that has just been inserted into the
        ** interface table matches the shipment you are trying to create.
        */
/* Bug: 2348161.Changed the below SQL and removed the reference to the tables
                HZ_LOCATIONS and HR_LOCATIONS and also the corresponding where
                clause. Instead added a subquery to check for the location_id
                to improve the performance
*/
        SELECT PLI.shipment_num
         INTO   x_po_shipment_num
         FROM   PO_LINES_INTERFACE   PLI,
                PO_REQUISITION_LINES_ALL PRL,  --<Shared Proc FPJ>
      MTL_SYSTEM_ITEMS     MSI ,
                PO_LINE_TYPES        PLT ,
                PO_SYSTEM_PARAMETERS_ALL PSP ,  --<Shared Proc FPJ>
                FINANCIALS_SYSTEM_PARAMS_ALL FSP,  --<Shared Proc FPJ>
                PO_VENDORS           POV,
                PO_HEADERS_INTERFACE PHI
         WHERE  PLI.LINE_NUM = x_po_line_num
     AND    PLI.shipment_num is not null
     AND    PLI.item_id = MSI.inventory_item_id
         AND    MSI.organization_id=
                    FSP.inventory_organization_id
         AND    PLI.line_type_id = PLT.line_type_id
         AND    PHI.vendor_id  = POV.vendor_id (+)
         AND    PLI.interface_header_id =
                    PHI.interface_header_id
         AND    PRL.REQUISITION_LINE_ID =
        x_requisition_line_id
         AND    NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
         AND    NVL(fsp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
         --Bug 4599140 (included the following OR condition so that the SQL works correctly
         --for null need by date)
         AND    ( ( to_char(PLI.need_by_date-(to_number(substr(to_char(PLI.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
                   OR
                   (PLI.need_by_date is NULL AND x_need_by_date is NULL)
               )
         AND    nvl(PLI.drop_ship_flag, 'N') <> 'Y' --<DropShip FPJ> cannot add to Drop Ship Shipments
         --togeorge 09/27/2000
   --added note to receiver
   --AND    rtrim(PLI.note_to_receiver) = rtrim(x_note_to_receiver)
   --Bug# 1867976,togeorge, 07/06/2001
   --added nvl
   AND    rtrim(nvl(PLI.note_to_receiver,'99')) = rtrim(nvl(x_note_to_receiver,'99'))
         --bug 1942696 hr_location changes to reflect the new view
       AND exists (select 'x'
                   from HR_LOCATIONS HRL
                   where PRL.deliver_to_location_id = HRL.location_id
                   and nvl(HRL.ship_to_location_id, HRL.location_id) = x_ship_to_location_id
                   UNION ALL
                   select 'x'
                   from HZ_LOCATIONS HZ
                   where PRL.deliver_to_location_id = HZ.location_id
                   and HZ.location_id = x_ship_to_location_id)
-- start of 1548597
         AND
               (
                ( PLI.PREFERRED_GRADE IS NULL AND  x_preferred_grade IS NULL )
                 OR
                ( PLI.PREFERRED_GRADE = x_preferred_grade )
                )
-- end of 1548597
         AND    ROWNUM = 1
     ORDER BY shipment_num;

     EXCEPTION
           WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
        x_po_shipment_num := -1;
           WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
       wrapup(x_interface_header_id);
       RAISE;
         END;

      END IF;

/* Bug# 1512955: kagarwal
** Forward Fix of bug# 1502551
--Added by jbalakri for  1502551 , RFQ's having multiple lines at the
--shipment level even though requisitions are having same item,need by
--date and ship to location.
*/

   ELSIF (x_po_shipment_num=-1) and (g_document_type='RFQ') THEN

     l_progress:='170';
     BEGIN
        /*
        ** See if a record that has just been inserted into the
        ** interface table matches the shipment you are trying to create.
        */
      begin
        l_progress:='180';
        SELECT document_subtype
        into x_check_doc_sub_type
        from
        PO_HEADERS_INTERFACE
        WHERE
        INTERFACE_HEADER_ID=x_interface_header_id;
      exception
      When others then
        IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                               p_progress => l_progress);
        END IF;
        wrapup(x_interface_header_id);
          raise;
      end;
       IF x_check_doc_sub_type='BID' then

/* Bug: 2348161.Changed the below SQL and removed the reference to the tables
                HZ_LOCATIONS and HR_LOCATIONS and also the corresponding where
                clause. Instead added a subquery to check for the location_id
                to improve the performance
*/

    /* Bug # 2286618, Autocreate was not grouping Req. lines when two req.
    with the same line details was entered. This happened when they Entered
    a One Time Item in the lines block. We were not considering that the Item
    can be NULL when grouping shipment line. Used outer join on
    mtl_system_items when Checking for Item details. */

         l_progress:='190';
         SELECT PLI.shipment_num
         INTO   x_po_shipment_num
         FROM   PO_LINES_INTERFACE   PLI,
                PO_REQUISITION_LINES_ALL PRL,  --<Shared Proc FPJ>
           --bug 1942696 hr_location changes to reflect the new view
                MTL_SYSTEM_ITEMS     MSI ,
                PO_LINE_TYPES        PLT ,
                PO_SYSTEM_PARAMETERS_ALL PSP ,  --<Shared Proc FPJ>
                FINANCIALS_SYSTEM_PARAMS_ALL FSP,  --<Shared Proc FPJ>
                PO_VENDORS           POV,
                PO_HEADERS_INTERFACE PHI
         WHERE  PLI.LINE_NUM = x_po_line_num
         AND    PLI.shipment_num is not null
         AND    NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
         AND    NVL(fsp.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
         AND    PLI.item_id = MSI.inventory_item_id(+)
         AND    nvl(MSI.organization_id,FSP.inventory_organization_id) =
                    FSP.inventory_organization_id
         AND    PLI.line_type_id = PLT.line_type_id
         AND    PHI.vendor_id  = POV.vendor_id (+)
         AND    PLI.interface_header_id =
                    PHI.interface_header_id
/* Bug# 1638668, forward fix of 1549754 */
--changed by jbalakri  during testing of 1549754
       --AND    PRL.REQUISITION_LINE_ID =
       --       x_requisition_line_id
         AND    PRL.REQUISITION_LINE_ID <>
                        x_requisition_line_id
         AND PRL.requisition_line_id=PLI.requisition_line_id
--end of change for 1549754
    --Bug 4599140 (included the following OR condition so that the SQL works correctly
    --for null need by date)
         AND    ( ( to_char(PLI.need_by_date-(to_number(substr(to_char(PLI.need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS') =
                                  to_char(x_need_by_date-(to_number(substr(to_char(x_need_by_date,
                                  'DD-MM-YYYY HH24:MI:SS'),18, 2))/86400), 'DD-MM-YYYY HH24:MI:SS')
                                 )
                     OR
                     (PLI.need_by_date is NULL AND x_need_by_date is NULL)
                )
         --bug 1942696 hr_location changes to reflect the new view
         AND exists (select 'x'
                     from HR_LOCATIONS HRL
                     where PRL.deliver_to_location_id = HRL.location_id
                     and nvl(HRL.ship_to_location_id, HRL.location_id) = x_ship_to_location_id
                     UNION ALL
                     select 'x'
                     from HZ_LOCATIONS HZ
                     where PRL.deliver_to_location_id = HZ.location_id
                     and HZ.location_id = x_ship_to_location_id)
         AND    ROWNUM = 1
         ORDER BY shipment_num;
       END IF;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
                IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                        p_token    => l_progress,
                                        p_message  => 'NO_DATA_FOUND: '||SQLERRM);
                END IF;
                  x_po_shipment_num := -1;
           WHEN OTHERS THEN
                IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                    PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                       p_progress => l_progress);
                END IF;
             wrapup(x_interface_header_id);
             RAISE;
         END;

--end of change

   END IF; -- end of grouping
   --Bug 7312562
   --Moving this code to the end of the procedure.
   --So that the same logic is used for Drop shipments also.
   --Ensuring that two drop shipments are not inserted into same shipment,
   --by setting x_po_shipment_num := -1;
   IF g_document_type = 'PO' AND x_drop_ship_flag = 'Y' THEN
     x_po_shipment_num := -1;
   END IF;

     /* <Bug 14608120 Autocreate GE ER>
    	Do not group shipments if the req is wip enabled.*/
	   IF (is_wip_enabled(x_requisition_line_id)) THEN
	     l_progress := '200';
		 x_po_shipment_num := -1;
		 IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
		   PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
	                                   p_token    => l_progress,
									   p_message  => 'Req is WIP enabled ');
		 END IF;
	   END IF;

     /*<Bug 14608120 Autocreate GE ER>
	 14608120 Do not group shipments if the Group Shipments checkbox is checked.*/
	 l_progress := '210';

	 IF (x_group_shipments IS NULL) THEN
	     SELECT psp.group_shipments_flag
		 INTO l_group_shipments
		 FROM po_system_parameters_all psp
		 where NVL(psp.org_id, -99) = NVL(g_purchasing_ou_id, -99);
	 ELSE
	     l_group_shipments := x_group_shipments;
	 END IF;

	 IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
		   PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
	                                   p_token    => l_progress,
									   p_message  => 'l_group_shipments : '||l_group_shipments);
     END IF;

     IF (l_group_shipments = 'N' AND
	      ((g_document_type = 'PO' and (g_document_subtype='STANDARD' OR g_document_subtype='PLANNED')) OR
		  (g_document_subtype = 'RELEASE'))) THEN
       x_po_shipment_num := -1;
	 END IF;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress||'_main',
                             p_message  => 'NO_DATA_FOUND: '||SQLERRM);
     END IF;
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     po_message_s.sql_error('get_shipment_num',l_progress,sqlcode);
     wrapup(x_interface_header_id);
     raise;
END get_shipment_num;


/* ============================================================================
     NAME: UPDATE_SHIPMENT
     DESC: Update shipment information in interface table
     ARGS: x_interface_header_id IN number
     x_po_shipment_num IN number
     ALGR:
   ==========================================================================*/
PROCEDURE update_shipment(x_interface_header_id IN NUMBER,
         x_po_shipment_num IN number,
         x_po_line_num IN NUMBER,
         x_requisition_line_id IN NUMBER,
         x_po_line_id IN NUMBER,
               x_document_num IN VARCHAR2,
         x_release_num IN NUMBER,
                           x_create_new_line IN VARCHAR2,
                           x_row_id  IN VARCHAR2) IS
x_shipment_num NUMBER;
x_int_shipment_num NUMBER;
x_line_num NUMBER;
x_int_line_num NUMBER;
l_api_name CONSTANT VARCHAR2(30) := 'update_shipment';      --< Bug 3210331 >
l_progress VARCHAR2(3) := '000';                            --< Bug 3210331 >

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

      /* Shipment Exists */
      IF (x_po_shipment_num <> -1) THEN

         /*
         ** Shipment exists.
         ** A shipment associated with the purchase order
         ** line matches the requisition line information.
         */

        if x_requisition_line_id is not null then
         l_progress := '010';
         update po_lines_interface
            set shipment_num= x_po_shipment_num
          where interface_header_id=x_interface_header_id
            and requisition_line_id=x_requisition_line_id;

        else
         l_progress := '015';
          update po_lines_interface
            set shipment_num= x_po_shipment_num
          where interface_header_id=x_interface_header_id
            and rowid=x_row_id;
        end if;

      ELSE /* Shipment does not exist */

         /*
         ** Get the maximum shipment number in the po tables
         */
         l_progress := '020';

   IF (g_document_subtype = 'STANDARD'
    OR g_document_subtype = 'PLANNED' OR
             g_document_type = 'RFQ')
   THEN

           /* GA FPI start : if create new line parameter is 'Y' then we need to reset
              the shipment number and create a new line with one shipment */

            IF nvl(x_create_new_line,'N') = 'Y' and g_document_subtype = 'STANDARD' THEN

               x_int_shipment_num := 0;
               x_shipment_num     := 0;

               -- Bug 2757020 START
               -- In Add mode, PLI.line_num is set to the existing document
               -- line number. We need to generate a new line number.
	       --Bug 6072900
	       -- while Auto Creating PO with req lines with same need by dates from DropShip Sales Order
	       -- the below condition is false for g_mode=NEW ,because of this req lines with same
               -- need-by-dates were combined into one line and one shipment .
	       -- So commented the below condition.

               --IF (g_mode = 'ADD') THEN
                  -- Set PLI.line_num to the largest line number in use + 1.

                  l_progress := '030';
                  select nvl(max(line_num),0)
                   into x_line_num
                   from po_headers_all ph,  --<Shared Proc FPJ>
                        po_lines_all pl  --<Shared Proc FPJ>
                  where pl.po_header_id = ph.po_header_id
                    and ph.segment1 = x_document_num
                    AND NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

                  l_progress := '040';
                  select nvl(max(line_num),0)
                   into x_int_line_num
                   from po_lines_interface pli
                  where pli.interface_header_id = x_interface_header_id;

                  IF (x_line_num >= x_int_line_num) THEN
                     x_line_num := x_line_num;
                  ELSE
                     x_line_num := x_int_line_num;
                  END IF;

                  l_progress := '050';
                  update po_lines_interface
                  set    line_num = x_line_num + 1
                  where  interface_header_id = x_interface_header_id
                  and    requisition_line_id = x_requisition_line_id;
               -- Bug 6072900
               --END IF;

               -- Bug 2757020 END

            /* GA FPI end */

            ELSE
               l_progress := '060';
               select nvl(max(shipment_num),0)
                 into x_shipment_num
                 from po_line_locations_all poll  --<Shared Proc FPJ>
                where poll.po_line_id = x_po_line_id
                  and poll.shipment_type in ('STANDARD', 'PLANNED', 'RFQ');

               -- Bug 605715, lpo, 01/05/98
               -- We now check to see if the line_num matches as well by
               -- appending an AND condition in the WHERE clause.

               l_progress := '070';
               /*
               ** Get the max shipment number already
               ** assigned in the interface table.
               */
               select nvl(max(shipment_num),0)
               into x_int_shipment_num
               from po_lines_interface pli
               where pli.interface_header_id = x_interface_header_id
               and pli.line_num = x_po_line_num;

              -- End of fix. Bug 605715, lpo, 01/05/98
            END IF; -- create new line

        ELSE
           l_progress := '080';

         select nvl(max(shipment_num),0)
         into   x_shipment_num
               from   po_headers_all ph,  --<Shared Proc FPJ>
                     po_line_locations_all poll,  --<Shared Proc FPJ>
                     po_releases_all pr  --<Shared Proc FPJ>
               where  ph.po_header_id = poll.po_header_id
               and    ph.segment1 = x_document_num
               and    pr.po_header_id = ph.po_header_id
               and    pr.release_num = x_release_num
               and    ph.type_lookup_code = 'BLANKET'
               and    poll.po_release_id=pr.po_release_id
               AND    NVL(pr.org_id, -99) = NVL(g_purchasing_ou_id, -99)  --<Shared Proc FPJ>
               AND    NVL(ph.org_id, -99) = NVL(g_purchasing_ou_id, -99);  --<Shared Proc FPJ>

               -- Bug 605715, lpo, 01/05/98
               -- For Releases, we don't care about the line_num.

               l_progress := '090';
               /*
               ** Get the max shipment number already
               ** assigned in the interface table.
               */
               select nvl(max(shipment_num),0)
               into x_int_shipment_num
               from po_lines_interface pli
               where pli.interface_header_id = x_interface_header_id;

               -- End of fix. Bug 605715, lpo, 01/05/98

   END IF;

         l_progress := '100';

         IF (x_shipment_num >= x_int_shipment_num) THEN
          x_shipment_num := x_shipment_num;
         ELSE
          x_shipment_num := x_int_shipment_num;
         END IF;

        if x_requisition_line_id is not null then
          l_progress := '110';
          update po_lines_interface
            set shipment_num = x_shipment_num + 1
          where interface_header_id=x_interface_header_id
            and requisition_line_id=x_requisition_line_id;
        else
          l_progress := '120';
          update po_lines_interface
            set shipment_num = x_shipment_num + 1
          where interface_header_id=x_interface_header_id
            and rowid=x_row_id;
        end if;

      END IF; /* Shipment Exists */

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                             p_token    => l_progress||'_main',
                             p_message  => 'NO_DATA_FOUND: '||SQLERRM);
     END IF;
  WHEN OTHERS THEN
     IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
         PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                            p_progress => l_progress);
     END IF;
     po_message_s.sql_error('update_shipment',l_progress,sqlcode);
     wrapup(x_interface_header_id);
     raise;

END update_shipment;

/* ============================================================================
     NAME: CALCULATE_LOCAL
     DESC: This procedure serve as a hook to the function of localization team.

   ==========================================================================*/

PROCEDURE CALCULATE_LOCAL(document_type varchar2,
                          level_type    varchar2,
                          level_id      number

) IS

  l_cursor         integer;
  sqlstmt          varchar2(2000);
  l_jl_installed   varchar2(30);
  l_execute        integer;
  l_return         number;
  l_progress VARCHAR2(3) := '000';                          --< Bug 3210331 >
  l_api_name CONSTANT VARCHAR2(30) := 'calculate_local';    --< Bug 3210331 >
BEGIN
 /* Bug4430300 Removed the references to the JL_BR packages */

  -- <Bug 8513167 START>
  -- Added call to JG_GLOBE_UTIL_PKG.process_po_globe_event

    IF g_debug_stmt THEN
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    ---------------------------------------------------
    -- Check whether the Regional Package is installed
    ---------------------------------------------------
    SELECT  DISTINCT 'Package Installed'
    INTO    l_jl_installed
    FROM    user_objects
    WHERE   object_name = 'JG_GLOBE_UTIL_PKG'
    AND     object_type = 'PACKAGE BODY';

    l_progress := '010';
    ---------------------------------------------------
    -- Execute dynamically the Regional Procedure
    ---------------------------------------------------
    sqlstmt := 'BEGIN  JG_GLOBE_UTIL_PKG.process_po_globe_event(:p_document_type,:p_level_type,:p_level_id);  END;';

    -- Create the SQL statement
    l_cursor := dbms_sql.open_cursor;

    l_progress := '020';

    -- Parse the SQL statement
    dbms_sql.parse (l_cursor, sqlstmt, dbms_sql.native);

    l_progress := '030';
    -- Define the variables
    dbms_sql.bind_variable(l_cursor, ':p_document_type', document_type);
    dbms_sql.bind_variable(l_cursor, ':p_level_type', level_type);
    dbms_sql.bind_variable(l_cursor, ':p_level_id', level_id);

    l_progress := '040';
    -- Execute the SQL statement
    l_execute := dbms_sql.execute(l_cursor);

    -- Get the return value (success)
    --  dbms_sql.variable_value(l_cursor, ':b_return', l_return);

    l_progress := '050';
    -- Close the cursor
    dbms_sql.close_cursor(l_cursor);

    IF g_debug_stmt THEN
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
  -- <Bug 8513167 END>
EXCEPTION

    WHEN no_data_found THEN

        ----------------------------------------
        -- Regional Procedure is not installed
        ----------------------------------------
        IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
            PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                                p_token    => l_progress,
                                p_message  => 'NO_DATA_FOUND: '||SQLERRM);
        END IF;

    --<Bug 3336920 START>
    WHEN OTHERS THEN

        IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
           PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                               p_progress => l_progress);
        END IF;
        RAISE;
    --<Bug 3336920 END>
END CALCULATE_LOCAL;

-- 2082757: Added this function:
/* ============================================================================
     NAME: SOURCE_BLANKET_LINE
     DESC: Return the line number of that BPO line which matches the
           sourcing candidature criterion.
     ARGS: IN: x_po_header_id NUMBER : header id of source blanket PO
           IN: x_requisition_line_id NUMBER : id of the corresponding req line.
           IN: x_interface_line_num NUMBER : number from lines interface table
           IN: x_allow_different_uoms VARCHAR2 : If not 'Y', require the
             matching BPA line to have the same UOM as the requisition line.
           IN: p_purchasing_ou_id NUMBER : purchasing operating unit id
     ALGR:
           - For One-time item, item description of the BPO line should match
             that of requisition line.  For others, both item_id and description
             should match.
           - If there is no BPO line matching the description, then just match
             the item_id.
           - For any case above, if more than one candidate BPO lines pass the
             conditions, then pick the one having the minimum line_num
     See Bug 2082757 for details.
  ===========================================================================*/

FUNCTION source_blanket_line(x_po_header_id IN NUMBER,
                             x_requisition_line_id IN NUMBER,
                             x_interface_line_num IN NUMBER,
                             x_allow_different_uoms IN VARCHAR2, -- Bug 2707576
                             p_purchasing_ou_id     IN NUMBER  --<Shared Proc FPJ>
                            ) RETURN NUMBER IS

    v_line_num NUMBER := null;
    x_item_id  number;
    x_inv_org_id  number;
    x_item_rev_control number := null;

   /* Bug: 2432506 Expriation of document should happen at the end of
           the expiration_date */
   /* Bug 3828673:Release was not created when the requisition line type is
      different from the source document line type.*/
  /* Bug 7492597 Added a condition to check for item description and category for one-time item
      so that valid GBPA line number is picked up for one-time item req line */
   /* Bug 9745707 : This bug was introduced because of Bug4541335 fix.

     As part of this fix,If the Req is being autocreated to a document/release to which it is already to Sourced to,
     then the Source Doc line number on Req was matched to the Current Doc line no,
     because of this, the system was nt picking up the valid blanket line in case the line to which Req was sourced to
     has expired.

     Modified the condition in such a way that If the Req is being autocreated to a document/release to which it is already to Sourced to,
     then
     1. take the line from the the Current Doc,which has  expiry date >= sysdate and it is same as the Source Doc line number on Req
     or
     2. the expiration date on the line should be greater than the need by date on the Req Line.

   */

    CURSOR c1 (p_po_header_id        IN NUMBER,
               p_requisition_line_id IN NUMBER,
               p_interface_line_num  IN NUMBER,
               p_item_rev_control    IN NUMBER,
               x_allow_different_uoms IN VARCHAR2 -- Bug 2707576
              ) IS
                            SELECT MIN(pol.line_num)
                            FROM  po_lines_all pol,
                                  po_requisition_lines_all prl  --<Shared Proc FPJ>
                            WHERE pol.po_header_id = p_po_header_id
                            AND   prl.requisition_line_id = p_requisition_line_id
                            AND   NVL(pol.cancel_flag,'N') = 'N'
                            AND   NVL(pol.closed_code,'OPEN') <> 'FINALLY CLOSED'
                            -- Bug 3828673 START
                            -- AND   pol.line_type_id = prl.line_type_id
                            AND   pol.order_type_lookup_code = prl.order_type_lookup_code
                            AND   pol.purchase_basis = prl.purchase_basis
                            AND   pol.matching_basis = prl.matching_basis
                            -- Bug 3828673 END
                            AND   nvl(pol.job_id,-999) = nvl(prl.job_id, -999) -- <SERVICES FPJ>
                            AND   ((pol.item_id = prl.item_id                        --bug 7492597
                                    and pol.item_description = prl.item_description
                                   )
                                   or (pol.item_id is null                                --bug 7492597 added for one-time item
                                       and prl.item_id is null                            --bug 7492597
                                       and pol.item_description = prl.item_description    --bug 7492597
                                       and pol.category_id = prl.category_id              --bug 7492597
                                       )
                                   )
                            AND   ((pol.item_revision IS NULL
                                   and prl.item_revision IS NULL)
                                   or  pol.item_revision = prl.item_revision
                                   or  (prl.item_revision is null  and p_item_rev_control = 1))
                            AND   (pol.transaction_reason_code IS NULL
                                   or pol.transaction_reason_code =
                                   NVL(prl.transaction_reason_code,
                                                pol.transaction_reason_code))
                             -- Bug 9745707 starts
				  AND   NVL(P_INTERFACE_LINE_NUM,POL.LINE_NUM) =  POL.LINE_NUM
                             AND ((---  CASE 1 : REQ IS NT SOURCED TO ANY DOC
                                   ( (PRL.BLANKET_PO_LINE_NUM IS NULL)						-- Bug 16013325 . Added extra open parenthesis.
                                        OR
                                     ---  CASE 2 : REQ IS  SOURCED TO A DOC OTHER THAN THE CURRENT ONE
                                    (PRL.BLANKET_PO_LINE_NUM IS NOT NULL AND  PRL.BLANKET_PO_HEADER_ID <> P_PO_HEADER_ID) )	-- Bug 16013325 . Added extra open parenthesis.
                                    -- IN CASE 1 AND 2, VALIDATE THE EXPIRY DATE WITH NEED BY DATE
                                    AND TRUNC(NVL(POL.EXPIRATION_DATE,SYSDATE + 1)) >= TRUNC(DECODE(POL.EXPIRATION_DATE,NULL,SYSDATE,NVL(PRL.NEED_BY_DATE,SYSDATE)))
                                    )
                                    OR
                                    --- CASE 3 : REQ IS ALREADY SOURCED TO THE DOCUMENT(CUURENT DOC)
                                    (PRL.BLANKET_PO_LINE_NUM IS NOT NULL AND  PRL.BLANKET_PO_HEADER_ID = P_PO_HEADER_ID
                                      -- IF THE REQ IS SOURCED TO THE DOC AND THE ALREADY SOURCED LINE IS VALID
                                    AND ((TRUNC(NVL(POL.EXPIRATION_DATE,SYSDATE + 1)) >= TRUNC(SYSDATE) AND PRL.BLANKET_PO_LINE_NUM = POL.LINE_NUM)
                                    -- IF THE REQ IS SOURCED TO THE DOC,BUT THE ALREADY SOURCED LINE IS INVALID,THEN TAKE THE OTHER VALID LINE FROM SOURCE DOCUMENT
                                    --OR TRUNC(NVL(POL.EXPIRATION_DATE,SYSDATE + 1)) >= TRUNC(DECODE(POL.EXPIRATION_DATE,NULL,SYSDATE, NVL(PRL.NEED_BY_DATE,SYSDATE))) ) --13876074
                                    --Bug 13876074, ensure to pick another source line
                                    --only if the current source line reference is not valid.
                                        OR ((NOT EXISTS (SELECT 1 FROM po_lines_all pol2
                                                      WHERE pol2.po_header_id = pol.po_header_id
                                                        AND TRUNC(NVL(pol2.expiration_date,SYSDATE + 1))
                                                            >= TRUNC(SYSDATE)
                                                        AND prl.blanket_po_line_num  = pol2.line_num))
                                             AND TRUNC(NVL(pol.expiration_date,SYSDATE + 1))
                                                 >= TRUNC(DECODE(pol.expiration_date,NULL,SYSDATE,
                                                                 NVL(prl.need_by_date,SYSDATE))))
                                       ) --end bug 13876074
                                    )
                              )

                            /*Bug4541335  AND   nvl(p_interface_line_num,pol.line_num) =
                                                                     pol.line_num
                            AND   trunc(nvl(pol.expiration_date,sysdate+1))
                                                                >= trunc(sysdate)
         Bug4541335 start
       AND (p_InterFace_Line_num = pol.Line_num
             OR (p_InterFace_Line_num IS NULL
                 AND prl.Blanket_po_Header_Id = p_po_Header_Id
                 AND prl.Blanket_po_Line_num = pol.Line_num)
             OR (p_InterFace_Line_num IS NULL
                 AND (prl.Blanket_po_Header_Id <> p_po_Header_Id
                       OR prl.Blanket_po_Line_num IS NULL )))
       AND (((p_InterFace_Line_num IS NOT NULL
               OR (prl.Blanket_po_Header_Id = p_po_Header_Id
                   AND prl.Blanket_po_Line_num = pol.Line_num))
             AND Trunc(Nvl(pol.Expiration_Date,SYSDATE + 1)) >= Trunc(SYSDATE))
             OR ((p_InterFace_Line_num IS NULL
                  AND (prl.Blanket_po_Header_Id <> p_po_Header_Id
                        OR prl.Blanket_po_Line_num IS NULL ))
                 AND Trunc(Nvl(pol.Expiration_Date,SYSDATE + 1)) >= Trunc(DECODE(pol.Expiration_Date,NULL,SYSDATE,
                                                                                                     Nvl(prl.Need_By_Date,SYSDATE)))))
           Bug4541335 End */
	    -- Bug 9745707 ends

           -- Bug 2707576 Start
           -- Require the BPA and req to have the same UOM
           -- if x_allow_different_uoms is not 'Y'.
        AND   (   (  NVL(POL.unit_meas_lookup_code,chr(0)) =
                                         decode ( x_allow_different_uoms,'Y',
                                                  NVL(POL.unit_meas_lookup_code,chr(0)),
                                                  PRL.unit_meas_lookup_code)
                                      )                       -- <SERVICES FPJ>
                                  OR  (   ( POL.unit_meas_lookup_code IS NULL )
                                      AND ( PRL.unit_meas_lookup_code IS NULL ) )
                                  );

                            -- Bug 2707576 End

   /* Bug: 2432506 Expriation of document should happen at the end of
           the expiration_date */
   /* Bug 3828673:Release was not created when the requisition line type is
      different from the source document line type.*/
   /* Bug 7492597 Added a condition to check for item description and category for one-time item
      so that valid GBPA line number is picked up for one-time item req line */

    CURSOR c2 (p_po_header_id        IN NUMBER,
               p_requisition_line_id IN NUMBER,
               p_interface_line_num  IN NUMBER,
               p_item_rev_control    IN NUMBER,
               x_allow_different_uoms IN VARCHAR2 -- Bug 2707576
              ) IS
                            SELECT MIN(pol.line_num)
                            FROM  po_lines_all pol,
                                  po_requisition_lines_all prl  --<Shared Proc FPJ>
                            WHERE pol.po_header_id = p_po_header_id
                            AND   prl.requisition_line_id = p_requisition_line_id
                            AND   NVL(pol.cancel_flag,'N') = 'N'
                            AND   NVL(pol.closed_code,'OPEN') <> 'FINALLY CLOSED'
                            -- Bug 3828673 START
                            -- AND   pol.line_type_id = prl.line_type_id
                            AND   pol.order_type_lookup_code = prl.order_type_lookup_code
                            AND   pol.purchase_basis = prl.purchase_basis
                            AND   pol.matching_basis = prl.matching_basis
                            -- Bug 3828673 END
                            AND   nvl(pol.job_id,-999) = nvl(prl.job_id, -999) -- <SERVICES FPJ>
                            AND   (   ( POL.item_id = PRL.item_id ) -- <SERVICES FPJ>
                                  OR  (   ( POL.item_id IS NULL )
                                      AND ( PRL.item_id IS NULL )
                                      AND ( POL.item_description = PRL.item_description )
                                      AND ( POL.category_id = PRL.category_id) )   --bug 7492597
                                  )
                            AND   ((pol.item_revision IS NULL
                                   and prl.item_revision IS NULL)
                                   or  pol.item_revision = prl.item_revision
                                   or  (prl.item_revision is null  and p_item_rev_control = 1))
                            AND   (pol.transaction_reason_code IS NULL
                                   or pol.transaction_reason_code =
                                   NVL(prl.transaction_reason_code,
                                                pol.transaction_reason_code))

                             -- Bug 9745707 starts
				  AND   NVL(P_INTERFACE_LINE_NUM,POL.LINE_NUM) =  POL.LINE_NUM
                             AND ((---  CASE 1 : REQ IS NT SOURCED TO ANY DOC
                                   ( (PRL.BLANKET_PO_LINE_NUM IS NULL)							-- Bug 16013325 . Added extra open parenthesis.
                                        OR
                                     ---  CASE 2 : REQ IS  SOURCED TO A DOC OTHER THAN THE CURRENT ONE
                                    (PRL.BLANKET_PO_LINE_NUM IS NOT NULL AND  PRL.BLANKET_PO_HEADER_ID <> P_PO_HEADER_ID) )  -- Bug 16013325 . Added extra close parenthesis.
                                    -- IN CASE 1 AND 2, VALIDATE THE EXPIRY DATE WITH NEED BY DATE
                                    AND TRUNC(NVL(POL.EXPIRATION_DATE,SYSDATE + 1)) >= TRUNC(DECODE(POL.EXPIRATION_DATE,NULL,SYSDATE,NVL(PRL.NEED_BY_DATE,SYSDATE)))
                                    )
                                    OR
                                    --- CASE 3 : REQ IS ALREADY SOURCED TO THE DOCUMENT(CUURENT DOC)
                                    (PRL.BLANKET_PO_LINE_NUM IS NOT NULL AND  PRL.BLANKET_PO_HEADER_ID = P_PO_HEADER_ID
                                      -- IF THE REQ IS SOURCED TO THE DOC AND THE ALREADY SOURCED LINE IS VALID
                                    AND ((TRUNC(NVL(POL.EXPIRATION_DATE,SYSDATE + 1)) >= TRUNC(SYSDATE) AND PRL.BLANKET_PO_LINE_NUM = POL.LINE_NUM)
                                    -- IF THE REQ IS SOURCED TO THE DOC,BUT THE ALREADY SOURCED LINE IS INVALID,THEN TAKE THE OTHER VALID LINE FROM SOURCE DOCUMENT
                                      --OR TRUNC(NVL(POL.EXPIRATION_DATE,SYSDATE + 1)) >= TRUNC(DECODE(POL.EXPIRATION_DATE,NULL,SYSDATE,NVL(PRL.NEED_BY_DATE,SYSDATE))) ) --13876074
                                    --Bug 13876074, ensure to pick another source line
                                    --only if the current source line reference is not valid.
                                        OR ((NOT EXISTS (SELECT 1 FROM po_lines_all pol2
                                                      WHERE pol2.po_header_id = pol.po_header_id
                                                        AND TRUNC(NVL(pol2.expiration_date,SYSDATE + 1))
                                                            >= TRUNC(SYSDATE)
                                                        AND prl.blanket_po_line_num  = pol2.line_num))
                                             AND TRUNC(NVL(pol.expiration_date,SYSDATE + 1))
                                                 >= TRUNC(DECODE(pol.expiration_date,NULL,SYSDATE,
                                                                 NVL(prl.need_by_date,SYSDATE))))
                                       ) --end bug 13876074

                                    )
                              )


                            /*Bug4541335  AND   nvl(p_interface_line_num,pol.line_num) =
                                                                     pol.line_num
                            AND   trunc(nvl(pol.expiration_date,sysdate+1))
                                                                >= trunc(sysdate)

       AND (p_InterFace_Line_num = pol.Line_num
             OR (p_InterFace_Line_num IS NULL
                 AND prl.Blanket_po_Header_Id = p_po_Header_Id
                 AND prl.Blanket_po_Line_num = pol.Line_num)
             OR (p_InterFace_Line_num IS NULL
                 AND (prl.Blanket_po_Header_Id <> p_po_Header_Id
                       OR prl.Blanket_po_Line_num IS NULL )))
       AND (((p_InterFace_Line_num IS NOT NULL
               OR (prl.Blanket_po_Header_Id = p_po_Header_Id
                   AND prl.Blanket_po_Line_num = pol.Line_num))
             AND Trunc(Nvl(pol.Expiration_Date,SYSDATE + 1)) >= Trunc(SYSDATE))
             OR ((p_InterFace_Line_num IS NULL
                  AND (prl.Blanket_po_Header_Id <> p_po_Header_Id
                        OR prl.Blanket_po_Line_num IS NULL ))
                 AND Trunc(Nvl(pol.Expiration_Date,SYSDATE + 1)) >= Trunc(DECODE(pol.Expiration_Date,NULL,SYSDATE,
                                                                                                     Nvl(prl.Need_By_Date,SYSDATE)))))
           Bug4541335 End */

	    -- Bug 9745707 ends
                            -- Bug 2707576 Start
                            -- Require the BPA and req to have the same UOM
                            -- if x_allow_different_uoms is not 'Y'.
                            AND   (   (  NVL(POL.unit_meas_lookup_code,chr(0)) =
                                         decode ( x_allow_different_uoms,'Y',
                                                  NVL(POL.unit_meas_lookup_code,chr(0)),
                                                  PRL.unit_meas_lookup_code)
                                      )                       -- <SERVICES FPJ>
                                  OR  (   ( POL.unit_meas_lookup_code IS NULL )
                                      AND ( PRL.unit_meas_lookup_code IS NULL ) )
                                  );
                            -- Bug 2707576 End

BEGIN

     /* bug 2315931 : when creating a release , if the requisition does not
       have a revision and the item is not revision controlled then we can
       match it to the blanket with a revision. For this added the additional
       clause in the cursors for the item revision matching */

      begin
       SELECT   inventory_organization_id
       INTO     x_inv_org_id
         FROM   financials_system_params_all  --<Shared Proc FPJ>
        WHERE   NVL(org_id, -99) = NVL(p_purchasing_ou_id, -99);  --<Shared Proc FPJ>

       select item_id
       into x_item_id
       from po_requisition_lines_all  --<Shared Proc FPJ>
       where requisition_line_id = x_requisition_line_id;

     if x_item_id is not null then
       SELECT   msi.revision_qty_control_code
       INTO     x_item_rev_control
       FROM     mtl_system_items msi
       WHERE    msi.inventory_item_id = x_item_id
       AND      msi.organization_id = x_inv_org_id;
     end if;

      exception
       when no_data_found then
         null;
     end;
        -- Get the first BPO line having the same item_id AND description
        -- as that of requisition line.
        OPEN c1(x_po_header_id, x_requisition_line_id, x_interface_line_num,x_item_rev_control,
                x_allow_different_uoms -- Bug 2707576
               );

        FETCH c1 INTO v_line_num;

        IF c1%NOTFOUND  OR v_line_num IS NULL THEN
                -- Get the first BPO line having the same item_id as
                -- that of requisition line, ignoring the description.
                OPEN  c2(x_po_header_id,
                         x_requisition_line_id,
                         x_interface_line_num,
                         x_item_rev_control,
                         x_allow_different_uoms -- Bug 2707576
                        );
                FETCH c2 INTO v_line_num;
                CLOSE c2;
        END IF;
        CLOSE c1;
        RETURN v_line_num;

EXCEPTION
        WHEN OTHERS THEN RETURN -1;

END source_blanket_line;

--<RENEG BLANKET FPI START>
/*============================================================================
Name      :     CREATE_PRICE_BREAK
Type      :     Private
Function  :     This procedure is called from 'create_line'. This procedure inserts
                records from po_lines_interface table to po_line_locations_all table
                for the price break information.
Pre-req   :     None
Parameters:
IN        :     p_po_line_id            IN      NUMBER  REQUIRED
OUT       :     x_line_location_id      OUT     NOCOPY
==============================================================================*/
PROCEDURE CREATE_PRICE_BREAK(p_po_line_id IN number,
                             x_line_location_id OUT NOCOPY number,
                 p_outsourced_assembly IN NUMBER --<SHIKYU R12>
) IS

l_row_id            varchar2(18) := NULL;
l_progress          varchar2(3) := '000';            --< Bug 3210331 >
l_api_name VARCHAR2(30) := 'create_price_break';      --< Bug 3210331, 3336920 >
unexpected_create_pb_err   EXCEPTION;

l_ship_org_id_line  mtl_system_items.organization_id%type;
l_ship_org_code       varchar2(3);
l_ship_org_name     varchar2(60);

l_value_basis   PO_LINES_ALL.order_type_lookup_code%TYPE; -- <Complex Work R12>

BEGIN
    -- Standard start of API savepoint
    SAVEPOINT       create_price_break_pvt;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    begin
       SELECT po_line_locations_s.nextval
          INTO x_line_location_id
          FROM sys.dual;
    exception
        when others then
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            po_message_s.sql_error('Exception of create_price_break()', l_progress,sqlcode);
            FND_MSG_PUB.Add;
            RAISE unexpected_create_pb_err;
    end;

    l_progress := '010';
    -- Check that price break ship_to_organization_id and ship_to_location_id match
    -- (if both are provided)
    if (interface.line_ship_to_org_id is not NULL and
        interface.line_ship_to_loc_id is not NULL and params.sob_id is not NULL) then
        po_locations_s.get_loc_org(interface.line_ship_to_loc_id,
                                   params.sob_id,
                                   l_ship_org_id_line,
                                   l_ship_org_code,
                                   l_ship_org_name);
        -- if the orgs do match raise an error
  if (l_ship_org_id_line <> interface.line_ship_to_org_id) then
            --Create an error code 4 for price break ship_to_loc and ship_to_org do not match
            g_sourcing_errorcode := 3;
           -- raise;
        end if;
    end if; /*check ship_loc and ship_org */

    l_progress := '020';
    --Call the row handler for po_line_location9in file POXP1PSB.pls to insert the row

    -- <Complex Work R12 Start>
    -- Get value basis from line

    SELECT pol.order_type_lookup_code
    INTO l_value_basis
    FROM po_lines_all pol
    WHERE pol.po_line_id = p_po_line_id;

    l_progress := '025';

    -- <Complex Work R12 End>


    begin
      po_line_locations_pkg_s0.insert_row(
                       l_row_id,
                       x_Line_Location_Id,
                       interface.last_update_date,
                       interface.last_updated_by,
                       interface.Po_Header_Id,
                       p_po_Line_Id,
                       interface.Last_Update_Login,
                       interface.creation_Date,
                       interface.created_By,
                       interface.quantity,
                       0, --quantity_received
                       0, --Quantity_Accepted
                       0, --Quantity_Rejected
                       0, --Quantity_Billed
                       0, --Quantity_Cancelled,
                       interface.unit_meas_lookup_code, --unit of measure
                       NULL, -- release_id
                       interface.line_Ship_To_Loc_Id,
                       interface.Ship_Via_Lookup_Code,
                       NULL, --Need_By_Date
                       NULL, --Promised_Date
                       NULL, --Last_Accept_Date
           interface.unit_price, --Price_override
                       'N', --Encumbered flag
                       NULL, --Encumbered_Date
                       NULL, --Fob_Lookup_Code
                       NULL, --Freight_Terms_Lookup_Code
                       'N', --Taxable_Flag
                       NULL, --Tax_Code_Id
                       'N', --Tax_User_Override_Flag
                       NULL, --Calculate_Tax_Flag
                       NULL, --X_From_Header_Id
                       NULL, --X_From_Line_Id
                       NULL, --X_From_Line_Location_Id
                       interface.line_effective_date, --X_Start_Date
                       interface.line_expiration_date, --X_End_Date
                       NULL, --X_Lead_Time,
                       NULL, --X_Lead_Time_Unit,
                       interface.Price_Discount,
                       interface.Terms_Id,
                       NULL, --X_Approved_Flag,
                       NULL, --X_Approved_Date,
                       'N', --X_Closed_Flag,
                       'N', --X_Cancel_Flag,
                       NULL, --X_Cancelled_By,
                       NULL, --X_Cancel_Date,
                       NULL, --X_Cancel_Reason,
                       'N', --X_Firm_Status_Lookup_Code,
                       NULL, --X_Attribute_Category,
                       NULL, --X_Attribute1,
                       NULL, --X_Attribute2,
                       NULL, --X_Attribute3,
                       NULL, --X_Attribute4,
                       NULL, --X_Attribute5,
                       NULL, --X_Attribute6,
                       NULL, --X_Attribute7,
                       NULL, --X_Attribute8,
                       NULL, --X_Attribute9,
                       NULL, --X_Attribute10,
                       NULL, --X_Attribute11,
                       NULL, --X_Attribute12,
                       NULL, --X_Attribute13,
                       NULL, --X_Attribute14,
                       NULL, --X_Attribute15,
                       'N', --X_Inspection_Required_Flag,
                       'N', --X_Receipt_Required_Flag,
                       NULL, --X_Qty_Rcv_Tolerance,
                       NULL, --X_Qty_Rcv_Exception_Code,
                       'NONE', --X_Enforce_Ship_To_Location,
                       NULL, --X_Allow_Substitute_Receipts,
                       NULL, --X_Days_Early_Receipt_Allowed,
                       NULL, --X_Days_Late_Receipt_Allowed,
                       NULL, --X_Receipt_Days_Exception_Code,
                       NULL, --X_Invoice_Close_Tolerance,
                       NULL, --X_Receive_Close_Tolerance,
                       interface.line_Ship_To_Org_Id,
                       interface.Shipment_Num,
                       NULL, --X_Source_Shipment_Id,
                       interface.Shipment_Type,
                       'OPEN', --X_Closed_Code,
                       NULL, --
                       NULL, --X_Government_Context,
                       NULL, --X_Receiving_Routing_Id,
                       NULL, --X_Accrue_On_Receipt_Flag,
                       NULL, --X_Closed_Reason,
                       NULL, --X_Closed_Date,
                       NULL, --X_Closed_By,
                       NULL, --X_Global_Attribute_Category,
                       NULL, --X_Global_Attribute1,
                       NULL, --X_Global_Attribute2,
                       NULL, --X_Global_Attribute3,
                       NULL, --X_Global_Attribute4,
                       NULL, --X_Global_Attribute5,
                       NULL, --X_Global_Attribute6,
                       NULL, --X_Global_Attribute7,
                       NULL, --X_Global_Attribute8,
                       NULL, --X_Global_Attribute9,
                       NULL, --X_Global_Attribute10,
                       NULL, --X_Global_Attribute11,
                       NULL, --X_Global_Attribute12,
                       NULL, --X_Global_Attribute13,
                       NULL, --X_Global_Attribute14,
                       NULL, --X_Global_Attribute15,
                       NULL, --X_Global_Attribute16,
                       NULL, --X_Global_Attribute17,
                       NULL, --X_Global_Attribute18,
                       NULL, --X_Global_Attribute19,
                       NULL, --X_Global_Attribute20,
                       NULL, --X_Country_of_Origin_Code,
                       'P', --invoice option
                       l_value_basis,   -- <Complex Work R12>
                       NULL,            -- <Complex Work R12>: matching basis
                       NULL, --X_note_to_receiver,
                       NULL, --X_Secondary_Unit_Of_Measure,
                       NULL, --X_Secondary_Quantity,
                       NULL, --X_Preferred_Grade,
                       NULL, --X_Secondary_Quantity_Received,
                       NULL, --X_Secondary_Quantity_Accepted,
                       NULL, --X_Secondary_Quantity_Rejected,
                       NULL, --X_Secondary_Quantity_Cancelled,
                       NULL,            --X_Consigned_Flag    -- <SERVICES FPJ>
                       interface.amount, --X_Amount            -- <SERVICES FPJ>
                       NULL, -- p_transaction_flow_header_id
                       NULL, -- p_manual_price_change_flag
           interface.org_id                      -- <R12 MOAC>
           ,p_outsourced_assembly --<SHIKYU R12>
                       );

        l_progress := '030';
        -- <SERVICES FPJ START> Insert Price Break Price Differentials into
        -- main table from the interface table.
        --
        PO_PRICE_DIFFERENTIALS_PVT.create_from_interface
        (   p_entity_id         => x_line_location_id
        ,   p_interface_line_id => interface.interface_line_id
        );
        -- <SERVICES FPJ END>

      exception
        when others then
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            po_message_s.sql_error('Exception of create_price_break()', l_progress, sqlcode);
            FND_MSG_PUB.Add;
            RAISE unexpected_create_pb_err;
      end;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION
        when unexpected_create_pb_err then
            RAISE; --Bug 3336920
            --ROLLBACK to create_price_break_pvt;
        when others then
            IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
                PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                                   p_progress => l_progress);
            END IF;
            --ROLLBACK to create_price_break_pvt;
            RAISE; --Bug 3336920
END CREATE_PRICE_BREAK;
--<RENEG BLANKET FPI END>

-- <Complex Work R12 Start>: Added logging; cleaned tabbing.
FUNCTION get_ship_to_loc(p_deliver_to_loc_id IN NUMBER)
RETURN NUMBER
IS

  l_ship_to_location_id  NUMBER;
  l_found BOOLEAN := FALSE;

  d_module VARCHAR2(70) := 'po.plsql.PO_INTERFACE_S.get_ship_to_loc';
  d_progress NUMBER;

BEGIN

  d_progress := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_deliver_to_loc_id', p_deliver_to_loc_id);
  END IF;

  d_progress := 10;

  BEGIN
/*Bug 8763609 : When HR: Business Group is set to some value and
    HR Cross business Group is set to Y, then autocreate was failing
    because the 2 sqls below were returning no rows.Instead of using the
    views , we need to use _all tables to get the ship to location id.  */
    SELECT NVL(hrl.ship_to_location_id, hrl.location_id)
    INTO l_ship_to_location_id
    FROM hr_locations_all hrl --bug 8763609
    WHERE hrl.location_id = p_deliver_to_loc_id;

    l_found := TRUE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'No data found in hr_locations.');
      END IF;
  END;

  d_progress := 20;

  IF (NOT l_found) THEN

    BEGIN

      SELECT hzl.location_id
      INTO l_ship_to_location_id
      FROM hz_locations hzl
      WHERE hzl.location_id = p_deliver_to_loc_id;

      l_found := TRUE;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_progress, 'No data found in hz_locations.');
        END IF;
    END;

  END IF;  -- if not l_found

  IF (NOT l_found) THEN
    RAISE NO_DATA_FOUND;
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_return(d_module, l_ship_to_location_id);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN l_ship_to_location_id;

EXCEPTION
  WHEN OTHERS THEN
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
    END IF;
    wrapup(interface.interface_header_id);
    RAISE;
END;
-- <Complex Work R12 End>

--<CONFIG_ID FPJ START>

----------------------------------------------------------------------------
--Start of Comments
--Name: validate_interface_records
--Pre-reqs:
--  None
--Modifies:
--  None
--Locks:
--  None
--Function:
--  Performs various validations on the interface records.
--Parameters:
--IN:
--p_interface_header_id
--  header ID of the interface records to check
--Returns:
--  TRUE if the interface records pass all the validations;
--  FALSE otherwise.
--Testing:
--  None
--End of Comments
----------------------------------------------------------------------------

FUNCTION validate_interface_records (
  p_interface_header_id IN PO_HEADERS_INTERFACE.interface_header_id%TYPE
) RETURN BOOLEAN IS

  l_api_name CONSTANT VARCHAR2(30) := 'validate_interface_records';
  l_pass_validations BOOLEAN;

BEGIN

  l_pass_validations := validate_config_id(p_interface_header_id);
  RETURN l_pass_validations;

END validate_interface_records;


----------------------------------------------------------------------------
--Start of Comments
--Name: validate_config_id
--Pre-reqs:
--  g_document_type and g_document_subtype should have been set.
--Modifies:
--  None
--Locks:
--  None
--Function: Verifies that Config ID lines are only placed on the Standard PO
--  document type.
--Parameters:
--IN:
--p_interface_header_id
--  header ID of the interface records to check
--Returns:
--  TRUE if the document type is Standard PO, or if none of the lines have
--  Config ID; FALSE otherwise.
--Testing:
--  None
--End of Comments
----------------------------------------------------------------------------

FUNCTION validate_config_id (
  p_interface_header_id IN PO_HEADERS_INTERFACE.interface_header_id%TYPE
) RETURN BOOLEAN IS

  l_api_name CONSTANT VARCHAR2(30) := 'validate_config_id';
  l_num_config_id_lines NUMBER;
  l_progress VARCHAR2(3) := '000';              --< Bug 3210331 >

BEGIN

  IF (g_document_type = 'PO' AND g_document_subtype = 'STANDARD') THEN
    RETURN TRUE; -- The lines are being placed on a Standard PO.
  END IF;

  SELECT count(*)
  INTO l_num_config_id_lines
  FROM po_lines_interface PLI, po_requisition_lines PRL
  WHERE PLI.interface_header_id = p_interface_header_id
  AND PLI.requisition_line_id = PRL.requisition_line_id -- JOIN
  AND PRL.supplier_ref_number IS NOT NULL;

  IF (l_num_config_id_lines = 0) THEN
    RETURN TRUE; -- None of the lines have Config ID.
  ELSE
    l_progress := '010';
    -- We do not allow req lines with Config ID to be placed on any document type
    -- other than Standard PO.
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                            p_token    => l_progress,
                            p_message  => FND_MESSAGE.get_string('PO','PO_CONFIG_ID_ONLY_ON_STD_PO'));
    END IF;
    RETURN FALSE;
  END IF;

EXCEPTION

  WHEN OTHERS THEN
    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                           p_progress => l_progress);
    END IF;
    wrapup(p_interface_header_id);
    RAISE;

END validate_config_id;

--<CONFIG_ID FPJ END>


--<GRANTS FPJ START>
----------------------------------------------------------------------------
--Start of Comments
--Name: update_award_distributions
--Pre-reqs:
--  None
--Modifies:
--  PO_DISTRIBUTIONS_INTERFACE
--  GMS_AWARD_DISTRIBUTIONS
--Locks:
--  None
--Function:
--  Calls Grants Accounting API to create new award distributions lines
--  when a requisition with distributions that reference awards is
--  autocreated into a PO.
--Parameters:
--  <Complex Work R12>: Add p_table_type and p_po_line_id
--  p_table_type
--    'INTERFACE' - query/update interface tables (default)
--    'ALL - query/update _ALL tables
--  p_po_line_id
--    Only necessary if p_table_type = 'ALL', this is the line for
--    which to update the award distributions for.
--Returns:
--  None
--Testing:
--  None
--End of Comments
----------------------------------------------------------------------------

PROCEDURE update_award_distributions(
  p_table_type   IN   VARCHAR2   DEFAULT 'INTERFACE'
, p_po_line_id   IN   NUMBER     DEFAULT NULL
)
IS

  l_api_name     CONSTANT VARCHAR(30) := 'update_award_distributions';
  l_return_status        VARCHAR2(1);
  l_progress           VARCHAR2(4) := '000';              --< Bug 3210331 >
  l_gms_po_interface_obj gms_po_interface_type;
  l_msg_count          NUMBER;
  l_msg_data           VARCHAR2(2000);
  l_msg_buf              VARCHAR2(2000);

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

    -- <Complex Work R12 Start>
    IF (p_table_type = 'ALL') THEN

      --SQL WHAT: For distributions with award_id references, select
      --          the columns that Grants needs from the
      --          po_distributions_all table
      --SQL WHY : Needed to call GMS API to update award distribution
      --          lines table.

      SELECT pod.po_distribution_id,
             pod.distribution_num,
             pod.project_id,
             pod.task_id,
             pod.award_id,
             NULL
      BULK COLLECT INTO
             l_gms_po_interface_obj.distribution_id,
             l_gms_po_interface_obj.distribution_num,
             l_gms_po_interface_obj.project_id,
             l_gms_po_interface_obj.task_id,
             l_gms_po_interface_obj.award_set_id_in,
             l_gms_po_interface_obj.award_set_id_out
      FROM po_distributions_all pod
      WHERE pod.po_line_id = p_po_line_id
        AND pod.award_id IS NOT NULL;

    ELSE

      --SQL WHAT: For distributions with award_id references, select
      --          the columns that Grants needs from the
      --          po_distributions_interface table
      --SQL WHY : Need to call GMS API to update award distribution
      --          lines table.

      SELECT po_distribution_id,
             distribution_num,
             project_id,
             task_id,
             award_id,
             NULL
      BULK COLLECT INTO
             l_gms_po_interface_obj.distribution_id,
             l_gms_po_interface_obj.distribution_num,
             l_gms_po_interface_obj.project_id,
             l_gms_po_interface_obj.task_id,
             l_gms_po_interface_obj.award_set_id_in,
             l_gms_po_interface_obj.award_set_id_out
      FROM PO_DISTRIBUTIONS_INTERFACE
      WHERE interface_header_id = interface.interface_header_id
            AND interface_line_id = interface.interface_line_id
            AND award_id IS NOT NULL;

    END IF;  -- if p_table_type = 'ALL'
    -- <Complex Work R12 End>

    IF SQL%NOTFOUND THEN
      RETURN;
    END IF;


    l_progress := '010';

    --Create new award distribution lines in GMS_AWARDS_DISTRIBUTIONS table
    PO_GMS_INTEGRATION_PVT.maintain_adl (
          p_api_version           => 1.0,
          x_return_status         => l_return_status,
          x_msg_count             => l_msg_count,
          x_msg_data              => l_msg_data,
          p_caller                => 'AUTOCREATE',
          x_po_gms_interface_obj  => l_gms_po_interface_obj);

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    l_progress := '020';

    -- <Complex Work R12 Start>
    IF (p_table_type = 'ALL') THEN

      --SQL WHAT: Update po_distributions_all table with the new
      --          award_id's
      --SQL WHY : award_id's in PO tables need to be synchronized with
      --          award_id's in GMS tables.

      FORALL i IN 1..l_gms_po_interface_obj.distribution_id.COUNT
          UPDATE po_distributions_all
          SET award_id =
                l_gms_po_interface_obj.award_set_id_out(i)
          WHERE po_distribution_id =
                l_gms_po_interface_obj.distribution_id(i);

    ELSE

      --SQL WHAT: Update po_distributions_interface table with the new
      --          award_id's
      --SQL WHY : award_id's in PO tables need to be synchronized with
      --          award_id's in GMS tables.

      FORALL i IN 1..l_gms_po_interface_obj.distribution_id.COUNT
          UPDATE po_distributions_interface
          SET award_id = l_gms_po_interface_obj.award_set_id_out(i)
          WHERE po_distribution_id = l_gms_po_interface_obj.distribution_id(i);

    END IF; -- if p_table_type = 'ALL'
    -- <Complex Work R12 End>

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION

  WHEN FND_API.G_EXC_ERROR THEN
    IF FND_MSG_PUB.check_msg_level(
         p_message_level => FND_MSG_PUB.g_msg_lvl_unexp_error) THEN
      FND_MSG_PUB.add_exc_msg( p_pkg_name => G_PKG_NAME,
                               p_procedure_name => l_api_name);
    END IF;

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >

       FOR i IN 1..FND_MSG_PUB.count_msg LOOP
          l_msg_buf := SUBSTRB(FND_MSG_PUB.get(p_msg_index => i,
                                               p_encoded   => FND_API.G_FALSE),
                               1, 2000);
          PO_DEBUG.debug_stmt(p_log_head => g_log_head||l_api_name,
                              p_token    => l_progress,
                              p_message  => 'EXCEPTION: '|| l_msg_buf);
       END LOOP;

    END IF;
    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;

  WHEN OTHERS THEN
    IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                           p_progress => l_progress);
    END IF;
    IF FND_MSG_PUB.check_msg_level(
         p_message_level => FND_MSG_PUB.g_msg_lvl_unexp_error) THEN
      FND_MSG_PUB.add_exc_msg( p_pkg_name => G_PKG_NAME,
                               p_procedure_name => l_api_name);
    END IF;

    RAISE;

END update_award_distributions;

--<GRANTS FPJ END>

--<Shared Proc FPJ START>
-------------------------------------------------------------------------------
--Start of Comments
--Name: GET_RATE_FOR_REQ_PRICE
--Pre-reqs:
--   None
--Modifies:
--  None
--Locks:
--  None.
--Function:
--  Get the conversion rate between PO Currency and Req Functional Currency for
--  Default Rate type of Purchasing Org
--Parameters:
--  IN:
--  p_requesting_ou_id: Requesting Operating Unit <ACHTML R12>
--  p_purchasing_ou_id: Purchasing Operating Unit <ACHTML R12>
--  p_po_currency_code: The currency in which PO will be cut
--  p_rate_type: The default rate type of Purchasing Operating Unit
--  p_rate_date: The date used to derive rate between PO and POU functional currency
--  OUT:
--  x_rate: The rate between PO currency and Requisition raising Operating Unit's functional currency
--          Returns NULL if POU and ROU are in same Set Of Books (implying same functional currency)
--Notes:
--  None
--Testing:
--  None
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE get_rate_for_req_price(
  p_requesting_ou_id IN NUMBER, -- <ACHTML R12>
  p_purchasing_ou_id IN NUMBER, -- <ACHTML R12>
  p_po_currency_code IN VARCHAR2,
  p_rate_type        IN VARCHAR2,
  p_rate_date        IN DATE,
  x_rate             OUT NOCOPY NUMBER
)
IS

l_req_ou_sob_id              GL_SETS_OF_BOOKS.set_of_books_id%TYPE;
l_po_ou_sob_id               GL_SETS_OF_BOOKS.set_of_books_id%TYPE;
l_inverse_rate_display_flag  VARCHAR2(1) := 'N';
l_display_rate               NUMBER;
l_progress                   VARCHAR2(3) := '000';
l_rate_type                  PO_HEADERS_INTERFACE.rate_type%TYPE;
l_api_name CONSTANT VARCHAR2(30) := 'get_rate_for_req_price';  --< Bug 3210331 >

BEGIN
    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_begin(p_log_head => g_log_head||l_api_name);
    END IF;

   select req_fsp.set_of_books_id
   into l_req_ou_sob_id
   from financials_system_params_all req_fsp
   where req_fsp.org_id = p_requesting_ou_id; -- <ACHTML R12>

   l_progress := '010';
   select po_fsp.set_of_books_id
   into l_po_ou_sob_id
   from financials_system_params_all po_fsp
   where po_fsp.org_id = p_purchasing_ou_id; -- <ACHTML R12>

   IF l_req_ou_sob_id = l_po_ou_sob_id THEN
      x_rate := NULL;
      return;
   END IF;

   IF p_rate_type is NULL THEN
      l_progress := '020';
      select default_rate_type
      into  l_rate_type
      from  po_system_parameters_all psp
      where psp.org_id = p_purchasing_ou_id; -- <ACHTML R12>
   ELSE
     l_rate_type := p_rate_type;
   END IF;

   l_progress := '030';

   po_currency_sv.get_rate(l_req_ou_sob_id,
                              p_po_currency_code,
                              l_rate_type,
                              p_rate_date,
                              l_inverse_rate_display_flag,
                              x_rate,
                              l_display_rate);

    IF g_debug_stmt THEN    --< Bug 3210331: use proper debugging >
        PO_DEBUG.debug_end(p_log_head => g_log_head||l_api_name);
    END IF;
EXCEPTION
  WHEN OTHERS THEN
      IF g_debug_unexp THEN    --< Bug 3210331: use proper debugging >
          PO_DEBUG.debug_exc(p_log_head => g_log_head||l_api_name,
                             p_progress => l_progress);
      END IF;
      po_message_s.sql_error('GET_RATE_FOR_REQ_PRICE',l_progress,sqlcode);
END get_rate_for_req_price;
--<Shared Proc FPJ END>


-- <Complex Work R12 Start>
-------------------------------------------------------------------------------
--Start of Comments
--Name: create_payitems
--Pre-reqs:
--   PO Line has been created.
--Modifies:
--  PO_LINE_LOCATIONS_ALL
--Locks:
--  None.
--Function:
--  Create all payitems for a PO Line.  If PO_LINE_LOCATIONS_INTERFACE is
--  populated, use that information.  Otherwise, create a default
--  payitem.  Also create DELIVERY and ADVANCE payitems as necessary.
--Parameters:
--  IN:
--    p_interface_line_id:  id of the line in po_lines_interface
--    p_po_line_id: id of the line in po_lines_all
--    p_precision: precision of the currency desired.  Used to round amounts.
--    p_ext_precision: extended precision of the currency desired.
--                     Used to round prices
--  OUT:
--    x_line_location_id: id of the first actuals (STANDARD) payitem
--                        in po_line_locations_all
--    x_line_loc_id_tbl: ids of all payitems created in po_line_locations_all
--Notes:
--  None
--Testing:
--  None
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE create_payitems(
  p_interface_line_id IN         NUMBER
, p_po_line_id        IN         NUMBER
, p_precision         IN         NUMBER
, p_ext_precision     IN         NUMBER
, x_line_location_id  OUT NOCOPY NUMBER
, x_line_loc_id_tbl   OUT NOCOPY po_tbl_number
)
IS

d_progress  NUMBER;
d_module    VARCHAR2(70) := 'po.plsql.PO_INTERFACE_S.create_payitems';

l_po_header_id         PO_LINES_ALL.po_header_id%TYPE;
l_line_value_basis     PO_LINES_ALL.order_type_lookup_code%TYPE;
l_line_matching_basis  PO_LINES_ALL.matching_basis%TYPE;
l_line_unit_price      PO_LINES_ALL.unit_price%TYPE;
l_line_quantity        PO_LINES_ALL.quantity%TYPE;
l_line_amount          PO_LINES_ALL.amount%TYPE;
l_line_purchase_basis  PO_LINES_ALL.purchase_basis%TYPE;

l_payment_type       PO_LINE_LOCATIONS_ALL.payment_type%TYPE;
l_shipment_type      PO_LINE_LOCATIONS_ALL.shipment_type%TYPE;
l_payitem_quantity   PO_LINE_LOCATIONS_ALL.quantity%TYPE;
l_payitem_amount     PO_LINE_LOCATIONS_ALL.amount%TYPE;
l_payitem_price      PO_LINE_LOCATIONS_ALL.price_override%TYPE;

l_req_tax_code_id    PO_REQUISITION_LINES_ALL.tax_code_id%TYPE;
l_req_tax_user_override_flag    PO_REQUISITION_LINES_ALL.tax_user_override_flag%TYPE;
l_req_tax_status_indicator PO_REQUISITION_LINES_ALL.tax_status_indicator%TYPE;

l_tax_name                      AP_TAX_CODES.name%TYPE;
l_tax_code_id                   AP_TAX_CODES.tax_id%TYPE;
l_tax_type                      AP_TAX_CODES.tax_type%TYPE;
l_tax_description               AP_TAX_CODES.description%TYPE;
l_allow_tax_code_override_flag  GL_TAX_OPTION_ACCOUNTS.allow_tax_code_override_flag%TYPE;

l_isFinancing          BOOLEAN;
l_ship_to_location_id  NUMBER;

l_payitem_tax_code_id_tbl   po_tbl_number;
l_payitems_created          NUMBER;

l_routing_name   RCV_ROUTING_HEADERS.routing_name%TYPE;
l_line_loc_id    PO_LINE_LOCATIONS_ALL.line_location_id%TYPE;

l_po_promised_def_prf   VARCHAR2(1) := FND_PROFILE.value('PO_NEED_BY_PROMISE_DEFAULTING');
l_country_of_origin_code VARCHAR2(2);
l_tax_status             VARCHAR2(10);
l_encoded_msg            VARCHAR2(2000);

l_advance_desc           VARCHAR2(240);
--<eTax integration R12 Start >
l_return_status             VARCHAR2(1);
l_msg_count                 NUMBER;
l_msg_data                  VARCHAR2(2000);
--<eTax integration R12 End>

CURSOR poll_interface_cursor(p_interface_line_id NUMBER)
IS
  SELECT polli.interface_line_location_id,
         polli.quantity,
         polli.amount,
         polli.ship_to_location_id,
         polli.need_by_date,
         polli.promised_date,
         polli.price_override,
         polli.shipment_type,
         polli.shipment_num,
         polli.ship_to_organization_id,
         polli.value_basis,
         polli.matching_basis,
         polli.payment_type,
         polli.description,
         polli.work_approver_id,
         polli.bid_payment_id,
         polli.unit_of_measure
  FROM po_line_locations_interface polli
  WHERE polli.interface_line_id = p_interface_line_id
  ORDER BY polli.shipment_num;

line_location_rec     poll_interface_cursor%ROWTYPE;
payitem_rcv_ctl_rec   rcv_controls_type;

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_interface_line_id', p_interface_line_id);
    PO_LOG.proc_begin(d_module, 'p_po_line_id', p_po_line_id);
  END IF;

  d_progress := 10;

  SELECT pol.order_type_lookup_code
       , pol.matching_basis
       , pol.po_header_id
       , pol.unit_price
       , pol.quantity
       , pol.amount
       , pol.purchase_basis
  INTO l_line_value_basis
     , l_line_matching_basis
     , l_po_header_id
     , l_line_unit_price
     , l_line_quantity
     , l_line_amount
     , l_line_purchase_basis
  FROM po_lines_all pol
  WHERE pol.po_line_id = p_po_line_id;

  d_progress := 20;

  l_isFinancing := PO_COMPLEX_WORK_PVT.is_financing_po(
                     p_po_header_id => l_po_header_id
                   );

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'l_isFinancing', l_isFinancing);
  END IF;

  d_progress := 30;

  IF (interface.poll_interface_pop_flag = 'N') THEN

    d_progress := 40;

    -- If line locations interface is not populated, then we are either
    -- autocreating from requisition or there are no payitems negotiated
    -- in sourcing for this line.  We need to populate data for the default
    -- payitem in the interface tables.

    PO_COMPLEX_WORK_PVT.get_default_payitem_info(
      p_po_header_id          => l_po_header_id
    , p_po_line_id            => p_po_line_id
    , p_line_value_basis      => l_line_value_basis
    , p_line_matching_basis   => l_line_matching_basis
    , p_line_qty      => ROUND(l_line_quantity, 15)
    , p_line_amt      => l_line_amount
    , p_line_price    => l_line_unit_price
    , x_payment_type  => l_payment_type
    , x_payitem_qty   => l_payitem_quantity
    , x_payitem_amt   => l_payitem_amount
    , x_payitem_price => l_payitem_price
    );

    d_progress := 50;

    --SQL WHAT: Insert information for default payitem into
    -- po_line_locations interface table
    --SQL WHY : We will use line_locations_interface as a
    -- common entry point for payitems - whether they come from
    -- sourcing or we default them from scratch here.

    INSERT INTO po_line_locations_interface
    (
      interface_line_location_id
    , interface_header_id
    , interface_line_id
    , quantity
    , amount
    , price_override
    , shipment_type
    , payment_type
    , shipment_num
    , need_by_date
    , promised_date
    )
    VALUES
    (
      PO_LINE_LOCATIONS_INTERFACE_S.NEXTVAL
    , interface.interface_header_id
    , p_interface_line_id
    , l_payitem_quantity
    , l_payitem_amount
    , l_payitem_price
    , NULL
    , l_payment_type
    , 1
    , interface.need_by_date
    , interface.promised_date                             ----Bug11655669
    );

  END IF;  -- interface.poll_interface_pop_flag = 'N'

  d_progress := 60;

  IF (l_isFinancing) THEN

    d_progress := 70;

    -- if financing case, create actual delivery payitem
    -- this payitem has a shipment_type of STANDARD and payment_type of DELIVERY

    --SQL WHAT: Insert information for delivery payitem into
    -- po_line_locations_interface table
    --SQL WHY : We will use line_locations_interface as a
    -- common entry point for payitems, including ones we create
    -- behind the scenes

    INSERT INTO po_line_locations_interface
    (
      interface_line_location_id
    , interface_header_id
    , interface_line_id
    , quantity
    , amount
    , price_override
    , payment_type
    , shipment_type
    , description
    , shipment_num
    , need_by_date
    , promised_date
    )
    VALUES
    (
      PO_LINE_LOCATIONS_INTERFACE_S.NEXTVAL
    , interface.interface_header_id
    , p_interface_line_id
    , l_line_quantity
    , l_line_amount
    , l_line_unit_price
    , 'DELIVERY'
    , 'STANDARD'
    , interface.item_description
    , 1
    , interface.need_by_date
    , interface.promised_date            --Bug5532424
    );

  END IF;  -- if l_isFinancing

  d_progress := 80;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'interface.has_advance_flag', interface.has_advance_flag);
  END IF;

  IF (interface.has_advance_flag = 'Y') THEN

    d_progress := 90;

    -- if line has advance, create financing payitem to represent it.
    -- the payitem has shipment_type of PREPAYMENT and payment_type of ADVANCE

    -- get default advance description
    FND_MESSAGE.set_name('PO', 'PO_CWPUI_ADVANCE_DESC_PREFIX');
    FND_MESSAGE.set_token(token => 'LINE_DESC',
                          value => interface.item_description);
    l_advance_desc := substrb(FND_MESSAGE.get, 1, 240);

    --SQL WHAT: Insert information for advance payitem into
    -- po_line_locations_interface table
    --SQL WHY : We will use line_locations_interface as a
    -- common entry point for payitems, including ones we create
    -- behind the scenes

    INSERT INTO po_line_locations_interface
    (
      interface_line_location_id
    , interface_header_id
    , interface_line_id
    , quantity
    , amount
    , price_override
    , payment_type
    , shipment_type
    , description
    , shipment_num
    , need_by_date
    )
    VALUES
    (
      PO_LINE_LOCATIONS_INTERFACE_S.NEXTVAL
    , interface.interface_header_id
    , p_interface_line_id
    , NULL
    , interface.advance_amount
    , NULL
    , 'ADVANCE'
    , 'PREPAYMENT'
    , l_advance_desc
    , 0
    , NULL
    );

  END IF;  -- if interface.has_advance_flag = 'Y'

  d_progress := 100;

  -- at this point, line_locations_interface has been populated with
  -- all necessary payitems - whether they come from sourcing or were
  -- created above from line information.

  -- we now update all rows in the line interface, filling in
  -- columns as necessary.  Some columns may have already been filled in;
  -- for those columns, we do a NULL check first (using NVL).

  l_ship_to_location_id := get_ship_to_loc(interface.deliver_to_location_id);

  IF (l_isFinancing) THEN
    l_shipment_type := 'PREPAYMENT';
  ELSE
    l_shipment_type := 'STANDARD';
  END IF;

  d_progress := 110;

  --SQL WHAT: Default/update values for scratch payitems in interface table
  --SQL WHY : This allows us to update all new payitems' values at once,
  -- including payitems from sourcing or ones we've created in autocreate

  UPDATE po_line_locations_interface polli
  SET polli.value_basis =
          DECODE(polli.payment_type,
                   'RATE', 'QUANTITY',
                   'LUMPSUM', 'FIXED PRICE',
                   'MILESTONE', l_line_value_basis,
                   'ADVANCE', 'FIXED PRICE',
                   'DELIVERY', l_line_value_basis,
                    polli.value_basis),
      polli.matching_basis =
          DECODE(polli.payment_type,
                   'RATE', 'QUANTITY',
                   'LUMPSUM', 'AMOUNT',
                   'MILESTONE', l_line_matching_basis,
                   'ADVANCE', 'AMOUNT',
                   'DELIVERY', l_line_matching_basis,
                    polli.matching_basis),
      polli.ship_to_location_id =
                    NVL(polli.ship_to_location_id, l_ship_to_location_id),
      polli.ship_to_organization_id =
                    NVL(polli.ship_to_organization_id,
                                   interface.destination_organization_id),
      polli.promised_date =
          NVL(polli.promised_date,
            DECODE(NVL(l_po_promised_def_prf, 'N'), 'Y', polli.need_by_date,
                                                         polli.promised_date)),
      polli.shipment_type = NVL(polli.shipment_type, l_shipment_type),
      polli.description = NVL(polli.description, interface.item_description),
      polli.unit_of_measure = NVL(polli.unit_of_measure, interface.unit_meas_lookup_code)
    WHERE polli.interface_line_id = p_interface_line_id;

  d_progress := 120;

  IF (interface.requisition_line_id IS NOT NULL) THEN

    d_progress := 130;

    SELECT prl.tax_code_id
        ,  nvl(prl.tax_user_override_flag,'N')
        ,  nvl(prl.tax_status_indicator,'SYSTEM')
        ,  nvl(prl.org_id, g_hdr_requesting_ou_id)
    INTO l_req_tax_code_id
      ,  l_req_tax_user_override_flag
      ,  l_req_tax_status_indicator
      ,  g_line_requesting_ou_id
    FROM po_requisition_lines_all prl
    WHERE prl.requisition_line_id = interface.requisition_line_id;

    l_tax_code_id := l_req_tax_code_id;

  ELSE

    d_progress := 140;
    l_req_tax_status_indicator := 'SYSTEM';
    g_line_requesting_ou_id := g_hdr_requesting_ou_id;

  END IF;  -- if interface.requisition_line_id IS NOT NULL

  d_progress := 150;
  x_line_loc_id_tbl := po_tbl_number();
  l_payitem_tax_code_id_tbl := po_tbl_number();
  l_payitems_created := 0;

  -- now iterate over the rows in the interface table
  -- for each row, get the default tax, receiving controls, and country of
  -- origin before inserting a new row into po_line_locations_all

  OPEN poll_interface_cursor(p_interface_line_id);
  LOOP

    FETCH poll_interface_cursor INTO line_location_rec;
    EXIT WHEN poll_interface_cursor%NOTFOUND;

    d_progress := 160;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Getting receiving controls.');
    END IF;

    RCV_CORE_S.get_receiving_controls(
      p_order_type_lookup_code => line_location_rec.value_basis
    , p_purchase_basis         => l_line_purchase_basis
    , p_line_location_id       => NULL
    , p_item_id                => interface.item_id
    , p_org_id                 => line_location_rec.ship_to_organization_id
    , p_vendor_id              => interface.vendor_id
    , p_drop_ship_flag         => interface.drop_ship_flag
    , p_payment_type           => line_location_rec.payment_type
    , x_enforce_ship_to_loc_code => payitem_rcv_ctl_rec.enforce_ship_to_location_code
    , x_allow_substitute_receipts => payitem_rcv_ctl_rec.allow_substitute_receipts_flag
    , x_routing_id => payitem_rcv_ctl_rec.receiving_routing_id
    , x_routing_name => l_routing_name
    , x_qty_rcv_tolerance => payitem_rcv_ctl_rec.qty_rcv_tolerance
    , x_qty_rcv_exception_code => payitem_rcv_ctl_rec.qty_rcv_exception_code
    , x_days_early_receipt_allowed => payitem_rcv_ctl_rec.days_early_receipt_allowed
    , x_days_late_receipt_allowed => payitem_rcv_ctl_rec.days_late_receipt_allowed
    , x_receipt_days_exception_code => payitem_rcv_ctl_rec.receipt_days_exception_code
    );

    d_progress := 200;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Getting default country of origin');
    END IF;

    po_coo_s.get_default_country_of_origin(
      x_item_id           => interface.item_id
    , x_ship_to_org_id    => line_location_rec.ship_to_organization_id
    , x_vendor_id         => interface.vendor_id
    , x_vendor_site_id    => interface.vendor_site_id
    , x_country_of_origin => l_country_of_origin_code
    );

    d_progress := 210;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Inserting payitem into po_line_locations_all');
    END IF;

    -- insert payitem into po_line_locations_all

    --SQL WHAT: Insert payitem, using info in po_line_locations_interface
    --SQL WHY : This allows us to insert all payitems in one location.

    INSERT INTO po_line_locations_all
    (
      line_location_id
    , last_update_date
    , last_updated_by
    , po_header_id
    , creation_date
    , created_by
    , last_update_login
    , po_line_id
    , quantity
    , quantity_received
    , quantity_accepted
    , quantity_rejected
    , quantity_billed
    , quantity_cancelled
    , quantity_financed
    , amount
    , amount_received
    , amount_accepted
    , amount_rejected
    , amount_billed
    , amount_cancelled
    , amount_financed
    , ship_to_location_id
    , need_by_date
    , promised_date
    , from_header_id
    , from_line_id
    , note_to_receiver
    , approved_flag
    , po_release_id
    , closed_code
    , closed_reason
    , price_override
    , encumbered_flag
    , taxable_flag
    , tax_code_id
    , tax_user_override_flag
    , shipment_type
    , shipment_num
    , inspection_required_flag
    , receipt_required_flag
    , days_early_receipt_allowed
    , days_late_receipt_allowed
    , enforce_ship_to_location_code
    , ship_to_organization_id
    , invoice_close_tolerance
    , receive_close_tolerance
    , accrue_on_receipt_flag
    , allow_substitute_receipts_flag
    , receiving_routing_id
    , qty_rcv_tolerance
    , qty_rcv_exception_code
    , receipt_days_exception_code
    , terms_id
    , ship_via_lookup_code
    , freight_terms_lookup_code
    , fob_lookup_code
    , unit_meas_lookup_code
    , last_accept_date
    , match_option
    , country_of_origin_code
    , vmi_flag
    , drop_ship_flag
    , consigned_flag
    , transaction_flow_header_id
    , org_id
    , closed_for_receiving_date
    , closed_for_invoice_date
    , value_basis
    , matching_basis
    , payment_type
    , description
    , work_approver_id
    , bid_payment_id
    , outsourced_assembly
    ,tax_attribute_update_code --<eTax Integration R12>
    )
    VALUES
    (
      PO_LINE_LOCATIONS_S.nextval
    , interface.last_update_date
    , interface.last_updated_by
    , interface.po_header_id
    , interface.creation_date
    , interface.created_by
    , interface.last_update_login
    , p_po_line_id
    , line_location_rec.quantity   -- quantity
    , 0                            -- quantity_received
    , 0                            -- quantity_accepted
    , 0                            -- quantity_rejected
    , 0                            -- quantity_billed
    , 0                            -- quantity_cancelled
    , 0                            -- quantity_financed
    , line_location_rec.amount     -- amount
    , 0                            -- amount_received
    , 0                            -- amount_accepted
    , 0                            -- amount_rejected
    , 0                            -- amount_billed
    , 0                            -- amount_cancelled
    , 0                            -- amount_financed
    , line_location_rec.ship_to_location_id
    , line_location_rec.need_by_date
    , line_location_rec.promised_date
    /* Modified for Bug# 8446396 */
    /* Bug11802312 - Retain the document reference for a consigned PO */
    , interface.from_header_id
    , interface.from_line_id
    , interface.note_to_receiver
    , 'N'                          -- approved_flag
    , NULL                         -- po_release_d
    , 'OPEN'                       -- closed_code
    , NULL                         -- closed_reason
    , line_location_rec.price_override
    , 'N'                            -- encumbered_flag
    , NVL2(l_tax_code_id, 'Y', 'N')  -- taxable_flag
    , l_tax_code_id
    , l_req_tax_user_override_flag
    , line_location_rec.shipment_type
    , line_location_rec.shipment_num
    , 'N'                           -- inspection_required_flag
    , DECODE(line_location_rec.value_basis,    -- receipt_required_flag
               'FIXED_PRICE', 'N',
               coalesce(item.receipt_required_flag,
                        vendor.receipt_required_flag,
                        params.receiving_flag,
                        'N'))
    , payitem_rcv_ctl_rec.days_early_receipt_allowed
    , payitem_rcv_ctl_rec.days_late_receipt_allowed
    , payitem_rcv_ctl_rec.enforce_ship_to_location_code
    , line_location_rec.ship_to_organization_id
    , coalesce(item.invoice_close_tolerance, params.invoice_close_tolerance, 100)
    , DECODE(line_location_rec.payment_type,
               'MILESTONE', 0,
               coalesce(item.receive_close_tolerance,
                        params.receive_close_tolerance,
                        100))
    , DECODE(line_location_rec.shipment_type,   -- acrrue_on_receipt_flag
              'PREPAYMENT', 'N',
              DECODE(coalesce(item.receipt_required_flag,
                              interface.receipt_required_flag,
                              vendor.receipt_required_flag,
                              params.receiving_flag,
                              'N'),
                      'N', 'N',
                      DECODE(params.expense_accrual_code,
                                'PERIOD END', 'N', 'Y')))
    , payitem_rcv_ctl_rec.allow_substitute_receipts_flag
    , payitem_rcv_ctl_rec.receiving_routing_id
    , payitem_rcv_ctl_rec.qty_rcv_tolerance
    , payitem_rcv_ctl_rec.qty_rcv_exception_code
    , payitem_rcv_ctl_rec.receipt_days_exception_code
    , NULL     -- terms_id
    , NULL     -- ship_via_lookup_code
    , NULL     -- freight_terms_lookup_code
    , NULL     -- fob_lookup_code
    , line_location_rec.unit_of_measure   -- unit_meas_lookup_code
    , line_location_rec.promised_date     -- last_accept_date
            + payitem_rcv_ctl_rec.days_late_receipt_allowed
    , vendor.invoice_match_option
    , l_country_of_origin_code
    , NULL                -- vmi_flag
    , NULL                -- drop_ship_flag
    , NULL                -- consigned_flag
    , interface.transaction_flow_header_id
    , g_purchasing_ou_id
    , NULL       -- closed_for_receiving_date
    , NULL       -- closed_for_invoice_date
    , line_location_rec.value_basis
    , line_location_rec.matching_basis
    , line_location_rec.payment_type
    , line_location_rec.description
    , line_location_rec.work_approver_id
    , line_location_rec.bid_payment_id
    , 2                                 -- outsourced_assembly
    ,nvl2(g_calculate_tax_flag, 'CREATE', null)  --<eTax Integration R12>

    )
    RETURNING line_location_id INTO l_line_loc_id;

    d_progress := 220;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Inserted payitem.');
      PO_LOG.stmt(d_module, d_progress, 'l_line_loc_id', l_line_loc_id);
    END IF;

    d_progress := 230;

    -- create link between interface row and transaction row
    UPDATE po_line_locations_interface polli
    SET polli.line_location_id = l_line_loc_id
    WHERE polli.interface_line_location_id =
                         line_location_rec.interface_line_location_id;

    d_progress := 240;

    calculate_local('PO', 'SHIPMENT', l_line_loc_id);

    d_progress := 250;
    l_payitems_created := l_payitems_created + 1;
    x_line_loc_id_tbl.EXTEND;
    x_line_loc_id_tbl(l_payitems_created) := l_line_loc_id;
    l_payitem_tax_code_id_tbl.EXTEND;
    l_payitem_tax_code_id_tbl(l_payitems_created) := l_tax_code_id;

    -- set x_line_location_id to id of first actual (STANDARD) payitem
    IF ((x_line_location_id IS NULL)
        AND (line_location_rec.shipment_type = 'STANDARD')) THEN
      x_line_location_id := l_line_loc_id;
    END IF;

  END LOOP;  -- poll_interface_cursor loop
  CLOSE poll_interface_cursor;

  d_progress := 300;

  -- call create_payitem_dists to create distributions for all new payitems
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'Ready to call create_payitem_dists');
  END IF;

  create_payitem_dists(
    p_po_line_id        => p_po_line_id
  , p_req_line_id       => interface.requisition_line_id
  , p_interface_line_id => p_interface_line_id
  , p_precision         => p_precision
  , p_ext_precision     => p_ext_precision
  );

  d_progress := 310;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'Done calling create_payitem dists');
  END IF;

  d_progress := 400;

 IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'calling tax api ');
 END IF;

 d_progress := 1420;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_line_location_id', x_line_location_id);
    PO_LOG.proc_end(d_module, 'x_line_loc_id_tbl',  x_line_loc_id_tbl);
    PO_LOG.proc_end(d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN

    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
    END IF;

    IF (poll_interface_cursor%ISOPEN) THEN
      CLOSE poll_interface_cursor;
    END IF;

    wrapup(interface.interface_header_id);
    RAISE;
END create_payitems;


-------------------------------------------------------------------------------
--Start of Comments
--Name: create_payitem_dists
--Pre-reqs:
--   PO Payitems have all been created.
--Modifies:
--  PO_DISTRIBUTIONS_ALL
--Locks:
--  None.
--Function:
--  Create all distributions for all payitems for a PO Line.
--Parameters:
--  IN:
--    p_req_line_id: id of the requisition line that is the source of
--                   the po line; null if no backing req.
--    p_po_line_id: id of the line in po_lines_all
--    p_interface_line_id: id of the line in po_lines_interface
--    p_precision: precision of the currency desired.  Used to round amounts.
--    p_ext_precision: extended precision of the currency desired.
--                     Used to round prices
--  OUT:
--    None.
--Notes:
--  None
--Testing:
--  None
--End of Comments
-------------------------------------------------------------------------------
PROCEDURE create_payitem_dists(
  p_po_line_id         IN NUMBER
, p_req_line_id        IN NUMBER
, p_interface_line_id  IN NUMBER
, p_precision          IN NUMBER
, p_ext_precision      IN NUMBER
)
IS

d_progress   NUMBER;
d_module     VARCHAR2(70) := 'po.plsql.PO_INTERFACE_S.create_payitem_dists';

CURSOR payitem_acct_gen_cursor(p_po_line_id NUMBER)
IS
  SELECT pod.po_distribution_id
       , pod.project_id
       , pod.task_id
       , pod.award_id
       , pod.expenditure_type
       , pod.expenditure_item_date
       , pod.expenditure_organization_id
       , pod.destination_type_code
       , pod.destination_organization_id
       , pod.destination_subinventory
       , pod.deliver_to_location_id
       , pod.deliver_to_person_id
       , pod.gl_encumbered_date
       , poll.price_override
       , poll.payment_type
       , pod.distribution_type
       , pod.rate
  FROM po_distributions_all pod,
       po_line_locations_all poll
  WHERE poll.po_line_id = p_po_line_id
    AND pod.line_location_id = poll.line_location_id
    AND pod.req_distribution_id IS NULL;

payitem_acct_rec      payitem_acct_gen_cursor%ROWTYPE;

l_line_loc_id_tbl              po_tbl_number;
l_line_loc_value_basis_tbl     po_tbl_varchar30;
l_dist_id_tbl                  po_tbl_number;

l_return_status       VARCHAR2(1);
l_msg_count           NUMBER;
l_msg_data            VARCHAR2(2000);
l_gl_date_option      VARCHAR2(25);
l_sob_id              PO_REQ_DISTRIBUTIONS_ALL.set_of_books_id%TYPE;


-- Acct. Generator Variables Start
l_dest_charge_success          BOOLEAN   := TRUE;
l_dest_variance_success        BOOLEAN   := TRUE;
l_charge_success               BOOLEAN   := TRUE;
l_budget_success               BOOLEAN   := TRUE;
l_accrual_success              BOOLEAN   := TRUE;
l_variance_success             BOOLEAN   := TRUE;

l_dest_charge_account_id       NUMBER;
l_dest_variance_account_id     NUMBER;
l_code_combination_id          NUMBER;
l_budget_account_id            NUMBER;
l_accrual_account_id           NUMBER;
l_variance_account_id          NUMBER;

l_dest_charge_account_desc     VARCHAR2(2000);
l_dest_variance_account_desc   VARCHAR2(2000);
l_charge_account_desc          VARCHAR2(2000);
l_budget_account_desc          VARCHAR2(2000);
l_accrual_account_desc         VARCHAR2(2000);
l_variance_account_desc        VARCHAR2(2000);

l_dest_charge_account_flex     VARCHAR2(2000);
l_dest_variance_account_flex   VARCHAR2(2000);
l_charge_account_flex          VARCHAR2(2000);
l_budget_account_flex          VARCHAR2(2000);
l_accrual_account_flex         VARCHAR2(2000);
l_variance_account_flex        VARCHAR2(2000);

l_wf_itemkey                   VARCHAR2(80) := NULL;
l_new_combination              BOOLEAN      := FALSE;
l_fb_error_msg                 VARCHAR2(2000);

l_acct_api_success             BOOLEAN;
-- Acct. Generator Variables End


BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_po_line_id', p_po_line_id);
    PO_LOG.proc_begin(d_module, 'p_req_line_id', p_req_line_id);
    PO_LOG.proc_begin(d_module, 'p_interface_line_id', p_interface_line_id);
  END IF;

  d_progress := 10;

  IF (p_req_line_id IS NOT NULL) THEN

    -- if backing req exists, use req distributions as base for creating
    -- po distributions.

    d_progress := 20;

    FND_PROFILE.GET('PO_AUTOCREATE_DATE', l_gl_date_option);

    IF ((params.po_encumbrance_flag = 'Y')
      AND (l_gl_date_option <> 'REQ GL DATE')
      AND (params.period_name IS NULL)) THEN

      -- derive period name if it isn't already known

      d_progress := 30;

      SELECT prd.set_of_books_id
      INTO l_sob_id
      FROM po_req_distributions_all prd
      WHERE prd.requisition_line_id = p_req_line_id
        AND ROWNUM = 1;

      d_progress := 40;

      PO_PERIODS_SV.get_period_name(
        x_sob_id  => l_sob_id
      , x_gl_date => SYSDATE
      , x_gl_period => params.period_name
      );

      IF (params.period_name IS NULL) THEN
        d_progress := 50;
        IF (PO_LOG.d_exc) THEN
          PO_LOG.exc(d_module, d_progress, 'Unable to find period name for SYSDATE');
        END IF;
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

    END IF;  -- if params.po_encumbrance_flag = 'Y' AND ...

    -- create distributions from req distributions

    d_progress := 60;

    --SQL WHAT: Create payitem distributions from backing req. distributions
    --SQL WHY : Create all such payitem distributions in one place

    INSERT INTO po_distributions_all(
      po_distribution_id
    , last_update_date
    , last_updated_by
    , last_update_login
    , creation_date
    , created_by
    , po_header_id
    , po_line_id
    , line_location_id
    , distribution_num
    , req_distribution_id
    , set_of_books_id
    , code_combination_id
    , deliver_to_location_id
    , deliver_to_person_id
    , destination_type_code
    , destination_organization_id
    , destination_subinventory
    , project_id
    , task_id
    , award_id
    , end_item_unit_number
    , expenditure_type
    , project_accounting_context
    , destination_context
    , expenditure_organization_id
    , expenditure_item_date
    , rate
    , rate_date
    , budget_account_id
    , accrual_account_id
    , variance_account_id
    , accrued_flag
    , encumbered_flag
    , prevent_encumbrance_flag
    , gl_encumbered_date
    , gl_encumbered_period_name
    , recovery_rate
    , recoverable_tax
    , nonrecoverable_tax
    , accrue_on_receipt_flag
    , kanban_card_id
    , org_id
    , distribution_type
    , quantity_ordered
    , amount_ordered
    ,tax_attribute_update_code    --<eTax Integration R12>
    )
    SELECT
      PO_DISTRIBUTIONS_S.NEXTVAL
    , interface.last_update_date
    , interface.last_updated_by
    , interface.last_update_login
    , interface.creation_date
    , interface.created_by
    , interface.po_header_id
    , p_po_line_id
    , poll.line_location_id
    , prd.distribution_num
    , prd.distribution_id  --Bug 4744751: these 2 cols were reversed in order
    , prd.set_of_books_id  --Bug 4744751: these 2 cols were reversed in order
    , prd.code_combination_id
    , prl.deliver_to_location_id
    , prl.to_person_id
    , prl.destination_type_code
    , prl.destination_organization_id
    , prl.destination_subinventory
    , prd.project_id
    , prd.task_id
    , prd.award_id
    , prd.end_item_unit_number
    , prd.expenditure_type
    , prd.project_accounting_context
    , prl.destination_context
    , prd.expenditure_organization_id
    , prd.expenditure_item_date
    , interface.h_rate
    , interface.h_rate_date
    , DECODE(poll.shipment_type, 'PREPAYMENT', null, prd.budget_account_id)
    , prd.accrual_account_id
    , prd.variance_account_id
    , 'N'         -- accrued_flag
    , 'N'         -- encumbered_flag
    , DECODE(params.po_encumbrance_flag, 'Y',
               DECODE(poll.shipment_type, 'PREPAYMENT', 'Y', 'N'),
               null)  -- prevent_encumbrance_flag
    , (CASE        -- gl_encumbered_date
         WHEN (params.req_encumbrance_flag = 'Y' AND
                 l_gl_date_option = 'REQ GL DATE')
           THEN prd.gl_encumbered_date
         WHEN (params.po_encumbrance_flag = 'Y')
           THEN trunc(SYSDATE)
         ELSE NULL
       END)
    , (CASE        -- gl_encumbered_period_name
         WHEN (params.req_encumbrance_flag = 'Y' AND
                 l_gl_date_option = 'REQ GL DATE')
           THEN prd.gl_encumbered_period_name
         WHEN (params.po_encumbrance_flag = 'Y')
           THEN params.period_name
         ELSE NULL
       END)
    , prd.recovery_rate
    , prd.recoverable_tax
    , prd.nonrecoverable_tax
    , poll.accrue_on_receipt_flag
    , prl.kanban_card_id
    , g_purchasing_ou_id
    , poll.shipment_type
    , (CASE                     -- quantity_ordered
         WHEN poll.value_basis <> 'QUANTITY'
           THEN NULL
         WHEN poll.payment_type IN ('MILESTONE', 'DELIVERY')
           THEN ROUND((prd.req_line_quantity / prl.quantity) * poll.quantity, 15)
         WHEN poll.payment_type = 'RATE'
           THEN ROUND((prd.req_line_amount / prl.amount) * poll.quantity, 15)
       END)
    , (CASE                     -- amount_ordered
         WHEN poll.value_basis <> 'FIXED PRICE'
           THEN NULL
         ELSE ROUND((prd.req_line_amount / prl.amount) * poll.amount, p_precision)
       END)
       ,nvl2(g_calculate_tax_flag, 'CREATE', null) --<eTax integration R12>
    FROM po_line_locations_all poll
       , po_req_distributions_all prd
       , po_requisition_lines_all prl
    WHERE poll.po_line_id = p_po_line_id
      AND prd.requisition_line_id = p_req_line_id
      AND prl.requisition_line_id = prd.requisition_line_id
      AND poll.payment_type <> 'ADVANCE';

    d_progress := 70;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Payitems distributions created from requisition distributions.');
    END IF;

  ELSE

    -- no backing req exists; create distributions for payitems
    -- from scratch.  Accounts are not set here - they will
    -- be generated and populated later.

    d_progress := 80;

    IF ((params.po_encumbrance_flag = 'Y')
      AND (params.period_name IS NULL)) THEN

      -- derive period name if it isn't already known
      d_progress := 90;

      PO_PERIODS_SV.get_period_name(
        x_sob_id  => params.sob_id
      , x_gl_date => SYSDATE
      , x_gl_period => params.period_name
      );

      IF (params.period_name IS NULL) THEN
        d_progress := 100;
        IF (PO_LOG.d_exc) THEN
          PO_LOG.exc(d_module, d_progress, 'Unable to find period name for SYSDATE');
        END IF;
        RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
      END IF;

    END IF;  -- if params.po_encumbrance_flag = 'Y' AND ...

    d_progress := 110;

    --SQL WHAT: Create payitem distributions in the case of no backing req.
    --SQL WHY : Create all such payitem distributions in one place

    INSERT INTO po_distributions_all(
      po_distribution_id
    , last_update_date
    , last_updated_by
    , last_update_login
    , creation_date
    , created_by
    , po_header_id
    , po_line_id
    , line_location_id
    , distribution_num
    , req_distribution_id
    , deliver_to_location_id
    , deliver_to_person_id
    , destination_type_code
    , destination_organization_id
    , destination_subinventory
    , rate
    , rate_date
    , accrued_flag
    , encumbered_flag
    , prevent_encumbrance_flag
    , gl_encumbered_date
    , gl_encumbered_period_name
    , accrue_on_receipt_flag
    , org_id
    , distribution_type
    , project_id
    , task_id
    , award_id
    , end_item_unit_number
    , expenditure_type
    , project_accounting_context
    , destination_context
    , expenditure_organization_id
    , expenditure_item_date
    , quantity_ordered
    , amount_ordered
    , set_of_books_id
    ,tax_attribute_update_code  --<eTax Integration R12>
    )
    SELECT
      PO_DISTRIBUTIONS_S.NEXTVAL
    , interface.last_update_date
    , interface.last_updated_by
    , interface.last_update_login
    , interface.creation_date
    , interface.created_by
    , interface.po_header_id
    , p_po_line_id
    , poll.line_location_id
    , 1                          -- distribution_num
    , NULL                       -- req_distribution_id
    , poll.ship_to_location_id
    , NULL                       -- deliver_to_person_id
    , 'EXPENSE'                  -- destination_type_code
    , poll.ship_to_organization_id
    , NULL                       -- destination_subinventory
    , interface.h_rate
    , interface.h_rate_date
    , 'N'                        -- accrued_flag
    , 'N'                        -- encumbered_flag
    , DECODE(params.po_encumbrance_flag, 'Y',
               DECODE(poll.shipment_type, 'PREPAYMENT', 'Y', 'N'),
               null)  -- prevent_encumbrance_flag
    , DECODE(params.po_encumbrance_flag, 'Y', trunc(SYSDATE), NULL)
    , DECODE(params.po_encumbrance_flag, 'Y', params.period_name, NULL)
    , poll.accrue_on_receipt_flag
    , g_purchasing_ou_id
    , poll.shipment_type
    , polli.project_id
    , polli.task_id
    , polli.award_id
    , NULL                       -- end_item_unit_number
    , polli.expenditure_type
    , NULL                       -- project_accounting_context
    , 'EXPENSE'                  -- destination_context
    , polli.expenditure_organization_id
    , polli.expenditure_item_date
    , poll.quantity
    , poll.amount
    , params.sob_id
    ,nvl2(g_calculate_tax_flag, 'CREATE', null) --<eTax integration R12>
    FROM po_line_locations_all poll
       , po_line_locations_interface polli
    WHERE poll.po_line_id = p_po_line_id
      AND poll.line_location_id = polli.line_location_id
      AND poll.payment_type <> 'ADVANCE';

    d_progress := 120;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Payitems distributions created from scratch.');
    END IF;

  END IF;  -- if p_req_line_id IS NOT NULL

  d_progress := 130;

  IF (interface.has_advance_flag = 'Y') THEN

    -- create advance distributions
    -- logic: copy distributions from first actuals payitem

    d_progress := 140;

    --SQL WHAT: Create payitem distributions for advance payitems
    --SQL WHY : Create all such payitem distributions in one place

    INSERT INTO po_distributions_all
    (
      po_distribution_id
    , last_update_date
    , last_updated_by
    , last_update_login
    , creation_date
    , created_by
    , po_header_id
    , po_line_id
    , line_location_id
    , distribution_num
    , req_distribution_id
    , deliver_to_location_id
    , deliver_to_person_id
    , destination_type_code
    , destination_organization_id
    , destination_subinventory
    , rate
    , rate_date
    , accrued_flag
    , encumbered_flag
    , prevent_encumbrance_flag
    , gl_encumbered_date
    , gl_encumbered_period_name
    , accrue_on_receipt_flag
    , org_id
    , distribution_type
    , amount_ordered
    , quantity_ordered
    , project_id
    , task_id
    , award_id
    , end_item_unit_number
    , expenditure_type
    , project_accounting_context
    , destination_context
    , expenditure_organization_id
    , expenditure_item_date
    , set_of_books_id
    ,tax_attribute_update_code  --<eTax Integration R12>
    )
    SELECT
      PO_DISTRIBUTIONS_S.NEXTVAL
    , interface.last_update_date
    , interface.last_updated_by
    , interface.last_update_login
    , interface.creation_date
    , interface.created_by
    , interface.po_header_id
    , p_po_line_id
    , adv.line_location_id
    , pod.distribution_num           -- distribution_num
    , NULL                           -- req_distribution_id
    , pod.deliver_to_location_id
    , pod.deliver_to_person_id
    , pod.destination_type_code
    , pod.destination_organization_id
    , pod.destination_subinventory
    , pod.rate
    , pod.rate_date
    , pod.accrued_flag
    , pod.encumbered_flag
    , DECODE(params.po_encumbrance_flag, 'Y', 'Y', null) --prevent_enc_flag
    , NULL                           -- gl_encumbered_date
    , NULL                           -- gl_encumbered_period_name
    , adv.accrue_on_receipt_flag
    , pod.org_id
    , adv.shipment_type
    , ROUND(                         -- amount_ordered
       (NVL(pod.amount_ordered, deliv.price_override * pod.quantity_ordered)
        / NVL(deliv.amount, deliv.price_override * deliv.quantity))
         * adv.amount, 15)
    , NULL                           -- quantity_ordered
    , pod.project_id
    , pod.task_id
    , pod.award_id
    , pod.end_item_unit_number
    , pod.expenditure_type
    , pod.project_accounting_context
    , pod.destination_context
    , pod.expenditure_organization_id
    , pod.expenditure_item_date
    , params.sob_id
    ,nvl2(g_calculate_tax_flag, 'CREATE', null)  --<eTax integration R12>
      FROM po_line_locations_all adv,
           po_line_locations_all deliv,
           po_distributions_all pod
      WHERE adv.po_line_id = p_po_line_id
        AND adv.payment_type = 'ADVANCE'
        AND deliv.line_location_id =
           ( SELECT poll.line_location_id
             FROM po_line_locations_all poll
             WHERE poll.po_line_id = p_po_line_id
               AND poll.shipment_type = 'STANDARD'
               AND poll.shipment_num =
                    ( SELECT min(poll2.shipment_num)
                      FROM po_line_locations_all poll2
                      WHERE poll2.po_line_id = poll.po_line_id
                        AND poll2.shipment_type = 'STANDARD'))
        AND pod.line_location_id = deliv.line_location_id;

    d_progress := 150;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Advance distributions created.');
    END IF;

  END IF;  -- if interface.has_advance_flag

  d_progress := 160;

  -- calibrate last distribution for each pay item

  SELECT poll.line_location_id, poll.value_basis
  BULK COLLECT INTO l_line_loc_id_tbl, l_line_loc_value_basis_tbl
  FROM po_line_locations_all poll
  WHERE poll.po_line_id = p_po_line_id;

  FOR i in 1..l_line_loc_id_tbl.COUNT
  LOOP

    IF (l_line_loc_value_basis_tbl(i) = 'FIXED PRICE') THEN
      calibrate_last_dist_amount(l_line_loc_id_tbl(i));
    ELSE
      calibrate_last_dist_quantity(l_line_loc_id_tbl(i));
    END IF;

  END LOOP;

  d_progress := 170;

  -- now, generate accounts for all distributions that are not
  -- tied to a backing req. distribution

  OPEN payitem_acct_gen_cursor(p_po_line_id);
  LOOP

    FETCH payitem_acct_gen_cursor INTO payitem_acct_rec;
    EXIT WHEN payitem_acct_gen_cursor%NOTFOUND;

    d_progress := 180;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Calling account generator wf method.');
      PO_LOG.stmt(d_module, d_progress, 'payitem_acct_rec.po_distribution_id', payitem_acct_rec.po_distribution_id);
    END IF;

    l_acct_api_success := PO_WF_BUILD_ACCOUNT_INIT.Start_Workflow(
      x_purchasing_ou_id  =>  g_purchasing_ou_id
    , x_transaction_flow_header_id  => NULL
    , x_dest_charge_success         => l_dest_charge_success
    , x_dest_charge_account_id      => l_dest_charge_account_id
    , x_dest_charge_account_desc    => l_dest_charge_account_desc
    , x_dest_charge_account_flex    => l_dest_charge_account_flex
    , x_dest_variance_success       => l_dest_variance_success
    , x_dest_variance_account_id    => l_dest_variance_account_id
    , x_dest_variance_account_desc  => l_dest_charge_account_desc
    , x_dest_variance_account_flex  => l_dest_charge_account_flex
    , x_charge_success              => l_charge_success
    , x_budget_success              => l_budget_success
    , x_accrual_success             => l_accrual_success
    , x_variance_success            => l_variance_success
    , x_code_combination_id         => l_code_combination_id
    , x_budget_account_id           => l_budget_account_id
    , x_accrual_account_id          => l_accrual_account_id
    , x_variance_account_id         => l_variance_account_id
    , x_charge_account_flex         => l_charge_account_flex
    , x_budget_account_flex         => l_budget_account_flex
    , x_accrual_account_flex        => l_accrual_account_flex
    , x_variance_account_flex       => l_variance_account_flex
    , x_charge_account_desc         => l_charge_account_desc
    , x_budget_account_desc         => l_budget_account_desc
    , x_accrual_account_desc        => l_accrual_account_desc
    , x_variance_account_desc       => l_variance_account_desc
    , x_coa_id                      => params.coa_id
    , x_bom_resource_id             => NULL
    , x_bom_cost_element_id         => NULL
    , x_category_id                 => interface.category_id
    , x_item_id                     => interface.item_id
    , x_type_lookup_code            => interface.document_subtype
    , x_line_type_id                => interface.line_type_id
    , x_agent_id                    => interface.agent_id
    , x_destination_type_code       => payitem_acct_rec.destination_type_code
    , x_deliver_to_location_id      => payitem_acct_rec.deliver_to_location_id
    , x_deliver_to_person_id        => payitem_acct_rec.deliver_to_person_id
    , x_destination_organization_id => payitem_acct_rec.destination_organization_id
    , x_destination_subinventory    => payitem_acct_rec.destination_subinventory
    , x_expenditure_type            => payitem_acct_rec.expenditure_type
    , x_expenditure_organization_id => payitem_acct_rec.expenditure_organization_id
    , x_expenditure_item_date       => payitem_acct_rec.expenditure_item_date
    , x_project_id                  => payitem_acct_rec.project_id
    , x_task_id                     => payitem_acct_rec.task_id
    , x_award_id                    => payitem_acct_rec.award_id
    , x_from_type_lookup_code       => NULL
    , x_from_header_id              => NULL
    , x_from_line_id                => NULL
    , x_vendor_id                   => interface.vendor_id
    , x_vendor_site_id              => interface.vendor_site_id
    , x_wip_entity_id               => NULL
    , x_wip_entity_type             => NULL
    , x_wip_line_id                 => NULL
    , x_wip_repetitive_schedule_id  => NULL
    , x_wip_operation_seq_num       => NULL
    , x_wip_resource_seq_num        => NULL
    , x_po_encumberance_flag        => params.po_encumbrance_flag
    , x_gl_encumbered_date          => payitem_acct_rec.gl_encumbered_date
    , x_result_billable_flag        => NULL
    , wf_itemkey                    => l_wf_itemkey
    , x_new_combination             => l_new_combination
    , header_att1        => NULL
    , header_att2        => NULL
    , header_att3        => NULL
    , header_att4        => NULL
    , header_att5        => NULL
    , header_att6        => NULL
    , header_att7        => NULL
    , header_att8        => NULL
    , header_att9        => NULL
    , header_att10       => NULL
    , header_att11       => NULL
    , header_att12       => NULL
    , header_att13       => NULL
    , header_att14       => NULL
    , header_att15       => NULL
    , line_att1          => NULL
    , line_att2          => NULL
    , line_att3          => NULL
    , line_att4          => NULL
    , line_att5          => NULL
    , line_att6          => NULL
    , line_att7          => NULL
    , line_att8          => NULL
    , line_att9          => NULL
    , line_att10         => NULL
    , line_att11         => NULL
    , line_att12         => NULL
    , line_att13         => NULL
    , line_att14         => NULL
    , line_att15         => NULL
    , shipment_att1      => NULL
    , shipment_att2      => NULL
    , shipment_att3      => NULL
    , shipment_att4      => NULL
    , shipment_att5      => NULL
    , shipment_att6      => NULL
    , shipment_att7      => NULL
    , shipment_att8      => NULL
    , shipment_att9      => NULL
    , shipment_att10     => NULL
    , shipment_att11     => NULL
    , shipment_att12     => NULL
    , shipment_att13     => NULL
    , shipment_att14     => NULL
    , shipment_att15     => NULL
    , distribution_att1  => NULL
    , distribution_att2  => NULL
    , distribution_att3  => NULL
    , distribution_att4  => NULL
    , distribution_att5  => NULL
    , distribution_att6  => NULL
    , distribution_att7  => NULL
    , distribution_att8  => NULL
    , distribution_att9  => NULL
    , distribution_att10 => NULL
    , distribution_att11 => NULL
    , distribution_att12 => NULL
    , distribution_att13 => NULL
    , distribution_att14 => NULL
    , distribution_att15 => NULL
    , FB_ERROR_MSG       => l_fb_error_msg
    , p_func_unit_price  =>
        ROUND(payitem_acct_rec.price_override * NVL (payitem_acct_rec.rate, 1),
                NVL(p_ext_precision, 15))
    , p_distribution_type    => payitem_acct_rec.distribution_type
    , p_payment_type         => payitem_acct_rec.payment_type
    );

    d_progress := 190;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'Finished account generator call.');
      PO_LOG.stmt(d_module, d_progress, 'l_acct_api_success', l_acct_api_success);
      PO_LOG.stmt(d_module, d_progress, 'l_charge_success', l_charge_success);
      PO_LOG.stmt(d_module, d_progress, 'l_variance_success', l_variance_success);
      PO_LOG.stmt(d_module, d_progress, 'l_budget_success', l_budget_success);
      PO_LOG.stmt(d_module, d_progress, 'l_accrual_success', l_accrual_success);
    END IF;

    -- follow same behavior as with shipment distributions:
    -- if account generator failed, do not create distribution

    d_progress := 200;

    IF ( l_acct_api_success AND l_charge_success
         --Bug 5645242: Added the check to test if the charge account id generated is null or 0,
         --if this is the case, then we should delete the distribution record.
         AND  (NVL(l_code_combination_id , 0) <> 0)
         AND l_variance_success AND l_accrual_success
         AND (l_budget_success OR (NVL(params.po_encumbrance_flag, 'N') <> 'Y')))
    THEN

      d_progress := 210;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Updating dist. with acct. info');
      END IF;

      --SQL WHAT: Update account information for a po distribution
      --SQL WHY : PO Distributions that don't have a backing req need to
      --          have account defaulted from account generator.

      UPDATE po_distributions_all pod
      SET pod.code_combination_id = l_code_combination_id
        , pod.budget_account_id = DECODE(NVL(params.po_encumbrance_flag, 'N'),
                                    'Y', l_budget_account_id,
                                    NULL)
        , pod.accrual_account_id = l_accrual_account_id
        , pod.variance_account_id = l_variance_account_id
      WHERE pod.po_distribution_id = payitem_acct_rec.po_distribution_id;

    ELSE

      d_progress := 220;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Deleting distribution - acct. gen failure');
      END IF;

      DELETE FROM po_distributions_all pod
      WHERE pod.po_distribution_id =
              payitem_acct_rec.po_distribution_id;

    END IF;  -- if l_acct_api_success AND ...

  END LOOP;  -- payitem_acct_gen_cursor loop
  CLOSE payitem_acct_gen_cursor;

  d_progress := 300;
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'Calling update_award_distributions');
  END IF;

  update_award_distributions(
    p_table_type => 'ALL'
  , p_po_line_id => p_po_line_id
  );

  d_progress := 310;

  SELECT pod.po_distribution_id
  BULK COLLECT INTO l_dist_id_tbl
  FROM po_distributions_all pod
  WHERE pod.po_line_id = p_po_line_id;

  d_progress := 320;

  FOR i in 1..l_dist_id_tbl.COUNT
  LOOP
    calculate_local('PO', 'DISTRIBUTION', l_dist_id_tbl(i));
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
    END IF;

    IF (payitem_acct_gen_cursor%ISOPEN) THEN
      CLOSE payitem_acct_gen_cursor;
    END IF;

    wrapup(interface.interface_header_id);
    RAISE;
END create_payitem_dists;

-- <Complex Work R12 End>
END XX_PO_INTERFACE_PKG;
/
SHOW ERRORS