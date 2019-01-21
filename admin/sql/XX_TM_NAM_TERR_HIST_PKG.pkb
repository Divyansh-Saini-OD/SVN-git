CREATE OR REPLACE PACKAGE BODY XX_TM_NAM_TERR_HIST_PKG 
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_TM_NAM_TERR_HIST_PKG.pkb                                               |
-- | Description : Package Body to perform the create records in XX_TM_NAM_TERR_HISTORY_DTLS |
-- |               records based on conversion or interface mode.                            |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author              Remarks                                 |
-- |=======    ==========        =============       ========================                |
-- |DRAFT 1a   12-Mar-2008       jeevan babu           Initial draft version                 |
-- |           12/26/2008        Mohan Kalyanasundaram Defect 58/66 changes                  |
-- |           04/01/2009        Kishore Jena          Made Changes to stop creating         |
-- |                                                   duplicate assignment history records. |
--|            
-- |           10/07/2009        Prasad Devar         Made Changes to add prspectdefect 2551 |
-- |                                                                                         |
-- +=========================================================================================+
AS
  -- Global Variable
  
     
   --------------------------------------------------------------------------------------------
  --Procedure registered as Concurrent program to perform the reassignment of resource,role --
  -- and group on the basis of territory ID                                                 --
  --------------------------------------------------------------------------------------------

PROCEDURE Log_Exception ( p_program_name       IN  VARCHAR2
                         ,p_error_location     IN  VARCHAR2
                         ,p_error_message_code IN  VARCHAR2
                         ,p_error_msg          IN  VARCHAR2 )
IS

  ln_login     PLS_INTEGER           := FND_GLOBAL.Login_Id;
  ln_user_id   PLS_INTEGER           := FND_GLOBAL.User_Id;

BEGIN

  XX_COM_ERROR_LOG_PUB.log_error_crm
     (
      p_return_code             => FND_API.G_RET_STS_ERROR
     ,p_msg_count               => 1
     ,p_application_name        => 'XXCRM'
     ,p_program_type            => 'Api to Populate the History Table'
     ,p_program_name            => p_program_name
     ,p_module_name             => 'TM'
     ,p_error_location          => p_error_location
     ,p_error_message_code      => p_error_message_code
     ,p_error_message           => p_error_msg
     ,p_error_message_severity  => 'MAJOR'
     ,p_error_status            => 'ACTIVE'
     ,p_created_by              => ln_user_id
     ,p_last_updated_by         => ln_user_id
     ,p_last_update_login       => ln_login
     ,p_program_id              => G_REQUEST_ID
     );

END ;

procedure insert_record ( p_creation_date in date, p_start_date in date, x_record_count out number) 
is 

Cursor lcu_customer_assignment is
select DISTINCT 
-- XX_TM_NAM_TERR_HISTORY_DTLS_S.NEXTVAL record_id,
xtntd.named_acct_terr_id, 
xtnted.named_acct_terr_entity_id, 
xtntrd.named_acct_terr_rsc_id,
xtnted.entity_id PARTY_SITE_ID, 
xtntrd.resource_id, 
xtntrd.resource_role_id, 
xtntrd.group_id,
jrrb.attribute15 division,
xtntrd.status,
nvl(p_start_date,xtnted.start_date_active) START_DATE_ACTIVE,
--fnd_global.user_id CREATED_BY,
--SYSDATE CREATION_DATE,
--fnd_global.user_id LAST_UPDATED_BY,
--SYSDATE LAST_UPDATE_DATE,
--fnd_global.user_id LAST_UPDATE_LOGIN,
hp.party_name party_name,
hps.party_site_number party_site_number
from 
xx_tm_nam_terr_defn xtntd,
xx_tm_nam_terr_entity_dtls xtnted, 
xx_tm_nam_terr_rsc_dtls xtntrd,
jtf_rs_group_members jrgm, 
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb,
hz_parties hp, 
hz_party_sites hps
where
hp.party_id = hps.party_id
and hp.party_type='ORGANIZATION'
--and hp.attribute13='CUSTOMER' -- commemted by Prasad on oct 7-09 (defect 2551 )
--and hp.status ='A' -- Mohan commented this line 12/26/2008
--and hps.status='A' -- Mohan commented this line 12/26/2008
and hps.party_site_id = xtnted.entity_id 
and xtntd.named_acct_terr_id = xtnted.named_acct_terr_id 
and xtnted.named_acct_terr_id = xtntrd.named_acct_terr_id 
and (TRUNC(xtnted.creation_date) >= nvl(p_creation_date, trunc(xtnted.creation_date)) 
or TRUNC(xtntrd.creation_date) >= nvl(p_creation_date, trunc(xtntrd.creation_date)))
--and xtnted.status ='A' -- Mohan commented this line 12/26/2008
--and xtntrd.status ='A' -- Mohan commented this line 12/26/2008
--and xtntd.status ='A'  -- Mohan commented this line 12/26/2008
and xtnted.entity_type ='PARTY_SITE'
and jrgm.resourcE_id = xtntrd.resource_id 
and jrgm.group_id = xtntrd.group_id 
--and nvl(jrgm.delete_flag,'N') ='N' -- Mohan commented this line 12/26/2008
and jrgm.group_member_id = jrrr.role_resourcE_id 
--and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) -- Mohan commented this line 12/26/2008
and jrrr.role_id = xtntrd.resourcE_role_id
and jrrb.role_id = jrrr.role_id
and jrrb.attribute15 ='BSD'
and not exists
( select 1 from XX_TM_NAM_TERR_HISTORY_DTLS
where party_site_id = xtnted.entity_id and status ='A');

