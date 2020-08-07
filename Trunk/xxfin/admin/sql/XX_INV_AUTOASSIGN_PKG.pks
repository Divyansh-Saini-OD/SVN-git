SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating Package Specification XX_INV_AUTOASSIGN_PKG

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

CREATE OR REPLACE
PACKAGE XX_INV_AUTOASSIGN_PKG
AS
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name :        OD:INV Auto Assign Items                            |
-- | Description : To automatically assign the items to the            |
-- |                organization in organization group                 |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |1.0       05-FEB-2007  Gowri Shankar        Initial version        |
-- |1.1       09-NOV-2007  Radhika Raman        Modified for           |
-- |                                            Defect: 2591           |
-- |1.2       12-FEB-2008  Radhika Raman        Modified for Defect    |
-- |                                            4561                   |
-- |                                                                   |
-- +===================================================================+
-- +===================================================================+
-- | Name : PROCESS                                                    |
-- | Description : This Program automatically assigns the items to the |
-- | Inventory organization, to which it is not assigned previously    |
-- |                                                                   |
-- | Program "OD: INV Auto Assign Items".                              |
-- |                                                                   |
-- | Parameters : p_item_from, p_item_to, p_category_set_id            |
-- |  , p_org_group_id, p_item_status, p_organization_id               |
-- |                                                                   |
-- |   Returns  : x_error_buff,x_ret_code                              |
-- +===================================================================+

    PROCEDURE PROCESS(
        x_error_buff           OUT VARCHAR2
       ,x_ret_code             OUT NUMBER
       ,p_task_type            IN  NUMBER  -- defect 4561
       ,p_item_from            IN  VARCHAR2
       ,p_item_to              IN  VARCHAR2
       ,p_category_set_name    IN  VARCHAR2 -- Modified for defect 2591
       ,p_org_group_id         IN  NUMBER
       ,p_item_status          IN  VARCHAR2
       ,p_organization_id      IN  NUMBER);

    gc_concurrent_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;

END XX_INV_AUTOASSIGN_PKG;
/
SHOW ERROR