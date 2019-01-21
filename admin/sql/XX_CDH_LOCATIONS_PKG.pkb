SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_LOCATIONS_PKG AS

G_PKG_NAME CONSTANT VARCHAR2(50) := 'XX_CDH_LOCATIONS_PKG';
--

  TYPE Generic_Cache_Rec_Typ IS RECORD(
    INPUT_PARAM1           VARCHAR2(500),
    OUTPUT_PARAM1           VARCHAR2(500)
    );

  TYPE Generic_Cache_Tab_Typ IS TABLE OF Generic_Cache_Rec_Typ INDEX BY BINARY_INTEGER;

  g_int_loc_cache Generic_Cache_Tab_Typ;


--========================================================================
-- PROCEDURE : get_table_index
--
-- COMMENT   : Validate using Hash (internal API)
--             uses Hash and avoids linear scans while using PL/SQL tables
-- PARAMETERS:
-- p_validate_rec   -- Input Key to be validated
-- x_generic_tab  -- populated for existing cached records
-- x_index       -- New index which can be used for x_flag = U
-- x_return_status     -- S,E,U,W
-- x_flag    -- U to use this index,D to indicate valid record
--
-- HISTORY   : Bug 3821688
-- NOTE      : For performance reasons, no debug calls are added
--========================================================================
PROCEDURE get_table_index
  (p_validate_rec  IN Generic_Cache_Rec_Typ,
   p_generic_tab   IN Generic_Cache_Tab_Typ,
   x_index         OUT NOCOPY NUMBER,
   x_return_status OUT NOCOPY VARCHAR2,
   x_flag          OUT NOCOPY VARCHAR2
  )IS

  c_hash_base CONSTANT NUMBER := 1;
  c_hash_size CONSTANT NUMBER := power(2, 25);

  l_hash_string      VARCHAR2(3000) := NULL;
  l_index            NUMBER;
  l_hash_exists      BOOLEAN := FALSE;

  l_flag             VARCHAR2(1);

BEGIN

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

    -- need to hash this index
    -- Key (for hash) : param1
    l_hash_string := p_validate_rec.input_param1;

    -- Hash returns a common index if l_hash_string is identical
    l_index := dbms_utility.get_hash_value (
                 name => l_hash_string,
                 base => c_hash_base,
                 hash_size => c_hash_size);
    WHILE NOT l_hash_exists LOOP
      IF p_generic_tab.EXISTS(l_index) THEN
        IF (
            ((p_generic_tab(l_index).input_param1 = p_validate_rec.input_param1)
              OR
             (p_generic_tab(l_index).input_param1 IS NULL AND
              p_validate_rec.input_param1 IS NULL))
           ) THEN
            -- exact match found at this index
            l_flag := 'D';
            EXIT;
        ELSE

          -- Index exists but key does not match this table element
          -- Bump l_index till key matches or table element does not exist
          l_index := l_index + 1;
        END IF;
      ELSE
        -- Index is not used in the table, can be used to create a new record
        l_hash_exists := TRUE; -- to exit from the loop
        l_flag := 'U';
      END IF;
    END LOOP;

  x_index := l_index;
  x_flag := l_flag;

END get_table_index;




 -----------------------------------------------------------------------------------
 -- Start of comments
 -- API name : Get_Missing_Timezones
 -- Type     : Public
 -- Pre-reqs : None.
 -- Function : Obtain timezone codes from the Geocoding API for the locations that
 --            are missing timezone codes.
 --
 -- Parameters :
 --   p_LocationId_Tbl      IN        WSH_LOCATIONS_PKG.ID_Tbl_Type,
 --   p_Country_Tbl         IN        WSH_LOCATIONS_PKG.Address_Tbl_Type
 --   p_State_Tbl           IN        WSH_LOCATIONS_PKG.Address_Tbl_Type
 --   p_Province_Tbl        IN        WSH_LOCATIONS_PKG.Address_Tbl_Type
 --   p_County_Tbl          IN        WSH_LOCATIONS_PKG.Address_Tbl_Type
 --   p_City_Tbl            IN        WSH_LOCATIONS_PKG.Address_Tbl_Type
 --   p_Postal_Code_Tbl     IN        WSH_LOCATIONS_PKG.Address_Tbl_Type
 --   p_Timezone_Tbl        IN        WSH_LOCATIONS_PKG.LocationCode_Tbl_Type
 --
 --   l_debug_on            IN        BOOLEAN
 --   x_return_status       OUT       VARCHAR2
 --   x_error_msg           OUT       VARCHAR2
 --
 -- Version : 1.0
 -- Previous version 1.0
 -- Initial version 1.0
 -- End of comments
 -----------------------------------------------------------------------------------
