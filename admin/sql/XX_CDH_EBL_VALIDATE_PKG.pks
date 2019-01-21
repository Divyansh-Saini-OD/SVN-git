SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_CDH_EBL_VALIDATE_PKG

-- +===========================================================================+
-- |                  OFFICE DEPOT - EBILLING PROJECT                          |
-- |                         WIPRO/OFFICE DEPOT                                |
-- +===========================================================================+
-- | NAME        : XX_CDH_EBL_VALIDATE_PKG                                     |
-- | DESCRIPTION :                                                             |
-- | THIS PACKAGE WILL VALIDATE ENTIRE DATA BEFORE INSERTING DATA INTO TABLES. |
-- | AND ALSO ALL THE VALIDATION FUNCTIONS ARE EXCEUTED ONE FINAL TIME BEFORE  |
-- | CHANGING THE DOCUMENT STATUS, TO MAKE SURE THAT THE DATE IS VALID.        |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |CHANGE RECORD:                                                             |
-- |===============                                                            |
-- |VERSION  DATE        AUTHOR        REMARKS                             |
-- |======== =========== ============= ========================================|
-- |DRAFT 1A 25-FEB-2010 SRINI CH      INITIAL DRAFT VERSION                   |
-- |                                                                           |
-- |                                                                           |
-- |                                                                           |
-- |===========================================================================|
-- | SUBVERSION INFO:                                                          |
-- | $HEADURL: HTTP://SVN.NA.ODCORP.NET/SVN/OD/CRM/BRANCHES/FIX/XXCRM/ADMIN/SQL/XX_CDH_EBL_VALIDATE_PKG.PKB $                                                               |
-- | $REV: 148259 $                                                                   |
-- | $DATE: 2011-09-16 13:51:39 -0400 (FRI, 16 SEP 2011) $                                                                  |
-- |                                                                           |
-- +===========================================================================+
 AS

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_EBL_MAIN                                           |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_MAIN TABLE AND ALSO VALIDATE DATE BEFORE CHANGING              |
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

  FUNCTION VALIDATE_EBL_MAIN(
    P_CUST_DOC_ID               IN NUMBER
   ,P_CUST_ACCOUNT_ID           IN NUMBER
   ,P_EBILL_TRANSMISSION_TYPE   IN VARCHAR2
   ,P_EBILL_ASSOCIATE           IN VARCHAR2
   ,P_FILE_PROCESSING_METHOD    IN VARCHAR2
   ,P_FILE_NAME_EXT             IN VARCHAR2
   ,P_MAX_FILE_SIZE             IN NUMBER
   ,P_MAX_TRANSMISSION_SIZE     IN NUMBER
   ,P_ZIP_REQUIRED              IN VARCHAR2
   ,P_ZIPPING_UTILITY           IN VARCHAR2
   ,P_ZIP_FILE_NAME_EXT         IN VARCHAR2
   ,P_OD_FIELD_CONTACT          IN VARCHAR2
   ,P_OD_FIELD_CONTACT_EMAIL    IN VARCHAR2
   ,P_OD_FIELD_CONTACT_PHONE    IN VARCHAR2
   ,P_CLIENT_TECH_CONTACT       IN VARCHAR2
   ,P_CLIENT_TECH_CONTACT_EMAIL IN VARCHAR2
   ,P_CLIENT_TECH_CONTACT_PHONE IN VARCHAR2
   ,P_FILE_NAME_SEQ_RESET       IN VARCHAR2
   ,P_FILE_NEXT_SEQ_NUMBER      IN NUMBER
   ,P_FILE_SEQ_RESET_DATE       IN DATE
   ,P_FILE_NAME_MAX_SEQ_NUMBER  IN NUMBER
   ,P_ATTRIBUTE1                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE2                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE3                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE4                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE5                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE6                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE7                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE8                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE9                IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE10               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE11               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE12               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE13               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE14               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE15               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE16               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE17               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE18               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE19               IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE20               IN VARCHAR2 DEFAULT NULL
  ) 
