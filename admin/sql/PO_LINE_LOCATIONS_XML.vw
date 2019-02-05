SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Replacing view PO_LINE_LOCATIONS_XML
-- ************************************************

WHENEVER SQLERROR CONTINUE
SET TERM ON
PROMPT
PROMPT Replacing view PO_LINE_LOCATIONS_XML
PROMPT
SET TERM OFF

CREATE OR REPLACE FORCE VIEW APPS.PO_LINE_LOCATIONS_XML (SHIPMENT_NUM
                                                       , DUE_DATE
                                                       , QUANTITY
                                                       , PRICE_OVERRIDE
                                                       , QUANTITY_CANCELLED
                                                       , CANCEL_FLAG
                                                       , CANCEL_DATE
                                                       , CANCEL_REASON
                                                       , TAXABLE_FLAG
                                                       , START_DATE
                                                       , END_DATE
                                                       , ATTRIBUTE_CATEGORY
                                                       , ATTRIBUTE1
                                                       , ATTRIBUTE2
                                                       , ATTRIBUTE3
                                                       , ATTRIBUTE4
                                                       , ATTRIBUTE5
                                                       , ATTRIBUTE6
                                                       , ATTRIBUTE7
                                                       , ATTRIBUTE8
                                                       , ATTRIBUTE9
                                                       , ATTRIBUTE10
                                                       , ATTRIBUTE11
                                                       , ATTRIBUTE12
                                                       , ATTRIBUTE13
                                                       , ATTRIBUTE14
                                                       , ATTRIBUTE15
                                                       , PO_HEADER_ID
                                                       , PO_LINE_ID
                                                       , LINE_LOCATION_ID
                                                       , SHIPMENT_TYPE
                                                       , PO_RELEASE_ID
                                                       , CONSIGNED_FLAG
                                                       , USSGL_TRANSACTION_CODE
                                                       , GOVERNMENT_CONTEXT
                                                       , RECEIVING_ROUTING_ID
                                                       , ACCRUE_ON_RECEIPT_FLAG
                                                       , CLOSED_REASON
                                                       , CLOSED_DATE
                                                       , CLOSED_BY
                                                       , ORG_ID
                                                       , UNIT_OF_MEASURE_CLASS
                                                       , ENCUMBER_NOW
                                                       , INSPECTION_REQUIRED_FLAG
                                                       , RECEIPT_REQUIRED_FLAG
                                                       , QTY_RCV_TOLERANCE
                                                       , QTY_RCV_EXCEPTION_CODE
                                                       , ENFORCE_SHIP_TO_LOCATION_CODE
                                                       , ALLOW_SUBSTITUTE_RECEIPTS_FLAG
                                                       , DAYS_EARLY_RECEIPT_ALLOWED
                                                       , DAYS_LATE_RECEIPT_ALLOWED
                                                       , RECEIPT_DAYS_EXCEPTION_CODE
                                                       , INVOICE_CLOSE_TOLERANCE
                                                       , RECEIVE_CLOSE_TOLERANCE
                                                       , SHIP_TO_ORGANIZATION_ID
                                                       , SOURCE_SHIPMENT_ID
                                                       , CLOSED_CODE
                                                       , REQUEST_ID
                                                       , PROGRAM_APPLICATION_ID
                                                       , PROGRAM_ID
                                                       , PROGRAM_UPDATE_DATE
                                                       , LAST_ACCEPT_DATE
                                                       , ENCUMBERED_FLAG
                                                       , ENCUMBERED_DATE
                                                       , UNENCUMBERED_QUANTITY
                                                       , FOB_LOOKUP_CODE
                                                       , FREIGHT_TERMS_LOOKUP_CODE
                                                       , ESTIMATED_TAX_AMOUNT
                                                       , FROM_HEADER_ID
                                                       , FROM_LINE_ID
                                                       , FROM_LINE_LOCATION_ID
                                                       , LEAD_TIME
                                                       , LEAD_TIME_UNIT
                                                       , PRICE_DISCOUNT
                                                       , TERMS_ID
                                                       , APPROVED_FLAG
                                                       , APPROVED_DATE
                                                       , CLOSED_FLAG
                                                       , CANCELLED_BY
                                                       , FIRM_STATUS_LOOKUP_CODE
                                                       , FIRM_DATE
                                                       , LAST_UPDATE_DATE
                                                       , LAST_UPDATED_BY
                                                       , LAST_UPDATE_LOGIN
                                                       , CREATION_DATE
                                                       , CREATED_BY
                                                       , QUANTITY_RECEIVED
                                                       , QUANTITY_ACCEPTED
                                                       , QUANTITY_REJECTED
                                                       , QUANTITY_BILLED
                                                       , UNIT_MEAS_LOOKUP_CODE
                                                       , SHIP_VIA_LOOKUP_CODE
                                                       , GLOBAL_ATTRIBUTE_CATEGORY
                                                       , GLOBAL_ATTRIBUTE1
                                                       , GLOBAL_ATTRIBUTE2
                                                       , GLOBAL_ATTRIBUTE3
                                                       , GLOBAL_ATTRIBUTE4
                                                       , GLOBAL_ATTRIBUTE5
                                                       , GLOBAL_ATTRIBUTE6
                                                       , GLOBAL_ATTRIBUTE7
                                                       , GLOBAL_ATTRIBUTE8
                                                       , GLOBAL_ATTRIBUTE9
                                                       , GLOBAL_ATTRIBUTE10
                                                       , GLOBAL_ATTRIBUTE11
                                                       , GLOBAL_ATTRIBUTE12
                                                       , GLOBAL_ATTRIBUTE13
                                                       , GLOBAL_ATTRIBUTE14
                                                       , GLOBAL_ATTRIBUTE15
                                                       , GLOBAL_ATTRIBUTE16
                                                       , GLOBAL_ATTRIBUTE17
                                                       , GLOBAL_ATTRIBUTE18
                                                       , GLOBAL_ATTRIBUTE19
                                                       , GLOBAL_ATTRIBUTE20
                                                       , QUANTITY_SHIPPED
                                                       , COUNTRY_OF_ORIGIN_CODE
                                                       , TAX_USER_OVERRIDE_FLAG
                                                       , MATCH_OPTION
                                                       , CALCULATE_TAX_FLAG
                                                       , CHANGE_PROMISED_DATE_REASON
                                                       , NOTE_TO_RECEIVER
                                                       , SECONDARY_UNIT_OF_MEASURE
                                                       , SECONDARY_QUANTITY
                                                       , PREFERRED_GRADE
                                                       , SECONDARY_QUANTITY_RECEIVED
                                                       , SECONDARY_QUANTITY_ACCEPTED
                                                       , SECONDARY_QUANTITY_REJECTED
                                                       , SECONDARY_QUANTITY_CANCELLED
                                                       , VMI_FLAG
                                                       , RETROACTIVE_DATE
                                                       , SUPPLIER_ORDER_LINE_NUMBER
                                                       , AMOUNT
                                                       , AMOUNT_RECEIVED
                                                       , AMOUNT_BILLED
                                                       , AMOUNT_CANCELLED
                                                       , AMOUNT_ACCEPTED
                                                       , AMOUNT_REJECTED
                                                       , DROP_SHIP_FLAG
                                                       , SALES_ORDER_UPDATE_DATE
                                                       , SHIP_TO_LOCATION_ID
                                                       , SHIP_TO_LOCATION_NAME
                                                       , SHIP_ONE_TIME
                                                       , SHIP_TO_ADDRESS_LINE1
                                                       , SHIP_TO_ADDRESS_LINE2
                                                       , SHIP_TO_ADDRESS_LINE3
                                                       , SHIP_TO_ADDRESS_LINE4
                                                       , SHIP_TO_ADDRESS_INFO
                                                       , SHIP_TO_TOWN_OR_CITY
                                                       , SHIP_TO_POSTAL_CODE
                                                       , SHIP_TO_STATE_OR_PROVINCE
                                                       , SHIP_TO_COUNTRY
                                                       , IS_SHIPMENT_ONE_TIME_LOC
                                                       , ONE_TIME_ADDRESS_DETAILS
                                                       , DETAILS
                                                       , SHIP_CONT_PHONE
                                                       , SHIP_CONT_EMAIL
                                                       , ULTIMATE_DELIVER_CONT_PHONE
                                                       , ULTIMATE_DELIVER_CONT_EMAIL
                                                       , SHIP_CONT_NAME
                                                       , ULTIMATE_DELIVER_CONT_NAME
                                                       , SHIP_CUST_NAME
                                                       , SHIP_CUST_LOCATION
                                                       , ULTIMATE_DELIVER_CUST_NAME
                                                       , ULTIMATE_DELIVER_CUST_LOCATION
                                                       , SHIP_TO_CONTACT_FAX
                                                       , ULTIMATE_DELIVER_TO_CONT_NAME
                                                       , ULTIMATE_DELIVER_TO_CONT_FAX
                                                       , SHIPPING_METHOD
                                                       , SHIPPING_INSTRUCTIONS
                                                       , PACKING_INSTRUCTIONS
                                                       , CUSTOMER_PRODUCT_DESC
                                                       , CUSTOMER_PO_NUM
                                                       , CUSTOMER_PO_LINE_NUM
                                                       , CUSTOMER_PO_SHIPMENT_NUM
                                                       , NEED_BY_DATE
                                                       , PROMISED_DATE
                                                       , TOTAL_SHIPMENT_AMOUNT
                                                       , FINAL_MATCH_FLAG
                                                       , MANUAL_PRICE_CHANGE_FLAG
                                                       , TRANSACTION_FLOW_HEADER_ID
                                                       , VALUE_BASIS
                                                       , MATCHING_BASIS
                                                       , PAYMENT_TYPE
                                                       , DESCRIPTION
                                                       , QUANTITY_FINANCED
                                                       , AMOUNT_FINANCED
                                                       , QUANTITY_RECOUPED
                                                       , AMOUNT_RECOUPED
                                                       , RETAINAGE_WITHHELD_AMOUNT
                                                       , RETAINAGE_RELEASED_AMOUNT
                                                       , WORK_APPROVER_ID
                                                       , BID_PAYMENT_ID
                                                       , AMOUNT_SHIPPED
                                                       , DROP_SHIP_ADDRESS1
                                                       , DROP_SHIP_ADDRESS2
                                                       , DROP_SHIP_ADDRESS3
                                                       , DROP_SHIP_ADDRESS4
                                                       , DROP_SHIP_ADDRESS5
                                                       , DROP_SHIP_LOCATION
                                                       , TOTAL_SHIP_AMOUNT
                                                       , IS_LOC_LONG_TEXT
                                                        )