PROCEDURE Get_Missing_Timezones (p_LocationId_Tbl  IN  WSH_LOCATIONS_PKG.ID_Tbl_Type,
                                 p_Country_Tbl     IN  WSH_LOCATIONS_PKG.Address_Tbl_Type,
                                 p_State_Tbl       IN  WSH_LOCATIONS_PKG.Address_Tbl_Type,
                                 p_Province_Tbl    IN  WSH_LOCATIONS_PKG.Address_Tbl_Type,
                                 p_County_Tbl      IN  WSH_LOCATIONS_PKG.Address_Tbl_Type,
                                 p_City_Tbl        IN  WSH_LOCATIONS_PKG.Address_Tbl_Type,
                                 p_Postal_Code_Tbl IN  WSH_LOCATIONS_PKG.Address_Tbl_Type,
                                 l_debug_on        IN  BOOLEAN,
                                 x_Latitude_Tbl    IN  OUT NOCOPY WSH_LOCATIONS_PKG.ID_Tbl_Type,
                                 x_Longitude_Tbl   IN  OUT NOCOPY WSH_LOCATIONS_PKG.ID_Tbl_Type,
                                 x_Timezone_Tbl    IN  OUT NOCOPY WSH_LOCATIONS_PKG.LocationCode_Tbl_Type,
                                 x_return_status   OUT NOCOPY VARCHAR2,
                                 x_error_msg       OUT NOCOPY VARCHAR2) IS

 l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_MISSING_TIMEZONES';
 l_msg_count   VARCHAR2(100);
 l_location    WSH_LOCATIONS_PKG.LOCATION_REC_TYPE;

 BEGIN

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
  END IF;

  FOR i IN p_LocationId_Tbl.FIRST..p_LocationId_Tbl.LAST LOOP
    IF (x_Timezone_Tbl(i) IS NULL OR
        x_Longitude_Tbl(i) IS NULL OR
        x_Latitude_Tbl(i) IS NULL) THEN

      l_location.COUNTRY       := p_Country_Tbl(i);
      l_location.STATE         := p_State_Tbl(i);
      l_location.PROVINCE      := p_Province_Tbl(i);
      l_location.COUNTY        := p_County_Tbl(i);
      l_location.CITY          := p_City_Tbl(i);
      l_location.POSTAL_CODE   := p_Postal_Code_Tbl(i);
      l_location.LATITUDE      := NULL;
      l_location.LONGITUDE     := NULL;
      l_location.TIMEZONE_CODE := NULL;
      l_location.GEOMETRY      := NULL;

      IF l_debug_on THEN
        WSH_DEBUG_SV.LogMsg(l_module_name, 'Get_Lat_Long_and_Timezone: ' || p_LocationId_Tbl(i));
      END IF;

      WSH_GEOCODING.Get_Lat_Long_and_TimeZone(p_api_version   => 1.0,
                                              p_init_msg_list => NULL,
                                              x_return_status => x_return_status,
                                              x_msg_count     => l_msg_count,
                                              x_msg_data      => x_error_msg,
                                              l_location      => l_location);

      IF l_debug_on THEN
        WSH_DEBUG_SV.Log(l_module_name, 'latitude', l_location.LATITUDE);
        WSH_DEBUG_SV.Log(l_module_name, 'longitude', l_location.LONGITUDE);
        WSH_DEBUG_SV.Log(l_module_name, 'timezone_code', l_location.TIMEZONE_CODE);
      END IF;

      --Update the Latitude, Longitude, Geometry and Timezone Code if
      --The source values are null.

      IF (x_Latitude_Tbl(i) IS NULL) THEN
        x_Latitude_Tbl(i) := l_location.LATITUDE;
      END IF;

      IF (x_Longitude_Tbl(i) IS NULL) THEN
        x_Longitude_Tbl(i) := l_location.LONGITUDE;
      END IF;

      IF (x_Timezone_Tbl(i) IS NULL) THEN
        x_Timezone_Tbl(i) := l_location.TIMEZONE_CODE;
      END IF;

    END IF;

  END LOOP;

  IF x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS THEN
     x_error_msg := 'Error in WSH_GEOCODING.Get_Lat_Long_and_TimeZone ';
     --x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
  END IF;

  IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
  END IF;

 EXCEPTION
  WHEN OTHERS THEN
   x_error_msg := 'Unexpected Error in Get_Missing_Timezones: ' || sqlerrm;
   IF l_debug_on THEN
	WSH_DEBUG_SV.logmsg(l_module_name, x_error_msg);
   END IF;
   --x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
   x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;

   IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
   END IF;

 END Get_Missing_Timezones;



 -----------------------------------------------------------------------------------
 -- Start of comments
 -- API name : Update_Geometries
 -- Type     : Public
 -- Pre-reqs : None.
 -- Function : Updates the wsh_location table and updates the given location_ids
 --            with geometry objects obtained from the given longitudes and latitudes
 --
 -- Parameters :
 --   p_location_ids     IN           WSH_LOCATIONS_PKG.ID_Tbl_Type,
 --   p_latitudes	 IN           WSH_LOCATIONS_PKG.ID_Tbl_Type,
 --   p_longitudes	 IN           WSH_LOCATIONS_PKG.ID_Tbl_Type,
 --   l_debug_on         IN           BOOLEAN
 --   x_return_status    OUT  NOCOPY  VARCHAR2
 --   x_error_msg        OUT  NOCOPY  VARCHAR2
 --
 -- Version : 1.0
 -- Previous version 1.0
 -- Initial version 1.0
 -- End of comments
 -----------------------------------------------------------------------------------
 PROCEDURE Update_Geometries (p_location_ids    IN  	   WSH_LOCATIONS_PKG.ID_Tbl_Type,
                   	      p_latitudes       IN  	   WSH_LOCATIONS_PKG.ID_Tbl_Type,
                  	      p_longitudes	IN  	   WSH_LOCATIONS_PKG.ID_Tbl_Type,
                  	      l_debug_on	IN  	   BOOLEAN,
			      x_return_status	OUT NOCOPY VARCHAR2,
                  	      x_error_msg	OUT NOCOPY VARCHAR2) IS

    k                NUMBER;
    l_location_id    NUMBER;
    l_latitude	     NUMBER;
    l_longitude	     NUMBER;
    l_geometry	     MDSYS.SDO_GEOMETRY;
    l_module_name    CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'UPDATE_GEOMETRIES';

 BEGIN

   IF l_debug_on THEN
     WSH_DEBUG_SV.push(l_module_name);
   END IF;

   k := p_location_ids.FIRST;
   LOOP
     l_location_id := p_location_ids(k);
     l_latitude	   := p_latitudes(k);
     l_longitude   := p_longitudes(k);

     IF (l_latitude IS NOT NULL AND
         l_longitude IS NOT NULL) THEN

	 IF l_debug_on THEN
	   WSH_DEBUG_SV.LogMsg(l_module_name,
	                       'Create Geometry for Lat/Lon: ' || l_latitude || '/'|| l_longitude);
	 END IF;

	 Create_Geometry (p_longitude      => l_longitude,
                          p_latitude       => l_latitude,
                          x_geometry       => l_geometry,
                          x_return_status  => x_return_status,
                          x_error_msg      => x_error_msg);


	 IF (l_geometry IS NOT NULL) THEN

	   IF l_debug_on THEN
	     WSH_DEBUG_SV.LogMsg(l_module_name, 'Geometry Created Succesfully');
	   END IF;

	   BEGIN
	     UPDATE wsh_locations
	     SET geometry = l_geometry
	     WHERE wsh_location_id = p_location_ids(k);
	   EXCEPTION
	    WHEN OTHERS THEN
	      x_error_msg := 'UNEXP. Error in Update Geometries: ' || sqlerrm;
	      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
	   END;
	 END IF;

     END IF;

     EXIT WHEN k = p_location_ids.LAST;
     k := p_location_ids.NEXT(k);
   END LOOP;

   IF l_debug_on THEN
     WSH_DEBUG_SV.pop(l_module_name);
   END IF;

 EXCEPTION
   WHEN OTHERS THEN
     NULL;
 END;


/*===========================================================================+
 | PROCEDURE                                                                 |
 |              Process_Locations                                            |
 |                                                                           |
 | DESCRIPTION                                                               |
 |                                                                           |
 |           This procedure will populate the WSH_LOCATIONS table            |
 |           with the locations in HZ_LOCATIONS (whose usage is deliver_to   |
 |           or ship_to) and HR_LOCATIONS                                    |
 |                                                                           |
 +===========================================================================*/

  --
  -- Parameters
  --
  --   p_location_type         Location Type (EXTERNAL/INTERNAL/BOTH)
  --   p_from_location         From Location ID
  --   p_to_location           To Location ID
  --   p_start_date            Start Date
  --   p_end_date              End Date
  --   If the Start Date and End Date are not null then the locations which are updated
  --   in this date range will be considered.

PROCEDURE Process_Locations
(
  p_from_location        IN   NUMBER,
  p_to_location          IN   NUMBER,
  p_start_date           IN   VARCHAR2,
  p_end_date             IN   VARCHAR2,
  p_create_facilities    IN   VARCHAR2 default NULL,
  p_caller               IN  VARCHAR2 default NULL,
  x_return_status        OUT NOCOPY   VARCHAR2,
  x_sqlcode              OUT NOCOPY   NUMBER,
  x_sqlerr               OUT NOCOPY   VARCHAR2
) IS

l_sqlcode                     NUMBER;
l_sqlerr                      VARCHAR2(2000);
l_log_level                   NUMBER;
l_batchsize                   NUMBER := 500;
l_from_location               NUMBER;
l_to_location                 NUMBER;

pUpdateLocationIdTbl          WSH_LOCATIONS_PKG.ID_Tbl_Type;
pInsertLocationIdTbl          WSH_LOCATIONS_PKG.ID_Tbl_Type;

