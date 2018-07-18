create or replace 
PACKAGE BODY XX_TDS_AUTO_REPROCESS_PKG
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
  -- | 2.0         21-Jan-2016   Vasu Raparla    Removed Schema References for R.12.2             |
  -- +============================================================================================+
  -- +============================================================================+
  -- | Name             : SEND_EMAIL                                              |
  -- |                                                                            |
  -- | Description      : This procedure will email the output of the             |
  -- |                    main program to reprocess orders                        |
  -- | Parameters       :                                                         |
  -- |                  :                                                         |
  -- |                  :                                                         |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      21-Jan-2015  Rma Goyal      Initial version                       |
  -- +============================================================================+
PROCEDURE SEND_EMAIL
IS
  L_REQ_ID         NUMBER:=0;
  L_MAIL_RECIPIENT VARCHAR2(200); -- Size of 200 to accomodate additions to translation for email addresses
BEGIN
  BEGIN
    SELECT XFTV.TARGET_VALUE1
      || ','
      ||XFTV.TARGET_VALUE2
      ||','
      ||XFTV.TARGET_VALUE3
    INTO L_MAIL_RECIPIENT
    FROM XX_FIN_TRANSLATEDEFINITION XFTD ,
      XX_FIN_TRANSLATEVALUES XFTV
    WHERE XFTD.TRANSLATE_ID   = XFTV.TRANSLATE_ID
    AND XFTD.TRANSLATION_NAME = 'XX_TDS_EBS_NOTIFY_EMAIL'
    AND XFTV.SOURCE_VALUE1    ='XX_TDS_EMAIL'
    AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1)
    AND SYSDATE BETWEEN XFTD.START_DATE_ACTIVE AND NVL(XFTD.END_DATE_ACTIVE,SYSDATE+1)
    AND XFTV.ENABLED_FLAG = 'Y'
    AND XFTD.ENABLED_FLAG = 'Y';
  EXCEPTION
  WHEN OTHERS THEN
     FND_FILE.PUT_LINE(FND_FILE.LOG, ' Mailing List Generation Ended in Exception.');
  end;
  L_REQ_ID         := FND_REQUEST.SUBMIT_REQUEST ('xxfin' ,'XXODROEMAILER' ,'' ,'' ,FALSE ,'OD:TDS Retrigger Orders from EBS' , L_MAIL_RECIPIENT ,' OD:TDS Retrigger Orders from EBS' ,' OD:TDS Retrigger Orders from EBS' ,'Y' ,FND_GLOBAL.CONC_REQUEST_ID);
END SEND_EMAIL;
-- +============================================================================+
-- | Name             : XX_MAIN                                                 |
-- |                                                                            |
-- | Description      : This procedure is the main procedure called from the    |
-- |                    concurrent program                                      |
-- | Parameters       : p_action_type can be NC - Tasks without Connect Button  |
-- |                                         NT - Tasks not created in EBS      |
-- |                  :   p_from_date is the user entered date                  |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      21-Jan-2015  Rma Goyal      Initial version                       |
-- +============================================================================+
PROCEDURE XX_MAIN(
    ERRBUFF OUT NOCOPY VARCHAR2,
    RETCODE OUT NOCOPY NUMBER,
    P_ACTION_TYPE IN VARCHAR2,
    P_FROM_DATE   IN VARCHAR2 )
IS
BEGIN
  IF P_ACTION_TYPE = 'NC' THEN
    BEGIN
      REPROCESS_NC(P_FROM_DATE);
      SEND_EMAIL();
    END;
  ELSIF P_ACTION_TYPE = 'NT' THEN
    BEGIN
      REPROCESS_NT(P_FROM_DATE);
      SEND_EMAIL();
    END;
  END IF;
END XX_MAIN;
-- +============================================================================+
-- | Name             : REPROCESS_NT                                            |
-- |                                                                            |
-- | Description      : This procedure reprocessed all the stuck service orders |
-- |                    for which tasks were not created. This is based on      |
-- |                  p_action_type=NT in the XX_MAIN                           |
-- | Parameters       : p_from_date is the user entered date                    |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      21-Jan-2015  Rma Goyal      Initial version                       |
-- +============================================================================+
PROCEDURE REPROCESS_NT(
    P_FROM_DATE IN VARCHAR2)
