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
-- | Name        : XX_VALIDATE_SCRIPT1-12.sql                                |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 1 throught 12 ....
PROMPT

    select count(*), process_flag from xx_fa_mass_additions_stg group by process_flag;
    select count(*), process_flag, company_code from xx_fa_mass_additions_stg group by process_flag, company_code;
    select count(*), process_flag, class from xx_fa_mass_additions_stg group by process_flag, class;
    select sum(calc_fixed_assets_cost) from xx_fa_mass_additions_stg;
    select sum(calc_fixed_assets_cost), company_code from xx_fa_mass_additions_stg group by company_code;
    select sum(calc_fixed_assets_cost), class from xx_fa_mass_additions_stg group by class;
    select abs(sum(ytd_deprn)) from xx_fa_mass_additions_stg;
    select abs(sum(ytd_deprn)), company_code from xx_fa_mass_additions_stg group by company_code;
    select abs(sum(ytd_deprn)), class from xx_fa_mass_additions_stg group by class;
    select abs(sum(deprn_reserve)) from xx_fa_mass_additions_stg;
    select abs(sum(deprn_reserve)), company_code from xx_fa_mass_additions_stg group by company_code;
    select abs(sum(deprn_reserve)), class from xx_fa_mass_additions_stg group by class;

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
