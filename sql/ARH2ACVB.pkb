/*
 *  Copyright (c) 2001 Oracle Corporation Redwood Shores, California, USA
 *                          All rights reserved.
 *=======================================================================
 * FILE       ARH2ACVB.pls
 *
 * PACKAGE    HZ_ACCOUNT_VALIDATE_V2PUB
 *
 * DESCRIPTION
 *     This package contains public API to do validation for all of
 *     the entities in account level.
 *
 * RELATED PACKAGES
 *     HZ_CUST_ACCOUNT_V2PUB
 *     HZ_CUSTOEMR_PROFILE_V2PUB
 *     HZ_CUST_ACCOUNT_SITE_V2PUB
 *     HZ_CUST_ACCOUNT_ROLE_V2PUB
 *
 * PUBLIC VARIABLES
 *
 * PUBLIC PROCEDURES
 *     validate_cust_account
 *     validate_cust_acct_relate
 *     validate_customer_profile
 *     validate_cust_profile_amt
 *     validate_cust_acct_site
 *     validate_cust_site_use
 *     validate_cust_account_role
 *     validate_role_responsibility
 *
 * PUBLIC FUNCTIONS
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   08-07-2001    Jianying Huang      o Bug 1934845: Added parameter 'p_check_foreign_key'
 *                                       in 'validate_cust_profile_amt'.
 *   08-07-2001    Jianying Huang      o Before calling gl_id_xxx, should check if
 *                                       it is G_MISS_NUM instead of G_MISS_CHAR.
 *   08-08-2001    Jianying Huang      o Modified 'search' procedure to use 'OR'
 *                                       instead of 'AND' when checking enable_flag
 *                                       and start_date_active.
 *   08-13-2001    Jianying Huang      o Bug 1934845: Should skip the validation on site_use_id
 *                                       when 'p_check_foreign_key' is set to FALSE. 
 *   08-17-2001    Jianying Huang      o Updated validate_customer_profile. Added validation
 *                                       'profile_class_id' cannot be updated to NULL.
 *   09-05-2001    Jianying Huang      o Bug 1978307: Modified 'search' procedure to use 'AND'.
 *                                       Enabled_flag should always be 'Y' for active lookup code.
 *   09-17-2001    Jianying Huang      o Bug 1999718: site use code 'STMS' should be 'STMTS'.
 *   09-21-2001    Jianying Huang      o Bug 2009646: when create cust account site, check
 *                                       unique combination of cust_account_id+party_site_id
 *                                       against hz_cust_acct_sites instead of hz_cust_acct_sites_all
 *   11-08-2001    Rajeshwari P          Bug 1999742, 1999234 .
 *                                       Included the validation for fields, tax_code,invoice_quantity_rule,
 *                                       customer_class_code,tax_rounding_rule,primary_salesrep_id,
 *                                       order_type_id,price_list_id,ship_partial,fob_point ,
 *                                       item_cross_ref_pref,warehouse_id,date_type_preference,
 *                                       ship_sets_include_lines_flag and  arrivalsets_include_lines_flag
 *                                       in  procedure VALIDATE_CUST_ACCOUNT.
 *                                       
 *                                       Added validations  for fields, tax_code,payment_term_id,
 *                                       demand_class_code,primary_salesrep_id,finchrg_receivables_trx_id,
 *                                       order_type_id,order_type_id,ship_partial,item_cross_ref_pref,
 *                                       warehouse_id,date_type_preference,ship_sets_include_lines_flag
 *                                       and arrivalsets_include_lines_flag in procedure 
 *                                       VALIDATE_CUST_SITE_USE.
 *                         
 *                                       Added the lookup validation for lookup,
 *                                       FND_COMMON_LOOKUPS in procedure SEARCH.
 *               
 *                                       Added the following private procedures,
 *                                       check_tax_code,check_payterm_id_fk,
 *                                       check_prim_salesrep,check_finchrg_trx_fk
 *                                       check_ord_type,check_price_list_fk,
 *                                       check_item_cross_ref and check_warehouse.
 *  11-08-2001        P.Suresh           Bug No : 1999532. Validated the following profile fields 
 *                                       as done in customer standard form and interface.
 *                                       Added validations in the validate_customer_profile
 *                                       procedure for account_status,tolerence,percent_collectable,
 *                                       standard_terms,override_terms,discount_grace_days,
 *                                       lockbox_matching_option,autocash_hierarchy_id,
 *                                       autocash_hierarchy_id_for_adr,statement_cycle_id,
 *                                       dunning_letters,send_statements,interest_charges,
 *                                       discount_terms,clearing_days,payment_grace_days,
 *                                       statement_cycle_id,grouping_rule_id and
 *                                       tax_printing_option.
 *                                       Bug Fix : 2001573. Validated overall_credit_limit.
 *                                       It should be greater or equal to trx_credit_limit.  
 *  11-22-2001      Rajeshwari P         Bug No 2120539.Removed the check, AR_VAT_TAX.tax_type
 *                                       <> 'LOCATION' from the where clause of the select 
 *                                       statement in procedure, CHECK_TAX_CODE. 
 *  12-05-2001       P.Suresh            Bug No : 2125994. Commented the mandatory check
 *                                       on charge_on_finance_charge_flag when interest
 *                                       charge is 'Y'.
 *  01-31-2002       P.Suresh            Bug No : 2204789. Added the check for the status
 *                                       while validating cust_acct_site_id and site_use_code 
 *                                       together should be unique in validate_cust_site_use
 *                                       procedure.
 *  02-22-2002       P.Suresh            Bug No : 2229511. Changed the message name from
 *                                       HZ_API_VAL_MAND_DEP_FIELDS to HZ_API_MAND_DEP_FIELDS
 *                                       in validate_customer_profile procedure. 
 *  03-26-2002       P.Suresh            Bug No : 2266165. Added the check that bill_to_flag of
 *                                       hz_cust_acct_relate_all table should be Y when validating 
 *                                       bill_to_site_use_id.
 *  04-04-2002      Rajeshwari P         Bug 2183072. Handled the exception for 'Select from 
 *                                       ar_system_parameters'.                                
 *  04-11-2002       P.Suresh            Bug No : 2260832. Added the check for the status
 *                                       when validating that only one primary is allowed for
 *                                       one site use type per account in the procedure
 *                                       validate_cust_site_use.
 *  03-05-2002     Rashmi Goyal   Bug 2197181: Because of Mix-n-Match project, location from 3rd 
 *              party content providers can now be used in the business flow.
 *              Therefore, removing restriction that the "party_site_id must
 *              link to a 'USER_ENTERED' location".
 *  06-MAY-2002     Herve Yu             Bug No : 2310474 Credit Management
 *                                       Validate PERIODIC_REVIEW_CYCLE,
 *                                         PARTY_ID non-updateable in Update
 *                                         PARTY_ID mandatory in create
 *                                         Cust_account_id can be equal to -1
 *                                         Profile at site level => Cust_Account_id mandatory
 * 21-MAY-2002     Rajeshwari P          Bug fix 2311760.Commented the code which validates 
 *                                       Obsolete column ship_partial.
 *  06-13-2002      P.Suresh             Bug No : 2403263. Added validation that the contact_id
 *                                       should be a foreign key to hz_cust_account_roles.
 *                                       cust_account_role_id in validate_cust_site_use procedure.
 * 06-19-2002      Rajeshwari P          Bug 2399491.Validating site_use_id for duplicates
 *                                       against hz_cust_site_uses_all table instead of the
 *                                       org stripped view, hz_cust_site_uses in 
 *                                       validate_cust_site_use procedure.
 *  07-05-2002      P.Suresh             Bug No : 2447204. Truncated the start date and end date
 *                                       in the where clause of the lookup validation sqls in the
 *                                       search function.
 *  08-02-2002      Porkodi C            Bug No : 2248243. The query to select valid order type is 
 *                                       changed now. The where clause doesn't have the and check with 
 *                                       fnd_doc_sequence_categories table. And the parameter for 
 *                                       check_warehouse method is corrected to take warehouse_id.
 *  09-13-2002      P.Suresh             Bug No : 2441092. Added a condition that the discount_terms 
 *                                       should be 'Y' when defaulting the discount_grace_days from the 
 *                                       hz_cust_profile_classes in validate_customer_profile procedure.
 *  10-10-2002     Rajeshwari P          Bug No 2529143.Added validation for column 'Credit_Classification'
 *                                       in validate_customer_profile procedure.
 *  10-25-2002      P.Suresh             Bug No : 2528119. Added validation for ece_tp_location_code
 *                                       in validate_cust_acct_site procedure.
 *  11-15-2002    Seedhar Mohan          Bug No : 2553286. Changed the validation for gl_id_xxx fields
 *                                       in validate_cust_site_use procedure.
 *  11-20-2002    P.Suresh               Bug No : 2676848. Added NOCOPY hint for
 *                                       OUT and IN OUT parameters.
 *  11-26-2002    Seedhar Mohan          Bug No : 2262248. Commented out the if block in 
 *                                       check_oe_ship_methods_v_fk procedure. API should 
 *                                       NOT DISALLOW the specification of a value for 
 *                                       ship-via based on multi-org installation status 
 *                                       for ACOUNT and SITE USE levels.
 *  11-26-2002    Seedhar Mohan          Bug No : 2262616. In the procedure, check_price_list_fk,
 *                                       changed the query, which was looking at SO_PRICE_LISTS
 *                                       to query qp_list_headers_b with active_flag.
 *  02-27-2003   Rajeshwari P            Bug No:2792589. Set status = 'A' while validating primary_flag
 *                                       in validate_cust_site_use procedure.
 *  04-09-2003   Dylan Wan               Bug No : 2896116.  Validate the Credit_Classification against 
 *                                       AR_CMGT_CREDIT_CLASSIFICATION.
 *  05-26-2003   Ramesh Ch               Bug No:2441276. Added Validation to make 
 *                                       account_number as non updateable.
 *  05-30-2003   Ramesh Ch               Bug No : 2884220. Added a condition that the interest_charges 
 *                                       should be 'Y' when initializing the interest_period_days from 
 *              the hz_cust_profile_classes in validate_customer_profile procedure.
 *
 *  06-12-2003 Dhaval Mehta       Bug No : 2998504. Added a condition in where clause that the status
 *              should be 'A' in HZ_CUST_SITE_USES,  when validating the location for  
 *              uniqueness withn a customer account / site_use_type 
 *                                       in validate_cust_site_uses procedure.
 *
 *  06-23-2003  Ramesh Ch      Bug No : 2884220. Added a condition that the dunning_letters,send_statements 
 *                                       should be 'Y' when initializing the dunning_letter_set_id,statement_cycle_id resp
 *              from the hz_cust_profile_classes in validate_customer_profile procedure.
 *
 *  09-03-2003 Ramesh Ch       Bug No : 3125660.Restricted the site use code to BILL_TO/DUN/STMTS 
 *              while creating site level customer profiles in validate_customer_profile
 *              procedure.
 *  09-16-2003 Ramesh Ch       Bug No : 3125660.Commented the changes made to the previous version.
 *              Please ignore ARH2ACVB.pls 115.45.
 *  10-04-2003 Rajib Ranjan Borah        o Bug 2985448.In procedure validate_cust_acct_relate ,       
 *                                       only  active  relationships will  be considered  while 
 *                                       checking for duplicates.
 *
 *   12-18-2003   Pranav          o Bug 2643624.When a site use is created,it
 *                                       should be set as primary when there are no
 *                                       primary site uses already there.In case there
 *                                       are primary site uses and the primary flag is
 *                                       set to Y in this one, then this has to be set
 *                                       as primary after unsetting the previous one.
 *                                       To enable the above we have to remove the  .
 *                                       validation for primary site use.
 *   19-DEC-2003    Ramesh Ch.          o Commented out the g_debug,enable_debug,disable_debug & calls to hz_utility_pub's 
 *               debug & debug_return_messages and added code to call to 
 *               hz_utility_pub's debug & debug_return_messages as part of
 *               Common Logging Infrastructure uptake.
 *   25-FEB-2004    Rajib Ranjan Borah  o Bug 3439053.Modified procedure validate_nonupdateable.
 *                                        Handled the scenario where p_old_column_value = 
 *                                        FND_API.G_MISS_XXX during p_restricted = 'N'.
 *   18-May-2004    Rajib Ranjan Borah  o Bug 3591694.Modified procedure check_per_all_people_f_fk
 *                                        to consider effective_start_date and effective_end_date
 *                                        in PER_ALL_PEOPLE_F.
 *                                      o Modified validate_cust_acct_site. Called per_all_people_f_fk
 *                                        for secondary_specialist_id instead of check_cust_account_fk.
 *                                      o In procedure check_price_list_fk, passed QP_LIST_HEADERS_B
 *                                        instead of SO_PRICE_LISTS as token for COLUMN in 
 *                                        message HZ_API_INVALID_FK.
 *   03-May-2004    Venkata Sowjanya S    Bug No : 3609601. Commented the statements which sets tokens Column1,Column2
 *                                        for message HZ_API_INACTIVE_CANNOT_PRIM 
 *   26-NOV-2004    V.Ravichandran      o Bug 3969469. Modified the procedure validate_cust_account
 *                                        to allow update of account number if     
 *                                        AUTO_CUSTOMER_NUMBERING is OFF.             
 *   30-NOV-2004    V.Ravichandran      o Bug 3988537. Modified the procedure validate_cust_site_use
 *                                        to check if the site_use_type and cust_acct_site_id
 *                                        combination remains unique while updating an
 *                                        inactive account site use to be active.
 *   12-JAN-2005    Kalyan              o Bug 3877782. Added currency_flag, enabled_flag, start_date_active 
 *                                        and end_date_active in the where clause while checking in 
 *                                        fnd_currencies in 'check_currency_fk'
 *   02-MAR-2006    Idris Ali           o Bug 5073767: Replaced the parameter rowid with cust_acct_relate_id 
 *                                         in procedure validate_cust_acct_relate.
 */ 

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY HZ_ACCOUNT_VALIDATE_V2PUB AS
/*$Header: ARH2ACVB.pls 115.61 2006/12/13 00:50:53 awu ship $ */

--------------------------------------
-- declaration of private global varibles
--------------------------------------

G_DEBUG_COUNT                           NUMBER := 0;
--G_DEBUG                                 BOOLEAN := FALSE;

G_SPECIAL_STRING                        CONSTANT VARCHAR2(4):= '%#@*';
G_LENGTH                                CONSTANT NUMBER := LENGTHB( G_SPECIAL_STRING );

TYPE VAL_TAB_TYPE IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;

--------------------------------------
-- define the internal table that will cache values
--------------------------------------

VAL_TAB                                 VAL_TAB_TYPE;    -- the table of values
TABLE_SIZE                              BINARY_INTEGER := 2048; -- the size of above tables

--------------------------------------
-- declaration of private procedures and functions
--------------------------------------

/*PROCEDURE enable_debug;

PROCEDURE disable_debug;
*/


FUNCTION get_index (
    p_val                               IN     VARCHAR2
) RETURN BINARY_INTEGER;

PROCEDURE put (
    p_val                               IN     VARCHAR2
);

FUNCTION search (
    p_val                               IN     VARCHAR2,
    p_category                          IN     VARCHAR2
) RETURN BOOLEAN;

