SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE xx_om_wsh_otm_inbound_grp_pkg
/* $Header: /home/cvs/repository/Office_Depot/SRC/OTC/E0280_CarrierSelection/3.\040Source\040Code\040&\040Install\040Files/XX_OM_WSH_OTM_INBOUND_GRP_PKG.pks,v 1.3 2007/07/26 10:07:28 vvtamil Exp $ */

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
   -- ----------------------------------
   -- Global Variable Declarations
   -- ----------------------------------

   ge_exception  xxod_report_exception := xxod_report_exception(
                                                                 'OTHERS'
                                                                ,'OTC'
                                                                ,'Carrier Selection'
                                                                ,'Carrier Selection'
                                                                ,NULL
                                                                ,NULL
                                                                ,NULL
                                                                ,NULL
                                                               );

   -- +===================================================================+
   -- | Name        : Write_Exception                                     |
   -- | Description : Procedure to log exceptions from this package using |
   -- |               the Common Exception Handling Framework             |
   -- |                                                                   |
   -- | Parameters  : Error_Code                                          |
   -- |               Error_Description                                   |
   -- |               Entity_Reference                                    |
   -- |               Entity_Reference_Id                                 |
   -- |                                                                   |
   -- +===================================================================+

   PROCEDURE Write_Exception(
                              p_error_code        IN  VARCHAR2
                             ,p_error_description IN  VARCHAR2
                             ,p_entity_reference  IN  VARCHAR2
                             ,p_entity_ref_id     IN  VARCHAR2
                            );

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

   PROCEDURE initiate_planned_shipment(p_int_trip_info     IN   XX_OM_WSH_OTM_TRIP_TAB
                                      ,x_output_request_id OUT  NOCOPY NUMBER
                                      ,x_return_status     OUT  NOCOPY VARCHAR2
                                      ,x_msg_count         OUT  NOCOPY NUMBER
                                      ,x_msg_data          OUT  NOCOPY VARCHAR2
                                      );

END xx_om_wsh_otm_inbound_grp_pkg;
/
SHOW ERRORS;