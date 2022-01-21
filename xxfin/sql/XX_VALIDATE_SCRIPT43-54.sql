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
-- | Name        : XX_VALIDATE_SCRIPT43-54.sql                               |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 43 throught 54 .... 
PROMPT

    select count(*) from fa_additions_b where creation_date >= &conversion_date;
    select count(*), substr(attribute6,1,4) comp_code from fa_additions_b where creation_date >= &conversion_date group by substr(attribute6,1,4);
    select count(*), stg.calc_asset_category_segments from fa_additions_b fab, xx_fa_mass_additions_stg stg where fab.attribute10 = stg.attribute10 group by stg.calc_asset_category_segments;
    select sum(fixed_assets_cost) from fa_asset_invoices where creation_date >= &conversion_date;
    select sum(fai.fixed_assets_cost) , substr(stg.attribute10,10,4) from fa_additions_b fab, fa_asset_invoices fai, fa_mass_additions stg where fai.asset_id = fab.asset_id and fab.asset_number = stg.asset_number group by substr(stg.attribute10,10,4) and fab.creation_date >= &conversion_date;
    select sum(fti.cost) , substr(stg.attribute6,6,4) from fa_tax_interface fti, fa_mass_additions stg where fti.asset_number = stg.asset_number group by substr(stg.attribute6,6,4), fti.creation_date >= &conversion_date;
    select sum(fds.ytd_deprn) from fa_additions_b fab, fa.fa_deprn_summary fds where fab.asset_id = fds.asset_id and fab.creation_date >= &conversion_date;
    select sum(fds.ytd_deprn), substr(fma.attribute6,1,4) from fa_additions_b fab, fa.fa_deprn_summary fds, fa_mass_additions fma where fab.asset_id = fds.asset_id and fab.creation_date >= &conversion_date group by substr(fma.attribute6,1,4);
    select sum(fds.ytd_deprn), substr(fma.attribute6,6,4) from fa_additions_b fab, fa.fa_deprn_summary fds, fa_mass_additions fma where fab.asset_id = fds.asset_id and fab.creation_date >= &conversion_date group by substr(fma.attribute6,6,4);
    select sum(fds.deprn_reserve) from fa_additions_b fab, fa.fa_deprn_summary fds where fab.asset_id = fds.asset_id and fab.creation_date >= &conversion_date;
    select sum(fds.deprn_reserve), substr(fma.attribute6,1,4) from fa_additions_b fab, fa.fa_deprn_summary fds, fa_mass_additions fma where fab.asset_id = fds.asset_id and fab.creation_date >= &conversion_date group by substr(fma.attribute6,1,4);
    select sum(fds.deprn_reserve), substr(fma.attribute6,6,4) from fa_additions_b fab, fa.fa_deprn_summary fds, fa_mass_additions fma where fab.asset_id = fds.asset_id and fab.creation_date >= &conversion_date group by substr(fma.attribute6,6,4);

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
