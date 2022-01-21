select d.entity_name, c.line_item_name, e.user_dim1_name, f.channel_name, g.company_name, 
       b.cal_period_name,  a.from_currency, a.to_currency, a.translated_rate, a.translated_amount,
	   a.last_update_date, a.last_updated_by
from gcs_historical_rates a,
     fem_cal_periods_tl b,
	 fem_ln_items_tl c,
	 fem_entities_tl d,
	 fem_user_dim1_tl e,
	 fem_channels_tl f,
	 fem_companies_tl g
where b.cal_period_id = a.cal_period_id
and c.line_item_id = a.line_item_id
and d.entity_id = a.entity_id
and e.user_dim1_id = a.user_dim1_id
and f.channel_id = a.channel_id	 
and g.company_id = a.intercompany_id
and c.line_item_name = '3011000'
and b.cal_period_name = 'SEP-06'


update gcs_historical_rates
set translated_rate = 1.2 

delete from gcs_historical_rates
where cal_period_id in
  (select cal_period_id
   from fem_cal_periods_tl
   where cal_period_name = 'JAN-06')

select * from fem_Balances

Insert into gcs.gcs_historical_rates
   (ENTITY_ID, HIERARCHY_ID, CAL_PERIOD_ID, FROM_CURRENCY, TO_CURRENCY, COMPANY_COST_CENTER_ORG_ID, CHANNEL_ID, LINE_ITEM_ID, INTERCOMPANY_ID, USER_DIM1_ID, USER_DIM2_ID, TRANSLATED_RATE, RATE_TYPE_CODE, UPDATE_FLAG, ACCOUNT_TYPE_CODE, STOP_ROLLFORWARD_FLAG, CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
 Values
   (162440, 10220, 24537640000000000000011300110021, 'EUR', 'USD', 159605, 159683, 45800, 159559, 162220, 159564, 1.3, 'H', 'N', 'EQUITY', 'N', sysdate, 1111, sysdate, 1111);

   
   
select * from gcs_translation_Rates   

select * from dba_tab_columns where table_name like 'GCS%' and column_name like '%EQUITY%'

select * from gcs_curr_treatments_tl where curr_treatment_name like '134%'

select * from gcs_curr_treatments_b where curr_treatment_id = 10142

update gcs_curr_treatments_b 
set equity_mode_code = 'PTD'
where curr_treatment_id = 10142
