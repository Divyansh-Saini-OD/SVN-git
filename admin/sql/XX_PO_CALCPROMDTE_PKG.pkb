CREATE OR REPLACE PACKAGE BODY xx_po_calcpromdte_pkg IS

c_def_ocycle CONSTANT VARCHAR2(42) DEFAULT 'SUNMONTUEWEDTHUFRISAT';

PROCEDURE xx_po_calcpromdte_pkg (p_order_dt IN     DATE,
                                 p_supplier IN     NUMBER,
                                 p_location IN     NUMBER,
                                 p_item     IN     NUMBER,
                                 p_prom_dt  IN OUT DATE) IS
w_found            PLS_INTEGER;
w_recfound         PLS_INTEGER := 0;
w_cal_code         VARCHAR2(10);
w_cal              PLS_INTEGER;
w_dummy            PLS_INTEGER;
r_overall_lt       xx_po_lead_time_order_cycle.overall_lt%TYPE;
r_order_cycle_days CHAR(42);
r_freq             PLS_INTEGER;

BEGIN
-- Search for supplier/location/item 
 BEGIN
  SELECT overall_lt,
         order_cycle_days,
         (ordercycle_frequency * 7),
         (p_order_dt + overall_lt - 1) prom_dt
    INTO r_overall_lt,
         r_order_cycle_days,
         r_freq,
         p_prom_dt
    FROM xx_po_lead_time_order_cycle
   WHERE source_id        = p_supplier
--     AND source_type      = 'V'
     AND destination_id   = p_location
--     AND destination_type = 'S'
     AND item_id          = p_item
     AND order_cycle_days IS NOT NULL;
  w_recfound := 1;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
       w_recfound := 0;
 END;
 IF w_recfound = 0 THEN
-- Search for supplier/location 
 BEGIN
  SELECT overall_lt,
         order_cycle_days,
         (ordercycle_frequency * 7),
         (p_order_dt + overall_lt - 1) prom_dt
    INTO r_overall_lt,
         r_order_cycle_days,
         r_freq,
         p_prom_dt
    FROM xx_po_lead_time_order_cycle
   WHERE source_id        = p_supplier
--     AND source_type      = 'V'
     AND destination_id   = p_location
--     AND destination_type = 'S'
     AND item_id          = 0
     AND order_cycle_days IS NOT NULL;
  w_recfound := 1;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
       w_recfound := 0;
 END;
 END IF;
 IF w_recfound = 0 THEN
-- Search for supplier 
 BEGIN
  SELECT overall_lt,
         order_cycle_days,
         (ordercycle_frequency * 7),
         (p_order_dt + overall_lt - 1) prom_dt
    INTO r_overall_lt,
         r_order_cycle_days,
         r_freq,
         p_prom_dt
    FROM xx_po_lead_time_order_cycle
   WHERE source_id        = p_supplier
--     AND source_type      = 'V'
     AND destination_id   = 0
--     AND destination_type = 'S'
     AND item_id          = 0
     AND order_cycle_days IS NOT NULL;
  w_recfound := 1;
 EXCEPTION
  WHEN NO_DATA_FOUND THEN
       w_recfound := 0;
 END;
 END IF;
 IF w_recfound = 0 THEN
    -- Global default LT
    r_overall_lt := 7;
    r_order_cycle_days := c_def_ocycle;
    r_freq := 7;
    p_prom_dt := p_order_dt + r_overall_lt - 1;
  END IF;
  BEGIN
    -- Find calendar code for location
    SELECT calendar_code
      INTO w_cal_code
      FROM mtl_parameters
     WHERE organization_id = p_location;
  w_cal := 1;
  EXCEPTION
   WHEN NO_DATA_FOUND THEN
        w_cal := 0;
  END;
  w_found := 0;
  WHILE w_found = 0 LOOP
   BEGIN
    IF w_cal = 1 THEN
       -- Validate holiday
       BEGIN
        SELECT seq_num
          INTO w_dummy
          FROM bom_calendar_dates
         WHERE calendar_code  = w_cal_code
           AND calendar_date  = p_prom_dt
           AND seq_num       IS NOT NULL;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
              w_cal:= 0;
       END;
    END IF;
    IF instr(r_order_cycle_days, to_char(p_prom_dt,'DY')) > 0 THEN
       w_found := 1;
    ELSE
       p_prom_dt := p_prom_dt + 1;
    END IF;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
         NULL;
   END;
  END LOOP;
--INSERT INTO xxmer.xx_test_calcdte
--    VALUES (p_order_dt
--           ,p_supplier
--           ,p_location
--           ,p_item
--           ,p_prom_dt
--           ,r_overall_lt
--           ,r_order_cycle_days
--           ,r_freq);
--COMMIT;
END xx_po_calcpromdte_pkg;

END xx_po_calcpromdte_pkg;
/
