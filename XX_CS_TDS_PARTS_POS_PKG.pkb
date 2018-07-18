create or replace PACKAGE BODY xx_cs_tds_parts_pos_pkg
IS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_CS_TDS_PARTS_POS_PKG.pkb                                        |
-- | Description: Wrapper package for update service request and tasks               |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |1.0       07-JUL-2011   Jagadeesh S        Creation                              |
-- |                                                                                 |
---+=================================================================================+
-- -----------------------------------------------------------------------------------
-- Procedure Log Messages
-- -----------------------------------------------------------------------------------
   PROCEDURE log_exception (
      p_object_id            IN   VARCHAR2,
      p_error_location       IN   VARCHAR2,
      p_error_message_code   IN   VARCHAR2,
      p_error_msg            IN   VARCHAR2
   )
   IS
   BEGIN
      xx_com_error_log_pub.log_error
                               (p_return_code                 => fnd_api.g_ret_sts_error,
                                p_msg_count                   => 1,
                                p_application_name            => 'XX_CRM',
                                p_program_type                => 'Custom Messages',
                                p_program_name                => 'XX_CS_TDS_PARTS_POS_PKG',
                                p_object_id                   => p_object_id,
                                p_module_name                 => 'CSF',
                                p_error_location              => p_error_location,
                                p_error_message_code          => p_error_message_code,
                                p_error_message               => p_error_msg,
                                p_error_message_severity      => 'MAJOR',
                                p_error_status                => 'ACTIVE',
                                p_created_by                  => g_user_id,
                                p_last_updated_by             => g_user_id,
                                p_last_update_login           => g_login_id
                               );
   END log_exception;

-- -----------------------------------------------------------------------------------
-- Main Procedure
-- -----------------------------------------------------------------------------------
   PROCEDURE main (
      p_sr_number        IN       VARCHAR2,
      x_return_status    IN OUT   VARCHAR2,
      x_return_message   IN OUT   VARCHAR2
   )
   IS
      l_incident_id     NUMBER;
      l_return_status   VARCHAR2 (30);
      l_msg_count       NUMBER;
      l_msg_data        VARCHAR2 (2000);
      l_obj_ver_num     NUMBER;
      l_sr_status_id    NUMBER;
      l_sr_status       VARCHAR2 (20);
      l_notes           cs_servicerequest_pub.notes_table;
      lc_resolution_code VARCHAR2(50);
      
   BEGIN
      -- Get user_id
      SELECT user_id
        INTO g_user_id
        FROM fnd_user
       WHERE user_name = g_user_name;

      -- Initialize the environment
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
      g_sr_number := p_sr_number;

      BEGIN
         -- Get Incident info
         SELECT incident_id, incident_status_id, 
                object_version_number, resolution_code
           INTO l_incident_id, l_sr_status_id, 
                l_obj_ver_num, lc_resolution_code
           FROM cs_incidents_all_b
          WHERE incident_number = p_sr_number;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status := fnd_api.g_ret_sts_error;
            x_return_message :=
                  'Error in finding the given incident number: '
               || ' - '
               || SQLERRM;
            log_exception (p_object_id               => g_sr_number,
                           p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.MAIN',
                           p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                           p_error_msg               => x_return_message
                          );
      END;
      

      IF NVL(x_return_status, fnd_api.g_ret_sts_success) <> fnd_api.g_ret_sts_error
      THEN
      
      IF lc_resolution_code is null then
         -- Get Incident Status
         SELECT NAME
           INTO l_sr_status
           FROM cs_incident_statuses
          WHERE incident_subtype = 'INC'
            AND incident_status_id = l_sr_status_id;

         l_return_status := NULL;
         l_msg_data := NULL;
         l_msg_count := 0;
         l_notes (1).note_type := 'GENERAL';
         l_notes (1).note := 'Payment Confirmation';
         l_notes (1).note_detail := 'Payment confirmation received';

         IF l_sr_status IN ('Open', 'Service Not Started')
         THEN
            l_return_status := NULL;
            l_msg_data := NULL;
            l_msg_count := 0;
            update_servicerequest (p_sr_request_id      => l_incident_id,
                                   p_obj_ver_num        => l_obj_ver_num,
                                   p_status             => 'Pending In Store',
                                   p_sr_notes           => l_notes,
                                   x_return_status      => l_return_status,
                                   x_msg_data           => l_msg_data
                                  );
            x_return_status := l_return_status;
            x_return_message :=  'Error Status From Update Status: ' || l_msg_data;

            IF l_return_status = fnd_api.g_ret_sts_success
            THEN
               l_return_status := NULL;
               l_msg_data := NULL;
               update_task (l_incident_id, l_return_status, l_msg_data);

               IF l_return_status <> fnd_api.g_ret_sts_success
               THEN
                  x_return_status := l_return_status;
                  x_return_message :=
                              'Error Status From Update Task: ' || l_msg_data;
               END IF;
            END IF;
         ELSE
            l_return_status := NULL;
            l_msg_data := NULL;
            create_note (l_incident_id, l_notes, l_return_status, l_msg_data);
            x_return_status := l_return_status;
            fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
            lc_resolution_code := 'TDS_PAYMENT';
            BEGIN
              UPDATE CS_INCIDENTS_ALL_B
              SET RESOLUTION_CODE = LC_RESOLUTION_CODE
              WHERE INCIDENT_ID = L_INCIDENT_ID;
              
              COMMIT;
            EXCEPTION
              WHEN OTHERS THEN
                  x_return_status := l_return_status;
            END;

            IF l_return_status <> fnd_api.g_ret_sts_success
            THEN
               x_return_message := 'Error Status From Create Note: ' || l_msg_data;
            END IF;
         END IF;
       else
          x_return_status := fnd_api.g_ret_sts_error;
          x_return_message := 'Duplicate confirmation';
       END IF;  -- RESOLUTION CODE
      END IF;  -- X_RETURN_STATUS
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_return_message :=
                         'Exception in main for incident number: ' || SQLERRM;
         log_exception (p_object_id               => g_sr_number,
                        p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.MAIN',
                        p_error_message_code      => 'XX_CS_SR01_ERR_LOG',
                        p_error_msg               => x_return_message
                       );
   END main;

