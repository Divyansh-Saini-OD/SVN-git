CREATE OR REPLACE
FUNCTION XX_CS_CLOSE_LOOP_DATE_FORMAT (P_DATE VARCHAR2) 
RETURN DATE AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_CLOSE_LOOP_BPEL_PKG                                |
-- |                                                                   |
-- | Description: Extension for Close the Request based on Mobile cast |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       15-DEC-09   Bala E	   Initial draft version       |
-- |1.1       06-Jun-08   B. Penski        Added New Short Message     |
-- +===================================================================+
--|-------------------------------------------------------------


LC_DATE  cs_incidents_all_b.INCIDENT_ATTRIBUTE_13%TYPE;
LD_DATE DATE ;
LN_LENGTH NUMBER;
lc_slash VARCHAR2(1);
BEGIN
lc_date := P_DATE;
SELECT LENGTH(LC_DATE),SUBSTR(lc_date,3,1) INTO LN_LENGTH,lc_slash FROM DUAL;
IF LN_LENGTH = 9 THEN
SELECT TO_DATE(LC_DATE,'DD-MON-YY') INTO LD_DATE FROM DUAL;
ELSIF  LN_LENGTH = 8 THEN
SELECT TO_DATE(LC_DATE,'DD/MM/YY') INTO LD_DATE FROM DUAL;
ELSIF  LN_LENGTH = 10 THEN
IF lc_slash = '/' THEN
SELECT TO_DATE(LC_DATE,'MM/DD/YYYY') INTO LD_DATE FROM DUAL;
ELSE 
SELECT TO_DATE(LC_DATE,'YYYY/MM/DD') INTO LD_DATE FROM DUAL;
END IF;
ELSIF LN_LENGTH = 11 THEN
SELECT TO_DATE(LC_DATE,'DD-MON-YYYY') INTO LD_DATE FROM DUAL;
ELSIF LN_LENGTH = 18 THEN
SELECT TO_DATE(LC_DATE,'DD-MON-YY HH24:MI:SS') INTO LD_DATE FROM DUAL;
ELSIF LN_LENGTH = 19 THEN
IF lc_slash = '/' THEN
SELECT TO_DATE(LC_DATE,'MM/DD/YYYY HH24:MI:SS') INTO LD_DATE FROM DUAL;
ELSE 
SELECT TO_DATE(LC_DATE,'YYYY/MM/DD HH24:MI:SS') INTO LD_DATE FROM DUAL;
END IF;
ELSIF LN_LENGTH = 20 THEN
SELECT TO_DATE(LC_DATE,'DD-MON-YYYY HH24:MI:SS') INTO LD_DATE FROM DUAL;
END IF;
/*
SELECT 
  TO_DATE('10-JAN-09','DD-MON-YY')
, TO_DATE('10-JAN-2009 00:00:00','DD-MON-YYYY HH24:MI:SS')
, To_DATE('10/01/2009', 'DD/MM/YYYY')
, TO_DATE('10/01/2009 00:00:00','DD/MM/YYYY HH24:MI:SS')
, TO_DATE('01/31/2009', 'MM/DD/YYYY')
, TO_DATE('01/31/2009 00:00:00', 'MM/DD/YYYY HH24:MI:SS')
, TO_DATE('2009/01/10', 'YYYY/MM/DD')
, TO_DATE('2009/01/31 00:00:00', 'YYYY/MM/DD HH24:MI:SS')
, TO_DATE('2009/31/01', 'YYYY/DD/MM')
, TO_DATE('2009/31/01 00:00:00', 'YYYY/DD/MM HH24:MI:SS')
  FROM DUAL;
*/ 

DBMS_OUTPUT.PUT_LINE('DATE:::'||LD_DATE);  
RETURN(LD_DATE);
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('OTHERS:::'||SQLERRM);
END;
/
SHOW ERRORS;
EXIT;