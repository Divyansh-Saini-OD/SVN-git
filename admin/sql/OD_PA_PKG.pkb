SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
set serveroutput on;
CREATE OR REPLACE PACKAGE BODY OD_PA_PKG
AS
   g_user_id        NUMBER := apps.fnd_global.user_id;
   g_resp_id        NUMBER := apps.fnd_global.resp_id;
   g_resp_appl_id   NUMBER := apps.fnd_global.resp_appl_id;

/*============================================================================+
|               Office Depot                                  |
+=============================================================================+
|                                                                             |
| Program Name :  OD_PA_PKG.PKB                                               |
| Purpose      :  Package specification to update task and project statuses   |
|                                                              |
| Parameters   :  Project Id, Task Id.                                                       |
|                                                                             |
| Ver  Date       Name           Revision Description                         |
| ===  =========  ============== ===========================================  |
| 1.0  09-SEP-11  Suraj Charan   Initial.                                     |
+=============================================================================*/
   PROCEDURE od_update_task_manager_person (
      p_projectid             IN       NUMBER,
      p_taskid                IN       NUMBER,
      p_taskmanagerpersonid   IN       NUMBER,
      p_sdate                 IN       VARCHAR2,
      p_edate                 IN       VARCHAR2,
      errmsg                  OUT      VARCHAR2
   )
   IS
      l_return_status             VARCHAR2 (1)                        := NULL;
      l_msg_count                 NUMBER                                 := 0;
      l_msg_data                  VARCHAR2 (1000)                     := NULL;
      l_pm_product_code           VARCHAR2 (30)                       := NULL;
      l_task_name                 VARCHAR2 (20)                       := NULL;
      l_out_pa_task_id            NUMBER;
      l_out_pm_task_reference     VARCHAR2 (25);
      l_project_resource_status   VARCHAR2 (30)                       := NULL;
      l_pa_source_template_id     NUMBER;
      l_rec_no                    NUMBER                                 := 1;
      x_msg_cnt                   NUMBER                                 := 0;
      l_project_in_rec_type       apps.pa_project_pub.project_in_rec_type;
      l_project_out_rec_type      apps.pa_project_pub.project_out_rec_type;
      l_key_members               apps.pa_project_pub.project_role_tbl_type;
      l_class_categories          apps.pa_project_pub.class_category_tbl_type;
      l_task_in_tbl_type          apps.pa_project_pub.task_in_tbl_type;
      l_tasks_out                 apps.pa_project_pub.task_out_tbl_type;
      l_org_roles                 apps.pa_project_pub.project_role_tbl_type;
      l_structure_in              apps.pa_project_pub.structure_in_rec_type;
      l_pass_entire_structure     VARCHAR2 (1)                         := 'Y';
      l_ext_attr_in_tbl           apps.pa_project_pub.pa_ext_attr_table_type;
      x_msg_data                  VARCHAR2 (2000)                     := NULL;
      x_return_status             VARCHAR2 (1)                        := NULL;
      l_workflow_started          VARCHAR2 (1);
      x_error_data                VARCHAR2 (2000)                     := NULL;
      x_msg_index_out             NUMBER;
      l_api_err_msg               VARCHAR2 (4000)                     := NULL;
      l_prgm_status               VARCHAR2 (1)                        := NULL;
   BEGIN
      l_prgm_status := 'Y';

      BEGIN
         SELECT ppa.pm_product_code
           INTO l_pm_product_code
           FROM pa_projects ppa
          WHERE ppa.project_id = p_projectid;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_pm_product_code := 'WORKPLAN';
      END;

      BEGIN
         SELECT pt.task_name
           INTO l_task_name
           FROM pa_tasks pt
          WHERE pt.project_id = p_projectid AND pt.task_id = p_taskid;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_task_name := NULL;
      END;

      BEGIN
         SELECT DECODE (1, 1, 'RESOURCE EXISTS', 'RESOURCE NOT EXISTING')
                                                             proj_resc_status
           INTO l_project_resource_status
           FROM pa_project_players
          WHERE project_id = p_projectid AND person_id = p_taskmanagerpersonid;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
