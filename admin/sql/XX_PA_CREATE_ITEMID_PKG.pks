CREATE OR REPLACE PACKAGE XX_PA_CREATE_ITEMID_PKG IS
/*======================================================================
-- +===================================================================+
-- |                  Office Depot - PA/QA-Project                     |
-- |              Private Brand China Global Sourcing                  |
-- +===================================================================+
-- | Name       :  XX_PA_CREATE_ITEMID_PKG                             |
-- | Description:  This procedure is Created for the PBCGS PA to QA    |
-- |               as a concurrent program which will auto create      |
-- |               item ids for projects with a new or revised SKU NUM |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |                                                                   | 
-- |1.0      14-Apr-2008  Ian Bassaragh    Created This procedure      |
-- |                                                                   |
-- +===================================================================+
+======================================================================*/
PROCEDURE XXOD_CREATE_ITEMID ( retcode   OUT VARCHAR2,
                             errbuf      OUT VARCHAR2,
                             p_project_id IN VARCHAR2,
                             p_num_skus   IN VARCHAR2,
                             p_updated_by IN VARCHAR2                                                        
                             );
END   XX_PA_CREATE_ITEMID_PKG; 
/
EXIT;