tempTbl                      WSH_LOCATIONS_PKG.ID_Tbl_Type;

i                             NUMBER;
j                             NUMBER;
l_location_source_code        VARCHAR2(3);
l_previous_rows               NUMBER;
l_current_rows                NUMBER;
l_remaining_rows              NUMBER;

l_geometry                    MDSYS.SDO_GEOMETRY;

-- Cursor Declarations

CURSOR Get_Ext_Update_Loc IS
  SELECT SOURCE_LOCATION_ID,
         HZ.ADDRESS1,
         HZ.ADDRESS2,
         HZ.ADDRESS3,
         HZ.ADDRESS4,
         HZ.COUNTRY,
         HZ.STATE,
         HZ.PROVINCE,
         HZ.COUNTY,
         HZ.CITY,
         HZ.POSTAL_CODE ,
         HZ.ADDRESS_EXPIRATION_DATE ,
         HPS.PARTY_SITE_NUMBER,
         HPS.PARTY_SITE_NUMBER||' : '||HZ.ADDRESS1||'-'||HZ.CITY||'-'||NVL(HZ.STATE,HZ.PROVINCE),
         HP.PARTY_NAME,
         WSH.LATITUDE,
         WSH.LONGITUDE,
         NVL(TZ.TIMEZONE_CODE, WSH.TIMEZONE_CODE),
         SYSDATE
  FROM   WSH_LOCATIONS WSH, HZ_LOCATIONS HZ, HZ_PARTY_SITES HPS, HZ_PARTIES HP, FND_TIMEZONES_B TZ  --3842898 : Replaced fnd_timezones_vl with fnd_timezones_b
  WHERE  SOURCE_LOCATION_ID between p_from_location and p_to_location
  AND    hz.last_update_date >= nvl(to_date(p_start_date,'YYYY/MM/DD HH24:MI:SS'), hz.last_update_date)
  AND    hz.last_update_date <= nvl(to_date(p_end_date,'YYYY/MM/DD HH24:MI:SS'), hz.last_update_date)
  AND    hz.location_id = wsh.source_location_id
  AND    LOCATION_SOURCE_CODE = 'HZ'
  AND    hps.location_id = hz.location_id
  AND    hp.party_id = hps.party_id
  AND    hps.party_site_number =
         (SELECT party_site_number
          FROM hz_party_sites hps1, hz_orig_sys_references osr
          WHERE hps1.location_id = hz.location_id
          AND hps1.party_site_id=osr.owner_table_id
          AND osr.owner_table_name='HZ_PARTY_SITES'
          AND osr.orig_system='RMS'
          AND rownum = 1)
  AND    hz.timezone_id = tz.upgrade_tz_id(+)
  ORDER BY HZ.LOCATION_ID;

CURSOR Get_Ext_Insert_Loc IS
  SELECT HZ.LOCATION_ID,
         HZ.ADDRESS1,
         HZ.ADDRESS2,
         HZ.ADDRESS3,
         HZ.ADDRESS4,
         HZ.COUNTRY,
         HZ.STATE,
         HZ.PROVINCE,
         HZ.COUNTY,
         HZ.CITY,
         HZ.POSTAL_CODE ,
         HZ.ADDRESS_EXPIRATION_DATE ,
         HPS.PARTY_SITE_NUMBER,
         HPS.PARTY_SITE_NUMBER||' : '||HZ.ADDRESS1||'-'||HZ.CITY||'-'||NVL(HZ.STATE,HZ.PROVINCE),
         HP.PARTY_NAME,
         NULL,
         NULL,
         TZ.TIMEZONE_CODE
  FROM   HZ_LOCATIONS HZ, HZ_PARTY_SITES HPS, HZ_PARTIES HP, FND_TIMEZONES_VL TZ
  WHERE  HZ.LOCATION_ID between p_from_location and p_to_location
  AND    hz.last_update_date >= nvl(to_date(p_start_date,'YYYY/MM/DD HH24:MI:SS'), hz.last_update_date)
  AND    hz.last_update_date <= nvl(to_date(p_end_date,'YYYY/MM/DD HH24:MI:SS'), hz.last_update_date)
  AND    hz.location_id NOT IN ( select /*+ INDEX (wl,WSH_LOCATIONS_N1) */
                                 wl.source_location_id
                                 from wsh_locations wl
                                 where wl.location_source_code = 'HZ'
                                 and wl.source_location_id = hz.location_id)
  AND    hps.location_id = hz.location_id
  AND    hp.party_id = hps.party_id
  AND    hps.party_site_number =
         (SELECT party_site_number
          FROM hz_party_sites hps, hz_orig_sys_references osr
          WHERE hps.location_id = hz.location_id
          AND hps.party_site_id=osr.owner_table_id
          AND osr.owner_table_name='HZ_PARTY_SITES'
          AND osr.orig_system='RMS'
          AND rownum = 1)
  AND    hz.timezone_id = tz.upgrade_tz_id(+)
  ORDER BY HZ.LOCATION_ID;



