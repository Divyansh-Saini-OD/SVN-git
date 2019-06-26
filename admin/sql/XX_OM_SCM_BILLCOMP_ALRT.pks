CREATE OR REPLACE PACKAGE APPS.XX_OM_SCM_BILLCOMP_ALRT
AS
 PROCEDURE extract_pending_bc_orders (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2,
	  p_num_days     IN    NUMBER
   );
   
END XX_OM_SCM_BILLCOMP_ALRT;