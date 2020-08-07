SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
create or replace PACKAGE BODY OE_Credit_Card_Migrate_Util AS
-- $Header: OEXECCNB.pls 115.0.11510.8 2005/10/29 03:32:18 spooruli noship $
--+=======================================================================+
--|               Copyright (c) 2000 Oracle Corporation                   |
--|                       Redwood Shores, CA, USA                         |
--|                         All rights reserved.                          |
--+=======================================================================+
--| FILENAME                                                              |
--|    OEXECCNB.pls                                                       |
--|                                                                       |
--| DESCRIPTION                                                           |
--|    Package Spec of OE_Credit_Card_Migrate_Util                        |
--|	 This package body contains some utility procedures to            |
--|	 encrypt credit cards number from the following tables.           |
--|                                                                       |
--|      OE_ORDER_HEADERS_ALL                                             |
--|      OE_ORDER_HEADER_HISTORY                                          |
--|      OE_PAYMENTS                                                      |
--|                                                                       |
--| PROCEDURE LIST                                                        |
--|    Migrate_CC_Number_MGR                                              |
--|    Migrate_CC_Number_WKR                                              |
--|                                                                       |
--| HISTORY                                                               |
--|    SEP-06-2005 Initial creation                                       |
--|    OCT-28-2005 To exclude non-numeric CC# and length of CC# should    |
--|                be < 31                                                |
--+=======================================================================+

G_PKG_NAME    CONSTANT VARCHAR2(30) := 'OE_Credit_Card_Migrate_Util';

PROCEDURE Migrate_CC_Number_MGR
(   X_errbuf     OUT NOCOPY VARCHAR2,
    X_retcode    OUT NOCOPY VARCHAR2,
    X_batch_size  IN NUMBER,
    X_Num_Workers IN NUMBER
)
IS
  l_product                   VARCHAR2(30) := 'ONT' ;
BEGIN
  AD_CONC_UTILS_PKG.submit_subrequests(
               X_errbuf                   => X_errbuf,
               X_retcode                  => X_retcode,
               X_WorkerConc_app_shortname => l_product,
               X_workerConc_progname      => 'ONT_ENCRYPT_OLD_CARD_DATA_WKR',
               X_batch_size               => X_batch_size,
               X_Num_Workers              => X_Num_Workers) ;
END Migrate_CC_Number_MGR ;

