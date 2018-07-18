create or replace
PACKAGE BODY "XX_CS_LOOKUPS_PKG" AS

 -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_LOOKUPS_PKG                                        |
-- | Description: Case Management lookups package                       |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-APR-07   Raj Jagarlamudi  Initial draft version       |
-- |1.1       25-Jan-16   Manikant Kasu	   Removed schema references as|
-- |	    	        					             per GSCC R12.2.2 Compliance.|
-- +===================================================================+

PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_REQ_PRO_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_REQ_PRO_REC_TYPE(NULL,NULL,NULL,NULL);

END Initialize_Line_Object;

PROCEDURE REQUEST_TYPES (P_USER_ID IN VARCHAR2,
                         P_LEVEL IN VARCHAR2,
                         P_RETURN_MESG  IN OUT NOCOPY VARCHAR2,
                         P_REQ_TYPE_TBL IN OUT NOCOPY XX_CS_REQUEST_TBL_TYPE)
IS
CURSOR C1 IS
select incident_type_id request_id,
        name request_type
from cs_incident_types_tl
where  incident_type_id in (
select cb.incident_type_id
from  cs_sr_type_mapping cm,
      cs_incident_types_b cb,
      fnd_responsibility fn
where cm.incident_type_id = cb.incident_type_id
and   fn.responsibility_id = cm.responsibility_id
and   fn.application_id = 514
and   cb.attribute5 like '%'||nvl(p_user_id,cb.attribute5)||'%'
and   nvl(cb.attribute11, 'X') = decode(p_user_id, 'OD_CSR', P_LEVEL, nvl(cb.attribute11,'X'))
and   cb.end_date_active is null);

c1_rec  c1%rowtype;
I       NUMBER := 0;
BEGIN
     I                      := 1;
     P_REQ_TYPE_TBL        := XX_CS_REQUEST_TBL_TYPE();
    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;
      p_req_type_tbl.extend;
      p_req_type_tbl(I) := XX_CS_REQUEST_REC_TYPE(NULL,NULL);

    BEGIN

        P_REQ_TYPE_TBL(I).REQUEST_ID     := C1_REC.REQUEST_ID;
        P_REQ_TYPE_TBL(I).REQUEST_TYPE   := C1_REC.REQUEST_TYPE;

    END;

     I := I + 1;

    END LOOP;
  --  DBMS_OUTPUT.PUT_LINE('COUNT '||P_REQ_TYPE_TBL.COUNT);
    CLOSE C1;
    EXCEPTION
      WHEN OTHERS THEN
         P_RETURN_MESG := SQLERRM;
END;
/***********************************************************/

PROCEDURE PROBLEM_CODES (P_USER_ID IN VARCHAR2,
                         P_REQUEST_ID IN NUMBER,
                         P_RETURN_MESG  IN OUT NOCOPY VARCHAR2,
                         P_PROBLEM_CODE_TBL IN OUT NOCOPY XX_CS_PROBLEMCODE_TBL_TYPE)
IS
CURSOR C1 IS
SELECT D.PROBLEM_CODE,
       C.DESCRIPTION
FROM   CS_SR_PROB_CODE_MAPPING_DETAIL D,
       CS_LOOKUPS C
WHERE  C.LOOKUP_CODE = D.PROBLEM_CODE
AND    D.INCIDENT_TYPE_ID =  P_REQUEST_ID
AND    C.LOOKUP_TYPE = 'REQUEST_PROBLEM_CODE'
AND    C.ENABLED_FLAG = 'Y'
AND    D.END_DATE_ACTIVE IS NULL
AND    C.END_DATE_ACTIVE IS NULL;

