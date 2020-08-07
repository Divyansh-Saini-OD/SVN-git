CREATE OR REPLACE PROCEDURE APPS.XX_IPO_NEEDBYDATE_PROC(
   p_item_id            IN OUT NOCOPY NUMBER,
   p_need_by_date       IN OUT NOCOPY DATE,
   p_return_code           OUT NOCOPY NUMBER,
   p_error_msg             OUT NOCOPY VARCHAR2,
   p_deliver_to_org_id  IN OUT NOCOPY NUMBER
)
IS
-- +====================================================================+
-- |                  Office Depot - Project Simplify                   |
-- |                       WIPRO Technologies                           |
-- +====================================================================+
-- | Name :  Assign Need By Date - E0979                                |
-- | Description : This Extenstion will derive the Need By Date on the  |
-- | basis of lead time of the item that is defined at the inventory    |
-- | and this will be online all the time.The extension has to be active|
-- | and working all the time.                                          |
-- |                                                                    |
-- |                                                                    |
-- |Change Record:                                                      |
-- |===============                                                     |
-- |Version   Date          Author              Remarks                 |
-- |=======   ==========   =============        ========================|
-- |1.0       05-JAN-2006  Pradeep Ramasamy,    Initial version         |
-- |                       Wipro Technologies                           |
-- +====================================================================+
-- +====================================================================+
-- | Name : xx_ipo_needbydate_proc                                      |
-- | Description : This Procedure is to assign                          |
-- | the Need By date to the PO Requisition with the help of the lead   |
-- | time of the item selected.(Need by date=Sydate+Lead time of the    |
-- | item selected)                                                     |
-- | Parameters :  p_item_id,p_need_by_date,                            |
-- |              ,p_return_code,p_error_msg,p_deliver_to_org_id        |
-- +====================================================================+
   ln_tot_lead_time   NUMBER;
   ln_pre_time        NUMBER;
   ln_full_time       NUMBER;
   ln_post_time       NUMBER;
BEGIN
   SELECT NVL (msi.preprocessing_lead_time,0),
          NVL (msi.full_lead_time,0),
          NVL (msi.postprocessing_lead_time,0)
     INTO ln_pre_time,
          ln_full_time,
          ln_post_time
     FROM mtl_system_items_fvl msi
    WHERE msi.inventory_item_id = p_item_id
      AND organization_id = p_deliver_to_org_id;

   ln_tot_lead_time := ln_pre_time + ln_full_time + ln_post_time;

   IF ln_tot_lead_time <> 0 
   THEN
    p_need_by_date := TO_DATE(TO_CHAR(TRUNC(SYSDATE + ln_tot_lead_time),'MM/DD/YYYY')||' 23:59:59','MM/DD/YYYY HH24:MI:SS');
   END IF;
   p_return_code := 0;
   p_error_msg   := '';
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      p_return_code := 0;
   WHEN OTHERS
   THEN
      p_return_code := 1;
      p_error_msg := 'Oracle Error:' ||SQLERRM ||' Detected at: ' ||
                     'Assign Need By date: '|| p_need_by_date ||' for the Item'|| p_item_id ;
END XX_IPO_NEEDBYDATE_PROC;
/

SHOW ERRORS;