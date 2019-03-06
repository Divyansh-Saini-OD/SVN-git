CREATE OR REPLACE
PACKAGE BODY      xx_cs_task_wf_util AS
  /* $Header: jtftkwub.pls 115.22 2007/08/01 09:55:05 venjayar ship $ */

  /****************************************************************************
  *
  * Program Name : xx_cs_task_wf_util
  * Language     : PL/SQL
  * Description  : Package to support custom TASK WORKFLOW for Service Requests.
  * History      :
  *
  * WHO             WHAT                                    WHEN
  * --------------  --------------------------------------- ---------------
  * Mohsin Ansari   Created                                 3/31/08
  * Raj Jagarlamudi Added Adoch roles                       5/22/08
  * Raj Jagarlamudi Update the SR status                    6/12/08
  ****************************************************************************/



  FUNCTION get_resource_name(p_resource_type IN VARCHAR2, p_resource_id IN NUMBER)
    RETURN VARCHAR2 IS
    TYPE cur_typ IS REF CURSOR;

    c               cur_typ;
    l_sql_statement VARCHAR2(500)                         := NULL;
    l_resource_name jtf_tasks_b.source_object_name%TYPE   := NULL;
    l_where_clause  jtf_objects_b.where_clause%TYPE       := NULL;

    -------------------------------------------------------------------------
    -- Create a SQL statement for getting the resource name
    -------------------------------------------------------------------------
    CURSOR c_get_res_name(b_resource_type jtf_tasks_b.owner_type_code%TYPE) IS
      SELECT where_clause
           , 'SELECT ' || select_name || ' FROM ' || from_table || ' WHERE ' || select_id || ' = :RES'
        FROM jtf_objects_vl
       WHERE object_code = b_resource_type;
  BEGIN
    OPEN c_get_res_name(p_resource_type);
    FETCH c_get_res_name INTO l_where_clause, l_sql_statement;
    IF c_get_res_name%NOTFOUND THEN
      CLOSE c_get_res_name;
      RETURN NULL;
    END IF;
    CLOSE c_get_res_name;

    -- assign the value again so it is null-terminated, to avoid ORA-600 [12261]
    l_sql_statement  := l_sql_statement;

    IF l_sql_statement IS NOT NULL THEN
      IF l_where_clause IS NOT NULL THEN
        l_sql_statement  := l_sql_statement || ' AND ' || l_where_clause;
      END IF;

      OPEN c FOR l_sql_statement USING p_resource_id;
      FETCH c INTO l_resource_name;
      CLOSE c;

      RETURN l_resource_name;
    ELSE
      RETURN NULL;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_resource_name;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE include_role(p_role_name IN VARCHAR2) IS
    l_index        NUMBER               := xx_cs_task_wf_util.notiflist.COUNT;
    l_search_index NUMBER;
    l_role_name    wf_roles.NAME%TYPE;
  BEGIN
    -- check to see if the role is already in the list
    l_role_name  := p_role_name;

    IF l_index > 0 THEN
      FOR l_search_index IN xx_cs_task_wf_util.notiflist.FIRST .. xx_cs_task_wf_util.notiflist.LAST LOOP
        IF l_role_name = xx_cs_task_wf_util.notiflist(l_search_index).NAME THEN
          l_role_name  := NULL;
          EXIT;
        END IF;
      END LOOP;
    END IF;

    IF l_role_name IS NOT NULL THEN
      -- add the role to the list
      xx_cs_task_wf_util.notiflist(l_index + 1).NAME  := l_role_name;
      --
      -- add the role type to the list
      xx_cs_task_wf_util.notiflist(l_index + 1).ROLE_TYPE := g_role_type;
    END IF;
  END include_role;
