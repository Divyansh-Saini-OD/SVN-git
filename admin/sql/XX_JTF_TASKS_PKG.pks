SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_JTF_TASKS_PKG
-- +=======================================================================+
-- |                  Office Depot - Project Simplify                      |
-- |                 Oracle NAIO Consulting Organization                   |
-- +=======================================================================+
-- | Name        : XX_JTF_TASKS_PKG                                        |
-- | Description : Package to create Tasks, Task References, Task          |
-- |               Assignments, Task Dependencies and Task Recurrences     |
-- |                                                                       |
-- |Change Record:                                                         |
-- |===============                                                        |
-- |Version     Date           Author               Remarks                |
-- |=======    ==========      ================     =======================|
-- |1.0        17-Sept-2007    Bibhubrata Jena                             |
-- +=======================================================================+

AS

----------------------------
--Declaring Global Variables
----------------------------

    g_errbuf                         VARCHAR2(2000);
    g_conv_id                        NUMBER;
    g_record_control_id              NUMBER;
    g_source_system_code             VARCHAR2(240);
    g_orig_sys_ref                   VARCHAR2(240);
    g_procedure_name                 VARCHAR2(250);
    g_staging_table_name             VARCHAR2(250);
    g_staging_column_name            VARCHAR2(32);
    g_staging_column_value           VARCHAR2(500);
    g_batch_id                       NUMBER;
-- +===================================================================+
-- | Name        : create_tasks_main                                   |
-- | Description : Main procedure to be called from the concurrent     |
-- |               program 'OD: JTF Task Creation Program'             |
-- | Parameters  : p_batch_id_from,p_batch_id_to                       |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_tasks_main
    (
         x_errbuf                   OUT NOCOPY  VARCHAR2
        ,x_retcode                  OUT NOCOPY  VARCHAR2
        ,p_batch_id_from            IN          NUMBER
        ,p_batch_id_to              IN          NUMBER
    );

-- +===================================================================+
-- | Name        : create_task                                         |
-- | Description : Procedure to create a new task                      |
-- |                                                                   |
-- | Parameters  : l_jtf_tasks_int                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task
    (
         l_jtf_tasks_int            IN          XX_JTF_IMP_TASKS_INT%ROWTYPE
        ,x_tasks_return_status      OUT NOCOPY  VARCHAR2
    );

-- +===================================================================+
-- | Name        : create_task_references                              |
-- | Description : Procedure to create, update and delete              |
-- |               a task reference                                    |
-- | Parameters  : l_jtf_task_refs_int                                 |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_references
    (
        l_jtf_task_refs_int         IN          XX_JTF_IMP_TASK_REFS_INT%ROWTYPE
       ,x_task_refs_return_status   OUT NOCOPY  VARCHAR2
    );

-- +===================================================================+
-- | Name        : create_task_assignment                              |
-- | Description : Procedure to create, update and delete              |
-- |               a task assignment                                   |
-- | Parameters  : l_jtf_task_assgn_int                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_assignment
    (
        l_jtf_task_assgn_int        IN          XX_JTF_IMP_TASK_ASSGN_INT%ROWTYPE
       ,x_task_assgn_ret_status     OUT NOCOPY  VARCHAR2
    );

-- +===================================================================+
-- | Name        : create_task_dependency                              |
-- | Description : Procedure to create, update and delete              |
-- |               a task dependency                                   |
-- | Parameters  : l_jtf_tasks_depend_int                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_dependency
    (
        l_jtf_tasks_depend_int      IN          XX_JTF_IMP_TASKS_DEPEND_INT%ROWTYPE
       ,x_task_depend_ret_status    OUT NOCOPY  VARCHAR2
    );

-- +===================================================================+
-- | Name        : create_task_recurrence                              |
-- | Description : Procedure to create and update a task recurrence    |
-- |                                                                   |
-- | Parameters  : l_jtf_tasks_recur_int                               |
-- |                                                                   |
-- +===================================================================+
PROCEDURE create_task_recurrence
    (
        l_jtf_tasks_recur_int       IN          XX_JTF_IMP_TASK_RECUR_INT%ROWTYPE
       ,x_tasks_recur_return_status OUT NOCOPY  VARCHAR2
    );

