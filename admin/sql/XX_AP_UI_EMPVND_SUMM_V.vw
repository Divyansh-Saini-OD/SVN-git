WHENEVER SQLERROR EXIT FAILURE
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_UI_EMPVND_SUMM_V.vw                                 |
-- |                                                                          |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        18-OCT-2017    Paddy Sanjeevi        Initial Version           |
-- +==========================================================================+
CREATE OR REPLACE VIEW XX_AP_UI_EMPVND_SUMM_V (org_id,
                                               vendor_assistant,
                                               employee_id,
                                               vendor_name,
                                               supplier,
                                               vendor_site_code,
                                               disc,
                                               total_inv_count,
                                               total_inv_amount,
                                               total_line_amount,
                                               total_moot_count,
                                               total_moot_inv_amount,
                                               total_moot_line_amount,
                                               total_nrf_count,
                                               total_nrf_amount
                                              )
AS
   SELECT org_id, vendor_assistant, employee_id, vendor_name, supplier,
          vendor_site_code, disc, total_inv_count, total_inv_amount,
          total_line_amount, total_moot_count, total_moot_inv_amount,
          total_moot_line_amount, total_nrf_count, total_nrf_amount
     FROM TABLE
             (xx_ap_ui_view_pkg.xx_ap_ui_empvnd_summ_f
                                         (xx_ap_ui_view_pkg.get_org,
                                          xx_ap_ui_view_pkg.get_p_vendor,
                                          xx_ap_ui_view_pkg.get_p_vendor_site,
                                          xx_ap_ui_view_pkg.get_p_employee
                                         )
             ) a
;
/
