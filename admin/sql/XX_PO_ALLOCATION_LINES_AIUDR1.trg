-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                             Office Depot                          |
-- +===================================================================+
-- | Name  : APPS.XX_PO_ALLOCATION_LINES_AIUDR1                        |
-- | Description: CUSTOM TRIGGER ON INSERT, UPDATE, AND DELETE OF      |
-- |            COLUMNS ALLOCATION_QYT AND LOCKED_ID IN TABLE          |
-- |            XX_PO_ALLOCATION_LINES.  CREATE A TYPE OF              |
-- |            XX_PO_ALLOCATION_T AND PUT IT ON AQ XX_PO_ALLOCATION_Q |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      06-21-2007   K.CRAWFORD       INITAL CODE                 |
-- +===================================================================+
CREATE OR REPLACE TRIGGER APPS.XX_PO_ALLOCATION_LINES_AIUDR1
AFTER DELETE OR INSERT OR UPDATE OF ALLOCATION_QTY,LOCKED_IN
ON XX_PO_ALLOCATION_LINES 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE 
   action_type char;
   po       varchar(20);
   item     number;
   ship_to  number;
   alloc_loc number;
   e_opt      DBMS_AQ.enqueue_options_t;
   m_prop     DBMS_AQ.message_properties_t;
   m_handle   RAW (16);
   MESSAGE    XX_PO_ALLOCATION_T;
   

BEGIN
   IF INSERTING THEN
      IF :NEW.ALLOCATION_TYPE <> 'JITA' THEN   
       action_type := 'I';
  select segment1 into po from po_headers_all where :new.PO_HEADER_ID = po_header_id;
  SELECT TO_NUMBER(ATTRIBUTE1) into ship_to  FROM HR_ALL_ORGANIZATION_UNITS WHERE ORGANIZATION_ID = :new.ship_to_organization_id;
     SELECT TO_NUMBER(ATTRIBUTE1) into alloc_loc  FROM HR_ALL_ORGANIZATION_UNITS WHERE ORGANIZATION_ID = :new.alloc_organization_id;
   SELECT distinct TO_NUMBER(I.SEGMENT1) into item 
    FROM MTL_SYSTEM_ITEMS_B I
       ,MTL_PARAMETERS P
      ,XX_PO_ALLOCATION_HEADER AH 
    WHERE I.INVENTORY_ITEM_ID  = AH.ITEM_ID
      AND I.ORGANIZATION_ID = P.MASTER_ORGANIZATION_ID
    AND P.ORGANIZATION_ID = P.MASTER_ORGANIZATION_ID
      AND :new.ALLOCATION_HEADER_ID = AH.ALLOCATION_HEADER_ID;
    
       MESSAGE :=
             XX_PO_ALLOCATION_T (po,item, ship_to,alloc_loc,:new.ALLOCATION_QTY,:new.LOCKED_IN,action_type);

         DBMS_AQ.enqueue (queue_name              => 'XX_PO_ALLOCATION_Q',
                   enqueue_options         => e_opt,
                           message_properties      => m_prop,
                           payload                 => MESSAGE,
                           msgid                   => m_handle
                          );
 END IF;      
   END IF; 
   IF UPDATING THEN
      action_type := 'U';
   select segment1 into po from po_headers_all where :new.PO_HEADER_ID = po_header_id; 
   SELECT TO_NUMBER(ATTRIBUTE1) into ship_to  FROM HR_ALL_ORGANIZATION_UNITS WHERE ORGANIZATION_ID = :new.ship_to_organization_id;
   SELECT TO_NUMBER(ATTRIBUTE1) into alloc_loc  FROM HR_ALL_ORGANIZATION_UNITS WHERE ORGANIZATION_ID = :new.alloc_organization_id;
   SELECT distinct TO_NUMBER(I.SEGMENT1) into item 
 FROM MTL_SYSTEM_ITEMS_B I
   ,MTL_PARAMETERS P
   ,XX_PO_ALLOCATION_HEADER AH 
  WHERE I.INVENTORY_ITEM_ID  = AH.ITEM_ID
  AND I.ORGANIZATION_ID = P.MASTER_ORGANIZATION_ID
  AND P.ORGANIZATION_ID = P.MASTER_ORGANIZATION_ID
  AND :new.ALLOCATION_HEADER_ID = AH.ALLOCATION_HEADER_ID;
        MESSAGE :=
                XX_PO_ALLOCATION_T (po,item, ship_to,alloc_loc,:new.ALLOCATION_QTY,:new.LOCKED_IN,action_type);


      DBMS_AQ.enqueue (queue_name              => 'XX_PO_ALLOCATION_Q',
                       enqueue_options         => e_opt,
                       message_properties      => m_prop,
                       payload                 => MESSAGE,
                       msgid                   => m_handle
                      );
   END IF; 
   IF DELETING THEN
      action_type := 'D';
      select segment1 into po from po_headers_all where :old.PO_HEADER_ID = po_header_id;
      SELECT TO_NUMBER(ATTRIBUTE1) into ship_to  FROM HR_ALL_ORGANIZATION_UNITS WHERE ORGANIZATION_ID = :old.ship_to_organization_id;
      SELECT TO_NUMBER(ATTRIBUTE1) into alloc_loc  FROM HR_ALL_ORGANIZATION_UNITS WHERE ORGANIZATION_ID = :old.alloc_organization_id;
      SELECT distinct TO_NUMBER(I.SEGMENT1) into item 
 FROM MTL_SYSTEM_ITEMS_B I
   ,MTL_PARAMETERS P
   ,XX_PO_ALLOCATION_HEADER AH 
  WHERE I.INVENTORY_ITEM_ID  = AH.ITEM_ID
  AND I.ORGANIZATION_ID = P.MASTER_ORGANIZATION_ID
  AND P.ORGANIZATION_ID = P.MASTER_ORGANIZATION_ID
  AND :old.ALLOCATION_HEADER_ID = AH.ALLOCATION_HEADER_ID; 
      MESSAGE :=
                XX_PO_ALLOCATION_T (po,item, ship_to,alloc_loc,:old.ALLOCATION_QTY,:old.LOCKED_IN,action_type);

  

      DBMS_AQ.enqueue (queue_name              => 'XX_PO_ALLOCATION_Q',
                       enqueue_options         => e_opt,
                       message_properties      => m_prop,
                       payload                 => MESSAGE,
                       msgid                   => m_handle
                      );
   
   END IF;
   EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END XX_PO_ALLOCATION_LINES_AIUDR1;