c1_rec  c1%rowtype;
I       NUMBER := 0;
BEGIN
   I                      := 1;
     P_PROBLEM_CODE_TBL        := XX_CS_PROBLEMCODE_TBL_TYPE();
    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;
      p_problem_code_tbl.extend;
      p_problem_code_tbl(I) := XX_CS_PROBLECODE_REC_TYPE(NULL,NULL);

    BEGIN

        P_PROBLEM_CODE_TBL(I).PROBLEM_CODE     := C1_REC.PROBLEM_CODE;
        P_PROBLEM_CODE_TBL(I).PROBLEM_DESCR    := C1_REC.DESCRIPTION;

    END;

     I := I + 1;

    END LOOP;
  --  DBMS_OUTPUT.PUT_LINE('COUNT '||P_PROBLEM_CODE_TBL.COUNT);
    CLOSE C1;
    EXCEPTION
      WHEN OTHERS THEN
         P_RETURN_MESG := SQLERRM;
END;
/***********************************************************/

PROCEDURE MAP_TYPE_CODE (P_USER_ID IN VARCHAR2,
                         P_RETURN_MESG  IN OUT NOCOPY VARCHAR2,
                         P_REQ_LINES_TBL IN OUT NOCOPY XX_CS_REQ_PRO_TBL_TYPE)

IS
CURSOR C1 IS
SELECT T.INCIDENT_TYPE_ID REQUEST_ID,
       T.NAME   REQUEST_TYPE,
       M.PROBLEM_CODE PROBLEM_CODE
FROM CS_INCIDENT_TYPES_TL T,
     CS_SR_PROB_CODE_MAPPING_DETAIL M
WHERE M.INCIDENT_TYPE_ID = T.INCIDENT_TYPE_ID;

C1_REC                C1%ROWTYPE;
I                     NUMBER := 0;

BEGIN
     I                      := 1;
     P_REQ_LINES_TBL        := XX_CS_REQ_PRO_TBL_TYPE();
    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;
      p_req_lines_tbl.extend;
      Initialize_Line_Object(p_req_lines_tbl(i));

    BEGIN

        P_REQ_LINES_TBL(I).REQUEST_ID     := C1_REC.REQUEST_ID;
        P_REQ_LINES_TBL(I).REQUEST_TYPE   := C1_REC.REQUEST_TYPE;
        P_REQ_LINES_TBL(I).PROBLEM_CODE   := C1_REC.PROBLEM_CODE;
        P_REQ_LINES_TBL(I).PROBLEM_DESCR  := NULL;
    END;

     I := I + 1;

    END LOOP;
  --  DBMS_OUTPUT.PUT_LINE('COUNT '||P_REQ_LINES_TBL.COUNT);
    CLOSE C1;
    EXCEPTION
      WHEN OTHERS THEN
         P_RETURN_MESG := SQLERRM;
END;
/***********************************************************/
PROCEDURE CHANNEL_LIST (P_RETURN_MESG IN OUT NOCOPY VARCHAR2,
                        P_CHANNEL_TBL IN OUT NOCOPY XX_CS_CHANNEL_TBL)
IS
CURSOR C1 IS
SELECT MEANING
FROM FND_LOOKUP_VALUES_VL
WHERE LOOKUP_TYPE = 'CS_SR_CREATION_CHANNEL';

C1_REC  C1%ROWTYPE;
I       NUMBER;
BEGIN
     I                    := 1;
     P_CHANNEL_TBL        := XX_CS_CHANNEL_TBL();
    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;

    BEGIN
         P_CHANNEL_TBL.EXTEND;
         P_CHANNEL_TBL(I)   := C1_REC.MEANING;

    END;

     I := I + 1;

    END LOOP;
 --   DBMS_OUTPUT.PUT_LINE('COUNT '||P_CHANNEL_TBL.COUNT);
    CLOSE C1;
    EXCEPTION
      WHEN OTHERS THEN
         P_RETURN_MESG := SQLERRM;
END;

/*************************************************************/
PROCEDURE STATUS_LIST (P_RETURN_MESG IN OUT NOCOPY VARCHAR2,
                        P_STATUS_TBL IN OUT NOCOPY XX_CS_SR_STATUS_TBL)
IS
CURSOR C1 IS
SELECT NAME, INCIDENT_STATUS_ID
FROM CS_INCIDENT_STATUSES_VL
WHERE INCIDENT_SUBTYPE = 'INC'
AND Name IN ('Open','Closed','Cancelled');

C1_REC  C1%ROWTYPE;
I       NUMBER;

