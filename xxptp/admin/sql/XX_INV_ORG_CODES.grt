--+===============================================================================+--
--|                                                                               |--
--| Object Name    : XX_INV_ORG_CODES.grt		                          |--
--|                                                                               |--
--| Program Name   : XX_INV_ORG_CODES.grt                                         |--        
--|                                                                               |--   
--| Purpose        : Populate org code data in custom table .                     |--
--|                  The Objects created are:                                     |--
--|                                                                               |--
--|                                                                               |-- 
--| Change History  :                                                             |--
--| Ver   Date           Changed By           Description                         |--
--+===============================================================================+--
--| 1.0   01-APR-2008    Ganesh B Nadakudhiti Initial Creation                    |--
--+===============================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Inserting org code data into XX_INV_ORG_CODES 
PROMPT

DECLARE
v_num1 number :=65;
v_num2 number :=65;
b number;
v_code VARCHAR2(20);
BEGIN
 FOR i IN 1..26 LOOP
  FOR J in 1..99 LOOP
   v_code :=CHR(v_num1)||lpad(j,2,0);
   BEGIN
   INSERT into xx_inv_org_codes(sno,org_code,process_flag)
   select xx_inv_org_codes_s.nextval,v_code,'N' from dual;
   EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
     NULL;
   END;
  END LOOP;
  v_num1:=v_num1+1;
 END LOOP;
--
 v_num1:=65;
 v_num2:=65;
 FOR i IN 1..26 LOOP
  FOR j IN 1..26 LOOP
   FOR K in 1..9 LOOP
    v_code :=CHR(v_num1)||CHR(v_num2)||TO_CHAR(k);
    BEGIN
     INSERT into xx_inv_org_codes(sno,org_code,process_flag)
     select xx_inv_org_codes_s.nextval,v_code,'N' from dual;
    EXCEPTION
     WHEN DUP_VAL_ON_INDEX THEN
      NULL;
     WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(v_code);
    END;
   END LOOP;
   v_num2:=v_num2+1;
  END LOOP;
  v_num1 := v_num1+1;
  v_num2 :=65;
 END LOOP;

 --
 v_num1:=65;
 v_num2:=65;
 FOR i IN 1..26 LOOP
  FOR j IN 1..26 LOOP
   FOR K in 1..9 LOOP
    v_code :=CHR(v_num1)||TO_CHAR(k)||CHR(v_num2);
    BEGIN
     INSERT into xx_inv_org_codes(sno,org_code,process_flag)
     select xx_inv_org_codes_s.nextval,v_code,'N' from dual;
    EXCEPTION
     WHEN DUP_VAL_ON_INDEX THEN
      NULL;
     WHEN OTHERS THEN
      DBMS_OUTPUT.put_line(v_code);
    END;
   end loop;
   v_num2:=v_num2+1;
  end loop;
  v_num1 := v_num1+1;
  v_num2 :=65;
 end loop;
 --
 DELETE from xx_inv_org_codes where org_code like 'V%';
 COMMIT;
END;
/
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================