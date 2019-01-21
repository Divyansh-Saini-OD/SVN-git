SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_SFA_PERZ_GEN_PKG AUTHID CURRENT_USER
AS
-- +================================================================================+
-- |                  Office Depot - Project Simplify                               |
-- |      Oracle NAIO/Office Depot/Consulting Organization                          |
-- +================================================================================+
-- | Name       : XX_SFA_PERZ_GEN_PKG                                               |
-- |                                                                                |
-- | Description:                                                                   |
-- |                                                                                |
-- |Change Record:                                                                  |
-- |===============                                                                 |
-- |Version   Date        Author                    Remarks                         |
-- |=======   ==========  =============             ================================|
-- |DRAFT 1A 26-MAR-2008 Sarah Maria Justina     Initial draft version              |
-- +================================================================================+
TYPE xx_file_list_tbl_type IS TABLE OF VARCHAR2(48)
  INDEX BY BINARY_INTEGER;
-- +===========================================================================================================+
-- | Name        :  create_perz_main
-- | Description :  This procedure is used to generate the User Personalizations in ASN for Managers(DSMs) and  
-- |                Proxy Administrators.
-- |                This gets called from the following Conc Programs: 
-- |                1) OD: SFA Upload Customer Personalizations Program
-- |                2) OD: SFA Upload Opportunity Personalizations Program
-- |                3) OD: SFA Upload Lead Personalizations Program
-- | Parameters  :  p_person_id    IN   PER_ALL_PEOPLE_F.PERSON_ID%TYPE,
-- |                p_lead_status  IN as_statuses_b.status_code%TYPE,
-- |                p_oppty_status IN as_statuses_b.status_code%TYPE,
-- |                p_perz_type    IN VARCHAR2
-- +===========================================================================================================+ 
PROCEDURE create_perz_main  (p_person_id    IN per_all_people_f.person_id%TYPE,
                             p_lead_status  IN as_statuses_b.status_code%TYPE,
                             p_oppty_status IN as_statuses_b.status_code%TYPE,
                             p_perz_type    IN VARCHAR2);
END XX_SFA_PERZ_GEN_PKG;
/

SHOW ERRORS
EXIT;
