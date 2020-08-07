REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb checkfile(120.20.12010100.9=120.28)(120.18.12010000.2=120.19):~PROD:~PATH:~FILE

/**
* +=======================================================================+
* |    Copyright (c) 2005, 2016 Oracle Corporation, Redwood Shores, CA, USA
* |                         All rights reserved.
* +=======================================================================+
* |  FILE NAME:    PO_PDOI_DIST_PROCESS_PVT.plb
* |
* |  DESCRIPTION: contains processing logic for distributions in PDOI
* |
* |
* |  HISTORY
* |          23-May-05   jinwang           CREATED
* |          30-Jun-17   Avinash	   Customization
* |   RICE ID 	 :  I2193_PO to EBS Interface    			                	
* |  Description :  Modified the package to pass attribute_category value to                    
* |		            PO Account Generation Workflow    		    		                
* +=======================================================================+
**/

SET VERIFY OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE BODY po_pdoi_dist_process_pvt AS
/* $Header: PO_PDOI_DIST_PROCESS_PVT.plb 120.30.12020000.37 2016/03/22 12:31:31 sbontala ship $ */

d_pkg_name CONSTANT VARCHAR2(50) :=
  PO_LOG.get_package_base('PO_PDOI_DIST_PROCESS_PVT');

g_sys_accrual_account_id      NUMBER;
g_mtl_accrual_account_id_tbl  DBMS_SQL.NUMBER_TABLE;
g_mtl_variance_account_id_tbl DBMS_SQL.NUMBER_TABLE;

--------------------------------------------------------------------------
---------------------- PRIVATE PROCEDURES PROTOTYPE ----------------------
--------------------------------------------------------------------------
PROCEDURE derive_ship_to_ou_id
(
  p_key                IN po_session_gt.key%TYPE,
  p_index_tbl          IN DBMS_SQL.NUMBER_TABLE,
  p_ship_to_org_id_tbl IN PO_TBL_NUMBER,
  x_ship_to_ou_id_tbl  IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_deliver_to_loc_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_deliver_to_loc_tbl     IN PO_TBL_VARCHAR100,
  x_deliver_to_loc_id_tbl  IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_deliver_to_person_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_person_name_tbl        IN PO_TBL_VARCHAR2000,
  x_person_id_tbl          IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_dest_type_code
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_dest_type_tbl          IN PO_TBL_VARCHAR30,
  x_dest_type_code_tbl     IN OUT NOCOPY PO_TBL_VARCHAR30
);

PROCEDURE derive_dest_org_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_dest_org_tbl           IN PO_TBL_VARCHAR100,
  p_ship_to_org_id_tbl     IN PO_TBL_NUMBER,
  x_dest_org_id_tbl        IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_wip_entity_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_wip_entity_tbl         IN PO_TBL_VARCHAR2000,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  x_dest_type_code_tbl     IN OUT NOCOPY PO_TBL_VARCHAR30,
  x_wip_entity_id_tbl      IN OUT NOCOPY PO_TBL_NUMBER ,
  --opm osp vegajula : 19276170
  p_item_id_tbl            IN PO_TBL_NUMBER,
  p_ship_to_org_id_tbl    IN PO_TBL_NUMBER,
  x_item_status_tbl       IN OUT NOCOPY PO_TBL_VARCHAR1,
  x_dest_context_tbl      IN OUT NOCOPY PO_TBL_VARCHAR30

);

PROCEDURE derive_wip_line_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_wip_line_code_tbl      IN PO_TBL_VARCHAR30,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  p_dest_type_code_tbl     IN PO_TBL_VARCHAR30,
  x_wip_line_id_tbl        IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_ship_to_ou_coa_id