PROCEDURE Migrate_CC_Number_WKR
(   X_errbuf     OUT NOCOPY VARCHAR2,
    X_retcode    OUT NOCOPY VARCHAR2,
    X_batch_size  IN NUMBER,
    X_Worker_Id   IN NUMBER,
    X_Num_Workers IN NUMBER
)
IS
  TYPE Num15Tab  IS TABLE OF NUMBER(15)   INDEX BY BINARY_INTEGER ;
  TYPE Char30Tab IS TABLE OF VARCHAR2(30) INDEX BY BINARY_INTEGER ;
  TYPE DateTab   IS TABLE OF DATE         INDEX BY BINARY_INTEGER ;

  c_header_id                 Num15Tab ;
  c_line_id                   Num15Tab ;
  c_payment_number            Num15Tab ;
  c_hist_creation_date        DateTab ;
  c_entity_id                 Num15Tab ;
  c_entity_number             Num15Tab ;
  c_attribute_id              Num15Tab ;
  c_old_attribute_value       Char30Tab ;
  c_new_attribute_value       Char30Tab ;
  c_cc_number                 Char30Tab ;
  c_cc_number_enc             Char30Tab ;
  c_cc_fk_id                  Num15Tab ;

  l_start_rowid               ROWID ;
  l_end_rowid                 ROWID ;
  l_rows_processed            NUMBER ;
  l_user_id                   NUMBER := NVL(fnd_global.user_id, -1) ;

  l_table_name                VARCHAR2(30) ;
  l_product                   VARCHAR2(30) := 'ONT' ;
  l_script_name               VARCHAR2(30) := 'OEXECCNB.pls' ;

  l_status                    VARCHAR2(30) ;
  l_industry                  VARCHAR2(30) ;
  l_retstatus                 BOOLEAN ;

  l_worker_id                 NUMBER ;
  l_num_workers               NUMBER ;
  l_table_owner               VARCHAR2(30) ;
  l_batch_size                VARCHAR2(30) ;
  l_any_rows_to_process       BOOLEAN ;

  -- parameters required by security features

  l_sys_key                   RAW(24) ;
  l_sub_key                   RAW(24) ;
  l_sub_key_cipher            IBY_SYS_SECURITY_SUBKEYS.SUBKEY_CIPHER_TEXT%TYPE ;
  l_sub_key_id                NUMBER ;

  l_new_key                   VARCHAR2(1) ;
  l_total                     NUMBER := 0 ;

  l_error_total1              NUMBER := 0 ;
  l_error_total2              NUMBER := 0 ;
  l_process_total             NUMBER := 0 ;

  l_debug_level               CONSTANT NUMBER := oe_debug_pub.g_debug_level ;

  -- Cursor that queries all transactions needed to be migrated
  -- Filter the records that are already encrypted
  -- The last above two where clauses will make sure the credit card number will not be re-encrypted

  CURSOR oe_order_headers_all_cur(p_start_rowid ROWID, p_end_rowid ROWID) is
      SELECT /*+ rowid(OOH) */
             OOH.header_id,
	     TRANSLATE(OOH.credit_card_number,'0: -_', '0')
        FROM OE_ORDER_HEADERS_ALL OOH
       WHERE OOH.Rowid BETWEEN p_start_rowid AND p_end_rowid
         AND OOH.payment_type_code = 'CREDIT_CARD'
         AND LENGTH(TRANSLATE(OOH.credit_card_number,'0: -_', '0')) < 31
         AND LENGTH(TRIM(TRANSLATE(OOH.credit_card_number, ' -.:_0123456789',' '))) IS NULL
	 AND SUBSTR(OOH.credit_card_number, 1,1) <> '9'
         AND LENGTH(OOH.credit_card_number) <> 25 ;

  CURSOR oe_order_header_history_cur(p_start_rowid ROWID, p_end_rowid ROWID) is
      SELECT /*+ rowid(OHH) */
	     OHH.header_id,
	     OHH.hist_creation_date,
	     TRANSLATE(OHH.credit_card_number,'0: -_', '0')
        FROM OE_ORDER_HEADER_HISTORY OHH
       WHERE OHH.Rowid BETWEEN p_start_rowid AND p_end_rowid
         AND OHH.payment_type_code = 'CREDIT_CARD'
         AND LENGTH(TRANSLATE(OHH.credit_card_number,'0: -_', '0')) < 31
         AND LENGTH(TRIM(TRANSLATE(OHH.credit_card_number, ' -.:_0123456789',' '))) IS NULL
         AND SUBSTR(OHH.credit_card_number, 1,1) <> '9'
         AND LENGTH(OHH.credit_card_number) <> 25 ;

  CURSOR oe_payments_cur(p_start_rowid ROWID, p_end_rowid ROWID) is
      SELECT /*+ rowid(OP) */
	     OP.header_id,
	     OP.line_id,
	     OP.payment_number,
	     TRANSLATE(OP.credit_card_number,'0: -_', '0')
	FROM OE_PAYMENTS OP
       WHERE OP.Rowid BETWEEN p_start_rowid AND p_end_rowid
         AND OP.payment_type_code = 'CREDIT_CARD'
         AND LENGTH(TRANSLATE(OP.credit_card_number,'0: -_', '0')) < 31
         AND LENGTH(TRIM(TRANSLATE(OP.credit_card_number, ' -.:_0123456789',' '))) IS NULL
	 AND SUBSTR(OP.credit_card_number, 1,1) <> '9'
	 AND LENGTH(OP.credit_card_number) <> 25 ;

  CURSOR oe_audit_attr_history_cur(p_start_rowid ROWID, p_end_rowid ROWID) is
      SELECT /*+ rowid(OP) */
	     OAA.hist_creation_date,
	     OAA.entity_id,
	     OAA.entity_number,
	     OAA.attribute_id,
	     TRANSLATE(OAA.old_attribute_value,'0: -_', '0'),
	     TRANSLATE(OAA.new_attribute_value,'0: -_', '0')
	FROM OE_AUDIT_ATTR_HISTORY OAA
       WHERE OAA.Rowid BETWEEN p_start_rowid AND p_end_rowid
         AND OAA.attribute_id = 49
         AND LENGTH(TRANSLATE(OAA.old_attribute_value,'0: -_', '0')) < 31
         AND LENGTH(TRIM(TRANSLATE(OAA.old_attribute_value, ' -.:_0123456789',' '))) IS NULL
         AND LENGTH(TRANSLATE(OAA.new_attribute_value,'0: -_', '0')) < 31
         AND LENGTH(TRIM(TRANSLATE(OAA.new_attribute_value, ' -.:_0123456789',' '))) IS NULL
	 AND ((SUBSTR(OAA.old_attribute_value, 1,1) <> 'X')
	  OR  (SUBSTR(OAA.new_attribute_value, 1,1) <> 'X')) ;

