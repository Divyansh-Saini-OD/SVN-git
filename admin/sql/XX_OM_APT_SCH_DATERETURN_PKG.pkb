create or replace
PACKAGE BODY        "XX_OM_APT_SCH_DATERETURN_PKG" 

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  : XX_OM_APT_SCH_DATERETURN_PKG (XXOMAPTSCHDTRTN.PKS)        |
-- | Description      : This Program will Returns Appointment date     |
-- |			and slots for funrbiture items with appointment|
-- |                    scheduling flag enabled shipmethids            |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author            Remarks                 |
-- |=======    ==========    =============     ======================= |
-- |DRAFT 1A   20-July-2007  John Tempalski    Initial draft version   |
-- |                                                                   |
-- +===================================================================+

AS

-- +===================================================================+
    -- | Name  : Write_Exception                                           |
    -- | Description : Procedure to log exceptions from this package using |
    -- |               the Common Exception Handling Framework             |
    -- |                                                                   |
    -- | Parameters :       Error_Code                                     |
    -- |                    Error_Description                              |
    -- |                    Entity_Reference                               |
    -- |                    Entity_Reference_Id                            |
    -- |                                                                   |
    -- +===================================================================+

PROCEDURE Write_Exception (
                                p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_reference  IN  VARCHAR2
                               ,p_entity_ref_id     IN  VARCHAR2
                            )
IS

     lc_errbuf    VARCHAR2(4000);
     lc_retcode   VARCHAR2(4000);

BEGIN                               -- Procedure Block

     ge_exception.p_error_code        := p_error_code;
     ge_exception.p_error_description := p_error_description;
     ge_exception.p_entity_ref        := p_entity_reference;
     ge_exception.p_entity_ref_id     := p_entity_ref_id;

     xx_om_global_exception_pkg.Insert_Exception(
                                                  ge_exception
                                                 ,lc_errbuf
                                                 ,lc_retcode
                                                );

END Write_Exception;                -- End Procedure Block

-- +===================================================================+
-- | Name  : Check_delivery_date_proc                                  |
-- | Description     : This procedure will be called from ATP/Soucing  |
-- |                   to check the availability of the capacity on    |
-- |                   the date validated against Customer calendar    |
-- |                   and warehouse calendar. If capacity is not      |             
-- |                   available on the date passed procedure will     |                                            
-- |                   attempt to find first date/time slot available  |                                      
-- |                   and pass back to front end.                     |                                   
-- |                                                                   |
-- | Parameters      : p_eComsitetype   IN 		               |
-- |                   P_zone_id        IN 			       |
-- |                   P_inventory_org_id  IN 			       |
-- |                   p_delivery_date IN 		               |
-- |                   x_available_flag OUT                            |
-- |                   x_delv_from_time OUT                            |
-- |                   x_delv_to_time   OUT                            |
-- |                   x_return_status  OUT                            |
-- +===================================================================+

PROCEDURE check_delivery_date_proc  (
      p_eComsitetype       IN      VARCHAR2
    , p_planning_category  IN      VARCHAR2
    , p_operating_unit     IN      NUMBER   
    , p_customer_number    IN      VARCHAR2
    , p_ship_method_code   IN      VARCHAR2     
    , p_zone_id            IN      NUMBER
    , p_inventory_org_id   IN      NUMBER
    , p_delivery_date      IN OUT  DATE
    , x_delv_from_time     OUT     NOCOPY VARCHAR2
    , x_delv_to_time       OUT     NOCOPY VARCHAR2
    , x_msg_id             OUT	   NOCOPY VARCHAR2
    , x_return_status      OUT     NOCOPY VARCHAR2
    )
    
IS
  
    ln_org_id                      NUMBER;
    ln_slot_start_time             VARCHAR2(4);
    ln_slot_end_time               VARCHAR2(4);
    ln_slot_id                     NUMBER;
    la_slot_id                     NUMBER;
    ln_sum_capacity                NUMBER;
    ln_max_capacity                NUMBER;
    ln_region_id                   NUMBER; 
    ln_max_date                    DATE; 
    ln_return_status               VARCHAR2(1);
    ln_msg_id                      VARCHAR2(100);
    ln_fill                        VARCHAR2(1);
    ln_calendar_usage              VARCHAR2(8) := 'SHIPPING';
    lc_errbuf                      VARCHAR2(4000);
    lc_err_code                    VARCHAR2(4000);
 
 --Cursor to get available slots and max capacities        
   CURSOR aptsch_cursor(c_zone_id xx_om_aptsch_calendar.zone_id%TYPE
         ,c_inventory_org_id xx_om_aptsch_calendar.inventory_org_id%TYPE
         ,c_delivery_date xx_om_aptsch_calendar.cldr_date%TYPE
         ,c_planning_category xx_om_aptsch_calendar.planning_category%TYPE
         ,c_operating_unit xx_om_aptsch_calendar.operating_unit%TYPE) 
   IS
   SELECT 
       apt_slot_id  la_slot_id    
      ,slot_max_capacity ln_max_capacity 
   FROM
       xx_om_aptsch_calendar
   WHERE
       cldr_date = TRUNC(c_delivery_date)
   AND zone_id = c_zone_id
   AND inventory_org_id = c_inventory_org_id
   AND planning_category = c_planning_category
   AND operating_unit = c_operating_unit;
      
