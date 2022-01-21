create or replace PACKAGE XX_OM_ADI_ERROR_TRACKING_PKG 
as
   -- +=====================================================================================+
   -- |                  Office Depot - Project Simplify                                    |
   -- +=====================================================================================+
   -- | Name       : XX_OM_ADI_ERROR_TRACKING_PKG                                           |
   -- | RICE ID    : NA                                                                     |
   -- | Description: This package is used to insert records into XX_OM_ADI_ERROR_STATUS     |
   -- |              from Web ADI integrator OD: OM Order Error Status Tracking             |
   -- |                                                                                     |
   -- |Change Record:                                                                       |
   -- |===============                                                                      |
   -- |Version    Date         Author         Remarks                                       |
   -- |=========  ===========  =============  =============================                 |
   -- |1.0        12-Aug-2020  Atul K         Initial version                               |
   -- +=====================================================================================+
	PROCEDURE GET_ADI_RECORD(
				P_ORIG_SYS_DOCUMENT_REF IN VARCHAR2,
				P_ACTION_PERFORMED IN VARCHAR2,
				P_PERFORMED_BY IN VARCHAR2);
END XX_OM_ADI_ERROR_TRACKING_PKG;
/