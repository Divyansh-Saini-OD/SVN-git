-- +============================================================================+
-- | Office Depot - Project Simplify                                            |
-- | Providge Consulting                                                        |
-- +============================================================================+
-- | SQL Script to alter table:  XX_CE_AJB998                                   |
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

--Script to enable / gather histograms:

  Exec fnd_stats.LOAD_HISTOGRAM_COLS('INSERT', 20043, 'XX_CE_AJB998', 'STATUS_1310');



