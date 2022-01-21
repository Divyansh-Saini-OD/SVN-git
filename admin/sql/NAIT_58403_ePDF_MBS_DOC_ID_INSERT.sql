-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : NAIT_58403_ePDF_MBS_DOC_ID_INSERT                                       |
-- | Description : This Script is used to insert two new MBS Doc    ID's(10240,25674) for ePDF Dely Method for SKU Level Tax and SKU Level Total
   |
   |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 28-AUG-2018  Capgemini             Defect# NAIT-58403                          |
-- +===========================================================================================+
--Inserting new MBS Doc ID's (10240,25674) for eXLS SKU Level Tax and SKU Level Total
INSERT
INTO XX_CDH_MBS_DOCUMENT_MASTER
  (
    DOCUMENT_ID,
    DOC_DETAIL_LEVEL,
    DOC_TYPE,
    DOC_DESC,
    DOC_SORT_ORDER,
    TOTAL_THROUGH_FIELD_ID,
    PAGE_BREAK_THROUGH_ID,
    CONTENT_SET,
    CUSTOM_FLAG,
    STANDARD_SUITE,
    OUTPUT_FORMAT_CODE,
    INCLUDE_REMIT_FLAG,
    END_OF_FIELD_INDICATOR,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    ATTRIBUTE_CATEGORY,
    ATTRIBUTE1,
    ATTRIBUTE2,
    ATTRIBUTE3,
    ATTRIBUTE4,
    ATTRIBUTE5,
    ATTRIBUTE6,
    ATTRIBUTE7,
    ATTRIBUTE8,
    ATTRIBUTE9,
    ATTRIBUTE10,
    ATTRIBUTE11,
    ATTRIBUTE12,
    ATTRIBUTE13,
    ATTRIBUTE14,
    ATTRIBUTE15
  )
  VALUES
  (
    (SELECT MAX(document_id)+1
      FROM  XX_CDH_MBS_DOCUMENT_MASTER
      WHERE DOCUMENT_ID LIKE '1%'
    ),
    'DETAILSKU',
    'Invoice',
    'INVO SRT-B1',
    'B1',
    NULL,
    NULL,
    NULL,
    'N',
    'Y',
    'R',
    'N',
    'X',
    '-1',
    to_date('01-JAN-90','DD-MON-RR'),
    -1,
    to_date('01-JAN-90','DD-MON-RR'),
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  );
INSERT
INTO XX_CDH_MBS_DOCUMENT_MASTER
  (
    DOCUMENT_ID,
    DOC_DETAIL_LEVEL,
    DOC_TYPE,
    DOC_DESC,
    DOC_SORT_ORDER,
    TOTAL_THROUGH_FIELD_ID,
    PAGE_BREAK_THROUGH_ID,
    CONTENT_SET,
    CUSTOM_FLAG,
    STANDARD_SUITE,
    OUTPUT_FORMAT_CODE,
    INCLUDE_REMIT_FLAG,
    END_OF_FIELD_INDICATOR,
    CREATED_BY,
    CREATION_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_DATE,
    ATTRIBUTE_CATEGORY,
    ATTRIBUTE1,
    ATTRIBUTE2,
    ATTRIBUTE3,
    ATTRIBUTE4,
    ATTRIBUTE5,
    ATTRIBUTE6,
    ATTRIBUTE7,
    ATTRIBUTE8,
    ATTRIBUTE9,
    ATTRIBUTE10,
    ATTRIBUTE11,
    ATTRIBUTE12,
    ATTRIBUTE13,
    ATTRIBUTE14,
    ATTRIBUTE15
  )
  VALUES
  (
    (SELECT MAX(document_id)+1
      FROM XX_CDH_MBS_DOCUMENT_MASTER
      WHERE DOCUMENT_ID LIKE '2%'
    ),
    'DETAILSKU',
    'Consolidated Bill',
    'SUMM DET TOT-B1 PAG-B1 SRT-B1',
    'B1',
    'B1',
    'B1',
    NULL,
    'N',
    'Y',
    'R',
    'N',
    'X',
    '-1',
    to_date('01-JAN-90','DD-MON-RR'),
    -1,
    to_date('01-JAN-90','DD-MON-RR'),
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
  );
Commit;