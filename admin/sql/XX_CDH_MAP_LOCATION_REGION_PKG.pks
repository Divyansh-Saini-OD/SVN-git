SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_MAP_LOCATION_REGION_PKG AS

  g_loc_commit    VARCHAR2(1) := 'Y';

TYPE loc_rec_type IS RECORD(
      WSH_LOCATION_ID         WSH_LOCATIONS.WSH_LOCATION_ID%TYPE,
      SOURCE_LOCATION_ID      WSH_LOCATIONS.SOURCE_LOCATION_ID%TYPE,
      LOCATION_SOURCE_CODE    WSH_LOCATIONS.LOCATION_SOURCE_CODE%TYPE,
      LOCATION_CODE           WSH_LOCATIONS.LOCATION_CODE%TYPE,
      UI_LOCATION_CODE        WSH_LOCATIONS.UI_LOCATION_CODE%TYPE,
      ADDRESS1                WSH_LOCATIONS.ADDRESS1%TYPE,
      ADDRESS2                WSH_LOCATIONS.ADDRESS2%TYPE,
      ADDRESS3                WSH_LOCATIONS.ADDRESS3%TYPE,
      ADDRESS4                WSH_LOCATIONS.ADDRESS4%TYPE,
      COUNTRY                 WSH_LOCATIONS.COUNTRY%TYPE,
      STATE                   WSH_LOCATIONS.STATE%TYPE,
      PROVINCE                WSH_LOCATIONS.PROVINCE%TYPE,
      COUNTY                  WSH_LOCATIONS.COUNTY%TYPE,
      CITY                    WSH_LOCATIONS.CITY%TYPE,
      POSTAL_CODE             WSH_LOCATIONS.POSTAL_CODE%TYPE,
      INACTIVE_DATE           WSH_LOCATIONS.INACTIVE_DATE%TYPE);

TYPE TableNumbers  is TABLE of NUMBER  INDEX BY BINARY_INTEGER; -- table number type
TYPE TableVarchar  is TABLE of VARCHAR2(120) INDEX BY BINARY_INTEGER; -- table varchar(120) type

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

PROCEDURE Map_Locations (
    p_errbuf              OUT NOCOPY   VARCHAR2,
    p_retcode             OUT NOCOPY   NUMBER,
    p_map_regions         IN   VARCHAR2,
    p_num_of_instances    IN   NUMBER,
    p_start_date          IN   VARCHAR2,
    p_end_date            IN   VARCHAR2,
    p_fte_installed	  IN   VARCHAR2 default NULL,
    p_create_facilities	  IN   VARCHAR2 default NULL);

/*===========================================================================+
| PROCEDURE                                                                 |
|              Map_Location_Child_Program                                   |
|                                                                           |
| DESCRIPTION                                                               |
|              This is just a wrapper routine and call the main processing  |
|              API Mapping_Main. This procedure is also by the TCA Callout  |
|              API Rule_Location.                                           |
|                                                                           |
+===========================================================================*/

PROCEDURE Map_Locations_Child_Program (
    p_errbuf              OUT NOCOPY   VARCHAR2,
    p_retcode             OUT NOCOPY   NUMBER,
    p_map_regions         IN   VARCHAR2,
    p_from_location       IN   NUMBER,
    p_to_location         IN   NUMBER,
    p_start_date          IN   VARCHAR2,
    p_end_date            IN   VARCHAR2,
    p_create_facilities	  IN   VARCHAR2 default NULL) ;

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
    x_sqlcode          OUT NOCOPY   NUMBER,
    x_sqlerr           OUT NOCOPY   VARCHAR2);

/*===========================================================================+
 | FUNCTION                                                                  |
 |              Insert_Record                                                |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This API just inserts the record into intersection table     |
 |                                                                           |
 +===========================================================================*/

PROCEDURE Insert_Record
  (
    p_location_id         IN   NUMBER,
    p_region_id           IN   NUMBER,
    p_region_type         IN   NUMBER,
    p_exception           IN   VARCHAR2,
    p_location_source     IN   VARCHAR2,
    p_parent_region       IN   VARCHAR2,
    x_return_status       OUT NOCOPY   VARCHAR2
   );

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
       x_sqlerr             OUT NOCOPY   VARCHAR2);

/*===========================================================================+
 | FUNCTION                                                                  |
 |              Rule_Location                                                |
 |                                                                           |
 | DESCRIPTION                                                               |
 |              This is the rule function for the following TCA events :     |
 |                   # oracle.apps.ar.hz.Location.create                     |
 |                   # oracle.apps.ar.hz.Location.update                     |
 |              This calls the Mapping_Main API to recreate the mapping once |
 |              a location gets created on a location gets updated.          |
 |                                                                           |
 +===========================================================================*/

FUNCTION Rule_Location(
               p_subscription_guid  in raw,
               p_event              in out NOCOPY  wf_event_t)
RETURN VARCHAR2;

END XX_CDH_MAP_LOCATION_REGION_PKG;
/
SHOW ERRORS;