BEGIN
   --
   -- get schema name of the table for ROWID range processing
   --
   l_retstatus := fnd_installation.get_app_info(l_product, l_status, l_industry, l_table_owner) ;

   IF ((l_retstatus = FALSE)
       OR
       (l_table_owner is null))
   THEN
      raise_application_error(-20001,
         'Cannot get schema name for product : ' || l_product) ;
   END IF ;

   -- Check whether the credit card encryption option is turned on or not
   IF (NOT iby_cc_security_pub.encryption_enabled()) THEN
      raise_application_error(-20001,
       'CC Encryption not enabled for product : ' || l_product) ;
       RETURN ;
   END IF ;

   -----------------------------------------------------------
   -- Log Output file
   -----------------------------------------------------------
   fnd_file.put_line(FND_FILE.OUTPUT, '');
   fnd_file.put_line(FND_FILE.OUTPUT, 'Encrypt OM Historical Card Data');
   fnd_file.put_line(FND_FILE.OUTPUT, '');
   fnd_file.put_line(FND_FILE.OUTPUT, 'Concurrent Program Parameters');
   fnd_file.put_line(FND_FILE.OUTPUT, 'Batch Size        : '|| X_batch_size);
   fnd_file.put_line(FND_FILE.OUTPUT, 'Number of Threads : '|| X_num_workers);

   BEGIN
     -----------------------------------------------------------
     -- Fetching records from OE_ORDER_HEADERS_ALL table
     -----------------------------------------------------------
     l_table_name := 'OE_ORDER_HEADERS_ALL' ;

     ad_parallel_updates_pkg.delete_update_information(
	             0,
	             l_table_owner,
	             l_table_name,
	             l_script_name ) ;

     ad_parallel_updates_pkg.initialize_rowid_range(
	             ad_parallel_updates_pkg.ROWID_RANGE,
	             l_table_owner,
	             l_table_name,
	             l_script_name,
	             X_worker_id,
	             X_num_workers,
	             X_batch_size, 0) ;

     ad_parallel_updates_pkg.get_rowid_range(
	             l_start_rowid,
	             l_end_rowid,
	             l_any_rows_to_process,
	             X_batch_size,
	             TRUE) ;

     fnd_file.put_line(FND_FILE.OUTPUT, '');
     fnd_file.put_line(FND_FILE.OUTPUT, 'Process starting from OE_ORDER_HEADERS_ALL table');

     IF l_debug_level  > 0 THEN
        oe_debug_pub.add('') ;
        oe_debug_pub.add('AD parallel details: ') ;
        oe_debug_pub.add('') ;
        oe_debug_pub.add('Table owner  : ' || l_table_owner) ;
        oe_debug_pub.add('Table name   : ' || l_table_name) ;
        oe_debug_pub.add('Batch Size   : ' || X_batch_size) ;
        oe_debug_pub.add('Worker ID    : ' || X_worker_id) ;
        oe_debug_pub.add('No of Workers: ' || X_num_workers) ;
     END IF ;

     l_new_key       := 'Y' ;
     l_total         := 0 ;

     l_error_total1  := 0 ;
     l_error_total2  := 0 ;
     l_process_total := 0 ;

     WHILE (l_any_rows_to_process = TRUE) LOOP
       IF (l_new_key = 'Y') THEN
          -- get the subkey required by IBY for this worker.
          -- Note: This piece of code gets a new sub key for every 1000 records for each worker.

          l_new_key := 'N' ;

          l_sys_key := IBY_SECURITY_PKG.get_sys_key_raw();

	  l_sub_key := dbms_obfuscation_toolkit.des3getkey
	        (seed => Fnd_Crypto.randombytes(IBY_SECURITY_PKG.C_DES3_MAX_KEY_LEN * 8),
                which => dbms_obfuscation_toolkit.ThreeKeyMode
	        );

	  l_sub_key_cipher :=
	        dbms_obfuscation_toolkit.des3encrypt
	         ( input => l_sub_key,
	             key => l_sys_key,
                   which => dbms_obfuscation_toolkit.ThreeKeyMode
                  ) ;

          -- Insert into sub key table
          INSERT INTO iby_sys_security_subkeys
	      (sec_subkey_id,
	       subkey_cipher_text,
	       use_count,
	       created_by,
	       creation_date,
	       last_updated_by,
	       last_update_date,
	       last_update_login,
	       object_version_number)
	      VALUES
	      (iby_sys_security_subkeys_s.NEXTVAL,
	       l_sub_key_cipher,
	       X_batch_size,
	       l_user_id,
	       sysdate,
	       l_user_id,
	       sysdate,
	       l_user_id,
	       1)
	       RETURNING sec_subkey_id INTO l_sub_key_id ;
       END IF;

       -- Fetch the transactions
       OPEN oe_order_headers_all_cur(l_start_rowid, l_end_rowid) ;

       FETCH oe_order_headers_all_cur BULK COLLECT INTO
	 c_header_id, c_cc_number
       LIMIT X_batch_size ;

       CLOSE oe_order_headers_all_cur ;

