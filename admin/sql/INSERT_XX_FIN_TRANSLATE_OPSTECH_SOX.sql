-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Insert_xx_fin_translatevalues_opstech_sox                                   |
-- | Description : This Script is used to insert the OPSTECH Method                            |
-- |               into translations values                                                    |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 28-SEP-2018  Thilak CG               Defect# NAIT-56624                          |
-- +===========================================================================================+
--Inserting values for OPSTECH SOX Report

INSERT
INTO XX_FIN_TRANSLATEVALUES
  (
    TRANSLATE_ID,
    SOURCE_VALUE1,
    SOURCE_VALUE2,
    SOURCE_VALUE3,
    SOURCE_VALUE4,
    SOURCE_VALUE5,
    SOURCE_VALUE6,
    SOURCE_VALUE7,
    TARGET_VALUE1,
    TARGET_VALUE2,
    TARGET_VALUE3,
    TARGET_VALUE4,
    TARGET_VALUE5,
    TARGET_VALUE6,
    TARGET_VALUE7,
    TARGET_VALUE8,
    TARGET_VALUE9,
    TARGET_VALUE10,
    TARGET_VALUE11,
    TARGET_VALUE12,
    TARGET_VALUE13,
    TARGET_VALUE14,
    TARGET_VALUE15,
    TARGET_VALUE16,
    TARGET_VALUE17,
    TARGET_VALUE18,
    TARGET_VALUE19,
    TARGET_VALUE20,
    CREATION_DATE,
    CREATED_BY,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    LAST_UPDATE_LOGIN,
    START_DATE_ACTIVE,
    END_DATE_ACTIVE,
    READ_ONLY_FLAG,
    ENABLED_FLAG,
    SOURCE_VALUE8,
    SOURCE_VALUE9,
    SOURCE_VALUE10,
    TRANSLATE_VALUE_ID,
    TARGET_VALUE21,
    TARGET_VALUE22,
    TARGET_VALUE23,
    TARGET_VALUE24,
    TARGET_VALUE25,
    TARGET_VALUE26,
    TARGET_VALUE27,
    TARGET_VALUE28,
    TARGET_VALUE29,
    TARGET_VALUE30
  )
  VALUES
  (
    15321,
    NULL,
    'OPSTECH',
    'CBI',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    'XX_AR_OPS_EBILL',
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
    NULL,
    NULL,
    NULL,
    to_date('01-OCT-18','DD-MON-RR'),
    3822771,
    to_date('01-OCT-18','DD-MON-RR'),
    3822771,
    69483666,
    to_date('01-OCT-18','DD-MON-RR'),
    NULL,
    NULL,
    'Y',
    NULL,
    NULL,
    NULL,
    725401,
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
  
COMMIT;