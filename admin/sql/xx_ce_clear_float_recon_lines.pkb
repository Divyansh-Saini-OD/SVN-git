SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body xx_ce_clear_float_recon_lines

CREATE OR REPLACE PACKAGE BODY xx_ce_clear_float_recon_lines as
-- +===================================================================================+
-- |                       Office Depot - Project Simplify                             |
-- +===================================================================================+
-- | Name       : xx_ce_clear_float_recon_lines.pkb                                    |
-- | Description: Cash Management Clearing float reconciliation status                 |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |                                                                                   |
-- |Change Record                                                                      |
-- |==============                                                                     |
-- |Version   Date         Authors            Remarks                                  |
-- |========  ===========  ===============    ============================             |
-- |1.0       14-APR-2018  M.Rakesh Reddy     Created the package for Defect#44057     |
-- +===================================================================================+
   -- -------------------------------------------
-- Global Variables
-- ----------------------------------------------

PROCEDURE clear_records(X_ERRBUF              OUT VARCHAR2,
                        X_RETCODE             OUT NUMBER) 
as

ln_trx_id 					NUMBER 	:= 0;
l_user_id 					NUMBER;
l_responsibility_id 		NUMBER;
l_responsibility_appl_id 	NUMBER;
ln_err_code					NUMBER;
lc_err_buff					VARCHAR2(200);



CURSOR c_rec_float_AJB is
	SELECT XCINT.TRX_ID, XCINT.TRX_NUMBER, XCINT.BANK_REC_ID, XCINT.PROCESSOR_ID, XCINT.TRX_TYPE,
	CBA.BANK_ID, CBA.BANK_ACCOUNT_NUM CSH_BANK_ACC_NUMBER, CBA.BANK_ACCOUNT_NAME CSH_BANK_ACC_NAME, 
	CSH.STATEMENT_NUMBER, CSH.STATEMENT_HEADER_ID, CSL.STATEMENT_LINE_ID, CSL.BANK_TRX_NUMBER, 
	CSL.LINE_NUMBER, CSH.STATEMENT_DATE, XCINT.MANUALLY_MATCHED, XCINT.AMOUNT, XCINT.MATCH_AMOUNT
	FROM XX_CE_999_INTERFACE xcint,
		CE_STATEMENT_HEADERS CSH,
		CE_STATEMENT_LINES CSL,
		CE_BANK_ACCOUNTS CBA
	where 1=1
	AND CSH.BANK_ACCOUNT_ID = nvl(CBA.BANK_ACCOUNT_ID,CSH.BANK_ACCOUNT_ID)
	AND CSH.STATEMENT_HEADER_ID = CSL.STATEMENT_HEADER_ID
	AND xcint.statement_line_id = csl.statement_line_id
	AND XCINT.STATEMENT_HEADER_ID = CSH.STATEMENT_HEADER_ID
	AND XCINT.STATUS = 'FLOAT'
	AND (XCINT.X999_GL_COMPLETE='Y' AND XCINT.X998_GL_COMPLETE='Y' AND XCINT.X996_GL_COMPLETE='Y')
	AND XCINT.RECORD_TYPE = 'AJB'
	AND CSL.STATUS = 'RECONCILED'
	AND XCINT.CREATION_DATE BETWEEN TRUNC(SYSDATE-365) AND TRUNC (SYSDATE-1);
	
CURSOR c_rec_float_STORE is
	SELECT XCINT.TRX_ID, XCINT.TRX_NUMBER, XCINT.TRX_TYPE, --XCINT.BANK_REC_ID, XCINT.PROCESSOR_ID, 	
	CBA.BANK_ID, CBA.BANK_ACCOUNT_NUM CSH_BANK_ACC_NUMBER, CBA.BANK_ACCOUNT_NAME CSH_BANK_ACC_NAME, 
	CSH.STATEMENT_NUMBER, CSH.STATEMENT_HEADER_ID, CSL.STATEMENT_LINE_ID, CSL.BANK_TRX_NUMBER, 
	CSL.LINE_NUMBER, CSH.STATEMENT_DATE, XCINT.MANUALLY_MATCHED, XCINT.AMOUNT, XCINT.MATCH_AMOUNT
	FROM XX_CE_999_INTERFACE xcint,
		 CE_STATEMENT_HEADERS CSH,
		 CE_STATEMENT_LINES CSL,
		 CE_BANK_ACCOUNTS CBA
	where 1=1
	AND CSH.BANK_ACCOUNT_ID = nvl(CBA.BANK_ACCOUNT_ID,CSH.BANK_ACCOUNT_ID)
	AND CSH.STATEMENT_HEADER_ID = CSL.STATEMENT_HEADER_ID
	AND xcint.statement_line_id = csl.statement_line_id
	AND XCINT.STATEMENT_HEADER_ID = CSH.STATEMENT_HEADER_ID
	AND XCINT.STATUS = 'FLOAT'
	AND XCINT.EXPENSES_COMPLETE = 'Y'
	AND XCINT.RECORD_TYPE = 'STORE_O/S'
	AND CSL.STATUS = 'RECONCILED'
	AND XCINT.CREATION_DATE BETWEEN TRUNC(SYSDATE-365) AND TRUNC (SYSDATE-1);

