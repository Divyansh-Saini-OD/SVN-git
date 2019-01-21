SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY xx_cdh_credit_change_pkg

-- +==========================================================================+
-- |                      Office Depot - Project Simplify                     |
-- |                    Oracle NAIO Consulting Organization                   |
-- +==========================================================================+
-- | Name        : XX_CDH_CREDIT_CHANGE_PKG                                   |
-- | Rice ID     : E0266_RoleRestrictionsMerges                               |
-- | Description : Custom Package called from the Workflow Engine. Contains a |
-- |               procedure Set_Notification that is called to determine the |
-- |               attributes for the Performer and the Message Details.      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version  Date        Author                 Remarks                       |
-- |=======  ==========  ===================    ==============================|
-- |Draft 1a 12-Jul-2007 Prem Kumar             Initial draft version         |
-- |Draft 1b 30-Aug-2007 Vidhya Valantina T                                   |
-- |1.0      31-Aug-2007 Vidhya Valantina T     Baselined after review        |
-- |1.1      13-Nov-2007 Rajeev Kamath          Code review comments added    |
-- |1.2      24-Dec-2015 Vasu Raparla           Removed references to         |
-- |                                             RA_CUSTOMERS                 |
-- +==========================================================================+

AS

-- ---------------------
-- Procedure Definitions
-- ---------------------

    -- +=================================================+
    -- | Name        : Set_Notification                  |
    -- | Description : Procedure to set the attributes   |
    -- |               for performer and message details |
    -- |                                                 |
    -- | Parameters  : itemtype  varchar2                |
    -- |               itemkey   varchar2                |
    -- |               actid     number                  |
    -- |               funcmode  varchar2                |
    -- |               resultout varchar2                |
    -- +=================================================+

        PROCEDURE Set_Notification ( itemtype  IN         VARCHAR2
                                    ,itemkey   IN         VARCHAR2
                                    ,actid     IN         NUMBER
                                    ,funcmode  IN         VARCHAR2
                                    ,resultout OUT NOCOPY VARCHAR2 )
        IS
        -- ---------------------------
        -- Local Variable Declarations
        -- ---------------------------

            lc_customer_name                  hz_parties.party_name%TYPE;
            lc_customer_number                hz_cust_accounts.account_number%TYPE;
            lc_last_update_by                 FND_USER.user_name%TYPE;
            lc_party_number                   hz_parties.party_number%TYPE;
            lc_performer                      FND_USER.user_name%TYPE DEFAULT NULL;
            lc_retcode                        VARCHAR2(4000);

            ld_last_update_date               HZ_CUST_PROFILE_AMTS.last_update_date%TYPE;
            ld_sysdate                        DATE   := SYSDATE;

            ln_cust_acct_prof_amt_id          NUMBER;
            ln_login                          NUMBER := FND_GLOBAL.Login_Id;
            ln_msg_count                      NUMBER;
            ln_ovr_credit_limit               HZ_CUST_PROFILE_AMTS.overall_credit_limit%TYPE;
            ln_trx_credit_limit               HZ_CUST_PROFILE_AMTS.trx_credit_limit%TYPE;
            ln_user_id                        NUMBER := FND_GLOBAL.User_Id;
            ln_resp_id                        NUMBER;
            ln_appl_id                        NUMBER;

            -- -------------------
            -- Cursor Declarations
            -- -------------------

            --
            -- Cursor to fetch performer
            --
            CURSOR  lcu_get_performer ( p_cust_acct_prof_amt_id NUMBER )
            IS
            SELECT  FU.user_name
            FROM    as_accesses_all           AAA
                   ,jtf_rs_role_relations     JRRR
                   ,jtf_rs_resource_extns_vl  JRRE
                   ,jtf_rs_roles_vl           JRRV
                   ,fnd_user                  FU
            WHERE   AAA.salesforce_id       = JRRR.role_resource_id
            AND     JRRR.role_resource_id   = JRRE.resource_id
            AND     JRRR.role_id            = JRRV.role_id
            AND     JRRV.attribute15        = 'BSD'
            AND     JRRE.source_id          = FU.employee_id
            AND     AAA.customer_id      IN ( SELECT  hca.party_id
                                              FROM    hz_cust_profile_amts    HCPA
                                                     ,hz_cust_accounts        HCA
                                              WHERE   HCPA.cust_account_id          = HCA.cust_account_id
                                              AND     HCPA.cust_acct_profile_amt_id = p_cust_acct_prof_amt_id );
            --
            -- Cursor to fetch customer details
            --

            CURSOR  lcu_get_cust_detail ( p_cust_acct_prof_amt_id NUMBER )
            IS
            SELECT  hp.party_name customer_name
                   ,hp.party_number
                   ,hca.account_number customer_number
                   ,HCPA.overall_credit_limit
                   ,HCPA.trx_credit_limit
                   ,FU.user_name
                   ,HCPA.last_update_date
            FROM    hz_cust_profile_amts            HCPA
                   ,hz_cust_accounts                HCA
                   ,hz_parties                      HP
                   ,fnd_user                        FU
            WHERE   HCPA.cust_account_id          = HCA.cust_account_id
            AND     HCA.party_id                  = hp.party_id
            AND     HCPA.last_updated_by          = FU.user_id
            AND     HCPA.cust_acct_profile_amt_id = p_cust_acct_prof_amt_id;

        BEGIN
        
          IF (funcmode = 'RUN') THEN
          
            ----------------------
	    -- Set Apps Context --
	    ----------------------
	    ln_user_id := wf_engine.GetItemAttrNumber(itemtype => itemtype, itemkey => itemkey, aname => 'USER_ID');
	    ln_resp_id := wf_engine.GetItemAttrNumber(itemtype => itemtype, itemkey => itemkey, aname => 'RESPONSIBILITY_ID');
	    ln_appl_id := wf_engine.GetItemAttrNumber(itemtype => itemtype, itemkey => itemkey, aname => 'APPLICATION_ID');
	    fnd_global.apps_initialize(user_id => ln_user_id, resp_id => ln_resp_id, resp_appl_id => ln_appl_id);  

            --
            -- Fetch the Cust Acct Prof Amt ID
            --
            ln_cust_acct_prof_amt_id  := Wf_Engine.GetItemAttrText( itemtype      => itemtype
                                                                   ,itemkey       => itemkey
                                                                   ,aname         => 'CUST_ACCT_PROF_AMT_ID' );

            --
            -- Fetch the performer details
            --
            FOR  get_performer_rec IN lcu_get_performer ( ln_cust_acct_prof_amt_id )
            LOOP
                lc_performer := get_performer_rec.user_name;
                EXIT;
            END LOOP;

            --
            -- Fetch the customer details
            --
            FOR  get_cust_detail_rec IN lcu_get_cust_detail ( ln_cust_acct_prof_amt_id )
            LOOP
                lc_customer_name     :=  get_cust_detail_rec.customer_name;
                lc_customer_number   :=  get_cust_detail_rec.customer_number;
                lc_last_update_by    :=  get_cust_detail_rec.user_name;
                lc_party_number      :=  get_cust_detail_rec.party_number;
                ld_last_update_date  :=  get_cust_detail_rec.last_update_date;
                ln_ovr_credit_limit  :=  get_cust_detail_rec.overall_credit_limit;
                ln_trx_credit_limit  :=  get_cust_detail_rec.trx_credit_limit;
                EXIT;
            END LOOP;

            --
            -- Set the workflow attributes
            --
            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'NOTIFY_TO'
                            ,avalue       => lc_performer );

            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'CUST_NAME'
                            ,avalue       => lc_customer_name );

            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'PARTY_NUMBER'
                            ,avalue       => lc_party_number );

            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'CUST_NUM'
                            ,avalue       => lc_customer_number );

            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'CREDIT_LIMIT'
                            ,avalue       => ln_ovr_credit_limit );

            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'USER_NAME'
                            ,avalue       => lc_last_update_by );

            Wf_Engine.SetItemAttrText
                           ( itemtype     => itemtype
                            ,itemkey      => itemkey
                            ,aname        => 'LAST_UPDATE_DATE'
                            ,avalue       => ld_last_update_date );
            
            resultout := 'COMPLETE';
            RETURN;
            
          ELSIF (funcmode = 'CANCEL') THEN
            resultout := 'COMPLETE';
            RETURN;
            
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
                   ,p_error_location          => 'Procedure : xx_cdh_credit_change_pkg '
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
                   
                wf_core.context('XX_CDH_CREDIT_CHANGE_PKG','SET_NOTIFICATION',itemtype,itemkey,
		                    'Unknown Exception: '||SQLERRM);
		resultout := wf_engine.eng_error;
                APP_EXCEPTION.RAISE_EXCEPTION;
            RETURN;
        END Set_Notification;

END xx_cdh_credit_change_pkg;
/

SHOW ERRORS;
