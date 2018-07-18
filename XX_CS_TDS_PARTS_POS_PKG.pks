SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Spec xx_cs_tds_parts_pos_pkg
PROMPT Program exits if the creation is not SUCCESSFUL

CREATE OR REPLACE PACKAGE xx_cs_tds_parts_pos_pkg
IS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_CS_TDS_PARTS_POS_PKG.pks                                        |
-- | Description: Wrapper package for update service request and tasks               |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |1.0       07-JUL-2011   Jagadeesh S        Creation                              |
-- |                                                                                 |
---+=================================================================================+
   g_user_id                 PLS_INTEGER;
   g_resp_id        CONSTANT PLS_INTEGER   := 21739; -- fnd_global.resp_id;
   g_resp_appl_id   CONSTANT PLS_INTEGER   := 514;   -- fnd_global.resp_appl_id;
   g_login_id       CONSTANT PLS_INTEGER   := -1;    -- fnd_global.login_id;
   g_user_name      CONSTANT VARCHAR2 (20) := 'CS_ADMIN';
   g_sr_number               VARCHAR2 (50);

   PROCEDURE main (
      p_sr_number        IN       VARCHAR2,
      x_return_status    IN OUT   VARCHAR2,
      x_return_message   IN OUT   VARCHAR2
   );

   PROCEDURE update_servicerequest (
      p_sr_request_id   IN       NUMBER,
      p_obj_ver_num     IN       NUMBER,
      p_status          IN       VARCHAR2,
      p_sr_notes        IN       cs_servicerequest_pub.notes_table,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );

   PROCEDURE create_note (
      p_sr_request_id   IN       NUMBER,
      p_sr_notes        IN       cs_servicerequest_pub.notes_table,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );

   PROCEDURE update_task (
      p_sr_request_id   IN       NUMBER,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   );
END xx_cs_tds_parts_pos_pkg;
/

SHOW errors;