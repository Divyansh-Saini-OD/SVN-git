create or replace 
PACKAGE XX_TDS_AUTO_REPROCESS_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- +============================================================================================+
  -- |  Name:  XX_TDS_AUTO_REPROCESS_PKG                                                          |
  -- |  Description:  Package to reprocess TDS Orders                                             |
  -- |  Rice ID : E3114                                                                           |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         21-Jan-2015   Rma Goyal       Initial version                                  |
  -- +============================================================================================+
  PROCEDURE XX_MAIN(
      ERRBUFF OUT NOCOPY VARCHAR2,
      RETCODE OUT NOCOPY NUMBER,
      P_ACTION_TYPE IN VARCHAR2,
      P_FROM_DATE   IN VARCHAR2 );
  
  PROCEDURE REPROCESS_NC(
      P_FROM_DATE IN VARCHAR2 );
  
  PROCEDURE REPROCESS_NT(
    P_FROM_DATE IN VARCHAR2 );
  
  PROCEDURE REPROCESS_NC_ONE(
      P_FROM_DATE       IN VARCHAR2,
      P_INCIDENT_NUMBER IN VARCHAR2,
      P_TASK_ID         IN NUMBER,
      P_TASK_DESC       IN VARCHAR2,
      P_TASK_OBJ_NUM    IN NUMBER,
      X_RETURN_VAL OUT VARCHAR2 );
  
  PROCEDURE REPROCESS_NT_ONE(
      P_FROM_DATE    IN VARCHAR2,
      P_INCIDENT_NUM IN VARCHAR2,
      X_RETURN_VAL OUT VARCHAR2 );
  
  PROCEDURE monitor_query_report(
      retcode OUT NUMBER,
      ERRBUF OUT VARCHAR2 );
  
  PROCEDURE int_error_mail_msg(
      P_MASTER_DATA IN VARCHAR2 );
END XX_TDS_AUTO_REPROCESS_PKG;

/