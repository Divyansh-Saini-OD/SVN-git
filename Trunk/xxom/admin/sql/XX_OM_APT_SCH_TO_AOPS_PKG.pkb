create or replace
PACKAGE BODY XX_OM_APT_SCH_TO_AOPS_PKG  
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

  lrec_exception_obj_type xx_om_report_exception_t:=
                          xx_om_report_exception_t( NULL
                                                  , NULL
                                                  , NULL
                                                  , NULL
                                                  , NULL
                                                  , NULL
                                                  , NULL
                                                  , NULL);
   lc_error_code          VARCHAR2 (240)  := 'S';
   lc_error_description   VARCHAR2 (2000) := NULL;
   lc_entity_ref          VARCHAR2 (30)   := NULL;
   ln_entity_ref_id       PLS_INTEGER;
   
   --Get current date and time
   lc_create_date         DATE         := to_char(SYSDATE,'dd-mon-yy');
   lc_create_time         VARCHAR2(10) := to_char(SYSDATE,'hh24:mm:ss');
      
   --Variables for AQ output
   lc_location_code        VARCHAR2(04) := '    ';
   lc_zone_name		   VARCHAR2(10) := '          ';
   lc_zone_description	   VARCHAR2(30) := '                              ';
   lc_zip_code		   VARCHAR2(05) := '     ';
   lc_zone_carrier	   VARCHAR2(01) := ' ';
   lc_delivery_charge_code VARCHAR2(03) := '   ';
   lc_delivery_date_code   VARCHAR2(03) := '   ';
   lc_max_Capacity	   VARCHAR2(05) := '00000';
   lc_used_Capacity	   VARCHAR2(05) := '00000';
   lc_day_of_week	   VARCHAR2(01) := ' ';
   lc_date_slot		   VARCHAR2(08) := '        ';
   lc_from_time		   VARCHAR2(04) := '    ';
   lc_to_time		   VARCHAR2(04) := '    ';
   lc_created_by           NUMBER       := NULL;
   lc_date_Sent	           VARCHAR2(10) := TO_CHAR(SYSDATE,'YYYYMMDD');
   lc_time_Sent	           VARCHAR2(10) := TO_CHAR(SYSDATE,'HHMM');


   -- +===================================================================+
   -- | Name  : aptshc_log_exceptions                                      |
   -- | Description: This procedure will be responsible to store all      |
   -- |              the exceptions occured during the procees using      |
   -- |              global custom exception handling framework           |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE Aptsch_log_exceptions(  p_error_code        IN  VARCHAR2
                                   , p_error_description IN  VARCHAR2
                                   , p_entity_ref        IN  VARCHAR2
                                   , p_entity_ref_id     IN  PLS_INTEGER
                                  )
   IS

      x_errbuf                    VARCHAR2(1000);
      x_retcode                   VARCHAR2(40);  
      BEGIN
dbms_output.put_line (lc_error_description);
         lrec_exception_obj_type.p_exception_header  := 'OTHERS';
         lrec_exception_obj_type.p_track_code        := 'ATP';
         lrec_exception_obj_type.p_solution_domain   := 'Available to Purchase';
         lrec_exception_obj_type.p_function          := 'AppointmentScheduling';
         lrec_exception_obj_type.p_error_code        := p_error_code;
         lrec_exception_obj_type.p_error_description := p_error_description;
         lrec_exception_obj_type.p_entity_ref        := p_entity_ref;
         lrec_exception_obj_type.p_entity_ref_id     := p_entity_ref_id;
         
         x_errbuf  := lc_error_description;
         x_retcode := lc_error_code;
         --  Perform Global Exception Processing
         xx_om_global_exception_pkg.insert_exception
                                 (  lrec_exception_obj_type
                                  , x_errbuf
                                  , x_retcode 
                                 );

END aptsch_log_exceptions;   

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
                          ) 
   IS
      -- Initialize error code to 'S'uccess
      x_ret_code   VARCHAR2 (40)   := 'S';
      x_err_buf    VARCHAR2 (1000) := 'Success';
      BEGIN