-- -----------------------------------------------------------------------------------
-- Procedure Update Service Request
-- -----------------------------------------------------------------------------------
   PROCEDURE update_servicerequest (
      p_sr_request_id   IN       NUMBER,
      p_obj_ver_num     IN       NUMBER,
      p_status          IN       VARCHAR2,
      p_sr_notes        IN       cs_servicerequest_pub.notes_table,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   )
   IS
      l_msg_count             NUMBER;
      l_msg_data              VARCHAR2 (2000);
      l_interaction_id        NUMBER;
      l_return_status         VARCHAR2 (10);
      l_msg_index_out         VARCHAR2 (2000);
      l_status_id             NUMBER;
      l_sr_number             VARCHAR2 (100);
      l_contacts              cs_servicerequest_pvt.contacts_table;
      l_service_request_rec   cs_servicerequest_pvt.service_request_rec_type;
      l_notes                 cs_servicerequest_pub.notes_table;
   BEGIN
      l_return_status := NULL;
      l_msg_count := 0;
      l_msg_data := NULL;
      l_interaction_id := NULL;
      l_notes := p_sr_notes;

      -- Get user_id
      SELECT user_id
        INTO g_user_id
        FROM fnd_user
       WHERE user_name = g_user_name;

      BEGIN
         -- Get Incident info
         SELECT incident_number
           INTO l_sr_number
           FROM cs_incidents_all_b
          WHERE object_version_number = p_obj_ver_num
            AND incident_id = p_sr_request_id;

         g_sr_number := l_sr_number;
         l_return_status := fnd_api.g_ret_sts_success;
      EXCEPTION
         WHEN OTHERS
         THEN
            x_return_status := fnd_api.g_ret_sts_error;
            l_msg_data :=
                    'Error in finding the given incident number: ' || SQLERRM;
            l_return_status := fnd_api.g_ret_sts_error;
            log_exception
               (p_object_id               => TO_CHAR (p_sr_request_id),
                p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_SERVICEREQUEST',
                p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                p_error_msg               => l_msg_data
               );
      END;

      IF (l_return_status = fnd_api.g_ret_sts_success)
      THEN
         -- Get Incident Status
         SELECT incident_status_id
           INTO l_status_id
           FROM cs_incident_statuses
          WHERE incident_subtype = 'INC' AND NAME = p_status;

         fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
         cs_servicerequest_pub.update_status
                                    (p_api_version                    => 2.0,
                                     p_init_msg_list                  => fnd_api.g_true,
                                     p_commit                         => fnd_api.g_false,
                                     x_return_status                  => l_return_status,
                                     x_msg_count                      => l_msg_count,
                                     x_msg_data                       => l_msg_data,
                                     p_resp_appl_id                   => g_resp_appl_id,
                                     p_resp_id                        => g_resp_id,
                                     p_user_id                        => g_user_id,
                                     p_login_id                       => NULL,
                                     p_request_id                     => p_sr_request_id,
                                     p_request_number                 => NULL,
                                     p_object_version_number          => p_obj_ver_num,
                                     p_status_id                      => l_status_id,
                                     p_status                         => NULL,
                                     p_closed_date                    => SYSDATE,
                                     p_audit_comments                 => NULL,
                                     p_called_by_workflow             => NULL,
                                     p_workflow_process_id            => NULL,
                                     p_comments                       => NULL,
                                     p_public_comment_flag            => fnd_api.g_false,
                                     p_validate_sr_closure            => 'N',
                                     p_auto_close_child_entities      => 'N',
                                     x_interaction_id                 => l_interaction_id
                                    );
         x_return_status := l_return_status;

         -- Check errors
         IF (l_return_status <> fnd_api.g_ret_sts_success)
         THEN
            IF (fnd_msg_pub.count_msg >= 1)
            THEN
               --Display all the error messages
               FOR j IN 1 .. fnd_msg_pub.count_msg
               LOOP
                  fnd_msg_pub.get (p_msg_index          => j,
                                   p_encoded            => 'F',
                                   p_data               => x_msg_data,
                                   p_msg_index_out      => l_msg_index_out
                                  );
               END LOOP;
            ELSE
               --Only one error
               fnd_msg_pub.get (p_msg_index          => 1,
                                p_encoded            => 'F',
                                p_data               => x_msg_data,
                                p_msg_index_out      => l_msg_index_out
                               );
            END IF;

            l_msg_data := 'Error while updating service request ' || SQLERRM;
            log_exception
               (p_object_id               => g_sr_number,
                p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_SERVICEREQUEST',
                p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
                p_error_msg               => x_msg_data
               );
         ELSE
            COMMIT;

            -- if no errors from update_status API
            IF l_notes.COUNT > 0
            THEN
               l_return_status := NULL;
               l_msg_data := NULL;
               create_note (p_sr_request_id,
                            l_notes,
                            l_return_status,
                            l_msg_data
                           );
               x_return_status := l_return_status;
               x_msg_data := l_msg_data;
            END IF;
         END IF;
      ELSE
         x_return_status := l_return_status;
         x_msg_data := l_msg_data;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_msg_data := 'Error while updating service request ' || SQLERRM;
         log_exception
            (p_object_id               => g_sr_number,
             p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_SERVICEREQUEST',
             p_error_message_code      => 'XX_CS_SR02_ERR_LOG',
             p_error_msg               => x_msg_data
            );
   END update_servicerequest;

