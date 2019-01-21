create or replace 
PACKAGE XX_CDH_AOPS_AB_PKG
AS
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                 			   |
-- +===============================================================================+
-- | Name  :  XX_CDH_AOPS_AB_PKG                                   			       |
-- |                                                                 			   |
-- | Description: Package to verify mismatch in AOPS Load and Oracle DB for AB and |
-- |              generate OD: CRM AOPS to Oracle AB Mismatch Report which will be |
-- |              send to AOPS for customer data sync   						   |
-- |                                                              			       |
-- |Change Record:                                                			       |
-- |===============                                               			       |
-- |Version   Date        Author           Remarks                			       |
-- |=======   ==========  =============    ========================================|
-- |1.0       16-Sep-16   Poonam Gupta     Initial draft version   			       |
-- |                                       for Defect #37159        			   |
-- +===============================================================================+
   PROCEDURE main (
      x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      NUMBER,
      p_load_aops   IN              VARCHAR2 DEFAULT 'N'
   );
END XX_CDH_AOPS_AB_PKG;
/