dbms_output.put_line ('entering proc aptsch_insert');
         -- don't reject transaction if created by is null
         IF  p_created_by is null THEN
             lc_created_by := -1;
         END IF;    
         -- Insert the transaction into the log file before any editing for research
         BEGIN
         INSERT INTO  XX_OM_APTSCH_CAL_UPD_AOPS
                            (
                              transaction_type
                             ,inventory_org_id
                             ,zone_id
                             ,ship_to_org_id 
                             ,zip_code
                             ,country
                             ,zone_carrier
                             ,delivery_charge_code
                             ,carrier_ship_method_id
                             ,slot_max_capacity
                             ,used_capacity
                             ,cldr_day_name
                             ,cldr_date
                             ,slot_start_time
                             ,slot_end_time
                             ,created_by
                             ,created_date
                             ,created_time
                            ) VALUES
                            (
                              p_transaction_type          
                             ,p_inventory_org_id          
                             ,p_zone_id                   
                             ,p_ship_to_org_id            
                             ,p_zip_code                   
                             ,p_country                   
                             ,p_zone_carrier                               
                             ,p_delivery_charge_code                       
                             ,p_carrier_ship_method_id               
                             ,p_slot_max_capacity         
                             ,p_used_capacity             
                             ,p_cldr_day_name             
                             ,p_cldr_date                 
                             ,p_slot_start_time           
                             ,p_slot_end_time             
                             ,p_created_by                
                             ,lc_create_date              
                             ,lc_create_time              
                            );  
         EXCEPTION
            WHEN OTHERS THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Error on insert to XX_OM_APTSCH_CAL_UPD_AOPS. '   
                   || p_transaction_type || '.  Date: ' || lc_create_date
                   || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;
                  Aptsch_log_exceptions( lc_error_code        
                                        ,lc_error_description 
                                        ,lc_entity_ref        
                                        ,ln_entity_ref_id     
                                       ); 
         END;
dbms_output.put_line ('insert done');         
         --three parameters are required for all p_transaction_type
         IF lc_error_code = 'S' and
            (p_transaction_type is null OR p_country is null OR 
             p_inventory_org_id is null) 
         THEN
             lc_error_code        := 'E';
             lc_error_description := 'ATP Appt. Sync. Required field is NULL '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;
            Aptsch_log_exceptions( lc_error_code        
                                  ,lc_error_description 
                                  ,lc_entity_ref        
                                  ,ln_entity_ref_id     
                                  );
         END IF; 
            
         IF lc_error_code = 'S' THEN
            -- get AOPS location code from organization_id
            BEGIN 
               SELECT lpad(SUBSTR(attribute1,1,4),4,'0') 
               INTO lc_location_code
               FROM Hr_all_organization_units
               WHERE organization_id = p_inventory_org_id;
            EXCEPTION
            WHEN OTHERS THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Organization ID invalid. '   
                   || p_transaction_type || '.  Date: ' || lc_create_date
                   || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;
                  Aptsch_log_exceptions( lc_error_code        
                                        ,lc_error_description 
                                        ,lc_entity_ref        
                                        ,ln_entity_ref_id     
                                       ); 
            END; 
         END IF;   
         IF lc_error_code = 'S' THEN
            -- determine transaciton type, then execute correct procedure to build
            -- the AOPS transaction from the input parameters
            CASE 
                WHEN p_transaction_type in ('INCUSED', 'DECUSED')
                THEN   
                   AptSch_validate_used
                          ( p_transaction_type          
                           ,p_inventory_org_id          
                           ,p_zone_id                   
                           ,p_ship_to_org_id            
                           ,p_zip_code                   
                           ,p_country                   
                           ,p_zone_carrier                               
                           ,p_delivery_charge_code                       
                           ,p_carrier_ship_method_id                
                           ,p_slot_max_capacity         
                           ,p_used_capacity             
                           ,p_cldr_day_name             
                           ,p_cldr_date                 
                           ,p_slot_start_time           
                           ,p_slot_end_time             
                           ,p_created_by                
                          ); 
                WHEN p_transaction_type in ('ADDMKT', 'CHGMKT', 'DELMKT')
                THEN   
                   AptSch_validate_mkt
                          ( p_transaction_type          
                           ,p_inventory_org_id          
                           ,p_zone_id                   
                           ,p_ship_to_org_id            
                           ,p_zip_code                   
                           ,p_country                   
                           ,p_zone_carrier                                 
                           ,p_delivery_charge_code                       
                           ,p_carrier_ship_method_id               
                           ,p_slot_max_capacity         
                           ,p_used_capacity             
                           ,p_cldr_day_name             
                           ,p_cldr_date                 
                           ,p_slot_start_time           
                           ,p_slot_end_time             
                           ,p_created_by                
                          ); 
                WHEN p_transaction_type in ('ADDZIP', 'CHGZIP', 'DELZIP')
                THEN   
                      AptSch_validate_zip
                          ( p_transaction_type          
                           ,p_inventory_org_id          
                           ,p_zone_id                   
                           ,p_ship_to_org_id            
                           ,p_zip_code                  
                           ,p_country                   
                           ,p_zone_carrier                               
                           ,p_delivery_charge_code                      
                           ,p_carrier_ship_method_id                
                           ,p_slot_max_capacity         
                           ,p_used_capacity             
                           ,p_cldr_day_name             
                           ,p_cldr_date                 
                           ,p_slot_start_time           
                           ,p_slot_end_time             
                           ,p_created_by                
                          ); 
                WHEN p_transaction_type in ('ADDCAL', 'CHGCAL', 'DELCAL')
                THEN   
                      AptSch_validate_cal
                          ( p_transaction_type          
                           ,p_inventory_org_id          
                           ,p_zone_id                   
                           ,p_ship_to_org_id            
                           ,p_zip_code                  
                           ,p_country                   
                           ,p_zone_carrier                              
                           ,p_delivery_charge_code                       
                           ,p_carrier_ship_method_id                
                           ,p_slot_max_capacity         
                           ,p_used_capacity             
                           ,p_cldr_day_name             
                           ,p_cldr_date                 
                           ,p_slot_start_time           
                           ,p_slot_end_time             
                           ,p_created_by                
                          );
                WHEN p_transaction_type in ('ADDFOOT', 'CHGFOOT', 'DELFOOT')
                THEN   
                      AptSch_validate_foot
                          ( p_transaction_type          
                           ,p_inventory_org_id          
                           ,p_zone_id                   
                           ,p_ship_to_org_id           
                           ,p_zip_code                   
                           ,p_country                   
                           ,p_zone_carrier                              
                           ,p_delivery_charge_code                       
                           ,p_carrier_ship_method_id                
                           ,p_slot_max_capacity         
                           ,p_used_capacity             
                           ,p_cldr_day_name             
                           ,p_cldr_date                 
                           ,p_slot_start_time           
                           ,p_slot_end_time             
                           ,p_created_by                
                          );
                WHEN p_transaction_type in ('REBUILD')
                THEN   
                      AptSch_validate_rebuild
                          ( p_transaction_type          
                           ,p_inventory_org_id          
                           ,p_zone_id                   
                           ,p_ship_to_org_id            
                           ,p_zip_code                  
                           ,p_country                   
                           ,p_zone_carrier                               
                           ,p_delivery_charge_code                       
                           ,p_carrier_ship_method_id                
                           ,p_slot_max_capacity         
                           ,p_used_capacity             
                           ,p_cldr_day_name             
                           ,p_cldr_date                 
                           ,p_slot_start_time           
                           ,p_slot_end_time             
                           ,p_created_by                
                          );              
                -- If not one of the transactions in the CASE, then it is invalid
                ELSE
                   lc_error_code        := 'E';
                   lc_error_description := 'ATP Appt. Sync. Error on tran type. '   
                   || p_transaction_type || '.  Date: ' || lc_create_date
                   || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                
                   Aptsch_log_exceptions( lc_error_code        
                                         ,lc_error_description 
                                         ,lc_entity_ref        
                                         ,ln_entity_ref_id     
                                        );                   
                END CASE;    -- Finished looking for the transaction type
             END IF;         -- end "if lc_error_code = 'S'".
      END AptSch_insert;

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
                          )
      IS
         BEGIN

