SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_MAP_LOCATION_REGION_PKG AS

 

 /*===========================================================================+
 | PROCEDURE                                                                 |
 |              Map_Locations                                                |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This procedure selects the minimum and maximum location id   |
 |              and fires the child concurrent program depending on the      |
 |              value of parameter p_num_of_instances                        |
 |                                                                           |
 +===========================================================================*/

G_PKG_NAME CONSTANT VARCHAR2(50) := 'XX_CDH_MAP_LOCATION_REGION_PKG';

PROCEDURE Map_Locations (
    p_errbuf              OUT NOCOPY   VARCHAR2,
    p_retcode             OUT NOCOPY   NUMBER,
    p_map_regions         IN   VARCHAR2,
    p_num_of_instances    IN   NUMBER,
    p_start_date          IN   VARCHAR2,
    p_end_date            IN   VARCHAR2,
    p_fte_installed	  IN   VARCHAR2 default NULL,
    p_create_facilities   IN   VARCHAR2 default NULL) IS

l_new_request_id     NUMBER := 0;
i                    NUMBER := 0;
l_worker_min         NUMBER := 0;
l_worker_max         NUMBER := 0;
l_min                NUMBER := 0;
l_max                NUMBER := 0;
l_sqlcode            NUMBER;
l_sqlerr             VARCHAR2(2000);
l_return_status      VARCHAR2(10);
l_completion_status  VARCHAR2(30);
l_temp               BOOLEAN;
l_ratio              NUMBER;
l_retcode            NUMBER;
l_errbuf             VARCHAR2(2000);
l_log_level          NUMBER;

BEGIN

 l_log_level         :=  FND_PROFILE.VALUE('ONT_DEBUG_LEVEL');

  WSH_UTIL_CORE.Enable_Concurrent_Log_Print;

   IF l_log_level IS NOT NULL THEN
     WSH_UTIL_CORE.Set_Log_Level(l_log_level);
   END IF;

 WSH_UTIL_CORE.println('Parameters Passed');
 WSH_UTIL_CORE.println('===============================');
 WSH_UTIL_CORE.println('Map Region : ' || p_map_regions);
 WSH_UTIL_CORE.println('Number of Instances : ' || p_num_of_instances);
 WSH_UTIL_CORE.println('Start Date : ' || p_start_date);
 WSH_UTIL_CORE.println('End Date : ' || p_end_date);
 WSH_UTIL_CORE.println('Create Facilities?: ' || p_create_facilities);
 WSH_UTIL_CORE.println('===============================');

