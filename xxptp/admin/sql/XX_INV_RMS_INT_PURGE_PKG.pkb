SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_INV_RMS_INT_PURGE_PKG
-- +====================================================================================+
-- |                  Office Depot - Project Simplify                                   |
-- +====================================================================================+
-- | Name        :  XX_INV_RMS_INT_PURGE_PKG.pkb                                        |
-- | Description :  RMS EBS Interface Purge Package Body                                |
-- |                                                                                    |
-- |Change Record:                                                                      |
-- |===============                                                                     |
-- |Version   Date        Author             Remarks                                    |
-- |========  =========== ================== ===================================        |
-- |1.0       10-Jun-2008 Paddy Sanjeevi       Initital Version                           |
-- |1.1       02-Oct-2008 Paddy Sanjeevi       Added procedures for Reconciliation        |
-- |1.2       02-Oct-2008 Paddy Sanjeevi       Modfied item/loc Reconciliation procedure  |
-- |1.3       20-Oct-2008 Paddy Sanjeevi       Modfied PURGE_PROCESSED_RECS procedure     |
-- |1.4       10-Nov-2008 Paddy Sanjeevi       Modfied PURGE_PROCESSED_RECS procedure to  |
-- |                                         add p_days parameter                       |
-- |1.5       04-Jan-2010 Paddy Sanjeevi       Added item_reprocess procedure             |
-- |1.6       19-Oct-2015 Madhu Bolli        Remove schema for 12.2 retrofit            |
-- |1.7       29-MAY-2019 Arun gannarapu     Remove DB link for LNS                     |
-- +====================================================================================+
AS
-- +====================================================================================+
-- | Name        :  RMS_EBS_MERCH_RECON                                                 |
-- | Description :  This procedure is invoked from the procedure RMS_EBS_RECON for the  |
-- |                reconcliation of Merch Hierarchy between RMS and EBS                |
-- | Parameters  :                                                                      |
-- +====================================================================================+

PROCEDURE SEND_NOTIFICATION( p_subject IN VARCHAR2
                ,p_email_list IN VARCHAR2
                ,p_text IN VARCHAR2 )
IS
  lc_mailhost    VARCHAR2(64) := FND_PROFILE.VALUE('XX_INV_MAIL_HOST');
  lc_from        VARCHAR2(64) := 'rms-ebs-interface@officedepot.com';
  l_mail_conn    UTL_SMTP.connection;
  lc_to          VARCHAR2(2000);
  lc_to_all      VARCHAR2(2000) := p_email_list ;
  i              BINARY_INTEGER;
  TYPE T_V100 IS TABLE OF VARCHAR2(100)  INDEX BY BINARY_INTEGER;
  lc_to_tbl      T_V100;
  crlf VARCHAR2 (10) := UTL_TCP.crlf; 
BEGIN
  -- If setup data is missing then return

  IF lc_mailhost IS NULL OR lc_to_all IS NULL THEN
      RETURN;
  END IF;

  l_mail_conn := UTL_SMTP.open_connection(lc_mailhost, 25);
  UTL_SMTP.helo(l_mail_conn, lc_mailhost);
  UTL_SMTP.mail(l_mail_conn, lc_from);

  -- Check how many recipients are present in lc_to_all

  i := 1;
  LOOP
      lc_to := SUBSTR(lc_to_all,1,INSTR(lc_to_all,':') - 1);
      IF lc_to IS NULL OR i = 20 THEN
          lc_to_tbl(i) := lc_to_all;
          UTL_SMTP.rcpt(l_mail_conn, lc_to_all);
          EXIT;
      END IF;
      lc_to_tbl(i) := lc_to;
      UTL_SMTP.rcpt(l_mail_conn, lc_to);
      lc_to_all := SUBSTR(lc_to_all,INSTR(lc_to_all,':') + 1);
      i := i + 1;
  END LOOP;

  UTL_SMTP.open_data(l_mail_conn);

  UTL_SMTP.write_data(l_mail_conn, 'Date: '    || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'From: '    || lc_from || Chr(13));
  UTL_SMTP.write_data(l_mail_conn, 'Subject: ' || p_subject || Chr(13));

  --UTL_SMTP.write_data(l_mail_conn, Chr(13));

  -- Checl all recipients

  FOR i IN 1..lc_to_tbl.COUNT LOOP

      UTL_SMTP.write_data(l_mail_conn, 'To: '      || lc_to_tbl(i) || Chr(13));

  END LOOP;
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.write_data(l_mail_conn, p_text||crlf);
  UTL_SMTP.write_data (l_mail_conn, ' ' || crlf); 
  UTL_SMTP.close_data(l_mail_conn);
  UTL_SMTP.quit(l_mail_conn);