dbms_output.put_line ('in procedure AptSch_Validate_used');
            -- this data is required to build the INCUSED, DECUSED transaction
            IF p_ship_to_org_id is null or
               p_cldr_date is null or 
               p_slot_start_time is null or
               p_slot_end_time is null or
               p_created_by is null 
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                     );
            END IF;
            IF lc_error_code = 'S' THEN
               BEGIN
               -- Get the zip code using the ship_to_org_id
               SELECT distinct SUBSTR(HL.postal_code,1,5) 
               INTO   lc_zip_code
               FROM   hz_cust_accounts        HCA
                     ,hz_cust_acct_sites_all  HCAS
                     ,hz_cust_site_uses_all   HCSU
                     ,hz_party_sites          HPS
                     ,hz_locations            HL
                     ,oe_order_headers_all    OOH
               WHERE  
                     HCA.cust_account_id    = OOH.sold_to_org_id      and
                     HCAS.cust_acct_site_id = HCSU.cust_acct_site_id  and
                     HCSU.site_use_code     = 'SHIP_TO'               and
                     HCSU.site_use_id       = p_ship_to_org_id        and
                     HPS.party_site_id      = HCAS.party_site_id      and
                     HPS.party_id           = HCA.party_id            and
                     HL.location_id         = HPS.location_id;
               EXCEPTION
                  WHEN OTHERS THEN
                  lc_error_code        := 'E';
                  lc_error_description := 'ATP Appt. Sync. Error on ship to org id. '   
                    || p_transaction_type || '.  Date: ' || lc_create_date
                    || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                
                  aptsch_log_exceptions( lc_error_code        
                                        ,lc_error_description 
                                        ,lc_entity_ref        
                                        ,ln_entity_ref_id);                            
               END;
            END IF;
            IF lc_error_code = 'S' THEN
               -- The following fields are not required for INCUSED, DECUSED
               -- so initialize to null
               lc_zone_carrier	       := ' ';
               lc_delivery_charge_code := '   ';
               lc_delivery_date_code   := '   ';
               lc_max_Capacity	       := '00000';
               lc_used_Capacity	       := '00000';
               lc_day_of_week	       := ' ';
               IF lc_zone_description is NULL
               THEN  lc_zone_description := ' ';
               END IF;
               lc_zone_description     := rpad(lc_zone_description,30,' ');
               lc_zone_name            := '          ';
               -- format the date slot and times from the input parameters to the
               -- correct format to send to AOPS
               lc_date_slot	       := TO_CHAR(p_cldr_date,'YYYYMMDD');
               lc_from_time            := lpad(SUBSTR(p_slot_start_time,1,4),4,'0');
               lc_to_time              := lpad(SUBSTR(p_slot_end_time,1,4),4,'0');

               --Send AQ 
               AptSch_send_AQ 
                  ( p_transaction_type	   
                   ,lc_location_code       
                   ,lc_zone_name	   
                   ,lc_zone_description	   
                   ,lc_zip_code		   
                   ,lc_zone_carrier	   
                   ,lc_delivery_charge_code
                   ,lc_delivery_date_code  
                   ,lc_max_Capacity	   
                   ,lc_used_Capacity	   
                   ,lc_day_of_week	   
                   ,lc_date_slot	   
                   ,lc_from_time	   
                   ,lc_to_time
                   ,p_created_by
                   ,lc_create_date	   
                   ,lc_create_time  
                  );  
            END IF;
      END AptSch_validate_used;     -- end "if lc_error_code = 'S'".
                                
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
                          )
      IS                    
         BEGIN
