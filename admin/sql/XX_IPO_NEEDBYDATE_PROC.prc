SET SHOW OFF 
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Procedure  XX_IPO_NEEDBYDATE_PROC

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PROCEDURE XX_IPO_NEEDBYDATE_PROC(
                                                   p_item_id           IN OUT NOCOPY NUMBER
                                                  ,p_need_by_date      IN OUT NOCOPY DATE
                                                  ,p_return_code          OUT NOCOPY NUMBER
                                                  ,p_error_msg            OUT NOCOPY VARCHAR2
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
-- |1.1       18-JAN-2006  Radhika Raman        Modified for defect 3583|
-- +====================================================================+
-- +====================================================================+
-- | Name : XX_IPO_NEEDBYDATE_PROC                                      |
-- | Description : This Procedure is to assign                          |
-- | the Need By date to the PO Requisition with the help of the lead   |
-- | time of the item selected.(Need by date=Sydate+Lead time of the    |
-- | item selected)                                                     |
-- | Parameters :  p_item_id,p_need_by_date,                            |
-- |              ,p_return_code,p_error_msg,p_deliver_to_org_id        |
-- |                                                                    |
-- | Returns    :  p_item_id,p_need_by_date, p_return_code,p_error_msg, |
-- |               p_deliver_to_org_id                                  |
-- +====================================================================+
   ln_tot_lead_time   NUMBER;
   ln_pre_time        NUMBER;
   ln_full_time       NUMBER;
   ln_post_time       NUMBER;
   lc_loc_err_msg     VARCHAR2(2000);
   lc_error_loc       VARCHAR2(200);
   lc_internal_item   VARCHAR2(1);
   ln_organization_id NUMBER;          --Included for the Defect 3583 Assign Need By Date Dt 30 Jan 2007 by Madankumar J, Wipro Technologies
BEGIN
   lc_error_loc:='Fetching lead times';
  --<<BEGIN>> Modification for the Defect 3583 Assign Need By Date Dt 30 Jan 2007 by Madankumar J, Wipro Technologies
   SELECT OOD.organization_id 
   INTO ln_organization_id
   FROM 
   org_organization_definitions OOD
  ,xx_fin_translatedefinition XFTD
  ,xx_fin_translatevalues XFTV
   WHERE 
   OOD.organization_name = XFTV.source_value2 
  AND XFTD.translation_name='OD_ITEM_VALIDATION_UNIT'
  AND XFTV.source_value1=FND_GLOBAL.org_name 
  AND XFTV.enabled_flag='Y'
  AND XFTD.translate_id = XFTV.translate_id
  AND TRUNC(NVL(XFTV.end_date_active,SYSDATE+1)) > TRUNC(SYSDATE);
  --<<END>> Modification for the Defect 3583 Assign Need By Date Dt 30 Jan 2007 by Madankumar J, Wipro Technologies

   SELECT NVL (msi.preprocessing_lead_time,0)
         ,NVL (msi.full_lead_time,0)
         ,NVL (msi.postprocessing_lead_time,0)
         ,internal_order_flag
   INTO ln_pre_time
        ,ln_full_time
        ,ln_post_time
        ,lc_internal_item
   FROM mtl_system_items_b msi
   WHERE msi.inventory_item_id = p_item_id
   AND organization_id = ln_organization_id;    --Included for the Defect 3583 Assign Need By Date Dt 30 Jan 2007 by Madankumar J, Wipro Technologies

   ln_tot_lead_time := ln_pre_time + ln_full_time + ln_post_time;

   IF lc_internal_item <> 'Y' THEN
      IF ln_tot_lead_time <> 0
      THEN
         lc_error_loc:='Finding need by date';
         p_need_by_date := TO_DATE(TO_CHAR(TRUNC(SYSDATE + ln_tot_lead_time),'MM/DD/YYYY')||' 23:59:59','MM/DD/YYYY HH24:MI:SS');
      END IF;
   END IF;
   p_return_code := 0;
   p_error_msg := '';
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      p_return_code := 0;
   WHEN OTHERS THEN
      p_return_code := 1;
      FND_MESSAGE.SET_NAME( application =>'XXFIN', name  =>'XX_IPO_0001_ERROR');
      FND_MESSAGE.SET_TOKEN(token => 'NEED_BY_DATE',value => p_need_by_date);
      FND_MESSAGE.SET_TOKEN( token => 'ITEM_ID',value => p_item_id);
      FND_MESSAGE.SET_TOKEN(token =>'ERR_ORA',value =>SQLERRM);
      
      lc_loc_err_msg :=  FND_MESSAGE.GET;
      
      XX_COM_ERROR_LOG_PUB.LOG_ERROR (
                                      p_program_type           => 'PROCEDURE'
                                     ,p_program_name           => 'XX_IPO_NEEDBYDATE_PROC'
                                     ,p_module_name            => 'PO'
                                     ,p_error_location         => lc_error_loc
                                                                  || SUBSTR(p_need_by_date,1,50)                                     
                                     ,p_error_message_code     => 'XX_IPO_0001_ERROR'
                                     ,p_error_message          => lc_loc_err_msg                                     
                                     ,p_notify_flag            => 'N'
                                     ,p_object_type            => 'Extension'
                                     ,p_object_id              => 'E0979'
                                    );                               
END;
/
SHOW ERRORS

