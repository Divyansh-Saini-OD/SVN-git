-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                         WIPRO Technologies                               |
-- +==========================================================================+
---|  Application    :   GL                                                   |
---|                                                                          |
---|  Name           :   XX_GL_INTERFACE_HIGH_VOL_NA.sql                      |
---|                                                                          |
---|  Description    :   This script creates XX_GL_INTERFACE_HIGH_VOL_NA table|
---|                     by calling gl_journal_import_pkg.create_table        |
---|                     procedure                                            |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author             Remarks                        |
-- |=======   ===========   ================   ===============================|
-- | V1.0     15-DEC-2009   Lincy K            For Defect 2851                |
-- | V1.1     25-JAN-2010   R. Aldridge        Defect 2851 - modify storage   |
-- |                                           parameters, add tablespace,and |                          
-- |                                           add add index creation parms.  |
-- |                                                                          |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

BEGIN
apps.gl_journal_import_pkg.create_table(table_name             => 'XX_GL_INTERFACE_HIGH_VOL_NA'
                                       ,TABLESPACE             => 'APPS_TS_TX_DATA_32M'
                                       ,physical_attributes    => 'INITRANS 10'
                                       ,create_n1_index        => TRUE
                                       ,n1_tablespace          => 'APPS_TS_TX_IDX_16M'
                                       ,n1_physical_attributes => 'INITRANS 11'
                                       ,create_n2_index        => TRUE
                                       ,n2_tablespace          => 'APPS_TS_TX_IDX_16M'
                                       ,n2_physical_attributes => 'INITRANS 11'
                                       );
END;

/