dbms_output.put_line ('in procedure AptSch_Validate_MKT');         
            --  required data for ADDMKT, CHGMKT
            IF  p_transaction_type in ('ADDMKT', 'CHGMKT') and
               (p_zone_id is null or p_zone_carrier is null or
                p_delivery_charge_code is null or
                p_carrier_ship_method_id is null or
                p_created_by is null
               )
            THEN  
               lc_error_code        := 'E'; 
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
dbms_output.put_line ('1-' || lc_error_code || lc_error_description);         
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                    );
            ELSIF   
                -- required data for DELMKT
                p_transaction_type = 'DELMKT' and
               (p_zone_id is null or
                p_created_by is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
dbms_output.put_line ('2-' || lc_error_code || lc_error_description);    
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                    );
            END IF; 
dbms_output.put_line ('out of tran-code ' || lc_error_code);                
            IF lc_error_code = 'S' THEN
dbms_output.put_line ('comparing tran_type ');                 
               -- some data required for ADDMKT, CHGMKT and not for DELMKT
               IF p_transaction_type in('ADDMKT','CHGMKT') THEN
                  lc_zone_carrier         := SUBSTR(p_zone_carrier,1,1);
                  lc_delivery_charge_code := SUBSTR(p_delivery_charge_code,1,3);
                  BEGIN
dbms_output.put_line ('selecting service level ' );                       
                     -- get the delivery charge code and delivery date code if ADD, CHG
                     SELECT SUBSTR(service_level,1,3)
                     INTO   lc_delivery_date_code 
                     FROM   wsh_carrier_ship_methods  
                     WHERE  carrier_ship_method_id = p_carrier_ship_method_id;                       
                     EXCEPTION
                        WHEN OTHERS THEN
                           lc_error_code        := 'E';
                           lc_error_description := 'ATP Appt. Sync. SHIP_METHOD not found. '   
                           || p_transaction_type || '.  Date: ' || lc_create_date
                           || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
dbms_output.put_line ('3-' || lc_error_code || lc_error_description);    
                           aptsch_log_exceptions( lc_error_code        
                                                 ,lc_error_description 
                                                 ,lc_entity_ref        
                                                 ,ln_entity_ref_id     
                                                );
                  END;                                             
               ELSE
                  -- initialize if not  ADD, CHG (then it is DELete)
                  lc_zone_carrier         := ' ';
                  lc_delivery_charge_code := '   ';
                  lc_delivery_date_code   := '   '; 
               END IF;   
               -- following data required by ADD, CHG and DEL
dbms_output.put_line ('Selecting zone');    
               BEGIN
                  -- get the zone name and zone description from zone_id
                  SELECT substr(zone,1,10),
                         substr(alternate_name,1,30)
                  INTO lc_zone_name, lc_zone_description
                  FROM wsh_zone_regions WZR, 
                       wsh_regions_tl   WRT
                  WHERE WZR.zone_region_id = p_zone_id and
                        WRT.region_id = WZR.region_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        lc_error_code        := 'E';
                        lc_error_description := 'ATP Appt. Sync. ZONE not found. '   
                           || p_transaction_type || '.  Date: ' || lc_create_date
                           || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
