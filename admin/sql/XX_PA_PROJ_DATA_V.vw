-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name : XX_PA_PROJ_DATA__V                                                |
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

   CREATE VIEW xx_pa_proj_data_v AS  SELECT  *  FROM  WS_Projs_EBS_PA@EJM.NA.ODCORP.NET;

   SHOW ERROR