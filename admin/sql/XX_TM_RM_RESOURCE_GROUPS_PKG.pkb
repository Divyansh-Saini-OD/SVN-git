SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_TM_RM_RESOURCE_GROUPS_PKG package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_TM_RM_RESOURCE_GROUPS_PKG
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
                        p_sales_rep_name     VARCHAR2
                        , p_sales_rep_id     NUMBER
                        , p_sales_number     VARCHAR2
                        , p_sales_role_name  VARCHAR2
                        , p_sales_legacy_id  VARCHAR2
                        , p_sales_role_code  VARCHAR2
                        , p_sales_grp_name   VARCHAR2
                        , p_sales_mgr_name   VARCHAR2
                        , p_sales_mgr_id     VARCHAR2
                        , p_mgr_role_name    VARCHAR2                        
                        , p_mgr_role_code    VARCHAR2 
                        , p_parent_grp_name  VARCHAR2                         
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
   
         write_out(' '
                   ||RPAD(NVL(p_sales_rep_name,'(null)'),50)||chr(9)
                   ||RPAD(NVL(to_char(p_sales_rep_id),'(null)'),20)||chr(9)
                   ||RPAD(NVL(p_sales_number,'(null)'),30)||chr(9)
                   ||RPAD(NVL(p_sales_role_name,'(null)'),60)||chr(9)
                   ||RPAD(NVL(p_sales_legacy_id,'(null)'),30)||chr(9)                   
                   ||RPAD(NVL(p_sales_role_code,'(null)'),30)||chr(9)
                   ||RPAD(NVL(p_sales_grp_name,'(null)'),60)||chr(9)
                   ||RPAD(NVL(p_sales_mgr_name,'(null)'),50)||chr(9)
                   ||RPAD(NVL(to_char(p_sales_mgr_id),'(null)'),20)||chr(9)
                   ||RPAD(NVL(p_mgr_role_name,'(null)'),60)||chr(9)
                   ||RPAD(NVL(p_mgr_role_code,'(null)'),30)||chr(9)
                   ||RPAD(NVL(p_parent_grp_name,'(null)'),60)||chr(9)                         
                    );   
            
EXCEPTION
   WHEN OTHERS THEN
       FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0007_UNEXPECTED_ERR');
       lc_err_message     :=  'Unexpected Error in procedure: PRINT_DISPLAY';
       FND_MESSAGE.SET_TOKEN('PROCEDURE_NAME', lc_err_message);
       FND_MESSAGE.SET_TOKEN('ERROR_CODE', SQLCODE);
       FND_MESSAGE.SET_TOKEN('ERROR_MESSAGE', SQLERRM);
       lc_message := FND_MESSAGE.GET;
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
             ,p_sales_group_id in number
            )
IS
---------------------------
--Declaring local variables
---------------------------
lc_set_message        VARCHAR2(2000);
lc_error_message      VARCHAR2(2000); 
lc_rsc_assgn_pty_site VARCHAR2(10);

-- ----------------------------------------------------------------------------------------
-- Declare cursor to fetch only the admin and manager records as resource_id is not passed
-- ----------------------------------------------------------------------------------------
cursor lcu_sales_resources is
SELECT   
    sales_jrre.source_name       sales_rep_name,
    sales_jrre.resource_id       sales_rep_id,
    sales_jrrt.role_name         sales_rep_role_name,
    sales_jrrb.ATTRIBUTE14       sales_rep_attribute14,
    sales_jrgt.GROUP_name        sales_rep_group_name,
    sales_jrgt.group_id          sales_rep_group_id,
    sales_jrrr.attribute15       sales_rep_legacy_id
FROM     
    jtf_rs_resource_extns        sales_jrre,
    jtf_rs_groups_tl             sales_jrgt,
    jtf_rs_group_usages          sales_jrgu,
    jtf_rs_group_members         sales_jrgm,
    jtf_rs_role_relations        sales_jrrr,
    jtf_rs_roles_b               sales_jrrb,
    jtf_rs_roles_tl              sales_jrrt
WHERE    
     sales_jrre.resource_id          = sales_jrgm.resource_id
AND  sales_jrgm.group_id             = sales_jrgt.group_id
AND  sales_jrgu.group_id             = sales_jrgt.group_id
AND  sales_jrgu.usage                ='SALES'
AND  NVL(sales_jrgm.delete_flag,'N') ='N'
AND  sales_jrrr.role_resource_id     = SALES_jrgm.group_member_id
AND  sales_jrrr.role_id              = sales_jrrb.role_id
--AND  sales_jrrb.attribute14 NOT IN ( 'OT','HSE')
AND  sales_jrrb.ROLE_TYPE_CODE       ='SALES'
AND  SYSDATE BETWEEN sales_jrrr.                   start_date_active
AND  NVL(sales_jrrr.end_date_active,SYSDATE)
AND  NVL(sales_jrrr.delete_flag,'N') = 'N'
AND  sales_jrrb.role_id              = sales_jrrt.role_id
AND  sales_jrrt.language             = userenv('LANG')
AND  sales_jrgt.language             = userenv('LANG')
AND  decode(p_sales_group_id,NULL,sales_jrgm.group_id,p_sales_group_id) = sales_jrgm.group_id
order by sales_jrre.source_name ;


cursor lcu_sales_res_number (p_resource_id number) 
is 
select salesrep_number
from jtf_rs_salesreps
where resource_id = p_resource_id;