--       oe_debug_pub.add('Number of Records : ' || c_cc_number.count) ;

       -- Perform encryption on the cc number column
       -- bulk insert into credit card encryption table, and get foreign key back
       -- Note: You shouldn't change the following sql statement except the variables

       IF c_cc_number.count > 0 THEN
          BEGIN
            FORALL i in c_header_id.first..c_header_id.last SAVE EXCEPTIONS
              INSERT INTO iby_security_segments
                (
                 sec_segment_id,
                 segment_cipher_text,
                 sec_subkey_id,
                 cc_number_hash1,
                 cc_number_hash2,
                 cc_issuer_range_id,
                 cc_number_length,
                 encoding_scheme,
                 cc_unmask_digits,
                 created_by,
                 creation_date,
                 last_updated_by,
                 last_update_date,
                 last_update_login,
                 object_version_number)
               VALUES
                 (
                  iby_security_segments_s.nextval,
                  iby_creditcard_pkg.cipher_ccnumber(c_cc_number(i), l_sub_key),
                  l_sub_key_id,
                  IBY_CC_SECURITY_PUB.get_hash(c_cc_number(i), FND_API.G_FALSE),
                  IBY_CC_SECURITY_PUB.get_hash(c_cc_number(i), FND_API.G_TRUE),
                  iby_cc_validate.get_cc_issuer_range(c_cc_number(i)),
                  LENGTH(iby_cc_validate.stripCC(c_cc_number(i),' -')),
                  'NUMERIC',
                  IBY_CC_SECURITY_PUB.get_unmasked_digits(c_cc_number(i)),
                  l_user_id,
                  sysdate,
                  l_user_id,
                  sysdate,
                  l_user_id,
                  1)
                RETURNING sec_segment_id BULK COLLECT INTO c_cc_fk_id ;
          EXCEPTION
	     WHEN OTHERS THEN
               l_error_total1  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Insert failing at IBY_SECURITY_SEGMENTS from OE_ORDER_HEADERS_ALL_CUR for Header ID ' ||
		         c_header_id(j));
               END LOOP;
          END;

	  -- Update the CREDIT_CARD_NUMBER field with the new encrypted value
          BEGIN
            FORALL i in c_header_id.first..c_header_id.last SAVE EXCEPTIONS
	      UPDATE OE_ORDER_HEADERS_ALL
	         SET CREDIT_CARD_NUMBER =
	             iby_cc_security_pub.get_secure_card_ref(c_cc_fk_id(i), c_cc_number(i))
 	       WHERE payment_type_code = 'CREDIT_CARD'
                 AND header_id         = c_header_id(i) ;
	  EXCEPTION
	     WHEN OTHERS THEN
               l_error_total2  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Update failing at OE_ORDER_HEADERS_ALL from OE_ORDER_HEADERS_ALL_CUR for Header ID ' ||
		         c_header_id(j));
               END LOOP;
          END;

          l_rows_processed := SQL%ROWCOUNT ;

          l_total          := l_total + l_rows_processed ;

          l_process_total  := l_process_total + l_total ;

          IF (l_total > 1000) THEN
              l_new_key := 'Y' ;
              l_total   := 0 ;
          END IF;
       END IF ;

       ad_parallel_updates_pkg.processed_rowid_range
	                        (l_rows_processed,
	                         l_end_rowid) ;

       COMMIT ;

       ad_parallel_updates_pkg.get_rowid_range
	                        (l_start_rowid,
	                         l_end_rowid,
	                         l_any_rows_to_process,
	                         X_batch_size,
	                         FALSE) ;
     END LOOP ;

     oe_debug_pub.add('Total No of records processed successfully             : ' || l_process_total) ;
     oe_debug_pub.add('Total No of records errored in IBY_SECURITY_SEGMENTS   : ' || l_error_total1) ;
     oe_debug_pub.add('Total No of records errored in OE_ORDER_HEADERS_ALL    : ' || l_error_total2) ;

     fnd_file.put_line(FND_FILE.OUTPUT, 'Process ending from OE_ORDER_HEADERS_ALL table') ;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add('') ;
         oe_debug_pub.add('No record found from OE_ORDER_HEADERS_ALL table for Worker Id : ' || X_worker_id) ;

         fnd_file.put_line(FND_FILE.OUTPUT, 'No record found from OE_ORDER_HEADERS_ALL table for Worker Id : ' || X_worker_id) ;
  END ;

  BEGIN
     -----------------------------------------------------------
     -- Fetching records from OE_ORDER_HEADER_HISTORY table
     -----------------------------------------------------------
     l_table_name := 'OE_ORDER_HEADER_HISTORY' ;

     ad_parallel_updates_pkg.delete_update_information(
	             0,
	             l_table_owner,
	             l_table_name,
	             l_script_name ) ;

     ad_parallel_updates_pkg.initialize_rowid_range(
	             ad_parallel_updates_pkg.ROWID_RANGE,
	             l_table_owner,
	             l_table_name,
	             l_script_name,
	             X_worker_id,
	             X_num_workers,
	             X_batch_size, 0) ;

     ad_parallel_updates_pkg.get_rowid_range(
	             l_start_rowid,
	             l_end_rowid,
	             l_any_rows_to_process,
	             X_batch_size,
	             TRUE) ;

     fnd_file.put_line(FND_FILE.OUTPUT, '');
     fnd_file.put_line(FND_FILE.OUTPUT, 'Process starting from OE_ORDER_HEADER_HISTORY table');

     IF l_debug_level  > 0 THEN
        oe_debug_pub.add('') ;
        oe_debug_pub.add('AD parallel details: ') ;
        oe_debug_pub.add('') ;
        oe_debug_pub.add('Table owner  : ' || l_table_owner) ;
        oe_debug_pub.add('Table name   : ' || l_table_name) ;
        oe_debug_pub.add('Batch Size   : ' || X_batch_size) ;
        oe_debug_pub.add('Worker ID    : ' || X_worker_id) ;
        oe_debug_pub.add('No of Workers: ' || X_num_workers) ;
     END IF ;

     l_new_key       := 'Y' ;
     l_total         := 0 ;

     l_error_total1  := 0 ;
     l_error_total2  := 0 ;
     l_process_total := 0 ;

     WHILE (l_any_rows_to_process = TRUE) LOOP
       IF (l_new_key = 'Y') THEN
          -- get the subkey required by IBY for this worker.
          -- Note: This piece of code gets a new sub key for every 1000 records for each worker.

          l_new_key := 'N' ;

          l_sys_key := IBY_SECURITY_PKG.get_sys_key_raw();

	  l_sub_key := dbms_obfuscation_toolkit.des3getkey
	        (seed => Fnd_Crypto.randombytes(IBY_SECURITY_PKG.C_DES3_MAX_KEY_LEN * 8),
                which => dbms_obfuscation_toolkit.ThreeKeyMode
	        );

	  l_sub_key_cipher :=
	        dbms_obfuscation_toolkit.des3encrypt
	         ( input => l_sub_key,
	             key => l_sys_key,
                   which => dbms_obfuscation_toolkit.ThreeKeyMode
                  ) ;

          -- Insert into sub key table
          INSERT INTO iby_sys_security_subkeys
	      (sec_subkey_id,
	       subkey_cipher_text,
	       use_count,
	       created_by,
	       creation_date,
	       last_updated_by,
	       last_update_date,
	       last_update_login,
	       object_version_number)
	      VALUES
	      (iby_sys_security_subkeys_s.NEXTVAL,
	       l_sub_key_cipher,
	       X_batch_size,
	       l_user_id,
	       sysdate,
	       l_user_id,
	       sysdate,
	       l_user_id,
	       1)
	       RETURNING sec_subkey_id INTO l_sub_key_id ;
       END IF;

       -- Fetch the transactions
       OPEN oe_order_header_history_cur(l_start_rowid, l_end_rowid) ;

       FETCH oe_order_header_history_cur BULK COLLECT INTO
	 c_header_id, c_hist_creation_date, c_cc_number
       LIMIT X_batch_size ;

       CLOSE oe_order_header_history_cur ;

