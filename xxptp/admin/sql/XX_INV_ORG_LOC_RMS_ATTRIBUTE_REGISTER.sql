/*=============================================================================+
|                                                                              |
| Program Name   : XX_INV_ORG_LOC_RMS_ATTRIBUTE_REGISTER.sql                   |
|                                                                              |
| Purpose        : To register the custom table XX_INV_ORG_LOC_RMS_ATTRIBUTE   |
|                  in apps                                                     |
| Change History  :                                                            |
| Ver   Date           Changed By           Description                        |
+==============================================================================+
| 1.0   22-OCT-2007    Ganesh B Nadakudhiti Initial Creation                   |
+=============================================================================*/
DECLARE
 CURSOR col_cur is
 SELECT *
   FROM dba_tab_columns
  WHERE table_name = 'XX_INV_ORG_LOC_RMS_ATTRIBUTE';

BEGIN
  AD_DD.register_table(p_appl_short_name => 'FND',
                       p_tab_name => 'XX_INV_ORG_LOC_RMS_ATTRIBUTE',
                       p_tab_type => 'T'
                      );

  FOR col_rec IN col_cur LOOP

    AD_DD.register_column(p_appl_short_name => 'FND',
                          p_tab_name =>'XX_INV_ORG_LOC_RMS_ATTRIBUTE',
                          p_col_name => col_rec.column_name,
                          p_col_seq => col_rec.column_id,
                          p_col_type => col_rec.data_type,
                          p_col_width => col_rec.data_length,
                          p_nullable => col_rec.nullable,
                          p_translate => 'N',
                          p_precision => col_rec.data_precision,
                          p_scale => col_rec.data_scale
                          );

  END LOOP;

COMMIT;

END ;
/