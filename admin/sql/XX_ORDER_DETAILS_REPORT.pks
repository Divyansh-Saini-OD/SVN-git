create or replace PACKAGE     XX_ORDER_DETAILS_REPORT  
IS
/*=============================================================================+
|                Office Depot Inc. | Compucom CSI                              |
|                                                                              |
+============================================================================= +
| FILENAME     :  XX_ORDER_DETAILS_REPORT.pks                                  |
| DESCRIPTION  :  Order Details (Entered,Pending and Missing)                  |
| Author       :  Anmol Patil                                                  |
|                                                                              |
| HISTORY                                                                      |
| Version   Date        Author           Remarks                               |
| ====   ==========  =============    =========================================|
| 1.0    05-MAY-2021  Anmol Patil     Created New                              |
|                                                                              |      
|                                                                              |                  
==============================================================================*/

PROCEDURE Order_Details(ERR_BUFF          OUT NOCOPY varchar2
			      		,ERR_NUM          OUT NOCOPY number
						,P_ORDER_EXTRACT  IN VARCHAR2
						,P_START_DATE     IN VARCHAR2
						,P_END_DATE       IN VARCHAR2);

END  XX_ORDER_DETAILS_REPORT ;
/