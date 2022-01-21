create or replace
PACKAGE XX_PA_ACC_GEN_WF_PKG AUTHID CURRENT_USER AS



----------------------------------------------------------------------------------
-- API Name	: XX_PA_ACC_GEN_WF_PKG.GET_PROJECT_TYPE_CLASS_CODE
--
-- API Type	: Procedure
--
-- Type		: Public
--
-- Pre-reqs	: None
--
-- Function	: This API is attached to a Workflow function for account
-- generation for Project related POs and Requisitions. It sets the
-- XX_PROJ_TYPE_CLASS_CODE attribute based on the PROJECT_TYPE attribute
-- by looking it up in PA_PROJECT_TYPES_ALL
--
-- Parameters	:
--		p_itemtype		IN  VARCHAR2	Required
--		p_itemkey			IN  VARCHAR2	Required
--		p_actid				IN  NUMBER	  Required
--		p_funcmode 		IN  VARCHAR2	Required
--		x_result			OUT VARCHAR2
----------------------------------------------------------------------------------

PROCEDURE GET_PROJECT_TYPE_CLASS_CODE (
		p_itemtype IN  VARCHAR2,
		p_itemkey	 IN  VARCHAR2,
		p_actid		 IN  NUMBER,
		p_funcmode IN  VARCHAR2,
		x_result	 OUT NOCOPY VARCHAR2);



----------------------------------------------------------------------------------
-- API Name	: XX_PA_ACC_GEN_WF_PKG.PA_LOCATION_LOOKUP
--
-- API Type	: Procedure
--
-- Type		: Public
--
-- Pre-reqs	: None
--
-- Function	: This API is attached to a Workflow function for account
-- generation for Project related POs and Requisitions.
--
-- Parameters	:
--		p_itemtype		IN  VARCHAR2	Required
--		p_itemkey			IN  VARCHAR2	Required
--		p_actid				IN  NUMBER	  Required
--		p_funcmode 		IN  VARCHAR2	Required
--		x_result			OUT VARCHAR2
----------------------------------------------------------------------------------

PROCEDURE PA_LOCATION_LOOKUP (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	  IN  VARCHAR2,
		p_actid		  IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	  OUT NOCOPY VARCHAR2);


----------------------------------------------------------------------------------
-- API Name	: XX_PA_ACC_GEN_WF_PKG.ASSIGN_TEXT_TO_NUMBER_ATT
--
-- API Type	: Procedure
--
-- Type		: Public
--
-- Pre-reqs	: None
--
-- Function	: Similar to standard Assign, but converts text to number
--
-- IN
--   itemtype  - item type
--   itemkey   - item key
--   actid     - process activity instance id
--   funcmode  - execution mode
-- OUT
--   result    - 'NULL'
-- ACTIVITY ATTRIBUTES REFERENCED
--   ATTR         - Item attribute to set
--   TEXT_VALUE   - text value
----------------------------------------------------------------------------------
PROCEDURE ASSIGN_TEXT_TO_NUMBER_ATT(
   p_itemtype  IN  VARCHAR2,
   p_itemkey   IN  VARCHAR2,
   p_actid     IN  NUMBER,
   p_funcmode  IN  VARCHAR2,
   x_resultout OUT NOCOPY VARCHAR2);
   
PROCEDURE IS_AA_DIFF_FOR_PO_TYPE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2);  

PROCEDURE IS_VA_DIFF_FOR_PO_TYPE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2); 		

PROCEDURE IS_LOB_OVERWRITE (
		p_itemtype	IN  VARCHAR2,
		p_itemkey	IN  VARCHAR2,
		p_actid		IN  NUMBER,
		p_funcmode	IN  VARCHAR2,
		x_result	OUT nocopy VARCHAR2); 	
END XX_PA_ACC_GEN_WF_PKG;
/
