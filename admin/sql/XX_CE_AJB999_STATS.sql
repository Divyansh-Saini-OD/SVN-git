-- +============================================================================+
-- | Office Depot - Project Simplify                                            |
-- | Providge Consulting                                                        |
-- +============================================================================+
-- | SQL Script to alter table:  XX_CE_AJB999                                   |
-- |                                                                            |
-- |Change Record:                                                              |
-- |===============                                                             |
-- |Version   Date          Author         Remarks                              |
-- |=======   ===========   =============  =====================================|
-- |1.0       20-JAN-2010   Vinaykumar S   Defect 2610                          |
-- |                                                                            |
-- +============================================================================+

  SET SHOW         OFF
  SET VERIFY       OFF
  SET ECHO         OFF
  SET TAB          OFF
  SET FEEDBACK     ON

--Script to gather Stats:

  Exec fnd_stats.Gather_table_stats('XXFIN', 'XX_CE_AJB999', PERCENT=>'10', DEGREE=>'4');


/