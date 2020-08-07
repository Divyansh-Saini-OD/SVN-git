CREATE OR REPLACE PACKAGE APPS.XX_PO_SHIPSTAT_CONV_PKG AS
/******************************************************************************
   NAME:       XX_PO_SHIPSTAT_CONV_PKG 
   PURPOSE:    Process the Load portion of the PO Ship Status Conversions,
               which will take data from from XX_PO_SHIP_STATUS_CONV_STG,
               determine the EBS Organization ID and which ship date we're
               processing, and write the result to XX_PO_SHIP_STATUS 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/19/2007   Roc Polimeni         1. Created this package.
******************************************************************************/


PROCEDURE XX_PO_SHIPSTAT_CONV;

END XX_PO_SHIPSTAT_CONV_PKG;
/
