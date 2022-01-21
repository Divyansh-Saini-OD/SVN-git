SET SHOW        OFF;
SET VERIFY      OFF;
SET ECHO        OFF;
SET TAB         OFF;
SET FEEDBACK    OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_OM_WSH_OTM_OUTBOUND_PKG AS

-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |                      Oracle NAIO Consulting Organization                                |
-- +=========================================================================================+
-- | Name   : XX_OM_WSH_OTM_OUTBOUND_PKG                                                     |
-- | RICE ID: E0271_EBSOTMDataMap                                                            |
-- | Description      : Package Body containing procedure for Delivery Information extraction|
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   30-Jan-2007       Shashi Kumar     Initial Draft Version                      |
-- |                                                                                         |
-- |1.0        22-Jun-07         Shashi Kumar     Based lined after testing                  |
-- +=========================================================================================+

--===================
-- CONSTANTS
--===================
-- declare debug variables
l_debug_on BOOLEAN;
l_debugfile     VARCHAR2(2000);

-- +===================================================================+
-- | Name       :  get_del_details                                     |
-- | Description:  This Procedure will be used delivery detail         |
-- |               assignment                                          |
-- | Parameters :  XX_OM_WSH_OTM_DET_TAB is the input rec type.        |
-- | returns    :  XX_OM_WSH_OTM_DET_TAB  Extracted Item Info          |
-- +===================================================================+

PROCEDURE get_del_details(p_all_details   IN  XX_OM_WSH_OTM_DET_TAB,
                          p_delivery_id   IN  NUMBER,
                          x_del_details   IN OUT  NOCOPY XX_OM_WSH_OTM_DET_TAB) IS

l_sub_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_DEL_DETAILS';

BEGIN
  -- Debug
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_sub_module_name);
  END IF;

  FOR i IN 1..p_all_details.COUNT LOOP
  --{
    IF p_all_details(i).delivery_id = p_delivery_id THEN
        x_del_details.EXTEND;
        x_del_details(x_del_details.COUNT) := p_all_details(i);
    END IF;
    IF x_del_details.COUNT >0 AND  p_all_details(i).delivery_id <> p_delivery_id THEN
        EXIT;
    END IF;
  --}
  END LOOP;

  IF l_debug_on THEN
      WSH_DEBUG_SV.pop(l_sub_module_name);
  END IF;

EXCEPTION

WHEN FND_API.G_EXC_ERROR THEN
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' FND_API.G_EXC_ERROR',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:FND_API.G_EXC_ERROR');
       END IF;
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' FND_API.G_EXC_UNEXPECTED_ERROR',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:FND_API.G_EXC_UNEXPECTED_ERROR');
       END IF;
  WHEN OTHERS THEN
       wsh_util_core.default_handler('WSH_OTM_OUTBOUND.GET_DEL_DETAILS',l_sub_module_name);
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' OTHERS',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:OTHERS');
       END IF;
END;

-- +===================================================================+
-- | Name       :  GET_TRIP_OBJECTS                                    |
-- | Description:  This Procedure will be used get the Trip, Trip Stop,|
-- | delivery,delivery details and Lpn info                            |
-- |                                                                   |
-- | Parameters : Inputs/Outputs:                                      |
-- |            p_trip_id_tab - id table (list of Trip Ids)            |
-- |            p_user_id     - User Id to set the context             |
-- |            p_resp_id     - Resp Id to set the context             |
-- |            p_resp_appl_id    - Resp Appl Id to set the context    |
-- |           Output:                                                 |
-- |            x_domain_name         - domain name                    |
-- |            x_otm_user_name       - otm User Name                  |
-- |            x_otm_pwd             - otm Password                   |
-- |            x_otm_pwd             - otm Password                   |
-- |            x_trip_tab            - Nested Table which contains    |
-- |                                    the trip info                  |
-- |            x_error_trip_id_tab   - List of ids for which the      |
-- |                                    data could not be retrieved    |
-- +===================================================================+

PROCEDURE GET_TRIP_OBJECTS(p_trip_id_tab        IN OUT NOCOPY   WSH_OTM_ID_TAB,
                   p_user_id        IN      NUMBER,
                   p_resp_id        IN      NUMBER,
                   p_resp_appl_id       IN      NUMBER,
                   x_domain_name        OUT NOCOPY  VARCHAR2,
                   x_otm_user_name      OUT NOCOPY  VARCHAR2,
                   x_otm_pwd        OUT NOCOPY  VARCHAR2,
                   x_server_tz_code     OUT NOCOPY  VARCHAR2,
                   x_trip_tab       OUT NOCOPY  WSH_OTM_TRIP_TAB,
                   x_dlv_tab        OUT NOCOPY  XX_OM_WSH_OTM_DLV_TAB,
                   x_error_trip_id_tab  OUT NOCOPY  WSH_OTM_ID_TAB,
                   x_return_status      OUT NOCOPY  VARCHAR2)IS

-- Declare local variables

l_sub_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_TRIP_OBJECTS';

l_trip_tab      WSH_OTM_TRIP_TAB;
l_stops_tab     WSH_OTM_STOP_TAB;
--lpn_tab       WSH_OTM_LPN_TAB;
l_dlv_tab       XX_OM_WSH_OTM_DLV_TAB;
l_dlv_ids       WSH_OTM_ID_TAB;
l_vol           NUMBER;
l_gross_weight      NUMBER;
l_net_weight        NUMBER;
l_total_gross_wt    NUMBER;
l_total_net_wt      NUMBER;
l_total_vol     NUMBER;
l_delivery_id       NUMBER;
l_vol_uom       VARCHAR2(150);
l_weight_uom        VARCHAR2(150);
x_base_wt_uom       VARCHAR2(150);
x_base_vol_uom      VARCHAR2(150);
l_lpn_count     NUMBER;
l_stop_details      WSH_OTM_STOP_DET_TAB;
l_new_stop_details      WSH_OTM_STOP_DET_TAB;
l_lpns          WSH_OTM_LPN_TAB;
l_pick_up_flag      VARCHAR2(1);
l_drop_off_flag     VARCHAR2(1);
l_trips_sql         VARCHAR2(2000);
l_trip_obj      WSH_OTM_TRIP_OBJ;
l_stop_obj      WSH_OTM_STOP_OBJ;
c_trips             WSH_UTIL_CORE.RefCurType;
bind_col_tab        WSH_UTIL_CORE.tbl_varchar;
i           NUMBER;
i1          NUMBER;
l_lpn_tab       WSH_OTM_LPN_TAB;
l_organization_id   NUMBER;
l_return_status     VARCHAR2(10);
l_all_dlv_tab       XX_OM_WSH_OTM_DLV_TAB;
l_total_freight_cost    NUMBER;
l_currency_code     VARCHAR2(15);
l_sob_id        NUMBER;
l_car_type      VARCHAR2(5) := 'CAR-';

-- Define cursor to get the deliveries picked at a stop
CURSOR get_deliveries_picked (p_stop_id NUMBER) IS
SELECT delivery_id
FROM
wsh_delivery_legs
WHERE pick_up_stop_id = p_stop_id;

-- Define cursor to get the deliveries dropped at a stop
CURSOR get_deliveries_dropped (p_stop_id NUMBER) IS
SELECT delivery_id
FROM
wsh_delivery_legs
WHERE drop_off_stop_id = p_stop_id;

TYPE dlv_in_tab_type IS TABLE OF XX_OM_WSH_OTM_DLV_OBJ INDEX BY BINARY_INTEGER;
dlv_in_tab dlv_in_tab_type;

GET_DELIVERY_OBJECTS_FALIED     EXCEPTION;
GET_DEAFULT_UOMS_FALIED     EXCEPTION;
GET_FREIGHT_COST_ERROR      EXCEPTION;

BEGIN


  --  Initialize API return status to success

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  -- Debug
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_sub_module_name);
  END IF;

  -- Setting the apps context
  FND_GLOBAL.apps_initialize(user_id => p_user_id,
                resp_id =>p_resp_id,
                resp_appl_id => p_resp_appl_id);

  IF l_debug_on THEN
    WSH_DEBUG_SV.LOG(l_sub_module_name,'Building the dymanic sql to fetch Trips');
  END IF;

   --dbms_output.put_line('Building the sql');
  l_trips_sql :=
    'select '||
    'WSH_OTM_TRIP_OBJ(WT.TP_PLAN_NAME,  '||
    'NAME    ,'||
    'null,'||
    '''RC'','||
    'WT.carrier_id,'||
    'null,'||
    'WT.MODE_OF_TRANSPORT,'||
    'null,'||
    'null,'|| --weight_uom
    'null,'|| --Volume
    'null,'|| -- volume_uom
    'null,'|| --lpn count
    'WT.FREIGHT_TERMS_CODE,'||
    'null,'|| -- stop count
    'null,'|| -- release count
    'null,'||
    'null,'||
    'WT.VEHICLE_ITEM_ID,'||
    'WT.VEHICLE_NUM_PREFIX,'||
    'WT.VEHICLE_NUMBER,'||
    'null,'||
    'WT.VEHICLE_ORGANIZATION_ID,'||
    'null,'||
    'WT.SEAL_CODE,'||
    'sequence_number,'|| -- master_bol_number
    'WT.PLANNED_FLAG,'||
    'WT.ROUTING_INSTRUCTIONS,'||
    'null, '||-- gross weight
    'null, '||-- net_weight
    'wt.BOOKING_NUMBER    ,    '||
    'null,'||
    'WT.TRIP_ID,'||
    'nvl(WT.IGNORE_FOR_PLANNING,''N''),'||
    'WT.OPERATOR,'||
    'null,'|| -- Manual Freight cost
    'null,'|| -- Currency Code
    'null, '||
    '''TRIP_ID'','||
    '''MBOL_NUMBER'','||
    '''PLANNED_TRIP'','||
    '''MANUAL_FREIGHT_COSTS'','||
    '''MAN_FREIGHT_COST_CUR'','||
    '''OPERATOR'','||
    '''ROUTING_INSTR'','||
    'null,'|| -- Stops
    'null ,null,null,null,null), '||
    'WSH_OTM_STOP_OBJ(wts.STOP_ID , '||
        'WTS.STOP_SEQUENCE_NUMBER,null,null,'||
        'TO_CHAR(WTS.PLANNED_ARRIVAL_DATE,''YYYYMMDDHH24MISS''),'||
        'TO_CHAR(WTS.PLANNED_DEPARTURE_DATE,''YYYYMMDDHH24MISS''),'||
        'TO_CHAR(WTS.ACTUAL_ARRIVAL_DATE,''YYYYMMDDHH24MISS''),'||
        'TO_CHAR(WTS.ACTUAL_DEPARTURE_DATE,''YYYYMMDDHH24MISS''),'||
