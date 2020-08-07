CREATE OR REPLACE PACKAGE APPS.XX_PO_SHIPSTATUS_PKG AS
/******************************************************************************
   NAME:       PO_LIB
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        6/12/2007             1. Created this package.
******************************************************************************/

  
  FUNCTION XX_PO_SHIPSTATUS_UPDATE (I_Bill_of_Lading   in VARCHAR2,
                                     I_Document_Nbr     in VARCHAR2,    -- includes Loc_ID 
                                    I_Pro_Bill_Nbr     in VARCHAR2,
                                    I_Reason_CD        in VARCHAR2,
                                    I_SCAC             in VARCHAR2,
                                    I_Status_Code      in VARCHAR2,
                                    I_ShipDateTime     in VARCHAR2)  -- includes Date, Time, and Time Zone 
    RETURN NUMBER;
    
  

END XX_PO_SHIPSTATUS_PKG;
/
