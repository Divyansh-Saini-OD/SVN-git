create or replace
PACKAGE BODY XX_CDH_REL_SYNC_PKG
AS
   gc_commit   VARCHAR2 (1) := 'N';

   PROCEDURE wr_log (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.LOG, p_msg);
   END wr_log;

   PROCEDURE wr_out (p_msg IN VARCHAR2)
   AS
   BEGIN
      fnd_file.put_line (fnd_file.output, p_msg);
   END wr_out;

-- +========================================================================+
-- | Name        : fill_partyid                                             |
-- | Description : Not all customers in AOPS rels exist in Oracle, check and|
-- |               update the party_ids for records where OP is NULL        |
-- +========================================================================+
   PROCEDURE fill_partyid (x_retcode OUT NUMBER)
   AS
      CURSOR cur_partyid
      IS
         SELECT temp.parent_id parent_id, temp.child_id child_id,
                a.party_id sub_id, b.party_id obj_id
           FROM xxod_cust_relate_temp temp,
                hz_cust_accounts a,
                hz_cust_accounts b
          WHERE op IS NULL
            AND LPAD (TO_CHAR (temp.parent_id), 8, 0) || '-00001-A0' =
                                                       a.orig_system_reference
            AND LPAD (TO_CHAR (temp.child_id), 8, 0) || '-00001-A0' =
                                                       b.orig_system_reference;

      ln_l_limit       NUMBER          := 1000; -- Changed from 10000 to 1000 for effective batching

      TYPE lr_partyid_type IS TABLE OF cur_partyid%ROWTYPE
         INDEX BY BINARY_INTEGER;

      lr_partyid_tbl   lr_partyid_type;
   BEGIN
      wr_log ('Starting fill_partyid procedure');
      x_retcode := 2;

      OPEN cur_partyid;

      LOOP
         FETCH cur_partyid
         BULK COLLECT INTO lr_partyid_tbl LIMIT ln_l_limit;

         EXIT WHEN lr_partyid_tbl.COUNT < 1;
         NULL;
         FORALL i IN lr_partyid_tbl.FIRST .. lr_partyid_tbl.LAST
            UPDATE xxod_cust_relate_temp
               SET subject_id = lr_partyid_tbl (i).sub_id,
                   object_id = lr_partyid_tbl (i).obj_id
             WHERE parent_id = lr_partyid_tbl (i).parent_id
               AND child_id = lr_partyid_tbl (i).child_id;
         COMMIT;
      END LOOP;

      x_retcode := 0;
      wr_log ('Completed fill_partyid procedure successfully');
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         wr_log ('Error in fill_partyid Procedure' || SQLERRM);
   END fill_partyid;

