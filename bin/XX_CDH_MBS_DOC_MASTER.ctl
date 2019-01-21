
-- +=======================================================================+
-- |               Office Depot - Project Simplify                         |
-- |             Oracle NAIO Consulting Organization                       |
-- +=======================================================================+
-- | Name            : XX_CDH_MBS_DOC_MASTER.ctl                           |
-- | Original Author : Prakash Sowriraj                                    |
-- | Description     : Custom table for E1331_CDH_MetaData_Attributes      |
-- |                                                                       |
-- |                                                                       |
-- |Change History:                                                        |
-- |---------------                                                        |
-- |                                                                       |
-- |Version  Date        Author             Remarks                        |
-- |-------  ----------- -----------------  -------------------------------|
-- |DRAFT 1a  15-JUN-2007 Prakash Sowriraj  Initial draft version          |
-- |DRAFT 1b  26-JUN-2007 Prakash Sowriraj  Table name has been renamed    |
-- |1.0       16-JUL-2007 Rajeev Kamath     Delimiter change, Trailing Null|
-- |1.1       04-AUG-2008 Rajeev Kamath     REPLACE mode for PRD; since we |
--                                          are to get files periodically  |
-- +=======================================================================+


LOAD DATA
INFILE  *
REPLACE  
INTO TABLE XX_CDH_MBS_DOCUMENT_MASTER
FIELDS TERMINATED BY "|" OPTIONALLY ENCLOSED BY '"' 
( 
    DOCUMENT_ID                 ,
    DOC_DETAIL_LEVEL            ,
    DOC_TYPE                    ,      
    DOC_DESC                    ,
    DOC_SORT_ORDER              ,
    TOTAL_THROUGH_FIELD_ID      ,
    PAGE_BREAK_THROUGH_ID       ,
    CONTENT_SET                 ,
    CUSTOM_FLAG                 ,
    STANDARD_SUITE              ,
    OUTPUT_FORMAT_CODE          ,
    INCLUDE_REMIT_FLAG          ,
    END_OF_FIELD_INDICATOR      ,
    CREATED_BY                  ,
    CREATION_DATE               ,
    LAST_UPDATED_BY             ,
    LAST_UPDATE_DATE            ,
    ATTRIBUTE_CATEGORY          ,
    ATTRIBUTE1                  ,
    ATTRIBUTE2                  ,
    ATTRIBUTE3                  ,
    ATTRIBUTE4                  ,
    ATTRIBUTE5                  ,
    ATTRIBUTE6                  ,
    ATTRIBUTE7                  ,
    ATTRIBUTE8                  ,
    ATTRIBUTE9                  ,
    ATTRIBUTE10                 ,
    ATTRIBUTE11                 ,
    ATTRIBUTE12                 ,
    ATTRIBUTE13                 ,
    ATTRIBUTE14                 ,
    ATTRIBUTE15             
  )
