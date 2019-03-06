SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_ROUTENO_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name  : XX_OM_ROUTENO_PKG.pks                                     |
-- | Rice ID      :I0311_WholesalerRoutingNo                           |
-- | Description      : This package is used to update route number    |
-- |                    obtained from transport web service to the TRIP|
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   17-APR-2007   Francis M        Initial draft version    |
-- |1.0        19-JUN-2007   Hema Chikkanna   Updated the Comments     |
-- |                                          Section as per onsite    |
-- |                                          requirement              |
-- |1.1        29-JUN-2007   Hema Chikkanna   Updated the file name    |
-- |                                          Section as new MD40 Std  |
-- |1.2        25-JUL-2007   Hema Chikkanna   Incorporated the changes |
-- |                                          as per the oniste review |
-- |                                          comments                 |
-- +===================================================================+

   AS
          
    lc_error_code              xx_om_global_exceptions.error_code%TYPE;
    lc_error_description       xx_om_global_exceptions.description%TYPE;
    ln_entity_ref_id           xx_om_global_exceptions.entity_ref_id%TYPE;
    lc_delivery_status         wsh_new_deliveries.attribute1%TYPE := 'ELIGIBLE FOR DOOR AND WAVE UPDATE';
       
-- +===================================================================+
-- | Name  : Write_Exception                                           |
-- | Description :Procedure to log exceptions using                    |
-- |               the Common Exception Handling Framework             |
-- |                                                                   |
-- | Parameters :    p_error_code                                      |
-- |                 p_error_description                               |
-- |                 p_entity_ref_id                                   |
-- | Returns    :                                                      |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_exception ( 
                             p_error_code             IN VARCHAR2,
                             p_error_description      IN VARCHAR2,
                             p_entity_ref_id          IN PLS_INTEGER
                          )
IS

lc_errbuf     VARCHAR2(2000);
lc_retcode    VARCHAR2(100);

BEGIN  
    
    ge_exception.p_error_code        := p_error_code;
    ge_exception.p_error_description := p_error_description;
    ge_exception.p_entity_ref_id     := p_entity_ref_id;
    
    -------------------------------------------------------------------
    -- Call the global exception package to insert the error messages
    -------------------------------------------------------------------
    xx_om_global_exception_pkg.Insert_Exception (
                                                  p_report_exception => ge_exception
                                                 ,x_err_buf          => lc_errbuf
                                                 ,x_ret_code         => lc_retcode
                                               );
END write_exception; 

-- +===================================================================+
-- | Name  : GET_ROUTENO                                               |
-- | Description:       This Procedure will be used to get the route no|
-- |                    from roadnet system                            |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_delivery_id                                  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_region_id                                    |
-- |                    x_location_id                                  |
-- |                    x_location_type                                |
-- |                    x_route_no                                     |
-- |                    x_status                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE get_routeno (
                         p_delivery_id   IN            PLS_INTEGER
                        ,x_region_id     OUT NOCOPY    PLS_INTEGER
                        ,x_location_id   OUT NOCOPY    VARCHAR2
                        ,x_location_type OUT NOCOPY    VARCHAR2
                        ,x_status        OUT NOCOPY    VARCHAR2
                       )
IS

ln_ult_dropoff_location_id       wsh_new_deliveries.ultimate_dropoff_location_id%TYPE;
lc_process_status                wsh_new_deliveries.attribute1%TYPE;
lc_roadnet_flag                  wsh_trips.attribute3%TYPE;
lc_b2b_status                    wsh_new_deliveries.attribute3%TYPE;


lc_err_msg                       VARCHAR2(4000);

--------------------------------------------------------
-- Cursor to check the delivery if eligible for roadnet
--------------------------------------------------------

CURSOR  lcu_delivery IS
SELECT  WND.ultimate_dropoff_location_id 
       ,WND.attribute1  -- DFF to check for Eligibilty for Roadnet 
       ,WND.attribute3  -- BB delivery creation DFF
       ,WT.attribute2   -- Roadnet Flag 
FROM    wsh_new_deliveries          WND,
        wsh_delivery_legs           WDL,
        wsh_trip_stops              WTSP,
        wsh_trip_stops              WTSD,
        wsh_trips                   WT
WHERE   WND.delivery_id          =   WDL.delivery_id
AND     WDL.pick_up_stop_id      =   WTSP.stop_id 
AND     WDL.drop_off_stop_id     =   WTSD.stop_id 
AND     WTSD.trip_id             =   WT.trip_id
AND     WTSP.trip_id             =   WT.trip_id
AND     WND.delivery_id          =   p_delivery_id;

