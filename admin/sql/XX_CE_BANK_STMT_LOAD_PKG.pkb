SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package body XX_CE_BANK_STMT_LOAD_PKG
PROMPT Program exits if the creation is not successful
WHENEVER SQLERROR CONTINUE
CREATE OR REPLACE PACKAGE BODY APPS.XX_CE_BANK_STMT_LOAD_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      Bank statement Transaction text update program        |
-- | Description : To Update the transaction text with desctiption     |
-- |               of the corresponding transaction code               |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author             Remarks                 |
-- |=======   ==========   ===============     ========================|
-- |Draft 1   13-MAR-08     Ranjith            Initial version         |
-- |V.1.0     21-AUG-2008   Ranjith            Fixed defect 10100      |
-- |v.1.1     09-SEP-2008   Ranjith            Fixed defect 10807      |
-- |v 1.2     11-SEP-2008   Shabbar Hasan      Fixed Defect 9399       |
-- |v 1.3     22-OCT-228    Ranjith            fixed defect 12041      |
-- |v 1.4     31-OCT-228    Ranjith            fixed defect 12234      |
-- |v 1.5     12-NOV-08     Raji               fixed defect 12367      |
-- |v 1.6     09-JUL-13     Shruthi Vasisht    I0032 - Modified for R12|
-- |                                           Upgrade Retrofit.       |
-- +===================================================================+
-- +===================================================================+
-- | Name : UPDATE_TRX_TEXT                                            |
-- | Description : update the TRX_TEXT field of                        |
-- | CE_STATEMENT_LINES_INTERFACE with description of the              |
-- | corresponding transaction code                                    |
-- | This procedure will be the executable of Concurrent               |
-- | program : OD: CE Bank Statement Loader                            |
-- | Parameters : x_error_buff, x_ret_code ,p_statement_date           |
-- |              ,p_org_id                                            |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+
PROCEDURE UPDATE_TRX_TEXT (
                     x_error_buff           OUT  NOCOPY    VARCHAR2
                    ,x_ret_code             OUT  NOCOPY    NUMBER
                    ,p_creation_date       IN              VARCHAR2
                    ,p_org_id               IN             VARCHAR2 -- added for defect 10100
                     )
		  AS
		  CURSOR lcu_trx_code (p_creation_date VARCHAR2 )
		   IS
		         SELECT CSLI.ROWID
                               ,CSLI.trx_code
                               ,CSLI.trx_text
                          --     ,XFTV.target_value1           -- commneted for defect 12041
                               ,get_trx_desc(CSLI.trx_code,CSLI.bank_account_num)  -- added for defect 12041
                               ,get_inv_text(CSLI.trx_code,CSLI.bank_account_num)  ---- added for defect 12041
		         FROM ce_statement_lines_interface CSLI
		         WHERE CSLI.statement_number IN (
		         		SELECT DISTINCT
		         		CSHIA.statement_number
                -- Commented and added the following by Shruthi for R122 Retrofit Upgrade
                                       -- FROM ce_statement_headers_int_all CSHIA  
                                       FROM ce_statement_headers_int CSHIA
                                       -- end of addition
		         		WHERE TO_DATE(CSHIA.creation_date,'DD-MON-RRRR') = to_date(p_creation_date,'DD-MON-RRRR')
		         		AND CSHIA.record_status_flag IN ('N','E')
                                        AND CSHIA.org_id=p_org_id
		         		)
                         AND NVL(CSLI.attribute1,'N') = 'N';
		  TYPE trx_code_tbl_type IS TABLE OF ce_statement_lines_interface.trx_code%TYPE;
		  TYPE trx_text_tbl_type IS TABLE OF ce_statement_lines_interface.trx_text%TYPE;
		  TYPE trx_code_rowid_tbl_type  IS TABLE OF ROWID INDEX BY PLS_INTEGER;
		  TYPE trx_inv_text_tbl_type IS TABLE OF xx_fin_translatevalues.target_value2%TYPE;
		  TYPE trx_description_tbl_type IS TABLE OF xx_fin_translatevalues.source_value2%TYPE;
		  ln_count                    NUMBER;
		  lt_trx_code                 trx_code_tbl_type;
		  lt_trx_text  				  trx_text_tbl_type;
		  lt_trx_code_rowid           trx_code_rowid_tbl_type;
		  lt_trx_description          trx_description_tbl_type;
                  lt_inv_text                 trx_inv_text_tbl_type;
                  lc_creation_date                   VARCHAR2(50);
		  BEGIN
                  lc_creation_date := fnd_date.canonical_to_date(p_creation_date);
		  OPEN lcu_trx_code(lc_creation_date);
                  FETCH lcu_trx_code BULK COLLECT into lt_trx_code_rowid,lt_trx_code,lt_trx_text,lt_trx_description,lt_inv_text;
		       IF lt_trx_code_rowid.COUNT =0 THEN
                         RAISE NO_DATA_FOUND;
		       END IF;
                    FORALL i IN lt_trx_code_rowid.FIRST..lt_trx_code_rowid.LAST
		      UPDATE CE_STATEMENT_LINES_INTERFACE CSLI
		  --    SET   CSLI.trx_text = lt_trx_description(i)||' '||lt_trx_text(i)  commented for defect 12234
          SET   CSLI.trx_text =rtrim(lt_trx_description(i)||' '||substr(lt_trx_text(i),1,(254-length(lt_trx_description(i)))),' ') -- added for defect 12234 and added rtrim for defect 12367
                      , CSLI.ATTRIBUTE1 = 'Y'
                   --   , CSLI.bank_trx_number = CSLI.invoice_text  -- added for defect 10807  -- commented by ranjith for defect 12041
		      ,CSLI.bank_trx_number = NVL(lt_inv_text(i),CSLI.invoice_text) ---- added for defect 12041
                      ,CSLI.invoice_text  =  NVL(lt_inv_text(i),CSLI.invoice_text)  ---- added for defect 12041
                      WHERE CSLI.ROWID=lt_trx_code_rowid(i)
                      AND NVL(CSLI.ATTRIBUTE1,'N') = 'N' ;
                      COMMIT;
                   CLOSE lcu_trx_code;
		  EXCEPTION
		        WHEN NO_DATA_FOUND THEN
		            FND_FILE.PUT_LINE (FND_FILE.LOG,'No Updatable record in Interface');
		        WHEN OTHERS THEN
		            FND_FILE.PUT_LINE (FND_FILE.LOG,'Problem in Updating Transaction Text'|| sqlerrm);
 END UPDATE_TRX_TEXT;
 -- +===================================================================+
