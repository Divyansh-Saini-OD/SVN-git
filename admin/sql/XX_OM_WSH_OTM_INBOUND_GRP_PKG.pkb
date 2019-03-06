SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_om_wsh_otm_inbound_grp_pkg
/* $Header: /home/cvs/repository/Office_Depot/SRC/OTC/E0280_CarrierSelection/3.\040Source\040Code\040&\040Install\040Files/XX_OM_WSH_OTM_INBOUND_GRP_PKG.pkb,v 1.5 2007/07/26 10:07:23 vvtamil Exp $ */

-- +===========================================================================+
-- |                      Office Depot - Project Simplify                      |
-- |                    Oracle NAIO Consulting Organization                    |
-- +===========================================================================+
-- | Name        : XX_OM_WSH_OTM_INBOUND_GRP                                   |
-- | Rice ID     : E0280_CarrierSelection                                      |
-- | Description :                                                             |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version   Date        Author                 Remarks                       |
-- |=======   ==========  ===================    ==============================|
-- |DRAFT 1A 13-Apr-2007  Faiz                   Initial draft version         |
-- |1.1      20-Jun-2007  Pankaj Kapse           Made changes as per new       |
-- |                                             standard                      |
-- |                                                                           |
-- +===========================================================================+
AS
   --
   -- Global Variables
   --
   g_pkg_name  CONSTANT VARCHAR2(30) := 'XX_OM_WSH_OTM_INBOUND_GRP_PKG';
   l_debug_msg VARCHAR2(5000);

   TYPE WSH_OTM_DEL_INTERFACE IS RECORD (
                                         delivery_interface_id     NUMBER
                                        ,leg_created_flag          VARCHAR2(1)
                                        );

   TYPE WSH_OTM_DEL_INTERFACES IS TABLE OF WSH_OTM_DEL_INTERFACE INDEX BY VARCHAR2(32767);

   TYPE WSH_OTM_STOP_INTERFACES IS TABLE OF NUMBER INDEX BY VARCHAR2(32767);

   -- +===================================================================+
   -- | Name        : Write_Exception                                     |
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
      ln_retcode   NUMBER;

   BEGIN                               -- Procedure Block

      ge_exception.p_error_code        := p_error_code;
      ge_exception.p_error_description := p_error_description;
      ge_exception.p_entity_ref        := p_entity_reference;
      ge_exception.p_entity_ref_id     := p_entity_ref_id;

      xxod_global_exception_pkg.Insert_Exception (
                                                   ge_exception
                                                  ,lc_errbuf
                                                  ,ln_retcode
                                                 );

   END Write_Exception;                -- End Procedure Block

   -- +===================================================================+
   -- | Name        : initiate_planned_shipment                           |
   -- | Description : Procedure used to takes a table of trip records to  |
   -- |               process.Processes the trip and children stops,      |
   -- |               releases and legs and inserts into the WSH Interface|
   -- |               tables and then launches the WSHOTMRL concurrent    |
   -- |               program                                             |
   -- |                                                                   |
   -- | Parameters :  p_int_trip_info                                     |
   -- |                                                                   |
   -- | Return     :  x_output_request_id                                 |
   -- |               x_return_status                                     |
   -- |               x_msg_count                                         |
   -- |               x_msg_data                                          |
   -- +===================================================================+

   PROCEDURE initiate_planned_shipment( p_int_trip_info      IN   XX_OM_WSH_OTM_TRIP_TAB,
                                        x_output_request_id  OUT  NOCOPY NUMBER,
                                        x_return_status      OUT  NOCOPY VARCHAR2,
                                        x_msg_count          OUT  NOCOPY NUMBER,
                                        x_msg_data           OUT  NOCOPY VARCHAR2) IS

      CURSOR c_get_del_revision(c_delivery_id IN NUMBER) IS
      SELECT tms_version_number,name
      FROM  wsh_new_deliveries
      WHERE delivery_id = c_delivery_id;


      i                                NUMBER := 0;
      j                                NUMBER;
      k                                NUMBER;
      l                                NUMBER;
      m                                NUMBER;
      p                                NUMBER;
      q                                NUMBER;
      t                                NUMBER;
      l_count                          NUMBER;
      l_skip_trip                      BOOLEAN := FALSE;
      l_tp_plan_name                   WSH_UTIL_CORE.column_tab_type;
      l_carrier_id                     WSH_UTIL_CORE.id_tab_type;
      l_mode_of_transport              WSH_UTIL_CORE.column_tab_type;
      l_service_level                  WSH_UTIL_CORE.column_tab_type;
      l_freight_terms_code             WSH_UTIL_CORE.column_tab_type;
      l_vehicle_item_id                WSH_UTIL_CORE.id_tab_type;
      l_vehicle_item_name              WSH_UTIL_CORE.column_tab_type;
      l_vehicle_number                 WSH_UTIL_CORE.column_tab_type;
      l_vehicle_number_prefix          WSH_UTIL_CORE.column_tab_type;
      l_vessel                         WSH_UTIL_CORE.column_tab_type;
      l_voyage_number                  WSH_UTIL_CORE.column_tab_type;
      l_stop_location_id               WSH_UTIL_CORE.column_tab_type;
      l_stop_sequence_number           WSH_UTIL_CORE.id_tab_type;
      l_stop_timezone_code             WSH_UTIL_CORE.column_tab_type;
      l_stop_trip_int_id               WSH_UTIL_CORE.column_tab_type;
      /*
      l_stop_pa_date                   WSH_UTIL_CORE.column_tab_type;
      l_stop_pd_date                   WSH_UTIL_CORE.column_tab_type;
      l_stop_aa_date                   WSH_UTIL_CORE.column_tab_type;
      l_stop_ad_date                   WSH_UTIL_CORE.column_tab_type;
      */

      l_stop_pa_date                   WSH_UTIL_CORE.date_tab_type;
      l_stop_pd_date                   WSH_UTIL_CORE.date_tab_type;
      l_stop_aa_date                   WSH_UTIL_CORE.date_tab_type;
      l_stop_ad_date                   WSH_UTIL_CORE.date_tab_type;

      l_delivery_name                  WSH_UTIL_CORE.column_tab_type;
      l_release_xid                    WSH_UTIL_CORE.column_tab_type;
      l_ship_from_location_xid         WSH_UTIL_CORE.column_tab_type;
      l_ship_to_location_xid           WSH_UTIL_CORE.column_tab_type;
      /*
      l_earliest_pickup_date           WSH_UTIL_CORE.column_tab_type;
      l_latest_pickup_date             WSH_UTIL_CORE.column_tab_type;
      l_earliest_dropoff_date          WSH_UTIL_CORE.column_tab_type;
      l_latest_dropoff_date            WSH_UTIL_CORE.column_tab_type;
      */
      l_earliest_pickup_date           WSH_UTIL_CORE.date_tab_type;
      l_latest_pickup_date             WSH_UTIL_CORE.date_tab_type;
      l_earliest_dropoff_date          WSH_UTIL_CORE.date_tab_type;
      l_latest_dropoff_date            WSH_UTIL_CORE.date_tab_type;

      l_release_refnum                 WSH_UTIL_CORE.column_tab_type;
      l_release_freight_cost           WSH_UTIL_CORE.column_tab_type;
      l_release_freight_currency       WSH_UTIL_CORE.column_tab_type;
      l_release_freight_del_id         WSH_UTIL_CORE.column_tab_type;
      l_release_freight_dint_id        WSH_UTIL_CORE.id_tab_type;

      l_delivery_tab                   WSH_TMS_RELEASE.delivery_tab;
      l_dummy_del_id_tab               WSH_UTIL_CORE.id_tab_type;
      l_return_status                  VARCHAR2(1);

      l_delivery_id                    VARCHAR2(32767) := NULL;
      l_local_release_tab              WSH_OTM_DEL_INTERFACES;
      l_stop_loc_tab                   WSH_OTM_STOP_INTERFACES;

      l_interface_act_code             VARCHAR2(30) := WSH_TMS_RELEASE.g_tms_release_code;
      l_del_refnum                     NUMBER := NULL;
      l_del_id_number                  NUMBER := 0;
      l_release_id                     VARCHAR2(100);
      l_dleg_pu_loc_id                 VARCHAR2(100);
      l_dleg_do_loc_id                 VARCHAR2(100);
      l_del_revision_number            NUMBER := 0;
      l_fc_count                       NUMBER := 0;
      l_int_del_cnt                    NUMBER := 0;
      l_int_stop_cnt                   NUMBER := 0;

      l_dleg_int_act_code              WSH_UTIL_CORE.column_tab_type;
      l_dleg_del_id                    WSH_UTIL_CORE.column_tab_type;
      l_dleg_del_int_id                WSH_UTIL_CORE.id_tab_type;
      l_dleg_pustop_id                 WSH_UTIL_CORE.id_tab_type;
      l_dleg_dostop_id                 WSH_UTIL_CORE.id_tab_type;
      l_group_id                       NUMBER ;
      l_request_id                     NUMBER ;
      l_user_id                        NUMBER;
      l_resp_id                        NUMBER;

      --l_process_trip_cnt               NUMBER := 0;
      l_cnt                            NUMBER := p_int_trip_info.COUNT;
      l_inp_count                      VARCHAR2(30) := 'p_int_trip_info COUNT '||p_int_trip_info.COUNT;
      l_stop_count                     NUMBER := 1;
      l_release_count                  NUMBER := 1;
      l_ship_unit_count                NUMBER := 1;
      l_del_int_id_tab                 WSH_UTIL_CORE.id_tab_type;
      l_trip_int_id                    WSH_UTIL_CORE.id_tab_type;
      l_stop_int_id_tab                WSH_UTIL_CORE.id_tab_type;

      l_debug_on                       CONSTANT BOOLEAN := WSH_DEBUG_SV.is_debug_enabled;
      l_module_name                    CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'initiate_planned_shipment';

      --The new columns added are been declared--Added BY Faiz Mohammad.B
      l_itinerary_id                   WSH_UTIL_CORE.column_tab_type;
      l_mobilecast_flag                WSH_UTIL_CORE.column_tab_type;
      l_roadnet_flag                   WSH_UTIL_CORE.column_tab_type;

      -- Added to handle exception
      lc_errbuf                        VARCHAR2(4000);
      ln_err_code                      NUMBER;


      lc_process_further_flag VARCHAR2(1);
          --End
   BEGIN

      x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

      IF l_debug_on THEN
        WSH_DEBUG_SV.push (l_module_name);
        WSH_DEBUG_SV.logmsg(l_module_name,'-------------- START ----------------');
        WSH_DEBUG_SV.logmsg(l_module_name,'p_int_trip_info COUNT  : '||l_cnt);
      END IF;


      SAVEPOINT before_insert;

      l_user_id := FND_PROFILE.value('WSH_OTM_DEFAULT_APPS_USER');
      l_resp_id := FND_PROFILE.value('WSH_OTM_DEFAULT_APPS_RESP');

      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Profile User Id : '||l_user_id);
        WSH_DEBUG_SV.logmsg(l_module_name,'Profile Responsibility Id : '||l_resp_id);
        WSH_DEBUG_SV.logmsg(l_module_name,'Calling FND_GLOBAL.APPS_INITIALIZE ');
      END IF;

      -- security_group_id is optional
      --fnd_global.apps_initialize(l_user_id,l_resp_id,l_resp_appl_id,l_security_group_id);


      FND_GLOBAL.APPS_INITIALIZE(l_user_id,l_resp_id,660);


      /*

         -- Construct delivery legs for groups of ship units
            -- shipunit -> (pick first one) shipunitcontent -> release xid
         -- How to derive group_id for this transaction ?
            -- new sequence
         -- where to store incoming vehicle item name ?
            -- create a new column in trips_interface
         -- populate interface action code
         -- populate trips, stops, deliveries, legs and freight costs interface tables

      */

      l_delivery_tab.DELETE;
      l_ship_unit_count := 0;

      i := p_int_trip_info.FIRST;

      IF i IS NOT NULL THEN
      LOOP
         l_skip_trip := FALSE;

         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'current trip record is  i = '||i);
            WSH_DEBUG_SV.logmsg(l_module_name,'p_int_trip_info.shipment_stops COUNT  : '||p_int_trip_info(i).shipment_stops.COUNT);
            WSH_DEBUG_SV.logmsg(l_module_name,'p_int_trip_info.shipment_releases COUNT  : '||p_int_trip_info(i).shipment_releases.COUNT);
            WSH_DEBUG_SV.logmsg(l_module_name,'p_int_trip_info.shipment_ship_units COUNT  : '||p_int_trip_info(i).shipment_ship_units.COUNT);
            WSH_DEBUG_SV.logmsg(l_module_name,'p_int_trip_info.stop_locations. COUNT  : '||p_int_trip_info(i).stop_locations.COUNT);
         END IF;

         -- Call anshuman's API to derive list of EBS delivery ids and versions for the input tp_plan_name for a trip
         -- Check versions for each of the deliveries in a trip
            -- Error out / Skip a trip if any delivery in a trip has a version less than that of the EBS version
            -- What to do if all trips fail version check ?
            -- no need to launch concurrent program

         -- Returns x_delivery_tab.COUNT = 0 if WSH trip corresponding to p_tp_plan_name does not exist
         -- In that case will have to query delivery by delivery to derive revision number

         --IF NVL(p_int_trip_info(i).transaction_code,'CREATE') <> 'DELETE' THEN

         IF NVL(p_int_trip_info(i).transaction_code,'CREATE') <> 'D' THEN

            WSH_TMS_RELEASE.find_deliveries_for_trip(
                            p_trip_id              =>  NULL,
                            p_tp_plan_name         =>  p_int_trip_info(i).shipment_xid,
                            x_delivery_tab         =>  l_delivery_tab,
                            x_delivery_id_tab      =>  l_dummy_del_id_tab,
                            x_return_status        =>  l_return_status);

            IF l_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR,WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
            ELSE
               IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Returned from WSH_TMS_RELEASE.FIND_DELIVERIES_FOR_TRIP x_return_status : '||l_return_status);
                 WSH_DEBUG_SV.logmsg(l_module_name,'l_delivery_tab.COUNT : '||l_delivery_tab.COUNT);
               END IF;

            END IF;


            -- This API will return an assciative array indexed by delivery_id
            -- This record structure has revision_number

         -- Delete all tables of local release/delivery
         l_local_release_tab.DELETE;
         l_del_int_id_tab.DELETE;
         l_release_xid.DELETE;
         l_ship_from_location_xid.DELETE;
         l_ship_to_location_xid.DELETE;
         l_release_refnum.DELETE;
         l_earliest_pickup_date.DELETE;
         l_latest_pickup_date.DELETE;
         l_earliest_dropoff_date.DELETE;
         l_latest_dropoff_date.DELETE;
         l_release_freight_cost.delete;
         l_release_freight_currency.delete;
         l_fc_count := 0;
         l_del_refnum := NULL;
         l_del_revision_number := NULL;

         l := p_int_trip_info(i).shipment_releases.FIRST;

         IF l IS NOT NULL THEN
            LOOP

              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'current release record is  l = '||l);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Release_xid  : '||p_int_trip_info(i).shipment_releases(l).release_xid);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Release_refnum  : '||p_int_trip_info(i).shipment_releases(l).release_refnum);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Early Pickup Date  : '||p_int_trip_info(i).shipment_releases(l).early_pickup_date);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Late Pickup Date  : '||p_int_trip_info(i).shipment_releases(l).late_pickup_date);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Early Delivery Date  : '||p_int_trip_info(i).shipment_releases(l).early_delivery_date);
                 WSH_DEBUG_SV.logmsg(l_module_name,'Late Delivery Date  : '||p_int_trip_info(i).shipment_releases(l).late_delivery_date);
                 WSH_DEBUG_SV.logmsg(l_module_name,'p_int_trip_info.shipment_releases.release_freight_costs COUNT  : '||p_int_trip_info(i).shipment_releases(l).release_freight_costs.COUNT);
              END IF;

              -- Derive delivery's revision_number if could not be defined for the trip earlier

              l_del_id_number := TO_NUMBER(p_int_trip_info(i).shipment_releases(l).release_xid);

              IF l_delivery_tab.COUNT = 0 OR (NOT l_delivery_tab.EXISTS(p_int_trip_info(i).shipment_releases(l).release_xid)) THEN

                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'l_del_id_number : '||l_del_id_number);
                    WSH_DEBUG_SV.logmsg(l_module_name,'Opening c_get_del_revision for release_xid '||p_int_trip_info(i).shipment_releases(l).release_xid);
                 END IF;

                 OPEN c_get_del_revision(l_del_id_number);
                 FETCH c_get_del_revision INTO l_del_revision_number,l_delivery_name(l);

                 IF c_get_del_revision%NOTFOUND THEN
                    IF l_debug_on THEN
                       WSH_DEBUG_SV.logmsg(l_module_name,'WSH revision not found for release_xid : '||p_int_trip_info(i).shipment_releases(l).release_xid);
                       WSH_DEBUG_SV.logmsg(l_module_name,'Skipping this trip ');
                    END IF;

                    l_skip_trip := TRUE;

                    CLOSE c_get_del_revision;

                    EXIT;


                 END IF;

                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'l_del_revision_number : '||l_del_revision_number);
                    WSH_DEBUG_SV.logmsg(l_module_name,'l_del_name : '||l_delivery_name(l));
                 END IF;

                 CLOSE c_get_del_revision;

              ELSE
                 l_del_revision_number := l_delivery_tab(p_int_trip_info(i).shipment_releases(l).release_xid).tms_version_number;
                 l_delivery_name(l)    := l_delivery_tab(p_int_trip_info(i).shipment_releases(l).release_xid).name;
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'l_del_revision_number : '||l_del_revision_number);
                    WSH_DEBUG_SV.logmsg(l_module_name,'l_del_name : '||l_delivery_name(l));
                 END IF;
              END IF;


              l_del_refnum := TO_NUMBER(p_int_trip_info(i).shipment_releases(l).release_refnum);

              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'l_del_refnum : '||l_del_refnum);
              END IF;


              IF NVL(l_del_refnum,0) < NVL(l_del_revision_number,0) THEN
                 l_skip_trip := TRUE;
                 EXIT;
              END IF;

              l_delivery_id := p_int_trip_info(i).shipment_releases(l).release_xid;

              -- Create a local delivery record type  l_local_release_tab indexed by delivery_id with attributes
              -- delivery_interface_id and leg_created_flag

              l_local_release_tab(l_delivery_id).delivery_interface_id := NULL;
              l_local_release_tab(l_delivery_id).leg_created_flag      := 'N';

              l_release_xid(l)            := p_int_trip_info(i).shipment_releases(l).release_xid;

              l_ship_from_location_xid(l) := substrb(p_int_trip_info(i).shipment_releases(l).ship_from_location_xid,instrb(p_int_trip_info(i).shipment_releases(l).ship_from_location_xid,'-',1,2) + 1);

              l_ship_to_location_xid(l)   := substrb(p_int_trip_info(i).shipment_releases(l).ship_to_location_xid,instrb(p_int_trip_info(i).shipment_releases(l).ship_to_location_xid,'-',1,2) + 1);

              l_earliest_pickup_date(l)   := TO_DATE(p_int_trip_info(i).shipment_releases(l).early_pickup_date,'YYYYMMDDHH24MISS');
              l_latest_pickup_date(l)     := TO_DATE(p_int_trip_info(i).shipment_releases(l).late_pickup_date,'YYYYMMDDHH24MISS');
              l_earliest_dropoff_date(l)  := TO_DATE(p_int_trip_info(i).shipment_releases(l).early_delivery_date,'YYYYMMDDHH24MISS');
              l_latest_dropoff_date(l)    := TO_DATE(p_int_trip_info(i).shipment_releases(l).late_delivery_date,'YYYYMMDDHH24MISS');
              l_release_refnum(l)         := p_int_trip_info(i).shipment_releases(l).release_refnum;


              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Populated release record structure ');
                 WSH_DEBUG_SV.logmsg(l_module_name,'l_release_xid  : '||l_release_xid(l));
              END IF;

              -- LOOP over freight cost records for a release
              -- create wsh_fc_interface record structures
              --l_release_freight_cost(l) := 0;
              p := p_int_trip_info(i).shipment_releases(l).release_freight_costs.FIRST;
              IF p IS NOT NULL THEN
                 LOOP
                    l_fc_count := l_fc_count + 1;

                    IF l_debug_on THEN
                      WSH_DEBUG_SV.logmsg(l_module_name,'current freight cost record is  p = '||p);
                      WSH_DEBUG_SV.logmsg(l_module_name,'for shipment_xid  : '||p_int_trip_info(i).shipment_releases(l).release_freight_costs(p).shipment_xid);
                    END IF;
                    -- Insert each record

                    l_release_freight_del_id(l_fc_count) := p_int_trip_info(i).shipment_releases(l).release_xid;
                    l_release_freight_cost(l_fc_count) := p_int_trip_info(i).shipment_releases(l).release_freight_costs(p).monetary_amount;
                    l_release_freight_currency(l_fc_count) := p_int_trip_info(i).shipment_releases(l).release_freight_costs(p).currency_code;

                    EXIT WHEN p = p_int_trip_info(i).shipment_releases(l).release_freight_costs.LAST;
                    p := p_int_trip_info(i).shipment_releases(l).release_freight_costs.NEXT(p);


                 END LOOP;
              END IF;

              EXIT WHEN l = p_int_trip_info(i).shipment_releases.LAST;
              l := p_int_trip_info(i).shipment_releases.NEXT(l);

            END LOOP;
         END IF;

         IF l_skip_trip THEN

            IF l_debug_on THEN

                 WSH_DEBUG_SV.logmsg(l_module_name,'Skipping this trip ');
            END IF;

            GOTO next_trip;


         END IF;

         ELSE
            l_interface_act_code := WSH_TMS_RELEASE.g_tms_delete_code;
         END IF; -- Transaction_code <> 'DELETE'

         --l_process_trip_cnt := l_process_trip_cnt + 1;
         -- Call purge_interface_tables API :
         -- Delete if any record exits in interface tables for the input deliveries
         -- What about the exceptions for those deliveries ?  -- This API takes care

         WSH_TMS_RELEASE.purge_interface_data(
                                              p_tp_plan_name          =>  p_int_trip_info(i).shipment_xid,
                                              p_commit_flag           =>  'N',
                                              x_return_status         =>  l_return_status
                                           );

         IF l_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR,WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR) THEN
                   RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
         END IF;

         --IF NVL(p_int_trip_info(i).transaction_code,'CREATE') <> 'DELETE' THEN
         IF NVL(p_int_trip_info(i).transaction_code,'CREATE') <> 'D' THEN

         -- Bulk insert delivery interface records here
         -- returning delivery_interface_id s BULK COLLECT INTO l_del_int_id_tab
         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Bulk Inserting into wsh_new_del_interface ');
         END IF;

         FORALL j IN p_int_trip_info(i).shipment_releases.FIRST .. p_int_trip_info(i).shipment_releases.LAST
            INSERT INTO  WSH_NEW_DEL_INTERFACE
                 (DELIVERY_INTERFACE_ID,
                  INTERFACE_ACTION_CODE,
                  DELIVERY_ID,
                  NAME,
                  PLANNED_FLAG,
                  STATUS_CODE,
                  INITIAL_PICKUP_LOCATION_ID,
                  ULTIMATE_DROPOFF_LOCATION_ID,
                  EARLIEST_PICKUP_DATE,
                  LATEST_PICKUP_DATE,
                  EARLIEST_DROPOFF_DATE,
                  LATEST_DROPOFF_DATE,
                  DELIVERY_TYPE,
                  TMS_VERSION_NUMBER,
                  CREATION_DATE,
                  CREATED_BY,
                  LAST_UPDATE_DATE,
                  LAST_UPDATED_BY)
            VALUES (WSH_NEW_DEL_INTERFACE_S.NEXTVAL,
                    l_interface_act_code,
                    l_release_xid(j),
                    l_delivery_name(j),
                    'Y',
                    'OP',
                    l_ship_from_location_xid(j),
                    l_ship_to_location_xid(j),
                    l_earliest_pickup_date(j),
                    l_latest_pickup_date(j),
                    l_earliest_dropoff_date(j),
                    l_latest_dropoff_date(j),
                    'STANDARD',
                    l_release_refnum(j),
                    SYSDATE,
                    1,
                    SYSDATE,
                    1)
            RETURNING DELIVERY_INTERFACE_ID BULK COLLECT INTO l_del_int_id_tab;

         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'interface id count l_del_int_id_tab : '||l_del_int_id_tab.COUNT);
         END IF;

         -- Create an associative array of delivery_interface_id s indexed by delivery_id
         --     Populate l_local_release_tab
         l_int_del_cnt := 0;
         l := p_int_trip_info(i).shipment_releases.FIRST;

         IF l IS NOT NULL THEN
            LOOP

              l_int_del_cnt := l_int_del_cnt + 1;
              l_local_release_tab(p_int_trip_info(i).shipment_releases(l).release_xid).delivery_interface_id := l_del_int_id_tab(l_int_del_cnt);
              l_local_release_tab(p_int_trip_info(i).shipment_releases(l).release_xid).leg_created_flag := 'N';

              IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Creating local release for release_xid : '||p_int_trip_info(i).shipment_releases(l).release_xid);
                 WSH_DEBUG_SV.logmsg(l_module_name,'delivery_interface_id : '||l_local_release_tab(p_int_trip_info(i).shipment_releases(l).release_xid).delivery_interface_id);
                 WSH_DEBUG_SV.logmsg(l_module_name,'leg_created_flag : '||l_local_release_tab(p_int_trip_info(i).shipment_releases(l).release_xid).leg_created_flag);
              END IF;

              EXIT WHEN l = p_int_trip_info(i).shipment_releases.LAST;
              l := p_int_trip_info(i).shipment_releases.NEXT(l);
            END LOOP;
         END IF;

         IF l_fc_count > 0 THEN
            FOR p IN 1 .. l_fc_count
               LOOP
                  l_release_freight_dint_id(p) := l_local_release_tab(l_release_freight_del_id(p)).delivery_interface_id;
            END LOOP;
         END IF;

         -- Bulk insert fc interface record by deriving delivery_interface_id s for each of the record
         -- from the above associative array

         IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'Inserting into wsh_freight_costs_inetrface ');
         END IF;

         FORALL j IN 1 .. l_fc_count
            INSERT INTO WSH_FREIGHT_COSTS_INTERFACE
                        (FREIGHT_COST_INTERFACE_ID,
                         INTERFACE_ACTION_CODE,
                         UNIT_AMOUNT,
                         TOTAL_AMOUNT,
                         CURRENCY_CODE,
                         DELIVERY_ID,
                         DELIVERY_INTERFACE_ID,
                         CREATION_DATE,
                         CREATED_BY,
                         LAST_UPDATE_DATE,
                         LAST_UPDATED_BY)
            VALUES
                   (WSH_FREIGHT_COSTS_INTERFACE_S.nextval,
                    l_interface_act_code,
                    l_release_freight_cost(j),
                    l_release_freight_cost(j),
                    l_release_freight_currency(j),
                    l_release_freight_del_id(j),
                    l_release_freight_dint_id(j),
                    SYSDATE,
                    1,
                    SYSDATE,
                    1);

         END IF; -- Transaction_code <> 'DELETE'


         l_tp_plan_name(i) := p_int_trip_info(i).shipment_xid;


         l_carrier_id(i) := substrb(p_int_trip_info(i).service_provider_xid,5);


         l_mode_of_transport(i) := p_int_trip_info(i).transport_mode_xid;

         l_service_level(i) := p_int_trip_info(i).rate_service_xid;


         l_freight_terms_code(i) := p_int_trip_info(i).payment_code_xid;

         --l_vehicle_item_name(i) := p_int_trip_info(i).equipment_xid;
         l_vehicle_item_name(i) := p_int_trip_info(i).equipment_group_xid;


         l_vehicle_number(i) := p_int_trip_info(i).equipment_number;


         l_vehicle_number_prefix(i) := p_int_trip_info(i).equipment_initial;


         l_vessel(i) := p_int_trip_info(i).vessel_xid;


         l_voyage_number(i) := p_int_trip_info(i).voyage_xid;

         --The following has been added by FAIZ MOHAMMAD.B for Carrier Selection
         l_itinerary_id(i) := p_int_trip_info(i).ITINERARY_ID;


         l_mobilecast_flag(i) :=p_int_trip_info(i).MOBILECAST_FLAG;


         l_roadnet_flag(i) := p_int_trip_info(i).ROADNET_FLAG;
         --End

         --The following has been added by FAIZ MOHAMMAD.B for Carrier Selection
         --Check for Mobile Cast and Road Net Flag for Valid Value--
         IF (l_mobilecast_flag(i) = 'Y' AND l_roadnet_flag(i) = 'N')
            OR (l_mobilecast_flag(i) = 'N' AND l_roadnet_flag(i) = 'Y') THEN
        --End
         -- Insert the trip_interface here returning the trip_interface_id into l_trip_int_id(i)

         IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'Inserting into wsh_trips interface ');
         END IF;

         INSERT INTO  WSH_TRIPS_INTERFACE
                 (TRIP_INTERFACE_ID,
                  INTERFACE_ACTION_CODE,
                  NAME,
                  GROUP_ID,
                  TP_PLAN_NAME,
                  CARRIER_ID,
                  MODE_OF_TRANSPORT,
                  SERVICE_LEVEL,
                  FREIGHT_TERMS_CODE,
                  VEHICLE_ITEM_NAME,
                  VEHICLE_NUMBER,
                  VEHICLE_NUM_PREFIX,
                  --VESSEL,
                  --VOYAGE_NUMBER,
                  CREATION_DATE,
                  CREATED_BY,
                  LAST_UPDATE_DATE,
                  LAST_UPDATED_BY,
                  --The following has been added by FAIZ MOHAMMAD.B for Carrier Selection
                  ATTRIBUTE1,
                  ATTRIBUTE2,
                  ATTRIBUTE3)
         VALUES (WSH_TRIPS_INTERFACE_S.NEXTVAL,
                  l_interface_act_code,
                  NULL,
                  NVL(l_group_id,WSH_TRIPS_INTERFACE_GROUP_S.NEXTVAL),
                  l_tp_plan_name(i),
                  l_carrier_id(i),
                  l_mode_of_transport(i),
                  l_service_level(i),
                  l_freight_terms_code(i),
                  l_vehicle_item_name(i),
                  l_vehicle_number(i),
                  l_vehicle_number_prefix(i),
                  --l_vessel(i),
                  --l_voyage_number(i),
                  SYSDATE,
                  1,
                  SYSDATE,
                  1,
                  --The following has been added by FAIZ MOHAMMAD.B for Carrier Selection
                  l_itinerary_id(i),
                  l_mobilecast_flag(i),
                  l_roadnet_flag(i)
                  )
         RETURNING TRIP_INTERFACE_ID,GROUP_ID INTO l_trip_int_id(i),l_group_id;


         --The following has been added by FAIZ MOHAMMAD.B for Carrier Selection
      lc_process_further_flag :='Y';--setting the process flag and insert only if MobileCast and roadnet flag has 'Y' OR 'N' values.

      END IF;--IF l_mobilecast_flag(i) = 'N' AND l_roadnet_flag(i) = 'Y' THEN
          --End

          IF l_debug_on THEN
            WSH_DEBUG_SV.logmsg(l_module_name,'interface id l_trip_int_id(i) : '||l_trip_int_id(i));
            WSH_DEBUG_SV.logmsg(l_module_name,'group id  : '||l_group_id);
          END IF;

          --IF NVL(p_int_trip_info(i).transaction_code,'CREATE') <> 'DELETE' THEN
          IF NVL(p_int_trip_info(i).transaction_code,'CREATE') <> 'D' THEN

          -- Delete stop tables
          l_stop_loc_tab.DELETE;
          l_stop_int_id_tab.DELETE;
          l_stop_location_id.DELETE;
          l_stop_sequence_number.DELETE;
          l_stop_trip_int_id.DELETE;
          l_stop_pa_date.DELETE;
          l_stop_pd_date.DELETE;
          l_stop_aa_date.DELETE;
          l_stop_ad_date.DELETE;

          k := p_int_trip_info(i).shipment_stops.FIRST;

          IF k IS NOT NULL THEN
             LOOP
               -- Need to insert trip_interface_id
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'current stop record is  k = '||k);
                  WSH_DEBUG_SV.logmsg(l_module_name,'stop_location_xid  : '||p_int_trip_info(i).shipment_stops(k).stop_location_xid);
                  WSH_DEBUG_SV.logmsg(l_module_name,'stop_sequence_number  : '||p_int_trip_info(i).shipment_stops(k).stop_sequence_number);
                  WSH_DEBUG_SV.logmsg(l_module_name,'pa_date  : '||p_int_trip_info(i).shipment_stops(k).planned_arrival_time);
                  WSH_DEBUG_SV.logmsg(l_module_name,'pd_date  : '||p_int_trip_info(i).shipment_stops(k).planned_departure_time);
                  WSH_DEBUG_SV.logmsg(l_module_name,'aa_date  : '||p_int_trip_info(i).shipment_stops(k).actual_arrival_time);
                  WSH_DEBUG_SV.logmsg(l_module_name,'ad_date  : '||p_int_trip_info(i).shipment_stops(k).actual_departure_time);
               END IF;

               l_stop_location_id(k) := substrb(p_int_trip_info(i).shipment_stops(k).stop_location_xid,instrb(p_int_trip_info(i).shipment_stops(k).stop_location_xid,'-',1,2) + 1);
               l_stop_sequence_number(k) := p_int_trip_info(i).shipment_stops(k).stop_sequence_number;
               l_stop_trip_int_id(k) := l_trip_int_id(i);

               -- Timezone conversion
               -- Create timezone_code as a new column in wsh_trip_stops_interface

               -- LOOP over p_int_trip_info(i).locations
               -- IF LocationGid.Xid matches stop_location_xid THEN store Address.TimeZoneGid.Xid of that record as TimezoneCode
               -- Exit LOOP

               t := p_int_trip_info(i).stop_locations.FIRST;
               IF t IS NOT NULL THEN
                  LOOP
                    IF l_debug_on THEN
                       WSH_DEBUG_SV.logmsg(l_module_name,'tz location xid : '||p_int_trip_info(i).stop_locations(t).location_xid);
                    END IF;
                    IF p_int_trip_info(i).stop_locations(t).location_xid = p_int_trip_info(i).shipment_stops(k).stop_location_xid THEN
                       l_stop_timezone_code(k) := p_int_trip_info(i).stop_locations(t).timezone_xid;
                       IF l_debug_on THEN
                          WSH_DEBUG_SV.logmsg(l_module_name,'Stop timezone_xid : '||l_stop_timezone_code(k));
                       END IF;
                       EXIT;
                    END IF;

                    EXIT WHEN t = p_int_trip_info(i).stop_locations.LAST;
                    t := p_int_trip_info(i).stop_locations.NEXT(t);
                  END LOOP;
               END IF;

               l_stop_pa_date(k) := to_date(p_int_trip_info(i).shipment_stops(k).planned_arrival_time,'YYYYMMDDHH24MISS');
               l_stop_pd_date(k) := to_date(p_int_trip_info(i).shipment_stops(k).planned_departure_time,'YYYYMMDDHH24MISS');

               l_stop_aa_date(k) := to_date(p_int_trip_info(i).shipment_stops(k).actual_arrival_time,'YYYYMMDDHH24MISS');
               l_stop_ad_date(k) := to_date(p_int_trip_info(i).shipment_stops(k).actual_departure_time,'YYYYMMDDHH24MISS');

               EXIT WHEN k = p_int_trip_info(i).shipment_stops.LAST;
               k := p_int_trip_info(i).shipment_stops.NEXT(k);
            END LOOP;
          END IF;

          --END IF;--IF l_mobilecast_flag(i) = 'Y' AND l_roadnet_flag(i) = 'N' THEN
      --END IF;--IF l_mobilecast_flag(i) = 'N' AND l_roadnet_flag(i) = 'Y' THEN
          -- Bulk insert stop interface records here
          -- returning stop_interface_id s BULK COLLECT INTO l_stop_int_id_tab

        --Checking for the condition that the Mobile Cast flag and Roadnet flag has 'Y' OR 'N' VALUES..
        -- only then inserting into WSH_TRIP_STOPS_INTERFACE
        --The following has been added by FAIZ MOHAMMAD.B for Carrier Selection
        IF lc_process_further_flag ='Y' THEN
        --End
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'Inserting into wsh_trip_stops_interface ');
          END IF;

          FORALL j IN p_int_trip_info(i).shipment_stops.FIRST .. p_int_trip_info(i).shipment_stops.LAST
             INSERT INTO  WSH_TRIP_STOPS_INTERFACE
                  (STOP_INTERFACE_ID,
                   INTERFACE_ACTION_CODE,
                   TRIP_INTERFACE_ID,
                   STOP_LOCATION_ID,
                   STOP_SEQUENCE_NUMBER,
                   TIMEZONE_CODE,
                   PLANNED_ARRIVAL_DATE,
                   PLANNED_DEPARTURE_DATE,
                   CREATION_DATE,
                   CREATED_BY,
                   LAST_UPDATE_DATE,
                   LAST_UPDATED_BY)
             VALUES (WSH_TRIP_STOPS_INTERFACE_S.nextval,
                     l_interface_act_code,
                     l_stop_trip_int_id(j),
                     l_stop_location_id(j),
                     l_stop_sequence_number(j),
                     l_stop_timezone_code(j),
                     l_stop_pa_date(j),
                     l_stop_pd_date(j),
                     SYSDATE,
                     1,
                     SYSDATE,
                     1)
             Returning STOP_INTERFACE_ID BULK COLLECT into l_stop_int_id_tab;

        END IF;--IF lc_process_further_flag ='Y' THEN
          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'interface id count l_stop_int_id_tab : '||l_stop_int_id_tab.COUNT);
          END IF;

          -- Create an associative array of stop_interface_id s indexed by stop_location_id
          -- l_stop_loc_tab

          l_int_stop_cnt := 0;

          k := p_int_trip_info(i).shipment_stops.FIRST;

          IF k IS NOT NULL THEN
             LOOP

               l_int_stop_cnt := l_int_stop_cnt + 1;


               l_stop_loc_tab(p_int_trip_info(i).shipment_stops(k).stop_location_xid) := l_stop_int_id_tab(l_int_stop_cnt);
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'stop_location_xid : '||p_int_trip_info(i).shipment_stops(k).stop_location_xid);
                  WSH_DEBUG_SV.logmsg(l_module_name,'l_stop_loc_tab data : '||l_stop_loc_tab(p_int_trip_info(i).shipment_stops(k).stop_location_xid));
               END IF;

               EXIT WHEN k = p_int_trip_info(i).shipment_stops.LAST;
               k := p_int_trip_info(i).shipment_stops.NEXT(k);

             END LOOP;

          END IF;

          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'Created l_stop_loc_tab : '||l_stop_loc_tab.COUNT);
          END IF;



          m := p_int_trip_info(i).shipment_ship_units.FIRST;
          IF m IS NOT NULL THEN
             LOOP
                -- Construct delivery legs for groups of ship units
                -- shipunit -> (pick first one) shipunitcontent -> release xid


                l_release_id := p_int_trip_info(i).shipment_ship_units(m).release_xid;


                l_dleg_pu_loc_id := p_int_trip_info(i).shipment_ship_units(m).ship_from_location_xid;


                l_dleg_do_loc_id := p_int_trip_info(i).shipment_ship_units(m).ship_to_location_xid;




                IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'shipunit count  : '||m);
                  WSH_DEBUG_SV.logmsg(l_module_name,'ship_unit_xid : '||p_int_trip_info(i).shipment_ship_units(m).ship_unit_xid);
                  WSH_DEBUG_SV.logmsg(l_module_name,'l_release_id : '||l_release_id);
                  WSH_DEBUG_SV.logmsg(l_module_name,'l_dleg_pu_loc_id : '||l_dleg_pu_loc_id);
                  WSH_DEBUG_SV.logmsg(l_module_name,'l_dleg_do_loc_id : '||l_dleg_do_loc_id);
                END IF;


                -- 0. Skip the current ship_unit if the leg created flag for this ship_unit's delivery_id is Yes

                IF l_local_release_tab(l_release_id).leg_created_flag = 'Y' THEN
                   IF l_debug_on THEN
                      WSH_DEBUG_SV.logmsg(l_module_name,'Skipping as alreasy created shunit xid : '||p_int_trip_info(i).shipment_ship_units(m).ship_unit_xid);
                   END IF;
                   GOTO next_shipunit;
                END IF;

                IF l_debug_on THEN
                   WSH_DEBUG_SV.logmsg(l_module_name,'Using shunit xid : '||p_int_trip_info(i).shipment_ship_units(m).ship_unit_xid);
                END IF;

                l_ship_unit_count := l_ship_unit_count + 1;



                -- 1. derive delivery_interface_id from delivery_id associative array

                l_dleg_int_act_code(l_ship_unit_count) := l_interface_act_code;
                l_dleg_del_int_id(l_ship_unit_count) := l_local_release_tab(l_release_id).delivery_interface_id;
                l_dleg_del_id(l_ship_unit_count) := l_release_id;


                IF l_debug_on THEN
                   WSH_DEBUG_SV.logmsg(l_module_name,'After Using l_local_release_tab ');
                END IF;


                -- 2. derive stop_interface_id from location_id associative array

               l_dleg_pustop_id(l_ship_unit_count) := l_stop_loc_tab(l_dleg_pu_loc_id);

                 --dbms_output.put_line('Stage50.1.1.a - before modification: '||l_stop_loc_tab.last);
                --l_stop_loc_tab(l_ship_unit_count) := l_dleg_do_loc_id;
                --dbms_output.put_line('Stage50.1.1.b - after modification: '||l_stop_loc_tab.last);
                l_dleg_dostop_id(l_ship_unit_count) := l_stop_loc_tab(l_dleg_do_loc_id);

                --dbms_output.put_line('satge 50.1.2 ship_to_loc_id: '||l_dleg_dostop_id(l_ship_unit_count));



                --dbms_output.put_line('satge 50.2'||l_debug_msg);
                IF l_debug_on THEN
                   WSH_DEBUG_SV.logmsg(l_module_name,'After Using l_stop_loc_tab ');
                END IF;


                -- 3. Mark the leg created flag for the current delivery_id as Yes

                l_local_release_tab(l_release_id).leg_created_flag :=  'Y';

               <<next_shipunit>>

               EXIT WHEN m = p_int_trip_info(i).shipment_ship_units.LAST;
               m := p_int_trip_info(i).shipment_ship_units.NEXT(m);
             END LOOP;
          END IF;

          IF l_debug_on THEN
             WSH_DEBUG_SV.logmsg(l_module_name,'Out of ship_units loop l_ship_unit_count : '||l_ship_unit_count);
          END IF;

          END IF; -- Transaction_code <> 'DELETE'
          <<next_trip>>

          EXIT WHEN i = p_int_trip_info.LAST;
          i := p_int_trip_info.NEXT(i);

       END LOOP;

       END IF;


       IF l_ship_unit_count > 0 THEN

       -- Bulk insert into wsh_del_legs_interface
       IF l_debug_on THEN
          WSH_DEBUG_SV.logmsg(l_module_name,'Inserting into wsh_del_legs_interface ');
       END IF;

       FORALL j IN 1 .. l_ship_unit_count
          INSERT INTO  WSH_DEL_LEGS_INTERFACE
               (
                DELIVERY_LEG_INTERFACE_ID,
                INTERFACE_ACTION_CODE,
                DELIVERY_ID,
                DELIVERY_INTERFACE_ID,
                PICK_UP_STOP_INTERFACE_ID,
                DROP_OFF_STOP_INTERFACE_ID,
                CREATION_DATE,
                CREATED_BY,
                LAST_UPDATE_DATE,
                LAST_UPDATED_BY
                )
          VALUES(
                  WSH_DEL_LEGS_INTERFACE_S.nextval,
                  l_dleg_int_act_code(j),
                  l_dleg_del_id(j),
                  l_dleg_del_int_id(j),
                  l_dleg_pustop_id(j),
                  l_dleg_dostop_id(j),
                  SYSDATE,
                  1,
                  SYSDATE,
                  1
                );
       END IF; -- l_ship_unit_count > 0

       COMMIT;
       --END IF;--IF l_mobilecast_flag(i) = 'Y' AND l_roadnet_flag(i) = 'N' THEN
    --END IF;--IF l_mobilecast_flag(i) = 'N' AND l_roadnet_flag(i) = 'Y' THEN

       -- Launch Anshuman's concurrent program passing l_group_id as input
       -- Launch only if atleast 1 trip was processed into interface table
       IF l_group_id IS NOT NULL THEN

           IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Calling program unit FND_REQUEST.Submit_Request',WSH_DEBUG_SV.C_PROC_LEVEL);
               WSH_DEBUG_SV.log(l_module_name,'Current Time is ',SYSDATE);
            END IF;
            l_request_id := FND_REQUEST.Submit_Request(
                                                         application => 'WSH',
                                                         program     => 'WSHOTMRL',
                                                         argument1   => l_group_id
                                                      );

            IF l_request_id = 0 THEN
               -- If request submission failed, exit with error.
               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'Request submission failed ');
               END IF;
               x_msg_data := FND_MESSAGE.GET_STRING('WSH','WSH_OTM_IB_CONC_ERROR');
               --x_msg_data := 'Concurrent Request submission failed';
               x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
            ELSE
               x_output_request_id := l_request_id;

               IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'Request '||l_request_id||' submitted successfully');
               END IF;
            END IF;

       ELSE
               x_msg_data := FND_MESSAGE.GET_STRING('WSH','WSH_OTM_IB_NO_ELIG_DLVY');
               --x_msg_data := 'No Eligible Deliveries Found';
               x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;

       END IF; -- l_group_id IS NOT NULL

       IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Returning x_return_status : '|| x_return_status);
         WSH_DEBUG_SV.logmsg(l_module_name,'-------------- END ----------------');
         WSH_DEBUG_SV.pop(l_module_name);
       END IF;

      --END IF;--IF l_mobilecast_flag(i) = 'Y' AND l_roadnet_flag(i) = 'N' THEN
    --END IF;--IF l_mobilecast_flag(i) = 'N' AND l_roadnet_flag(i) = 'Y' THEN

   EXCEPTION
   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO SAVEPOINT before_insert;
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR ;
      --

      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.logmsg(l_module_name,'-------------- END ----------------');
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:FND_API.G_EXC_UNEXPECTED_ERROR');
      END IF;
      --
      x_msg_data := 'Oracle error message in UE is '|| SQLERRM;
   WHEN OTHERS THEN
      ROLLBACK TO SAVEPOINT before_insert;
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
      x_msg_data      := 'Oracle error message in WO is '|| SQLERRM;
      WSH_UTIL_CORE.default_handler('WSH_OTM_INBOUND_GRP.initiate_planned_shipment');
      --
      IF l_debug_on THEN
        WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
        WSH_DEBUG_SV.logmsg(l_module_name,'-------------- END ----------------');
        WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:FND_API.G_EXC_UNEXPECTED_ERROR');
      END IF;

      FND_MESSAGE.SET_NAME('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      FND_MESSAGE.SET_TOKEN('ERROR_CODE',SQLCODE);
      FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE',x_msg_data);

      lc_errbuf   := FND_MESSAGE.GET;
      ln_err_code := FND_MESSAGE.GET_NUMBER('XXOM','XX_OM_65100_UNEXPECTED_ERROR');

      -- -------------------------------------
      -- Call the Write_Exception procedure to
      -- insert into Global Exception Table
      -- -------------------------------------

      Write_Exception (
                       p_error_code        => ln_err_code
                      ,p_error_description => lc_errbuf
                      ,p_entity_reference  => 'Error in initiate_planned_shipment procedure '
                      ,p_entity_ref_id     => l_del_id_number
                      );


   END initiate_planned_shipment;

END xx_om_wsh_otm_inbound_grp_pkg;
/
SHOW ERRORS;