-- +===================================================================+
-- | Name        : Get_task_recurrence_id                              |
-- |                                                                   |
-- | Description : Procedure used to get task_recurrence_id            |
-- |                                                                   |
-- | Parameters  : p_task_recur_orig_sys_ref                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_recurrence_id
    (
         p_task_recur_orig_sys_ref    IN          VARCHAR2
        ,x_task_recur_id              OUT NOCOPY  NUMBER
        ,x_obj_ver_num                OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_dependency_id                              |
-- |                                                                   |
-- | Description : Procedure used to get task_dependency_id            |
-- |                                                                   |
-- | Parameters  : p_task_dpnd_orig_sys_ref                            |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_dependency_id
    (
         p_task_dpnd_orig_sys_ref   IN          VARCHAR2
        ,x_task_dpnd_id             OUT NOCOPY  NUMBER
        ,x_obj_ver_num              OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_assignment_id                              |
-- |                                                                   |
-- | Description : Procedure used to get task_id                       |
-- |                                                                   |
-- | Parameters  : p_task_assign_orig_sys_ref                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_assignment_id
    (
         p_task_assign_orig_sys_ref   IN          VARCHAR2
        ,x_task_assign_id             OUT NOCOPY  NUMBER
        ,x_obj_ver_num                OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_assign_status_id                                |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_status_id from  |
-- |               the task_status_name                                |
-- | Parameters  : p_assign_status_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_assign_status_id
    (
         p_assign_status_name              IN          VARCHAR2
        ,x_assign_status_id                OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_reference_id                               |
-- |                                                                   |
-- | Description : Procedure used to get task_id                       |
-- |                                                                   |
-- | Parameters  : p_task_ref_orig_sys_ref                             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_reference_id
    (
         p_task_ref_orig_sys_ref     IN          VARCHAR2
        ,x_task_ref_id               OUT NOCOPY  NUMBER
        ,x_obj_ver_num               OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_object_id                                       |
-- | Description : Procedure used to get object_id for task reference  |
-- |                                                                   |
-- | Parameters  : p_task_orig_system_ref                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_object_id
    (
         p_object_type_code         IN          VARCHAR2
        ,p_object_orig_system_ref   IN          VARCHAR2
        ,x_object_name              OUT NOCOPY  VARCHAR2
        ,x_object_id                OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_id                                         |
-- | Description : Procedure used to get task_id                       |
-- |                                                                   |
-- | Parameters  : p_task_orig_system_ref                              |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_id
    (
         p_task_orig_system_ref     IN          VARCHAR2
        ,x_task_id                  OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_customer_id                                     |
-- | Description : Procedure used to get customer_id                   |
-- |                                                                   |
-- | Parameters  : p_source_object_code,p_object_source_id             |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_customer_id
    (
         p_source_object_code       IN          VARCHAR2
        ,p_object_source_id         IN          NUMBER
        ,x_customer_id              OUT NOCOPY  NUMBER
        ,x_address_id               OUT NOCOPY  NUMBER
        ,x_account_id               OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_object_source_id                                |
-- | Description : Procedure used to get object_source_id              |
-- |                                                                   |
-- | Parameters  : p_source_object_code,p_source_object_orig_system_ref|
-- |               p_source_object_orig_sys                            |
-- +===================================================================+
PROCEDURE Get_object_source_id
    (
         p_source_object_code            IN          VARCHAR2
        ,p_source_object_orig_sys_ref    IN          VARCHAR2
        ,p_source_object_orig_sys        IN          VARCHAR2
        ,x_object_source_id              OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_type_id                                    |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_type_id from the|
-- |               task_type_name                                      |
-- | Parameters  : p_task_type_name                                    |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_type_id
    (
         p_task_type_name                IN          VARCHAR2
        ,x_task_type_id                  OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_status_id                                  |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_status_id from  |
-- |               the task_status_name                                |
-- | Parameters  : p_task_status_name                                  |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_status_id
    (
         p_task_status_name              IN          VARCHAR2
        ,x_task_status_id                OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_task_priority_id                                |
-- |                                                                   |
-- | Description : Procedure used to retrieve the task_priority_id from|
-- |               the task_priority_name                              |
-- | Parameters  : p_task_priority_name                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_priority_id
    (
         p_task_priority_name         IN          VARCHAR2
        ,x_task_priority_id           OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_timezone_id                                     |
-- |                                                                   |
-- | Description : Procedure used to retrieve the timezone_id from     |
-- |               timezone_name                                       |
-- | Parameters  : p_timezone_name                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_timezone_id
    (
         p_timezone_name                IN          VARCHAR2
        ,x_timezone_id                  OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : Get_resource_id                                     |
-- |                                                                   |
-- | Description : Procedure used to retrieve the resource_id of the   |
-- |               Owner/Assignee of a Task                            |
-- | Parameters  : p_resource_orig_system_ref                          |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_resource_id
    (
         p_resource_orig_system_ref     IN          VARCHAR2
        ,x_resource_id                  OUT NOCOPY  NUMBER
        ,x_user_id                      OUT NOCOPY  NUMBER
        ,x_own_type_code                   OUT NOCOPY VARCHAR2
    );

-- +===================================================================+
-- | Name        : Get_task_obj_ver_num                                |
-- | Description : Procedure used to get the object_version_number for |
-- |               task                                                |
-- |                                                                   |
-- | Parameters  : p_task_id                                           |
-- |                                                                   |
-- +===================================================================+
PROCEDURE Get_task_obj_ver_num
    (
        p_task_id               IN          VARCHAR2
       ,x_obj_ver_num           OUT NOCOPY  NUMBER
    );

-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- | Description : Procedure used to store the count of records that   |
-- |               are processed/failed/succeeded                      |
-- |                                                                   |
-- | Parameters  : p_debug_msg                                         |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
    (
         p_debug_msg  IN  VARCHAR2
    );

-- +===================================================================+
-- | Name        : log_exception                                       |
-- | Description : This procedure is used for logging exceptions into  |
-- |               conversion common elements tables.                  |
-- |                                                                   |
-- | Parameters  : p_conversion_id,p_record_control_id,p_procedure_name|
-- |               p_batch_id,p_exception_log,p_oracle_error_msg       |
-- +===================================================================+
PROCEDURE log_exception
    (
         p_conversion_id          IN NUMBER
        ,p_record_control_id      IN NUMBER
        ,p_source_system_code     IN VARCHAR2
        ,p_source_system_ref      IN VARCHAR2
        ,p_procedure_name         IN VARCHAR2
        ,p_staging_table_name     IN VARCHAR2
        ,p_staging_column_name    IN VARCHAR2
        ,p_staging_column_value   IN VARCHAR2
        ,p_batch_id               IN NUMBER
        ,p_exception_log          IN VARCHAR2
        ,p_oracle_error_code      IN VARCHAR2
        ,p_oracle_error_msg       IN VARCHAR2
        ,p_msg_severity           IN VARCHAR2        
    );
END XX_JTF_TASKS_PKG;
/
SHOW ERRORS;