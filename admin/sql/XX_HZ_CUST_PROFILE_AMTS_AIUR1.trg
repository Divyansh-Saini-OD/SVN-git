SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_HZ_CUST_PROFILE_AMTS_AIUR1                              |
-- | Rice ID     : E0266_RoleRestrictionsMerges                               |
-- | Description : Custom Package called from the Workflow Engine. Contains a |
-- |               procedure Set_Notification that is called to determine the |
-- |               attributes for the Performer and the Message Details.      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 30-Aug-2007 Vidhya Valantina T                                   |
-- |1.0      31-Aug-2007 Vidhya Valantina T     Baselined after review        |
-- |1.1      12-Nov-2007 Rajeev Kamath          Code Review                   |
-- +==========================================================================+

SET TERM ON

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Create Trigger XX_HZ_CUST_PROFILE_AMTS_AIUR1
PROMPT

CREATE OR REPLACE TRIGGER xx_hz_cust_profile_amts_aiur1 AFTER INSERT OR UPDATE ON hz_cust_profile_amts FOR EACH ROW
DECLARE

-- ---------------------------
-- Local Variable Declarations
-- ---------------------------

    lc_item_key_prefix    VARCHAR2(50)    := 'XXCRECHG - ';
    lc_item_key           VARCHAR2(100)   := NULL;
    lc_launch             VARCHAR2(1)     := 'N';
    lc_retcode            VARCHAR2(4000)  := NULL;

    ld_sysdate            DATE            := SYSDATE;

    ln_login              NUMBER          := FND_GLOBAL.Login_Id;
    ln_msg_count          NUMBER          := 0;
    ln_user_id            NUMBER          := FND_GLOBAL.User_Id;

-- -------------------
-- Cursor Declarations
-- -------------------

    --
    -- Cursor to fetch item key
    --

    CURSOR lcu_item_key
    IS
    SELECT xx_cdh_credit_change_itemkey_s.NEXTVAL item_key_seq
    FROM   SYS.dual;

BEGIN

    IF UPDATING THEN

        IF (   NVL(:OLD.overall_credit_limit,-1) <> NVL(:NEW.overall_credit_limit,-1)
            OR NVL(:OLD.trx_credit_limit,-1)     <> NVL(:NEW.trx_credit_limit,-1) ) THEN

            lc_launch := 'Y';

        END IF;


    ELSIF INSERTING THEN

        lc_launch := 'Y';


    END IF;

    IF ( lc_launch = 'Y' ) THEN

        FOR item_key_rec IN lcu_item_key
        LOOP

            lc_item_key := lc_item_key_prefix || item_key_rec.item_key_seq;

        END LOOP;


        Wf_Engine.CreateProcess( itemtype  =>'XXCRECHG'
                                ,itemkey   => lc_item_key
                                ,process   =>'SEND_NOTIFY'
                               );

        Wf_Engine.SetItemAttrText( itemtype     => 'XXCRECHG'
                                  ,itemkey      => lc_item_key
                                  ,aname        => 'CUST_ACCT_PROF_AMT_ID'
                                  ,avalue       => :NEW.cust_acct_profile_amt_id );
                                  
        -- Add attributes to set contexts
        wf_engine.SetItemAttrNumber(itemtype => 'XXCRECHG',
	                            itemkey  => lc_item_key,
	                            aname    => 'USER_ID',
                                    avalue   => FND_GLOBAL.USER_ID);
        wf_engine.SetItemAttrNumber(itemtype => 'XXCRECHG',
	                            itemkey  => lc_item_key,
	                            aname    => 'RESPONSIBILITY_ID',
                                    avalue   => FND_GLOBAL.RESP_ID);
        wf_engine.SetItemAttrNumber(itemtype => 'XXCRECHG',
	                            itemkey  => lc_item_key,
	                            aname    => 'USER_ID',
                                    avalue   => FND_GLOBAL.RESP_APPL_ID);

        Wf_Engine.StartProcess( itemtype => 'XXCRECHG'
                               ,itemkey  => lc_item_key );

    END IF;

EXCEPTION

    WHEN OTHERS THEN

        xx_com_error_log_pub.Log_Error (
            p_return_code             => lc_retcode
           ,p_msg_count               => ln_msg_count
           ,p_application_name        => 'EBS'
           ,p_program_type            => 'Extension'
           ,p_program_name            => 'E0266_RoleRestrictionsMerges'
           ,p_module_name             => 'CDH'
           ,p_error_location          => ' Trigger : xx_hz_cust_profile_amts_aiur1 '
           ,p_error_message_count     => 1
           ,p_error_message_code      => 'E'
           ,p_error_message           => SQLERRM
           ,p_error_message_severity  => NULL
           ,p_error_status            => 'EXCEPTION'
           ,p_notify_flag             => 'N'
           ,p_object_type             => 'User'
           ,p_object_id               => ln_user_id
           ,p_creation_date           => ld_sysdate
           ,p_created_by              => ln_user_id
           ,p_last_update_date        => ld_sysdate
           ,p_last_updated_by         => ln_user_id
           ,p_last_update_login       => ln_login );

END xx_hz_cust_profile_amts_aiur1;
/

SHOW ERRORS;

WHENEVER SQLERROR EXIT 1;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;