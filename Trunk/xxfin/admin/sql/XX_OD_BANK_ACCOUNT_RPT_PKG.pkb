SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET TERM ON

PROMPT Creating PACKAGE Body XX_OD_BANK_ACCOUNT_RPT_PKG
PROMPT Program exits IF the creation is not successful

WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE
PACKAGE BODY XX_OD_BANK_ACCOUNT_RPT_PKG
AS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle GSD		                             |
-- +=====================================================================+
-- | Name : XX_OD_BANK_ACCOUNT_RPT_PKG                                   |
-- | Defect# 13836		                                                 |
-- | Description : This package houses the report submission procedure   |
-- |              									                     |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |Draft 1A  13-Jan-2012   Sai Kumar Reddy      Initial version         |
-- +=====================================================================+

-- +=====================================================================+
-- | Name :  XX_OD_BANK_ACCOUNT_PRC                                      |
-- | Description : This procedure will submit the New Bank Account		 |
-- |               report			                                     |
-- | Parameters  : P_PERIOD									             |
-- | Returns     : x_err_buff,x_ret_code                                 |
-- +=====================================================================+

PROCEDURE XX_OD_BANK_ACCOUNT_PRC (
                                   x_err_buff    OUT VARCHAR2,
                                   x_ret_code    OUT NUMBER,
                                   P_PERIOD 		 IN VARCHAR2,
                                   P_FORMAT      IN VARCHAR2 DEFAULT 'EXCEL'
                                 )
AS

 ln_srequest_id NUMBER(15);

 lb_sreq_status  BOOLEAN;

 lb_layout       BOOLEAN;


 lc_sphase       VARCHAR2(50);
 lc_sstatus      VARCHAR2(50);
 lc_sdevphase    VARCHAR2(50);
 lc_sdevstatus   VARCHAR2(50);
 lc_smessage     VARCHAR2(50);

  lc_xptr_name       xx_fin_translatevalues.target_value1%TYPE;
  l_file_name        fnd_concurrent_requests.outfile_name%TYPE;
  l_out_dir          VARCHAR2(100);
  lp_filename        fnd_conc_req_outputs.file_name%TYPE;
  lp_file_type       fnd_conc_req_outputs.file_type%TYPE;  
  l_request_id       NUMBER;

BEGIN
	   IF (P_FORMAT IS NULL OR P_FORMAT IN ('EXCEL','PDF')) THEN

		   lb_layout := FND_REQUEST.ADD_LAYOUT(
											  'XXFIN'
											 ,'XXODNEWBANKACCOUNT'
											 ,'en'
											 ,'US'
											 ,NVL(P_FORMAT,'EXCEL')
											 );
											 
		   ln_srequest_id := FND_REQUEST.SUBMIT_REQUEST(application =>'XXFIN',
														program   =>'XXODNEWBANKACCOUNT',
														argument1 => P_PERIOD
													   );
		  COMMIT;

		  IF ln_srequest_id IS NOT NULL THEN	

        fnd_file.put_line(fnd_file.log,'Report is Submitted for following parameters');
        fnd_file.put_line(fnd_file.log,'Period: '||P_PERIOD);
        fnd_file.put_line(fnd_file.log,'Output Format: '||NVL(P_FORMAT,'EXCEL'));
      
			  lb_sreq_status := FND_CONCURRENT.WAIT_FOR_REQUEST(
																request_id => ln_srequest_id
															   ,interval   => '2'
															   ,max_wait   => NULL
															   ,phase      => lc_sphase
															   ,status     => lc_sstatus
															   ,dev_phase  => lc_sdevphase
															   ,dev_status => lc_sdevstatus
															   ,message    => lc_smessage
															   );


					  IF (UPPER(lc_sstatus) = 'ERROR') THEN

						  x_err_buff := 'The Report Completed in ERROR';
						  x_ret_code := 2;

					  ELSIF (UPPER(lc_sstatus) = 'WARNING') THEN

						  x_err_buff := 'The Report Completed in WARNING';
						  x_ret_code := 1;

					  ELSE

						  x_err_buff := 'The Report Completion is NORMAL';
						  x_ret_code := 0;

					  END IF;
		--Invoke File copy program to copy lockbox output file to XPTR
			
			IF nvl(fnd_profile.value_specific('XX_FIN_DISABLE_XPTR_OP'),
				   'N') = 'N'
			THEN
			
			  BEGIN
				SELECT substr(val.target_value1,3)
				  INTO lc_xptr_name
				  FROM xx_fin_translatedefinition def
					  ,xx_fin_translatevalues     val
				 WHERE def.translate_id = val.translate_id
				   AND def.translation_name = 'XXOD_FIN_XPTR'
				   AND val.source_value1 = 'XXODNEWBANKACCOUNT'
				   AND SYSDATE BETWEEN def.start_date_active AND
					   nvl(def.end_date_active,
						   SYSDATE + 1)
				   AND SYSDATE BETWEEN val.start_date_active AND
					   nvl(val.end_date_active,
						   SYSDATE + 1)
				   AND def.enabled_flag = 'Y'
				   AND val.enabled_flag = 'Y';
				IF lc_xptr_name IS NOT NULL
				THEN
				  l_out_dir := '/app/xptrrs/orarpt/orclcm/' || lc_xptr_name;
				ELSE
				  l_out_dir    := '/app/xptrrs/orarpt/orclcm/CMBANKAC';
				END IF;
			  EXCEPTION
				WHEN OTHERS THEN
				  lc_xptr_name := NULL;
				  l_out_dir    := '/app/xptrrs/orarpt/orclcm/CMBANKAC';
			  END;
			
			  BEGIN
			  
				SELECT file_name,decode(file_type,'EXCEL','XLS',file_type)
				  INTO l_file_name,lp_file_type
				  FROM fnd_conc_req_outputs
				 WHERE concurrent_request_id = ln_srequest_id;
			  
			  EXCEPTION
				WHEN OTHERS THEN
				  l_file_name := NULL;
			  END;
			  IF l_file_name IS NOT NULL
			  THEN
				l_out_dir  := l_out_dir || ln_srequest_id || '.'||lp_file_type;
				l_request_id := fnd_request.submit_request(application => 'XXFIN',
														   program     => 'XXCOMFILCOPY',
														   description => 'OD: Common File Copy',
														   start_time  => to_char(SYSDATE,
																				  'DD-MON-YY HH24:MI:SS'),
														   sub_request => FALSE,
														   argument1   => l_file_name,
														   argument2   => l_out_dir);
				IF l_request_id = 0
				THEN
				  fnd_file.put_line(fnd_file.log,
									'+----------------------------------------------------------------+');
				  fnd_file.put_line(fnd_file.log,
									'                                                                  ');
				  fnd_file.put_line(fnd_file.log,
									'XPTR Program is not invoked');
				ELSE
				  fnd_file.put_line(fnd_file.log,
									'XPTR Program to transfer file to XNET is invoked, requeust id is" ' || l_request_id);
				  COMMIT;
				END IF;
			  END IF;
			END IF;					  
		  ELSE
			fnd_file.put_line(fnd_file.log,'Report Not Submitted');
		  END IF;
	  ELSE
			fnd_file.put_line(fnd_file.log,'Output Format Error, Please select output as ''EXCEL'' or ''PDF''');
	  END IF;
	EXCEPTION
    WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log,'Report Submision failed'||SUBSTR(SQLERRM,1,30)); 	 
END XX_OD_BANK_ACCOUNT_PRC;
END XX_OD_BANK_ACCOUNT_RPT_PKG;
/