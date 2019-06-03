CREATE OR REPLACE PACKAGE APPS.XX_PA_XXPATTSK_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_XXAPATTSK_PKG                                |
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
 p_tsk_res  VARCHAR2(10);
 p_tsk_res1  VARCHAR2(10);
 p_tsk_res2  VARCHAR2(10);
 p_tsk_res3  VARCHAR2(10);
 p_tsk_res4  VARCHAR2(10);
 p_tsk_res5  VARCHAR2(10);
 p_res       VARCHAR2(35);
 p_res1      VARCHAR2(35);
 p_res2      VARCHAR2(35);
 p_res3      VARCHAR2(35);
 p_res4      VARCHAR2(35);
 p_res5      VARCHAR2(35);


 p_deptwhere varchar2(3200);
 p_divwhere varchar2(3200);
 p_tskwhere varchar2(3200);
 p_reswhere VARCHAR2(3200);

 v_tsk_name VARCHAR2(200);
 v_dept     VARCHAR2(200);
 v_division VARCHAR2(200);
 v_lres      VARCHAR2(200);

 function BeforeReportTrigger return boolean;

END;
/