--       oe_debug_pub.add('Number of Records : ' || c_cc_number.count) ;

       -- Perform encryption on the cc number column
       -- bulk insert into credit card encryption table, and get foreign key back
       -- Note: You shouldn't change the following sql statement except the variables

       IF c_cc_number.count > 0 THEN
          BEGIN
            FORALL i in c_header_id.first..c_header_id.last SAVE EXCEPTIONS
              INSERT INTO iby_security_segments
                (
                 sec_segment_id,
                 segment_cipher_text,
                 sec_subkey_id,
                 cc_number_hash1,
                 cc_number_hash2,
                 cc_issuer_range_id,
                 cc_number_length,
                 encoding_scheme,
                 cc_unmask_digits,
                 created_by,
                 creation_date,
                 last_updated_by,
                 last_update_date,
                 last_update_login,
                 object_version_number)
               VALUES
                 (
                  iby_security_segments_s.nextval,
                  iby_creditcard_pkg.cipher_ccnumber(c_cc_number(i), l_sub_key),
                  l_sub_key_id,
                  IBY_CC_SECURITY_PUB.get_hash(c_cc_number(i), FND_API.G_FALSE),
                  IBY_CC_SECURITY_PUB.get_hash(c_cc_number(i), FND_API.G_TRUE),
                  iby_cc_validate.get_cc_issuer_range(c_cc_number(i)),
                  LENGTH(iby_cc_validate.stripCC(c_cc_number(i),' -')),
                  'NUMERIC',
                  IBY_CC_SECURITY_PUB.get_unmasked_digits(c_cc_number(i)),
                  l_user_id,
                  sysdate,
                  l_user_id,
                  sysdate,
                  l_user_id,
                  1)
                RETURNING sec_segment_id BULK COLLECT INTO c_cc_fk_id ;
          EXCEPTION
	     WHEN OTHERS THEN
               l_error_total1  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Insert failing at IBY_SECURITY_SEGMENTS from OE_ORDER_HEADERS_ALL_CUR for Header ID ' ||
		         c_header_id(j));
               END LOOP;
          END;

	  -- Update the CREDIT_CARD_NUMBER field with the new encrypted value
          BEGIN
            FORALL i in c_header_id.first..c_header_id.last SAVE EXCEPTIONS
	      UPDATE OE_ORDER_HEADER_HISTORY
	         SET CREDIT_CARD_NUMBER =
	             iby_cc_security_pub.get_secure_card_ref(c_cc_fk_id(i), c_cc_number(i))
 	       WHERE payment_type_code  = 'CREDIT_CARD'
		 AND hist_creation_date = c_hist_creation_date(i)
		 AND header_id          = c_header_id(i) ;
          EXCEPTION
	     WHEN OTHERS THEN
               l_error_total2  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Update failing at OE_ORDER_HEADER_HISTORY from OE_ORDER_HEADER_HISTORY_CUR for Header ID ' ||
		         c_header_id(j));
               END LOOP;
          END;

	  l_rows_processed := SQL%ROWCOUNT ;

          l_total          := l_total + l_rows_processed ;

          l_process_total  := l_process_total + l_total ;

          IF (l_total > 1000) THEN
              l_new_key := 'Y' ;
              l_total   := 0 ;
          END IF;
       END IF ;

       ad_parallel_updates_pkg.processed_rowid_range
	                        (l_rows_processed,
	                         l_end_rowid) ;

       COMMIT ;

       ad_parallel_updates_pkg.get_rowid_range
	                        (l_start_rowid,
	                         l_end_rowid,
	                         l_any_rows_to_process,
	                         X_batch_size,
	                         FALSE) ;
     END LOOP ;

     oe_debug_pub.add('Total No of records processed successfully             : ' || l_process_total) ;
     oe_debug_pub.add('Total No of records errored in IBY_SECURITY_SEGMENTS   : ' || l_error_total1) ;
     oe_debug_pub.add('Total No of records errored in OE_ORDER_HEADER_HISTORY : ' || l_error_total2) ;

     fnd_file.put_line(FND_FILE.OUTPUT, 'Process ending from OE_ORDER_HEADER_HISTORY table') ;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add('') ;
         oe_debug_pub.add('No record found from OE_ORDER_HEADER_HISTORY table for Worker Id : ' || X_worker_id) ;

         fnd_file.put_line(FND_FILE.OUTPUT, 'No record found from OE_ORDER_HEADER_HISTORY table for Worker Id : ' || X_worker_id) ;
  END ;

  BEGIN
     -----------------------------------------------------------
     -- Fetching records from OE_PAYMENTS table
     -----------------------------------------------------------
     l_table_name := 'OE_PAYMENTS' ;

     ad_parallel_updates_pkg.delete_update_information(
	             0,
	             l_table_owner,
	             l_table_name,
	             l_script_name ) ;

     ad_parallel_updates_pkg.initialize_rowid_range(
	             ad_parallel_updates_pkg.ROWID_RANGE,
	             l_table_owner,
	             l_table_name,
	             l_script_name,
	             X_worker_id,
	             X_num_workers,
	             X_batch_size, 0) ;

     ad_parallel_updates_pkg.get_rowid_range(
	             l_start_rowid,
	             l_end_rowid,
	             l_any_rows_to_process,
	             X_batch_size,
	             TRUE) ;

     fnd_file.put_line(FND_FILE.OUTPUT, '');
     fnd_file.put_line(FND_FILE.OUTPUT, 'Process starting from OE_PAYMENTS table');

     IF l_debug_level  > 0 THEN
        oe_debug_pub.add('') ;
        oe_debug_pub.add('AD parallel details: ') ;
        oe_debug_pub.add('') ;
        oe_debug_pub.add('Table owner  : ' || l_table_owner) ;
        oe_debug_pub.add('Table name   : ' || l_table_name) ;
        oe_debug_pub.add('Batch Size   : ' || X_batch_size) ;
        oe_debug_pub.add('Worker ID    : ' || X_worker_id) ;
        oe_debug_pub.add('No of Workers: ' || X_num_workers) ;
     END IF ;

     l_new_key       := 'Y' ;
     l_total         := 0 ;

     l_error_total1  := 0 ;
     l_error_total2  := 0 ;
     l_process_total := 0 ;

     WHILE (l_any_rows_to_process = TRUE) LOOP
       IF (l_new_key = 'Y') THEN
          -- get the subkey required by IBY for this worker.
          -- Note: This piece of code gets a new sub key for every 1000 records for each worker.

          l_new_key := 'N' ;

          l_sys_key := IBY_SECURITY_PKG.get_sys_key_raw();

	  l_sub_key := dbms_obfuscation_toolkit.des3getkey
	        (seed => Fnd_Crypto.randombytes(IBY_SECURITY_PKG.C_DES3_MAX_KEY_LEN * 8),
                which => dbms_obfuscation_toolkit.ThreeKeyMode
	        );

	  l_sub_key_cipher :=
	        dbms_obfuscation_toolkit.des3encrypt
	         ( input => l_sub_key,
	             key => l_sys_key,
                   which => dbms_obfuscation_toolkit.ThreeKeyMode
                  ) ;

          -- Insert into sub key table
          INSERT INTO iby_sys_security_subkeys
	      (sec_subkey_id,
	       subkey_cipher_text,
	       use_count,
	       created_by,
	       creation_date,
	       last_updated_by,
	       last_update_date,
	       last_update_login,
	       object_version_number)
	      VALUES
	      (iby_sys_security_subkeys_s.NEXTVAL,
	       l_sub_key_cipher,
	       X_batch_size,
	       l_user_id,
	       sysdate,
	       l_user_id,
	       sysdate,
	       l_user_id,
	       1)
	       RETURNING sec_subkey_id INTO l_sub_key_id ;
       END IF;

       -- Fetch the transactions
       OPEN oe_payments_cur(l_start_rowid, l_end_rowid) ;

       FETCH oe_payments_cur BULK COLLECT INTO
	 c_header_id, c_line_id, c_payment_number, c_cc_number
       LIMIT X_batch_size ;

       CLOSE oe_payments_cur ;

