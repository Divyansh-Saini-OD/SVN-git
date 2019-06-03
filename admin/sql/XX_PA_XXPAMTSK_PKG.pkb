CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_XXPAMTSK_PKG
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
 
 FUNCTION get_pred_description(p_project_id IN NUMBER, p_task_id IN NUMBER) RETURN VARCHAR2
 IS
 v_description VARCHAR2(250);
 BEGIN
   select b.description 
     INTO v_description
     from apps.pa_percent_completes b,
          apps.pa_proj_elements a
    where b.task_id=a.proj_element_id
      and b.project_id=a.project_id
      and b.current_flag='Y' and a.project_id=p_project_id
      and a.proj_element_id=p_task_id
      and b.object_type='PA_TASKS';
    RETURN(v_description);
 EXCEPTION
   WHEN others THEN
     v_description:=NULL;
     RETURN(v_description);
 END get_pred_description;
 

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