--      'TO_CHAR(WTS.PLANNED_ARRIVAL_DATE,''DD-MON-YYYY HH24:MI:SS''),'||
--      'TO_CHAR(WTS.PLANNED_DEPARTURE_DATE,''DD-MON-YYYY HH24:MI:SS''),'||
--      'TO_CHAR(WTS.ACTUAL_ARRIVAL_DATE,''DD-MON-YYYY HH24:MI:SS''),'||
--      'TO_CHAR(WTS.ACTUAL_DEPARTURE_DATE,''DD-MON-YYYY HH24:MI:SS''),'||
        'WTS.loading_end_datetime -  WTS.loading_start_datetime,'||
        'WTS.DEPARTURE_SEAL_CODE,''DEPARTURE_SEAL_CODE'', null, null), '||
        'nvl(WTS.DEPARTURE_GROSS_WEIGHT,0),'||
        'nvl(WTS.DEPARTURE_NET_WEIGHT,0),'||
        'nvl(WTS.DEPARTURE_VOLUME,0),   '||
        'WTS.WEIGHT_UOM_CODE,'||
        'WTS.VOLUME_UOM_CODE '||
  ' from wsh_trips wt , wsh_document_instances wdi, wsh_trip_stops wts '||
  ' where wt.trip_id = wts.trip_id '||
  ' and wdi.entity_name(+) = ''WSH_TRIPS'''||
  ' and wdi.entity_id(+) = wt.trip_id '||
  ' and wts.physical_stop_id is null '||
  ' and wts.tms_interface_flag = ''ASP'''||
  ' and wt.trip_id in (';


   FOR i IN 1..p_trip_id_tab.COUNT LOOP
   --{
    IF i <> 1 THEN
        l_trips_sql := l_trips_sql || ',';
    END IF;
    l_trips_sql := l_trips_sql || ':' || i;
    bind_col_tab(bind_col_tab.COUNT+1) := TO_CHAR(p_trip_id_tab(i));
   --}
   END LOOP;
   l_trips_sql := l_trips_sql || ')';
   l_trips_sql := l_trips_sql || ' ORDER BY WT.TRIP_ID';

   i:=1;

   WSH_UTIL_CORE.OpenDynamicCursor(c_trips, l_trips_sql, bind_col_tab);
   x_trip_tab := WSH_OTM_TRIP_TAB();
   l_trip_tab := WSH_OTM_TRIP_TAB();
   l_stops_tab := WSH_OTM_STOP_TAB();
   l_stop_details := WSH_OTM_STOP_DET_TAB();
   l_all_dlv_tab := XX_OM_WSH_OTM_DLV_TAB();

   LOOP
   --{
        FETCH c_trips INTO l_trip_obj,l_stop_obj,l_gross_weight,l_net_weight, l_vol, l_weight_uom, l_vol_uom;
    EXIT  WHEN (c_trips%NOTFOUND);
    IF ( l_trip_tab.COUNT = 0  OR l_trip_tab(l_trip_tab.COUNT).trip_id <> l_trip_obj.trip_id) THEN
    --{
        l_trip_tab.EXTEND;
        l_trip_tab(l_trip_tab.COUNT) := l_trip_obj;
        l_trip_tab(l_trip_tab.COUNT).shipment_stops := WSH_OTM_STOP_TAB();

        IF l_debug_on
        THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'Fetch Trip Id', l_trip_obj.trip_id);
        END IF;


        -- Get the OrganizationId of Trip
        l_organization_id := WSH_UTIL_CORE.GET_TRIP_ORGANIZATION_ID(l_trip_obj.trip_id);
        IF l_debug_on
        THEN
              WSH_DEBUG_SV.LOG(l_sub_module_name,' Organization Id after calling GET_TRIP_ORGANIZATION_ID ' ,
                        l_organization_id);
        END IF;
        --If Vehicle_organization_id is null then take the trip Organization_id
        IF l_trip_tab(l_trip_tab.COUNT).EQUIPMENT_GROUP_XID IS NULL THEN
            l_trip_tab(l_trip_tab.COUNT).EQUIPMENT_GROUP_XID := l_organization_id;
        END IF;


        -- Get the Default UOMS based on the Organization Id
        wsh_wv_utils.get_default_uoms(l_organization_id, x_base_wt_uom, x_base_vol_uom, x_return_status);
        IF x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
           RAISE GET_DEAFULT_UOMS_FALIED;
        END IF;
        WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
            p_uom=>x_base_wt_uom,
            x_uom=>l_trip_tab(l_trip_tab.COUNT).WEIGHT_UOM_XID ,
            x_return_status=>l_return_status);
        IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
             (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
            IF l_debug_on
            THEN
                WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
            END IF;
            RAISE FND_API.G_EXC_ERROR;
        END IF;

        WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
            p_uom=>x_base_vol_uom,
            x_uom=>l_trip_tab(l_trip_tab.COUNT).VOLUME_UOM_XID ,
            x_return_status=>l_return_status);
        IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
             (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
            IF l_debug_on
            THEN
                WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
            END IF;
            RAISE FND_API.G_EXC_ERROR;
        END IF;

        l_total_gross_wt := 0;
        l_total_net_wt := 0;
        l_total_vol := 0;
    --}
    END IF;

    l_trip_tab(l_trip_tab.COUNT).shipment_stops.EXTEND;
    l_trip_tab(l_trip_tab.COUNT).shipment_stops(l_trip_tab(l_trip_tab.COUNT).shipment_stops.COUNT) := l_stop_obj;

    IF x_base_wt_uom <> l_weight_uom THEN
    --{
        l_total_gross_wt := l_total_gross_wt + WSH_WV_UTILS.CONVERT_UOM(l_weight_uom,
                                        x_base_wt_uom,
                                        l_gross_weight,NULL);
        l_total_net_wt := l_total_net_wt + WSH_WV_UTILS.CONVERT_UOM(l_weight_uom,
                                    x_base_wt_uom,
                                    l_net_weight,NULL);
    --}
    ELSE
    --{
        l_total_gross_wt := l_total_gross_wt + l_gross_weight;
        l_total_net_wt := l_total_net_wt + l_net_weight;
    --}
    END IF;

    IF x_base_vol_uom <> l_vol_uom THEN
        l_total_vol := l_total_vol + WSH_WV_UTILS.CONVERT_UOM(l_vol_uom,
                                    x_base_vol_uom,
                                    l_vol,NULL);
    ELSE
        l_total_vol := l_total_vol + l_vol;
    END IF;

    l_trip_tab(l_trip_tab.COUNT).GROSS_WEIGHT := l_total_gross_wt;
    l_trip_tab(l_trip_tab.COUNT).NET_WEIGHT := l_total_net_wt;
    l_trip_tab(l_trip_tab.COUNT).VOLUME := l_total_vol;

   --}
   END LOOP;

 IF l_debug_on THEN
    WSH_DEBUG_SV.LOG(l_sub_module_name,'Number of Trips Fetched' , l_trip_tab.COUNT);
 END IF;

 IF  l_trip_tab.COUNT >0 THEN
 --{
  FOR i IN 1..l_trip_tab.COUNT LOOP
  --{
    IF l_debug_on THEN
        WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Trip with Id ' , l_trip_tab(i).trip_id);
    END IF;

    l_dlv_ids := WSH_OTM_ID_TAB();
    l_stops_tab := l_trip_tab(i).shipment_stops;



    IF l_trip_tab(i).ignore_for_planning = 'Y' THEN
        l_trip_tab(i).SHIPMENT_XID := 'WSH-' || l_trip_tab(i).TRIP_ID ;
        l_trip_tab(i).STOP_COUNT := l_stops_tab.COUNT;
    ELSE
        l_trip_tab(i).SERVICE_PROVIDER_XID := '';
        l_trip_tab(i).TRANSPORT_MODE_XID := '';
        l_trip_tab(i).PAYMENT_CODE_XID := '';
        l_trip_tab(i).BOOKING_NUMBER := '';
    END IF;


    IF l_trip_tab(i).SERVICE_PROVIDER_XID IS NOT NULL THEN
        l_trip_tab(i).SERVICE_PROVIDER_XID := l_car_type || l_trip_tab(i).SERVICE_PROVIDER_XID;
    END IF;

    IF l_trip_tab(i).EQUIPMENT_XID IS NOT NULL THEN
        l_trip_tab(i).EQUIPMENT_XID := wsh_util_core.get_item_name(
                        p_item_id =>TO_NUMBER(l_trip_tab(i).EQUIPMENT_XID),
                        p_organization_id =>l_trip_tab(i).EQUIPMENT_GROUP_XID);
    END IF;


    -- Get the curreny code from GL_SETS_OF_BOOKS
    l_sob_id := FND_PROFILE.VALUE('GL_SET_OF_BKS_ID');
    SELECT currency_code INTO l_currency_code
    FROM GL_SETS_OF_BOOKS
    WHERE set_of_books_id = l_sob_id;

    WSH_FREIGHT_COSTS_PVT.Get_Trip_Manual_Freight_Cost(l_trip_tab(i).TRIP_ID,
                                l_currency_code,
                                l_total_freight_cost,
                                l_return_status);

        IF l_return_status NOT IN (WSH_UTIL_CORE.G_RET_STS_SUCCESS,WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
        RAISE GET_FREIGHT_COST_ERROR;
        ELSIF l_return_status=WSH_UTIL_CORE.G_RET_STS_WARNING THEN
            x_return_status:=l_return_status;
    END IF;

    l_trip_tab(i).MANUAL_FREIGHT_COSTS := l_total_freight_cost;
    l_trip_tab(i).CURRENCY_CODE := l_currency_code;



    FOR i1 IN 1..l_stops_tab.COUNT LOOP
    --{

      IF l_debug_on THEN
        WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Stop with Id ' , l_stops_tab(i1).STOP_LOCATION_XID);
      END IF;

      l_stop_details := WSH_OTM_STOP_DET_TAB();



      OPEN get_deliveries_picked(l_stops_tab(i1).STOP_LOCATION_XID);
      LOOP
      --{
        FETCH get_deliveries_picked INTO l_delivery_id;
        EXIT  WHEN (get_deliveries_picked%NOTFOUND);
        IF l_debug_on THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'Delivery being Picked up  ' , l_delivery_id);
        END IF;
        l_dlv_ids.EXTEND;
        l_dlv_ids(l_dlv_ids.COUNT) := l_delivery_id;
        -- Pick Up Stop
        l_pick_up_flag := 'Y';
        l_stop_details.EXTEND;
        l_stop_details(l_stop_details.COUNT) := WSH_OTM_STOP_DET_OBJ('P',l_delivery_id);
      --}
      END LOOP;

      OPEN get_deliveries_dropped(l_stops_tab(i1).STOP_LOCATION_XID);
      LOOP
      --{
        FETCH get_deliveries_dropped INTO l_delivery_id;
        EXIT  WHEN (get_deliveries_dropped%NOTFOUND);
        IF l_debug_on THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'Delivery being Dropped off  ' , l_delivery_id);
        END IF;

        -- Drop Off Stop
        l_drop_off_flag := 'Y';
        l_stop_details.EXTEND;
        l_stop_details(l_stop_details.COUNT) := WSH_OTM_STOP_DET_OBJ('D',l_delivery_id);
      --}
      END LOOP;


      IF l_trip_tab(i).IGNORE_FOR_PLANNING = 'N' THEN
        l_stops_tab(i1).stop_duration := NULL;
      END IF;
      -- Drop off Stop
      IF l_drop_off_flag = 'Y' THEN
      --{
        l_stops_tab(i1).stop_duration := NULL;
        IF l_trip_tab(i).IGNORE_FOR_PLANNING = 'Y' THEN
            l_stops_tab(i1).ACTUAL_ARRIVAL_TIME := NVL(l_stops_tab(i1).ACTUAL_ARRIVAL_TIME,l_stops_tab(i1).PLANNED_ARRIVAL_TIME) ;
            l_stops_tab(i1).ACTUAL_DEPARTURE_TIME := NVL(l_stops_tab(i1).ACTUAL_DEPARTURE_TIME,l_stops_tab(i1).PLANNED_DEPARTURE_TIME);
        END IF;
      --}
      END IF;

      CLOSE get_deliveries_picked;
      CLOSE get_deliveries_dropped;
      IF l_debug_on THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'Assigning the stop Details');
      END IF;
      l_stops_tab(i1).stop_details := l_stop_details;

      l_stops_tab(i1).STOP_LOCATION_XID :=  WSH_OTM_REF_DATA_GEN_PKG.GET_STOP_LOCATION_XID(l_stops_tab(i1).STOP_LOCATION_XID);
    --}
    END LOOP;




    IF l_debug_on THEN
        WSH_DEBUG_SV.LOG(l_sub_module_name,'List of delivery Ids passed to GET_DELIVERY_OBJECTS');
    END IF;
    FOR i IN 1..l_dlv_ids.COUNT LOOP
    --{
        IF l_debug_on THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'dlv_ids' ,l_dlv_ids(i));
        END IF;
    --}
    END LOOP;

    Get_Delivery_objects(l_dlv_ids,p_user_id,p_resp_id, p_resp_appl_id,'A',x_domain_name,x_otm_user_name,
                x_otm_pwd,x_server_tz_code, l_dlv_tab,x_error_trip_id_tab,x_return_status);
    IF x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
           RAISE GET_DELIVERY_OBJECTS_FALIED;
        END IF;

    l_lpn_tab := WSH_OTM_LPN_TAB();

    FOR i2 IN 1..l_dlv_tab.COUNT LOOP
    --{
        l_lpn_count := l_lpn_count + l_dlv_tab(i2).lpn.COUNT;
        FOR j IN 1..l_dlv_tab(i2).lpn.COUNT LOOP
        --{
            l_lpn_tab.EXTEND;
            l_lpn_tab(l_lpn_tab.COUNT) := l_dlv_tab(i2).lpn(j);
            l_lpn_tab(l_lpn_tab.COUNT).EQUIPMENT_XID := l_trip_tab(i).EQUIPMENT_XID;
        --}
        END LOOP;
        dlv_in_tab(l_dlv_tab(i2).delivery_id) := l_dlv_tab(i2);
        l_all_dlv_tab.EXTEND;
        l_all_dlv_tab(l_all_dlv_tab.COUNT) := l_dlv_tab(i2);
    --}
    END LOOP;

    -- Populating the Stop Details
    FOR i IN 1..l_stops_tab.COUNT LOOP
    --{
        l_stop_details := l_stops_tab(i).stop_details;
        l_stops_tab(i).stop_details := NULL;
        l_new_stop_details := WSH_OTM_STOP_DET_TAB();
            FOR j IN 1..l_stop_details.COUNT LOOP
            --{
                l_lpns := dlv_in_tab(l_stop_details(j).lpn_id).lpn;
                FOR k IN 1..l_lpns.COUNT LOOP
                --{
                    l_new_stop_details.EXTEND;
                    l_new_stop_details(l_new_stop_details.COUNT) := WSH_OTM_STOP_DET_OBJ(l_stop_details(j).activity,l_lpns(k).lpn_id);
                --}
                END LOOP;
            --}
            END LOOP;
        l_stops_tab(i).stop_details := l_new_stop_details;
    --}
    END LOOP;

    l_trip_tab(i).LPNS       := l_lpn_tab;
    l_trip_tab(i).SHIPMENT_STOPS     := l_stops_tab;
    l_trip_tab(i).shipunit_count     := l_lpn_count ;
    --l_trip_tab(i).shipment_deliveries:= l_dlv_tab;
  --}
  END LOOP;
  x_trip_tab := l_trip_tab;
  x_dlv_tab  := l_all_dlv_tab;
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  --}
 ELSE
 --{
   x_return_status := FND_API.G_RET_STS_ERROR;
 --}
 END IF;
 --
 -- Debug Statements
 --
 IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_sub_module_name);
 END IF;
 --
