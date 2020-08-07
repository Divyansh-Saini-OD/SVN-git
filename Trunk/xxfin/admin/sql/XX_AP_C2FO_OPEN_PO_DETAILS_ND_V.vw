---+========================================================================================================+        
---|                                        Office Depot - C2FO                                             |
---+========================================================================================================+
---|    Application             :       AP                                                                  |
---|                                                                                                        |
---|    Name                    :       XX_AP_C2FO_OP_PO_DETAILS_ND_V.vw                                    |
---|                                                                                                        |
---|    Description             :                                                                           |
---|                                                                                                        |
---|                                                                                                        |
---|                                                                                                        |
---|    Change Record                                                                                       |
---|    ---------------------------------                                                                   |
---|    Version         DATE              AUTHOR             DESCRIPTION                                    |
---|    ------------    ----------------- ---------------    ---------------------                          |
---|    1.0             31-AUG-2018       Antonio Morales    Initial Version                                |
---|                                                                                                        |
---+========================================================================================================+
--indeitfier too long XX_AP_C2FO_OPEN_PO_DETAILS_ND_V -- takes 10 minutes in DEV02 
CREATE OR REPLACE VIEW XX_AP_C2FO_OP_PO_DETAILS_ND_V AS 
SELECT
     replace(replace(sup.segment1|| '|' || assa.vendor_site_code,',',''),'"','') AS company_id,   --concatenation to get a unique ORGANIZATION for each vendor/site combination
     NULL AS division_id,
     ( pha.org_id|| '|' || sup.vendor_id|| '|' || assa.vendor_site_id|| '|' || pha.po_header_id ) AS po_id,
     ( SELECT nvl(SUM(pla.quantity * pla.unit_price),0) FROM po.po_lines_all pla WHERE 1 = 1 AND pla.po_header_id = pha.po_header_id ) AS amount,
     pha.currency_code       AS currency,
     TO_CHAR(pha.creation_date,'YYYY-MM-DD') AS create_date,
     TO_CHAR(pha.approved_date,'YYYY-MM-DD') AS approved_date,
     (SELECT
             MIN(TO_CHAR(rsh.shipped_date,'YYYY-MM-DD') )
         FROM
             rcv_transactions rct,
             rcv_shipment_headers rsh,
             rcv_shipment_lines rsl,
             po_lines_all pol,
             po_line_locations_all pll,
             po_headers_all ph,
             hr_all_organization_units haou1
         WHERE
             1 = 1
             AND rct.po_header_id = ph.po_header_id
             AND rct.po_line_location_id = pll.line_location_id
             AND rct.po_line_id = pol.po_line_id
             AND rct.shipment_line_id = rsl.shipment_line_id
             AND rsl.shipment_header_id = rsh.shipment_header_id
             AND rsh.ship_to_org_id = haou1.organization_id
             AND ph.po_header_id = pha.po_header_id
             AND ph.vendor_id = pha.vendor_id
             AND ph.vendor_site_id = pha.vendor_site_id
             AND haou1.organization_id = pha.org_id ) AS ship_date,
     ( hl1.country|| '|' || ( SELECT hg.geography_name FROM hz_geographies hg WHERE hg.geography_type = 'COUNTRY' AND hg.country_code = hl1.country) ) AS ship_orig_country,
     hl1.region_2            AS ship_orig_state,
     (SELECT
             MIN(TO_CHAR(rsh.expected_receipt_date,'YYYY-MM-DD') )
         FROM
             rcv_transactions rct,
             rcv_shipment_headers rsh,
             rcv_shipment_lines rsl,
             po_lines_all pol,
             po_line_locations_all pll,
             po_headers_all ph,
             hr_all_organization_units haou1
         WHERE
             1 = 1
             AND rct.po_header_id = ph.po_header_id
             AND rct.po_line_location_id = pll.line_location_id
             AND rct.po_line_id = pol.po_line_id
             AND rct.shipment_line_id = rsl.shipment_line_id
             AND rsl.shipment_header_id = rsh.shipment_header_id
             AND rsh.ship_to_org_id = haou1.organization_id
             AND ph.po_header_id = pha.po_header_id
             AND ph.vendor_id = pha.vendor_id
             AND ph.vendor_site_id = pha.vendor_site_id
             AND haou1.organization_id = pha.org_id ) AS estimated_arrival_date,
     (SELECT
             MIN(TO_CHAR(rct.transaction_date,'YYYY-MM-DD') )
         FROM
             rcv_transactions rct,
             rcv_shipment_headers rsh,
             rcv_shipment_lines rsl,
             po_lines_all pol,
             po_line_locations_all pll,
             po_headers_all ph,
             hr_all_organization_units haou1
         WHERE
             1 = 1
             AND rct.po_header_id = ph.po_header_id
             AND rct.po_line_location_id = pll.line_location_id
             AND rct.po_line_id = pol.po_line_id
             AND rct.shipment_line_id = rsl.shipment_line_id
             AND rsl.shipment_header_id = rsh.shipment_header_id
             AND rsh.ship_to_org_id = haou1.organization_id
             AND ph.po_header_id = pha.po_header_id
             AND ph.vendor_id = pha.vendor_id
             AND ph.vendor_site_id = pha.vendor_site_id
             AND haou1.organization_id = pha.org_id ) AS actual_arrival_date,
     ( assa.country || '|'|| (SELECT hg.geography_name FROM hz_geographies hg WHERE hg.geography_type = 'COUNTRY' AND hg.country_code = assa.country) ) AS supplier_country,
     haou.name                AS company_code,
     hl1.location_code        AS warehouse_code,
     pha.org_id               AS ebs_org_id,
     pha.segment1             AS ebs_ponumber,
     pha.po_header_id         AS ebs_po_header_id,
     sup.vendor_name          AS ebs_supplier,
     sup.segment1             AS ebs_supplier_number,
     pha.vendor_id            AS ebs_vendor_id,
     assa.vendor_site_code    AS ebs_suppliersite,
     assa.vendor_site_id      AS ebs_vendor_site_id,
     pha.type_lookup_code     AS ebs_potype,
     trunc(pha.creation_date) AS ebs_podate,
     hl2.location_code        AS ebs_billto_loc,
     papf.full_name           AS ebs_buyer,
     pha.authorization_status AS ebs_authorization_status,
     att.name                 AS ebs_terms,
     pha.closed_code          AS ebs_closed_code,
     pha.ship_to_location_id  AS ebs_ship_to_location_id
 FROM
     po_headers_all pha,
     ap_suppliers sup,
     ap_supplier_sites_all assa,
     hr_locations_all hl1,
     hr_locations_all hl2,
     per_all_people_f papf,
     hr_all_organization_units haou,
     ap_terms att
 WHERE
     pha.vendor_id = sup.vendor_id
     AND pha.type_lookup_code NOT IN ('RFQ','QUOTATION')
     AND pha.vendor_site_id = assa.vendor_site_id
     AND pha.ship_to_location_id = hl1.location_id
     AND pha.bill_to_location_id = hl2.location_id
     AND pha.agent_id = papf.person_id
     AND pha.org_id = haou.organization_id
     AND pha.terms_id = att.term_id
     AND pha.closed_code = 'OPEN'
     AND pha.authorization_status = 'APPROVED'
     AND (SELECT nvl(SUM(pla.quantity * pla.unit_price),0) FROM po_lines_all pla WHERE 1 = 1 AND pla.po_header_id = pha.po_header_id) > 0
ORDER BY 1
;