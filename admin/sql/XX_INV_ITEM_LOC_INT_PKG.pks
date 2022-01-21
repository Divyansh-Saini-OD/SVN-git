create or replace
PACKAGE BODY      XX_INV_ITEM_LOC_INT_PKG
IS
-- +=====================================================================+
-- |                  Office Depot - Project Simplify                    |
-- |                       Oracle  - GSD                                 |
-- +=====================================================================+
-- | Name : XX_INV_ITEM_LOC_INT_PKG                                      |
-- | Defect ID : 10266               XX_INV_ITEM_LOC_INT_PKG             |
-- | Description : This package houses Update the Item Parameters        |
-- |              and Updated Items report                               |
-- |              OD: Reset Item Interface Parameters                    |
-- | Change Record:                                                      |
-- |===============                                                      |
-- |Version   Date              Author              Remarks              |
-- |======   ==========     =============        ======================= |
-- |1.0      07-Apr-2011    Sai Kumar Reddy        			                 |
-- |1.1      29-May-2012    Oracle AMS Team  Added the code logic for    |
-- |                                         tuning the performance and  |
-- |                                         introduced action_type='A'  |
-- |                                         for item locations as well. |
-- |                                         Changed the to_date parameter|
-- |                                         for proper range and exception| 
-- |                                         handling for DL List        |
-- +=====================================================================+

-- +=====================================================================+
-- | Procedure Name :  XX_INV_MAIN                                       |
-- | Description : This procedure will Update the Item Parameters        |
-- |               reports			                         |
-- | Parameters  : P_MODE_SELECT					 |
-- | Returns     : errMsg,errCode		                         |
-- +=====================================================================+
PROCEDURE XX_INV_MAIN(
					errCode OUT NUMBER,
					errMsg OUT VARCHAR2,
					P_MODE_SELECT IN VARCHAR2,
					P_PROCESS IN VARCHAR2,
					P_FROM_DATE IN VARCHAR2,
					P_TO_DATE IN VARCHAR2
					)
AS
l_p_from_date DATE;
l_p_to_date DATE;
l_p_process varchar2(10);
 BEGIN
  IF P_FROM_DATE IS NULL THEN
    l_p_from_date := SYSDATE-1;
  ELSE
    l_p_from_date := fnd_date.canonical_to_date(P_FROM_DATE);
  END IF;
  IF P_TO_DATE IS NULL THEN
    l_p_to_date := SYSDATE;
  ELSE
    l_p_to_date := fnd_date.canonical_to_date(P_TO_DATE)+ 1 -1/(24*60*60);--Added by Oracle AMS Team Defect# 10266
  END IF;

  IF P_MODE_SELECT = 'N' THEN
  BEGIN
	IF P_PROCESS IN ('MA','MC') THEN

    fnd_file.put_line(fnd_file.log, 'Inside  P_PROCESS '||P_PROCESS) ;
                UPDATE xxptp.xx_inv_item_master_int
                SET process_flag=1,load_batch_id=null,last_update_date = SYSDATE,last_updated_by = fnd_global.user_id
                WHERE creation_date between  l_p_from_date and l_p_to_date
		AND VALIDATION_ORGS_STATUS_FLAG<>'S'
		AND process_Flag=6  -- Updated by Oracle AMS Team Defect# 10266
		AND ERROR_MESSAGE LIKE '%Validation%Org%Assignment%'  -- Updated by Ankit for defect 10266
		AND action_type='A';

		fnd_file.put_line(fnd_file.log, 'Number of records updated: '||SQL%ROWCOUNT);
		COMMIT;

	END IF;

	IF P_PROCESS IN ('LA','LC') THEN

	fnd_file.put_line(fnd_file.log, 'Inside  P_PROCESS '||P_PROCESS);

		UPDATE xxptp.xx_inv_item_loc_int a
		SET PROCESS_FLAG=1,LOAD_BATCH_ID=NULL,LAST_UPDATE_DATE = SYSDATE,LAST_UPDATED_BY = FND_GLOBAL.USER_ID
		WHERE CREATION_DATE BETWEEN  L_P_FROM_DATE AND L_P_TO_DATE
		AND LOCATION_PROCESS_FLAG=3
		AND PROCESS_FLAG=6  -- Updated by Oracle AMS Team Defect# 10266
    AND action_type='A';  --Added by Oracle AMS Team Defect# 10266

                fnd_file.put_line(fnd_file.log, 'Number of records updated: '||SQL%ROWCOUNT);
		COMMIT;

	END IF;

	l_p_process := P_PROCESS;
	XX_INV_ITEM_LOC_INT_PKG.XX_INV_ITM_REPORT(errCode,errMsg,l_p_from_date,l_p_to_date,l_p_process);

	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		fnd_file.put_line(fnd_file.log, 'No Data Found for Update');
	WHEN OTHERS THEN
		errMsg  := 'Request failed - unknown error: ' || sqlerrm;
		errCode := 2;
     		fnd_file.put_line(fnd_file.log, errMsg);

  END;
	 -- Start of Addition by Oracle AMS Team Defect# 10266
  ELSE
	l_p_process := P_PROCESS;
	XX_INV_ITEM_LOC_INT_PKG.XX_INV_ITM_REPORT_Y(errCode,errMsg,l_p_from_date,l_p_to_date,l_p_process);
  END IF;


  l_p_process := P_PROCESS;
  --XX_INV_ITEM_LOC_INT_PKG.XX_INV_ITM_REPORT(errCode,errMsg,l_p_from_date,l_p_to_date,l_p_process);

