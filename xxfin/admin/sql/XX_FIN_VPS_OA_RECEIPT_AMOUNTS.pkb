create or replace PACKAGE BODY XX_FIN_VPS_OA_RECEIPT_AMOUNTS
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XX_FIN_VPS_OA_RECEIPT_AMOUNTS.pkb                                                  |
  -- |                                                                                            |
  -- |  Description:  This package is used by REST SERVICES to pull VPS Receipts.                 |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUN-2017  Thejaswini Rajula    Initial version                              |
  -- +============================================================================================+

  g_pkg_name VARCHAR2(30):= 'XX_FIN_VPS_OA_RECEIPT_AMOUNTS';
  error_message VARCHAR2(256);
  return_status VARCHAr2(1);

  FUNCTION GET_RECEIPT_AMOUNTS (       
        From_Date      IN  VARCHAR2
      ) return varchar2
IS
  l_user_id                NUMBER;
  l_responsibility_id      NUMBER;
  l_responsibility_appl_id NUMBER;
  lv_count                 NUMBER := 0;
  ln_org_id                NUMBER;
  lv_receipts_array        VARCHAR2(32267);
  
  cursor c1 
  IS
     SELECT '{"Receipt_number":"' || Receipt_number  || 
            '","Receipt_date":"' || to_char(Receipt_date,'DD-MON-YYYY HH24:MI:SS') || 
            '","LAST_UPDATE_DATE":"' || to_char(RECEIPT_APPL_DATE,'DD-MON-YYYY HH24:MI:SS') ||
            '","Program_ID":"' || lpad(VPS_Program_ID,6,'0') || 
            '","Amount_Applied":' || SUM(amount_applied) || '}' as receipt_info
      FROM XX_FIN_VPS_RECEIPTS_INTERIM
    where  RECEIPT_APPL_DATE > to_date(FROM_DATE,'DD-MON-YYYY HH24:MI:SS')
      GROUP BY Receipt_number 
              ,Receipt_date 
              ,RECEIPT_APPL_DATE  
              ,VPS_Program_ID
       ;  

  BEGIN
    fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'Begin+' );
    BEGIN
      SELECT ORGANIZATION_ID
        INTO ln_org_id
        FROM HR_ALL_ORGANIZATION_UNITS
       WHERE NAME='OU_US_VPS'
       ;
       
      MO_GLOBAL.SET_POLICY_CONTEXT('S',ln_org_id);
      
    EXCEPTION
    WHEN OTHERS THEN
      error_message := 'Exception in initializing : ' || SQLERRM;
      fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'Unexpected Error: '||error_message );
      RETURN 'E';
    END;
    commit;
    BEGIN
      lv_receipts_array := null;
      lv_receipts_array := '[' ;
      FOR I IN c1 
      LOOP
        lv_receipts_array := lv_receipts_array || I.receipt_info || ',' ;
      END LOOP;
      lv_receipts_array := substr(lv_receipts_array,1,length(lv_receipts_array)-1);
      lv_receipts_array := lv_receipts_array || ']';
      fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'End-' );
      
      return lv_receipts_array;
    EXCEPTION
    WHEN OTHERS THEN
      error_message := 'While Fetching Receipts : ' || SQLERRM;
      fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'Unexpected Error: '||error_message );
      RETURN 'E';
    END;
    commit;
  EXCEPTION
    WHEN OTHERS THEN
      error_message := SUBSTR(sqlerrm,1,200)||'|'||SYSDATE;      
      fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'Unexpected Error: '||error_message );
  END GET_RECEIPT_AMOUNTS;

PROCEDURE Get_Receipts(
    Receipt_Details OUT XMLType
    ,FROM_DATE      IN  VARCHAR2
    )
IS
  l_user_id                NUMBER;
  l_responsibility_id      NUMBER;
  l_responsibility_appl_id NUMBER;
  lv_count                 NUMBER := 0;
  ln_org_id                NUMBER;
  ln_sum                   NUMBER(15,2) := 0.00;

  l_oa_receipt_obj         XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ;
  l_oa_receipt_obj_tbl     XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ_TBL := XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ_TBL();
  l_oa_receipts_obj        XXFIN.XX_FIN_VPS_OA_RECEIPTS_OBJ := XXFIN.XX_FIN_VPS_OA_RECEIPTS_OBJ(null, XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ_TBL());   
    
BEGIN
    fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'Begin+' );
    BEGIN
      SELECT ORGANIZATION_ID
        INTO ln_org_id
        FROM HR_ALL_ORGANIZATION_UNITS
       WHERE NAME='OU_US_VPS'
       ;
       
      MO_GLOBAL.SET_POLICY_CONTEXT('S',ln_org_id);
      
    EXCEPTION
    WHEN OTHERS THEN
      error_message := 'Exception in initializing : ' || SQLERRM;
      fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPT_AMOUNTS', 'Unexpected Error: '||error_message );
      RETURN;
    END;
  BEGIN
    FOR I IN
            (SELECT Receipt_number 
                   ,Receipt_date 
                   ,RECEIPT_APPL_DATE as last_update_date
                   ,VPS_Program_ID
                   ,SUM(amount_applied) as Amount_Applied
              FROM XX_FIN_VPS_RECEIPTS_INTERIM
              where  RECEIPT_APPL_DATE > to_date(FROM_DATE,'DD-MON-YYYY HH24:MI:SS')
              GROUP BY Receipt_number 
                      ,Receipt_date 
                      ,RECEIPT_APPL_DATE  
                      ,VPS_Program_ID
            )
    LOOP
      Lv_count                                   := lv_count+1;
      
      l_oa_receipt_obj := XXFIN.XX_FIN_VPS_OA_RECEIPT_OBJ.create_object (
         Receipt_Number   => TO_CHAR(I.Receipt_Number),
         Receipt_Date     => TO_CHAR(I.Receipt_Date,'DD-MON-YYYY HH24:MI:SS'),
         Last_Update_Date => TO_CHAR(I.last_update_date,'DD-MON-YYYY HH24:MI:SS'),
         Program_Id       => TO_CHAR(I.VPS_Program_ID),
         Applied_Amount   => TO_CHAR(I.Amount_Applied)

      );      
      ln_sum := ln_sum + I.Amount_Applied;
      l_oa_receipt_obj_tbl.extend();
      l_oa_receipt_obj_tbl(Lv_count) := l_oa_receipt_obj;
    END LOOP;
    
    l_oa_receipts_obj.receipts_sum := ln_sum;
    l_oa_receipts_obj.receipts_objs := l_oa_receipt_obj_tbl;
    Receipt_Details := XMLTYPE(l_oa_receipts_obj);
    Return_status := 'S';
  EXCEPTION
  WHEN OTHERS THEN
    return_status := 'E';
    error_message := 'While Fetching Receipts : ' || SQLERRM;
    fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPTS', 'Unexpected Error: '||error_message );
    RETURN;
  END;
EXCEPTION
WHEN OTHERS THEN
  return_status := 'E';
  error_message := SUBSTR(sqlerrm,1,200)||'|'||SYSDATE;
  fnd_log.STRING (fnd_log.level_statement, g_pkg_name || 'GET_RECEIPTS', 'Unexpected Error: '||error_message );
END Get_Receipts;
  
END XX_FIN_VPS_OA_RECEIPT_AMOUNTS;
/