dbms_output.put_line ('4-' || lc_error_code || lc_error_description);    
                        aptsch_log_exceptions( lc_error_code        
                                              ,lc_error_description 
                                              ,lc_entity_ref        
                                              ,ln_entity_ref_id     
                                             );
               END;                                
               lc_zip_code                := SUBSTR(p_zip_code,1,5);
               -- these fields not needed for this transaction type
               lc_max_capacity	          := '00000';
               lc_used_capacity	          := '00000';
               lc_day_of_week	          := ' ';
               lc_date_slot	          := '        ';
               IF lc_zone_name is NULL
               THEN lc_zone_name := ' ';
               END IF;
               lc_zone_name               := rpad(lc_zone_name,10,' ');
               IF lc_zone_description is NULL
               THEN lc_zone_description := ' ';
               END IF;               
               lc_zone_description        := rpad(lc_zone_description,30,' ');
dbms_output.put_line ('MKT-Sending AQ');                
               --Send AQ 
               AptSch_send_AQ 
                  ( p_transaction_type	   
                   ,lc_location_code       
                   ,lc_zone_name	   
                   ,lc_zone_description	   
                   ,lc_zip_code		   
                   ,lc_zone_carrier	   
                   ,lc_delivery_charge_code
                   ,lc_delivery_date_code  
                   ,lc_max_Capacity	   
                   ,lc_used_Capacity	   
                   ,lc_day_of_week	   
                   ,lc_date_slot	   
                   ,lc_from_time	   
                   ,lc_to_time
                   ,p_created_by
                   ,lc_create_date	   
                   ,lc_create_time  
                  ); 
            END IF;      -- end "if lc_error_code = 'S'"  */   
      END AptSch_validate_mkt;
      
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
                          )    IS         
      
      BEGIN
         dbms_output.put_line ('in procedure AptSch_Validate_zip');
            -- following data is required for this transaction type
            IF (p_zone_id is null or
                p_zip_code is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                    
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                    );
            END IF; 
            IF lc_error_code = 'S' THEN
               BEGIN
                  -- get the zone name and zone description using zone ID
                  SELECT SUBSTR(zone,1,10),
                         SUBSTR(alternate_name,1,30)
                  INTO lc_zone_name, lc_zone_description
                  FROM wsh_zone_regions WZR, 
                       wsh_regions_tl   WRT
                  WHERE WZR.zone_region_id = p_zone_id and
                        WRT.region_id = WZR.region_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        lc_error_code        := 'E';
                        lc_error_description := 'ATP Appt. Sync. ZONE not found. '   
                        || p_transaction_type || '.  Date: ' || lc_create_date
                        || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
                        aptsch_log_exceptions( lc_error_code        
                                              ,lc_error_description 
                                              ,lc_entity_ref        
                                              ,ln_entity_ref_id     
                                             );
               END;
               -- following data not needed except zip code (only first 5 for AOPS)
               IF lc_zone_description is NULL
               THEN lc_zone_description := ' ';
               END IF;               
               lc_zone_description     := rpad(lc_zone_description,30,' ');
               IF lc_zone_name is NULL
               THEN lc_zone_name := ' ';
               END IF;               
               lc_zone_name            := rpad(lc_zone_name,10,' ');
               lc_zip_code             := SUBSTR(p_zip_code,1,5);
               lc_zone_carrier	       := ' ';
               lc_delivery_charge_code := '   ';
               lc_delivery_date_code   := '   ';
               lc_max_Capacity	       := '00000';
               lc_used_Capacity	       := '00000';
               lc_day_of_week	       := ' ';
               lc_date_slot	       := '        ';
               lc_from_time	       := '    ';
               lc_to_time	       := '    ';
               
               --Send AQ 
               AptSch_send_AQ 
                  ( p_transaction_type	   
                   ,lc_location_code       
                   ,lc_zone_name	   
                   ,lc_zone_description	   
                   ,lc_zip_code		   
                   ,lc_zone_carrier	   
                   ,lc_delivery_charge_code
                   ,lc_delivery_date_code  
                   ,lc_max_Capacity	   
                   ,lc_used_Capacity	   
                   ,lc_day_of_week	   
                   ,lc_date_slot	   
                   ,lc_from_time	   
                   ,lc_to_time
                   ,p_created_by
                   ,lc_create_date	   
                   ,lc_create_time  
                  ); 
            END IF;         -- end "if lc_error_code = 'S'".          
      END AptSch_validate_zip;
      
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
                          )
      IS                    
         BEGIN