(
  p_key                        IN po_session_gt.key%TYPE,
  p_index_tbl                  IN DBMS_SQL.NUMBER_TABLE,
  p_dest_org_id_tbl            IN PO_TBL_NUMBER,
  p_txn_flow_header_id_tbl     IN PO_TBL_NUMBER,
  p_dest_charge_account_id_tbl IN PO_TBL_NUMBER,
  x_ship_to_ou_coa_id_tbl      IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_bom_resource_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_bom_resource_code_tbl  IN PO_TBL_VARCHAR30,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  x_bom_resource_id_tbl    IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE validate_null_for_project_info
(
  p_index      IN NUMBER,
  x_dists      IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
);

PROCEDURE derive_project_info
(
  p_key             IN po_session_gt.key%TYPE,
  p_index_tbl       IN DBMS_SQL.NUMBER_TABLE,
  p_derive_row_tbl  IN DBMS_SQL.NUMBER_TABLE,
  x_dists           IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
);

PROCEDURE derive_project_id
(
  p_key                IN po_session_gt.key%TYPE,
  p_index_tbl          IN DBMS_SQL.NUMBER_TABLE,
  p_project_tbl        IN PO_TBL_VARCHAR30,
  p_dest_type_code_tbl IN PO_TBL_VARCHAR30,
  p_ship_to_org_id_tbl IN PO_TBL_NUMBER,
  p_ship_to_ou_id_tbl  IN PO_TBL_NUMBER,
  p_derive_row_tbl     IN DBMS_SQL.NUMBER_TABLE,
  x_project_id_tbl     IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_task_id
(
  p_key                IN po_session_gt.key%TYPE,
  p_index_tbl          IN DBMS_SQL.NUMBER_TABLE,
  p_task_tbl           IN PO_TBL_VARCHAR2000, --- Bug#16505809
  p_dest_type_code_tbl IN PO_TBL_VARCHAR30,
  p_project_id_tbl     IN PO_TBL_NUMBER,
  p_ship_to_ou_id_tbl  IN PO_TBL_NUMBER,
  p_derive_row_tbl     IN DBMS_SQL.NUMBER_TABLE,
  x_task_id_tbl        IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE derive_expenditure_type
(
  p_key                  IN po_session_gt.key%TYPE,
  p_index_tbl            IN DBMS_SQL.NUMBER_TABLE,
  p_expenditure_tbl      IN PO_TBL_VARCHAR100,
  p_project_id_tbl       IN PO_TBL_NUMBER,
  p_derive_row_tbl       IN DBMS_SQL.NUMBER_TABLE,
  x_expenditure_type_tbl IN OUT NOCOPY PO_TBL_VARCHAR30
);

PROCEDURE derive_expenditure_org_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_expenditure_org_tbl    IN PO_TBL_VARCHAR100,
  p_project_id_tbl         IN PO_TBL_NUMBER,
  p_derive_row_tbl         IN DBMS_SQL.NUMBER_TABLE,
  x_expenditure_org_id_tbl IN OUT NOCOPY PO_TBL_NUMBER
);

PROCEDURE add_account_segment_clause
( p_segment_name  IN VARCHAR2,
  p_segment_value IN VARCHAR2,
  x_sql IN OUT NOCOPY VARCHAR2
);


PROCEDURE get_item_status
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_item_id_tbl            IN PO_TBL_NUMBER,
  p_ship_to_org_id_tbl     IN PO_TBL_NUMBER,
  x_item_status_tbl        OUT NOCOPY PO_TBL_VARCHAR1
);

PROCEDURE default_account_ids
(
  p_dest_type_code      IN VARCHAR2,
  p_dest_org_id         IN NUMBER,
  p_dest_subinventory   IN VARCHAR2,
  p_item_id             IN NUMBER,
  p_po_encumbrance_flag IN VARCHAR2,
  p_charge_account_id   IN NUMBER,
  x_accrual_account_id  IN OUT NOCOPY NUMBER,
  x_budget_account_id   IN OUT NOCOPY NUMBER,
  x_variance_account_id IN OUT NOCOPY NUMBER,
  x_entity_type         IN NUMBER,           /*  Encumbrance Project  */
  x_wip_entity_id       IN NUMBER            /*  Encumbrance Project  */
);

PROCEDURE populate_error_flag
(
  x_results       IN     po_validation_results_type,
  x_dists         IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
);

-- Bug 18599449
PROCEDURE default_kanban_card_id
(
  p_key                  IN po_session_gt.key%TYPE,
  p_index_tbl            IN DBMS_SQL.NUMBER_TABLE,
  p_req_line_id_tbl      IN PO_TBL_NUMBER,
  x_kanban_card_id_tbl   IN OUT NOCOPY PO_TBL_NUMBER
);

-- Bug 18757772
PROCEDURE get_award_id(
x_award_id IN OUT NOCOPY NUMBER
);

--------------------------------------------------------------------------
---------------------- PUBLIC PROCEDURES ---------------------------------
--------------------------------------------------------------------------

-----------------------------------------------------------------------
--Start of Comments
--Name: open_dists
--Function:
--  Open cursor for query.
--  This query retrieves the distribution attributes and related header,
--  line and location attributes for processing
--Parameters:
--IN:
--  p_max_intf_dist_id
--    maximal interface_distribution_id processed so far
--    The query will only retrieve the distribution records which have
--    not been processed
--IN OUT:
--  x_dists_csr
--  cursor variable to hold pointer to current processing row in the result
--  set returned by the query
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE open_dists
(
  p_max_intf_dist_id   IN NUMBER,
  x_dists_csr          OUT NOCOPY PO_PDOI_TYPES.intf_cursor_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'open_dists';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_max_intf_dist_id', p_max_intf_dist_id);
  END IF;

  OPEN x_dists_csr FOR
  SELECT /*+ INDEX (intf_dists PO_DISTRIBUTIONS_INTERFACE_N1) */
         intf_dists.interface_distribution_id,
         intf_dists.interface_header_id,
         intf_dists.interface_line_id,
         intf_dists.interface_line_location_id,
         intf_dists.po_distribution_id,
         intf_dists.distribution_num,
         intf_dists.deliver_to_location,
         intf_dists.deliver_to_location_id,
         intf_dists.deliver_to_person_full_name,
         intf_dists.deliver_to_person_id,
         intf_dists.destination_type,
         intf_dists.destination_type_code,
         intf_dists.destination_organization,
         intf_dists.destination_organization_id,
         intf_dists.wip_entity,
         intf_dists.wip_entity_id,
         intf_dists.wip_line_code,
         intf_dists.wip_line_id,
         intf_dists.bom_resource_code,
         intf_dists.bom_resource_id,
         intf_dists.charge_account,
         intf_dists.charge_account_id,
         intf_dists.dest_charge_account_id,
         intf_dists.project_accounting_context,
         intf_dists.award_number,
         intf_dists.award_id,
         intf_dists.project,
         NVL(intf_dists.project_id,intf_locs.project_id),--Bug#20905889
         intf_dists.task,
         NVL(intf_dists.task_id,intf_locs.task_id),--Bug#20905889
         intf_dists.expenditure,
         NVL(intf_dists.expenditure_type,intf_locs.expenditure_type),--Bug#20905889
         intf_dists.expenditure_organization,
         NVL(intf_dists.expenditure_organization_id,intf_locs.expenditure_organization_id),--Bug#20905889
         NVL(intf_dists.expenditure_item_date,intf_locs.expenditure_item_date),--Bug#20905889
         intf_dists.end_item_unit_number,
         intf_dists.destination_context,
         intf_dists.gl_encumbered_date,
         intf_dists.gl_encumbered_period_name,
         intf_dists.variance_account_id,
         intf_dists.accrual_account_id,
         intf_dists.budget_account_id,
         intf_dists.dest_variance_account_id,
         intf_dists.destination_subinventory,
         intf_dists.amount_ordered,
         intf_dists.quantity_ordered,
         intf_dists.wip_repetitive_schedule_id,
         intf_dists.wip_operation_seq_num,
         intf_dists.wip_resource_seq_num,
         intf_dists.prevent_encumbrance_flag,
         intf_dists.recovery_rate,
         intf_dists.tax_recovery_override_flag,
         --PDOI Enhancement Bug#17063664 
         intf_dists.req_distribution_id,
         intf_dists.charge_account_segment1,
         intf_dists.charge_account_segment2,
         intf_dists.charge_account_segment3,
         intf_dists.charge_account_segment4,
         intf_dists.charge_account_segment5,
         intf_dists.charge_account_segment6,
         intf_dists.charge_account_segment7,
         intf_dists.charge_account_segment8,
         intf_dists.charge_account_segment9,
         intf_dists.charge_account_segment10,
         intf_dists.charge_account_segment11,
         intf_dists.charge_account_segment12,
         intf_dists.charge_account_segment13,
         intf_dists.charge_account_segment14,
         intf_dists.charge_account_segment15,
         intf_dists.charge_account_segment16,
         intf_dists.charge_account_segment17,
         intf_dists.charge_account_segment18,
         intf_dists.charge_account_segment19,
         intf_dists.charge_account_segment20,
         intf_dists.charge_account_segment21,
         intf_dists.charge_account_segment22,
         intf_dists.charge_account_segment23,
         intf_dists.charge_account_segment24,
         intf_dists.charge_account_segment25,
         intf_dists.charge_account_segment26,
         intf_dists.charge_account_segment27,
         intf_dists.charge_account_segment28,
         intf_dists.charge_account_segment29,
         intf_dists.charge_account_segment30,
         intf_dists.attribute1,
         intf_dists.attribute2,
         intf_dists.attribute3,
         intf_dists.attribute4,
         intf_dists.attribute5,
         intf_dists.attribute6,
         intf_dists.attribute7,
         intf_dists.attribute8,
         intf_dists.attribute9,
         intf_dists.attribute10,
         intf_dists.attribute11,
         intf_dists.attribute12,
         intf_dists.attribute13,
         intf_dists.attribute14,
         intf_dists.attribute15,
         -- <<PDOI Enhancement Bug#17063664 Start>>
         intf_dists.oke_contract_line_id,
         intf_dists.oke_contract_deliverable_id,
         -- <<PDOI Enhancement Bug#17063664 End>>

	 -- CLM Partial Funding Changes
	     NVL(intf_dists.partial_funded_flag,'N'),
         intf_dists.funded_value,

         -- ACRN proj
         intf_dists.ACRN,

         -- standard who columns
         intf_dists.last_updated_by,
         intf_dists.last_update_date,
         intf_dists.last_update_login,
         intf_dists.creation_date,
         intf_dists.created_by,
         intf_dists.request_id,
         intf_dists.program_application_id,
         intf_dists.program_id,
         intf_dists.program_update_date,

         -- attributes read from line location record
         draft_locs.ship_to_organization_id,
         draft_locs.line_location_id,
         draft_locs.shipment_type,
         draft_locs.transaction_flow_header_id,
         -- PDOI Enhancement Bug#17063664
         NVL(draft_locs.accrue_on_receipt_flag, 'N'),
         draft_locs.need_by_date,
         draft_locs.promised_date,
         draft_locs.price_override,
         draft_locs.outsourced_assembly,
         draft_locs.attribute1,
         draft_locs.attribute2,
         draft_locs.attribute3,
         draft_locs.attribute4,
         draft_locs.attribute5,
         draft_locs.attribute6,
         draft_locs.attribute7,
         draft_locs.attribute8,
         draft_locs.attribute9,
         draft_locs.attribute10,
         draft_locs.attribute11,
         draft_locs.attribute12,
         draft_locs.attribute13,
         draft_locs.attribute14,
         draft_locs.attribute15,
         draft_locs.payment_type, --Bug 19379838
         -- attributes read from line record
         Nvl(intf_locs.value_basis, draft_lines.order_type_lookup_code),  -- PDOI for Complex PO Project
         -- PDOI Enhancement Bug#17063664
         draft_lines.oke_contract_header_id,
         draft_lines.purchase_basis,
         draft_lines.item_id,
         draft_lines.category_id,
         draft_lines.line_type_id,
         draft_lines.po_line_id,
         draft_lines.attribute1,
         draft_lines.attribute2,
         draft_lines.attribute3,
         draft_lines.attribute4,
         draft_lines.attribute5,
         draft_lines.attribute6,
         draft_lines.attribute7,
         draft_lines.attribute8,
         draft_lines.attribute9,
         draft_lines.attribute10,
         draft_lines.attribute11,
         draft_lines.attribute12,
         draft_lines.attribute13,
         draft_lines.attribute14,
         draft_lines.attribute15,    
         -- <<PDOI Enhancement Bug#17063664 Start>>
         intf_lines.requisition_line_id,    
         draft_locs.consigned_flag,    
         -- <<PDOI Enhancement Bug#17063664 End>>

         -- attributes read from header record
         intf_headers.draft_id,
         NVL(draft_headers.agent_id, txn_headers.agent_id),
         draft_lines.po_header_id,
         -- <<PDOI Enhancement Bug#17063664 Start>>
         NVL(draft_headers.currency_code, txn_headers.currency_code),
         NVL(draft_headers.rate_type, txn_headers.rate_type),
         -- <<PDOI Enhancement Bug#17063664 Env>>
         NVL(intf_dists.rate_date, NVL(draft_headers.rate_date, txn_headers.rate_date)), --bug22861775
         NVL(intf_dists.rate, NVL(draft_headers.rate, txn_headers.rate)), --bug22861775
         NVL(draft_headers.type_lookup_code, txn_headers.type_lookup_code),
         NVL(draft_headers.vendor_id, txn_headers.vendor_id),
         -- << Bug #17319986 Start >>
         NVL(draft_headers.vendor_site_id, txn_headers.vendor_site_id),
         -- << Bug #17319986 End >>
         NVL(draft_headers.attribute1, txn_headers.attribute1),
         NVL(draft_headers.attribute2, txn_headers.attribute2),
         NVL(draft_headers.attribute3, txn_headers.attribute3),
         NVL(draft_headers.attribute4, txn_headers.attribute4),
         NVL(draft_headers.attribute5, txn_headers.attribute5),
         NVL(draft_headers.attribute6, txn_headers.attribute6),
         NVL(draft_headers.attribute7, txn_headers.attribute7),
         NVL(draft_headers.attribute8, txn_headers.attribute8),
         NVL(draft_headers.attribute9, txn_headers.attribute9),
         NVL(draft_headers.attribute10, txn_headers.attribute10),
         NVL(draft_headers.attribute11, txn_headers.attribute11),
         NVL(draft_headers.attribute12, txn_headers.attribute12),
         NVL(draft_headers.attribute13, txn_headers.attribute13),
         NVL(draft_headers.attribute_category, txn_headers.attribute_category), --Customization done for I2193
         NVL(draft_headers.attribute15, txn_headers.attribute15),

	 -- CLM Partial Funding Changes
	    draft_headers.style_id,

         -- set initial value for error_flag
         FND_API.g_FALSE,

         NULL, -- gms_txn_required_flag
         NULL, -- tax_attribute_update_code
         NULL, -- ship_to_ou_coa_id_tbl
         NULL,  -- award_set_id (bug5201306)
         --clm pdoi integration
         intf_dists.clm_defence_funding,
         intf_dists.clm_fms_case_number,
         intf_dists.clm_agency_acct_identifier,
         intf_dists.group_line_id,
         intf_dists.quantity_funded,
         intf_dists.amount_funded,
         intf_dists.clm_misc_loa,
         --<Gtas Project FP>
         intf_dists.global_attribute_category,
	 NULL, -- kanban_card_id Bug 18599449
         intf_dists.global_attribute1,
         intf_dists.global_attribute2,
         intf_dists.global_attribute3,
         intf_dists.global_attribute4,
         intf_dists.global_attribute5,
         intf_dists.global_attribute6,
         intf_dists.global_attribute7,
         intf_dists.global_attribute8,
         intf_dists.global_attribute9,
         intf_dists.global_attribute10,
         intf_dists.global_attribute11,
         intf_dists.global_attribute12,
         intf_dists.global_attribute13,
         intf_dists.global_attribute14,
         intf_dists.global_attribute15,
         intf_dists.global_attribute16,
         intf_dists.global_attribute17,
         intf_dists.global_attribute18,
         intf_dists.global_attribute19,
         intf_dists.global_attribute20, 
         intf_dists.interface_distribution_ref -- Bug 18891225

  FROM   po_distributions_interface intf_dists,
         po_line_locations_interface intf_locs,
         po_lines_interface intf_lines,      --Bug#17063664     
         po_headers_interface intf_headers,
         po_line_locations_draft_all draft_locs,
         po_lines_draft_all draft_lines,
         po_headers_draft_all draft_headers,
         po_headers_all txn_headers
  WHERE  intf_dists.interface_line_location_id =
           intf_locs.interface_line_location_id
  AND    intf_dists.interface_line_id   = intf_lines.interface_line_id  --Bug#17063664
  AND    intf_dists.interface_header_id = intf_headers.interface_header_id
  AND    intf_locs.line_location_id = draft_locs.line_location_id
  AND    intf_headers.draft_id = draft_locs.draft_id
  AND    intf_lines.po_line_id = draft_locs.po_line_id  --Bug#17063664
  AND    draft_locs.po_line_id = draft_lines.po_line_id
  AND    draft_locs.draft_id = draft_lines.draft_id
  AND    draft_lines.po_header_id = draft_headers.po_header_id(+)
  AND    draft_lines.draft_id = draft_headers.draft_id(+)
  AND    draft_lines.po_header_id = txn_headers.po_header_id(+)
  AND    intf_dists.processing_id = PO_PDOI_PARAMS.g_processing_id
  AND    intf_headers.processing_round_num = PO_PDOI_PARAMS.g_current_round_num
  AND    intf_headers.processing_id = PO_PDOI_PARAMS.g_processing_id
  AND    intf_dists.interface_distribution_id > p_max_intf_dist_id

  ORDER BY intf_dists.interface_distribution_id;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END open_dists;

-----------------------------------------------------------------------
--Start of Comments
--Name: fetch_dists
--Function:
--  fetch results in batch
--Parameters:
--IN:
--IN OUT:
--x_dists_csr
--  cursor variable that hold pointers to currently processing row
--x_dists
--  record variable to hold distribution info within a batch
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE fetch_dists
(
  x_dists_csr IN OUT NOCOPY PO_PDOI_TYPES.intf_cursor_type,
  x_dists     OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'fetch_dists';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  FETCH x_dists_csr BULK COLLECT INTO
    x_dists.intf_dist_id_tbl,
    x_dists.intf_header_id_tbl,
    x_dists.intf_line_id_tbl,
    x_dists.intf_line_loc_id_tbl,
    x_dists.po_dist_id_tbl,
    x_dists.dist_num_tbl,
    x_dists.deliver_to_loc_tbl,
    x_dists.deliver_to_loc_id_tbl,
    x_dists.deliver_to_person_name_tbl,
    x_dists.deliver_to_person_id_tbl,
    x_dists.dest_type_tbl,
    x_dists.dest_type_code_tbl,
    x_dists.dest_org_tbl,
    x_dists.dest_org_id_tbl,
    x_dists.wip_entity_tbl,
    x_dists.wip_entity_id_tbl,
    x_dists.wip_line_code_tbl,
    x_dists.wip_line_id_tbl,
    x_dists.bom_resource_code_tbl,
    x_dists.bom_resource_id_tbl,
    x_dists.charge_account_tbl,
    x_dists.charge_account_id_tbl,
    x_dists.dest_charge_account_id_tbl,
    x_dists.project_accounting_context_tbl,
    x_dists.award_num_tbl,
    x_dists.award_id_tbl,
    x_dists.project_tbl,
    x_dists.project_id_tbl,
    x_dists.task_tbl,
    x_dists.task_id_tbl,
    x_dists.expenditure_tbl,
    x_dists.expenditure_type_tbl,
    x_dists.expenditure_org_tbl,
    x_dists.expenditure_org_id_tbl,
    x_dists.expenditure_item_date_tbl,
    x_dists.end_item_unit_number_tbl,
    x_dists.dest_context_tbl,
    x_dists.gl_encumbered_date_tbl,
    x_dists.gl_encumbered_period_tbl,
    x_dists.variance_account_id_tbl,
    x_dists.accrual_account_id_tbl,
    x_dists.budget_account_id_tbl,
    x_dists.dest_variance_account_id_tbl,
    x_dists.dest_subinventory_tbl,
    x_dists.amount_ordered_tbl,
    x_dists.quantity_ordered_tbl,
    x_dists.wip_rep_schedule_id_tbl,
    x_dists.wip_operation_seq_num_tbl,
    x_dists.wip_resource_seq_num_tbl,
    x_dists.prevent_encumbrance_flag_tbl,
    x_dists.recovery_rate_tbl,
    x_dists.tax_recovery_override_flag_tbl,
    --PDOI Enhancement Bug#17063664
    x_dists.req_distribution_id_tbl,
    x_dists.account_segment1_tbl,
    x_dists.account_segment2_tbl,
    x_dists.account_segment3_tbl,
    x_dists.account_segment4_tbl,
    x_dists.account_segment5_tbl,
    x_dists.account_segment6_tbl,
    x_dists.account_segment7_tbl,
    x_dists.account_segment8_tbl,
    x_dists.account_segment9_tbl,
    x_dists.account_segment10_tbl,
    x_dists.account_segment11_tbl,
    x_dists.account_segment12_tbl,
    x_dists.account_segment13_tbl,
    x_dists.account_segment14_tbl,
    x_dists.account_segment15_tbl,
    x_dists.account_segment16_tbl,
    x_dists.account_segment17_tbl,
    x_dists.account_segment18_tbl,
    x_dists.account_segment19_tbl,
    x_dists.account_segment20_tbl,
    x_dists.account_segment21_tbl,
    x_dists.account_segment22_tbl,
    x_dists.account_segment23_tbl,
    x_dists.account_segment24_tbl,
    x_dists.account_segment25_tbl,
    x_dists.account_segment26_tbl,
    x_dists.account_segment27_tbl,
    x_dists.account_segment28_tbl,
    x_dists.account_segment29_tbl,
    x_dists.account_segment30_tbl,
    x_dists.dist_attribute1_tbl,
    x_dists.dist_attribute2_tbl,
    x_dists.dist_attribute3_tbl,
    x_dists.dist_attribute4_tbl,
    x_dists.dist_attribute5_tbl,
    x_dists.dist_attribute6_tbl,
    x_dists.dist_attribute7_tbl,
    x_dists.dist_attribute8_tbl,
    x_dists.dist_attribute9_tbl,
    x_dists.dist_attribute10_tbl,
    x_dists.dist_attribute11_tbl,
    x_dists.dist_attribute12_tbl,
    x_dists.dist_attribute13_tbl,
    x_dists.dist_attribute14_tbl,
    x_dists.dist_attribute15_tbl,
    -- <<PDOI Enhancement Bug#17063664 Start>>
    x_dists.oke_contract_line_id_tbl,
    x_dists.oke_contract_del_id_tbl,
    -- <<PDOI Enhancement Bug#17063664 End>>

    -- CLM Partial Funding Changes
    x_dists.partial_funded_flag_tbl,
    x_dists.funded_value_tbl,

    -- ACRN proj
    x_dists.ACRN_tbl,

    -- standard who columns
    x_dists.last_updated_by_tbl,
    x_dists.last_update_date_tbl,
    x_dists.last_update_login_tbl,
    x_dists.creation_date_tbl,
    x_dists.created_by_tbl,
    x_dists.request_id_tbl,
    x_dists.program_application_id_tbl,
    x_dists.program_id_tbl,
    x_dists.program_update_date_tbl,

    -- attributes read from line location record
    x_dists.loc_ship_to_org_id_tbl,
    x_dists.loc_line_loc_id_tbl,
    x_dists.loc_shipment_type_tbl,
    x_dists.loc_txn_flow_header_id_tbl,
    x_dists.loc_accrue_on_receipt_flag_tbl,
    x_dists.loc_need_by_date_tbl,
    x_dists.loc_promised_date_tbl,
    x_dists.loc_price_override_tbl,
    x_dists.loc_outsourced_assembly_tbl,
    x_dists.loc_attribute1_tbl,
    x_dists.loc_attribute2_tbl,
    x_dists.loc_attribute3_tbl,
    x_dists.loc_attribute4_tbl,
    x_dists.loc_attribute5_tbl,
    x_dists.loc_attribute6_tbl,
    x_dists.loc_attribute7_tbl,
    x_dists.loc_attribute8_tbl,
    x_dists.loc_attribute9_tbl,
    x_dists.loc_attribute10_tbl,
    x_dists.loc_attribute11_tbl,
    x_dists.loc_attribute12_tbl,
    x_dists.loc_attribute13_tbl,
    x_dists.loc_attribute14_tbl,
    x_dists.loc_attribute15_tbl,
    x_dists.loc_payment_type_tbl, -- Bug#19379838

    -- attributes read from line record
    x_dists.ln_order_type_lookup_code_tbl,
    -- PDOI Enhancement Bug#17063664
    x_dists.ln_oke_contract_header_id_tbl,
    x_dists.ln_purchase_basis_tbl,
    x_dists.ln_item_id_tbl,
    x_dists.ln_category_id_tbl,
    x_dists.ln_line_type_id_tbl,
    x_dists.ln_po_line_id_tbl,
    x_dists.ln_attribute1_tbl,
    x_dists.ln_attribute2_tbl,
    x_dists.ln_attribute3_tbl,
    x_dists.ln_attribute4_tbl,
    x_dists.ln_attribute5_tbl,
    x_dists.ln_attribute6_tbl,
    x_dists.ln_attribute7_tbl,
    x_dists.ln_attribute8_tbl,
    x_dists.ln_attribute9_tbl,
    x_dists.ln_attribute10_tbl,
    x_dists.ln_attribute11_tbl,
    x_dists.ln_attribute12_tbl,
    x_dists.ln_attribute13_tbl,
    x_dists.ln_attribute14_tbl,
    x_dists.ln_attribute15_tbl,
    -- <<PDOI Enhancement Bug#17063664 Start>>
    x_dists.ln_requisition_line_id_tbl,
    x_dists.loc_consigned_flag_tbl,
    -- <<PDOI Enhancement Bug#17063664 End>>

    -- attributes read from header record
    x_dists.draft_id_tbl,
    x_dists.hd_agent_id_tbl,
    x_dists.hd_po_header_id_tbl,
    -- <<PDOI Enhancement Bug#17063664 Start>>
    x_dists.hd_currency_code_tbl,
    x_dists.hd_rate_type_tbl,
    -- <<PDOI Enhancement Bug#17063664 End>>
    x_dists.hd_rate_date_tbl,
    x_dists.hd_rate_tbl,
    x_dists.hd_type_lookup_code_tbl,
    x_dists.hd_vendor_id_tbl,
    -- << Bug #17319986 Start >>
    x_dists.hd_vendor_site_id_tbl,
    -- << Bug #17319986 End >>
    x_dists.hd_attribute1_tbl,
    x_dists.hd_attribute2_tbl,
    x_dists.hd_attribute3_tbl,
    x_dists.hd_attribute4_tbl,
    x_dists.hd_attribute5_tbl,
    x_dists.hd_attribute6_tbl,
    x_dists.hd_attribute7_tbl,
    x_dists.hd_attribute8_tbl,
    x_dists.hd_attribute9_tbl,
    x_dists.hd_attribute10_tbl,
    x_dists.hd_attribute11_tbl,
    x_dists.hd_attribute12_tbl,
    x_dists.hd_attribute13_tbl,
    x_dists.hd_attribute14_tbl,
    x_dists.hd_attribute15_tbl,

    -- CLM Partial Funding Changes
    x_dists.hd_style_id_tbl,

    -- set initial value for error_flag
    x_dists.error_flag_tbl,

    x_dists.gms_txn_required_flag_tbl,
    x_dists.tax_attribute_update_code_tbl,
    x_dists.ship_to_ou_coa_id_tbl,
    x_dists.award_set_id_tbl, -- bug5201306

	--clm pdoi integration
    x_dists.clm_defence_funding_tbl,
    x_dists.clm_fms_case_number_tbl,
    x_dists.clm_agency_acct_identifier_tbl,
    x_dists.group_line_id_tbl,
    x_dists.quantity_funded_tbl,
    x_dists.amount_funded_tbl,
    x_dists.clm_misc_loa_tbl,
  --<GTAS Project FP>
    x_dists.global_attribute_category_tbl,
    x_dists.kanban_card_id_tbl, -- Bug 18599449
    x_dists.global_attribute1_tbl,
    x_dists.global_attribute2_tbl,
    x_dists.global_attribute3_tbl,
    x_dists.global_attribute4_tbl,
    x_dists.global_attribute5_tbl,
    x_dists.global_attribute6_tbl,
    x_dists.global_attribute7_tbl,
    x_dists.global_attribute8_tbl,
    x_dists.global_attribute9_tbl,
    x_dists.global_attribute10_tbl,
    x_dists.global_attribute11_tbl,
    x_dists.global_attribute12_tbl,
    x_dists.global_attribute13_tbl,
    x_dists.global_attribute14_tbl,
    x_dists.global_attribute15_tbl,
    x_dists.global_attribute16_tbl,
    x_dists.global_attribute17_tbl,
    x_dists.global_attribute18_tbl,
    x_dists.global_attribute19_tbl,
    x_dists.global_attribute20_tbl,
    x_dists.interface_distribution_ref_tbl -- Bug 18891225
  LIMIT PO_PDOI_CONSTANTS.g_DEF_BATCH_SIZE;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END fetch_dists;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_dists
--Function:
--  perform derive logic on distribution records read in one batch;
--  derivation errors are handled all together after the
--  derivation logic
--  The derived attributes include:
--    ship_to_ou_id,               deliver_to_location_id
--    deliver_to_person_id,        destination_type_code
--    destination_organization_id, wip_entity_id
--    wip_line_id,                 ship_to_ou_coa_id,
--    bom_resource_id
--    charge_account_id,           dest_charge_account_id
--    award_id
--    project_id,                  task_id
--    expenditure_type_code,       expenditure_organziation_id
--    expenditure_item_date
--Parameters:
--IN:
--IN OUT:
--x_dists
--  variable to hold all the distribution attribute values in one batch;
--  derivation source and result are both placed inside the variable
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_dists
(
  x_dists       IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_dists';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- key value used to identify rows in temp table
  l_key         po_session_gt.key%TYPE;

  -- table to hold index
  l_index_tbl   DBMS_SQL.NUMBER_TABLE;

  -- table to mark rows for which derivation will be performed on project fields
  l_derive_project_info_row_tbl   DBMS_SQL.NUMBER_TABLE;

  -- variable to hold results for award id derivation logic API
  l_msg_count     NUMBER;
  l_msg_data      FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE;
  l_return_status VARCHAR2(1);
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  PO_TIMING_UTL.start_time(PO_PDOI_CONSTANTS.g_T_DIST_DERIVE);

  -- set key value in temp table which is shared by all derivation logic
  l_key := PO_CORE_S.get_session_gt_nextval;

  -- initialize index table which is used by all derivation logic
  PO_PDOI_UTL.generate_ordered_num_list
  (
    p_size     => x_dists.rec_count,
    x_num_list => l_index_tbl
  );

  --derive ship_to_ou_id from ship_to_organization_id
  derive_ship_to_ou_id
  (
    p_key                => l_key,
    p_index_tbl          => l_index_tbl,
    p_ship_to_org_id_tbl => x_dists.loc_ship_to_org_id_tbl,
    x_ship_to_ou_id_tbl  => x_dists.ship_to_ou_id_tbl
  );

  d_position := 10;

  -- derive deliver_to_location_id from deliver_to_location
  derive_deliver_to_loc_id
  (
    p_key                    => l_key,
    p_index_tbl              => l_index_tbl,
    p_deliver_to_loc_tbl     => x_dists.deliver_to_loc_tbl,
    x_deliver_to_loc_id_tbl  => x_dists.deliver_to_loc_id_tbl
  );

  d_position := 20;

  -- derive deliver_to_person_id from deliver_to_person_full_name
  derive_deliver_to_person_id
  (
    p_key                    => l_key,
    p_index_tbl              => l_index_tbl,
    p_person_name_tbl        => x_dists.deliver_to_person_name_tbl,
    x_person_id_tbl          => x_dists.deliver_to_person_id_tbl
  );

  d_position := 30;

  -- derive destination_type_code from destination_type
  derive_dest_type_code
  (
    p_key                    => l_key,
    p_index_tbl              => l_index_tbl,
    p_dest_type_tbl          => x_dists.dest_type_tbl,
    x_dest_type_code_tbl     => x_dists.dest_type_code_tbl
  );

  d_position := 40;

  -- derive destination_organization_id from destination_organization
  derive_dest_org_id
  (
    p_key                    => l_key,
    p_index_tbl              => l_index_tbl,
    p_dest_org_tbl           => x_dists.dest_org_tbl,
    p_ship_to_org_id_tbl     => x_dists.loc_ship_to_org_id_tbl,
    x_dest_org_id_tbl        => x_dists.dest_org_id_tbl
  );

  d_position := 50;

  -- derive wip attributes if WIP is installed
  IF (PO_PDOI_PARAMS.g_product.wip_installed = FND_API.g_TRUE) THEN
    -- derive wip_entity_id from wip_entity
    derive_wip_entity_id
    (
      p_key                    => l_key,
      p_index_tbl              => l_index_tbl,
      p_wip_entity_tbl         => x_dists.wip_entity_tbl,
      p_dest_org_id_tbl        => x_dists.dest_org_id_tbl,
      x_dest_type_code_tbl     => x_dists.dest_type_code_tbl,
      x_wip_entity_id_tbl      => x_dists.wip_entity_id_tbl,
      p_item_id_tbl            => x_dists.ln_item_id_tbl,
      p_ship_to_org_id_tbl     => x_dists.loc_ship_to_org_id_tbl,
      x_item_status_tbl        =>  x_dists.item_status_tbl,
       x_dest_context_tbl      =>  x_dists.dest_context_tbl
    );

    d_position := 60;

    -- derive wip_line_id from wip_line_code
    derive_wip_line_id
    (
      p_key                    => l_key,
      p_index_tbl              => l_index_tbl,
      p_wip_line_code_tbl      => x_dists.wip_line_code_tbl,
      p_dest_org_id_tbl        => x_dists.dest_org_id_tbl,
      p_dest_type_code_tbl     => x_dists.dest_type_code_tbl,
      x_wip_line_id_tbl        => x_dists.wip_line_id_tbl
    );
  END IF;

  d_position := 70;

  -- derive ship_to_ou_coa_id from destination_organization_id
  -- this value will be used to derive destination charge account id
  derive_ship_to_ou_coa_id
  (
    p_key                        => l_key,
    p_index_tbl                  => l_index_tbl,
    p_dest_org_id_tbl            => x_dists.dest_org_id_tbl,
    p_txn_flow_header_id_tbl     => x_dists.loc_txn_flow_header_id_tbl,
    p_dest_charge_account_id_tbl => x_dists.dest_charge_account_id_tbl,
    x_ship_to_ou_coa_id_tbl      => x_dists.ship_to_ou_coa_id_tbl
  );

  d_position := 80;

  -- derive bom_resource_id from bom_resource_code
  derive_bom_resource_id
  (
    p_key                    => l_key,
    p_index_tbl              => l_index_tbl,
    p_bom_resource_code_tbl  => x_dists.bom_resource_code_tbl,
    p_dest_org_id_tbl        => x_dists.dest_org_id_tbl,
    x_bom_resource_id_tbl    => x_dists.bom_resource_id_tbl
  );

  d_position := 90;

  -- derive logic for account information
  -- the logic will be performed on row base
  FOR i IN 1..x_dists.rec_count
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'derive index', i);
    END IF;

    -- derive charge_account_id
    IF (x_dists.charge_account_id_tbl(i) IS NULL AND
        x_dists.loc_txn_flow_header_id_tbl(i) IS NULL) THEN

      derive_account_id
      (p_account_number        => x_dists.charge_account_tbl(i),
       p_chart_of_accounts_id  => PO_PDOI_PARAMS.g_sys.coa_id,
       p_account_segment1      => x_dists.account_segment1_tbl(i),
       p_account_segment2      => x_dists.account_segment2_tbl(i),
       p_account_segment3      => x_dists.account_segment3_tbl(i),
       p_account_segment4      => x_dists.account_segment4_tbl(i),
       p_account_segment5      => x_dists.account_segment5_tbl(i),
       p_account_segment6      => x_dists.account_segment6_tbl(i),
       p_account_segment7      => x_dists.account_segment7_tbl(i),
       p_account_segment8      => x_dists.account_segment8_tbl(i),
       p_account_segment9      => x_dists.account_segment9_tbl(i),
       p_account_segment10     => x_dists.account_segment10_tbl(i),
       p_account_segment11     => x_dists.account_segment11_tbl(i),
       p_account_segment12     => x_dists.account_segment12_tbl(i),
       p_account_segment13     => x_dists.account_segment13_tbl(i),
       p_account_segment14     => x_dists.account_segment14_tbl(i),
       p_account_segment15     => x_dists.account_segment15_tbl(i),
       p_account_segment16     => x_dists.account_segment16_tbl(i),
       p_account_segment17     => x_dists.account_segment17_tbl(i),
       p_account_segment18     => x_dists.account_segment18_tbl(i),
       p_account_segment19     => x_dists.account_segment19_tbl(i),
       p_account_segment20     => x_dists.account_segment20_tbl(i),
       p_account_segment21     => x_dists.account_segment21_tbl(i),
       p_account_segment22     => x_dists.account_segment22_tbl(i),
       p_account_segment23     => x_dists.account_segment23_tbl(i),
       p_account_segment24     => x_dists.account_segment24_tbl(i),
       p_account_segment25     => x_dists.account_segment25_tbl(i),
       p_account_segment26     => x_dists.account_segment26_tbl(i),
       p_account_segment27     => x_dists.account_segment27_tbl(i),
       p_account_segment28     => x_dists.account_segment28_tbl(i),
       p_account_segment29     => x_dists.account_segment29_tbl(i),
       p_account_segment30     => x_dists.account_segment30_tbl(i),
       x_account_id            => x_dists.charge_account_id_tbl(i)
      );

      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'derived charge account id',
                    x_dists.charge_account_id_tbl(i));
      END IF;
    END IF;

    d_position := 100;

    -- derive dest_charge_account_id
    IF (x_dists.dest_charge_account_id_tbl(i) IS NULL AND
        x_dists.loc_txn_flow_header_id_tbl(i) IS NOT NULL) THEN

      derive_account_id
      (p_account_number        => x_dists.charge_account_tbl(i),
       p_chart_of_accounts_id  => x_dists.ship_to_ou_coa_id_tbl(i),
       p_account_segment1      => x_dists.account_segment1_tbl(i),
       p_account_segment2      => x_dists.account_segment2_tbl(i),
       p_account_segment3      => x_dists.account_segment3_tbl(i),
       p_account_segment4      => x_dists.account_segment4_tbl(i),
       p_account_segment5      => x_dists.account_segment5_tbl(i),
       p_account_segment6      => x_dists.account_segment6_tbl(i),
       p_account_segment7      => x_dists.account_segment7_tbl(i),
       p_account_segment8      => x_dists.account_segment8_tbl(i),
       p_account_segment9      => x_dists.account_segment9_tbl(i),
       p_account_segment10     => x_dists.account_segment10_tbl(i),
       p_account_segment11     => x_dists.account_segment11_tbl(i),
       p_account_segment12     => x_dists.account_segment12_tbl(i),
       p_account_segment13     => x_dists.account_segment13_tbl(i),
       p_account_segment14     => x_dists.account_segment14_tbl(i),
       p_account_segment15     => x_dists.account_segment15_tbl(i),
       p_account_segment16     => x_dists.account_segment16_tbl(i),
       p_account_segment17     => x_dists.account_segment17_tbl(i),
       p_account_segment18     => x_dists.account_segment18_tbl(i),
       p_account_segment19     => x_dists.account_segment19_tbl(i),
       p_account_segment20     => x_dists.account_segment20_tbl(i),
       p_account_segment21     => x_dists.account_segment21_tbl(i),
       p_account_segment22     => x_dists.account_segment22_tbl(i),
       p_account_segment23     => x_dists.account_segment23_tbl(i),
       p_account_segment24     => x_dists.account_segment24_tbl(i),
       p_account_segment25     => x_dists.account_segment25_tbl(i),
       p_account_segment26     => x_dists.account_segment26_tbl(i),
       p_account_segment27     => x_dists.account_segment27_tbl(i),
       p_account_segment28     => x_dists.account_segment28_tbl(i),
       p_account_segment29     => x_dists.account_segment29_tbl(i),
       p_account_segment30     => x_dists.account_segment30_tbl(i),
       x_account_id            => x_dists.dest_charge_account_id_tbl(i)
      );

      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'derived dest charge account id',
                    x_dists.dest_charge_account_id_tbl(i));
      END IF;
    END IF;

    d_position := 110;

    -- valiadte and derive project related info
    IF (x_dists.ln_order_type_lookup_code_tbl(i) = 'FIXED PRICE' AND
        x_dists.ln_purchase_basis_tbl(i) = 'SERVICES'AND
        PO_PDOI_PARAMS.g_product.project_11510_installed = FND_API.g_FALSE)
       OR
       (x_dists.ln_order_type_lookup_code_tbl(i) = 'TEMP LABOR' AND
        PO_PDOI_PARAMS.g_product.project_cwk_installed = FND_API.g_FALSE) THEN

      d_position := 120;

      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'all project info need to be empty');
      END IF;

      -- validate all project fields should be null
      validate_null_for_project_info
      (
        p_index      => i,
        x_dists      => x_dists
      );

      x_dists.project_accounting_context_tbl(i) := 'N';
      x_dists.gms_txn_required_flag_tbl(i) := 'N';
      x_dists.award_id_tbl(i) := NULL;
    ELSE

      d_position := 130;

      -- derive project fields if enabled
      IF (PO_PDOI_PARAMS.g_product.pa_installed = FND_API.g_TRUE AND
          NVL(x_dists.project_accounting_context_tbl(i),'N') = 'Y') THEN --bug19713416
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'project info needs to be derived');
        END IF;

        -- mark the line to do the derivation logic later
        l_derive_project_info_row_tbl(i) := i;
      END IF;

      -- set correct values on gms_txn_required_flag and award_id
      -- depending on current context
      IF (PO_PDOI_PARAMS.g_product.gms_enabled = FND_API.g_FALSE AND
          (x_dists.award_num_tbl(i) IS NOT NULL OR
           x_dists.award_id_tbl(i) IS NOT NULL))
         OR
         (NVL(x_dists.project_accounting_context_tbl(i),'N') <> 'Y') --bug19713416
         OR
         (x_dists.dest_type_code_tbl(i) <> 'EXPENSE') THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'set gms_txn_required_flag to N');
        END IF;

        x_dists.gms_txn_required_flag_tbl(i) := 'N';
        x_dists.award_id_tbl(i) := NULL;
      ELSE
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'set gms_txn_required_flag to Y');
        END IF;

        x_dists.gms_txn_required_flag_tbl(i) := 'Y';
      END IF;

      -- derive award_id from award_num
      IF (PO_PDOI_PARAMS.g_product.gms_enabled  = FND_API.g_TRUE AND
          x_dists.gms_txn_required_flag_tbl(i) = 'Y' AND
          x_dists.award_num_tbl(i) IS NOT NULL AND
          x_dists.award_id_tbl(i) IS NULL) THEN

        d_position := 140;

        -- call GMS API to derive the award_id
        x_dists.award_id_tbl(i) :=
          GMS_PO_API_GRP.get_award_id
          (
            p_api_version       => 1.0,
            p_commit            => FND_API.g_FALSE,
            p_init_msg_list     => FND_API.g_TRUE,
            p_validation_level  => FND_API.g_VALID_LEVEL_FULL,
            x_msg_count         => l_msg_count,
            x_msg_data          => l_msg_data,
            x_return_status     => l_return_status,
            p_award_number      => x_dists.award_num_tbl(i)
          );

        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'l_return_status', l_return_status);
          PO_LOG.stmt(d_module, d_position, 'award_id', x_dists.award_id_tbl(i));
        END IF;

        -- check return status to see whether derivation is successful
        IF (l_return_status <> FND_API.g_RET_STS_SUCCESS) THEN
          -- insert error
          PO_PDOI_ERR_UTL.add_fatal_error
          (
            p_interface_header_id  => x_dists.intf_header_id_tbl(i),
            p_interface_line_id    => x_dists.intf_line_id_tbl(i),
            p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
            p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
            p_error_message_name   => 'PO_PDOI_GMS_ERROR',
            p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
            p_column_name          => 'AWARD_NUMBER',
            p_column_value         => x_dists.award_num_tbl(i),
            p_error_message        => l_msg_data
          );

          x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
          x_dists.gms_txn_required_flag_tbl(i) := 'N';
        END IF;
      END IF;
    END IF; -- IF (x_dists.ln_order_type_lookup_code_tbl(i) = 'FIXED PRICE' AND
  END LOOP;

  d_position := 150;

  -- perform derive logic on project fields in batch mode
  -- the logic will be performed only for rows marked in l_derive_project_info_row_tbl
  derive_project_info
  (
    p_key             => l_key,
    p_index_tbl       => l_index_tbl,
    p_derive_row_tbl  => l_derive_project_info_row_tbl,
    x_dists           => x_dists
  );

  d_position := 160;

  -- handle all derivation errors
  FOR i IN 1..x_dists.rec_count
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', i);
    END IF;

    -- derivation error for deliver_to_location_id
    IF (x_dists.deliver_to_loc_tbl(i) IS NOT NULL AND
        x_dists.deliver_to_loc_id_tbl(i) IS NULL) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'deliver to loc id derivation failed');
        PO_LOG.stmt(d_module, d_position, 'deliver to loc', x_dists.deliver_to_loc_tbl(i));
      END IF;

      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_INVALID_DEL_LOCATION',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'DELIVER_TO_LOCATION',
        p_column_value         => x_dists.deliver_to_loc_tbl(i),
        p_token1_name          => 'DELIVER_TO_LOCATION',
        p_token1_value         => x_dists.deliver_to_loc_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    END IF;

    -- derivation error for deliver_to_person_id
    IF (x_dists.deliver_to_person_name_tbl(i) IS NOT NULL AND
        x_dists.deliver_to_person_id_tbl(i) IS NULL) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'deliver to person id derivation failed');
        PO_LOG.stmt(d_module, d_position, 'deliver to person name',
                    x_dists.deliver_to_person_name_tbl(i));
      END IF;

      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_INVALID_DEL_PERSON',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'DELIVER_TO_PERSON',
        p_column_value         => x_dists.deliver_to_person_name_tbl(i),
        p_token1_name          => 'DELIVER_TO_PERSON',
        p_token1_value         => x_dists.deliver_to_person_name_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    END IF;

    -- derivation error for destination_type_code
    IF (x_dists.dest_type_tbl(i) IS NOT NULL AND
        x_dists.dest_type_code_tbl(i) IS NULL) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'dest type code derivation failed');
        PO_LOG.stmt(d_module, d_position, 'dest type',
                    x_dists.dest_type_tbl(i));
      END IF;

      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_INVALID_DEST_TYPE',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'DESTINATION_TYPE',
        p_column_value         => x_dists.dest_type_tbl(i),
        p_token1_name          => 'DESTINATION_TYPE',
        p_token1_value         => x_dists.dest_type_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    END IF;

    -- derivation error for destination_organization_id
    IF (x_dists.dest_org_tbl(i) IS NOT NULL AND
        x_dists.dest_org_id_tbl(i) IS NULL) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'dest org id derivation failed');
        PO_LOG.stmt(d_module, d_position, 'dest org',
                    x_dists.dest_org_tbl(i));
      END IF;

      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_INVALID_DEST_ORG',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'DESTINATION_ORGANIZATION',
        p_column_value         => x_dists.dest_org_tbl(i),
        p_token1_name          => 'DESTINATION_ORGANIZATION',
        p_token1_value         => x_dists.dest_org_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    END IF;

    IF (PO_PDOI_PARAMS.g_product.wip_installed = FND_API.g_TRUE AND
        x_dists.dest_type_code_tbl(i) = 'SHOP FLOOR') THEN
      -- derivation error for wip_entity_id
      IF (x_dists.wip_entity_tbl(i) IS NOT NULL AND
          x_dists.wip_entity_id_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'wip entity id derivation failed');
          PO_LOG.stmt(d_module, d_position, 'wip entity',
                      x_dists.wip_entity_tbl(i));
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_WIP_ENTITY',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'WIP_ENTITY',
          p_column_value         => x_dists.wip_entity_tbl(i),
          p_token1_name          => 'WIP_ENTITY',
          p_token1_value         => x_dists.wip_entity_tbl(i)
        );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;

      -- derivation error for wip_line_id
      IF (x_dists.wip_line_code_tbl(i) IS NOT NULL AND
          x_dists.wip_line_id_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'wip line id derivation failed');
          PO_LOG.stmt(d_module, d_position, 'wip line code',
                      x_dists.wip_line_code_tbl(i));
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_WIP_LINE',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'WIP_LINE_CODE',
          p_column_value         => x_dists.wip_line_code_tbl(i),
          p_token1_name          => 'WIP_LINE_CODE',
          p_token1_value         => x_dists.wip_line_code_tbl(i)
        );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;
    END IF;

    -- derivation error for bom_resource_id
    IF (x_dists.bom_resource_code_tbl(i) IS NOT NULL AND
        x_dists.bom_resource_id_tbl(i) IS NULL) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'bom resource id derivation failed');
        PO_LOG.stmt(d_module, d_position, 'bom resource code',
                    x_dists.bom_resource_code_tbl(i));
      END IF;

      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_INVALID_BOM_RESOURCE',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'BOM_RESOURCE_CODE',
        p_column_value         => x_dists.bom_resource_code_tbl(i),
        p_token1_name          => 'BOM_RESOURCE_CODE',
        p_token1_value         => x_dists.bom_resource_code_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    END IF;

    -- derivation error for ship_to_ou_coa_id
    IF (x_dists.dest_charge_account_id_tbl(i) IS NULL AND
        x_dists.loc_txn_flow_header_id_tbl(i) IS NOT NULL AND
        x_dists.ship_to_ou_coa_id_tbl(i) = -1) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'ship_to ou coa id derivation failed');
      END IF;

      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_INVALID_DEST_ORG',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'DESTINATION_ORGANIZATION',
        p_column_value         => x_dists.dest_org_tbl(i),
        p_token1_name          => 'DESTINATION_ORGANIZATION',
        p_token1_value         => x_dists.dest_org_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    END IF;

    -- check derivation error for project fields
    IF (l_derive_project_info_row_tbl.EXISTS(i)) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'l_derive_project_info_row',
                    l_derive_project_info_row_tbl.EXISTS(i));
      END IF;

      -- derivation error for project_id
      IF (x_dists.project_tbl(i) IS NOT NULL AND
          x_dists.project_id_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'project id derivation failed');
          PO_LOG.stmt(d_module, d_position, 'project',
                      x_dists.project_tbl(i));
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_PROJECT',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'PROJECT',
          p_column_value         => x_dists.project_tbl(i),
          p_token1_name          => 'PROJECT',
          p_token1_value         => x_dists.project_tbl(i)
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;

      -- derivation error for task_id
      IF (x_dists.project_id_tbl(i) IS NOT NULL AND
          x_dists.task_tbl(i) IS NOT NULL AND
          x_dists.task_id_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'task id derivation failed');
          PO_LOG.stmt(d_module, d_position, 'task',
                      x_dists.task_tbl(i));
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_TASK',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'TASK',
          p_column_value         => x_dists.task_tbl(i),
          p_token1_name          => 'TASK',
          p_token1_value         => x_dists.task_tbl(i)
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;

      -- derivation error for expenditure_type
      IF (x_dists.project_id_tbl(i) IS NOT NULL AND
          x_dists.expenditure_tbl(i) IS NOT NULL AND
          x_dists.expenditure_type_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'expenditure type derivation failed');
          PO_LOG.stmt(d_module, d_position, 'expenditure',
                      x_dists.expenditure_tbl(i));
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_EXPEND_TYPE',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'EXPENDITURE',
          p_column_value         => x_dists.expenditure_tbl(i),
          p_token1_name          => 'EXPENDITURE',
          p_token1_value         => x_dists.expenditure_tbl(i)
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;

      -- derivation error for expenditure_organization_id
      IF (x_dists.project_id_tbl(i) IS NOT NULL AND
          x_dists.expenditure_org_tbl(i) IS NOT NULL AND
          x_dists.expenditure_org_id_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'expenditure org id derivation failed');
          PO_LOG.stmt(d_module, d_position, 'expenditure org',
                      x_dists.expenditure_org_tbl(i));
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_EXPEND_ORG',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'EXPENDITURE_ORGANIZATION',
          p_column_value         => x_dists.expenditure_org_tbl(i),
          p_token1_name          => 'EXPENDITURE_ORGANIZATION',
          p_token1_value         => x_dists.expenditure_org_tbl(i)
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;

      -- derivation error on expenditure_item_date
      IF (x_dists.project_id_tbl(i) IS NOT NULL AND
          x_dists.expenditure_org_id_tbl(i) IS NOT NULL AND
          x_dists.expenditure_item_date_tbl(i) IS NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'expenditure item date derivation failed');
        END IF;

        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_INVALID_EXPEND_DATE',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'EXPENDITURE',
          p_column_value         => x_dists.expenditure_tbl(i),
          p_token1_name          => 'EXPENDITURE',
          p_token1_value         => x_dists.expenditure_tbl(i)
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;
    END IF;
  END LOOP;

  PO_TIMING_UTL.stop_time(PO_PDOI_CONSTANTS.g_T_DIST_DERIVE);

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_dists;

