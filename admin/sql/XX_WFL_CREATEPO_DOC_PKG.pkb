
SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE
PACKAGE BODY XX_WFL_CREATEPO_DOC_PKG  
-- +==================================================================================================+
-- |                  Office Depot - Project Simplify                                                 |
-- |                  WIPRO Technologies                                                              |
-- +==================================================================================================+
-- | Name        :  XX_WFL_CREATEPO_DOC_PKG.pkb                                                       |
-- | Description :  This script is used to process each requisition for which PO                      |
-- |                needs to be created.                                                              |
-- |                1.XX_IS_REQ_FROM_SALES_ORDER Procedure->Will check whether the                    |
-- |              requisition is created from a backtoback or dropship salesorder.(E0216)             |
-- |            2.If requisition created from BacktoBack/Dropship so line,check                       |
-- |              whether we have enough information to group the requisition lines                   | 
-- |              based on the custom logic.This is done by the procedure                             | 
-- |              XX_GET_REQ_INFO_TO_GROUP.(RiceId:E0216)                                             |
-- |            3.If enough information is found for grouping the requisition,                        | 
-- |              call the XX_GROUP_REQ_LINES procedure to group the requisition lines                |
-- |              for backtoback/dropship to create PO's.After grouping insert the                    | 
-- |              attribute_category,attribute6,attribute7 columns of requisition                     | 
-- |              lines table into po_headers_interface.(RiceID:E0216)                                |
-- |            4.Just before creating AUTOCREATE PO,check whether the data in                        |
-- |              the po interface is  from a dropship/backtoback.This is done by                     |
-- |              XX_IS_PO_DROPSHP_B2B.(RiceID:E0216)                                                 | 
-- |            5.If the PO in the interface is from a dropship/backtoback,                           |
-- |              call XX_CREATE_PO procedure which inturn calls                                      |  
-- |              XX_PO_INTERFACE_PKG.CREATE_DOCUMENTS package to insert the                          |
-- |                  attribute columns into PO_HEADERS_ALL table.(RiceID:E0216).                     |  
-- |                6.XX_IS_PO_FROM_SALES_ORDER procedure checks whether the PO created               |
-- |                  is for a Back to back or dropship sales order line.If Yes,then the              |                                                                     
-- |              PO line is checked for ONETIME deal or NONCODE in the procedure                     |                                                                     
-- |              XX_IS_PO_LINE_DEAL_NONCODE.(RiceID:E0240)                                           |                                                                     
-- |            7.XX_IS_PO_LINE_DEAL_NONCODE checks whether the PO line is ONETIME                    |                                                                     
-- |              deal or NONCODE.IF PO line is either ONETIME or NONCODE ,the PO is                  |                                                                    
-- |                  set to Incomplete status and not approved.(RiceID:E0240)                        |                                                                     
-- |Change Record:                                                                                    |
-- |===============                                                                                   |
-- |Rice Id Version   Date        Author                  Remarks                                     |
-- |======= =======   ==========  =============           ============================                |
-- |                                                                                                  |
-- |E0216   V1.0     10-APR-2007  SANDEEP GORLA(WIPRO)    First Version.                              |                                            
-- |E0216   V1.1     30-MAY-2007  SANDEEP GORLA(WIPRO)    Modified code as per new naming standards.  |
-- |E0240   V1.2     02-JUN-2007  SANDEEP GORLA(WIPRO)    Added procedures and logic for theextension |
-- |                                                      E0240_POApprovalProcess.                    |
-- |E0240&                                                                                            |
-- |E0216   V1.3     07-JUN-2007  SANDEEP GORLA(WIPRO)    Changed the code to assign error_code       |
-- |                                                      direclty to the global exception procedure  |
-- |                                                      XX_LOG_EXCEPTION_PROC instead of custom     | 
-- |                                                      numbers                                     |
-- |E0240   V1.4     15-Nov-2007  Matthew Craig           Updated to use extension table and not DFF  |
-- +==================================================================================================+
                                                                      
AS


-- Read the profile option that enables/disables the debug log
g_po_wf_debug VARCHAR2(1) := NVL(FND_PROFILE.VALUE('PO_SET_DEBUG_WORKFLOW_ON'),'N');


x_progress              VARCHAR2(300);

lc_error_msg            xxom.xx_om_global_exceptions.description%TYPE;
lc_entity_ref           xxom.xx_om_global_exceptions.entity_ref%TYPE;
ln_entity_ref_id        xxom.xx_om_global_exceptions.entity_ref_id%TYPE;


/* Private Procedure/Function prototypes */
--<Comments> Sandeep Gorla,Rice ID E0216,10-APR-2007
--Copied the below functions valid_contact,get_contact_id and procedure set_purchasing_org_id
--from PO_AUTOCREATE_DOC package as they are private functions/procedures to PO_AUTOCREATE_DOC package
--which cannot be used outside
--<Comments>

FUNCTION valid_contact(p_vendor_site_id number, p_vendor_contact_id number) RETURN BOOLEAN;
FUNCTION get_contact_id(p_contact_name varchar2, p_vendor_site_id number) RETURN NUMBER;



PROCEDURE set_purchasing_org_id(
    itemtype            IN VARCHAR2,
    itemkey             IN VARCHAR2,
    p_org_id            IN NUMBER,
    p_suggested_vendor_site_id      IN NUMBER
);
 




/********************************************************************************
 *  AUTHOR     : Sandeep Gorla                                              *
 *      RICE ID    : E0216_Requisition-POProcess                                *
 *      PROCEDURE  : XX_LOG_EXCEPTION_PROC                                      *
 *  DESCRIPTION: Procedure to log exceptions                                *
 *                                                                              *
 *                                                                              *
 ********************************************************************************/

PROCEDURE XX_LOG_EXCEPTION_PROC(p_error_code        IN  VARCHAR2
                               ,p_error_description IN  VARCHAR2
                               ,p_entity_ref        IN  VARCHAR2
                               ,p_entity_ref_id     IN  NUMBER
                                )
AS
x_errbuf              VARCHAR2(1000);
x_retcode             VARCHAR2(40);

BEGIN

           exception_object_type.p_exception_header  :=    G_exception_header;
           exception_object_type.p_track_code        :=    G_track_code;
           exception_object_type.p_solution_domain   :=    G_solution_domain;
           exception_object_type.p_function          :=    G_function;

           exception_object_type.p_error_code        :=    p_error_code;
       exception_object_type.p_error_description :=    p_error_description;
       exception_object_type.p_entity_ref        :=    p_entity_ref;
       exception_object_type.p_entity_ref_id     :=    p_entity_ref_id;    


           XX_OM_GLOBAL_EXCEPTION_PKG.INSERT_EXCEPTION(exception_object_type,x_errbuf,x_retcode);

END;


/*********************************************************************************************      
 *AUTHOR        : Sandeep Gorla                                                              * 
 *RICE ID       : E0216_Requisition-POProcess                                                *
 *PROCEDURE     : XX_IS_REQ_FROM_SALES_ORDER                                                 *
 *DESCRIPTION   : Procedure to check whether the requisition is from a DROPSHIP/BACKTOBACK   *
 *            sales or not.IF requisition is from DROPSHIP/BACKTOBACK,the workflow takes *
 *            the flow of grouping the requisitions to create PO's based on the custom   *
 *            grouping logic in XX_GROUP_REQ_LINES procedure.                            *
 *                                                                                           *
 *********************************************************************************************/
 
PROCEDURE XX_IS_REQ_FROM_SALES_ORDER(itemtype   IN   VARCHAR2
                                    ,itemkey    IN   VARCHAR2
                                    ,actid      IN   NUMBER
                                    ,funcmode   IN   VARCHAR2
                                    ,resultout  OUT NOCOPY  VARCHAR2 ) 
IS
ln_req_header_id    Po_Requisition_Headers_All.requisition_header_id%TYPE;
ln_sales_order      Oe_Order_Headers_All.order_number%TYPE;
lc_so_type      VARCHAR2(10);
ln_count                NUMBER;

         
BEGIN
--Get the REQ_HEADER_ID workflow attribute value into the variable for processing.
ln_req_header_id:= po_wf_util_pkg.GetItemAttrNumber
                         (itemtype => itemtype,
                          itemkey  => itemkey,
                          aname    => 'REQ_HEADER_ID');   



--Check whether the requisition is from a dropship sales order or not.

SELECT COUNT(OEH.order_number)
INTO   ln_sales_order
FROM   oe_drop_ship_sources ODSS
      ,oe_order_headers_all OEH
      ,oe_order_lines_all OEL
WHERE  OEH.header_id=OEL.header_id
AND    ODSS.line_id=OEL.line_id
AND    ODSS.requisition_header_id=ln_req_header_id;
 
        
    IF  ln_sales_order>0 THEN
    lc_so_type :='DROPSHIP' ;
    ELSE
      BEGIN ---check whether the requisition is from a backtoback sales or not
       SELECT COUNT(OEH.order_number)
       INTO   ln_sales_order
       FROM   mtl_reservations MR
             ,mtl_supply MS
             ,oe_order_lines_all OEL
             ,oe_order_headers_all OEH
       WHERE  MR.demand_source_type_id = 2
       AND    MR.demand_source_line_id = OEL.line_id
       AND    OEH.header_id=OEL.header_id
       AND    MR.supply_source_type_id =17
       AND    MR.supply_source_line_id = MS.supply_source_id
       AND    MS.req_header_id = ln_req_header_id;
         
                     
           IF ln_sales_order >0 THEN
              lc_so_type :='BACKTOBACK';
           ELSIF 
              ln_sales_order=0 THEN
              resultout     :=  wf_engine.eng_completed || ':' ||  'N';
              x_progress    := '10: xx_is_req_from_sales_order: result = N';
       
          IF (g_po_wf_debug = 'Y') THEN
             po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;
           END IF;
                  
      END;
    END IF;

    IF ln_sales_order >0 THEN    
       --Assign DROPSHIP/BACKTOBACK based on the sales order of the requisition into 
       --the custom workflow attribute XX_ORDER_TYPE
       
       po_wf_util_pkg.SetItemAttrText(itemtype   => itemtype,
                                  itemkey    => itemkey,
                                  aname      => 'XX_ORDER_TYPE',
                                      avalue     => lc_so_type);
        
       resultout    := wf_engine.eng_completed || ':' ||  'Y';
       x_progress   := '20: xx_is_req_from_sales_order: result = Y';
       IF (g_po_wf_debug = 'Y') THEN
          po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
       END IF;
    END IF;


END XX_IS_REQ_FROM_SALES_ORDER;

 

/*******************************************************************************************
 *AUTHOR     : Sandeep Gorla                                                               *
 *RICE ID    : E0216_Requisition-POProcess                                                 *
 *PROCEDURE  : XX_GET_REQ_INFO_TO_GROUP                                                    *
 *DESCRIPTION: Procedure to check whether the requisition has enough information           *   
 *             to group the requisition.                                                   * 
 *             For DROPSHIP Requisition Line->Line Type is mandatory to group.             * 
 *             For BACKTOBACK RequisitionLine->Line Type and DeliveryNumber(attribute6)    *
 *             are mandatory to group as grouping the requisitions is done based on these  *
 *             values.                                                                     * 
 *                                                                                         * 
 *******************************************************************************************/
 

PROCEDURE XX_GET_REQ_INFO_TO_GROUP(itemtype IN VARCHAR2
                                  ,itemkey  IN VARCHAR2
                                  ,actid    IN NUMBER
                                  ,funcmode IN VARCHAR2
                                  ,resultout OUT NOCOPY VARCHAR2) IS
lc_so_type           VARCHAR2(50);                          
x_group_id           NUMBER;
ln_group_id          NUMBER;
ln_req_header_id     Po_Requisition_Headers_All.requisition_header_id%TYPE;
ln_req_line_id       Po_Requisition_Lines_All.requisition_line_id%TYPE;
lc_line_type         Po_Requisition_Lines_All.attribute_category%type;
lcu_req_lines_found  VARCHAR2(1):='Y';

--lc_attribute6 is desktop address/cost center if attribute_category is dropship/Non-code Dropship
--lc_attribute6 is delivery number if attribute_category is backtoback/non-code backtoback  

lc_attribute6        Po_Requisition_Lines_All.attribute6%type; 

--lc_attribute7 is null if context is dropship/non-code dropship
--lc_attribute7 is routing number if context is backtoback/non-code backtoback

lc_attribute7        Po_Requisition_Lines_All.attribute7%type;
 



--Get the requisitions that need be processed to group  