EXCEPTION
WHEN OTHERS THEN
  errMsg  := 'Request failed - unknown error: ' || sqlerrm;
  errCode := 2;
  fnd_file.put_line(fnd_file.log, errMsg);

END XX_INV_MAIN;

PROCEDURE XX_INV_ITM_REPORT( errCode 	 OUT NUMBER,
							errMsg 		 OUT VARCHAR2,
							P_FROM_DATE IN DATE,
							P_TO_DATE IN DATE,
              P_PROCESS IN VARCHAR2 )
AS
  l_us VARCHAR2(1) := '-';
  l_space VARCHAR2(2) := '  ';
  l_line  VARCHAR2(500);
  l_cnt   NUMBER := 0;
  l_tot_cnt   NUMBER := 0;
  l_status varchar2(10);
  l_email_flag		VARCHAR2(1)		:= 'N';
  l_req_id			NUMBER		DEFAULT NULL;
  l_mail_receipent varchar2(100);
BEGIN
  l_line := rpad(l_us,100,'-');
  fnd_file.put_line(fnd_file.output,rpad('Office Depot',25,' ') ||rpad('OD Items Reprocessed',50,' ')||rpad('Date: '||TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),25,' '));
  fnd_file.put_line(fnd_file.output,'From Date    : ' ||  P_FROM_DATE);
  fnd_file.put_line(fnd_file.output,'To Date      : ' || P_TO_DATE);
  fnd_file.put_line(fnd_file.output,'Process      : ' || P_PROCESS);
  fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));
  fnd_file.put_line(fnd_file.output,rpad('Location',15,' ') || rpad('Error Message',15,' ') ||lpad('Count',30,' '));
  fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));

  IF P_PROCESS IN ('LA','LC') THEN
  FOR XX_INV_ITM_CUR IN
  (
	  SELECT loc,  count(*) cnt
	  FROM XXPTP.XX_INV_ITEM_LOC_INT
	  WHERE CREATION_DATE  BETWEEN P_FROM_DATE AND P_TO_DATE
	  AND LOCATION_PROCESS_FLAG=3
	  AND PROCESS_FLAG=1
    AND action_type='A'--Added by Oracle AMS Team Defect# 10266
	  group by loc
  )

  LOOP
  fnd_file.put_line(fnd_file.output,rpad(XX_INV_ITM_CUR.loc,15,' ') || lpad(XX_INV_ITM_CUR.cnt,43,' '));
	l_cnt := l_cnt + 1;
	l_tot_cnt := l_tot_cnt + XX_INV_ITM_CUR.cnt;
  END LOOP;

 IF l_cnt > 0 THEN
    fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));
    fnd_file.put_line(fnd_file.output,'Total Number of records processed: ' || rpad(l_tot_cnt,20,' '));
    l_email_flag := 'Y';
  ELSE
	fnd_file.put_line(fnd_file.output,'********No Data found********');
    l_email_flag := 'Y';
  END IF;
  END IF;

  --Added done by Oracle AMS Team Defect# 10266
  IF P_PROCESS IN ('MA','MC') THEN
  FOR XX_INV_ITM_CUR_MAS IN
  (
	  SELECT error_message,  count(*) cnt
	  FROM XXPTP.xx_inv_item_master_int
	  WHERE creation_date  between P_FROM_DATE and P_TO_DATE
	  AND validation_orgs_status_flag<>'S'
		AND process_Flag=1  -- Updated by Oracle AMS Team Defect# 10266
		AND error_message like '%Validation%Org%Assignment%'  -- Updated by Ankit for defect 10266
		AND action_type='A'
	  group by error_message
  )

  LOOP
  fnd_file.put_line(fnd_file.output,lpad(XX_INV_ITM_CUR_MAS.error_message,47,' ') || lpad(XX_INV_ITM_CUR_MAS.cnt,10,' '));
  	l_cnt := l_cnt + 1;
	l_tot_cnt := l_tot_cnt + XX_INV_ITM_CUR_MAS.cnt;
  END LOOP;

	   IF l_cnt > 0 THEN
	    fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));
	    fnd_file.put_line(fnd_file.output,'Total Number of records processed: ' || rpad(l_tot_cnt,20,' '));
	    l_email_flag := 'Y';
	  ELSE
		fnd_file.put_line(fnd_file.output,'********No Data found********');
	    l_email_flag := 'Y';
	  END IF;
	  END IF;

	  --End of Addition by Oracle AMS Team Defect# 10266
  ----------For sending the Mail----------
 IF l_email_flag = 'Y' THEN
		FND_FILE.PUT_LINE(fnd_file.log,'preparing to send email alert ');

 --Handling exception block. Done by Oracle AMS Team Defect# 10266