-- +========================================================================+
-- | Name        : mail_alert                                               |
-- | Description : Send out alert mail, called by check_load                |
-- +========================================================================+
   PROCEDURE mail_alert (
      p_cr       IN       NUMBER,
      p_dl       IN       NUMBER,
      p_t        IN       NUMBER,
      p_sy       IN       NUMBER,
      x_status   OUT      VARCHAR2
   )
   AS
      lc_conn        UTL_SMTP.connection;
      lc_host        VARCHAR2 (50)
                              := fnd_profile.VALUE ('XX_CDH_REL_MAIL_SERVER');
      lc_sender      VARCHAR2 (10)       := 'ODCDH';
      lc_recv        VARCHAR2 (100)
                                := fnd_profile.VALUE ('XX_CDH_RELS_EMAIL_ID');
      lc_subject     VARCHAR2 (100)
         := 'CDH program alert  - "OD: CDH Customer Relationships Correction Program"';
      ln_set_limit   NUMBER   := fnd_profile.VALUE ('XX_CDH_RELS_LOAD_LIMIT');
      crlf           VARCHAR2 (20)       := UTL_TCP.crlf;
      ln_cnt         NUMBER              := 100;
      LC_INSTANCE         varchar2(100)   := null;
      
   begin
    
     SELECT instance_name
          into LC_INSTANCE
          from V$INSTANCE;
      
      LC_SUBJECT := LC_INSTANCE ||': '||LC_SUBJECT;
    
      wr_log ('Starting Mail_alert procedure');
      lc_conn := UTL_SMTP.open_connection (lc_host, 25, 60);
      UTL_SMTP.helo (lc_conn, lc_host);
      UTL_SMTP.mail (lc_conn, lc_sender);
      UTL_SMTP.rcpt (lc_conn, lc_recv);
      UTL_SMTP.DATA
         (lc_conn,
             'From: '
          || lc_sender
          || crlf
          || 'To: '
          || lc_recv
          || crlf
          || 'Subject: '
          || LC_SUBJECT
          || crlf
          || 'This notification is generated from the instance: '
          || LC_INSTANCE
          || CRLF
          || crlf
          || 'The number of customer relationships out of sync with AOPS has crossed the set limit of : '
          || ln_set_limit
          || '.'
          || crlf
          || 'Please submit the "OD: CDH Customer Relationships Correction Program" manually.'
          || crlf
          || crlf
          || 'Summary of the Relationship Correction program'
          || crlf
          || '---------------------------------------------------------------------------'
          || crlf
          || 'Number of relationships to be created :      '
          || p_cr
          || crlf
          || 'Number of relationships to be removed :      '
          || p_dl
          || crlf
          || 'Total number of relationships to be fixed :  '
          || p_t
          || crlf
          || 'Number of relationships in sync :            '
          || p_sy
         );
      
      UTL_SMTP.quit (lc_conn);
      x_status := 'S';
      wr_log ('Completed Mail_alert procedure successfully');
   EXCEPTION
      WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
      THEN
         wr_log ('Error : Unable to send mail, ' || SQLERRM);
         x_status := 'E';
      WHEN OTHERS
      THEN
         wr_log ('Error : Unable to send mail, ' || SQLERRM);
         x_status := 'E';
   END mail_alert;

-- +========================================================================+
-- | Name        : check_load                                               |
-- | Description : Checks the current mismatch count with the threshold set,|
-- |              if above limit skip fixing and send email.                |
-- +========================================================================+
   PROCEDURE check_load (
      x_override_fix   IN OUT NOCOPY   VARCHAR,
      x_retcode        OUT             NUMBER
   )
   AS
      ln_load_limit   NUMBER;
      ln_cnt          NUMBER       := 0;
      ln_cnt_cr       NUMBER       := 0;
      ln_cnt_dl       NUMBER       := 0;
      ln_cnt_sy       NUMBER       := 0;
      x_status        VARCHAR2 (5);
      e_fail          EXCEPTION;
   BEGIN
      wr_log ('Starting Check_load procedure');
      ln_load_limit :=
                  NVL (fnd_profile.VALUE ('XX_CDH_RELS_LOAD_LIMIT'), 1000000);

      SELECT COUNT (1)
        INTO ln_cnt_cr
        FROM xxod_cust_relate_temp
       WHERE op IS NULL AND subject_id IS NOT NULL AND object_id IS NOT NULL;

      SELECT COUNT (1)
        INTO ln_cnt_dl
        FROM xxod_cust_relate_temp
       WHERE op = 'D';

      SELECT COUNT (1)
        INTO ln_cnt_sy
        FROM xxod_cust_relate_temp
       WHERE op = 'S';

      wr_out (CHR (10) || 'Mismatch analysis :' || CHR (10));
      wr_out ('Number of relationships in sync : ' || ln_cnt_sy);
      wr_out ('Number of relationships to be created : ' || ln_cnt_cr);
      wr_out ('Number of relationships to be removed : ' || ln_cnt_dl);
      ln_cnt := ln_cnt_cr + ln_cnt_dl;

      IF ln_cnt > ln_load_limit
      THEN
         mail_alert (ln_cnt_cr, ln_cnt_dl, ln_cnt, ln_cnt_sy, x_status);
         x_override_fix := 'N';
         wr_log
            ('The number of mismatches has exceeded the set limit, skipping the auto correction process'
            );

         IF x_status = 'E'
         THEN
            RAISE e_fail;
         END IF;
      END IF;

      x_retcode := 0;
      wr_log ('Completed Check_load procedure successfully');
   EXCEPTION
      WHEN e_fail
      THEN
         x_retcode := 2;
      WHEN OTHERS
      THEN
         wr_log ('Error in  Check_load procedure  : ' || SQLERRM);
         x_retcode := 2;
   END check_load;