CURSOR lcu_req_lines  
IS               
  SELECT PRLT.group_id
        ,PRLT.requisition_header_id
        ,PRLT.requisition_line_id
        ,PRL.attribute_category
        ,PRL.attribute6
        ,PRL.attribute7   
    FROM po_wf_candidate_req_lines_temp PRLT
        ,po_requisition_lines PRL
   WHERE PRLT.process_code = 'PENDING'
     AND PRLT.group_id     = x_group_id
     AND PRLT.requisition_line_id = PRL.requisition_line_id
     AND NVL(PRL.reqs_in_pool_flag,'Y') = 'Y';   


BEGIN
     x_group_id := po_wf_util_pkg.GetItemAttrNumber (itemtype => itemtype,
                             itemkey  => itemkey,
                             aname    => 'GROUP_ID');
     
     --Get the custom workflow attribute XX_ORDER_TYPE value which 
     --was assigned in the procedure XX_IS_REQ_FROM_SALES_ORDER into a local variable to process
     
     lc_so_type  := po_wf_util_pkg.GetItemAttrText(itemtype    => itemtype,
                              itemkey     => itemkey,
                              aname       => 'XX_ORDER_TYPE');                                        
OPEN lcu_req_lines;
LOOP
FETCH lcu_req_lines INTO ln_group_id,
                         ln_req_header_id,
                         ln_req_line_id,
                         lc_line_type,
                         lc_attribute6,
                         lc_attribute7;
IF (lcu_req_lines%ROWCOUNT)=0 THEN
    lcu_req_lines_found :='N';
END IF;
EXIT WHEN lcu_req_lines%NOTFOUND;
 
              
IF lc_so_type ='DROPSHIP' THEN
  
   IF lc_line_type IS NULL THEN
      --Assign this requisition line to a workflow attribute XX_REQ_LINE_ID
      --to pass it to XX_GROUP_REQ_LINES procedure's cursor so that this 
      --particular requisition will not be picked to group as lineType is not present
      
      po_wf_util_pkg.SetItemAttrNumber(itemtype   => itemtype,
                                   itemkey    => itemkey,
                                   aname      => 'XX_REQ_LINE_ID',
                                       avalue     => ln_req_line_id);
      
      FND_MESSAGE.SET_NAME ('xxom','ODP_OM_POREQ_LINETYPE_NOTFOUND');                                       
    
      lc_error_msg  :=   FND_MESSAGE.GET;
      lc_entity_ref :=  'Requisition Line Id';
      ln_entity_ref_id  :=   ln_req_line_id;
      
      XX_LOG_EXCEPTION_PROC ( 'ODP_OM_POREQ_LINETYPE_NOTFOUND'
                              ,lc_error_msg
                              ,lc_entity_ref
                              ,ln_entity_ref_id
                          );
   
      resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
      x_progress:= '10: xx_get_req_info_to_group: result = ACTIVITY_PERFORMED ' ||
                   'line_type is not found';
      IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
      END IF;
      
      RETURN;
   END IF;
   --Assign ln_requisition_line_id to 0 as this requisition has all the information to group
   ln_req_line_id := 0;
   po_wf_util_pkg.SetItemAttrNumber(itemtype   => itemtype,
                                itemkey    => itemkey,
                                aname      => 'XX_REQ_LINE_ID',
                                    avalue     => ln_req_line_id);
   resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';

   x_progress:= '20: xx_get_req_info_to_group: result = ACTIVITY_PERFORMED';
  
   IF (g_po_wf_debug = 'Y') THEN
      po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
   END IF;

ELSIF lc_so_type='BACKTOBACK' THEN

   IF lc_line_type IS NULL THEN
    --Assign this requisition line to a workflow attribute XX_REQ_LINE_ID
    --to pass it to XX_GROUP_REQ_LINES procedure's cursor so that this 
    --particular requisition will not be picked to group as lineType is not present
      po_wf_util_pkg.SetItemAttrNumber(itemtype   => itemtype,
                                   itemkey    => itemkey,
                                   aname      => 'XX_REQ_LINE_ID',
                                       avalue     => ln_req_line_id);
      
      FND_MESSAGE.SET_NAME ('xxom','ODP_OM_POREQ_LINETYPE_NOTFOUND');
     
      lc_error_msg    :=     FND_MESSAGE.GET;
      lc_entity_ref   :=    'Requisition Line Id';
      ln_entity_ref_id    :=     ln_req_line_id;
        
      XX_LOG_EXCEPTION_PROC('ODP_OM_POREQ_LINETYPE_NOTFOUND'
                        ,lc_error_msg
                        ,lc_entity_ref
                        ,ln_entity_ref_id
                        );
      resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
      
      x_progress:= '30: xx_get_req_info_to_group: result = ACTIVITY_PERFORMED ' ||
                   'line_type is not found';
      IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
      END IF;
    RETURN;
   END IF;
   
   IF lc_attribute6 is null THEN
    --Assign this requisition line to a workflow attribute XX_REQ_LINE_ID
    --to pass it to XX_GROUP_REQ_LINES procedure's cursor so that this 
    --particular requisition will not be picked to group as DeliveryNumber(attribute6) is not present
      po_wf_util_pkg.SetItemAttrNumber(itemtype   => itemtype,
                                   itemkey    => itemkey,
                                   aname      => 'XX_REQ_LINE_ID',
                                       avalue     => ln_req_line_id);
      
      FND_MESSAGE.SET_NAME ('xxom','ODP_OM_POREQ_DELIVERYNUM_NOTFOUND');
      
      lc_error_msg  :=   FND_MESSAGE.GET;
      lc_entity_ref :=  'Requisition Line Id';
      ln_entity_ref_id  :=   ln_req_line_id;
      
      XX_LOG_EXCEPTION_PROC('ODP_OM_POREQ_DELIVERYNUM_NOTFOUND'
                        ,lc_error_msg
                        ,lc_entity_ref
                        ,ln_entity_ref_id
                        );
      resultout     :=  wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';
      x_progress    := '40: xx_get_req_info_to_group: result = ACTIVITY_PERFORMED ' ||
                           'delivery_number is not found';
      IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
      END IF;
     RETURN;
   END IF;
   
   --Assign ln_requisition_line_id to 0 as this requisition has all the information to group
 
   ln_req_line_id:=0;
   
   po_wf_util_pkg.SetItemAttrNumber(itemtype   => itemtype,
                                itemkey    => itemkey,
                                aname      => 'XX_REQ_LINE_ID',
                                    avalue     => ln_req_line_id);
   
   resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';

   x_progress:= '50: xx_get_req_info_to_group: result = ACTIVITY_PERFORMED';
   
   IF (g_po_wf_debug = 'Y') THEN
      po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
   END IF;
END IF;

END LOOP;
CLOSE lcu_req_lines;

IF lcu_req_lines_found ='N' THEN
   resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';

   x_progress:= '60: xx_get_req_info_to_group: result = ACTIVITY_PERFORMED';
   
   IF (g_po_wf_debug = 'Y') THEN
      po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
   END IF;        
END IF;

EXCEPTION 
 WHEN OTHERS THEN
 
 CLOSE lcu_req_lines; 
 wf_core.context('XX_WFL_CREATEPO_DOC_PKG ','xx_get_req_info_to_group',x_progress);
 RAISE;
END XX_GET_REQ_INFO_TO_GROUP;

 

/*************************************************************************************************
 *AUTHOR     : Sandeep Gorla                                     *
 *RICE ID    : E0216_Requisition-POProcess                           *
 *PROCEDURE  : XX_GROUP_REQ_LINES                                *
 *DESCRIPTION: This procedure is copied from standard package PO_AUTOCREATE_DOC.Group_req_lines  *
 *             to XX_GROUP_REQ_LINES to group the requisition lines based on the custom logic    *
 *             DropShip-->Group by LineType,DesktopAddress/Cost Center,Sales order       *
 *             BackToback-->Group by LineType,DeliveryNumber.                    *
 *                                               *
 *************************************************************************************************/  
 

PROCEDURE XX_GROUP_REQ_LINES (itemtype   IN   VARCHAR2,
                              itemkey    IN   VARCHAR2,
                              actid      IN   NUMBER,
                              funcmode   IN   VARCHAR2,
                              resultout  OUT NOCOPY  VARCHAR2 ) is


c1_group_id         number;
c1_req_header_id        number;
c1_req_line_id          number;
c1_suggested_buyer_id       number;
c1_source_doc_type_code     varchar2(25);
c1_source_doc_id        number;
c1_source_doc_line      number;
c1_suggested_vendor_id      number;
c1_suggested_vendor_site_id number;
c1_currency_code        varchar2(15);
c1_rate_type            varchar2(30);
c1_rate_date            date;
c1_rate             number;
c1_process_code         varchar2(30);
c1_rel_gen_method       varchar2(25);
c1_item_id          number;
c1_pcard_id         number;
c1_contract_id          number;
c1_deliver_to_location_code     hr_locations_all.location_code%type;
c1_dest_org_id                  number;                                           
c1_dest_type_code               po_requisition_lines.destination_type_code%TYPE;  
c1_cons_from_supp_flag          varchar2(1);                                     
c1_labor_req_line_id            number;   

c2_rowid            rowid;
c2_group_id         number;
c2_req_header_id        number;
c2_req_line_id          number;
c2_suggested_buyer_id       number;
c2_source_doc_type_code     varchar2(25);
c2_source_doc_id        number;
c2_source_doc_line      number;
c2_suggested_vendor_id      number;
c2_suggested_vendor_site_id number;
c2_currency_code        varchar2(15);
c2_rate_type            varchar2(30);
c2_rate_date            date;
c2_rate             number;
c2_process_code         varchar2(30);
c2_rel_gen_method       varchar2(25);
c2_item_id          number;
c2_pcard_id         number;
c2_contract_id          number;
c2_labor_req_line_id            number;   

l_enable_vmi_flag       po_asl_attributes.enable_vmi_flag%TYPE;               
l_last_billing_date     po_asl_attributes.last_billing_date%TYPE;             
l_cons_billing_cycle    po_asl_attributes.consigned_billing_cycle%TYPE;       

c2_dest_org_id              number;                                            
c2_dest_type_code           po_requisition_lines.destination_type_code%TYPE;   
c2_cons_from_supp_flag      varchar2(1);                                       
x_group_id          number;
x_first_time_for_this_comb  varchar2(5);
x_interface_header_id       number;
x_suggested_vendor_contact_id   number;
x_suggested_vendor_contact      varchar2(240);
c2_deliver_to_location_code     hr_locations_all.location_code%type;
x_prev_sug_vendor_contact_id    number;
x_carry_contact_to_po_flag      varchar2(10);

/*  x_grouping_allowed              varchar2(1); Bug 2974129 */
x_group_one_time_address        varchar2(1);

x_progress              varchar2(300);
x_valid             number;

c1_ga_flag                      varchar2(1);      
c2_ga_flag                      varchar2(1);      

--Bug 2745549
l_ref_ga_is_valid               varchar2(1) := 'N';

l_return_status             varchar2(1)    := NULL;
l_msg_count                 number         := NULL;
l_msg_data                  varchar2(2000) := NULL;

x_source_contact_id     NUMBER :=NULL; -- Bug 3586181
c2_found            VARCHAR2(1); -- Bug 3586181

---Defined variables as part of the extension E0216,OD CUSTOMIZATION,Sandeep Gorla

ln1_sales_order             Oe_Order_Headers_All.order_number%TYPE;
lc1_desktop_address         Po_Requisition_Lines_All.attribute6%TYPE;
lc1_delivery_number         Po_Requisition_Lines_All.attribute6%TYPE;
lc1_routing_number          Po_Requisition_Lines_All.attribute7%TYPE;
lc1_door                        Po_Requisition_Lines_All.attribute8%TYPE;
lc1_wave                        Po_Requisition_Lines_All.attribute9%TYPE;
lc1_line_type               Po_Requisition_Lines_All.attribute_category%TYPE;


ln2_sales_order             Oe_Order_Headers_All.order_number%TYPE;
lc2_desktop_address         Po_Requisition_Lines_All.attribute6%TYPE;
lc2_delivery_number         Po_Requisition_Lines_All.attribute6%TYPE;
lc2_routing_number          Po_Requisition_Lines_All.attribute7%TYPE;
lc2_door                        Po_Requisition_Lines_All.attribute8%TYPE;
lc2_wave                        Po_Requisition_Lines_All.attribute9%TYPE;
lc2_line_type               Po_Requisition_Lines_All.attribute_category%TYPE;

lc_so_type              VARCHAR2(50);
ln_requisition_line_id          Po_Requisition_Lines_All.requisition_line_id%TYPE;
lc_attribute_category           Po_Requisition_Lines_All.attribute_category%TYPE;
lc_attribute6                   Po_Requisition_Lines_All.attribute6%TYPE;
lc_attribute7                   Po_Requisition_Lines_All.attribute7%TYPE;
lc_attribute8                   Po_Requisition_Lines_All.attribute8%TYPE;
lc_attribute9                   Po_Requisition_Lines_All.attribute9%TYPE;  

