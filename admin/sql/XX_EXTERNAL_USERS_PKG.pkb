CREATE OR REPLACE PACKAGE BODY XX_EXTERNAL_USERS_PKG
AS

/*
-- +====================================================================================================+
-- |                                Office Depot - Project Simplify                                     |
-- |                                        Oracle Consulting                                           |
-- +====================================================================================================+
-- | Name        : XX_EXTERNAL_USERS_PKG                                                             |
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

   g_pkg_name                     CONSTANT VARCHAR2(30)  := 'XX_EXTERNAL_USERS_PKG';

   PROCEDURE write_log( p_msg VARCHAR2);

   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_PVT.fnd_user_rec_type
                            , x_return_status           OUT NOCOPY VARCHAR2
                            , x_msg_count               OUT        NUMBER
                            , x_msg_data                OUT NOCOPY VARCHAR2
                         );

   PROCEDURE write_log( p_msg VARCHAR2)
   IS
     PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
        INSERT INTO XX_IREC_DEBUG (MSG)
               VALUES ( to_char(SYSDATE, 'dd-mon-yyyy hh24:mi:ss') || ' - ' || p_msg);

        fnd_file.put_line (fnd_file.log, p_msg);
        COMMIT;
   END;

   PROCEDURE process_new_user_access ( x_errbuf            OUT    VARCHAR2
                                     , x_retcode           OUT    VARCHAR2
                                     , p_force             IN     VARCHAR2  DEFAULT NULL
                                     , p_date              IN     DATE      DEFAULT NULL
                                     )
   IS

      TYPE C_FND_NEW_USER_TYPE   IS TABLE OF webcontact_user_rec_type INDEX BY BINARY_INTEGER;
      TYPE r_webcontact_cur_type IS REF CURSOR;

      c_webcontact_cur           r_webcontact_cur_type;

      lc_fnd_new_users         C_FND_NEW_USER_TYPE;
      ln_bulk_limit            NUMBER := 100;

      lt_curr_run_date         TIMESTAMP;
      lt_last_run_date         TIMESTAMP;
      lc_return_status         VARCHAR(60);
      ln_msg_count             NUMBER;
      lc_msg_data              VARCHAR2(4000);

      ln_counter               PLS_INTEGER  :=  0;
      ln_sucess_count          PLS_INTEGER  :=  0;
      ln_failed_count          PLS_INTEGER  :=  0;
      ln_record_count          PLS_INTEGER  :=  0;

      l_date                   DATE;
      l_fnd_user_rec           XX_EXTERNAL_USERS_PVT.fnd_user_rec_type;
      l_cur_extuser_rec        XX_EXTERNAL_USERS_PVT.external_user_rec_type;
      l_new_extuser_rec        XX_EXTERNAL_USERS_PVT.external_user_rec_type;

   BEGIN

      write_log( p_msg => 'Executing XX_EXTERNAL_USERS_PKG.process_new_user_access');
      write_log( p_msg => 'Parameters:');
      write_log( p_msg => '  Force = ' || p_force);
      write_log( p_msg => '  Date  = ' || p_date);

      XX_COM_JOB_RUN_STATUS_PKG.get_program_run_date ( p_program_name       => 'PROCESS_NEW_USER_ACCESS'
                                                     , x_run_date           => lt_last_run_date
                                                     , x_return_status      => lc_return_status
                                                     , x_msg_count          => ln_msg_count
                                                     , x_msg_data           => lc_msg_data
                                                     );


      ln_sucess_count :=  0;
      ln_failed_count :=  0;
      ln_record_count :=  0;

      SELECT SYSTIMESTAMP
      INTO   lt_curr_run_date
      FROM DUAL;

      write_log( p_msg => 'Last Run Date    : ' || lt_last_run_date);
      write_log( p_msg => 'Current Run Date : ' || lt_curr_run_date);

      -- CURSOR  c_fnd_new_user (lt_last_run_date, lt_curr_run_date)
      IF NVL(p_force, 'N') = 'N'
      THEN
         OPEN c_webcontact_cur FOR  SELECT fnd.rowid "fnd_user_rowid",
                                           fnd.user_id,
                                           fnd.user_name,
                                           fnd.description,
                                           fnd.customer_id,
                                           ext.rowid "ext_user_rowid",
                                           ext.ext_user_id,
                                           ext.userid,
                                           ext.password,
                                           ext.person_first_name,
                                           ext.person_middle_name,
                                           ext.person_last_name,
                                           ext.email,
                                           ext.party_id,
                                           ext.status,
                                           'A0' "orig_system",
                                           ext.contact_osr,
                                           ext.acct_site_osr,
                                           ext.access_code,
                                           ext.permission_flag,
                                           ext.site_key,
                                           ext.end_date,
                                           ext.load_status,
                                           ext.user_locked,
                                           ext.created_by,
                                           ext.creation_date,
                                           ext.last_update_date,
                                           ext.last_updated_by,
                                           ext.last_update_login
                                    FROM   fnd_user versions BETWEEN scn minvalue
                                                             AND maxvalue fnd,
                                           xx_external_users ext
                                    WHERE fnd.user_name = ext.fnd_user_name
                                    AND   fnd.versions_operation = 'C'
                                    AND   fnd.versions_starttime BETWEEN lt_last_run_date
                                                                 AND   lt_curr_run_date;
      ELSE
         l_date  :=   NVL(p_date, lt_last_run_date);
         write_log( p_msg => 'Extract Date     : ' || l_date);

         OPEN c_webcontact_cur FOR  SELECT fnd.rowid "fnd_user_rowid",
                                           fnd.user_id,
                                           fnd.user_name,
                                           fnd.description,
                                           fnd.customer_id,
                                           ext.rowid "ext_user_rowid",
                                           ext.ext_user_id,
                                           ext.userid,
                                           ext.password,
                                           ext.person_first_name,
                                           ext.person_middle_name,
                                           ext.person_last_name,
                                           ext.email,
                                           ext.party_id,
                                           ext.status,
                                           'A0' "orig_system",
                                           ext.contact_osr,
                                           ext.acct_site_osr,
                                           ext.access_code,
                                           ext.permission_flag,
                                           ext.site_key,
                                           ext.end_date,
                                           ext.load_status,
                                           ext.user_locked,
                                           ext.created_by,
                                           ext.creation_date,
                                           ext.last_update_date,
                                           ext.last_updated_by,
                                           ext.last_update_login
                                    FROM   fnd_user fnd,
                                           xx_external_users ext
                                    WHERE fnd.user_name = ext.fnd_user_name
                                    AND   fnd.creation_date >= l_date;
      END IF; -- NVL(p_force, 'N') = 'N'

      LOOP
         FETCH c_webcontact_cur BULK COLLECT INTO lc_fnd_new_users Limit ln_bulk_limit ;

         $if $$tracing $then
            write_log( p_msg => 'Fetched  : ' || c_webcontact_cur%ROWCOUNT);
         $end

         IF lc_fnd_new_users.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_fnd_new_users.COUNT =0 THEN

         FOR ln_counter in lc_fnd_new_users.FIRST .. lc_fnd_new_users.LAST
         LOOP
            ln_record_count           :=   ln_record_count+1;

            write_log( p_msg => ' ');
            write_log( p_msg => 'Processing Record ' || ln_record_count);

            l_fnd_user_rec.fnd_user_rowid              := lc_fnd_new_users(ln_counter).fnd_user_rowid;
            l_fnd_user_rec.user_id                     := lc_fnd_new_users(ln_counter).user_id;
            l_fnd_user_rec.user_name                   := lc_fnd_new_users(ln_counter).user_name;
            l_fnd_user_rec.description                 := lc_fnd_new_users(ln_counter).description;
            l_fnd_user_rec.customer_id                 := lc_fnd_new_users(ln_counter).customer_id;

            l_new_extuser_rec.ext_user_rowid           := lc_fnd_new_users(ln_counter).ext_user_rowid;
            l_new_extuser_rec.ext_user_id              := lc_fnd_new_users(ln_counter).ext_user_id;
            l_new_extuser_rec.userid                   := lc_fnd_new_users(ln_counter).userid;
            l_new_extuser_rec.password                 := lc_fnd_new_users(ln_counter).password;
            l_new_extuser_rec.person_first_name        := lc_fnd_new_users(ln_counter).person_first_name;
            l_new_extuser_rec.person_middle_name       := lc_fnd_new_users(ln_counter).person_middle_name;
            l_new_extuser_rec.person_last_name         := lc_fnd_new_users(ln_counter).person_last_name;
            l_new_extuser_rec.email                    := lc_fnd_new_users(ln_counter).email;
            l_new_extuser_rec.party_id                 := lc_fnd_new_users(ln_counter).party_id;
            l_new_extuser_rec.status                   := lc_fnd_new_users(ln_counter).status;
            l_new_extuser_rec.orig_system              := lc_fnd_new_users(ln_counter).orig_system;
            l_new_extuser_rec.contact_osr              := lc_fnd_new_users(ln_counter).contact_osr;
            l_new_extuser_rec.acct_site_osr            := lc_fnd_new_users(ln_counter).acct_site_osr;
            l_new_extuser_rec.access_code              := lc_fnd_new_users(ln_counter).access_code;
            l_new_extuser_rec.permission_flag          := lc_fnd_new_users(ln_counter).permission_flag;
            l_new_extuser_rec.site_key                 := lc_fnd_new_users(ln_counter).site_key;
            l_new_extuser_rec.end_date                 := lc_fnd_new_users(ln_counter).end_date;
            l_new_extuser_rec.load_status              := lc_fnd_new_users(ln_counter).load_status;
            l_new_extuser_rec.user_locked              := lc_fnd_new_users(ln_counter).user_locked;
            l_new_extuser_rec.created_by               := lc_fnd_new_users(ln_counter).created_by;
            l_new_extuser_rec.creation_date            := lc_fnd_new_users(ln_counter).creation_date;
            l_new_extuser_rec.last_update_date         := lc_fnd_new_users(ln_counter).last_update_date;
            l_new_extuser_rec.last_updated_by          := lc_fnd_new_users(ln_counter).last_updated_by;
            l_new_extuser_rec.last_update_login        := lc_fnd_new_users(ln_counter).last_update_login;

            $if $$tracing $then
               write_log( p_msg => '*********************************************************** ');
               write_log( p_msg => 'l_fnd_user_rec.fnd_user_rowid              : ' ||  l_fnd_user_rec.fnd_user_rowid        );
               write_log( p_msg => 'l_fnd_user_rec.user_id                     : ' ||  l_fnd_user_rec.user_id               );
               write_log( p_msg => 'l_fnd_user_rec.user_name                   : ' ||  l_fnd_user_rec.user_name             );
               write_log( p_msg => 'l_fnd_user_rec.description                 : ' ||  l_fnd_user_rec.description           );
               write_log( p_msg => 'l_fnd_user_rec.customer_id                 : ' ||  l_fnd_user_rec.customer_id           );
               write_log( p_msg => '-------------------------------------------' );
               write_log( p_msg => 'l_new_extuser_rec.ext_user_rowid           : ' ||  l_new_extuser_rec.ext_user_rowid     );
               write_log( p_msg => 'l_new_extuser_rec.ext_user_id              : ' ||  l_new_extuser_rec.ext_user_id        );
               write_log( p_msg => 'l_new_extuser_rec.userid                   : ' ||  l_new_extuser_rec.userid             );
               write_log( p_msg => 'l_new_extuser_rec.password                 : ' ||  l_new_extuser_rec.password           );
               write_log( p_msg => 'l_new_extuser_rec.person_first_name        : ' ||  l_new_extuser_rec.person_first_name  );
               write_log( p_msg => 'l_new_extuser_rec.person_middle_name       : ' ||  l_new_extuser_rec.person_middle_name );
               write_log( p_msg => 'l_new_extuser_rec.person_last_name         : ' ||  l_new_extuser_rec.person_last_name   );
               write_log( p_msg => 'l_new_extuser_rec.email                    : ' ||  l_new_extuser_rec.email              );
               write_log( p_msg => 'l_new_extuser_rec.party_id                 : ' ||  l_new_extuser_rec.party_id           );
               write_log( p_msg => 'l_new_extuser_rec.status                   : ' ||  l_new_extuser_rec.status             );
               write_log( p_msg => 'l_new_extuser_rec.orig_system              : ' ||  l_new_extuser_rec.orig_system        );
               write_log( p_msg => 'l_new_extuser_rec.contact_osr              : ' ||  l_new_extuser_rec.contact_osr        );
               write_log( p_msg => 'l_new_extuser_rec.acct_site_osr            : ' ||  l_new_extuser_rec.acct_site_osr      );
               write_log( p_msg => 'l_new_extuser_rec.access_code              : ' ||  l_new_extuser_rec.access_code        );
               write_log( p_msg => 'l_new_extuser_rec.permission_flag          : ' ||  l_new_extuser_rec.permission_flag    );
               write_log( p_msg => 'l_new_extuser_rec.site_key                 : ' ||  l_new_extuser_rec.site_key           );
               write_log( p_msg => 'l_new_extuser_rec.end_date                 : ' ||  l_new_extuser_rec.end_date           );
               write_log( p_msg => 'l_new_extuser_rec.load_status              : ' ||  l_new_extuser_rec.load_status        );
               write_log( p_msg => 'l_new_extuser_rec.user_locked              : ' ||  l_new_extuser_rec.user_locked        );
               write_log( p_msg => 'l_new_extuser_rec.created_by               : ' ||  l_new_extuser_rec.created_by);
               write_log( p_msg => 'l_new_extuser_rec.creation_date            : ' ||  l_new_extuser_rec.creation_date);
               write_log( p_msg => 'l_new_extuser_rec.last_update_date         : ' ||  l_new_extuser_rec.last_update_date);
               write_log( p_msg => 'l_new_extuser_rec.last_updated_by          : ' ||  l_new_extuser_rec.last_updated_by);
               write_log( p_msg => 'l_new_extuser_rec.last_update_login        : ' ||  l_new_extuser_rec.last_update_login);
               write_log( p_msg => '-------------------------------------------' );
            $end

            update_fnd_user ( p_cur_extuser_rec            => l_cur_extuser_rec
                            , p_new_extuser_rec            => l_new_extuser_rec
                            , p_fnd_user_rec               => l_fnd_user_rec
                            , x_return_status              => lc_return_status
                            , x_msg_count                  => ln_msg_count
                            , x_msg_data                   => lc_msg_data
                            );

=            IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
            THEN
               ln_failed_count          := ln_failed_count+1;
            ELSE
               ln_sucess_count          := ln_sucess_count+1;
            END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS


         END LOOP;

         EXIT WHEN c_webcontact_cur%NOTFOUND;

      END LOOP;

      CLOSE c_webcontact_cur;

      fnd_file.put_line (fnd_file.output, 'Processed Successfully : ' || ln_sucess_count);
      fnd_file.put_line (fnd_file.output, 'Erorrs                 : ' || ln_failed_count);
      fnd_file.put_line (fnd_file.output, 'Total Count            : ' || ln_record_count);

      XX_COM_JOB_RUN_STATUS_PKG.update_program_run_date ( p_program_name       => 'PROCESS_NEW_USER_ACCESS'
                                                        , p_run_date           => lt_curr_run_date
                                                        , x_return_status      => lc_return_status
                                                        , x_msg_count          => ln_msg_count
                                                        , x_msg_data           => lc_msg_data
                                                        );

      IF ln_record_count > 0
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
      END IF; -- ln_record_count > 0

   EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.process_new_user_access');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         fnd_file.put_line (fnd_file.output, fnd_message.get());
         write_log( p_msg => fnd_message.get());

         IF c_webcontact_cur%ISOPEN
         THEN
            CLOSE c_webcontact_cur;
         END IF; -- c_fnd_user%ISOPEN

   END process_new_user_access;


   PROCEDURE update_fnd_user( p_cur_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_new_extuser_rec         IN         XX_EXTERNAL_USERS_PVT.external_user_rec_type
                            , p_fnd_user_rec            IN         XX_EXTERNAL_USERS_PVT.fnd_user_rec_type
                            , x_return_status           OUT NOCOPY VARCHAR2
                            , x_msg_count               OUT        NUMBER
                            , x_msg_data                OUT NOCOPY VARCHAR2
                         )
   AS
   BEGIN
      SAVEPOINT update_fnd_user_sv;

      XX_EXTERNAL_USERS_PVT.update_fnd_user ( p_cur_extuser_rec            => p_cur_extuser_rec
                                            , p_new_extuser_rec            => p_new_extuser_rec
                                            , p_fnd_user_rec               => p_fnd_user_rec
                                            , x_return_status              => x_return_status
                                            , x_msg_count                  => x_msg_count
                                            , x_msg_data                   => x_msg_data
                                            );

      IF X_return_status <> FND_API.G_RET_STS_SUCCESS
      THEN
         ROLLBACK TO SAVEPOINT update_fnd_user_sv;
      ELSE
         COMMIT;
      END IF;


   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT update_fnd_user_sv;

   END update_fnd_user;


   PROCEDURE process_new_ext_user ( x_errbuf            OUT    VARCHAR2
                                  , x_retcode           OUT    VARCHAR2
                                  )
   IS

      CURSOR c_webcontact_cur
      IS
         SELECT *
         FROM   xx_external_users
         WHERE  fnd_user_name IS NULL
         OR     party_id IS NULL;

      TYPE EXT_USER_REC_TYP   IS TABLE OF xx_external_users%ROWTYPE INDEX BY BINARY_INTEGER;

      lc_new_users             EXT_USER_REC_TYP;

      ext_user_id_tbl          dbms_sql.number_table;
      party_id_tbl             dbms_sql.number_table;
      fnd_user_name_tbl        dbms_sql.varchar2_table;
      orig_system_tbl          dbms_sql.varchar2_table;


      ln_ext_user_id           XX_EXTERNAL_USERS.ext_user_id%TYPE;
      ln_party_id              XX_EXTERNAL_USERS.party_id%TYPE;
      lc_fnd_user_name         XX_EXTERNAL_USERS.fnd_user_name%TYPE;
      lc_orig_system           XX_EXTERNAL_USERS.orig_system%TYPE;

      ln_bulk_limit            NUMBER := 100;

      lc_return_status         VARCHAR(60);
      ln_msg_count             NUMBER;
      lc_msg_data              VARCHAR2(4000);

      ln_counter               PLS_INTEGER  :=  0;
      ln_counter1              PLS_INTEGER  :=  0;
      ln_sucess_count          PLS_INTEGER  :=  0;
      ln_failed_count          PLS_INTEGER  :=  0;
      ln_record_count          PLS_INTEGER  :=  0;

      l_update                 BOOLEAN := FALSE;

      l_date                   DATE;

      ln_size                  NUMBER;
      ln_errors                NUMBER;

      dml_errors               EXCEPTION;
      PRAGMA exception_init(dml_errors, -24381);

   BEGIN

      write_log( p_msg => 'Executing XX_EXTERNAL_USERS_PKG.process_new_ext_user');

      ln_sucess_count :=  0;
      ln_failed_count :=  0;
      ln_record_count :=  0;

      OPEN c_webcontact_cur;
      LOOP
         FETCH c_webcontact_cur BULK COLLECT INTO lc_new_users Limit ln_bulk_limit ;

         write_log( p_msg => 'Fetched  : ' || c_webcontact_cur%ROWCOUNT);
         IF lc_new_users.COUNT = 0
         THEN
             EXIT;
         END IF; -- lc_new_users.COUNT =0 THEN

         l_update := FALSE;

         FOR ln_counter in lc_new_users.FIRST .. lc_new_users.LAST
         LOOP
            ln_record_count           :=   ln_record_count+1;

            write_log( p_msg => ' ');
            write_log( p_msg => 'Processing Record ' || ln_record_count);

            $if $$tracing $then
               write_log( p_msg => '*********************************************************** ');
               write_log( p_msg => 'orig_system     : ' ||  lc_new_users(ln_counter).orig_system        );
               write_log( p_msg => 'fnd_user_name   : ' ||  lc_new_users(ln_counter).fnd_user_name      );
               write_log( p_msg => 'party_id        : ' ||  lc_new_users(ln_counter).party_id           );
               write_log( p_msg => 'orig_system     : ' ||  lc_new_users(ln_counter).orig_system        );
               write_log( p_msg => 'contact_osr     : ' ||  lc_new_users(ln_counter).contact_osr        );
               write_log( p_msg => 'ext_user_id     : ' ||  lc_new_users(ln_counter).ext_user_id            );
            $end

            IF  lc_new_users(ln_counter).orig_system IS NULL
            THEN
               lc_orig_system := 'A0';
               l_update       := TRUE;
            END IF; --  lc_new_users(ln_counter).fnd_user_name IS NULL

            IF  lc_new_users(ln_counter).fnd_user_name IS NULL
            THEN
               lc_fnd_user_name := lc_new_users(ln_counter).site_key || lc_new_users(ln_counter).userid;
               l_update := TRUE;
            END IF; --  lc_new_users(ln_counter).fnd_user_name IS NULL

            IF  lc_new_users(ln_counter).party_id IS NULL
            THEN
               XX_EXTERNAL_USERS_PVT.get_contact_id ( p_orig_system          => lc_new_users(ln_counter).orig_system
                                                    , p_cust_acct_cnt_osr    => lc_new_users(ln_counter).contact_osr
                                                    , x_party_id             => ln_party_id
                                                    , x_return_status        => lc_return_status
                                                    , x_msg_count            => ln_msg_count
                                                    , x_msg_data             => lc_msg_data
                                                    );

               IF lc_return_status <> FND_API.G_RET_STS_SUCCESS
               THEN
                  ln_failed_count := ln_failed_count+1;
                  l_update        := FALSE;
               ELSE
                  l_update        := TRUE;
               END IF; -- lc_return_status <> FND_API.G_RET_STS_SUCCESS
            END IF; -- lc_new_users(ln_counter).party_id IS NULL

            IF l_update
            THEN
               ln_counter1 := ln_counter + 1;

               ext_user_id_tbl(ln_counter1)   := lc_new_users(ln_counter).ext_user_id;
               party_id_tbl(ln_counter1)      := ln_party_id;
               fnd_user_name_tbl(ln_counter1) := lc_fnd_user_name;
               orig_system_tbl(ln_counter1)   := lc_orig_system;

               $if $$tracing $then
                  write_log( p_msg => '*********************************************************** ');
                  write_log( p_msg => 'ext_user_id_tbl     : ' ||  ext_user_id_tbl(ln_counter1)        );
                  write_log( p_msg => 'party_id_tbl        : ' ||  party_id_tbl(ln_counter1)           );
                  write_log( p_msg => 'fnd_user_name_tbl   : ' ||  fnd_user_name_tbl(ln_counter1)      );
                  write_log( p_msg => 'orig_system_tbl     : ' ||  orig_system_tbl                     );
               $end

            END IF; -- l_update

         END LOOP;

         ln_size := orig_system_tbl.COUNT;

         IF ln_size > 0
         THEN
             FORALL ln_counter1 IN 1 .. ln_size -- SAVE EXCEPTIONS
                    UPDATE xx_external_users
                    SET    fnd_user_name =  fnd_user_name_tbl(ln_counter1),
                           orig_system   =  orig_system_tbl(ln_counter1),
                           party_id      =  party_id_tbl(ln_counter1)
                    WHERE  ext_user_id   =  ext_user_id_tbl(ln_counter1);
         END IF; -- ln_size > 0

         EXIT WHEN c_webcontact_cur%NOTFOUND;

      END LOOP;

      CLOSE c_webcontact_cur;

      fnd_file.put_line (fnd_file.output, 'Total Count            : ' || ln_record_count);
      fnd_file.put_line (fnd_file.output, 'Erorrs                 : ' || ln_failed_count);

      IF ln_record_count > 0
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
      END IF; -- ln_record_count > 0

   EXCEPTION
     WHEN OTHERS THEN
         ROLLBACK;
         fnd_message.set_name('FND', 'SQL_PLSQL_ERROR');
         fnd_message.set_token('ROUTINE', g_pkg_name || '.process_new_user_access');
         fnd_message.set_token('ERRNO', SQLCODE);
         fnd_message.set_token('REASON', SQLERRM);
         fnd_file.put_line (fnd_file.output, fnd_message.get());
         write_log( p_msg => fnd_message.get());

         IF c_webcontact_cur%ISOPEN
         THEN
            CLOSE c_webcontact_cur;
         END IF; -- c_fnd_user%ISOPEN

   END process_new_ext_user;

END XX_EXTERNAL_USERS_PKG;

/

SHOW ERRORS;