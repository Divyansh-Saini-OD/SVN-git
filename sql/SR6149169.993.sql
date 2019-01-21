update fnd_lookup_types
set CUSTOMIZATION_LEVEL = 'U'
where LOOKUP_TYPE = 'ARTAXVDR_LOC_QUALIFIER'
and APPLICATION_ID = 222;
commit