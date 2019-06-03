CREATE OR REPLACE PACKAGE BODY APPS.XX_PA_XXPATKFC_PKG
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
 FUNCTION BeforeReportTrigger return boolean is
 BEGIN

   IF (p_task1 IS NULL AND p_task2 IS NULL AND p_task3 IS NULL AND p_task4 IS NULL AND p_task5 IS NULL) THEN
       p_tsk_where:=' and 1=1 ';
   ELSE
     IF p_task1 IS NOT NULL THEN
        v_tsk_name:=p_task1||'%';
        p_tsk_where:=p_tsk_where||' tsk.element_name LIKE '||''''||v_tsk_name||'''';
     END IF;
     IF p_task2 IS NOT NULL THEN
        v_tsk_name:=p_task2||'%';
	IF p_tsk_where IS NOT NULL THEN
           p_tsk_where:=p_tsk_where||' or tsk.element_name LIKE '||''''||v_tsk_name||'''';
	ELSE
           p_tsk_where:=p_tsk_where||' tsk.element_name LIKE '||''''||v_tsk_name||'''';
	END IF;
     END IF;
     IF p_task3 IS NOT NULL THEN
        v_tsk_name:=p_task3||'%';
	IF p_tsk_where IS NOT NULL THEN
           p_tsk_where:=p_tsk_where||' or tsk.element_name LIKE '||''''||v_tsk_name||'''';
	ELSE
           p_tsk_where:=p_tsk_where||' tsk.element_name LIKE '||''''||v_tsk_name||'''';
	END IF;
     END IF;
     IF p_task4 IS NOT NULL THEN
        v_tsk_name:=p_task4||'%';
	IF p_tsk_where IS NOT NULL THEN
           p_tsk_where:=p_tsk_where||' or tsk.element_name LIKE '||''''||v_tsk_name||'''';
	ELSE
           p_tsk_where:=p_tsk_where||' tsk.element_name LIKE '||''''||v_tsk_name||'''';
	END IF;
     END IF;
     IF p_task5 IS NOT NULL THEN
        v_tsk_name:=p_task5||'%';
	IF p_tsk_where IS NOT NULL THEN
           p_tsk_where:=p_tsk_where||' or tsk.element_name LIKE '||''''||v_tsk_name||'''';
	ELSE
           p_tsk_where:=p_tsk_where||' tsk.element_name LIKE '||''''||v_tsk_name||'''';
	END IF;
     END IF;
     p_tsk_where:=' and ( '||p_tsk_where||' ) ';
   END IF;
   RETURN(TRUE);    
 END;
END;
/