-- +========================================================================+
-- | Name        : load_aops                                                |
-- | Description : Read relationships from AOPS and dump in Oracle INT table|
-- +========================================================================+
   PROCEDURE load_aops (x_retcode OUT NUMBER)
   AS
      lc_db_name   VARCHAR2 (100);
      ln_limit     NUMBER          := 1000;-- Changed from 10000 to 1000 for effective batching
      lc_query     VARCHAR2 (500);

      TYPE lc_arels_ref IS REF CURSOR;

      c_arels      lc_arels_ref;

      TYPE lr_rec_type IS RECORD (
         pid   NUMBER,
         cid   NUMBER
      );

      TYPE lr_rec_tab IS TABLE OF lr_rec_type;

      lr_rec       lr_rec_tab;
      ln_count     NUMBER;
      l_tabcount   NUMBER          := 0;
      lc_query2    VARCHAR2 (1000);
   BEGIN
      x_retcode := 2;
      wr_log ('Starting load_aops procedure');
      wr_log ('Truncating table : xxod_cust_relate_temp');

      EXECUTE IMMEDIATE ('TRUNCATE TABLE xxcrm.xxod_cust_relate_temp');

      SELECT COUNT (1)
        INTO ln_count
        FROM xxod_cust_relate_temp;

      IF ln_count > 0
      THEN
         wr_log ('Load_AOPS proc failed, Truncate table failed');
         x_retcode := 2;
         RETURN;
      ELSE
         wr_log ('Truncate success');
      END IF;

      lc_db_name :=
         NVL (fnd_profile.VALUE ('XX_CDH_RELS_AOPS_DB_LINK'),
              'RACOONDTA.FCU005P@STUBBY.NA.ODCORP.NET'
             );
      wr_log ('DB link used : ' || lc_db_name);
      lc_query :=
            'SELECT FCU005P_PARENT_ID,FCU005P_CUSTOMER_ID FROM ' || lc_db_name;
      wr_log ('Query used : ' || lc_query);

      OPEN c_arels FOR lc_query;

      LOOP
         FETCH c_arels
         BULK COLLECT INTO lr_rec LIMIT ln_limit;

         EXIT WHEN lr_rec.COUNT < 1;
         FORALL i IN lr_rec.FIRST .. lr_rec.LAST
            INSERT INTO xxod_cust_relate_temp
                        (parent_id, child_id
                        )
                 VALUES (lr_rec (i).pid, lr_rec (i).cid
                        );
      END LOOP;

      COMMIT;

      CLOSE c_arels;

      x_retcode := 0;
      wr_log ('Completed load_aops procedure successfully');
   EXCEPTION
      WHEN OTHERS
      THEN
         wr_log ('Error in Load_aops procedure  :' || SQLERRM);
         x_retcode := 2;
   END load_aops;

