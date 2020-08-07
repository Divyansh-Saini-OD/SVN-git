SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON
-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : UPDATE_MENU_PROMPT_CREATE_DOCUMENT                                    	   |
-- | Description : SQL Script is used to update Prompt NULL for Create Document Function      |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |V1.0 12-APR-2018   Jitendra Atale          table updates      |
-- +===========================================================================================+

update APPLSYS.FND_MENU_ENTRIES_VL 
set PROMPT=null
where menu_id=83670 and entry_sequence=11 and Prompt='Create Document';

commit;

Exit;