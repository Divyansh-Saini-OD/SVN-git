CREATE OR REPLACE PACKAGE APPS.XX_PO_APPTINFO_PKG AS
/******************************************************************************
   NAME:       XX_PO_APPTINFO_PKG 
   PURPOSE:    Write Appointment Info from XX_PO_APPOINTMENT_DATE_TEMP to 
               XX_PO_APPOINTMENT_DATE for both Conversion and Interface processing 


   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/19/2007             1. Created this package.
******************************************************************************/

PROCEDURE XX_PO_APPTINFO(x_error_buff	OUT	VARCHAR2
                        ,x_ret_code	    OUT	VARCHAR2);
                   
END XX_PO_APPTINFO_PKG; 
/