-- -----------------------------------------------------------------------------------
-- Procedure Create Note
-- -----------------------------------------------------------------------------------
   PROCEDURE create_note (
      p_sr_request_id   IN       NUMBER,
      p_sr_notes        IN       cs_servicerequest_pub.notes_table,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   )
   IS
      l_notes           cs_servicerequest_pub.notes_table;
      l_note_contexts   jtf_notes_pub.jtf_note_contexts_tbl_type;
      l_return_status   VARCHAR2 (10);
      l_msg_count       NUMBER;
      l_msg_data        VARCHAR2 (2000);
      l_jtf_note_id     NUMBER;
      l_msg_index_out   VARCHAR2 (2000);
      l_sr_number       VARCHAR2 (100);
   BEGIN
      l_return_status := NULL;
      l_msg_count := 0;
      l_msg_data := NULL;
      l_jtf_note_id := NULL;
      l_notes := p_sr_notes;

      -- Get user_id
      SELECT user_id
        INTO g_user_id
        FROM fnd_user
       WHERE user_name = g_user_name;

      BEGIN
         -- Get Incident info
         SELECT incident_number
           INTO l_sr_number
           FROM cs_incidents_all_b
          WHERE incident_id = p_sr_request_id;

         g_sr_number := l_sr_number;
         l_return_status := fnd_api.g_ret_sts_success;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data :=
                    'Error in finding the given incident number: ' || SQLERRM;
            l_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (p_object_id               => TO_CHAR (p_sr_request_id),
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE',
                   p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
      END;

      IF (l_return_status = fnd_api.g_ret_sts_success)
      THEN
         fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);

         IF l_notes.COUNT = 1
         THEN
            jtf_notes_pub.create_note
                           (p_api_version                => 1.0,
                            p_init_msg_list              => fnd_api.g_true,
                            p_commit                     => fnd_api.g_false,
                            p_validation_level           => fnd_api.g_valid_level_full,
                            x_return_status              => l_return_status,
                            x_msg_count                  => l_msg_count,
                            x_msg_data                   => l_msg_data,
                            p_jtf_note_id                => l_jtf_note_id,
                            p_entered_by                 => g_user_id,
                            p_entered_date               => SYSDATE,
                            p_source_object_id           => p_sr_request_id,
                            p_source_object_code         => 'SR',
                            p_notes                      => l_notes (1).note,
                            p_notes_detail               => l_notes (1).note_detail,
                            p_note_type                  => l_notes (1).note_type,
                            p_note_status                => 'I',
                            p_jtf_note_contexts_tab      => l_note_contexts,
                            x_jtf_note_id                => l_jtf_note_id,
                            p_last_update_date           => SYSDATE,
                            p_last_updated_by            => g_user_id,
                            p_creation_date              => SYSDATE,
                            p_created_by                 => g_user_id,
                            p_last_update_login          => fnd_global.login_id
                           );
            x_return_status := l_return_status;

            -- Check errors
            IF (l_return_status <> fnd_api.g_ret_sts_success)
            THEN
               IF (fnd_msg_pub.count_msg >= 1)
               THEN
                  --Display all the error messages
                  FOR j IN 1 .. fnd_msg_pub.count_msg
                  LOOP
                     fnd_msg_pub.get (p_msg_index          => j,
                                      p_encoded            => 'F',
                                      p_data               => l_msg_data,
                                      p_msg_index_out      => l_msg_index_out
                                     );
                     x_msg_data := x_msg_data || ' - ' || l_msg_data;
                  END LOOP;
               ELSE
                  --Only one error
                  fnd_msg_pub.get (p_msg_index          => 1,
                                   p_encoded            => 'F',
                                   p_data               => x_msg_data,
                                   p_msg_index_out      => l_msg_index_out
                                  );
               END IF;

               l_msg_data := 'Error while creating note : ' || SQLERRM;
               log_exception
                   (p_object_id               => g_sr_number,
                    p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE',
                    p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                    p_error_msg               => l_msg_data
                   );
            ELSE
               COMMIT;
            END IF;
         ELSIF l_notes.COUNT > 1
         THEN
            FOR i IN l_notes.FIRST .. l_notes.LAST
            LOOP
               l_return_status := NULL;
               l_msg_count := 0;
               l_msg_data := NULL;
               l_jtf_note_id := NULL;
               jtf_notes_pub.create_note
                           (p_api_version                => 1.0,
                            p_init_msg_list              => fnd_api.g_true,
                            p_commit                     => fnd_api.g_false,
                            p_validation_level           => fnd_api.g_valid_level_full,
                            x_return_status              => l_return_status,
                            x_msg_count                  => l_msg_count,
                            x_msg_data                   => l_msg_data,
                            p_jtf_note_id                => l_jtf_note_id,
                            p_entered_by                 => g_user_id,
                            p_entered_date               => SYSDATE,
                            p_source_object_id           => p_sr_request_id,
                            p_source_object_code         => 'SR',
                            p_notes                      => l_notes (i).note,
                            p_notes_detail               => l_notes (i).note_detail,
                            p_note_type                  => l_notes (i).note_type,
                            p_note_status                => 'I', -- I - Public
                            p_jtf_note_contexts_tab      => l_note_contexts,
                            x_jtf_note_id                => l_jtf_note_id,
                            p_last_update_date           => SYSDATE,
                            p_last_updated_by            => g_user_id,
                            p_creation_date              => SYSDATE,
                            p_created_by                 => g_user_id,
                            p_last_update_login          => g_login_id
                           );
               x_return_status := l_return_status;

               -- Check errors
               IF (l_return_status <> fnd_api.g_ret_sts_success)
               THEN
                  IF (fnd_msg_pub.count_msg >= 1)
                  THEN
                     --Display all the error messages
                     FOR j IN 1 .. fnd_msg_pub.count_msg
                     LOOP
                        fnd_msg_pub.get (p_msg_index          => j,
                                         p_encoded            => 'F',
                                         p_data               => l_msg_data,
                                         p_msg_index_out      => l_msg_index_out
                                        );
                        x_msg_data := x_msg_data || ' - ' || l_msg_data;
                     END LOOP;
                  ELSE
                     --Only one error
                     fnd_msg_pub.get (p_msg_index          => 1,
                                      p_encoded            => 'F',
                                      p_data               => x_msg_data,
                                      p_msg_index_out      => l_msg_index_out
                                     );
                  END IF;

                  l_msg_data :=
                        'Error while creating note for index: '
                     || i
                     || ' : '
                     || SQLERRM;
                  log_exception
                     (p_object_id               => g_sr_number,
                      p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE',
                      p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                      p_error_msg               => x_msg_data
                     );
               ELSE
                  COMMIT;
               END IF;
            END LOOP;
         END IF;
      ELSE
         x_return_status := l_return_status;
         x_msg_data := l_msg_data;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_msg_data := 'Error while creating note ' || SQLERRM;
         log_exception
                  (p_object_id               => g_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.CREATE_NOTE',
                   p_error_message_code      => 'XX_CS_SR03_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
   END create_note;

-- -----------------------------------------------------------------------------------
-- Procedure Update Task
-- -----------------------------------------------------------------------------------
   PROCEDURE update_task (
      p_sr_request_id   IN       NUMBER,
      x_return_status   OUT      VARCHAR2,
      x_msg_data        OUT      VARCHAR2
   )
   IS
      l_msg_data         VARCHAR2 (2000);
      l_msg_count        NUMBER;
      l_return_status    VARCHAR2 (10);
      l_task_id          NUMBER;
      l_obj_ver_no       NUMBER;
      l_store            VARCHAR2 (100);
      l_category         VARCHAR2 (20);
      l_resource_id      NUMBER;
      l_msg_index_out    VARCHAR2 (2000);
      l_task_status_id   NUMBER;
      l_task_assign_id   NUMBER;
      l_status           VARCHAR2 (10);
      l_status_msg       VARCHAR2 (2000);
      l_sr_number        VARCHAR2 (100);
   BEGIN
      -- Get user_id
      SELECT user_id
        INTO g_user_id
        FROM fnd_user
       WHERE user_name = g_user_name;

      BEGIN
         -- Get Incident info
         SELECT incident_number
           INTO l_sr_number
           FROM cs_incidents_all_b
          WHERE incident_id = p_sr_request_id;

         g_sr_number := l_sr_number;
         l_return_status := fnd_api.g_ret_sts_success;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_msg_data :=
                    'Error in finding the given incident number: ' || SQLERRM;
            l_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (p_object_id               => TO_CHAR (p_sr_request_id),
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UDPATE_TASK',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => l_msg_data
                  );
      END;

      IF l_return_status = fnd_api.g_ret_sts_success
      THEN
         BEGIN
            -- Get the task_id
            SELECT task_id, object_version_number
              INTO l_task_id, l_obj_ver_no
              FROM jtf_tasks_vl
             WHERE source_object_id = p_sr_request_id
               AND source_object_type_code = 'SR'
               AND task_name = 'TDS Diagnosis and Repair'
               AND attribute1 = 'Nexicore';

            l_status := fnd_api.g_ret_sts_success;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_status := fnd_api.g_ret_sts_error;
               l_status_msg := 'Task_id can not found';
         END;

         BEGIN
            -- Get Incident info
            SELECT incident_attribute_11
              INTO l_store
              FROM cs_incidents_all_b
             WHERE incident_id = p_sr_request_id;

            l_status := fnd_api.g_ret_sts_success;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_status := fnd_api.g_ret_sts_error;
               l_status_msg :=
                            l_status_msg || ' - ' || 'Store_id can not found';
         END;

         BEGIN
            --  Get resource category
            SELECT 'RS_' || CATEGORY, resource_id
              INTO l_category, l_resource_id
              FROM jtf_rs_resource_extns
             WHERE user_name = l_store;

            l_status := fnd_api.g_ret_sts_success;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_status := fnd_api.g_ret_sts_error;
               l_status_msg :=
                  l_status_msg || ' - '
                  || 'Category and resouce can not found';
         END;

         BEGIN
            -- Get task status id
            SELECT task_status_id
              INTO l_task_status_id
              FROM jtf_task_statuses_vl
             WHERE NAME = 'Accepted';

            l_status := fnd_api.g_ret_sts_success;
         EXCEPTION
            WHEN OTHERS
            THEN
               l_status := fnd_api.g_ret_sts_error;
               l_status_msg :=
                  l_status_msg || ' - '
                  || 'Category and resouce can not found';
         END;

         IF     l_status = fnd_api.g_ret_sts_success
            AND l_task_id IS NOT NULL
            AND l_obj_ver_no IS NOT NULL
            AND l_task_status_id IS NOT NULL
         THEN
            BEGIN
               fnd_global.apps_initialize (g_user_id,
                                           g_resp_id,
                                           g_resp_appl_id
                                          );
               jtf_tasks_pub.update_task
                                     (p_api_version                => 1.0,
                                      p_init_msg_list              => fnd_api.g_true,
                                      p_commit                     => fnd_api.g_false,
                                      p_object_version_number      => l_obj_ver_no,
                                      p_task_id                    => l_task_id,
                                      p_task_status_id             => l_task_status_id,
                                      p_task_number                => NULL,
                                      p_planned_start_date         => SYSDATE,
                                      p_scheduled_start_date       => SYSDATE,
                                      x_return_status              => l_return_status,
                                      x_msg_count                  => l_msg_count,
                                      x_msg_data                   => l_msg_data,
                                      p_enable_workflow            => NULL,
                                      p_abort_workflow             => NULL,
                                      p_task_split_flag            => NULL
                                     );
               x_return_status := l_return_status;

               -- Check errors
               IF (l_return_status <> fnd_api.g_ret_sts_success)
               THEN
                  IF (fnd_msg_pub.count_msg >= 1)
                  THEN
                     --Display all the error messages
                     FOR j IN 1 .. fnd_msg_pub.count_msg
                     LOOP
                        fnd_msg_pub.get (p_msg_index          => j,
                                         p_encoded            => 'F',
                                         p_data               => x_msg_data,
                                         p_msg_index_out      => l_msg_index_out
                                        );
                     END LOOP;
                  ELSE
                     --Only one error
                     fnd_msg_pub.get (p_msg_index          => 1,
                                      p_encoded            => 'F',
                                      p_data               => x_msg_data,
                                      p_msg_index_out      => l_msg_index_out
                                     );
                  END IF;

                  l_msg_data := 'Error while updating task ' || SQLERRM;
                  log_exception
                     (p_object_id               => g_sr_number,
                      p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_TASK',
                      p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                      p_error_msg               => l_msg_data
                     );
               ELSE
                  COMMIT;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  x_msg_data := 'Error while updating task ' || SQLERRM;
                  log_exception
                     (p_object_id               => g_sr_number,
                      p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_TASK',
                      p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                      p_error_msg               => x_msg_data
                     );
            END;

            IF     (l_return_status = fnd_api.g_ret_sts_success)
               AND l_category IS NOT NULL
               AND l_resource_id IS NOT NULL
               AND l_task_status_id IS NOT NULL
            THEN
               -- if task update status is success then call to task assignment
               BEGIN
                  l_return_status := NULL;
                  l_msg_count := NULL;
                  l_msg_data := NULL;
                  jtf_task_assignments_pub.create_task_assignment
                                 (p_api_version               => 1.0,
                                  p_init_msg_list             => fnd_api.g_true,
                                  p_commit                    => fnd_api.g_false,
                                  p_task_id                   => l_task_id,
                                  p_resource_type_code        => l_category,
                                  p_resource_id               => l_resource_id,
                                  p_assignment_status_id      => l_task_status_id,
                                  ---- 2,
                                  p_actual_start_date         => SYSDATE,
                                  x_return_status             => l_return_status,
                                  x_msg_count                 => l_msg_count,
                                  x_msg_data                  => l_msg_data,
                                  x_task_assignment_id        => l_task_assign_id,
                                  p_enable_workflow           => NULL,
                                  p_abort_workflow            => NULL,
                                  p_object_capacity_id        => NULL,
                                  p_free_busy_type            => NULL
                                 );
                  x_return_status := l_return_status;

                  -- Check errors
                  IF (l_return_status <> fnd_api.g_ret_sts_success)
                  THEN
                     IF (fnd_msg_pub.count_msg >= 1)
                     THEN
                        --Display all the error messages
                        FOR j IN 1 .. fnd_msg_pub.count_msg
                        LOOP
                           fnd_msg_pub.get
                                          (p_msg_index          => j,
                                           p_encoded            => 'F',
                                           p_data               => x_msg_data,
                                           p_msg_index_out      => l_msg_index_out
                                          );
                        END LOOP;
                     ELSE
                        --Only one error
                        fnd_msg_pub.get (p_msg_index          => 1,
                                         p_encoded            => 'F',
                                         p_data               => x_msg_data,
                                         p_msg_index_out      => l_msg_index_out
                                        );
                     END IF;

                     x_msg_data :=
                            'Error while creating task assignment ' || SQLERRM;
                     log_exception
                        (p_object_id               => g_sr_number,
                         p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_TASK',
                         p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                         p_error_msg               => x_msg_data
                        );
                  ELSE
                     COMMIT;
                  END IF;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     x_msg_data :=
                           'Error while creating task assignment ' || SQLERRM;
                     log_exception
                        (p_object_id               => g_sr_number,
                         p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_TASK',
                         p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                         p_error_msg               => x_msg_data
                        );
               END;
            END IF;
         ELSE
            x_msg_data := 'Error while updating task - ' || l_status_msg;
            x_return_status := fnd_api.g_ret_sts_error;
            log_exception
                  (p_object_id               => g_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_TASK',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
         END IF;
      ELSE
         x_return_status := l_return_status;
         x_msg_data := l_msg_data;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         x_return_status := fnd_api.g_ret_sts_error;
         x_msg_data := 'Error in udpate task procedure ' || SQLERRM;
         log_exception
                  (p_object_id               => g_sr_number,
                   p_error_location          => 'XX_CS_TDS_PARTS_POS_PKG.UPDATE_TASK',
                   p_error_message_code      => 'XX_CS_SR04_ERR_LOG',
                   p_error_msg               => x_msg_data
                  );
   End Update_Task;
END xx_cs_tds_parts_pos_pkg;
/
SHOW errors;