BEGIN

--Validattion List
-- 1. Organization validation 
-- 2. Zone validation 
        x_return_status := 'S';
        
        IF (p_inventory_org_id IS NULL) THEN
        x_return_status := 'E';
        x_msg_id := 'Invalid Inventory Org';  
        END IF;
        
        IF (p_zone_id IS NULL) THEN
        x_return_status := 'E';
        x_msg_id := 'Ivalid Zone Id';
        END IF;   
 IF(x_return_status) <> 'E' THEN         
   ln_max_date := p_delivery_date + 91;

--verify caledars for ship method and customer accept deliveries on dates       
   IF XX_MSC_SOURCING_DATE_CALC_PKG.Is_Carrier_Calendar_Open(
       p_ship_method => p_ship_method_code
      ,p_date => p_delivery_date
      ,x_return_status => ln_return_status
      ,x_msg => ln_msg_id ) THEN 
      ln_fill := 'A';   
   END IF;
   
   IF XX_MSC_SOURCING_DATE_CALC_PKG.Is_Customer_Calendar_Open(
       p_partner_number => p_customer_number
      ,p_calendar_usage => ln_calendar_usage 
      ,p_date => p_delivery_date
      ,x_return_status => ln_return_status
      ,x_msg => ln_msg_id ) THEN 
      ln_fill := 'A';   
   END IF;
   
   p_delivery_date := p_delivery_date - 1;
   WHILE p_delivery_date < ln_max_date
 LOOP                                                 
   p_delivery_date := p_delivery_date + 1;
      FOR aptsch_cursor_rec_type IN aptsch_cursor(p_zone_id,
                                               p_inventory_org_id,
                                               p_delivery_date,
                                               p_planning_category,
                                               p_operating_unit)
  
  LOOP
-- Get used capacity for date and slot retrieved in cursor above  
   BEGIN
       SELECT
           sum(used_capacity) 
       INTO 
           ln_sum_capacity
       FROM
           xx_om_aptsch_cldr_all 
       WHERE apt_slot_id = aptsch_cursor_rec_type.la_slot_id
       AND delivery_date = TRUNC(p_delivery_date)
       AND zone_id = p_zone_id
       AND inventory_org_id = p_inventory_org_id
       AND planning_category = p_planning_category
       AND operating_unit = p_operating_unit; 
  
       IF (ln_sum_capacity IS NULL) THEN
       ln_sum_capacity := 0;
       END IF;
   END;
 
 -- If capacity is available get the slot from and to times from table     
   IF (ln_sum_capacity < aptsch_cursor_rec_type.ln_max_capacity) THEN
      BEGIN
         SELECT slot_start_time, 
                slot_end_time
         INTO 
             ln_slot_start_time,
             ln_slot_end_time
         FROM
             xx_om_aptsch_cal_slots       
         WHERE
             slot_id = aptsch_cursor_rec_type.la_slot_id
         AND slot_planning_category = p_planning_category
         AND operating_unit = p_operating_unit;
    
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
         x_return_status := 'E';
         x_msg_id := 'No dates available for appointment scheduling';
      END;
   END IF;

--Send results to client       
      IF (ln_slot_start_time IS NOT NULL) THEN
          x_delv_from_time := ln_slot_start_time;
          x_delv_to_time   := ln_slot_end_time;
          x_return_status  := 'S'; 
        EXIT;
      END IF;
 END LOOP;
  
      IF (ln_slot_start_time IS NOT NULL) THEN
      EXIT;
      END IF;
  
 END LOOP;
  
      IF (ln_slot_start_time IS NULL) THEN
      x_return_status := 'E';
      x_msg_id := 'No dates available for appointment scheduling';
      END IF;

END IF;

      EXCEPTION
      WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_E1059_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_E1059_UNEXPECTED_ERROR3';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'APPOINT SCHED'
                       ,p_entity_ref_id     => 1059
           );
           
      x_return_status := 'E';
      x_msg_id := 'Unexpected Error has Occurred';
 
