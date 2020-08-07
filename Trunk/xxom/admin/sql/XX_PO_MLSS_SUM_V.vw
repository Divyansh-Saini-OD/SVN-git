-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_SUM_V.vw                                 |
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
PROMPT Dropping View XX_PO_MLSS_SUM_V 
PROMPT

DROP VIEW XX_PO_MLSS_SUM_V ;


PROMPT
PROMPT Creating the Custom Views ......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the view XX_PO_MLSS_SUM_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW APPS.xx_po_mlss_sum_v
                    (      
                       organization_code
                      ,mlss_header_id
                      ,category
                      ,vendor_name
                      ,vendor_site_code
                      ,supply_loc_no
                      ,rank
                      ,end_point       
                      ,ds_lt        
                      ,b2b_lt          
                      ,supp_loc_ac     
                      ,supp_facility_cd
                     )
                    AS 
                    SELECT  xpmhv.organization_code
                           ,xpmhv.mlss_header_id
                           ,xpmhv.category
                           ,xpmdv.vendor_name
                           ,xpmdv.vendor_site_code
                           ,xpmdv.supply_loc_no
                           ,xpmdv.rank
                           ,xpmdv.end_point
                           ,xpmdv.ds_lt
                           ,xpmdv.b2b_lt
                           ,xpmdv.supp_loc_ac
                           ,xpmdv.supp_facility_cd
                    FROM    xx_po_mlss_hdr_v   xpmhv,
                            xx_po_mlss_det_v   xpmdv
                    WHERE   xpmhv.mlss_header_id  =  xpmdv.mlss_header_id;
                    

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;