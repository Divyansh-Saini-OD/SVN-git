SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_QP_MODIFIERS_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name        :  XX_QP_MODIFIERS_PKG.pks                            |
-- | Description :  This package is used to Create,update and Delete   |
-- |                Price List.                                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft 1a  19-Apr-2007 Fajna K.P        Initial draft version       |
-- |Draft 1b  19-Jul-2007 Madhukar Salunke Added LOG_ERROR procedure   |
-- |                                       for EBS Error Handling      | 
-- +===================================================================+
IS

-- ----------------------------------------
-- Global constants used for error handling
-- ----------------------------------------
G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_QP_MODIFIERS_PKG.CREATE_MODIFIER_MAIN';
G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'QP';
G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'Y';
G_MAJOR                  CONSTANT VARCHAR2(15)  := 'MAJOR';
G_MINOR                  CONSTANT VARCHAR2(15)  := 'MINOR';

--+=============================================================================================================+
--| PROCEDURE  : create_modifier_main                                                                        |
--| P_modifier_header      IN    QP_MODIFIERS_PUB.modifier_list_rec_type      Modifier header details           |
--| P_modifier_lines       IN    QP_MODIFIERS_PUB.modifiers_tbl_type          Modifier lines details            |
--| P_modifier_attributes  IN    QP_QUALIFIER_RULES_PUB.qualifiers_tbl_type   Modifier attribute details        |
--| P_modifier_qualifiers  IN    QP_MODIFIERS_PUB.pricing_attr_tbl_type       Modifier qualifier details        |
--| x_message_code         OUT   NUMBER                                                                         |
--| x_message_data         OUT   VARCHAR2                                                                       |
--+=============================================================================================================+

PROCEDURE create_modifier_main(
                               P_modifier_header_rec      IN    QP_MODIFIERS_PUB.modifier_list_rec_type,
                               P_modifier_lines_tbl       IN    QP_MODIFIERS_PUB.modifiers_tbl_type ,
                               P_modifier_attributes_tbl  IN    QP_MODIFIERS_PUB.Pricing_Attr_Tbl_Type,
                               P_modifier_qualifiers_tbl  IN    QP_QUALIFIER_RULES_PUB.qualifiers_tbl_type,
                               x_message_code             OUT   NUMBER,
                               x_message_data             OUT   VARCHAR2
                              );

END xx_qp_modifiers_pkg;
/
SHOW ERRORS;
--EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------