END check_delivery_date_proc;

-- +===================================================================+
-- | Name  : get_delivery_dateTimes_proc                               |
-- | Description     : This procedure will be called from font-end     |
-- |                   to get the available dates 1 on           |
-- |                   the show up  as a calendar to make a slection   |
-- |                   by the user.                                    |
-- |                                                                   |
-- | Parameters      : p_eComsitetype   IN                             |
-- |                   p_bill_to_org_id IN                             |
-- |                   p_ship_to_org_id IN       	               |
-- |                   P_zone_id        IN 			       |
-- |                   P_inventory_org_id  IN 	                       |
-- |                   p_inventory_item_id  IN  		       |
-- |                   p_ordered_quantity  IN                          |
-- |                   p_def_delv_date   IN 		               |
-- |                   x_delv_date_times OUT                           |
-- |                   x_msg_id          OUT                           |
-- |                   x_return_status  OUT                            |
-- +===================================================================+

PROCEDURE get_delivery_dateTimes_proc  (
      p_eComsitetype       IN      VARCHAR2
    , p_bill_to            IN      NUMBER
    , p_ship_to            IN      NUMBER
    , p_ship_method_code   IN      VARCHAR2
    , p_planning_category  IN      VARCHAR2
    , p_operating_unit     IN      NUMBER
    , P_zone_id            IN      NUMBER
    , P_inventory_org_id   IN      NUMBER
    , p_def_delv_date      IN      DATE
    , x_delv_date_times    OUT     NOCOPY daterun_tbl_type
    , x_msg_id             OUT     NOCOPY VARCHAR2
    , x_return_status      OUT     NOCOPY VARCHAR2
    )

IS 

    ln_days                NUMBER := 0;
    ln_used_capacity       NUMBER := 0;
    ln_count               NUMBER := 0; 
    ln_slot_start_time     VARCHAR2(4);
    ln_slot_end_time       VARCHAR2(4); 
    ln_value               VARCHAR2(1); 
    ln_calendar_usage      VARCHAR2(8) := 'SHIPPING';
    ln_return_status       VARCHAR2(1);
    ln_msg_id              VARCHAR2(100);
    ln_fill                VARCHAR2(1); 
    ln_days_count          NUMBER := 0;
    ln_hold_date           DATE := '01-JAN-01';
    lc_errbuf              VARCHAR2(4000);
    lc_err_code            VARCHAR2(4000);

-- Cursor to retrieve used capacity for a date and slot id                  
    CURSOR xx_om_aptsch_del_date_cur(c_zone_id xx_om_aptsch_cldr_all.zone_id%TYPE
         ,c_inventory_org_id xx_om_aptsch_cldr_all.inventory_org_id%TYPE
         ,c_def_delv_date xx_om_aptsch_cldr_all.delivery_date%TYPE
         ,c_apt_slot_id  xx_om_aptsch_cldr_all.apt_slot_id%TYPE
         ,c_planning_category xx_om_aptsch_cldr_all.planning_category%TYPE
         ,c_operating_unit xx_om_aptsch_cldr_all.operating_unit%TYPE)  
    IS
     SELECT 
         delivery_date  
        ,apt_slot_id
        ,sum(used_capacity) ln_used_capacity
     FROM 
        xx_om_aptsch_cldr_all 
     WHERE
         delivery_date = TRUNC(c_def_delv_date)
     AND zone_id = c_zone_id 
     AND inventory_org_id = c_inventory_org_id 
     AND apt_slot_id = c_apt_slot_id
     AND operating_unit = c_operating_unit
     AND planning_category = c_planning_category
     GROUP BY delivery_date, apt_slot_id;  

     xx_om_aptsch_del_date_rec xx_om_aptsch_del_date_cur%ROWTYPE;