cursor lcu_sales_res_manager (p_group_id number) 
is 
select 
jrre.source_name sales_mgr_name, 
jrre.resource_id sales_mgr_id,
jrrt.role_name   mgr_role_name,
jrrb.ATTRIBUTE14 mgr_attribute14
from 
jtf_rs_role_relations jrrr, 
jtf_rs_group_members jrgm, 
jtf_rs_roles_tl jrrt, 
jtf_rs_roles_b jrrb,
jtf_rs_resource_extns jrre
where
jrgm.group_id = p_group_id 
and nvl(jrgm.delete_flag,'N') = 'N'
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate)
and jrrr.role_resource_id = jrgm.group_member_id
and jrrt.role_id = jrrr.role_id
and jrrb.role_id = jrrt.role_id
and jrrb.role_type_code='SALES'
and jrrb.manager_flag ='Y'
and jrrt.language = userenv('lang')
and jrre.resource_id = jrgm.resource_id;

cursor lcu_parent_group (p_group_id number) 
is 
SELECT   jrgt.group_name
FROM     jtf_rs_groups_tl jrgt,
JTF_RS_GRP_RELATIONS jrgr
WHERE    jrgt.group_id  = jrgr.related_group_id
AND      jrgt.LANGUAGE  = userenv('LANG')
AND      jrgr.group_id  = p_group_id
and      sysdate between jrgr.start_date_active and nvl(jrgr.end_date_active,sysdate)
and      nvl(jrgr.delete_flag,'N') = 'N';

lcr_salesrep_number   lcu_sales_res_number%rowtype;
lcr_sales_res_manager lcu_sales_res_manager%rowtype;
lcr_parent_group      lcu_parent_group%rowtype;

BEGIN
   
       write_out(RPAD(' Sales Rep Name',50)||chr(9)
                 ||RPAD(' Sales Rep Id',20)||chr(9)
                 ||RPAD(' Sales Rep Number',30)||chr(9)
                 ||RPAD(' Sales Rep Role Name',60)||chr(9)
                 ||RPAD(' Sales Legacy Id',30)||chr(9)
                 ||RPAD(' Sales Rep Role Code',30)||chr(9)
                 ||RPAD(' Sales Rep Group Name',60)||chr(9)
                 ||RPAD(' Supervisor Name',50)||chr(9)
                 ||RPAD(' Supervisor Id',20)||chr(9)
                 ||RPAD(' Supervisor Role Name',60)||chr(9)
                 ||RPAD(' Supervisor Role Code',30)||chr(9)
                 ||RPAD(' Parent Group Name',60)||chr(9));
                 
      /* write_out(RPAD(' ',50,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',60,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',60,'-')
                 ||RPAD(' ',50,'-')
                 ||RPAD(' ',20,'-')
                 ||RPAD(' ',60,'-')
                 ||RPAD(' ',30,'-')
                 ||RPAD(' ',60,'-')); */                
 
                for lru_sales_resources in lcu_sales_resources 
                loop
                        
                        --lru_sales_resources.sales_rep_name         := null;       
                        --lru_sales_resources.sales_rep_id           := null;
                        lcr_salesrep_number.salesrep_number        := null;  
                        --lru_sales_resources.sales_rep_role_name    := null;
                        --lru_sales_resources.sales_rep_attribute14  := null;
                        --lru_sales_resources.sales_rep_group_id     := null; 
                        --lru_sales_resources.sales_rep_group_name   := null;
                        lcr_sales_res_manager.sales_mgr_name       := null;
                        lcr_sales_res_manager.sales_mgr_id         := null;
                        lcr_sales_res_manager.mgr_role_name        := null;                
                        lcr_sales_res_manager.mgr_attribute14      := null;
                        lcr_parent_group.group_name                := null;
                        
                        
                        open lcu_sales_res_number (lru_sales_resources.sales_rep_id); 
                        fetch lcu_sales_res_number into lcr_salesrep_number;
                        close lcu_sales_res_number;

                        open lcu_sales_res_manager(lru_sales_resources.sales_rep_group_id);
                        fetch lcu_sales_res_manager into lcr_sales_res_manager;
                        close lcu_sales_res_manager;     

                        open lcu_parent_group(lru_sales_resources.sales_rep_group_id);
                        fetch lcu_parent_group into lcr_parent_group;
                        close lcu_parent_group; 
                        
                        print_display(
                        p_sales_rep_name     =>lru_sales_resources.sales_rep_name
                        , p_sales_rep_id     =>lru_sales_resources.sales_rep_id
                        , p_sales_number     =>lcr_salesrep_number.salesrep_number
                        , p_sales_role_name  =>lru_sales_resources.sales_rep_role_name
                        , p_sales_legacy_id  =>lru_sales_resources.sales_rep_legacy_id
                        , p_sales_role_code  =>lru_sales_resources.sales_rep_attribute14
                        , p_sales_grp_name   =>lru_sales_resources.sales_rep_group_name
                        , p_sales_mgr_name   =>lcr_sales_res_manager.sales_mgr_name
                        , p_sales_mgr_id     =>lcr_sales_res_manager.sales_mgr_id
                        , p_mgr_role_name    =>lcr_sales_res_manager.mgr_role_name                        
                        , p_mgr_role_code    =>lcr_sales_res_manager.mgr_attribute14 
                        , p_parent_grp_name  =>lcr_parent_group.group_name                         
                       );                        
                        
                end loop;
                     
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

END XX_TM_RM_RESOURCE_GROUPS_PKG;
/
SHOW ERRORS;
EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================