-- +========================================================================+
-- | Name        : create_rels                                              |
-- | Description : Create Rels for all records in INT table where OP is NULL|
-- +========================================================================+
   PROCEDURE create_rels (x_retcode OUT NUMBER)
   AS
      CURSOR c_ac_rel
      IS
         SELECT parent_id, child_id, subject_id sub_id, object_id obj_id
           FROM xxod_cust_relate_temp temp
          WHERE op IS NULL AND subject_id IS NOT NULL
                AND object_id IS NOT NULL;

      ln_limit             NUMBER                                    := 1000;-- Changed from 10000 to 1000 for effective batching
      lr_rel_rec           hz_relationship_v2pub.relationship_rec_type;
      lc_relship_id        NUMBER;
      ln_ovn               NUMBER;
      lc_ret_status        VARCHAR2 (1);
      ln_msg_count         NUMBER;
      lc_msg_data          VARCHAR2 (1000);
      ln_party_ovn         NUMBER;
      ln_cr_rel_id         NUMBER;
      ln_cr_party_id       NUMBER;
      ln_cr_party_number   NUMBER;
      ln_pcount            NUMBER                                      := 0;
      ln_scount            NUMBER                                      := 0;
      ln_ecount            NUMBER                                      := 0;

      TYPE ltb_active_rel IS TABLE OF c_ac_rel%ROWTYPE;

      lt_active_rel        ltb_active_rel;
   BEGIN
      x_retcode := 2;
      wr_log ('Starting create_rels procedure');
      wr_log
         ('******************************************************************************************************'
         );
      wr_log ('Below relationships to be created :');
      wr_log
         ('------------------------------------------------------------------------------------------------------'
         );
      wr_log ('parent_id | child_id | subject_id | object_id');

      OPEN c_ac_rel;

      LOOP
         FETCH c_ac_rel
         BULK COLLECT INTO lt_active_rel LIMIT ln_limit;

         EXIT WHEN lt_active_rel.COUNT < 1;

         FOR i IN lt_active_rel.FIRST .. lt_active_rel.LAST
         LOOP
            BEGIN
               wr_log (   lt_active_rel (i).parent_id
                       || ','
                       || lt_active_rel (i).child_id
                       || ','
                       || lt_active_rel (i).sub_id
                       || ','
                       || lt_active_rel (i).obj_id
                      );
               ln_pcount := ln_pcount + 1;
               lr_rel_rec := NULL;
               lr_rel_rec.subject_id := lt_active_rel (i).sub_id;
               lr_rel_rec.subject_type := 'ORGANIZATION';
               lr_rel_rec.subject_table_name := 'HZ_PARTIES';
               lr_rel_rec.object_id := lt_active_rel (i).obj_id;
               lr_rel_rec.object_type := 'ORGANIZATION';
               lr_rel_rec.object_table_name := 'HZ_PARTIES';
               lr_rel_rec.relationship_code := 'PARENT_COMPANY';
               LR_REL_REC.RELATIONSHIP_TYPE := 'OD_CUST_HIER';
               lr_rel_rec.start_date := SYSDATE ;
               lr_rel_rec.created_by_module := 'TCA_V2_API';
               --TCA_API;  --- ADDED FOR DEFECT  31715
               hz_relationship_v2pub.create_relationship
                                        (p_init_msg_list           => fnd_api.g_true,
                                         p_relationship_rec        => lr_rel_rec,
                                         x_relationship_id         => ln_cr_rel_id,
                                         x_party_id                => ln_cr_party_id,
                                         x_party_number            => ln_cr_party_number,
                                         x_return_status           => lc_ret_status,
                                         x_msg_count               => ln_msg_count,
                                         x_msg_data                => lc_msg_data,
                                         p_create_org_contact      => NULL
                                        );

               IF lc_ret_status <> fnd_api.g_ret_sts_success
               THEN
                  lc_msg_data := NULL;

                  IF (ln_msg_count > 0)
                  THEN
                     FOR counter IN 1 .. ln_msg_count
                     LOOP
                        lc_msg_data :=
                              lc_msg_data
                           || ' '
                           || fnd_msg_pub.get (counter, fnd_api.g_false);
                     END LOOP;
                  END IF;

                  fnd_msg_pub.delete_msg;
                  ln_ecount := ln_ecount + 1;
                  wr_log ('Error : ' || lc_msg_data);
               ELSE
                  ln_scount := ln_scount + 1;
                  wr_log (   'Successfully created relationship_id: '
                          || ln_cr_rel_id
                         );
               END IF;

               IF (gc_commit = 'Y')
               THEN
                  COMMIT;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_ecount := ln_ecount + 1;
                  wr_log ('Error/Exception : ' || SQLERRM);
            END;
         END LOOP;
      END LOOP;

      CLOSE c_ac_rel;

      wr_out (   CHR (10)
              || 'Summary of the Create Relationship process'
              || CHR (10)
             );
      wr_out ('Total processed :' || ln_pcount);
      wr_out ('Total success :' || ln_scount);
      wr_out ('Total error :' || ln_ecount);
      x_retcode := 0;
      wr_log ('Completed create_rels procedure successfully');
   EXCEPTION
      WHEN OTHERS
      THEN
         wr_log ('Create Procedure errored out : ' || SQLERRM);
         x_retcode := 2;
   END create_rels;

