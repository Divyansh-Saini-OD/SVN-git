create or replace
PROCEDURE      XX_FA_PARENT 
(errbuf OUT VARCHAR2, retcode OUT VARCHAR2)  AS

/******************************************************************************
   NAME:       XX_FA_PARENT
   PURPOSE:    This procedure will load the Parent Asset file into 
               FA_MASS_ADDITIONS_STG table.
               
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0       8/22/2007   Sandeep Pandhare Created this procedure.
   1.1       11/22/2007  Sandeep Pandhare Removed hard-coding for CORP book.   
******************************************************************************/
  
  /* Define constants */
  c_file_path CONSTANT VARCHAR2(15) := 'XXFIN_INBOUND';
  c_separator CONSTANT VARCHAR2(1) := '|';
  c_blank     CONSTANT VARCHAR2(1) := ' ';
  c_when      CONSTANT DATE := SYSDATE;
  c_who       CONSTANT fnd_user.user_id%TYPE := Fnd_Load_Util.owner_id('USER');
  --c_who       CONSTANT fnd_user.user_id%TYPE := Fnd_Load_Util.owner_id('440946');
c_convaction CONSTANT VARCHAR2(10) := 'CREATE';
c_convsystemcd CONSTANT VARCHAR2(5) := 'U4PSF';
c_srcsystemref CONSTANT VARCHAR2(25) := 'PS Parent Asset Conv';
c_feedersystem CONSTANT VARCHAR2(25) := 'PEOPLESOFT';
c_status CONSTANT VARCHAR2(5):= 'POST';
c_processflg number := 1;
c_AUDIT_ID number := 999999; 


  /* Define variables */
v_Fileid  UTL_FILE.file_type;
v_book VARCHAR2(25);
v_ca_book VARCHAR2(25);
v_us_book VARCHAR2(25);
v_file_name VARCHAR2(32) := 'parent_assets.txt';
v_fieldno NUMBER;
v_fieldvalue VARCHAR2(100);
v_dataline VARCHAR2(32767);
l_eof BOOLEAN;
v_bool                         BOOLEAN;
v_reccnt NUMBER;
v_tablecnt NUMbER := 0;
v_delimiterposn NUMBER := 0;
v_prevdelimiterposn NUMBER := 0;
v_org_id NUMBER;
sqlrowcount NUMBER;
v_request_id                   fnd_concurrent_requests.request_id%TYPE;
v_set_completion_status_flag   VARCHAR2(10) := 'S';
v_set_completion_status_text   VARCHAR2(240);
too_many_elements EXCEPTION;
v_oper_unit varchar2(32);
v_dept varchar2(32);
v_acct varchar2(32);
v_chartfld1 varchar2(32);


v_AUDIT_ID    xx_fa_mass_additions_stg.AUDIT_ID%TYPE;                   
v_RECORD_ID  xx_fa_mass_additions_stg.RECORD_ID%TYPE;                     
v_CONTROL_ID xx_fa_mass_additions_stg.CONTROL_ID%TYPE;                                      
v_BATCH_ID   xx_fa_mass_additions_stg.BATCH_ID%TYPE;                                  
v_MASS_ADDITION_ID  xx_fa_mass_additions_stg.MASS_ADDITION_ID%TYPE;  -- start at 999000000 and increment it;                  
v_DESCRIPTION  xx_fa_mass_additions_stg.DESCRIPTION%TYPE;                   
v_ASSET_CATEGORY_ID  xx_fa_mass_additions_stg.ASSET_CATEGORY_ID%TYPE; 
v_category  varchar2(32);
v_profile varchar2(32);
v_project varchar2(32);
               
v_DATE_PLACED_IN_SERVICE  xx_fa_mass_additions_stg.DATE_PLACED_IN_SERVICE%TYPE;        
v_FIXED_ASSETS_COST  xx_fa_mass_additions_stg.FIXED_ASSETS_COST%TYPE;             
               
