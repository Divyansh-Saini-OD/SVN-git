CREATE OR REPLACE PACKAGE BODY APPS.XX_WFL_POAPPRV_REQAPPROVAL
AS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name : XX_WFL_POAPPRV_REQAPPROVAL                                  |
-- | Description : This Package is used to  capture the employee name   |
-- | from the buyer approval category form when the buyer is unable to  |
-- | approve a PO and is not set as an Internal procurement Buyer       |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   =============        ========================|
-- |1A        02-APR-2007  Pradeep Ramasamy,    Initial version         |
-- |                       Wipro Technologies                           |
-- |1B        14-JUN-2007  Pradeep Ramasamy,    Updated to add custom   |
-- |                       Wipro Technologies   error exception package |
-- |                                            XX_COM_ERROR_LOG_PUB    |
-- |                                            .LOG_ERROR              |
-- |1.0       11-SEP-2007  Radhika Raman        Modified for            |
-- |                                            Defect - 1842           |
-- |1.1       24-SEP-2007  Agnes Poornima M     Modified to fix         |
-- |                                            Defect  # 2014          |
-- |1.2       11-JUL-2013  Srinivas Sivalanka   Modified fro R12 upgrade|
-- |                       (Oracle)             Retrofit                |
-- +====================================================================+
-- +====================================================================+
-- | Name : GET_PO_APPROVER_NAME                                        |
-- | Description : This Procedure will be created to capture the        |
-- | employee name from the buyer approval category form when the buyer |
-- | is unable to approve a PO and DFF on the buyer table record for the|
-- | employees is set to 'NO'                                           |
-- | Parameters :  p_itemtype,p_itemkey,p_act_id,p_funcmode,p_resultout |
-- |                                                                    |
-- | Returns    :  p_resultout                                          |
-- +====================================================================+
PROCEDURE GET_PO_APPROVER_NAME (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
)
IS
   ln_empid                NUMBER;
   lc_buyer_flag           po_agents_v.attribute1%TYPE;
   ln_org_id               NUMBER;
   ln_approver_id          xx_icx_org_atts.approver_id%TYPE;
   lc_preparer_user_name   VARCHAR2(100);
   lc_agent_name           per_people_f.full_name%TYPE;
   lc_loc_err_msg          VARCHAR2(2000);
   lc_error_loc            VARCHAR2(1000);
   lc_operating_unit       VARCHAR2(100);
   ln_notification_id      NUMBER;
   ln_po_routing_check     NUMBER;
   lc_app_user_name        wf_users.name%TYPE;
