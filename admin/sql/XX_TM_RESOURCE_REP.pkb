SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_TM_RESOURCE_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_TM_RESOURCE_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_TM_RESOURCE_REP                                            |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Resource Details' with                        |
-- |                     resource details                                              |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    MAIN_PROC               This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  07-Mar-08   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS

----------------------------
--Declaring Global Constants
----------------------------

----------------------------
--Declaring Global Variables
----------------------------


-----------------------------------
--Declaring Global Record Variables
-----------------------------------

---------------------------------------
--Declaring Global Table Type Variables
---------------------------------------

-- +===================================================================+
-- | Name  : WRITE_LOG                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program log file                               |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

PROCEDURE write_log(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_log;
-- +===================================================================+
-- | Name  : WRITE_OUT                                                 |
-- |                                                                   |
-- | Description:       This Procedure shall write to the concurrent   |
-- |                    program output file                            |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE write_out(
                    p_message IN VARCHAR2
                   )
IS
---------------------------
--Declaring local variables
---------------------------
lc_error_message  VARCHAR2(2000);
lc_set_message    VARCHAR2(2000);

BEGIN

   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while writing to the log file.';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       WRITE_LOG(lc_error_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.WRITE_LOG'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );

END write_out;


-- +==============================================================================+
-- | Name  : Main_proc                                                            |
-- |                                                                              |
-- | Description      :  This custom package will get called from the concurrent  |
-- |                     program 'OD: TM Resource Details' with                   |
-- |                     resource details                                         |
-- |                                                                              |
-- +==============================================================================+