IS
  L_P_FROM_DATE DATE;
  CURSOR SR_TO_TRIGGER
  IS
    SELECT INCIDENT_ID
    FROM CS_INCIDENTS_ALL_B
    WHERE 2          =2
    AND INCIDENT_ID IN
      (SELECT INCIDENT_ID
      FROM CS_INCIDENTS_ALL_B
      WHERE CREATION_DATE >TO_DATE(P_FROM_DATE, 'YYYY/MM/DD HH24:MI:SS')
      AND PROBLEM_CODE    = 'TDS-SERVICES'
      AND NOT EXISTS
        (SELECT'X'
        FROM JTF_TASKS_B
        WHERE 1                     =1
        AND source_object_type_code = 'SR'
        AND SOURCE_OBJECT_ID        = CS_INCIDENTS_ALL_B.INCIDENT_ID
        )
      );
    SR_TO_TRIGGER_REC SR_TO_TRIGGER%ROWTYPE;
    LC_STATUS       VARCHAR2(100);
    LN_STATUS_ID    NUMBER;
    LN_USER_ID      NUMBER :=0;
    X_RETURN_STATUS VARCHAR2(25);
    LC_MESSAGE      VARCHAR2(250);
  BEGIN
    IF P_FROM_DATE  IS NULL THEN
      L_P_FROM_DATE := SYSDATE-1;
    ELSE
      L_P_FROM_DATE := FND_DATE.CANONICAL_TO_DATE(P_FROM_DATE);
    END IF;
    BEGIN
      SELECT USER_ID INTO LN_USER_ID FROM FND_USER WHERE USER_NAME = 'CS_ADMIN';
    EXCEPTION
    WHEN OTHERS THEN
      X_RETURN_STATUS := 'F';
    END;
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inside No Tasks Created; Date From:'||P_FROM_DATE) ;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'           Work Orders without Tasks in EBS           ') ;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Service Order # ');
    FOR SR_TO_TRIGGER_REC IN SR_TO_TRIGGER
    LOOP
      LN_STATUS_ID := 1;
      LC_STATUS    := 'Open';
      -- update SR status
      BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,SR_TO_TRIGGER_REC.INCIDENT_ID);
        XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(P_SR_REQUEST_ID => SR_TO_TRIGGER_REC.INCIDENT_ID, P_USER_ID => LN_USER_ID, P_STATUS_ID => LN_STATUS_ID, P_STATUS => LC_STATUS, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_DATA => LC_MESSAGE);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'After open ');
        COMMIT;
      END;
      LN_STATUS_ID := 6100;
      LC_STATUS    := 'Service Not Started';
      -- update SR status
      BEGIN
        XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(P_SR_REQUEST_ID => SR_TO_TRIGGER_REC.INCIDENT_ID, P_USER_ID => LN_USER_ID, P_STATUS_ID => LN_STATUS_ID, P_STATUS => LC_STATUS, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_DATA => LC_MESSAGE);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'After Service not started ');
        COMMIT;
      END;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'End Loop ');
    --CLOSE SR_TO_TRIGGER;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error: '||SQLERRM);
  END REPROCESS_NT;
  -- +============================================================================+
  -- | Name             : REPROCESS_NC                                            |
  -- |                                                                            |
  -- | Description      : This procedure reprocessed all the stuck service orders |
  -- |                    for which tasks do not have connect button, based on    |
  -- |                  p_action_type=NC in the XX_MAIN                         |
  -- | Parameters       : p_from_date is the user entered date                    |
  -- |                                                                            |
  -- | Change Record:                                                             |
  -- | ==============                                                             |
  -- | Version  Date         Author          Remarks                              |
  -- | =======  ===========  =============   ===================================  |
  -- | 1.0      21-Jan-2015  Rma Goyal      Initial version                       |
  -- +============================================================================+
PROCEDURE REPROCESS_NC(
    P_FROM_DATE IN VARCHAR2 )
