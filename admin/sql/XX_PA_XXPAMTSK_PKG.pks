CREATE OR REPLACE PACKAGE APPS.XX_PA_XXPAMTSK_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPAMTSK_PKG                                |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS
 p_tsk_name VARCHAR2(200);
 p_division VARCHAR2(200);
 p_dept     VARCHAR2(200);

 p_deptwhere varchar2(3200);
 p_divwhere varchar2(3200);
 p_tskwhere varchar2(3200);

 v_tsk_name VARCHAR2(200);
 v_dept     VARCHAR2(200);
 v_division VARCHAR2(200);

 function BeforeReportTrigger return boolean;

 function get_pred_description(p_project_id IN NUMBER,p_task_id IN NUMBER) return varchar2;

END;
/