-- Cusror to retrieve all available dates and slot ids
     CURSOR xx_om_aptsch_avail_date_cur(c_zone_id xx_om_aptsch_calendar.zone_id%TYPE
         ,c_inventory_org_id xx_om_aptsch_calendar.inventory_org_id%TYPE
         ,c_def_delv_date xx_om_aptsch_calendar.cldr_date%TYPE
         ,c_planning_category xx_om_aptsch_calendar.planning_category%TYPE
         ,c_operating_unit xx_om_aptsch_calendar.operating_unit%TYPE) 
     IS
       SELECT 
           cldr_date
          ,apt_slot_id
          ,slot_max_capacity  
       FROM
          xx_om_aptsch_calendar
       WHERE
           cldr_date >= TRUNC(c_def_delv_date)
       AND zone_id = c_zone_id
       AND inventory_org_id = c_inventory_org_id
       AND operating_unit = c_operating_unit
       AND planning_category = c_planning_category
       ORDER BY cldr_date, apt_slot_id;

 BEGIN 
    
    x_return_status := 'S';
    x_msg_id := 'Success';
    
    IF (p_zone_id IS NULL) THEN
      x_return_status := 'E';
      x_msg_id := 'Invalid Zone ID';
    END IF;

    IF (p_inventory_org_id IS NULL) THEN
      x_return_status := 'E';
      x_msg_id := 'Invalid Inventory Org';  
    END IF;
      
 IF (x_return_status <> 'E') THEN 
 
    CASE SUBSTR(p_eComsitetype,1,3) 
      WHEN 'OD ' THEN ln_days := 7;
      WHEN 'BSD' THEN ln_days := 20;
      WHEN 'JM ' THEN ln_days := 60; 
      ELSE ln_days := 7;
    END CASE;

--Retrieve available dates and slot ids  
  FOR xx_om_aptsch_avail_date_rec
  IN xx_om_aptsch_avail_date_cur(p_zone_id
    ,p_inventory_org_id, p_def_delv_date
    ,p_planning_category
    ,p_operating_unit) 

  LOOP
     
--Retrieve used capacity for retrieved date and slot id   
     OPEN xx_om_aptsch_del_date_cur (p_zone_id
         ,p_inventory_org_id
         ,xx_om_aptsch_avail_date_rec.cldr_date
         ,xx_om_aptsch_avail_date_rec.apt_slot_id
         ,p_planning_category
         ,p_operating_unit);

     FETCH xx_om_aptsch_del_date_cur INTO xx_om_aptsch_del_date_rec; 
     
     IF (xx_om_aptsch_del_date_cur%NOTFOUND) THEN
     xx_om_aptsch_del_date_rec.ln_used_capacity := 0;
     END IF;
     
     ln_value := 'N';

-- If capacity still available check calendars to ensure delivery is 
-- allowed on date requested.     
  IF ((xx_om_aptsch_del_date_rec.ln_used_capacity) < 
       xx_om_aptsch_avail_date_rec.slot_max_capacity) THEN
  
     IF XX_MSC_SOURCING_DATE_CALC_PKG.Is_Carrier_Calendar_Open(
        p_ship_method => p_ship_method_code
       ,p_date => p_def_delv_date
       ,x_return_status => ln_return_status
      ,x_msg => ln_msg_id ) THEN 
       ln_fill := 'A';   
     END IF;
   
     IF XX_MSC_SOURCING_DATE_CALC_PKG.Is_Customer_Calendar_Open(
         p_partner_number => p_bill_to
        ,p_calendar_usage => ln_calendar_usage 
        ,p_date => p_def_delv_date
        ,x_return_status => ln_return_status
        ,x_msg => ln_msg_id ) THEN 
        ln_fill := 'A';   
     END IF;
 
     ln_value := 'Y';

  END IF;
  
     CLOSE xx_om_aptsch_del_date_cur;
-- Retrieve from and to times for slot 
     IF(ln_value = 'Y') THEN
     
        SELECT 
            slot_start_time
           ,slot_end_time
        INTO 
            ln_slot_start_time
           ,ln_slot_end_time
        FROM 
            xx_om_aptsch_cal_slots 
        WHERE 
            slot_id = xx_om_aptsch_avail_date_rec.apt_slot_id;

        IF(ln_hold_date <> xx_om_aptsch_avail_date_rec.cldr_date) THEN
           ln_hold_date := xx_om_aptsch_avail_date_rec.cldr_date;
           ln_days_count := ln_days_count + 1;
        END IF;
      
-- If days loaded is ove max days to be loaded get out...    
        IF(ln_days_count > ln_days) THEN
        EXIT;
        END IF;
        
