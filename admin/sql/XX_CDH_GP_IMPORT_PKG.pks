SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +============================================================================================+
-- |                  Office Depot - Project Simplify                                           |
-- +============================================================================================+
-- | Name        : XX_CDH_GP_IMPORT_PKG.pks                                                     |
-- | Description : GP Import                                                                    |
-- |                                                                                            |
-- |                                                                                            |
-- |Change Record:                                                                              |
-- |===============                                                                             |
-- |Version     Date           Author               Remarks                                     |
-- |=======    ==========      ================     ============================================|
-- |1.0        30-Jun-2011     Indra Varada        Initial version                              |
-- |1.1        01-Aug-2011     Indra Varada        fix for defect#12951                         |
-- +============================================================================================+

create or replace
PACKAGE XX_CDH_GP_IMPORT_PKG AS

  FUNCTION save_gp (
    p_gp_id                      IN NUMBER,
    p_gp_name                    IN VARCHAR2,
    p_owner                      IN VARCHAR2,
    p_segment                    IN VARCHAR2,
    p_revenue_band               IN VARCHAR2,
    p_written_agreement          IN VARCHAR2,
    p_requestor                  IN VARCHAR2,
    p_notes                      IN VARCHAR2,
    p_active                     IN VARCHAR2
  ) RETURN VARCHAR2;   

  FUNCTION save_gp_rel (
   p_parent_id          IN NUMBER,
   p_gp_id              IN NUMBER,
   p_start_date         IN DATE,
   p_end_date           IN DATE,
   p_requestor          IN VARCHAR2,
   p_notes              IN VARCHAR2
  ) RETURN VARCHAR2;


END XX_CDH_GP_IMPORT_PKG;
/
SHOW ERRORS;
