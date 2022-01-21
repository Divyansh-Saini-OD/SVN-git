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
-- | Name        : XX_VALIDATE_SCRIPT55-63.sql                               |
-- | Description : Error Scripts                                             |
-- |Change History:                                                          |
-- |---------------                                                          |
-- |                                                                         |
-- |Version  Date        Author             Remarks                          |
-- |-------  ----------- -----------------  ---------------------------------|
-- | 1.0     22-JAN-2015 Mark Schmit        Original                         |
-- +=========================================================================+

PROMPT
PROMPT Error scripts 55 throught 63 .... 
PROMPT

    select count(*), book_type_code from fa_books where last_update_date >= &conversion_date group by book_type_code;
    select count(*), substr(fab.attribute6,1,4), fb.book_type_code from fa_additions_b fab, fa_books fb where fab.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by substr(fab.attribute6,1,4), fb.book_type_code;
    select count(*), stg.calc_asset_category_segments, fb.book_type_code from fa_tax_interface fab, xx_fa_mass_additions_stg stg, fa_books fb where fab.attribute10 = stg.attribute10 and fab.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by stg.calc_asset_category_segments, fb.book_type_code;
    select sum(fb.cost), fb.book_type_code from fa_tax_interface fab, fa_books fb where fab.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by fb.book_type_code;
    select sum(fb.cost), substr(stg.attribute10,10,4), fb.book_type_code from fa_tax_interface fti, fa_mass_additions stg, fa_books fb where fti.asset_number = stg.asset_number  and fti.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by substr(stg.attribute10,10,4), fb.book_type_code;
    select sum(fb.cost), substr(stg.attribute6,6,4), fb.book_type_code from fa_tax_interface fti, fa_mass_additions stg, fa_books fb where fti.asset_number = stg.asset_number  and fti.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by substr(stg.attribute6,6,4), fb.book_type_code;
    select sum(fds.deprn_reserve), fb.book_type_code from fa_additions_b fab, fa.fa_deprn_detail fds, fa_books fb where fab.asset_id = fds.asset_id and fds.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by fb.book_type_code;

    select sum(fds.deprn_reserve), substr(fma.attribute6,1,4), fb.book_type_code from fa_additions_b fab, fa.fa_deprn_detail fds, fa_mass_additions fma, fa_books fb where fab.asset_id = fds.asset_id and fds.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by substr(fma.attribute6,1,4), fb.book_type_code;
    select sum(fds.deprn_reserve), substr(fma.attribute6,6,4), fb.book_type_code from fa_additions_b fab, fa.fa_deprn_detail fds, fa_mass_additions fma, fa_books fb where fab.asset_id = fds.asset_id and fds.asset_id = fb.asset_id and fab.creation_date >= &conversion_date group by substr(fma.attribute6,6,4), fb.book_type_code;

SHOW ERRORS;

REM================================================================================================
REM                                 End Of Script
REM================================================================================================
