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
-- | Name        : XX_VALIDATE_SCRIPT22-33.sql                               |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 22 throught 33 .... 
PROMPT

    select count(*) from fa_mass_additions;
    select count(*), substr(attribute6,1,4) comp_code from fa_mass_additions group by substr(attribute6,1,4);
    select count(*), stg.calc_asset_category_segments from fa_additions_b fab, xx_fa_mass_additions_stg stg where fab.attribute10 = stg.attribute10 group by stg.calc_asset_category_segments;
    select sum(fixed_assets_cost) from fa_mass_additions;
    select sum(fixed_assets_cost), substr(attribute10,10,4) from fa_mass_additions group by substr(attribute10,10,4);
    select sum(fixed_assets_cost), substr(attribute6,6,4) from fa_mass_additions group by substr(attribute6,6,4);
    select sum(ytd_deprn) from fa_mass_additions;
    select sum(ytd_deprn), substr(attribute6,1,4) from fa_mass_additions group by substr(attribute6,1,4);
    select sum(ytd_deprn), substr(attribute6,6,4) from fa_mass_additions group by substr(attribute6,6,4);
    select sum(deprn_reserve) from fa_mass_additions;
    select sum(deprn_reserve), substr(attribute6,1,4) from fa_mass_additions group by substr(attribute6,1,4);
    select sum(deprn_reserve), substr(attribute6,6,4) from fa_mass_additions group by substr(attribute6,6,4);

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
