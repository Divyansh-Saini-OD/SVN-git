create or replace PACKAGE BODY XX_FIN_VPS_PURGE_PKG
as
-- =========================================================================================================================
--   NAME:       XX_FIN_VPS_PURGE_PKG .
--   PURPOSE:    This package used to delete all the stagging tables data used in VPS based on specific duration. 
--   REVISIONS:
--   Ver        Date        Author           Description
--   ---------  ----------  ---------------  -------------------------------------------------------------------------------
--   1.0        23/10/2017  Uday Jadhav      Created this package. 
-- =========================================================================================================================
	procedure purge_process(
							p_errbuf_out              OUT      VARCHAR2
							,p_retcod_out              OUT      VARCHAR2 
						)
	AS					   
	v_purge_duration NUMBER;
	BEGIN
		
		BEGIN
			SELECT target_value1 INTO  v_purge_duration
							FROM xx_fin_translatedefinition xftd
								, xx_fin_translatevalues xftv
							WHERE xftv.translate_id = xftd.translate_id
							AND xftd.translation_name ='OD_VPS_TRANSLATION'
							AND source_value1='STAGING_TBLS_PURGE_DURATION'
							AND NVL (xftv.enabled_flag, 'N') = 'Y';
							
			EXCEPTION
			WHEN OTHERS THEN
				fnd_file.put_line(fnd_file.log,sqlerrm); 
		END;
		
		
	/*	DELETE 
			FROM 
				XX_AR_VPS_CMINV_HDR 
			WHERE 
				trunc(creation_date) <=trunc(sysdate-v_purge_duration);
		
			fnd_file.put_line(fnd_file.log,'XX_AR_VPS_CMINV_HDR Records Deleted:'||SQL%ROWCOUNT); */
		
		DELETE 
			FROM 
				XX_FIN_VPS_RECEIPTS_STG 
			WHERE 
				receipt_date <=	sysdate-v_purge_duration;  
		
			fnd_file.put_line(fnd_file.log,'XX_FIN_VPS_RECEIPTS_STG Records Deleted:'||SQL%ROWCOUNT);
		
		DELETE 
			FROM 
				XX_FIN_VPS_STMT_BACKUP_DATA 
			WHERE 
				TRUNC(creation_date) <=TRUNC(sysdate-v_purge_duration);
		
			fnd_file.put_line(fnd_file.log,'XX_FIN_VPS_STMT_BACKUP_DATA Records Deleted:'||SQL%ROWCOUNT);
		
		DELETE 
			FROM 
				XX_FIN_VPS_TRX_STG 
			WHERE		
				TRUNC(creation_date) <=TRUNC(sysdate-v_purge_duration);
		
			fnd_file.put_line(fnd_file.log,'XX_FIN_VPS_TRX_STG Records Deleted:'||SQL%ROWCOUNT);
		
		DELETE 
			FROM 
				XX_CDH_VPS_CUSTOMER_STG 
			WHERE TRUNC(creation_date) <=TRUNC(sysdate-v_purge_duration); 
			fnd_file.put_line(fnd_file.log,'XX_CDH_VPS_CUSTOMER_STG Records Deleted:'||SQL%ROWCOUNT); 
		
		DELETE 
			FROM 
				XX_FIN_VPS_SYS_NETTING_STG 
			WHERE TRUNC(creation_date) <=TRUNC(sysdate-v_purge_duration); 
			fnd_file.put_line(fnd_file.log,'XX_FIN_VPS_SYS_NETTING_STG Records Deleted:'||SQL%ROWCOUNT); 
		
    COMMIT;
    
		EXCEPTION WHEN OTHERS THEN
		fnd_file.put_line(fnd_file.log,sqlerrm);  
	END; 
END;
/