-----------------------------------------------------------------------
--Start of Comments
--Name: default_dists
--Function:
--  perform default logic on distribution records within one batch;
--Parameters:
--IN:
--IN OUT:
--x_dists
--  variable to hold all the distribution attribute values in one batch;
--  default result are saved inside the variable
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE default_dists
(
  x_dists     IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'default_dists';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- key value used to identify row in temp table
  l_key                 po_session_gt.key%TYPE;

  -- table to hold index
  l_index_tbl           DBMS_SQL.NUMBER_TABLE;

  -- <<Bug#18200706>>
  local_index_tbl       PO_TBL_NUMBER;

  -- flag to indicate whether po encumbrance is enabled
  l_po_encumbrance_flag VARCHAR2(1);

  -- PDOI Enhancement Bug#17063664  
  -- <<Bug#18200706 Start>>
  -- variable to hold the value project_reference_enabled
  l_project_ref_enabled_tbl PO_TBL_VARCHAR1;
  -- variable to hold derived result
  l_result_tbl              PO_TBL_VARCHAR1;  
  -- <<Bug#18200706 End>>

  -- variable to hold results for GMS API call
  l_msg_count     NUMBER;
  l_msg_data      FND_NEW_MESSAGES.MESSAGE_TEXT%TYPE;
  l_return_status VARCHAR2(1);

  -- variables used to call API to get gl_encumbered_period_name
  l_period_year_tbl      PO_TBL_NUMBER;
  l_period_num_tbl       PO_TBL_NUMBER;
  l_quarter_num_tbl      PO_TBL_NUMBER;
  l_invalid_period_flag  VARCHAR2(1);

  -- variable used in workflow API call
  l_charge_success   BOOLEAN := TRUE;
  l_budget_success   BOOLEAN := TRUE;
  l_accrual_success  BOOLEAN := TRUE;
  l_variance_success BOOLEAN := TRUE;
  l_charge_account_flex    VARCHAR2(2000);
  l_budget_account_flex    VARCHAR2(2000);
  l_accrual_account_flex   VARCHAR2(2000);
  l_variance_account_flex  VARCHAR2(2000);
  l_charge_account_desc    VARCHAR2(2000);
  l_budget_account_desc    VARCHAR2(2000);
  l_accrual_account_desc   VARCHAR2(2000);
  l_variance_account_desc  VARCHAR2(2000);
  l_dest_charge_success        BOOLEAN := TRUE;
  l_dest_variance_success      BOOLEAN := TRUE;
  l_dest_charge_account_desc   VARCHAR2(2000);
  l_dest_variance_account_desc VARCHAR2(2000);
  l_dest_charge_account_flex   VARCHAR2(2000);
  l_dest_variance_account_flex VARCHAR2(2000);
  l_wf_itemkey                 VARCHAR2(80) := NULL;
  l_new_ccid_generated         BOOLEAN := FALSE;
  l_fb_error_msg               VARCHAR2(2000);
  l_bom_cost_element_id        NUMBER := NULL;
  l_result_billable_flag       VARCHAR2(5) := NULL;
  l_from_type_lookup_code      VARCHAR2(5) := NULL;
  l_from_header_id             NUMBER := NULL;
  l_from_line_id               NUMBER := NULL;
  l_wip_entity_type            VARCHAR2(25) := NULL;

  l_success                    BOOLEAN;
  l_entity_type                NUMBER;
  --Bug 12855747
  l_gl_enc_period_name  VARCHAR2(30);
  --<GTAS Project FP>
  p_other_params  po_name_value_pair_tab;

-- <<Bug#18338259 Start>>
-- FND Global values
  l_login_id            NUMBER;
  l_conc_request_id     NUMBER;
  l_prog_appl_id        NUMBER;
  l_conc_program_id     NUMBER;
-- <<Bug#18338259 End>>

BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  PO_TIMING_UTL.start_time(PO_PDOI_CONSTANTS.g_T_DIST_DEFAULT);

  -- pick a new key from temp table which will be used in all derive logic
  l_key := PO_CORE_S.get_session_gt_nextval;

  -- initialize index table which is used by all derivation logic
  PO_PDOI_UTL.generate_ordered_num_list
  (
    p_size     => x_dists.rec_count,
    x_num_list => l_index_tbl
  );

  -- read value from system parameter
  l_po_encumbrance_flag := PO_PDOI_PARAMS.g_sys.po_encumbrance_flag;

  -- get item_status for each distribution
  get_item_status
  (
    p_key                  => l_key,
    p_index_tbl            => l_index_tbl,
    p_item_id_tbl          => x_dists.ln_item_id_tbl,
    p_ship_to_org_id_tbl   => x_dists.loc_ship_to_org_id_tbl,
    x_item_status_tbl      => x_dists.item_status_tbl
  );

  -- Bug 18599449
  default_kanban_card_id
  (
    p_key                  => l_key,
    p_index_tbl            => l_index_tbl,
    p_req_line_id_tbl      => x_dists.ln_requisition_line_id_tbl,
    x_kanban_card_id_tbl   => x_dists.kanban_card_id_tbl
  );
  
  -- <<Bug#18200706 Start>>
  l_project_ref_enabled_tbl := PO_TBL_VARCHAR1();
  l_project_ref_enabled_tbl.EXTEND(l_index_tbl.COUNT);
  
  --SQL What: Fetch the attribute project_reference_enabled from mtl_parameters
  --SQL Why:  This attribute is needed when defaulting of 
  --          project_accounting_context
  FORALL i IN 1..l_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, char1)
    SELECT l_key,
           l_index_tbl(i),
           mp.PROJECT_REFERENCE_ENABLED
    FROM   mtl_parameters mp
    WHERE  mp.organization_id = x_dists.loc_ship_to_org_id_tbl(i);
  
  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = l_key
  RETURNING num1, char1 BULK COLLECT INTO local_index_tbl, l_result_tbl;
  
  -- set value back to x_item_status_tbl
  FOR i IN 1..local_index_tbl.COUNT
  LOOP   
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'local_index_tbl', local_index_tbl);
      PO_LOG.stmt(d_module, d_position, 'l_result_tbl', l_result_tbl(i));
    END IF; 
    
    l_project_ref_enabled_tbl(local_index_tbl(i)) := l_result_tbl(i);
  END LOOP;	
   -- <<Bug#18200706 End>>

  d_position := 10;

  -- default values for each distribution record
  x_dists.prevent_encumbrance_flag_tbl.EXTEND(x_dists.rec_count);
  FOR i IN 1..x_dists.rec_count
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', i);
    END IF;

    -- default distribution_num
    IF (x_dists.dist_num_tbl(i) IS NULL OR
        x_dists.dist_num_unique_tbl(i) = FND_API.g_FALSE) THEN
      x_dists.dist_num_tbl(i) :=
           PO_PDOI_MAINPROC_UTL_PVT.get_next_dist_num(x_dists.loc_line_loc_id_tbl(i));
    END IF;

    -- set distribution_id
    x_dists.po_dist_id_tbl(i) :=
      PO_PDOI_MAINPROC_UTL_PVT.get_next_dist_id;

    /* bug <8565566> Need to re-initialize the following boolean values for each distributions record comes for processing
      <start> */
    l_charge_success         := TRUE;
    l_budget_success         := TRUE;
    l_accrual_success        := TRUE;
    l_variance_success       := TRUE;
    l_dest_charge_success    := TRUE;
    l_dest_variance_success  := TRUE;
    l_new_ccid_generated     := FALSE;
    /*<end> bug 8565566 */

  --<<Bug# 19379838 Changing the default Logic of destination type code  START>>
   -- 1. One time item or complex PO , destination type is expense
   IF (x_dists.dest_type_code_tbl(i) IS NULL) THEN
     IF x_dists.ln_item_id_tbl(i) IS NULL OR x_dists.loc_payment_type_tbl(i) IS NOT NULL THEN 
       x_dists.dest_type_code_tbl(i) := 'EXPENSE';
       x_dists.dest_context_tbl(i) := 'EXPENSE';
     --2. Consigned shipment or out sourced assembly, destination type is inventory 
     ELSIF x_dists.loc_consigned_flag_tbl(i) = 'Y' OR x_dists.loc_outsourced_assembly_tbl(i) = 1 THEN 
       x_dists.dest_type_code_tbl(i) := 'INVENTORY';
       x_dists.dest_context_tbl(i) := 'INVENTORY';   
     -- 3. Outside processing item , destination type is shop floor
     ELSIF(x_dists.item_status_tbl(i) = 'O') THEN
         x_dists.dest_type_code_tbl(i) := 'SHOP FLOOR';
         x_dists.dest_context_tbl(i) := 'SHOP FLOOR';
     -- 4. Stockable item and accrue on receipt is Y ,destination type is inventory
     ELSIF (x_dists.item_status_tbl(i) = 'E')  AND x_dists.loc_accrue_on_receipt_flag_tbl(i) = 'Y' THEN
         x_dists.dest_type_code_tbl(i) := 'INVENTORY';
         x_dists.dest_context_tbl(i) := 'INVENTORY';
     -- 5. Stockable item and accrue on receipt is N , destination type is expense
     ELSIF (x_dists.item_status_tbl(i) = 'E')  AND x_dists.loc_accrue_on_receipt_flag_tbl(i) = 'N' THEN
        x_dists.dest_type_code_tbl(i) := 'EXPENSE';
        x_dists.dest_context_tbl(i) := 'EXPENSE';
     -- 6. item is not stockable , destination type is expense
     ELSE 
        x_dists.dest_type_code_tbl(i) := 'EXPENSE';
        x_dists.dest_context_tbl(i) := 'EXPENSE';
     END IF;
    END IF;
  --<<Bug# 19379838 END>>

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'dist num', x_dists.dist_num_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'dist id', x_dists.po_dist_id_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'item status', x_dists.item_status_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'dest type code', x_dists.dest_type_code_tbl(i));
    END IF;

    d_position := 20;

    -- set value for prevent_encumbrance_flag based on destination_type_code
    /* For Encumbrance Project - To enable Encumbrance for Destination type - Shop Floor and WIP entity type - EAM
     Retriving entity_type and Setting the prevent_encumbrance_flag to 'Y' if destination type = shop floor
     and wip_entity_type != 6 ( '6' is for EAM jobs) */

    -- Bug 18662279
    -- Correcting logic for defaulting of prevent_encumbrance_flag.
    BEGIN        /* added for Encumbrance Project */
     SELECT entity_type
     INTO l_entity_type
     FROM wip_entities
     WHERE wip_entity_id = x_dists.wip_entity_id_tbl(i) ;
    EXCEPTION
    WHEN OTHERS THEN
     l_entity_type := 1;   /*if exception, setting entity type to a value <> 6*/
    END;

    /* Condition added for Encumbrance Project  */
    IF ( (x_dists.dest_type_code_tbl(i) = 'SHOP FLOOR' AND l_entity_type <> 6)
        OR x_dists.loc_shipment_type_tbl(i) = 'PREPAYMENT') THEN
			       -- PDOI for Complex PO Project
      x_dists.prevent_encumbrance_flag_tbl(i) := 'Y';
    ELSE
      x_dists.prevent_encumbrance_flag_tbl(i) := 'N';
    END IF;


    -- set gl_encumbered_date and gl_encumbered_period_name based on
    -- po_encumbrance_flag
    -- If the flag is g_TRUE, default gl_encumbered_period
    -- later in bulk mode

    -- bug4907624
    -- Compare l_po_encumbrance_flag to 'Y' rather than FND_API.G_TRUE

    IF (l_po_encumbrance_flag = 'Y') THEN
      x_dists.gl_encumbered_date_tbl(i) :=
        NVL(x_dists.gl_encumbered_date_tbl(i), sysdate);
    ELSE
      x_dists.gl_encumbered_date_tbl(i) := NULL;
      x_dists.gl_encumbered_period_tbl(i) := NULL;
    END IF;
    
    --<PDOI Enhancement Bug#17063664 Start>
    -- set expenditure_org_id with the value from the profile 'pa_default_exp_org'
    x_dists.expenditure_org_id_tbl(i) := NVL(x_dists.expenditure_org_id_tbl(i), 
                  PO_PDOI_PARAMS.g_profile.pa_default_exp_org_id);
    
    -- Default project_accounting_context with 'Y':
    --    If destination type is expense and PA is installed
    --      or if destination type is not expense and PJM is installed and Project
    --      Reference Enabled is 1.

    -- Bug 18636560
    -- Default project_accounting_context to Y only when there is project.
    IF (x_dists.project_id_tbl(i) IS NOT NULL) THEN
	IF (x_dists.dest_type_code_tbl(i) = 'EXPENSE') THEN
		IF PO_PDOI_PARAMS.g_product.pa_installed = FND_API.g_TRUE THEN
			x_dists.project_accounting_context_tbl(i) := 'Y';
		END IF;
	ELSE
		IF PO_PDOI_PARAMS.g_product.pjm_installed = FND_API.g_TRUE
			AND l_project_ref_enabled_tbl(i) = 1 THEN
			x_dists.project_accounting_context_tbl(i) := 'Y';
		END IF;
	END IF;
    END IF;
    
    --<PDOI Enhancement Bug#17063664 End>

    -- set project fields to null if not applicable
    IF (NVL(x_dists.project_accounting_context_tbl(i),'N') <> 'Y') THEN --bug19713416
      x_dists.project_id_tbl(i) := NULL;
      x_dists.task_id_tbl(i) := NULL;
      x_dists.expenditure_type_tbl(i) := NULL;
      x_dists.expenditure_org_id_tbl(i) := NULL;
      x_dists.expenditure_item_date_tbl(i) := NULL;
      x_dists.award_id_tbl(i) := NULL;
    END IF;

    -- clear expenditure related fields for 'INVENTORY' type
    IF (x_dists.dest_type_code_tbl(i) = 'INVENTORY') THEN
      x_dists.expenditure_type_tbl(i):= NULL;
      x_dists.expenditure_org_id_tbl(i) := NULL;
      x_dists.expenditure_item_date_tbl(i) := NULL;
      x_dists.award_id_tbl(i) := NULL;
    END IF;

    -- If all of the PATEO fields are NULL's then there is no need to call the
    -- GMS validation API.
    IF (x_dists.project_id_tbl(i) IS NULL AND
        x_dists.task_id_tbl(i) IS NULL AND
        x_dists.expenditure_type_tbl(i) IS NULL AND
        x_dists.expenditure_org_id_tbl(i) IS NULL AND
        x_dists.expenditure_item_date_tbl(i) IS NULL AND
        x_dists.award_id_tbl(i) IS NULL) THEN
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'set gms_txn_required_flag to N');
      END IF;

      x_dists.gms_txn_required_flag_tbl(i) := 'N';

      -- Bug 18757772 begin
      ELSIF (x_dists.award_id_tbl(i) IS NOT NULL) THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'set gms_txn_required_flag to Y');
        END IF;
      
        x_dists.gms_txn_required_flag_tbl(i) := 'Y';
      -- Bug 18757772 end

    END IF;

    -- validate the Award transaction and then create the ADL
    IF (PO_PDOI_PARAMS.g_product.gms_enabled = FND_API.g_TRUE AND
        x_dists.gms_txn_required_flag_tbl(i) = 'Y') THEN

      d_position := 30;

      -- Bug 18757772 begin
      -- derive award_id from gms_award_distribution
      IF (x_dists.req_distribution_id_tbl(i) IS NOT NULL) THEN --bug19713416

        get_award_id
        (
          x_award_id  => x_dists.award_id_tbl(i)
        );

      END IF;
      -- Bug 18757772 end

      GMS_PO_API_GRP.validate_transaction
      (
        p_api_version           => 1.0,
        p_commit                => FND_API.g_FALSE,
        p_init_msg_list         => FND_API.g_TRUE,
        p_validation_level      => FND_API.g_VALID_LEVEL_FULL,
        x_msg_count             => l_msg_count,
        x_msg_data              => l_msg_data,
        x_return_status         => l_return_status,
        p_project_id            => x_dists.project_id_tbl(i),
        p_task_id               => x_dists.task_id_tbl(i),
        p_award_id              => x_dists.award_id_tbl(i),
        p_expenditure_type      => x_dists.expenditure_type_tbl(i),
        p_expenditure_item_date => x_dists.expenditure_item_date_tbl(i),
        p_calling_module        => 'PO_PDOI_DIST_PROCESS_PVT.default_dists'
      );

      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'return status', l_return_status);
      END IF;

      IF (l_return_status <> FND_API.g_RET_STS_SUCCESS) THEN
        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_GMS_ERROR',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'AWARD_NUMBER',
          p_column_value         => x_dists.award_num_tbl(i),
          p_error_message        => l_msg_data
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      ELSE

        d_position := 40;

        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'award id', x_dists.award_id_tbl(i));
        END IF;

        IF (x_dists.award_id_tbl(i) IS NOT NULL) THEN
          x_dists.award_set_id_tbl(i) := GMS_PO_API_GRP.get_new_award_set_id();

          GMS_PO_API_GRP.create_pdoi_adls
          (
            p_api_version       => 1.0,
            p_commit            => FND_API.g_FALSE,
            p_init_msg_list     => FND_API.g_TRUE,
            p_validation_level  => FND_API.g_VALID_LEVEL_FULL,
            x_msg_count         => l_msg_count,
            x_msg_data          => l_msg_data,
            x_return_status     => l_return_status,
            p_distribution_id   => x_dists.po_dist_id_tbl(i),
            p_distribution_num  => x_dists.dist_num_tbl(i),
            p_project_id        => x_dists.project_id_tbl(i),
            p_task_id           => x_dists.task_id_tbl(i),
            p_award_id          => x_dists.award_id_tbl(i),
            p_award_set_id      => x_dists.award_set_id_tbl(i) -- bug5201306
          );

          IF (PO_LOG.d_stmt) THEN
            PO_LOG.stmt(d_module, d_position, 'return status', l_return_status);
          END IF;

          -- insert error if failed
          IF (l_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
            PO_PDOI_ERR_UTL.add_fatal_error
            (
              p_interface_header_id  => x_dists.intf_header_id_tbl(i),
              p_interface_line_id    => x_dists.intf_line_id_tbl(i),
              p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
              p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
              p_error_message_name   => 'PO_PDOI_GMS_ERROR',
              p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
              p_column_name          => 'AWARD_NUMBER',
              p_column_value         => x_dists.award_num_tbl(i),
              p_error_message        => l_msg_data
            );

            x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
          END IF;
        END IF; -- IF (x_dists.award_id_tbl(i) IS NOT NULL)
      END IF;  -- IF (l_return_status <> FND_API.G_RET_STS_SUCCESS)
    END IF; -- IF (PO_PDOI_PARAMS.g_product.gms_enabled = FND_API.g_TRUE AND ..

    d_position := 50;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'dest type code',
                  x_dists.dest_type_code_tbl(i));
    END IF;

    -- bug 4284077:
    --   if the account_ids have been provided in the interface table,
    --   we will use them

    /*
    -- bug 4284077: comment out the code

    -- set to NULL before workflow since values of these attributes
    -- in the interface table are ignored
    x_dists.variance_account_id_tbl(i) := NULL;
    x_dists.accrual_account_id_tbl(i) := NULL;
    x_dists.budget_account_id_tbl(i) := NULL;
    x_dists.dest_variance_account_id_tbl(i) := NULL;
    IF (x_dists.dest_type_code_tbl(i) <> 'EXPENSE') THEN
      x_dists.charge_account_id_tbl(i) := NULL;
      x_dists.dest_charge_account_id_tbl(i) := NULL;
    END IF;
    */

       /* Bug 10421902 This is to fetch the billable flag from pa_tasks.
	  This flag would be later used in the account generator workflow */
	BEGIN
	  IF x_dists.project_id_tbl(i) IS NOT NULL
	     AND x_dists.task_id_tbl(i) IS NOT NULL  THEN
	    SELECT billable_flag
	    INTO   l_result_billable_flag
	 -- FROM   pa_tasks Bug	16863607
            FROM   pa_tasks_expend_v
	    WHERE  task_id = x_dists.task_id_tbl(i)
		   AND project_id = x_dists.project_id_tbl(i);
	  END IF;
	EXCEPTION
	  WHEN OTHERS THEN
	    l_result_billable_flag := NULL;
	END;

    --Start of code changes for the bug 12933412
    /*
    IF (x_dists.charge_account_id_tbl(i) IS NOT NULL) THEN
       default_account_ids
       (
         p_dest_type_code              => x_dists.dest_type_code_tbl(i),
         p_dest_org_id                 => x_dists.dest_org_id_tbl(i),
         p_dest_subinventory           => x_dists.dest_subinventory_tbl(i),
         p_item_id                     => x_dists.ln_item_id_tbl(i),
         p_po_encumbrance_flag         => l_po_encumbrance_flag,
         p_charge_account_id           => x_dists.charge_account_id_tbl(i),
         x_accrual_account_id          => x_dists.accrual_account_id_tbl(i),
         x_budget_account_id           => x_dists.budget_account_id_tbl(i),
         x_variance_account_id         => x_dists.variance_account_id_tbl(i),
         x_entity_type                 => l_entity_type,
         x_wip_entity_id               => x_dists.wip_entity_id_tbl(i)
       );
    ELSE
    */
      d_position := 60;
  
      --<<Bug#14088099>>
      -- call utility method to default standard who columns
      PO_PDOI_MAINPROC_UTL_PVT.default_who_columns
      (
        x_last_update_date_tbl       => x_dists.last_update_date_tbl,
        x_last_updated_by_tbl        => x_dists.last_updated_by_tbl,
        x_last_update_login_tbl      => x_dists.last_update_login_tbl,
        x_creation_date_tbl          => x_dists.creation_date_tbl,
        x_created_by_tbl             => x_dists.created_by_tbl,
        x_request_id_tbl             => x_dists.request_id_tbl,
        x_program_application_id_tbl => x_dists.program_application_id_tbl,
        x_program_id_tbl             => x_dists.program_id_tbl,
        x_program_update_date_tbl    => x_dists.program_update_date_tbl
      );
	  
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'req distribution id', 
                  x_dists.req_distribution_id_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'transaction flow header id', 
                  x_dists.loc_txn_flow_header_id_tbl(i));
    END IF;
    