--End of Defined variables as part of the extension Rice Id :E0216_Requisition-PoProcess,OD CUSTOMIZATION,Sandeep Gorla


/* Define the cursor which picks up records from the temp table.
 * We need the 'for update' since we are going to update the
 * process_code.
 */
/* Bug # 1721991.
   The 'for update' clause was added to update the row which was processed
   in the Cursor c2 but this led to another problem in Oracle 8.1.6.3 or above
   where you can't have a commit inside a 'for update' Cursor loop.
   This let to the Runtime Error 'fetch out of sequence'
   The commit was actually issued in the procedure insert_into_header_interface.
   To solve this we removed the for update in the cursor and instead used rowid
   to update the row processed by the Cursor.
*/
-- <SERVICES FPJ>
-- Added labor_req_line_id to the select statement
cursor c1  is               /* x_group_id is a parameter */
  select prlt.group_id,
         prlt.requisition_header_id,
         prlt.requisition_line_id,
     prlt.suggested_buyer_id,
         prlt.source_doc_type_code,
     prlt.source_doc_id,
     prlt.source_doc_line,
     prlt.suggested_vendor_id,
         prlt.suggested_vendor_site_id,
     prlt.currency_code,
         prlt.rate_type,
     prlt.rate_date,
     prlt.rate,
     prlt.process_code,
     prlt.release_generation_method,
     prlt.item_id,
     prlt.pcard_id,
         prlt.contract_id,
         hrl.location_code,
         prl.destination_organization_id,
         prl.destination_type_code,
         prl.labor_req_line_id
    from po_wf_candidate_req_lines_temp prlt,
         po_requisition_lines prl,
         hr_locations_all hrl
   where prlt.process_code = 'PENDING'
     and prlt.group_id     = x_group_id
     and prlt.requisition_line_id = prl.requisition_line_id
     and prl.requisition_line_id <> ln_requisition_line_id 
     --<Comments>,Sandeep Gorla,Rice ID:E0216_Requisition-PoProcess,30-MAY-07
     --added above condition to restrict requisitions which do not have enough data to group
     --<Comments>
     and prl.deliver_to_location_id = hrl.location_id(+)    -- bug 2709046
     and nvl(prl.reqs_in_pool_flag,'Y') = 'Y';  -- bug 2347636

-- <SERVICES FPJ>
-- Added labor_req_line_id to the select statement
cursor c2  is               /* x_group_id is a parameter */
  select prlt.rowid,   -- Bug# 1721991 , Added rowid to update row processed
         prlt.group_id,
         prlt.requisition_header_id,
         prlt.requisition_line_id,
     prlt.suggested_buyer_id,
         prlt.source_doc_type_code,
     prlt.source_doc_id,
     prlt.source_doc_line,
     prlt.suggested_vendor_id,
         prlt.suggested_vendor_site_id,
     prlt.currency_code,
         prlt.rate_type,
     prlt.rate_date,
     prlt.rate,
     prlt.process_code,
     prlt.release_generation_method,
     prlt.item_id,
     prlt.pcard_id,
         prlt.contract_id,
     prl.suggested_vendor_contact,
     prl.vendor_contact_id,
         hrl.location_code,
         prl.destination_organization_id,
         prl.destination_type_code,
         prl.labor_req_line_id
    from po_wf_candidate_req_lines_temp prlt,
     po_requisition_lines prl,
         hr_locations_all hrl
   where prlt.process_code = 'PENDING'
     and prlt.group_id     = x_group_id
     and prlt.requisition_line_id = prl.requisition_line_id
     and prl.requisition_line_id <> ln_requisition_line_id  
     --<Comments>,Sandeep Gorla,Rice ID:E0216_Requisition-PoProcess,
     --added above condition to restrict requisitions which do not have enough data to group
     --<Comments>                          
     and prl.deliver_to_location_id = hrl.location_id(+)  -- bug 2709046
     and nvl(prl.reqs_in_pool_flag,'Y') = 'Y';   -- bug 2347636
     --Bug# 1721991, for update;
begin

   /* Get the group_id since we only want to process lines belonging
    * to the same group. We need to get the group_id before opening
    * the cursor since it is a parameter to the cursor.
    */

   x_group_id := po_wf_util_pkg.GetItemAttrNumber (itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'GROUP_ID');

 /* Bug 2974129. This Grouping allowed flag should not decide the #of documents
    Instead this should be applied to group the lines.

   x_grouping_allowed := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'GROUPING_ALLOWED_FLAG');   */

   x_group_one_time_address := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                              itemkey  => itemkey,
                                              aname    => 'GROUP_ONE_ADDR_LINE_FLAG');
 --<Comments> Sandeep Gorla,Rice Id :E0216_Requisition-PoProcess,30-MAY-07
   lc_so_type     := po_wf_util_pkg.GetItemAttrText(itemtype     =>itemtype,
                                itemkey      =>itemkey,
                                aname        =>'XX_ORDER_TYPE');    
   
   ln_requisition_line_id  := po_wf_util_pkg.GetItemAttrText(itemtype     =>itemtype,
                                         itemkey      =>itemkey,
                                         aname        =>'XX_REQ_LINE_ID');    
 --End of Code added Sandeep Gorla,Rice Id:E0216_Requisition-PoProcess,30-MAY-07                           

/*   if x_grouping_allowed is NULL then

     x_grouping_allowed := 'Y';

   end if; Bug 2974129 */

   if x_group_one_time_address is NULL then

     x_group_one_time_address := 'Y';

   end if;

   /* Open the cursor with that group_id */
   open c1;     /* Based on x_group_id */

   loop
      fetch c1 into c1_group_id,
            c1_req_header_id,
                c1_req_line_id,
                c1_suggested_buyer_id,
                c1_source_doc_type_code,
                c1_source_doc_id,
                c1_source_doc_line,
                c1_suggested_vendor_id,
                c1_suggested_vendor_site_id,
                c1_currency_code,
                c1_rate_type,
                c1_rate_date,
                c1_rate,
                c1_process_code,
                c1_rel_gen_method,
                c1_item_id,
            c1_pcard_id,
                    c1_contract_id,
                    c1_deliver_to_location_code,
                    c1_dest_org_id,
                    c1_dest_type_code,
                    c1_labor_req_line_id;
        exit when c1%NOTFOUND;

     /* FPI GA start */
        if (c1_source_doc_id is not null) then
            select global_agreement_flag
            into c1_ga_flag
            from po_headers_all
            where po_header_id = c1_source_doc_id;
        end if;

     /* FPI GA End */

     /* Consigned FPI start */
        PO_THIRD_PARTY_STOCK_GRP.Get_Asl_Attributes
       ( p_api_version                  => 1.0
       , p_init_msg_list                => NULL
       , x_return_status                => l_return_status
       , x_msg_count                    => l_msg_count
       , x_msg_data                     => l_msg_data
       , p_inventory_item_id            => c1_item_id
       , p_vendor_id                    => c1_suggested_vendor_id
       , p_vendor_site_id               => c1_suggested_vendor_site_id
       , p_using_organization_id        => c1_dest_org_id
       , x_consigned_from_supplier_flag => c1_cons_from_supp_flag
       , x_enable_vmi_flag              => l_enable_vmi_flag
       , x_last_billing_date            => l_last_billing_date
       , x_consigned_billing_cycle      => l_cons_billing_cycle
      );

       if c1_cons_from_supp_flag = 'Y' and
          nvl(c1_dest_type_code,'INVENTORY') <> 'EXPENSE' then
           c1_source_doc_id := null;
           c1_contract_id   := NULL;     -- <GC FPJ>
       else
          c1_cons_from_supp_flag := 'N';
       end if;

     /* Consigned FPI end */

     --<Bug 2745549 mbhargav START>
     --Null out GA information if GA is not valid
     if c1_source_doc_id is not null then

         is_ga_still_valid(c1_source_doc_id, l_ref_ga_is_valid);

         if l_ref_ga_is_valid = 'N' then
             c1_source_doc_id := null;
         end if;
     end if;
     --<Bug 2745549 mbhargav END>


     /* Supplier PCard FPH. Check whether c1_pcard_id is valid. The function
      * will return pcard_id if valid else will have value null if not.
     */

     If (c1_pcard_id is not null) then
        c1_pcard_id := po_pcard_pkg.get_valid_pcard_id(c1_pcard_id,c1_suggested_vendor_id,c1_suggested_vendor_site_id);
     end if;
      /* Supplier PCard FPH */
      x_first_time_for_this_comb := 'TRUE';
      x_suggested_vendor_contact_id := NULL;
      x_carry_contact_to_po_flag := 'TRUE';
      x_prev_sug_vendor_contact_id := NULL;
      c2_found :='Y';

---<Comments> Start of code added  by Sandeep Gorla,RiceID:E0216_Requisition-PoProcess,30-May-07
---For Dropship ,Get the required info(context,desktop address/cost center) for grouping
IF lc_so_type ='DROPSHIP' THEN
      BEGIN
     SELECT  OEH.order_number
        ,PRL.attribute_category
        ,PRL.attribute6
        ,PRL.attribute7
     INTO    ln1_sales_order
        ,lc1_line_type
        ,lc1_desktop_address
        ,lc1_routing_number
     FROM    oe_drop_ship_sources ODSS
        ,oe_order_headers_all OEH
        ,oe_order_lines_all OEL
        ,po_requisition_lines_all PRL
     WHERE   ODSS.header_id=OEH.header_id
     AND     ODSS.line_id=OEL.line_id
     AND     ODSS.requisition_header_id=c1_req_header_id
     AND     ODSS.requisition_line_id=c1_req_line_id
     AND     PRL.requisition_line_id=ODSS.requisition_line_id; 
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           ln1_sales_order  := null;
           lc1_line_type        := null;
           lc1_desktop_address  := null;
           lc1_routing_number   := null;
      WHEN OTHERS THEN
           ln1_sales_order  := null;
       lc1_line_type        := null;
       lc1_desktop_address  := null;
           lc1_routing_number   := null;
      END;
--For BacktoBack,Get the required info(context,delivery_number) for grouping

ELSIF lc_so_type ='BACKTOBACK' THEN
      BEGIN
     SELECT OEH.order_number
           ,PRL.attribute_category
           ,PRL.attribute6
           ,PRL.attribute7
           ,PRL.attribute8
           ,PRL.attribute9
     INTO   ln1_sales_order
           ,lc1_line_type
           ,lc1_delivery_number
           ,lc1_routing_number
           ,lc1_door
           ,lc1_wave
     FROM   mtl_reservations MR
           ,mtl_supply MS
           ,oe_order_lines_all OEL
           ,oe_order_headers_all OEH
           ,po_requisition_lines_all PRL
     WHERE  MR.demand_source_type_id = 2
     AND    MR.demand_source_line_id = OEL.line_id
     AND    OEH.header_id=OEL.header_id
     AND    MR.supply_source_type_id =17
     AND    MR.supply_source_line_id = MS.supply_source_id
     AND    MS.req_header_id = c1_req_header_id
     AND    MS.req_line_id =c1_req_line_id
     AND    MS.req_line_id=PRL.requisition_line_id;
      EXCEPTION 
      WHEN NO_DATA_FOUND THEN
           ln1_sales_order     := null;
           lc1_line_type       := null;
           lc1_delivery_number := null;
           lc1_routing_number  := null;
           lc1_door            := null;
           lc1_wave            := null;
      WHEN OTHERS THEN
           ln1_sales_order     := null;
       lc1_line_type       := null;
       lc1_delivery_number := null;
       lc1_routing_number  := null;
       lc1_door            := null;
           lc1_wave            := null;
      END;
