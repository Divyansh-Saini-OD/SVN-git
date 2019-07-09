create or replace 
PACKAGE BODY xx_int_err_notificatn_pkg
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |           
-- +===================================================================+
-- | Name  : XXINTERRORNOTIFYPKG.PKB                                   |
-- | Description      : Package Body                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version    Date          Author           Remarks                  |
-- |=======    ==========    =============    ======================== |
-- |DRAFT 1A   16-MAR-2015   Saritha M        Initial draft version    |
-- |1.1        16-Apr-2015   Sai Kiran        Changes to the Email format as per Defect#34188|
-- |1.2        19-Oct-2015   Madhu Bolli      Remove schema for 12.2 retrofit |
-- |1.3        19-Oct-2015   Madhu Bolli      Replaced the datatype of l_item_code to CLOB |
-- |            							  from varchar2(500) as the storage value |
-- |1.4        03-OCT-2017   Suresh Naragam   Changes for the defect#43330            |
-- |1.5        04-MAR-2018   Venkateshwar Panduga ITEM ERROR Report should show all   |
-- |            |                                    RMS-EBS ITEM Interface Error for the Defect # 44629       |
-- |2.0     08-JUL-2019   Venkateshwar Panduga    Change output files generation path     |
-- |                                               for LNS                        |
 
-- |            |
-- |                                                                   |
-- +===================================================================+

-- int_interface procedure will extract the items based on orders stuck in interface
   PROCEDURE int_interface (
      retcode        OUT   NUMBER,
      errbuf         OUT   VARCHAR2      
   )
   IS
      L_MASTER_ITEM         VARCHAR2 (1000) := NULL;
      l_item_code           clob  := NULL;   -- 1.3
      l_count               NUMBER          := 0;
      p_status              VARCHAR2 (10);
      lc_error_message      VARCHAR2 (1000);
      l_loc_cnt             NUMBER          := 0;
      l_child_item          VARCHAR2 (1000) := NULL;
      l_loc                 VARCHAR2 (1000) := NULL;
      l_organization_name   VARCHAR2 (1000) := NULL;
      l_child_item_code       CLOB            := NULL; 
      l_check          varchar2(1):='Y';
      l_email_list          VARCHAR2(2000) := NULL;
      L_CHECK_STATUS        VARCHAR2(20):='Y';
      
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
--    V_LOCATION        VARCHAR2 (200) := 'XXFIN_OUTBOUND_GLEXTRACT';   ---Commented for V2.0
    V_LOCATION        VARCHAR2 (200); ---Added for V2.0
    V_MODE            VARCHAR2 (1)       := 'W'; 
    L_MASTER_CNT NUMBER := 0;
    L_CHILD_CNT NUMBER := 0;
   
  ---- End Defect #44629   

      CURSOR order_stuck
      IS
         SELECT DISTINCT m.MESSAGE_TEXT
                    FROM oe_headers_iface_all h,
                         oe_processing_msgs_vl m
                   WHERE 1 = 1
                     AND h.error_flag = 'Y'
                     AND h.orig_sys_document_ref = m.original_sys_document_ref
                     AND h.order_source_id = m.order_source_id
                     AND (   SUBSTR (m.MESSAGE_TEXT, 1, 8) = '10000018'
                          OR SUBSTR (m.MESSAGE_TEXT, 1, 8) = '10000017'
                         )
                     AND NOT EXISTS ( SELECT 1 
                                        FROM  oe_lines_iface_all l
   				       WHERE  L.INVENTORY_ITEM IN ('LB','INCOMM FEES 2','INCOMM FEES 5','INCOMM FEES 1','INCOMM FEES 3')
					 AND L.ORIG_SYS_DOCUMENT_REF= H.ORIG_SYS_DOCUMENT_REF) ;   
           
