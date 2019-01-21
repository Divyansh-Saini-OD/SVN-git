SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package spec XX_CDH_WC_IN_CUST_UPDATE_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_CDH_WC_IN_CUST_UPDATE_PKG
AS
-- +========================================================================+
-- |                  Office Depot - Webcollect CDH                         |
-- +========================================================================+
-- | Name        : XX_CDH_WC_IN_CUST_UPDATE_PKG.pks                         |
-- | Description : To update the customer profile and import dunning        |
-- |               contacts and contact pints from webcollect to oracle     |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      22-Mar-2012  Jay Gupta             Initial version             |
-- +========================================================================+

-- +========================================================================+
-- | Name        : cust_dunn_contact_update                                 |
-- | Description : create/update customer dunning contact and contact points|
-- +========================================================================+
                                
  PROCEDURE XX_CDH_INBOUND_MAIN ( 
         x_errbuf         OUT NOCOPY VARCHAR2,
         X_RETCODE        OUT NOCOPY varchar2,
         p_debug_flag     VARCHAR2
);
 
END XX_CDH_WC_IN_CUST_UPDATE_PKG;
/
SHOW ERR