-- <<Bug#18338259 Start>>
-- Assign FND Global values to the local variables
    l_login_id := FND_GLOBAL.login_id;
    l_conc_request_id := FND_GLOBAL.conc_request_id;
    l_prog_appl_id := FND_GLOBAL.prog_appl_id;
    l_conc_program_id := FND_GLOBAL.conc_program_id;		
-- <<Bug#18338259 End>>

    -- generate account
    -- PDOI Enhancment Bug#17063664 
    -- Account generator should be call only 
    -- if there is no backing requisition
    -- or if transaction flow exists for shared procurement
    IF x_dists.req_distribution_id_tbl(i) IS NULL OR 
       x_dists.loc_txn_flow_header_id_tbl(i) IS NOT NULL THEN

      --Bug#19498303:Adding the below code in begin end exception block

      BEGIN
 
      l_success := PO_WF_BUILD_ACCOUNT_INIT.Start_Workflow
      (
        x_purchasing_ou_id            => PO_PDOI_PARAMS.g_request.org_id,
        x_transaction_flow_header_id  => x_dists.loc_txn_flow_header_id_tbl(i),
        x_dest_charge_success         => l_dest_charge_success,
        x_dest_variance_success       => l_dest_variance_success,
        x_dest_charge_account_id      => x_dists.dest_charge_account_id_tbl(i),
        x_dest_variance_account_id    => x_dists.dest_variance_account_id_tbl(i),
        x_dest_charge_account_desc    => l_dest_charge_account_desc,
        x_dest_variance_account_desc  => l_dest_variance_account_desc,
        x_dest_charge_account_flex    => l_dest_charge_account_flex,
        x_dest_variance_account_flex  => l_dest_variance_account_flex,
        x_charge_success              => l_charge_success,
        x_budget_success              => l_budget_success,
        x_accrual_success             => l_accrual_success,
        x_variance_success            => l_variance_success,
        x_code_combination_id         => x_dists.charge_account_id_tbl(i),
        x_budget_account_id           => x_dists.budget_account_id_tbl(i),
        x_accrual_account_id          => x_dists.accrual_account_id_tbl(i),
        x_variance_account_id         => x_dists.variance_account_id_tbl(i),
        x_charge_account_flex         => l_charge_account_flex,
        x_budget_account_flex         => l_budget_account_flex,
        x_accrual_account_flex        => l_accrual_account_flex,
        x_variance_account_flex       => l_variance_account_flex,
        x_charge_account_desc         => l_charge_account_desc,
        x_budget_account_desc         => l_budget_account_desc,
        x_accrual_account_desc        => l_accrual_account_desc,
        x_variance_account_desc       => l_variance_account_desc,
        x_coa_id                      => PO_PDOI_PARAMS.g_sys.coa_id,
        x_bom_resource_id             => x_dists.bom_resource_id_tbl(i),
        x_bom_cost_element_id         => l_bom_cost_element_id,
        x_category_id                 => x_dists.ln_category_id_tbl(i),
        x_destination_type_code       => x_dists.dest_type_code_tbl(i),
        x_deliver_to_location_id      => x_dists.deliver_to_loc_id_tbl(i),
        x_destination_organization_id => x_dists.dest_org_id_tbl(i),
        x_destination_subinventory    => x_dists.dest_subinventory_tbl(i),
        x_expenditure_type            => x_dists.expenditure_type_tbl(i),
        x_expenditure_organization_id => x_dists.expenditure_org_id_tbl(i),
        x_expenditure_item_date       => x_dists.expenditure_item_date_tbl(i),
        x_item_id                     => x_dists.ln_item_id_tbl(i),
        x_line_type_id                => x_dists.ln_line_type_id_tbl(i),
        x_result_billable_flag        => l_result_billable_flag,
        x_agent_id                    => x_dists.hd_agent_id_tbl(i),
        x_project_id                  => x_dists.project_id_tbl(i),
        x_from_type_lookup_code       => l_from_type_lookup_code,
        x_from_header_id              => l_from_header_id,
        x_from_line_id                => l_from_line_id,
        x_task_id                     => x_dists.task_id_tbl(i),
        x_deliver_to_person_id        => x_dists.deliver_to_person_id_tbl(i),
        x_type_lookup_code            => x_dists.hd_type_lookup_code_tbl(i),
        x_vendor_id                   => x_dists.hd_vendor_id_tbl(i),
        x_wip_entity_id               => x_dists.wip_entity_id_tbl(i),
      --   Bug 19288447
      --x_wip_entity_type             => l_wip_entity_type,
	x_wip_entity_type             => l_entity_type,
        x_wip_line_id                 => x_dists.wip_line_id_tbl(i),
        x_wip_repetitive_schedule_id  => x_dists.wip_rep_schedule_id_tbl(i),
        x_wip_operation_seq_num       => x_dists.wip_operation_seq_num_tbl(i),
        x_wip_resource_seq_num        => x_dists.wip_resource_seq_num_tbl(i),
        x_po_encumberance_flag        => PO_PDOI_PARAMS.g_sys.po_encumbrance_flag,
        x_gl_encumbered_date          => x_dists.gl_encumbered_date_tbl(i),
        wf_itemkey                    => l_wf_itemkey,
        x_new_combination             => l_new_ccid_generated,
        header_att1                   => x_dists.hd_attribute1_tbl(i),
        header_att2                   => x_dists.hd_attribute2_tbl(i),
        header_att3                   => x_dists.hd_attribute3_tbl(i),
        header_att4                   => x_dists.hd_attribute4_tbl(i),
        header_att5                   => x_dists.hd_attribute5_tbl(i),
        header_att6                   => x_dists.hd_attribute6_tbl(i),
        header_att7                   => x_dists.hd_attribute7_tbl(i),
        header_att8                   => x_dists.hd_attribute8_tbl(i),
        header_att9                   => x_dists.hd_attribute9_tbl(i),
        header_att10                  => x_dists.hd_attribute10_tbl(i),
        header_att11                  => x_dists.hd_attribute11_tbl(i),
        header_att12                  => x_dists.hd_attribute12_tbl(i),
        header_att13                  => x_dists.hd_attribute13_tbl(i),
        header_att14                  => x_dists.hd_attribute14_tbl(i),
        header_att15                  => x_dists.hd_attribute15_tbl(i),
        line_att1                     => x_dists.ln_attribute1_tbl(i),
        line_att2                     => x_dists.ln_attribute2_tbl(i),
        line_att3                     => x_dists.ln_attribute3_tbl(i),
        line_att4                     => x_dists.ln_attribute4_tbl(i),
        line_att5                     => x_dists.ln_attribute5_tbl(i),
        line_att6                     => x_dists.ln_attribute6_tbl(i),
        line_att7                     => x_dists.ln_attribute7_tbl(i),
        line_att8                     => x_dists.ln_attribute8_tbl(i),
        line_att9                     => x_dists.ln_attribute9_tbl(i),
        line_att10                    => x_dists.ln_attribute10_tbl(i),
        line_att11                    => x_dists.ln_attribute11_tbl(i),
        line_att12                    => x_dists.ln_attribute12_tbl(i),
        line_att13                    => x_dists.ln_attribute13_tbl(i),
        line_att14                    => x_dists.ln_attribute14_tbl(i),
        line_att15                    => x_dists.ln_attribute15_tbl(i),
        shipment_att1                 => x_dists.loc_attribute1_tbl(i),
        shipment_att2                 => x_dists.loc_attribute2_tbl(i),
        shipment_att3                 => x_dists.loc_attribute3_tbl(i),
        shipment_att4                 => x_dists.loc_attribute4_tbl(i),
        shipment_att5                 => x_dists.loc_attribute5_tbl(i),
        shipment_att6                 => x_dists.loc_attribute6_tbl(i),
        shipment_att7                 => x_dists.loc_attribute7_tbl(i),
        shipment_att8                 => x_dists.loc_attribute8_tbl(i),
        shipment_att9                 => x_dists.loc_attribute9_tbl(i),
        shipment_att10                => x_dists.loc_attribute10_tbl(i),
        shipment_att11                => x_dists.loc_attribute11_tbl(i),
        shipment_att12                => x_dists.loc_attribute12_tbl(i),
        shipment_att13                => x_dists.loc_attribute13_tbl(i),
        shipment_att14                => x_dists.loc_attribute14_tbl(i),
        shipment_att15                => x_dists.loc_attribute15_tbl(i),
        distribution_att1             => x_dists.dist_attribute1_tbl(i),
        distribution_att2             => x_dists.dist_attribute2_tbl(i),
        distribution_att3             => x_dists.dist_attribute3_tbl(i),
        distribution_att4             => x_dists.dist_attribute4_tbl(i),
        distribution_att5             => x_dists.dist_attribute5_tbl(i),
        distribution_att6             => x_dists.dist_attribute6_tbl(i),
        distribution_att7             => x_dists.dist_attribute7_tbl(i),
        distribution_att8             => x_dists.dist_attribute8_tbl(i),
        distribution_att9             => x_dists.dist_attribute9_tbl(i),
        distribution_att10            => x_dists.dist_attribute10_tbl(i),
        distribution_att11            => x_dists.dist_attribute11_tbl(i),
        distribution_att12            => x_dists.dist_attribute12_tbl(i),
        distribution_att13            => x_dists.dist_attribute13_tbl(i),
        distribution_att14            => x_dists.dist_attribute14_tbl(i),
        distribution_att15            => x_dists.dist_attribute15_tbl(i),
        fb_error_msg                  => l_fb_error_msg,
        p_distribution_type           => NULL,
        p_payment_type                => NULL,
        --x_award_id                    => x_dists.award_id_tbl(i), /* 10089606 bug NULL */
        x_award_id                    => x_dists.award_set_id_tbl(i), /* bug#16982912 */
        x_vendor_site_id              => x_dists.hd_vendor_site_id_tbl(i), /* Bug #17319986 */
        p_func_unit_price             => x_dists.loc_price_override_tbl(i) * NVL(x_dists.hd_rate_tbl(i), 1)
      );

    --END IF;
    --End of code changes for the bug 12933412

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'l_success', l_success);
      PO_LOG.stmt(d_module, d_position, 'l_po_encumbrance_flag',
                  l_po_encumbrance_flag);
      PO_LOG.stmt(d_module, d_position, 'l_charge_success', l_charge_success);
      PO_LOG.stmt(d_module, d_position, 'charge_account_id',
                  x_dists.charge_account_id_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'l_budget_success', l_budget_success);
      PO_LOG.stmt(d_module, d_position, 'l_accrual_success', l_accrual_success);
      PO_LOG.stmt(d_module, d_position, 'l_variance_success', l_variance_success);
    END IF;

-- <<Bug#18338259 Start>>
-- Assign FND Global values to the local variables
    FND_GLOBAL.INITIALIZE('LOGIN_ID',l_login_id);
    FND_GLOBAL.INITIALIZE('CONC_REQUEST_ID',l_conc_request_id);
    FND_GLOBAL.INITIALIZE('PROG_APPL_ID',l_prog_appl_id);
    FND_GLOBAL.INITIALIZE('CONC_PROGRAM_ID',l_conc_program_id);		
-- <<Bug#18338259 End>>

    d_position := 70;

    -- after workflow, check result
    IF (l_po_encumbrance_flag = 'N' OR
        x_dists.dest_type_code_tbl(i) = 'SHOP FLOOR') then
        l_budget_success := TRUE;
    END IF;

    IF (l_charge_success <> TRUE OR
        NVL(x_dists.charge_account_id_tbl(i), 0) = 0) THEN 
        
      IF (PO_PDOI_PARAMS.g_request.calling_module = PO_PDOI_CONSTANTS.g_CALL_MOD_SOURCING) THEN --bug 20043259
        x_dists.charge_account_id_tbl(i) := NULL; --bug 20043259 

      ELSIF (x_dists.dest_type_code_tbl(i) = 'EXPENSE' AND
          l_charge_success = FALSE) THEN
        PO_PDOI_ERR_UTL.add_fatal_error
        (
          p_interface_header_id  => x_dists.intf_header_id_tbl(i),
          p_interface_line_id    => x_dists.intf_line_id_tbl(i),
          p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
          p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
          p_error_message_name   => 'PO_PDOI_CHARGE_FAILED',
          p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
          p_column_name          => 'CHARGE_ACCOUNT_ID',
          p_column_value         => x_dists.charge_account_id_tbl(i)
        );

        x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
      END IF;
    ELSIF (l_budget_success <> TRUE) THEN
      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_BUDGET_FAILED',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'BUDGET_ACCOUNT_ID',
        p_column_value         => x_dists.budget_account_id_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    ELSIF (l_accrual_success <> TRUE) THEN
      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_ACCRUAL_FAILED',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'ACCRUAL_ACCOUNT_ID',
        p_column_value         => x_dists.accrual_account_id_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    ELSIF (l_variance_success <> TRUE) THEN
      PO_PDOI_ERR_UTL.add_fatal_error
      (
        p_interface_header_id  => x_dists.intf_header_id_tbl(i),
        p_interface_line_id    => x_dists.intf_line_id_tbl(i),
        p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
        p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
        p_error_message_name   => 'PO_PDOI_VARIANCE_FAILED',
        p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
        p_column_name          => 'VARIANCE_ACCOUNT_ID',
        p_column_value         => x_dists.variance_account_id_tbl(i)
      );

      x_dists.error_flag_tbl(i) := FND_API.g_TRUE;
    ELSE
      NULL;
    END IF;

   --Bug#19498303 : Adding message in exception block 
    EXCEPTION
    WHEN OTHERS THEN 
       PO_PDOI_ERR_UTL.add_fatal_error
     (
       p_interface_header_id  => x_dists.intf_header_id_tbl(i),
       p_interface_line_id    => x_dists.intf_line_id_tbl(i),
       p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(i),
       p_interface_distribution_id  => x_dists.intf_dist_id_tbl(i),
       p_error_message_name   => 'PO_PDOI_ACCT_GEN_FAILED',
       p_table_name           => 'PO_DISTRIBUTIONS_INTERFACE',
       p_column_name          => 'CHARGE_ACCOUNT_ID',
       p_column_value         => x_dists.charge_account_id_tbl(i)
     );
     x_dists.error_flag_tbl(i) := FND_API.g_TRUE; 
    END;

   END IF; 
    d_position := 80;

    IF (l_po_encumbrance_flag = 'N' OR
          Nvl(x_dists.prevent_encumbrance_flag_tbl(i),'N') = 'Y') THEN -- PDOI for Complex PO Project
      x_dists.budget_account_id_tbl(i) := NULL;
    END IF;

    -- default tax related columns
    x_dists.tax_attribute_update_code_tbl(i) := 'CREATE';

 /* bug#20425637- tax_recovery_override_flag is available in po_distributions_interface
  * so we should skip derive the tax_recovery_override_flag to avoid sending
  * a wrong recovery rate to ZX .
  *
  *  IF (x_dists.recovery_rate_tbl(i) IS NOT NULL) THEN
  *    x_dists.tax_recovery_override_flag_tbl(i) := 'Y';
  *  ELSE
  *    x_dists.tax_recovery_override_flag_tbl(i) := NULL;
  *  END IF;
  */

  END LOOP;

  d_position := 90;

      -- call bulk API to default gl_encumbered_period_name
    IF (l_po_encumbrance_flag = 'Y') THEN
      -- GL Date Project#Start: If the profile PO: Validate GL Period has been
      -- set to Redefault, default the distribution's GL date.

      IF Nvl(FND_PROFILE.VALUE('PO_VALIDATE_GL_PERIOD'), 'Y') = 'R' THEN
        PO_PERIODS_SV.get_gl_date(x_sob_id  => PO_PDOI_PARAMS.g_sys.sob_id,
                                  x_gl_date => x_dists.gl_encumbered_date_tbl);
      END IF;
      -- GL Date Project#End

      PO_PERIODS_SV.get_period_info(p_roll_logic          => NULL,
                                    p_set_of_books_id     => PO_PDOI_PARAMS.g_sys.sob_id,
                                    p_date_tbl            => x_dists.gl_encumbered_date_tbl,
                                    x_period_name_tbl     => x_dists.gl_encumbered_period_tbl,
                                    x_period_year_tbl     => l_period_year_tbl,
                                    x_period_num_tbl      => l_period_num_tbl,
                                    x_quarter_num_tbl     => l_quarter_num_tbl,
                                    x_invalid_period_flag => l_invalid_period_flag);
    END IF;

  d_position := 100;

  --<GTAS PROJECT FP> Call FV code to default gdf attributes
  IF( fv_install.enabled) THEN
    FV_GTAS_UTILITY_PKG.po_default_distributions  ( p_distributions => x_dists,
                                                    p_other_params  => p_other_params,
                                                    x_return_status => l_return_status  );
  END IF;

  PO_TIMING_UTL.stop_time(PO_PDOI_CONSTANTS.g_T_DIST_DEFAULT);

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END default_dists;

