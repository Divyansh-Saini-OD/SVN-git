CREATE OR REPLACE PACKAGE BODY xx_pa_pb_compliance_pkg
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                           |
-- +===================================================================================+
-- | Name        :  XX_PA_PB_COMPLIANCE_PKG.pkb                                        |
-- | Description :  OD PA PB Product Upload Pkg                                        |
-- | Rice id     :  E2069                                                              |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author             Remarks                                   |
-- |========  =========== ================== =================================  =======|
-- |1.0       23-Sep-2010 Paddy Sanjeevi     Initial version                           |
-- |1.1       31-Jan-2011 Paddy Sanjeevi     Removed update of Next Audit Date         |
-- |1.2       21-Feb-2011 Paddy Sanjeevi     Removed update for NB Status              |
-- |1.3       17-Mar-2011 Paddy Sanjeevi     Changed Need Improvement dates            |
-- |1.4       27-May-2011 Rama Dwibhashyam   added procedure for enhancements          |
-- |1.5       01-Oct-2011 Rama Dwibhashyam   added procedure for enhancements          |
-- |1.6       01-Dec-2011 Rama Dwibhashyam   Fixed QC defect 15296                     |
-- |1.7       19-Jul-2012 Paddy Sanjeevi     Fixed QC defect 19239                     |
-- |1.8       05-Dec-2012 Satish Silveri     Changes as per QC defect 21138            |
-- |1.9       11-Jun-2013 Kiran Maddala	     Changes as per QC defect 23300            |
-- |1.10      01-Jul-2013 Paddy Sanjeevi     Modified for R12                          |
-- |1.11      12-Jul-2014 shishir sahay      Added Debug messages for defect  30098    |                                                                               |
-- |1.12      14-Jul-2014 Shishir Sahay      Update Distribution list as perdefect30917|
-- |1.13      01-Aug-2014 Manjusha Tangirala Removal of harcoding Defect 31287         |
-- |1.14      25-Aug-2014 Paddy Sanjeevi     Added call to assign_globals              |
-- |1.15      16-Sep-2014 Manjusha Tangirala Changes to email assignments      		   |
--                                                      in xx_sc_int_process           |
-- |1.16      17-Sep-2014 Paddy Sanjeevi   Change mime type to text 31287              |
-- |1.17      02-Oct-2014 Shishir Sahay    Commented audit request date and API sending|
-- |                                       late audit email notifications to UL RS     |
-- |                                       (3rd party provider)as per defect #31511    |
-- |1.18      21-OCT-2014 Saritha Mummaneni           Changed to fix NULL from address |
-- |                                      for email notification as per defect # 32310 |
-- |1.19      23-Nov-2015 Harvinder Rakhra Retrofit R12.2                              |
-- |1.20      18-Jan-2016 Paddy Sanjeevi   Retrofit R12.2                              |
-- +===================================================================================+
AS
----------------------------------------------------------------------------------------
--Declaring xx_process_data
----------------------------------------------------------------------------------------
  Gc_Notify_Contact1 Xx_Fin_Translatevalues.Target_Value1%Type;
  Gc_Notify_Contact2 Xx_Fin_Translatevalues.Target_Value2%Type;
  Gc_Notify_Contact3 Xx_Fin_Translatevalues.Target_Value3%Type;
  Gc_Sa_Compliance_Sender Xx_Fin_Translatevalues.Target_Value4%Type;
  Gc_Audit_Regrush_Notify Xx_Fin_Translatevalues.Target_Value5%Type;
  Gc_Aud_Result_Notify Xx_Fin_Translatevalues.Target_Value6%Type;
  Gc_Vendsk_Notify Xx_Fin_Translatevalues.Target_Value7%Type;
  Gc_Gso_Social_Notify Xx_Fin_Translatevalues.Target_Value8%Type;
  Gc_Eu_Social_Notify Xx_Fin_Translatevalues.Target_Value9%Type;
  Gc_Asia_Social_Notify Xx_Fin_Translatevalues.Target_Value10%Type;
  Gc_odmx_social_notify Xx_Fin_Translatevalues.Target_Value11%Type;
  Gc_Errbuf  VARCHAR2(200) :=NULL;
  gc_retcode NUMBER        := NULL;
  -- Procedure added to remove hard coding fo defect 31287
  PROCEDURE Assign_Globals
  IS
  Lc_Action VARCHAR2(300);
  BEGIN
  Fnd_File.Put_Line(Fnd_File.log,'Step 1: Assigning Defaults');
  SELECT xftv.target_value1 ,
    xftv.target_value2 ,
    xftv.target_value3 ,
    xftv.target_value4 ,
    xftv.target_value5 ,
    xftv.target_value6 ,
    Xftv.Target_Value7 ,
    Xftv.Target_Value8 ,
    Xftv.Target_Value9 ,
    Xftv.Target_Value10,
    Xftv.Target_Value11
   INTO Gc_Notify_Contact1 ,
    Gc_Notify_Contact2 ,
    Gc_Notify_Contact3 ,
    Gc_Sa_Compliance_Sender ,
    Gc_Audit_Regrush_Notify ,
    Gc_Aud_Result_Notify ,
    Gc_Vendsk_Notify ,
    Gc_Gso_Social_Notify ,
    Gc_Eu_Social_Notify ,
    Gc_Asia_Social_Notify,
    Gc_odmx_social_notify
   FROM xx_fin_translatedefinition xftd ,
    xx_fin_translatevalues xftv
   WHERE Xftd.Translate_Id   = Xftv.Translate_Id
   AND Xftd.Translation_Name = 'XX_PA_PB_COMPLIANCE_EMAIL'
   AND XFTV.source_value1    ='XX_COMPLIANCE_EMAIL'
   AND SYSDATE BETWEEN XFTV.start_date_active AND NVL(XFTV.end_date_active,SYSDATE+1)
   AND SYSDATE BETWEEN XFTD.start_date_active AND NVL(XFTD.end_date_active,SYSDATE+1)
   AND Xftv.Enabled_Flag = 'Y'
   AND Xftd.Enabled_Flag = 'Y';
 EXCEPTION
  WHEN OTHERS THEN

  Gc_Notify_Contact1      := 'padmanaban.sanjeevi@officedepot.com';
  Gc_Notify_Contact2      := 'francia.pampillonia@officedepot.com';
  Gc_Notify_Contact3      := 'sandy.stainton@officedepot.com';
  Gc_Sa_Compliance_Sender := 'SA-Compliance@officedepot.com';
  Gc_Audit_Regrush_Notify := 'OfficeDepot@ul.com';
  Gc_Aud_Result_Notify    := 'Sabrina.hernandezcruz@officedepot.com';
  Gc_Vendsk_Notify        := 'VendorDesk@officedepot.com';
  Gc_Gso_Social_Notify    := 'gso.socialaccountability@officedepot.com';
  Gc_Eu_Social_Notify     := 'Compliance.EU@officedepot.com';
  Gc_Asia_Social_Notify   := 'asia.socialaccountability@officedepot.com' ;
  Gc_odmx_social_notify   := 'ODMX.socialaccountability@officedepot.com.mx' ;
   END;


   FUNCTION check_vend_dup (p_vend_no IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_cnt         NUMBER        := 0;
      v_vendor_no   VARCHAR2 (50);
   BEGIN
      SELECT od_sc_vendor_number
        INTO v_vendor_no
        FROM q_od_pb_sc_vendor_master_v
       WHERE od_sc_vendor_number = p_vend_no;

      RETURN ('N');
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN ('N');
      WHEN OTHERS
      THEN
         RETURN ('N');
   END check_vend_dup;

   PROCEDURE vend_request (
      p_subject   IN   VARCHAR2,
      p_email     IN   VARCHAR2,
      p_ccmail    IN   VARCHAR2,
      p_text      IN   VARCHAR2,
      p_plan_id   IN   NUMBER,
      p_ocr       IN   NUMBER
   )
   IS
      v_addlayout     BOOLEAN;
      v_wait          BOOLEAN;
      v_request_id    NUMBER;
      vc_request_id   NUMBER;
      v_file_name     VARCHAR2 (50);
      v_dfile_name    VARCHAR2 (50);
      v_sfile_name    VARCHAR2 (50);
      x_dummy         VARCHAR2 (2000);
      v_dphase        VARCHAR2 (100);
      v_dstatus       VARCHAR2 (100);
      v_phase         VARCHAR2 (100);
      v_status        VARCHAR2 (100);
      x_cdummy        VARCHAR2 (2000);
      v_cdphase       VARCHAR2 (100);
      v_cdstatus      VARCHAR2 (100);
      v_cphase        VARCHAR2 (100);
      v_cstatus       VARCHAR2 (100);
      conn            UTL_SMTP.connection;
      lc_send_mail    VARCHAR2 (1)
                                  := fnd_profile.VALUE ('XX_PB_SC_SEND_MAIL');

      CURSOR c1
      IS
         SELECT fl.file_name, fl.file_id, fl.file_data, fl.file_content_type,
                fdc.user_name
           FROM fnd_lobs fl,
                fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = p_plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id
            AND fl.file_id = fd.media_id  --Modified for R12
            AND fdc.user_name = 'SR_OD PO Terms';
   BEGIN
       fnd_file.put_line (fnd_file.LOG, ' Entered into template layout');
	   fnd_file.put_line (fnd_file.LOG, ' occurrence:'||p_ocr);
	   fnd_file.put_line (fnd_file.LOG, ' plan_id:'||p_plan_id);

      v_addlayout :=
         fnd_request.add_layout (template_appl_name      => 'XXMER',
                                 template_code           => 'XXPAVNDI',
                                 template_language       => 'en',
                                 template_territory      => 'US',
                                 output_format           => 'PDF'
                                );

      IF (v_addlayout)
      THEN
         fnd_file.put_line (fnd_file.LOG, 'The layout has been submitted');
      ELSE
         fnd_file.put_line (fnd_file.LOG,
                            'The layout has not been submitted');
      END IF;
      fnd_file.put_line (fnd_file.LOG, ' before calling XXPAVNDI');
      v_request_id :=
         fnd_request.submit_request ('XXMER',
                                     'XXPAVNDI',
                                     'OD PB SC Vendor Request',
                                     NULL,
                                     FALSE,
                                     TO_CHAR (p_plan_id),
                                     TO_CHAR (p_ocr),
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL
                                    );

      IF v_request_id > 0
      THEN
         COMMIT;
         v_file_name := 'XXPAVNDI_' || TO_CHAR (v_request_id) || '_1.PDF';
         v_dfile_name :=
                   '$XXMER_DATA/outbound/' || TO_CHAR (v_request_id)
                   || '.PDF';
         v_sfile_name := TO_CHAR (v_request_id) || '.PDF';

				   fnd_file.put_line(fnd_file.LOG,'#9 Request Id '||v_request_id);
                   fnd_file.put_line(fnd_file.LOG,'#9 File name '||v_file_name);
      END IF;
      fnd_file.put_line (fnd_file.LOG, ' #9.1 after program submision');
      IF (fnd_concurrent.wait_for_request (v_request_id,
                                           1,
                                           60000,
                                           v_phase,
                                           v_status,
                                           v_dphase,
                                           v_dstatus,
                                           x_dummy
                                          )
         )
      THEN
         IF v_dphase = 'COMPLETE'
         THEN
		    fnd_file.put_line (fnd_file.LOG, ' #9.2 before XXCOMFILCOPY ');
            v_file_name := '$APPLCSF/$APPLOUT/' || v_file_name;
            vc_request_id :=
               fnd_request.submit_request ('XXFIN',
                                           'XXCOMFILCOPY',
                                           'OD: Common File Copy',
                                           NULL,
                                           FALSE,
                                           v_file_name,
                                           v_dfile_name,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL
                                          );

            IF vc_request_id > 0
            THEN
			 fnd_file.put_line (fnd_file.LOG, ' #9.3 before commit ');
               COMMIT;
            END IF;

            IF (fnd_concurrent.wait_for_request (vc_request_id,
                                                 1,
                                                 60000,
                                                 v_cphase,
                                                 v_cstatus,
                                                 v_cdphase,
                                                 v_cdstatus,
                                                 x_cdummy
                                                )
               )
            THEN
               IF v_cdphase = 'COMPLETE'
               THEN                                                  -- child
                  IF lc_send_mail = 'Y'
                  THEN
				   fnd_file.put_line(fnd_file.LOG,'#10 p_ccmail: '||p_email);
                   fnd_file.put_line(fnd_file.LOG,'#10 p_ccmail :'||p_ccmail);
                     conn :=
                        xx_pa_pb_mail.begin_mail
                              (sender             => Gc_Sa_Compliance_Sender,
                               recipients         => p_email,
                               cc_recipients      => p_ccmail,
                               subject            => p_subject,
                               mime_type          => xx_pa_pb_mail.multipart_mime_type
                              );
                  ELSE
				    fnd_file.put_line(fnd_file.LOG,'#10.1 before conn ');
                     conn :=
                        xx_pa_pb_mail.begin_mail
                           (sender             =>  Gc_Sa_Compliance_Sender,
                            recipients         =>  Gc_Notify_Contact1,
                            cc_recipients      =>  Gc_Notify_Contact3 ||';'||Gc_Notify_Contact2,
                            subject            => p_subject,
                            mime_type          => xx_pa_pb_mail.multipart_mime_type
                           );
					 fnd_file.put_line(fnd_file.LOG,'#10.2 after conn ');
                  END IF;

                  FOR cf IN c1
                  LOOP
                     xx_pa_pb_mail.xx_attch_doc (conn,
                                                 cf.file_name,
                                                 cf.file_data,
                                                 cf.file_content_type
                                                );
					 fnd_file.put_line(fnd_file.LOG,'#10.4 after attach ');

                  END LOOP;
                    fnd_file.put_line(fnd_file.LOG,' #10.5 all condition satisfied ');
                  xx_pa_pb_mail.xx_attch_rpt (conn, v_sfile_name);
                  xx_pa_pb_mail.end_attachment (conn => conn);
                  xx_pa_pb_mail.attach_text (conn           => conn,
                                             DATA           => p_text --,  Defect 31287
                                             --mime_type      => 'multipart/html'
                                            );
                  xx_pa_pb_mail.end_mail (conn => conn);
               END IF;               --IF v_cdphase = 'COMPLETE' THEN -- child
			     fnd_file.put_line(fnd_file.LOG,' #10.6 end if ');
            END IF;
			     fnd_file.put_line(fnd_file.LOG,' #10.7 end if ');
         --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,
         END IF;
                 fnd_file.put_line(fnd_file.LOG,' #10.8 end if ');		 -- IF v_dphase = 'COMPLETE' THEN  -- Main
      END IF;                   -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
   END vend_request;

   PROCEDURE send_notification (
      p_subject         IN   VARCHAR2,
      p_email_list      IN   VARCHAR2,
      p_cc_email_list   IN   VARCHAR2,
      p_text            IN   VARCHAR2
   )
   IS
      lc_mailhost   VARCHAR2 (64) := fnd_profile.VALUE ('XX_PA_PB_MAIL_HOST');
      lc_from       VARCHAR2 (64)       := Gc_Sa_Compliance_Sender;
      l_mail_conn   UTL_SMTP.connection;
      lc_to         VARCHAR2 (2000);
      lc_cc         VARCHAR2 (2000);
      lc_to_all     VARCHAR2 (2000)     := p_email_list;
      lc_cc_all     VARCHAR2 (2000)     := p_cc_email_list;
      i             BINARY_INTEGER;
      j             BINARY_INTEGER;
      ld_est_date   DATE;

      TYPE t_v100 IS TABLE OF VARCHAR2 (100)
         INDEX BY BINARY_INTEGER;

      lc_to_tbl     t_v100;
      lc_cc_tbl     t_v100;
      lc_database   VARCHAR2 (100);
      lc_subject    VARCHAR2 (3000);
      crlf          VARCHAR2 (10)       := UTL_TCP.crlf;
   BEGIN

    -- Modified code as per defect # 32310
       assign_globals;
       lc_from          := Gc_Sa_Compliance_Sender;

       -- End of code modification as per defect # 32310


      BEGIN

        SELECT new_time( sysdate, 'GMT', 'EST' )
          INTO ld_est_date
          FROM dual;
		           fnd_file.put_line(fnd_file.LOG,'#12 Subject: '||p_subject);
                   fnd_file.put_line(fnd_file.LOG,'#12 Text: '||p_text);
				   fnd_file.put_line(fnd_file.LOG,'#12 Mail To '||lc_to_all);
                   fnd_file.put_line(fnd_file.LOG,'#12 Mail CC To '||lc_cc_all);

      EXCEPTION
        WHEN OTHERS
        THEN
          ld_est_date := sysdate ;
      END;
      -- checking for the database added by Rama for 11.3
      BEGIN
         SELECT NAME
           INTO lc_database
           FROM v$database;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            lc_database := 'GSIDEV01';
         WHEN OTHERS
         THEN
            lc_database := 'GSIDEV01';
      END;

      lc_subject := p_subject;
      fnd_file.put_line(fnd_file.LOG,'#17 lc_subject '||lc_subject);
      IF lc_database <> 'GSIPRDGB'
      THEN
         lc_subject := 'Please Ignore this email :' || lc_subject;
		 fnd_file.put_line(fnd_file.LOG,'#20 Data base check '||lc_database);
      END IF;

      -- If setup data is missing then return
      IF lc_mailhost IS NULL OR lc_to_all IS NULL
      THEN
         RETURN;
      END IF;

      l_mail_conn := UTL_SMTP.open_connection (lc_mailhost, 25);
      UTL_SMTP.helo (l_mail_conn, lc_mailhost);
      UTL_SMTP.mail (l_mail_conn, lc_from);
      -- Check how many recipients are present in lc_to_all
      i := 1;
          fnd_file.put_line(fnd_file.LOG,'#21 Before opening the loop ');
      LOOP
         lc_to := SUBSTR (lc_to_all, 1, INSTR (lc_to_all, ':') - 1);

		 fnd_file.put_line(fnd_file.LOG,'#13 lc_to '||lc_to);

         IF lc_to IS NULL OR i = 20
         THEN
            lc_to_tbl (i) := lc_to_all;
            UTL_SMTP.rcpt (l_mail_conn, lc_to_all);
			fnd_file.put_line(fnd_file.LOG,' #13.1 inside lc_to if condition ');
            EXIT;
         END IF;

         lc_to_tbl (i) := lc_to;
         UTL_SMTP.rcpt (l_mail_conn, lc_to);
		 fnd_file.put_line(fnd_file.LOG,'#13.2 after UTL_SMTP.rcpt ');
         lc_to_all := SUBSTR (lc_to_all, INSTR (lc_to_all, ':') + 1);
		  fnd_file.put_line(fnd_file.LOG,'#14 lc_to_all '||lc_to_all);
         i := i + 1;
      END LOOP;

      IF lc_cc_all IS NOT NULL
      THEN
         j := 1;
        fnd_file.put_line(fnd_file.LOG,' #14.1 inside lc_cc_all if condition ');
         LOOP
            lc_cc := SUBSTR (lc_cc_all, 1, INSTR (lc_cc_all, ':') - 1);
			 fnd_file.put_line(fnd_file.LOG,'#15 lc_cc '||lc_cc);

            IF lc_cc IS NULL OR j = 20
            THEN
               lc_cc_tbl (j) := lc_cc_all;
               UTL_SMTP.rcpt (l_mail_conn, lc_cc_all);
			   fnd_file.put_line(fnd_file.LOG,' #15.1  UTL_SMTP.rcpt  '||lc_cc_all);
               EXIT;
            END IF;

            lc_cc_tbl (j) := lc_cc;
            UTL_SMTP.rcpt (l_mail_conn, lc_cc);
            lc_cc_all := SUBSTR (lc_cc_all, INSTR (lc_cc_all, ':') + 1);
			 fnd_file.put_line(fnd_file.LOG,'#16 lc_cc_all '||lc_cc_all);
            j := j + 1;
         END LOOP;
      END IF;
      fnd_file.put_line(fnd_file.LOG,'#16.1 before UTL_SMTP ');
	  fnd_file.put_line(fnd_file.LOG,'#16.2 lc_from '||lc_from);
	  fnd_file.put_line(fnd_file.LOG,'#16.3 lc_subject '||lc_subject);
      UTL_SMTP.open_data (l_mail_conn);
      UTL_SMTP.write_data (l_mail_conn,
                              'Date: '
                           || TO_CHAR (ld_est_date, 'DD-MON-YYYY HH24:MI:SS')
                           || CHR (13)
                          );
      UTL_SMTP.write_data (l_mail_conn, 'From: ' || lc_from || CHR (13));
      UTL_SMTP.write_data (l_mail_conn, 'Subject: ' || lc_subject || CHR (13));

      --UTL_SMTP.write_data(l_mail_conn, Chr(13));

      -- Checl all recipients
      FOR i IN 1 .. lc_to_tbl.COUNT
      LOOP
         UTL_SMTP.write_data (l_mail_conn,
                              'To: ' || lc_to_tbl (i) || CHR (13));
		 fnd_file.put_line(fnd_file.LOG,' #16.4 before end loop ');
      END LOOP;
         fnd_file.put_line(fnd_file.LOG,' #16.5 after for loop  ');
      IF lc_cc_all IS NOT NULL
      THEN
         FOR j IN 1 .. lc_cc_tbl.COUNT
         LOOP
            UTL_SMTP.write_data (l_mail_conn,
                                 'Cc: ' || lc_cc_tbl (j) || CHR (13)
                                );
         END LOOP;
      END IF;

      UTL_SMTP.write_data (l_mail_conn, ' ' || crlf);
      UTL_SMTP.write_data (l_mail_conn, p_text || crlf);
      UTL_SMTP.write_data (l_mail_conn, ' ' || crlf);
      UTL_SMTP.close_data (l_mail_conn);
      UTL_SMTP.quit (l_mail_conn);
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END send_notification;

   FUNCTION xx_preaudit_check (
      p_waiver       IN   VARCHAR2,
      p_waiver_apr   IN   VARCHAR2,
      p_pastatus     IN   VARCHAR2,
      p_pafadate     IN   DATE,
      p_plan_id      IN   NUMBER,
      p_ocr          IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      CURSOR c1
      IS
         SELECT pk1_value, fdc.user_name
           FROM fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = p_plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id;

      v_fad_form   VARCHAR2 (1) := 'N';
   BEGIN
      FOR cur IN c1
      LOOP
         IF cur.user_name = 'SR_Factory Add-Drop Forms'
         THEN
            v_fad_form := 'Y';
         END IF;
      END LOOP;

      IF p_waiver IS NOT NULL AND p_waiver_apr = 'Approved'
      THEN
         RETURN ('Y');
      END IF;

      IF (p_pastatus IS NULL AND p_pafadate IS NOT NULL AND v_fad_form = 'N'
         )
      THEN
         RETURN ('N');
      ELSIF (p_pastatus IS NULL AND p_pafadate IS NOT NULL
             AND v_fad_form = 'Y'
            )
      THEN
         RETURN ('N');
      ELSIF (    p_pastatus = 'Approved'
             AND p_pafadate IS NOT NULL
             AND v_fad_form = 'N'
            )
      THEN
         RETURN ('N');
      END IF;

      RETURN ('Y');
   END xx_preaudit_check;

   FUNCTION xx_init_audit (p_plan_id IN NUMBER, p_ocr IN NUMBER)
      RETURN VARCHAR2
   IS
      CURSOR c1
      IS
         SELECT pk1_value, fdc.user_name
           FROM fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = p_plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id;

      v_fad_form   VARCHAR2 (1) := 'N';
   BEGIN
      FOR cur IN c1
      LOOP
         IF cur.user_name = 'SR_Factory Add-Drop Forms'
         THEN
            v_fad_form := 'Y';
         END IF;
      END LOOP;

      IF v_fad_form = 'N'
      THEN
         RETURN ('N');
      ELSE
         RETURN ('Y');
      END IF;

      RETURN ('Y');
   END xx_init_audit;

   FUNCTION xx_cap_check (
      p_waiver       IN   VARCHAR2,
      p_waiver_apr   IN   VARCHAR2,
      p_castatus     IN   VARCHAR2,
      p_cafadate     IN   DATE
   )
      RETURN VARCHAR2
   IS
   BEGIN
      IF p_waiver IS NOT NULL AND p_waiver_apr = 'Approved'
      THEN
         RETURN ('Y');
      END IF;

      IF p_castatus IS NULL AND p_cafadate IS NOT NULL
      THEN
         RETURN ('N');
      END IF;

      RETURN ('Y');
   END xx_cap_check;

   FUNCTION xx_doc_check (
      p_type      IN   VARCHAR2,
      p_plan_id   IN   NUMBER,
      p_ocr       IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      CURSOR c1
      IS
         SELECT pk1_value, fdc.user_name
           FROM fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = p_plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id;

      v_fad_form   VARCHAR2 (1) := 'N';
      v_pot_form   VARCHAR2 (1) := 'N';
   BEGIN
      FOR cur IN c1
      LOOP
         IF cur.user_name = 'SR_Factory Add-Drop Forms'
         THEN
            v_fad_form := 'Y';
         ELSIF cur.user_name = 'SR_OD PO Terms'
         THEN
            v_pot_form := 'Y';
         END IF;
      END LOOP;

      IF p_type = 'NB'
      THEN
         IF v_pot_form = 'N'
         THEN
            RETURN ('N');
         ELSE
            RETURN ('Y');
         END IF;
      ELSIF p_type = 'DOM'
      THEN
         IF v_fad_form = 'N'
         THEN
            RETURN ('N');
         ELSE
            RETURN ('Y');
         END IF;
      ELSIF p_type = 'OTH'
      THEN
         IF (v_fad_form = 'N' OR v_pot_form = 'N')
         THEN
            RETURN ('N');
         ELSE
            RETURN ('Y');
         END IF;
      END IF;

      RETURN ('Y');
   END xx_doc_check;

   FUNCTION xx_vendsk_check (
      p_agent        IN   VARCHAR2,
      p_vtype        IN   VARCHAR2,
      p_waiver       IN   VARCHAR2,
      p_waiver_apr   IN   VARCHAR2,
      p_potadate     IN   DATE,
      p_ocr          IN   NUMBER,
      p_plan_id      IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      v_nb   VARCHAR2 (1);
   BEGIN
      IF p_waiver IS NOT NULL
      THEN
         IF     (   (p_vtype = 'DI' AND p_agent IN
                                                  ('LF', 'ODGSO', 'Domestic')
                    )
                 OR (p_vtype = 'Domestic' AND p_agent IN ('LF', 'ODGSO'))
                )
            AND p_waiver_apr = 'Approved'
         THEN
            v_nb := xx_doc_check ('NB', p_plan_id, p_ocr);

            IF v_nb = 'N' OR p_potadate IS NULL
            THEN                                  -- check all else condition
               RETURN ('N');
            ELSE
               RETURN ('Y');
            END IF;
         ELSIF     (   (    p_vtype = 'DI'
                        AND p_agent IN ('LF', 'ODGSO', 'Domestic')
                       )
                    OR (p_vtype = 'Domestic' AND p_agent IN ('LF', 'ODGSO'))
                   )
               AND p_waiver_apr = 'Denied'
         THEN
            v_nb := xx_doc_check ('OTH', p_plan_id, p_ocr);

            IF v_nb = 'N' OR p_potadate IS NULL
            THEN                                  -- check all else condition
               RETURN ('N');
            ELSE
               RETURN ('Y');
            END IF;
         ELSIF p_waiver_apr IS NULL
         THEN
            RETURN ('N');
         END IF;
      END IF;

      -- check this (looks like both are same)
      IF     p_waiver IS NULL
         AND (   (p_vtype = 'DI' AND p_agent IN ('LF', 'ODGSO', 'Domestic'))
              OR (p_vtype = 'Domestic' AND p_agent IN ('LF', 'ODGSO'))
             )
      THEN
         v_nb := xx_doc_check ('OTH', p_plan_id, p_ocr);

         IF v_nb = 'N'
         THEN
            RETURN ('N');
         END IF;
      END IF;

      RETURN ('Y');
   END xx_vendsk_check;

   FUNCTION xx_doc_exists (
      p_action       IN   VARCHAR2,
      p_agent        IN   VARCHAR2,
      p_vtype        IN   VARCHAR2,
      p_waiver       IN   VARCHAR2,
      p_waiver_apr   IN   VARCHAR2,
      p_potadate     IN   DATE,
      p_inactive     IN   DATE,
      p_reactive     IN   DATE,
      p_plan_id      IN   NUMBER,
      p_ocr          IN   NUMBER
   )
      RETURN VARCHAR2
   IS
      v_cnt        NUMBER;

      CURSOR c1
      IS
         SELECT pk1_value, fdc.user_name
           FROM fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = p_plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id;

      CURSOR c2
      IS
         SELECT pk1_value, fdc.user_name
           FROM fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = p_plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id
            AND fd.creation_date > p_inactive;

      v_fad_form   VARCHAR2 (1) := 'N';
      v_pot_form   VARCHAR2 (1) := 'N';
      v_rel_form   VARCHAR2 (1) := 'N';
      v_sgp_form   VARCHAR2 (1) := 'N';
      v_qac_form   VARCHAR2 (1) := 'N';
   BEGIN
      IF p_action = 'ACTIVATE'
      THEN
         FOR cur IN c1
         LOOP
            IF cur.user_name = 'SR_Factory Add-Drop Forms'
            THEN
               v_fad_form := 'Y';
            ELSIF cur.user_name = 'SR_OD PO Terms'
            THEN
               v_pot_form := 'Y';
            ELSIF cur.user_name = 'SR_Report Release Form'
            THEN
               v_rel_form := 'Y';
            ELSIF cur.user_name = 'SR_Supplier Guiding Principles'
            THEN
               v_sgp_form := 'Y';
            ELSIF cur.user_name = 'SR_QA Comply'
            THEN
               v_qac_form := 'Y';
            END IF;
         END LOOP;
      END IF;

      IF p_action = 'REACTIVATE'
      THEN
         FOR cur IN c2
         LOOP
            IF cur.user_name = 'SR_Factory Add-Drop Forms'
            THEN
               v_fad_form := 'Y';
            ELSIF cur.user_name = 'SR_OD PO Terms'
            THEN
               v_pot_form := 'Y';
            ELSIF cur.user_name = 'SR_Report Release Form'
            THEN
               v_rel_form := 'Y';
            ELSIF cur.user_name = 'SR_Supplier Guiding Principles'
            THEN
               v_sgp_form := 'Y';
            ELSIF cur.user_name = 'SR_QA Comply'
            THEN
               v_qac_form := 'Y';
            END IF;
         END LOOP;
      END IF;

      IF p_waiver IS NOT NULL
      THEN
         IF     (   (p_vtype = 'DI' AND p_agent IN
                                                  ('LF', 'ODGSO', 'Domestic')
                    )
                 OR (p_vtype = 'Domestic' AND p_agent IN ('LF', 'ODGSO'))
                )
            AND p_waiver_apr = 'Approved'
         THEN
            IF    (v_fad_form = 'N' OR v_pot_form = 'N' OR v_sgp_form = 'N'
                  )
               OR p_potadate IS NULL
            THEN
               RETURN ('N');
            END IF;
         ELSIF     (   (    p_vtype = 'DI'
                        AND p_agent IN ('LF', 'ODGSO', 'Domestic')
                       )
                    OR (p_vtype = 'Domestic' AND p_agent IN ('LF', 'ODGSO'))
                   )
               AND p_waiver_apr = 'Denied'
         THEN
            IF    (   v_fad_form = 'N'
                   OR v_pot_form = 'N'
                   OR v_rel_form = 'N'
                   OR v_sgp_form = 'N'
                   OR v_qac_form = 'N'
                  )
               OR p_potadate IS NULL
            THEN
               RETURN ('N');
            END IF;
         ELSIF     (   (    p_vtype = 'DI'
                        AND p_agent IN ('LF', 'ODGSO', 'Domestic')
                       )
                    OR (p_vtype = 'Domestic' AND p_agent IN ('LF', 'ODGSO'))
                   )
               AND p_waiver_apr IS NULL
         THEN
            IF    (   v_fad_form = 'N'
                   OR v_pot_form = 'N'
                   OR v_rel_form = 'N'
                   OR v_sgp_form = 'N'
                   OR v_qac_form = 'N'
                  )
               OR p_potadate IS NULL
            THEN
               RETURN ('N');
            END IF;
         END IF;
      END IF;

      IF p_vtype = 'Domestic' AND p_agent = 'Domestic'
      THEN
         IF (   v_fad_form = 'N'
             OR v_rel_form = 'N'
             OR v_sgp_form = 'N'
             OR v_qac_form = 'N'
            )
         THEN
            RETURN ('N');
         END IF;
      END IF;

      IF p_waiver IS NULL AND p_vtype <> 'Domestic' AND p_agent <> 'Domestic'
      THEN
         IF (   v_fad_form = 'N'
             OR v_pot_form = 'N'
             OR v_rel_form = 'N'
             OR v_sgp_form = 'N'
             OR v_qac_form = 'N'
            )
         THEN
            RETURN ('N');
         END IF;
      END IF;

      RETURN ('Y');
   END xx_doc_exists;

   PROCEDURE xx_status_upd (
      p_vend_id     IN   VARCHAR2,
      p_vend_name   IN   VARCHAR2,
      p_fact_id     IN   VARCHAR2,
      p_fact_name   IN   VARCHAR2,
      p_task        IN   VARCHAR2
   )
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('Task status update');
   END xx_status_upd;

   PROCEDURE xx_sc_process (
      x_errbuf    OUT NOCOPY   VARCHAR2,
      x_retcode   OUT NOCOPY   VARCHAR2
   )
   IS
      CURSOR c_inactive
      IS
         SELECT a.*
           FROM q_od_pb_sc_vendor_master_v a
          WHERE od_sc_vendor_status = 'Inactive'
            AND od_sc_inactive_date IS NOT NULL;

      CURSOR c_new_vendor
      IS
         SELECT a.*
           FROM q_od_pb_sc_vendor_master_v a
          WHERE od_sc_activation_date IS NULL AND od_sc_vendor_status IS NULL;

      CURSOR c_existing_vendors
      IS
         SELECT a.*
           FROM q_od_pb_sc_vendor_master_v a
          WHERE od_sc_activation_date IS NOT NULL
            AND od_sc_vendor_status = 'Active';

      CURSOR c_get_fad_form (p_ocr NUMBER)
      IS
         SELECT fl.file_name, fl.file_id, fl.file_data, fl.file_content_type,
                fdc.user_name
           FROM fnd_lobs fl,
                fnd_document_categories_tl fdc,
                fnd_documents fd,
                fnd_documents_tl fdt,
                fnd_document_datatypes fdd,
                fnd_attached_documents fad,
                qa_plans a
          WHERE a.NAME = 'OD_PB_SC_VENDOR_MASTER'
            AND fd.document_id = fdt.document_id
            AND fd.datatype_id = fdd.datatype_id
            AND fdd.user_name = 'File'
            AND fd.document_id = fad.document_id
            AND fdd.LANGUAGE = 'US'
            AND fad.entity_name = 'QA_RESULTS'
            AND fad.pk3_value = a.plan_id
            AND fad.pk1_value = p_ocr
            AND fdc.category_id = fd.category_id
            AND fl.file_id = fd.media_id  -- Modified for R12
            AND fdc.user_name = 'SR_Factory Add-Drop Forms';

      conn               UTL_SMTP.connection;
      v_email_list       VARCHAR2 (3000);
      v_cc_email_list    VARCHAR2 (3000);
      v_text             VARCHAR2 (3000);
      v_subject          VARCHAR2 (3000);
      v_region_contact   VARCHAR2 (250);
      v_region           VARCHAR2 (50);
      v_nextaudit_date   DATE;
      lc_send_mail       VARCHAR2 (1)
                                   := fnd_profile.VALUE ('XX_PB_SC_SEND_MAIL');
      v_errbuf           VARCHAR2 (2000);
      v_retcode          VARCHAR2 (50);
	  v_conc_req_id      VARCHAR2 (30):=fnd_global.conc_request_id; --added for defect #30098
   BEGIN

      assign_globals;      -- Defect 31287

      FOR cur IN c_inactive
      LOOP
         UPDATE qa_results
            SET character80 = NULL,
                character81 = NULL,
                character82 = NULL,
                character83 = NULL,
                character84 = NULL,
                character85 = NULL,
                character86 = NULL,
                character87 = NULL
          WHERE plan_id = cur.plan_id
            AND occurrence = cur.occurrence
            AND organization_id = cur.organization_id
            AND character6 IS NOT NULL;
      END LOOP;

      COMMIT;

      FOR cur IN c_new_vendor
      LOOP
         v_region := NULL;
         v_region_contact := NULL;

         IF cur.od_sc_vendor_number IS NULL
            OR cur.od_sc_vendor_status IS NULL
         THEN
            IF     cur.od_sc_audit_waiver IS NOT NULL
         --IN ('Self Assessment','National Brand','Corrugate','Shared Audit')
               AND NVL (cur.od_sc_nb_notify, 'N') = 'N'
            THEN
      fnd_file.put_line(fnd_file.LOG,'#A.1 od_sc_nb_notify '||cur.od_sc_nb_notify||' , '||' od_sc_audit_waiver: '||cur.od_sc_audit_waiver);
               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||
                     'Please review approval for '
                  || cur.od_sc_audit_waiver
                  || ' Waiver.'
                  || CHR (10);
               v_text :=
                     v_text
                  || 'Vendor Name is '
                  || cur.od_sc_vendor_name
                  || ' for '
                  || cur.od_sc_product
                  || '.';
               v_text := v_text || ' Website provided below';
               v_subject :=
                     'Request for '
                  || cur.od_sc_audit_waiver
                  || ' waiver :'
                  || cur.od_sc_vendor_name;

               IF lc_send_mail = 'Y'
               THEN
                  v_email_list := Gc_Notify_Contact2;  --'francia.pampillonia@officedepot.com';
                  v_cc_email_list := Gc_Sa_Compliance_Sender;--'SA-Compliance@officedepot.com';
               ELSE
                  v_email_list := Gc_Notify_Contact1; --'padmanaban.sanjeevi@officedepot.com';
                  v_cc_email_list := Gc_Notify_Contact3||':'||Gc_Notify_Contact2;
                   --  'sandy.stainton@officedepot.com:francia.pampillonia@officedepot.com';
               END IF;
		fnd_file.put_line(fnd_file.LOG,'#1 Request id: '||v_conc_req_id||' , '||' od_sc_audit_required: '||cur.od_sc_audit_required||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);
		fnd_file.put_line(fnd_file.LOG,'#1 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
        fnd_file.put_line(fnd_file.LOG,'#1 Text :'||v_text);
        fnd_file.put_line(fnd_file.LOG,'#1 Subject :'||v_subject);

               xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                          v_email_list,
                                                          v_cc_email_list,
                                                          v_text
                                                         );

               UPDATE qa_results
                  SET character87 = 'Y'
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
            END IF;
         END IF;

         IF cur.od_sc_vend_region IS NOT NULL
         THEN
            v_region := cur.od_sc_vend_region;
         END IF;

         IF cur.od_sc_europe_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_europe_rgn;
         END IF;

         IF cur.od_sc_eu_sub_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_eu_sub_rgn;
         END IF;

         IF cur.od_sc_mexico_region IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_mexico_region;
         END IF;

         IF cur.od_sc_mx_sub_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_mx_sub_rgn;
         END IF;

         IF cur.od_sc_asia_region IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_asia_region;
         END IF;

         IF cur.od_sc_as_sub_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_as_sub_rgn;
         END IF;

         IF cur.od_sc_eu_contact IS NOT NULL
         THEN
            v_region_contact := cur.od_sc_eu_contact || ':';
         END IF;

         IF cur.od_sc_mx_contact IS NOT NULL
         THEN
            v_region_contact :=
                              v_region_contact || cur.od_sc_mx_contact || ':';
         END IF;

         IF cur.od_sc_asia_contact IS NOT NULL
         THEN
            v_region_contact :=
                            v_region_contact || cur.od_sc_asia_contact || ':';
         END IF;

         -- Checking for Pre-Audit completion
         IF cur.od_sc_vendor_number IS NULL
            AND cur.od_sc_vendor_status IS NULL
         THEN
            IF (   (    cur.od_sc_zt_status = 'Approved'
                    AND cur.od_sc_fzt_aprvl_d IS NOT NULL
                   )
                OR (    cur.od_sc_zt_status = 'Waived'
                    AND cur.od_sc_audit_agent = 'Domestic'
                    AND cur.od_sc_audit_waiver IS NULL
                   )
                OR (    cur.od_sc_audit_waiver IN
                           ('National Brand',
                            'Self Assessment',
                            'Corrugate',
                            'Shared Audit',
					 'Certification',
					 'Collaboration'
                           )
                    AND cur.od_sc_audit_waiver_status = 'Denied'
                   )
               )
            THEN
               IF NVL (cur.od_sc_initstr_notify, 'N') = 'N'
               THEN
                  IF lc_send_mail = 'Y'
                  THEN
                     v_email_list :=Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                    --    'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
                     v_cc_email_list :=V_Region_Contact || Gc_Sa_Compliance_Sender||':'||Gc_Aud_Result_Notify;
                       /*    v_region_contact
                        || 'SA-Compliance@officedepot.com:Sabrina.hernandezcruz@officedepot.com';*/
                  ELSE
                     V_Email_List :=Gc_Notify_Contact1||':'||Gc_Notify_Contact2;
                      --  'padmanaban.sanjeevi@officedepot.com:francia.pampillonia@officedepot.com';
                     v_cc_email_list := Gc_Notify_Contact3;-- 'sandy.stainton@officedepot.com';
                  END IF;
                  fnd_file.put_line(fnd_file.LOG,'#A.2 od_sc_initstr_notify '||cur.od_sc_initstr_notify);
				  fnd_file.put_line(fnd_file.LOG,'#A.2 od_sc_zt_status '||cur.od_sc_zt_status);
				  fnd_file.put_line(fnd_file.LOG,'#A.2 od_sc_fzt_aprvl_d '||cur.od_sc_fzt_aprvl_d);
                  v_subject :=
                        cur.od_sc_vendor_name
                     || ' / '
                     || v_region
                     || ' / '
                     || cur.od_sc_audit_agent
                     || ' /  Pre-Audit Status Notification';

                  v_text := null;
                  v_text := v_text||chr(13);
                  v_text := v_text||
                        'This is to inform you that the Pre-audit CAP for '
                     || cur.od_sc_vendor_name
                     || ' / '
                     || cur.od_sc_factory_name
                     || ' has been completed'
                     || CHR (10);
                  v_text :=
                        v_text
                     || 'and approved on '
                     || TO_CHAR (cur.od_sc_fzt_aprvl_d)
                     || ' with a Pre-audit result of '
                     || cur.od_sc_preaudt_result
                     || '.'
                     || CHR (10);
                  v_text :=
                        v_text
                     || 'The new vendor setup forms have been uploaded in the Social Compliance Oracle Module.'
                     || CHR (10);
                  v_text := v_text || CHR (10);
                  v_text :=
                        v_text
                     || 'The ODUS merchant is '
                     || cur.od_sc_merchant
                     || ' , product type is '
                     || cur.od_sc_product
                     || '.'
                     || CHR (10);
                  v_text := v_text || CHR (10);
                  v_text :=
                        v_text
                     || 'UL RS Audit has been initiated as '
                     || cur.od_sc_audit_required
                     || '.'
                     || CHR (10);

                  IF cur.od_sc_zt_status = 'Approved'

                  THEN
				 fnd_file.put_line(fnd_file.LOG,'#1.1 Request id: '||v_conc_req_id||' , '||'od_sc_zt_status: '||cur.od_sc_zt_status||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);
		         fnd_file.put_line(fnd_file.LOG,'#1.1 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                 fnd_file.put_line(fnd_file.LOG,'#1.1 Text :'||v_text);
                 fnd_file.put_line(fnd_file.LOG,'#1.1 Subject :'||v_subject);
                     xx_pa_pb_compliance_pkg.send_notification
                                                            (v_subject,
                                                             v_email_list,
                                                             v_cc_email_list,
                                                             v_text
                                                            );
                  END IF;

                  -- Notification of STR to initiate audit 1st Mail
                  IF cur.od_sc_audit_required IN ('Regular', 'Rush')
                  THEN
                     IF lc_send_mail = 'Y'
                     THEN
                        v_email_list :=Gc_Audit_Regrush_Notify ;--'OfficeDepot@ul.com';
                        v_cc_email_list :=Gc_Sa_Compliance_Sender||';'||Gc_Notify_Contact2||';'||Gc_Notify_Contact3;
                          -- 'SA-Compliance@officedepot.com;francia.pampillonia@officedepot.com;sandy.stainton@officedepot.com'; --Replaced Sabrina.hernandezcruz@officedepot.com as per defect # 30917 ;
				     fnd_file.put_line(fnd_file.LOG,'#1 Request id: '||v_conc_req_id||' , '||' od_sc_audit_required: '||cur.od_sc_audit_required||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
					 fnd_file.put_line(fnd_file.LOG,'#1 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                     fnd_file.put_line(fnd_file.LOG,'#1 Text :'||v_text);
                     fnd_file.put_line(fnd_file.LOG,'#1 Subject :'||v_subject);
					 fnd_file.put_line(fnd_file.LOG,'#1 od_sc_audit_required'||cur.od_sc_audit_required);
                     ELSE
                        v_email_list :=Gc_Notify_Contact1||';'||Gc_Notify_Contact2;
                          -- 'padmanaban.sanjeevi@officedepot.com;francia.pampillonia@officedepot.com';
                        v_cc_email_list :=Gc_Notify_Contact3;-- 'sandy.stainton@officedepot.com';
                     END IF;

                     --- Added cur.od_sc_factory_name by Rama for 11.3
                     v_subject :=
                           cur.od_sc_vendor_name
                        || ' / '
                        || cur.od_sc_factory_name
                        || ' / '
                        || v_region
                        || ' / '
                        || cur.od_sc_audit_agent
                        || ' / UL RS Audit Request';

                     v_text := null;
                     v_text := v_text||chr(13);
                     v_text := v_text||'UL RS Team,' || CHR (10);
                     v_text :=
                           v_text
                        || 'Please initiate and/or confirm initiation of the UL RS audit for '
                        || cur.od_sc_vendor_name
                        || '.'
                        || CHR (10);
                     v_text :=
                           v_text
                        || 'The Factory Declaration Add/Drop form is attached.'
                        || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text :=
                        v_text || 'AGENT: ' || cur.od_sc_audit_agent  --defect 21138 changes
                        || CHR (10);
                     v_text :=
                           v_text
                        || 'AUDIT TYPE: '   --defect 21138 changes
                        || cur.od_sc_audit_required
                        || CHR (10);
                     v_text :=
                              v_text || 'REGION(S): ' || v_region || CHR (10);
                     v_text :=
                         v_text || 'OPEN ACCOUNT: ' || cur.od_sc_payment_retainer;
                     -- defect 21138 changes start
                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR NAME: ' || cur.OD_SC_VENDOR_NAME;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR ID: ' || cur.OD_SC_VENDOR_NUMBER;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR ADDRESS: ' || cur.OD_SC_VEND_ADDRESS;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR CONTACT NAME ' || '&' || ' TITLE: ' || cur.OD_SC_VEND_CONT_NAME;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR EMAIL: ' || cur.OD_SC_VEND_EMAIL;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR PHONE: ' || cur.OD_SC_VEND_PHONE;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'VENDOR FAX: ' || cur.OD_SC_VEND_FAX;

                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY NAME: ' || cur.OD_SC_FACTORY_NAME;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY ID: ' || cur.OD_SC_FACTORY_NUMBER;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY ADDRESS: ' || cur.OD_SC_FACTORY_ADDRESS;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY CONTACT NAME ' || '&' || ' TITLE: ' || cur.OD_SC_FACT_CONT_NAME;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY EMAIL: ' || cur.OD_SC_FACTORY_EMAIL;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY PHONE: ' || cur.OD_SC_FACTORY_PHONE;
                     v_text := v_text || CHR (10);
                     v_text :=
                              v_text || 'FACTORY FAX: ' || cur.OD_SC_FACTORY_FAX;
                     -- defect 21138 changes end
                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text := v_text || 'OFFICE DEPOT INC.' || CHR (10);
                     v_text := v_text || 'Social Compliance Team' || CHR (10);
                     v_text :=
                         v_text || Gc_Sa_Compliance_Sender --'SA-Compliance@officedepot.com'
                                || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text :=
                           v_text
                        || 'Please do not reply to this email address. Send correspondence to ' ||Gc_Sa_Compliance_Sender --SA-Compliance@officedepot.com'
                        || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text := v_text || CHR (10);
                     v_text :=
                           v_text
                        || 'NOTICE. This message contains information which is confidential and the copyright of our company or a third party. If you are not the intended recipient of this message please delete it and destroy all copies. If you are the intended recipient of this message you should not disclose or distribute this message to third parties without the consent of Office Depot, Inc.';

					 fnd_file.put_line(fnd_file.LOG,'#1.2 Request id: '||v_conc_req_id||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
					 fnd_file.put_line(fnd_file.LOG,'#1.2 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                     fnd_file.put_line(fnd_file.LOG,'#1.2 Text :'||v_text);
                     fnd_file.put_line(fnd_file.LOG,'#1.2 Subject :'||v_subject);
                     conn :=
                        xx_pa_pb_mail.begin_mail
                               (sender             => Gc_Sa_Compliance_Sender, --'SA-Compliance@officedepot.com'
                                recipients         => v_email_list,
                                cc_recipients      => v_cc_email_list,
                                subject            => v_subject,
                                mime_type          => xx_pa_pb_mail.multipart_mime_type
                               );

                     FOR cf IN c_get_fad_form (cur.occurrence)
                     LOOP
                        xx_pa_pb_mail.xx_attch_doc (conn,
                                                    cf.file_name,
                                                    cf.file_data,
                                                    cf.file_content_type
                                                   );
					 fnd_file.put_line(fnd_file.LOG,'#a.3 after Attach doc :');
                     END LOOP;

                     xx_pa_pb_mail.end_attachment (conn => conn);
                     xx_pa_pb_mail.attach_text (conn           => conn,
                                                DATA           => v_text --, Defect 31287
                                                --mime_type      => 'multipart/html'
                                               );
					 fnd_file.put_line(fnd_file.LOG,'#a.3 after Attach text :');
                     xx_pa_pb_mail.end_mail (conn => conn);

                     UPDATE qa_results
                        SET character80 = 'Y',        --  OD_SC_INITSTR_NOTIFY
                            character63 =
                               TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                                                     -- STR Audit Request Date
                      WHERE plan_id = cur.plan_id
                        AND occurrence = cur.occurrence
                        AND organization_id = cur.organization_id;

                     COMMIT;
                  END IF;
                 --     IF cur.OD_SC_AUDIT_REQUIRED IN ('Regular','Rush') THEN
               END IF;        --IF  NVL(cur.OD_SC_INITSTR_NOTIFY,'N')='N' THEN
            END IF;
--- IF cur.OD_SC_ZT_STATUS='Approved' AND cur.OD_SC_FZT_APRVL_D IS NOT NULL THEN
         END IF;
  --IF cur.OD_SC_VENDOR_NUMBER IS NULL OR cur.OD_SC_VENDOR_STATUS IS NULL THEN

         -- Vendor Payment not received after the audit is requested
         IF     cur.od_sc_initstr_notify = 'Y'
            AND NVL (cur.od_sc_vendpay_notify, 'N') = 'N'
            AND cur.od_sc_vendpay_rcvd_d IS NULL
            AND cur.od_sc_audit_required IN ('Regular', 'Rush')
            AND cur.od_sc_straudt_req_d IS NOT NULL
            AND cur.od_sc_payment_retainer = 'N'
            AND cur.od_sc_activation_date IS NULL
            AND (SYSDATE - cur.od_sc_straudt_req_d) > 13
         THEN
            IF lc_send_mail = 'Y'
            THEN
               v_email_list := Gc_Sa_Compliance_Sender;-- 'SA-compliance@officedepot.com';
            ELSE
               v_email_list :=Gc_Notify_Contact1 ; -- 'padmanaban.sanjeevi@officedepot.com';
               v_cc_email_list :=Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
               --   'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
            END IF;
           fnd_file.put_line(fnd_file.LOG,'#B.1 od_sc_initstr_notify :'||cur.od_sc_initstr_notify||' , '||' od_sc_vendpay_notify: '||cur.od_sc_vendpay_notify);
		   fnd_file.put_line(fnd_file.LOG,'#B.1 od_sc_vendpay_rcvd_d :'||cur.od_sc_vendpay_rcvd_d||' , '||' od_sc_audit_required: '||cur.od_sc_audit_required);
		   fnd_file.put_line(fnd_file.LOG,'#B.1 od_sc_straudt_req_d  :'||cur.od_sc_straudt_req_d||' ,  '||' od_sc_payment_retainer: '||cur.od_sc_payment_retainer);
		   fnd_file.put_line(fnd_file.LOG,'#B.1 od_sc_activation_date  :'||cur.od_sc_activation_date);
            v_subject :=
                  'ALERT New Vendor Payment Not Received for UL RS Invoice / '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || v_region
               || ' / '
               || cur.od_sc_audit_agent
               || ' / Dept : '
               || cur.od_sc_department;

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||'Social Accountability Team,' || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'To date UL RS has not received payment for the audit requested on '
               || TO_CHAR (cur.od_sc_straudt_req_d)
               || '.'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Please follow up with the merchant and/or agent to assist with collection.';

            UPDATE qa_results
               SET character81 = 'Y'                  --  OD_SC_VENDPAY_NOTIFY
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
			         fnd_file.put_line(fnd_file.LOG,'#1.4 Request id: '||v_conc_req_id||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
					 fnd_file.put_line(fnd_file.LOG,'#1.4 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                     fnd_file.put_line(fnd_file.LOG,'#1.4 Text :'||v_text);
                     fnd_file.put_line(fnd_file.LOG,'#1.4 Subject :'||v_subject);
            xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      );
         END IF;                                                             --

         -- Vendor Payment Received, STR audit not scheduled_Revised  -- new logic per sandy 2nd Mail
         IF     NVL (cur.od_sc_regrush_notify, 'N') = 'N'
            AND cur.od_sc_activation_date IS NULL
            AND cur.od_sc_vendpay_rcvd_d IS NOT NULL
            AND NVL (cur.od_sc_payment_retainer, 'N') = 'N'
            AND cur.od_sc_straudt_schd_d IS NULL
            AND (   (    cur.od_sc_audit_required = 'Regular'
                     AND (SYSDATE - cur.od_sc_vendpay_rcvd_d) > 14
                    )
                 OR (    cur.od_sc_audit_required = 'Rush'
                     AND (SYSDATE - cur.od_sc_vendpay_rcvd_d) > 5
                    )
                )
         THEN
            IF lc_send_mail = 'Y'
            THEN
               v_email_list :=Gc_Audit_Regrush_Notify;--'OfficeDepot@ul.com';
               v_cc_email_list := NULL;
			         fnd_file.put_line(fnd_file.LOG,'#2 Request id :'||v_conc_req_id||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);
					 fnd_file.put_line(fnd_file.LOG,'#2 Plan name: '||cur.plan_name||' ,  '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                     fnd_file.put_line(fnd_file.LOG,'#2 Text :'||v_text);
                     fnd_file.put_line(fnd_file.LOG,'#2 Subject :'||v_subject);
					 fnd_file.put_line(fnd_file.LOG,'#2 od_sc_regrush_notify :'||cur.od_sc_initstr_notify||' , '||'od_sc_activation_date:  '||cur.od_sc_activation_date);
                     fnd_file.put_line(fnd_file.LOG,'#2 od_sc_vendpay_rcvd_d :'||cur.od_sc_vendpay_rcvd_d||' , '||'od_sc_payment_retainer: '||cur.od_sc_payment_retainer);
					 fnd_file.put_line(fnd_file.LOG,'#2 od_sc_audit_required :'||cur.od_sc_audit_required||' , '||'od_sc_straudt_schd_d:   '||cur.od_sc_straudt_schd_d);

            ELSE
               v_email_list := Gc_Notify_Contact1; --'padmanaban.sanjeevi@officedepot.com';
               v_cc_email_list :=Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                -- 'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
            END IF;

            v_subject :=
                  'ALERT Vendor Payment has been received for the UL RS required audit. Audit to be scheduled./ '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || v_region
               || ' / '
               || cur.od_sc_audit_agent;

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||'UL RS Team,' || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'UL RS has confirmed payment receipt from '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || cur.od_sc_audit_agent
               || '.'
               || CHR (10);
            v_text :=
                  v_text
               || 'However, Office Depot has not received confirmation that the audit has been scheduled.'
               || CHR (10);
            v_text :=
                  v_text
               || 'Please advise when this audit will be scheduled or reason(s) for the delay.'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || 'OFFICE DEPOT INC.' || CHR (10);
            v_text := v_text || 'Social Compliance Team' || CHR (10);
            v_text := v_text || Gc_Sa_Compliance_Sender--'SA-Compliance@officedepot.com'
                             || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Please do not reply to this email address. Send correspondence to '||Gc_Sa_Compliance_Sender--SA-Compliance@officedepot.com'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'NOTICE. This message contains information which is confidential and the copyright of our company or a third party. If you are not the intended recipient of this message please delete it and destroy all copies. If you are the intended recipient of this message you should not disclose or distribute this message to third parties without the consent of Office Depot, Inc.';

            UPDATE qa_results
               SET character82 = 'Y'                  --  OD_SC_REGRUSH_NOTIFY
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
			         fnd_file.put_line(fnd_file.LOG,'#2 Request id :'||v_conc_req_id||' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);
					 fnd_file.put_line(fnd_file.LOG,'#2 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                     fnd_file.put_line(fnd_file.LOG,'#2 Text :'||v_text);
                     fnd_file.put_line(fnd_file.LOG,'#2 Subject :'||v_subject);
            xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      );
         END IF;

         IF     NVL (cur.od_sc_regrush_notify, 'N') = 'N'
            AND cur.od_sc_activation_date IS NULL
            AND cur.od_sc_vendpay_rcvd_d IS NULL
            AND cur.od_sc_payment_retainer = 'Y'
            AND cur.od_pb_payrtn_aprvl_date IS NOT NULL
            AND cur.od_sc_straudt_schd_d IS NULL
            AND (   (    cur.od_sc_audit_required = 'Regular'
                     AND (SYSDATE - cur.od_pb_payrtn_aprvl_date) > 14
                    )
                 OR (    cur.od_sc_audit_required = 'Rush'
                     AND (SYSDATE - cur.od_pb_payrtn_aprvl_date) > 5
                    )
                )
         THEN
            IF lc_send_mail = 'Y'   -- 3rd Mail
            THEN
               v_email_list :=Gc_Audit_Regrush_Notify ; --'OfficeDepot@ul.com';
               v_cc_email_list := NULL;
			         fnd_file.put_line(fnd_file.LOG,'#3 Request id :'||v_conc_req_id||' , '||' od_sc_audit_required :'||cur.od_sc_audit_required||' , '||' Vendor Name :'||cur.od_sc_vendor_name||' , '||'Factory Name :'||cur.od_sc_factory_name);
					 fnd_file.put_line(fnd_file.LOG,'#3 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
                     fnd_file.put_line(fnd_file.LOG,'#3 Text :'||v_text);
                     fnd_file.put_line(fnd_file.LOG,'#3 Subject :'||v_subject);
					 fnd_file.put_line(fnd_file.LOG,'#3 od_sc_regrush_notify :'||cur.od_sc_regrush_notify||' , '||'od_sc_activation_date:   '||cur.od_sc_activation_date);
					 fnd_file.put_line(fnd_file.LOG,'#3 od_sc_payment_retainer :'||cur.od_sc_payment_retainer||' , '||'od_pb_payrtn_aprvl_date: '||cur.od_pb_payrtn_aprvl_date);
					 fnd_file.put_line(fnd_file.LOG,'#3 od_sc_straudt_schd_d :'||cur.od_sc_straudt_schd_d||' , '||'od_sc_audit_required:'||cur.od_sc_audit_required);
            ELSE
               v_email_list := Gc_Notify_Contact1;
               ---'padmanaban.sanjeevi@officedepot.com';
               v_cc_email_list :=Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                 -- 'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
            END IF;

            v_subject :=
                  'ALERT Payment Retainer has been approved for the UL RS required audit. Audit to be scheduled./ '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || v_region
               || '/ '
               || cur.od_sc_audit_agent;

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||'UL RS Team,' || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Office Depot has approved the retainer as payment for the audit of '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || cur.od_sc_audit_agent
               || '.'
               || CHR (10);
            v_text :=
                  v_text
               || 'However, Office Depot has not received confirmation that the audit has been scheduled.'
               || CHR (10);
            v_text :=
                  v_text
               || 'Please advise when this audit will be scheduled or reason(s) for the delay.'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || 'OFFICE DEPOT INC.' || CHR (10);
            v_text := v_text || 'Social Compliance Team' || CHR (10);
            v_text := v_text || Gc_Sa_Compliance_Sender --'SA-Compliance@officedepot.com'
                             || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Please do not reply to this email address. Send correspondence to '||Gc_Sa_Compliance_Sender--SA-Compliance@officedepot.com'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'NOTICE. This message contains information which is confidential and the copyright of our company or a third party. If you are not the intended recipient of this message please delete it and destroy all copies. If you are the intended recipient of this message you should not disclose or distribute this message to third parties without the consent of Office Depot, Inc.';

            UPDATE qa_results
               SET character82 = 'Y'                  --  OD_SC_REGRUSH_NOTIFY
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
			fnd_file.put_line(fnd_file.LOG,'#4 Request id :'||v_conc_req_id||' , '||' od_sc_audit_required :'||cur.od_sc_audit_required||' , '||' Vendor Name :'||cur.od_sc_vendor_name||' , '||'Factory Name :'||cur.od_sc_factory_name);	--	v_conc_req_id
            fnd_file.put_line(fnd_file.LOG,'#4 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
		    fnd_file.put_line(fnd_file.LOG,'#4 Text :'||v_text);
            fnd_file.put_line(fnd_file.LOG,'#4 Subject :'||v_subject);
            xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      );
         END IF;

         IF (    cur.od_sc_str_audit_result IS NOT NULL
             AND cur.od_sc_straudt_schd_d IS NOT NULL
            )
         THEN
            IF     NVL (cur.od_sc_audreszt_notify, 'N') = 'N'
               AND cur.od_sc_str_audit_result IN
                                           ('Denied Entry', 'Zero Tolerance')
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list :=Gc_Aud_Result_Notify ||':'||Gc_Sa_Compliance_Sender;
                    -- 'Sabrina.hernandezcruz@officedepot.com:SA-Compliance@officedepot.com';
               ELSE
                  v_email_list :=Gc_Notify_Contact2;
                   -- 'padmanaban.sanjeevi@officedepot.com';
                  v_cc_email_list := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                   --  'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
               END IF;

               IF cur.od_sc_str_audit_result = 'Zero Tolerance'
               THEN
                  v_subject := 'Zero Tolerance Notification for ';
               ELSIF cur.od_sc_str_audit_result = 'Denied Entry'
               THEN
                  v_subject := 'Denied Entry Notification for ';
               END IF;
			   fnd_file.put_line(fnd_file.LOG,'#C.1 od_sc_str_audit_result:'||cur.od_sc_str_audit_result||' , '||'od_sc_straudt_schd_d:   '||cur.od_sc_straudt_schd_d);
               fnd_file.put_line(fnd_file.LOG,'#C.1 od_sc_audreszt_notify:'||cur.od_sc_audreszt_notify);
               v_subject :=
                     v_subject
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' / '
                  || cur.od_sc_audit_agent
                  || ' / '
                  || v_region;

               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||
                     'The audit for '
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' was conducted on '
                  || TO_CHAR (cur.od_sc_straudt_schd_d)
                  || '.'
                  || CHR (10);
               v_text :=
                     v_text
                  || 'The facility is graded as '
                  || cur.od_sc_str_audit_result
                  || ' based on the current assessment.';

               UPDATE qa_results
                  SET character83 = 'Y'              --  OD_SC_AUDRESZT_NOTIFY
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
			   fnd_file.put_line(fnd_file.LOG,'#5 Request id :'||v_conc_req_id||' , '||' od_sc_audit_required :'||cur.od_sc_audit_required||' , '||' Vendor Name :'||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
               fnd_file.put_line(fnd_file.LOG,'#5 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
			   fnd_file.put_line(fnd_file.LOG,'#5 Text: '||v_text);
               fnd_file.put_line(fnd_file.LOG,'#5 Subject: '||v_subject);
               xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                          v_email_list,
                                                          v_cc_email_list,
                                                          v_text
                                                         );
            END IF;

            IF cur.od_sc_req_audit_date IS NULL
            THEN
               IF cur.od_sc_str_audit_result IN ('Denied Entry')
               THEN
                  v_nextaudit_date := cur.od_sc_straudt_schd_d + 30;
               ELSIF cur.od_sc_str_audit_result = 'Needs Improvement'
               THEN
                  v_nextaudit_date := cur.od_sc_straudt_schd_d + 180;
               ELSIF cur.od_sc_str_audit_result IN
                                    ('Satisfactory', 'Minor Progress Needed')
               THEN
                  v_nextaudit_date := cur.od_sc_straudt_schd_d + 365;
               END IF;

               UPDATE qa_results
                  SET character68 =
                         TO_CHAR (v_nextaudit_date, 'YYYY/MM/DD')
                                                      --  OD_SC_REQ_AUDIT_DATE
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
            -- reset the flags for recaudit,cap,  -- pending
            END IF;
         END IF;
--     IF (cur.OD_SC_STR_AUDIT_RESULT IS NOT NULL AND cur.OD_SC_STRAUDT_SCHD_D IS NOT NULL) THEN

         IF     cur.od_sc_str_audit_result IS NOT NULL
            AND cur.od_sc_straudt_schd_d IS NOT NULL
            AND cur.od_sc_str_audit_result = 'Zero Tolerance'
            AND cur.od_sc_req_audit_date IS NULL
            AND cur.od_sc_srtaudt_us_apr_d IS NOT NULL
         THEN
            v_nextaudit_date := cur.od_sc_srtaudt_us_apr_d + 30;

            UPDATE qa_results
               SET character68 =
                      TO_CHAR (v_nextaudit_date, 'YYYY/MM/DD')
                                                      --  OD_SC_REQ_AUDIT_DATE
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
         END IF;

         IF     cur.od_sc_straudt_cap_status = 'Complete'
            AND cur.od_sc_cap_final_approver IS NOT NULL
            AND cur.od_sc_srtaudt_us_apr_d IS NOT NULL
            --AND cur.OD_SC_FQA_APRVL_D IS NOT NULL     -- commented by Rama 11.3
            AND cur.od_sc_activation_date IS NULL
         THEN
            IF NVL (cur.od_sc_cap_notify, 'N') = 'N'
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list := Gc_Sa_Compliance_Sender; --'SA-Compliance@officedepot.com';
                  v_cc_email_list := NULL;
               ELSE
                v_email_list    :=Gc_Notify_Contact1 ;-- 'padmanaban.sanjeevi@officedepot.com';
                 V_Cc_Email_List := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                -- 'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
        END IF;
            fnd_file.put_line(fnd_file.LOG,'#D.1 od_sc_cap_notify:'||cur.od_sc_cap_notify);
               v_subject :=
                     'CAP APPROVED_ACTIVATION REQUEST/ '
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' / '
                  || cur.od_sc_audit_agent
                  || ' / '
                  || v_region;

               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||
                     'The CAP for '
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || '  '
                  || cur.od_sc_vendor_number
                  || 'has been approved.'
                  || CHR (10);
               -- v_text:=v_text||'The FQA has been approved on '||TO_CHAR(cur.OD_SC_FQA_APRVL_D)||'.'||chr(10);
               -- v_text:=v_text||chr(10);
                --- added the following line by Rama for 11.3
               v_text :=
                     v_text
                  || 'The FQA must be approved before the Vendor ID is activated.'
                  || CHR (10);
               v_text := v_text || CHR (10);
               v_text := v_text || 'The vendor is ready to be activated.';

               UPDATE qa_results
                  SET character85 = 'Y'                    -- OD_SC_CAP_NOTIFY
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
			   fnd_file.put_line(fnd_file.LOG,'#5.1 Request id :'||v_conc_req_id||' , '||' Vendor Name :'||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
               fnd_file.put_line(fnd_file.LOG,'#5.1 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
			   fnd_file.put_line(fnd_file.LOG,'#5.1 Text: '||v_text);
               fnd_file.put_line(fnd_file.LOG,'#5.1 Subject: '||v_subject);
               xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                          v_email_list,
                                                          v_cc_email_list,
                                                          v_text
                                                         );
            END IF;
         END IF;

         IF     cur.od_sc_vend_initiate = 'Yes'
            AND  cur.od_sc_vendor_number IS NULL
            -- the following line added by Rama for 11.3
            AND cur.od_sc_vend_region IS NOT NULL
            AND (   (    cur.od_sc_vend_type = 'DI'
                     AND cur.od_sc_audit_agent IN ('LF', 'ODGSO', 'Domestic')
                    )
                 OR (    cur.od_sc_vend_type = 'Domestic'
                     AND cur.od_sc_audit_agent IN ('LF', 'ODGSO')
                    )
                )
         THEN
            IF NVL (cur.od_sc_vendsk_notify, 'N') = 'N'
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list := gc_Vendsk_Notify||';'||Gc_Aud_Result_Notify||';' ||Gc_Notify_Contact3||';'||Gc_Notify_Contact2;
                   --  'VendorDesk@officedepot.com;Sabrina.hernandezcruz@officedepot.com;sandy.stainton@officedepot.com;francia.pampillonia@officedepot.com';
                  v_cc_email_list := Gc_Sa_Compliance_Sender;--'SA-Compliance@officedepot.com';

               ELSE
                  v_email_list :=Gc_Notify_Contact1||';'||Gc_Notify_Contact2||';'||Gc_Notify_Contact3;
                   --  'padmanaban.sanjeevi@officedepot.com;sandy.stainton@officedepot.com;francia.pampillonia@officedepot.com';
                  v_cc_email_list := NULL;
               END IF;
                  fnd_file.put_line(fnd_file.LOG,'#D.2 od_sc_vendsk_notify:'||cur.od_sc_vendsk_notify);
               v_subject :=
                     'New Vendor Request for '
                  || cur.od_sc_vendor_name
                  || '/'
                  || cur.od_sc_factory_name;

               v_text := null;
               v_text := v_text||chr(13);
               v_text := 'Social Compliance,' || CHR (10);
               v_text :=
                     v_text
                  || 'Please approve the new vendor request form for '
                  || cur.od_sc_vendor_name
                  || '/'
                  || cur.od_sc_factory_name
                  || '.'
                  || CHR (10);
               v_text := v_text || CHR (10);
               v_text := v_text || 'Vendor Desk,' || CHR (10);
               v_text :=
                     v_text
                  || 'Please process the new vendor request form for '
                  || cur.od_sc_vendor_name
                  || '/'
                  || cur.od_sc_factory_name
                  || '.'
                  || CHR (10);
               v_text := v_text || 'The required documents are attached.';


               -- Pending Vendor Desk form attachment
               UPDATE qa_results
                  SET character86 = 'Y'                 -- OD_SC_VENDSK_NOTIFY
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
			     fnd_file.put_line(fnd_file.LOG,'#5.4 Request id: '||v_conc_req_id||' , '||' od_sc_vend_initiate :'||cur.od_sc_vend_initiate||' , '||' Vendor Name :'||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name||' , '||' od_sc_vendsk_notify :'||cur.od_sc_vendsk_notify);	--	v_conc_req_id
			   fnd_file.put_line(fnd_file.LOG,'#5.4 vendor number :'||cur.od_sc_vendor_number||' , '||' od_sc_vend_region :'||cur.od_sc_vend_region||' , '||' od_sc_vend_type :'||cur.od_sc_vend_type||' , '||'od_sc_audit_agent:'||cur.od_sc_audit_agent);	--	v_conc_req_id
			   fnd_file.put_line(fnd_file.LOG,'#5.4 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
			   fnd_file.put_line(fnd_file.LOG,'#5.4 Text: '||v_text);
               fnd_file.put_line(fnd_file.LOG,'#5.4 Subject: '||v_subject);
               xx_pa_pb_compliance_pkg.vend_request (v_subject,
                                                     v_email_list,
                                                     v_cc_email_list,
                                                     v_text,
                                                     cur.plan_id,
                                                     cur.occurrence
                                                    );
            END IF;
         END IF;
      END LOOP;                                             -- FOr new vendors

      FOR cur IN c_existing_vendors
      LOOP
         v_region := NULL;
         v_region_contact := NULL;

         IF cur.od_sc_vend_region IS NOT NULL
         THEN
            v_region := cur.od_sc_vend_region;
         END IF;

         IF cur.od_sc_europe_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_europe_rgn;
         END IF;

         IF cur.od_sc_eu_sub_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_eu_sub_rgn;
         END IF;

         IF cur.od_sc_mexico_region IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_mexico_region;
         END IF;

         IF cur.od_sc_mx_sub_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_mx_sub_rgn;
         END IF;

         IF cur.od_sc_asia_region IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_asia_region;
         END IF;

         IF cur.od_sc_as_sub_rgn IS NOT NULL
         THEN
            v_region := v_region || ' / ' || cur.od_sc_as_sub_rgn;
         END IF;

         IF cur.od_sc_eu_contact IS NOT NULL
         THEN
            v_region_contact := cur.od_sc_eu_contact || ':';
         END IF;

         IF cur.od_sc_mx_contact IS NOT NULL
         THEN
            v_region_contact :=
                              v_region_contact || cur.od_sc_mx_contact || ':';
         END IF;

         IF cur.od_sc_asia_contact IS NOT NULL
         THEN
            v_region_contact :=
                            v_region_contact || cur.od_sc_asia_contact || ':';
         END IF;

         IF     cur.od_sc_req_audit_date IS NOT NULL AND cur.OD_SC_AUDIT_WAIVER IS NULL  -- Modified for R12
            AND NVL (cur.od_sc_recaudit_notify, 'N') = 'N'
         THEN
            IF (cur.od_sc_req_audit_date - SYSDATE) < 7  -- 4th Mail
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list := Gc_Audit_Regrush_Notify ;--'OfficeDepot@ul.com';
                  v_cc_email_list :=
                        v_region_contact ||Gc_Audit_Regrush_Notify ||':'||Gc_Sa_Compliance_Sender ;
                   --  || 'OfficeDepot@ul.com:SA-Compliance@officedepot.com';

              ELSE
                  V_Email_List := Gc_Notify_Contact1||':'||Gc_Notify_Contact3;
                   --   'padmanaban.sanjeevi@officedepot.com:sandy.stainton@officedepot.com';
                  V_Cc_Email_List := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                   --  'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
        END IF;

               v_subject :=
                     'REMINDER: UL RS REAUDIT DUE for '
                  || cur.od_sc_vendor_name
                  || '/'
                  || cur.od_sc_factory_name;

               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||'UL RS Team,' || CHR (10);
               v_text := v_text || CHR (10);
               v_text :=
                     v_text
                  || 'Last audit for '
                  || cur.od_sc_vendor_name
                  || ' V# '
                  || cur.od_sc_vendor_number
                  || ' aligned to '
                  || cur.od_sc_factory_name
                  || ' F# '
                  || cur.od_sc_factory_number;
               v_text :=
                     v_text
                  || ' was conducted on '
                  || TO_CHAR (cur.od_sc_straudt_schd_d)
                  || ' with a '
                  || cur.od_sc_str_audit_result
                  || '.'
                  || CHR (10);
               v_text := v_text || CHR (10);
               v_text :=
                     v_text
                  || 'The vendor is active in our system. Please confirm that an UL RS invoice has been generated to initiate the reaudit.';

               UPDATE qa_results
                  SET character84 = 'Y',             --  OD_SC_RECAUDIT_NOTIFY
                     -- character63 = TO_CHAR (SYSDATE, 'YYYY/MM/DD'),           commented as per defect# 31511
                                     -- audit request date OD_SC_STRAUDT_REQ_D
                      character64 = 'N',              --OD_SC_PAYMENT_RETAINER
                      character66 = NULL,               --OD_SC_VENDPAY_RCVD_D
                      character67 = NULL,               --OD_SC_STRAUDT_SCHD_D
                      character69 = NULL,             --OD_SC_STR_AUDIT_RESULT
                      character73 = NULL,           --OD_SC_STRAUDT_CAP_STATUS
                      character77 = NULL,           --OD_SC_CAP_FINAL_APPROVER
                      character78 = NULL,             --OD_SC_SRTAUDT_US_APR_D
                      character81 = NULL,               --OD_SC_VENDPAY_NOTIFY
                      character82 = NULL,                --OD_SC_REGRUSH_NOTIF
                      character83 = NULL,              --OD_SC_AUDRESZT_NOTIFY
                      character85 = NULL,                   --OD_SC_CAP_NOTIFY
                      character88 = NULL,
                      character44 = 'Regular'
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

				   fnd_file.put_line(fnd_file.LOG,'#6 Request id :'||v_conc_req_id|| ' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
                   fnd_file.put_line(fnd_file.LOG,'#6 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
				   fnd_file.put_line(fnd_file.LOG,'#6 Text: '||v_text);
                   fnd_file.put_line(fnd_file.LOG,'#6 Subject: '||v_subject);

               COMMIT;
               xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                          v_email_list,
                                                          v_cc_email_list,
                                                          v_text
                                                         );
            END IF;
         END IF;

         IF     cur.od_sc_recaudit_notify = 'Y'
            AND NVL (cur.od_sc_vendpay_notify, 'N') = 'N'
            AND cur.od_sc_vendpay_rcvd_d IS NULL
            AND cur.od_sc_audit_required IN ('Regular', 'Rush')
            AND cur.od_sc_straudt_req_d IS NOT NULL
            AND cur.od_sc_payment_retainer = 'N'
            AND (SYSDATE - cur.od_sc_straudt_req_d) > 13
         THEN
            IF lc_send_mail = 'Y'
            THEN
               v_email_list := Gc_Sa_Compliance_Sender;--'SA-compliance@officedepot.com';
               v_cc_email_list := NULL;
            ELSE
               v_email_list := Gc_Notify_Contact1; --'padmanaban.sanjeevi@officedepot.com';
                V_Cc_Email_List := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
        --    'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
      END IF;
               fnd_file.put_line(fnd_file.LOG,'#E.1 od_sc_recaudit_notify :'||cur.od_sc_recaudit_notify|| ' , '||'od_sc_vendpay_notify: '||cur.od_sc_vendpay_notify);
			   fnd_file.put_line(fnd_file.LOG,'#E.1 od_sc_vendpay_rcvd_d  :'||cur.od_sc_vendpay_rcvd_d|| ' , '||'od_sc_audit_required:  '||cur.od_sc_audit_required);
			   fnd_file.put_line(fnd_file.LOG,'#E.1 od_sc_straudt_req_d   :'||cur.od_sc_straudt_req_d|| ' , '||'od_sc_payment_retainer: '||cur.od_sc_payment_retainer);

            v_subject :=
                  'ALERT New Vendor Payment Not Received for UL RS Invoice/ '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || v_region
               || ' / '
               || cur.od_sc_audit_agent
               || ' / Dept :'
               || cur.od_sc_department;

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||'Social Accountability Team,' || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=v_text
               ||'To date, UL RS has not received payment for the re-audit due on '
               || TO_CHAR (cur.od_sc_req_audit_date)
               || '.';
            v_text :=
                  v_text
               || 'Please follow up with the merchant and/or agent to assist with collection.';

            UPDATE qa_results
               SET character81 = 'Y'                  --  OD_SC_VENDPAY_NOTIFY
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
          /*  xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      ); */  --Commented as per defect #31511
         END IF;                                                             --

         IF     NVL (cur.od_sc_regrush_notify, 'N') = 'N'
            AND cur.od_sc_recaudit_notify = 'Y'
            AND cur.od_sc_vendpay_rcvd_d IS NOT NULL
            AND NVL (cur.od_sc_payment_retainer, 'N') = 'N'
            AND cur.od_sc_straudt_schd_d IS NULL
            AND (   (    cur.od_sc_audit_required = 'Regular'
                     AND (SYSDATE - cur.od_sc_vendpay_rcvd_d) > 14
                    )
                 OR (    cur.od_sc_audit_required = 'Rush'
                     AND (SYSDATE - cur.od_sc_vendpay_rcvd_d) > 5
                    )
                )
         THEN
            IF lc_send_mail = 'Y'
            THEN
               v_email_list :=Gc_Audit_Regrush_Notify||':'||Gc_Sa_Compliance_Sender;--'OfficeDepot@ul.com:SA-Compliance@officedepot.com';
               v_cc_email_list := NULL;

            ELSE
               v_email_list := Gc_Notify_Contact1;--'padmanaban.sanjeevi@officedepot.com';
                 V_Cc_Email_List := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
        --  'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
       END IF;
	           fnd_file.put_line(fnd_file.LOG,'#F.1 od_sc_regrush_notify:'||cur.od_sc_regrush_notify|| ' , '||'od_sc_recaudit_notify: '||cur.od_sc_recaudit_notify);
               fnd_file.put_line(fnd_file.LOG,'#F.1 od_sc_vendpay_rcvd_d:'||cur.od_sc_vendpay_rcvd_d|| ' , '||'od_sc_payment_retainer: '||cur.od_sc_payment_retainer);
			   fnd_file.put_line(fnd_file.LOG,'#F.1 od_sc_audit_required:'||cur.od_sc_audit_required);
            v_subject :=
                  'ALERT Vendor Payment has been received for the UL RS required audit. Audit to be scheduled./ '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || v_region
               || ' / '
               || cur.od_sc_audit_agent;

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||'UL RS Team,' || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'UL RS has confirmed payment receipt from '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || cur.od_sc_audit_agent
               || '.'
               || CHR (10);
            v_text :=
                  v_text
               || 'However, Office Depot has not received confirmation that the audit has been scheduled.'
               || CHR (10);
            v_text :=
                  v_text
               || 'Please advise when this audit will be scheduled or reason(s) for the delay.'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || 'OFFICE DEPOT INC.' || CHR (10);
            v_text := v_text || 'Social Compliance Team' || CHR (10);
            v_text := v_text || Gc_Sa_Compliance_Sender--'SA-Compliance@officedepot.com'
                             || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Please do not reply to this email address. Send correspondence to '|| Gc_Sa_Compliance_Sender -- SA-Compliance@officedepot.com'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'NOTICE. This message contains information which is confidential and the copyright of our company or a third party. If you are not the intended recipient of this message please delete it and destroy all copies. If you are the intended recipient of this message you should not disclose or distribute this message to third parties without the consent of Office Depot, Inc.';


			       fnd_file.put_line(fnd_file.LOG,'#7 Request id '||v_conc_req_id|| ' , '||' Vendor Name '||cur.od_sc_vendor_name||' , '||'Factory Name'||cur.od_sc_factory_name);	--	v_conc_req_id
				   fnd_file.put_line(fnd_file.LOG,'#7 od_sc_regrush_notify '||cur.od_sc_regrush_notify|| ' , '||' od_sc_recaudit_notify '||cur.od_sc_recaudit_notify||' , '||'od_sc_vendpay_rcvd_d'||cur.od_sc_vendpay_rcvd_d);
				   fnd_file.put_line(fnd_file.LOG,'#7 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
				   fnd_file.put_line(fnd_file.LOG,'#7 Text '||v_text);
                   fnd_file.put_line(fnd_file.LOG,'#7 Subject '||v_subject);

            UPDATE qa_results
               SET character82 = 'Y'                  --  OD_SC_REGRUSH_NOTIFY
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
            xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      );
         END IF;

         IF     NVL (cur.od_sc_regrush_notify, 'N') = 'N'
            AND cur.od_sc_recaudit_notify = 'Y'
            AND cur.od_sc_vendpay_rcvd_d IS NULL
            AND cur.od_sc_payment_retainer = 'Y'
            AND cur.od_pb_payrtn_aprvl_date IS NOT NULL
            AND cur.od_sc_straudt_schd_d IS NULL
            AND (   (    cur.od_sc_audit_required = 'Regular'
                     AND (SYSDATE - cur.od_pb_payrtn_aprvl_date) > 14
                    )
                 OR (    cur.od_sc_audit_required = 'Rush'
                     AND (SYSDATE - cur.od_pb_payrtn_aprvl_date) > 5
                    )
                )
         THEN
            IF lc_send_mail = 'Y'
            THEN
               v_email_list :=Gc_Audit_Regrush_Notify||':'||Gc_Sa_Compliance_Sender;--'OfficeDepot@ul.com:SA-Compliance@officedepot.com';
               v_cc_email_list := NULL;

            ELSE
               v_email_list := Gc_Notify_Contact1;
                   --'padmanaban.sanjeevi@officedepot.com';
               v_cc_email_list :=Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                 -- 'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
            END IF;
            fnd_file.put_line(fnd_file.LOG,'#F.1 od_sc_regrush_notify:'||cur.od_sc_regrush_notify|| ' , '||'od_sc_recaudit_notify: '||cur.od_sc_recaudit_notify);
			fnd_file.put_line(fnd_file.LOG,'#F.1 od_sc_vendpay_rcvd_d:'||cur.od_sc_vendpay_rcvd_d|| ' , '||'od_sc_payment_retainer:'||cur.od_sc_payment_retainer);
			fnd_file.put_line(fnd_file.LOG,'#F.1 od_pb_payrtn_aprvl_date:'||cur.od_pb_payrtn_aprvl_date|| ' , '||'od_sc_straudt_schd_d:'||cur.od_sc_straudt_schd_d);
            v_subject :=
                  'ALERT Payment Retainer has been approved for the UL RS required audit. Audit to be scheduled./ '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || v_region
               || ' / '
               || cur.od_sc_audit_agent;

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||'UL RS Team,' || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Office Depot has approved the retainer as payment for the audit of '
               || cur.od_sc_vendor_name
               || ' / '
               || cur.od_sc_factory_name
               || ' / '
               || cur.od_sc_audit_agent
               || '.'
               || CHR (10);
            v_text :=
                  v_text
               || 'However, Office Depot has not received confirmation that the audit has been scheduled.'
               || CHR (10);
            v_text :=
                  v_text
               || 'Please advise when this audit will be scheduled or reason(s) for the delay.'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || 'OFFICE DEPOT INC.' || CHR (10);
            v_text := v_text || 'Social Compliance Team' || CHR (10);
            v_text := v_text || Gc_Sa_Compliance_Sender --'SA-Compliance@officedepot.com'
                             || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Please do not reply to this email address. Send correspondence to '|| Gc_Sa_Compliance_Sender  --SA-Compliance@officedepot.com'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'NOTICE. This message contains information which is confidential and the copyright of our company or a third party. If you are not the intended recipient of this message please delete it and destroy all copies. If you are the intended recipient of this message you should not disclose or distribute this message to third parties without the consent of Office Depot, Inc.';

    			   fnd_file.put_line(fnd_file.LOG,'#8 Request id: '||v_conc_req_id|| ' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
				   fnd_file.put_line(fnd_file.LOG,'#8 od_sc_regrush_notify: '||cur.od_sc_regrush_notify|| ' , '||' od_sc_recaudit_notify :'||cur.od_sc_recaudit_notify||' , '||'od_sc_vendpay_rcvd_d:'||cur.od_sc_vendpay_rcvd_d);
				   fnd_file.put_line(fnd_file.LOG,'#8 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
				   fnd_file.put_line(fnd_file.LOG,'#8 Text: '||v_text);
                   fnd_file.put_line(fnd_file.LOG,'#8 Subject: '||v_subject);

            UPDATE qa_results
               SET character82 = 'Y'                  --  OD_SC_REGRUSH_NOTIFY
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
            xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      );
         END IF;

         IF (    cur.od_sc_str_audit_result IS NOT NULL
             AND cur.od_sc_straudt_schd_d IS NOT NULL
            )
         THEN
            IF     NVL (cur.od_sc_audreszt_notify, 'N') = 'N'
               AND cur.od_sc_str_audit_result IN
                                           ('Denied Entry', 'Zero Tolerance')
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list :=Gc_Aud_Result_Notify||':'||Gc_Sa_Compliance_Sender;
                  --   'Sabrina.hernandezcruz@officedepot.com:SA-Compliance@officedepot.com';
                  v_cc_email_list := NULL;
               ELSE
                  v_email_list := Gc_Notify_Contact1;--'padmanaban.sanjeevi@officedepot.com';

                  v_cc_email_list :=Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                  --   'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
               END IF;

               IF cur.od_sc_str_audit_result = 'Zero Tolerance'
               THEN
                  v_subject := 'Zero Tolerance Notification for ';
               ELSIF cur.od_sc_str_audit_result = 'Denied Entry'
               THEN
                  v_subject := 'Denied Entry Notification for ';
               END IF;

               v_subject :=
                     v_subject
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' / '
                  || cur.od_sc_audit_agent
                  || ' / '
                  || v_region;

               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||
                     'The audit for '
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' was conducted on '
                  || TO_CHAR (cur.od_sc_straudt_schd_d)
                  || '.'
                  || CHR (10);
               v_text :=
                     v_text
                  || 'The facility is graded as '
                  || cur.od_sc_str_audit_result
                  || ' based on the current assessment.';

               UPDATE qa_results
                  SET character83 = 'Y'              --  OD_SC_AUDRESZT_NOTIFY
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
			       fnd_file.put_line(fnd_file.LOG,'#8.1 Request id: '||v_conc_req_id|| ' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id

				   fnd_file.put_line(fnd_file.LOG,'#8.1 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
				   fnd_file.put_line(fnd_file.LOG,'#8.1 Text: '||v_text);
                   fnd_file.put_line(fnd_file.LOG,'#8.1 Subject: '||v_subject);
               xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                          v_email_list,
                                                          v_cc_email_list,
                                                          v_text
                                                         );
            END IF;

            IF cur.od_sc_req_audit_date IS NULL
            THEN
               IF cur.od_sc_str_audit_result IN ('Denied Entry')
               THEN
                  v_nextaudit_date := cur.od_sc_straudt_schd_d + 30;
               ELSIF cur.od_sc_str_audit_result = 'Needs Improvement'
               THEN
                  v_nextaudit_date := cur.od_sc_straudt_schd_d + 180;
               ELSIF cur.od_sc_str_audit_result IN
                                    ('Satisfactory', 'Minor Progress Needed')
               THEN
                  v_nextaudit_date := cur.od_sc_straudt_schd_d + 365;
               END IF;

               UPDATE qa_results
                  SET character68 = TO_CHAR (v_nextaudit_date, 'YYYY/MM/DD'),
                                                      --  OD_SC_REQ_AUDIT_DATE
                      character84 = NULL                --OD_SC_RECAUDIT_NOTIF
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
            -- reset the flags for recaudit,cap,  -- pending
            END IF;
         END IF;
--     IF (cur.OD_SC_STR_AUDIT_RESULT IS NOT NULL AND cur.OD_SC_STRAUDT_SCHD_D IS NOT NULL) THEN

         IF     cur.od_sc_str_audit_result IS NOT NULL
            AND cur.od_sc_straudt_schd_d IS NOT NULL
            AND cur.od_sc_str_audit_result = 'Zero Tolerance'
            AND cur.od_sc_req_audit_date IS NULL
            AND cur.od_sc_srtaudt_us_apr_d IS NOT NULL
         THEN
            v_nextaudit_date := cur.od_sc_srtaudt_us_apr_d + 30;

            UPDATE qa_results
               SET character68 =
                      TO_CHAR (v_nextaudit_date, 'YYYY/MM/DD')
                                                      --  OD_SC_REQ_AUDIT_DATE
             WHERE plan_id = cur.plan_id
               AND occurrence = cur.occurrence
               AND organization_id = cur.organization_id;

            COMMIT;
         END IF;

         IF     cur.od_sc_straudt_cap_status = 'Complete'
            AND cur.od_sc_cap_final_approver IS NOT NULL
            AND cur.od_sc_srtaudt_us_apr_d IS NOT NULL
            AND cur.od_sc_fqa_aprvl_d IS NOT NULL
         THEN
            IF NVL (cur.od_sc_cap_notify, 'N') = 'N'
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list := Gc_Sa_Compliance_Sender;         --'SA-Compliance@officedepot.com';
                  v_cc_email_list := NULL;
                ELSE
                  V_Email_List := Gc_Notify_Contact1;
                  -- 'padmanaban.sanjeevi@officedepot.com';
                   V_Cc_Email_List := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
                  -- 'francia.pampillonia@officedepot.com:sandy.stainton@officedepot.com';
                END IF;

               v_subject :=
                     'CAP APPROVED_ACTIVATION REQUEST/ '
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' / '
                  || cur.od_sc_audit_agent
                  || ' / '
                  || v_region;

               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||'Social Accountability Team,' || CHR (10);
               v_text := v_text || CHR (10);
               v_text :=
                     v_text
                  || 'The CAP for '
                  || cur.od_sc_vendor_name
                  || ' / '
                  || cur.od_sc_factory_name
                  || ' for '
                  || cur.od_sc_vendor_number
                  || ' has been approved.'
                  || CHR (10);
               v_text :=
                     v_text
                  || 'The FQA has been approved on '
                  || TO_CHAR (cur.od_sc_fqa_aprvl_d)
                  || '.'
                  || CHR (10);
               v_text := v_text || CHR (10);

               UPDATE qa_results
                  SET character85 = 'Y'                    -- OD_SC_CAP_NOTIFY
                WHERE plan_id = cur.plan_id
                  AND occurrence = cur.occurrence
                  AND organization_id = cur.organization_id;

               COMMIT;
			       fnd_file.put_line(fnd_file.LOG,'#9.1 Request id: '||v_conc_req_id|| ' , '||' Vendor Name: '||cur.od_sc_vendor_name||' , '||'Factory Name:'||cur.od_sc_factory_name);	--	v_conc_req_id
				   fnd_file.put_line(fnd_file.LOG,'#9.1 Plan name: '||cur.plan_name||' , '||' occurrence: '||cur.occurrence||' , '||' last_update_date: '||cur.last_update_date||' , '||'last_updated_by:'||cur.last_updated_by);
				   fnd_file.put_line(fnd_file.LOG,'#9.1 Text: '||v_text);
                   fnd_file.put_line(fnd_file.LOG,'#9.1 Subject: '||v_subject);

               xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                          v_email_list,
                                                          v_cc_email_list,
                                                          v_text
                                                         );
            END IF;
         END IF;
      END LOOP;

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         COMMIT;
         v_errbuf := 'Error in When others :' || SQLERRM;
         v_retcode := SQLCODE;
   END xx_sc_process;

   PROCEDURE xx_sc_status_alert (
      x_errbuf    OUT NOCOPY   VARCHAR2,
      x_retcode   OUT NOCOPY   VARCHAR2
   )
   IS
      CURSOR cur_str_status
      IS
         SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.collection_id,mas.occurrence,
       mas.od_sc_vendor_number,mas.od_sc_factory_number,mas.od_sc_vendor_name,mas.od_sc_audit_agent,
       mas.od_sc_factory_name,
       mas.od_sc_europe_rgn,mas.od_sc_mexico_region,mas.od_sc_asia_region,mas.od_sc_vend_region,
       mas.od_sc_str_audit_result,mas.od_sc_audit_status_notify
  FROM q_od_pb_sc_vendor_master_v mas
 WHERE 1 = 1
   AND mas.od_sc_vendor_status = 'Active'
   AND mas.od_sc_audit_agent IN ('ODGSO', 'LF')
   AND NVL (mas.od_sc_audit_status_notify, 'N') = 'N'
   AND EXISTS (
          SELECT 'x'
            FROM q_od_sc_vendor_audit_v aud
           WHERE aud.od_sc_transmission_status = 'Final'
             AND substr(aud.od_sc_vendor,1,15) = substr(mas.od_sc_vendor_name,1,15)
             AND substr(aud.od_sc_factory,1,15) = substr(mas.od_sc_factory_name,1,15)
             AND aud.od_sc_grade = 'Needs Improvement')
union all
SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.collection_id,mas.occurrence,
       mas.od_sc_vendor_number,mas.od_sc_factory_number,mas.od_sc_vendor_name,mas.od_sc_audit_agent,
       mas.od_sc_factory_name,
       mas.od_sc_europe_rgn,mas.od_sc_mexico_region,mas.od_sc_asia_region,mas.od_sc_vend_region,
       mas.od_sc_str_audit_result,mas.od_sc_audit_status_notify
  FROM q_od_sc_eu_vendor_master_v mas
 WHERE 1 = 1
   AND mas.od_sc_vendor_status = 'Active'
   AND mas.od_sc_audit_agent IN ('ODGSO', 'LF')
   AND NVL (mas.od_sc_audit_status_notify, 'N') = 'N'
   AND EXISTS (
          SELECT 'x'
            FROM q_od_sc_vendor_audit_v aud
           WHERE aud.od_sc_transmission_status = 'Final'
             AND substr(aud.od_sc_vendor,1,15) = substr(mas.od_sc_vendor_name,1,15)
             AND substr(aud.od_sc_factory,1,15) = substr(mas.od_sc_factory_name,1,15)
             AND aud.od_sc_grade = 'Needs Improvement')
union all
SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.collection_id,mas.occurrence,
       mas.od_sc_vendor_number,mas.od_sc_factory_number,mas.od_sc_vendor_name,mas.od_sc_audit_agent,
       mas.od_sc_factory_name,
       mas.od_sc_europe_rgn,mas.od_sc_mexico_region,mas.od_sc_asia_region,mas.od_sc_vend_region,
       mas.od_sc_str_audit_result,mas.od_sc_audit_status_notify
  FROM q_od_sc_asia_vendor_master_v mas
 WHERE 1 = 1
   AND mas.od_sc_vendor_status = 'Active'
   AND mas.od_sc_audit_agent IN ('ODGSO', 'LF')
   AND NVL (mas.od_sc_audit_status_notify, 'N') = 'N'
   AND EXISTS (
          SELECT 'x'
            FROM q_od_sc_vendor_audit_v aud
           WHERE aud.od_sc_transmission_status = 'Final'
             AND substr(aud.od_sc_vendor,1,15) = substr(mas.od_sc_vendor_name,1,15)
             AND substr(aud.od_sc_factory,1,15) = substr(mas.od_sc_factory_name,1,15)
             AND aud.od_sc_grade = 'Needs Improvement')
union all
SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.collection_id,mas.occurrence,
       mas.od_sc_vendor_number,mas.od_sc_factory_number,mas.od_sc_vendor_name,mas.od_sc_audit_agent,
       mas.od_sc_factory_name,
       mas.od_sc_europe_rgn,mas.od_sc_mexico_region,mas.od_sc_asia_region,mas.od_sc_vend_region,
       mas.od_sc_str_audit_result,mas.od_sc_audit_status_notify
  FROM q_od_sc_mx_vendor_master_v mas
 WHERE 1 = 1
   AND mas.od_sc_vendor_status = 'Active'
   AND mas.od_sc_audit_agent IN ('ODGSO', 'LF')
   AND NVL (mas.od_sc_audit_status_notify, 'N') = 'N'
   AND EXISTS (
          SELECT 'x'
            FROM q_od_sc_vendor_audit_v aud
           WHERE aud.od_sc_transmission_status = 'Final'
             AND substr(aud.od_sc_vendor,1,15) = substr(mas.od_sc_vendor_name,1,15)
             AND substr(aud.od_sc_factory,1,15) = substr(mas.od_sc_factory_name,1,15)
             AND aud.od_sc_grade = 'Needs Improvement')    ;

      conn               UTL_SMTP.connection;
      v_email_list       VARCHAR2 (3000);
      v_cc_email_list    VARCHAR2 (3000);
      v_text             VARCHAR2 (3000);
      v_subject          VARCHAR2 (3000);
      v_region_contact   VARCHAR2 (250);
      v_region           VARCHAR2 (50);
      v_nextaudit_date   DATE;
      lc_send_mail       VARCHAR2 (1)
                                   := fnd_profile.VALUE ('XX_PB_SC_SEND_MAIL');
      v_errbuf           VARCHAR2 (2000);
      v_retcode          VARCHAR2 (50);
      ln_audit_count     NUMBER;
   BEGIN
         assign_globals;      -- Defect 31287
     FOR str_status IN cur_str_status
       LOOP
         BEGIN
            SELECT COUNT (DISTINCT od_sc_inspection_no)
              INTO ln_audit_count
              FROM q_od_sc_vendor_audit_v
             WHERE od_sc_transmission_status = 'Final'
               AND od_sc_vendor = str_status.od_sc_vendor_name
               AND od_sc_factory = str_status.od_sc_factory_name
               AND od_sc_grade = 'Needs Improvement';
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               ln_audit_count := 0;
            WHEN OTHERS
            THEN
               ln_audit_count := 0;
         END;

         IF     ln_audit_count >= 3
            AND NVL (str_status.od_sc_audit_status_notify, 'N') = 'N'
         THEN

            v_text := null;
            v_text := v_text||chr(13);
            v_text := v_text||
                  'This notification is to advise you that '
               || str_status.od_sc_vendor_name
               || '/'
               || str_status.od_sc_vendor_number
               || ''
               || CHR (10);
            v_text :=
                  v_text
               || 'assigned to '
               || str_status.od_sc_factory_name
               || '/'
               || str_status.od_sc_factory_number
               || ' has recently received a third sequential Needs Improvement Grade.'
               || CHR (10);
            v_text :=
                  v_text
               || 'At this time you are required to start looking for an alternate vendor to be set up within the next 6 months.'
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text :=
                  v_text
               || 'Your vendor may be terminated if they receive two additional Needs Improvement gradings. '
               || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || CHR (10);
            v_text := v_text || 'Sabrina Hernandez-Cruz' || CHR (10);
            v_text :=
                  v_text
               || 'Director, Vendor Compliance and Social Responsibility'
               || CHR (10);
            v_text := v_text || '6600 North Military Trail' || CHR (10);
            v_text :=
                 v_text || 'Mail Code: N532, Boca Raton, FL 33496' || CHR (10);
            v_text := v_text || '(P) 561.438.8142' || CHR (10);
            v_text := v_text || '(F) 561.438.4280' || CHR (10);
            v_text :=
                 v_text ||Gc_Aud_Result_Notify -- 'Sabrina.HernandezCruz@officedepot.com'
                       || CHR (10);
            v_subject :=
                 'Needs Improvement Warning :' || str_status.od_sc_vendor_name;

        IF lc_send_mail = 'Y'
            THEN

            v_email_list                        := gc_gso_social_notify;--'gso.socialaccountability@officedepot.com';
           IF str_status.od_sc_europe_rgn       = 'ODEU' THEN
            v_cc_email_list                   :=Gc_Sa_Compliance_Sender||' : '||gc_eu_social_notify; --'SA-Compliance@officedepot.com:Compliance.EU@officedepot.com';
           ELSIF str_status.od_sc_asia_region   = 'ODASIA' THEN
            v_cc_email_list                   := Gc_Sa_Compliance_Sender||' : '||gc_asia_social_notify;--'SA-Compliance@officedepot.com:asia.socialaccountability@officedepot.com';
           ELSIF str_status.od_sc_mexico_region = 'ODMX' THEN
            V_Cc_Email_List                   := Gc_Sa_Compliance_Sender||' : '||gc_odmx_social_notify;
            --'SA-Compliance@officedepot.com:ODMX.socialaccountability@officedepot.com.mx';
            ELSIF str_status.od_sc_vend_region = 'ODUS' THEN
            v_cc_email_list                 := Gc_Sa_Compliance_Sender;--'SA-Compliance@officedepot.com';
           END IF;
           ELSE
            V_Email_List := Gc_Notify_Contact1;
            -- 'padmanaban.sanjeevi@officedepot.com';
            V_Cc_Email_List := Gc_Notify_Contact2||':'||Gc_Notify_Contact3;
             --   'sandy.stainton@officedepot.com:francia.pampillonia@officedepot.com';
        END IF;

             fnd_file.put_line(fnd_file.LOG,'#c.1 Text :'||v_text);
               fnd_file.put_line(fnd_file.LOG,'#c.2 Subject :'||v_subject);
			   fnd_file.put_line(fnd_file.LOG,'#c.1 Plan :'||str_status.plan_id);
               fnd_file.put_line(fnd_file.LOG,'#c.2 Occurrence :'||str_status.occurrence);

            xx_pa_pb_compliance_pkg.send_notification (v_subject,
                                                       v_email_list,
                                                       v_cc_email_list,
                                                       v_text
                                                      );

            UPDATE qa_results
               SET character99 = 'Y'
             WHERE plan_id = str_status.plan_id
               AND occurrence = str_status.occurrence
               AND organization_id = str_status.organization_id;

            COMMIT;
         END IF;
      END LOOP;                                            --- end master loop

      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         COMMIT;
         v_errbuf := 'Error in When others :' || SQLERRM;
         v_retcode := SQLCODE;
   END xx_sc_status_alert;


PROCEDURE xx_sc_int_process (
   x_errbuf    OUT NOCOPY   VARCHAR2,
   x_retcode   OUT NOCOPY   VARCHAR2
)
IS

    CURSOR cur_audit_init IS
    SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.occurrence,
           mas.od_sc_vendor_number, mas.od_sc_vendor_name, od_sc_audit_agent,
           mas.od_sc_factory_number, mas.od_sc_factory_name,
           mas.od_sc_europe_rgn region, mas.od_sc_eu_sub_rgn sub_region,
           mas.od_sc_fzt_aprvl_d, mas.od_sc_preaudt_result,
           mas.od_sc_initstr_notify, mas.od_sc_merchant, mas.od_sc_product,
           mas.od_sc_audit_required, fl.file_name, fl.file_id, fl.file_data,
           fl.file_content_type, fdc.user_name,
           MAS.OD_SC_VEND_ADDRESS, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_CONT_NAME, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_PHONE, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_FAX, 		-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_EMAIL,	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_ADDRESS, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACT_CONT_NAME, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_PHONE, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_FAX, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_EMAIL 	-- Added by Kiran Maddala as per Version 1.9
      FROM fnd_lobs fl,
           fnd_document_categories_tl fdc,
           fnd_documents fd,
           fnd_documents_tl fdt,
           fnd_document_datatypes fdd,
           fnd_attached_documents fad,
           q_od_sc_eu_vendor_master_v mas
     WHERE 1 = 1
       AND fd.document_id = fdt.document_id
       AND fd.datatype_id = fdd.datatype_id
       AND fdd.user_name = 'File'
       AND fd.document_id = fad.document_id
       AND fdd.LANGUAGE = 'US'
       AND fad.entity_name = 'QA_RESULTS'
       AND fad.pk3_value = mas.plan_id
       AND fad.pk1_value = mas.occurrence
       AND fdc.category_id = fd.category_id
       AND fl.file_id = fd.media_id  -- Modified for R12
       AND fdc.user_name = 'SR_Factory Add-Drop Forms'
       AND mas.od_sc_preaudt_result IS NOT NULL
       AND mas.od_sc_zt_status IS NOT NULL
       AND mas.od_sc_fzt_approver IS NOT NULL
       AND mas.od_sc_fzt_aprvl_d IS NOT NULL
       AND mas.od_sc_audit_required IS NOT NULL
       AND nvl(mas.od_sc_initstr_notify,'N') = 'N'
    UNION ALL
    SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.occurrence,
           mas.od_sc_vendor_number, mas.od_sc_vendor_name, od_sc_audit_agent,
           mas.od_sc_factory_number, mas.od_sc_factory_name,
           mas.od_sc_asia_region region, mas.od_sc_as_sub_rgn sub_region,
           mas.od_sc_fzt_aprvl_d, mas.od_sc_preaudt_result,
           mas.od_sc_initstr_notify, mas.od_sc_merchant, mas.od_sc_product,
           mas.od_sc_audit_required, fl.file_name, fl.file_id, fl.file_data,
           fl.file_content_type, fdc.user_name,
           MAS.OD_SC_VEND_ADDRESS, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_CONT_NAME, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_PHONE, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_FAX, 		-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_EMAIL,	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_ADDRESS, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACT_CONT_NAME, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_PHONE, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_FAX, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_EMAIL 	-- Added by Kiran Maddala as per Version 1.9
      FROM fnd_lobs fl,
           fnd_document_categories_tl fdc,
           fnd_documents fd,
           fnd_documents_tl fdt,
           fnd_document_datatypes fdd,
           fnd_attached_documents fad,
           q_od_sc_asia_vendor_master_v mas
     WHERE 1 = 1
       AND fd.document_id = fdt.document_id
       AND fd.datatype_id = fdd.datatype_id
       AND fdd.user_name = 'File'
       AND fd.document_id = fad.document_id
       AND fdd.LANGUAGE = 'US'
       AND fad.entity_name = 'QA_RESULTS'
       AND fad.pk3_value = mas.plan_id
       AND fad.pk1_value = mas.occurrence
       AND fdc.category_id = fd.category_id
       AND fl.file_id = fd.media_id  -- Modified for R12
       AND fdc.user_name = 'SR_Factory Add-Drop Forms'
       AND mas.od_sc_preaudt_result IS NOT NULL
       AND mas.od_sc_zt_status IS NOT NULL
       AND mas.od_sc_fzt_approver IS NOT NULL
       AND mas.od_sc_fzt_aprvl_d IS NOT NULL
       AND mas.od_sc_audit_required IS NOT NULL
       AND nvl(mas.od_sc_initstr_notify,'N') = 'N'
    UNION ALL
    SELECT mas.plan_id,mas.plan_name,mas.organization_id,mas.occurrence,
           mas.od_sc_vendor_number, mas.od_sc_vendor_name, od_sc_audit_agent,
           mas.od_sc_factory_number, mas.od_sc_factory_name,
           mas.od_sc_mexico_region region, mas.od_sc_mx_sub_rgn sub_region,
           mas.od_sc_fzt_aprvl_d, mas.od_sc_preaudt_result,
           mas.od_sc_initstr_notify, mas.od_sc_merchant, mas.od_sc_product,
           mas.od_sc_audit_required, fl.file_name, fl.file_id, fl.file_data,
           fl.file_content_type, fdc.user_name,
           MAS.OD_SC_VEND_ADDRESS, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_CONT_NAME, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_PHONE, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_FAX, 		-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_VEND_EMAIL,	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_ADDRESS, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACT_CONT_NAME, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_PHONE, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_FAX, 	-- Added by Kiran Maddala as per Version 1.9
	   MAS.OD_SC_FACTORY_EMAIL 	-- Added by Kiran Maddala as per Version 1.9
      FROM fnd_lobs fl,
           fnd_document_categories_tl fdc,
           fnd_documents fd,
           fnd_documents_tl fdt,
           fnd_document_datatypes fdd,
           fnd_attached_documents fad,
           q_od_sc_mx_vendor_master_v mas
     WHERE 1 = 1
       AND fd.document_id = fdt.document_id
       AND fd.datatype_id = fdd.datatype_id
       AND fdd.user_name = 'File'
       AND fd.document_id = fad.document_id
       AND fdd.LANGUAGE = 'US'
       AND fad.entity_name = 'QA_RESULTS'
       AND fad.pk3_value = mas.plan_id
       AND fad.pk1_value = mas.occurrence
       AND fdc.category_id = fd.category_id
       AND fl.file_id = fd.media_id  -- Modified for R12
       AND fdc.user_name = 'SR_Factory Add-Drop Forms'
       AND mas.od_sc_preaudt_result IS NOT NULL
       AND mas.od_sc_zt_status IS NOT NULL
       AND mas.od_sc_fzt_approver IS NOT NULL
       AND mas.od_sc_fzt_aprvl_d IS NOT NULL
       AND mas.od_sc_audit_required IS NOT NULL
       AND nvl(mas.od_sc_initstr_notify,'N') = 'N' ;

    CURSOR cur_next_aud_dt IS
    SELECT mas.plan_id, mas.plan_name, mas.organization_id, mas.occurrence,
           mas.od_sc_str_audit_result, mas.od_sc_straudt_schd_d,
           mas.od_sc_req_audit_date, mas.od_sc_srtaudt_us_apr_d,
           mas.od_sc_audreszt_notify, mas.od_sc_vendor_number,
           mas.od_sc_vendor_name, od_sc_audit_agent, mas.od_sc_factory_number,
           mas.od_sc_factory_name
      FROM q_od_sc_eu_vendor_master_v mas
     WHERE 1 = 1
       AND mas.od_sc_str_audit_result IS NOT NULL
       AND NVL (mas.od_sc_audreszt_notify, 'N') = 'N'
    UNION ALL
    SELECT mas.plan_id, mas.plan_name, mas.organization_id, mas.occurrence,
           mas.od_sc_str_audit_result, mas.od_sc_straudt_schd_d,
           mas.od_sc_req_audit_date, mas.od_sc_srtaudt_us_apr_d,
           mas.od_sc_audreszt_notify, mas.od_sc_vendor_number,
           mas.od_sc_vendor_name, od_sc_audit_agent, mas.od_sc_factory_number,
           mas.od_sc_factory_name
      FROM q_od_sc_asia_vendor_master_v mas
     WHERE 1 = 1
       AND mas.od_sc_str_audit_result IS NOT NULL
       AND NVL (mas.od_sc_audreszt_notify, 'N') = 'N'
    UNION ALL
    SELECT mas.plan_id, mas.plan_name, mas.organization_id, mas.occurrence,
           mas.od_sc_str_audit_result, mas.od_sc_straudt_schd_d,
           mas.od_sc_req_audit_date, mas.od_sc_srtaudt_us_apr_d,
           mas.od_sc_audreszt_notify, mas.od_sc_vendor_number,
           mas.od_sc_vendor_name, od_sc_audit_agent, mas.od_sc_factory_number,
           mas.od_sc_factory_name
      FROM q_od_sc_mx_vendor_master_v mas
     WHERE 1 = 1
       AND mas.od_sc_str_audit_result IS NOT NULL
       AND NVL (mas.od_sc_audreszt_notify, 'N') = 'N';

   conn               UTL_SMTP.connection;
   v_email_list       VARCHAR2 (3000);
   v_cc_email_list    VARCHAR2 (3000);
   v_text             VARCHAR2 (3000);
   v_subject          VARCHAR2 (3000);
   v_sub_region       VARCHAR2 (50);
   v_region           VARCHAR2 (50);
   v_nextaudit_date   DATE;
   lc_send_mail       VARCHAR2 (1) := fnd_profile.VALUE ('XX_PB_SC_SEND_MAIL');
   v_errbuf           VARCHAR2 (2000);
   v_retcode          VARCHAR2 (50);
   Lc_Eu_Email_List      VARCHAR2 (2000) ;                        --'Compliance.EU@officedepot.com' ;
   Lc_Asia_Email_List    VARCHAR2 (2000) ;                      --'asia.socialaccountability@officedepot.com';
   Lc_Mx_Email_List      VARCHAR2 (2000) ;                      --'ODMX.socialaccountability@officedepot.com.mx';
   Lc_Test_Email_List    VARCHAR2 (2000) ;                        --'padmanaban.sanjeevi@officedepot.com';
   Lc_Test_Cc_Email_List VARCHAR2 (2000) ;                 --'Sandy.Stainton@officedepot.com;francia.pampillonia@officedepot.com';
   ld_nextaudit_date	    DATE;
   lc_grade                 VARCHAR2 (150);
   ld_audit_schduled_date   DATE;
   ld_inspection_date       DATE;
   ld_cap_final_appr_date   DATE;

BEGIN

   assign_globals;      -- Defect 31287

   Lc_Eu_Email_List          := Gc_Eu_Social_Notify;                        --'Compliance.EU@officedepot.com' ;
   Lc_Asia_Email_List        := Gc_Asia_Social_Notify;                      --'asia.socialaccountability@officedepot.com';
   Lc_Mx_Email_List          := Gc_Odmx_Social_Notify;                      --'ODMX.socialaccountability@officedepot.com.mx';
   Lc_Test_Email_List        := Gc_Notify_Contact1 ;                        --'padmanaban.sanjeevi@officedepot.com';
   Lc_Test_Cc_Email_List     := Gc_Notify_Contact2||';'||Gc_Notify_Contact3;--'Sandy.Stainton@officedepot.com;francia.pampillonia@officedepot.com';

   Fnd_File.Put_Line(Fnd_File.Log, 'Notify_EU_Email_list: '||Lc_Eu_Email_List );
   Fnd_File.Put_Line(Fnd_File.Log, 'Notify_Asia_Email_list: '||Lc_Asia_Email_List );
   Fnd_File.Put_Line(Fnd_File.Log, 'Notify_MX_Email_list: '||Lc_Mx_Email_List  );
   Fnd_File.Put_Line(Fnd_File.Log, 'Notify_Test_Email_list: '||Lc_Test_Email_List  );
   Fnd_File.Put_Line(Fnd_File.Log, 'Notify_Test_Cc_Email_list: '||Lc_Test_Cc_Email_List );

   --End Defect 31287
   FOR audit_rec IN cur_audit_init
   LOOP
      -- Checking for Pre-Audit completion
            IF NVL (audit_rec.od_sc_initstr_notify, 'N') = 'N'
            THEN
               IF lc_send_mail = 'Y'
               THEN
                  v_email_list := Gc_Sa_Compliance_Sender;--'SA-Compliance@officedepot.com' ;
                  IF audit_rec.region = 'ODEU'
                  THEN
                  v_cc_email_list := lc_test_cc_email_list||';'||lc_eu_email_list  ;
                  ELSIF audit_rec.region = 'ODASIA'
                  THEN
                  v_cc_email_list := lc_test_cc_email_list||';'||lc_asia_email_list  ;
                  ELSIF audit_rec.region = 'ODMX'
                  THEN
                  v_cc_email_list := lc_test_cc_email_list||';'||lc_mx_email_list  ;
                  END IF;

               ELSE
                  v_email_list := lc_test_email_list ;
                  v_cc_email_list := lc_test_cc_email_list ;
               END IF;

              fnd_file.put_line(fnd_file.LOG,'#G.1 od_sc_initstr_notify :'||audit_rec.od_sc_initstr_notify);
               v_subject :=
                     audit_rec.od_sc_vendor_name
                  || ' / '
                  || audit_rec.od_sc_factory_name
                  || ' / '
                  || audit_rec.od_sc_audit_agent
                  || ' / '
                  || audit_rec.region
                  || ' / '
                  || audit_rec.sub_region
                  || ' /  Notification to Initiate UL RS Audit Request';

               v_text := null;
               v_text := v_text||chr(13);
               v_text := v_text||
                     'This is to inform you that the Pre-audit CAP for '
                  || audit_rec.od_sc_vendor_name
                  || ' / '
                  || audit_rec.od_sc_factory_name
                  || ' has been completed'
                  || CHR (10);
               v_text :=
                     v_text
                  || 'and approved on '
                  || TO_CHAR (audit_rec.od_sc_fzt_aprvl_d)
                  || ' with a Pre-audit result of '
                  || audit_rec.od_sc_preaudt_result
                  || '.'
                  || CHR (10);
               v_text :=
                     v_text
                  || 'The Factory Declaration Add/Drop form is attached.'
                  || CHR (10);
               v_text := v_text || CHR (10);
               v_text :=
                     v_text
                  || 'The Merchant is '
                  || audit_rec.od_sc_merchant
                  || ' , product type is '
                  || audit_rec.od_sc_product
                  || '.'
                  || CHR (10);
               v_text := v_text || CHR (10);
               v_text :=
                     v_text
                  || 'Please submit a request to initiate the UL RS Audit as '
                  || audit_rec.od_sc_audit_required
                 -- || '.' 	-- commented by Kiran Maddala as per Version 1.9
                 -- || CHR (10) -- commented by Kiran Maddala as per Version 1.9
                  || ' for the below vendor.' -- Added by Kiran Maddala as per Version 1.9
                  || CHR (10);
             -- Change Started by Kiran Maddala      as per Version 1.9
             	v_text := v_text|| CHR (10);
             	v_text :=
		         v_text
                  || 'VENDOR NAME:  '||audit_rec.od_sc_vendor_name
                  || CHR (10)
                  || 'VENDOR ADDRESS:  '||audit_rec.od_sc_vend_address
                  || CHR (10)
                  || 'VENDOR CONTACT NAME:  '||audit_rec.od_sc_vend_cont_name
                  || CHR (10)
                  || 'VENDOR PHONE:  '||audit_rec.od_sc_vend_phone
                  || CHR (10)
                  || 'VENDOR FAX:  '||audit_rec.od_sc_vend_fax
                  || CHR (10)
                  || 'VENDOR EMAIL:  '||audit_rec.od_sc_vend_email
                  || CHR (10);
                  v_text := v_text|| CHR (10);
		  v_text :=
		  	v_text
                  || 'FACTORY NAME:  '||audit_rec.od_sc_factory_name
                  || CHR (10)
                  || 'FACTORY ADDRESS:  '||audit_rec.od_sc_factory_address
                  || CHR (10)
                  || 'FACTORY CONTACT NAME:  '||audit_rec.od_sc_fact_cont_name
                  || CHR (10)
                  || 'FACTORY PHONE:  '||audit_rec.od_sc_factory_phone
                  || CHR (10)
                  || 'FACTORY FAX:  '||audit_rec.od_sc_factory_fax
                  || CHR (10)
                  || 'FACTORY EMAIL:  '||audit_rec.od_sc_factory_email
                  || CHR (10);
                  v_text := v_text|| CHR (10);

	       -- Change ended by Kiran Maddala 	as per Version 1.9

               -- Notification to US to initiate audit

                  v_text :=
                        v_text
                     || 'Please do not reply to this email address. Send correspondence to ' ||Gc_Sa_Compliance_Sender--SA-Compliance@officedepot.com'
                     || CHR (10);
                  v_text := v_text || CHR (10);
                  v_text := v_text || CHR (10);
                  v_text :=
                        v_text
                     || 'NOTICE. This message contains information which is confidential and the copyright of our company or a third party. If you are not the intended recipient of this message please delete it and destroy all copies. If you are the intended recipient of this message you should not disclose or distribute this message to third parties without the consent of Office Depot, Inc.';

                  fnd_file.put_line(fnd_file.LOG,'#c.3 Text :'||v_text);
                  fnd_file.put_line(fnd_file.LOG,'#c.4 Subject :'||v_subject);
				  fnd_file.put_line(fnd_file.LOG,'#c.5 Plan :'||audit_rec.plan_id);
                  fnd_file.put_line(fnd_file.LOG,'#c.6 Occurrence :'||audit_rec.occurrence);
				  conn :=
                     xx_pa_pb_mail.begin_mail
                               (sender             => Gc_Sa_Compliance_Sender,--'SA-Compliance@officedepot.com',
                                recipients         => v_email_list,
                                cc_recipients      => v_cc_email_list,
                                subject            => v_subject,
                                mime_type          => xx_pa_pb_mail.multipart_mime_type
                               );

                     xx_pa_pb_mail.xx_attch_doc (conn,
                                                 audit_rec.file_name,
                                                 audit_rec.file_data,
                                                 audit_rec.file_content_type
                                                );


                     xx_pa_pb_mail.end_attachment (conn => conn);
                     xx_pa_pb_mail.attach_text (conn           => conn,
                                             DATA           => v_text--, Defect 31287
                                             --mime_type      => 'multipart/html'
                                            );
                     xx_pa_pb_mail.end_mail (conn => conn);

                  UPDATE qa_results
                     SET character81 = 'Y',           --  OD_SC_INITSTR_NOTIFY
                         character63 = TO_CHAR (SYSDATE, 'YYYY/MM/DD')
                   -- STR Audit Request Date
                  WHERE  plan_id = audit_rec.plan_id
                     AND occurrence = audit_rec.occurrence
                     AND organization_id = audit_rec.organization_id;

                  COMMIT;

            END IF;           --IF  NVL(cur.OD_SC_INITSTR_NOTIFY,'N')='N' THEN


   END LOOP;

   COMMIT;

   FOR next_aud_rec IN cur_next_aud_dt
   LOOP

   lc_grade                 := next_aud_rec.od_sc_str_audit_result ;
   ld_audit_schduled_date   := next_aud_rec.od_sc_straudt_schd_d ;
   ld_cap_final_appr_date   := next_aud_rec.od_sc_srtaudt_us_apr_d ;

        IF next_aud_rec.od_sc_str_audit_result = 'Denied Entry'  THEN
            ld_nextaudit_date:= ld_audit_schduled_date + 30;
        ELSIF next_aud_rec.od_sc_str_audit_result = 'Zero Tolerance' THEN
           If ld_cap_final_appr_date IS NOT NULL
           THEN
            ld_nextaudit_date := ld_cap_final_appr_date + 30 ;
           ELSE
            ld_nextaudit_date := Null;
           END IF;
        ELSIF next_aud_rec.od_sc_str_audit_result = 'Needs Improvement' THEN
            ld_nextaudit_date := ld_audit_schduled_date + 180;
        ELSIF next_aud_rec.od_sc_str_audit_result IN ('Satisfactory','Minor Progress Needed') THEN
            ld_nextaudit_date := ld_audit_schduled_date + 365;
        END IF;

        update qa_results
           SET character84 = 'Y',           --  OD_SC_AUDRESZT_NOTIFY
               character69 = TO_CHAR(ld_nextaudit_date,'YYYY/MM/DD')   -- Next Audit Date
         WHERE  plan_id = next_aud_rec.plan_id
           AND occurrence = next_aud_rec.occurrence
           AND organization_id = next_aud_rec.organization_id;

        COMMIT;


   END LOOP;


EXCEPTION
   WHEN OTHERS
   THEN
      COMMIT;
      v_errbuf := 'Error in When others :' || SQLERRM;
      fnd_file.put_line(fnd_file.log,'Error in When others :' || SQLERRM);
      v_retcode := SQLCODE;
END xx_sc_int_process;

END xx_pa_pb_compliance_pkg;
/
