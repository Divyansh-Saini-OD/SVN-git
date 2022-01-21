SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
SET TERM         ON

PROMPT Creating Package Body XX_AR_REMIT_TO_ADDRESS_PKG
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE BODY XX_AR_REMIT_TO_ADDRESS_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name  :  XX_AR_REMIT_TO_ADDRESS_PKG                               |
-- |                                                                   |
-- | Description : This extension consists of a Concurrent program     |
-- | "OD: AR Update Remit to Address" which will be included in the    |
-- | request set 'OD: AR Updation of Remit to Address Request Set'.    |
-- |                                                                   |
-- | The concurrent program 'OD: AR Update Remit to Address' scans the |
-- | invoices that was imported by Autoinvoice and updates the invoice |
-- | with new remittance to address id if the re-run parameter is 'N'. |
-- | When the re-run parameter is 'Y', program picks up the invoices   |
-- | which were errored by previously run remit to address program     |
-- |                                                                   |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |Draft1A   22-FEB-2007  Shivkumar Iyer,      Initial version.       | 
-- |                       Wipro Technologies                          |
-- |Draft1B   04-Apr-2007  Shivkumar Iyer,      Changes based on CR 55 |
-- |                       Wipro Technologies                          |
-- |Draft1C   04-Jun-2007  Shivkumar Iyer,      Incorporated  Remit to |
-- |                       Wipro Technologies   Address Sales Channel  |
-- |                                            Logic.                 |
-- |1.0       18-Jun-2007  Shivkumar Iyer,      Changes based on new   |
-- |                       Wipro Technologies   Error Handling done.   |
-- |1.0       27-Feb-2008 Sowmya Mohanasundaram,Commented the primary  |
-- |                       Wipro Technologies   flag for Defect#13368  |
-- +===================================================================+
-- +===================================================================+
-- | Name  : UPDATE_REMIT_ID                                           |
-- | Description  : Updates the Remit to Address ID based on scenarios.|
-- |                                                                   |
-- | Parameters : OUT : x_error_buff                                   |
-- |              OUT : x_ret_code                                     |
-- |              IN  : p_rerun_flag                                   |
-- |              IN  : p_txn_from_date                                |
-- |              IN  : p_txn_to_date                                  |
-- |              IN  : p_inv_from_num                                 |
-- |              IN  : p_inv_to_num                                   |
-- | Returns : Error Buffer                                            |
-- |          ,Return Code                                             |
-- +===================================================================+

   PROCEDURE UPDATE_REMIT_ID (
                              x_error_buff     OUT VARCHAR2
                             ,x_ret_code       OUT NUMBER
                             ,p_rerun_flag     IN  VARCHAR2
                             ,p_txn_from_date  IN  DATE     DEFAULT NULL
                             ,p_txn_to_date    IN  DATE     DEFAULT NULL
                             ,p_inv_from_num   IN  VARCHAR2 DEFAULT NULL
                             ,p_inv_to_num     IN  VARCHAR2 DEFAULT NULL
                             )
   AS
      ln_location_id             NUMBER;
      ln_org_id                  NUMBER;
      ln_set_of_book             NUMBER;
      ln_request_id              NUMBER;
      ln_remit_to_add            NUMBER;
      ln_remit_dflt_add          NUMBER;
      ln_cust_txn_cnt            NUMBER DEFAULT 0;
      lc_email_address           fnd_user.email_address%TYPE;
      lc_sys_par_attr            ar_system_parameters_all.attribute1%TYPE;
      ln_update_count            NUMBER DEFAULT 0;
      ln_req_id                  NUMBER;
      ln_trx_count               NUMBER;
      ld_date                    DATE  := SYSDATE;
      lc_user_id                 VARCHAR2 (25) := FND_GLOBAL.USER_ID;
      lc_error_loc               VARCHAR2 (2000);
      lc_err_msg                 VARCHAR2 (2000);
      lc_default_flag            VARCHAR2 (1);
      lc_concurrent_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
      --lc_rmt_dflt_addr           VARCHAR2 (100) DEFAULT 'PO Box 70025';
      --lc_rmt_dflt_city           VARCHAR2 (100) DEFAULT 'Los Angeles';
      --lc_rmt_dflt_pstl_cd        VARCHAR2 (100) DEFAULT '90074-0025'; 
      --lc_rmt_dflt_county         VARCHAR2 (100) DEFAULT 'Los Angeles';
      --lc_rmt_dflt_state          VARCHAR2 (100) DEFAULT 'CA'; 
      --lc_rmt_dflt_country        VARCHAR2 (100) DEFAULT 'US'; 
      
      -- Record Type Defination based on some columns of the RA_CUSTOMER_TRX_ALL table.
      TYPE ra_cust_trx_rec_type IS RECORD (
          trx_number            ra_customer_trx_all.trx_number%TYPE
         ,customer_trx_id       ra_customer_trx_all.customer_trx_id%TYPE
         ,bill_to_customer_id   ra_customer_trx_all.bill_to_customer_id%TYPE
         ,bill_to_site_use_id   ra_customer_trx_all.bill_to_site_use_id%TYPE
      );

      -- Variables of the record type ra_cust_trx_rec_type.
      lc_cust_txn_rec       ra_cust_trx_rec_type;

      -- Long Variable for the SELECT statement to be used in the REF CURSOR.

      lc_cust_txn           VARCHAR2 (150) := 'SELECT trx_number'
                                              ||',customer_trx_id'
                                              ||',bill_to_customer_id'
                                              ||',bill_to_site_use_id'
                                              ||' FROM ra_customer_trx_all ';

      -- Long Variable to Build the WHERE clause in the REF CURSOR.
      lc_cst_where_clause   VARCHAR2 (500) := 'WHERE ';

      -- REF CURSOR Type Defination.
      TYPE lc_cust_csr_type IS REF CURSOR;

      -- Defination of REF CURSOR Type Variable.
      lc_cust_csr_var       lc_cust_csr_type;
   BEGIN

      lc_error_loc   := 'Determining the Concurrent Program Name.';
      
      SELECT FCPT.user_concurrent_program_name
      INTO   lc_concurrent_program_name
      FROM   fnd_concurrent_programs_tl FCPT
      WHERE  FCPT.concurrent_program_id = FND_GLOBAL.CONC_PROGRAM_ID
      AND    FCPT.language = 'US';

      -- The following query determines the org id.
      ln_org_id := fnd_global.org_id;

      IF ln_org_id IS NOT NULL
      THEN
         -- The following determines the SOB id.
         ln_set_of_book := FND_PROFILE.VALUE ('GL_SET_OF_BKS_ID');

         lc_error_loc   := 'Determining the Email Address of the current user.';
          
         -- The following determines the the email address of the current user.
         BEGIN
            SELECT email_address
            INTO lc_email_address
            FROM fnd_user
            WHERE user_id = (SELECT FND_GLOBAL.USER_ID 
                             FROM dual);
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location: '||lc_error_loc);
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0003_NO_EMAIL_ID');
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                            p_program_type            => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => lc_concurrent_program_name
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'AR'
                                           ,p_error_location          => 'Error at ' || lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_err_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'Remit to Address updation'
            );


         WHEN OTHERS
         THEN

            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message  : '||SQLERRM);
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0004_EMAIL_ID_ERR');
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                            p_program_type            => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => lc_concurrent_program_name
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'AR'
                                           ,p_error_location          => 'Error at ' || lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => SQLERRM
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'Remit to Address updation'
            );

         END;

         -- The following query checks if the ATTRIBUTE1
         -- (Remit-to address derivation) in AR System Options is enabled.
         BEGIN

            lc_error_loc   := 'Determining if the System Parameter Information is enabled.';
            
            SELECT NVL(attribute1,'N')
            INTO lc_sys_par_attr
            FROM ar_system_parameters_all
            WHERE set_of_books_id = ln_set_of_book
            AND org_id = ln_org_id;
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
               
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location: '||lc_error_loc);
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0001_ATTR1_DISABLE');
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                            p_program_type            => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => lc_concurrent_program_name
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'AR'
                                           ,p_error_location          => 'Error at ' || lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_err_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'Remit to Address updation'
            );

         WHEN OTHERS
         THEN

            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0002_ATTR1_ERROR');
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                            p_program_type            => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => lc_concurrent_program_name
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'AR'
                                           ,p_error_location          => 'Error at ' || lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => SQLERRM
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'Remit to Address updation'
            );
         END;

         -- If Remit-to address derivation is enabled,
         -- then proceed with the processing.

         IF NVL (lc_sys_par_attr, 'N') = 'Y'
         THEN
            IF p_rerun_flag = 'N'
            THEN
               BEGIN

                  lc_error_loc   := 'Determining the invoices processed by Import Program.';
                  
                  SELECT FCR2.request_id
                  INTO   ln_request_id
                  FROM   fnd_concurrent_programs FCPM
                        ,fnd_concurrent_requests FCR2
                        ,fnd_concurrent_requests FCR1
                  WHERE  FCR1.request_id = FND_GLOBAL.CONC_REQUEST_ID
                  AND    FCR2.priority_request_id = FCR1.priority_request_id
                  AND    FCR2.concurrent_program_id = FCPM.concurrent_program_id
                  AND    FCPM.concurrent_program_name = 'RAXTRX';
               EXCEPTION
               WHEN NO_DATA_FOUND
               THEN

                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0005_NO_INV_AI');
                  lc_err_msg :=  FND_MESSAGE.get;
                  FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                  p_program_type            => 'CONCURRENT PROGRAM'
                                                 ,p_program_name            => lc_concurrent_program_name
                                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                 ,p_module_name             => 'AR'
                                                 ,p_error_location          => 'Error at ' || lc_error_loc
                                                 ,p_error_message_count     => 1
                                                 ,p_error_message_code      => 'E'
                                                 ,p_error_message           => lc_err_msg
                                                 ,p_error_message_severity  => 'Major'
                                                 ,p_notify_flag             => 'N'
                                                 ,p_object_type             => 'Remit to Address updation'
                  );

               WHEN OTHERS
               THEN

                  FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location: '||lc_error_loc);
                  FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0006_AI_PRG_ERR');
                  lc_err_msg :=  FND_MESSAGE.get;
                  FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                  p_program_type            => 'CONCURRENT PROGRAM'
                                                 ,p_program_name            => lc_concurrent_program_name
                                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                 ,p_module_name             => 'AR'
                                                 ,p_error_location          => 'Error at ' || lc_error_loc
                                                 ,p_error_message_count     => 1
                                                 ,p_error_message_code      => 'E'
                                                 ,p_error_message           => SQLERRM
                                                 ,p_error_message_severity  => 'Major'
                                                 ,p_notify_flag             => 'N'
                                                 ,p_object_type             => 'Remit to Address updation'
                  );

               END;

                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0009_AI_PROCESS');
                  lc_err_msg :=  FND_MESSAGE.get;
                  FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                  p_program_type            => 'CONCURRENT PROGRAM'
                                                 ,p_program_name            => lc_concurrent_program_name
                                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                 ,p_module_name             => 'AR'
                                                 ,p_error_location          => 'Error at ' || lc_error_loc
                                                 ,p_error_message_count     => 1
                                                 ,p_error_message_code      => 'E'
                                                 ,p_error_message           => lc_err_msg
                                                 ,p_error_message_severity  => 'Major'
                                                 ,p_notify_flag             => 'N'
                                                 ,p_object_type             => 'Remit to Address updation'
                  );

                  lc_cst_where_clause := lc_cst_where_clause  
                                         || ' request_id = (SELECT FCR2.request_id '
                                         || ' FROM fnd_concurrent_programs FCPM '
                                         || '      ,fnd_concurrent_requests FCR2 '
                                         || '      ,fnd_concurrent_requests FCR1  '
                                         || ' WHERE FCR1.request_id = FND_GLOBAL.CONC_REQUEST_ID '
                                         || ' AND FCR2.priority_request_id = FCR1.priority_request_id '
                                         || ' AND FCR2.concurrent_program_id = FCPM.concurrent_program_id '
                                         || ' AND FCPM.concurrent_program_name = ''RAXTRX'')';

               OPEN lc_cust_csr_var FOR lc_cust_txn || ' ' || lc_cst_where_clause;
            ELSIF p_rerun_flag = 'Y'
            THEN

                  FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0010_RMT_PROCESS');
                  lc_err_msg :=  FND_MESSAGE.get;
                  FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                  XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                  p_program_type            => 'CONCURRENT PROGRAM'
                                                 ,p_program_name            => lc_concurrent_program_name
                                                 ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                 ,p_module_name             => 'AR'
                                                 ,p_error_location          => 'Error at ' || lc_error_loc
                                                 ,p_error_message_count     => 1
                                                 ,p_error_message_code      => 'E'
                                                 ,p_error_message           => lc_err_msg
                                                 ,p_error_message_severity  => 'Major'
                                                 ,p_notify_flag             => 'N'
                                                 ,p_object_type             => 'Remit to Address updation'
                  );

                  lc_cst_where_clause := lc_cst_where_clause
                                         || ' trx_number IN '
                                         || ' (SELECT trx_number FROM xx_ar_remit_errors '
                                         || ' WHERE RmttoAdd_Updt_Flg = ''Y'') ';

               IF (p_txn_from_date) IS NOT NULL OR (p_txn_to_date) IS NOT NULL
               THEN
                  lc_cst_where_clause := lc_cst_where_clause
                                         || ' AND trx_date BETWEEN '
                                         || CHR (39)
                                         || NVL (p_txn_from_date, p_txn_to_date)
                                         || CHR (39)
                                         || ' AND '
                                         || CHR (39)
                                         || NVL (p_txn_to_date, p_txn_from_date)
                                         || CHR (39);
               END IF;

               IF (p_inv_from_num) IS NOT NULL OR (p_inv_to_num) IS NOT NULL
               THEN
                  lc_cst_where_clause := lc_cst_where_clause
                                         || ' AND trx_number BETWEEN '
                                         || CHR (39)
                                         || NVL (p_inv_from_num, p_inv_to_num)
                                         || CHR (39)
                                         || ' AND '
                                         || CHR (39)
                                         || NVL (p_inv_to_num, p_inv_from_num)
                                         || CHR (39);
               END IF;

               OPEN lc_cust_csr_var FOR lc_cust_txn
                                        || ' '
                                        || lc_cst_where_clause;
            END IF;

            LOOP
              FETCH lc_cust_csr_var
              INTO lc_cust_txn_rec;

              EXIT WHEN lc_cust_csr_var%NOTFOUND;
              FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0011_PROCESS_INV');
              FND_MESSAGE.SET_TOKEN('INVOICE',LTRIM (RTRIM (lc_cust_txn_rec.trx_number)));
              lc_err_msg :=  FND_MESSAGE.get;
              FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

              ln_cust_txn_cnt := ln_cust_txn_cnt + 1;

              BEGIN

                -- If there is a value in the Remit to Address Sales Channel field on the CDH for the customer's BILL-TO
                -- Then update the invoice's remit to address with the value corresponding to the remit to address Sales
                -- Channel code in the remit to address setup form.

                lc_error_loc   := 'Determining the Remit to Address ID by Sales Channel.';
                ln_remit_to_add := NULL;

                SELECT artav.address_id
                INTO   ln_remit_to_add
                FROM   hz_cust_site_uses_all HCSUA
                      ,ar_remit_to_addresses_v ARTAV
                   -- ,ra_addresses_all RAA
                WHERE  HCSUA.site_use_code = 'BILL_TO'
                AND    HCSUA.attribute_category = 'BILL_TO'
                AND    HCSUA.status = 'A'
              --  AND    HCSUA.primary_flag = 'Y'      ---Commented for Defect#13368 
                AND    HCSUA.org_id = ln_org_id
                AND    HCSUA.site_use_id = lc_cust_txn_rec.bill_to_site_use_id
                --AND    RAA.PARTY_SITE_ID = HCSUA.cust_acct_site_ID
                --AND    RAA.postal_code between ARTAV.attribute2 AND ARTAV.attribute3
                AND    HCSUA.attribute25 = ARTAV.attribute1;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN 
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
                 FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0018_NO_RMT');
                 lc_err_msg :=  FND_MESSAGE.get;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                 p_program_type            => 'CONCURRENT PROGRAM'
                                                ,p_program_name            => lc_concurrent_program_name
                                                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                ,p_module_name             => 'AR'
                                                ,p_error_location          => 'Error at ' || lc_error_loc
                                                ,p_error_message_count     => 1
                                                ,p_error_message_code      => 'E'
                                                ,p_error_message           => SQLERRM
                                                ,p_error_message_severity  => 'Major'
                                                ,p_notify_flag             => 'N'
                                                ,p_object_type             => 'Remit to Address updation'
                 );

              WHEN TOO_MANY_ROWS 
              THEN  
                 ln_remit_to_add := '';
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
                 FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0017_MULTIPLE_RMT');
                 lc_err_msg :=  FND_MESSAGE.get;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                 p_program_type            => 'CONCURRENT PROGRAM'
                                                ,p_program_name            => lc_concurrent_program_name
                                                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                ,p_module_name             => 'AR'
                                                ,p_error_location          => 'Error at ' || lc_error_loc
                                                ,p_error_message_count     => 1
                                                ,p_error_message_code      => 'E'
                                                ,p_error_message           => SQLERRM
                                                ,p_error_message_severity  => 'Major'
                                                ,p_notify_flag             => 'N'
                                                ,p_object_type             => 'Remit to Address updation'
                 );

              WHEN OTHERS THEN
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
                 FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Message : '||SQLERRM);
                 lc_err_msg :=  FND_MESSAGE.get;
                 FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                 XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                                 p_program_type            => 'CONCURRENT PROGRAM'
                                                ,p_program_name            => lc_concurrent_program_name
                                                ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                                ,p_module_name             => 'AR'
                                                ,p_error_location          => 'Error at ' || lc_error_loc
                                                ,p_error_message_count     => 1
                                                ,p_error_message_code      => 'E'
                                                ,p_error_message           => SQLERRM
                                                ,p_error_message_severity  => 'Major'
                                                ,p_notify_flag             => 'N'
                                                ,p_object_type             => 'Remit to Address updation'
                 );

               END;

               IF ln_remit_to_add IS NOT NULL
               THEN
    
                    UPDATE ra_customer_trx_all
                    SET remit_to_address_id = ln_remit_to_add
                    WHERE trx_number = lc_cust_txn_rec.trx_number;

                    ln_update_count := ln_update_count + 1;

                    DELETE FROM xx_ar_remit_errors
                    WHERE trx_number = lc_cust_txn_rec.trx_number
                    AND rmttoadd_updt_flg = 'Y';

                    -- If there is no value in the remit to address sales channel field on the CDH,
                    -- then default the remit to address as PO Box 70025,Los Angeles,CA 90074-0025.

               ELSE  -- IF ln_remit_to_add IS NULL
                   
                   lc_error_loc   := 'Determining the Default Remit to Address ID.';  

                   BEGIN

                     SELECT RAA.address_id
                     INTO   ln_remit_dflt_add
                     FROM   ra_addresses_all RAA
                           ,ra_remit_tos RRT
                     WHERE RRT.country = 'DEFAULT'
                     AND RAA.address_id = RRT.address_id;

                   EXCEPTION
                   WHEN NO_DATA_FOUND
                   THEN
                      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
                      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0007_DFF_ERROR');
                      lc_err_msg :=  FND_MESSAGE.get;
                      FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                   WHEN TOO_MANY_ROWS
                   THEN 
                      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
                      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0007_DFF_ERROR');
                      lc_err_msg :=  FND_MESSAGE.get;
                      FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

                   WHEN OTHERS
                   THEN 
                      FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
                      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0007_DFF_ERROR');
                      lc_err_msg :=  FND_MESSAGE.get;
                      FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);
                   END; 

                   IF ln_remit_dflt_add IS NOT NULL THEN

                        UPDATE ra_customer_trx_all
                        SET remit_to_address_id = ln_remit_dflt_add
                        WHERE trx_number = lc_cust_txn_rec.trx_number;

                   ELSE
                        -- Updating the Error Table with the Invoice Details whose Remit Id has not been updated.
                        INSERT 
                        INTO xx_ar_remit_errors (
                                                 trx_number
                                                ,customer_trx_id
                                                ,error_code
                                                ,error_msg
                                                ,rmttoadd_updt_flg
                                                ,creation_date
                                                ,created_by
                                                ,last_update_date
                                                ,last_updated_by
                        )
                        VALUES 
                        (
                         lc_cust_txn_rec.trx_number
                        ,lc_cust_txn_rec.customer_trx_id
                        ,'REMIT_ADDR_ERR'
                        ,'Remit to Address ID not updated for Invoice -'||lc_cust_txn_rec.trx_number
                        ,'Y'
                        ,ld_date
                        ,lc_user_id
                        ,ld_date
                        ,lc_user_id
                        );
                   END IF;   
               END IF;
            END LOOP;

            CLOSE lc_cust_csr_var;

            COMMIT;
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0013_TOTAL_INV_RD');
            FND_MESSAGE.SET_TOKEN('TOTAL_READ',ln_cust_txn_cnt);
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0014_TOTAL_INV_PS');
            FND_MESSAGE.SET_TOKEN('INVOICE_PS',ln_update_count);
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0015_TOTAL_INV_ERR');
            FND_MESSAGE.SET_TOKEN('INVOICE_ERR',TO_NUMBER (ln_cust_txn_cnt - ln_update_count));
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

         ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0001_ATTR1_DISABLE');
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                            p_program_type            => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => lc_concurrent_program_name
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'AR'
                                           ,p_error_location          => 'Error at ' || lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_err_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'Remit to Address updation'
            );

 
         END IF;
      ELSE
            FND_FILE.PUT_LINE (FND_FILE.LOG,'Error Location : '||lc_error_loc);
            FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0008_ORG_ID_ERR');
            lc_err_msg :=  FND_MESSAGE.get;
            FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);

            XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                            p_program_type            => 'CONCURRENT PROGRAM'
                                           ,p_program_name            => lc_concurrent_program_name
                                           ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                           ,p_module_name             => 'AR'
                                           ,p_error_location          => 'Error at ' || lc_error_loc
                                           ,p_error_message_count     => 1
                                           ,p_error_message_code      => 'E'
                                           ,p_error_message           => lc_err_msg
                                           ,p_error_message_severity  => 'Major'
                                           ,p_notify_flag             => 'N'
                                           ,p_object_type             => 'Remit to Address updation'
            );

      END IF;
   EXCEPTION
   WHEN OTHERS
   THEN
      FND_MESSAGE.SET_NAME('XXFIN','XX_AR_REMIT_0006_AI_PRG_ERR');
      lc_err_msg :=  FND_MESSAGE.get;
      FND_FILE.PUT_LINE (FND_FILE.LOG,lc_err_msg);
      FND_FILE.PUT_LINE (FND_FILE.LOG,SQLERRM);

      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type            => 'CONCURRENT PROGRAM'
                                     ,p_program_name            => lc_concurrent_program_name
                                     ,p_program_id              => FND_GLOBAL.CONC_PROGRAM_ID
                                     ,p_module_name             => 'AR'
                                     ,p_error_location          => 'Error at ' || lc_error_loc
                                     ,p_error_message_count     => 1
                                     ,p_error_message_code      => 'E'
                                     ,p_error_message           => SQLERRM
                                     ,p_error_message_severity  => 'Major'
                                     ,p_notify_flag             => 'N'
                                     ,p_object_type             => 'Remit to Address updation'
      );

  
   END UPDATE_REMIT_ID;
END XX_AR_REMIT_TO_ADDRESS_PKG;
/

SHOW ERROR