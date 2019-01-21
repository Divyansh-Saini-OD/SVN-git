SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CDH_LOCATIONS_PKG AS

  

  --
  -- Package: WSH_LOCATIONS_PKG
  --
  -- Purpose: To populate data in WSH_LOCATIONS with the data in
  --          HZ_LOCATIONS, HR_LOCATIONS
  --
  --
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
  p_from_location        IN   NUMBER ,
  p_to_location          IN   NUMBER ,
  p_start_date           IN   VARCHAR2,
  p_end_date             IN   VARCHAR2,
  p_create_facilities    IN   VARCHAR2 default NULL,
  p_caller               IN  VARCHAR2 default NULL,
  x_return_status        OUT NOCOPY   VARCHAR2,
  x_sqlcode              OUT NOCOPY   NUMBER,
  x_sqlerr               OUT NOCOPY   varchar2
);



PROCEDURE get_site_number(pLocationIdTbl      IN     WSH_LOCATIONS_PKG.ID_Tbl_Type,
                          pLocationCodeTbl    IN OUT NOCOPY WSH_LOCATIONS_PKG.LocationCode_Tbl_Type,
                          pUILocationCodeTbl  IN OUT NOCOPY WSH_LOCATIONS_PKG.LocationCode_Tbl_Type);

PROCEDURE insert_locations(pInsertLocationIdTbl      IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                           p_location_source_code    IN VARCHAR2,
                           x_return_status           OUT NOCOPY VARCHAR2);

PROCEDURE update_locations(pUpdateLocationIdTbl      IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                           p_location_source_code    IN VARCHAR2,
                           x_return_status           OUT NOCOPY VARCHAR2);

PROCEDURE insert_location_owners(pLocationIdTbl          IN WSH_LOCATIONS_PKG.ID_Tbl_Type,
                                 p_location_source_code  IN VARCHAR2,
                                 x_return_status         OUT NOCOPY VARCHAR2);

PROCEDURE Create_Geometry (p_longitude        IN  NUMBER,
                           p_latitude         IN  NUMBER,
                           x_geometry         OUT NOCOPY MDSYS.SDO_GEOMETRY,
                           x_return_status    OUT NOCOPY VARCHAR2,
                           x_error_msg        OUT NOCOPY VARCHAR2 );


PROCEDURE Convert_internal_cust_location(
               p_internal_cust_location_id   IN         NUMBER,
               x_internal_org_location_id    OUT NOCOPY NUMBER,
               x_return_status               OUT NOCOPY VARCHAR2);

FUNCTION Convert_internal_cust_location(
               p_internal_cust_location_id   IN         NUMBER)
RETURN NUMBER;

pUpdateAddress1Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateAddress2Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateAddress3Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateAddress4Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateCountryTbl          WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateStateTbl            WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateProvinceTbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateCountyTbl           WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateCityTbl             WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdatePostalCodeTbl       WSH_LOCATIONS_PKG.Address_Tbl_Type;
pUpdateExpDateTbl          WSH_LOCATIONS_PKG.Date_Tbl_Type;
pUpdateLocCodeTbl          WSH_LOCATIONS_PKG.LocationCode_Tbl_Type;
pUpdateUILocCodeTbl        WSH_LOCATIONS_PKG.LocationCode_Tbl_Type;
pUpdateOwnerNameTbl        WSH_LOCATIONS_PKG.Address_Tbl_Type;

pInsertAddress1Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertAddress2Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertAddress3Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertAddress4Tbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertCountryTbl          WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertStateTbl            WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertProvinceTbl         WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertCountyTbl           WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertCityTbl             WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertPostalCodeTbl       WSH_LOCATIONS_PKG.Address_Tbl_Type;
pInsertExpDateTbl          WSH_LOCATIONS_PKG.Date_Tbl_Type;
pInsertLocCodeTbl          WSH_LOCATIONS_PKG.LocationCode_Tbl_Type;
pInsertUILocCodeTbl        WSH_LOCATIONS_PKG.LocationCode_Tbl_Type;
pInsertOwnerNameTbl        WSH_LOCATIONS_PKG.Address_Tbl_Type;

pLocLocationIdTbl          WSH_LOCATIONS_PKG.ID_Tbl_Type;
pLocOwnerIdTbl             WSH_LOCATIONS_PKG.ID_Tbl_Type;
pLocOwnerTypeTbl           WSH_LOCATIONS_PKG.ID_Tbl_Type;

pLatitudeTbl               WSH_LOCATIONS_PKG.ID_Tbl_Type;
pLongitudeTbl              WSH_LOCATIONS_PKG.ID_Tbl_Type;
pTimezoneTbl               WSH_LOCATIONS_PKG.LocationCode_Tbl_Type;
--pGeometryTbl               Geometry_Tbl_Type;
pLastUpdateDateTbl         WSH_LOCATIONS_PKG.Date_Tbl_Type;

END XX_CDH_LOCATIONS_PKG;
/
SHOW ERRORS;
