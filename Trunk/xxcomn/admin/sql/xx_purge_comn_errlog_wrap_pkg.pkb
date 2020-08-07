CREATE OR REPLACE PACKAGE BODY xx_purge_comn_errlog_wrap_pkg
-- +===============================================================================+
-- |                  Office Depot - Project Simplify                              |
-- |                Oracle Consulting Organization                                 |
-- +===============================================================================+
-- | Name        :  xx_purge_comn_errlog_wrap_pkg.pkb                              |
-- | Description :  This package is a wrapper for purge common error log           |
-- | Subversion Info:                                                              |
-- |                                                                               |
-- |   $HeadURL: $
-- |       $Rev: $
-- |      $Date: $
-- |                                                                               |
-- |                                                                               |
-- |Change Record:                                                                 |
-- |===============                                                                |
-- |Version   Date           Author                      Remarks                   |
-- |========  =========== ================== ======================================|
-- |1.0       07-NOV-2014  Sridevi K         Initial                               |
-- |2.0       13-NOV-2014  Sridevi K         Added wait for request logic          |
-- |3.0       18-NOV-2015  Manikant Kasu     Removed schema alias as part of GSCC  | 
-- |                                         R12.2.2 Retrofit                      |
-- +===============================================================================+
AS
   gc_package      VARCHAR2 (30) := 'xx_purge_comn_errlog_wrap_pkg';
   gn_request_id   NUMBER        := fnd_global.conc_request_id;

   FUNCTION wait_for_request (p_request_id NUMBER)
      RETURN VARCHAR2;

   PROCEDURE submit_request (
      p_program   IN   VARCHAR2,
      p_module    IN   VARCHAR2,
      p_age       IN   NUMBER
   );

-- +===================================================================+
-- | Name             : display_log                                    |
-- | Description      : Local procedure to print the output in log file|
-- |                                                                   |
-- | Parameters :       p_message                                      |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          None                                           |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE display_log (p_message VARCHAR2)
   IS
   BEGIN
      --DBMS_OUTPUT.PUT_line('gn_request_id'||gn_request_id);
      IF gn_request_id < 1
      THEN                         -- Not running from the concurrent manager
         DBMS_OUTPUT.put_line (p_message);
      ELSE
         fnd_file.put_line (fnd_file.LOG, p_message);
      END IF;
   END;

-- +===================================================================+
-- | Name             : main                                           |
-- | Description      : This is the procedure which gets called from SRS|
-- |                                                                   |
-- | Parameters :                                                      |
-- |  Parameter Name    Parameter Type    Description                  |
-- |  p_program_name    IN                Program Name                 |
-- |  p_module_name     IN                Module Name                  |
-- |  p_run_day         IN                Run Day                      |
-- |  x_errbuf          OUT               Error Message                |
-- |  x_retcode         OUT               Return Code                  |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE main (
      x_errbuf         OUT NOCOPY      VARCHAR2,
      x_retcode        OUT NOCOPY      VARCHAR2,
      p_module_name    IN              VARCHAR2,
      p_program_name   IN              VARCHAR2,
      p_run_day        IN              VARCHAR2
   )
   AS
--=================================================================---
-- Declaring local variables                                       ---
      lc_procedure   VARCHAR2 (30) := 'main';
      ln_count       NUMBER        := 0;

