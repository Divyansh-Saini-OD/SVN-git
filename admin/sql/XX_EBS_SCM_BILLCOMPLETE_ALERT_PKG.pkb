CREATE OR REPLACE PACKAGE BODY APPS.XX_EBS_SCM_BILLCOMPLETE_ALERT_PKG
AS
-- +======================================================================+
-- |                  Office Depot - Project Simplify                     |
-- |																	  |
-- +======================================================================+
-- | Name             : XXEBSSCMBILLCOMPLETEALERT.PKB                     |
-- | Description      : Package Body                                      |
-- |                                                                      |
-- |                                                                      |
-- |Change Record:                                                        |
-- |===============                                                       |
-- |Version    Date          Author           Remarks                     | 
-- |=======    ==========    =============    ============================|
-- |DRAFT 1A   09-03-2019    Arun Gannarapu   pending bill complete orders|
-- |                                                                      |
-- +======================================================================+
-- int_interface procedure will extract the items based on orders stuck in interface

   PROCEDURE int_interface (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2
   )
   IS
      L_MASTER_ITEM         VARCHAR2 (1000) := NULL;
      l_item_code           clob            := NULL;   -- 1.3
      l_count               NUMBER          := 0;
      p_status              VARCHAR2 (10);
      lc_error_message      VARCHAR2 (1000);
      l_loc_cnt             NUMBER          := 0;
      l_child_item          VARCHAR2 (1000) := NULL;
      l_loc                 VARCHAR2 (1000) := NULL;
      l_organization_name   VARCHAR2 (1000) := NULL;
      l_child_item_code       CLOB          := NULL;
      l_check          varchar2(1)          :='Y';
      l_email_list          VARCHAR2(2000)  := NULL;
      L_CHECK_STATUS        VARCHAR2(20)    :='Y';

----  Below varibles added for Defect#44629
       L_ITEM_CREATION_CHECK  VARCHAR2(1) := 'Y';
       L_ITEM_CREATION_CODE   CLOB            := NULL;
       L_ITEM_LOC_ERR_CODE    CLOB            := NULL;
       LC_MAIL_FROM        VARCHAR2 (100)      := 'noreply@officedepot.com';
       LC_MAIL_CONN        UTL_SMTP.CONNECTION;
       LC_INSTANCE         VARCHAR2 (100);
       L_TEXT              VARCHAR2(2000)  := NULL;

    L_MESSAGE VARCHAR2(2000) := 'Attached are the Item Interface errors which are stuck with the below criteria.'|| UTL_TCP.crlf ||'Items not created in EBS'
                                ||CHR(13) || 'Items not being assigned to the corresponding Locations.'||CHR(10) || 'Please check the attachment for error details.';
    V_FILENAME1       VARCHAR2(2000);
    V_FILENAME2       VARCHAR2(2000);
    V_FILENAME3      VARCHAR2(2000);
    v_filename4       VARCHAR2(2000);
    V_FILEHANDLE      UTL_FILE.FILE_TYPE;
    V_LOCATION        VARCHAR2 (200) := 'XXFIN_OUTBOUND_GLEXTRACT'; --??
    V_MODE            VARCHAR2 (1)       := 'W';
    L_MASTER_CNT NUMBER := 0;
    L_CHILD_CNT NUMBER := 0;

  ---- End Defect #44629

      CURSOR order_stuck
      IS
SELECT /*+ PARALLEL(4) */
a.parent_order_num, 
TO_CHAR(B.ORDER_NUMBER) CHILD_ODR, 
a.bill_comp_flag,
to_char(a.creation_date,'dd-mon-rrrr hh24:mi:ss'),
hp.party_name,
b.sold_to_org_id,
 --  a.*
from apps.xx_om_header_attributes_all a,
     apps.oe_order_headers_all b ,
     apps.hz_cust_accounts hca, 
     apps.hz_parties hp