cursor lcu_resource_name (p_resource_id in number) is 
select source_name 
from jtf_rs_resource_extns 
where resource_id = p_resource_id ;

cursor lcu_role_name (p_role_id in number) is
select role_name from jtf_rs_roles_tl 
where role_id = p_role_id 
and language = userenv('LANG');

TYPE ltable_customer_assign is table of lcu_customer_assignment%ROWTYPE INDEX BY BINARY_INTEGER;
Type ltable_record_id     is table of number index by binary_integer;
Type ltable_division      is table of varchar2(100) index by binary_integer;
Type ltable_status        is table of varchar2(2) index by binary_integer;
Type ltable_start_date    is table of date index by binary_integer;

lc_source_name             jtf_rs_resource_extns.source_name%type;
lc_role_name               jtf_rs_roles_tl.role_name%type;
lc_table_bulk_limit number :=NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),200);
lc_table_customer_assign ltable_customer_assign;
lc_table_record_id       ltable_record_id;
lc_table_terr_id         ltable_record_id;
lc_table_entity_id       ltable_record_id;
lc_table_rsc_id          ltable_record_id;
lc_table_party_site_id   ltable_record_id;
lc_table_resource_id     ltable_record_id;
lc_table_role_id         ltable_record_id;
lc_table_group_id        ltable_record_id;
lc_table_division        ltable_division;
lc_table_status          ltable_status;
lc_table_start_date      ltable_start_date;
lc_table_created         ltable_record_id;
lc_table_creation        ltable_start_date;
lc_table_last_update     ltable_record_id;
lc_table_last_date       ltable_start_date;
lc_table_last_login      ltable_record_id;
begin 
x_record_count:=0;
--FND_FILE.PUT_LINE(FND_FILE.log,' Step 1');
FND_FILE.PUT_LINE(FND_FILE.output,rpad('Office Depot ',20,' ')||rpad(' ',50)|| rpad(to_char(sysdate,'DD-MON-YY'),15));
FND_FILE.PUT_LINE(FND_FILE.output,rpad(' ',85,'-'));
FND_FILE.PUT_LINE(FND_FILE.log,rpad('Site Number ',50)||'   '||rpad('Customer Name',50));
--FND_FILE.PUT_LINE(FND_FILE.log,' Step 1');
open lcu_customer_assignment;
--FND_FILE.PUT_LINE(FND_FILE.log,' Step 2');
x_record_count:=0;
loop 
fetch lcu_customer_assignment BULK COLLECT into lc_table_customer_assign LIMIT lc_table_bulk_limit;
--FND_FILE.PUT_LINE(FND_FILE.log,' Step 3'||lc_table_customer_assign.count);
if lc_table_customer_assign.count >0 then 
for i in lc_table_customer_assign.first .. lc_table_customer_assign.last 
loop 
lc_source_name:=null;
lc_role_name:=null;
begin 
open lcu_resource_name(lc_table_customer_assign(i).resource_id); 
fetch lcu_resource_name into lc_source_name;
close lcu_resource_name;
exception 
when others then 
null;
end; 
begin 
open lcu_role_name(lc_table_customer_assign(i).resource_role_id);
fetch lcu_role_name into lc_role_name;
close lcu_role_name;
exception 
when others then 
null;
end;

