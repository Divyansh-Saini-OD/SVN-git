SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
 
SET TERM ON
 
PROMPT Creating views for OD Vendor Site KFF Attributes
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                                               |
-- +===================================================================+
-- |Name  :  Create    XX_PO_VENDOR_SITES_KFF_V                        |
-- |Description      :   This view is used to create custom attributes |
-- |                     for the oD vendor site KFF                    |
-- |Change Record:                                                     |
-- |==============                                                     |
-- |Version   Date        Author            Remarks                    |
-- |=======   ==========  ================  ===========================|
-- |                                                                   |
-- |V1.0     06-Mar-2018  Sunil Kalal       View updated for four      |
-- |                                        additional attibutes for   |
-- |                                        RMS PI PACK. Attributes    |
-- |                                        are as follows:            |
-- |                                        OD_CONTRACT_SIGNATURE      |
-- |                                        OD_CONTRACT_TITLE          |
-- |                                        OD_VENDOR_SIGNATURE_NAME   | 
-- |                                        OD_VENDOR_SIGNATURE_TITLE  | 
-- +===================================================================+

  CREATE OR REPLACE FORCE EDITIONABLE VIEW  "XX_PO_VENDOR_SITES_KFF_V" ("VENDOR_SITE_ID", "LEAD_TIME", "BACK_ORDER_FLAG", "DELIVERY_POLICY", "MIN_PREPAID_CODE", "VENDOR_MIN_AMOUNT", "SUPPLIER_SHIP_TO", "INVENTORY_TYPE_CODE", "VERTICAL_MARKET_INDICATOR", "ALLOW_AUTO_RECEIPT", "HANDLING", "EFT_SETTLE_DAYS", "SPLIT_FILE_FLAG", "MASTER_VENDOR_ID", "PI_PACK_YEAR", "OD_DATE_SIGNED", "VENDOR_DATE_SIGNED", "DEDUCT_FROM_INVOICE_FLAG", "MIN_BUS_CATEGORY", "COMBINE_PICK_TICKET", "NEW_STORE_FLAG", "NEW_STORE_TERMS", "SEASONAL_FLAG", "START_DATE", "END_DATE", "SEASONAL_TERMS", "LATE_SHIP_FLAG", "850_PO", "860_PO_CHANGE", "855_CONFIRM_PO", "856_ASN", "846_AVAILABILITY", "810_INVOICE", "832_PRICE_SALES_CAT", "820_EFT", "861_DAMAGE_SHORTAGE", "852_SALES", "EDI_DISTRIBUTION_CODE", "OD_CONTRACT_SIGNATURE", "OD_CONTRACT_TITLE", "RTV_OPTION", "RTV_FREIGHT_PAYMENT_METHOD", "PERMANENT_RGA", "DESTROY_ALLOW_AMOUNT", "PAYMENT_FREQUENCY", "MIN_RETURN_QTY", "MIN_RETURN_AMOUNT", "DAMAGE_DESTROY_LIMIT", "RTV_INSTRUCTIONS", "ADDL_RTV_INSTRUCTIONS", "RGA_MARKED_FLAG", "REMOVE_PRICE_STICKER_FLAG", "CONTACT_SUPPLIER_FOR_RGA_FLAG", "DESTROY_FLAG", "SERIAL_NUM_REQUIRED_FLAG", "OBSOLETE_ITEM", "OBSOLETE_ALLOWANCE_PCT", "OBSOLETE_ALLOWANCE_DAYS", "RTV_RELATED_SITE", "OD_VENDOR_SIGNATURE_NAME", "OD_VENDOR_SIGNATURE_TITLE", "BLANK61", "BLANK62", "BLANK63", "BLANK64", "BLANK65", "BLANK66", "BLANK67", "BLANK68", "BLANK69", "BLANK70", "BLANK71", "BLANK72", "BLANK73", "BLANK74", "BLANK75", "BLANK76", "BLANK77", "BLANK78", "BLANK79", "BLANK80", "BLANK81", "BLANK82", "BLANK83", "BLANK84", "BLANK85", "BLANK86", "BLANK87", "BLANK88", "BLANK89", "MANUFACTURING_SITE_ID", "BUYING_AGENT_SITE_ID", "FREIGHT_FORWARDER_SITE_ID", "SHIP_FROM_PORT_ID", "BLANK94", "BLANK95", "BLANK96", "BLANK97", "BLANK98", "BLANK99", "BLANK100") AS 
  SELECT pvsa1.vendor_site_id
        , xpvsk1.segment1 lead_time
        , xpvsk1.segment2 back_order_flag
        , xpvsk1.segment3 delivery_policy
        , xpvsk1.segment4 min_prepaid_code
        , xpvsk1.segment5 vendor_min_amount
        , xpvsk1.segment6 supplier_ship_to
        , xpvsk1.segment7 inventory_type_code
        , xpvsk1.segment8 vertical_market_indicator
        , xpvsk1.segment9 allow_auto_receipt
        , xpvsk1.segment10 handling
        , xpvsk1.segment11 eft_settle_days
        , xpvsk1.segment12 split_file_flag
        , xpvsk1.segment13 master_vendor_id
        , xpvsk1.segment14 pi_pack_year
        , xpvsk1.segment15 od_date_signed
        , xpvsk1.segment16 vendor_date_signed
        , xpvsk1.segment17 deduct_from_invoice_flag
        , xpvsk1.segment18 min_bus_category
        , xpvsk1.segment19 combine_pick_ticket
        , xpvsk2.segment20 new_store_flag
        , xpvsk2.segment21 new_store_terms
        , xpvsk2.segment22 seasonal_flag
        , xpvsk2.segment23 start_date
        , xpvsk2.segment24 end_date
        , xpvsk2.segment25 seasonal_terms
        , xpvsk2.segment26 late_ship_flag
        , xpvsk2.segment27 "850_PO"
        , xpvsk2.segment28 "860_PO_CHANGE"
        , xpvsk2.segment29 "855_CONFIRM_PO"
        , xpvsk2.segment30 "856_ASN"
        , xpvsk2.segment31 "846_AVAILABILITY"
        , xpvsk2.segment32 "810_INVOICE"
        , xpvsk2.segment33 "832_PRICE_SALES_CAT"
        , xpvsk2.segment34 "820_EFT"
        , xpvsk2.segment35 "861_DAMAGE_SHORTAGE"
        , xpvsk2.segment36 "852_SALES"
        , xpvsk2.segment37 edi_distribution_code
        , xpvsk1.segment38 od_contract_signature
        , xpvsk1.segment39 od_contract_title
        , xpvsk3.segment40 rtv_option
        , xpvsk3.segment41 rtv_freight_payment_method
        , xpvsk3.segment42 permanent_rga
        , xpvsk3.segment43 destroy_allow_amount
        , xpvsk3.segment44 payment_frequency
        , xpvsk3.segment45 min_return_qty
        , xpvsk3.segment46 min_return_amount
        , xpvsk3.segment47 damage_destroy_limit
        , xpvsk3.segment48 rtv_instructions
        , xpvsk3.segment49 addl_rtv_instructions
        , xpvsk3.segment50 rga_marked_flag
        , xpvsk3.segment51 remove_price_sticker_flag
        , xpvsk3.segment52 contact_supplier_for_rga_flag
        , xpvsk3.segment53 destroy_flag
        , xpvsk3.segment54 serial_num_required_flag
        , xpvsk3.segment55 obsolete_item
        , xpvsk3.segment56 obsolete_allowance_pct
        , xpvsk3.segment57 obsolete_allowance_days
        , xpvsk3.segment58 rtv_related_site
        , xpvsk1.segment59 od_vendor_signature_name
        , xpvsk1.segment60 od_vendor_signature_title
        , xpvsk3.segment61 blank61
        , xpvsk3.segment62 blank62
        , xpvsk3.segment63 blank63
        , xpvsk3.segment64 blank64
        , xpvsk3.segment65 blank65
        , xpvsk3.segment66 blank66
        , xpvsk3.segment67 blank67
        , xpvsk3.segment68 blank68
        , xpvsk3.segment69 blank69
        , xpvsk3.segment70 blank70
        , xpvsk3.segment71 blank71
        , xpvsk3.segment72 blank72
        , xpvsk3.segment73 blank73
        , xpvsk3.segment74 blank74
        , xpvsk3.segment75 blank75
        , xpvsk3.segment76 blank76
        , xpvsk3.segment77 blank77
        , xpvsk3.segment78 blank78
        , xpvsk3.segment79 blank79
        , xpvsk3.segment80 blank80
        , xpvsk3.segment81 blank81
        , xpvsk3.segment82 blank82
        , xpvsk3.segment83 blank83
        , xpvsk3.segment84 blank84
        , xpvsk3.segment85 blank85
        , xpvsk3.segment86 blank86
        , xpvsk3.segment87 blank87
        , xpvsk3.segment88 blank88
        , xpvsk3.segment89 blank89
        , xpvsk4.segment90 manufacturing_site_id
        , xpvsk4.segment91 buying_agent_site_id
        , xpvsk4.segment92 freight_forwarder_site_id
        , xpvsk4.segment93 ship_from_port_id
        , xpvsk4.segment94 blank94
        , xpvsk4.segment95 blank95
        , xpvsk4.segment96 blank96
        , xpvsk4.segment97 blank97
        , xpvsk4.segment98 blank98
        , xpvsk4.segment99 blank99
        , xpvsk4.segment100 blank100
     FROM xx_po_vendor_sites_kff xpvsk1
        , xx_po_vendor_sites_kff xpvsk2
        , xx_po_vendor_sites_kff xpvsk3
        , xx_po_vendor_sites_kff xpvsk4
       -- Start -- Replacing these table with the new tables as part of OD R12 Upgrade -- Vamshi Katta - 24-Jul-2013
       -- , po_vendor_sites_all pvsa1
       -- , po_vendor_sites_all pvsa2
       -- , po_vendor_sites_all pvsa3
       -- , po_vendor_sites_all pvsa4
       -- End  -- Replacing these table with the new tables as part of OD R12 Upgrade -- Vamshi Katta - 24-Jul-2013
       -- Start  -- New tables as part of OD R12 Upgrade -- Vamshi Katta - 24-Jul-2013
       	, ap_supplier_sites_all pvsa1
       	, ap_supplier_sites_all pvsa2
       	, ap_supplier_sites_all pvsa3
       	, ap_supplier_sites_all pvsa4
       -- End  -- New tables as part of OD R12 Upgrade -- Vamshi Katta - 24-Jul-2013
    WHERE pvsa1.attribute10 = xpvsk1.vs_kff_id(+)
      AND pvsa2.ROWID = pvsa1.ROWID
      AND pvsa2.attribute11 = xpvsk2.vs_kff_id(+)
      AND pvsa3.ROWID = pvsa1.ROWID
      AND pvsa3.attribute12 = xpvsk3.vs_kff_id(+)
      AND pvsa4.ROWID = pvsa1.ROWID
      AND pvsa4.attribute15 = xpvsk4.vs_kff_id(+);

SHOW ERROR