CREATE OR REPLACE
PACKAGE XX_MER_JITA_PKG AS
-- +===================================================================+
-- | Name  : XX_MER_JITA_PKG                                           |
-- | Description      : This package houses all procedures, functions, |
--                      variables for JITA Just IN Time Allocations    |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks            	       |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A              S. Saripalli        Initial draft version    |
-- |DRAFT 1B DD-MON-YYYY                                               |
-- |1.0      DD-MON-YYYY                                               |
-- +===================================================================+

-- Constants
  G_STORE_TYPE_NON_TRADITIONAL CONSTANT VARCHAR2(2) := 'NT';
  G_STORE_TYPE_REGULAR constant CHAR(2) := 'RG';
  G_STORE_TYPE_RELOC   constant CHAR(2) := 'RL';
  G_STORE_TYPE_REMERCH constant CHAR(2) := 'RM';
  
  G_PROCESS_NAME_ONLINE constant CHAR(6):= 'ONLINE';
  G_PROCESS_NAME_60D constant CHAR(3):= '60D';
  G_PROCESS_NAME_100D constant CHAR(4):= '100D';
  G_PROCESS_NAME_200D constant CHAR(4):= '200D';
  G_PROCESS_NAME_650D constant CHAR(4):= '650D';
  G_PROCESS_NAME_ALL constant CHAR(3):= 'ALL';
  
  G_ALLOC_CODE_LOCK  constant CHAR(4) := 'LOCK'; -- planner locked in 
  G_ALLOC_CODE_ATP   constant CHAR(3) := 'ATP'; --ATP customer orders
  G_ALLOC_CODE_ATP_SL   constant CHAR(5) := 'ATPSL';
  G_ALLOC_CODE_NS_BOTTOM constant CHAR(8) := 'NSBOTTOM';
  G_ALLOC_CODE_NS_NEED constant CHAR(6) := 'NSNEED';
  G_ALLOC_CODE_OUTS constant CHAR(4) := 'OUTS';
  G_ALLOC_CODE_NEED constant CHAR(4) := 'NEED';
  G_ALLOC_CODE_CONFIRM constant CHAR(7) := 'CONFIRM';-- for confirmation distro
  
  G_SUB_INV_CODE_STOCK constant CHAR(5) := 'STOCK';
  
  G_OVERAGE_START_DISTRO_NUM constant NUMBER  := 1000001;
  G_DISTRO_TYPE_OVERAGE CONSTANT NUMBER := 7;
  G_DISTRO_TYPE_FLOWTHRU CONSTANT NUMBER := 3;
  --G_OVERAGE_THRESHOLD constant NUMBER(8,3) := 0.1;  
  G_DISTRO_TYPE_CONFIRM constant NUMBER := 99;
  --G_BOTTOM_FILL_THRESHOLD constant NUMBER(8,3) := 0.51;
  
  G_THRESHOLD constant NUMBER := 120; -- mins  to decide which appts to process
  
  


-- Procedures

-- +===================================================================+
-- | Name  : APPT_PROC                                                 |
-- | Description      :                                                |
-- |                    for a given order.                             |
-- |                                                                   |
-- | Parameters :       Order_id                                       |
-- |                                                                   |
-- |                                                                   |
-- | Returns :          Order_date                                     |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+
PROCEDURE APPT_PROC (
  p_ASN IN  VARCHAR2,
  p_org_id IN NUMBER,
  p_appt_time IN varchar2 );

/*
PROCEDURE JITA_ONLINE_TEST (
  p_ASN    IN  NUMBER,
  p_po_nbr IN  NUMBER,
  p_sku IN NUMBER,
  p_location_id IN NUMBER,
  p_received_qty IN NUMBER,
  p_is_overage IN BOOLEAN,
  p_xml_out OUT NOCOPY CLOB);
*/

PROCEDURE JITA_DISCREPANCY (
  p_source_org_id IN NUMBER,
  p_dest_org_id IN NUMBER,
  p_ASN IN VARCHAR2,
  p_po_num IN VARCHAR2,
  p_po_line_num IN NUMBER,
  p_po_shipment_num IN NUMBER,
  p_SKU IN VARCHAR2,
  p_Adj_Qty IN NUMBER,
  p_Adj_type IN VARCHAR2 );

PROCEDURE JITA_GUARD_CHECKIN (
  p_ASN IN  VARCHAR2,
  p_threshold IN  NUMBER,
  p_org_id NUMBER,
  p_xml_out OUT NOCOPY CLOB);

PROCEDURE JITA_PRECOMPUTE (
  ERRBUF  OUT NOCOPY VARCHAR2,
  RETCODE OUT NOCOPY VARCHAR2,
  p_ORG_ID IN HR_ALL_ORGANIZATION_UNITS.organization_id%TYPE);


PROCEDURE JITA_BATCH (
  ERRBUF  OUT NOCOPY VARCHAR2,
  RETCODE OUT NOCOPY VARCHAR2,
  p_Program_name VARCHAR2,
  p_warehouse_list VARCHAR2 );


END XX_MER_JITA_PKG;