--       oe_debug_pub.add('Number of Records : ' || c_cc_number.count) ;

       -- Perform encryption on the cc number column
       -- bulk insert into credit card encryption table, and get foreign key back
       -- Note: You shouldn't change the following sql statement except the variables

       IF c_cc_number.count > 0 THEN
          BEGIN
            FORALL i in c_header_id.first..c_header_id.last SAVE EXCEPTIONS
              INSERT INTO iby_security_segments
                (
                 sec_segment_id,
                 segment_cipher_text,
                 sec_subkey_id,
                 cc_number_hash1,
                 cc_number_hash2,
                 cc_issuer_range_id,
                 cc_number_length,
                 encoding_scheme,
                 cc_unmask_digits,
                 created_by,
                 creation_date,
                 last_updated_by,
                 last_update_date,
                 last_update_login,
                 object_version_number)
               VALUES
                 (
                  iby_security_segments_s.nextval,
                  iby_creditcard_pkg.cipher_ccnumber(c_cc_number(i), l_sub_key),
                  l_sub_key_id,
                  IBY_CC_SECURITY_PUB.get_hash(c_cc_number(i), FND_API.G_FALSE),
                  IBY_CC_SECURITY_PUB.get_hash(c_cc_number(i), FND_API.G_TRUE),
                  iby_cc_validate.get_cc_issuer_range(c_cc_number(i)),
                  LENGTH(iby_cc_validate.stripCC(c_cc_number(i),' -')),
                  'NUMERIC',
                  IBY_CC_SECURITY_PUB.get_unmasked_digits(c_cc_number(i)),
                  l_user_id,
                  sysdate,
                  l_user_id,
                  sysdate,
                  l_user_id,
                  1)
                RETURNING sec_segment_id BULK COLLECT INTO c_cc_fk_id ;
          EXCEPTION
	     WHEN OTHERS THEN
               l_error_total1  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Insert failing at IBY_SECURITY_SEGMENTS from OE_PAYMENTS_CUR for Header ID ' ||
		         c_header_id(j));
               END LOOP;
          END;

	  -- Update the CREDIT_CARD_NUMBER field with the new encrypted value
          BEGIN
            FORALL i in c_header_id.first..c_header_id.last SAVE EXCEPTIONS
	         UPDATE OE_PAYMENTS
	            SET CREDIT_CARD_NUMBER =
	                iby_cc_security_pub.get_secure_card_ref(c_cc_fk_id(i), c_cc_number(i))
                  WHERE payment_type_code = 'CREDIT_CARD'
	            AND header_id         = c_header_id(i)
		    AND NVL(line_id,-99)  = NVL(c_line_id(i),-99)
 	            AND payment_number    = c_payment_number(i) ;
          EXCEPTION
	     WHEN OTHERS THEN
               l_error_total2  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Update failing at OE_PAYMENTS from OE_PAYMENTS_CUR for Header ID ' ||
		         c_header_id(j));
               END LOOP;
          END;

	  l_rows_processed := SQL%ROWCOUNT ;

          l_total          := l_total + l_rows_processed ;

          l_process_total  := l_process_total + l_total ;

          IF (l_total > 1000) THEN
              l_new_key := 'Y' ;
              l_total   := 0 ;
          END IF;
       END IF ;

       ad_parallel_updates_pkg.processed_rowid_range
	                        (l_rows_processed,
	                         l_end_rowid) ;

       COMMIT ;

       ad_parallel_updates_pkg.get_rowid_range
	                        (l_start_rowid,
	                         l_end_rowid,
	                         l_any_rows_to_process,
	                         X_batch_size,
	                         FALSE) ;
     END LOOP ;

     oe_debug_pub.add('Total No of records processed successfully             : ' || l_process_total) ;
     oe_debug_pub.add('Total No of records errored in IBY_SECURITY_SEGMENTS   : ' || l_error_total1) ;
     oe_debug_pub.add('Total No of records errored in OE_PAYMENTS             : ' || l_error_total2) ;

     fnd_file.put_line(FND_FILE.OUTPUT, 'Process ending from OE_PAYMENTS table');

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add('') ;
         oe_debug_pub.add('No record found from OE_PAYMENTS table for Worker Id : ' || X_worker_id) ;

         fnd_file.put_line(FND_FILE.OUTPUT, 'No record found from OE_PAYMENTS table for Worker Id : ' || X_worker_id) ;
  END ;

  BEGIN
     -----------------------------------------------------------
     -- Fetching records from OE_AUDIT_ATTR_HISTORY table
     -----------------------------------------------------------
     l_table_name := 'OE_AUDIT_ATTR_HISTORY' ;

     ad_parallel_updates_pkg.delete_update_information(
	             0,
	             l_table_owner,
	             l_table_name,
	             l_script_name ) ;

     ad_parallel_updates_pkg.initialize_rowid_range(
	             ad_parallel_updates_pkg.ROWID_RANGE,
	             l_table_owner,
	             l_table_name,
	             l_script_name,
	             X_worker_id,
	             X_num_workers,
	             X_batch_size, 0) ;

     ad_parallel_updates_pkg.get_rowid_range(
	             l_start_rowid,
	             l_end_rowid,
	             l_any_rows_to_process,
	             X_batch_size,
	             TRUE) ;

     fnd_file.put_line(FND_FILE.OUTPUT, '');
     fnd_file.put_line(FND_FILE.OUTPUT, 'Process starting from OE_AUDIT_ATTR_HISTORY table');

     IF l_debug_level  > 0 THEN
        oe_debug_pub.add('') ;
        oe_debug_pub.add('AD parallel details: ') ;
        oe_debug_pub.add('') ;
        oe_debug_pub.add('Table owner  : ' || l_table_owner) ;
        oe_debug_pub.add('Table name   : ' || l_table_name) ;
        oe_debug_pub.add('Batch Size   : ' || X_batch_size) ;
        oe_debug_pub.add('Worker ID    : ' || X_worker_id) ;
        oe_debug_pub.add('No of Workers: ' || X_num_workers) ;
     END IF ;

     l_error_total1  := 0 ;
     l_process_total := 0 ;

     WHILE (l_any_rows_to_process = TRUE) LOOP
       -- Fetch the transactions
       OPEN oe_audit_attr_history_cur(l_start_rowid, l_end_rowid) ;

       FETCH oe_audit_attr_history_cur BULK COLLECT INTO
	 c_hist_creation_date, c_entity_id, c_entity_number, c_attribute_id, c_old_attribute_value, c_new_attribute_value
       LIMIT X_batch_size ;

       CLOSE oe_audit_attr_history_cur ;

