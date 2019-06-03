-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                             Office Depot                          |
-- +===================================================================+
-- | Name  : APPS.XX_PO_ALLOCATION_DETAILS_V                           |
-- | Description: View for Allocatino OAF Screen                       |
-- |                                                                   |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |1.0      06-21-2007   K.CRAWFORD       INITAL CODE                 |
-- +===================================================================+



CREATE OR REPLACE VIEW XX_PO_ALLOCATION_DETAILS_V
(ALLOCATION_LINE_ID, QOH, ONORDER, INTRANSIT, RUTL, 
 RTC, AWS, WEEKS_SUPPLY, INNER_PK, CASE_PK)
AS 
SELECT A.ALLOCATION_LINE_ID
   ,COALESCE(QOH ,0)  QOH
   ,COALESCE(E.ONORDER ,0) ONORDER
   ,COALESCE(C.BALANCE_QTY,0)  INTRANSIT 
  
   ,TO_NUMBER(COALESCE(B.RUTL ,'0'))  RUTL
   ,B.RTC
   ,2 AWS --STILL NEED
   ,1.2 WEEKS_SUPPLY -- On hand / AWS --STILL NEED-
   ,6 INNER_PK --STILL NEED
   ,30 CASE_PK --STILL NEED
 --  ,A.ALLOC_ORGANIZATION_ID
   --,A.ITEM_ID
 
    
    
    
      
FROM (SELECT
     AL.ALLOCATION_LINE_ID,
     AL.ALLOC_ORGANIZATION_ID,
     AH.ITEM_ID 
   FROM  XX_PO_ALLOCATION_LINES AL,
       XX_PO_ALLOCATION_HEADER AH
   WHERE AL.ALLOCATION_HEADER_ID = AH.ALLOCATION_HEADER_ID) A ,
        (SELECT          
         MCAT.SEGMENT1 RUTL,
         MCAT.SEGMENT7 RTC,
   AH.ITEM_ID,
   AL.ALLOC_ORGANIZATION_ID
            
        FROM XX_PO_ALLOCATION_LINES AL, 
          PO_HEADERS_ALL PO, 
          XX_PO_ALLOCATION_HEADER AH,
          MTL_ITEM_CATEGORIES I,
          MTL_CATEGORIES_B MCAT,
          MTL_CATEGORY_SETS S --,
--    MTL_SYSTEM_ITEMS_B MSI  
        WHERE PO.PO_HEADER_ID = AL.PO_HEADER_ID
          AND AH.ALLOCATION_HEADER_ID = AL.ALLOCATION_HEADER_ID
          AND I.INVENTORY_ITEM_ID = AH.ITEM_ID
          AND I.ORGANIZATION_ID = AL.ALLOC_ORGANIZATION_ID
          AND MCAT.CATEGORY_ID = I.CATEGORY_ID
  
       --   AND S.CATEGORY_SET_NAME = 'Inventory'
        AND S.CATEGORY_SET_NAME = 'RMS Location Traits Attributes'
          AND S.STRUCTURE_ID = MCAT.STRUCTURE_ID) B  
      ,(SELECT
         L.TO_ORGANIZATION_ID,
         L.ITEM_ID,
           SUM(L.QUANTITY_SHIPPED - L.QUANTITY_RECEIVED) BALANCE_QTY 
      FROM RCV_SHIPMENT_LINES L       
      WHERE  L.SHIPMENT_LINE_STATUS_CODE != 'FULLY RECEIVED'
     AND  L.TO_SUBINVENTORY = 'STOCK'
      GROUP BY L.TO_ORGANIZATION_ID,
           L.ITEM_ID) C    
 , (SELECT M.INVENTORY_ITEM_ID ITEM_ID, 
       M.ORGANIZATION_ID, 
     SUM(M.PRIMARY_TRANSACTION_QUANTITY) QOH
    FROM MTL_ONHAND_QUANTITIES_DETAIL M
  WHERE  M.SUBINVENTORY_CODE = 'STOCK'
   GROUP BY  M.INVENTORY_ITEM_ID, 
       M.ORGANIZATION_ID) D
 ,(SELECT    
         AL.ALLOCATION_LINE_ID,
         SUM(POLL.QUANTITY - POLL.QUANTITY_RECEIVED) ONORDER
   --OVER (PARTITION BY AL.ALLOCATION_LINE_ID) ONORDER,
   
       FROM PO_LINE_LOCATIONS_ALL POLL, 
            XX_PO_ALLOCATION_LINES AL,
            PO_LINES_ALL POL ,
          XX_PO_ALLOCATION_HEADER AH       
       WHERE POLL.QUANTITY_RECEIVED < POLL.QUANTITY  
      AND POLL.CLOSED_DATE IS NULL     
         AND POLL.PO_LINE_ID=POL.PO_LINE_ID
   AND POLL.PO_HEADER_ID = POL.PO_HEADER_ID
         AND AH.ITEM_ID =POL.ITEM_ID
         AND AH.ALLOCATION_HEADER_ID = AL.ALLOCATION_HEADER_ID
         AND AL.ALLOC_ORGANIZATION_ID =POLL.SHIP_TO_ORGANIZATION_ID
   GROUP BY  AL.ALLOCATION_LINE_ID
   ) E 
WHERE A.ITEM_ID = B.ITEM_ID(+)
  AND A.ALLOC_ORGANIZATION_ID = B.ALLOC_ORGANIZATION_ID(+)
  AND A.ALLOC_ORGANIZATION_ID = C.TO_ORGANIZATION_ID(+)
  AND A.ITEM_ID = D.ITEM_ID(+)
  AND A.ALLOC_ORGANIZATION_ID = D.ORGANIZATION_ID(+)
  AND A.ALLOCATION_LINE_ID = E.ALLOCATION_LINE_ID(+)
 