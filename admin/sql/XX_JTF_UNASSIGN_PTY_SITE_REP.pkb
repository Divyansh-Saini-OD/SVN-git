SET VERIFY OFF
WHENEVER SQLERROR CONTINUE
WHENEVER OSERROR EXIT FAILURE ROLLBACK

PROMPT
PROMPT Creating XX_JTF_UNASSIGN_PTY_SITE_REP package body
PROMPT

CREATE OR REPLACE PACKAGE BODY XX_JTF_UNASSIGN_PTY_SITE_REP
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_JTF_UNASSIGN_PTY_SITE_REP                                  |
-- |                                                                                   |
-- | Description      :  This custom package will get called from the concurrent       |
-- |                     program 'OD: TM Un-Assigned Party Sites Report' with          |
-- |                     Resource Name as the Input parameters.                        |
-- |                     This public procedure will display the party-sites that       |
-- |                     are assigned to the resource in the custom assignments table. |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |PROCEDURE    Assign_pty_site         This is the public procedure                  |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  04-Mar-08   Abhradip Ghosh               Initial draft version           |
-- |1.0       04-Sep-08   Kishore Jena                 Changed Code to exclude hard-   |
-- |                                                   assigned sites as well as re-   |
-- |                                                   assigned sites from TOPS.       |
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
                        p_party_site_number        VARCHAR2
                        , p_party_site_id          NUMBER
                        , p_orig_system_reference  VARCHAR2
                        , p_postal_code            VARCHAR2
                        , p_resource_number        VARCHAR2
                        , p_resource_id            NUMBER
                        , p_role_code              VARCHAR2
                        , p_role_name              VARCHAR2
                        , p_resource_name          VARCHAR2
                        , p_legacy_id              VARCHAR2
                        , p_source_name            VARCHAR2
			, p_party_type             VARCHAR2
                       )
IS
---------------------------
--Declaring local variables
---------------------------
lc_message            VARCHAR2(2000);
lc_err_message        VARCHAR2(2000);

