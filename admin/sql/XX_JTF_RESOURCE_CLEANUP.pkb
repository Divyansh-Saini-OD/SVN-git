CREATE OR REPLACE
PACKAGE BODY "XX_JTF_RESOURCE_CLEANUP" AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_JTF_RESOURCE_CLEANUP                                  |
-- | Rice ID :                                                         |
-- | Description: This package contains the PROCEDURES that DELETE     |
-- |              Update end_Date of extra resource                    |
-- |                                                                   |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       04-Aug-08   Raj Jagarlamudi  Initial draft version       |
-- +===================================================================+

PROCEDURE UPDATE_END_DATE ( X_ERRBUF      OUT VARCHAR2,
                            X_RETCODE     OUT NUMBER) IS
begin
    begin
      update jtf_rs_resource_extns ext1
      set end_date_active = sysdate
      where ext1.category = 'EMPLOYEE'
      and   not exists ( select 'x' from jtf_rs_defresroles_vl
                   where role_type_code in ('CALLCENTER','SUPPORT','SALES','SALES_COMP','COLLECTIONS')
                    and role_resource_id = ext1.resource_id);
      
    exception
      when others then
        x_errbuf  := 'Update with errors,  '||SQLERRM ;
        x_retcode := 2 ;
    END;

    commit;
END; -- UPDATE_END_DATE
       
/***************************************************************************/
/**************************************************************************/

PROCEDURE DELETE_RESOURCE ( X_ERRBUF      OUT VARCHAR2,
                            X_RETCODE     OUT NUMBER,
                            P_COMMIT_FLAG IN VARCHAR2) IS

cursor ext1_cur is
select distinct ext1.resource_id
from jtf_rs_resource_extns ext1
where ext1.category = 'EMPLOYEE'
and   not exists ( select 'x' from jtf_rs_defresroles_vl
                   where role_resource_id = ext1.resource_id);

ext1_rec ext1_cur%rowtype;
ln_count        number := 0;
lc_message      varchar2(2000);
ln_err_cnt      number := 0;
ln_success_cnt  number := 0;
BEGIN
  BEGIN
    OPEN ext1_cur;
    LOOP
    FETCH ext1_cur into ext1_rec;
    exit when ext1_cur%notfound;
    
      -- delete from jtf_rs_resource_extns
      begin
        fnd_file.put_line(fnd_file.log, 'Deleting Resource: ' || ext1_rec.resource_id);
        
        delete from jtf_rs_resource_extns
        where resource_id = ext1_rec.resource_id;
        
         delete from jtf_rs_resource_extns_tl
         where resource_id = ext1_rec.resource_id;
         
         ln_success_cnt := ln_success_cnt + 1;
      exception
        when others then
           ln_err_cnt := ln_err_cnt + 1;
            x_errbuf  := 'Error while deleting Resource:'||ext1_rec.resource_id||'; '||SQLERRM ;
            x_retcode := 2 ; 
      end;
     
      ln_count      := ln_count + 1;
     
    END LOOP;
    IF NVL(P_COMMIT_FLAG,'N') = 'Y' THEN
        fnd_file.put_line(fnd_file.log, 'Commiting...   ');
        COMMIT;
    ELSE
        fnd_file.put_line(fnd_file.log, 'Rolling back...   ');
        ROLLBACK;
    END IF;
    CLOSE EXT1_CUR;
    exception
      when others then
        x_retcode := 2 ; 
        x_errbuf  := 'Error while deleting Resource:'||SQLERRM ;
    END;
    lc_message := 'No. of Records Submitted : '||ln_count ;
    fnd_file.put_line(fnd_file.log,lc_message);
    fnd_file.put_line(fnd_file.log,'No. Of Records completed Successfully: '||ln_success_cnt);
    fnd_file.put_line(fnd_file.log,'No. of Records failed : '||ln_err_cnt);
    
end; --delete resource

END;

/
show errors;
exit;