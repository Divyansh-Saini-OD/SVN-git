-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name         :XX_PO_MLSS_HDR_V.vw                                 |
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
PROMPT Dropping View XX_PO_MLSS_HDR_V
PROMPT

DROP VIEW XX_PO_MLSS_HDR_V;

PROMPT
PROMPT Creating the Custom Views ......
PROMPT

WHENEVER SQLERROR EXIT 1

PROMPT
PROMPT Creating the View XX_PO_MLSS_HDR_V .....
PROMPT

CREATE OR REPLACE FORCE VIEW APPS.xx_po_mlss_hdr_v
                (      
                  row_id
                 ,mlss_header_id
                 ,organization_id
                 ,organization_code
                 ,category
                 ,category_level
                 ,category_dsp
                 ,mlss_name
                 ,start_date
                 ,end_date
                 ,imu_amt_pt
                 ,imu_value
                 ,last_update_login
                 ,last_update_date
                 ,last_updated_by
                 ,creation_date
                 ,created_by 
                 )
AS 
                  SELECT  XPMH.rowid
                         ,XPMH.mlss_header_id
                         ,OOD.organization_id
                         ,OOD.organization_code||'-'||OOD.organization_name
                         ,XPMH.category
                         ,XPMH.category_level
                         ,FFVV.description
                         ,OOD.organization_code||'-'||FFVV.description
                         ,XPMH.start_date
                         ,XPMH.end_date
                         ,XPMH.imu_amt_pt
                         ,XPMH.imu_value
                         ,XPMH.last_update_login
                         ,XPMH.last_update_date
                         ,XPMH.last_updated_by
                         ,XPMH.creation_date
                         ,XPMH.created_by
                  FROM    xx_po_mlss_hdr                XPMH
                         ,org_organization_definitions  OOD
                         ,fnd_id_flex_segments          FIFG 
                         ,fnd_id_flex_structures        FIFS 
                         ,fnd_flex_values_vl            FFVV 
                  WHERE   XPMH.using_organization_id    = OOD.organization_id 
                  AND     FFVV.flex_value               = XPMH.category
                  AND     FIFG.segment_name             = XPMH.category_level
                  AND     FIFS.application_id           = FIFG.application_id
                  AND     FIFG.id_flex_code             = FIFS.id_flex_code 
                  AND     FIFG.id_flex_num              = FIFS.id_flex_num 
                  AND     FIFG.flex_value_set_id        = FFVV.flex_value_set_id
                  AND     FIFS.id_flex_structure_code   = 'ITEM_CATEGORIES'
                  AND     FIFG.application_id           = 401  ; 


WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;