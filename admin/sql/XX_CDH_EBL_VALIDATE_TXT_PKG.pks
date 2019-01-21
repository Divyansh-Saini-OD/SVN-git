SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace PACKAGE XX_CDH_EBL_VALIDATE_TXT_PKG
 AS
-- +===========================================================================+
-- |                  Office Depot - eBilling Project                          |
-- +===========================================================================+
-- | Name        : XX_CDH_EBL_VALIDATE_TXT_PKG                                 |
-- | Description :                                                             |
-- | This package specification for validating.                                |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |Change Record:                                                             |
-- |===============                                                            |
-- |Version  Date        Author        Remarks                                 |
-- |======== =========== ============= ========================================|
-- |1.0      27-May-2016 Sridevi K     I2186 - For MOD 4B R4                   |
-- +===========================================================================+


  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_EBL_TEMPL_DTL                                      |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_TEMPL_DTL TABLE AND ALSO VALIDATE DATE BEFORE CHANGING         |
  -- | THE DOCUMENT STATUS FROM "IN PROCESS" TO "TESTING" (OR) FROM "TESTING"    |
  -- | TO "COMPLETE".                                                            |
  -- |                                                                           |
  -- |                                                                           |
  -- | PARAMETERS  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | RETURNS     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

  FUNCTION VALIDATE_EBL_TEMPL_DTL
  (
    P_CUST_ACCOUNT_ID          IN NUMBER
   ,P_EBILL_FILE_CREATION_TYPE IN XX_CDH_EBL_TEMPL_HEADER.EBILL_FILE_CREATION_TYPE%TYPE
   ,P_EBL_TEMPL_ID             IN NUMBER
   ,P_CUST_DOC_ID              IN NUMBER
   ,P_RECORD_TYPE              IN VARCHAR2
   ,P_SEQ                      IN NUMBER
   ,P_FIELD_ID                 IN NUMBER
   ,P_LABEL                    IN VARCHAR2
   ,P_START_POS                IN NUMBER
   ,P_FIELD_LEN                IN NUMBER
   ,P_DATA_FORMAT              IN VARCHAR2
   ,P_STRING_FUN               IN VARCHAR2
   ,P_SORT_ORDER               IN NUMBER
   ,P_SORT_TYPE                IN VARCHAR2
   ,P_MANDATORY                IN VARCHAR2
   ,P_SEQ_START_VAL            IN NUMBER
   ,P_SEQ_INC_VAL              IN NUMBER
   ,P_SEQ_RESET_FIELD          IN NUMBER
   ,P_CONSTANT_VALUE           IN VARCHAR2
   ,P_ALIGNMENT                IN VARCHAR2
   ,P_PADDING_CHAR             IN VARCHAR2
   ,P_DEFAULT_IF_NULL          IN VARCHAR2
   ,P_COMMENTS                 IN VARCHAR2
   ,P_ATTRIBUTE1               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE2               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE3               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE4               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE5               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE6               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE7               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE8               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE9               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE10              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE11              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE12              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE13              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE14              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE15              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE16              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE17              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE18              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE19              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE20              IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2;

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_FINAL                                              |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE CHANING THE STATUS     |
  -- | FROM "IN PROCESS" TO "TESTING" (OR) FROM "TESTING" TO "COMPLETE".         |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- | PARAMETERS  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | RETURNS     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

  FUNCTION VALIDATE_FINAL
  (
    P_CUST_DOC_ID     IN NUMBER
   ,P_CUST_ACCOUNT_ID IN NUMBER
   ,P_CHANGE_STATUS   IN VARCHAR2
  ) RETURN VARCHAR2;


END XX_CDH_EBL_VALIDATE_txt_PKG;
/
SHOW ERRORS;
