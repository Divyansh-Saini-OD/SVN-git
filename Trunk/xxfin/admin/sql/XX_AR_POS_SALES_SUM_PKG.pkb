CREATE OR REPLACE PACKAGE BODY xx_ar_pos_sales_sum_pkg
AS
/******************************************************************************
   NAME:       XX_AR_POS_SALES_SUM_PKG
   PURPOSE:    Contains Procedures used by OD: AR POS Sales Summary by Store Report

   REVISIONS:
   Ver        Date        Author            Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        15-Apr-2011 Siddharth J      Created this package.
   2.0        13-Nov-2015 Manikant K       Removed schema reference from package 
                                           name definition
******************************************************************************/
   PROCEDURE main (
      x_errbuf            OUT NOCOPY      VARCHAR2,
      x_retcode           OUT NOCOPY      VARCHAR2,
      p_trans_date_from   IN              VARCHAR2,
      p_trans_date_to     IN              VARCHAR2,
      p_store_num         IN              VARCHAR2,
      p_gl_date_from      IN              VARCHAR2,
      p_gl_date_to        IN              VARCHAR2,
      p_ou_id             IN              NUMBER
   )
   IS
   BEGIN
   
      sum_by_store_proc(p_trans_date_from,
                         p_trans_date_to,
                         p_store_num,
                         p_gl_date_from,
                         p_gl_date_to,
                         p_ou_id
                        );
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END main;

   PROCEDURE sum_by_store_proc (
      p_trx_date_from   IN   VARCHAR2,
      p_trx_date_to     IN   VARCHAR2,
      p_store         IN   VARCHAR2,
      p_gl_date_from      IN   VARCHAR2,
      p_gl_date_to        IN   VARCHAR2,
      p_ou_id             IN   NUMBER
   )
   IS
   lb_print_option      BOOLEAN;
   lb_layout            BOOLEAN;
   ln_request_id        NUMBER;
   v_trx_date_from      DATE;
      v_trx_date_to        DATE;
      v_gl_date_from         DATE;
      v_gl_date_to           DATE;
   BEGIN

   v_trx_date_from := to_date (p_trx_date_from, 'RRRR/MM/DD HH24:MI:SS');
   v_trx_date_to := to_date (p_trx_date_to, 'RRRR/MM/DD HH24:MI:SS');
   v_gl_date_from := to_date (p_gl_date_from, 'RRRR/MM/DD HH24:MI:SS');
   v_gl_date_to := to_date (p_gl_date_to, 'RRRR/MM/DD HH24:MI:SS');
   
      lb_print_option :=
               fnd_request.set_print_options (printer      => 'XPTR',
                                              copies       => 1);
 -- Set the Output File Format
-- --------------------------
      lb_layout :=
         fnd_request.add_layout ('XXFIN',
                                 'XXARPOSSASU',
                                 'en',
                                 'US',
                                 'EXCEL'
                                );
-- Submit the program - OD: AR POS Sales Summary by Store Report
-- -------------------------------------------------------------
      ln_request_id :=
         fnd_request.submit_request ('XXFIN',
                                     'XXARPOSSASU',
                                     NULL,
                                     NULL,
                                     FALSE,
                                     v_trx_date_from,
                                     v_trx_date_to,
                                     p_store,
                                     v_gl_date_from,
                                     v_gl_date_to,
                                     p_ou_id                                     
                                    );
      COMMIT;

      IF ln_request_id <> 0
      THEN
         COMMIT;
         fnd_file.put_line
            (fnd_file.LOG,
                'Successfully submitted OD: AR POS Sales Summary by Store Report - '
             || ln_request_id
            );
      ELSE
         fnd_file.put_line
            (fnd_file.LOG, 'OD: AR POS Sales Summary by Store Report Failed' || ln_request_id );
         fnd_file.put_line
            (fnd_file.LOG, 'ERRMSG:' || SQLERRM );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line
            (fnd_file.LOG, 'OD: AR POS Sales Summary by Store Report Failed' || ln_request_id );
         
         fnd_file.put_line
            (fnd_file.LOG, 'ERRMSG:' || SQLERRM );
   END sum_by_store_proc;
END xx_ar_pos_sales_sum_pkg;
/