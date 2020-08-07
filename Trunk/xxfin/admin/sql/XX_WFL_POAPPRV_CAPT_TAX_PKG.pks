SET SHOW         OFF 
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
SET TERM         ON

PROMPT Creating Package Specfication XX_WFL_POAPPRV_CAPT_TAX_PKG
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_WFL_POAPPRV_CAPT_TAX_PKG
AS
-- +====================================================================+
 -- |                  Office Depot - Project Simplify                   |
 -- |                       WIPRO Technologies                           |
 -- +====================================================================+
 -- | Name : XX_WFL_POAPPRV_CAPT_TAX_PKG                                 |
 -- |                                                                    |
 -- | Description : This Package will be used to determine whether tax   |
 --                 has to be calculated for a PO and hence determines   |
 --                 whether Taxware concurrent program should be called. |
 -- |                                                                    |
 -- |Change Record:                                                      |
 -- |===============                                                     |
 -- |Version   Date          Author                     Remarks          |
 -- |=======   ==========   =============               =================|
 -- |Draft 1A 29-MAY-2007  Ramalingam Muthaianpillai,                    |
 -- |                       Wipro Technologies           Initial Version |
 -- +====================================================================+
 -- +====================================================================+
 -- | Name :VERIFY_PO                                                    |
 -- |                                                                    |
 -- | Description : The Sales Tax value for a PO is calculated by Taxware|
 -- |               Concurrent program. This procedure determines whether| 
 -- |               the concurrent program should be called or not based |
 -- |               on the PO Type and PO subtype. Taxware Program is    |
 -- |               called for Standard Purchase Orders and Blanket      |
 -- |               Releases.                                            |
 -- |                                                                    |
 -- | Parameters :  itemtype,itemkey,actid,funcmode,resultout            |
 -- +====================================================================+

   PROCEDURE VERIFY_PO (
                         itemtype    IN         VARCHAR2
                        ,itemkey     IN         VARCHAR2
                        ,actid       IN         NUMBER
                        ,funcmode    IN         VARCHAR2
                        ,resultout   OUT NOCOPY VARCHAR2);

END  XX_WFL_POAPPRV_CAPT_TAX_PKG;
/

SHOW ERROR

SET SHOW         ON 
SET VERIFY       ON
SET ECHO         ON
SET TAB          ON
SET FEEDBACK     ON
SET TERM         ON


