-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |                                                                       |
-- +=======================================================================+
-- | NAME             :  XX_HZ_HIERARCHY_NODES_INTERIM                     |
-- |                                                                       |
-- | DESCRIPTION      :  To Populate XX_HZ_HIERARCHY_NODES_INTERIM for     |
-- |                     every row inserted or updated in                  |
-- |                     HZ_HIERARCHY_NODES for OD_FIN_PAY_WITHIN          |
-- |                     hierarchy type.                                   |
-- |CHANGE HISTORY:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date         Author             Remarks                       |
-- |-------  -----------  -----------------  ------------------------------|
-- |Draft    10-NOV-2011  P.Sankaran         Initial Draft Version         |
-- |1.1      11-Dec-2015  Manikant Kasu      Removed schema alias as part  | 
-- |                                         of GSCC R12.2.2 Retrofit      |
-- +=======================================================================+

CREATE OR REPLACE TRIGGER XX_HZ_HIERARCHY_NODES_INTERIM
AFTER INSERT OR UPDATE OR DELETE
ON  HZ_HIERARCHY_NODES
FOR EACH ROW
   WHEN (NEW.hierarchy_type = 'OD_FIN_PAY_WITHIN' OR OLD.hierarchy_type = 'OD_FIN_PAY_WITHIN')
BEGIN

   IF INSERTING THEN
      INSERT into XX_HZ_HIERARCHY_NODES_INTERIM
      VALUES
      (
       :NEW.ROWID
      ,:NEW.HIERARCHY_TYPE
      ,:NEW.PARENT_ID
      ,:NEW.PARENT_TABLE_NAME
      ,:NEW.PARENT_OBJECT_TYPE
      ,:NEW.CHILD_ID
      ,:NEW.CHILD_TABLE_NAME
      ,:NEW.CHILD_OBJECT_TYPE
      ,:NEW.LEVEL_NUMBER
      ,:NEW.TOP_PARENT_FLAG
      ,:NEW.LEAF_CHILD_FLAG
      ,:NEW.EFFECTIVE_START_DATE
      ,:NEW.EFFECTIVE_END_DATE
      ,:NEW.STATUS
      ,:NEW.RELATIONSHIP_ID
      ,:NEW.CREATED_BY
      ,:NEW.CREATION_DATE
      ,:NEW.LAST_UPDATED_BY
      ,:NEW.LAST_UPDATE_DATE
      ,:NEW.LAST_UPDATE_LOGIN
      ,:NEW.ACTUAL_CONTENT_SOURCE
       );

   END IF;
   
   IF UPDATING THEN
      
      UPDATE XX_HZ_HIERARCHY_NODES_INTERIM
      SET PARENT_ID  								= :NEW.PARENT_ID
         ,CHILD_ID 									= :NEW.CHILD_ID
         ,LEVEL_NUMBER								= :NEW.LEVEL_NUMBER
         ,TOP_PARENT_FLAG						= :NEW.TOP_PARENT_FLAG
         ,LEAF_CHILD_FLAG						= :NEW.LEAF_CHILD_FLAG
         ,EFFECTIVE_START_DATE				= :NEW.EFFECTIVE_START_DATE
         ,EFFECTIVE_END_DATE					= :NEW.EFFECTIVE_END_DATE
         ,STATUS											= :NEW.STATUS
         ,RELATIONSHIP_ID						= :NEW.RELATIONSHIP_ID
         ,CREATED_BY									= :NEW.CREATED_BY
         ,CREATION_DATE							= :NEW.CREATION_DATE
         ,LAST_UPDATED_BY						= :NEW.LAST_UPDATED_BY
         ,LAST_UPDATE_DATE						= :NEW.LAST_UPDATE_DATE
         ,LAST_UPDATE_LOGIN					= :NEW.LAST_UPDATE_LOGIN
      WHERE ROW_ID = :OLD.ROWID;
      
      IF SQL%ROWCOUNT = 0 THEN
      
            INSERT into XX_HZ_HIERARCHY_NODES_INTERIM
            VALUES
            (
             :NEW.ROWID
            ,:NEW.HIERARCHY_TYPE
            ,:NEW.PARENT_ID
            ,:NEW.PARENT_TABLE_NAME
            ,:NEW.PARENT_OBJECT_TYPE
            ,:NEW.CHILD_ID
            ,:NEW.CHILD_TABLE_NAME
            ,:NEW.CHILD_OBJECT_TYPE
            ,:NEW.LEVEL_NUMBER
            ,:NEW.TOP_PARENT_FLAG
            ,:NEW.LEAF_CHILD_FLAG
            ,:NEW.EFFECTIVE_START_DATE
            ,:NEW.EFFECTIVE_END_DATE
            ,:NEW.STATUS
            ,:NEW.RELATIONSHIP_ID
            ,:NEW.CREATED_BY
            ,:NEW.CREATION_DATE
            ,:NEW.LAST_UPDATED_BY
            ,:NEW.LAST_UPDATE_DATE
            ,:NEW.LAST_UPDATE_LOGIN
            ,:NEW.ACTUAL_CONTENT_SOURCE
             );
      END IF;

    END IF;
    
    IF DELETING THEN
       
       DELETE FROM XX_HZ_HIERARCHY_NODES_INTERIM
       WHERE ROW_ID = :OLD.ROWID; 

    END IF;
END;
/
