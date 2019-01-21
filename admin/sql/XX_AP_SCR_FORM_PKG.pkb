CREATE OR REPLACE PACKAGE BODY APPS.XX_AP_SCR_FORM_PKG AS


-- +============================================================================================+ 
PROCEDURE reserve
( p_header_id           IN   NUMBER,
  p_reserve_return      IN   NUMBER,
  p_reserve_hold_amt    IN   NUMBER,
  x_header_row          OUT  NOCOPY     XX_AP_SCR_HEADERS_ALL%ROWTYPE )
IS
  lc_sub_name        CONSTANT VARCHAR2(50)   := 'RESERVE'; 
  
  x_new_update_date           DATE           DEFAULT SYSDATE;
  
  ln_total_hold_amt           NUMBER         DEFAULT NULL;
  ln_payable_amount number;
  
  CURSOR c_header IS
    SELECT xash.header_id,
           xash.net_amount,
           xash.payable_amount,
           xash.bundle_amount,
           xash.auto_reserve,
           xash.reserve_return,
           xash.reserve_hold_amt,
           NVL( (SELECT SUM(NVL(invoice_amount,0)-NVL(discount_amount,0))
              FROM xx_ap_scr_lines_all
             WHERE header_id = xash.header_id
               AND reserve_flag = 'Y'), 0) reserved_amount,
           NVL( (SELECT SUM(NVL(invoice_amount,0)-NVL(discount_amount,0))
              FROM xx_ap_scr_lines_all
             WHERE header_id = xash.header_id
               AND reserve_flag = 'N'), 0) unreserved_amount
      FROM xx_ap_scr_headers_all xash
     WHERE xash.header_id = p_header_id;
     
  l_header_row              c_header%ROWTYPE;
  
  CURSOR c_reserve IS
    SELECT xash.header_id,
           xasl.line_id,
           xasl.invoice_id,
           xasl.invoice_num,
           NVL(xasl.invoice_amount,0)-NVL(xasl.discount_amount,0) line_amount,
           aps.due_date
      FROM xx_ap_scr_headers_all xash,
           xx_ap_scr_lines_all xasl,
           ap_payment_schedules_all aps
     WHERE xash.header_id = xasl.header_id
       AND xasl.invoice_id = aps.invoice_id
       AND xash.header_id = p_header_id
     ORDER BY aps.due_date DESC, xasl.invoice_amount;
  
  TYPE t_reserve_tbl IS TABLE OF c_reserve%ROWTYPE
    INDEX BY PLS_INTEGER;
    
  l_reserve_tbl         t_reserve_tbl;
  
  CURSOR c_payable_amount IS
    SELECT SUM(NVL(invoice_amount,0) - NVL(discount_amount,0))
      FROM xxfin.xx_ap_scr_lines_all
     WHERE reserve_flag = 'N'
       AND header_id = p_header_id;  

  CURSOR c_refresh IS
    SELECT *
      FROM xx_ap_scr_headers_all xash
     WHERE xash.header_id = p_header_id;
