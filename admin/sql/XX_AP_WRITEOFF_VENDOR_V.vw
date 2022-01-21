WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_WRITEOFF_VENDOR_V.vw                                |
-- | RICE ID     :  E3522                                                     |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        18-OCT-2017    Paddy Sanjeevi        Initial Version           |
-- +==========================================================================+

prompt Create XX_AP_WRITEOFF_VENDOR_V...

CREATE OR REPLACE VIEW APPS.XX_AP_WRITEOFF_VENDOR_V (VENDOR_NAME, VENDOR_ID, OPERATING_UNIT_ID) AS 
  SELECT DISTINCT sup.vendor_name, sup.vendor_id,crs.operating_unit_id
           FROM ap_suppliers sup, cst_reconciliation_summary crs
          WHERE sup.vendor_id = crs.vendor_id;
/					
show err
