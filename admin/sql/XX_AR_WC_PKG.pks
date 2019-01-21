CREATE OR REPLACE PACKAGE APPS.xx_ar_wc_pkg
AS
   --Global variable  declaration
   gc_program_name         xx_com_error_log.program_name%TYPE                     := 'OD: AR WC Outbounds establish date';
   gc_program_short_name   fnd_concurrent_programs.concurrent_program_name%TYPE   := 'XX_AR_WC_PKG';
   gc_module_name          xx_com_error_log.module_name%TYPE                      := 'XXFIN';
   gc_error_debug          VARCHAR2 (400)                                         := NULL;
   gn_nextval              NUMBER;
   gc_error_loc            VARCHAR2 (250);

   PROCEDURE EST_DATE (
      p_errbuf        OUT      VARCHAR2
     ,p_retcode       OUT      NUMBER
     ,p_to_run_date   IN       VARCHAR2
   );

   PROCEDURE from_to_date (
      p_from_date   OUT   VARCHAR2
     ,p_to_date     OUT   VARCHAR2
     ,p_retcode     OUT   NUMBER
   );
END xx_ar_wc_pkg;
/