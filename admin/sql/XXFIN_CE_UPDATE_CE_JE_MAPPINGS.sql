-- This update script is to Update the ce_je_mappings reference_txt
-- This will update 10389 records.
UPDATE CE_JE_MAPPINGS
SET REFERENCE_TXT = 'Master Store Conc Clearing'
WHERE REFERENCE_TXT = 'Master Store Concentration Clearing';
-- This update script is to Update the ce_je_mappings reference_txt
-- This will update 7 records.
UPDATE CE_JE_MAPPINGS
SET REFERENCE_TXT = 'AmSav Store Deposit Clearing'
WHERE REFERENCE_TXT = 'American Savings Store Deposit Clearing';
-- This update script is to Update the ce_je_mappings reference_txt
-- This will update 8128 records.
UPDATE CE_JE_MAPPINGS
SET REFERENCE_TXT = 'Wach Conc Clearing'
WHERE REFERENCE_TXT = 'Wachovia Concentration Clearing';
-- This update script is to Update the ce_je_mappings reference_txt
-- This will update 3409 records.
UPDATE CE_JE_MAPPINGS
SET REFERENCE_TXT = 'BofA Store Deposit Clearing'
WHERE REFERENCE_TXT = 'Bank of America Store Deposit Clearing';
-- This update script is to Update the ce_je_mappings reference_txt
-- This will update 1 record.
UPDATE CE_JE_MAPPINGS
SET REFERENCE_TXT = 'Master Store Conc Clearing'
WHERE REFERENCE_TXT = 'mASTER sTORE cONCENTRATION cLEARING';
COMMIT;
/