AS
   SELECT pll.shipment_num
        , TO_CHAR (NVL (pll.need_by_date, pll.promised_date), 'DD-MON-YYYY HH24:MI:SS') due_date
        ,
            --Added and Commented for R12 Upgrade Retrofit
          --pll.quantity,
          -- Included nvl for quantity (defect# 5933)
          NVL (pll.quantity, 0)
        , pll.price_override
        , pll.quantity_cancelled
        , pll.cancel_flag
        , TO_CHAR (pll.cancel_date, 'DD-MON-YYYY HH24:MI:SS') cancel_date
        , pll.cancel_reason
        , pll.taxable_flag
        , TO_CHAR (pll.start_date, 'DD-MON-YYYY HH24:MI:SS') start_date
        , TO_CHAR (pll.end_date, 'DD-MON-YYYY HH24:MI:SS') end_date
        , pll.attribute_category
        , pll.attribute1
        ,
          --pll.attribute2, --Commented and added for defect# 26317
          DECODE (pll.shipment_type
                , 'BLANKET', (SELECT SUM (NVL (pda.nonrecoverable_tax, 0))
                                     + SUM (NVL (pda.recoverable_tax, 0))
                              FROM   po_distributions_all pda
                              WHERE  pll.po_line_id = pda.po_line_id AND pda.po_release_id = pll.po_release_id)
                , (SELECT SUM (NVL (pda.nonrecoverable_tax, 0)) + SUM (NVL (pda.recoverable_tax, 0))
                   FROM   po_distributions_all pda
                   WHERE  pll.po_line_id = pda.po_line_id)
                 ) attribute2
        , pll.attribute3
        , pll.attribute4
        , pll.attribute5
        , pll.attribute6
        , pll.attribute7
        , pll.attribute8
        , pll.attribute9
        , pll.attribute10
        , pll.attribute11
        , pll.attribute12
        , pll.attribute13
        , pll.attribute14
        , pll.attribute15
        , pll.po_header_id
        , pl.po_line_id
        , pll.line_location_id
        , DECODE (NVL (pll.shipment_type, 'PRICE BREAK')
                , 'PRICE BREAK', 'BLANKET'
                , 'SCHEDULED', 'RELEASE'
                , 'BLANKET', 'RELEASE'
                , 'STANDARD', 'STANDARD'
                , 'PLANNED', 'PLANNED'
                , 'PREPAYMENT', 'PREPAYMENT'
                 ) shipment_type
        , pll.po_release_id
        , pll.consigned_flag
        , pll.ussgl_transaction_code
        , pll.government_context
        , pll.receiving_routing_id
        , pll.accrue_on_receipt_flag
        , pll.closed_reason
        , TO_CHAR (pll.closed_date, 'DD-MON-YYYY HH24:MI:SS') closed_date
        , pll.closed_by
        , pll.org_id
        , pll.unit_of_measure_class
        , pll.encumber_now
        , pll.inspection_required_flag
        , pll.receipt_required_flag
        , pll.qty_rcv_tolerance
        , pll.qty_rcv_exception_code
        , pll.enforce_ship_to_location_code
        , pll.allow_substitute_receipts_flag
        , pll.days_early_receipt_allowed
        , pll.days_late_receipt_allowed
        , pll.receipt_days_exception_code
        , pll.invoice_close_tolerance
        , pll.receive_close_tolerance
        , pll.ship_to_organization_id
        , pll.source_shipment_id
        , pll.closed_code
        , pll.request_id
        , pll.program_application_id
        , pll.program_id
        , pll.program_update_date
        , TO_CHAR (pll.last_accept_date, 'DD-MON-YYYY HH24:MI:SS') last_accept_date
        , pll.encumbered_flag
        , TO_CHAR (pll.encumbered_date, 'DD-MON-YYYY HH24:MI:SS') encumbered_date
        , pll.unencumbered_quantity
        , pll.fob_lookup_code
        , pll.freight_terms_lookup_code
        , TO_CHAR (pll.estimated_tax_amount, pgt.format_mask) estimated_tax_amount
        , pll.from_header_id
        , pll.from_line_id
        , pll.from_line_location_id
        , pll.lead_time
        , pll.lead_time_unit
        , pll.price_discount
        , pll.terms_id
        , pll.approved_flag
        , TO_CHAR (pll.approved_date, 'DD-MON-YYYY HH24:MI:SS') approved_date
        , pll.closed_flag
        , pll.cancelled_by
        , pll.firm_status_lookup_code
        , TO_CHAR (pll.firm_date, 'DD-MON-YYYY HH24:MI:SS') firm_date
        , TO_CHAR (pll.last_update_date, 'DD-MON-YYYY HH24:MI:SS') last_update_date
        , pll.last_updated_by
        , pll.last_update_login
        , TO_CHAR (pll.creation_date, 'DD-MON-YYYY HH24:MI:SS') creation_date
        , pll.created_by
        , pll.quantity_received
        , pll.quantity_accepted
        , pll.quantity_rejected
        , pll.quantity_billed
        , NVL (mum.unit_of_measure_tl, pll.unit_meas_lookup_code) unit_meas_lookup_code
        , pll.ship_via_lookup_code
        , pll.global_attribute_category
        , pll.global_attribute1
        , pll.global_attribute2
        , pll.global_attribute3
        , pll.global_attribute4
        , pll.global_attribute5
        , pll.global_attribute6
        , pll.global_attribute7
        , pll.global_attribute8
        , pll.global_attribute9
        , pll.global_attribute10
        , pll.global_attribute11
        , pll.global_attribute12
        , pll.global_attribute13
        , pll.global_attribute14
        , pll.global_attribute15
        , pll.global_attribute16
        , pll.global_attribute17
        , pll.global_attribute18
        , pll.global_attribute19
        , pll.global_attribute20
        , pll.quantity_shipped
        , pll.country_of_origin_code
        , pll.tax_user_override_flag
        , pll.match_option
        ,
          --zl.tax_rate_id, /* bug 8842297 */ --Commented for Defect# 26317
          pll.calculate_tax_flag
        , pll.change_promised_date_reason
        , pll.note_to_receiver
        , pll.secondary_unit_of_measure
        , pll.secondary_quantity
        , pll.preferred_grade
        , pll.secondary_quantity_received
        , pll.secondary_quantity_accepted
        , pll.secondary_quantity_rejected
        , pll.secondary_quantity_cancelled
        , pll.vmi_flag
        , TO_CHAR (pll.retroactive_date, 'DD-MON-YYYY HH24:MI:SS') retroactive_date
        , pll.supplier_order_line_number
        , TO_CHAR (po_core_s.get_total ('S', pll.line_location_id), pgt.format_mask) amount
        , TO_CHAR (pll.amount_received, pgt.format_mask) amount_received
        , TO_CHAR (pll.amount_billed, pgt.format_mask) amount_billed
        , TO_CHAR (pll.amount_cancelled, pgt.format_mask) amount_cancelled
        , TO_CHAR (pll.amount_accepted, pgt.format_mask) amount_accepted
        , TO_CHAR (pll.amount_rejected, pgt.format_mask) amount_rejected
        , pll.drop_ship_flag
        , TO_CHAR (pll.sales_order_update_date, 'DD-MON-YYYY HH24:MI:SS') sales_order_update_date
        , DECODE (NVL (pll.ship_to_location_id, -1)
                , -1, NULL
                , po_communication_pvt.getlocationinfo (pll.ship_to_location_id)
                 ) ship_to_location_id
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getlocationname ())
                                                                                        ship_to_location_name
        ,
          --Added for R12 Upgrade Retrofit
          DECODE (NVL (po_communication_pvt.getlocationname, 'x')
                , 'OD US ONE TIME SHIP TO LOCATION', 1
                , 'OD CA ONE TIME SHIP TO LOCATION', 1
                , 0
                 ) ship_one_time
        ,
          --end
          DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline1 ())
                                                                                        ship_to_address_line1
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline2 ())
                                                                                        ship_to_address_line2
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline3 ())
                                                                                        ship_to_address_line3
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline4 ())
                                                                                        ship_to_address_line4
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressinfo ())
                                                                                         ship_to_address_info
        ,
          --Added for R12 Upgrade Retrofit
          DECODE (NVL (ph.ship_to_location_id, -1)
                , NVL (pll.ship_to_location_id, -1), NULL
                , (DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.gettownorcity ())
                  )
                 ) ship_to_town_or_city
        , DECODE (NVL (ph.ship_to_location_id, -1)
                , NVL (pll.ship_to_location_id, -1), NULL
                , (DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getpostalcode ())
                  )
                 ) ship_to_postal_code
        , DECODE (NVL (ph.ship_to_location_id, -1)
                , NVL (pll.ship_to_location_id, -1), NULL
                , (DECODE (NVL (pll.ship_to_location_id, -1)
                         , -1, NULL
                         , po_communication_pvt.getstateorprovince ()
                          )
                  )
                 ) ship_to_state_or_province
        ,
          --end
          DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getterritoryshortname ())
                                                                                              ship_to_country
        , DECODE (NVL (pll.ship_to_location_id, -1)
                , -1, NULL
                , po_communication_pvt.get_onetime_loc (pll.ship_to_location_id)
                 ) is_shipment_one_time_loc
        , DECODE (NVL (pll.ship_to_location_id, -1)
                , -1, NULL
                , po_communication_pvt.get_onetime_address (pll.line_location_id)
                 ) one_time_address_details
        , DECODE (pll.drop_ship_flag
                , 'Y', po_communication_pvt.get_drop_ship_details (pll.line_location_id)
                , NULL
                 ) details
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontphone (), NULL) ship_cont_phone
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontemail (), NULL) ship_cont_email
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontphone (), NULL)
                                                                                  ultimate_deliver_cont_phone
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontemail (), NULL)
                                                                                  ultimate_deliver_cont_email
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontname (), NULL) ship_cont_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontname (), NULL)
                                                                                   ultimate_deliver_cont_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcustname (), NULL) ship_cust_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcustlocation (), NULL)
                                                                                           ship_cust_location
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercustname (), NULL)
                                                                                   ultimate_deliver_cust_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercustlocation (), NULL)
                                                                               ultimate_deliver_cust_location
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontactfax (), NULL)
                                                                                          ship_to_contact_fax
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontactname (), NULL)
                                                                                ultimate_deliver_to_cont_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontactfax (), NULL)
                                                                                 ultimate_deliver_to_cont_fax
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshippingmethod (), NULL) shipping_method
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshippinginstructions (), NULL)
                                                                                        shipping_instructions
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getpackinginstructions (), NULL)
                                                                                         packing_instructions
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerproductdesc (), NULL)
                                                                                        customer_product_desc
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerponumber (), NULL) customer_po_num
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerpolinenum (), NULL)
                                                                                         customer_po_line_num
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerposhipmentnum (), NULL)
                                                                                     customer_po_shipment_num
        , TO_CHAR (pll.need_by_date, 'DD-MON-YYYY HH24:MI:SS') need_by_date
        , TO_CHAR (pll.promised_date, 'DD-MON-YYYY HH24:MI:SS') promised_date
        , TO_CHAR (pll.amount, pgt.format_mask) total_shipment_amount
        , pll.final_match_flag
        , pll.manual_price_change_flag
        ,
          --zl.tax_rate_code, /* bug 8842297 */ --Commented for Defect# 26317
          pll.transaction_flow_header_id
        , pll.value_basis
        , pll.matching_basis
        , pll.payment_type
        , pll.description
        , pll.quantity_financed
        , TO_CHAR (pll.amount_financed, pgt.format_mask) amount_financed
        , pll.quantity_recouped
        , TO_CHAR (pll.amount_recouped, pgt.format_mask) amount_recouped
        , TO_CHAR (pll.retainage_withheld_amount, pgt.format_mask) retainage_withheld_amount
        , TO_CHAR (pll.retainage_released_amount, pgt.format_mask) retainage_released_amount
        , pll.work_approver_id
        , pll.bid_payment_id
        , TO_CHAR (pll.amount_shipped, pgt.format_mask) amount_shipped