l_completion_status := 'NORMAL';


    SELECT MIN(LOCATION_ID),MAX(LOCATION_ID)
    INTO   l_min, l_max
    FROM   HZ_LOCATIONS l
    WHERE  l.last_update_date >= nvl(to_date(p_start_date,'YYYY/MM/DD HH24:MI:SS'), l.last_update_date)
    AND    l.last_update_date <= nvl(to_date(p_end_date,'YYYY/MM/DD HH24:MI:SS'), l.last_update_date);

    fnd_file.put_line (fnd_file.log, 'l_min:' || l_min);
    fnd_file.put_line (fnd_file.log, 'l_max:' || l_max);


  IF l_min IS NOT NULL and l_max IS NOT NULL and p_num_of_instances > 0 THEN

   l_ratio := ((l_max - l_min) / p_num_of_instances);

    FOR i in 1..p_num_of_instances
     LOOP

        WSH_UTIL_CORE.println('Value of i : ' || i);

        l_worker_min := l_min + TRUNC((i - 1)* l_ratio );
        l_worker_max := l_min + TRUNC(i * l_ratio);

        IF i <> p_num_of_instances THEN
          l_worker_max := l_worker_max - 1;
        END IF;

        WSH_UTIL_CORE.println('l_worker_min:' || l_worker_min);
        WSH_UTIL_CORE.println('l_worker_max:' || l_worker_max);

        l_new_request_id :=  FND_REQUEST.SUBMIT_REQUEST(
                               'XXCNV',
                               'XX_CDH_IMPORT_SHIP_LOC_CHILD',
                               'OD: CDH Import Shipping Locations - Child '||to_char(i),
                               NULL,
                               NULL,
                               p_map_regions,
                               l_worker_min,
                               l_worker_max,
                               p_start_date,
                               p_end_date,
                               p_create_facilities);
                               
          COMMIT;                     

          WSH_UTIL_CORE.println('Child request ID : ' || l_new_request_id);

          IF l_new_request_id = 0 THEN
            WSH_UTIL_CORE.println('Error Submitting concurrent request');
          END IF;

      END LOOP;

   ELSIF nvl(p_num_of_instances,0) = 0 THEN

      Map_Locations_Child_Program (
          p_errbuf            => l_errbuf,
          p_retcode           => l_retcode,
          p_map_regions       => p_map_regions,
          p_from_location     => l_min,
          p_to_location       => l_max,
          p_start_date        => p_start_date,
          p_end_date          => p_end_date,
          p_create_facilities => p_create_facilities );

      IF l_retcode = '2' THEN
         l_completion_status := 'ERROR';
      ELSIF l_retcode = '1' THEN
         l_completion_status := 'WARNING';
      END IF;

   END IF;

   l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
   IF l_completion_status = 'NORMAL' THEN
       p_errbuf := 'Map_Locations Program completed successfully';
       p_retcode := '0';
   ELSIF l_completion_status = 'WARNING' THEN
       p_errbuf := 'Map_Locations Program is completed with warning';
       p_retcode := '1';
   ELSIF l_completion_status = 'ERROR' THEN
       p_errbuf := 'Map_Locations Program is completed with error';
       p_retcode := '2';
   END IF;

 EXCEPTION

     WHEN No_Data_Found THEN
       WSH_UTIL_CORE.println('No matching records for the entered parameters');

     WHEN others THEN
       l_sqlcode := SQLCODE;
       l_sqlerr  := SQLERRM;
       WSH_UTIL_CORE.println('In the Others Exception');
       WSH_UTIL_CORE.println('SQLCODE : ' || l_sqlcode);
       WSH_UTIL_CORE.println('SQLERRM : '  || l_sqlerr);

       l_completion_status := 'ERROR';
       l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
       p_errbuf := 'Exception occurred in Map_Locations Program';
       p_retcode := '2';

END Map_Locations;

/*===========================================================================+
| PROCEDURE                                                                 |
|              Map_Location_Child_Program                                   |
|                                                                           |
| DESCRIPTION                                                               |
|              This is just a wrapper routine and call the main processing  |
|              API Mapping_Regions_Main. This procedure is also by the      |
|              TCA Callout API Rule_Location.                               |
|                                                                           |
+===========================================================================*/

-- Will the conc program fail because of the new parameter
PROCEDURE Map_Locations_Child_Program (
    p_errbuf              OUT NOCOPY   VARCHAR2,
    p_retcode             OUT NOCOPY   NUMBER,
    p_map_regions         IN   VARCHAR2,
    p_from_location       IN   NUMBER,
    p_to_location         IN   NUMBER,
    p_start_date          IN   VARCHAR2,
    p_end_date            IN   VARCHAR2,
    p_create_facilities   IN   VARCHAR2 default NULL) IS

l_return_status      VARCHAR2(20);
l_sqlcode            NUMBER;
l_sqlerr             VARCHAR2(2000);
l_completion_status  VARCHAR2(30);
l_temp               BOOLEAN;