-----------------------------------------------------------------------
--Start of Comments
--Name: validate_dists
--Function:
--  validate distribution attributes read within a batch
--Parameters:
--IN:
--IN OUT:
--x_dists
--  The record contains the values to be validated.
--  If there is error(s) on any attribute of the distribution row,
--  corresponding value in error_flag_tbl will be set with value
--  FND_API.g_TRUE.
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE validate_dists
(
  x_dists     IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'validate_dists';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  l_distributions         PO_DISTRIBUTIONS_VAL_TYPE := PO_DISTRIBUTIONS_VAL_TYPE();
  l_result_type           VARCHAR2(30);
  l_results               po_validation_results_type;
  l_parameter_name_tbl    PO_TBL_VARCHAR2000 := PO_TBL_VARCHAR2000();
  l_parameter_value_tbl   PO_TBL_VARCHAR2000 := PO_TBL_VARCHAR2000();

BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  PO_TIMING_UTL.start_time(PO_PDOI_CONSTANTS.g_T_DIST_VALIDATE);

  l_distributions.interface_id                  := x_dists.intf_dist_id_tbl;
  l_distributions.amount_ordered                := x_dists.amount_ordered_tbl;
  l_distributions.line_order_type_lookup_code   := x_dists.ln_order_type_lookup_code_tbl;
  l_distributions.line_purchase_basis           := x_dists.ln_purchase_basis_tbl;          -- bug 7644072
  l_distributions.quantity_ordered              := x_dists.quantity_ordered_tbl;
  l_distributions.destination_organization_id   := x_dists.dest_org_id_tbl;
  l_distributions.ship_to_organization_id       := x_dists.loc_ship_to_org_id_tbl;
  l_distributions.deliver_to_location_id        := x_dists.deliver_to_loc_id_tbl;
  l_distributions.deliver_to_person_id          := x_dists.deliver_to_person_id_tbl;
  l_distributions.destination_type_code         := x_dists.dest_type_code_tbl;
  l_distributions.distribution_type             := x_dists.loc_shipment_type_tbl; -- PDOI for Complex PO Project
  l_distributions.line_item_id                  := x_dists.ln_item_id_tbl;
  l_distributions.po_header_id                  := x_dists.hd_po_header_id_tbl;
  l_distributions.accrue_on_receipt_flag        := x_dists.loc_accrue_on_receipt_flag_tbl;
  l_distributions.destination_subinventory      := x_dists.dest_subinventory_tbl;
  l_distributions.wip_entity_id                 := x_dists.wip_entity_id_tbl;
  l_distributions.wip_repetitive_schedule_id    := x_dists.wip_rep_schedule_id_tbl;
  l_distributions.prevent_encumbrance_flag      := x_dists.prevent_encumbrance_flag_tbl;
  l_distributions.code_combination_id           := x_dists.charge_account_id_tbl;
  l_distributions.gl_encumbered_date            := x_dists.gl_encumbered_date_tbl;
  l_distributions.budget_account_id             := x_dists.budget_account_id_tbl;
  l_distributions.accrual_account_id            := x_dists.accrual_account_id_tbl;
  l_distributions.variance_account_id           := x_dists.variance_account_id_tbl;
  l_distributions.dest_variance_account_id      := x_dists.dest_variance_account_id_tbl;
  l_distributions.project_accounting_context    := x_dists.project_accounting_context_tbl;
  l_distributions.project_id                    := x_dists.project_id_tbl;
  l_distributions.task_id                       := x_dists.task_id_tbl;
  l_distributions.expenditure_type              := x_dists.expenditure_type_tbl;
  l_distributions.expenditure_organization_id   := x_dists.expenditure_org_id_tbl;
  l_distributions.header_need_by_date           := x_dists.loc_need_by_date_tbl;
  l_distributions.promised_date                 := x_dists.loc_promised_date_tbl;
  l_distributions.expenditure_item_date         := x_dists.expenditure_item_date_tbl;
  l_distributions.hdr_agent_id                  := x_dists.hd_agent_id_tbl;
  l_distributions.hdr_vendor_id                 := x_dists.hd_vendor_id_tbl;--<Gtas Project FP>
  l_distributions.hdr_vendor_site_id            := x_dists.hd_vendor_site_id_tbl; --Bug#21269302
  l_distributions.loc_outsourced_assembly       := x_dists.loc_outsourced_assembly_tbl;
  --<<Bug#19379838 >>
  l_distributions.consigned_flag                := x_dists.loc_consigned_flag_tbl;
  l_distributions.transaction_flow_header_id    := x_dists.loc_txn_flow_header_id_tbl;
  l_distributions.tax_recovery_override_flag    := x_dists.tax_recovery_override_flag_tbl;
  -- <<PDOI Enhancement Bug#17063664 Start>>
  l_distributions.oke_contract_header_id        := x_dists.ln_oke_contract_header_id_tbl;
  l_distributions.oke_contract_line_id          := x_dists.oke_contract_line_id_tbl;
  l_distributions.oke_contract_deliverable_id   := x_dists.oke_contract_del_id_tbl;
  -- <<PDOI Enhancement Bug#17063664 End>>

  -- ACRN proj
  l_distributions.ACRN                          := x_dists.ACRN_tbl;

  -- CLM Partial Funding Changes
  l_distributions.partial_funded_flag           := x_dists.partial_funded_flag_tbl;
  l_distributions.funded_value                  := x_dists.funded_value_tbl;
  l_distributions.style_id                      := x_dists.hd_style_id_tbl;
  l_distributions.clm_defence_funding           := x_dists.clm_defence_funding_tbl;
  /*CLM PDOI Integration*/
  l_distributions.intf_line_id                  := x_dists.intf_line_id_tbl;
  -- <GTAS PROJECT FP>
  l_distributions.global_attribute_category    := x_dists.global_attribute_category_tbl;
  l_distributions.global_attribute1      := x_dists.global_attribute1_tbl;
  l_distributions.global_attribute2      := x_dists.global_attribute2_tbl;
  l_distributions.global_attribute3      := x_dists.global_attribute3_tbl;
  l_distributions.global_attribute4      := x_dists.global_attribute4_tbl;
  l_distributions.global_attribute5      := x_dists.global_attribute5_tbl;
  l_distributions.global_attribute6      := x_dists.global_attribute6_tbl;
  l_distributions.global_attribute7      := x_dists.global_attribute7_tbl;
  l_distributions.global_attribute8      := x_dists.global_attribute8_tbl;
  l_distributions.global_attribute9      := x_dists.global_attribute9_tbl;
  l_distributions.global_attribute10     := x_dists.global_attribute10_tbl;
  l_distributions.global_attribute11     := x_dists.global_attribute11_tbl;
  l_distributions.global_attribute12     := x_dists.global_attribute12_tbl;
  l_distributions.global_attribute13     := x_dists.global_attribute13_tbl;
  l_distributions.global_attribute14     := x_dists.global_attribute14_tbl;
  l_distributions.global_attribute15     := x_dists.global_attribute15_tbl;
  l_distributions.global_attribute16     := x_dists.global_attribute16_tbl;
  l_distributions.global_attribute17     := x_dists.global_attribute17_tbl;
  l_distributions.global_attribute18     := x_dists.global_attribute18_tbl;
  l_distributions.global_attribute19     := x_dists.global_attribute19_tbl;
  l_distributions.global_attribute20     := x_dists.global_attribute20_tbl;

  d_position := 10;

  l_parameter_name_tbl.EXTEND(5);
  l_parameter_value_tbl.EXTEND(5);

  l_parameter_name_tbl(1) := 'CHART_OF_ACCOUNT_ID';
  l_parameter_value_tbl(1) := PO_PDOI_PARAMS.g_sys.coa_id;

  l_parameter_name_tbl(2) := 'PO_ENCUMBRANCE_FLAG';
  l_parameter_value_tbl(2) := PO_PDOI_PARAMS.g_sys.po_encumbrance_flag;

  l_parameter_name_tbl(3) := 'OPERATING_UNIT';
  l_parameter_value_tbl(3) := PO_PDOI_PARAMS.g_request.org_id;

  l_parameter_name_tbl(4) := 'EXPENSE_ACCRUAL_CODE';
  l_parameter_value_tbl(4) := PO_PDOI_PARAMS.g_sys.expense_accrual_code;

  l_parameter_name_tbl(5) := 'ALLOW_TAX_RATE_OVERRIDE';
  l_parameter_value_tbl(5) := PO_PDOI_PARAMS.g_profile.allow_tax_rate_override;

  PO_VALIDATIONS.validate_pdoi
  (
    p_distributions        => l_distributions,
    p_parameter_name_tbl   => l_parameter_name_tbl,
    p_parameter_value_tbl  => l_parameter_value_tbl,
    x_result_type          => l_result_type,
    x_results              => l_results
  );

  IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'vaidate dists returns :' || l_result_type);
  END IF;

  d_position := 20;

  IF l_result_type = po_validations.c_result_type_failure THEN
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'vaidate dists returns');
    END IF;

    PO_PDOI_ERR_UTL.process_val_type_errors
    (
      x_results    => l_results,
      p_table_name => 'PO_DISTRIBUTIONS_INTERFACE',
      p_distributions => x_dists
    );

    d_position := 30;

    populate_error_flag
    (
      x_results    => l_results,
      x_dists      => x_dists
    );
  END IF;

  IF l_result_type = po_validations.c_result_type_fatal THEN
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'vaidate dists return fatal');
    END IF;

    RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
  END IF;

  PO_TIMING_UTL.stop_time(PO_PDOI_CONSTANTS.g_T_DIST_VALIDATE);

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END validate_dists;

-------------------------------------------------------------------------
--------------------- PRIVATE PROCEDURES --------------------------------
-------------------------------------------------------------------------

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_ship_to_ou_id
--Function:
--  perform logic to derive ship_to_ou_id from ship_to_org_id
--  in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_ship_to_org_tbl
--   list of ship_to_org_tbl in the batch.
--IN OUT:
--x_ship_to_ou_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_ship_to_ou_id
(
  p_key                IN po_session_gt.key%TYPE,
  p_index_tbl          IN DBMS_SQL.NUMBER_TABLE,
  p_ship_to_org_id_tbl IN PO_TBL_NUMBER,
  x_ship_to_ou_id_tbl  IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_ship_to_ou_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_ship_to_org_id_tbl', p_ship_to_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_ship_to_ou_id_tbl', x_ship_to_ou_id_tbl);
  END IF;

  x_ship_to_ou_id_tbl := PO_TBL_NUMBER();
  x_ship_to_ou_id_tbl.EXTEND(p_index_tbl.COUNT);

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           TO_NUMBER(org_info.org_information3)
    FROM   hr_organization_information org_info,
           mtl_parameters param
    WHERE  param.organization_id = p_ship_to_org_id_tbl(i)
    AND    param.organization_id = org_info.organization_id
    AND    org_info.org_information_context = 'Accounting Information';

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_ship_to_ou_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new ship_to ou id',
                  l_result_tbl(i));
    END IF;

    x_ship_to_ou_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_ship_to_ou_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_deliver_to_loc_id
--Function:
--  perform logic to derive deliver_to_location_id from
--  deliver_to_location in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_deliver_to_loc_tbl
--  list of deliver_to_location values within the batch
--IN OUT:
--x_deliver_to_loc_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_deliver_to_loc_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_deliver_to_loc_tbl     IN PO_TBL_VARCHAR100,
  x_deliver_to_loc_id_tbl  IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_deliver_to_loc_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_deliver_to_loc_tbl',
                      p_deliver_to_loc_tbl);
    PO_LOG.proc_begin(d_module, 'x_deliver_to_loc_id_tbl',
                      x_deliver_to_loc_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           location_id
    FROM   hr_locations
    WHERE  p_deliver_to_loc_tbl(i) IS NOT NULL
    AND    x_deliver_to_loc_id_tbl(i) IS NULL
    AND    location_code = p_deliver_to_loc_tbl(i);

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_deliver_to_loc_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new deliver_to loc id',
                  l_result_tbl(i));
    END IF;

    x_deliver_to_loc_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_deliver_to_loc_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_deliver_to_person_id
--Function:
--  perform logic to derive deliver_to_person_id from
--  deliver_to_person_full_name in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_person_name_tbl
--  list of deliver_to_person_full_name values in the batch
--IN OUT:
--x_person_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_deliver_to_person_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_person_name_tbl        IN PO_TBL_VARCHAR2000,
  x_person_id_tbl          IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_deliver_to_person_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_person_name_tbl', p_person_name_tbl);
    PO_LOG.proc_begin(d_module, 'x_person_id_tbl', x_person_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           employee_id
    FROM   hr_employees_all_v
    WHERE  p_person_name_tbl(i) IS NOT NULL
    AND    x_person_id_tbl(i) IS NULL
    AND    full_name = p_person_name_tbl(i);

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_person_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new deliver_to person id',
                  l_result_tbl(i));
    END IF;

    x_person_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_deliver_to_person_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_dest_type_code
--Function:
--  perform logic to derive destination_type_code from
--  destination_type in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_dest_type_tbl
--  list of destination_type values in the batch
--IN OUT:
--x_dest_type_code_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_dest_type_code
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_dest_type_tbl          IN PO_TBL_VARCHAR30,
  x_dest_type_code_tbl     IN OUT NOCOPY PO_TBL_VARCHAR30
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_dest_type_code';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_VARCHAR25;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_dest_type_tbl', p_dest_type_tbl);
    PO_LOG.proc_begin(d_module, 'x_dest_type_code_tbl', x_dest_type_code_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, char1)
    SELECT p_key,
           p_index_tbl(i),
           lookup_code
    FROM   po_destination_types_all_v
    WHERE  p_dest_type_tbl(i) IS NOT NULL
    AND    x_dest_type_code_tbl(i) IS NULL
    AND    displayed_field = p_dest_type_tbl(i);

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, char1 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_dest_type_code_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new dest type code',
                  l_result_tbl(i));
    END IF;

    x_dest_type_code_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_dest_type_code;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_dest_org_id
--Function:
--  perform logic to derive destination_oragnization_id from
--  destination_organization in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_dest_org_tbl
--  list of destination_organization values in the batch
--p_ship_to_org_id_tbl
--  list of ship_to_organization_id values in the batch
--IN OUT:
--x_dest_org_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_dest_org_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_dest_org_tbl           IN PO_TBL_VARCHAR100,
  p_ship_to_org_id_tbl     IN PO_TBL_NUMBER,
  x_dest_org_id_tbl        IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_dest_org_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_dest_org_tbl', p_dest_org_tbl);
    PO_LOG.proc_begin(d_module, 'p_ship_to_org_id_tbl', p_ship_to_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_dest_org_id_tbl', x_dest_org_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           organization_id
    FROM   org_organization_definitions
    WHERE  p_dest_org_tbl(i) IS NOT NULL
    AND    x_dest_org_id_tbl(i) IS NULL
    AND    organization_code = p_dest_org_tbl(i)
    AND    TRUNC(sysdate) < NVL(disable_date, TRUNC(sysdate+1))
    AND    inventory_enabled_flag = 'Y';

  d_position := 10;

  -- set destination_organization_id as ship_to_organization
  -- if destination_organization is null
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           p_ship_to_org_id_tbl(i)
    FROM   dual
    WHERE  p_dest_org_tbl (i) IS NULL
    AND    x_dest_org_id_tbl(i) IS NULL;

  d_position := 20;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 30;

  -- set value back to x_dest_org_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new dest org id',
                  l_result_tbl(i));
    END IF;

    x_dest_org_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_dest_org_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_wip_entity_id
--Function:
--  perform logic to derive wip_entity_id from
--  wip_entity in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_wip_entity_tbl
--  list of wip_entity values within the batch
--p_dest_org_id_tbl
--  list of destination_organization_id values within the batch
--p_dest_type_code_tbl
--  list of destination_type_code values within the batch
--IN OUT:
--x_wip_entity_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_wip_entity_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_wip_entity_tbl         IN PO_TBL_VARCHAR2000,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  x_dest_type_code_tbl     IN OUT NOCOPY PO_TBL_VARCHAR30,
  x_wip_entity_id_tbl      IN OUT NOCOPY PO_TBL_NUMBER,
  p_item_id_tbl          IN PO_TBL_NUMBER,
  p_ship_to_org_id_tbl   IN PO_TBL_NUMBER,
  x_item_status_tbl      IN OUT NOCOPY PO_TBL_VARCHAR1,
  x_dest_context_tbl     IN OUT NOCOPY PO_TBL_VARCHAR30

) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_wip_entity_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_dest_org_id_tbl', p_dest_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_org_id_tbl', p_dest_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_dest_type_code_tbl', x_dest_type_code_tbl);
    PO_LOG.proc_begin(d_module, 'x_wip_entity_id_tbl', x_wip_entity_id_tbl);
  END IF;

  --to run the below code successfully, p_dest_type_code_tbl is an important parameter.
  --need to call default item info and the dest type population code here.

    get_item_status
  (
    p_key                  => p_key,
    p_index_tbl            => p_index_tbl,
    p_item_id_tbl          => p_item_id_tbl,
    p_ship_to_org_id_tbl   => p_ship_to_org_id_tbl,
    x_item_status_tbl      => x_item_status_tbl
  );

  FOR i IN 1..p_index_tbl.Count
  Loop
      -- default destination_type_code and destination_context from item status
    IF (x_dest_type_code_tbl(i) IS NULL) THEN
      IF (x_item_status_tbl(i) = 'O') THEN
         x_dest_type_code_tbl(i) := 'SHOP FLOOR'; 
         x_dest_context_tbl(i) := 'SHOP FLOOR';
      ELSIF (x_item_status_tbl(i) = 'E')  THEN
         x_dest_type_code_tbl(i) := 'INVENTORY';
         x_dest_context_tbl(i) := 'INVENTORY';
      ELSE
        x_dest_type_code_tbl(i) := 'EXPENSE';
        x_dest_context_tbl(i) := 'EXPENSE';
      END IF;
    END IF;
  END LOOP;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           we.wip_entity_id
    FROM   wip_entities we, mtl_parameters mp     --vegajula osp opm
    WHERE  p_wip_entity_tbl(i) IS NOT NULL
    AND    x_wip_entity_id_tbl(i) IS NULL
    AND    x_dest_type_code_tbl(i) = 'SHOP FLOOR'
    AND    we.wip_entity_name = p_wip_entity_tbl(i)
    AND    we.organization_id = p_dest_org_id_tbl(i)
    --osp opm
    AND    mp.organization_id = p_dest_org_id_tbl(i)
    AND    Nvl(mp.process_enabled_flag, 'N') = 'N';

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_wip_entity_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new wip entity id',
                  l_result_tbl(i));
    END IF;

    x_wip_entity_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;



  --osp opm
  --derive batch id from batch name for the records missed in above derivation
  --whose x_wip_entity_id_tbl(i) IS still NULL.
    d_position := 20;

    FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           gbh.batch_id
    FROM   GME_BATCH_HEADER gbh, mtl_parameters mp
    WHERE  p_wip_entity_tbl(i) IS NOT NULL
    AND    x_wip_entity_id_tbl(i) IS NULL
    AND    x_dest_type_code_tbl(i) = 'SHOP FLOOR'
    AND    gbh.BATCH_NO = p_wip_entity_tbl(i)
    AND    gbh.organization_id = p_dest_org_id_tbl(i)
    --osp opm
    AND    mp.organization_id = p_dest_org_id_tbl(i)
    AND    Nvl(mp.process_enabled_flag, 'N') = 'Y';

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 30;

  -- set value back to x_wip_entity_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new wip entity id',
                  l_result_tbl(i));
    END IF;

    x_wip_entity_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

    d_position := 40;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_wip_entity_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_wip_line_id
--Function:
--  perform logic to derive wip_line_id from
--  wip_line_code in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_wip_line_code_tbl
--  list of wip_line_code values within the batch
--p_dest_org_id_tbl
--  list of destination_organization_id values within the batch
--p_dest_type_code_tbl
--  list of destination_type_code values within the batch
--IN OUT:
--x_wip_line_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_wip_line_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_wip_line_code_tbl      IN PO_TBL_VARCHAR30,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  p_dest_type_code_tbl     IN PO_TBL_VARCHAR30,
  x_wip_line_id_tbl        IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_wip_line_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_wip_line_code_tbl', p_wip_line_code_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_org_id_tbl', p_dest_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_type_code_tbl', p_dest_type_code_tbl);
    PO_LOG.proc_begin(d_module, 'x_wip_line_id_tbl', x_wip_line_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  -- osp opm vegajula
  -- wip line is not needed for process manufacturing	orgs
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           line_id
    FROM   wip_lines wl, mtl_parameters	mp
    WHERE  p_wip_line_code_tbl(i) IS NOT NULL
    AND    x_wip_line_id_tbl(i) IS NULL
    AND    p_dest_type_code_tbl(i) = 'SHOP FLOOR'
    AND    wl.line_code = p_wip_line_code_tbl(i)
    AND    wl.organization_id = p_dest_org_id_tbl(i)
    AND    mp.organization_id = wl.organization_id
    AND    Nvl(mp.process_enabled_flag, 'N') = 'N';

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_wip_line_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new wip line id',
                  l_result_tbl(i));
    END IF;

    x_wip_line_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_wip_line_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_ship_to_ou_coa_id
--Function:
--  perform logic to derive ship_to_ou_coa_id in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_dest_org_id_tbl
--  list of destination_organization_id values within the batch
--p_txn_flow_header_id_tbl
--  list of transaction_flow_header_id values within the batch
--p_dest_charge_account_id_tbl
--  list of charge_account_id values within the batch
--IN OUT:
--x_ship_to_ou_coa_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_ship_to_ou_coa_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  p_txn_flow_header_id_tbl IN PO_TBL_NUMBER,
  p_dest_charge_account_id_tbl IN PO_TBL_NUMBER,
  x_ship_to_ou_coa_id_tbl  IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_ship_to_ou_coa_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_dest_org_id_tbl', p_dest_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_txn_flow_header_id_tbl',
                      p_txn_flow_header_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_charge_account_id_tbl',
                      p_dest_charge_account_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_ship_to_ou_coa_id_tbl',
                      x_ship_to_ou_coa_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           sob.chart_of_accounts_id
    FROM   gl_sets_of_books sob,
           hr_organization_information org_info,
           mtl_parameters param
    WHERE  p_txn_flow_header_id_tbl(i) IS NOT NULL
    AND    p_dest_charge_account_id_tbl(i) IS NULL
    AND    param.organization_id = p_dest_org_id_tbl(i)
    AND    param.organization_id = org_info.organization_id
    AND    org_info.org_information_context = 'Accounting Information'
    AND    TO_NUMBER(org_info.org_information1) = sob.set_of_books_id;

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_wip_line_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new ship_to ou coa id',
                  l_result_tbl(i));
    END IF;

    x_ship_to_ou_coa_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_ship_to_ou_coa_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_bom_resource_id
--Function:
--  perform logic to derive bom_resource_id from
--  bom_resource_code in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_bom_resource_code_tbl
--  list of bom_resource_code values within the batch
--p_dest_org_id_tbl
--  list of destination_organziation_id values within the batch
--IN OUT:
--x_bom_resource_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_bom_resource_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_bom_resource_code_tbl  IN PO_TBL_VARCHAR30,
  p_dest_org_id_tbl        IN PO_TBL_NUMBER,
  x_bom_resource_id_tbl    IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_bom_resource_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_bom_resource_code_tbl',
                      p_bom_resource_code_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_org_id_tbl', p_dest_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_bom_resource_id_tbl',
                      x_bom_resource_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           resource_id
    FROM   bom_resources
    WHERE  p_bom_resource_code_tbl(i) IS NOT NULL
    AND    x_bom_resource_id_tbl(i) IS NULL
    AND    resource_code = p_bom_resource_code_tbl(i)
    AND    organization_id = p_dest_org_id_tbl(i);

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_bom_resource_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new bom resource id',
                  l_result_tbl(i));
    END IF;

    x_bom_resource_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_bom_resource_id;