BEGIN

        SELECT FLV.MEANING
        INTO l_mail_receipent
      FROM fnd_lookup_values_vl flv,fnd_application_tl fat
      WHERE flv.lookup_type = 'XX_OD_SCM_DL_MAIL_LIST'
      AND FLV.ENABLED_FLAG = 'Y'
      AND SYSDATE BETWEEN FLV.START_DATE_ACTIVE
      AND NVL (FLV.END_DATE_ACTIVE, SYSDATE + 1)
      AND fat.application_id = flv.view_application_id
      AND fat.application_name = 'Application Utilities'--Common Lookup from Applicaction Developers
      AND fat.language= userenv('LANG');
      
      
      	 EXCEPTION

              WHEN NO_DATA_FOUND THEN
    					FND_FILE.PUT_LINE(FND_FILE.LOG, ' No DL attached for the Mail List :::');
              WHEN TOO_MANY_ROWS THEN
    					FND_FILE.PUT_LINE(FND_FILE.LOG, ' Multiple DL-s attached for the Mail List :::');
              WHEN OTHERS THEN
    					FND_FILE.PUT_LINE(FND_FILE.LOG, ' Mailing List Went into Exception :::');
                        
    END;

		l_req_id := FND_REQUEST.SUBMIT_REQUEST
                                ('xxfin'
                                ,'XXODROEMAILER'
                                ,''
                                ,''
                                ,FALSE
                                ,'OD INV Item Interface Reprocess'
                                , l_mail_receipent
                                ,' OD INV Item Interface Reprocess'
                                ,' OD INV Item Interface Reprocess'
                                ,'Y'
                                ,FND_GLOBAL.CONC_REQUEST_ID);
	END IF;

EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Report Generation Failed'||sqlerrm);
END XX_INV_ITM_REPORT;


--Addition done by Oracle AMS Team Defect# 10266
-------------------------------------------
PROCEDURE XX_INV_ITM_REPORT_Y( errCode 	 OUT NUMBER,
							errMsg 		 OUT VARCHAR2,
							P_FROM_DATE IN DATE,
							P_TO_DATE IN DATE,
              P_PROCESS IN VARCHAR2 )
