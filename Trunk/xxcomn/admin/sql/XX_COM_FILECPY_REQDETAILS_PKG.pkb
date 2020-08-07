create or replace PACKAGE BODY XX_COM_FILECPY_REQDETAILS_PKG
 AS
 -- +===================================================================+
 -- |                  Office Depot - Project Simplify                  |
 -- |                       WIPRO Technologies                          |
 -- +===================================================================+
 -- | Name :    XX_COM_FILECPY_REQDETAILS_PKG                           |
 -- | RICE :    E1373                                                   |
 -- | Description : This package is used to get the request details of  |
 -- |               the OD: Common File Copy that is run adhoc to       |
 -- |               reprocess files that failed during BPEL process     |
 -- |Change Record:                                                     |
 -- |===============                                                    |
 -- |Version   Date          Author              Remarks                |
 -- |=======   ==========   =============        =======================|
 -- |1.0       22-OCT-09    Harini G             Initial version        |
 -- |                                            Added for Defect 1917  |
 -- |1.1       07-JUN-10    Joe Klein            Added request_id,      |
 -- |                                            concurrent pgm, and    |
 -- |                                            status columns.        |
 -- |                                            Added start_date_from  |
 -- |                                            and start_date_to      |
 -- |                                            parameters.            |
 -- |1.2       11-DEC-2015   Vasu Raparla        Removed Schema         |
 -- |                                            References for R.12.2  |
 -- +===================================================================+
 -- +===================================================================+
 -- | Name        : COMN_FILECPY_REQDETAILS                             |
 -- | Description : The procedure is used to accomplish the following   |
 -- |               tasks:                                              |
 -- |               1. It gets the details of the OD: Common File Copy  |
 -- |                  that was submitted ad-hoc to reprocess files     |
 -- |                  that failed during BPEL process and prints it.   |
 -- |                                                                   |
 -- | Parameters  : p_start_date_from                                   |
 -- |             : p_start_date_to                                     |
 -- | Returns     : x_err_buff                                          |
 -- |             : x_ret_code                                          |
 -- +===================================================================+
   PROCEDURE COMN_FILECPY_REQDETAILS(
                                      x_err_buff      OUT VARCHAR2
                                     ,x_ret_code      OUT NUMBER
                                     ,p_start_date_from IN VARCHAR2 DEFAULT NULL
                                     ,p_start_date_to   IN VARCHAR2 DEFAULT NULL
                                    )
   IS
      ln_source_length     NUMBER :=0;
      ln_dest_length       NUMBER :=0;
      ln_no_data_check     NUMBER;
      lc_source_file       xx_fin_translatevalues.source_value2%TYPE DEFAULT NULL;
      lc_destination_file  xx_fin_translatevalues.source_value3%TYPE DEFAULT NULL;
      ln_length_total      NUMBER :=0;
      
      --The below cursor fetches the those request details that were submitted manually
      --by non-SVC users in order to place files from archive to FTP folders to ensure 
      --BPEL reprocessing of the files which failed processing previously.
      CURSOR lcu_get_request_details(p_source_file IN VARCHAR2
                                    ,p_destination_file IN VARCHAR2
                                    )
      IS 
         SELECT FU.user_name                                                 Requestor
               ,FCR.request_id                                               Request_ID
               ,FCP.user_concurrent_program_name                             Concurrent_Pgm
               ,FL.meaning                                                   Status 
               ,TO_CHAR(FCR.actual_start_date,'DD-MON-YYYY HH24:MI:SS')      Start_Date
               ,TO_CHAR(FCR.actual_completion_date,'DD-MON-YYYY HH24:MI:SS') End_Date
               ,FCR.argument1                                                Source_File
               ,FCR.argument2                                                Destination_File
               ,LENGTH(FCR.argument1)                                        Source_Len
               ,LENGTH(FCR.argument2)                                        Dest_Len
         FROM  FND_CONCURRENT_REQUESTS FCR
              ,FND_CONCURRENT_PROGRAMS_VL FCP
              ,FND_USER FU
              ,FND_LOOKUPS FL
         WHERE FCR.requested_by=FU.user_id
         AND   FCR.program_application_id=FCP.application_id
         AND   FCR.concurrent_program_id=FCP.concurrent_program_id
         AND   FL.lookup_code = FCR.status_code
         AND   FCR.actual_start_date BETWEEN TO_DATE(SUBSTR(p_start_date_from,1,10)|| '00:00:00', 'YYYY/MM/DD HH24:MI:SS') 
                                         AND TO_DATE(SUBSTR(p_start_date_to,1,10)|| '23:59:59', 'YYYY/MM/DD HH24:MI:SS')
         AND   FL.lookup_type = 'CP_STATUS_CODE'
         AND   FCP.concurrent_program_name = 'XXCOMFILCOPY'
         AND   FU.user_name NOT IN (SELECT target_value1 
                                    FROM xx_fin_translatedefinition XXF  
                                        ,xx_fin_translatevalues     XXV
                                    WHERE XXF.translate_id = XXV.translate_id
                                    AND   XXF.translation_name = 'XX_OD_COMMON_COPY_DETAILS'
                                    AND   XXV.source_value1 = 'SVC_User'
                                   )
         AND FCR.argument1 like '%' || p_source_file || '%'
         AND FCR.argument2 like  '%'|| p_destination_file || '%';
   BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_start_date_from:'||p_start_date_from);
      FND_FILE.PUT_LINE(FND_FILE.LOG,'p_start_date_to:'||p_start_date_to);
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'to_date_start_date_from:'||TO_DATE(SUBSTR(p_start_date_from,1,10)|| '00:00:00', 'YYYY/MM/DD HH24:MI:SS'));
      --FND_FILE.PUT_LINE(FND_FILE.LOG,'to_date_start_date_to:'||TO_DATE(SUBSTR(p_start_date_to,1,10)|| '23:59:59', 'YYYY/MM/DD HH24:MI:SS'));
      
      -- The below BEGIN END block is to get the source file convention from a translation. It checks if the source file
      -- parameter contains archive, which implies the file is being transferred from archive using OD: Common File Copy.
      -- As per Defect 1917.
      BEGIN
         SELECT target_value1
         INTO   lc_source_file
         FROM   xx_fin_translatedefinition XXF  
               ,xx_fin_translatevalues     XXV
         WHERE  XXF.translate_id=XXV.translate_id
         AND    XXF.translation_name = 'XX_OD_COMMON_COPY_DETAILS'
         AND    XXV.source_value1 = 'Source_File_Contains';
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010,'Translation does not contain matching the source file value.Define appropriate translation value');
            x_ret_code:=2;
      END;
      
      -- The below BEGIN END block is to get the destination file convention from a translation. It checks if the destination file
      -- parameter contains ftp, which implies the file is being transferred to FTP (for BPEL re-processing) using OD: Common File Copy.
      -- As per Defect 1917.
      BEGIN
         SELECT target_value1
         INTO   lc_destination_file
         FROM   xx_fin_translatedefinition XXF  
               ,xx_fin_translatevalues     XXV
         WHERE  XXF.translate_id=XXV.translate_id
         AND    XXF.translation_name = 'XX_OD_COMMON_COPY_DETAILS'
         AND    XXV.source_value1 = 'Destination_File_Contains';
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20011,'Translation does not contain matching the destination file value.Define appropriate translation value');
            x_ret_code:=2;
      END;
      
      --The below loop is to check if the cursor has data and also fetches the length of the longest file 
      --based on which the headers and data would be aligned.
      FOR lcr_get_length IN lcu_get_request_details(lc_source_file,lc_destination_file)
      LOOP
         ln_no_data_check := lcu_get_request_details%ROWCOUNT;
         ln_source_length        := GREATEST(lcr_get_length.Source_Len,ln_source_length);
         ln_dest_length   := GREATEST(lcr_get_length.Dest_Len,ln_dest_length);
         ln_length_total  := GREATEST(LENGTH(lcr_get_length.requestor)
                                     +LENGTH(lcr_get_length.Request_ID)
                                     +LENGTH(lcr_get_length.Concurrent_Pgm)
                                     +LENGTH(lcr_get_length.Status)
                                     +LENGTH(lcr_get_length.start_date)
                                     +LENGTH(lcr_get_length.end_date)
                                     +LENGTH(lcr_get_length.source_file)
                                     +LENGTH(lcr_get_length.destination_file),ln_length_total);
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'ln_source_length:'||ln_source_length);
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'  ln_dest_length:'||ln_dest_length);
       --FND_FILE.PUT_LINE(FND_FILE.LOG,' ln_length_total:'||ln_length_total);
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'  ln_source_file:'||LENGTH(lcr_get_length.source_file));
       --FND_FILE.PUT_LINE(FND_FILE.LOG,'  ln_destin_file:'||LENGTH(lcr_get_length.destination_file));
      END LOOP;
      
      --The below IF ELSE block is added for alignment of the headers in case of NO_DATA_FOUND. After the above loop
      --if the value for ln_source_length is still 0, it implies that there is no data in the cursor.
      --Since the variable ln_source_length is being made use of, while printing the report headers,
      --we are assigning the below value so that the destination file header is padded sufficiently towards the left 
      --while printing the report headers in case no data is fetched from the cursor .
      IF ln_source_length = 0 THEN
         ln_source_length:= LENGTH('Source File');
      END IF;
      --Printing Report Headers
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('OD: Common File Copy',75));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
      IF ln_length_total != 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',ln_length_total+39,'-'));
      END IF;
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('Requestor',11)
                                      ||RPAD('Request ID',12)
                                      ||RPAD('Concurrent Pgm',30)
                                      ||RPAD('Status',15)
                                      ||RPAD('Start Date',22)
                                      ||RPAD('End Date',22)
                                      ||RPAD('Source File',ln_source_length+5)
                                      ||RPAD('Destination File',ln_dest_length));      
      IF ln_length_total != 0 THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('-',ln_length_total+39,'-'));
      END IF;
      --Printing NO_DATA_FOUND when the cursor fetches no data
      IF ln_no_data_check IS NULL THEN
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('***NO DATA FOUND***',75));
      ELSE
      --Printing the request details of the OD:Common File Copy concurrent Requests that were submitted Ad-Hoc 
      --in order to place files in FTP for BPEL reprocessing.
         FOR lcr_get_request_details IN lcu_get_request_details(lc_source_file,lc_destination_file)
         LOOP
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(lcr_get_request_details.Requestor,11)
                                            ||RPAD(lcr_get_request_details.Request_ID,12)
                                            ||RPAD(lcr_get_request_details.Concurrent_Pgm,30)
                                            ||RPAD(lcr_get_request_details.Status,15)
                                            ||RPAD(lcr_get_request_details.Start_date,22)
                                            ||RPAD(lcr_get_request_details.end_date,22)
                                            ||RPAD(lcr_get_request_details.source_file,ln_source_length+5)
                                            ||RPAD(lcr_get_request_details.destination_file,ln_dest_length));
         END LOOP;
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT,LPAD('***END OF REPORT***',75));
      END IF;
      EXCEPTION
      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error Occured because of:'||SQLERRM);
         x_ret_code:=2;
   END COMN_FILECPY_REQDETAILS;
END XX_COM_FILECPY_REQDETAILS_PKG;

/