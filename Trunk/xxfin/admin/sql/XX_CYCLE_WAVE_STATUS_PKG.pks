CREATE OR REPLACE PACKAGE XX_CYCLE_WAVE_STATUS_PKG AS
/*-- +=============================================================================+
  -- | PACKAGE NAME : GET_CYCLE_DATE                                               |
  -- |                                                                             |
  -- | DESCRIPTION    : This package is used to get the details                    |
  -- |                  about the batch program's running in the Waves             |
  -- |                                                                             |
  -- |                                                                             |
  -- |Version   Date         Author               Remarks                          |
  -- |========  ===========  ===============      =================================|
  -- |1.0       16-AUG-2010  A.JUDE FELIX ANTONY                                   |
  -- |                                                                             |
  -- |                                                                             |
  -- +=============================================================================+*/
PROCEDURE GET_CYCLE_DATE (errbuff        OUT  VARCHAR2
                         ,retcode        OUT  VARCHAR2
                         ,p_cycle_date        VARCHAR2  DEFAULT   NULL
                         ,p_issues            CLOB      DEFAULT  'No Issues'
                         ,p_mail_type         VARCHAR2  DEFAULT  'DEF'
			 ,p_dummy             VARCHAR2
                         ,p_mail_address      VARCHAR2  DEFAULT  ''
                         ,p_mail_flag         VARCHAR2  DEFAULT  'Y'
                         );

END;
/