-----------------------------------------------------------------------
--Start of Comments
--Name: derive_account_id
--Function:
--  Derive code_combination_id based of account segments
--Parameters:
--IN:
--p_account_number
--  reserved
--p_chart_of_accounts_id
--  chart of account id
--p_account_segment1-30
--  account segment values
--IN OUT:
--OUT:
--x_account_id
--  account id if one can be derived.
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_account_id
( p_account_number IN VARCHAR2,
  p_chart_of_accounts_id IN NUMBER,
  p_account_segment1 IN VARCHAR2, p_account_segment2 IN VARCHAR2,
  p_account_segment3 IN VARCHAR2, p_account_segment4 IN VARCHAR2,
  p_account_segment5 IN VARCHAR2, p_account_segment6 IN VARCHAR2,
  p_account_segment7 IN VARCHAR2, p_account_segment8 IN VARCHAR2,
  p_account_segment9 IN VARCHAR2, p_account_segment10 IN VARCHAR2,
  p_account_segment11 IN VARCHAR2, p_account_segment12 IN VARCHAR2,
  p_account_segment13 IN VARCHAR2, p_account_segment14 IN VARCHAR2,
  p_account_segment15 IN VARCHAR2, p_account_segment16 IN VARCHAR2,
  p_account_segment17 IN VARCHAR2, p_account_segment18 IN VARCHAR2,
  p_account_segment19 IN VARCHAR2, p_account_segment20 IN VARCHAR2,
  p_account_segment21 IN VARCHAR2, p_account_segment22 IN VARCHAR2,
  p_account_segment23 IN VARCHAR2, p_account_segment24 IN VARCHAR2,
  p_account_segment25 IN VARCHAR2, p_account_segment26 IN VARCHAR2,
  p_account_segment27 IN VARCHAR2, p_account_segment28 IN VARCHAR2,
  p_account_segment29 IN VARCHAR2, p_account_segment30 IN VARCHAR2,
  x_account_id       OUT NOCOPY NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_account_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  l_sql VARCHAR2(4000);
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin (d_module);
  END IF;

  IF (p_account_segment1  IS NULL AND p_account_segment2  IS NULL AND
      p_account_segment3  IS NULL AND p_account_segment4  IS NULL AND
      p_account_segment5  IS NULL AND p_account_segment6  IS NULL AND
      p_account_segment7  IS NULL AND p_account_segment8  IS NULL AND
      p_account_segment9  IS NULL AND p_account_segment10 IS NULL AND
      p_account_segment11 IS NULL AND p_account_segment12 IS NULL AND
      p_account_segment13 IS NULL AND p_account_segment14 IS NULL AND
      p_account_segment15 IS NULL AND p_account_segment16 IS NULL AND
      p_account_segment17 IS NULL AND p_account_segment18 IS NULL AND
      p_account_segment19 IS NULL AND p_account_segment20 IS NULL AND
      p_account_segment21 IS NULL AND p_account_segment22 IS NULL AND
      p_account_segment23 IS NULL AND p_account_segment24 IS NULL AND
      p_account_segment25 IS NULL AND p_account_segment26 IS NULL AND
      p_account_segment27 IS NULL AND p_account_segment28 IS NULL AND
      p_account_segment29 IS NULL AND p_account_segment30 IS NULL) THEN

    -- No segment has been provided
    RETURN;
  END IF;

  d_position := 10;


  -- bug5010268
  -- Chagned p_chart_of_accounts_id to bind variable
  l_sql := 'SELECT GCC.code_combination_id FROM gl_code_combinations GCC ' ||
           'WHERE GCC.chart_of_accounts_id =  :p_chart_of_accounts_id ';

  add_account_segment_clause('segment1', p_account_segment1, l_sql);
  add_account_segment_clause('segment2', p_account_segment2, l_sql);
  add_account_segment_clause('segment3', p_account_segment3, l_sql);
  add_account_segment_clause('segment4', p_account_segment4, l_sql);
  add_account_segment_clause('segment5', p_account_segment5, l_sql);
  add_account_segment_clause('segment6', p_account_segment6, l_sql);
  add_account_segment_clause('segment7', p_account_segment7, l_sql);
  add_account_segment_clause('segment8', p_account_segment8, l_sql);
  add_account_segment_clause('segment9', p_account_segment9, l_sql);
  add_account_segment_clause('segment10', p_account_segment10, l_sql);
  add_account_segment_clause('segment11', p_account_segment11, l_sql);
  add_account_segment_clause('segment12', p_account_segment12, l_sql);
  add_account_segment_clause('segment13', p_account_segment13, l_sql);
  add_account_segment_clause('segment14', p_account_segment14, l_sql);
  add_account_segment_clause('segment15', p_account_segment15, l_sql);
  add_account_segment_clause('segment16', p_account_segment16, l_sql);
  add_account_segment_clause('segment17', p_account_segment17, l_sql);
  add_account_segment_clause('segment18', p_account_segment18, l_sql);
  add_account_segment_clause('segment19', p_account_segment19, l_sql);
  add_account_segment_clause('segment20', p_account_segment20, l_sql);
  add_account_segment_clause('segment21', p_account_segment21, l_sql);
  add_account_segment_clause('segment22', p_account_segment22, l_sql);
  add_account_segment_clause('segment23', p_account_segment23, l_sql);
  add_account_segment_clause('segment24', p_account_segment24, l_sql);
  add_account_segment_clause('segment25', p_account_segment25, l_sql);
  add_account_segment_clause('segment26', p_account_segment26, l_sql);
  add_account_segment_clause('segment27', p_account_segment27, l_sql);
  add_account_segment_clause('segment28', p_account_segment28, l_sql);
  add_account_segment_clause('segment29', p_account_segment29, l_sql);
  add_account_segment_clause('segment30', p_account_segment30, l_sql);

  d_position := 20;

  IF (PO_LOG.d_stmt) THEN
    --PO_LOG.stmt(d_module, ' stmt to generate acct id: ' || l_sql);
    --< Shared Proc 14223789 Start >
    PO_LOG.stmt(d_module, d_position, ' stmt to generate acct id: ', l_sql);
    --< Shared Proc 14223789 End >
  END IF;

  BEGIN

    -- bug5010268
    -- Bind p_chart_of_accounts_id as well
    EXECUTE IMMEDIATE l_sql INTO x_account_id
    USING p_chart_of_accounts_id,
          p_account_segment1,  p_account_segment2,
          p_account_segment3,  p_account_segment4,
          p_account_segment5,  p_account_segment6,
          p_account_segment7,  p_account_segment8,
          p_account_segment9,  p_account_segment10,
          p_account_segment11, p_account_segment12,
          p_account_segment13, p_account_segment14,
          p_account_segment15, p_account_segment16,
          p_account_segment17, p_account_segment18,
          p_account_segment19, p_account_segment20,
          p_account_segment21, p_account_segment22,
          p_account_segment23, p_account_segment24,
          p_account_segment25, p_account_segment26,
          p_account_segment27, p_account_segment28,
          p_account_segment29, p_account_segment30;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    IF (PO_LOG.d_stmt) THEN
      --PO_LOG.stmt(d_module, 'cannot find account id based on segments provided');
      --< Shared Proc 14223789 Start >
      PO_LOG.stmt(d_module, d_position, 'cannot find account id based on segments provided');
      --< Shared Proc 14223789 End >
    END IF;

    x_account_id := NULL;
  END;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_account_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: add_account_segment_clause
--Function:
--  append where clause containing the comparison of a particular segment
--  to the overall sql statement
--Parameters:
--IN:
--p_segment_name
--  segment name
--p_segment_value
--  segment value
--x_sql
--  sql to append where clause to.
--IN OUT:
--OUT:
--x_account_id
--  account id if one can be derived.
--End of Comments
------------------------------------------------------------------------
PROCEDURE add_account_segment_clause
( p_segment_name  IN VARCHAR2,
  p_segment_value IN VARCHAR2,
  x_sql IN OUT NOCOPY VARCHAR2
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'append_account_segment_clause';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

BEGIN

  IF (p_segment_value IS NOT NULL) THEN
    x_sql := x_sql || ' AND GCC.' || p_segment_name || ' = :' || p_segment_name;
  ELSE
    -- if value is null, originally we do not need bind variable. However,
    -- to make coding simple we are still appending a dummy NVL operation
    -- just to make sure that we always have the same number of bind variables.

    x_sql := x_sql || ' AND NVL(:' || p_segment_name || ', GCC.' ||
             p_segment_name || ') IS NULL';
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END add_account_segment_clause;


-----------------------------------------------------------------------
--Start of Comments
--Name: validate_null_for_project_info
--Function:
--  validate whether the project related fields are null when this
--  procedure is called. If any of the field is not null, an error
--  will be inserted into the error table
--Parameters:
--IN:
--p_index
--  index of distribution row within the batch
--IN OUT:
--x_dists
--  record of tables to hold all distribution attribute values
--  within the batch
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE validate_null_for_project_info
(
  p_index      IN NUMBER,
  x_dists      IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'validate_null_for_project_info';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  l_error_msg    VARCHAR2(30);
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  IF (x_dists.project_id_tbl(p_index) IS NOT NULL OR
      x_dists.project_tbl(p_index) IS NOT NULL OR
      x_dists.task_id_tbl(p_index) IS NOT NULL OR
      x_dists.task_tbl(p_index) IS NOT NULL OR
      x_dists.expenditure_tbl(p_index) IS NOT NULL OR
      x_dists.expenditure_type_tbl(p_index) IS NOT NULL OR
      NVL(x_dists.project_accounting_context_tbl(p_index), 'N') = 'Y' OR
      x_dists.expenditure_org_tbl(p_index) IS NOT NULL OR
      x_dists.expenditure_org_id_tbl(p_index) IS NOT NULL OR
      x_dists.expenditure_item_date_tbl(p_index) IS NOT NULL OR
      x_dists.end_item_unit_number_tbl(p_index) IS NOT NULL) THEN

    d_position := 10;

    -- add errors
    IF (x_dists.ln_purchase_basis_tbl(p_index) = 'SERVICES') THEN
      l_error_msg := 'PO_SVC_PA_11I10_NOT_ENABLED';
    ELSE
      l_error_msg := 'PO_SVC_PA_FPM_NOT_ENABLED';
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'error_msg', l_error_msg);
    END IF;

    PO_PDOI_ERR_UTL.add_fatal_error
    (
      p_interface_header_id        => x_dists.intf_header_id_tbl(p_index),
      p_interface_line_id          => x_dists.intf_line_id_tbl(p_index),
      p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(p_index),
      p_interface_distribution_id  => x_dists.intf_dist_id_tbl(p_index),
      p_error_message_name         => l_error_msg,
      p_table_name                 => 'PO_DISTRIBUTIONS_INTERFACE',
      p_column_name                => 'PROJECT_ID',
      p_column_value               => x_dists.project_id_tbl(p_index)
    );

    x_dists.error_flag_tbl(p_index) := FND_API.g_TRUE;
  END IF;

  d_position := 20;

  IF (x_dists.award_id_tbl(p_index) IS NOT NULL OR
      x_dists.award_num_tbl(p_index) IS NOT NULL) THEN
    -- add errors
    IF (x_dists.ln_purchase_basis_tbl(p_index) = 'SERVICES') THEN
      l_error_msg := 'PO_SVC_GMS_11I10_NOT_ENABLED';
    ELSE
      l_error_msg := 'PO_SVC_GMS_FPM_NOT_ENABLED';
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'error_msg', l_error_msg);
    END IF;

    PO_PDOI_ERR_UTL.add_fatal_error
    (
      p_interface_header_id        => x_dists.intf_header_id_tbl(p_index),
      p_interface_line_id          => x_dists.intf_line_id_tbl(p_index),
      p_interface_line_location_id => x_dists.intf_line_loc_id_tbl(p_index),
      p_interface_distribution_id  => x_dists.intf_dist_id_tbl(p_index),
      p_error_message_name         => l_error_msg,
      p_table_name                 => 'PO_DISTRIBUTIONS_INTERFACE',
      p_column_name                => 'AWARD_ID',
      p_column_value               => x_dists.award_id_tbl(p_index)
     );

    x_dists.error_flag_tbl(p_index) := FND_API.g_TRUE;
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END validate_null_for_project_info;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_project_info
--Function:
--  derive project related fields when this procedure is called
--  the derived fields include:
--    project_id,             task_id,
--    expenditure_type,       expenditure_organization_id
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_derive_row_tbl
--  table to mark for which row project fields should be
--  derived.
--IN OUT:
--x_dists
--  record of tables to hold all distribution attribute values
--  within the batch
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_project_info
(
  p_key             IN po_session_gt.key%TYPE,
  p_index_tbl       IN DBMS_SQL.NUMBER_TABLE,
  p_derive_row_tbl  IN DBMS_SQL.NUMBER_TABLE,
  x_dists           IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_project_info';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  l_index NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);

    PO_LOG.proc_begin(d_module, 'p_derive_row_tbl.COUNT', p_derive_row_tbl.COUNT);
    l_index := p_derive_row_tbl.FIRST;
    WHILE (l_index IS NOT NULL)
    LOOP
      PO_LOG.proc_begin(d_module, 'need to derive project info for line', l_index);
      l_index := p_derive_row_tbl.NEXT(l_index);
    END LOOP;
  END IF;

  -- derive project id
  derive_project_id
  (
    p_key                => p_key,
    p_index_tbl          => p_index_tbl,
    p_project_tbl        => x_dists.project_tbl,
    p_dest_type_code_tbl => x_dists.dest_type_code_tbl,
    p_ship_to_org_id_tbl => x_dists.loc_ship_to_org_id_tbl,
    p_ship_to_ou_id_tbl  => x_dists.ship_to_ou_id_tbl,
    p_derive_row_tbl     => p_derive_row_tbl,
    x_project_id_tbl     => x_dists.project_id_tbl
  );

  d_position := 10;

  -- derive task id
  derive_task_id
  (
    p_key                => p_key,
    p_index_tbl          => p_index_tbl,
    p_task_tbl           => x_dists.task_tbl,
    p_dest_type_code_tbl => x_dists.dest_type_code_tbl,
    p_project_id_tbl     => x_dists.project_id_tbl,
    p_ship_to_ou_id_tbl  => x_dists.ship_to_ou_id_tbl,
    p_derive_row_tbl     => p_derive_row_tbl,
    x_task_id_tbl        => x_dists.task_id_tbl
  );

  d_position := 20;

  -- derive expenditure type
  derive_expenditure_type
  (
    p_key                  => p_key,
    p_index_tbl            => p_index_tbl,
    p_expenditure_tbl      => x_dists.expenditure_tbl,
    p_project_id_tbl       => x_dists.project_id_tbl,
    p_derive_row_tbl       => p_derive_row_tbl,
    x_expenditure_type_tbl => x_dists.expenditure_type_tbl
  );

  d_position := 30;

  -- derive expenditure organiation id
  derive_expenditure_org_id
  (
    p_key                     => p_key,
    p_index_tbl               => p_index_tbl,
    p_expenditure_org_tbl     => x_dists.expenditure_org_tbl,
    p_project_id_tbl          => x_dists.project_id_tbl,
    p_derive_row_tbl          => p_derive_row_tbl,
    x_expenditure_org_id_tbl  => x_dists.expenditure_org_id_tbl
  );

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_project_info;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_project_id
--Function:
--  perform logic to derive project_id from project in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_project_tbl
--  list of project values within the batch
--p_dest_type_code_tbl
--  list of destination_type_code values within the batch
--p_ship_to_org_id_tbl
--  list of ship_to_organization_id values within the batch
--p_ship_to_ou_id_tbl
--  list of ship_to_ou_id values within the batch
--p_derive_row_tbl
--  table to mark rows for which project derivation logic
--  needs to be performed
--IN OUT:
--x_project_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_project_id
(
  p_key                IN po_session_gt.key%TYPE,
  p_index_tbl          IN DBMS_SQL.NUMBER_TABLE,
  p_project_tbl        IN PO_TBL_VARCHAR30,
  p_dest_type_code_tbl IN PO_TBL_VARCHAR30,
  p_ship_to_org_id_tbl IN PO_TBL_NUMBER,
  p_ship_to_ou_id_tbl  IN PO_TBL_NUMBER,
  p_derive_row_tbl     IN DBMS_SQL.NUMBER_TABLE,
  x_project_id_tbl     IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_project_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_project_tbl', p_project_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_type_code_tbl', p_dest_type_code_tbl);
    PO_LOG.proc_begin(d_module, 'p_ship_to_org_id_tbl', p_ship_to_org_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_ship_to_ou_id_tbl', p_ship_to_ou_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_project_id_tbl', x_project_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  -- query different views based on value of destination_type_code
  FORALL i IN INDICES OF p_derive_row_tbl
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           project_id
    FROM   pa_projects_expend_v
    WHERE  p_project_tbl(i) IS NOT NULL
    AND    x_project_id_tbl(i) IS NULL
    AND    p_dest_type_code_tbl(i) = 'EXPENSE'
    AND    project_name = p_project_tbl(i);

  d_position := 10;

  FORALL i IN INDICES OF p_derive_row_tbl
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           project_id
    FROM   pjm_projects_org_ou_v
    WHERE  p_project_tbl(i) IS NOT NULL
    AND    x_project_id_tbl(i) IS NULL
    AND    p_dest_type_code_tbl(i) <> 'EXPENSE'
    AND    project_name = p_project_tbl(i)
    AND    inventory_organization_id = p_ship_to_org_id_tbl(i)
    AND    NVL(org_id, p_ship_to_ou_id_tbl(i)) = p_ship_to_ou_id_tbl(i);

  d_position := 20;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 30;

  -- set value back to x_project_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new project id',
                  l_result_tbl(i));
    END IF;

    x_project_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_project_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_task_id
--Function:
--  perform logic to derive task_id from task in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_task_tbl
--  list of task values within the batch
--p_dest_type_code_tbl
--  list of destination_type_code values within the batch
--p_project_id_tbl
--  list of project_id values within the batch
--p_ship_to_ou_id_tbl
--  list of ship_to_ou_id values within the batch
--p_derive_row_tbl
--  table to mark rows for which project derivation logic
--  needs to be performed
--IN OUT:
--x_task_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_task_id
(
  p_key                IN po_session_gt.key%TYPE,
  p_index_tbl          IN DBMS_SQL.NUMBER_TABLE,
  p_task_tbl           IN PO_TBL_VARCHAR2000, --- Bug#16505809
  p_dest_type_code_tbl IN PO_TBL_VARCHAR30,
  p_project_id_tbl     IN PO_TBL_NUMBER,
  p_ship_to_ou_id_tbl  IN PO_TBL_NUMBER,
  p_derive_row_tbl     IN DBMS_SQL.NUMBER_TABLE,
  x_task_id_tbl        IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_task_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_task_tbl', p_task_tbl);
    PO_LOG.proc_begin(d_module, 'p_dest_type_code_tbl', p_dest_type_code_tbl);
    PO_LOG.proc_begin(d_module, 'p_project_id_tbl', p_project_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_ship_to_ou_id_tbl', p_ship_to_ou_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_task_id_tbl', x_task_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  -- query different views based on value of destination_type_code
  FORALL i IN INDICES OF p_derive_row_tbl
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           task_id
    FROM   pa_tasks_expend_v
    WHERE  p_task_tbl(i) IS NOT NULL
    AND    x_task_id_tbl(i) IS NULL
    AND    p_dest_type_code_tbl(i) = 'EXPENSE'
    AND    project_id = p_project_id_tbl(i)
    AND    task_number = p_task_tbl(i);

  d_position := 10;

  FORALL i IN INDICES OF p_derive_row_tbl
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           task_id
    FROM   pa_tasks_all_expend_v
    WHERE  p_task_tbl(i) IS NOT NULL
    AND    x_task_id_tbl(i) IS NULL
    AND    p_dest_type_code_tbl(i) <> 'EXPENSE'
    AND    project_id = p_project_id_tbl(i)
    AND    task_number = p_task_tbl(i)
    AND    NVL(expenditure_org_id, p_ship_to_ou_id_tbl(i)) = p_ship_to_ou_id_tbl(i);

  d_position := 20;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 30;

  -- set value back to x_task_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new task id',
                  l_result_tbl(i));
    END IF;

    x_task_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_task_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_expenditure_type
--Function:
--  perform logic to derive expenditure_type from expenditure in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_expenditure_tbl
--  list of expenditure values within the batch
--p_project_id_tbl
--  list of project_id values within the batch
--p_derive_row_tbl
--  table to mark rows for which project derivation logic
--  needs to be performed
--IN OUT:
--x_expenditure_type_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_expenditure_type
(
  p_key                  IN po_session_gt.key%TYPE,
  p_index_tbl            IN DBMS_SQL.NUMBER_TABLE,
  p_expenditure_tbl      IN PO_TBL_VARCHAR100,
  p_project_id_tbl       IN PO_TBL_NUMBER,
  p_derive_row_tbl       IN DBMS_SQL.NUMBER_TABLE,
  x_expenditure_type_tbl IN OUT NOCOPY PO_TBL_VARCHAR30
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_expenditure_type';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_VARCHAR30;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_expenditure_tbl', p_expenditure_tbl);
    PO_LOG.proc_begin(d_module, 'p_project_id_tbl', p_project_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_expenditure_type_tbl', x_expenditure_type_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN INDICES OF p_derive_row_tbl
    INSERT INTO po_session_gt(key, num1, char1)
    SELECT p_key,
           p_index_tbl(i),
           expenditure_type
    FROM   pa_expenditure_types_v
    WHERE  p_expenditure_tbl(i) IS NOT NULL
    AND    x_expenditure_type_tbl(i) IS NULL
    AND    p_project_id_tbl(i) IS NOT NULL
    AND    description = p_expenditure_tbl(i);

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, char1 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_expenditure_type_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new expenditure type',
                  l_result_tbl(i));
    END IF;

    x_expenditure_type_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_expenditure_type;

-----------------------------------------------------------------------
--Start of Comments
--Name: derive_expenditure_org_id
--Function:
--  perform logic to derive expenditure_organization_id from
--  expenditure_organization in batch mode
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_expenditure_org_tbl
--  list of expenditure_organization values within the batch
--p_project_id_tbl
--  list of project_id values within the batch
--p_derive_row_tbl
--  table to mark rows for which project derivation logic
--  needs to be performed
--IN OUT:
--x_expenditure_org_id_tbl
--  contains the derived result if original value is null;
--  original value will not be changed if it is not null
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE derive_expenditure_org_id
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_expenditure_org_tbl    IN PO_TBL_VARCHAR100,
  p_project_id_tbl         IN PO_TBL_NUMBER,
  p_derive_row_tbl         IN DBMS_SQL.NUMBER_TABLE,
  x_expenditure_org_id_tbl IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'derive_expenditure_org_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_NUMBER;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_expenditure_org_tbl', p_expenditure_org_tbl);
    PO_LOG.proc_begin(d_module, 'p_project_id_tbl', p_project_id_tbl);
    PO_LOG.proc_begin(d_module, 'x_expenditure_org_id_tbl',
                      x_expenditure_org_id_tbl);
  END IF;

  -- query database to get derived result in batch mode
  FORALL i IN INDICES OF p_derive_row_tbl
    INSERT INTO po_session_gt(key, num1, num2)
    SELECT p_key,
           p_index_tbl(i),
           organization_id
    FROM   pa_organizations_expend_v
    WHERE  p_expenditure_org_tbl(i) IS NOT NULL
    AND    x_expenditure_org_id_tbl(i) IS NULL
    AND    p_project_id_tbl(i) IS NOT NULL
    AND    name = p_expenditure_org_tbl(i)
    AND    active_flag = 'Y';

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_expenditure_org_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'new expenditure org id',
                  l_result_tbl(i));
    END IF;

    x_expenditure_org_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END derive_expenditure_org_id;

-----------------------------------------------------------------------
--Start of Comments
--Name: get_item_status
--Function:
--  extract item_status for each distribution row
--Parameters:
--IN:
--p_key
--  identifier in the temp table on the derived result
--p_index_tbl
--  indexes of the records
--p_item_id_tbl
--  list of item_id values within the batch
--p_ship_to_org_id_tbl
--  list of ship_to_organization_id values within the batcj
--IN OUT:
--x_item_status_tbl
--  returned status extracted from the query
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE get_item_status
(
  p_key                    IN po_session_gt.key%TYPE,
  p_index_tbl              IN DBMS_SQL.NUMBER_TABLE,
  p_item_id_tbl            IN PO_TBL_NUMBER,
  p_ship_to_org_id_tbl     IN PO_TBL_NUMBER,
  x_item_status_tbl        OUT NOCOPY PO_TBL_VARCHAR1
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'get_item_status';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- variable to hold derived result
  l_index_tbl        PO_TBL_NUMBER;
  l_result_tbl       PO_TBL_VARCHAR1;
BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_item_id_tbl', p_item_id_tbl);
    PO_LOG.proc_begin(d_module, 'p_ship_to_org_id_tbl', p_ship_to_org_id_tbl);
  END IF;

  -- initialize out parameter
  x_item_status_tbl := PO_TBL_VARCHAR1();
  x_item_status_tbl.EXTEND(p_index_tbl.COUNT);

  FORALL i IN 1..p_index_tbl.COUNT
    INSERT INTO po_session_gt(key, num1, char1)
    SELECT p_key,
           p_index_tbl(i),
           DECODE(outside_operation_flag,'Y','O',
             DECODE(stock_enabled_flag,'Y','E','D'))
    FROM   mtl_system_items
    WHERE  organization_id = p_ship_to_org_id_tbl(i)
    AND    inventory_item_id = p_item_id_tbl(i);

  d_position := 10;

  -- retrieve values from temp table and delete the records at the
  -- same time
  DELETE FROM po_session_gt
  WHERE  key = p_key
  RETURNING num1, char1 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;

  -- set value back to x_item_status_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'item status',
                  l_result_tbl(i));
    END IF;

    x_item_status_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END get_item_status;

-----------------------------------------------------------------------
--Start of Comments
--Name: default_account_ids
--Function:
--  Set default values for accrual_account_id, variance_account_id and
--  budget_account_id
--Parameters:
--IN:
--p_dest_type_code
--  destination type code for the distribution record
--p_dest_org_id
--  destination organization id for the distribution record
--p_dest_subinventory
--  destination subinventory for the distribution record
--p_item_id
--  line level inventory item id
--p_po_encumbrance_flag
--  flag which indicates whether encumbrance is enabled on PO
--p_charge_account_id
--  charge account id for the distribution record
--IN OUT:
--x_accrual_account_id
--  accrual account id which is to be defaulted if empty
--x_budget_account_id
--  budget account id which is to be defaulted if empty
--x_variance_account_id
--  variance account id which is to be defaulted if empty
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE default_account_ids
(
  p_dest_type_code      IN VARCHAR2,
  p_dest_org_id         IN NUMBER,
  p_dest_subinventory   IN VARCHAR2,
  p_item_id             IN NUMBER,
  p_po_encumbrance_flag IN VARCHAR2,
  p_charge_account_id   IN NUMBER,
  x_accrual_account_id  IN OUT NOCOPY NUMBER,
  x_budget_account_id   IN OUT NOCOPY NUMBER,
  x_variance_account_id IN OUT NOCOPY NUMBER,
  x_entity_type         IN NUMBER,           /*  Encumbrance Project  */
  x_wip_entity_id       IN NUMBER            /*  Encumbrance Project  */
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'default_account_ids';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;
  l_acct NUMBER;
  l_api_version NUMBER := 1;
  l_return_status VARCHAR2(100) := NULL;
  l_msg_count NUMBER;
  l_msg_data  VARCHAR2(500);

BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_dest_type_code', p_dest_type_code);
    PO_LOG.proc_begin(d_module, 'p_dest_org_id', p_dest_org_id);
    PO_LOG.proc_begin(d_module, 'p_dest_subinventory', p_dest_subinventory);
    PO_LOG.proc_begin(d_module, 'p_item_id', p_item_id);
    PO_LOG.proc_begin(d_module, 'p_po_encumbrance_flag', p_po_encumbrance_flag);
    PO_LOG.proc_begin(d_module, 'p_charge_account_id', p_charge_account_id);
    PO_LOG.proc_begin(d_module, 'x_accrual_account_id', x_accrual_account_id);
    PO_LOG.proc_begin(d_module, 'x_budget_account_id', x_budget_account_id);
    PO_LOG.proc_begin(d_module, 'x_variance_account_id', x_variance_account_id);
  END IF;

  IF (p_dest_type_code = 'EXPENSE') THEN

    d_position := 10;

    IF (x_accrual_account_id IS NULL) THEN

      d_position := 20;

      IF (g_sys_accrual_account_id IS NULL) THEN

        d_position := 30;

        SELECT accrued_code_combination_id
        INTO   g_sys_accrual_account_id
        FROM   po_system_parameters;
      END IF;

      x_accrual_account_id := g_sys_accrual_account_id;
    END IF;

    IF x_budget_account_id IS NULL THEN
      x_budget_account_id := p_charge_account_id;
    END IF;

    IF x_variance_account_id IS NULL THEN
      x_variance_account_id := p_charge_account_id;
    END IF;
  ELSIF (p_dest_type_code IN ('SHOP FLOOR','INVENTORY')) THEN

    d_position := 40;

    -- default accrual_account_id and variance_account_id
    IF (x_accrual_account_id IS NULL OR
        x_variance_account_id IS NULL) AND
       p_dest_org_id IS NOT NULL THEN

      d_position := 50;

      IF (NOT g_mtl_accrual_account_id_tbl.EXISTS(p_dest_org_id)) THEN

        d_position := 60;
        SELECT ap_accrual_account, invoice_price_var_account
          INTO g_mtl_accrual_account_id_tbl(p_dest_org_id),
               g_mtl_variance_account_id_tbl(p_dest_org_id)
    	    FROM mtl_parameters
    	   WHERE organization_id = p_dest_org_id;
      END IF;

      IF (x_accrual_account_id IS NULL) THEN
        x_accrual_account_id := g_mtl_accrual_account_id_tbl(p_dest_org_id);
      END IF;

      IF (x_variance_account_id IS NULL) THEN
        x_variance_account_id := g_mtl_variance_account_id_tbl(p_dest_org_id);
      END IF;
    END IF;

    -- default budget_account_id only when encumbrance is enabled
    IF (p_po_encumbrance_flag = 'Y' AND x_budget_account_id IS NULL) THEN
     /* IF (p_dest_type_code = 'SHOP FLOOR') THEN
        x_budget_account_id := P_charge_account_id; Code commented for Encumbrance Project  */

     /* - For Encumbrance Project - To enable Encumbrance for Destination type Shop Floor and WIP entity type EAM   */
     /* Start */

      IF (p_dest_type_code = 'SHOP FLOOR') and ( x_entity_type = 6) then

  -- Calling Costing API

     CST_EAMCOST_PUB.get_account
     (p_wip_entity_id      =>  x_wip_entity_id,
      p_item_id            =>  p_item_id,
      p_account_name       => 'ENCUMBRANCE',
      p_api_version        =>  l_api_version,
      x_acct               =>  l_acct,
      x_return_status      =>  l_return_status,
      x_msg_count          =>  l_msg_count,
      x_msg_data           =>  l_msg_data );



        IF (l_return_status = 'S' AND l_acct IS NOT NULL ) then
                 x_budget_account_id := l_acct;
        END IF;

     ELSIF (p_dest_type_code = 'SHOP FLOOR') and ( x_entity_type <> 6) THEN

      x_budget_account_id := P_charge_account_id;

  /* End */

      ELSE  -- p_destination_type_code = 'INVENTORY'

        d_position := 70;

        -- first try to get it from mtl_item_sub_inventories, then mtl_secondary_
        -- inventories, then mtl_system_items and finally mtl_parameters
        -- Bug6811980 (including the exception block)
        BEGIN
        SELECT NVL(misi.encumbrance_account, msci.encumbrance_account)
    	    INTO x_budget_account_id
          FROM mtl_item_sub_inventories misi,
               mtl_secondary_inventories msci
         WHERE misi.organization_id = p_dest_org_id
           AND misi.inventory_item_id = p_item_id
           AND misi.secondary_inventory = p_dest_subinventory
           AND msci.organization_id = p_dest_org_id
           AND msci.secondary_inventory_name = p_dest_subinventory
           AND p_dest_subinventory is not NULL;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            null;
        END;

        -- Bug6811980 (including the exception block)
        BEGIN
        IF (x_budget_account_id IS NULL) THEN
          d_position := 80;

          SELECT NVL(msi.encumbrance_account, mp.encumbrance_account)
            INTO x_budget_account_id
            FROM mtl_system_items msi,
                 mtl_parameters mp
           WHERE p_item_id = msi.inventory_item_id
             AND p_dest_org_id = msi.organization_id
             AND mp.organization_id = p_dest_org_id;
        END IF;
	EXCEPTION
          WHEN NO_DATA_FOUND THEN
            null;
        END;

        IF (x_budget_account_id IS NULL) THEN
          x_budget_account_id := p_charge_account_id;
        END IF;
      END IF;
    END IF;
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END default_account_ids;

-----------------------------------------------------------------------
--Start of Comments
--Name: populate_error_flag
--Function:
--  corresponding value in error_flag_tbl will be set with value FND_API.G_FALSE.
--Parameters:
--IN:
--x_results
--  The validation results that contains the errored line information.
--IN OUT:
--x_dists
--  The record contains the values to be validated.
--  If there is error(s) on any attribute of the price differential row,
--  corresponding value in error_flag_tbl will be set with value
--  FND_API.g_TRUE.
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE populate_error_flag
(
  x_results       IN     po_validation_results_type,
  x_dists         IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'populate_error_flag';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  l_index_tbl  DBMS_SQL.number_table;

BEGIN
  d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  FOR i IN 1 .. x_dists.intf_dist_id_tbl.COUNT LOOP
      l_index_tbl(x_dists.intf_dist_id_tbl(i)) := i;
  END LOOP;

  d_position := 10;

  FOR i IN 1 .. x_results.entity_id.COUNT LOOP
     IF x_results.result_type(i) = po_validations.c_result_type_failure THEN
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'error on index',
                      l_index_tbl(x_results.entity_id(i)));
        END IF;

        x_dists.error_flag_tbl(l_index_tbl(x_results.entity_id(i))) := FND_API.g_TRUE;
     END IF;
  END LOOP;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    (
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END populate_error_flag;

-- <<PDOI Enhancement Bug#17063664 Start>>
-----------------------------------------------------------------------
--Start of Comments
--Name: setup_dists_intf
--Function:
--  1. Inserts the data into po_distributions_interface from requisition for
--      all the lines which has req reference.
--  2. Inserts the data into po_distributions_interface from  
--      po_line_locations_interface if shipments are not having corresponding 
--      distributions.
--Parameters:
--IN: None
--IN OUT: None
--OUT: None
--End of Comments
------------------------------------------------------------------------
PROCEDURE setup_dists_intf
IS

  d_api_name CONSTANT VARCHAR2(30) := 'setup_dists_intf';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;
    
  l_draft_id_tbl                 PO_TBL_NUMBER;
  l_req_line_id_tbl              PO_TBL_NUMBER;
  l_intf_line_id_tbl             PO_TBL_NUMBER;
  l_intf_line_loc_id_tbl         PO_TBL_NUMBER;
 --<<Bug#22383780 Start>>--
  l_dist_count_tbl               PO_TBL_NUMBER;
  l_qty_tbl                      PO_TBL_NUMBER;
  l_amt_tbl                      PO_TBL_NUMBER;
--<<Bug#22383780 End>>--

BEGIN
  d_position := 0;
 
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;
  
  --SQL What: Get all the lines interface records requires line distribution 
  --          interface records population
  --SQL Why: Need to fetch req distribution date and populate into distribution 
  --         interface for all the lines for which requisition line id is populated
  SELECT intf_lines.interface_line_id
       , intf_lines.requisition_line_id
       , draft_lines.draft_id
  BULK COLLECT INTO 
    l_intf_line_id_tbl
  , l_req_line_id_tbl
  , l_draft_id_tbl
  FROM po_lines_interface intf_lines
     , po_lines_draft_all draft_lines
     ,po_headers_interface intf_headers  --Bug#22383780
  WHERE intf_lines.processing_id = PO_PDOI_PARAMS.g_processing_id
  AND   intf_lines.po_line_id    = draft_lines.po_line_id
  AND   intf_lines.interface_header_id = intf_headers.interface_header_id --Bug#22383780
  AND   intf_headers.processing_round_num = PO_PDOI_PARAMS.g_current_round_num --Bug#22383780
  AND   intf_headers.processing_id = PO_PDOI_PARAMS.g_processing_id --Bug#22383780
  AND   intf_lines.requisition_line_id IS NOT NULL;
    
  d_position := 10;
  
  IF (l_intf_line_id_tbl.COUNT = 0) THEN
    d_position := 20;
  END IF;
  
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_position, 'number of lines fetched: ' || 
                l_intf_line_id_tbl.COUNT);
    PO_LOG.stmt(d_module, d_position, 'l_intf_line_id_tbl',l_intf_line_id_tbl);
    PO_LOG.stmt(d_module, d_position, 'l_req_line_id_tbl',l_req_line_id_tbl);
    PO_LOG.stmt(d_module, d_position, 'l_draft_id_tbl',l_draft_id_tbl);
  END IF;  
  
  d_position := 30;
  
  --SQL What: Inserts data into distribution interface from the req
  --SQL Why: ditributions interface should be populated for all the lines if
  --         req reference exists
  FORALL i IN 1..l_intf_line_id_tbl.COUNT
  INSERT INTO po_distributions_interface
  (
    interface_header_id,
    interface_line_id,
    interface_line_location_id,
    interface_distribution_id,
    processing_id,
    distribution_num,
    charge_account_id,
    set_of_books_id,
    quantity_ordered,
    amount_ordered,
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
    dest_charge_account_id,
    dest_variance_account_id,
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
    tax_recovery_override_flag, 
    recovery_rate,
    recoverable_tax,
    nonrecoverable_tax,
    award_id,
    oke_contract_line_id,
    oke_contract_deliverable_id,
    group_line_id,
    funded_value,
    partial_funded_flag,
    quantity_funded,
    amount_funded
  )
  SELECT plli.interface_header_id,
    plli.interface_line_id,
    plli.interface_line_location_id,
    po_distributions_interface_s.nextval,
    plli.processing_id,
    prd.distribution_num,
    -- <<PDOI Enhancement Bug#17063664 Start>>
    (CASE   -- charge_account_id
      WHEN plld.transaction_flow_header_id is not null	/* BUG#21835965 */
        THEN NULL
      ELSE
        prd.code_combination_id
    END),
    -- <<PDOI Enhancement Bug#17063664 End>>
    prd.set_of_books_id,
    (CASE   -- quantity_ordered
      WHEN plld.payment_type = 'RATE'
        THEN ROUND((prd.req_line_amount / prl.amount) * plli.quantity, 15)
      ELSE 
        ROUND((prd.req_line_quantity / prl.quantity) * plli.quantity, 15)
    END),
    (CASE   -- amount_ordered
      WHEN PO_PDOI_PARAMS.g_request.calling_module = PO_PDOI_CONSTANTS.g_CALL_MOD_SOURCING
        THEN ROUND((prd.req_line_amount / prl.amount) * plli.amount, 15)
	 -- Bug#22866270 Amounts have to be prorated if Requisition has multiple distributions
      WHEN NVL(prl.suggest_multiple_suppliers,'N') = 'Y' 
        THEN  ROUND((prd.req_line_amount / prl.amount) * plli.amount, 15)
      ELSE prd.req_line_amount
    END),
    prd.distribution_id,
    prl.deliver_to_location_id,
    DECODE(prl.drop_ship_flag,'Y',NULL,prl.to_person_id),
    NVL(prd.encumbered_flag, 'N'),
    DECODE (PO_PDOI_PARAMS.g_profile.auto_create_date_option ,
                 'REQ GL DATE',
                 prd.gl_encumbered_date,
		 SYSDATE),
    prd.gl_encumbered_period_name,
    prl.destination_type_code,
    prl.destination_organization_id,
    prl.destination_subinventory,
    prd.budget_account_id,
    prd.accrual_account_id,
    prd.variance_account_id,
    -- <<PDOI Enhancement Bug#17063664 Start>>
    (CASE   -- dest_charge_account_id
      WHEN plld.transaction_flow_header_id is not null	/* BUG#21835965 */
        THEN prd.code_combination_id
      ELSE
        NULL
    END),
    -- <<PDOI Enhancement Bug#17063664 End>>
    NULL, -- dest_variance_account_id
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
    prd.project_related_flag, --prd.project_accounting_context, bug19305759
    prl.destination_context,
    prd.expenditure_organization_id,
    prd.expenditure_item_date,
    prd.tax_recovery_override_flag,
    DECODE(prd.tax_recovery_override_flag, 'Y', prd.recovery_rate, NULL),
    prd.recoverable_tax,
    prd.nonrecoverable_tax,
    prd.award_id, 
    DECODE(plld.consigned_flag,'Y',NULL, prd.oke_contract_line_id),
    DECODE(plld.consigned_flag,'Y',NULL, prd.oke_contract_deliverable_id),
    prd.info_line_id,
    prd.funded_value,
    prd.partial_funded_flag,
    prd.quantity_funded,
    prd.amount_funded
  FROM po_requisition_lines_all prl, 
    po_req_distributions_all prd,
    po_line_locations_interface plli,
    po_line_locations_draft_all plld
  WHERE plli.interface_line_id  = l_intf_line_id_tbl(i)
    AND prl.requisition_line_id = l_req_line_id_tbl(i) 
    AND prd.requisition_line_id = prl.requisition_line_id
    AND plli.line_location_id   = plld.line_location_id
    AND plld.draft_id           = l_draft_id_tbl(i)
    AND (plld.payment_type IS NULL 
      OR plld.payment_type      <> 'ADVANCE');

  IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'No of records identified: ', SQL%ROWCOUNT);
  END IF;

  d_position := 40;

  l_draft_id_tbl.delete; --Bug#22383780

  --SQL What: Get all the lines locations which does not have distributions  
  --          populated in the interface
  --SQL Why: All the shipments should have corresponding distributions
  -- Bug#22383780: Modified the sql to include current round num

  SELECT  intf_line_locs.interface_line_location_id,intf_headers.draft_id
  BULK COLLECT INTO
         l_intf_line_loc_id_tbl,l_draft_id_tbl
  FROM   po_line_locations_interface intf_line_locs,po_headers_interface intf_headers,
         po_lines_interface intf_lines
  WHERE  intf_line_locs.processing_id = PO_PDOI_PARAMS.g_processing_id
    AND  intf_lines.interface_header_id = intf_headers.interface_header_id
    AND  intf_line_locs.interface_header_id = intf_headers.interface_header_id
    AND  intf_headers.processing_round_num = PO_PDOI_PARAMS.g_current_round_num
    AND intf_headers.processing_id = PO_PDOI_PARAMS.g_processing_id
  -- 18650313, 18643737 Creation of default distribution, excluding option lines
  AND intf_lines.interface_line_id =  intf_line_locs.interface_line_id
  AND Nvl(intf_lines.clm_option_indicator,'*') <> 'O'
  AND NOT EXISTS
  (
      SELECT 'distribution exists for the line location'
      FROM po_distributions_interface dists_intf
      WHERE dists_intf.interface_line_location_id = intf_line_locs.interface_line_location_id
    );

  d_position := 50;
  
  IF (l_intf_line_loc_id_tbl.COUNT = 0) THEN
    d_position := 60;
    RETURN; --Bug#22383780
  END IF;
    
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_position
        , 'number of line locations which are not having distributions: '
        || l_intf_line_loc_id_tbl.COUNT);
  END IF;  
  
  d_position := 70;
  
  --SQL What: Inserts the default data into distributions interface from the 
  --          line locations interface for all the shipments which are not 
  --          having the corresponding distributions.
  FORALL i IN 1..l_intf_line_loc_id_tbl.COUNT  
  INSERT INTO po_distributions_interface
  (
    interface_distribution_id,
    interface_header_id,
    interface_line_id,
    interface_line_location_id,
    processing_id,
    process_code,
    distribution_num,
    req_distribution_id,
    po_header_id, --Bug#22383780
    po_line_id, --Bug#22383780
    line_location_id, --Bug#22383780
    deliver_to_location_id,
    deliver_to_person_id,
    destination_type_code,
    destination_organization_id,
    destination_subinventory,
    quantity_ordered,
    amount_ordered,
    rate_date,
    accrue_on_receipt_flag,
    prevent_encumbrance_flag,
    creation_date,
    created_by,
    last_update_date,
    last_updated_by,
    last_update_login,
    request_id,
    program_application_id,
    program_id,
    program_update_date
  )
  SELECT po_distributions_interface_s.nextval,
    PLL.interface_header_id,
    PLL.interface_line_id,
    PLL.interface_line_location_id,
    PLL.processing_id,
    PLL.process_code,
    1,          -- distribution_num
    NULL,		    -- req_distribution_id
    plld.po_header_id, --Bug#22383780
    plld.po_line_id, --Bug#22383780
    plld.line_location_id, --Bug#22383780
    PLLD.ship_to_location_id,
    NULL,
    -- PDOI Enhancement Bug#17063664: defaulting destination_type_code with NULL instead of 'EXPENSE'
    NULL,  -- destination_type_code
    PLLD.ship_to_organization_id,
    NULL,		-- destination_subinventory
    DECODE(PLLD.payment_type, 'ADVANCE', NULL, PLLD.quantity),
    PLLD.amount, -- amount_ordered
    SYSDATE,    -- rate_date
    NVL(PLLD.accrue_on_receipt_flag, 'N'),
    DECODE(PLLD.payment_type, 'ADVANCE', 'Y'
              , 'DELIVERY', 'N', NULL), -- prevent_encumbrance_flag
    PLLD.creation_date,
    PLLD.created_by,
    PLLD.last_update_date,
    PLLD.last_updated_by,
    PLLD.last_update_login,
    PLLD.request_id,
    PLLD.program_application_id,
    PLLD.program_id,
    PLLD.program_update_date
  FROM po_line_locations_interface PLL,
       po_line_locations_draft_all PLLD -- Bug 18534140 - Take data from drafts.
  WHERE PLL.interface_line_location_id = l_intf_line_loc_id_tbl(i)
  AND   PLL.line_location_id = PLLD.line_location_id--Bug#22383780
  and plld.draft_id = l_draft_id_tbl(i); --Bug#22383780

  d_position := 80;     

  IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'No of records identified: ', SQL%ROWCOUNT);
  END IF;


  --<<Bug#22383780 Start>>--

  l_intf_line_loc_id_tbl.delete; 
   
   
 
   SELECT  pdi.line_location_id,count (*) dist_count
   BULK COLLECT INTO l_intf_line_loc_id_tbl
                 ,l_dist_count_tbl
   FROM    po_distributions_interface pdi
          ,po_headers_interface phi
          ,po_lines_interface pli
   WHERE   pdi.interface_header_id = phi.interface_header_id
   AND     pdi.interface_line_id = pli.interface_line_id
   AND     phi.processing_round_num = po_pdoi_params.g_current_round_num
   AND     pli.line_loc_populated_flag = 'S'
   AND     phi.processing_id = po_pdoi_params.g_processing_id
   AND     pdi.req_distribution_id IS NULL
   AND     pdi.line_location_id IS NOT NULL
   GROUP BY pdi.line_location_id;

  FORALL i in 1..l_intf_line_loc_id_tbl.count  
  UPDATE po_distributions_interface
  SET quantity_ordered = quantity_ordered/l_dist_count_tbl(i),
      amount_ordered = amount_ordered/l_dist_count_tbl(i)
  WHERE line_location_id = l_intf_line_loc_id_tbl(i);