/*FND_FILE.PUT_LINE(FND_FILE.log,rpad(lc_table_customer_assign(i).party_site_number,50,' ')
                                  ||rpad(lc_table_customer_assign(i).party_name,100,' ')
                                  ||rpad(lc_source_name,50,' ') 
                                  ||rpad(lc_role_name,50,' '));

*/
FND_FILE.PUT_LINE(FND_FILE.log,lc_table_customer_assign(i).party_site_number ||'   '||
                                lc_table_customer_assign(i).party_name||'   '||
                                lc_sourcE_name ||'   '||
                                lc_role_name );
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 4');                                
--lc_table_record_id(i)     :=lc_table_customer_assign(i).record_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 5');
lc_table_terr_id(i)       :=lc_table_customer_assign(i).named_acct_terr_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 6');
lc_table_entity_id(i)     :=lc_table_customer_assign(i).named_acct_terr_entity_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 7');
lc_table_rsc_id(i)        :=lc_table_customer_assign(i).named_acct_terr_rsc_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 8');
lc_table_party_site_id(i) :=lc_table_customer_assign(i).party_site_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 9');
lc_table_resource_id(i)   :=lc_table_customer_assign(i).resource_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 10');
lc_table_role_id(i)       :=lc_table_customer_assign(i).resource_role_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 11');
lc_table_group_id(i)      :=lc_table_customer_assign(i).group_id;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 12');
lc_table_division(i)      :=lc_table_customer_assign(i).division;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 13');
lc_table_status(i)        :=lc_table_customer_assign(i).status;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 14');
lc_table_start_date(i)    :=lc_table_customer_assign(i).start_date_active;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 15');
--lc_table_created(i)       :=lc_table_customer_assign(i).created_by;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 16');
--lc_table_creation(i)      :=lc_table_customer_assign(i).creation_date;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 17');
--lc_table_last_update(i)   :=lc_table_customer_assign(i).last_updated_by;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 18');
--lc_table_last_date(i)     :=lc_table_customer_assign(i).last_update_date;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 19');
--lc_table_last_login(i)    :=lc_table_customer_assign(i).last_update_login;
--FND_FILE.PUT_LINE(FND_FILE.log,'Step 20');
x_record_count:= x_record_count +1;
end loop;


