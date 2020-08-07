
-- +=========================================================================================+
-- |                        Office Depot - Project Simplify                                  |
-- |            Oracle NAIO/Office Depot/Consulting Organization                             |
-- +=========================================================================================+
-- | Name             : XXPOADDPOTYPEPOLICY.sql                                              |
-- | Description      : SQL Script to add policy on the tables                               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
-- |DRAFT 1A   20-JUN-2007       Vikas Raina      Initial draft version                      |
-- |DRAFT 1B                                      Changes as per RCL Id NNNN                 |
-- |1.0                                           Baselined after testing                    |
-- |1.1        29-JUN-2007       Lalitha Budithi  Commented the Update_check parameter       |
-- +=========================================================================================+

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE
-- ************************************************
-- Applying Policies
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
DBMS_OUTPUT.PUT_LINE(' Applying policy XX_PO_HEADER on PO_HEADERS_ALL Table');

--
-- Commented the Update_check and make use of the default value - False on 29-AUG-2007 Defect No#1213 -- Lalitha Budithi 
--
DBMS_RLS.add_policy
(object_schema   => 'APPS',
 object_name     => 'PO_HEADERS_ALL', 
 policy_name     => 'XX_PO_HEADER',
 policy_function => 'XX_PO_RESTRICT_POTYPE_PKG.PO_TYPE_HDR_PRED',
 statement_types => 'INSERT'
 -- update_check    =>  TRUE

 );

DBMS_OUTPUT.PUT_LINE('Added policy XX_PO_HEADER on PO_HEADERS_ALL Table');

EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(' Policy already exists ');
END;
/

-- *********************************************
-- Add policy for select
-- *********************************************

BEGIN
DBMS_RLS.add_policy
(object_schema   => 'APPS',
 object_name     => 'PO_HEADERS_ALL', 
 policy_name     => 'XX_PO_HEADER_SELECT',
 policy_function => 'XX_PO_RESTRICT_POTYPE_PKG.PO_TYPE_HDR_PRED',
 statement_types => 'SELECT'
 );

EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(' Policy already exists ');
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

BEGIN

DBMS_OUTPUT.PUT_LINE('Applying policy XX_DESCR_FLEX_CONTEXTS on FND_DESCR_FLEX_CONTEXTS Table');
 
DBMS_RLS.add_policy
(object_schema   => 'APPS',
 object_name     => 'FND_DESCR_FLEX_CONTEXTS',
 policy_name     => 'XX_DESCR_FLEX_CONTEXTS',
 policy_function => 'XX_PO_RESTRICT_POTYPE_PKG.PO_GET_POTYPE_PRED',
 statement_types => 'SELECT'
 );

DBMS_OUTPUT.PUT_LINE('Added policy XX_DESCR_FLEX_CONTEXTS on FND_DESCR_FLEX_CONTEXTS Table');

EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Policy XX_DESCR_FLEX_CONTEXTS does not exist');
END;
/

SET TERM ON
PROMPT
PROMPT VPD Policies applied successfully!!
PROMPT

SHOW ERRORS

EXIT;

-- ************************************
-- *          END OF SCRIPT           *
-- ************************************
