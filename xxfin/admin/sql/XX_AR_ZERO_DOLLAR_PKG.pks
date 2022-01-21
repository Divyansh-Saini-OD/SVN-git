SET SHOW OFF;
SET VERIFY OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
PROMPT Creating Package Specification XX_AR_ZERO_DOLLAR_NOTE_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE
PACKAGE XX_AR_ZERO_DOLLAR_PKG
  -- +============================================================================+
  -- |                  Office Depot - Project Simplify                           |
  -- |                        Office Depot Organization                           |
  -- +============================================================================+
  -- | Name             :  XX_AR_ZERO_DOLLAR_PKG.pks                              |
  -- | RICE ID          : R1389                                                   |
  -- |                                                                            |
  -- | Description      :  This package will display Zero Dollar Application      |
  -- |                     Receipts.                                              |
  -- |                                                                            |
  -- |Change Record:                                                              |
  -- |===============                                                             |
  -- |Version Date        Author            Remarks                               |
  -- |======= =========== =============     ================                      |
  -- |DRAFT1A 03-OCT-13   Gayathri K       Created as part of QC#24465            |
  -- |                                                                            |
  -- | 1.1    16-SEP-14   Gayathri K       Changed data type from DATE to VARCHAR2|
  -- |                                    as part of QC#30179                     |
  -- +============================================================================+
AS
  --Define Global variables
  g_user_id NUMBER := fnd_global.user_id;
  g_org_id  NUMBER := fnd_profile.value('org_id');
  RPT_REQUEST_ID NUMBER(20);
  -- +============================================================================+
  -- | Name             :  XX_AR_ZERO_DOLLAR_PROC                                  |
  -- |                                                                            |
  -- | Description      :  This procedure will display Zero Dollar application    |
  -- | Parameters       :  p_from_trans_date        IN ->  Transmission From Date |
  -- |                                                                            | 
  -- |                  :  p_to_trans_date    IN->         Transmission FTo Date  |
  -- |                                                                            |
  -- +============================================================================+
PROCEDURE XX_AR_ZERO_DOLLAR_PROC(
    x_retcode             Out Nocopy      Number,
    x_errbuf              OUT NOCOPY      VARCHAR2,
   -- p_from_trans_date IN DATE,  -- commneted as part of QC#30179
   -- p_to_trans_date IN DATE )   -- commneted as part of QC#30179
    p_from_trans_date IN VARCHAR2,-- Added as part of QC#30179
    p_to_trans_date IN VARCHAR2 );-- Added as part of QC#30179
END XX_AR_ZERO_DOLLAR_PKG;
/
SHOW ERR
