SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package XX_CS_TDS_AP_INVOICE_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
create or replace PACKAGE xx_cs_tds_ap_invoice_pkg
-- +=============================================================================================+
-- |                       Oracle GSD  (India)                                                   |
-- |                        Hyderabad  India                                                     |
-- +=============================================================================================+
-- | Name         : XX_CS_TDS_AP_INVOICE_PKG.pkb                                                 |
-- | Description  : This package is used to insert the records into the Payables Interface tables|
-- |                                                                                             |
-- |                                                                                             |
-- |Change Record:                                                                               |
-- |===============                                                                              |
-- |Version      Date          Author           Remarks                                          |
-- |=======   ==========   ===============      =================================================|
-- |V1.0      20-Jul-2011  Jagadeesh/S Tirumala Initial draft version                            |
-- |V1.1      22-Jan-16    Vasu raparla         Removed Schema References for R.12.2             |
-- +=============================================================================================+
AS
   gn_user_id    NUMBER := fnd_global.user_id;
   gn_login_id   NUMBER := fnd_global.login_id;

   TYPE t_invdetrectbl IS TABLE OF ap_invoice_lines_interface%ROWTYPE
      INDEX BY BINARY_INTEGER;

   PROCEDURE insert_proc (
      p_header_rec   IN       xx_cs_tds_ap_inv_rec
    , p_lines_tab    IN       xx_cs_tds_ap_inv_lines_tbl
    , x_status       OUT      VARCHAR2
    , x_msg_data     OUT      VARCHAR2
   );
END xx_cs_tds_ap_invoice_pkg;
/
SHOW ERROR;
EXIT;
