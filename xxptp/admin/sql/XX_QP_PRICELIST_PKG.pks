SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_QP_PRICELIST_PKG AUTHID CURRENT_USER
-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |      Oracle NAIO/WIPRO/Office Depot/Consulting Organization       |
-- +===================================================================+
-- | Name        :  XX_QP_PRICELIST_PKG.pks                            |
-- | Description :  This package is used to Create,update and Delete   |
-- |                Price List.                                        |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |Draft 1a  24-May-2007 Madhukar Salunke Initial draft version       |
-- |Draft 1b  29-May-2007 Madhukar Salunke Updated after peer review   |
-- +===================================================================+
IS

TYPE Od_Price_List_Rec_Type IS RECORD
   (   operatingunit        VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   operationh           VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   operationl           VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   operationa           VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   name                 VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   description          VARCHAR2(2000) := FND_API.G_MISS_CHAR
   ,   currency_code        VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   rounding_factor      NUMBER         := FND_API.G_MISS_NUM
   ,   active_flag          VARCHAR2(1)    := FND_API.G_MISS_CHAR
   ,   attribute6           VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   attribute7           VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   languageh            VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   product_attr_value   VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   start_date_activeh   DATE           := FND_API.G_MISS_DATE
   ,   end_date_activeh     DATE           := FND_API.G_MISS_DATE
   ,   start_date_activel   DATE           := FND_API.G_MISS_DATE
   ,   end_date_activel     DATE           := FND_API.G_MISS_DATE
   ,   operand              NUMBER         := FND_API.G_MISS_NUM
   ,   product_uom_code     VARCHAR2(3)    := FND_API.G_MISS_CHAR
   ,   multi_unit1          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit2          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit3          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit4          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit5          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit6          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit7          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit8          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit9          VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit10         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit11         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit12         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit13         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit14         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit15         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit16         VARCHAR2(240)  := FND_API.G_MISS_CHAR
   ,   multi_unit_rtl1      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl2      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl3      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl4      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl5      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl6      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl7      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl8      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl9      NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl10     NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl11     NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl12     NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl13     NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl14     NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl15     NUMBER         := FND_API.G_MISS_NUM
   ,   multi_unit_rtl16     NUMBER         := FND_API.G_MISS_NUM
   ,   product_precedence   NUMBER         := FND_API.G_MISS_NUM
   ,   publishstatuscode    VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   creation_date        DATE           := FND_API.G_MISS_DATE
   ,   sourceapplid         VARCHAR2(30)   := FND_API.G_MISS_CHAR
   ,   price_by_formula_id  NUMBER         := FND_API.G_MISS_NUM
   );

-- ----------------------------------------
-- Global constants used for error handling
-- ----------------------------------------
   G_PROG_NAME              CONSTANT VARCHAR2(50)  := 'XX_QP_PRICELIST_PKG.CREATE_PRICELIST_MAIN';
   G_MODULE_NAME            CONSTANT VARCHAR2(50)  := 'QP';
   G_PROG_TYPE              CONSTANT VARCHAR2(50)  := 'CUSTOM API';
   G_NOTIFY                 CONSTANT VARCHAR2(1)   := 'Y';

--+=======================================================================================+
--| PROCEDURE  : create_pricelist_main                                                    |
--| P_Od_Price_List_Rec_Type IN    Od_Price_List_Rec_Type    Price list attribute details |
--| x_message_data         OUT   VARCHAR2                                                 |
--| Description :  This procedures is used to Create,update and Delete Price List.        |
--+=======================================================================================+
PROCEDURE create_pricelist_main(
          P_Od_Price_List_Rec_Type    IN    Od_Price_List_Rec_Type
         ,x_message_data              OUT   VARCHAR2
          );

END XX_QP_PRICELIST_PKG;
/
SHOW ERRORS;
EXIT;
-- --------------------------------------------------------------------------------
-- +==============================================================================+
-- |                         End of Script                                        |
-- +==============================================================================+
-- --------------------------------------------------------------------------------