EXCEPTION
  WHEN GET_FREIGHT_COST_ERROR THEN
       IF get_deliveries_picked%ISOPEN THEN
          CLOSE get_deliveries_picked;
       END IF;
       IF get_deliveries_dropped%ISOPEN THEN
          CLOSE get_deliveries_dropped;
       END IF;
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' GET_FREIGHT_COST_ERROR',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:GET_FREIGHT_COST_ERROR');
       END IF;


  WHEN GET_DEAFULT_UOMS_FALIED THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       IF get_deliveries_picked%ISOPEN THEN
          CLOSE get_deliveries_picked;
       END IF;
       IF get_deliveries_dropped%ISOPEN THEN
          CLOSE get_deliveries_dropped;
       END IF;
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' GET_DEAFULT_UOMS_FALIED',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:GET_DEAFULT_UOMS_FALIED');
       END IF;


  WHEN GET_DELIVERY_OBJECTS_FALIED THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       IF get_deliveries_picked%ISOPEN THEN
          CLOSE get_deliveries_picked;
       END IF;
       IF get_deliveries_dropped%ISOPEN THEN
          CLOSE get_deliveries_dropped;
       END IF;
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' GET_DELIVERY_OBJECTS_FALIED',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:GET_DELIVERY_OBJECTS_FALIED');
       END IF;

  WHEN FND_API.G_EXC_ERROR THEN
       x_return_status := FND_API.G_RET_STS_ERROR;
       IF get_deliveries_picked%ISOPEN THEN
          CLOSE get_deliveries_picked;
       END IF;
       IF get_deliveries_dropped%ISOPEN THEN
          CLOSE get_deliveries_dropped;
       END IF;
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' FND_API.G_EXC_ERROR',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:FND_API.G_EXC_ERROR');
       END IF;
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF get_deliveries_picked%ISOPEN THEN
          CLOSE get_deliveries_picked;
       END IF;
       IF get_deliveries_dropped%ISOPEN THEN
          CLOSE get_deliveries_dropped;
       END IF;
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' FND_API.G_EXC_UNEXPECTED_ERROR',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:FND_API.G_EXC_UNEXPECTED_ERROR');
       END IF;
  WHEN OTHERS THEN
       wsh_util_core.default_handler('WSH_OTM_OUTBOUND.GET_TRIP_OBJECTS',l_sub_module_name);
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF get_deliveries_picked%ISOPEN THEN
          CLOSE get_deliveries_picked;
       END IF;
       IF get_deliveries_dropped%ISOPEN THEN
          CLOSE get_deliveries_dropped;
       END IF;
       IF l_debug_on THEN
      WSH_DEBUG_SV.LOG(l_sub_module_name,' OTHERS',SQLERRM);
          WSH_DEBUG_SV.pop(l_sub_module_name,'EXCEPTION:OTHERS');
       END IF;
END GET_TRIP_OBJECTS;


-- +==================================================================================================+
-- |  Procedure : GET_DELIVERY_OBJECTS                                                                |
-- |  Description:                                                                                    |
-- |     Procedure to get the delivery,delivery details and Lpn info                                  |
-- |     in the form of objects (WSH_OTM_DLV_TAB)                                                     |
-- |                                                                                                  |
-- |  Inputs/Outputs:                                                                                 |
-- |           p_dlv_id_tab  - id table (list of delivery Ids)                                        |
-- |           p_user_id     - User Id to set the context                                             |
-- |           p_resp_id     - Resp Id to set the context                                             |
-- |           p_resp_appl_id    - Resp Appl Id to set the context                                    |
-- |           p_caller      - When passed from GET_TRIP_OBJECTS this will have a                     |
-- |             value of 'A' else default 'D'                                                        |
-- |  Output:                                                                                         |
-- |           x_domain_name     - domain name                                                        |
-- |           x_otm_user_name   - otm User Name                                                      |
-- |       x_otm_pwd     - otm Password                                                               |
-- |       x_otm_pwd     - otm Password                                                               |
-- |       x_dlv_tab     - Nested Table which contains the delivery info                              |
-- |       x_error_dlv_id_tab - List of ids for which the data could not be retrieved                 |
-- |           x_return_status                                                                        |
-- +==================================================================================================+