------------------------------ Below code added for Defect#44629
---------- Below cursor is used for ITEM CREATION DATA ERROR          
          CURSOR cur_item_cre
          IS
          SELECT DISTINCT XXIIMI.ITEM, XXIIMI.ACTION_TYPE, XXIIMI.CLASS, XXIIMI.DEPT, XXIIMI.SUBCLASS, XXIIMI.STATUS, XXIIMI.PROCESS_FLAG, XXIIMI.ERROR_MESSAGE
                        FROM XX_INV_ITEM_MASTER_INT XXIIMI
                        WHERE 1=1
                        AND XXIIMI.ERROR_MESSAGE IS NOT NULL
                        AND XXIIMI.ACTION_TYPE != 'C'
                        AND NOT EXISTS (SELECT MSIB.SEGMENT1
                                        FROM MTL_SYSTEM_ITEMS_B MSIB
                                        WHERE 1=1
                                        AND MSIB.ORGANIZATION_ID = 441
                                        AND MSIB.SEGMENT1 = XXIIMI.ITEM)
                        ORDER BY XXIIMI.ITEM DESC ;

---------- Below cursor is used for ITEM-LOC DATA ERROR
              CURSOR ITEM_LOC_ERR_CUR
              IS
              select distinct xxiili.item,xxiili.loc,xxiili.action_type,xxiili.process_flag,xxiili.status,xxiili.error_message
              from XX_INV_ITEM_LOC_INT xxiili
              where 1=1
              and xxiili.error_message is not null
              and xxiili.action_type != 'C'
              and not exists (select msib.segment1, msib.organization_id
                              from MTL_SYSTEM_ITEMS_B msib
                              where 1=1
                              --and msib.organization_id = 441
                              and msib.segment1 = xxiili.item
                              and msib.organization_id = (select ood.organization_id
                                                          from ORG_ORGANIZATION_DEFINITIONS ood
                                                          where 1=1
                                                          AND OOD.ORGANIZATION_NAME LIKE LPAD(XXIILI.LOC,6,0)||'%'))
              ORDER BY XXIILI.ITEM ;

--- End for Defect#44629

   begin
 ---Below code commented for V2.0  
   /*
--    SELECT NAME
--	  INTO LC_INSTANCE
--    FROM v$database;
  ---*/
 --- End for V2.0 
   --- Added for V2.0   
     select SYS_CONTEXT('userenv','DB_NAME')
		into LC_INSTANCE
		from DUAL; 
 ----   End For V2.0  
    
    V_FILENAME1   :=  'HVOP_Master_Item_Creation_Error_'||LC_INSTANCE||'.txt' ;  
    V_FILENAME2   :=  'HVOP_Item_Location_Assignment_Error_'||LC_INSTANCE||'.txt' ;
    V_FILENAME3   :=  'RMS_Item_Creation_Error_'||LC_INSTANCE||'.txt' ;
    V_FILENAME4   :=  'RMS_Item_Location_Error_'||LC_INSTANCE||'.txt' ;
    
      L_MASTER_ITEM := null;
 --Below code is added for V2.0     
  begin    
   	  select TARGET_VALUE1 ,TARGET_VALUE10
    INTO l_email_list ,V_LOCATION
	    FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
	   WHERE def.translate_id=val.translate_id
	     AND   def.translation_name = 'XX_OM_INV_NOTIFICATION';
	  EXCEPTION 
    when OTHERS then
	     V_LOCATION := 'XXFIN_OUT';
       
          end;   
-------- End  for V2.0    

      FOR order_stuck_rec IN order_stuck
      LOOP
      
         IF SUBSTR (order_stuck_rec.MESSAGE_TEXT, 1, 8) = '10000017'
         THEN
         -- CHID#34188 Start
           -- l_master_item := SUBSTR (order_stuck_rec.MESSAGE_TEXT, 36, 6);
            l_master_item :=SUBSTR(order_stuck_rec.MESSAGE_TEXT,(INSTR(order_stuck_rec.MESSAGE_TEXT,':',1,1)+27),(INSTR(order_stuck_rec.MESSAGE_TEXT,'Solution:',1,1)-(INSTR(order_stuck_rec.MESSAGE_TEXT,':',1,1)+27)));
            -- CHID#34188 End
            fnd_file.put_line (fnd_file.LOG,
                               'Item information..' || l_master_item
                              );

            SELECT COUNT (1)
              INTO l_count
              FROM xx_inv_item_master_int
             WHERE item = l_master_item;

            IF l_count = 0
            THEN
            
            IF L_MASTER_CNT =0 THEN
               V_MODE := 'W' ;
             ELSE
              V_MODE := 'A';
            END IF;   
            L_CHECK_STATUS:='N';
                     