forall lcn_index in  lc_table_customer_assign.first .. lc_table_customer_assign.last 
INSERT INTO XX_TM_NAM_TERR_HISTORY_DTLS
(record_id ,                 
named_acct_terr_id,         
named_acct_terr_entity_id,  
named_acct_terr_rsc_id,     
party_site_id,              
resource_id,                
resource_role_id,           
group_id,                   
division,                   
status,                     
start_date_active,
created_by,                 
creation_date,              
last_updated_by,            
last_update_date,           
last_update_login) VALUES (
XX_TM_NAM_TERR_HISTORY_DTLS_S.NEXTVAL ,   
lc_table_terr_id(lcn_index)  ,    
lc_table_entity_id(lcn_index),    
lc_table_rsc_id(lcn_index)   ,    
lc_table_party_site_id(lcn_index),
lc_table_resource_id(lcn_index),  
lc_table_role_id(lcn_index)    ,  
lc_table_group_id(lcn_index) ,    
lc_table_division(lcn_index) ,    
lc_table_status(lcn_index),       
lc_table_start_date(lcn_index),   
fnd_global.user_id,
SYSDATE,
fnd_global.user_id,
SYSDATE,
fnd_global.user_id
);
--lc_table_created(lcn_index),      
--lc_table_creation(lcn_index),     
--lc_table_last_update(lcn_index),  
--lc_table_last_date(lcn_index),    
--lc_table_last_login(lcn_index));
commit;
end if;
exit when lcu_customer_assignment%notfound; 
end loop;
close lcu_customer_assignment;
FND_FILE.PUT_LINE(FND_FILE.output,'');
FND_FILE.PUT_LINE(FND_FILE.output,'');
--rollback;
/*
INSERT INTO XX_TM_NAM_TERR_HISTORY_DTLS
(
RECORD_ID ,                 
NAMED_ACCT_TERR_ID,         
NAMED_ACCT_TERR_ENTITY_ID,  
NAMED_ACCT_TERR_RSC_ID,     
PARTY_SITE_ID,              
RESOURCE_ID,                
RESOURCE_ROLE_ID,           
GROUP_ID,                   
DIVISION,                   
STATUS,                     
START_DATE_ACTIVE,
CREATED_BY,                 
CREATION_DATE,              
LAST_UPDATED_BY,            
LAST_UPDATE_DATE,           
LAST_UPDATE_LOGIN)
select 
XX_TM_NAM_TERR_HISTROY_DTLS_S.NEXTVAL,
xtntd.named_acct_terr_id, 
xtnted.named_acct_terr_entity_id, 
xtntrd.named_acct_terr_rsc_id,
xtnted.entity_id, 
xtntrd.resource_id, 
xtntrd.resourcE_role_id, 
xtntrd.group_id,
jrrb.attribute15,
xtntrd.status,
nvl(p_start_date,xtnted.start_date_active),
fnd_global.user_id,
SYSDATE,
fnd_global.user_id,
SYSDATE,
fnd_global.user_id
from 
xx_tm_nam_terr_defn xtntd,
xx_tm_nam_terr_entity_dtls xtnted, 
xx_tm_nam_terr_rsc_dtls xtntrd,
jtf_rs_group_members jrgm, 
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb,
hz_parties hp, 
hz_party_sites hps
where
hp.party_id = hps.party_id
and hp.party_type='ORGANIZATION'
--and hp.attribute13='CUSTOMER' -- commemted by Prasad on oct 7-09 (defect 2551 )
and hp.status ='A'
and hps.status='A'
and hps.party_site_id = xtnted.entity_id 
and xtntd.named_acct_terr_id = xtnted.named_acct_terr_id 
and xtnted.named_acct_terr_id = xtntrd.named_acct_terr_id 
and (TRUNC(xtnted.creation_date) >= nvl(p_creation_date, trunc(xtnted.creation_date)) 
or TRUNC(xtntrd.creation_date) >= nvl(p_creation_date, trunc(xtntrd.creation_date)))
and xtnted.status ='A'
and xtntrd.status ='A'
and xtntd.status ='A'
and xtnted.entity_type ='PARTY_SITE'
and jrgm.resourcE_id = xtntrd.resource_id 
and jrgm.group_id = xtntrd.group_id 
and nvl(jrgm.delete_flag,'N') ='N'
and jrgm.group_member_id = jrrr.role_resourcE_id 
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate)
and jrrr.role_id = xtntrd.resourcE_role_id
and jrrb.role_id = jrrr.role_id
and jrrb.attribute15 ='BSD'
and not exists
( select 1 from XX_TM_NAM_TERR_HISTORY_DTLS
where party_site_id = xtnted.entity_id )
and rownum <10;

*/

--x_record_count := sql%rowcount;

EXCEPTION 
WHEN OTHERS THEN 
FND_FILE.PUT_LINE(FND_FILE.log,SQLERRM);
Log_Exception ( 
 p_program_name       =>  'XX_TM_NAM_TERR_HIST_PKG.INSERT_RECORD'
,p_error_location     =>  'XX_TM_NAM_TERR_HIST_PKG.INSERT_RECORD'
,p_error_message_code =>  'E'
,p_error_msg          =>  SQLERRM
);
END INSERT_RECORD;

PROCEDURE MAIN_CONV_PROC (
                           X_ERRBUF  OUT NOCOPY VARCHAR2,
                           X_RETCODE OUT NOCOPY NUMBER
                           )
is
ld_creation_date date := null;
ln_record_count number:=0;
ld_start_date    date ;
begin 

   BEGIN
   
        SELECT to_date(FPOV.profile_option_value)
        INTO   ld_start_date
        FROM   fnd_profile_option_values FPOV
               , fnd_profile_options FPO
        WHERE  FPO.profile_option_id = FPOV.profile_option_id
        AND    FPO.application_id = FPOV.application_id
        AND    FPOV.level_id = G_LEVEL_ID
        AND    FPOV.level_value = G_LEVEL_VALUE
        AND    FPOV.profile_option_value IS NOT NULL
        AND    FPO.profile_option_name = 'OD_TM_NAM_RETRO_START_DATE';
   
   EXCEPTION
      WHEN OTHERS THEN
          ld_start_date := null;
          X_ERRBUF:='OD: Start date for Retro Assignment profile isn''t setup';
          X_RETCODE :=2;
          return;
   END;
APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,' Calling insert_record api with ld_creation_date => '|| ld_creation_date 
                                     ||' ld_start_date=>   '||ld_start_date);


insert_record( p_creation_date => ld_creation_date,
               p_start_date    => ld_start_date,
               x_record_count  => ln_record_count);

APPS.FND_FILE.PUT_LINE(FND_FILE.output,'Number of records created in Conversion :' || ln_record_count);

EXCEPTION 
WHEN OTHERS THEN 
Log_Exception ( 
 p_program_name       =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_CONV_PROC'
,p_error_location     =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_CONV_PROC'
,p_error_message_code =>  'E'
,p_error_msg          =>  SQLERRM
);
APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,SQLERRM);

end MAIN_CONV_PROC;

PROCEDURE MAIN_INTER_PROC (
                           X_ERRBUF  OUT NOCOPY VARCHAR2,
                           X_RETCODE OUT NOCOPY NUMBER
                         )
is 
ld_creation_date date := sysdate;
ld_start_date    date ;
ln_record_count number:=0;
lc_error_message varchar2(1000);
ld_sysdate date; -- For defect 14781. Stores the time when the prog. starts inserting records to be saved in profile.
		 -- Since the records created during the insert_record is being ignored.
begin 
   BEGIN
   
        SELECT to_date(FPOV.profile_option_value)
        INTO   ld_creation_date
        FROM   fnd_profile_option_values FPOV
               , fnd_profile_options FPO
        WHERE  FPO.profile_option_id = FPOV.profile_option_id
        AND    FPO.application_id = FPOV.application_id
        AND    FPOV.level_id = G_LEVEL_ID
        AND    FPOV.level_value = G_LEVEL_VALUE
        AND    FPOV.profile_option_value IS NOT NULL
        AND    FPO.profile_option_name = 'OD_TM_NAM_RETRO_INTERFACE_DATE';
   
   EXCEPTION
      WHEN OTHERS THEN
          ld_creation_date := sysdate;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: TM Retro Interface Last Execution Date profile isn''t setup');
          --X_RETCODE :=2;
          --return;
   END;
   BEGIN 
        select 
        start_date 
        INTO ld_start_date
        from 
        gl_periods
        where 
        period_type='41'
        and trunc(Sysdate) between start_date and end_date;     
   EXCEPTION 
     When others then 
          --lc_creation_date := sysdate;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'Not able to derive the Start Date for Assignment');
          X_RETCODE :=2;
          return;     
   END;
APPS.FND_FILE.PUT_LINE(FND_FILE.LOG,' Calling insert_record api with ld_creation_date => '|| ld_creation_date 
                                     ||' ld_start_date=>   '||ld_start_date);
                                     
ld_sysdate := sysdate; -- for defect 14781                                     
insert_record( p_creation_date => ld_creation_date,
               p_start_date    => ld_start_date,
               x_record_count  => ln_record_count);
               

APPS.FND_FILE.PUT_LINE(FND_FILE.output,'Number of records created in Interface :' || ln_record_count);

   -- To update the profile
   IF FND_PROFILE.SAVE('OD_TM_NAM_RETRO_INTERFACE_DATE',to_char(ld_sysdate,'dd-mon-yy'),'SITE') THEN -- for defect 14781 changed sysdate to ld_sysdate
      FND_FILE.PUT_LINE(FND_FILE.LOG,' OD: TM Retro Interface Last Execution Date profile is updated with '||to_char(ld_sysdate,'dd-mon-yy')); -- for defect 14781 changed sysdate to ld_sysdate
      COMMIT;
   
   ELSE
   
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0147_PROFILE_ERR');
       lc_error_message := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       Log_Exception ( 
       p_program_name       =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_INTER_PROC'
       ,p_error_location     =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_INTER_PROC'
       ,p_error_message_code =>  'E'
       ,p_error_msg          =>  lc_error_message
       );
       X_RETCODE := 1;
   
   END IF;
EXCEPTION 
WHEN OTHERS THEN 
Log_Exception ( 
 p_program_name       =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_INTER_PROC'
,p_error_location     =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_INTER_PROC'
,p_error_message_code =>  'E'
,p_error_msg          =>  SQLERRM
);

end MAIN_INTER_PROC;

