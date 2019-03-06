create or replace package body XX_CS_CLOSE_LOOP_DATE_PKG  as
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                Office Depot                                         |
-- +=====================================================================+
-- | Name  : XX_CS_CLOSE_LOOP_DATE_PKG                       |
-- | Description  : This package contains procedure that will Converte date |
-- |                                                                     |
-- |Change Record:                                                       |
-- |===============                                                      |
-- |Version    Date          Author           Remarks                    |
-- |=======    ==========    =============    ========================   |
-- |1.0        05-DEC-2009   Bala E   Initial version                    |
-- |                                                                     |
-- +=====================================================================+

FUNCTION XX_CS_CLOSE_LOOP_DATE_FORMAT (P_DATE VARCHAR2) 
RETURN DATE AS

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

--DBMS_OUTPUT.PUT_LINE('DATE:::'||LD_DATE);  
RETURN(LD_DATE);
EXCEPTION
WHEN OTHERS THEN
LD_DATE := NULL;
RETURN (LD_DATE);
--DBMS_OUTPUT.PUT_LINE('OTHERS:::'||SQLERRM);
END;

FUNCTION CLOSE_LOOP_XML_CONVERT( LC_COMMENTS VARCHAR2) 
RETURN VARCHAR2 AS
ln_verify Number:=0;
lc_comments_out VARCHAR2 (32000);
BEGIN
lc_comments_out := lc_comments;

SELECT instr(lc_comments_out,'<') INTO ln_verify FROM dual;
  if ln_verify > 0 then
    select substr(replace(lc_comments_out,'<',' '),1,31990) into lc_comments_out from dual;
  else
    lc_comments_out := substr(lc_comments_out,1,31990);
  End if;
  
SELECT instr(lc_comments_out,'>') INTO ln_verify FROM dual;
  if ln_verify > 0 then
    select substr(replace(lc_comments_out,'>',' '),1,31990) into lc_comments_out from dual;
  else
    lc_comments_out := substr(lc_comments_out,1,31990);  
  End if;  
  
SELECT instr(lc_comments_out,'&') INTO ln_verify FROM dual;
  if ln_verify > 0 then
    select substr(replace(lc_comments_out,'&',' '),31990) into lc_comments_out from dual;
  else
    lc_comments_out := substr(lc_comments_out,1,31990);  
  End if;    
SELECT instr(lc_comments_out,'"') INTO ln_verify FROM dual;
  if ln_verify > 0 then
    select substr(replace(lc_comments_out,'"',' '),1,31990) into lc_comments_out from dual;
  else
    lc_comments_out := substr(lc_comments_out,1,31990);  
  End if;     
SELECT instr(lc_comments_out,'"') INTO ln_verify FROM dual;
  if ln_verify > 0 then
    select substr(replace(lc_comments_out,'''',' '),1,31990) into lc_comments_out from dual;
  else
    lc_comments_out := substr(lc_comments_out,1,31990);  
 End if;     
 RETURN lc_comments_out;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  RETURN lc_comments_out;
WHEN OTHERS THEN
 lc_comments_out := NULL;
RETURN lc_comments_out;

END;
END XX_CS_CLOSE_LOOP_DATE_PKG ;
/
SHOW ERRORS PACKAGE BODY XX_CS_CLOSE_LOOP_DATE_PKG ;
EXIT;
