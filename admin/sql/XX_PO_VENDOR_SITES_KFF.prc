/*
declare
cursor col_cur is
select *
from dba_tab_columns
where table_name = 'XX_PO_VENDOR_SITES_KFF';
begin
for col_rec in col_cur loop
ad_dd.delete_column( p_appl_short_name => 'XXFIN',
p_tab_name =>'XX_PO_VENDOR_SITES_KFF',
p_col_name => col_rec.column_name);
end loop;
ad_dd.delete_table( p_appl_short_name => 'XXFIN',
p_tab_name => 'XX_PO_VENDOR_SITES_KFF');
commit;
end;
*/

declare
cursor col_cur is
select *
from dba_tab_columns
where table_name = 'XX_PO_VENDOR_SITES_KFF';
--Added next 3 lines for table extension
--and   column_name like 'SEG%'
--and   (column_name > 'SEGMENT60' or column_name like '%100')
--and   length(column_name) > 8;
begin
ad_dd.register_table( p_appl_short_name => 'XXFIN',
p_tab_name => 'XX_PO_VENDOR_SITES_KFF',
p_tab_type => 'T' );
for col_rec in col_cur loop
ad_dd.register_column( p_appl_short_name => 'XXFIN',
p_tab_name =>'XX_PO_VENDOR_SITES_KFF',
p_col_name => col_rec.column_name,
p_col_seq => col_rec.column_id,
p_col_type => col_rec.data_type,
p_col_width => col_rec.data_length,
p_nullable => col_rec.nullable,
p_translate => 'N',
p_precision => col_rec.data_precision,
p_scale => col_rec.data_scale );
end loop;
commit;
end;
/