--- Below code is commented for Defect#44629                     
               L_ITEM_CODE := SUBSTR(ORDER_STUCK_REC.MESSAGE_TEXT,(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,':',1,1)+2),
                          (INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,'Solution:',1,1)-(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,':',1,1)+2)))|| UTL_TCP.CRLF;
                          
          V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME1, v_mode);
           UTL_FILE.PUT_LINE (V_FILEHANDLE, L_ITEM_CODE);
           UTL_FILE.FCLOSE (V_FILEHANDLE);             
                       
---- CHID#34188 End
--- End Defect#44629 
l_master_cnt := 1;
            END IF;
         END IF;                                 

         IF SUBSTR (order_stuck_rec.MESSAGE_TEXT, 1, 8) = '10000018'
         THEN
         -- CHID#34188 Start
           -- l_child_item := SUBSTR (order_stuck_rec.MESSAGE_TEXT, 16, 6);
--            l_loc:=  LTRIM(SUBSTR(SUBSTR(order_stuck_rec.MESSAGE_TEXT,INSTR(order_stuck_rec.MESSAGE_TEXT,'W',1,1)),
--  		    INSTR(SUBSTR(order_stuck_rec.MESSAGE_TEXT,INSTR(order_stuck_rec.MESSAGE_TEXT,'W',1,1)),'0',1),6),'0');
          l_child_item := SUBSTR (order_stuck_rec.MESSAGE_TEXT, INSTR(order_stuck_rec.MESSAGE_TEXT,' ',1,2)+1,INSTR(order_stuck_rec.MESSAGE_TEXT,' ',1,3)-(INSTR(order_stuck_rec.MESSAGE_TEXT,' ',1,2)+1) );
          l_loc:=  trunc(SUBSTR(order_stuck_rec.MESSAGE_TEXT,(INSTR(order_stuck_rec.MESSAGE_TEXT,'Warehouse',1,1)+9),INSTR(order_stuck_rec.MESSAGE_TEXT,':',2,1)-2),'0');
           -- CHID#34188 End
            BEGIN
               SELECT b.organization_name
                 INTO l_organization_name
                 FROM hr_all_organization_units a,
                      org_organization_definitions b
                WHERE a.organization_id = b.organization_id
                  AND a.attribute1 = l_loc;
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line (fnd_file.LOG, 'No Data found for organization');
                  p_status := 'N';
            END;

            SELECT COUNT (1)
              INTO l_loc_cnt
              FROM xx_inv_item_loc_int
             WHERE item = l_child_item AND loc = l_loc;

            IF l_loc_cnt = 0
            THEN
               L_CHECK:='N';
--- Below statment is added for Defect#44629               
              IF l_child_cnt =0 THEN
               V_MODE := 'W' ;
             ELSE
              V_MODE := 'A';
            END IF; 
--- Below code is commented for Defect#44629                    
               L_CHILD_ITEM_CODE := SUBSTR(ORDER_STUCK_REC.MESSAGE_TEXT,(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,':',1,1)+2),
                      (INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,'Solution:',1,1)-(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,':',1,1)+2)))|| UTL_TCP.crlf;
                --  || CHR (10)
-- CHID#34188 Start
--                  || 'Item Code :'  --Commented and added as part of Defect#34188
--                  || l_child_item
--                  || CHR (10)
--                  || 'Location :'
--                  || l_organization_name
--                  || CHR (10)
--                  || RPAD ('-', 60, '-');
--                    || SUBSTR(ORDER_STUCK_REC.MESSAGE_TEXT,(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,':',1,1)+2),(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,'Solution:',1,1)-(INSTR(ORDER_STUCK_REC.MESSAGE_TEXT,':',1,1)+2)))
--                    ||'.'|| UTL_TCP.crlf;
-- CHID#34188 End
V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME2, v_mode);
           UTL_FILE.PUT_LINE (V_FILEHANDLE, L_CHILD_ITEM_CODE);
           UTL_FILE.FCLOSE (V_FILEHANDLE);  
