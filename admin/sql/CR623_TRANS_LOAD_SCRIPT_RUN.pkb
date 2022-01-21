Create or replace procedure XX_READ_TRANS_VALUES(FILE_NAME varchar2) 
IS
 vSFile   utl_file.file_type;
 vNewLine VARCHAR2(200);
 
  ln_hyp_cnt  NUMBER;
  lc_temp_txt VARCHAR2(2000) ;
  ln_acc_num apps.hz_cust_accounts.account_number%TYPE;
  ln_trans_id number;

 TYPE coln_values_type
IS
  TABLE OF VARCHAR2(100); 
  lt_coln_values coln_values_type;
    
  begin
  DBMS_OUTPUT.PUT_LINE('test1');
  --VSFILE := UTL_FILE.FOPEN('/app/ebs/ctgsidev01/xxfin/inbound/secure/', FILE_NAME,'r'); -- need to make directory for the file location
    vSFile := utl_file.fopen('XXFIN_INBOUND_SECURE', file_name,'r'); -- need to make directory for the file location

  IF utl_file.is_open(vSFile) THEN
    LOOP
      BEGIN
        utl_file.get_line(vSFile, vNewLine);

        IF vNewLine IS NULL THEN
          EXIT;
        END IF;
        dbms_output.put_line(vNewLine);
        
        BEGIN
        ln_hyp_cnt     := LENGTH(vNewLine)-LENGTH(REPLACE(vNewLine,',',''));
        lt_coln_values := coln_values_type(NULL);
        lc_temp_txt :=vNewLine;
        FOR i          IN 1..ln_hyp_cnt
        LOOP
          lt_coln_values.extend;
          lt_coln_values(i) := SUBSTR(lc_temp_txt,1,INSTR(lc_temp_txt,',')-1);
          lc_temp_txt       := SUBSTR(lc_temp_txt,INSTR(lc_temp_txt,',')  +1);
          dbms_output.put_line(lt_coln_values(i));
        END LOOP;
        lt_coln_values(ln_hyp_cnt+1) := lc_temp_txt;
        dbms_output.put_line(lt_coln_values(ln_hyp_cnt+1));
        END;
        
        BEGIN
        
        -- To find account number
        select  nvl(account_number,0) into ln_acc_num from apps.hz_cust_accounts where orig_system_reference like lt_coln_values(1)||'%';
        
        dbms_output.put_line(ln_acc_num);

       EXCEPTION
      when NO_DATA_FOUND then
        DBMS_OUTPUT.PUT_LINE('Oracle Account not found for = '||LT_COLN_VALUES(1)); 
        ln_acc_num:=0;
        END;
        
        -- get translate id
       BEGIN 
        select translate_id into ln_trans_id from xx_fin_translatedefinition where 
        translation_name = 'FLAT_DISCOUNTS';
        
        dbms_output.put_line(ln_trans_id); 
        
        -- To insert into translation values
       if  ln_acc_num <> 0 then
        INSERT into xx_fin_translatevalues (translate_id, source_value1, target_value1, target_value2, creation_date, created_by, 
                                           last_update_date, last_updated_by, last_update_login, start_date_active, enabled_flag, translate_value_id)
                          values     (   ln_trans_id, ln_acc_num,lt_coln_values(2),'US_SMALL DOLLAR ADJUSTMENT_OD',SYSDATE,
                                          FND_GLOBAL.USER_ID,SYSDATE,FND_GLOBAL.USER_ID,FND_GLOBAL.LOGIN_ID,SYSDATE,'Y',XX_FIN_TRANSLATEVALUES_S.NEXTVAL);
                                          
         commit;
         end if;
             
        EXCEPTION when OTHERS then
        dbms_output.put_line('error');
        end;
        
        
        --  EXIT;
         END;
    END LOOP;
    COMMIT;
  END IF;
  utl_file.fclose(vSFile);
EXCEPTION
  WHEN utl_file.invalid_mode THEN
    RAISE_APPLICATION_ERROR (-20051, 'Invalid Mode Parameter');
  WHEN utl_file.invalid_path THEN
    RAISE_APPLICATION_ERROR (-20052, 'Invalid File Location');
  WHEN utl_file.invalid_filehandle THEN
    RAISE_APPLICATION_ERROR (-20053, 'Invalid Filehandle');
  WHEN utl_file.invalid_operation THEN
    RAISE_APPLICATION_ERROR (-20054, 'Invalid Operation');
  WHEN utl_file.read_error THEN
    RAISE_APPLICATION_ERROR (-20055, 'Read Error');
  WHEN utl_file.internal_error THEN
    RAISE_APPLICATION_ERROR (-20057, 'Internal Error');
  WHEN utl_file.charsetmismatch THEN
    RAISE_APPLICATION_ERROR (-20058, 'Opened With FOPEN_NCHAR
    But Later I/O Inconsistent');
  WHEN utl_file.file_open THEN
    RAISE_APPLICATION_ERROR (-20059, 'File Already Opened');
  WHEN utl_file.invalid_maxlinesize THEN
    RAISE_APPLICATION_ERROR(-20060,'Line Size Exceeds 32K');
  WHEN utl_file.invalid_filename THEN
    RAISE_APPLICATION_ERROR (-20061, 'Invalid File Name');
  WHEN utl_file.access_denied THEN
    RAISE_APPLICATION_ERROR (-20062, 'File Access Denied By');
  WHEN utl_file.invalid_offset THEN
    RAISE_APPLICATION_ERROR (-20063,'FSEEK Param Less Than 0');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR (-20099, 'Unknown UTL_FILE Error');
end;
/
