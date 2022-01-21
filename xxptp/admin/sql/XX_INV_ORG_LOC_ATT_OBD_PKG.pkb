SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE  BODY XX_INV_ORG_LOC_ATT_OBD_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY XX_INV_ORG_LOC_ATT_OBD_PKG
  -- +=========================================================================+
  -- |                  Office Depot - Project Simplify                        |
  -- |                  Office Depot                                           |
  -- +=========================================================================+
  -- | Name             : XX_INV_ORG_LOC_ATT_OBD_PKG                           |
  -- | RICE ID        :                                                      |
  -- | Description      : Extract data from staging and invoke the webservice  |
  -- |                                                                         |
  -- |                                                                         |
  -- |Change Record:                                                           |
  -- |===============                                                          |
  -- |Version    Date          Author            Remarks                       |
  -- |=======    ==========    =============     ==============================|
  -- |    1.0    05/09/2017    Praveen vanga     Initial code                  |
  -- +=========================================================================+
AS

 /*********************************************************************
    * Procedure used to out the text to the concurrent program.
    * Will log to dbms_output if request id is not set,
    * else will log to concurrent program output file.     
    *********************************************************************/
    PROCEDURE print_out_msg(
        P_Message  In  Varchar2)
    IS
        lc_message  VARCHAR2(32500) := NULL;
    Begin
        Lc_Message :=P_Message;
        Fnd_File.Put_Line(Fnd_File.output, Lc_Message);
        IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
        Then
            DBMS_OUTPUT.put_line(lc_message);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END print_out_msg;   

  /*********************************************************************
    * Function to Get Time Zone Code.     
    *********************************************************************/
	
	FUNCTION XX_TIME_ZONE(P_TIMEZONE_CODE varchar2) return varchar2
	As
	 x_time_zone varchar2(250):=null;
	BEGIN
       SELECT b.name
	     INTO x_time_zone
         From Fnd_Timezones_Vl B 
        WHERE b.TIMEZONE_CODE =P_TIMEZONE_CODE 
		  AND ROWNUM < 2;
		  
		  Return x_time_zone;
		
	EXCEPTION
	 WHEN OTHERS THEN
	   x_time_zone:=null;
	   Return x_time_zone;
	END XX_TIME_ZONE;
	
	/*********************************************************************
    * Function to Get Ship to Location Name.     
    *********************************************************************/
	
	FUNCTION XX_SHIP_TO_LOC(P_ship_to_location_id number) return varchar2
	AS
	  x_ship_to_loc varchar2(250):=null;
	BEGIN
	     SELECT substr(location_code,8)
	      INTO x_ship_to_loc
          FROM Hr_Locations
         WHERE location_id=p_ship_to_location_id
		   AND ROWNUM < 2;
		   
		   Return x_ship_to_loc;
		   
	EXCEPTION
	 WHEN OTHERS THEN
	   x_ship_to_loc:=null;
	   Return x_ship_to_loc;
	END XX_SHIP_TO_LOC;       
	
	--+============================================================================+
   --| Name          : XX_OD_INV_ORG_LOC_XML_TAG                                  |
   --| Description   : procedure will be called from the main procedure to create |
   --|                 xml tags for webservices                                   |
   --| Parameters    : p_od_inv_org_attr_rec_tbl                                  |        
   --| Returns       :                                                            |
   --|                                                                            |
   --|                                                                            |
   --+============================================================================+    
	PROCEDURE XX_OD_INV_ORG_LOC_XML_TAG(p_od_inv_org_attr_rec_tbl  XX_INV_ORG_LOC_ATT_OBD_PKG.od_inv_org_loc_attr_rec_tbl)
	Is
  lv_soap_request Varchar2(32500);
	BEGIN
	
	  
	   FOR c1 IN p_od_inv_org_attr_rec_tbl.FIRST .. p_od_inv_org_attr_rec_tbl.COUNT() LOOP 
	     
		lv_soap_request:='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
          <soapenv:Header/>
		    <soapenv:Body>
			 <inv:invorglocattEventRequest>
			    <hrlc:hrlocations>
					<hrlc:locationcode>'||p_od_inv_org_attr_rec_tbl(c1).Location_code||'</hrlc:locationcode> 
					<hrlc:description>'||p_od_inv_org_attr_rec_tbl(c1).Description||'</hrlc:description> 
					<hrlc:inactivedate>'||p_od_inv_org_attr_rec_tbl(c1).INACTIVE_DATE||'</hrlc:inactivedate> 
					<hrlc:locationuse>'||p_od_inv_org_attr_rec_tbl(c1).Location_use||'</hrlc:locationuse> 					
				    <hrlc:taxname>'||p_od_inv_org_attr_rec_tbl(c1).TAX_NAME||'</hrlc:taxname> 	
					<hrlc:TpLocationCode>'||p_od_inv_org_attr_rec_tbl(c1).ECE_TP_LOCATION_CODE||'</hrlc:TpLocationCode> 
				</hrlc:hrlocations>
			    <odc:address> 
				   <odc:addressline1>'||p_od_inv_org_attr_rec_tbl(c1).ADDRESS_LINE_1||'</odc:addressline1>
					<odc:addressline2>'||p_od_inv_org_attr_rec_tbl(c1).ADDRESS_LINE_2||'</odc:addressline2> 	
					<odc:addressline3>'||p_od_inv_org_attr_rec_tbl(c1).ADDRESS_LINE_3||'</odc:addressline3> 	
					<odc:city>'||p_od_inv_org_attr_rec_tbl(c1).TOWN_OR_CITY||'</odc:city> 
					<odc:country>'||p_od_inv_org_attr_rec_tbl(c1).COUNTRY||'</odc:country> 	
					<odc:ZipCode>'||p_od_inv_org_attr_rec_tbl(c1).POSTAL_CODE||'</odc:ZipCode>
					<odc:County>'||p_od_inv_org_attr_rec_tbl(c1).REGION_1||'</odc:County> 	
					<odc:State>'||p_od_inv_org_attr_rec_tbl(c1).REGION_2||'</odc:State> 	
					<odc:Telephone>'||p_od_inv_org_attr_rec_tbl(c1).TELEPHONE_NUMBER_1||'</odc:Telephone> 	
					<odc:Fax>'||p_od_inv_org_attr_rec_tbl(c1).TELEPHONE_NUMBER_2||'</odc:Fax> 	
					<odc:ManagerName>'||p_od_inv_org_attr_rec_tbl(c1).LOC_INFORMATION15||'</odc:ManagerName> 	
					<odc:EmailAddress>'||p_od_inv_org_attr_rec_tbl(c1).LOC_INFORMATION16||'</odc:EmailAddress> 	
					<odc:CrossStreetDirections>'||p_od_inv_org_attr_rec_tbl(c1).LOC_INFORMATION17||'</odc:CrossStreetDirections> 	
					<odc:TimeZone>'||p_od_inv_org_attr_rec_tbl(c1).TIMEZONE_CODE||'</odc:TimeZone> 					
					<odc:CountryID>'||p_od_inv_org_attr_rec_tbl(c1).COUNTRY_ID_SW||'</odc:CountryID> 	
					<odc:CrossStreetDirection2>'||p_od_inv_org_attr_rec_tbl(c1).OD_CROSS_STREET_DIR_2_SW||'</odc:CrossStreetDirection2> 	
					<odc:Format>'||p_od_inv_org_attr_rec_tbl(c1).FORMAT_S||'</odc:Format> 	
					<odc:District>'||p_od_inv_org_attr_rec_tbl(c1).DISTRICT_SW||'</odc:District> 
					<odc:SalesTaxOverride>'||p_od_inv_org_attr_rec_tbl(c1).LOC_INFORMATION13||'</odc:SalesTaxOverride> 	
					<odc:InsideCityLimits>'||p_od_inv_org_attr_rec_tbl(c1).LOC_INFORMATION14||'</odc:InsideCityLimits> 	
				</odc:address>
				<ship:shiptoflags>
  			        <ship:ShipToLocation>'||p_od_inv_org_attr_rec_tbl(c1).SHIP_TO_LOCATION_NAME||'</ship:ShipToLocation> 	
					<ship:ShipToSiteFlag>'||p_od_inv_org_attr_rec_tbl(c1).SHIP_TO_SITE_FLAG||'</ship:ShipToSiteFlag> 	
					<ship:ReceivingSiteFlag>'||p_od_inv_org_attr_rec_tbl(c1).RECEIVING_SITE_FLAG||'</ship:ReceivingSiteFlag> 	
					<ship:BillToSiteFlag>'||p_od_inv_org_attr_rec_tbl(c1).BILL_TO_SITE_FLAG||'</ship:billtositeflag>	
					<ship:officesiteflag>'||p_od_inv_org_attr_rec_tbl(c1).OFFICE_SITE_FLAG||'</ship:officesiteflag> 
				</ship:shiptoflags>
				<odc:LOC_ADDITIONAL_INFO>
				    <odc:GLLocationSegmentValue>'||p_od_inv_org_attr_rec_tbl(c1).ATTRIBUTE1||'</odc:GLLocationSegmentValue> 
				    <odc:GLPrimaryLocation>'||p_od_inv_org_attr_rec_tbl(c1).ATTRIBUTE2||'</odc:GLPrimaryLocation> 	
					<odc:LocationType>'||p_od_inv_org_attr_rec_tbl(c1).ATTRIBUTE3||'</odc:LocationType> 	
					<odc:ShippingLane>'||p_od_inv_org_attr_rec_tbl(c1).ATTRIBUTE6||'</odc:ShippingLane> 	
					<odc:GeoCode>'||p_od_inv_org_attr_rec_tbl(c1).ATTRIBUTE15||'</odc:GeoCode> 	
				</odc:LOC_ADDITIONAL_INFO>
				<xxinv:customtab>
 				    <xxinv:LocationNumber>'||p_od_inv_org_attr_rec_tbl(c1).LOCATION_NUMBER_SW||'</xxinv:LocationNumber> 
                    <xxinv:LocationName>'||p_od_inv_org_attr_rec_tbl(c1).NAME_SW||'</hrlc:LocationName> 					   
				    <xxinv:OrgType>'||p_od_inv_org_attr_rec_tbl(c1).ORG_TYPE||'</xxinv:OrgType> 	
				    <xxinv:LocationType>'||p_od_inv_org_attr_rec_tbl(c1).OD_TYPE_SW||'</xxinv:LocationType> 	
					<xxinv:SubType>'||p_od_inv_org_attr_rec_tbl(c1).OD_SUB_TYPE_CD_SW||'</xxinv:SubType> 	
					<xxinv:ODWHOrgCode>'||p_od_inv_org_attr_rec_tbl(c1).OD_WHSE_ORG_CD_SW||'</xxinv:ODWHOrgCode> 
   				    <xxinv:Currency>'||p_od_inv_org_attr_rec_tbl(c1).ORIG_CURRENCY_CODE||'</xxinv:Currency> 	
					<xxinv:StoreClass>'||p_od_inv_org_attr_rec_tbl(c1).STORE_CLASS_S||'</xxinv:StoreClass> 	
					<xxinv:Division>'||p_od_inv_org_attr_rec_tbl(c1).OD_DIVISION_ID_SW||'</xxinv:Division> 	
					<xxinv:AdvertisingOpeningDate>'||p_od_inv_org_attr_rec_tbl(c1).OPEN_DATE_SW||'</xxinv:AdvertisingOpeningDate> 	
					<xxinv:AdvertisingClosingDate>'||p_od_inv_org_attr_rec_tbl(c1).CLOSE_DATE_SW||'</xxinv:AdvertisingClosingDate> 	
					<xxinv:DefaultXDockWH>'||p_od_inv_org_attr_rec_tbl(c1).DEFAULT_WH_SW||'</xxinv:DefaultXDockWH> 
					<xxinv:DefaultCSCWarehouse>'||p_od_inv_org_attr_rec_tbl(c1).OD_DEFAULT_WH_CSC_S||'</xxinv:DefaultCSCWarehouse> 	
					<xxinv:MarketOpeningDate>'||p_od_inv_org_attr_rec_tbl(c1).OD_MKT_OPEN_DATE_S||'</xxinv:MarketOpeningDate> 	
					<xxinv:StartOrderDays>'||p_od_inv_org_attr_rec_tbl(c1).START_ORDER_DAYS_S||'</xxinv:StartOrderDays> 	
					<xxinv:StopOrderDays>'||p_od_inv_org_attr_rec_tbl(c1).STOP_ORDER_DAYS_S||'</xxinv:StopOrderDays> 	
					<xxinv:ClosingStoreIndicator>'||p_od_inv_org_attr_rec_tbl(c1).OD_CLOSING_STORE_IND_S||'</xxinv:ClosingStoreIndicator>
					<xxinv:ModelTaxLocation>'||p_od_inv_org_attr_rec_tbl(c1).OD_MODEL_TAX_LOC_SW||'</xxinv:ModelTaxLocation> 	
					<xxinv:LocationBrandCode>'||p_od_inv_org_attr_rec_tbl(c1).OD_LOC_BRAND_CD_SW||'</xxinv:LocationBrandCode>
					<xxinv:GeoCode>'||p_od_inv_org_attr_rec_tbl(c1).OD_GEO_CD_SW||'</xxinv:GeoCode> 	
					<xxinv:BackToSchoolFlightID>'||p_od_inv_org_attr_rec_tbl(c1).OD_BTS_FLIGHT_ID_SW||'</xxinv:BackToSchoolFlightID> 	
					<xxinv:AdvertisingMarketID>'||p_od_inv_org_attr_rec_tbl(c1).OD_AD_MKT_ID_SW||'</xxinv:AdvertisingMarketID> 	
					<xxinv:ChannelID>'||p_od_inv_org_attr_rec_tbl(c1).CHANNEL_ID_SW||'</xxinv:ChannelID>
					<xxinv:TransactionNOGenerated>'||p_od_inv_org_attr_rec_tbl(c1).TRANSACTION_NO_GENERATED_S||'</xxinv:TransactionNOGenerated> 	
					<xxinv:RemerchandisingIndicator>'||p_od_inv_org_attr_rec_tbl(c1).OD_REMERCH_IND_S||'</xxinv:RemerchandisingIndicator>
					<xxinv:SisterWarehouse1>'||p_od_inv_org_attr_rec_tbl(c1).OD_SISTER_STORE1_SW||'</xxinv:SisterWarehouse1> 	
					<xxinv:SisterWarehouse2>'||p_od_inv_org_attr_rec_tbl(c1).OD_SISTER_STORE2_SW||'</xxinv:SisterWarehouse2> 	
					<xxinv:SisterWarehouse3>'||p_od_inv_org_attr_rec_tbl(c1).OD_SISTER_STORE3_SW||'</xxinv:SisterWarehouse3> 
					<xxinv:CrossdockLeadtime>'||p_od_inv_org_attr_rec_tbl(c1).OD_CROSS_DOCK_LEAD_TIME_SW||'</xxinv:CrossdockLeadtime> 	
					<xxinv:OrderCutoffTime>'||p_od_inv_org_attr_rec_tbl(c1).OD_ORD_CUTOFF_TM_SW||'</xxinv:OrderCutoffTime> 	
					<xxinv:DeliveryCode>'||p_od_inv_org_attr_rec_tbl(c1).OD_DELIVERY_CD_SW||'</xxinv:DeliveryCode> 	
					<xxinv:RoutingCode'||p_od_inv_org_attr_rec_tbl(c1).OD_ROUTING_CD_SW||'</xxinv:RoutingCode> 	
					<xxinv:RelocationID>'||p_od_inv_org_attr_rec_tbl(c1).OD_RELOC_ID_SW||'</xxinv:RelocationID> 	
					<xxinv:TotalSquareFeet>'||p_od_inv_org_attr_rec_tbl(c1).TOTAL_SQUARE_FEET_S||'</xxinv:TotalSquareFeet> 	
					<xxinv:BreakPackIndW>'||p_od_inv_org_attr_rec_tbl(c1).BREAK_PACK_IND_W||'</xxinv:BreakPackIndW> 
					<xxinv:DeliveryPolicy>'||p_od_inv_org_attr_rec_tbl(c1).DELIVERY_POLICY_W||'</xxinv:DeliveryPolicy> 
					<xxinv:ExpandedMixFlag>'||p_od_inv_org_attr_rec_tbl(c1).OD_EXPANDED_MIX_FLG_W||'</xxinv:ExpandedMixFlag> 	
				    <xxinv:DefaultImportWH>'||p_od_inv_org_attr_rec_tbl(c1).OD_DEFAULT_IMPORT_WH_W||'</xxinv:DefaultImportWH> 	
					<xxinv:WMSApplication>'||p_od_inv_org_attr_rec_tbl(c1).OD_EXTERNAL_WMS_SYSTEM_W||'</xxinv:WMSApplication> 	
					<xxinv:ProtectedIndicator>'||p_od_inv_org_attr_rec_tbl(c1).PROTECTED_IND_W||'</xxinv:ProtectedIndicator> 
					<xxinv:ForecastIndicator>'||p_od_inv_org_attr_rec_tbl(c1).FORECAST_WH_IND_W||'</xxinv:ForecastIndicator>
					<xxinv:ReplenishIndicator>'||p_od_inv_org_attr_rec_tbl(c1).REPL_IND_W||'</xxinv:ReplenishIndicator> 	
					<xxinv:ReplenishSRSORD>'||p_od_inv_org_attr_rec_tbl(c1).REPL_SRS_ORD_W||'</xxinv:ReplenishSRSORD> 	
					<xxinv:RestrictedIndicator>'||p_od_inv_org_attr_rec_tbl(c1).RESTRICTED_IND_W||'</xxinv:RestrictedIndicator> 	
					<xxinv:PickupORDeliveryCutoff>'||p_od_inv_org_attr_rec_tbl(c1).PICKUP_DELIVERY_CUTOFF_SW||'</xxinv:PickupORDeliveryCutoff> 	
					<xxinv:SamedayDelivery>'||p_od_inv_org_attr_rec_tbl(c1).SAMEDAY_DELIVERY_SW||'</xxinv:SamedayDelivery> 	
					<xxinv:FurnitureCutoff>'||p_od_inv_org_attr_rec_tbl(c1).FURNITURE_CUTOFF_SW||'</xxinv:FurnitureCutoff> 	
					<xxinv:RPHToWHLink>'||p_od_inv_org_attr_rec_tbl(c1).LINK_TO_RPF_AND_WH||'</xxinv:RPHToWHLink>
					<xxinv:WMSApplication>'||p_od_inv_org_attr_rec_tbl(c1).SEGMENT1||'</odc:WMSApplication> 	
					<xxinv:OrderCutoffTime>'||p_od_inv_org_attr_rec_tbl(c1).SEGMENT2||'</odc:OrderCutoffTime>	
				</xxinv:customtab>
			 </inv:invorglocattEventRequest>
		    </soapenv:Body>
           </soapenv:Envelope>';
		   
	     -- Updating the extracted record status
		 UPDATE hr_locations
		    SET attribute4 = 'INTERFACED'
          WHERE attribute4 IS NOT NULL
	        AND attribute4 NOT LIKE 'INT%'  
			and Substr(Location_Code,1,6) = Lpad(p_od_inv_org_attr_rec_tbl(c1).LOCATION_NUMBER_SW,6,'0');
			
			  
	   
		   print_out_msg(RPAD(p_od_inv_org_attr_rec_tbl(c1).LOCATION_NUMBER_SW,22,' '));
		
	   
	   END LOOP;
	
	   COMMIT;
		  
    EXCEPTION
	  WHEN OTHERS THEN
        print_out_msg(sqlerrm);
	END XX_OD_INV_ORG_LOC_XML_TAG;
	  
   --+============================================================================+
   --| Name          : main                                                       |
   --| Description   : main procedure will be called from the concurrent program  |
   --|                 for invoice org location attributes                        |
   --| Parameters    :                                                            |        
   --| Returns       :                                                            |
   --|                   x_errbuf                  OUT      VARCHAR2              |
   --|                   x_retcode                 OUT      NUMBER                |
   --|                                                                            |
   --|                                                                            |
   --+============================================================================+    
 PROCEDURE MAIN(x_errbuf                   OUT NOCOPY VARCHAR2
               ,x_retcode                  OUT NOCOPY NUMBER) 
 IS

 CURSOR C1 IS
 SELECT location_code,
		location_use,
		description,
		inactive_date,
		address_line_1,
		address_line_2,
		address_line_3,
		town_or_city,
		(select TERRITORY_SHORT_NAME
             from FND_TERRITORIES_VL
			 where TERRITORY_CODE = country) country,
		postal_code,
		region_1,
		region_2,
		region_3,
		telephone_number_1,
		telephone_number_2,
		loc_information13,
		loc_information14,
		loc_information15,
		loc_information16,
		Loc_Information17,
		Xx_Time_Zone(nvl(Timezone_Code,'XYZ')) Timezone_Code,
		Xx_Ship_To_Loc(Ship_To_Location_Id)  ship_to_location_NAME,
		ship_to_site_flag,
		receiving_site_flag,
		bill_to_site_flag,
		in_organization_flag,
		office_site_flag,
		tax_name,
		ece_tp_location_code,
		attribute2,
		attribute3,
		attribute6,
		attribute15,
		ATTRIBUTE1
		FROM hr_locations
  WHERE attribute4 IS NOT NULL
	AND attribute4 NOT LIKE 'INT%' ;
		  
 
  CURSOR C2(p_location_num Varchar2) IS
  SELECT Location_Number_Sw,
		Name_Sw,
		Od_Type_Sw,
		Country_Id_Sw,
		Od_Cross_Street_Dir_2_Sw,
		Orig_Currency_Code,
		Store_Class_S,
		Format_S,
		District_Sw,
		Od_Division_Id_Sw,
		substr(Od_Sub_Type_Cd_Sw,1,2) Od_Sub_Type_Cd_Sw,
		Open_Date_Sw,
		Close_Date_Sw,
		Default_Wh_Sw,
		Od_Default_Wh_Csc_S,
		Od_Mkt_Open_Date_S,
		Start_Order_Days_S,
		Stop_Order_Days_S,
		Od_Closing_Store_Ind_S,
		Od_Model_Tax_Loc_Sw,
		Od_Loc_Brand_Cd_Sw,
		Od_Geo_Cd_Sw,
		Od_Bts_Flight_Id_Sw,
		Od_Ad_Mkt_Id_Sw,
		Channel_Id_Sw,
		Transaction_No_Generated_S,
		Od_Remerch_Ind_S,
		Od_Sister_Store1_Sw,
		Od_Sister_Store2_Sw,
		Od_Sister_Store3_Sw,
		Od_Cross_Dock_Lead_Time_Sw,
		Od_Ord_Cutoff_Tm_Sw,
		Od_Delivery_Cd_Sw,
		Od_Routing_Cd_Sw,
		Od_Reloc_Id_Sw,
		Total_Square_Feet_S,
		Break_Pack_Ind_W,
		Delivery_Policy_W,
		Od_Expanded_Mix_Flg_W,
		Od_Default_Import_Wh_W,
		Od_External_Wms_System_W,
		Protected_Ind_W,
		Forecast_Wh_Ind_W,
		Repl_Ind_W,
		Repl_Srs_Ord_W,
		Restricted_Ind_W,
		Pickup_Delivery_Cutoff_Sw,
		Sameday_Delivery_Sw,
		Furniture_Cutoff_Sw,
		substr(Od_Whse_Org_Cd_Sw,1,2) Od_Whse_Org_Cd_Sw,
		substr(Org_Type,1,2) Org_Type,
		Link_To_Rpf_And_Wh,
		Segment1,
		Segment2
    FROM xx_inv_org_loc_rms_attribute 
   WHERE Lpad(Location_Number_Sw,6,'0') = p_location_num;
 
 
  p_counter number:=1;
  od_inv_org_loc_attr_rec_tbl XX_INV_ORG_LOC_ATT_OBD_PKG.od_inv_org_loc_attr_rec_tbl;

 BEGIN
  
      for i in c1 loop
	  
           
			od_inv_org_loc_attr_rec_tbl(p_counter).Location_code:=i.Location_code	;
			od_inv_org_loc_attr_rec_tbl(p_counter).Location_use:=i.Location_use	;
			od_inv_org_loc_attr_rec_tbl(p_counter).Description:=i.Description	;
			od_inv_org_loc_attr_rec_tbl(p_counter).INACTIVE_DATE:=i.INACTIVE_DATE	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ADDRESS_LINE_1:=i.ADDRESS_LINE_1	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ADDRESS_LINE_2:=i.ADDRESS_LINE_2	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ADDRESS_LINE_3:=i.ADDRESS_LINE_3	;
			od_inv_org_loc_attr_rec_tbl(p_counter).TOWN_OR_CITY:=i.TOWN_OR_CITY	;
			od_inv_org_loc_attr_rec_tbl(p_counter).COUNTRY:=i.COUNTRY	;
			od_inv_org_loc_attr_rec_tbl(p_counter).POSTAL_CODE:=i.POSTAL_CODE	;
			od_inv_org_loc_attr_rec_tbl(p_counter).REGION_1:=i.REGION_1	;
			od_inv_org_loc_attr_rec_tbl(p_counter).REGION_2:=i.REGION_2	;
			od_inv_org_loc_attr_rec_tbl(p_counter).REGION_3:=i.REGION_3	;
			od_inv_org_loc_attr_rec_tbl(p_counter).TELEPHONE_NUMBER_1:=i.TELEPHONE_NUMBER_1	;
			od_inv_org_loc_attr_rec_tbl(p_counter).TELEPHONE_NUMBER_2:=i.TELEPHONE_NUMBER_2	;
			od_inv_org_loc_attr_rec_tbl(p_counter).LOC_INFORMATION13:=i.LOC_INFORMATION13	;
			od_inv_org_loc_attr_rec_tbl(p_counter).LOC_INFORMATION14:=i.LOC_INFORMATION14	;
			od_inv_org_loc_attr_rec_tbl(p_counter).LOC_INFORMATION15:=i.LOC_INFORMATION15	;
			od_inv_org_loc_attr_rec_tbl(p_counter).LOC_INFORMATION16:=i.LOC_INFORMATION16	;
			Od_Inv_Org_Loc_Attr_Rec_Tbl(P_Counter).Loc_Information17:=I.Loc_Information17	;
			--od_inv_org_loc_attr_rec_tbl(p_counter).TIMEZONE_CODE:=i.TIMEZONE_CODE	;
			--od_inv_org_loc_attr_rec_tbl(p_counter).SHIP_TO_LOCATION_NAME:=i.SHIP_TO_LOCATION_NAME	;
			od_inv_org_loc_attr_rec_tbl(p_counter).SHIP_TO_SITE_FLAG:=i.SHIP_TO_SITE_FLAG	;
			od_inv_org_loc_attr_rec_tbl(p_counter).RECEIVING_SITE_FLAG:=i.RECEIVING_SITE_FLAG	;
			od_inv_org_loc_attr_rec_tbl(p_counter).BILL_TO_SITE_FLAG:=i.BILL_TO_SITE_FLAG	;
			od_inv_org_loc_attr_rec_tbl(p_counter).IN_ORGANIZATION_FLAG:=i.IN_ORGANIZATION_FLAG	;
			od_inv_org_loc_attr_rec_tbl(p_counter).OFFICE_SITE_FLAG:=i.OFFICE_SITE_FLAG	;
			od_inv_org_loc_attr_rec_tbl(p_counter).TAX_NAME:=i.TAX_NAME	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ECE_TP_LOCATION_CODE:=i.ECE_TP_LOCATION_CODE	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ATTRIBUTE1:=i.ATTRIBUTE1	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ATTRIBUTE2:=i.ATTRIBUTE2	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ATTRIBUTE3:=i.ATTRIBUTE3	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ATTRIBUTE6:=i.ATTRIBUTE6	;
			od_inv_org_loc_attr_rec_tbl(p_counter).ATTRIBUTE15:=i.ATTRIBUTE15	;
		
      for j in c2(Substr(i.Location_Code,1,6)) loop
			    
				od_inv_org_loc_attr_rec_tbl(p_counter).LOCATION_NUMBER_SW:=j.LOCATION_NUMBER_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).NAME_SW:=j.NAME_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_TYPE_SW:=j.OD_TYPE_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).COUNTRY_ID_SW:=j.COUNTRY_ID_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_CROSS_STREET_DIR_2_SW:=j.OD_CROSS_STREET_DIR_2_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).ORIG_CURRENCY_CODE:=j.ORIG_CURRENCY_CODE	;
				od_inv_org_loc_attr_rec_tbl(p_counter).STORE_CLASS_S:=j.STORE_CLASS_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).FORMAT_S:=j.FORMAT_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).DISTRICT_SW:=j.DISTRICT_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_DIVISION_ID_SW:=j.OD_DIVISION_ID_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_SUB_TYPE_CD_SW:=j.OD_SUB_TYPE_CD_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OPEN_DATE_SW:=j.OPEN_DATE_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).CLOSE_DATE_SW:=j.CLOSE_DATE_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).DEFAULT_WH_SW:=j.DEFAULT_WH_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_DEFAULT_WH_CSC_S:=j.OD_DEFAULT_WH_CSC_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_MKT_OPEN_DATE_S:=j.OD_MKT_OPEN_DATE_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).START_ORDER_DAYS_S:=j.START_ORDER_DAYS_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).STOP_ORDER_DAYS_S:=j.STOP_ORDER_DAYS_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_CLOSING_STORE_IND_S:=j.OD_CLOSING_STORE_IND_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_MODEL_TAX_LOC_SW:=j.OD_MODEL_TAX_LOC_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_LOC_BRAND_CD_SW:=j.OD_LOC_BRAND_CD_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_GEO_CD_SW:=j.OD_GEO_CD_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_BTS_FLIGHT_ID_SW:=j.OD_BTS_FLIGHT_ID_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_AD_MKT_ID_SW:=j.OD_AD_MKT_ID_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).CHANNEL_ID_SW:=j.CHANNEL_ID_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).TRANSACTION_NO_GENERATED_S:=j.TRANSACTION_NO_GENERATED_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_REMERCH_IND_S:=j.OD_REMERCH_IND_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_SISTER_STORE1_SW:=j.OD_SISTER_STORE1_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_SISTER_STORE2_SW:=j.OD_SISTER_STORE2_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_SISTER_STORE3_SW:=j.OD_SISTER_STORE3_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_CROSS_DOCK_LEAD_TIME_SW:=j.OD_CROSS_DOCK_LEAD_TIME_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_ORD_CUTOFF_TM_SW:=j.OD_ORD_CUTOFF_TM_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_DELIVERY_CD_SW:=j.OD_DELIVERY_CD_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_ROUTING_CD_SW:=j.OD_ROUTING_CD_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_RELOC_ID_SW:=j.OD_RELOC_ID_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).TOTAL_SQUARE_FEET_S:=j.TOTAL_SQUARE_FEET_S	;
				od_inv_org_loc_attr_rec_tbl(p_counter).BREAK_PACK_IND_W:=j.BREAK_PACK_IND_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).DELIVERY_POLICY_W:=j.DELIVERY_POLICY_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_EXPANDED_MIX_FLG_W:=j.OD_EXPANDED_MIX_FLG_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_DEFAULT_IMPORT_WH_W:=j.OD_DEFAULT_IMPORT_WH_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_EXTERNAL_WMS_SYSTEM_W:=j.OD_EXTERNAL_WMS_SYSTEM_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).PROTECTED_IND_W:=j.PROTECTED_IND_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).FORECAST_WH_IND_W:=j.FORECAST_WH_IND_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).REPL_IND_W:=j.REPL_IND_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).REPL_SRS_ORD_W:=j.REPL_SRS_ORD_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).RESTRICTED_IND_W:=j.RESTRICTED_IND_W	;
				od_inv_org_loc_attr_rec_tbl(p_counter).PICKUP_DELIVERY_CUTOFF_SW:=j.PICKUP_DELIVERY_CUTOFF_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).SAMEDAY_DELIVERY_SW:=j.SAMEDAY_DELIVERY_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).FURNITURE_CUTOFF_SW:=j.FURNITURE_CUTOFF_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).OD_WHSE_ORG_CD_SW:=j.OD_WHSE_ORG_CD_SW	;
				od_inv_org_loc_attr_rec_tbl(p_counter).ORG_TYPE:=j.ORG_TYPE	;
				od_inv_org_loc_attr_rec_tbl(p_counter).LINK_TO_RPF_AND_WH:=j.LINK_TO_RPF_AND_WH	;
				od_inv_org_loc_attr_rec_tbl(p_counter).SEGMENT1:=j.SEGMENT1	;
				od_inv_org_loc_attr_rec_tbl(p_counter).SEGMENT2:=j.SEGMENT2	;


			  
			end loop; -- c2 loop end
			
		
		p_counter:=p_counter+1;
 
      end loop; --Cursor c1 loop ends
	  
	  print_out_msg('                                                                                                                                          Request Date :'||sysdate);
	  print_out_msg(' ');
	  Print_Out_Msg(' ');
	  Print_Out_Msg('Location Number         ');
    print_out_msg('----------------------  '); 	  
    
      if p_counter < 2 then  	
        print_out_msg(' ');
  	    Print_Out_Msg(' ');
  		print_out_msg(' ');
	    print_out_msg(' --------      NO DATA EXISTS  ----------  ');
	  end if;
	 
     -- call the xml tag creation procedure
	  If P_Counter > 1 Then
 	      Xx_Od_Inv_Org_Loc_Xml_Tag(Od_Inv_Org_Loc_Attr_Rec_Tbl);
    end if;
   
    
 EXCEPTION
   WHEN OTHERS THEN
      x_retcode := 2;
      x_errbuf  := SUBSTR(sqlerrm,1,240); 
      print_out_msg('ErrBuf :'||x_errbuf || 'Retcode:'|| to_char(x_retcode));
 END MAIN;
 

END XX_INV_ORG_LOC_ATT_OBD_PKG;
/