--- End for Defect#44629 
l_child_cnt  := 1;
            END IF;
         END IF;
      END LOOP;
      
  IF L_ITEM_CODE IS NULL
  THEN
  V_MODE := 'W';
   V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME1, v_mode);
           UTL_FILE.PUT_LINE (V_FILEHANDLE, 'No Action Required to trigger the Master Items');
           UTL_FILE.FCLOSE (V_FILEHANDLE);   
  END IF;
  
   IF L_CHILD_ITEM_CODE IS NULL
  THEN
   v_mode := 'W';
   V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME2, V_MODE);
           UTL_FILE.PUT_LINE (V_FILEHANDLE, 'No Action Required to trigger the Item Location Assignment Error');
           UTL_FILE.FCLOSE (V_FILEHANDLE);   
  END IF;
  
------------- Below code added for Defect#44629    
---
   V_FILEHANDLE := null;
   V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME3, 'W');
       FOR I IN CUR_ITEM_CRE
       LOOP
               
        L_ITEM_CREATION_CHECK := 'N';
          L_ITEM_CREATION_CODE  :=  'Item :  '
                                   ||I.ITEM     || ','
                                   ||'     Error Message : '  
                                   ||I.ERROR_MESSAGE || UTL_TCP.crlf;
       
           UTL_FILE.PUT_LINE (V_FILEHANDLE,L_ITEM_CREATION_CODE);
                                         
             
       END LOOP;
      IF L_ITEM_CREATION_CODE IS NULL
      THEN
       L_ITEM_CREATION_CHECK := 'Y';
       L_ITEM_CREATION_CODE := 'No Action is requried for RMS Item creation errors';
       UTL_FILE.PUT_LINE (V_FILEHANDLE,L_ITEM_CREATION_CODE);
       END IF;
       
    UTL_FILE.FCLOSE (V_FILEHANDLE);    
-----  
  V_FILEHANDLE := NULL;
   V_FILEHANDLE :=UTL_FILE.FOPEN (RTRIM (V_LOCATION, '/'), V_FILENAME4, 'W');
      FOR rec_loc_err IN ITEM_LOC_ERR_CUR 
       LOOP
        L_ITEM_CREATION_CHECK := 'N';
        
         L_ITEM_LOC_ERR_CODE  := 'Item :  '
                                   ||REC_LOC_ERR.ITEM || ','    
                                   ||'     Location : ' 
                                   ||REC_LOC_ERR.LOC || ','  
                                   ||'     Error Message : ' 
                                   ||REC_LOC_ERR.ERROR_MESSAGE || UTL_TCP.crlf;
     
           UTL_FILE.PUT_LINE (V_FILEHANDLE,L_ITEM_LOC_ERR_CODE);
        
       END LOOP;
        IF L_ITEM_LOC_ERR_CODE IS NULL
      THEN
       L_ITEM_CREATION_CHECK := 'Y';
       L_ITEM_LOC_ERR_CODE := 'No Action is requried for RMS Item location errors';
       UTL_FILE.PUT_LINE (V_FILEHANDLE,L_ITEM_LOC_ERR_CODE);
       END IF;
       
     UTL_FILE.FCLOSE (V_FILEHANDLE);

--------- End Defect#44629
--  IF l_check_status='Y' then
--  
--  l_item_code :='No Action Required to trigger the Master Items';
--  END IF;
--      IF L_CHECK='N' 
--         OR L_ITEM_CREATION_CHECK = 'N'  --
--      THEN
-----Below code is commented for V2.0
/*         begin      
	  select TARGET_VALUE1
    INTO l_email_list 
	    FROM xx_fin_translatedefinition def,xx_fin_translatevalues val
	   WHERE def.translate_id=val.translate_id
	     AND   def.translation_name = 'XX_OM_INV_NOTIFICATION';
	  EXCEPTION WHEN NO_DATA_FOUND THEN
	                 NULL;
          end; */