PROCEDURE validate_mandatory (
    p_create_update_flag                    IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    p_restricted                            IN     VARCHAR2 DEFAULT 'N',
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_mandatory (
    p_create_update_flag                    IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    p_restricted                            IN     VARCHAR2 DEFAULT 'N',
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_mandatory (
    p_create_update_flag                    IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     DATE,
    p_restricted                            IN     VARCHAR2 DEFAULT 'N',
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_nonupdateable (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    p_old_column_value                      IN     VARCHAR2,
    p_restricted                            IN     VARCHAR2 DEFAULT 'Y',
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_nonupdateable (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    p_old_column_value                      IN     NUMBER,
    p_restricted                            IN     VARCHAR2 DEFAULT 'Y',
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_nonupdateable (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     DATE,
    p_old_column_value                      IN     DATE,
    p_restricted                            IN     VARCHAR2 DEFAULT 'Y',
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_start_end_date (
    p_create_update_flag                    IN     VARCHAR2,
    p_start_date_column_name                IN     VARCHAR2,
    p_start_date                            IN     DATE,
    p_old_start_date                        IN     DATE,
    p_end_date_column_name                  IN     VARCHAR2,
    p_end_date                              IN     DATE,
    p_old_end_date                          IN     DATE,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_cannot_update_to_null (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_cannot_update_to_null (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_cannot_update_to_null (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     DATE,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_lookup (
    p_column                                IN     VARCHAR2,
    p_lookup_table                          IN     VARCHAR2 DEFAULT 'AR_LOOKUPS',
    p_lookup_type                           IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_cust_account_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_cust_acct_site_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_cust_site_use_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);
PROCEDURE check_cust_site_use_cont_fk(
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    p_customer_id                           IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);
PROCEDURE check_cust_account_role_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_per_all_people_f_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_collector_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_party_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_party_site_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_currency_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_oe_ship_methods_v_fk (
    p_entity                                IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_payterm_id_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_finchrg_trx_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_price_list_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_item_cross_ref(
          p_column                                IN     VARCHAR2,
          p_column_value                          IN     VARCHAR2,
          x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_warehouse(
          p_column                                IN     VARCHAR2,
          p_column_value                          IN     VARCHAR2,
          x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_ord_type(
        p_column                                IN     VARCHAR2,
        p_column_value                          IN     VARCHAR2,
        x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_prim_salesrep(
        p_column                                IN     VARCHAR2,
        p_column_value                          IN     VARCHAR2,
        x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_tax_code(
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_partial_mandatory_column (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_partial_mandatory_column (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE validate_gl_id (
    p_gl_name                               IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_auto_hierid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_stat_cycid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_dunning_letid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_standard_terms_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_grouping_ruleid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);

PROCEDURE check_positive_value (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);
PROCEDURE check_greater_than_zero (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
);
--------------------------------------
-- public procedures and functions
--------------------------------------

/**
 * PROCEDURE validate_cust_account
 *
 * DESCRIPTION
 *     Validates customer account record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_cust_account_rec             Customer account record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   11-08-2001    Rajeshwari P        Included the validation for fields, tax_code,
 *                                     invoice_quantity_rule,customer_class_code,
 *                                     tax_rounding_rule,primary_salesrep_id,
 *                                     order_type_id,price_list_id,ship_partial,fob_point ,
 *                                     item_cross_ref_pref,warehouse_id,date_type_preference,
 *                                     ship_sets_include_lines_flag and 
 *                                     arrivalsets_include_lines_flag in  procedure 
 *                                     VALIDATE_CUST_ACCOUNT.
 *  21-05-2002   Rajeshwari P          Bug fix 2311760.Commented the code which validates the
 *                                     Obsolete column ship_partial.
 *
 *  05-26-2003   Ramesh Ch               Bug No:2441276. Added Validation to make 
 *                                       account_number as non updateable.
 */

PROCEDURE validate_cust_account (
    p_create_update_flag                    IN     VARCHAR2,
    p_cust_account_rec                      IN     HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_cust_account'

    l_dummy                                 VARCHAR2(1);
    l_rowid                                 ROWID := NULL;
    l_profile                               AR_SYSTEM_PARAMETERS.generate_customer_number%TYPE;

    l_orig_system_reference HZ_CUST_ACCOUNTS.orig_system_reference%TYPE;
    l_orig_system_reference1                 HZ_CUST_ACCOUNTS.orig_system_reference%TYPE;
    l_account_established_date              HZ_CUST_ACCOUNTS.account_established_date%TYPE;
    l_account_termination_date              HZ_CUST_ACCOUNTS.account_termination_date%TYPE;
    l_account_activation_date               HZ_CUST_ACCOUNTS.account_activation_date%TYPE;
    l_created_by_module                     HZ_CUST_ACCOUNTS.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_status                                HZ_CUST_ACCOUNTS.status%TYPE;
    l_customer_type                         HZ_CUST_ACCOUNTS.customer_type%TYPE;
    l_sales_channel_code                    HZ_CUST_ACCOUNTS.sales_channel_code%TYPE;
    l_freight_term                          HZ_CUST_ACCOUNTS.freight_term%TYPE;
    l_ship_via                              HZ_CUST_ACCOUNTS.ship_via%TYPE;
    l_ship_sets_inc_lines_f                 HZ_CUST_ACCOUNTS.ship_sets_include_lines_flag%TYPE;
    l_arrivalsets_inc_lines_f               HZ_CUST_ACCOUNTS.arrivalsets_include_lines_flag%TYPE;
    l_tax_code                              HZ_CUST_ACCOUNTS.TAX_CODE%TYPE;
    l_invoice_quantity_rule                 HZ_CUST_ACCOUNTS.INVOICE_QUANTITY_RULE%TYPE;
    l_primary_salesrep_id                   HZ_CUST_ACCOUNTS.PRIMARY_SALESREP_ID%TYPE;
    l_order_type_id                         HZ_CUST_ACCOUNTS.ORDER_TYPE_ID%TYPE;
    l_price_list_id                         HZ_CUST_ACCOUNTS.PRICE_LIST_ID%TYPE;
--    l_ship_partial                          HZ_CUST_ACCOUNTS.SHIP_PARTIAL%TYPE;
    l_fob_point                             HZ_CUST_ACCOUNTS.FOB_POINT%TYPE;
    l_item_cross_ref_pref                   HZ_CUST_ACCOUNTS.ITEM_CROSS_REF_PREF%TYPE;
    l_warehouse_id                          HZ_CUST_ACCOUNTS.WAREHOUSE_ID%TYPE;
    l_date_type_preference                  HZ_CUST_ACCOUNTS.DATE_TYPE_PREFERENCE%TYPE;
    l_customer_class_code                   HZ_CUST_ACCOUNTS.CUSTOMER_CLASS_CODE%TYPE;
    l_tax_rounding_rule                     HZ_CUST_ACCOUNTS.TAX_ROUNDING_RULE%TYPE;
    l_account_number           HZ_CUST_ACCOUNTS.ACCOUNT_NUMBER%TYPE;
    l_instr_length  number := 0;
    l_validate_flag varchar2(1) := 'Y';
    l_mosr_owner_table_id number;

BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.    
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'validate_cust_account (+)',                
                p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT ACCOUNT_NUMBER,ORIG_SYSTEM_REFERENCE, ACCOUNT_ESTABLISHED_DATE,
               ACCOUNT_TERMINATION_DATE, ACCOUNT_ACTIVATION_DATE,
               CREATED_BY_MODULE, APPLICATION_ID,
               STATUS, CUSTOMER_TYPE, SALES_CHANNEL_CODE, FREIGHT_TERM,
               SHIP_VIA,SHIP_SETS_INCLUDE_LINES_FLAG,ARRIVALSETS_INCLUDE_LINES_FLAG,
          TAX_CODE,INVOICE_QUANTITY_RULE,PRIMARY_SALESREP_ID,
          ORDER_TYPE_ID,PRICE_LIST_ID,FOB_POINT,
          ITEM_CROSS_REF_PREF,WAREHOUSE_ID,DATE_TYPE_PREFERENCE,
                CUSTOMER_CLASS_CODE,TAX_ROUNDING_RULE
        INTO l_account_number,l_orig_system_reference, l_account_established_date,
             l_account_termination_date, l_account_activation_date,
             l_created_by_module, l_application_id,
             l_status, l_customer_type, l_sales_channel_code, l_freight_term,
             l_ship_via,l_ship_sets_inc_lines_f,l_arrivalsets_inc_lines_f,
        l_tax_code,l_invoice_quantity_rule,l_primary_salesrep_id,
        l_order_type_id,l_price_list_id,l_fob_point,
        l_item_cross_ref_pref,l_warehouse_id,l_date_type_preference,
        l_customer_class_code,l_tax_rounding_rule
        FROM HZ_CUST_ACCOUNTS
        WHERE ROWID = p_rowid;
    END IF;

    --------------------------------------
    -- validate cust_account_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.
 
        IF p_cust_account_rec.cust_account_id IS NOT NULL AND
           p_cust_account_rec.cust_account_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCOUNTS
            WHERE CUST_ACCOUNT_ID = p_cust_account_rec.cust_account_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'cust_account_id is unique during creation if passed in. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
              p_message=>'cust_account_id is unique during creation if passed in. ' ||
                    'x_return_status = ' || x_return_status,             
              p_msg_level=>fnd_log.level_statement);
        END IF;

        END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate cust_account_id ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate cust_account_id ... ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate account_number
    --------------------------------------

    -- account_number should be mandatory and unique.

    -- check if need generate account_number.
   BEGIN

    SELECT GENERATE_CUSTOMER_NUMBER INTO l_profile
    FROM AR_SYSTEM_PARAMETERS;

 --Bug Fix 2183072 Handled the exception 
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
       FND_MESSAGE.SET_NAME( 'AR','AR_NO_ROW_IN_SYSTEM_PARAMETERS');
       FND_MSG_PUB.ADD;
       x_return_status := FND_API.G_RET_STS_ERROR;

 END ;

   /* IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            'account_number autonumbering is ' || NVL( l_profile, 'N' ),
            l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_number autonumbering is ' || NVL( l_profile, 'N' ),
              p_msg_level=>fnd_log.level_statement);
    END IF;

    IF p_create_update_flag = 'C' THEN

        -- If autonumbering is on, if user has passed in an account_number, 
        -- error out. If autonumbering is off, if user has not passed in
        -- value, error out; 

        IF l_profile = 'Y' THEN
            IF p_cust_account_rec.account_number IS NOT NULL AND
               p_cust_account_rec.account_number <> FND_API.G_MISS_CHAR 
            THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_ACCOUNT_NUMBER_AUTO_ON' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
            END IF;
 
            -- the account_number will be generated from sequence by table handler.

            /*IF G_DEBUG THEN
                hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                    'account_number cannot be passed in if autonumbering is on. ' ||
                    'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                             p_message=>'account_number cannot be passed in if autonumbering is on. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
            END IF;

        ELSE
            IF p_cust_account_rec.account_number IS NULL OR
               p_cust_account_rec.account_number = FND_API.G_MISS_CHAR 
            THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
                FND_MESSAGE.SET_TOKEN( 'COLUMN', 'account_number' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
            END IF;

            /*IF G_DEBUG THEN
                hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                    'account_number is mandatory if autonumbering is off. ' ||
                    'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_number is mandatory if autonumbering is off. ' ||
                  'x_return_status = ' || x_return_status,                   
                         p_msg_level=>fnd_log.level_statement);
            END IF;

        END IF;

    ELSE -- in update
        IF p_cust_account_rec.account_number IS NOT NULL THEN
            validate_cannot_update_to_null (
                p_column                                => 'account_number', 
                p_column_value                          => p_cust_account_rec.account_number,
                x_return_status                         => x_return_status );

            /*IF G_DEBUG THEN
                hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                    'account_number cannot be updated to null. ' ||
                    'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_number cannot be updated to null. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
       END IF;

       --------------------------------------
       -- validate ACCOUNT NUMBER  BugNo:2441276
       --------------------------------------

       --  bug 3969469. account_number is updatable if the system option
            --  if AUTO_CUSTOMER_NUMBERING is OFF else it is not updatable.
            

       IF  (p_cust_account_rec.account_number<>l_account_number 
                AND l_profile='Y') -- bug 3969469
            THEN
          
      validate_nonupdateable (
          p_column                                => 'account_number',
          p_column_value                          => p_cust_account_rec.account_number,
          p_old_column_value                      => l_account_number,
          x_return_status                         => x_return_status );

      /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
         'account_number is non-updateable. ' ||
         'x_return_status = ' || x_return_status, l_debug_prefix );
      END IF;
      */
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_number is non-updateable. ' ||
                      'x_return_status = ' || x_return_status,                    
                      p_msg_level=>fnd_log.level_statement);
      END IF;

       END IF;
        
   END IF;

    END IF;

    -- account_number is unique.
    IF p_cust_account_rec.account_number IS NOT NULL AND
       p_cust_account_rec.account_number <> FND_API.G_MISS_CHAR 
    THEN
    BEGIN
        SELECT ROWID INTO l_rowid
        FROM HZ_CUST_ACCOUNTS
        WHERE ACCOUNT_NUMBER = p_cust_account_rec.account_number;

        IF p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U' AND l_rowid <> p_rowid )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'account_number' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            'account_number is unique. ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_number is unique. ' ||
                    'x_return_status = ' || x_return_status,              
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;




    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate account_number ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate account_number ... ' ||
              'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate orig_system_reference
    --------------------------------------

    -- orig_system_reference is unique. Since orig_system_refence is defaulting to
    -- primary key, we only need to check the uniqueness if user passes some value.
    -- database constraints can catch unique error when we defaulting.
    -- orig_system_reference is non-updateable, we only need to check uniqueness 
    -- during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_account_rec.orig_system_reference IS NOT NULL AND
       p_cust_account_rec.orig_system_reference <> FND_API.G_MISS_CHAR
    THEN
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_CUST_ACCOUNTS
        WHERE ORIG_SYSTEM_REFERENCE = p_cust_account_rec.orig_system_reference;
        
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'orig_system_reference' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            'orig_system_reference is unique. ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'orig_system_reference is unique. ' ||
                'x_return_status = ' || x_return_status,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;

    l_instr_length := instr(l_orig_system_reference,'#@');
    if l_instr_length > 0
    then
   l_orig_system_reference1 := null;
   if  substr(l_orig_system_reference,1,l_instr_length-1) <> p_cust_account_rec.orig_system_reference
        then
      l_validate_flag := 'N';
   end if;
    else
   l_orig_system_reference1 := p_cust_account_rec.orig_system_reference;
    end if;
   
   IF (p_cust_account_rec.orig_system is not null and p_cust_account_rec.orig_system <>fnd_api.g_miss_char) 
    and (p_cust_account_rec.orig_system_reference is not null and p_cust_account_rec.orig_system_reference <>fnd_api.g_miss_char) 
    and p_create_update_flag = 'U'
   then
   hz_orig_system_ref_pub.get_owner_table_id 
   (p_orig_system => p_cust_account_rec.orig_system, 
   p_orig_system_reference => p_cust_account_rec.orig_system_reference, 
   p_owner_table_name => 'HZ_CUST_ACCOUNTS', 
   x_owner_table_id => l_mosr_owner_table_id, 
   x_return_status => x_return_status); 
   IF x_return_status = fnd_api.g_ret_sts_success and l_mosr_owner_table_id= nvl(p_cust_account_rec.cust_account_id,l_mosr_owner_table_id)
   then
      l_validate_flag := 'N';
   end if;
    end if;
    -- orig_system_reference is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_account_rec.orig_system_reference IS NOT NULL
       and l_validate_flag = 'Y' 
    THEN

        validate_nonupdateable (
            p_column                                => 'orig_system_reference',
            p_column_value                          => l_orig_system_reference1,
            p_old_column_value                      => l_orig_system_reference,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'orig_system_reference is non-updateable. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'orig_system_reference is non-updateable. ' ||
               'x_return_status = ' || x_return_status,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate orig_system_reference ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate orig_system_reference ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;



    
    --------------------------------------
    -- validate status
    --------------------------------------

    -- status cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_cust_account_rec.status IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'status', 
            p_column_value                          => p_cust_account_rec.status,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'status cannot be updated to null. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'status cannot be updated to null. ' ||
               'x_return_status = ' || x_return_status,
                    p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- status is lookup code in lookup type CODE_STATUS
    IF p_cust_account_rec.status IS NOT NULL AND
       p_cust_account_rec.status <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.status <> NVL( l_status, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'status',
            p_lookup_type                           => 'CODE_STATUS',
            p_column_value                          => p_cust_account_rec.status,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'status is lookup code in lookup type CODE_STATUS. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'status is lookup code in lookup type CODE_STATUS. ' ||
                 'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate status ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate status ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate customer_type
    --------------------------------------

    -- customer_type is lookup code in lookup type CUSTOMER_TYPE
    IF p_cust_account_rec.customer_type IS NOT NULL AND
       p_cust_account_rec.customer_type <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.customer_type <> NVL( l_customer_type, FND_API.G_MISS_CHAR ) ) )
    THEN    
        validate_lookup (
            p_column                                => 'customer_type',
            p_lookup_type                           => 'CUSTOMER_TYPE',
            p_column_value                          => p_cust_account_rec.customer_type,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'customer_type is lookup code in lookup type CUSTOMER_TYPE. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'customer_type is lookup code in lookup type CUSTOMER_TYPE. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate customer_type ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate customer_type ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate sales_channel_code
    --------------------------------------

    -- sales_channel_code is lookup code in lookup type SALES_CHANNEL in so_lookups
    IF p_cust_account_rec.sales_channel_code IS NOT NULL AND
       p_cust_account_rec.sales_channel_code <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.sales_channel_code <> NVL( l_sales_channel_code, FND_API.G_MISS_CHAR ) ) )
    THEN 
        validate_lookup (
            p_column                                => 'sales_channel_code',
            p_lookup_table                          => 'SO_LOOKUPS',
            p_lookup_type                           => 'SALES_CHANNEL',
            p_column_value                          => p_cust_account_rec.sales_channel_code,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'sales_channel_code is lookup code in lookup type SALES_CHANNEL in so_lookups. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'sales_channel_code is lookup code in lookup type SALES_CHANNEL in so_lookups. ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate sales_channel_code ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate sales_channel_code ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate freight_term
    --------------------------------------

    -- freight_term is lookup code in lookup type FREIGHT_TERMS in so_lookups
    IF p_cust_account_rec.freight_term IS NOT NULL AND
       p_cust_account_rec.freight_term <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.freight_term <> NVL( l_freight_term, FND_API.G_MISS_CHAR ) ) )
    THEN 
        validate_lookup (
            p_column                                => 'freight_term',
            p_lookup_table                          => 'SO_LOOKUPS',
            p_lookup_type                           => 'FREIGHT_TERMS',
            p_column_value                          => p_cust_account_rec.freight_term,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'freight_term is lookup code in lookup type FREIGHT_TERMS in so_lookups. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'freight_term is lookup code in lookup type FREIGHT_TERMS in so_lookups. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;

   
    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate freight_term ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate freight_term ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate tax_header_level_flag
    --------------------------------------

    -- tax_header_level_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.tax_header_level_flag IS NOT NULL AND
       p_cust_account_rec.tax_header_level_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'tax_header_level_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.tax_header_level_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'tax_header_level_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'tax_header_level_flag is lookup code in lookup type YES/NO. ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate tax_header_level_flag ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate tax_header_level_flag ... ' ||
              'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;


       ----------------------------
       --validate tax_code    
       ----------------------------
    
      --tax_code is a valid value in ar_vat_tax
      IF p_cust_account_rec.tax_code is NOT NULL AND
         p_cust_account_rec.tax_code <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.tax_code <> NVL( l_tax_code, FND_API.G_MISS_CHAR ) ) )
      THEN
          check_tax_code(
               p_column                                => 'tax_code',
               p_column_value                          => p_cust_account_rec.tax_code,
               x_return_status                         => x_return_status );

          /*IF G_DEBUG THEN
             hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'Tax_code should be a valid value defined in table ar_vat_tax. '||
                'x_return_status = ' || x_return_status, l_debug_prefix);
          END IF;
     */
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Tax_code should be a valid value defined in table ar_vat_tax. '||
                  'x_return_status = ' || x_return_status,                    
                     p_msg_level=>fnd_log.level_statement);
     END IF;

   END IF;
          /*IF G_DEBUG THEN
             hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                '(+) after validate tax_code..' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
     END IF;
     */
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate tax_code..' ||
               'x_return_status = ' || x_return_status,                       
                        p_msg_level=>fnd_log.level_statement);
     END IF;


      ----------------------------------------------------------
      --validate order_type_id  
      ----------------------------------------------------------
      --order_type_id should be a valid value defined in OE_ORDER_TYPES_V

      IF p_cust_account_rec.order_type_id is NOT NULL AND
         p_cust_account_rec.order_type_id <> FND_API.G_MISS_NUM AND  
       ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.order_type_id <> NVL( l_order_type_id, FND_API.G_MISS_NUM ) ) )
      THEN
          check_ord_type(
                p_column                                => 'order_type_id',
                p_column_value                          => p_cust_account_rec.order_type_id,
                x_return_status                         => x_return_status );

         /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
               'order_type_id should be a valid value defined in OE_ORDER_TYPES_V..' ||
               'x_return_status = ' || x_return_status, l_debug_prefix);
         END IF;   
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'order_type_id should be a valid value defined in OE_ORDER_TYPES_V..' ||
                  'x_return_status = ' || x_return_status,                
                      p_msg_level=>fnd_log.level_statement);
    END IF;

      END IF;
         /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
               '(+) after validate order_type_id..' ||
               'x_return_status = ' || x_return_status, l_debug_prefix );
         END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate order_type_id..' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


   ----------------------------------------------------------
   --validate primary_salesrep_id  
   ----------------------------------------------------------
   --Primary_salesrep_id should be a valid value defined in RA_SALESREPS

   IF p_cust_account_rec.primary_salesrep_id is NOT NULL AND
      p_cust_account_rec.primary_salesrep_id <> FND_API.G_MISS_NUM
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.primary_salesrep_id <> NVL( l_primary_salesrep_id, FND_API.G_MISS_NUM ) ) )
   THEN
       check_prim_salesrep(
                   p_column                                => 'primary_salesrep_id',
              p_column_value                          => p_cust_account_rec.primary_salesrep_id,
                  x_return_status                         => x_return_status );

          /*IF G_DEBUG THEN
             hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  'Primary_salesrep_id should be a valid value defined in RA_SALESREPS. '||
                  'x_return_status = ' || x_return_status, l_debug_prefix);
       END IF;   
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Primary_salesrep_id should be a valid value defined in RA_SALESREPS. '||
               'x_return_status = ' || x_return_status,                       
                        p_msg_level=>fnd_log.level_statement);
        END IF;

        END IF;
            /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate primary_salesrep_id..' ||
                  'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate primary_salesrep_id..' ||
                  'x_return_status = ' || x_return_status,                        
                         p_msg_level=>fnd_log.level_statement);
       END IF;


--Bug fix 2311760
/**********
   -------------------------------------------------------
   --validate ship_partial
   -------------------------------------------------------
   -- ship_partial is a lookup code in lookup type YES/NO

        IF p_cust_account_rec.ship_partial IS NOT NULL AND
            p_cust_account_rec.ship_partial <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.ship_partial <> NVL( l_ship_partial, FND_API.G_MISS_CHAR) ) )
        THEN
            validate_lookup (
                p_column                                => 'ship_partial',
                p_lookup_type                           => 'YES/NO',
                p_column_value                          => p_cust_account_rec.ship_partial,
                x_return_status                         => x_return_status );
           
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'ship_partial is a lookup code in lookup type YES/NO. ' ||
                    'x_return_status = ' || x_return_status,                           
                           p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
         
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate ship_partial ... ' ||
                  'x_return_status = ' || x_return_status,                   
                         p_msg_level=>fnd_log.level_statement);
       END IF;


***************/
        -----------------------------------------------------------
   --validate tax_rounding_rule
   -----------------------------------------------------------
        --tax_rounding_rule is a lookup_code in lookup type TAX_ROUNDING_RULE

   IF p_cust_account_rec.tax_rounding_rule is NOT NULL AND
           p_cust_account_rec.tax_rounding_rule <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.tax_rounding_rule <> NVL( l_tax_rounding_rule, FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
                p_column        =>'tax_rounding_rule',
                p_lookup_type   =>'TAX_ROUNDING_RULE',
                p_column_value  =>p_cust_account_rec.tax_rounding_rule,
                x_return_status =>x_return_status  );

          /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  'tax_rounding_rule is lookup_code in lookup type TAX_ROUNDING_RULE. '||
                  'x_return_status = ' || x_return_status, l_debug_prefix);
            END IF;   
       */

       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'tax_rounding_rule is lookup_code in lookup type TAX_ROUNDING_RULE. '||
                   'x_return_status = ' || x_return_status,                 
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
            /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate tax_rounding_rule..' ||
                  'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate tax_rounding_rule..' ||
                   'x_return_status = ' || x_return_status,                 
                   p_msg_level=>fnd_log.level_statement);
        END IF;


   -------------------------------------------------------
   --validate customer_class_code
   -------------------------------------------------------
   --Customer_class_code is a lookup_code in lookup type CUSTOMER_CLASS 

   IF p_cust_account_rec.customer_class_code is NOT NULL AND
      p_cust_account_rec.customer_class_code <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.customer_class_code <> NVL( l_customer_class_code, FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
                p_column        =>'customer_class_code',
                p_lookup_type   =>'CUSTOMER CLASS',
                p_column_value  =>p_cust_account_rec.customer_class_code,
                x_return_status =>x_return_status  );
       /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  'Customer_class_code is lookup_code in lookup type CUSTOMER_CLASS. '||
                  'x_return_status = ' || x_return_status, l_debug_prefix);
            END IF;   
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Customer_class_code is lookup_code in lookup type CUSTOMER_CLASS. '||
                  'x_return_status = ' || x_return_status,                        
               p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
            /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate CUSTOMER_CLASS_CODE..' ||
                  'x_return_status = ' || x_return_status, l_debug_prefix );
             END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate CUSTOMER_CLASS_CODE..' ||
                  'x_return_status = ' || x_return_status,                
                 p_msg_level=>fnd_log.level_statement);
        END IF;


   ---------------------------------------------------
   --validate Invoice_quantity_rule
   ---------------------------------------------------
   --Invoice_quantity_rule is lookup_code in lookup type INVOICE_BASIS

   IF p_cust_account_rec.invoice_quantity_rule is NOT NULL AND
      p_cust_account_rec.invoice_quantity_rule <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.invoice_quantity_rule <> NVL( l_invoice_quantity_rule, FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
           p_column        =>'invoice_quantity_rule',
           p_lookup_table  =>'OE_LOOKUPS',
           p_lookup_type   =>'INVOICE_BASIS',
           p_column_value  =>p_cust_account_rec.invoice_quantity_rule,
           x_return_status =>x_return_status  );

       /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  'Invoice_quantity_rule is lookup_code in lookup type INVOICE_BASIS. '||
             'x_return_status = ' || x_return_status, l_debug_prefix);
            END IF;   
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=> 'Invoice_quantity_rule is lookup_code in lookup type INVOICE_BASIS. '||
                     'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
            /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate invoice_quantity_rule..' ||
                  'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */

       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate invoice_quantity_rule..' ||
                     'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
        END IF;


   ----------------------------------------------------------
   --validate price_list_id
   ----------------------------------------------------------
   --price_list_id should be a valid value defined in SO_PRICE_LISTS

   IF p_cust_account_rec.price_list_id is NOT NULL AND
      p_cust_account_rec.price_list_id <> FND_API.G_MISS_NUM
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.price_list_id <> NVL( l_price_list_id, FND_API.G_MISS_NUM) ) )
   THEN
       check_price_list_fk(
             p_column                           => 'price_list_id',
            p_column_value                     => p_cust_account_rec.price_list_id,
            x_return_status                    => x_return_status );
       /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  'price_list_id should be a valid value defined in SO_PRICE_LISTS. '||
                  'x_return_status = ' || x_return_status, l_debug_prefix);
       END IF;   
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'price_list_id should be a valid value defined in SO_PRICE_LISTS. '||
                'x_return_status = ' || x_return_status,                       
               p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
       /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate price_list_id..' ||
                  'x_return_status = ' || x_return_status, l_debug_prefix );
            END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate price_list_id..' ||
                  'x_return_status = ' || x_return_status,              
               p_msg_level=>fnd_log.level_statement);
       END IF;


   ----------------------------------------------------------
   --validate fob_point
   ----------------------------------------------------------
   --fob_point is lookup_code in lookup type FOB

   IF p_cust_account_rec.fob_point is NOT NULL AND
      p_cust_account_rec.fob_point <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.fob_point <> NVL( l_fob_point, FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
           p_column        =>'fob_point',
                 p_lookup_type   =>'FOB',
           p_column_value  =>p_cust_account_rec.fob_point,
           x_return_status =>x_return_status  );

       /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
             'fob_point is lookup_code in lookup type FOB. '||
             'x_return_status = ' || x_return_status, l_debug_prefix);
            END IF;   
       */
            IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'fob_point is lookup_code in lookup type FOB. '||
                  'x_return_status = ' || x_return_status,              
               p_msg_level=>fnd_log.level_statement);
       END IF;
      

   END IF;
            /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate fob_point..' ||
                  'x_return_status = ' || x_return_status, l_debug_prefix );
       END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate fob_point..' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   ----------------------------------------------------------
   --validate item_cross_ref_pref
   ----------------------------------------------------------
   --item_cross_ref_pref should be a value defined in MTL_CROSS_REFERENCE_TYPES or should have value 'INT' or 'CUST'

   IF p_cust_account_rec.item_cross_ref_pref is NOT NULL AND
      p_cust_account_rec.item_cross_ref_pref <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.item_cross_ref_pref <> NVL( l_item_cross_ref_pref, FND_API.G_MISS_CHAR) ) )
   THEN
       IF p_cust_account_rec.item_cross_ref_pref NOT IN('INT','CUST')
       THEN
           check_item_cross_ref(
                p_column                           => 'item_cross_ref_pref',
                p_column_value                     => p_cust_account_rec.item_cross_ref_pref,
                x_return_status                    => x_return_status );

           /*IF G_DEBUG THEN
              hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                 'item_cross_ref_pref should be a value defined in MTL_CROSS_REFERENCE_TYPES or should be INT or CUST . '||
                      'x_return_status = ' || x_return_status, l_debug_prefix);
                END IF;   
      */
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'item_cross_ref_pref should be a value defined in MTL_CROSS_REFERENCE_TYPES or should be INT or CUST . '||
                     'x_return_status = ' || x_return_status,                                 
                        p_msg_level=>fnd_log.level_statement);
      END IF;

      END IF;
       END IF;
          /*IF G_DEBUG THEN
                  hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                     '(+) after validate item_cross_ref_pref..' ||
                     'x_return_status = ' || x_return_status, l_debug_prefix );
               END IF;
          */
          IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate item_cross_ref_pref..' ||
                     'x_return_status = ' || x_return_status,                     
                      p_msg_level=>fnd_log.level_statement);
      END IF;


   ----------------------------------------------------------
   --validate warehouse_id
   ----------------------------------------------------------
   --warehouse_id should be a value defined in ORG_ORGANIZATION_DEFINITIONS

   IF p_cust_account_rec.warehouse_id is NOT NULL AND
      p_cust_account_rec.warehouse_id <> FND_API.G_MISS_NUM
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.warehouse_id <> NVL( l_warehouse_id, FND_API.G_MISS_NUM) ) )
   THEN
       check_warehouse(
            p_column                           => 'warehouse_id',
            p_column_value                     => p_cust_account_rec.warehouse_id,
            x_return_status                    => x_return_status );
       /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
             'warehouse_id should be a value defined in ORG_ORGANIZATION_DEFINITIONS . '||
             'x_return_status = ' || x_return_status, l_debug_prefix);
            END IF;   
       */

       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'warehouse_id should be a value defined in ORG_ORGANIZATION_DEFINITIONS . '||
                     'x_return_status = ' || x_return_status,                        
                         p_msg_level=>fnd_log.level_statement);
       END IF;

   END IF;
       /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
             '(+) after validate warehouse_id..' ||
             'x_return_status = ' || x_return_status, l_debug_prefix );
       END IF;
       */

       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate warehouse_id..' ||
                  'x_return_status = ' || x_return_status,                        
                         p_msg_level=>fnd_log.level_statement);
       END IF;


   ----------------------------------------------------------
   --validate date_type_preference
   ----------------------------------------------------------
   --date_type_preference is a lookup_code in lookup_type REQUEST_DATE_TYPE in oe_lookups

   IF p_cust_account_rec.date_type_preference is NOT NULL AND
      p_cust_account_rec.date_type_preference <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.date_type_preference <> NVL( l_date_type_preference, FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
            p_column               =>'date_type_preference',
            p_lookup_table         =>'OE_LOOKUPS',
            p_lookup_type          =>'REQUEST_DATE_TYPE',
            p_column_value         =>p_cust_account_rec.date_type_preference,
            x_return_status        =>x_return_status   );
       /*IF G_DEBUG THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
             'date_type_preference is a lookup_code in lookup_type REQUEST_DATE_TYPE in oe_lookups. '||
             'x_return_status = ' || x_return_status, l_debug_prefix);
       END IF;   
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'date_type_preference is a lookup_code in lookup_type REQUEST_DATE_TYPE in oe_lookups. '||
                     'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
       /*IF G_DEBUG THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
             '(+) after validate date_type_preference..' ||
             'x_return_status = ' || x_return_status, l_debug_prefix );
       END IF;
       */
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate date_type_preference..' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
            END IF;


    --------------------------------------
    -- validate primary_specialist_id
    --------------------------------------

    -- primary_specialist_id is foreign key to per_all_people_f
    IF p_cust_account_rec.primary_specialist_id IS NOT NULL AND
       p_cust_account_rec.primary_specialist_id <> FND_API.G_MISS_NUM 
    THEN
        check_per_all_people_f_fk (
            p_column                                 => 'primary_specialist_id',
            p_column_value                           => p_cust_account_rec.primary_specialist_id,
            x_return_status                          => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'primary_specialist_id is foreign key to per_all_people_f. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'primary_specialist_id is foreign key to per_all_people_f. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
        END IF;


    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate primary_specialist_id ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate primary_specialist_id ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate secondary_specialist_id
    --------------------------------------

    -- secondary_specialist_id is foreign key to per_all_people_f
    IF p_cust_account_rec.secondary_specialist_id IS NOT NULL AND
       p_cust_account_rec.secondary_specialist_id <> FND_API.G_MISS_NUM 
    THEN
        check_per_all_people_f_fk (
            p_column                                 => 'secondary_specialist_id',
            p_column_value                           => p_cust_account_rec.secondary_specialist_id,
            x_return_status                          => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'secondary_specialist_id is foreign key to per_all_people_f. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'secondary_specialist_id is foreign key to per_all_people_f. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate secondary_specialist_id ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate secondary_specialist_id ... ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate account_liable_flag
    --------------------------------------

    -- account_liable_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.account_liable_flag IS NOT NULL AND
       p_cust_account_rec.account_liable_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'account_liable_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.account_liable_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'account_liable_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_liable_flag is lookup code in lookup type YES/NO. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate account_liable_flag ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate account_liable_flag ... ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate hold_bill_flag
    --------------------------------------

    -- hold_bill_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.hold_bill_flag IS NOT NULL AND
       p_cust_account_rec.hold_bill_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'hold_bill_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.hold_bill_flag,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'hold_bill_flag is lookup code in lookup type YES/NO. ' ||
                    'x_return_status = ' || x_return_status,
              p_prefix=>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate hold_bill_flag ... ' ||
               'x_return_status = ' || x_return_status,
              p_prefix=>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate dormant_account_flag
    --------------------------------------

    -- dormant_account_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.dormant_account_flag IS NOT NULL AND
       p_cust_account_rec.dormant_account_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'dormant_account_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.dormant_account_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'dormant_account_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'dormant_account_flag is lookup code in lookup type YES/NO. ' ||
                   'x_return_status = ' || x_return_status,                 
                   p_msg_level=>fnd_log.level_statement);
       END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate dormant_account_flag ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate dormant_account_flag ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate ship_sets_include_lines_flag
    --------------------------------------

    -- ship_sets_include_lines_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.ship_sets_include_lines_flag IS NOT NULL AND
       p_cust_account_rec.ship_sets_include_lines_flag <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.ship_sets_include_lines_flag <> NVL( l_ship_sets_inc_lines_f, FND_API.G_MISS_CHAR) ) )
    THEN 
        validate_lookup (
            p_column                                => 'ship_sets_include_lines_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.ship_sets_include_lines_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'ship_sets_include_lines_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'ship_sets_include_lines_flag is lookup code in lookup type YES/NO. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

--if ship_sets_include_lines_flag is set to Y then arrivalsets_include_lines_flag
--is always set to N.

IF (p_create_update_flag = 'C' or
   (p_create_update_flag ='U' and
    p_cust_account_rec.ship_sets_include_lines_flag <> NVL(l_ship_sets_inc_lines_f,FND_API.G_MISS_CHAR)))
THEN
   IF p_cust_account_rec.ship_sets_include_lines_flag = 'Y'
   THEN
     BEGIN
       SELECT decode(p_cust_account_rec.ship_sets_include_lines_flag,p_cust_account_rec.arrivalsets_include_lines_flag,
                     'N',l_arrivalsets_inc_lines_f,
                                         decode(p_cust_account_rec.arrivalsets_include_lines_flag,l_ship_sets_inc_lines_f,                                                'Y','N'),'Y') 
       INTO l_dummy 
       FROM DUAL;
       IF l_dummy <> 'Y'
       THEN
       FND_MESSAGE.SET_NAME('AR','HZ_API_VAL_DEP_FIELDS');
       FND_MESSAGE.SET_TOKEN('COLUMN1','ship_sets_include_lines_flag');
            FND_MESSAGE.SET_TOKEN('VALUE1','Y');
            FND_MESSAGE.SET_TOKEN('COLUMN2','arrivalsets_include_lines_flag');
            FND_MESSAGE.SET_TOKEN('VALUE2','N');
       FND_MSG_PUB.ADD;
       x_return_status := FND_API.G_RET_STS_ERROR;
       END IF;
     END ;
   END IF;
END IF;
   /*IF G_DEBUG THEN
       hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
           'If ship_sets_include_lines_flag is set to Y then arrivalsets_include_lines_flag is always set to N. '||
           'x_return_status = ' || x_return_status, l_debug_prefix);
   END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'If ship_sets_include_lines_flag is set to Y then arrivalsets_include_lines_flag is always set to N. '||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
        END IF;



        /*IF G_DEBUG THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
              '(+) after validate arrivalsets_include_lines_flag ... ' ||
         'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate arrivalsets_include_lines_flag ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
        END IF;


    --------------------------------------
    -- validate arrivalsets_include_lines_flag
    --------------------------------------

    -- arrivalsets_include_lines_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.arrivalsets_include_lines_flag IS NOT NULL AND
       p_cust_account_rec.arrivalsets_include_lines_flag <> FND_API.G_MISS_CHAR
         AND ( p_create_update_flag = 'C' OR 
         ( p_create_update_flag = 'U'  AND 
           p_cust_account_rec.arrivalsets_include_lines_flag <> NVL( l_arrivalsets_inc_lines_f, FND_API.G_MISS_CHAR) ) )
    THEN 
        validate_lookup (
            p_column                                => 'arrivalsets_include_lines_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.arrivalsets_include_lines_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'arrivalsets_include_lines_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'arrivalsets_include_lines_flag is lookup code in lookup type YES/NO. ' ||
              'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

--If arrivalsets_include_lines_flag is set to Y then ship_sets_include_lines_flag
--is always set to N.

IF (p_create_update_flag ='C' or
        (p_create_update_flag ='U' and
         p_cust_account_rec.arrivalsets_include_lines_flag <> NVL(l_arrivalsets_inc_lines_f,FND_API.G_MISS_CHAR)))
THEN
        IF p_cust_account_rec.arrivalsets_include_lines_flag = 'Y'
        THEN
          BEGIN
            SELECT decode(p_cust_account_rec.arrivalsets_include_lines_flag,p_cust_account_rec.ship_sets_include_lines_flag,
                          'N',l_ship_sets_inc_lines_f,
                                        decode(p_cust_account_rec.ship_sets_include_lines_flag,l_arrivalsets_inc_lines_f,
                                               'Y','N'),'Y')
            INTO l_dummy
            FROM DUAL;
            IF l_dummy <> 'Y'
            THEN
          FND_MESSAGE.SET_NAME('AR','HZ_API_VAL_DEP_FIELDS');
          FND_MESSAGE.SET_TOKEN('COLUMN1','arrivalsets_include_lines_flag');
               FND_MESSAGE.SET_TOKEN('VALUE1','Y');
               FND_MESSAGE.SET_TOKEN('COLUMN2','ship_sets_include_lines_flag');
               FND_MESSAGE.SET_TOKEN('VALUE2','N');
                    FND_MSG_PUB.ADD;
               x_return_status := FND_API.G_RET_STS_ERROR;
            END IF;
          END ;
        END IF;
END IF;
        /*IF G_DEBUG THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
              'If arrivalsets_include_lines_flag is set to Y then ship_sets_include_lines_flag is always set to N. ' ||
              'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'If arrivalsets_include_lines_flag is set to Y then ship_sets_include_lines_flag is always set to N. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
   END IF;


        /*IF G_DEBUG THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                  '(+) after validate arrivalsets_include_lines_flag ... ' ||
                 'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate arrivalsets_include_lines_flag ... ' ||
                'x_return_status = ' || x_return_status,                 
                   p_msg_level=>fnd_log.level_statement);
   END IF;


    --------------------------------------
    -- validate sched_date_push_flag
    --------------------------------------

    -- sched_date_push_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.sched_date_push_flag IS NOT NULL AND
       p_cust_account_rec.sched_date_push_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'sched_date_push_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.sched_date_push_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'sched_date_push_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'sched_date_push_flag is lookup code in lookup type YES/NO. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate sched_date_push_flag ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate sched_date_push_flag ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate account_established_date and account_termination_date
    ----------------------------------------------

    -- account_termination_date should be greater than account_established_date
    validate_start_end_date (
        p_create_update_flag                    => p_create_update_flag,
        p_start_date_column_name                => 'account_established_date',
        p_start_date                            => p_cust_account_rec.account_established_date,
        p_old_start_date                        => l_account_established_date,
        p_end_date_column_name                  => 'account_termination_date',
        p_end_date                              => p_cust_account_rec.account_termination_date,
        p_old_end_date                          => l_account_termination_date,
        x_return_status                         => x_return_status );

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            'account_termination_date should be greater than account_established_date. ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_termination_date should be greater than account_established_date. ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate account_established_date and account_activation_date
    ----------------------------------------------

    -- account_activation_date should be greater than account_established_date
    validate_start_end_date (
        p_create_update_flag                    => p_create_update_flag,
        p_start_date_column_name                => 'account_established_date',
        p_start_date                            => p_cust_account_rec.account_established_date,
        p_old_start_date                        => l_account_established_date,
        p_end_date_column_name                  => 'account_activation_date',
        p_end_date                              => p_cust_account_rec.account_activation_date,
        p_old_end_date                          => l_account_activation_date,
        x_return_status                         => x_return_status );

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            'account_activation_date should be greater than account_established_date. ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_activation_date should be greater than account_established_date. ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate account_activation_date and account_termination_date
    ----------------------------------------------

    -- account_termination_date should be greater than account_activation_date
    validate_start_end_date (
        p_create_update_flag                    => p_create_update_flag,
        p_start_date_column_name                => 'account_activation_date',
        p_start_date                            => p_cust_account_rec.account_activation_date,
        p_old_start_date                        => l_account_activation_date,
        p_end_date_column_name                  => 'account_termination_date',
        p_end_date                              => p_cust_account_rec.account_termination_date,
        p_old_end_date                          => l_account_termination_date,
        x_return_status                         => x_return_status );

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            'account_termination_date should be greater than account_activation_date. ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'account_termination_date should be greater than account_activation_date. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate autopay_flag
    --------------------------------------

    -- autopay_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.autopay_flag IS NOT NULL AND
       p_cust_account_rec.autopay_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'autopay_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.autopay_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'autopay_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'autopay_flag is lookup code in lookup type YES/NO. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate autopay_flag ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate autopay_flag ... ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate notify_flag
    --------------------------------------

    -- notify_flag is lookup code in lookup type YES/NO
    IF p_cust_account_rec.notify_flag IS NOT NULL AND
       p_cust_account_rec.notify_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'notify_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_rec.notify_flag,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'notify_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'notify_flag is lookup code in lookup type YES/NO. ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate notify_flag ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate notify_flag ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate ship_via
    --------------------------------------

    -- ship_via is foreign key to oe_ship_methods_v
    -- can be used only in single org case.
    IF p_cust_account_rec.ship_via IS NOT NULL AND
       p_cust_account_rec.ship_via <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_cust_account_rec.ship_via <> NVL( l_ship_via, FND_API.G_MISS_CHAR ) ) )
    THEN
        check_oe_ship_methods_v_fk (
            p_entity                                 => 'ACCOUNT',
            p_column                                 => 'ship_via',
            p_column_value                           => p_cust_account_rec.ship_via,
            x_return_status                          => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'ship_via is foreign key to oe_ship_methods_v and can be used only in single org case. ' ||
                    'x_return_status = ' || x_return_status,   
              p_prefix=>l_debug_prefix,        
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate ship_via ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate ship_via ... ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate selling_party_id
    --------------------------------------

    -- selling_party_id is foreign key of hz_parties
    IF p_cust_account_rec.selling_party_id IS NOT NULL AND
       p_cust_account_rec.selling_party_id <> FND_API.G_MISS_NUM 
    THEN
        check_party_fk (
            p_column                                 => 'selling_party_id',
            p_column_value                           => p_cust_account_rec.selling_party_id,
            x_return_status                          => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'selling_party_id is foreign key of hz_parties. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'selling_party_id is foreign key of hz_parties. ' ||
                     'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate selling_party_id ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate selling_party_id ... ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_account_rec.created_by_module,
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'created_by_module is mandatory. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'created_by_module is mandatory. ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_account_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_account_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate created_by_module ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate created_by_module ... ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_account_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_cust_account_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );

        /*IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
   */
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    /*IF G_DEBUG THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
            '(+) after validate application_id ... ' ||
            'x_return_status = ' || x_return_status, l_debug_prefix );
    END IF;
    */
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=> '(+) after validate application_id ... ' ||
               'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- Debug info.
    /*IF G_DEBUG THEN
        HZ_UTILITY_V2PUB.debug ( 'validate_cust_account (-)' );
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'validate_cust_account (-)',                
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_cust_account;

/**
 * PROCEDURE validate_cust_acct_relate
 *
 * DESCRIPTION
 *     Validates customer account relate record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_cust_account_rec             Customer account relate record.
 *     p_cust_acct_relate_id          Primary key of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   10-04-2003    Rajib Ranjan Borah  o Bug 2985448.Only active relationships will be considered
 *                                       while checking for duplicates.
 *   02-MAR-2006   Idris Ali           o Bug 5073767:Replaced p_rowid with p_cust_acct_relate_id. 
 */

PROCEDURE validate_cust_acct_relate (
    p_create_update_flag                    IN     VARCHAR2,
    p_cust_acct_relate_rec                  IN     HZ_CUST_ACCOUNT_V2PUB.CUST_ACCT_RELATE_REC_TYPE,
    p_cust_acct_relate_id                   IN     NUMBER,      -- Bug 5073767
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; 
    l_dummy                                 VARCHAR2(1);
    l_customer_reciprocal_flag              HZ_CUST_ACCT_RELATE.customer_reciprocal_flag%TYPE;
    l_created_by_module                     HZ_CUST_ACCT_RELATE.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_relationship_type                     HZ_CUST_ACCT_RELATE.relationship_type%TYPE;
    l_status                                HZ_CUST_ACCT_RELATE.status%TYPE;

BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_acct_relate (+)',
                p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;
    

    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT CUSTOMER_RECIPROCAL_FLAG, CREATED_BY_MODULE, APPLICATION_ID,
               RELATIONSHIP_TYPE, STATUS
        INTO l_customer_reciprocal_flag, l_created_by_module, l_application_id,
             l_relationship_type, l_status
        FROM HZ_CUST_ACCT_RELATE
        WHERE CUST_ACCT_RELATE_ID = p_cust_acct_relate_id;
    END IF;

    --------------------------------------
    -- validate cust_account_id
    --------------------------------------
  
   IF  (p_create_update_flag <> 'U') OR
       (p_cust_acct_relate_rec.cust_acct_relate_id is NULL)  -- Bug 5073767
   THEN

     -- cust_account_id is mandatory field
     validate_mandatory (
        p_create_update_flag                    => p_create_update_flag,
        p_column                                => 'cust_account_id',
        p_column_value                          => p_cust_acct_relate_rec.cust_account_id,
        p_restricted                            => 'Y',
        x_return_status                         => x_return_status );
    
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'cust_account_id is mandatory. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
     END IF;
    END IF;
    -- since cust account id is part of primary key, we do not need to
    -- check non-updateable.

    -- cust_account_id is foreign key of hz_cust_accounts
    IF p_create_update_flag = 'C' AND 
       p_cust_acct_relate_rec.cust_account_id IS NOT NULL AND
       p_cust_acct_relate_rec.cust_account_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_account_fk (
            p_column                                 => 'cust_account_id',
            p_column_value                           => p_cust_acct_relate_rec.cust_account_id,
            x_return_status                          => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is foreign key of hz_cust_accounts. ' ||
                    'x_return_status = ' || x_return_status,
                                  p_prefix=>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'(+) after validate cust_account_id ... ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate related_cust_account_id
    --------------------------------------
   IF  (p_create_update_flag <> 'U') OR
       (p_cust_acct_relate_rec.cust_acct_relate_id is NULL)  -- Bug 5073767
   THEN

    -- related_cust_account_id is mandatory field
     validate_mandatory (
        p_create_update_flag                    => p_create_update_flag,
        p_column                                => 'related_cust_account_id',
        p_column_value                          => p_cust_acct_relate_rec.related_cust_account_id,
        p_restricted                            => 'Y',
        x_return_status                         => x_return_status );

     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'related_cust_account_id is mandatory. ' ||
                    'x_return_status = ' || x_return_status,                   
                   p_msg_level=>fnd_log.level_statement);
     END IF;
    END IF;

    -- since related_cust account id is part of primary key, we do not need to
    -- check non-updateable.

    -- related_cust_account_id is foreign key of hz_cust_accounts
    IF p_create_update_flag = 'C' AND
       p_cust_acct_relate_rec.related_cust_account_id IS NOT NULL AND
       p_cust_acct_relate_rec.related_cust_account_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_account_fk (
            p_column                                 => 'related_cust_account_id',
            p_column_value                           => p_cust_acct_relate_rec.related_cust_account_id,
            x_return_status                          => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'related_cust_account_id is foreign key of hz_cust_accounts. ' ||
                  'x_return_status = ' || x_return_status,                  
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- combination of cust_account_id and related_cust_account_id should be unique.
    -- we do not need to check this in update mode because there two columns
    -- are primary key.
    IF p_create_update_flag = 'C' THEN
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_CUST_ACCT_RELATE
        WHERE CUST_ACCOUNT_ID = p_cust_acct_relate_rec.cust_account_id
        AND RELATED_CUST_ACCOUNT_ID = p_cust_acct_relate_rec.related_cust_account_id
   --Bug 2985448
   AND STATUS='A';

        FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_REL_ALREADY_EXISTS' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'combination of cust_account_id and related_cust_account_id should be unique. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate related_cust_account_id ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate customer_reciprocal_flag
    --------------------------------------
    
    -- donot need to check customer_reciprocal_flag mandatory
    -- because customer_reciprocal_flag is non-updateable and it is defaulted
    -- to 'N' during insert

    -- customer_reciprocal_flag is non-updateable
    IF p_create_update_flag = 'U' AND
       p_cust_acct_relate_rec.customer_reciprocal_flag IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'customer_reciprocal_flag',
            p_column_value                          => p_cust_acct_relate_rec.customer_reciprocal_flag,
            p_old_column_value                      => l_customer_reciprocal_flag,
            x_return_status                         => x_return_status );

        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'customer_reciprocal_flag is non-updateable. ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- customer_reciprocal_flag is lookup code in lookup type YES/NO
    -- Since customer_reciprocal_flag is non-updateable, we only need to do
    -- checking during create.

    IF p_create_update_flag = 'C' AND
       p_cust_acct_relate_rec.customer_reciprocal_flag IS NOT NULL AND
       p_cust_acct_relate_rec.customer_reciprocal_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'customer_reciprocal_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_acct_relate_rec.customer_reciprocal_flag,
            x_return_status                         => x_return_status );

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'customer_reciprocal_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate customer_reciprocal_flag ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    --------------------------------------
    -- validate relationship_type
    --------------------------------------

    -- relationship_type is lookup code in lookup type RELATIONSHIP_TYPE
    IF p_cust_acct_relate_rec.relationship_type IS NOT NULL AND
       p_cust_acct_relate_rec.relationship_type <> FND_API.G_MISS_CHAR AND
        ( p_create_update_flag = 'C' OR
          ( p_create_update_flag = 'U'  AND
            p_cust_acct_relate_rec.relationship_type <> NVL( l_relationship_type, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'relationship_type',
            p_lookup_type                           => 'RELATIONSHIP_TYPE',
            p_column_value                          => p_cust_acct_relate_rec.relationship_type,
            x_return_status                         => x_return_status );

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'relationship_type is lookup code in lookup type RELATIONSHIP_TYPE. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate relationship_type ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    --------------------------------------
    -- validate status
    --------------------------------------

    -- status cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_cust_acct_relate_rec.status IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'status', 
            p_column_value                          => p_cust_acct_relate_rec.status,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status cannot be updated to null. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    -- status is lookup code in lookup type CODE_STATUS
    IF p_cust_acct_relate_rec.status IS NOT NULL AND
       p_cust_acct_relate_rec.status <> FND_API.G_MISS_CHAR AND
        ( p_create_update_flag = 'C' OR
          ( p_create_update_flag = 'U'  AND
            p_cust_acct_relate_rec.status <> NVL( l_status, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'status',
            p_lookup_type                           => 'CODE_STATUS',
            p_column_value                          => p_cust_acct_relate_rec.status,
            x_return_status                         => x_return_status );

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status is lookup code in lookup type CODE_STATUS. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate status ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory 
    -- during creation. 

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_acct_relate_rec.created_by_module,
            x_return_status                         => x_return_status );

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_acct_relate_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_acct_relate_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate created_by_module ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_acct_relate_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_cust_acct_relate_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate application_id ... ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    -- Debug info.

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>' validate_cust_acct_relate (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;   
    

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_cust_acct_relate;

/**
 * PROCEDURE validate_customer_profile
 *
 * DESCRIPTION
 *     Validates customer profile record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_customer_profile_rec         Customer profile record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   11-08-2001    P.Suresh            * Bug No : 1999532. Added validations as present in 
 *                                       customer standard form and interface.
 *   12-05-2001    P.Suresh            * Bug No : 2125994. Commented the mandatory check
 *                                       on charge_on_finance_charge_flag when interest
 *                                       charge is 'Y'.
 *   16-09-2002    P.Suresh            * Bug No : 2441092. Added a condition that the 
 *                                       discount_terms should be 'Y' when defaulting the
 *                                       discount_grace_days from the hz_cust_profile_classes.
 *   05-30-2003   Ramesh Ch            * Bug No : 2884220. Added a condition that the 
 *              interest_charges should be 'Y' when initializing 
 *              the interest_period_days from the hz_cust_profile_classes.
 *  06-23-2003  Ramesh Ch      Bug No : 2884220. Added a condition that the dunning_letters,send_statements 
 *                                       should be 'Y' when initializing the dunning_letter_set_id,statement_cycle_id resp
 *              from the hz_cust_profile_classes.
 *
 */

PROCEDURE validate_customer_profile (
    p_create_update_flag                    IN     VARCHAR2,
    p_customer_profile_rec                  IN     HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_customer_profile'

    l_dummy                                 VARCHAR2(1);

    l_cust_account_id                       NUMBER;
    l_collector_id                          NUMBER;
    l_profile_class_id                      NUMBER;
    l_site_use_id                           NUMBER;
    l_cust_acct_site_id                     NUMBER;
    l_class_status                          HZ_CUST_PROFILE_CLASSES.status%TYPE;
    l_profile_class_name                    HZ_CUST_PROFILE_CLASSES.name%TYPE;
    l_created_by_module                     HZ_CUSTOMER_PROFILES.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_credit_rating                         HZ_CUSTOMER_PROFILES.credit_rating%TYPE;          
    l_risk_code                             HZ_CUSTOMER_PROFILES.risk_code%TYPE;  
    l_status                                HZ_CUSTOMER_PROFILES.status%TYPE;
    l_profile_class_rec                     HZ_CUST_PROFILE_CLASSES%ROWTYPE;
    v_customer_profile_rec                  HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE 
                                                                     := p_customer_profile_rec;
    l_discount_terms                        HZ_CUSTOMER_PROFILES.discount_terms%TYPE;
    l_discount_grace_days                   HZ_CUSTOMER_PROFILES.discount_grace_days%TYPE; 
    l_dunning_letters                       HZ_CUSTOMER_PROFILES.dunning_letters%TYPE;
    l_dunning_letter_set_id                 HZ_CUSTOMER_PROFILES.dunning_letter_set_id%TYPE;
    l_send_statements                       HZ_CUSTOMER_PROFILES.send_statements%TYPE; 
    l_statement_cycle_id                    HZ_CUSTOMER_PROFILES.statement_cycle_id%TYPE;
    l_credit_balance_statements             HZ_CUSTOMER_PROFILES.credit_balance_statements%TYPE;
    l_interest_charges                      HZ_CUSTOMER_PROFILES.interest_charges%TYPE; 
    l_finance_charge_flag                   HZ_CUSTOMER_PROFILES.charge_on_finance_charge_flag%TYPE;
    l_interest_period_days                  HZ_CUSTOMER_PROFILES.interest_period_days%TYPE;

    l_account_status                        HZ_CUSTOMER_PROFILES.ACCOUNT_STATUS%TYPE;
    l_tolerance                             HZ_CUSTOMER_PROFILES.TOLERANCE%TYPE;
    l_percent_collectable                   HZ_CUSTOMER_PROFILES.PERCENT_COLLECTABLE%TYPE;
    l_standard_terms                        HZ_CUSTOMER_PROFILES.STANDARD_TERMS%TYPE;
    l_override_terms                        HZ_CUSTOMER_PROFILES.OVERRIDE_TERMS%TYPE;
    l_lockbox_matching_option               HZ_CUSTOMER_PROFILES.LOCKBOX_MATCHING_OPTION%TYPE;
    l_autocash_hierarchy_id                 HZ_CUSTOMER_PROFILES.AUTOCASH_HIERARCHY_ID%TYPE;
    l_autocash_hierarchy_id_for_ad          HZ_CUSTOMER_PROFILES.AUTOCASH_HIERARCHY_ID_FOR_ADR%TYPE;
    l_clearing_days                         HZ_CUSTOMER_PROFILES.CLEARING_DAYS%TYPE;
    l_payment_grace_days                    HZ_CUSTOMER_PROFILES.PAYMENT_GRACE_DAYS%TYPE;
    l_grouping_rule_id                      HZ_CUSTOMER_PROFILES.GROUPING_RULE_ID%TYPE;
    l_tax_printing_option                   HZ_CUSTOMER_PROFILES.TAX_PRINTING_OPTION%TYPE;
    l_review_cycle                          HZ_CUSTOMER_PROFILES.REVIEW_CYCLE%TYPE;
    l_last_credit_review_date               HZ_CUSTOMER_PROFILES.LAST_CREDIT_REVIEW_DATE%TYPE;
    l_next_credit_review_date               HZ_CUSTOMER_PROFILES.NEXT_CREDIT_REVIEW_DATE%TYPE;
    l_party_id                              HZ_CUSTOMER_PROFILES.PARTY_ID%TYPE;
    l_credit_classification                 HZ_CUSTOMER_PROFILES.CREDIT_CLASSIFICATION%TYPE;

    l_cust_acct_site_use_code               HZ_CUST_SITE_USES.SITE_USE_CODE%TYPE;

BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=> 'validate_customer_profile (+)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;
    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' 
    THEN

        SELECT CUST_ACCOUNT_ID, SITE_USE_ID, CREATED_BY_MODULE, APPLICATION_ID,
               CREDIT_RATING, RISK_CODE, STATUS,DISCOUNT_TERMS,
               DISCOUNT_GRACE_DAYS,DUNNING_LETTERS,DUNNING_LETTER_SET_ID,
               SEND_STATEMENTS,STATEMENT_CYCLE_ID,CREDIT_BALANCE_STATEMENTS,
               INTEREST_CHARGES,CHARGE_ON_FINANCE_CHARGE_FLAG,
               INTEREST_PERIOD_DAYS,ACCOUNT_STATUS,TOLERANCE,PERCENT_COLLECTABLE,
          STANDARD_TERMS,OVERRIDE_TERMS,LOCKBOX_MATCHING_OPTION,
          AUTOCASH_HIERARCHY_ID,AUTOCASH_HIERARCHY_ID_FOR_ADR,
          CLEARING_DAYS,PAYMENT_GRACE_DAYS,GROUPING_RULE_ID,
          TAX_PRINTING_OPTION,
               REVIEW_CYCLE,LAST_CREDIT_REVIEW_DATE,NEXT_CREDIT_REVIEW_DATE,PARTY_ID,
               CREDIT_CLASSIFICATION
        INTO l_cust_account_id, l_site_use_id, l_created_by_module, l_application_id,
             l_credit_rating, l_risk_code, l_status,l_discount_terms,
             l_discount_grace_days,l_dunning_letters,l_dunning_letter_set_id,
             l_send_statements,l_statement_cycle_id,l_credit_balance_statements,
             l_interest_charges,l_finance_charge_flag,
             l_interest_period_days,l_account_status,l_tolerance,l_percent_collectable,
        l_standard_terms,l_override_terms,l_lockbox_matching_option,
        l_autocash_hierarchy_id,l_autocash_hierarchy_id_for_ad,
        l_clearing_days,l_payment_grace_days,l_grouping_rule_id,
        l_tax_printing_option,
             l_review_cycle,l_last_credit_review_date,l_next_credit_review_date,l_party_id,
             l_credit_classification
        FROM HZ_CUSTOMER_PROFILES
        WHERE ROWID = p_rowid;
    END IF;

    --------------------------------------
    -- validate cust_account_profile_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.
 
        IF p_customer_profile_rec.cust_account_profile_id IS NOT NULL AND
           p_customer_profile_rec.cust_account_profile_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM   HZ_CUSTOMER_PROFILES
            WHERE  CUST_ACCOUNT_PROFILE_ID = p_customer_profile_rec.cust_account_profile_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_profile_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_profile_id is unique during creation if passed in. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

        END IF;
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_profile_id ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate cust_account_id
    ----------------------------------------------

    -- cust_account_id is mandatory field
    -- Since cust_account_id is non-updateable, we only need to check mandatory
    -- during creation.
    --
    -- 2310474: cust_account_id can be equal = -1 if the profile is related to party
    -- and not a customer account.
    --

   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id = ' || p_customer_profile_rec.cust_account_id || ' ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_account_id',
            p_column_value                          => p_customer_profile_rec.cust_account_id,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is mandatory. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- 2310474 party_id is mandatory field
    IF p_create_update_flag = 'C'
    THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'party_id',
            p_column_value                          => p_customer_profile_rec.party_id,
            x_return_status                         => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_id is mandatory. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- cust_account_id is non-updateable field.
    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.cust_account_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_account_id',
            p_column_value                          => p_customer_profile_rec.cust_account_id,
            p_old_column_value                      => l_cust_account_id,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is non-updateable. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- 2310474 After the migration script to fill up party_id for all exiting customer profiles arhucppt.sql
    -- the party_id is not updeatable

    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.party_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'party_id',
            p_column_value                          => p_customer_profile_rec.party_id,
            p_old_column_value                      => l_party_id,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is non-updateable. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;


    -- cust_account_id is foreign key to hz_cust_accounts
    -- Since cust_acocunt_id is non-updateable, we only need to 
    -- check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_customer_profile_rec.cust_account_id IS NOT NULL AND
       p_customer_profile_rec.cust_account_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_account_fk (
            p_column                                 => 'cust_account_id',
            p_column_value                           => p_customer_profile_rec.cust_account_id,
            x_return_status                          => x_return_status );

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is foreign key to hz_cust_accounts. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- We can only have one customer profile for one account
    -- Because cust_account_id is non-updateable, we only need to do this check during
    -- creation.
    -------------------------------------
    -- 2310474: p_cust_account_rec.cust_account_id = -1 if we are creating the profile for a party
    --      One party can only have 1 only 1 customer profile directly attached to it
    -------------------------------------

    IF p_create_update_flag = 'C' AND
       ( p_customer_profile_rec.site_use_id IS NULL OR
         p_customer_profile_rec.site_use_id = FND_API.G_MISS_NUM ) AND
       p_customer_profile_rec.cust_account_id <> -1
    THEN
      BEGIN
          SELECT 'Y' INTO l_dummy
          FROM HZ_CUSTOMER_PROFILES
          WHERE CUST_ACCOUNT_ID = p_customer_profile_rec.cust_account_id
          AND SITE_USE_ID IS NULL
          AND ROWNUM = 1;

          FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
          FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_id' );
          FND_MSG_PUB.ADD;
          x_return_status := FND_API.G_RET_STS_ERROR;
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
              NULL;
      END;
         
  
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'only one customer profile for one account. ' ||
                         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
      END IF;


    ELSIF p_create_update_flag = 'C' AND
         ( p_customer_profile_rec.site_use_id IS NULL OR
           p_customer_profile_rec.site_use_id = FND_API.G_MISS_NUM ) AND
          p_customer_profile_rec.cust_account_id = -1
    THEN
      -- 2310474 in this case we are creating a customer profile for party
      -- One party can only have 1 and only 1 profile directly attachment to the party
      -- At party level
      BEGIN
         SELECT 'Y' INTO l_dummy
         FROM HZ_CUSTOMER_PROFILES
         WHERE PARTY_ID = p_customer_profile_rec.party_id
         AND CUST_ACCOUNT_ID = -1;

         FND_MESSAGE.SET_NAME( 'AR', 'HZ_ONLY_ONE_PROF_AT_PARTY_LEV' );
         FND_MESSAGE.SET_TOKEN( 'PARTY_ID', p_customer_profile_rec.party_id );
         FND_MSG_PUB.ADD;
         x_return_status := FND_API.G_RET_STS_ERROR;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
                NULL;
      END;


      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'only one customer profile for one party at party level. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
      END IF;


    END IF;

 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ---------------------------------
    -- 2310474 Validation of review_cycle
    -- The last_credit_review_date and next_credit_review_date are not part of TCA API management
    -- Credit Management team take care of them
    -- V2 API does not do any validation on Last_Review_date and Next_review_date 
    ---------------------------------

    -- Validate lookup_code of the REVIEW_CYCLE
    IF p_customer_profile_rec.review_cycle IS NOT NULL AND
       p_customer_profile_rec.review_cycle <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.review_cycle <> NVL( l_review_cycle, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'review_cycle',
            p_lookup_table                          => 'AR_LOOKUPS',
            p_lookup_type                           => 'PERIODIC_REVIEW_CYCLE',
            p_column_value                          => p_customer_profile_rec.review_cycle,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'review_cycle is lookup code in lookup type PERIODIC_REVIEW_CYCLE in ar_lookups. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;


    END IF;


    ----------------------------------------------
    -- validate collector_id
    ----------------------------------------------

    -- collector_id is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the collector_id can be null or G_MISS during
    -- creation and it will default to collect_id of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'collector_id',
        p_column_value                           => p_customer_profile_rec.collector_id,
        x_return_status                          => x_return_status );

   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'collector_id is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    -- collector_id is foreign key to ar_collectors
    IF p_customer_profile_rec.collector_id IS NOT NULL AND
       p_customer_profile_rec.collector_id <> FND_API.G_MISS_NUM
    THEN
        check_collector_fk (
            p_column                                 => 'collector_id',
            p_column_value                           => p_customer_profile_rec.collector_id,
            x_return_status                          => x_return_status );


   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'collector_id is foreign key to ar_collectors. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate collector_id ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate credit_checking
    ----------------------------------------------

    -- credit_checking is mandatory field.

    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the credit_checking can be null or G_MISS during
    -- creation and it will default to credit_checking of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'credit_checking',
        p_column_value                           => p_customer_profile_rec.credit_checking,
        x_return_status                          => x_return_status );
 
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_checking is mandatory : it can be null but not G_MISS. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

  
    -- credit_checking is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.credit_checking IS NOT NULL AND
       p_customer_profile_rec.credit_checking <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'credit_checking',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.credit_checking,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_checking is lookup code in lookup type YES/NO. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate credit_checking ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate discount_terms
    ----------------------------------------------

    -- discount_terms is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the discount_terms can be null or G_MISS during
    -- creation and it will default to discount_terms of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'discount_terms',
        p_column_value                           => p_customer_profile_rec.discount_terms,
        x_return_status                          => x_return_status );
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'discount_terms is mandatory : it can be null but not G_MISS. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- discount_terms is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.discount_terms IS NOT NULL AND
       p_customer_profile_rec.discount_terms <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.discount_terms <> NVL( l_discount_terms, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'discount_terms',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.discount_terms,
            x_return_status                         => x_return_status );

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'discount_terms is lookup code in lookup type YES/NO. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate discount_terms ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate tolerance
    ----------------------------------------------

    -- tolerance is mandatory field.

    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the tolerance can be null or G_MISS during
    -- creation and it will default to tolerance of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'tolerance',
        p_column_value                           => p_customer_profile_rec.tolerance,
        x_return_status                          => x_return_status );

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'tolerance is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate profile_class_id
    ----------------------------------------------

    -- profile_class_id is foreign key to hz_cust_profile_classes
    IF p_customer_profile_rec.profile_class_id IS NOT NULL AND
       p_customer_profile_rec.profile_class_id <> FND_API.G_MISS_NUM
    THEN
        IF p_customer_profile_rec.profile_class_id < 0 THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NEGATIVE_PROFILE_CLASS' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        ELSE
        BEGIN
            SELECT STATUS, NAME INTO l_class_status, l_profile_class_name
            FROM HZ_CUST_PROFILE_CLASSES
            WHERE PROFILE_CLASS_ID = p_customer_profile_rec.profile_class_id;

            IF l_class_status <> 'A' THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INACTIVE_PROFILE_CLASS' );
                FND_MESSAGE.SET_TOKEN( 'NAME', l_profile_class_name );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
                FND_MESSAGE.SET_TOKEN( 'FK', 'profile_class_id' );
                FND_MESSAGE.SET_TOKEN( 'COLUMN', 'profile_class_id' );
                FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_profile_classes');
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
        END;
        END IF;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'profile_class_id should be positive, foreign key of hz_cust_profile_classes and point to an active profile class. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- profile_class_id cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.profile_class_id IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'profile_class_id',
            p_column_value                          => p_customer_profile_rec.profile_class_id,
            x_return_status                         => x_return_status );

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'profile_class_id cannot be updated to null. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate profile_class_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate site_use_id
    ----------------------------------------------

    -- site_use_id is non-updateable field.
    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.site_use_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'site_use_id',
            p_column_value                          => p_customer_profile_rec.site_use_id,
            p_old_column_value                      => l_site_use_id,
            x_return_status                         => x_return_status );
 
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_id is non-updateable. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    ------------------
    -- site_use_id is foreign key to hz_cust_site_uses.
    -- one site use can only have one profile.
    -- Since site_use_id is non-updateable, we only need to check
    -- FK during creation.
    ------------------
    -- 2310474: User can create a customer profile at site level
    -- only if the profile is created for at account level
    -- and not at party level
    ------------------
    

    IF p_create_update_flag = 'C' AND
       p_customer_profile_rec.site_use_id IS NOT NULL AND
       p_customer_profile_rec.site_use_id <> FND_API.G_MISS_NUM AND
       p_customer_profile_rec.cust_account_id <> -1
    THEN

        BEGIN
            SELECT CUST_ACCT_SITE_ID,SITE_USE_CODE INTO l_cust_acct_site_id,l_cust_acct_site_use_code
            FROM HZ_CUST_SITE_USES
            WHERE SITE_USE_ID = p_customer_profile_rec.site_use_id;
       /*--Start of BugNo:3125660.
       IF l_cust_acct_site_use_code NOT IN ('BILL_TO','DUN','STMTS') THEN
                FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ADDR_MUST_BILL_DUN_STM' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;    
       END IF;
      --End of BugNo:3125660.
      */
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
                FND_MESSAGE.SET_TOKEN( 'FK', 'site_use_id' );
                FND_MESSAGE.SET_TOKEN( 'COLUMN', 'site_use_id' );
                FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_site_uses' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
        END;

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_id is foreign key to hz_cust_site_uses. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;


        -- cust_account_id should be same as cust_account_id site_use_id belongs to.
        SELECT CUST_ACCOUNT_ID INTO l_cust_account_id
        FROM HZ_CUST_ACCT_SITES
        WHERE CUST_ACCT_SITE_ID = l_cust_acct_site_id;

        IF l_cust_account_id <> p_customer_profile_rec.cust_account_id THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_ACCT_SITEUSE_MISMATCH' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;

    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id should be same as cust_account_id site_use_id belongs to. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;


        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUSTOMER_PROFILES
            WHERE CUST_ACCOUNT_ID = p_customer_profile_rec.cust_account_id
            AND SITE_USE_ID = p_customer_profile_rec.site_use_id
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'one site use can only have one profile. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;


    -- 2310474: Profile can not be at account site level if it is created at party level
    ELSIF p_create_update_flag = 'C' AND
          p_customer_profile_rec.site_use_id IS NOT NULL AND
          p_customer_profile_rec.site_use_id <> FND_API.G_MISS_NUM AND
          p_customer_profile_rec.cust_account_id = -1
    THEN
          FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NO_SITE_PROF_AT_PTY_LEV' );
          FND_MESSAGE.SET_TOKEN( 'PARTY_ID', p_customer_profile_rec.party_id );
          FND_MESSAGE.SET_TOKEN( 'SITE_USE_ID', p_customer_profile_rec.site_use_id );
          FND_MSG_PUB.ADD;
          x_return_status := FND_API.G_RET_STS_ERROR;

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'profile at party level cannot be assign to a site. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;


    END IF;

   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate site_use_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate site_use_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate credit_rating
    ----------------------------------------------

    -- credit_rating is lookup code in lookup type CREDIT_RATING
    IF p_customer_profile_rec.credit_rating IS NOT NULL AND
       p_customer_profile_rec.credit_rating <> FND_API.G_MISS_CHAR AND
        ( p_create_update_flag = 'C' OR
          ( p_create_update_flag = 'U'  AND
            p_customer_profile_rec.credit_rating <> NVL( l_credit_rating, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'credit_rating',
            p_lookup_type                           => 'CREDIT_RATING',
            p_column_value                          => p_customer_profile_rec.credit_rating,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_rating is lookup code in lookup type CREDIT_RATING. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate credit_rating ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate risk_code
    ----------------------------------------------

    -- risk_code is lookup code in lookup type RISK_CODE
    IF p_customer_profile_rec.risk_code IS NOT NULL AND
       p_customer_profile_rec.risk_code <> FND_API.G_MISS_CHAR AND
        ( p_create_update_flag = 'C' OR
          ( p_create_update_flag = 'U'  AND
            p_customer_profile_rec.risk_code <> NVL( l_risk_code, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'risk_code',
            p_lookup_type                           => 'RISK_CODE',
            p_column_value                          => p_customer_profile_rec.risk_code,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'risk_code is lookup code in lookup type RISK_CODE. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate risk_code ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate auto_rec_incl_disputed_flag
    ----------------------------------------------

    -- auto_rec_incl_disputed_flag is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the auto_rec_incl_disputed_flag can be null or G_MISS during
    -- creation and it will default to auto_rec_incl_disputed_flag of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'auto_rec_incl_disputed_flag',
        p_column_value                           => p_customer_profile_rec.auto_rec_incl_disputed_flag,
        x_return_status                          => x_return_status );

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'auto_rec_incl_disputed_flag is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- auto_rec_incl_disputed_flag is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.auto_rec_incl_disputed_flag IS NOT NULL AND
       p_customer_profile_rec.auto_rec_incl_disputed_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'auto_rec_incl_disputed_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.auto_rec_incl_disputed_flag,
            x_return_status                         => x_return_status );

       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'auto_rec_incl_disputed_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate auto_rec_incl_disputed_flag ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate charge_on_finance_charge_flag
    ----------------------------------------------

    -- charge_on_finance_charge_flag is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.charge_on_finance_charge_flag IS NOT NULL AND
       p_customer_profile_rec.charge_on_finance_charge_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'charge_on_finance_charge_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.charge_on_finance_charge_flag,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'charge_on_finance_charge_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after charge_on_finance_charge_flag ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate cons_inv_flag
    ----------------------------------------------

    -- cons_inv_flag is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.cons_inv_flag IS NOT NULL AND
       p_customer_profile_rec.cons_inv_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'cons_inv_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.cons_inv_flag,
            x_return_status                         => x_return_status );

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cons_inv_flag is lookup code in lookup type YES/NO. ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after cons_inv_flag ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate status
    ----------------------------------------------

    -- status cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.status IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'status', 
            p_column_value                          => p_customer_profile_rec.status,
            x_return_status                         => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status cannot be updated to null. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- status is lookup code in lookup type CODE_STATUS
    IF p_customer_profile_rec.status IS NOT NULL AND
       p_customer_profile_rec.status <> FND_API.G_MISS_CHAR AND
        ( p_create_update_flag = 'C' OR
          ( p_create_update_flag = 'U'  AND
            p_customer_profile_rec.status <> NVL( l_status, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'status',
            p_lookup_type                           => 'CODE_STATUS',
            p_column_value                          => p_customer_profile_rec.status,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status is lookup code in lookup type CODE_STATUS. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after status ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate dunning_letters
    ----------------------------------------------

    -- dunning_letters is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the dunning_letters can be null or G_MISS during
    -- creation and it will default to dunning_letters of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'dunning_letters',
        p_column_value                           => p_customer_profile_rec.dunning_letters,
        x_return_status                          => x_return_status );
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'dunning_letters is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- dunning_letters is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.dunning_letters IS NOT NULL AND
       p_customer_profile_rec.dunning_letters <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.dunning_letters <> NVL( l_dunning_letters, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'dunning_letters',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.dunning_letters,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'dunning_letters is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after dunning_letters ... ' ||
      'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate interest_charges
    ----------------------------------------------

    -- interest_charges is mandatory field.

    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the interest_charges can be null or G_MISS during
    -- creation and it will default to interest_charges of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'interest_charges',
        p_column_value                           => p_customer_profile_rec.interest_charges,
        x_return_status                          => x_return_status );
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'interest_charges is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    -- interest_charges is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.interest_charges IS NOT NULL AND
       p_customer_profile_rec.interest_charges <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.interest_charges <> NVL( l_interest_charges, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'interest_charges',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.interest_charges,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'interest_charges is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after interest_charges ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate send_statements
    ----------------------------------------------

    -- send_statements is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the send_statements can be null or G_MISS during
    -- creation and it will default to send_statements of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'send_statements',
        p_column_value                           => p_customer_profile_rec.send_statements,
        x_return_status                          => x_return_status );

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'send_statements is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- send_statements is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.send_statements IS NOT NULL AND
       p_customer_profile_rec.send_statements <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.send_statements <> NVL( l_send_statements, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'send_statements',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.send_statements,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'send_statements is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after send_statements ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate credit_balance_statements
    ----------------------------------------------

    -- credit_balance_statements is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the credit_balance_statements can be null or G_MISS during
    -- creation and it will default to credit_balance_statements of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'credit_balance_statements',
        p_column_value                           => p_customer_profile_rec.credit_balance_statements,
        x_return_status                          => x_return_status );

   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_balance_statements is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- credit_balance_statements is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.credit_balance_statements IS NOT NULL AND
       p_customer_profile_rec.credit_balance_statements <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'credit_balance_statements',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.credit_balance_statements,
            x_return_status                         => x_return_status );
 
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_balance_statements is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after credit_balance_statements ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate credit_hold
    ----------------------------------------------

    -- credit_hold is mandatory field.
  
    -- Since we are defaulting to default profile class if profile_class_id 
    -- has not been passed in, the credit_hold can be null or G_MISS during
    -- creation and it will default to credit_hold of default profile class if
    -- it is NULL. We can have G_MISS checking to make it mandatory.

    check_partial_mandatory_column (
        p_column                                 => 'credit_hold',
        p_column_value                           => p_customer_profile_rec.credit_hold,
        x_return_status                          => x_return_status );
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_hold is mandatory : it can be null but not G_MISS. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- credit_hold is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.credit_hold IS NOT NULL AND
       p_customer_profile_rec.credit_hold <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'credit_hold',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_customer_profile_rec.credit_hold,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_hold is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after credit_hold ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_customer_profile_rec.created_by_module,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_customer_profile_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after created_by_module ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_customer_profile_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_customer_profile_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value.' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after application_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ------------------------------------------
    ----*** Select fields to validate  ***----
    ------------------------------------------
      IF  p_customer_profile_rec.profile_class_id IS NOT NULL AND
          p_customer_profile_rec.profile_class_id <> FND_API.G_MISS_NUM 
      THEN

          SELECT * INTO l_profile_class_rec
          FROM     HZ_CUST_PROFILE_CLASSES
          WHERE    PROFILE_CLASS_ID = p_customer_profile_rec.profile_class_id;

      END IF;
   
    ------------------------------------------
    ---***  Account Status Validation   ***---
    ------------------------------------------
   IF p_customer_profile_rec.account_status IS NOT NULL AND
      p_customer_profile_rec.account_status <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.account_status <> NVL( l_account_status, FND_API.G_MISS_CHAR ) ) )
   THEN
        validate_lookup (
            p_column                   => 'account_status',
            p_lookup_type              => 'ACCOUNT_STATUS',
            p_column_value             => p_customer_profile_rec.account_status,
            x_return_status            => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'account_status is lookup code in lookup type ACCOUNT_STATUS.' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate account_status ... ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;


    ---------------------------------------
    ------***Tolerance Validation ***------
    ---------------------------------------
   IF p_customer_profile_rec.tolerance IS NOT NULL AND
      p_customer_profile_rec.tolerance <> FND_API.G_MISS_NUM
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.tolerance <> NVL( l_tolerance, FND_API.G_MISS_NUM ) ) )
   THEN
       IF p_customer_profile_rec.tolerance > 100  OR
          p_customer_profile_rec.tolerance < -100 
       THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VALUE_BETWEEN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN','tolerance');
            FND_MESSAGE.SET_TOKEN( 'VALUE1', '-100' );
            FND_MESSAGE.SET_TOKEN( 'VALUE2', '100' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
           IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'Tolerance should be between -100 and 100 .' ||
                         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

       END IF;
   END IF;
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate tolerance ... ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -------------------------------------------------
    ---***   Validating Percent_Collectable    ***---
    -------------------------------------------------
   IF  p_customer_profile_rec.percent_collectable IS NOT NULL AND
       p_customer_profile_rec.percent_collectable <> FND_API.G_MISS_NUM
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.percent_collectable <> NVL( l_percent_collectable, FND_API.G_MISS_NUM ) ) )
   THEN
       IF p_customer_profile_rec.percent_collectable > 100 OR
          p_customer_profile_rec.percent_collectable < 0 
       THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VALUE_BETWEEN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN','percent_collectable');
            FND_MESSAGE.SET_TOKEN( 'VALUE1', '0' );
            FND_MESSAGE.SET_TOKEN( 'VALUE2', '100' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
            
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'Percent_Collectable should be between 0 and 100 .' ||
                      'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

        END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate percent_collectable ... ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

  
    -----------------------------------------
    ---***  Validating Override_Terms  ***---
    -----------------------------------------
    -- override_terms is lookup code in lookup type YES/NO
    IF p_customer_profile_rec.override_terms IS NOT NULL AND
       p_customer_profile_rec.override_terms <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.override_terms <> NVL( l_override_terms, FND_API.G_MISS_CHAR) ) )
    THEN
        validate_lookup (
            p_column                   => 'override_terms',
            p_lookup_type              => 'YES/NO',
            p_column_value             => p_customer_profile_rec.override_terms,
            x_return_status            => x_return_status );

        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'override_terms is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after override_terms ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


     ----------------------------------------------
     ---***Validating lockbox_matching_option***---
     ----------------------------------------------
     IF p_customer_profile_rec.lockbox_matching_option IS NOT NULL AND
        p_customer_profile_rec.lockbox_matching_option <> FND_API.G_MISS_CHAR
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.lockbox_matching_option <> NVL( l_lockbox_matching_option, FND_API.G_MISS_CHAR) ) )
     THEN
        validate_lookup (
            p_column          => 'lockbox_matching_option',
            p_lookup_type     => 'ARLPLB_MATCHING_OPTION',
            p_column_value    => p_customer_profile_rec.lockbox_matching_option,
            x_return_status   => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'lockbox_matching_option is lookup code in lookup type 
               ARLPLB_MATCHING_OPTION.' ||'x_return_status = ' || 
               x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

    END IF;
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate lockbox_matching_option ... ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

      
      --------------------------------------------
      --*** Validating autocash_hierarchy_id***---
      --------------------------------------------
    IF p_customer_profile_rec.autocash_hierarchy_id IS NOT NULL AND
        p_customer_profile_rec.autocash_hierarchy_id <> FND_API.G_MISS_NUM
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.autocash_hierarchy_id <> NVL( l_autocash_hierarchy_id, FND_API.G_MISS_NUM) ) )
    THEN
        check_auto_hierid_fk (
           p_column             => 'autocash_hierarchy_id',
           p_column_value       => p_customer_profile_rec.autocash_hierarchy_id,
           x_return_status      => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'autocash_hierarchy_id is foreign key to 
                   ar_autocash_hierarchies. ' || 'x_return_status = ' || 
                   x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate autocash_hierarchy_id ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

  
     ---------------------------------------------------------
     -----*** Validating autocash_hierarchy_id_for_adr***-----
     ---------------------------------------------------------
   IF p_customer_profile_rec.autocash_hierarchy_id_for_adr IS NOT NULL AND
      p_customer_profile_rec.autocash_hierarchy_id_for_adr <> FND_API.G_MISS_NUM
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.autocash_hierarchy_id_for_adr<> NVL( l_autocash_hierarchy_id_for_ad, FND_API.G_MISS_NUM) ) )
   THEN
     check_auto_hierid_fk (
        p_column       => 'autocash_hierarchy_id_for_adr',
        p_column_value => p_customer_profile_rec.autocash_hierarchy_id_for_adr,
        x_return_status=> x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'autocash_hierarchy_id_for_adr is foreign key to 
                   ar_autocash_hierarchies . ' || 'x_return_status = ' || 
                   x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate autocash_hierarchy_id_for_adr ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

     --------------------------------------------
     ---*** Validating statement_cycle_id  ***---
     --------------------------------------------
     IF p_customer_profile_rec.statement_cycle_id IS NOT NULL AND
        p_customer_profile_rec.statement_cycle_id <> FND_API.G_MISS_NUM
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.statement_cycle_id <> NVL( l_statement_cycle_id, FND_API.G_MISS_NUM) ) )
     THEN
          check_stat_cycid_fk (
           p_column             => 'statement_cycle_id',
           p_column_value       => p_customer_profile_rec.statement_cycle_id,
           x_return_status      => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'statement_cycle_id is foreign key to 
             ar_statement_cycles . ' || 'x_return_status = ' || 
             x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate statement_cycle_id ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ---------------------------------------------
    --------------*** Clearing Days***-----------
    ---------------------------------------------
   IF p_customer_profile_rec.clearing_days IS NOT NULL            AND
      p_customer_profile_rec.clearing_days <> FND_API.G_MISS_NUM 
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.clearing_days <> NVL( l_clearing_days, FND_API.G_MISS_NUM) ) )
   THEN
     -- Error
       check_positive_value (
           p_column             => 'clearing_days',
           p_column_value       => p_customer_profile_rec.clearing_days,
           x_return_status      => x_return_status );
    
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'clearing_days should be > 0.' ||'x_return_status = ' ||
                  x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


   END IF;
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate clearing_days... ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

    ---------------------------------------------
    ------------*** Payment_grace_days***--------
    ---------------------------------------------
   IF p_customer_profile_rec.payment_grace_days IS NOT NULL            AND
      p_customer_profile_rec.payment_grace_days <> FND_API.G_MISS_NUM 
       AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.payment_grace_days <> NVL( l_payment_grace_days, FND_API.G_MISS_NUM) ) )
   THEN
       check_positive_value (
           p_column             => 'payment_grace_days',
           p_column_value       => p_customer_profile_rec.payment_grace_days,
           x_return_status      => x_return_status );
    
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'payment_grace_days should be > 0.' ||'x_return_status = ' ||
                  x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

   END IF;
      
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate payment_grace_days... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;


    ---------------------------------------------
    -----------***Interest_period_day***---------
    ---------------------------------------------
   IF p_customer_profile_rec.interest_period_days IS NOT NULL            AND
      p_customer_profile_rec.interest_period_days <> FND_API.G_MISS_NUM
   THEN
       check_greater_than_zero (
           p_column             => 'interest_period_days',
           p_column_value       => p_customer_profile_rec.interest_period_days,
           x_return_status      => x_return_status );
    
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'interest_period_days should be > 0.' ||'x_return_status = ' ||
                x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

   END IF;
      
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate interest_period_days... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;


     --------------------------------------------
     ---***Validating dunning_letter_set_id***---
     --------------------------------------------
 IF p_customer_profile_rec.dunning_letter_set_id IS NOT NULL AND
    p_customer_profile_rec.dunning_letter_set_id <> FND_API.G_MISS_NUM
 THEN
     check_dunning_letid_fk (
           p_column             => 'dunning_letter_set_id',
           p_column_value       => p_customer_profile_rec.dunning_letter_set_id,
           x_return_status      => x_return_status );
     
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'dunning_letter_set_id is foreign key to 
                ar_dunning_letter_sets . ' || 'x_return_status = ' || 
                x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

 END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate dunning_letter_set_id ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

     --------------------------------------------
     ---*** Validating tax_printing_option ***---
     --------------------------------------------
     IF p_customer_profile_rec.tax_printing_option IS NOT NULL AND
        p_customer_profile_rec.tax_printing_option <> FND_API.G_MISS_CHAR
        AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
         p_customer_profile_rec.tax_printing_option <> NVL( l_tax_printing_option, FND_API.G_MISS_CHAR ) ))
     THEN
        validate_lookup (
            p_column          => 'tax_printing_option',
            p_lookup_type     => 'TAX_PRINTING_OPTION',
            p_column_value    => p_customer_profile_rec.tax_printing_option,
            x_return_status   => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'tax_printing_option is lookup code in lookup type 
                  TAX_PRINTING_OPTION.' ||'x_return_status = ' || 
                  x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

     END IF;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate tax_printing_option ... ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;


     ----------------------------------------
     ----***  Validating standard_terms***---
     ----------------------------------------
 IF p_customer_profile_rec.standard_terms IS NOT NULL AND
    p_customer_profile_rec.standard_terms <> FND_API.G_MISS_NUM
        AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
         p_customer_profile_rec.standard_terms <> NVL( l_standard_terms, FND_API.G_MISS_NUM ) ))
 THEN
       check_standard_terms_fk (
           p_column             => 'standard_terms',
           p_column_value       => p_customer_profile_rec.standard_terms,
           x_return_status      => x_return_status );
    
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'standard_terms is foreign key to ra_terms . ' || 
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

 END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate standard_terms ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    
     -------------------------------------------
     ---*** Validating grouping_rule_id   ***---
     -------------------------------------------
 IF p_customer_profile_rec.grouping_rule_id IS NOT NULL AND
    p_customer_profile_rec.grouping_rule_id <> FND_API.G_MISS_NUM
        AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
         p_customer_profile_rec.grouping_rule_id <> NVL( l_grouping_rule_id, FND_API.G_MISS_NUM ) ))

 THEN
     check_grouping_ruleid_fk (
           p_column             => 'grouping_rule_id',
           p_column_value       => p_customer_profile_rec.grouping_rule_id,
           x_return_status      => x_return_status );
    
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'grouping_rule_id is foreign key to ra_grouping_rules  . ' || 
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

 END IF;

 IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate grouping_rule_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
 END IF;

    -------------------------------------------------
    ------------*** Discount_grace_days **---------------
    -------------------------------------------------