where a.header_id = b.header_id
and hca.party_id = hp.party_id
and hca.cust_account_id = b.sold_to_org_id
--and b.sold_to_org_id in (31822,268535)
and a.bill_comp_flag in ('Y','B')
and b.last_update_date >= sysdate-15
AND NOT EXISTS ( SELECT 1 
                 FROM APPS.XX_SCM_BILL_SIGNAl
                 WHERE CHILD_ORDER_NUMBER = B.ORDER_NUMBER);

    V_FILENAME1   :=  'EBS_Bill_Complete_file_'||LC_INSTANCE ||'.txt';

    L_MASTER_ITEM := NULL;

    V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME1, v_mode);

     vl_hdr_message := 'Parent_order_number||'|'|'Child_order_number'||'|'||'Bill_complete_flag'||'|'||'Creation date'||'|'||'PARTY NAME'||'|'||'Account Number'||';
     UTL_FILE.PUT_LINE (V_FILEHANDLE, vl_hdr_message);
      FOR bc_order_rec IN order_stuck
      LOOP

        vl_line_message := bc_order_rec.parent_order_number||'|'|
                           bc_order_rec.child_order_number||'|'|
                           bc_order_rec.bill_Complete_flag||'|'|
                           bc_order_rec.creation_date||'|'|
                           bc_order_rec.party_name||'|'|
                           bc_order_rec.account_number||'|';

        UTL_FILE.PUT_LINE (V_FILEHANDLE, vl_line_message);
        UTL_FILE.FFLUSH(V_filehandle);
      END LOOP;

      UTL_FILE.FCLOSE (V_FILEHANDLE);

      IF lc_instance = 'GSIPRDGB'
      THEN
         l_text := 'Bill Complete pending order';
        ELSE
         L_TEXT :='Please Ignore this email: bill compelte reports ';
        END IF;
        fnd_file.put_line(fnd_file.log,'Before sending mail');
       SEND_MAIL_PRC (
         LC_MAIL_FROM ,
         l_email_list,
         L_TEXT,
         L_MESSAGE
         || CHR (13),
         V_FILENAME1,
         V_LOCATION                               --default null
       ) ;

    fnd_file.put_line(fnd_file.log,' After calling Email Notification ' );
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Notification Successfully Sent To:' || NVL(L_EMAIL_LIST,'NO MAIL ADDRESS SETUP'));

    retcode := 0;
    errbuf := 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         fnd_file.put_line (fnd_file.LOG,'No Data found');
         p_status := 'N';
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,'Unknown Error occured'||SQLERRM);
         p_status := 'N';
   END;

  PROCEDURE send_mail_prc (
      p_sender      IN   VARCHAR2,
      p_recipient   IN   VARCHAR2,
      p_subject     IN   VARCHAR2,
      p_message     IN   CLOB,
      attachlist    IN   VARCHAR2,                            -- default null,
      DIRECTORY     IN   VARCHAR2                               --default null
   )
   AS
      --l_mailhost     VARCHAR2 (255)          := 'gwsmtp.usa.net';
      l_mailhost     VARCHAR2 (100)  := fnd_profile.VALUE ('XX_COMN_SMTP_MAIL_SERVER');
                                                                        --2.0
      l_mail_conn    UTL_SMTP.connection;
      v_add_src      VARCHAR2 (4000);
      v_addr         VARCHAR2 (4000);
      slen           NUMBER                  := 1;
      crlf           VARCHAR2 (2)            := CHR (13) || CHR (10);
      i              NUMBER (12);
      j              NUMBER (12);
      len            NUMBER (12);
      len1           NUMBER (12);
      part           NUMBER (12)             := 16384;
      /*extraashu start*/
      smtp           UTL_SMTP.connection;
      reply          UTL_SMTP.reply;
      file_handle    BFILE;
      file_exists    BOOLEAN;
      block_size     NUMBER;
      file_len       NUMBER;
      pos            NUMBER;
      total          NUMBER;
      read_bytes     NUMBER;
      DATA           RAW (200);
      my_code        NUMBER;
      my_errm        VARCHAR2 (32767);
      mime_type      VARCHAR2 (50);
      myhostname     VARCHAR2 (255);
      att_table      DBMS_UTILITY.uncl_array;
      att_count      NUMBER;
      tablen         BINARY_INTEGER;
      loopcount      NUMBER;
      /*extraashu end*/
      l_stylesheet   CLOB
         := '
       <html><head>
       <style type="text/css">
                   body     { font-family     : Verdana, Arial;
                              font-size       : 10pt;}

                   .green   { color           : #00AA00;
                              font-weight     : bold;}

                   .red     { color           : #FF0000;
                              font-weight     : bold;}

                   pre      { margin-left     : 10px;}

                   table    { empty-cells     : show;
                              border-collapse : collapse;
                              width           : 100%;
                              border          : solid 2px #444444;}

                   td       { border          : solid 1px #444444;
                              font-size       : 12pt;
                              padding         : 2px;}

                   th       { background      : #EEEEEE;
                              border          : solid 1px #444444;
                              font-size       : 12pt;
                              padding         : 2px;}

                   dt       { font-weight     : bold; }

                  </style>
                 </head>
                 <body>';
               /*EXTRAASHU START*/
--    Procedure WriteLine(
--          line          in      varchar2 default null
--       ) is
--       Begin
--          utl_smtp.Write_Data( smtp, line||utl_tcp.CRLF );
--       End;
   BEGIN
      l_mail_conn := UTL_SMTP.open_connection (l_mailhost, 25);
      UTL_SMTP.helo (l_mail_conn, l_mailhost);
      UTL_SMTP.mail (l_mail_conn, p_sender);

      IF (INSTR (p_recipient, ',') = 0)
      THEN
         fnd_file.put_line (fnd_file.LOG, 'rcpt ' || p_recipient);
         UTL_SMTP.rcpt (l_mail_conn, p_recipient);
      ELSE
         v_add_src := p_recipient || ',';

         WHILE (INSTR (v_add_src, ',', slen) > 0)
         LOOP
            v_addr :=
               SUBSTR (v_add_src,
                       slen,
                       INSTR (SUBSTR (v_add_src, slen), ',') - 1
                      );
            slen := slen + INSTR (SUBSTR (v_add_src, slen), ',');
             fnd_file.put_line (fnd_file.LOG, 'rcpt ' || v_addr);
            UTL_SMTP.rcpt (l_mail_conn, v_addr);
         END LOOP;
      END IF;
     --UTL_SMTP.write_data (l_mail_conn, crlf);
      --utl_smtp.rcpt(l_mail_conn, p_recipient);
      UTL_SMTP.open_data (l_mail_conn);
      UTL_SMTP.write_data (l_mail_conn,
                              'MIME-version: 1.0'
                           || crlf
                           || 'Content-Type: text/html; charset=ISO-8859-15'
                           || crlf
                           || 'Content-Transfer-Encoding: 8bit'
                           || crlf
                           || 'Date: '
                           || TO_CHAR ((SYSDATE - 1 / 24),
                                       'Dy, DD Mon YYYY hh24:mi:ss',
                                       'nls_date_language=english'
                                      )
                           || crlf
                           || 'From: '
                           || p_sender
                           || crlf
                           || 'Subject: '
                           || p_subject
                           || crlf
                           || 'To: '
                           || p_recipient
                           || crlf
                          );
      UTL_SMTP.write_data
         (l_mail_conn,
             'Content-Type: multipart/mixed; boundary="gc0p4Jq0M2Yt08jU534c0p"'
          || crlf
         );
      UTL_SMTP.write_data (l_mail_conn, 'MIME-Version: 1.0' || crlf);
      UTL_SMTP.write_data (l_mail_conn, crlf);
--              UTL_SMTP.write_data (l_mail_conn,'--gc0p4Jq0M2Yt08jU534c0p'||crlf);
--              UTL_SMTP.write_data (l_mail_conn,'Content-Type: text/plain'||crlf);
--              UTL_SMTP.write_data (l_mail_conn,crlf);
            -- UTL_SMTP.write_data (l_mail_conn,  Body ||crlf);
      UTL_SMTP.write_data (l_mail_conn, crlf);
      UTL_SMTP.write_data (l_mail_conn, '--gc0p4Jq0M2Yt08jU534c0p' || crlf);
      UTL_SMTP.write_data (l_mail_conn,
                              'Content-Type: text/html; charset=ISO-8859-15'
                           || crlf
                          );
      UTL_SMTP.write_data (l_mail_conn,
                           'Content-Transfer-Encoding: 8bit' || crlf || crlf
                          );
      UTL_SMTP.write_raw_data (l_mail_conn,
                               UTL_RAW.cast_to_raw (l_stylesheet));
      i := 1;
      len := DBMS_LOB.getlength (p_message);

      WHILE (i < len)
      LOOP
         UTL_SMTP.write_raw_data
                            (l_mail_conn,
                             UTL_RAW.cast_to_raw (DBMS_LOB.SUBSTR (p_message,
                                                                   part,
                                                                   i
                                                                  )
                                                 )
                            );
         i := i + part;
      END LOOP;

      /*j:= 1;
      len1 := DBMS_LOB.getLength(p_message1);
      WHILE (j < len1) LOOP
          utl_smtp.write_raw_data(l_mail_conn, utl_raw.cast_to_raw(DBMS_LOB.SubStr(p_message1,part, i)));
          j := j + part;
      END LOOP;*/
      UTL_SMTP.write_raw_data (l_mail_conn,
                               UTL_RAW.cast_to_raw ('</body></html>')
                              );
          /*EXTRAASHU START*/
--        WriteLine;
      UTL_SMTP.write_data (l_mail_conn, crlf);
      --  WriteLine( '--gc0p4Jq0M2Yt08jU534c0p' );
      UTL_SMTP.write_data (l_mail_conn, '--gc0p4Jq0M2Yt08jU534c0p' || crlf);
      -- Split up the attachment list
      loopcount := 0;

      SELECT COUNT (*)
        INTO ATT_COUNT
        FROM TABLE (xx_int_err_notificatn_pkg.SPLIT (attachlist, NULL));

      IF attachlist IS NOT NULL AND DIRECTORY IS NOT NULL
      THEN
         FOR I IN (SELECT LTRIM (RTRIM (COLUMN_VALUE)) AS ATTACHMENT
                     FROM TABLE (xx_int_err_notificatn_pkg.SPLIT (attachlist, NULL)))
         LOOP
            loopcount := loopcount + 1;
            fnd_file.put_line (fnd_file.LOG,
                               'Attaching: ' || DIRECTORY || '/'
                               || i.attachment
                              );
            UTL_FILE.fgetattr (DIRECTORY,
                               i.attachment,
                               file_exists,
                               file_len,
                               block_size
                              );

            IF file_exists
            THEN
               fnd_file.put_line (fnd_file.LOG,
                                  'Getting mime_type for the attachment'
                                 );


              mime_type := 'text/plain';
               --  WriteLine( 'Content-Type: '||mime_type );
               UTL_SMTP.write_data (l_mail_conn,
                                    'Content-Type: ' || mime_type || crlf
                                   );
               --    WriteLine( 'Content-Transfer-Encoding: base64');
               UTL_SMTP.write_data (l_mail_conn,
                                    'Content-Transfer-Encoding: base64'
                                    || crlf
                                   );
               --WriteLine( 'Content-Disposition: attachment; filename="'||i.attachment||'"' );
               UTL_SMTP.write_data
                             (l_mail_conn,
                                 'Content-Disposition: attachment; filename="'
                              || REPLACE (i.attachment, '.req', '.txt')
                              || '"'
                              || crlf
                             );
               --   WriteLine;
               UTL_SMTP.write_data (l_mail_conn, crlf);
               file_handle := BFILENAME (DIRECTORY, i.attachment);
               pos := 1;
               total := 0;
               file_len := DBMS_LOB.getlength (file_handle);
               DBMS_LOB.OPEN (file_handle, DBMS_LOB.lob_readonly);

               LOOP
                  IF pos + 57 - 1 > file_len
                  THEN
                     read_bytes := file_len - pos + 1;
                     fnd_file.put_line (fnd_file.LOG,
                                        'Last read - Start: ' || pos
                                       );
                  ELSE
                     fnd_file.put_line (fnd_file.LOG,
                                        'Reading - Start: ' || pos
                                       );
                     read_bytes := 57;
                  END IF;

                  total := total + read_bytes;
                  DBMS_LOB.READ (file_handle, read_bytes, pos, DATA);
                  UTL_SMTP.write_raw_data (l_mail_conn,
                                           UTL_ENCODE.base64_encode (DATA)
                                          );
                  --utl_smtp.write_raw_data(smtp,data);
                  pos := pos + 57;

                  IF pos > file_len
                  THEN
                     EXIT;
                  END IF;
               END LOOP;

               fnd_file.put_line (fnd_file.LOG, 'Length was ' || file_len);
               DBMS_LOB.CLOSE (file_handle);

               IF (loopcount < att_count)
               THEN
                  --WriteLine;
                  UTL_SMTP.write_data (l_mail_conn, crlf);
                  --WriteLine( '--gc0p4Jq0M2Yt08jU534c0p' );
                  UTL_SMTP.write_data (l_mail_conn,
                                       '--gc0p4Jq0M2Yt08jU534c0p' || crlf
                                      );
               ELSE
                  --WriteLine;
                  UTL_SMTP.write_data (l_mail_conn, crlf);
                  -- WriteLine( '--gc0p4Jq0M2Yt08jU534c0p--' );
                  UTL_SMTP.write_data (l_mail_conn,
                                       '--gc0p4Jq0M2Yt08jU534c0p--' || crlf
                                      );
                  fnd_file.put_line (fnd_file.LOG, 'Writing end boundary');
               END IF;
            ELSE
               fnd_file.put_line (fnd_file.LOG,
                                     'Skipping: '
                                  || DIRECTORY
                                  || '/'
                                  || i.attachment
                                  || 'Does not exist.'
                                 );
            END IF;
         END LOOP;
      END IF;

      /*EXTRAASHU END*/
      UTL_SMTP.close_data (l_mail_conn);
      UTL_SMTP.QUIT (L_MAIL_CONN);
   END SEND_MAIL_PRC;
    Function split
   (
      p_list varchar2,
      p_del varchar2 --:= ','
   ) return split_tbl pipelined
   is
      p_del1 varchar2(1):= ',';
      l_idx    pls_integer;
      l_list    varchar2(32767) := p_list;
      l_value    varchar2(32767);
   begin
   p_del1 := ',';
      loop
         l_idx := instr(l_list,p_del1);
         if l_idx > 0 then
            pipe row(substr(l_list,1,l_idx-1));
            l_list := substr(l_list,l_idx+length(p_del1));
         else
            pipe row(l_list);
            exit;
         end if;
      end loop;
      RETURN;
   end split;

END xx_int_err_notificatn_pkg;
/
