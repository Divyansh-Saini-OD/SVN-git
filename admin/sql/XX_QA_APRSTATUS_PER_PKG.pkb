SET SHOW      OFF;
SET VERIFY    OFF;
SET ECHO      OFF;
SET TAB       OFF;
SET FEEDBACK  OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_QA_APRSTATUS_PER_PKG
AS 
-- +==============================================================================+
-- |                  Office Depot - Project Simplify                             |
-- +==============================================================================+
-- | Name       : XX_QA_APRSTATUS_PER_PKG                                         |
-- | Description: This package checks if the user has the ability to approve the  |
-- |              collection plan 						  |
-- |                                                                              |
-- |Change Record:                                                                |
-- |==============                                                                |
-- |Version   Date         Author           Remarks                               |
-- |=======   ==========   ===============  ======================================|
-- |1.0       04-MAR-2009  Paddy Sanjeevi   Initial version                       |
-- |1.1       04-OCT-2010  Rama Dwibhashyam Changed group name to QA MANAGER      |
-- +==============================================================================+

FUNCTION IS_ELIGIBLE_TO_APPROVE RETURN VARCHAR2
-- +==================================================================================================================+
-- |                                                                                                                  |
-- | Name             : IS_ELIGIBLE_TO_APPROVE                                                                        |
-- |                                                                                                                  |
-- | Description      : This functon checks if the logged user have been set up in Manager User group                 |
-- |                    If it is set up returns 'Y' else it returns 'N'.                                              |
-- |                                                                                                                  |
-- | Parameters       : 											      |
-- +==================================================================================================================+

IS 

ln_cnt NUMBER := 0;

BEGIN
  SELECT COUNT(1)
    INTO ln_cnt
    FROM qa_user_group_v
   WHERE group_name='QA MANAGER'
     AND user_id=fnd_global.user_id
     AND status='A';
  IF ln_cnt<>0 THEN
     RETURN 'Y';
  ELSE
     RETURN 'N';
  END IF;

EXCEPTION

WHEN OTHERS THEN
  RETURN 'Y';
END IS_ELIGIBLE_TO_APPROVE;

END XX_QA_APRSTATUS_PER_PKG;
/

SHOW ERRORS;

EXIT;