-- +========================================================================+
-- | Name        : inactivate_rels                                          |
-- | Description : Inactivate Rels for all records in INT table where OP is 'D'|
-- +========================================================================+
   PROCEDURE inactivate_rels (x_retcode OUT NUMBER)
   AS
      CURSOR c_in_rel
      IS
         SELECT parent_id, child_id, subject_id, object_id
           FROM xxod_cust_relate_temp
          WHERE op = 'D';

      TYPE ltb_inactive_rel IS TABLE OF c_in_rel%ROWTYPE;

      lt_inactive_rel   ltb_inactive_rel;
      ln_limit          NUMBER                                      := NVL(fnd_profile.value ('XX_CDH_BULK_FETCH_LIMIT'),200); -- Changed from 10000 to 200 default for performance reasons
      lr_rel_rec        hz_relationship_v2pub.relationship_rec_type;
      lc_relship_id     NUMBER;
      ln_ovn            NUMBER;
      lc_ret_status     VARCHAR2 (1);
      ln_msg_count      NUMBER;
      lc_msg_data       VARCHAR2 (1000);
      ln_party_ovn      NUMBER;
      l_rec             VARCHAR2 (200);
      ln_pcount         NUMBER                                      := 0;
      ln_scount         NUMBER                                      := 0;
      ln_ecount         NUMBER                                      := 0;
      l_party_id        NUMBER;
   BEGIN
      x_retcode := 2;
      wr_log ('Starting inactivate_rels procedure');
      wr_log
         ('******************************************************************************************************'
         );
      wr_log ('Below relationships to be inactivated');
      wr_log
         ('------------------------------------------------------------------------------------------------------'
         );
      wr_log ('parent_id | child_id | subject_id | object_id');

      OPEN c_in_rel;

      LOOP
         FETCH c_in_rel
         BULK COLLECT INTO lt_inactive_rel LIMIT ln_limit;

         EXIT WHEN lt_inactive_rel.COUNT < 1;

         FOR j IN lt_inactive_rel.FIRST .. lt_inactive_rel.LAST
         LOOP
            BEGIN
               ln_pcount := ln_pcount + 1;
               wr_log (   lt_inactive_rel (j).parent_id
                       || ','
                       || lt_inactive_rel (j).child_id
                       || ','
                       || lt_inactive_rel (j).subject_id
                       || ','
                       || lt_inactive_rel (j).object_id
                      );

               SELECT relationship_id, object_version_number, party_id
                 INTO lc_relship_id, ln_ovn, l_party_id
                 FROM hz_relationships
                WHERE relationship_type = 'OD_CUST_HIER'
                  AND subject_id = lt_inactive_rel (j).subject_id
                  AND object_id = lt_inactive_rel (j).object_id
                  AND status = 'A'
                  AND relationship_code = 'PARENT_COMPANY'
                  AND direction_code = 'P';

               ------- ADDED FOR DEFECT  31715
               BEGIN
                  SELECT object_version_number
                    INTO ln_party_ovn
                    FROM hz_parties
                   WHERE party_id = l_party_id;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ln_party_ovn := NULL;
               END;

--- ADDED FOR DEFECT  31715
               lr_rel_rec.relationship_id := lc_relship_id;
               lr_rel_rec.status := 'I';
               lr_rel_rec.end_date := SYSDATE;
               hz_relationship_v2pub.update_relationship
                               (p_init_msg_list                    => fnd_api.g_true,
                                p_relationship_rec                 => lr_rel_rec,
                                p_object_version_number            => ln_ovn,
                                p_party_object_version_number      => ln_party_ovn,
                                x_return_status                    => lc_ret_status,
                                x_msg_count                        => ln_msg_count,
                                x_msg_data                         => lc_msg_data
                               );

               IF lc_ret_status <> fnd_api.g_ret_sts_success
               THEN
                  lc_msg_data := NULL;

                  IF (ln_msg_count > 0)
                  THEN
                     FOR counter IN 1 .. ln_msg_count
                     LOOP
                        lc_msg_data :=
                              lc_msg_data
                           || ' '
                           || fnd_msg_pub.get (counter, fnd_api.g_false);
                     END LOOP;
                  END IF;

                  fnd_msg_pub.delete_msg;
                  ln_ecount := ln_ecount + 1;
                  wr_log ('Error : ' || lc_msg_data);
               ELSE
                  ln_scount := ln_scount + 1;
                  wr_log (   'Successfully inactivated relationship_id: '
                          || lc_relship_id
                         );
               END IF;

               IF (gc_commit = 'Y')
               THEN
                  COMMIT;
               END IF;
            EXCEPTION
               WHEN OTHERS
               THEN
                  wr_log ('Error/Exception : ' || SQLERRM);
                  ln_ecount := ln_ecount + 1;
            END;
         END LOOP;
      END LOOP;

      CLOSE c_in_rel;

      wr_out (   CHR (10)
              || 'Summary of the Inactivate Relationship process'
              || CHR (10)
             );
      wr_out ('Total processed :' || ln_pcount);
      wr_out ('Total success :' || ln_scount);
      wr_out ('Total error :' || ln_ecount);
      x_retcode := 0;
      wr_log ('Completed Inactivate_rels procedure successfully');
   EXCEPTION
      WHEN OTHERS
      THEN
         wr_log ('Inactivate Procedure errored out : ' || SQLERRM);
         x_retcode := 2;
   END inactivate_rels;