IS
  L_P_FROM_DATE DATE;
  CURSOR TASK_BE_TRIGGER
  IS
    SELECT CIAB.INCIDENT_NUMBER,
      CIAB.INCIDENT_ID,
      JTV.TASK_ID,
      JTV.OBJECT_VERSION_NUMBER,
      JTV.DESCRIPTION
    FROM JTF_TASKS_VL JTV,
      JTF_TASK_STATUSES_VL JTSV,
      JTF_TASK_TYPES_tL JTTV,
      CS_INCIDENTS_ALL_B CIAB,
      CS_INCIDENT_TYPES_VL CITV
    WHERE JTV.SOURCE_OBJECT_TYPE_CODE = 'SR'
    AND JTV.ATTRIBUTE1                = 'Support.com'
    AND JTV.ATTRIBUTE5                ='R'
    AND JTSV.TASK_STATUS_ID           = JTV.TASK_STATUS_ID
    AND JTTV.TASK_TYPE_ID             =JTV.TASK_TYPE_ID
    AND JTTV.NAME                     = 'In Store Remote'
    AND JTSV.TASK_STATUS_ID           = 14
    AND CIAB.INCIDENT_ID              = JTV.SOURCE_OBJECT_ID
    AND (CIAB.INCIDENT_STATUS_ID NOT IN (2,9100)
    OR CIAB.INCIDENT_STATUS_ID        =4100)
    AND CITV.INCIDENT_TYPE_ID         = CIAB.INCIDENT_TYPE_ID
    AND CITV.INCIDENT_SUBTYPE         = 'INC'
    AND CITV.END_DATE_ACTIVE         IS NULL
    AND CITV.NAME LIKE 'TDS%'
    and CIAB.EXTERNAL_ATTRIBUTE_14 is null
    and CIAB.CREATION_DATE          >TO_DATE(P_FROM_DATE, 'DD-MON-YYYY HH24:MI:SS');
    --AND CIAB.CREATION_DATE          >TO_DATE(P_FROM_DATE, 'YYYY/MM/DD HH24:MI:SS');
  TASK_BE_TRIGGER_REC TASK_BE_TRIGGER%ROWTYPE;
  X_RETURN_STATUS VARCHAR2(250);
  X_MSG_COUNT     VARCHAR2(250);
  X_MSG_DATA      VARCHAR2(250);
  LN_DESCRIPTION  VARCHAR2(500);
  LN_MSG_COUNT    VARCHAR2(100);
  l_response      VARCHAR2(2000);
BEGIN
  IF P_FROM_DATE  IS NULL THEN
    L_P_FROM_DATE := SYSDATE-1;
  ELSE
    L_P_FROM_DATE := FND_DATE.CANONICAL_TO_DATE(P_FROM_DATE);
  END IF;
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inside No Connect Button Date From:'||P_FROM_DATE) ;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'           Work Orders without Connect Button in EBS           ') ;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Task #' ||',' || 'Service Order # '||','||'Message');
  FOR TASK_BE_TRIGGER_REC IN TASK_BE_TRIGGER
  LOOP
    BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Initiating task update:' || TASK_BE_TRIGGER_REC.TASK_ID || 'For Service Order: '|| TASK_BE_TRIGGER_REC.INCIDENT_NUMBER);
      LN_DESCRIPTION:= TASK_BE_TRIGGER_REC.DESCRIPTION||'.';
      JTF_TASKS_PUB.UPDATE_TASK ( P_OBJECT_VERSION_NUMBER => TASK_BE_TRIGGER_REC.OBJECT_VERSION_NUMBER ,P_API_VERSION => 1.0 ,P_INIT_MSG_LIST => FND_API.G_TRUE ,P_COMMIT => FND_API.G_TRUE ,P_TASK_ID => TASK_BE_TRIGGER_REC.TASK_ID ,X_RETURN_STATUS => X_RETURN_STATUS ,X_MSG_COUNT => LN_MSG_COUNT ,X_MSG_DATA => X_MSG_DATA ,P_DESCRIPTION => LN_DESCRIPTION);
      SELECT RESPONDER_COMMENT
      INTO L_RESPONSE
      FROM CS_MESSAGES
      where SOURCE_OBJECT_INT_ID = TASK_BE_TRIGGER_REC.INCIDENT_ID
      and LAST_UPDATE_DATE       > TO_DATE(P_FROM_DATE, 'DD-MON-YYYY HH24:MI:SS')
   --   AND LAST_UPDATE_DATE       > TO_DATE(P_FROM_DATE, 'YYYY/MM/DD HH24:MI:SS')
      AND ROWNUM                 <2 ;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, TASK_BE_TRIGGER_REC.TASK_ID ||',' || TASK_BE_TRIGGER_REC.INCIDENT_NUMBER||','|| L_RESPONSE);
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error updating task:' || TASK_BE_TRIGGER_REC.TASK_ID || 'For Service Order: '|| TASK_BE_TRIGGER_REC.INCIDENT_NUMBER || 'Error is : '|| X_MSG_DATA);
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Error updating task:' || TASK_BE_TRIGGER_REC.TASK_ID || 'For Service Order: '|| TASK_BE_TRIGGER_REC.INCIDENT_NUMBER || 'Error is : '|| X_MSG_DATA);
    END;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Error triggering Business Event');