----End code for V2.0          
        FND_FILE.PUT_LINE(FND_FILE.LOG,' Before calling Email Notification ' );
              
              
----- Below code is commented for Defect#44629
--         int_error_mail_msg (l_item_code,
--                             L_CHILD_ITEM_CODE,
--                            l_email_list,
--                             p_status
--                            );
------ End for Defect#44629
---- Below code is added for Defect#44629

    
        
        IF lc_instance = 'GSIPRDGB' 
        THEN
       -- l_text := 'Item not assigned to location ';
         l_text := 'Item Interface error reports ';
        ELSE
--        L_TEXT :='Please Ignore this email: Item not assigned to location ';
        L_TEXT :='Please Ignore this email: Item Interface error reports ';
        END IF;
   fnd_file.put_line(fnd_file.log,'Before sending mail');        
    SEND_MAIL_PRC (
      LC_MAIL_FROM ,
      l_email_list,
      L_TEXT,
      L_MESSAGE
      || CHR (13),
      V_FILENAME1||','||V_FILENAME2||','||V_FILENAME3||','||V_FILENAME4,
      V_LOCATION                               --default null
   ) ; 
 fnd_file.put_line(fnd_file.log,' After calling Email Notification ' );       
 FND_FILE.PUT_LINE(FND_FILE.LOG,'Email Notification Successfully Sent To:' || NVL(L_EMAIL_LIST,'NO MAIL ADDRESS SETUP'));

---- End for Defect#44629
--         fnd_file.put_line(fnd_file.log,' After calling Email Notification ' );
--          IF p_status = 'Y' THEN
--          fnd_file.put_line(fnd_file.log,'Email Notification Successfully Sent To:' || NVL(l_email_list,'NO MAIL ADDRESS SETUP'));
--          ELSE
--         fnd_file.put_line(fnd_file.log,'Error during Email Notification:'|| SQLERRM);
--          END IF;                              
--      ELSE
--         fnd_file.put_line (fnd_file.LOG, 'Email notification not required - No data to be triggered from RMS.....');
--      END IF;

      retcode := 0;
      ERRBUF := 'Y';

---- Added logic for 2.0
begin
FND_FILE.PUT_LINE(FND_FILE.log,' Before removing files ' ); 

UTL_FILE.FREMOVE (
location => V_LOCATION       ,    -----in varchar2,
FILENAME =>V_FILENAME1         -----IN VARCHAR2
);

UTL_FILE.FREMOVE (
location => V_LOCATION       ,    -----in varchar2,
FILENAME =>V_FILENAME2         -----IN VARCHAR2
);

UTL_FILE.FREMOVE (
location => V_LOCATION       ,    -----in varchar2,
FILENAME =>V_FILENAME3         -----IN VARCHAR2
);

UTL_FILE.FREMOVE (
location => V_LOCATION       ,    -----in varchar2,
FILENAME =>V_FILENAME4         -----IN VARCHAR2
);
FND_FILE.PUT_LINE(FND_FILE.log,' After removing files ' ); 
exception
when OTHERS then
FND_FILE.PUT_LINE(FND_FILE.log,'Error while removing file: '||SQLERRM);
end;

--- End logic for 2.0      
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