IF v_customer_profile_rec.discount_grace_days IS NOT NULL AND
   v_customer_profile_rec.discount_grace_days <> FND_API.G_MISS_NUM 
        AND ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
         p_customer_profile_rec.discount_grace_days <> NVL( l_discount_grace_days, FND_API.G_MISS_NUM ) ))
THEN
    check_positive_value (
           p_column             => 'discount_grace_days',
           p_column_value       => v_customer_profile_rec.discount_grace_days,
           x_return_status      => x_return_status );
   
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'discount_grace_days should be > 0.' ||'x_return_status = ' ||
             x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

END IF;     

IF p_create_update_flag = 'C' OR 
   (p_create_update_flag = 'U' AND
   v_customer_profile_rec.profile_class_id IS NOT NULL AND
   v_customer_profile_rec.profile_class_id <> FND_API.G_MISS_NUM)
THEN

   IF v_customer_profile_rec.discount_terms IS  NULL THEN
      v_customer_profile_rec.discount_terms := 
      l_profile_class_rec.discount_terms;
   END IF;
   
   IF v_customer_profile_rec.discount_grace_days IS NULL AND 
      v_customer_profile_rec.discount_terms = 'Y' 
   THEN

      v_customer_profile_rec.discount_grace_days := 
      l_profile_class_rec.discount_grace_days;
   END IF;
