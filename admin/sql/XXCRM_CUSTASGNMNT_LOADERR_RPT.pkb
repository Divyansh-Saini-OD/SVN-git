create or replace
PACKAGE BODY XXCRM_CUSTASGNMNT_LOADERR_RPT
 -- +===================================================================================== +
  -- |                  Office Depot - Project Simplify                                     |
  -- +===================================================================================== +
  -- |                                                                                      |
  -- | Name             : XXCRM_CUSTASGNMNT_LOADERR_RPT                                     |
  -- | Description      : This program is for querying and detailing CUSTOMER               |
  -- |                    ASSIGNMENT UPLOAD Error details.                                  |
  -- |                                                                                      |
  -- |                                                                                      |
  -- | This package contains the following sub programs:                                    |
  -- | =================================================                                    |
  -- |Type         Name                  Description                                        |
  -- |=========    ===========           ================================================   |
  -- |PROCEDURE    MAIN_PROC             This procedure will be used to extract and display |
  -- |                                   the  Customer Assignment Upload Errors             |
  -- |                                           .                                          |
  -- |Change Record:                                                                        |
  -- |===============                                                                       |
  -- |Version   Date         Author           Remarks                                       |
  -- |=======   ==========   =============    ============================================= |
  -- |Change    05-21-2009  Mohan Kalyanasundaram New Version                               !
 -- +===================================================================================== +

 AS

     -- +====================================================================+
     -- | Name        :  display_log                                         |
     -- | Description :  This procedure is invoked to print in the log file  |
     -- |                                                                    |
     -- | Parameters  :  Log Message                                         |
     -- +====================================================================+

     PROCEDURE display_log(
                           p_message IN VARCHAR2
                          )

     IS

     BEGIN

          FND_FILE.PUT_LINE(FND_FILE.LOG,p_message);

    END display_log;

        -- +====================================================================+
        -- | Name        :  display_out                                         |
        -- | Description :  This procedure is invoked to print in the output    |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+

        PROCEDURE display_out(
                              p_message IN VARCHAR2
                             )

        IS

        BEGIN

             FND_FILE.PUT_LINE(FND_FILE.OUTPUT,p_message);

        END display_out;



        -- +====================================================================+
        -- | Name        :  Main_Proc                                           |
        -- | Description :  This is the Main Procedure  invoked by the          |
        -- |                Concurrent Program                                  |
        -- |                file                                                |
        -- |                                                                    |
        -- | Parameters  :  Log Message                                         |
        -- +====================================================================+


        PROCEDURE Main_Proc ( x_errbuf           OUT VARCHAR2
	                        , x_retcode          OUT NUMBER
                                ,p_delete_flag IN VARCHAR2)

        IS
       Cursor c_upload_err_dtl
       IS
          select rs_overlay_asgnmt_id, rep_id, customer_number, ship_to, processed_remark 
          from xxcrm.xxcrm_rs_overlay_assignments where processed_flag = 'E' order by rep_id, rs_overlay_asgnmt_id;

         TYPE upload_err_tbl_type IS TABLE OF c_upload_err_dtl%ROWTYPE INDEX BY BINARY_INTEGER;
	 l_upload_err_report upload_err_tbl_type;

        BEGIN
         fnd_file.put_line(fnd_file.log, 'Start of Concurrent Program - OD: XXCRM Customer Assignment Upload Error Report');
		 fnd_file.put_line(fnd_file.log, 'Executing Procedure - Main_proc BEGIN');
		 x_retcode := 0;
		 l_upload_err_report.delete;

              display_out(
			'RepID,CustomerNumber,ShipTo,OverlayAsgnmtID,ErrorDescription');
                OPEN  c_upload_err_dtl;
                FETCH c_upload_err_dtl BULK COLLECT INTO l_upload_err_report;
                CLOSE c_upload_err_dtl;

                IF l_upload_err_report.count > 0 THEN

                     FOR i IN l_upload_err_report.FIRST.. l_upload_err_report.LAST
                        LOOP
                           display_out(l_upload_err_report(i).rep_id||','||l_upload_err_report(i).customer_number||','||l_upload_err_report(i).ship_to||','||l_upload_err_report(i).rs_overlay_asgnmt_id||','||l_upload_err_report(i).processed_remark);
                        END LOOP;
                END IF;

          BEGIN
            IF nvl(p_delete_flag,'X') = 'Y' THEN
              delete xxcrm.xxcrm_rs_overlay_assignments where processed_flag = 'E';
              commit;
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            log_exception (
              p_program_name             => NULL
              ,p_error_location           => 'Main_Proc'
              ,p_error_status             => 'ERROR'
              ,p_oracle_error_code        => NULL
              ,p_oracle_error_msg         => '***Error DELETING Error Records from xxcrm.xxcrm_rs_overlay_assignments*** SQL Error Code: '||SQLCODE||' '||SUBSTR(SQLERRM,1,100)
              ,p_error_message_severity   => 'MAJOR'
              ,p_attribute1               => NULL);
          END;
           EXCEPTION WHEN OTHERS THEN
                 x_retcode := 2;
                 x_errbuf  := SUBSTR('Unexpected error occurred.Error:'||SQLERRM,1,255);
                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                 P_PROGRAM_TYPE            => 'CONCURRENT PROGRAM'
                                                ,P_PROGRAM_NAME            => 'XXCRM_CUSTASGNMNT_LOADERR_RPT.MAIN_PROC'
                                                ,P_PROGRAM_ID              => NULL
                                                ,P_MODULE_NAME             => 'XXCRM'
                                                ,P_ERROR_LOCATION          => 'WHEN OTHERS EXCEPTION'
                                                ,P_ERROR_MESSAGE_COUNT     => NULL
                                                ,P_ERROR_MESSAGE_CODE      => x_retcode
                                                ,P_ERROR_MESSAGE           => x_errbuf
                                                ,P_ERROR_MESSAGE_SEVERITY  => 'MAJOR'
                                                ,P_NOTIFY_FLAG             => 'Y'
                                                ,P_OBJECT_TYPE             => 'Customer Upload Error report'
                                                ,P_OBJECT_ID               => NULL
                                                ,P_ATTRIBUTE1              => NULL
                                                ,P_ATTRIBUTE3              => NULL
                                                ,P_RETURN_CODE             => NULL
                                                ,P_MSG_COUNT               => NULL
                                               );
	     fnd_file.put_line(fnd_file.log, 'Executing Procedure - Main_proc END');
		 fnd_file.put_line(fnd_file.log, 'End of Concurrent Program - OD: XXCRM Customer Assignment Upload Error Report');

       END MAIN_PROC;
