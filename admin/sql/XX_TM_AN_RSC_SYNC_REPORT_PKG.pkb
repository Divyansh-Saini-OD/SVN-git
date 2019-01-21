SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_TM_AN_RSC_SYNC_REPORT_PKG package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_TM_AN_RSC_SYNC_REPORT_PKG
 -- +===================================================================================== +
 -- |                  Office Depot - Project Simplify                                     |
 -- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization                          |
 -- +===================================================================================== +
 -- |                                                                                      |
 -- | Name             : XX_TM_RM_RESOURCE_GROUPS_PKG                                      |
 -- | Description      : This custom package extracts the resource details                 |
 -- |                    from resource manager and prints to a log output file             |
 -- |                                                                                      |
 -- | This package contains the following sub programs:                                    |
 -- | =================================================                                    |
 -- |Type         Name                  Description                                        |
 -- |=========    ===========           ================================================   |
 -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
 -- |                                   the  resource details                              |
 -- |                                           .                                          |
 -- |Change Record:                                                                        |
 -- |===============                                                                       |
 -- |Version   Date         Author           Remarks                                       |
 -- |=======   ==========   =============    ============================================= |
 -- |Draft 1a  21-Apr-2008  Gowri Nagarajan  Initial draft version                         |
 -- +===================================================================================== +
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
                                          , p_program_name           => 'XX_JTF_UNASSIGN_PTY_SITE_REP.WRITE_LOG'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSIGN_PTY_SITE_REP.WRITE_LOG'
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
-- +===================================================================+
-- | Name  : print_display                                             |
-- |                                                                   |
-- | Description:       This is the private procedure to print the     |
-- |                    details of the record in the log file          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE print_display(
                          p_sales_rep_id     NUMBER
                        , p_sales_number     VARCHAR2
                        , p_sales_name       VARCHAR2
                        , p_sales_legacy_id  VARCHAR2
                        , p_tm_group_id      VARCHAR2
                        , p_tm_role_id       VARCHAR2
                        , p_tm_start_date    VARCHAR2
                        , p_tm_end_date      VARCHAR2
                        , p_rm_group_id      VARCHAR2
                        , p_rm_role_id       VARCHAR2
                        , p_rm_start_date    VARCHAR2
                        , p_rm_end_date      VARCHAR2
                        , p_exception        VARCHAR2                         
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
       
       write_out(RPAD(NVL(to_char(p_sales_rep_id),' (null)'),20)||chr(9)
                 ||RPAD(NVL(p_sales_number,' (null)'),30)||chr(9)
                 ||RPAD(NVL(p_sales_name,' (null)'),50)||chr(9)
                 ||RPAD(NVL(p_sales_legacy_id,' (null)'),30)||chr(9)
                 ||RPAD(NVL(p_rm_group_id,' (null)'),30)||chr(9)
                 ||RPAD(NVL(p_rm_role_id,' (null)'),30)||chr(9)
                 ||RPAD(NVL(p_rm_start_date,' (null)'),15)||chr(9)
                 ||RPAD(NVL(p_rm_end_date,' (null)'),15)||chr(9)               
                 ||RPAD(NVL(p_tm_group_id,' (null)'),30)||chr(9)
                 ||RPAD(NVL(p_tm_role_id,' (null)'),30)||chr(9)
                 ||RPAD(NVL(p_tm_start_date,' (null)'),15)||chr(9)
                 ||RPAD(NVL(p_tm_end_date,' (null)'),15)||chr(9)
                 ||RPAD(NVL(p_exception,' (null)'),50)||chr(9)
                 );            
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_err_message     :=  'Unexpected Error in procedure: PRINT_DISPLAY';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
       write_log(lc_message);
       XX_COM_ERROR_LOG_PUB.log_error_crm(
                                          p_return_code              => FND_API.G_RET_STS_ERROR 
                                          , p_application_name       => G_APPLICATION_NAME
                                          , p_program_type           => G_PROGRAM_TYPE
                                          , p_program_name           => 'XX_JTF_UNASSGN_PST_EXP_REP.PRINT_DISPLAY'
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSGN_PST_EXP_REP.PRINT_DISPLAY' 
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_message
                                          , p_error_message_severity => G_MEDIUM_ERROR_MSG_SEVERTY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END print_display;

    -- +===================================================================== +
    -- | Name       : MAIN_PROC                                               |
    -- |                                                                      |
    -- | Description: This procedure will be used to extract the resource     |
    -- |              information                                             |
    -- |                                                                      |
    -- | Parameters : p_resource_id   IN  GROUP_ID                            |
    -- |              x_retcode  OUT Holds '0','1','2'                        |
    -- |              x_errbuf   OUT Holds the error message                  |
    -- +======================================================================+

PROCEDURE MAIN_PROC
            (
             x_errbuf         OUT NOCOPY VARCHAR2
             , x_retcode      OUT NOCOPY NUMBER
            )
IS
---------------------------
--Declaring local variables
---------------------------
lc_set_message        VARCHAR2(2000);
lc_error_message      VARCHAR2(2000); 
lc_rsc_assgn_pty_site VARCHAR2(10);

-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch all the resource from Autonamed Resources details
-- ----------------------------------------------------------------------------------------
cursor lcu_terr_name 
is
select 
xtntrd.resource_id sales_rep_id, 
xtntrd.group_id    sales_group_id,
xtntrd.resource_role_id sales_role_id,
xtntd.named_acct_terr_name , 
jrre.source_name     sales_rep_name, 
papf.employee_number sales_rep_employee_num,
xtntrd.start_date_active sales_rep_tm_start_date,
xtntrd.end_date_active   sales_rep_tm_end_date,
jrre.end_date_active    sales_rep_end_date
from 
xx_tm_nam_terr_rsc_dtls xtntrd,
xx_tm_nam_terr_defn xtntd, 
jtf_rs_resource_extns jrre, 
per_all_people_f papf
where 
xtntd.named_acct_terr_id = xtntrd.named_acct_terr_id 
and xtntrd.status ='A'
and xtntd.status ='A'
and sysdate between xtntrd.start_date_active and nvl(xtntrd.end_date_active,sysdate) 
and sysdate between xtntd.start_date_active and nvl(xtntd.end_date_active,sysdate) 
and jrre.resource_id = xtntrd.resource_id
and papf.person_id = jrre.source_id
order by sales_rep_name;

-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch legacy ID for the given Resource Id and Group Id
-- ----------------------------------------------------------------------------------------
cursor lcu_sales_legacy_id ( p_resource_id number, p_group_id number)
is 
select distinct jrrr.attribute15 legacy_id
from 
jtf_rs_role_relations jrrr, 
jtf_rs_group_members jrgm
where jrrr.role_resource_id = jrgm.group_member_id 
and   jrgm.group_id = p_group_id
--and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
--and nvl(jrgm.delete_flag,'N') = 'N'
and jrgm.resource_id = p_resource_id;

-- ----------------------------------------------------------------------------------------
-- Declare cursor to validate the given Resource Id, Group Id and Role Id
-- ----------------------------------------------------------------------------------------
cursor lcu_tm_rm_sales_rep_dtls ( p_resource_id number, p_group_id number, p_role_id number) 
is 
select 
jrgm.group_id sales_rm_group_id, 
jrrr.role_id  sales_rm_role_id, 
jrrr.start_date_active rm_start_date_active, 
jrrr.end_date_active   rm_end_date_active,
nvl(jrgm.delete_flag,'N') mgr_delete_flag
from 
jtf_rs_group_members jrgm,
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb
where 
jrgm.resource_id = p_resource_id 
and jrgm.group_id = p_group_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_resource_id = jrgm.group_member_id 
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
and jrrr.role_id = jrrb.role_id 
and jrrr.role_id = p_role_id
and jrrb.role_type_code ='SALES';
-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch Group and Role count for given Resource Id and Group Id
-- ----------------------------------------------------------------------------------------
cursor lcu_tm_rm_group_count ( p_resource_id number, p_group_id number) 
is 
select 
count(distinct jrgm.group_id) group_count, count(distinct jrrr.role_id) role_count
from
jtf_rs_group_members jrgm,
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb
where 
jrgm.resource_id = p_resource_id 
and jrgm.group_id = p_group_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_resource_id = jrgm.group_member_id 
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
and jrrr.role_id = jrrb.role_id 
and jrrb.role_type_code ='SALES';
-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch Group and Role count for given Resource Id
-- ----------------------------------------------------------------------------------------
cursor lcu_rm_group_count ( p_resource_id number) 
is 
select 
count(distinct jrgm.group_id) group_count, count(distinct jrrr.role_id) role_count
from
jtf_rs_group_members jrgm,
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb
where 
jrgm.resource_id = p_resource_id 
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_resource_id = jrgm.group_member_id 
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
and jrrr.role_id = jrrb.role_id 
and jrrb.role_type_code ='SALES';
-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch group id for the given Resource Id 
-- ----------------------------------------------------------------------------------------
cursor lcu_rm_group_dtls ( p_resource_id number) 
is 
select 
jrgm.group_id sales_rm_group_id
from 
jtf_rs_group_members jrgm,
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb
where 
jrgm.resource_id = p_resource_id 
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_resource_id = jrgm.group_member_id 
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
and jrrr.role_id = jrrb.role_id 
and jrrb.role_type_code ='SALES';

-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch role details for the given Resource Id and Group Id
-- ----------------------------------------------------------------------------------------
cursor lcu_tm_rm_role_dtls ( p_resource_id number, p_group_id number) 
is 
select 
jrrr.role_id  sales_rm_role_id, 
jrrr.start_date_active rm_start_date_active, 
jrrr.end_date_active   rm_end_date_active
from
jtf_rs_group_members jrgm,
jtf_rs_role_relations jrrr, 
jtf_rs_roles_b jrrb
where 
jrgm.resource_id = p_resource_id 
and jrgm.group_id = p_group_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrrr.role_resource_id = jrgm.group_member_id 
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
and jrrr.role_id = jrrb.role_id 
and jrrb.role_type_code ='SALES';

lcr_sales_rep_legacy_id lcu_sales_legacy_id%rowtype;
lcr_sales_rep_dtls      lcu_tm_rm_sales_rep_dtls%rowtype;
lcr_rm_tm_group_count   lcu_tm_rm_group_count%rowtype;
lcr_tm_rm_role_dtls     lcu_tm_rm_role_dtls%rowtype;
lcr_rm_group_count      lcu_rm_group_count%rowtype;
ln_group_count          number;

lc_exception            varchar2(100);
BEGIN
      
          --write_out(RPAD('System Date: '||to_char(sysdate,'Month DD,YYYY'),40,' '));
          WRITE_out(RPAD(' ',50,' ')
                    ||RPAD(' ',50,' ')
                    ||RPAD(' ',65,' ')||chr(9)||chr(9)||chr(9)||chr(9)
                    ||RPAD('Resource Manager Data',55)
                    ||RPAD(' ',34,' ')||chr(9)||chr(9)||chr(9)||chr(9)
                    ||RPAD(' Auto Name Resource Data',55)
                    ||RPAD(' ',50,' ')
                    );
                
       write_out(RPAD('Resource Id',20)||chr(9)
                 ||RPAD(' Employee Number',30)||chr(9)
                 ||RPAD(' Resource Name',50)||chr(9)
                 ||RPAD(' Legacy Rep Id',30)||chr(9)
                 ||RPAD(' Group Id',30)||chr(9)
                 ||RPAD(' Role Id',30)||chr(9)
                 ||RPAD(' Start Date',15)||chr(9)
                 ||RPAD(' End Date',15)||chr(9)
                 ||RPAD(' Group Id',30)||chr(9)
                 ||RPAD(' Role Id',30)||chr(9)
                 ||RPAD(' Start Date',15)||chr(9)
                 ||RPAD(' End Date',15)||chr(9)
                 ||RPAD(' Exception',50)||chr(9)
                 );
                 
       /*write_out(RPAD('-',20,'-')
                 ||RPAD(' -',30,'-')
                 ||RPAD(' -',50,'-')
                 ||RPAD(' -',30,'-')
                 ||RPAD(' -',30,'-')
                 ||RPAD(' -',30,'-')
                 ||RPAD(' -',15,'-')
                 ||RPAD(' -',15,'-')
                 ||RPAD(' -',30,'-')
                 ||RPAD(' -',30,'-')
                 ||RPAD(' -',15,'-')
                 ||RPAD(' -',15,'-')
                 ||RPAD(' -',50,'-')
                 );           */     
 
      FOR lcr_terr_name IN lcu_terr_name
      LOOP
      lcr_sales_rep_legacy_id.legacy_id:=NULL;
      lcr_sales_rep_dtls.sales_rm_group_id := NULL;
      lcr_sales_rep_dtls.sales_rm_role_id:= NULL;
      lcr_sales_rep_dtls.rm_start_date_active:= NULL;
      lcr_sales_rep_dtls.rm_end_date_active:= NULL;
      lcr_rm_group_count.group_count :=0;
      lcr_rm_group_count.role_count :=0;
      lcr_rm_tm_group_count.group_count:=0;
      lcr_rm_tm_group_count.role_count:=0;
      lcr_tm_rm_role_dtls.sales_rm_role_id:=NULL;      
      lcr_tm_rm_role_dtls.rm_start_date_active:=NULL;
      lcr_tm_rm_role_dtls.rm_end_date_active:=NULL;
      
      lc_exception:=NULL;
      ln_group_count:=0;
      
      IF lcr_terr_name.sales_rep_end_date IS NOT NULL THEN 
      lc_exception:='Resource is End dated';
      ELSE
        --Retrieve the legacy Id
        OPEN lcu_sales_legacy_id(lcr_terr_name.sales_rep_id,
                               lcr_terr_name.sales_group_id);
        FETCH lcu_sales_legacy_id into lcr_sales_rep_legacy_id;
        CLOSE lcu_sales_legacy_id;
        
        --Retrieve from the RM details
        OPEN lcu_tm_rm_sales_rep_dtls(lcr_terr_name.sales_rep_id,
                                 lcr_terr_name.sales_group_id,
                                 lcr_terr_name.sales_role_id);
        FETCH lcu_tm_rm_sales_rep_dtls INTO lcr_sales_rep_dtls;
        CLOSE lcu_tm_rm_sales_rep_dtls;

        IF lcr_sales_rep_dtls.rm_start_date_active IS NOT NULL THEN
          lc_exception:='In Sync';
        ELSE
          --Retrieve the group and role count
          OPEN lcu_tm_rm_group_count(lcr_terr_name.sales_rep_id,
                                 lcr_terr_name.sales_group_id);
          FETCH lcu_tm_rm_group_count INTO lcr_rm_tm_group_count;
          CLOSE lcu_tm_rm_group_count;
          --Validate the group but the role is invalid
          IF lcr_rm_tm_group_count.role_count >0 THEN 
            lcr_sales_rep_dtls.sales_rm_group_id:=lcr_terr_name.sales_group_id;
                
            IF lcr_rm_tm_group_count.role_count =1 THEN 
              --Retrieve the role details for given Resource Id and Group Id
              OPEN lcu_tm_rm_role_dtls(lcr_terr_name.sales_rep_id,
                                 lcr_terr_name.sales_group_id);
              FETCH lcu_tm_rm_role_dtls INTO lcr_tm_rm_role_dtls;
              CLOSE lcu_tm_rm_role_dtls;
              
              lcr_sales_rep_dtls.sales_rm_role_id:=lcr_tm_rm_role_dtls.sales_rm_role_id;
              lcr_sales_rep_dtls.rm_start_date_active :=lcr_tm_rm_role_dtls.rm_start_date_active;
              lcr_sales_rep_dtls.rm_end_date_active :=lcr_tm_rm_role_dtls.rm_end_date_active;
              lc_exception:='Role not in Sync';
            ELSE
              lc_exception:='Role not in Sync, Multiple Roles in RM';
            END IF;--lcr_rm_tm_group_count.role_count =1
        
          ELSE 
            --Retrieve the valid group id and role id for the given Resource id
            OPEN lcu_rm_group_count(lcr_terr_name.sales_rep_id);
            FETCH lcu_rm_group_count INTO lcr_rm_group_count;
            CLOSE lcu_rm_group_count;
            
            IF lcr_rm_group_count.group_count >1 THEN
              lc_exception:='Group Not in Sync,Multiple Group Membership in RM';
            ELSE
              --Retrieve the group details for given resource id
              OPEN lcu_rm_group_dtls(lcr_terr_name.sales_rep_id);
              FETCH lcu_rm_group_dtls INTO ln_group_count;
              CLOSE lcu_rm_group_dtls;
              --Retrieve the role details for given resource id and group id
              IF lcr_rm_group_count.role_count = 1 THEN
                OPEN lcu_tm_rm_role_dtls(lcr_terr_name.sales_rep_id,
                                   ln_group_count);
                FETCH lcu_tm_rm_role_dtls into lcr_tm_rm_role_dtls;
                CLOSE lcu_tm_rm_role_dtls;
                
                lcr_sales_rep_dtls.sales_rm_role_id:=lcr_tm_rm_role_dtls.sales_rm_role_id;
                lcr_sales_rep_dtls.rm_start_date_active :=lcr_tm_rm_role_dtls.rm_start_date_active;
                lcr_sales_rep_dtls.rm_end_date_active :=lcr_tm_rm_role_dtls.rm_end_date_active; 
                
                IF lcr_sales_rep_dtls.sales_rm_group_id <> lcr_terr_name.sales_group_id
                 AND lcr_sales_rep_dtls.sales_rm_role_id <>lcr_terr_name.sales_role_id THEN 
                 lc_exception:='Group '||chr(38)||' Role Not in Sync';
                ELSIF lcr_sales_rep_dtls.sales_rm_group_id = lcr_terr_name.sales_group_id
                 AND lcr_sales_rep_dtls.sales_rm_role_id <>lcr_terr_name.sales_role_id THEN 
                 lc_exception:='Role Not in Sync';
                ELSIF lcr_sales_rep_dtls.sales_rm_group_id <> lcr_terr_name.sales_group_id
                 AND lcr_sales_rep_dtls.sales_rm_role_id = lcr_terr_name.sales_role_id THEN
                 lc_exception:='Group Not in Sync';
                END IF;
              ELSIF lcr_rm_group_count.role_count > 1 then 
                lc_exception:='Role Not in Sync,Multiple Roles in RM';
              END IF;--lcr_rm_group_count.role_count = 1
            lcr_sales_rep_dtls.sales_rm_group_id:=ln_group_count;
            lc_exception:='Group Not in Sync';
            END IF;--lcr_rm_group_count.group_count >0 
          END IF;--lcr_rm_tm_group_count.role_count >0
       
        END IF;--lcr_sales_rep_dtls.rm_start_date_active IS NOT NULL
      END IF;--lcr_terr_name.sales_rep_end_date is not null
      
      
      print_display(  p_sales_rep_id     =>lcr_terr_name.sales_rep_id
                    , p_sales_number     =>lcr_terr_name.sales_rep_employee_num
                    , p_sales_name       =>lcr_terr_name.sales_rep_name
                    , p_sales_legacy_id  =>lcr_sales_rep_legacy_id.legacy_id
                    , p_rm_group_id      =>lcr_sales_rep_dtls.sales_rm_group_id
                    , p_rm_role_id       =>lcr_sales_rep_dtls.sales_rm_role_id
                    , p_rm_start_date    =>lcr_sales_rep_dtls.rm_start_date_active
                    , p_rm_end_date      =>lcr_sales_rep_dtls.rm_end_date_active
                    , p_tm_group_id      =>lcr_terr_name.sales_group_id
                    , p_tm_role_id       =>lcr_terr_name.sales_role_id
                    , p_tm_start_date    =>lcr_terr_name.sales_rep_tm_start_date
                    , p_tm_end_date      =>lcr_terr_name.sales_rep_tm_end_date                    
                    , p_exception        =>lc_exception                     
                       );
      END LOOP;
            
                     
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
                                          , p_program_name           => 'XX_JTF_UNASSIGN_PTY_SITE_REP.ASSIGN_PTY_SITE'
                                          , p_program_id             => gn_program_id
                                          , p_module_name            => G_MODULE_NAME
                                          , p_error_location         => 'XX_JTF_UNASSIGN_PTY_SITE_REP.ASSIGN_PTY_SITE'
                                          , p_error_message_code     => 'XX_TM_0007_UNEXPECTED_ERR'
                                          , p_error_message          => lc_error_message
                                          , p_error_message_severity => G_MAJOR_ERROR_MESSAGE_SEVERITY
                                          , p_error_status           => G_ERROR_STATUS_FLAG
                                         );
END MAIN_PROC;

END XX_TM_AN_RSC_SYNC_REPORT_PKG;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================