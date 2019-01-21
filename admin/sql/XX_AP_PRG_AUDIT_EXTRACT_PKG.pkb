SET VERIFY OFF
SET ECHO OFF
SET FEEDBACK OFF
SET TERM ON
PROMPT Creating PACKAGE  BODY XX_AP_PRG_AUDIT_EXTRACT_PKG
PROMPT Program exits IF the creation IS NOT SUCCESSFUL
WHENEVER SQLERROR CONTINUE


create or replace 
PACKAGE BODY XX_AP_PRG_AUDIT_EXTRACT_PKG
AS
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                                                 |
  -- +==================================================================================================+
  -- | Name             :  XX_AP_AUDIT_EXTRACT_PKG                                                      |
  -- | Description      :  This Package is used to Extract Audit data requested from PRG.               |
  -- | RICE id          :  I1142                                                                        |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date          Author          Remarks                                                   |
  -- |=======   ==========    =============   ==========================================================|
  -- | 1.0      27-OCT-2010   Lenny Lee       Initial programming.                                      |
  -- | 1.1      21-JUL-2011   Lenny Lee       Defect# 12694  modify local variable l_description to     |
  -- |                                        varchar2(240).                                            |
  -- | 1.2      22-Jul-2013   Paddy Sanjeevi  Modified for R12                                          |
  -- | 1.3      24-Jan-2014   Paddy Sanjeevi  Modified for defect 27400                                 |
  -- | 1.4      27-JAN-2014   Deepak V        Defect# 27400                                             |
  -- | 1.5      03-Feb-2014   Paddy Sanjeevi  Defect# 27400                                             |
  -- | 1.6      25-AUG-2014   Madhan Sanjeevi Defect# 31315, 31345                                      |
  -- | 1.7      04-NOV-2015   Harvinder Rkahra Retroffit R12.2                                          |
  ---| 1.8      07-AUG-2018   Priyam Parmar   DEFECT # 49742  CSI Sales Extract                         |
  ---| 1.9      14-AUG-2018   Jitendra Atale  DEFECT # NAIT-53790 for AP_INVOICES_LINES_ALL Extract     |
  ---|                                        DEFECT # NAIT-53791 for MTL_SYSTEMS_ITEMS_B Extract       |
  ---| 2.0      10-SEP-2018   Jitendra Atale  DEFECT # NAIT-56507 for CSISALEs Extract Name change       |
  ---| 2.1      10-SEP-2018   Priyam Parmar   DEFECT # NAIT-59122 for XX_AP_RTV_HDR_ATTR and XX_AP_RTV_LINES_ATTR |
  ---| 2.2     01-OCT-2018   Priyam Parmar   DEFECT # NAIT-56507 for CSISALEs MSDE column and CONSIGN_FLAG=Y       |
  ---| 2.3     11-OCT-2018   Ragni Gupta      DEFECT # NAIT-56507 for CSISALEs Quantity column is multiplied with sign       |
  -- +==================================================================================================+
  gc_file_path VARCHAR2(500) := 'XXFIN_OUTBOUND';
PROCEDURE write_log(
    p_debug_flag VARCHAR2,
    p_msg        VARCHAR2)
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                                                 |
  -- +==================================================================================================+
  -- | Name             :  write_log                                          |
  -- | Description      :  This procedure is used to write in to log file based on the debug flag       |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date         Author            Remarks                                       |
  -- |=======   ==========   =============    =====================================================|
  -- |                                                                                                  |
  -- +==================================================================================================+
AS
BEGIN
  IF(p_debug_flag = 'Y') THEN
    fnd_file.put_line(FND_FILE.LOG,p_msg);
  END IF;
END;
-- Added get_contact_alt_name for Defect 27400
FUNCTION get_contact_alt_name(
    p_rel_id IN NUMBER)
  RETURN VARCHAR2
IS
  V_contact_name VARCHAR2(240);
BEGIN
  SELECT c.known_as
  INTO v_contact_name
  FROM hz_parties c,
    hz_relationships b
  WHERE b.relationship_id=p_rel_id
  AND b.directional_flag ='F'
  AND b.relationship_code='CONTACT_OF'
  AND c.party_id         =b.subject_id;
  RETURN(v_contact_name);
EXCEPTION
WHEN OTHERS THEN
  v_contact_name:=NULL;
END;
PROCEDURE generate_file(
    p_directory  VARCHAR2 ,
    p_file_name  VARCHAR2 ,
    p_request_id NUMBER)
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                               |
  -- +==================================================================================================+
  -- | Name             :  generate_file                                                   |
  -- | Description      :  This procedure is used to generate a output extract file and it calls XPTR   |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date         Author            Remarks                                               |
  -- |=======   ==========   =============
  --=======================================================|
AS
  ln_req_id          NUMBER;
  lc_source_dir_path VARCHAR2(4000);
  lc_archive_dir     VARCHAR2(200);
  lc_file_name       VARCHAR2(200);
BEGIN
  BEGIN
    SELECT directory_path
    INTO lc_source_dir_path
    FROM dba_directories
    WHERE directory_name = gc_file_path;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path '|| SQLERRM);
  END;
  lc_file_name:=p_file_name||'_'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Path:'||lc_source_dir_path||'   Directory:'||p_directory||'   File Name:'||lc_file_name);
  ln_req_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPYREP' ,'' ,'' ,FALSE ,lc_source_dir_path||'/'||p_request_id||'.out' ,p_directory||'/'||lc_file_name ,'','','','',p_request_id,'','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','') ;
  --- copy file to Archive file
  lc_archive_dir:='$XXFIN_ARCHIVE';
  ln_req_id     :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPYREP' ,'' ,'' ,FALSE ,lc_source_dir_path||'/'||p_request_id||'.out' ,lc_archive_dir||'/'||lc_file_name ,'','','','',p_request_id,'','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','') ;
END;
---  **************************************************
PROCEDURE gen_sumry_file(
    p_directory  VARCHAR2 ,
    p_file_name  VARCHAR2 ,
    p_request_id NUMBER)
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                               |
  -- +==================================================================================================+
  -- | Name             :  gen_sumry_file                                                   |
  -- | Description      :  This procedure is used to generate a output summary file and it calls XPTR   |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date         Author            Remarks                                               |
  -- |=======   ==========   =============
  --=======================================================|
AS
  ln_req_id          NUMBER;
  lc_source_dir_path VARCHAR2(4000);
  lc_summry_dir      VARCHAR2(200);
  lc_file_name       VARCHAR2(200);
BEGIN
  BEGIN
    SELECT directory_path
    INTO lc_source_dir_path
    FROM dba_directories
    WHERE directory_name = gc_file_path;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path '|| SQLERRM);
  END;
  lc_file_name:='OD_AP_PRG_SUMMARY.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Summary Path:'||lc_source_dir_path||'   Directory:'||p_directory||'   File Name:'||lc_file_name);
  ln_req_id    :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPYREP' ,'' ,'' ,FALSE ,lc_source_dir_path||'/'||'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD') ,p_directory||'/'||lc_file_name ,'','','','',p_request_id,'','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','') ;
  lc_summry_dir:='$XXFIN_DATA/ftp/out/prg';
  ln_req_id    :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPYREP' ,'' ,'' ,FALSE ,lc_source_dir_path||'/'||'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD') ,lc_summry_dir||'/'||lc_file_name ,'','','','',p_request_id,'','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','') ;
  lc_summry_dir:='$XXFIN_DATA/archive';
  ln_req_id    :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPYREP' ,'' ,'' ,FALSE ,lc_source_dir_path||'/'||'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD') ,lc_summry_dir||'/'||lc_file_name ,'','','','',p_request_id,'','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','','','','','','','' ,'','','','','','','','','','','','','','','','') ;
END;
-- *******************************************************************************************
---  **************************************************
PROCEDURE zip_file(
    p_directory  VARCHAR2 ,
    p_file_name  VARCHAR2 ,
    p_request_id NUMBER)
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                                                 |
  -- +==================================================================================================+
  -- | Name             :  zip_file                                                                   |
  -- | Description      :  This procedure is used to zip file                                           |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date         Author            Remarks                                                 |
  -- |=======   ==========   =============
  --====================================================================================================|
AS
  ln_req_id              NUMBER;
  lc_source_dir_path     VARCHAR2(4000);
  lc_zip_destination_dir VARCHAR2(4000);
  ln_buffer BINARY_INTEGER := 32767;
  lc_file_name       VARCHAR2(200);
  lc_summry_filename VARCHAR2(200);
  lt_file utl_file.file_type;
BEGIN
  BEGIN
    SELECT directory_path
    INTO lc_source_dir_path
    FROM dba_directories
    WHERE directory_name = gc_file_path;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while getting directory path '|| SQLERRM);
  END;
  -- delay 3 minutes to ensure all copying files routines are done before zipping.
  DBMS_LOCK.sleep(180);
  lc_zip_destination_dir:='$XXFIN_DATA/ftp/out/prg';
  ln_req_id             :=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXODDIRZIP' ,'' ,'' ,FALSE ,p_directory ,lc_zip_destination_dir||'/OD_AP_PRG_ZIP_'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS') ) ;
  --  clear summary work file content
  lc_summry_filename:= 'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD');
  lt_file           := UTL_FILE.fopen(gc_file_path,lc_summry_filename ,'w',ln_buffer);
END;
PROCEDURE get_cutoff_date(
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2 ,
    p_start_date OUT DATE ,
    p_end_date OUT DATE ,
    p_debug_flag IN VARCHAR2)
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                                                 |
  -- +==================================================================================================+
  -- | Name             :  get_cutoff_period                                                        |
  -- | Description      :  This procedure is get period when parameter periods are null                 |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date         Author            Remarks                                                 |
  -- |=======   ==========   =============    =========================================================|
  -- |
  -- +==================================================================================================+
AS
  l_cutoff_date   DATE;
  l_no_of_days    NUMBER;
  ld_start_date   DATE;
  ld_end_date     DATE;
  l_created       DATE;
  l_last_compiled VARCHAR2(30);
  l_status        VARCHAR2(20);
  l_system_date   DATE;
BEGIN
  SELECT TIMESTAMP,
    status,
    created
  INTO l_last_compiled,
    l_status,
    l_created
  FROM dba_objects
  WHERE object_type = 'PACKAGE BODY'
  AND object_name   = 'XX_AP_PRG_AUDIT_EXTRACT_PKG';
  write_log(p_debug_flag,' ');
  write_log(p_debug_flag,'Package XX_AP_PRG_AUDIT_EXTRACT_PKG --->  created:'||l_created||'   last_DDL_time:'||l_last_compiled ||'   Status:'||l_status);
  write_log(p_debug_flag,' ');
  SELECT sysdate
  INTO l_system_date
  FROM DUAL;
  write_log(p_debug_flag,'System Date: '||l_system_date);
  write_log(p_debug_flag,' ');
  write_log(p_debug_flag,'p_cutoff_date: '||p_cutoff_date);
  --------------  get previous period name ---------------------
  IF p_cutoff_date IS NULL THEN
    ld_end_date    :=l_system_date;
    write_log(p_debug_flag,ld_end_date||' Cutoff Date from System');
  ELSE
    ld_end_date:=TRUNC(TO_DATE(p_cutoff_date,'YYYY/MM/DD HH24:MI:SS'));
    write_log(p_debug_flag,ld_end_date||' Cutoff Date from Parameter');
  END IF;
  IF p_no_of_days IS NULL THEN
    l_no_of_days  :=7;
    write_log(p_debug_flag,l_no_of_days||' Default number of days');
  ELSE
    l_no_of_days:=TO_NUMBER(p_no_of_days,'9999');
    write_log(p_debug_flag,l_no_of_days||' Number of days from Parameter');
  End If;
  IF p_no_of_days > 30 THEN
    write_log(p_debug_flag,l_no_of_days||' exceeds 30 days; force to 30 days');
    l_no_of_days:=30;
  END IF;
  ld_start_date:=ld_end_date - l_no_of_days + 1;
  write_log(p_debug_flag,ld_start_date||' Begin Date ');
  write_log(p_debug_flag,ld_end_date||' End Date');
  p_end_date  :=ld_end_date;
  p_start_date:=ld_start_date;
END;
PROCEDURE replace_control_char(
    l_data IN OUT VARCHAR2)
  -- +==================================================================================================+
  -- |                  Office Depot - Project Simplify                                                 |
  -- |                  IT Office Depot                                                                 |
  -- +==================================================================================================+
  -- | Name             :  replace_control_char                                                      |
  -- | Description      :  This procedure is replace control characters by a space.                     |
  -- |                                                                                                  |
  -- |Change Record:                                                                                    |
  -- |===============                                                                                   |
  -- |Version   Date         Author            Remarks                                                 |
  -- |=======   ==========   =============    =========================================================|
  -- |
  -- +==================================================================================================+
AS
  --l_data VARCHAR2(4000);
  l_idx NUMBER;
BEGIN
  FOR l_idx IN 1..31
  LOOP
    l_data:=REPLACE(l_data,CHR(l_idx),' ');
  END LOOP;
END;
-- +===============  Extract # 1  ====================================================================+
PROCEDURE Extract_ap_terms_tl(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 :='OD_AP_PRG_ap_terms_tl.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_terms_tl                                                 |
  -- | Description      : This procedure is used to extract ap_terms_tl                                  |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data             VARCHAR2(4000);
  l_period_name      VARCHAR2(30);
  l_out_cnt          NUMBER;
  lc_filename        VARCHAR2(4000);
  lc_summry_filename VARCHAR2(4000);
  ln_req_id          NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  ln_req_id    := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename  := ln_req_id||'.out';
  lt_file      := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data       :='term_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'NAME' ||'|'||'ENABLED_FLAG' ||'|'||'DUE_CUTOFF_DAY' ||'|'||'DESCRIPTION' ||'|'||'TYPE' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'RANK' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'LANGUAGE' ||'|'||'SOURCE_LANG' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR att_Cur IN
    (SELECT TERM_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      NAME ,
      ENABLED_FLAG ,
      DUE_CUTOFF_DAY ,
      DESCRIPTION ,
      TYPE ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      RANK ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      LANGUAGE ,
      SOURCE_LANG
    FROM ap_terms_tl
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=att_Cur.term_id ||'|'||att_CUR.LAST_UPDATE_DATE ||'|'||att_CUR.LAST_UPDATED_BY ||'|'||att_CUR.CREATION_DATE ||'|'||att_CUR.CREATED_BY ||'|'||att_CUR.LAST_UPDATE_LOGIN ||'|'||att_CUR.NAME ||'|'||att_CUR.ENABLED_FLAG ||'|'||att_CUR.DUE_CUTOFF_DAY ||'|'||att_CUR.DESCRIPTION ||'|'||att_CUR.TYPE ||'|'||att_CUR.START_DATE_ACTIVE ||'|'||att_CUR.END_DATE_ACTIVE ||'|'||att_CUR.RANK ||'|'||att_CUR.ATTRIBUTE_CATEGORY ||'|'||att_CUR.ATTRIBUTE1 ||'|'||att_CUR.ATTRIBUTE2 ||'|'||att_CUR.ATTRIBUTE3 ||'|'||att_CUR.ATTRIBUTE4 ||'|'||att_CUR.ATTRIBUTE5 ||'|'||att_CUR.ATTRIBUTE6 ||'|'||att_CUR.ATTRIBUTE7 ||'|'||att_CUR.ATTRIBUTE8 ||'|'||att_CUR.ATTRIBUTE9 ||'|'||att_CUR.ATTRIBUTE10 ||'|'||att_CUR.ATTRIBUTE11 ||'|'||att_CUR.ATTRIBUTE12 ||'|'||att_CUR.ATTRIBUTE13 ||'|'||att_CUR.ATTRIBUTE14 ||'|'||att_CUR.ATTRIBUTE15 ||'|'||att_CUR.LANGUAGE ||'|'||att_CUR.SOURCE_LANG ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_terms_tl = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_terms_tl');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    --  open summary work file for appending
    lc_summry_filename:= 'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD');
    lt_file           := UTL_FILE.fopen(gc_file_path,lc_summry_filename ,'a',ln_buffer);
    l_data            :='total record count in ap_terms_tl =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_terms_tl;
-- +===================================================================================================+
-- +================   Extract # 2   ===================================================================+
PROCEDURE Extract_ap_terms_lines(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_ap_terms_lines.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_terms_lines                                                 |
  -- | Description      : This procedure is used to extract ap_terms_lines                                  |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data              VARCHAR2(4000);
  l_file_name         VARCHAR2(100);
  l_period_name_begin VARCHAR2(30);
  l_period_name_end   VARCHAR2(30);
  l_out_cnt           NUMBER;
  lc_filename         VARCHAR2(4000);
  lc_summry_filename  VARCHAR2(4000);
  ln_req_id           NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='term_id' ||'|'||'SEQUENCE_NUM' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'DUE_PERCENT' ||'|'||'DUE_AMOUNT' ||'|'||'DUE_DAYS' ||'|'||'DUE_DAY_OF_MONTH' ||'|'||'DUE_MONTHS_FORWARD' ||'|'||'DISCOUNT_PERCENT' ||'|'||'DISCOUNT_DAYS' ||'|'||'DISCOUNT_DAY_OF_MONTH' ||'|'||'DISCOUNT_MONTHS_FORWARD' ||'|'||'DISCOUNT_PERCENT_2' ||'|'||'DISCOUNT_DAYS_2' ||'|'||'DISCOUNT_DAY_OF_MONTH_2' ||'|'||'DISCOUNT_MONTHS_FORWARD_2' ||'|'||'DISCOUNT_PERCENT_3' ||'|'||'DISCOUNT_DAYS_3' ||'|'||'DISCOUNT_DAY_OF_MONTH_3' ||'|'||'DISCOUNT_MONTHS_FORWARD_3' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'FIXED_DATE' ||'|'||
  'CALENDAR' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR atl_Cur IN
    (SELECT TERM_ID ,
      SEQUENCE_NUM ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      DUE_PERCENT ,
      DUE_AMOUNT ,
      DUE_DAYS ,
      DUE_DAY_OF_MONTH ,
      DUE_MONTHS_FORWARD ,
      DISCOUNT_PERCENT ,
      DISCOUNT_DAYS ,
      DISCOUNT_DAY_OF_MONTH ,
      DISCOUNT_MONTHS_FORWARD ,
      DISCOUNT_PERCENT_2 ,
      DISCOUNT_DAYS_2 ,
      DISCOUNT_DAY_OF_MONTH_2 ,
      DISCOUNT_MONTHS_FORWARD_2 ,
      DISCOUNT_PERCENT_3 ,
      DISCOUNT_DAYS_3 ,
      DISCOUNT_DAY_OF_MONTH_3 ,
      DISCOUNT_MONTHS_FORWARD_3 ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      FIXED_DATE ,
      CALENDAR
    FROM ap_terms_lines
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=atl_Cur.term_id ||'|'||atl_Cur.SEQUENCE_NUM ||'|'||atl_Cur.LAST_UPDATE_DATE ||'|'||atl_Cur.LAST_UPDATED_BY ||'|'||atl_Cur.CREATION_DATE ||'|'||atl_Cur.CREATED_BY ||'|'||atl_Cur.LAST_UPDATE_LOGIN ||'|'||atl_Cur.DUE_PERCENT ||'|'||atl_Cur.DUE_AMOUNT ||'|'||atl_Cur.DUE_DAYS ||'|'||atl_Cur.DUE_DAY_OF_MONTH ||'|'||atl_Cur.DUE_MONTHS_FORWARD ||'|'||atl_Cur.DISCOUNT_PERCENT ||'|'||atl_Cur.DISCOUNT_DAYS ||'|'||atl_Cur.DISCOUNT_DAY_OF_MONTH ||'|'||atl_Cur.DISCOUNT_MONTHS_FORWARD ||'|'||atl_Cur.DISCOUNT_PERCENT_2 ||'|'||atl_Cur.DISCOUNT_DAYS_2 ||'|'||atl_Cur.DISCOUNT_DAY_OF_MONTH_2 ||'|'||atl_Cur.DISCOUNT_MONTHS_FORWARD_2 ||'|'||atl_Cur.DISCOUNT_PERCENT_3 ||'|'||atl_Cur.DISCOUNT_DAYS_3 ||'|'||atl_Cur.DISCOUNT_DAY_OF_MONTH_3 ||'|'||atl_Cur.DISCOUNT_MONTHS_FORWARD_3 ||'|'||atl_Cur.ATTRIBUTE_CATEGORY ||'|'||atl_Cur.ATTRIBUTE1 ||'|'||atl_Cur.ATTRIBUTE2 ||'|'||atl_Cur.ATTRIBUTE3 ||'|'||atl_Cur.ATTRIBUTE4 ||'|'||atl_Cur.ATTRIBUTE5 ||'|'||atl_Cur.ATTRIBUTE6 ||'|'||atl_Cur.ATTRIBUTE7 ||
      '|'||atl_Cur.ATTRIBUTE8 ||'|'||atl_Cur.ATTRIBUTE9 ||'|'||atl_Cur.ATTRIBUTE10 ||'|'||atl_Cur.ATTRIBUTE11 ||'|'||atl_Cur.ATTRIBUTE12 ||'|'||atl_Cur.ATTRIBUTE13 ||'|'||atl_Cur.ATTRIBUTE14 ||'|'||atl_Cur.ATTRIBUTE15 ||'|'||atl_Cur.FIXED_DATE ||'|'||atl_Cur.CALENDAR ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_terms_lines = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_terms_lines');
    write_log(p_debug_flag,' FILE NAME: '||lc_filename);
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lc_summry_filename:= 'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD');
    lt_file           := UTL_FILE.fopen(gc_file_path,lc_summry_filename ,'a',ln_buffer);
    l_data            :='total record count in ap_terms_lines =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_terms_lines;
-- +===================================================================================================+
-- +================   Extract # 3   ===================================================================+
PROCEDURE Extract_ap_check_stocks_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_ap_check_stocks_all.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_check_stocks_all                                                 |
  -- | Description      : This procedure is used to extract ap_check_stocks_all                                  |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data              VARCHAR2(4000);
  l_period_name_begin VARCHAR2(30);
  l_period_name_end   VARCHAR2(30);
  l_out_cnt           NUMBER;
  lc_filename         VARCHAR2(4000);
  lc_summry_filename  VARCHAR2(4000);
  ln_req_id           NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     := 'PAYMENT_DOCUMENT_ID' ||'|'||'PAYMENT_DOC_CATEGORY' ||'|'||'PAYMENT_DOCUMENT_NAME' ||'|'||'PAYMENT_INSTRUCTION_ID' ||'|'||'INTERNAL_BANK_ACCOUNT_ID' ||'|'||'PAPER_STOCK_TYPE' ||'|'||'ATTACHED_REMITTANCE_STUB_FLAG' ||'|'||'NUMBER_OF_LINES_PER_REMIT_STUB' ||'|'||'NUMBER_OF_SETUP_DOCUMENTS' ||'|'||'FORMAT_CODE' ||'|'||'FIRST_AVAILABLE_DOCUMENT_NUM' ||'|'||'LAST_AVAILABLE_DOCUMENT_NUMBER' ||'|'||'LAST_ISSUED_DOCUMENT_NUMBER' ||'|'||'MANUAL_PAYMENTS_ONLY_FLAG' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'INACTIVE_DATE' ||'|'||'CREATED_BY' ||'|'||'CREATION_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'OBJECT_VERSION_NUMBER' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR acsa_Cur IN
    (SELECT PAYMENT_DOCUMENT_ID,
      PAYMENT_DOC_CATEGORY,
      PAYMENT_DOCUMENT_NAME,
      PAYMENT_INSTRUCTION_ID,
      INTERNAL_BANK_ACCOUNT_ID,
      PAPER_STOCK_TYPE,
      ATTACHED_REMITTANCE_STUB_FLAG,
      NUMBER_OF_LINES_PER_REMIT_STUB,
      NUMBER_OF_SETUP_DOCUMENTS,
      FORMAT_CODE,
      FIRST_AVAILABLE_DOCUMENT_NUM,
      LAST_AVAILABLE_DOCUMENT_NUMBER,
      LAST_ISSUED_DOCUMENT_NUMBER,
      MANUAL_PAYMENTS_ONLY_FLAG,
      ATTRIBUTE_CATEGORY,
      ATTRIBUTE1,
      ATTRIBUTE2,
      ATTRIBUTE3,
      ATTRIBUTE4,
      ATTRIBUTE5,
      ATTRIBUTE6,
      ATTRIBUTE7,
      ATTRIBUTE8,
      ATTRIBUTE9,
      ATTRIBUTE10,
      ATTRIBUTE11,
      ATTRIBUTE12,
      ATTRIBUTE13,
      ATTRIBUTE14,
      ATTRIBUTE15,
      INACTIVE_DATE,
      CREATED_BY,
      CREATION_DATE,
      LAST_UPDATED_BY,
      LAST_UPDATE_DATE,
      LAST_UPDATE_LOGIN,
      OBJECT_VERSION_NUMBER
    FROM ce_payment_documents
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=acsa_cur.PAYMENT_DOCUMENT_ID ||'|'||acsa_cur.PAYMENT_DOC_CATEGORY ||'|'||acsa_cur.PAYMENT_DOCUMENT_NAME ||'|'||acsa_cur.PAYMENT_INSTRUCTION_ID ||'|'||acsa_cur.INTERNAL_BANK_ACCOUNT_ID ||'|'||acsa_cur.PAPER_STOCK_TYPE ||'|'||acsa_cur.ATTACHED_REMITTANCE_STUB_FLAG ||'|'||acsa_cur.NUMBER_OF_LINES_PER_REMIT_STUB ||'|'||acsa_cur.NUMBER_OF_SETUP_DOCUMENTS ||'|'||acsa_cur.FORMAT_CODE ||'|'||acsa_cur.FIRST_AVAILABLE_DOCUMENT_NUM ||'|'||acsa_cur.LAST_AVAILABLE_DOCUMENT_NUMBER ||'|'||acsa_cur.LAST_ISSUED_DOCUMENT_NUMBER ||'|'||acsa_cur.MANUAL_PAYMENTS_ONLY_FLAG ||'|'||acsa_cur.ATTRIBUTE_CATEGORY ||'|'||acsa_cur.ATTRIBUTE1 ||'|'||acsa_cur.ATTRIBUTE2 ||'|'||acsa_cur.ATTRIBUTE3 ||'|'||acsa_cur.ATTRIBUTE4 ||'|'||acsa_cur.ATTRIBUTE5 ||'|'||acsa_cur.ATTRIBUTE6 ||'|'||acsa_cur.ATTRIBUTE7 ||'|'||acsa_cur.ATTRIBUTE8 ||'|'||acsa_cur.ATTRIBUTE9 ||'|'||acsa_cur.ATTRIBUTE10 ||'|'||acsa_cur.ATTRIBUTE11 ||'|'||acsa_cur.ATTRIBUTE12 ||'|'||acsa_cur.ATTRIBUTE13 ||'|'||acsa_cur.ATTRIBUTE14 ||'|'||
      acsa_cur.ATTRIBUTE15 ||'|'||acsa_cur.INACTIVE_DATE ||'|'||acsa_cur.CREATED_BY ||'|'||acsa_cur.CREATION_DATE ||'|'||acsa_cur.LAST_UPDATED_BY ||'|'||acsa_cur.LAST_UPDATE_DATE ||'|'||acsa_cur.LAST_UPDATE_LOGIN ||'|'||acsa_cur.OBJECT_VERSION_NUMBER ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ce_payment_documents_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||'  Total Records Written for ce_payment_documents_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lc_summry_filename:= 'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD');
    lt_file           := UTL_FILE.fopen(gc_file_path,lc_summry_filename ,'a',ln_buffer);
    l_data            :='total record count in ap_check_stocks_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_check_stocks_all;
-- +===================================================================================================+
-- +================   Extract # 4   ===================================================================+
PROCEDURE Extract_ap_checks_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_ap_checks_all.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_checks_all                                                 |
  -- | Description      : This procedure is used to extract ap_checks_all                                  |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data              VARCHAR2(4000);
  l_period_name_begin VARCHAR2(30);
  l_period_name_end   VARCHAR2(30);
  l_out_cnt           NUMBER;
  lc_filename         VARCHAR2(4000);
  ln_req_id           NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='amount' ||'|'||'BANK_ACCOUNT_ID' ||'|'||'BANK_ACCOUNT_NAME' ||'|'||'CHECK_DATE' ||'|'||'CHECK_ID' ||'|'||'CHECK_NUMBER' ||'|'||'CURRENCY_CODE' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'PAYMENT_METHOD_LOOKUP_CODE' ||'|'||'PAYMENT_TYPE_FLAG' ||'|'||'ADDRESS_LINE1' ||'|'||'ADDRESS_LINE2' ||'|'||'ADDRESS_LINE3' ||'|'||'CHECKRUN_NAME' ||'|'||'CHECK_FORMAT_ID' ||'|'||'CHECK_STOCK_ID' ||'|'||'CITY' ||'|'||'COUNTRY' ||'|'||'CREATED_BY' ||'|'||'CREATION_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'STATUS_LOOKUP_CODE' ||'|'||'VENDOR_NAME' ||'|'||'VENDOR_SITE_CODE' ||'|'||'ZIP' ||'|'||'BANK_ACCOUNT_NUM' ||'|'||'BANK_ACCOUNT_TYPE' ||'|'||'BANK_NUM' ||'|'||'CHECK_VOUCHER_NUM' ||'|'||'CLEARED_AMOUNT' ||'|'||'CLEARED_DATE' ||'|'||'DOC_CATEGORY_CODE' ||'|'||'DOC_SEQUENCE_ID' ||'|'||'DOC_SEQUENCE_VALUE' ||'|'||'PROVINCE' ||'|'||'RELEASED_AT' ||'|'||'RELEASED_BY' ||'|'||'STATE' ||'|'||'STOPPED_AT' ||'|'||'STOPPED_BY' ||'|'||'VOID_DATE' ||'|'||'ATTRIBUTE1' ||'|'||
  'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'FUTURE_PAY_DUE_DATE' ||'|'||'TREASURY_PAY_DATE' ||'|'||'TREASURY_PAY_NUMBER' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'USSGL_TRX_CODE_CONTEXT' ||'|'||'WITHHOLDING_STATUS_LOOKUP_CODE' ||'|'||'RECONCILIATION_BATCH_ID' ||'|'||'CLEARED_BASE_AMOUNT' ||'|'||'CLEARED_EXCHANGE_RATE' ||'|'||'CLEARED_EXCHANGE_DATE' ||'|'||'CLEARED_EXCHANGE_RATE_TYPE' ||'|'||'ADDRESS_LINE4' ||'|'||'COUNTY' ||'|'||'ADDRESS_STYLE' ||'|'||'ORG_ID' ||'|'||'VENDOR_ID' ||'|'||'VENDOR_SITE_ID' ||'|'||'EXCHANGE_RATE' ||'|'||'EXCHANGE_DATE' ||'|'||'EXCHANGE_RATE_TYPE' ||'|'||'BASE_AMOUNT' ||'|'||'CHECKRUN_ID' ||'|'||'REQUEST_ID' ||'|'||'CLEARED_ERROR_AMOUNT' ||'|'||'CLEARED_CHARGES_AMOUNT' ||'|'||
  'CLEARED_ERROR_BASE_AMOUNT' ||'|'||'CLEARED_CHARGES_BASE_AMOUNT' ||'|'||'POSITIVE_PAY_STATUS_CODE' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'TRANSFER_PRIORITY' ||'|'||'EXTERNAL_BANK_ACCOUNT_ID' ||'|'||'STAMP_DUTY_AMT' ||'|'||'STAMP_DUTY_BASE_AMT' ||'|'||'MRC_CLEARED_BASE_AMOUNT' ||'|'||'MRC_CLEARED_EXCHANGE_RATE' ||'|'||'MRC_CLEARED_EXCHANGE_DATE' ||'|'||'MRC_CLEARED_EXCHANGE_RATE_TYPE' ||'|'||'MRC_EXCHANGE_RATE' ||'|'||'MRC_EXCHANGE_DATE'
  ||'|'||'MRC_EXCHANGE_RATE_TYPE' ||'|'||'MRC_BASE_AMOUNT' ||'|'||'MRC_CLEARED_ERROR_BASE_AMOUNT' ||'|'||'MRC_CLEARED_CHARGES_BASE_AMT' ||'|'||'MRC_STAMP_DUTY_BASE_AMT' ||'|'||'MATURITY_EXCHANGE_DATE' ||'|'||'MATURITY_EXCHANGE_RATE_TYPE' ||'|'||'MATURITY_EXCHANGE_RATE' ||'|'||'DESCRIPTION' ||'|'||'ACTUAL_VALUE_DATE' ||'|'||'ANTICIPATED_VALUE_DATE' ||'|'||'RELEASED_DATE' ||'|'||'STOPPED_DATE' ||'|'||'MRC_MATURITY_EXG_DATE' ||'|'||'MRC_MATURITY_EXG_RATE' ||'|'||'MRC_MATURITY_EXG_RATE_TYPE' ||'|'||'IBAN_NUMBER' ||'|'||'VOID_CHECK_ID' ||'|'||'VOID_CHECK_NUMBER' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR aca_Cur IN
    (SELECT apa.AMOUNT ,
      cbau.BANK_ACCOUNT_ID ,
      cba.BANK_ACCOUNT_NAME ,
      apa.CHECK_DATE ,
      apa.CHECK_ID ,
      apa.CHECK_NUMBER ,
      apa.CURRENCY_CODE ,
      apa.LAST_UPDATED_BY ,
      apa.LAST_UPDATE_DATE ,
      apa.PAYMENT_METHOD_CODE PAYMENT_METHOD_LOOKUP_CODE--PAYMENT_METHOD_LOOKUP_CODE renamed to PAYMENT_METHOD_CODE in R12 QC Defect 27400
      ,
      apa.PAYMENT_TYPE_FLAG ,
      apa.ADDRESS_LINE1 ,
      apa.ADDRESS_LINE2 ,
      apa.ADDRESS_LINE3 ,
      apa.CHECKRUN_NAME ,
      apa.payment_document_id CHECK_FORMAT_ID--  CHECK_FORMAT_ID renamed to payment_document_id in R12 QC Defect 27400
      ,
      apa.payment_document_id CHECK_STOCK_ID --  CHECK_STOCK_ID renamed to payment_document_id in R12 QC Defect 27400
      ,
      apa.CITY ,
      apa.COUNTRY ,
      apa.CREATED_BY ,
      apa.CREATION_DATE ,
      apa.LAST_UPDATE_LOGIN ,
      apa.STATUS_LOOKUP_CODE ,
      apa.VENDOR_NAME ,
      apa.VENDOR_SITE_CODE ,
      apa.ZIP ,
      apa.BANK_ACCOUNT_NUM ,
      apa.BANK_ACCOUNT_TYPE ,
      apa.BANK_NUM ,
      apa.CHECK_VOUCHER_NUM ,
      apa.CLEARED_AMOUNT ,
      apa.CLEARED_DATE ,
      apa.DOC_CATEGORY_CODE ,
      apa.DOC_SEQUENCE_ID ,
      apa.DOC_SEQUENCE_VALUE ,
      apa.PROVINCE ,
      apa.RELEASED_AT ,
      apa.RELEASED_BY ,
      apa.STATE ,
      apa.STOPPED_AT ,
      apa.STOPPED_BY ,
      apa.VOID_DATE ,
      apa.ATTRIBUTE1 ,
      apa.ATTRIBUTE10 ,
      apa.ATTRIBUTE11 ,
      apa.ATTRIBUTE12 ,
      apa.ATTRIBUTE13 ,
      apa.ATTRIBUTE14 ,
      apa.ATTRIBUTE15 ,
      apa.ATTRIBUTE2 ,
      apa.ATTRIBUTE3 ,
      apa.ATTRIBUTE4 ,
      apa.ATTRIBUTE5 ,
      apa.ATTRIBUTE6 ,
      apa.ATTRIBUTE7 ,
      apa.ATTRIBUTE8 ,
      apa.ATTRIBUTE9 ,
      apa.ATTRIBUTE_CATEGORY ,
      apa.FUTURE_PAY_DUE_DATE ,
      apa.TREASURY_PAY_DATE ,
      apa.TREASURY_PAY_NUMBER ,
      apa.USSGL_TRANSACTION_CODE ,
      apa.USSGL_TRX_CODE_CONTEXT ,
      apa.WITHHOLDING_STATUS_LOOKUP_CODE ,
      apa.RECONCILIATION_BATCH_ID ,
      apa.CLEARED_BASE_AMOUNT ,
      apa.CLEARED_EXCHANGE_RATE ,
      apa.CLEARED_EXCHANGE_DATE ,
      apa.CLEARED_EXCHANGE_RATE_TYPE ,
      apa.ADDRESS_LINE4 ,
      apa.COUNTY ,
      apa.ADDRESS_STYLE ,
      apa.ORG_ID ,
      apa.VENDOR_ID ,
      apa.VENDOR_SITE_ID ,
      apa.EXCHANGE_RATE ,
      apa.EXCHANGE_DATE ,
      apa.EXCHANGE_RATE_TYPE ,
      apa.BASE_AMOUNT ,
      apa.CHECKRUN_ID ,
      apa.REQUEST_ID ,
      apa.CLEARED_ERROR_AMOUNT ,
      apa.CLEARED_CHARGES_AMOUNT ,
      apa.CLEARED_ERROR_BASE_AMOUNT ,
      apa.CLEARED_CHARGES_BASE_AMOUNT ,
      apa.POSITIVE_PAY_STATUS_CODE ,
      apa.GLOBAL_ATTRIBUTE_CATEGORY ,
      apa.GLOBAL_ATTRIBUTE1 ,
      apa.GLOBAL_ATTRIBUTE2 ,
      apa.GLOBAL_ATTRIBUTE3 ,
      apa.GLOBAL_ATTRIBUTE4 ,
      apa.GLOBAL_ATTRIBUTE5 ,
      apa.GLOBAL_ATTRIBUTE6 ,
      apa.GLOBAL_ATTRIBUTE7 ,
      apa.GLOBAL_ATTRIBUTE8 ,
      apa.GLOBAL_ATTRIBUTE9 ,
      apa.GLOBAL_ATTRIBUTE10 ,
      apa.GLOBAL_ATTRIBUTE11 ,
      apa.GLOBAL_ATTRIBUTE12 ,
      apa.GLOBAL_ATTRIBUTE13 ,
      apa.GLOBAL_ATTRIBUTE14 ,
      apa.GLOBAL_ATTRIBUTE15 ,
      apa.GLOBAL_ATTRIBUTE16 ,
      apa.GLOBAL_ATTRIBUTE17 ,
      apa.GLOBAL_ATTRIBUTE18 ,
      apa.GLOBAL_ATTRIBUTE19 ,
      apa.GLOBAL_ATTRIBUTE20 ,
      apa.TRANSFER_PRIORITY ,
      apa.EXTERNAL_BANK_ACCOUNT_ID ,
      apa.STAMP_DUTY_AMT ,
      apa.STAMP_DUTY_BASE_AMT ,
      apa.MRC_CLEARED_BASE_AMOUNT ,
      apa.MRC_CLEARED_EXCHANGE_RATE ,
      apa.MRC_CLEARED_EXCHANGE_DATE ,
      apa.MRC_CLEARED_EXCHANGE_RATE_TYPE ,
      apa.MRC_EXCHANGE_RATE ,
      apa.MRC_EXCHANGE_DATE ,
      apa.MRC_EXCHANGE_RATE_TYPE ,
      apa.MRC_BASE_AMOUNT ,
      apa.MRC_CLEARED_ERROR_BASE_AMOUNT ,
      apa.MRC_CLEARED_CHARGES_BASE_AMT ,
      apa.MRC_STAMP_DUTY_BASE_AMT ,
      apa.MATURITY_EXCHANGE_DATE ,
      apa.MATURITY_EXCHANGE_RATE_TYPE ,
      apa.MATURITY_EXCHANGE_RATE ,
      apa.DESCRIPTION ,
      apa.ACTUAL_VALUE_DATE ,
      apa.ANTICIPATED_VALUE_DATE ,
      apa.RELEASED_DATE ,
      apa.STOPPED_DATE ,
      apa.MRC_MATURITY_EXG_DATE ,
      apa.MRC_MATURITY_EXG_RATE ,
      apa.MRC_MATURITY_EXG_RATE_TYPE ,
      apa.IBAN_NUMBER ,
      apa.VOID_CHECK_ID ,
      apa.VOID_CHECK_NUMBER
    FROM ap_checks_all apa ,
      CE_BANK_ACCT_USES_ALL cbau -- added for defect 27400
      ,
      ce_bank_accounts cba -- added for defect 27400
    WHERE ( TRUNC(apa.last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(apa.creation_date) BETWEEN ld_start_date AND ld_end_date )
    AND apa.ce_BANK_ACCT_USE_ID = cbau.bank_acct_use_id
    AND cbau.bank_account_id    = cba.bank_account_id
    )
    LOOP
      l_data:=aca_Cur.amount ||'|'||aca_Cur.BANK_ACCOUNT_ID ||'|'||aca_Cur.BANK_ACCOUNT_NAME ||'|'||aca_Cur.CHECK_DATE ||'|'||aca_Cur.CHECK_ID ||'|'||aca_Cur.CHECK_NUMBER ||'|'||aca_Cur.CURRENCY_CODE ||'|'||aca_Cur.LAST_UPDATED_BY ||'|'||aca_Cur.LAST_UPDATE_DATE ||'|'||aca_Cur.PAYMENT_METHOD_LOOKUP_CODE ||'|'||aca_Cur.PAYMENT_TYPE_FLAG ||'|'||aca_Cur.ADDRESS_LINE1 ||'|'||aca_Cur.ADDRESS_LINE2 ||'|'||aca_Cur.ADDRESS_LINE3 ||'|'||aca_Cur.CHECKRUN_NAME ||'|'||aca_Cur.CHECK_FORMAT_ID ||'|'||aca_Cur.CHECK_STOCK_ID ||'|'||aca_Cur.CITY ||'|'||aca_Cur.COUNTRY ||'|'||aca_Cur.CREATED_BY ||'|'||aca_Cur.CREATION_DATE ||'|'||aca_Cur.LAST_UPDATE_LOGIN ||'|'||aca_Cur.STATUS_LOOKUP_CODE ||'|'||aca_Cur.VENDOR_NAME ||'|'||aca_Cur.VENDOR_SITE_CODE ||'|'||aca_Cur.ZIP
      --            ||'|'||aca_Cur.BANK_ACCOUNT_NUM
      ||'|'||' ' ||'|'||aca_Cur.BANK_ACCOUNT_TYPE
      --            ||'|'||aca_Cur.BANK_NUM
      ||'|'||' ' ||'|'||aca_Cur.CHECK_VOUCHER_NUM ||'|'||aca_Cur.CLEARED_AMOUNT ||'|'||aca_Cur.CLEARED_DATE ||'|'||aca_Cur.DOC_CATEGORY_CODE ||'|'||aca_Cur.DOC_SEQUENCE_ID ||'|'||aca_Cur.DOC_SEQUENCE_VALUE ||'|'||aca_Cur.PROVINCE ||'|'||aca_Cur.RELEASED_AT ||'|'||aca_Cur.RELEASED_BY ||'|'||aca_Cur.STATE ||'|'||aca_Cur.STOPPED_AT ||'|'||aca_Cur.STOPPED_BY ||'|'||aca_Cur.VOID_DATE ||'|'||aca_Cur.ATTRIBUTE1 ||'|'||aca_Cur.ATTRIBUTE10 ||'|'||aca_Cur.ATTRIBUTE11 ||'|'||aca_Cur.ATTRIBUTE12 ||'|'||aca_Cur.ATTRIBUTE13 ||'|'||aca_Cur.ATTRIBUTE14 ||'|'||aca_Cur.ATTRIBUTE15 ||'|'||aca_Cur.ATTRIBUTE2 ||'|'||aca_Cur.ATTRIBUTE3 ||'|'||aca_Cur.ATTRIBUTE4 ||'|'||aca_Cur.ATTRIBUTE5 ||'|'||aca_Cur.ATTRIBUTE6 ||'|'||aca_Cur.ATTRIBUTE7 ||'|'||aca_Cur.ATTRIBUTE8 ||'|'||aca_Cur.ATTRIBUTE9 ||'|'||aca_Cur.ATTRIBUTE_CATEGORY ||'|'||aca_Cur.FUTURE_PAY_DUE_DATE ||'|'||aca_Cur.TREASURY_PAY_DATE ||'|'||aca_Cur.TREASURY_PAY_NUMBER ||'|'||aca_Cur.USSGL_TRANSACTION_CODE ||'|'||aca_Cur.USSGL_TRX_CODE_CONTEXT ||'|'||
      aca_Cur.WITHHOLDING_STATUS_LOOKUP_CODE ||'|'||aca_Cur.RECONCILIATION_BATCH_ID ||'|'||aca_Cur.CLEARED_BASE_AMOUNT ||'|'||aca_Cur.CLEARED_EXCHANGE_RATE ||'|'||aca_Cur.CLEARED_EXCHANGE_DATE ||'|'||aca_Cur.CLEARED_EXCHANGE_RATE_TYPE ||'|'||aca_Cur.ADDRESS_LINE4 ||'|'||aca_Cur.COUNTY ||'|'||aca_Cur.ADDRESS_STYLE ||'|'||aca_Cur.ORG_ID ||'|'||aca_Cur.VENDOR_ID ||'|'||aca_Cur.VENDOR_SITE_ID ||'|'||aca_Cur.EXCHANGE_RATE ||'|'||aca_Cur.EXCHANGE_DATE ||'|'||aca_Cur.EXCHANGE_RATE_TYPE ||'|'||aca_Cur.BASE_AMOUNT ||'|'||aca_Cur.CHECKRUN_ID ||'|'||aca_Cur.REQUEST_ID ||'|'||aca_Cur.CLEARED_ERROR_AMOUNT ||'|'||aca_Cur.CLEARED_CHARGES_AMOUNT ||'|'||aca_Cur.CLEARED_ERROR_BASE_AMOUNT ||'|'||aca_Cur.CLEARED_CHARGES_BASE_AMOUNT ||'|'||aca_Cur.POSITIVE_PAY_STATUS_CODE ||'|'||aca_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||aca_Cur.GLOBAL_ATTRIBUTE1 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE2 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE3 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE4 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE5 ||'|'||
      aca_Cur.GLOBAL_ATTRIBUTE6 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE7 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE8 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE9 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE10 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE11 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE12 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE13 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE14 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE15 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE16 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE17 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE18 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE19 ||'|'||aca_Cur.GLOBAL_ATTRIBUTE20 ||'|'||aca_Cur.TRANSFER_PRIORITY ||'|'||aca_Cur.EXTERNAL_BANK_ACCOUNT_ID ||'|'||aca_Cur.STAMP_DUTY_AMT ||'|'||aca_Cur.STAMP_DUTY_BASE_AMT ||'|'||aca_Cur.MRC_CLEARED_BASE_AMOUNT ||'|'||aca_Cur.MRC_CLEARED_EXCHANGE_RATE ||'|'||aca_Cur.MRC_CLEARED_EXCHANGE_DATE ||'|'||aca_Cur.MRC_CLEARED_EXCHANGE_RATE_TYPE ||'|'||aca_Cur.MRC_EXCHANGE_RATE ||'|'||aca_Cur.MRC_EXCHANGE_DATE ||'|'||aca_Cur.MRC_EXCHANGE_RATE_TYPE ||'|'||aca_Cur.MRC_BASE_AMOUNT ||'|'||aca_Cur.MRC_CLEARED_ERROR_BASE_AMOUNT ||'|'||
      aca_Cur.MRC_CLEARED_CHARGES_BASE_AMT ||'|'||aca_Cur.MRC_STAMP_DUTY_BASE_AMT ||'|'||aca_Cur.MATURITY_EXCHANGE_DATE ||'|'||aca_Cur.MATURITY_EXCHANGE_RATE_TYPE ||'|'||aca_Cur.MATURITY_EXCHANGE_RATE ||'|'||aca_Cur.DESCRIPTION ||'|'||aca_Cur.ACTUAL_VALUE_DATE ||'|'||aca_Cur.ANTICIPATED_VALUE_DATE ||'|'||aca_Cur.RELEASED_DATE ||'|'||aca_Cur.STOPPED_DATE ||'|'||aca_Cur.MRC_MATURITY_EXG_DATE ||'|'||aca_Cur.MRC_MATURITY_EXG_RATE ||'|'||aca_Cur.MRC_MATURITY_EXG_RATE_TYPE ||'|'||aca_Cur.IBAN_NUMBER ||'|'||aca_Cur.VOID_CHECK_ID ||'|'||aca_Cur.VOID_CHECK_NUMBER ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_checks_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||'  Total Records Written for ap_checks_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    write_log(p_debug_flag,' ');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in ap_checks_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_checks_all;
-- +===================================================================================================+
-- +===============  Extract # 5  ====================================================================+
PROCEDURE Extract_ap_inv_dist_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_ap_inv_dist_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_invoice_distributions_all                                                  |
  -- | Description      : This procedure is used to extract ap_invoice_distributions_all                                    |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  l_source    VARCHAR2(25);
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  ln_req_id    := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename  := ln_req_id||'.out';
  lt_file      := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data       :='accounting_date' ||'|'||'ACCRUAL_POSTED_FLAG' ||'|'||'ASSETS_ADDITION_FLAG' ||'|'||'ASSETS_TRACKING_FLAG' ||'|'||'CASH_POSTED_FLAG' ||'|'||'DISTRIBUTION_LINE_NUMBER' ||'|'||'DIST_CODE_COMBINATION_ID' ||'|'||'INVOICE_ID' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LINE_TYPE_LOOKUP_CODE' ||'|'||'PERIOD_NAME' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'ACCTS_PAY_CODE_COMBINATION_ID' ||'|'||'AMOUNT' ||'|'||'BASE_AMOUNT' ||'|'||'BASE_INVOICE_PRICE_VARIANCE' ||'|'||'BATCH_ID' ||'|'||'CREATED_BY' ||'|'||'CREATION_DATE' ||'|'||'DESCRIPTION' ||'|'||'EXCHANGE_RATE_VARIANCE' ||'|'||'FINAL_MATCH_FLAG' ||'|'||'INCOME_TAX_REGION' ||'|'||'INVOICE_PRICE_VARIANCE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'MATCH_STATUS_FLAG' ||'|'||'POSTED_FLAG' ||'|'||'PO_DISTRIBUTION_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'QUANTITY_INVOICED' ||'|'||'RATE_VAR_CODE_COMBINATION_ID' ||'|'||'REQUEST_ID' ||'|'||'REVERSAL_FLAG' ||'|'||'TYPE_1099' ||'|'||
  'UNIT_PRICE' ||'|'||'VAT_CODE' ||'|'||'AMOUNT_ENCUMBERED' ||'|'||'BASE_AMOUNT_ENCUMBERED' ||'|'||'ENCUMBERED_FLAG' ||'|'||'EXCHANGE_DATE' ||'|'||'EXCHANGE_RATE' ||'|'||'EXCHANGE_RATE_TYPE' ||'|'||'PRICE_ADJUSTMENT_FLAG' ||'|'||'PRICE_VAR_CODE_COMBINATION_ID' ||'|'||'QUANTITY_UNENCUMBERED' ||'|'||'STAT_AMOUNT' ||'|'||'AMOUNT_TO_POST' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'BASE_AMOUNT_TO_POST' ||'|'||'CASH_JE_BATCH_ID' ||'|'||'EXPENDITURE_ITEM_DATE' ||'|'||'EXPENDITURE_ORGANIZATION_ID' ||'|'||'EXPENDITURE_TYPE' ||'|'||'JE_BATCH_ID' ||'|'||'PARENT_INVOICE_ID' ||'|'||'PA_ADDITION_FLAG' ||'|'||'PA_QUANTITY' ||'|'||'POSTED_AMOUNT' ||'|'||'POSTED_BASE_AMOUNT' ||'|'||'PREPAY_AMOUNT_REMAINING'
  ||'|'||'PROJECT_ACCOUNTING_CONTEXT' ||'|'||'PROJECT_ID' ||'|'||'TASK_ID' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'USSGL_TRX_CODE_CONTEXT' ||'|'||'EARLIEST_SETTLEMENT_DATE' ||'|'||'REQ_DISTRIBUTION_ID' ||'|'||'QUANTITY_VARIANCE' ||'|'||'BASE_QUANTITY_VARIANCE' ||'|'||'PACKET_ID' ||'|'||'AWT_FLAG' ||'|'||'AWT_GROUP_ID' ||'|'||'AWT_TAX_RATE_ID' ||'|'||'AWT_GROSS_AMOUNT' ||'|'||'AWT_INVOICE_ID' ||'|'||'AWT_ORIGIN_GROUP_ID' ||'|'||'REFERENCE_1' ||'|'||'REFERENCE_2' ||'|'||'ORG_ID' ||'|'||'OTHER_INVOICE_ID' ||'|'||'AWT_INVOICE_PAYMENT_ID' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||
  'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'AMOUNT_INCLUDES_TAX_FLAG' ||'|'||'TAX_CALCULATED_FLAG' ||'|'||'LINE_GROUP_NUMBER' ||'|'||'RECEIPT_VERIFIED_FLAG' ||'|'||'RECEIPT_REQUIRED_FLAG' ||'|'||'RECEIPT_MISSING_FLAG' ||'|'||'JUSTIFICATION' ||'|'||'EXPENSE_GROUP' ||'|'||'START_EXPENSE_DATE' ||'|'||'END_EXPENSE_DATE' ||'|'||'RECEIPT_CURRENCY_CODE' ||'|'||'RECEIPT_CONVERSION_RATE' ||'|'||'RECEIPT_CURRENCY_AMOUNT' ||'|'||'DAILY_AMOUNT' ||'|'||'WEB_PARAMETER_ID' ||'|'||'ADJUSTMENT_REASON' ||'|'||'AWARD_ID' ||'|'||'MRC_DIST_CODE_COMBINATION_ID' ||'|'||'MRC_BASE_AMOUNT' ||'|'||'MRC_BASE_INV_PRICE_VARIANCE' ||'|'||'MRC_EXCHANGE_RATE_VARIANCE' ||'|'||'MRC_RATE_VAR_CCID' ||'|'||'MRC_EXCHANGE_DATE' ||'|'||'MRC_EXCHANGE_RATE' ||'|'||'MRC_EXCHANGE_RATE_TYPE' ||'|'||'MRC_RECEIPT_CONVERSION_RATE' ||'|'||'DIST_MATCH_TYPE' ||'|'||'RCV_TRANSACTION_ID' ||'|'||'INVOICE_DISTRIBUTION_ID' ||'|'||
  'PARENT_REVERSAL_ID' ||'|'||'TAX_RECOVERY_RATE' ||'|'||'TAX_RECOVERY_OVERRIDE_FLAG' ||'|'||'TAX_RECOVERABLE_FLAG' ||'|'||'TAX_CODE_OVERRIDE_FLAG' ||'|'||'TAX_CODE_ID' ||'|'||'PA_CC_AR_INVOICE_ID' ||'|'||'PA_CC_AR_INVOICE_LINE_NUM' ||'|'||'PA_CC_PROCESSED_CODE' ||'|'||'MERCHANT_DOCUMENT_NUMBER' ||'|'||'MERCHANT_NAME' ||'|'||'MERCHANT_REFERENCE' ||'|'||'MERCHANT_TAX_REG_NUMBER' ||'|'||'MERCHANT_TAXPAYER_ID' ||'|'||'COUNTRY_OF_SUPPLY' ||'|'||'MATCHED_UOM_LOOKUP_CODE' ||'|'||'GMS_BURDENABLE_RAW_COST' ||'|'||'ACCOUNTING_EVENT_ID' ||'|'||'PREPAY_DISTRIBUTION_ID' ||'|'||'CREDIT_CARD_TRX_ID' ||'|'||'UPGRADE_POSTED_AMT' ||'|'||'UPGRADE_BASE_POSTED_AMT' ||'|'||'INVENTORY_TRANSFER_STATUS' ||'|'||'COMPANY_PREPAID_INVOICE_ID' ||'|'||'CC_REVERSAL_FLAG' ||'|'||'PREPAY_TAX_PARENT_ID' ||'|'||'AWT_WITHHELD_AMT' ||'|'||'INVOICE_INCLUDES_PREPAY_FLAG' ||'|'||'PRICE_CORRECT_INV_ID' ||'|'||'PRICE_CORRECT_QTY' ||'|'||'PA_CMT_XFACE_FLAG' ||'|'||'CANCELLATION_FLAG' ||'|'||'FULLY_PAID_ACCTD_FLAG' ||'|'||
  'ROOT_DISTRIBUTION_ID' ||'|'||'XINV_PARENT_REVERSAL_ID' ||'|'||'AMOUNT_VARIANCE' ||'|'||'BASE_AMOUNT_VARIANCE' ||'|'||'RECURRING_PAYMENT_ID' ||'|'||'INVOICE_LINE_NUMBER' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR aida_Cur IN
    (SELECT aid.ACCOUNTING_DATE ,
      aid.ACCRUAL_POSTED_FLAG ,
      aid.ASSETS_ADDITION_FLAG ,
      aid.ASSETS_TRACKING_FLAG ,
      aid.CASH_POSTED_FLAG ,
      aid.DISTRIBUTION_LINE_NUMBER ,
      aid.DIST_CODE_COMBINATION_ID ,
      aid.INVOICE_ID ,
      aid.LAST_UPDATED_BY ,
      aid.LAST_UPDATE_DATE ,
      aid.LINE_TYPE_LOOKUP_CODE ,
      aid.PERIOD_NAME ,
      aid.SET_OF_BOOKS_ID ,
      aid.ACCTS_PAY_CODE_COMBINATION_ID ,
      aid.AMOUNT ,
      aid.BASE_AMOUNT ,
      aid.BASE_INVOICE_PRICE_VARIANCE ,
      aid.BATCH_ID ,
      aid.CREATED_BY ,
      aid.CREATION_DATE ,
      aid.DESCRIPTION ,
      aid.EXCHANGE_RATE_VARIANCE ,
      aid.FINAL_MATCH_FLAG ,
      aid.INCOME_TAX_REGION ,
      aid.INVOICE_PRICE_VARIANCE ,
      aid.LAST_UPDATE_LOGIN ,
      aid.MATCH_STATUS_FLAG ,
      aid.POSTED_FLAG ,
      aid.PO_DISTRIBUTION_ID ,
      aid.PROGRAM_APPLICATION_ID ,
      aid.PROGRAM_ID ,
      aid.PROGRAM_UPDATE_DATE ,
      aid.QUANTITY_INVOICED ,
      aid.RATE_VAR_CODE_COMBINATION_ID ,
      aid.REQUEST_ID ,
      aid.REVERSAL_FLAG ,
      aid.TYPE_1099 ,
      aid.UNIT_PRICE ,
      aid.VAT_CODE ,
      aid.AMOUNT_ENCUMBERED ,
      aid.BASE_AMOUNT_ENCUMBERED ,
      aid.ENCUMBERED_FLAG ,
      aid.EXCHANGE_DATE ,
      aid.EXCHANGE_RATE ,
      aid.EXCHANGE_RATE_TYPE ,
      aid.PRICE_ADJUSTMENT_FLAG ,
      aid.PRICE_VAR_CODE_COMBINATION_ID ,
      aid.QUANTITY_UNENCUMBERED ,
      aid.STAT_AMOUNT ,
      aid.AMOUNT_TO_POST ,
      aid.ATTRIBUTE1 ,
      aid.ATTRIBUTE10 ,
      aid.ATTRIBUTE11 ,
      aid.ATTRIBUTE12 ,
      aid.ATTRIBUTE13 ,
      aid.ATTRIBUTE14 ,
      aid.ATTRIBUTE15 ,
      aid.ATTRIBUTE2 ,
      aid.ATTRIBUTE3 ,
      aid.ATTRIBUTE4 ,
      aid.ATTRIBUTE5 ,
      aid.ATTRIBUTE6 ,
      aid.ATTRIBUTE7 ,
      aid.ATTRIBUTE8 ,
      aid.ATTRIBUTE9 ,
      aid.ATTRIBUTE_CATEGORY ,
      aid.BASE_AMOUNT_TO_POST ,
      aid.CASH_JE_BATCH_ID ,
      aid.EXPENDITURE_ITEM_DATE ,
      aid.EXPENDITURE_ORGANIZATION_ID ,
      aid.EXPENDITURE_TYPE ,
      aid.JE_BATCH_ID ,
      aid.PARENT_INVOICE_ID ,
      aid.PA_ADDITION_FLAG ,
      aid.PA_QUANTITY ,
      aid.POSTED_AMOUNT ,
      aid.POSTED_BASE_AMOUNT ,
      aid.PREPAY_AMOUNT_REMAINING ,
      aid.PROJECT_ACCOUNTING_CONTEXT ,
      aid.PROJECT_ID ,
      aid.TASK_ID ,
      aid.USSGL_TRANSACTION_CODE ,
      aid.USSGL_TRX_CODE_CONTEXT ,
      aid.EARLIEST_SETTLEMENT_DATE ,
      aid.REQ_DISTRIBUTION_ID ,
      aid.QUANTITY_VARIANCE ,
      aid.BASE_QUANTITY_VARIANCE ,
      aid.PACKET_ID ,
      aid.AWT_FLAG ,
      aid.AWT_GROUP_ID ,
      aid.AWT_TAX_RATE_ID ,
      aid.AWT_GROSS_AMOUNT ,
      aid.AWT_INVOICE_ID ,
      aid.AWT_ORIGIN_GROUP_ID ,
      aid.REFERENCE_1 ,
      aid.REFERENCE_2 ,
      aid.ORG_ID ,
      aid.OTHER_INVOICE_ID ,
      aid.AWT_INVOICE_PAYMENT_ID ,
      aid.GLOBAL_ATTRIBUTE_CATEGORY ,
      aid.GLOBAL_ATTRIBUTE1 ,
      aid.GLOBAL_ATTRIBUTE2 ,
      aid.GLOBAL_ATTRIBUTE3 ,
      aid.GLOBAL_ATTRIBUTE4 ,
      aid.GLOBAL_ATTRIBUTE5 ,
      aid.GLOBAL_ATTRIBUTE6 ,
      aid.GLOBAL_ATTRIBUTE7 ,
      aid.GLOBAL_ATTRIBUTE8 ,
      aid.GLOBAL_ATTRIBUTE9 ,
      aid.GLOBAL_ATTRIBUTE10 ,
      aid.GLOBAL_ATTRIBUTE11 ,
      aid.GLOBAL_ATTRIBUTE12 ,
      aid.GLOBAL_ATTRIBUTE13 ,
      aid.GLOBAL_ATTRIBUTE14 ,
      aid.GLOBAL_ATTRIBUTE15 ,
      aid.GLOBAL_ATTRIBUTE16 ,
      aid.GLOBAL_ATTRIBUTE17 ,
      aid.GLOBAL_ATTRIBUTE18 ,
      aid.GLOBAL_ATTRIBUTE19 ,
      aid.GLOBAL_ATTRIBUTE20
      --,aid.AMOUNT_INCLUDES_TAX_FLAG  Commented for QC 27400
      ,
      zls.TAX_AMT_INCLUDED_FLAG AMOUNT_INCLUDES_TAX_FLAG -- Added for QC 27400
      ,
      aid.TAX_CALCULATED_FLAG ,
      aid.LINE_GROUP_NUMBER ,
      aid.RECEIPT_VERIFIED_FLAG ,
      aid.RECEIPT_REQUIRED_FLAG ,
      aid.RECEIPT_MISSING_FLAG ,
      aid.JUSTIFICATION ,
      aid.EXPENSE_GROUP ,
      aid.START_EXPENSE_DATE ,
      aid.END_EXPENSE_DATE ,
      aid.RECEIPT_CURRENCY_CODE ,
      aid.RECEIPT_CONVERSION_RATE ,
      aid.RECEIPT_CURRENCY_AMOUNT ,
      aid.DAILY_AMOUNT ,
      aid.WEB_PARAMETER_ID ,
      aid.ADJUSTMENT_REASON ,
      aid.AWARD_ID ,
      aid.MRC_DIST_CODE_COMBINATION_ID ,
      aid.MRC_BASE_AMOUNT ,
      aid.MRC_BASE_INV_PRICE_VARIANCE ,
      aid.MRC_EXCHANGE_RATE_VARIANCE ,
      aid.MRC_RATE_VAR_CCID ,
      aid.MRC_EXCHANGE_DATE ,
      aid.MRC_EXCHANGE_RATE ,
      aid.MRC_EXCHANGE_RATE_TYPE ,
      aid.MRC_RECEIPT_CONVERSION_RATE ,
      aid.DIST_MATCH_TYPE ,
      aid.RCV_TRANSACTION_ID ,
      aid.INVOICE_DISTRIBUTION_ID ,
      aid.PARENT_REVERSAL_ID ,
      aid.TAX_RECOVERY_RATE ,
      aid.TAX_RECOVERY_OVERRIDE_FLAG ,
      aid.TAX_RECOVERABLE_FLAG
      --,aid.TAX_CODE_OVERRIDE_FLAG Commented for QC 27400
      ,
      zls.OVERRIDDEN_FLAG TAX_CODE_OVERRIDE_FLAG --      Added for QC 27400
      ,
      aid.TAX_CODE_ID ,
      aid.PA_CC_AR_INVOICE_ID ,
      aid.PA_CC_AR_INVOICE_LINE_NUM ,
      aid.PA_CC_PROCESSED_CODE ,
      aid.MERCHANT_DOCUMENT_NUMBER ,
      aid.MERCHANT_NAME ,
      aid.MERCHANT_REFERENCE ,
      aid.MERCHANT_TAX_REG_NUMBER ,
      aid.MERCHANT_TAXPAYER_ID ,
      aid.COUNTRY_OF_SUPPLY ,
      aid.MATCHED_UOM_LOOKUP_CODE ,
      aid.GMS_BURDENABLE_RAW_COST ,
      aid.ACCOUNTING_EVENT_ID ,
      aid.PREPAY_DISTRIBUTION_ID ,
      aid.CREDIT_CARD_TRX_ID ,
      aid.UPGRADE_POSTED_AMT ,
      aid.UPGRADE_BASE_POSTED_AMT ,
      aid.INVENTORY_TRANSFER_STATUS ,
      aid.COMPANY_PREPAID_INVOICE_ID ,
      aid.CC_REVERSAL_FLAG ,
      aid.PREPAY_TAX_PARENT_ID ,
      aid.AWT_WITHHELD_AMT ,
      aid.INVOICE_INCLUDES_PREPAY_FLAG ,
      aid.PRICE_CORRECT_INV_ID ,
      aid.PRICE_CORRECT_QTY ,
      aid.PA_CMT_XFACE_FLAG ,
      aid.CANCELLATION_FLAG ,
      aid.FULLY_PAID_ACCTD_FLAG ,
      aid.ROOT_DISTRIBUTION_ID ,
      aid.XINV_PARENT_REVERSAL_ID ,
      aid.AMOUNT_VARIANCE ,
      aid.BASE_AMOUNT_VARIANCE ,
      aid.RECURRING_PAYMENT_ID ,
	  aid.INVOICE_LINE_NUMBER
    FROM ap_invoice_distributions_all aid,
      ZX_LINES_SUMMARY zls -- Added for defect 27400
    WHERE (TRUNC(aid.last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(aid.creation_date) BETWEEN ld_start_date AND ld_end_date )
    AND aid.invoice_id              = zls.trx_id(+)                 -- Modified Based on the Defect# 31315
    AND aid.DISTRIBUTION_LINE_NUMBER=zls.SUMMARY_TAX_LINE_NUMBER(+) -- Modified Based on the Defect# 31315
    )
    LOOP
      SELECT source
      INTO l_source
      FROM ap_invoices_all
      WHERE invoice_id       = aida_Cur.INVOICE_ID;
      IF l_SOURCE            = 'US_OD_PAYROLL_GARNISHMENT' THEN
        aida_Cur.description:= ' ';
      END IF;
      l_data:=aida_Cur.accounting_date ||'|'||aida_Cur.ACCRUAL_POSTED_FLAG ||'|'||aida_Cur.ASSETS_ADDITION_FLAG ||'|'||aida_Cur.ASSETS_TRACKING_FLAG ||'|'||aida_Cur.CASH_POSTED_FLAG ||'|'||aida_Cur.DISTRIBUTION_LINE_NUMBER ||'|'||aida_Cur.DIST_CODE_COMBINATION_ID ||'|'||aida_Cur.INVOICE_ID ||'|'||aida_Cur.LAST_UPDATED_BY ||'|'||aida_Cur.LAST_UPDATE_DATE ||'|'||aida_Cur.LINE_TYPE_LOOKUP_CODE ||'|'||aida_Cur.PERIOD_NAME ||'|'||aida_Cur.SET_OF_BOOKS_ID ||'|'||aida_Cur.ACCTS_PAY_CODE_COMBINATION_ID ||'|'||aida_Cur.AMOUNT ||'|'||aida_Cur.BASE_AMOUNT ||'|'||aida_Cur.BASE_INVOICE_PRICE_VARIANCE ||'|'||aida_Cur.BATCH_ID ||'|'||aida_Cur.CREATED_BY ||'|'||aida_Cur.CREATION_DATE ||'|'||aida_Cur.DESCRIPTION ||'|'||aida_Cur.EXCHANGE_RATE_VARIANCE ||'|'||aida_Cur.FINAL_MATCH_FLAG ||'|'||aida_Cur.INCOME_TAX_REGION ||'|'||aida_Cur.INVOICE_PRICE_VARIANCE ||'|'||aida_Cur.LAST_UPDATE_LOGIN ||'|'||aida_Cur.MATCH_STATUS_FLAG ||'|'||aida_Cur.POSTED_FLAG ||'|'||aida_Cur.PO_DISTRIBUTION_ID ||'|'||
      aida_Cur.PROGRAM_APPLICATION_ID ||'|'||aida_Cur.PROGRAM_ID ||'|'||aida_Cur.PROGRAM_UPDATE_DATE ||'|'||aida_Cur.QUANTITY_INVOICED ||'|'||aida_Cur.RATE_VAR_CODE_COMBINATION_ID ||'|'||aida_Cur.REQUEST_ID ||'|'||aida_Cur.REVERSAL_FLAG ||'|'||aida_Cur.TYPE_1099 ||'|'||aida_Cur.UNIT_PRICE ||'|'||aida_Cur.VAT_CODE ||'|'||aida_Cur.AMOUNT_ENCUMBERED ||'|'||aida_Cur.BASE_AMOUNT_ENCUMBERED ||'|'||aida_Cur.ENCUMBERED_FLAG ||'|'||aida_Cur.EXCHANGE_DATE ||'|'||aida_Cur.EXCHANGE_RATE ||'|'||aida_Cur.EXCHANGE_RATE_TYPE ||'|'||aida_Cur.PRICE_ADJUSTMENT_FLAG ||'|'||aida_Cur.PRICE_VAR_CODE_COMBINATION_ID ||'|'||aida_Cur.QUANTITY_UNENCUMBERED ||'|'||aida_Cur.STAT_AMOUNT ||'|'||aida_Cur.AMOUNT_TO_POST ||'|'||aida_Cur.ATTRIBUTE1 ||'|'||aida_Cur.ATTRIBUTE10 ||'|'||aida_Cur.ATTRIBUTE11 ||'|'||aida_Cur.ATTRIBUTE12 ||'|'||aida_Cur.ATTRIBUTE13 ||'|'||aida_Cur.ATTRIBUTE14 ||'|'||aida_Cur.ATTRIBUTE15 ||'|'||aida_Cur.ATTRIBUTE2 ||'|'||aida_Cur.ATTRIBUTE3 ||'|'||aida_Cur.ATTRIBUTE4 ||'|'||aida_Cur.ATTRIBUTE5
      ||'|'||aida_Cur.ATTRIBUTE6 ||'|'||aida_Cur.ATTRIBUTE7 ||'|'||aida_Cur.ATTRIBUTE8 ||'|'||aida_Cur.ATTRIBUTE9 ||'|'||aida_Cur.ATTRIBUTE_CATEGORY ||'|'||aida_Cur.BASE_AMOUNT_TO_POST ||'|'||aida_Cur.CASH_JE_BATCH_ID ||'|'||aida_Cur.EXPENDITURE_ITEM_DATE ||'|'||aida_Cur.EXPENDITURE_ORGANIZATION_ID ||'|'||aida_Cur.EXPENDITURE_TYPE ||'|'||aida_Cur.JE_BATCH_ID ||'|'||aida_Cur.PARENT_INVOICE_ID ||'|'||aida_Cur.PA_ADDITION_FLAG ||'|'||aida_Cur.PA_QUANTITY ||'|'||aida_Cur.POSTED_AMOUNT ||'|'||aida_Cur.POSTED_BASE_AMOUNT ||'|'||aida_Cur.PREPAY_AMOUNT_REMAINING ||'|'||aida_Cur.PROJECT_ACCOUNTING_CONTEXT ||'|'||aida_Cur.PROJECT_ID ||'|'||aida_Cur.TASK_ID ||'|'||aida_Cur.USSGL_TRANSACTION_CODE ||'|'||aida_Cur.USSGL_TRX_CODE_CONTEXT ||'|'||aida_Cur.EARLIEST_SETTLEMENT_DATE ||'|'||aida_Cur.REQ_DISTRIBUTION_ID ||'|'||aida_Cur.QUANTITY_VARIANCE ||'|'||aida_Cur.BASE_QUANTITY_VARIANCE ||'|'||aida_Cur.PACKET_ID ||'|'||aida_Cur.AWT_FLAG ||'|'||aida_Cur.AWT_GROUP_ID ||'|'||aida_Cur.AWT_TAX_RATE_ID ||
      '|'||aida_Cur.AWT_GROSS_AMOUNT ||'|'||aida_Cur.AWT_INVOICE_ID ||'|'||aida_Cur.AWT_ORIGIN_GROUP_ID ||'|'||aida_Cur.REFERENCE_1 ||'|'||aida_Cur.REFERENCE_2 ||'|'||aida_Cur.ORG_ID ||'|'||aida_Cur.OTHER_INVOICE_ID ||'|'||aida_Cur.AWT_INVOICE_PAYMENT_ID ||'|'||aida_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||aida_Cur.GLOBAL_ATTRIBUTE1 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE2 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE3 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE4 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE5 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE6 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE7 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE8 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE9 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE10 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE11 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE12 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE13 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE14 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE15 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE16 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE17 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE18 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE19 ||'|'||aida_Cur.GLOBAL_ATTRIBUTE20 ||'|'||
      aida_Cur.AMOUNT_INCLUDES_TAX_FLAG ||'|'||aida_Cur.TAX_CALCULATED_FLAG ||'|'||aida_Cur.LINE_GROUP_NUMBER ||'|'||aida_Cur.RECEIPT_VERIFIED_FLAG ||'|'||aida_Cur.RECEIPT_REQUIRED_FLAG ||'|'||aida_Cur.RECEIPT_MISSING_FLAG ||'|'||aida_Cur.JUSTIFICATION ||'|'||aida_Cur.EXPENSE_GROUP ||'|'||aida_Cur.START_EXPENSE_DATE ||'|'||aida_Cur.END_EXPENSE_DATE ||'|'||aida_Cur.RECEIPT_CURRENCY_CODE ||'|'||aida_Cur.RECEIPT_CONVERSION_RATE ||'|'||aida_Cur.RECEIPT_CURRENCY_AMOUNT ||'|'||aida_Cur.DAILY_AMOUNT ||'|'||aida_Cur.WEB_PARAMETER_ID ||'|'||aida_Cur.ADJUSTMENT_REASON ||'|'||aida_Cur.AWARD_ID ||'|'||aida_Cur.MRC_DIST_CODE_COMBINATION_ID ||'|'||aida_Cur.MRC_BASE_AMOUNT ||'|'||aida_Cur.MRC_BASE_INV_PRICE_VARIANCE ||'|'||aida_Cur.MRC_EXCHANGE_RATE_VARIANCE ||'|'||aida_Cur.MRC_RATE_VAR_CCID ||'|'||aida_Cur.MRC_EXCHANGE_DATE ||'|'||aida_Cur.MRC_EXCHANGE_RATE ||'|'||aida_Cur.MRC_EXCHANGE_RATE_TYPE ||'|'||aida_Cur.MRC_RECEIPT_CONVERSION_RATE ||'|'||aida_Cur.DIST_MATCH_TYPE ||'|'||
      aida_Cur.RCV_TRANSACTION_ID ||'|'||aida_Cur.INVOICE_DISTRIBUTION_ID ||'|'||aida_Cur.PARENT_REVERSAL_ID ||'|'||aida_Cur.TAX_RECOVERY_RATE ||'|'||aida_Cur.TAX_RECOVERY_OVERRIDE_FLAG ||'|'||aida_Cur.TAX_RECOVERABLE_FLAG ||'|'||aida_Cur.TAX_CODE_OVERRIDE_FLAG ||'|'||aida_Cur.TAX_CODE_ID ||'|'||aida_Cur.PA_CC_AR_INVOICE_ID ||'|'||aida_Cur.PA_CC_AR_INVOICE_LINE_NUM ||'|'||aida_Cur.PA_CC_PROCESSED_CODE ||'|'||aida_Cur.MERCHANT_DOCUMENT_NUMBER ||'|'||aida_Cur.MERCHANT_NAME ||'|'||aida_Cur.MERCHANT_REFERENCE ||'|'||aida_Cur.MERCHANT_TAX_REG_NUMBER ||'|'||aida_Cur.MERCHANT_TAXPAYER_ID ||'|'||aida_Cur.COUNTRY_OF_SUPPLY ||'|'||aida_Cur.MATCHED_UOM_LOOKUP_CODE ||'|'||aida_Cur.GMS_BURDENABLE_RAW_COST ||'|'||aida_Cur.ACCOUNTING_EVENT_ID ||'|'||aida_Cur.PREPAY_DISTRIBUTION_ID ||'|'||aida_Cur.CREDIT_CARD_TRX_ID ||'|'||aida_Cur.UPGRADE_POSTED_AMT ||'|'||aida_Cur.UPGRADE_BASE_POSTED_AMT ||'|'||aida_Cur.INVENTORY_TRANSFER_STATUS ||'|'||aida_Cur.COMPANY_PREPAID_INVOICE_ID ||'|'||
      aida_Cur.CC_REVERSAL_FLAG ||'|'||aida_Cur.PREPAY_TAX_PARENT_ID ||'|'||aida_Cur.AWT_WITHHELD_AMT ||'|'||aida_Cur.INVOICE_INCLUDES_PREPAY_FLAG ||'|'||aida_Cur.PRICE_CORRECT_INV_ID ||'|'||aida_Cur.PRICE_CORRECT_QTY ||'|'||aida_Cur.PA_CMT_XFACE_FLAG ||'|'||aida_Cur.CANCELLATION_FLAG ||'|'||aida_Cur.FULLY_PAID_ACCTD_FLAG ||'|'||aida_Cur.ROOT_DISTRIBUTION_ID ||'|'||aida_Cur.XINV_PARENT_REVERSAL_ID ||'|'||aida_Cur.AMOUNT_VARIANCE ||'|'||aida_Cur.BASE_AMOUNT_VARIANCE ||'|'||aida_Cur.RECURRING_PAYMENT_ID ||'|'||aida_Cur.INVOICE_LINE_NUMBER ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_invoice_distributions_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_invoice_distributions_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in ap_invoice_distributions_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_inv_dist_all;
-- +===================================================================================================+
-- +===============  Extract # 6  ====================================================================+
PROCEDURE Extract_ap_inv_pymnt_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_ap_inv_pymnt_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_invoice_payments_all                                                  |
  -- | Description      : This procedure is used to extract ap_invoice_payments_all                                    |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='ACCOUNTING_EVENT_ID' ||'|'||'ACCOUNTING_DATE' ||'|'||'ACCRUAL_POSTED_FLAG' ||'|'||'AMOUNT' ||'|'||'CASH_POSTED_FLAG' ||'|'||'CHECK_ID' ||'|'||'INVOICE_ID' ||'|'||'INVOICE_PAYMENT_ID' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'PAYMENT_NUM' ||'|'||'PERIOD_NAME' ||'|'||'POSTED_FLAG' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'ACCTS_PAY_CODE_COMBINATION_ID' ||'|'||'ASSET_CODE_COMBINATION_ID' ||'|'||'CREATED_BY' ||'|'||'CREATION_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'BANK_ACCOUNT_NUM' ||'|'||'BANK_ACCOUNT_TYPE' ||'|'||'BANK_NUM' ||'|'||'DISCOUNT_LOST' ||'|'||'DISCOUNT_TAKEN' ||'|'||'EXCHANGE_DATE' ||'|'||'EXCHANGE_RATE' ||'|'||'EXCHANGE_RATE_TYPE' ||'|'||'GAIN_CODE_COMBINATION_ID' ||'|'||'INVOICE_BASE_AMOUNT' ||'|'||'LOSS_CODE_COMBINATION_ID' ||'|'||'PAYMENT_BASE_AMOUNT' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||
  'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'CASH_JE_BATCH_ID' ||'|'||'FUTURE_PAY_CODE_COMBINATION_ID' ||'|'||'FUTURE_PAY_POSTED_FLAG' ||'|'||'JE_BATCH_ID' ||'|'||'ELECTRONIC_TRANSFER_ID' ||'|'||'ASSETS_ADDITION_FLAG' ||'|'||'INVOICE_PAYMENT_TYPE' ||'|'||'OTHER_INVOICE_ID' ||'|'||'ORG_ID' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||
  'EXTERNAL_BANK_ACCOUNT_ID' ||'|'||'MRC_EXCHANGE_DATE' ||'|'||'MRC_EXCHANGE_RATE' ||'|'||'MRC_EXCHANGE_RATE_TYPE' ||'|'||'MRC_GAIN_CODE_COMBINATION_ID' ||'|'||'MRC_INVOICE_BASE_AMOUNT' ||'|'||'MRC_LOSS_CODE_COMBINATION_ID' ||'|'||'MRC_PAYMENT_BASE_AMOUNT' ||'|'||'REVERSAL_FLAG' ||'|'||'REVERSAL_INV_PMT_ID' ||'|'||'IBAN_NUMBER' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR aipa_Cur IN
    (SELECT aipa.ACCOUNTING_EVENT_ID ,
      aipa.ACCOUNTING_DATE ,
      aipa.ACCRUAL_POSTED_FLAG ,
      aipa.AMOUNT ,
      aipa.CASH_POSTED_FLAG ,
      aipa.CHECK_ID ,
      aipa.INVOICE_ID ,
      aipa.INVOICE_PAYMENT_ID ,
      aipa.LAST_UPDATED_BY ,
      aipa.LAST_UPDATE_DATE ,
      aipa.PAYMENT_NUM ,
      aipa.PERIOD_NAME ,
      aipa.POSTED_FLAG ,
      aipa.SET_OF_BOOKS_ID ,
      aipa.ACCTS_PAY_CODE_COMBINATION_ID ,
      aipa.ASSET_CODE_COMBINATION_ID ,
      aipa.CREATED_BY ,
      aipa.CREATION_DATE ,
      aipa.LAST_UPDATE_LOGIN ,
      aipa.BANK_ACCOUNT_NUM ,
      ieba.BANK_ACCOUNT_TYPE--Changed for QC Defect 27400
      ,
      aipa.BANK_NUM ,
      aipa.DISCOUNT_LOST ,
      aipa.DISCOUNT_TAKEN ,
      aipa.EXCHANGE_DATE ,
      aipa.EXCHANGE_RATE ,
      aipa.EXCHANGE_RATE_TYPE ,
      aipa.GAIN_CODE_COMBINATION_ID ,
      aipa.INVOICE_BASE_AMOUNT ,
      aipa.LOSS_CODE_COMBINATION_ID ,
      aipa.PAYMENT_BASE_AMOUNT ,
      aipa.ATTRIBUTE1 ,
      aipa.ATTRIBUTE10 ,
      aipa.ATTRIBUTE11 ,
      aipa.ATTRIBUTE12 ,
      aipa.ATTRIBUTE13 ,
      aipa.ATTRIBUTE14 ,
      aipa.ATTRIBUTE15 ,
      aipa.ATTRIBUTE2 ,
      aipa.ATTRIBUTE3 ,
      aipa.ATTRIBUTE4 ,
      aipa.ATTRIBUTE5 ,
      aipa.ATTRIBUTE6 ,
      aipa.ATTRIBUTE7 ,
      aipa.ATTRIBUTE8 ,
      aipa.ATTRIBUTE9 ,
      aipa.ATTRIBUTE_CATEGORY ,
      aipa.CASH_JE_BATCH_ID ,
      aipa.FUTURE_PAY_CODE_COMBINATION_ID ,
      aipa.FUTURE_PAY_POSTED_FLAG ,
      aipa.JE_BATCH_ID ,
      aipa.ELECTRONIC_TRANSFER_ID ,
      aipa.ASSETS_ADDITION_FLAG ,
      aipa.INVOICE_PAYMENT_TYPE ,
      aipa.OTHER_INVOICE_ID ,
      aipa.ORG_ID ,
      aipa.GLOBAL_ATTRIBUTE_CATEGORY ,
      aipa.GLOBAL_ATTRIBUTE1 ,
      aipa.GLOBAL_ATTRIBUTE2 ,
      aipa.GLOBAL_ATTRIBUTE3 ,
      aipa.GLOBAL_ATTRIBUTE4 ,
      aipa.GLOBAL_ATTRIBUTE5 ,
      aipa.GLOBAL_ATTRIBUTE6 ,
      aipa.GLOBAL_ATTRIBUTE7 ,
      aipa.GLOBAL_ATTRIBUTE8 ,
      aipa.GLOBAL_ATTRIBUTE9 ,
      aipa.GLOBAL_ATTRIBUTE10 ,
      aipa.GLOBAL_ATTRIBUTE11 ,
      aipa.GLOBAL_ATTRIBUTE12 ,
      aipa.GLOBAL_ATTRIBUTE13 ,
      aipa.GLOBAL_ATTRIBUTE14 ,
      aipa.GLOBAL_ATTRIBUTE15 ,
      aipa.GLOBAL_ATTRIBUTE16 ,
      aipa.GLOBAL_ATTRIBUTE17 ,
      aipa.GLOBAL_ATTRIBUTE18 ,
      aipa.GLOBAL_ATTRIBUTE19 ,
      aipa.GLOBAL_ATTRIBUTE20 ,
      aipa.EXTERNAL_BANK_ACCOUNT_ID ,
      aipa.MRC_EXCHANGE_DATE ,
      aipa.MRC_EXCHANGE_RATE ,
      aipa.MRC_EXCHANGE_RATE_TYPE ,
      aipa.MRC_GAIN_CODE_COMBINATION_ID ,
      aipa.MRC_INVOICE_BASE_AMOUNT ,
      aipa.MRC_LOSS_CODE_COMBINATION_ID ,
      aipa.MRC_PAYMENT_BASE_AMOUNT ,
      aipa.REVERSAL_FLAG ,
      aipa.REVERSAL_INV_PMT_ID ,
      aipa.IBAN_NUMBER
    FROM ap_invoice_payments_all aipa,
      IBY_EXT_BANK_ACCOUNTS ieba --Added for QC Defect 27400
    WHERE (TRUNC(aipa.last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(aipa.creation_date) BETWEEN ld_start_date AND ld_end_date )
    AND aipa.EXTERNAL_BANK_ACCOUNT_ID = ieba.EXT_BANK_ACCOUNT_ID(+) -- Modified Based on the Defect# 31345
    )
    LOOP
      l_data:=aipa_Cur.accounting_event_id ||'|'||aipa_Cur.ACCOUNTING_DATE ||'|'||aipa_Cur.ACCRUAL_POSTED_FLAG ||'|'||aipa_Cur.AMOUNT ||'|'||aipa_Cur.CASH_POSTED_FLAG ||'|'||aipa_Cur.CHECK_ID ||'|'||aipa_Cur.INVOICE_ID ||'|'||aipa_Cur.INVOICE_PAYMENT_ID ||'|'||aipa_Cur.LAST_UPDATED_BY ||'|'||aipa_Cur.LAST_UPDATE_DATE ||'|'||aipa_Cur.PAYMENT_NUM ||'|'||aipa_Cur.PERIOD_NAME ||'|'||aipa_Cur.POSTED_FLAG ||'|'||aipa_Cur.SET_OF_BOOKS_ID ||'|'||aipa_Cur.ACCTS_PAY_CODE_COMBINATION_ID ||'|'||aipa_Cur.ASSET_CODE_COMBINATION_ID ||'|'||aipa_Cur.CREATED_BY ||'|'||aipa_Cur.CREATION_DATE ||'|'||aipa_Cur.LAST_UPDATE_LOGIN
      --         ||'|'||aipa_Cur.BANK_ACCOUNT_NUM
      ||'|'||' ' ||'|'||aipa_Cur.BANK_ACCOUNT_TYPE
      --         ||'|'||aipa_Cur.BANK_NUM
      ||'|'||' ' ||'|'||aipa_Cur.DISCOUNT_LOST ||'|'||aipa_Cur.DISCOUNT_TAKEN ||'|'||aipa_Cur.EXCHANGE_DATE ||'|'||aipa_Cur.EXCHANGE_RATE ||'|'||aipa_Cur.EXCHANGE_RATE_TYPE ||'|'||aipa_Cur.GAIN_CODE_COMBINATION_ID ||'|'||aipa_Cur.INVOICE_BASE_AMOUNT ||'|'||aipa_Cur.LOSS_CODE_COMBINATION_ID ||'|'||aipa_Cur.PAYMENT_BASE_AMOUNT ||'|'||aipa_Cur.ATTRIBUTE1 ||'|'||aipa_Cur.ATTRIBUTE10 ||'|'||aipa_Cur.ATTRIBUTE11 ||'|'||aipa_Cur.ATTRIBUTE12 ||'|'||aipa_Cur.ATTRIBUTE13 ||'|'||aipa_Cur.ATTRIBUTE14 ||'|'||aipa_Cur.ATTRIBUTE15 ||'|'||aipa_Cur.ATTRIBUTE2 ||'|'||aipa_Cur.ATTRIBUTE3 ||'|'||aipa_Cur.ATTRIBUTE4 ||'|'||aipa_Cur.ATTRIBUTE5 ||'|'||aipa_Cur.ATTRIBUTE6 ||'|'||aipa_Cur.ATTRIBUTE7 ||'|'||aipa_Cur.ATTRIBUTE8 ||'|'||aipa_Cur.ATTRIBUTE9 ||'|'||aipa_Cur.ATTRIBUTE_CATEGORY ||'|'||aipa_Cur.CASH_JE_BATCH_ID ||'|'||aipa_Cur.FUTURE_PAY_CODE_COMBINATION_ID ||'|'||aipa_Cur.FUTURE_PAY_POSTED_FLAG ||'|'||aipa_Cur.JE_BATCH_ID ||'|'||aipa_Cur.ELECTRONIC_TRANSFER_ID ||'|'||aipa_Cur.ASSETS_ADDITION_FLAG ||
      '|'||aipa_Cur.INVOICE_PAYMENT_TYPE ||'|'||aipa_Cur.OTHER_INVOICE_ID ||'|'||aipa_Cur.ORG_ID ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE1 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE2 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE3 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE4 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE5 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE6 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE7 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE8 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE9 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE10 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE11 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE12 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE13 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE14 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE15 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE16 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE17 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE18 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE19 ||'|'||aipa_Cur.GLOBAL_ATTRIBUTE20 ||'|'||aipa_Cur.EXTERNAL_BANK_ACCOUNT_ID ||'|'||aipa_Cur.MRC_EXCHANGE_DATE ||'|'||aipa_Cur.MRC_EXCHANGE_RATE ||'|'||aipa_Cur.MRC_EXCHANGE_RATE_TYPE ||'|'||
      aipa_Cur.MRC_GAIN_CODE_COMBINATION_ID ||'|'||aipa_Cur.MRC_INVOICE_BASE_AMOUNT ||'|'||aipa_Cur.MRC_LOSS_CODE_COMBINATION_ID ||'|'||aipa_Cur.MRC_PAYMENT_BASE_AMOUNT ||'|'||aipa_Cur.REVERSAL_FLAG ||'|'||aipa_Cur.REVERSAL_INV_PMT_ID ||'|'||aipa_Cur.IBAN_NUMBER ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_invoice_payments_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_invoice_payments_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in ap_invoice_payments_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_inv_pymnt_all;
-- +===================================================================================================+
-- +===============  Extract # 7  ====================================================================+
PROCEDURE Extract_rcv_trans(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_rcv_trans.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_rcv_transactions                                               |
  -- | Description      : This procedure is used to extract rcv_transactions                                    |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='transaction_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'TRANSACTION_TYPE' ||'|'||'TRANSACTION_DATE' ||'|'||'QUANTITY' ||'|'||'UNIT_OF_MEASURE' ||'|'||'SHIPMENT_HEADER_ID' ||'|'||'SHIPMENT_LINE_ID' ||'|'||'USER_ENTERED_FLAG' ||'|'||'INTERFACE_SOURCE_CODE' ||'|'||'INTERFACE_SOURCE_LINE_ID' ||'|'||'INV_TRANSACTION_ID' ||'|'||'SOURCE_DOCUMENT_CODE' ||'|'||'DESTINATION_TYPE_CODE' ||'|'||'PRIMARY_QUANTITY' ||'|'||'PRIMARY_UNIT_OF_MEASURE' ||'|'||'UOM_CODE' ||'|'||'EMPLOYEE_ID' ||'|'||'PARENT_TRANSACTION_ID' ||'|'||'PO_HEADER_ID' ||'|'||'PO_RELEASE_ID' ||'|'||'PO_LINE_ID' ||'|'||'PO_LINE_LOCATION_ID' ||'|'||'PO_DISTRIBUTION_ID' ||'|'||'PO_REVISION_NUM' ||'|'||'REQUISITION_LINE_ID' ||'|'||'PO_UNIT_PRICE' ||'|'||'CURRENCY_CODE' ||'|'||'CURRENCY_CONVERSION_TYPE' ||'|'||
  'CURRENCY_CONVERSION_RATE' ||'|'||'CURRENCY_CONVERSION_DATE' ||'|'||'ROUTING_HEADER_ID' ||'|'||'ROUTING_STEP_ID' ||'|'||'DELIVER_TO_PERSON_ID' ||'|'||'DELIVER_TO_LOCATION_ID' ||'|'||'VENDOR_ID' ||'|'||'VENDOR_SITE_ID' ||'|'||'ORGANIZATION_ID' ||'|'||'SUBINVENTORY' ||'|'||'LOCATOR_ID' ||'|'||'WIP_ENTITY_ID' ||'|'||'WIP_LINE_ID' ||'|'||'WIP_REPETITIVE_SCHEDULE_ID' ||'|'||'WIP_OPERATION_SEQ_NUM' ||'|'||'WIP_RESOURCE_SEQ_NUM' ||'|'||'BOM_RESOURCE_ID' ||'|'||'LOCATION_ID' ||'|'||'SUBSTITUTE_UNORDERED_CODE' ||'|'||'RECEIPT_EXCEPTION_FLAG' ||'|'||'INSPECTION_STATUS_CODE' ||'|'||'ACCRUAL_STATUS_CODE' ||'|'||'INSPECTION_QUALITY_CODE' ||'|'||'VENDOR_LOT_NUM' ||'|'||'RMA_REFERENCE' ||'|'||'COMMENTS' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'
  ||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'REQ_DISTRIBUTION_ID' ||'|'||'DEPARTMENT_CODE' ||'|'||'REASON_ID' ||'|'||'DESTINATION_CONTEXT' ||'|'||'LOCATOR_ATTRIBUTE' ||'|'||'CHILD_INSPECTION_FLAG' ||'|'||'SOURCE_DOC_UNIT_OF_MEASURE' ||'|'||'SOURCE_DOC_QUANTITY' ||'|'||'INTERFACE_TRANSACTION_ID' ||'|'||'GROUP_ID' ||'|'||'MOVEMENT_ID' ||'|'||'INVOICE_ID' ||'|'||'INVOICE_STATUS_CODE' ||'|'||'QA_COLLECTION_ID' ||'|'||'MRC_CURRENCY_CONVERSION_TYPE' ||'|'||'MRC_CURRENCY_CONVERSION_DATE' ||'|'||'MRC_CURRENCY_CONVERSION_RATE' ||'|'||'COUNTRY_OF_ORIGIN_CODE' ||'|'||'MVT_STAT_STATUS' ||'|'||'QUANTITY_BILLED' ||'|'||'MATCH_FLAG' ||'|'||'AMOUNT_BILLED' ||'|'||'MATCH_OPTION' ||'|'||'OE_ORDER_HEADER_ID' ||'|'||'OE_ORDER_LINE_ID' ||'|'||'CUSTOMER_ID' ||'|'||'CUSTOMER_SITE_ID' ||'|'||'LPN_ID' ||'|'||'TRANSFER_LPN_ID' ||'|'||'MOBILE_TXN' ||'|'||'SECONDARY_QUANTITY' ||'|'||'SECONDARY_UNIT_OF_MEASURE' ||'|'||'QC_GRADE' ||'|'||'SECONDARY_UOM_CODE' ||'|'||'PA_ADDITION_FLAG' ||'|'||'CONSIGNED_FLAG' ||
  '|'||'SOURCE_TRANSACTION_NUM' ||'|'||'FROM_SUBINVENTORY' ||'|'||'FROM_LOCATOR_ID' ||'|'||'AMOUNT' ||'|'||'DROPSHIP_TYPE_CODE' ||'|'||'LPN_GROUP_ID' ||'|'||'JOB_ID' ||'|'||'TIMECARD_ID' ||'|'||'TIMECARD_OVN' ||'|'||'PROJECT_ID' ||'|'||'TASK_ID' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR rt_Cur IN
    (SELECT TRANSACTION_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      TRANSACTION_TYPE ,
      TRANSACTION_DATE ,
      QUANTITY ,
      UNIT_OF_MEASURE ,
      SHIPMENT_HEADER_ID ,
      SHIPMENT_LINE_ID ,
      USER_ENTERED_FLAG ,
      INTERFACE_SOURCE_CODE ,
      INTERFACE_SOURCE_LINE_ID ,
      INV_TRANSACTION_ID ,
      SOURCE_DOCUMENT_CODE ,
      DESTINATION_TYPE_CODE ,
      PRIMARY_QUANTITY ,
      PRIMARY_UNIT_OF_MEASURE ,
      UOM_CODE ,
      EMPLOYEE_ID ,
      PARENT_TRANSACTION_ID ,
      PO_HEADER_ID ,
      PO_RELEASE_ID ,
      PO_LINE_ID ,
      PO_LINE_LOCATION_ID ,
      PO_DISTRIBUTION_ID ,
      PO_REVISION_NUM ,
      REQUISITION_LINE_ID ,
      PO_UNIT_PRICE ,
      CURRENCY_CODE ,
      CURRENCY_CONVERSION_TYPE ,
      CURRENCY_CONVERSION_RATE ,
      CURRENCY_CONVERSION_DATE ,
      ROUTING_HEADER_ID ,
      ROUTING_STEP_ID ,
      DELIVER_TO_PERSON_ID ,
      DELIVER_TO_LOCATION_ID ,
      VENDOR_ID ,
      VENDOR_SITE_ID ,
      ORGANIZATION_ID ,
      SUBINVENTORY ,
      LOCATOR_ID ,
      WIP_ENTITY_ID ,
      WIP_LINE_ID ,
      WIP_REPETITIVE_SCHEDULE_ID ,
      WIP_OPERATION_SEQ_NUM ,
      WIP_RESOURCE_SEQ_NUM ,
      BOM_RESOURCE_ID ,
      LOCATION_ID ,
      SUBSTITUTE_UNORDERED_CODE ,
      RECEIPT_EXCEPTION_FLAG ,
      INSPECTION_STATUS_CODE ,
      ACCRUAL_STATUS_CODE ,
      INSPECTION_QUALITY_CODE ,
      VENDOR_LOT_NUM ,
      RMA_REFERENCE ,
      COMMENTS ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      REQ_DISTRIBUTION_ID ,
      DEPARTMENT_CODE ,
      REASON_ID ,
      DESTINATION_CONTEXT ,
      LOCATOR_ATTRIBUTE ,
      CHILD_INSPECTION_FLAG ,
      SOURCE_DOC_UNIT_OF_MEASURE ,
      SOURCE_DOC_QUANTITY ,
      INTERFACE_TRANSACTION_ID ,
      GROUP_ID ,
      MOVEMENT_ID ,
      INVOICE_ID ,
      INVOICE_STATUS_CODE ,
      QA_COLLECTION_ID ,
      MRC_CURRENCY_CONVERSION_TYPE ,
      MRC_CURRENCY_CONVERSION_DATE ,
      MRC_CURRENCY_CONVERSION_RATE ,
      COUNTRY_OF_ORIGIN_CODE ,
      MVT_STAT_STATUS ,
      QUANTITY_BILLED ,
      MATCH_FLAG ,
      AMOUNT_BILLED ,
      MATCH_OPTION ,
      OE_ORDER_HEADER_ID ,
      OE_ORDER_LINE_ID ,
      CUSTOMER_ID ,
      CUSTOMER_SITE_ID ,
      LPN_ID ,
      TRANSFER_LPN_ID ,
      MOBILE_TXN ,
      SECONDARY_QUANTITY ,
      SECONDARY_UNIT_OF_MEASURE ,
      QC_GRADE ,
      SECONDARY_UOM_CODE ,
      PA_ADDITION_FLAG ,
      NVL(CONSIGNED_FLAG,'N') CONSIGNED_FLAG -- QC Defct 27400.
      ,
      SOURCE_TRANSACTION_NUM ,
      FROM_SUBINVENTORY ,
      FROM_LOCATOR_ID ,
      AMOUNT ,
      DROPSHIP_TYPE_CODE ,
      LPN_GROUP_ID ,
      JOB_ID ,
      TIMECARD_ID ,
      TIMECARD_OVN ,
      PROJECT_ID ,
      TASK_ID
    FROM rcv_transactions
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=rt_Cur.transaction_id ||'|'||rt_Cur.LAST_UPDATE_DATE ||'|'||rt_Cur.LAST_UPDATED_BY ||'|'||rt_Cur.CREATION_DATE ||'|'||rt_Cur.CREATED_BY ||'|'||rt_Cur.LAST_UPDATE_LOGIN ||'|'||rt_Cur.REQUEST_ID ||'|'||rt_Cur.PROGRAM_APPLICATION_ID ||'|'||rt_Cur.PROGRAM_ID ||'|'||rt_Cur.PROGRAM_UPDATE_DATE ||'|'||rt_Cur.TRANSACTION_TYPE ||'|'||rt_Cur.TRANSACTION_DATE ||'|'||rt_Cur.QUANTITY ||'|'||rt_Cur.UNIT_OF_MEASURE ||'|'||rt_Cur.SHIPMENT_HEADER_ID ||'|'||rt_Cur.SHIPMENT_LINE_ID ||'|'||rt_Cur.USER_ENTERED_FLAG ||'|'||rt_Cur.INTERFACE_SOURCE_CODE ||'|'||rt_Cur.INTERFACE_SOURCE_LINE_ID ||'|'||rt_Cur.INV_TRANSACTION_ID ||'|'||rt_Cur.SOURCE_DOCUMENT_CODE ||'|'||rt_Cur.DESTINATION_TYPE_CODE ||'|'||rt_Cur.PRIMARY_QUANTITY ||'|'||rt_Cur.PRIMARY_UNIT_OF_MEASURE ||'|'||rt_Cur.UOM_CODE ||'|'||rt_Cur.EMPLOYEE_ID ||'|'||rt_Cur.PARENT_TRANSACTION_ID ||'|'||rt_Cur.PO_HEADER_ID ||'|'||rt_Cur.PO_RELEASE_ID ||'|'||rt_Cur.PO_LINE_ID ||'|'||rt_Cur.PO_LINE_LOCATION_ID ||'|'||rt_Cur.PO_DISTRIBUTION_ID ||
      '|'||rt_Cur.PO_REVISION_NUM ||'|'||rt_Cur.REQUISITION_LINE_ID ||'|'||rt_Cur.PO_UNIT_PRICE ||'|'||rt_Cur.CURRENCY_CODE ||'|'||rt_Cur.CURRENCY_CONVERSION_TYPE ||'|'||rt_Cur.CURRENCY_CONVERSION_RATE ||'|'||rt_Cur.CURRENCY_CONVERSION_DATE ||'|'||rt_Cur.ROUTING_HEADER_ID ||'|'||rt_Cur.ROUTING_STEP_ID ||'|'||rt_Cur.DELIVER_TO_PERSON_ID ||'|'||rt_Cur.DELIVER_TO_LOCATION_ID ||'|'||rt_Cur.VENDOR_ID ||'|'||rt_Cur.VENDOR_SITE_ID ||'|'||rt_Cur.ORGANIZATION_ID ||'|'||rt_Cur.SUBINVENTORY ||'|'||rt_Cur.LOCATOR_ID ||'|'||rt_Cur.WIP_ENTITY_ID ||'|'||rt_Cur.WIP_LINE_ID ||'|'||rt_Cur.WIP_REPETITIVE_SCHEDULE_ID ||'|'||rt_Cur.WIP_OPERATION_SEQ_NUM ||'|'||rt_Cur.WIP_RESOURCE_SEQ_NUM ||'|'||rt_Cur.BOM_RESOURCE_ID ||'|'||rt_Cur.LOCATION_ID ||'|'||rt_Cur.SUBSTITUTE_UNORDERED_CODE ||'|'||rt_Cur.RECEIPT_EXCEPTION_FLAG ||'|'||rt_Cur.INSPECTION_STATUS_CODE ||'|'||rt_Cur.ACCRUAL_STATUS_CODE ||'|'||rt_Cur.INSPECTION_QUALITY_CODE ||'|'||rt_Cur.VENDOR_LOT_NUM ||'|'||rt_Cur.RMA_REFERENCE ||'|'||rt_Cur.COMMENTS
      ||'|'||rt_Cur.ATTRIBUTE_CATEGORY ||'|'||rt_Cur.ATTRIBUTE1 ||'|'||rt_Cur.ATTRIBUTE2 ||'|'||rt_Cur.ATTRIBUTE3 ||'|'||rt_Cur.ATTRIBUTE4 ||'|'||rt_Cur.ATTRIBUTE5 ||'|'||rt_Cur.ATTRIBUTE6 ||'|'||rt_Cur.ATTRIBUTE7 ||'|'||rt_Cur.ATTRIBUTE8 ||'|'||rt_Cur.ATTRIBUTE9 ||'|'||rt_Cur.ATTRIBUTE10 ||'|'||rt_Cur.ATTRIBUTE11 ||'|'||rt_Cur.ATTRIBUTE12 ||'|'||rt_Cur.ATTRIBUTE13 ||'|'||rt_Cur.ATTRIBUTE14 ||'|'||rt_Cur.ATTRIBUTE15 ||'|'||rt_Cur.REQ_DISTRIBUTION_ID ||'|'||rt_Cur.DEPARTMENT_CODE ||'|'||rt_Cur.REASON_ID ||'|'||rt_Cur.DESTINATION_CONTEXT ||'|'||rt_Cur.LOCATOR_ATTRIBUTE ||'|'||rt_Cur.CHILD_INSPECTION_FLAG ||'|'||rt_Cur.SOURCE_DOC_UNIT_OF_MEASURE ||'|'||rt_Cur.SOURCE_DOC_QUANTITY ||'|'||rt_Cur.INTERFACE_TRANSACTION_ID ||'|'||rt_Cur.GROUP_ID ||'|'||rt_Cur.MOVEMENT_ID ||'|'||rt_Cur.INVOICE_ID ||'|'||rt_Cur.INVOICE_STATUS_CODE ||'|'||rt_Cur.QA_COLLECTION_ID ||'|'||rt_Cur.MRC_CURRENCY_CONVERSION_TYPE ||'|'||rt_Cur.MRC_CURRENCY_CONVERSION_DATE ||'|'||rt_Cur.MRC_CURRENCY_CONVERSION_RATE ||'|'
      ||rt_Cur.COUNTRY_OF_ORIGIN_CODE ||'|'||rt_Cur.MVT_STAT_STATUS ||'|'||rt_Cur.QUANTITY_BILLED ||'|'||rt_Cur.MATCH_FLAG ||'|'||rt_Cur.AMOUNT_BILLED ||'|'||rt_Cur.MATCH_OPTION ||'|'||rt_Cur.OE_ORDER_HEADER_ID ||'|'||rt_Cur.OE_ORDER_LINE_ID ||'|'||rt_Cur.CUSTOMER_ID ||'|'||rt_Cur.CUSTOMER_SITE_ID ||'|'||rt_Cur.LPN_ID ||'|'||rt_Cur.TRANSFER_LPN_ID ||'|'||rt_Cur.MOBILE_TXN ||'|'||rt_Cur.SECONDARY_QUANTITY ||'|'||rt_Cur.SECONDARY_UNIT_OF_MEASURE ||'|'||rt_Cur.QC_GRADE ||'|'||rt_Cur.SECONDARY_UOM_CODE ||'|'||rt_Cur.PA_ADDITION_FLAG ||'|'||rt_Cur.CONSIGNED_FLAG ||'|'||rt_Cur.SOURCE_TRANSACTION_NUM ||'|'||rt_Cur.FROM_SUBINVENTORY ||'|'||rt_Cur.FROM_LOCATOR_ID ||'|'||rt_Cur.AMOUNT ||'|'||rt_Cur.DROPSHIP_TYPE_CODE ||'|'||rt_Cur.LPN_GROUP_ID ||'|'||rt_Cur.JOB_ID ||'|'||rt_Cur.TIMECARD_ID ||'|'||rt_Cur.TIMECARD_OVN ||'|'||rt_Cur.PROJECT_ID ||'|'||rt_Cur.TASK_ID ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for rcv_transactions = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for rcv_transactions');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in rcv_transactions =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_rcv_trans;
-- +===================================================================================================+
-- +===============  Extract # 8  ====================================================================+
PROCEDURE Extract_rcv_ship_hdr(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_rcv_ship_hdr.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_rcv_shipment_headers                                               |
  -- | Description      : This procedure is used to extract rcv_shipment_headers                                    |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='shipment_header_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'RECEIPT_SOURCE_CODE' ||'|'||'VENDOR_ID' ||'|'||'VENDOR_SITE_ID' ||'|'||'ORGANIZATION_ID' ||'|'||'SHIPMENT_NUM' ||'|'||'RECEIPT_NUM' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'BILL_OF_LADING' ||'|'||'PACKING_SLIP' ||'|'||'SHIPPED_DATE' ||'|'||'FREIGHT_CARRIER_CODE' ||'|'||'EXPECTED_RECEIPT_DATE' ||'|'||'EMPLOYEE_ID' ||'|'||'NUM_OF_CONTAINERS' ||'|'||'WAYBILL_AIRBILL_NUM' ||'|'||'COMMENTS' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'GOVERNMENT_CONTEXT' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||
  '|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'ASN_TYPE' ||'|'||'EDI_CONTROL_NUM' ||'|'||'NOTICE_CREATION_DATE' ||'|'||'GROSS_WEIGHT' ||'|'||'GROSS_WEIGHT_UOM_CODE' ||'|'||'NET_WEIGHT' ||'|'||'NET_WEIGHT_UOM_CODE' ||'|'||'TAR_WEIGHT' ||'|'||'TAR_WEIGHT_UOM_CODE' ||'|'||'PACKAGING_CODE' ||'|'||'CARRIER_METHOD' ||'|'||'CARRIER_EQUIPMENT' ||'|'||'CARRIER_EQUIPMENT_NUM' ||'|'||'CARRIER_EQUIPMENT_ALPHA' ||'|'||'SPECIAL_HANDLING_CODE' ||'|'||'HAZARD_CODE' ||'|'||'HAZARD_CLASS' ||'|'||'HAZARD_DESCRIPTION' ||'|'||'FREIGHT_TERMS' ||'|'||'FREIGHT_BILL_NUMBER' ||'|'||'INVOICE_NUM' ||'|'||'INVOICE_DATE' ||'|'||'INVOICE_AMOUNT' ||'|'||'TAX_NAME' ||'|'||'TAX_AMOUNT' ||'|'||'FREIGHT_AMOUNT' ||'|'||'INVOICE_STATUS_CODE' ||'|'||'ASN_STATUS' ||'|'||'CURRENCY_CODE' ||'|'||'CONVERSION_RATE_TYPE' ||'|'||'CONVERSION_RATE' ||'|'||'CONVERSION_DATE' ||'|'||'PAYMENT_TERMS_ID' ||'|'||'MRC_CONVERSION_RATE_TYPE' ||'|'||'MRC_CONVERSION_DATE' ||'|'||'MRC_CONVERSION_RATE' ||'|'||'SHIP_TO_ORG_ID' ||'|'||
  'CUSTOMER_ID' ||'|'||'CUSTOMER_SITE_ID' ||'|'||'REMIT_TO_SITE_ID' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR rsh_Cur IN
    (SELECT SHIPMENT_HEADER_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      RECEIPT_SOURCE_CODE ,
      VENDOR_ID ,
      VENDOR_SITE_ID ,
      ORGANIZATION_ID ,
      SHIPMENT_NUM ,
      RECEIPT_NUM ,
      SHIP_TO_LOCATION_ID ,
      BILL_OF_LADING ,
      PACKING_SLIP ,
      SHIPPED_DATE ,
      FREIGHT_CARRIER_CODE ,
      EXPECTED_RECEIPT_DATE ,
      EMPLOYEE_ID ,
      NUM_OF_CONTAINERS ,
      WAYBILL_AIRBILL_NUM ,
      COMMENTS ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      USSGL_TRANSACTION_CODE ,
      GOVERNMENT_CONTEXT ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      ASN_TYPE ,
      EDI_CONTROL_NUM ,
      NOTICE_CREATION_DATE ,
      GROSS_WEIGHT ,
      GROSS_WEIGHT_UOM_CODE ,
      NET_WEIGHT ,
      NET_WEIGHT_UOM_CODE ,
      TAR_WEIGHT ,
      TAR_WEIGHT_UOM_CODE ,
      PACKAGING_CODE ,
      CARRIER_METHOD ,
      CARRIER_EQUIPMENT ,
      CARRIER_EQUIPMENT_NUM ,
      CARRIER_EQUIPMENT_ALPHA ,
      SPECIAL_HANDLING_CODE ,
      HAZARD_CODE ,
      HAZARD_CLASS ,
      HAZARD_DESCRIPTION ,
      FREIGHT_TERMS ,
      FREIGHT_BILL_NUMBER ,
      INVOICE_NUM ,
      INVOICE_DATE ,
      INVOICE_AMOUNT ,
      TAX_NAME ,
      TAX_AMOUNT ,
      FREIGHT_AMOUNT ,
      INVOICE_STATUS_CODE ,
      ASN_STATUS ,
      CURRENCY_CODE ,
      CONVERSION_RATE_TYPE ,
      CONVERSION_RATE ,
      CONVERSION_DATE ,
      PAYMENT_TERMS_ID ,
      MRC_CONVERSION_RATE_TYPE ,
      MRC_CONVERSION_DATE ,
      MRC_CONVERSION_RATE ,
      SHIP_TO_ORG_ID ,
      CUSTOMER_ID ,
      CUSTOMER_SITE_ID ,
      REMIT_TO_SITE_ID
    FROM rcv_shipment_headers
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=rsh_Cur.shipment_header_id ||'|'||rsh_Cur.LAST_UPDATE_DATE ||'|'||rsh_Cur.LAST_UPDATED_BY ||'|'||rsh_Cur.CREATION_DATE ||'|'||rsh_Cur.CREATED_BY ||'|'||rsh_Cur.LAST_UPDATE_LOGIN ||'|'||rsh_Cur.RECEIPT_SOURCE_CODE ||'|'||rsh_Cur.VENDOR_ID ||'|'||rsh_Cur.VENDOR_SITE_ID ||'|'||rsh_Cur.ORGANIZATION_ID ||'|'||rsh_Cur.SHIPMENT_NUM ||'|'||rsh_Cur.RECEIPT_NUM ||'|'||rsh_Cur.SHIP_TO_LOCATION_ID ||'|'||rsh_Cur.BILL_OF_LADING ||'|'||rsh_Cur.PACKING_SLIP ||'|'||rsh_Cur.SHIPPED_DATE ||'|'||rsh_Cur.FREIGHT_CARRIER_CODE ||'|'||rsh_Cur.EXPECTED_RECEIPT_DATE ||'|'||rsh_Cur.EMPLOYEE_ID ||'|'||rsh_Cur.NUM_OF_CONTAINERS ||'|'||rsh_Cur.WAYBILL_AIRBILL_NUM ||'|'||rsh_Cur.COMMENTS ||'|'||rsh_Cur.ATTRIBUTE_CATEGORY ||'|'||rsh_Cur.ATTRIBUTE1 ||'|'||rsh_Cur.ATTRIBUTE2 ||'|'||rsh_Cur.ATTRIBUTE3 ||'|'||rsh_Cur.ATTRIBUTE4 ||'|'||rsh_Cur.ATTRIBUTE5 ||'|'||rsh_Cur.ATTRIBUTE6 ||'|'||rsh_Cur.ATTRIBUTE7 ||'|'||rsh_Cur.ATTRIBUTE8 ||'|'||rsh_Cur.ATTRIBUTE9 ||'|'||rsh_Cur.ATTRIBUTE10 ||'|'||
      rsh_Cur.ATTRIBUTE11 ||'|'||rsh_Cur.ATTRIBUTE12 ||'|'||rsh_Cur.ATTRIBUTE13 ||'|'||rsh_Cur.ATTRIBUTE14 ||'|'||rsh_Cur.ATTRIBUTE15 ||'|'||rsh_Cur.USSGL_TRANSACTION_CODE ||'|'||rsh_Cur.GOVERNMENT_CONTEXT ||'|'||rsh_Cur.REQUEST_ID ||'|'||rsh_Cur.PROGRAM_APPLICATION_ID ||'|'||rsh_Cur.PROGRAM_ID ||'|'||rsh_Cur.PROGRAM_UPDATE_DATE ||'|'||rsh_Cur.ASN_TYPE ||'|'||rsh_Cur.EDI_CONTROL_NUM ||'|'||rsh_Cur.NOTICE_CREATION_DATE ||'|'||rsh_Cur.GROSS_WEIGHT ||'|'||rsh_Cur.GROSS_WEIGHT_UOM_CODE ||'|'||rsh_Cur.NET_WEIGHT ||'|'||rsh_Cur.NET_WEIGHT_UOM_CODE ||'|'||rsh_Cur.TAR_WEIGHT ||'|'||rsh_Cur.TAR_WEIGHT_UOM_CODE ||'|'||rsh_Cur.PACKAGING_CODE ||'|'||rsh_Cur.CARRIER_METHOD ||'|'||rsh_Cur.CARRIER_EQUIPMENT ||'|'||rsh_Cur.CARRIER_EQUIPMENT_NUM ||'|'||rsh_Cur.CARRIER_EQUIPMENT_ALPHA ||'|'||rsh_Cur.SPECIAL_HANDLING_CODE ||'|'||rsh_Cur.HAZARD_CODE ||'|'||rsh_Cur.HAZARD_CLASS ||'|'||rsh_Cur.HAZARD_DESCRIPTION ||'|'||rsh_Cur.FREIGHT_TERMS ||'|'||rsh_Cur.FREIGHT_BILL_NUMBER ||'|'||rsh_Cur.INVOICE_NUM ||
      '|'||rsh_Cur.INVOICE_DATE ||'|'||rsh_Cur.INVOICE_AMOUNT ||'|'||rsh_Cur.TAX_NAME ||'|'||rsh_Cur.TAX_AMOUNT ||'|'||rsh_Cur.FREIGHT_AMOUNT ||'|'||rsh_Cur.INVOICE_STATUS_CODE ||'|'||rsh_Cur.ASN_STATUS ||'|'||rsh_Cur.CURRENCY_CODE ||'|'||rsh_Cur.CONVERSION_RATE_TYPE ||'|'||rsh_Cur.CONVERSION_RATE ||'|'||rsh_Cur.CONVERSION_DATE ||'|'||rsh_Cur.PAYMENT_TERMS_ID ||'|'||rsh_Cur.MRC_CONVERSION_RATE_TYPE ||'|'||rsh_Cur.MRC_CONVERSION_DATE ||'|'||rsh_Cur.MRC_CONVERSION_RATE ||'|'||rsh_Cur.SHIP_TO_ORG_ID ||'|'||rsh_Cur.CUSTOMER_ID ||'|'||rsh_Cur.CUSTOMER_SITE_ID ||'|'||rsh_Cur.REMIT_TO_SITE_ID ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for rcv_shipment_headers = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for rcv_shipment_headers');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in rcv_shipment_headers =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_rcv_ship_hdr;
-- +===================================================================================================+
-- +===============  Extract # 9  ====================================================================+
PROCEDURE Extract_rcv_ship_line(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_rcv_ship_line.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_rcv_shipment_lines                                               |
  -- | Description      : This procedure is used to extract rcv_shipment_lines                                    |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='shipment_line_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'SHIPMENT_HEADER_ID' ||'|'||'LINE_NUM' ||'|'||'CATEGORY_ID' ||'|'||'QUANTITY_SHIPPED' ||'|'||'QUANTITY_RECEIVED' ||'|'||'UNIT_OF_MEASURE' ||'|'||'ITEM_DESCRIPTION' ||'|'||'ITEM_ID' ||'|'||'ITEM_REVISION' ||'|'||'VENDOR_ITEM_NUM' ||'|'||'VENDOR_LOT_NUM' ||'|'||'UOM_CONVERSION_RATE' ||'|'||'SHIPMENT_LINE_STATUS_CODE' ||'|'||'SOURCE_DOCUMENT_CODE' ||'|'||'PO_HEADER_ID' ||'|'||'PO_RELEASE_ID' ||'|'||'PO_LINE_ID' ||'|'||'PO_LINE_LOCATION_ID' ||'|'||'PO_DISTRIBUTION_ID' ||'|'||'REQUISITION_LINE_ID' ||'|'||'REQ_DISTRIBUTION_ID' ||'|'||'ROUTING_HEADER_ID' ||'|'||'PACKING_SLIP' ||'|'||'FROM_ORGANIZATION_ID' ||'|'||'DELIVER_TO_PERSON_ID' ||'|'||'EMPLOYEE_ID' ||'|'||'DESTINATION_TYPE_CODE' ||'|'||'TO_ORGANIZATION_ID' ||'|'||'TO_SUBINVENTORY' ||'|'||'LOCATOR_ID' ||'|'||'DELIVER_TO_LOCATION_ID' ||'|'||'CHARGE_ACCOUNT_ID' ||'|'||
  'TRANSPORTATION_ACCOUNT_ID' ||'|'||'SHIPMENT_UNIT_PRICE' ||'|'||'TRANSFER_COST' ||'|'||'TRANSPORTATION_COST' ||'|'||'COMMENTS' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'REASON_ID' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'GOVERNMENT_CONTEXT' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'DESTINATION_CONTEXT' ||'|'||'PRIMARY_UNIT_OF_MEASURE' ||'|'||'EXCESS_TRANSPORT_REASON' ||'|'||'EXCESS_TRANSPORT_RESPONSIBLE' ||'|'||'EXCESS_TRANSPORT_AUTH_NUM' ||'|'||'ASN_LINE_FLAG' ||'|'||'ORIGINAL_ASN_PARENT_LINE_ID' ||'|'||'ORIGINAL_ASN_LINE_FLAG' ||'|'||'VENDOR_CUM_SHIPPED_QUANTITY' ||'|'||'NOTICE_UNIT_PRICE' ||'|'||'TAX_NAME' ||'|'||
  'TAX_AMOUNT' ||'|'||'INVOICE_STATUS_CODE' ||'|'||'CUM_COMPARISON_FLAG' ||'|'||'CONTAINER_NUM' ||'|'||'TRUCK_NUM' ||'|'||'BAR_CODE_LABEL' ||'|'||'TRANSFER_PERCENTAGE' ||'|'||'MRC_SHIPMENT_UNIT_PRICE' ||'|'||'MRC_TRANSFER_COST' ||'|'||'MRC_TRANSPORTATION_COST' ||'|'||'MRC_NOTICE_UNIT_PRICE' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'COUNTRY_OF_ORIGIN_CODE' ||'|'||'OE_ORDER_HEADER_ID' ||'|'||'OE_ORDER_LINE_ID' ||'|'||'CUSTOMER_ITEM_NUM' ||'|'||'COST_GROUP_ID' ||'|'||'SECONDARY_QUANTITY_SHIPPED' ||'|'||'SECONDARY_QUANTITY_RECEIVED' ||'|'||'SECONDARY_UNIT_OF_MEASURE' ||'|'||'QC_GRADE' ||'|'||'MMT_TRANSACTION_ID' ||'|'||'ASN_LPN_ID' ||'|'||'AMOUNT' ||'|'||'AMOUNT_RECEIVED' ||'|'||'JOB_ID' ||'|'||'TIMECARD_ID' ||'|'||'TIMECARD_OVN' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR rsl_Cur IN
    (SELECT SHIPMENT_LINE_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      SHIPMENT_HEADER_ID ,
      LINE_NUM ,
      CATEGORY_ID ,
      QUANTITY_SHIPPED ,
      QUANTITY_RECEIVED ,
      UNIT_OF_MEASURE ,
      ITEM_DESCRIPTION ,
      ITEM_ID ,
      ITEM_REVISION ,
      VENDOR_ITEM_NUM ,
      VENDOR_LOT_NUM ,
      UOM_CONVERSION_RATE ,
      SHIPMENT_LINE_STATUS_CODE ,
      SOURCE_DOCUMENT_CODE ,
      PO_HEADER_ID ,
      PO_RELEASE_ID ,
      PO_LINE_ID ,
      PO_LINE_LOCATION_ID ,
      PO_DISTRIBUTION_ID ,
      REQUISITION_LINE_ID ,
      REQ_DISTRIBUTION_ID ,
      ROUTING_HEADER_ID ,
      PACKING_SLIP ,
      FROM_ORGANIZATION_ID ,
      DELIVER_TO_PERSON_ID ,
      EMPLOYEE_ID ,
      DESTINATION_TYPE_CODE ,
      TO_ORGANIZATION_ID ,
      TO_SUBINVENTORY ,
      LOCATOR_ID ,
      DELIVER_TO_LOCATION_ID ,
      CHARGE_ACCOUNT_ID ,
      TRANSPORTATION_ACCOUNT_ID ,
      SHIPMENT_UNIT_PRICE ,
      TRANSFER_COST ,
      TRANSPORTATION_COST ,
      COMMENTS ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      REASON_ID ,
      USSGL_TRANSACTION_CODE ,
      GOVERNMENT_CONTEXT ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      DESTINATION_CONTEXT ,
      PRIMARY_UNIT_OF_MEASURE ,
      EXCESS_TRANSPORT_REASON ,
      EXCESS_TRANSPORT_RESPONSIBLE ,
      EXCESS_TRANSPORT_AUTH_NUM ,
      ASN_LINE_FLAG ,
      ORIGINAL_ASN_PARENT_LINE_ID ,
      ORIGINAL_ASN_LINE_FLAG ,
      VENDOR_CUM_SHIPPED_QUANTITY ,
      NOTICE_UNIT_PRICE ,
      TAX_NAME ,
      TAX_AMOUNT ,
      INVOICE_STATUS_CODE ,
      CUM_COMPARISON_FLAG ,
      CONTAINER_NUM ,
      TRUCK_NUM ,
      BAR_CODE_LABEL ,
      TRANSFER_PERCENTAGE ,
      MRC_SHIPMENT_UNIT_PRICE ,
      MRC_TRANSFER_COST ,
      MRC_TRANSPORTATION_COST ,
      MRC_NOTICE_UNIT_PRICE ,
      SHIP_TO_LOCATION_ID ,
      COUNTRY_OF_ORIGIN_CODE ,
      OE_ORDER_HEADER_ID ,
      OE_ORDER_LINE_ID ,
      CUSTOMER_ITEM_NUM ,
      COST_GROUP_ID ,
      SECONDARY_QUANTITY_SHIPPED ,
      SECONDARY_QUANTITY_RECEIVED ,
      SECONDARY_UNIT_OF_MEASURE ,
      QC_GRADE ,
      MMT_TRANSACTION_ID ,
      ASN_LPN_ID ,
      AMOUNT ,
      AMOUNT_RECEIVED ,
      JOB_ID ,
      TIMECARD_ID ,
      TIMECARD_OVN
    FROM rcv_shipment_lines
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=rsl_Cur.shipment_line_id ||'|'||rsl_Cur.LAST_UPDATE_DATE ||'|'||rsl_Cur.LAST_UPDATED_BY ||'|'||rsl_Cur.CREATION_DATE ||'|'||rsl_Cur.CREATED_BY ||'|'||rsl_Cur.LAST_UPDATE_LOGIN ||'|'||rsl_Cur.SHIPMENT_HEADER_ID ||'|'||rsl_Cur.LINE_NUM ||'|'||rsl_Cur.CATEGORY_ID ||'|'||rsl_Cur.QUANTITY_SHIPPED ||'|'||rsl_Cur.QUANTITY_RECEIVED ||'|'||rsl_Cur.UNIT_OF_MEASURE ||'|'||rsl_Cur.ITEM_DESCRIPTION ||'|'||rsl_Cur.ITEM_ID ||'|'||rsl_Cur.ITEM_REVISION ||'|'||rsl_Cur.VENDOR_ITEM_NUM ||'|'||rsl_Cur.VENDOR_LOT_NUM ||'|'||rsl_Cur.UOM_CONVERSION_RATE ||'|'||rsl_Cur.SHIPMENT_LINE_STATUS_CODE ||'|'||rsl_Cur.SOURCE_DOCUMENT_CODE ||'|'||rsl_Cur.PO_HEADER_ID ||'|'||rsl_Cur.PO_RELEASE_ID ||'|'||rsl_Cur.PO_LINE_ID ||'|'||rsl_Cur.PO_LINE_LOCATION_ID ||'|'||rsl_Cur.PO_DISTRIBUTION_ID ||'|'||rsl_Cur.REQUISITION_LINE_ID ||'|'||rsl_Cur.REQ_DISTRIBUTION_ID ||'|'||rsl_Cur.ROUTING_HEADER_ID ||'|'||rsl_Cur.PACKING_SLIP ||'|'||rsl_Cur.FROM_ORGANIZATION_ID ||'|'||rsl_Cur.DELIVER_TO_PERSON_ID ||'|'||
      rsl_Cur.EMPLOYEE_ID ||'|'||rsl_Cur.DESTINATION_TYPE_CODE ||'|'||rsl_Cur.TO_ORGANIZATION_ID ||'|'||rsl_Cur.TO_SUBINVENTORY ||'|'||rsl_Cur.LOCATOR_ID ||'|'||rsl_Cur.DELIVER_TO_LOCATION_ID ||'|'||rsl_Cur.CHARGE_ACCOUNT_ID ||'|'||rsl_Cur.TRANSPORTATION_ACCOUNT_ID ||'|'||rsl_Cur.SHIPMENT_UNIT_PRICE ||'|'||rsl_Cur.TRANSFER_COST ||'|'||rsl_Cur.TRANSPORTATION_COST ||'|'||rsl_Cur.COMMENTS ||'|'||rsl_Cur.ATTRIBUTE_CATEGORY ||'|'||rsl_Cur.ATTRIBUTE1 ||'|'||rsl_Cur.ATTRIBUTE2 ||'|'||rsl_Cur.ATTRIBUTE3 ||'|'||rsl_Cur.ATTRIBUTE4 ||'|'||rsl_Cur.ATTRIBUTE5 ||'|'||rsl_Cur.ATTRIBUTE6 ||'|'||rsl_Cur.ATTRIBUTE7 ||'|'||rsl_Cur.ATTRIBUTE8 ||'|'||rsl_Cur.ATTRIBUTE9 ||'|'||rsl_Cur.ATTRIBUTE10 ||'|'||rsl_Cur.ATTRIBUTE11 ||'|'||rsl_Cur.ATTRIBUTE12 ||'|'||rsl_Cur.ATTRIBUTE13 ||'|'||rsl_Cur.ATTRIBUTE14 ||'|'||rsl_Cur.ATTRIBUTE15 ||'|'||rsl_Cur.REASON_ID ||'|'||rsl_Cur.USSGL_TRANSACTION_CODE ||'|'||rsl_Cur.GOVERNMENT_CONTEXT ||'|'||rsl_Cur.REQUEST_ID ||'|'||rsl_Cur.PROGRAM_APPLICATION_ID ||'|'||
      rsl_Cur.PROGRAM_ID ||'|'||rsl_Cur.PROGRAM_UPDATE_DATE ||'|'||rsl_Cur.DESTINATION_CONTEXT ||'|'||rsl_Cur.PRIMARY_UNIT_OF_MEASURE ||'|'||rsl_Cur.EXCESS_TRANSPORT_REASON ||'|'||rsl_Cur.EXCESS_TRANSPORT_RESPONSIBLE ||'|'||rsl_Cur.EXCESS_TRANSPORT_AUTH_NUM ||'|'||rsl_Cur.ASN_LINE_FLAG ||'|'||rsl_Cur.ORIGINAL_ASN_PARENT_LINE_ID ||'|'||rsl_Cur.ORIGINAL_ASN_LINE_FLAG ||'|'||rsl_Cur.VENDOR_CUM_SHIPPED_QUANTITY ||'|'||rsl_Cur.NOTICE_UNIT_PRICE ||'|'||rsl_Cur.TAX_NAME ||'|'||rsl_Cur.TAX_AMOUNT ||'|'||rsl_Cur.INVOICE_STATUS_CODE ||'|'||rsl_Cur.CUM_COMPARISON_FLAG ||'|'||rsl_Cur.CONTAINER_NUM ||'|'||rsl_Cur.TRUCK_NUM ||'|'||rsl_Cur.BAR_CODE_LABEL ||'|'||rsl_Cur.TRANSFER_PERCENTAGE ||'|'||rsl_Cur.MRC_SHIPMENT_UNIT_PRICE ||'|'||rsl_Cur.MRC_TRANSFER_COST ||'|'||rsl_Cur.MRC_TRANSPORTATION_COST ||'|'||rsl_Cur.MRC_NOTICE_UNIT_PRICE ||'|'||rsl_Cur.SHIP_TO_LOCATION_ID ||'|'||rsl_Cur.COUNTRY_OF_ORIGIN_CODE ||'|'||rsl_Cur.OE_ORDER_HEADER_ID ||'|'||rsl_Cur.OE_ORDER_LINE_ID ||'|'||
      rsl_Cur.CUSTOMER_ITEM_NUM ||'|'||rsl_Cur.COST_GROUP_ID ||'|'||rsl_Cur.SECONDARY_QUANTITY_SHIPPED ||'|'||rsl_Cur.SECONDARY_QUANTITY_RECEIVED ||'|'||rsl_Cur.SECONDARY_UNIT_OF_MEASURE ||'|'||rsl_Cur.QC_GRADE ||'|'||rsl_Cur.MMT_TRANSACTION_ID ||'|'||rsl_Cur.ASN_LPN_ID ||'|'||rsl_Cur.AMOUNT ||'|'||rsl_Cur.AMOUNT_RECEIVED ||'|'||rsl_Cur.JOB_ID ||'|'||rsl_Cur.TIMECARD_ID ||'|'||rsl_Cur.TIMECARD_OVN ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for rcv_shipment_lines = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for rcv_shipment_lines');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in rcv_shipment_lines =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_rcv_ship_line;
-- +===================================================================================================+
-- +===============  Extract # 10  ====================================================================+
PROCEDURE Extract_po_line_loc_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_line_loc_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_line_locations_all                                                |
  -- | Description      : This procedure is used to extract po_line_locations_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='line_location_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'PO_HEADER_ID' ||'|'||'PO_LINE_ID' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'QUANTITY' ||'|'||'QUANTITY_RECEIVED' ||'|'||'QUANTITY_ACCEPTED' ||'|'||'QUANTITY_REJECTED' ||'|'||'QUANTITY_BILLED' ||'|'||'QUANTITY_CANCELLED' ||'|'||'UNIT_MEAS_LOOKUP_CODE' ||'|'||'PO_RELEASE_ID' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'SHIP_VIA_LOOKUP_CODE' ||'|'||'NEED_BY_DATE' ||'|'||'PROMISED_DATE' ||'|'||'LAST_ACCEPT_DATE' ||'|'||'PRICE_OVERRIDE' ||'|'||'ENCUMBERED_FLAG' ||'|'||'ENCUMBERED_DATE' ||'|'||'UNENCUMBERED_QUANTITY' ||'|'||'FOB_LOOKUP_CODE' ||'|'||'FREIGHT_TERMS_LOOKUP_CODE' ||'|'||'TAXABLE_FLAG' ||'|'||'TAX_NAME' ||'|'||'ESTIMATED_TAX_AMOUNT' ||'|'||'FROM_HEADER_ID' ||'|'||'FROM_LINE_ID' ||'|'||'FROM_LINE_LOCATION_ID' ||'|'||'START_DATE' ||'|'||'END_DATE' ||'|'||'LEAD_TIME' ||'|'||'LEAD_TIME_UNIT' ||'|'||'PRICE_DISCOUNT' ||'|'||'TERMS_ID' ||'|'||'APPROVED_FLAG' ||'|'||
  'APPROVED_DATE' ||'|'||'CLOSED_FLAG' ||'|'||'CANCEL_FLAG' ||'|'||'CANCELLED_BY' ||'|'||'CANCEL_DATE' ||'|'||'CANCEL_REASON' ||'|'||'FIRM_STATUS_LOOKUP_CODE' ||'|'||'FIRM_DATE' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'UNIT_OF_MEASURE_CLASS' ||'|'||'ENCUMBER_NOW' ||'|'||'INSPECTION_REQUIRED_FLAG' ||'|'||'RECEIPT_REQUIRED_FLAG' ||'|'||'QTY_RCV_TOLERANCE' ||'|'||'QTY_RCV_EXCEPTION_CODE' ||'|'||'ENFORCE_SHIP_TO_LOCATION_CODE' ||'|'||'ALLOW_SUBSTITUTE_RECEIPTS_FLAG' ||'|'||'DAYS_EARLY_RECEIPT_ALLOWED' ||'|'||'DAYS_LATE_RECEIPT_ALLOWED' ||'|'||'RECEIPT_DAYS_EXCEPTION_CODE' ||'|'||'INVOICE_CLOSE_TOLERANCE' ||'|'||'RECEIVE_CLOSE_TOLERANCE' ||'|'||'SHIP_TO_ORGANIZATION_ID' ||'|'||'SHIPMENT_NUM'
  ||'|'||'SOURCE_SHIPMENT_ID' ||'|'||'SHIPMENT_TYPE' ||'|'||'CLOSED_CODE' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'GOVERNMENT_CONTEXT' ||'|'||'RECEIVING_ROUTING_ID' ||'|'||'ACCRUE_ON_RECEIPT_FLAG' ||'|'||'CLOSED_REASON' ||'|'||'CLOSED_DATE' ||'|'||'CLOSED_BY' ||'|'||'ORG_ID' ||'|'||'QUANTITY_SHIPPED' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||
  'COUNTRY_OF_ORIGIN_CODE' ||'|'||'TAX_USER_OVERRIDE_FLAG' ||'|'||'MATCH_OPTION' ||'|'||'TAX_CODE_ID' ||'|'||'CALCULATE_TAX_FLAG' ||'|'||'CHANGE_PROMISED_DATE_REASON' ||'|'||'NOTE_TO_RECEIVER' ||'|'||'SECONDARY_QUANTITY' ||'|'||'SECONDARY_UNIT_OF_MEASURE' ||'|'||'PREFERRED_GRADE' ||'|'||'SECONDARY_QUANTITY_RECEIVED' ||'|'||'SECONDARY_QUANTITY_ACCEPTED' ||'|'||'SECONDARY_QUANTITY_REJECTED' ||'|'||'SECONDARY_QUANTITY_CANCELLED' ||'|'||'VMI_FLAG' ||'|'||'CONSIGNED_FLAG' ||'|'||'RETROACTIVE_DATE' ||'|'||'SUPPLIER_ORDER_LINE_NUMBER' ||'|'||'AMOUNT' ||'|'||'AMOUNT_RECEIVED' ||'|'||'AMOUNT_BILLED' ||'|'||'AMOUNT_CANCELLED' ||'|'||'AMOUNT_REJECTED' ||'|'||'AMOUNT_ACCEPTED' ||'|'||'DROP_SHIP_FLAG' ||'|'||'SALES_ORDER_UPDATE_DATE' ||'|'||'TRANSACTION_FLOW_HEADER_ID' ||'|'||'FINAL_MATCH_FLAG' ||'|'||'MANUAL_PRICE_CHANGE_FLAG' ||'|'||'SHIPMENT_CLOSED_DATE' ||'|'||'CLOSED_FOR_RECEIVING_DATE' ||'|'||'CLOSED_FOR_INVOICE_DATE' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR plla_Cur IN
    (SELECT LINE_LOCATION_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      PO_HEADER_ID ,
      PO_LINE_ID ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      QUANTITY ,
      QUANTITY_RECEIVED ,
      QUANTITY_ACCEPTED ,
      QUANTITY_REJECTED ,
      QUANTITY_BILLED ,
      QUANTITY_CANCELLED ,
      UNIT_MEAS_LOOKUP_CODE ,
      PO_RELEASE_ID ,
      SHIP_TO_LOCATION_ID ,
      SHIP_VIA_LOOKUP_CODE ,
      NEED_BY_DATE ,
      PROMISED_DATE ,
      LAST_ACCEPT_DATE ,
      PRICE_OVERRIDE ,
      ENCUMBERED_FLAG ,
      ENCUMBERED_DATE ,
      UNENCUMBERED_QUANTITY ,
      FOB_LOOKUP_CODE ,
      FREIGHT_TERMS_LOOKUP_CODE ,
      TAXABLE_FLAG ,
      TAX_NAME ,
      ESTIMATED_TAX_AMOUNT ,
      FROM_HEADER_ID ,
      FROM_LINE_ID ,
      FROM_LINE_LOCATION_ID ,
      START_DATE ,
      END_DATE ,
      LEAD_TIME ,
      LEAD_TIME_UNIT ,
      PRICE_DISCOUNT ,
      TERMS_ID ,
      APPROVED_FLAG ,
      APPROVED_DATE ,
      CLOSED_FLAG ,
      CANCEL_FLAG ,
      CANCELLED_BY ,
      CANCEL_DATE ,
      CANCEL_REASON ,
      FIRM_STATUS_LOOKUP_CODE ,
      FIRM_DATE ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      UNIT_OF_MEASURE_CLASS ,
      ENCUMBER_NOW ,
      INSPECTION_REQUIRED_FLAG ,
      RECEIPT_REQUIRED_FLAG ,
      QTY_RCV_TOLERANCE ,
      QTY_RCV_EXCEPTION_CODE ,
      ENFORCE_SHIP_TO_LOCATION_CODE ,
      ALLOW_SUBSTITUTE_RECEIPTS_FLAG ,
      DAYS_EARLY_RECEIPT_ALLOWED ,
      DAYS_LATE_RECEIPT_ALLOWED ,
      RECEIPT_DAYS_EXCEPTION_CODE ,
      INVOICE_CLOSE_TOLERANCE ,
      RECEIVE_CLOSE_TOLERANCE ,
      SHIP_TO_ORGANIZATION_ID ,
      SHIPMENT_NUM ,
      SOURCE_SHIPMENT_ID ,
      SHIPMENT_TYPE ,
      CLOSED_CODE ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      USSGL_TRANSACTION_CODE ,
      GOVERNMENT_CONTEXT ,
      RECEIVING_ROUTING_ID ,
      ACCRUE_ON_RECEIPT_FLAG ,
      CLOSED_REASON ,
      CLOSED_DATE ,
      CLOSED_BY ,
      ORG_ID ,
      QUANTITY_SHIPPED ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      COUNTRY_OF_ORIGIN_CODE ,
      TAX_USER_OVERRIDE_FLAG ,
      MATCH_OPTION ,
      TAX_CODE_ID ,
      CALCULATE_TAX_FLAG ,
      CHANGE_PROMISED_DATE_REASON ,
      NOTE_TO_RECEIVER ,
      SECONDARY_QUANTITY ,
      SECONDARY_UNIT_OF_MEASURE ,
      PREFERRED_GRADE ,
      SECONDARY_QUANTITY_RECEIVED ,
      SECONDARY_QUANTITY_ACCEPTED ,
      SECONDARY_QUANTITY_REJECTED ,
      SECONDARY_QUANTITY_CANCELLED ,
      VMI_FLAG ,
      CONSIGNED_FLAG ,
      RETROACTIVE_DATE ,
      SUPPLIER_ORDER_LINE_NUMBER ,
      AMOUNT ,
      AMOUNT_RECEIVED ,
      AMOUNT_BILLED ,
      AMOUNT_CANCELLED ,
      AMOUNT_REJECTED ,
      AMOUNT_ACCEPTED ,
      DROP_SHIP_FLAG ,
      SALES_ORDER_UPDATE_DATE ,
      TRANSACTION_FLOW_HEADER_ID ,
      FINAL_MATCH_FLAG ,
      MANUAL_PRICE_CHANGE_FLAG ,
      SHIPMENT_CLOSED_DATE ,
      CLOSED_FOR_RECEIVING_DATE ,
      CLOSED_FOR_INVOICE_DATE
    FROM po_line_locations_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=plla_Cur.line_location_id ||'|'||plla_Cur.LAST_UPDATE_DATE ||'|'||plla_Cur.LAST_UPDATED_BY ||'|'||plla_Cur.PO_HEADER_ID ||'|'||plla_Cur.PO_LINE_ID ||'|'||plla_Cur.LAST_UPDATE_LOGIN ||'|'||plla_Cur.CREATION_DATE ||'|'||plla_Cur.CREATED_BY ||'|'||plla_Cur.QUANTITY ||'|'||plla_Cur.QUANTITY_RECEIVED ||'|'||plla_Cur.QUANTITY_ACCEPTED ||'|'||plla_Cur.QUANTITY_REJECTED ||'|'||plla_Cur.QUANTITY_BILLED ||'|'||plla_Cur.QUANTITY_CANCELLED ||'|'||plla_Cur.UNIT_MEAS_LOOKUP_CODE ||'|'||plla_Cur.PO_RELEASE_ID ||'|'||plla_Cur.SHIP_TO_LOCATION_ID ||'|'||plla_Cur.SHIP_VIA_LOOKUP_CODE ||'|'||plla_Cur.NEED_BY_DATE ||'|'||plla_Cur.PROMISED_DATE ||'|'||plla_Cur.LAST_ACCEPT_DATE ||'|'||plla_Cur.PRICE_OVERRIDE ||'|'||plla_Cur.ENCUMBERED_FLAG ||'|'||plla_Cur.ENCUMBERED_DATE ||'|'||plla_Cur.UNENCUMBERED_QUANTITY ||'|'||plla_Cur.FOB_LOOKUP_CODE ||'|'||plla_Cur.FREIGHT_TERMS_LOOKUP_CODE ||'|'||plla_Cur.TAXABLE_FLAG ||'|'||plla_Cur.TAX_NAME ||'|'||plla_Cur.ESTIMATED_TAX_AMOUNT ||'|'||
      plla_Cur.FROM_HEADER_ID ||'|'||plla_Cur.FROM_LINE_ID ||'|'||plla_Cur.FROM_LINE_LOCATION_ID ||'|'||plla_Cur.START_DATE ||'|'||plla_Cur.END_DATE ||'|'||plla_Cur.LEAD_TIME ||'|'||plla_Cur.LEAD_TIME_UNIT ||'|'||plla_Cur.PRICE_DISCOUNT ||'|'||plla_Cur.TERMS_ID ||'|'||plla_Cur.APPROVED_FLAG ||'|'||plla_Cur.APPROVED_DATE ||'|'||plla_Cur.CLOSED_FLAG ||'|'||plla_Cur.CANCEL_FLAG ||'|'||plla_Cur.CANCELLED_BY ||'|'||plla_Cur.CANCEL_DATE ||'|'||plla_Cur.CANCEL_REASON ||'|'||plla_Cur.FIRM_STATUS_LOOKUP_CODE ||'|'||plla_Cur.FIRM_DATE ||'|'||plla_Cur.ATTRIBUTE_CATEGORY ||'|'||plla_Cur.ATTRIBUTE1 ||'|'||plla_Cur.ATTRIBUTE2 ||'|'||plla_Cur.ATTRIBUTE3 ||'|'||plla_Cur.ATTRIBUTE4 ||'|'||plla_Cur.ATTRIBUTE5 ||'|'||plla_Cur.ATTRIBUTE6 ||'|'||plla_Cur.ATTRIBUTE7 ||'|'||plla_Cur.ATTRIBUTE8 ||'|'||plla_Cur.ATTRIBUTE9 ||'|'||plla_Cur.ATTRIBUTE10 ||'|'||plla_Cur.ATTRIBUTE11 ||'|'||plla_Cur.ATTRIBUTE12 ||'|'||plla_Cur.ATTRIBUTE13 ||'|'||plla_Cur.ATTRIBUTE14 ||'|'||plla_Cur.ATTRIBUTE15 ||'|'||
      plla_Cur.UNIT_OF_MEASURE_CLASS ||'|'||plla_Cur.ENCUMBER_NOW ||'|'||plla_Cur.INSPECTION_REQUIRED_FLAG ||'|'||plla_Cur.RECEIPT_REQUIRED_FLAG ||'|'||plla_Cur.QTY_RCV_TOLERANCE ||'|'||plla_Cur.QTY_RCV_EXCEPTION_CODE ||'|'||plla_Cur.ENFORCE_SHIP_TO_LOCATION_CODE ||'|'||plla_Cur.ALLOW_SUBSTITUTE_RECEIPTS_FLAG ||'|'||plla_Cur.DAYS_EARLY_RECEIPT_ALLOWED ||'|'||plla_Cur.DAYS_LATE_RECEIPT_ALLOWED ||'|'||plla_Cur.RECEIPT_DAYS_EXCEPTION_CODE ||'|'||plla_Cur.INVOICE_CLOSE_TOLERANCE ||'|'||plla_Cur.RECEIVE_CLOSE_TOLERANCE ||'|'||plla_Cur.SHIP_TO_ORGANIZATION_ID ||'|'||plla_Cur.SHIPMENT_NUM ||'|'||plla_Cur.SOURCE_SHIPMENT_ID ||'|'||plla_Cur.SHIPMENT_TYPE ||'|'||plla_Cur.CLOSED_CODE ||'|'||plla_Cur.REQUEST_ID ||'|'||plla_Cur.PROGRAM_APPLICATION_ID ||'|'||plla_Cur.PROGRAM_ID ||'|'||plla_Cur.PROGRAM_UPDATE_DATE ||'|'||plla_Cur.USSGL_TRANSACTION_CODE ||'|'||plla_Cur.GOVERNMENT_CONTEXT ||'|'||plla_Cur.RECEIVING_ROUTING_ID ||'|'||plla_Cur.ACCRUE_ON_RECEIPT_FLAG ||'|'||plla_Cur.CLOSED_REASON ||'|'||
      plla_Cur.CLOSED_DATE ||'|'||plla_Cur.CLOSED_BY ||'|'||plla_Cur.ORG_ID ||'|'||plla_Cur.QUANTITY_SHIPPED ||'|'||plla_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||plla_Cur.GLOBAL_ATTRIBUTE1 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE2 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE3 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE4 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE5 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE6 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE7 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE8 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE9 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE10 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE11 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE12 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE13 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE14 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE15 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE16 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE17 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE18 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE19 ||'|'||plla_Cur.GLOBAL_ATTRIBUTE20 ||'|'||plla_Cur.COUNTRY_OF_ORIGIN_CODE ||'|'||plla_Cur.TAX_USER_OVERRIDE_FLAG ||'|'||plla_Cur.MATCH_OPTION ||'|'||plla_Cur.TAX_CODE_ID ||'|'||
      plla_Cur.CALCULATE_TAX_FLAG ||'|'||plla_Cur.CHANGE_PROMISED_DATE_REASON ||'|'||plla_Cur.NOTE_TO_RECEIVER ||'|'||plla_Cur.SECONDARY_QUANTITY ||'|'||plla_Cur.SECONDARY_UNIT_OF_MEASURE ||'|'||plla_Cur.PREFERRED_GRADE ||'|'||plla_Cur.SECONDARY_QUANTITY_RECEIVED ||'|'||plla_Cur.SECONDARY_QUANTITY_ACCEPTED ||'|'||plla_Cur.SECONDARY_QUANTITY_REJECTED ||'|'||plla_Cur.SECONDARY_QUANTITY_CANCELLED ||'|'||plla_Cur.VMI_FLAG ||'|'||plla_Cur.CONSIGNED_FLAG ||'|'||plla_Cur.RETROACTIVE_DATE ||'|'||plla_Cur.SUPPLIER_ORDER_LINE_NUMBER ||'|'||plla_Cur.AMOUNT ||'|'||plla_Cur.AMOUNT_RECEIVED ||'|'||plla_Cur.AMOUNT_BILLED ||'|'||plla_Cur.AMOUNT_CANCELLED ||'|'||plla_Cur.AMOUNT_REJECTED ||'|'||plla_Cur.AMOUNT_ACCEPTED ||'|'||plla_Cur.DROP_SHIP_FLAG ||'|'||plla_Cur.SALES_ORDER_UPDATE_DATE ||'|'||plla_Cur.TRANSACTION_FLOW_HEADER_ID ||'|'||plla_Cur.FINAL_MATCH_FLAG ||'|'||plla_Cur.MANUAL_PRICE_CHANGE_FLAG ||'|'||plla_Cur.SHIPMENT_CLOSED_DATE ||'|'||plla_Cur.CLOSED_FOR_RECEIVING_DATE ||'|'||
      plla_Cur.CLOSED_FOR_INVOICE_DATE ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_line_locations_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_line_locations_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_line_locations_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_line_loc_all;
-- +===================================================================================================+
-- +===============  Extract # 11  ====================================================================+
PROCEDURE Extract_po_line_types_b(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_line_types_b.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_line_types_b                                                |
  -- | Description      : This procedure is used to extract po_line_types_b                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='line_type_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'ORDER_TYPE_LOOKUP_CODE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'CATEGORY_ID' ||'|'||'UNIT_OF_MEASURE' ||'|'||'UNIT_PRICE' ||'|'||'RECEIVING_FLAG' ||'|'||'INACTIVE_DATE' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'OUTSIDE_OPERATION_FLAG' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'RECEIVE_CLOSE_TOLERANCE' ||'|'||'PURCHASE_BASIS' ||'|'||'MATCHING_BASIS' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pltb_Cur IN
    (SELECT LINE_TYPE_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      ORDER_TYPE_LOOKUP_CODE ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      CATEGORY_ID ,
      UNIT_OF_MEASURE ,
      UNIT_PRICE ,
      RECEIVING_FLAG ,
      INACTIVE_DATE ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      OUTSIDE_OPERATION_FLAG ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      RECEIVE_CLOSE_TOLERANCE ,
      PURCHASE_BASIS ,
      MATCHING_BASIS
    FROM po_line_types_b
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=pltb_Cur.line_type_id ||'|'||pltb_Cur.LAST_UPDATE_DATE ||'|'||pltb_Cur.LAST_UPDATED_BY ||'|'||pltb_Cur.ORDER_TYPE_LOOKUP_CODE ||'|'||pltb_Cur.LAST_UPDATE_LOGIN ||'|'||pltb_Cur.CREATION_DATE ||'|'||pltb_Cur.CREATED_BY ||'|'||pltb_Cur.CATEGORY_ID ||'|'||pltb_Cur.UNIT_OF_MEASURE ||'|'||pltb_Cur.UNIT_PRICE ||'|'||pltb_Cur.RECEIVING_FLAG ||'|'||pltb_Cur.INACTIVE_DATE ||'|'||pltb_Cur.ATTRIBUTE_CATEGORY ||'|'||pltb_Cur.ATTRIBUTE1 ||'|'||pltb_Cur.ATTRIBUTE2 ||'|'||pltb_Cur.ATTRIBUTE3 ||'|'||pltb_Cur.ATTRIBUTE4 ||'|'||pltb_Cur.ATTRIBUTE5 ||'|'||pltb_Cur.ATTRIBUTE6 ||'|'||pltb_Cur.ATTRIBUTE7 ||'|'||pltb_Cur.ATTRIBUTE8 ||'|'||pltb_Cur.ATTRIBUTE9 ||'|'||pltb_Cur.ATTRIBUTE10 ||'|'||pltb_Cur.ATTRIBUTE11 ||'|'||pltb_Cur.ATTRIBUTE12 ||'|'||pltb_Cur.ATTRIBUTE13 ||'|'||pltb_Cur.ATTRIBUTE14 ||'|'||pltb_Cur.ATTRIBUTE15 ||'|'||pltb_Cur.OUTSIDE_OPERATION_FLAG ||'|'||pltb_Cur.REQUEST_ID ||'|'||pltb_Cur.PROGRAM_APPLICATION_ID ||'|'||pltb_Cur.PROGRAM_ID ||'|'||pltb_Cur.PROGRAM_UPDATE_DATE ||'|'
      ||pltb_Cur.RECEIVE_CLOSE_TOLERANCE ||'|'||pltb_Cur.PURCHASE_BASIS ||'|'||pltb_Cur.MATCHING_BASIS ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_line_types_b = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_line_types_b');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_line_types_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_line_types_b;
-- +===================================================================================================+
-- +===============  Extract # 12  ====================================================================+
PROCEDURE Extract_po_distr_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_distr_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_distributions_all                                                |
  -- | Description      : This procedure is used to extract po_distributions_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='po_distribution_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'PO_HEADER_ID' ||'|'||'PO_LINE_ID' ||'|'||'LINE_LOCATION_ID' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'CODE_COMBINATION_ID' ||'|'||'QUANTITY_ORDERED' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'PO_RELEASE_ID' ||'|'||'QUANTITY_DELIVERED' ||'|'||'QUANTITY_BILLED' ||'|'||'QUANTITY_CANCELLED' ||'|'||'REQ_HEADER_REFERENCE_NUM' ||'|'||'REQ_LINE_REFERENCE_NUM' ||'|'||'REQ_DISTRIBUTION_ID' ||'|'||'DELIVER_TO_LOCATION_ID' ||'|'||'DELIVER_TO_PERSON_ID' ||'|'||'RATE_DATE' ||'|'||'RATE' ||'|'||'AMOUNT_BILLED' ||'|'||'ACCRUED_FLAG' ||'|'||'ENCUMBERED_FLAG' ||'|'||'ENCUMBERED_AMOUNT' ||'|'||'UNENCUMBERED_QUANTITY' ||'|'||'UNENCUMBERED_AMOUNT' ||'|'||'FAILED_FUNDS_LOOKUP_CODE' ||'|'||'GL_ENCUMBERED_DATE' ||'|'||'GL_ENCUMBERED_PERIOD_NAME' ||'|'||'GL_CANCELLED_DATE' ||'|'||'DESTINATION_TYPE_CODE' ||'|'||'DESTINATION_ORGANIZATION_ID' ||'|'||'DESTINATION_SUBINVENTORY' ||'|'||
  'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'WIP_ENTITY_ID' ||'|'||'WIP_OPERATION_SEQ_NUM' ||'|'||'WIP_RESOURCE_SEQ_NUM' ||'|'||'WIP_REPETITIVE_SCHEDULE_ID' ||'|'||'WIP_LINE_ID' ||'|'||'BOM_RESOURCE_ID' ||'|'||'BUDGET_ACCOUNT_ID' ||'|'||'ACCRUAL_ACCOUNT_ID' ||'|'||'VARIANCE_ACCOUNT_ID' ||'|'||'PREVENT_ENCUMBRANCE_FLAG' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'GOVERNMENT_CONTEXT' ||'|'||'DESTINATION_CONTEXT' ||'|'||'DISTRIBUTION_NUM' ||'|'||'SOURCE_DISTRIBUTION_ID' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'PROJECT_ID' ||'|'||'TASK_ID' ||'|'||'EXPENDITURE_TYPE' ||'|'||'PROJECT_ACCOUNTING_CONTEXT' ||'|'||'EXPENDITURE_ORGANIZATION_ID'
  ||'|'||'GL_CLOSED_DATE' ||'|'||'ACCRUE_ON_RECEIPT_FLAG' ||'|'||'EXPENDITURE_ITEM_DATE' ||'|'||'ORG_ID' ||'|'||'KANBAN_CARD_ID' ||'|'||'AWARD_ID' ||'|'||'MRC_RATE_DATE' ||'|'||'MRC_RATE' ||'|'||'MRC_ENCUMBERED_AMOUNT' ||'|'||'MRC_UNENCUMBERED_AMOUNT' ||'|'||'END_ITEM_UNIT_NUMBER' ||'|'||'TAX_RECOVERY_OVERRIDE_FLAG' ||'|'||'RECOVERABLE_TAX' ||'|'||'NONRECOVERABLE_TAX' ||'|'||'RECOVERY_RATE' ||'|'||'OKE_CONTRACT_LINE_ID' ||'|'||'OKE_CONTRACT_DELIVERABLE_ID' ||'|'||'AMOUNT_ORDERED' ||'|'||'AMOUNT_DELIVERED' ||'|'||'AMOUNT_CANCELLED' ||'|'||'DISTRIBUTION_TYPE' ||'|'||'AMOUNT_TO_ENCUMBER' ||'|'||'INVOICE_ADJUSTMENT_FLAG' ||'|'||'DEST_CHARGE_ACCOUNT_ID' ||'|'||'DEST_VARIANCE_ACCOUNT_ID' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pda_Cur IN
    (SELECT PO_DISTRIBUTION_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      PO_HEADER_ID ,
      PO_LINE_ID ,
      LINE_LOCATION_ID ,
      SET_OF_BOOKS_ID ,
      CODE_COMBINATION_ID ,
      QUANTITY_ORDERED ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      PO_RELEASE_ID ,
      QUANTITY_DELIVERED ,
      QUANTITY_BILLED ,
      QUANTITY_CANCELLED ,
      REQ_HEADER_REFERENCE_NUM ,
      REQ_LINE_REFERENCE_NUM ,
      REQ_DISTRIBUTION_ID ,
      DELIVER_TO_LOCATION_ID ,
      DELIVER_TO_PERSON_ID ,
      RATE_DATE ,
      RATE ,
      AMOUNT_BILLED ,
      ACCRUED_FLAG ,
      ENCUMBERED_FLAG ,
      ENCUMBERED_AMOUNT ,
      UNENCUMBERED_QUANTITY ,
      UNENCUMBERED_AMOUNT ,
      FAILED_FUNDS_LOOKUP_CODE ,
      GL_ENCUMBERED_DATE ,
      GL_ENCUMBERED_PERIOD_NAME ,
      GL_CANCELLED_DATE ,
      DESTINATION_TYPE_CODE ,
      DESTINATION_ORGANIZATION_ID ,
      DESTINATION_SUBINVENTORY ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      WIP_ENTITY_ID ,
      WIP_OPERATION_SEQ_NUM ,
      WIP_RESOURCE_SEQ_NUM ,
      WIP_REPETITIVE_SCHEDULE_ID ,
      WIP_LINE_ID ,
      BOM_RESOURCE_ID ,
      BUDGET_ACCOUNT_ID ,
      ACCRUAL_ACCOUNT_ID ,
      VARIANCE_ACCOUNT_ID ,
      PREVENT_ENCUMBRANCE_FLAG ,
      USSGL_TRANSACTION_CODE ,
      GOVERNMENT_CONTEXT ,
      DESTINATION_CONTEXT ,
      DISTRIBUTION_NUM ,
      SOURCE_DISTRIBUTION_ID ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      PROJECT_ID ,
      TASK_ID ,
      EXPENDITURE_TYPE ,
      PROJECT_ACCOUNTING_CONTEXT ,
      EXPENDITURE_ORGANIZATION_ID ,
      GL_CLOSED_DATE ,
      ACCRUE_ON_RECEIPT_FLAG ,
      EXPENDITURE_ITEM_DATE ,
      ORG_ID ,
      KANBAN_CARD_ID ,
      AWARD_ID ,
      MRC_RATE_DATE ,
      MRC_RATE ,
      MRC_ENCUMBERED_AMOUNT ,
      MRC_UNENCUMBERED_AMOUNT ,
      END_ITEM_UNIT_NUMBER ,
      TAX_RECOVERY_OVERRIDE_FLAG ,
      RECOVERABLE_TAX ,
      NONRECOVERABLE_TAX ,
      RECOVERY_RATE ,
      OKE_CONTRACT_LINE_ID ,
      OKE_CONTRACT_DELIVERABLE_ID ,
      AMOUNT_ORDERED ,
      AMOUNT_DELIVERED ,
      AMOUNT_CANCELLED ,
      DISTRIBUTION_TYPE ,
      AMOUNT_TO_ENCUMBER ,
      INVOICE_ADJUSTMENT_FLAG ,
      DEST_CHARGE_ACCOUNT_ID ,
      DEST_VARIANCE_ACCOUNT_ID
    FROM po_distributions_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=pda_Cur.po_distribution_id ||'|'||pda_Cur.LAST_UPDATE_DATE ||'|'||pda_Cur.LAST_UPDATED_BY ||'|'||pda_Cur.PO_HEADER_ID ||'|'||pda_Cur.PO_LINE_ID ||'|'||pda_Cur.LINE_LOCATION_ID ||'|'||pda_Cur.SET_OF_BOOKS_ID ||'|'||pda_Cur.CODE_COMBINATION_ID ||'|'||pda_Cur.QUANTITY_ORDERED ||'|'||pda_Cur.LAST_UPDATE_LOGIN ||'|'||pda_Cur.CREATION_DATE ||'|'||pda_Cur.CREATED_BY ||'|'||pda_Cur.PO_RELEASE_ID ||'|'||pda_Cur.QUANTITY_DELIVERED ||'|'||pda_Cur.QUANTITY_BILLED ||'|'||pda_Cur.QUANTITY_CANCELLED ||'|'||pda_Cur.REQ_HEADER_REFERENCE_NUM ||'|'||pda_Cur.REQ_LINE_REFERENCE_NUM ||'|'||pda_Cur.REQ_DISTRIBUTION_ID ||'|'||pda_Cur.DELIVER_TO_LOCATION_ID ||'|'||pda_Cur.DELIVER_TO_PERSON_ID ||'|'||pda_Cur.RATE_DATE ||'|'||pda_Cur.RATE ||'|'||pda_Cur.AMOUNT_BILLED ||'|'||pda_Cur.ACCRUED_FLAG ||'|'||pda_Cur.ENCUMBERED_FLAG ||'|'||pda_Cur.ENCUMBERED_AMOUNT ||'|'||pda_Cur.UNENCUMBERED_QUANTITY ||'|'||pda_Cur.UNENCUMBERED_AMOUNT ||'|'||pda_Cur.FAILED_FUNDS_LOOKUP_CODE ||'|'||
      pda_Cur.GL_ENCUMBERED_DATE ||'|'||pda_Cur.GL_ENCUMBERED_PERIOD_NAME ||'|'||pda_Cur.GL_CANCELLED_DATE ||'|'||pda_Cur.DESTINATION_TYPE_CODE ||'|'||pda_Cur.DESTINATION_ORGANIZATION_ID ||'|'||pda_Cur.DESTINATION_SUBINVENTORY ||'|'||pda_Cur.ATTRIBUTE_CATEGORY ||'|'||pda_Cur.ATTRIBUTE1 ||'|'||pda_Cur.ATTRIBUTE2 ||'|'||pda_Cur.ATTRIBUTE3 ||'|'||pda_Cur.ATTRIBUTE4 ||'|'||pda_Cur.ATTRIBUTE5 ||'|'||pda_Cur.ATTRIBUTE6 ||'|'||pda_Cur.ATTRIBUTE7 ||'|'||pda_Cur.ATTRIBUTE8 ||'|'||pda_Cur.ATTRIBUTE9 ||'|'||pda_Cur.ATTRIBUTE10 ||'|'||pda_Cur.ATTRIBUTE11 ||'|'||pda_Cur.ATTRIBUTE12 ||'|'||pda_Cur.ATTRIBUTE13 ||'|'||pda_Cur.ATTRIBUTE14 ||'|'||pda_Cur.ATTRIBUTE15 ||'|'||pda_Cur.WIP_ENTITY_ID ||'|'||pda_Cur.WIP_OPERATION_SEQ_NUM ||'|'||pda_Cur.WIP_RESOURCE_SEQ_NUM ||'|'||pda_Cur.WIP_REPETITIVE_SCHEDULE_ID ||'|'||pda_Cur.WIP_LINE_ID ||'|'||pda_Cur.BOM_RESOURCE_ID ||'|'||pda_Cur.BUDGET_ACCOUNT_ID ||'|'||pda_Cur.ACCRUAL_ACCOUNT_ID ||'|'||pda_Cur.VARIANCE_ACCOUNT_ID ||'|'||
      pda_Cur.PREVENT_ENCUMBRANCE_FLAG ||'|'||pda_Cur.USSGL_TRANSACTION_CODE ||'|'||pda_Cur.GOVERNMENT_CONTEXT ||'|'||pda_Cur.DESTINATION_CONTEXT ||'|'||pda_Cur.DISTRIBUTION_NUM ||'|'||pda_Cur.SOURCE_DISTRIBUTION_ID ||'|'||pda_Cur.REQUEST_ID ||'|'||pda_Cur.PROGRAM_APPLICATION_ID ||'|'||pda_Cur.PROGRAM_ID ||'|'||pda_Cur.PROGRAM_UPDATE_DATE ||'|'||pda_Cur.PROJECT_ID ||'|'||pda_Cur.TASK_ID ||'|'||pda_Cur.EXPENDITURE_TYPE ||'|'||pda_Cur.PROJECT_ACCOUNTING_CONTEXT ||'|'||pda_Cur.EXPENDITURE_ORGANIZATION_ID ||'|'||pda_Cur.GL_CLOSED_DATE ||'|'||pda_Cur.ACCRUE_ON_RECEIPT_FLAG ||'|'||pda_Cur.EXPENDITURE_ITEM_DATE ||'|'||pda_Cur.ORG_ID ||'|'||pda_Cur.KANBAN_CARD_ID ||'|'||pda_Cur.AWARD_ID ||'|'||pda_Cur.MRC_RATE_DATE ||'|'||pda_Cur.MRC_RATE ||'|'||pda_Cur.MRC_ENCUMBERED_AMOUNT ||'|'||pda_Cur.MRC_UNENCUMBERED_AMOUNT ||'|'||pda_Cur.END_ITEM_UNIT_NUMBER ||'|'||pda_Cur.TAX_RECOVERY_OVERRIDE_FLAG ||'|'||pda_Cur.RECOVERABLE_TAX ||'|'||pda_Cur.NONRECOVERABLE_TAX ||'|'||pda_Cur.RECOVERY_RATE ||'|'||
      pda_Cur.OKE_CONTRACT_LINE_ID ||'|'||pda_Cur.OKE_CONTRACT_DELIVERABLE_ID ||'|'||pda_Cur.AMOUNT_ORDERED ||'|'||pda_Cur.AMOUNT_DELIVERED ||'|'||pda_Cur.AMOUNT_CANCELLED ||'|'||pda_Cur.DISTRIBUTION_TYPE ||'|'||pda_Cur.AMOUNT_TO_ENCUMBER ||'|'||pda_Cur.INVOICE_ADJUSTMENT_FLAG ||'|'||pda_Cur.DEST_CHARGE_ACCOUNT_ID ||'|'||pda_Cur.DEST_VARIANCE_ACCOUNT_ID ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_distributions_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_distributions_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_distributions_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_distr_all;
-- +===================================================================================================+
-- +===============  Extract # 13  ====================================================================+
PROCEDURE Extract_po_lines_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_lines_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_lines_all                                                |
  -- | Description      : This procedure is used to extract po_lines_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='po_line_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'PO_HEADER_ID' ||'|'||'LINE_TYPE_ID' ||'|'||'LINE_NUM' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'ITEM_ID' ||'|'||'ITEM_REVISION' ||'|'||'CATEGORY_ID' ||'|'||'ITEM_DESCRIPTION' ||'|'||'UNIT_MEAS_LOOKUP_CODE' ||'|'||'QUANTITY_COMMITTED' ||'|'||'COMMITTED_AMOUNT' ||'|'||'ALLOW_PRICE_OVERRIDE_FLAG' ||'|'||'NOT_TO_EXCEED_PRICE' ||'|'||'LIST_PRICE_PER_UNIT' ||'|'||'UNIT_PRICE' ||'|'||'QUANTITY' ||'|'||'UN_NUMBER_ID' ||'|'||'HAZARD_CLASS_ID' ||'|'||'NOTE_TO_VENDOR' ||'|'||'FROM_HEADER_ID' ||'|'||'FROM_LINE_ID' ||'|'||'MIN_ORDER_QUANTITY' ||'|'||'MAX_ORDER_QUANTITY' ||'|'||'QTY_RCV_TOLERANCE' ||'|'||'OVER_TOLERANCE_ERROR_FLAG' ||'|'||'MARKET_PRICE' ||'|'||'UNORDERED_FLAG' ||'|'||'CLOSED_FLAG' ||'|'||'USER_HOLD_FLAG' ||'|'||'CANCEL_FLAG' ||'|'||'CANCELLED_BY' ||'|'||'CANCEL_DATE' ||'|'||'CANCEL_REASON' ||'|'||'FIRM_STATUS_LOOKUP_CODE' ||'|'||'FIRM_DATE' ||'|'||
  'VENDOR_PRODUCT_NUM' ||'|'||'CONTRACT_NUM' ||'|'||'TAXABLE_FLAG' ||'|'||'TAX_NAME' ||'|'||'TYPE_1099' ||'|'||'CAPITAL_EXPENSE_FLAG' ||'|'||'NEGOTIATED_BY_PREPARER_FLAG' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'REFERENCE_NUM' ||'|'||'MIN_RELEASE_AMOUNT' ||'|'||'PRICE_TYPE_LOOKUP_CODE' ||'|'||'CLOSED_CODE' ||'|'||'PRICE_BREAK_LOOKUP_CODE' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'GOVERNMENT_CONTEXT' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'CLOSED_DATE' ||'|'||'CLOSED_REASON' ||'|'||'CLOSED_BY' ||'|'||'TRANSACTION_REASON_CODE' ||'|'||'ORG_ID' ||'|'||'QC_GRADE' ||'|'||'BASE_UOM' ||'|'||'BASE_QTY' ||'|'||'SECONDARY_UOM' ||'|'
  ||'SECONDARY_QTY' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'LINE_REFERENCE_NUM' ||'|'||'PROJECT_ID' ||'|'||'TASK_ID' ||'|'||'EXPIRATION_DATE' ||'|'||'TAX_CODE_ID' ||'|'||'OKE_CONTRACT_HEADER_ID' ||'|'||'OKE_CONTRACT_VERSION_ID' ||'|'||'SECONDARY_QUANTITY' ||'|'||'SECONDARY_UNIT_OF_MEASURE' ||'|'||'PREFERRED_GRADE' ||'|'||'AUCTION_HEADER_ID' ||'|'||'AUCTION_DISPLAY_NUMBER' ||'|'||'AUCTION_LINE_NUMBER' ||'|'||'BID_NUMBER' ||'|'||
  'BID_LINE_NUMBER' ||'|'||'RETROACTIVE_DATE' ||'|'||'FROM_LINE_LOCATION_ID' ||'|'||'SUPPLIER_REF_NUMBER' ||'|'||'CONTRACT_ID' ||'|'||'START_DATE' ||'|'||'AMOUNT' ||'|'||'JOB_ID' ||'|'||'CONTRACTOR_FIRST_NAME' ||'|'||'CONTRACTOR_LAST_NAME' ||'|'||'ORDER_TYPE_LOOKUP_CODE' ||'|'||'PURCHASE_BASIS' ||'|'||'MATCHING_BASIS' ||'|'||'SVC_AMOUNT_NOTIF_SENT' ||'|'||'SVC_COMPLETION_NOTIF_SENT' ||'|'||'BASE_UNIT_PRICE' ||'|'||'MANUAL_PRICE_CHANGE_FLAG' ||'|'||'CATALOG_NAME' ||'|'||'SUPPLIER_PART_AUXID' ||'|'||'IP_CATEGORY_ID' ||'|'||'LAST_UPDATED_PROGRAM' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pla_Cur IN
    (SELECT PO_LINE_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      PO_HEADER_ID ,
      LINE_TYPE_ID ,
      LINE_NUM ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      ITEM_ID ,
      ITEM_REVISION ,
      CATEGORY_ID ,
      ITEM_DESCRIPTION ,
      UNIT_MEAS_LOOKUP_CODE ,
      QUANTITY_COMMITTED ,
      COMMITTED_AMOUNT ,
      ALLOW_PRICE_OVERRIDE_FLAG ,
      NOT_TO_EXCEED_PRICE ,
      LIST_PRICE_PER_UNIT ,
      UNIT_PRICE ,
      QUANTITY ,
      UN_NUMBER_ID ,
      HAZARD_CLASS_ID ,
      NOTE_TO_VENDOR ,
      FROM_HEADER_ID ,
      FROM_LINE_ID ,
      MIN_ORDER_QUANTITY ,
      MAX_ORDER_QUANTITY ,
      QTY_RCV_TOLERANCE ,
      OVER_TOLERANCE_ERROR_FLAG ,
      MARKET_PRICE ,
      UNORDERED_FLAG ,
      CLOSED_FLAG ,
      USER_HOLD_FLAG ,
      CANCEL_FLAG ,
      CANCELLED_BY ,
      CANCEL_DATE ,
      CANCEL_REASON ,
      FIRM_STATUS_LOOKUP_CODE ,
      FIRM_DATE ,
      VENDOR_PRODUCT_NUM ,
      CONTRACT_NUM ,
      TAXABLE_FLAG ,
      TAX_NAME ,
      TYPE_1099 ,
      CAPITAL_EXPENSE_FLAG ,
      NEGOTIATED_BY_PREPARER_FLAG ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      REFERENCE_NUM ,
      MIN_RELEASE_AMOUNT ,
      PRICE_TYPE_LOOKUP_CODE ,
      CLOSED_CODE ,
      PRICE_BREAK_LOOKUP_CODE ,
      USSGL_TRANSACTION_CODE ,
      GOVERNMENT_CONTEXT ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      CLOSED_DATE ,
      CLOSED_REASON ,
      CLOSED_BY ,
      TRANSACTION_REASON_CODE ,
      ORG_ID ,
      QC_GRADE ,
      BASE_UOM ,
      BASE_QTY ,
      SECONDARY_UOM ,
      SECONDARY_QTY ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      LINE_REFERENCE_NUM ,
      PROJECT_ID ,
      TASK_ID ,
      EXPIRATION_DATE ,
      TAX_CODE_ID ,
      OKE_CONTRACT_HEADER_ID ,
      OKE_CONTRACT_VERSION_ID ,
      SECONDARY_QUANTITY ,
      SECONDARY_UNIT_OF_MEASURE ,
      PREFERRED_GRADE ,
      AUCTION_HEADER_ID ,
      AUCTION_DISPLAY_NUMBER ,
      AUCTION_LINE_NUMBER ,
      BID_NUMBER ,
      BID_LINE_NUMBER ,
      RETROACTIVE_DATE ,
      FROM_LINE_LOCATION_ID ,
      SUPPLIER_REF_NUMBER ,
      CONTRACT_ID ,
      START_DATE ,
      AMOUNT ,
      JOB_ID ,
      CONTRACTOR_FIRST_NAME ,
      CONTRACTOR_LAST_NAME ,
      ORDER_TYPE_LOOKUP_CODE ,
      PURCHASE_BASIS ,
      MATCHING_BASIS ,
      SVC_AMOUNT_NOTIF_SENT ,
      SVC_COMPLETION_NOTIF_SENT ,
      BASE_UNIT_PRICE ,
      MANUAL_PRICE_CHANGE_FLAG ,
      CATALOG_NAME ,
      SUPPLIER_PART_AUXID ,
      IP_CATEGORY_ID ,
      LAST_UPDATED_PROGRAM
    FROM po_lines_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=pla_Cur.po_line_id ||'|'||pla_Cur.LAST_UPDATE_DATE ||'|'||pla_Cur.LAST_UPDATED_BY ||'|'||pla_Cur.PO_HEADER_ID ||'|'||pla_Cur.LINE_TYPE_ID ||'|'||pla_Cur.LINE_NUM ||'|'||pla_Cur.LAST_UPDATE_LOGIN ||'|'||pla_Cur.CREATION_DATE ||'|'||pla_Cur.CREATED_BY ||'|'||pla_Cur.ITEM_ID ||'|'||pla_Cur.ITEM_REVISION ||'|'||pla_Cur.CATEGORY_ID ||'|'||pla_Cur.ITEM_DESCRIPTION ||'|'||pla_Cur.UNIT_MEAS_LOOKUP_CODE ||'|'||pla_Cur.QUANTITY_COMMITTED ||'|'||pla_Cur.COMMITTED_AMOUNT ||'|'||pla_Cur.ALLOW_PRICE_OVERRIDE_FLAG ||'|'||pla_Cur.NOT_TO_EXCEED_PRICE ||'|'||pla_Cur.LIST_PRICE_PER_UNIT ||'|'||pla_Cur.UNIT_PRICE ||'|'||pla_Cur.QUANTITY ||'|'||pla_Cur.UN_NUMBER_ID ||'|'||pla_Cur.HAZARD_CLASS_ID ||'|'||pla_Cur.NOTE_TO_VENDOR ||'|'||pla_Cur.FROM_HEADER_ID ||'|'||pla_Cur.FROM_LINE_ID ||'|'||pla_Cur.MIN_ORDER_QUANTITY ||'|'||pla_Cur.MAX_ORDER_QUANTITY ||'|'||pla_Cur.QTY_RCV_TOLERANCE ||'|'||pla_Cur.OVER_TOLERANCE_ERROR_FLAG ||'|'||pla_Cur.MARKET_PRICE ||'|'||pla_Cur.UNORDERED_FLAG ||'|'||
      pla_Cur.CLOSED_FLAG ||'|'||pla_Cur.USER_HOLD_FLAG ||'|'||pla_Cur.CANCEL_FLAG ||'|'||pla_Cur.CANCELLED_BY ||'|'||pla_Cur.CANCEL_DATE ||'|'||pla_Cur.CANCEL_REASON ||'|'||pla_Cur.FIRM_STATUS_LOOKUP_CODE ||'|'||pla_Cur.FIRM_DATE ||'|'||pla_Cur.VENDOR_PRODUCT_NUM ||'|'||pla_Cur.CONTRACT_NUM ||'|'||pla_Cur.TAXABLE_FLAG ||'|'||pla_Cur.TAX_NAME ||'|'||pla_Cur.TYPE_1099 ||'|'||pla_Cur.CAPITAL_EXPENSE_FLAG ||'|'||pla_Cur.NEGOTIATED_BY_PREPARER_FLAG ||'|'||pla_Cur.ATTRIBUTE_CATEGORY ||'|'||pla_Cur.ATTRIBUTE1 ||'|'||pla_Cur.ATTRIBUTE2 ||'|'||pla_Cur.ATTRIBUTE3 ||'|'||pla_Cur.ATTRIBUTE4 ||'|'||pla_Cur.ATTRIBUTE5 ||'|'||pla_Cur.ATTRIBUTE6 ||'|'||pla_Cur.ATTRIBUTE7 ||'|'||pla_Cur.ATTRIBUTE8 ||'|'||pla_Cur.ATTRIBUTE9 ||'|'||pla_Cur.ATTRIBUTE10 ||'|'||pla_Cur.ATTRIBUTE11 ||'|'||pla_Cur.ATTRIBUTE12 ||'|'||pla_Cur.ATTRIBUTE13 ||'|'||pla_Cur.ATTRIBUTE14 ||'|'||pla_Cur.ATTRIBUTE15 ||'|'||pla_Cur.REFERENCE_NUM ||'|'||pla_Cur.MIN_RELEASE_AMOUNT ||'|'||pla_Cur.PRICE_TYPE_LOOKUP_CODE ||'|'||
      pla_Cur.CLOSED_CODE ||'|'||pla_Cur.PRICE_BREAK_LOOKUP_CODE ||'|'||pla_Cur.USSGL_TRANSACTION_CODE ||'|'||pla_Cur.GOVERNMENT_CONTEXT ||'|'||pla_Cur.REQUEST_ID ||'|'||pla_Cur.PROGRAM_APPLICATION_ID ||'|'||pla_Cur.PROGRAM_ID ||'|'||pla_Cur.PROGRAM_UPDATE_DATE ||'|'||pla_Cur.CLOSED_DATE ||'|'||pla_Cur.CLOSED_REASON ||'|'||pla_Cur.CLOSED_BY ||'|'||pla_Cur.TRANSACTION_REASON_CODE ||'|'||pla_Cur.ORG_ID ||'|'||pla_Cur.QC_GRADE ||'|'||pla_Cur.BASE_UOM ||'|'||pla_Cur.BASE_QTY ||'|'||pla_Cur.SECONDARY_UOM ||'|'||pla_Cur.SECONDARY_QTY ||'|'||pla_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||pla_Cur.GLOBAL_ATTRIBUTE1 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE2 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE3 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE4 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE5 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE6 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE7 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE8 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE9 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE10 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE11 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE12 ||'|'||
      pla_Cur.GLOBAL_ATTRIBUTE13 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE14 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE15 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE16 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE17 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE18 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE19 ||'|'||pla_Cur.GLOBAL_ATTRIBUTE20 ||'|'||pla_Cur.LINE_REFERENCE_NUM ||'|'||pla_Cur.PROJECT_ID ||'|'||pla_Cur.TASK_ID ||'|'||pla_Cur.EXPIRATION_DATE ||'|'||pla_Cur.TAX_CODE_ID ||'|'||pla_Cur.OKE_CONTRACT_HEADER_ID ||'|'||pla_Cur.OKE_CONTRACT_VERSION_ID ||'|'||pla_Cur.SECONDARY_QUANTITY ||'|'||pla_Cur.SECONDARY_UNIT_OF_MEASURE ||'|'||pla_Cur.PREFERRED_GRADE ||'|'||pla_Cur.AUCTION_HEADER_ID ||'|'||pla_Cur.AUCTION_DISPLAY_NUMBER ||'|'||pla_Cur.AUCTION_LINE_NUMBER ||'|'||pla_Cur.BID_NUMBER ||'|'||pla_Cur.BID_LINE_NUMBER ||'|'||pla_Cur.RETROACTIVE_DATE ||'|'||pla_Cur.FROM_LINE_LOCATION_ID ||'|'||pla_Cur.SUPPLIER_REF_NUMBER ||'|'||pla_Cur.CONTRACT_ID ||'|'||pla_Cur.START_DATE ||'|'||pla_Cur.AMOUNT ||'|'||pla_Cur.JOB_ID ||'|'||pla_Cur.CONTRACTOR_FIRST_NAME ||
      '|'||pla_Cur.CONTRACTOR_LAST_NAME ||'|'||pla_Cur.ORDER_TYPE_LOOKUP_CODE ||'|'||pla_Cur.PURCHASE_BASIS ||'|'||pla_Cur.MATCHING_BASIS ||'|'||pla_Cur.SVC_AMOUNT_NOTIF_SENT ||'|'||pla_Cur.SVC_COMPLETION_NOTIF_SENT ||'|'||pla_Cur.BASE_UNIT_PRICE ||'|'||pla_Cur.MANUAL_PRICE_CHANGE_FLAG ||'|'||pla_Cur.CATALOG_NAME ||'|'||pla_Cur.SUPPLIER_PART_AUXID ||'|'||pla_Cur.IP_CATEGORY_ID ||'|'||pla_Cur.LAST_UPDATED_PROGRAM ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_lines_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_lines_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_lines_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_lines_all;
-- +===================================================================================================+
-- +===============  Extract # 14  ====================================================================+
PROCEDURE Extract_po_headers_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_headers_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_headers_all                                                |
  -- | Description      : This procedure is used to extract po_headers_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='po_header_id' ||'|'||'AGENT_ID' ||'|'||'TYPE_LOOKUP_CODE' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'SEGMENT1' ||'|'||'SEGMENT2' ||'|'||'SEGMENT3' ||'|'||'SEGMENT4' ||'|'||'SEGMENT5' ||'|'||'SUMMARY_FLAG' ||'|'||'ENABLED_FLAG' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'VENDOR_ID' ||'|'||'VENDOR_SITE_ID' ||'|'||'VENDOR_CONTACT_ID' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'BILL_TO_LOCATION_ID' ||'|'||'TERMS_ID' ||'|'||'SHIP_VIA_LOOKUP_CODE' ||'|'||'FOB_LOOKUP_CODE' ||'|'||'FREIGHT_TERMS_LOOKUP_CODE' ||'|'||'STATUS_LOOKUP_CODE' ||'|'||'CURRENCY_CODE' ||'|'||'RATE_TYPE' ||'|'||'RATE_DATE' ||'|'||'RATE' ||'|'||'FROM_HEADER_ID' ||'|'||'FROM_TYPE_LOOKUP_CODE' ||'|'||'START_DATE' ||'|'||'END_DATE' ||'|'||'BLANKET_TOTAL_AMOUNT' ||'|'||'AUTHORIZATION_STATUS' ||'|'||'REVISION_NUM' ||'|'||'REVISED_DATE' ||'|'||'APPROVED_FLAG' ||'|'||'APPROVED_DATE' ||'|'||'AMOUNT_LIMIT' ||'|'||
  'MIN_RELEASE_AMOUNT' ||'|'||'NOTE_TO_AUTHORIZER' ||'|'||'NOTE_TO_VENDOR' ||'|'||'NOTE_TO_RECEIVER' ||'|'||'PRINT_COUNT' ||'|'||'PRINTED_DATE' ||'|'||'VENDOR_ORDER_NUM' ||'|'||'CONFIRMING_ORDER_FLAG' ||'|'||'COMMENTS' ||'|'||'REPLY_DATE' ||'|'||'REPLY_METHOD_LOOKUP_CODE' ||'|'||'RFQ_CLOSE_DATE' ||'|'||'QUOTE_TYPE_LOOKUP_CODE' ||'|'||'QUOTATION_CLASS_CODE' ||'|'||'QUOTE_WARNING_DELAY_UNIT' ||'|'||'QUOTE_WARNING_DELAY' ||'|'||'QUOTE_VENDOR_QUOTE_NUMBER' ||'|'||'ACCEPTANCE_REQUIRED_FLAG' ||'|'||'ACCEPTANCE_DUE_DATE' ||'|'||'CLOSED_DATE' ||'|'||'USER_HOLD_FLAG' ||'|'||'APPROVAL_REQUIRED_FLAG' ||'|'||'CANCEL_FLAG' ||'|'||'FIRM_STATUS_LOOKUP_CODE' ||'|'||'FIRM_DATE' ||'|'||'FROZEN_FLAG' ||'|'||'SUPPLY_AGREEMENT_FLAG' ||'|'||'EDI_PROCESSED_FLAG' ||'|'||'EDI_PROCESSED_STATUS' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||
  'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'CLOSED_CODE' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'GOVERNMENT_CONTEXT' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'ORG_ID' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'INTERFACE_SOURCE_CODE' ||'|'||'REFERENCE_NUM' ||'|'||'WF_ITEM_TYPE' ||'|'||
  'WF_ITEM_KEY' ||'|'||'MRC_RATE_TYPE' ||'|'||'MRC_RATE_DATE' ||'|'||'MRC_RATE' ||'|'||'PCARD_ID' ||'|'||'PRICE_UPDATE_TOLERANCE' ||'|'||'PAY_ON_CODE' ||'|'||'XML_FLAG' ||'|'||'XML_SEND_DATE' ||'|'||'XML_CHANGE_SEND_DATE' ||'|'||'GLOBAL_AGREEMENT_FLAG' ||'|'||'CONSIGNED_CONSUMPTION_FLAG' ||'|'||'CBC_ACCOUNTING_DATE' ||'|'||'CONSUME_REQ_DEMAND_FLAG' ||'|'||'CHANGE_REQUESTED_BY' ||'|'||'SHIPPING_CONTROL' ||'|'||'CONTERMS_EXIST_FLAG' ||'|'||'CONTERMS_ARTICLES_UPD_DATE' ||'|'||'CONTERMS_DELIV_UPD_DATE' ||'|'||'ENCUMBRANCE_REQUIRED_FLAG' ||'|'||'PENDING_SIGNATURE_FLAG' ||'|'||'CHANGE_SUMMARY' ||'|'||'DOCUMENT_CREATION_METHOD' ||'|'||'SUBMIT_DATE' ||'|'||'ENABLE_ALL_SITES' ||'|'||'CREATED_LANGUAGE' ||'|'||'CPA_REFERENCE' ||'|'||'LAST_UPDATED_PROGRAM' ||'|'||'OTM_STATUS_CODE' ||'|'||'OTM_RECOVERY_FLAG' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pha_Cur IN
    (SELECT PO_HEADER_ID ,
      AGENT_ID ,
      TYPE_LOOKUP_CODE ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      SEGMENT1 ,
      SEGMENT2 ,
      SEGMENT3 ,
      SEGMENT4 ,
      SEGMENT5 ,
      SUMMARY_FLAG ,
      ENABLED_FLAG ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      VENDOR_ID ,
      VENDOR_SITE_ID ,
      VENDOR_CONTACT_ID ,
      SHIP_TO_LOCATION_ID ,
      BILL_TO_LOCATION_ID ,
      TERMS_ID ,
      SHIP_VIA_LOOKUP_CODE ,
      FOB_LOOKUP_CODE ,
      FREIGHT_TERMS_LOOKUP_CODE ,
      STATUS_LOOKUP_CODE ,
      CURRENCY_CODE ,
      RATE_TYPE ,
      RATE_DATE ,
      RATE ,
      FROM_HEADER_ID ,
      FROM_TYPE_LOOKUP_CODE ,
      START_DATE ,
      END_DATE ,
      BLANKET_TOTAL_AMOUNT ,
      AUTHORIZATION_STATUS ,
      REVISION_NUM ,
      REVISED_DATE ,
      APPROVED_FLAG ,
      APPROVED_DATE ,
      AMOUNT_LIMIT ,
      MIN_RELEASE_AMOUNT ,
      NOTE_TO_AUTHORIZER ,
      NOTE_TO_VENDOR ,
      NOTE_TO_RECEIVER ,
      PRINT_COUNT ,
      PRINTED_DATE ,
      VENDOR_ORDER_NUM ,
      CONFIRMING_ORDER_FLAG ,
      COMMENTS ,
      REPLY_DATE ,
      REPLY_METHOD_LOOKUP_CODE ,
      RFQ_CLOSE_DATE ,
      QUOTE_TYPE_LOOKUP_CODE ,
      QUOTATION_CLASS_CODE ,
      QUOTE_WARNING_DELAY_UNIT ,
      QUOTE_WARNING_DELAY ,
      QUOTE_VENDOR_QUOTE_NUMBER ,
      ACCEPTANCE_REQUIRED_FLAG ,
      ACCEPTANCE_DUE_DATE ,
      CLOSED_DATE ,
      USER_HOLD_FLAG ,
      APPROVAL_REQUIRED_FLAG ,
      CANCEL_FLAG ,
      FIRM_STATUS_LOOKUP_CODE ,
      FIRM_DATE ,
      FROZEN_FLAG ,
      SUPPLY_AGREEMENT_FLAG ,
      EDI_PROCESSED_FLAG ,
      EDI_PROCESSED_STATUS ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      CLOSED_CODE ,
      USSGL_TRANSACTION_CODE ,
      GOVERNMENT_CONTEXT ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      ORG_ID ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      INTERFACE_SOURCE_CODE ,
      REFERENCE_NUM ,
      WF_ITEM_TYPE ,
      WF_ITEM_KEY ,
      MRC_RATE_TYPE ,
      MRC_RATE_DATE ,
      MRC_RATE ,
      PCARD_ID ,
      PRICE_UPDATE_TOLERANCE ,
      PAY_ON_CODE ,
      XML_FLAG ,
      XML_SEND_DATE ,
      XML_CHANGE_SEND_DATE ,
      GLOBAL_AGREEMENT_FLAG ,
      CONSIGNED_CONSUMPTION_FLAG ,
      CBC_ACCOUNTING_DATE ,
      CONSUME_REQ_DEMAND_FLAG ,
      CHANGE_REQUESTED_BY ,
      SHIPPING_CONTROL ,
      CONTERMS_EXIST_FLAG ,
      CONTERMS_ARTICLES_UPD_DATE ,
      CONTERMS_DELIV_UPD_DATE ,
      ENCUMBRANCE_REQUIRED_FLAG ,
      PENDING_SIGNATURE_FLAG ,
      CHANGE_SUMMARY ,
      DOCUMENT_CREATION_METHOD ,
      SUBMIT_DATE ,
      ENABLE_ALL_SITES ,
      CREATED_LANGUAGE ,
      CPA_REFERENCE ,
      LAST_UPDATED_PROGRAM ,
      OTM_STATUS_CODE ,
      OTM_RECOVERY_FLAG
    FROM po_headers_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=pha_Cur.po_header_id ||'|'||pha_Cur.AGENT_ID ||'|'||pha_Cur.TYPE_LOOKUP_CODE ||'|'||pha_Cur.LAST_UPDATE_DATE ||'|'||pha_Cur.LAST_UPDATED_BY ||'|'||pha_Cur.SEGMENT1 ||'|'||pha_Cur.SEGMENT2 ||'|'||pha_Cur.SEGMENT3 ||'|'||pha_Cur.SEGMENT4 ||'|'||pha_Cur.SEGMENT5 ||'|'||pha_Cur.SUMMARY_FLAG ||'|'||pha_Cur.ENABLED_FLAG ||'|'||pha_Cur.START_DATE_ACTIVE ||'|'||pha_Cur.END_DATE_ACTIVE ||'|'||pha_Cur.LAST_UPDATE_LOGIN ||'|'||pha_Cur.CREATION_DATE ||'|'||pha_Cur.CREATED_BY ||'|'||pha_Cur.VENDOR_ID ||'|'||pha_Cur.VENDOR_SITE_ID ||'|'||pha_Cur.VENDOR_CONTACT_ID ||'|'||pha_Cur.SHIP_TO_LOCATION_ID ||'|'||pha_Cur.BILL_TO_LOCATION_ID ||'|'||pha_Cur.TERMS_ID ||'|'||pha_Cur.SHIP_VIA_LOOKUP_CODE ||'|'||pha_Cur.FOB_LOOKUP_CODE ||'|'||pha_Cur.FREIGHT_TERMS_LOOKUP_CODE ||'|'||pha_Cur.STATUS_LOOKUP_CODE ||'|'||pha_Cur.CURRENCY_CODE ||'|'||pha_Cur.RATE_TYPE ||'|'||pha_Cur.RATE_DATE ||'|'||pha_Cur.RATE ||'|'||pha_Cur.FROM_HEADER_ID ||'|'||pha_Cur.FROM_TYPE_LOOKUP_CODE ||'|'||pha_Cur.START_DATE
      ||'|'||pha_Cur.END_DATE ||'|'||pha_Cur.BLANKET_TOTAL_AMOUNT ||'|'||pha_Cur.AUTHORIZATION_STATUS ||'|'||pha_Cur.REVISION_NUM ||'|'||pha_Cur.REVISED_DATE ||'|'||pha_Cur.APPROVED_FLAG ||'|'||pha_Cur.APPROVED_DATE ||'|'||pha_Cur.AMOUNT_LIMIT ||'|'||pha_Cur.MIN_RELEASE_AMOUNT ||'|'||pha_Cur.NOTE_TO_AUTHORIZER ||'|'||pha_Cur.NOTE_TO_VENDOR ||'|'||pha_Cur.NOTE_TO_RECEIVER ||'|'||pha_Cur.PRINT_COUNT ||'|'||pha_Cur.PRINTED_DATE ||'|'||pha_Cur.VENDOR_ORDER_NUM ||'|'||pha_Cur.CONFIRMING_ORDER_FLAG ||'|'||pha_Cur.COMMENTS ||'|'||pha_Cur.REPLY_DATE ||'|'||pha_Cur.REPLY_METHOD_LOOKUP_CODE ||'|'||pha_Cur.RFQ_CLOSE_DATE ||'|'||pha_Cur.QUOTE_TYPE_LOOKUP_CODE ||'|'||pha_Cur.QUOTATION_CLASS_CODE ||'|'||pha_Cur.QUOTE_WARNING_DELAY_UNIT ||'|'||pha_Cur.QUOTE_WARNING_DELAY ||'|'||pha_Cur.QUOTE_VENDOR_QUOTE_NUMBER ||'|'||pha_Cur.ACCEPTANCE_REQUIRED_FLAG ||'|'||pha_Cur.ACCEPTANCE_DUE_DATE ||'|'||pha_Cur.CLOSED_DATE ||'|'||pha_Cur.USER_HOLD_FLAG ||'|'||pha_Cur.APPROVAL_REQUIRED_FLAG ||'|'||
      pha_Cur.CANCEL_FLAG ||'|'||pha_Cur.FIRM_STATUS_LOOKUP_CODE ||'|'||pha_Cur.FIRM_DATE ||'|'||pha_Cur.FROZEN_FLAG ||'|'||pha_Cur.SUPPLY_AGREEMENT_FLAG ||'|'||pha_Cur.EDI_PROCESSED_FLAG ||'|'||pha_Cur.EDI_PROCESSED_STATUS ||'|'||pha_Cur.ATTRIBUTE_CATEGORY ||'|'||pha_Cur.ATTRIBUTE1 ||'|'||pha_Cur.ATTRIBUTE2 ||'|'||pha_Cur.ATTRIBUTE3 ||'|'||pha_Cur.ATTRIBUTE4 ||'|'||pha_Cur.ATTRIBUTE5 ||'|'||pha_Cur.ATTRIBUTE6 ||'|'||pha_Cur.ATTRIBUTE7 ||'|'||pha_Cur.ATTRIBUTE8 ||'|'||pha_Cur.ATTRIBUTE9 ||'|'||pha_Cur.ATTRIBUTE10 ||'|'||pha_Cur.ATTRIBUTE11 ||'|'||pha_Cur.ATTRIBUTE12 ||'|'||pha_Cur.ATTRIBUTE13 ||'|'||pha_Cur.ATTRIBUTE14 ||'|'||pha_Cur.ATTRIBUTE15 ||'|'||pha_Cur.CLOSED_CODE ||'|'||pha_Cur.USSGL_TRANSACTION_CODE ||'|'||pha_Cur.GOVERNMENT_CONTEXT ||'|'||pha_Cur.REQUEST_ID ||'|'||pha_Cur.PROGRAM_APPLICATION_ID ||'|'||pha_Cur.PROGRAM_ID ||'|'||pha_Cur.PROGRAM_UPDATE_DATE ||'|'||pha_Cur.ORG_ID ||'|'||pha_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||pha_Cur.GLOBAL_ATTRIBUTE1 ||'|'||
      pha_Cur.GLOBAL_ATTRIBUTE2 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE3 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE4 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE5 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE6 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE7 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE8 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE9 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE10 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE11 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE12 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE13 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE14 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE15 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE16 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE17 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE18 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE19 ||'|'||pha_Cur.GLOBAL_ATTRIBUTE20 ||'|'||pha_Cur.INTERFACE_SOURCE_CODE ||'|'||pha_Cur.REFERENCE_NUM ||'|'||pha_Cur.WF_ITEM_TYPE ||'|'||pha_Cur.WF_ITEM_KEY ||'|'||pha_Cur.MRC_RATE_TYPE ||'|'||pha_Cur.MRC_RATE_DATE ||'|'||pha_Cur.MRC_RATE ||'|'||pha_Cur.PCARD_ID ||'|'||pha_Cur.PRICE_UPDATE_TOLERANCE ||'|'||pha_Cur.PAY_ON_CODE ||'|'||pha_Cur.XML_FLAG ||'|'||pha_Cur.XML_SEND_DATE ||'|'||
      pha_Cur.XML_CHANGE_SEND_DATE ||'|'||pha_Cur.GLOBAL_AGREEMENT_FLAG ||'|'||pha_Cur.CONSIGNED_CONSUMPTION_FLAG ||'|'||pha_Cur.CBC_ACCOUNTING_DATE ||'|'||pha_Cur.CONSUME_REQ_DEMAND_FLAG ||'|'||pha_Cur.CHANGE_REQUESTED_BY ||'|'||pha_Cur.SHIPPING_CONTROL ||'|'||pha_Cur.CONTERMS_EXIST_FLAG ||'|'||pha_Cur.CONTERMS_ARTICLES_UPD_DATE ||'|'||pha_Cur.CONTERMS_DELIV_UPD_DATE ||'|'||pha_Cur.ENCUMBRANCE_REQUIRED_FLAG ||'|'||pha_Cur.PENDING_SIGNATURE_FLAG ||'|'||pha_Cur.CHANGE_SUMMARY ||'|'||pha_Cur.DOCUMENT_CREATION_METHOD ||'|'||pha_Cur.SUBMIT_DATE ||'|'||pha_Cur.ENABLE_ALL_SITES ||'|'||pha_Cur.CREATED_LANGUAGE ||'|'||pha_Cur.CPA_REFERENCE ||'|'||pha_Cur.LAST_UPDATED_PROGRAM ||'|'||pha_Cur.OTM_STATUS_CODE ||'|'||pha_Cur.OTM_RECOVERY_FLAG ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_headers_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_headers_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_headers_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_headers_all;
-- +===================================================================================================+
-- +===============  Extract # 15  ====================================================================+
PROCEDURE Extract_ap_invoices_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_ap_invoices_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_invoices_all                                                |
  -- | Description      : This procedure is used to extract ap_invoices_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date  DATE;
  ld_end_date    DATE;
  ld_description VARCHAR2(240);
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='invoice_id' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'VENDOR_ID' ||'|'||'INVOICE_NUM' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'INVOICE_CURRENCY_CODE' ||'|'||'PAYMENT_CURRENCY_CODE' ||'|'||'PAYMENT_CROSS_RATE' ||'|'||'INVOICE_AMOUNT' ||'|'||'VENDOR_SITE_ID' ||'|'||'AMOUNT_PAID' ||'|'||'DISCOUNT_AMOUNT_TAKEN' ||'|'||'INVOICE_DATE' ||'|'||'SOURCE' ||'|'||'INVOICE_TYPE_LOOKUP_CODE' ||'|'||'DESCRIPTION' ||'|'||'BATCH_ID' ||'|'||'AMOUNT_APPLICABLE_TO_DISCOUNT' ||'|'||'TAX_AMOUNT' ||'|'||'TERMS_ID' ||'|'||'TERMS_DATE' ||'|'||'PAYMENT_METHOD_LOOKUP_CODE' ||'|'||'PAY_GROUP_LOOKUP_CODE' ||'|'||'ACCTS_PAY_CODE_COMBINATION_ID' ||'|'||'PAYMENT_STATUS_FLAG' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'BASE_AMOUNT' ||'|'||'VAT_CODE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'EXCLUSIVE_PAYMENT_FLAG' ||'|'||'PO_HEADER_ID' ||'|'||'FREIGHT_AMOUNT' ||'|'||'GOODS_RECEIVED_DATE' ||'|'||'INVOICE_RECEIVED_DATE' ||'|'||'VOUCHER_NUM' ||'|'||'APPROVED_AMOUNT' ||'|'||
  'RECURRING_PAYMENT_ID' ||'|'||'EXCHANGE_RATE' ||'|'||'EXCHANGE_RATE_TYPE' ||'|'||'EXCHANGE_DATE' ||'|'||'EARLIEST_SETTLEMENT_DATE' ||'|'||'ORIGINAL_PREPAYMENT_AMOUNT' ||'|'||'DOC_SEQUENCE_ID' ||'|'||'DOC_SEQUENCE_VALUE' ||'|'||'DOC_CATEGORY_CODE' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'APPROVAL_STATUS' ||'|'||'APPROVAL_DESCRIPTION' ||'|'||'INVOICE_DISTRIBUTION_TOTAL' ||'|'||'POSTING_STATUS' ||'|'||'PREPAY_FLAG' ||'|'||'AUTHORIZED_BY' ||'|'||'CANCELLED_DATE' ||'|'||'CANCELLED_BY' ||'|'||'CANCELLED_AMOUNT' ||'|'||'TEMP_CANCELLED_AMOUNT' ||'|'||'PROJECT_ACCOUNTING_CONTEXT' ||'|'||'USSGL_TRANSACTION_CODE' ||'|'||'USSGL_TRX_CODE_CONTEXT' ||'|'||'PROJECT_ID' ||'|'||'TASK_ID' ||'|'||
  'EXPENDITURE_TYPE' ||'|'||'EXPENDITURE_ITEM_DATE' ||'|'||'PA_QUANTITY' ||'|'||'EXPENDITURE_ORGANIZATION_ID' ||'|'||'PA_DEFAULT_DIST_CCID' ||'|'||'VENDOR_PREPAY_AMOUNT' ||'|'||'PAYMENT_AMOUNT_TOTAL' ||'|'||'AWT_FLAG' ||'|'||'AWT_GROUP_ID' ||'|'||'REFERENCE_1' ||'|'||'REFERENCE_2' ||'|'||'ORG_ID' ||'|'||'PRE_WITHHOLDING_AMOUNT' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'AUTO_TAX_CALC_FLAG' ||'|'||'PAYMENT_CROSS_RATE_TYPE' ||'|'||
  'PAYMENT_CROSS_RATE_DATE' ||'|'||'PAY_CURR_INVOICE_AMOUNT' ||'|'||'MRC_BASE_AMOUNT' ||'|'||'MRC_EXCHANGE_RATE' ||'|'||'MRC_EXCHANGE_RATE_TYPE' ||'|'||'MRC_EXCHANGE_DATE' ||'|'||'GL_DATE' ||'|'||'AWARD_ID' ||'|'||'PAID_ON_BEHALF_EMPLOYEE_ID' ||'|'||'AMT_DUE_CCARD_COMPANY' ||'|'||'AMT_DUE_EMPLOYEE' ||'|'||'APPROVAL_READY_FLAG' ||'|'||'APPROVAL_ITERATION' ||'|'||'WFAPPROVAL_STATUS' ||'|'||'REQUESTER_ID' ||'|'||'VALIDATION_REQUEST_ID' ||'|'||'VALIDATED_TAX_AMOUNT' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR aia_Cur IN
    (SELECT INVOICE_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      VENDOR_ID ,
      INVOICE_NUM ,
      SET_OF_BOOKS_ID ,
      INVOICE_CURRENCY_CODE ,
      PAYMENT_CURRENCY_CODE ,
      PAYMENT_CROSS_RATE ,
      INVOICE_AMOUNT ,
      VENDOR_SITE_ID ,
      AMOUNT_PAID ,
      DISCOUNT_AMOUNT_TAKEN ,
      INVOICE_DATE ,
      SOURCE ,
      INVOICE_TYPE_LOOKUP_CODE ,
      DESCRIPTION ,
      BATCH_ID ,
      AMOUNT_APPLICABLE_TO_DISCOUNT ,
      TAX_AMOUNT ,
      TERMS_ID ,
      TERMS_DATE ,
      PAYMENT_METHOD_LOOKUP_CODE ,
      PAY_GROUP_LOOKUP_CODE ,
      ACCTS_PAY_CODE_COMBINATION_ID ,
      PAYMENT_STATUS_FLAG ,
      CREATION_DATE ,
      CREATED_BY ,
      BASE_AMOUNT ,
      VAT_CODE ,
      LAST_UPDATE_LOGIN ,
      EXCLUSIVE_PAYMENT_FLAG ,
      PO_HEADER_ID ,
      FREIGHT_AMOUNT ,
      GOODS_RECEIVED_DATE ,
      INVOICE_RECEIVED_DATE ,
      VOUCHER_NUM ,
      APPROVED_AMOUNT ,
      RECURRING_PAYMENT_ID ,
      EXCHANGE_RATE ,
      EXCHANGE_RATE_TYPE ,
      EXCHANGE_DATE ,
      EARLIEST_SETTLEMENT_DATE ,
      ORIGINAL_PREPAYMENT_AMOUNT ,
      DOC_SEQUENCE_ID ,
      DOC_SEQUENCE_VALUE ,
      DOC_CATEGORY_CODE ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      ATTRIBUTE_CATEGORY ,
      APPROVAL_STATUS ,
      APPROVAL_DESCRIPTION ,
      INVOICE_DISTRIBUTION_TOTAL ,
      POSTING_STATUS ,
      PREPAY_FLAG ,
      AUTHORIZED_BY ,
      CANCELLED_DATE ,
      CANCELLED_BY ,
      CANCELLED_AMOUNT ,
      TEMP_CANCELLED_AMOUNT ,
      PROJECT_ACCOUNTING_CONTEXT ,
      USSGL_TRANSACTION_CODE ,
      USSGL_TRX_CODE_CONTEXT ,
      PROJECT_ID ,
      TASK_ID ,
      EXPENDITURE_TYPE ,
      EXPENDITURE_ITEM_DATE ,
      PA_QUANTITY ,
      EXPENDITURE_ORGANIZATION_ID ,
      PA_DEFAULT_DIST_CCID ,
      VENDOR_PREPAY_AMOUNT ,
      PAYMENT_AMOUNT_TOTAL ,
      AWT_FLAG ,
      AWT_GROUP_ID ,
      REFERENCE_1 ,
      REFERENCE_2 ,
      ORG_ID ,
      PRE_WITHHOLDING_AMOUNT ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      AUTO_TAX_CALC_FLAG ,
      PAYMENT_CROSS_RATE_TYPE ,
      PAYMENT_CROSS_RATE_DATE ,
      PAY_CURR_INVOICE_AMOUNT ,
      MRC_BASE_AMOUNT ,
      MRC_EXCHANGE_RATE ,
      MRC_EXCHANGE_RATE_TYPE ,
      MRC_EXCHANGE_DATE ,
      GL_DATE ,
      AWARD_ID ,
      PAID_ON_BEHALF_EMPLOYEE_ID ,
      AMT_DUE_CCARD_COMPANY ,
      AMT_DUE_EMPLOYEE ,
      APPROVAL_READY_FLAG ,
      APPROVAL_ITERATION ,
      WFAPPROVAL_STATUS ,
      REQUESTER_ID ,
      VALIDATION_REQUEST_ID ,
      VALIDATED_TAX_AMOUNT
    FROM ap_invoices_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      ld_description   :=aia_Cur.description;
      IF aia_Cur.SOURCE = 'US_OD_PAYROLL_GARNISHMENT' THEN
        ld_description := ' ';
      END IF;
      l_data:=aia_Cur.invoice_id ||'|'||aia_Cur.LAST_UPDATE_DATE ||'|'||aia_Cur.LAST_UPDATED_BY ||'|'||aia_Cur.VENDOR_ID ||'|'||aia_Cur.INVOICE_NUM ||'|'||aia_Cur.SET_OF_BOOKS_ID ||'|'||aia_Cur.INVOICE_CURRENCY_CODE ||'|'||aia_Cur.PAYMENT_CURRENCY_CODE ||'|'||aia_Cur.PAYMENT_CROSS_RATE ||'|'||aia_Cur.INVOICE_AMOUNT ||'|'||aia_Cur.VENDOR_SITE_ID ||'|'||aia_Cur.AMOUNT_PAID ||'|'||aia_Cur.DISCOUNT_AMOUNT_TAKEN ||'|'||aia_Cur.INVOICE_DATE ||'|'||aia_Cur.SOURCE ||'|'||aia_Cur.INVOICE_TYPE_LOOKUP_CODE ||'|'||ld_description ||'|'||aia_Cur.BATCH_ID ||'|'||aia_Cur.AMOUNT_APPLICABLE_TO_DISCOUNT ||'|'||aia_Cur.TAX_AMOUNT ||'|'||aia_Cur.TERMS_ID ||'|'||aia_Cur.TERMS_DATE ||'|'||aia_Cur.PAYMENT_METHOD_LOOKUP_CODE ||'|'||aia_Cur.PAY_GROUP_LOOKUP_CODE ||'|'||aia_Cur.ACCTS_PAY_CODE_COMBINATION_ID ||'|'||aia_Cur.PAYMENT_STATUS_FLAG ||'|'||aia_Cur.CREATION_DATE ||'|'||aia_Cur.CREATED_BY ||'|'||aia_Cur.BASE_AMOUNT ||'|'||aia_Cur.VAT_CODE ||'|'||aia_Cur.LAST_UPDATE_LOGIN ||'|'||
      aia_Cur.EXCLUSIVE_PAYMENT_FLAG ||'|'||aia_Cur.PO_HEADER_ID ||'|'||aia_Cur.FREIGHT_AMOUNT ||'|'||aia_Cur.GOODS_RECEIVED_DATE ||'|'||aia_Cur.INVOICE_RECEIVED_DATE ||'|'||aia_Cur.VOUCHER_NUM ||'|'||aia_Cur.APPROVED_AMOUNT ||'|'||aia_Cur.RECURRING_PAYMENT_ID ||'|'||aia_Cur.EXCHANGE_RATE ||'|'||aia_Cur.EXCHANGE_RATE_TYPE ||'|'||aia_Cur.EXCHANGE_DATE ||'|'||aia_Cur.EARLIEST_SETTLEMENT_DATE ||'|'||aia_Cur.ORIGINAL_PREPAYMENT_AMOUNT ||'|'||aia_Cur.DOC_SEQUENCE_ID ||'|'||aia_Cur.DOC_SEQUENCE_VALUE ||'|'||aia_Cur.DOC_CATEGORY_CODE ||'|'||aia_Cur.ATTRIBUTE1 ||'|'||aia_Cur.ATTRIBUTE2 ||'|'||aia_Cur.ATTRIBUTE3 ||'|'||aia_Cur.ATTRIBUTE4 ||'|'||aia_Cur.ATTRIBUTE5 ||'|'||aia_Cur.ATTRIBUTE6 ||'|'||aia_Cur.ATTRIBUTE7 ||'|'||aia_Cur.ATTRIBUTE8 ||'|'||aia_Cur.ATTRIBUTE9 ||'|'||aia_Cur.ATTRIBUTE10 ||'|'||aia_Cur.ATTRIBUTE11 ||'|'||aia_Cur.ATTRIBUTE12 ||'|'||aia_Cur.ATTRIBUTE13 ||'|'||aia_Cur.ATTRIBUTE14 ||'|'||aia_Cur.ATTRIBUTE15 ||'|'||aia_Cur.ATTRIBUTE_CATEGORY ||'|'||aia_Cur.APPROVAL_STATUS ||
      '|'||aia_Cur.APPROVAL_DESCRIPTION ||'|'||aia_Cur.INVOICE_DISTRIBUTION_TOTAL ||'|'||aia_Cur.POSTING_STATUS ||'|'||aia_Cur.PREPAY_FLAG ||'|'||aia_Cur.AUTHORIZED_BY ||'|'||aia_Cur.CANCELLED_DATE ||'|'||aia_Cur.CANCELLED_BY ||'|'||aia_Cur.CANCELLED_AMOUNT ||'|'||aia_Cur.TEMP_CANCELLED_AMOUNT ||'|'||aia_Cur.PROJECT_ACCOUNTING_CONTEXT ||'|'||aia_Cur.USSGL_TRANSACTION_CODE ||'|'||aia_Cur.USSGL_TRX_CODE_CONTEXT ||'|'||aia_Cur.PROJECT_ID ||'|'||aia_Cur.TASK_ID ||'|'||aia_Cur.EXPENDITURE_TYPE ||'|'||aia_Cur.EXPENDITURE_ITEM_DATE ||'|'||aia_Cur.PA_QUANTITY ||'|'||aia_Cur.EXPENDITURE_ORGANIZATION_ID ||'|'||aia_Cur.PA_DEFAULT_DIST_CCID ||'|'||aia_Cur.VENDOR_PREPAY_AMOUNT ||'|'||aia_Cur.PAYMENT_AMOUNT_TOTAL ||'|'||aia_Cur.AWT_FLAG ||'|'||aia_Cur.AWT_GROUP_ID ||'|'||aia_Cur.REFERENCE_1 ||'|'||aia_Cur.REFERENCE_2 ||'|'||aia_Cur.ORG_ID ||'|'||aia_Cur.PRE_WITHHOLDING_AMOUNT ||'|'||aia_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||aia_Cur.GLOBAL_ATTRIBUTE1 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE2 ||'|'||
      aia_Cur.GLOBAL_ATTRIBUTE3 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE4 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE5 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE6 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE7 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE8 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE9 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE10 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE11 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE12 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE13 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE14 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE15 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE16 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE17 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE18 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE19 ||'|'||aia_Cur.GLOBAL_ATTRIBUTE20 ||'|'||aia_Cur.AUTO_TAX_CALC_FLAG ||'|'||aia_Cur.PAYMENT_CROSS_RATE_TYPE ||'|'||aia_Cur.PAYMENT_CROSS_RATE_DATE ||'|'||aia_Cur.PAY_CURR_INVOICE_AMOUNT ||'|'||aia_Cur.MRC_BASE_AMOUNT ||'|'||aia_Cur.MRC_EXCHANGE_RATE ||'|'||aia_Cur.MRC_EXCHANGE_RATE_TYPE ||'|'||aia_Cur.MRC_EXCHANGE_DATE ||'|'||aia_Cur.GL_DATE ||'|'||aia_Cur.AWARD_ID ||'|'||aia_Cur.PAID_ON_BEHALF_EMPLOYEE_ID ||'|'||
      aia_Cur.AMT_DUE_CCARD_COMPANY ||'|'||aia_Cur.AMT_DUE_EMPLOYEE ||'|'||aia_Cur.APPROVAL_READY_FLAG ||'|'||aia_Cur.APPROVAL_ITERATION ||'|'||aia_Cur.WFAPPROVAL_STATUS ||'|'||aia_Cur.REQUESTER_ID ||'|'||aia_Cur.VALIDATION_REQUEST_ID ||'|'||aia_Cur.VALIDATED_TAX_AMOUNT ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_invoices_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_invoices_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in ap_invoices_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_invoices_all;
-- +=================================================================================================+
-- +===============  Extract # 16  ====================================================================+
PROCEDURE Extract_ap_batches_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_ap_batches_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_batches_all                                                |
  -- | Description      : This procedure is used to extract ap_batches_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='BATCH_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'BATCH_NAME' ||'|'||'BATCH_DATE' ||'|'||'CONTROL_INVOICE_COUNT' ||'|'||'CONTROL_INVOICE_TOTAL' ||'|'||'ACTUAL_INVOICE_COUNT' ||'|'||'ACTUAL_INVOICE_TOTAL' ||'|'||'INVOICE_CURRENCY_CODE' ||'|'||'PAYMENT_CURRENCY_CODE' ||'|'||'PAY_GROUP_LOOKUP_CODE' ||'|'||'BATCH_CODE_COMBINATION_ID' ||'|'||'TERMS_ID' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'INVOICE_TYPE_LOOKUP_CODE' ||'|'||'HOLD_LOOKUP_CODE' ||'|'||'HOLD_REASON' ||'|'||'DOC_CATEGORY_CODE' ||'|'||'ORG_ID' ||'|'||'GL_DATE' ||'|'||'PAYMENT_PRIORITY' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR aba_Cur IN
    (SELECT BATCH_ID ,
      BATCH_NAME ,
      BATCH_DATE ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CONTROL_INVOICE_COUNT ,
      CONTROL_INVOICE_TOTAL ,
      ACTUAL_INVOICE_COUNT ,
      ACTUAL_INVOICE_TOTAL ,
      INVOICE_CURRENCY_CODE ,
      PAYMENT_CURRENCY_CODE ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      PAY_GROUP_LOOKUP_CODE ,
      BATCH_CODE_COMBINATION_ID ,
      TERMS_ID ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      INVOICE_TYPE_LOOKUP_CODE ,
      HOLD_LOOKUP_CODE ,
      HOLD_REASON ,
      DOC_CATEGORY_CODE ,
      ORG_ID ,
      GL_DATE ,
      PAYMENT_PRIORITY
    FROM ap_batches_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=aba_Cur.batch_id ||'|'||aba_Cur.LAST_UPDATE_DATE ||'|'||aba_Cur.LAST_UPDATED_BY ||'|'||aba_Cur.CREATION_DATE ||'|'||aba_Cur.CREATED_BY ||'|'||aba_Cur.LAST_UPDATE_LOGIN ||'|'||aba_Cur.BATCH_NAME ||'|'||aba_Cur.BATCH_DATE ||'|'||aba_Cur.CONTROL_INVOICE_COUNT ||'|'||aba_Cur.CONTROL_INVOICE_TOTAL ||'|'||aba_Cur.ACTUAL_INVOICE_COUNT ||'|'||aba_Cur.ACTUAL_INVOICE_TOTAL ||'|'||aba_Cur.INVOICE_CURRENCY_CODE ||'|'||aba_Cur.PAYMENT_CURRENCY_CODE ||'|'||aba_Cur.PAY_GROUP_LOOKUP_CODE ||'|'||aba_Cur.BATCH_CODE_COMBINATION_ID ||'|'||aba_Cur.TERMS_ID ||'|'||aba_Cur.ATTRIBUTE_CATEGORY ||'|'||aba_Cur.ATTRIBUTE1 ||'|'||aba_Cur.ATTRIBUTE2 ||'|'||aba_Cur.ATTRIBUTE3 ||'|'||aba_Cur.ATTRIBUTE4 ||'|'||aba_Cur.ATTRIBUTE5 ||'|'||aba_Cur.ATTRIBUTE6 ||'|'||aba_Cur.ATTRIBUTE7 ||'|'||aba_Cur.ATTRIBUTE8 ||'|'||aba_Cur.ATTRIBUTE9 ||'|'||aba_Cur.ATTRIBUTE10 ||'|'||aba_Cur.ATTRIBUTE11 ||'|'||aba_Cur.ATTRIBUTE12 ||'|'||aba_Cur.ATTRIBUTE13 ||'|'||aba_Cur.ATTRIBUTE14 ||'|'||aba_Cur.ATTRIBUTE15 ||'|'||
      aba_Cur.INVOICE_TYPE_LOOKUP_CODE ||'|'||aba_Cur.HOLD_LOOKUP_CODE ||'|'||aba_Cur.HOLD_REASON ||'|'||aba_Cur.DOC_CATEGORY_CODE ||'|'||aba_Cur.ORG_ID ||'|'||aba_Cur.GL_DATE ||'|'||aba_Cur.PAYMENT_PRIORITY ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_batches_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_batches_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in ap_batches_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_batches_all;
-- +=================================================================================================+
-- +===============  Extract # 17  ====================================================================+
PROCEDURE Extract_po_vendor_sites_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_vendor_sites_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_vendor_sites_all                                                |
  -- | Description      : This procedure is used to extract po_vendor_sites_all                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='VENDOR_SITE_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'VENDOR_ID' ||'|'||'VENDOR_SITE_CODE' ||'|'||'VENDOR_SITE_CODE_ALT' ||'|'||'PURCHASING_SITE_FLAG' ||'|'||'RFQ_ONLY_SITE_FLAG' ||'|'||'PAY_SITE_FLAG' ||'|'||'ATTENTION_AR_FLAG' ||'|'||'ADDRESS_LINE1' ||'|'||'ADDRESS_LINES_ALT' ||'|'||'ADDRESS_LINE2' ||'|'||'ADDRESS_LINE3' ||'|'||'CITY' ||'|'||'STATE' ||'|'||'ZIP' ||'|'||'PROVINCE' ||'|'||'COUNTRY' ||'|'||'AREA_CODE' ||'|'||'PHONE' ||'|'||'CUSTOMER_NUM' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'BILL_TO_LOCATION_ID' ||'|'||'SHIP_VIA_LOOKUP_CODE' ||'|'||'FREIGHT_TERMS_LOOKUP_CODE' ||'|'||'FOB_LOOKUP_CODE' ||'|'||'INACTIVE_DATE' ||'|'||'FAX' ||'|'||'FAX_AREA_CODE' ||'|'||'TELEX' ||'|'||'PAYMENT_METHOD_LOOKUP_CODE' ||'|'||'BANK_ACCOUNT_NAME' ||'|'||'BANK_ACCOUNT_NUM' ||'|'||'BANK_NUM' ||'|'||'BANK_ACCOUNT_TYPE' ||'|'||'TERMS_DATE_BASIS' ||'|'||'CURRENT_CATALOG_NUM' ||'|'||'VAT_CODE' ||
  '|'||'DISTRIBUTION_SET_ID' ||'|'||'ACCTS_PAY_CODE_COMBINATION_ID' ||'|'||'PREPAY_CODE_COMBINATION_ID' ||'|'||'PAY_GROUP_LOOKUP_CODE' ||'|'||'PAYMENT_PRIORITY' ||'|'||'TERMS_ID' ||'|'||'INVOICE_AMOUNT_LIMIT' ||'|'||'PAY_DATE_BASIS_LOOKUP_CODE' ||'|'||'ALWAYS_TAKE_DISC_FLAG' ||'|'||'INVOICE_CURRENCY_CODE' ||'|'||'PAYMENT_CURRENCY_CODE' ||'|'||'HOLD_ALL_PAYMENTS_FLAG' ||'|'||'HOLD_FUTURE_PAYMENTS_FLAG' ||'|'||'HOLD_REASON' ||'|'||'HOLD_UNMATCHED_INVOICES_FLAG' ||'|'||'AP_TAX_ROUNDING_RULE' ||'|'||'AUTO_TAX_CALC_FLAG' ||'|'||'AUTO_TAX_CALC_OVERRIDE' ||'|'||'AMOUNT_INCLUDES_TAX_FLAG' ||'|'||'EXCLUSIVE_PAYMENT_FLAG' ||'|'||'TAX_REPORTING_SITE_FLAG' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||
  'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'VALIDATION_NUMBER' ||'|'||'EXCLUDE_FREIGHT_FROM_DISCOUNT' ||'|'||'VAT_REGISTRATION_NUM' ||'|'||'OFFSET_VAT_CODE' ||'|'||'ORG_ID' ||'|'||'CHECK_DIGITS' ||'|'||'BANK_NUMBER' ||'|'||'ADDRESS_LINE4' ||'|'||'COUNTY' ||'|'||'ADDRESS_STYLE' ||'|'||'LANGUAGE' ||'|'||'ALLOW_AWT_FLAG' ||'|'||'AWT_GROUP_ID' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||
  'EDI_TRANSACTION_HANDLING' ||'|'||'EDI_ID_NUMBER' ||'|'||'EDI_PAYMENT_METHOD' ||'|'||'EDI_PAYMENT_FORMAT' ||'|'||'EDI_REMITTANCE_METHOD' ||'|'||'BANK_CHARGE_BEARER' ||'|'||'EDI_REMITTANCE_INSTRUCTION' ||'|'||'BANK_BRANCH_TYPE' ||'|'||'PAY_ON_CODE' ||'|'||'DEFAULT_PAY_SITE_ID' ||'|'||'PAY_ON_RECEIPT_SUMMARY_CODE' ||'|'||'TP_HEADER_ID' ||'|'||'ECE_TP_LOCATION_CODE' ||'|'||'PCARD_SITE_FLAG' ||'|'||'MATCH_OPTION' ||'|'||'COUNTRY_OF_ORIGIN_CODE' ||'|'||'FUTURE_DATED_PAYMENT_CCID' ||'|'||'CREATE_DEBIT_MEMO_FLAG' ||'|'||'OFFSET_TAX_FLAG' ||'|'||'SUPPLIER_NOTIF_METHOD' ||'|'||'EMAIL_ADDRESS' ||'|'||'REMITTANCE_EMAIL' ||'|'||'PRIMARY_PAY_SITE_FLAG' ||'|'||'SHIPPING_CONTROL' ||'|'||'SELLING_COMPANY_IDENTIFIER' ||'|'||'GAPLESS_INV_NUM_FLAG' ||'|'||'DUNS_NUMBER' ||'|'||'TOLERANCE_ID' ||'|'||'SERVICES_TOLERANCE_ID' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pvsa_Cur IN
    (SELECT VENDOR_SITE_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      VENDOR_ID ,
      VENDOR_SITE_CODE ,
      VENDOR_SITE_CODE_ALT ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      PURCHASING_SITE_FLAG ,
      RFQ_ONLY_SITE_FLAG ,
      PAY_SITE_FLAG ,
      ATTENTION_AR_FLAG ,
      ADDRESS_LINE1 ,
      ADDRESS_LINES_ALT ,
      ADDRESS_LINE2 ,
      ADDRESS_LINE3 ,
      CITY ,
      STATE ,
      ZIP ,
      PROVINCE ,
      COUNTRY ,
      AREA_CODE ,
      PHONE ,
      CUSTOMER_NUM ,
      SHIP_TO_LOCATION_ID ,
      BILL_TO_LOCATION_ID ,
      SHIP_VIA_LOOKUP_CODE ,
      FREIGHT_TERMS_LOOKUP_CODE ,
      FOB_LOOKUP_CODE ,
      INACTIVE_DATE ,
      FAX ,
      FAX_AREA_CODE ,
      TELEX ,
      PAYMENT_METHOD_LOOKUP_CODE ,
      BANK_ACCOUNT_NAME ,
      BANK_ACCOUNT_NUM ,
      BANK_NUM ,
      BANK_ACCOUNT_TYPE ,
      TERMS_DATE_BASIS ,
      CURRENT_CATALOG_NUM ,
      VAT_CODE ,
      DISTRIBUTION_SET_ID ,
      ACCTS_PAY_CODE_COMBINATION_ID ,
      PREPAY_CODE_COMBINATION_ID ,
      PAY_GROUP_LOOKUP_CODE ,
      PAYMENT_PRIORITY ,
      TERMS_ID ,
      INVOICE_AMOUNT_LIMIT ,
      PAY_DATE_BASIS_LOOKUP_CODE ,
      ALWAYS_TAKE_DISC_FLAG ,
      INVOICE_CURRENCY_CODE ,
      PAYMENT_CURRENCY_CODE ,
      HOLD_ALL_PAYMENTS_FLAG ,
      HOLD_FUTURE_PAYMENTS_FLAG ,
      HOLD_REASON ,
      HOLD_UNMATCHED_INVOICES_FLAG ,
      AP_TAX_ROUNDING_RULE ,
      AUTO_TAX_CALC_FLAG ,
      AUTO_TAX_CALC_OVERRIDE ,
      AMOUNT_INCLUDES_TAX_FLAG ,
      EXCLUSIVE_PAYMENT_FLAG ,
      TAX_REPORTING_SITE_FLAG ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      VALIDATION_NUMBER ,
      EXCLUDE_FREIGHT_FROM_DISCOUNT ,
      VAT_REGISTRATION_NUM ,
      OFFSET_VAT_CODE ,
      ORG_ID ,
      CHECK_DIGITS ,
      BANK_NUMBER ,
      ADDRESS_LINE4 ,
      COUNTY ,
      ADDRESS_STYLE ,
      LANGUAGE ,
      ALLOW_AWT_FLAG ,
      AWT_GROUP_ID ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      EDI_TRANSACTION_HANDLING ,
      EDI_ID_NUMBER ,
      EDI_PAYMENT_METHOD ,
      EDI_PAYMENT_FORMAT ,
      EDI_REMITTANCE_METHOD ,
      BANK_CHARGE_BEARER ,
      EDI_REMITTANCE_INSTRUCTION ,
      BANK_BRANCH_TYPE ,
      PAY_ON_CODE ,
      DEFAULT_PAY_SITE_ID ,
      PAY_ON_RECEIPT_SUMMARY_CODE ,
      TP_HEADER_ID ,
      ECE_TP_LOCATION_CODE ,
      PCARD_SITE_FLAG ,
      MATCH_OPTION ,
      COUNTRY_OF_ORIGIN_CODE ,
      FUTURE_DATED_PAYMENT_CCID ,
      CREATE_DEBIT_MEMO_FLAG ,
      OFFSET_TAX_FLAG ,
      SUPPLIER_NOTIF_METHOD ,
      EMAIL_ADDRESS ,
      REMITTANCE_EMAIL ,
      PRIMARY_PAY_SITE_FLAG ,
      SHIPPING_CONTROL ,
      SELLING_COMPANY_IDENTIFIER ,
      GAPLESS_INV_NUM_FLAG ,
      DUNS_NUMBER ,
      TOLERANCE_ID ,
      SERVICES_TOLERANCE_ID
    FROM ap_supplier_sites_all -- Modified for R12 po_vendor_sites_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=pvsa_Cur.vendor_site_id ||'|'||pvsa_Cur.LAST_UPDATE_DATE ||'|'||pvsa_Cur.LAST_UPDATED_BY ||'|'||pvsa_Cur.CREATION_DATE ||'|'||pvsa_Cur.CREATED_BY ||'|'||pvsa_Cur.LAST_UPDATE_LOGIN ||'|'||pvsa_Cur.VENDOR_ID ||'|'||pvsa_Cur.VENDOR_SITE_CODE ||'|'||pvsa_Cur.VENDOR_SITE_CODE_ALT ||'|'||pvsa_Cur.PURCHASING_SITE_FLAG ||'|'||pvsa_Cur.RFQ_ONLY_SITE_FLAG ||'|'||pvsa_Cur.PAY_SITE_FLAG ||'|'||pvsa_Cur.ATTENTION_AR_FLAG ||'|'||pvsa_Cur.ADDRESS_LINE1 ||'|'||pvsa_Cur.ADDRESS_LINES_ALT ||'|'||pvsa_Cur.ADDRESS_LINE2 ||'|'||pvsa_Cur.ADDRESS_LINE3 ||'|'||pvsa_Cur.CITY ||'|'||pvsa_Cur.STATE ||'|'||pvsa_Cur.ZIP ||'|'||pvsa_Cur.PROVINCE ||'|'||pvsa_Cur.COUNTRY ||'|'||pvsa_Cur.AREA_CODE ||'|'||pvsa_Cur.PHONE ||'|'||pvsa_Cur.CUSTOMER_NUM ||'|'||pvsa_Cur.SHIP_TO_LOCATION_ID ||'|'||pvsa_Cur.BILL_TO_LOCATION_ID ||'|'||pvsa_Cur.SHIP_VIA_LOOKUP_CODE ||'|'||pvsa_Cur.FREIGHT_TERMS_LOOKUP_CODE ||'|'||pvsa_Cur.FOB_LOOKUP_CODE ||'|'||pvsa_Cur.INACTIVE_DATE ||'|'||pvsa_Cur.FAX ||'|'||
      pvsa_Cur.FAX_AREA_CODE ||'|'||pvsa_Cur.TELEX ||'|'||pvsa_Cur.PAYMENT_METHOD_LOOKUP_CODE ||'|'||pvsa_Cur.BANK_ACCOUNT_NAME
      --           ||'|'||pvsa_Cur.BANK_ACCOUNT_NUM
      --           ||'|'||pvsa_Cur.BANK_NUM
      ||'|'||' ' ||'|'||' ' ||'|'||pvsa_Cur.BANK_ACCOUNT_TYPE ||'|'||pvsa_Cur.TERMS_DATE_BASIS ||'|'||pvsa_Cur.CURRENT_CATALOG_NUM ||'|'||pvsa_Cur.VAT_CODE ||'|'||pvsa_Cur.DISTRIBUTION_SET_ID ||'|'||pvsa_Cur.ACCTS_PAY_CODE_COMBINATION_ID ||'|'||pvsa_Cur.PREPAY_CODE_COMBINATION_ID ||'|'||pvsa_Cur.PAY_GROUP_LOOKUP_CODE ||'|'||pvsa_Cur.PAYMENT_PRIORITY ||'|'||pvsa_Cur.TERMS_ID ||'|'||pvsa_Cur.INVOICE_AMOUNT_LIMIT ||'|'||pvsa_Cur.PAY_DATE_BASIS_LOOKUP_CODE ||'|'||pvsa_Cur.ALWAYS_TAKE_DISC_FLAG ||'|'||pvsa_Cur.INVOICE_CURRENCY_CODE ||'|'||pvsa_Cur.PAYMENT_CURRENCY_CODE ||'|'||pvsa_Cur.HOLD_ALL_PAYMENTS_FLAG ||'|'||pvsa_Cur.HOLD_FUTURE_PAYMENTS_FLAG ||'|'||pvsa_Cur.HOLD_REASON ||'|'||pvsa_Cur.HOLD_UNMATCHED_INVOICES_FLAG ||'|'||pvsa_Cur.AP_TAX_ROUNDING_RULE ||'|'||pvsa_Cur.AUTO_TAX_CALC_FLAG ||'|'||pvsa_Cur.AUTO_TAX_CALC_OVERRIDE ||'|'||pvsa_Cur.AMOUNT_INCLUDES_TAX_FLAG ||'|'||pvsa_Cur.EXCLUSIVE_PAYMENT_FLAG ||'|'||pvsa_Cur.TAX_REPORTING_SITE_FLAG ||'|'||pvsa_Cur.ATTRIBUTE_CATEGORY ||'|'||
      pvsa_Cur.ATTRIBUTE1 ||'|'||pvsa_Cur.ATTRIBUTE2 ||'|'||pvsa_Cur.ATTRIBUTE3 ||'|'||pvsa_Cur.ATTRIBUTE4 ||'|'||pvsa_Cur.ATTRIBUTE5 ||'|'||pvsa_Cur.ATTRIBUTE6 ||'|'||pvsa_Cur.ATTRIBUTE7 ||'|'||pvsa_Cur.ATTRIBUTE8 ||'|'||pvsa_Cur.ATTRIBUTE9 ||'|'||pvsa_Cur.ATTRIBUTE10 ||'|'||pvsa_Cur.ATTRIBUTE11 ||'|'||pvsa_Cur.ATTRIBUTE12 ||'|'||pvsa_Cur.ATTRIBUTE13 ||'|'||pvsa_Cur.ATTRIBUTE14 ||'|'||pvsa_Cur.ATTRIBUTE15 ||'|'||pvsa_Cur.REQUEST_ID ||'|'||pvsa_Cur.PROGRAM_APPLICATION_ID ||'|'||pvsa_Cur.PROGRAM_ID ||'|'||pvsa_Cur.PROGRAM_UPDATE_DATE ||'|'||pvsa_Cur.VALIDATION_NUMBER ||'|'||pvsa_Cur.EXCLUDE_FREIGHT_FROM_DISCOUNT ||'|'||pvsa_Cur.VAT_REGISTRATION_NUM ||'|'||pvsa_Cur.OFFSET_VAT_CODE ||'|'||pvsa_Cur.ORG_ID ||'|'||pvsa_Cur.CHECK_DIGITS
      --         ||'|'||pvsa_Cur.BANK_NUMBER
      ||'|'||' ' ||'|'||pvsa_Cur.ADDRESS_LINE4 ||'|'||pvsa_Cur.COUNTY ||'|'||pvsa_Cur.ADDRESS_STYLE ||'|'||pvsa_Cur.LANGUAGE ||'|'||pvsa_Cur.ALLOW_AWT_FLAG ||'|'||pvsa_Cur.AWT_GROUP_ID ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE1 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE2 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE3 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE4 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE5 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE6 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE7 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE8 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE9 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE10 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE11 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE12 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE13 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE14 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE15 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE16 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE17 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE18 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE19 ||'|'||pvsa_Cur.GLOBAL_ATTRIBUTE20 ||'|'||pvsa_Cur.EDI_TRANSACTION_HANDLING ||'|'||pvsa_Cur.EDI_ID_NUMBER ||'|'||
      pvsa_Cur.EDI_PAYMENT_METHOD ||'|'||pvsa_Cur.EDI_PAYMENT_FORMAT ||'|'||pvsa_Cur.EDI_REMITTANCE_METHOD ||'|'||pvsa_Cur.BANK_CHARGE_BEARER ||'|'||pvsa_Cur.EDI_REMITTANCE_INSTRUCTION ||'|'||pvsa_Cur.BANK_BRANCH_TYPE ||'|'||pvsa_Cur.PAY_ON_CODE ||'|'||pvsa_Cur.DEFAULT_PAY_SITE_ID ||'|'||pvsa_Cur.PAY_ON_RECEIPT_SUMMARY_CODE ||'|'||pvsa_Cur.TP_HEADER_ID ||'|'||pvsa_Cur.ECE_TP_LOCATION_CODE ||'|'||pvsa_Cur.PCARD_SITE_FLAG ||'|'||pvsa_Cur.MATCH_OPTION ||'|'||pvsa_Cur.COUNTRY_OF_ORIGIN_CODE ||'|'||pvsa_Cur.FUTURE_DATED_PAYMENT_CCID ||'|'||pvsa_Cur.CREATE_DEBIT_MEMO_FLAG ||'|'||pvsa_Cur.OFFSET_TAX_FLAG ||'|'||pvsa_Cur.SUPPLIER_NOTIF_METHOD ||'|'||pvsa_Cur.EMAIL_ADDRESS ||'|'||pvsa_Cur.REMITTANCE_EMAIL ||'|'||pvsa_Cur.PRIMARY_PAY_SITE_FLAG ||'|'||pvsa_Cur.SHIPPING_CONTROL ||'|'||pvsa_Cur.SELLING_COMPANY_IDENTIFIER ||'|'||pvsa_Cur.GAPLESS_INV_NUM_FLAG ||'|'||pvsa_Cur.DUNS_NUMBER ||'|'||pvsa_Cur.TOLERANCE_ID ||'|'||pvsa_Cur.SERVICES_TOLERANCE_ID ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_vendor_sites_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_vendor_sites_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_vendor_sites_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_vendor_sites_all;
-- +=================================================================================================+
-- +===============  Extract # 18  ====================================================================+
PROCEDURE Extract_po_vendors(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_vendors.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_vendors                                               |
  -- | Description      : This procedure is used to extract po_vendors                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
  ld_num_1099   VARCHAR2(30);
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='VENDOR_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'VENDOR_NAME' ||'|'||'VENDOR_NAME_ALT' ||'|'||'SEGMENT1' ||'|'||'SUMMARY_FLAG' ||'|'||'ENABLED_FLAG' ||'|'||'SEGMENT2' ||'|'||'SEGMENT3' ||'|'||'SEGMENT4' ||'|'||'SEGMENT5' ||'|'||'EMPLOYEE_ID' ||'|'||'VENDOR_TYPE_LOOKUP_CODE' ||'|'||'CUSTOMER_NUM' ||'|'||'ONE_TIME_FLAG' ||'|'||'PARENT_VENDOR_ID' ||'|'||'MIN_ORDER_AMOUNT' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'BILL_TO_LOCATION_ID' ||'|'||'SHIP_VIA_LOOKUP_CODE' ||'|'||'FREIGHT_TERMS_LOOKUP_CODE' ||'|'||'FOB_LOOKUP_CODE' ||'|'||'TERMS_ID' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'CREDIT_STATUS_LOOKUP_CODE' ||'|'||'CREDIT_LIMIT' ||'|'||'ALWAYS_TAKE_DISC_FLAG' ||'|'||'PAY_DATE_BASIS_LOOKUP_CODE' ||'|'||'PAY_GROUP_LOOKUP_CODE' ||'|'||'PAYMENT_PRIORITY' ||'|'||'INVOICE_CURRENCY_CODE' ||'|'||'PAYMENT_CURRENCY_CODE' ||'|'||'INVOICE_AMOUNT_LIMIT' ||'|'||'EXCHANGE_DATE_LOOKUP_CODE' ||'|'||
  'HOLD_ALL_PAYMENTS_FLAG' ||'|'||'HOLD_FUTURE_PAYMENTS_FLAG' ||'|'||'HOLD_REASON' ||'|'||'DISTRIBUTION_SET_ID' ||'|'||'ACCTS_PAY_CODE_COMBINATION_ID' ||'|'||'DISC_LOST_CODE_COMBINATION_ID' ||'|'||'DISC_TAKEN_CODE_COMBINATION_ID' ||'|'||'EXPENSE_CODE_COMBINATION_ID' ||'|'||'PREPAY_CODE_COMBINATION_ID' ||'|'||'NUM_1099' ||'|'||'TYPE_1099' ||'|'||'WITHHOLDING_STATUS_LOOKUP_CODE' ||'|'||'WITHHOLDING_START_DATE' ||'|'||'ORGANIZATION_TYPE_LOOKUP_CODE' ||'|'||'VAT_CODE' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'MINORITY_GROUP_LOOKUP_CODE' ||'|'||'PAYMENT_METHOD_LOOKUP_CODE' ||'|'||'BANK_ACCOUNT_NAME' ||'|'||'BANK_ACCOUNT_NUM' ||'|'||'BANK_NUM' ||'|'||'BANK_ACCOUNT_TYPE' ||'|'||'WOMEN_OWNED_FLAG' ||'|'||'SMALL_BUSINESS_FLAG' ||'|'||'STANDARD_INDUSTRY_CLASS' ||'|'||'HOLD_FLAG' ||'|'||'PURCHASING_HOLD_REASON' ||'|'||'HOLD_BY' ||'|'||'HOLD_DATE' ||'|'||'TERMS_DATE_BASIS' ||'|'||'PRICE_TOLERANCE' ||'|'||'INSPECTION_REQUIRED_FLAG' ||'|'||'RECEIPT_REQUIRED_FLAG' ||'|'||
  'QTY_RCV_TOLERANCE' ||'|'||'QTY_RCV_EXCEPTION_CODE' ||'|'||'ENFORCE_SHIP_TO_LOCATION_CODE' ||'|'||'DAYS_EARLY_RECEIPT_ALLOWED' ||'|'||'DAYS_LATE_RECEIPT_ALLOWED' ||'|'||'RECEIPT_DAYS_EXCEPTION_CODE' ||'|'||'RECEIVING_ROUTING_ID' ||'|'||'ALLOW_SUBSTITUTE_RECEIPTS_FLAG' ||'|'||'ALLOW_UNORDERED_RECEIPTS_FLAG' ||'|'||'HOLD_UNMATCHED_INVOICES_FLAG' ||'|'||'EXCLUSIVE_PAYMENT_FLAG' ||'|'||'AP_TAX_ROUNDING_RULE' ||'|'||'AUTO_TAX_CALC_FLAG' ||'|'||'AUTO_TAX_CALC_OVERRIDE' ||'|'||'AMOUNT_INCLUDES_TAX_FLAG' ||'|'||'TAX_VERIFICATION_DATE' ||'|'||'NAME_CONTROL' ||'|'||'STATE_REPORTABLE_FLAG' ||'|'||'FEDERAL_REPORTABLE_FLAG' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'REQUEST_ID' ||'|'||
  'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'OFFSET_VAT_CODE' ||'|'||'VAT_REGISTRATION_NUM' ||'|'||'AUTO_CALCULATE_INTEREST_FLAG' ||'|'||'VALIDATION_NUMBER' ||'|'||'EXCLUDE_FREIGHT_FROM_DISCOUNT' ||'|'||'TAX_REPORTING_NAME' ||'|'||'CHECK_DIGITS' ||'|'||'BANK_NUMBER' ||'|'||'ALLOW_AWT_FLAG' ||'|'||'AWT_GROUP_ID' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'EDI_TRANSACTION_HANDLING' ||'|'||
  'EDI_PAYMENT_METHOD' ||'|'||'EDI_PAYMENT_FORMAT' ||'|'||'EDI_REMITTANCE_METHOD' ||'|'||'EDI_REMITTANCE_INSTRUCTION' ||'|'||'BANK_CHARGE_BEARER' ||'|'||'BANK_BRANCH_TYPE' ||'|'||'MATCH_OPTION' ||'|'||'FUTURE_DATED_PAYMENT_CCID' ||'|'||'CREATE_DEBIT_MEMO_FLAG' ||'|'||'OFFSET_TAX_FLAG' ||'|'||'UNIQUE_TAX_REFERENCE_NUM' ||'|'||'PARTNERSHIP_UTR' ||'|'||'PARTNERSHIP_NAME' ||'|'||'CIS_ENABLED_FLAG' ||'|'||'FIRST_NAME' ||'|'||'SECOND_NAME' ||'|'||'LAST_NAME' ||'|'||'SALUTATION' ||'|'||'TRADING_NAME' ||'|'||'WORK_REFERENCE' ||'|'||'COMPANY_REGISTRATION_NUMBER' ||'|'||'NATIONAL_INSURANCE_NUMBER' ||'|'||'VERIFICATION_NUMBER' ||'|'||'VERIFICATION_REQUEST_ID' ||'|'||'MATCH_STATUS_FLAG' ||'|'||'CIS_VERIFICATION_DATE' ||'|'||'INDIVIDUAL_1099'
  ---                ||'|'||'CIS_PARENT_VENDOR_ID'
  ---                ||'|'||'BUS_CLASS_LAST_CERTIFIED_DATE'
  ---                ||'|'||'BUS_CLASS_LAST_CERTIFIED_BY'
  ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pv_Cur IN
    (SELECT VENDOR_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      VENDOR_NAME ,
      VENDOR_NAME_ALT ,
      SEGMENT1 ,
      SUMMARY_FLAG ,
      ENABLED_FLAG ,
      SEGMENT2 ,
      SEGMENT3 ,
      SEGMENT4 ,
      SEGMENT5 ,
      EMPLOYEE_ID ,
      VENDOR_TYPE_LOOKUP_CODE ,
      CUSTOMER_NUM ,
      ONE_TIME_FLAG ,
      PARENT_VENDOR_ID ,
      MIN_ORDER_AMOUNT ,
      SHIP_TO_LOCATION_ID ,
      BILL_TO_LOCATION_ID ,
      SHIP_VIA_LOOKUP_CODE ,
      FREIGHT_TERMS_LOOKUP_CODE ,
      FOB_LOOKUP_CODE ,
      TERMS_ID ,
      SET_OF_BOOKS_ID ,
      CREDIT_STATUS_LOOKUP_CODE ,
      CREDIT_LIMIT ,
      ALWAYS_TAKE_DISC_FLAG ,
      PAY_DATE_BASIS_LOOKUP_CODE ,
      PAY_GROUP_LOOKUP_CODE ,
      PAYMENT_PRIORITY ,
      INVOICE_CURRENCY_CODE ,
      PAYMENT_CURRENCY_CODE ,
      INVOICE_AMOUNT_LIMIT ,
      EXCHANGE_DATE_LOOKUP_CODE ,
      HOLD_ALL_PAYMENTS_FLAG ,
      HOLD_FUTURE_PAYMENTS_FLAG ,
      HOLD_REASON ,
      DISTRIBUTION_SET_ID ,
      ACCTS_PAY_CODE_COMBINATION_ID ,
      DISC_LOST_CODE_COMBINATION_ID ,
      DISC_TAKEN_CODE_COMBINATION_ID ,
      EXPENSE_CODE_COMBINATION_ID ,
      PREPAY_CODE_COMBINATION_ID ,
      NUM_1099 ,
      TYPE_1099 ,
      WITHHOLDING_STATUS_LOOKUP_CODE ,
      WITHHOLDING_START_DATE ,
      ORGANIZATION_TYPE_LOOKUP_CODE ,
      VAT_CODE ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      MINORITY_GROUP_LOOKUP_CODE ,
      PAYMENT_METHOD_LOOKUP_CODE ,
      BANK_ACCOUNT_NAME ,
      BANK_ACCOUNT_NUM ,
      BANK_NUM ,
      BANK_ACCOUNT_TYPE ,
      WOMEN_OWNED_FLAG ,
      SMALL_BUSINESS_FLAG ,
      STANDARD_INDUSTRY_CLASS ,
      HOLD_FLAG ,
      PURCHASING_HOLD_REASON ,
      HOLD_BY ,
      HOLD_DATE ,
      TERMS_DATE_BASIS ,
      PRICE_TOLERANCE ,
      INSPECTION_REQUIRED_FLAG ,
      RECEIPT_REQUIRED_FLAG ,
      QTY_RCV_TOLERANCE ,
      QTY_RCV_EXCEPTION_CODE ,
      ENFORCE_SHIP_TO_LOCATION_CODE ,
      DAYS_EARLY_RECEIPT_ALLOWED ,
      DAYS_LATE_RECEIPT_ALLOWED ,
      RECEIPT_DAYS_EXCEPTION_CODE ,
      RECEIVING_ROUTING_ID ,
      ALLOW_SUBSTITUTE_RECEIPTS_FLAG ,
      ALLOW_UNORDERED_RECEIPTS_FLAG ,
      HOLD_UNMATCHED_INVOICES_FLAG ,
      EXCLUSIVE_PAYMENT_FLAG ,
      AP_TAX_ROUNDING_RULE ,
      AUTO_TAX_CALC_FLAG ,
      AUTO_TAX_CALC_OVERRIDE ,
      AMOUNT_INCLUDES_TAX_FLAG ,
      TAX_VERIFICATION_DATE ,
      NAME_CONTROL ,
      STATE_REPORTABLE_FLAG ,
      FEDERAL_REPORTABLE_FLAG ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_ID ,
      PROGRAM_UPDATE_DATE ,
      OFFSET_VAT_CODE ,
      VAT_REGISTRATION_NUM ,
      AUTO_CALCULATE_INTEREST_FLAG ,
      VALIDATION_NUMBER ,
      EXCLUDE_FREIGHT_FROM_DISCOUNT ,
      TAX_REPORTING_NAME ,
      CHECK_DIGITS ,
      BANK_NUMBER ,
      ALLOW_AWT_FLAG ,
      AWT_GROUP_ID ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      EDI_TRANSACTION_HANDLING ,
      EDI_PAYMENT_METHOD ,
      EDI_PAYMENT_FORMAT ,
      EDI_REMITTANCE_METHOD ,
      EDI_REMITTANCE_INSTRUCTION ,
      BANK_CHARGE_BEARER ,
      BANK_BRANCH_TYPE ,
      MATCH_OPTION ,
      FUTURE_DATED_PAYMENT_CCID ,
      CREATE_DEBIT_MEMO_FLAG ,
      OFFSET_TAX_FLAG ,
      UNIQUE_TAX_REFERENCE_NUM ,
      PARTNERSHIP_UTR ,
      PARTNERSHIP_NAME ,
      CIS_ENABLED_FLAG ,
      FIRST_NAME ,
      SECOND_NAME ,
      LAST_NAME ,
      SALUTATION ,
      TRADING_NAME ,
      WORK_REFERENCE ,
      COMPANY_REGISTRATION_NUMBER ,
      NATIONAL_INSURANCE_NUMBER ,
      VERIFICATION_NUMBER ,
      VERIFICATION_REQUEST_ID ,
      MATCH_STATUS_FLAG ,
      CIS_VERIFICATION_DATE ,
      INDIVIDUAL_1099
      ---         ,CIS_PARENT_VENDOR_ID
      ---         ,BUS_CLASS_LAST_CERTIFIED_DATE
      ---         ,BUS_CLASS_LAST_CERTIFIED_BY
    FROM ap_suppliers -- Modified for R12 po_vendors
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      ld_num_1099                                   :=pv_Cur.NUM_1099;
      IF UPPER(pv_Cur.ORGANIZATION_TYPE_LOOKUP_CODE) = 'INDIVIDUAL' THEN
        ld_num_1099                                 :=' ';
      END IF;
      l_data:=pv_Cur.VENDOR_ID ||'|'||pv_Cur.LAST_UPDATE_DATE ||'|'||pv_Cur.LAST_UPDATED_BY ||'|'||pv_Cur.CREATION_DATE ||'|'||pv_Cur.CREATED_BY ||'|'||pv_Cur.LAST_UPDATE_LOGIN ||'|'||pv_Cur.VENDOR_NAME ||'|'||pv_Cur.VENDOR_NAME_ALT ||'|'||pv_Cur.SEGMENT1 ||'|'||pv_Cur.SUMMARY_FLAG ||'|'||pv_Cur.ENABLED_FLAG ||'|'||pv_Cur.SEGMENT2 ||'|'||pv_Cur.SEGMENT3 ||'|'||pv_Cur.SEGMENT4 ||'|'||pv_Cur.SEGMENT5 ||'|'||pv_Cur.EMPLOYEE_ID ||'|'||pv_Cur.VENDOR_TYPE_LOOKUP_CODE ||'|'||pv_Cur.CUSTOMER_NUM ||'|'||pv_Cur.ONE_TIME_FLAG ||'|'||pv_Cur.PARENT_VENDOR_ID ||'|'||pv_Cur.MIN_ORDER_AMOUNT ||'|'||pv_Cur.SHIP_TO_LOCATION_ID ||'|'||pv_Cur.BILL_TO_LOCATION_ID ||'|'||pv_Cur.SHIP_VIA_LOOKUP_CODE ||'|'||pv_Cur.FREIGHT_TERMS_LOOKUP_CODE ||'|'||pv_Cur.FOB_LOOKUP_CODE ||'|'||pv_Cur.TERMS_ID ||'|'||pv_Cur.SET_OF_BOOKS_ID ||'|'||pv_Cur.CREDIT_STATUS_LOOKUP_CODE ||'|'||pv_Cur.CREDIT_LIMIT ||'|'||pv_Cur.ALWAYS_TAKE_DISC_FLAG ||'|'||pv_Cur.PAY_DATE_BASIS_LOOKUP_CODE ||'|'||pv_Cur.PAY_GROUP_LOOKUP_CODE ||'|'||
      pv_Cur.PAYMENT_PRIORITY ||'|'||pv_Cur.INVOICE_CURRENCY_CODE ||'|'||pv_Cur.PAYMENT_CURRENCY_CODE ||'|'||pv_Cur.INVOICE_AMOUNT_LIMIT ||'|'||pv_Cur.EXCHANGE_DATE_LOOKUP_CODE ||'|'||pv_Cur.HOLD_ALL_PAYMENTS_FLAG ||'|'||pv_Cur.HOLD_FUTURE_PAYMENTS_FLAG ||'|'||pv_Cur.HOLD_REASON ||'|'||pv_Cur.DISTRIBUTION_SET_ID ||'|'||pv_Cur.ACCTS_PAY_CODE_COMBINATION_ID ||'|'||pv_Cur.DISC_LOST_CODE_COMBINATION_ID ||'|'||pv_Cur.DISC_TAKEN_CODE_COMBINATION_ID ||'|'||pv_Cur.EXPENSE_CODE_COMBINATION_ID ||'|'||pv_Cur.PREPAY_CODE_COMBINATION_ID ||'|'||ld_num_1099 ||'|'||pv_Cur.TYPE_1099 ||'|'||pv_Cur.WITHHOLDING_STATUS_LOOKUP_CODE ||'|'||pv_Cur.WITHHOLDING_START_DATE ||'|'||pv_Cur.ORGANIZATION_TYPE_LOOKUP_CODE ||'|'||pv_Cur.VAT_CODE ||'|'||pv_Cur.START_DATE_ACTIVE ||'|'||pv_Cur.END_DATE_ACTIVE ||'|'||pv_Cur.MINORITY_GROUP_LOOKUP_CODE ||'|'||pv_Cur.PAYMENT_METHOD_LOOKUP_CODE ||'|'||pv_Cur.BANK_ACCOUNT_NAME
      --           ||'|'||pv_Cur.BANK_ACCOUNT_NUM
      --           ||'|'||pv_Cur.BANK_NUM
      ||'|'||' ' ||'|'||' ' ||'|'||pv_Cur.BANK_ACCOUNT_TYPE ||'|'||pv_Cur.WOMEN_OWNED_FLAG ||'|'||pv_Cur.SMALL_BUSINESS_FLAG ||'|'||pv_Cur.STANDARD_INDUSTRY_CLASS ||'|'||pv_Cur.HOLD_FLAG ||'|'||pv_Cur.PURCHASING_HOLD_REASON ||'|'||pv_Cur.HOLD_BY ||'|'||pv_Cur.HOLD_DATE ||'|'||pv_Cur.TERMS_DATE_BASIS ||'|'||pv_Cur.PRICE_TOLERANCE ||'|'||pv_Cur.INSPECTION_REQUIRED_FLAG ||'|'||pv_Cur.RECEIPT_REQUIRED_FLAG ||'|'||pv_Cur.QTY_RCV_TOLERANCE ||'|'||pv_Cur.QTY_RCV_EXCEPTION_CODE ||'|'||pv_Cur.ENFORCE_SHIP_TO_LOCATION_CODE ||'|'||pv_Cur.DAYS_EARLY_RECEIPT_ALLOWED ||'|'||pv_Cur.DAYS_LATE_RECEIPT_ALLOWED ||'|'||pv_Cur.RECEIPT_DAYS_EXCEPTION_CODE ||'|'||pv_Cur.RECEIVING_ROUTING_ID ||'|'||pv_Cur.ALLOW_SUBSTITUTE_RECEIPTS_FLAG ||'|'||pv_Cur.ALLOW_UNORDERED_RECEIPTS_FLAG ||'|'||pv_Cur.HOLD_UNMATCHED_INVOICES_FLAG ||'|'||pv_Cur.EXCLUSIVE_PAYMENT_FLAG ||'|'||pv_Cur.AP_TAX_ROUNDING_RULE ||'|'||pv_Cur.AUTO_TAX_CALC_FLAG ||'|'||pv_Cur.AUTO_TAX_CALC_OVERRIDE ||'|'||pv_Cur.AMOUNT_INCLUDES_TAX_FLAG ||'|'||
      pv_Cur.TAX_VERIFICATION_DATE ||'|'||pv_Cur.NAME_CONTROL ||'|'||pv_Cur.STATE_REPORTABLE_FLAG ||'|'||pv_Cur.FEDERAL_REPORTABLE_FLAG ||'|'||pv_Cur.ATTRIBUTE_CATEGORY ||'|'||pv_Cur.ATTRIBUTE1 ||'|'||pv_Cur.ATTRIBUTE2 ||'|'||pv_Cur.ATTRIBUTE3 ||'|'||pv_Cur.ATTRIBUTE4 ||'|'||pv_Cur.ATTRIBUTE5 ||'|'||pv_Cur.ATTRIBUTE6 ||'|'||pv_Cur.ATTRIBUTE7 ||'|'||pv_Cur.ATTRIBUTE8 ||'|'||pv_Cur.ATTRIBUTE9 ||'|'||pv_Cur.ATTRIBUTE10 ||'|'||pv_Cur.ATTRIBUTE11 ||'|'||pv_Cur.ATTRIBUTE12 ||'|'||pv_Cur.ATTRIBUTE13 ||'|'||pv_Cur.ATTRIBUTE14 ||'|'||pv_Cur.ATTRIBUTE15 ||'|'||pv_Cur.REQUEST_ID ||'|'||pv_Cur.PROGRAM_APPLICATION_ID ||'|'||pv_Cur.PROGRAM_ID ||'|'||pv_Cur.PROGRAM_UPDATE_DATE ||'|'||pv_Cur.OFFSET_VAT_CODE ||'|'||pv_Cur.VAT_REGISTRATION_NUM ||'|'||pv_Cur.AUTO_CALCULATE_INTEREST_FLAG ||'|'||pv_Cur.VALIDATION_NUMBER ||'|'||pv_Cur.EXCLUDE_FREIGHT_FROM_DISCOUNT ||'|'||pv_Cur.TAX_REPORTING_NAME ||'|'||pv_Cur.CHECK_DIGITS ||'|'||pv_Cur.BANK_NUMBER ||'|'||pv_Cur.ALLOW_AWT_FLAG ||'|'||pv_Cur.AWT_GROUP_ID
      ||'|'||pv_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||pv_Cur.GLOBAL_ATTRIBUTE1 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE2 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE3 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE4 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE5 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE6 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE7 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE8 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE9 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE10 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE11 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE12 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE13 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE14 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE15 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE16 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE17 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE18 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE19 ||'|'||pv_Cur.GLOBAL_ATTRIBUTE20 ||'|'||pv_Cur.EDI_TRANSACTION_HANDLING ||'|'||pv_Cur.EDI_PAYMENT_METHOD ||'|'||pv_Cur.EDI_PAYMENT_FORMAT ||'|'||pv_Cur.EDI_REMITTANCE_METHOD ||'|'||pv_Cur.EDI_REMITTANCE_INSTRUCTION ||'|'||pv_Cur.BANK_CHARGE_BEARER ||'|'||pv_Cur.BANK_BRANCH_TYPE ||'|'||pv_Cur.MATCH_OPTION ||'|'||
      pv_Cur.FUTURE_DATED_PAYMENT_CCID ||'|'||pv_Cur.CREATE_DEBIT_MEMO_FLAG ||'|'||pv_Cur.OFFSET_TAX_FLAG ||'|'||pv_Cur.UNIQUE_TAX_REFERENCE_NUM ||'|'||pv_Cur.PARTNERSHIP_UTR ||'|'||pv_Cur.PARTNERSHIP_NAME ||'|'||pv_Cur.CIS_ENABLED_FLAG ||'|'||pv_Cur.FIRST_NAME ||'|'||pv_Cur.SECOND_NAME ||'|'||pv_Cur.LAST_NAME ||'|'||pv_Cur.SALUTATION ||'|'||pv_Cur.TRADING_NAME ||'|'||pv_Cur.WORK_REFERENCE ||'|'||pv_Cur.COMPANY_REGISTRATION_NUMBER ||'|'||pv_Cur.NATIONAL_INSURANCE_NUMBER ||'|'||pv_Cur.VERIFICATION_NUMBER ||'|'||pv_Cur.VERIFICATION_REQUEST_ID ||'|'||pv_Cur.MATCH_STATUS_FLAG ||'|'||pv_Cur.CIS_VERIFICATION_DATE ||'|'||pv_Cur.INDIVIDUAL_1099
      ---            ||'|'||pv_Cur.CIS_PARENT_VENDOR_ID
      ---            ||'|'||pv_Cur.BUS_CLASS_LAST_CERTIFIED_DATE
      ---            ||'|'||pv_Cur.BUS_CLASS_LAST_CERTIFIED_BY
      ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_vendors = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_vendors');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_vendors =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_vendors;
-- +=================================================================================================+
-- +===============  Extract # 19  ====================================================================+
PROCEDURE Extract_po_vendor_contacts(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_po_vendor_contacts.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_po_vendor_contacts                                               |
  -- | Description      : This procedure is used to extract po_vendor_contacts                                      |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date   DATE;
  ld_end_date     DATE;
  v_cont_alt_name VARCHAR2(240);
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='VENDOR_CONTACT_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'VENDOR_SITE_ID' ||'|'||'INACTIVE_DATE' ||'|'||'FIRST_NAME' ||'|'||'MIDDLE_NAME' ||'|'||'LAST_NAME' ||'|'||'PREFIX' ||'|'||'TITLE' ||'|'||'MAIL_STOP' ||'|'||'AREA_CODE' ||'|'||'PHONE' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'CONTACT_NAME_ALT' ||'|'||'FIRST_NAME_ALT' ||'|'||'LAST_NAME_ALT' ||'|'||'DEPARTMENT' ||'|'||'EMAIL_ADDRESS' ||'|'||'URL' ||'|'||'ALT_AREA_CODE' ||'|'||'ALT_PHONE' ||'|'||'FAX_AREA_CODE' ||'|'||'FAX' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR pvc_Cur IN
    (SELECT VENDOR_CONTACT_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      VENDOR_SITE_ID
      --,INACTIVE_DATE
      ,
      DECODE(SIGN(TRUNC(inactive_date)-TRUNC(SYSDATE)),1,NULL,0,TRUNC(SYSDATE),-1,inactive_date) INACTIVE_DATE ,
      FIRST_NAME ,
      MIDDLE_NAME ,
      LAST_NAME ,
      PREFIX ,
      TITLE ,
      MAIL_STOP ,
      AREA_CODE ,
      PHONE ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      NULL REQUEST_ID ,
      NULL PROGRAM_APPLICATION_ID ,
      NULL PROGRAM_ID ,
      PROGRAM_UPDATE_DATE
      --,CONTACT_NAME_ALT
      ,
      FIRST_NAME_ALT ,
      LAST_NAME_ALT ,
      DEPARTMENT ,
      EMAIL_ADDRESS ,
      URL ,
      ALT_AREA_CODE ,
      ALT_PHONE ,
      FAX_AREA_CODE ,
      FAX ,
      relationship_id
    FROM po_vendor_contacts
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      v_cont_alt_name:=get_contact_alt_name(pvc_cur.relationship_id); -- Defect 27400
      l_data         :=pvc_Cur.VENDOR_CONTACT_ID ||'|'||pvc_Cur.LAST_UPDATE_DATE ||'|'||pvc_Cur.LAST_UPDATED_BY ||'|'||pvc_Cur.CREATION_DATE ||'|'||pvc_Cur.CREATED_BY ||'|'||pvc_Cur.LAST_UPDATE_LOGIN ||'|'||pvc_Cur.VENDOR_SITE_ID ||'|'||pvc_Cur.INACTIVE_DATE ||'|'||pvc_Cur.FIRST_NAME ||'|'||pvc_Cur.MIDDLE_NAME ||'|'||pvc_Cur.LAST_NAME ||'|'||pvc_Cur.PREFIX ||'|'||pvc_Cur.TITLE ||'|'||pvc_Cur.MAIL_STOP ||'|'||pvc_Cur.AREA_CODE ||'|'||pvc_Cur.PHONE ||'|'||pvc_Cur.ATTRIBUTE_CATEGORY ||'|'||pvc_Cur.ATTRIBUTE1 ||'|'||pvc_Cur.ATTRIBUTE2 ||'|'||pvc_Cur.ATTRIBUTE3 ||'|'||pvc_Cur.ATTRIBUTE4 ||'|'||pvc_Cur.ATTRIBUTE5 ||'|'||pvc_Cur.ATTRIBUTE6 ||'|'||pvc_Cur.ATTRIBUTE7 ||'|'||pvc_Cur.ATTRIBUTE8 ||'|'||pvc_Cur.ATTRIBUTE9 ||'|'||pvc_Cur.ATTRIBUTE10 ||'|'||pvc_Cur.ATTRIBUTE11 ||'|'||pvc_Cur.ATTRIBUTE12 ||'|'||pvc_Cur.ATTRIBUTE13 ||'|'||pvc_Cur.ATTRIBUTE14 ||'|'||pvc_Cur.ATTRIBUTE15 ||'|'||pvc_Cur.REQUEST_ID ||'|'||pvc_Cur.PROGRAM_APPLICATION_ID ||'|'||pvc_Cur.PROGRAM_ID ||'|'||
      pvc_Cur.PROGRAM_UPDATE_DATE ||'|'||v_cont_alt_name ||'|'||pvc_Cur.FIRST_NAME_ALT ||'|'||pvc_Cur.LAST_NAME_ALT ||'|'||pvc_Cur.DEPARTMENT ||'|'||pvc_Cur.EMAIL_ADDRESS ||'|'||pvc_Cur.URL ||'|'||pvc_Cur.ALT_AREA_CODE ||'|'||pvc_Cur.ALT_PHONE ||'|'||pvc_Cur.FAX_AREA_CODE ||'|'||pvc_Cur.FAX ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for po_vendor_contacts = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for po_vendor_contacts');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in po_vendor_contacts =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_po_vendor_contacts;
-- +=================================================================================================+
-- +===============  Extract # 20  ====================================================================+
PROCEDURE Extract_gl_code_combo(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_gl_code_combo.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_gl_code_combinations                                              |
  -- | Description      : This procedure is used to extract gl_code_combinations                                     |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  --------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='CODE_COMBINATION_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CHART_OF_ACCOUNTS_ID' ||'|'||'DETAIL_POSTING_ALLOWED_FLAG' ||'|'||'DETAIL_BUDGETING_ALLOWED_FLAG' ||'|'||'ACCOUNT_TYPE' ||'|'||'ENABLED_FLAG' ||'|'||'SUMMARY_FLAG' ||'|'||'SEGMENT1' ||'|'||'SEGMENT2' ||'|'||'SEGMENT3' ||'|'||'SEGMENT4' ||'|'||'SEGMENT5' ||'|'||'SEGMENT6' ||'|'||'SEGMENT7' ||'|'||'SEGMENT8' ||'|'||'SEGMENT9' ||'|'||'SEGMENT10' ||'|'||'SEGMENT11' ||'|'||'SEGMENT12' ||'|'||'SEGMENT13' ||'|'||'SEGMENT14' ||'|'||'SEGMENT15' ||'|'||'SEGMENT16' ||'|'||'SEGMENT17' ||'|'||'SEGMENT18' ||'|'||'SEGMENT19' ||'|'||'SEGMENT20' ||'|'||'SEGMENT21' ||'|'||'SEGMENT22' ||'|'||'SEGMENT23' ||'|'||'SEGMENT24' ||'|'||'SEGMENT25' ||'|'||'SEGMENT26' ||'|'||'SEGMENT27' ||'|'||'SEGMENT28' ||'|'||'SEGMENT29' ||'|'||'SEGMENT30' ||'|'||'DESCRIPTION' ||'|'||'TEMPLATE_ID' ||'|'||'ALLOCATION_CREATE_FLAG' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||
  'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'CONTEXT' ||'|'||'SEGMENT_ATTRIBUTE1' ||'|'||'SEGMENT_ATTRIBUTE2' ||'|'||'SEGMENT_ATTRIBUTE3' ||'|'||'SEGMENT_ATTRIBUTE4' ||'|'||'SEGMENT_ATTRIBUTE5' ||'|'||'SEGMENT_ATTRIBUTE6' ||'|'||'SEGMENT_ATTRIBUTE7' ||'|'||'SEGMENT_ATTRIBUTE8' ||'|'||'SEGMENT_ATTRIBUTE9' ||'|'||'SEGMENT_ATTRIBUTE10' ||'|'||'SEGMENT_ATTRIBUTE11' ||'|'||'SEGMENT_ATTRIBUTE12' ||'|'||'SEGMENT_ATTRIBUTE13' ||'|'||'SEGMENT_ATTRIBUTE14' ||'|'||'SEGMENT_ATTRIBUTE15' ||'|'||'SEGMENT_ATTRIBUTE16' ||'|'||'SEGMENT_ATTRIBUTE17' ||'|'||'SEGMENT_ATTRIBUTE18' ||'|'||'SEGMENT_ATTRIBUTE19' ||'|'||'SEGMENT_ATTRIBUTE20' ||'|'||'SEGMENT_ATTRIBUTE21' ||'|'||'SEGMENT_ATTRIBUTE22' ||'|'||'SEGMENT_ATTRIBUTE23' ||'|'||'SEGMENT_ATTRIBUTE24' ||'|'||'SEGMENT_ATTRIBUTE25' ||'|'||'SEGMENT_ATTRIBUTE26' ||'|'||'SEGMENT_ATTRIBUTE27' ||'|'||'SEGMENT_ATTRIBUTE28' ||'|'||
  'SEGMENT_ATTRIBUTE29' ||'|'||'SEGMENT_ATTRIBUTE30' ||'|'||'SEGMENT_ATTRIBUTE31' ||'|'||'SEGMENT_ATTRIBUTE32' ||'|'||'SEGMENT_ATTRIBUTE33' ||'|'||'SEGMENT_ATTRIBUTE34' ||'|'||'SEGMENT_ATTRIBUTE35' ||'|'||'SEGMENT_ATTRIBUTE36' ||'|'||'SEGMENT_ATTRIBUTE37' ||'|'||'SEGMENT_ATTRIBUTE38' ||'|'||'SEGMENT_ATTRIBUTE39' ||'|'||'SEGMENT_ATTRIBUTE40' ||'|'||'SEGMENT_ATTRIBUTE41' ||'|'||'SEGMENT_ATTRIBUTE42' ||'|'||'REFERENCE1' ||'|'||'REFERENCE2' ||'|'||'REFERENCE3' ||'|'||'REFERENCE4' ||'|'||'REFERENCE5' ||'|'||'JGZZ_RECON_FLAG' ||'|'||'JGZZ_RECON_CONTEXT' ||'|'||'PRESERVE_FLAG' ||'|'||'REFRESH_FLAG' ||'|'||'IGI_BALANCED_BUDGET_FLAG' ||'|'||'COMPANY_COST_CENTER_ORG_ID' ||'|'||'REVALUATION_ID' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR gcc_Cur IN
    (SELECT CODE_COMBINATION_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CHART_OF_ACCOUNTS_ID ,
      DETAIL_POSTING_ALLOWED_FLAG ,
      DETAIL_BUDGETING_ALLOWED_FLAG ,
      ACCOUNT_TYPE ,
      ENABLED_FLAG ,
      SUMMARY_FLAG ,
      SEGMENT1 ,
      SEGMENT2 ,
      SEGMENT3 ,
      SEGMENT4 ,
      SEGMENT5 ,
      SEGMENT6 ,
      SEGMENT7 ,
      SEGMENT8 ,
      SEGMENT9 ,
      SEGMENT10 ,
      SEGMENT11 ,
      SEGMENT12 ,
      SEGMENT13 ,
      SEGMENT14 ,
      SEGMENT15 ,
      SEGMENT16 ,
      SEGMENT17 ,
      SEGMENT18 ,
      SEGMENT19 ,
      SEGMENT20 ,
      SEGMENT21 ,
      SEGMENT22 ,
      SEGMENT23 ,
      SEGMENT24 ,
      SEGMENT25 ,
      SEGMENT26 ,
      SEGMENT27 ,
      SEGMENT28 ,
      SEGMENT29 ,
      SEGMENT30 ,
      DESCRIPTION ,
      TEMPLATE_ID ,
      ALLOCATION_CREATE_FLAG ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      CONTEXT ,
      SEGMENT_ATTRIBUTE1 ,
      SEGMENT_ATTRIBUTE2 ,
      SEGMENT_ATTRIBUTE3 ,
      SEGMENT_ATTRIBUTE4 ,
      SEGMENT_ATTRIBUTE5 ,
      SEGMENT_ATTRIBUTE6 ,
      SEGMENT_ATTRIBUTE7 ,
      SEGMENT_ATTRIBUTE8 ,
      SEGMENT_ATTRIBUTE9 ,
      SEGMENT_ATTRIBUTE10 ,
      SEGMENT_ATTRIBUTE11 ,
      SEGMENT_ATTRIBUTE12 ,
      SEGMENT_ATTRIBUTE13 ,
      SEGMENT_ATTRIBUTE14 ,
      SEGMENT_ATTRIBUTE15 ,
      SEGMENT_ATTRIBUTE16 ,
      SEGMENT_ATTRIBUTE17 ,
      SEGMENT_ATTRIBUTE18 ,
      SEGMENT_ATTRIBUTE19 ,
      SEGMENT_ATTRIBUTE20 ,
      SEGMENT_ATTRIBUTE21 ,
      SEGMENT_ATTRIBUTE22 ,
      SEGMENT_ATTRIBUTE23 ,
      SEGMENT_ATTRIBUTE24 ,
      SEGMENT_ATTRIBUTE25 ,
      SEGMENT_ATTRIBUTE26 ,
      SEGMENT_ATTRIBUTE27 ,
      SEGMENT_ATTRIBUTE28 ,
      SEGMENT_ATTRIBUTE29 ,
      SEGMENT_ATTRIBUTE30 ,
      SEGMENT_ATTRIBUTE31 ,
      SEGMENT_ATTRIBUTE32 ,
      SEGMENT_ATTRIBUTE33 ,
      SEGMENT_ATTRIBUTE34 ,
      SEGMENT_ATTRIBUTE35 ,
      SEGMENT_ATTRIBUTE36 ,
      SEGMENT_ATTRIBUTE37 ,
      SEGMENT_ATTRIBUTE38 ,
      SEGMENT_ATTRIBUTE39 ,
      SEGMENT_ATTRIBUTE40 ,
      SEGMENT_ATTRIBUTE41 ,
      SEGMENT_ATTRIBUTE42 ,
      REFERENCE1 ,
      REFERENCE2 ,
      REFERENCE3 ,
      REFERENCE4 ,
      REFERENCE5 ,
      JGZZ_RECON_FLAG ,
      JGZZ_RECON_CONTEXT ,
      PRESERVE_FLAG ,
      REFRESH_FLAG ,
      IGI_BALANCED_BUDGET_FLAG ,
      COMPANY_COST_CENTER_ORG_ID ,
      REVALUATION_ID
    FROM gl_code_combinations
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=gcc_Cur.CODE_COMBINATION_ID ||'|'||gcc_Cur.LAST_UPDATE_DATE ||'|'||gcc_Cur.LAST_UPDATED_BY ||'|'||gcc_Cur.CHART_OF_ACCOUNTS_ID ||'|'||gcc_Cur.DETAIL_POSTING_ALLOWED_FLAG ||'|'||gcc_Cur.DETAIL_BUDGETING_ALLOWED_FLAG ||'|'||gcc_Cur.ACCOUNT_TYPE ||'|'||gcc_Cur.ENABLED_FLAG ||'|'||gcc_Cur.SUMMARY_FLAG ||'|'||gcc_Cur.SEGMENT1 ||'|'||gcc_Cur.SEGMENT2 ||'|'||gcc_Cur.SEGMENT3 ||'|'||gcc_Cur.SEGMENT4 ||'|'||gcc_Cur.SEGMENT6 ||'|'||gcc_Cur.SEGMENT7 ||'|'||gcc_Cur.SEGMENT8 ||'|'||gcc_Cur.SEGMENT9 ||'|'||gcc_Cur.SEGMENT10 ||'|'||gcc_Cur.SEGMENT11 ||'|'||gcc_Cur.SEGMENT12 ||'|'||gcc_Cur.SEGMENT13 ||'|'||gcc_Cur.SEGMENT14 ||'|'||gcc_Cur.SEGMENT15 ||'|'||gcc_Cur.SEGMENT16 ||'|'||gcc_Cur.SEGMENT17 ||'|'||gcc_Cur.SEGMENT18 ||'|'||gcc_Cur.SEGMENT19 ||'|'||gcc_Cur.SEGMENT20 ||'|'||gcc_Cur.SEGMENT21 ||'|'||gcc_Cur.SEGMENT22 ||'|'||gcc_Cur.SEGMENT23 ||'|'||gcc_Cur.SEGMENT24 ||'|'||gcc_Cur.SEGMENT25 ||'|'||gcc_Cur.SEGMENT26 ||'|'||gcc_Cur.SEGMENT27 ||'|'||gcc_Cur.SEGMENT28 ||'|'||
      gcc_Cur.SEGMENT29 ||'|'||gcc_Cur.SEGMENT30 ||'|'||gcc_Cur.DESCRIPTION ||'|'||gcc_Cur.TEMPLATE_ID ||'|'||gcc_Cur.ALLOCATION_CREATE_FLAG ||'|'||gcc_Cur.START_DATE_ACTIVE ||'|'||gcc_Cur.END_DATE_ACTIVE ||'|'||gcc_Cur.ATTRIBUTE1 ||'|'||gcc_Cur.ATTRIBUTE2 ||'|'||gcc_Cur.ATTRIBUTE3 ||'|'||gcc_Cur.ATTRIBUTE4 ||'|'||gcc_Cur.ATTRIBUTE5 ||'|'||gcc_Cur.ATTRIBUTE6 ||'|'||gcc_Cur.ATTRIBUTE7 ||'|'||gcc_Cur.ATTRIBUTE8 ||'|'||gcc_Cur.ATTRIBUTE9 ||'|'||gcc_Cur.ATTRIBUTE10 ||'|'||gcc_Cur.CONTEXT ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE1 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE2 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE3 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE4 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE5 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE6 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE7 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE8 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE9 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE10 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE11 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE12 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE13 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE14 ||'|'||
      gcc_Cur.SEGMENT_ATTRIBUTE15 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE16 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE17 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE18 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE19 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE20 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE21 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE22 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE23 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE24 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE25 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE26 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE27 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE28 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE29 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE30 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE31 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE32 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE33 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE34 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE36 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE37 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE38 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE39 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE40 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE41 ||'|'||gcc_Cur.SEGMENT_ATTRIBUTE42 ||'|'||gcc_Cur.REFERENCE1 ||'|'||gcc_Cur.REFERENCE2 ||
      '|'||gcc_Cur.REFERENCE3 ||'|'||gcc_Cur.REFERENCE4 ||'|'||gcc_Cur.REFERENCE5 ||'|'||gcc_Cur.JGZZ_RECON_FLAG ||'|'||gcc_Cur.JGZZ_RECON_CONTEXT ||'|'||gcc_Cur.PRESERVE_FLAG ||'|'||gcc_Cur.REFRESH_FLAG ||'|'||gcc_Cur.IGI_BALANCED_BUDGET_FLAG ||'|'||gcc_Cur.COMPANY_COST_CENTER_ORG_ID ||'|'||gcc_Cur.REVALUATION_ID ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for gl_code_combinations = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for gl_code_combinations');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in gl_code_combinations =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_gl_code_combo;
-- +=================================================================================================+
-- +===============  Extract # 21  ====================================================================+
PROCEDURE Extract_hr_locations_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_hr_loc_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_hr_locations_all                                             |
  -- | Description      : This procedure is used to extract hr_locations_all                                     |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='LOCATION_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATED_BY' ||'|'||'CREATION_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'LOCATION_CODE' ||'|'||'BUSINESS_GROUP_ID' ||'|'||'DESCRIPTION' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'SHIP_TO_SITE_FLAG' ||'|'||'RECEIVING_SITE_FLAG' ||'|'||'BILL_TO_SITE_FLAG' ||'|'||'IN_ORGANIZATION_FLAG' ||'|'||'OFFICE_SITE_FLAG' ||'|'||'DESIGNATED_RECEIVER_ID' ||'|'||'INVENTORY_ORGANIZATION_ID' ||'|'||'TAX_NAME' ||'|'||'INACTIVE_DATE' ||'|'||'STYLE' ||'|'||'ADDRESS_LINE_1' ||'|'||'ADDRESS_LINE_2' ||'|'||'ADDRESS_LINE_3' ||'|'||'TOWN_OR_CITY' ||'|'||'COUNTRY' ||'|'||'POSTAL_CODE' ||'|'||'REGION_1' ||'|'||'REGION_2' ||'|'||'REGION_3' ||'|'||'TELEPHONE_NUMBER_1' ||'|'||'TELEPHONE_NUMBER_2' ||'|'||'TELEPHONE_NUMBER_3' ||'|'||'LOC_INFORMATION13' ||'|'||'LOC_INFORMATION14' ||'|'||'LOC_INFORMATION15' ||'|'||'LOC_INFORMATION16' ||'|'||'LOC_INFORMATION17' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||
  'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'ATTRIBUTE16' ||'|'||'ATTRIBUTE17' ||'|'||'ATTRIBUTE18' ||'|'||'ATTRIBUTE19' ||'|'||'ATTRIBUTE20' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'ENTERED_BY' ||'|'||'TP_HEADER_ID' ||
  '|'||'ECE_TP_LOCATION_CODE' ||'|'||'OBJECT_VERSION_NUMBER' ||'|'||'LOC_INFORMATION18' ||'|'||'LOC_INFORMATION19' ||'|'||'LOC_INFORMATION20' ||'|'||'DERIVED_LOCALE' ||'|'||'LEGAL_ADDRESS_FLAG' ||'|'||'TIMEZONE_CODE' ||'|'||'GEOMETRY' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR hl_Cur IN
    (SELECT LOCATION_ID ,
      LOCATION_CODE ,
      BUSINESS_GROUP_ID ,
      DESCRIPTION ,
      SHIP_TO_LOCATION_ID ,
      SHIP_TO_SITE_FLAG ,
      RECEIVING_SITE_FLAG ,
      BILL_TO_SITE_FLAG ,
      IN_ORGANIZATION_FLAG ,
      OFFICE_SITE_FLAG ,
      DESIGNATED_RECEIVER_ID ,
      INVENTORY_ORGANIZATION_ID ,
      TAX_NAME ,
      INACTIVE_DATE ,
      STYLE ,
      ADDRESS_LINE_1 ,
      ADDRESS_LINE_2 ,
      ADDRESS_LINE_3 ,
      TOWN_OR_CITY ,
      COUNTRY ,
      POSTAL_CODE ,
      REGION_1 ,
      REGION_2 ,
      REGION_3 ,
      TELEPHONE_NUMBER_1 ,
      TELEPHONE_NUMBER_2 ,
      TELEPHONE_NUMBER_3 ,
      LOC_INFORMATION13 ,
      LOC_INFORMATION14 ,
      LOC_INFORMATION15 ,
      LOC_INFORMATION16 ,
      LOC_INFORMATION17 ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      ATTRIBUTE16 ,
      ATTRIBUTE17 ,
      ATTRIBUTE18 ,
      ATTRIBUTE19 ,
      ATTRIBUTE20 ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE20 ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      LAST_UPDATE_LOGIN ,
      CREATED_BY ,
      CREATION_DATE ,
      ENTERED_BY ,
      TP_HEADER_ID ,
      ECE_TP_LOCATION_CODE ,
      OBJECT_VERSION_NUMBER ,
      GEOMETRY ,
      LOC_INFORMATION18 ,
      LOC_INFORMATION19 ,
      LOC_INFORMATION20 ,
      DERIVED_LOCALE ,
      LEGAL_ADDRESS_FLAG ,
      TIMEZONE_CODE
    FROM hr_locations_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=hl_Cur.LOCATION_ID ||'|'||hl_Cur.LAST_UPDATE_DATE ||'|'||hl_Cur.LAST_UPDATED_BY ||'|'||hl_Cur.CREATED_BY ||'|'||hl_Cur.CREATION_DATE ||'|'||hl_Cur.LAST_UPDATE_LOGIN ||'|'||hl_Cur.LOCATION_CODE ||'|'||hl_Cur.BUSINESS_GROUP_ID ||'|'||hl_Cur.DESCRIPTION ||'|'||hl_Cur.SHIP_TO_LOCATION_ID ||'|'||hl_Cur.SHIP_TO_SITE_FLAG ||'|'||hl_Cur.RECEIVING_SITE_FLAG ||'|'||hl_Cur.BILL_TO_SITE_FLAG ||'|'||hl_Cur.IN_ORGANIZATION_FLAG ||'|'||hl_Cur.OFFICE_SITE_FLAG ||'|'||hl_Cur.DESIGNATED_RECEIVER_ID ||'|'||hl_Cur.INVENTORY_ORGANIZATION_ID ||'|'||hl_Cur.TAX_NAME ||'|'||hl_Cur.INACTIVE_DATE ||'|'||hl_Cur.STYLE ||'|'||hl_Cur.ADDRESS_LINE_1 ||'|'||hl_Cur.ADDRESS_LINE_2 ||'|'||hl_Cur.ADDRESS_LINE_3 ||'|'||hl_Cur.TOWN_OR_CITY ||'|'||hl_Cur.COUNTRY ||'|'||hl_Cur.POSTAL_CODE ||'|'||hl_Cur.REGION_1 ||'|'||hl_Cur.REGION_2 ||'|'||hl_Cur.REGION_3 ||'|'||hl_Cur.TELEPHONE_NUMBER_1 ||'|'||hl_Cur.TELEPHONE_NUMBER_2 ||'|'||hl_Cur.TELEPHONE_NUMBER_3 ||'|'||hl_Cur.LOC_INFORMATION13 ||'|'||
      hl_Cur.LOC_INFORMATION14 ||'|'||hl_Cur.LOC_INFORMATION15 ||'|'||hl_Cur.LOC_INFORMATION16 ||'|'||hl_Cur.LOC_INFORMATION17 ||'|'||hl_Cur.ATTRIBUTE_CATEGORY ||'|'||hl_Cur.ATTRIBUTE1 ||'|'||hl_Cur.ATTRIBUTE2 ||'|'||hl_Cur.ATTRIBUTE3 ||'|'||hl_Cur.ATTRIBUTE4 ||'|'||hl_Cur.ATTRIBUTE5 ||'|'||hl_Cur.ATTRIBUTE6 ||'|'||hl_Cur.ATTRIBUTE7 ||'|'||hl_Cur.ATTRIBUTE8 ||'|'||hl_Cur.ATTRIBUTE9 ||'|'||hl_Cur.ATTRIBUTE10 ||'|'||hl_Cur.ATTRIBUTE11 ||'|'||hl_Cur.ATTRIBUTE12 ||'|'||hl_Cur.ATTRIBUTE13 ||'|'||hl_Cur.ATTRIBUTE14 ||'|'||hl_Cur.ATTRIBUTE15 ||'|'||hl_Cur.ATTRIBUTE16 ||'|'||hl_Cur.ATTRIBUTE17 ||'|'||hl_Cur.ATTRIBUTE18 ||'|'||hl_Cur.ATTRIBUTE19 ||'|'||hl_Cur.ATTRIBUTE20 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||hl_Cur.GLOBAL_ATTRIBUTE1 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE2 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE3 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE4 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE5 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE6 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE7 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE8 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE9
      ||'|'||hl_Cur.GLOBAL_ATTRIBUTE10 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE11 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE12 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE13 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE14 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE15 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE16 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE17 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE18 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE19 ||'|'||hl_Cur.GLOBAL_ATTRIBUTE20 ||'|'||hl_Cur.ENTERED_BY ||'|'||hl_Cur.TP_HEADER_ID ||'|'||hl_Cur.ECE_TP_LOCATION_CODE ||'|'||hl_Cur.OBJECT_VERSION_NUMBER ||'|'||hl_Cur.LOC_INFORMATION18 ||'|'||hl_Cur.LOC_INFORMATION19 ||'|'||hl_Cur.LOC_INFORMATION20 ||'|'||hl_Cur.DERIVED_LOCALE ||'|'||hl_Cur.LEGAL_ADDRESS_FLAG ||'|'||hl_Cur.TIMEZONE_CODE ||'|'||''
      --       ||'|'||hl_Cur.GEOMETRY  always nulls
      ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for hr_locations_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for hr_locations_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in hr_locations_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_hr_locations_all;
-- +=================================================================================================+
-- +===============  Extract # 22  ====================================================================+
PROCEDURE Extract_fnd_lookup_values(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_fnd_lookup_values.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_fnd_lookup_values                                            |
  -- | Description      : This procedure is used to extract fnd_lookup_values                                     |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='LOOKUP_TYPE' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATED_BY' ||'|'||'CREATION_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'LOOKUP_CODE ' ||'|'||'LANGUAGE     ' ||'|'||'MEANING     ' ||'|'||'DESCRIPTION  ' ||'|'||'ENABLED_FLAG  ' ||'|'||'START_DATE_ACTIVE ' ||'|'||'END_DATE_ACTIVE ' ||'|'||'SOURCE_LANG  ' ||'|'||'SECURITY_GROUP_ID' ||'|'||'VIEW_APPLICATION_ID  ' ||'|'||'TERRITORY_CODE ' ||'|'||'ATTRIBUTE_CATEGORY ' ||'|'||'ATTRIBUTE1  ' ||'|'||'ATTRIBUTE2  ' ||'|'||'ATTRIBUTE3  ' ||'|'||'ATTRIBUTE4  ' ||'|'||'ATTRIBUTE5  ' ||'|'||'ATTRIBUTE6  ' ||'|'||'ATTRIBUTE7 ' ||'|'||'ATTRIBUTE8 ' ||'|'||'ATTRIBUTE9 ' ||'|'||'ATTRIBUTE10 ' ||'|'||'ATTRIBUTE11 ' ||'|'||'ATTRIBUTE12 ' ||'|'||'ATTRIBUTE13 ' ||'|'||'ATTRIBUTE14 ' ||'|'||'ATTRIBUTE15 ' ||'|'||'TAG     ' ||'|'||'LEAF_NODE ' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR flv_Cur IN
    (SELECT LOOKUP_TYPE ,
      LANGUAGE ,
      LOOKUP_CODE ,
      MEANING ,
      DESCRIPTION ,
      ENABLED_FLAG ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      CREATED_BY ,
      CREATION_DATE ,
      LAST_UPDATED_BY ,
      LAST_UPDATE_LOGIN ,
      LAST_UPDATE_DATE ,
      SOURCE_LANG ,
      SECURITY_GROUP_ID ,
      VIEW_APPLICATION_ID ,
      TERRITORY_CODE ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      TAG ,
      LEAF_NODE
    FROM fnd_lookup_values
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:=flv_Cur.LOOKUP_TYPE ||'|'||flv_Cur.LAST_UPDATE_DATE ||'|'||flv_Cur.LAST_UPDATED_BY ||'|'||flv_Cur.CREATED_BY ||'|'||flv_Cur.CREATION_DATE ||'|'||flv_Cur.LAST_UPDATE_LOGIN ||'|'||flv_Cur.LOOKUP_CODE ||'|'||flv_Cur.LANGUAGE ||'|'||flv_Cur.MEANING ||'|'||flv_Cur.DESCRIPTION ||'|'||flv_Cur.ENABLED_FLAG ||'|'||flv_Cur.START_DATE_ACTIVE ||'|'||flv_Cur.END_DATE_ACTIVE ||'|'||flv_Cur.SOURCE_LANG ||'|'||flv_Cur.SECURITY_GROUP_ID ||'|'||flv_Cur.VIEW_APPLICATION_ID ||'|'||flv_Cur.TERRITORY_CODE ||'|'||flv_Cur.ATTRIBUTE_CATEGORY ||'|'||flv_Cur.ATTRIBUTE1 ||'|'||flv_Cur.ATTRIBUTE2 ||'|'||flv_Cur.ATTRIBUTE3 ||'|'||flv_Cur.ATTRIBUTE4 ||'|'||flv_Cur.ATTRIBUTE5 ||'|'||flv_Cur.ATTRIBUTE6 ||'|'||flv_Cur.ATTRIBUTE7 ||'|'||flv_Cur.ATTRIBUTE8 ||'|'||flv_Cur.ATTRIBUTE9 ||'|'||flv_Cur.ATTRIBUTE10 ||'|'||flv_Cur.ATTRIBUTE11 ||'|'||flv_Cur.ATTRIBUTE12 ||'|'||flv_Cur.ATTRIBUTE13 ||'|'||flv_Cur.ATTRIBUTE14 ||'|'||flv_Cur.ATTRIBUTE15 ||'|'||flv_Cur.TAG ||'|'||flv_Cur.LEAF_NODE ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for fnd_lookup_values = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for fnd_lookup_values');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in fnd_lookup_values =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_fnd_lookup_values;
-- +=================================================================================================+
-- +===============  Extract # 23  ====================================================================+
PROCEDURE Extract_fnd_id_flexs(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_fnd_id_flexs.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_fnd_id_flexs                                                      |
  -- | Description      : This procedure is used to extract fnd_id_flexs                                 |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='APPLICATION_ID' ||'|'||'ID_FLEX_CODE' ||'|'||'ID_FLEX_NAME' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'TABLE_APPLICATION_ID' ||'|'||'APPLICATION_TABLE_NAME' ||'|'||'ALLOW_ID_VALUESETS' ||'|'||'DYNAMIC_INSERTS_FEASIBLE_FLAG' ||'|'||'INDEX_FLAG' ||'|'||'UNIQUE_ID_COLUMN_NAME' ||'|'||'DESCRIPTION' ||'|'||'APPLICATION_TABLE_TYPE' ||'|'||'SET_DEFINING_COLUMN_NAME' ||'|'||'MAXIMUM_CONCATENATION_LEN' ||'|'||'CONCATENATION_LEN_WARNING' ||'|'||'CONCATENATED_SEGS_VIEW_NAME' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR fif_Cur IN
    (SELECT APPLICATION_ID ,
      ID_FLEX_CODE ,
      ID_FLEX_NAME ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      TABLE_APPLICATION_ID ,
      APPLICATION_TABLE_NAME ,
      ALLOW_ID_VALUESETS ,
      DYNAMIC_INSERTS_FEASIBLE_FLAG ,
      INDEX_FLAG ,
      UNIQUE_ID_COLUMN_NAME ,
      DESCRIPTION ,
      APPLICATION_TABLE_TYPE ,
      SET_DEFINING_COLUMN_NAME ,
      MAXIMUM_CONCATENATION_LEN ,
      CONCATENATION_LEN_WARNING ,
      CONCATENATED_SEGS_VIEW_NAME
    FROM fnd_id_flexs
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= fif_Cur.APPLICATION_ID ||'|'||fif_Cur.ID_FLEX_CODE ||'|'||fif_Cur.ID_FLEX_NAME ||'|'||fif_Cur.LAST_UPDATE_DATE ||'|'||fif_Cur.LAST_UPDATED_BY ||'|'||fif_Cur.CREATION_DATE ||'|'||fif_Cur.CREATED_BY ||'|'||fif_Cur.LAST_UPDATE_LOGIN ||'|'||fif_Cur.TABLE_APPLICATION_ID ||'|'||fif_Cur.APPLICATION_TABLE_NAME ||'|'||fif_Cur.ALLOW_ID_VALUESETS ||'|'||fif_Cur.DYNAMIC_INSERTS_FEASIBLE_FLAG ||'|'||fif_Cur.INDEX_FLAG ||'|'||fif_Cur.UNIQUE_ID_COLUMN_NAME ||'|'||fif_Cur.DESCRIPTION ||'|'||fif_Cur.APPLICATION_TABLE_TYPE ||'|'||fif_Cur.SET_DEFINING_COLUMN_NAME ||'|'||fif_Cur.MAXIMUM_CONCATENATION_LEN ||'|'||fif_Cur.CONCATENATION_LEN_WARNING ||'|'||fif_Cur.CONCATENATED_SEGS_VIEW_NAME ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for fnd_id_flexs = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for fnd_id_flexs');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in fnd_id_flexs =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_fnd_id_flexs;
-- +=================================================================================================+
-- +===============  Extract # 24  ====================================================================+
PROCEDURE Extract_fnd_id_flex_segments(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_fnd_id_flex_segments.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_fnd_id_flex_segments                    |
  -- | Description      : This procedure is used to extract fnd_id_flex_segments                         |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                        |
  -- |=======   ==========   =============    ======================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
  CURSOR c_fifm_Cur(ld_start_date DATE, ld_end_date DATE)
  IS
    SELECT APPLICATION_ID ,
      ID_FLEX_CODE ,
      ID_FLEX_NUM ,
      APPLICATION_COLUMN_NAME ,
      SEGMENT_NAME ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      SEGMENT_NUM ,
      APPLICATION_COLUMN_INDEX_FLAG ,
      ENABLED_FLAG ,
      REQUIRED_FLAG ,
      DISPLAY_FLAG ,
      DISPLAY_SIZE ,
      SECURITY_ENABLED_FLAG ,
      MAXIMUM_DESCRIPTION_LEN ,
      CONCATENATION_DESCRIPTION_LEN ,
      FLEX_VALUE_SET_ID ,
      RANGE_CODE ,
      DEFAULT_TYPE ,
      DEFAULT_VALUE ,
      RUNTIME_PROPERTY_FUNCTION ,
      ADDITIONAL_WHERE_CLAUSE
    FROM fnd_id_flex_segments
    WHERE ( TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date );
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= TO_CHAR(ln_req_id)||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='APPLICATION_ID' ||'|'||'ID_FLEX_CODE' ||'|'||'ID_FLEX_NUM' ||'|'||'APPLICATION_COLUMN_NAME' ||'|'||'SEGMENT_NAME' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY ' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'SEGMENT_NUM' ||'|'||'APPLICATION_COLUMN_INDEX_FLAG' ||'|'||'ENABLED_FLAG' ||'|'||'REQUIRED_FLAG ' ||'|'||'DISPLAY_FLAG' ||'|'||'DISPLAY_SIZE ' ||'|'||'SECURITY_ENABLED_FLAG' ||'|'||'MAXIMUM_DESCRIPTION_LEN' ||'|'||'CONCATENATION_DESCRIPTION_LEN ' ||'|'||'FLEX_VALUE_SET_ID' ||'|'||'RANGE_CODE  ' ||'|'||'DEFAULT_TYPE' ||'|'||'DEFAULT_VALUE' ||'|'||'RUNTIME_PROPERTY_FUNCTION' ||'|'||'ADDITIONAL_WHERE_CLAUSE' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    --fifm_Cur
    FOR fifm_Cur IN c_fifm_Cur(ld_start_date,ld_end_date)
    LOOP
      l_data:= fifm_Cur.APPLICATION_ID ||'|'||fifm_Cur.ID_FLEX_CODE ||'|'||fifm_Cur.ID_FLEX_NUM ||'|'||fifm_Cur.APPLICATION_COLUMN_NAME ||'|'||fifm_Cur.SEGMENT_NAME ||'|'||fifm_Cur.LAST_UPDATE_DATE ||'|'||fifm_Cur.LAST_UPDATED_BY ||'|'||fifm_Cur.CREATION_DATE ||'|'||fifm_Cur.CREATED_BY ||'|'||fifm_Cur.LAST_UPDATE_LOGIN ||'|'||fifm_Cur.SEGMENT_NUM ||'|'||fifm_Cur.APPLICATION_COLUMN_INDEX_FLAG ||'|'||fifm_Cur.ENABLED_FLAG ||'|'||fifm_Cur.REQUIRED_FLAG ||'|'||fifm_Cur.DISPLAY_FLAG ||'|'||fifm_Cur.DISPLAY_SIZE ||'|'||fifm_Cur.SECURITY_ENABLED_FLAG ||'|'||fifm_Cur.MAXIMUM_DESCRIPTION_LEN ||'|'||fifm_Cur.CONCATENATION_DESCRIPTION_LEN ||'|'||fifm_Cur.FLEX_VALUE_SET_ID ||'|'||fifm_Cur.RANGE_CODE ||'|'||fifm_Cur.DEFAULT_TYPE ||'|'||fifm_Cur.DEFAULT_VALUE ||'|'||fifm_Cur.RUNTIME_PROPERTY_FUNCTION ||'|'||fifm_Cur.ADDITIONAL_WHERE_CLAUSE ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for fnd_id_flex_segments = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for fnd_id_flex_segments');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in fnd_id_flex_segments =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF; -- IF ld_start_date IS NOT NULL and ld_end_date IS NOT NULL THEN
END Extract_fnd_id_flex_segments;
-- +=================================================================================================+
-- +===============  Extract # 25  ====================================================================+
PROCEDURE Extract_fnd_id_flex_structures(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_fnd_id_flex_structures.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_fnd_id_flex_structures                                                      |
  -- | Description      : This procedure is used to extract fnd_id_flex_structures                                 |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='APPLICATION_ID' ||'|'||'ID_FLEX_CODE' ||'|'||'ID_FLEX_NUM' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN ' ||'|'||'CONCATENATED_SEGMENT_DELIMITER' ||'|'||'CROSS_SEGMENT_VALIDATION_FLAG' ||'|'||'DYNAMIC_INSERTS_ALLOWED_FLAG' ||'|'||'ENABLED_FLAG' ||'|'||'FREEZE_FLEX_DEFINITION_FLAG' ||'|'||'FREEZE_STRUCTURED_HIER_FLAG' ||'|'||'SHORTHAND_ENABLED_FLAG ' ||'|'||'SHORTHAND_LENGTH' ||'|'||'STRUCTURE_VIEW_NAME' ||'|'||'ID_FLEX_STRUCTURE_CODE' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR fift_Cur IN
    (SELECT APPLICATION_ID ,
      ID_FLEX_CODE ,
      ID_FLEX_NUM ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      CONCATENATED_SEGMENT_DELIMITER ,
      CROSS_SEGMENT_VALIDATION_FLAG ,
      DYNAMIC_INSERTS_ALLOWED_FLAG ,
      ENABLED_FLAG ,
      FREEZE_FLEX_DEFINITION_FLAG ,
      FREEZE_STRUCTURED_HIER_FLAG ,
      SHORTHAND_ENABLED_FLAG ,
      SHORTHAND_LENGTH ,
      STRUCTURE_VIEW_NAME ,
      ID_FLEX_STRUCTURE_CODE
    FROM fnd_id_flex_structures
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= fift_Cur.APPLICATION_ID ||'|'||fift_Cur.ID_FLEX_CODE ||'|'||fift_Cur.ID_FLEX_NUM ||'|'||fift_Cur.LAST_UPDATE_DATE ||'|'||fift_Cur.LAST_UPDATED_BY ||'|'||fift_Cur.CREATION_DATE ||'|'||fift_Cur.CREATED_BY ||'|'||fift_Cur.LAST_UPDATE_LOGIN ||'|'||fift_Cur.CONCATENATED_SEGMENT_DELIMITER ||'|'||fift_Cur.CROSS_SEGMENT_VALIDATION_FLAG ||'|'||fift_Cur.DYNAMIC_INSERTS_ALLOWED_FLAG ||'|'||fift_Cur.ENABLED_FLAG ||'|'||fift_Cur.FREEZE_FLEX_DEFINITION_FLAG ||'|'||fift_Cur.FREEZE_STRUCTURED_HIER_FLAG ||'|'||fift_Cur.SHORTHAND_ENABLED_FLAG ||'|'||fift_Cur.SHORTHAND_LENGTH ||'|'||fift_Cur.STRUCTURE_VIEW_NAME ||'|'||fift_Cur.ID_FLEX_STRUCTURE_CODE ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for fnd_id_flex_structures = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for fnd_id_flex_structures');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in fnd_id_flex_structures =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_fnd_id_flex_structures;
-- +=================================================================================================+
-- +===============  Extract # 26  ====================================================================+
-- +===================================================================================================+
--
-- |                  Office Depot - Project Simplify                                                  |
-- |                  IT OfficeDepot                                                                   |
-- +===================================================================================================+
-- | Name             :  Extract_fnd_flex_values                    |
-- | Description      : This procedure is used to extract fnd_flex_values                              |
-- |                                                                                                   |
-- |Change Record:                                                                                     |
-- |===============                                                                                    |
-- |Version   Date         Author            Remarks                                        |
-- |=======   ==========   =============    ======================================================|
PROCEDURE Extract_fnd_flex_values(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_fnd_flex_values.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='FLEX_VALUE_SET_ID' ||'|'||'FLEX_VALUE_ID' ||'|'||'FLEX_VALUE ' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY ' ||'|'||'CREATION_DATE ' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'ENABLED_FLAG ' ||'|'||'SUMMARY_FLAG ' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'PARENT_FLEX_VALUE_LOW' ||'|'||'PARENT_FLEX_VALUE_HIGH' ||'|'||'STRUCTURED_HIERARCHY_LEVEL' ||'|'||'HIERARCHY_LEVEL ' ||'|'||'COMPILED_VALUE_ATTRIBUTES' ||'|'||'VALUE_CATEGORY ' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2 ' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9 ' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15 ' ||'|'||'ATTRIBUTE16 ' ||'|'||'ATTRIBUTE17' ||'|'||'ATTRIBUTE18 ' ||'|'||'ATTRIBUTE19' ||'|'||'ATTRIBUTE20' ||'|'||'ATTRIBUTE21' ||'|'||'ATTRIBUTE22' ||
  '|'||'ATTRIBUTE23' ||'|'||'ATTRIBUTE24 ' ||'|'||'ATTRIBUTE25' ||'|'||'ATTRIBUTE26' ||'|'||'ATTRIBUTE27' ||'|'||'ATTRIBUTE28' ||'|'||'ATTRIBUTE29' ||'|'||'ATTRIBUTE30 ' ||'|'||'ATTRIBUTE31  ' ||'|'||'ATTRIBUTE32 ' ||'|'||'ATTRIBUTE33' ||'|'||'ATTRIBUTE34 ' ||'|'||'ATTRIBUTE35' ||'|'||'ATTRIBUTE36' ||'|'||'ATTRIBUTE37' ||'|'||'ATTRIBUTE38 ' ||'|'||'ATTRIBUTE39' ||'|'||'ATTRIBUTE40 ' ||'|'||'ATTRIBUTE41' ||'|'||'ATTRIBUTE42' ||'|'||'ATTRIBUTE43' ||'|'||'ATTRIBUTE44 ' ||'|'||'ATTRIBUTE45' ||'|'||'ATTRIBUTE46' ||'|'||'ATTRIBUTE47 ' ||'|'||'ATTRIBUTE48' ||'|'||'ATTRIBUTE49' ||'|'||'ATTRIBUTE50' ||'|'||'ATTRIBUTE_SORT_ORDER' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    -- FFV_CUR
    FOR ffv_Cur IN
    (SELECT FLEX_VALUE_SET_ID ,
      FLEX_VALUE_ID ,
      FLEX_VALUE ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      ENABLED_FLAG ,
      SUMMARY_FLAG ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      PARENT_FLEX_VALUE_LOW ,
      PARENT_FLEX_VALUE_HIGH ,
      STRUCTURED_HIERARCHY_LEVEL ,
      HIERARCHY_LEVEL ,
      COMPILED_VALUE_ATTRIBUTES ,
      VALUE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      ATTRIBUTE16 ,
      ATTRIBUTE17 ,
      ATTRIBUTE18 ,
      ATTRIBUTE19 ,
      ATTRIBUTE20 ,
      ATTRIBUTE21 ,
      ATTRIBUTE22 ,
      ATTRIBUTE23 ,
      ATTRIBUTE24 ,
      ATTRIBUTE25 ,
      ATTRIBUTE26 ,
      ATTRIBUTE27 ,
      ATTRIBUTE28 ,
      ATTRIBUTE29 ,
      ATTRIBUTE30 ,
      ATTRIBUTE31 ,
      ATTRIBUTE32 ,
      ATTRIBUTE33 ,
      ATTRIBUTE34 ,
      ATTRIBUTE35 ,
      ATTRIBUTE36 ,
      ATTRIBUTE37 ,
      ATTRIBUTE38 ,
      ATTRIBUTE39 ,
      ATTRIBUTE40 ,
      ATTRIBUTE41 ,
      ATTRIBUTE42 ,
      ATTRIBUTE43 ,
      ATTRIBUTE44 ,
      ATTRIBUTE45 ,
      ATTRIBUTE46 ,
      ATTRIBUTE47 ,
      ATTRIBUTE48 ,
      ATTRIBUTE49 ,
      ATTRIBUTE50 ,
      ATTRIBUTE_SORT_ORDER
    FROM fnd_flex_values
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= ffv_Cur.FLEX_VALUE_SET_ID ||'|'||ffv_Cur.FLEX_VALUE_ID ||'|'||ffv_Cur.FLEX_VALUE ||'|'||ffv_Cur.LAST_UPDATE_DATE ||'|'||ffv_Cur.LAST_UPDATED_BY ||'|'||ffv_Cur.CREATION_DATE ||'|'||ffv_Cur.CREATED_BY ||'|'||ffv_Cur.LAST_UPDATE_LOGIN ||'|'||ffv_Cur.ENABLED_FLAG ||'|'||ffv_Cur.SUMMARY_FLAG ||'|'||ffv_Cur.START_DATE_ACTIVE ||'|'||ffv_Cur.END_DATE_ACTIVE ||'|'||ffv_Cur.START_DATE_ACTIVE ||'|'||ffv_Cur.END_DATE_ACTIVE ||'|'||ffv_Cur.PARENT_FLEX_VALUE_LOW ||'|'||ffv_Cur.PARENT_FLEX_VALUE_HIGH ||'|'||ffv_Cur.STRUCTURED_HIERARCHY_LEVEL ||'|'||ffv_Cur.HIERARCHY_LEVEL ||'|'||ffv_Cur.COMPILED_VALUE_ATTRIBUTES ||'|'||ffv_Cur.VALUE_CATEGORY ||'|'||ffv_Cur.ATTRIBUTE1 ||'|'||ffv_Cur.ATTRIBUTE2 ||'|'||ffv_Cur.ATTRIBUTE3 ||'|'||ffv_Cur.ATTRIBUTE4 ||'|'||ffv_Cur.ATTRIBUTE5 ||'|'||ffv_Cur.ATTRIBUTE6 ||'|'||ffv_Cur.ATTRIBUTE7 ||'|'||ffv_Cur.ATTRIBUTE8 ||'|'||ffv_Cur.ATTRIBUTE9 ||'|'||ffv_Cur.ATTRIBUTE10 ||'|'||ffv_Cur.ATTRIBUTE11 ||'|'||ffv_Cur.ATTRIBUTE12 ||'|'||ffv_Cur.ATTRIBUTE13 ||'|'
      ||ffv_Cur.ATTRIBUTE14 ||'|'||ffv_Cur.ATTRIBUTE15 ||'|'||ffv_Cur.ATTRIBUTE16 ||'|'||ffv_Cur.ATTRIBUTE17 ||'|'||ffv_Cur.ATTRIBUTE18 ||'|'||ffv_Cur.ATTRIBUTE19 ||'|'||ffv_Cur.ATTRIBUTE20 ||'|'||ffv_Cur.ATTRIBUTE21 ||'|'||ffv_Cur.ATTRIBUTE22 ||'|'||ffv_Cur.ATTRIBUTE23 ||'|'||ffv_Cur.ATTRIBUTE24 ||'|'||ffv_Cur.ATTRIBUTE25 ||'|'||ffv_Cur.ATTRIBUTE26 ||'|'||ffv_Cur.ATTRIBUTE27 ||'|'||ffv_Cur.ATTRIBUTE28 ||'|'||ffv_Cur.ATTRIBUTE29 ||'|'||ffv_Cur.ATTRIBUTE30 ||'|'||ffv_Cur.ATTRIBUTE31 ||'|'||ffv_Cur.ATTRIBUTE32 ||'|'||ffv_Cur.ATTRIBUTE33 ||'|'||ffv_Cur.ATTRIBUTE34 ||'|'||ffv_Cur.ATTRIBUTE35 ||'|'||ffv_Cur.ATTRIBUTE36 ||'|'||ffv_Cur.ATTRIBUTE37 ||'|'||ffv_Cur.ATTRIBUTE38 ||'|'||ffv_Cur.ATTRIBUTE39 ||'|'||ffv_Cur.ATTRIBUTE40 ||'|'||ffv_Cur.ATTRIBUTE41 ||'|'||ffv_Cur.ATTRIBUTE42 ||'|'||ffv_Cur.ATTRIBUTE43 ||'|'||ffv_Cur.ATTRIBUTE44 ||'|'||ffv_Cur.ATTRIBUTE45 ||'|'||ffv_Cur.ATTRIBUTE46 ||'|'||ffv_Cur.ATTRIBUTE47 ||'|'||ffv_Cur.ATTRIBUTE48 ||'|'||ffv_Cur.ATTRIBUTE49 ||'|'||
      ffv_Cur.ATTRIBUTE50 ||'|'||ffv_Cur.ATTRIBUTE_SORT_ORDER ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for fnd_flex_values = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for fnd_flex_values');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in fnd_flex_values =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_fnd_flex_values;
-- +=================================================================================================+
-- +===============  Extract # 27  ====================================================================+
PROCEDURE Extract_fnd_flex_value_hier(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_fnd_flex_value_hier.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_fnd_flex_value_hierarchies                                                      |
  -- | Description      : This procedure is used to extract fnd_flex_value_hierarchies                                 |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     :='FLEX_VALUE_SET_ID ' ||'|'||'PARENT_FLEX_VALUE ' ||'|'||'CHILD_FLEX_VALUE_LOW ' ||'|'||'CHILD_FLEX_VALUE_HIGH' ||'|'||'LAST_UPDATE_DATE ' ||'|'||'LAST_UPDATED_BY' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR ffvh_Cur IN
    (SELECT FLEX_VALUE_SET_ID ,
      PARENT_FLEX_VALUE ,
      CHILD_FLEX_VALUE_LOW ,
      CHILD_FLEX_VALUE_HIGH ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      CREATION_DATE ,
      CREATED_BY ,
      LAST_UPDATE_LOGIN ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE
    FROM fnd_flex_value_hierarchies
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= ffvh_Cur.FLEX_VALUE_SET_ID ||'|'||ffvh_Cur.PARENT_FLEX_VALUE ||'|'||ffvh_Cur.CHILD_FLEX_VALUE_LOW ||'|'||ffvh_Cur.CHILD_FLEX_VALUE_HIGH ||'|'||ffvh_Cur.LAST_UPDATE_DATE ||'|'||ffvh_Cur.LAST_UPDATED_BY ||'|'||ffvh_Cur.CREATION_DATE ||'|'||ffvh_Cur.CREATED_BY ||'|'||ffvh_Cur.LAST_UPDATE_LOGIN ||'|'||ffvh_Cur.START_DATE_ACTIVE ||'|'||ffvh_Cur.END_DATE_ACTIVE ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for fnd_flex_value_hierarchies = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for fnd_flex_value_hierarchies');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in fnd_flex_value_hierarchies =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_fnd_flex_value_hier;
-- +=================================================================================================+
-- +===============  Extract # 28  ====================================================================+
PROCEDURE Extract_ap_tax_codes_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_ap_tax_codes_all.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_tax_codes_all                                                     |
  -- | Description      : This procedure is used to extract ap_tax_codes_all                             |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     := 'TAX_ID' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'TAX_TYPE' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'DESCRIPTION' ||'|'||'TAX_RATE' ||'|'||'TAX_CODE_COMBINATION_ID' ||'|'||'INACTIVE_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'AWT_VENDOR_ID' ||'|'||'AWT_VENDOR_SITE_ID' ||'|'||'AWT_PERIOD_TYPE' ||'|'||'AWT_PERIOD_LIMIT' ||'|'||'RANGE_AMOUNT_BASIS' ||'|'||'RANGE_PERIOD_BASIS' ||'|'||'ORG_ID' ||'|'||'VAT_TRANSACTION_TYPE' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'
  ||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'WEB_ENABLED_FLAG' ||'|'||'TAX_RECOVERY_RULE_ID' ||'|'||'TAX_RECOVERY_RATE' ||'|'||'START_DATE' ||'|'||'ENABLED_FLAG' ||'|'||'AWT_RATE_TYPE' ||'|'||'OFFSET_TAX_CODE_ID ' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR atca_Cur IN
    (SELECT TAX_ID ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      TAX_TYPE ,
      SET_OF_BOOKS_ID ,
      DESCRIPTION ,
      TAX_RATE ,
      TAX_CODE_COMBINATION_ID ,
      INACTIVE_DATE ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      AWT_VENDOR_ID ,
      AWT_VENDOR_SITE_ID ,
      AWT_PERIOD_TYPE ,
      AWT_PERIOD_LIMIT ,
      RANGE_AMOUNT_BASIS ,
      RANGE_PERIOD_BASIS ,
      ORG_ID ,
      VAT_TRANSACTION_TYPE ,
      GLOBAL_ATTRIBUTE_CATEGORY ,
      GLOBAL_ATTRIBUTE1 ,
      GLOBAL_ATTRIBUTE2 ,
      GLOBAL_ATTRIBUTE3 ,
      GLOBAL_ATTRIBUTE4 ,
      GLOBAL_ATTRIBUTE5 ,
      GLOBAL_ATTRIBUTE6 ,
      GLOBAL_ATTRIBUTE7 ,
      GLOBAL_ATTRIBUTE8 ,
      GLOBAL_ATTRIBUTE9 ,
      GLOBAL_ATTRIBUTE10 ,
      GLOBAL_ATTRIBUTE11 ,
      GLOBAL_ATTRIBUTE12 ,
      GLOBAL_ATTRIBUTE13 ,
      GLOBAL_ATTRIBUTE14 ,
      GLOBAL_ATTRIBUTE20 ,
      GLOBAL_ATTRIBUTE19 ,
      GLOBAL_ATTRIBUTE18 ,
      GLOBAL_ATTRIBUTE17 ,
      GLOBAL_ATTRIBUTE15 ,
      GLOBAL_ATTRIBUTE16 ,
      WEB_ENABLED_FLAG ,
      TAX_RECOVERY_RULE_ID ,
      TAX_RECOVERY_RATE ,
      START_DATE ,
      ENABLED_FLAG ,
      AWT_RATE_TYPE ,
      OFFSET_TAX_CODE_ID
    FROM ap_tax_codes_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= atca_Cur.TAX_ID ||'|'||atca_Cur.LAST_UPDATE_DATE ||'|'||atca_Cur.LAST_UPDATED_BY ||'|'||atca_Cur.TAX_TYPE ||'|'||atca_Cur.SET_OF_BOOKS_ID ||'|'||atca_Cur.DESCRIPTION ||'|'||atca_Cur.TAX_RATE ||'|'||atca_Cur.TAX_CODE_COMBINATION_ID ||'|'||atca_Cur.INACTIVE_DATE ||'|'||atca_Cur.LAST_UPDATE_LOGIN ||'|'||atca_Cur.CREATION_DATE ||'|'||atca_Cur.CREATED_BY ||'|'||atca_Cur.ATTRIBUTE_CATEGORY ||'|'||atca_Cur.ATTRIBUTE1 ||'|'||atca_Cur.ATTRIBUTE2 ||'|'||atca_Cur.ATTRIBUTE3 ||'|'||atca_Cur.ATTRIBUTE4 ||'|'||atca_Cur.ATTRIBUTE5 ||'|'||atca_Cur.ATTRIBUTE6 ||'|'||atca_Cur.ATTRIBUTE7 ||'|'||atca_Cur.ATTRIBUTE8 ||'|'||atca_Cur.ATTRIBUTE9 ||'|'||atca_Cur.ATTRIBUTE10 ||'|'||atca_Cur.ATTRIBUTE11 ||'|'||atca_Cur.ATTRIBUTE12 ||'|'||atca_Cur.ATTRIBUTE13 ||'|'||atca_Cur.ATTRIBUTE14 ||'|'||atca_Cur.ATTRIBUTE15 ||'|'||atca_Cur.AWT_VENDOR_ID ||'|'||atca_Cur.AWT_VENDOR_SITE_ID ||'|'||atca_Cur.AWT_PERIOD_TYPE ||'|'||atca_Cur.AWT_PERIOD_LIMIT ||'|'||atca_Cur.RANGE_AMOUNT_BASIS ||'|'||
      atca_Cur.RANGE_PERIOD_BASIS ||'|'||atca_Cur.ORG_ID ||'|'||atca_Cur.VAT_TRANSACTION_TYPE ||'|'||atca_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||atca_Cur.GLOBAL_ATTRIBUTE1 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE2 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE3 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE4 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE5 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE6 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE7 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE8 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE9 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE10 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE11 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE12 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE13 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE14 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE20 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE19 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE18 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE17 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE15 ||'|'||atca_Cur.GLOBAL_ATTRIBUTE16 ||'|'||atca_Cur.WEB_ENABLED_FLAG ||'|'||atca_Cur.TAX_RECOVERY_RULE_ID ||'|'||atca_Cur.TAX_RECOVERY_RATE ||'|'||atca_Cur.START_DATE ||'|'||atca_Cur.ENABLED_FLAG ||'|'||
      atca_Cur.AWT_RATE_TYPE ||'|'||atca_Cur.OFFSET_TAX_CODE_ID ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for ap_tax_codes_all = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for ap_tax_codes_all');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in ap_tax_codes_all =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_ap_tax_codes_all;
-- +=================================================================================================+
-- +===============  Extract # 29  ====================================================================+
PROCEDURE Extract_mtl_categories_v(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   IN VARCHAR2 ,
    p_file_name   IN VARCHAR2 := 'OD_AP_PRG_mtl_categories_v.txt' ,
    p_debug_flag  IN VARCHAR2 ,
    p_file_path   IN VARCHAR2 ,
    p_cutoff_date IN VARCHAR2 ,
    p_no_of_days  IN VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_mtl_categories_b                                                      |
  -- | Description      : This procedure is used to extract mtl_categories_b                             |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     := 'CATEGORY_ID' ||'|'||'STRUCTURE_ID' ||'|'||'DISABLE_DATE' ||'|'||'WEB_STATUS' ||'|'||'SEGMENT1' ||'|'||'SEGMENT2' ||'|'||'SEGMENT3' ||'|'||'SEGMENT4' ||'|'||'SEGMENT5' ||'|'||'SEGMENT6' ||'|'||'SEGMENT7' ||'|'||'SEGMENT8' ||'|'||'SEGMENT9' ||'|'||'SEGMENT10' ||'|'||'SEGMENT11' ||'|'||'SEGMENT12' ||'|'||'SEGMENT13' ||'|'||'SEGMENT14' ||'|'||'SEGMENT15' ||'|'||'SEGMENT16' ||'|'||'SEGMENT17' ||'|'||'SEGMENT18' ||'|'||'SEGMENT19' ||'|'||'SEGMENT20' ||'|'||'SUMMARY_FLAG' ||'|'||'SUPPLIER_ENABLED_FLAG' ||'|'||'ENABLED_FLAG' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||'|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||
  'LAST_UPDATE_LOGIN' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'REQUEST_ID' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'DESCRIPTION' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR atca_Cur IN
    (SELECT CATEGORY_ID ,
      STRUCTURE_ID ,
      DISABLE_DATE ,
      WEB_STATUS ,
      SEGMENT1 ,
      SEGMENT2 ,
      SEGMENT3 ,
      SEGMENT4 ,
      SEGMENT5 ,
      SEGMENT6 ,
      SEGMENT7 ,
      SEGMENT8 ,
      SEGMENT9 ,
      SEGMENT10 ,
      SEGMENT11 ,
      SEGMENT12 ,
      SEGMENT13 ,
      SEGMENT14 ,
      SEGMENT15 ,
      SEGMENT16 ,
      SEGMENT17 ,
      SEGMENT18 ,
      SEGMENT19 ,
      SEGMENT20 ,
      SUMMARY_FLAG ,
      SUPPLIER_ENABLED_FLAG ,
      ENABLED_FLAG ,
      START_DATE_ACTIVE ,
      END_DATE_ACTIVE ,
      ATTRIBUTE_CATEGORY ,
      ATTRIBUTE1 ,
      ATTRIBUTE2 ,
      ATTRIBUTE3 ,
      ATTRIBUTE4 ,
      ATTRIBUTE5 ,
      ATTRIBUTE6 ,
      ATTRIBUTE7 ,
      ATTRIBUTE8 ,
      ATTRIBUTE9 ,
      ATTRIBUTE10 ,
      ATTRIBUTE11 ,
      ATTRIBUTE12 ,
      ATTRIBUTE13 ,
      ATTRIBUTE14 ,
      ATTRIBUTE15 ,
      LAST_UPDATE_DATE ,
      LAST_UPDATED_BY ,
      LAST_UPDATE_LOGIN ,
      CREATION_DATE ,
      CREATED_BY ,
      REQUEST_ID ,
      PROGRAM_APPLICATION_ID ,
      PROGRAM_UPDATE_DATE ,
      DESCRIPTION
    FROM mtl_categories_b
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= atca_Cur.CATEGORY_ID ||'|'||atca_Cur.STRUCTURE_ID ||'|'||atca_Cur.DISABLE_DATE ||'|'||atca_Cur.WEB_STATUS ||'|'||atca_Cur.SEGMENT1 ||'|'||atca_Cur.SEGMENT2 ||'|'||atca_Cur.SEGMENT3 ||'|'||atca_Cur.SEGMENT4 ||'|'||atca_Cur.SEGMENT5 ||'|'||atca_Cur.SEGMENT6 ||'|'||atca_Cur.SEGMENT7 ||'|'||atca_Cur.SEGMENT8 ||'|'||atca_Cur.SEGMENT9 ||'|'||atca_Cur.SEGMENT10 ||'|'||atca_Cur.SEGMENT11 ||'|'||atca_Cur.SEGMENT12 ||'|'||atca_Cur.SEGMENT13 ||'|'||atca_Cur.SEGMENT14 ||'|'||atca_Cur.SEGMENT15 ||'|'||atca_Cur.SEGMENT16 ||'|'||atca_Cur.SEGMENT17 ||'|'||atca_Cur.SEGMENT18 ||'|'||atca_Cur.SEGMENT19 ||'|'||atca_Cur.SEGMENT20 ||'|'||atca_Cur.SUMMARY_FLAG ||'|'||atca_Cur.SUPPLIER_ENABLED_FLAG ||'|'||atca_Cur.ENABLED_FLAG ||'|'||atca_Cur.START_DATE_ACTIVE ||'|'||atca_Cur.END_DATE_ACTIVE ||'|'||atca_Cur.ATTRIBUTE_CATEGORY ||'|'||atca_Cur.ATTRIBUTE1 ||'|'||atca_Cur.ATTRIBUTE2 ||'|'||atca_Cur.ATTRIBUTE3 ||'|'||atca_Cur.ATTRIBUTE4 ||'|'||atca_Cur.ATTRIBUTE5 ||'|'||atca_Cur.ATTRIBUTE6 ||'|'||
      atca_Cur.ATTRIBUTE7 ||'|'||atca_Cur.ATTRIBUTE8 ||'|'||atca_Cur.ATTRIBUTE9 ||'|'||atca_Cur.ATTRIBUTE10 ||'|'||atca_Cur.ATTRIBUTE11 ||'|'||atca_Cur.ATTRIBUTE12 ||'|'||atca_Cur.ATTRIBUTE13 ||'|'||atca_Cur.ATTRIBUTE14 ||'|'||atca_Cur.ATTRIBUTE15 ||'|'||atca_Cur.LAST_UPDATE_DATE ||'|'||atca_Cur.LAST_UPDATED_BY ||'|'||atca_Cur.LAST_UPDATE_LOGIN ||'|'||atca_Cur.CREATION_DATE ||'|'||atca_Cur.CREATED_BY ||'|'||atca_Cur.REQUEST_ID ||'|'||atca_Cur.PROGRAM_APPLICATION_ID ||'|'||atca_Cur.PROGRAM_UPDATE_DATE ||'|'||atca_Cur.DESCRIPTION ;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for mtl_categories_b = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for mtl_categories_b');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in mtl_categories_b =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END Extract_mtl_categories_v;
-- +=================================================================================================+
-- +=================================================================================================+
-- +===============  Extract # 30  ====================================================================+
PROCEDURE Extract_xx_ap_trade_inv_lines(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_CSISALE_XX_AP_TRADE_INV_LINES.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_xx_ap_trade_inv_lines                                                     |
  -- | Description      : This procedure is used to extract xx_ap_trade_inv_lines for CSI Sales                             |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  LT_FILE    := UTL_FILE.FOPEN(GC_FILE_PATH,LC_FILENAME ,'w',LN_BUFFER);
  L_DATA     := 'AP-VENDOR' ||'|'||'INVOICE-NBR' ||'|'||'LOC-ID' ||'|'||'SALE-DT' ||'|'||'SKU' ||'|'||'INVOICE-QTY' ||'|'||'MDSE-AMOUNT'||'|'||'AVG-COST-CSI'||'|'||'PO-COST-CSI' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR atil_Cur IN
    (SELECT LTRIM(AP_VENDOR, '0') AP_VENDOR,
      INVOICE_NUMBER INVOICE_NUMBER,
      LOCATION_NUMBER LOCATION_NUMBER,
      INVOICE_DATE SALE_DATE,
      SKU,
      DECODE(QUANTITY_SIGN,'-',QUANTITY*-1,QUANTITY) INVOICE_QTY,
      PO_COST PO_COST_CSI,
      MDSE_AMOUNT,
      cost AVG_COST      
    from XX_AP_TRADE_INV_LINES
    WHERE source='US_OD_CONSIGNMENT_SALES' AND CONSIGN_FLAG = 'Y'
    AND (TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date)
    )
    LOOP
      l_data:= atil_Cur.AP_VENDOR ||'|'||atil_Cur.INVOICE_NUMBER ||'|'||atil_Cur.LOCATION_NUMBER ||'|'||atil_Cur.SALE_DATE ||'|'||atil_Cur.SKU ||'|'||atil_Cur.INVOICE_QTY||'|'||atil_Cur.MDSE_AMOUNT||'|'||atil_Cur.AVG_COST||'|'||atil_Cur.PO_COST_CSI;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for XX_AP_TRADE_INV_LINES = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for XX_AP_TRADE_INV_LINES');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in XX_AP_TRADE_INV_LINES =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END extract_xx_ap_trade_inv_lines;
-- +===============  Extract # 31  ====================================================================+
PROCEDURE Extract_ap_invoice_lines_all(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_ap_invoice_lines_all.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_ap_invoice_lines_all                                                  |
  -- | Description      : This procedure is used to extract ap_invoice_lines_all                         |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := utl_file.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     := 'INVOICE_ID' ||'|'||'LINE_NUMBER' ||'|'||'LINE_TYPE_LOOKUP_CODE' ||'|'||'REQUESTER_ID' ||'|'||'DESCRIPTION' ||'|'||'LINE_SOURCE' ||'|'||'ORG_ID' ||'|'||'LINE_GROUP_NUMBER' ||'|'||'INVENTORY_ITEM_ID' ||'|'||'ITEM_DESCRIPTION' ||'|'||'SERIAL_NUMBER' ||'|'||'MANUFACTURER' ||'|'||'MODEL_NUMBER' ||'|'||'WARRANTY_NUMBER' ||'|'||'GENERATE_DISTS' ||'|'||'MATCH_TYPE' ||'|'||'DISTRIBUTION_SET_ID' ||'|'||'ACCOUNT_SEGMENT' ||'|'||'BALANCING_SEGMENT' ||'|'||'COST_CENTER_SEGMENT' ||'|'||'OVERLAY_DIST_CODE_CONCAT' ||'|'||'DEFAULT_DIST_CCID' ||'|'||'PRORATE_ACROSS_ALL_ITEMS' ||'|'||'ACCOUNTING_DATE' ||'|'||'PERIOD_NAME' ||'|'||'DEFERRED_ACCTG_FLAG' ||'|'||'DEF_ACCTG_START_DATE' ||'|'||'DEF_ACCTG_END_DATE' ||'|'||'DEF_ACCTG_NUMBER_OF_PERIODS' ||'|'||'DEF_ACCTG_PERIOD_TYPE' ||'|'||'SET_OF_BOOKS_ID' ||'|'||'AMOUNT' ||'|'||'BASE_AMOUNT' ||'|'||'ROUNDING_AMT' ||'|'||'QUANTITY_INVOICED' ||'|'||'UNIT_MEAS_LOOKUP_CODE' ||'|'||'UNIT_PRICE' ||'|'||'WFAPPROVAL_STATUS' ||'|'||
  'USSGL_TRANSACTION_CODE' ||'|'||'DISCARDED_FLAG' ||'|'||'ORIGINAL_AMOUNT' ||'|'||'ORIGINAL_BASE_AMOUNT' ||'|'||'ORIGINAL_ROUNDING_AMT' ||'|'||'CANCELLED_FLAG' ||'|'||'INCOME_TAX_REGION' ||'|'||'TYPE_1099' ||'|'||'STAT_AMOUNT' ||'|'||'PREPAY_INVOICE_ID' ||'|'||'PREPAY_LINE_NUMBER' ||'|'||'INVOICE_INCLUDES_PREPAY_FLAG' ||'|'||'CORRECTED_INV_ID' ||'|'||'CORRECTED_LINE_NUMBER' ||'|'||'PO_HEADER_ID' ||'|'||'PO_LINE_ID' ||'|'||'PO_RELEASE_ID' ||'|'||'PO_LINE_LOCATION_ID' ||'|'||'PO_DISTRIBUTION_ID' ||'|'||'RCV_TRANSACTION_ID' ||'|'||'FINAL_MATCH_FLAG' ||'|'||'ASSETS_TRACKING_FLAG' ||'|'||'ASSET_BOOK_TYPE_CODE' ||'|'||'ASSET_CATEGORY_ID' ||'|'||'PROJECT_ID' ||'|'||'TASK_ID' ||'|'||'EXPENDITURE_TYPE' ||'|'||'EXPENDITURE_ITEM_DATE' ||'|'||'EXPENDITURE_ORGANIZATION_ID' ||'|'||'PA_QUANTITY' ||'|'||'PA_CC_AR_INVOICE_ID' ||'|'||'PA_CC_AR_INVOICE_LINE_NUM' ||'|'||'PA_CC_PROCESSED_CODE' ||'|'||'AWARD_ID' ||'|'||'AWT_GROUP_ID' ||'|'||'REFERENCE_1' ||'|'||'REFERENCE_2' ||'|'||
  'RECEIPT_VERIFIED_FLAG' ||'|'||'RECEIPT_REQUIRED_FLAG' ||'|'||'RECEIPT_MISSING_FLAG' ||'|'||'JUSTIFICATION' ||'|'||'EXPENSE_GROUP' ||'|'||'START_EXPENSE_DATE' ||'|'||'END_EXPENSE_DATE' ||'|'||'RECEIPT_CURRENCY_CODE' ||'|'||'RECEIPT_CONVERSION_RATE' ||'|'||'RECEIPT_CURRENCY_AMOUNT' ||'|'||'DAILY_AMOUNT' ||'|'||'WEB_PARAMETER_ID' ||'|'||'ADJUSTMENT_REASON' ||'|'||'MERCHANT_DOCUMENT_NUMBER' ||'|'||'MERCHANT_NAME' ||'|'||'MERCHANT_REFERENCE' ||'|'||'MERCHANT_TAX_REG_NUMBER' ||'|'||'MERCHANT_TAXPAYER_ID' ||'|'||'COUNTRY_OF_SUPPLY' ||'|'||'CREDIT_CARD_TRX_ID' ||'|'||'COMPANY_PREPAID_INVOICE_ID' ||'|'||'CC_REVERSAL_FLAG' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'PROGRAM_APPLICATION_ID' ||'|'||'PROGRAM_ID' ||'|'||'PROGRAM_UPDATE_DATE' ||'|'||'REQUEST_ID' ||'|'||'ATTRIBUTE_CATEGORY' ||'|'||'ATTRIBUTE1' ||'|'||'ATTRIBUTE2' ||'|'||'ATTRIBUTE3' ||'|'||'ATTRIBUTE4' ||'|'||'ATTRIBUTE5' ||'|'||'ATTRIBUTE6' ||
  '|'||'ATTRIBUTE7' ||'|'||'ATTRIBUTE8' ||'|'||'ATTRIBUTE9' ||'|'||'ATTRIBUTE10' ||'|'||'ATTRIBUTE11' ||'|'||'ATTRIBUTE12' ||'|'||'ATTRIBUTE13' ||'|'||'ATTRIBUTE14' ||'|'||'ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE_CATEGORY' ||'|'||'GLOBAL_ATTRIBUTE1' ||'|'||'GLOBAL_ATTRIBUTE2' ||'|'||'GLOBAL_ATTRIBUTE3' ||'|'||'GLOBAL_ATTRIBUTE4' ||'|'||'GLOBAL_ATTRIBUTE5' ||'|'||'GLOBAL_ATTRIBUTE6' ||'|'||'GLOBAL_ATTRIBUTE7' ||'|'||'GLOBAL_ATTRIBUTE8' ||'|'||'GLOBAL_ATTRIBUTE9' ||'|'||'GLOBAL_ATTRIBUTE10' ||'|'||'GLOBAL_ATTRIBUTE11' ||'|'||'GLOBAL_ATTRIBUTE12' ||'|'||'GLOBAL_ATTRIBUTE13' ||'|'||'GLOBAL_ATTRIBUTE14' ||'|'||'GLOBAL_ATTRIBUTE15' ||'|'||'GLOBAL_ATTRIBUTE16' ||'|'||'GLOBAL_ATTRIBUTE17' ||'|'||'GLOBAL_ATTRIBUTE18' ||'|'||'GLOBAL_ATTRIBUTE19' ||'|'||'GLOBAL_ATTRIBUTE20' ||'|'||'LINE_SELECTED_FOR_APPL_FLAG' ||'|'||'PREPAY_APPL_REQUEST_ID' ||'|'||'APPLICATION_ID' ||'|'||'PRODUCT_TABLE' ||'|'||'REFERENCE_KEY1' ||'|'||'REFERENCE_KEY2' ||'|'||'REFERENCE_KEY3' ||'|'||'REFERENCE_KEY4' ||'|'||
  'REFERENCE_KEY5' ||'|'||'PURCHASING_CATEGORY_ID' ||'|'||'COST_FACTOR_ID' ||'|'||'CONTROL_AMOUNT' ||'|'||'ASSESSABLE_VALUE' ||'|'||'TOTAL_REC_TAX_AMOUNT' ||'|'||'TOTAL_NREC_TAX_AMOUNT' ||'|'||'TOTAL_REC_TAX_AMT_FUNCL_CURR' ||'|'||'TOTAL_NREC_TAX_AMT_FUNCL_CURR' ||'|'||'INCLUDED_TAX_AMOUNT' ||'|'||'PRIMARY_INTENDED_USE' ||'|'||'TAX_ALREADY_CALCULATED_FLAG' ||'|'||'SHIP_TO_LOCATION_ID' ||'|'||'PRODUCT_TYPE' ||'|'||'PRODUCT_CATEGORY' ||'|'||'PRODUCT_FISC_CLASSIFICATION' ||'|'||'USER_DEFINED_FISC_CLASS' ||'|'||'TRX_BUSINESS_CATEGORY' ||'|'||'SUMMARY_TAX_LINE_ID' ||'|'||'TAX_REGIME_CODE' ||'|'||'TAX' ||'|'||'TAX_JURISDICTION_CODE' ||'|'||'TAX_STATUS_CODE' ||'|'||'TAX_RATE_ID' ||'|'||'TAX_RATE_CODE' ||'|'||'TAX_RATE' ||'|'||'TAX_CODE_ID' ||'|'||'HISTORICAL_FLAG' ||'|'||'TAX_CLASSIFICATION_CODE' ||'|'||'SOURCE_APPLICATION_ID' ||'|'||'SOURCE_EVENT_CLASS_CODE' ||'|'||'SOURCE_ENTITY_CODE' ||'|'||'SOURCE_TRX_ID' ||'|'||'SOURCE_LINE_ID' ||'|'||'SOURCE_TRX_LEVEL_TYPE' ||'|'||'RETAINED_AMOUNT' ||
  '|'||'RETAINED_AMOUNT_REMAINING' ||'|'||'RETAINED_INVOICE_ID' ||'|'||'RETAINED_LINE_NUMBER' ||'|'||'LINE_SELECTED_FOR_RELEASE_FLAG' ||'|'||'LINE_OWNER_ROLE' ||'|'||'DISPUTABLE_FLAG' ||'|'||'RCV_SHIPMENT_LINE_ID' ||'|'||'AIL_INVOICE_ID' ||'|'||'AIL_DISTRIBUTION_LINE_NUMBER' ||'|'||'AIL_INVOICE_ID2' ||'|'||'AIL_DISTRIBUTION_LINE_NUMBER2' ||'|'||'AIL_INVOICE_ID3' ||'|'||'AIL_DISTRIBUTION_LINE_NUMBER3' ||'|'||'AIL_INVOICE_ID4' ||'|'||'PAY_AWT_GROUP_ID';
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR aila_Cur IN
    (SELECT INVOICE_ID,
      LINE_NUMBER,
      LINE_TYPE_LOOKUP_CODE,
      REQUESTER_ID,
      DESCRIPTION,
      LINE_SOURCE,
      ORG_ID,
      LINE_GROUP_NUMBER,
      INVENTORY_ITEM_ID,
      ITEM_DESCRIPTION,
      SERIAL_NUMBER,
      MANUFACTURER,
      MODEL_NUMBER,
      WARRANTY_NUMBER,
      GENERATE_DISTS,
      MATCH_TYPE,
      DISTRIBUTION_SET_ID,
      ACCOUNT_SEGMENT,
      BALANCING_SEGMENT,
      COST_CENTER_SEGMENT,
      OVERLAY_DIST_CODE_CONCAT,
      DEFAULT_DIST_CCID,
      PRORATE_ACROSS_ALL_ITEMS,
      ACCOUNTING_DATE,
      PERIOD_NAME,
      DEFERRED_ACCTG_FLAG,
      DEF_ACCTG_START_DATE,
      DEF_ACCTG_END_DATE,
      DEF_ACCTG_NUMBER_OF_PERIODS,
      DEF_ACCTG_PERIOD_TYPE,
      SET_OF_BOOKS_ID,
      AMOUNT,
      BASE_AMOUNT,
      ROUNDING_AMT,
      QUANTITY_INVOICED,
      UNIT_MEAS_LOOKUP_CODE,
      UNIT_PRICE,
      WFAPPROVAL_STATUS,
      USSGL_TRANSACTION_CODE,
      DISCARDED_FLAG,
      ORIGINAL_AMOUNT,
      ORIGINAL_BASE_AMOUNT,
      ORIGINAL_ROUNDING_AMT,
      CANCELLED_FLAG,
      INCOME_TAX_REGION,
      TYPE_1099,
      STAT_AMOUNT,
      PREPAY_INVOICE_ID,
      PREPAY_LINE_NUMBER,
      INVOICE_INCLUDES_PREPAY_FLAG,
      CORRECTED_INV_ID,
      CORRECTED_LINE_NUMBER,
      PO_HEADER_ID,
      PO_LINE_ID,
      PO_RELEASE_ID,
      PO_LINE_LOCATION_ID,
      PO_DISTRIBUTION_ID,
      RCV_TRANSACTION_ID,
      FINAL_MATCH_FLAG,
      ASSETS_TRACKING_FLAG,
      ASSET_BOOK_TYPE_CODE,
      ASSET_CATEGORY_ID,
      PROJECT_ID,
      TASK_ID,
      EXPENDITURE_TYPE,
      EXPENDITURE_ITEM_DATE,
      EXPENDITURE_ORGANIZATION_ID,
      PA_QUANTITY,
      PA_CC_AR_INVOICE_ID,
      PA_CC_AR_INVOICE_LINE_NUM,
      PA_CC_PROCESSED_CODE,
      AWARD_ID,
      AWT_GROUP_ID,
      REFERENCE_1,
      REFERENCE_2,
      RECEIPT_VERIFIED_FLAG,
      RECEIPT_REQUIRED_FLAG,
      RECEIPT_MISSING_FLAG,
      JUSTIFICATION,
      EXPENSE_GROUP,
      START_EXPENSE_DATE,
      END_EXPENSE_DATE,
      RECEIPT_CURRENCY_CODE,
      RECEIPT_CONVERSION_RATE,
      RECEIPT_CURRENCY_AMOUNT,
      DAILY_AMOUNT,
      WEB_PARAMETER_ID,
      ADJUSTMENT_REASON,
      MERCHANT_DOCUMENT_NUMBER,
      MERCHANT_NAME,
      MERCHANT_REFERENCE,
      MERCHANT_TAX_REG_NUMBER,
      MERCHANT_TAXPAYER_ID,
      COUNTRY_OF_SUPPLY,
      CREDIT_CARD_TRX_ID,
      COMPANY_PREPAID_INVOICE_ID,
      CC_REVERSAL_FLAG,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATED_BY,
      LAST_UPDATE_DATE,
      LAST_UPDATE_LOGIN,
      PROGRAM_APPLICATION_ID,
      PROGRAM_ID,
      PROGRAM_UPDATE_DATE,
      REQUEST_ID,
      ATTRIBUTE_CATEGORY,
      ATTRIBUTE1,
      ATTRIBUTE2,
      ATTRIBUTE3,
      ATTRIBUTE4,
      ATTRIBUTE5,
      ATTRIBUTE6,
      ATTRIBUTE7,
      ATTRIBUTE8,
      ATTRIBUTE9,
      ATTRIBUTE10,
      ATTRIBUTE11,
      ATTRIBUTE12,
      ATTRIBUTE13,
      ATTRIBUTE14,
      ATTRIBUTE15,
      GLOBAL_ATTRIBUTE_CATEGORY,
      GLOBAL_ATTRIBUTE1,
      GLOBAL_ATTRIBUTE2,
      GLOBAL_ATTRIBUTE3,
      GLOBAL_ATTRIBUTE4,
      GLOBAL_ATTRIBUTE5,
      GLOBAL_ATTRIBUTE6,
      GLOBAL_ATTRIBUTE7,
      GLOBAL_ATTRIBUTE8,
      GLOBAL_ATTRIBUTE9,
      GLOBAL_ATTRIBUTE10,
      GLOBAL_ATTRIBUTE11,
      GLOBAL_ATTRIBUTE12,
      GLOBAL_ATTRIBUTE13,
      GLOBAL_ATTRIBUTE14,
      GLOBAL_ATTRIBUTE15,
      GLOBAL_ATTRIBUTE16,
      GLOBAL_ATTRIBUTE17,
      GLOBAL_ATTRIBUTE18,
      GLOBAL_ATTRIBUTE19,
      GLOBAL_ATTRIBUTE20,
      LINE_SELECTED_FOR_APPL_FLAG,
      PREPAY_APPL_REQUEST_ID,
      APPLICATION_ID,
      PRODUCT_TABLE,
      REFERENCE_KEY1,
      REFERENCE_KEY2,
      REFERENCE_KEY3,
      REFERENCE_KEY4,
      REFERENCE_KEY5,
      PURCHASING_CATEGORY_ID,
      COST_FACTOR_ID,
      CONTROL_AMOUNT,
      ASSESSABLE_VALUE,
      TOTAL_REC_TAX_AMOUNT,
      TOTAL_NREC_TAX_AMOUNT,
      TOTAL_REC_TAX_AMT_FUNCL_CURR,
      TOTAL_NREC_TAX_AMT_FUNCL_CURR,
      INCLUDED_TAX_AMOUNT,
      PRIMARY_INTENDED_USE,
      TAX_ALREADY_CALCULATED_FLAG,
      SHIP_TO_LOCATION_ID,
      PRODUCT_TYPE,
      PRODUCT_CATEGORY,
      PRODUCT_FISC_CLASSIFICATION,
      USER_DEFINED_FISC_CLASS,
      TRX_BUSINESS_CATEGORY,
      SUMMARY_TAX_LINE_ID,
      TAX_REGIME_CODE,
      TAX,
      TAX_JURISDICTION_CODE,
      TAX_STATUS_CODE,
      TAX_RATE_ID,
      TAX_RATE_CODE,
      TAX_RATE,
      TAX_CODE_ID,
      HISTORICAL_FLAG,
      TAX_CLASSIFICATION_CODE,
      SOURCE_APPLICATION_ID,
      SOURCE_EVENT_CLASS_CODE,
      SOURCE_ENTITY_CODE,
      SOURCE_TRX_ID,
      SOURCE_LINE_ID,
      SOURCE_TRX_LEVEL_TYPE,
      RETAINED_AMOUNT,
      RETAINED_AMOUNT_REMAINING,
      RETAINED_INVOICE_ID,
      RETAINED_LINE_NUMBER,
      LINE_SELECTED_FOR_RELEASE_FLAG,
      LINE_OWNER_ROLE,
      DISPUTABLE_FLAG,
      RCV_SHIPMENT_LINE_ID,
      AIL_INVOICE_ID,
      AIL_DISTRIBUTION_LINE_NUMBER,
      AIL_INVOICE_ID2,
      AIL_DISTRIBUTION_LINE_NUMBER2,
      AIL_INVOICE_ID3,
      AIL_DISTRIBUTION_LINE_NUMBER3,
      AIL_INVOICE_ID4,
      pay_awt_group_id
    FROM ap_invoice_lines_all
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= aila_Cur.INVOICE_ID ||'|'||aila_Cur.LINE_NUMBER ||'|'||aila_Cur.LINE_TYPE_LOOKUP_CODE ||'|'||aila_Cur.REQUESTER_ID ||'|'||aila_Cur.DESCRIPTION ||'|'||aila_Cur.LINE_SOURCE ||'|'||aila_Cur.ORG_ID ||'|'||aila_Cur.LINE_GROUP_NUMBER ||'|'||aila_Cur.INVENTORY_ITEM_ID ||'|'||aila_Cur.ITEM_DESCRIPTION ||'|'||aila_Cur.SERIAL_NUMBER ||'|'||aila_Cur.MANUFACTURER ||'|'||aila_Cur.MODEL_NUMBER ||'|'||aila_Cur.WARRANTY_NUMBER ||'|'||aila_Cur.GENERATE_DISTS ||'|'||aila_Cur.MATCH_TYPE ||'|'||aila_Cur.DISTRIBUTION_SET_ID ||'|'||aila_Cur.ACCOUNT_SEGMENT ||'|'||aila_Cur.BALANCING_SEGMENT ||'|'||aila_Cur.COST_CENTER_SEGMENT ||'|'||aila_Cur.OVERLAY_DIST_CODE_CONCAT ||'|'||aila_Cur.DEFAULT_DIST_CCID ||'|'||aila_Cur.PRORATE_ACROSS_ALL_ITEMS ||'|'||aila_Cur.ACCOUNTING_DATE ||'|'||aila_Cur.PERIOD_NAME ||'|'||aila_Cur.DEFERRED_ACCTG_FLAG ||'|'||aila_Cur.DEF_ACCTG_START_DATE ||'|'||aila_Cur.DEF_ACCTG_END_DATE ||'|'||aila_Cur.DEF_ACCTG_NUMBER_OF_PERIODS ||'|'||aila_Cur.DEF_ACCTG_PERIOD_TYPE ||'|'
      ||aila_Cur.SET_OF_BOOKS_ID ||'|'||aila_Cur.AMOUNT ||'|'||aila_Cur.BASE_AMOUNT ||'|'||aila_Cur.ROUNDING_AMT ||'|'||aila_Cur.QUANTITY_INVOICED ||'|'||aila_Cur.UNIT_MEAS_LOOKUP_CODE ||'|'||aila_Cur.UNIT_PRICE ||'|'||aila_Cur.WFAPPROVAL_STATUS ||'|'||aila_Cur.USSGL_TRANSACTION_CODE ||'|'||aila_Cur.DISCARDED_FLAG ||'|'||aila_Cur.ORIGINAL_AMOUNT ||'|'||aila_Cur.ORIGINAL_BASE_AMOUNT ||'|'||aila_Cur.ORIGINAL_ROUNDING_AMT ||'|'||aila_Cur.CANCELLED_FLAG ||'|'||aila_Cur.INCOME_TAX_REGION ||'|'||aila_Cur.TYPE_1099 ||'|'||aila_Cur.STAT_AMOUNT ||'|'||aila_Cur.PREPAY_INVOICE_ID ||'|'||aila_Cur.PREPAY_LINE_NUMBER ||'|'||aila_Cur.INVOICE_INCLUDES_PREPAY_FLAG ||'|'||aila_Cur.CORRECTED_INV_ID ||'|'||aila_Cur.CORRECTED_LINE_NUMBER ||'|'||aila_Cur.PO_HEADER_ID ||'|'||aila_Cur.PO_LINE_ID ||'|'||aila_Cur.PO_RELEASE_ID ||'|'||aila_Cur.PO_LINE_LOCATION_ID ||'|'||aila_Cur.PO_DISTRIBUTION_ID ||'|'||aila_Cur.RCV_TRANSACTION_ID ||'|'||aila_Cur.FINAL_MATCH_FLAG ||'|'||aila_Cur.ASSETS_TRACKING_FLAG ||'|'||
      aila_Cur.ASSET_BOOK_TYPE_CODE ||'|'||aila_Cur.ASSET_CATEGORY_ID ||'|'||aila_Cur.PROJECT_ID ||'|'||aila_Cur.TASK_ID ||'|'||aila_Cur.EXPENDITURE_TYPE ||'|'||aila_Cur.EXPENDITURE_ITEM_DATE ||'|'||aila_Cur.EXPENDITURE_ORGANIZATION_ID ||'|'||aila_Cur.PA_QUANTITY ||'|'||aila_Cur.PA_CC_AR_INVOICE_ID ||'|'||aila_Cur.PA_CC_AR_INVOICE_LINE_NUM ||'|'||aila_Cur.PA_CC_PROCESSED_CODE ||'|'||aila_Cur.AWARD_ID ||'|'||aila_Cur.AWT_GROUP_ID ||'|'||aila_Cur.REFERENCE_1 ||'|'||aila_Cur.REFERENCE_2 ||'|'||aila_Cur.RECEIPT_VERIFIED_FLAG ||'|'||aila_Cur.RECEIPT_REQUIRED_FLAG ||'|'||aila_Cur.RECEIPT_MISSING_FLAG ||'|'||aila_Cur.JUSTIFICATION ||'|'||aila_Cur.EXPENSE_GROUP ||'|'||aila_Cur.START_EXPENSE_DATE ||'|'||aila_Cur.END_EXPENSE_DATE ||'|'||aila_Cur.RECEIPT_CURRENCY_CODE ||'|'||aila_Cur.RECEIPT_CONVERSION_RATE ||'|'||aila_Cur.RECEIPT_CURRENCY_AMOUNT ||'|'||aila_Cur.DAILY_AMOUNT ||'|'||aila_Cur.WEB_PARAMETER_ID ||'|'||aila_Cur.ADJUSTMENT_REASON ||'|'||aila_Cur.MERCHANT_DOCUMENT_NUMBER ||'|'||
      aila_Cur.MERCHANT_NAME ||'|'||aila_Cur.MERCHANT_REFERENCE ||'|'||aila_Cur.MERCHANT_TAX_REG_NUMBER ||'|'||aila_Cur.MERCHANT_TAXPAYER_ID ||'|'||aila_Cur.COUNTRY_OF_SUPPLY ||'|'||aila_Cur.CREDIT_CARD_TRX_ID ||'|'||aila_Cur.COMPANY_PREPAID_INVOICE_ID ||'|'||aila_Cur.CC_REVERSAL_FLAG ||'|'||aila_Cur.CREATION_DATE ||'|'||aila_Cur.CREATED_BY ||'|'||aila_Cur.LAST_UPDATED_BY ||'|'||aila_Cur.LAST_UPDATE_DATE ||'|'||aila_Cur.LAST_UPDATE_LOGIN ||'|'||aila_Cur.PROGRAM_APPLICATION_ID ||'|'||aila_Cur.PROGRAM_ID ||'|'||aila_Cur.PROGRAM_UPDATE_DATE ||'|'||aila_Cur.REQUEST_ID ||'|'||aila_Cur.ATTRIBUTE_CATEGORY ||'|'||aila_Cur.ATTRIBUTE1 ||'|'||aila_Cur.ATTRIBUTE2 ||'|'||aila_Cur.ATTRIBUTE3 ||'|'||aila_Cur.ATTRIBUTE4 ||'|'||aila_Cur.ATTRIBUTE5 ||'|'||aila_Cur.ATTRIBUTE6 ||'|'||aila_Cur.ATTRIBUTE7 ||'|'||aila_Cur.ATTRIBUTE8 ||'|'||aila_Cur.ATTRIBUTE9 ||'|'||aila_Cur.ATTRIBUTE10 ||'|'||aila_Cur.ATTRIBUTE11 ||'|'||aila_Cur.ATTRIBUTE12 ||'|'||aila_Cur.ATTRIBUTE13 ||'|'||aila_Cur.ATTRIBUTE14 ||'|'||
      aila_Cur.ATTRIBUTE15 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE_CATEGORY ||'|'||aila_Cur.GLOBAL_ATTRIBUTE1 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE2 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE3 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE4 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE5 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE6 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE7 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE8 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE9 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE10 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE11 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE12 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE13 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE14 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE15 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE16 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE17 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE18 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE19 ||'|'||aila_Cur.GLOBAL_ATTRIBUTE20 ||'|'||aila_Cur.LINE_SELECTED_FOR_APPL_FLAG ||'|'||aila_Cur.PREPAY_APPL_REQUEST_ID ||'|'||aila_Cur.APPLICATION_ID ||'|'||aila_Cur.PRODUCT_TABLE ||'|'||aila_Cur.REFERENCE_KEY1 ||'|'||aila_Cur.REFERENCE_KEY2 ||'|'||aila_Cur.REFERENCE_KEY3
      ||'|'||aila_Cur.REFERENCE_KEY4 ||'|'||aila_Cur.REFERENCE_KEY5 ||'|'||aila_Cur.PURCHASING_CATEGORY_ID ||'|'||aila_Cur.COST_FACTOR_ID ||'|'||aila_Cur.CONTROL_AMOUNT ||'|'||aila_Cur.ASSESSABLE_VALUE ||'|'||aila_Cur.TOTAL_REC_TAX_AMOUNT ||'|'||aila_Cur.TOTAL_NREC_TAX_AMOUNT ||'|'||aila_Cur.TOTAL_REC_TAX_AMT_FUNCL_CURR ||'|'||aila_Cur.TOTAL_NREC_TAX_AMT_FUNCL_CURR ||'|'||aila_Cur.INCLUDED_TAX_AMOUNT ||'|'||aila_Cur.PRIMARY_INTENDED_USE ||'|'||aila_Cur.TAX_ALREADY_CALCULATED_FLAG ||'|'||aila_Cur.SHIP_TO_LOCATION_ID ||'|'||aila_Cur.PRODUCT_TYPE ||'|'||aila_Cur.PRODUCT_CATEGORY ||'|'||aila_Cur.PRODUCT_FISC_CLASSIFICATION ||'|'||aila_Cur.USER_DEFINED_FISC_CLASS ||'|'||aila_Cur.TRX_BUSINESS_CATEGORY ||'|'||aila_Cur.SUMMARY_TAX_LINE_ID ||'|'||aila_Cur.TAX_REGIME_CODE ||'|'||aila_Cur.TAX ||'|'||aila_Cur.TAX_JURISDICTION_CODE ||'|'||aila_Cur.TAX_STATUS_CODE ||'|'||aila_Cur.TAX_RATE_ID ||'|'||aila_Cur.TAX_RATE_CODE ||'|'||aila_Cur.TAX_RATE ||'|'||aila_Cur.TAX_CODE_ID ||'|'||
      aila_Cur.HISTORICAL_FLAG ||'|'||aila_Cur.TAX_CLASSIFICATION_CODE ||'|'||aila_Cur.SOURCE_APPLICATION_ID ||'|'||aila_Cur.SOURCE_EVENT_CLASS_CODE ||'|'||aila_Cur.SOURCE_ENTITY_CODE ||'|'||aila_Cur.SOURCE_TRX_ID ||'|'||aila_Cur.SOURCE_LINE_ID ||'|'||aila_Cur.SOURCE_TRX_LEVEL_TYPE ||'|'||aila_Cur.RETAINED_AMOUNT ||'|'||aila_Cur.RETAINED_AMOUNT_REMAINING ||'|'||aila_Cur.RETAINED_INVOICE_ID ||'|'||aila_Cur.RETAINED_LINE_NUMBER ||'|'||aila_Cur.LINE_SELECTED_FOR_RELEASE_FLAG ||'|'||aila_Cur.LINE_OWNER_ROLE ||'|'||aila_Cur.DISPUTABLE_FLAG ||'|'||aila_Cur.RCV_SHIPMENT_LINE_ID ||'|'||aila_Cur.AIL_INVOICE_ID ||'|'||aila_Cur.AIL_DISTRIBUTION_LINE_NUMBER ||'|'||aila_Cur.AIL_INVOICE_ID2 ||'|'||aila_Cur.AIL_DISTRIBUTION_LINE_NUMBER2 ||'|'||aila_Cur.AIL_INVOICE_ID3 ||'|'||aila_Cur.AIL_DISTRIBUTION_LINE_NUMBER3 ||'|'||aila_Cur.AIL_INVOICE_ID4 ||'|'||aila_Cur.PAY_AWT_GROUP_ID;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for AP_INVOICE_LINES_ALL = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for AP_INVOICE_LINES_ALL');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in AP_INVOICE_LINES_ALL =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END extract_ap_invoice_lines_all;
-- +===============  Extract # 32  ====================================================================+
PROCEDURE Extract_mtl_system_items_b(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_mtl_system_items_b.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    P_CUTOFF_DATE VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_mtl_system_items_b                                                     |
  -- | Description      : This procedure is used to extract mtl_system_items_b                             |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  LT_FILE    := UTL_FILE.FOPEN(GC_FILE_PATH,LC_FILENAME ,'w',LN_BUFFER);
  L_DATA     := 'INVENTORY_ITEM_ID' ||'|'||'SEGMENT1' ||'|'||'DESCRIPTION' ||'|'||'PRIMARY_UOM_CODE' ||'|'||'ENABLED_FLAG' ||'|'||'START_DATE_ACTIVE' ||'|'||'END_DATE_ACTIVE' ||'|'||'PURCHASING_ITEM_FLAG' ||'|'||'PURCHASING_ENABLED_FLAG' ||'|'||'RETURNABLE_FLAG' ||'|'||'RECEIPT_REQUIRED_FLAG' ||'|'||'SERVICE_ITEM_FLAG' ||'|'||'INVENTORY_ITEM_FLAG' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF LD_START_DATE IS NOT NULL AND LD_END_DATE IS NOT NULL THEN
    FOR MTL_CUR IN
    (SELECT MSI.INVENTORY_ITEM_ID,
      MSI.SEGMENT1,
      MSI.DESCRIPTION,
      MSI.PRIMARY_UOM_CODE,
      MSI.ENABLED_FLAG,
      MSI.START_DATE_ACTIVE,
      MSI.END_DATE_ACTIVE,
      MSI.PURCHASING_ITEM_FLAG,
      MSI.PURCHASING_ENABLED_FLAG,
      MSI.RETURNABLE_FLAG,
      MSI.RECEIPT_REQUIRED_FLAG,
      MSI.SERVICE_ITEM_FLAG,
      MSI.INVENTORY_ITEM_FLAG
    FROM MTL_SYSTEM_ITEMS_B MSI
    WHERE msi.organization_id = 441
    AND (TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date)
    )
    LOOP
      l_data:= mtl_Cur.INVENTORY_ITEM_ID ||'|'||mtl_Cur.SEGMENT1 ||'|'||mtl_Cur.DESCRIPTION ||'|'||mtl_Cur.PRIMARY_UOM_CODE ||'|'||mtl_Cur.ENABLED_FLAG ||'|'||mtl_Cur.START_DATE_ACTIVE ||'|'||mtl_Cur.END_DATE_ACTIVE ||'|'||mtl_Cur.PURCHASING_ITEM_FLAG ||'|'||mtl_Cur.PURCHASING_ENABLED_FLAG ||'|'||mtl_Cur.RETURNABLE_FLAG ||'|'||mtl_Cur.RECEIPT_REQUIRED_FLAG ||'|'||mtl_Cur.SERVICE_ITEM_FLAG ||'|'||MTL_CUR.INVENTORY_ITEM_FLAG;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for mtl_system_items_b = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for mtl_system_items_b');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in mtl_system_items_b =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END extract_mtl_system_items_b;
-- +===============  Extract # 33  ====================================================================+
PROCEDURE Extract_xx_ap_rtv_hdr_attr(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_xx_ap_rtv_hdr_attr.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_xx_ap_rtv_hdr_attr                                                     |
  -- | Description      : This procedure is used to extract data for xx_ap_rtv_hdr_attr                              |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     := 'HEADER_ID' ||'|'||'RECORD_TYPE' ||'|'||'RTV_NUMBER' ||'|'||'VOUCHER_NUM' ||'|'||'LOCATION' ||'|'||'FREIGHT_BILL_NUM1' ||'|'||'FREIGHT_BILL_NUM2' ||'|'||'FREIGHT_BILL_NUM3' ||'|'||'FREIGHT_BILL_NUM4' ||'|'||'FREIGHT_BILL_NUM5' ||'|'||'FREIGHT_BILL_NUM6' ||'|'||'FREIGHT_BILL_NUM7' ||'|'||'FREIGHT_BILL_NUM8' ||'|'||'FREIGHT_BILL_NUM9' ||'|'||'FREIGHT_BILL_NUM10' ||'|'||'CARRIER_NAME' ||'|'||'COMPANY_ADDRESS' ||'|'||'VENDOR_ADDRESS' ||'|'||'RETURN_CODE' ||'|'||'RETURN_DESCRIPTION' ||'|'||'SHIP_NAME' ||'|'||'SHIP_ADDRESS1' ||'|'||'SHIP_ADDRESS2' ||'|'||'SHIP_ADDRESS3' ||'|'||'SHIP_ADDRESS4' ||'|'||'SHIP_ADDRESS5' ||'|'||'LOCATION_ADDRESS1' ||'|'||'LOCATION_ADDRESS2' ||'|'||'LOCATION_ADDRESS3' ||'|'||'LOCATION_ADDRESS4' ||'|'||'LOCATION_ADDRESS5' ||'|'||'LOCATION_ADDRESS6' ||'|'||'GROUP_NAME' ||'|'||'COMPANY_CODE' ||'|'||'VENDOR_NUM' ||'|'||'GROSS_AMT' ||'|'||'QUANTITY' ||'|'||'RECORD_STATUS' ||'|'||'ERROR_DESCRIPTION' ||'|'||'REQUEST_ID' ||'|'||'CREATION_DATE' ||'|'||
  'CREATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'TERMS_ID' ||'|'||'PAY_GROUP_LOOKUP_CODE' ||'|'||'PAYMENT_METHOD_LOOKUP_CODE' ||'|'||'SUPPLIER_ATTR_CATEGORY' ||'|'||'VENDOR_SITES_KFF_ID' ||'|'||'FREQUENCY_CODE' ||'|'||'INVOICE_NUM' ||'|'||'REASON_CODE';
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR rtv_Cur IN
    (SELECT HEADER_ID,
      RECORD_TYPE,
      RTV_NUMBER,
      VOUCHER_NUM,
      LOCATION,
      FREIGHT_BILL_NUM1,
      FREIGHT_BILL_NUM2,
      FREIGHT_BILL_NUM3,
      FREIGHT_BILL_NUM4,
      FREIGHT_BILL_NUM5,
      FREIGHT_BILL_NUM6,
      FREIGHT_BILL_NUM7,
      FREIGHT_BILL_NUM8,
      FREIGHT_BILL_NUM9,
      FREIGHT_BILL_NUM10,
      CARRIER_NAME,
      COMPANY_ADDRESS,
      VENDOR_ADDRESS,
      RETURN_CODE,
      RETURN_DESCRIPTION,
      SHIP_NAME,
      SHIP_ADDRESS1,
      SHIP_ADDRESS2,
      SHIP_ADDRESS3,
      SHIP_ADDRESS4,
      SHIP_ADDRESS5,
      LOCATION_ADDRESS1,
      LOCATION_ADDRESS2,
      LOCATION_ADDRESS3,
      LOCATION_ADDRESS4,
      LOCATION_ADDRESS5,
      LOCATION_ADDRESS6,
      GROUP_NAME,
      COMPANY_CODE,
      VENDOR_NUM,
      GROSS_AMT,
      QUANTITY,
      RECORD_STATUS,
      ERROR_DESCRIPTION,
      REQUEST_ID,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      LAST_UPDATE_LOGIN,
      TERMS_ID,
      PAY_GROUP_LOOKUP_CODE,
      PAYMENT_METHOD_LOOKUP_CODE,
      SUPPLIER_ATTR_CATEGORY,
      VENDOR_SITES_KFF_ID,
      FREQUENCY_CODE,
      INVOICE_NUM,
	  REASON_CODE
    FROM xx_ap_rtv_hdr_attr
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      l_data:= rtv_cur.HEADER_ID ||'|'||rtv_cur.RECORD_TYPE ||'|'||rtv_cur.RTV_NUMBER ||'|'||rtv_cur.VOUCHER_NUM ||'|'||rtv_cur.LOCATION ||'|'||rtv_cur.FREIGHT_BILL_NUM1 ||'|'||rtv_cur.FREIGHT_BILL_NUM2 ||'|'||rtv_cur.FREIGHT_BILL_NUM3 ||'|'||rtv_cur.FREIGHT_BILL_NUM4 ||'|'||rtv_cur.FREIGHT_BILL_NUM5 ||'|'||rtv_cur.FREIGHT_BILL_NUM6 ||'|'||rtv_cur.FREIGHT_BILL_NUM7 ||'|'||rtv_cur.FREIGHT_BILL_NUM8 ||'|'||rtv_cur.FREIGHT_BILL_NUM9 ||'|'||rtv_cur.FREIGHT_BILL_NUM10 ||'|'||rtv_cur.CARRIER_NAME ||'|'||rtv_cur.COMPANY_ADDRESS ||'|'||rtv_cur.VENDOR_ADDRESS ||'|'||rtv_cur.RETURN_CODE ||'|'||rtv_cur.RETURN_DESCRIPTION ||'|'||rtv_cur.SHIP_NAME ||'|'||rtv_cur.SHIP_ADDRESS1 ||'|'||rtv_cur.SHIP_ADDRESS2 ||'|'||rtv_cur.SHIP_ADDRESS3 ||'|'||rtv_cur.SHIP_ADDRESS4 ||'|'||rtv_cur.SHIP_ADDRESS5 ||'|'||rtv_cur.LOCATION_ADDRESS1 ||'|'||rtv_cur.LOCATION_ADDRESS2 ||'|'||rtv_cur.LOCATION_ADDRESS3 ||'|'||rtv_cur.LOCATION_ADDRESS4 ||'|'||rtv_cur.LOCATION_ADDRESS5 ||'|'||rtv_cur.LOCATION_ADDRESS6 ||'|'||
      rtv_cur.GROUP_NAME ||'|'||rtv_cur.COMPANY_CODE ||'|'||rtv_cur.VENDOR_NUM ||'|'||rtv_cur.GROSS_AMT ||'|'||rtv_cur.QUANTITY ||'|'||rtv_cur.RECORD_STATUS ||'|'||rtv_cur.ERROR_DESCRIPTION ||'|'||rtv_cur.REQUEST_ID ||'|'||rtv_cur.CREATION_DATE ||'|'||rtv_cur.CREATED_BY ||'|'||rtv_cur.LAST_UPDATE_DATE ||'|'||rtv_cur.LAST_UPDATED_BY ||'|'||rtv_cur.LAST_UPDATE_LOGIN ||'|'||rtv_cur.TERMS_ID ||'|'||rtv_cur.PAY_GROUP_LOOKUP_CODE ||'|'||rtv_cur.PAYMENT_METHOD_LOOKUP_CODE ||'|'||rtv_cur.SUPPLIER_ATTR_CATEGORY ||'|'||rtv_cur.VENDOR_SITES_KFF_ID ||'|'||rtv_cur.FREQUENCY_CODE ||'|'||rtv_cur.INVOICE_NUM ||'|'||rtv_cur.REASON_CODE;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for xx_ap_rtv_hdr_attr = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for xx_ap_rtv_hdr_attr');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in xx_ap_rtv_hdr_attr =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END extract_xx_ap_rtv_hdr_attr;
--===================================================================================================+
-- +===============  Extract # 34  ====================================================================+
PROCEDURE Extract_xx_ap_rtv_lines_attr(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory   VARCHAR2 ,
    p_file_name   VARCHAR2 := 'OD_AP_PRG_xx_ap_rtv_lines_attr.txt' ,
    p_debug_flag  VARCHAR2 ,
    p_file_path   VARCHAR2 ,
    p_cutoff_date VARCHAR2 ,
    p_no_of_days  VARCHAR2)
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  Extract_xx_ap_rtv_lines_attr                                                     |
  -- | Description      : This procedure is used to extract data for  xx_ap_rtv_lines_attr                              |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
  l_data      VARCHAR2(4000);
  l_out_cnt   NUMBER;
  lc_filename VARCHAR2(4000);
  ln_req_id   NUMBER;
  ln_buffer BINARY_INTEGER := 32767;
  lt_file utl_file.file_type;
  ld_start_date DATE;
  ld_end_date   DATE;
BEGIN
  -------------  get previous period name ---------------------
  get_cutoff_date(p_cutoff_date ,p_no_of_days ,ld_start_date ,ld_end_date ,p_debug_flag);
  --------------  get previous period name ---------------------
  gc_file_path := p_file_path;
  write_log(p_debug_flag,' ');
  ln_req_id  := fnd_profile.value('CONC_REQUEST_ID');
  lc_filename:= ln_req_id||'.out';
  lt_file    := UTL_FILE.fopen(gc_file_path,lc_filename ,'w',ln_buffer);
  l_data     := 'LINE_ID' ||'|'||'HEADER_ID' ||'|'||'RECORD_TYPE' ||'|'||'RTV_NUMBER' ||'|'||'WORKSHEET_NUM' ||'|'||'RGA_NUMBER' ||'|'||'SKU' ||'|'||'VENDOR_PRODUCT_CODE' ||'|'||'ITEM_DESCRIPTION' ||'|'||'SERIAL_NUM' ||'|'||'QTY' ||'|'||'COST' ||'|'||'LINE_AMOUNT' ||'|'||'GROUP_NAME' ||'|'||'COMPANY' ||'|'||'VENDOR_NUM' ||'|'||'RECORD_STATUS' ||'|'||'ERROR_DESCRIPTION' ||'|'||'REQUEST_ID' ||'|'||'CREATION_DATE' ||'|'||'CREATED_BY' ||'|'||'LAST_UPDATE_DATE' ||'|'||'LAST_UPDATED_BY' ||'|'||'LAST_UPDATE_LOGIN' ||'|'||'FREQUENCY_CODE' ||'|'||'LOCATION' ||'|'||'INVOICE_NUM' ||'|'||'RTV_DATE' ||'|'||'ADJUSTED_QTY' ||'|'||'ADJUSTED_COST' ||'|'||'ADJUSTED_LINE_AMOUNT' ;
  UTL_FILE.PUT_LINE(lt_file,l_data);
  l_out_cnt        := 1;
  IF ld_start_date IS NOT NULL AND ld_end_date IS NOT NULL THEN
    FOR rtv_Cur_line IN
    (SELECT LINE_ID,
      HEADER_ID,
      RECORD_TYPE,
      RTV_NUMBER,
      WORKSHEET_NUM,
      RGA_NUMBER,
      SKU,
      VENDOR_PRODUCT_CODE,
      ITEM_DESCRIPTION,
      SERIAL_NUM,
      QTY,
      COST,
      LINE_AMOUNT,
      GROUP_NAME,
      COMPANY,
      VENDOR_NUM,
      RECORD_STATUS,
      ERROR_DESCRIPTION,
      REQUEST_ID,
      CREATION_DATE,
      CREATED_BY,
      LAST_UPDATE_DATE,
      LAST_UPDATED_BY,
      LAST_UPDATE_LOGIN,
      FREQUENCY_CODE,
      LOCATION,
      INVOICE_NUM,
      RTV_DATE,
      ADJUSTED_QTY,
      ADJUSTED_COST,
      adjusted_line_amount
    FROM xx_ap_rtv_lines_attr
    WHERE TRUNC(last_update_date) BETWEEN ld_start_date AND ld_end_date
    OR TRUNC(creation_date) BETWEEN ld_start_date AND ld_end_date
    )
    LOOP
      L_DATA:= RTV_CUR_LINE.LINE_ID ||'|'||RTV_CUR_LINE.HEADER_ID ||'|'||RTV_CUR_LINE.RECORD_TYPE ||'|'||RTV_CUR_LINE.RTV_NUMBER ||'|'||
      RTV_CUR_LINE.WORKSHEET_NUM ||'|'||RTV_CUR_LINE.RGA_NUMBER ||'|'||RTV_CUR_LINE.SKU ||'|'||RTV_CUR_LINE.VENDOR_PRODUCT_CODE ||'|'||
      rtv_Cur_line.ITEM_DESCRIPTION ||'|'||rtv_Cur_line.SERIAL_NUM||'|'||rtv_Cur_line.QTY ||'|'||rtv_Cur_line.COST ||'|'||rtv_Cur_line.LINE_AMOUNT ||'|'||rtv_Cur_line.GROUP_NAME ||'|'||rtv_Cur_line.COMPANY ||'|'||rtv_Cur_line.VENDOR_NUM ||'|'||rtv_Cur_line.RECORD_STATUS ||'|'||rtv_Cur_line.ERROR_DESCRIPTION ||'|'||rtv_Cur_line.REQUEST_ID ||'|'||rtv_Cur_line.CREATION_DATE ||'|'||rtv_Cur_line.CREATED_BY ||'|'||rtv_Cur_line.LAST_UPDATE_DATE ||'|'||rtv_Cur_line.LAST_UPDATED_BY ||'|'||rtv_Cur_line.LAST_UPDATE_LOGIN ||'|'||rtv_Cur_line.FREQUENCY_CODE ||'|'||rtv_Cur_line.LOCATION ||'|'||rtv_Cur_line.INVOICE_NUM ||'|'||rtv_Cur_line.RTV_DATE ||'|'||rtv_Cur_line.ADJUSTED_QTY ||'|'||rtv_Cur_line.ADJUSTED_COST ||'|'||
      rtv_Cur_line.ADJUSTED_LINE_AMOUNT;
      replace_control_char(l_data);
      UTL_FILE.PUT_LINE(lt_file,l_data);
      l_out_cnt := l_out_cnt + 1;
    END LOOP;
    l_out_cnt := l_out_cnt + 1;
    l_data    :='total record count in this file for xx_ap_rtv_lines_attr = '||l_out_cnt||'|';
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    generate_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    write_log(p_debug_flag,l_out_cnt||' Total Records Written for xx_ap_rtv_lines_attr');
    write_log(p_debug_flag,'----------------------------------------------------');
    ---  **************************************************
    lt_file := UTL_FILE.fopen(gc_file_path,'OD_AP_PRG_SUM_WRK.txt'||'_'||TO_CHAR(SYSDATE,'YYYYMMDD'),'a',ln_buffer);
    l_data  :='total record count in xx_ap_rtv_lines_attr =|'||l_out_cnt||'|'||ld_start_date|| ' thru '||ld_end_date||'|request date=|'||TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS')||'|request id=|'||ln_req_id;
    UTL_FILE.PUT_LINE(lt_file,l_data);
    UTL_FILE.fclose(lt_file);
    gen_sumry_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
    ---  **************************************************
  END IF;
END extract_xx_ap_rtv_lines_attr;
-- +===============  Zipping files  =================================================================+
PROCEDURE zipping_files(
    p_ret_code OUT NUMBER ,
    p_err_msg OUT VARCHAR2 ,
    p_directory  IN VARCHAR2 ,
    p_file_name  IN VARCHAR2 ,
    p_debug_flag IN VARCHAR2 ,
    p_file_path  IN VARCHAR2 )
  -- +===================================================================================================+
  --
  -- |                  Office Depot - Project Simplify                                                  |
  -- |                  IT OfficeDepot                                                                   |
  -- +===================================================================================================+
  -- | Name             :  zipping files                                                        |
  -- | Description      : This procedure is used to zip files                                            |
  -- |                                                                                                   |
  -- |Change Record:                                                                                     |
  -- |===============                                                                                    |
  -- |Version   Date         Author            Remarks                                                  |
  -- |=======   ==========   =============    ==========================================================|
AS
BEGIN
  zip_file(p_directory,p_file_name,fnd_profile.value('CONC_REQUEST_ID'));
END zipping_files;
-- +===================================================================================================+
END XX_AP_PRG_AUDIT_EXTRACT_PKG;

/