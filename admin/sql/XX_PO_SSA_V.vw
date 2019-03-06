-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_SSA_V.vw                                      |
-- | Rice ID      :I1095_SupplierSourcingAssignments                   |
-- | Description  :OD Supplier Sourcing Assignments View Creation      |
-- |               Script                                              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 25-APR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.1      04-MAY-2007  Hema Chikkanna   Created Indvidual scripts as|
-- |                                       per onsite requirement      |
-- |1.2      19-JUN-2007  Hema Chikkanna   Incorporated the changes to |
-- |                                       file name as per the new    |
-- |                                       MD40 document               |
-- |1.3      11-JUL-2007  Hema Chikkanna   Modified the view to display|
-- |                                       global suppliers in the     |
-- |                                       custom form                 |
-- |1.4      17-JUL-2007  Hema Chikkanna   Modified the view to display|
-- |                                       disabled suppliers also     |
-- |1.5	 02-Oct-2007  Bala E		 Modified the view to display| 
-- |							 not to display the disabled |
-- |							 suppliers and not having the|
-- |							 rank assigned.  	           |
-- +===================================================================+
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Dropping Existing Custom Views......
PROMPT

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Dropping View XX_PO_SSA_V
PROMPT

DROP VIEW XX_PO_SSA_V;

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the Custom Views.......
PROMPT

PROMPT
PROMPT Creating the View XX_PO_SSA_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW APPS.XX_PO_SSA_V
         (   row_id
            ,asl_id
            ,using_organization_id
            ,organization_code
            ,item_id
            ,item_name
            ,vendor_id
            ,vendor_name
            ,vendor_site_id
            ,vendor_site_code
            ,disabled
            ,vm_indicator
            ,rank
            ,supp_loc_count_ind
            ,inv_type_ind
            ,primary_supp_ind
            ,lead_time
            ,drop_ship_cd
            ,mls_source_name
            ,primary_vendor_item
            ,backorders_allowed_flag
            ,Legacy_vendor_number		
            ,mlss_Header_id  
         ) AS
         SELECT  PASL.rowid
                ,PASL.asl_id
                ,PASL.using_organization_id
                ,MP.organization_code
                ,PASL.item_id
                ,MSIB.segment1
                ,PASL.vendor_id
                ,PV.vendor_name
                ,PASL.vendor_site_id
                ,PVSA.vendor_site_code
                ,PASL.disable_flag
                ,XPVSKV.vertical_market_indicator
                ,XISRA.rank_priority
                ,PVSA.attribute8                    
                ,XPVSKV.inventory_type_code         
                ,XISRA.primary_supp_ind
                ,XPVSKV.lead_time
                ,XISRA.drop_ship_cd
                ,XPSSA.mls_source_name
                -- Added additional fields
                ,PASL.primary_vendor_item
                ,XISRA.backorders_allowed
		    ,PVSA.attribute9
                ,XPSSA.mlss_header_id 
         FROM    po_approved_supplier_list     PASL
                ,mtl_parameters                MP 
                ,mtl_system_items_b            MSIB
                ,xxpo_item_supp_rms_attribute  XISRA
                ,xx_po_supp_sr_assignment      XPSSA
                ,po_vendors                    PV
                ,po_vendor_sites_all           PVSA
                ,xx_po_vendor_sites_kff_v      XPVSKV
         WHERE   PASL.asl_id                    = XPSSA.asl_id(+)
         AND     PASL.attribute1                = XISRA.combination_id(+)
         AND     PASL.vendor_site_id            = XPVSKV.vendor_site_id(+)
         -- Changed on 11-Jul-07 to display global suppliers
         -- AND  MP.organization_id             = PASL.using_organization_id
         AND     MP.organization_id             = DECODE(PASL.using_organization_id,-1,PASL.owning_organization_id,PASL.using_organization_id)
         -- End of Change 11-Jul-07
         AND     PASL.item_id                   = MSIB.inventory_item_id
         AND     MP.organization_id             = MSIB.organization_id
         AND     PASL.vendor_id                 = PV.vendor_id
         AND     PVSA.vendor_site_id(+)         = PASL.vendor_site_id 
         AND     NVL(PASL.disable_flag||'','N') = 'N'
         -- changed on 02-Oct-07 to validate the disabled suppliers
         AND NVL(XISRA.END_DATE_ACTIVE, sysdate - 1) < sysdate
         AND NVL(XISRA.END_DATE_ACTIVE, sysdate + 1) > sysdate
         -- Changed to validate the Rank_priority
         AND XISRA.rank_priority is not null
         -- End of Change 02-Oct-07
         ORDER BY PASL.asl_id;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;