END IF;

IF p_create_update_flag = 'U' AND 
   v_customer_profile_rec.profile_class_id  IS NULL THEN
   IF v_customer_profile_rec.discount_terms IS NULL 
   THEN
      v_customer_profile_rec.discount_terms := l_discount_terms;
   END IF;
   IF v_customer_profile_rec.discount_grace_days IS NULL THEN
      v_customer_profile_rec.discount_grace_days := l_discount_grace_days;
   END IF;
END IF;


 IF v_customer_profile_rec.discount_terms = 'N' OR 
    v_customer_profile_rec.discount_terms is NULL 
 THEN 
      IF v_customer_profile_rec.discount_grace_days >= 0 AND
         v_customer_profile_rec.discount_grace_days <> FND_API.G_MISS_NUM 
      THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN1', 'discount_terms' );
            FND_MESSAGE.SET_TOKEN( 'VALUE1', 'N' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN2', 'discount_grace_days'); 
            FND_MESSAGE.SET_TOKEN( 'VALUE2', 'NULL' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
 
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'discount_grace_days should be null when discount_terms is N.' ||
                 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

      END IF;
 END IF;

 IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate discount_terms ... ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
 END IF;


     -----------------------------------------------------------
     ------------*** dunning_letters ***------------------------
     ----------------------------------------------------------
 
IF p_create_update_flag = 'C' OR 
   (p_create_update_flag = 'U' AND
   v_customer_profile_rec.profile_class_id IS NOT NULL AND
   v_customer_profile_rec.profile_class_id <> FND_API.G_MISS_NUM)
THEN
   IF v_customer_profile_rec.dunning_letters IS NULL THEN
      v_customer_profile_rec.dunning_letters := 
      l_profile_class_rec.dunning_letters;
   END IF;
   /* Bug Fix:2884220  Added "v_customer_profile_rec.dunning_letters='Y'" Condition 
                       when initializing dunning_letter_set_id from hz_cust_profile_classes.
   */
   IF v_customer_profile_rec.dunning_letters='Y' and
      v_customer_profile_rec.dunning_letter_set_id IS  NULL THEN
      v_customer_profile_rec.dunning_letter_set_id := 
      l_profile_class_rec.dunning_letter_set_id;
   END IF;
END IF;

IF p_create_update_flag = 'U' AND
   v_customer_profile_rec.profile_class_id IS NULL 
THEN
   IF v_customer_profile_rec.dunning_letters IS NULL THEN
      v_customer_profile_rec.dunning_letters := l_dunning_letters;
   END IF;
   IF v_customer_profile_rec.dunning_letter_set_id IS NULL THEN
      v_customer_profile_rec.dunning_letter_set_id := l_dunning_letter_set_id;
   END IF;
END IF;


 IF v_customer_profile_rec.dunning_letters = 'Y' 
 THEN
     IF v_customer_profile_rec.dunning_letter_set_id = FND_API.G_MISS_NUM OR
        v_customer_profile_rec.dunning_letter_set_id IS NULL 
     THEN
       FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MAND_DEP_FIELDS' );
       FND_MESSAGE.SET_TOKEN('COLUMN1', 'dunning_letters');
       FND_MESSAGE.SET_TOKEN('VALUE1', 'Y');
       FND_MESSAGE.SET_TOKEN('COLUMN2','dunning_letter_set_id');
       FND_MSG_PUB.ADD;
       x_return_status := FND_API.G_RET_STS_ERROR;
         
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'dunning_letter_set_id cannot be NULL when dunning_letters is Y.' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
     END IF;

       END IF;
 END IF;

 IF v_customer_profile_rec.dunning_letters = 'N' OR
    v_customer_profile_rec.dunning_letters IS NULL  
 THEN
   IF v_customer_profile_rec.dunning_letter_set_id >= 0 AND 
      v_customer_profile_rec.dunning_letter_set_id <> FND_API.G_MISS_NUM 
   THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN('COLUMN1','dunning_letters');
            FND_MESSAGE.SET_TOKEN('VALUE1','N');
            FND_MESSAGE.SET_TOKEN('COLUMN2','dunning_letter_set_id');
            FND_MESSAGE.SET_TOKEN('VALUE2','NULL');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
            
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'dunning_letter_set_id should be NULL when dunning_letters is N.' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
 END IF;
  IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate duning_letters ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
  END IF;


------------------------------------------------
---------*** send_statements ***----------------
------------------------------------------------
 
IF p_create_update_flag = 'C' OR
   ( p_create_update_flag = 'U' AND 
   v_customer_profile_rec.profile_class_id is not null AND
   v_customer_profile_rec.profile_class_id <> FND_API.G_MISS_NUM ) 
THEN

   IF v_customer_profile_rec.send_statements IS  NULL   THEN
      v_customer_profile_rec.send_statements := 
      l_profile_class_rec.statements;
   END IF;
   /* Bug Fix:2884220  Added "v_customer_profile_rec.send_statements='Y'" Condition 
                       when initializing statement_cycle_id from hz_cust_profile_classes.
   */
   IF v_customer_profile_rec.send_statements='Y' and 
      v_customer_profile_rec.statement_cycle_id IS NULL THEN
      v_customer_profile_rec.statement_cycle_id := 
      l_profile_class_rec.statement_cycle_id;
   END IF;
   IF v_customer_profile_rec.credit_balance_statements IS NULL THEN
      v_customer_profile_rec.credit_balance_statements := 
      l_profile_class_rec.credit_balance_statements;
   END IF;

END IF;

IF p_create_update_flag = 'U' AND 
   v_customer_profile_rec.profile_class_id is null 
THEN
   IF v_customer_profile_rec.send_statements IS NULL   THEN
      v_customer_profile_rec.send_statements := l_send_statements;
   END IF;
   IF v_customer_profile_rec.statement_cycle_id IS NULL THEN
      v_customer_profile_rec.statement_cycle_id := l_statement_cycle_id;
   END IF;
   IF v_customer_profile_rec.credit_balance_statements IS NULL THEN
      v_customer_profile_rec.credit_balance_statements := l_credit_balance_statements;
   END IF;
END IF;

IF v_customer_profile_rec.send_statements = 'Y' THEN
      IF v_customer_profile_rec.statement_cycle_id = FND_API.G_MISS_NUM OR
         v_customer_profile_rec.statement_cycle_id IS NULL 
      THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MAND_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN1','send_statements');
            FND_MESSAGE.SET_TOKEN( ' VALUE1','Y');
            FND_MESSAGE.SET_TOKEN( 'COLUMN2','statement_cycle_id');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;

            IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'statement_cycle_id cannot be NULL when send_statements
                   is Y.' || 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

       END IF;
       IF  v_customer_profile_rec.credit_balance_statements IS NULL THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MAND_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN1','send_statements');
            FND_MESSAGE.SET_TOKEN( ' VALUE1','Y');
            FND_MESSAGE.SET_TOKEN( 'COLUMN2','credit_balance_statements');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
           
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'credit_balance_statements cannot be NULL when 
                  send_statements is Y .' || 'x_return_status = ' || 
                  x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF; 
END IF;

IF v_customer_profile_rec.send_statements = 'N' OR 
      v_customer_profile_rec.send_statements IS NULL 
THEN 
        IF v_customer_profile_rec.statement_cycle_id >= 0 AND 
           v_customer_profile_rec.statement_cycle_id <> FND_API.G_MISS_NUM 
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN('COLUMN1', 'send_statements');
            FND_MESSAGE.SET_TOKEN('VALUE1', 'N');
            FND_MESSAGE.SET_TOKEN('COLUMN2','statement_cycle_id');
            FND_MESSAGE.SET_TOKEN('VALUE2', 'NULL');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
     
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'statement_cycle_id should be NULL when send_statements
                      is N .' || 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
        IF v_customer_profile_rec.credit_balance_statements <> 'N' AND
           v_customer_profile_rec.credit_balance_statements IS NOT NULL
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN('COLUMN1','send_statements');
            FND_MESSAGE.SET_TOKEN('VALUE1','N');
            FND_MESSAGE.SET_TOKEN('COLUMN2','credit_balance_statements');
            FND_MESSAGE.SET_TOKEN('VALUE2','N');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;       
       
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'credit_balance_statements should be N when send_statements
                     is N .' || 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate send_statements ... ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


       
    --------------------------------------------------
    ------------*** interest_charges ***--------------
    --------------------------------------------------
 
IF p_create_update_flag = 'C' OR
   ( p_create_update_flag = 'U' AND 
     v_customer_profile_rec.profile_class_id is not null AND
     v_customer_profile_rec.profile_class_id <> FND_API.G_MISS_NUM ) 
THEN

   IF v_customer_profile_rec.interest_charges  IS NULL   THEN
      v_customer_profile_rec.interest_charges := 
      l_profile_class_rec.interest_charges;
   END IF;
   /* Bug Fix:2884220  Added "v_customer_profile_rec.interest_charges='Y'" Condition 
                       when initializing interest_period_days from hz_cust_profile_classes.
   */
   IF v_customer_profile_rec.interest_charges='Y' and
       v_customer_profile_rec.interest_period_days IS NULL THEN
      v_customer_profile_rec.interest_period_days := 
      l_profile_class_rec.interest_period_days;
   END IF;
   IF v_customer_profile_rec.charge_on_finance_charge_flag IS  NULL THEN
      v_customer_profile_rec.charge_on_finance_charge_flag := 
      l_profile_class_rec.charge_on_finance_charge_flag;
   END IF;

END IF;

IF p_create_update_flag = 'U' AND 
   v_customer_profile_rec.profile_class_id is null 
THEN
   IF v_customer_profile_rec.interest_charges  IS NULL  THEN
      v_customer_profile_rec.interest_charges := l_interest_charges;
   END IF;
   IF v_customer_profile_rec.interest_period_days IS NULL THEN
      v_customer_profile_rec.interest_period_days := l_interest_period_days;
   END IF;
   IF v_customer_profile_rec.charge_on_finance_charge_flag IS NULL THEN
      v_customer_profile_rec.charge_on_finance_charge_flag := 
      l_finance_charge_flag;
   END IF;
END IF;

IF v_customer_profile_rec.interest_charges = 'Y' THEN
      IF v_customer_profile_rec.interest_period_days = FND_API.G_MISS_NUM OR
         v_customer_profile_rec.interest_period_days IS  NULL 
      THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_INT_CHARGES_Y' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'interest_period_days cannot be NULL when interest_charges is Y.' || 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

       END IF;
    /* Commented the mandatory check for 2125994.
        validate_mandatory (
            p_create_update_flag     => p_create_update_flag,
            p_column                 => 'charge_on_finance_charge_flag',
            p_column_value           => v_customer_profile_rec.charge_on_finance_charge_flag,
            x_return_status          => x_return_status );
    

        IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'charge_on_finance_charge_flag is mandatory. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;
    */
END IF;
IF v_customer_profile_rec.interest_charges = 'N' OR 
   v_customer_profile_rec.interest_charges IS NULL 
THEN
       IF v_customer_profile_rec.interest_period_days >= 0 AND 
          v_customer_profile_rec.interest_period_days <> FND_API.G_MISS_NUM 
       THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN1','interest_charges');
            FND_MESSAGE.SET_TOKEN( 'VALUE1','N');
            FND_MESSAGE.SET_TOKEN( 'COLUMN2','interest_period_days');
            FND_MESSAGE.SET_TOKEN( 'VALUE2','NULL');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
      
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'Interest_period_days should be NULL when interest_charges
                     is N .' || 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
        IF v_customer_profile_rec.charge_on_finance_charge_flag  = 'Y' 
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_DEP_FIELDS' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN1','interest_charges');
            FND_MESSAGE.SET_TOKEN( 'VALUE1','N');
            FND_MESSAGE.SET_TOKEN( 'COLUMN2','charge_on_finance_charge_flag');
            FND_MESSAGE.SET_TOKEN( 'VALUE2','N');
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;      
     
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'charge_on_finance_charge_flag cannot be Y when 
                  interest_charges is N .' || 'x_return_status ='
                  || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
END IF;
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate interest_charges ... ' ||
                 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

-----------------------------------------------------------------------
--                          Credit_classification
-----------------------------------------------------------------------
-- Validate lookup_code of the CREDIT_CLASSIFICATION
    IF p_customer_profile_rec.credit_classification IS NOT NULL AND
       p_customer_profile_rec.credit_classification <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_customer_profile_rec.credit_classification <> NVL( l_credit_classification, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'credit_classification',
            p_lookup_table                          => 'AR_LOOKUPS',
            p_lookup_type                           => 'AR_CMGT_CREDIT_CLASSIFICATION', 
            p_column_value                          => p_customer_profile_rec.credit_classification,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'credit_classification is lookup code in lookup type AR_CMGT_CREDIT_CLASSIFICATION in ar_lookups. ' ||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;


    END IF;


    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_customer_profile (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_customer_profile;

/**
 * PROCEDURE validate_cust_profile_amt
 *
 * DESCRIPTION
 *     Validates customer profile amount record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_check_foreign_key            If do foreign key checking on cust_account_id
 *                                    and cust_account_profile_id or not.
 *     p_cust_profile_amt_rec         Customer profile amount record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   11-08-2001    P.Suresh            * Bug Fix : 2001573. Validated overall_credit_limit. 
 *                                       It should be greater or equal to trx_credit_limit.  
 *
 */

PROCEDURE validate_cust_profile_amt (
    p_create_update_flag                    IN     VARCHAR2,
    p_check_foreign_key                     IN     VARCHAR2,
    p_cust_profile_amt_rec                  IN     HZ_CUSTOMER_PROFILE_V2PUB.CUST_PROFILE_AMT_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_cust_profile_amt'

    l_dummy                                 VARCHAR2(1);

    l_cust_account_id                       NUMBER;
    l_site_use_id                           NUMBER;
    l_cust_account_profile_id               NUMBER;
    l_currency_code                         HZ_CUST_PROFILE_AMTS.currency_code%TYPE;
    l_created_by_module                     HZ_CUST_PROFILE_AMTS.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_overall_credit_limit                  HZ_CUST_PROFILE_AMTS.OVERALL_CREDIT_LIMIT%TYPE;
    l_trx_credit_limit                      HZ_CUST_PROFILE_AMTS.TRX_CREDIT_LIMIT%TYPE;

BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_profile_amt (+)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT CUST_ACCOUNT_ID, SITE_USE_ID, 
               CUST_ACCOUNT_PROFILE_ID, CURRENCY_CODE,
               CREATED_BY_MODULE, APPLICATION_ID,
               OVERALL_CREDIT_LIMIT,TRX_CREDIT_LIMIT
        INTO l_cust_account_id, l_site_use_id,
             l_cust_account_profile_id, l_currency_code,
             l_created_by_module, l_application_id,
        l_overall_credit_limit,l_trx_credit_limit
        FROM HZ_CUST_PROFILE_AMTS
        WHERE ROWID = p_rowid;
    END IF;

    --------------------------------------
    -- validate cust_acct_profile_amt_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.
 
        IF p_cust_profile_amt_rec.cust_acct_profile_amt_id IS NOT NULL AND
           p_cust_profile_amt_rec.cust_acct_profile_amt_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_PROFILE_AMTS
            WHERE CUST_ACCT_PROFILE_AMT_ID = p_cust_profile_amt_rec.cust_acct_profile_amt_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_acct_profile_amt_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_profile_amt_id is unique during creation if passed in. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
        END IF;
    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_acct_profile_amt_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate cust_account_profile_id
    ----------------------------------------------

    -- cust_account_profile_id is mandatory field
    -- Since cust_account_profile_id is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_account_profile_id',
            p_column_value                          => p_cust_profile_amt_rec.cust_account_profile_id,
            x_return_status                         => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_profile_id is mandatory. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_profile_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_profile_amt_rec.cust_account_profile_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_account_profile_id',
            p_column_value                          => p_cust_profile_amt_rec.cust_account_profile_id,
            p_old_column_value                      => l_cust_account_profile_id,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_profile_id is non-updateable. ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_profile_id is foreign key to hz_customer_profiles
    -- Since cust_account_profile_id is mandatory and non-updateable,
    -- we only need to check FK during creation.

 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_profile_id = ' || p_cust_profile_amt_rec.cust_account_profile_id || ' ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    IF p_create_update_flag = 'C' AND
       p_check_foreign_key = FND_API.G_TRUE AND 
       p_cust_profile_amt_rec.cust_account_profile_id IS NOT NULL AND
       p_cust_profile_amt_rec.cust_account_profile_id <> FND_API.G_MISS_NUM
    THEN
    BEGIN
        -- select cust_account_id, site_use_id for later cross reference checking

        SELECT CUST_ACCOUNT_ID, SITE_USE_ID INTO l_cust_account_id, l_site_use_id
        FROM HZ_CUSTOMER_PROFILES
        WHERE CUST_ACCOUNT_PROFILE_ID = p_cust_profile_amt_rec.cust_account_profile_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
            FND_MESSAGE.SET_TOKEN( 'FK', 'cust_account_profile_id' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_profile_id' );
            FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_customer_profiles' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
    END;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_profile_id is foreign key to hz_customer_profiles. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_profile_id ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate cust_account_id
    ----------------------------------------------

    -- cust_account_id is mandatory field
    -- Since cust_account_id is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_account_id',
            p_column_value                          => p_cust_profile_amt_rec.cust_account_id,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is mandatory. ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_profile_amt_rec.cust_account_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_account_id',
            p_column_value                          => p_cust_profile_amt_rec.cust_account_id,
            p_old_column_value                      => l_cust_account_id,
            x_return_status                         => x_return_status );
  
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is non-updateable. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_id is foreign key to hz_cust_accounts
    -- Since cust_account_id is mandatory and non-updateable,
    -- we only need to check FK during creation.

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id = ' || p_cust_profile_amt_rec.cust_account_id || ' ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    IF p_create_update_flag = 'C' AND
       p_check_foreign_key = FND_API.G_TRUE AND
       p_cust_profile_amt_rec.cust_account_id IS NOT NULL AND
       p_cust_profile_amt_rec.cust_account_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_account_fk (
            p_column                                 => 'cust_account_id',
            p_column_value                           => p_cust_profile_amt_rec.cust_account_id,
            x_return_status                          => x_return_status );
 
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is foreign key to hz_cust_accounts. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

        -- cross reference checking

        IF p_cust_profile_amt_rec.cust_account_id <> l_cust_account_id THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_PROF_AMT_IDS_MISMATCH' );
            FND_MESSAGE.SET_TOKEN( 'ENTITY', 'customer' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id should be the same as cust_account_id in corresponding customer profile. ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;    

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_id ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate currency_code
    ----------------------------------------------

    -- currency_code is mandatory field
    -- Since currency_code is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'currency_code',
            p_column_value                          => p_cust_profile_amt_rec.currency_code,
            x_return_status                         => x_return_status );
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'currency_code is mandatory. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- currency_code is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_profile_amt_rec.currency_code IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'currency_code',
            p_column_value                          => p_cust_profile_amt_rec.currency_code,
            p_old_column_value                      => l_currency_code,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'currency_code is non-updateable. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    -- currency_code is foreign key to fnd_currencies
    -- Since currency_code is mandatory and non-updateable,
    -- we only need to check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_profile_amt_rec.currency_code IS NOT NULL AND
       p_cust_profile_amt_rec.currency_code <> FND_API.G_MISS_CHAR
    THEN
        check_currency_fk (
            p_column                                => 'currency_code',
            p_column_value                          => p_cust_profile_amt_rec.currency_code,
            x_return_status                         => x_return_status );
 
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'currency_code is foreign key to fnd_currencies. ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- For a given cust_account_profile_id and currency_code, only one
    -- record of the profile amount is allowed.
    -- Since cust_account_profile_id and currency_code are mandatory
    -- and non-updateable columns, we only need to do the checking
    -- during creation.

    IF p_create_update_flag = 'C' THEN
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_CUST_PROFILE_AMTS
        WHERE CUST_ACCOUNT_PROFILE_ID = p_cust_profile_amt_rec.cust_account_profile_id
        AND CURRENCY_CODE = p_cust_profile_amt_rec.currency_code
        AND ROWNUM = 1;

        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_profile_id - currency_code' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'for a given cust_account_profile_id and currency_code, only one record of the profile amount is allowed. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    END IF;
 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate currency_code ... ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate site_use_id
    ----------------------------------------------

    -- site_use_id is non-updateable field
    IF p_create_update_flag = 'U' AND 
       p_cust_profile_amt_rec.site_use_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'site_use_id',
            p_column_value                          => p_cust_profile_amt_rec.site_use_id,
            p_old_column_value                      => l_site_use_id,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_id is non-updateable. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
    END IF;

    -- site_use_id is foreign key to hz_cust_site_uses
    -- Since site_use_id is non-updateable, we only need to 
    -- check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_check_foreign_key = FND_API.G_TRUE  
    THEN
        IF p_cust_profile_amt_rec.site_use_id IS NOT NULL AND
           p_cust_profile_amt_rec.site_use_id <> FND_API.G_MISS_NUM
        THEN
            check_cust_site_use_fk (
                p_column                                 => 'site_use_id',
                p_column_value                           => p_cust_profile_amt_rec.site_use_id,
                x_return_status                          => x_return_status );
    
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_id is foreign key to hz_cust_site_uses. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
        END IF;

        -- cross reference checking

        IF ( p_cust_profile_amt_rec.site_use_id IS NOT NULL
             AND p_cust_profile_amt_rec.site_use_id <> FND_API.G_MISS_NUM AND
             ( l_site_use_id IS NULL OR
               l_site_use_id <> p_cust_profile_amt_rec.site_use_id ) ) OR
           ( ( p_cust_profile_amt_rec.site_use_id IS NULL OR
               p_cust_profile_amt_rec.site_use_id = FND_API.G_MISS_NUM ) AND
             l_site_use_id IS NOT NULL )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_PROF_AMT_IDS_MISMATCH' );
            FND_MESSAGE.SET_TOKEN( 'ENTITY', 'site use' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_id should be the same as site_use_id site_use_id in corresponding customer profile. ' ||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate site_use_id ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_profile_amt_rec.created_by_module,
            x_return_status                         => x_return_status );
  
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_profile_amt_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_profile_amt_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=> '(+) after validate created_by_module ... ' ||
                     'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_profile_amt_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_cust_profile_amt_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate application_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
    
    ------------------------------------
    --*** Credit Limit Validations ***--
    ------------------------------------
   
    IF p_cust_profile_amt_rec.overall_credit_limit   <> FND_API.G_MISS_NUM  AND
       p_cust_profile_amt_rec.overall_credit_limit   IS NOT NULL 
    THEN
       IF  p_cust_profile_amt_rec.trx_credit_limit   <>  FND_API.G_MISS_NUM  AND
           p_cust_profile_amt_rec.trx_credit_limit   IS NOT NULL 
       THEN

        IF ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            (
        (p_cust_profile_amt_rec.overall_credit_limit <> NVL( l_overall_credit_limit, FND_API.G_MISS_NUM )) 
        OR  
        (p_cust_profile_amt_rec.trx_credit_limit <> NVL(l_trx_credit_limit,FND_API.G_MISS_NUM))
       )
      )
      )
        THEN
           IF p_cust_profile_amt_rec.overall_credit_limit < p_cust_profile_amt_rec.trx_credit_limit     
           THEN
              FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_VAL_OVERALL_CREDIT' );
              FND_MSG_PUB.ADD;
              x_return_status := FND_API.G_RET_STS_ERROR;
          
         IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'overall_credit_limit should be greater than the trx_credit_limit. ' ||
               'x_return_status = ' || x_return_status,
                          p_prefix =>l_debug_prefix,
                          p_msg_level=>fnd_log.level_statement);
         END IF;
           END IF; 
   END IF;
       END IF;
    END IF;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'Credit Limit Validation failure. Please check the overall_credit_limit and trx_credit_limit ' || 'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=> 'validate_cust_profile_amt (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;
  
    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_cust_profile_amt;

/**
 * PROCEDURE validate_cust_acct_site
 *
 * DESCRIPTION
 *     Validates customer account site record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_cust_acct_site_rec           Customer account site record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   10-25-2002    P.Suresh            o Bug No : 2528119. Added validation for ece_tp_location_code
 *                                       in validate_cust_acct_site procedure.
 *
 */

PROCEDURE validate_cust_acct_site (
    p_create_update_flag                    IN     VARCHAR2,
    p_cust_acct_site_rec                    IN     HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_cust_acct_site'

    l_dummy                                 VARCHAR2(1);
    l_rowid                                 ROWID := NULL;

    l_cust_account_id                       NUMBER;
    l_party_site_id                         NUMBER;
    l_orig_system_reference                 HZ_CUST_ACCT_SITES.orig_system_reference%TYPE;
    l_orig_system_reference1                 HZ_CUST_ACCOUNTS.orig_system_reference%TYPE;
    l_created_by_module                     HZ_CUST_ACCT_SITES.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_status                                HZ_CUST_ACCT_SITES.status%TYPE;
    l_customer_category_code                HZ_CUST_ACCT_SITES.customer_category_code%TYPE;
    l_count                                 NUMBER := 0;
    l_instr_length  number := 0;
    l_validate_flag varchar2(1) := 'Y';
    l_mosr_owner_table_id number;
    
BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_acct_site (+)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT CUST_ACCOUNT_ID, PARTY_SITE_ID, ORIG_SYSTEM_REFERENCE,
               CREATED_BY_MODULE, APPLICATION_ID, STATUS, CUSTOMER_CATEGORY_CODE
        INTO l_cust_account_id, l_party_site_id, l_orig_system_reference,
             l_created_by_module, l_application_id, l_status, l_customer_category_code
        FROM HZ_CUST_ACCT_SITES
        WHERE ROWID = p_rowid;
    END IF;

    --------------------------------------
    -- validate cust_acct_site_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.
 
        IF p_cust_acct_site_rec.cust_acct_site_id IS NOT NULL AND
           p_cust_acct_site_rec.cust_acct_site_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCT_SITES
            WHERE CUST_ACCT_SITE_ID = p_cust_acct_site_rec.cust_acct_site_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_acct_site_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        -- Debug info.
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id is unique during creation if passed in. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
        END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_acct_site_id ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate cust_account_id
    ----------------------------------------------

    -- cust_account_id is mandatory field
    -- Since cust_account_id is non-updateable filed, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_account_id',
            p_column_value                          => p_cust_acct_site_rec.cust_account_id,
            x_return_status                         => x_return_status );

        -- Debug info.
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'cust_account_id is mandatory. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_acct_site_rec.cust_account_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_account_id',
            p_column_value                          => p_cust_acct_site_rec.cust_account_id,
            p_old_column_value                      => l_cust_account_id,
            x_return_status                         => x_return_status );

        -- Debug info.
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'cust_account_id is non-updateable. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_id is foreign key of hz_cust_accounts
    -- Do not need to check during update because cust_account_id is
    -- non-updateable.
    IF p_create_update_flag = 'C' THEN
        IF p_cust_acct_site_rec.cust_account_id <> -1 AND
           p_cust_acct_site_rec.cust_account_id IS NOT NULL AND
           p_cust_acct_site_rec.cust_account_id <> FND_API.G_MISS_NUM
        THEN
            check_cust_account_fk (
                p_column                                 => 'cust_account_id',
                p_column_value                           => p_cust_acct_site_rec.cust_account_id,
                x_return_status                          => x_return_status );

            -- Debug info.
          
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'cust_account_id is foreign key of hz_cust_accounts. ' ||
                     'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
        END IF;
    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_id ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate party_site_id
    ----------------------------------------------

    -- party_site_id is mandatory field
    -- Since party_site_id is non-updateable filed, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'party_site_id',
            p_column_value                          => p_cust_acct_site_rec.party_site_id,
            x_return_status                         => x_return_status );

        -- Debug info.
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_site_id is mandatory. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- party_site_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_acct_site_rec.party_site_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'party_site_id',
            p_column_value                          => p_cust_acct_site_rec.party_site_id,
            p_old_column_value                      => l_party_site_id,
            x_return_status                         => x_return_status );

        -- Debug info.
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_site_id is non-updateable. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- party_site_id is foreign key of hz_party_sites
    -- Do not need to check during update because party_site_id is
    -- non-updateable.
    IF p_create_update_flag = 'C' AND
       p_cust_acct_site_rec.party_site_id IS NOT NULL AND
       p_cust_acct_site_rec.party_site_id <> FND_API.G_MISS_NUM
    THEN
        check_party_site_fk (
            p_column                                => 'party_site_id',
            p_column_value                          => p_cust_acct_site_rec.party_site_id,
            x_return_status                         => x_return_status );
           
        -- Debug info.
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_site_id is foreign key of hz_party_sites. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;



       -- Bug 2197181: Because of Mix-n-Match project, location from 3rd party content
       -- providers can now be used in the business flow. Therefore, removing restriction
       -- that the "party_site_id must link to a 'USER_ENTERED' location".