END IF;
---<Comments> End of code added  by Sandeep Gorla,RiceID:E0216_Requisition-PoProcess,30-May-07


      OPEN C2;

      LOOP
         fetch c2 into  c2_rowid,  -- Bug# 1721991, Added rowid
                        c2_group_id,
            c2_req_header_id,
                c2_req_line_id,
                    c2_suggested_buyer_id,
                    c2_source_doc_type_code,
                    c2_source_doc_id,
            c2_source_doc_line,
                    c2_suggested_vendor_id,
                    c2_suggested_vendor_site_id,
                    c2_currency_code,
                    c2_rate_type,
                    c2_rate_date,
                    c2_rate,
                    c2_process_code,
                    c2_rel_gen_method,
                    c2_item_id,
                c2_pcard_id,
                        c2_contract_id,
            x_suggested_vendor_contact,
            x_suggested_vendor_contact_id,
                        c2_deliver_to_location_code,
                        c2_dest_org_id,
                        c2_dest_type_code,
                        c2_labor_req_line_id;

       if (c2%rowcount)= 0 then  -- Bug 3586181
                c2_found:='N';
           end if;
          exit when c2%NOTFOUND;

      /* FPI GA start */
        if (c2_source_doc_id is not null) then
            select global_agreement_flag
            into c2_ga_flag
            from po_headers_all
            where po_header_id = c2_source_doc_id;
        end if;

     /* FPI GA End */
     /* Consigned FPI start */
        PO_THIRD_PARTY_STOCK_GRP.Get_Asl_Attributes
       ( p_api_version                  => 1.0
       , p_init_msg_list                => NULL
       , x_return_status                => l_return_status
       , x_msg_count                    => l_msg_count
       , x_msg_data                     => l_msg_data
       , p_inventory_item_id            => c2_item_id
       , p_vendor_id                    => c2_suggested_vendor_id
       , p_vendor_site_id               => c2_suggested_vendor_site_id
       , p_using_organization_id        => c2_dest_org_id
       , x_consigned_from_supplier_flag => c2_cons_from_supp_flag
       , x_enable_vmi_flag              => l_enable_vmi_flag
       , x_last_billing_date            => l_last_billing_date
       , x_consigned_billing_cycle      => l_cons_billing_cycle
      );

       if c2_cons_from_supp_flag = 'Y' and
          nvl(c2_dest_type_code,'INVENTORY') <> 'EXPENSE' then
           c2_source_doc_id := null;
           c2_contract_id := NULL;        -- <GC FPJ>
       else
           c2_cons_from_supp_flag := 'N';
       end if;

     /* Consigned FPI end */

     --<Bug 2745549 mbhargav START>
     --Null out GA information if GA is not valid
     if c2_source_doc_id is not null then

         is_ga_still_valid(c2_source_doc_id, l_ref_ga_is_valid);

         if l_ref_ga_is_valid = 'N' then
             c2_source_doc_id := null;
         end if;
     end if;
     --<Bug 2745549 mbhargav END>

     /* Supplier PCard FPH. Check whether c2_pcard_id is valid. The function
      * will return pcard_id if valid else will have value null if not.
     */
    If (c2_pcard_id is not null) then
        c2_pcard_id := po_pcard_pkg.get_valid_pcard_id(c2_pcard_id,c2_suggested_vendor_id,c2_suggested_vendor_site_id);
    end if;
        /* Supplier PCard FPH */
      /* Associate similiar lines with the same header. This is the core
           * grouping logic.
           */

      x_progress := '10: xx_group_req_lines : c1_req_line_id = '
                || to_char(c1_req_line_id) || '   c2_req_line_id = '
                || to_char(c2_req_line_id);

      if (x_suggested_vendor_contact_id is null) then
        x_suggested_vendor_contact_id := get_contact_id(x_suggested_vendor_contact, c2_suggested_vendor_site_id);
      end if;

          IF (g_po_wf_debug = 'Y') THEN
             po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;

   /* Bug 1362315
   When you initiate the create doc workflow from requisition import
   for a batch of 5000 requisitions or more, the process
   failed to create the po for one or two requisitions bcos
   we were not truncating the sysdate before a comparison in the following
   if logic and thereby not creating records in the po_headers_interface
   table for the autocreate logic to process the req to a PO.
   */
--<Comments> added by Sandeep Gorla,RiceID:E0216_Requisition-POProcess,30-May-07
---For Dropship ,Get the required info(context,desktop address/cost center) for grouping
IF lc_so_type ='DROPSHIP' THEN
      BEGIN
     SELECT OEH.order_number
           ,PRL.attribute_category
           ,PRL.attribute6
           ,PRL.attribute7
     INTO   ln2_sales_order
           ,lc2_line_type
           ,lc2_desktop_address
           ,lc2_routing_number
         FROM   oe_drop_ship_sources ODSS
               ,oe_order_headers_all OEH
               ,oe_order_lines_all OEL
               ,po_requisition_lines_all PRL
         WHERE  ODSS.header_id=OEH.header_id
         AND    ODSS.line_id=OEL.line_id
         AND    ODSS.requisition_header_id=c2_req_header_id
         AND    ODSS.requisition_line_id=c2_req_line_id
         AND    PRL.requisition_line_id=ODSS.requisition_line_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           ln2_sales_order  := null;
           lc2_line_type        := null;
           lc2_desktop_address  := null;
           lc2_routing_number   := null;
      WHEN OTHERS THEN
           ln2_sales_order  := null;
           lc2_line_type        := null;
           lc2_desktop_address  := null;
           lc2_routing_number   := null;
      END;
      
--For BackToBack,Get the required info(context,delivery Number) for grouping         
ELSIF lc_so_type ='BACKTOBACK' THEN
      BEGIN
         SELECT OEH.order_number
               ,PRL.attribute_category
               ,PRL.attribute6
               ,PRL.attribute7
               ,PRL.attribute8
               ,PRL.attribute9
         INTO   ln2_sales_order
               ,lc2_line_type
               ,lc2_delivery_number
               ,lc2_routing_number
               ,lc2_door
               ,lc2_wave
         FROM   mtl_reservations MR
               ,mtl_supply MS
               ,oe_order_lines_all OEL
               ,oe_order_headers_all OEH
               ,po_requisition_lines_all PRL
         WHERE  MR.demand_source_type_id = 2
         AND    MR.demand_source_line_id = OEL.line_id
         AND    OEH.header_id=OEL.header_id
         AND    MR.supply_source_type_id =17
         AND    MR.supply_source_line_id = MS.supply_source_id
         AND    MS.req_header_id = c2_req_header_id
         AND    MS.req_line_id =c2_req_line_id
         AND    MS.req_line_id=PRL.requisition_line_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           ln2_sales_order  := null;
           lc2_line_type    := null;
           lc2_delivery_number  := null;
           lc2_routing_number   := null;
           lc2_door         := null;
           lc2_wave         := null;
      WHEN OTHERS THEN
       ln2_sales_order  := null;
       lc2_line_type    := null;
       lc2_delivery_number  := null;
       lc2_routing_number   := null;
       lc2_door         := null;
           lc2_wave         := null;
      END;     
END IF;
---<Comments> End of Code added by Sandeep Gorla,RiceID:E0216_Requisition-POProcess,30-MAY-07
          /* Add one time location grouping logic */

    if (c1_req_line_id = c2_req_line_id) /* Always insert if c1 and c2 is the same line */
           OR
           ( /* (x_grouping_allowed = 'Y') AND Bug 2974129 */
           (x_group_one_time_address = 'Y' OR
           (x_group_one_time_address = 'N' AND
            c1_deliver_to_location_code <> fnd_profile.value('POR_ONE_TIME_LOCATION') AND
            c2_deliver_to_location_code <> fnd_profile.value('POR_ONE_TIME_LOCATION'))) AND
            (c1_suggested_buyer_id    = c2_suggested_buyer_id)      AND
        (c1_suggested_vendor_id       = c2_suggested_vendor_id)     AND
        (c1_suggested_vendor_site_id = c2_suggested_vendor_site_id) AND
        (nvl(c1_source_doc_type_code ,'QUOTATION')=nvl(c2_source_doc_type_code,'QUOTATION')) AND  
            (nvl(c1_ga_flag,'N')         = nvl(c2_ga_flag,'N'))         AND      -- FPI GA
            (nvl(c1_contract_id,-1)  = nvl(c2_contract_id,-1))  AND
            (nvl(c1_currency_code,'ok')  = nvl(c2_currency_code, 'ok')) AND
        (nvl(c1_rate_type, 'ok')     = nvl(c2_rate_type, 'ok')) AND
             --<Comments>code added Sandeep Gorla to add extra groping logic,RiceId:E0216_Requisition-PoProcess,30-MAY-07
            (lc_so_type='DROPSHIP' AND (nvl(lc1_desktop_address,-1)=nvl(lc2_desktop_address,-1)) AND (ln1_sales_order=ln2_sales_order) AND (lc1_line_type=lc2_line_type))
            OR 
            (lc_so_type='BACKTOBACK' AND (lc1_delivery_number=lc2_delivery_number) AND (lc1_line_type=lc2_line_type))
            AND
             --<Comments>End of code added by Sandeep Gorla to add extra grouping logic,RiceId:E0216_Requisition-PoProcess,30-MAY-07
            ((c1_rate is NULL AND c2_rate is NULL)     --<Bug 3343855>
            OR
        (nvl(c1_rate_date, trunc(sysdate))  = nvl(c2_rate_date, trunc(sysdate))))    AND
        (nvl(c1_rate,-1)          = nvl(c2_rate, -1))        AND
        (nvl(c1_pcard_id,-1)      = nvl(c2_pcard_id,-1))     AND
        ((nvl(c1_source_doc_id,-1)    = nvl(c2_source_doc_id,-1))
        OR
            (nvl(c1_source_doc_type_code ,'QUOTATION')   = 'QUOTATION')
            OR
            ((nvl(c1_source_doc_type_code,'QUOTATION') = 'BLANKET') AND (nvl(c1_ga_flag,'N') = 'Y'))) -- FPI GA   AND
            )
            -- <SERVICES FPJ START>
            OR
            (nvl(c1_req_line_id, -1) = nvl(c2_labor_req_line_id, -1))
            OR
            (nvl(c1_labor_req_line_id, -1) = nvl(c2_req_line_id, -1))
            -- <SERVICES FPJ END>
            THEN

          x_progress := '20: xx_group_req_lines: c1 and c2 match ';
          IF (g_po_wf_debug = 'Y') THEN
          po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;


         /* Update the process code of the current line in the temp table so
          * it doesn't get picked up again by the cursor for processing.
          */

         update po_wf_candidate_req_lines_temp
         set process_code = 'PROCESSED'
             where rowid=c2_rowid;
         -- Bug# 1721991, where current of c2;

         x_progress:= '30:xx_group_req_lines: Updated process_code ';
         IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
         END IF;
              
             --<Comments> Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07
             IF lc_so_type='DROPSHIP' THEN
                lc_attribute_category := lc2_line_type;
                lc_attribute6         := lc2_desktop_address;
                lc_attribute7         := lc2_routing_number;
                lc_attribute8         := null;
                lc_attribute9         := null;
             ElSIF lc_so_type ='BACKTOBACK' THEN
                lc_attribute_category := lc2_line_type;
                lc_attribute6         := lc2_delivery_number;
                lc_attribute7         := lc2_routing_number;
                lc_attribute8         := lc2_door;
                lc_attribute9         := lc2_wave;
                
             END IF;
             --<Comments> End of code by Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07
          
        
         if (x_first_time_for_this_comb  = 'TRUE') then
         
         ---<Comments> Start of code by Sandeep Gorla,RiceId:E0216_Requisition-POProcess,30-MAY-07
       
                  if(XX_WFL_CREATEPO_DOC_PKG.XX_INSERT_HEADERS_INTERFACE
                     (itemtype,
                      itemkey,
                      c2_group_id,
                      c2_suggested_vendor_id,
                      c2_suggested_vendor_site_id,
                      c2_suggested_buyer_id,
                      c2_source_doc_type_code,
                      c2_source_doc_id,
                      c2_currency_code,
                      c2_rate_type,
                      c2_rate_date,
                      c2_rate,
                      c2_pcard_id,
                      lc_attribute_category,   --added by Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07
                      lc_attribute6,           --added by Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07
                      lc_attribute7,           --added by Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07
                      lc_attribute8,           --added by Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07 
                      lc_attribute9,           --added by Sandeep Gorla,RiceId:E0216_Requisition-PoProcess,30-MAY-07
                      x_interface_header_id) = FALSE) then
                  exit; --bug 3401653: po creation failed, skip out of inner loop
                end if;
              
                  
                --<Comments> End of code by Sandeep Gorla,RiceId:E0216_Requisition-POProcess,30-MAY-07



            po_autocreate_doc.insert_into_lines_interface (itemtype,
                                itemkey,
                                x_interface_header_id,
                                c2_req_line_id,
                                c2_source_doc_line,
                                c2_source_doc_type_code,
                                                            c2_contract_id,
                                                            c2_source_doc_id,         -- GA FPI
                                                            c2_cons_from_supp_flag);  -- Consigned FPI

        /* Bug  3586181 When the document is Contract or Global Aggrement
                               get the vendor contact from them*/

                Begin
                 if ((NVL(c1_source_doc_type_code,'BLANKET')='CONTRACT') ) then

             select vendor_contact_id
             into   x_source_contact_id
             from   po_headers_all
             where  po_header_id=c2_contract_id;

                 elsif (NVL(c2_ga_flag,'N')='Y') then -- For Global Aggrement.

              select vendor_contact_id
              into   x_source_contact_id
              from   po_headers_all           -- To take care of GAs in Diff Operating unit
              where  po_header_id=c2_source_doc_id;
                 else
              x_source_contact_id := null;
         end if;
        Exception
              when no_data_found then x_source_contact_id := NULL;
            end;

            /* End  3586181*/

            x_progress := '40: xx_group_req_lines: inserted header'||
                  ' and line for req line = ' || to_char(c2_req_line_id);
        IF (g_po_wf_debug = 'Y') THEN
        po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
        END IF;
