        -- +==========================================================================+
        -- |                  Office Depot - Project Simplify                         |
        -- |                       WIPRO Technologies                                 |
        -- +==========================================================================+
        -- | SQL Script to create the Sequences                                       |
        -- | xx_fa_tax_interface_stg_bt_s1 - BATCH_ID of XX_FA_TAX_INTERFACE_STG      |
        -- | xx_fa_tax_interface_stg_ct_s1 - CONTROL_ID of XX_FA_TAX_INTERFACE_STG    |
        -- |                                                                          |
        -- |                                                                          |
        -- |SQL Script to create the Synonyms for the Sequences                       |
        -- |    xx_fa_tax_interface_stg_bt_s1,xx_fa_tax_interface_stg_ct_s1           |
        -- |Change Record:                                                            |
        -- |===============                                                           |
        -- |Version   Date         Author               Remarks                       |
        -- |=======   ==========   =============        ==============================|
        -- | 1.0      15-FEB-2007  Amaresh Rath        Initial version                |
        -- +==========================================================================+
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     ON

DROP   SEQUENCE xxfin.xx_fa_tax_interface_stg_bt_s1;
CREATE SEQUENCE xxfin.xx_fa_tax_interface_stg_bt_s1 START WITH 1 INCREMENT BY 1;

DROP   SEQUENCE xxfin.xx_fa_tax_interface_stg_ct_s1;
CREATE SEQUENCE xxfin.xx_fa_tax_interface_stg_ct_s1 START WITH 1 INCREMENT BY 1;

DROP   SYNONYM xx_fa_tax_interface_stg_bt_s1;
CREATE SYNONYM xx_fa_tax_interface_stg_bt_s1 FOR xxfin.xx_fa_tax_interface_stg_bt_s1;

DROP   SYNONYM xx_fa_tax_interface_stg_ct_s1;
CREATE SYNONYM xx_fa_tax_interface_stg_ct_s1  FOR xxfin.xx_fa_tax_interface_stg_ct_s1 ;

SHOW ERROR