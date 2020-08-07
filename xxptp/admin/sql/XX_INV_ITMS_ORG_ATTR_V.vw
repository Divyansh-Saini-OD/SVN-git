--**************************************************************************************************
--
-- Object Name    : E0420_ItemFormZoom 
--
-- Program Name   : XX_INV_ITMS_ORG_ATTR_V.vw
--
-- Author         : Seemant Gour - Oracle Corporation 
--
-- Purpose        : Create Custom view to maintain RMS items Location/Organization information.
--                  The Objects created are:
--                     1) XX_INV_ITMS_ORG_ATTR_V view
--
-- Change History  :
-- Version         Date             Changed By        Description 
--**************************************************************************************************
-- 1.0             25/05/2007       Seemant Gour      Orignal code 
-- 1.1             27/05/2007       Seemant Gour      Removed custom schema (XXPTP) reference from table
--**************************************************************************************************

SET VERIFY      ON
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating/Replacing the Custom View XX_INV_ITMS_ORG_ATTR_V
PROMPT

CREATE OR REPLACE FORCE VIEW XX_INV_ITMS_ORG_ATTR_V
         ( ROW_ID
         , INVENTORY_ITEM_ID
         , ORGANIZATION_ID          
         , OD_DIST_TARGET           
         , OD_EBW_QTY               
         , OD_INFINITE_QTY_CD       
         , OD_LOCK_UP_ITEM_FLG      
         , OD_PROPRIETARY_TYPE_CD   
         , OD_REPLEN_SUB_TYPE_CD    
         , OD_REPLEN_TYPE_CD        
         , OD_WHSE_ITEM_CD          
         , OD_ABC_CLASS             
         , LOCAL_ITEM_DESC          
         , LOCAL_SHORT_DESC         
         , PRIMARY_SUPP             
         , OD_CHANNEL_BLOCK    
         )
AS SELECT  XIIOA.ROWID
         , XIIOA.INVENTORY_ITEM_ID      
         , XIIOA.ORGANIZATION_ID       
         , XIIOA.OD_DIST_TARGET        
         , XIIOA.OD_EBW_QTY            
         , XIIOA.OD_INFINITE_QTY_CD    
         , XIIOA.OD_LOCK_UP_ITEM_FLG   
         , XIIOA.OD_PROPRIETARY_TYPE_CD
         , XIIOA.OD_REPLEN_SUB_TYPE_CD 
         , XIIOA.OD_REPLEN_TYPE_CD     
         , XIIOA.OD_WHSE_ITEM_CD       
         , XIIOA.OD_ABC_CLASS          
         , XIIOA.LOCAL_ITEM_DESC       
         , XIIOA.LOCAL_SHORT_DESC      
         , XIIOA.PRIMARY_SUPP          
         , XIIOA.OD_CHANNEL_BLOCK
FROM  XX_INV_ITEM_ORG_ATTRIBUTES    XIIOA
WITH READ ONLY;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM*****************************************************************
REM                        End Of Script                           * 
REM*****************************************************************