/*        ,
          --Added for R12 Upgrade Retrofit
          drop_ship.ship_to_address1 AS drop_ship_address1
        , drop_ship.ship_to_address2 AS drop_ship_address2
        , drop_ship.ship_to_address3 AS drop_ship_address3
        , drop_ship.ship_to_address4 AS drop_ship_address4
        , drop_ship.ship_to_address5 AS drop_ship_address5
        , drop_ship.ship_to_location AS drop_ship_location*/ --Commented by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        ,
          --Added for R12 Upgrade Retrofit
          NULL drop_ship_address1 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address2 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address3 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address4 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address5 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_location --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        ,
          -- Included nvl for quantity (defect# 5933)
          TO_CHAR (DECODE (NVL (pll.cancel_flag, 'N')
                         , 'N', NVL (pll.price_override, 0) * NVL (pll.quantity, 0)
                         , 0
                          )
                 , pgt.format_mask
                  ) AS total_ship_amount
        , (SELECT COUNT (1)
           FROM   fnd_attached_docs_form_vl fad, fnd_documents_long_text fds, po_line_locations_all pllx
           WHERE  entity_name = 'PO_SHIPMENTS'
           AND    pk1_value = pllx.line_location_id
           AND    function_name = 'PO_PRINTPO'
           AND    fad.media_id = fds.media_id
           AND    pllx.po_header_id = pll.po_header_id
           AND    pllx.line_location_id = pll.line_location_id
           AND    pllx.po_line_id = pll.po_line_id) AS is_loc_long_text
   --end
   FROM   po_line_locations_all pll
        , po_lines_all pl
        , po_communication_gt pgt
        , mtl_units_of_measure_tl mum
        ,
            --zx_lines zl, /* bug 8842297 */--Commented for Defect# 26317
          --Added for R12 Upgrade Retrofit
          -- (SELECT ship_to_location_id, po_header_id -- Commented for Defect 28601
               -- FROM po_headers_all) ph, -- Commented for Defect 28601
          po_headers_all ph
/*        ,                                                                          -- Changes for defect 28601
          (SELECT line_id
                , ship_to_address1
                , ship_to_address2
                , ship_to_address3
                , ship_to_address4
                , ship_to_address5
                , ship_to_location
           FROM   oe_order_lines_v
           WHERE  line_id IN (SELECT line_id
                              FROM   oe_drop_ship_sources)) drop_ship*/ --Commented by Rohit Nanda on 11-MAY-2017 for Defect- 42218
   --end
   WHERE  pll.po_line_id(+) = pl.po_line_id                         /* bug 8842297 */
                              /*AND pll.po_header_id = zl.trx_id
                              AND pll.line_location_id = zl.trx_line_id
                              AND zl.application_id = 201
                              AND zl.entity_code = 'PURCHASE_ORDER'
                              AND zl.event_class_code = 'PO_PA' /* bug 8842297 */
                                                                                 --Commented for Defect# 26317
   AND    (pll.shipment_type(+) <> 'BLANKET' AND pgt.po_release_id IS NULL)
   AND    pll.unit_meas_lookup_code = mum.unit_of_measure(+)
   AND    mum.LANGUAGE(+) = USERENV ('LANG')
   --Added for R12 Upgrade Retrofit
   AND    ph.po_header_id = pl.po_header_id(+)
--   AND    drop_ship.line_id(+) = pl.po_line_id --Commented by Rohit Nanda on 11-MAY-2017 for Defect- 42218
   --end
   UNION
   SELECT pll.shipment_num
        , TO_CHAR (NVL (pll.need_by_date, pll.promised_date), 'DD-MON-YYYY HH24:MI:SS') due_date
        ,
            --Added and Commented for R12 Upgrade Retrofit
          --pll.quantity,
          -- Included nvl for quantity (defect# 5933)
          NVL (pll.quantity, 0)
        , pll.price_override
        , pll.quantity_cancelled
        , pll.cancel_flag
        , TO_CHAR (pll.cancel_date, 'DD-MON-YYYY HH24:MI:SS') cancel_date
        , pll.cancel_reason
        , pll.taxable_flag
        , TO_CHAR (pll.start_date, 'DD-MON-YYYY HH24:MI:SS') start_date
        , TO_CHAR (pll.end_date, 'DD-MON-YYYY HH24:MI:SS') end_date
        , pll.attribute_category
        , pll.attribute1
        ,
          --pll.attribute2, --Commented and added for defect# 26317
          DECODE (pll.shipment_type
                , 'BLANKET', (SELECT SUM (NVL (pda.nonrecoverable_tax, 0))
                                     + SUM (NVL (pda.recoverable_tax, 0))
                              FROM   po_distributions_all pda
                              WHERE  pll.po_line_id = pda.po_line_id AND pda.po_release_id = pll.po_release_id)
                , (SELECT SUM (NVL (pda.nonrecoverable_tax, 0)) + SUM (NVL (pda.recoverable_tax, 0))
                   FROM   po_distributions_all pda
                   WHERE  pll.po_line_id = pda.po_line_id)
                 ) attribute2
        , pll.attribute3
        , pll.attribute4
        , pll.attribute5
        , pll.attribute6
        , pll.attribute7
        , pll.attribute8
        , pll.attribute9
        , pll.attribute10
        , pll.attribute11
        , pll.attribute12
        , pll.attribute13
        , pll.attribute14
        , pll.attribute15
        , pll.po_header_id
        , pl.po_line_id
        , pll.line_location_id
        , DECODE (pll.shipment_type
                , 'PRICE BREAK', 'BLANKET'
                , 'SCHEDULED', 'RELEASE'
                , 'BLANKET', 'RELEASE'
                , 'STANDARD', 'STANDARD'
                , 'PLANNED', 'PLANNED'
                , 'PREPAYMENT', 'PREPAYMENT'
                 ) shipment_type
        , pll.po_release_id
        , pll.consigned_flag
        , pll.ussgl_transaction_code
        , pll.government_context
        , pll.receiving_routing_id
        , pll.accrue_on_receipt_flag
        , pll.closed_reason
        , TO_CHAR (pll.closed_date, 'DD-MON-YYYY HH24:MI:SS') closed_date
        , pll.closed_by
        , pll.org_id
        , pll.unit_of_measure_class
        , pll.encumber_now
        , pll.inspection_required_flag
        , pll.receipt_required_flag
        , pll.qty_rcv_tolerance
        , pll.qty_rcv_exception_code
        , pll.enforce_ship_to_location_code
        , pll.allow_substitute_receipts_flag
        , pll.days_early_receipt_allowed
        , pll.days_late_receipt_allowed
        , pll.receipt_days_exception_code
        , pll.invoice_close_tolerance
        , pll.receive_close_tolerance
        , pll.ship_to_organization_id
        , pll.source_shipment_id
        , pll.closed_code
        , pll.request_id
        , pll.program_application_id
        , pll.program_id
        , pll.program_update_date
        , TO_CHAR (pll.last_accept_date, 'DD-MON-YYYY HH24:MI:SS') last_accept_date
        , pll.encumbered_flag
        , TO_CHAR (pll.encumbered_date, 'DD-MON-YYYY HH24:MI:SS') encumbered_date
        , pll.unencumbered_quantity
        , pll.fob_lookup_code
        , pll.freight_terms_lookup_code
        , TO_CHAR (pll.estimated_tax_amount, pgt.format_mask) estimated_tax_amount
        , pll.from_header_id
        , pll.from_line_id
        , pll.from_line_location_id
        , pll.lead_time
        , pll.lead_time_unit
        , pll.price_discount
        , pll.terms_id
        , pll.approved_flag
        , TO_CHAR (pll.approved_date, 'DD-MON-YYYY HH24:MI:SS') approved_date
        , pll.closed_flag
        , pll.cancelled_by
        , pll.firm_status_lookup_code
        , TO_CHAR (pll.firm_date, 'DD-MON-YYYY HH24:MI:SS') firm_date
        , TO_CHAR (pll.last_update_date, 'DD-MON-YYYY HH24:MI:SS') last_update_date
        , pll.last_updated_by
        , pll.last_update_login
        , TO_CHAR (pll.creation_date, 'DD-MON-YYYY HH24:MI:SS') creation_date
        , pll.created_by
        , pll.quantity_received
        , pll.quantity_accepted
        , pll.quantity_rejected
        , pll.quantity_billed
        , NVL (mum.unit_of_measure_tl, pll.unit_meas_lookup_code) unit_meas_lookup_code
        , pll.ship_via_lookup_code
        , pll.global_attribute_category
        , pll.global_attribute1
        , pll.global_attribute2
        , pll.global_attribute3
        , pll.global_attribute4
        , pll.global_attribute5
        , pll.global_attribute6
        , pll.global_attribute7
        , pll.global_attribute8
        , pll.global_attribute9
        , pll.global_attribute10
        , pll.global_attribute11
        , pll.global_attribute12
        , pll.global_attribute13
        , pll.global_attribute14
        , pll.global_attribute15
        , pll.global_attribute16
        , pll.global_attribute17
        , pll.global_attribute18
        , pll.global_attribute19
        , pll.global_attribute20
        , pll.quantity_shipped
        , pll.country_of_origin_code
        , pll.tax_user_override_flag
        , pll.match_option
        ,
          --zl.tax_rate_id, /* bug 8842297 */ --Commented for Defect# 26317
          pll.calculate_tax_flag
        , pll.change_promised_date_reason
        , pll.note_to_receiver
        , pll.secondary_unit_of_measure
        , pll.secondary_quantity
        , pll.preferred_grade
        , pll.secondary_quantity_received
        , pll.secondary_quantity_accepted
        , pll.secondary_quantity_rejected
        , pll.secondary_quantity_cancelled
        , pll.vmi_flag
        , TO_CHAR (pll.retroactive_date, 'DD-MON-YYYY HH24:MI:SS') retroactive_date
        , pll.supplier_order_line_number
        , TO_CHAR (po_core_s.get_total ('S', pll.line_location_id), pgt.format_mask) amount
        , TO_CHAR (pll.amount_received, pgt.format_mask) amount_received
        , TO_CHAR (pll.amount_billed, pgt.format_mask) amount_billed
        , TO_CHAR (pll.amount_cancelled, pgt.format_mask) amount_cancelled
        , TO_CHAR (pll.amount_accepted, pgt.format_mask) amount_accepted
        , TO_CHAR (pll.amount_rejected, pgt.format_mask) amount_rejected
        , pll.drop_ship_flag
        , TO_CHAR (pll.sales_order_update_date, 'DD-MON-YYYY HH24:MI:SS') sales_order_update_date
        , DECODE (NVL (pll.ship_to_location_id, -1)
                , -1, NULL
                , po_communication_pvt.getlocationinfo (pll.ship_to_location_id)
                 ) ship_to_location_id
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getlocationname ())
                                                                                        ship_to_location_name
        ,
          -- Added for R12 Upgrade Retrofit
          DECODE (NVL (po_communication_pvt.getlocationname, 'x')
                , 'OD US ONE TIME SHIP TO LOCATION', 1
                , 'OD CA ONE TIME SHIP TO LOCATION', 1
                , 0
                 ) ship_one_time
        ,
          --end
          DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline1 ())
                                                                                        ship_to_address_line1
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline2 ())
                                                                                        ship_to_address_line2
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline3 ())
                                                                                        ship_to_address_line3
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressline4 ())
                                                                                        ship_to_address_line4
        , DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getaddressinfo ())
                                                                                         ship_to_address_info
        ,
          -- Added for R12 Upgrade Retrofit
          DECODE (NVL (ph.ship_to_location_id, -1)
                , NVL (pll.ship_to_location_id, -1), NULL
                , (DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.gettownorcity ())
                  )
                 ) ship_to_town_or_city
        , DECODE (NVL (ph.ship_to_location_id, -1)
                , NVL (pll.ship_to_location_id, -1), NULL
                , (DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getpostalcode ())
                  )
                 ) ship_to_postal_code
        , DECODE (NVL (ph.ship_to_location_id, -1)
                , NVL (pll.ship_to_location_id, -1), NULL
                , (DECODE (NVL (pll.ship_to_location_id, -1)
                         , -1, NULL
                         , po_communication_pvt.getstateorprovince ()
                          )
                  )
                 ) ship_to_state_or_province
        ,
          -- end
          DECODE (NVL (pll.ship_to_location_id, -1), -1, NULL, po_communication_pvt.getterritoryshortname ())
                                                                                              ship_to_country
        , DECODE (NVL (pll.ship_to_location_id, -1)
                , -1, NULL
                , po_communication_pvt.get_onetime_loc (pll.ship_to_location_id)
                 ) is_shipment_one_time_loc
        , DECODE (NVL (pll.ship_to_location_id, -1)
                , -1, NULL
                , po_communication_pvt.get_onetime_address (pll.line_location_id)
                 ) one_time_address_details
        , DECODE (pll.drop_ship_flag
                , 'Y', po_communication_pvt.get_drop_ship_details (pll.line_location_id)
                , NULL
                 ) details
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontphone (), NULL) ship_cont_phone
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontemail (), NULL) ship_cont_email
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontphone (), NULL)
                                                                                  ultimate_deliver_cont_phone
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontemail (), NULL)
                                                                                  ultimate_deliver_cont_email
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontname (), NULL) ship_cont_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontname (), NULL)
                                                                                   ultimate_deliver_cont_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcustname (), NULL) ship_cust_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcustlocation (), NULL)
                                                                                           ship_cust_location
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercustname (), NULL)
                                                                                   ultimate_deliver_cust_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercustlocation (), NULL)
                                                                               ultimate_deliver_cust_location
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshipcontactfax (), NULL)
                                                                                          ship_to_contact_fax
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontactname (), NULL)
                                                                                ultimate_deliver_to_cont_name
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getdelivercontactfax (), NULL)
                                                                                 ultimate_deliver_to_cont_fax
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshippingmethod (), NULL) shipping_method
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getshippinginstructions (), NULL)
                                                                                        shipping_instructions
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getpackinginstructions (), NULL)
                                                                                         packing_instructions
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerproductdesc (), NULL)
                                                                                        customer_product_desc
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerponumber (), NULL) customer_po_num
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerpolinenum (), NULL)
                                                                                         customer_po_line_num
        , DECODE (pll.drop_ship_flag, 'Y', po_communication_pvt.getcustomerposhipmentnum (), NULL)
                                                                                     customer_po_shipment_num
        , TO_CHAR (pll.need_by_date, 'DD-MON-YYYY HH24:MI:SS') need_by_date
        , TO_CHAR (pll.promised_date, 'DD-MON-YYYY HH24:MI:SS') promised_date
        , TO_CHAR (pll.amount, pgt.format_mask) total_shipment_amount
        , pll.final_match_flag
        , pll.manual_price_change_flag
        ,
          --zl.tax_rate_code, /* bug 8842297 */ --Commented for Defect# 26317
          pll.transaction_flow_header_id
        , pll.value_basis
        , pll.matching_basis
        , pll.payment_type
        , pll.description
        , pll.quantity_financed
        , TO_CHAR (pll.amount_financed, pgt.format_mask) amount_financed
        , pll.quantity_recouped
        , TO_CHAR (pll.amount_recouped, pgt.format_mask) amount_recouped
        , TO_CHAR (pll.retainage_withheld_amount, pgt.format_mask) retainage_withheld_amount
        , TO_CHAR (pll.retainage_released_amount, pgt.format_mask) retainage_released_amount
        , pll.work_approver_id
        , pll.bid_payment_id
        , TO_CHAR (pll.amount_shipped, pgt.format_mask) amount_shipped
        /*,
          --Added for R12 Upgrade Retrofit
          drop_ship.ship_to_address1 AS drop_ship_address1
        , drop_ship.ship_to_address2 AS drop_ship_address2
        , drop_ship.ship_to_address3 AS drop_ship_address3
        , drop_ship.ship_to_address4 AS drop_ship_address4
        , drop_ship.ship_to_address5 AS drop_ship_address5
        , drop_ship.ship_to_location AS drop_ship_location*/ --Commented by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        ,
          --Added for R12 Upgrade Retrofit
          NULL drop_ship_address1 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address2 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address3 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address4 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_address5 --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        , NULL drop_ship_location --Added by Rohit Nanda on 11-MAY-2017 for Defect- 42218
        ,
          -- Included nvl for quantity (defect# 5933)
          TO_CHAR (DECODE (NVL (pll.cancel_flag, 'N')
                         , 'N', NVL (pll.price_override, 0) * NVL (pll.quantity, 0)
                         , 0
                          )
                 , pgt.format_mask
                  ) AS total_ship_amount
        , (SELECT COUNT (1)
           FROM   fnd_attached_docs_form_vl fad, fnd_documents_long_text fds, po_line_locations_all pllx
           WHERE  entity_name = 'PO_SHIPMENTS'
           AND    pk1_value = pllx.line_location_id
           AND    function_name = 'PO_PRINTPO'
           AND    fad.media_id = fds.media_id
           AND    pllx.po_header_id = pll.po_header_id
           AND    pllx.line_location_id = pll.line_location_id
           AND    pllx.po_line_id = pll.po_line_id) AS is_loc_long_text
   -- end
   FROM   po_line_locations_all pll
        , po_lines_all pl
        , po_communication_gt pgt
        , mtl_units_of_measure_tl mum
        ,
            --zx_lines zl, /* bug 8842297 */ --Commented for Defect# 26317
          --Added for R12 Upgrade Retrofit
          -- (SELECT ship_to_location_id, po_header_id -- Commented for defect 28601
               -- FROM po_headers_all) ph, -- Commented for defect 28601
          po_headers_all ph
        /*,                                                                          -- Changes for defect 28601
          (SELECT line_id
                , ship_to_address1
                , ship_to_address2
                , ship_to_address3
                , ship_to_address4
                , ship_to_address5
                , ship_to_location
           FROM   oe_order_lines_v
           WHERE  line_id IN (SELECT line_id
                              FROM   oe_drop_ship_sources)) drop_ship*/  --Commented by Rohit Nanda on 11-MAY-2017 for Defect- 42218
   --end
   WHERE  pll.po_line_id(+) = pl.po_line_id                        /* bug 8842297 */
                             /*AND pll.po_header_id = zl.trx_id
                             AND pll.line_location_id = zl.trx_line_id
                             AND zl.application_id = 201
                             AND zl.entity_code = 'PURCHASE_ORDER'
                             AND zl.event_class_code = 'PO_PA' /* bug 8842297 */ --Commented for Defect# 26317
   AND    (pll.shipment_type(+) = 'BLANKET' AND pgt.po_release_id IS NOT NULL)
   AND    pll.unit_meas_lookup_code = mum.unit_of_measure(+)
   AND    mum.LANGUAGE(+) = USERENV ('LANG')
   --Added for R12 Upgrade Retrofit
   AND    ph.po_header_id = pl.po_header_id(+);
--   AND    drop_ship.line_id(+) = pl.po_line_id --Commented by Rohit Nanda on 11-MAY-2017 for Defect- 42218


/
SHOW ERRORS;

EXIT;