RETURN VARCHAR2;

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_EBL_TRANSMISSION                                   |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_TRANSMISSION_DTL TABLE AND ALSO VALIDATE DATE BEFORE CHANGING  |
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

  FUNCTION VALIDATE_EBL_TRANSMISSION
  (
    P_CUST_DOC_ID             IN NUMBER
   ,P_TRANSMISSION_TYPE       IN VARCHAR2
   ,P_EMAIL_SUBJECT           IN VARCHAR2
   ,P_EMAIL_STD_MESSAGE       IN VARCHAR2
   ,P_EMAIL_CUSTOM_MESSAGE    IN VARCHAR2
   ,P_EMAIL_STD_DISCLAIMER    IN VARCHAR2
   ,P_EMAIL_SIGNATURE         IN VARCHAR2
   ,P_EMAIL_LOGO_REQUIRED     IN VARCHAR2
   ,P_EMAIL_LOGO_FILE_NAME    IN VARCHAR2
   ,P_FTP_DIRECTION           IN VARCHAR2
   ,P_FTP_TRANSFER_TYPE       IN VARCHAR2
   ,P_FTP_DESTINATION_SITE    IN VARCHAR2
   ,P_FTP_DESTINATION_FOLDER  IN VARCHAR2
   ,P_FTP_USER_NAME           IN VARCHAR2
   ,P_FTP_PASSWORD            IN VARCHAR2
   ,P_FTP_PICKUP_SERVER       IN VARCHAR2
   ,P_FTP_PICKUP_FOLDER       IN VARCHAR2
   ,P_FTP_CUST_CONTACT_NAME   IN VARCHAR2
   ,P_FTP_CUST_CONTACT_EMAIL  IN VARCHAR2
   ,P_FTP_CUST_CONTACT_PHONE  IN VARCHAR2
   ,P_FTP_NOTIFY_CUSTOMER     IN VARCHAR2
   ,P_FTP_CC_EMAILS           IN VARCHAR2
   ,P_FTP_EMAIL_SUB           IN VARCHAR2
   ,P_FTP_EMAIL_CONTENT       IN VARCHAR2
   ,P_FTP_SEND_ZERO_BYTE_FILE IN VARCHAR2
   ,P_FTP_ZERO_BYTE_FILE_TEXT IN VARCHAR2
   ,P_FTP_ZERO_BYTE_NOTIF_TXT IN VARCHAR2
   ,P_CD_FILE_LOCATION        IN VARCHAR2
   ,P_CD_SEND_TO_ADDRESS      IN VARCHAR2
   ,P_COMMENTS                IN VARCHAR2
   ,P_ATTRIBUTE1              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE2              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE3              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE4              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE5              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE6              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE7              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE8              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE9              IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE10             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE11             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE12             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE13             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE14             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE15             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE16             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE17             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE18             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE19             IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE20             IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2;

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_EBL_CONTACTS                                       |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_CONTACTS TABLE AND ALSO VALIDATE DATE BEFORE CHANGING          |
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

  FUNCTION VALIDATE_EBL_CONTACTS
  (
    P_CUST_ACCOUNT_ID    IN XX_CDH_EBL_MAIN.CUST_ACCOUNT_ID%TYPE
   ,P_TRANSMISSION_TYPE  IN XX_CDH_EBL_MAIN.EBILL_TRANSMISSION_TYPE%TYPE
   ,P_PAYDOC_IND         IN VARCHAR2
   ,P_EBL_DOC_CONTACT_ID IN NUMBER
   ,P_CUST_DOC_ID        IN NUMBER
   ,P_ORG_CONTACT_ID     IN NUMBER
   ,P_CUST_ACCT_SITE_ID  IN NUMBER
   ,P_ATTRIBUTE1         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE2         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE3         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE4         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE5         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE6         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE7         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE8         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE9         IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE10        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE11        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE12        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE13        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE14        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE15        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE16        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE17        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE18        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE19        IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE20        IN VARCHAR2 DEFAULT NULL
  ) RETURN VARCHAR2;

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : VALIDATE_EBL_FILE_NAME                                      |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_FILE_NAME_DTL TABLE AND ALSO VALIDATE DATE BEFORE CHANGING     |
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

  FUNCTION VALIDATE_EBL_FILE_NAME
  (
    P_EBL_FILE_NAME_ID         IN NUMBER
   ,P_CUST_DOC_ID              IN NUMBER
   ,P_FILE_NAME_ORDER_SEQ      IN NUMBER
   ,P_FIELD_ID                 IN NUMBER
   ,P_CONSTANT_VALUE           IN VARCHAR2
   ,P_DEFAULT_IF_NULL          IN VARCHAR2
   ,P_COMMENTS                 IN VARCHAR2
   ,P_FILE_NAME_SEQ_RESET      IN VARCHAR2
   ,P_FILE_NEXT_SEQ_NUMBER     IN NUMBER
   ,P_FILE_SEQ_RESET_DATE      IN DATE
   ,P_FILE_NAME_MAX_SEQ_NUMBER IN NUMBER
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
  -- | NAME        : VALIDATE_EBL_TEMPL_HEADER                                   |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_TEMPL_HEADER TABLE AND ALSO VALIDATE DATE BEFORE CHANGING      |
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

  FUNCTION VALIDATE_EBL_TEMPL_HEADER
  (
    P_CUST_ACCOUNT_ID          IN NUMBER
   ,P_CUST_DOC_ID              IN NUMBER
   ,P_EBILL_FILE_CREATION_TYPE IN VARCHAR2
   ,P_DELIMITER_CHAR           IN VARCHAR2
   ,P_LINE_FEED_STYLE          IN VARCHAR2
   ,P_INCLUDE_HEADER           IN VARCHAR2
   ,P_LOGO_FILE_NAME           IN VARCHAR2
   ,P_FILE_SPLIT_CRITERIA      IN VARCHAR2
   ,P_FILE_SPLIT_VALUE         IN NUMBER
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
  -- | NAME        : VALIDATE_EBL_STD_AGGR_DTL                                   |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION WILL BE USED TO VALIDATE DATE BEFORE INSERTING INTO         |
  -- | XX_CDH_EBL_STD_AGGR_DTL TABLE AND ALSO VALIDATE DATE BEFORE CHANGING      |
  -- | THE DOCUMENT STATUS FROM "IN PROCESS" TO "TESTING" (OR) FROM "TESTING"    |
  -- | TO "COMPLETE". THIS VALIDATION PACKAGE IS NOT CALLED FOR ETXT.            |
  -- |                                                                           |
  -- |                                                                           |
  -- | PARAMETERS  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | RETURNS     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

  FUNCTION VALIDATE_EBL_STD_AGGR_DTL
  (
    P_EBL_AGGR_ID     IN NUMBER
   ,P_CUST_DOC_ID     IN NUMBER
   ,P_AGGR_FUN        IN VARCHAR2
   ,P_AGGR_FIELD_ID   IN NUMBER
   ,P_CHANGE_FIELD_ID IN NUMBER
   ,P_LABEL_ON_FILE   IN VARCHAR2
   ,P_ATTRIBUTE1      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE2      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE3      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE4      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE5      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE6      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE7      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE8      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE9      IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE10     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE11     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE12     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE13     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE14     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE15     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE16     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE17     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE18     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE19     IN VARCHAR2 DEFAULT NULL
   ,P_ATTRIBUTE20     IN VARCHAR2 DEFAULT NULL
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

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : INSERT_EBL_ERROR                                            |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS FUNCTION IS USED TO INSERT DATA INTO ERROR TABLE (XX_CDH_EBL_ERROR), |
  -- | WHEN VALIDATION PROGRAM COMES ACROSS AN ERROR.                            |
  -- |                                                                           |
  -- |                                                                           |
  -- | PARAMETERS  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | RETURNS     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

  FUNCTION INSERT_EBL_ERROR
  (
    P_CUST_DOC_ID      IN NUMBER
   ,P_DOC_PROCESS_DATE IN DATE
   ,P_ERROR_CODE       IN VARCHAR2
   ,P_ERROR_DESC       IN VARCHAR2
  ) RETURN VARCHAR2;

  -- +===========================================================================+
  -- |                                                                           |
  -- | NAME        : DELETE_EBL_ERROR                                            |
  -- |                                                                           |
  -- | DESCRIPTION :                                                             |
  -- | THIS PROCEDURE IS USED TO DELETE DATA INTO ERROR TABLE (XX_CDH_EBL_ERROR).|
  -- |                                                                           |
  -- |                                                                           |
  -- | PARAMETERS  :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- | RETURNS     :                                                             |
  -- |                                                                           |
  -- |                                                                           |
  -- +===========================================================================+

  PROCEDURE DELETE_EBL_ERROR(P_CUST_DOC_ID IN NUMBER);

END XX_CDH_EBL_VALIDATE_PKG;
/
SHOW ERRORS;