v_FIXED_ASSETS_UNITS  xx_fa_mass_additions_stg.FIXED_ASSETS_UNITS%TYPE;            
v_PAYABLES_CODE_COMBINATION_ID   xx_fa_mass_additions_stg.PAYABLES_CODE_COMBINATION_ID%TYPE; 
v_EXPENSE_CODE_COMBINATION_ID   xx_fa_mass_additions_stg.PAYABLES_CODE_COMBINATION_ID%TYPE;  
v_LOCATION_ID   xx_fa_mass_additions_stg.LOCATION_ID%TYPE;                                                           
v_CREATE_BATCH_ID    xx_fa_mass_additions_stg.CREATE_BATCH_ID%TYPE;                                                                                                 
v_PAYABLES_COST      xx_fa_mass_additions_stg.PAYABLES_COST%TYPE;                                          
v_DEPRECIATE_FLAG    xx_fa_mass_additions_stg.DEPRECIATE_FLAG%TYPE;                                                                       
v_ASSET_TYPE         xx_fa_mass_additions_stg.ASSET_TYPE%TYPE;             
v_DEPRN_RESERVE      xx_fa_mass_additions_stg.DEPRN_RESERVE%TYPE;             
v_YTD_DEPRN          xx_fa_mass_additions_stg.YTD_DEPRN%TYPE;                                                       
v_ATTRIBUTE6         xx_fa_mass_additions_stg.ATTRIBUTE6%TYPE;                                 
v_ATTRIBUTE10        xx_fa_mass_additions_stg.ATTRIBUTE10%TYPE;                                
v_ATTRIBUTE13        xx_fa_mass_additions_stg.ATTRIBUTE13%TYPE;                                                                                                             
v_ORIGINAL_DEPRN_START_DATE     xx_fa_mass_additions_stg.ORIGINAL_DEPRN_START_DATE%TYPE;         
--v_CREATED_BY         xx_fa_mass_additions_stg.AUDIT_ID%TYPE;                          
--v_LAST_UPDATE_LOGIN  xx_fa_mass_additions_stg.AUDIT_ID%TYPE;                           
--v_ACCOUNTING_DATE    xx_fa_mass_additions_stg.AUDIT_ID%TYPE; 
--v_PROPERTY_TYPE_CODE xx_fa_mass_additions_stg.AUDIT_ID%TYPE;             
--v_PROPERTY_1245_1250_CODE       xx_fa_mass_additions_stg.AUDIT_ID%TYPE;  
--v_IN_USE_FLAG        xx_fa_mass_additions_stg.AUDIT_ID%TYPE;             
--v_OWNED_LEASED       xx_fa_mass_additions_stg.AUDIT_ID%TYPE;             
--v_NEW_USED           xx_fa_mass_additions_stg.AUDIT_ID%TYPE;   
--v_AMORTIZE_FLAG      xx_fa_mass_additions_stg.AUDIT_ID%TYPE; 
--v_PAYABLES_UNITS   xx_fa_mass_additions_stg.AUDIT_ID%TYPE;
--v_BOOK_TYPE_CODE   xx_fa_mass_additions_stg.AUDIT_ID%TYPE;
v_DEPRN_METHOD_CODE  xx_fa_mass_additions_stg.DEPRN_METHOD_CODE%TYPE;             
v_LIFE_IN_MONTHS     xx_fa_mass_additions_stg.LIFE_IN_MONTHS%TYPE;   

PROCEDURE INSERT_MASS_ADDITION_STG  IS

