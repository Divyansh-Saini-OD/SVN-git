declare
  vSFile utl_file.file_type;
  vNewLine VARCHAR2(200);
  file_name varchar2(30) := 'CR623_DISCOUNT_UPDATE.csv';
  TEMP VARCHAR2(200);
  discount_id varchar2(30);
  DIS_DFF        VARCHAR2(30);
  PERCENT         varchar2(10);

BEGIN

  vSFile                := utl_file.fopen('XXFIN_INBOUND_SECURE', file_name,'r'); -- need to make directory for the file location
  IF utl_file.is_open(vSFile) THEN
    LOOP
      utl_file.get_line(vSFile, vNewLine);
      IF vNewLine IS NULL THEN
        EXIT;
      ELSE
        TEMP := vNewLine;

        discount_id := to_number(SUBSTR(TEMP,1,INSTR(TEMP,',')-1));
        TEMP := SUBSTR(TEMP,INSTR(temp,',')+1);

        PERCENT  := SUBSTR(TEMP,1,INSTR(TEMP,',')-1);
        TEMP := SUBSTR(TEMP,INSTR(temp,',')+1);

        DIS_DFF := TEMP;
        BEGIN
      
           UPDATE APPS.RA_TERMS_LINES_DISCOUNTS
              SET DISCOUNT_PERCENT = TO_NUMBER(PERCENT)  
                 ,DISCOUNT_DAYS = NULL
                 ,DISCOUNT_DATE = NULL
                 ,DISCOUNT_DAY_OF_MONTH = 1
                 ,DISCOUNT_MONTHS_FORWARD = 1
                 ,ATTRIBUTE1 = DIS_DFF 
                 ,last_update_date=sysdate
            WHERE TERMs_lines_discount_id = to_number(discount_ID);

           COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
           NULL;
        END;
     END IF;
    END LOOP;
 END IF;
    utl_file.fclose
    (
      vSFile
    )
    ;
EXCEPTION
WHEN OTHERS THEN
  utl_file.fclose
  (
    vSFile
  )
  ;
END;
/