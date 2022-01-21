SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE VIEW XX_PO_RESP_CATSETS_V AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :      E0990 IPO Restrict Items                              |
-- | Description : This view pick's the items that are assigned to the |
-- |  category for that particular responsibility using  the table     |
-- |  xx_po_resp_category                                              |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       10-APR-2007  Anusha R             Initial version        |
-- |1.1       07-AUG-2008  Rama Krishna K       Perf defect #9644      |
-- |1.2       16-OCT-2012  OD AMS Offshore      Perf defect #20478     |
-- |1.3       22-Mar-2016  Suresh P             Database violation     |
-- +===================================================================+
-- Added Distinct Clause for inventory item id as per defect #9644
-- Removing Distinct Clause and tuning the query as it is impacting performance for search in iProc page as per defect #20478
SELECT MIC.inventory_item_id
FROM   mtl_item_categories MIC
WHERE  1 = 1
    AND MIC.organization_id = (SELECT organization_id
                                FROM   HR_ALL_ORGANIZATION_UNITS
                                WHERE  type = 'MAS' AND date_from <= SYSDATE
                                AND    NVL(date_to,SYSDATE+1) >= SYSDATE
                                AND rownum<2
                               )
   AND MIC.category_set_id IN (SELECT category_set_id
                                FROM   xx_po_resp_category XPRC
                                WHERE  resp_id = FND_PROFILE.VALUE('RESP_ID')
                                AND    XPRC.enable_flag = 'Y'
                                UNION
                                SELECT ds.category_set_id
                                FROM   mtl_default_category_sets ds,
                                       mtl_category_sets_tl cst
                                WHERE  ds.functional_area_id = 2
                                   AND cst.category_set_id(+) = ds.category_set_id
                                   AND 0 = NVL((SELECT COUNT(1)
                                                FROM   xx_po_resp_category XPRC
                                                where  RESP_ID = FND_PROFILE.value('RESP_ID')
                                                and    XPRC.ENABLE_FLAG = 'Y'),0));
    -- Removed the inner group for category_set_id and organization_id as per defect #20478

SHOW ERROR