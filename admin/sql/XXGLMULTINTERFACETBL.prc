-- +==================================================================================+
-- |                       Office Depot - Project Simplify                            |
-- |                                                                                  |
-- +==================================================================================+
-- | SQL Script to create the sequence:  XXGLMULTIINTERFACETBL.sql                    |
-- |                                                                                  |
-- |  For I0985_GL_Interface - Interface and Utility Package Development              |
-- |  This script will create the XX_GL_INTERFACE_NA table in the GL schema needed    |
-- |  for the multi table GL import process. See GL users guide for info              |
-- |                                                                                  |
-- |Change Record:                                                                    |
-- |===============                                                                   |
-- |Version   Date          Author               Remarks                              |
-- |=======   ===========   =============        =====================================|
-- |1.0       6-AUG-2007     P. MArco             Initial version                     |
-- |                                                                                  |
-- +==================================================================================+



EXEC   APPS.GL_JOURNAL_IMPORT_PKG.CREATE_TABLE('XX_GL_INTERFACE_NA');


/