-----------
-- Cursor to select the 4 digit region id for the given delivery
----------
CURSOR lcu_regionid IS
   SELECT XIOLRA.location_number_sw location
   FROM   wsh_new_deliveries              WND
         ,hr_locations                    HL
         ,mtl_parameters                  MP
         ,xx_inv_org_loc_rms_attribute    XIOLRA
   WHERE  XIOLRA.combination_id           = MP.attribute6
   AND    WND.initial_pickup_location_id  = HL.location_id    
   AND    HL.inventory_organization_id    = MP.organization_id
   AND    WND.delivery_id                 = p_delivery_id;
   
  
------
-- Location 1
-- Cursor to select location id for the given delivery
-- Open Issue
------

------
-- Location 2
-- Cursor to select location type for the given delivery
-- Open Issue
------

BEGIN

   ln_ult_dropoff_location_id   := NULL;
   lc_process_status            := NULL;
   lc_roadnet_flag              := NULL;
   lc_b2b_status                := NULL;
   x_status                     := NULL;


   FOR l_delivery IN lcu_delivery
   LOOP
      
      ln_ult_dropoff_location_id := l_delivery.ultimate_dropoff_location_id;
      lc_process_status          := l_delivery.attribute1;
      lc_roadnet_flag            := l_delivery.attribute2;
      lc_b2b_status              := l_delivery.attribute2;
      
      
      IF lc_process_status = 'ELIGIBLE FOR ROADNET ROUTING'
         AND lc_roadnet_flag ='Y'
            AND lc_b2b_status = 'BB Delivery Creation'  THEN
            
                FOR l_regionid IN lcu_regionid
                LOOP
                     
                     x_region_id := l_regionid.location;
                     
                END LOOP;
                
      END IF;
      
   END LOOP; 
   

EXCEPTION

   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
       lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR';
       lc_error_description := FND_MESSAGE.GET;   
       ln_entity_ref_id     := p_delivery_id;  
       x_status             :='E';
       
       ----------------------------------
       -- Call write exception procedure
       ----------------------------------
       write_exception( p_error_code          => lc_error_code
                       ,p_error_description   => lc_error_description
                       ,p_entity_ref_id       => ln_entity_ref_id);
  
   

END get_routeno;


-- +===================================================================+
-- | Name  : TRIP_UPDATE                                               |
-- | Description:       This Procedure will be used to update the      |
-- |                    Route Number for a Delivery Trip               |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_trip_name                                    |
-- |                    p_route_no                                     |
-- |                    p_delivery_id                                  |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          x_error                                        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE    trip_update( 
                          p_delivery_id          IN  PLS_INTEGER
                         ,p_trip_name            IN  VARCHAR2
                         ,p_route_no             IN  VARCHAR2
                         ,x_error                OUT NOCOPY VARCHAR2
                        )
IS
ln_api_version          PLS_INTEGER:= 1;
ln_count                PLS_INTEGER;
lc_data                 VARCHAR2(4000);
lc_status               VARCHAR2(1);
lr_trip_info            wsh_trips_pub.trip_pub_rec_type;
lc_trip_name            wsh_trips.name%TYPE;
ln_trip_id              wsh_trips.trip_id%TYPE;
lc_error_msg            VARCHAR2(4000);
lc_comments             VARCHAR2(400);

BEGIN

    lc_error_code       := NULL;
    lc_error_description:= NULL; 
    ln_entity_ref_id    := 0;

    FND_MSG_PUB.INITIALIZE;  
    
    lr_trip_info.attribute1   :=  p_route_no;
    
    -------------------
    --TRIP UPDATE API
    -------------------
    
    WSH_TRIPS_PUB.CREATE_UPDATE_TRIP ( 
                                        p_api_version_number   =>  ln_api_version
                                       ,p_init_msg_list        =>  FND_API.G_FALSE
                                       ,x_return_status        =>  lc_status
                                       ,x_msg_count            =>  ln_count
                                       ,x_msg_data             =>  lc_data
                                       ,p_action_code          =>  'UPDATE'
                                       ,p_trip_info            =>  lr_trip_info
                                       ,p_trip_name            =>  p_trip_name
                                       ,x_trip_id              =>  ln_trip_id
                                       ,x_trip_name            =>  lc_trip_name
                                     );  
                                     
    IF (lc_status = FND_API.G_RET_STS_SUCCESS) THEN 
        x_error:=NULL; 
    ELSIF   (lc_status = FND_API.G_RET_STS_ERROR) THEN    
        IF (ln_count >= 1) THEN
            FOR I IN 1..ln_count
            LOOP
                lc_error_msg    :=   SUBSTR(FND_MSG_PUB.GET(p_msg_index => i,p_encoded => FND_API.G_FALSE),1,255);
                lc_comments     :=   'wsh_trips_pub.create_update_trip';
            END LOOP;
        END IF;
        x_error:= lc_comments||':-'||lc_error_msg;
    END IF;        

