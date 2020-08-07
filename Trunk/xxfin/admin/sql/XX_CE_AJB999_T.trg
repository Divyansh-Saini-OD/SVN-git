-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                       Providge Consulting                                |
-- +==========================================================================+
-- | Name :APPS.XX_CE_AJB999_T                                                |
-- | Description : Create the Cash Management (CE) Reconciliation             |
-- |               trigger XX_CE_AJB999_T.  When the transaction is           |
-- |               inserted the org_id is derived from country_code.          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author        Remarks                              |
-- |=======   ==========   ============= =====================================|
-- | V1.0     21-Jan-2008  T Banks       Initial version                      |
-- | v1.1     12-Jun-2008  D Gowda       Defect 8023 Recon_date derivation    |
-- |          03-Jul-2008  D Gowda       Defect 8743-Exception handling for   |
-- |                                     recon date derivation                | 
-- |          08-Jul-2008  D Gowda       Defect 8743-If recon date is null    |
-- |                                       default to SYSDATE                 |
-- |                                                                          |
-- |                                                                          |
-- +==========================================================================+
--
CREATE OR REPLACE TRIGGER xx_ce_ajb999_t
   BEFORE INSERT
   ON xx_ce_ajb999
   FOR EACH ROW
DECLARE
   tv_org_id      NUMBER := -2;
   td_recon_date  DATE;
BEGIN
   IF :NEW.country_code IS NOT NULL
   THEN
      BEGIN
         SELECT TO_NUMBER
                   (apps.xx_fin_country_defaults_pkg.f_org_id(ft.territory_code) )
           INTO tv_org_id
           FROM fnd_territories ft
          WHERE ft.iso_numeric_code = :NEW.country_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            :NEW.org_id := tv_org_id;
      END;

      :NEW.org_id := tv_org_id;
   END IF;

   IF :NEW.bank_rec_id IS NOT NULL
   THEN
      BEGIN
         td_recon_date :=
                        xx_ce_ajb_cc_recon_pkg.get_recon_date(:NEW.bank_rec_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            BEGIN
               td_recon_date := TO_DATE(SUBSTR(:NEW.bank_rec_id, 1, 8)
                                      , 'YYYYMMDD'
                                       );
            EXCEPTION
               WHEN OTHERS
               THEN
                  td_recon_date := TRUNC(SYSDATE);
            END;
      END;

      :NEW.recon_date := td_recon_date;
   ELSE
      :NEW.recon_date := TRUNC(SYSDATE);
   END IF;
END xx_ce_ajb999_t;
/