BEGIN
     I                    := 1;
     P_STATUS_TBL         := XX_CS_SR_STATUS_TBL();
    OPEN C1;
    LOOP
    FETCH C1 INTO C1_REC;
    EXIT WHEN C1%NOTFOUND;

    BEGIN
         P_STATUS_TBL.EXTEND;
         P_STATUS_TBL(I)           := XX_CS_SR_STATUS_REC(NULL,NULL);
         P_STATUS_TBL(I).STATUS    := C1_REC.NAME;
         P_STATUS_TBL(I).STATUS_ID := C1_REC.INCIDENT_STATUS_ID;

    END;

     I := I + 1;

    END LOOP;
   -- DBMS_OUTPUT.PUT_LINE('COUNT '||P_STATUS_TBL.COUNT);
    CLOSE C1;
    EXCEPTION
      WHEN OTHERS THEN
         P_RETURN_MESG := SQLERRM;
END;
/*******************************************************************************/
PROCEDURE MPS_DEVICES (P_SERIAL_NO      IN VARCHAR2,
                       X_CUST_NO        IN OUT NOCOPY NUMBER,
                       X_ORDER_NO       IN OUT NOCOPY VARCHAR2,
                       X_CUST_TYPE      IN OUT NOCOPY VARCHAR2,
                       X_RETURN_STATUS  OUT NOCOPY VARCHAR2,
                       X_RETURN_MESG    OUT NOCOPY VARCHAR2)
IS
LC_REQUEST_NUMBER   VARCHAR2(50);
LN_PARTY_ID         NUMBER;
BEGIN
   x_return_status := 'S';

   BEGIN
      SELECT DISTINCT AOPS_CUST_NUMBER,
             DECODE(ESSENTIALS_ATR_FLAG,'Y','ATR','MPS') CUST_TYPE,
             PARTY_ID
      INTO X_CUST_NO,
          X_CUST_TYPE,
          LN_PARTY_ID
      FROM XX_CS_MPS_DEVICE_B
      WHERE SERIAL_NO = UPPER(P_SERIAL_NO);
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
          X_RETURN_STATUS := 'F';
          X_RETURN_MESG   := 'not a valid serial number';
       WHEN OTHERS THEN
          X_RETURN_STATUS := 'F';
          X_RETURN_MESG   := 'Error while validating Serial no '||p_serial_no;
    END;

  IF X_CUST_NO IS NOT NULL THEN

   BEGIN
     SELECT MD.TONER_ORDER_NUMBER,
            MD.REQUEST_NUMBER
      INTO  X_ORDER_NO,
            LC_REQUEST_NUMBER
      FROM XX_CS_MPS_DEVICE_DETAILS MD
      WHERE MD.SERIAL_NO = UPPER(P_SERIAL_NO)
      AND MD.SUPPLIES_LABEL <> 'USAGE'
      AND MD.REQUEST_NUMBER IS NOT NULL
      AND   ROWNUM <2
      ORDER BY MD.TONER_ORDER_DATE DESC;
    EXCEPTION
       WHEN OTHERS THEN
          NULL;
    END;


    IF X_ORDER_NO IS NULL THEN

      BEGIN
       select cb.incident_attribute_1 order_no
       into x_order_no
        from cs_incidents_all_b cb,
             cs_incident_types_tl ct
        where ct.incident_type_id = cb.incident_type_id
        and  ct.name = 'MPS Supplies Request'
        and  cb.customer_id = ln_party_id
        and cb.incident_attribute_3 = upper(p_serial_no)
        and cb.incident_attribute_1 is not null
        and rownum < 2
        order by cb.creation_date desc;
      EXCEPTION
        WHEN OTHERS THEN
           X_RETURN_STATUS := 'S';
            X_RETURN_MESG   := 'No orders placed for this Serial#'||P_SERIAL_NO;
      END;

    END IF;

  END IF;
  dbms_output.put_line('cust no '||x_cust_no||' '||x_order_no);
END;
/*******************************************************************************/

END XX_CS_LOOKUPS_PKG;
/
show errors;
exit;