BEGIN
   lc_error_loc := 'Fetch Attribute Values';
   ln_empid := WF_ENGINE.GETITEMATTRNUMBER ( itemtype => p_itemtype,
                                             itemkey  => p_itemkey,
                                             aname    => 'BUYER_USER_ID');
   ln_org_id := WF_ENGINE.GETITEMATTRNUMBER ( itemtype   => p_itemtype,
                                              itemkey    => p_itemkey,
                                              aname      => 'ORG_ID');
   lc_operating_unit  := WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype,
                                                    itemkey  => p_itemkey,
                                                    aname    => 'OPERATING_UNIT_NAME');
   lc_error_loc := 'Fetch the Buyer Type ln_empid'||ln_empid;
   SELECT NVL(attribute1,'N')   --Modified for R12 upgrade retrofit (sivalanka)
   INTO lc_buyer_flag
   FROM po_agents_v
   WHERE agent_id=(SELECT employee_id FROM fnd_user WHERE user_id=ln_empid);  --Modified for R12 upgrade retrofit (sivalanka)
        --Buyer is a Internal procurement Buyer
   IF lc_buyer_flag = 'Y' THEN
      p_resultout:='COMPLETE:'||'Y';
   ELSE
      --Buyer is a Non-Internal procurement Buyer
      --Get the Approver Name from custom table
     ln_po_routing_check  := WF_ENGINE.GETITEMATTRNUMBER( itemtype => p_itemtype,
                                                    itemkey  => p_itemkey,
                                                    aname    => 'PO_ROUTING_CHECK');
        BEGIN
          lc_error_loc := 'Fetch the OU Approver';
          SELECT approver_id
          INTO ln_approver_id
          FROM xx_icx_org_atts
          WHERE org_id=ln_org_id;
          lc_error_loc := 'Fetch the Forward TO Full Name';
          SELECT name, display_name
          INTO lc_app_user_name, lc_agent_name
          FROM wf_users
          WHERE orig_system = 'PER'
          AND orig_system_id = ln_approver_id
          AND TRUNC(SYSDATE) BETWEEN TRUNC(start_date) AND TRUNC(NVL(expiration_date,SYSDATE+2))
          AND status = 'ACTIVE';
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME( application =>'XXFIN',name   =>'XX_PO_0064_ROUTING_NO_DATA');
            FND_MESSAGE.SET_TOKEN(token => 'ORG_ID',value => lc_operating_unit );
           lc_loc_err_msg :=  FND_MESSAGE.GET;
           XX_COM_ERROR_LOG_PUB.LOG_ERROR ( p_program_type            => 'WORKFLOW PROGRAM'
                                           ,p_program_name            => 'XX_WFL_POAPPRV_REQAPPROVAL'
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'PO'
                                           ,p_error_location          => lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_loc_err_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'PO Routing' );
          lc_preparer_user_name  := WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype,
                                                                itemkey  => p_itemkey,
                                                                aname    => 'BUYER_USER_NAME');
          WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'OU_APPROVER_NOT_FOUND'
                                   ,avalue   => lc_loc_err_msg  );
          ln_notification_id := WF_NOTIFICATION.SEND(role     => lc_preparer_user_name
                                                    ,msg_type => 'POAPPRV'
                                                    ,msg_name => 'OU_APPROVER_NOT_FOUND'
                                                    ,due_date => SYSDATE
                                                    ,callback => 'WF_ENGINE.CB'
                                                    ,context  => p_itemtype||':'||p_itemkey||':'||p_actid);
        END;
     IF ln_po_routing_check = 0 THEN
       WF_ENGINE.SetItemAttrText ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'FORWARD_TO_USERNAME'
                                   ,avalue   => lc_app_user_name
         );
         WF_ENGINE.SETITEMATTRNUMBER ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'PO_ROUTING_CHECK'
                                   ,avalue   => 1
         );
         -- The attributes have been set to ensure that the PO_ACTION_HISTORY gets updated. Added to fix Defect #2014
	WF_ENGINE.SetItemAttrText ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'FORWARD_FROM_ID'
                                   ,avalue   => ln_empid
         );
	WF_ENGINE.SetItemAttrText ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'FORWARD_TO_ID'
                                   ,avalue   => ln_approver_id
         );
        p_resultout:='COMPLETE:'||'N';
      ELSE
        -- Attributes set to fix the defect #1842
        IF ln_po_routing_check = 1 THEN
           Wf_Engine.SetItemAttrNumber (itemtype => p_itemtype
                                    ,itemkey  => p_itemkey
                                    ,aname    => 'APPROVER_EMPID'
                                    ,avalue   => ln_approver_id);
           WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'APPROVER_USER_NAME'
                                   ,avalue   => lc_app_user_name
             );
          WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'APPROVER_DISPLAY_NAME'
                                   ,avalue   => lc_agent_name
            );
          WF_ENGINE.SETITEMATTRNUMBER ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'PO_ROUTING_CHECK'
                                   ,avalue   => 2
             );
        END IF;
        p_resultout:='COMPLETE:'||'Y';
      END IF;
   END IF;
EXCEPTION
WHEN OTHERS THEN
      FND_MESSAGE.SET_NAME(application =>'XXFIN',name =>'XX_PO_0065_ROUTING_OTHERS');
      FND_MESSAGE.SET_TOKEN(token => 'ERR_LOC',value => lc_error_loc);
      FND_MESSAGE.SET_TOKEN(token =>'ERR_ORA',value =>SQLERRM);
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                       p_program_type            => 'WORKFLOW PROGRAM'
                                      ,p_program_name            => 'XX_WFL_POAPPRV_REQAPPROVAL'
                                      ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                      ,p_module_name             => 'PO'
                                      ,p_error_location          => 'Oracle Error '||SQLERRM
                                      ,p_error_message_count     => 1
                                      ,p_error_message_code      => 'E'
                                      ,p_error_message           => lc_loc_err_msg
                                      ,p_error_message_severity  => 'Major'
                                      ,p_notify_flag             => 'N'
                                      ,p_object_type             => 'PO Routing'
      );
      lc_preparer_user_name  := WF_ENGINE.GETITEMATTRTEXT ( itemtype => p_itemtype,
                                                            itemkey  => p_itemkey,
                                                            aname    => 'BUYER_USER_NAME');
      WF_ENGINE.SETITEMATTRTEXT ( itemtype => p_itemtype
                                   ,itemkey  => p_itemkey
                                   ,aname    => 'EXCEPTION_OTHERS'
                                   ,avalue   => lc_loc_err_msg  );
      ln_notification_id := WF_NOTIFICATION.SEND(role      => lc_preparer_user_name
                                                 ,msg_type => 'POAPPRV'
                                                 ,msg_name => 'EXCEPTION_OTHERS'
                                                 ,due_date => SYSDATE
                                                 ,callback => 'WF_ENGINE.CB'
                                                 ,context  => p_itemtype||':'||p_itemkey||':'||p_actid);
END GET_PO_APPROVER_NAME;
END XX_WFL_POAPPRV_REQAPPROVAL;
/
