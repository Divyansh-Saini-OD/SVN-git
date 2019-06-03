
-- +=========================================================================================+
-- | Name             : 
-- | Description      : SQL Script to add policy on the tables                               |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version    Date              Author           Remarks                                    |
-- |=======    ==========        =============    ========================                   |
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
 policy_function => 'XX_PO_RESTRICT_POTYPE_PKG.PO_TYPE_HDR_PRED'
-- statement_types => 'INSERT'
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
 policy_function => 'XX_PO_RESTRICT_POTYPE_PKG.PO_TYPE_HDR_PRED'
 --statement_types => 'SELECT'
 );

EXCEPTION
   WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(' Policy already exists ');
END;
/