--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'PROCESS_LOCATIONS';
--
BEGIN

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
      --
      WSH_DEBUG_SV.log(l_module_name,'P_FROM_LOCATION',P_FROM_LOCATION);
      WSH_DEBUG_SV.log(l_module_name,'P_TO_LOCATION',P_TO_LOCATION);
      WSH_DEBUG_SV.log(l_module_name,'P_START_DATE',P_START_DATE);
      WSH_DEBUG_SV.log(l_module_name,'P_END_DATE',P_END_DATE);
      WSH_DEBUG_SV.log(l_module_name,'P_CREATE_FACILITIES',P_CREATE_FACILITIES);
      WSH_DEBUG_SV.log(l_module_name,'P_CALLER',P_CALLER);
  END IF;
  --
  l_log_level         :=  FND_PROFILE.VALUE('ONT_DEBUG_LEVEL');

  /*
  WSH_UTIL_CORE.Enable_Concurrent_Log_Print;

   IF l_log_level IS NOT NULL THEN
     WSH_UTIL_CORE.Set_Log_Level(l_log_level);
   END IF;
  */
  IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,'In the procedure Process_Locations');
     WSH_DEBUG_SV.logmsg(l_module_name,'Processing Locations between ' || p_from_location || ' and '|| p_to_location);
  END IF;
  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  l_previous_rows := 0;

  
      IF l_debug_on THEN
         WSH_DEBUG_SV.logmsg(l_module_name,'Processing the External Locations');
      END IF;

      l_location_source_code := 'HZ';

      OPEN Get_Ext_Update_Loc;
      LOOP
         FETCH Get_Ext_Update_Loc BULK COLLECT INTO
               pUpdateLocationIdTbl,
               pUpdateAddress1Tbl,
               pUpdateAddress2Tbl,
               pUpdateAddress3Tbl,
               pUpdateAddress4Tbl,
               pUpdateCountryTbl,
               pUpdateStateTbl,
               pUpdateProvinceTbl,
               pUpdateCountyTbl,
               pUpdateCityTbl,
               pUpdatePostalCodeTbl,
               pUpdateExpDateTbl,
               pUpdateLocCodeTbl,
               pUpdateUILocCodeTbl,
               pUpdateOwnerNameTbl,
               pLatitudeTbl,
               pLongitudeTbl,
               pTimezoneTbl,
               pLastUpdateDateTbl
          LIMIT l_Batchsize;

          l_current_rows   := Get_Ext_Update_Loc%rowcount ;
          l_remaining_rows := l_current_rows - l_previous_rows;

          IF (l_remaining_rows <= 0) then
            EXIT;
          END IF;

          l_previous_rows := l_current_rows ;

          IF pUpdateLocationIdTbl.COUNT <> 0 THEN
	    IF l_debug_on THEN
	        WSH_DEBUG_SV.logmsg(l_module_name,' found '||pUpdateLocationIdTbl.COUNT||' hz locations for update ');
	    END IF;
            -- Bug 3373128 : OMFST:J:FTE: LOCATION CODE DISPLAYED TWICE
	    -- Commenting the code for get_site_number
	    -- pUpDateUILocCode and pUpdateLocCodeTb1 populated in the cursor.
	    -- get_site_number(pUpdateLocationIdTbl, pUpdateLocCodeTbl, pUpdateUILocCodeTbl);

            Get_Missing_Timezones(p_LocationId_Tbl  => pUpdateLocationIdTbl,
                                  p_Country_Tbl     => pUpdateCountryTbl,
                                  p_State_Tbl       => pUpdateStateTbl,
                                  p_Province_Tbl    => pUpdateProvinceTbl,
                                  p_County_Tbl      => pUpdateCountyTbl,
                                  p_City_Tbl        => pUpdateCityTbl,
                                  p_Postal_Code_Tbl => pUpdatePostalCodeTbl,
                                  l_debug_on        => l_debug_on,
                                  x_Latitude_Tbl    => pLatitudeTbl,
                                  x_Longitude_Tbl   => pLongitudeTbl,
                                  x_Timezone_Tbl    => pTimezoneTbl,
                                  x_return_status   => x_return_status,
                                  x_error_msg       => x_sqlerr);

            IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
	       IF l_debug_on THEN
	          WSH_DEBUG_SV.logmsg(l_module_name,'Get_Missing_Timezones : ' || x_sqlerr);
	       END IF;
               x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
            END IF;

            Update_Locations(pUpdateLocationIdTbl,l_location_source_code,x_return_status);

            IF (x_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR,WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)) THEN
	       IF l_debug_on THEN
                  WSH_DEBUG_SV.logmsg(l_module_name,'Error in Update_Locations ');
		  WSH_DEBUG_SV.pop(l_module_name);
	       END IF;
               --x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
               return;
            END IF;
	    IF l_debug_on THEN
                WSH_DEBUG_SV.logmsg(l_module_name,'Successful in the update operation');
	    END IF;

            --Create facilities for the locations, if necessary.
            --'N' is the default for the <p_create_facilities> parameter.
            -- 1. If this procedure is explicitly called with 'Y', then we create facilities.
            -- 2. If <p_create_facilities> is NULL, then we create facilities only if TP is installed.
            IF (UPPER(p_create_facilities) = 'Y' OR
                (p_create_facilities IS NULL AND WSH_UTIL_CORE.Tp_Is_Installed = 'Y')) THEN
              i := pUpdateLocationIdTbl.COUNT;
	      IF l_debug_on THEN
	          WSH_DEBUG_SV.logmsg(l_module_name,
                                  'Calling WSH_FACILITIES_INTEGRATION.CREATE_FACILITIES with ' ||i|| ' External locations.');
	      END IF;
              BEGIN

                WSH_FACILITIES_INTEGRATION.Create_Facilities(p_location_ids  => pUpdateLocationIdTbl,
                                                             p_company_names => pUpdateOwnerNameTbl,
                                                             p_site_names    => pUpdateLocCodeTbl,
                                                             x_return_status => x_return_status,
                                                             x_error_msg     => x_sqlerr);

                IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
		  IF l_debug_on THEN
	              WSH_DEBUG_SV.logmsg(l_module_name,'Create Facilities: ' || x_sqlerr);
		  END IF;
                  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                END IF;

              EXCEPTION
                WHEN OTHERS THEN
		  IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'UNEXP. EXCEPTION WHILE CREATING FACILITIES: ' || sqlerrm);
		  END IF;
                  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
              END;
            END IF;

            --If TP is installed, manually create a Geometry object from the latitude and longitude
            -- and update the location with the geometry object.
            IF (WSH_UTIL_CORE.Tp_Is_Installed = 'Y') THEN
              BEGIN
              	Update_Geometries(p_location_ids  => pUpdateLocationIdTbl,
              			  p_latitudes     => pLatitudeTbl,
              			  p_longitudes    => pLongitudeTbl,
				  l_debug_on	  => l_debug_on,
              			  x_return_status => x_return_status,
              			  x_error_msg     => x_sqlerr);
              EXCEPTION
	        WHEN OTHERS THEN
		  IF l_debug_on THEN
		    WSH_DEBUG_SV.logmsg(l_module_name,'UNEXP. Exception while updating geometries: ' || sqlerrm);
		  END IF;
		  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	      END;
            END IF;

          END IF;

          EXIT WHEN Get_Ext_Update_Loc%NOTFOUND;
      END LOOP;

      IF Get_Ext_Update_Loc%ISOPEN THEN
         CLOSE Get_Ext_Update_Loc;
      END IF;

      ----------------------------------------------------------------
      l_previous_rows := 0;
      OPEN Get_Ext_Insert_Loc;
      LOOP
         FETCH Get_Ext_Insert_Loc BULK COLLECT INTO
               pInsertLocationIdTbl,
               pInsertAddress1Tbl,
               pInsertAddress2Tbl,
               pInsertAddress3Tbl,
               pInsertAddress4Tbl,
               pInsertCountryTbl,
               pInsertStateTbl,
               pInsertProvinceTbl,
               pInsertCountyTbl,
               pInsertCityTbl,
               pInsertPostalCodeTbl,
               pInsertExpDateTbl,
               pInsertLocCodeTbl,
               pInsertUILocCodeTbl,
               pInsertOwnerNameTbl,
               pLatitudeTbl,
               pLongitudeTbl,
               pTimezoneTbl
         LIMIT l_batchsize;

         l_current_rows   := Get_Ext_Insert_Loc%rowcount ;
         l_remaining_rows := l_current_rows - l_previous_rows;

         IF (l_remaining_rows <= 0) then
           EXIT;
         END IF;

          l_previous_rows := l_current_rows ;

          IF pInsertLocationIdTbl.COUNT = 0 THEN
	    IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Number of locations to be inserted or updated in this range is 0');
	    END IF;
            --
            -- Debug Statements
            --
            IF l_debug_on THEN
                WSH_DEBUG_SV.pop(l_module_name);
            END IF;
            --
            return ;
          END IF;

          IF pInsertLocationIdTbl.COUNT <> 0 THEN
	    IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,' found '||pInsertLocationIdTbl.COUNT||' hz locations for insert ');
	    END IF;