PROCEDURE GET_DELIVERY_OBJECTS(p_dlv_id_tab         IN OUT NOCOPY   WSH_OTM_ID_TAB,
                   p_user_id        IN      NUMBER,
                   p_resp_id        IN      NUMBER,
                   p_resp_appl_id       IN      NUMBER,
                   p_caller         IN      VARCHAR2 DEFAULT 'D',
                   x_domain_name        OUT NOCOPY  VARCHAR2,
                   x_otm_user_name      OUT NOCOPY  VARCHAR2,
                   x_otm_pwd        OUT NOCOPY  VARCHAR2,
                   x_server_tz_code     OUT NOCOPY  VARCHAR2,
                   x_dlv_tab        OUT NOCOPY  XX_OM_WSH_OTM_DLV_TAB,
                   x_error_dlv_id_tab   OUT NOCOPY  WSH_OTM_ID_TAB,
                   x_return_status      OUT NOCOPY  VARCHAR2  ) IS

-- Declare local variables

  l_sub_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_DELIVERY_OBJECTS';
  l_dlv_tab         XX_OM_WSH_OTM_DLV_TAB;
  l_all_details     XX_OM_WSH_OTM_DET_TAB;
  l_del_details     XX_OM_WSH_OTM_DET_TAB;
  l_rl_details      XX_OM_WSH_OTM_DET_TAB;
  l_lpn_tab         wsh_otm_lpn_tab;
  l_packed_items    WSH_OTM_LPN_CONT_TAB;
  l_loose_items_ids WSH_OTM_ID_TAB;
  l_dlv_obj         XX_OM_WSH_OTM_DLV_OBJ;
  l_det_obj         XX_OM_WSH_OTM_DET_OBJ;
  l_weight          NUMBER;
  l_dlv_id_tab      WSH_OTM_ID_TAB;
  l_error_dlv_id_tab    WSH_OTM_ID_TAB;


  c_deliveries          WSH_UTIL_CORE.RefCurType;
  bind_col_tab          WSH_UTIL_CORE.tbl_varchar;
  otm_uom_tab           WSH_UTIL_CORE.tbl_varchar;
  l_deliveries_sql  VARCHAR2(2000);
  l_count       NUMBER;
  l_customer_id     NUMBER;
  l_cnt         NUMBER;
  i             NUMBER;
  l         NUMBER;
  x         NUMBER;
  l_total_quantity  NUMBER;
  l_cont_type       VARCHAR2(30);
  l_length      NUMBER;
  l_height      NUMBER;
  l_width       NUMBER;
  l_uom         VARCHAR2(150);
  l_organization_code   VARCHAR2(30);
  l_internal_org_location_id    VARCHAR2(150);
  l_dropoff_location_id     NUMBER;
  l_return_status       VARCHAR2(10);
  position          NUMBER;
  l_found           BOOLEAN;
  l_quantity            NUMBER;
  l_delivery_id         NUMBER;
  l_inventory_item      VARCHAR2(30);
  l_otm_dimen_uom       VARCHAR2(150);
  l_cust_type           VARCHAR2(5) := 'CUS-';
  l_org_type            VARCHAR2(5) := 'ORG-';
  l_car_type            VARCHAR2(5) := 'CAR-';
  l_organization_id     NUMBER;
  x_base_wt_uom         VARCHAR2(150);
  x_base_vol_uom        VARCHAR2(150);

  CONVERT_INT_LOC_FALIED    EXCEPTION;
  GET_DEAFULT_UOMS_FAILED   EXCEPTION;

  TYPE All_LPNS  IS TABLE OF  wsh_otm_lpn_obj INDEX BY BINARY_INTEGER;
  l_all_lpn_tab         All_LPNS;
  l_dummy_lpn_tab       All_LPNS;

  TYPE all_lpn_rec_type IS RECORD(
  lpn_id            NUMBER,
  lpn_type          VARCHAR2(100),
  gross_weight          NUMBER,
  net_weight            NUMBER,
  weight_uom_code       VARCHAR2(150),
  volume_uom_code       VARCHAR2(150),
  seal_code         VARCHAR2(30),
  packed_items          WSH_OTM_LPN_CONT_TAB,
  parent_delivery_detail_id     NUMBER);




  CURSOR get_customer_id (p_delivery_id NUMBER) IS
   SELECT wdd.customer_id, COUNT(*) cnt
   FROM   wsh_delivery_assignments wda,
          wsh_delivery_details wdd
   WHERE  wdd.delivery_detail_id = wda.delivery_detail_id
   AND    wda.delivery_id        =  p_delivery_id
   AND    wdd.container_flag     = 'N'
   GROUP BY customer_id
   ORDER BY cnt DESC;

   CURSOR get_organization_code( p_location_id NUMBER) IS
   SELECT organization_code
   FROM   mtl_parameters mp, hr_organization_units hou
   WHERE  mp.organization_id = hou.organization_id
   AND    hou.location_id = p_location_id;


 CURSOR get_container_details ( p_inventory_item_id NUMBER) IS
 SELECT CONTAINER_TYPE_CODE,
    UNIT_LENGTH ,
    UNIT_HEIGHT  ,
    UNIT_WIDTH   ,
    DIMENSION_UOM_CODE
 FROM mtl_system_items
 WHERE inventory_item_id = p_inventory_item_id;

