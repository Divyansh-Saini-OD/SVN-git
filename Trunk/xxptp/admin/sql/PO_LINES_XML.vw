-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : PO_LINES_XML.sql                                                     |
-- | Description      : SQL Script to replace view PO_LINES_XML                              |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    | 
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   23-APR-2007       Sarah Justina    Initial draft version                      |              
-- |1.0        30-APR-2007       Sarah Justina    Baseline                                   |
-- |2.0        22-Apr-2008       Antonio Morales  Included nvl for quantity (defect# 5933)   |
-- |3.0        09-Feb-2009       Rama Dwibhashyam quantity column fixed (defect# 12727)      |
-- |3.1        27-MAY-2009       Rama Dwibhashyam Unit Price Decimal fixed (defect# 15456)   |
-- |4.0        14-Jun-2012       Adithya          defect#16630- Minimum Baseline patch-retrofit|
-- |4.1        10-OCT-2013       Darshini         E0407 - Modified for R12 Upgrade Retrofit  |
-- |4.2        14-Dec-2013       Darshini         E0407 - Defect#26317- Modified the query to|
-- |                                              pick the tax amount from po_distributions_all| 
-- |4.3        13-Mar-2014       Deepak           E0407 - Defect#28601- Changes for the      |
-- |                                              performance.                               |
-- |6.2        27-May-2015       Harvinder Rakhra Defect 34469 Incorporated ceded changes    | 
-- |                                              12.0.3 version                             | 
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Replacing view PO_LINES_XML
-- ************************************************

WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Replacing view PO_LINES_XML
PROMPT
SET TERM OFF

CREATE OR REPLACE VIEW apps.po_lines_xml (item_revision,
                                     line_num,
                                     item_description,
                                     cancel_flag,
                                     cancel_date,
                                     cancel_reason,
                                     vendor_product_num,
                                     note_to_vendor,
                                     unit_meas_lookup_code,
                                     un_number,
                                     un_desc,
                                     hazard_class,
                                     order_type_lookup_code,
                                     contract_num,
                                     segment1,
                                     global_agreement_flag,
                                     quote_vendor_quote_number,
                                     quotation_line,
                                     attribute_category,
                                     attribute1,
                                     attribute2,
                                     attribute3,
                                     attribute4,
                                     attribute5,
                                     attribute6,
                                     attribute7,
                                     attribute8,
                                     attribute9,
                                     attribute10,
                                     attribute11,
                                     attribute12,
                                     attribute13,
                                     attribute14,
                                     attribute15,
                                     unit_price,
                                     quantity,
                                     quantity_committed,
                                     po_header_id,
                                     po_line_id,
                                     item_id,
                                     from_header_id,
                                     from_line_id,
                                     reference_num,
                                     min_release_amount,
                                     price_type_lookup_code,
                                     closed_code,
                                     price_break_lookup_code,
                                     ussgl_transaction_code,
                                     government_context,
                                     request_id,
                                     program_application_id,
                                     program_id,
                                     program_update_date,
                                     closed_date,
                                     closed_reason,
                                     closed_by,
                                     transaction_reason_code,
                                     org_id,
                                     hazard_class_id,
                                     min_order_quantity,
                                     max_order_quantity,
                                     qty_rcv_tolerance,
                                     over_tolerance_error_flag,
                                     market_price,
                                     unordered_flag,
                                     closed_flag,
                                     user_hold_flag,
                                     cancelled_by,
                                     firm_status_lookup_code,
                                     firm_date,
                                     taxable_flag,
                                     type_1099,
                                     capital_expense_flag,
                                     negotiated_by_preparer_flag,
                                     qc_grade,
                                     base_uom,
                                     base_qty,
                                     secondary_uom,
                                     secondary_qty,
                                     last_update_date,
                                     last_updated_by,
                                     line_type_id,
                                     last_update_login,
                                     creation_date,
                                     created_by,
                                     category_id,
                                     committed_amount,
                                     allow_price_override_flag,
                                     not_to_exceed_price,
                                     list_price_per_unit,
                                     un_number_id,
                                     global_attribute_category,
                                     global_attribute1,
                                     global_attribute2,
                                     global_attribute3,
                                     global_attribute4,
                                     global_attribute5,
                                     global_attribute6,
                                     global_attribute7,
                                     global_attribute8,
                                     global_attribute9,
                                     global_attribute10,
                                     global_attribute11,
                                     global_attribute12,
                                     global_attribute13,
                                     global_attribute14,
                                     global_attribute15,
                                     global_attribute16,
                                     global_attribute17,
                                     global_attribute18,
                                     global_attribute19,
                                     global_attribute20,
                                     line_reference_num,
                                     project_id,
                                     task_id,
                                     expiration_date,
                                     tax_code_id,
                                     oke_contract_header_id,
                                     oke_contract_version_id,
                                     tax_name,
                                     secondary_unit_of_measure,
                                     secondary_quantity,
                                     preferred_grade,
                                     auction_header_id,
                                     auction_display_number,
                                     auction_line_number,
                                     bid_number,
                                     bid_line_number,
                                     retroactive_date,
                                     supplier_ref_number,
                                     contract_id,
                                     job_id,
                                     amount,
                                     start_date,
                                     line_type,
                                     purchase_basis,
                                     item_num,
                                     job_name,
                                     contractor_first_name,
                                     contractor_last_name,
                                     line_amount,
                                     canceled_amount,
                                     total_line_amount,
                                     base_unit_price,
                                     manual_price_change_flag,
                                     matching_basis,
                                     svc_amount_notif_sent,
                                     svc_completion_notif_sent,
                                     from_line_location_id,
                                     retainage_rate,
                                     max_retainage_amount,
                                     progress_payment_rate,
                                     recoupment_rate,
                                     --Added for R12 Upgrade Retrofit
                                     country_of_origin,
                                     total_amount,
                                     dept_class_subclass,
                                     master_cartons,
                                     description,
                                     qty_ordered,
                                     qty_cancelled,
                                     line_short_text,
                                     shipment_lines,
                                     min_line_loc_id,
                                     is_long_text
                                     --end
                                    )
					AS
SELECT pl.item_revision, pl.line_num,
       DECODE (NVL (msi.allow_item_desc_update_flag, 'Y'),
               'Y', pl.item_description,
               DECODE (pl.order_type_lookup_code,
                       'QUANTITY', t.description,
                       pl.item_description
                      )
              ) item_description,
       NVL (pl.cancel_flag, 'N') cancel_flag,
       TO_CHAR (pl.cancel_date, 'DD-MON-YYYY HH24:MI:SS') cancel_date,
       pl.cancel_reason, pl.vendor_product_num, pl.note_to_vendor,
       NVL (mum.unit_of_measure_tl,
            pl.unit_meas_lookup_code
           ) unit_meas_lookup_code,
       pun.un_number, pun.description un_desc, phc.hazard_class,
       plt.order_type_lookup_code,
       DECODE
             (NVL (pl.contract_id, -1),
              -1, NULL,
              po_communication_pvt.getsegmentnum (pl.contract_id)
             ) contract_num,
       DECODE (NVL (pl.from_header_id, -1),
               -1, NULL,
               po_communication_pvt.getsegmentnum (pl.from_header_id)
              ) segment1,
       DECODE (NVL (pl.from_header_id, -1),
               -1, NULL,
               po_communication_pvt.getagreementflag ()
              ) global_agreement_flag,
       DECODE
            (NVL (pl.from_header_id, -1),
             -1, NULL,
             po_communication_pvt.getquotenumber ()
            ) quote_vendor_quote_number,
       DECODE
          (NVL (pl.from_line_id, -1),
           -1, NULL,
           po_communication_pvt.getagreementlinenumber (pl.from_line_id)
          ) quotation_line,
       pl.attribute_category, pl.attribute1,
       --Commented and added for Defect#26317
       --pl.attribute2,
       (SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
               + SUM (NVL (pda.recoverable_tax, 0))
          FROM po_distributions_all pda
         WHERE pl.po_line_id = pda.po_line_id) attribute2,
       pl.attribute3, pl.attribute4, pl.attribute5, pl.attribute6,
       pl.attribute7, pl.attribute8, pl.attribute9, pl.attribute10,
       pl.attribute11, pl.attribute12, pl.attribute13, pl.attribute14,
       pl.attribute15, pl.unit_price, pl.quantity, pl.quantity_committed,
       pl.po_header_id, pl.po_line_id, pl.item_id, pl.from_header_id,
       pl.from_line_id, pl.reference_num,
       TO_CHAR (pl.min_release_amount, pgt.format_mask) min_release_amount,
       pl.price_type_lookup_code, pl.closed_code, pl.price_break_lookup_code,
       pl.ussgl_transaction_code, pl.government_context, pl.request_id,
       pl.program_application_id, pl.program_id,
       TO_CHAR (pl.program_update_date,
                'DD-MON-YYYY HH24:MI:SS'
               ) program_update_date,
       TO_CHAR (pl.closed_date, 'DD-MON-YYYY HH24:MI:SS') closed_date,
       pl.closed_reason, pl.closed_by, pl.transaction_reason_code, pl.org_id,
       pl.hazard_class_id, pl.min_order_quantity, pl.max_order_quantity,
       pl.qty_rcv_tolerance, pl.over_tolerance_error_flag, pl.market_price,
       pl.unordered_flag, pl.closed_flag, pl.user_hold_flag, pl.cancelled_by,
       pl.firm_status_lookup_code,
       TO_CHAR (pl.firm_date, 'DD-MON-YYYY HH24:MI:SS') firm_date,
       pl.taxable_flag, pl.type_1099, pl.capital_expense_flag,
       pl.negotiated_by_preparer_flag, pl.qc_grade, pl.base_uom, pl.base_qty,
       pl.secondary_uom, pl.secondary_qty,
       TO_CHAR (pl.last_update_date,
                'DD-MON-YYYY HH24:MI:SS'
               ) last_update_date,
       pl.last_updated_by, pl.line_type_id, pl.last_update_login,
       TO_CHAR (pl.creation_date, 'DD-MON-YYYY HH24:MI:SS') creation_date,
       pl.created_by, pl.category_id,
       TO_CHAR (pl.committed_amount, pgt.format_mask) committed_amount,
       pl.allow_price_override_flag, pl.not_to_exceed_price,
       pl.list_price_per_unit, pl.un_number_id, pl.global_attribute_category,
       pl.global_attribute1, pl.global_attribute2, pl.global_attribute3,
       pl.global_attribute4, pl.global_attribute5, pl.global_attribute6,
       pl.global_attribute7, pl.global_attribute8, pl.global_attribute9,
       pl.global_attribute10, pl.global_attribute11, pl.global_attribute12,
       pl.global_attribute13, pl.global_attribute14, pl.global_attribute15,
       pl.global_attribute16, pl.global_attribute17, pl.global_attribute18,
       pl.global_attribute19, pl.global_attribute20, pl.line_reference_num,
       pl.project_id, pl.task_id,
       TO_CHAR (pl.expiration_date, 'DD-MON-YYYY HH24:MI:SS') expiration_date,
       pl.tax_code_id, pl.oke_contract_header_id, pl.oke_contract_version_id,
       pl.tax_name, pl.secondary_unit_of_measure, pl.secondary_quantity,
       pl.preferred_grade, pl.auction_header_id, pl.auction_display_number,
       pl.auction_line_number, pl.bid_number, pl.bid_line_number,
       pl.retroactive_date, pl.supplier_ref_number, pl.contract_id, pl.job_id,
       pl.amount, TO_CHAR (pl.start_date,
                           'DD-MON-YYYY HH24:MI:SS') start_date,
       plt.order_type_lookup_code line_type, plt.purchase_basis,
       po_communication_pvt.get_item_num (pl.item_id,
                                          msi.organization_id
                                         ) item_num,
       DECODE (NVL (pl.job_id, -1),
               -1, NULL,
               po_communication_pvt.getjob (pl.job_id)
              ) job_name,
       pl.contractor_first_name, pl.contractor_last_name,
       TO_CHAR
          (DECODE (pgt.po_release_id,
                   NULL, po_core_s.get_total ('L', pl.po_line_id),
                   po_core_s.get_release_line_total (pl.po_line_id,
                                                     pgt.po_release_id
                                                    )
                  ),
           pgt.format_mask
          ) line_amount,
       DECODE
          (pl.cancel_flag,
           'Y', TO_CHAR
                     (po_communication_pvt.getcanceledamount (pl.po_line_id,
                                                              NULL,
                                                              pl.po_header_id
                                                             ),
                      pgt.format_mask
                     ),
           NULL
          ) canceled_amount,
       DECODE
          (pl.cancel_flag,
           'Y', TO_CHAR (po_communication_pvt.getlineoriginalamount (),
                         pgt.format_mask
                        ),
           NULL
          ) total_line_amount,
       pl.base_unit_price, pl.manual_price_change_flag, pl.matching_basis,
       pl.svc_amount_notif_sent, pl.svc_completion_notif_sent,
       pl.from_line_location_id, pl.retainage_rate,
       TO_CHAR (pl.max_retainage_amount,
                pgt.format_mask) max_retainage_amount,
       pl.progress_payment_rate, pl.recoupment_rate,
       --Added for R12 Upgrade Retrofit
       DECODE
             ((SELECT COUNT (po_line_id) - 1
                 FROM po_line_locations_all
                WHERE po_line_id = pl.po_line_id),
              0, (SELECT DISTINCT country_of_origin_code
                             FROM po_line_locations_all
                            WHERE po_line_id = pl.po_line_id
                              AND po_header_id = pl.po_header_id),
              ''
             ) AS country_of_origin,
       -- Included nvl for quantity (defect# 5933)
       TO_CHAR (NVL (pl.unit_price, 0) * NVL (pl.quantity, 0),
                pgt.format_mask
               ) AS total_amount,
          mc.segment3
       || '/'
       || mc.segment4
       || '/'
       || mc.segment5 AS dept_class_subclass,
       (SELECT pasl.attribute2 case_pack_size
          FROM po_approved_supplier_list pasl,
               po_headers_all ph
         WHERE pasl.vendor_site_id = ph.vendor_site_id
           AND pasl.item_id(+) = pl.item_id
           AND ph.po_header_id = pl.po_header_id
           AND pasl.using_organization_id = ph.org_id) master_cartons,
       (SELECT description
          FROM mtl_system_items
         WHERE inventory_item_id = pl.item_id
           AND organization_id = fsp.inventory_organization_id)
                                                               AS description,
       -- Included nvl for quantity (defect# 5933,)
       -- Release id logic for quantity (defect# 12727)
       DECODE (pgt.po_release_id,
               NULL, (SELECT SUM (NVL (quantity, 0))
                        FROM po_line_locations_all
                       WHERE po_line_id = pl.po_line_id),
               (SELECT SUM (NVL (quantity, 0))
                  FROM po_line_locations_all
                 WHERE po_line_id = pl.po_line_id
                   AND po_release_id = pgt.po_release_id)
              ) AS qty_ordered,
       (SELECT SUM (quantity_cancelled)
          FROM po_line_locations_all
         WHERE po_line_id = pl.po_line_id) AS qty_cancelled,
       CAST
          (MULTISET (SELECT fdst.short_text
                       FROM fnd_attached_documents fad,
                            fnd_documents_short_text fdst,
                            fnd_documents_tl fdt
                      WHERE fad.entity_name = 'PO_LINES'
                        AND fdst.media_id = fdt.media_id
                        AND fad.pk1_value = pl.po_line_id
                        AND fdt.document_id = fad.document_id
                    ) AS xx_po_short_text_tab
          ) line_rec,
       (SELECT COUNT (po_line_id)
          FROM po_line_locations_all
         WHERE po_line_id = pl.po_line_id) AS shipment_lines,
       -- Included nvl for ship_to_location_id to solve defect#6456
       (SELECT MIN (NVL (ship_to_location_id, 0))
          FROM po_line_locations_all
         WHERE po_line_id = pl.po_line_id) AS min_line_loc_id,
       (SELECT COUNT (1)
          FROM fnd_attached_docs_form_vl fad,
               fnd_documents_long_text fds,
               po_lines_all plx
         WHERE entity_name = 'PO_LINES'
           AND pk1_value = plx.po_line_id
           AND function_name = 'PO_PRINTPO'
           AND fad.media_id = fds.media_id
           AND plx.po_header_id = pl.po_header_id
           AND plx.po_line_id = pl.po_line_id) AS is_long_text
  -- Include release id by Paul
  --end
FROM   po_line_types_b plt,
       po_lines_all pl,
       po_un_numbers_tl pun,
       po_hazard_classes_tl phc,
       mtl_units_of_measure_tl mum,
       mtl_system_items_tl t,
       mtl_system_items_b msi,
       financials_system_params_all fsp,
       po_communication_gt pgt,
       mtl_categories mc                      --Added for R12 Upgrade Retrofit
 WHERE pl.line_type_id = plt.line_type_id
   AND pl.hazard_class_id = phc.hazard_class_id(+)
   AND pl.un_number_id = pun.un_number_id(+)
   AND pl.unit_meas_lookup_code = mum.unit_of_measure(+)
   AND pl.item_id = msi.inventory_item_id
   AND NVL (msi.organization_id, fsp.inventory_organization_id) =
                                                 fsp.inventory_organization_id
   AND phc.LANGUAGE(+) = USERENV ('LANG')
   AND pun.LANGUAGE(+) = USERENV ('LANG')
   AND mum.LANGUAGE(+) = USERENV ('LANG')
   AND pl.org_id = fsp.org_id
   AND mc.category_id = pl.category_id        --Added for R12 Upgrade Retrofit
   AND pgt.po_header_id = pl.po_header_id
   AND msi.inventory_item_id = t.inventory_item_id
   AND msi.organization_id = t.organization_id
   AND t.LANGUAGE(+) = USERENV ('LANG')
UNION ALL
SELECT pl.item_revision, pl.line_num, pl.item_description item_description,
       NVL (pl.cancel_flag, 'N') cancel_flag,
       TO_CHAR (pl.cancel_date, 'DD-MON-YYYY HH24:MI:SS') cancel_date,
       pl.cancel_reason, pl.vendor_product_num, pl.note_to_vendor,
       NVL (mum.unit_of_measure_tl,
            pl.unit_meas_lookup_code
           ) unit_meas_lookup_code,
       pun.un_number, pun.description un_desc, phc.hazard_class,
       plt.order_type_lookup_code,
       DECODE
             (NVL (pl.contract_id, -1),
              -1, NULL,
              po_communication_pvt.getsegmentnum (pl.contract_id)
             ) contract_num,
       DECODE (NVL (pl.from_header_id, -1),
               -1, NULL,
               po_communication_pvt.getsegmentnum (pl.from_header_id)
              ) segment1,
       DECODE (NVL (pl.from_header_id, -1),
               -1, NULL,
               po_communication_pvt.getagreementflag ()
              ) global_agreement_flag,
       DECODE
            (NVL (pl.from_header_id, -1),
             -1, NULL,
             po_communication_pvt.getquotenumber ()
            ) quote_vendor_quote_number,
       DECODE
          (NVL (pl.from_line_id, -1),
           -1, NULL,
           po_communication_pvt.getagreementlinenumber (pl.from_line_id)
          ) quotation_line,
       pl.attribute_category, pl.attribute1,
       --Commented and added for defect#26317
       --pl.attribute2,
       (SELECT   SUM (NVL (pda.nonrecoverable_tax, 0))
               + SUM (NVL (pda.recoverable_tax, 0))
          FROM po_distributions_all pda
         WHERE pl.po_line_id = pda.po_line_id) attribute2,
       pl.attribute3, pl.attribute4, pl.attribute5, pl.attribute6,
       pl.attribute7, pl.attribute8, pl.attribute9, pl.attribute10,
       pl.attribute11, pl.attribute12, pl.attribute13, pl.attribute14,
       pl.attribute15, pl.unit_price, pl.quantity, pl.quantity_committed,
       pl.po_header_id, pl.po_line_id, pl.item_id, pl.from_header_id,
       pl.from_line_id, pl.reference_num,
       TO_CHAR (pl.min_release_amount, pgt.format_mask) min_release_amount,
       pl.price_type_lookup_code, pl.closed_code, pl.price_break_lookup_code,
       pl.ussgl_transaction_code, pl.government_context, pl.request_id,
       pl.program_application_id, pl.program_id,
       TO_CHAR (pl.program_update_date,
                'DD-MON-YYYY HH24:MI:SS'
               ) program_update_date,
       TO_CHAR (pl.closed_date, 'DD-MON-YYYY HH24:MI:SS') closed_date,
       pl.closed_reason, pl.closed_by, pl.transaction_reason_code, pl.org_id,
       pl.hazard_class_id, pl.min_order_quantity, pl.max_order_quantity,
       pl.qty_rcv_tolerance, pl.over_tolerance_error_flag, pl.market_price,
       pl.unordered_flag, pl.closed_flag, pl.user_hold_flag, pl.cancelled_by,
       pl.firm_status_lookup_code,
       TO_CHAR (pl.firm_date, 'DD-MON-YYYY HH24:MI:SS') firm_date,
       pl.taxable_flag, pl.type_1099, pl.capital_expense_flag,
       pl.negotiated_by_preparer_flag, pl.qc_grade, pl.base_uom, pl.base_qty,
       pl.secondary_uom, pl.secondary_qty,
       TO_CHAR (pl.last_update_date,
                'DD-MON-YYYY HH24:MI:SS'
               ) last_update_date,
       pl.last_updated_by, pl.line_type_id, pl.last_update_login,
       TO_CHAR (pl.creation_date, 'DD-MON-YYYY HH24:MI:SS') creation_date,
       pl.created_by, pl.category_id,
       TO_CHAR (pl.committed_amount, pgt.format_mask) committed_amount,
       pl.allow_price_override_flag, pl.not_to_exceed_price,
       pl.list_price_per_unit, pl.un_number_id, pl.global_attribute_category,
       pl.global_attribute1, pl.global_attribute2, pl.global_attribute3,
       pl.global_attribute4, pl.global_attribute5, pl.global_attribute6,
       pl.global_attribute7, pl.global_attribute8, pl.global_attribute9,
       pl.global_attribute10, pl.global_attribute11, pl.global_attribute12,
       pl.global_attribute13, pl.global_attribute14, pl.global_attribute15,
       pl.global_attribute16, pl.global_attribute17, pl.global_attribute18,
       pl.global_attribute19, pl.global_attribute20, pl.line_reference_num,
       pl.project_id, pl.task_id,
       TO_CHAR (pl.expiration_date, 'DD-MON-YYYY HH24:MI:SS') expiration_date,
       pl.tax_code_id, pl.oke_contract_header_id, pl.oke_contract_version_id,
       pl.tax_name, pl.secondary_unit_of_measure, pl.secondary_quantity,
       pl.preferred_grade, pl.auction_header_id, pl.auction_display_number,
       pl.auction_line_number, pl.bid_number, pl.bid_line_number,
       pl.retroactive_date, pl.supplier_ref_number, pl.contract_id, pl.job_id,
       pl.amount, TO_CHAR (pl.start_date,
                           'DD-MON-YYYY HH24:MI:SS') start_date,
       plt.order_type_lookup_code line_type, plt.purchase_basis,
       NULL item_num,
       DECODE (NVL (pl.job_id, -1),
               -1, NULL,
               po_communication_pvt.getjob (pl.job_id)
              ) job_name,
       pl.contractor_first_name, pl.contractor_last_name,
       TO_CHAR
          (DECODE (pgt.po_release_id,
                   NULL, po_core_s.get_total ('L', pl.po_line_id),
                   po_core_s.get_release_line_total (pl.po_line_id,
                                                     pgt.po_release_id
                                                    )
                  ),
           pgt.format_mask
          ) line_amount,
       DECODE
          (pl.cancel_flag,
           'Y', TO_CHAR
                     (po_communication_pvt.getcanceledamount (pl.po_line_id,
                                                              NULL,
                                                              pl.po_header_id
                                                             ),
                      pgt.format_mask
                     ),
           NULL
          ) canceled_amount,
       DECODE
          (pl.cancel_flag,
           'Y', TO_CHAR (po_communication_pvt.getlineoriginalamount (),
                         pgt.format_mask
                        ),
           NULL
          ) total_line_amount,
       pl.base_unit_price, pl.manual_price_change_flag, pl.matching_basis,
       pl.svc_amount_notif_sent, pl.svc_completion_notif_sent,
       pl.from_line_location_id, pl.retainage_rate,
       TO_CHAR (pl.max_retainage_amount,
                pgt.format_mask) max_retainage_amount,
       pl.progress_payment_rate, pl.recoupment_rate,
       --Added for R12 Upgrade Retrofit
       DECODE
             ((SELECT COUNT (po_line_id) - 1
                 FROM po_line_locations_all
                WHERE po_line_id = pl.po_line_id),
              0, (SELECT DISTINCT country_of_origin_code
                             FROM po_line_locations_all
                            WHERE po_line_id = pl.po_line_id
                              AND po_header_id = pl.po_header_id),
              ''
             ) AS country_of_origin,
       -- Included nvl for quantity (defect# 5933)
       TO_CHAR (NVL (pl.unit_price, 0) * NVL (pl.quantity, 0),
                pgt.format_mask
               ) AS total_amount,
          mc.segment3
       || '/'
       || mc.segment4
       || '/'
       || mc.segment5 AS dept_class_subclass,
       (SELECT pasl.attribute2 case_pack_size
          FROM po_approved_supplier_list pasl,
               po_headers_all ph
         WHERE pasl.vendor_site_id = ph.vendor_site_id
           AND pasl.item_id(+) = pl.item_id
           AND ph.po_header_id = pl.po_header_id
           AND pasl.using_organization_id = ph.org_id) master_cartons,
       (SELECT description
          FROM mtl_system_items
         WHERE inventory_item_id = pl.item_id
           AND organization_id = fsp.inventory_organization_id)
                                                               AS description,
       -- Included nvl for quantity (defect# 5933,)
       -- Release id logic for quantity (defect# 12727)
       DECODE (pgt.po_release_id,
               NULL, (SELECT SUM (NVL (quantity, 0))
                        FROM po_line_locations_all
                       WHERE po_line_id = pl.po_line_id),
               (SELECT SUM (NVL (quantity, 0))
                  FROM po_line_locations_all
                 WHERE po_line_id = pl.po_line_id
                   AND po_release_id = pgt.po_release_id)
              ) AS qty_ordered,
       (SELECT SUM (quantity_cancelled)
          FROM po_line_locations_all
         WHERE po_line_id = pl.po_line_id) AS qty_cancelled,
       CAST
          (MULTISET (SELECT fdst.short_text
                       FROM fnd_attached_documents fad,
                            fnd_documents_short_text fdst,
                            fnd_documents_tl fdt
                      WHERE fad.entity_name = 'PO_LINES'
                        AND fdst.media_id = fdt.media_id
                        AND fad.pk1_value = pl.po_line_id
                        AND fdt.document_id = fad.document_id
                    ) AS xx_po_short_text_tab
          ) line_rec,
       (SELECT COUNT (po_line_id)
          FROM po_line_locations_all
         WHERE po_line_id = pl.po_line_id) AS shipment_lines,
       -- Included nvl for ship_to_location_id to solve defect#6456
       (SELECT MIN (NVL (ship_to_location_id, 0))
          FROM po_line_locations_all
         WHERE po_line_id = pl.po_line_id) AS min_line_loc_id,
       (SELECT COUNT (1)
          FROM fnd_attached_docs_form_vl fad,
               fnd_documents_long_text fds,
               po_lines_all plx
         WHERE entity_name = 'PO_LINES'
           AND pk1_value = plx.po_line_id
           AND function_name = 'PO_PRINTPO'
           AND fad.media_id = fds.media_id
           AND plx.po_header_id = pl.po_header_id
           AND plx.po_line_id = pl.po_line_id) AS is_long_text
  -- Include release id by Paul
  --end
FROM   po_line_types_b plt,
       po_lines_all pl,
       po_un_numbers_tl pun,
       po_hazard_classes_tl phc,
       mtl_units_of_measure_tl mum,
       financials_system_params_all fsp,
       po_communication_gt pgt,
       mtl_categories mc                      --Added for R12 Upgrade Retrofit
 WHERE pl.line_type_id = plt.line_type_id
   AND pl.hazard_class_id = phc.hazard_class_id(+)
   AND pl.un_number_id = pun.un_number_id(+)
   AND pl.unit_meas_lookup_code = mum.unit_of_measure(+)
   AND pl.item_id IS NULL
   AND pgt.po_header_id = pl.po_header_id
   AND phc.LANGUAGE(+) = USERENV ('LANG')
   AND pun.LANGUAGE(+) = USERENV ('LANG')
   AND mum.LANGUAGE(+) = USERENV ('LANG')
   AND pl.org_id = fsp.org_id
   AND mc.category_id = pl.category_id        --Added for R12 Upgrade Retrofit
/

SHOW ERRORS;

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************   
