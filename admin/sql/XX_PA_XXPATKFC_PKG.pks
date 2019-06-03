CREATE OR REPLACE PACKAGE APPS.XX_PA_XXPATKFC_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPATKFC_PKG                                |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       15-Feb-2010 Paddy Sanjeevi     Initial version           |
-- +===================================================================+
AS
 p_task1      VARCHAR2(100);
 p_task2      VARCHAR2(100);
 p_task3      VARCHAR2(100);
 p_task4      VARCHAR2(100);
 p_task5      VARCHAR2(100);
 p_division   VARCHAR2(100);
 p_di_merchant VARCHAR2(100);
 p_prj_mgr     VARCHAR2(100);
 p_tsk_mgr	VARCHAR2(100);
 p_dept		VARCHAR2(100);
 p_task_status	varchar2(100);
 p_start_date varchar2(100);
 p_end_date varchar2(100);

 p_tsk_where  VARCHAR2(3200);
 v_tsk_name  VARCHAR2(100);

 function BeforeReportTrigger return boolean;

END;
/
