SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY APPS.XX_QA_ED_PKG
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_QA_ED_PKG.pkb      	   	               |
-- | Description :  OD QA ED Processing Pkg                            |
-- | Rice id     :  E3045                                              |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |1.0       03-AUG-2011 Bapuji Nanapaneni  Initial version           |
-- |1.1       12-Jan-2012 Paddy Sanjeevi     Added parameter in send_rpt
-- |1.2       20-Jun-2013 Paddy Sanjeevi     Modified for R12          |
--f +===================================================================+
AS

PROCEDURE send_rpt( p_subject   IN VARCHAR2
                  , p_email     IN VARCHAR2
                  , p_ccmail    IN VARCHAR2
                  , p_text      IN VARCHAR2
                  , p_edid      IN VARCHAR2
		  , p_affidavit IN VARCHAR2
                  ) IS

  v_addlayout           BOOLEAN;
  v_wait                BOOLEAN;
  v_request_id          NUMBER;
  vc_request_id         NUMBER;
  v_file_name           VARCHAR2(50);
  v_dfile_name          VARCHAR2(50);
  v_sfile_name          VARCHAR2(50);
  x_dummy               VARCHAR2(2000);
  v_dphase              VARCHAR2(100);
  v_dstatus             VARCHAR2(100);
  v_phase               VARCHAR2(100);
  v_status              VARCHAR2(100);
  x_cdummy              VARCHAR2(2000);
  v_cdphase             VARCHAR2(100);
  v_cdstatus            VARCHAR2(100);
  v_cphase              VARCHAR2(100);
  v_cstatus             VARCHAR2(100);
  v_copy_file           VARCHAR2(100);

  conn                  utl_smtp.connection;

CURSOR C1 IS
SELECT fl.file_name
     , fl.file_id
     , fl.file_data
     , fl.file_content_type
     , fad.category_description
     , fad.datatype_name
  FROM apps.fnd_lobs fl
     , apps.fnd_attached_docs_form_vl fad
     , apps.qa_plans a
 WHERE a.name            = 'OD_OB_ED'
   AND fad.entity_name   = 'QA_PLANS'
   AND fad.pk1_value     = a.plan_id 
   AND fad.function_name = 'QAPLMDF'
   AND fad.function_type = 'F'
   AND fl.file_id        = fad.media_id;

