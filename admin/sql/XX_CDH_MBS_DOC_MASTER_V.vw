SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name             :XX_CDH_MBS_DOC_MASTER_V.tbl                         |
-- | Description      :Custom view for E1331_CDH_MetaData_Attributes       |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |1.0      23-JUL-2007 Rajeev Kamath      Initial version                |
-- +=======================================================================+

-- ------------------------------------------------------
--      Create Custom Table XX_CDH_MBS_DOCUMENT_MASTER --
-- ------------------------------------------------------
CREATE OR REPLACE VIEW XX_CDH_MBS_DOCUMENT_MASTER_V
(        DOCUMENT_ID                ,DOC_DETAIL_LEVEL
        ,DOC_TYPE                   ,DOC_DESC                   
        ,DOC_SORT_ORDER             ,TOTAL_THROUGH_FIELD_ID     
        ,PAGE_BREAK_THROUGH_ID      ,CONTENT_SET                
        ,CUSTOM_FLAG                ,STANDARD_SUITE              
        ,OUTPUT_FORMAT_CODE         ,INCLUDE_REMIT_FLAG         
        ,END_OF_FIELD_INDICATOR     ,CREATED_BY                 
        ,CREATION_DATE              ,LAST_UPDATED_BY            
        ,LAST_UPDATE_DATE           ,ATTRIBUTE_CATEGORY         
        ,ATTRIBUTE1                 ,ATTRIBUTE2                 
        ,ATTRIBUTE3                 ,ATTRIBUTE4                 
        ,ATTRIBUTE5                 ,ATTRIBUTE6                 
        ,ATTRIBUTE7                 ,ATTRIBUTE8                 
        ,ATTRIBUTE9                 ,ATTRIBUTE10                
        ,ATTRIBUTE11                ,ATTRIBUTE12                
        ,ATTRIBUTE13                ,ATTRIBUTE14                
        ,ATTRIBUTE15                
) AS 
SELECT    
         DOCUMENT_ID                ,DOC_DETAIL_LEVEL
        ,DOC_TYPE                   ,DOC_DESC                   
        ,DOC_SORT_ORDER             ,TOTAL_THROUGH_FIELD_ID     
        ,PAGE_BREAK_THROUGH_ID      ,CONTENT_SET                
        ,CUSTOM_FLAG                ,STANDARD_SUITE              
        ,OUTPUT_FORMAT_CODE         ,INCLUDE_REMIT_FLAG         
        ,END_OF_FIELD_INDICATOR     ,CREATED_BY                 
        ,CREATION_DATE              ,LAST_UPDATED_BY            
        ,LAST_UPDATE_DATE           ,ATTRIBUTE_CATEGORY         
        ,ATTRIBUTE1                 ,ATTRIBUTE2                 
        ,ATTRIBUTE3                 ,ATTRIBUTE4                 
        ,ATTRIBUTE5                 ,ATTRIBUTE6                 
        ,ATTRIBUTE7                 ,ATTRIBUTE8                 
        ,ATTRIBUTE9                 ,ATTRIBUTE10                
        ,ATTRIBUTE11                ,ATTRIBUTE12                
        ,ATTRIBUTE13                ,ATTRIBUTE14                
        ,ATTRIBUTE15
FROM XX_CDH_MBS_DOCUMENT_MASTER;
    
SHOW ERRORS;    

EXIT;
        
        
        