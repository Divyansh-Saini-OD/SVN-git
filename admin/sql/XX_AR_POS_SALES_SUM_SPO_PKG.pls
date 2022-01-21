CREATE OR REPLACE PACKAGE xx_ar_pos_sales_sum_spo_pkg
AS
/********************************************************************************************************
   NAME:       XX_AR_POS_SALES_SUM_SPO_PKG
   PURPOSE:    Contains Procedures used by OD: AR POS Sales Summary by Store Report for Single Pay Orders.

   REVISIONS:
   Ver        Date        Author            Description
   ---------  ----------  ---------------  --------------------------------------------------------------
   1.0        19-Apr-2012 Gayathri K      Created this package.

********************************************************************************************************/
   PROCEDURE main (
      x_errbuf            OUT NOCOPY      VARCHAR2,
      x_retcode           OUT NOCOPY      VARCHAR2,
      p_trans_date_from   IN              VARCHAR2,
      p_trans_date_to     IN              VARCHAR2,
      p_store_num         IN              VARCHAR2,
      p_gl_date_from      IN              VARCHAR2,
      p_gl_date_to        IN              VARCHAR2,
      p_ou_id             IN              NUMBER
   );

   PROCEDURE sum_by_store_spo_proc (
      p_trx_date_from   IN   VARCHAR2,
      p_trx_date_to     IN   VARCHAR2,
      p_store         IN   VARCHAR2,
      p_gl_date_from      IN   VARCHAR2,
      p_gl_date_to        IN   VARCHAR2,
      p_ou_id             IN   NUMBER
   );
END xx_ar_pos_sales_sum_spo_pkg;
/
