 -- +=================================================================================+
 -- |                  Office Depot - Project Simplify                                |
 -- |    Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
 -- +=================================================================================+
 -- | Name  :      XXOMHDRKFFDFFREG.sql                                               |
 -- | Description: Table registration script for KFF and DFF                          |
 -- |                                                                                 |
 -- |                                                                                 |
 -- |                                                                                 |
 -- |Change Record:                                                                   |
 -- |===============                                                                  |
 -- |Version   Date          Author              Remarks                              |
 -- |=======   ==========  =============    ==========================================|
 -- |1.0       17-APR-2007   Sandeep Gorla  Initial draft Version                     |
 -- +=================================================================================+


SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;



DECLARE
   CURSOR col_cur is
   SELECT *
   FROM dba_tab_columns
   WHERE table_name = 'XX_OM_HEADERS_ATTRIBUTES_ALL';

BEGIN
   ad_dd.register_table( p_appl_short_name => 'XXOM',
                                 p_tab_name => 'XX_OM_HEADERS_ATTRIBUTES_ALL',
                                 p_tab_type => 'T' );

   for col_rec in col_cur loop
   ad_dd.register_column( p_appl_short_name => 'XXOM',
                                   p_tab_name =>'XX_OM_HEADERS_ATTRIBUTES_ALL',
                                   p_col_name => col_rec.column_name,
                                   p_col_seq => col_rec.column_id,
                                   p_col_type => col_rec.data_type,
                                   p_col_width => col_rec.data_length,
                                   p_nullable => col_rec.nullable,
                                   p_translate => 'N',
                                   p_precision => col_rec.data_precision,
                                   p_scale => col_rec.data_scale );
    end loop;
COMMIT;
END;
/
show errors;