EXCEPTION
    WHEN OTHERS THEN
    NULL;
END SEND_NOTIFICATION;


PROCEDURE item_reprocess( x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
             ,Cat_reproc           IN  VARCHAR2)
IS

CURSOR C1 IS
SELECT inventory_item_id,
       organization_id,
       rowid drowid
  FROM xx_inv_item_master_int
 WHERE creation_date>sysdate-1
   AND validation_orgs_status_flag<>'S'
   AND process_Flag=7
   AND error_message like '%Validation%Org%Assignment%'
   AND action_type='A';


CURSOR C2 IS
SELECT argument1,
       argument2
  FROM fnd_concurrent_requests
 WHERE concurrent_program_id=151458
   AND actual_start_date>sysdate-1
   AND status_code='E'
 ORDER BY 1;


ln_cnt         NUMBER:=0;
v_email_list    VARCHAR2(3000):='ebs.merch@officedepot.com';
v_text        VARCHAR2(3000);
v_subject    VARCHAR2(3000);

BEGIN

-- Resubmitting failed item master records

  FOR cur IN c2 LOOP

    IF cur.argument1 IN ('MA','MC') THEN
       UPDATE xx_inv_item_master_int a
          SET process_flag=1,load_batch_id=null,inventory_item_id=-1
        WHERE load_batch_id=TO_NUMBER(cur.argument2);
    END IF;

    IF cur.argument1 IN ('LA','LC') THEN

       UPDATE xx_inv_item_loc_int a
          SET process_flag=1,load_batch_id=null,inventory_item_id=-1
        WHERE load_batch_id=TO_NUMBER(cur.argument2);

    END IF;

    COMMIT;

   END LOOP;


-- Resubmitting failed validation org records

  FOR cur IN C1 LOOP
    SELECT COUNT(1)
      INTO ln_cnt
      FROM mtl_system_items_b
     WHERE inventory_item_id=cur.inventory_item_id
       AND organization_id IN (442,443);
  
    IF ln_cnt<>2 THEN

       UPDATE xx_inv_item_master_int
          SET process_flag=1,load_batch_id=null,inventory_item_id=-1,
          validation_orgs_status_flag='F'
        WHERE rowid=cur.drowid;

    END IF;

  END LOOP;
  COMMIT;

  UPDATE xx_inv_item_loc_int a
     SET process_flag=1,load_batch_id=null,inventory_item_id=-1,location_process_Flag=null
   WHERE creation_date>sysdate-1
     AND location_process_Flag=3
     AND process_flag=7;
  COMMIT;

  SELECT COUNT(1)
    INTO ln_cnt
    FROM xx_inv_item_master_int
   WHERE creation_date>sysdate-1
     AND process_flag=7
     AND (odpb_category_process_flag<>7 OR atp_category_process_flag<>7);

  IF ln_cnt<>0 THEN

     v_subject:='RMS EBS Interface Alert : ATP/Private Brand Category Setup Missing';
     XX_INV_RMS_INT_PURGE_PKG.send_notification(v_subject,v_email_list,v_subject);

  END IF;
 
  IF Cat_reproc='Y' THEN

     UPDATE xx_inv_item_master_int
        SET process_flag=1,load_batch_id=null,inventory_item_id=-1
      WHERE creation_date>sysdate-5
    AND process_flag=7
        AND odpb_category_process_flag<>7;


     UPDATE xx_inv_item_master_int
        SET process_flag=1,load_batch_id=null,inventory_item_id=-1
      WHERE creation_date>sysdate-5
        AND process_flag=7
        AND atp_category_process_flag<>7;

  END IF;
  COMMIT;
END item_reprocess;