BEGIN
-- dbms_output.put_line('INSERT_MASS_ADDITION_STG procedure started .......');
INSERT INTO XX_FA_MASS_ADDITIONS_STG
(
AUDIT_ID,                       
RECORD_ID,                      
CONTROL_ID,                     
PROCESS_FLAG,                   
CONV_ACTION ,                                         
SOURCE_SYSTEM_CODE,             
SOURCE_SYSTEM_REF,              
MASS_ADDITION_ID,                                 
DESCRIPTION,                    
ASSET_CATEGORY_ID,                                
BOOK_TYPE_CODE,                 
DATE_PLACED_IN_SERVICE,         
FIXED_ASSETS_COST,              
PAYABLES_UNITS,                 
FIXED_ASSETS_UNITS,             
PAYABLES_CODE_COMBINATION_ID,   
EXPENSE_CODE_COMBINATION_ID,    
LOCATION_ID,                               
FEEDER_SYSTEM_NAME,             
CREATE_BATCH_DATE,              
--CREATE_BATCH_ID,                
LAST_UPDATE_DATE,               
LAST_UPDATED_BY,                                                
POSTING_STATUS,                 
QUEUE_NAME,                                                 
PAYABLES_COST,                                               
DEPRECIATE_FLAG,                                              
--AMORTIZE_FLAG,                                  
ASSET_TYPE,                     
DEPRN_RESERVE,                  
YTD_DEPRN,                                      
CREATED_BY,                     
CREATION_DATE,                  
LAST_UPDATE_LOGIN,                            
ACCOUNTING_DATE,                              
ATTRIBUTE6,                                         
ATTRIBUTE10,                                       
ATTRIBUTE13,                                                                                                        
CONVERSION_DATE,                
ORIGINAL_DEPRN_START_DATE,             
TRANSACTION_DATE,                                 
--PROPERTY_TYPE_CODE,             
--PROPERTY_1245_1250_CODE,        
--IN_USE_FLAG,                    
--OWNED_LEASED,                   
--NEW_USED,                                                        
DEPRN_METHOD_CODE,              
LIFE_IN_MONTHS             
)
VALUES
(

c_AUDIT_ID,                       
v_MASS_ADDITION_ID,                      
v_MASS_ADDITION_ID,                     
c_processflg,                   
c_convaction ,                                          
c_convsystemcd,             
c_srcsystemref,              
v_MASS_ADDITION_ID,                                 
v_DESCRIPTION,                    
v_ASSET_CATEGORY_ID,                                
v_BOOK,                 
v_DATE_PLACED_IN_SERVICE,         
v_FIXED_ASSETS_COST,              
v_FIXED_ASSETS_UNITS,                 
v_FIXED_ASSETS_UNITS,             
v_PAYABLES_CODE_COMBINATION_ID,   
v_EXPENSE_CODE_COMBINATION_ID,    
v_LOCATION_ID,                               
c_feedersystem,             
c_when,              
--v_CREATE_BATCH_ID,                
c_when,               
c_who,                                                
c_STATUS,                 
c_STATUS,                                                 
v_FIXED_ASSETS_COST,    -- Payables Cost                                           
v_DEPRECIATE_FLAG,                                              
--v_AMORTIZE_FLAG,                                  
'CAPITALIZED',     -- ASSET_TYPE,                     
v_DEPRN_RESERVE,                  
v_YTD_DEPRN,                                      
c_who,                     
c_when,                  
c_who,                            
c_when,    -- ACCOUNTING_DATE,                              
v_ATTRIBUTE6,                                         
v_ATTRIBUTE10,                                       
v_ATTRIBUTE13,                                                                                                        
c_when,  -- Conversion date              
v_ORIGINAL_DEPRN_START_DATE,             
c_when,                                 
--v_PROPERTY_TYPE_CODE,             
--v_PROPERTY_1245_1250_CODE,        
--v_IN_USE_FLAG,                    
--v_OWNED_LEASED,                   
--v_NEW_USED,                                                        
v_DEPRN_METHOD_CODE,              
v_LIFE_IN_MONTHS                 

);

sqlrowcount := SQL%ROWCOUNT;
if sqlrowcount <> 1 then
  dbms_output.put_line('Insert into FA_MASS_ADDITIONs failed.');
else
 null;
--  dbms_output.put_line('Insert into FA_MASS_ADDITIONs procedure completed .......');
end if;

v_tablecnt := v_tablecnt + 1;
END INSERT_MASS_ADDITION_STG;



PROCEDURE INITIALIZE IS

BEGIN

                                                                           
v_DESCRIPTION := ' ';                    
v_ASSET_CATEGORY_ID  := ' ';                                                    
v_DATE_PLACED_IN_SERVICE :=  c_when;         
v_FIXED_ASSETS_COST := 0;            
v_FIXED_ASSETS_UNITS := 0;                      
v_PAYABLES_CODE_COMBINATION_ID := ' ';
v_EXPENSE_CODE_COMBINATION_ID := ' ';
v_LOCATION_ID  := ' ';                                                                                                                                        
v_PAYABLES_COST := 0;                                               
v_DEPRECIATE_FLAG  := ' ';                                               
v_DEPRN_RESERVE  := 0;                
v_YTD_DEPRN  := 0;                                      
v_ATTRIBUTE6  := ' ';                                       
v_ATTRIBUTE10  := ' ';                                 
v_ATTRIBUTE13  := ' ';                                                                                                        
v_ORIGINAL_DEPRN_START_DATE :=  c_when;                                                            
v_DEPRN_METHOD_CODE := ' ';              
v_LIFE_IN_MONTHS := 0;
v_prevdelimiterposn := 0;
v_delimiterposn := 0;