-- Load record in table which will go back to client         
     ln_count := NVL(ln_count,0)+1;
     x_delv_date_times(ln_count).delivery_date  
        := xx_om_aptsch_avail_date_rec.cldr_date; 
     x_delv_date_times(ln_count).slot_start_time := ln_slot_start_time;
     x_delv_date_times(ln_count).slot_end_time   := ln_slot_end_time; 
 
    
     END IF;
  
  END LOOP;
    
   -- BEGIN
   -- FOR i IN 1 .. ln_count 
   -- LOOP 
   --  DBMS_OUTPUT.PUT_LINE('END Date ' || x_delv_date_times(i).delivery_date); 
   --   DBMS_OUTPUT.PUT_LINE('END Start Time ' || x_delv_date_times(i).slot_start_time);
   --   DBMS_OUTPUT.PUT_LINE('END End Time ' || x_delv_date_times(i).slot_end_time);
   -- END LOOP;
     
   -- END;
 
 END IF;

    EXCEPTION
      WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME('XXOM','XX_OM_E1059_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);

      lc_errbuf   := FND_MESSAGE.GET;
      lc_err_code := 'XX_OM_E1059_UNEXPECTED_ERROR3';

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                        p_error_code        => lc_err_code
                       ,p_error_description => lc_errbuf
                       ,p_entity_reference  => 'APPOINT SCHED'
                       ,p_entity_ref_id     => 1059
           );
      
      x_return_status := 'E';
      x_msg_id := 'Unexpected Error has Occurred OK';


  
END get_delivery_dateTimes_proc;

-- +===================================================================+
-- | Name  : book_delivery_date_proc                                   |
-- | Description     : This procedure will be called from any process  |
-- |                   that either adds or deletes appointments from   |
-- |                   an order.  some processes the will call this    |
-- |                   are order booking, order cancellation, etc.     |
-- |                                                                   |
-- | Parameters      : p_eComsitetype      IN                          |
-- |                   p_zone_id           IN                          |
-- |                   p_inventory_org_id  IN     	               |
-- |                   P_book_date         IN 			       |
-- |                   P_order_number      IN 	                       |
-- |                   p_order_type        IN  	               	       |
-- |                   p_from_slot         IN                          |
-- |                   p_to_slot           IN 		               |
-- |                   p_action_flag       IN                          |
-- |                   x_msg_id            OUT                         |
-- |                   x_return_status     OUT                         |
-- +===================================================================+

PROCEDURE book_delivery_date_proc  (
      p_eComsitetype       IN      VARCHAR2
    , p_zone_id            IN      NUMBER
    , p_inventory_org_id   IN      NUMBER
    , p_planning_category  IN      VARCHAR2
    , p_operating_unit     IN      NUMBER
    , p_book_date          IN      DATE   
    , p_order_number       IN      NUMBER
    , p_order_type         IN      NUMBER
    , p_from_slot          IN      NUMBER
    , p_to_slot            IN      NUMBER 
    , p_action_flag        IN      VARCHAR2
    , x_msg_id             OUT     NOCOPY VARCHAR2
    , x_return_status      OUT     NOCOPY VARCHAR2
    )

IS 
      ln_slot_id           NUMBER;
      ln_used_capcity      NUMBER;
      ln_cldr_rec_id       NUMBER;  
            
  BEGIN

-- If action is 'A' order else Return 
       IF(p_action_flag = 'A') THEN
          ln_used_capcity := 1;
       ELSE
          ln_used_capcity := -1;
       END IF;

 
 -- Get slot id for times passed     
   SELECT 
       slot_id
   INTO 
       ln_slot_id
   FROM 
       xx_om_aptsch_cal_slots 
   WHERE 
       slot_start_time = p_from_slot 
   AND slot_end_time = p_to_slot
   AND slot_planning_category = p_planning_category
   AND operating_unit = p_operating_unit;

-- Get record id for date and slot passed 
   SELECT
       cldr_rec_id
   INTO
       ln_cldr_rec_id
   FROM 
       xx_om_aptsch_calendar 
   WHERE
       cldr_date = TRUNC(p_book_date)
   AND apt_slot_id = ln_slot_id
   AND zone_id = p_zone_id 
   AND inventory_org_id = p_inventory_org_id
   AND planning_category = p_planning_category
   AND operating_unit = p_operating_unit;

   INSERT INTO xx_om_aptsch_cldr_all (
               transaction_id
              ,cldr_rec_id
              ,delivery_date
              ,apt_slot_id
              ,planning_category 
              ,zone_id
              ,inventory_org_id
              ,order_number
              ,order_type_id
              ,operating_unit
              ,used_capacity
              ,creation_date
              ,last_update_date)
   VALUES (
              xx_om_aptsch_tran_rec_id_s.NEXTVAL
             ,ln_cldr_rec_id
             ,p_book_date
             ,ln_slot_id
             ,p_planning_category
             ,p_zone_id
             ,p_inventory_org_id
             ,p_order_number
             ,p_order_type
             ,p_operating_unit
             ,ln_used_capcity
             ,SYSDATE
             ,SYSDATE);
   COMMIT;

END book_delivery_date_proc;

END XX_OM_APT_SCH_DATERETURN_PKG;
