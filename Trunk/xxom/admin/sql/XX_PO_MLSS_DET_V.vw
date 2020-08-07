-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_DET_V.vw                                 |
-- | Rice ID      :E1252_MultiLocationSupplierSourcing                 |
-- | Description  :OD MultiLocationSupplier Sourcing View Creation     |
-- |               Script                                              |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A 15-MAR-2007  Hema Chikkanna   Initial draft version       |
-- |1.0      17-MAR-2007  Hema Chikkanna   Baselined after testing     |
-- |1.1      27-APR-2007  Hema Chikkanna   Updated the Comments Section|
-- |                                       as per onsite requirement   |
-- |1.2      04-MAY-2007  Hema Chikkanna   Created Indvidual scripts as|
-- |                                       per onsite requirement      |
-- |1.3      18-JUN-2007  Hema Chikkanna   Incorporated the file name  |
-- |                                       change as per onsite        |
-- |                                       requirement                 |
-- |                                                                   |
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
PROMPT Dropping View XX_PO_MLSS_DET_V 
PROMPT

DROP VIEW XX_PO_MLSS_DET_V ;


PROMPT
PROMPT Creating the Custom Views ......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT Creating the view XX_PO_MLSS_DET_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW APPS.xx_po_mlss_det_v
                    ( row_id
                     ,mlss_header_id
                     ,mlss_line_id
                     ,vendor_id  
                     ,vendor_name
                     ,vendor_site_id
                     ,vendor_site_code
                     ,supply_loc_no
                     ,rank
                     ,end_point       
                     ,ds_lt        
                     ,b2b_lt          
                     ,supp_loc_ac     
                     ,supp_facility_cd
                     ,last_update_login
                     ,last_update_date
                     ,last_updated_by 
                     ,creation_date
                     ,created_by 
                     )
AS 
                    SELECT  xpmd.rowid
                           ,xpmh.mlss_header_id
                           ,xpmd.mlss_line_id
                           ,xpmd.vendor_id
                           ,pv.vendor_name
                           ,xpmd.vendor_site_id
                           ,pova.vendor_site_code
                           ,xpmd.supply_loc_no
                           ,xpmd.rank
                           ,xpmd.end_point
                           ,xpmd.ds_lt
                           ,xpmd.b2b_lt
                           ,xpmd.supp_loc_ac
                           ,xpmd.supp_facility_cd
                           ,xpmh.last_update_login
                           ,xpmd.last_update_date
                           ,xpmd.last_updated_by
                           ,xpmd.creation_date
                           ,xpmd.created_by
                    FROM    xx_po_mlss_hdr      xpmh
                           ,xx_po_mlss_det      xpmd
                           ,po_vendors          pv
                           ,po_vendor_sites_all pova
                    WHERE   xpmh.mlss_header_id = xpmd.mlss_header_id
                    AND     pv.vendor_id        = pova.vendor_id
                    AND     xpmd.vendor_id      = pv.vendor_id
                    AND     xpmd.vendor_site_id = pova.vendor_site_id;  
                
    

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;