-- Vijay: commenting out
--            get_site_number(pInsertLocationIdTbl, pInsertLocCodeTbl, pInsertUILocCodeTbl);

            Get_Missing_Timezones(p_LocationId_Tbl  => pInsertLocationIdTbl,
                                  p_Country_Tbl     => pInsertCountryTbl,
                                  p_State_Tbl       => pInsertStateTbl,
                                  p_Province_Tbl    => pInsertProvinceTbl,
                                  p_County_Tbl      => pInsertCountyTbl,
                                  p_City_Tbl        => pInsertCityTbl,
                                  p_Postal_Code_Tbl => pInsertPostalCodeTbl,
                                  l_debug_on        => l_debug_on,
                                  x_Latitude_Tbl    => pLatitudeTbl,
                                  x_Longitude_Tbl   => pLongitudeTbl,
                                  x_Timezone_Tbl    => pTimezoneTbl,
                                  x_return_status   => x_return_status,
                                  x_error_msg       => x_sqlerr);

            IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
	       IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Get_Missing_Timezones : ' || x_sqlerr);
               END IF;
               x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
            END IF;

            Insert_Locations(pInsertLocationIdTbl,l_location_source_code,x_return_status);

            IF (x_return_status IN (WSH_UTIL_CORE.G_RET_STS_ERROR,WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR)) THEN
	       IF l_debug_on THEN
                 WSH_DEBUG_SV.logmsg(l_module_name,'Error in Insert_Locations ');
	       END IF;
               --x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
               IF l_debug_on THEN
                  WSH_DEBUG_SV.pop(l_module_name);
               END IF;
               return;
            END IF;
	    IF l_debug_on THEN
              WSH_DEBUG_SV.logmsg(l_module_name,'Successful in the insert operation');
	    END IF;
            --Create facilities for the locations, if necessary.
            --'N' is the default for the <p_create_facilities> parameter.
            -- 1. If this procedure is explicitly called with 'Y', then we create facilities.
            -- 2. If <p_create_facilities> is NULL, then we create facilities only if TP is installed.
            IF (UPPER(p_create_facilities) = 'Y' OR
                (p_create_facilities IS NULL AND WSH_UTIL_CORE.Tp_Is_Installed = 'Y')) THEN
              i := pInsertLocationIdTbl.COUNT;
	      IF l_debug_on THEN
                WSH_DEBUG_SV.logmsg(l_module_name,'Calling WSH_FACILITIES_INTEGRATION.CREATE_FACILITIES with ' ||i|| 'External locations.');
              END IF;
              BEGIN

                WSH_FACILITIES_INTEGRATION.Create_Facilities(p_location_ids  => pInsertLocationIdTbl,
                                                      	     p_company_names => pInsertOwnerNameTbl,
                                                      	     p_site_names    => pInsertLocCodeTbl,
                                                      	     x_return_status => x_return_status,
                                                      	     x_error_msg     => x_sqlerr);

                  IF (x_return_status <> WSH_UTIL_CORE.G_RET_STS_SUCCESS) THEN
		    IF l_debug_on THEN
                      WSH_DEBUG_SV.logmsg(l_module_name,'Create Facilities: ' || x_sqlerr);
		    END IF;
                    x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
                  END IF;

              EXCEPTION
                WHEN OTHERS THEN
		  IF l_debug_on THEN
                    WSH_DEBUG_SV.logmsg(l_module_name,'UNEXP. EXCEPTION WHILE CREATING FACILITIES: ' || sqlerrm);
		  END IF;
                  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
              END;

            END IF;


            --If TP is installed, manually create a Geometry object from the latitude and longitude
            -- and update the location with the geometry object.
            IF (WSH_UTIL_CORE.Tp_Is_Installed = 'Y') THEN
              BEGIN
              	Update_Geometries(p_location_ids  => pInsertLocationIdTbl,
              			  p_latitudes     => pLatitudeTbl,
              			  p_longitudes    => pLongitudeTbl,
				  l_debug_on	  => l_debug_on,
              			  x_return_status => x_return_status,
              			  x_error_msg     => x_sqlerr);
              EXCEPTION
	        WHEN OTHERS THEN
		  IF l_debug_on THEN
		    WSH_DEBUG_SV.logmsg(l_module_name,'UNEXP. Exception while updating geometries: ' || sqlerrm);
		  END IF;
		  x_return_status := WSH_UTIL_CORE.G_RET_STS_WARNING;
	      END;
            END IF;

          END IF;

          EXIT WHEN Get_Ext_Insert_Loc%NOTFOUND;
      END LOOP;

        IF Get_Ext_Insert_Loc%ISOPEN THEN
           CLOSE Get_Ext_Insert_Loc;
        END IF;

  -- End of External Location Type

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
  EXCEPTION
   WHEN others THEN
     x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
     l_sqlcode := SQLCODE;
     l_sqlerr  := SQLERRM;
     --
     -- Debug Statements
     --
     IF l_debug_on THEN
       WSH_DEBUG_SV.pop(l_module_name);
       WSH_DEBUG_SV.logmsg(l_module_name,'In the Others Exception of Locations_Child');
       WSH_DEBUG_SV.logmsg(l_module_name,'SQLCODE : ' || l_sqlcode);
       WSH_DEBUG_SV.logmsg(l_module_name,'SQLERRM : '  || l_sqlerr);
     END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
    WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
END IF;
--
  END Process_Locations;


PROCEDURE get_site_number(pLocationIdTbl   IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                          pLocationCodeTbl IN OUT NOCOPY WSH_LOCATIONS_PKG.LocationCode_Tbl_Type,
                          pUILocationCodeTbl IN OUT NOCOPY WSH_LOCATIONS_PKG.LocationCode_Tbl_Type)
IS
CURSOR get_site_number(l_location_id NUMBER) IS
  SELECT party_site_number
  FROM   hz_party_sites hps
  WHERE  hps.location_id = l_location_id;

i NUMBER;
l_site_number1 VARCHAR2(30);
l_site_number2 VARCHAR2(30);

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_SITE_NUMBER';
--
BEGIN

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
   END IF;
   --
   FOR i IN 1..pLocationIdTbl.count LOOP

     l_site_number1 := null;
     l_site_number2 := null;

     pLocationCodeTbl(i) := null;

     OPEN get_site_number(pLocationIdTbl(i));
     FETCH get_site_number INTO l_site_number1;

     IF (l_site_number1 IS NOT NULL) THEN

-- Vijay: commenting out to be in sync with upgrade script changes on 5/12/03
--        FETCH get_site_number INTO l_site_number2;

--      IF (l_site_number2 IS NULL) THEN

            pLocationCodeTbl(i) := l_site_number1;
            pUILocationCodeTbl(i) := l_site_number1 || ' : ' || pUILocationCodeTbl(i);

--      END IF;

     END IF;
     CLOSE get_site_number;

   END LOOP;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
END get_site_number;


PROCEDURE insert_locations(pInsertLocationIdTbl   IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                           p_location_source_code IN VARCHAR2,
                           x_return_status OUT NOCOPY VARCHAR2)