BEGIN
   
   v_addlayout:= FND_REQUEST.ADD_LAYOUT( template_appl_name => 'XXMER'
                                       , template_code      => 'XXQAENVPI' -- chnage the short name with new report name
                                       , template_language  => 'en' 
                                       , template_territory => 'US' 
                                       , output_format      => 'EXCEL'
                                       );

   IF (v_addlayout) THEN
       fnd_file.put_line(fnd_file.LOG, 'The layout has been submitted');
   ELSE
       fnd_file.put_line(fnd_file.LOG, 'The layout has not been submitted');
   END IF;
   
   v_request_id:= fnd_request.submit_request( application  => 'XXMER'
                                            , program      => 'XXQAENVPI'    
                                            , description  => 'OD: Environmental Product Information Report'
                                            , start_time   => NULL
                                            , sub_request  => FALSE
                                            , argument1    => p_edid
                                            , argument2    => NULL
                                            , argument3    => NULL
                                            , argument4    => NULL
                                            , argument5    => NULL
                                            , argument6    => NULL
                                            , argument7    => NULL
                                            , argument8    => NULL
                                            , argument9    => NULL
                                            , argument10   => NULL
                                            , argument11   => NULL
                                            , argument12   => NULL
                                            , argument13   => NULL
                                            , argument14   => NULL
                                            , argument15   => NULL
                                            , argument16   => NULL
                                            , argument17   => NULL
                                            , argument18   => NULL
                                            , argument19   => NULL
                                            , argument20   => NULL
                                            , argument21   => NULL
                                            , argument22   => NULL
                                            , argument23   => NULL
                                            , argument24   => NULL
                                            , argument25   => NULL
                                            , argument26   => NULL
                                            , argument27   => NULL
                                            , argument28   => NULL
                                            , argument29   => NULL
                                            , argument30   => NULL
                                            , argument31   => NULL
                                            , argument32   => NULL
                                            , argument33   => NULL
                                            , argument34   => NULL
                                            , argument35   => NULL
                                            , argument36   => NULL
                                            , argument37   => NULL
                                            , argument38   => NULL
                                            , argument39   => NULL
                                            , argument40   => NULL
                                            , argument41   => NULL
                                            , argument42   => NULL
                                            , argument43   => NULL
                                            , argument44   => NULL
                                            , argument45   => NULL
                                            , argument46   => NULL
                                            , argument47   => NULL
                                            , argument48   => NULL
                                            , argument49   => NULL
                                            , argument50   => NULL
                                            , argument51   => NULL
                                            , argument52   => NULL
                                            , argument53   => NULL
                                            , argument54   => NULL
                                            , argument55   => NULL
                                            , argument56   => NULL
                                            , argument57   => NULL
                                            , argument58   => NULL
                                            , argument59   => NULL
                                            , argument60   => NULL
                                            , argument61   => NULL
                                            , argument62   => NULL
                                            , argument63   => NULL
                                            , argument64   => NULL
                                            , argument65   => NULL
                                            , argument66   => NULL
                                            , argument67   => NULL
                                            , argument68   => NULL
                                            , argument69   => NULL
                                            , argument70   => NULL
                                            , argument71   => NULL
                                            , argument72   => NULL
                                            , argument73   => NULL
                                            , argument74   => NULL
                                            , argument75   => NULL
                                            , argument76   => NULL
                                            , argument77   => NULL
                                            , argument78   => NULL
                                            , argument79   => NULL
                                            , argument80   => NULL
                                            , argument81   => NULL
                                            , argument82   => NULL
                                            , argument83   => NULL
                                            , argument84   => NULL
                                            , argument85   => NULL
                                            , argument86   => NULL
                                            , argument87   => NULL
                                            , argument88   => NULL
                                            , argument89   => NULL
                                            , argument90   => NULL
                                            , argument91   => NULL
                                            , argument92   => NULL
                                            , argument93   => NULL
                                            , argument94   => NULL
                                            , argument95   => NULL
                                            , argument96   => NULL
                                            , argument97   => NULL
                                            , argument98   => NULL
                                            , argument99   => NULL
                                            , argument100  => NULL
                                            );
   IF v_request_id > 0 THEN
       COMMIT;
       v_file_name  := 'XXQAENVPI_'||TO_CHAR(v_request_id)||'_1.EXCEL';
       v_sfile_name := p_edid||'_'||TO_CHAR(SYSDATE,'MMDDYY')||'.xls';
       v_dfile_name := '$XXMER_DATA/outbound/'||v_sfile_name;
       
   END IF;

   IF (FND_CONCURRENT.WAIT_FOR_REQUEST( v_request_id,1,60000,v_phase
                                      , v_status,v_dphase,v_dstatus,x_dummy
									  )
      )  THEN
       IF v_dphase = 'COMPLETE' THEN
       
           v_copy_file := '$APPLCSF/$APPLOUT/'||v_file_name;
           vc_request_id:=FND_REQUEST.SUBMIT_REQUEST('XXFIN','XXCOMFILCOPY','OD: Common File Copy',NULL,FALSE,
	    			  v_copy_file,v_dfile_name,NULL,NULL,NULL,NULL,NULL,
	   			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
	   			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
	   			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
	   			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
	   			  NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
			          NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
           /*
           vc_request_id:= fnd_request.submit_request( application  => 'XXFIN'
                                                     , program      => 'XXCOMFILCOPY'    
                                                     , description  => 'OD: Common File Copy'
                                                     , start_time   => NULL
                                                     , sub_request  => FALSE
                                                     , argument1    => v_copy_file
                                                     , argument2    => v_dfile_name
                                                     , argument3    => NULL
                                                     , argument4    => NULL
                                                     , argument5    => NULL
                                                     , argument6    => NULL
                                                     , argument7    => NULL
                                                     , argument8    => NULL
                                                     , argument9    => NULL
                                                     , argument10   => NULL
                                                     , argument11   => NULL
                                                     , argument12   => NULL
                                                     , argument13   => NULL
                                                     , argument14   => NULL
                                                     , argument15   => NULL
                                                     , argument16   => NULL
                                                     , argument17   => NULL
                                                     , argument18   => NULL
                                                     , argument19   => NULL
                                                     , argument20   => NULL
                                                     , argument21   => NULL
                                                     , argument22   => NULL
                                                     , argument23   => NULL
                                                     , argument24   => NULL
                                                     , argument25   => NULL
                                                     , argument26   => NULL
                                                     , argument27   => NULL
                                                     , argument28   => NULL
                                                     , argument29   => NULL
                                                     , argument30   => NULL
                                                     , argument31   => NULL
                                                     , argument32   => NULL
                                                     , argument33   => NULL
                                                     , argument34   => NULL
                                                     , argument35   => NULL
                                                     , argument36   => NULL
                                                     , argument37   => NULL
                                                     , argument38   => NULL
                                                     , argument39   => NULL
                                                     , argument40   => NULL
                                                     , argument41   => NULL
                                                     , argument42   => NULL
                                                     , argument43   => NULL
                                                     , argument44   => NULL
                                                     , argument45   => NULL
                                                     , argument46   => NULL
                                                     , argument47   => NULL
                                                     , argument48   => NULL
                                                     , argument49   => NULL
                                                     , argument50   => NULL
                                                     , argument51   => NULL
                                                     , argument52   => NULL
                                                     , argument53   => NULL
                                                     , argument54   => NULL
                                                     , argument55   => NULL
                                                     , argument56   => NULL
                                                     , argument57   => NULL
                                                     , argument58   => NULL
                                                     , argument59   => NULL
                                                     , argument60   => NULL
                                                     , argument61   => NULL
                                                     , argument62   => NULL
                                                     , argument63   => NULL
                                                     , argument64   => NULL
                                                     , argument65   => NULL
                                                     , argument66   => NULL
                                                     , argument67   => NULL
                                                     , argument68   => NULL
                                                     , argument69   => NULL
                                                     , argument70   => NULL
                                                     , argument71   => NULL
                                                     , argument72   => NULL
                                                     , argument73   => NULL
                                                     , argument74   => NULL
                                                     , argument75   => NULL
                                                     , argument76   => NULL
                                                     , argument77   => NULL
                                                     , argument78   => NULL
                                                     , argument79   => NULL
                                                     , argument80   => NULL
                                                     , argument81   => NULL
                                                     , argument82   => NULL
                                                     , argument83   => NULL
                                                     , argument84   => NULL
                                                     , argument85   => NULL
                                                     , argument86   => NULL
                                                     , argument87   => NULL
                                                     , argument88   => NULL
                                                     , argument89   => NULL
                                                     , argument90   => NULL
                                                     , argument91   => NULL
                                                     , argument92   => NULL
                                                     , argument93   => NULL
                                                     , argument94   => NULL
                                                     , argument95   => NULL
                                                     , argument96   => NULL
                                                     , argument97   => NULL
                                                     , argument98   => NULL
                                                     , argument99   => NULL
                                                     , argument100  => NULL
                                                    );
               */
           IF vc_request_id > 0 THEN
               COMMIT;
           END IF;

 	       IF (fnd_concurrent.wait_for_request( request_id  => vc_request_id
 	                                          , interval    => 1
 	                                          , max_wait    => 60000
 	                                          , phase       => v_cphase
 	                                          , status      => v_cstatus
 	                                          , dev_phase   => v_cdphase
 	                                          , dev_status  => v_cdstatus
 	                                          , message     => x_cdummy
 	                                          )
 	          ) THEN                                                     
	
	           IF v_cdphase = 'COMPLETE' THEN  -- child 
	 
	               IF lc_send_mail = 'Y' THEN
                           conn := xx_pa_pb_mail.begin_mail( sender        => 'OD-OB-QualityTeam@officedepot.com'
                                                           , recipients    => p_email
                                                           , cc_recipients => p_ccmail
                                                           , subject       => p_subject
                                                           , mime_type     => xx_pa_pb_mail.MULTIPART_MIME_TYPE
                                                           );
       	               ELSE
	                   conn := xx_pa_pb_mail.begin_mail( sender        => 'OD-OB-QualityTeam@officedepot.com'
	                                                   , recipients    => 'padmanaban.sanjeevi@officedepot.com'
	                                                   , cc_recipients => 'padmanaban.sanjeevi@officedepot.com'  -- Modified for R12
	                                                   , subject       =>  p_subject
	                                                   , mime_type     =>  xx_pa_pb_mail.MULTIPART_MIME_TYPE
	                                                   );
	               END IF;
		
		       IF p_affidavit LIKE 'Y%' THEN 

    	                  FOR Cf IN C1 LOOP
                              xx_pa_pb_mail.xx_attch_doc( conn        => conn
                                                        , p_filename  => cf.file_name
                                                        , p_blob      => cf.file_data
                                                        , p_mime_type => cf.file_content_type
                                                        ); 	          
                          END LOOP;
		
		       END IF;

                       xx_pa_pb_mail.xx_attch_rpt( conn        => conn
                                                 , p_filename => v_sfile_name
                                                 );
                       xx_pa_pb_mail.end_attachment(conn    => conn);
                       xx_pa_pb_mail.attach_text( conn      => conn
                                                , data      => p_text
                                                , mime_type => 'multipart/html'
                                                );

                       xx_pa_pb_mail.end_mail( conn => conn );


	           END IF; --IF v_cdphase = 'COMPLETE' THEN -- child

 	       END IF; --IF (FND_CONCURRENT.WAIT_FOR_REQUEST(vc_request_id,1,60000,v_cphase,

       END IF; -- IF v_dphase = 'COMPLETE' THEN  -- Main

   END IF; -- IF (FND_CONCURRENT.WAIT_FOR_REQUEST -- Main
   COMMIT;   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found for send rpt ');
       
   WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others Raised in send_rpt : '||SQLERRM);
END send_rpt;

PROCEDURE xx_ed_process( x_errbuf      OUT NOCOPY VARCHAR2
                       , x_retcode     OUT NOCOPY VARCHAR2
		       ) IS

CURSOR c_ed_status IS
    SELECT a.plan_id
         , a.organization_id
         , a.occurrence
         , a.od_ob_edid
         , a.od_sc_entry_date
         , a.od_ob_issue_type
         , a.od_ob_vendor_name
         , a.od_sc_vend_email
         , a.od_pb_qa_requester
         , a.od_ob_engr_ntfy
         , a.od_ob_aprsts_ntfy  --30 days
         , a.od_pb_date_verified
         , a.od_ob_pfd_ntfy --45 days
	 , a.od_ob_dispute_yn affidavit
      FROM apps.q_od_ob_ed_v     a
     WHERE a.od_sc_entry_date IS NOT NULL;

CURSOR c_ed_sku_status (p_ed_id IN VARCHAR2 )  IS
    SELECT b.od_ob_sku
         , b.od_pb_item_desc
         , b.od_ob_vpn vpn
         , b.od_ob_ref_edid
      FROM apps.q_od_ob_ed_sku_v b
     WHERE od_ob_ref_edid = p_ed_id;

 conn               utl_smtp.connection;
 v_email_list       VARCHAR2(3000);
 v_cc_email_list    VARCHAR2(3000);
 v_text             VARCHAR2(3000);
 v_sku_text         VARCHAR2(3000);
 v_subject          VARCHAR2(3000);
 v_region_contact   VARCHAR2(250);
 v_region           VARCHAR2(50);
 v_nextaudit_date   DATE;
 v_errbuf           VARCHAR2(2000);
 v_retcode          VARCHAR2(50);
 v_fqa_esc          VARCHAR2(150);
 v_instance         VARCHAR2(10);
 
BEGIN

   SELECT name INTO v_instance FROM v$database;

   FOR cur IN c_ed_status LOOP

       v_text := NULL;
       v_sku_text := NULL;
       
       v_text   :=v_text || 'EDID               : '||cur.od_ob_edid                   || chr(10);   
       v_text   :=v_text || 'Entry Date         : '||TO_CHAR(cur.od_sc_entry_date)    || chr(10); 
       v_text   :=v_text || 'Vendor Name        : '||cur.od_ob_vendor_name            || chr(10);
       v_text   :=v_text || 'Issue              : '||cur.od_ob_issue_type             || chr(10);
       v_text   :=v_text ||chr(10);
       
       FOR sku_cur IN c_ed_sku_status(cur.od_ob_edid) LOOP

           v_sku_text   :=v_sku_text || 'SKU                : '||TO_CHAR(sku_cur.od_ob_sku)           || chr(10);		
           v_sku_text   :=v_sku_text || 'Description        : '||(sku_cur.od_pb_item_desc)            || chr(10);       
           v_sku_text   :=v_sku_text || 'VPN                : '||(sku_cur.vpn);						
           v_sku_text   :=v_sku_text ||chr(10);
           v_sku_text   :=v_sku_text ||chr(10);
           
       END LOOP;

	   IF v_sku_text IS NOT NULL THEN
	      v_text := v_text  ||chr(10) || 'SKU INFO '||chr(10);
              v_text :=v_text || v_sku_text;
           END IF;


           IF lc_send_mail = 'Y' THEN    
               v_email_list:= cur.od_pb_qa_requester||';'||cur.od_sc_vend_email;          
           ELSE       
               v_email_list    := 'padmanaban.sanjeevi@officedepot.com';   -- Modified for R12
               v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
           END IF;
  
           IF NVL(cur.OD_OB_ENGR_NTFY,'X') <> 'Y' THEN          
           
               v_subject := 'EDID '||cur.od_ob_edid ||' : Please complete the attached document and return';
           
               IF v_instance <>'GSIPRDGB' THEN
                   v_subject:='Please Ignore this mail :'||v_subject;
               END IF;

               send_rpt( p_subject   => v_subject
                       , p_email     => v_email_list
                       , p_ccmail    => v_cc_email_list
                       , p_text      => v_text
                       , p_edid      => cur.od_ob_edid
		       , p_affidavit => cur.affidavit
                       );        

  	       UPDATE apps.qa_results  
                  SET character13     = 'Y'
                WHERE plan_id         = cur.plan_id
                  AND occurrence      = cur.occurrence
	          AND organization_id = cur.organization_id;


           ELSIF (SYSDATE - cur.od_sc_entry_date) > 45  AND cur.od_pb_date_verified IS NULL
             AND NVL(cur.od_ob_pfd_ntfy,'X') <>'45' THEN
           
               v_subject :='EDID '||cur.od_ob_edid ||'Environmental Discrepancies is still open more than 45 days';

           IF lc_send_mail = 'Y' THEN    
               v_email_list:= cur.od_pb_qa_requester||':'||cur.od_sc_vend_email;          
           ELSE       
               v_email_list    := 'padmanaban.sanjeevi@officedepot.com';   -- Modified for R12
               v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
           END IF;

    
               IF v_instance <>'GSIPRDGB' THEN
	           v_subject:= 'Please Ignore this mail :' || v_subject;
               END IF;
           
               -- Calling Notifaction proc
               xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                              , p_email_list    => v_email_list
                                              , p_cc_email_list => v_cc_email_list
                                              , p_text          => v_text
                                              );

  	       UPDATE apps.qa_results  
                  SET character15     = '45'
                WHERE plan_id         = cur.plan_id
                  AND occurrence      = cur.occurrence
	          AND organization_id = cur.organization_id;

           ELSIF (SYSDATE - cur.od_sc_entry_date) > 30 AND cur.od_pb_date_verified IS NULL
             AND NVL(cur.od_ob_aprsts_ntfy,'X') <> '30' THEN

               v_subject :='EDID '||cur.od_ob_edid ||'Environmental Discrepancies is still open more than 30 days';
    
               IF v_instance <> 'GSIPRDGB' THEN
	           v_subject:='Please Ignore this mail :'||v_subject;
               END IF;
               
               IF lc_send_mail = 'Y' THEN    
	           v_email_list:= cur.od_pb_qa_requester||':'||cur.od_sc_vend_email;          
	       ELSE       
	           v_email_list    := 'padmanaban.sanjeevi@officedepot.com';  -- Modified for R12
	           v_cc_email_list := 'Fritz.Lutzy@officedepot.com';	  
	       END IF;


               -- Calling Notifaction proc
               xx_qa_fqa_pkg.send_notification( p_subject       => v_subject
                                              , p_email_list    => v_email_list
                                              , p_cc_email_list => v_cc_email_list
                                              , p_text          => v_text
                                              );
  	       UPDATE apps.qa_results  
                  SET character14     = '30'
                WHERE plan_id         = cur.plan_id
                  AND occurrence      = cur.occurrence
	          AND organization_id = cur.organization_id;

           END IF;           
   END LOOP;
   COMMIT;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'NO Data Found in xx_ed_process ');
       
   WHEN OTHERS THEN
       FND_FILE.PUT_LINE(FND_FILE.LOG,'When Others raised in xx_ed_process : '||SQLERRM);
       commit;
       v_errbuf  := 'Error in When others :'||SQLERRM;
       v_retcode := SQLCODE;
       
END xx_ed_process;
END XX_QA_ED_PKG;
/
SHOW ERRORS PACKAGE BODY XX_QA_ED_PKG;
  
--EXIT;
