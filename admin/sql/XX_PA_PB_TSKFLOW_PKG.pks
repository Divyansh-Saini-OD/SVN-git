CREATE OR REPLACE PACKAGE APPS.XX_PA_PB_TSKFLOW_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_PA_PB_TSKFLOW_PKG                               |
-- | Description :  OD Private Brand Reports                           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       11-Aug-2009 Paddy Sanjeevi     Initial version           |
-- |1.1       23-Dec-2009 Paddy Sanjeevi     Modified not initiate wf for parent task|
-- +===================================================================+
AS

FUNCTION get_party_id(p_emp IN VARCHAR2) RETURN NUMBER;

FUNCTION get_role(p_emp IN VARCHAR2,p_party_id IN NUMBER) RETURN VARCHAR2;


FUNCTION get_user_name(p_user_ID IN NUMBER) RETURN VARCHAR2;

PROCEDURE start_xxpatnot(p_project_id IN NUMBER);

FUNCTION get_notify_user(p_proj_id IN NUMBER,p_task_id IN NUMBER,p_task_manager_id IN NUMBER) RETURN VARCHAR2;

PROCEDURE IS_NOTIFY_EMAIL (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                );

PROCEDURE IS_TASK_STARTED (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                	  );

PROCEDURE IS_MGR_TO_BE_NOTIFIED (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                );

PROCEDURE IS_TASK_DUE (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
                );



PROCEDURE GET_TASK_STATUS  (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
	   		   );


PROCEDURE GET_TSK_FINISH_RECEIVER (
                                p_itemtype    IN         VARCHAR2
                               ,p_itemkey     IN         VARCHAR2
                               ,p_actid       IN         NUMBER
                               ,p_funcmode    IN         VARCHAR2
                               ,p_resultout   OUT NOCOPY VARCHAR2
				);

PROCEDURE ABORT_XXPATNOT(  x_errbuf               OUT NOCOPY VARCHAR2
		                ,x_retcode              OUT NOCOPY VARCHAR2
      			   	,p_project_no	        IN  VARCHAR2
				,p_recreate     IN VARCHAR2
			      );

END;
/