--=================================================================
--  Cursor for submitting purge common error log by module
--  as per translation setup
--=================================================================
      CURSOR cur_purge_req
      IS
         SELECT xftv.source_value1 program_name,
                xftv.source_value2 module_name, xftv.source_value3 age,
                xftv.source_value4 run_day, xftv.source_value5 run_flag
           FROM xx_fin_translatedefinition xftd,
                xx_fin_translatevalues xftv
          WHERE xftd.translate_id = xftv.translate_id
            AND xftd.translation_name = 'XXOD_PURGECOMMON_WRAPPER'
            AND xftv.enabled_flag = 'Y'
            AND SYSDATE BETWEEN xftv.start_date_active
                            AND NVL (xftv.end_date_active, SYSDATE)
            AND (   UPPER (NVL (p_run_day, 'ALL')) =
                                       UPPER (NVL (xftv.source_value4, 'ALL'))
                 OR UPPER (TO_CHAR (SYSDATE, 'day')) =
                                       UPPER (NVL (xftv.source_value4, 'ALL'))
                 OR 'ALL' = UPPER (NVL (xftv.source_value4, 'ALL'))
                )
            AND (CASE
                    WHEN p_program_name IS NULL
                       THEN 'ALL'
                    ELSE xftv.source_value1
                 END
                ) = NVL (p_program_name, 'ALL')
            AND xftv.source_value2 = NVL (p_module_name, xftv.source_value2)
            AND NVL (xftv.source_value3, -1) NOT IN (0, -1)
            AND NVL (xftv.source_value5, 'N') = 'Y';
   BEGIN
      display_log ('Start ' || gc_package || '.' || lc_procedure);
      display_log ('Input Parameters:');
      display_log ('=================');
      display_log ('p_program_name:' || NVL (p_program_name, 'ALL'));
      display_log ('p_module_name:' || NVL (p_module_name, 'ALL'));
      display_log ('p_runday:' || NVL (p_run_day, 'ALL'));
      display_log ('=================');
      -- Initializing OUT NOCOPY Variables
      x_retcode := 0;
      x_errbuf := NULL;

      FOR lcu_purge_req_rec IN cur_purge_req
      LOOP
         ln_count := 1;

         BEGIN
            display_log
                  ('--------------------------------------------------------');
            display_log ('Submitting program for parameters:');
            display_log ('Program:' || lcu_purge_req_rec.program_name);
            display_log ('Module:' || lcu_purge_req_rec.module_name);
            display_log ('Age:' || lcu_purge_req_rec.age);
            --Submitting concurrent Request
            submit_request (p_program      => lcu_purge_req_rec.program_name,
                            p_module       => lcu_purge_req_rec.module_name,
                            p_age          => lcu_purge_req_rec.age
                           );
            display_log
                   ('--------------------------------------------------------');
         EXCEPTION
            WHEN OTHERS
            THEN
               x_retcode := 1;
               x_errbuf :=
                    'Error Submitting concurrent request. Please check log. ';
               display_log
                        (   'Exception while submitting concurrent request. '
                         || ' Error: '
                         || SQLERRM
                        );
               display_log
                   ('--------------------------------------------------------');
         END;
      END LOOP;

      IF ln_count = 0
      THEN
         display_log ('No eligible translation setup data found!');
      END IF;

      display_log ('End ' || gc_package || '.' || lc_procedure);
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 1;
         x_errbuf :=
               'Unexpected error in Procedure '
            || gc_package
            || '.'
            || lc_procedure
            || ' Error: '
            || SQLCODE
            || '-'
            || SQLERRM;
         display_log (   'Unexpected error in Procedure '
                      || gc_package
                      || '.'
                      || lc_procedure
                      || ' Error: '
                      || SQLERRM
                     );
         display_log ('End ' || gc_package || '.' || lc_procedure);
   END main;

-- +===================================================================+
-- | Name             : submit request                                 |
-- | Description      : This is the procedure which submits            |
-- |                    OD: Purge Common Error Log By Module           |
-- |                                                                   |
-- | Parameters :                                                      |
-- |  Parameter Name    Parameter Type    Description                  |
-- |  p_program         IN                Program Name                 |
-- |  p_module          IN                Module Name                  |
-- |  p_age             IN                NUMBER                       |
-- |                                                                   |
-- +===================================================================+
   PROCEDURE submit_request (
      p_program   IN   VARCHAR2,
      p_module    IN   VARCHAR2,
      p_age       IN   NUMBER
   )
   IS