END INITIALIZE;


-- Main Section
BEGIN

  INITIALIZE;
  v_reccnt := 0;
  v_MASS_ADDITION_ID := 999000000;
  
begin
  select book_type_code 
  into v_ca_book
  from fa_book_controls  
  where book_class = 'CORPORATE'
  and book_type_name like '%CANADA%';

    EXCEPTION
      WHEN OTHERS THEN
        Fnd_File.put_line(Fnd_File.LOG,'Error while processing file: '||SQLERRM);
        v_ca_book := 'OD CA CORP';
END;
Fnd_File.put_line(Fnd_File.LOG,'Canadian Corporate Book: '||v_ca_book);  

begin
  select book_type_code 
  into v_us_book
  from fa_book_controls  
  where book_class = 'CORPORATE'
  and book_type_name not like '%CANADA%';

    EXCEPTION
      WHEN OTHERS THEN
        Fnd_File.put_line(Fnd_File.LOG,'Error while processing file: '||SQLERRM);
        v_us_book := 'OD US CORP';
END;  
Fnd_File.put_line(Fnd_File.LOG,'US Corporate Book: '||v_us_book);  

  /* Open the file for reading */
  v_fileid := UTL_FILE.FOPEN(c_file_path, v_file_name, 'R',  32000);

   /* Get the Header file line */
   UTL_FILE.GET_LINE(v_fileid, v_dataline, 32767);
   DBMS_OUTPUT.PUT_LINE('Header Line has been read');
  /* Loop through the file and process each row */
  LOOP
   BEGIN
   /* Get the data file line */
   UTL_FILE.GET_LINE(v_fileid, v_dataline, 32767);
   
   v_dataline := v_dataline || c_separator;
--   DBMS_OUTPUT.PUT_LINE('Data' || v_reccnt || ' ' || v_dataline);
   v_fieldno := 0;
   LOOP
     v_delimiterposn := INSTR(v_dataline, c_separator, v_delimiterposn + 1);
     
     exit when v_delimiterposn = 0;
      
      v_fieldno := v_fieldno + 1;
      v_fieldvalue := trim(substr (v_dataline, v_prevdelimiterposn+1, v_delimiterposn - v_prevdelimiterposn - 1));
      v_prevdelimiterposn := v_delimiterposn;
      
      case v_fieldno
      when 1 then
--        DBMS_OUTPUT.PUT_LINE('F1' || v_fieldvalue);
        v_attribute13 := v_fieldvalue;
        if v_attribute13 = '00003' then
           v_book := v_ca_book;
        else
           v_book := v_us_book;
        end if;
      when 2 then
--        DBMS_OUTPUT.PUT_LINE('F2' || v_fieldvalue);
        v_attribute6 := v_fieldvalue;
        v_attribute10 := v_fieldvalue;
      when 3 then
--        DBMS_OUTPUT.PUT_LINE('Units before:' || v_fieldvalue);
        v_FIXED_ASSETS_UNITS := to_number(v_fieldvalue);
--        DBMS_OUTPUT.PUT_LINE('Units after:' || v_FIXED_ASSETS_UNITS);
      when 4 then
        v_FIXED_ASSETS_COST := to_number(v_fieldvalue);
      when 5 then
--        DBMS_OUTPUT.PUT_LINE('Date before:' || v_fieldvalue);
        v_DATE_PLACED_IN_SERVICE := to_date(v_fieldvalue,'yyyy-mm-dd');
--        DBMS_OUTPUT.PUT_LINE('Date after:' || v_DATE_PLACED_IN_SERVICE);
      when 6 then
        null; -- v_FIXED_ASSETS_UNITS := v_fieldvalue;
      when 7 then
        v_ORIGINAL_DEPRN_START_DATE := to_date(v_fieldvalue,'yyyy-mm-dd');
      when 8 then
        v_DEPRECIATE_FLAG := 'NO';
        if v_fieldvalue = 'D' then
          v_DEPRECIATE_FLAG := 'YES';
        end if;