-- | Name : SUBMIT_REQUEST                                             |
-- | Description : This submits two requests                           |
-- |          Bank Statement Loader and                                |
-- |          OD: CE Update Transaction Text                           |
-- | Parameters : x_error_buff, x_ret_code,p_process_option,           |
-- |              ,p_load_name ,p_filename,p_filepath,p_statement_date |
-- | Returns : Returns Code                                            |
-- |           Error Message                                           |
-- +===================================================================+
PROCEDURE SUBMIT_REQUEST (
                    x_error_buff           OUT  NOCOPY    VARCHAR2
                   ,x_ret_code             OUT  NOCOPY    NUMBER
                   ,p_process_option       IN             VARCHAR2
                   ,p_load_name            IN             VARCHAR2
                   ,p_filename			   IN     VARCHAR2
                   ,p_filepath             IN             VARCHAR2
                   ,p_creation_date      IN               VARCHAR2
                            )
  AS
   --Added this cursor as part of the fix for Defect 9399
   CURSOR lcu_child_requests (p_parent_request_id  NUMBER)
   IS
   SELECT request_id,parent_request_id,status_code
   FROM   fnd_concurrent_requests
          CONNECT BY PRIOR request_id = parent_request_id
          START WITH       request_id = p_parent_request_id;        -- the parent program BPEL started
   lb_req_set                         BOOLEAN;
   lb_req_std_import                  BOOLEAN;
   lb_req_custom_req                  BOOLEAN;
   ln_req_submit	              NUMBER;
   ln_child_request_id 	              NUMBER;
   ln_parent_request_id               NUMBER;                        -- Added for Defect 9399
   ln_request_id      	              NUMBER;
   lb_req_status                      BOOLEAN;
   lc_phase                           VARCHAR2 (50);
   lc_bank_name                       VARCHAR2(100);
   lc_status                          VARCHAR2 (50);
   lc_devphase                        VARCHAR2 (50);
   lc_devstatus                       VARCHAR2 (50);
   lc_message                         VARCHAR2 (50);
   lc_error_loc                       VARCHAR2 (2000);
   lc_org_id                          VARCHAR2(10);
   lc_creation_date                   VARCHAR2(50);
   BEGIN
    lc_org_id :=FND_PROFILE.VALUE('ORG_ID');
 --   lc_creation_date := fnd_date.canonical_to_date(p_creation_date);
    FND_FILE.PUT_LINE (FND_FILE.LOG,'Creation date'||lc_creation_date);
