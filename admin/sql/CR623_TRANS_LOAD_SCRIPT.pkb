delete XX_FIN_TRANSLATEVALUES
where TRANSLATE_ID=38321;
/
declare
  vSFile utl_file.file_type;
  vNewLine VARCHAR2(200);
  ora_acc_num apps.hz_cust_accounts.account_number%TYPE;
  ln_trans_id NUMBER;
  acct        VARCHAR2(30);
  DIS         varchar2(10);
  file_name varchar2(20) := 'CR623.csv';
BEGIN
  SELECT translate_id
  INTO ln_trans_id
  FROM xx_fin_translatedefinition
  WHERE translation_name = 'FLAT_DISCOUNTS';
  vSFile                := utl_file.fopen('XXFIN_INBOUND_SECURE', file_name,'r'); -- need to make directory for the file location
  IF utl_file.is_open(vSFile) THEN
    LOOP
      utl_file.get_line(vSFile, vNewLine);
      IF vNewLine IS NULL THEN
        EXIT;
      ELSE
        ACCT := SUBSTR(vNewLine,1,INSTR(vNewLine,',')-1);
        DIS  := SUBSTR(vNewLine,INSTR(vNewLine,',')  +1);
        BEGIN
          SELECT account_number
          INTO ora_acc_num
          FROM hz_cust_accounts_all
          WHERE orig_system_reference LIKE ACCT
            ||'%';
          INSERT
          INTO xx_fin_translatevalues
            (
              translate_id,
              source_value1,
              target_value1,
              target_value2,
              creation_date,
              created_by,
              last_update_date,
              last_updated_by,
              last_update_login,
              start_date_active,
              enabled_flag,
              translate_value_id
            )
            VALUES
            (
              ln_trans_id,
              ora_acc_num ,
              dis,
              'US_SMALL DOLLAR ADJUSTMENT_OD',
              SYSDATE,
              FND_GLOBAL.USER_ID,
              SYSDATE,
              FND_GLOBAL.USER_ID,
              FND_GLOBAL.LOGIN_ID,
              SYSDATE,
              'Y',
              XX_FIN_TRANSLATEVALUES_S.NEXTVAL
            );
          COMMIT;
        EXCEPTION
        WHEN OTHERS THEN
          NULL;
        END;
      END IF;
    END LOOP;
    utl_file.fclose
    (
      vSFile
    )
    ;
  END IF;
EXCEPTION
WHEN OTHERS THEN
  utl_file.fclose
  (
    vSFile
  )
  ;
END;
/