-- +========================================================================+
-- | Name        : update_temp                                              |
-- | Description : If the rel is found in both Oracle and INT table then    |
-- |               update record in INT table with op as 'S', means in sync |
-- +========================================================================+
   PROCEDURE update_temp (
      p_parent   IN   NUMBER,
      p_child    IN   NUMBER,
      p_sub_id   IN   NUMBER,
      p_obj_id   IN   NUMBER
   )
   AS
   BEGIN
      UPDATE xxod_cust_relate_temp
         SET parent_id = p_parent,
             child_id = p_child,
             op = 'S'
       WHERE parent_id = p_parent AND child_id = p_child;
   EXCEPTION
      WHEN OTHERS
      THEN
         wr_log ('Error updating temp table, child_id : ' || p_child);
   END update_temp;

-- +========================================================================+
-- | Name        : insert_temp                                              |
-- | Description : If the record is found only in Oracle but not in INT,    |
-- |               then insert into Temp table with op as 'D', means Delete rel|
-- +========================================================================+
   PROCEDURE insert_temp (
      p_parent   IN   NUMBER,
      p_child    IN   NUMBER,
      p_sub_id   IN   NUMBER,
      p_obj_id   IN   NUMBER
   )
   AS
   BEGIN
      INSERT INTO xxod_cust_relate_temp
                  (parent_id, child_id, subject_id, object_id, op
                  )
           VALUES (p_parent, p_child, p_sub_id, p_obj_id, 'D'
                  );
   EXCEPTION
      WHEN OTHERS
      THEN
         wr_log (   'Error inserting temp table, child_id : '
                 || p_child
                 || ','
                 || 'parent_id : '
                 || p_parent
                );
   END insert_temp;

-- +========================================================================+
-- | Name        : main_procedure                                           |
-- | Description : Compares Oracle and AOPS rels and decides actions        |
-- +========================================================================+
   PROCEDURE rel_main (
      x_errbuf      OUT NOCOPY      VARCHAR2,
      x_retcode     OUT NOCOPY      VARCHAR2,
      p_load_aops   IN              VARCHAR2,
      p_run_fix     IN              VARCHAR2,
      p_chk_load    IN              VARCHAR2,
      p_commit      IN              VARCHAR2
   )
   AS
      CURSOR c_aops_rel (pid NUMBER, cid NUMBER)
      IS
         SELECT 1
           FROM xxod_cust_relate_temp
          where PARENT_ID = PID and CHILD_ID = CID and rownum <= 1;