PROCEDURE MAIN_CUST_PROC(
                           X_ERRBUF  OUT NOCOPY VARCHAR2,
                           X_RETCODE OUT NOCOPY NUMBER
                         )
IS 
--Cursor for retrieve the mistmatch customer assignment record
-- created by customer interface concurrent program 
Cursor lcu_customer_assign (p_creation_date in date) is 
SELECT xcscau.batch_id,
xcscau.record_id         cust_record_id,
xcscau.party_site_id,
xcscau.resource_id       cust_resource_id,
xcscau.role_id           cust_role_id,
xcscau.rsc_group_id      cust_group_id,
xtntrd.resource_id       entity_resource_id,
xtntrd.resource_role_id  entity_role_id,
xtntrd.group_id          entity_group_id,
xtnted.start_date_active entity_start_date,
jrrb.attribute15         division,
xtnthd.record_id         history_record_id,
xtnthd.resource_id       history_resource_id,
xtnthd.resource_role_id  history_role_id,
xtnthd.group_id          history_group_id,
xtnthd.start_date_active history_start_date 
FROM
apps.xx_cdh_solar_batch_id xcsbi, 
apps.xx_cdh_solar_cust_asgn_update xcscau, 
apps.xx_tm_nam_terr_defn xtntd, 
apps.xx_tm_nam_terr_entity_dtls xtnted, 
apps.xx_tm_nam_terr_rsc_dtls xtntrd,
apps.xx_tm_nam_terr_history_dtls xtnthd, 
apps.jtf_rs_roles_b jrrb 
WHERE
xcsbi.batch_id = xcscau.batch_id 
AND xcscau.error_code = 'S'
AND xcsbi.batch_name like 'SOLAR CUSTOMER ASSIGNMENT INTERFACE%'
AND trunc(xcsbi.CREATION_DATE) = nvl(p_creation_date,trunc(xcsbi.CREATION_DATE))
AND xtnthd.party_site_id = xcscau.party_site_id 
AND xtnthd.status ='A'
AND xtntd.named_Acct_terr_id= xtnted.named_acct_terr_id 
AND xtnted.named_acct_Terr_id =xtntrd.named_Acct_terr_id 
AND xtntd.status ='A'
AND xtnted.status ='A'
AND xtntrd.status ='A'
AND sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate)
AND sysdate between xtnted.start_date_active and nvl(xtnted.end_date_active,sysdate)
AND sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate)
AND xtnted.entity_type='PARTY_SITE'
AND xtnted.entity_id = xcscau.party_site_id 
AND xtntrd.resource_id =xcscau.resource_id 
AND xtntrd.resource_role_id = xcscau.role_id 
AND xtntrd.group_id = xcscau.rsc_group_id 
AND jrrb.role_id =xtntrd.resource_role_id 
AND jrrb.attribute15 ='BSD'
AND xtnthd.resource_id <> xcscau.resource_id;

--Cursor to validate the party site, resource, group and role combination 
cursor c_party_resc_valid(p_party_site_id in number, 
                          p_resource_id in number, 
                          p_group_id in number,
                          p_role_id in number)
is                          
select 
count(1)
from 
apps.hz_parties hp,
apps.hz_party_sites hps, 
apps.jtf_rs_group_members jrgm, 
apps.jtf_rs_role_relations jrrr, 
apps.jtf_rs_roles_b jrrb 
where
hp.party_id = hps.party_id 
and hp.party_type='ORGANIZATION'
and hp.status ='A'
and hps.status ='A'
and hps.party_site_id = p_party_site_id
and jrgm.group_member_id = jrrr.role_resource_id 
and jrgm.group_id = p_group_id 
and nvl(jrgm.delete_flag,'N') ='N'
and jrgm.resource_id = p_resource_id
and jrrr.role_id = jrrb.role_id 
and sysdate between jrrr.start_date_active and nvl( jrrr.end_date_active,sysdate)
and jrrr.role_id = p_role_id;

type lt_customer_assign_pty is table of lcu_customer_assign%rowtype
index by binary_integer; ltu_customer_assign_pty lt_customer_assign_pty;

--lru_current_record_assign lcu_current_assign%rowtype;
--lru_temp_current_rec      lcu_current_assign%rowtype;

--lru_history_record_assign lcu_history_assign%rowtype;
--lru_temp_history_rec      lcu_history_assign%rowtype;