END REPROCESS_NC;
-- +============================================================================+
-- | Name             : REPROCESS_NC_ONE                                        |
-- |                                                                            |
-- | Description      : This procedure reprocessed the user-selected orders     |
-- |                    for which tasks do not have connect button, based on    |
-- |                  action from the user screen                             |
-- | Parameters       : p_from_date is the user entered date                    |
-- |                  : p_incident_number is the service order number           |
-- |                  : p_task_id is the id of the task without connect button  |
-- |                  : p_task_desc is the description of the task              |
-- |                  : p_task_obj_num is the object version number of the task |
-- |                                                                            |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      21-Jan-2015  Rma Goyal      Initial version                       |
-- +============================================================================+
PROCEDURE REPROCESS_NC_ONE(
    P_FROM_DATE       IN VARCHAR2,
    P_INCIDENT_NUMBER IN VARCHAR2,
    P_TASK_ID         IN NUMBER,
    P_TASK_DESC       in varchar2,
    P_TASK_OBJ_NUM    IN NUMBER,
    X_RETURN_VAL OUT VARCHAR2 )
IS
  X_RETURN_STATUS VARCHAR2(250);
  X_MSG_COUNT     VARCHAR2(250);
  X_MSG_DATA      VARCHAR2(250);
  L_TASK_DESC     VARCHAR2(80); -- Database limit is 80 for this field
  L_TASK_ID       NUMBER;
  L_TASK_OBJ_NUM  NUMBER;
  LN_MSG_COUNT    varchar2(100);
  l_order             VARCHAR2(5000):=NULL;
BEGIN
  L_TASK_ID     :=P_TASK_ID;
  L_TASK_OBJ_NUM:=P_TASK_OBJ_NUM;
  L_TASK_DESC   :=P_TASK_DESC||'.';
  JTF_TASKS_PUB.UPDATE_TASK ( P_OBJECT_VERSION_NUMBER => L_TASK_OBJ_NUM ,P_API_VERSION => 1.0 ,P_INIT_MSG_LIST => FND_API.G_TRUE ,P_COMMIT => FND_API.G_TRUE ,P_TASK_ID => L_TASK_ID ,X_RETURN_STATUS => X_RETURN_STATUS ,X_MSG_COUNT => LN_MSG_COUNT ,X_MSG_DATA => X_MSG_DATA ,P_DESCRIPTION => L_TASK_DESC);
  l_order :=  'Order Reprocessed: ' || CHR (10) || P_INCIDENT_NUMBER || CHR (10) ;
  
  X_RETURN_STATUS:='SUCCESS';
  X_RETURN_VAL   :=X_RETURN_STATUS;
  
    FND_FILE.PUT_LINE (FND_FILE.log,' l_order..' || L_ORDER );
    INT_ERROR_MAIL_MSG (L_ORDER);
    
EXCEPTION
WHEN OTHERS THEN
  X_RETURN_STATUS:='FAILED';
  X_RETURN_VAL   :=X_RETURN_STATUS;
END REPROCESS_NC_ONE;
-- +============================================================================+
-- | Name             : REPROCESS_NT_ONE                                        |
-- |                                                                            |
-- | Description      : This procedure reprocessed the user-selected orders     |
-- |                    for which tasks were not created. This is based on      |
-- |                  action from the user screen                             |
-- | Parameters       : p_from_date is the user entered date                    |
-- |                  : p_incident_number is the service order number           |
-- | Change Record:                                                             |
-- | ==============                                                             |
-- | Version  Date         Author          Remarks                              |
-- | =======  ===========  =============   ===================================  |
-- | 1.0      21-Jan-2015  Rma Goyal      Initial version                       |
-- +============================================================================+
PROCEDURE REPROCESS_NT_ONE(
    P_FROM_DATE    IN VARCHAR2,
    P_INCIDENT_NUM IN VARCHAR2,
    X_RETURN_VAL OUT VARCHAR2 )