dbms_output.put_line ('in procedure AptSch_Validate_cal');         
            --  some data required to build transaction ADDCAL, CHGCAL
            IF  p_transaction_type in ('ADDCAL', 'CHGCAL') and
               (p_zone_id is null or 
                p_zip_code is null or 
                p_slot_max_capacity is null or
                p_used_capacity is null or
                p_cldr_date is null or
                p_slot_start_time is null or
                p_slot_end_time is null or
                p_created_by is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                                
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                    );
            ELSIF   
                -- some data required for DELCAL
                p_transaction_type = 'DELCAL' and
               (p_zone_id is null or 
                p_zip_code is null or 
                p_cldr_date is null or 
                p_slot_start_time is null or
                p_slot_end_time is null or
                p_created_by is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                    
                aptsch_log_exceptions( lc_error_code        
                                      ,lc_error_description 
                                      ,lc_entity_ref        
                                      ,ln_entity_ref_id     
                                     );
            END IF; 
            IF lc_error_code = 'S' THEN
               -- get data required for ADDCAL, DELCAL
               IF p_transaction_type in ('ADDCAL','CHGCAL') THEN
                  lc_max_Capacity	 := lpad(p_slot_max_capacity,5,'0');
                  lc_used_Capacity	 := lpad(p_used_capacity,5,'0');
               ELSE 
               -- not needed for DELCAL   
                  lc_max_Capacity	 := '00000';
                  lc_used_Capacity	 := '00000';            
               END IF;
               BEGIN
                  -- get zone name and zone description using zone id
                  SELECT SUBSTR(zone,1,10)  
                  INTO lc_zone_name   
                  FROM wsh_zone_regions WZR, 
                       wsh_regions_tl   WRT
                  WHERE WZR.zone_region_id = p_zone_id and
                        WRT.region_id = WZR.region_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        lc_error_code        := 'E';
                        lc_error_description := 'ATP Appt. Sync. ZONE not found. '   
                        || p_transaction_type || '.  Date: ' || lc_create_date
                        || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
                        aptsch_log_exceptions( lc_error_code        
                                              ,lc_error_description 
                                              ,lc_entity_ref        
                                              ,ln_entity_ref_id     
                                             );
               END; 
               -- this data required for ADDCAL, CHGCAL and DELCAL or is NULL (not required)
               IF lc_zone_description is NULL
               THEN lc_zone_description := ' ';
               END IF;                              
               lc_zone_description       := rpad(lc_zone_description,30,' '); 
               IF lc_zone_name is NULL
               THEN lc_zone_name := ' ';
               END IF;                              
               lc_zone_name              := rpad(lc_zone_name,10,' ');
               lc_zip_code               := SUBSTR(p_zip_code,1,5);
               lc_zone_carrier	         := ' ';
               lc_delivery_charge_code   := '   ';
               lc_delivery_date_code     := '   ';
               lc_day_of_week	         := ' ';
               lc_date_slot	         := TO_CHAR(p_cldr_date,'YYYYMMDD');
               lc_from_time              := lpad(SUBSTR(p_slot_start_time,1,4),4,'0');
               lc_to_time                := lpad(SUBSTR(p_slot_end_time,1,4),4,'0');
               lc_zone_name              := rpad(lc_zone_name,10,' ');


            
               --Send AQ 
               AptSch_send_AQ 
                  ( p_transaction_type	   
                   ,lc_location_code       
                   ,lc_zone_name	   
                   ,lc_zone_description	   
                   ,lc_zip_code		   
                   ,lc_zone_carrier	   
                   ,lc_delivery_charge_code
                   ,lc_delivery_date_code  
                   ,lc_max_Capacity	   
                   ,lc_used_Capacity	   
                   ,lc_day_of_week	   
                   ,lc_date_slot	   
                   ,lc_from_time	   
                   ,lc_to_time
                   ,p_created_by
                   ,lc_create_date	   
                   ,lc_create_time  
                  ); 
                  
            END IF;          -- end "if lc_error_code = 'S'".     
      END AptSch_validate_cal;
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
                          )
      IS                    
         BEGIN
