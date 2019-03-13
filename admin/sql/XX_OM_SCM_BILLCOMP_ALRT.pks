CREATE OR REPLACE PACKAGE APPS.XX_OM_SCM_BILLCOMP_ALRT
AS
 PROCEDURE extract_pending_bc_orders (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2
   );
   
END XX_OM_SCM_BILLCOMP_ALRT;