/* bug 2656323
   Added code to update vendor_contact_id when  po_headers is inserted for first time. */
         if (x_carry_contact_to_po_flag = 'TRUE' and
                  valid_contact(c2_suggested_vendor_site_id, x_suggested_vendor_contact_id)) then
         begin
                        update po_headers_interface
                    set vendor_contact_id = x_suggested_vendor_contact_id
                where interface_header_id = x_interface_header_id;
             exception
                 when others then
                IF (g_po_wf_debug = 'Y') THEN
                           po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
                    END IF;
             end;
         end if;



            x_first_time_for_this_comb := 'FALSE';
        --bug#3586181
        if (x_suggested_vendor_contact_id is not NULL) then
            x_prev_sug_vendor_contact_id := x_suggested_vendor_contact_id;
        end if;
        --bug#3586181


         else  /*  ie. x_first_time_for_this_comb  = FALSE */

                /* The line we are checking now can put put onto the same header
             * as a previous one, so only insert a new line into the
                 * po_lines_interface table.
             */

                po_autocreate_doc.insert_into_lines_interface (itemtype,
                                itemkey,
                                x_interface_header_id,
                                c2_req_line_id,
                                c2_source_doc_line,
                                c2_source_doc_type_code,
                                                            c2_contract_id,
                                                            c2_source_doc_id,          -- GA FPI
                                                            c2_cons_from_supp_flag);   -- Consigned FPI

             x_progress := '50: xx_group_req_lines: inserted just line for '||
                     'req line = ' || to_char(c2_req_line_id);
         IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
         END IF;

        --bug#3586181
         if (x_carry_contact_to_po_flag = 'TRUE')  then -- SS
             if ( x_suggested_vendor_contact_id is not null and x_prev_sug_vendor_contact_id is not null) and
                (x_suggested_vendor_contact_id <> x_prev_sug_vendor_contact_id) then -- SS
                    x_carry_contact_to_po_flag := 'FALSE';
             end if;
         end if;
        --bug#3586181

         end if;

          end if;
        --bug#3586181
        if(x_suggested_vendor_contact_id is not null)then
          x_prev_sug_vendor_contact_id := x_suggested_vendor_contact_id;
        end if;
        --bug#3586181


      end loop;
/* Commented this code as we are updating vendor_contact_id when header is inserted first time.
      if (x_carry_contact_to_po_flag = 'TRUE' and
          valid_contact(c2_suggested_vendor_site_id, x_suggested_vendor_contact_id)) then
            begin
                    x_progress := '55: group_req_lines: updating header with vendor contact :'||x_interface_header_id;
                    update po_headers_interface
                    set vendor_contact_id = x_suggested_vendor_contact_id
                    where interface_header_id = x_interface_header_id;
            exception
                    when others then
                    IF (g_po_wf_debug = 'Y') THEN
                       po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
                    END IF;
        end;
      end if;
*/
      close c2;



 /* Bug 3586181 Update the contact id if the either Contract or GA has
                got a valid contact */
       if (c2_found='Y') then
       Begin

         if ( x_source_contact_id is not null) then
          update po_headers_interface
              set    vendor_contact_id = x_source_contact_id
              where  interface_header_id = x_interface_header_id;

         elsif (x_carry_contact_to_po_flag = 'FALSE') then -- Implies contacts in Req lines are different
              update po_headers_interface
              set    vendor_contact_id = NULL
              where  interface_header_id = x_interface_header_id;
         elsif (x_carry_contact_to_po_flag = 'TRUE') and (x_prev_sug_vendor_contact_id is not null) then
              update po_headers_interface
          set    vendor_contact_id = x_prev_sug_vendor_contact_id
              where  interface_header_id = x_interface_header_id;

          end if;
        end;
      end if;
 /* End 3586181 */



   end loop;

   close c1;

   /* Calling process should do the commit, so comment out here.
    * COMMIT;
    */

  resultout := wf_engine.eng_completed || ':' ||  'ACTIVITY_PERFORMED';

  x_progress := '60: xx_group_req_lines: result = ACTIVITY_PERFORMED ';
  IF (g_po_wf_debug = 'Y') THEN
     po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
  END IF;

exception
  when others then
    close c1;
    close c2;
    wf_core.context('XX_WFL_CREATEPO_DOC_PKG ','xx_group_req_lines',x_progress);
    raise;
end xx_group_req_lines;
--End of Procedure added by Sandeep Gorla



 
/************************************************************************************************
 *AUTHOR     : Sandeep Gorla                                                                    *
 *PROCEDURE  : INSERT_INTO_HEADERS_INTERFACE (Copied this procedure form PO_AUTOCREATE_DOC pack.*
 *DESCRIPTION: Inserts a row into the po_headers_interface                                      *
 *         returns false if creating PO header fails, and true otherwise.                   *
 *         Added 3 additional parameters x_attribute_category,x_attribute6,x_attribute7     *
 *         to insert into PO_HEADERS_INTERFACE so that the same can be inserted into        *
 *         PO_HEADERS_ALL table as per the Extension requirement.                           * 
 ************************************************************************************************/
 

FUNCTION  XX_INSERT_HEADERS_INTERFACE (itemtype          IN  VARCHAR2,
                     itemkey             IN  VARCHAR2,
                     x_group_id          IN  NUMBER,
                     x_suggested_vendor_id       IN  NUMBER,
                     x_suggested_vendor_site_id  IN  NUMBER,
                     x_suggested_buyer_id        IN  NUMBER,
                     x_source_doc_type_code      IN  VARCHAR2,
                     x_source_doc_id         IN  NUMBER,
                     x_currency_code         IN  VARCHAR2,
                     x_rate_type             IN  VARCHAR2,
                     x_rate_date             IN  DATE,
                     x_rate              IN  NUMBER,
                     x_pcard_id          IN  NUMBER,
                                         x_attribute_category        IN  VARCHAR2, --added by Sandeep Gorla
                                         x_attribute6                IN  VARCHAR2, --added by Sandeep Gorla
                                         x_attribute7                IN  VARCHAR2, --added by Sandeep Gorla
                                         x_attribute8                IN  VARCHAR2, --added by Sandeep Gorla
                                         x_attribute9                IN  VARCHAR2, --added by Sandeep Gorla
                     x_interface_header_id   IN OUT NOCOPY  NUMBER)
RETURN boolean is  


x_batch_id          number;
x_creation_date         date    := sysdate;
x_last_update_date      date    := sysdate;
x_created_by            number;
x_last_updated_by       number;
x_org_id            number;
x_doc_type_to_create        varchar2(25);
x_release_date          date;
x_document_num          varchar2(25);
x_release_num           number;
x_release_num1          number;
x_currency_code_doc     varchar2(15);
x_found             varchar2(30);

x_no_releases           number;
x_ga_flag                       varchar2(1);   -- FPI GA
x_progress              varchar2(300);

x_grouping_allowed              varchar2(1); /* Bug 2974129 */
x_group_code                    po_headers_interface.group_code%TYPE; /* Bug 2974129 */
l_purchasing_org_id             po_headers_all.org_id%TYPE;  --<Shared Proc FPJ>

--begin bug 3401653
l_source_doc_currency_code      po_headers_all.currency_code%TYPE := NULL;
l_pou_currency_code      po_headers_all.currency_code%TYPE;
l_rou_currency_code      po_headers_all.currency_code%TYPE;
l_pou_sob_id             gl_sets_of_books.set_of_books_id%TYPE;
l_pou_default_rate_type  po_headers_all.rate_type%TYPE;
l_interface_rate         po_headers_all.rate%TYPE := NULL;
l_interface_rate_type    po_headers_all.rate_type%TYPE := NULL;
l_interface_rate_date    po_headers_all.rate_date%TYPE := NULL;
l_display_rate           po_headers_all.rate%TYPE := NULL;
--end bug 3401653