dbms_output.put_line ('in procedure AptSch_Validate_foot');         
            --  some data is required for ADDFOOT, CHGFOOT
            IF  p_transaction_type in ('ADDFOOT', 'CHGFOOT') and
               (p_zone_id is null or 
                p_zip_code is null or 
                p_slot_max_capacity is null or
                p_used_capacity is null or
                p_cldr_day_name  is null or
                p_slot_start_time is null or
                p_slot_end_time is null or 
                p_created_by is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                    
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                    );
            ELSIF   
                -- some data required for DELFOOT
                p_transaction_type = 'DELFOOT' and
               (p_zone_id is null or 
                p_zip_code is null or 
                p_cldr_day_name  is null or 
                p_slot_start_time is null or
                p_slot_end_time is null or 
                p_created_by is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                                
                aptsch_log_exceptions( lc_error_code        
                                      ,lc_error_description 
                                      ,lc_entity_ref        
                                      ,ln_entity_ref_id     
                                     );
            END IF;
            IF lc_error_code = 'S' THEN
               BEGIN
                  -- get zone name and zone description using zone id
                  SELECT SUBSTR(zone,1,10)  
                  INTO lc_zone_name   
                  FROM wsh_zone_regions WZR, 
                       wsh_regions_tl   WRT
                  WHERE WZR.zone_region_id = p_zone_id and
                        WRT.region_id = WZR.region_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        lc_error_code        := 'E';
                        lc_error_description := 'ATP Appt. Sync. ZONE not found. '   
                        || p_transaction_type || '.  Date: ' || lc_create_date
                        || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
                        aptsch_log_exceptions( lc_error_code        
                                              ,lc_error_description 
                                              ,lc_entity_ref        
                                              ,ln_entity_ref_id     
                                             );
               END;               
               -- get data required for ADDFOOT, CHGFOOT
               IF p_transaction_type in('ADDFOOT','CHGFOOT') THEN
                  lc_max_Capacity	    := lpad(p_slot_max_capacity,5,'0');
                  lc_used_Capacity	    := lpad(p_used_capacity,5,'0');
               ELSE  
                  -- if DELCAL initialize these fields
                  lc_max_Capacity       := '00000';
                  lc_used_Capacity      := '00000'; 
               END IF; 
               --convert day of week name to AOPS equivalent
               CASE
                  WHEN p_cldr_day_name = ('Monday') THEN
                     lc_day_of_week := '1';
                  WHEN p_cldr_day_name = ('Tuesday') THEN
                     lc_day_of_week := '2';
                  WHEN p_cldr_day_name = ('Wednesday') THEN
                     lc_day_of_week := '3';
                  WHEN p_cldr_day_name = ('Thursday') THEN
                     lc_day_of_week := '4';
                  WHEN p_cldr_day_name = ('Friday') THEN
                     lc_day_of_week := '5';
                  WHEN p_cldr_day_name = ('Saturday') THEN
                     lc_day_of_week := '6';
                  WHEN p_cldr_day_name = ('Sunday') THEN
                     lc_day_of_week := '7';
                  ELSE
                     -- invalid day of week
                     lc_error_code        := 'E';
                     lc_error_description := 'ATP Appt. Sync. Day of week is invalid. '   
                       || p_transaction_type || '.  Date: ' || lc_create_date
                       || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                                         
                     aptsch_log_exceptions
                        ( lc_error_code        
                         ,lc_error_description 
                         ,lc_entity_ref        
                         ,ln_entity_ref_id     
                        );
               END CASE;  -- finished checking day of week               
               lc_from_time            := lpad(SUBSTR(p_slot_start_time,1,4),4,'0');
               lc_to_time              := lpad(SUBSTR(p_slot_end_time,1,4),4,'0');
               IF lc_zone_description is NULL
               THEN lc_zone_description := ' ';
               END IF;                              
               lc_zone_description      := rpad(lc_zone_description,30,' '); 
               IF lc_zone_name is NULL
               THEN lc_zone_name := ' ';
               END IF;                              
               lc_zone_name             := rpad(lc_zone_description,10,' ');
               --send AQ
               AptSch_send_AQ 
                  ( p_transaction_type	   
                   ,lc_location_code       
                   ,lc_zone_name	   
                   ,lc_zone_description	   
                   ,lc_zip_code		   
                   ,lc_zone_carrier	   
                   ,lc_delivery_charge_code
                   ,lc_delivery_date_code  
                   ,lc_max_Capacity	   
                   ,lc_used_Capacity	   
                   ,lc_day_of_week	   
                   ,lc_date_slot	   
                   ,lc_from_time	   
                   ,lc_to_time
                   ,p_created_by
                   ,lc_create_date	   
                   ,lc_create_time  
                  ); 
            END IF;          -- end "if lc_error_code = 'S'".  
      END AptSch_validate_foot;
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
                          )
      IS        
         BEGIN