-- USE_INVISIBLE_INDEX HINT ADDED AS RECOMMENDED BY ERP ENGINEERING TEAM -- Sreedhar Mohan 04-Sep-2015 -- USE_INVISIBLE_INDEXES
      CURSOR c_oracle_rel
      is
         SELECT /*+ NO_BIND_AWARE USE_INVISIBLE_INDEXES */  TO_NUMBER (SUBSTR (a.orig_system_reference, 1, 8)) parent_id,
                TO_NUMBER (SUBSTR (b.orig_system_reference, 1, 8)) child_id,
                a.party_id sub_id, b.party_id obj_id
           FROM hz_relationships r,
                hz_cust_accounts a,
                hz_cust_accounts b
          WHERE relationship_type = 'OD_CUST_HIER'
            AND relationship_code = 'PARENT_COMPANY'
            AND subject_type = 'ORGANIZATION'
            AND subject_table_name = 'HZ_PARTIES'
            AND object_type = 'ORGANIZATION'
            AND object_table_name = 'HZ_PARTIES'
            AND a.party_id = r.subject_id
            AND b.party_id = r.object_id
            AND r.status = 'A'
            AND SYSDATE BETWEEN start_date AND NVL (end_date, SYSDATE + 1);

      TYPE lt_oracle_rels IS TABLE OF c_oracle_rel%ROWTYPE
         INDEX BY BINARY_INTEGER;

      lr_oracle_rels   lt_oracle_rels;
      lr_aops_rels     c_aops_rel%ROWTYPE;
      l_limit          NUMBER (10)          := 100;
      e_procfail       EXCEPTION;
      e_load           EXCEPTION;
      lc_run_fix       VARCHAR2 (10);
   BEGIN
      gc_commit := p_commit;
      lc_run_fix := p_run_fix;

      IF p_load_aops = 'Y'
      THEN
         load_aops (x_retcode);

         IF (x_retcode <> 0)
         THEN
            RAISE e_load;
         END IF;

         OPEN c_oracle_rel;

         LOOP
            FETCH c_oracle_rel
            BULK COLLECT INTO lr_oracle_rels LIMIT l_limit;

            EXIT WHEN lr_oracle_rels.COUNT < 1;

            FOR i IN lr_oracle_rels.FIRST .. lr_oracle_rels.LAST
            LOOP
               OPEN c_aops_rel (lr_oracle_rels (i).parent_id,
                                lr_oracle_rels (i).child_id
                               );

               FETCH c_aops_rel
                INTO lr_aops_rels;

               IF c_aops_rel%FOUND
               THEN
                  update_temp (lr_oracle_rels (i).parent_id,
                               lr_oracle_rels (i).child_id,
                               lr_oracle_rels (i).sub_id,
                               lr_oracle_rels (i).obj_id
                              );
               ELSE
                  insert_temp (lr_oracle_rels (i).parent_id,
                               lr_oracle_rels (i).child_id,
                               lr_oracle_rels (i).sub_id,
                               lr_oracle_rels (i).obj_id
                              );
               END IF;

               CLOSE c_aops_rel;

               COMMIT;
            END LOOP;     --FOR i in lr_oracle_rels.FIRST..lr_oracle_rels.LAST
         END LOOP;

         --FETCH c_oracle_rel BULK COLLECT INTO lr_oracle_rels LIMIT l_limit;
         CLOSE c_oracle_rel;
      END IF;                                      --IF p_load_aops = 'Y' THEN

      fill_partyid (x_retcode);

      IF x_retcode = 2
      THEN
         RAISE e_procfail;
      END IF;

      IF p_chk_load = 'Y'
      THEN
         check_load (lc_run_fix, x_retcode);

         IF x_retcode = 2
         THEN
            RAISE e_procfail;
         END IF;
      END IF;

      IF lc_run_fix = 'Y'
      THEN
         inactivate_rels (x_retcode);

         IF x_retcode = 2
         THEN
            RAISE e_procfail;
         END IF;

         create_rels (x_retcode);

         IF x_retcode = 2
         THEN
            RAISE e_procfail;
         END IF;
      end if;
-- Commented for Performance improvement - Sreedhar Mohan - Aug-2015
  /*    IF (gc_commit = 'Y')
      THEN
         COMMIT;
         wr_log ('Commit');
      ELSE
         ROLLBACK;
         wr_log ('Rollback');
      END IF;
      */

      wr_log ('Main Program completed succesfully');
   EXCEPTION
      WHEN e_load
      THEN
         ROLLBACK;
      WHEN e_procfail
      THEN
         ROLLBACK;
      WHEN OTHERS
      THEN
         ROLLBACK;
         x_retcode := 2;
         wr_log ('Exception in main procedure' || SQLERRM);
   end REL_MAIN;
END XX_CDH_REL_SYNC_PKG;
/