BEGIN	
	BEGIN
		ln_trx_id :=0;
		fnd_file.put_line(fnd_file.log,'Processing records for type AJB');
		for rec_line in c_rec_float_AJB
		LOOP
			ln_trx_id := rec_line.TRX_ID;
			 fnd_file.put_line(fnd_file.log,'Calling CE_999_PKG.CLEAR for'                            );
			 fnd_file.put_line(fnd_file.log,'   TRX_ID               = '||rec_line.TRX_ID             );
			 fnd_file.put_line(fnd_file.log,'   TRX_NUMBER           = '||rec_line.TRX_NUMBER         );
			 fnd_file.put_line(fnd_file.log,'   BANK_REC_ID          = '||rec_line.BANK_REC_ID        );
			 fnd_file.put_line(fnd_file.log,'   PROCESSOR_ID         = '||rec_line.PROCESSOR_ID       );
			 fnd_file.put_line(fnd_file.log,'   TRX_TYPE             = '||rec_line.TRX_TYPE           );
			 fnd_file.put_line(fnd_file.log,'   BANK_ID              = '||rec_line.BANK_ID            );
			 fnd_file.put_line(fnd_file.log,'   CSH_BANK_ACC_NUMBER  = '||rec_line.CSH_BANK_ACC_NUMBER);
			 fnd_file.put_line(fnd_file.log,'   CSH_BANK_ACC_NAME    = '||rec_line.CSH_BANK_ACC_NAME  );
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_NUMBER     = '||rec_line.STATEMENT_NUMBER   );
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_HEADER_ID  = '||rec_line.STATEMENT_HEADER_ID);
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_LINE_ID    = '||rec_line.STATEMENT_LINE_ID  );
			 fnd_file.put_line(fnd_file.log,'   BANK_TRX_NUMBER      = '||rec_line.BANK_TRX_NUMBER    );
			 fnd_file.put_line(fnd_file.log,'   LINE_NUMBER          = '||rec_line.LINE_NUMBER        );
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_DATE       = '||rec_line.STATEMENT_DATE     );
			 fnd_file.put_line(fnd_file.log,'   MANUALLY_MATCHED     = '||rec_line.MANUALLY_MATCHED   );
			 fnd_file.put_line(fnd_file.log,'   AMOUNT               = '||rec_line.AMOUNT             );
			 fnd_file.put_line(fnd_file.log,'   MATCH_AMOUNT         = '||rec_line.MATCH_AMOUNT       );
			 fnd_file.put_line(fnd_file.log,'--------------------------------------------------------');
		
			CE_999_PKG.CLEAR (x_trx_id => ln_trx_id
			, x_trx_type         => NULL
			, x_status           => NULL
			, x_trx_number       => NULL
			, x_trx_date         => NULL
			, x_trx_currency     => NULL
			, x_gl_date          => NULL
			, x_bank_currency    => NULL
			, x_cleared_amount   => NULL
			, x_cleared_date     => NULL
			, x_charges_amount   => NULL
			, x_errors_amount    => NULL
			, x_exchange_date    => NULL
			, x_exchange_type    => NULL
			, x_exchange_rate    => NULL
			);
			
			commit;
		
		END LOOP;
		
		if ln_trx_id = 0 then
				fnd_file.put_line(fnd_file.log,'No Records found for AJB to be processed');
				
		end if;
		
	EXCEPTION when OTHERS then
		fnd_file.put_line(fnd_file.log,'Exception occured in AJB for trx_id: '||ln_trx_id||' - '||sqlerrm);
		ln_err_code := 2;
		lc_err_buff := 'Failed for AJB transaction. See log for more details';
	END;
	
		
	BEGIN
		ln_trx_id 	 	:= 0;
		fnd_file.put_line(fnd_file.log,'Processing records for type STORE_O/S');
		for rec_line in c_rec_float_STORE
		LOOP
		ln_trx_id := rec_line.TRX_ID;
			 fnd_file.put_line(fnd_file.log,'Calling CE_999_PKG.CLEAR for'                            );
			 fnd_file.put_line(fnd_file.log,'   TRX_ID               = '||rec_line.TRX_ID             );
			 fnd_file.put_line(fnd_file.log,'   TRX_NUMBER           = '||rec_line.TRX_NUMBER         );
			 --fnd_file.put_line(fnd_file.log,'   BANK_REC_ID          = '||rec_line.BANK_REC_ID        );
			 --fnd_file.put_line(fnd_file.log,'   PROCESSOR_ID         = '||rec_line.PROCESSOR_ID       );
			 fnd_file.put_line(fnd_file.log,'   TRX_TYPE             = '||rec_line.TRX_TYPE           );
			 fnd_file.put_line(fnd_file.log,'   BANK_ID              = '||rec_line.BANK_ID            );
			 fnd_file.put_line(fnd_file.log,'   CSH_BANK_ACC_NUMBER  = '||rec_line.CSH_BANK_ACC_NUMBER);
			 fnd_file.put_line(fnd_file.log,'   CSH_BANK_ACC_NAME    = '||rec_line.CSH_BANK_ACC_NAME  );
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_NUMBER     = '||rec_line.STATEMENT_NUMBER   );
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_HEADER_ID  = '||rec_line.STATEMENT_HEADER_ID);
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_LINE_ID    = '||rec_line.STATEMENT_LINE_ID  );
			 fnd_file.put_line(fnd_file.log,'   BANK_TRX_NUMBER      = '||rec_line.BANK_TRX_NUMBER    );
			 fnd_file.put_line(fnd_file.log,'   LINE_NUMBER          = '||rec_line.LINE_NUMBER        );
			 fnd_file.put_line(fnd_file.log,'   STATEMENT_DATE       = '||rec_line.STATEMENT_DATE     );
			 fnd_file.put_line(fnd_file.log,'   MANUALLY_MATCHED     = '||rec_line.MANUALLY_MATCHED   );
			 fnd_file.put_line(fnd_file.log,'   AMOUNT               = '||rec_line.AMOUNT             );
			 fnd_file.put_line(fnd_file.log,'   MATCH_AMOUNT         = '||rec_line.MATCH_AMOUNT       );
			 fnd_file.put_line(fnd_file.log,'--------------------------------------------------------');
		
			CE_999_PKG.CLEAR (x_trx_id => ln_trx_id
			, x_trx_type         => NULL
			, x_status           => NULL
			, x_trx_number       => NULL
			, x_trx_date         => NULL
			, x_trx_currency     => NULL
			, x_gl_date          => NULL
			, x_bank_currency    => NULL
			, x_cleared_amount   => NULL
			, x_cleared_date     => NULL
			, x_charges_amount   => NULL
			, x_errors_amount    => NULL
			, x_exchange_date    => NULL
			, x_exchange_type    => NULL
			, x_exchange_rate    => NULL
			);
			
		commit;
		END LOOP;
		if ln_trx_id = 0 then
				fnd_file.put_line(fnd_file.log,'No Records found for Store O/S to be processed'); 
		end if;	
	EXCEPTION when OTHERS then
		fnd_file.put_line(fnd_file.log,'Exception occured in Store O/S for trx_id: '||ln_trx_id||' - '||sqlerrm); 
		X_RETCODE := 2;
		X_ERRBUF  := 'Failed for STORE O/S transaction. See log for more details';
	END;
	
	if(ln_err_code > 0  or x_retcode > 0)
	then	
		x_retcode := 2;
		X_ERRBUF  := lc_err_buff||' '||X_ERRBUF;
	end if;
	
EXCEPTION when OTHERS then
	fnd_file.put_line(fnd_file.log,'Exception for trx_id: '||ln_trx_id||' - '||sqlerrm);
END clear_records;
END xx_ce_clear_float_recon_lines;
/
show err