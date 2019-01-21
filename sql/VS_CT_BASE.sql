REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    :                                                                            |--
--|                                                                                             |--
--| Program Name   : VS_CT_BASE.sql                                                             |--        
--|                                                                                             |--   
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              23-Apr-2008       Nabarun Ghosh           Initial version                  |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script VS_CT_BASE....
PROMPT

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_WORD_REPLACEMENTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_DICTIONARY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_INTERFACE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCT_SITES_ALL_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ADAPTER_TERRITORIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_ADDRESSUSES_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEOGRAPHY_IDENTIFIERS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CONTACTPTS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEOGRAPHY_RANGES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SRCH_CONTACTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEO_STRUCT_MAP hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CONTACTROLES_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CONTACTS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEO_STRUCT_MAP_DTL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_DUP_DETAILS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_ERRORS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOCATION_PROFILES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_INTERFACE_ERRORS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TIMEZONES_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TIMEZONES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PHONE_AREA_CODES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_MERGE_LOG_DICT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_RELATIONSHIP_TYPES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PHONE_COUNTRY_CODES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_INDUSTRIAL_CLASS_APP hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLE_FMT_LAYOUTS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ADAPTERS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLES_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_ENTITIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_GROUPS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLE_FMT_VARIATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLE_FORMATS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_GROUPS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLE_FMT_LOCALES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */'HZ_STYLE_FMT_LOCALES',  count(*) from  apps.HZ_WORD_LISTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_CRITERIA hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_SCHEME_FUNCTIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLE_FMT_LAYOUTS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CLASS_CATEGORIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CLASS_CATEGORY_USES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_SECURED_ENTITIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SELECT_DATA_SOURCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLE_FORMATS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DQM_SYNC_INTERFACE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ENTITY_ATTRIBUTES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STYLES_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_PARTY_DETAILS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SRCH_PSITES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_DUP_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FINANCIAL_REPORTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FINANCIAL_PROFILE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_EMPLOYMENT_HISTORY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_PARTIES_SUGG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_ENTITY_ATTRIBUTES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_HIERARCHY_NODES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOCATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_TMP_REL_END_DATE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEOGRAPHIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_ADAPTERS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_BATCH_DETAILS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_BATCH_SUMMARY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FINANCIAL_NUMBERS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_SET_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_MERGE_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_EDUCATION hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_SETS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DSS_ASSIGNMENTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_BATCH hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CLASSIFICS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_INDUSTRIAL_REFERENCE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUSTOMER_PROFILES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SUSPENSION_ACTIVITY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_PROFILE_AMTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_CONTACT_ROLES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORGANIZATION_INDICATORS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_CONTACTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_PREFERENCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PERSON_LANGUAGE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITE_USES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PERSON_PROFILES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STAGED_CONTACT_POINTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STAGED_PARTY_SITES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_RELATIONSHIPS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PERSON_INTEREST hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_TMP_ERRORS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SRCH_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_PROF_CLASS_AMTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_USAGE_RULE_SETS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PRIMARY_TRANS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_USAGE_RULE_SETS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCT_RELATE_ALL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SRCH_CPTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCOUNTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_CONTACT_POINTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCH_RULE_PRIMARY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCH_RULES_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCH_RULES_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_PARTYDTLS_SUGG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_WORD_RPL_CONDS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_WORD_RPL_COND_ATTRIBS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_NON_PURGE_CANDIDATES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DQM_STAGE_LOG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCOUNTS_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_PARTY_LOG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PHONE_FORMATS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_THIRDPARTY_RULE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_PARTY_HISTORY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_USER_OVERWRITE_RULES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_USER_CREATE_RULES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUSTOMER_PROFILES_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DNB_REQUEST_LOG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_PROFILE_AMTS_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CONTACT_RESTRICTIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOG2 hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MOBILE_PREFIXES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_SITE_USES_ALL_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUSTOMER_MERGE_LOG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCOUNT_ROLES_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCT_RELATE_ALL_M hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_EXT_DATA_RULES_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_REG_VERIFICATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_WORK_CLASS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_WIN_SOURCE_EXCEPS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TIMEZONE_MAPPING hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_THIRDPARTY_EXCEPS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STOCK_MARKETS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PURGE_CANDIDATES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PURGE_BATCHES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARAM_TAB hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STAGED_CONTACTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCH_RULE_SECONDARY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_EMAIL_DOMAINS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_WORK_UNITS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ADAPTER_LOGS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SECURITY_ISSUED hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_REGISTRATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_REFERENCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORIG_SYS_MAPPING hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_USAGE_RULES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_USAGES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_SITE_USES_ALL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCOUNT_ROLES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CLASS_CODE_DENORM hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_PROFILE_AMTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_PROFILES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_INDUSTRIAL_CLASSES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEO_STRUCTURE_LEVELS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ROLE_RESPONSIBILITY hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MERGE_BATCH hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOC_ASSIGNMENTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_MATCH_DETAILS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_EXCLUSIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_PARTIES_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_RELSHIPS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_OSR_CHANGE hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEO_NAME_REFERENCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_BILLING_PREFERENCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CONTACT_POINTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CERTIFICATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CONTACT_PREFERENCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CITIZENSHIP hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_STAGED_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_WORD_RPL_CONDS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORIG_SYS_REFERENCES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TRANS_FUNCTIONS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TRANS_FUNCTIONS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_SECONDARY_TRANS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_FINNUMBERS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEO_NAME_REFERENCE_LOG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_RESULTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_INT_DUP_RESULTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_RATINGS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_INT_DEDUP_RESULTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TRANS_ATTRIBUTES_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CREDITRTNGS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEOGRAPHY_TYPES_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_FINREPORTS_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GEOGRAPHY_TYPES_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_RELATIONSHIPS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CLASS_CODE_RELATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_ADDRESSES_INT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORGANIZATION_PROFILES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCT_SITES_ALL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CODE_ASSIGNMENTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_TRANS_ATTRIBUTES_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_PROFILE_CLASSES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_PROFILES_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_PROFILES_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PER_PROFILES_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITE_USES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PER_PROFILES_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOCATIONS_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCH_RULE_CONDITIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOCATIONS_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DL_SELECTED_CRITERIA hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITES_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITES_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_RATINGS_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CREDIT_RATINGS_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FIN_REPORTS_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FIN_REPORTS_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FIN_NUMBERS_EXT_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_FIN_NUMBERS_EXT_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_PROFILES_EXT_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PER_PROFILES_EXT_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORIG_SYSTEMS_B hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORIG_SYSTEMS_TL hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_HIERARCHY_NODES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOCATIONS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CUST_ACCOUNTS hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTIES hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_BANK_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_CONTACT_POINT_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_USER_ORG_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PURGE_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_APPLICATION_TRANS_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DQM_SYNC_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCHED_PARTIES_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCHED_PARTY_SITES_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCHED_CONTACTS_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_MATCHED_CPTS_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SCORE_DTLS_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DQM_PARTIES_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DQM_DETAILS_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DQM_STAGE_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_GROUP_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_LOCATION_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_CONTACT_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_ORG_PROFILE_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_SITE_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_PARTY_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_RELATIONSHIP_VAL_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_DUP_WORKER_CHUNK_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_INT_DUP_RESULTS_GT hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_PARTIES_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_ADDRESSES_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CONTACTPTS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CREDITRTNGS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CLASSIFICS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_FINREPORTS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_FINNUMBERS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_RELSHIPS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CONTACTS_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_CONTACTROLES_SG hz;

select /*+ FULL(hz) PARALLEL(hz, 8) */ count(*) from  apps.HZ_IMP_ADDRESSUSES_SG hz;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
