SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Body XX_IBY_STORE_MERCH_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_IBY_STORE_MERCH_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Loading the Store, Merchant Numbers                 |
-- | RICE ID     : I2059_MerchantnumbersforODAMEX_CPCCards             |
-- | Description : To load the Store and Merchant numbers from the     |
-- |               Mainframe system into the translation table         |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      30-AUG-2007  Gowri Shankar         Initial version        |
-- |1.1      13-NOV-2014  Kirubha Samuel        Modified for defect #32284  |
-- |                                                                   |
-- +===================================================================+

    -- +=========================================================================+
    -- | Name : LOAD_TRANSLATE                                                   |
    -- | Description : To Load the Store, Merchant numbers into Staging table    |
    -- | Returns : x_error_buf, x_ret_code                                       |
    -- |                                                                         |
    -- +=========================================================================+

    PROCEDURE LOAD_TRANSLATE (
                             x_error_buf             OUT VARCHAR2
                            ,x_ret_code              OUT NUMBER
                             )
    IS 
	
	
        CURSOR c_store_merchant IS
            (SELECT  XISM.rowid
                    ,XISM.store_number
                    ,XISM.merchant_number
                    ,XISM.brand_code
                    ,XISM.card_code
             FROM   xx_iby_store_merchant_stg XISM
            );

        CURSOR c_translate_inactive (p_translate_id xx_fin_translatevalues.translate_id%TYPE) IS
            (
            SELECT  XFT.ROWID
            FROM   xx_fin_translatevalues XFT
            WHERE  XFT.TRANSLATE_ID = p_translate_id
            AND   NOT EXISTS 
                    (SELECT 1 
                      FROM   xx_iby_store_merchant_stg XISM 
                      WHERE  XISM.store_number = XFT.source_value1
                      AND    XISM.brand_code =XFT.source_value4
                      AND    XISM.card_code =XFT.source_value2)
            );
				
	
        TYPE translation_rows      IS TABLE OF ROWID;
        translation_rows_type      translation_rows;
        ln_store_count             NUMBER := 0;
        ln_translate_id            xx_fin_translatedefinition.translate_id%TYPE;

        lc_error_loc               VARCHAR2(4000) := NULL;
        lc_error_debug             VARCHAR2(4000) := NULL;

    BEGIN

        lc_error_loc    := 'Getting the Translation ID for the translation AMEX_FIN_MERCHANT_NUMBERS';
        lc_error_debug  := '';

        SELECT XFT.translate_id
        INTO   ln_translate_id
        FROM   xx_fin_translatedefinition XFT
        WHERE  XFT.translation_name = 'AMEX_FIN_MERCHANT_NUMBERS';

        FOR lcu_store_merchant IN c_store_merchant
        LOOP

            lc_error_loc    := 'Checking if the Store Number is already loaded for the Brand, Card Code';
            lc_error_debug  := 'Store Number: '||lcu_store_merchant.store_number||' Card Code: '||lcu_store_merchant.card_code||' Brand Code: '||lcu_store_merchant.brand_code;

            SELECT COUNT(1)
            INTO   ln_store_count
            FROM   xx_fin_translatevalues  XFT
            WHERE  XFT.translate_id = ln_translate_id
            AND    XFT.source_value1 = lcu_store_merchant.store_number
            AND    XFT.source_value2 = lcu_store_merchant.card_code
            AND    XFT.source_value4 = lcu_store_merchant.brand_code;

            IF (ln_store_count = 0) THEN

                lc_error_loc    := 'Inserting into the translation table XX_FIN_TRANSLATEVALUES';   
                lc_error_debug  := 'Store Number: '||lcu_store_merchant.store_number||'Merchant Number: '
                                    ||lcu_store_merchant.merchant_number||' Card Code: '
                                    ||lcu_store_merchant.card_code||' Brand Code: '||lcu_store_merchant.brand_code;

	
                INSERT 
                INTO xx_fin_translatevalues 
                (
                     translate_id
                    ,translate_value_id
                    ,source_value1     --Location
                    ,source_value2     --Card Code
                    ,source_value3     --Merchant Number
                    ,source_value4     --Brand Code
                    ,enabled_flag
                    ,start_date_active
                    ,creation_date
                    ,created_by
                    ,last_update_date
                    ,last_updated_by
                    ,last_update_login
                )
                VALUES
                (
                     ln_translate_id
                    ,xx_fin_translatevalues_s.nextval
                    ,lcu_store_merchant.store_number
                    ,lcu_store_merchant.card_code
                    ,lcu_store_merchant.merchant_number
                    ,lcu_store_merchant.brand_code
                    ,'Y'
                    ,SYSDATE
                    ,SYSDATE
                    ,fnd_global.user_id
                    ,SYSDATE
                    ,fnd_global.user_id
                    ,fnd_global.login_id   
                );

                ELSE

                UPDATE xx_fin_translatevalues XFT
                SET    XFT.source_value3 = lcu_store_merchant.merchant_number
                      ,XFT.end_date_active = NULL
                      ,XFT.enabled_flag = 'Y'
                      ,XFT.last_update_date = SYSDATE
                      ,XFT.last_updated_by = fnd_global.user_id
                      ,XFT.last_update_login = fnd_global.login_id
                WHERE  translate_id  = ln_translate_id
                AND    source_value1 = lcu_store_merchant.store_number
                AND    source_value2 = lcu_store_merchant.card_code
                AND    source_value4 = lcu_store_merchant.brand_code;

            END IF;

        END LOOP;

        OPEN c_translate_inactive(ln_translate_id);
            LOOP
                DBMS_OUTPUT.PUT_LINE('test_tab_type.COUNT1: ');

                lc_error_loc    := 'Performing BULK COLLECT for End Dating the Store Numbers';   
                lc_error_debug  := '';

                FETCH c_translate_inactive BULK COLLECT INTO translation_rows_type;

                DBMS_OUTPUT.PUT_LINE('test_tab_type.COUNT: '||translation_rows_type.COUNT);

                lc_error_loc    := 'BULK Updation of the Translation table XX_FIN_TRANSLATEVALUES';   
                lc_error_debug  := '';

                FORALL i IN 1..translation_rows_type.COUNT
                    UPDATE  xx_fin_translatevalues XFT
                    SET     XFT.enabled_flag = 'N'
                           ,XFT.end_date_active = SYSDATE
                           ,XFT.last_update_date = SYSDATE
                           ,XFT.last_updated_by = fnd_global.user_id
                           ,XFT.last_update_login = fnd_global.login_id
                    WHERE   XFT.ROWID = translation_rows_type(i);

                EXIT WHEN c_translate_inactive%NOTFOUND;

            END LOOP;
        CLOSE c_translate_inactive;

        lc_error_loc    := 'Deleting the Staging table XX_IBY_STORE_MERCHANT_STG';   
        lc_error_debug  := '';

        --DELETE FROM xx_iby_store_merchant_stg XISM;

        COMMIT;

    EXCEPTION WHEN OTHERS THEN
        x_ret_code := 2;
        x_error_buf := SQLERRM;
        ROLLBACK;
        FND_FILE.PUT_LINE(fnd_file.log,'Error Message: '||SQLERRM);
        FND_FILE.PUT_LINE(fnd_file.output,' Error Location: '||lc_error_loc||' Error Debug: '||lc_error_debug);
        XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                    ,p_module_name             => 'IBY'
                    ,p_error_location          => ''
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => SQLERRM
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'Store Merchant Loading');

    END LOAD_TRANSLATE;
	
    -- +=========================================================================+
	-- | Name : LOAD                                                             |
	-- | Description : To Load the Store, Merchant numbers into Staging table    |
	-- | Parameters :                                                            |
	-- | Returns : x_error_buf, x_ret_code                                       |
	-- |                                                                         |
	-- +=========================================================================+
	
    PROCEDURE LOAD        (
                            x_error_buf             OUT VARCHAR2
                           ,x_ret_code              OUT NUMBER
                          )
    IS
	
        lc_error_msg                VARCHAR2(1000);
        ln_ret_code                 NUMBER;

        ln_conc_request_id          fnd_concurrent_requests.request_id%TYPE;
        lb_request_status           BOOLEAN;
        lc_phase                    VARCHAR2(1000);
        lc_status                   VARCHAR2(1000);
        lc_devphase                 VARCHAR2(1000);
        lc_devstatus                VARCHAR2(1000);
        lc_message                  VARCHAR2(4000);
        lc_mainframe_filename       xx_fin_translatevalues.source_value1%TYPE;
        lc_ebs_filename             xx_fin_translatevalues.source_value2%TYPE;
        lc_ebs_filepath             xx_fin_translatevalues.source_value2%TYPE;
		ln_record_count            NUMBER := 0; --Added for defect #32284
        lc_error_loc               VARCHAR2(4000) := NULL;
        lc_error_debug             VARCHAR2(4000) := NULL;
        EX_GET_FILE                EXCEPTION;
        EX_LOAD_FILE               EXCEPTION;
		EX_NO_DATA                 EXCEPTION; --Added for defect #32284
	
    BEGIN
	
        --Get the Concurrent Program Name
        lc_error_loc   := 'Get the Concurrent Program Name';
        lc_error_debug := 'Concurrent Program id: '||fnd_global.conc_program_id;
			
        SELECT FCPT.user_concurrent_program_name
        INTO   gc_concurrent_program_name
        FROM   fnd_concurrent_programs_tl FCPT
        WHERE  FCPT.concurrent_program_id = fnd_global.conc_program_id
        AND    FCPT.language = 'US';

        lc_error_loc    := 'Getting the Translation values for Mainframe and EBS file name';
        lc_error_debug  := 'Translation Name: AMEX_STORE_MERCHANT_LOAD';

        SELECT XFTV.source_value1 , XFTV.source_value2||TO_CHAR(SYSDATE,'YYYYMMDDHH24MISS')||'.TXT'
        INTO   lc_mainframe_filename, lc_ebs_filename
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'AMEX_STORE_MERCHANT_LOAD'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_error_loc    := 'Getting the Location for the Data File';
        lc_error_debug  := 'Translation Name: OD_FTP_PROCESSES, Translation Value: OD_GET_AMEX_MERCHANT';

        SELECT XFTV.target_value5
        INTO   lc_ebs_filepath
        FROM   xx_fin_translatevalues XFTV
              ,xx_fin_translatedefinition XFTD
        WHERE  XFTV.translate_id    = XFTD.translate_id
        AND    XFTD.translation_name = 'OD_FTP_PROCESSES'
        AND    XFTV.source_value1 = 'OD_GET_AMEX_MERCHANT'
        AND    SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
        AND    SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
        AND    XFTV.enabled_flag = 'Y'
        AND    XFTD.enabled_flag = 'Y';

        lc_error_loc    := 'Submitting the Concurrent Program to get the file from Mainframe';
        lc_error_debug  := 'Program Name: "OD: Common Get Program"';
	
        ln_conc_request_id  := FND_REQUEST.SUBMIT_REQUEST(
                                                     'XXFIN'
                                                    ,'XXCOMGET'
                                                    ,''
                                                    ,''
                                                    ,FALSE
                                                    ,'OD_GET_AMEX_MERCHANT'
                                                    ,lc_mainframe_filename
                                                    ,lc_ebs_filename);
		
        COMMIT;

        lb_request_status   := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                    ln_conc_request_id
                                                    ,'15'
                                                    ,''
                                                    ,lc_phase
                                                    ,lc_status
                                                    ,lc_devphase
                                                    ,lc_devstatus
                                                    ,lc_message);

        IF (lc_devstatus <> 'NORMAL') THEN

            RAISE EX_GET_FILE;

        END IF;

        lc_error_loc    := 'Deleting the Staging table XX_IBY_STORE_MERCHANT_STG';   
        lc_error_debug  := '';
	
        DELETE FROM xx_iby_store_merchant_stg XISM;
	
        COMMIT;

        lc_error_loc    := 'Submitting the Concurrent Program';   
        lc_error_debug  := 'Program Name: "OD: IBY Store Merchant Number Stage Loading"';
	
        ln_conc_request_id  := FND_REQUEST.SUBMIT_REQUEST(
                                                    'XXFIN'
                                                    ,'XXIBYSTOREMERCHLOAD'
                                                    ,''
                                                    ,''
                                                    ,FALSE
                                                    ,'XXIBYSTOREMERCHANT.ctl'
                                                    ,lc_ebs_filepath
                                                    ,lc_ebs_filename
                                                    );
		
        COMMIT;

        lb_request_status   := FND_CONCURRENT.WAIT_FOR_REQUEST(
                                                    ln_conc_request_id
                                                    ,'15'
                                                    ,''
                                                    ,lc_phase
                                                    ,lc_status
                                                    ,lc_devphase
                                                    ,lc_devstatus
                                                    ,lc_message);

        IF (lc_devstatus <> 'NORMAL') THEN

            RAISE EX_LOAD_FILE;

        END IF;
		
		--Changes for the defect #32284
		SELECT COUNT(*)
		INTO ln_record_count
		FROM XX_IBY_STORE_MERCHANT_STG;
				
		IF ln_record_count = 0 THEN
		RAISE EX_NO_DATA;
		END IF;
		--Changes ends for the defect #32284

        lc_error_loc    := 'Calling the Procedure LOAD_TRANSLATE to load into the translation table';   
        lc_error_debug  := '';
	
        LOAD_TRANSLATE(
                            x_error_buf => lc_error_msg
                           ,x_ret_code =>  ln_ret_code);

        x_ret_code := ln_ret_code;
        x_error_buf := lc_error_msg;


    EXCEPTION 
        WHEN EX_GET_FILE THEN
            x_ret_code := 2;
            x_error_buf := 'Error in Getting the File from the Mainframe,  Please check the program "OD: Common Get Program"';
            FND_FILE.PUT_LINE(fnd_file.log,'Error Message: '||x_error_buf);


        WHEN EX_LOAD_FILE THEN
            x_ret_code := 2;
            x_error_buf := 'Error in loading the Merchant Numbers from file to staging table,  Please check the program "OD: IBY Store Merchant Number Stage Loading"';
            FND_FILE.PUT_LINE(fnd_file.log,'Error Message: '||x_error_buf);
			
		WHEN EX_NO_DATA THEN
        x_ret_code := 2;
        x_error_buf := 'File is not loaded successfully, Please check the size of the file';
        FND_FILE.PUT_LINE(fnd_file.log,'Error Message: '||x_error_buf);

        WHEN OTHERS THEN
            x_ret_code := 2;
            x_error_buf := SQLERRM;
            ROLLBACK;
            FND_FILE.PUT_LINE(fnd_file.log,'Error Message: '||SQLERRM);
            FND_FILE.PUT_LINE(fnd_file.output,' Error Location: '||lc_error_loc||' Error Debug: '||lc_error_debug);
	
            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                     p_program_type            => 'CONCURRENT PROGRAM'
                    ,p_program_name            => gc_concurrent_program_name
                    ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                    ,p_module_name             => 'IBY'
                    ,p_error_location          => ''
                    ,p_error_message_count     => 1
                    ,p_error_message_code      => 'E'
                    ,p_error_message           => SQLERRM
                    ,p_error_message_severity  => 'Major'
                    ,p_notify_flag             => 'N'
                    ,p_object_type             => 'Store Merchant Loading');


    END LOAD;
	
END XX_IBY_STORE_MERCH_PKG;
/
SHOW ERR