--=================================================================
-- Declaraing local variables
--=================================================================
      lc_procedure               VARCHAR2 (30) := 'submit_request';
      lc_status                  VARCHAR2 (10);
      ln_concurrent_request_id   NUMBER        := 0;
      lc_program                 VARCHAR2 (50)
                                            := 'XX_PURGE_ERROR_LOG_BY_MODULE';
   BEGIN
      display_log ('Start ' || gc_package || '.' || lc_procedure);
      display_log ('Submitting Program ');
      ln_concurrent_request_id :=
         fnd_request.submit_request (application      => 'XXCOMN',
                                     program          => lc_program,
                                     description      => NULL,
                                     start_time       => SYSDATE,
                                     sub_request      => FALSE,
                                     argument1        => p_module,
                                     --Module Name
                                     argument2        => p_program,
                                     --program Name
                                     argument3        => p_age,          --Age
                                     argument4        => CHR (0)
                                    );
      COMMIT;
      lc_status := wait_for_request (ln_concurrent_request_id);

      IF ln_concurrent_request_id = 0
      THEN
         display_log (   'Error while submittimg concurrent request: '
                      || fnd_message.get
                     );
      ELSE
         display_log ('Submitted request:' || ln_concurrent_request_id);

         IF lc_status = 'S'
         THEN
            display_log (   'Request ID: '
                         || ln_concurrent_request_id
                         || ' Finished Successfully'
                        );
         ELSIF lc_status = 'W'
         THEN
            display_log (   'Request ID: '
                         || ln_concurrent_request_id
                         || ' Finished with warnings. Please check log.'
                        );
         ELSIF lc_status = 'E'
         THEN
            display_log (   'Request ID: '
                         || ln_concurrent_request_id
                         || ' Finished with errors. Please check log.'
                        );
         END IF;
      END IF;

      display_log ('End ' || gc_package || '.' || lc_procedure);
   EXCEPTION
      WHEN OTHERS
      THEN
         ROLLBACK;
         display_log (   'Exception in Procedure '
                      || gc_package
                      || '.'
                      || lc_procedure
                      || ' Error: '
                      || SQLERRM
                     );
         display_log ('End ' || gc_package || '.' || lc_procedure);
   END submit_request;

   -- +==================================================================================================+
-- |PROCEDURE   : wait_for_request                                                                |
-- |                                                                                                  |
-- |DESCRIPTION : Function for waiting for a concurrent request to get completed                       |                                                      |
-- |                                                                                                  |
-- |PARAMETERS  :                                                                                     |
-- |                                                                                                  |
-- |    NAME                Mode       TYPE                  DESCRIPTION                              |
-- |-------------           ----   --------------   ---------------------------------                 |
-- | p_request_id              IN      NUMBER         Request Id                                     |
-- |--------------------------------------------------------------------------------------------------|
   FUNCTION wait_for_request (p_request_id NUMBER)
      RETURN VARCHAR2
   IS
      ln_concurrent_request_id   PLS_INTEGER;
      lc_phase                   VARCHAR2 (50);
      lc_wait_status             VARCHAR2 (50);
      lc_dev_phase               VARCHAR2 (15);
      lc_dev_status              VARCHAR2 (15);
      lc_return_status           VARCHAR2 (1);
      lc_message                 VARCHAR2 (2000);
      lc_procedure               VARCHAR2 (30)   := 'wait_for_request';
      lb_wait                    BOOLEAN;
      lc_program                 VARCHAR2 (30);
   BEGIN
      ln_concurrent_request_id := p_request_id;

      WHILE (UPPER (NVL (lc_dev_phase, 'XX')) <> 'COMPLETE')
      LOOP
         lc_dev_phase := 'XX';
         lb_wait :=
            fnd_concurrent.wait_for_request (ln_concurrent_request_id,
                                             10,
                                             0,
                                             lc_phase,
                                             lc_wait_status,
                                             lc_dev_phase,
                                             lc_dev_status,
                                             lc_message
                                            );
         EXIT WHEN UPPER (lc_dev_phase) = 'COMPLETE';
      END LOOP;

      IF (lc_dev_phase = 'COMPLETE' AND lc_dev_status = 'NORMAL')
      THEN
         display_log (   'Request ID: '
                      || ln_concurrent_request_id
                      || ' Successful'
                     );
         lc_return_status := 'S';
      ELSIF (lc_dev_phase = 'COMPLETE' AND lc_dev_status = 'WARNING')
      THEN
         display_log (   'Request ID: '
                      || ln_concurrent_request_id
                      || ' Finished with warnings'
                     );
         lc_return_status := 'W';
      ELSE
         display_log (   'Request ID:'
                      || ln_concurrent_request_id
                      || ' Finished with errors'
                      || fnd_message.get
                     );
         lc_return_status := 'E';
      END IF;

      display_log ('End ' || gc_package || '.' || lc_procedure);
      RETURN lc_return_status;
   EXCEPTION
      WHEN OTHERS
      THEN
         display_log (   'Exception in Procedure '
                      || gc_package
                      || '.'
                      || lc_procedure
                      || ' Error: '
                      || SQLERRM
                     );
         display_log ('End ' || gc_package || '.' || lc_procedure);
         RAISE;
   END wait_for_request;
END xx_purge_comn_errlog_wrap_pkg;
/

SHOW ERRORS;