------------------------------------------------------------------------------------------
--  Submitting the Bank Statement Loader
------------------------------------------------------------------------------------------
FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting Bank Statement Loader Program');
              lc_error_loc := 'Submitting Bank Statement Loader ';
              ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                  application      => 'CE'
                                                 ,program          => 'CESQLLDR'
                                                 ,description      => ''
                                                 ,sub_request      => FALSE
                                                 ,argument1     => p_process_option
                                                 ,argument2     => p_load_name
                                                 ,argument3     => p_filename
                                                 ,argument4     => p_filepath
                                                 ,argument5     => NULL
                                                 ,argument6     => NULL
                                                 ,argument7     => SYSDATE
                                                 ,argument8     => NULL
                                                 ,argument9     => NULL
                                                 ,argument10    => NULL
                                                 ,argument11    => 'N'
                                                 ,argument12    => NULL
                                                 ,argument13    => NULL
                                                 ,argument14    => NULL  -- Added by Shruthi for R12 Retrofit Upgrade
                                                 ,argument15    => NULL  -- Added by Shruthi for R12 Retrofit Upgrade
                                                 ,argument16    => NULL   -- Added by Shruthi for R12 Retrofit Upgrade
                                                 );
                                       COMMIT;
------------------------------------------------------------------------------------------
--  Waiting for Bank Statement Loader Program
------------------------------------------------------------------------------------------
          lc_error_loc := 'Waiting for Bank Statement Loader Program to complete ';
          lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                              request_id => ln_request_id
                                                             ,interval   => '5'
                                                             ,max_wait   => ''
                                                             ,phase      => lc_phase
                                                             ,status     => lc_status
                                                             ,dev_phase  => lc_devphase
                                                             ,dev_status => lc_devstatus
                                                             ,message    => lc_message
                                                             );
                IF lb_req_status = TRUE AND lc_devphase= 'COMPLETE' THEN
		SELECT FCR.request_id
		INTO ln_child_request_id
		FROM fnd_concurrent_requests FCR
		 WHERE FCR.parent_request_id = ln_request_id
		 AND FCR.concurrent_program_id = (
		                                 SELECT concurrent_program_id
		                                 FROM fnd_concurrent_programs
		                                 WHERE concurrent_program_name='CESLRPROBAI2'
		                                 );
------------------------------------------------------------------------------------------
--  Waiting for Run SQL*Loader- BAI2 program to complete
------------------------------------------------------------------------------------------
        lc_error_loc := 'Waiting for Run SQL*Loader- BAI2 program to complete ';
		lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (
		                                                           request_id => ln_child_request_id
		                                                          ,interval   => '5'
		                                                          ,max_wait   => ''
		                                                          ,phase      => lc_phase
		                                                          ,status     => lc_status
		                                                          ,dev_phase  => lc_devphase
		                                                          ,dev_status => lc_devstatus
		                                                          ,message    => lc_message
		                                                          );
                                IF lb_req_status = TRUE AND lc_devphase= 'COMPLETE' THEN
				SELECT request_id
				INTO ln_child_request_id
				FROM fnd_concurrent_requests
				WHERE parent_request_id = ln_request_id
				AND concurrent_program_id =  (
											SELECT concurrent_program_id
											FROM fnd_concurrent_programs
											WHERE concurrent_program_name='CEBSLDR'
											);
------------------------------------------------------------------------------------------
    --  Waiting for Load Bank Statement Data program
------------------------------------------------------------------------------------------
					lc_error_loc := 'Waiting for Load Bank Statement Data program to complete ';
					lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (
					                                       request_id => ln_child_request_id
					                                      ,interval   => '5'
					                                      ,max_wait   => ''
					                                      ,phase      => lc_phase
					                                      ,status     => lc_status
					                                      ,dev_phase  => lc_devphase
					                                      ,dev_status => lc_devstatus
					                                      ,message    => lc_message
					                                      );
------------------------------------------------------------------------------------------
--  Submitting OD: CE Update Transaction Text program
------------------------------------------------------------------------------------------
FND_FILE.PUT_LINE (FND_FILE.LOG,'Submitting OD: CE Update Transaction Text program');
                            IF lb_req_status = TRUE AND lc_devphase= 'COMPLETE' THEN
                                 lc_error_loc := 'Submitting OD: CE Update Transaction Text program ';
                                 ln_request_id := FND_REQUEST.SUBMIT_REQUEST(
                                                                             application      => 'XXFIN'
                                                                             ,program          => 'XX_CE_BNK_STMT_PKG_UPD_TRX_TXT'
                                                                             ,description      => ''
                                                                             ,sub_request      => FALSE
                                                                             ,argument1        => p_creation_date
                                                                             ,argument2        => lc_org_id
                                                                             );
                                 COMMIT;
