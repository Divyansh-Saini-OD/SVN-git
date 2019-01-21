CREATE OR REPLACE
PACKAGE BODY XX_AR_MPS_AOPS_EXTR
AS
 -- +=========================================================================================+
 -- |                  Office Depot - Project Simplify                                        |
 -- |                       WIPRO Technologies                                                |
 -- +=========================================================================================+
 -- | Name :    XX_AR_MPS_AOPS_EXTR                                                           |
 -- | Description : This package will extract MPS data and send it to AOPS                    |
 -- |                                                                                         |
 -- |Change Record:                                                                           |
 -- |===============                                                                          |
 -- |Version   Date          Author              Remarks                                      |
 -- |=======   ==========   =============        =============================================|
 -- |1.0       04/23/2013   Ray Strauss          Initial version                              |
 -- |2.0       11/03/2015   Havish Kasina        Removed the Schema references in the existing|
 -- |                                            code as per R12.2 Retrofit Changes           |
 -- +=========================================================================================+

   PROCEDURE EXTRACT_MPS    ( x_errbuf                       OUT NOCOPY   VARCHAR2
                             ,x_retcode                      OUT NOCOPY   NUMBER
                             )
   IS

lc_file_path             VARCHAR2(200) := 'XXFIN_OUTBOUND';
lc_file_path_copy        VARCHAR2(100) := '$XXFIN_DATA/ftp/out/MPS/';
lc_file_handle           UTL_FILE.FILE_TYPE;
lc_file_name             VARCHAR2(400);
lc_dba_dir_path          VARCHAR2(400);
lc_instance_name         VARCHAR2(10);
ln_req_id                NUMBER;
lc_rec_str               VARCHAR2(200);
lc_lb_wait               BOOLEAN;
lc_conc_phase            VARCHAR2(200);
lc_conc_status           VARCHAR2(200);
lc_dev_phase             VARCHAR2(200);
lc_dev_status            VARCHAR2(200);
lc_conc_message          VARCHAR2(400);

CURSOR mps_extract IS
       SELECT DISTINCT LPAD(aops_cust_number,8,0) AS AOPS_CUST_NUMBER, 
              serial_no 
       FROM   xx_cs_mps_device_b
       WHERE  program_type in ('MPS','ATR');     

BEGIN

      FND_FILE.PUT_LINE(FND_FILE.LOG,'MPS extract for AOPS has begun');
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

      SELECT directory_path
      INTO   lc_dba_dir_path
      FROM   dba_directories
      WHERE  directory_name = lc_file_path ;

	SELECT NAME
      INTO   lc_instance_name
	FROM   v$database;

      lc_file_name   := 'XX_AR_MPS_AOPS_EXTRACT_'||lc_instance_name||'_'||TO_CHAR(SYSDATE,'MMDDYYYY')||'.txt';

      lc_file_handle := UTL_FILE.FOPEN(lc_file_path, lc_file_name, 'W');

      FND_FILE.PUT_LINE(FND_FILE.LOG,'MPS extracting to: '||lc_file_name);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

      FOR extract_rec in mps_extract
          LOOP
          lc_rec_str := extract_rec.aops_cust_number||' '||extract_rec.serial_no;
          UTL_FILE.PUT_LINE ( lc_file_handle, lc_rec_str );
          END LOOP;

      UTL_FILE.FCLOSE(lc_file_handle) ;

      FND_FILE.PUT_LINE(FND_FILE.LOG,'Copying file '||lc_file_name||' to '||lc_file_path_copy);
      FND_FILE.PUT_LINE(FND_FILE.LOG,' ');

      ln_req_id := FND_REQUEST.SUBMIT_REQUEST
                                  (
                                     'XXFIN',
                                     'XXCOMFILCOPY',
                                     '',
                                      SYSDATE,
                                      FALSE,
                                      lc_dba_dir_path||'/'||lc_file_name,
                                      lc_file_path_copy||lc_file_name,
                                     '',
                                     ''
                                   );

      COMMIT;

      IF ln_req_id > 0 THEN
         lc_lb_wait := fnd_concurrent.wait_for_request(
                                      ln_req_id,
                                      10,
                                       0,
                                      lc_conc_phase,
                                      lc_conc_status,
                                      lc_dev_phase,
                                      lc_dev_status,
                                      lc_conc_message
                                                   );
      END IF ;

      IF trim(lc_conc_status) = 'Error' THEN
         FND_FILE.PUT_LINE(fnd_file.log,'Error Occured Copying MPS file. msg = '||lc_conc_message);
      END IF ;

   EXCEPTION

      WHEN OTHERS THEN
         FND_FILE.PUT_LINE(FND_FILE.LOG,'Error - OTHERS: '||sqlcode||' - '||sqlerrm);

END EXTRACT_MPS;

END XX_AR_MPS_AOPS_EXTR;
/
SHOW ERRORS
