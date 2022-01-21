-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                                                                          |
-- +==========================================================================+
-- | Name : XX_PA_PROJ_EJM_KEYM_V                                             |
-- | Description :SQL Script to create view.                                  |
-- |              Holds project manager, etc. from EJM system.                |
-- |              Cross references from HR_EMPLOYEES for employee_id          |
-- |              Indexed by PANEx.                                           |
-- |                                                                          |
-- | Change Record:                                                           |
-- | ===============                                                          |
-- | Version   Date          Author               Remarks                     |
-- | =======   ===========   =============        ============================|
-- | V1.0      01-Jan-2008   Daniel Ligas         Initial version             |
-- |                                                                          |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON


   CREATE OR REPLACE FORCE VIEW XX_PA_PROJ_EJM_KEYM_V
AS
SELECT "PANEx" panex, "Role" role, employee_id, "EmployeeID" employee_num
  FROM XX_PA_PROJ_EJM_KEYM E
       LEFT JOIN HR_EMPLOYEES H
         ON H.employee_num = to_char(E."EmployeeID");


   SHOW ERROR