/******************************************************************************************************
********************************************************************************************************/
  PROCEDURE get_party_details(p_resource_id IN NUMBER, p_resource_type_code IN VARCHAR2, x_role_name OUT NOCOPY VARCHAR2) IS
    CURSOR c_resource_party(b_resource_id jtf_tasks_b.owner_id%TYPE) IS
      SELECT source_id
        FROM jtf_rs_resource_extns
       WHERE resource_id = b_resource_id;

    l_party_id     hz_parties.party_id%TYPE;
    l_display_name VARCHAR2(100);   -- check this declaration
  BEGIN
    x_role_name  := NULL;

    IF p_resource_type_code IN('RS_SUPPLIER_CONTACT', 'RS_PARTNER', 'RS_PARTY') THEN
      -- supplier or party resource
      OPEN c_resource_party(p_resource_id);
      FETCH c_resource_party INTO l_party_id;
      IF c_resource_party%NOTFOUND THEN
        CLOSE c_resource_party;
        RETURN;
      END IF;
      CLOSE c_resource_party;
    ELSE
      -- party
      l_party_id  := p_resource_id;
    END IF;

    wf_directory.getusername('HZ_PARTY', l_party_id, x_role_name, l_display_name);
  END get_party_details;
/*****************************************************************************************
******************************************************************************************/

  PROCEDURE find_role(p_resource_id IN NUMBER, p_resource_type_code IN VARCHAR2) IS
    CURSOR c_group_members(b_group_id jtf_rs_group_members.GROUP_ID%TYPE) IS
      SELECT resource_id
           , 'RS_' || CATEGORY resource_type_code
        FROM jtf_rs_resource_extns
       WHERE resource_id IN(SELECT resource_id
                              FROM jtf_rs_group_members
                             WHERE GROUP_ID = b_group_id AND NVL(delete_flag, 'N') = 'N');

    CURSOR c_team_members(b_team_id jtf_rs_team_members.team_id%TYPE) IS
      SELECT resource_id
           , 'RS_' || CATEGORY resource_type_code
        FROM jtf_rs_resource_extns
       WHERE resource_id IN(SELECT team_resource_id
                              FROM jtf_rs_team_members
                             WHERE team_id = b_team_id AND NVL(delete_flag, 'N') = 'N');

    l_group_rec c_group_members%ROWTYPE;
    l_team_rec  c_team_members%ROWTYPE;
    l_role_name wf_roles.NAME%TYPE;
    l_members   VARCHAR2(80)              := fnd_profile.VALUE('JTF_TASK_NOTIFY_MEMBERS');
  BEGIN
    l_role_name  := NULL;

    IF p_resource_type_code = 'RS_EMPLOYEE' THEN
      -- employee resource
      l_role_name  := jtf_rs_resource_pub.get_wf_role(p_resource_id);

      IF l_role_name IS NOT NULL THEN
        include_role(p_role_name => l_role_name);
      ELSE
        fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
        fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
        fnd_msg_pub.ADD;
      END IF;
    ELSIF p_resource_type_code IN('RS_GROUP', 'RS_TEAM') THEN
      -- group or team resource
      IF l_members = 'Y' THEN
        -- expand into individual members
        IF p_resource_type_code = 'RS_GROUP' THEN
          FOR l_group_rec IN c_group_members(p_resource_id) LOOP
            IF l_group_rec.resource_type_code = 'RS_EMPLOYEE' THEN
              -- employee resource
              l_role_name  := jtf_rs_resource_pub.get_wf_role(l_group_rec.resource_id);

              IF l_role_name IS NOT NULL THEN
                include_role(p_role_name => l_role_name);
              ELSE
                fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
                fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
                fnd_msg_pub.ADD;
              END IF;
            ELSIF l_group_rec.resource_type_code IN('RS_SUPPLIER_CONTACT', 'RS_PARTNER', 'RS_PARTY', 'PARTY_PERSON') THEN
              get_party_details(
                p_resource_id                => l_group_rec.resource_id
              , p_resource_type_code         => l_group_rec.resource_type_code
              , x_role_name                  => l_role_name
              );

              IF l_role_name IS NOT NULL THEN
                include_role(p_role_name => l_role_name);
              ELSE
                fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
                fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
                fnd_msg_pub.ADD;
              END IF;
            ELSE
              fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
              fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
              fnd_msg_pub.ADD;
            END IF;
          END LOOP;
        ELSIF p_resource_type_code = 'RS_TEAM' THEN
          FOR l_team_rec IN c_team_members(p_resource_id) LOOP
            IF l_team_rec.resource_type_code = 'RS_EMPLOYEE' THEN
              -- employee resource
              l_role_name  := jtf_rs_resource_pub.get_wf_role(l_team_rec.resource_id);

              IF l_role_name IS NOT NULL THEN
                include_role(p_role_name => l_role_name);
              ELSE
                fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
                fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
                fnd_msg_pub.ADD;
              END IF;
            ELSIF l_team_rec.resource_type_code IN('RS_SUPPLIER_CONTACT', 'RS_PARTNER', 'RS_PARTY', 'PARTY_PERSON') THEN
              get_party_details(
                p_resource_id                => l_team_rec.resource_id
              , p_resource_type_code         => l_team_rec.resource_type_code
              , x_role_name                  => l_role_name
              );

              IF l_role_name IS NOT NULL THEN
                include_role(p_role_name => l_role_name);
              ELSE
                fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
                fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
                fnd_msg_pub.ADD;
              END IF;
            ELSE
              fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
              fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
              fnd_msg_pub.ADD;
            END IF;
          END LOOP;
        ELSE
          fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
          fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
          fnd_msg_pub.ADD;
        END IF;
      ELSE
        fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
        fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
        fnd_msg_pub.ADD;
      END IF;
    ELSIF p_resource_type_code IN('RS_SUPPLIER_CONTACT', 'RS_PARTNER', 'RS_PARTY', 'PARTY_PERSON') THEN
      get_party_details(p_resource_id => p_resource_id, p_resource_type_code => p_resource_type_code
      , x_role_name                  => l_role_name);

      IF l_role_name IS NOT NULL THEN
        include_role(p_role_name => l_role_name);
      ELSE
        fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
        fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
        fnd_msg_pub.ADD;
      END IF;
    ELSE
      fnd_message.set_name('JTF', 'JTF_RS_ROLE_NOTFOUND');
      fnd_message.set_token('P_RESOURCE_NAME', get_resource_name(p_resource_type_code, p_resource_id));
      fnd_msg_pub.ADD;
    END IF;
  END find_role;
