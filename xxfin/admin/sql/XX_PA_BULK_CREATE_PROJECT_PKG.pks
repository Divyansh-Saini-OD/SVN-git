CREATE OR REPLACE
PACKAGE XX_PA_BULK_CREATE_PROJECT_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot - Project Simplify                                                           |
  -- |                                                                                            |
  -- +============================================================================================+
  -- |  Name:  XX_PA_BULK_CREATE_PROJECT_PKG                                                      |
  -- |  Description:  PA Mass Upload Tool to bulk create projects in oracle.                      |
  -- |  Rice ID : E3067                                                                           |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         26-Aug-2013   Archana N.        Initial version                                |
  -- | 1.1         16-Oct-2018   Jitendra A.       Added FETCH_DATA procedure                     |
  -- | 1.1         19-Oct-2018   Priyam P          Added function remove_spcl_char
  -- +============================================================================================+
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.LOAD_TASKS                                            |
  -- |  Description: This procedure will extract tasks for the project based on the template      |
  -- |  provided                                                                                  |
  -- =============================================================================================|
  PROCEDURE LOAD_TASKS(
      p_project_in         IN XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE ,
      p_parent_task_id     IN NUMBER ,
      p_parent_task_number IN VARCHAR2 ,
      pt_tasks_in          IN OUT NOCOPY pa_project_pub.task_in_tbl_type ,
      p_template_id        IN NUMBER ,
      p_proj_org_id        IN NUMBER );
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.ASSIGN_ASSETS                                         |
  -- |  Description: This procedure will add asset assignments to the new project created based   |
  -- |  on the template provided.                                                                 |
  -- =============================================================================================|
  PROCEDURE ASSIGN_ASSETS(
      p_project_in  IN XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE ,
      p_project_id  IN NUMBER ,
      p_template_id IN NUMBER );
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.CREATE_BUDGET                                         |
  -- |  Description: This procedure will create draft and baseline budgets for the new project    |
  -- |  created.                                                                                  |
  -- =============================================================================================|
  PROCEDURE CREATE_BUDGET(
      p_project_id IN NUMBER ,
      p_project_in IN XX_PA_BULK_CREATE_PRJ_STG%ROWTYPE );
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.PUBLISH_REPORT                                        |
  -- |  Description: This pkg.procedure will invoke the publisher program to publish the report in|
  -- |               Excel format.                                                                |
  -- =============================================================================================|
  PROCEDURE Publish_Report;
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.FETCH_DATA                                            |
  -- |  Description: This pkg.procedure will insert the excel data in to staging table          - |
  -- |               XX_PA_BULK_CREATE_PRJ_STG.                                                   |
  -- =============================================================================================|
  PROCEDURE FETCH_DATA(
      P_PAN                 VARCHAR2,
      P_PROJECT_EXTENSION   VARCHAR2,
      P_PROJECT_START_DATE  DATE,
      P_PROJECT_END_DATE    DATE,
      P_PROJECT_NAME        VARCHAR2,
      P_PROJECT_LONG_NAME   VARCHAR2,
      P_PROJECT_DESCRIPTION VARCHAR2,
      P_ADD_TO_DESC         VARCHAR2,
      P_PROJECT_MANAGER     VARCHAR2,
      P_TEMPLATE_NAME       VARCHAR2,
      P_PROJECT_LOCATION    VARCHAR2,
      P_PROJECT_ORG         VARCHAR2,
      P_CAPITAL_BUDGET      NUMBER,
      P_EXPENSE_BUDGET      NUMBER,
      P_COUNTRY             VARCHAR2,
      P_CURRENCY_CODE       VARCHAR2 DEFAULT 'USD',
      P_PROJECT_NUMBER      VARCHAR2 DEFAULT NULL,
      P_STATUS              VARCHAR2 DEFAULT 'I',
      P_STATUS_CODE         VARCHAR2 DEFAULT NULL,
      P_CONC_REQ_ID         NUMBER DEFAULT NULL,
      P_STATUS_MESG         VARCHAR2 DEFAULT NULL,
      P_ATTRIBUTE1          VARCHAR2 DEFAULT NULL,
      P_ATTRIBUTE2          VARCHAR2 DEFAULT NULL,
      P_ATTRIBUTE3          VARCHAR2 DEFAULT NULL,
      P_ATTRIBUTE4          VARCHAR2 DEFAULT NULL,
      P_ATTRIBUTE5          VARCHAR2 DEFAULT NULL,
      P_CREATION_DATE       DATE DEFAULT SYSDATE,
      P_CREATED_BY          NUMBER DEFAULT fnd_global.user_id,
      P_LAST_UPDATE_DATE    DATE DEFAULT SYSDATE,
      P_LAST_UPDATED_BY     NUMBER DEFAULT fnd_global.user_id,
      P_Last_Update_Login   NUMBER DEFAULT Fnd_Global.User_Id,
      P_error_mesg OUT VARCHAR2 ,
      P_Flag OUT NUMBER);
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.FIND_SPCL_CHAR                                            |
  -- |  Description: This pkg.procedure will find special characters          - |
  -- |               XX_PA_BULK_CREATE_PRJ_STG.                                                   |
  -- =============================================================================================
  FUNCTION FIND_SPCL_CHAR(
      P_DATA_ELEMENT IN VARCHAR2)
    RETURN NUMBER;
  -- +============================================================================================+
  -- |  Name: XX_PA_BULK_CREATE_PROJECT_PKG.XX_MAIN                                               |
  -- |  Description: This procedure will invoke the create_project API and create projects in     |
  -- |  Oracle.                                                                                   |
  -- =============================================================================================|
  PROCEDURE XX_MAIN(
      errbuff OUT NOCOPY VARCHAR2,
      retcode OUT NOCOPY NUMBER);
END XX_PA_BULK_CREATE_PROJECT_PKG;
/
SHOW ERRORS;
EXIT;