create or replace
PROCEDURE XX_AP_BANK_SCRAMBLE (errbuf OUT VARCHAR2,   retcode OUT VARCHAR2) 
AS
/******************************************************************************
   NAME:       XX_AP_BANK_SCRAMBLE
   PURPOSE:    This procedure will scramble the Employee Bank Account information
               except for Production Database.

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        9/05/2007   Sandeep Pandhare Created this procedure.

******************************************************************************/

 /* Define constants */ 
c_when constant DATE := sysdate;
c_who constant fnd_user.user_id%TYPE := fnd_load_util.owner_id('USER');

/* Define variables */
 
v_dbname VARCHAR2(60);
v_extract_dt date := NULL;
v_timestamp VARCHAR2(30) := to_char(c_when, 'DDMONYY_HHMISS');
fileid utl_file.file_type;
v_name VARCHAR2(64);
v_vendor_number VARCHAR2(30);
v_reccnt NUMBER := 0;
v_emplid   xx_hr_employee_banks.LEGACY_EMPLOYEE_ID%TYPE;
v_banknum  xx_hr_employee_banks.BANK_NUM%TYPE;
v_bankname xx_hr_employee_banks.BANK_NAME%TYPE;
v_bankaccountnum xx_hr_employee_banks.BANK_ACCOUNT_NUM%TYPE;
v_bankbranchname xx_hr_employee_banks.BANK_BRANCH_NAME%TYPE;
v_randbanknum xx_hr_employee_banks.BANK_NUM%TYPE;
v_randbankaccountnum xx_hr_employee_banks.BANK_ACCOUNT_NUM%TYPE;

/* desc xxcnv.xx_hr_employee_banks
Name                           Null     Type                                                                                                                                                                                          
------------------------------ -------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
LEGACY_EMPLOYEE_ID             NOT NULL NUMBER(22)                                                                                                                                                                                    
LAST_UPDATE_DATE                        DATE                                                                                                                                                                                          
LAST_UPDATED_BY                         NUMBER                                                                                                                                                                                        
LAST_UPDATE_LOGIN                       NUMBER                                                                                                                                                                                        
CREATION_DATE                           DATE                                                                                                                                                                                          
CREATED_BY                              NUMBER(22)                                                                                                                                                                                    
BANK_NUM                       NOT NULL VARCHAR2(25)                                                                                                                                                                                  
BANK_NAME                      NOT NULL VARCHAR2(60)                                                                                                                                                                                  
BANK_ACCOUNT_NUM               NOT NULL VARCHAR2(30)                                                                                                                                                                                  
BANK_BRANCH_NAME               NOT NULL VARCHAR2(60)                                                                                                                                                                                  
COUNTRY                                 VARCHAR2(25) 
*/

CURSOR employee_banks_cur IS
SELECT LEGACY_EMPLOYEE_ID,
  BANK_NUM,
  BANK_NAME,
  BANK_ACCOUNT_NUM,
  BANK_BRANCH_NAME

FROM xx_hr_employee_banks
-- where legacy_employee_id in (10,36,49)  for testing
order by LEGACY_EMPLOYEE_ID
;


BEGIN

v_dbname := null;

select name
into v_dbname
from v$database;

if v_dbname = 'GSIPRDGB' then
-- Don't change the data in this database;
    DBMS_OUTPUT.PUT_LINE( 'Database:' || v_dbname || 'Scramble not allowed' );
    fnd_file.PUT_LINE(fnd_file.LOG,'Database:' || v_dbname || 'Scramble not allowed');
    fnd_file.PUT_LINE(fnd_file.LOG,'Total Number of records updated: ' || v_reccnt);
else
    OPEN employee_banks_cur;

fnd_file.PUT_LINE(fnd_file.LOG, 'Employee_ID  Bank_Num   Scramble   Bank_Account_Num  Scramble' );  
  LOOP
    FETCH employee_banks_cur
    INTO v_emplid,
      v_banknum,
      v_bankname,
      v_bankaccountnum,
      v_bankbranchname
;

    EXIT  WHEN NOT employee_banks_cur % FOUND;


v_randbanknum  := to_char(abs(dbms_random.random));
if length(v_randbanknum) >= 9 then
   v_randbanknum := substr(v_randbanknum, 1, 9);
else
   v_randbanknum := LPAD(v_randbanknum, 9, '0');
end if;

v_randbankaccountnum := to_char(abs(dbms_random.random));

update xx_hr_employee_banks
set BANK_NUM = v_randbanknum, 
BANK_ACCOUNT_NUM = v_randbankaccountnum,
last_update_date = c_when,
last_updated_by = c_who
where LEGACY_EMPLOYEE_ID = v_emplid
and  BANK_NUM = v_banknum
and  BANK_NAME = v_bankname
and  BANK_ACCOUNT_NUM = v_bankaccountnum
and  BANK_BRANCH_NAME = v_bankbranchname
  ;
  
  
    
  v_reccnt := v_reccnt + 1;

fnd_file.PUT_LINE(fnd_file.LOG, v_emplid || ' ' || v_banknum || ' ' ||  v_randbanknum || ' ' || v_bankaccountnum || ' ' || v_randbankaccountnum  );
--  DBMS_OUTPUT.PUT_LINE( v_reccnt || ':' || v_emplid || ' ' || v_banknum || ' ' ||  v_randbanknum || ' ' || v_bankaccountnum || ' ' || v_randbankaccountnum  );
END LOOP;


    CLOSE employee_banks_cur;  
    DBMS_OUTPUT.PUT_LINE ('Total Number of records updated: ' || v_reccnt);
    fnd_file.PUT_LINE(fnd_file.LOG,'Total Number of records updated: ' || v_reccnt);

end if;

commit;
END XX_AP_BANK_SCRAMBLE;


/