BEGIN

    l_completion_status := 'NORMAL';

    WSH_UTIL_CORE.println('-----------------------------');
    WSH_UTIL_CORE.println('Calling procedure Process_Locations');
    XX_CDH_LOCATIONS_PKG.Process_Locations (
            p_from_location       => p_from_location,
            p_to_location         => p_to_location,
            p_start_date          => p_start_date,
            p_end_date            => p_end_date,
            p_create_facilities   => p_create_facilities,
            x_return_status       => l_return_status,
            x_sqlcode             => l_sqlcode,
            x_sqlerr              => l_sqlerr);

     IF l_return_status NOT IN
        (WSH_UTIL_CORE.G_RET_STS_SUCCESS, WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
         WSH_UTIL_CORE.println('Failed in Procedure Process_Locations');
         l_completion_status := 'ERROR';
     END IF;

   IF p_map_regions = 'Y' AND l_completion_status <> 'ERROR' THEN

    WSH_UTIL_CORE.println('-----------------------------');
    WSH_UTIL_CORE.println('*** Map Regions parameter is Yes ***');
    WSH_UTIL_CORE.println('Calling procedure Mapping_Regions_Main');

     Mapping_Regions_Main (
        p_from_location    => p_from_location,
        p_to_location      => p_to_location,
        p_start_date       => p_start_date,
        p_end_date         => p_end_date,
        x_return_status    => l_return_status,
        x_sqlcode          => l_sqlcode,
        x_sqlerr           => l_sqlerr);

        IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS  THEN
          WSH_UTIL_CORE.println('Failed in Procedure Mapping_Regions_Main');
          l_completion_status := 'ERROR';
        END IF;
    END IF;

    l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
    IF l_completion_status = 'NORMAL' THEN
       p_errbuf := 'Map_Locations_Child_Program completed successfully';
       p_retcode := '0';
    ELSIF l_completion_status = 'WARNING' THEN
       p_errbuf := 'Map_Locations_Child_Program is completed with warning';
       p_retcode := '1';
    ELSIF l_completion_status = 'ERROR' THEN
       p_errbuf := 'Map_Locations_Child_Program is completed with error';
       p_retcode := '2';
    END IF;

EXCEPTION
   WHEN others THEN
     l_completion_status := 'ERROR';
     l_temp := FND_CONCURRENT.SET_COMPLETION_STATUS(l_completion_status,'');
     p_errbuf := 'Exception occurred in Map_Locations_Child_Program';
     p_retcode := '2';
     l_sqlcode := SQLCODE;
     l_sqlerr  := SQLERRM;
     WSH_UTIL_CORE.println('In the Others Exception of Map_Locations_Child');
     WSH_UTIL_CORE.println('SQLCODE : ' || l_sqlcode);
     WSH_UTIL_CORE.println('SQLERRM : '  || l_sqlerr);

END Map_Locations_Child_Program;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Mapping_Regions_Main                                         |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This API selects all the location data into PL/SQL table     |
 |              types and calls the Map_Location_To_Region by passing the    |
 |              location information                                         |
 |                                                                           |
 +===========================================================================*/

PROCEDURE Mapping_Regions_Main (
    p_from_location    IN   NUMBER,
    p_to_location      IN   NUMBER,
    p_start_date       IN   VARCHAR2,
    p_end_date         IN   VARCHAR2,
    x_return_status    OUT NOCOPY   VARCHAR2,
    x_sqlcode          OUT NOCOPY  NUMBER,
    x_sqlerr        out NOCOPY  varchar2) IS


l_return_status VARCHAR2(20);
l_sqlcode       NUMBER;
l_sqlerr        VARCHAR2(2000);
l_current_rows  NUMBER;
l_remaining_rows NUMBER;
l_previous_rows  NUMBER;
l_batchsize      NUMBER := 500;
l_location_source  VARCHAR2(4);

l_loc_tab          TableNumbers; -- Location ID Table Type
l_state_tab        TableVarchar; -- State Table Type
l_city_tab         TableVarchar; -- City Table Type
l_postal_code_tab  TableVarchar; -- Postal Code Table Type
l_ter_code_tab     TableVarchar; -- Territory Code Table Type
l_ter_sn_tab       TableVarchar; -- Territory Short Name Table Type
l_loc_source_tab   TableVarchar; -- Location Source Table Type

-- Cursor Declarations

CURSOR Get_External_Locations IS
  SELECT
    l.wsh_location_id,
    t.territory_short_name,
    t.territory_code,
    nvl(l.state, l.province) state,
    l.city city,
    l.postal_code
  FROM
    wsh_locations l,
    fnd_territories_tl t
  WHERE
    t.territory_code = l.country and
    t.language = userenv('LANG') and
    l.wsh_location_id between p_from_location and p_to_location and
    l.location_source_code = 'HZ' and
    l.last_update_date >= nvl(to_date(p_start_date,'YYYY/MM/DD HH24:MI:SS'), l.last_update_date) and
    l.last_update_date <= nvl(to_date(p_end_date,'YYYY/MM/DD HH24:MI:SS'), l.last_update_date);


BEGIN

   l_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

   ----------------------------------------------------------------------
   -- Depending on the location type, fetch all the data into respective
   -- PL/SQL tables. The call Map_Location_To_Region to map the data.
   ----------------------------------------------------------------------

   l_previous_rows := 0;


      l_location_source := 'HZ';


       OPEN Get_External_Locations;
       LOOP
          FETCH Get_External_Locations BULK COLLECT INTO
               l_loc_tab,
               l_ter_sn_tab,
               l_ter_code_tab,
               l_state_tab,
               l_city_tab,
               l_postal_code_tab
          LIMIT l_Batchsize;

          l_current_rows   := Get_External_Locations%rowcount ;
          l_remaining_rows := l_current_rows - l_previous_rows;

            IF (l_remaining_rows <= 0) then
              EXIT;
            END IF;

          l_previous_rows := l_current_rows ;

          -----------------------------------------------------
          -- Loop through the entire PL/SQL table and call the
          -- Map_Location_To_Region by passing corresponding
          -- parameters.
          -----------------------------------------------------

             IF l_ter_sn_tab.COUNT > 0 THEN

                FOR i in l_ter_sn_tab.FIRST..l_ter_sn_tab.LAST
                  LOOP
                    WSH_UTIL_CORE.println('Processing location id :' || l_loc_tab(i));
                    WSH_UTIL_CORE.println('Calling Map_Location_To_Region');

                      Map_Location_To_Region (
                         p_country          =>  l_ter_sn_tab(i),
                         p_country_code     =>  l_ter_code_tab(i),
                         p_state            =>  l_state_tab(i),
                         p_city             =>  l_city_tab(i),
                         p_postal_code      =>  l_postal_code_tab(i),
                         p_location_id      =>  l_loc_tab(i),
                         p_location_source  =>  l_location_source,
                         x_return_status    =>  l_return_status,
                         x_sqlcode          =>  l_sqlcode,
                         x_sqlerr           =>  l_sqlerr );

                        IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
                           WSH_UTIL_CORE.println('Failed in API Map_Location_To_Region');
                           x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
                        END IF;

                       WSH_UTIL_CORE.println('After call to Map_Location_To_Region');
                       WSH_UTIL_CORE.println('Processing Next Location');
                       WSH_UTIL_CORE.println('*******************************************');
                  END LOOP;
             END IF;

             EXIT WHEN Get_External_Locations%NOTFOUND;
       END LOOP;

       IF Get_External_Locations%ISOPEN THEN
          CLOSE Get_External_Locations;
       END IF;


    x_return_status := l_return_status;

    IF x_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
     commit;
    END IF;

EXCEPTION

   WHEN No_Data_Found THEN
    WSH_UTIL_CORE.println('No records found for the entered parameters');

   WHEN Others THEN
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    l_sqlcode := SQLCODE;
    l_sqlerr := SQLERRM;
    WSH_UTIL_CORE.println('When Others of Procedure Mapping_Regions_Main ');
    WSH_UTIL_CORE.println('SQLCODE :' || l_sqlcode);
    WSH_UTIL_CORE.println('Error :' || l_sqlerr);

END Mapping_Regions_Main;

/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Map_Location_To_Region                                       |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This API does the main mapping process. It calls the API     |
 |              WSH_REGIONS_SEARCH_PKG.Get_Region_Info which inturn returns  |
 |              the region id. For this particuar region, the parent regions |
 |              are also obtained and all these are inserted into the        |
 |              intersection table.                                          |
 |                                                                           |
 +===========================================================================*/

PROCEDURE Map_Location_To_Region (
       p_country            IN   VARCHAR2,
       p_country_code       IN   VARCHAR2,
       p_state              IN   VARCHAR2,
       p_city               IN   VARCHAR2,
       p_postal_code        IN   VARCHAR2,
       p_location_id        IN   NUMBER,
       p_location_source    IN   VARCHAR2,
       x_return_status      OUT NOCOPY   VARCHAR2,
       x_sqlcode            OUT NOCOPY   NUMBER,
       x_sqlerr             OUT NOCOPY   VARCHAR2) IS


  l_region_info        WSH_REGIONS_SEARCH_PKG.region_rec;
  l_region_type        NUMBER := 0;
  l_region_id          NUMBER := 0;
  l_region_table       WSH_REGIONS_SEARCH_PKG.region_table;
  l_country            l_region_info.country%TYPE;
  l_return_status      VARCHAR2(10);
  Insert_Failed        EXCEPTION;
  l_sqlcode            NUMBER;
  l_sqlerr             VARCHAR2(2000);
  l_region_type_const  NUMBER := 0 ;
  l_parent_region      VARCHAR2(1) := 'N';
  l_rows_before        NUMBER := 0;
  l_rows_after         NUMBER := 0;
  l_exists             VARCHAR2(10);
  l_location_source    VARCHAR2(4);
  l_status             NUMBER := 0;
  i                    NUMBER := 0;

CURSOR Check_Location_Exists(c_location_id IN NUMBER) IS
select 'exists'
from  wsh_region_locations
where location_id = c_location_id;

l_exception_msg_count NUMBER;
l_exception_msg_data  VARCHAR2(15000);
l_dummy_exception_id NUMBER;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'Map_Location_To_Region';

BEGIN

  x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;

  --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   --
   -- Debug Statements
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       WSH_DEBUG_SV.log(l_module_name,'P_COUNTRY',P_COUNTRY);
       WSH_DEBUG_SV.log(l_module_name,'P_COUNTRY_CODE',P_COUNTRY_CODE);
       WSH_DEBUG_SV.log(l_module_name,'P_STATE',P_STATE);
       WSH_DEBUG_SV.log(l_module_name,'P_CITY',P_CITY);
       WSH_DEBUG_SV.log(l_module_name,'P_POSTAL_CODE',P_POSTAL_CODE);
       WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_ID',P_LOCATION_ID);
       WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_SOURCE',P_LOCATION_SOURCE);
   END IF;

  l_region_info.country_code := p_country_code;
  l_region_info.country := p_country;

  IF (p_country_code IS NULL) THEN
        l_country := p_country;
  END IF;

  IF (length(p_state) <= 3) THEN
        l_region_info.state_code := p_state;
  ELSE
        l_region_info.state := p_state;
  END IF;

  IF (length(p_city) <=2 OR (length(p_city) = 3 and upper(p_city) = p_city)) THEN
        l_region_info.city_code := p_city;
  ELSE
        l_region_info.city := p_city;
  END IF;

  l_region_info.postal_code_from := p_postal_code;
  l_region_info.postal_code_to   := p_postal_code;

  IF (p_postal_code IS NOT NULL) THEN
     l_region_type := 3;
  ELSIF (p_city IS NOT NULL) THEN
     l_region_type := 2;
  ELSIF (p_state IS NOT NULL) THEN
     l_region_type := 1;
  END IF;

  -- START affected area
  -- change call to use get_all_region_matches

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'Calling program unit WSH_REGIONS_SEARCH_PKG.GET_ALL_REGION_MATCHES');
  END IF;

  WSH_REGIONS_SEARCH_PKG.Get_All_Region_Matches(
                  p_country => l_country,
                  p_country_region => l_region_info.country_region,
                  p_state => l_region_info.state,
                  p_city => l_region_info.city,
                  p_postal_code_from => l_region_info.postal_code_from,
                  p_postal_code_to => l_region_info.postal_code_to,
                  p_country_code => l_region_info.country_code,
                  p_country_region_code => l_region_info.country_region_code,
                  p_state_code => l_region_info.state_code,
                  p_city_code => l_region_info.city_code,
                  -- p_lang_code => null,
		  p_lang_code => USERENV('LANG'),
                  p_location_id => null,
                  p_zone_flag => 'N',
                  x_status => l_status,
                  x_regions => l_region_table);

  IF l_status = 1 THEN

   IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'get_all_region_matches could not find matching regions for location : ' || p_location_id);
   END IF;

  END IF;

  -- END affected area

  OPEN Check_Location_Exists(p_location_id);
  FETCH Check_Location_Exists INTO l_exists;
  CLOSE Check_Location_Exists;

  SAVEPOINT WSH_LOCATION_EXISTS;

  ---------------------------------------------------------------
  -- If a region is existing already, delete the records so that
  -- fresh mappings are inserted. Savepoint is issued before
  -- doing this.
  ---------------------------------------------------------------

  IF l_exists IS NOT NULL THEN

       -- Potentially if codes are same region records with same region_id
       -- are created in wsh_regions_tl table
       -- Hence, the delete below might indirectly remove mapping
       -- for another language sharing the same region_id
       -- BUT if for the current language the code is not changed
       -- or removed from the concerned region, the mapping should
       -- get recreated.
       -- 02/04 Discussed and validated this issue with Rohit

       -- Should delete mappings in current language and the ones
       -- with NULL region_id
       DELETE from wsh_region_locations where location_id = p_location_id
       and ( ( region_id in (select wrt.region_id from wsh_regions_tl wrt,
                         wsh_regions wr
                         where wrt.region_id = wr.region_id
                         and wrt.language = USERENV('LANG'))
           ) OR region_id IS NULL);

       l_rows_before := sql%rowcount; -- Bug 3736133

       IF l_debug_on THEN
           WSH_DEBUG_SV.log(l_module_name,'No. of mapped regions before deletion ', l_rows_before);
       END IF;

  END IF;

  l_location_source := p_location_source;

  IF p_location_source = 'TCA' THEN
     l_location_source := 'HZ';
  END IF;

  IF l_region_table.COUNT = 0 THEN

   IF l_debug_on THEN
       WSH_DEBUG_SV.log(l_module_name,'No matching regions were found for location : ' || p_location_id);
   END IF;

       -----------------------------------------------------------
       -- If no region is found still insert the the location with
       -- region id as null and exception_flag Y
       -----------------------------------------------------------

       Insert_Record (
           p_location_id     => p_location_id,
           p_region_id       => NULL,
           p_region_type     => NULL,
           p_exception       => 'Y',
           p_location_source => l_location_source,
           p_parent_region   => l_parent_region,
           x_return_status   => l_return_status);

           IF l_return_status <>  WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
              RAISE Insert_Failed;
           END IF;

           l_rows_after := 1; -- Bug 3736133

  ELSE

  -----------------------------------------------------------
  --  If some regions are found, then insert everything in the intersection
  --  table. If the region is a parent region, set the parent
  --  flag accordingly.
  -----------------------------------------------------------

   IF l_debug_on THEN
      WSH_DEBUG_SV.log(l_module_name,' Looping over l_region_table for inserting into the intersection table ');
   END IF;

   l_rows_after := 0; -- Bug 3736133

   i := l_region_table.FIRST;
   LOOP  -- 3. region hierarchy

       IF l_region_table(i).region_type >= 0 THEN

          IF l_region_table(i).region_type <> l_region_type THEN
              l_parent_region := 'Y';
          ELSE
              l_parent_region := 'N';
          END IF;

          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'Calling Insert_Record for location id :' || p_location_id);
             WSH_DEBUG_SV.log(l_module_name,' Region Id : ' || l_region_table(i).region_id);
             WSH_DEBUG_SV.log(l_module_name,' Region Type : ' || l_region_table(i).region_type);
             WSH_DEBUG_SV.log(l_module_name,' Parent Region : ' || l_parent_region);
          END IF;

          Insert_Record (
                 p_location_id     => p_location_id,
                 p_region_id       => l_region_table(i).region_id,
                 p_region_type     => l_region_table(i).region_type,
                 p_exception       => 'N',
                 p_location_source => l_location_source,
                 p_parent_region   => l_parent_region,
                 x_return_status   => l_return_status);

          IF l_debug_on THEN
             WSH_DEBUG_SV.log(l_module_name,'After calling Insert_Record for location id :' || p_location_id);
          END IF;

          IF l_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
                  RAISE Insert_Failed;
          END IF;

          l_rows_after := l_rows_after + 1; -- Bug 3736133

       END IF;

       EXIT WHEN i = l_region_table.LAST;
       i := l_region_table.NEXT(i);
   END LOOP;   --  4. region hierarchy
  END IF;

  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name,'No. of mapped regions after deletion and reinsert ', l_rows_after);
  END IF;

  --------------------------------------------------------
  --  If the number of locations that was matching before
  --  is less than now or no match is found, update the exception flag
  --  to 'Y'
  --------------------------------------------------------

  IF (l_rows_after < l_rows_before AND l_rows_before > 0) OR l_region_table.COUNT = 0 THEN

    -- There is a possibility that exception flags are updated for mappings
    -- in one language, but they are visible in the UI
    -- from another language.
    -- 02/04 discussed and validated with Rohit
    -- the user will have to map again

    UPDATE wsh_region_locations
    SET    exception_type = 'Y'
    WHERE  location_id = p_location_id
    and region_id in (select wrt.region_id from wsh_regions_tl wrt,
                         wsh_regions wr
                         where wrt.region_id = wr.region_id
                         and wrt.language = USERENV('LANG'));

    -- Vijay 08/25: added call to put exception WSH_LOCATION_REGIONS_2_ERR

    wsh_xc_util.log_exception(
                     p_api_version             => 1.0,
                     x_return_status           => l_return_status,
                     x_msg_count               => l_exception_msg_count,
                     x_msg_data                => l_exception_msg_data,
                     x_exception_id            => l_dummy_exception_id ,
                     p_logged_at_location_id   => p_location_id,
                     p_exception_location_id   => p_location_id,
                     p_logging_entity          => 'SHIPPER',
                     p_logging_entity_id       => FND_GLOBAL.USER_ID,
                     p_exception_name          => 'WSH_LOCATION_REGIONS_2',
                     p_message                 => 'WSH_LOCATION_REGIONS_2_ERR'
                     );

  END IF;

  --------------------------------------------------------
  --  If the number of regions being matched is only one set
  --  exception WSH_LOCATION_REGIONS_1_ERR
  --------------------------------------------------------

  IF (l_rows_after = l_rows_before AND l_rows_before = 1) THEN

    wsh_xc_util.log_exception(
                     p_api_version             => 1.0,
                     x_return_status           => l_return_status,
                     x_msg_count               => l_exception_msg_count,
                     x_msg_data                => l_exception_msg_data,
                     x_exception_id            => l_dummy_exception_id ,
                     p_logged_at_location_id   => p_location_id,
                     p_exception_location_id   => p_location_id,
                     p_logging_entity          => 'SHIPPER',
                     p_logging_entity_id       => FND_GLOBAL.USER_ID,
                     p_exception_name          => 'WSH_LOCATION_REGIONS_1',
                     p_message                 => 'WSH_LOCATION_REGIONS_1_ERR'
                     );

  END IF;

  x_return_status := l_return_status;

  IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
  END IF;

