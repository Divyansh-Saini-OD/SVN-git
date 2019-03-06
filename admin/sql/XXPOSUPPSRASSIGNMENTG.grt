-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XXPOSUPPSRASSIGNMENTG.grt                           |
-- | Rice ID      :I1095_SupplierSourcingAssignments                   |
-- | Description  :OD Supplier Sourcing Assignments Grant Creation     |
-- |               Script                                              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-APR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.1      04-MAY-2007  Hema Chikkanna   Created Indvidual scripts as|
-- |                                       per onsite requirement      |
-- |1.2      19-JUN-2007  Hema Chikkanna   Incorporated the changes to |
-- |                                       file name as per the new    |
-- |                                       MD40 document               |
-- |                                                                   |
-- +===================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF


PROMPT
PROMPT Providing Grant on Custom Table to Apps......
PROMPT


WHENEVER SQLERROR EXIT 1


PROMPT
PROMPT Providing Grant on the Table XX_PO_SUPP_SR_ASSIGNMENT to Apps .....
PROMPT


GRANT ALL ON  XXOM.XX_PO_SUPP_SR_ASSIGNMENT TO APPS;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