ln_record_count     number:=0;
ln_sucess_count     number:=0;
ln_error_count      number:=0;
lc_table_bulk_limit number :=500;
ld_start_date    date;
ld_creation_date date;
lc_delete_flag   char;
ln_count         number;
lc_error_message varchar2(1000);
BEGIN
 BEGIN
   
        SELECT to_date(FPOV.profile_option_value)
        INTO   ld_creation_date
        FROM   fnd_profile_option_values FPOV
               , fnd_profile_options FPO
        WHERE  FPO.profile_option_id = FPOV.profile_option_id
        AND    FPO.application_id = FPOV.application_id
        AND    FPOV.level_id = G_LEVEL_ID
        AND    FPOV.level_value = G_LEVEL_VALUE
        AND    FPOV.profile_option_value IS NOT NULL
        AND    FPO.profile_option_name = 'OD_TM_NAM_RETRO_CUST_INTER_DATE';
   
   EXCEPTION
      WHEN OTHERS THEN
          ld_creation_date := null;
          FND_FILE.PUT_LINE(FND_FILE.LOG,'OD: TM Retro Customer Interface Last Execution Date profile isn''t setup');
          --X_RETCODE :=2;
          --return;
   END;
   
--ld_creation_date:='29-aug-08';--trunc(sysdate);
open lcu_customer_assign(ld_creation_date);
loop fetch lcu_customer_assign bulk collect into ltu_customer_assign_pty
LIMIT lc_table_bulk_limit;
 
 if ltu_customer_assign_pty.count > 0 then

  for i in ltu_customer_assign_pty.first .. ltu_customer_assign_pty.last
  loop
 

  APPS.FND_FILE.PUT_LINE(FND_FILE.log,
    --dbms_output.put_line(
        ltu_customer_assign_pty(i).cust_record_id     ||' '||
        ltu_customer_assign_pty(i).party_site_id      ||' '||
        ltu_customer_assign_pty(i).cust_resource_id   ||' '||
        ltu_customer_assign_pty(i).cust_role_id       ||' '||
        ltu_customer_assign_pty(i).cust_group_id      ||' '||
        ltu_customer_assign_pty(i).entity_start_date  ||' '||
        ltu_customer_assign_pty(i).division           ||' '||
        ltu_customer_assign_pty(i).history_record_id  ||' '||
        ltu_customer_assign_pty(i).history_resource_id||' '||
        ltu_customer_assign_pty(i).history_role_id    ||' '||
        ltu_customer_assign_pty(i).history_group_id   ||' '||
        ltu_customer_assign_pty(i).history_start_date);
  ln_count:=0;
  open c_party_resc_valid(p_party_site_id => ltu_customer_assign_pty(i).party_site_id
                          ,p_resource_id  => ltu_customer_assign_pty(i).cust_resource_id
                          ,p_group_id     => ltu_customer_assign_pty(i).cust_group_id
                          ,p_role_id      => ltu_customer_assign_pty(i).cust_role_id);
  
  fetch c_party_resc_valid into ln_count; 
  close c_party_resc_valid;
  
  If ln_count >= 1 then 
   ld_start_date:=null;
   lc_delete_flag:=null;
   if trunc(ltu_customer_assign_pty(i).entity_start_date)-1  <=
      trunc(ltu_customer_assign_pty(i).history_start_date) then
      
      ld_start_date := ltu_customer_assign_pty(i).history_start_date;
      lc_delete_flag:='Y';
   else
      ld_start_date:=trunc(ltu_customer_assign_pty(i).entity_start_date)-1;
   end if;
 
   update xx_tm_nam_terr_history_dtls
   set status ='I',
   end_date_active = ld_start_date,
   delete_flag = lc_delete_flag
   where record_id = ltu_customer_assign_pty(i).history_record_id;
 
   INSERT INTO xx_tm_nam_terr_history_dtls
   (record_id ,                 
   named_acct_terr_id,         
   named_acct_terr_entity_id,  
   named_acct_terr_rsc_id,     
   party_site_id,              
   resource_id,                
   resource_role_id,           
   group_id,                   
   division,                   
   status,                     
   start_date_active,
   created_by,                 
   creation_date,              
   last_updated_by,            
   last_update_date,           
   last_update_login)
   select
   XX_TM_NAM_TERR_HISTORY_DTLS_S.NEXTVAL, 
   xtntd.named_acct_terr_id, 
   xtnted.named_acct_terr_entity_id, 
   xtntrd.named_acct_terr_rsc_id, 
   xtnted.entity_id, 
   xtntrd.resource_id, 
   xtntrd.resourcE_role_id, 
   xtntrd.group_id, 
   jrrb.attribute15, 
   xtntrd.status, 
   ld_start_date, 
   fnd_global.user_id, 
   SYSDATE, 
   fnd_global.user_id, 
   SYSDATE,
   fnd_global.user_id
   FROM
   apps.xx_tm_nam_terr_defn xtntd,
   apps.xx_tm_nam_terr_entity_dtls xtnted,
   apps.xx_tm_nam_terr_rsc_dtls xtntrd,
   apps.jtf_rs_group_members jrgm,
   apps.jtf_rs_role_relations jrrr,
   apps.jtf_rs_roles_b jrrb,
   apps.hz_parties hp,
   apps.hz_party_sites hps
   WHERE
   hp.party_id = hps.party_id
   AND hp.party_type='ORGANIZATION'
   --AND hp.attribute13='CUSTOMER' -- commemted by Prasad on oct 7-09 (defect 2551 )
   AND hp.status ='A'
   AND hps.status='A'
   AND hps.party_site_id = xtnted.entity_id 
   AND xtntd.named_acct_terr_id =xtnted.named_acct_terr_id 
   AND xtnted.named_acct_terr_id =xtntrd.named_acct_terr_id 
   AND xtnted.status ='A'
   AND xtntrd.status ='A'
   AND xtntd.status ='A'
   AND xtnted.entity_type ='PARTY_SITE'
   AND xtnted.entity_id = ltu_customer_assign_pty(i).party_site_id
   AND jrgm.resourcE_id = xtntrd.resource_id 
   AND jrgm.group_id = xtntrd.group_id 
   AND nvl(jrgm.delete_flag,'N') ='N'
   AND jrgm.group_member_id = jrrr.role_resourcE_id 
   AND sysdate between jrrr.start_date_active  and nvl(jrrr.end_date_active,sysdate)
   AND jrrr.role_id = xtntrd.resourcE_role_id 
   AND jrrb.role_id =   jrrr.role_id 
   AND jrrb.attribute15 ='BSD'
   AND NOT EXISTS
   ( SELECT 1 FROM xx_tm_nam_terr_history_dtls 
     WHERE party_site_id = xtnted.entity_id AND status ='A' );
   ln_sucess_count := ln_sucess_count +1;
  ELSE
  
   ln_error_count  := ln_error_count +1;
   APPS.FND_FILE.PUT_LINE(FND_FILE.log,ltu_customer_assign_pty(i).party_site_id
                                      ||' Party Site is invalid or Resource, role ,group combination is invalid');
  END IF;
  ln_record_count := ln_record_count+1;
  END LOOP;
  END IF;--ltu_customer_assign_pty.count > 0 
 EXIT WHEN lcu_customer_assign%notfound;  
 END LOOP;

 close lcu_customer_assign; 
 APPS.FND_FILE.PUT_LINE(FND_FILE.output,'Total Number of records processed :'||ln_record_count);
 APPS.FND_FILE.PUT_LINE(FND_FILE.output,'Total Number of successful records:'||ln_sucess_count);
 APPS.FND_FILE.PUT_LINE(FND_FILE.output,'Total Number of error records     :'||ln_error_count);
 IF FND_PROFILE.SAVE('OD_TM_NAM_RETRO_CUST_INTER_DATE',to_char(sysdate,'dd-mon-yy'),'SITE') THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,' OD: TM Retro Customer Interface Last Execution Date profile is updated with '||to_char(sysdate,'dd-mon-yy'));
      COMMIT;
   
   ELSE 
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0147_PROFILE_ERR');
       lc_error_message := FND_MESSAGE.GET;
       FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
       Log_Exception ( 
       p_program_name       =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_CUST_PROC'
       ,p_error_location     =>  'XX_TM_NAM_TERR_HIST_PKG.MAIN_CUST_PROC'
       ,p_error_message_code =>  'E'
       ,p_error_msg          =>  lc_error_message
       );
       X_RETCODE := 1;
   END IF;   
END MAIN_CUST_PROC;
END XX_TM_NAM_TERR_HIST_PKG;

/