/******************************************************************************************************
******************************************************************************************************/

  PROCEDURE set_text_attr(
    p_itemtype   IN VARCHAR2
  , p_itemkey    IN VARCHAR2
  , p_attr_name  IN VARCHAR2
  , p_attr_value IN VARCHAR2
  ) IS
    e_wf_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_wf_error, -20002);
  BEGIN
    ---
    --- Using this procedure to ignore Workflow error 3103 when an
    --- attribute does not exist
    ---
    wf_engine.setitemattrtext(
      itemtype => p_itemtype
    , itemkey  => p_itemkey
    , aname    => p_attr_name
    , avalue   => p_attr_value
    );
  EXCEPTION
    WHEN e_wf_error THEN
      IF SUBSTR(SQLERRM, 12, 4) = '3103' THEN
        NULL;
      ELSE
        RAISE;
      END IF;
  END set_text_attr;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE set_num_attr(p_itemtype IN VARCHAR2, p_itemkey IN VARCHAR2, p_attr_name IN VARCHAR2, p_attr_value IN NUMBER) IS
    e_wf_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_wf_error, -20002);
  BEGIN
    ---
    --- Using this procedure to ignore Workflow error 3103 when an
    --- attribute does not exist
    ---
    wf_engine.setitemattrnumber(
      itemtype => p_itemtype
    , itemkey  => p_itemkey
    , aname    => p_attr_name
    , avalue   => p_attr_value
    );
  EXCEPTION
    WHEN e_wf_error THEN
      IF SUBSTR(SQLERRM, 12, 4) = '3103' THEN
        NULL;
      ELSE
        RAISE;
      END IF;
  END set_num_attr;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE list_notify_roles(
    p_event             IN VARCHAR2
  , p_task_id           IN VARCHAR2
  , p_old_owner_id      IN NUMBER DEFAULT jtf_task_utl.g_miss_number
  , p_old_owner_code    IN VARCHAR2 DEFAULT jtf_task_utl.g_miss_char
  , p_new_owner_id      IN NUMBER
  , p_new_owner_code    IN VARCHAR2
  , p_old_assignee_id   IN NUMBER DEFAULT jtf_task_utl.g_miss_number
  , p_old_assignee_code IN VARCHAR2 DEFAULT jtf_task_utl.g_miss_char
  , p_new_assignee_id   IN NUMBER DEFAULT jtf_task_utl.g_miss_number
  , p_new_assignee_code IN VARCHAR2 DEFAULT jtf_task_utl.g_miss_char
  ) IS
    CURSOR c_assignees(b_task_id jtf_tasks_b.task_id%TYPE) IS
      SELECT resource_id
           , resource_type_code
        FROM jtf_task_all_assignments
       WHERE task_id = b_task_id AND assignee_role = 'ASSIGNEE';

    l_assignees c_assignees%ROWTYPE;
  BEGIN
    -- Always notify the current owner
    g_role_type := 'O' ;
    find_role(p_resource_id => p_new_owner_id, p_resource_type_code => p_new_owner_code);

    -- For DELETE_TASK, CHANGE_TASK_DETAILS and NO_UPDATE events, notify all assignees
    -- For CREATE_TASK, Assignees are not notified (Refer Bug# 4251583)
    IF p_event IN('DELETE_TASK', 'CHANGE_TASK_DETAILS', 'NO_UPDATE') THEN
      g_role_type := 'A' ;
      FOR l_assignees IN c_assignees(p_task_id) LOOP
        find_role(p_resource_id => l_assignees.resource_id, p_resource_type_code => l_assignees.resource_type_code);
      END LOOP;
    END IF;

    -- For CHANGE_OWNER notify the old owner
    IF p_event = 'CHANGE_OWNER' THEN
      g_role_type := 'O' ;
      find_role(p_resource_id => p_old_owner_id, p_resource_type_code => p_old_owner_code);
    END IF;

    -- For ADD_ASSIGNEE and CHANGE_ASSIGNEE notify the new assignee
    IF p_event IN('ADD_ASSIGNEE', 'CHANGE_ASSIGNEE') THEN
      g_role_type := 'A' ;
      find_role(p_resource_id => p_new_assignee_id, p_resource_type_code => p_new_assignee_code);
    END IF;

    -- For CHANGE_ASSIGNEE and DELETE_ASSIGNEE notify the old assignee
    IF p_event IN('CHANGE_ASSIGNEE', 'DELETE_ASSIGNEE') THEN
      g_role_type := 'A' ;
      find_role(p_resource_id => p_old_assignee_id, p_resource_type_code => p_old_assignee_code);
    END IF;
  END list_notify_roles;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE set_notif_performer(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  ) IS
    l_counter BINARY_INTEGER;
    l_role    wf_roles.NAME%TYPE;
    l_role_type xx_cs_task_wf_util.g_role_type%TYPE ;
    ln_task_number  number;
    lc_group_owner  varchar2(250);
    lc_cust_name    varchar2(200);
    lc_cust_info    varchar2(200);
    lc_from_value   varchar2(200);
  BEGIN
    IF funcmode = 'RUN' THEN
      l_counter  := wf_engine.getitemattrnumber(itemtype => itemtype, itemkey => itemkey, aname => 'LIST_COUNTER');
      l_role     := xx_cs_task_wf_util.notiflist(l_counter).NAME;
      -- Capture the current role type from the notification list into a item attribute
      l_role_type := xx_cs_task_wf_util.notiflist(l_counter).ROLE_TYPE;

      IF l_role IS NOT NULL THEN
        set_text_attr(
          p_itemtype   => itemtype
        , p_itemkey    => itemkey
        , p_attr_name  => 'MESSAGE_RECIPIENT'
        , p_attr_value => l_role);

      END IF;

      IF l_role_type IS NOT NULL THEN
        set_text_attr(
          p_itemtype   => itemtype
        , p_itemkey    => itemkey
        , p_attr_name  => 'XX_CS_RECEIPIENT_TYPE'
        , p_attr_value => l_role_type);
      END IF;

      l_counter  := l_counter + 1;
      set_num_attr(
        p_itemtype   => itemtype
      , p_itemkey    => itemkey
      , p_attr_name  => 'LIST_COUNTER'
      , p_attr_value => l_counter
      );

      -- Set Customer Details
      ln_task_number      := WF_ENGINE.GetItemAttrText( itemtype => itemtype,itemkey => itemkey,aname => 'TASK_NUMBER');
      BEGIN
         SELECT HZ.PARTY_NAME,
                CS.CUSTOMER_PHONE_ID,
                GL.GROUP_NAME
          INTO  LC_CUST_NAME,
                LC_CUST_INFO,
                LC_GROUP_OWNER
          FROM  JTF_TASKS_VL TL,
                CS_INCIDENTS CS,
                HZ_PARTIES HZ,
                JTF_RS_GROUPS_VL GL
          WHERE GL.GROUP_ID = CS.OWNER_GROUP_ID
           AND   HZ.PARTY_ID = TL.CUSTOMER_ID
           AND   TL.SOURCE_OBJECT_ID = CS.INCIDENT_ID
           AND   TO_NUMBER(TL.TASK_NUMBER) = LN_TASK_NUMBER;
      EXCEPTION
         WHEN OTHERS THEN
           LC_CUST_NAME := NULL;
           LC_CUST_INFO := NULL;
           LC_GROUP_OWNER := NULL;
      END;

      IF LC_CUST_NAME IS NOT NULL THEN
          set_text_attr(
               p_itemtype   => itemtype
               , p_itemkey    => itemkey
               , p_attr_name  => 'CUSTOMER_NAME'
               , p_attr_value => lc_cust_name
           );
        END IF;

       IF LC_CUST_INFO IS NOT NULL THEN
          set_text_attr(
               p_itemtype   => itemtype
               , p_itemkey    => itemkey
               , p_attr_name  => 'XX_CS_CONTACT_NAME'
               , p_attr_value => lc_cust_info
           );
        END IF;
       -- end of customer details
       -- Add assign from attribute
       IF LC_GROUP_OWNER LIKE 'ECR%' THEN
          lc_from_value := 'Executive Customer Relations';
       ELSIF LC_GROUP_OWNER LIKE 'EC %' THEN
          lc_from_value := 'eCommerce Customer Support';
       ELSIF LC_GROUP_OWNER LIKE '%Warehouse%' THEN
          lc_from_value := 'OD Delivery Center';
       ELSIF LC_GROUP_OWNER IN ('PHOENIX', 'HCL') THEN
          lc_from_value := 'OD Delivery Center';
       ELSIF LC_GROUP_OWNER LIKE 'DPS%' THEN
          lc_from_value := 'OD DPS Support';
       ELSIF LC_GROUP_OWNER LIKE 'Stock%' THEN
          lc_from_value := 'OD Norcross Customer Relations';
       ELSE
          lc_from_value := 'OD Customer Service';
       END IF;

       IF lc_from_value IS NOT NULL THEN
          set_text_attr(
               p_itemtype   => itemtype
               , p_itemkey    => itemkey
               , p_attr_name  => 'XX_CS_SR_OWNER'
               , p_attr_value => lc_from_value
           );
        END IF;

      resultout  := 'COMPLETE';
      RETURN;
    END IF;

    IF funcmode = 'CANCEL' THEN
      resultout  := 'COMPLETE';
      RETURN;
    END IF;

    IF funcmode = 'TIMEOUT' THEN
      resultout  := 'COMPLETE';
      RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT(g_pkg_name, 'Set_Notif_Performer', itemtype, itemkey, TO_CHAR(actid), funcmode);
      RAISE;
  END set_notif_performer;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE set_notif_list(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  ) IS
    l_counter BINARY_INTEGER;
  BEGIN
    IF funcmode = 'RUN' THEN
      -------------------------------------------------------------------------
      -- Set the Notification List
      -------------------------------------------------------------------------
      list_notify_roles(
        p_event                      => jtf_task_wf_util.g_event
      , p_task_id                    => jtf_task_wf_util.g_task_id
      , p_old_owner_id               => jtf_task_wf_util.g_old_owner_id
      , p_old_owner_code             => jtf_task_wf_util.g_old_owner_code
      , p_new_owner_id               => jtf_task_wf_util.g_owner_id
      , p_new_owner_code             => jtf_task_wf_util.g_owner_type_code
      , p_old_assignee_id            => jtf_task_wf_util.g_old_assignee_id
      , p_old_assignee_code          => jtf_task_wf_util.g_old_assignee_code
      , p_new_assignee_id            => jtf_task_wf_util.g_new_assignee_id
      , p_new_assignee_code          => jtf_task_wf_util.g_new_assignee_code
      );

      IF xx_cs_task_wf_util.notiflist.COUNT > 0 THEN
        -------------------------------------------------------------------------
        -- Set the process counters
        -------------------------------------------------------------------------
        l_counter  := xx_cs_task_wf_util.notiflist.COUNT;
        set_num_attr(
          p_itemtype => itemtype
        , p_itemkey => itemkey
        , p_attr_name => 'LIST_COUNTER'
        , p_attr_value => 1
        );
        set_num_attr(
          p_itemtype   => itemtype
        , p_itemkey    => itemkey
        , p_attr_name  => 'PERFORMER_LIMIT'
        , p_attr_value => l_counter
        );
        resultout  := 'COMPLETE:T';
      ELSE
        resultout  := 'COMPLETE:F';
      END IF;

      RETURN;
    END IF;

    IF funcmode = 'CANCEL' THEN
      resultout  := 'COMPLETE:F';
      RETURN;
    END IF;

    IF funcmode = 'TIMEOUT' THEN
      resultout  := 'COMPLETE:F';
      RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT(g_pkg_name, 'Set_Notif_List', itemtype, itemkey, TO_CHAR(actid), funcmode);
      RAISE;
  END set_notif_list;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE select_task_event(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  ) IS
    l_event VARCHAR2(200);
  BEGIN
    IF funcmode = 'RUN' THEN
      l_event    := wf_engine.getitemattrtext(itemtype => itemtype, itemkey => itemkey, aname => 'TASK_EVENT');
      --
				resultout  := 'XX_CS_'||l_event;
				RETURN;
		ELSE
				resultout  := 'XX_CS_NO_UPDATE';
				RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT(g_pkg_name, 'Select_Task_Event', itemtype, itemkey, TO_CHAR(actid), funcmode);
      RAISE;
  END select_task_event;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE check_role_type(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  ) IS
    l_role_type xx_cs_task_wf_util.g_role_type%TYPE ;
  BEGIN
    IF funcmode = 'RUN' THEN
      l_role_type     := wf_engine.getitemattrtext(itemtype => itemtype, itemkey => itemkey, aname => 'XX_CS_RECEIPIENT_TYPE');
      --
      IF l_role_type IN ('O','A') THEN
				resultout  := 'COMPLETE:'||l_role_type;
				RETURN;
		  ELSE
				resultout  := 'COMPLETE:U';
				RETURN;
		  END IF ;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT(g_pkg_name, 'Check_Role_Type', itemtype, itemkey, TO_CHAR(actid), funcmode);
      RAISE;
  END check_role_type;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE check_task_type_event(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  ) IS
    l_task_event      VARCHAR2(200);
    l_task_type_name  VARCHAR2(200);
  BEGIN
    IF funcmode = 'RUN' THEN
      l_task_event     := wf_engine.getitemattrtext(itemtype => itemtype, itemkey => itemkey, aname => 'TASK_EVENT');
      l_task_type_name := wf_engine.getitemattrtext(itemtype => itemtype, itemkey => itemkey, aname => 'TASK_TYPE_NAME');
      --
/*    IF l_task_type_name = 'OD Supplier Follow Up' AND
         l_task_event     in ('ADD_ASSIGNEE', 'NEW_ASSIGNEE') */
      IF l_task_event     in ('ADD_ASSIGNEE', 'NEW_ASSIGNEE')
      THEN
        resultout  := 'COMPLETE:T';
				RETURN;
		  ELSE
        resultout  := 'COMPLETE:F';
				RETURN;
		  END IF ;
		ELSE
			resultout  := 'COMPLETE:F';
			RETURN;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT(g_pkg_name, 'Check_Task_Type_Event', itemtype, itemkey, TO_CHAR(actid), funcmode);
      RAISE;
  END check_task_type_event;
/**************************************************************************************************
***************************************************************************************************/

  PROCEDURE show_blank_action_history(
    document_id   IN     VARCHAR2
  , display_type  IN     VARCHAR2
  , document      IN OUT VARCHAR2
  , document_type IN OUT VARCHAR2
  )
  IS
  BEGIN
    document := '<P></P>';
    document_type := 'text/html' ;
  EXCEPTION
    WHEN OTHERS THEN
      wf_core.CONTEXT(g_pkg_name, 'Show_Blank_Action_History', document_id, display_type);
      RAISE;
  END show_blank_action_history ;
END xx_cs_task_wf_util;

/
show errors;
Exit;