/*

        --- party_site_id must link to a 'USER_ENTERED' location
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_LOCATIONS
            WHERE LOCATION_ID = (
                SELECT LOCATION_ID
                FROM HZ_PARTY_SITES
                WHERE PARTY_SITE_ID = p_cust_acct_site_rec.party_site_id )
            AND CONTENT_SOURCE_TYPE = HZ_PARTY_V2PUB.G_MISS_CONTENT_SOURCE_TYPE;
        
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_LOC_CONTENT_INVALID' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
        END;

        -- Debug info.
        IF G_DEBUG THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                'party_site_id must link to a USER_ENTERED location. ' ||
                'x_return_status = ' || x_return_status, l_debug_prefix );
        END IF;

*/


        -- cust_account_id and party_site_id together should be unique.
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCT_SITES
            WHERE CUST_ACCOUNT_ID = p_cust_acct_site_rec.cust_account_id
            AND PARTY_SITE_ID = p_cust_acct_site_rec.party_site_id
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_id - party_site_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        -- Debug info.
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id and party_site_id together should be unique. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate party_site_id ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate orig_system_reference
    ----------------------------------------------

    -- orig_system_reference is unique. Since orig_system_refence is defaulting to
    -- primary key, we only need to check the uniqueness if user passes some value.
    -- database constraints can catch unique error when we defaulting.
    -- orig_system_reference is non-updateable, we only need to check uniqueness 
    -- during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_acct_site_rec.orig_system_reference IS NOT NULL AND
       p_cust_acct_site_rec.orig_system_reference <> FND_API.G_MISS_CHAR
    THEN
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_CUST_ACCT_SITES
        WHERE ORIG_SYSTEM_REFERENCE = p_cust_acct_site_rec.orig_system_reference;

        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'orig_system_reference' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- Debug info.
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'orig_system_reference is unique if passed in. ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;

    -- orig_system_reference is non-updateable field
    l_instr_length := instr(l_orig_system_reference,'#@');
    if l_instr_length > 0
    then
   l_orig_system_reference1 := null;
   if  substr(l_orig_system_reference,1,l_instr_length-1) <> p_cust_acct_site_rec.orig_system_reference
        then
      l_validate_flag := 'N';
   end if;
    else
   l_orig_system_reference1 := p_cust_acct_site_rec.orig_system_reference;
    end if;
   
   IF (p_cust_acct_site_rec.orig_system is not null and p_cust_acct_site_rec.orig_system <>fnd_api.g_miss_char) 
    and (p_cust_acct_site_rec.orig_system_reference is not null and p_cust_acct_site_rec.orig_system_reference <>fnd_api.g_miss_char) 
    and p_create_update_flag = 'U'
   then
   hz_orig_system_ref_pub.get_owner_table_id 
   (p_orig_system => p_cust_acct_site_rec.orig_system, 
   p_orig_system_reference => p_cust_acct_site_rec.orig_system_reference, 
   p_owner_table_name => 'HZ_CUST_ACCT_SITES_ALL',  
   x_owner_table_id => l_mosr_owner_table_id, 
   x_return_status => x_return_status); 
   IF x_return_status = fnd_api.g_ret_sts_success and l_mosr_owner_table_id= nvl(p_cust_acct_site_rec.cust_acct_site_id,l_mosr_owner_table_id)
   then
      l_validate_flag := 'N';
   end if;
    end if;
    -- orig_system_reference is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_acct_site_rec.orig_system_reference IS NOT NULL
       and l_validate_flag = 'Y' 
    THEN
        validate_nonupdateable (
            p_column                                => 'orig_system_reference',
            p_column_value                          => p_cust_acct_site_rec.orig_system_reference,
            p_old_column_value                      => l_orig_system_reference,
            x_return_status                         => x_return_status );

        -- Debug info.
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'orig_system_reference is non-updateable. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate orig_system_reference ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate tp_header_id
    --------------------------------------

    -- We have unique index on tp_header_id

    IF p_cust_acct_site_rec.tp_header_id IS NOT NULL AND
       p_cust_acct_site_rec.tp_header_id <> FND_API.G_MISS_NUM
    THEN
    BEGIN
        SELECT ROWID INTO l_rowid
        FROM HZ_CUST_ACCT_SITES_ALL
        WHERE TP_HEADER_ID = p_cust_acct_site_rec.tp_header_id;

        IF p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U' AND l_rowid <> p_rowid )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'tp_header_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'tp_header_id is unique if passed in. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate tp_header_id ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate status
    --------------------------------------

    -- status cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_cust_acct_site_rec.status IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'status', 
            p_column_value                          => p_cust_acct_site_rec.status,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status cannot be updated to null. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- status is lookup code in lookup type CODE_STATUS
    IF p_cust_acct_site_rec.status IS NOT NULL AND
       p_cust_acct_site_rec.status <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_cust_acct_site_rec.status <> NVL( l_status, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'status',
            p_lookup_type                           => 'CODE_STATUS',
            p_column_value                          => p_cust_acct_site_rec.status,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status is lookup code in lookup type CODE_STATUS. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate status ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate customer_category_code
    ----------------------------------------------

    -- customer_category_code is lookup code in lookup type ADDRESS_CATEGORY
    IF p_cust_acct_site_rec.customer_category_code IS NOT NULL AND
       p_cust_acct_site_rec.customer_category_code <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_cust_acct_site_rec.customer_category_code <> NVL( l_customer_category_code, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'customer_category_code',
            p_lookup_type                           => 'ADDRESS_CATEGORY',
            p_column_value                          => p_cust_acct_site_rec.customer_category_code,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'customer_category_code is lookup code in lookup type ADDRESS_CATEGORY. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate customer_category_code ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate language
    ----------------------------------------------

    -- language is foreign key of fnd installed languages
    IF p_cust_acct_site_rec.language IS NOT NULL AND
       p_cust_acct_site_rec.language <> FND_API.G_MISS_CHAR 
    THEN
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM FND_LANGUAGES
        WHERE LANGUAGE_CODE = p_cust_acct_site_rec.language
        AND INSTALLED_FLAG IN ('B', 'I')
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
            FND_MESSAGE.SET_TOKEN( 'FK', 'language' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'language_code' );
            FND_MESSAGE.SET_TOKEN( 'TABLE', 'fnd_languages(installed)' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
    END;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'language is foreign key of fnd installed languages. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate language ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate primary_specialist_id
    --------------------------------------

    -- primary_specialist_id is foreign key to per_all_people_f
    IF p_cust_acct_site_rec.primary_specialist_id IS NOT NULL AND
       p_cust_acct_site_rec.primary_specialist_id <> FND_API.G_MISS_NUM 
    THEN
        check_per_all_people_f_fk (
            p_column                                 => 'primary_specialist_id',
            p_column_value                           => p_cust_acct_site_rec.primary_specialist_id,
            x_return_status                          => x_return_status );
  
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_specialist_id is foreign key to per_all_people_f. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate primary_specialist_id ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate secondary_specialist_id
    --------------------------------------

    -- secondary_specialist_id is foreign key to per_all_people_f
    IF p_cust_acct_site_rec.secondary_specialist_id IS NOT NULL AND
       p_cust_acct_site_rec.secondary_specialist_id <> FND_API.G_MISS_NUM 
    THEN
    /* Bug 3591694 Changed foreign key validation from check_cust_account_fk to 
                   check_per_all_people_f_fk.
    */
    --   check_cust_account_fk (
         check_per_all_people_f_fk(
            p_column                                 => 'secondary_specialist_id',
            p_column_value                           => p_cust_acct_site_rec.secondary_specialist_id,
            x_return_status                          => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'secondary_specialist_id is foreign key to per_all_people_f. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate secondary_specialist_id ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_acct_site_rec.created_by_module,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_acct_site_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_acct_site_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
  
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate created_by_module ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_acct_site_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_cust_acct_site_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate application_id ... ' ||
        'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate ece_tp_location_code
    --------------------------------------
     IF p_create_update_flag = 'C' THEN
        IF p_cust_acct_site_rec.cust_account_id <> -1 AND
           p_cust_acct_site_rec.cust_account_id IS NOT NULL AND
           p_cust_acct_site_rec.cust_account_id <> FND_API.G_MISS_NUM
        THEN
          IF p_cust_acct_site_rec.ece_tp_location_code IS NOT NULL AND
             p_cust_acct_site_rec.ece_tp_location_code <> FND_API.G_MISS_CHAR
          THEN
             select  count(1)
             into    l_count
             from    hz_cust_acct_sites addr
             where   addr.cust_account_id        = p_cust_acct_site_rec.cust_account_id
             and     addr.ece_tp_location_code   = p_cust_acct_site_rec.ece_tp_location_code;

             IF l_count > 0 THEN
                FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ADDR_EDI_LOC_EXISTS' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
             END IF;
          END IF;
        END IF;
     ELSIF p_create_update_flag = 'U' THEN
        IF p_cust_acct_site_rec.ece_tp_location_code IS NOT NULL AND
           p_cust_acct_site_rec.ece_tp_location_code <> FND_API.G_MISS_CHAR
        THEN
             select  count(1)
             into    l_count
             from    hz_cust_acct_sites addr
             where   addr.cust_account_id        = l_cust_account_id
             and     addr.ece_tp_location_code   = p_cust_acct_site_rec.ece_tp_location_code
             and     addr.cust_acct_site_id      <> p_cust_acct_site_rec.cust_acct_site_id;

             IF l_count > 0 THEN
                FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ADDR_EDI_LOC_EXISTS' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
             END IF;
         END IF;
     END IF;
   
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'The ece_tp_location_code should be unique for a customer ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    -- Debug info.
  
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_acct_site (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_cust_acct_site;

/**
 * PROCEDURE validate_cust_site_use
 *
 * DESCRIPTION
 *     Validates customer account site use record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_cust_site_use_rec            Customer account site use record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   11-08-2001    Rajeshwari P          Added validations  for fields, tax_code,payment_term_id,
 *                                       demand_class_codeprimary_salesrep_id,finchrg_receivables_trx_id,
 *                                       order_type_id,order_type_id,ship_partial,item_cross_ref_pref,
 *                                       warehouse_id,date_type_preference,
 *                                       ship_sets_include_lines_flag and arrivalsets_include_lines_flag
 *                                       in procedure VALIDATE_CUST_SITE_USE.
 *   03-26-2002    P.Suresh              Bug No : 2266165. Added the check that bill_to_flag of
 *                                       hz_cust_acct_relate_all table should be Y when validating 
 *                                       bill_to_site_use_id.
 *   04-11-2002    P.Suresh              Bug No : 2260832. Added the check for the status
 *                                       when validating that only one primary is allowed for
 *                                       one site use type per account in the procedure
 *                                       validate_cust_site_use.
 *   21-05-2002   Rajeshwari P           Bug fix 2311760.Commented the code which validates the
 *                                       Obsolete column ship_partial.
 *   06-13-2002    P.Suresh              Bug No : 2403263. Added validation that the contact_id
 *                                       should be a foreign key to hz_cust_account_roles.
 *                                       cust_account_role_id.
 *   06-19-2002   Rajeshwari P           Bug 2399491.Validating site_use_id for duplicates
 *                                       against hz_cust_site_uses_all table instead of the
 *                                       org stripped view, hz_cust_site_uses.
 *   03-May-3004 Venkata Sowjanya S      Bug No : 3609601. Commented the statements which sets tokens Column1,Column2
 *                                        for message HZ_API_INACTIVE_CANNOT_PRIM 
 
 */

PROCEDURE validate_cust_site_use (
    p_create_update_flag                    IN     VARCHAR2,
    p_cust_site_use_rec                     IN     HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_SITE_USE_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_cust_site_use'

    l_dummy                                 VARCHAR2(1);
    l_profile                               AR_SYSTEM_PARAMETERS.auto_site_numbering%TYPE;

    l_cust_acct_site_id                     NUMBER;
    l_site_use_code                         HZ_CUST_SITE_USES.site_use_code%TYPE;
    l_cust_account_id                       NUMBER;
    l_orig_system_reference                 HZ_CUST_SITE_USES.orig_system_reference%TYPE;
    l_created_by_module                     HZ_CUST_SITE_USES.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_status                                HZ_CUST_SITE_USES.status%TYPE;
    l_ship_via                              HZ_CUST_SITE_USES.ship_via%TYPE;
    l_freight_term                          HZ_CUST_SITE_USES.freight_term%TYPE;
    l_ship_sets_inc_lines_f                 HZ_CUST_SITE_USES.ship_sets_include_lines_flag%TYPE;
    l_arrivalsets_inc_lines_f               HZ_CUST_SITE_USES.arrivalsets_include_lines_flag%TYPE;
    l_tax_code                             HZ_CUST_SITE_USES.tax_code%TYPE;
    l_payment_term_id                       HZ_CUST_SITE_USES.payment_term_id%TYPE;
    l_demand_class_code                     HZ_CUST_SITE_USES.demand_class_code%TYPE;
    l_primary_salesrep_id                   HZ_CUST_SITE_USES.primary_salesrep_id%TYPE;
    l_finchrg_receivables_trx_id     HZ_CUST_SITE_USES.FINCHRG_RECEIVABLES_TRX_ID%TYPE;
    l_order_type_id                         HZ_CUST_SITE_USES.ORDER_TYPE_ID%TYPE;
    l_price_list_id            HZ_CUST_SITE_USES.PRICE_LIST_ID%TYPE;
--    l_ship_partial                          HZ_CUST_SITE_USES.SHIP_PARTIAL%TYPE;
    l_fob_point                             HZ_CUST_SITE_USES.FOB_POINT%TYPE;
    l_item_cross_ref_pref                   HZ_CUST_SITE_USES.ITEM_CROSS_REF_PREF%TYPE;
    l_warehouse_id                          HZ_CUST_SITE_USES.WAREHOUSE_ID%TYPE;
    l_date_type_preference                  HZ_CUST_SITE_USES.DATE_TYPE_PREFERENCE%TYPE;
--    l_ship_sets_include_lines_flag          HZ_CUST_SITE_USES.SHIP_SETS_INCLUDE_LINES_FLAG%TYPE;
    l_primary_flag                          HZ_CUST_SITE_USES.PRIMARY_FLAG%TYPE;
    l_error                                 BOOLEAN := FALSE;
    l_validate_flag varchar2(1) := 'Y';
    l_mosr_owner_table_id number;
BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;
    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_site_use (+)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT CUST_ACCT_SITE_ID, SITE_USE_CODE, ORIG_SYSTEM_REFERENCE,
               CREATED_BY_MODULE, APPLICATION_ID, STATUS, SHIP_VIA, FREIGHT_TERM,
               SHIP_SETS_INCLUDE_LINES_FLAG,ARRIVALSETS_INCLUDE_LINES_FLAG,
          TAX_CODE,DEMAND_CLASS_CODE,PRIMARY_SALESREP_ID,FINCHRG_RECEIVABLES_TRX_ID,
          ORDER_TYPE_ID,PRICE_LIST_ID,FOB_POINT,ITEM_CROSS_REF_PREF,
          WAREHOUSE_ID,DATE_TYPE_PREFERENCE
        INTO l_cust_acct_site_id, l_site_use_code, l_orig_system_reference,
             l_created_by_module, l_application_id, l_status, l_ship_via, l_freight_term,
             l_ship_sets_inc_lines_f,l_arrivalsets_inc_lines_f,l_tax_code,l_demand_class_code,
             l_primary_salesrep_id,l_finchrg_receivables_trx_id,l_order_type_id,l_price_list_id,
        l_fob_point,l_item_cross_ref_pref,l_warehouse_id,l_date_type_preference
        FROM HZ_CUST_SITE_USES
        WHERE ROWID = p_rowid;
    END IF;

    --------------------------------------
    -- validate site_use_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.

--Bug Fix 2399491, Checking for duplicates in the _all table.
 
        IF p_cust_site_use_rec.site_use_id IS NOT NULL AND
           p_cust_site_use_rec.site_use_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_SITE_USES_ALL
            WHERE SITE_USE_ID = p_cust_site_use_rec.site_use_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_site_use_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        -- Debug info.
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_id is unique during creation if passed in. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

        END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate site_use_id ... ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate cust_acct_site_id
    ----------------------------------------------

    -- cust_acct_site_id is mandatory field
    -- Since cust_acct_site_id is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_acct_site_id',
            p_column_value                          => p_cust_site_use_rec.cust_acct_site_id,
            x_return_status                         => x_return_status );

        -- for later use. It is selected from database during update.
        l_cust_acct_site_id := p_cust_site_use_rec.cust_acct_site_id;

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id is mandatory. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_acct_site_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.cust_acct_site_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_acct_site_id',
            p_column_value                          => p_cust_site_use_rec.cust_acct_site_id,
            p_old_column_value                      => l_cust_acct_site_id,
            x_return_status                         => x_return_status );
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id is non-updateable. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- Since cust_acct_site_id is mandatory and non-updateable, we only need
    -- to check FK during site use creation.

    -- cust_acct_site_id is foreign key to hz_cust_acct_sites
    IF p_create_update_flag = 'C' AND
       p_cust_site_use_rec.cust_acct_site_id IS NOT NULL AND
       p_cust_site_use_rec.cust_acct_site_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_acct_site_fk (
            p_column                                 => 'cust_acct_site_id',
            p_column_value                           => p_cust_site_use_rec.cust_acct_site_id,
            x_return_status                          => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id is foreign key to hz_cust_acct_sites. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- Find customer account id this site use belongs to.
    -- For later use.

    SELECT CUST_ACCOUNT_ID INTO l_cust_account_id
    FROM HZ_CUST_ACCT_SITES
    WHERE CUST_ACCT_SITE_ID = l_cust_acct_site_id;
 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_acct_site_id ... ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
        
    --------------------------------------
    -- validate status
    --------------------------------------

    -- status cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.status IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'status', 
            p_column_value                          => p_cust_site_use_rec.status,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status cannot be updated to null. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- status is lookup code in lookup type CODE_STATUS
    IF p_cust_site_use_rec.status IS NOT NULL AND
       p_cust_site_use_rec.status <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_cust_site_use_rec.status <> NVL( l_status, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'status',
            p_lookup_type                           => 'CODE_STATUS',
            p_column_value                          => p_cust_site_use_rec.status,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status is lookup code in lookup type CODE_STATUS. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate status ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
        
    ----------------------------------------------
    -- validate site_use_code
    ----------------------------------------------

    -- site_use_code is mandatory field
    -- Since site_use_code is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'site_use_code',
            p_column_value                          => p_cust_site_use_rec.site_use_code,
            x_return_status                         => x_return_status );

        -- for later use. It is selected from database during update.
        l_site_use_code := p_cust_site_use_rec.site_use_code;
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_code is mandatory. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
    END IF;

    -- site_use_code is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.site_use_code IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'site_use_code',
            p_column_value                          => p_cust_site_use_rec.site_use_code,
            p_old_column_value                      => l_site_use_code,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_code is non-updateable. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- site_use_code is lookup code in lookup type SITE_USE_CODE
    -- Since site_use_code is non-updateable, we only need to do the checking
    -- during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_site_use_rec.site_use_code IS NOT NULL AND
       p_cust_site_use_rec.site_use_code <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'site_use_code',
            p_lookup_type                           => 'SITE_USE_CODE',
            p_column_value                          => p_cust_site_use_rec.site_use_code,
            x_return_status                         => x_return_status );
 
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'site_use_code is lookup code in lookup type SITE_USE_CODE. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- l_status is selected from database during update.

    IF p_cust_site_use_rec.status = 'A' OR
       ( p_create_update_flag = 'C' AND
         ( p_cust_site_use_rec.status IS NULL OR
           p_cust_site_use_rec.status = FND_API.G_MISS_CHAR ) ) OR
       ( p_create_update_flag = 'U' AND
         p_cust_site_use_rec.status IS NULL AND
         l_status = 'A' )
    THEN

        -- A customer can have only one active DUN, STMTS, LEGAL site use

        IF l_site_use_code IN ( 'DUN', 'STMTS', 'LEGAL' ) THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCT_SITES site,
                 HZ_CUST_SITE_USES su
            WHERE site.CUST_ACCOUNT_ID = l_cust_account_id
            AND site.CUST_ACCT_SITE_ID = su.CUST_ACCT_SITE_ID
            AND su.SITE_USE_CODE = l_site_use_code
            AND su.STATUS = 'A'
            AND ( p_create_update_flag = 'C' OR 
                  p_create_update_flag = 'U' AND su.ROWID <> p_rowid )
            AND ROWNUM = 1;

            IF l_site_use_code = 'DUN' THEN
                FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ONE_ACTIVE_DUN_SITE' );
            ELSIF l_site_use_code = 'LEGAL' THEN
                FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ONE_ACTIVE_LEGAL_SITE' );
            ELSIF l_site_use_code = 'STMTS' THEN
                FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ONE_ACTIVE_STMTS_SITE' );
            END IF;

            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;  

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
        END IF;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'A customer can have only one active DUN, STMTS, LEGAL site use. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_acct_site_id and site_use_code together should be unique.
    
    -- Bug 3988537.
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_CUST_SITE_USES
        WHERE CUST_ACCT_SITE_ID = nvl(p_cust_site_use_rec.cust_acct_site_id,l_cust_acct_site_id)
        AND SITE_USE_CODE = nvl(p_cust_site_use_rec.site_use_code,l_site_use_code)
        AND SITE_USE_ID <> nvl(p_cust_site_use_rec.site_use_id,fnd_api.g_miss_num)
        AND STATUS = 'A'
        AND ROWNUM = 1;

        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_acct_site_id - site_use_code' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id and site_use_code together should be unique. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate site_use_code ... ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
        
    ----------------------------------------------
    -- validate location
    ----------------------------------------------

    -- location should be mandatory.

    -- check if need generate location.
    BEGIN

       SELECT AUTO_SITE_NUMBERING INTO l_profile
       FROM AR_SYSTEM_PARAMETERS;

 --Bug Fix 2183072 Handled the exception 
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR','AR_NO_ROW_IN_SYSTEM_PARAMETERS');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
   END ;

    IF p_create_update_flag = 'C' THEN
        IF p_cust_site_use_rec.location IS NULL OR
           p_cust_site_use_rec.location = FND_API.G_MISS_CHAR 
        THEN
            IF l_profile = 'N' THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
                FND_MESSAGE.SET_TOKEN( 'COLUMN', 'location' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;
            END IF;
          
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'location is mandatory if autonumbering is set to N. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

        END IF;
    ELSIF p_create_update_flag = 'U' AND
          p_cust_site_use_rec.location IS NOT NULL
    THEN
        -- location cannot be set to null during update
        validate_cannot_update_to_null (
            p_column                                => 'location', 
            p_column_value                          => p_cust_site_use_rec.location,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'location cannot be updated to null. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- location must be unique within a customer account/site_use_type

    IF p_cust_site_use_rec.location IS NOT NULL AND
       p_cust_site_use_rec.location <> FND_API.G_MISS_CHAR
    THEN
    BEGIN

--Bug No : 2998504. Status check added to the where clause. 
-- Office Depot: 13-Oct-2007.
-- Go to base tables to improve performance
-- No impact to functionality since we are also adding ORG_ID

SELECT   'Y'
INTO l_dummy
FROM HZ_CUST_ACCT_SITES_ALL site,
HZ_CUST_SITE_USES_ALL su
WHERE site.CUST_ACCOUNT_ID = l_cust_account_id
AND site.CUST_ACCT_SITE_ID = su.CUST_ACCT_SITE_ID
AND su.SITE_USE_CODE = l_site_use_code
and NVL(SU.ORG_ID,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),'',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99))=NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),'',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
and NVL(SITE.ORG_ID,NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),'',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99))=NVL(TO_NUMBER(DECODE(SUBSTRB(USERENV('CLIENT_INFO'),1,1),'',NULL,SUBSTRB(USERENV('CLIENT_INFO'),1,10))),-99)
AND su.LOCATION = p_cust_site_use_rec.location
AND ( p_create_update_flag = 'C' OR
p_create_update_flag = 'U' AND su.ROWID <> p_rowid )
AND su.STATUS = 'A'
AND ROWNUM = 1;   

        FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_DUP_CODE_LOCATION' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'location must be unique within a customer account/site_use_type. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate location ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
 
    ----------------------------------------------
    -- validate contact_id
    ----------------------------------------------
    IF p_cust_site_use_rec.contact_id IS NOT NULL AND
       p_cust_site_use_rec.contact_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_site_use_cont_fk (
            p_column                                 => 'cust_account_role_id',
            p_column_value                           => p_cust_site_use_rec.contact_id,
            p_customer_id                            => l_cust_account_id,
            x_return_status                          => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'contact_id is foreign key to hz_cust_account_roles. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF; 
    ----------------------------------------------
    -- validate bill_to_site_use_id
    ----------------------------------------------

    -- For SHIP_TO site use, bill_to_site_use_id should be a valid 
    -- BILL_TO site use of this account and its related account.
    -- For other type of site uses, this column should be NULL.
    -- Bug No : 2266165. Added the check for bill_to_flag. 
    IF p_cust_site_use_rec.bill_to_site_use_id IS NOT NULL AND
       p_cust_site_use_rec.bill_to_site_use_id <> FND_API.G_MISS_NUM
    THEN
        IF l_site_use_code = 'SHIP_TO' THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCT_SITES site,
                 HZ_CUST_SITE_USES su
            WHERE su.SITE_USE_ID = p_cust_site_use_rec.bill_to_site_use_id
            AND su.SITE_USE_CODE = 'BILL_TO'
            AND su.STATUS = 'A'
            AND site.CUST_ACCT_SITE_ID = su.CUST_ACCT_SITE_ID
            AND site.STATUS = 'A'
            AND site.CUST_ACCOUNT_ID IN (
                SELECT l_cust_account_id
                FROM DUAL
                UNION
                SELECT CUST_ACCOUNT_ID
                FROM HZ_CUST_ACCT_RELATE_ALL
                WHERE RELATED_CUST_ACCOUNT_ID = l_cust_account_id 
                AND   BILL_TO_FLAG            = 'Y' );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_BILL_TO_SITE_USE_F' );
                FND_MSG_PUB.ADD;
                x_return_status := FND_API.G_RET_STS_ERROR;  
        END;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'For SHIP_TO site use, bill_to_site_use_id should be a valid BILL_TO site use of this account and its related account. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

        ELSE
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_BILL_TO_SITE_USE_S' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;    
        END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate bill_to_site_use_id ... ' ||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate orig_system_reference
    ----------------------------------------------
    IF (p_cust_site_use_rec.orig_system is not null and p_cust_site_use_rec.orig_system <>fnd_api.g_miss_char) 
    and (p_cust_site_use_rec.orig_system_reference is not null and p_cust_site_use_rec.orig_system_reference <>fnd_api.g_miss_char) 
     and p_create_update_flag = 'U'
    then
   hz_orig_system_ref_pub.get_owner_table_id 
   (p_orig_system => p_cust_site_use_rec.orig_system, 
   p_orig_system_reference => p_cust_site_use_rec.orig_system_reference, 
   p_owner_table_name =>'HZ_CUST_SITE_USES_ALL', 
   x_owner_table_id => l_mosr_owner_table_id, 
   x_return_status => x_return_status); 
   IF x_return_status = fnd_api.g_ret_sts_success and l_mosr_owner_table_id= nvl(p_cust_site_use_rec.site_use_id,l_mosr_owner_table_id)
   then
      l_validate_flag := 'N';
   end if;
    end if;
    -- orig_system_reference is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.orig_system_reference IS NOT NULL
       and l_validate_flag = 'Y' 
    THEN
        validate_nonupdateable (
            p_column                                => 'orig_system_reference',
            p_column_value                          => p_cust_site_use_rec.orig_system_reference,
            p_old_column_value                      => l_orig_system_reference,
            x_return_status                         => x_return_status );
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'orig_system_reference is non-updateable. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate orig_system_reference ... ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate freight_term
    ----------------------------------------------

    -- freight_term is lookup code in lookup type FREIGHT_TERMS in so_lookups
    IF p_cust_site_use_rec.freight_term IS NOT NULL AND
       p_cust_site_use_rec.freight_term <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_cust_site_use_rec.freight_term <> NVL( l_freight_term, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'freight_term',
            p_lookup_table                          => 'SO_LOOKUPS',
            p_lookup_type                           => 'FREIGHT_TERMS',
            p_column_value                          => p_cust_site_use_rec.freight_term,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'freight_term is lookup code in lookup type FREIGHT_TERMS in so_lookups. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate freight_term ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate primary_flag
    ----------------------------------------------

    -- primary_flag cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.primary_flag IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'primary_flag',
            p_column_value                          => p_cust_site_use_rec.primary_flag,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag cannot be updated to NULL. ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- primary_flag is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.primary_flag IS NOT NULL AND
       p_cust_site_use_rec.primary_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'primary_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.primary_flag,
            x_return_status                         => x_return_status );
  
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag is lookup code in lookup type YES/NO. ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- only one primary is allowed for one site use type per account
    -- Bug Fix : 2260832
    -- Bug 2643624  Removing the below validation so as to enable the setting
    --              of another site use as primary.
/*

    IF p_cust_site_use_rec.primary_flag = 'Y' 
    THEN
    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_CUST_ACCT_SITES site,
             HZ_CUST_SITE_USES su
        WHERE site.CUST_ACCOUNT_ID = l_cust_account_id
        AND su.CUST_ACCT_SITE_ID = site.CUST_ACCT_SITE_ID
        AND su.SITE_USE_CODE = l_site_use_code
        AND su.PRIMARY_FLAG = 'Y'
--Bug 2792589        AND su.STATUS       = 'Y'
        AND su.STATUS       = 'A'
        AND ( p_create_update_flag = 'C' OR
              (p_create_update_flag = 'U' AND su.ROWID <> p_rowid ))
        AND ROWNUM = 1;
        
        FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ONE_PRIMARY_SU' );
        FND_MESSAGE.SET_TOKEN( 'SITE_CODE', l_site_use_code );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'only one primary is allowed for one site use type per account. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;
*/
    
    -- check to ensure that an inactive site use is never marked
    -- as primary.
    IF p_create_update_flag = 'C' THEN
      IF p_cust_site_use_rec.primary_flag IS NULL OR
         p_cust_site_use_rec.primary_flag = fnd_api.g_miss_char
      THEN
        l_primary_flag := 'N';
      ELSE
        l_primary_flag := p_cust_site_use_rec.primary_flag;
      END IF;

      IF p_cust_site_use_rec.status IS NULL OR
         p_cust_site_use_rec.status = fnd_api.g_miss_char
      THEN
        l_status := 'A';
      ELSE
        l_status := p_cust_site_use_rec.status;
      END IF;

      IF l_primary_flag = 'Y' AND l_status <> 'A' THEN
        l_error := TRUE;
      END IF;
    ELSE
      IF p_cust_site_use_rec.primary_flag = 'Y' AND
         ((p_cust_site_use_rec.status IS NOT NULL AND
           p_cust_site_use_rec.status <> 'A') OR
          (p_cust_site_use_rec.status IS NULL AND
           l_status <> 'A'))
      THEN
        l_error := TRUE;
      END IF;
    END IF;

    IF l_error THEN
          fnd_message.set_name('AR', 'HZ_API_INACTIVE_CANNOT_PRIM');
          fnd_message.set_token('ENTITY', 'Site Use');
      --    fnd_message.set_token('COLUMN1', 'primary_flag');
      --    fnd_message.set_token('COLUMN2', 'status');
          fnd_msg_pub.add;
          x_return_status := FND_API.G_RET_STS_ERROR;
      -- reset l_error for later use.
          l_error := FALSE;
    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'an inactive site use is never marked as primary. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate primary_flag ... ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


--bug fix 2311760
/***************************
    ----------------------------------------------
    -- validate ship_partial
    ----------------------------------------------

    -- ship_partial is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.ship_partial IS NOT NULL AND
       p_cust_site_use_rec.ship_partial <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'ship_partial',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.ship_partial,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'ship_partial is lookup code in lookup type YES/NO. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate ship_partial ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;
 
***********************/
    ----------------------------------------------
    -- validate ship_sets_include_lines_flag
    ----------------------------------------------

    -- ship_sets_include_lines_flag is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.ship_sets_include_lines_flag IS NOT NULL AND
       p_cust_site_use_rec.ship_sets_include_lines_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'ship_sets_include_lines_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.ship_sets_include_lines_flag,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'ship_sets_include_lines_flag is lookup code in lookup type YES/NO. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

--If ship_sets_include_lines_flag is set to Y then arrivalsets_include_lines_flag
--is always set to N.
IF (p_create_update_flag = 'C' or
   (p_create_update_flag ='U' and
    p_cust_site_use_rec.ship_sets_include_lines_flag <> NVL(l_ship_sets_inc_lines_f,FND_API.G_MISS_CHAR)))
THEN
   IF p_cust_site_use_rec.ship_sets_include_lines_flag = 'Y'
   THEN
    BEGIN
       SELECT decode(p_cust_site_use_rec.ship_sets_include_lines_flag,p_cust_site_use_rec.arrivalsets_include_lines_flag,
                     'N',l_arrivalsets_inc_lines_f,
                                        decode(p_cust_site_use_rec.arrivalsets_include_lines_flag,l_ship_sets_inc_lines_f,
                                               'Y','N'),'Y') 
       INTO l_dummy
       FROM DUAL;
       IF l_dummy <> 'Y'
       THEN
       FND_MESSAGE.SET_NAME('AR','HZ_API_VAL_DEP_FIELDS');
       FND_MESSAGE.SET_TOKEN('COLUMN1','ship_sets_include_lines_flag');
            FND_MESSAGE.SET_TOKEN('VALUE1','Y');
            FND_MESSAGE.SET_TOKEN('COLUMN2','arrivalsets_include_lines_flag');
            FND_MESSAGE.SET_TOKEN('VALUE2','N');
       FND_MSG_PUB.ADD;
       x_return_status := FND_API.G_RET_STS_ERROR;
   END IF;
    END ;
   END IF;
END IF;
      
     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'If ship_sets_include_lines_flag is set to Y then arrivalsets_include_lines_flag is always set to N. '||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
     END IF;

     IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'(+) after validate ship_sets_include_lines_flag ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
      END IF;
 
    ----------------------------------------------
    -- validate arrivalsets_include_lines_flag
    ----------------------------------------------

    -- arrivalsets_include_lines_flag is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.arrivalsets_include_lines_flag IS NOT NULL AND
       p_cust_site_use_rec.arrivalsets_include_lines_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'arrivalsets_include_lines_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.arrivalsets_include_lines_flag,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'arrivalsets_include_lines_flag is lookup code in lookup type YES/NO. ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

--If arrivalsets_include_lines_flag is set to Y then ship_sets_include_lines_flag
--is always set to N.

IF (p_create_update_flag ='C' or
    (p_create_update_flag ='U' and
    p_cust_site_use_rec.arrivalsets_include_lines_flag <> NVL(l_arrivalsets_inc_lines_f,FND_API.G_MISS_CHAR)))
THEN
 IF p_cust_site_use_rec.arrivalsets_include_lines_flag = 'Y'
 THEN
   BEGIN
     SELECT decode(p_cust_site_use_rec.arrivalsets_include_lines_flag,p_cust_site_use_rec.ship_sets_include_lines_flag,
                   'N',l_ship_sets_inc_lines_f,
                                       decode(p_cust_site_use_rec.ship_sets_include_lines_flag,l_arrivalsets_inc_lines_f,
                                               'Y','N'),'Y') 
     INTO l_dummy
     FROM DUAL;
     IF l_dummy <> 'Y'
     THEN
       FND_MESSAGE.SET_NAME('AR','HZ_API_VAL_DEP_FIELDS');
       FND_MESSAGE.SET_TOKEN('COLUMN1','arrivalsets_include_lines_flag');
            FND_MESSAGE.SET_TOKEN('VALUE1','Y');
            FND_MESSAGE.SET_TOKEN('COLUMN2','ship_sets_include_lines_flag');
            FND_MESSAGE.SET_TOKEN('VALUE2','N');
       FND_MSG_PUB.ADD;
       x_return_status := FND_API.G_RET_STS_ERROR;
     END IF;
   END ;
  END IF;
END IF;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'If arrivalsets_include_lines_flag is set to Y then ship_sets_include_lines_flag is always setto N. ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate arrivalsets_include_lines_flag ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

   ------------------------------------------
   -- validate tax_code
   ------------------------------------------
   --Tax_code should be a valid value defined in ar_vat_tax

   IF p_cust_site_use_rec.tax_code is NOT NULL AND
      p_cust_site_use_rec.tax_code <> FND_API.G_MISS_CHAR
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.tax_code <> NVL( l_tax_code, FND_API.G_MISS_CHAR ) ) )
   THEN
      check_tax_code(
               p_column                                => 'tax_code',
               p_column_value                          => p_cust_site_use_rec.tax_code,
               x_return_status                         => x_return_status );
        
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'Tax_code should be a valid value defined in table ar_vat_tax. '||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
      END IF;

   END IF;
     
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'(+) after validate tax_code..' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
      END IF;
   ------------------------------------
   --validate payment_term_id
   ------------------------------------
   --Payment_term_id should be a valid value defined in RA_TERMS

   IF p_cust_site_use_rec.payment_term_id is NOT NULL AND
      p_cust_site_use_rec.payment_term_id <> FND_API.G_MISS_NUM
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.payment_term_id <> NVL( l_payment_term_id, FND_API.G_MISS_NUM ) ) )
   THEN
          check_payterm_id_fk(
                p_column                                => 'payment_term_id',
               p_column_value                          => p_cust_site_use_rec.payment_term_id,
               x_return_status                         => x_return_status );
    
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'Payment_term_id should be a valid value defined in  RA_TERMS. '||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   END IF;
      
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'(+) after validate payment_term_id..' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
   ---------------------------------------------
   --validate demand_class_code
   ---------------------------------------------
   --Demand_class_code is lookup_code in lookup_type DEMAND_CLASS in fnd_common_lookups

   IF p_cust_site_use_rec.demand_class_code is NOT NULL AND
      p_cust_site_use_rec.demand_class_code <> FND_API.G_MISS_CHAR
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.demand_class_code <> NVL(l_demand_class_code,FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
           p_column               =>'demand_class_code',
           p_lookup_table         =>'FND_COMMON_LOOKUPS',
           p_lookup_type           =>'DEMAND_CLASS',
           p_column_value         =>p_cust_site_use_rec.demand_class_code,
           x_return_status        =>x_return_status   );
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'Demand_class_code is lookup_code in lookup_type DEMAND_CLASS in fnd_common_lookups. '||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;
   END IF;
   
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'(+) after validate demand_class_code..' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   -----------------------------------------------
   --validate primary_salesrep_id
   -----------------------------------------------
   --Primary_salesrep_id should be a valid value defined in RA_SALESREPS

   IF p_cust_site_use_rec.primary_salesrep_id is NOT NULL AND
      p_cust_site_use_rec.primary_salesrep_id <> FND_API.G_MISS_NUM
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.primary_salesrep_id <> NVL(l_primary_salesrep_id,FND_API.G_MISS_NUM) ) )
   THEN
       check_prim_salesrep(
              p_column                                => 'primary_salesrep_id',
              p_column_value                          => p_cust_site_use_rec.primary_salesrep_id,
                    x_return_status                         => x_return_status );
     
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'Primary_salesrep_id should be a valid value defined in RA_SALESREPS. '||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

   END IF;
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate primary_salesrep_id..' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

