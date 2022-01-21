CREATE OR REPLACE PACKAGE APPS.XX_AP_IBY_POSITIVE_PAY_PKG
AS

-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_AP_IBY_POSITIVE_PAY_PKG                         |
-- | Description      :    Package for AP Positive Pay                        |
-- | RICE ID          :    I0228                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      03-Oct-2013  Paddy Sanjeevi      Initial                        |
-- | 1.1      02-Jun-2014  Paddy Sanjevi       Defect 30031                   |
-- | 1.5      16-Sep-2014  Kirubha Samuel      Defect 31197                   |
-- +==========================================================================+


PROCEDURE submit_pos_pay_process  ( p_errbuf   		IN OUT  VARCHAR2
                                   ,p_retcode  		IN OUT  NUMBER
				   ,p_bank_name		IN 	VARCHAR2
				   ,p_format		IN      VARCHAR2
				   ,p_payment_status    IN 	VARCHAR2
				   ,p_payment_to_date IN   VARCHAR2 --added for 31197
                              );


END XX_AP_IBY_POSITIVE_PAY_PKG;
/
