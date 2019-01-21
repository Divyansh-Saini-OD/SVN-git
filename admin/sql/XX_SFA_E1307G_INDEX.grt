create index xxcrm.xx_sfa_hz_parties_comp_n2 on ar.hz_parties(upper(duns_number_c),duns_number_c) nologging;
/
create index xxcrm.xx_sfa_hz_parties_comp_n3 on ar.hz_parties(upper(url),url) nologging;
/
create index xxcrm.xx_sfa_hz_parties_comp_n4 on ar.hz_parties(upper(jgzz_fiscal_code),jgzz_fiscal_code) nologging;
/
create index xxcrm.xx_sfa_hz_parties_comp_n5 on ar.hz_parties(upper(sic_code_type),sic_code_type) nologging;
/
create index xxcrm.xx_sfa_hz_parties_comp_n6 on ar.hz_parties(upper(sic_code),sic_code) nologging;
/
create index xxcrm.xx_sfa_hz_parties_comp_n7 on ar.hz_parties(category_code) nologging;
/
create index xxcrm.xx_sfa_hz_locations_comp_n1 on ar.hz_locations(UPPER(city),city) nologging;
/
create index xxcrm.xx_sfa_hz_locations_comp_n2 on ar.hz_locations(UPPER(province),province) nologging;
/
create index xxcrm.xx_sfa_hz_locations_comp_n3 on ar.hz_locations(UPPER(postal_code),postal_code) nologging;
/
create index xxcrm.xx_sfa_hz_locations_comp_n4 on ar.hz_locations(UPPER(country),country) nologging;
/
create index xxcrm.xx_sfa_hz_locations_comp_n5 on ar.hz_locations(UPPER(state),state) nologging;
/
create index xxcrm.xx_sfa_hz_cust_acct_comp_n1 on hz_cust_accounts(upper(attribute18),attribute18) nologging;
/