BEGIN

  --  Initialize API return status to success

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  -- Debug
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  -- Debug Statements
  --
  IF l_debug_on THEN
      WSH_DEBUG_SV.push(l_sub_module_name);
  END IF;

  IF l_debug_on THEN
      FOR i IN 1..p_dlv_id_tab.COUNT LOOP
         WSH_DEBUG_SV.LOG(l_sub_module_name,'Dlv Id : ' , p_dlv_id_tab(i));
      END LOOP;
      WSH_DEBUG_SV.LOG(l_sub_module_name,'p_user_id' , p_user_id);
      WSH_DEBUG_SV.LOG(l_sub_module_name,'p_resp_id' , p_resp_id);
      WSH_DEBUG_SV.LOG(l_sub_module_name,'p_resp_appl_id' , p_resp_appl_id);
      WSH_DEBUG_SV.LOG(l_sub_module_name,'p_caller' , p_caller);
  END IF ;

 -- Setting the apps context
 FND_GLOBAL.APPS_INITIALIZE(user_id => p_user_id,
                resp_id =>p_resp_id,
                resp_appl_id => p_resp_appl_id);


 -- Getting the profile values
 fnd_profile.get('WSH_OTM_DOMAIN_NAME',x_domain_name);
 fnd_profile.get('WSH_OTM_USER_ID',x_otm_user_name);
 fnd_profile.get('WSH_OTM_PASSWORD',x_otm_pwd);
 x_server_tz_code := FND_TIMEZONES.get_server_timezone_code();

 IF l_debug_on THEN
    WSH_DEBUG_SV.LOG(l_sub_module_name,'Building the dymanic sql to fetch Deliveries');
 END IF;

 l_deliveries_sql :=
 'select '
 ||'XX_OM_WSH_OTM_DLV_OBJ( '
 ||'decode(wnd.tms_interface_flag,''CP'',''RC'',''UP'',''RC'',''DP'',''D''),'
 --||'''RC'','
 ||'wnd.delivery_id,'
 ||'wnd.name,'
 ||'wnd.freight_terms_code,'
 ||'wnd.fob_code,'
 ||'wnd.carrier_id,'
 ||'wnd.service_level,'
 ||'wnd.mode_of_transport,'
 ||'wnd.organization_id||''-''|| wnd.INITIAL_PICKUP_LOCATION_ID,'
 ||'wnd.customer_id ||''-''||wnd.ULTIMATE_DROPOFF_LOCATION_ID,'
 ||'wnd.EARLIEST_PICKUP_DATE,'
 ||'wnd.LATEST_PICKUP_DATE,'
 ||'wnd.EARLIEST_DROPOFF_DATE,'
 ||'wnd.LATEST_DROPOFF_DATE,'
 ||'nvl(wnd.GROSS_WEIGHT,0),'
 ||'wnd.WEIGHT_UOM_CODE,'
 ||'nvl(wnd.VOLUME,0),'
 ||'wnd.VOLUME_UOM_CODE,'
 ||'nvl(wnd.NET_WEIGHT,0),'
 ||'wnd.TMS_VERSION_NUMBER,'   -- revision number
 ||'wnd.REASON_OF_TRANSPORT,'
 ||'wnd.DESCRIPTION,'
 ||'wnd.ADDITIONAL_SHIPMENT_INFO,'
 ||'wnd.ROUTING_INSTRUCTIONS,'
 ||'(SELECT hps.attribute1 FROM   wsh_delivery_details wdd1, hz_cust_accounts hca,hz_party_sites hps  WHERE  wdd.customer_id = hca.cust_account_id AND hca.party_id = hps.party_id AND hps.identifying_address_flag = ''Y'' AND wdd1.delivery_detail_id = wdd.delivery_detail_id ) hpattr1 ,'
 ||'(SELECT hcasa.attribute1 FROM  wsh_delivery_details wdd1,hz_cust_accounts hca,hz_party_sites hps, hz_cust_acct_sites_all hcasa WHERE wdd.customer_id = hca.cust_account_id AND hca.cust_account_id = hcasa.cust_account_id AND hca.party_id = hps.party_id AND hps.party_site_id =  hcasa.party_site_id AND hps.identifying_address_flag = ''Y'' AND wdd1.delivery_detail_id = wdd.delivery_detail_id) hcattr1,'
 ||'wnd.Attribute1,'
 ||'wnd.Attribute2,' 
 ||'null,''REVNUM'',''TRSP_REASON'',''DEL_DESCRIPTION'',''ADD_INFOS'',''ROUTING_INSTR'',null,null),'
 ||'XX_OM_WSH_OTM_DET_OBJ(wdd.delivery_detail_id,'
        ||'wdd.lot_number,'
            ||'wdd.serial_number,'
            ||'wdd.to_serial_number,'
        ||'nvl(wdd.GROSS_WEIGHT,0),'
        ||'wdd.WEIGHT_UOM_CODE  ,'
        ||'nvl(wdd.VOLUME,0)    ,'
        ||'wdd.VOLUME_UOM_CODE,'
        ||'wdd.REQUESTED_QUANTITY,'
        ||'wdd.SHIPPED_QUANTITY,'
        ||'wdd.organization_id || ''-'' || wdd.INVENTORY_ITEM_ID,'
        ||'wdd.container_flag,'
        ||'wda.parent_delivery_detail_id,'
        ||'wdd.cust_po_number,'
        ||'wdd.source_header_number,''CUST_PO'',''SO_NUM'', wda.delivery_id,nvl(wdd.NET_WEIGHT,0),'
        ||'wdd.attribute1,'
        ||'wdd.attribute2,'
        ||'wdd.attribute3,'
        ||'wdd.attribute4,'
        ||'wdd.attribute5,'
        ||'wdd.attribute6)'
 ||'  from wsh_new_deliveries wnd, wsh_delivery_details wdd  , wsh_delivery_assignments wda'
 ||' where wdd.delivery_detail_id(+) = wda.delivery_detail_id '
 ||' and wnd.delivery_id = wda.delivery_id(+) '
 ||' and wnd.delivery_id in (';

 FOR i IN 1..p_dlv_id_tab.COUNT LOOP
 --{
    IF i <> 1 THEN
        l_deliveries_sql := l_deliveries_sql || ',';
    END IF;
    l_deliveries_sql := l_deliveries_sql || ':' || i;
    bind_col_tab(bind_col_tab.COUNT+1) := TO_CHAR(p_dlv_id_tab(i));
 --}
 END LOOP;

 l_deliveries_sql := l_deliveries_sql || ')';
 IF p_caller <> 'A' THEN
    l_deliveries_sql := l_deliveries_sql || ' and wnd.tms_interface_flag in (''CP'',''DP'',''UP'') ';
 END IF;
 l_deliveries_sql := l_deliveries_sql || 'order by wda.delivery_id, wdd.container_flag desc';

 i:=1;

 WSH_UTIL_CORE.OpenDynamicCursor(c_deliveries, l_deliveries_sql, bind_col_tab);
 l_count := 1;
 l_dlv_tab := XX_OM_WSH_OTM_DLV_TAB();
 --l_all_details - contains the delivery details of all the deliveries queried.
 l_all_details := XX_OM_WSH_OTM_DET_TAB();
 --l_dlv_obj := wsh_otm_dlv_obj();
l_dlv_id_tab := WSH_OTM_ID_TAB();
 LOOP
 --{
    FETCH c_deliveries INTO l_dlv_obj,l_det_obj;
    EXIT  WHEN (c_deliveries%NOTFOUND);
    IF ( l_dlv_tab.COUNT = 0  OR l_dlv_tab(l_dlv_tab.COUNT).delivery_id <> l_dlv_obj.delivery_id) THEN
        l_dlv_tab.EXTEND;
        l_dlv_tab(l_dlv_tab.COUNT) := l_dlv_obj;
    END IF;
    l_all_details.EXTEND;
    l_all_details(l_all_details.COUNT) := l_det_obj;
    l_count := l_count+1;
 --}
 END LOOP;

WSH_DEBUG_SV.LOG(l_sub_module_name,'count of deliveries ' , l_dlv_tab.COUNT);


IF  l_dlv_tab.COUNT >0 THEN
--{

  l_error_dlv_id_tab := WSH_OTM_ID_TAB();
  FOR i IN 1..l_dlv_tab.COUNT LOOP
  --{
    l_dlv_id_tab.EXTEND;
    l_dlv_id_tab(l_dlv_id_tab.COUNT) := l_dlv_tab(i).delivery_id;
    l_delivery_id := l_dlv_tab(i).delivery_id;

    IF p_caller = 'A' THEN
        l_dlv_tab(i).transaction_code := 'RC';
    END IF;


    IF l_dlv_tab(i).CARRIER_ID IS NOT NULL THEN
        l_dlv_tab(i).CARRIER_ID := l_car_type || l_dlv_tab(i).CARRIER_ID;
    END IF;

    -- Getting the organization_id
        position := INSTR(l_dlv_tab(i).INITIAL_PICKUP_LOCATION_ID,'-');
        l_organization_id := SUBSTR(l_dlv_tab(i).INITIAL_PICKUP_LOCATION_ID,1, position-1);


    IF l_dlv_tab(i).INITIAL_PICKUP_LOCATION_ID IS NOT NULL THEN
        l_dlv_tab(i).INITIAL_PICKUP_LOCATION_ID := l_org_type || l_dlv_tab(i).INITIAL_PICKUP_LOCATION_ID;
    END IF;

    -- Populating the ULTIMATE_DROPOFF_LOCATION_ID based on whether it is internal or external location.
        position := INSTR(l_dlv_tab(i).ULTIMATE_DROPOFF_LOCATION_ID,'-');
        l_customer_id := SUBSTR(l_dlv_tab(i).ULTIMATE_DROPOFF_LOCATION_ID,1, position-1);
        l_dropoff_location_id := SUBSTR(l_dlv_tab(i).ULTIMATE_DROPOFF_LOCATION_ID,position+1);

        WSH_OTM_REF_DATA_GEN_PKG.GET_INT_LOCATION_XID(
                    p_location_id => l_dropoff_location_id,
                    x_location_xid  => l_internal_org_location_id,
                    x_return_status =>l_return_status);

    IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
           RAISE CONVERT_INT_LOC_FALIED;
        END IF;
    IF l_internal_org_location_id IS NOT NULL THEN
        l_dlv_tab(i).ULTIMATE_DROPOFF_LOCATION_ID := l_internal_org_location_id;
    ELSE
    --{
            -- If customer_id is null in wsh_new_deliveries
        IF l_customer_id IS NULL THEN
            OPEN get_customer_id(l_dlv_tab(i).delivery_id);
            FETCH get_customer_id INTO l_customer_id,l_cnt;
            CLOSE get_customer_id;
        END IF;
        l_dlv_tab(i).ULTIMATE_DROPOFF_LOCATION_ID := l_cust_type
                                || l_customer_id  || '-'
                                || l_dropoff_location_id;
    --}
    END IF;

    WSH_WV_UTILS.GET_DEFAULT_UOMS(l_organization_id, x_base_wt_uom, x_base_vol_uom, x_return_status);
    IF x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
       RAISE GET_DEAFULT_UOMS_FAILED;
    END IF;

    IF l_dlv_tab(i).WEIGHT_UOM_CODE IS NULL THEN
        l_dlv_tab(i).WEIGHT_UOM_CODE := x_base_wt_uom;
    END IF;
    IF l_dlv_tab(i).VOLUME_UOM_CODE IS NULL THEN
        l_dlv_tab(i).VOLUME_UOM_CODE := x_base_vol_uom;
    END IF;

    WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
        p_uom=>l_dlv_tab(i).WEIGHT_UOM_CODE,
        x_uom=>l_dlv_tab(i).WEIGHT_UOM_CODE,
        x_return_status=>l_return_status);
    IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
         (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
        IF l_debug_on
        THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
        END IF;
        RAISE FND_API.G_EXC_ERROR;
    END IF;

    WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
        p_uom=>l_dlv_tab(i).VOLUME_UOM_CODE,
        x_uom=>l_dlv_tab(i).VOLUME_UOM_CODE,
        x_return_status=>l_return_status);
    IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
         (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
        IF l_debug_on
        THEN
            WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
        END IF;
        RAISE FND_API.G_EXC_ERROR;
    END IF;





    --l_del_details - contains the delivery details of the delivery l_dlv_tab(i).delivery_id

        l_del_details := XX_OM_WSH_OTM_DET_TAB();
        get_del_details(l_all_details,l_dlv_tab(i).delivery_id,l_del_details);




    l_rl_details := XX_OM_WSH_OTM_DET_TAB();
    l_lpn_tab := wsh_otm_lpn_tab();
    l_all_lpn_tab := l_dummy_lpn_tab;
    l_total_quantity := 0;

    -- Loop through l_del_details to create the following
    -- l_rl_details  -- Basically all the release lines of this delivery
    -- l_loose_items   -- All the loose items in l_del_details
    -- lpn_tab       -- All the Outmost lpns in l_del_details + Lpns for Loose Items
    -- l_all_lpn_tab   -- All the lpns in l_del_details
    FOR i IN 1..l_del_details.COUNT LOOP
    --{
        IF l_del_details(i).WEIGHT_UOM_CODE IS NULL THEN
            l_del_details(i).WEIGHT_UOM_CODE := x_base_wt_uom;
        END IF;
        IF l_del_details(i).VOLUME_UOM_CODE IS NULL THEN
            l_del_details(i).VOLUME_UOM_CODE := x_base_vol_uom;
        END IF;


        WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
            p_uom=>l_del_details(i).WEIGHT_UOM_CODE,
            x_uom=>l_del_details(i).WEIGHT_UOM_CODE,
            x_return_status=>l_return_status);
        IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
             (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
            IF l_debug_on
            THEN
                WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
            END IF;
            RAISE FND_API.G_EXC_ERROR;
        END IF;

        WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
            p_uom=>l_del_details(i).VOLUME_UOM_CODE,
            x_uom=>l_del_details(i).VOLUME_UOM_CODE,
            x_return_status=>l_return_status);
        IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
             (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
            IF l_debug_on
            THEN
                WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
            END IF;
            RAISE FND_API.G_EXC_ERROR;
        END IF;





        IF l_del_details(i).container_flag = 'N'THEN
        --{
            l_rl_details.EXTEND;
            l_rl_details(l_rl_details.COUNT ) := l_del_details(i);
            IF p_caller = 'A' THEN
                l_quantity := l_del_details(i).SHIPPED_QUANTITY;
            ELSE
                l_quantity := l_del_details(i).REQUESTED_QUANTITY;
            END IF;
            l_total_quantity := l_total_quantity + l_quantity;

            IF l_del_details(i).parent_delivery_detail_id IS NULL THEN
            --{

                l_packed_items := WSH_OTM_LPN_CONT_TAB();
                l_packed_items.EXTEND;
                l_packed_items(l_packed_items.COUNT) := WSH_OTM_LPN_CONT_OBJ(l_del_details(i).delivery_detail_id,1,
                                        l_del_details(i).inventory_item_id,
                                        CEIL(l_quantity),
                                        l_del_details(i).delivery_detail_id,
                                        l_delivery_id,
                                        l_del_details(i).gross_weight,
                                        l_del_details(i).net_weight,
                                        l_del_details(i).weight_uom_code,
                                        l_del_details(i).volume,
                                        l_del_details(i).volume_uom_code
                                        );
                -- Creating a dummy lpn for the loose item
                l_lpn_tab.EXTEND;
                l_lpn_tab(l_lpn_tab.COUNT) := wsh_otm_lpn_obj(l_del_details(i).delivery_detail_id,NULL,l_del_details(i).gross_weight,l_del_details(i).net_weight,
                                l_del_details(i).weight_uom_code,l_del_details(i).volume_uom_code,
                                NULL,l_packed_items,NULL,
                                NULL,NULL,NULL,NULL,NULL,l_del_details(i).volume,NULL);
            --}
            ELSE
            --{
                x := l_del_details(i).parent_delivery_detail_id;
                LOOP
                --{
                    IF l_all_lpn_tab(x).parent_delivery_detail_id IS NULL THEN
                        l_all_lpn_tab(x).packed_items.EXTEND;
                        l_all_lpn_tab(x).packed_items(l_all_lpn_tab(x).packed_items.COUNT)
                                    := WSH_OTM_LPN_CONT_OBJ(
                                    l_del_details(i).delivery_detail_id,
                                    l_all_lpn_tab(x).packed_items.COUNT,
                                    l_del_details(i).inventory_item_id,
                                    CEIL(l_quantity),
                                    l_all_lpn_tab(x).lpn_id,
                                    l_delivery_id,
                                    l_del_details(i).gross_weight,
                                    l_del_details(i).net_weight,
                                    l_del_details(i).weight_uom_code,
                                    l_del_details(i).volume,
                                    l_del_details(i).volume_uom_code
                                    );
                        EXIT;
                    ELSE
                        x:= l_all_lpn_tab(x).parent_delivery_detail_id;
                    END IF;
                --}
                END LOOP;
            --}
            END IF;
        --}
        ELSE
        --{
            IF l_del_details(i).parent_delivery_detail_id IS NULL THEN
                l_inventory_item := l_del_details(i).inventory_item_id;
                OPEN get_container_details(SUBSTR(l_inventory_item,INSTR(l_inventory_item,'-') + 1));
                FETCH get_container_details INTO l_cont_type, l_length, l_height, l_width, l_uom;
                CLOSE get_container_details;
            END IF;

            WSH_OTM_RIQ_XML.Get_EBS_To_OTM_UOM(
                p_uom=>l_uom,
                x_uom=>l_otm_dimen_uom ,
                x_return_status=>l_return_status);
            IF((l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) AND
                 (l_return_status <> WSH_UTIL_CORE.G_RET_STS_WARNING)) THEN
                IF l_debug_on
                THEN
                    WSH_DEBUG_SV.LOG(l_sub_module_name,'Get_EBS_To_OTM_UOM Weight Failed');
                END IF;
                RAISE FND_API.G_EXC_ERROR;
            END IF;


            l_all_lpn_tab(l_del_details(i).delivery_detail_id) :=
                                wsh_otm_lpn_obj(l_del_details(i).delivery_detail_id,
                                NULL,
                                l_del_details(i).gross_weight,
                                l_del_details(i).net_weight,
                                l_del_details(i).weight_uom_code,
                                l_del_details(i).volume_uom_code,
                                NULL,
                                NULL,
                                l_del_details(i).parent_delivery_detail_id,
                                l_cont_type, l_length, l_height, l_width, l_otm_dimen_uom,l_del_details(i).volume,NULL);
            l_all_lpn_tab(l_del_details(i).delivery_detail_id).packed_items := WSH_OTM_LPN_CONT_TAB();
        --}
        END IF;
    --}
    END LOOP;


    -- Populating the lpn_tab with the outermost Lpns in l_all_lpn_tab
    IF l_all_lpn_tab.COUNT >0 THEN
    --{
        l := l_all_lpn_tab.FIRST;
        WHILE l IS NOT NULL
        LOOP
        --{
            IF l_all_lpn_tab(l).parent_delivery_detail_id IS NULL THEN
                l_lpn_tab.EXTEND;
                l_lpn_tab(l_lpn_tab.COUNT) := l_all_lpn_tab(l);

            END IF;
            l := l_all_lpn_tab.NEXT(l);
        --}
        END LOOP;
    --}
    END IF;

    l_dlv_tab(i).lpn :=  l_lpn_tab;
    l_dlv_tab(i).rl_details := l_rl_details;
    l_dlv_tab(i).TOTAL_ITEM_COUNT := CEIL(l_total_quantity);
  --}
  END LOOP;

  -- If all the deliveries in the input parameter p_dlv_id_tab where not queried
  -- Put those id's in the error_dlv_id_list
  IF l_dlv_id_tab.COUNT <> p_dlv_id_tab.COUNT THEN
  --{
    FOR i IN 1..p_dlv_id_tab.COUNT LOOP
    --{
        l_found := FALSE;
    FOR j IN 1..l_dlv_id_tab.COUNT LOOP
    --{
        IF l_dlv_id_tab(j) = p_dlv_id_tab(i) THEN
            l_found := TRUE;
            EXIT;
        END IF;
        IF l_dlv_id_tab(j) > p_dlv_id_tab(i) THEN
            EXIT;
        END IF;
    --}
        END LOOP;
        IF l_found = FALSE THEN
            l_error_dlv_id_tab.EXTEND;
            l_error_dlv_id_tab(l_error_dlv_id_tab.COUNT) := p_dlv_id_tab(i);
        END IF;
    --}
    END LOOP;
  --}
  END IF;

  x_dlv_tab := l_dlv_tab;
  p_dlv_id_tab := l_dlv_id_tab;
  x_error_dlv_id_tab := l_error_dlv_id_tab;



  --------- Printing the complete structure------------
  IF l_debug_on THEN
  --{
    FOR k IN 1..x_dlv_tab.COUNT LOOP
    --{
    WSH_DEBUG_SV.LOG(l_sub_module_name,'dlv_id' , x_dlv_tab(k).delivery_id);
    FOR i IN 1..x_dlv_tab(k).rl_details.COUNT LOOP
          WSH_DEBUG_SV.LOG(l_sub_module_name,'DD  ' , x_dlv_tab(k).rl_details(i).delivery_detail_id);
    END LOOP;
    WSH_DEBUG_SV.LOG(l_sub_module_name,'Ship Units Count' , x_dlv_tab(k).lpn.COUNT);
    FOR i IN 1..x_dlv_tab(k).lpn.COUNT LOOP
    --{
          WSH_DEBUG_SV.LOG(l_sub_module_name,'Lpn Id ' , x_dlv_tab(k).lpn(i).lpn_id);
          FOR j IN 1..x_dlv_tab(k).lpn(i).packed_items.COUNT LOOP
                 WSH_DEBUG_SV.LOG(l_sub_module_name,'Content  ' ,x_dlv_tab(k).lpn(i).packed_items(j).content_id);
         WSH_DEBUG_SV.LOG(l_sub_module_name,'Content  ' ,x_dlv_tab(k).lpn(i).packed_items(j).line_number);
          END LOOP;
        --}
    END LOOP;
    --}
    END LOOP;
  --}
  END IF;
  --------- End of Printing the complete structure------------

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
  --}
ELSE
    x_error_dlv_id_tab := p_dlv_id_tab;
    p_dlv_id_tab := l_dlv_id_tab;
    x_dlv_tab := l_dlv_tab;
    x_return_status := FND_API.G_RET_STS_ERROR;
END IF;

 --
 -- Debug Statements
 --
 IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_sub_module_name);
 END IF;
 --
EXCEPTION
 WHEN GET_DEAFULT_UOMS_FAILED THEN
       WSH_DEBUG_SV.LOG(l_sub_module_name,'GET_DEAFULT_UOMS_FALIED',SQLERRM);
       x_return_status := FND_API.G_RET_STS_ERROR;
       IF get_customer_id%ISOPEN THEN
          CLOSE get_customer_id;
       END IF;
       IF get_container_details%ISOPEN THEN
          CLOSE get_container_details;
       END IF;

 WHEN CONVERT_INT_LOC_FALIED THEN
       WSH_DEBUG_SV.LOG(l_sub_module_name,'CONVERT_INT_LOC_FALIED',SQLERRM);
       x_return_status := FND_API.G_RET_STS_ERROR;
       IF get_customer_id%ISOPEN THEN
          CLOSE get_customer_id;
       END IF;
       IF get_container_details%ISOPEN THEN
          CLOSE get_container_details;
       END IF;

 WHEN FND_API.G_EXC_ERROR THEN
       WSH_DEBUG_SV.LOG(l_sub_module_name,' FND_API.G_EXC_ERROR',SQLERRM);
       x_return_status := FND_API.G_RET_STS_ERROR;
       IF get_customer_id%ISOPEN THEN
          CLOSE get_customer_id;
       END IF;
       IF get_container_details%ISOPEN THEN
          CLOSE get_container_details;
       END IF;
  WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
       WSH_DEBUG_SV.LOG(l_sub_module_name,'FND_API.G_EXC_UNEXPECTED_ERROR',SQLERRM);
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF get_customer_id%ISOPEN THEN
          CLOSE get_customer_id;
       END IF;
       IF get_container_details%ISOPEN THEN
          CLOSE get_container_details;
       END IF;
  WHEN OTHERS THEN
       wsh_util_core.default_handler('WSH_OTM_OUTBOUND.GET_DELIVERY_OBJECTS',l_sub_module_name);
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF get_customer_id%ISOPEN THEN
          CLOSE get_customer_id;
       END IF;
       IF get_container_details%ISOPEN THEN
          CLOSE get_container_details;
       END IF;
       IF l_debug_on THEN
            WSH_DEBUG_SV.pop(l_sub_module_name,'When Others');
       END IF;
END GET_DELIVERY_OBJECTS;

-- +====================================================================================================+
-- |  Procedure : UPDATE_ENTITY_INTF_STATUS                                                             |
-- |  Description:                                                                                      |
-- |     This procedure will be used to upate the interface flag status on the delivery or trip stop.   |
-- |                                                                                                    |
-- |  Inputs/Outputs:                                                                                   |
-- |           p_entity_type - Valid values are "DELIVERY",  "TRIP"                                     |
-- |           p_entity_id_tab  - id table  (IN / OUT) -- List of Delivery id or Trip id                |
-- |           p_new_intf_status - Delivery or Trip Stop Status                                         |
-- |            Valid values of this parameter are "IN_PROCESS", "COMPLETE"                             |
-- |                                                                                                    |
-- |                      Trip Stop Interface Flag values (internal):                                   |
-- |                      ASR - ACTUAL_SHIP_REQUIRED                                                    |
-- |                      ASP - ACTUAL_IN_PROCESS                                                       |
-- |                      CMP - COMPLETE                                                                |
-- |                                                                                                    |
-- |                      Delivery Interface Flag values (internal):                                    |
-- |                      NS - NOT TO BE SENT                                                           |
-- |                      CR - CREATE_REQUIRED                                                          |
-- |                      UR - UPDATE_REQUIRED                                                          |
-- |                      DR - DELETE_REQUIRED                                                          |
-- |                      CP - CREATE_IN_PROCESS                                                        |
-- |                      UP- UPDATE_IN_PROCESS                                                         |
-- |                      DP - DELETE_IN_PROCESS                                                        |
-- |                      AW - AWAITING_ANSWER                                                          |
-- |                      AR - ANSWER_RECEIVED                                                          |
-- |                      CMP - COMPLETE                                                                |
-- |           p_user_Id  - user id ( application user id )                                             |
-- |           p_resp_Id - responsibility id                                                            |
-- |           p_resp_appl_Id - resp application id ( Application Responsibility Id)                    |
-- |  Output:                                                                                           |
-- |           p_error_id_tab - erred entity id table  -- list of ERRORed delivery id or tripd id       |
-- |           p_entity_id_tab  - id table  (IN / OUT) - list of SUCCESS delivery id or trip id         |
-- |           x_return_status - "S"-Success, "E"-Error, "U"-Unexpected Error                           |
-- |  API is called from the following phases / API                                                     |
-- +====================================================================================================+
/*
1.Concurrent Request --TripStop and Delivery TMS_INTERFACE_FLAG is updated to newStatus = X_IN_PROCESS.
2.WSH_GLOG_OUTBOUND.GET_TRIP_OBJECTS - TripStop and Delivery TMS_INTERFACE_FLAG is updated to newStatus = AWAITING_ANSWER.
3.WSH_GLOG_OUTBOUND.GET_DELIVERY_OBJECTS - TripStop and Delivery TMS_INTERFACE_FLAG is updated to newStatus = AWAITING_ANSWER.
*/

PROCEDURE UPDATE_ENTITY_INTF_STATUS(
           x_return_status   OUT NOCOPY   VARCHAR2,
           p_entity_type     IN VARCHAR2,
           p_new_intf_status IN VARCHAR2,
           p_userId          IN    NUMBER DEFAULT NULL,
           p_respId          IN    NUMBER DEFAULT NULL,
           p_resp_appl_Id    IN    NUMBER DEFAULT NULL,
           p_entity_id_tab   IN OUT NOCOPY WSH_OTM_ID_TAB,
           p_error_id_tab    IN OUT NOCOPY WSH_OTM_ID_TAB
      ) IS

-- Declare local variables

l_sub_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'UPDATE_ENTITY_INTF_STATUS';
l_entity_id_out_tab WSH_OTM_ID_TAB :=WSH_OTM_ID_TAB();
l_error_id_out_tab WSH_OTM_ID_TAB := WSH_OTM_ID_TAB();
l_id_tab WSH_UTIL_CORE.ID_TAB_TYPE;
l_status_tab WSH_UTIL_CORE.COLUMN_TAB_TYPE;
l_del_current_status VARCHAR2(3);
l_del_id_error_flag VARCHAR2(1) := 'N';
l_stop_id_tab WSH_UTIL_CORE.ID_TAB_TYPE;
l_stop_status_tab WSH_UTIL_CORE.COLUMN_TAB_TYPE;
l_return_status VARCHAR2(1);
l_del_status_code VARCHAR2(30);
i NUMBER;
j NUMBER;
k NUMBER;
-- Define Exception variables
UPD_DEL_INTF_FLAG_API_FALIED EXCEPTION;
UPD_STOP_INTF_FLAG_API_FALIED EXCEPTION;
INVALID_ENTITY_TYPE EXCEPTION;
INVALID_NEW_INTF_STATUS EXCEPTION;

-- define the cursor to get the current TMS_INTERFACE_FLAG  status of delivery
CURSOR get_del_tms_interface_flag(c_delivery_id NUMBER) IS
       SELECT TMS_INTERFACE_FLAG,status_code FROM wsh_new_deliveries
       WHERE delivery_id = c_delivery_id;

-- define the cursor to get all trip stops for the given trip id.
CURSOR get_trip_stops(c_trip_id NUMBER) IS
       SELECT stop_id,TMS_INTERFACE_FLAG FROM wsh_trip_stops
       WHERE trip_id = c_trip_id;
      -- and (TMS_INTERFACE_FLAG ='ASR' or TMS_INTERFACE_FLAG ='ASP');
BEGIN
  -- save point
  SAVEPOINT  UPDATE_ENTITY_INTF_STATUS;

  --  Initialize API return status to success
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  -- Debug
  --
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL
  THEN
     l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;
  --
  -- initialize Apps variables
  IF p_userid IS NOT NULL THEN
      fnd_global.apps_initialize(user_id => p_userid,
                     resp_id => p_respid,
                     resp_appl_id => p_resp_appl_Id
                     );
  END IF;
  --
  -- Debug Statements
  --
  IF l_debug_on THEN
     --{
     fnd_profile.get('WSH_DEBUG_LOG_DIRECTORY',l_debugfile);
     l_debugfile := l_debugfile||'/'||WSH_DEBUG_SV.g_file;

     WSH_DEBUG_SV.push(l_sub_module_name);
     WSH_DEBUG_SV.LOG(l_sub_module_name,'Begin of the process ',l_debugfile);
     WSH_DEBUG_SV.LOG(l_sub_module_name,'p_entity_type ',p_entity_type);
     WSH_DEBUG_SV.LOG(l_sub_module_name,'p_new_intf_status ',p_new_intf_status);
    --}
  END IF;
  --
  --Validations
  IF p_new_intf_status NOT IN ('IN_PROCESS','COMPLETE') THEN
     IF l_debug_on THEN
        WSH_DEBUG_SV.LOG(l_sub_module_name,'Invalid p_new_intf_status',p_new_intf_status);
     END IF;
     RAISE INVALID_NEW_INTF_STATUS;
  END IF;
  -- General Process
  -- Move all entity id ( trip / delivery ) to Error id table, if there is any error in "U" or "E"
  -- Process for DELIVERY
  -- if the input - p_new_intf_status is "IN_PROCESS"
  -- Query the delivery for the give delivery id
  -- if the current interface flag 'CR', need to update the status as "CP"
  -- if the current interface flag 'UR', need to update the status as "UP"
  -- if the current interface flag 'DR', need to update the status as "DP"
  -- if the current interface flag is 'CP,UP,DP', no update required,
  --                    For all other cases, move the delivery id to error id table.
  -- if the input - p_new_intf_status is "COMPLETE"
  -- if the current interface flag is CP, DP, or UP -> update to status AW
  -- if the current interface flag not in CP, DP, UP , add to ErrorId List
  k := 0;
  IF p_entity_type = 'DELIVERY' THEN
     --{
     IF l_debug_on THEN
        WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery Count',p_entity_id_tab.COUNT);
     END IF;
     --
     FOR i IN 1..p_entity_id_tab.COUNT
     LOOP
        l_del_id_error_flag := 'N';
        OPEN get_del_tms_interface_flag(p_entity_id_tab(i));
        FETCH get_del_tms_interface_flag INTO l_del_current_status,l_del_status_code;
        --
        IF get_del_tms_interface_flag%NOTFOUND THEN
           IF l_debug_on THEN
              WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery Not found',p_entity_id_tab(i));
           END IF;
           -- Move delivery id to  error table - p_error_id_tab
             l_del_id_error_flag := 'Y';
        END IF;
        --
        CLOSE get_del_tms_interface_flag;
        --
        IF p_new_intf_status = 'IN_PROCESS' THEN
           IF l_debug_on THEN
              WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery - Status',p_new_intf_status);
           END IF;
           --{
           -- Query the delivery for the given delivery id list and
           -- if the current interface flag is not in 'CR,UR,DR',
           -- no update required, move the delivery id to error id table.
           --
           IF l_del_current_status = 'CR' THEN
              WSH_DEBUG_SV.LOG(l_sub_module_name,'value of k1 '|| k);
              l_status_tab(k) := 'CP' ;
              l_id_tab(k) := p_entity_id_tab(i);
              k := k+ 1;
           ELSIF l_del_current_status = 'UR' THEN
              l_status_tab(k) := 'UP';
              l_id_tab(k) := p_entity_id_tab(i);
              k := k+ 1;
           ELSIF l_del_current_status = 'DR' THEN
              l_status_tab(k) := 'DP';
              l_id_tab(k) := p_entity_id_tab(i);
              k := k+ 1;
           ELSIF l_del_current_status IN ('CP','DP','UP') THEN
              -- no change to the status since the delivery is in process
              NULL;
           ELSE
              IF l_debug_on THEN
                 WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery - Error ',p_entity_id_tab(i));
              END IF;
              -- set l_del_id_error_flag to "YES" to move this del-id to error table.
              l_del_id_error_flag := 'Y';
           END IF;
           --
           --}End of p_new_intf_status = 'IN_PROCESS'
           --
        ELSIF p_new_intf_status = 'COMPLETE' THEN
          --{
          -- if the current interface flag is CP, or UP -> update to status AW
          -- if the current interface flag is DP -> update to status 'CMP' ( if del-status is "CL")
          -- if the current interface flag is DP -> update to status 'NS' ( if del-status is not "CL")
          -- if the current interface flag not in CP, DP, UP , add to ErrorId List
          IF l_del_current_status IN ('CP', 'UP') THEN
             l_status_tab(k) := 'AW';
             l_id_tab(k) := p_entity_id_tab(i);
             k := k+ 1;
          ELSIF l_del_current_status = 'DP' THEN
             IF l_del_status_code = 'CL' THEN
                l_status_tab(k) := 'CMP';
             ELSE
                l_status_tab(k) := 'NS';
             END IF;
             --
             l_id_tab(k) := p_entity_id_tab(i);
             k := k+ 1;
          ELSE
             l_del_id_error_flag := 'Y';
          END IF;
          --}
        END IF;
        IF l_del_id_error_flag = 'Y' THEN
           --{
              -- Move delivery id to  error table - p_error_id_tab
              IF l_debug_on THEN
                 WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery ID-Moving to error table ');
              END IF;
              l_error_id_out_tab.EXTEND;
              l_error_id_out_tab(l_error_id_out_tab.COUNT):=p_entity_id_tab(i);
              --
           --}
        ELSE
           IF l_debug_on THEN
              WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery ID-Success to table ',p_entity_id_tab(i));
           END IF;

           -- Move delivery id to  success table - l_entity_id_out_tab
           l_entity_id_out_tab.EXTEND;
           l_entity_id_out_tab(l_entity_id_out_tab.COUNT):=p_entity_id_tab(i);
        END IF;
        --
     END LOOP;
     IF l_id_tab.COUNT > 0 THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery Calling WSH API to update status-Del-Count',l_id_tab.COUNT);
        END IF;
        --{
        --Call WSH API to update the new status
        WSH_NEW_DELIVERIES_PVT.UPDATE_TMS_INTERFACE_FLAG
              (P_DELIVERY_ID_TAB=>l_id_tab,
               P_TMS_INTERFACE_FLAG_TAB =>l_status_tab,
               X_RETURN_STATUS   =>l_return_status);
        IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
           RAISE UPD_DEL_INTF_FLAG_API_FALIED;
        END IF;
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Delivery Calling WSH API to update status-Success-Del-Count',l_id_tab.COUNT);
        END IF;
        --}
     END IF;
     --}
  ELSIF p_entity_type = 'TRIP' THEN
     --{
     -- Process for TRIP
     -- For each Trip ID, need to query the trip stops
     -- IF p_new_intf_status is 'IN_PROCESS' and the current status is "ASR"
     --    update the status to "ASP"
     -- Otherwise no change.
     -- IF p_new_intf_status is 'COMPLETE' and the current status is "ASP"
     --    update the status to "CMP"
     -- Otherwise no change.
     -- if there is no trip stops for the give trip id, move the trip id to error id table.
     k := 0;
     IF l_debug_on THEN
        WSH_DEBUG_SV.LOG(l_sub_module_name,'Trip Count ',p_entity_id_tab.COUNT);
     END IF;
     --{
     FOR i IN 1..p_entity_id_tab.COUNT
     LOOP
        --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'Trip Stop ID  ',p_entity_id_tab(i));
        END IF;
        OPEN get_trip_stops(p_entity_id_tab(i));
        FETCH get_trip_stops BULK COLLECT INTO l_stop_id_tab,l_stop_status_tab;
        CLOSE get_trip_stops;
        --
        WSH_DEBUG_SV.LOG(l_sub_module_name,'Trip Stps count  ',l_stop_id_tab.COUNT);
        IF l_stop_id_tab.COUNT > 0 THEN
           --{
           j := l_stop_id_tab.FIRST;
           WHILE j IS NOT NULL
           LOOP
              --{
              IF l_debug_on THEN
                 WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Trip STOP ID  ',l_stop_id_tab(j) ||'-'||l_stop_status_tab(j));
              END IF;
              --
              IF p_new_intf_status = 'IN_PROCESS' THEN
                 --
                 --IF l_stop_status_tab(j) = 'ASR' then
                    l_status_tab(k) := 'ASP' ;
                    IF l_debug_on THEN
                       WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Trip STOP ID -New Status  ',l_status_tab(k));
                    END IF;
                    l_id_tab(k) := l_stop_id_tab(j);
                    k := k + 1;
                 --end if ;
                 --
              ELSIF p_new_intf_status = 'COMPLETE' THEN
                 --
                 --IF l_stop_status_tab(j) = 'ASP' then
                    l_status_tab(k) := 'CMP';
                    IF l_debug_on THEN
                       WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Trip STOP ID -New Status  ',l_status_tab(k));
                    END IF;
                    l_id_tab(k) := l_stop_id_tab(j);
                    k := k + 1;
                 --END IF;
                 --
              END IF;
              --
              j := l_stop_id_tab.NEXT(j);
              --}
           END LOOP;
           -- Move delivery id to  success table - l_entity_id_out_tab
           l_entity_id_out_tab.EXTEND;
           l_entity_id_out_tab(l_entity_id_out_tab.COUNT):=p_entity_id_tab(i);
           --}
        ELSE
           --{
           IF l_debug_on THEN
              WSH_DEBUG_SV.LOG(l_sub_module_name,'Moving to Error table for Trip id',p_entity_id_tab(i));
           END IF;
           -- Move the Trip Id into error table
           l_error_id_out_tab.EXTEND;
           l_error_id_out_tab(l_error_id_out_tab.COUNT):=p_entity_id_tab(i);
           --}
        END IF;
        --}
     END LOOP;
     --Call WSH API to update the new status in Trip Stops
     IF l_id_tab.COUNT > 0 THEN
        --{
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'Calling WSH API-UPDATE_TMS_INTERFACE_FLAG Total stops ids',l_id_tab.COUNT);
        END IF;
        --
        WSH_TRIP_STOPS_PVT.UPDATE_TMS_INTERFACE_FLAG
            (P_STOP_ID_TAB=>l_id_tab,
             P_TMS_INTERFACE_FLAG_TAB =>l_status_tab,
             X_RETURN_STATUS   =>l_return_status);
        IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
           RAISE UPD_STOP_INTF_FLAG_API_FALIED;
        END IF;
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'Processing Trip Calling WSH API to update status-Success-Trip-Stops-Count',l_id_tab.COUNT);
        END IF;
        --}
     END IF;
     --}
  ELSE
     RAISE INVALID_ENTITY_TYPE;
  END IF;
  -- store the success deliveries/trips back to p_entity_id_tab table
  -- store the error deliveries/trips tp_error_id_tab table
  p_entity_id_tab := l_entity_id_out_tab;
  p_error_id_tab := l_error_id_out_tab;
  IF l_debug_on THEN
     WSH_DEBUG_SV.LOG(l_sub_module_name,'End of Process - Delivery/Trip Success',p_entity_id_tab.COUNT);
     WSH_DEBUG_SV.LOG(l_sub_module_name,'End of Process - Delivery/Trip Error',p_error_id_tab.COUNT);
  END IF;
--
EXCEPTION
   WHEN UPD_DEL_INTF_FLAG_API_FALIED THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'UPD_DEL_INTF_FLAG_API_FALIED',SQLERRM);
        END IF;
        ROLLBACK TO UPDATE_ENTITY_INTF_STATUS;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := FND_API.G_RET_STS_ERROR;
   WHEN UPD_STOP_INTF_FLAG_API_FALIED THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'UPD_STOP_INTF_FLAG_API_FALIED',SQLERRM);
        END IF;
        ROLLBACK TO UPDATE_ENTITY_INTF_STATUS;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := FND_API.G_RET_STS_ERROR;
   WHEN INVALID_ENTITY_TYPE THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'INVALID_ENTITY_TYPE',SQLERRM);
        END IF;
        ROLLBACK TO UPDATE_ENTITY_INTF_STATUS;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := FND_API.G_RET_STS_ERROR;
   WHEN INVALID_NEW_INTF_STATUS THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'INVALID_NEW_INTF_STATUS',SQLERRM);
        END IF;
        ROLLBACK TO UPDATE_ENTITY_INTF_STATUS;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := FND_API.G_RET_STS_ERROR;
   WHEN FND_API.G_EXC_ERROR THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,' FND_API.G_EXC_ERROR',SQLERRM);
        END IF;
        ROLLBACK TO UPDATE_ENTITY_INTF_STATUS;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := FND_API.G_RET_STS_ERROR;
   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'FND_API.G_EXC_UNEXPECTED_ERROR',SQLERRM);
        END IF;
        ROLLBACK TO UPDATE_ENTITY_INTF_STATUS;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
   WHEN OTHERS THEN
        IF l_debug_on THEN
           WSH_DEBUG_SV.LOG(l_sub_module_name,'OTHERS - ERROR',SQLERRM);
        END IF;
        -- returning all entitiy id to error id table
        p_error_id_tab := p_entity_id_tab;
        x_return_status := FND_API.G_RET_STS_ERROR;
        wsh_util_core.default_handler('WSH_OTM_OUTBOUND.UPDATE_ENTITY_INTF_STATUS');
END;

END XX_OM_WSH_OTM_OUTBOUND_PKG;
/
SHOW ERRORS;
EXIT;