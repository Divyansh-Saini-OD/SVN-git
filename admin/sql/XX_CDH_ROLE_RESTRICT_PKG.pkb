SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cdh_role_restrict_pkg

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CDH_ROLE_RESTRICT_PKG                                   |
-- | Rice ID     : E0266_RoleRestrictionsMerges                               |
-- | Description : Custom Package part of the VPD Implementation. Contains the|
-- |               functions to return the predicate for Tables during Insert,|
-- |               Update or Delete, based on the Profile Values. Profile     |
-- |               'XX_CDH_SEC_BYPASS_SEC_RULES' shall determine if VPD can be|
-- |               bypassed.                                                  |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 12-Jul-2007 Prem Kumar             Initial draft version         |
-- |Draft 1b 13-Aug-2007 Vidhya Valantina T                                   |
-- |1.0      XX-Aug-2007 Vidhya Valantina T     Baselined after review        |
-- |2.0      27-Dec-2007 Rajeev Kamath          Bug Fixes - Profiles not used |
-- |2.1      15-Jan-2008 Rajeev Kamath          Bug Fixes - QC 3466, 3399     |
-- |2.2      15-Jan-2008 Sreedhar Mohan         Bug Fixes - QC 3327           |
-- |2.3      03-Mar-2008 Rajeev Kamath          Bug Fixes - QC 4480           |
-- |2.3      04-Apr-2008 Sreedhar Mohan         Changes for SFA contacts and  |
-- |                                            contact_points                |
-- |2.4      03-Jul-2007 Rajeev Kamath          QC: 8454 Update Relatioship   |
-- |2.5      02-Nov-2016 Hanmanth Jogiraju      Def 39738 - Retrofitted to use editioning views instead of tables |
-- +==========================================================================+

AS
    -- +=================================================+
    -- | Name        : Log_Predicate                     |
    -- | Description : Procedure to log exceptions using |
    -- |               the EBS Error Handling Strategy   |
    -- |                                                 |
    -- | Parameters  : Predicate_Function                |
    -- |               Predicate                         |
    -- |                                                 |
    -- +=================================================+

        PROCEDURE Log_Predicate ( p_predicate_function  IN  VARCHAR2
                                 ,p_predicate           IN  VARCHAR2 )
        IS
        PRAGMA AUTONOMOUS_TRANSACTION;

            lc_retcode   VARCHAR2(4000);

            ld_sysdate   DATE   := SYSDATE;

            ln_login     NUMBER := FND_GLOBAL.Login_Id;
            ln_msg_count NUMBER;
            ln_user_id   NUMBER := FND_GLOBAL.User_Id;

        BEGIN                               -- Procedure Block
            HZ_UTILITY_V2PUB.Debug (
                p_message        => p_predicate_function || p_predicate
               ,p_prefix         => 'DEBUG'
               ,p_msg_level      => FND_LOG.LEVEL_STATEMENT
               ,p_module_prefix  => 'E0266_RoleRestrictionsMerges'
               ,p_module         => 'CDH'
               );

            gc_step_number := gc_step_number + 1;

        END Log_Predicate;                -- End Procedure Block


-- +===================================================================+
-- | Name        : disable_policy                                      |
-- | Description : This function checks if the "dnb" context is set for|
-- |               for bulk import. If set, there should be no         |
-- |               predicate else errors on                            |
-- |      ORA-12408: unsupported operation: CONTENT_SOURCE_TYPE_SEC    |
-- |      Stage 2 worker: SQLERRM: User-Defined Exception              |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_custom_max_errors                                |
-- |                                                                   |
-- +===================================================================+
function disable_policy return boolean is
    l_context                       VARCHAR2(10);
BEGIN
    l_context := NVL(SYS_CONTEXT('hz', 'dnb_used'),'N');
    -- If the context is set, then policies need to be disabled
    -- since this is currently being diabled for "Import Batch to TCA Registry"
    if (l_context = 'Y') then
        Log_Predicate(p_predicate_function => 'SysContext(hz-dnb_used) is set', p_predicate => '-');
        return true;
    else
        return false;
    end if;
END;

function is_application_id_exist (p_value_set_name varchar2,
                                  p_application_id number)
return boolean is
  lb_exist boolean := false;
  ln_count number;
  cursor get_appl_id (p_value_set_name varchar2, p_application_id number)
  is
    select count(1) 
    from FND_FLEX_VALUES_VL c , 
         FND_FLEX_VALUE_SETS s 
    where c.flex_value_set_id = s.flex_value_set_id 
    and s.flex_value_set_name = p_value_set_name
    and c.enabled_flag = 'Y' 
    and sysdate between nvl(c.start_date_active, sysdate - 1) 
    and nvl(c.end_date_active, sysdate + 1)
    and c.flex_value=p_application_id;
begin
  open get_appl_id(p_value_set_name, p_application_id);
  fetch get_appl_id into ln_count;
  close get_appl_id;
  if ln_count > 0 then
    lb_exist := true;
  else
    lb_exist := false;
  end if;
  return lb_exist;
end is_application_id_exist;

-- ---------------------
-- Procedure Definitions
-- ---------------------

    -- +=================================================+
    -- | Name        : Log_Exception                     |
    -- | Description : Procedure to log exceptions using |
    -- |               the EBS Error Handling Strategy   |
    -- |                                                 |
    -- | Parameters  : Error_Location                    |
    -- |               Error_Msg                         |
    -- |                                                 |
    -- +=================================================+

        PROCEDURE Log_Exception ( p_error_location    IN  VARCHAR2
                                 ,p_error_msg         IN  VARCHAR2 )
        IS

            lc_retcode   VARCHAR2(4000);

            ld_sysdate   DATE   := SYSDATE;

            ln_login     NUMBER := FND_GLOBAL.Login_Id;
            ln_msg_count NUMBER;
            ln_user_id   NUMBER := FND_GLOBAL.User_Id;

        BEGIN                               -- Procedure Block

            xx_com_error_log_pub.Log_Error (
                p_return_code             => lc_retcode
               ,p_msg_count               => ln_msg_count
               ,p_application_name        => 'EBS'
               ,p_program_type            => 'Extension'
               ,p_program_name            => 'E0266_RoleRestrictionsMerges'
               ,p_module_name             => 'CDH'
               ,p_error_location          => p_error_location
               ,p_error_message_count     => 1
               ,p_error_message_code      => 'E'
               ,p_error_message           => p_error_msg
               ,p_error_message_severity  => NULL
               ,p_error_status            => 'EXCEPTION'
               ,p_notify_flag             => 'N'
               ,p_object_type             => 'User'
               ,p_object_id               => ln_user_id
               ,p_creation_date           => ld_sysdate
               ,p_created_by              => ln_user_id
               ,p_last_update_date        => ld_sysdate
               ,p_last_updated_by         => ln_user_id
               ,p_last_update_login       => ln_login
               );

            HZ_UTILITY_V2PUB.Debug (
                p_message        => p_error_location || p_error_msg
               ,p_prefix         => 'DEBUG'
               ,p_msg_level      => FND_LOG.LEVEL_EXCEPTION
               ,p_module_prefix  => 'E0266_RoleRestrictionsMerges'
               ,p_module         => 'CDH'
               );

        END Log_Exception;                -- End Procedure Block