------------------------------------------------------------------------------------------
    --  Waiting for OD: CE Update Transaction Text program
    --  Added FND_CONCURRENT.WAIT_FOR_REQUEST as a part of the fix for Defect 9399
------------------------------------------------------------------------------------------
                                 lc_error_loc := 'Waiting for OD: CE Update Transaction Text program to complete ';
                                 lb_req_status := FND_CONCURRENT.WAIT_FOR_REQUEST (
					                                       request_id => ln_request_id
					                                      ,interval   => '5'
					                                      ,max_wait   => ''
					                                      ,phase      => lc_phase
					                                      ,status     => lc_status
					                                      ,dev_phase  => lc_devphase
					                                      ,dev_status => lc_devstatus
					                                      ,message    => lc_message
					                                      );
                            END IF;
			END IF;
		END IF;
      -- Following Code Added for Defect 9399
      ln_parent_request_id := FND_GLOBAL.CONC_REQUEST_ID;
      FOR lr_child_request IN lcu_child_requests(ln_parent_request_id)
      LOOP
         IF lr_child_request.status_code = 'E' THEN
            x_ret_code := 2;
            EXIT;
         ELSIF lr_child_request.status_code = 'G' THEN
            x_ret_code := 1;
         END IF;
      END LOOP;
      -- Code Changes for Defect 9399 over
   EXCEPTION
   WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while '||lc_error_loc);
   END SUBMIT_REQUEST;

 -- +===================================================================+
-- | Name : get_trx_desc                                               |
-- | Description : This returns the trx description for the given      |
-- |               trx code and bank account number                    |
-- |          OD: CE Update Transaction Text                           |
-- | Parameters : p_trx_code , p_bank_acct_num                         |
-- | Returns : transaction text description                            |
-- +===================================================================+
-- added for defect 12041

FUNCTION get_trx_desc(p_trx_code NUMBER
                     ,p_bank_acct_num NUMBER
                     )
RETURN VARCHAR2
AS
lc_trx_text ce_statement_lines_interface.trx_text%TYPE;
 BEGIN
   SELECT XFTV.target_value1
   INTO lc_trx_text
   FROM xx_fin_translatedefinition  XFTD, xx_fin_translatevalues XFTV
   where XFTV.translate_id = XFTD.translate_id
   AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
   AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
   AND XFTV.source_value1 = p_trx_code
   AND XFTV.source_value2= p_bank_acct_num
   AND XFTD.translation_name = 'XX_CE_BANK_TRX_CODES'
   AND XFTV.enabled_flag = 'Y'
   AND XFTD.enabled_flag = 'Y';
   RETURN (lc_trx_text);
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
    BEGIN
    SELECT XFTV.target_value1
   INTO lc_trx_text
   FROM xx_fin_translatedefinition  XFTD, xx_fin_translatevalues XFTV
   where XFTV.translate_id = XFTD.translate_id
   AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
   AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
   AND XFTV.source_value1 = p_trx_code
   AND XFTV.source_value2 is NULL
   AND XFTD.translation_name = 'XX_CE_BANK_TRX_CODES'
   AND XFTV.enabled_flag = 'Y'
   AND XFTD.enabled_flag = 'Y';
   RETURN (lc_trx_text);
   EXCEPTION
      WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'No description found for given trx code'|| SQLERRM);
      RETURN NULL;
      END;
 END get_trx_desc;
 -- +===================================================================+
-- | Name : get_inv_text                                               |
-- | Description : This returns the invoice_text for the given         |
-- |               trx code and bank account number                    |
-- |          OD: CE Update Transaction Text                           |
-- | Parameters : p_trx_code , p_bank_acct_num                         |
-- | Returns : Invoice text                                            |
-- +===================================================================+
-- added for defect 12041
 FUNCTION get_inv_text(p_trx_code NUMBER
                     ,p_bank_acct_num NUMBER
                     )
 RETURN VARCHAR2
AS
lc_inv_text VARCHAR2(100);
 BEGIN
   SELECT XFTV.target_value2
   INTO lc_inv_text
   FROM xx_fin_translatedefinition  XFTD, xx_fin_translatevalues XFTV
   where XFTV.translate_id = XFTD.translate_id
   AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,sysdate+1)
   AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,sysdate+1)
   AND XFTV.source_value1 = p_trx_code
   AND XFTV.source_value2= p_bank_acct_num
   AND XFTD.translation_name = 'XX_CE_BANK_TRX_CODES'
   AND XFTV.enabled_flag = 'Y'
   AND XFTD.enabled_flag = 'Y';
   RETURN lc_inv_text;
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN
         RETURN NULL;
 END get_INV_TEXT;
 END XX_CE_BANK_STMT_LOAD_PKG;
/
SHOW ERR;