--        DBMS_OUTPUT.PUT_LINE('Depr Flag = ' || v_DEPRECIATE_FLAG);    
      when 9 then
        v_LIFE_IN_MONTHS  := to_number(v_fieldvalue);
      when 10 then
        v_DEPRN_METHOD_CODE  := '';
        if v_fieldvalue = 'SL' then
          v_DEPRN_METHOD_CODE  := 'STL';
        end if;  
      when 11 then
        null;
      when 12 then
        null;
      when 13 then
        null;
      when 14 then
        null;
      when 15 then
        null;
      when 16 then
        null;        
      when 17 then
        null;        
      when 18 then
        v_DESCRIPTION := v_fieldvalue;
      when 19 then
        v_oper_unit := trim(v_fieldvalue);
      when 20 then
        v_dept := trim(v_fieldvalue);
--        DBMS_OUTPUT.PUT_LINE('Department is ' ||v_dept); 
        if (v_dept is NULL ) then
           v_dept := '0903';
--           DBMS_OUTPUT.PUT_LINE('Department is blank. ' ||v_attribute6);           
        end if;   
      when 21 then
        v_chartfld1 := trim(v_fieldvalue);
       if v_chartfld1 is null then
--           DBMS_OUTPUT.PUT_LINE('Chartfield is blank. ' ||v_attribute6);
           v_chartfld1 := '03';
        end if; 
      when 22 then
        v_Acct := v_fieldvalue;
      when 23 then
        v_project := v_fieldvalue;
      when 24 then
        v_profile := v_fieldvalue;
      when 25 then
        v_category := v_fieldvalue;
      when 26 then
        v_location_id := '0' || v_fieldvalue;        
--      when 27,28,29,30,31,32,33 then
--       null;
--      when 34,35 then   -- Year and Period
--        null;
--  if Operating unit is null then use Location Id
        if v_oper_unit is null then
           v_oper_unit := v_fieldvalue;
        end if; 
      when 36 then
        v_YTD_DEPRN := to_number(v_fieldvalue);
      when 37 then
        v_DEPRN_RESERVE := to_number(v_fieldvalue);
--      when 38,39 then   -- Life rem parent id
--        null; 
      else
        null;
      end case;
   end loop;
   
   -- call the Insert statement
--   00002.0903.1300020000.00929.00000.03.000000	BU v_dept v_acct v_oper_unit # v_chartfld1 #
   v_PAYABLES_CODE_COMBINATION_ID := v_attribute13 || '.' || v_dept || '.' || v_acct || '.' || v_oper_unit || '.' || '00000' || '.' || v_chartfld1 || '.' || '000000';
   v_EXPENSE_CODE_COMBINATION_ID := v_attribute13 || '.' || v_dept || '.' || '9350010000'  || '.' || v_oper_unit || '.' || '00000' || '.' || v_chartfld1 || '.' || '000000';
   v_asset_category_id := v_category || '.' || v_profile;
   
   -- Insert into Mass Additions table;
   v_reccnt := v_reccnt + 1;
   v_MASS_ADDITION_ID := v_MASS_ADDITION_ID + 1;   
   DBMS_OUTPUT.PUT_LINE('Record ' || v_reccnt || ' inserted.');
   INSERT_MASS_ADDITION_STG;  
   INITIALIZE;
    

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        EXIT;
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Main: Error while processing file. ' ||SQLERRM);
        Fnd_File.put_line(Fnd_File.LOG,'Error while processing file: '||SQLERRM);

        EXIT;
    END;

  END LOOP;  
    DBMS_OUTPUT.PUT_LINE('Commit and Close the File');
    Commit;
    UTL_FILE.fclose(v_Fileid);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   'Program Name: Office Depot FA Conversion for Parent Assets                                     Date: '||SYSDATE);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   '                                                                                                    ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   '                                                                                                        ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   'Number of lines in the File: ' || v_reccnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,   'Number of rows inserted into table: ' || v_tablecnt);
    DBMS_OUTPUT.PUT_LINE('Number of Records:' || v_reccnt || ' Table Inserts:' || v_tablecnt);

END;

/                                                                                                                                                                     