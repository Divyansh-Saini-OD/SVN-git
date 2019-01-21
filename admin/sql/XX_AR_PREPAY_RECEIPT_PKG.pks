SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
PROMPT Creating Package Specification XX_AR_PREPAY_RECEIPT_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_AR_PREPAY_RECEIPT_PKG
  -- +============================================================================+
  -- |                  Office Depot - Project Simplify                           |
  -- |                        Office Depot Organization                           |
  -- +============================================================================+
  -- | Name             :  XX_AR_PREPAY_RECEIPT_PKG.pks                           |
  -- | RICE ID          : E3080                                                   |
  -- |                                                                            |
  -- | Description      :  This package will create Prepayment Receipt based on   |
  -- |                     Order Header Id.                                       |
  -- |                                                                            |
  -- |Change Record:                                                              |
  -- |===============                                                             |
  -- |Version Date        Author            Remarks                               |
  -- |======= =========== =============     ================                      |
  -- |DRAFT1A 08-JUN-13   Gayathri K       Created as part of QC#23068            |
  -- |                                                                            |
  -- +============================================================================+
AS
  --Define Global variables
  g_user_id NUMBER := fnd_global.user_id;
  g_org_id  NUMBER := fnd_profile.value('org_id');
  -- +============================================================================+
  -- | Name             :  XX_AR_PREPAY_RECEIPT_PROC                              |
  -- |                                                                            |
  -- | Description      :  This procedure will create AR Receipt (with Prepayment |
  -- |                     Application) based on the data present in oe_payments  |
  -- |                     and oe_order_headers_all tables.                       |
  -- | Parameters       :  p_header_id        IN ->  Order Header ID for which    |
  -- |                     prepayment receipt needs to be created.                |
  -- |                  :  p_return_status    OUT->         S=Success, F=Failure  |
  -- |                                                                            |
  -- +============================================================================+
PROCEDURE XX_AR_PREPAY_RECEIPT_PROC(
    p_header_id IN NUMBER,
    p_return_status OUT VARCHAR2 );
END XX_AR_PREPAY_RECEIPT_PKG;
/
SHOW ERR