IS
  X_RETURN_STATUS VARCHAR2(250);
  X_MSG_COUNT     VARCHAR2(250);
  X_MSG_DATA      VARCHAR2(250);
  L_MSG_DATA      VARCHAR2(250);
  LN_MSG_COUNT    VARCHAR2(100);
  L_INCIDENT_ID   NUMBER;
  L_INCIDENT_NUM  VARCHAR2(64);
  LN_USER_ID      NUMBER :=0;
  L_STATUS_ID     NUMBER;
  L_STATUS        varchar2(90);
  l_order             VARCHAR2 (5000) := NULL;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Inside No Tasks ONE Date From:'||P_FROM_DATE) ;
  BEGIN
    SELECT USER_ID INTO LN_USER_ID FROM FND_USER WHERE USER_NAME = 'CS_ADMIN';
  EXCEPTION
  WHEN OTHERS THEN
    X_RETURN_STATUS := 'F';
  END;
  BEGIN
    SELECT INCIDENT_ID
    INTO L_INCIDENT_ID
    FROM CS_INCIDENTS_ALL_B
    WHERE INCIDENT_NUMBER=P_INCIDENT_NUM;
  END;
  L_STATUS_ID :=1;
  L_STATUS    :='Open';
  BEGIN
    XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(P_SR_REQUEST_ID => L_INCIDENT_ID, P_USER_ID => LN_USER_ID, P_STATUS_ID =>L_STATUS_ID, P_STATUS => L_STATUS, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_DATA => L_MSG_DATA);
    COMMIT;
  END;
  L_STATUS_ID:=6100;
  L_STATUS   :='Service Not Started';
  BEGIN
    XX_CS_SR_UTILS_PKG.UPDATE_SR_STATUS(P_SR_REQUEST_ID => L_INCIDENT_ID, P_USER_ID => LN_USER_ID, P_STATUS_ID => L_STATUS_ID, P_STATUS => L_STATUS, X_RETURN_STATUS => X_RETURN_STATUS, X_MSG_DATA => L_MSG_DATA);
    COMMIT;
  END;
  X_RETURN_STATUS:='SUCCESS';
  X_RETURN_VAL   :=X_RETURN_STATUS;
  l_order :=  'Order Reprocessed: ' || CHR (10) || P_INCIDENT_NUM || CHR (10) ;
    FND_FILE.PUT_LINE (FND_FILE.LOG,' l_order..' || l_order );
    INT_ERROR_MAIL_MSG (L_ORDER);
  
EXCEPTION
WHEN OTHERS THEN
  X_RETURN_STATUS:='FAILED';
  X_RETURN_VAL   :=X_RETURN_STATUS;
END REPROCESS_NT_ONE;
PROCEDURE monitor_query_report(
    retcode OUT NUMBER,
    errbuf OUT VARCHAR2 )
IS
  l_master_order      VARCHAR2 (1000) := NULL;
  l_order             VARCHAR2 (5000) := NULL;
  l_count             NUMBER          := 0;
  p_status            VARCHAR2 (10);
  lc_error_message    VARCHAR2 (1000);
  l_loc_cnt           NUMBER          := 0;
  l_child_item        VARCHAR2 (1000) := NULL;
  l_loc               VARCHAR2 (1000) := NULL;
  l_organization_name VARCHAR2 (1000) := NULL;
  l_child_item_code CLOB              := NULL;
  l_check VARCHAR2(1)                 :='Y';
  CURSOR order_stuck
  IS
    SELECT CIAB.INCIDENT_NUMBER INCIDENT_NUMBER,
      CIAB.INCIDENT_date incident_date,
      CIAB.INCIDENT_ID,
      JTV.TASK_ID,
      JTV.OBJECT_VERSION_NUMBER,
      JTV.DESCRIPTION
    FROM JTF_TASKS_VL JTV,
      JTF_TASK_STATUSES_VL JTSV,
      JTF_TASK_TYPES_TL JTTV,
      CS_INCIDENTS_ALL_B CIAB,
      CS_INCIDENT_TYPES_VL CITV
    WHERE JTV.SOURCE_OBJECT_TYPE_CODE = 'SR'
    AND JTV.ATTRIBUTE1                = 'Support.com'
    AND JTV.ATTRIBUTE5                ='R'
    AND JTSV.TASK_STATUS_ID           = JTV.TASK_STATUS_ID
    AND JTTV.TASK_TYPE_ID             =JTV.TASK_TYPE_ID
    AND JTTV.NAME                     = 'In Store Remote'
    AND JTSV.TASK_STATUS_ID           = 14
    AND CIAB.INCIDENT_ID              = JTV.SOURCE_OBJECT_ID
    AND (CIAB.INCIDENT_STATUS_ID NOT IN (2,9100)
    OR CIAB.INCIDENT_STATUS_ID        =4100)
    AND CITV.INCIDENT_TYPE_ID         = CIAB.INCIDENT_TYPE_ID
    AND CITV.INCIDENT_SUBTYPE         = 'INC'
    AND CITV.END_DATE_ACTIVE         IS NULL
    AND CITV.NAME LIKE 'TDS%'
    AND CIAB.EXTERNAL_ATTRIBUTE_14 IS NULL;
