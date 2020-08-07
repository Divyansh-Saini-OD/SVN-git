-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name : APPS.XX_CE_AJB99X_DROP_T.sql                                      |
-- | Description : Drop Triggers 			                      |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author        Remarks                              |
-- |=======   ==========   ============= =====================================|
-- | v1.0     23-Jul-2008  D. Gowda      Defect 7926 - Drop triggers due to   |
-- |					 Performance updates- Derive trigger  |
-- |                                     values during PreProcessjoin 	      |
-- |									      |
-- +==========================================================================+

DROP TRIGGER xx_ce_ajb996_t;
DROP TRIGGER xx_ce_ajb998_t;
DROP TRIGGER xx_ce_ajb999_t;

