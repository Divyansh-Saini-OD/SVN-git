set define off

DECLARE

v_translate_id NUMBER;

BEGIN

  BEGIN
    SELECT translate_id
      INTO v_translate_id
      FROM XX_FIN_TRANSLATEDEFINITION
     WHERE translation_name='XXFA_CLASS_CATEGORY'
       AND enabled_flag='Y';
  EXCEPTION
    WHEN others THEN
      v_translate_id:=NULL;
      dbms_output.put_line('Translation XXFA_CLASS_CATEGORY not set up');
  END;

  BEGIN
    delete
      FROM xx_fin_translatevalues
     WHERE translate_id = v_translate_id
       AND enabled_flag='Y';
  EXCEPTION
    WHEN others THEN
      v_translate_id:=NULL;
      dbms_output.put_line('Delete for XXFA_CLASS_CATEGORY not executed');
  END;

  IF v_translate_id IS NOT NULL THEN

     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1703','LEASEHOLD IMP','BI','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1706','LEASEHOLD IMP','BI','07 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1710','LEASEHOLD IMP','BI','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1712','LEASEHOLD IMP','BI','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1713','LEASEHOLD IMP','OWNED','07 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1714','LEASEHOLD IMP','OWNED','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1715','BUILDING','OWNED','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1716','LAND','LAND','NONE',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1717','LEASEHOLD IMP','OWNED','15 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1718','LEASEHOLD IMP','OWNED','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1720','F&F','F&F 10 YR','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1721','F&F','F&F 05 YR','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1722','F&F','F&F 10 YR','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1723','F&F','F&F 05 YR','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1724','LEASEHOLD IMP','BI','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1725','SIGNAGE','INT SIGNS','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1727','LEASEHOLD IMP','RELAMP','EXP',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1728','LEASEHOLD IMP','RELAMP','EXP',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1730','M&E','M&E 05','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1731','M&E','M&E 05','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1732','COMPUTER','EQPMT 03','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1733','COMPUTER','EQPMT 03','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1734','M&E','M&E 05','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1735','COMPUTER','EQPMT 05','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1736','SOFTWARE','SW 03','03 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1750','SOFTWARE','SW 03','03 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1752','SOFTWARE','SW 03','03 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1753','SOFTWARE','SW 05','03 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1755','SOFTWARE','SW 03','03 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1762','VEHICLE','AUTO','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '1763','VEHICLE','TRUCK','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '2710','LEASEHOLD IMP','BI','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '2712','LEASEHOLD IMP','BI','39 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '2721','F&F','F&F 05 YR','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '2730','M&E','M&E 05','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '2732','COMPUTER','EQPMT 03','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);
     insert into xx_fin_translatevalues (translate_id,source_value1,target_value1,target_value2,target_value3,creation_date,created_by,last_update_date,last_updated_by,last_update_login,start_date_active,enabled_Flag,translate_value_id)VALUES(v_translate_id, '2733','M&E','M&E 05','05 YR',sysdate,-1,sysdate,-1,-1,sysdate,'Y',XX_FIN_TRANSLATEVALUES_S.nextval);

  END IF;  
  COMMIT;
EXCEPTION
  WHEN others THEN
    dbms_output.put_line('When others :'||SQLERRM);
END;
/
