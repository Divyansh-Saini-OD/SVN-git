CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_XXPATTSK_PKG
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
 FUNCTION BeforeReportTrigger return boolean is
 BEGIN
   IF p_tsk_name IS NULL THEN
      p_tskwhere:=' and 1=1';
   ELSE
      v_tsk_name:=p_tsk_name||'%';
      p_tskwhere:=' and tsk.element_name LIKE '||''''||v_tsk_name||'''';
   END IF;

   IF p_division IS NULL THEN
      p_divwhere:=' and 1=1';
   ELSE
      v_division:=p_division||'%';
      p_divwhere:=' and EEB1.C_EXT_ATTR5 LIKE '||''''||v_division||'''';
   END IF;

    IF (      p_tsk_res IS NULL
     and  p_tsk_res1 IS NULL
     and  p_tsk_res2 IS NULL
     and  p_tsk_res3 IS NULL
     and  p_tsk_res4 IS NULL
     and  p_tsk_res5 IS NULL
      )  THEN
      p_reswhere:=' and 1=1';
   END IF;
   IF p_tsk_res IS NOT NULL THEN
      v_lres:=','||p_tsk_res;
   END IF;
   IF p_tsk_res1 IS NOT NULL THEN
      v_lres:=v_lres||','||p_tsk_res1;
   END IF;
   IF p_tsk_res2 IS NOT NULL THEN
      v_lres:=v_lres||','||p_tsk_res2;
   END IF;
   IF p_tsk_res3 IS NOT NULL THEN
      v_lres:=v_lres||','||p_tsk_res3;
   END IF;
   IF p_tsk_res4 IS NOT NULL THEN
      v_lres:=v_lres||','||p_tsk_res4;
   END IF;
   IF p_tsk_res5 IS NOT NULL THEN
      v_lres:=v_lres||','||p_tsk_res5;
   END IF;
   IF v_lres IS NOT NULL THEN
      p_reswhere:=' and tsk.task_manager_id IN (0'||v_lres||')';
   ELSE
      p_reswhere:=' and 1=1';
   END IF;


   IF p_dept IS NULL THEN
      p_deptwhere:=' and 1=1';
   ELSE
      v_dept:=p_dept||'%';
      p_deptwhere:=' and EEB1.C_EXT_ATTR1 LIKE '||''''||v_dept||'''';
   END IF;
   RETURN(TRUE);    
 END;
END;
/
