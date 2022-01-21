create or replace
PACKAGE XX_PA_MASS_ADJST_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name:  XX_PA_MASS_ADJST_PKG                                                               |
  -- |  Description:  PA Mass Upload Tool to mass-update projects in oracle.                      |
  -- |  Rice ID : E3072                                                                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         27-Sep-2013   Archana N.        Initial version                                |
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.LOAD_TASKS_FOR_UPDATE                                 |
  -- |  Description: This procedure will load tasks from staging table to API composite           |
  -- |  variable.                                                                                 |
  -- =============================================================================================|
PROCEDURE LOAD_TASKS_FOR_UPDATE(p_project_number VARCHAR2,
    p_project_id         IN NUMBER ,
    pt_tasks_in          IN OUT NOCOPY pa_project_pub.task_in_tbl_type);
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.LOAD_KEYM_FOR_UPDATE                                           |
  -- |  Description: This procedure will load key members from staging table to API composite     |
  -- |  variable.                                                                                 |
  -- =============================================================================================|
PROCEDURE LOAD_KEYM_FOR_UPDATE(p_project_number VARCHAR2,
    p_project_id     IN NUMBER ,
    p_keym_in IN OUT NOCOPY pa_project_pub.project_role_tbl_type);
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.ASSIGN_ASSETS_FOR_UPDATE                                       |
  -- |  Description: This procedure will invoke add_asset_assignment API to assign assets to tasks|
  -- =============================================================================================|
PROCEDURE ASSIGN_ASSETS_FOR_UPDATE(p_project_number VARCHAR2,
      p_project_id NUMBER);
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.POPULATE_IDS                                                   |
  -- |  Description: This procedure will fetch project,task,project_asset and employee ids for    |
  -- |  each eligible project in the staging table.                                               |
  -- =============================================================================================|
PROCEDURE POPULATE_IDS(errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER);
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.UPDATE_PROJECT                                                 |
  -- |  Description: This procedure will invoke the update_project API and update projects and    |
  -- |  tasks in Oracle.                                                                          |
  -- =============================================================================================|
PROCEDURE UPDATE_PROJECT(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER);
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.EXTRACT                                                        |
  -- |  Description: This procedure will extract task,project information from Oracle for mass    |
  -- |  adjustments.                                                                              |
  -- =============================================================================================|
PROCEDURE EXTRACT(
    errbuff OUT NOCOPY VARCHAR2,
    retcode OUT NOCOPY NUMBER);
  -- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.PUBLISH_REPORT                                                 |
  -- |  Description: This procedure will extract report for mass adjustments done for in Oracle.  |
  -- =============================================================================================|
PROCEDURE PUBLISH_REPORT;
-- +============================================================================================+
  -- |  Name: XX_PA_MASS_ADJST_PKG.POPULATE_HIST_TABLE                                            |
  -- |  Description: This procedure will insert all records from staging table to history table.  |
  -- =============================================================================================|
PROCEDURE POPULATE_HIST_TABLE;
END XX_PA_MASS_ADJST_PKG;
/