dbms_output.put_line ('in procedure AptSch_Rebuild');
            -- some data is required for REBUILD
            IF (p_zone_id is null or 
                p_created_by is null
               )
            THEN
               lc_error_code        := 'E';
               lc_error_description := 'ATP Appt. Sync. Required field is NULL. '   
                 || p_transaction_type || '.  Date: ' || lc_create_date
                 || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                                
               aptsch_log_exceptions( lc_error_code        
                                     ,lc_error_description 
                                     ,lc_entity_ref        
                                     ,ln_entity_ref_id     
                                    );
            END IF;
            IF lc_error_code = 'S' THEN
               BEGIN
                  SELECT SUBSTR(zone,1,10),
                         SUBSTR(alternate_name,1,30)
                  INTO lc_zone_name, lc_zone_description
                  FROM wsh_zone_regions WZR, 
                       wsh_regions_tl   WRT
                  WHERE WZR.zone_region_id = p_zone_id and
                        WRT.region_id = WZR.region_id;
                  EXCEPTION
                     WHEN OTHERS THEN
                        lc_error_code        := 'E';
                        lc_error_description := 'ATP Appt. Sync. ZONE not found. '   
                        || p_transaction_type || '.  Date: ' || lc_create_date
                        || '.  Time: ' || lc_create_time || '.  Created by: ' || p_created_by;                            
                        aptsch_log_exceptions( lc_error_code        
                                              ,lc_error_description 
                                              ,lc_entity_ref        
                                              ,ln_entity_ref_id     
                                             );
               END; 
               -- build data for REBUILD transaction
               lc_zip_code             := '     ';
               lc_zone_carrier	       := ' ';
               lc_delivery_charge_code := '   ';
               lc_delivery_date_code   := '   ';
               lc_date_slot	       := '        ';
               lc_from_time            := '    ';
               lc_to_time              := '    ';
               IF lc_zone_description is NULL
               THEN lc_zone_description := ' ';
               END IF;                              
               lc_zone_description     := rpad(lc_zone_description,30,' '); 
               IF lc_zone_name is NULL
               THEN lc_zone_name := ' ';
               END IF;                              
               lc_zone_name            := rpad(lc_zone_description,10,' ');                
        
               --Send AQ
               AptSch_send_AQ 
                  ( p_transaction_type	   
                   ,lc_location_code       
                   ,lc_zone_name	   
                   ,lc_zone_description	   
                   ,lc_zip_code		   
                   ,lc_zone_carrier	   
                   ,lc_delivery_charge_code
                   ,lc_delivery_date_code  
                   ,lc_max_Capacity	   
                   ,lc_used_Capacity	   
                   ,lc_day_of_week	   
                   ,lc_date_slot	   
                   ,lc_from_time	   
                   ,lc_to_time
                   ,p_created_by
                   ,lc_create_date	   
                   ,lc_create_time  
                  ); 
            END IF;           -- end "if lc_error_code = 'S'".    
                                    
      END AptSch_validate_rebuild;

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
                          ) 
      IS
      -- below, get the transaction type to take up exactly 10 spaces in 
      -- the AQ string
      -- ln_transaction_length NUMBER       := length(p_transaction_type);
      lc_transaction_type   VARCHAR2(10) := rpad(p_transaction_type,
                                                 10,' ');
      --define AQ options
      enqueue_options dbms_aq.enqueue_options_t;
      message_properties dbms_aq.message_properties_t;
--      recipients dbms_aq.aq$_recipient_list_t;
      message_handle RAW(16);
      
      BEGIN
         BEGIN
dbms_output.put_line                       (lc_transaction_type      || ',' || 
                                            lc_location_code        || ',' ||       
                                            lc_zone_name            || ',' || 	     
                                            lc_zone_description     || ',' ||	    
                                            lc_zip_code             ||  ',' || 		     
                                            lc_zone_carrier         ||  ',' || 	     
                                            lc_delivery_charge_code || ',' || 
                                            lc_delivery_date_code   ||  ',' ||   
                                            lc_max_capacity         || ',' ||	     
                                            lc_used_capacity	    || ',' ||     
                                            lc_day_of_week          || ',' ||	     
                                            lc_date_slot            || ',' ||	     
                                            lc_from_time            || ',' ||	     
                                            lc_to_time              || ','); 		    

-- below (NULL,NULL,NULL) is not correct 1st null should be "subscriber" ???
--            recipients(1) := sys.AQ$_AGENT(NULL,NULL,NULL);
--            message_properties.recipient_list := recipients;
--THIS IS A TEST AQ FOR NOW UNTIL THE PRODUCTION ONE IS DEFINED--XX_OM_APPT_SCH_AOPS_Q
            -- ITG request for BPEL AQ in GSI database is 31121
            -- insert the queue entry as string, undelimited  
            dbms_aq.enqueue(queue_name  => 'TEST_QUEUE_MSG_OBJ2_msg'
                    ,enqueue_options    => enqueue_options
                    ,message_properties => message_properties
                    ,payload            => (lc_transaction_type     ||
                                            lc_location_code        ||        
                                            lc_zone_name            || 	     
                                            lc_zone_description     ||	    
                                            lc_zip_code             ||  		     
                                            lc_zone_carrier         ||  	     
                                            lc_delivery_charge_code || 
                                            lc_delivery_date_code   ||    
                                            lc_max_capacity         ||	     
                                            lc_used_capacity	    ||     
                                            lc_day_of_week          ||	     
                                            lc_date_slot            ||	     
                                            lc_from_time            ||	     
                                            lc_to_time              		    
                                           )
                    ,msgid              => message_handle);
               COMMIT;   -- successful       
            EXCEPTION
               WHEN others THEN
                lc_error_code := 'E';
                lc_error_description := 'ATP Appt. Sync. Error on advanced queuing insert';
                aptsch_log_exceptions( lc_error_code        
                                      ,lc_error_description 
                                      ,lc_entity_ref        
                                      ,ln_entity_ref_id     
                                     );
         END;
      END AptSch_send_AQ;

      
END XX_OM_APT_SCH_TO_AOPS_PKG;   