BEGIN
   
  /* write_out(
             RPAD(' ',1,' ')||
             RPAD(p_party_site_number,20,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(p_party_site_id,20,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(p_orig_system_reference,30,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(NVL(p_postal_code,'XX'),20,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(p_resource_number,20,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(p_resource_name,40,' ')||chr(9)||
             --RPAD(' ',5,' ')||             
             RPAD(p_resource_id,20,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(nvl(p_legacy_id,'(null)'),20,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(p_role_code,30,' ')||chr(9)||
             --RPAD(' ',5,' ')||
             RPAD(p_role_name,40,' ')||chr(9)
            );*/
            
            write_out(   RPAD(' ',1,' ')||
	    	                 RPAD(p_party_type,20,' ')||chr(9)||
	    	              --   RPAD(' ',1,' ')||
	    	                 RPAD(p_party_site_number,20,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(p_party_site_id,20,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(p_orig_system_reference,30,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(NVL(p_postal_code,'XX'),20,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(p_source_name,40,' ')||chr(9)||
	    			 --RPAD(' ',5,' ')||
	                             RPAD(p_resource_number,20,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(p_resource_name,40,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||             
	    	                 RPAD(p_resource_id,20,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(nvl(p_legacy_id,'(null)'),20,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(p_role_code,30,' ')||chr(9)||
	    	                 --RPAD(' ',5,' ')||
	    	                 RPAD(p_role_name,40,' ')||chr(9)
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

-- +==========================================================================+
-- | Name  : assign_pty_site                                                  |
-- |                                                                          |
-- | Description  :  This custom package will get called from the concurrent  |
-- |                 program 'OD: TM Un-Assigned Party Sites Report' with     |
-- |                 Resource Name as the Input parameters. This public       |
-- |                 procedure will display the party-sites that are          |
-- |                 assigned to the resource in the custom assignments table.|
-- +==========================================================================+

PROCEDURE assign_pty_site
            (
             x_errbuf         OUT NOCOPY VARCHAR2
             , x_retcode      OUT NOCOPY NUMBER
             , p_rsd_group_id IN NUMBER
             , p_mgr_resource_id IN  NUMBER
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
CURSOR lcu_mgr_admin_assgn_terr_id
IS
SELECT XTR.resource_id
       , XTR.named_acct_terr_id
       , JRRE.resource_number
       , ROV.role_code
       , ROV.role_name  
       , null legacy_id
       , jrre.source_name       
FROM   xx_tm_nam_terr_rsc_dtls XTR
       , xx_tm_nam_terr_defn XTN
       , jtf_rs_resource_extns JRRE
       , jtf_rs_roles_vl ROV
WHERE  XTN.named_acct_terr_id = XTR.named_acct_terr_id
AND    NVL(XTR.status,'A') = 'A'
AND    NVL(XTN.status,'A') = 'A'
AND    XTR.resource_role_id = ROV.role_id
AND    XTR.resource_id = JRRE.resource_id
AND    (ROV.admin_flag = 'Y' OR ROV.manager_flag = 'Y' OR ROV.attribute14 = 'HSE')
AND    ROV.active_flag = 'Y'
AND EXISTS
(
SELECT 1 
FROM   apps.jtf_rs_role_relations JRR
      , apps.jtf_rs_group_members MEM
      , apps.jtf_rs_group_usages JRU
      , apps.jtf_rs_roles_b ROL
WHERE  JRR.role_resource_id = MEM.group_member_id
AND    MEM.resource_id = XTR.resource_id
AND    MEM.group_id = XTR.group_id
AND    MEM.group_id = JRU.group_id
AND    JRU.USAGE='SALES'
AND    JRR.role_id = ROL.role_id
AND    ROL.role_type_code='SALES'
AND    ROL.active_flag = 'Y'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'
AND    NVL(MEM.delete_flag,'N') <> 'Y'
)
ORDER BY JRRE.resource_number;

-- --------------------------------------------------------------------------------------
-- Declare cursor to verify whether the party_site_id already exists in the entity table
-- --------------------------------------------------------------------------------------
CURSOR lcu_rsc_assgn_terr_id(
                             p_resource_id NUMBER
                            )
IS
SELECT JRRE.resource_id
       , XTNT.named_acct_terr_id
       , JRRE.resource_number
       , ROL.role_code 
       , ROL.role_name
       , jrr.attribute15 legacy_id
       , jrre.source_name
FROM   jtf_rs_resource_extns JRRE
       , xx_tm_nam_terr_rsc_dtls XTNT
       , jtf_rs_role_relations JRR
       , jtf_rs_group_members MEM
       , jtf_rs_group_usages JRU
       , jtf_rs_roles_vl ROL 
WHERE  JRR.role_resource_id = MEM.group_member_id
AND    JRRE.resource_id = p_resource_id
AND    MEM.resource_id = JRRE.resource_id
AND    JRRE.resource_id = XTNT.resource_id
AND    MEM.group_id = XTNT.group_id
AND    MEM.group_id = JRU.group_id
AND    JRU.USAGE = 'SALES'
AND    JRR.role_id = ROL.role_id
AND    ROL.role_type_code = 'SALES'
AND    ROL.active_flag = 'Y'
AND    TRUNC(SYSDATE) BETWEEN TRUNC(JRR.start_date_active) AND NVL(TRUNC(JRR.end_date_active),TRUNC(SYSDATE))
AND    NVL(JRR.delete_flag,'N') <> 'Y'
AND    NVL(MEM.delete_flag,'N') <> 'Y'
ORDER BY JRRE.resource_number;

CURSOR lcu_mgr_assgn_terr_id (
                                p_group_id  NUMBER
                             )
is                             
select 
manager.resource_id, 
manager.named_acct_terr_id,
manager.resource_number,
manager.role_code,
manager.role_name,
manager.legacy_id,
manager.source_name
from 
(select 
jrre.resource_id,
xtntd.named_acct_terr_id,
JRRE.resource_number, 
jrrb.role_code,
jrrt.role_name, 
jrgt.group_id,
jrrr.attribute15 legacy_id,
jrre.source_name
from 
JTF_RS_RESOURCE_EXTNS jrre,
jtf_rs_roles_b jrrb,
jtf_rs_roles_tl jrrt,
jtf_rs_role_relations jrrr, 
jtf_rs_group_members jrgm, 
jtf_rs_groups_tl jrgt, 
jtf_rs_group_usages jrgu, 
xx_tm_nam_terr_defn xtntd,
xx_tm_nam_terr_rsc_dtls xtntrd
where 
jrrb.role_type_code='SALES'
and ( jrrb.manager_flag='Y' or jrrb.attribute14='HSE')
and jrrt.role_id = jrrb.role_id 
and jrrt.language = userenv('LANG')
and nvl(jrrr.delete_flag,'N') = 'N'
and jrrr.role_id = jrrb.role_id
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate) 
and jrgm.group_member_id = jrrr.role_resource_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrgm.group_id = jrgt.group_id 
and jrgu.group_id = jrgm.group_id
and jrgu.usage ='SALES'
and jrgt.language = userenv('LANG')
and jrre.resource_id = jrgm.resource_id
and xtntrd.NAMED_ACCT_TERR_ID = xtntd.NAMED_ACCT_TERR_ID
and xtntrd.status ='A'
and  xtntrd.resource_id = jrre.resource_id
and xtntd.status='A'
and  xtntrd.group_id = jrgm.group_id
and  xtntrd.resource_role_id = jrrb.role_id) manager, jtf_rs_groups_denorm jrgd
where manager.group_id = jrgd.group_id
and jrgd.parent_group_id = p_group_id;




-- -------------------------------------------
-- Declare Cursor to fetch the party details
-- -------------------------------------------
CURSOR lcu_party_sites(
                       p_named_acct_terr_id NUMBER,
                       p_resource_id NUMBER
                      )
IS                      
SELECT TERR_ENT.entity_id 
       , HPS.party_site_number
       , HPS.orig_system_reference
       , HLO.postal_code
       , (select hp.attribute13 from hz_parties hp where hp.party_id = hps.party_id) party_type
FROM   xx_tm_nam_terr_defn TERR
       , xx_tm_nam_terr_entity_dtls TERR_ENT
       , hz_party_sites HPS
       , hz_locations HLO
       , fnd_user USR
WHERE TERR.named_acct_terr_id = TERR_ENT.named_acct_terr_id
AND   TERR.named_acct_terr_id = p_named_acct_terr_id
AND   TERR_ENT.entity_id = HPS.party_site_id  
AND   HPS.location_id = HLO.location_id
AND   SYSDATE between TERR.start_date_active AND NVL(TERR.end_date_active,SYSDATE)
AND   SYSDATE between TERR_ENT.start_date_active AND NVL(TERR_ENT.end_date_active,SYSDATE)
AND   NVL(TERR.status,'A')     = 'A'
AND   NVL(TERR_ENT.status,'A') = 'A'
AND   TERR_ENT.entity_type = 'PARTY_SITE'
-- Exclude the hard-assigned sites
AND   USR.user_id = TERR_ENT.created_by
AND   USR.user_name <> 'ODSFA'
-- Exclude the re-assigned sites from TOPS
AND   NOT EXISTS (SELECT 1
                  FROM   xxtps.xxtps_site_requests XSR
                  WHERE  XSR.party_site_id = TERR_ENT.entity_id
                    AND  XSR.to_resource_id = p_resource_id
                    AND  XSR.request_status_code = 'COMPLETED'
                    AND  XSR.last_update_date =  (SELECT max(XSR1.last_update_date)
                                                  FROM   xxtps.xxtps_site_requests XSR1
                                                  WHERE  XSR1.party_site_id = TERR_ENT.entity_id
                                                    AND  XSR1.request_status_code = 'COMPLETED'
                                                 )
                 )
ORDER BY TERR_ENT.entity_id;


CURSOR lcu_admin_assgn_terr_id (
                                p_group_id  NUMBER
                             )
is   
select --jrrb.role_id, jrrt.role_name, 
jrre.resource_id,jrre.source_name--,jrgt.group_name, jrrb.role_code, jrrb.attribute14
from
JTF_RS_RESOURCE_EXTNS jrre,
JTF_RS_ROLES_B jrrb,
JTF_RS_ROLES_TL jrrt,
JTF_RS_ROLE_RELATIONS jrrr,
JTF_RS_GROUP_MEMBERS jrgm,
JTF_RS_GROUPS_TL jrgt,
JTF_RS_GROUP_USAGES jrgu
where jrrb.attribute14='SETUP'
and jrrb.role_type_code='SALES'
and jrrt.role_id = jrrb.role_id
and jrrt.language = userenv('LANG')
and nvl(jrrr.delete_flag,'N') = 'N'
and jrrr.role_id = jrrb.role_id
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate)
and jrgm.group_member_id = jrrr.role_resource_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrgm.group_id = jrgt.group_id
and jrgu.group_id = jrgm.group_id
and jrgm.group_id = p_group_id
and jrgu.usage ='SALES'
and jrgt.language = userenv('LANG')
and jrre.resource_id = jrgm.resource_id;

CURSOR lcu_rsd_name (
                     p_group_id  NUMBER
                    )
is                             
select jrre.resource_id,jrre.source_name
from
JTF_RS_RESOURCE_EXTNS jrre,
jtf_rs_roles_b jrrb,jtf_rs_roles_tl jrrt,
jtf_rs_role_relations jrrr,
jtf_rs_group_members jrgm,
jtf_rs_groups_tl jrgt,
jtf_rs_group_usages jrgu,
Per_all_people_f papf
where
(jrrb.attribute14='RSD' or jrrb.attribute14='SETUP')
and jrrb.role_type_code='SALES'
and jrrt.role_id = jrrb.role_id
and jrrt.language = userenv('LANG')
and nvl(jrrr.delete_flag,'N') = 'N'
and jrrr.role_id = jrrb.role_id
and sysdate between jrrr.start_date_active and nvl(jrrr.end_date_active,sysdate)
and jrgm.group_member_id = jrrr.role_resource_id
and nvl(jrgm.delete_flag,'N') = 'N'
and jrgm.group_id = jrgt.group_id
and jrgu.group_id = jrgm.group_id
and jrgu.usage ='SALES'
and jrgt.language = userenv('LANG')
and jrre.resource_id = jrgm.resource_id
and jrre.source_id = papf.person_id
and sysdate between papf.effective_start_date and papf.effective_end_date
and jrgt.group_id = p_group_id;
----------------------------------
-- Declaring Table Type Variables
----------------------------------
TYPE terr_id_dtls_rec_type IS TABLE OF lcu_rsc_assgn_terr_id%ROWTYPE INDEX BY BINARY_INTEGER;
lt_terr_id_dtls terr_id_dtls_rec_type;

ln_setup_resource_id    JTF_RS_RESOURCE_EXTNS.resource_id%type;
lnr_setup_resource_id    JTF_RS_RESOURCE_EXTNS.resource_id%type;
lrc_setup_resource_name  JTF_RS_RESOURCE_EXTNS.source_name%type;
lmc_setup_resource_name  JTF_RS_RESOURCE_EXTNS.source_name%type;
ln_resource_id          JTF_RS_RESOURCE_EXTNS.resource_id%type;
BEGIN
   
   -- --------------------------------------
   -- DISPLAY PROJECT NAME AND PROGRAM NAME
   -- --------------------------------------
  


   WRITE_LOG('P_RSD_GROUP_ID => '|| p_rsd_group_id);            
   BEGIN 
        OPEN  lcu_admin_assgn_terr_id(p_rsd_group_id);
        FETCH lcu_admin_assgn_terr_id into  ln_setup_resource_id,lrc_setup_resource_name;
        CLOSE lcu_admin_assgn_terr_id;
   EXCEPTION 
        WHEN OTHERS THEN
         ln_setup_resource_id:=0;
   END;
   WRITE_LOG('ln_setup_resource_id => '|| ln_setup_resource_id);
   IF lrc_setup_resource_name is null then 
        open lcu_rsd_name(p_rsd_group_id);
        fetch lcu_rsd_name into  lnr_setup_resource_id,lrc_setup_resource_name;
        close lcu_rsd_name;
   end if;
   Write_out ('RSD/Admin Resource Id :'||lnr_setup_resource_id);
   Write_out ('RSD/Admin Resource Name :'||lrc_setup_resource_name);
   
   If p_mgr_resource_id is not null then
     begin 
          select source_name into lmc_setup_resource_name 
          from jtf_rs_resource_extns
          where resource_id = p_mgr_resource_id;
     exception 
        when others then 
             null;
      end;
   else
        lmc_setup_resource_name :=null;
   end if;   
   Write_out ('Manager Resource id '||p_mgr_resource_id);
   Write_out ('Manager Resource Name :'||lmc_setup_resource_name);

   /*write_out(
                RPAD(' ',1,' ')||
                RPAD('Party Site Number',20,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Party Site Id',20,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Orig System Reference',30,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Postal Code',20,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Resource Number',20,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Resource Name',40,' ')||chr(9)||
                --RPAD(' ',5,' ')||                
                RPAD('Resource Id',20,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Legacy Id',20,' ')||chr(9)||
                --RPAD(' ',5,' ')||                
                RPAD('Role Code',30,' ')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('Role Name',40,' ')||chr(9)
               );
      write_out(
                RPAD(' ',1,' ')||
                RPAD('-',20,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',20,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',30,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',20,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',20,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',40,'-')||chr(9)||
                --RPAD(' ',5,' ')||                
                RPAD('-',20,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',20,'-')||chr(9)||
                --RPAD(' ',5,' ')||                
                RPAD('-',30,'-')||chr(9)||
                --RPAD(' ',5,' ')||
                RPAD('-',40,'-')||chr(9)
            );*/
            
            write_out(
	    	                     RPAD(' ',1,' ')||
	    			     RPAD('Party Type',20,' ')||chr(9)||
	    	                    -- RPAD(' ',1,' ')||
	    	                     RPAD('Party Site Number',20,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Party Site Id',20,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Orig System Reference',30,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Postal Code',20,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Source name',40,' ')||chr(9)||
	    			     --RPAD(' ',5,' ')||chr(9)||
	    	                     RPAD('Resource Number',20,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Resource Name',40,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||                
	    	                     RPAD('Resource Id',20,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Legacy Id',20,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||                
	    	                     RPAD('Role Code',30,' ')||chr(9)||
	    	                     --RPAD(' ',5,' ')||
	    	                     RPAD('Role Name',40,' ')||chr(9)
	    	                    );
	     
            
   IF p_mgr_resource_id IS NOT NULL or  nvl(ln_setup_resource_id,0) <> 0  THEN
      
      IF nvl(ln_setup_resource_id,0) =0 THEN 
         ln_resource_id := p_mgr_resource_id;      
      ELSE
         ln_resource_id := ln_setup_resource_id;
      END IF;
      
      OPEN lcu_rsc_assgn_terr_id(
                                 p_resource_id => ln_resource_id
                                );
      FETCH lcu_rsc_assgn_terr_id BULK COLLECT INTO lt_terr_id_dtls;
      CLOSE lcu_rsc_assgn_terr_id;
   
   
   ELSE
       
       --OPEN lcu_mgr_admin_assgn_terr_id;
       --FETCH lcu_mgr_admin_assgn_terr_id BULK COLLECT INTO lt_terr_id_dtls;
       --CLOSE lcu_mgr_admin_assgn_terr_id;
       
       
       OPEN lcu_mgr_assgn_terr_id(p_rsd_group_id);
       FETCH lcu_mgr_assgn_terr_id BULK COLLECT INTO lt_terr_id_dtls;
       CLOSE lcu_mgr_assgn_terr_id;
   
   END IF;
   write_log('lt_terr_id_dtls.COUNT =>'||lt_terr_id_dtls.COUNT);
   IF lt_terr_id_dtls.COUNT <> 0 THEN
      
      FOR i IN lt_terr_id_dtls.FIRST .. lt_terr_id_dtls.LAST
      LOOP
          write_log(lt_terr_id_dtls(i).named_acct_terr_id);
          lc_rsc_assgn_pty_site := 'N';
          
          FOR party_sites_rec IN lcu_party_sites(
                                                 p_named_acct_terr_id => lt_terr_id_dtls(i).named_acct_terr_id,
                                                 p_resource_id => lt_terr_id_dtls(i).resource_id
                                                )
          LOOP
              
              lc_rsc_assgn_pty_site := 'Y';
              
              print_display(
                            p_party_site_number        => party_sites_rec.party_site_number
                            , p_party_site_id          => party_sites_rec.entity_id
                            , p_orig_system_reference  => party_sites_rec.orig_system_reference
                            , p_postal_code            => party_sites_rec.postal_code
                            , p_resource_number        => lt_terr_id_dtls(i).resource_number
                            , p_resource_id            => lt_terr_id_dtls(i).resource_id
                            , p_role_code              => lt_terr_id_dtls(i).role_code
                            , p_role_name              => lt_terr_id_dtls(i).role_name
                            , p_resource_name          => lt_terr_id_dtls(i).source_name
                            , p_legacy_id              => lt_terr_id_dtls(i).legacy_id
                            , p_source_name            => lt_terr_id_dtls(i).source_name
                            , p_party_type             => party_sites_rec.party_type
                           );
          
          END LOOP;
          
          IF lc_rsc_assgn_pty_site = 'N' THEN
                
            FND_MESSAGE.SET_NAME('XXCRM','XX_TM_0246_NO_PTY_SITE_ASSIGN');
            FND_MESSAGE.SET_TOKEN('P_RESOURCE_ID', lt_terr_id_dtls(i).resource_number);
            lc_error_message := FND_MESSAGE.GET;
            --write_out(lc_error_message);
             
          END IF;
          
          --write_out(RPAD(' ',236,'-'));
      
      END LOOP;
         
   END IF;
                     
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
END assign_pty_site;

END XX_JTF_UNASSIGN_PTY_SITE_REP;
/
SHOW ERRORS;
--EXIT

REM============================================================================================
REM                                   End Of Script                                            
REM============================================================================================
