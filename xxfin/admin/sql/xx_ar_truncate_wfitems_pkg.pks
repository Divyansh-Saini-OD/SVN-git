CREATE OR REPLACE PACKAGE xx_ar_truncate_wfitems_pkg AS
FUNCTION dunning_check(p_site_use_id IN NUMBER
                       ,p_category_type IN VARCHAR2) 
-- +===================================================================+
-- | Name  :DUNNING_CHECK                                              |
-- | Description      :  This Funtion will check if dunning set up is  |
-- |                     properly set                                  |
-- |                                                                   |
-- | Parameters :p_site_use_id(customer site use id)                   |
-- |                                                                   |
-- |                                                                   |
-- | Returns : check flag                                              |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
RETURN NUMBER;
PROCEDURE truncate_wfitems;
-- +===================================================================+
-- | Name  :DUNNING_CHECK                                              |
-- | Description      :  This Procedure will delete records which donot|
-- |                     have dunning setup properly done from wf_items|
-- |                                                                   |
-- | Parameters :                                                      |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
END xx_ar_truncate_wfitems_pkg;
/
SHO ERR