REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Program Name   : CREATE XXOD_OMX_CNV_AR_TRX_STG_HIST.tbl                                              |--
--|                                                                                             |--
--| Purpose        : Create Custom Tables .                                                     |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                1. XXOD_OMX_CNV_AR_TRX_STG_HIST   (OD Conversion OMX/"OD North" AR Transactions   |--
--| RICE ID : C0704                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By           Description                         |--
--+=============================================================================================+--
--| 1.0              23-JAN-2018       Punit Gupta          Original                            |--
--+=============================================================================================+--

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Creating the Custom Table ......
PROMPT

PROMPT
PROMPT Creating the Table XXOD_OMX_CNV_AR_TRX_STG_HIST......
PROMPT

CREATE TABLE XXFIN.XXOD_OMX_CNV_AR_TRX_STG_HIST
 ( 
   RECORD_ID    NUMBER
  ,ACCT_NO		VARCHAR2(30)
  ,PAY_DUE_DATE		DATE
  ,INV_NO		VARCHAR2(20)
  ,INV_SEQ_NO	VARCHAR2(20)
  ,INV_CREATION_DATE		DATE
  ,CNSG_NO		VARCHAR2(20)
  ,BILL_CNSG_NO	VARCHAR2(20)
  ,SUM_CYCLE		VARCHAR2(1)
  ,SHIP_TO_LOC		NUMBER
  ,PO_NO			VARCHAR2(40)
  ,TRAN_TYPE		NUMBER
  ,INV_AMT		NUMBER
  ,TAX_AMT		NUMBER
  ,ORD_NO		VARCHAR2(20)
  ,TIER1_IND		VARCHAR2(1)
  ,ADJ_CODE			VARCHAR2(2)
  ,DESCRIPTION	VARCHAR2(2000)
  ,PROCESS_FLAG	VARCHAR2(1)
  ,BATCH_ID		NUMBER
  ,BATCH_SOURCE_NAME VARCHAR2(50)
  ,CONV_ERROR_FLAG          VARCHAR2(5)
  ,CONV_ERROR_MSG           VARCHAR2(4000)
  ,REQUEST_ID               NUMBER
  ,CREATED_BY               NUMBER
  ,CREATION_DATE            DATE
  ,LAST_UPDATED_BY          NUMBER
  ,LAST_UPDATE_DATE         DATE 
);

PROMPT Table Created Successfully

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT 

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================



