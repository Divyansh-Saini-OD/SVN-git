create or replace
PACKAGE        "XX_OM_APT_SCH_DATERETURN_PKG" AS

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
-- ---------------------------------
-- Global Variable Declarations
-- ----------------------------------
    
    ge_exception  xx_om_report_exception_t :=
                  xx_om_report_exception_t(
                                           'OTHERS'
                                           ,'OTC'
                                           ,'Pick Release'
                                           ,'Package Insert Process'
                                           ,NULL
                                           ,NULL
                                           ,NULL
                                           ,NULL
                                                 );



-- +===================================================================+
-- | Name  : Check_delivery_date_proc                                  |
-- | Description     : This procedure will be called from ATP/Soucing  |
-- |                   to check the availability of the capacity on    |
-- |                   the date validated against Customer calendar    |
-- |                   and warehouse calendar. if the capacity is      |
-- |                   avaialble it sends the slot information along   |
-- |                   date and a flag 'Y' saying avaialble. If the    |
-- |                   capacity is not avaialble it passes 'N'value    |
-- |                   saying capacity is not avaialble.               |
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
    );

TYPE daterun_rec_type IS RECORD 
                   (  delivery_date                DATE  
                     ,slot_start_time              VARCHAR2(4) 
                     ,slot_end_time                VARCHAR2(4) 
                    );

  --Table of the record contains output details
  TYPE daterun_tbl_type IS TABLE OF daterun_rec_type 
  INDEX BY BINARY_INTEGER;


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
    ,p_ship_method_code    IN      VARCHAR2
    , p_planning_category  IN      VARCHAR2
    , p_operating_unit     IN      NUMBER
    , P_zone_id            IN      NUMBER
    , P_inventory_org_id   IN      NUMBER
    , p_def_delv_date      IN      DATE
    , x_delv_date_times    OUT     NOCOPY daterun_tbl_type
    , x_msg_id             OUT     NOCOPY VARCHAR2
    , x_return_status      OUT     NOCOPY VARCHAR2
    );

-- +===================================================================+
-- | Name  : book_delivery_date_proc                                   |
-- | Description     : This procedure will be called from any process  |
-- |                   where an appointment is either added or deleted |
-- |                   from a date and time slot.                      |
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
    );
    
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
                             );

    
    
END XX_OM_APT_SCH_DATERETURN_PKG;