EXCEPTION

    WHEN Insert_Failed THEN
     rollback to wsh_location_exists;
     x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'Failed in API Insert_Record');
        WSH_DEBUG_SV.pop(l_module_name);
     END IF;

    WHEN Others THEN
     rollback to wsh_location_exists;
     x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
     l_sqlcode := SQLCODE;
     l_sqlerr := SQLERRM;
     IF l_debug_on THEN
        WSH_DEBUG_SV.log(l_module_name,'When Others of Procedure Map_Location_To_Region');
        WSH_DEBUG_SV.log(l_module_name,'SQLCODE :' || l_sqlcode);
        WSH_DEBUG_SV.log(l_module_name,'Error :' || l_sqlerr);
        WSH_DEBUG_SV.pop(l_module_name);
     END IF;

END Map_Location_To_Region;

/*===========================================================================+
 | FUNCTION                                                                  |
 |              Insert_Record                                                |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This API just inserts the record into intersection table     |
 |                                                                           |
 +===========================================================================*/

Procedure Insert_Record
  (
    p_location_id         IN   NUMBER,
    p_region_id           IN   NUMBER,
    p_region_type         IN   NUMBER,
    p_exception           IN   VARCHAR2,
    p_location_source     IN   VARCHAR2,
    p_parent_region       IN   VARCHAR2,
    x_return_status       OUT NOCOPY   VARCHAR2
   ) IS

   l_region_id          NUMBER := 0;
   l_sqlcode            NUMBER;
   l_sqlerr             VARCHAR2(2000);

   BEGIN

       x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

       INSERT INTO WSH_REGION_LOCATIONS(
          region_id,
          location_id,
          exception_type,
          region_type,
          parent_region_flag,
          location_source,
          creation_date,
          created_by,
          last_update_date,
          last_updated_by,
          last_update_login )
       values (
          p_region_id,
          p_location_id,
          p_exception,
          p_region_type,
          p_parent_region,
          p_location_source,
          sysdate,
          fnd_global.user_id,
          sysdate,
          fnd_global.user_id,
          fnd_global.login_id
          );

