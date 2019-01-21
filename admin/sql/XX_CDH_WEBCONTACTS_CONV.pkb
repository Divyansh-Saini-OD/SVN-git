CREATE OR REPLACE PACKAGE BODY XX_CDH_WEBCONTACTS_CONV
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_RESP_PKG                                                           |
-- | Description : Package body for E1328_BSD_iReceivables_interface                                    |
-- |               This package performs the following                                                  |
-- |               1. Setup the contact at a bill to level                                              |
-- |               2. Insert web user details into xx_external_users                                    |
-- |               3. Assign responsibilites and party id  when the webuser is created in fnd_user      |
-- |                                                                                                    |
-- |                                                                                                    |
-- |                                                                                                    |
-- |Change Record:                                                                                      |
-- |===============                                                                                     |
-- |Version   Date        Author             Remarks                                                    |
-- |========  =========== ================== ===========================================================|
-- |1.0       30-Jan-2008 Alok Sahay         Initial draft version.      			 	                    |
-- |                                                                                                    |
-- +====================================================================================================+
*/

   g_pkg_name                     CONSTANT VARCHAR2(30)  := 'XX_CDH_WEBCONTACTS_CONV';

   PROCEDURE write_log( p_msg VARCHAR2);

   -- ===========================================================================
   -- Name             : write_log
   -- Description      : Writes a message to the concurrent log
   --
   -- Parameters :      p_msg          : Message
   --
   -- ===========================================================================
   PROCEDURE write_log( p_msg VARCHAR2)
   IS
     PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
        fnd_file.put_line (fnd_file.log, p_msg);
        XX_EXTERNAL_USERS_DEBUG.log_debug_message(1, p_msg);
   END;

   -- ===========================================================================
   -- Name             : write_messages
   -- Description      : Writes the message to the concurrent log / output file
   --
   -- Parameters :      p_return_status     : Return Status
   --                   p_msg_count         : Number of Errors
   --                   p_msg_data          : Error Message
   --
   -- ===========================================================================
  PROCEDURE write_messages ( p_return_status  IN VARCHAR2
                           , p_msg_count      IN NUMBER
                           , p_msg_data       IN VARCHAR2
                           )
  IS
  BEGIN

    IF( p_msg_count > 1 AND p_return_status <> FND_API.G_RET_STS_SUCCESS )
    THEN
      FOR I IN 1..FND_MSG_PUB.Count_Msg
      LOOP
        write_log(FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE));
      END LOOP;
    ELSE
      write_log(p_msg_data);
    END IF;

  END write_messages;


   -- ===========================================================================
   -- Name             : update_ext_attributes
   -- Description      : Updates all WebContact Account Site Extensible entries
   --                    with the Oracle Ids
   --
   -- Parameters :      x_errbuf    : Concurrent Program Return Message
   --                   x_retcode   : Concurrent Program Return Value
   --
   -- ===========================================================================
  PROCEDURE update_ext_attributes ( x_errbuf            OUT NOCOPY VARCHAR2
                                  , x_retcode           OUT NOCOPY VARCHAR2
                                  )
  IS

      CURSOR  c_new_webcontact
      IS
         SELECT webcts.extension_id,
                webcts.cust_acct_site_id,
                webcts.webcontacts_bill_to_osr,
                webcts.webcontacts_contact_party_osr,
                webcts.webcontacts_contact_party_id,
                webcts.webcontacts_bill_to_site_id,
                btosr.owner_table_id "ORIG_BILL_TO_SITE_ID"
         FROM   xx_cdh_as_ext_webcts_v webcts,
                hz_orig_sys_references btosr
         WHERE  webcts.webcontacts_bill_to_osr = btosr.orig_system_reference
         AND    btosr.orig_system = 'A0'
         AND    btosr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
         AND    btosr.status = 'A'
         AND    ( NVL(webcontacts_contact_party_id,0) = 0 OR
                  NVL(webcontacts_bill_to_site_id,0) =0
                );

      -- webcontact_rec_type              c_new_webcontact%ROWTYPE;
      TYPE webcontact_rec_type   IS TABLE OF c_new_webcontact%ROWTYPE INDEX BY BINARY_INTEGER;

      -- c_webcontact_cur           webcontact_rec_type;

      lc_webcontact            webcontact_rec_type;
      ln_bulk_limit            NUMBER := 100;

      ln_update_counter        PLS_INTEGER := 0;
      lt_extension_id          dbms_sql.number_table;
      lt_party_id              dbms_sql.number_table;
      lt_bill_to_site_id       dbms_sql.number_table;

      lt_curr_run_date         TIMESTAMP;
      lt_last_run_date         TIMESTAMP;

      lc_return_status         VARCHAR(60);
      ln_msg_count             NUMBER;
      lc_msg_data              VARCHAR2(4000);

      ln_counter               PLS_INTEGER  := 0;
      ln_sucess_count          PLS_INTEGER  := 0;
      ln_failed_count          PLS_INTEGER  := 0;
      ln_record_count          PLS_INTEGER  := 0;
      ln_exception_count       PLS_INTEGER  := 0;

      l_date                   DATE;

   BEGIN

      XX_EXTERNAL_USERS_DEBUG.enable_debug;
      XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Executing XX_CDH_WEBCONTACTS_CONV.update_ext_attributes');
      ln_sucess_count :=  0;
      ln_failed_count :=  0;
      ln_record_count :=  0;

      OPEN c_new_webcontact;
      LOOP
         -- --------------------------------------------------------------------------------
         -- Get All Web Contacts Records from Account Site Extensible Table
         -- --------------------------------------------------------------------------------
         FETCH c_new_webcontact BULK COLLECT INTO lc_webcontact Limit ln_bulk_limit ;

         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  'Fetched  : ' || c_new_webcontact%ROWCOUNT);

         IF lc_webcontact.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_fnd_new_users.COUNT =0 THEN

         FOR ln_counter in lc_webcontact.FIRST .. lc_webcontact.LAST
         LOOP
            ln_record_count           :=   ln_record_count+1;

            $if $$enable_debug
            $then
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  ' ');
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'Processing Record ' || ln_record_count);
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  '*********************************************************** ');

               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'EXTENSION_ID                   : ' ||  lc_webcontact(ln_counter).extension_id             );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'CUST_ACCT_SITE_ID              : ' ||  lc_webcontact(ln_counter).cust_acct_site_id        );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'WEBCONTACTS_BILL_TO_OSR        : ' ||  lc_webcontact(ln_counter).webcontacts_bill_to_osr  );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'WEBCONTACTS_CONTACT_PARTY_OSR  : ' ||  lc_webcontact(ln_counter).webcontacts_contact_party_osr   );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'WEBCONTACTS_CONTACT_PARTY_ID   : ' ||  lc_webcontact(ln_counter).webcontacts_contact_party_id    );
               XX_EXTERNAL_USERS_DEBUG.log_debug_message(3,  'WEBCONTACTS_BILL_TO_SITE_ID    : ' ||  lc_webcontact(ln_counter).webcontacts_bill_to_site_id);
            $end

            -- --------------------------------------------------------------------------------
            -- If Party ID is null, then get party_id based on the Contact OSR
            -- --------------------------------------------------------------------------------
            IF NVL(lc_webcontact(ln_counter).webcontacts_contact_party_id,0)=0
            THEN
               XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => 'A0'
                                                    , p_cust_acct_cnt_osr    => lc_webcontact(ln_counter).webcontacts_contact_party_osr
                                                    , x_party_id             => lc_webcontact(ln_counter).webcontacts_contact_party_id
                                                    , x_return_status        => lc_return_status
                                                    , x_msg_count            => ln_msg_count
                                                    , x_msg_data             => lc_msg_data
                                                    );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
               THEN
                  ln_failed_count          := ln_failed_count+1;
                  write_messages ( p_return_status  => lc_return_status
                                 , p_msg_count      => ln_msg_count
                                 , p_msg_data       => lc_msg_data
                                 );
               ELSE
                  ln_sucess_count          := ln_sucess_count+1;
               END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

            END IF; -- lc_webcontact(ln_counter).webcontacts_contact_party_id IS NULL

            /*
            -- --------------------------------------------------------------------------------
            -- If bill_to_site_id is null, then get bill_to_site_id based on the BILL_TO OSR
            -- --------------------------------------------------------------------------------
            IF lc_webcontact(ln_counter).webcontacts_bill_to_site_id IS NULL
            THEN
               XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => lc_webcontact(ln_counter).webcontacts_orig_system
                                                    , p_cust_acct_cnt_osr    => lc_webcontact(ln_counter).webcontacts_bill_to_site_osr
                                                    , x_party_id             => lc_webcontact(ln_counter).webcontacts_bill_to_site_id
                                                    , x_return_status        => lc_return_status
                                                    , x_msg_count            => ln_msg_count
                                                    , x_msg_data             => lc_msg_data
                                                    );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
               THEN
                  ln_failed_count          := ln_failed_count+1;
                  write_messages ( p_return_status  => lc_return_status
                                 , p_msg_count      => ln_msg_count
                                 , p_msg_data       => lc_msg_data
                                 );
               ELSE
                  ln_sucess_count          := ln_sucess_count+1;
               END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS

            END IF; -- lc_webcontact(ln_counter).webcontacts_contact_party_id IS NULL
            */

            -- -----------------------------------------------------------------------
            -- Copy Rows with Party ID and Bill_To_Site_ID to update using BULK Update
            -- -----------------------------------------------------------------------
            lt_extension_id(ln_counter)     := lc_webcontact(ln_counter).extension_id;
            lt_party_id(ln_counter)         := lc_webcontact(ln_counter).webcontacts_contact_party_id;
            IF NVL(lc_webcontact(ln_counter).webcontacts_bill_to_site_id,0)=0
            THEN
               lt_bill_to_site_id(ln_counter)  := lc_webcontact(ln_counter).orig_bill_to_site_id;
            ELSE
               lt_bill_to_site_id(ln_counter)  := lc_webcontact(ln_counter).webcontacts_bill_to_site_id;
            END IF; -- NVL(lc_webcontact(ln_counter).webcontacts_bill_to_site_id,0)=0

         END LOOP;

         BEGIN
            FORALL ln_counter1 IN lt_extension_id.FIRST .. lt_extension_id.LAST SAVE EXCEPTIONS
               UPDATE XX_CDH_ACCT_SITE_EXT_B
               SET    N_EXT_ATTR1 = lt_party_id(ln_counter1)          -- WEBCONTACTS_CONTACT_PARTY_ID
                    , N_EXT_ATTR2 = lt_bill_to_site_id(ln_counter1)   -- WEBCONTACTS_BILL_TO_SITE_ID
               WHERE  EXTENSION_ID = lt_extension_id(ln_counter1);
         EXCEPTION
            WHEN OTHERS THEN
                 ln_exception_count := SQL%BULK_EXCEPTIONS.COUNT;
                 ln_failed_count    := ln_failed_count + ln_exception_count;
                 ln_sucess_count    := ln_sucess_count - ln_exception_count;

                 XX_EXTERNAL_USERS_DEBUG.log_debug_message(0,  'Number of Rows that failed : ' || ln_exception_count);
                 FOR i IN 1..ln_exception_count
                 LOOP
                     XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error #' || i || ' occurred during ' || 'iteration #' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX );
                     XX_EXTERNAL_USERS_DEBUG.log_debug_message(0, 'Error message is ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
                 END LOOP;
         END;

         COMMIT;


         EXIT WHEN c_new_webcontact%NOTFOUND;

      END LOOP;

      CLOSE c_new_webcontact;

      fnd_file.put_line (fnd_file.output, 'Processed Successfully : ' || ln_sucess_count);
      fnd_file.put_line (fnd_file.output, 'Erorrs                 : ' || ln_failed_count);
      fnd_file.put_line (fnd_file.output, 'Total Count            : ' || ln_record_count);

      IF ln_failed_count > 0
      THEN
         IF  ln_failed_count = ln_record_count
         THEN
             x_retcode := 2;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSIF  ln_failed_count > 0
         THEN
             x_retcode := 1;
             x_errbuf  := to_char(ln_failed_count) || ' records failed';
         ELSE
             x_retcode := 0;
             x_errbuf  := 'Successfully Processed ' || ln_sucess_count || ' Records';
         END IF; --  ln_failed_count > 0
      ELSE
          x_retcode := 0;
          x_errbuf  := 'No records Processed';
      END IF; -- ln_failed_count > 0
      XX_EXTERNAL_USERS_DEBUG.disable_debug;

   EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.update_ext_attributes');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         fnd_file.put_line (fnd_file.output, fnd_message.get());
         XX_EXTERNAL_USERS_DEBUG.log_debug_message(2,  fnd_message.get());
         x_retcode := 2;
         x_errbuf  := fnd_message.get();

         IF c_new_webcontact%ISOPEN
         THEN
            CLOSE c_new_webcontact;
         END IF; -- c_new_webcontact%ISOPEN

   END update_ext_attributes;

END XX_CDH_WEBCONTACTS_CONV;

/

SHOW ERRORS;