
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XXPODROPPOTYPEPOLICY.sql                                              |
-- | Description      : SQL Script to add policy on the tables                               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT      03-MAR-2008       Kalai Sulur      Initial version  	                     |
-- |											     |
-- |											     |
-- |											     |
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Drop Policies
-- ************************************************

BEGIN

DBMS_OUTPUT.PUT_LINE(' Dropping policy XX_PO_HEADER on PO_HEADERS_ALL Table');

 DBMS_RLS.drop_policy 
 (object_schema    => 'APPS', 
  object_name     => 'PO_HEADERS_ALL', 
  policy_name     => 'XX_PO_HEADER' ); 

DBMS_OUTPUT.PUT_LINE('Policy XX_PO_HEADER dropped');

EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(' Policy does not exist');
END;
/

-- ***************************************
-- Drop policy for select
-- ***************************************

 BEGIN 
  DBMS_RLS.drop_policy 
  (object_schema    => 'APPS', 
   object_name     => 'PO_HEADERS_ALL', 
   policy_name     => 'XX_PO_HEADER_SELECT' );  
 EXCEPTION
    WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE(' Policy does not exist');
 END;
/


BEGIN
 DBMS_RLS.drop_policy 
 (object_schema    => 'APPS', 
  object_name      => 'FND_DESCR_FLEX_CONTEXTS',
  policy_name      => 'XX_DESCR_FLEX_CONTEXTS' 
 ); 

DBMS_OUTPUT.PUT_LINE('Policy XX_DESCR_FLEX_CONTEXTS on XX_DESCR_FLEX_CONTEXTS table dropped');

EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Policy XX_DESCR_FLEX_CONTEXTS does not exist');
END;
/

SET TERM ON
PROMPT
PROMPT VPD Policies dropped successfully!!
PROMPT

SHOW ERRORS

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************