BEGIN

  -- get current information
  OPEN c_header;
  FETCH c_header
   INTO l_header_row;
  CLOSE c_header;
  
  -- if header id is not defined or cannot be found
  IF (l_header_row.header_id IS NULL) THEN
    RAISE_APPLICATION_ERROR 
    ( -20001, 'Please define a valid "Header Id".' );
  END IF;
  
  -- if header has been previously reserved
  IF (l_header_row.reserved_amount > 0) THEN
    -- unreserve all lines to re-process them
    UPDATE xx_ap_scr_lines_all
       SET reserve_flag = 'N',
           last_updated_by = FND_GLOBAL.USER_ID,
           last_update_date = x_new_update_date,
           last_update_login = FND_GLOBAL.LOGIN_ID
     WHERE header_id = p_header_id
       AND reserve_flag = 'Y';
  
    -- update header back to original values
    --   defect #2914
    UPDATE xx_ap_scr_headers_all
       SET payable_amount = NVL(net_amount,0),
           bundle_amount = NVL(net_amount,0)
     WHERE header_id = p_header_id;
     
    l_header_row.payable_amount := l_header_row.net_amount;
    l_header_row.bundle_amount := l_header_row.net_amount;
  END IF;
  
  -- calculate hold amount with reserve percent
  ln_total_hold_amt := 
    NVL(p_reserve_hold_amt,0)
    + ( (NVL(l_header_row.bundle_amount,0) - NVL(p_reserve_hold_amt,0)) 
        * NVL(p_reserve_return/100,0));
        
  -- if hold amount is greater than bundle amount, set it to the bundle amount
  IF (NVL(ln_total_hold_amt,0) > NVL(l_header_row.bundle_amount,0)) THEN
    ln_total_hold_amt := NVL(l_header_row.bundle_amount,0);
  END IF;
  
  -- if hold amount is zero, then just return without reserving any lines
  IF (NVL(ln_total_hold_amt,0) > 0) THEN
    -- get invoices to reserve
    OPEN c_reserve;
    FETCH c_reserve
     BULK COLLECT
     INTO l_reserve_tbl;
    CLOSE c_reserve;
  
    -- loop through invoices to reserve
    IF (l_reserve_tbl.COUNT > 0) THEN
      FOR i_index IN l_reserve_tbl.FIRST..l_reserve_tbl.LAST LOOP
        -- update the invoice (batch line)
        UPDATE xx_ap_scr_lines_all
           SET reserve_flag = 'Y',
               last_updated_by = FND_GLOBAL.USER_ID,
               last_update_date = x_new_update_date,
               last_update_login = FND_GLOBAL.LOGIN_ID
         WHERE line_id = l_reserve_tbl(i_index).line_id;
            
        -- decrease hold amount the amount of the invoice (batch line)
        ln_total_hold_amt := ln_total_hold_amt - l_reserve_tbl(i_index).line_amount;
       
        -- if all the hold amount is depleted then do not reserve any more lines
        EXIT WHEN (ln_total_hold_amt <= 0);
      END LOOP;
    END IF;
  END IF;
  
  -- return the updated header row (cursor) and added NVL-0
  --   defect #2914
  OPEN c_payable_amount;
  FETCH c_payable_amount
   INTO ln_payable_amount;
  CLOSE c_payable_amount;
                                        
  -- update header with new amounts and record history
  UPDATE xx_ap_scr_headers_all xasha
     SET reserve_return = NVL(p_reserve_return,0),
         reserve_hold_amt = NVL(p_reserve_hold_amt,0),
         payable_amount = NVL(ln_payable_amount,0),
         bundle_amount  = NVL(ln_payable_amount,0),
         last_updated_by = FND_GLOBAL.USER_ID,
         last_update_date = x_new_update_date,
         last_update_login = FND_GLOBAL.LOGIN_ID
   WHERE header_id = p_header_id;
  
  -- return the updated header row
  OPEN c_refresh;
  FETCH c_refresh
   INTO x_header_row;
  CLOSE c_refresh;
END;


-- +============================================================================================+ 
FUNCTION last_batch
( p_batch_id            IN   NUMBER )
RETURN BOOLEAN
IS
  lc_sub_name        CONSTANT VARCHAR2(50)   := 'LAST_BATCH'; 
  
  ln_last_batch_id            NUMBER         DEFAULT NULL;
  
  CURSOR c_batch IS
    SELECT MAX(batch_id)
      FROM xx_ap_scr_headers_all;
BEGIN
  -- fetch the highest batch id
  OPEN c_batch;
  FETCH c_batch
   INTO ln_last_batch_id;
  CLOSE c_batch;
  
  -- if given batch matches the highest batch, return true
  IF (p_batch_id = ln_last_batch_id) THEN
    RETURN TRUE;
  ELSE 
    RETURN FALSE;
  END IF;
END;


-- +============================================================================================+ 
FUNCTION get_business_unit
( p_vendor_site_id      IN   NUMBER )
RETURN VARCHAR2
IS
  lc_sub_name        CONSTANT VARCHAR2(50)   := 'GET_BUSINESS_UNIT'; 
  
  lc_bus_unit        VARCHAR2(100)           DEFAULT NULL;
  
  CURSOR c_bus_unit IS
    SELECT SUBSTR(gsob.short_name,1,2) ||
           CASE SUBSTR(pvs.attribute8,1,2)
             WHEN 'TR' THEN 'TRA'
             WHEN 'EX' THEN 'EXP'
             ELSE NULL END
      FROM po_vendor_sites_all pvs,
           hr_operating_units hou,
           gl_sets_of_books gsob
     WHERE pvs.org_id    = hou.organization_id
       AND hou.set_of_books_id = gsob.set_of_books_id
       --AND gsob.short_name IN ('US_USD_P','CA_CAD_P')
       AND gsob.set_of_books_id = xx_fin_country_defaults_pkg.f_set_of_books_id('US')
       AND pvs.vendor_site_id = p_vendor_site_id;
BEGIN
  -- fetch the business unit for the vendor site
  OPEN c_bus_unit;
  FETCH c_bus_unit
   INTO lc_bus_unit;
  CLOSE c_bus_unit;
  
  -- return the business unit value
  RETURN lc_bus_unit;
END;

  
END;
/