begin

   /* Set the org context. Backend create_po process assumes it is in
    * an org.
    */

    x_org_id := po_wf_util_pkg.GetItemAttrNumber
                    (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ORG_ID');

    --<Shared Proc FPJ START>

    x_progress := '10:insert_into_headers_interface:' ||
          'just before set_purchasing_org_id';

    set_purchasing_org_id(itemtype,
            itemkey,
            x_org_id,
            x_suggested_vendor_site_id);

    l_purchasing_org_id := po_wf_util_pkg.GetItemAttrNumber
                                        (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PURCHASING_ORG_ID');

    x_progress:= '20: insert_into_headers_interface: org_id = ' ||
        to_char(x_org_id) || ' purchasing_org_id = ' ||
        to_char(l_purchasing_org_id);

    --<Shared Proc FPJ END>


  /* Bug 2974129.
     This attribute should decide the grouping logic in Auto Create. If this is set Y,
     then the 'DEFAULT' will be populated as grope code else 'REQUISITION' will be
     populated as group code */

    x_grouping_allowed := PO_WF_UTIL_PKG.GetItemAttrText (itemtype => itemtype,
                                                          itemkey  => itemkey,
                                                          aname    => 'GROUPING_ALLOWED_FLAG');

   if x_grouping_allowed = 'N' then
          x_group_code := 'REQUISITION';
   else
          x_group_code := 'DEFAULT';
   end if;


    fnd_client_info.set_org_context(to_char(x_org_id));

   /* Get user values */

   x_created_by       := to_number(FND_PROFILE.VALUE('user_id'));
   x_last_updated_by  := to_number(FND_PROFILE.VALUE('user_id'));


   /* Get the interface_header_id from the sequence */

   select po_headers_interface_s.nextval
     into x_interface_header_id
     from sys.dual;

   /* Set the batch id which can be the same as
    * the interface_header_id since we create only one
    * po at a time from workflow
    */

   x_batch_id := x_interface_header_id;

   /* If the source doc is a blanket then we are going to create a blanket release.
    * If the source doc is a quotation then we are going to create a standard po.
    */

  /* FPI GA - If ga flag is Y then we create a standard PO */

  -- Bug 2695074 getting the ga flag from the db as the attribute does not have any value
  -- in this process

   if x_source_doc_id is not null then
     select global_agreement_flag, currency_code
     into x_ga_flag, l_source_doc_currency_code
     from po_headers_all
     where po_header_id = x_source_doc_id;
   end if;

   /* Bug 2735730.
    * If x_source_doc_id is null, then it would be only in the case
    * when the supplier is set up as a consigned enabled and the
    * destination type is INVENTORY for the requisition. In this case,
    * we should still create a Standard PO. Hence x_doc_type_to_create
    * should be STANDARD in this case.
   */
   if (x_source_doc_id is null) then
    x_doc_type_to_create := 'STANDARD';
   else
       if (x_source_doc_type_code = 'BLANKET')
            and nvl(x_ga_flag,'N') = 'N' then  -- FPI GA
          x_doc_type_to_create    := 'RELEASE';
       else
          x_doc_type_to_create    := 'STANDARD';
       end if;
   end if;


   if (x_doc_type_to_create = 'STANDARD') then

     /* Whether automatic numbering is on our not, we are going to use
      * the automatic number from the unique identifier table. This is
      * as per req import. If however we have an  po num (eg. emergency po)
      * passed into the workflow then we need to use that.
      *
      * The autocreate backend will take whatever doc num we give it and
      * will try and create that. If we weren't to pass in a doc num and
      * automatic numbering was on, it would get the next number.
      *
      * If we are not using automatic numbering but we get the po num
      * from the unique identifier table then we could get a number that
      * has been used (entered manually by the user). We need to make sure
      * that the doc number is unique here since the backend expects that
      * when using manual numbering.
      */

     x_document_num := po_wf_util_pkg.GetItemAttrText
                    (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PO_NUM_TO_CREATE');

     if (x_document_num is NULL) then

        x_progress := '30: insert_into_headers_interface: Just about to get doc' ||
               'num from po_unique_identifier_control';

    IF (g_po_wf_debug = 'Y') THEN
    po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
    END IF;

/*
   Bug# 1869409
   Created a function get_document_num  to get the next doucument
   Number from the PO_UNIQUE_IDENTIFIER_CONTROL table. This was
   done as the Commit after the UPDATE of the PO_UNIQUE_IDENTIFIER_CONTROL
   table was also affecting the Workflow transactions.
   The function get_document_num is an autonomous transaction.
*/
        --<Shared Proc FPJ>
        --Get document num in purchasing org
        x_document_num := get_document_num(l_purchasing_org_id);

        x_progress := '40: insert_into_headers_interface: Got doc' ||
               'num from po_unique_identifier_control';
    IF (g_po_wf_debug = 'Y') THEN
    po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
    END IF;

     end if;

     /* Check to make sure the doc num is not a duplicate */

     begin
        --<Shared Proc FPJ>
        --Modified the query to select from po_headers_all instead of po_headers.
        select 'PO EXISTS'
          into x_found
          from po_headers_all
         where segment1 = x_document_num
           and NVL(org_id, -99) = NVL(l_purchasing_org_id, -99)
           and type_lookup_code IN ('STANDARD', 'PLANNED', 'BLANKET', 'CONTRACT');

     exception
        when NO_DATA_FOUND then
             null;
    when others then
         /* We have found a duplicate so raise the exception */

             x_progress := '45: insert_into_headers_interface: document_num is a ' ||
               'duplicate - not going to insert into po_headers_interface';
         IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
         END IF;

         raise;
     end;

     x_release_num          := NULL;
     x_release_date         := NULL;


    --begin bug 3401653
    select sob.currency_code, fsp.set_of_books_id
      into l_pou_currency_code, l_pou_sob_id
      from financials_system_params_all fsp,
           gl_sets_of_books sob
     where fsp.set_of_books_id = sob.set_of_books_id
           and nvl(fsp.org_id, -99) = nvl(l_purchasing_org_id, -99);

    select default_rate_type
      into l_pou_default_rate_type
      from po_system_parameters_all psp  --<Shared Proc FPJ>
     where nvl(psp.org_id, -99) = nvl(l_purchasing_org_id, -99);  --<Shared Proc FPJ>

    select sob.currency_code
      into l_rou_currency_code
      from financials_system_params_all fsp,
           gl_sets_of_books sob
     where fsp.set_of_books_id = sob.set_of_books_id
           and nvl(fsp.org_id, -99) = nvl(x_org_id, -99);
    --end bug 3401653

     /* Bug:565623. gtummala. 10/17/97
      * The backend also needs the currency_code to be populated in the
      * the po_headers_interface table. Should use functional currency if
      * its null.
      */
     if (x_currency_code is NULL) then
       x_currency_code_doc := l_pou_currency_code;
     else
       x_currency_code_doc := x_currency_code;
     end if;


    --begin bug 3401653

    IF(l_source_doc_currency_code is not null) THEN
        x_currency_code_doc := l_source_doc_currency_code;
    END IF;

    l_interface_rate_date := x_rate_date;
    IF(l_purchasing_org_id = x_org_id) THEN --x_org_id is req_org_id
       IF(x_currency_code_doc <> l_rou_currency_code) THEN
          --rate from req can go to po because pou=rou
          l_interface_rate_type := x_rate_type;
          l_interface_rate := x_rate;
       END IF;
    ELSE
        IF(l_pou_currency_code <> x_currency_code_doc) THEN
            IF l_pou_default_rate_type IS NULL THEN
                IF (g_po_wf_debug = 'Y') THEN
                    x_progress := '47: insert_into_headers_interface: Purchasing Operating unit' ||
                    ' has no default rate type, cannot create PO';
                    po_wf_debug_pkg.insert_debug (itemtype, itemkey, x_progress);
                END IF;
                return FALSE;
            END IF;

            -- copy rate info for PO currency to pou_currency
            l_interface_rate_type := l_pou_default_rate_type;
            l_interface_rate_date := trunc(sysdate);
            PO_CURRENCY_SV.get_rate(x_set_of_books_id => l_pou_sob_id,
                                    x_currency_code => x_currency_code_doc,
                                    x_rate_type => l_pou_default_rate_type,
                                    x_rate_date => l_interface_rate_date,
                                    x_inverse_rate_display_flag => 'N',
                                    x_rate => l_interface_rate,
                                    x_display_rate => l_display_rate);

       END IF;
       IF(l_rou_currency_code <> x_currency_code_doc) THEN
            IF l_pou_default_rate_type IS NULL THEN
                IF (g_po_wf_debug = 'Y') THEN
                    x_progress := '47: insert_into_headers_interface: Purchasing Operating unit' ||
                    ' has no default rate type, cannot create PO';
                    po_wf_debug_pkg.insert_debug (itemtype, itemkey, x_progress);
                END IF;

               return FALSE;
            END IF;

            -- Fail creation of the PO if there is no rate to convert from
            -- ROU currency to PO currency
            IF(PO_CURRENCY_SV.rate_exists (
                                      p_from_currency => l_rou_currency_code,
                                      p_to_currency => x_currency_code_doc,
                                      p_conversion_date => trunc(sysdate),
                                      p_conversion_type => l_pou_default_rate_type) <> 'Y')
                THEN
                IF (g_po_wf_debug = 'Y') THEN
                    x_progress := '48: insert_into_headers_interface: No rate defined to' ||
                    ' convert from Requesting OU currency to PO currency, cannot create PO';
                    po_wf_debug_pkg.insert_debug (itemtype, itemkey, x_progress);
                END IF;
                return FALSE;
            END IF;
       END IF;
    END IF;
    --end bug 3401653



   else

     /* Doc is RELEASE */
     x_currency_code_doc := x_currency_code;

     l_interface_rate_type := x_rate_type; --bug 3401653
     l_interface_rate_date := x_rate_date; --bug 3401653
     l_interface_rate := x_rate; --bug 3401653

     select segment1
       into x_document_num
       from po_headers
      where po_header_id = x_source_doc_id;

     /* Get the release number as the next release in sequence */

     select nvl(max(release_num),0)+1
       into x_release_num
       from po_releases por,
            po_headers poh
      where poh.po_header_id = x_source_doc_id
        and poh.po_header_id = por.po_header_id;

     /* Bug565530. gtummala. 10/23/97.
      * Even if the po_releases table gives us the next one in sequence,
      * this could conflict with a release_num that we have inserted into
      * the po_headers_interface table previously that has yet to converted
      * into a release eg. when we have two req lines that will be created
      * onto two diff. releases.
      */

     -- Bug 722352, lpo, 08/26/98
     -- Commented out the release_num filters for the next 2 queries.

     select count (*)
       into x_no_releases
       from po_headers_interface phi
      where phi.document_num = x_document_num;
      -- and phi.release_num  = x_release_num;

     if (x_no_releases <> 0) then
       select max(release_num)+1
     into x_release_num1
         from po_headers_interface phi
        where phi.document_num = x_document_num;
    --  and phi.release_num  = x_release_num;
     end if;

     -- End of fix. Bug 722352, lpo, 08/26/98



     -- <Action Date TZ FPJ>
      /* Bug 638599, lpo, 03/26/98
       * Strip out time portion to be consistent with Enter Release form.
       * 10/22/2003: Action Date TZ FPJ Change
       * Since release_date on the Enter Release form is now
       * a datetime, the trunc is now removed.
       */
      /* Set release date to sysdate */
      x_release_date := SYSDATE;

      -- <End Action Date TZ FPJ>


    end if;

    /* dreddy : bug 1394312 */
    if (x_release_num1 >= x_release_num) then
     x_release_num := x_release_num1;
    end if;

   /* Insert into po_headers_inteface */

   x_progress := '50: insert_into_headers_interface: Just about to insert into ' ||
          'po_headers_interface';
   IF (g_po_wf_debug = 'Y') THEN
      po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
   END IF;

   x_progress :=  '11: the doc type to be created ' || x_doc_type_to_create ;

    IF (g_po_wf_debug = 'Y') THEN
       po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
    END IF;

    begin
      insert into po_headers_interface
                    (wf_group_id,
                 interface_header_id,
                     interface_source_code,
                     batch_id,
                     process_code,
                     action,
                     document_type_code,
                     document_subtype,
                     document_num,
                     group_code,
                     vendor_id,
                     vendor_site_id,
                 release_num,
                     release_date,
                     agent_id,
                 currency_code,
                 rate_type_code,
                 rate_date,
                 rate,
                 creation_date,
                 created_by,
                     last_update_date,
                 last_updated_by,
                 pcard_id,
                                 attribute_category, --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 attribute6,         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 attribute7,         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 attribute8,         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 attribute9)         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                values
                    (x_group_id,
                 x_interface_header_id,
                     'PO',
                     x_batch_id,
                 'NEW',
                     'NEW',
                     'PO',                -- PO for both po's and releases
                     x_doc_type_to_create,
                     x_document_num,
                     x_group_code, /* Bug 2974129 */
                     x_suggested_vendor_id,
                     x_suggested_vendor_site_id,
                 x_release_num,
                 x_release_date,
                     x_suggested_buyer_id,
                 x_currency_code_doc,
                 l_interface_rate_type, --bug 3401653
                 l_interface_rate_date, --bug 3401653
                 l_interface_rate, --bug 3401653
                 x_creation_date,
                 x_created_by,
                 x_last_update_date,
                 x_last_updated_by,
                 x_pcard_id,
                                 x_attribute_category, --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 x_attribute6,         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 x_attribute7,         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 x_attribute8,         --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
                                 x_attribute9);        --added by Sandeep Gorla,E0216_Requisition-PoProcess,30-MAY-07,OD CUSTOMIZATION
      

                 return TRUE; --bug 3401653

    exception
        when others then
      x_progress := '55: insert_into_headers_interface: IN EXCEPTION when '||
            'inserting into po_headers_interface';
          IF (g_po_wf_debug = 'Y') THEN
             po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;

          raise;
    end;

    x_progress := '60: insert_into_headers_interface: Inserted into ' ||
          'po_headers_interface';
    IF (g_po_wf_debug = 'Y') THEN
       po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
    END IF;

    /* The interface_header_id is returned as an out parameter so that
     * subsequent lines can be tied to this same header if needed.
     */


exception
  when others then
    wf_core.context('po_autoinsert_into_headers_interface','create_doc',x_progress);
    raise;
end xx_insert_headers_interface;



/***********************************************************************************************************
 *AUTHOR     : Sandeep Gorla                                                                               *
 *RICE ID    : E0216_Requisition-POProcess                                                                 *
 *PROCEDURE  : XX_IS_PO_DRPSHIP_B2B                                                                        *
 *DESCRIPTION: Procedure to check whether the record in PO_HEADERS_INTERFACE is                            *
 *             from a DROPSHIP/BACKTOBACK requisition Line or not.If Yes,then                              *
 *             call XX_CREATE_DOC procedure which inserts the additional attribute                         *
 *             columns (attribute6,attribute7,attribute_category) of PO_HEADERS_INTERFACE                  *
 *             into PO_HEADERS_ALL table.This is done as the standard API PO_INTERFACE_S.CREATE_DOCUMENT   *
 *             does not insert attribute columns of PO_HEADERS_INTERFACE to PO_HEADERS_ALL                 *
 *             table.                                                                                      *
 ***********************************************************************************************************/
 

PROCEDURE XX_IS_PO_DRPSHIP_B2B(itemtype IN VARCHAR2
                              ,itemkey  IN VARCHAR2
                              ,actid    IN NUMBER
                              ,funcmode IN VARCHAR2
                              ,resultout OUT NOCOPY VARCHAR2) 
IS

ln_interface_header_id      Po_Headers_Interface.interface_header_id%TYPE;
x_progress              VARCHAR2(300);
x_org_id                        Mtl_Parameters.organization_id%TYPE;
lc_ds_b2b_po                    VARCHAR2(1);

BEGIN

    
x_org_id := po_wf_util_pkg.GetItemAttrNumber
                            (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ORG_ID');
                                         
fnd_client_info.set_org_context(to_char(x_org_id));

ln_interface_header_id := po_wf_util_pkg.GetItemAttrNumber
                        (itemtype   => itemtype,
                                         itemkey    => itemkey,
                                         aname      => 'INTERFACE_HEADER_ID');
--Check whether the PO in the interface table is for a backtoback/dropship sales order line
   BEGIN   
     SELECT 'Y'  
     INTO    lc_ds_b2b_po
     FROM    po_headers_interface
     WHERE   UPPER(attribute_category) IN ( SELECT UPPER(FLV.meaning) 
                                FROM   fnd_lookup_values FLV                                        
                            WHERE  FLV.lookup_type='OD_PO_CANCEL_ISP'                                     
                            AND    FLV.enabled_flag='Y'
                            AND    FLV.language=USERENV('LANG')
                            AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) 
                            AND    NVL(FLV.end_date_active,SYSDATE))
     AND     interface_header_id=ln_interface_header_id;    
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
          resultout   := wf_engine.eng_completed || ':' ||  'N';

          x_progress  := '10: XX_IS_PO_DRPSHIP_B2B: result = N';
       
          IF (g_po_wf_debug = 'Y') THEN
             po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;
   WHEN OTHERS THEN
          resultout   := wf_engine.eng_completed || ':' ||  'N';
      
      x_progress  := '10: XX_IS_PO_DRPSHIP_B2B: result = N';
             
      IF (g_po_wf_debug = 'Y') THEN
         po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;   
   END;
   
   
   IF lc_ds_b2b_Po='Y' THEN
   
      resultout  := wf_engine.eng_completed || ':' ||  'Y';

      x_progress := '20: XX_IS_PO_DRPSHIP_B2B: result = Y';
       
       IF (g_po_wf_debug = 'Y') THEN
          po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
       END IF;
   
   END IF;
  End XX_IS_PO_DRPSHIP_B2B;
  
  
/****************************************************************************************
 *                                                                  *
 *  Keyword: OD CUSTOMIZATION                                                           *
 *                                                                                      *
 *  Rice ID Author        Date Modified  Description                                    *
 *  E0240   SandeepGorla  02-Jun-2007    This procedure checks whether the PO created   *
 *                                       is for a Back to back or dropship sales order  *
 *                                       line.If Yes,then the PO line is checked for    *
 *                                       ONETIME deal or NONCODE in the procedure       *
 *                                       XX_IS_PO_LINE_DEAL_NONCODE.                    *
 *                                                                                      *    
 *                                                                                      *
 ****************************************************************************************/      
    
    
 PROCEDURE XX_IS_PO_FROM_SALES_ORDER (itemtype  IN VARCHAR2
                         ,itemkey   IN VARCHAR2
                         ,actid     IN NUMBER
                         ,funcmode  IN VARCHAR2
                         ,resultout OUT NOCOPY VARCHAR2) is
    
 x_doc_id    Po_Headers_All.po_header_id%TYPE;
 lc_po_type  Po_Headers_All.attribute_category%TYPE;
    
 BEGIN
    
 x_doc_id := po_wf_util_pkg.GetItemAttrNumber (itemtype  => itemtype,
                               itemkey   => itemkey,
                               aname     => 'AUTOCREATED_DOC_ID');
    
   BEGIN  --check whether the PO created is for a dropship/backtoback sales order line.
      SELECT 'Y'
      INTO   lc_po_type
      FROM   PO_HEADERS_ALL
      WHERE  po_header_id = x_doc_id
      AND    UPPER(attribute_category) IN ( SELECT UPPER(FLV.meaning) 
                                FROM   fnd_lookup_values FLV                                        
                            WHERE  FLV.lookup_type='OD_PO_CANCEL_ISP'                                     
                            AND    FLV.enabled_flag='Y'
                            AND    FLV.language=USERENV('LANG')
                            AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) 
                            AND    NVL(FLV.end_date_active,SYSDATE)); 
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        lc_po_type  :=  null;
   END;
    
       IF lc_po_type='Y' THEN
    
          resultout := wf_engine.eng_completed || ':' ||  'Y';
    
          x_progress:= '10: XX_IS_PO_FROM_SALES_ORDER: result = Y';
          IF (g_po_wf_debug = 'Y') THEN
             po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;
       ELSE
    
          resultout := wf_engine.eng_completed || ':' ||  'N';
          
          x_progress :='20: XX_IS_PO_FROM_SALES_ORDER: result = N';
          IF (g_po_wf_debug = 'Y') THEN
             po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
          END IF;
       END IF;
    
 END XX_IS_PO_FROM_SALES_ORDER;
    
    
/********************************************************************************************      
 *                                                                  *  
 *  Keyword: OD CUSTOMIZATION                                                               *
 *                                                                                          *  
 *  Rice ID Author        Date Modified  Description                                        *
 *  E0240   SandeepGorla  02-Jun-2007    This procedure checks whether the PO line ONETIME  *
 *                                       deal or NONCODE.IF PO line is either ONETIME or    *
 *                                       NONCODE ,the PO is set to Incomplete status and    *
 *                                       not approved.                                      *
 *                                                                                          *  
 *                                                                                          *         
 ********************************************************************************************/                                                                                       
            
    
    
 PROCEDURE XX_IS_PO_LINE_DEAL_NONCODE (itemtype  IN VARCHAR2
                          ,itemkey   IN VARCHAR2
                          ,actid     IN NUMBER
                          ,funcmode  IN VARCHAR2
                          ,resultout OUT NOCOPY VARCHAR2) is
    
    
 x_doc_id         po_headers_all.po_header_id%TYPE;
 lc_po_line_count NUMBER :=0;
 lc_ot_deal       Oe_Order_Lines_All.attribute9%TYPE;
 lc_noncode_lt    Oe_Order_Lines_All.attribute10%TYPE;
 ln_po_line_id    Po_Lines_All.po_line_id%TYPE;
 lc_po_type   Fnd_Lookup_Values.lookup_code%TYPE;
 ln_req_line_id   Po_Requisition_Lines_All.requisition_line_id%TYPE;
 ln_line_loc_id   Po_Line_Locations_All.line_location_id%TYPE;
    
--Fetch the Purchase order line details to check whether the line is onetime deal/non code
 CURSOR lcu_po_line IS
 SELECT PLA.po_line_id 
       ,DECODE(FLV.lookup_code,'BACKTOBACK','B2B'
       ,'NON-CODE BACKTOBACK','NB'
       ,'DROPSHIP','DS'
       ,'NON-CODE DROPSHIP','NDS') po_type
       ,PRL.requisition_line_id
       ,PLL.line_location_id
 FROM   po_headers_all PHA
       ,po_lines_all PLA
       ,po_line_locations_all PLL
       ,po_requisition_lines_all PRL                 
       ,fnd_lookup_values FLV
 WHERE  PHA.po_header_id=PLA.po_header_id
 AND    PLL.po_line_id=PLA.po_line_id
 AND    PRL.line_location_id=PLL.line_location_id
 AND    PHA.po_header_id=x_doc_id
 AND    UPPER(PHA.attribute_category)=UPPER(FLV.meaning)
 AND    FLV.lookup_type='OD_PO_CANCEL_ISP'
 AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE) 
 AND    NVL(FLV.end_date_active,SYSDATE)
 AND    FLV.enabled_flag='Y'
 AND    FLV.language=USERENV('LANG');
    
 BEGIN
    
 x_doc_id := po_wf_util_pkg.GetItemAttrNumber (itemtype  => itemtype
                              ,itemkey   => itemkey
                              ,aname     => 'AUTOCREATED_DOC_ID'); 
    
    
 OPEN lcu_po_line;
 LOOP
 FETCH lcu_po_line INTO ln_po_line_id,
                    lc_po_type,
                ln_req_line_id,
                ln_line_loc_id;
 EXIT WHEN lcu_po_line%NOTFOUND;
    
    IF lc_po_type IN ('DS','NDS') THEN
             
     --Check whether the line is a one time deal (which is dropship) for the po line.
     -- 15-nov-07 MC converted to extension table from DFF table
             
       BEGIN   
          SELECT  XOLL.one_time_deal
          INTO    lc_ot_deal
          FROM    oe_order_lines_all OEL
                 ,po_line_locations_all PLL
                 ,oe_drop_ship_sources ODSS
                 ,xx_om_line_attributes_all xoll 
          WHERE   ODSS.line_id=OEL.line_id
          AND     XOLL.line_id=OEL.line_id
          AND     ODSS.line_location_id=PLL.line_location_id
          AND     ODSS.line_location_id=ln_line_loc_id
          AND     ODSS.po_line_id=ln_po_line_id;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            lc_ot_deal    := null;          
       END;
    
             
       --Check whether the sales order line (which is dropship) is NON CODE line for the PO Line .
       -- 15-nov-07 MC converted to extension table from DFF table
       
       BEGIN
          SELECT  UPPER(XOLL.line_type)
          INTO    lc_noncode_lt
          FROM    oe_order_lines_all OEL
                 ,po_line_locations_all PLL
                 ,oe_drop_ship_sources ODSS
                 ,xx_om_line_attributes_all XOLL  
          WHERE   ODSS.line_id=OEL.line_id
          AND     XOLL.line_id=OEL.line_id
          AND     ODSS.line_location_id=PLL.line_location_id
          AND     ODSS.line_location_id=ln_line_loc_id
          AND     ODSS.po_line_id=ln_po_line_id;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            lc_noncode_lt  := null;  
       END;
               
          IF lc_ot_deal is not null or lc_noncode_lt ='NON CODE' THEN
    
             lc_po_line_count := lc_po_line_count+1;
             
          END IF;
    
    ELSIF lc_po_type in ('B2B','NB') THEN
    
      --Check whether the line is a one time deal (which is BacktoBack) for the po line.
      -- 15-nov-07 MC converted to extension table from DFF table
               
    
      BEGIN
         SELECT XOLL.one_time_deal   
         INTO   lc_ot_deal         
         FROM   oe_order_lines_all OEL
           ,mtl_reservations MR
           ,po_requisition_lines_all PRL
           ,po_line_locations_all PLL
           ,xx_om_line_attributes_all XOLL  
         WHERE  MR.demand_source_type_id=2
         AND    MR.demand_source_line_id = OEL.line_id
         AND    MR.supply_source_type_id = 17   
         AND    MR.supply_source_line_id = PRL.requisition_line_id
         AND    PRL.line_location_id=PLL.line_location_id
         AND    XOLL.line_id=OEL.line_id
         AND    PRL.requisition_line_id=ln_req_line_id
         AND    PLL.po_line_id =ln_po_line_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           lc_ot_deal := null;                   
      END;
    
               
      --Check whether the sales order line (which is backtoback) is NON CODE line for the PO Line .
      -- 15-nov-07 MC converted to extension table from DFF table
               
      BEGIN
         SELECT UPPER(XOLL.line_type)  
         INTO   lc_noncode_lt         
         FROM   oe_order_lines_all OEL
           ,mtl_reservations MR                   
           ,po_requisition_lines_all PRL
           ,po_line_locations_all PLL
           ,xx_om_line_attributes_all XOLL 
         WHERE  MR.demand_source_type_id=2
         AND    MR.demand_source_line_id = OEL.line_id
         AND    MR.supply_source_type_id = 17
         AND    MR.supply_source_line_id = PRL.requisition_line_id
         AND    PRL.line_location_id=PLL.line_location_id
         AND    XOLL.line_id=OEL.line_id
         AND    PRL.requisition_line_id=ln_req_line_id
         AND    PLL.po_line_id =ln_po_line_id;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
           lc_noncode_lt := null;        
      END;

              IF lc_ot_deal is not null OR lc_noncode_lt ='NON CODE' THEN
                 lc_po_line_count := lc_po_line_count+1;
              END IF;
    END IF; 
 END LOOP;
 CLOSE lcu_po_line;
    
    
          IF lc_po_line_count >0 THEN
               resultout  := wf_engine.eng_completed || ':' ||  'Y';
               x_progress :='10: XX_IS_PO_LINE_DEAL_NONCODE: result = Y';
               IF (g_po_wf_debug = 'Y') THEN
              po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
               END IF;
          ELSE
               resultout  := wf_engine.eng_completed || ':' ||  'N';
               x_progress :='20: XX_IS_PO_LINE_DEAL_NONCODE: result = N';
               IF (g_po_wf_debug = 'Y') THEN
              po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
               END IF;
          END IF;
 EXCEPTION 
 WHEN OTHERS THEN
                           
      
      lc_error_msg   :=  SUBSTR(SQLERRM,1,200);
      lc_entity_ref  := 'PO Line Id';
      ln_entity_ref_id   :=  ln_po_line_id;
  
      CLOSE lcu_po_line;
  
      XX_LOG_EXCEPTION_PROC (SQLCODE
                ,lc_error_msg
                ,lc_entity_ref
                ,ln_entity_ref_id
                    );
  
      resultout  := wf_engine.eng_completed || ':' ||  'Y';
      x_progress :='10: XX_IS_PO_LINE_DEAL_NONCODE: result = Y';
      IF (g_po_wf_debug = 'Y') THEN
          po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
      END IF; 
        
      wf_core.context('XX_WFL_PO_AUTOCREATE_DOC_PKG ','XX_IS_PO_LINE_DEAL_NONCODE',x_progress);
  
 END XX_IS_PO_LINE_DEAL_NONCODE;
  
  
   
/*************************************************************************************
 *      Author:         Sandeep Gorla                                                *
 *      Rice Id :       E0216-Requisition-PoProcess                                  *
 *  Procedure:  XX_CREATE_DOC                                                *
 *                                                                                   *
 *  Description:    This procedure is copied from standard package               *
 *                      PO_AUTOCREATE_DOC.CREATE_DOC  .                              *
 *                      Calls backend autocreate package to create the               *
 *          standard po or blanket release.This procedure                * 
 *                      calls XX_PO_INTERFACE_PKG.CREATE_DOCUMENT to insert          *
 *                      additional attribute columns of PO_HEADERS_INTERFACE         * 
 *                      table into PO_HEADERS_ALL.The custom package is              *
 *                      created as the standard API PO_INTERFACE_S.CREATE_DOCUMENT   *
 *                      does not insert attribute columns of interface table         *
 *                      to PO_HEADERS_ALL table.                                     * 
 *************************************************************************************/
 
  
 
PROCEDURE XX_CREATE_DOC (itemtype    IN   VARCHAR2,
                         itemkey     IN   VARCHAR2,
                         actid       IN   NUMBER,
                         funcmode    IN   VARCHAR2,
                         resultout   OUT NOCOPY  VARCHAR2 ) is

x_interface_header_id       number;
x_num_lines_processed       number;
x_autocreated_doc_id        number;
x_org_id            number;
x_progress              varchar2(300);

--<Shared Proc FPJ START>
l_purchasing_org_id             PO_HEADERS_ALL.org_id%TYPE;
l_return_status                 VARCHAR2(1);
l_msg_count                     NUMBER;
l_msg_data                      FND_NEW_MESSAGES.message_text%TYPE;
l_doc_number                    PO_HEADERS_ALL.segment1%TYPE;
--<Shared Proc FPJ END>

begin

   /* Set the org context. Backend create_po process assumes it is in
    * an org.
    */

    x_org_id := po_wf_util_pkg.GetItemAttrNumber
                    (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'ORG_ID');
    --<Shared Proc FPJ START>
    l_purchasing_org_id := po_wf_util_pkg.GetItemAttrNumber
                    (itemtype => itemtype,
                                         itemkey  => itemkey,
                                         aname    => 'PURCHASING_ORG_ID');
    --<Shared Proc FPJ END>
    fnd_client_info.set_org_context(to_char(x_org_id));

    x_interface_header_id := po_wf_util_pkg.GetItemAttrNumber
                        (itemtype  => itemtype,
                                        itemkey    => itemkey,
                                        aname      => 'INTERFACE_HEADER_ID');




    /* Call the main sever side routine to actually create
     * the documents, ie:
     *          - default in values not populated
     *          - group accordingly
     *          - insert into the main tables from the
     *            the interface tables.
     *
     * x_document_id is populated with po_header_id for pos
     * and po_release_id for releases
     */


     x_progress:= '10: xx_create_doc: Kicking off backend with' ||
              'interface_header_id = '|| to_char(x_interface_header_id);
     IF (g_po_wf_debug = 'Y') THEN
        po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
     END IF;

     --<Shared Proc FPJ>
     --Call Autocreate Backend to create the document
     --in the purchasing org specified.
     
     --<Comments>Added by Sandeep Gorla .Copied PO_INTERFACE_S.Create_documents 
     --to XX_PO_INTERFACE_PKG.CREATE_DOCUMENTS
     --to insert additional attributes and attribute category columnes 
     --into po_headers_interface table.RiceID:E0216-Requisition-POProcess,10-Apr-07
     --<Comments>
     
     xx_po_interface_pkg.create_documents(p_api_version     => 1.0,
                                     x_return_status            => l_return_status,
                                     x_msg_count                => l_msg_count,
                                     x_msg_data                 => l_msg_data,
                                     p_batch_id                 => x_interface_header_id,
                                     p_req_operating_unit_id    => x_org_id,
                                     p_purch_operating_unit_id  => l_purchasing_org_id,
                                     x_document_id              => x_autocreated_doc_id,
                                     x_number_lines             => x_num_lines_processed,
                                     x_document_number          => l_doc_number,
                 -- Bug 3648268. Using lookup code instead of hardcoded value
                                     p_document_creation_method => 'CREATEDOC'
                                    );
--<Comments>
--End of code by Sandeep Gorla ,RiceID:E0216-Requisition-PoProcess,10-Apr-07
--<Comments>

     x_progress := '20: xx_create_doc: Came back from the backend with '  ||
           'doc_id = ' || to_char(x_autocreated_doc_id) || '/ ' ||
           'num_lines_processed = ' || to_char(x_num_lines_processed);

     IF (g_po_wf_debug = 'Y') THEN
        po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
     END IF;


     /* If at least one req line got processed then we have succeeded in
      * creating the po or release
      */

     if (x_num_lines_processed > 0) then
       po_wf_util_pkg.SetItemAttrNumber (itemtype   => itemtype,
                                    itemkey    => itemkey,
                                    aname      => 'AUTOCREATED_DOC_ID',
                                    avalue     => x_autocreated_doc_id);

       /* Call procedure to setup notification data which will be used
        * in sending a notification to the buyer that the doc has been
        * created successfully.
        */

       po_autocreate_doc.setup_notification_data (itemtype, itemkey);

       resultout := wf_engine.eng_completed || ':' ||  'CREATE_OK';

       x_progress:= '30: xx_create_doc: result = CREATE_OK';
       IF (g_po_wf_debug = 'Y') THEN
          po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
       END IF;

     else
       resultout := wf_engine.eng_completed || ':' ||  'CREATE_FAILED';

       x_progress:= '40: xx_create_doc: result = CREATE_FAILED';
       IF (g_po_wf_debug = 'Y') THEN
          po_wf_debug_pkg.insert_debug(itemtype,itemkey,x_progress);
       END IF;

     end if;

exception
  when others then
    wf_core.context('po_autocreate_doc','xxcreate_doc',x_progress);
    raise;
end xx_create_doc;

--<Comments> 
--Copied this procedure as this is a private procedure in PO_AUTOCREATE_DOC Procedure,Sandeep Gorla,10-APR-2007
--<Comments>

FUNCTION  get_document_num (
  p_purchasing_org_id IN NUMBER --<Shared Proc FPJ>
) RETURN VARCHAR2
IS

 

  pragma AUTONOMOUS_TRANSACTION;
  x_document_num varchar2(25);
  x_progress    varchar2(300);

begin

        x_progress := '10: get_document_num: Just before get doc' ||
                       'num from po_unique_identifier_control';

        --<Shared Proc FPJ>
        --Modified the query to run against po_unique_identifier_cont_all
        --instead of po_unique_identifier_control.
        select to_char(current_max_unique_identifier +1)
          into x_document_num
          from po_unique_identifier_cont_all
         where table_name = 'PO_HEADERS'
               AND NVL(org_id, -99) = NVL(p_purchasing_org_id, -99)
         for update of current_max_unique_identifier;

        --<Shared Proc FPJ>
        --Modified the statement to update po_unique_identifier_cont_all
        --instead of po_unique_identifier_control.
        update po_unique_identifier_cont_all
           set current_max_unique_identifier = current_max_unique_identifier+1
         where table_name = 'PO_HEADERS'
               AND NVL(org_id, -99) = NVL(p_purchasing_org_id, -99);

        /* Commit to release the lock on the po_unique_identifier_control
           table */

        COMMIT;

        x_progress := '20: get_document_num: Just after get doc' ||
                       'num from po_unique_identifier_control';

        return x_document_num;

exception
  when others then
   wf_core.context('po_autocreate_doc','get_document_num',x_progress);
   raise;

end get_document_num;



 
--<Comments> 
--Copied this procedure as this is a private procedure in PO_AUTOCREATE_DOC Procedure.,Sandeep Gorla,10-APR-2007
--<Comments>
 
--Checks whether the referenced document is not cancelled or finally closed
PROCEDURE is_ga_still_valid(p_ga_po_header_id   IN NUMBER,
                            x_ref_is_valid          OUT NOCOPY VARCHAR2) IS

BEGIN
         x_ref_is_valid := 'N';

         --Check the referenced GA for cancel/finally closed status
         select 'Y'
         into   x_ref_is_valid
         from   po_headers_all poh
         where  poh.po_header_id = p_ga_po_header_id and
                nvl(poh.cancel_flag, 'N') = 'N' and
                nvl(poh.closed_code, 'OPEN')  <> 'FINALLY CLOSED';

EXCEPTION
   WHEN OTHERS THEN
       x_ref_is_valid := 'N';
END;


--<Comments> 
--Copied this procedure as this is a private function in PO_AUTOCREATE_DOC Procedure.,10-APR-2007
--<Comments>
/* Private Procedure/Functions */

FUNCTION valid_contact(p_vendor_site_id number, p_vendor_contact_id number) RETURN BOOLEAN
is
   x_count number;
begin
    if (p_vendor_site_id is null or p_vendor_contact_id is null) then
        return false;
    else
        -- check if contact on req. lines is valid
        select count(*) into x_count
        from po_vendor_contacts
        where vendor_site_id = p_vendor_site_id
        and vendor_contact_id = p_vendor_contact_id
        and nvl(inactive_date, sysdate+1) > sysdate;

        if (x_count > 0) then
            return true;
        else
            return false;
        end if;
    end if;
end;
--<Comments> 
--Copied this procedure as this is a private Function in PO_AUTOCREATE_DOC Procedure.Sandeep Gorla,10-APR-2007
--<Comments>
FUNCTION get_contact_id(p_contact_name varchar2, p_vendor_site_id number) RETURN NUMBER
IS
     x_first_name varchar2(60);
     x_last_name  varchar2(60);
     x_comma_pos  number;
     x_contact_id number := null;
BEGIN

    begin
        select max(vendor_contact_id)
        into x_contact_id
        from po_supplier_contacts_val_v
        where vendor_site_id = p_vendor_site_id
        and contact = p_contact_name;
    exception
        when others then
        x_contact_id := null;
    end;

    return x_contact_id;
END;

--<Comments> 
--Copied this procedure as this is a private procedure in PO_AUTOCREATE_DOC Procedure.,Sandeep Gorla,10-APR-2007
--<Comments>

----------------------------------------------------------------
--Start of Comments
--Name: set_purchasing_org_id
--Pre-reqs:
--  None
--Modifies:
--  None
--Locks:
--  None
--Function:
--  Helper function to set the PURCHASING_ORG_ID workflow
--  attribute.
--Parameters:
--IN:
--itemtype
--  internal name for the item type
--itemkey
--  primary key generated by the workflow for the item type
--p_org_id
--  org_id of the operating unit where the requisition in
--  question was created
--p_suggested_vendor_site_id
--  id of the suggested vendor site for the requisition in
--  question
--Notes:
--  Added for Shared Procurement Services Project in FPJ
--Testing:
--  None
--End of Comments
----------------------------------------------------------------
--<Comments> 
--Copied this procedure as this is a private procedure in PO_AUTOCREATE_DOC Procedure.,Sandeep Gorla,10-APR-2007
--<Comments>
PROCEDURE set_purchasing_org_id(
  itemtype              IN VARCHAR2,
  itemkey               IN VARCHAR2,
  p_org_id          IN NUMBER,
  p_suggested_vendor_site_id    IN NUMBER
)
IS

  l_purchasing_org_id   PO_HEADERS_ALL.org_id%TYPE;
  l_progress        VARCHAR2(300);

BEGIN

  --Get the purchasing_org_id

  l_progress:= '10: set_purchasing_org_id: org_id = ' || to_char(p_org_id);

  IF p_suggested_vendor_site_id IS NOT NULL THEN
    BEGIN
      SELECT org_id
      INTO l_purchasing_org_id
      FROM po_vendor_sites_all
      WHERE vendor_site_id = p_suggested_vendor_site_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_purchasing_org_id := p_org_id;
    END;
  ELSE
    --suggested_vendor_site_id is null
    l_purchasing_org_id := p_org_id;
  END IF;


  l_progress:= '20: set_purchasing_org_id: org_id = ' || to_char(p_org_id)
                || ' purchasing_org_id = ' || to_char(l_purchasing_org_id);


  --Set purchasing_org_id workflow attribute
  po_wf_util_pkg.SetItemAttrNumber (itemtype   => itemtype,
                                itemkey    => itemkey,
                                aname      => 'PURCHASING_ORG_ID',
                                avalue     => l_purchasing_org_id);

EXCEPTION

  WHEN OTHERS THEN
    wf_core.context('po_autocreate_doc', 'set_purchasing_org_id', l_progress);
    RAISE;

END set_purchasing_org_id;                                            

END XX_WFL_CREATEPO_DOC_PKG ;
/
SHOW ERRORS