--<<Bug#22383780 Start>>--

   
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    ( 
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
  
END setup_dists_intf;


-----------------------------------------------------------------------
--Start of Comments
--Name: process_currency_conversions
--Function:
--  perform currency conversions
--Parameters:
--IN:
--IN OUT:
--x_line_locs
--  variable to hold all the line location attribute values in one batch;
--  default result are saved inside the variable
--OUT:
--End of Comments
------------------------------------------------------------------------
PROCEDURE process_currency_conversions
(
  x_dists     IN OUT NOCOPY PO_PDOI_TYPES.distributions_rec_type  
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'process_currency_conversions';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;
 
  l_inverse_rate_display_flag  VARCHAR2(1) := 'N';
  l_display_rate               NUMBER;
  l_rate                       NUMBER;
  l_precision                  NUMBER;
  l_ext_precision              NUMBER;
  l_min_acct_unit              NUMBER;
  
  l_order_type_lookup_code_tbl PO_TBL_VARCHAR30;
  l_po_currency_code_tbl       PO_TBL_VARCHAR30;
  l_req_currency_code_tbl      PO_TBL_VARCHAR30;
  l_req_ou_currency_code_tbl   PO_TBL_VARCHAR30;
  l_req_amount_tbl             PO_TBL_NUMBER;
  l_req_currency_amount_tbl    PO_TBL_NUMBER;
  l_req_sob_id_tbl             PO_TBL_NUMBER;
  l_po_sob_id_tbl              PO_TBL_NUMBER;
  l_req_rate_tbl               PO_TBL_NUMBER;
  l_po_rate_tbl                PO_TBL_NUMBER;
  l_rate_type_tbl              PO_TBL_VARCHAR30;
  l_rate_date_tbl              PO_TBL_DATE;
  
  -- temp index value
  local_index_tbl              PO_TBL_NUMBER;
  l_index_tbl                  PO_TBL_NUMBER;
  l_index                      NUMBER;
  
BEGIN
  d_position := 0;
 
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;
  
  PO_TIMING_UTL.start_time(PO_PDOI_CONSTANTS.g_T_DIST_DERIVE);

  local_index_tbl      := PO_TBL_NUMBER();
  local_index_tbl.EXTEND(x_dists.rec_count);
  
  -- initialize index table which is used by all derivation logic
  FOR i IN 1..x_dists.rec_count LOOP
    local_index_tbl(i) := i;
  END LOOP;
  
  d_position := 10;
  
  -- retrieve the values based on requisition line id
  SELECT index_tbl.val ,
    ln_order_type_lookup_code_tbl.val ,
    hd_cur_code_tbl.val ,
    prl.currency_code ,
    gsb.currency_code ,
    prd.req_line_amount ,	-- BUG#21623559
    NVL(prd.req_line_currency_amount, prd.req_line_amount) ,	-- BUG#21623559
    req_fsp.set_of_books_id ,
    po_fsp.set_of_books_id ,
    NVL(prl.rate,1) ,
    hd_rate_tbl.val ,
    hd_rate_type_tbl.val ,
    hd_rate_date_tbl.val
  BULK COLLECT INTO l_index_tbl ,
    l_order_type_lookup_code_tbl ,
    l_po_currency_code_tbl ,
    l_req_currency_code_tbl ,
    l_req_ou_currency_code_tbl ,
    l_req_amount_tbl ,
    l_req_currency_amount_tbl ,
    l_req_sob_id_tbl ,
    l_po_sob_id_tbl ,
    l_req_rate_tbl ,
    l_po_rate_tbl ,
    l_rate_type_tbl ,
    l_rate_date_tbl
  FROM po_requisition_lines_all prl,
    po_req_distributions_all prd,	-- BUG#21623559
    financials_system_params_all po_fsp,
    financials_system_params_all req_fsp,
    gl_sets_of_books gsb,
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.req_distribution_id_tbl)
    ) req_dist_id_tbl ,		-- BUG#21623559
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.ln_requisition_line_id_tbl)
    ) req_line_id_tbl ,
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.hd_currency_code_tbl)
    ) hd_cur_code_tbl ,
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.hd_rate_tbl)
    ) hd_rate_tbl ,
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.hd_rate_type_tbl)
    ) hd_rate_type_tbl ,
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.hd_rate_date_tbl)
    ) hd_rate_date_tbl ,
    (SELECT column_value val, rownum rn FROM TABLE(x_dists.ln_order_type_lookup_code_tbl)
    ) ln_order_type_lookup_code_tbl ,
    (SELECT column_value val, rownum rn FROM TABLE(local_index_tbl)
    ) index_tbl
  WHERE req_line_id_tbl.val  IS NOT NULL
  AND req_dist_id_tbl.val  IS NOT NULL				-- BUG#21623559
  AND prl.requisition_line_id 	= prd.requisition_line_id	-- BUG#21623559
  AND prd.distribution_id	= req_dist_id_tbl.val		-- BUG#21623559
  AND prl.requisition_line_id   = req_line_id_tbl.val
  AND index_tbl.rn              = req_dist_id_tbl.rn		-- BUG#21623559
  AND index_tbl.rn              = req_line_id_tbl.rn
  AND index_tbl.rn              = hd_cur_code_tbl.rn
  AND index_tbl.rn              = hd_rate_tbl.rn
  AND index_tbl.rn              = hd_rate_type_tbl.rn
  AND index_tbl.rn              = hd_rate_date_tbl.rn
  AND index_tbl.rn              = ln_order_type_lookup_code_tbl.rn
  AND po_fsp.org_id 			      = PO_PDOI_PARAMS.g_request.org_id
  AND NVL(prl.org_id, -99)      = NVL(req_fsp.org_id, -99)
  AND req_fsp.set_of_books_id   = gsb.set_of_books_id;

  d_position := 20;

  -- set the result in OUT parameters
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    l_index := l_index_tbl(i);
  
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', i); 
      PO_LOG.stmt(d_module, d_position, 'order_type_lookup_code', l_order_type_lookup_code_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'po_currency_code', l_po_currency_code_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'req_currency_code', l_req_currency_code_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'req_ou_currency_code', l_req_ou_currency_code_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'req_amount', l_req_amount_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'req_currency_amount', l_req_currency_amount_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'req_sob_id', l_req_sob_id_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'po_sob_id', l_po_sob_id_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'req_rate', l_req_rate_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'po_rate', l_po_rate_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'rate_type', l_rate_type_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'rate_date', l_rate_date_tbl(i));
    END IF; 
    
    l_rate                      := NULL;
    l_inverse_rate_display_flag := NULL;
    l_display_rate              := NULL;
    l_precision                 := NULL;
    l_ext_precision             := NULL;
    l_min_acct_unit             := NULL;

    -- Take precision
    fnd_currency.get_info (l_po_currency_code_tbl(i),
                           l_precision,
                           l_ext_precision,
                           l_min_acct_unit); 
    
    d_position := 30;
    
    -- Conversion not required if req_ou_currency = Po currency    
    IF l_req_ou_currency_code_tbl(i) <> l_po_currency_code_tbl(i) THEN     
    
      -- If req set of books = po set of books then take rate from po_header
      -- Else If req currency and po_currency are same then no need to fetch rate
      -- Else take rate between req ou currency and PO currency
      IF l_req_sob_id_tbl(i) = l_po_sob_id_tbl(i) OR l_req_currency_code_tbl(i) = l_po_currency_code_tbl(i) THEN 
        l_rate := l_po_rate_tbl(i);
        d_position := 40;   
        
      ELSE 
        po_currency_sv.get_rate( x_set_of_books_id              => l_req_sob_id_tbl(i),
                                 x_currency_code                => l_po_currency_code_tbl(i),
                                 x_rate_type                    => l_rate_type_tbl(i),
                                 x_rate_date                    => l_rate_date_tbl(i),
                                 x_inverse_rate_display_flag    => l_inverse_rate_display_flag,
                                 x_rate                         => l_rate,
                                 x_display_rate                 => l_display_rate);  
       d_position := 50;
       
      END IF; --  l_req_sob_id_tbl(i) = l_po_sob_id_tbl(i) OR l_req_currency_tbl(i) = l_po_currency_tbl(i)
                     
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_position, 'l_rate', l_rate);
        PO_LOG.stmt(d_module, d_position, 'l_ext_precision', l_ext_precision);                          
      END IF;
        
      d_position := 60;    
        
      IF l_order_type_lookup_code_tbl(i) = 'AMOUNT' THEN
        IF l_req_currency_code_tbl(i) = l_po_currency_code_tbl(i) THEN
          x_dists.quantity_ordered_tbl(l_index) := round(x_dists.quantity_ordered_tbl(l_index)/l_req_rate_tbl(i), nvl(l_ext_precision, 15) );
        ELSE
          x_dists.quantity_ordered_tbl(l_index) := round(x_dists.quantity_ordered_tbl(l_index)/l_rate, nvl(l_ext_precision, 15) );
        END IF;
        
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'Converted Quantity ', x_dists.quantity_ordered_tbl(l_index));                                                      
        END IF;
        
      END IF;
      
      d_position := 70;    
      
      IF l_order_type_lookup_code_tbl(i) = 'FIXED PRICE' THEN
        IF l_req_currency_code_tbl(i) = l_po_currency_code_tbl(i) THEN
          x_dists.amount_ordered_tbl(l_index) := l_req_currency_amount_tbl(i);
        ELSIF l_req_ou_currency_code_tbl(i) = l_po_currency_code_tbl(i) THEN
          x_dists.amount_ordered_tbl(l_index) := l_req_amount_tbl(i);
        ELSE
          x_dists.amount_ordered_tbl(l_index) := round(l_req_amount_tbl(i)/l_rate, l_precision);
        END IF;
        
        IF (PO_LOG.d_stmt) THEN
          PO_LOG.stmt(d_module, d_position, 'Converted Amount ', x_dists.amount_ordered_tbl(l_index));                                                      
        END IF;
      
      END IF;      
        
    END IF; -- l_req_ou_currency_code_tbl(i) <> l_po_currency_code_tbl(i)
  
  END LOOP;
  
  d_position := 80;    
  
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module);
  END IF;
 
EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    ( 
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;  
END process_currency_conversions;

-----------------------------------------------------------------------
--Start of Comments
--Name: process_qty_amt_rollups
--Function:
--  This procedure is used to process quantity and amount rollup. 
--    Lines quantity/amount will be updated with sum of shipments quantity/amount
--    Shipments quantity/amount will be updated with sum of distributions quantity/amount
--Parameters:
--IN: None
--IN OUT: None
--OUT: None
--End of Comments
------------------------------------------------------------------------
PROCEDURE process_qty_amt_rollups
(
    p_line_loc_id_tbl       IN PO_TBL_NUMBER,
    p_draft_id_tbl          IN PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'process_qty_amt_rollups';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  -- key of temp table used to identify the derived result
  l_key po_session_gt.key%TYPE;
  
  l_line_locs   PO_PDOI_TYPES.line_locs_rec_type;
  l_dists       PO_PDOI_TYPES.distributions_rec_type;
  
  l_draft_id_tbl        PO_TBL_NUMBER;
  l_loc_draft_id_tbl    PO_TBL_NUMBER;  --Bug#21878033 
  l_po_line_id_tbl      PO_TBL_NUMBER;
  l_line_loc_id_tbl     PO_TBL_NUMBER;   --Bug#21878033 
  
BEGIN

  d_position := 0;
 
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
  END IF;

  -- assign a new key used in temporary table
  l_key := PO_CORE_S.get_session_gt_nextval;
  
  d_position :=10;


  --<Bug#21878033 : START>--
  --Collecting line location ids in table 
  -- Using plsql table in select clause
  -- is causing out of memory error 
   FORALL i IN 1..p_line_loc_id_tbl.COUNT
  INSERT INTO po_session_gt
  (key,
   num1,
   num2)
  SELECT l_key,
         p_line_loc_id_tbl(i),
	 p_draft_id_tbl(i)
  FROM dual;

  SELECT DISTINCT num1,num2   
  BULK COLLECT INTO l_line_loc_id_tbl,l_loc_draft_id_tbl
  FROM po_session_gt
  WHERE KEY = l_key;

  DELETE FROM po_session_gt
  WHERE KEY = l_key;

  --<Bug#21878033 : END>---

  -- SQL What: Select draft_id, line_id, line_location_id, distribution_id, 
  --  quantity and amount from distributions draft table.
  -- SQL Why: Insert all these draft table values into the po_session_gt 
  --  which is used to roll up the quantity and amounts.
  -- SQL Join: draft_id and line_location_id

  --Bug#21878033 : Modified the query to avoid usiing plsql table in select clause
  FORALL i IN 1..l_line_loc_id_tbl.count
  INSERT INTO po_session_gt(
    key
  , num1
  , num2
  , num3
  , num4
  , num5
  , num6
  , char1) -- PDOI Enhancement Bug#17063664
  SELECT l_key
    , draft_dists.draft_id
    , draft_dists.po_line_id
    , draft_dists.line_location_id
    , draft_dists.po_distribution_id
    , draft_dists.quantity_ordered
    , draft_dists.amount_ordered
    , draft_line_loc.payment_type
  FROM po_distributions_draft_all draft_dists ,
       po_line_locations_draft_all draft_line_loc
  WHERE draft_dists.line_location_id = l_line_loc_id_tbl(i)
    AND draft_dists.draft_id         = l_loc_draft_id_tbl(i)  
    AND draft_line_loc.line_location_id = draft_dists.line_location_id
    AND draft_line_loc.draft_id = draft_dists.draft_id
    AND EXISTS (SELECT 'Y'
                FROM po_distributions_draft_all pda
		WHERE pda.line_location_id = draft_dists.line_location_id
		AND   pda.draft_id = draft_dists.draft_id
		AND   pda.req_distribution_id IS NOT NULL); -- Bug 17802425 rollup only when req reference

  d_position :=20;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_position, 'No of rows inserted in session table: ', SQL%ROWCOUNT);
  END IF;

  -- SQL What: Select draft_id and po_line_id values from po_session_gt table.
  -- SQL Why: Collect these attributes into local tables 
  SELECT DISTINCT num1, num2 -- draft_id, po_line_id
  BULK COLLECT INTO
    l_draft_id_tbl
  , l_po_line_id_tbl
  FROM po_session_gt
  WHERE key = l_key;
  
  -- SQL What: Select draft_id, line_id, line_location_id, distribution_id, 
  --  quantity and amount from po_distributions_all table.
  -- SQL Why: Insert all these transaction table values into po_session_gt 
  --  which is used to roll up the quantity and amounts.
  -- SQL Join: line_id of po_distributions_all

   -- Bug#21878033 : Modified the query to add FORALL statment instead
   -- of plsql table in select clause to improve performance
  FORALL i IN 1..l_po_line_id_tbl.COUNT 
  INSERT INTO po_session_gt(
    key
  , num1
  , num2
  , num3
  , num4
  , num5
  , num6
  , char1) -- PDOI Enhancement Bug#17063664
  SELECT l_key
    , l_draft_id_tbl(i)
    , txn_dists.po_line_id
    , txn_dists.line_location_id
    , txn_dists.po_distribution_id
    , txn_dists.quantity_ordered
    , txn_dists.amount_ordered
    , txn_line_loc.payment_type
  FROM po_distributions_all txn_dists ,
       po_line_locations_all txn_line_loc
  WHERE  txn_dists.po_line_id         = l_po_line_id_tbl(i)
    AND txn_line_loc.line_location_id = txn_dists.line_location_id;

  d_position :=30;
  
  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_position, 'No of rows inserted in session table: ', SQL%ROWCOUNT);
  END IF;
  
  -- SQL What: Select draft_id, line_location_id, sum of quantity's and sum of 
  --  amount's of distribution
  -- SQL Why: Need to update the shipments quantity/amount with 
  --    sum of distributions quantity/amount
  -- SQL Join: None
  SELECT psg.num1,       -- draft_id
         psg.num3,       -- line_location_id
         SUM(psg.num5),  -- quantity
         SUM(psg.num6)   -- amount
  BULK COLLECT INTO  
        l_dists.draft_id_tbl ,
        l_dists.loc_line_loc_id_tbl ,
        l_dists.quantity_ordered_tbl ,
        l_dists.amount_ordered_tbl
  FROM po_session_gt psg
  WHERE key = l_key
  GROUP BY psg.num3, psg.num1;  -- line_location_id

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_position, 'draft id', l_dists.draft_id_tbl);
    PO_LOG.stmt(d_module, d_position, 'line location id', l_dists.loc_line_loc_id_tbl);
    PO_LOG.stmt(d_module, d_position, 'quantity', l_dists.quantity_ordered_tbl);
    PO_LOG.stmt(d_module, d_position, 'amount', l_dists.amount_ordered_tbl);
  END IF; 
        
  d_position :=40;
  
  -- Update the quantity and amount in po_line_locations_interface table with 
  --    sum of distributions quantity/amount
  FORALL i IN 1..l_dists.loc_line_loc_id_tbl.COUNT
    UPDATE po_line_locations_draft_all plld
    SET plld.quantity           = l_dists.quantity_ordered_tbl(i) ,
        plld.amount             = l_dists.amount_ordered_tbl(i)
    WHERE plld.line_location_id = l_dists.loc_line_loc_id_tbl(i)
      AND plld.draft_id         = l_dists.draft_id_tbl(i); 
       
  d_position :=50;
  
  -- SQL What: Select draft_id, line_id and sum of quantity's 
  --  and sum of amount's of shipments
  -- SQL Why: Need to update the lines quantity/amount with 
  --    sum of shipments quantity/amount
  -- SQL Join: None
  SELECT psg.num1,       -- draft_id
         psg.num2,       -- line_id
         SUM(psg.num5),  -- quantity
         SUM(psg.num6)   -- amount
  BULK COLLECT INTO 
        l_line_locs.draft_id_tbl ,
        l_line_locs.ln_po_line_id_tbl ,
        l_line_locs.quantity_tbl ,
        l_line_locs.amount_tbl
  FROM po_session_gt psg
  WHERE key = l_key
  AND (char1 IS NULL
       OR char1 NOT IN ('ADVANCE','DELIVERY'))
       -- PDOI Enhancement Bug#17063664: do not consider payment_type advance and delivery
       -- For rollup of quantity and amount
  GROUP BY psg.num2, psg.num1;  -- line_id

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_position, 'draft id', l_line_locs.draft_id_tbl);
    PO_LOG.stmt(d_module, d_position, 'line id', l_line_locs.ln_po_line_id_tbl);
    PO_LOG.stmt(d_module, d_position, 'quantity', l_line_locs.quantity_tbl);
    PO_LOG.stmt(d_module, d_position, 'amount', l_line_locs.amount_tbl);
  END IF; 
        
  d_position :=60;
  
  -- Update the quantity and amount in po_lines_draft_all table with sum of shipments 
  --    quantity/amount  
  FORALL i IN 1..l_line_locs.ln_po_line_id_tbl.COUNT
    UPDATE po_lines_draft_all draft_lines
    SET draft_lines.quantity      = l_line_locs.quantity_tbl(i) ,
        draft_lines.amount        = l_line_locs.amount_tbl(i)
    WHERE draft_lines.po_line_id  = l_line_locs.ln_po_line_id_tbl(i)
      AND draft_lines.draft_id    = l_line_locs.draft_id_tbl(i);
    
  d_position :=70;
  
  -- Update the quantity and amount in po_lines_draft_all table with sum of shipments 
  --    quantity/amount for RATE based lines
  FORALL i IN 1..l_line_locs.ln_po_line_id_tbl.COUNT
    UPDATE po_lines_draft_all draft_lines
    SET amount =(SELECT SUM(Decode(Nvl(payment_type,'DELIVERY'),
                           'RATE',Nvl(quantity,0)*Nvl(price_override,0),
                           amount))                   
                 FROM po_line_locations_draft_all
                 WHERE  po_line_id = draft_lines.po_line_id
                  AND    draft_id = draft_lines.draft_id
                  AND    (payment_type IS NULL OR payment_type NOT IN ('ADVANCE','DELIVERY')))                                                         
    WHERE draft_lines.po_line_id  = l_line_locs.ln_po_line_id_tbl(i)
      AND draft_lines.draft_id    = l_line_locs.draft_id_tbl(i);
            
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;
       
EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    ( 
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END process_qty_amt_rollups;

-- <<PDOI Enhancement Bug#17063664 End>>

-----------------------------------------------------------------------
--Start of Comments
-- Bug 18599449
--Name: default_kanban_card_id
--Function:
--  defaults kanban_card_id from requisition_line
--Parameters:
--IN:
--  p_key
--    identifier in the temp table on the derived result
--  p_index_tbl         
--    indexes of the records
--p_req_line_id_tbl
--  list of requisition_line_ids
-- IN OUT:
-- x_kanban_card_id_tbl
--  kanban_card_id from requisition

--End of Comments
------------------------------------------------------------------------
PROCEDURE default_kanban_card_id
(
  p_key                  IN po_session_gt.key%TYPE,
  p_index_tbl            IN DBMS_SQL.NUMBER_TABLE,
  p_req_line_id_tbl      IN PO_TBL_NUMBER,
  x_kanban_card_id_tbl   IN OUT NOCOPY PO_TBL_NUMBER
) IS

  d_api_name CONSTANT VARCHAR2(30) := 'default_kanban_card_id';
  d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
  d_position NUMBER;

  l_index_tbl PO_TBL_NUMBER;
  l_result_tbl PO_TBL_NUMBER;

BEGIN

 d_position := 0;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module, 'p_req_line_id_tbl', p_req_line_id_tbl);
  END IF;

  -- retrieve kanban_card_id  from po_requisition_lines_all
  FORALL i IN 1..p_index_tbl.COUNT
  INSERT INTO po_session_gt(key, num1, num2)
  SELECT p_key,
         p_index_tbl(i),
         kanban_card_id
  FROM   po_requisition_lines_all
  WHERE  p_req_line_id_tbl(i) IS NOT NULL
  AND    requisition_line_id = p_req_line_id_tbl(i);

  d_position := 10;
 
  -- get result from temp table
  DELETE FROM po_session_gt
  WHERE key = p_key
  RETURNING num1, num2 BULK COLLECT INTO l_index_tbl, l_result_tbl;

  d_position := 20;
 
  -- set result back to x_kanban_card_id_tbl
  FOR i IN 1..l_index_tbl.COUNT
  LOOP
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_position, 'index', l_index_tbl(i));
      PO_LOG.stmt(d_module, d_position, 'kanban_card_id ',
                  l_result_tbl(i));
    END IF; 
    d_position := 30;
    x_kanban_card_id_tbl(l_index_tbl(i)) := l_result_tbl(i);
  END LOOP;

  d_position := 40;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end (d_module);
  END IF;
 
EXCEPTION
  WHEN OTHERS THEN
    PO_MESSAGE_S.add_exc_msg
    ( 
      p_pkg_name => d_pkg_name,
      p_procedure_name => d_api_name || '.' || d_position
    );
    RAISE;
END default_kanban_card_id;

-----------------------------------------------------------------------
 --Start of Comments
 -- Bug 18757772
 --Name: get_award_id
 --Function:
 --  get actual award_id from gms_award_distributions according to 
 --  the award_set_id store on requisition_lines.
 --Parameters:
 -- IN OUT:
 -- x_award_id_tbl from requisition_lines
 --End of Comments
 ------------------------------------------------------------------------
 PROCEDURE get_award_id (
 x_award_id IN OUT NOCOPY NUMBER
 ) IS
   d_api_name CONSTANT VARCHAR2(30) := 'get_award_id';
   d_module   CONSTANT VARCHAR2(255) := d_pkg_name || d_api_name || '.';
   d_position NUMBER;

   l_award_id NUMBER;
 BEGIN
   
   d_position := '0';
   
   IF (PO_LOG.d_proc) THEN
     PO_LOG.proc_begin(d_module);
   END IF;

   IF (PO_PDOI_PARAMS.g_product.gms_enabled = FND_API.g_FALSE) THEN
     IF (PO_LOG.d_proc) THEN
       PO_LOG.proc_end(d_module);
     END IF;

     RETURN;
   END IF;
   
   d_position := '10';
   
   SELECT award_id
   INTO l_award_id
   FROM gms_award_distributions
   WHERE award_set_id = x_award_id;

   x_award_id := l_award_id;

   IF (PO_LOG.d_proc) THEN
     PO_LOG.proc_end(d_module);
   END IF;

   EXCEPTION
   WHEN OTHERS THEN
     PO_MESSAGE_S.add_exc_msg
     (
       p_pkg_name => d_pkg_name,
       p_procedure_name => d_api_name || '.' || d_position
     );
     RAISE;   
   
 END get_award_id;

END PO_PDOI_DIST_PROCESS_PVT;
/
SHOW ERRORS;
EXIT;
