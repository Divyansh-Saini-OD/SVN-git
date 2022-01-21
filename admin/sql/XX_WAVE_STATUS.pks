SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET DEFINE OFF

CREATE OR REPLACE
PACKAGE XX_WAVE_STATUS
AS
-- +==========================================================================+
-- |                 EAS Oracle Center Of Excellence                          |
-- |                       WIPRO Technologies                                 |
-- |                                                                          |
-- +==========================================================================+
-- | Name :    PROCESS_REQUEST                                                |
-- |                                                                          |
-- | Description : Procedure is used to submit the wave status Program.       |
-- | Change Record:                                                           |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- | 1.0    05-OCT-2010     Jude Felix Antony       Initial Version           |
-- |                                                                          |
-- +==========================================================================+

   PROCEDURE PROCESS_REQUEST(p_cycle_date        VARCHAR2  DEFAULT   NULL 
                            ,p_mail_type         VARCHAR2  DEFAULT  'DEF'
                            ,p_mail_address      VARCHAR2  DEFAULT  ''
                            ,p_mail_flag         VARCHAR2  DEFAULT  'Y'
                            ,p_issues            CLOB      DEFAULT  'No Issues'
                            ,p_action            VARCHAR2 );

-- +==========================================================================+
-- |                 EAS Oracle Center Of Excellence                          |
-- |                       WIPRO Technologies                                 |
-- +==========================================================================+
-- | Name :    MAILING                                                        |
-- |                                                                          |
-- | Description : Procedure to generate the UI which is used to submit wave  |
-- |               status.                                                    |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date              Author              Remarks                   |
-- |======   ==========     =============        =======================      |
-- |  1.0    05-OCT-2010    Jude Felix Antony    Initial Version              |
-- |                                                                          |
-- +==========================================================================+

   PROCEDURE MAILING;

END;
/
SHOW ERR;
/
