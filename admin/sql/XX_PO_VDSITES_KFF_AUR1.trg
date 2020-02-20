create or replace trigger "APPS"."XX_PO_VDSITES_KFF_AUR1"
AFTER UPDATE ON "APPS"."XX_PO_VENDOR_SITES_KFF" FOR EACH ROW

 
  -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_PO_VEND_SITES_KFF_AUR1.trg                              |
    -- | Description : Trigger created per jira NAIT-103952                            |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  22-JAN-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                               |
    -- +===============================================================================+
  
  DECLARE
  
  l_count number;
  
  BEGIN
  
  SELECT COUNT(*) INTO L_COUNT FROM XX_PO_VEND_SITES_KFF_AUD
WHERE 
 NVL(VS_KFF_ID,0)=NVL(:NEW.VS_KFF_ID,0)
 AND   LAST_UPDATED_BY =:new.LAST_UPDATED_BY
 AND   NVL(LAST_UPDATE_LOGIN,0)=NVL(:NEW.LAST_UPDATE_LOGIN,0)
AND   CREATED_BY=:new.CREATED_BY
  AND   NVL(SEGMENT1,'N')= NVL(:NEW.SEGMENT1,'N')
  AND   NVL(SEGMENT2,'N')= NVL(:NEW.SEGMENT2,'N')
  AND   NVL(SEGMENT3,'N')= NVL(:NEW.SEGMENT3,'N')
  AND   NVL(SEGMENT4,'N')= NVL(:NEW.SEGMENT4,'N')
  AND   NVL(SEGMENT5,'N')= NVL(:NEW.SEGMENT5,'N')
  AND   NVL(SEGMENT11,'N')= NVL(:NEW.SEGMENT11,'N')
  AND   NVL(SEGMENT13,'N')= NVL(:NEW.SEGMENT13,'N')
  AND   NVL(SEGMENT14,'N')= NVL(:NEW.SEGMENT14,'N')
  AND   NVL(SEGMENT15,'N')= NVL(:NEW.SEGMENT15,'N')
  AND   NVL(SEGMENT16,'N')= NVL(:NEW.SEGMENT16,'N')
  AND   NVL(SEGMENT17,'N')= NVL(:NEW.SEGMENT17,'N')
  AND   NVL(SEGMENT37,'N')= NVL(:NEW.SEGMENT37,'N')
  AND   NVL(SEGMENT40,'N')= NVL(:NEW.SEGMENT40,'N')
  AND   NVL(SEGMENT42,'N')= NVL(:NEW.SEGMENT42,'N')
  AND   NVL(SEGMENT43,'N')= NVL(:NEW.SEGMENT43,'N')
  AND   NVL(SEGMENT44,'N')= NVL(:NEW.SEGMENT44,'N')
  AND   NVL(SEGMENT47,'N')= NVL(:NEW.SEGMENT47,'N')
  AND   NVL(SEGMENT50,'N')= NVL(:NEW.SEGMENT50,'N')
  AND   NVL(SEGMENT51,'N')= NVL(:NEW.SEGMENT51,'N')
  AND   NVL(SEGMENT52,'N')= NVL(:NEW.SEGMENT52,'N')
  AND   NVL(SEGMENT53,'N')= NVL(:NEW.SEGMENT53,'N')
  AND   NVL(SEGMENT54,'N')= NVL(:NEW.SEGMENT54,'N')
  AND   NVL(SEGMENT55,'N')= NVL(:NEW.SEGMENT55,'N')
  AND   NVL(SEGMENT58,'N')= NVL(:NEW.SEGMENT58,'N')
  AND   NVL(SEGMENT60,'N')= NVL(:NEW.SEGMENT60,'N');
							
  IF l_count=0 THEN 
 
   IF trunc(:new.last_update_date) = trunc(sysdate) THEN
   
  INSERT INTO XX_PO_VEND_SITES_KFF_AUD (VS_KFF_AUD_ID 
,VERSIONS_OPERATION
,VERSION_TIMESTAMP
,LAST_UPDATE_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_LOGIN
,CREATION_DATE
,CREATED_BY
,VS_KFF_ID
,SEGMENT1
,SEGMENT2
,SEGMENT3
,SEGMENT4
,SEGMENT5
,SEGMENT11
,SEGMENT13
,SEGMENT14
,SEGMENT15
,SEGMENT16
,SEGMENT17
,SEGMENT37
,SEGMENT40
,SEGMENT42
,SEGMENT43
,SEGMENT44
,SEGMENT47
,SEGMENT50
,SEGMENT51
,SEGMENT52
,SEGMENT53
,SEGMENT54
,SEGMENT55
,SEGMENT58
,SEGMENT60) 
VALUES (XX_PO_VEND_SITES_KFF_AUD_SEG.NEXTVAL
,'U'
,systimestamp
,:NEW.LAST_UPDATE_DATE
,:NEW.LAST_UPDATED_BY
,:NEW.LAST_UPDATE_LOGIN
,:NEW.CREATION_DATE
,:NEW.CREATED_BY
,:NEW.VS_KFF_ID
,:NEW.SEGMENT1
,:NEW.SEGMENT2
,:NEW.SEGMENT3
,:NEW.SEGMENT4
,:NEW.SEGMENT5
,:NEW.SEGMENT11
,:NEW.SEGMENT13
,:NEW.SEGMENT14
,:NEW.SEGMENT15
,:NEW.SEGMENT16
,:NEW.SEGMENT17
,:NEW.SEGMENT37
,:NEW.SEGMENT40
,:NEW.SEGMENT42
,:NEW.SEGMENT43
,:NEW.SEGMENT44
,:NEW.SEGMENT47
,:NEW.SEGMENT50
,:NEW.SEGMENT51
,:NEW.SEGMENT52
,:NEW.SEGMENT53
,:NEW.SEGMENT54
,:NEW.SEGMENT55
,:NEW.SEGMENT58
,:NEW.SEGMENT60);

END IF;

END IF;

END;
