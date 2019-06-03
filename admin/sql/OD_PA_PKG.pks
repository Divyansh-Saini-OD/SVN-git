SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE OD_PA_PKG
AS
/*============================================================================+
|               Office Depot					              |
+=============================================================================+
|                                                                             |
| Program Name :  od_pa_pkg.pks                                               |
| Purpose      :  Package specification to update task and project statuses   |
|				                                              |
| Parameters   :  Project Id, Task Id.                                                       |
|                                                                             |
| Ver  Date       Name           Revision Description                         |
| ===  =========  ============== ===========================================  |
| 1.0  09-SEP-11  Suraj Charan   Original.                                    |
+=============================================================================*/
PROCEDURE OD_UPDATE_STATUS(PROJECTID IN NUMBER, TASKID IN NUMBER, STAUSTYPE IN VARCHAR2, ERRMSG  OUT VARCHAR2);
PROCEDURE OD_UPDATE_TASK_MANAGER_PERSON(p_projectid IN NUMBER, p_taskid IN NUMBER, p_taskmanagerpersonid IN NUMBER,p_sdate IN VARCHAR2, p_edate IN VARCHAR2, errMsg OUT VARCHAR2);

END OD_PA_PKG;
/