-- Procedure  to send Email notification to RMS team to trigger the items
--   PROCEDURE int_error_mail_msg (
--      P_MASTER_DATA        IN       VARCHAR2,
--      P_CHILD_ITEM_CODE    IN       clob,
--      p_email_list         IN       VARCHAR2,
--      x_mail_sent_status   OUT      VARCHAR2
--   )
--   IS
--      lc_mail_from        VARCHAR2 (100)      := 'noreply@officedepot.com';
--      lc_mail_recipient   VARCHAR2 (1000);
--      lc_mail_subject     VARCHAR2 (1000)
--                                      := 'Items and Orgs data stuck in Interface';
----commented as part of Defect#34188 and fetching the Server name from Profile.
--      lc_mail_host        VARCHAR2 (100)      := fnd_profile.value('XX_COMN_SMTP_MAIL_SERVER'); --'USCHMSX83.na.odcorp.net';
--      lc_mail_conn        UTL_SMTP.connection;
--      crlf                VARCHAR2 (10)       := CHR (13) || CHR (10);
--      slen                NUMBER              := 1;
--      v_addr              VARCHAR2 (1000);
--      lc_instance         VARCHAR2 (100);
--      l_text              VARCHAR2(2000)  := NULL;
--   BEGIN
--   fnd_file.put_line(fnd_file.log,' Before calling Email Notification ' );
--      lc_mail_conn := UTL_SMTP.open_connection (lc_mail_host, 25);
--      lc_mail_recipient := p_email_list;
--      UTL_SMTP.helo (lc_mail_conn, lc_mail_host);
--      UTL_SMTP.MAIL (LC_MAIL_CONN, LC_MAIL_FROM);
--      IF (INSTR (lc_mail_recipient, ',') = 0)
--      THEN
--         v_addr := lc_mail_recipient;
--         UTL_SMTP.rcpt (lc_mail_conn, v_addr);
--      ELSE
--         lc_mail_recipient := REPLACE (lc_mail_recipient, ' ', '_') || ',';
--
--         WHILE (INSTR (lc_mail_recipient, ',', slen) > 0)
--         LOOP
--            v_addr :=
--               SUBSTR (lc_mail_recipient,
--                       slen,
--                       INSTR (SUBSTR (lc_mail_recipient, slen), ',') - 1
--                      );
--            slen := slen + INSTR (SUBSTR (lc_mail_recipient, slen), ',');
--            UTL_SMTP.rcpt (lc_mail_conn, v_addr);
--         END LOOP;
--      END IF;     
--        
--        SELECT NAME
--	  INTO lc_instance
--           FROM v$database;  
--        
--        IF lc_instance = 'GSIPRDGB' 
--        THEN
--        l_text := 'Item not assigned to location ';
--        ELSE
--        l_text :='Please Ignore this email: Item not assigned to location ';
--        END IF;
--
--      lc_mail_subject :=
--                  l_text  || ' ' || lc_instance;
--      UTL_SMTP.DATA
--         (lc_mail_conn,
--             'From:'
--          || lc_mail_from
--          || UTL_TCP.crlf
--          || 'To: '
--          || v_addr
--          || UTL_TCP.crlf
--          || 'Subject: '
--          || lc_mail_subject
--          || UTL_TCP.crlf
--          || 'RMS Team,'
--          || crlf
--          || crlf
--          || crlf
--          || 'Sales Orders are stuck in EBS as below items are either not created or assigned to their corresponding location.'
--          || crlf
--          || crlf
--          ||'Current Impact: Revenue Impact - Unable to process Sales orders'
--          || crlf
--          || crlf
--          || '-------------------------------------------------------------------------------------------------'
--          || crlf
--          || 'Master Item Creation Request for EBS - '||lc_instance
--          || crlf
--          || '-------------------------------------------------------------------------------------------------'        
--          || crlf                
--          || p_master_data
--          || crlf
--          || crlf
--          || '-------------------------------------------------------------------------------------------------'
--	  || crlf
--	  || 'Location Item assignment Request for EBS - '||lc_instance
--	  || crlf
--          || '-------------------------------------------------------------------------------------------------'          
--          || crlf         
--          || P_CHILD_ITEM_CODE 
--          || CRLF
--          || crlf
--         
--             );
--         
--      UTL_SMTP.quit (lc_mail_conn);
--      x_mail_sent_status := 'Y';
--   EXCEPTION
--      WHEN UTL_SMTP.transient_error OR UTL_SMTP.permanent_error
--      THEN
--         raise_application_error (-20000, 'Unable to send mail: ' || SQLERRM);
--      WHEN OTHERS
--      THEN
--         fnd_file.put_line (fnd_file.LOG,'Unable to send mail..:'|| SQLERRM);   
--   END INT_ERROR_MAIL_MSG;
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
