CREATE OR REPLACE PACKAGE APPS.xx_cs_task_wf_util AUTHID CURRENT_USER AS

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
  * Mohsin Ansari   Procedure to create skeleton Action History table
  *                                                         4/8/08
  *
  ****************************************************************************/

  g_pkg_name            CONSTANT VARCHAR2(30)                       := 'XX_CS_Task_WF_Util';
  jtf_task_wf_item_type CONSTANT VARCHAR2(8)                        := 'JTFTASK';
  jtf_task_main_process CONSTANT VARCHAR2(30)                       := 'XX_CS_TASK_WORKFLOW';

  -- ROLE_TYPE indicates whether the role name is for a Owner or Assignee
  TYPE nlist_rec_type IS RECORD(
    NAME          wf_users.NAME%TYPE            := fnd_api.g_miss_char
  , display_name  wf_users.display_name%TYPE    := fnd_api.g_miss_char
  , email_address wf_users.email_address%TYPE   := fnd_api.g_miss_char
  , role_type     VARCHAR2(10)                  := fnd_api.g_miss_char
  );


  TYPE nlist_tbl_type IS TABLE OF nlist_rec_type
    INDEX BY BINARY_INTEGER;

  notiflist                      nlist_tbl_type;
  g_miss_notiflist               nlist_tbl_type;
  g_miss_nlist_rec               nlist_rec_type;
  g_event                        VARCHAR2(80);
  g_task_id                      jtf_tasks_b.task_id%TYPE;
  g_old_owner_id                 jtf_tasks_b.owner_id%TYPE;
  g_old_owner_code               jtf_tasks_b.owner_type_code%TYPE;
  g_owner_id                     jtf_tasks_b.owner_id%TYPE;
  g_owner_type_code              jtf_tasks_b.owner_type_code%TYPE;
  g_old_assignee_id              jtf_tasks_b.owner_id%TYPE;
  g_old_assignee_code            jtf_tasks_b.owner_type_code%TYPE;
  g_new_assignee_id              jtf_tasks_b.owner_id%TYPE;
  g_new_assignee_code            jtf_tasks_b.owner_type_code%TYPE;
  --
  -- g_role_type defined to keep track of what role type is being resolved
  g_role_type    VARCHAR2(10) := fnd_api.g_miss_char ;

  PROCEDURE set_notif_performer(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  );

  PROCEDURE set_notif_list(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  );

  PROCEDURE select_task_event(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  );

  PROCEDURE check_role_type(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  );

  PROCEDURE check_task_type_event(
    itemtype  IN            VARCHAR2
  , itemkey   IN            VARCHAR2
  , actid     IN            NUMBER
  , funcmode  IN            VARCHAR2
  , resultout OUT NOCOPY    VARCHAR2
  );

  PROCEDURE show_blank_action_history(
    document_id   IN     VARCHAR2
  , display_type  IN     VARCHAR2
  , document      IN OUT VARCHAR2
  , document_type IN OUT VARCHAR2
  );

END xx_cs_task_wf_util;
/

