SET VERIFY        OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE
PACKAGE BODY XX_CS_SR_WF_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :  XX_CS_SR_WF_PKG                                          |
-- |                                                                   |
-- | Description: Added group owner to notification                    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0       24-Apr-07   Raj Jagarlamudi  Initial draft version       |
-- |                                                                   |
-- +===================================================================+


PROCEDURE Check_Owner ( itemtype      VARCHAR2,
                        itemkey       VARCHAR2,
                        actid         NUMBER,
                        funmode       VARCHAR2,
                        result    OUT NOCOPY VARCHAR2 )
IS

  l_owner        Varchar2(100);
  
BEGIN

  IF (funmode = 'RUN') THEN

    l_owner := WF_ENGINE.GetItemAttrText( itemtype => itemtype,itemkey => itemkey,aname => 'DOC_OWNER');
   
    IF l_owner is null then
      result := 'COMPLETE:N';
    ELSE
      result := 'COMPLETE:Y';
    END IF;
    
   ELSIF (funmode = 'CANCEL') THEN
       result := 'COMPLETE';
   END IF;
    EXCEPTION
    WHEN OTHERS THEN
    WF_CORE.Context('XX_CS_SR_WF_PKG', 'Check Owner',itemtype, itemkey, actid, funmode);
    RAISE;
END;
/******************************************************************************
*******************************************************************************/

PROCEDURE Set_Notif_Performer( itemtype      VARCHAR2,
                               	   itemkey       VARCHAR2,
                                   actid         NUMBER,
                                   funmode       VARCHAR2,
                                   result    OUT NOCOPY VARCHAR2 ) AS

  l_group_id        NUMBER;
  l_sr_number       varchar2(900);
  l_msg_recipient   VARCHAR2(100);

BEGIN
  IF (funmode = 'RUN') THEN

    l_sr_number := WF_ENGINE.GetItemAttrText( itemtype => itemtype,itemkey => itemkey,aname => 'DOC_NUMBER');

    BEGIN
      select owner_group_id
      into l_group_id
      from cs_incidents_all_b
      where incident_number = l_sr_number;
    exception
      when others then
          l_group_id := null;
    end;
    
    IF L_GROUP_ID IS NOT NULL THEN
      BEGIN
           SELECT  U.USER_NAME
           INTO    L_MSG_RECIPIENT
           FROM    JTF_RS_GROUP_MEMBERS_VL V1,
                   JTF_RS_DEFRESROLES_VL V2,
                   FND_USER U
            WHERE  U.EMPLOYEE_ID = V1.PERSON_ID
             AND   V2.ROLE_RESOURCE_ID = V1.RESOURCE_ID
             AND   V2.MANAGER_FLAG = 'Y'
             AND   V1.GROUP_ID = L_GROUP_ID
             AND  ROWNUM < 2;
         EXCEPTION
             WHEN OTHERS THEN
              L_MSG_RECIPIENT := NULL;
      END;
    END IF;
    
   IF L_MSG_RECIPIENT is not null then

    WF_ENGINE.SetItemAttrNumber(itemtype => itemtype,
                                itemkey => itemkey,
                                aname => 'LIST_COUNTER',
                                avalue => 0 );

    WF_ENGINE.SetItemAttrNumber(itemtype => itemtype,
                                itemkey => itemkey,
                                aname => 'PERFORMER_LIMIT',
                                avalue => 0 );
                               
    WF_ENGINE.SetItemAttrText(itemtype => itemtype,
                                itemkey => itemkey,
                                aname => 'MESSAGE_RECIPIENT',
                                avalue => L_MSG_RECIPIENT );
                                
                      
    end if;
    
    result := 'COMPLETE';

  ELSIF (funmode = 'CANCEL') THEN
  result := 'COMPLETE';
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
    WF_CORE.Context('XX_CS_SR_WF_PKG', 'Set_Notif_Performer',itemtype, itemkey, actid, funmode);
    RAISE;
END Set_Notif_Performer;

END XX_CS_SR_WF_PKG;
/
SHOW ERRORS;
EXIT;