/* -- commented for LNS
PROCEDURE rms_ebs_merch_recon
IS
  CURSOR C1 IS
  SELECT  TO_CHAR(div.division) division_id  
         ,TO_CHAR(grp.group_no) group_id  
         ,TO_CHAR(deps.dept)    dept_id  
         ,TO_CHAR(class.class)  class_id  
         ,TO_CHAR(subclass.subclass) subclass_id  
    FROM rms10.comphead@rms.na.odcorp.net comp 
    JOIN rms10.division@rms.na.odcorp.net div  on 
        (1 = comp.company) 
    JOIN rms10.groups@rms.na.odcorp.net grp  on 
     (grp.division = div.division)
    JOIN rms10.deps@rms.na.odcorp.net deps  on 
     (deps.group_no = grp.group_no)
    JOIN rms10.od_dept_attributes@rms.na.odcorp.net depsAttr  on 
     (depsAttr.dept = deps.dept)
    JOIN rms10.class@rms.na.odcorp.net class  on 
     (class.dept = deps.dept)      
    JOIN rms10.od_class_attributes@rms.na.odcorp.net classAttr  on 
     (classAttr.dept = class.dept and
      classAttr.class = class.class)      
    JOIN rms10.subclass@rms.na.odcorp.net subclass  on 
     (subclass.class = class.class)      
    JOIN rms10.od_subclass_attributes@rms.na.odcorp.net subclassAttr  on 
     (subclassAttr.dept = subclass.dept and      
      subclassAttr.class = subclass.class and 
      subclassAttr.subclass = subclass.subclass)
   MINUS
  SELECT  LTRIM(RTRIM(segment1)) division_id
        ,LTRIM(RTRIM(segment2)) group_id
       ,LTRIM(RTRIM(segment3)) dept_id
       ,LTRIM(RTRIM(segment4)) class_id
       ,LTRIM(RTRIM(segment5)) subclass_id
   FROM mtl_categories_b
  WHERE structure_id=101
    AND enabled_flag='Y';
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing Merchierchy in EBS                                   ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 --------------------------                                   ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'DIVISION'||'   '||'GROUP  '||'   '||'DEPT  '||'   '||'CLASS '||'   '||'SUBCLASS');    
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'--------'||'   '||'-------'||'   '||'------'||'   '||'------'||'   '||'--------');    
  FOR cur IN C1 LOOP
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(cur.division_id,11,' ')||RPAD(cur.group_id,10,' ')||
                             RPAD(cur.dept_id,9,' ')||RPAD(cur.class_id,9,' ')||cur.subclass_id);
  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
END rms_ebs_merch_recon;
*/ -- per lns

-- +====================================================================================+
-- | Name        :  RMS_EBS_LOCATION_RECON                                              |
-- | Description :  This procedure is invoked from the procedure RMS_EBS_RECON for the  |
-- |                reconcliation of Location between RMS and EBS                       |
-- | Parameters  :                                                                      |
-- +====================================================================================+
/* -- commented for LNS
PROCEDURE rms_ebs_location_recon
IS
CURSOR C1 IS
SELECT LPAD(s.store,6,'0') location
  FROM STORE@rms.na.odcorp.net s, store_attributes@rms.na.odcorp.net sa
 WHERE s.STORE = sa.STORE
   AND s.STORE < 10000
UNION
SELECT LPAD(w.wh,6,'0') location
  FROM WH@rms.na.odcorp.net w, WH_ATTRIBUTES@rms.na.odcorp.net wa
 WHERE w.WH = wa.WH
   AND w.WH < 10000 AND w.wh not in (2070,4110)
MINUS
SELECT SUBSTR(name,1,6) location
  FROM hr_all_organization_units
 WHERE attribute1 is not null;
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing Locations in EBS                                   ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ------------------------                                   ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Store/Warehouse');    
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'----------------');    
  FOR cur IN C1 LOOP
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,cur.location);
  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
END rms_ebs_location_recon;

*/ -- per LNS

-- +====================================================================================+
-- | Name        :  RMS_EBS_ORGHIER_RECON                                               |
-- | Description :  This procedure is invoked from the procedure RMS_EBS_RECON for the  |
-- |                reconcliation of Org Hierarchy between RMS and EBS                  |
-- | Parameters  :                                                                      |
-- +====================================================================================+

