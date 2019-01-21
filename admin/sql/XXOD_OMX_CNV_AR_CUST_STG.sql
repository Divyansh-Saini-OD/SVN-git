REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Program Name   : CREATE XXOD_OMX_CNV_AR_CUST_STG.tbl                                         |--
--|                                                                                             |--
--| Purpose        : Create Custom Tables .                                                     |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                1. XXOD_OMX_CNV_AR_CUST_STG   (OD Conversion OMX/"OD North" AR Customers     |--
--| RICE ID :                                                                                   |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By           Description                         |--
--+=============================================================================================+-- 
--| 1.0              04-DEC-2017       Punit Gupta          Original                            |--
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
PROMPT Creating the Table XXOD_OMX_CNV_AR_CUST_STG......
PROMPT

CREATE TABLE XXOD_OMX_CNV_AR_CUST_STG
 ( 
    RECORD_ID             NUMBER,
	ODN_CUST_NUM          VARCHAR2(30),
    ODN_CUST_NAME         VARCHAR2(360),
    ORG_ADDRESS1          VARCHAR2(240),
    ORG_ADDRESS2          VARCHAR2(240),
    ORG_CITY              VARCHAR2(60),
    ORG_STATE             VARCHAR2(60),
    ORG_ZIPCODE           VARCHAR2(60),
    ORG_CONTACT_NAME      VARCHAR2(360),
    ORG_CONTACT_EMAIL     VARCHAR2(2000),
    ORG_CONTACT_PHONE     VARCHAR2(40),
    BILL_TO_CNSGNO        VARCHAR2(60),
    BILL_TO_ADDRESS1      VARCHAR2(240),
    BILL_TO_ADDRESS2      VARCHAR2(240),
    BILL_TO_CITY          VARCHAR2(60),
    BILL_TO_STATE         VARCHAR2(60),
    BILL_TO_ZIPCODE       VARCHAR2(60),
    BILL_TO_CONTACT_NAME  VARCHAR2(360),
    BILL_TO_CONTACT_EMAIL VARCHAR2(2000),
    BILL_TO_CONTACT_PHONE VARCHAR2(40),
    SHIP_TO_CNSGNO        VARCHAR2(60),
    SHIP_TO_ADDRESS1      VARCHAR2(240),
    SHIP_TO_ADDRESS2      VARCHAR2(240),
    SHIP_TO_CITY          VARCHAR2(60),
    SHIP_TO_STATE         VARCHAR2(60),
    SHIP_TO_ZIPCODE       VARCHAR2(60),
    SHIP_TO_CONTACT_NAME  VARCHAR2(360),
    SHIP_TO_CONTACT_EMAIL VARCHAR2(2000),
    SHIP_TO_CONTACT_PHONE VARCHAR2(40),
    INTERFACE_ID          NUMBER,
    REQUEST_ID            NUMBER,
    RECORD_STATUS         VARCHAR2(1),
    CONV_ERROR_MSG        VARCHAR2(4000),
    CREATION_DATE         DATE,
    CREATED_BY            NUMBER,
    LAST_UPDATE_DATE      DATE,
    LAST_UPDATED_BY       NUMBER,
    LAST_UPDATE_LOGIN     NUMBER,
   -- PROCESS_FLAG	      VARCHAR2(1),
    BATCH_ID		      NUMBER
  --,BATCH_SOURCE_NAME VARCHAR2(50)
  -- CONV_ERROR_FLAG          VARCHAR2(5),
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



