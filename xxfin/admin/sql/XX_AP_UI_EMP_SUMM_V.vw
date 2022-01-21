WHENEVER SQLERROR EXIT FAILURE
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  xx_ap_ui_emp_summ_v.vw                                    |
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
CREATE OR REPLACE VIEW xx_ap_ui_emp_summ_v (vendor_assistant,
                                            employee_id,
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
   SELECT a.vendor_assistant, a.employee_id, a.total_inv_count,
          a.total_inv_amount, a.total_line_amount, a.total_moot_count,
          a.total_moot_inv_amount, a.total_moot_line_amount,
          a.total_nrf_count, a.total_nrf_amount
     FROM TABLE (xx_ap_ui_view_pkg.xx_ap_ui_emp_summ_f) a
;
/

	 