/* -- commented for LNS

PROCEDURE rms_ebs_orghier_recon
IS
CURSOR c1 IS
SELECT to_char(chain) hvalue, 'CHAIN' ORGHIER
  FROM chain@rms.na.odcorp.net
MINUS
SELECT a.flex_value hvalue,'CHAIN' ORGHIER
  FROM fnd_flex_values a,
      fnd_flex_value_sets b
 WHERE b.flex_value_set_name='XX_GI_CHAIN_VS'
   AND a.flex_value_set_id=b.flex_value_set_id 
   AND a.end_date_active IS NULL
UNION
SELECT to_char(area) hvalue, 'AREA' ORGHIER
  FROM rms10.area@rms.na.odcorp.net
MINUS
SELECT a.flex_value hvalue, 'AREA' ORGHIER
 FROM fnd_flex_values a,
      fnd_flex_value_sets b
WHERE b.flex_value_set_name='XX_GI_AREA_VS'
  AND a.flex_value_set_id=b.flex_value_set_id
  AND a.end_date_active IS NULL
UNION
SELECT to_char(region) hvalue,'REGION' ORGHIER
  FROM region@rms.na.odcorp.net
MINUS
SELECT a.flex_value hvalue, 'REGION' ORGHIER
 FROM fnd_flex_values a,
      fnd_flex_value_sets b
WHERE b.flex_value_set_name='XX_GI_REGION_VS'
  AND a.flex_value_set_id=b.flex_value_set_id
  AND a.end_date_active IS NULL
UNION
SELECT to_char(district) hvalue, 'DISTRICT' ORGHIER
  FROM district@rms.na.odcorp.net
MINUS
SELECT a.flex_value hvalue, 'DISTRICT' ORGHIER
 FROM fnd_flex_values a,
      fnd_flex_value_sets b
WHERE b.flex_value_set_name='XX_GI_DISTRICT_VS'
  AND a.flex_value_set_id=b.flex_value_set_id
  AND a.end_date_active IS NULL
ORDER BY 2;
v_type    VARCHAR2(40) := ' ';
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing Orghierarchy in EBS                                   ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ---------------------------                                   ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FOR cur IN C1 LOOP
     IF v_type <> cur.orghier THEN
      v_type := cur.orghier; 
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');                 
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD(v_type,12,' '));
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD('-',12,'-'));
     END IF;
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT,cur.hvalue);
  END LOOP;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
END rms_ebs_orghier_recon; 

*/ -- per LNS

-- +====================================================================================+
-- | Name        :  RMS_EBS_ITEM_RECON                                                  |
-- | Description :  This procedure is invoked from the procedure RMS_EBS_RECON for the  |
-- |                reconcliation of Item Master between RMS and EBS                    |
-- | Parameters  :                                                                      |
-- +====================================================================================+

/* -- commented for LNS

PROCEDURE rms_ebs_item_recon
IS
v_total_item     NUMBER:=0;
v_total_sclass     NUMBER:=0;
j             NUMBER:=0;
CURSOR c1 IS
 SELECT   --+ PARALLEL(M,4) 
      TO_CHAR(m.item) item
   FROM (item_master@rms.na.odcorp.net m LEFT
  OUTER JOIN item_attributes@rms.na.odcorp.net a ON m.item = a.item) LEFT
  OUTER JOIN od_item_subsell@rms.na.odcorp.net s ON m.item = s.item
 WHERE m.status = 'A'
MINUS
SELECT  --+ PARALLEL(A,4) 
    A.SEGMENT1 item
  FROM mtl_system_items_b A
WHERE A.organization_id=441;

CURSOR c2 IS
SELECT --+ PARALLEL(M,4) 
     to_char(m.item) item,to_char(m.subclass) subclass
FROM(item_master@rms.na.odcorp.net m LEFT
  OUTER JOIN item_attributes@rms.na.odcorp.net a ON m.item = a.item) LEFT
  OUTER JOIN od_item_subsell@rms.na.odcorp.net s ON m.item = s.item
WHERE m.status = 'A' 
minus
SELECT --+ PARALLEL(c,4)  
     c.segment1 item,d.segment5 subclass
  FROM  mtl_categories d,
             mtl_item_categories b,
             mtl_system_items_b c
WHERE c.organization_id=441
     AND b.inventory_item_id=c.inventory_item_id
     AND b.organization_id=c.organization_id
     AND b.category_set_id=1
     AND d.category_id=b.category_id;

BEGIN
-- To get the item which does not exists in EBS
  FOR cur IN C1 LOOP
    v_total_item:=v_total_item+1;
    j:=j+1;
    IF j>=5000 THEN
       COMMIT;
       j:=1;
    END IF;
    BEGIN
      INSERT
      INTO xx_inv_error_log
      VALUES
      (XX_INV_ERROR_LOG_S.NEXTVAL,-1,'ITEMMASTERRECON',cur.item,NULL,NULL,NULL,NULL,'Missing Item in EBS from Reconciliation',
       'N',SYSDATE,FND_GLOBAL.user_id,SYSDATE,FND_GLOBAL.user_id);
    EXCEPTION
    WHEN others THEN
      NULL;
    END;
  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing Items in EBS                                          ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 --------------------                                          ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No of Items : '||TO_CHAR(v_total_item));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
-- To get the items which does not match subclass with items in EBS
  j:=0;
  FOR cur IN C2 LOOP
    v_total_sclass:=v_total_sclass+1;
    j:=j+1;
    IF j>=5000 THEN
       COMMIT;
       j:=1;
    END IF;
    BEGIN
      INSERT
      INTO xx_inv_error_log
      VALUES
      (XX_INV_ERROR_LOG_S.NEXTVAL,-1,'ITEMMASTERRECON',cur.item,cur.subclass,NULL,NULL,NULL,'Missing Item/Subclass in EBS from Reconciliation',
       'N',SYSDATE,FND_GLOBAL.user_id,SYSDATE,FND_GLOBAL.user_id);
    EXCEPTION
    WHEN others THEN
      NULL;
    END;
  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Item Subclass mismatch in EBS                                 ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 -----------------------------                                 ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No of Items : '||TO_CHAR(v_total_sclass));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
END rms_ebs_item_recon;

*/ -- per LNS

