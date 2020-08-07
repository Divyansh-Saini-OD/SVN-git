create or replace
PACKAGE XX_OM_APT_SCH_TO_AOPS_PKG  
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       OD Staff                                    |
-- +===================================================================+
-- | Name  :  XX_OM_APTSCH_TO_AOPS_PKG                   |
-- | Description: This program is called from all programs that perform|
-- |              updates to appointment scheduling calendars and data.|
-- |              This program will accept input parms and validate.   |  
-- |              If errors, the GLOBAL_EXCEPTIONS_PKG will be called. |
-- |              This program will build an AQ if the data is valid   |
-- |              The AQ is processed by a BPEL process to send an MQ  |
-- |              to AOPS for the calendar update (BPEL process is     |
-- |              ApptSchedulingUpdatesToAOPS)                         |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 29-Sep-2007  Dedra Maloy      Initial draft version       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

AS

   -- +===================================================================+
   -- | Name  : aptshc_log_exceptions                                      |
   -- | Description: This procedure will be responsible to store all      |
   -- |              the exceptions occured during the procees using      |
   -- |              global custom exception handling framework           |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE aptsch_log_exceptions( p_error_code        IN  VARCHAR2
                                  ,p_error_description IN  VARCHAR2
                                  ,p_entity_ref        IN  VARCHAR2
                                  ,p_entity_ref_id     IN  PLS_INTEGER
                                 );
                                 
   -- +===================================================================+
   -- | Name  : AptSch_Insert                                             |
   -- | Description: This procedure accepts input parameters from the     |
   -- |              calling program, inserts the data into the log table | 
   -- |              XX_OM_APTSCH_CAL_UPD_AOPS, then validates the trans- |
   -- |              action_type. If valid, then executes the procedure to|
   -- |              validate the input parameters required for a particu-|
   -- |              lar transaction_type.                                |
   -- +===================================================================+
      PROCEDURE AptSch_insert
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER            
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 

   -- +===================================================================+
   -- | Name  : AptSch_validate_used                                      |
   -- | Description: This procedure accepts input parameters from         |
   -- |              procedure AptSch_Insert when the transaction_type    | 
   -- |              is 'INCUSED' or 'DECUSED'.  This procedure validates |
   -- |              that the data required to build this AQ for the AOPS |
   -- |              update is present and valid in the input.            |
   -- +===================================================================+
      PROCEDURE AptSch_validate_used
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER            
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 

   -- +===================================================================+
   -- | Name  : AptSch_validate_mkt                                       |
   -- | Description: This procedure accepts input parameters from         |
   -- |              procedure AptSch_Insert when the transaction_type    | 
   -- |              is 'ADDMKT', 'CHGMKT', 'DELMKT'.  This procedure     |
   -- |              validates that the data required to build this AQ for|
   -- |              the AOPS update is present and valid in the input.   |
   -- +===================================================================+
      PROCEDURE AptSch_validate_mkt
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER         
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 

   -- +===================================================================+
   -- | Name  : AptSch_validate_zip                                       |
   -- | Description: This procedure accepts input parameters from         |
   -- |              procedure AptSch_Insert when the transaction_type    | 
   -- |              is 'ADDZIP', 'CHGZIP', 'DELZIP'.  This procedure     |
   -- |              validates that the data required to build this AQ for|
   -- |              the AOPS update is present and valid in the input.   |
   -- +===================================================================+                          
      PROCEDURE AptSch_validate_zip
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER         
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 

   -- +===================================================================+
   -- | Name  : AptSch_validate_cal                                       |
   -- | Description: This procedure accepts input parameters from         |
   -- |              procedure AptSch_Insert when the transaction_type    | 
   -- |              is 'ADDCAL', 'CHGCAL', 'DELCAL'.  This procedure     |
   -- |              validates that the data required to build this AQ for|
   -- |              the AOPS update is present and valid in the input.   |
   -- +===================================================================+                          
      PROCEDURE AptSch_validate_cal
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER         
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 
   -- +===================================================================+
   -- | Name  : AptSch_validate_foot                                      |
   -- | Description: This procedure accepts input parameters from         |
   -- |              procedure AptSch_Insert when the transaction_type    | 
   -- |              is 'ADDFOOT', 'CHGFOOT', 'DELFOOT'.  This procedure  |
   -- |              validates that the data required to build this AQ for|
   -- |              the AOPS update is present and valid in the input.   |
   -- +===================================================================+
      PROCEDURE AptSch_validate_foot
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER         
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 

   -- +===================================================================+
   -- | Name  : AptSch_validate_rebuild                                   |
   -- | Description: This procedure accepts input parameters from         |
   -- |              procedure AptSch_Insert when the transaction_type    | 
   -- |              is 'REBUILD'.  This procedure validates the data     |
   -- |              required to build this AQ for the AOPS update is     |
   -- |              present and valid in the input.                      |
   -- +===================================================================+                          
      PROCEDURE AptSch_validate_rebuild
                          ( p_transaction_type          VARCHAR2 --(10)
                           ,p_inventory_org_id          NUMBER
                           ,p_zone_id                   NUMBER
                           ,p_ship_to_org_id            NUMBER
                           ,p_zip_code                  VARCHAR2 --(60) 
                           ,p_country                   VARCHAR2 --(80)
                           ,p_zone_carrier              VARCHAR2 --TBD                 
                           ,p_delivery_charge_code      VARCHAR2 --TBD                 
                           ,p_carrier_ship_method_id    NUMBER         
                           ,p_slot_max_capacity         NUMBER
                           ,p_used_capacity             NUMBER
                           ,p_cldr_day_name             VARCHAR2 --(10)
                           ,p_cldr_date                 DATE
                           ,p_slot_start_time           VARCHAR2 --(10)
                           ,p_slot_end_time             VARCHAR2 --(10)
                           ,p_created_by                NUMBER
                          ); 
     
   -- +===================================================================+
   -- | Name  : AptSch_send_AQ                                            |
   -- | Description: This procedure accepts input parameters from one of  |
   -- |              the proceudres AptSch_validate_nnnnnn depending on   | 
   -- |              the input parameter trasnaction_type.  This procedure|
   -- |              will build an AQ message and send.  This AQ entry    |
   -- |              will be processed by the BPEL process                |
   -- |              ApptSchedulingUpdatesToAOPS                          |
   -- +===================================================================+                                    
      PROCEDURE AptSch_send_AQ
                          ( p_transaction_type      VARCHAR2  --(10)
                           ,lc_location_code        VARCHAR2  --(04)
                           ,lc_zone_name 	    VARCHAR2  --(10) 
                           ,lc_zone_description	    VARCHAR2  --(30) 
                           ,lc_zip_code		    VARCHAR2  --(05) 
                           ,lc_zone_carrier	    VARCHAR2  --(01) 
                           ,lc_delivery_charge_code VARCHAR2  --(03) 
                           ,lc_delivery_date_code   VARCHAR2  --(03) 
                           ,lc_max_Capacity	    VARCHAR2  --(05) 
                           ,lc_used_Capacity	    VARCHAR2  --(05) 
                           ,lc_day_of_week	    VARCHAR2  --(01) 
                           ,lc_date_slot	    VARCHAR2  --(08) 
                           ,lc_from_time	    VARCHAR2  --(04) 
                           ,lc_to_time		    VARCHAR2  --(04)
                           ,p_created_by            VARCHAR2  --(10)
                           ,lc_create_date	    VARCHAR2  --(10) 
                           ,lc_create_time	    VARCHAR2  --(10) 
                          ); 
END XX_OM_APT_SCH_TO_AOPS_PKG;   