PROCEDURE Main_proc
            (
             x_errbuf               OUT NOCOPY VARCHAR2
             , x_retcode            OUT NOCOPY NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
ln_count               PLS_INTEGER := 0;
ln_postal_count        PLS_INTEGER := 0;
ln_index               PLS_INTEGER := 0;
lc_parent_terr_name    VARCHAR2(2000);
lc_set_message         VARCHAR2(2000);
lc_error_message       VARCHAR2(2000); 
ln_child_index         PLS_INTEGER;

-- ----------------------------------------------
-- Declare cursor to fetch Terralign - Territory 
-- ----------------------------------------------
CURSOR lcu_terr_rsc_dtls
IS
select 
jta.name terr_name, 
jta.row_count, 
jrre.source_name, 
JRS.SALESREP_NUMBER, 
jta_parent.name parent_name, 
JRRB.ATTRIBUTE15 division, 
jrgt.group_name, 
jrrt.role_name,
jrrb.attribute14  role_code,
jrrr.attribute15 legacy_id,
pj.name, 
jrre.resource_id
from
(select jta.terr_id, jta.name,jta.parent_territory_id, count(jtva.low_value_char) row_count
from ( select jta.terr_id, jta.orig_system_reference,jta.name,jta.parent_territory_id, level level1
from apps.jtf_terr_all jta 
start with name like 'Nor%' and sysdate between start_date_active and nvl(end_date_active,sysdate) 
connect by prior terr_id = parent_territory_id
) jta,
apps.jtf_terr_qualifiers_v jtqv,
apps.jtf_terr_values_all jtva
where jta.terr_id = jtqv.terr_id --and jta.name ='W101299'
and jtqv.qualifier_name = 'Postal Code'
and jtqv.qual_type_id <> -1001
and jtva.terr_qual_id = jtqv.terr_qual_id
and jta.level1=5
group by jta.terr_id, jta.parent_territory_id,jta.name
) jta,
apps.jtf_terr_rsc_all jtra ,
apps.jtf_rs_resource_extns jrre,
apps.JTF_RS_SALESREPS jrs, 
apps.jtf_terr_all jta_parent,
apps.jtf_rs_group_members jrgm, 
apps.jtf_rs_roles_b jrrb,
apps.jtf_rs_roles_tl jrrt,
apps.jtf_rs_groups_tl jrgt, 
apps.jtf_rs_groups_b jrgb,
apps.jtf_rs_group_usages jrgu,
apps.jtf_rs_role_relations jrrr,
apps.per_all_people_f papf,
apps.per_all_assignments_f paaf,
apps.per_jobs pj
where
jta.terr_id = jtra.terr_id 
and sysdate between jtra.start_date_active and nvl(jtra.end_date_active,sysdate)
and jrre.resource_id = jtra.resource_id
and jrs.resource_id = jrre.resource_id
and jta_parent.terr_id = jta.parent_territory_id
and jrgm.resource_id = jrre.resource_id
and nvl(jrgm.delete_flag,'N') ='N' 
and jrgm.group_member_id = jrrr.role_resourcE_id
and jrgb.group_id = jrgm.group_id 
and jrgt.group_id = jrgb.group_id 
and jrgt.language = userenv('LANG') 
and jrgt.group_id = jrgu.group_id 
and jrgu.usage ='SALES'
and jrrr.role_id = jrrb.role_id 
and jrrB.role_TYPE_CODE='SALES'
and jrrb.role_id = jrrt.role_id
and jrrt.language = userenv('LANG')  
and jrs.org_id =fnd_profile.value('ORG_ID')
and papf.person_id = jtra.person_id 
and sysdate between papf.effective_start_date and nvl(papf.effective_end_date,sysdate)
and papf.person_id = paaf.person_id 
and sysdate between paaf.effective_start_date and nvl(paaf.effective_end_date,sysdate)
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate)
and paaf.job_id = pj.job_id
and jrrb.member_flag='Y' and jrrb.attribute14 <> 'OT';
-- --------------------------------
-- Declaring Record Type Variables
-- --------------------------------
lcn_terr_count number:=0;
BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------

   WRITE_OUT(RPAD(' ',1,' ')||RPAD('Office Depot',90)||RPAD(' ',115,' ')||'Date: '||trunc(SYSDATE));
   WRITE_OUT(RPAD(' ',320,'-'));
   WRITE_OUT(RPAD(' ',142,' ')||RPAD('OD: Territory Resource Detail Report',60));
   WRITE_OUT(RPAD(' ',320,'-'));
   WRITE_OUT('');

       write_out(RPAD(' Territory Name',30)
                 ||RPAD(' Postal Count',20)
                 ||RPAD(' Parent Name',40)
                 ||RPAD(' Sales Rep Name',30)
                 ||RPAD(' Sales Rep Number',20)
                 ||RPAD(' Sales Legacy Id',20)
                 ||RPAD(' Sales Rep Role Code',20)
                 ||RPAD(' Sales Rep Role Name',20)
                 ||RPAD(' Sales Rep Division',20)
                 ||RPAD(' Sales Rep Group Name',30)
                 ||RPAD(' Sales Rep Job Name',50)
                 ||RPAD(' Sales Rep Resource Id',20));

       write_out(RPAD(' ',30,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',40,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',50,'-')                 
                 ||RPAD(' ',20,'-'));  
  
   --WRITE_OUT(RPAD(' ',300,'-'));
   For lcn_count in lcu_terr_rsc_dtls
   loop
       write_out(RPAD(nvl(lcn_count.terr_name,'(null)'),30)
                 ||RPAD(nvl(to_char(lcn_count.row_count),'(null)'),20)
                 ||RPAD(nvl(lcn_count.parent_name,'null'),40)
                 ||RPAD(nvl(lcn_count.source_name,'(null)'),30)
                 ||RPAD(nvl(lcn_count.SALESREP_NUMBER,'(null)'),20)
                 ||RPAD(nvl(lcn_count.legacy_id,'(null)'),20)
                 ||RPAD(nvl(lcn_count.role_code,'(null)'),20)
                 ||RPAD(nvl(lcn_count.role_name,'(null)'),20)
                 ||RPAD(nvl(lcn_count.division,'(null)'),20)
                 ||RPAD(nvl(lcn_count.group_name,'(null)'),30)
                 ||RPAD(nvl(lcn_count.name,'(null)'),50)                 
                 ||RPAD(nvl(to_char(lcn_count.resource_id),'(null)'),20)                 
                 ); 
        lcn_terr_count := lcn_terr_count+1;
   end loop;
   WRITE_OUT(RPAD(' ',320,'-'));  
   WRITE_OUT(RPAD(' ',100)||' Total number of Territories : '||lcn_terr_count);
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_set_message     :=  'Unexpected Error while creating the report';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_set_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_error_message := FND_MESSAGE.GET;
       x_errbuf         := lc_error_message;
       x_retcode        := 2 ;
       WRITE_LOG(x_errbuf);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.TERR_WITHOUT_RSC'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_TERR_SM_POSTAL_CODE_REP.TERR_WITHOUT_RSC'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );  
END Main_proc;

END XX_TM_RESOURCE_REP;
/
SHOW ERRORS;
--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================