EXCEPTION

   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
       lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR';
       lc_error_description := FND_MESSAGE.GET;   
       ln_entity_ref_id     := p_delivery_id;  
       
       ----------------------------------
       -- Call write exception procedure
       ----------------------------------
       write_exception( p_error_code          => lc_error_code
                       ,p_error_description   => lc_error_description
                       ,p_entity_ref_id       => ln_entity_ref_id);
       
       
       
END trip_update;

-- +===================================================================+
-- | Name  : log_delivery_status                                       |
-- | Description:       This Procedure will be updating the process    |
-- |                    status for the delivery in wsh_new_deliveries, |
-- |                    to identify the exact state of the processing. |
-- | Parameters                                                        |
-- | IN        :        p_delivery_id                                  |
-- |                    p_process_status                               |
-- | Returns   :        x_status                                       |
-- |                                                                   |
-- +===================================================================+

PROCEDURE log_delivery_status( 
                                p_delivery_id     IN  wsh_new_deliveries.delivery_id%TYPE
                               ,p_process_status  IN  wsh_new_deliveries.attribute1%TYPE
                               ,x_status          OUT NOCOPY VARCHAR2
                             )
  
AS

   
   lc_name                         VARCHAR2(4000);
   ln_delivery_id                  wsh_new_deliveries.delivery_id%TYPE;
   delivery_info_rec_type          wsh_deliveries_pub.delivery_pub_rec_type;
   
   lc_return_status                VARCHAR2(40);
   ln_msg_count                    PLS_INTEGER;
   lc_msg_data                     VARCHAR2(2000);
  
  BEGIN
    
    lc_return_status              := NULL;
    ln_msg_count                  := NULL;
    lc_msg_data                   := NULL;
    lc_error_code                 := NULL;
    lc_error_description          := NULL;
    ln_entity_ref_id              := 0;


    
    delivery_info_rec_type.delivery_id      :=  p_delivery_id;
    delivery_info_rec_type.attribute1       :=  p_process_status;
    
    WSH_DELIVERIES_PUB.Create_Update_Delivery( 
                                               p_api_version_number   => 1.0,
                                               p_init_msg_list        => FND_API.G_TRUE,
                                               x_return_status        => lc_return_status,
                                               x_msg_count            => ln_msg_count,
                                               x_msg_data             => lc_msg_data,
                                               p_action_code          => 'UPDATE',
                                               p_delivery_info        => delivery_info_rec_type,
                                               p_delivery_name        => FND_API.G_NULL_CHAR,
                                               x_delivery_id          => ln_delivery_id,
                                               x_name                 => lc_name
                                             );
    
    IF TRIM(UPPER(lc_return_status)) <> TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN 
       x_status      := lc_return_status;
    ELSIF  TRIM(UPPER(lc_return_status)) = TRIM(UPPER(FND_API.G_RET_STS_SUCCESS)) THEN
       COMMIT;
       x_status      := lc_return_status;
    END IF;  

  EXCEPTION
  
      WHEN OTHERS THEN
         x_status             := FND_API.G_RET_STS_UNEXP_ERROR;
         FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
         FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
         FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
         lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR';
         lc_error_description := FND_MESSAGE.GET;
         ln_entity_ref_id     := p_delivery_id;

         ----------------------------------   
         -- Call write exception procedure
         ----------------------------------

         write_exception( p_error_code          => lc_error_code
                         ,p_error_description   => lc_error_description
                         ,p_entity_ref_id       => ln_entity_ref_id);

  END log_delivery_status; 

-- +===================================================================+
-- | Name  : UPDATE_ROUTENO                                            |
-- | Description:       This Procedure will be used to update          |
-- |                    Status                                         |
-- |                                                                   |
-- |                                                                   |
-- | Parameters:        p_delivery_id                                  |
-- |                    p_status                                       |
-- |                                                                   |
-- | Returns :          None                                           |
-- |                                                                   |
-- +===================================================================+

