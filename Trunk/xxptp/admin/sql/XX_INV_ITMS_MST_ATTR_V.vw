--**************************************************************************************************
--
-- Object Name    : E0420_ItemFormZoom 
--
-- Program Name   : XX_INV_ITMS_MST_ATTR_V.vw
--
-- Author         : Seemant Gour - Oracle Corporation 
--
-- Purpose        : Create Custom view to maintain RMS items Master information.  
--                  The Objects created are:
--                     1) XX_INV_ITMS_MST_ATTR_V view
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
PROMPT Creating/Replacing the Custom View XX_INV_ITMS_MST_ATTR_V
PROMPT

CREATE OR REPLACE FORCE VIEW XX_INV_ITMS_MST_ATTR_V
         ( ROW_ID
         , INVENTORY_ITEM_ID   
         , ORGANIZATION_ID
         , ORDER_AS_TYPE            
         , PACK_IND                 
         , PACK_TYPE                
         , PACKAGE_SIZE             
         , SHIP_ALONE_IND           
         , HANDLING_SENSITIVITY     
         , OD_META_CD               
         , OD_OVRSIZE_DELVRY_FLG    
         , OD_PROD_PROTECT_CD       
         , OD_GIFT_CERTIF_FLG       
         , OD_IMPRINTED_ITEM_FLG    
         , OD_RECYCLE_FLG          
         , OD_READY_TO_ASSEMBLE_FLG 
         , OD_PRIVATE_BRAND_FLG     
         , OD_GSA_FLG               
         , OD_CALL_FOR_PRICE_CD     
         , OD_COST_UP_FLG           
         , MASTER_ITEM              
         , SUBSELL_MASTER_QTY       
         , SIMPLE_PACK_IND          
         , OD_LIST_OFF_FLG          
         , OD_ASSORTMENT_CD         
         , OD_OFF_CAT_FLG           
         , OD_SKU_TYPE_CD           
         , ITEM_NUMBER_TYPE         
         , SHORT_DESC               
         , STORE_ORD_MULT           
         , OD_RETAIL_PRICING_FLG
         )
AS SELECT  XIIMA.ROWID
         , XIIMA.INVENTORY_ITEM_ID   
         , XIIMA.ORGANIZATION_ID
         , XIIMA.ORDER_AS_TYPE           
         , XIIMA.PACK_IND                
         , XIIMA.PACK_TYPE               
         , XIIMA.PACKAGE_SIZE            
         , XIIMA.SHIP_ALONE_IND          
         , XIIMA.HANDLING_SENSITIVITY    
         , XIIMA.OD_META_CD              
         , XIIMA.OD_OVRSIZE_DELVRY_FLG   
         , XIIMA.OD_PROD_PROTECT_CD      
         , XIIMA.OD_GIFT_CERTIF_FLG      
         , XIIMA.OD_IMPRINTED_ITEM_FLG   
         , XIIMA.OD_RECYCLE_FLG         
         , XIIMA.OD_READY_TO_ASSEMBLE_FLG
         , XIIMA.OD_PRIVATE_BRAND_FLG    
         , XIIMA.OD_GSA_FLG              
         , XIIMA.OD_CALL_FOR_PRICE_CD    
         , XIIMA.OD_COST_UP_FLG          
         , XIIMA.MASTER_ITEM             
         , XIIMA.SUBSELL_MASTER_QTY      
         , XIIMA.SIMPLE_PACK_IND         
         , XIIMA.OD_LIST_OFF_FLG         
         , XIIMA.OD_ASSORTMENT_CD        
         , XIIMA.OD_OFF_CAT_FLG          
         , XIIMA.OD_SKU_TYPE_CD          
         , XIIMA.ITEM_NUMBER_TYPE        
         , XIIMA.SHORT_DESC  
         , XIIMA.STORE_ORD_MULT   
         , XIIMA.OD_RETAIL_PRICING_FLG
FROM XX_INV_ITEM_MASTER_ATTRIBUTES XIIMA
WITH READ ONLY;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM*****************************************************************
REM                        End Of Script                           * 
REM*****************************************************************