-- +====================================================================================+
-- | Name        :  RMS_EBS_ITEMLOC_RECON                                               |
-- | Description :  This procedure is invoked from the procedure RMS_EBS_RECON for the  |
-- |                reconcliation of item loc between RMS and EBS                       |
-- | Parameters  :                                                                      |
-- +====================================================================================+

/* -- commented for LNS

PROCEDURE rms_ebs_itemloc_recon
IS
v_total_loc NUMBER:=0;
j         NUMBER:=0;
CURSOR C1 IS
SELECT -- *+ PARALLEL(m,4) 
       l.item,to_char(l.loc) loc
  FROM (item_master@rms.na.odcorp.net m
  INNER JOIN item_loc@rms.na.odcorp.net l on m.item=l.item)
  INNER JOIN item_loc_traits@rms.na.odcorp.net t ON l.item=t.item
  AND l.loc=t.loc 
 WHERE m.status='A' 
   AND l.loc<10000
   AND l.status<>'D'
   AND l.loc NOT IN (799,4110,2070)
MINUS
SELECT --+ PARALLEL(b,4) 
    b.segment1,c.attribute1 loc
   FROM mtl_system_items_b b,
      hr_all_organization_units c
  WHERE c.attribute1 IS NOT NULL
    AND b.organization_id=c.organization_id;

BEGIN
  FOR cur IN C1 LOOP
    v_total_loc:=v_total_loc+1;
    j:=j+1;
    IF j>=5000 THEN
       COMMIT;
       j:=1;
    END IF;
    BEGIN
      INSERT
      INTO xx_inv_error_log
      VALUES
      (XX_INV_ERROR_LOG_S.NEXTVAL,-1,'ITEMLOCRECON',cur.item,cur.loc,NULL,NULL,NULL,'Missing Item LOC in EBS from Reconciliation',
       'N',SYSDATE,FND_GLOBAL.user_id,SYSDATE,FND_GLOBAL.user_id);
    EXCEPTION
    WHEN others THEN
      NULL;
    END;
  END LOOP;
  COMMIT;
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing Item locs in EBS                                      ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ------------------------                                      ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total No of Itemlocs : '||TO_CHAR(v_total_loc));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
END rms_ebs_itemloc_recon;

*/ --per lNS

-- +====================================================================================+
-- | Name        :  RMS_EBS_ITEMXREF_RECON                                              |
-- | Description :  This procedure is invoked from the procedure RMS_EBS_RECON for the  |
-- |                reconcliation of Merch Hierarchy between RMS and EBS                |
-- | Parameters  :                                                                      |
-- +====================================================================================+

