REM================================================================================================
REM                                 Start Of Script
REM================================================================================================
SET SHOW         OFF
SET VERIFY       OFF
SET ECHO         OFF
SET TAB          OFF
SET FEEDBACK     OFF
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +=========================================================================+
-- |               Office Depot - Project Simplify                           |
-- +=========================================================================+
-- | Name        : XX_VALIDATE_SCRIPT34-42.sql                               |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 34 throught 42 .... 
PROMPT

    select count(*) from fa_tax_interface;
    select count(fab.asset_number), substr(fab.attribute6,1,4) from fa_additions_b fab, fa_tax_interface fti where fab.asset_number = fti.asset_number group by substr(fab.attribute6,1,4);
    select count(*), stg.calc_asset_category_segments from fa_tax_interface fab, xx_fa_mass_additions_stg stg where fab.attribute10 = stg.attribute10 group by stg.calc_asset_category_segments;
    select sum(cost) from fa_tax_interface;
    select sum(fti.cost) , substr(stg.attribute10,10,4) from fa_tax_interface fti, fa_mass_additions stg where fti.asset_number = stg.asset_number group by substr(stg.attribute10,10,4);
    select sum(fti.cost) , substr(stg.attribute6,6,4) from fa_tax_interface fti, fa_mass_additions stg where fti.asset_number = stg.asset_number group by substr(stg.attribute6,6,4);
    select sum(deprn_reserve) from fa_tax_interface;
    select sum(fti.deprn_reserve), substr(fab.attribute6,1,4) from fa_additions_b fab, fa_tax_interface fti where fab.asset_number = fti.asset_number group by substr(fab.attribute6,1,4);
    select sum(fti.deprn_reserve), substr(fab.attribute6,6,4) from fa_additions_b fab, fa_tax_interface fti where fab.asset_number = fti.asset_number group by substr(fab.attribute6,6,4);

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