EXCEPTION

  WHEN Others THEN
   WSH_UTIL_CORE.println(' Insert into WSH_REGION_LOCATIONS failed : ' || sqlerrm);
   x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;

End Insert_Record;


/*===========================================================================+
 | FUNCTION                                                                  |
 |              Rule_Location                                                |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the rule function for the following TCA events :     |
 |                   # oracle.apps.ar.hz.Location.create                     |
 |                   # oracle.apps.ar.hz.Location.update                     |
 |              This calls the Mapping_Regions_Main API to recreate the      |
 |              mapping once a location gets created or a location gets      |
 |              updated.                                                     |
 |                                                                           |
 +===========================================================================*/

FUNCTION Rule_Location(
               p_subscription_guid  in raw,
               p_event              in out NOCOPY  wf_event_t)
RETURN VARCHAR2 IS

  i_status   varchar2(200);
  myList     wf_parameter_list_t;
  pos        number := 1;

  l_return_status    VARCHAR2(20);
  l_return_status1   VARCHAR2(20);
  p_location_id      NUMBER;
  l_sqlcode          NUMBER;
  l_sqlerr           VARCHAR2(2000);

  l_org_id           NUMBER;
  l_user_id          NUMBER;
  l_resp_id          NUMBER;
  l_resp_appl_id     NUMBER;
  l_security_group_id  NUMBER;

  --
  l_debug_on BOOLEAN;
  --
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'Rule_Location';

