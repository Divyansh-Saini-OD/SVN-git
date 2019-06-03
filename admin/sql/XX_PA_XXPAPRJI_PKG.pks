CREATE OR REPLACE PACKAGE APPS.XX_PA_XXPAPRJI_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPAPRJI_PKG                                |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS

 FUNCTION get_proj_progress_status(p_proj_status IN VARCHAR2) return varchar2;
 FUNCTION get_issue_status(p_issue_status IN VARCHAR2) return varchar2;
 FUNCTION get_issue_progress_status(p_issue_progress_status IN VARCHAR2) return varchar2;
 FUNCTION get_task_member(p_user_id IN VARCHAR2) return varchar2;
 FUNCTION get_orig_forecast(p_project_id IN NUMBER) return NUMBER;
 FUNCTION get_rev_forecast(p_project_id IN NUMBER) return NUMBER;
 FUNCTION get_curr_forecast(p_project_id IN NUMBER) return NUMBER;
END;
/
