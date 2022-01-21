SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

PROMPT Creating Package Specification XX_FA_MASSCHANGE_PKG
PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE PACKAGE XX_FA_MASSCHANGE_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :  XX_FA_MASS_CHANGE                                         |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description :This package Spec is used to retrieve the values from|
-- |              fa_mass_changes tables once the data is saved in     |
-- |              Mass Changes form for the varying search criteria    |
-- |              which are Assets Range, Category,Location and        |
-- |              Accounting Date Range. The old depreciation value    |
-- |              will be checked(in fa_additions_b table) and if it is|
-- |              equal to the value mentioned in the Mass Changes form|
-- |              then the corresponding assets will have the new      |
-- |              depreciation value updated(the new value             |
-- |              is also mentioned in the form Mass Changes). The new |
-- |              values will be updated in the fa_tax_interface       |
-- |              table and the standard API will be called.           |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |Draft1A   10-JAN-2006  Pradeep Ramasamy,    Initial version        |
-- |                       Wipro Technologies                          |
-- |                                                                   |
-- |1.0       22-JUN-2007  Nandini Bhimana       Updated cursor for    |
-- |                        Boina,               Multiple selection    |
-- |                       Wipro Technologies    criteria              |
-- +===================================================================+
-- +===================================================================+
-- | Name : MASSCHANGE                                                 |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This Procedure is used to retrieve the              |
-- |               values from fa_mass_changes tables once the data is |
-- |               saved in Mass Changes form for the varying search   |
-- |               criteria which are Assets Range, Category, Location |
-- |               and Accounting Date Range.The old depreciation value|
-- |               will be checked and if it is equal to the value     |
-- |               mentioned in the Mass Changes form then the         |
-- |               corresponding assets will have the new depreciation |
-- |               value updated in fa_tax_interface table.            |
-- |                                                                   |
-- | Parameter  : p_mass_change_id                                     |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE MASSCHANGE(
                        p_mass_change_id  IN NUMBER
                        );

-- +===================================================================+
-- | Name : PREVIEW                                                    |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This Procedure is used to submit the preview        |
-- |               report which will preview the mass change report    |
-- |               once the data is saved in Mass Changes form for the |
-- |               varying search criteria which are Assets Range,     |
-- |               Category, Location and Accounting Date Range.       |
-- |               This procedure is the executable for the concurrent |
-- |               program OD: Mass Change Preview Report              |
-- |                                                                   |
-- | Parameter  : p_mass_transaction_id                                |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE PREVIEW(
                     p_mass_transaction_id IN VARCHAR2
                     );

-- +===================================================================+
-- | Name : REVIEW                                                     |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This Procedure is used to submit the review         |
-- |               report which will review the mass change report once|
-- |               the data is saved in Mass  Changes form for the     |
-- |               varying search criteria which are Assets Range,     |
-- |               Category,Location and Accounting Date Range         |
-- |               This procedure is the executable for the concurrent |
-- |               program OD: Mass Change Review Report               |
-- |                                                                   |
-- | Parameter  : p_mass_transaction_id                                |
-- |                                                                   |
-- +===================================================================+

    PROCEDURE REVIEW(
                    p_mass_transaction_id in VARCHAR2
                    );

-- +===================================================================+
-- | Name : GET_REQ_ID                                                 |
-- |                                                                   |
-- | Rice id : E0073                                                   |
-- |                                                                   |
-- | Description : This function is used to return the request id      |
-- |               of the concurrent program and reports.              |
-- |                                                                   |
-- | Returns : gn_req_id                                               |
-- +===================================================================+

    FUNCTION GET_REQ_ID RETURN NUMBER;

END XX_FA_MASSCHANGE_PKG;
/
SHOW ERROR