-- --------------------
-- Function Definitions
-- --------------------

    -- +=================================================+
    -- | Name        : hz_party_create                   |
    -- | Description : HZ_PARTIES Table                  |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_party_create ( p_obj_schema  IN VARCHAR2
                                  ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate     VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PARTY_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;
            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;
            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_party_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_party_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_party_create;

    -- +=================================================+
    -- | Name        : hz_party_update                   |
    -- | Description : HZ_PARTIES Table                  |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_party_update ( p_obj_schema  IN VARCHAR2
                                  ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PARTY_UPDT_ACCESS'),'R');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PARTY_UPDT_ACCESS') ,'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || ' WHERE  HCA.party_id   = '|| p_obj_name ||'.party_id )';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_party_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_party_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_party_update;

    -- +=================================================+
    -- | Name        : hz_partysite_create               |
    -- | Description : HZ_PARTY_SITES Table              |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_partysite_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_SITES_CREATE_ACCESS'),'N');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_CREATE_ACCESS') ,'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'N' ) THEN

                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || ' WHERE  HCA.party_id   = '|| p_obj_name ||'.party_id )';

                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_partysite_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_partysite_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_partysite_create;

    -- +=================================================+
    -- | Name        : hz_partysite_update               |
    -- | Description : HZ_PARTY_SITES Table              |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_partysite_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_SITES_UPDT_ACCESS'),'R');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_UPDT_ACCESS') ,'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || ' WHERE  HCA.party_id   = '|| p_obj_name ||'.party_id )';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_partysite_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_partysite_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_partysite_update;

    -- +=================================================+
    -- | Name        : hz_ptysite_uses_create            |
    -- | Description : HZ_PARTY_SITE_USES Table          |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_ptysite_uses_create ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_SITE_USE_CREATE_ACCESS'),'N');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USE_CREATE_ACCESS') ,'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'N' ) THEN

                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || '       ,hz_party_sites   HPS'
                                                       || ' WHERE  HCA.party_id      = HPS.party_id'
                                                       || ' AND    HPS.party_site_id = '|| p_obj_name ||'.party_site_id )';

                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_ptysite_uses_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_ptysite_uses_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_ptysite_uses_create;

    -- +=================================================+
    -- | Name        : hz_ptysite_uses_update            |
    -- | Description : HZ_PARTY_SITE_USES Table          |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_ptysite_uses_update ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_SITE_USE_UPDT_ACCESS'),'R');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USE_UPDT_ACCESS') ,'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || '       ,hz_party_sites   HPS'
                                                       || ' WHERE  HCA.party_id      = HPS.party_id'
                                                       || ' AND    HPS.party_site_id = '|| p_obj_name ||'.party_site_id )';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_ptysite_uses_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_ptysite_uses_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_ptysite_uses_update;

    -- +=================================================+
    -- | Name        : hz_org_profile_create             |
    -- | Description : HZ_ORGANIZATION_PROFILES Table    |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_org_profile_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_PROF_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy and (FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES') = 'Y') ) then
                Log_Predicate ( p_predicate_function => ' Function : hz_org_profile_create  [' || p_obj_schema ||'.'
                                                      || p_obj_name ||']  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => 'Bypass = Y and dnb_used context is set');

                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_org_profile_create  [' || p_obj_schema ||'.'|| p_obj_name ||']  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_org_profile_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_org_profile_create;

    -- +=================================================+
    -- | Name        : hz_org_profile_update             |
    -- | Description : HZ_ORGANIZATION_PROFILES Table    |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_org_profile_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_PROF_UPDT_ACCESS'),'R');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_ORGPROF_UPDT_ACCESS')  ,'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy and (FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES') = 'Y') ) then
                Log_Predicate ( p_predicate_function => ' Function : hz_org_profile_update  [' || p_obj_schema ||'.'
                                                      || p_obj_name ||']  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => 'Bypass = Y and dnb_used context is set');
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || ' WHERE  HCA.party_id   = '||p_obj_name||'.party_id )';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_org_profile_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_org_profile_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_org_profile_update;

    -- +=================================================+
    -- | Name        : hz_person_profile_create          |
    -- | Description : HZ_PERSON_PROFILES Table          |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_person_profile_create ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PER_PROF_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy and (FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES') = 'Y') ) then
                Log_Predicate ( p_predicate_function => ' Function : hz_person_profile_create  [' || p_obj_schema ||'.'
                                                      || p_obj_name ||']  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => 'Bypass = Y and dnb_used context is set');
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_person_profile_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_person_profile_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_person_profile_create;

    -- +=================================================+
    -- | Name        : hz_person_profile_update          |
    -- | Description : HZ_PERSON_PROFILES Table          |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_person_profile_update ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            ln_application_id number;
            lc_predicate      VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PER_PROF_UPDT_ACCESS'),'R');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PER_PROF_UPDT_ACCESS' ),'R');

        BEGIN
            ln_application_id := fnd_global.resp_appl_id;
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy and (FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES') = 'Y') ) then
                Log_Predicate ( p_predicate_function => ' Function : hz_person_profile_update  [' || p_obj_schema ||'.'
                                                      || p_obj_name ||']  [' || p_obj_schema ||'.'|| p_obj_name ||'] ' || ' [Application_id:' || ln_application_id || '] '
                               ,p_predicate          => 'Bypass = Y and dnb_used context is set');
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate := '1 = 1 and not exists (select 1 from ' ||
                                    ' hz_cust_account_roles vpdhcar, hz_relationships vpdhr  ' ||
                                    ' where vpdhcar.party_id = vpdhr.party_id  ' ||
                                    ' and vpdhr.subject_id = '||p_obj_name||'.party_id  ' ||
                                    ' and vpdhr.subject_type = ''PERSON'') ';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN

                   if (is_application_id_exist('XXOD_CDH_SEC_SFA_APPLICATIONS', ln_application_id)) then

                          lc_predicate := '1 = 1 and not exists (select 1 from ' ||
                                          ' hz_cust_account_roles vpdhcar, hz_relationships vpdhr, hz_role_responsibility vpdhrr ' ||
                                          ' where vpdhcar.party_id = vpdhr.party_id ' ||
                                          ' and vpdhrr.cust_account_role_id = vpdhcar.cust_account_role_id ' ||
                                          ' and vpdhr.subject_id = '||p_obj_name||'.party_id ' ||
                                          ' and vpdhr.subject_type = ''PERSON'') ';
                         
                   else  
                            if (is_application_id_exist('XXOD_CDH_SEC_GETPAID_APPLICATIONS', ln_application_id)) then
                            lc_predicate := '1 = 1 and ((exists (select 1 from ' ||
                                          ' hz_cust_account_roles vpdhcar, hz_relationships vpdhr, hz_role_responsibility vpdhrr ' ||
                                          ' where vpdhcar.party_id = vpdhr.party_id ' ||
                                          ' and vpdhrr.cust_account_role_id = vpdhcar.cust_account_role_id ' ||
                                          ' and vpdhr.subject_id = '||p_obj_name||'.party_id ' ||
                                          ' and vpdhrr.RESPONSIBILITY_TYPE IN (select c.flex_value  ' ||
                                          ' from FND_FLEX_VALUES_VL c , FND_FLEX_VALUE_SETS s  ' ||
                                          ' where c.flex_value_set_id = s.flex_value_set_id  ' ||
                                          ' and s.flex_value_set_name = ''XXOD_CDH_SEC_CNT_ROLE_GETPAID''  ' ||
                                          ' and c.enabled_flag = ''Y''  ' ||
                                          ' and sysdate between nvl(c.start_date_active, sysdate - 1) and nvl(c.end_date_active, sysdate + 1) ) ' ||
                                          ' and vpdhr.subject_type = ''PERSON'')) or (not exists (select 1 from ' ||
                                          ' hz_cust_account_roles vpdhcar, hz_relationships vpdhr, hz_role_responsibility vpdhrr ' ||
                                          ' where vpdhcar.party_id = vpdhr.party_id ' ||
                                          ' and vpdhrr.cust_account_role_id = vpdhcar.cust_account_role_id ' ||
                                          ' and vpdhr.subject_id = '||p_obj_name||'.party_id )))';
                            
                            else
                              lc_predicate := '1 = 2';
                            end if;
                   end if;


                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_person_profile_update  [' || p_obj_schema ||'.'|| p_obj_name ||']' || ' [Application_id:' || ln_application_id || '] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_person_profile_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_person_profile_update;

    -- +=================================================+
    -- | Name        : hz_relationships_create           |
    -- | Description : HZ_RELATIONSHIPS Table            |
    -- |               Predicate Function for Insert     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+

        FUNCTION hz_relationships_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate      VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_BUS_RELN_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSIF ( lc_profile_prosp = 'N' ) THEN
                    lc_predicate := '1 = 2';
                ELSE
                    -- QC: 4480. Need to allow certain types of relations
                    lc_predicate := '1 = 1 AND RELATIONSHIP_TYPE  IN (select c.flex_value '
                                          || ' from FND_FLEX_VALUES_VL c , FND_FLEX_VALUE_SETS s '
                                          || ' where c.flex_value_set_id = s.flex_value_set_id '
                                          || ' and s.flex_value_set_name = ''' || lc_profile_prosp 
                                          || ''' and c.enabled_flag = ''Y'' '
                                          || ' and sysdate between nvl(c.start_date_active, sysdate - 1) and nvl(c.end_date_active, sysdate + 1) )';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_relationships_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_relationships_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_relationships_create;

    -- +=================================================+
    -- | Name        : hz_relationships_update           |
    -- | Description : HZ_RELATIONSHIPS Table            |
    -- |               Predicate Function for Update     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_relationships_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate      VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_BUS_RELN_UPDT_ACCESS'),'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSIF ( lc_profile_prosp = 'N' ) THEN
                    lc_predicate := '1 = 2';
                ELSE
                    -- QC: 4480. Need to allow certain types of relations                
                    lc_predicate := '1 = 1 AND RELATIONSHIP_TYPE  IN (select c.flex_value '
                                          || ' from FND_FLEX_VALUES_VL c , FND_FLEX_VALUE_SETS s '
                                          || ' where c.flex_value_set_id = s.flex_value_set_id '
                                          || ' and s.flex_value_set_name = ''' || lc_profile_prosp 
                                          || ''' and c.enabled_flag = ''Y'' '
                                          || ' and sysdate between nvl(c.start_date_active, sysdate - 1) and nvl(c.end_date_active, sysdate + 1) )';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_relationships_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_relationships_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_relationships_update;

    -- +=================================================+
    -- | Name        : hz_contact_pnt_create             |
    -- | Description : HZ_CONTACT_POINTS Table           |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_contact_pnt_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_CONT_POINTS_CREATE_ACCESS'),'N');
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_CONT_POINTS_CREATE_ACCESS') ,'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'CO' AND lc_profile_acct = 'CO' ) THEN

                    lc_predicate := ' 1=1 AND NOT EXISTS (SELECT party_id ' ||
                                                         ' FROM  hz_cust_account_roles ' ||
                                                         ' WHERE party_id = ' ||p_obj_name||'.owner_table_id) ' ||
                                          ' AND   EXISTS ( SELECT 1 ' ||
                                          '                FROM   hz_parties ' ||
                                          '                WHERE  hz_parties.party_id = '||p_obj_name||'.owner_table_id ' ||
                                          '                AND    hz_parties.party_type <> ''PARTY_RELATIONSHIP'' )';

                ELSIF ( lc_profile_prosp = 'CO' AND lc_profile_acct = 'COC' ) THEN

                    lc_predicate := ' 1=1 AND (( NOT EXISTS ( SELECT 1' 
                                                          || ' FROM   hz_cust_accounts HCA'
                                                          || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' ||
                                                   ' AND   EXISTS ( SELECT 1 ' ||
                                                   '       FROM   hz_parties ' ||
                                                   '       WHERE  hz_parties.party_id = ' ||p_obj_name||'.owner_table_id ' ||
                                                   '       AND    hz_parties.party_type <> ''PARTY_RELATIONSHIP'' ))' ||
                                              ' OR EXISTS ( SELECT party_id ' ||
                                                           ' FROM  hz_cust_account_roles ' ||
                                                           ' WHERE party_id = ' ||p_obj_name||'.owner_table_id )) ';

                ELSIF ( lc_profile_prosp = 'CO' AND lc_profile_acct = 'N' ) THEN

                    lc_predicate :=   ' 1 = 1 AND NOT EXISTS ( SELECT 1'
                                                          || ' FROM   hz_cust_accounts HCA'
                                                          || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '      AND      EXISTS ( SELECT 1 ' ||
                                      '                        FROM   hz_parties ' ||
                                      '                        WHERE  hz_parties.party_id = ' ||p_obj_name||'.owner_table_id ' ||
                                      '                        AND    hz_parties.party_type <> ''PARTY_RELATIONSHIP'' )' ;

                ELSIF ( lc_profile_prosp = 'CO' AND lc_profile_acct = 'Y' ) THEN

                    lc_predicate :=   ' 1 = 1 AND EXISTS ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id)' ;

                ELSIF ( lc_profile_prosp = 'COC' AND lc_profile_acct = 'CO' ) THEN

                    lc_predicate := ' 1 = 1 AND  (EXISTS ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'''
                                                      || ' AND    NOT EXISTS (SELECT party_id '
                                                      || '                    FROM   hz_cust_account_roles HAC '
                                                      || '                    WHERE  HAC.party_id = HP.party_id))'
                                               ||' OR EXISTS (SELECT 1'
                                               ||            ' FROM  hz_cust_accounts HAC '
                                               ||            ' WHERE HAC.party_id = ' ||p_obj_name||'.owner_table_id))';
                                                      
                ELSIF ( lc_profile_prosp = 'COC' AND lc_profile_acct = 'COC' ) THEN

                    lc_predicate := '  1 = 1 AND EXISTS      ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'')';

                ELSIF ( lc_profile_prosp = 'COC' AND lc_profile_acct = 'N' ) THEN

                    lc_predicate := '   1 = 1 AND EXISTS  ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'''
                                                      || ' AND    NOT EXISTS (SELECT party_id '
                                                      || '                    FROM   hz_cust_account_roles HAC '
                                                      || '                    WHERE  HAC.party_id = HP.party_id))';

                ELSIF ( lc_profile_prosp = 'COC' AND lc_profile_acct = 'Y' ) THEN

                    lc_predicate := ' 1 = 1 AND  (EXISTS ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'''
                                                      || ' AND    NOT EXISTS (SELECT party_id '
                                                      || '                    FROM   hz_cust_account_roles HAC '
                                                      || '                    WHERE  HAC.party_id = HP.party_id))'
                                               ||' OR EXISTS (SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type <> ''PARTY_RELATIONSHIP'')';

                ELSIF ( lc_profile_prosp = 'N' ) THEN

                    lc_predicate := ' 1 = 2';

                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'CO' ) THEN

                    lc_predicate :=   ' 1 = 1 AND (( NOT EXISTS ( SELECT 1'
                                                             || ' FROM   hz_cust_accounts HCA'
                                                             || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '              AND  NOT EXISTS ( SELECT 1 ' ||
                                      '                                FROM   hz_cust_account_roles ' ||
                                      '                                WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)) ' 
                                  ||  '       OR ( EXISTS    ( SELECT 1'
                                                          || ' FROM   hz_cust_accounts HCA'
                                                          || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)))' ;

                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'COC' ) THEN

                    lc_predicate :=   ' 1 = 1 AND (( NOT EXISTS ( SELECT 1'
                                                             || ' FROM   hz_cust_accounts HCA'
                                                             || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '              AND  NOT EXISTS ( SELECT 1 ' ||
                                      '                                FROM   hz_cust_account_roles ' ||
                                      '                                WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)) ' 
                                  ||  '       OR ( EXISTS    ( SELECT 1'
                                                          || ' FROM   hz_cust_account_roles '
                                                          || ' WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)))' ;

                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'N' ) THEN

                    lc_predicate :=   ' 1 = 1 AND (( NOT EXISTS ( SELECT 1'
                                                             || ' FROM   hz_cust_accounts HCA'
                                                             || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '              AND  NOT EXISTS ( SELECT 1 ' ||
                                      '                                FROM   hz_cust_account_roles ' ||
                                      '                                WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)) ';

                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '  1 = 1 ';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_contact_pnt_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_contact_pnt_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_contact_pnt_create;

    -- +=================================================+
    -- | Name        : hz_contact_pnt_update             |
    -- | Description : HZ_CONTACT_POINTS Table           |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_contact_pnt_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_CONT_POINTS_UPDT_ACCESS'),'R');
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_CONT_POINTS_UPDT_ACCESS') ,'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_prosp = 'UO' AND lc_profile_acct = 'UO' ) THEN

                    lc_predicate := ' 1=1 AND NOT EXISTS (SELECT party_id ' ||
                                                         ' FROM  hz_cust_account_roles ' ||
                                                         ' WHERE party_id = ' ||p_obj_name||'.owner_table_id) ' ||
                                          ' AND   EXISTS ( SELECT 1 ' ||
                                          '                FROM   hz_parties ' ||
                                          '                WHERE  hz_parties.party_id = ' ||p_obj_name||'.owner_table_id ' ||
                                          '                AND    hz_parties.party_type <> ''PARTY_RELATIONSHIP'' )';

                ELSIF ( lc_profile_prosp = 'UO' AND lc_profile_acct = 'UOC' ) THEN

                    lc_predicate := ' 1=1 AND (( NOT EXISTS ( SELECT 1' 
                                                          || ' FROM   hz_cust_accounts HCA'
                                                          || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' ||
                                                   ' AND   EXISTS ( SELECT 1 ' ||
                                                   '       FROM   hz_parties ' ||
                                                   '       WHERE  hz_parties.party_id = ' ||p_obj_name||'.owner_table_id ' ||
                                                   '       AND    hz_parties.party_type <> ''PARTY_RELATIONSHIP'' ))' ||
                                              ' OR EXISTS ( SELECT party_id ' ||
                                                           ' FROM  hz_cust_account_roles ' ||
                                                           ' WHERE party_id = ' ||p_obj_name||'.owner_table_id )) ';

                ELSIF ( lc_profile_prosp = 'UO' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate :=   ' 1 = 1 AND NOT EXISTS ( SELECT 1'
                                                          || ' FROM   hz_cust_accounts HCA'
                                                          || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '      AND      EXISTS ( SELECT 1 ' ||
                                      '                        FROM   hz_parties ' ||
                                      '                        WHERE  hz_parties.party_id = ' ||p_obj_name||'.owner_table_id ' ||
                                      '                        AND    hz_parties.party_type <> ''PARTY_RELATIONSHIP'' )' ;

                ELSIF ( lc_profile_prosp = 'UO' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate :=   ' 1 = 1 AND EXISTS ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id)' ;

                ELSIF ( lc_profile_prosp = 'UOC' AND lc_profile_acct = 'UO' ) THEN

                    lc_predicate := ' 1 = 1 AND  (EXISTS ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'''
                                                      || ' AND    NOT EXISTS (SELECT party_id '
                                                      || '                    FROM   hz_cust_account_roles HAC '
                                                      || '                    WHERE  HAC.party_id = HP.party_id))'
                                               ||' OR EXISTS (SELECT 1'
                                               ||            ' FROM  hz_cust_accounts HAC '
                                               ||            ' WHERE HAC.party_id = ' ||p_obj_name||'.owner_table_id))';
                                                      
                ELSIF ( lc_profile_prosp = 'UOC' AND lc_profile_acct = 'UOC' ) THEN

                    lc_predicate := '  1 = 1 AND EXISTS      ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'')';

                ELSIF ( lc_profile_prosp = 'UOC' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate := '   1 = 1 AND EXISTS  ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'''
                                                      || ' AND    NOT EXISTS (SELECT party_id '
                                                      || '                    FROM   hz_cust_account_roles HAC '
                                                      || '                    WHERE  HAC.party_id = HP.party_id))';

                ELSIF ( lc_profile_prosp = 'UOC' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate := ' 1 = 1 AND  (EXISTS ( SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type = ''PARTY_RELATIONSHIP'''
                                                      || ' AND    NOT EXISTS (SELECT party_id '
                                                      || '                    FROM   hz_cust_account_roles HAC '
                                                      || '                    WHERE  HAC.party_id = HP.party_id))'
                                               ||' OR EXISTS (SELECT 1'
                                                      || ' FROM   hz_parties HP'
                                                      || ' WHERE  HP.party_id = ' ||p_obj_name||'.owner_table_id'
                                                      || ' AND    HP.party_type <> ''PARTY_RELATIONSHIP'')';

                ELSIF ( lc_profile_prosp = 'R' ) THEN

                    lc_predicate := ' 1 = 2';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'UO' ) THEN

                    lc_predicate :=   ' 1 = 1 AND (( NOT EXISTS ( SELECT 1'
                                                             || ' FROM   hz_cust_accounts HCA'
                                                             || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '              AND  NOT EXISTS ( SELECT 1 ' ||
                                      '                                FROM   hz_cust_account_roles ' ||
                                      '                                WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)) ' 
                                  ||  '       OR ( EXISTS    ( SELECT 1'
                                                          || ' FROM   hz_cust_accounts HCA'
                                                          || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)))' ;

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'UOC' ) THEN

                    lc_predicate :=   ' 1 = 1 AND (( NOT EXISTS ( SELECT 1'
                                                             || ' FROM   hz_cust_accounts HCA'
                                                             || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '              AND  NOT EXISTS ( SELECT 1 ' ||
                                      '                                FROM   hz_cust_account_roles ' ||
                                      '                                WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)) ' 
                                  ||  '       OR ( EXISTS    ( SELECT 1'
                                                          || ' FROM   hz_cust_account_roles '
                                                          || ' WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)))' ;

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN

                    lc_predicate :=   ' 1 = 1 AND (( NOT EXISTS ( SELECT 1'
                                                             || ' FROM   hz_cust_accounts HCA'
                                                             || ' WHERE  HCA.party_id = ' ||p_obj_name||'.owner_table_id)' 
                                  ||  '              AND  NOT EXISTS ( SELECT 1 ' ||
                                      '                                FROM   hz_cust_account_roles ' ||
                                      '                                WHERE  hz_cust_account_roles.party_id = ' ||p_obj_name||'.owner_table_id)) ';

                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN

                    lc_predicate := '  1 = 1 ';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_contact_pnt_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_contact_pnt_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_contact_pnt_update;

    -- +=================================================+
    -- | Name        : hz_org_contact_create             |
    -- | Description : HZ_ORG_CONTACTS Table             |
    -- |               Predicate Function for Insert     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+
        FUNCTION hz_org_contact_create ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_CONT_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF  ( lc_profile_prosp = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_contact_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;

            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_contact_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_contact_create;

    -- +=================================================+
    -- | Name        : hz_org_contact_update             |
    -- | Description : HZ_ORG_CONTACTS Table             |
    -- |               Predicate Function for Update     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+
        FUNCTION hz_org_contact_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_CONT_UPDT_ACCESS'),'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'U' )  THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_contact_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;

            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_contact_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_contact_update;

    -- +=================================================+
    -- | Name        : hz_org_cnts_rls_create            |
    -- | Description : HZ_ORG_CONTACT_ROLES Table        |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_org_cnts_rls_create ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_CONT_ROLES_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'Y' ) THEN
                    lc_predicate := '1 = 1'; 
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_cnts_rls_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;

            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_cnts_rls_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_cnts_rls_create;

    -- +=================================================+
    -- | Name        : hz_org_cnts_rls_update            |
    -- | Description : HZ_ORG_CONTACT_ROLES Table        |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_org_cnts_rls_update ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_CONT_ROLES_UPDT_ACCESS'),'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'U' ) THEN
                    lc_predicate := '1 = 1'; 
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_cnts_rls_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;

            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_cnts_rls_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_cnts_rls_update;



    -- +=================================================+
    -- | Name        : hz_cust_acct_create               |
    -- | Description : HZ_CUST_ACCOUNTS Table            |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PARTY_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_create;

    -- +=================================================+
    -- | Name        : hz_cust_acct_update               |
    -- | Description : HZ_CUST_ACCOUNTS Table            |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PARTY_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_update;

    -- +=================================================+
    -- | Name        : hz_customer_prf_create            |
    -- | Description : HZ_CUSTOMER_PROFILES Table        |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_customer_prf_create ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_TRX_N_DOC_PROF_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_acct = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_customer_prf_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_customer_prf_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_customer_prf_create;

    -- +=================================================+
    -- | Name        : hz_customer_prf_update            |
    -- | Description : HZ_CUSTOMER_PROFILES Table        |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_customer_prf_update ( p_obj_schema  IN VARCHAR2
                                         ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_TRX_N_DOC_PROF_UPDT_ACCESS'),'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_acct = 'U' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_customer_prf_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_customer_prf_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_customer_prf_update;

    -- +=================================================+
    -- | Name        : hz_cust_acct_sites_create         |
    -- | Description : HZ_CUST_ACCT_SITES_ALL Table      |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_sites_create ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_sites_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_sites_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_sites_create;

    -- +=================================================+
    -- | Name        : hz_cust_acct_sites_update         |
    -- | Description : HZ_CUST_ACCT_SITES_ALL Table      |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_sites_update ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_sites_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_sites_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_sites_update;

    -- +=================================================+
    -- | Name        : hz_cust_site_uses_create          |
    -- | Description : HZ_CUST_SITE_USES_ALL Table       |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_site_uses_create ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USE_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_site_uses_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_site_uses_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_site_uses_create;

    -- +=================================================+
    -- | Name        : hz_cust_site_uses_update          |
    -- | Description : HZ_CUST_SITE_USES_ALL Table       |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_site_uses_update ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USE_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_site_uses_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_site_uses_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_site_uses_update;

    -- +=================================================+
    -- | Name        : hz_cust_acct_rls_create           |
    -- | Description : HZ_CUST_ACCOUNT_ROLES Table       |
    -- |               Predicate Function for Insert     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+

        FUNCTION hz_cust_acct_rls_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_CONT_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                -- QC Defect: 4480
                -- HZ_CUST_ACCOUNT_ROLES just has "CONTACT" role types - nothing else
                -- Resolution is to combine YAR and Y - since they both mean the same in this case.
                IF ( ( lc_profile_acct = 'YAR' ) OR ( lc_profile_acct = 'Y' ) ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_rls_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_cust_acct_rls_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_cust_acct_rls_create;

    -- +=================================================+
    -- | Name        : hz_cust_acct_rls_update           |
    -- | Description : HZ_CUST_ACCOUNT_ROLES Table       |
    -- |               Predicate Function for Update     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+

        FUNCTION hz_cust_acct_rls_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000):= '1 = 1';
            lc_profile_acct     VARCHAR2(60)  := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_CONT_UPDT_ACCESS') ,'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                -- QC Defect: 4480
                -- HZ_CUST_ACCOUNT_ROLES just has "CONTACT" role types - nothing else
                -- Resolution is to combine UAR and U - since they both mean the same in this case.
                IF ( ( lc_profile_acct = 'UAR' ) OR ( lc_profile_acct = 'U' ) )THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_rls_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_cust_acct_rls_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_cust_acct_rls_update;

    -- +=================================================+
    -- | Name        : hz_role_resp_create               |
    -- | Description : HZ_ROLE_RESPONSIBILITY Table      |
    -- |               Predicate Function for Insert     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+
        FUNCTION hz_role_resp_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_CONT_ROLES_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                -- QC Defect: 4480
                -- HZ_ROLE_RESPONSIBILITY has RESPONSIBILITY_TYPE. This must be used rather than joins to role types.
                IF ( lc_profile_acct = 'YAR' ) THEN
                    lc_predicate := '1 = 1 AND RESPONSIBILITY_TYPE IN (''DUN'',''CREDIT_CONTACT'',''STMTS'',''SELF_SERVICE_USER'', ''BILLING'')';
                ELSIF ( lc_profile_acct = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_role_resp_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;

            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_role_resp_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_role_resp_create;

    -- +=================================================+
    -- | Name        : hz_role_resp_update               |
    -- | Description : HZ_ROLE_RESPONSIBILITY Table      |
    -- |               Predicate Function for Update     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+
        FUNCTION hz_role_resp_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_CONT_ROLES_UPDT_ACCESS'),'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                -- QC Defect: 4480
                -- HZ_ROLE_RESPONSIBILITY has RESPONSIBILITY_TYPE. This must be used rather than joins to role type.            
                IF ( lc_profile_acct = 'UAR' ) THEN
                    lc_predicate := '1 = 1 AND RESPONSIBILITY_TYPE IN (''DUN'',''CREDIT_CONTACT'',''STMTS'',''SELF_SERVICE_USER'', ''BILLING'')';
                ELSIF ( lc_profile_acct = 'U' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_role_resp_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_role_resp_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_role_resp_update;

    -- +=================================================+
    -- | Name        : hz_cust_profile_amt_create        |
    -- | Description : HZ_CUST_PROFILE_AMTS Table        |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_profile_amt_create ( p_obj_schema  IN VARCHAR2
                                             ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_cust     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROF_AMTS_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_cust = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_profile_amt_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_profile_amt_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_profile_amt_create;

    -- +=================================================+
    -- | Name        : hz_cust_profile_amt_update        |
    -- | Description : HZ_CUST_PROFILE_AMTS Table        |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_profile_amt_update ( p_obj_schema  IN VARCHAR2
                                             ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_cust     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROF_AMTS_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_cust = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_profile_amt_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_profile_amt_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_profile_amt_update;

    -- +=================================================+
    -- | Name        : hz_cust_acct_rlt_create           |
    -- | Description : HZ_CUST_ACCT_RELATE_ALL Table     |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_rlt_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_RELN_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'CO' ) THEN

                    lc_predicate := '1 = 1 AND hz_cust_acct_relate_all.relationship_type NOT IN ( ''GLOBAL_SUBSIDIARY_OF'''
                                                                                              ||',''SUBSIDIARY_OF'''
                                                                                              ||',''GLOBAL_ULTIMATE_OF'''
                                                                                              ||',''PARENT_OF'''
                                                                                              ||',''DIVISION_OF'''
                                                                                              ||',''CHILD_OF'''
                                                                                              ||',''HEADQUARTERS_OF'' )';


                ELSIF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_rlt_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_rlt_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_rlt_create;

    -- +=================================================+
    -- | Name        : hz_cust_acct_rlt_update           |
    -- | Description : HZ_CUST_ACCT_RELATE_ALL Table     |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_rlt_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_RELN_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'UO' ) THEN

                    lc_predicate := '1 = 1 AND hz_cust_acct_relate_all.relationship_type NOT IN ( ''GLOBAL_SUBSIDIARY_OF'''
                                                                                              ||',''SUBSIDIARY_OF'''
                                                                                              ||',''GLOBAL_ULTIMATE_OF'''
                                                                                              ||',''PARENT_OF'''
                                                                                              ||',''DIVISION_OF'''
                                                                                              ||',''CHILD_OF'''
                                                                                              ||',''HEADQUARTERS_OF'' )';

                ELSIF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_rlt_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_rlt_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_rlt_update;

    -- +=================================================+
    -- | Name        : ap_bank_acct_create               |
    -- | Description : AP_BANK_ACCOUNTS_ALL Table        |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION ap_bank_acct_create ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BANK_ACCTS_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : ap_bank_acct_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : ap_bank_acct_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END ap_bank_acct_create;

    -- +=================================================+
    -- | Name        : ap_bank_acct_update               |
    -- | Description : AP_BANK_ACCOUNTS_ALL Table        |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION ap_bank_acct_update ( p_obj_schema  IN VARCHAR2
                                      ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BANK_ACCTS_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : ap_bank_acct_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : ap_bank_acct_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END ap_bank_acct_update;

    -- +=================================================+
    -- | Name        : ap_bank_acct_use_create           |
    -- | Description : AP_BANK_ACCOUNT_USES_ALL Table    |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION ap_bank_acct_use_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BANK_ACCTS_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : ap_bank_acct_use_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : ap_bank_acct_use_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END ap_bank_acct_use_create;

    -- +=================================================+
    -- | Name        : ap_bank_acct_use_update           |
    -- | Description : AP_BANK_ACCOUNT_USES_ALL Table    |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION ap_bank_acct_use_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BANK_ACCTS_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : ap_bank_acct_use_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : ap_bank_acct_use_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END ap_bank_acct_use_update;

    -- +=================================================+
    -- | Name        : ra_cust_receipt_mtds_create       |
    -- | Description : RA_CUST_RECEIPT_METHODS Table     |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION ra_cust_receipt_mtds_create ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PAY_METH_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : ra_cust_receipt_mtds_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : ra_cust_receipt_mtds_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END ra_cust_receipt_mtds_create;

    -- +=================================================+
    -- | Name        : ra_cust_receipt_mtds_update       |
    -- | Description : RA_CUST_RECEIPT_METHODS Table     |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION ra_cust_receipt_mtds_update ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PAY_METH_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : ra_cust_receipt_mtds_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : ra_cust_receipt_mtds_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END ra_cust_receipt_mtds_update;

    -- +=================================================+
    -- | Name        : hz_org_profile_ext_create         |
    -- | Description : HZ_ORG_PROFILES_EXT_B and         |
    -- |               HZ_ORG_PROFILES_EXT_TL Tables     |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_org_profile_ext_create ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_PROF_EXT_CREATE_ACCESS'),'N');
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_ORG_PROF_EXT_CREATE_ACCESS') ,'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_acct = 'Y' ) THEN
                    IF ( lc_profile_prosp = 'Y' ) THEN
                        lc_predicate := '1 = 1';
                    ELSE
                        lc_predicate := '1 = 1 AND EXISTS ( SELECT 1'
                                                       || ' FROM   hz_organization_profiles      HOP'
                                                       || '       ,hz_cust_accounts              HCA'
                                                       || ' WHERE  HOP.party_id                = HCA.party_id'
                                                       || ' AND    HOP.organization_profile_id = ' || p_obj_name || '.organization_profile_id)';
                    END IF;
                ELSIF ( lc_profile_prosp = 'Y' ) THEN
                        lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_organization_profiles      HOP'
                                                       || '       ,hz_cust_accounts              HCA'
                                                       || ' WHERE  HOP.party_id                = HCA.party_id'
                                                       || ' AND    HOP.organization_profile_id = ' || p_obj_name || '.organization_profile_id)';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;
            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_profile_ext_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_profile_ext_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_profile_ext_create;

    -- +=================================================+
    -- | Name        : HZ_ORG_PROFILE_EXT_UPDATE         |
    -- | Description : HZ_ORG_PROFILES_EXT_B             |
    -- |               HZ_ORG_PROFILES_EXT_TL Table      |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION HZ_ORG_PROFILE_EXT_UPDATE   ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_PROF_EXT_UPDT_ACCESS'),'R');
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_ORG_PROF_EXT_UPDT_ACCESS') ,'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN
                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                        || ' FROM   hz_organization_profiles      HOP'
                                        || '       ,hz_cust_accounts              HCA'
                                        || ' WHERE  HOP.party_id                = HCA.party_id'
                                        || ' AND    HOP.organization_profile_id = ' || p_obj_name || '.organization_profile_id)';
                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_profile_ext_b_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_profile_ext_b_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END HZ_ORG_PROFILE_EXT_UPDATE;

    -- +=================================================+
    -- | Name        : HZ_ORG_PROFILE_EXT_DELETE         |
    -- | Description : HZ_ORG_PROFILES_EXT_B,            |
    -- |               HZ_ORG_PROFILES_EXT_TL Table      |
    -- |                                                 |
    -- |               Predicate Function for Delete     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION HZ_ORG_PROFILE_EXT_DELETE ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_PROF_EXT_DEL_ACCESS'),'N');
            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_ORG_PROF_EXT_DEL_ACCESS') ,'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'N' ) THEN
                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_organization_profiles      HOP'
                                                       || '       ,hz_cust_accounts              HCA'
                                                       || ' WHERE  HOP.party_id                = HCA.party_id'
                                                       || ' AND    HOP.organization_profile_id = ' || p_obj_name || '.organization_profile_id)';
                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : HZ_ORG_PROFILE_EXT_DELETE  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : HZ_ORG_PROFILE_EXT_DELETE '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END HZ_ORG_PROFILE_EXT_DELETE;

    -- +=================================================+
    -- | Name        : hz_per_profile_ext_create         |
    -- | Description : HZ_PER_PROFILES_EXT_B and         |
    -- |               HZ_PER_PROFILES_EXT_TL Tables     |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_per_profile_ext_create ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate             VARCHAR2(4000) := '1 = 1';
            lc_per_profile_ext       VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PER_PROF_EXT_CREATE_ACCESS'),'N');
            lc_per_acct_profile_ext  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PER_PROF_EXT_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_per_acct_profile_ext = 'Y' ) THEN
                    IF  ( lc_per_profile_ext  = 'Y' ) THEN
                        lc_predicate := '1 = 1';
                    ELSE
                        lc_predicate := '1 = 1 AND EXISTS ( SELECT 1 '
                                            ||' FROM HZ_PERSON_PROFILES HPP'
                                            ||'     ,HZ_CUST_ACCOUNTS   HCA'
                                            ||' WHERE HPP.PARTY_ID = HCA.PARTY_ID'
                                            ||' AND HPP.PERSON_PROFILE_ID = ' || p_obj_name || '.PERSON_PROFILE_ID)';
                    END IF;
                ELSE
                    IF  ( lc_per_profile_ext  = 'Y' ) THEN
                        lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1 '
                                            ||' FROM HZ_PERSON_PROFILES HPP'
                                            ||'     ,HZ_CUST_ACCOUNTS   HCA'
                                            ||' WHERE HPP.PARTY_ID = HCA.PARTY_ID'
                                            ||' AND HPP.PERSON_PROFILE_ID = ' || p_obj_name || '.PERSON_PROFILE_ID)';
                    ELSE
                        lc_predicate := '1 = 2';
                    END IF;
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_per_profile_ext_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_per_profile_ext_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_per_profile_ext_create;

    -- +=================================================+
    -- | Name        : hz_per_profile_ext_update         |
    -- | Description : HZ_PER_PROFILES_EXT_B, TL Table   |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_per_profile_ext_update ( p_obj_schema  IN VARCHAR2
                                            ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate             VARCHAR2(4000) := '1 = 1';
            lc_per_profile_ext_b     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PER_PROF_EXT_UPDT_ACCESS'),'R');
            lc_acct_profile_ext_b    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PER_PROF_EXT_UPDT_ACCESS'),'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_per_profile_ext_b = 'U' AND lc_acct_profile_ext_b = 'U' ) THEN
                    lc_predicate := '1 = 1';
                ELSIF ( lc_per_profile_ext_b = 'U' AND lc_acct_profile_ext_b = 'R' ) THEN
                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1 '
                                                        ||' FROM HZ_PERSON_PROFILES HPP'
                                                        ||'     ,HZ_CUST_ACCOUNTS   HCA'
                                                        ||' WHERE HPP.PARTY_ID = HCA.PARTY_ID'
                                                        ||' AND HPP.PERSON_PROFILE_ID = ' || p_obj_name || '.PERSON_PROFILE_ID)';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;
            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_per_profile_ext_b_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_per_profile_ext_b_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_per_profile_ext_update;


    -- +=================================================+
    -- | Name        : hz_per_profile_ext_delete         |
    -- | Description : HZ_PER_PROFILES_EXT_B, TL Table   |
    -- |                                                 |
    -- |               Predicate Function for Delete     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_per_profile_ext_delete ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate             VARCHAR2(4000) := '1 = 1';
            lc_per_profile_ext_b     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PER_PROF_EXT_DEL_ACCESS'),'N');
            lc_acct_profile_ext_b    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PER_PROF_EXT_DEL_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
               IF ( lc_per_profile_ext_b = 'Y' AND lc_acct_profile_ext_b = 'Y' ) THEN
                   lc_predicate := '1 = 1';
               ELSIF ( lc_per_profile_ext_b = 'Y' AND lc_acct_profile_ext_b = 'N' ) THEN
                   lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1 '
                                                                       ||' FROM HZ_PERSON_PROFILES HPP'
                                                                       ||'     ,HZ_CUST_ACCOUNTS   HCA'
                                                                       ||' WHERE HPP.PARTY_ID = HCA.PARTY_ID'
                                                                       ||' AND HPP.PERSON_PROFILE_ID = ' || p_obj_name || '.PERSON_PROFILE_ID)';

               ELSE
                    lc_predicate := '1 = 2';
               END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_per_profile_ext_b_delete  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_per_profile_ext_b_delete '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_per_profile_ext_delete;

    -- +=================================================+
    -- | Name        : hz_party_site_ext_create          |
    -- | Description : HZ_PARTY_SITES_EXT_B and          |
    -- |               HZ_PARTY_SITES_EXT_TL Tables      |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_party_site_ext_create ( p_obj_schema  IN VARCHAR2
                                           ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_prosp_ps_ext     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PARTY_SITES_EXT_CREATE_ACCESS'),'N');
            lc_acct_ps_ext     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PARTY_SITES_EXT_CREATE_ACCESS'),'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
               if (lc_acct_ps_ext = 'Y') then
                   IF ( lc_prosp_ps_ext = 'Y' ) THEN
                       lc_predicate := '1 = 1';
                   else
                       lc_predicate := '1=1 AND EXISTS ( SELECT 1 '
                                              ||' FROM HZ_CUST_ACCOUNTS HCA'
                                              ||'     ,HZ_PARTY_SITES   HPS'
                                              ||' WHERE HCA.PARTY_ID = HPS.PARTY_ID'
                                              ||' AND HPS.PARTY_SITE_ID = ' || p_obj_name || '.PARTY_SITE_ID)';
                   end if;
                ELSE
                    if ( lc_prosp_ps_ext = 'Y' ) THEN
                       lc_predicate := '1=1 AND NOT EXISTS ( SELECT 1 '
                                              ||' FROM HZ_CUST_ACCOUNTS HCA'
                                              ||'     ,HZ_PARTY_SITES   HPS'
                                              ||' WHERE HCA.PARTY_ID = HPS.PARTY_ID'
                                              ||' AND HPS.PARTY_SITE_ID = ' || p_obj_name || '.PARTY_SITE_ID)';
                    else
                        lc_predicate := '1 = 2';
                    end if;
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_party_site_ext_create [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_party_site_ext_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_party_site_ext_create;

    -- +=================================================+
    -- | Name        : hz_party_site_ext_update          |
    -- | Description : HZ_PARTY_SITES_EXT_B, TL Table    |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_party_site_ext_update   ( p_obj_schema  IN VARCHAR2
                                             ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate          VARCHAR2(4000) := '1 = 1';

            lc_prosp_ps_ext_b     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PARTY_SITES_EXT_UPDT_ACCESS'),'R');
            lc_acct_site_ext_b    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PARTY_SITES_EXT_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_prosp_ps_ext_b = 'U' AND lc_acct_site_ext_b = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSIF ( lc_prosp_ps_ext_b = 'U' AND lc_acct_site_ext_b = 'R' ) THEN

                    lc_predicate := 'NOT EXISTS ( SELECT 1 '
                                                      ||' FROM hz_cust_acct_sites_all HCA'
                                                      ||' WHERE HCA.PARTY_SITE_ID = ' || p_obj_name || '.PARTY_SITE_ID)';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_party_site_ext_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_party_site_ext_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_party_site_ext_update;

    -- +=================================================+
    -- | Name        : hz_party_site_ext_delete          |
    -- | Description : HZ_PARTY_SITES_EXT_B, TL Table    |
    -- |                                                 |
    -- |               Predicate Function for Delete     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_party_site_ext_delete   ( p_obj_schema  IN VARCHAR2
                                             ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate        VARCHAR2(4000) := '1 = 1';
            lc_prosp_ps_ext_b     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_PARTY_SITES_EXT_DEL_ACCESS'),'N');
            lc_acct_site_ext_b    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_PARTY_SITES_EXT_DEL_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_prosp_ps_ext_b = 'Y' AND lc_acct_site_ext_b = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSIF ( lc_prosp_ps_ext_b = 'Y' AND lc_acct_site_ext_b = 'N' ) THEN
                    lc_predicate := '1=1 AND NOT EXISTS ( SELECT 1 '
                                                      ||' FROM HZ_CUST_ACCOUNTS HCA'
                                                      ||'     ,HZ_PARTY_SITES   HPS'
                                                      ||' WHERE HCA.PARTY_ID = HPS.PARTY_ID'
                                                      ||' AND HPS.PARTY_SITE_ID = ' || p_obj_name || '.PARTY_SITE_ID)';
                ELSE
                   lc_predicate := '1 = 2';
                END IF;
            END IF;
            
            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_party_site_ext_delete  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_party_site_ext_delete '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_party_site_ext_delete;


    -- +=================================================+
    -- | Name        : hz_cust_acct_ext_create           |
    -- | Description : XX_CDH_CUST_ACCT_EXT_B and        |
    -- |               XX_CDH_CUST_ACCT_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_ext_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_acct_ext_crte    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCTS_EXT_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF (lc_acct_ext_crte = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_ext_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_ext_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_ext_create;

    -- +=================================================+
    -- | Name        : hz_cust_acct_ext_update           |
    -- | Description : XX_CDH_CUST_ACCT_EXT_B and        |
    -- |               XX_CDH_CUST_ACCT_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_ext_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_acct_ext_updt    VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCTS_EXT_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF (  lc_acct_ext_updt = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_ext_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_ext_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_ext_update;

    -- +=================================================+
    -- | Name        : hz_cust_acct_ext_delete           |
    -- | Description : XX_CDH_CUST_ACCT_EXT_B and        |
    -- |               XX_CDH_CUST_ACCT_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Delete     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_cust_acct_ext_delete ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_acct_ext_del     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCTS_EXT_DEL_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF (  lc_acct_ext_del = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_cust_acct_ext_delete  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_cust_acct_ext_delete '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_cust_acct_ext_delete;

    -- +=================================================+
    -- | Name        : hz_acct_site_ext_create           |
    -- | Description : XX_CDH_ACCT_SITE_EXT_B and        |
    -- |               XX_CDH_ACCT_SITE_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_acct_site_ext_create ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate              VARCHAR2(4000) := '1 = 1';

            lc_acct_site_ext_crte     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_EXT_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_acct_site_ext_crte = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_acct_site_ext_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_acct_site_ext_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_acct_site_ext_create;

    -- +=================================================+
    -- | Name        : hz_acct_site_ext_update           |
    -- | Description : XX_CDH_ACCT_SITE_EXT_B and        |
    -- |               XX_CDH_ACCT_SITE_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_acct_site_ext_update ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate              VARCHAR2(4000) := '1 = 1';

            lc_acct_site_ext_updt     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_EXT_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_acct_site_ext_updt = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_acct_site_ext_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_acct_site_ext_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_acct_site_ext_update;

    -- +=================================================+
    -- | Name        : hz_acct_site_ext_delete           |
    -- | Description : XX_CDH_ACCT_SITE_EXT_B and        |
    -- |               XX_CDH_ACCT_SITE_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Delete     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_acct_site_ext_delete ( p_obj_schema  IN VARCHAR2
                                          ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_acct_site_ext_del     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITES_EXT_DEL_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_acct_site_ext_del = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_acct_site_ext_delete  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_acct_site_ext_delete '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_acct_site_ext_delete;

    -- +=================================================+
    -- | Name        : hz_acct_site_use_ext_create       |
    -- | Description : XX_CDH_SITE_USES_EXT_B and        |
    -- |               XX_CDH_SITE_USES_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Insert     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_acct_site_use_ext_create ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USES_EXT_CREATE_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_acct_site_use_ext_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_acct_site_use_ext_create '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_acct_site_use_ext_create;

    -- +=================================================+
    -- | Name        : hz_acct_site_use_ext_update       |
    -- | Description : XX_CDH_SITE_USES_EXT_B and        |
    -- |               XX_CDH_SITE_USES_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Update     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_acct_site_use_ext_update ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USES_EXT_UPDT_ACCESS'),'R');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'U' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_acct_site_use_ext_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_acct_site_use_ext_update '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_acct_site_use_ext_update;

    -- +=================================================+
    -- | Name        : hz_acct_site_use_ext_delete       |
    -- | Description : XX_CDH_SITE_USES_EXT_B  and       |
    -- |               XX_CDH_SITE_USES_EXT_TL Tables    |
    -- |                                                 |
    -- |               Predicate Function for Delete     |
    -- |                                                 |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- |                                                 |
    -- +=================================================+

        FUNCTION hz_acct_site_use_ext_delete ( p_obj_schema  IN VARCHAR2
                                              ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS

            lc_predicate        VARCHAR2(4000) := '1 = 1';

            lc_profile_acct     VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_SITE_USES_EXT_DEL_ACCESS'),'N');

        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN

                IF ( lc_profile_acct = 'Y' ) THEN

                    lc_predicate := '1 = 1';

                ELSE

                    lc_predicate := '1 = 2';

                END IF;

            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN

                Log_Predicate ( p_predicate_function => ' Function : hz_acct_site_use_ext_delete  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );

            END IF;

            RETURN lc_predicate;

        EXCEPTION

            WHEN OTHERS THEN

                Log_Exception ( p_error_location => ' Function : hz_acct_site_use_ext_delete '
                               ,p_error_msg      => SQLERRM );

                RETURN '1 = 2';

        END hz_acct_site_use_ext_delete;
        
        
    -- +=================================================+
    -- | Name        : hz_org_classfn_create             |
    -- | Description : HZ_CODE_ASSIGNMENTS Table         |
    -- |               Predicate Function for Insert     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+
        FUNCTION hz_org_classfn_create ( p_obj_schema  IN VARCHAR2
                                  ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate      VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_CLASSFN_CREATE_ACCESS'),'N');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_ORG_CLASSFN_CREATE_ACCESS') ,'N');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'R' ) THEN
                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || ' WHERE  HCA.party_id   = hz_parties.party_id )';
                ELSIF ( lc_profile_prosp = 'R' AND lc_profile_acct = 'Y' ) THEN
                    lc_predicate := '1 = 1 AND EXISTS ( SELECT 1'
                                                     || ' FROM   hz_cust_accounts HCA'
                                                     || ' WHERE  HCA.party_id   = hz_parties.party_id )';
                ELSIF ( lc_profile_prosp = 'Y' AND lc_profile_acct = 'Y' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_classfn_create  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_classfn_create '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_classfn_create;


    -- +=================================================+
    -- | Name        : hz_org_classfn_update             |
    -- | Description : HZ_CODE_ASSIGNMENTS Table         |
    -- |               Predicate Function for Update     |
    -- | Parameters  : Obj_Schema                        |
    -- |               Obj_Name                          |
    -- +=================================================+

        FUNCTION hz_org_classfn_update ( p_obj_schema  IN VARCHAR2
                                        ,p_obj_name    IN VARCHAR2 )
        RETURN VARCHAR2 IS
            lc_predicate      VARCHAR2(4000) := '1 = 1';
            lc_profile_prosp  VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_PROSP_ORG_CLASSFN_UPDT_ACCESS'),'R');
            lc_profile_acct   VARCHAR2(60)   := NVL(FND_PROFILE.VALUE('XX_CDH_SEC_ACCT_ORG_CLASSFN_UPDT_ACCESS') ,'R');
        BEGIN
            -- Check if running "Import Batch to TCA Registry"
            if (disable_policy) then
                return '';
            end if;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_BYPASS_SEC_RULES'),'Y') = 'N' ) THEN
                IF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'R' ) THEN
                    lc_predicate := '1 = 1 AND NOT EXISTS ( SELECT 1'
                                                       || ' FROM   hz_cust_accounts HCA'
                                                       || ' WHERE  HCA.party_id   = hz_parties.party_id )';
                ELSIF ( lc_profile_prosp = 'R' AND lc_profile_acct = 'U' ) THEN
                    lc_predicate := '1 = 1 AND EXISTS ( SELECT 1'
                                                     || ' FROM   hz_cust_accounts HCA'
                                                     || ' WHERE  HCA.party_id   = hz_parties.party_id )';
                ELSIF ( lc_profile_prosp = 'U' AND lc_profile_acct = 'U' ) THEN
                    lc_predicate := '1 = 1';
                ELSE
                    lc_predicate := '1 = 2';
                END IF;
            END IF;

            IF ( NVL(FND_PROFILE.VALUE('XX_CDH_SEC_LOG_PREDICATE'),'N') = 'Y' ) THEN
                Log_Predicate ( p_predicate_function => ' Function : hz_org_classfn_update  [' || p_obj_schema ||'.'|| p_obj_name ||'] '
                               ,p_predicate          => lc_predicate );
            END IF;
            RETURN lc_predicate;
        EXCEPTION
            WHEN OTHERS THEN
                Log_Exception ( p_error_location => ' Function : hz_org_classfn_update '
                               ,p_error_msg      => SQLERRM );
                RETURN '1 = 2';
        END hz_org_classfn_update;
        
END xx_cdh_role_restrict_pkg;
/

SHOW ERRORS;