IS
i NUMBER;
j NUMBER;
l_error_code               NUMBER;
l_start                    NUMBER;
l_loc_id                   NUMBER;
--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'INSERT_LOCATIONS';
--
BEGIN

        x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
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
            --
            WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_SOURCE_CODE',P_LOCATION_SOURCE_CODE);
        END IF;
        --
        BEGIN
         l_start := pInsertLocationIdTbl.FIRST;

         LOOP
           BEGIN
             forall i in l_start..pInsertLocationIdTbl.LAST
               Insert into  WSH_LOCATIONS
                    (WSH_LOCATION_ID,
                     SOURCE_LOCATION_ID,
                     LOCATION_SOURCE_CODE,
                     LOCATION_CODE,
                     ADDRESS1,
                     ADDRESS2,
                     ADDRESS3,
                     ADDRESS4,
                     COUNTRY,
                     STATE,
                     PROVINCE,
                     COUNTY,
                     CITY,
                     POSTAL_CODE,
                     INACTIVE_DATE,
                     CREATION_DATE,
                     CREATED_BY,
                     LAST_UPDATE_DATE,
                     LAST_UPDATED_BY,
                     UI_LOCATION_CODE,
                     LATITUDE,
                     LONGITUDE,
                     TIMEZONE_CODE)
             Values (pInsertLocationIdTbl(i),
                     pInsertLocationIdTbl(i),
                     p_location_source_code,
                     pInsertLocCodeTbl(i),
                     pInsertAddress1Tbl(i),
                     pInsertAddress2Tbl(i),
                     pInsertAddress3Tbl(i),
                     pInsertAddress4Tbl(i),
                     pInsertCountryTbl(i),
                     pInsertStateTbl(i),
                     pInsertProvinceTbl(i),
                     pInsertCountyTbl(i),
                     pInsertCityTbl(i),
                     pInsertPostalCodeTbl(i),
                     pInsertExpDateTbl(i),
                     SYSDATE,
                     1,
                     SYSDATE,
                     1,
                     pInsertUILocCodeTbl(i),
                     pLatitudeTbl(i),
                     pLongitudeTbl(i),
                     pTimezoneTbl(i));
             EXIT;
           EXCEPTION
             WHEN OTHERS THEN
               l_error_code := SQLCODE;
               l_loc_id := pInsertLocationIdTbl(l_start + sql%rowcount);
               --ORA:00001 is the unique constraint violation. We are attempting
               --to insert a facility that already exists.
               IF ( l_error_code = -1 ) THEN
	         IF l_debug_on THEN
                   WSH_DEBUG_SV.logmsg(l_module_name,'Duplicate location id found for location_id '||l_loc_id);
		 END IF;
                 l_start := l_start + sql%rowcount + 1;
               ELSE
	         IF l_debug_on THEN
                   WSH_DEBUG_SV.logmsg(l_module_name,'UNEXPECTED ERROR WHILE CREATING WSH_LOCATION LOCATION '||l_loc_id);
                   WSH_DEBUG_SV.logmsg(l_module_name,'ERROR MESSAGE '||SQLERRM);
		 END IF;
                 x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
                 IF l_debug_on THEN
                    WSH_DEBUG_SV.pop(l_module_name);
                 END IF;
                 RETURN;
               END IF;
           END;
          END LOOP;
        END;

    --IF (WSH_UTIL_CORE.FTE_Is_Installed = 'Y') THEN
       insert_location_owners(pInsertLocationIdTbl, p_location_source_code,x_return_status);
    --END IF;

    --
    -- Debug Statements
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
END insert_locations;

PROCEDURE update_locations(pUpdateLocationIdTbl   IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                           p_location_source_code IN VARCHAR2,
                           x_return_status OUT NOCOPY VARCHAR2)
IS
i NUMBER;
j NUMBER;
l_error_code               NUMBER;
l_loc_id                   NUMBER;
--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'UPDATE_LOCATIONS';
--
BEGIN

    x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
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
        --
        WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_SOURCE_CODE',P_LOCATION_SOURCE_CODE);
    END IF;
    --
    BEGIN
    forall i in pUpdateLocationIdTbl.FIRST..pUpdateLocationIdTbl.LAST
      update WSH_LOCATIONS
      set location_code    = pUpdateLocCodeTbl(i),
          address1         = pUpdateAddress1Tbl(i),
          address2         = pUpdateAddress2Tbl(i),
          address3         = pUpdateAddress3Tbl(i),
          address4         = pUpdateAddress4Tbl(i),
          country          = pUpdateCountryTbl(i),
          state            = pUpdateStateTbl(i),
          province         = pUpdateProvinceTbl(i),
          county           = pUpdateCountyTbl(i),
          city             = pUpdateCityTbl(i),
          postal_code      = pUpdatePostalCodeTbl(i),
          inactive_date    = pUpdateExpDateTbl(i),
          latitude         = pLatitudeTbl(i),
          longitude        = pLongitudeTbl(i),
          timezone_code    = pTimezoneTbl(i),
          ui_location_code = pUpdateUILocCodeTbl(i),
          last_update_date = pLastUpdateDateTbl(i)
      where SOURCE_LOCATION_ID = pUpdateLocationIdTbl(i)
      and location_source_code = p_location_source_code;

   EXCEPTION
     WHEN OTHERS THEN
       l_loc_id := pUpdateLocCodeTbl(pUpdateLocationIdTbl.FIRST + sql%rowcount);
       x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
       IF l_debug_on THEN
	  WSH_DEBUG_SV.logmsg(l_module_name,'UNEXPECTED ERROR WHILE UPDATING WSH_LOCATION FOR LOCATION '||l_loc_id);
          WSH_DEBUG_SV.logmsg(l_module_name,'ERROR MESSAGE '||SQLERRM);
          WSH_DEBUG_SV.pop(l_module_name);
       END IF;
       return;
    END;
    --IF (WSH_UTIL_CORE.FTE_Is_Installed = 'Y') THEN
      insert_location_owners(pUpdateLocationIdTbl, p_location_source_code,x_return_status);
    --END IF;

    --
    -- Debug Statements
    --
    IF l_debug_on THEN
        WSH_DEBUG_SV.pop(l_module_name);
    END IF;
    --
END update_locations;


PROCEDURE get_location_owner(p_location_id IN NUMBER,
                             p_location_source_code IN VARCHAR2) IS

CURSOR get_location_info(c_location_id IN NUMBER) IS
SELECT owner_party_id
FROM   wsh_location_owners
WHERE  wsh_location_id = c_location_id;

CURSOR get_party_info(c_location_id IN NUMBER) IS
SELECT distinct ps.party_id
FROM   hz_party_sites ps
WHERE  ps.location_id = c_location_id;

-- TODO
-- might not be tied to internal org
CURSOR get_org_info(c_location_id IN NUMBER) IS
SELECT ou.organization_id
FROM   hr_organization_units ou, mtl_parameters mp
WHERE  ou.organization_id = mp.organization_id
       AND ou.location_id = c_location_id;

CURSOR check_party_carrier_supplier(l_party_id IN NUMBER) IS
SELECT 3
FROM   wsh_carriers c
WHERE  c.carrier_id = l_party_id
UNION ALL
SELECT 4
FROM   hz_relationships r, po_vendors v
WHERE  r.relationship_type = 'POS_VENDOR_PARTY' AND
       r.subject_id = v.vendor_id AND
       r.object_id = l_party_id;

cnt NUMBER;
l_owner_type NUMBER;
l_party_id NUMBER;
l_organization_id NUMBER;

