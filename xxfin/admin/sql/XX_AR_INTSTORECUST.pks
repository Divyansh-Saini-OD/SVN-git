SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_AR_INTSTORECUST
PROMPT Program exits if the creation is not successful

create or replace PACKAGE XX_AR_INTSTORECUST_PKG
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- +=================================================================================+
-- | Name       : XX_AR_INTSTORECUST.pks                                              |
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |                                                                                 |
-- |1.0      26-APR-2011   Gaurav Agarwal     Created the package for E3015          |
-- |                                                                                 |
---+=================================================================================+
   PROCEDURE main(
      x_errbuf               OUT NOCOPY      VARCHAR2,
      x_retcode              OUT NOCOPY      NUMBER,
      p_tbl_name        IN              VARCHAR2
     
   );
   

END XX_AR_INTSTORECUST_PKG
;
/
show errors;
--exit;