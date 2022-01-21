CREATE OR REPLACE
PACKAGE XX_UTL_SEND_MAIL_PKG AS
/*-- +============================================================================+
  -- | PACKAGE NAME   : XX_UTL_SEND_MAIL_PKG                                      |
  -- |                                                                            |
  -- | DESCRIPTION    : This Package is used to send wave status mail             |
  -- |                                                                            |
  -- |                                                                            |
  -- | PARAMETERS     : p_issues,p_cycle_date,p_mail_address                      |
  -- |                  p_mail_type,p_lockbox,p_settlement,p_mail_status          |
  -- |                                                                            |
  -- |Version   Date         Author               Remarks                         |
  -- |========  ===========  ===================  ================================|
  -- |1.0       17-AUG-2010  A.JUDE FELIX ANTONY                                  |
  -- |                                                                            |
  -- +===========================================================================+*/
PROCEDURE SENDING_MAIL  (p_issues             CLOB     DEFAULT 'No Issues'
                        ,p_cycle_date    IN   VARCHAR2
                        ,p_mail_address  IN   VARCHAR2 DEFAULT ''
                        ,p_mail_type          VARCHAR2 DEFAULT 'DEF'
                        ,p_lockbox       IN   VARCHAR2 DEFAULT '-'
                        ,p_settlement    IN   VARCHAR2 DEFAULT '-'
                        ,p_mail_status   IN   VARCHAR2
                        ) ;

END;
/
show err;