AS
  l_us VARCHAR2(1) := '-';
  l_space VARCHAR2(2) := '  ';
  l_line  VARCHAR2(500);
  l_cnt   NUMBER := 0;
  l_tot_cnt   NUMBER := 0;
  l_status varchar2(10);
  l_email_flag		VARCHAR2(1)		:= 'N';
  l_req_id			NUMBER		DEFAULT NULL;
  l_mail_receipent varchar2(100);
  BEGIN
  l_line := rpad(l_us,100,'-');
  fnd_file.put_line(fnd_file.output,rpad('Office Depot',25,' ') ||rpad('OD Items to be Reprocessed',50,' ')||rpad('Date: '||TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'),25,' '));
  fnd_file.put_line(fnd_file.output,'From Date    : ' ||  P_FROM_DATE);
  fnd_file.put_line(fnd_file.output,'To Date      : ' || P_TO_DATE);
  fnd_file.put_line(fnd_file.output,'Process      : ' || P_PROCESS);
  fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));
  fnd_file.put_line(fnd_file.output,rpad('Location',15,' ') || rpad('Error Message',15,' ') ||lpad('Count',30,' '));
  fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));

    IF P_PROCESS IN ('LA','LC') THEN
	 FOR XX_INV_ITM_CUR1 IN
  (
	  SELECT loc,  count(*) cnt
	  FROM XXPTP.XX_INV_ITEM_LOC_INT
	  WHERE CREATION_DATE  BETWEEN P_FROM_DATE AND P_TO_DATE
	  AND LOCATION_PROCESS_FLAG=3
	  AND PROCESS_FLAG=6
    AND action_type='A'--Added by Oracle AMS Team Defect# 10266
	  group by loc
  )

  LOOP
  fnd_file.put_line(fnd_file.output,rpad(XX_INV_ITM_CUR1.loc,15,' ') || lpad(XX_INV_ITM_CUR1.cnt,43,' '));
  	l_cnt := l_cnt + 1;
	l_tot_cnt := l_tot_cnt + XX_INV_ITM_CUR1.cnt;
  END LOOP;

	   IF l_cnt > 0 THEN
	    fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));
	    fnd_file.put_line(fnd_file.output,'Total Number of records needs to be processed: ' || rpad(l_tot_cnt,20,' '));
	    l_email_flag := 'Y';
	  ELSE
		fnd_file.put_line(fnd_file.output,'********No Data found********');
	    l_email_flag := 'Y';
	  END IF;
    END IF;

	IF P_PROCESS IN ('MA','MC') THEN
	 FOR XX_INV_ITM_CUR2 IN
  (
	  SELECT error_message,  count(*) cnt
	  FROM XXPTP.xx_inv_item_master_int
	  WHERE creation_date  between P_FROM_DATE and P_TO_DATE
	  AND validation_orgs_status_flag<>'S'
		AND process_Flag=6  -- Updated by Oracle AMS Team Defect# 10266
		AND error_message like '%Validation%Org%Assignment%'  -- Updated by Ankit for defect 10266
		AND action_type='A'
	  group by error_message
  )

  LOOP
  fnd_file.put_line(fnd_file.output,lpad(XX_INV_ITM_CUR2.error_message,47,' ') || lpad(XX_INV_ITM_CUR2.cnt,10,' '));
  	l_cnt := l_cnt + 1;
	l_tot_cnt := l_tot_cnt + XX_INV_ITM_CUR2.cnt;
  END LOOP;

	   IF l_cnt > 0 THEN
	    fnd_file.put_line(fnd_file.output,rpad('-',100,'-'));
	    fnd_file.put_line(fnd_file.output,'Total Number of records needs to be processed: ' || rpad(l_tot_cnt,20,' '));
	    l_email_flag := 'Y';
	  ELSE
		fnd_file.put_line(fnd_file.output,'********No Data found********');
	    l_email_flag := 'Y';
	  END IF;

    END IF;
	----------For sending the Mail----------
 IF l_email_flag = 'Y' THEN
		FND_FILE.PUT_LINE(fnd_file.log,'preparing to send email alert ');

--Handling exception block. Done by Oracle AMS Team Defect# 10266
BEGIN

        SELECT FLV.MEANING
        INTO l_mail_receipent
      FROM fnd_lookup_values_vl flv,fnd_application_tl fat
      WHERE flv.lookup_type = 'XX_OD_SCM_DL_MAIL_LIST'
      AND FLV.ENABLED_FLAG = 'Y'
      AND SYSDATE BETWEEN FLV.START_DATE_ACTIVE
      AND NVL (FLV.END_DATE_ACTIVE, SYSDATE + 1)
      AND fat.application_id = flv.view_application_id
      AND fat.application_name = 'Application Utilities'--Common Lookup from Applicaction Developers
      AND fat.language= userenv('LANG');
      
      
      	 EXCEPTION

              WHEN NO_DATA_FOUND THEN
    					FND_FILE.PUT_LINE(FND_FILE.LOG, ' No DL attached for the Mail List :::');
              WHEN TOO_MANY_ROWS THEN
    					FND_FILE.PUT_LINE(FND_FILE.LOG, ' Multiple DL-s attached for the Mail List :::');
              WHEN OTHERS THEN
    					FND_FILE.PUT_LINE(FND_FILE.LOG, ' Mailing List Went into Exception :::');
                        
    END;

		l_req_id := FND_REQUEST.SUBMIT_REQUEST
                                ('xxfin'
                                ,'XXODROEMAILER'
                                ,''
                                ,''
                                ,FALSE
                                ,'OD INV Item Interface Reprocess'
                                , l_mail_receipent
                                ,' OD INV Item Interface Reprocess'
                                ,' OD INV Item Interface Reprocess'
                                ,'Y'
                                ,FND_GLOBAL.CONC_REQUEST_ID);
	END IF;

EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'Report Generation Failed'||sqlerrm);
	-- End of Addition by Oracle AMS Team Defect# 10266
	END;

END XX_INV_ITEM_LOC_INT_PKG;
/
