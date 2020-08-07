--**************************************************************************************************
--
-- Object Name    : E033 GlobalPOIndicator 
--
-- Program Name   : XX_PO_GLOBAL_INDICATOR_V.vw
--
-- Author         : Arun Andavar.N - Oracle Corporation 
--
-- Purpose        : Create Custom view to maintain GlobalPO Indicator information.  
--                  The Objects created are:
--                     1) XX_PO_GLOBAL_INDICATOR_V view
--
-- Change History  :
-- Version         Date             Changed By        Description 
--**************************************************************************************************
-- 1.0             23/04/2007       Arun Andavar      Orignal code
-- 1.1             10/07/2007       Arun Andavar      Lookup used in the view is removed and column
--                                                     global_indicator_code is removed.
--**************************************************************************************************
SET VERIFY      ON
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Creating the Custom View XX_PO_GLOBAL_INDICATOR_V
PROMPT


WHENEVER SQLERROR EXIT 1 

CREATE OR REPLACE VIEW XX_PO_GLOBAL_INDICATOR_V
(SOURCE_TERRITORY_CODE
,SRC_TERRITORY_SHORT_NAME
,DESTINATION_TERRITORY_CODE
,DEST_TERRITORY_SHORT_NAME
,GLOBAL_INDICATOR_NAME
,START_DATE
,END_DATE
,CREATED_BY
,CREATION_DATE
,LAST_UPDATED_BY
,LAST_UPDATE_DATE
,LAST_UPDATE_LOGIN
)
AS 
SELECT XPGI.source_territory_code 
      ,FTV.territory_short_name src_territory_short_name 
      ,XPGI.destination_territory_code 
      ,FTV1.territory_short_name dest_territory_short_name 
      ,XPGI.global_indicator_name 
      ,XPGI.start_date 
      ,XPGI.end_date 
      ,XPGI.created_by 
      ,XPGI.creation_date 
      ,XPGI.last_updated_by 
      ,XPGI.last_update_date 
      ,XPGI.last_update_login 
FROM   xx_po_global_indicator XPGI 
      ,fnd_territories_vl FTV 
      ,fnd_territories_vl FTV1 
WHERE  FTV.territory_code = XPGI.source_territory_code 
AND    FTV1.territory_code = XPGI.destination_territory_code;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM*****************************************************************
REM                        End Of Script                           * 
REM*****************************************************************