--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'GET_LOCATION_OWNER';
--
BEGIN

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
       --
       WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_ID',P_LOCATION_ID);
       WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_SOURCE_CODE',P_LOCATION_SOURCE_CODE);
   END IF;
   --
   -- Found out that this API is getting called  multiple times for the same location_id
   IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,' getting owner for location '||p_location_id);
   END IF;

   OPEN get_location_info(p_location_id);
   FETCH get_location_info INTO l_party_id;
   CLOSE get_location_info;

   IF (l_party_id IS NULL) THEN

      cnt := pLocOwnerIdTbl.count;

      IF (p_location_source_code = 'HR') THEN

         OPEN get_org_info(p_location_id);
         LOOP
           FETCH get_org_info INTO l_organization_id;
           EXIT WHEN get_org_info%NOTFOUND;

           cnt := cnt + 1;
           pLocLocationIdTbl(cnt) := p_location_id;
           pLocOwnerIdTbl(cnt) := l_organization_id;
           pLocOwnerTypeTbl(cnt) := 1;
         END LOOP;
         IF get_org_info%ROWCOUNT = 0 THEN

           cnt := cnt + 1;
           pLocLocationIdTbl(cnt) := p_location_id;
           pLocOwnerIdTbl(cnt) := -1;
           pLocOwnerTypeTbl(cnt) := 1;
         END IF;
         CLOSE get_org_info;
         /*
         FOR orgs IN get_org_info(p_location_id) LOOP

            cnt := cnt + 1;

            pLocLocationIdTbl(cnt) := p_location_id;
            pLocOwnerIdTbl(cnt) := orgs.organization_id;
            pLocOwnerTypeTbl(cnt) := 1;

         END LOOP;
         */

      ELSE

         FOR parties IN get_party_info(p_location_id) LOOP

            cnt := cnt + 1;

            pLocLocationIdTbl(cnt) := p_location_id;
            pLocOwnerIdTbl(cnt) := parties.party_id;

            l_owner_type := 2;

            OPEN check_party_carrier_supplier(parties.party_id);
            FETCH check_party_carrier_supplier INTO l_owner_type;
            CLOSE check_party_carrier_supplier;

            -- If party is carrier OR supplier,
            -- l_owner_type will be 3 OR 4 ( <> 2)
            -- Otherwise, value of l_owner_type will not change

            --
            IF l_debug_on THEN
                WSH_DEBUG_SV.log(l_module_name,'l_owner_type after check_party_carrier_supplier : ',l_owner_type);
            END IF;
            --

            IF (l_owner_type IS NULL) THEN
               l_owner_type := 2;
            END IF;
            pLocOwnerTypeTbl(cnt) := l_owner_type;

         END LOOP;

      END IF;

   END IF;

--
-- Debug Statements
--
IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
END IF;
--
END get_location_owner;



PROCEDURE insert_location_owners(pLocationIdTbl      IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                                 p_location_source_code    IN VARCHAR2,
                                 x_return_status OUT NOCOPY VARCHAR2)
IS
i              NUMBER;
j              NUMBER;
cnt            NUMBER;
l_start        NUMBER;
l_error_code   NUMBER;
l_loc_id       NUMBER;
--
l_debug_on BOOLEAN;
--
l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'INSERT_LOCATION_OWNERS';
--
BEGIN
   x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;
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
       --
       WSH_DEBUG_SV.log(l_module_name,'P_LOCATION_SOURCE_CODE',P_LOCATION_SOURCE_CODE);
   END IF;
   --
   pLocLocationIdTbl.delete;
   pLocOwnerIdTbl.delete;
   pLocOwnerTypeTbl.delete;
   IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,' Number of locations being processed '||pLocationIdTbl.count);
   END IF;
   FOR cnt IN 1..pLocationIdTbl.count LOOP
      get_location_owner(pLocationIdTbl(cnt),p_location_source_code);
   END LOOP;
   IF l_debug_on THEN
     WSH_DEBUG_SV.logmsg(l_module_name,' Inserting owner table count '||pLocLocationIdTbl.count);
   END IF;
   IF (pLocLocationIdTbl.count > 0) THEN

     BEGIN
       l_start := pLocLocationIdTbl.FIRST;
       LOOP
        BEGIN
	    FORALL i in l_start..pLocLocationIdTbl.LAST
	     --Primary key - location_owner_id
	    Insert into  WSH_LOCATION_OWNERS
                 ( LOCATION_OWNER_ID,
		  WSH_LOCATION_ID,
                  OWNER_PARTY_ID,
                  OWNER_TYPE,
                  CREATION_DATE,
                  CREATED_BY,
                  LAST_UPDATE_DATE,
                  LAST_UPDATED_BY,
                  LAST_UPDATE_LOGIN)
           Values (
		   wsh_location_owners_s.nextval,
		   pLocLocationIdTbl(i),
                   pLocOwnerIdTbl(i),
                   pLocOwnerTypeTbl(i),
                   SYSDATE,
                   1,
                   SYSDATE,
                   1,
                   1);
           EXIT;
        EXCEPTION
         WHEN OTHERS THEN
           l_error_code := SQLCODE;
           l_loc_id := pLocLocationIdTbl(l_start + sql%rowcount);
           --ORA:00001 is the unique constraint violation. We are attempting
           --to insert a facility that already exists.
           IF ( l_error_code = -1 ) THEN
	     IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'Duplicate owner_party_id found for location_id '||l_loc_id);
	     END IF;
             l_start := l_start + sql%rowcount + 1;
           ELSE
	     IF l_debug_on THEN
               WSH_DEBUG_SV.logmsg(l_module_name,'UNEXPECTED ERROR WHILE CREATING LOCATION OWNER FOR LOCATION '||l_loc_id);
               WSH_DEBUG_SV.logmsg(l_module_name,'ERROR MESSAGE '||SQLERRM);
	     END IF;
             x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
             RETURN;
           END IF;
        END;
      END LOOP;
    END;
   END IF;

   --
   -- Debug Statements
   --
   IF l_debug_on THEN
       WSH_DEBUG_SV.pop(l_module_name);
   END IF;
   --
END insert_location_owners;



 -----------------------------------------------------------------------------------
 -- Start of comments
 -- API name : Create_Geometry
 -- Type     : Public
 -- Pre-reqs : None.
 -- Function : Create a MDSYS.SDO_GEOMETRY Object from a longitude and latitude.
 --
 -- Parameters :
 -- p_longitude      IN     NUMBER              The Longitude.
 -- p_latitude       IN     NUMBER              The Latitude.
 --
 -- x_geometry       OUT    MDSYS.SDO_GEOMETRY  The geometry object created.
 -- x_status         OUT    VARCHAR2
 -- x_error_msg      OUT    VARCHAR2
 --
 -- Version : 1.0
 -- Previous version 1.0
 -- Initial version 1.0
 -- End of comments
 -----------------------------------------------------------------------------------
 PROCEDURE Create_Geometry (p_longitude      IN  NUMBER,
                            p_latitude       IN  NUMBER,
                            x_geometry       OUT NOCOPY MDSYS.SDO_GEOMETRY,
                            x_return_status  OUT NOCOPY VARCHAR2,
                            x_error_msg      OUT NOCOPY VARCHAR2 ) IS

  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CREATE_GEOMETRY';
  l_debug_on BOOLEAN;
  BEGIN
    l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
    IF l_debug_on IS NULL THEN
      l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
    END IF;

    IF l_debug_on THEN
	WSH_DEBUG_SV.push(l_module_name);
    END IF;

    x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

    x_geometry := MDSYS.SDO_GEOMETRY(2001,  --SDO_GTYPE: Geometry type.
                                            --           2 indicates two-dimensional, 1 indicates a single point
                                     8307,  --SDO_SRID:  8307 is SRID for 'Long/Lat (WGS 84)' coordinate system
                                     MDSYS.SDO_POINT_TYPE(p_longitude, p_latitude, NULL),
                                     NULL,  -- SDO_ELEM_INFO: Not needed if point_type
                                     NULL); -- SDO_ORDINATES: Not needed if point_type

  IF l_debug_on THEN
    WSH_DEBUG_SV.pop(l_module_name);
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
      x_error_msg := 'ERROR: During Geometry Creation ' || sqlerrm;
     IF l_debug_on THEN
        WSH_DEBUG_SV.LogMsg(l_module_name, x_error_msg);
      END IF;
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;


 END Create_Geometry;


