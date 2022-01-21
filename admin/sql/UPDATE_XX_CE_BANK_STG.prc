-- +===========================================================================================+
-- |                  Office Depot - Project Simplify                                          |
-- +===========================================================================================+
-- | Name        : Update_XX_CE_BANK_STG                                           			   |
-- | Description : This Script is used to update Bank WebADI Tool staging table                |
-- |Change Record:                                                                             |
-- |===============                                                                            |
-- |Version   Date          Author                 Remarks                                     |
-- |=======   ==========   =============           ============================================|
-- |DRAFT 1.0 7-FEB-2018   Jitendra Atale          Bank WebADI Tool staging table updates      |
-- +===========================================================================================+
--Updating values in staging table XX_CE_BANK_STG

--update XX_CE_BANK_STG
--set CASH_CCID=21589735
--where BANK_NAME like 'Test%';

--update XX_CE_BANK_STG
--set COUNTRY_CODE = 'US', PROCESS_FLAG='Y',Branch_number='076401251',bank_branch_id=528879751
--where BANK_NAME='ABC Bank';

--update XX_CE_BANK_STG
--set PROCESS_FLAG='Y'
--where bank_id in(528964502);

--update XX_CE_BANK_STG
--set Currency='JPY'
--where bank_id=528964502 and agency_location_code='5343';

--update XX_CE_BANK_STG
--set bank_account_num='5422'
--where bank_id=528965232 and agency_location_code='00032322' and rownum=1;

--update bne_interface_cols_b
--set data_type=2
--where interface_code='OD_INT_BANK_XINTG_INTF1'
--and interface_col_name='P_AGENCY_LOCATION_CODE';

--update bne_interface_cols_b
--set data_type=2
--where interface_code='OD_INT_BANK_XINTG_INTF1'
--and interface_col_name='P_BANK_NUMBER';

--update bne_attributes 
--set attribute2='VARCHAR2'
--where attribute_code= 'OD_INT_BANK_XINTG_UPL1_A3';

--update bne_attributes
--set attribute2='VARCHAR2'
--where attribute_code='OD_INT_BANK_XINTG_UPL1_A15';

 
update bne_interface_cols_b
set data_type=2
where interface_code='OD_INT_BANK_XINTG_INTF1'
and interface_col_name='P_BANK_ERROR_CCID';

update bne_attributes 
set attribute2='VARCHAR2'
where attribute_code= 'OD_INT_BANK_XINTG_UPL1_A31';

update bne_interface_cols_b
set data_type=2
where interface_code='OD_INT_BANK_XINTG_INTF1'
and interface_col_name='P_BANK_CHARGES_CCID';

update bne_attributes 
set attribute2='VARCHAR2'
where attribute_code= 'OD_INT_BANK_XINTG_UPL1_A30';

update bne_interface_cols_b
set data_type=2
where interface_code='OD_INT_BANK_XINTG_INTF1'
and interface_col_name='P_CASH_CLEARING_CCID';

update bne_attributes 
set attribute2='VARCHAR2'
where attribute_code= 'OD_INT_BANK_XINTG_UPL1_A29';

update bne_interface_cols_b
set data_type=2
where interface_code='OD_INT_BANK_XINTG_INTF1'
and interface_col_name='P_CASH_CCID';

update bne_attributes 
set attribute2='VARCHAR2'
where attribute_code= 'OD_INT_BANK_XINTG_UPL1_A28';


commit;

Exit;