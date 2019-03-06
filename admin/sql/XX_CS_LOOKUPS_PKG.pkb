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
-- +===================================================================+

PROCEDURE Initialize_Line_Object (x_line_rec IN OUT NOCOPY XX_CS_REQ_PRO_REC_TYPE) IS

BEGIN
  x_line_rec := XX_CS_REQ_PRO_REC_TYPE(NULL,NULL,NULL,NULL);

END Initialize_Line_Object;

PROCEDURE REQUEST_TYPES (P_USER_ID IN VARCHAR2,
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
         P_STATUS_TBL(I)            := XX_CS_SR_STATUS_REC(NULL,NULL);
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

/*******************************************************************/

END XX_CS_LOOKUPS_PKG;
/
show errors;
exit;