PROCEDURE   update_routeno( 
                            p_delivery_id  IN  PLS_INTEGER
                           ,p_route_no     IN  VARCHAR2 
                           ,x_error_msg    OUT NOCOPY VARCHAR2
                          )
IS

lc_error_msg         VARCHAR2(4000);
lc_trip_name         wsh_trips.name%TYPE; 
lc_otm_route         wsh_trips.attribute1%TYPE;
lc_route_no          VARCHAR2(40);
lc_status            VARCHAR2(1);

---------------------------------
-- Cursor to select Trip Details
---------------------------------
CURSOR  lcu_trip IS
SELECT  WT.name
       ,WT.attribute1  
FROM    wsh_new_deliveries          WND,
        wsh_delivery_legs           WDL,
        wsh_trip_stops              WTSP,
        wsh_trip_stops              WTSD,
        wsh_trips                   WT
WHERE   WND.delivery_id          =   WDL.delivery_id
AND     WDL.pick_up_stop_id      =   WTSP.stop_id 
AND     WDL.drop_off_stop_id     =   WTSD.stop_id 
AND     WTSD.trip_id             =   WT.trip_id
AND     WTSP.trip_id             =   WT.trip_id
AND     WND.delivery_id          =   p_delivery_id;


BEGIN

   lc_error_code          := NULL;
   lc_error_description   := NULL; 
   ln_entity_ref_id       := 0;

   lc_trip_name           := NULL;
   lc_otm_route           := NULL;
   lc_route_no            := NULL;
   lc_status              := NULL;
   x_error_msg            := NULL;
   
   FOR l_trip IN lcu_trip
   LOOP
      lc_trip_name  := l_trip.name;
      lc_otm_route  := l_trip.attribute1;
      
   END LOOP;   

   IF p_route_no IS NOT NULL
      AND p_route_no <> '0000'
         AND  LENGTH(TRIM(TRANSLATE(p_route_no, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ' '))) IS NOT NULL   THEN

               lc_route_no := p_route_no;   

   ELSIF p_route_no IS NULL 
      OR p_route_no  =   '0000'
          OR  LENGTH(TRIM(TRANSLATE(p_route_no, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', ' '))) IS  NULL   THEN
          
            /* Location 3: The default value '0777' for the route number to be replaced with
              'OD_WSH_TransportationSuite_Default_Route_Id' profile value once 
               it is set up in apps */
               
              lc_route_no := '0777';
   END IF;
   
   ---------------------------------------------------------
   -- Call the trip update procedure to update route number
   ----------------------------------------------------------
   trip_update(
                p_delivery_id  => p_delivery_id
               ,p_trip_name    => lc_trip_name
               ,p_route_no     => lc_route_no
               ,x_error        => lc_error_msg
              );

        IF  lc_error_msg IS NOT NULL THEN 

            ----------------------------------
            -- Call write exception procedure
            ----------------------------------

            write_exception( p_error_code          => 'XX_OM_65136_WSH_API_ERROR'
                            ,p_error_description   => lc_error_msg
                            ,p_entity_ref_id       => p_delivery_id );
                            
            x_error_msg := lc_error_msg;                 
        ELSE
            ------------------------------------------
            -- Update the delivery status
            -- to 'ELIGIBLE FOR DOOR AND WAVE UPDATE'
            ------------------------------------------
            log_delivery_status( 
                                 p_delivery_id     => p_delivery_id
                                ,p_process_status  => lc_delivery_status
                                ,x_status          => lc_status
                               );
                               
        END IF;



EXCEPTION
   WHEN OTHERS THEN 
       FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');
       FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',SQLERRM);
       lc_error_code        := 'XX_OM_65100_UNEXPECTED_ERROR';
       lc_error_description := FND_MESSAGE.GET;   
       ln_entity_ref_id     := p_delivery_id;
       x_error_msg          := lc_error_description;

       ----------------------------------   
       -- Call write exception procedure
       ----------------------------------
       
       write_exception( p_error_code          => lc_error_code
                       ,p_error_description   => lc_error_description
                       ,p_entity_ref_id       => ln_entity_ref_id);

END update_routeno;


END XX_OM_ROUTENO_PKG;
/

SHOW ERRORS;

EXIT;
