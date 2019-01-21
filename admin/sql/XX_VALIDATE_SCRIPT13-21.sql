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
-- | Name        : XX_VALIDATE_SCRIPT13-20.sql                               |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 13 throught 20 .... 
PROMPT

    select count(*), process_flag from xx_fa_tax_interface_stg group by process_flag;
    select count(*), process_flag, company_code from xx_fa_tax_interface_stg group by process_flag, company_code;
    select count(*), process_flag, pwc_asset_class from xx_fa_tax_interface_stg group by process_flag, pwc_asset_class;
    select sum(pwc_initial_tax_cost) from xx_fa_tax_interface_stg;
    select sum(pwc_initial_tax_cost), calc_comp_code from xx_fa_tax_interface_stg group by calc_comp_code;
    select sum(pwc_initial_tax_cost), calc_class from xx_fa_tax_interface_stg group by calc_class;
    select abs(sum(pwc_accum_deprn)) from xx_fa_tax_interface_stg;
    select abs(sum(pwc_accum_deprn)), calc_comp_code from xx_fa_tax_interface_stg group by calc_comp_code;
    select abs(sum(pwc_accum_deprn)), calc_class from xx_fa_tax_interface_stg group by calc_class;

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
