create or replace 
PACKAGE BODY XXCRM_FILE_UPLOADS_CMN_PKG
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- +==========================================================================+
-- | Name             :  XXCRM_FILE_UPLOADS_CMN_PKG                           |
-- | Description      :  This package is used to upload data from             |
-- |                     a .csv file into a staging table and call a          |
-- |                     function which will validate the data and            |
-- |                     insert it into appropriate tables.                   |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author              Remarks                          |
-- |=======  ==========  ==================  =================================|
-- |1.0      20-FEB-2008 Shabbar Hasan       Created the package body         |
-- |                     Wipro Technologies                                   |
-- |2.0      20-JUN-2008 Mohan Kalyanasundaram Changed the place of           |
-- |                     of select for the error lob so the lob txn           |
-- |                     does not report error while the outside              |
-- |                     function commits within a loop.                      |
-- |3.0      25-MAY-2010 Mangalasundari K  CR769 Changed the Pacakge          |
-- |                     such that  it supports the upload of any kind        |
-- |                     of template and there is a generation of both        |
-- |                     Error file and Output File.   .                      |
-- |4.0      08-NOV-2010 Devi Viswanathan     Fix for defect# 8519            |
-- |5.0      18-JAN-2011 Devi Viswanathan     Fix for defect# 9592            |
-- |6.0      27-JAN-2010 Srini                Adding Pre and Post processing  |
-- |                                          logic (CR# 864).                |
-- |7.0      18-Feb-2011 Satish Silveri       Fix for defect# 9592            |
-- |8.0      7-Jun-2016  Shubashree R      QC38032 Removed schema references for R12.2 GSCC compliance|
-- |9.0      04-OCT-2016 Shubhashree R     Modified the pkg to move it from  |
-- |                                        XXTPS to XXCRM                    |
-- |10.0     08-Nov-2016 Shubhashree R     Fixed the error ORA-06502 QC 39888 |
-- +==========================================================================+
AS
FUNCTION SPLIT_CSV (
                   p_string      VARCHAR2
                   )
RETURN gt_tbltyp_strings
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  SPLIT_CSV                                     |
-- | Description      :  This function is used to split the .csv file  |
-- |                     row by row. It takes one row at a time and    |
-- |                     splits it into different tokens and returns   |
-- |                     all the tokens.                               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      20-FEB-2008 Shabbar Hasan       Initial version           |
-- |                     Wipro Technologies                            |
-- +===================================================================+
IS
  lc_str_token    VARCHAR2(32000);
  -- Defect 9592 Begin
  --lc_str_char     VARCHAR2(1);
  lc_str_char     VARCHAR2(32000);
  -- Defect 9592 End
  ln_table_pos    PLS_INTEGER := 1;
  ln_idx          NUMBER      := 1;
  lb_open_quote   BOOLEAN     := FALSE;
  lc_tokens       gt_tbltyp_strings;
BEGIN
  IF p_string IS NULL THEN
    RETURN lc_tokens;
  END IF;
  IF INSTR(p_string, ',',1) = 0 THEN
    lc_tokens(ln_table_pos) := p_string;
    RETURN(lc_tokens);
  END IF;
  WHILE ln_idx <= length(p_string)
  LOOP
    lc_str_char := SUBSTR(p_string, ln_idx, 1);
    CASE lc_str_char
    WHEN '"' THEN
      IF lb_open_quote = FALSE THEN
        lb_open_quote := TRUE;
      ELSIF SUBSTR(p_string, ln_idx+1,1) = '"' THEN
        lc_str_token := lc_str_token || '"';
        ln_idx := ln_idx + 1;
      ELSIF lb_open_quote = TRUE THEN
        lb_open_quote := FALSE;
      END IF;
    WHEN ',' THEN
      IF lb_open_quote = TRUE THEN
        lc_str_token := lc_str_token || ',';
      ELSE
        lc_tokens(ln_table_pos) := lc_str_token;
        lc_str_token := '';
        ln_table_pos := ln_table_pos + 1;
      END IF;
    ELSE
      lc_str_token := lc_str_token || lc_str_char;
    END CASE;
    ln_idx := ln_idx + 1;
  END LOOP;
  IF LENGTH(lc_str_token) != 0 OR SUBSTR(p_string,-1,1) = ',' THEN
    lc_tokens(ln_table_pos) := lc_str_token;
  END IF;
  RETURN lc_tokens;
END SPLIT_CSV;

PROCEDURE XXCRM_INITIATE_FILE_UPLOAD (x_request_id       OUT NUMBER
                                      ,p_file_upload_id  IN  NUMBER
                                     )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XXCRM_INITIATE_FILE_UPLOAD                    |
-- | Description      :  This procedure is called from the front end   |
-- |                     when the action of loading data is taken.     |
-- |                     This procedure will then submit a concurrent  |
-- |                     request which will upload the data from the   |
-- |                     the .csv file to the base tables.             |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      25-FEB-2008 Shabbar Hasan       Initial version           |
-- |                     Wipro Technologies                            |
-- |2.0      25-MAY-2010 Mangalasundari K                              |
-- |                     Wipro Technologies                            |
-- |                         CR769 Included an Out Paramter Request Id |
-- |                               in the Procedure                    |
-- +===================================================================+
AS
  ln_req_id NUMBER;
BEGIN
  ln_req_id := FND_REQUEST.SUBMIT_REQUEST(
                   application => 'XXCRM'             -- CR769
                   ,program    => 'XXCRM_FILE_UPLOAD' -- CR769
                   ,start_time => sysdate
                   ,sub_request => false
                   ,argument1  => p_file_upload_id );
   COMMIT;
  IF ln_req_id = 0 THEN
    UPDATE XXCRM_file_uploads
    SET    error_file_data = TO_CLOB('Request failed' || chr(10))
           ,file_status = 'E'
           ,last_updated_by = -1
           ,last_update_date = SYSDATE
    WHERE  file_upload_id = p_file_upload_id;
  ELSE
    UPDATE XXCRM_file_uploads
    SET    request_id = ln_req_id
    WHERE  file_upload_id = p_file_upload_id;
  END IF;
  COMMIT;
  x_request_id := ln_req_id ;
EXCEPTION
WHEN OTHERS THEN
  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Unexpected Error: ' || SQLERRM);
END XXCRM_INITIATE_FILE_UPLOAD;

PROCEDURE XXCRM_FILE_UPLOAD (
                             x_error_code      OUT NOCOPY NUMBER
                            ,x_error_buf       OUT NOCOPY VARCHAR2
                            ,p_file_upload_id  IN  NUMBER
                            )
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name             :  XXCRM_FILE_UPLOAD                             |
-- | Description      :  This procedure reads data from a .csv file    |
-- |                     and inserts the data into a staging table.    |
-- |                     Then, it calls a function with the required   |
-- |                     parameters. The function validates the data   |
-- |                     and inserts it into the base table. Invalid   |
-- |                     data alongwith the error messages are copied  |
-- |                     into an error file.                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version  Date        Author              Remarks                   |
-- |=======  ==========  ==================  ==========================|
-- |1.0      20-FEB-2008 Shabbar Hasan       Initial version           |
-- |                     Wipro Technologies                            |
-- +===================================================================+
AS
  EX_NO_FILE            EXCEPTION;
  EX_NO_TEMPLATE        EXCEPTION;
  EX_STAGING_INSERT     EXCEPTION;
  EX_NO_DATA            EXCEPTION; -- CR 769
  ln_file_pos           NUMBER;
  ln_file_length        NUMBER;
  lc_current_row        VARCHAR2(4000);
  lc_insert_str1        VARCHAR2(300);
  lc_insert_str2        VARCHAR2(32000);
  lc_insert_str3        VARCHAR2(300);
  lc_insert_str4        VARCHAR2(32000);
  ln_attr_pos           NUMBER := 1;
  j                     NUMBER := 1;
  lc_function_str       VARCHAR2(32000);
  lc_error_str          VARCHAR2(32000);
  lc_error_row          VARCHAR2(32000);
  lc_error_clob         CLOB;
  lc_clob_code          XXCRM_file_uploads.clob_code%TYPE;
  lc_attributes         XXCRM_template_file_uploads.attributes%TYPE;
  lc_func_name          XXCRM_template_file_uploads.statement%TYPE;
  lt_tab_tokens         gt_tbltyp_strings;
  lt_template_attr      gt_tbltyp_strings;
  lt_attr_values        gt_tbltyp_strings;
  lc_sql_stmt           VARCHAR2(32000);
  lc_processed_rec      NUMBER := 0;
  --Following are the variable declarations for CR769

  lc_output_row         VARCHAR2(32000);
  lc_out_str            VARCHAR2(32000);
  lc_out_clob           CLOB ;
  ln_success_cnt        NUMBER := 0;
  ln_error_cnt          NUMBER := 0;
 -- lc_attr_header  VARCHAR2(32000);
  lc_out_addnl_header   VARCHAR2(32000);
  lc_error_addnl_header VARCHAR2(32000);
  lc_stage_rec_cnt      NUMBER;
   /* Fix for defect# 8519 - Begin*/ 
  lc_last_char          VARCHAR2(10);  
  lc_eol                VARCHAR2(10);   
 lc_single             VARCHAR2(20) := '''';   
  /* Fix for defect# 8519 - End*/ 
  
  -- Added below variables for CR# 864 (V: 6).
  lc_pre_processing_function  XXCRM_template_file_uploads.pre_processing_function%TYPE;
  lc_post_processing_function XXCRM_template_file_uploads.post_processing_function%TYPE;
  EX_PRE_PROCESSING           EXCEPTION;
  EX_POST_PROCESSING          EXCEPTION;

  
  CURSOR lcu_staging_data
  IS
  SELECT *
  FROM   XXCRM_staging_file_uploads
  WHERE  file_upload_id = p_file_upload_id;
BEGIN
  BEGIN
    SELECT DBMS_LOB.GETLENGTH(file_data)
           ,clob_code
    INTO   ln_file_length
           ,lc_clob_code
    FROM   XXCRM_file_uploads
    WHERE  file_upload_id = p_file_upload_id;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE EX_NO_FILE; --File Upload ID Does not exist
  END;
  
  /* Fix for defect# 8519*/
  
  SELECT DBMS_LOB.SUBSTR(file_data, 1, ln_file_length) 
    INTO lc_last_char
    FROM XXCRM_file_uploads
   WHERE file_upload_id = p_file_upload_id; 
   
  SELECT CHR(10) 
    INTO lc_eol 
    FROM dual;       
             
  IF NOT lc_last_char = lc_eol THEN 
      
    UPDATE XXCRM_file_uploads 
       SET file_data = file_data || chr(10)
     WHERE file_upload_id = p_file_upload_id; 
        
  END IF;   
  
  /* End of fix for defect# 8519*/
  
  BEGIN
     
    fnd_file.PUT_LINE(fnd_file.LOG, 'BEGIN Program');
  
    SELECT   attributes
           , statement
           --, replace(attributes,'''',null)
           , replace(out_additional_col,'''',null)-- CR769
           , replace(error_additional_col,'''',null)-- CR769
           , pre_processing_function
           , post_processing_function
    INTO   lc_attributes
           ,lc_func_name
         --  ,lc_attr_header
           ,lc_out_addnl_header
           ,lc_error_addnl_header
           ,lc_pre_processing_function
           ,lc_post_processing_function
    FROM   XXCRM_template_file_uploads
    WHERE  template_code = lc_clob_code;
    
    fnd_file.PUT_LINE(fnd_file.LOG, 'Step 1 Get template header and other stuff');
    
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE EX_NO_TEMPLATE; --Template Code Not Found
  END;
  
  SELECT DBMS_LOB.INSTR(file_data, chr(10),1) + 1
  INTO   ln_file_pos
  FROM   XXCRM_file_uploads
  WHERE  file_upload_id = p_file_upload_id;
  
  fnd_file.PUT_LINE(fnd_file.LOG, 'Step 2');
  
  WHILE (ln_file_pos < ln_file_length)
  LOOP
   
    SELECT DBMS_LOB.SUBSTR(file_data,
                           DBMS_LOB.INSTR(file_data, chr(10), ln_file_pos,1) - ln_file_pos -1,
                           ln_file_pos)
    INTO   lc_current_row
    FROM   XXCRM_file_uploads
    WHERE  file_upload_id = p_file_upload_id;
    
    fnd_file.PUT_LINE(fnd_file.LOG, 'Step 3 Inside the loop - Got current row');
    
    lt_tab_tokens := SPLIT_CSV(lc_current_row);
    lc_insert_str1 := '';
    lc_insert_str2 := '';
    lc_insert_str3 := '';
    lc_insert_str4 := '';
    IF lt_tab_tokens.count > 0 THEN
      lc_insert_str1 := 'INSERT INTO XXCRM_staging_file_uploads (staging_file_upload_id,'
                                                              || 'file_upload_id,'
                                                              || 'program,'
                                                              || 'created_by,'
                                                              || 'creation_date,'
                                                              || 'last_updated_by,'
                                                              || 'last_update_date,'
                                                              || 'attribute1';

      FOR i IN 2 .. lt_tab_tokens.count
      LOOP
        lc_insert_str2 := lc_insert_str2 || ',attribute' || i;
      END LOOP;
      lc_insert_str2 := lc_insert_str2 || ') ';
    END IF;
    IF lt_tab_tokens.count > 0 THEN
      /*Modified for Defect 8519*/
      lc_insert_str3 := 'VALUES (XXCRM_staging_file_upload_id_s.NEXTVAL, '
                              || p_file_upload_id
                              || ', ''XXCRM_file_uploads_pkg.file_upload'', '
                              || '-1, '
                              || 'SYSDATE, '
                              || '-1, '
                              || 'SYSDATE, '
                       -- Defect 9592 Begin
                       --     || '''' || replace( lt_tab_tokens(1) ,lc_single,'')  || '''';                                                            
                       --     || '''' || replace(trim( replace( lt_tab_tokens(1) ,lc_single,'')),' ','')  || '''';
			      || '''' || trim( replace( lt_tab_tokens(1) ,lc_single,lc_single||lc_single)) || '''';
                       -- Defect 9592 End
                       --       || '''' ||  lt_tab_tokens(1) || '''';
       
      FOR i IN 2 .. lt_tab_tokens.count
      LOOP
      
       -- lc_insert_str4 := lc_insert_str4 || ',' || '''' || lt_tab_tokens(i) || ''''; 
       -- Defect 9592 Begin
      --  lc_insert_str4 := lc_insert_str4 || ',' || '''' || replace(lt_tab_tokens(i),lc_single,'') || '''';  
      --  lc_insert_str4 := lc_insert_str4 || ',' || '''' || replace(trim( replace( lt_tab_tokens(i) ,lc_single,'')),' ','') || '''';  
          lc_insert_str4 := lc_insert_str4 || ',' || '''' || trim( replace( lt_tab_tokens(i) ,lc_single,lc_single||lc_single)) || '''';
       -- Defect 9592 End 
       /*Modified for Defect 8519*/        
      END LOOP;
      lc_insert_str4 := lc_insert_str4 || ') ';
    END IF;
    BEGIN
      lc_sql_stmt := lc_insert_str1 || lc_insert_str2 || lc_insert_str3 || lc_insert_str4;
     EXECUTE IMMEDIATE (lc_insert_str1 || lc_insert_str2 || lc_insert_str3 || lc_insert_str4);
     
     fnd_file.PUT_LINE(fnd_file.LOG, 'Step 4 After inserting records into staging table');
     
    EXCEPTION
    WHEN OTHERS THEN
      lc_sql_stmt := lc_sql_stmt ||'  Error: '||SQLERRM;  
      RAISE EX_STAGING_INSERT;          
    END;
    ln_file_pos := ln_file_pos + LENGTH(lc_current_row) + 2;
  END LOOP;
  COMMIT;
  j := 1;
  ln_attr_pos := INSTR(lc_attributes,'''') + 1;
  WHILE (ln_attr_pos != 1)
  LOOP
    lt_template_attr(j) := SUBSTR(lc_attributes
                                 ,ln_attr_pos
                                 ,INSTR(lc_attributes,'''',ln_attr_pos) - ln_attr_pos
                                );
    ln_attr_pos := INSTR(lc_attributes, '''', ln_attr_pos,2) + 1;
    j := j+1;
  END LOOP;
  IF lt_template_attr.COUNT > 0 THEN
    lc_processed_rec := 0;
    lc_error_clob    :=NULL;
    lc_out_clob      :=NULL;

    SELECT count(1)
    INTO lc_stage_rec_cnt
    FROM   XXCRM_staging_file_uploads
    WHERE  file_upload_id = p_file_upload_id;
      IF lc_stage_rec_cnt =0  THEN -- Empty Input File
        RAISE EX_NO_DATA;
      END IF;

      -- Added below block for CR# 864 (V: 6).
      -- ----------------------------------------------------------------------
      -- Below Block is for Pre Processing function.
      -- Will execute the function which is mentioned in XXCRM_template_file_uploads table.
      -- ----------------------------------------------------------------------

      BEGIN
        IF lc_pre_processing_function IS NOT NULL
        THEN

          fnd_file.PUT_LINE(fnd_file.LOG, ' ----->>> Processing pre processing function.'
                                       || ' Function Command: BEGIN ' 
                                       || ':1 := ' || lc_pre_processing_function || '; END;');
                                         
          EXECUTE IMMEDIATE 'BEGIN ' || ':1 := ' || lc_pre_processing_function || '; END;'
          USING IN OUT lc_error_str;
      
          IF INSTR(lc_error_str, 'FALSE_') = 1 THEN
             fnd_file.PUT_LINE(fnd_file.LOG,lc_error_str);
             RAISE EX_PRE_PROCESSING;

          ELSE
             lc_error_str := '';
        
          END IF;
          fnd_file.PUT_LINE(fnd_file.LOG,'After calling the preprocessing procedure');
        END IF;
        
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_str := 'FALSE_' || 'Error while processing pre processing function: ' || SQLERRM;
        fnd_file.PUT_LINE(fnd_file.LOG,lc_error_str);
        RAISE EX_PRE_PROCESSING;
      END;
      
      fnd_file.PUT_LINE(fnd_file.LOG,'Step 6; Before the for loop');
      
    FOR l_staging_rec IN lcu_staging_data
    LOOP
      lc_processed_rec := lc_processed_rec + 1;
      lt_attr_values(1) := l_staging_rec.attribute1;
      lt_attr_values(2) := l_staging_rec.attribute2;
      lt_attr_values(3) := l_staging_rec.attribute3;
      lt_attr_values(4) := l_staging_rec.attribute4;
      lt_attr_values(5) := l_staging_rec.attribute5;
      lt_attr_values(6) := l_staging_rec.attribute6;
      lt_attr_values(7) := l_staging_rec.attribute7;
      lt_attr_values(8) := l_staging_rec.attribute8;
      lt_attr_values(9) := l_staging_rec.attribute9;
      lt_attr_values(10) := l_staging_rec.attribute10;
      lt_attr_values(11) := l_staging_rec.attribute11;
      lt_attr_values(12) := l_staging_rec.attribute12;
      lt_attr_values(13) := l_staging_rec.attribute13;
      lt_attr_values(14) := l_staging_rec.attribute14;
      lt_attr_values(15) := l_staging_rec.attribute15;
      lt_attr_values(16) := l_staging_rec.attribute16;
      lt_attr_values(17) := l_staging_rec.attribute17;
      lt_attr_values(18) := l_staging_rec.attribute18;
      lt_attr_values(19) := l_staging_rec.attribute19;
      lt_attr_values(20) := l_staging_rec.attribute20;
      lt_attr_values(21) := l_staging_rec.attribute21;
      lt_attr_values(22) := l_staging_rec.attribute22;
      lt_attr_values(23) := l_staging_rec.attribute23;
      lt_attr_values(24) := l_staging_rec.attribute24;
      lt_attr_values(25) := l_staging_rec.attribute25;
      lt_attr_values(26) := l_staging_rec.attribute26;
      lt_attr_values(27) := l_staging_rec.attribute27;
      lt_attr_values(28) := l_staging_rec.attribute28;
      lt_attr_values(29) := l_staging_rec.attribute29;
      lt_attr_values(30) := l_staging_rec.attribute30;
      lt_attr_values(31) := l_staging_rec.attribute31;
      lt_attr_values(32) := l_staging_rec.attribute32;
      lt_attr_values(33) := l_staging_rec.attribute33;
      lt_attr_values(34) := l_staging_rec.attribute34;
      lt_attr_values(35) := l_staging_rec.attribute35;
      lt_attr_values(36) := l_staging_rec.attribute36;
      lt_attr_values(37) := l_staging_rec.attribute37;
      lt_attr_values(38) := l_staging_rec.attribute38;
      lt_attr_values(39) := l_staging_rec.attribute39;
      lt_attr_values(40) := l_staging_rec.attribute40;
      lt_attr_values(41) := l_staging_rec.attribute41;
      lt_attr_values(42) := l_staging_rec.attribute42;
      lt_attr_values(43) := l_staging_rec.attribute43;
      lt_attr_values(44) := l_staging_rec.attribute44;
      lt_attr_values(45) := l_staging_rec.attribute45;
      lt_attr_values(46) := l_staging_rec.attribute46;
      lt_attr_values(47) := l_staging_rec.attribute47;
      lt_attr_values(48) := l_staging_rec.attribute48;
      lt_attr_values(49) := l_staging_rec.attribute49;
      lt_attr_values(50) := l_staging_rec.attribute50;
      lt_attr_values(51) := l_staging_rec.attribute51;
      lt_attr_values(52) := l_staging_rec.attribute52;
      lt_attr_values(53) := l_staging_rec.attribute53;
      lt_attr_values(54) := l_staging_rec.attribute54;
      lt_attr_values(55) := l_staging_rec.attribute55;
      lt_attr_values(56) := l_staging_rec.attribute56;
      lt_attr_values(57) := l_staging_rec.attribute57;
      lt_attr_values(58) := l_staging_rec.attribute58;
      lt_attr_values(59) := l_staging_rec.attribute59;
      lt_attr_values(60) := l_staging_rec.attribute60;
      lt_attr_values(61) := l_staging_rec.attribute61;
      lt_attr_values(62) := l_staging_rec.attribute62;
      lt_attr_values(63) := l_staging_rec.attribute63;
      lt_attr_values(64) := l_staging_rec.attribute64;
      lt_attr_values(65) := l_staging_rec.attribute65;
      lt_attr_values(66) := l_staging_rec.attribute66;
      lt_attr_values(67) := l_staging_rec.attribute67;
      lt_attr_values(68) := l_staging_rec.attribute68;
      lt_attr_values(69) := l_staging_rec.attribute69;
      lt_attr_values(70) := l_staging_rec.attribute70;
      lt_attr_values(71) := l_staging_rec.attribute71;
      lt_attr_values(72) := l_staging_rec.attribute72;
      lt_attr_values(73) := l_staging_rec.attribute73;
      lt_attr_values(74) := l_staging_rec.attribute74;
      lt_attr_values(75) := l_staging_rec.attribute75;
      lt_attr_values(76) := l_staging_rec.attribute76;
      lt_attr_values(77) := l_staging_rec.attribute77;
      lt_attr_values(78) := l_staging_rec.attribute78;
      lt_attr_values(79) := l_staging_rec.attribute79;
      lt_attr_values(80) := l_staging_rec.attribute80;
      lt_attr_values(81) := l_staging_rec.attribute81;
      lt_attr_values(82) := l_staging_rec.attribute82;
      lt_attr_values(83) := l_staging_rec.attribute83;
      lt_attr_values(84) := l_staging_rec.attribute84;
      lt_attr_values(85) := l_staging_rec.attribute85;
      lt_attr_values(86) := l_staging_rec.attribute86;
      lt_attr_values(87) := l_staging_rec.attribute87;
      lt_attr_values(88) := l_staging_rec.attribute88;
      lt_attr_values(89) := l_staging_rec.attribute89;
      lt_attr_values(90) := l_staging_rec.attribute90;
      lt_attr_values(91) := l_staging_rec.attribute91;
      lt_attr_values(92) := l_staging_rec.attribute92;
      lt_attr_values(93) := l_staging_rec.attribute93;
      lt_attr_values(94) := l_staging_rec.attribute94;
      lt_attr_values(95) := l_staging_rec.attribute95;
      lt_attr_values(96) := l_staging_rec.attribute96;
      lt_attr_values(97) := l_staging_rec.attribute97;
      lt_attr_values(98) := l_staging_rec.attribute98;
      lt_attr_values(99) := l_staging_rec.attribute99;
      lt_attr_values(100) := l_staging_rec.attribute100;
      lt_attr_values(101) := l_staging_rec.attribute101;
      lt_attr_values(102) := l_staging_rec.attribute102;
      lt_attr_values(103) := l_staging_rec.attribute103;
      lt_attr_values(104) := l_staging_rec.attribute104;
      lt_attr_values(105) := l_staging_rec.attribute105;
      lt_attr_values(106) := l_staging_rec.attribute106;
      lt_attr_values(107) := l_staging_rec.attribute107;
      lt_attr_values(108) := l_staging_rec.attribute108;
      lt_attr_values(109) := l_staging_rec.attribute109;
      lt_attr_values(110) := l_staging_rec.attribute110;
      lt_attr_values(111) := l_staging_rec.attribute111;
      lt_attr_values(112) := l_staging_rec.attribute112;
      lt_attr_values(113) := l_staging_rec.attribute113;
      lt_attr_values(114) := l_staging_rec.attribute114;
      lt_attr_values(115) := l_staging_rec.attribute115;
      lt_attr_values(116) := l_staging_rec.attribute116;
      lt_attr_values(117) := l_staging_rec.attribute117;
      lt_attr_values(118) := l_staging_rec.attribute118;
      lt_attr_values(119) := l_staging_rec.attribute119;
      lt_attr_values(120) := l_staging_rec.attribute120;
      lt_attr_values(121) := l_staging_rec.attribute121;
      lt_attr_values(122) := l_staging_rec.attribute122;
      lt_attr_values(123) := l_staging_rec.attribute123;
      lt_attr_values(124) := l_staging_rec.attribute124;
      lt_attr_values(125) := l_staging_rec.attribute125;
      lt_attr_values(126) := l_staging_rec.attribute126;
      lt_attr_values(127) := l_staging_rec.attribute127;
      lt_attr_values(128) := l_staging_rec.attribute128;
      lt_attr_values(129) := l_staging_rec.attribute129;
      lt_attr_values(130) := l_staging_rec.attribute130;
      lt_attr_values(131) := l_staging_rec.attribute131;
      lt_attr_values(132) := l_staging_rec.attribute132;
      lt_attr_values(133) := l_staging_rec.attribute133;
      lt_attr_values(134) := l_staging_rec.attribute134;
      lt_attr_values(135) := l_staging_rec.attribute135;
      lt_attr_values(136) := l_staging_rec.attribute136;
      lt_attr_values(137) := l_staging_rec.attribute137;
      lt_attr_values(138) := l_staging_rec.attribute138;
      lt_attr_values(139) := l_staging_rec.attribute139;
      lt_attr_values(140) := l_staging_rec.attribute140;
      lt_attr_values(141) := l_staging_rec.attribute141;
      lt_attr_values(142) := l_staging_rec.attribute142;
      lt_attr_values(143) := l_staging_rec.attribute143;
      lt_attr_values(144) := l_staging_rec.attribute144;
      lt_attr_values(145) := l_staging_rec.attribute145;
      lt_attr_values(146) := l_staging_rec.attribute146;
      lt_attr_values(147) := l_staging_rec.attribute147;
      lt_attr_values(148) := l_staging_rec.attribute148;
      lt_attr_values(149) := l_staging_rec.attribute149;
      lt_attr_values(150) := l_staging_rec.attribute150;
      lt_attr_values(151) := l_staging_rec.attribute151;
      lt_attr_values(152) := l_staging_rec.attribute152;
      lt_attr_values(153) := l_staging_rec.attribute153;
      lt_attr_values(154) := l_staging_rec.attribute154;
      lt_attr_values(155) := l_staging_rec.attribute155;
      lt_attr_values(156) := l_staging_rec.attribute156;
      lt_attr_values(157) := l_staging_rec.attribute157;
      lt_attr_values(158) := l_staging_rec.attribute158;
      lt_attr_values(159) := l_staging_rec.attribute159;
      lt_attr_values(160) := l_staging_rec.attribute160;
      lt_attr_values(161) := l_staging_rec.attribute161;
      lt_attr_values(162) := l_staging_rec.attribute162;
      lt_attr_values(163) := l_staging_rec.attribute163;
      lt_attr_values(164) := l_staging_rec.attribute164;
      lt_attr_values(165) := l_staging_rec.attribute165;
      lt_attr_values(166) := l_staging_rec.attribute166;
      lt_attr_values(167) := l_staging_rec.attribute167;
      lt_attr_values(168) := l_staging_rec.attribute168;
      lt_attr_values(169) := l_staging_rec.attribute169;
      lt_attr_values(170) := l_staging_rec.attribute170;
      lt_attr_values(171) := l_staging_rec.attribute171;
      lt_attr_values(172) := l_staging_rec.attribute172;
      lt_attr_values(173) := l_staging_rec.attribute173;
      lt_attr_values(174) := l_staging_rec.attribute174;
      lt_attr_values(175) := l_staging_rec.attribute175;
      lt_attr_values(176) := l_staging_rec.attribute176;
      lt_attr_values(177) := l_staging_rec.attribute177;
      lt_attr_values(178) := l_staging_rec.attribute178;
      lt_attr_values(179) := l_staging_rec.attribute179;
      lt_attr_values(180) := l_staging_rec.attribute180;
      lt_attr_values(181) := l_staging_rec.attribute181;
      lt_attr_values(182) := l_staging_rec.attribute182;
      lt_attr_values(183) := l_staging_rec.attribute183;
      lt_attr_values(184) := l_staging_rec.attribute184;
      lt_attr_values(185) := l_staging_rec.attribute185;
      lt_attr_values(186) := l_staging_rec.attribute186;
      lt_attr_values(187) := l_staging_rec.attribute187;
      lt_attr_values(188) := l_staging_rec.attribute188;
      lt_attr_values(189) := l_staging_rec.attribute189;
      lt_attr_values(190) := l_staging_rec.attribute190;
      lt_attr_values(191) := l_staging_rec.attribute191;
      lt_attr_values(192) := l_staging_rec.attribute192;
      lt_attr_values(193) := l_staging_rec.attribute193;
      lt_attr_values(194) := l_staging_rec.attribute194;
      lt_attr_values(195) := l_staging_rec.attribute195;
      lt_attr_values(196) := l_staging_rec.attribute196;
      lt_attr_values(197) := l_staging_rec.attribute197;
      lt_attr_values(198) := l_staging_rec.attribute198;
      lt_attr_values(199) := l_staging_rec.attribute199;
      lt_attr_values(200) := l_staging_rec.attribute200;
      lt_attr_values(201) := l_staging_rec.attribute201;
      lt_attr_values(202) := l_staging_rec.attribute202;
      lt_attr_values(203) := l_staging_rec.attribute203;
      lt_attr_values(204) := l_staging_rec.attribute204;
      lt_attr_values(205) := l_staging_rec.attribute205;
      lt_attr_values(206) := l_staging_rec.attribute206;
      lt_attr_values(207) := l_staging_rec.attribute207;
      lt_attr_values(208) := l_staging_rec.attribute208;
      lt_attr_values(209) := l_staging_rec.attribute209;
      lt_attr_values(210) := l_staging_rec.attribute210;
      lt_attr_values(211) := l_staging_rec.attribute211;
      lt_attr_values(212) := l_staging_rec.attribute212;
      lt_attr_values(213) := l_staging_rec.attribute213;
      lt_attr_values(214) := l_staging_rec.attribute214;
      lt_attr_values(215) := l_staging_rec.attribute215;
      lt_attr_values(216) := l_staging_rec.attribute216;
      lt_attr_values(217) := l_staging_rec.attribute217;
      lt_attr_values(218) := l_staging_rec.attribute218;
      lt_attr_values(219) := l_staging_rec.attribute219;
      lt_attr_values(220) := l_staging_rec.attribute220;
      lt_attr_values(221) := l_staging_rec.attribute221;
      lt_attr_values(222) := l_staging_rec.attribute222;
      lt_attr_values(223) := l_staging_rec.attribute223;
      lt_attr_values(224) := l_staging_rec.attribute224;
      lt_attr_values(225) := l_staging_rec.attribute225;
      lt_attr_values(226) := l_staging_rec.attribute226;
      lt_attr_values(227) := l_staging_rec.attribute227;
      lt_attr_values(228) := l_staging_rec.attribute228;
      lt_attr_values(229) := l_staging_rec.attribute229;
      lt_attr_values(230) := l_staging_rec.attribute230;
      lt_attr_values(231) := l_staging_rec.attribute231;
      lt_attr_values(232) := l_staging_rec.attribute232;
      lt_attr_values(233) := l_staging_rec.attribute233;
      lt_attr_values(234) := l_staging_rec.attribute234;
      lt_attr_values(235) := l_staging_rec.attribute235;
      lt_attr_values(236) := l_staging_rec.attribute236;
      lt_attr_values(237) := l_staging_rec.attribute237;
      lt_attr_values(238) := l_staging_rec.attribute238;
      lt_attr_values(239) := l_staging_rec.attribute239;
      lt_attr_values(240) := l_staging_rec.attribute240;
      lt_attr_values(241) := l_staging_rec.attribute241;
      lt_attr_values(242) := l_staging_rec.attribute242;
      lt_attr_values(243) := l_staging_rec.attribute243;
      lt_attr_values(244) := l_staging_rec.attribute244;
      lt_attr_values(245) := l_staging_rec.attribute245;
      lt_attr_values(246) := l_staging_rec.attribute246;
      lt_attr_values(247) := l_staging_rec.attribute247;
      lt_attr_values(248) := l_staging_rec.attribute248;
      lt_attr_values(249) := l_staging_rec.attribute249;
      lt_attr_values(250) := l_staging_rec.attribute250;
      lt_attr_values(251) := l_staging_rec.attribute251;
      lt_attr_values(252) := l_staging_rec.attribute252;
      lt_attr_values(253) := l_staging_rec.attribute253;
      lt_attr_values(254) := l_staging_rec.attribute254;
      lt_attr_values(255) := l_staging_rec.attribute255;
      lt_attr_values(256) := l_staging_rec.attribute256;
      lc_function_str := '';
      FOR m IN 1 .. lt_template_attr.COUNT
      LOOP
        -- lc_function_str := lc_function_str || '''' || lt_attr_values(m) || '''' || ',';
	-- Defect 9592 Begin
	lc_function_str := lc_function_str || '''' || trim( replace( lt_attr_values(m) ,lc_single,lc_single||lc_single)) || '''' || ',';
	-- Defect 9592 End
      END LOOP;
      lc_function_str := RTRIM(lc_function_str,',');
      BEGIN
        IF (lc_processed_rec = 1) OR (MOD(lc_processed_rec, 50) = 0)
        THEN
          fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Processing record: '||lc_processed_rec);
          fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Before calling XXCRM_BULK_TEMPLATES_PKG');
          fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Function Name: '||lc_func_name);
          fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Function Parameters: '||lc_function_str);
--          fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Function Command: ');
--          fnd_file.PUT_LINE(fnd_file.LOG,'BEGIN ' || ':1 := ' || lc_func_name || '(' || lc_function_str || '); END;');
        END IF;
        EXECUTE IMMEDIATE 'BEGIN ' || ':1 := ' || lc_func_name || '(' || lc_function_str || '); END;'
          USING IN OUT lc_error_str;
          fnd_file.PUT_LINE(fnd_file.LOG,'Step 7; after calling the processing function');
      EXCEPTION
      WHEN OTHERS THEN
        lc_error_str := 'FALSE_' || SQLERRM;
        fnd_file.PUT_LINE(fnd_file.LOG,lc_error_str);
      END;
--      fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> After calling XXCRM_BULK_TEMPLATES_PKG');
---Moved this from top so this is done after the outside function call is done. This
---change will make sure if there is a commit in the outside call the LOB transaction
---doesn't report error.
-- Mohan 6/20
      SELECT output_file_data -- CR769
      INTO   lc_out_clob
      FROM   XXCRM_file_uploads
      WHERE  file_upload_id = p_file_upload_id;
      fnd_file.PUT_LINE(fnd_file.LOG,'Step 8; after getting output_file_data');
      SELECT error_file_data
      INTO   lc_error_clob
      FROM   XXCRM_file_uploads
      WHERE  file_upload_id = p_file_upload_id
      FOR UPDATE;
      fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; after getting error_file_data');

      --lc_out_clob :=  lc_attr_header || CHR(10);
      IF INSTR(lc_error_str, 'FALSE_') = 1 THEN

         ln_error_cnt:=ln_error_cnt+1; --CR769
        lc_error_str := SUBSTR(lc_error_str, 7, LENGTH(lc_error_str)-6);
        lc_error_row := '';
        fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; Inside If1 error string has false');
       IF lc_out_clob is NULL
       THEN

--       lc_out_clob := lc_attr_header || ',' || lc_out_addnl_header ||  CHR(10);
         lc_out_clob :=  lc_out_addnl_header ||  CHR(10);
         fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; out clob is nulle');
       END IF;
       IF lc_error_clob = EMPTY_CLOB
       THEN

       --lc_error_clob := lc_attr_header || ',' || lc_error_addnl_header || CHR(10);
       lc_error_clob :=  lc_error_addnl_header || CHR(10);
       fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; error clob is empty clob');
       END IF;
        FOR t IN 1 .. lt_template_attr.COUNT
        LOOP
          lc_error_row := lc_error_row || '"' || lt_attr_values(t) || '",';
        END LOOP;
        lc_error_row :=  lc_error_row || '"' || lc_error_str || '"' || chr(10);
        fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; before writing to error clob');
        DBMS_LOB.CREATETEMPORARY(lc_error_clob, true);
        DBMS_LOB.WRITEAPPEND(lc_error_clob, LENGTH(lc_error_row), lc_error_row);
        DBMS_LOB.FREETEMPORARY(lc_error_clob);
        fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; before writing to out clob');
        DBMS_LOB.CREATETEMPORARY(lc_out_clob, true);
        DBMS_LOB.WRITEAPPEND(lc_out_clob, LENGTH(lc_error_row), lc_error_row);
        DBMS_LOB.FREETEMPORARY(lc_out_clob);
        fnd_file.PUT_LINE(fnd_file.LOG,'Step 9; after writing to out clob');
      ELSIF INSTR(lc_error_str, 'TRUE') != 1 THEN

       ln_error_cnt:=ln_error_cnt+1; --CR769
       lc_error_row := '';
       IF lc_error_clob= EMPTY_CLOB
       THEN

--       lc_error_clob := lc_attr_header || ',' || lc_error_addnl_header || CHR(10);
         lc_error_clob := lc_error_addnl_header || CHR(10);
       END IF;
        FOR t IN 1 .. lt_template_attr.COUNT
        LOOP
          lc_error_row := lc_error_row || '"' || lt_attr_values(t) || '",';
        END LOOP;
        -- Error Message Not In The Required Format
        lc_error_row := lc_error_row || '"UNKNOWN ERROR"' || chr(10);
		DBMS_LOB.CREATETEMPORARY(lc_error_clob, true);
        DBMS_LOB.WRITEAPPEND(lc_error_clob, LENGTH(lc_error_row), lc_error_row);
		DBMS_LOB.FREETEMPORARY(lc_error_clob);

-- CR769
       ELSIF INSTR(lc_error_str, 'TRUE') = 1 THEN

       ln_success_cnt:=ln_success_cnt+1;--CR769
       lc_error_str := SUBSTR(lc_error_str, 5, LENGTH(lc_error_str)-4); --CR769
       lc_output_row:='';
       IF lc_out_clob is NULL
       THEN
        --lc_out_clob := lc_attr_header || ',' || lc_out_addnl_header || CHR(10);
       lc_out_clob :=   lc_out_addnl_header || CHR(10);
       END IF;

        FOR t IN 1 .. lt_template_attr.COUNT
        LOOP
          lc_output_row := lc_output_row || '"' || lt_attr_values(t) || '",' ;
        END LOOP;
        --lc_output_row := lc_output_row || chr(10);
        lc_output_row :=  lc_output_row || '"' || lc_error_str || '"' || chr(10); -- --CR769
		DBMS_LOB.CREATETEMPORARY(lc_out_clob, true);
        DBMS_LOB.WRITEAPPEND(lc_out_clob , LENGTH(lc_output_row), lc_output_row);
		DBMS_LOB.FREETEMPORARY(lc_out_clob);
      END IF;
-- Updating the error clob back into the table
-- Mohan 6/20
      fnd_file.PUT_LINE(fnd_file.LOG,'Step 10; before updating the clob data to the table');
      UPDATE XXCRM_file_uploads
      SET    error_file_data          = lc_error_clob
             ,output_file_data        = lc_out_clob
             ,total_processed_records = lc_processed_rec -- CR769
             ,no_of_success_records   = ln_success_cnt -- CR769
             ,no_of_error_records     = ln_error_cnt -- CR769
             ,last_updated_by         = -1
             ,last_update_date        = SYSDATE
      WHERE  file_upload_id           = p_file_upload_id;
      fnd_file.PUT_LINE(fnd_file.LOG,'Step 10; after updating the clob data to the table');
      COMMIT; -- Commit for the update. Mohan 6/20
    END LOOP;
 -- CR769
    IF lc_out_clob != EMPTY_CLOB THEN
      UPDATE XXCRM_file_uploads
      SET    output_file_data = lc_out_clob
             ,file_status      = 'S'
             ,last_updated_by  = -1
             ,last_update_date = SYSDATE
      WHERE  file_upload_id    = p_file_upload_id;
    END IF;
    IF lc_error_clob != EMPTY_CLOB THEN
      UPDATE XXCRM_file_uploads
      SET    error_file_data    = lc_error_clob
             ,file_status       = 'C'
             ,last_updated_by   = -1
             ,last_update_date  = SYSDATE
      WHERE  file_upload_id     = p_file_upload_id;
    END IF;
    DELETE
    FROM   XXCRM_staging_file_uploads
    WHERE  file_upload_id = p_file_upload_id;
    COMMIT;
  END IF;
  fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Processing Complete. Total records processed: '||lc_processed_rec);
  fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Processing Complete. Total success records: '||ln_success_cnt); -- --CR769
  fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> Processing Complete. Total error records: '||ln_error_cnt); -- --CR769
  fnd_file.PUT_LINE(fnd_file.LOG,   ' ----->>> File upload id '||p_file_upload_id );
  
  
        -- Added below block for CR# 864 (V: 6).
        -- ----------------------------------------------------------------------
        -- Below Block is for Post Processing function.
        -- Will execute the function which is mentioned in XXCRM_template_file_uploads table.
        -- ----------------------------------------------------------------------
  
        BEGIN
          IF lc_post_processing_function IS NOT NULL
          THEN
            fnd_file.PUT_LINE(fnd_file.LOG, ' ----->>> Processing post processing function.'
                                         || ' Function Command: BEGIN ' 
                                         || ':1 := ' || lc_post_processing_function || '; END;');
  
            EXECUTE IMMEDIATE 'BEGIN ' || ':1 := ' || lc_post_processing_function || '; END;'
            USING IN OUT lc_error_str;
        
            IF INSTR(lc_error_str, 'FALSE_') = 1 THEN
               fnd_file.PUT_LINE(fnd_file.LOG,lc_error_str);
               RAISE EX_POST_PROCESSING;
  
            END IF;
            
          END IF;
          
        EXCEPTION
        WHEN OTHERS THEN
          lc_error_str := 'FALSE_' || 'Error while processing post processing function: ' || SQLERRM;
          fnd_file.PUT_LINE(fnd_file.LOG,lc_error_str);
          RAISE EX_POST_PROCESSING;
        END;
      
EXCEPTION
WHEN EX_NO_FILE THEN
  x_error_code := 2;
  fnd_file.put_line(fnd_file.LOG, 'The specified file_upload_id does not exist');
WHEN EX_NO_DATA THEN-- CR769 Input file is Empty
    x_error_code := 2;
    UPDATE XXCRM_file_uploads
    SET    file_status              = 'E'
         ,error_file_data         = TO_CLOB('Empty Input File' || chr(10))
   ,output_file_data        = TO_CLOB('Empty Input File' || chr(10))
         ,last_updated_by         = -1
         ,last_update_date        = SYSDATE
         ,total_processed_records = 0
         ,no_of_success_records   = 0 
         ,no_of_error_records     = 0
  WHERE  file_upload_id           = p_file_upload_id;
  COMMIT;
WHEN EX_NO_TEMPLATE THEN
  x_error_code := 2;
  UPDATE XXCRM_file_uploads
  SET    file_status              = 'E'
         ,error_file_data         = TO_CLOB('Template does not exist' || chr(10))
         ,last_updated_by         = -1
         ,last_update_date        = SYSDATE
         ,total_processed_records = lc_processed_rec -- CR769
         ,no_of_success_records   = ln_success_cnt -- CR769
         ,no_of_error_records     = ln_error_cnt -- CR769
  WHERE  file_upload_id           = p_file_upload_id;
  COMMIT;
WHEN EX_STAGING_INSERT THEN
  x_error_code := 2;
  ROLLBACK;
  UPDATE XXCRM_file_uploads
  SET    file_status               = 'E'
         ,error_file_data          = TO_CLOB('Not able to insert data into the staging table   ' || chr(10)||lc_sql_stmt)
         ,last_updated_by          = -1
         ,last_update_date         = SYSDATE
         ,total_processed_records  = lc_processed_rec -- CR769
         ,no_of_success_records    = ln_success_cnt -- CR769
         ,no_of_error_records      = ln_error_cnt -- CR769
  WHERE  file_upload_id            = p_file_upload_id;
  COMMIT;

-- ----------------------------------------------------------------------
-- Added below two exceptions (EX_PRE_PROCESSING, EX_POST_PROCESSING) 
-- for CR# 864 (V: 6).
-- ----------------------------------------------------------------------

WHEN EX_PRE_PROCESSING THEN
  x_error_code := 2;
  ROLLBACK;

  DELETE
  FROM   XXCRM_staging_file_uploads
  WHERE  file_upload_id = p_file_upload_id;

  UPDATE XXCRM_file_uploads
  SET    file_status                = 'E'
          ,error_file_data          = TO_CLOB(lc_error_str || chr(10))
          ,last_updated_by          = -1
          ,last_update_date         = SYSDATE
          ,total_processed_records  = lc_processed_rec -- CR769
         ,no_of_success_records     = ln_success_cnt -- CR769
         ,no_of_error_records       = ln_error_cnt -- CR769
  WHERE  file_upload_id             = p_file_upload_id;
  COMMIT;

WHEN EX_POST_PROCESSING THEN
    x_error_code := 2;
    lc_error_str := lc_error_str || chr(10);
    
    UPDATE XXCRM_file_uploads
    SET    file_status              = 'E'
          ,error_file_data          = error_file_data || lc_error_str
          ,NO_OF_Error_Records      = NO_OF_Error_Records + 1
    WHERE  file_upload_id           = p_file_upload_id;
    
    COMMIT;

WHEN OTHERS THEN
  x_error_code := 2;
  ROLLBACK;
  lc_error_str := 'UNEXPECTED ERROR: ' || SQLERRM;
 fnd_file.put_line(fnd_file.LOG, 'lc_error_str' || lc_error_str);
  DELETE
  FROM   XXCRM_staging_file_uploads
  WHERE  file_upload_id = p_file_upload_id;
  UPDATE XXCRM_file_uploads
  SET    file_status                = 'E'
          ,error_file_data          = TO_CLOB(lc_error_str || chr(10))
          ,last_updated_by          = -1
          ,last_update_date         = SYSDATE
          ,total_processed_records  = lc_processed_rec -- CR769
         ,no_of_success_records     = ln_success_cnt -- CR769
         ,no_of_error_records       = ln_error_cnt -- CR769
  WHERE  file_upload_id             = p_file_upload_id;
  COMMIT;
END XXCRM_FILE_UPLOAD;


-- ----------------------------------------------------------------------
-- Below Function is added for CR# 864 (V: 6).
-- ----------------------------------------------------------------------
  FUNCTION TRUNCATE_TABLE( p_table_name     VARCHAR2
                         )
  RETURN VARCHAR2
-- +==========================================================================+
-- | Name        : TRUNCATE_TABLE                                             |
-- | Description : To truncate table date. Need to pass table owner name also.|
-- |                                                                          |
-- | Returns     : VARCHAR2                                                   |
-- +==========================================================================+

  IS

     lc_truncate_string varchar2(4000);
  BEGIN

    fnd_file.PUT_LINE(fnd_file.LOG, '----------- Begin XXCRM_FILE_UPLOADS_CMN_PKG.TRUNCATE_TABLE Procedure -----------');

    lc_truncate_string := 'Truncate table ' || p_table_name ;
    fnd_file.PUT_LINE(fnd_file.LOG, 'lc_truncate_string: ' || lc_truncate_string);
    
    EXECUTE IMMEDIATE (lc_truncate_string);
    
    fnd_file.PUT_LINE(fnd_file.LOG, '----------- End XXCRM_FILE_UPLOADS_CMN_PKG.TRUNCATE_TABLE Procedure -----------');
        
    RETURN 'TRUE';
    
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'FALSE_ERROR_Unexpected exception in TRUNCATE_TABLE: ' || SQLERRM;
  END TRUNCATE_TABLE;


-- ----------------------------------------------------------------------
-- Below Function is added for CR# 864 (V: 6).
-- ----------------------------------------------------------------------
  FUNCTION ANALYZE_TABLE( 
        p_owner_name         VARCHAR2
       ,p_table_name         VARCHAR2
       ,p_estimate_percent   NUMBER
                         )
  RETURN VARCHAR2
-- +==========================================================================+
-- | Name        : ANALYZE_TABLE                                              |
-- | Description : To procedure will analyze a table.                         |
-- |                                                                          |
-- | Returns     : VARCHAR2                                                   |
-- +==========================================================================+

  IS

  BEGIN

    fnd_file.PUT_LINE(fnd_file.LOG, '----------- Begin XXCRM_FILE_UPLOADS_CMN_PKG.ANALYZE_TABLE Procedure -----------');

    DBMS_STATS.GATHER_TABLE_STATS (
                    p_owner_name
                  , p_table_name
                  , ESTIMATE_PERCENT => p_estimate_percent);
    
    fnd_file.PUT_LINE(fnd_file.LOG, '----------- End XXCRM_FILE_UPLOADS_CMN_PKG.ANALYZE_TABLE Procedure -----------');
        
    RETURN 'TRUE';
    
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'FALSE_ERROR_Unexpected exception in ANALYZE_TABLE: ' || SQLERRM;
  END ANALYZE_TABLE;

END XXCRM_FILE_UPLOADS_CMN_PKG;
/

SHOW ERRORS;