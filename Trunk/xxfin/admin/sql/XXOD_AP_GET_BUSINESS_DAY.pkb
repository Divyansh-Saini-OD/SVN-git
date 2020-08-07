CREATE OR REPLACE PACKAGE BODY XXOD_AP_GET_BUSINESS_DAY
AS
FUNCTION ap_get_business_day (p_date DATE)
RETURN DATE
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                      Wipro/Office Depot                           |
-- +===================================================================+
-- | Name  : XXOD_AP_GET_BUSINESS_DAY                                  |
-- | Description: To get the business day                              |
-- |                                                                   |                
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date         Author            Remarks                   |
-- |=======   ==========   =============     ==========================|
-- |1.0       18-OCT-2007  Ganesan JV        Initial Version	       |			
-- +===================================================================+|
IS
 lc_wkflag  CHAR(1) := 'N';
 ld_hday    DATE;
 ld_wday    DATE;
BEGIN
 ld_wday := p_date;
 WHILE lc_wkflag = 'N' LOOP
  SELECT  GTD.business_day_flag
  INTO lc_wkflag
  FROM gl_transaction_dates GTD
      ,gl_transaction_calendar GTC
  WHERE GTD.transaction_Calendar_id = GTC.transaction_calendar_id
  AND GTD.transaction_date= ld_wday;
  IF lc_wkflag = 'N' THEN
   ld_wday := to_date(ld_wday) + 1;
  ELSE
   BEGIN
    SELECT AP.start_Date
    INTO ld_hday
    FROM ap_other_periods AP
    WHERE AP.period_type='EFT HOLIDAY'
    AND start_Date = ld_wday;
    ld_wday := ld_hday +1;
    lc_wkflag := 'N';
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     lc_wkflag := 'Y';
   END;
  END IF;
 END LOOP;
 RETURN ld_wday;
END;
END XXOD_AP_GET_BUSINESS_DAY;
/