----------------------------------------------------
--validate finchrg_receivables_trx_id
----------------------------------------------------
IF p_cust_site_use_rec.finchrg_receivables_trx_id is NOT NULL AND
   p_cust_site_use_rec.finchrg_receivables_trx_id <> FND_API.G_MISS_NUM
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.finchrg_receivables_trx_id <> NVL(l_finchrg_receivables_trx_id,FND_API.G_MISS_NUM) ) )
THEN
check_finchrg_trx_fk(
       p_column                           => 'finchrg_receivables_trx_id',
       p_column_value                     => p_cust_site_use_rec.finchrg_receivables_trx_id,
       x_return_status                    => x_return_status );
 
IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'finchrg_receivables_trx_id should be a valid value defined in AR_RECEIVABLES_TRX. '||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
 END IF;


END IF;

 IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate finchrg_receivables_trx_id..' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
 END IF;



   -------------------------------------------
   --validate order_Type_id
   -------------------------------------------
   --order_type_id should be a valid value defined in OE_ORDER_TYPES_V

   IF p_cust_site_use_rec.order_type_id is NOT NULL AND
      p_cust_site_use_rec.order_type_id <> FND_API.G_MISS_NUM
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.order_type_id <> NVL(l_order_type_id,FND_API.G_MISS_NUM) ) )
   THEN
       check_ord_type(
              p_column                                => 'order_type_id',
              p_column_value                          => p_cust_site_use_rec.order_type_id,
              x_return_status                         => x_return_status );
     
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'order_type_id should be a valid value defined in OE_ORDER_TYPES_V. '||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
    
   END IF;
     
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'(+) after validate order_type_id..' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;
        

   ----------------------------------------------------------
   --validate price_list_id
   ----------------------------------------------------------
   --price_list_id should be a valid value defined in SO_PRICE_LISTS

   IF p_cust_site_use_rec.price_list_id is NOT NULL AND
      p_cust_site_use_rec.price_list_id <> FND_API.G_MISS_NUM
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.price_list_id <> NVL(l_price_list_id,FND_API.G_MISS_NUM) ) )
   THEN
       check_price_list_fk(
            p_column                           => 'price_list_id',
            p_column_value                     => p_cust_site_use_rec.price_list_id,
            x_return_status                    => x_return_status );

       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'price_list_id should be a valid value defined in SO_PRICE_LISTS. '||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   END IF;
     
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate price_list_id..' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
            END IF;


   ----------------------------------------------
   --validate item_cross_ref_pref
   ----------------------------------------------
   --item_cross_ref_pref should be a value defined in MTL_CROSS_REFERENCE_TYPES or should have value 'INT' or 'CUST'

   IF p_cust_site_use_rec.item_cross_ref_pref IS NOT NULL AND
      p_cust_site_use_rec.item_cross_ref_pref <> FND_API.G_MISS_CHAR
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.item_cross_ref_pref <> NVL(l_item_cross_ref_pref,FND_API.G_MISS_CHAR) ) )
   THEN
     IF p_cust_site_use_rec.item_cross_ref_pref NOT IN('INT','CUST')
     THEN
        check_item_cross_ref(
               p_column                           => 'price_list_id',
               p_column_value                     => p_cust_site_use_rec.item_cross_ref_pref,
               x_return_status                    => x_return_status );
    
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'item_cross_ref_pref should be a value defined in MTL_CROSS_REFERENCE_TYPES or should be INT or CUST . ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

     END IF;
   END IF;
      
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
       hz_utility_v2pub.debug(p_message=>'(+) after validate item_cross_ref_pref..' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   --------------------------------------------------
   --validate warehouse_id
   --------------------------------------------------
   --warehouse_id should be a value defined in ORG_ORGANIZATION_DEFINITIONS

   IF p_cust_site_use_rec.warehouse_id is NOT NULL AND
      p_cust_site_use_rec.warehouse_id <> FND_API.G_MISS_NUM
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.warehouse_id <> NVL(l_warehouse_id,FND_API.G_MISS_NUM) ) )
   THEN
       check_warehouse(
             p_column                           => 'warehouse_id',
             p_column_value                     => p_cust_site_use_rec.warehouse_id,
             x_return_status                    => x_return_status );
   
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'warehouse_id should be a value defined in ORG_ORGANIZATION_DEFINITIONS . '||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   END IF;
    
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate warehouse_id..' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;



    ----------------------------------------------
    --validate fob_point
    ----------------------------------------------
   --fob_point is lookup_code in lookup type FOB

   IF p_cust_site_use_rec.fob_point is NOT NULL AND
      p_cust_site_use_rec.fob_point <> FND_API.G_MISS_CHAR
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.fob_point <> NVL(l_fob_point,FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
                p_column        =>'fob_point',
           p_lookup_type   =>'FOB',
           p_column_value  =>p_cust_site_use_rec.fob_point,
         x_return_status =>x_return_status  );
      
       IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'fob_point is lookup_code in lookup type FOB. '||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   END IF;
      
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate fob_point..' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;



   ----------------------------------------------------------
   --validate date_type_preference
   ----------------------------------------------------------
   --date_type_preference is a lookup_code in lookup_type REQUEST_DATE_TYPE in oe_lookups

   IF p_cust_site_use_rec.date_type_preference IS NOT NULL AND
      p_cust_site_use_rec.date_type_preference <> FND_API.G_MISS_CHAR
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.date_type_preference <> NVL(l_date_type_preference,FND_API.G_MISS_CHAR) ) )
   THEN
       validate_lookup(
            p_column               =>'date_type_preference',
            p_lookup_table         =>'OE_LOOKUPS',
            p_lookup_type          =>'REQUEST_DATE_TYPE',
            p_column_value         =>p_cust_site_use_rec.date_type_preference,
            x_return_status        =>x_return_status   );
      
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'date_type_preference is a lookup_code in lookup_type REQUEST_DATE_TYPE in oe_lookups. '||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

   END IF;
      
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate date_type_preference..' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
      END IF;

