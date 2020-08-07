CREATE OR REPLACE PACKAGE BODY APPS.xx_ar_wc_pkg
AS
   /*+==============================================================================+
    | Name       : est_date                                                         |
    |                                                                               |
    | Description: This procedure is used to  get the to and from dates             |
    |                                                                               |
    | Parameters :                                                                  |
    | Returns    : p_err_buf                                                        |
    |              p_retcode                                                        |
    |              p_to_run_date                                                    |
    +=============================================================================+*/
   PROCEDURE EST_DATE (
      p_errbuf        OUT      VARCHAR2
     ,p_retcode       OUT      NUMBER
     ,p_to_run_date   IN       VARCHAR2
   )
   AS
      ld_previous_date   DATE;
   BEGIN
      BEGIN
         SELECT LOG1.program_run_date
           INTO ld_previous_date
           FROM xx_crmar_int_log LOG1
          WHERE LOG1.program_short_name = 'XX_AR_WC_PKG'
            AND LOG1.program_run_id = (SELECT MAX (LOG2.program_run_id)
                                         FROM xx_crmar_int_log LOG2
                                        WHERE LOG1.program_short_name = LOG2.program_short_name AND LOG2.status = 'SUCCESS');
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_loc := 'NO data found while getting previous run date';
            fnd_file.put_line (fnd_file.LOG, gc_error_loc);
      END;

      fnd_file.put_line (fnd_file.LOG, '********** AR Outbound Established Date **********');
      fnd_file.put_line (fnd_file.LOG, 'Parameters Passed In:');
      fnd_file.put_line (fnd_file.LOG, ' ');
      fnd_file.put_line (fnd_file.LOG, '   Run Date is     :' || p_to_run_date);
      fnd_file.put_line (fnd_file.LOG, 'Parameters Derived :');
      fnd_file.put_line (fnd_file.LOG, '   Run Date is     :' || ld_previous_date);

      BEGIN
         SELECT xx_crmar_int_log_s.NEXTVAL
           INTO gn_nextval
           FROM DUAL;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            gc_error_debug := 'NO data found while generating sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
         WHEN OTHERS
         THEN
            gc_error_debug := SQLERRM || ' Others exception raised while generating sequence value';
            fnd_file.put_line (fnd_file.LOG, gc_error_debug);
      END;

      INSERT INTO xx_crmar_int_log
                  (program_run_id
                  ,program_name
                  ,program_short_name
                  ,module_name
                  ,previous_run_date
                  ,program_run_date
                  ,status
                  )
           VALUES (gn_nextval
                  ,gc_Program_name
                  ,gc_program_short_name
                  ,gc_module_name
                  ,NVL (ld_previous_date, SYSDATE)
                  ,SYSDATE
                  ,'SUCCESS'
                  );

      COMMIT;
   END;

   /*+=============================================================================+
   | Name       : from_to_date                                                     |
   |                                                                               |
   | Description: This procedure is used to get From and To dates                  |
   |                                                                               |
   | Parameters :                                                                  |
   | Returns    : p_from_date                                                      |
   |              p_to_date                                                        |
   |              p_retcode                                                        |
   +=============================================================================+*/
   PROCEDURE from_to_date (
      p_from_date   OUT   VARCHAR2
     ,p_to_date     OUT   VARCHAR2
     ,p_retcode     OUT   NUMBER
   )
   IS
      ld_from_date   DATE;
      ld_to_date     DATE;
   BEGIN
      SELECT LOG1.previous_run_date
            ,LOG1.program_run_date
        INTO ld_from_date
            ,ld_to_date
        FROM xx_crmar_int_log LOG1
       WHERE LOG1.program_short_name = 'XX_AR_WC_PKG'
         AND LOG1.program_run_id = (SELECT MAX (LOG2.program_run_id)
                                      FROM xx_crmar_int_log LOG2
                                     WHERE LOG1.program_short_name = LOG2.program_short_name AND LOG2.status = 'SUCCESS');

      p_from_date := TO_CHAR (ld_from_date, 'YYYYMMDD HH24:MI:SS');
      p_to_date := TO_CHAR (ld_to_date, 'YYYYMMDD HH24:MI:SS');
   EXCEPTION
      WHEN OTHERS
      THEN
         gc_error_loc := SQLCODE || '-' || SQLERRM;
         fnd_file.put_line (fnd_file.LOG, 'Others exception raised in from_to_date procedure' || gc_error_loc);
         p_retcode := 2;
   --End of the procedure from_to_date
   END from_to_date;
END xx_ar_wc_pkg;
/