BEGIN

  l_org_id := p_event.getValueForParameter('ORG_ID');
  l_user_id := p_event.getValueForParameter('USER_ID');
  l_resp_id := p_event.getValueForParameter('RESP_ID');
  l_resp_appl_id := p_event.getValueForParameter('RESP_APPL_ID');
  l_security_group_id := p_event.getValueForParameter('SECURITY_GROUP_ID');

  fnd_global.apps_initialize(l_user_id,l_resp_id,l_resp_appl_id,l_security_group_id);

  --
   l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
   --
   IF l_debug_on IS NULL
   THEN
       l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
   END IF;
   --
   --
   -- Debug Statements
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.push(l_module_name);
       WSH_DEBUG_SV.log(l_module_name,'USER_ID: ',l_user_id);
       WSH_DEBUG_SV.log(l_module_name,'RESP_ID : ',l_resp_id);
       WSH_DEBUG_SV.log(l_module_name,'RESP_APPL_ID: ',l_resp_appl_id);
       WSH_DEBUG_SV.log(l_module_name,'SECURITY_GROUP_ID: ',l_security_group_id);
       WSH_DEBUG_SV.log(l_module_name,'USERENV LANG: ',USERENV('LANG'));
   END IF;

  myList := p_event.getParameterList();

  IF (myList is null) THEN
      IF l_debug_on THEN
          WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      return NULL;
  END IF;

  pos := myList.LAST;

   WHILE (pos is not null)
   LOOP

     IF myList(pos).getName() = 'LOCATION_ID' THEN
          p_location_id := myList(pos).getValue();
     END IF;

     pos := myList.PRIOR(pos);

   END LOOP;


   XX_CDH_LOCATIONS_PKG.Process_Locations(
     p_from_location     => p_location_id
     , p_to_location       => p_location_id
     , p_start_date        => NULL
     , p_end_date          => NULL
     , x_return_status     => l_return_status1
     , x_sqlcode           => l_sqlcode
     , x_sqlerr            => l_sqlerr );

   XX_CDH_MAP_LOCATION_REGION_PKG.Mapping_Regions_Main(
      p_from_location     => p_location_id
     , p_to_location       => p_location_id
     , p_start_date        => NULL
     , p_end_date          => NULL
     , x_return_status     => l_return_status
     , x_sqlcode           => l_sqlcode
     , x_sqlerr            => l_sqlerr );


    IF l_return_status = WSH_UTIL_CORE.G_RET_STS_SUCCESS and
       l_return_status1 IN
         (WSH_UTIL_CORE.G_RET_STS_SUCCESS, WSH_UTIL_CORE.G_RET_STS_WARNING) THEN
	 IF l_debug_on THEN
         WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      return 'SUCCESS';
    ELSE
      IF l_debug_on THEN
         WSH_DEBUG_SV.pop(l_module_name);
      END IF;
      return 'ERROR';
    END IF;


EXCEPTION

    WHEN Others THEN
      WF_CORE.CONTEXT('WSH_MAP_LOCATIONS_REGIONS', 'Rule_Location',
                            p_event.getEventName( ), p_subscription_guid);
      WF_EVENT.setErrorInfo(p_event, 'ERROR');
      IF l_debug_on THEN
         WSH_DEBUG_SV.pop(l_module_name);
      END IF;
            return 'ERROR';

END Rule_Location;

END XX_CDH_MAP_LOCATION_REGION_PKG;
/
SHOW ERRORS;