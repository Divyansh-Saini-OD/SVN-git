create or replace
PACKAGE xx_ce_cc_common_pkg
AS
-- +=================================================================================+
-- |                       Office Depot - Project Simplify                           |
-- |                                                                                 |
-- +=================================================================================+
-- | Name       : xx_ce_cc_common_pkg.pks                                            |
-- | Description: Common package for procedures called by multiple XX_CE_CC packages.|
-- |                                                                                 |
-- |                                                                                 |
-- |Change Record                                                                    |
-- |==============                                                                   |
-- |Version   Date         Authors            Remarks                                |
-- |========  ===========  ===============    ============================           |
-- |  1.0     2011-03-04   Joe Klein          New package copied from E1310 to       |
-- |                                          create separate package for the        |
-- |                                          common procedures used by other        |
-- |                                          XX_CE_CC packages.                     |
-- |                                                                                 |                                                                                     |
-- +=================================================================================+
-- | Name        : GET_DEFAULT_CARD_TYPE                                             |
-- | Description : This function returns the credit card type based on the           |
-- |               processor_id (provider).                                          |
-- |                                                                                 |
-- +=================================================================================+
FUNCTION get_default_card_type
           ( p_processor_id IN VARCHAR2
            ,p_org_id       IN NUMBER    --Added for Defect #1061
           ) RETURN VARCHAR2;


-- +=================================================================================+
-- | Name        : OD_MESSAGE                                                        |
-- | Description : This procedure will be used to create generic message to the      |
-- |               concurrent program's output, log, and error log.                  |
-- |                                                                                 |
-- +=================================================================================+
PROCEDURE od_message 
           ( p_msg_type         IN   VARCHAR2
            ,p_msg              IN   VARCHAR2
            ,p_msg_loc          IN   VARCHAR2 DEFAULT NULL
            ,p_addnl_line_len   IN   NUMBER DEFAULT 110
           );
           
           
END xx_ce_cc_common_pkg;

/