-- +====================================================================+
-- | Name        : log_exception                                        |
-- | Description : This procedure is used for logging exceptions into   |
-- |               conversion common elements tables.                   |
-- |                                                                    |
-- | Parameters  : p_program_name,p_procedure_name,p_error_location     |
-- |               p_error_status,p_oracle_error_code,p_oracle_error_msg|
-- +====================================================================+

  PROCEDURE log_exception
    (p_program_name IN VARCHAR2,
    p_error_location IN VARCHAR2,
    p_error_status IN VARCHAR2,
    p_oracle_error_code IN VARCHAR2,
    p_oracle_error_msg IN VARCHAR2,
    p_error_message_severity IN VARCHAR2,
    p_attribute1 IN VARCHAR2)

 AS

-- ============================================================================
-- Local Variables.
-- ============================================================================
  l_return_code VARCHAR2(1) := 'E';
  l_program_name VARCHAR2(50);
  l_object_type constant VARCHAR2(35) := 'OD: XXCRM Customer Assignment Upload Error Report';
  l_notify_flag constant VARCHAR2(1) := 'Y';
  l_program_type VARCHAR2(35) := 'CONCURRENT PROGRAM';

  BEGIN
    l_program_name := p_program_name;
    IF l_program_name IS NULL THEN
      l_program_name := 'OD: XXCRM Customer Assignment Upload Error Report';
    END IF;
    -- ============================================================================
    -- Call to custom error routine.
    -- ============================================================================
    xx_com_error_log_pub.log_error_crm(p_return_code => l_return_code,
      p_program_type => l_program_type,
      p_program_name => l_program_name,
      p_error_location => p_error_location,
      p_error_message_code => p_oracle_error_code,
      p_error_message => p_oracle_error_msg,
      p_error_message_severity => p_error_message_severity,
      p_error_status => p_error_status,
      p_notify_flag => l_notify_flag,
      p_object_type => l_object_type,
      p_attribute1 => p_attribute1);
  EXCEPTION
  WHEN others THEN
  fnd_file.PUT_LINE(fnd_file.LOG,   ': Error in logging exception :' || sqlerrm);

  END log_exception;

       END XXCRM_CUSTASGNMNT_LOADERR_RPT;

/