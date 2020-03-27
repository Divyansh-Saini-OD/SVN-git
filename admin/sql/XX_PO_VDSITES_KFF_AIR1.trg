create or replace trigger "APPS"."XX_PO_VDSITES_KFF_AIR1"
AFTER INSERT ON "APPS"."XX_PO_VENDOR_SITES_KFF" FOR EACH ROW

 
  -- +===============================================================================+
    -- |                  Office Depot - Project Simplify                              |
    -- +===============================================================================+
    -- | Name        : XX_PO_VDSITES_KFF_AIR1.trg                              |
    -- | Description : Trigger created per jira NAIT-103952                            |
    -- |Change Record:                                                                 |
    -- |===============                                                                |
    -- |Version   Date           Author                      Remarks                   |
    -- |========  =========== ================== ======================================|
    -- |DRAFT 1a  22-JAN-2020 Bhargavi Ankolekar Initial draft version                 |
    -- |                                                                               |
    -- +===============================================================================+
  
  
  DECLARE
  
  BEGIN
  
  INSERT INTO XX_PO_VEND_SITES_KFF_AUD_V1 (VS_KFF_AUD_ID 
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
VALUES (XXFIN.XX_PO_VDSITES_KFF_AUD_SEG_V1.NEXTVAL
,'I'
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

END;
/