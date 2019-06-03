/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA PROJECT - TRIGGER              |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_PROJ_ERP_EXT_B_T1                             |
-- | Description:  This trigger is Created for the PBCGS PA Project    |
-- |               to synchronize number of SKUS on a project with     |
-- |               project item ids.                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      03-Apr-2008  Ian Bassaragh    Created This Trigger        |
-- |1.1      03-Jun-2010  Paddy Sanjeevi   Modified to call            |
-- |                                               xx_qa_create_itemid |      
-- +===================================================================+
+======================================================================*/
CREATE OR REPLACE TRIGGER XX_PA_PROJ_ERP_EXT_B_T1
  AFTER INSERT OR UPDATE OF N_EXT_ATTR1 ON PA_PROJECTS_ERP_EXT_B
FOR EACH ROW
DECLARE
 l_attr_id NUMBER;
BEGIN

  SELECT FNDX.ATTR_GROUP_ID
    INTO l_attr_id
    FROM APPS.EGO_FND_DSC_FLX_CTX_EXT FNDX
   WHERE FNDX.DESCRIPTIVE_FLEX_CONTEXT_CODE = 'PB_GEN_INFO'
     AND FNDX.APPLICATION_ID = 275;

  IF UPDATING THEN
     IF :NEW.ATTR_GROUP_ID = l_attr_id THEN
        IF ( :NEW.N_EXT_ATTR1 > NVL(:OLD.N_EXT_ATTR1,0) ) THEN
           XX_QA_CREATE_ITEMID(:NEW.PROJECT_ID,:NEW.N_EXT_ATTR1,:NEW.LAST_UPDATED_BY);
        END IF;
     END IF;
  ELSE
     IF :NEW.ATTR_GROUP_ID = l_attr_id THEN
        IF ( NVL(:NEW.N_EXT_ATTR1,0) > 0 ) THEN
           XX_QA_CREATE_ITEMID(:NEW.PROJECT_ID,:NEW.N_EXT_ATTR1,:NEW.LAST_UPDATED_BY);
        END IF;
     END IF;
  END IF;
END;
/
