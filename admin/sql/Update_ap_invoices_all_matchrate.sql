-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Update_ap_invoices_all_matchrate                                               |
-- | Description : This Script is used to update the attribute4 of ap_invoices_all for release date               |
-- |Change Record:    
-- |Rice ID:E3523                                                                         |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 17-MAY-18  Priyam Parmar              Update attribute4 for EDI Invoices        |
-- +===========================================================================================+
--

update ap_invoices_all a
set a.attribute4=to_char(a.creation_date+6,'DD-MON-YYYY')
where a.source='US_OD_TRADE_EDI'
and a.creation_date BETWEEN TO_DATE('07-APR-18 00:00:00','DD-MON-RR HH24:MI:SS')
  AND TO_DATE(TO_CHAR(sysdate)||' 23:59:59','DD-MON-RR HH24:MI:SS')-7
      AND EXISTS(SELECT 'x'
                   FROM xx_fin_translatedefinition xftd,
                        xx_fin_translatevalues xftv,
                        ap_supplier_sites_all site
                  WHERE site.vendor_site_id=a.vendor_site_id
                    AND xftd.translation_name = 'XX_AP_TRADE_CATEGORIES'
                    AND xftd.translate_id     = xftv.translate_id
                    AND xftv.target_value1    = site.attribute8
                    AND xftv.enabled_flag     = 'Y'
                    AND SYSDATE BETWEEN xftv.start_date_active AND NVL(xftv.end_date_active,SYSDATE)
                  );
commit;
/