--
--  Procedure:          convert_internal_cust_location
--  Parameters:
--             p_location_id               location to convert
--             x_internal_org_location_id  physical location id
--                                           if not NULL, it is converted.
--                                           if NULL, the location is not
--                                           an internal customer location.
--             x_return_status       return status
--
--  Description:
--               Attempt to convert the putative internal customer
--               location into the internal organization location.
--               If it is internal customer location, the API will
--               populate x_internal_org_location_id as a physical
--               location.
--               Otherwise, x_internal_org_location_id will be NULL.
--
--
PROCEDURE Convert_internal_cust_location(
               p_internal_cust_location_id   IN         NUMBER,
               x_internal_org_location_id    OUT NOCOPY NUMBER,
               x_return_status               OUT NOCOPY VARCHAR2)
IS
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CONVERT_INTERNAL_CUST_LOCATION';
  --
  l_debug_on BOOLEAN;
  --
  CURSOR c_convert(p_int_cust_loc_id NUMBER) IS
  SELECT ploc.LOCATION_ID internal_org_location_id
  FROM PO_LOCATION_ASSOCIATIONS_ALL ploc,
       hz_cust_site_uses_all site_uses,
       hz_cust_acct_sites_all acct_sites,
       HZ_PARTY_SITES sites
  WHERE ploc.SITE_USE_ID = site_uses.SITE_USE_ID
  AND site_uses.CUST_ACCT_SITE_ID = acct_sites.CUST_ACCT_SITE_ID
  AND acct_sites.PARTY_SITE_ID = sites.PARTY_SITE_ID
  AND ploc.CUSTOMER_ID = acct_sites.CUST_ACCOUNT_ID
  AND sites.location_id = p_int_cust_loc_id;
  --
  l_cache_rec    Generic_Cache_Rec_Typ;
  l_index        NUMBER;
  l_rs           VARCHAR2(1);
  l_flag         VARCHAR2(1);

BEGIN
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
  END IF;
  --
  --
  l_cache_rec.input_param1 := to_char(p_internal_cust_location_id);

  x_return_status := WSH_UTIL_CORE.G_RET_STS_SUCCESS;

  get_table_index(
      p_validate_rec  => l_cache_rec,
      p_generic_tab   => g_int_loc_cache,
      x_index         => l_index,
      x_return_status => l_rs,
      x_flag          => l_flag);

  IF (l_rs IN (WSH_UTIL_CORE.G_RET_STS_ERROR,
               WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR))  THEN
    l_flag := NULL;
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
  END IF;

  IF l_flag = 'U' THEN
     OPEN c_convert(p_internal_cust_location_id);
     FETCH c_convert INTO l_cache_rec.output_param1;
     IF c_convert%NOTFOUND THEN
        l_cache_rec.output_param1 := NULL;
     END IF;
     CLOSE c_convert;
     g_int_loc_cache(l_index) := l_cache_rec;
  END IF;

  IF g_int_loc_cache.EXISTS(l_index) THEN
    x_internal_org_location_id := g_int_loc_cache(l_index).output_param1;
  ELSE
    x_return_status := WSH_UTIL_CORE.G_RET_STS_ERROR;
    x_internal_org_location_id := NULL;
  END IF;

  --
  --
  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name, 'x_return_status', x_return_status);
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
      x_return_status := WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR;
      IF c_convert%ISOPEN THEN
         CLOSE c_convert;
      END IF;
      WSH_UTIL_CORE.DEFAULT_HANDLER(
                        'XX_CDH_LOCATIONS_PKG.convert_internal_cust_location',
                        l_module_name);

    IF l_debug_on THEN
       WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
       WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
    END IF;

END convert_internal_cust_location;



--
--  Function:          convert_internal_cust_location
--  Parameters:
--             p_location_id               location to convert
--
--  Return:
--             internal organizatoin location ID
--                    NULL if not converted or no mapping exists.
--                    NOT NULL if successfully converted and mapping exists.
--  Description:
--             Wrapper function for procedure convert_internal_cust_location
--
--
FUNCTION Convert_internal_cust_location(
               p_internal_cust_location_id   IN         NUMBER)
RETURN NUMBER
IS
  l_module_name CONSTANT VARCHAR2(100) := 'wsh.plsql.' || G_PKG_NAME || '.' || 'CONVERT_INTERNAL_CUST_LOCATION[function]';
  --
  l_debug_on BOOLEAN;
  --
  l_internal_org_location_id           NUMBER;
  l_rs           VARCHAR2(1);
BEGIN
  l_debug_on := WSH_DEBUG_INTERFACE.g_debug;
  --
  IF l_debug_on IS NULL THEN
    l_debug_on := WSH_DEBUG_SV.is_debug_enabled;
  END IF;

  IF l_debug_on THEN
    WSH_DEBUG_SV.push(l_module_name);
  END IF;
  --
  --

  convert_internal_cust_location(
               p_internal_cust_location_id   => p_internal_cust_location_id,
               x_internal_org_location_id    => l_internal_org_location_id,
               x_return_status               => l_rs
  );

  IF (l_rs IN (WSH_UTIL_CORE.G_RET_STS_ERROR,
               WSH_UTIL_CORE.G_RET_STS_UNEXP_ERROR))  THEN
    l_internal_org_location_id := NULL;
  END IF;

  --
  --
  IF l_debug_on THEN
     WSH_DEBUG_SV.log(l_module_name, 'returning', l_internal_org_location_id);
     WSH_DEBUG_SV.pop(l_module_name);
  END IF;

  RETURN l_internal_org_location_id;

  EXCEPTION
    WHEN OTHERS THEN
      WSH_UTIL_CORE.DEFAULT_HANDLER(
                        'WSH_LOCATIONS_PKG.convert_internal_cust_location',
                        l_module_name);
    IF l_debug_on THEN
       WSH_DEBUG_SV.logmsg(l_module_name,'Unexpected error has occured. Oracle error message is '|| SQLERRM,WSH_DEBUG_SV.C_UNEXPEC_ERR_LEVEL);
       WSH_DEBUG_SV.pop(l_module_name,'EXCEPTION:OTHERS');
    END IF;
    RETURN NULL;

END convert_internal_cust_location;

 
END XX_CDH_LOCATIONS_PKG;
/
SHOW ERRORS;