BEGIN
  FOR order_stuck_rec IN order_stuck
  LOOP
    L_MASTER_ORDER := ORDER_STUCK_REC.INCIDENT_NUMBER || ',' || ORDER_STUCK_REC.INCIDENT_DATE;
    fnd_file.put_line (fnd_file.LOG, ' L_MASTER_ORDER..' || L_MASTER_ORDER );
    l_order := l_order || CHR (10) || l_master_order || CHR (10) ;
    FND_FILE.PUT_LINE (FND_FILE.LOG,' l_order..' || l_order );
  END LOOP;
  int_error_mail_msg (l_order);
  retcode := 0;
  errbuf  := 'Y';
EXCEPTION
WHEN NO_DATA_FOUND THEN
  lc_error_message := 'No Data found';
  p_status         := 'N';
WHEN OTHERS THEN
  lc_error_message := 'Unknown Error occured';
  P_STATUS         := 'N';
END monitor_query_report;
-- Procedure  to send Email notification to RMS team to trigger the items
PROCEDURE int_error_mail_msg(
    p_master_data IN VARCHAR2 )
IS
  lc_mail_from      VARCHAR2 (100) := 'EBS_TDS_MONITOR';
  lc_mail_recipient VARCHAR2 (1000);
  LC_MAIL_SUBJECT   VARCHAR2 (1000) := 'TDS Orders Stuck in EBS';
  lc_mail_host      VARCHAR2 (100)  := FND_PROFILE.VALUE('XX_COMN_SMTP_MAIL_SERVER');
  lc_mail_conn UTL_SMTP.connection;
  crlf        VARCHAR2 (10) := CHR (13) || CHR (10);
  slen        NUMBER        := 1;
  v_addr      VARCHAR2 (1000);
  lc_instance VARCHAR2 (100);
  l_text      VARCHAR2(2000) := NULL;
BEGIN
  lc_mail_conn := UTL_SMTP.open_connection (lc_mail_host, 25);
  UTL_SMTP.helo (lc_mail_conn, lc_mail_host);
  UTL_SMTP.mail (lc_mail_conn, lc_mail_from);
  SELECT XFTV.TARGET_VALUE1
    || ','
    ||XFTV.TARGET_VALUE2
    ||','
    ||XFTV.TARGET_VALUE3
  INTO Lc_MAIL_RECIPIENT
  FROM XX_FIN_TRANSLATEDEFINITION XFTD ,
    XX_FIN_TRANSLATEVALUES XFTV
  WHERE XFTD.TRANSLATE_ID   = XFTV.TRANSLATE_ID
  AND XFTD.TRANSLATION_NAME = 'XX_TDS_EBS_NOTIFY_EMAIL'
  AND XFTV.SOURCE_VALUE1    ='XX_TDS_EMAIL'
  AND SYSDATE BETWEEN XFTV.START_DATE_ACTIVE AND NVL(XFTV.END_DATE_ACTIVE,SYSDATE+1)
  AND SYSDATE BETWEEN XFTD.START_DATE_ACTIVE AND NVL(XFTD.END_DATE_ACTIVE,SYSDATE+1)
  AND XFTV.ENABLED_FLAG              = 'Y'
  AND XFTD.ENABLED_FLAG              = 'Y';
  
    V_ADDR                          := LC_MAIL_RECIPIENT;
   
    
  
  SELECT NAME INTO lc_instance FROM v$database;
  UTL_SMTP.DATA (lc_mail_conn, 'From:' || lc_mail_from || UTL_TCP.crlf || 'To: ' || v_addr || UTL_TCP.crlf || 'Subject: ' || lc_mail_subject || UTL_TCP.CRLF || 'OMServices Team,' || crlf || crlf || crlf || 'TDS Orders are stuck in EBS' || crlf || CRLF ||'Current Impact: Impact on Customer Service and Store Operations' || crlf || crlf || '-------------------------------------------------------------------------------------------------' || CRLF || 'Request to clear the orders' || crlf || '-------------------------------------------------------------------------------------------------' || crlf || p_master_data || crlf || crlf );
  UTL_SMTP.quit (lc_mail_conn);
END INT_ERROR_MAIL_MSG;
END XX_TDS_AUTO_REPROCESS_PKG;


/