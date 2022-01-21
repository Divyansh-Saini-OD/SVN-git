-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name : XX_PA_KEYPROJ_MEM_V                                               |
-- | Description :  Create view to pull out data from SQL Server through      |                                                                      |
-- |                DB Link.                                                  | 
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author               Remarks                       |
-- |=======   ==========   =============        ==============================|
-- | V1.0     27-Apr-2007  Raj Patel            Initial version               |
-- |                                                                          |
-- +==========================================================================+

   SET SHOW         OFF
   SET VERIFY       OFF
   SET ECHO         OFF
   SET TAB          OFF
   SET FEEDBACK     ON

   CREATE VIEW xx_pa_keyproj_mem_v  AS SELECT  *  FROM  dbo.vw_Projs_EBS_PA_KEYMEMBERS@EJM.NA.ODCORP.NET;

   SHOW ERROR