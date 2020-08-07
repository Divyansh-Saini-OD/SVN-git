WHENEVER SQLERROR EXIT FAILURE

-- +==========================================================================+
-- |                               Office Depot                               |
-- +==========================================================================+
-- | Name        :  XX_AP_WRITEOFF_PONUM_V.vw                                 |
-- | RICE ID     :  E3522                                                     |
-- | Subversion Info:                                                         |
-- |                                                                          |
-- |                                                                          |
-- |Change Record:                                                            |
-- |===============                                                           |
-- |Version    Date           Author                Remarks                   | 
-- |=======    ===========    ==================    ==========================+
-- |1.0        18-OCT-2017    Paddy Sanjeevi        Initial Version           |
-- +==========================================================================+

CREATE OR REPLACE FORCE EDITIONABLE VIEW APPS.XX_AP_WRITEOFF_PONUM_V (SEGMENT1, OPERATING_UNIT_ID) AS 
  select distinct NVL(poh.CLM_DOCUMENT_NUMBER,poh.SEGMENT1) segment1,crs.operating_unit_id
from   po_headers_all poh,
        po_distributions_all pod,
        cst_reconciliation_summary crs
where  pod.po_distribution_id = crs.po_distribution_id
and    poh.po_header_id = pod.po_header_id
order by NVL(poh.CLM_DOCUMENT_NUMBER,poh.SEGMENT1);
/					
show err
