-- +==========================================================================+
-- |                  Office Depot - R12 Upgrade                              |
-- +==========================================================================+
---|  Application    :   GL                                                   |
---|                                                                          |
---|  Name           :   XX_GL_INTERFACE_NA.sql                               |
---|                                                                          |
---|  Description    :   Droping and recreating the table XX_GL_INTERFACE_NA  |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date          Author             Remarks                        |
-- |=======   ===========   ================   ===============================|
-- | V1.0     10-JAN-2014   Jay Gupta          DEfect#26736                   |
-- +==========================================================================+

SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

BEGIN
gl_journal_import_pkg.drop_table(table_name             => 'XX_GL_INTERFACE_NA');
gl_journal_import_pkg.create_table(table_name             => 'XX_GL_INTERFACE_NA'
                                       ,TABLESPACE             => 'APPS_TS_TX_DATA_MISC'
                                       ,physical_attributes    => 'INITRANS 10'
                                       ,create_n1_index        => TRUE
                                       ,n1_tablespace          => 'APPS_TS_TX_IDX_MISC'
                                       ,n1_physical_attributes => 'INITRANS 11'
                                       ,create_n2_index        => TRUE
                                       ,n2_tablespace          => 'APPS_TS_TX_IDX_MISC'
                                       ,n2_physical_attributes => 'INITRANS 11'
                                       );
END;

/


