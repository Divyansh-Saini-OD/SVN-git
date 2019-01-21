CREATE OR REPLACE PACKAGE BODY APPS.XX_GL_EUR_RATES_PKG
AS
-- OD GL Create Send EUR Rates
-- +==========================================================================+
-- |                  Office Depot - Project Simplify                         |
-- |                            Providge                                      |
-- +==========================================================================+
-- | Name             :    XX_GL_EUR_RATES_PKG                                |
-- | Description      :    Package for send Euro rates to Europe IT Team      |
-- | RICE             :    I2122                                              |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version   Date         Author              Remarks                        |
-- |=======   ===========  ================    ========================       |
-- | 1.0      3-Nov-2013   Paddy Sanjeevi      Defect 25578                   |
-- | 1.1      9-DEC-2013   Paddy Sanjeevi      Modified to add XXGLEURP       |
-- +==========================================================================+

PROCEDURE send_rates          ( p_errbuf   		IN OUT    VARCHAR2
                               ,p_retcode  		IN OUT    NUMBER
                               ,p_date 	 	IN 	VARCHAR2
                              )
IS

  v_request_id 		NUMBER;
  v_phase		varchar2(100)   ;
  v_status		varchar2(100)   ;
  x_dummy		varchar2(2000) 	;
  v_dphase		varchar2(100)	;
  v_dstatus		varchar2(100)	;

  vc_request_id 	NUMBER;



  v_wait 		BOOLEAN;

  v_file_name 		varchar2(250);
  v_dfile_name		varchar2(250);
  v_sfile_name 		varchar2(250);
  x_cdummy		varchar2(2000) 	;
  v_cdphase		varchar2(100)	;
  v_cdstatus		varchar2(100)	;
  v_cphase		varchar2(100)   ;
  v_cstatus		varchar2(100)   ;

  v_timestamp		VARCHAR2(20);
  v_avg_date		VARCHAR2(25);

BEGIN

  v_timestamp:=TO_CHAR(SYSDATE,'MMDDYYYY');

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXGLEURP','OD GL EUR Rates File Purge',NULL,FALSE);

  IF v_request_id>0 THEN
     COMMIT;

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Submitted OD GL EUR Rates File Purge request id : '||TO_CHAR(v_request_id));

    IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
       IF v_dphase = 'COMPLETE' THEN

	  FND_FILE.PUT_LINE(FND_FILE.LOG, 'OD GL EUR Rates File Purge Completed');

       END IF;

    END IF;

  END IF;

  v_request_id:=0;

  -- Submitting concurrent program EUR Daily Rates and moving the file to XXFIN_DATA/ftp/out/eur_rates

  v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXGLCREATEANDSENDRATEFILES','OD: GL Create and Send Rate Files',NULL,FALSE,
					    p_date,'EUR_DAILY','Y','N','FX'
			    		   );
  IF v_request_id>0 THEN
     COMMIT;

     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Create Daily Rates request id : '||TO_CHAR(v_request_id));

     IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			v_status,v_dphase,v_dstatus,x_dummy))  THEN
        IF v_dphase = 'COMPLETE' THEN

           v_file_name  :='$XXFIN_DATA/outbound/'||'EUR_DAILY_RATES.TXT';
           v_dfile_name :='$XXFIN_DATA/ftp/out/eur_rates/'||'EUR_DAILY_RATES_'||v_timestamp||'.txt';

           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Source File Name : '||v_file_name);
           FND_FILE.PUT_LINE(FND_FILE.LOG, 'Target File Name : '||v_dfile_name);

           vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

   	   IF vc_request_id>0 THEN
	      COMMIT;
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Copying Daily Rates request id : '||TO_CHAR(vc_request_id));
           END IF;
       END IF;
    END IF;

  END IF;

  v_request_id:=0;
  vc_request_id:=0;
  v_file_name:=NULL;
  v_dfile_name:=NULL;

  -- Submitting concurrent program EUR Average Rates and moving the file to XXFIN_DATA/ftp/out/eur_rates


  IF TO_CHAR(SYSDATE,'DD')='01' THEN

     v_avg_date:=to_char(sysdate-1,'MM-DD-RRRR');

     v_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXGLCREATEANDSENDRATEFILES','OD: GL Create and Send Rate Files',NULL,FALSE,
					    v_avg_date,'EUR_AVG','Y','N','FX'
			    		   );
     IF v_request_id>0 THEN
        COMMIT;
        FND_FILE.PUT_LINE(FND_FILE.LOG, 'Create Average Rates request id : '||TO_CHAR(v_request_id));


       IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
			     	           v_status,v_dphase,v_dstatus,x_dummy))  THEN

          IF v_dphase = 'COMPLETE' THEN

             v_file_name  :='$XXFIN_DATA/outbound/'||'EUR_AVG_RATES.TXT';
             v_dfile_name :='$XXFIN_DATA/ftp/out/eur_rates/'||'EUR_AVG_RATES_'||v_timestamp||'.txt';


             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Source File Name : '||v_file_name);
             FND_FILE.PUT_LINE(FND_FILE.LOG, 'Target File Name : '||v_dfile_name);

             vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
 			  v_file_name,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);

  	     IF vc_request_id>0 THEN
 	        COMMIT;
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Copying Averate Rates request id : '||TO_CHAR(vc_request_id));
             END IF;

          END IF;  --       IF v_dphase = 'COMPLETE' THEN

       END IF;     --        IF (FND_CONCURRENT.WAIT_FOR_REQUEST(v_request_id,1,60000,v_phase,
 
     END IF;  --      IF v_request_id>0 THEN

  END IF; --IF TO_CHAR(SYSDATE,'DD')='01' THEN

EXCEPTION
   WHEN others THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while running program');
    FND_FILE.PUT_LINE(FND_FILE.LOG, SQLERRM);
END send_rates;

END XX_GL_EUR_RATES_PKG;

/