--       oe_debug_pub.add('Number of Records : ' || c_entity_number.count) ;

       IF c_entity_number.count > 0 THEN
	  -- Update the CREDIT_CARD_NUMBER field with the mask credit card number value
          BEGIN
            FORALL i in c_entity_number.first..c_entity_number.last SAVE EXCEPTIONS
	         UPDATE OE_AUDIT_ATTR_HISTORY
	            SET OLD_ATTRIBUTE_VALUE = iby_cc_security_pub.Mask_Card_Number(c_old_attribute_value(i)),
	                NEW_ATTRIBUTE_VALUE = iby_cc_security_pub.Mask_Card_Number(c_new_attribute_value(i))
		  WHERE hist_creation_date = c_hist_creation_date(i)
		    AND entity_id          = c_entity_id(i)
	            AND entity_number      = c_entity_number(i)
		    AND attribute_id       = c_attribute_id(i) ;
	  EXCEPTION
	     WHEN OTHERS THEN
               l_error_total1  := SQL%BULK_EXCEPTIONS.COUNT ;

	       FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
		   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Error occurred during iteration ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_INDEX ||
                         ' Oracle error is ' ||
                         SQL%BULK_EXCEPTIONS(j).ERROR_CODE );

                   fnd_file.put_line(FND_FILE.OUTPUT,
		        'Update failing at OE_PAYMENTS from OE_PAYMENTS_CUR for Entity Number ' ||
		         c_entity_number(j));
               END LOOP;
          END;

	  l_rows_processed := SQL%ROWCOUNT ;

          l_process_total  := l_process_total + l_rows_processed ;

       END IF ;

       ad_parallel_updates_pkg.processed_rowid_range
	                        (l_rows_processed,
	                         l_end_rowid) ;

       COMMIT ;

       ad_parallel_updates_pkg.get_rowid_range
	                        (l_start_rowid,
	                         l_end_rowid,
	                         l_any_rows_to_process,
	                         X_batch_size,
	                         FALSE) ;
     END LOOP ;

     oe_debug_pub.add('Total No of records processed successfully             : ' || l_process_total) ;
     oe_debug_pub.add('Total No of records errored in OE_AUDIT_ATTR_HISTORY   : ' || l_error_total1) ;

     fnd_file.put_line(FND_FILE.OUTPUT, 'Process ending from OE_AUDIT_ATTR_HISTORY table');

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
         oe_debug_pub.add('') ;
         oe_debug_pub.add('No record found from OE_AUDIT_ATTR_HISTORY table for Worker Id : ' || X_worker_id) ;

         fnd_file.put_line(FND_FILE.OUTPUT, 'No record found from OE_AUDIT_ATTR_HISTORY table for Worker Id : ' || X_worker_id) ;
  END ;

  COMMIT ;

  X_retcode := AD_CONC_UTILS_PKG.CONC_SUCCESS;

EXCEPTION
   WHEN FND_API.G_EXC_ERROR THEN
       X_retcode := AD_CONC_UTILS_PKG.CONC_FAIL ;

       IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
          OE_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, 'Migrate_CC_Number_WKR');
       END IF;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request Error : '||substr(sqlerrm,1,200));
   WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
       X_retcode := AD_CONC_UTILS_PKG.CONC_FAIL ;

       IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
          OE_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, 'Migrate_CC_Number_WKR');
       END IF;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request Error : '||substr(sqlerrm,1,200));
   WHEN OTHERS THEN
       X_retcode := AD_CONC_UTILS_PKG.CONC_FAIL ;

       IF OE_MSG_PUB.Check_Msg_Level(OE_MSG_PUB.G_MSG_LVL_UNEXP_ERROR) THEN
          OE_MSG_PUB.Add_Exc_Msg (G_PKG_NAME, 'Migrate_CC_Number_WKR');
       END IF;

       FND_FILE.PUT_LINE(FND_FILE.LOG,'Concurrent Request Error : '||substr(sqlerrm,1,200));
END Migrate_CC_Number_WKR ;

END OE_Credit_Card_Migrate_Util ;
/
SHOW ERRORS;
EXIT;
