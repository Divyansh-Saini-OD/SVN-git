CREATE OR REPLACE PACKAGE XX_GI_MISSHIP_RECPT_PKG  AUTHID CURRENT_USER
-- +=============================================================================+
-- |                  Office Depot - Project Simplify                            |
-- |                Oracle NAIO Consulting Organization                          |
-- +=============================================================================+
-- | Name        :  XX_GI_MISSHIP_RECPT_PKG.pks                                  |
-- | Description :  Matches and Validated the PO from staging table and Standard |
-- |                Table                                                        |
-- |                                                                             |
-- |Change Record:                                                               |
-- |===============                                                              |
-- |  Version      Date         Author             Remarks                       |
-- | =========  =========== =============== ==================================== |
-- |  DRAFT 1a  24-Oct-2007   Meenu Goyal     Initial draft version              |
-- +=============================================================================+
AS

--Declaring global variables to get the profile values

GN_REPROCESSING_FREQUENCY    CONSTANT NUMBER        := FND_PROFILE.VALUE('OD: PO CUSTOM IV REPROCESSING FREQUENCY');
GC_TRADE_EMAIL               CONSTANT VARCHAR2(250) := FND_PROFILE.VALUE('OD: GI MISSHIP TRADE ITEM NOTIFICATION TEAM');
GC_NON_TRADE_EMAIL           CONSTANT VARCHAR2(250) := FND_PROFILE.VALUE('OD: GI MISSHIP NON-TRADE ITEM NOTIFICATION TEAM');
GN_MASTER_ORGANIZATION       mtl_parameters.organization_id%type;


--Global variables used for assigning program values for inserting in the common error table

GC_PROGRAM_TYPE            CONSTANT VARCHAR2(20)    := 'CONCURRENT_PROGRAM' ;     
GC_PROGRAM_NAME            CONSTANT VARCHAR2(30)    := 'XX_GI_MISSHIP_RECPT_PKG'; 
GC_MODULE_NAME             CONSTANT VARCHAR2(20)    := 'GI';                     
GC_NOTIFY                  CONSTANT VARCHAR2(1)     := 'Y';
GC_MAJOR                   CONSTANT VARCHAR2(5)     := 'MAJOR';

--------------------------------------------------------------------------------------------------------
--Declaring VALIDATE_SKU_RECPT_PROC procedure which gets called from OD: GI Item Validation For RST Data
--------------------------------------------------------------------------------------------------------

PROCEDURE validate_sku_recpt_proc (
                                  x_errbuf    OUT NOCOPY VARCHAR2
                                 ,x_retcode   OUT NOCOPY VARCHAR2
                                  );
                                  
                                  
END XX_GI_MISSHIP_RECPT_PKG ;                                  