/* -- commented for LNS

PROCEDURE rms_ebs_itemxref_recon
IS
v_item_xref NUMBER:=0;
BEGIN
-- To get the itemxref between RMS and EBS
  SELECT COUNT(1)
    INTO v_item_xref
    FROM OD_ITEMXRF@rms.na.odcorp.net a 
   WHERE ITEM_ASST_CD = 'O'
     AND EXISTS (SELECT 'x' FROM rms10.item_master@rms.na.odcorp.net WHERE item=a.item AND status='A')
     AND EXISTS (SELECT 'x' FROM rms10.item_master@rms.na.odcorp.net WHERE item=a.xref_item AND status='A')
     AND NOT EXISTS (SELECT 'X'
                 FROM mtl_cross_reference_types b, 
                    fnd_lookup_values e, 
                    mtl_cross_references d,     
                    mtl_system_items_b c
                WHERE c.organization_id=441 
                  AND c.segment1=a.item
                  AND d.inventory_item_id=c.inventory_item_id
                  AND e.meaning=a.XREF_TYPE_CD    
                  AND e.lookup_type = 'RMS_EBS_CROSS_REFERENCE_TYPES'
                  AND b.cross_reference_type = e.lookup_code
                  AND d.cross_reference_type=b.cross_reference_type);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing Item xref in EBS                                      ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ------------------------                                      ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total Itemxref : '||TO_CHAR(v_item_xref));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
-- To get PRDF xref between RMS and EBS
  SELECT COUNT(1)
    INTO v_item_xref
    FROM OD_PRODXRF@rms.na.odcorp.net a
   WHERE EXISTS (SELECT  'x' FROM rms10.item_master@rms.na.odcorp.net WHERE item=a.item AND status='A')
     AND NOT EXISTS (SELECT 'X'
                   FROM mtl_cross_reference_types b, fnd_lookup_values e, 
                     mtl_cross_references d, mtl_system_items_b c
               WHERE c.organization_id=441 
                 AND c.segment1=a.item
                 AND d.inventory_item_id=c.inventory_item_id
                 AND e.meaning=a.product_source   
                 AND e.lookup_type = 'RMS_EBS_CROSS_REFERENCE_TYPES'
                 AND b.cross_reference_type = e.lookup_code
                 AND d.cross_reference_type=b.cross_reference_type);
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing PRDS xref in EBS                                      ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ------------------------                                      ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total PRDF xref : '||TO_CHAR(v_item_xref));
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
-- To get WHSL Xref between RMS and EBS
  SELECT COUNT(1)
    INTO v_item_xref
    FROM OD_WHSLR_PRODXRF@rms.na.odcorp.net a
   WHERE EXISTS (SELECT 'x' FROM rms10.item_master@rms.na.odcorp.net WHERE item=a.sku AND status='A')
     AND NOT EXISTS (SELECT 'X'
                   FROM mtl_cross_reference_types b, fnd_lookup_values e, 
                     mtl_cross_references d, mtl_system_items_b c
               WHERE c.organization_id=441 
                 AND c.segment1=a.sku
                 AND d.inventory_item_id=c.inventory_item_id
                 AND e.meaning=a.whslr_supplier_cd
                 AND e.lookup_type = 'RMS_EBS_CROSS_REFERENCE_TYPES'
                 AND b.cross_reference_type = e.lookup_code
                 AND d.cross_reference_type=b.cross_reference_type);
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 Missing WHLS xref in EBS                                      ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ------------------------                                      ');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total WHLS xref : '||TO_CHAR(v_item_xref));
   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
END rms_ebs_itemxref_recon;
*/ -- per lns

-- +====================================================================================+
-- | Name        :  RMS_EBS_MERCH_RECON                                                 |
-- | Description :  This procedure is invoked from ESP for the reconciliation between   |
-- |                RMS and EBS                                                         |
-- | Parameters  :                                                                      |
-- +====================================================================================+


PROCEDURE RMS_EBS_RECON(
                          x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
                         )
IS
BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 RMS EBS Reconciliation                                    ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                                                 ----------------------                                    ');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'');
/* -- commented for LNS
  rms_ebs_location_recon;
  rms_ebs_orghier_recon;
  rms_ebs_merch_recon;
  rms_ebs_item_recon;
  rms_ebs_itemloc_recon;
  rms_ebs_itemxref_recon;
  */ 
EXCEPTION
  WHEN others THEN
    x_errbuf:=SQLERRM;
    x_retcode:=SQLCODE;
END RMS_EBS_RECON;

-- +====================================================================================+
-- | Name        :  PURGE_PROCESSED_RECS                                                |
-- | Description :  This procedure is invoked from ESP to purge processed records in EBS|
-- |                                                                                    |
-- | Parameters  :                                                                      |
-- +====================================================================================+
PROCEDURE PURGE_PROCESSED_RECS(
                          x_errbuf             OUT NOCOPY VARCHAR2
                         ,x_retcode            OUT NOCOPY VARCHAR2
                 ,p_days             IN  NUMBER
                         )
