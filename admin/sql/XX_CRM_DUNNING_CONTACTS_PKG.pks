SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package spec XX_CRM_DUNNING_CONTACTS_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CRM_DUNNING_CONTACTS_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       WIPRO Technologies                               |
-- +========================================================================+
-- | Name        : XX_CRM_DUNNING_CONTACTS_PKG                            |
-- | Description : 1) To import dunning contacts and contact points into    |
-- |                  Oracle.                                               |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      18-JUN-2010  Devi Viswanathan     Initial version              |
-- +========================================================================+

-- +========================================================================+
-- | Name        : XX_CRM_DUNN_CONT_TMPLT                                   |
-- | Description : 1) To import dunning contacts and contact points into    |
-- |                  Oracle.                                               |
-- | Returns     :                                   |
-- +========================================================================+

  FUNCTION xx_crm_dunn_cont_tmplt ( p_last_name   VARCHAR2
				  , p_first_name  VARCHAR2
				  , p_email_id    VARCHAR2
				  , p_tele_code   VARCHAR2
				  , p_telephone   VARCHAR2           
				  , p_fax_code    VARCHAR2
				  , p_fax         VARCHAR2
				  , p_leg_acc_num VARCHAR2
				  , p_addr_seq    VARCHAR2
				  ) RETURN VARCHAR2;
           
           
  PROCEDURE fix_collect_rec( x_errbuf          OUT NOCOPY  VARCHAR2
                           , x_retcode         OUT NOCOPY  VARCHAR2
                           , p_account_number  IN          VARCHAR2                           
                           , p_commit          IN          VARCHAR2
                           );            


END XX_CRM_DUNNING_CONTACTS_PKG;
/
SHOW ERR
