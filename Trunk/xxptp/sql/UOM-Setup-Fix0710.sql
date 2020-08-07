-- Please find below script to make 2 UOMs OBSOLETE and fix UOM Code for 3 UOMs in 3 Tables
-- 	These 2 UOMs will have to be manually defined again if needed, with correct attributes after the script is run.
-- 	This script does not create setups, it labels existing setup for the 3 UOMs as obsolete and corrects the UOM code for 3 UOMs that are CAR -> CT, CA -> CN and CAS -> CA.
-- 	This fix is not meant for a Production instance, please use this script only in a development or test instance.
-- 	We advise to take backup of the instance prior to running this script if that instance contains large amounts of items or transactional data.

-- Run Query Below Prior to executing the script:
select unit_of_measure, uom_code, uom_class, base_uom_flag, unit_of_measure_tl
from apps.mtl_units_of_measure_tl
where uom_code in ('XBK','CAS','CAR','CA','CT','CN','FT','~FT');

-- Expected Result:
-- UNIT_OF_MEASURE           UOM UOM_CLASS  B UNIT_OF_MEASURE_TL
-- ------------------------- --- ---------- - -------------------------
-- BK                        XBK PACK       N BK
-- Foot                      FT  Length     Y Foot
-- CAR                       CAR Quantity   N CARTON
-- CASE                      CAS Quantity   N CASE
-- CAN                       CA  Quantity   N CAN

-- Update Script Begins
update apps.mtl_units_of_measure_tl
set unit_of_measure = 'Foot-Obsolete'
  , unit_of_measure_tl = 'Foot-Obsolete'
  , uom_code = '~FT'
where uom_code = 'FT';
-- Expected Result – 1 row updated.

update apps.mtl_uom_conversions
set unit_of_measure = 'Foot-Obsolete'
  , uom_code = '~FT'
where uom_code = 'FT';
-- Expected Result – 1 row updated.

update apps.mtl_units_of_measure_tl
set unit_of_measure = 'BK-Obsolete'
  , unit_of_measure_tl = 'BK-Obsolete'
where uom_code = 'XBK';
-- Expected Result – 1 row updated.

update apps.mtl_uom_conversions
set unit_of_measure = 'BK-Obsolete'
where uom_code = 'XBK';
-- Expected Result – 0 row updated.

update apps.mtl_units_of_measure_tl
set uom_code = 'CT'
where uom_code = 'CAR';
-- Expected Result – 1 row updated.

update apps.mtl_uom_conversions
set uom_code = 'CT'
where uom_code = 'CAR';
-- Expected Result – 1 row updated.

update apps.mtl_system_items_b
set primary_uom_code = 'CT'
where primary_uom_code = 'CAR';
-- Expected Result – <several> row(s) updated.

update apps.mtl_units_of_measure_tl
set uom_code = 'CN'
where uom_code = 'CA';
-- Expected Result – 1 row updated.

update apps.mtl_uom_conversions
set uom_code = 'CN'
where uom_code = 'CA';
-- Expected Result – 1 row updated.

update apps.mtl_system_items_b
set primary_uom_code = 'CN'
where primary_uom_code = 'CA';
-- Expected Result – <several> row(s) updated.

update apps.mtl_units_of_measure_tl
set uom_code = 'CA'
where uom_code = 'CAS';
-- Expected Result – 1 row updated.

update apps.mtl_uom_conversions
set uom_code = 'CA'
where uom_code = 'CAS';
-- Expected Result – 1 row updated.

update apps.mtl_system_items_b
set primary_uom_code = 'CA'
where primary_uom_code = 'CAS';
-- Expected Result – <several> row(s) updated.

-- Update Script Ends

-- Run Query Below After executing the script:
select unit_of_measure, uom_code, uom_class, base_uom_flag, unit_of_measure_tl
from apps.mtl_units_of_measure_tl
where uom_code in ('XBK','CAS','CAR','CA','CT','CN','FT','~FT');


-- Expected Result:
-- UNIT_OF_MEASURE           UOM UOM_CLASS  B UNIT_OF_MEASURE_TL
-- ------------------------- --- ---------- - -------------------------
-- BK-Obsolete               XBK PACK       N BK-Obsolete
-- Foot-Obsolete             ~FT Length     Y Foot-Obsolete
-- CAR                       CT  Quantity   N CARTON
-- CASE                      CA  Quantity   N CASE
-- CAN                       CN  Quantity   N CAN

PROMPT Issue Commit if expected results match, OR Rollback if expected results do not match

