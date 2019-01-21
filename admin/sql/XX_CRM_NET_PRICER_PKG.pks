SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE XX_CRM_NET_PRICER_PKG 
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name        :  XX_CRM_SOAP_API.pks                                |
-- | Description :  SOAP Message calls generic package                 |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author             Remarks                   |
-- |========  =========== ================== ==========================|
-- |DRAFT 1a  29-Sep-2009 Indra Varada       Initial draft version     |
-- +===================================================================+
AS

PROCEDURE get_net_sku_price
(
 PICST         IN      NUMBER
,PIADRSEQ      IN      NUMBER
,PIADRKEY      IN      VARCHAR2
,PILOC         IN      VARCHAR2
,PISK          IN      VARCHAR2
,PIQTY         IN      NUMBER 
,POPCUS        IN OUT  NUMBER        
,POPSAD        IN OUT  NUMBER      
,POPRDC        IN OUT  VARCHAR2    
,POCPRD        IN OUT  VARCHAR2 
,POSELLPCK     IN OUT  NUMBER     
,POORDU        IN OUT  VARCHAR2
,POIDES        IN OUT  VARCHAR2
,POQTYAVAIL    IN OUT  NUMBER    
,POPALS        IN OUT  NUMBER    
,POACP         IN OUT  NUMBER     
,POLOCAT       IN OUT  VARCHAR2
,POCDVN        IN OUT  VARCHAR2
,POVPRD        IN OUT  VARCHAR2
,POVNDID       IN OUT  VARCHAR2
,POMETASKU     IN OUT  VARCHAR2  
,POIMPRTSKU    IN OUT  VARCHAR2
,POSTDASSORT   IN OUT  VARCHAR2
,POTDCCOST     IN OUT  NUMBER     
,PORETURNSKU   IN OUT  VARCHAR2
,PODEPT        IN OUT  VARCHAR2
,POWEIGHT      IN OUT  VARCHAR2
,POADDDLVCHG   IN OUT  NUMBER    
,POASSORTFLG   IN OUT  VARCHAR2
,POBUNDLEFLG   IN OUT  VARCHAR2
,POPREMIUMFLG  IN OUT  VARCHAR2
,POCLAS        IN OUT  VARCHAR2 
,POSCLAS       IN OUT  VARCHAR2
,PODROPSHIP    IN OUT  VARCHAR2
,POGSASKU      IN OUT  VARCHAR2
,POFURNITURE   IN OUT  VARCHAR2
,POOVERSIZE    IN OUT  VARCHAR2
,POSELLBRAND   IN OUT  VARCHAR2
,POBULKPRICE   IN OUT  VARCHAR2
,POCOSTUP      IN OUT  VARCHAR2
,POOFFCAT      IN OUT  VARCHAR2
,POOFFLIST     IN OUT  VARCHAR2
,POOFFRETAIL   IN OUT  VARCHAR2
,PORETCONT     IN OUT  VARCHAR2
,POPROPRIETARY IN OUT  VARCHAR2  
,POHAZARD      IN OUT  VARCHAR2
,POPRCTYP      IN OUT  VARCHAR2
,POPPRMD       IN OUT  VARCHAR2
,POCONTPLANID  IN OUT  NUMBER    
,POCONTPLANSEQ IN OUT  NUMBER   
,POMETHODPCT   IN OUT  NUMBER   
,PODELONLY     IN OUT  VARCHAR2
,POCOSTTOUSE   IN OUT  VARCHAR2  
,POERROR       IN OUT  VARCHAR2 
);

END XX_CRM_NET_PRICER_PKG;
/
SHOW ERRORS;