--Bug fix 2311760
/***************************
    ----------------------------------------------
    -- validate ship_partial
    ----------------------------------------------

    -- ship_partial is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.ship_partial IS NOT NULL AND
       p_cust_site_use_rec.ship_partial <> FND_API.G_MISS_CHAR
          AND ( p_create_update_flag = 'C' OR
           ( p_create_update_flag = 'U'  AND
            p_cust_site_use_rec.ship_partial <> NVL(l_ship_partial,FND_API.G_MISS_CHAR) ) )
    THEN
        validate_lookup (
            p_column                                => 'ship_partial',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.ship_partial,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'ship_partial is lookup code in lookup type YES/NO. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate ship_partial ... ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

******************************/
    ----------------------------------------------
    -- validate sched_date_push_flag
    ----------------------------------------------

    -- sched_date_push_flag is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.sched_date_push_flag IS NOT NULL AND
       p_cust_site_use_rec.sched_date_push_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'sched_date_push_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.sched_date_push_flag,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'sched_date_push_flag is lookup code in lookup type YES/NO. ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate sched_date_push_flag ... ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    ----------------------------------------------
    -- validate gsa_indicator
    ----------------------------------------------

    -- gsa_indicator is lookup code in lookup type YES/NO
    IF p_cust_site_use_rec.gsa_indicator IS NOT NULL AND
       p_cust_site_use_rec.gsa_indicator <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'gsa_indicator',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_site_use_rec.gsa_indicator,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gsa_indicator is lookup code in lookup type YES/NO. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate gsa_indicator ... ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate gl_id_xxx fields
    ----------------------------------------------
    -- Bug 2553286
    -- If site_use_code is not 'BILL_TO', then Revenue, Tax, Freight, Clearing, 
    -- Unbilled Receivable and Unearned Revenue fields should not be populated.

    IF p_cust_site_use_rec.site_use_code <> 'BILL_TO' OR 
       ( p_cust_site_use_rec.site_use_code IS NULL AND l_site_use_code <> 'BILL_TO' )
    THEN
        IF ( p_cust_site_use_rec.gl_id_rev IS NOT NULL AND
             p_cust_site_use_rec.gl_id_rev <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_tax IS NOT NULL AND
             p_cust_site_use_rec.gl_id_tax <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_freight IS NOT NULL AND
             p_cust_site_use_rec.gl_id_freight <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_clearing IS NOT NULL AND
             p_cust_site_use_rec.gl_id_clearing <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_unbilled IS NOT NULL AND
             p_cust_site_use_rec.gl_id_unbilled <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_unearned IS NOT NULL AND
             p_cust_site_use_rec.gl_id_unearned <> FND_API.G_MISS_NUM )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'AR_AUTO_CCID_INVALID' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'If site_use_code is not BILL_TO, then Revenue, Tax, Freight, Clearing, ' ||
               'Unbilled Receivable and Unearned Revenue fields should not be populated. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
    -- Bug 2553286
    -- If site_use_code is not 'DRAWEE', then Unpaid Bills Receivables, 
    -- Remitted Bills Receivables and Factored Bills Receivables fields should not be populated.

    IF p_cust_site_use_rec.site_use_code <> 'DRAWEE' OR 
       ( p_cust_site_use_rec.site_use_code IS NULL AND l_site_use_code <> 'DRAWEE' )
    THEN
        IF ( p_cust_site_use_rec.gl_id_unpaid_rec IS NOT NULL AND
             p_cust_site_use_rec.gl_id_unpaid_rec <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_remittance IS NOT NULL AND
             p_cust_site_use_rec.gl_id_remittance <> FND_API.G_MISS_NUM ) OR
           ( p_cust_site_use_rec.gl_id_factor IS NOT NULL AND
             p_cust_site_use_rec.gl_id_factor <> FND_API.G_MISS_NUM )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'AR_AUTO_CCID_INVALID' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'If site_use_code is not DRAWEE, then Unpaid Bills Receivables, ' ||
               'Remitted Bills Receivables and Factored Bills Receivables fields should not be populated. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
    -- Bug 2553286
    -- If site_use_code is not 'BILL_TO OR DRAWEE', then Bills Receivables field should not be populated.

    IF p_cust_site_use_rec.site_use_code NOT IN ('BILL_TO', 'DRAWEE') OR 
        ( p_cust_site_use_rec.site_use_code IS NULL AND l_site_use_code NOT IN ('BILL_TO', 'DRAWEE') ) 
    THEN
        IF ( p_cust_site_use_rec.gl_id_rec IS NOT NULL AND
             p_cust_site_use_rec.gl_id_rec <> FND_API.G_MISS_NUM )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'AR_AUTO_CCID_INVALID' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'If site_use_code is not BILL_TO OR DRAWEE, then Bills Receivables field should not be populated. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
    ----------------------------------------------
    -- validate gl_id_rec
    ----------------------------------------------

    -- gl_id_rec is validate gl field.
    IF p_cust_site_use_rec.gl_id_rec IS NOT NULL AND
       p_cust_site_use_rec.gl_id_rec <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'REC',
            p_column_value                          => p_cust_site_use_rec.gl_id_rec,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_rec is validate gl field. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_rev
    ----------------------------------------------

    -- gl_id_rev is validate gl field.
    IF p_cust_site_use_rec.gl_id_rev IS NOT NULL AND
       p_cust_site_use_rec.gl_id_rev <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'REV',
            p_column_value                          => p_cust_site_use_rec.gl_id_rev,
            x_return_status                         => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_rev is validate gl field. ' ||
        'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_tax
    ----------------------------------------------

    -- gl_id_tax is validate gl field.
    IF p_cust_site_use_rec.gl_id_tax IS NOT NULL AND
       p_cust_site_use_rec.gl_id_tax <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'TAX',
            p_column_value                          => p_cust_site_use_rec.gl_id_tax,
            x_return_status                         => x_return_status );
   
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_tax is validate gl field. ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
       END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_freight
    ----------------------------------------------

    -- gl_id_freight is validate gl field.
    IF p_cust_site_use_rec.gl_id_freight IS NOT NULL AND
       p_cust_site_use_rec.gl_id_freight <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'FREIGHT',
            p_column_value                          => p_cust_site_use_rec.gl_id_freight,
            x_return_status                         => x_return_status );
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_freight is validate gl field. ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_clearing
    ----------------------------------------------

    -- gl_id_clearing is validate gl field.
    IF p_cust_site_use_rec.gl_id_clearing IS NOT NULL AND
       p_cust_site_use_rec.gl_id_clearing <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'CLEARING',
            p_column_value                          => p_cust_site_use_rec.gl_id_clearing,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_clearing is validate gl field. ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_unbilled
    ----------------------------------------------

    -- gl_id_unbilled is validate gl field.
    IF p_cust_site_use_rec.gl_id_unbilled IS NOT NULL AND
       p_cust_site_use_rec.gl_id_unbilled <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'UNBILLED',
            p_column_value                          => p_cust_site_use_rec.gl_id_unbilled,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_unbilled is validate gl field. ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_unearned
    ----------------------------------------------

    -- gl_id_unearned is validate gl field.
    IF p_cust_site_use_rec.gl_id_unearned IS NOT NULL AND
       p_cust_site_use_rec.gl_id_unearned <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'UNEARNED',
            p_column_value                          => p_cust_site_use_rec.gl_id_unearned,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_unearned is validate gl field. ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_unpaid_rec
    ----------------------------------------------

    -- gl_id_unpaid_rec is validate gl field.
    IF p_cust_site_use_rec.gl_id_unpaid_rec IS NOT NULL AND
       p_cust_site_use_rec.gl_id_unpaid_rec <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'UNPAID_REC',
            p_column_value                          => p_cust_site_use_rec.gl_id_unpaid_rec,
            x_return_status                         => x_return_status );
  
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_unpaid_rec is validate gl field. ' ||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_remittance
    ----------------------------------------------

    -- gl_id_remittance is validate gl field.
    IF p_cust_site_use_rec.gl_id_remittance IS NOT NULL AND
       p_cust_site_use_rec.gl_id_remittance <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'REMITTANCE',
            p_column_value                          => p_cust_site_use_rec.gl_id_remittance,
            x_return_status                         => x_return_status );
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_remittance is validate gl field. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    ----------------------------------------------
    -- validate gl_id_factor
    ----------------------------------------------

    -- gl_id_factor is validate gl field.
    IF p_cust_site_use_rec.gl_id_factor IS NOT NULL AND
       p_cust_site_use_rec.gl_id_factor <> FND_API.G_MISS_NUM
    THEN
        validate_gl_id (
            p_gl_name                               => 'FACTOR',
            p_column_value                          => p_cust_site_use_rec.gl_id_factor,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'gl_id_factor is validate gl field. ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate gl_xxx ... ' ||
          'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate ship_via
    --------------------------------------

    -- ship_via is foreign key to oe_ship_methods_v
    -- can be used in both single and multi org case.
    IF p_cust_site_use_rec.ship_via IS NOT NULL AND
       p_cust_site_use_rec.ship_via <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U'  AND
           p_cust_site_use_rec.ship_via <> NVL( l_ship_via, FND_API.G_MISS_CHAR ) ) )
    THEN
        check_oe_ship_methods_v_fk (
            p_entity                                 => 'SITE_USE',
            p_column                                 => 'ship_via',
            p_column_value                           => p_cust_site_use_rec.ship_via,
            x_return_status                          => x_return_status );
    
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'ship_via is foreign key to oe_ship_methods_v. ' ||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate ship_via ... ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_site_use_rec.created_by_module,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_site_use_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate created_by_module ... ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_site_use_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_cust_site_use_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate application_id ... ' ||
       'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- Debug info.
  
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_site_use (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;
END validate_cust_site_use;

/**
 * PROCEDURE validate_cust_account_role
 *
 * DESCRIPTION
 *     Validates customer account role record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_cust_account_role_rec        Customer account role record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *
 */

PROCEDURE validate_cust_account_role (
    p_create_update_flag                    IN     VARCHAR2,
    p_cust_account_role_rec                 IN     HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_cust_account_role'

    l_dummy                                 VARCHAR2(1);

    l_party_id                              NUMBER;
    l_cust_account_id                       NUMBER;
    l_cust_acct_site_id                     NUMBER;
    l_role_type                             HZ_CUST_ACCOUNT_ROLES.role_type%TYPE;
    l_created_by_module                     HZ_CUST_ACCOUNT_ROLES.created_by_module%TYPE;
    l_application_id                        NUMBER;
    l_orig_system_reference                 HZ_CUST_ACCOUNT_ROLES.orig_system_reference%TYPE;
    l_status                                HZ_CUST_ACCOUNT_ROLES.status%TYPE;
    l_validate_flag varchar2(1) := 'Y';
    l_mosr_owner_table_id number;
BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_account_role (+)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT PARTY_ID, CUST_ACCOUNT_ID, CUST_ACCT_SITE_ID,
               ROLE_TYPE, ORIG_SYSTEM_REFERENCE, CREATED_BY_MODULE, 
               APPLICATION_ID, STATUS
        INTO l_party_id, l_cust_account_id, l_cust_acct_site_id,
             l_role_type, l_orig_system_reference, l_created_by_module,
             l_application_id, l_status
        FROM HZ_CUST_ACCOUNT_ROLES
        WHERE CUST_ACCOUNT_ROLE_ID = p_cust_account_role_rec.cust_account_role_id;
    END IF;

    --------------------------------------
    -- validate cust_account_role_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.
 
        IF p_cust_account_role_rec.cust_account_role_id IS NOT NULL AND
           p_cust_account_role_rec.cust_account_role_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCOUNT_ROLES
            WHERE CUST_ACCOUNT_ROLE_ID = p_cust_account_role_rec.cust_account_role_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_role_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_role_id is unique during creation if passed in. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_role_id ... ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate party_id
    ----------------------------------------------

    -- party_id is mandatory field
    -- Since party_id is non-updateable, we only need to check mandatory 
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'party_id',
            p_column_value                          => p_cust_account_role_rec.party_id,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_id is mandatory. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- party_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.party_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'party_id',
            p_column_value                          => p_cust_account_role_rec.party_id,
            p_old_column_value                      => l_party_id,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_id is non-updateable. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- party_id is type of party_relationship. 
    -- party_id is the object_id in the relationship. Subject_id is the party
    -- referened by cust_account_id.
    -- However, we decide donot add this validation for now since we may 
    -- need migrate data. (Dylan's reply)

    -- party_id is foreign key to hz_parties
    -- Since party_id is mandatory and non-updateable, we only need to
    -- check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_account_role_rec.party_id IS NOT NULL AND
       p_cust_account_role_rec.party_id <> FND_API.G_MISS_NUM
    THEN
        check_party_fk (
            p_column                                => 'party_id',
            p_column_value                          => p_cust_account_role_rec.party_id,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party_id is foreign key to hz_parties. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;    
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate party_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate cust_account_id
    ----------------------------------------------

    -- cust_account_id is mandatory field
    -- Since cust_account_id is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_account_id',
            p_column_value                          => p_cust_account_role_rec.cust_account_id,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is mandatory. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- cust_account_id is non-updateable field
    IF p_create_update_flag = 'U' AND 
       p_cust_account_role_rec.cust_account_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_account_id',
            p_column_value                          => p_cust_account_role_rec.cust_account_id,
            p_old_column_value                      => l_cust_account_id,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is non-updateable. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- cust_account_id is foreign key to hz_cust_accounts
    -- Since cust_account_id is mandatory and non-updateable,
    -- we only need to check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_account_role_rec.cust_account_id IS NOT NULL AND
       p_cust_account_role_rec.cust_account_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_account_fk (
            p_column                                 => 'cust_account_id',
            p_column_value                           => p_cust_account_role_rec.cust_account_id,
            x_return_status                          => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_id is foreign key to hz_cust_accounts. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate cust_acct_site_id
    ----------------------------------------------

    -- cust_acct_site_id is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.cust_acct_site_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_acct_site_id',
            p_column_value                          => p_cust_account_role_rec.cust_acct_site_id,
            p_old_column_value                      => l_cust_acct_site_id,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id is non-updateable. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- cust_acct_site_id is foreign key to hz_cust_acct_sites.
    -- The cust_account_id in hz_cust_acct_sites should be same
    -- as we put in cust_account_id in hz_cust_account_roles.
    -- Since cust_acct_site_id is non-updateable, we only need to
    -- check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_account_role_rec.cust_acct_site_id IS NOT NULL AND
       p_cust_account_role_rec.cust_acct_site_id <> FND_API.G_MISS_NUM 
    THEN
    BEGIN
        SELECT CUST_ACCOUNT_ID INTO l_cust_account_id
        FROM HZ_CUST_ACCT_SITES
        WHERE CUST_ACCT_SITE_ID = p_cust_account_role_rec.cust_acct_site_id;

        IF l_cust_account_id <> p_cust_account_role_rec.cust_account_id THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_ACCT_SITE_MISSMATCH' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
       
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
            FND_MESSAGE.SET_TOKEN( 'FK', 'cust_acct_site_id' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_acct_site_id' );
            FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_acct_sites' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
    END;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_acct_site_id is foreign key to hz_cust_acct_sites and cust_account_id in hz_cust_acct_sites should be same as we put in cust_account_id in hz_cust_account_roles.' ||
           'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;    
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_acct_site_id ... ' ||
         'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate role_type
    ----------------------------------------------

    -- role_type is mandatory field
    -- Since role_type is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'role_type',
            p_column_value                          => p_cust_account_role_rec.role_type,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'role_type is mandatory. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- role_type is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.role_type IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'role_type',
            p_column_value                          => p_cust_account_role_rec.role_type,
            p_old_column_value                      => l_role_type,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'role_type is non-updateable. ' ||
                   'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- role_type is lookup code in lookup type ACCT_ROLE_TYPE
    -- Since role_type is non-updateable, we only need to do the checking
    -- during creation.

    IF p_create_update_flag = 'C' AND
       p_cust_account_role_rec.role_type IS NOT NULL AND
       p_cust_account_role_rec.role_type <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'role_type',
            p_lookup_type                           => 'ACCT_ROLE_TYPE',
            p_column_value                          => p_cust_account_role_rec.role_type,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'role_type is lookup code in lookup type ACCT_ROLE_TYPE. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- The combination of CUST_ACCOUNT_ID, PARTY_ID, ROLE_TYPE should be unique.
    -- Or the combination of CUST_ACCT_SITE_ID, PARTY_ID, ROLE_TYPE should be unique.
    -- We only need to check this during creation because all of these
    -- three columns are non-updateable.

    IF p_create_update_flag = 'C' THEN
        IF p_cust_account_role_rec.cust_acct_site_id IS NULL OR 
           p_cust_account_role_rec.cust_acct_site_id = FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCOUNT_ROLES
            WHERE CUST_ACCOUNT_ID = p_cust_account_role_rec.cust_account_id
            AND PARTY_ID = p_cust_account_role_rec.party_id
            AND CUST_ACCT_SITE_ID IS NULL
            AND ROLE_TYPE = p_cust_account_role_rec.role_type
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_id - party_id - role_type' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'the combination of cust_account_id, party_id, role_type should be unique. ' ||
              'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

        ELSE
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCOUNT_ROLES
            WHERE CUST_ACCT_SITE_ID = p_cust_account_role_rec.cust_acct_site_id
            AND PARTY_ID = p_cust_account_role_rec.party_id
            AND ROLE_TYPE = p_cust_account_role_rec.role_type
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_acct_site_id - party_id - role_type' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'the combination of cust_acct_site_id, party_id, role_type should be unique. ' ||
                    'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

        END IF;
    END IF;
 
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate role_type ... ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate orig_system_reference
    ----------------------------------------------
       IF (p_cust_account_role_rec.orig_system is not null and p_cust_account_role_rec.orig_system <>fnd_api.g_miss_char) 
    and (p_cust_account_role_rec.orig_system_reference is not null and p_cust_account_role_rec.orig_system_reference <>fnd_api.g_miss_char) 
    and p_create_update_flag = 'U'
   then
   hz_orig_system_ref_pub.get_owner_table_id 
   (p_orig_system => p_cust_account_role_rec.orig_system, 
   p_orig_system_reference => p_cust_account_role_rec.orig_system_reference, 
   p_owner_table_name =>  'HZ_CUST_ACCOUNT_ROLES', 
   x_owner_table_id => l_mosr_owner_table_id, 
   x_return_status => x_return_status); 
   IF x_return_status = fnd_api.g_ret_sts_success and l_mosr_owner_table_id= nvl(p_cust_account_role_rec.cust_account_role_id,l_mosr_owner_table_id)
   then
      l_validate_flag := 'N';
   end if;
    end if;
    -- orig_system_reference is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.orig_system_reference IS NOT NULL
       and l_validate_flag = 'Y' 
    THEN
        validate_nonupdateable (
            p_column                                => 'orig_system_reference',
            p_column_value                          => p_cust_account_role_rec.orig_system_reference,
            p_old_column_value                      => l_orig_system_reference,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'orig_system_reference is non-updateable. ' ||
                  'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate orig_system_reference ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate primary_flag
    ----------------------------------------------

    -- primary_flag is lookup code in lookup type YES/NO
    IF p_cust_account_role_rec.primary_flag IS NOT NULL AND
       p_cust_account_role_rec.primary_flag <> FND_API.G_MISS_CHAR
    THEN
        validate_lookup (
            p_column                                => 'primary_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_cust_account_role_rec.primary_flag,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag is lookup code in lookup type YES/NO. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- primary_flag is unique per cust_account_id or cust_acct_site_id

    IF p_cust_account_role_rec.primary_flag = 'Y' THEN
        IF p_create_update_flag = 'C' THEN
            l_cust_account_id := p_cust_account_role_rec.cust_account_id;
            l_cust_acct_site_id := p_cust_account_role_rec.cust_acct_site_id;
        END IF;

        IF l_cust_acct_site_id IS NULL OR
           l_cust_acct_site_id = FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCOUNT_ROLES
            WHERE CUST_ACCOUNT_ID = l_cust_account_id
            AND CUST_ACCT_SITE_ID IS NULL
            AND PRIMARY_FLAG = 'Y'
            AND ( p_create_update_flag = 'C' OR
                  p_create_update_flag = 'U' AND ROWID <> p_rowid )
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_CUST_ACCT_ROLE_PRIMARY' );
            FND_MESSAGE.SET_TOKEN( 'ENTITY', 'account' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag is unique per cust_account_id. ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

        ELSE
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_CUST_ACCOUNT_ROLES
            WHERE CUST_ACCOUNT_ID = l_cust_account_id
            AND CUST_ACCT_SITE_ID = l_cust_acct_site_id
            AND PRIMARY_FLAG = 'Y'
            AND ( p_create_update_flag = 'C' OR
                  p_create_update_flag = 'U' AND ROWID <> p_rowid )
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_CUST_ACCT_ROLE_PRIMARY' );
            FND_MESSAGE.SET_TOKEN( 'ENTITY', 'account site' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag is unique per cust_acct_site_id. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

        END IF;
    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate primary_flag ... ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate status
    --------------------------------------

    -- status cannot be set to null during update
    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.status IS NOT NULL
    THEN
        validate_cannot_update_to_null (
            p_column                                => 'status', 
            p_column_value                          => p_cust_account_role_rec.status,
            x_return_status                         => x_return_status );

   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status cannot be updated to null. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- status is lookup code in lookup type REGISTRY_STATUS because
    -- the status is used in party merge.
    IF p_cust_account_role_rec.status IS NOT NULL AND
       p_cust_account_role_rec.status <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U' AND 
           p_cust_account_role_rec.status <> NVL( l_status, FND_API.G_MISS_CHAR ) ) )
    THEN
        validate_lookup (
            p_column                                => 'status',
            p_lookup_type                           => 'REGISTRY_STATUS',
            p_column_value                          => p_cust_account_role_rec.status,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'status is lookup code in lookup type REGISTRY_STATUS. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate status ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_account_role_rec.created_by_module,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_cust_account_role_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate created_by_module ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_cust_account_role_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_cust_account_role_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate application_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    -- Debug info.    
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_cust_account_role (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_cust_account_role;

/**
 * PROCEDURE validate_role_responsibility
 *
 * DESCRIPTION
 *     Validates customer account role responsibility record. Checks for
 *         uniqueness
 *         lookup types
 *         mandatory columns
 *         non-updateable fields
 *         foreign key validations
 *         other validations
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *   IN:
 *     p_create_update_flag           Create update flag. 'C' = create. 'U' = update.
 *     p_role_responsibility_rec      Customer account role responsibility record.
 *     p_rowid                        Rowid of the record (used only in update mode).
 *   IN/OUT:
 *     x_return_status                Return status after the call. The status can
 *                                    be FND_API.G_RET_STS_SUCCESS (success),
 *                                    FND_API.G_RET_STS_ERROR (error),
 *                                    FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *
 */

PROCEDURE validate_role_responsibility (
    p_create_update_flag                    IN     VARCHAR2,
    p_role_responsibility_rec               IN     HZ_CUST_ACCOUNT_ROLE_V2PUB.ROLE_RESPONSIBILITY_REC_TYPE,
    p_rowid                                 IN     ROWID,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_debug_prefix                          VARCHAR2(30) := ''; -- 'validate_role_repsonsibility'

    l_dummy                                 VARCHAR2(1);

    l_responsibility_type                   HZ_ROLE_RESPONSIBILITY.responsibility_type%TYPE;
    l_cust_account_role_id                  NUMBER;
    l_orig_system_reference                 HZ_ROLE_RESPONSIBILITY.orig_system_reference%TYPE;
    l_created_by_module                     HZ_ROLE_RESPONSIBILITY.created_by_module%TYPE;
    l_application_id                        NUMBER;

BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.    
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_role_responsibility (+)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Select fields for later use during update.
    IF p_create_update_flag = 'U' THEN
        SELECT RESPONSIBILITY_TYPE, CUST_ACCOUNT_ROLE_ID, ORIG_SYSTEM_REFERENCE ,
               CREATED_BY_MODULE, APPLICATION_ID
        INTO l_responsibility_type, l_cust_account_role_id, l_orig_system_reference,
             l_created_by_module, l_application_id
        FROM HZ_ROLE_RESPONSIBILITY
        WHERE ROWID = p_rowid;
    END IF;

    --------------------------------------
    -- validate responsibility_id
    --------------------------------------

    IF p_create_update_flag = 'C' THEN

        -- If primary key value is passed, check for uniqueness.
        -- If primary key value is not passed, it will be generated
        -- from sequence by table handler.
 
        IF p_role_responsibility_rec.responsibility_id IS NOT NULL AND
           p_role_responsibility_rec.responsibility_id <> FND_API.G_MISS_NUM
        THEN
        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_ROLE_RESPONSIBILITY
            WHERE RESPONSIBILITY_ID = p_role_responsibility_rec.responsibility_id;

            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', 'responsibility_id' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'responsibility_id is unique during creation if passed in. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;


        END IF;
    END IF;
    
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate responsibility_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate responsibility_type
    ----------------------------------------------

    -- responsibility_type is mandatory field

    validate_mandatory (
        p_create_update_flag                    => p_create_update_flag,
        p_column                                => 'responsibility_type',
        p_column_value                          => p_role_responsibility_rec.responsibility_type,
        x_return_status                         => x_return_status );
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'responsibility_type is mandatory. ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- responsibility_type is lookup code in lookup type SITE_USE_CODE

    IF p_role_responsibility_rec.responsibility_type IS NOT NULL AND
       p_role_responsibility_rec.responsibility_type <> FND_API.G_MISS_CHAR AND
       ( p_create_update_flag = 'C' OR
         ( p_create_update_flag = 'U' AND
           p_role_responsibility_rec.responsibility_type <> NVL( l_responsibility_type, FND_API.G_MISS_CHAR ) ) ) 
    THEN
        validate_lookup (
            p_column                                => 'responsibility_type',
            p_lookup_type                           => 'SITE_USE_CODE',
            p_column_value                          => p_role_responsibility_rec.responsibility_type,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'responsibility_type is lookup code in lookup type SITE_USE_CODE. ' ||
        'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;


        l_responsibility_type := p_role_responsibility_rec.responsibility_type;
    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate responsibility_type ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate cust_account_role_id
    ----------------------------------------------

    -- cust_account_role_id is mandatory field
    -- Since cust_account_role_id is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'cust_account_role_id',
            p_column_value                          => p_role_responsibility_rec.cust_account_role_id,
            x_return_status                         => x_return_status );

        l_cust_account_role_id := p_role_responsibility_rec.cust_account_role_id;
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_role_id is mandatory. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;
    END IF;

    -- cust_account_role_id is non-updateable
    IF p_create_update_flag = 'U' AND
       p_role_responsibility_rec.cust_account_role_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'cust_account_role_id',
            p_column_value                          => p_role_responsibility_rec.cust_account_role_id,
            p_old_column_value                      => l_cust_account_role_id,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_role_id is non-updateable. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- cust_account_role_id is foreign key to hz_cust_account_roles.
    -- Since cust_account_role_id is mandatory and non-updateable,
    -- we only need to check FK during creation.

    IF p_create_update_flag = 'C' AND
       p_role_responsibility_rec.cust_account_role_id IS NOT NULL AND
       p_role_responsibility_rec.cust_account_role_id <> FND_API.G_MISS_NUM
    THEN
        check_cust_account_role_fk (
            p_column                                => 'cust_account_role_id',
            p_column_value                          => p_role_responsibility_rec.cust_account_role_id,
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_role_id is foreign key to hz_cust_account_roles. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;

    -- The combination of cust_account_role_id and responsibility_type
    -- should be unique. 
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'cust_account_role_id = ' || l_cust_account_role_id || ' ' ||
                'role_responsibility_id = ' || l_responsibility_type || ' ' ||
                'create_update_flag = ' || p_create_update_flag || ' ' ||
                'p_rowid = ' || p_rowid || ' ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_ROLE_RESPONSIBILITY
        WHERE CUST_ACCOUNT_ROLE_ID = l_cust_account_role_id
        AND RESPONSIBILITY_TYPE = l_responsibility_type
        AND ( p_create_update_flag = 'C' OR
            ( p_create_update_flag = 'U' AND ROWID <> p_rowid ) )
        AND ROWNUM = 1;

        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DUPLICATE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_role_id - responsibility_type' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'combination of cust_account_role_id and responsibility_type should be unique. ' ||
               'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate cust_account_role_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate orig_system_reference
    ----------------------------------------------

    -- orig_system_reference is non-updateable field
    IF p_create_update_flag = 'U' AND
       p_role_responsibility_rec.orig_system_reference IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'orig_system_reference',
            p_column_value                          => p_role_responsibility_rec.orig_system_reference,
            p_old_column_value                      => l_orig_system_reference,
            x_return_status                         => x_return_status );
     
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'orig_system_reference is non-updateable. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;


    END IF;
  
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate orig_system_reference ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    ----------------------------------------------
    -- validate primary_flag
    ----------------------------------------------

    -- primary_flag is lookup code in lookup type YES/NO
    IF p_role_responsibility_rec.primary_flag IS NOT NULL AND
       p_role_responsibility_rec.primary_flag <> FND_API.G_MISS_CHAR
    THEN 
        validate_lookup (
            p_column                                => 'primary_flag',
            p_lookup_type                           => 'YES/NO',
            p_column_value                          => p_role_responsibility_rec.primary_flag,
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag is lookup code in lookup type YES/NO. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- primary_flag is unique per cust_account_role_id
    IF p_role_responsibility_rec.primary_flag = 'Y' THEN
        IF p_create_update_flag = 'C' THEN
            l_cust_account_role_id := p_role_responsibility_rec.cust_account_role_id;
        END IF;

        BEGIN
            SELECT 'Y' INTO l_dummy
            FROM HZ_ROLE_RESPONSIBILITY
            WHERE CUST_ACCOUNT_ROLE_ID = l_cust_account_role_id
            AND PRIMARY_FLAG = 'Y'
            AND ( p_create_update_flag = 'C' OR
                  p_create_update_flag = 'U' AND ROWID <> p_rowid )
            AND ROWNUM = 1;

            FND_MESSAGE.SET_NAME( 'AR', 'AR_CUST_ROLE_PRIMARY' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'primary_flag is unique per cust_account_role_id. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after validate primary_flag ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate created_by_module
    --------------------------------------

    -- created_by_module is mandatory field
    -- Since created_by_module is non-updateable, we only need to check mandatory
    -- during creation.

    IF p_create_update_flag = 'C' THEN
        validate_mandatory (
            p_create_update_flag                    => p_create_update_flag,
            p_column                                => 'created_by_module',
            p_column_value                          => p_role_responsibility_rec.created_by_module,
            x_return_status                         => x_return_status );
       
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is mandatory. ' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;

    -- created_by_module is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_role_responsibility_rec.created_by_module IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'created_by_module',
            p_column_value                          => p_role_responsibility_rec.created_by_module,
            p_old_column_value                      => l_created_by_module,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
      
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'created_by_module is non-updateable. It can be updated from NULL to a value. ' ||
             'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
   END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after created_by_module ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    --------------------------------------
    -- validate application_id
    --------------------------------------

    -- application_id is non-updateable field. But it can be updated from NULL to
    -- some value.

    IF p_create_update_flag = 'U' AND
       p_role_responsibility_rec.application_id IS NOT NULL
    THEN
        validate_nonupdateable (
            p_column                                => 'application_id',
            p_column_value                          => p_role_responsibility_rec.application_id,
            p_old_column_value                      => l_application_id,
            p_restricted                            => 'N',
            x_return_status                         => x_return_status );
        
   IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'application_id is non-updateable. It can be updated from NULL to a value.' ||
                'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
        END IF;

    END IF;
   
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'(+) after application_id ... ' ||
            'x_return_status = ' || x_return_status,
                   p_prefix =>l_debug_prefix,
                   p_msg_level=>fnd_log.level_statement);
    END IF;


    -- Debug info.
   
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
   hz_utility_v2pub.debug(p_message=>'validate_role_responsibility (-)',
                          p_prefix=>l_debug_prefix,
                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

END validate_role_responsibility;

--------------------------------------
-- private procedures and functions
--------------------------------------

PROCEDURE check_cust_account_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

-- 2310474 : cust_account_id = -1 for profile at party level 

  IF p_column_value <> -1 THEN

    SELECT 'Y' INTO l_dummy
    FROM HZ_CUST_ACCOUNTS
    WHERE CUST_ACCOUNT_ID = p_column_value;

  END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'cust_account_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_accounts' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_cust_account_fk;

PROCEDURE check_cust_acct_site_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    SELECT 'Y' INTO l_dummy
    FROM HZ_CUST_ACCT_SITES
    WHERE CUST_ACCT_SITE_ID = p_column_value;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'cust_acct_site_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_acct_sites' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_cust_acct_site_fk;

PROCEDURE check_cust_site_use_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    SELECT 'Y' INTO l_dummy
    FROM HZ_CUST_SITE_USES
    WHERE SITE_USE_ID = p_column_value;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'site_use_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_site_uses' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_cust_site_use_fk;
PROCEDURE check_cust_site_use_cont_fk(
   p_column                                IN     VARCHAR2,
   p_column_value                          IN     NUMBER,
   p_customer_id                           IN     NUMBER,
   x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);
BEGIN
    SELECT 'Y' INTO l_dummy
    FROM HZ_CUST_ACCOUNT_ROLES
    WHERE CUST_ACCOUNT_ROLE_ID = p_column_value
    AND   CUST_ACCOUNT_ID      = p_customer_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'contact_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_account_roles' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_cust_site_use_cont_fk;

PROCEDURE check_cust_account_role_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN
    SELECT 'Y' INTO l_dummy
    FROM HZ_CUST_ACCOUNT_ROLES
    WHERE CUST_ACCOUNT_ROLE_ID = p_column_value;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'cust_account_role_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_account_roles' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_cust_account_role_fk;

PROCEDURE check_per_all_people_f_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    SELECT 'Y' INTO l_dummy
    FROM PER_ALL_PEOPLE_F
    WHERE PERSON_ID = p_column_value 
      /* Bug 3591694.
         Retrieve only those records, which are effective on sysdate.
         Both effective_start_date and effective_end_date are not null columns and
    as such there is no need to explicitely do a NVL.
       */
      AND EFFECTIVE_START_DATE <= SYSDATE 
      AND EFFECTIVE_END_DATE >= SYSDATE
      AND ROWNUM = 1; 

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'person_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'per_all_people_f' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_per_all_people_f_fk;

PROCEDURE check_collector_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    SELECT 'Y' INTO l_dummy
    FROM AR_COLLECTORS
    WHERE COLLECTOR_ID = p_column_value;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'collector_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ar_collectors');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_collector_fk;

PROCEDURE check_party_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    SELECT 'Y' INTO l_dummy
    FROM HZ_PARTIES
    WHERE PARTY_ID = p_column_value;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'party_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_parties' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_party_fk;

PROCEDURE check_party_site_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    BEGIN
        SELECT 'Y' INTO l_dummy
        FROM HZ_PARTY_SITES
        WHERE PARTY_SITE_ID = p_column_value;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
            FND_MESSAGE.SET_TOKEN( 'FK', 'party_site_id' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
            FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_party_sites' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
    END;

END check_party_site_fk;

PROCEDURE check_currency_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN
    -- Bug Fix: 3877782
    SELECT 'Y' INTO l_dummy
    FROM FND_CURRENCIES
    WHERE CURRENCY_CODE = p_column_value
    AND   CURRENCY_FLAG = 'Y'
    AND   ENABLED_FLAG  = 'Y'
    AND   TRUNC(SYSDATE) BETWEEN TRUNC(NVL(START_DATE_ACTIVE,SYSDATE))
                         AND     TRUNC(NVL(END_DATE_ACTIVE,SYSDATE));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'currency_code' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'fnd_currencies' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_currency_fk;

PROCEDURE check_oe_ship_methods_v_fk (
    p_entity                                IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_org_id                                NUMBER;

BEGIN
    --Bug Fix 2262248, API should NOT DISALLOW the specification of a value for 
    --ship-via based on multi-org installation status for ACOUNT and SITE USE levels.
    /**************************************************************************
    IF p_entity = 'ACCOUNT' THEN

     BEGIN
        SELECT MIN(ORG_ID) INTO l_org_id
        FROM AR_SYSTEM_PARAMETERS;

        IF l_org_id IS NOT NULL THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_COLUMN_SHOULD_BE_NULL' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
            FND_MESSAGE.SET_TOKEN( 'TABLE', 'hz_cust_accounts' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;

            RETURN;
        END IF;

 --Bug Fix 2183072 Handled the exception 
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          FND_MESSAGE.SET_NAME( 'AR', 'AR_NO_ROW_IN_SYSTEM_PARAMETERS');
          FND_MSG_PUB.ADD;
          x_return_status := FND_API.G_RET_STS_ERROR;
    END ;
    END IF;
    **************************************************************************/
    validate_lookup (
        p_column                                => p_column,
        p_lookup_table                          => 'OE_SHIP_METHODS_V',
        p_lookup_type                           => 'SHIP_METHOD',
        p_column_value                          => p_column_value,
        x_return_status                         => x_return_status );

END check_oe_ship_methods_v_fk;

PROCEDURE check_payterm_id_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS
        l_dummy                                 VARCHAR2(1);
  BEGIN
     SELECT 'Y' INTO l_dummy
     FROM RA_TERMS ra
     WHERE ra.term_id = p_column_value
     AND   trunc(sysdate) between START_DATE_ACTIVE and nvl(END_DATE_ACTIVE,trunc(sysdate));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'payment_term_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'RA_TERMS' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_payterm_id_fk;

PROCEDURE check_finchrg_trx_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS
        l_dummy                                 VARCHAR2(1);
  BEGIN
    SELECT 'Y' INTO l_dummy
     FROM AR_RECEIVABLES_TRX art
     WHERE art.receivables_trx_id = p_column_value
     AND   status = 'A';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'finchrg_receivables_trx_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'AR_RECEIVABLES_TRX' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_finchrg_trx_fk;

PROCEDURE check_price_list_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS
        l_dummy                                 VARCHAR2(1);
  BEGIN
  --Bug Fix 2262616, changed the query, which was lookong at SO_PRICE_LISTS
  --to query qp_list_headers_b with active_flag
  /**************************************************************************
     SELECT 'Y' INTO l_dummy
     FROM  SO_PRICE_LISTS pl
     WHERE pl.price_list_id = p_column_value
     AND   sysdate between nvl(pl.start_date_active,sysdate) and nvl(pl.end_date_active,sysdate);
  ***************************************************************************/ 
     SELECT  'Y' 
     INTO    l_dummy 
     FROM    qp_list_headers_b lh
     WHERE   list_header_id = p_column_value 
     AND     list_type_code = 'PRL' 
     AND     (sysdate between nvl(lh.start_date_active,sysdate) and nvl(lh.end_date_active,sysdate) 
     AND     nvl(active_flag, 'N') = 'Y'); 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'price_list_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
-- Bug 3591694        FND_MESSAGE.SET_TOKEN( 'TABLE', 'SO_PRICE_LISTS' );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'QP_LIST_HEADERS_B' );

        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_price_list_fk;

PROCEDURE check_item_cross_ref(
          p_column                                IN     VARCHAR2,
          p_column_value                          IN     VARCHAR2,
          x_return_status                         IN OUT NOCOPY VARCHAR2
) IS
        l_dummy                                 VARCHAR2(1);
  BEGIN
     SELECT 'Y' INTO l_dummy
     FROM MTL_CROSS_REFERENCE_TYPES mtl
     WHERE mtl.cross_reference_type = p_column_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'item_cross_ref_pref' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'mtl_cross_reference_types' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_item_cross_ref;

PROCEDURE check_tax_code(
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy         varchar2(1);
BEGIN
    SELECT 'Y' INTO l_dummy
    FROM AR_VAT_TAX avt
    WHERE avt.tax_code = p_column_value
    AND trunc(SYSDATE) BETWEEN START_DATE AND NVL(END_DATE,trunc(sysdate))
    AND avt.enabled_flag = 'Y'
    AND avt.tax_class = 'O'
    AND avt.displayed_flag = 'Y'
    AND avt.set_of_books_id = (select set_of_books_id from ar_system_parameters);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'tax_code' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'AR_VAT_TAX' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_tax_code;

PROCEDURE check_warehouse(
          p_column                                IN     VARCHAR2,
          p_column_value                          IN     VARCHAR2,
          x_return_status                         IN OUT NOCOPY VARCHAR2
) IS
        l_dummy                                 VARCHAR2(1);
  BEGIN
    SELECT 'Y' INTO l_dummy
    FROM ORG_ORGANIZATION_DEFINITIONS org
    WHERE org.organization_id = p_column_value
    AND trunc(sysdate) <= nvl(trunc(org.disable_date),trunc(sysdate));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'warehouse_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ORG_ORGANIZATION_DEFINITIONS' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_warehouse;

PROCEDURE check_prim_salesrep(
        p_column                                IN     VARCHAR2,
        p_column_value                          IN     VARCHAR2,
        x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy         varchar2(1);
BEGIN

     SELECT 'Y' INTO l_dummy
     FROM RA_SALESREPS ras
     WHERE ras.salesrep_id = p_column_value
     AND sysdate between nvl(start_date_active,sysdate) and nvl(end_date_active,sysdate)
     AND nvl(status, 'A') = 'A'
     AND salesrep_id NOT IN( -1,-2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'primary_salesrep_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'RA_SALESREPS' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_prim_salesrep;

PROCEDURE check_ord_type(
        p_column                                IN     VARCHAR2,
        p_column_value                          IN     VARCHAR2,
        x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy         varchar2(1);
BEGIN
     SELECT 'Y' INTO l_dummy
     FROM   OE_ORDER_TYPES_V ot
     WHERE ot.order_type_id = p_column_value
     AND   sysdate between nvl(ot.start_date_active,sysdate) and nvl(ot.end_date_active,sysdate);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'order_type_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'OE_TRANSACTIONS_TYPES_VL' );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
END check_ord_type;

PROCEDURE check_partial_mandatory_column (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN

    IF p_column_value = FND_API.G_MISS_NUM THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END check_partial_mandatory_column;

PROCEDURE check_partial_mandatory_column (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN

    IF p_column_value = FND_API.G_MISS_CHAR THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END check_partial_mandatory_column;

PROCEDURE validate_gl_id (
    p_gl_name                               IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN

    IF p_column_value IS NOT NULL AND
       p_column_value <> FND_API.G_MISS_NUM
    THEN
        IF NOT FND_FLEX_KEYVAL.validate_ccid (
            appl_short_name               => 'SQLGL',
            key_flex_code                 => 'GL#',
            structure_number              => ARP_GLOBAL.chart_of_accounts_id,
            combination_id                => p_column_value )
        THEN
            FND_MESSAGE.SET_NAME( 'AR', 'AR_AUTO_' ||
                UPPER( p_gl_name ) || '_CCID_INVALID' );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
    END IF;

END validate_gl_id;

PROCEDURE check_auto_hierid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN

    SELECT 'Y' into l_dummy
        FROM   ar_autocash_hierarchies h
        WHERE  h.status = 'A'
        AND    h.autocash_hierarchy_id =
               p_column_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', p_column );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ar_autocash_hierarchies');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_auto_hierid_fk;

PROCEDURE check_stat_cycid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN
    SELECT 'Y' into l_dummy
        FROM   ar_statement_cycles sc
        WHERE  sc.status = 'A'
        AND    sc.statement_cycle_id =
               p_column_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'statement_cycle_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ar_statement_cycles');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_stat_cycid_fk;

PROCEDURE check_dunning_letid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN
      SELECT 'Y' into l_dummy
        FROM   ar_dunning_letter_sets dls
        WHERE  dls.status = 'A'
        AND    dls.dunning_letter_set_id =
               p_column_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'dunning_letter_set_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ar_dunning_letter_sets');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_dunning_letid_fk;

PROCEDURE check_standard_terms_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN
      SELECT   'Y' into l_dummy
        FROM     ra_terms t
        WHERE    trunc(sysdate)
        BETWEEN  t.start_date_active AND
                 nvl(t.end_date_active,trunc(sysdate))
        AND      t.term_id =
                 p_column_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'standard_terms' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ra_terms');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_standard_terms_fk;

PROCEDURE check_grouping_ruleid_fk (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_dummy                                 VARCHAR2(1);

BEGIN
     SELECT   'Y' into l_dummy
        FROM     ra_grouping_rules gr
        WHERE    trunc(sysdate)
        BETWEEN  gr.start_date AND
                 nvl(gr.end_date,trunc(sysdate))
        AND      gr.grouping_rule_id =
                 p_column_value;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_FK' );
        FND_MESSAGE.SET_TOKEN( 'FK', 'grouping_rule_id' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MESSAGE.SET_TOKEN( 'TABLE', 'ra_grouping_rules');
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;

END check_grouping_ruleid_fk;

PROCEDURE check_positive_value (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN
      IF p_column_value < 0 THEN   
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_LESS_THAN_ZERO' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
      END IF;

END check_positive_value;

PROCEDURE check_greater_than_zero (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN
      IF p_column_value <= 0 THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_GREATER_THAN_ZERO' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
      END IF;

END check_greater_than_zero;

/**
 * PRIVATE PROCEDURE enable_debug
 *
 * DESCRIPTION
 *     Turn on debug mode.
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *     HZ_UTILITY_V2PUB.enable_debug
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *
 */

/*PROCEDURE enable_debug IS

BEGIN

    G_DEBUG_COUNT := G_DEBUG_COUNT + 1;

    IF G_DEBUG_COUNT = 1 THEN
        IF FND_PROFILE.value( 'HZ_API_FILE_DEBUG_ON' ) = 'Y' OR
           FND_PROFILE.value( 'HZ_API_DBMS_DEBUG_ON' ) = 'Y'
        THEN
           HZ_UTILITY_V2PUB.enable_debug;
           G_DEBUG := TRUE;
        END IF;
    END IF;

END enable_debug;
*/


/**
 * PRIVATE PROCEDURE disable_debug
 *
 * DESCRIPTION
 *     Turn off debug mode.
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *     HZ_UTILITY_V2PUB.disable_debug
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *
 */

/*PROCEDURE disable_debug IS

BEGIN

    IF G_DEBUG THEN
        G_DEBUG_COUNT := G_DEBUG_COUNT - 1;

        IF G_DEBUG_COUNT = 0 THEN
            HZ_UTILITY_V2PUB.disable_debug;
            G_DEBUG := FALSE;
        END IF;
    END IF;

END disable_debug;
*/


FUNCTION get_index (
    p_val                               IN     VARCHAR2
) RETURN BINARY_INTEGER IS

    l_table_index                       BINARY_INTEGER;
    l_found                             BOOLEAN := FALSE;
    l_hash_value                        NUMBER;

BEGIN

    l_table_index := DBMS_UTILITY.get_hash_value( p_val, 1, TABLE_SIZE );

    IF VAL_TAB.EXISTS(l_table_index) THEN
        IF VAL_TAB(l_table_index) = p_val THEN
            RETURN l_table_index;
        ELSE
            l_hash_value := l_table_index;
            l_table_index := l_table_index + 1;
            l_found := FALSE;

            WHILE ( l_table_index < TABLE_SIZE ) AND ( NOT l_found ) LOOP
                IF VAL_TAB.EXISTS(l_table_index) THEN
                    IF VAL_TAB(l_table_index) = p_val THEN
                        l_found := TRUE;
                    ELSE
                        l_table_index := l_table_index + 1;
                    END IF;
                ELSE
                    RETURN TABLE_SIZE + 1;
                END IF;
            END LOOP;

            IF NOT l_found THEN  -- Didn't find any till the end
                l_table_index := 1;  -- Start from the beginning

                WHILE ( l_table_index < l_hash_value ) AND ( NOT l_found ) LOOP
                    IF VAL_TAB.EXISTS(l_table_index) THEN
                        IF VAL_TAB(l_table_index) = p_val THEN
                            l_found := TRUE;
                        ELSE
                            l_table_index := l_table_index + 1;
                        END IF;
                    ELSE
                        RETURN TABLE_SIZE + 1;
                    END IF;
                END LOOP;
            END IF;

            IF NOT l_found THEN
                RETURN TABLE_SIZE + 1;  -- Return a higher value
            END IF;
        END IF;
    ELSE
        RETURN TABLE_SIZE + 1;
    END IF;

    RETURN l_table_index;

EXCEPTION
    WHEN OTHERS THEN  -- The entry doesn't exists
        RETURN TABLE_SIZE + 1;

END get_index;

PROCEDURE put (
    p_val                               IN     VARCHAR2
) IS

    l_table_index                       BINARY_INTEGER;
    l_stored                            BOOLEAN := FALSE;
    l_hash_value                        NUMBER;

BEGIN

    l_table_index := DBMS_UTILITY.get_hash_value( p_val, 1, TABLE_SIZE );

    IF VAL_TAB.EXISTS(l_table_index) THEN
        IF VAL_TAB(l_table_index) <> p_val THEN --Collision
            l_hash_value := l_table_index;
            l_table_index := l_table_index + 1;

            WHILE (l_table_index < TABLE_SIZE) AND (NOT l_stored) LOOP
                IF VAL_TAB.EXISTS(l_table_index) THEN
                    IF VAL_TAB(l_table_index) <> p_val THEN
                        l_table_index := l_table_index + 1;
                    END IF;
                ELSE
                    VAL_TAB(l_table_index) := p_val;
                    l_stored := TRUE;
                END IF;
            END LOOP;

            IF NOT l_stored THEN --Didn't find any free bucket till the end
                l_table_index := 1;

                WHILE (l_table_index < l_hash_value) AND (NOT l_stored) LOOP
                    IF VAL_TAB.EXISTS(l_table_index) THEN
                        IF VAL_TAB(l_table_index) <> p_val THEN
                            l_table_index := l_table_index + 1;
                        END IF;
                    ELSE
                        VAL_TAB(l_table_index) := p_val;
                        l_stored := TRUE;
                    END IF;
                END LOOP;
            END IF;

        END IF;
    ELSE
        VAL_TAB(l_table_index) := p_val;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        NULL;

END put;

FUNCTION search (
    p_val                               IN     VARCHAR2,
    p_category                          IN     VARCHAR2
) RETURN BOOLEAN IS

    l_table_index                       BINARY_INTEGER;
    l_return                            BOOLEAN;

    l_dummy                             VARCHAR2(1);
    l_position1                         NUMBER;
    l_position2                         NUMBER;

    l_lookup_table                      VARCHAR2(30);
    l_lookup_type                       AR_LOOKUPS.lookup_type%TYPE;
    l_lookup_code                       AR_LOOKUPS.lookup_code%TYPE;

BEGIN

    -- search for the value
    l_table_index := get_index( p_val || G_SPECIAL_STRING || p_category );

    IF l_table_index < table_size THEN
         l_return := TRUE;
    ELSE
        --Can't find the value in the table; look in the database
        IF p_category = 'LOOKUP' THEN

            l_position1 := INSTRB( p_val, G_SPECIAL_STRING, 1, 1 );
            l_lookup_table := SUBSTRB( p_val, 1, l_position1 - 1 );
            l_position2 := INSTRB( p_val, G_SPECIAL_STRING, 1, 2 );
            l_lookup_type := SUBSTRB( p_val, l_position1 + G_LENGTH,
                                     l_position2  - l_position1 - G_LENGTH );
            l_lookup_code := SUBSTRB( p_val, l_position2 + G_LENGTH );

            IF UPPER( l_lookup_table ) = 'AR_LOOKUPS' THEN
            BEGIN
                SELECT 'Y' INTO l_dummy
                FROM   AR_LOOKUPS
                WHERE  LOOKUP_TYPE = l_lookup_type
                AND    LOOKUP_CODE = l_lookup_code
                AND    ( ENABLED_FLAG = 'Y' AND 
                         TRUNC( SYSDATE ) BETWEEN 
                         TRUNC(NVL( START_DATE_ACTIVE,SYSDATE ) ) AND
                         TRUNC(NVL( END_DATE_ACTIVE,SYSDATE ) ) );

                l_return := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_return := FALSE;
            END;
            ELSIF UPPER( l_lookup_table ) = 'SO_LOOKUPS' THEN
            BEGIN
                SELECT 'Y' INTO l_dummy
                FROM   SO_LOOKUPS
                WHERE  LOOKUP_TYPE = l_lookup_type
                AND    LOOKUP_CODE = l_lookup_code
                AND    ( ENABLED_FLAG = 'Y' AND 
                         TRUNC( SYSDATE ) BETWEEN 
                         TRUNC(NVL( START_DATE_ACTIVE,SYSDATE ) ) AND
                         TRUNC(NVL( END_DATE_ACTIVE,SYSDATE ) ) );

                l_return := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_return := FALSE;
            END;
            ELSIF UPPER( l_lookup_table ) = 'OE_SHIP_METHODS_V' THEN
            BEGIN
                SELECT 'Y' INTO l_dummy
                FROM   OE_SHIP_METHODS_V
                WHERE  LOOKUP_TYPE = l_lookup_type
                AND    LOOKUP_CODE = l_lookup_code
                AND    ( ENABLED_FLAG = 'Y' AND 
                         TRUNC( SYSDATE ) BETWEEN 
                         TRUNC(NVL( START_DATE_ACTIVE,SYSDATE ) ) AND
                         TRUNC(NVL( END_DATE_ACTIVE,SYSDATE ) ) )
                AND    ROWNUM = 1;

                l_return := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_return := FALSE;
            END;
       ELSIF UPPER( l_lookup_table ) = 'OE_LOOKUPS' THEN
            BEGIN
                SELECT 'Y' INTO l_dummy
                FROM   OE_LOOKUPS
                WHERE  LOOKUP_TYPE = l_lookup_type
                AND    LOOKUP_CODE = l_lookup_code
                AND    ( ENABLED_FLAG = 'Y' AND
                         TRUNC( SYSDATE ) BETWEEN
                         TRUNC(NVL( START_DATE_ACTIVE,SYSDATE ) ) AND
                         TRUNC(NVL( END_DATE_ACTIVE,SYSDATE ) ) )
                AND    ROWNUM = 1;

                l_return := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_return := FALSE;
            END;
            ELSIF UPPER( l_lookup_table ) = 'FND_COMMON_LOOKUPS' THEN
            BEGIN
                SELECT 'Y' INTO l_dummy
                FROM   FND_COMMON_LOOKUPS
                WHERE  LOOKUP_TYPE = l_lookup_type
                AND    LOOKUP_CODE = l_lookup_code
                AND    ( ENABLED_FLAG = 'Y' AND
                         TRUNC( SYSDATE ) BETWEEN
                         TRUNC(NVL( START_DATE_ACTIVE,SYSDATE ) ) AND
                         TRUNC(NVL( END_DATE_ACTIVE,SYSDATE ) ) )
                AND    ROWNUM = 1;

                l_return := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_return := FALSE;
            END;
            ELSIF UPPER( l_lookup_table ) = 'FND_LOOKUP_VALUES' THEN
            BEGIN
                SELECT 'Y' INTO l_dummy
                FROM   FND_LOOKUP_VALUES
                WHERE  LOOKUP_TYPE = l_lookup_type
                AND    LOOKUP_CODE = l_lookup_code
                AND    ( ENABLED_FLAG = 'Y' AND 
                         TRUNC( SYSDATE ) BETWEEN 
                         TRUNC(NVL( START_DATE_ACTIVE,SYSDATE ) ) AND
                         TRUNC(NVL( END_DATE_ACTIVE,SYSDATE ) ) )
                AND    ROWNUM = 1;

                l_return := TRUE;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    l_return := FALSE;
            END;
            ELSE
                l_return := FALSE;
            END IF;
        END IF;

        --Cache the value
        IF l_return THEN
           put( p_val || G_SPECIAL_STRING || p_category );
        END IF;
    END IF;

    RETURN l_return;

END search;

PROCEDURE validate_mandatory (
    p_create_update_flag                    IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    p_restricted                            IN     VARCHAR2 DEFAULT 'N',
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_restricted = 'N' THEN
        IF ( p_create_update_flag = 'C' AND
             ( p_column_value IS NULL OR
               p_column_value = FND_API.G_MISS_CHAR ) ) OR
           ( p_create_update_flag = 'U' AND
             p_column_value = FND_API.G_MISS_CHAR )
        THEN
            l_error := TRUE;
        END IF;
    ELSE
        IF ( p_column_value IS NULL OR
             p_column_value = FND_API.G_MISS_CHAR )
        THEN
            l_error := TRUE;
        END IF;
    END IF;

    IF l_error THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_mandatory;

PROCEDURE validate_mandatory (
    p_create_update_flag                    IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    p_restricted                            IN     VARCHAR2 DEFAULT 'N',
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_restricted = 'N' THEN
        IF ( p_create_update_flag = 'C' AND
             ( p_column_value IS NULL OR
               p_column_value = FND_API.G_MISS_NUM ) ) OR
           ( p_create_update_flag = 'U' AND
             p_column_value = FND_API.G_MISS_NUM )
        THEN
            l_error := TRUE;
        END IF;
    ELSE
        IF ( p_column_value IS NULL OR
             p_column_value = FND_API.G_MISS_NUM )
        THEN
            l_error := TRUE;
        END IF;
    END IF;

    IF l_error THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_mandatory;

PROCEDURE validate_mandatory (
    p_create_update_flag                    IN     VARCHAR2,
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     DATE,
    p_restricted                            IN     VARCHAR2 DEFAULT 'N',
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_restricted = 'N' THEN
        IF ( p_create_update_flag = 'C' AND
             ( p_column_value IS NULL OR
               p_column_value = FND_API.G_MISS_DATE ) ) OR
           ( p_create_update_flag = 'U' AND
             p_column_value = FND_API.G_MISS_DATE )
        THEN
            l_error := TRUE;
        END IF;
    ELSE
        IF ( p_column_value IS NULL OR
             p_column_value = FND_API.G_MISS_DATE )
        THEN
            l_error := TRUE;
        END IF;
    END IF;

    IF l_error THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_MISSING_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_mandatory;

PROCEDURE validate_nonupdateable (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    p_old_column_value                      IN     VARCHAR2,
    p_restricted                            IN     VARCHAR2 DEFAULT 'Y',
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_column_value IS NOT NULL THEN
        IF p_restricted = 'Y' THEN
            IF ( p_column_value <> FND_API.G_MISS_CHAR OR
                 p_old_column_value IS NOT NULL ) AND
               ( p_old_column_value IS NULL OR
                 p_column_value <> p_old_column_value )
            THEN
               l_error := TRUE;
            END IF;
        ELSE
            IF (p_old_column_value IS NOT NULL AND       -- Bug 3439053.
           p_old_column_value <> FND_API.G_MISS_CHAR)
          AND 
               ( p_column_value = FND_API.G_MISS_CHAR OR
                 p_column_value <> p_old_column_value )
            THEN
               l_error := TRUE;
            END IF;
        END IF;
    END IF;

    IF l_error THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_nonupdateable;

PROCEDURE validate_nonupdateable (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    p_old_column_value                      IN     NUMBER,
    p_restricted                            IN     VARCHAR2 DEFAULT 'Y',
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_column_value IS NOT NULL THEN
        IF p_restricted = 'Y' THEN
            IF ( p_column_value <> FND_API.G_MISS_NUM OR
                 p_old_column_value IS NOT NULL ) AND
               ( p_old_column_value IS NULL OR
                 p_column_value <> p_old_column_value )
            THEN
               l_error := TRUE;
            END IF;
        ELSE
            IF (p_old_column_value IS NOT NULL AND          -- Bug 3439053
           p_old_column_value <> FND_API.G_MISS_NUM)
      AND
               ( p_column_value = FND_API.G_MISS_NUM OR
                 p_column_value <> p_old_column_value )
            THEN
               l_error := TRUE;
            END IF;
        END IF;
    END IF;

    IF l_error THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_nonupdateable;

PROCEDURE validate_nonupdateable (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     DATE,
    p_old_column_value                      IN     DATE,
    p_restricted                            IN     VARCHAR2 DEFAULT 'Y',
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_column_value IS NOT NULL THEN
        IF p_restricted = 'Y' THEN
            IF ( p_column_value <> FND_API.G_MISS_DATE OR
                 p_old_column_value IS NOT NULL ) AND
               ( p_old_column_value IS NULL OR
                 p_column_value <> p_old_column_value )
            THEN
               l_error := TRUE;
            END IF;
        ELSE
            IF (p_old_column_value IS NOT NULL AND       -- Bug 3439053
           p_old_column_value <> FND_API.G_MISS_DATE)
      AND
               ( p_column_value = FND_API.G_MISS_DATE OR
                 p_column_value <> p_old_column_value )
            THEN
               l_error := TRUE;
            END IF;
        END IF;
    END IF;

    IF l_error THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_nonupdateable;

PROCEDURE validate_start_end_date (
    p_create_update_flag                    IN     VARCHAR2,
    p_start_date_column_name                IN     VARCHAR2,
    p_start_date                            IN     DATE,
    p_old_start_date                        IN     DATE,
    p_end_date_column_name                  IN     VARCHAR2,
    p_end_date                              IN     DATE,
    p_old_end_date                          IN     DATE,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_start_date                            DATE := p_old_start_date;
    l_end_date                              DATE := p_old_end_date;

BEGIN

    IF p_create_update_flag = 'C' THEN
        l_start_date := p_start_date;
        l_end_date := p_end_date;
    ELSIF p_create_update_flag = 'U' THEN
        IF p_start_date IS NOT NULL
        THEN
            IF p_start_date = FND_API.G_MISS_DATE THEN
                l_start_date := NULL;
            ELSE
                l_start_date := p_start_date;
            END IF;
        END IF;

        IF p_end_date IS NOT NULL
        THEN
            IF p_end_date = FND_API.G_MISS_DATE THEN
                l_end_date := NULL;
            ELSE
                l_end_date := p_end_date;
            END IF;
        END IF;
    END IF;

    IF l_end_date IS NOT NULL AND
       l_end_date <> FND_API.G_MISS_DATE AND
       ( l_start_date IS NULL OR
         l_start_date = FND_API.G_MISS_DATE OR
         l_start_date > l_end_date )
    THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_DATE_GREATER' );
        FND_MESSAGE.SET_TOKEN( 'DATE2', p_end_date_column_name );
        FND_MESSAGE.SET_TOKEN( 'DATE1', p_start_date_column_name );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_start_end_date;

PROCEDURE validate_cannot_update_to_null (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN

    IF p_column_value = FND_API.G_MISS_CHAR THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_TO_NULL' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_cannot_update_to_null;

PROCEDURE validate_cannot_update_to_null (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     NUMBER,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN

    IF p_column_value = FND_API.G_MISS_NUM THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_TO_NULL' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_cannot_update_to_null;

PROCEDURE validate_cannot_update_to_null (
    p_column                                IN     VARCHAR2,
    p_column_value                          IN     DATE,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

BEGIN

    IF p_column_value = FND_API.G_MISS_DATE THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_TO_NULL' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
        FND_MSG_PUB.ADD;
        x_return_status := FND_API.G_RET_STS_ERROR;
    END IF;

END validate_cannot_update_to_null;

PROCEDURE validate_lookup (
    p_column                                IN     VARCHAR2,
    p_lookup_table                          IN     VARCHAR2 DEFAULT 'AR_LOOKUPS',
    p_lookup_type                           IN     VARCHAR2,
    p_column_value                          IN     VARCHAR2,
    x_return_status                         IN OUT NOCOPY VARCHAR2
) IS

    l_error                                 BOOLEAN := FALSE;

BEGIN

    IF p_column_value IS NOT NULL AND
       p_column_value <> FND_API.G_MISS_CHAR THEN

        IF p_lookup_type = 'YES/NO' THEN
            IF p_column_value NOT IN ('Y', 'N') THEN
                l_error := TRUE;
            END IF;
        ELSE
            IF NOT search(p_lookup_table || G_SPECIAL_STRING ||
                          p_lookup_type || G_SPECIAL_STRING || p_column_value,
                          'LOOKUP' )
            THEN
                l_error := TRUE;
            END IF;
        END IF;

        IF l_error THEN
            FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_INVALID_LOOKUP' );
            FND_MESSAGE.SET_TOKEN( 'COLUMN', p_column );
            FND_MESSAGE.SET_TOKEN( 'LOOKUP_TYPE', p_lookup_type );
            FND_MSG_PUB.ADD;
            x_return_status := FND_API.G_RET_STS_ERROR;
        END IF;
    END IF;

END validate_lookup;

END HZ_ACCOUNT_VALIDATE_V2PUB;
/
COMMIT;
