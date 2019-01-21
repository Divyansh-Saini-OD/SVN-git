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
-- | Name        : XX_VALIDATE_SCRIPT1-6S.sql                                |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 1 throught 6 .... 
PROMPT

    select company_code, cost_center, class, asset_number, description, calc_fixed_assets_cost, deprn_reserve, ytd_deprn, date_placed_in_service, calc_life_in_months  from xx_fa_mass_additions_stg where deprn_reserve > calc_fixed_assets_cost;
    select company_code, cost_center, class, asset_number, description, calc_fixed_assets_cost, deprn_reserve, ytd_deprn, date_placed_in_service, calc_life_in_months  from xx_fa_mass_additions_stg where ytd_deprn > calc_fixed_assets_cost;
    select company_code, cost_center, class, asset_number, description, calc_fixed_assets_cost, deprn_reserve, ytd_deprn, date_placed_in_service, calc_life_in_months  from xx_fa_mass_additions_stg where deprn_reserve >= ytd_deprn;
    select company_code, cost_center, class, asset_number, description, calc_fixed_assets_cost, deprn_reserve, ytd_deprn, date_placed_in_service, calc_life_in_months  from xx_fa_mass_additions_stg where asset_in_pwc != 'Y';
    select * from xx_fa_mass_additions where error_message is not null;
    select pwc_asset_nbr, pwc_rate, pwc_life, pwc_in_service_date  
from xx_fa_tax_interface_stg where asset_in_sap != 'Y';

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