IS
v_min_control_id NUMBER;
v_max_control_id NUMBER;
v_total         NUMBER;
v_loop         NUMBER;
v_rms_control_id NUMBER;
BEGIN
--  Purging Item Interface Processed records
  SELECT MIN(control_id),MAX(control_id)
    INTO v_min_control_id,v_max_control_id
    FROM xx_inv_item_master_int
   WHERE process_flag=7
     AND creation_date<SYSDATE-p_days;
  v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
    FROM xx_inv_item_master_int
     WHERE control_id between v_min_control_id and v_min_control_id+10000
       AND process_flag=7
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
  COMMIT;
--  Purging Item Loc Interface Processed records
  SELECT MIN(control_id),MAX(control_id)
    INTO v_min_control_id,v_max_control_id
    FROM xx_inv_item_loc_int
   WHERE process_flag=7
     AND creation_date<SYSDATE-p_days;
  v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
    FROM xx_inv_item_loc_int
     WHERE control_id between v_min_control_id and v_min_control_id+10000
       AND process_flag=7
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
  COMMIT;
--  Purging Processed Errored Records

/*   SELECT MAX(control_id)
    INTO v_rms_control_id
    FROM OD_EBS_INT_CONTROL
   WHERE process_name='EBS_ERRORS';
  SELECT MIN(control_id),MAX(control_id)
    INTO v_min_control_id,v_max_control_id
    FROM XX_INV_ERROR_LOG
   WHERE control_id<NVL(v_rms_control_id,0)
     AND creation_date<SYSDATE-p_days;
  v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
    FROM XX_INV_ERROR_LOG
     WHERE control_id between v_min_control_id and v_min_control_id+10000
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
   COMMIT; */
   
--  Purging Org Hierarchy Interface Processed records
  SELECT MIN(control_id),MAX(control_id)
    INTO v_min_control_id,v_max_control_id
    FROM xx_inv_orghier_int
   WHERE process_flag in(7,6)
     AND creation_date<SYSDATE-p_days;
  v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
    FROM xx_inv_orghier_int
     WHERE control_id between v_min_control_id and v_min_control_id+10000
       AND process_flag in(7,6)
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
  COMMIT;
--  Purging Merch Hierarchy Interface Processed records
  SELECT MIN(control_id),MAX(control_id)
    INTO v_min_control_id,v_max_control_id
    FROM xx_inv_merchier_int
   WHERE process_flag in(7,6)
     AND creation_date<SYSDATE-p_days;
v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
    FROM xx_inv_merchier_int
     WHERE control_id between v_min_control_id and v_min_control_id+10000
       AND process_flag in (7,6)
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
  COMMIT;
--  Purging ItemXref Interface Processed records
  SELECT MIN(control_id),MAX(control_id)
    INTO v_min_control_id,v_max_control_id
    FROM xx_inv_itemxref_int
   WHERE process_flag in(7,6)
     AND creation_date<SYSDATE-p_days;
  v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
    FROM xx_inv_itemxref_int
     WHERE control_id between v_min_control_id and v_min_control_id+10000
       AND process_flag in(7,6)
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
  COMMIT;
 --  Purging Location Interface Processed records
  SELECT MIN(bpel_instance_id),MAX(bpel_instance_id)
    INTO v_min_control_id,v_max_control_id
    FROM xx_inv_org_loc_def_stg
   WHERE process_flag in(7,6)
     AND creation_date<SYSDATE-p_days;
  v_total:=NVL(v_max_control_id,0) - NVL(v_min_control_id,0);
  v_loop:=ROUND(v_total/10000);
  IF v_loop=0 THEN
     v_loop:=1;
  END IF;
  FOR i IN 1..v_loop LOOP
    DELETE 
      FROM xx_inv_org_loc_def_stg
     WHERE bpel_instance_id between v_min_control_id and v_min_control_id+10000
       AND process_flag in(7,6)
       AND creation_date<SYSDATE-p_days;
    COMMIT;
    v_min_control_id:=v_min_control_id+10000;
  END LOOP;
  COMMIT;
--  
END PURGE_PROCESSED_RECS;
END XX_INV_RMS_INT_PURGE_PKG;
/
SHOW ERRORS
--EXIT;