--     errMsg := 'NO Records for RESOURCE EXISTENCE';
            l_project_resource_status := 'RESOURCE NOT EXISTING';
         WHEN OTHERS
         THEN
            errmsg := x_msg_data;                       --'ERROR IN PROCESS';
      END;

      DBMS_OUTPUT.put_line (   'Before  L_PROJECT_RESOURCE_STATUS= '
                            || l_project_resource_status
                           );
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);

      IF (l_project_resource_status = 'RESOURCE NOT EXISTING')
      THEN
         /* Assign Resource to Project*/
         l_prgm_status := 'N';

         BEGIN
            l_project_in_rec_type.pa_project_id := p_projectid;     --104210;
            l_key_members (l_rec_no).person_id := p_taskmanagerpersonid;
                                                                     --35065;
            l_key_members (l_rec_no).project_role_type := '1000';
            l_key_members (l_rec_no).start_date := p_sdate;  --'15-NOV-2011';
            l_key_members (l_rec_no).end_date := p_edate;    --'15-NOV-2012';
            l_project_in_rec_type.pa_project_id := p_projectid;     --104210;
            fnd_msg_pub.delete_msg (NULL);
            --ADDING A NEW RESOURCE AT PROJECT LEVEL
            DBMS_OUTPUT.put_line
                            (   'Before  pa_project_pub.update_project API= '
                             || l_project_resource_status
                            );
            apps.pa_project_pub.update_project
                          (p_api_version_number         => 1.0,
                           p_commit                     => fnd_api.g_false,
                           p_init_msg_list              => fnd_api.g_true,
                           p_msg_count                  => x_msg_cnt,
                           p_msg_data                   => x_msg_data,
                           p_return_status              => x_return_status,
                           p_workflow_started           => l_workflow_started,
                           p_pm_product_code            => l_pm_product_code,
                           p_project_in                 => l_project_in_rec_type,
                           p_project_out                => l_project_out_rec_type,
                           p_key_members                => l_key_members,
                           p_class_categories           => l_class_categories,
                           p_tasks_in                   => l_task_in_tbl_type,
                           p_tasks_out                  => l_tasks_out,
                           p_org_roles                  => l_org_roles,
                           p_structure_in               => l_structure_in,
                           p_pass_entire_structure      => l_pass_entire_structure,
                           p_ext_attr_tbl_in            => l_ext_attr_in_tbl
                          );
            COMMIT;
            DBMS_OUTPUT.put_line
               (   'AFTER  pa_project_pub.update_project API  x_return_status='
                || x_return_status
               );

            IF x_return_status != 'S'
            THEN
                   /*FOR i IN 1 .. NVL (x_msg_cnt, 0)
               LOOP
               pa_interface_utils_pub.get_messages (p_encoded            => fnd_api.g_false,
                                    p_msg_count          => x_msg_cnt,
                                    p_msg_index          => i,
                                    p_msg_data           => x_msg_data,
                                    p_data               => x_error_data,
                                    p_msg_index_out      => x_msg_index_out
                                    );
               */
               l_api_err_msg := l_api_err_msg || x_error_data;

               FOR i IN 1 .. x_msg_cnt
               LOOP
                  x_msg_data :=
                     SUBSTR (fnd_msg_pub.get (fnd_msg_pub.g_first,
                                              fnd_api.g_false
                                             ),
                             1,
                             3000
                            );
                  x_msg_data := x_msg_data || '-' || x_msg_data;
               END LOOP;

               --END LOOP;
               ROLLBACK;
               errmsg := x_msg_data;
            ELSIF x_return_status = 'S'
            THEN
               l_prgm_status := 'Y';
               COMMIT;
               errmsg := x_return_status;
               DBMS_OUTPUT.put_line ('Success');
               errmsg := x_return_status;
            END IF;
         EXCEPTION
            WHEN OTHERS
            THEN
               errmsg := x_msg_data;                    --'ERROR IN PROCESS';
         END;
      /* Assign Resource to Project*/
      END IF;

      IF l_prgm_status = 'Y'
      THEN
         apps.pa_project_pub.update_task
                          (p_api_version_number          => '1.0',
                           p_commit                      => fnd_api.g_false,
                           p_init_msg_list               => fnd_api.g_true,
                           p_msg_count                   => l_msg_count,
                           p_msg_data                    => l_msg_data,
                           p_return_status               => l_return_status,
                           p_pm_product_code             => l_pm_product_code,
                           p_pm_project_reference        => NULL,
                           p_pa_project_id               => p_projectid,
                           p_pm_task_reference           => NULL,
                           p_pa_task_id                  => p_taskid,
                           p_task_manager_person_id      => p_taskmanagerpersonid,
                           p_task_name                   => l_task_name,
                           p_out_pa_task_id              => l_out_pa_task_id,
                           p_out_pm_task_reference       => l_out_pm_task_reference
                          );

         IF l_return_status != 'S'
         THEN
            l_msg_data :=
               SUBSTR (fnd_msg_pub.get (fnd_msg_pub.g_first, fnd_api.g_false),
                       1,
                       3000
                      );
            l_msg_data := l_msg_data;
            DBMS_OUTPUT.put_line ('L_Msg_Data=' || l_msg_data);

            FOR i IN 1 .. l_msg_count
            LOOP
               l_msg_data :=
                  SUBSTR (fnd_msg_pub.get (fnd_msg_pub.g_first,
                                           fnd_api.g_false
                                          ),
                          1,
                          3000
                         );
               l_msg_data := l_msg_data ;
            END LOOP;

            DBMS_OUTPUT.put_line ('L_Msg_Data=' || l_msg_data);
            errmsg := l_msg_data;
         ELSIF l_return_status = 'S'
         THEN
            UPDATE pa_proj_elements ppe
               SET manager_person_id = p_taskmanagerpersonid
             WHERE ppe.proj_element_id = p_taskid;

            errmsg := l_return_status;
            COMMIT;
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg := l_msg_data;                          --'ERROR IN PROCESS';
   END;

   PROCEDURE od_update_status (
      projectid   IN       NUMBER,
      taskid      IN       NUMBER,
      staustype   IN       VARCHAR2,
      errmsg      OUT      VARCHAR2
   )
   IS
      l_return_status      VARCHAR2 (1)    := NULL;
      l_msg_count          NUMBER          := 0;
      l_msg_data           VARCHAR2 (1000) := NULL;
      l_as_of_date         DATE            := TRUNC (SYSDATE);
      l_pm_product_code    VARCHAR2 (30)   := NULL;
      l_percent_complete   NUMBER (7, 4);
      l_task_status        VARCHAR2 (25)   := staustype;
   BEGIN
      -- fnd_global.apps_initialize(1209807,52963,275);
      fnd_global.apps_initialize (g_user_id, g_resp_id, g_resp_appl_id);
      l_percent_complete := 100;

      BEGIN
         SELECT DECODE (SIGN (TRUNC (date_computed) - TRUNC (SYSDATE)),
                        1, TRUNC (date_computed) + 1,
                        0, TRUNC (SYSDATE) + 1,
                        TRUNC (SYSDATE)
                       ) as_of_date
           INTO l_as_of_date
           FROM pa_percent_completes
          WHERE task_id = taskid AND current_flag = 'Y'
	    AND rownum =1;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_as_of_date := TRUNC (SYSDATE);
	    errmsg:='Error as of date' ||l_as_of_date;
      END;

      BEGIN
         SELECT ppa.pm_product_code
           INTO l_pm_product_code
           FROM pa_projects_all ppa
          WHERE ppa.project_id = projectid;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_pm_product_code := NULL;
      END;

      pa_status_pub.update_progress (p_api_version_number      => '1.0',
                                     p_init_msg_list           => fnd_api.g_true,
                                     p_commit                  => fnd_api.g_false,
                                     p_return_status           => l_return_status,
                                     p_msg_count               => l_msg_count,
                                     p_msg_data                => l_msg_data,
                                     p_project_id              => projectid,
                                     p_task_id                 => taskid,
                                     p_as_of_date              => l_as_of_date,
                                     p_percent_complete        => 0,
                                     p_pm_product_code         => l_pm_product_code,
                                     p_task_status             => staustype,
                                     p_structure_type          => 'WORKPLAN'
                                    );

      IF l_return_status != 'S'
      THEN
         l_msg_data :=
            SUBSTR (fnd_msg_pub.get (fnd_msg_pub.g_first, fnd_api.g_false),
                    1,
                    3000
                   );
         l_msg_data := l_msg_data;
         DBMS_OUTPUT.put_line (   'L_Msg_Data='
                               || l_msg_data
                               || '  '
                               || l_return_status
                              );

         FOR i IN 1 .. l_msg_count
         LOOP
            l_msg_data :=
               SUBSTR (fnd_msg_pub.get (fnd_msg_pub.g_first, fnd_api.g_false),
                       1,
                       3000
                      );
            l_msg_data := l_msg_data || '-' || l_msg_data;
         END LOOP;

         errmsg := l_msg_data;
         DBMS_OUTPUT.put_line ('L_Msg_Data=' || l_msg_data);
      ELSIF l_return_status = 'S'
      THEN
         errmsg := l_return_status;
         DBMS_OUTPUT.put_line (   'L_Msg_Data='
                               || l_msg_data
                               || '  '
                               || l_return_status
                              );
         COMMIT;
      END IF;

DBMS_OUTPUT.put_line ('Ret STatus: ' || l_return_status||' Msg Cnt: '||l_msg_count||' Msg Data: '||L_Msg_Data);
--errMsg := 'test:'||l_msg_data;
   EXCEPTION
      WHEN OTHERS
      THEN
         errmsg := l_msg_data;                          --'ERROR IN PROCESS';
	          DBMS_OUTPUT.put_line ('Others ' || l_msg_data);
   END;
END OD_PA_PKG;
/
