/**
 *  Copyright (c) 2001, 2014 Oracle Corporation Redwood Shores, California, USA
 *                          All rights reserved.
 *=======================================================================
 * FILE       ARH2PASB.pls
 *
 * PACKAGE    HZ_PARTY_V2PUB
 *
 * DESCRIPTION
 *     This package contains public API for person, organization and group.
 *
 * RELATED PACKAGES
 *
 * PUBLIC VARIABLES
 *
 * PUBLIC PROCEDURES
 *     create_person
 *     update_person
 *     get_person_rec
 *     create_organization
 *     update_organization
 *     get_organization_rec
 *     create_group
 *     update_group
 *     get_group_rec
 *     get_party_rec
 *
 * PUBLIC FUNCTIONS
 *
 * NOTES
 *   As of mix-n-match project, we are going to introduce the third profile:
 *   SST (single-source-of-truth) profile. The profile will be identified by
 *   actual_content_source = 'SST'. The content_source_type is obsoleted and
 *   replaced by actual_content_source because lots of teams are hard-coding
 *   content_source_type = 'USER_ENTERED' in their queries.
 *
 *   This package is re-organized for mix-n-match because of the funcationality
 *   changes.
 *
 *   Creating person / organization (create_person/organization API)
 *     We will find out NOCOPY the real data source based on the content_source_type
 *     and actual_content_source for backward compatibility consideration.
 *
 *     If the real data source is 'SST' or 'USER_ENTERED',
 *       If the party already exists, we will error out. Otherwise, we create
 *       a profile with content_source_type = 'USER_ENTERED' and
 *       actual_content_source = 'SST'. We also create a party based on the
 *       profile.
 *     If the real data source is a third party data source,
 *       If the profile of this data source already exists for this party,
 *       we will error out. If the party exists, we will create only the profile
 *       with content_source_type and actual_content_source equals to the third
 *       party data source. If the mix-n-match is enabled and the third party
 *       data source is seleced as part of ranked data sources, we will propagate
 *       the change to the SST profile as well as the party.
 *
 *       If the party does not exists, we will use the third party profile to
 *       create user-entered, third party and SST profiles and denormalie the SST
 *       profile to the party.
 *
 *   Updating person / organization (update_person/organization API)
 *     We will update the profile no matter it is user-entered or third party.
 *     If the profile is SST profile, we will raise error if some attributes
 *     is not updated by the user. If the profile is user-entered or third party
 *     profile, we will update SST profile based on the rules set up by mix-n-match.
 *
 *   In summary, SST profile is the profile that we need to denormalize into
 *     hz_parties. We will generate / update SST profile if 1) mix-n-match is
 *     enabled 2) the third party data source is selected 3) this is the first
 *     time we create the third party profile.
 *
 *   The DQM and BES callouts are moved in do_create/update_party procedure.
 *   DQM:  We need to call DQM procedure to sync person and organization whenever
 *         we touch SST profile
 *   BES:  We need to raise event whenever we touch SST profile and in the event,
 *         we will pass SST record.
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Indrajit Sen        o Created.
 *   01-28-2001    Kate Shan           o modify API for DNB V3 ENHANCEMENT
 *                                       base bug#2188696
 *   01-29-2002    P.Suresh            o Bug No : 2196111. Added person name
 *                                       to the profile table handler in
 *                                       do_create_person_profile and
 *                                       do_update_person_profile.
 *   02-20-2002    Kate Shan           o bug fix 2229720
 *   02-21-2002    Chris Saulit        o Modify do_create_person_name to
 *                                       call the new name formatting routine.
 *                                       Base Bug #2221071
 *   04-30-2002    Jianying Huang      o Bug 2197181: Re-organized the package
 *                                       because of mix-n-match project. See
 *                                       notes for more details.
 *   05-13-2002    Herve Yu            o Bug 2290537: Old image for BES callout
 *   05-17-2002    Kate Shan           o Migrate failure score column to Credit Rating
 *   05-25-2002    Jianying Huang      o Fixed bugs for denormalization issue.
 *   06-25-2002    Jianying Huang      o Bug 2433734: bug fixes for mix-n-match.
 *   06-28-2002    P.Suresh            o Bug No : 2425365. Increased the length of the
 *                                       column previous_last_name in party_dup_rec_type
 *                                       record type from 40 to 150.
 *   07-02-2002    Jianying Huang      o Bug 2445583: Fixed caching issue by calling
 *                                       LoadDataSources every time we call the API.
 *   07-15-2002    Jianying Huang      o Bug 2445583: reset policy fn application
 *                                       context in exception handler.
 *   09-03-2002    Jyoti Pandey        o Bug 2486394 Data Sharing and security DSS
 *   11-20-2002    P.Suresh            o Bug No : 2676848. Added NOCOPY hint for
 *                                       OUT and IN OUT parameters.
 *   06-FEB-2003    Porkodi C          o Bug 2684319: Added deceased_flag field to person_rec_type.
 *   04-Mar-2003    Porkodi C          o Bug 2794173: Modified the code to assign default value to deceased_flag.
 *   06-MAY-2003    Sisir              o Bug 2970763: Modified for profile versioning project
 *                                       1.Modified do_create_person_profile and do_create_org_profile
 *                                       procedures by adding new parameter,version_number.
 *                                       2.Modified do_update_person_profile and do_update_org_profile
 *                                       to check a new profile,HZ_PROFILE_VERSION before creating/
 *                                       updating profiles.
 *   11-MAY-2003    Ramesh Ch          o Bug 2492748: Increased the length of the column
 *                                       person_iden_type from 5 to 30 in party_dup_rec_type
 *                                       record type.
 *   26-SEP-2003    Rajib Ranjan Borah o Bug Number 3099624. Sensitive HR data will not
 *                                       be propagated into HZ_PERSON_PROFILES.
 *   14-OCT-2003    Dhaval Mehta       o Bug 3040565 :  Modified the parameter p_class_category to
 *                                       set_primary_code_assignment to pass actual local_activity_code_type,
 *                                       instead of coding it to 'NACE'
 *   04-NOV-2003    Sisir              o Bug 3222456:Modified do_update_person_profile and do_update_org_profile
 *                                       to check if it same day updatation;if so effective_end_date is set
 *                                       as sysdate otherise sysdate-1.
 *   10-DEC-2003    Ramesh Ch.         o Commented out the g_debug,enable_debug,disable_debug
 *                                       & calls to hz_utility_pub's
 *                                       debug & debug_return_messages and added code to call to
 *                                       hz_utility_pub's debug & debug_return_messages as part of
 *                                       Common Logging Infrastructure uptake.
 *  29-Mar-2004     Ramesh Ch.         o Bug No: 2771835. Modified the code to
 *                                       make address text column in hz_cust_acct_sites_all as dirty.
 *   03-Mar-2004    Rajib Ranjan Borah o Bug 3317806.Modified do_create_party and do_update_party
 *                                       For non user entered data, if local_activity_code is
 *                                       invalid with respect to the position of the decimal point,
 *                                       then replace it with the valid value from fnd_lookup_values.
 *  20-Apr-2004     Dhaval Mehta       o Bug 3560323 : When HZ_PROFILE_VERSION = New Version, the
 *                                       business report  was not copied to newly
 *                                       created org profile record. Added code
 *                                       to copy BIR to new record in procedure do_update_org_profile.
 *  02-Aug-2004     V.Ravichandran     o Bug 2467872 : Added the field mission_statement to
 *                                       group_rec_type.
 *  06-AUG-2004     Jianying Huang     o Bug 3818648: check dss profile before call test_instance.
 *  02-SEP-2004     Jianying Huang     o Bug 3835601: replaced the dss message with a more user
 *                                       friendly message.
 *  19-Sep-2004     V.Ravichandran     o Bug 3856348 : Added the parameter created_by_module to
 *                                       set_primary_code_assignment() procedure.
 *  24-Sep-2004     V.Ravichandran     o Bug 3868940 : Defaulted the rated_as_of_date to sysdate
 *                                      while creating a credit_rating in populate_credit_rating()
 *                                       procedure and retained its previous value while updating
 *                                       a credit rating in populate_credit_rating procedure.
 *                                       Called HZ_PARTY_INFO_V2PUB.create/update_credit_rating
 *                                       from populate_credit_rating() procedure directly
 *                                       instead of calling the V1 APIs
 *                                       HZ_PARTY_INFO_PUB.create/updating_credit_rating.
 *                                       Commented out the procedure org_rec_to_cr_rec.
 *  26-NOV-2004     V.Ravichandran     o Bug 3999044. Modified the procedure
 *                                       do_create_update_party_only and
 *                                       do_update_person_profile to take the parameters
 *                                       known_as,person_first_name_phonetic,middle_name_phonetic,
 *                                       person_last_name_phonetic also into consideration for
 *                                       creating the person name while updating person
 *                                       information.
 *  07-DEC-2004     V.Ravichandran     o Bug 4043346. Modified the procedure
 *                                       do_process_classification so as to
 *                                       call HZ_CLASSIFICATION_v2PUB.set_primary_code_assignment
 *                                       procedure to update the code assignment
 *                                       when  SIC_CODE/SIC_CODE_TYPE/both change.
 *  31-DEC-2004   Rajib Ranjan Borah   o SSM SST Integration and Extension.
 *                                       In do_create_party, call HZ_MIXNM_UTILITY.create_exceptions
 *                                       if actual_content_source is not USER_ENTERED
 *                                       and no prior profile exists.
 *  12-JAN-2005   Dhaval Mehta         o SSM SST Integration and Extension.
 *                                       In do_create_party, call
 *                                       HZ_MIXNM_UTILITY.populateMRRExc
 *  04-MAR-2005   V.Ravichandran       o Bug 3876180 : Modified the procedure
 *                                       do_process_classification() to end date the code
 *                                       assignment in HZ_CODE_ASSIGNMENTS when the category_code/
 *                                       SIC_CODE and SIC_CODE_TYPE are nullified in the
 *                                       classification tab of the customer standard form.
 *  14-MAR-2005   Sravanthi A          o Bug 4232060 : Modified the procedure do_process_classification
 *                                       to pass created_by_module in calls to
 *                                       set_primary_code_assignemnt based on type of party being
 *                                       created or updated.
 *  17-MAR-2005   Dhaval Mehta         o Bug 4244112 : populate MRR exceptions
 *                                       only when first third party profile is
 *                                       created. For sub sequent profiles,
 *                                       mix-n-match API populates the
 *                                       exceptions. No need to populate for
 *                                       just UE record.
 *  19-MAY-2005   Jianying Huang       o Bug 4347910: added logic for R12 party usage project.
 *  07-JUL-2005   Dhaval Mehta         o Bug 4376604 : signature for procedure
 *                                       isDataSourceSelected is changed
 *  20-JUL-2005   Dhaval Metha         o Bug 4490715 : added logic for eTax integration
 *  25-JUL-2005   Jianying Huang       o Bug 3160144: Added home_country in organization rec type.
 *  02-AUG-2005   Arnold Ng            o Add populate function of person and organization for
 *                                       integration service.
 *  31-AUG-2005   Jianying Huang       o Added procedure validate_party_name for supplier name
 *                                       uniqueness check.
 *  04-OCT-2005   Anuj Singhal         o Bug 4586451:Added validation in do_create_party to check for the actual content
 *                                       source while creating supplier usage to maintain supplier name uniqueness.Called
 *                                       procedure validate_party_name from do_update_party to main supplier name
 *                                       uniqueness.Added a call in the procedure do_create_update_party_only to the
 *                                       iprocurement API to update them in case the supplier name is changing.
 *  13-OCT-2005   Arnold Ng            o Add condition to check global vaiable
 *                                       HZ_UTILITY_V2PUB.G_LOGICAL_API_CALLED
 *  18-OCT-2005   Dhaval Mehta         o Bug 4540322 : Fix issue with created_by_module
 *                                       in do_process_classification
 *  01-DEC-2005   Arnold Ng            o Remove condition to check global vaiable
 *                                       HZ_UTILITY_V2PUB.G_LOGICAL_API_CALLED
 *  13-DEC-2005   Dhaval Mehta         o Bug 4239442 : Create MOSR entry when
 *                                       profile is created instead of party.
 *                                       Create MOSR entry for GROUP party only
 *                                       from do_create_update_party_only
 *  15-FEB-2006   Jianying Huang       o Bug 5002370: removed default party usage.
 *  01-JUN-2006   Sai Choudhary        o Bug 4866187: Introduced condition to  avoid 
 * 					 duplicate calls to sync function.
 *  07-JUL-2006   Idris Ali            o Bug 5370799: Modified to call dqm sync even if  
 *                                       orig_sytem_ref not equal to null.
 *  30-AUG-2006   avjha                o Bug 5227963: Increased the Type Length of PersonName
 *					 from hz_person_profiles.person_name%TYPE [VARCHAR2(450)]
 * 					 to VARCHAR2(454) to avoid any error due to Overflow.
 *  28-JUN-2009   S.V.Sowjanya         o Bug 8537020. Modified do_update_party to check for  
 *                                        fnd_api.g_miss_char when looking for NACE. 
 *  13-May-2010    Sudhir Gokavarapu   o Bug 9648645 Added bank related variables 
 *                                       g_bank_code,g_branch_code,g_bank_or_branch_number at global level so that 
 *                                       those can be used in profile insert_row API after fetching
 *                                       values from get_organization_rec API.
 *  30-Jun-2010    Sudhir Gokavarapu   o Bug9735521 - In update_organization , update_person APIs
 *                                       When Actual Content Source is NULL then 'USER_ENTERED' is assigned.  
 *  10-Dec-2011    Sudhir Gokavarapu   o Bug 13117445
 *                                       Added an parameter p_party_create_update_flag
 *                                       to do_create_party_profile procedure.
 *                                       Passing l_party_create_update_flag value
 *                                       to new parameter from do_create_party procedure. 
 *  26-Sep-2014    Sudhir Gokavarapu   o Bug 19479134 -- Dqm_sync calls moved prior to business event calls.
 *  19-Feb-2017    Sreedhar Mohan      o Defect 41052 - Contact_point_conversion workers are locking each other.
 *                                       Commented out update on hz_cust_acct_sites_all for updating 
 *                                       address_text column as we are not doing party search on address_key.
 *  
 */

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile(120.59.12010000.8=120.65.12020000.2)(120.58.12000000.2=120.59):~PROD:~PATH:~FILE

SET VERIFY OFF;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
CREATE OR REPLACE PACKAGE BODY HZ_PARTY_V2PUB AS
/*$Header: ARH2PASB.pls 120.65.12020000.2 2014/10/20 06:05:41 rgokavar ship $ */

  --------------------------------------
  -- declaration of private global varibles
  --------------------------------------

  g_debug_count                        NUMBER := 0;
  --g_debug                              BOOLEAN := FALSE;

  g_pkg_name                           CONSTANT VARCHAR2(30) := 'HZ_PARTY_V2PUB';

  g_profile_fmt_bkwd_compatible
             CONSTANT VARCHAR2(30) := 'HZ_FMT_BKWD_COMPATIBLE';

  g_apps_context                       CONSTANT VARCHAR2(30) := 'dnb_used';

  TYPE party_dup_rec_type IS RECORD(
    sic_code                           VARCHAR2(30),
    sic_code_type                      VARCHAR2(30),
    hq_branch_ind                      VARCHAR2(2),
    tax_reference                      VARCHAR2(50),
    jgzz_fiscal_code                   VARCHAR2(20),
    duns_number_c                      VARCHAR2(30),
    pre_name_adjunct                   VARCHAR2(30),
    first_name                         VARCHAR2(150),
    middle_name                        VARCHAR2(60),
    last_name                          VARCHAR2(150),
    name_suffix                        VARCHAR2(30),
    title                              VARCHAR2(60),
    academic_title                     VARCHAR2(260),
    previous_last_name                 VARCHAR2(150),
    known_as                           VARCHAR2(240),
    known_as2                          VARCHAR2(240),
    known_as3                          VARCHAR2(240),
    known_as4                          VARCHAR2(240),
    known_as5                          VARCHAR2(240),
    person_iden_type                   VARCHAR2(30),
    person_identifier                  VARCHAR2(60),
    country                            VARCHAR2(60),
    address1                           VARCHAR2(240),
    address2                           VARCHAR2(240),
    address3                           VARCHAR2(240),
    address4                           VARCHAR2(240),
    city                               VARCHAR2(60),
    postal_code                        VARCHAR2(60),
    state                              VARCHAR2(60),
    province                           VARCHAR2(60),
    county                             VARCHAR2(60),
    url                                VARCHAR2(2000),
    email_address                      VARCHAR2(2000),
    next_fy_potential_revenue          NUMBER,
    mission_statement                  VARCHAR2(2000),
    organization_name_phonetic         VARCHAR2(320),
    person_first_name_phonetic         VARCHAR2(60),
    person_last_name_phonetic          VARCHAR2(60),
    middle_name_phonetic               VARCHAR2(60),
    language_name                      VARCHAR2(4),
    analysis_fy                        VARCHAR2(5),
    fiscal_yearend_month               VARCHAR2(30),
    employees_total                    NUMBER,
    curr_fy_potential_revenue          NUMBER,
    year_established                   NUMBER,
    gsa_indicator_flag                 VARCHAR2(1),
    created_by_module                  VARCHAR2(150),
    application_id                     NUMBER
  );

  -- Bug 2197181: added for mix-n-match project.

  g_per_mixnmatch_enabled              VARCHAR2(1);
  g_per_entity_attr_id                 NUMBER;
  g_per_selected_datasources           VARCHAR2(600);

  g_org_mixnmatch_enabled              VARCHAR2(1);
  g_org_entity_attr_id                 NUMBER;
  g_org_selected_datasources           VARCHAR2(600);

  g_resource_busy                      EXCEPTION;
  PRAGMA EXCEPTION_INIT(g_resource_busy, -00054);
    -- Bug 9648645 Added below bank related variables so that 
    -- those can be fetched in get_organization_rec api and used in profile insert_row API.
    g_bank_code                        VARCHAR2(30);
    g_branch_code                      VARCHAR2(30);
    g_bank_or_branch_number            VARCHAR2(60);
    g_party_id                         NUMBER;

  --------------------------------------
  -- declaration of private procedures and functions
  --------------------------------------

  --PROCEDURE enable_debug;

  --PROCEDURE disable_debug;

  PROCEDURE do_create_person_profile(
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_party_id                         IN     NUMBER,
    x_profile_id                       OUT    NOCOPY NUMBER,
    p_version_number                   IN     NUMBER,
    x_rowid                            OUT    NOCOPY ROWID
  );

  PROCEDURE do_update_person_profile(
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_old_person_rec                   IN     PERSON_REC_TYPE,
    p_data_source_type                 IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  );

  PROCEDURE do_create_org_profile(
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_party_id                         IN     NUMBER,
    x_profile_id                       OUT    NOCOPY NUMBER,
    p_version_number                   IN     NUMBER,
    x_rowid                            OUT    NOCOPY ROWID
  );

  PROCEDURE do_update_org_profile(
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE,
    p_data_source_type                 IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  );

  PROCEDURE do_create_party_profile (
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    p_person_rec                       IN OUT NOCOPY PERSON_REC_TYPE,
    p_organization_rec                 IN OUT NOCOPY ORGANIZATION_REC_TYPE,
    p_content_source_type              IN     VARCHAR2,
    p_actual_content_source            IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER,
    p_party_create_update_flag         IN     VARCHAR2
  );

  PROCEDURE do_update_party_profile (
    p_party_type                       IN     VARCHAR2,
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_data_source_type                 IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  );

  PROCEDURE do_get_party_profile (
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    p_data_source_type                 IN     VARCHAR2,
    x_person_rec                       OUT    NOCOPY PERSON_REC_TYPE,
    x_organization_rec                 OUT    NOCOPY ORGANIZATION_REC_TYPE
  );

  PROCEDURE do_create_update_party_only(
    p_create_update_flag               IN     VARCHAR2,
    p_party_type                       IN     VARCHAR2,
    -- p_party_id is used in update mode only.
    p_party_id                         IN     NUMBER := NULL,
    p_check_object_version_number      IN     VARCHAR2 := 'Y',
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    p_person_rec                       IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_group_rec                        IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_old_group_rec                    IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    -- x_party_id and x_party_number are used in create mode.
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2
  );

  PROCEDURE do_create_party (
    p_party_type                       IN     VARCHAR2,
    p_party_usage_code                 IN     VARCHAR2,
    p_person_rec                       IN OUT NOCOPY PERSON_REC_TYPE,
    p_organization_rec                 IN OUT NOCOPY ORGANIZATION_REC_TYPE,
    p_group_rec                        IN OUT NOCOPY GROUP_REC_TYPE,
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  );

  PROCEDURE do_update_party (
    p_party_type                       IN     VARCHAR2,
    p_person_rec                       IN OUT NOCOPY PERSON_REC_TYPE,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_organization_rec                 IN OUT NOCOPY ORGANIZATION_REC_TYPE,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_group_rec                        IN OUT NOCOPY GROUP_REC_TYPE,
    p_old_group_rec                    IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    x_profile_id                       OUT    NOCOPY NUMBER,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  );

  FUNCTION party_exists(
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2
  ) RETURN VARCHAR2;

  FUNCTION party_profile_exists(
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    p_data_source_type                 IN     VARCHAR2
  ) RETURN VARCHAR2;

  FUNCTION reset_sst_to_userentered(
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER
  ) RETURN VARCHAR2;

  FUNCTION do_create_person_name(
    p_person_rec                       IN     PERSON_REC_TYPE
  ) RETURN VARCHAR2;

  FUNCTION do_create_party_name(
    p_person_first_name                IN     VARCHAR2,
    p_person_last_name                 IN     VARCHAR2
  ) RETURN VARCHAR2;

  PROCEDURE do_update_party_rel_name(
    p_party_id                         IN     NUMBER,
    p_party_name                       IN     HZ_PARTIES.PARTY_NAME%TYPE
  );

  PROCEDURE do_process_classification(
    p_create_update_flag               IN     VARCHAR2,
    p_party_type                       IN     VARCHAR2,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_person_rec                       IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_group_rec                        IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_old_group_rec                    IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_data_source_type                 IN     VARCHAR2,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  );

  -- Bug 3868940
  /*
  PROCEDURE org_rec_to_cr_rec(
    p_create_update_flag               IN     VARCHAR2,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    x_credit_rating_rec                OUT    NOCOPY hz_party_info_pub.credit_ratings_rec_type
  );
  */

  PROCEDURE populate_credit_rating(
    p_create_update_flag               IN     VARCHAR2,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  );

---Bug No: 2771835------------------------------------------
PROCEDURE update_party_search(p_party_id          IN  NUMBER,
                              p_old_party_name    IN  VARCHAR2,
                              p_new_party_name    IN  VARCHAR2,
                              p_old_tax_reference IN  VARCHAR2,
                              p_new_tax_reference IN  VARCHAR2);
FUNCTION isModified(p_old_value VARCHAR2,p_new_value VARCHAR2)
RETURN BOOLEAN;
PROCEDURE update_rel_person_search(p_old_person_rec IN  HZ_PARTY_V2PUB.PERSON_REC_TYPE,
                                   p_new_person_rec IN  HZ_PARTY_V2PUB.PERSON_REC_TYPE);
-------------------------Bug 4586451
PROCEDURE validate_party_name (
    p_party_id                    IN     NUMBER,
    p_party_name                  IN     VARCHAR2,
    x_return_status               IN OUT NOCOPY VARCHAR2
);
---------------------------------Bug 4586451

---End of Bug No: 2771835---------------------------------------

  --------------------------------------
  -- private procedures and functions
  --------------------------------------

  /**
   * PRIVATE PROCEDURE enable_debug
   *
   * DESCRIPTION
   *     Turn on debug mode.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_utility_v2pub.enable_debug
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Jianying Huang      o Created.
   *
   */

  /*PROCEDURE enable_debug IS

  BEGIN
    g_debug_count := g_debug_count + 1;

    IF g_debug_count = 1 THEN
      IF fnd_profile.value('HZ_API_FILE_DEBUG_ON') = 'Y' OR
         fnd_profile.value('HZ_API_DBMS_DEBUG_ON') = 'Y'
      THEN
        hz_utility_v2pub.enable_debug;
        g_debug := TRUE;
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
   *     hz_utility_v2pub.disable_debug
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Jianying Huang      o Created.
   *
   */

  /*PROCEDURE disable_debug IS

  BEGIN

    IF g_debug THEN
      g_debug_count := g_debug_count - 1;

      IF g_debug_count = 0 THEN
        hz_utility_v2pub.disable_debug;
        g_debug := FALSE;
      END IF;
    END IF;

  END disable_debug;
  */

  /**
   * PRIVATE FUNCTION party_exists
   *
   * DESCRIPTION
   *    Returns if party exists based on the party type
   *    and party_id.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *       p_party_id
   *     OUT:
   *       x_party_number
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  FUNCTION party_exists(
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2
  ) RETURN VARCHAR2 IS

    CURSOR c_party_exists IS
      SELECT party_type, party_number
      FROM hz_parties
      WHERE party_id = p_party_id;

    l_party_type                       VARCHAR2(30);
    l_party_number                     HZ_PARTIES.PARTY_NUMBER%TYPE;
    l_debug_prefix                     VARCHAR2(30) := '';
  BEGIN
    -- Debug info.

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug(p_message=>'party exists (+)',
                             p_prefix=>l_debug_prefix,
                             p_msg_level=>fnd_log.level_procedure);
    END IF;



    OPEN c_party_exists;
    FETCH c_party_exists INTO l_party_type, l_party_number;

    IF c_party_exists%NOTFOUND THEN
      l_party_type := NULL;
    END IF;
    CLOSE c_party_exists;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,
                               p_message=>'party exists (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    IF l_party_type IS NULL THEN
      x_party_number := NULL;
      RETURN 'N';
    ELSIF l_party_type = p_party_type THEN
      x_party_number := l_party_number;
      RETURN 'Y';
    ELSE
      /* new message */
      fnd_message.set_name('AR','HZ_DUP_PARTY_WITH_PARTY_TYPE');
      fnd_message.set_token('PARTY_ID', p_party_id);
      fnd_message.set_token('PARTY_TYPE', l_party_type);
      fnd_msg_pub.add;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

  END party_exists;

  /**
   * PRIVATE FUNCTION do_create_person_name
   *
   * DESCRIPTION
   *     Creates person name.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_id
   *       p_party_name
   *     OUT:
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   * 02-21-2002    Chris Saulit        o Modify do_create_person_name to
   *                                     call the new name formatting routine.
   *                                     Base Bug #2221071
   */

  FUNCTION do_create_person_name (
    p_person_rec                       IN     PERSON_REC_TYPE
  ) RETURN VARCHAR2 IS

 -- l_person_name                      hz_person_profiles.person_name%TYPE;
    l_person_name                      VARCHAR2(454); --Type Length changed as per bug #5227963
    l_debug_prefix                     VARCHAR2(30) := '';

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_person_name (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_person_name (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    --
    --  Check "backwards compatability" profile option and determine
    --  whether to stick with the old-style name formatting, or call
    --  the new dynamic name formatting routines.
    --

    -- use new routines

    IF nvl(fnd_profile.value(g_profile_fmt_bkwd_compatible),'Y') = 'N' THEN

      --
      --  Invoke the person name formatting API
      --

      DECLARE

        l_line_cnt            NUMBER;
        l_return_status       VARCHAR2(1);
        l_msg_cnt             NUMBER;
        l_msg_data            VARCHAR2(2000);

        l_formatted_lines_cnt NUMBER;
        l_formatted_name_tbl  hz_format_pub.string_tbl_type;

      BEGIN

        hz_format_pub.format_name (
          -- input parameters
          p_person_title                => p_person_rec.person_title,
          p_person_first_name           => p_person_rec.person_first_name,
          p_person_middle_name          => p_person_rec.person_middle_name,
          p_person_last_name            => p_person_rec.person_last_name,
          p_person_name_suffix          => p_person_rec.person_name_suffix,
          p_person_known_as             => p_person_rec.known_as,
          p_first_name_phonetic         => p_person_rec.person_first_name_phonetic,
          p_middle_name_phonetic        => p_person_rec.middle_name_phonetic,
          p_last_name_phonetic          => p_person_rec.person_last_name_phonetic,
          -- output parameters
          x_return_status               => l_return_status,
          x_msg_count                   => l_msg_cnt,
          x_msg_data                    => l_msg_data,
          x_formatted_name              => l_person_name,
          x_formatted_lines_cnt         => l_formatted_lines_cnt,
          x_formatted_name_tbl          => l_formatted_name_tbl
        );

        -- If there are any errors, ignore them.  Not serious enough
        -- to abort the transaction.  Messages will be on the stack.
        -- If person name has not been determined, it will default
        -- to the original logic below.

      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;

    END IF;

    IF l_person_name IS NULL THEN

      --
      --  Preserve backwards compatibility and use the original logic
      --

      IF p_person_rec.person_title IS NOT NULL AND
         p_person_rec.person_title <> FND_API.G_MISS_CHAR
      THEN
        l_person_name := p_person_rec.person_title;
      END IF;

      IF p_person_rec.person_first_name IS NOT NULL AND
         p_person_rec.person_first_name <> FND_API.G_MISS_CHAR
      THEN
        IF l_person_name IS NOT NULL THEN
          l_person_name := l_person_name || ' ' || p_person_rec.person_first_name;
        ELSE
          l_person_name := p_person_rec.person_first_name;
        END IF;
      END IF;

      IF p_person_rec.person_middle_name IS NOT NULL AND
         p_person_rec.person_middle_name <> FND_API.G_MISS_CHAR
      THEN
        IF l_person_name IS NOT NULL THEN
          l_person_name := l_person_name || ' ' || p_person_rec.person_middle_name;
        ELSE
          l_person_name := p_person_rec.person_middle_name;
        END IF;
      END IF;

      IF p_person_rec.person_last_name IS NOT NULL AND
         p_person_rec.person_last_name <> FND_API.G_MISS_CHAR
      THEN
        IF l_person_name IS NOT NULL THEN
          l_person_name := l_person_name || ' ' || p_person_rec.person_last_name;
        ELSE
          l_person_name := p_person_rec.person_last_name;
        END IF;
      END IF;

      IF p_person_rec.person_name_suffix IS NOT NULL AND
         p_person_rec.person_name_suffix <> FND_API.G_MISS_CHAR
      THEN
        IF l_person_name IS NOT NULL THEN
          l_person_name := l_person_name || ' ' || p_person_rec.person_name_suffix;
        ELSE
          l_person_name := p_person_rec.person_name_suffix;
        END IF;
      END IF;
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_person_name = '||l_person_name);
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_person_name (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_person_name (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'l_person_name = '||l_person_name,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    RETURN(SUBSTRB(l_person_name, 1, 450));

  END do_create_person_name;

  /**
   * PRIVATE FUNCTION do_create_party_name
   *
   * DESCRIPTION
   *     Creates party name.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_person_first_name
   *       p_person_last_name
   *     OUT:
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  FUNCTION do_create_party_name (
    p_person_first_name                IN     VARCHAR2,
    p_person_last_name                 IN     VARCHAR2
  ) RETURN VARCHAR2 IS

    l_party_name                       HZ_PARTIES.PARTY_NAME%TYPE;
    l_debug_prefix                     VARCHAR2(30) := '';
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_party_name (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_party_name (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_person_first_name IS NOT NULL AND
       p_person_first_name <> FND_API.G_MISS_CHAR
    THEN
      l_party_name := p_person_first_name;
    END IF;

    IF p_person_last_name IS NOT NULL AND
       p_person_last_name <> FND_API.G_MISS_CHAR
    THEN
      IF l_party_name IS NOT NULL THEN
        l_party_name := l_party_name||' '||p_person_last_name;
      ELSE
        l_party_name := p_person_last_name;
      END IF;
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_party_name = '||l_party_name);
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_party_name (-)');
    END IF;*/
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'l_party_name = '||l_party_name,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_party_name (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    RETURN l_party_name;

  END do_create_party_name;

  /**
   * PRIVATE PROCEDURE do_update_party_rel_name
   *
   * DESCRIPTION
   *     update party relationships' party name when subject or object
   *     party's name has been changed. The procedure should be
   *     a recursive one because we might have a party relationship
   *     whose subject or object party is a relationship too.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_id
   *       p_party_name
   *     OUT:
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   */

  PROCEDURE do_update_party_rel_name(
    p_party_id                         IN     NUMBER,
    p_party_name                       IN     HZ_PARTIES.PARTY_NAME%TYPE
  ) IS

    l_party_name                       HZ_PARTIES.party_name%TYPE;

    CURSOR c_party_rels IS
      SELECT r.party_id, r.object_id, o.party_name, r.subject_id, s.party_name,
             rel.party_number, rel.party_name
      FROM hz_relationships r, hz_parties s, hz_parties o, hz_parties rel
      WHERE (r.subject_id = p_party_id OR r.object_id = p_party_id)
      AND r.party_id IS NOT NULL
      AND r.subject_table_name = 'HZ_PARTIES'
      AND r.object_table_name = 'HZ_PARTIES'
      AND r.directional_flag = 'F'
      AND r.subject_id = s.party_id
      AND r.object_id = o.party_id
      AND r.party_id = rel.party_id;

    TYPE IDlist IS TABLE OF NUMBER(15);
    TYPE NAMElist IS TABLE OF HZ_PARTIES.PARTY_NAME%TYPE;
    TYPE NUMBERlist IS TABLE OF HZ_PARTIES.PARTY_NUMBER%TYPE;

    i_party_id                         IDlist;
    i_object_id                        IDlist;
    i_object_name                      NAMElist;
    i_subject_id                       IDlist;
    i_subject_name                     NAMElist;
    i_party_number                     NUMBERlist;
    i_party_name                       NAMElist;
    l_dummy                            VARCHAR2(1);
    l_debug_prefix                     VARCHAR2(30) := '';

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_party_rel_name (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_party_rel_name (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    OPEN c_party_rels;
    FETCH c_party_rels BULK COLLECT INTO
      i_party_id,i_object_id,i_object_name,i_subject_id,i_subject_name,
      i_party_number, i_party_name;
    CLOSE c_party_rels;

    FOR i IN 1..i_party_id.COUNT LOOP
      l_party_name := SUBSTRB(i_subject_name(i) || '-' ||
                             i_object_name(i)  || '-' ||
                             i_party_number(i), 1, 360);

      IF l_party_name <> i_party_name(i) THEN
        --check if party is locked by any one else.
        BEGIN
          SELECT 'Y'
          INTO   l_dummy
          FROM   hz_parties
          WHERE  PARTY_ID = i_party_id(i)
          FOR UPDATE NOWAIT;
        EXCEPTION
          WHEN OTHERS THEN
            fnd_message.set_name('AR', 'HZ_API_RECORD_CHANGED');
            fnd_message.set_token('TABLE', 'HZ_PARTIES');
            fnd_msg_pub.add;
            RAISE FND_API.G_EXC_ERROR;
        END;

        UPDATE hz_parties
        SET party_name = l_party_name
        WHERE party_id = i_party_id(i);
      END IF;

      --recursively update those party relationships' name whose
      --subject or object party might also be a party relationship.

      do_update_party_rel_name(i_party_id(i), l_party_name);

    END LOOP;

    -- Debug info.

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_party_rel_name (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_update_party_rel_name;

  /**
   * PRIVATE FUNCTION party_profile_exists
   *
   * DESCRIPTION
   *    Returns if a party profile exists based
   *    on the type, id and data source.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *       p_party_id
   *       p_data_source_type
   *     OUT:
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  FUNCTION party_profile_exists(
    p_party_type                    IN     VARCHAR2,
    p_party_id                      IN     NUMBER,
    p_data_source_type              IN     VARCHAR2
  ) RETURN VARCHAR2 IS

    CURSOR c_org_profile_exists IS
      SELECT 'Y'
      FROM hz_organization_profiles
      WHERE party_id = p_party_id
      AND actual_content_source = p_data_source_type
      AND effective_end_date IS NULL;

    CURSOR c_per_profile_exists IS
      SELECT 'Y'
      FROM hz_person_profiles
      WHERE party_id = p_party_id
      AND actual_content_source = p_data_source_type
      AND effective_end_date IS NULL;

    l_dummy                         VARCHAR2(1);
    l_debug_prefix                     VARCHAR2(30) := '';
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'party profile exists (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'party profile exists (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_party_type = 'PERSON' THEN

      OPEN c_per_profile_exists;
      FETCH c_per_profile_exists INTO l_dummy;

      IF c_per_profile_exists%NOTFOUND THEN
        l_dummy := 'N';
      END IF;
      CLOSE c_per_profile_exists;

    ELSIF p_party_type = 'ORGANIZATION' THEN

      OPEN c_org_profile_exists;
      FETCH c_org_profile_exists INTO l_dummy;

      IF c_org_profile_exists%NOTFOUND THEN
        l_dummy := 'N';
      END IF;
      CLOSE c_org_profile_exists;

    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'party profile exists (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'party profile exists (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    RETURN l_dummy;

  END party_profile_exists;

  /**
   * PRIVATE FUNCTION reset_sst_to_userentered
   *
   * DESCRIPTION
   *    Returns 'Y' if a sst profile has been re-set
   *    to user-entered profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *       p_party_id
   *     OUT:
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  FUNCTION reset_sst_to_userentered(
    p_party_type                    IN     VARCHAR2,
    p_party_id                      IN     NUMBER
  ) RETURN VARCHAR2 IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'reset_sst_to_userentered (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'reset_sst_to_userentered (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_party_type = 'PERSON' THEN

      UPDATE hz_person_profiles
      SET actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
      WHERE party_id = p_party_id
      AND actual_content_source = G_SST_SOURCE_TYPE
      AND effective_end_date IS NULL
      AND NOT EXISTS (
        SELECT 'Y'
        FROM hz_person_profiles
        WHERE party_id = p_party_id
        AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
        AND effective_end_date IS NULL );

    ELSIF p_party_type = 'ORGANIZATION' THEN

      UPDATE hz_organization_profiles
      SET actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
      WHERE party_id = p_party_id
      AND actual_content_source = G_SST_SOURCE_TYPE
      AND effective_end_date IS NULL
      AND NOT EXISTS (
        SELECT 'Y'
        FROM hz_organization_profiles
        WHERE party_id = p_party_id
        AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
        AND effective_end_date IS NULL );

    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'reset_sst_to_userentered (-)');
    END IF;
    */
/*
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'reset_sst_to_userentered (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
*/
    IF SQL%NOTFOUND THEN
      RETURN 'N';
    ELSE
      RETURN 'Y';
    END IF;

  END reset_sst_to_userentered;

  /**
   * PRIVATE PROCEDURE do_process_classification
   *
   * DESCRIPTION
   *    Processes classification related columns.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_create_update_flag
   *       p_organization_rec
   *       p_old_organization_rec
   *       p_data_source_type
   *     OUT:
   *     IN/ OUT:
   *       x_return_status
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  PROCEDURE do_process_classification(
    p_create_update_flag            IN     VARCHAR2,
    p_party_type                    IN     VARCHAR2,
    p_organization_rec              IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_old_organization_rec          IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_person_rec                    IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_old_person_rec                IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_group_rec                     IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_old_group_rec                 IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_data_source_type              IN     VARCHAR2,
    x_return_status                 IN OUT NOCOPY VARCHAR2
  ) IS

    l_code_assignment_id            NUMBER;
    l_msg_count                     NUMBER;
    l_msg_data                      VARCHAR2(2000);
    l_sic_code                      HZ_PARTIES.SIC_CODE%TYPE;
    l_sic_code_type                 HZ_PARTIES.SIC_CODE_TYPE%TYPE;
    l_data_source_type              VARCHAR2(30);
    l_party_rec                     PARTY_REC_TYPE;
    l_old_party_rec                 PARTY_REC_TYPE;

    -- Bug 3040565 : Added a locla variable to store local_activity_code_type

   l_local_activity_code_type    varchar2(30);
   l_debug_prefix                      VARCHAR2(30) := '';
   --4232060
   l_created_by_module varchar2(150);
  BEGIN
    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_process_classification (+)');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'party_id = '||p_organization_rec.party_rec.party_id);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_process_classification (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'party_id = '||p_organization_rec.party_rec.party_id,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    IF p_data_source_type = G_SST_SOURCE_TYPE THEN
      l_data_source_type := G_MISS_CONTENT_SOURCE_TYPE;
    ELSE
      l_data_source_type := p_data_source_type;
    END IF;

    IF p_party_type = 'PERSON' THEN
      l_party_rec := p_person_rec.party_rec;
      l_old_party_rec := p_old_person_rec.party_rec;
      --4621564
      IF p_old_person_rec.created_by_module = fnd_api.g_miss_char THEN
          l_created_by_module := 'TCA_V2_API';
      ELSE
          l_created_by_module := p_old_person_rec.created_by_module;
      END IF;
      --4232060
      l_created_by_module := nvl(p_person_rec.created_by_module,l_created_by_module);
    ELSIF p_party_type = 'ORGANIZATION' THEN
      l_party_rec := p_organization_rec.party_rec;
      l_old_party_rec := p_old_organization_rec.party_rec;
      --4621564
      IF p_old_organization_rec.created_by_module = fnd_api.g_miss_char THEN
          l_created_by_module := 'TCA_V2_API';
      ELSE
          l_created_by_module := p_old_organization_rec.created_by_module;
      END IF;
      --4232060
      l_created_by_module := nvl(p_organization_rec.created_by_module,l_created_by_module);
    ELSE
      l_party_rec := p_group_rec.party_rec;
      l_old_party_rec := p_old_group_rec.party_rec;
      --4621564
      IF p_old_group_rec.created_by_module = fnd_api.g_miss_char THEN
          l_created_by_module := 'TCA_V2_API';
      ELSE
          l_created_by_module := p_old_group_rec.created_by_module;
      END IF;
      --4232060
      l_created_by_module := nvl(p_group_rec.created_by_module,l_created_by_module);
    END IF;

    -- call hz_classification_v2pub.set_primary_code_assignment when
    -- CATEGORY_CODE is specified for a user entered party.
    -- you can have customer category for a person not just organization.
    -- we should remove category_code from the party_rec once CRM uptake the
    -- new TCA classification model. Other application should not use the
    -- the category code column in the party table.

    -- We do not need to change the content source logic because of the mix-n-match.
    -- Mapping API is not populating party_rec.category_code.

    IF (p_create_update_flag = 'C' AND
        l_party_rec.category_code IS NOT NULL AND
        l_party_rec.category_code <> FND_API.G_MISS_CHAR) OR
       (p_create_update_flag = 'U'AND
        l_party_rec.category_code IS NOT NULL AND
        -- Bug 3876180.
        -- l_party_rec.category_code <> FND_API.G_MISS_CHAR AND
        l_party_rec.category_code <> l_old_party_rec.category_code) AND
       l_data_source_type = G_MISS_CONTENT_SOURCE_TYPE
    THEN
       hz_classification_v2pub.set_primary_code_assignment(
        p_owner_table_name          => 'HZ_PARTIES',
        p_owner_table_id            => l_party_rec.party_id,
        p_class_category            => 'CUSTOMER_CATEGORY',
        p_class_code                => l_party_rec.category_code,
        p_content_source_type       => l_data_source_type,
        -- Bug 3856348
      --  p_created_by_module         => nvl(p_organization_rec.created_by_module,
        --                               p_old_organization_rec.created_by_module),
        --4232060
        p_created_by_module         => l_created_by_module,
        x_code_assignment_id        => l_code_assignment_id,
        x_return_status             => x_return_status,
        x_msg_count                 => l_msg_count,
        x_msg_data                  => l_msg_data );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    IF p_party_type = 'ORGANIZATION' THEN

      -- sic_code_type is required for entering sic_code. When inserting
      -- sic_code_type is required for entering sic_code and vice versa.
      -- That means, for both of them, we either provide values or leave
      -- them NULL.
      IF p_create_update_flag = 'C' THEN
        l_sic_code := NVL(p_organization_rec.sic_code, FND_API.G_MISS_CHAR);
        l_sic_code_type := NVL(p_organization_rec.sic_code_type, FND_API.G_MISS_CHAR);
      ELSE
        l_sic_code := NVL(p_organization_rec.sic_code, p_old_organization_rec.sic_code);
        l_sic_code_type := NVL(p_organization_rec.sic_code_type, p_old_organization_rec.sic_code_type);
      END IF;

      IF (l_sic_code_type = FND_API.G_MISS_CHAR AND
          l_sic_code <> FND_API.G_MISS_CHAR) OR
         (l_sic_code = FND_API.G_MISS_CHAR AND
          l_sic_code_type <> FND_API.G_MISS_CHAR)
      THEN
        fnd_message.set_name('AR', 'HZ_API_SIC_CODE_TYPE_REQUIRED');
        fnd_msg_pub.add;
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- the sic_code_type ='OTHER' is allowed only when
      -- comming data source = G_MISS_CONTENT_SOURCE_TYPE

      IF l_sic_code_type = 'OTHER' AND
         l_data_source_type <> G_MISS_CONTENT_SOURCE_TYPE
      THEN
        fnd_message.set_name('AR', 'HZ_API_SIC_CODE_TYPE_OTHER');
        fnd_msg_pub.add;
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- call hz_classification_v2pub.set_primary_code_assignment.
      -- if sic_code_type is not 'OTHER', then make the sic_code as the primary
      -- industrial class code for the party by calling
      -- hz_classification_v2pub.set_primary_code_assignment.
      -- if local_activity_code has a value, call
      -- hz_classification_v2pub.set_primary_code_assignment.

     IF l_sic_code=FND_API.G_MISS_CHAR
        AND l_sic_code_type=FND_API.G_MISS_CHAR
        AND p_old_organization_rec.sic_code_type IS NOT NULL
        AND p_old_organization_rec.sic_code_type<>FND_API.G_MISS_CHAR
     THEN
       l_sic_code_type := p_old_organization_rec.sic_code_type;
     END IF;


      IF --l_sic_code <> FND_API.G_MISS_CHAR AND ( bug 3876180 )
         l_sic_code_type <> FND_API.G_MISS_CHAR AND
         l_sic_code_type <> 'OTHER' AND
         (p_create_update_flag = 'C' OR
          (p_create_update_flag = 'U' AND
           NVL(p_organization_rec.sic_code, FND_API.G_MISS_CHAR) <>
               p_old_organization_rec.sic_code
           OR -- Bug 4043346
           NVL(p_organization_rec.sic_code_type, FND_API.G_MISS_CHAR) <>
               p_old_organization_rec.sic_code_type))
      THEN
         hz_classification_v2pub.set_primary_code_assignment(
          p_owner_table_name          => 'HZ_PARTIES',
          p_owner_table_id            => p_organization_rec.party_rec.party_id,
          p_class_category            => l_sic_code_type,
          p_class_code                => l_sic_code,
          p_content_source_type       => l_data_source_type,
          -- Bug 3856348
        --  p_created_by_module         => nvl(p_organization_rec.created_by_module,
          --                             p_old_organization_rec.created_by_module),
          --bug 4232060
          p_created_by_module         => l_created_by_module,
          x_code_assignment_id        => l_code_assignment_id,
          x_return_status             => x_return_status,
          x_msg_count                 => l_msg_count,
          x_msg_data                  => l_msg_data );

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;

      IF (p_create_update_flag = 'C' AND
          p_organization_rec.local_activity_code IS NOT NULL AND
          p_organization_rec.local_activity_code <> FND_API.G_MISS_CHAR) OR
         (p_create_update_flag = 'U'AND
          p_organization_rec.local_activity_code IS NOT NULL AND
          p_organization_rec.local_activity_code <> FND_API.G_MISS_CHAR AND
          p_organization_rec.local_activity_code <> p_old_organization_rec.local_activity_code)
      THEN

      -- Bug 3040565 : Modified the parameter p_class_category to set_primary_code_assignment to pass
      --                 actual local_activity_code_type.
        l_local_activity_code_type := nvl(p_organization_rec.local_activity_code_type, p_old_organization_rec.local_activity_code_type);

        if(l_local_activity_code_type = '4' OR l_local_activity_code_type = '5') then
                l_local_activity_code_type := 'NACE';
        end if;

        hz_classification_v2pub.set_primary_code_assignment(
          p_owner_table_name          => 'HZ_PARTIES',
          p_owner_table_id            => p_organization_rec.party_rec.party_id,

--          p_class_category            => 'NACE',

          p_class_category            => l_local_activity_code_type,

          p_class_code                => p_organization_rec.local_activity_code,
          p_content_source_type       => l_data_source_type,
          -- Bug 3856348
          --p_created_by_module         => nvl(p_organization_rec.created_by_module,
          --                           p_old_organization_rec.created_by_module),
          --bug 4232060
          p_created_by_module         => l_created_by_module,
          x_code_assignment_id        => l_code_assignment_id,
          x_return_status             => x_return_status,
          x_msg_count                 => l_msg_count,
          x_msg_data                  => l_msg_data );

        IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_process_classification (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_process_classification (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_process_classification;

  /**
   * PRIVATE PROCEDURE do_create_person_profile
   *
   * DESCRIPTION
   *     Creates person profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_person_profiles_pkg.Insert_Row
   *
   * ARGUMENTS
   *     IN:
   *       p_party_id
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *       p_person_rec
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *    06-MAY-2003    Sisir    o Bug 2970763: Modified for profile
   *                              versioning project;added version_number
   *                              as parameter.
   */

  PROCEDURE do_create_person_profile(
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_party_id                         IN     NUMBER,
    x_profile_id                       OUT    NOCOPY NUMBER,
    p_version_number                   IN     NUMBER,
    x_rowid                            OUT    NOCOPY ROWID
  ) IS

    l_person_profile_id                NUMBER;
    l_rowid                            ROWID := NULL;

    l_debug_prefix                     VARCHAR2(30) := '';

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_person_profile (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_person_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug (
        'hz_person_profiles_pkg.Insert_Row (+)', l_debug_prefix);
    END IF;
    */

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_person_profiles_pkg.Insert_Row (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call table-handler.
    HZ_person_profiles_pkg.Insert_Row (
      x_rowid                                 => l_rowid,
      x_person_profile_id                     => l_person_profile_id,
      x_party_id                              => p_party_id,
      x_person_name                           => do_create_person_name(p_person_rec),
      x_attribute_category                    => p_person_rec.attribute_category,
      x_attribute1                            => p_person_rec.attribute1,
      x_attribute2                            => p_person_rec.attribute2,
      x_attribute3                            => p_person_rec.attribute3,
      x_attribute4                            => p_person_rec.attribute4,
      x_attribute5                            => p_person_rec.attribute5,
      x_attribute6                            => p_person_rec.attribute6,
      x_attribute7                            => p_person_rec.attribute7,
      x_attribute8                            => p_person_rec.attribute8,
      x_attribute9                            => p_person_rec.attribute9,
      x_attribute10                           => p_person_rec.attribute10,
      x_attribute11                           => p_person_rec.attribute11,
      x_attribute12                           => p_person_rec.attribute12,
      x_attribute13                           => p_person_rec.attribute13,
      x_attribute14                           => p_person_rec.attribute14,
      x_attribute15                           => p_person_rec.attribute15,
      x_attribute16                           => p_person_rec.attribute16,
      x_attribute17                           => p_person_rec.attribute17,
      x_attribute18                           => p_person_rec.attribute18,
      x_attribute19                           => p_person_rec.attribute19,
      x_attribute20                           => p_person_rec.attribute20,
      x_internal_flag                         => p_person_rec.internal_flag,
      x_person_pre_name_adjunct               => p_person_rec.person_pre_name_adjunct,
      x_person_first_name                     => p_person_rec.person_first_name,
      x_person_middle_name                    => p_person_rec.person_middle_name,
      x_person_last_name                      => p_person_rec.person_last_name,
      x_person_name_suffix                    => p_person_rec.person_name_suffix,
      x_person_title                          => p_person_rec.person_title,
      x_person_academic_title                 => p_person_rec.person_academic_title,
      x_person_previous_last_name             => p_person_rec.person_previous_last_name,
      x_person_initials                       => p_person_rec.person_initials,
      x_known_as                              => p_person_rec.known_as,
      x_person_name_phonetic                  => p_person_rec.person_name_phonetic,
      x_person_first_name_phonetic            => p_person_rec.person_first_name_phonetic,
      x_person_last_name_phonetic             => p_person_rec.person_last_name_phonetic,
      x_tax_reference                         => p_person_rec.tax_reference,
      x_jgzz_fiscal_code                      => p_person_rec.jgzz_fiscal_code,
      x_person_iden_type                      => p_person_rec.person_iden_type,
      x_person_identifier                     => p_person_rec.person_identifier,
      x_date_of_birth                         => p_person_rec.date_of_birth,
      x_place_of_birth                        => p_person_rec.place_of_birth,
      x_date_of_death                         => p_person_rec.date_of_death,
      x_deceased_flag                         => p_person_rec.deceased_flag,
      x_gender                                => p_person_rec.gender,
      x_declared_ethnicity                    => p_person_rec.declared_ethnicity,
      x_marital_status                        => p_person_rec.marital_status,
      x_marital_status_eff_date               => p_person_rec.marital_status_effective_date,
      x_personal_income                       => p_person_rec.personal_income,
      x_head_of_household_flag                => p_person_rec.head_of_household_flag,
      x_household_income                      => p_person_rec.household_income,
      x_household_size                        => p_person_rec.household_size,
      x_rent_own_ind                          => p_person_rec.rent_own_ind,
      x_last_known_gps                        => p_person_rec.last_known_gps,
      x_effective_start_date                  => trunc(hz_utility_pub.creation_date),
      x_effective_end_date                    => null,
      x_content_source_type                   => p_person_rec.content_source_type,
      x_known_as2                             => p_person_rec.known_as2,
      x_known_as3                             => p_person_rec.known_as3,
      x_known_as4                             => p_person_rec.known_as4,
      x_known_as5                             => p_person_rec.known_as5,
      x_middle_name_phonetic                  => p_person_rec.middle_name_phonetic,
      x_object_version_number                 => 1,
      x_created_by_module                     => p_person_rec.created_by_module,
      x_application_id                        => p_person_rec.application_id,
      x_actual_content_source                 => p_person_rec.actual_content_source,
      x_version_number                        => p_version_number
    );

    x_profile_id := l_person_profile_id;
    x_rowid := l_rowid;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug (
        'hz_person_profiles_pkg.Insert_Row (-) ' ||
        'x_profile_id = ' || x_profile_id, l_debug_prefix);
    END IF;
    */

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_person_profiles_pkg.Insert_Row (-) '||'x_profile_id = ' || x_profile_id,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_person_profile (-)');
    END IF;*/

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_person_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_create_person_profile;

  /**
   * PRIVATE PROCEDURE do_update_person_profile
   *
   * DESCRIPTION
   *     Updates person profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_person_profiles_pkg.Update_Row
   *
   * ARGUMENTS
   *     IN:
   *       p_data_source_type
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *       p_person_rec
   *       p_old_person_rec
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   */

  PROCEDURE do_update_person_profile(
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_old_person_rec                   IN     PERSON_REC_TYPE,
    p_data_source_type                 IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  ) IS

    l_rowid                            ROWID := NULL;
    l_person_profile_id                NUMBER;
    l_effective_start_date             DATE;
    l_object_version_number            NUMBER;
    l_person_name                      HZ_PERSON_PROFILES.PERSON_NAME%TYPE;
    l_person_rec                       PERSON_REC_TYPE;
    l_version_number                   NUMBER;

    CURSOR c_person IS
      SELECT person_profile_id, rowid,object_version_number,
             version_number, effective_start_date
      FROM hz_person_profiles
      WHERE party_id = p_person_rec.party_rec.party_id
      AND actual_content_source = p_data_source_type
      AND effective_end_date is null
      FOR UPDATE NOWAIT;

    l_debug_prefix                     VARCHAR2(30) := '';
    l_create_update_flag               VARCHAR2(1);
    l_return_status                    VARCHAR2(1);

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_person_profile (+)');
    END IF;
    */

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_person_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    OPEN c_person;
    FETCH c_person INTO
      l_person_profile_id, l_rowid,l_object_version_number,
      l_version_number, l_effective_start_date;

    IF c_person%NOTFOUND THEN
      fnd_message.set_name('AR', 'HZ_NO_PROFILE_PRESENT');
      fnd_message.set_token('PARTY_ID', TO_CHAR(p_person_rec.party_rec.party_id));
      fnd_message.set_token('CONTENT_SOURCE_TYPE', p_data_source_type);
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;
    CLOSE c_person;


    IF fnd_profile.value ('HZ_PROFILE_VERSION') = 'NEW_VERSION' THEN
        -- Always End date the existing profile and create a new profile
        l_create_update_flag := 'C';

    ELSIF fnd_profile.value ('HZ_PROFILE_VERSION') = 'NO_VERSION' THEN
        -- Always update the existing profile
        l_create_update_flag := 'U';

    ELSE
        IF TRUNC (l_effective_start_date) < TRUNC (SYSDATE) THEN
        -- End date the existing profile and create a new profile
                l_create_update_flag := 'C';
        ELSE
        -- Same day,so update the existing profile
                l_create_update_flag := 'U';
        END IF;
    END IF;

    IF l_create_update_flag = 'C' THEN
        -- Always End date the existing profile and create a new profile
       l_version_number :=  nvl(l_version_number,1)+1;

        UPDATE hz_person_profiles
        SET    effective_end_date = decode(trunc(effective_start_date),trunc(sysdate),trunc(sysdate),TRUNC (SYSDATE-1)),
               object_version_number = NVL(l_object_version_number, 1) + 1
               --,version_number = NVL(version_number,1)+1
        WHERE rowid = l_rowid;

      -- create a new record with same data as current profile
      do_create_person_profile(
        p_person_rec            => p_old_person_rec,
        p_party_id              => p_person_rec.party_rec.party_id,
        x_profile_id            => x_profile_id,
        p_version_number        => l_version_number,
        x_rowid                 => l_rowid );
      l_object_version_number := 2;

      --
      -- copy extent data for extensibility project.
      --
      IF p_data_source_type = G_SST_SOURCE_TYPE THEN
        HZ_EXTENSIBILITY_PVT.copy_person_extent_data (
          p_old_profile_id          => l_person_profile_id,
          p_new_profile_id          => x_profile_id,
          x_return_status           => l_return_status
        );

        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;

    ELSE
      x_profile_id := l_person_profile_id;
      l_object_version_number := NVL(l_object_version_number, 1) + 1;
      l_version_number  :=  nvl(l_version_number,1)+1;
    END IF;
/*
    IF TRUNC(l_effective_start_date) < TRUNC(SYSDATE) THEN
      UPDATE hz_person_profiles
      SET effective_end_date = TRUNC(SYSDATE-1),
          object_version_number = NVL(object_version_number, 1) + 1
      WHERE rowid = l_rowid;

      -- create a new record with same data as current profile
      do_create_person_profile(
        p_person_rec            => p_old_person_rec,
        p_party_id              => p_person_rec.party_rec.party_id,
        x_profile_id            => x_profile_id,
        x_rowid                 => l_rowid );

      l_object_version_number := 2;
    ELSE
      x_profile_id := l_person_profile_id;
      l_object_version_number := NVL(l_object_version_number, 1) + 1;
    END IF;
*/
    IF p_person_rec.person_title IS NULL AND
       p_person_rec.person_first_name IS NULL AND
       p_person_rec.person_middle_name IS NULL AND
       p_person_rec.person_last_name IS NULL AND
       p_person_rec.person_name_suffix IS NULL AND
       p_person_rec.known_as IS NULL AND
       p_person_rec.person_first_name_phonetic IS NULL AND
       p_person_rec.middle_name_phonetic IS NULL AND
       p_person_rec.person_last_name_phonetic IS NULL

    THEN
      l_person_name := NULL;
    ELSE
      l_person_rec.person_title :=
        NVL(p_person_rec.person_title, p_old_person_rec.person_title);
      l_person_rec.person_first_name :=
        NVL(p_person_rec.person_first_name, p_old_person_rec.person_first_name);
      l_person_rec.person_middle_name :=
        NVL(p_person_rec.person_middle_name, p_old_person_rec.person_middle_name);
      l_person_rec.person_last_name :=
        NVL(p_person_rec.person_last_name, p_old_person_rec.person_last_name);
      l_person_rec.person_name_suffix :=
        NVL(p_person_rec.person_name_suffix, p_old_person_rec.person_name_suffix);
      -- Bug 3999044
      l_person_rec.known_as :=
        NVL(p_person_rec.known_as,p_old_person_rec.known_as);
      l_person_rec.person_first_name_phonetic:=
        NVL(p_person_rec.person_first_name_phonetic,p_old_person_rec.person_first_name_phonetic);
      l_person_rec.middle_name_phonetic:=
        NVL(p_person_rec.middle_name_phonetic,p_old_person_rec.middle_name_phonetic);
      l_person_rec.person_last_name_phonetic :=
        NVL(p_person_rec.person_last_name_phonetic,p_old_person_rec.person_last_name_phonetic);


      l_person_name := do_create_person_name(l_person_rec);
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug ('profile_id = '||x_profile_id, l_debug_prefix);
      hz_utility_v2pub.debug (
        'hz_person_profiles_pkg.Update_Row (+) ',l_debug_prefix);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_person_profiles_pkg.Update_Row (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'profile_id = '||x_profile_id,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    -- call table-handler.
    HZ_person_profiles_pkg.Update_Row (
      x_rowid                                 => l_rowid,
      x_person_profile_id                     => x_profile_id,
      x_party_id                              => null,
      x_person_name                           => l_person_name,
      x_attribute_category                    => p_person_rec.attribute_category,
      x_attribute1                            => p_person_rec.attribute1,
      x_attribute2                            => p_person_rec.attribute2,
      x_attribute3                            => p_person_rec.attribute3,
      x_attribute4                            => p_person_rec.attribute4,
      x_attribute5                            => p_person_rec.attribute5,
      x_attribute6                            => p_person_rec.attribute6,
      x_attribute7                            => p_person_rec.attribute7,
      x_attribute8                            => p_person_rec.attribute8,
      x_attribute9                            => p_person_rec.attribute9,
      x_attribute10                           => p_person_rec.attribute10,
      x_attribute11                           => p_person_rec.attribute11,
      x_attribute12                           => p_person_rec.attribute12,
      x_attribute13                           => p_person_rec.attribute13,
      x_attribute14                           => p_person_rec.attribute14,
      x_attribute15                           => p_person_rec.attribute15,
      x_attribute16                           => p_person_rec.attribute16,
      x_attribute17                           => p_person_rec.attribute17,
      x_attribute18                           => p_person_rec.attribute18,
      x_attribute19                           => p_person_rec.attribute19,
      x_attribute20                           => p_person_rec.attribute20,
      x_internal_flag                         => p_person_rec.internal_flag,
      x_person_pre_name_adjunct               => p_person_rec.person_pre_name_adjunct,
      x_person_first_name                     => p_person_rec.person_first_name,
      x_person_middle_name                    => p_person_rec.person_middle_name,
      x_person_last_name                      => p_person_rec.person_last_name,
      x_person_name_suffix                    => p_person_rec.person_name_suffix,
      x_person_title                          => p_person_rec.person_title,
      x_person_academic_title                 => p_person_rec.person_academic_title,
      x_person_previous_last_name             => p_person_rec.person_previous_last_name,
      x_person_initials                       => p_person_rec.person_initials,
      x_known_as                              => p_person_rec.known_as,
      x_person_name_phonetic                  => p_person_rec.person_name_phonetic,
      x_person_first_name_phonetic            => p_person_rec.person_first_name_phonetic,
      x_person_last_name_phonetic             => p_person_rec.person_last_name_phonetic,
      x_tax_reference                         => p_person_rec.tax_reference,
      x_jgzz_fiscal_code                      => p_person_rec.jgzz_fiscal_code,
      x_person_iden_type                      => p_person_rec.person_iden_type,
      x_person_identifier                     => p_person_rec.person_identifier,
      x_date_of_birth                         => p_person_rec.date_of_birth,
      x_place_of_birth                        => p_person_rec.place_of_birth,
      x_date_of_death                         => p_person_rec.date_of_death,
      x_deceased_flag                         => p_person_rec.deceased_flag,
      x_gender                                => p_person_rec.gender,
      x_declared_ethnicity                    => p_person_rec.declared_ethnicity,
      x_marital_status                        => p_person_rec.marital_status,
      x_marital_status_eff_date               => p_person_rec.marital_status_effective_date,
      x_personal_income                       => p_person_rec.personal_income,
      x_head_of_household_flag                => p_person_rec.head_of_household_flag,
      x_household_income                      => p_person_rec.household_income,
      x_household_size                        => p_person_rec.household_size,
      x_rent_own_ind                          => p_person_rec.rent_own_ind,
      x_last_known_gps                        => p_person_rec.last_known_gps,
      x_effective_start_date                  => null,
      x_effective_end_date                    => null,
      x_content_source_type                   => null, -- the column is non-updateable
      x_known_as2                             => p_person_rec.known_as2,
      x_known_as3                             => p_person_rec.known_as3,
      x_known_as4                             => p_person_rec.known_as4,
      x_known_as5                             => p_person_rec.known_as5,
      x_middle_name_phonetic                  => p_person_rec.middle_name_phonetic,
      x_object_version_number                 => l_object_version_number,
      x_created_by_module                     => p_person_rec.created_by_module,
      x_application_id                        => p_person_rec.application_id,
      x_actual_content_source                 => null,  -- the column is non-updateable
      x_version_number                        => l_version_number
    );

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug (
            'hz_person_profiles_pkg.Update_Row (-) ',
            l_debug_prefix);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_person_profiles_pkg.Update_Row (-)',
                               p_msg_level=>fnd_log.level_procedure);

    END IF;

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_person_profile (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_person_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  EXCEPTION
    WHEN g_resource_busy THEN
      fnd_message.set_name('AR', 'HZ_API_RECORD_CHANGED');
      fnd_message.set_token('TABLE', 'HZ_PERSON_PROFILES');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;

  END do_update_person_profile;

  /**
   * PRIVATE PROCEDURE do_create_org_profile
   *
   * DESCRIPTION
   *     Creates organization profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_organization_profiles_pkg.Insert_Row
   *
   * ARGUMENTS
   *     IN:
   *       p_party_id
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *       p_organization_rec
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *   26-NOV-2001        Joe del Callar        Bug 2116225: added support
   *                                            for banks.
   *                                            Bug 2117973: modified to
   *                                            conform to PL/SQL coding stds
   */

  PROCEDURE do_create_org_profile(
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_party_id                         IN     NUMBER,
    x_profile_id                       OUT    NOCOPY NUMBER,
    p_version_number                   IN     NUMBER,
    x_rowid                            OUT    NOCOPY ROWID
  ) IS

    l_organization_profile_id          NUMBER;
    l_rowid                            ROWID := NULL;

    l_debug_prefix                     VARCHAR2(30) := '';
    l_bank_code                        VARCHAR2(30) := NULL;
    l_branch_code                      VARCHAR2(30) := NULL;
    l_bank_or_branch_number            VARCHAR2(60) := NULL;
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_org_profile (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_org_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'hz_organization_profiles_pkg.Insert_Row (+)',
                             l_debug_prefix);
    END IF;
    */
    --Bug9648645
    --When global variable g_party_id is having value (Bank related variable having value) and
    --Party is same then assign get_organization_rec fetched Bank related values to 
    --local variables and provide as paramenters to profile.insert_row API
    IF g_party_id IS NOT NULL AND p_party_id = g_party_id THEN
      l_bank_code              := g_bank_code;
      l_branch_code            := g_branch_code;
      l_bank_or_branch_number  := g_bank_or_branch_number;
      
      g_bank_code              := NULL;
      g_branch_code            := NULL;
      g_bank_or_branch_number  := NULL;
      
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Bank related variables are assigned to local variables'
                                 ||' and used in Creating new profile.',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
      
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_bank_or_branch_number : '||l_bank_or_branch_number
                                                                  ||' l_bank_code : '||l_bank_code
                                                                  ||' l_branch_code : '||l_branch_code
                                                                  ||' p_party_id : '||p_party_id,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
      
      
    END IF;
       

    
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_organization_profiles_pkg.Insert_Row (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call table-handler.
    HZ_organization_profiles_pkg.insert_row(
      x_rowid                             => l_rowid,
      x_organization_profile_id           => l_organization_profile_id,
      x_party_id                          => p_party_id,
      x_organization_name                 => p_organization_rec.organization_name,
      x_attribute_category                => p_organization_rec.attribute_category,
      x_attribute1                        => p_organization_rec.attribute1,
      x_attribute2                        => p_organization_rec.attribute2,
      x_attribute3                        => p_organization_rec.attribute3,
      x_attribute4                        => p_organization_rec.attribute4,
      x_attribute5                        => p_organization_rec.attribute5,
      x_attribute6                        => p_organization_rec.attribute6,
      x_attribute7                        => p_organization_rec.attribute7,
      x_attribute8                        => p_organization_rec.attribute8,
      x_attribute9                        => p_organization_rec.attribute9,
      x_attribute10                       => p_organization_rec.attribute10,
      x_attribute11                       => p_organization_rec.attribute11,
      x_attribute12                       => p_organization_rec.attribute12,
      x_attribute13                       => p_organization_rec.attribute13,
      x_attribute14                       => p_organization_rec.attribute14,
      x_attribute15                       => p_organization_rec.attribute15,
      x_attribute16                       => p_organization_rec.attribute16,
      x_attribute17                       => p_organization_rec.attribute17,
      x_attribute18                       => p_organization_rec.attribute18,
      x_attribute19                       => p_organization_rec.attribute19,
      x_attribute20                       => p_organization_rec.attribute20,
      x_enquiry_duns                      => p_organization_rec.enquiry_duns,
      x_ceo_name                          => p_organization_rec.ceo_name,
      x_ceo_title                         => p_organization_rec.ceo_title,
      x_principal_name                    => p_organization_rec.principal_name,
      x_principal_title                   => p_organization_rec.principal_title,
      x_legal_status                      => p_organization_rec.legal_status,
      x_control_yr                        => p_organization_rec.control_yr,
      x_employees_total                   => p_organization_rec.employees_total,
      x_hq_branch_ind                     => p_organization_rec.hq_branch_ind,
      x_branch_flag                       => p_organization_rec.branch_flag,
      x_oob_ind                           => p_organization_rec.oob_ind,
      x_line_of_business                  => p_organization_rec.line_of_business,
      x_cong_dist_code                    => p_organization_rec.cong_dist_code,
      x_sic_code                          => p_organization_rec.sic_code,
      x_import_ind                        => p_organization_rec.import_ind,
      x_export_ind                        => p_organization_rec.export_ind,
      x_labor_surplus_ind                 => p_organization_rec.labor_surplus_ind,
      x_debarment_ind                     => p_organization_rec.debarment_ind,
      x_minority_owned_ind                => p_organization_rec.minority_owned_ind,
      x_minority_owned_type               => p_organization_rec.minority_owned_type,
      x_woman_owned_ind                   => p_organization_rec.woman_owned_ind,
      x_disadv_8a_ind                     => p_organization_rec.disadv_8a_ind,
      x_small_bus_ind                     => p_organization_rec.small_bus_ind,
      x_rent_own_ind                      => p_organization_rec.rent_own_ind,
      x_debarments_count                  => p_organization_rec.debarments_count,
      x_debarments_date                   => p_organization_rec.debarments_date,
      x_failure_score                     => p_organization_rec.failure_score,
      x_failure_score_override_code       => p_organization_rec.failure_score_override_code,
      x_failure_score_commentary          => p_organization_rec.failure_score_commentary,
      x_global_failure_score              => p_organization_rec.global_failure_score,
      x_db_rating                         => p_organization_rec.db_rating,
      x_credit_score                      => p_organization_rec.credit_score,
      x_credit_score_commentary           => p_organization_rec.credit_score_commentary,
      x_paydex_score                      => p_organization_rec.paydex_score,
      x_paydex_three_months_ago           => p_organization_rec.paydex_three_months_ago,
      x_paydex_norm                       => p_organization_rec.paydex_norm,
      x_best_time_contact_begin           => p_organization_rec.best_time_contact_begin,
      x_best_time_contact_end             => p_organization_rec.best_time_contact_end,
      x_organization_name_phonetic        => p_organization_rec.organization_name_phonetic,
      x_tax_reference                     => p_organization_rec.tax_reference,
      x_gsa_indicator_flag                => p_organization_rec.gsa_indicator_flag,
      x_jgzz_fiscal_code                  => p_organization_rec.jgzz_fiscal_code,
      x_analysis_fy                       => p_organization_rec.analysis_fy,
      x_fiscal_yearend_month              => p_organization_rec.fiscal_yearend_month,
      x_curr_fy_potential_revenue         => p_organization_rec.curr_fy_potential_revenue,
      x_next_fy_potential_revenue         => p_organization_rec.next_fy_potential_revenue,
      x_year_established                  => p_organization_rec.year_established,
      x_mission_statement                 => p_organization_rec.mission_statement,
      x_organization_type                 => p_organization_rec.organization_type,
      x_business_scope                    => p_organization_rec.business_scope,
      x_corporation_class                 => p_organization_rec.corporation_class,
      x_known_as                          => p_organization_rec.known_as,
      x_local_bus_iden_type               => p_organization_rec.local_bus_iden_type,
      x_local_bus_identifier              => p_organization_rec.local_bus_identifier,
      x_pref_functional_currency          => p_organization_rec.pref_functional_currency,
      x_registration_type                 => p_organization_rec.registration_type,
      x_total_employees_text              => p_organization_rec.total_employees_text,
      x_total_employees_ind               => p_organization_rec.total_employees_ind,
      x_total_emp_est_ind                 => p_organization_rec.total_emp_est_ind,
      x_total_emp_min_ind                 => p_organization_rec.total_emp_min_ind,
      x_parent_sub_ind                    => p_organization_rec.parent_sub_ind,
      x_incorp_year                       => p_organization_rec.incorp_year,
      x_content_source_type               => p_organization_rec.content_source_type,
      x_content_source_number             => p_organization_rec.content_source_number,
      x_effective_start_date              => TRUNC(hz_utility_pub.creation_date),
      x_effective_end_date                => NULL,
      x_sic_code_type                     => p_organization_rec.sic_code_type,
      x_public_private_ownership          => p_organization_rec.public_private_ownership_flag,
      x_local_activity_code_type          => p_organization_rec.local_activity_code_type,
      x_local_activity_code               => p_organization_rec.local_activity_code,
      x_emp_at_primary_adr                => p_organization_rec.emp_at_primary_adr,
      x_emp_at_primary_adr_text           => p_organization_rec.emp_at_primary_adr_text,
      x_emp_at_primary_adr_est_ind        => p_organization_rec.emp_at_primary_adr_est_ind,
      x_emp_at_primary_adr_min_ind        => p_organization_rec.emp_at_primary_adr_min_ind,
      x_internal_flag                     => p_organization_rec.internal_flag,
      x_high_credit                       => p_organization_rec.high_credit,
      x_avg_high_credit                   => p_organization_rec.avg_high_credit,
      x_total_payments                    => p_organization_rec.total_payments,
      x_known_as2                         => p_organization_rec.known_as2,
      x_known_as3                         => p_organization_rec.known_as3,
      x_known_as4                         => p_organization_rec.known_as4,
      x_known_as5                         => p_organization_rec.known_as5,
      x_credit_score_class                => p_organization_rec.credit_score_class,
      x_credit_score_natl_percentile      => p_organization_rec.credit_score_natl_percentile,
      x_credit_score_incd_default         => p_organization_rec.credit_score_incd_default,
      x_credit_score_age                  => p_organization_rec.credit_score_age,
      x_credit_score_date                 => p_organization_rec.credit_score_date,
      x_failure_score_class               => p_organization_rec.failure_score_class,
      x_failure_score_incd_default        => p_organization_rec.failure_score_incd_default,
      x_failure_score_age                 => p_organization_rec.failure_score_age,
      x_failure_score_date                => p_organization_rec.failure_score_date,
      x_failure_score_commentary2         => p_organization_rec.failure_score_commentary2,
      x_failure_score_commentary3         => p_organization_rec.failure_score_commentary3,
      x_failure_score_commentary4         => p_organization_rec.failure_score_commentary4,
      x_failure_score_commentary5         => p_organization_rec.failure_score_commentary5,
      x_failure_score_commentary6         => p_organization_rec.failure_score_commentary6,
      x_failure_score_commentary7         => p_organization_rec.failure_score_commentary7,
      x_failure_score_commentary8         => p_organization_rec.failure_score_commentary8,
      x_failure_score_commentary9         => p_organization_rec.failure_score_commentary9,
      x_failure_score_commentary10        => p_organization_rec.failure_score_commentary10,
      x_credit_score_commentary2          => p_organization_rec.credit_score_commentary2,
      x_credit_score_commentary3          => p_organization_rec.credit_score_commentary3,
      x_credit_score_commentary4          => p_organization_rec.credit_score_commentary4,
      x_credit_score_commentary5          => p_organization_rec.credit_score_commentary5,
      x_credit_score_commentary6          => p_organization_rec.credit_score_commentary6,
      x_credit_score_commentary7          => p_organization_rec.credit_score_commentary7,
      x_credit_score_commentary8          => p_organization_rec.credit_score_commentary8,
      x_credit_score_commentary9          => p_organization_rec.credit_score_commentary9,
      x_credit_score_commentary10         => p_organization_rec.credit_score_commentary10,
      x_maximum_credit_recomm             => p_organization_rec.maximum_credit_recommendation,
      x_maximum_credit_currency_code      => p_organization_rec.maximum_credit_currency_code,
      x_displayed_duns_party_id           => p_organization_rec.displayed_duns_party_id,
      x_failure_score_natnl_perc          => p_organization_rec.failure_score_natnl_percentile,
      x_duns_number_c                     => p_organization_rec.duns_number_c,
      x_bank_or_branch_number             => l_bank_or_branch_number,
      x_bank_code                         => l_bank_code,
      x_branch_code                       => l_branch_code,
      x_object_version_number             => 1,
      x_created_by_module                 => p_organization_rec.created_by_module,
      x_application_id                    => p_organization_rec.application_id,
      x_do_not_confuse_with               => p_organization_rec.do_not_confuse_with,
      x_actual_content_source             => p_organization_rec.actual_content_source,
      x_version_number                    => p_version_number,
      x_home_country                      => p_organization_rec.home_country
    );

    x_profile_id := l_organization_profile_id;
    x_rowid := l_rowid;


    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug ('hz_organization_profiles_pkg.Insert_Row (-) ',
                              l_debug_prefix);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_organization_profiles_pkg.Insert_Row (-) ',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_org_profile (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_org_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_create_org_profile;

  /**
   * PRIVATE PROCEDURE do_update_org_profile
   *
   * DESCRIPTION
   *     Updates organization profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_organization_profiles_pkg.Update_Row
   *
   * ARGUMENTS
   *     IN:
   *       p_party_id
   *       p_data_source_type
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *       p_organization_rec
   *       p_old_organization_rec
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *   26-NOV-2001        Joe del Callar       Bug 2116225: modified for
   *                                           consolidated bank support.
   *                                           Bug 2117973: modified to conform
   *                                           to PL/SQL coding standards.
   *                                           Changed selects into cursors.
   */

  PROCEDURE do_update_org_profile(
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE,
    p_data_source_type                 IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  ) IS

    l_rowid                            ROWID := NULL;
    l_object_version_number            NUMBER;
    l_version_number                   NUMBER;
    l_organization_profile_id          NUMBER;
    l_effective_start_date             DATE;

    CURSOR c_org IS
      SELECT rowid, organization_profile_id,object_version_number,
             version_number,effective_start_date
      FROM hz_organization_profiles
      WHERE party_id = p_organization_rec.party_rec.party_id
      AND actual_content_source = p_data_source_type
      AND effective_end_date is null
      FOR UPDATE NOWAIT;

    l_debug_prefix                     VARCHAR2(30);
    l_create_update_flag               VARCHAR2(1);
    l_return_status                    VARCHAR2(1);
-- Bug 3560323 : Added local variable for business report
    l_business_report   CLOB;
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_org_profile (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_org_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    OPEN c_org;
    FETCH c_org INTO
      l_rowid, l_organization_profile_id,l_object_version_number,
      l_version_number,l_effective_start_date;

    IF c_org%NOTFOUND THEN
      fnd_message.set_name('AR', 'HZ_NO_PROFILE_PRESENT');
      fnd_message.set_token('PARTY_ID', TO_CHAR(p_organization_rec.party_rec.party_id));
      fnd_message.set_token('CONTENT_SOURCE_TYPE', p_data_source_type);
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;
    CLOSE c_org;

    IF fnd_profile.value ('HZ_PROFILE_VERSION') = 'NEW_VERSION' THEN
        -- Always End date the existing profile and create a new profile
        l_create_update_flag := 'C';

    ELSIF fnd_profile.value ('HZ_PROFILE_VERSION') = 'NO_VERSION' THEN
        -- Always update the existing profile
        l_create_update_flag := 'U';

    ELSE
        IF TRUNC (l_effective_start_date) < TRUNC (SYSDATE) THEN
        -- End date the existing profile and create a new profile
                l_create_update_flag := 'C';
        ELSE
        -- Same day,so update the existing profile
                l_create_update_flag := 'U';
        END IF;
    END IF;

    IF l_create_update_flag = 'C' THEN
        -- Always End date the existing profile and create a new profile
       --l_object_version_number := NVL(l_object_version_number, 1) + 1;
       l_version_number :=  nvl(l_version_number,1)+1;

        UPDATE hz_organization_profiles
        SET    effective_end_date = decode(trunc(effective_start_date),trunc(sysdate),trunc(sysdate),TRUNC (SYSDATE-1)),
               object_version_number = NVL(l_object_version_number, 1) + 1
               --,version_number = NVL(version_number,1)+1
        WHERE rowid = l_rowid;

-- Bug 3560323 : Get business report from previous org profile to copy to new org profile
        BEGIN
                SELECT business_report INTO l_business_report
                FROM hz_organization_profiles
                WHERE rowid = l_rowid;
        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                        NULL;
                WHEN OTHERS THEN
                        NULL;
        END;

      -- create a new record with same data as current profile
      do_create_org_profile(
        p_organization_rec           => p_old_organization_rec,
        p_party_id                   => p_organization_rec.party_rec.party_id,
        x_profile_id                 => x_profile_id,
        p_version_number             => l_version_number,
        x_rowid                      => l_rowid );

      l_object_version_number := 2;

-- Bug 3560323 : Update the new org profile with previous business report
        UPDATE hz_organization_profiles
        SET business_report = l_business_report
        WHERE organization_profile_id = x_profile_id;

      --
      -- copy extent data for extensibility project.
      --
      IF p_data_source_type = G_SST_SOURCE_TYPE THEN
        HZ_EXTENSIBILITY_PVT.copy_org_extent_data (
          p_old_profile_id          => l_organization_profile_id,
          p_new_profile_id          => x_profile_id,
          x_return_status           => l_return_status
        );

        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;

    ELSE
      x_profile_id := l_organization_profile_id;
      l_object_version_number := NVL(l_object_version_number, 1) + 1;
      l_version_number  :=  nvl(l_version_number,1)+1;
    END IF;

/*
    IF TRUNC(l_effective_start_date) < TRUNC(SYSDATE) THEN
      UPDATE hz_organization_profiles
      SET effective_end_date = TRUNC(SYSDATE-1),
          object_version_number = NVL(object_version_number, 1) + 1
      WHERE rowid = l_rowid;

      -- create a new record with same data as current profile
      do_create_org_profile(
        p_organization_rec           => p_old_organization_rec,
        p_party_id                   => p_organization_rec.party_rec.party_id,
        x_profile_id                 => x_profile_id,
        x_rowid                      => l_rowid );

      l_object_version_number := 2;
    ELSE
      x_profile_id := l_organization_profile_id;
      l_object_version_number := NVL(l_object_version_number, 1) + 1;
    END IF;
*/
    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug ('profile_id = '||x_profile_id, l_debug_prefix);
      hz_utility_v2pub.debug ('hz_organization_profiles_pkg.Update_Row (+) ',
                              l_debug_prefix);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_organization_profiles_pkg.Update_Row (+) ',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'profile_id = '||x_profile_id,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    -- call table-handler.
    HZ_organization_profiles_pkg.update_row (
      x_rowid                             => l_rowid,
      x_organization_profile_id           => x_profile_id,
      x_party_id                          => NULL,
      x_organization_name                 => p_organization_rec.organization_name,
      x_attribute_category                => p_organization_rec.attribute_category,
      x_attribute1                        => p_organization_rec.attribute1,
      x_attribute2                        => p_organization_rec.attribute2,
      x_attribute3                        => p_organization_rec.attribute3,
      x_attribute4                        => p_organization_rec.attribute4,
      x_attribute5                        => p_organization_rec.attribute5,
      x_attribute6                        => p_organization_rec.attribute6,
      x_attribute7                        => p_organization_rec.attribute7,
      x_attribute8                        => p_organization_rec.attribute8,
      x_attribute9                        => p_organization_rec.attribute9,
      x_attribute10                       => p_organization_rec.attribute10,
      x_attribute11                       => p_organization_rec.attribute11,
      x_attribute12                       => p_organization_rec.attribute12,
      x_attribute13                       => p_organization_rec.attribute13,
      x_attribute14                       => p_organization_rec.attribute14,
      x_attribute15                       => p_organization_rec.attribute15,
      x_attribute16                       => p_organization_rec.attribute16,
      x_attribute17                       => p_organization_rec.attribute17,
      x_attribute18                       => p_organization_rec.attribute18,
      x_attribute19                       => p_organization_rec.attribute19,
      x_attribute20                       => p_organization_rec.attribute20,
      x_enquiry_duns                      => p_organization_rec.enquiry_duns,
      x_ceo_name                          => p_organization_rec.ceo_name,
      x_ceo_title                         => p_organization_rec.ceo_title,
      x_principal_name                    => p_organization_rec.principal_name,
      x_principal_title                   => p_organization_rec.principal_title,
      x_legal_status                      => p_organization_rec.legal_status,
      x_control_yr                        => p_organization_rec.control_yr,
      x_employees_total                   => p_organization_rec.employees_total,
      x_hq_branch_ind                     => p_organization_rec.hq_branch_ind,
      x_branch_flag                       => p_organization_rec.branch_flag,
      x_oob_ind                           => p_organization_rec.oob_ind,
      x_line_of_business                  => p_organization_rec.line_of_business,
      x_cong_dist_code                    => p_organization_rec.cong_dist_code,
      x_sic_code                          => p_organization_rec.sic_code,
      x_import_ind                        => p_organization_rec.import_ind,
      x_export_ind                        => p_organization_rec.export_ind,
      x_labor_surplus_ind                 => p_organization_rec.labor_surplus_ind,
      x_debarment_ind                     => p_organization_rec.debarment_ind,
      x_minority_owned_ind                => p_organization_rec.minority_owned_ind,
      x_minority_owned_type               => p_organization_rec.minority_owned_type,
      x_woman_owned_ind                   => p_organization_rec.woman_owned_ind,
      x_disadv_8a_ind                     => p_organization_rec.disadv_8a_ind,
      x_small_bus_ind                     => p_organization_rec.small_bus_ind,
      x_rent_own_ind                      => p_organization_rec.rent_own_ind,
      x_debarments_count                  => p_organization_rec.debarments_count,
      x_debarments_date                   => p_organization_rec.debarments_date,
      x_failure_score                     => p_organization_rec.failure_score,
      x_failure_score_override_code       => p_organization_rec.failure_score_override_code,
      x_failure_score_commentary          => p_organization_rec.failure_score_commentary,
      x_global_failure_score              => p_organization_rec.global_failure_score,
      x_db_rating                         => p_organization_rec.db_rating,
      x_credit_score                      => p_organization_rec.credit_score,
      x_credit_score_commentary           => p_organization_rec.credit_score_commentary,
      x_paydex_score                      => p_organization_rec.paydex_score,
      x_paydex_three_months_ago           => p_organization_rec.paydex_three_months_ago,
      x_paydex_norm                       => p_organization_rec.paydex_norm,
      x_best_time_contact_begin           => p_organization_rec.best_time_contact_begin,
      x_best_time_contact_end             => p_organization_rec.best_time_contact_end,
      x_organization_name_phonetic        => p_organization_rec.organization_name_phonetic,
      x_tax_reference                     => p_organization_rec.tax_reference,
      x_gsa_indicator_flag                => p_organization_rec.gsa_indicator_flag,
      x_jgzz_fiscal_code                  => p_organization_rec.jgzz_fiscal_code,
      x_analysis_fy                       => p_organization_rec.analysis_fy,
      x_fiscal_yearend_month              => p_organization_rec.fiscal_yearend_month,
      x_curr_fy_potential_revenue         => p_organization_rec.curr_fy_potential_revenue,
      x_next_fy_potential_revenue         => p_organization_rec.next_fy_potential_revenue,
      x_year_established                  => p_organization_rec.year_established,
      x_mission_statement                 => p_organization_rec.mission_statement,
      x_organization_type                 => p_organization_rec.organization_type,
      x_business_scope                    => p_organization_rec.business_scope,
      x_corporation_class                 => p_organization_rec.corporation_class,
      x_known_as                          => p_organization_rec.known_as,
      x_local_bus_iden_type               => p_organization_rec.local_bus_iden_type,
      x_local_bus_identifier              => p_organization_rec.local_bus_identifier,
      x_pref_functional_currency          => p_organization_rec.pref_functional_currency,
      x_registration_type                 => p_organization_rec.registration_type,
      x_total_employees_text              => p_organization_rec.total_employees_text,
      x_total_employees_ind               => p_organization_rec.total_employees_ind,
      x_total_emp_est_ind                 => p_organization_rec.total_emp_est_ind,
      x_total_emp_min_ind                 => p_organization_rec.total_emp_min_ind,
      x_parent_sub_ind                    => p_organization_rec.parent_sub_ind,
      x_incorp_year                       => p_organization_rec.incorp_year,
      x_content_source_type               => null, -- the column is non-updateable
      x_content_source_number             => p_organization_rec.content_source_number,
      x_effective_start_date              => NULL,
      x_effective_end_date                => NULL,
      x_sic_code_type                     => p_organization_rec.sic_code_type,
      x_public_private_ownership          => p_organization_rec.public_private_ownership_flag,
      x_local_activity_code_type          => p_organization_rec.local_activity_code_type,
      x_local_activity_code               => p_organization_rec.local_activity_code,
      x_emp_at_primary_adr                => p_organization_rec.emp_at_primary_adr,
      x_emp_at_primary_adr_text           => p_organization_rec.emp_at_primary_adr_text,
      x_emp_at_primary_adr_est_ind        => p_organization_rec.emp_at_primary_adr_est_ind,
      x_emp_at_primary_adr_min_ind        => p_organization_rec.emp_at_primary_adr_min_ind,
      x_internal_flag                     => p_organization_rec.internal_flag,
      x_high_credit                       => p_organization_rec.high_credit,
      x_avg_high_credit                   => p_organization_rec.avg_high_credit,
      x_total_payments                    => p_organization_rec.total_payments,
      x_known_as2                         => p_organization_rec.known_as2,
      x_known_as3                         => p_organization_rec.known_as3,
      x_known_as4                         => p_organization_rec.known_as4,
      x_known_as5                         => p_organization_rec.known_as5,
      x_credit_score_class                => p_organization_rec.credit_score_class,
      x_credit_score_natl_percentile      => p_organization_rec.credit_score_natl_percentile,
      x_credit_score_incd_default         => p_organization_rec.credit_score_incd_default,
      x_credit_score_age                  => p_organization_rec.credit_score_age,
      x_credit_score_date                 => p_organization_rec.credit_score_date,
      x_failure_score_class               => p_organization_rec.failure_score_class,
      x_failure_score_incd_default        => p_organization_rec.failure_score_incd_default,
      x_failure_score_age                 => p_organization_rec.failure_score_age,
      x_failure_score_date                => p_organization_rec.failure_score_date,
      x_failure_score_commentary2         => p_organization_rec.failure_score_commentary2,
      x_failure_score_commentary3         => p_organization_rec.failure_score_commentary3,
      x_failure_score_commentary4         => p_organization_rec.failure_score_commentary4,
      x_failure_score_commentary5         => p_organization_rec.failure_score_commentary5,
      x_failure_score_commentary6         => p_organization_rec.failure_score_commentary6,
      x_failure_score_commentary7         => p_organization_rec.failure_score_commentary7,
      x_failure_score_commentary8         => p_organization_rec.failure_score_commentary8,
      x_failure_score_commentary9         => p_organization_rec.failure_score_commentary9,
      x_failure_score_commentary10        => p_organization_rec.failure_score_commentary10,
      x_credit_score_commentary2          => p_organization_rec.credit_score_commentary2,
      x_credit_score_commentary3          => p_organization_rec.credit_score_commentary3,
      x_credit_score_commentary4          => p_organization_rec.credit_score_commentary4,
      x_credit_score_commentary5          => p_organization_rec.credit_score_commentary5,
      x_credit_score_commentary6          => p_organization_rec.credit_score_commentary6,
      x_credit_score_commentary7          => p_organization_rec.credit_score_commentary7,
      x_credit_score_commentary8          => p_organization_rec.credit_score_commentary8,
      x_credit_score_commentary9          => p_organization_rec.credit_score_commentary9,
      x_credit_score_commentary10         => p_organization_rec.credit_score_commentary10,
      x_maximum_credit_recomm             => p_organization_rec.maximum_credit_recommendation,
      x_maximum_credit_currency_code      => p_organization_rec.maximum_credit_currency_code,
      x_displayed_duns_party_id           => p_organization_rec.displayed_duns_party_id,
      x_failure_score_natnl_perc          => p_organization_rec.failure_score_natnl_percentile,
      x_duns_number_c                     => p_organization_rec.duns_number_c,
      x_object_version_number             => l_object_version_number,
      x_created_by_module                 => p_organization_rec.created_by_module,
      x_application_id                    => p_organization_rec.application_id,
      x_do_not_confuse_with               => p_organization_rec.do_not_confuse_with,
      x_actual_content_source             => null, -- the column is non-updateable
      x_version_number                    => l_version_number,
      x_home_country                      => p_organization_rec.home_country
    );

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug ('hz_organization_profiles_pkg.Update_Row (-) ',
                              l_debug_prefix);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_organization_profiles_pkg.Update_Row (-) ',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_org_profile (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_org_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  EXCEPTION
    WHEN g_resource_busy THEN
      fnd_message.set_name('AR', 'HZ_API_RECORD_CHANGED');
      fnd_message.set_token('TABLE', 'HZ_ORGANIZATION_PROFILES');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;

  END do_update_org_profile;

  /**
   * PRIVATE PROCEDURE do_create_party_profile
   *
   * DESCRIPTION
   *     Creates party profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_id
   *       p_party_type
   *       p_content_source_type
   *       p_actual_content_source
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *       p_person_rec
   *       p_organization_rec
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *  Bug 13117445    Added an parameter p_party_create_update_flag
   *                  assigning this value to l_orig_sys_reference_rec.dqm_sync_mode
   *       
   */

  PROCEDURE do_create_party_profile (
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    p_person_rec                       IN OUT NOCOPY PERSON_REC_TYPE,
    p_organization_rec                 IN OUT NOCOPY ORGANIZATION_REC_TYPE,
    p_content_source_type              IN     VARCHAR2,
    p_actual_content_source            IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER,
    p_party_create_update_flag         IN     VARCHAR2
  ) IS

    l_rowid                         ROWID := NULL;
    l_debug_prefix                     VARCHAR2(30) := '';

    --  Bug 4239442 : Added cursor and variables
    l_orig_sys_reference_rec HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;
    l_orig_system HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM%TYPE;
    l_orig_system_reference HZ_ORIG_SYS_REFERENCES.ORIG_SYSTEM_REFERENCE%TYPE;
    l_created_by_module HZ_ORIG_SYS_REFERENCES.CREATED_BY_MODULE%TYPE;
    l_exists VARCHAR2(1);
    l_return_status                    VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    l_msg_count                        NUMBER;
    l_msg_data                         VARCHAR2(2000);

    CURSOR c_check_party_mapping
    IS
    SELECT 'Y'
    FROM hz_orig_sys_references
    WHERE owner_table_id = p_party_id
    AND   owner_table_name = 'HZ_PARTIES'
    AND   orig_system = l_orig_system
    AND   orig_system_reference = l_orig_system_reference
    AND   trunc(nvl(end_date_active, sysdate)) >= trunc(sysdate)
    AND   status = 'A';

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_party_profile (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_party_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_party_type = 'PERSON' THEN
      p_person_rec.content_source_type := p_content_source_type;
      p_person_rec.actual_content_source := p_actual_content_source;

      do_create_person_profile (
        p_person_rec               => p_person_rec,
        p_party_id                 => p_party_id,
        x_profile_id               => x_profile_id,
        p_version_number           => 1,
        x_rowid                    => l_rowid );

      --  Bug 4239442 : assign required vlaues to local variable
      l_orig_system := p_person_rec.party_rec.orig_system;
      l_orig_system_reference := p_person_rec.party_rec.orig_system_reference;
      l_created_by_module := p_person_rec.created_by_module;

    ELSIF p_party_type = 'ORGANIZATION' THEN
      p_organization_rec.content_source_type := p_content_source_type;
      p_organization_rec.actual_content_source := p_actual_content_source;

      do_create_org_profile (
        p_organization_rec         => p_organization_rec,
        p_party_id                 => p_party_id,
        x_profile_id               => x_profile_id,
        p_version_number           => 1,
        x_rowid                    => l_rowid );

      --  Bug 4239442 : assign required vlaues to local variable
      l_orig_system := p_organization_rec.party_rec.orig_system;
      l_orig_system_reference := p_organization_rec.party_rec.orig_system_reference;
      l_created_by_module := p_organization_rec.created_by_module;

    END IF;

    /* Bug 4239442 : If orig_system is passed by the user
     * check if there is already any MOSR entry for same
     * OS, OSR for same party. If not, create a new entry
     * If it is already existing, the call may be due to
     * HZ_PROFILE_VERSION profile setup
     */
    if l_orig_system is not null and
       l_orig_system <>fnd_api.g_miss_char
    then
       open c_check_party_mapping;
       fetch c_check_party_mapping into l_exists;
       if c_check_party_mapping%NOTFOUND then
          l_orig_sys_reference_rec.orig_system := l_orig_system ;
          l_orig_sys_reference_rec.orig_system_reference := l_orig_system_reference;
          l_orig_sys_reference_rec.owner_table_name := 'HZ_PARTIES';
          l_orig_sys_reference_rec.owner_table_id := p_party_id;
          l_orig_sys_reference_rec.created_by_module := nvl(l_created_by_module, 'TCA_V2_API');
          l_orig_sys_reference_rec.dqm_sync_mode := p_party_create_update_flag;
 	 
 	        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
 	              hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'DQM Sync Mode '||l_orig_sys_reference_rec.dqm_sync_mode,
 	                                     p_msg_level=>fnd_log.level_statement);
 	        END IF;
          hz_orig_system_ref_pub.create_orig_system_reference(
                        FND_API.G_FALSE,
                        l_orig_sys_reference_rec,
                        l_return_status,
                        l_msg_count,
                        l_msg_data);

          IF l_return_status <> fnd_api.g_ret_sts_success THEN
             RAISE FND_API.G_EXC_ERROR;
          END IF;
        end if;
    end if;

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_party_profile (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_party_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_create_party_profile;

  /**
   * PRIVATE PROCEDURE do_update_party_profile
   *
   * DESCRIPTION
   *     Updates party profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *       p_data_source_type
   *       p_person_rec
   *       p_old_person_rec
   *       p_organization_rec
   *       p_old_organization_rec
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  PROCEDURE do_update_party_profile (
    p_party_type                       IN     VARCHAR2,
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_data_source_type                 IN     VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_party_profile (+)');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'party_type = '||p_party_type);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_party_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);

    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'party_type = '||p_party_type,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    IF p_party_type = 'PERSON' THEN
      do_update_person_profile (
        p_person_rec                  => p_person_rec,
        p_old_person_rec              => p_old_person_rec,
        p_data_source_type            => p_data_source_type,
        x_profile_id                  => x_profile_id );

    ELSIF p_party_type = 'ORGANIZATION' THEN
      do_update_org_profile (
        p_organization_rec            => p_organization_rec,
        p_old_organization_rec        => p_old_organization_rec,
        p_data_source_type            => p_data_source_type,
        x_profile_id                  => x_profile_id );

    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_party_profile (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_party_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_update_party_profile;

  /**
   * PRIVATE PROCEDURE do_get_party_profile
   *
   * DESCRIPTION
   *     Gets party profile.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *       p_party_id
   *       p_data_source_type
   *     OUT:
   *       x_person_rec
   *       x_organization_rec
   *     IN/ OUT:
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  PROCEDURE do_get_party_profile (
    p_party_type                       IN     VARCHAR2,
    p_party_id                         IN     NUMBER,
    p_data_source_type                 IN     VARCHAR2,
    x_person_rec                       OUT    NOCOPY PERSON_REC_TYPE,
    x_organization_rec                 OUT    NOCOPY ORGANIZATION_REC_TYPE
  ) IS

    l_return_status                    VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    l_msg_count                        NUMBER;
    l_msg_data                         VARCHAR2(2000);
    l_debug_prefix                     VARCHAR2(30) := '';
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_get_party_profile (+)');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'party_type = '||p_party_type);
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_get_party_profile (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'party_type = '||p_party_type,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    IF p_party_type = 'PERSON' THEN
      get_person_rec (
        p_party_id                           => p_party_id,
        p_content_source_type                => p_data_source_type,
        x_person_rec                         => x_person_rec,
        x_return_status                      => l_return_status,
        x_msg_count                          => l_msg_count,
        x_msg_data                           => l_msg_data);

    ELSIF p_party_type = 'ORGANIZATION' THEN
      get_organization_rec (
        p_party_id                           => p_party_id,
        p_content_source_type                => p_data_source_type,
        x_organization_rec                   => x_organization_rec,
        x_return_status                      => l_return_status,
        x_msg_count                          => l_msg_count,
        x_msg_data                           => l_msg_data);

    END IF;

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_get_party_profile (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_get_party_profile (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_get_party_profile;

  /**
   * PRIVATE PROCEDURE do_create_update_party_only
   *
   * DESCRIPTION
   *     Creates / Updates only party.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *     IN:
   *       p_create_update_flag
   *       p_party_type
   *       p_party_id
   *       p_check_object_version_number
   *     OUT:
   *     IN/ OUT:
   *       p_party_object_version_number
   *       p_person_rec
   *       p_organization_rec
   *       p_group_rec
   *       x_party_id
   *       x_party_number
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   */

  PROCEDURE do_create_update_party_only(
    p_create_update_flag               IN     VARCHAR2,
    p_party_type                       IN     VARCHAR2,
    -- p_party_id is used in update mode only.
    p_party_id                         IN     NUMBER := NULL,
    p_check_object_version_number      IN     VARCHAR2 := 'Y',
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    p_person_rec                       IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_group_rec                        IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_old_group_rec                    IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    -- x_party_id and x_party_number are used in create mode.
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2
  ) IS

    l_party_rec                        PARTY_REC_TYPE;
    l_old_party_rec                    PARTY_REC_TYPE;
    l_party_dup_rec                    PARTY_DUP_REC_TYPE;
    l_person_rec                       PERSON_REC_TYPE;

    db_party_name                      HZ_PARTIES.PARTY_NAME%TYPE;
    db_created_by_module               HZ_PARTIES.CREATED_BY_MODULE%TYPE;
    l_party_name                       HZ_PARTIES.PARTY_NAME%TYPE;
    l_first_name                       HZ_PARTIES.PERSON_FIRST_NAME%TYPE;
    l_last_name                        HZ_PARTIES.PERSON_LAST_NAME%TYPE;
    l_customer_key                     HZ_PARTIES.CUSTOMER_KEY%TYPE;
    l_party_object_version_number      NUMBER;
    l_rowid                            ROWID := NULL;
    l_process_party_name               VARCHAR2(1);
    l_dummy                            VARCHAR2(1);
    l_return_status                    VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    l_context                          VARCHAR2(1);

    l_debug_prefix                     VARCHAR2(30);
     l_orig_sys_reference_rec    HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;

    l_msg_count number;
    l_msg_data varchar2(2000);
    l_created_by_module varchar2(150);

--  Bug 4490715 : Used to store party_tax_profile_id for update
    L_PARTY_TAX_PROFILE_ID      ZX_PARTY_TAX_PROFILE.PARTY_TAX_PROFILE_ID%TYPE;

    CURSOR c_party IS
      SELECT party_name, object_version_number, rowid,
             created_by_module
      FROM   hz_parties
      WHERE  party_id = p_party_id
      FOR UPDATE NOWAIT;

    CURSOR c_party_number_exists (
      p_party_number          VARCHAR2
    ) IS
      SELECT 'Y'
      FROM hz_parties
      WHERE party_number = p_party_number;

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_update_party_only (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_update_party_only (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_party_type = 'PERSON' THEN
      l_old_party_rec := p_old_person_rec.party_rec;
      l_party_rec := p_person_rec.party_rec;
      l_created_by_module := p_person_rec.created_by_module;
    ELSIF p_party_type = 'ORGANIZATION' THEN
      l_old_party_rec := p_old_organization_rec.party_rec;
      l_party_rec := p_organization_rec.party_rec;
       l_created_by_module := p_organization_rec.created_by_module;
    ELSIF p_party_type = 'GROUP' THEN
      l_old_party_rec := p_old_group_rec.party_rec;
      l_party_rec := p_group_rec.party_rec;
       l_created_by_module := p_group_rec.created_by_module;
    END IF;

 -- moved the mosr logic to update_xxx due to get_rec need party_id
/*    if p_create_update_flag = 'U' THEN
      IF (l_party_rec.orig_system is not null
         and l_party_rec.orig_system <>fnd_api.g_miss_char)
       and (l_party_rec.orig_system_reference is not null
         and l_party_rec.orig_system_reference <>fnd_api.g_miss_char)
       and (l_party_rec.party_id = FND_API.G_MISS_NUM or l_party_rec.party_id is null) THEN
           hz_orig_system_ref_pub.get_owner_table_id
                        (p_orig_system => l_party_rec.orig_system,
                        p_orig_system_reference => l_party_rec.orig_system_reference,
                        p_owner_table_name => 'HZ_PARTIES',
                        x_owner_table_id => l_party_rec.party_id,
                        x_return_status => l_return_status);
            IF l_return_status <> fnd_api.g_ret_sts_success THEN
                RAISE FND_API.G_EXC_ERROR;
            END IF;
      END IF;
   end if;
*/
    -- check party number in creation mode and
    -- lock record in update mode.

    IF p_create_update_flag = 'C' THEN

      -- if GENERATE_PARTY_NUMBER is 'N', then if party_number is
      -- not passed or is a duplicate raise error.

      IF NVL(fnd_profile.value('HZ_GENERATE_PARTY_NUMBER'), 'Y') = 'N' THEN

        IF l_party_rec.party_number = FND_API.G_MISS_CHAR OR
           l_party_rec.party_number IS NULL
        THEN
          fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
          fnd_message.set_token('COLUMN', 'party number');
          fnd_msg_pub.add;
          RAISE FND_API.G_EXC_ERROR;
        END IF;

        OPEN c_party_number_exists(l_party_rec.party_number);
        FETCH c_party_number_exists INTO l_dummy;

        IF NOT c_party_number_exists%NOTFOUND THEN
          fnd_message.set_name('AR', 'HZ_API_DUPLICATE_COLUMN');
          fnd_message.set_token('COLUMN', 'party_number');
          fnd_msg_pub.add;
          RAISE FND_API.G_EXC_ERROR;
        END IF;
        CLOSE c_party_number_exists;

      ELSE -- GENERATE_PARTY_NUMBER is 'Y'

        IF l_party_rec.party_number <> FND_API.G_MISS_CHAR AND
           l_party_rec.party_number IS NOT NULL
        THEN
          fnd_message.set_name('AR', 'HZ_API_PARTY_NUMBER_AUTO_ON');
          fnd_msg_pub.add;
          RAISE FND_API.G_EXC_ERROR;
        END IF;

      END IF;

    ELSE -- update mode

      -- check whether record has been updated by another user.
      -- if not, lock it.

      OPEN c_party;
      FETCH c_party INTO
        db_party_name, l_party_object_version_number, l_rowid, db_created_by_module;

      IF c_party%NOTFOUND THEN
        fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
        fnd_message.set_token('RECORD', 'party');
        fnd_message.set_token('VALUE', NVL(TO_CHAR(p_party_id), 'NULL'));
        fnd_msg_pub.add;
        RAISE fnd_api.g_exc_error;
      ELSIF p_check_object_version_number = 'Y' AND
            NOT ((p_party_object_version_number IS NULL AND
                 l_party_object_version_number IS NULL) OR
                (p_party_object_version_number IS NOT NULL AND
                 l_party_object_version_number IS NOT NULL AND
                 p_party_object_version_number = l_party_object_version_number))
      THEN
        fnd_message.set_name('AR', 'HZ_API_RECORD_CHANGED');
        fnd_message.set_token('TABLE', 'HZ_PARTIES');
        fnd_msg_pub.add;
        RAISE fnd_api.g_exc_error;
      END IF;
      CLOSE c_party;

      p_party_object_version_number := nvl(l_party_object_version_number, 1)+1;

    END IF;


    -- Construct dup rec.

    IF p_party_type = 'PERSON' THEN

      IF p_create_update_flag = 'C' THEN

        --  Check "backwards compatability" profile option and determine
        --  whether to stick with the old-style name formatting, or call
        --  the new dynamic name formatting routines.

        -- use new routines

        IF nvl(fnd_profile.value(g_profile_fmt_bkwd_compatible),'Y') = 'N' THEN

          -- use the new name formatting routine

          l_party_name := substrb( do_create_person_name(p_person_rec), 1, 360 );

        ELSE
          -- party_name is the concatenation of person_first_name, '.', and
          -- person_last_name

          l_party_name :=
            do_create_party_name(p_person_rec.person_first_name, p_person_rec.person_last_name);
        END IF;

        l_first_name := p_person_rec.person_first_name;
        l_last_name := p_person_rec.person_last_name;

      ELSE -- p_create_update_flag = 'U'

        -- Bug 3999044
        IF p_person_rec.person_title IS NULL AND
           p_person_rec.person_first_name IS NULL AND
           p_person_rec.person_middle_name IS NULL AND
           p_person_rec.person_last_name IS NULL AND
           p_person_rec.person_name_suffix IS NULL AND
           p_person_rec.known_as IS NULL AND
           p_person_rec.person_first_name_phonetic IS NULL AND
           p_person_rec.middle_name_phonetic IS NULL AND
           p_person_rec.person_last_name_phonetic IS NULL
        THEN
          l_process_party_name := 'N';
        ELSE
          l_person_rec.person_title :=
            NVL(p_person_rec.person_title, p_old_person_rec.person_title);
          l_person_rec.person_first_name :=
            NVL(p_person_rec.person_first_name, p_old_person_rec.person_first_name);
          l_person_rec.person_middle_name :=
            NVL(p_person_rec.person_middle_name, p_old_person_rec.person_middle_name);
          l_person_rec.person_last_name :=
            NVL(p_person_rec.person_last_name, p_old_person_rec.person_last_name);
          l_person_rec.person_name_suffix :=
            NVL(p_person_rec.person_name_suffix, p_old_person_rec.person_name_suffix);
          l_person_rec.known_as :=
            NVL(p_person_rec.known_as,p_old_person_rec.known_as);
          l_person_rec.person_first_name_phonetic:=
            NVL(p_person_rec.person_first_name_phonetic,p_old_person_rec.person_first_name_phonetic);
          l_person_rec.middle_name_phonetic:=
            NVL(p_person_rec.middle_name_phonetic,p_old_person_rec.middle_name_phonetic);
          l_person_rec.person_last_name_phonetic :=
            NVL(p_person_rec.person_last_name_phonetic,p_old_person_rec.person_last_name_phonetic);

          l_process_party_name := 'Y';
        END IF;

        IF l_process_party_name = 'Y' THEN

          --  Check "backwards compatability" profile option and determine
          --  whether to stick with the old-style name formatting, or call
          --  the new dynamic name formatting routines.

          -- use new routines

          IF nvl(fnd_profile.value(g_profile_fmt_bkwd_compatible),'Y') = 'N' THEN

            -- use the new name formatting routine
            l_party_name := substrb( do_create_person_name(l_person_rec), 1, 360 );

          ELSE

            IF p_person_rec.person_first_name IS NULL AND
               p_person_rec.person_last_name IS NULL
            THEN
              l_party_name := NULL;
            ELSE
              l_party_name :=
                do_create_party_name(l_person_rec.person_first_name, l_person_rec.person_last_name);
            END IF;

          END IF;
        END IF;

        l_first_name := l_person_rec.person_first_name;
        l_last_name := l_person_rec.person_last_name;
      END IF;

      l_party_dup_rec.created_by_module := p_person_rec.created_by_module;
      l_party_dup_rec.application_id := p_person_rec.application_id;
      l_party_dup_rec.tax_reference := p_person_rec.tax_reference;
      l_party_dup_rec.jgzz_fiscal_code := p_person_rec.jgzz_fiscal_code;
      l_party_dup_rec.pre_name_adjunct := p_person_rec.person_pre_name_adjunct;
      l_party_dup_rec.first_name := p_person_rec.person_first_name;
      l_party_dup_rec.middle_name := p_person_rec.person_middle_name;
      l_party_dup_rec.last_name := p_person_rec.person_last_name;
      l_party_dup_rec.name_suffix := p_person_rec.person_name_suffix;
      l_party_dup_rec.title := p_person_rec.person_title;
      l_party_dup_rec.academic_title := p_person_rec.person_academic_title;
      l_party_dup_rec.previous_last_name := p_person_rec.person_previous_last_name;
      l_party_dup_rec.known_as := p_person_rec.known_as;
      l_party_dup_rec.known_as2 := p_person_rec.known_as2;
      l_party_dup_rec.known_as3 := p_person_rec.known_as3;
      l_party_dup_rec.known_as4 := p_person_rec.known_as4;
      l_party_dup_rec.known_as5 := p_person_rec.known_as5;
      l_party_dup_rec.person_iden_type := p_person_rec.person_iden_type;
      l_party_dup_rec.person_identifier := p_person_rec.person_identifier;
      l_party_dup_rec.person_first_name_phonetic := p_person_rec.person_first_name_phonetic;
      l_party_dup_rec.person_last_name_phonetic := p_person_rec.person_last_name_phonetic;
      l_party_dup_rec.middle_name_phonetic := p_person_rec.middle_name_phonetic;

      -- generate customer key

      IF l_party_name IS NOT NULL AND
         l_party_name <> FND_API.G_MISS_CHAR AND
         l_party_name <> NVL(db_party_name, FND_API.G_MISS_CHAR)
      THEN
        l_customer_key := HZ_FUZZY_PUB.generate_key (
          p_key_type          => 'PERSON',
          p_first_name        => l_first_name,
          p_last_name         => l_last_name);
      END IF;

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'Generated person key : '||l_customer_key);
      END IF;*/

      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Generated person key : '||l_customer_key,
                               p_msg_level=>fnd_log.level_statement);
      END IF;

    ELSIF p_party_type = 'ORGANIZATION' THEN

      l_party_name := p_organization_rec.organization_name;
      l_party_dup_rec.created_by_module := p_organization_rec.created_by_module;
      l_party_dup_rec.application_id := p_organization_rec.application_id;
      l_party_dup_rec.sic_code := p_organization_rec.sic_code;
      l_party_dup_rec.sic_code_type := p_organization_rec.sic_code_type;
      l_party_dup_rec.hq_branch_ind := p_organization_rec.hq_branch_ind;
      l_party_dup_rec.tax_reference := p_organization_rec.tax_reference;
      l_party_dup_rec.jgzz_fiscal_code := p_organization_rec.jgzz_fiscal_code;
      l_party_dup_rec.duns_number_c := p_organization_rec.duns_number_c;
      l_party_dup_rec.known_as := p_organization_rec.known_as;
      l_party_dup_rec.known_as2 := p_organization_rec.known_as2;
      l_party_dup_rec.known_as3 := p_organization_rec.known_as3;
      l_party_dup_rec.known_as4 := p_organization_rec.known_as4;
      l_party_dup_rec.known_as5 := p_organization_rec.known_as5;
      l_party_dup_rec.fiscal_yearend_month := p_organization_rec.fiscal_yearend_month;
      l_party_dup_rec.employees_total := p_organization_rec.employees_total;
      l_party_dup_rec.curr_fy_potential_revenue := p_organization_rec.curr_fy_potential_revenue;
      l_party_dup_rec.next_fy_potential_revenue := p_organization_rec.next_fy_potential_revenue;
      l_party_dup_rec.year_established := p_organization_rec.year_established;
      l_party_dup_rec.gsa_indicator_flag := p_organization_rec.gsa_indicator_flag;
      l_party_dup_rec.mission_statement := p_organization_rec.mission_statement;
      l_party_dup_rec.organization_name_phonetic := p_organization_rec.organization_name_phonetic;
      l_party_dup_rec.analysis_fy := p_organization_rec.analysis_fy;

       -- generate customer key

      IF l_party_name IS NOT NULL AND
         l_party_name <> FND_API.G_MISS_CHAR AND
         l_party_name <> NVL(db_party_name, FND_API.G_MISS_CHAR)
      THEN
        l_customer_key := hz_fuzzy_pub.generate_key (
          p_key_type          => 'ORGANIZATION',
          p_party_name        => p_organization_rec.organization_name );
      END IF;

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'Generated organization key : '||l_customer_key);
      END IF;
      */
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Generated organization key : '||l_customer_key,
                               p_msg_level=>fnd_log.level_statement);
      END IF;

    ELSIF p_party_type = 'GROUP' THEN

      l_party_name := p_group_rec.group_name;
      l_party_dup_rec.created_by_module := p_group_rec.created_by_module;
      l_party_dup_rec.application_id := p_group_rec.application_id;
      -- Bug 2467872
      l_party_dup_rec.mission_statement := p_group_rec.mission_statement;

      -- generate customer key

      IF l_party_name IS NOT NULL AND
         l_party_name <> FND_API.G_MISS_CHAR AND
         l_party_name <> NVL(db_party_name, FND_API.G_MISS_CHAR)
      THEN
        l_customer_key := HZ_FUZZY_PUB.generate_key (
          p_key_type          => 'GROUP',
          p_party_name        => p_group_rec.group_name );
      END IF;

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'Generated group key : '||l_customer_key);
      END IF;
      */
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Generated group key : '||l_customer_key,
                               p_msg_level=>fnd_log.level_statement);
      END IF;

    END IF;


    -- validate party record.
    HZ_registry_validate_v2pub.validate_party(
       p_create_update_flag, l_party_rec, l_old_party_rec,
       NVL(db_created_by_module, fnd_api.g_miss_char), l_return_status);
    IF l_return_status <> fnd_api.g_ret_sts_success THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- call table handlers

    IF p_create_update_flag = 'C' THEN

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug (
          'hz_parties_pkg.Insert_Row (+)',l_debug_prefix);
      END IF;
      */
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_parties_pkg.Insert_Row (+)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- this is for handling orig_system_reference defaulting
      IF l_party_rec.party_id = FND_API.G_MISS_NUM THEN
        l_party_rec.party_id := NULL;
      END IF;

      hz_parties_pkg.insert_row (
        x_party_id                              => l_party_rec.party_id,
        x_party_number                          => l_party_rec.party_number,
        x_party_name                            => l_party_name,
        x_party_type                            => p_party_type,
        x_validated_flag                        => l_party_rec.validated_flag,
        x_attribute_category                    => l_party_rec.attribute_category,
        x_attribute1                            => l_party_rec.attribute1,
        x_attribute2                            => l_party_rec.attribute2,
        x_attribute3                            => l_party_rec.attribute3,
        x_attribute4                            => l_party_rec.attribute4,
        x_attribute5                            => l_party_rec.attribute5,
        x_attribute6                            => l_party_rec.attribute6,
        x_attribute7                            => l_party_rec.attribute7,
        x_attribute8                            => l_party_rec.attribute8,
        x_attribute9                            => l_party_rec.attribute9,
        x_attribute10                           => l_party_rec.attribute10,
        x_attribute11                           => l_party_rec.attribute11,
        x_attribute12                           => l_party_rec.attribute12,
        x_attribute13                           => l_party_rec.attribute13,
        x_attribute14                           => l_party_rec.attribute14,
        x_attribute15                           => l_party_rec.attribute15,
        x_attribute16                           => l_party_rec.attribute16,
        x_attribute17                           => l_party_rec.attribute17,
        x_attribute18                           => l_party_rec.attribute18,
        x_attribute19                           => l_party_rec.attribute19,
        x_attribute20                           => l_party_rec.attribute20,
        x_attribute21                           => l_party_rec.attribute21,
        x_attribute22                           => l_party_rec.attribute22,
        x_attribute23                           => l_party_rec.attribute23,
        x_attribute24                           => l_party_rec.attribute24,
        x_orig_system_reference                 => l_party_rec.orig_system_reference,
        x_sic_code                              => l_party_dup_rec.sic_code,
        x_hq_branch_ind                         => l_party_dup_rec.hq_branch_ind,
        x_customer_key                          => l_customer_key,
        x_tax_reference                         => l_party_dup_rec.tax_reference,
        x_jgzz_fiscal_code                      => l_party_dup_rec.jgzz_fiscal_code,
        x_person_pre_name_adjunct               => l_party_dup_rec.pre_name_adjunct,
        x_person_first_name                     => l_party_dup_rec.first_name,
        x_person_middle_name                    => l_party_dup_rec.middle_name,
        x_person_last_name                      => l_party_dup_rec.last_name,
        x_person_name_suffix                    => l_party_dup_rec.name_suffix,
        x_person_title                          => l_party_dup_rec.title,
        x_person_academic_title                 => l_party_dup_rec.academic_title,
        x_person_previous_last_name             => l_party_dup_rec.previous_last_name,
        x_known_as                              => l_party_dup_rec.known_as,
        x_person_iden_type                      => l_party_dup_rec.person_iden_type,
        x_person_identifier                     => l_party_dup_rec.person_identifier,
        x_group_type                            => p_group_rec.group_type,
        x_country                               => null,
        x_address1                              => null,
        x_address2                              => null,
        x_address3                              => null,
        x_address4                              => null,
        x_city                                  => null,
        x_postal_code                           => null,
        x_state                                 => null,
        x_province                              => null,
        x_status                                => l_party_rec.status,
        x_county                                => null,
        x_sic_code_type                         => l_party_dup_rec.sic_code_type,
        x_url                                   => null,
        x_email_address                         => null,
        x_analysis_fy                           => l_party_dup_rec.analysis_fy,
        x_fiscal_yearend_month                  => l_party_dup_rec.fiscal_yearend_month,
        x_employees_total                       => l_party_dup_rec.employees_total,
        x_curr_fy_potential_revenue             => l_party_dup_rec.curr_fy_potential_revenue,
        x_next_fy_potential_revenue             => l_party_dup_rec.next_fy_potential_revenue,
        x_year_established                      => l_party_dup_rec.year_established,
        x_gsa_indicator_flag                    => l_party_dup_rec.gsa_indicator_flag,
        x_mission_statement                     => l_party_dup_rec.mission_statement,
        x_organization_name_phonetic            => l_party_dup_rec.organization_name_phonetic,
        x_person_first_name_phonetic            => l_party_dup_rec.person_first_name_phonetic,
        x_person_last_name_phonetic             => l_party_dup_rec.person_last_name_phonetic,
        x_language_name                         => null,
        x_category_code                         => l_party_rec.category_code,
        x_salutation                            => l_party_rec.salutation,
        x_known_as2                             => l_party_dup_rec.known_as2,
        x_known_as3                             => l_party_dup_rec.known_as3,
        x_known_as4                             => l_party_dup_rec.known_as4,
        x_known_as5                             => l_party_dup_rec.known_as5,
        x_object_version_number                 => 1,
        x_duns_number_c                         => l_party_dup_rec.duns_number_c,
        x_created_by_module                     => l_party_dup_rec.created_by_module,
        x_application_id                        => l_party_dup_rec.application_id
      );


      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug (
          'hz_parties_pkg.Insert_Row (-)', l_debug_prefix);
      END IF;
      */
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_parties_pkg.Insert_Row (-)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      if l_party_rec.orig_system is not null
         and l_party_rec.orig_system <>fnd_api.g_miss_char
         --  Bug 4239442 : create MOSR entry only for GROUP party
         and p_party_type not in ('PERSON', 'ORGANIZATION')
      then
                l_orig_sys_reference_rec.orig_system := l_party_rec.orig_system;
                l_orig_sys_reference_rec.orig_system_reference := l_party_rec.orig_system_reference;
                l_orig_sys_reference_rec.owner_table_name := 'HZ_PARTIES';
                l_orig_sys_reference_rec.owner_table_id := l_party_rec.party_id;
                l_orig_sys_reference_rec.created_by_module := l_created_by_module;

                hz_orig_system_ref_pub.create_orig_system_reference(
                        FND_API.G_FALSE,
                        l_orig_sys_reference_rec,
                        l_return_status,
                        l_msg_count,
                        l_msg_data);
                 IF l_return_status <> fnd_api.g_ret_sts_success THEN
                        RAISE FND_API.G_EXC_ERROR;
                END IF;
      end if;

      x_party_id := l_party_rec.party_id;
      x_party_number := l_party_rec.party_number;

--  Bug 4490715 : If party is PERSON / ORGANIZATION call eTax
--                procedure to populate ZX_PARTY_TAX_PROFILE
      IF p_party_type IN ('PERSON', 'ORGANIZATION') THEN
        ZX_PARTY_TAX_PROFILE_PKG.insert_row (
         P_COLLECTING_AUTHORITY_FLAG => null,
         P_PROVIDER_TYPE_CODE => null,
         P_CREATE_AWT_DISTS_TYPE_CODE => null,
         P_CREATE_AWT_INVOICES_TYPE_COD => null,
         P_TAX_CLASSIFICATION_CODE => null,
         P_SELF_ASSESS_FLAG => null,
         P_ALLOW_OFFSET_TAX_FLAG => null,
         P_REP_REGISTRATION_NUMBER => l_party_dup_rec.tax_reference,
         P_EFFECTIVE_FROM_USE_LE => null,
         P_RECORD_TYPE_CODE => null,
         P_REQUEST_ID => null,
         P_ATTRIBUTE1 => null,
         P_ATTRIBUTE2 => null,
         P_ATTRIBUTE3 => null,
         P_ATTRIBUTE4 => null,
         P_ATTRIBUTE5 => null,
         P_ATTRIBUTE6 => null,
         P_ATTRIBUTE7 => null,
         P_ATTRIBUTE8 => null,
         P_ATTRIBUTE9 => null,
         P_ATTRIBUTE10 => null,
         P_ATTRIBUTE11 => null,
         P_ATTRIBUTE12 => null,
         P_ATTRIBUTE13 => null,
         P_ATTRIBUTE14 => null,
         P_ATTRIBUTE15 => null,
         P_ATTRIBUTE_CATEGORY => null,
         P_PARTY_ID => x_party_id,
         P_PROGRAM_LOGIN_ID => null,
         P_PARTY_TYPE_CODE => 'THIRD_PARTY',
         P_SUPPLIER_FLAG => null,
         P_CUSTOMER_FLAG => null,
         P_SITE_FLAG => null,
         P_PROCESS_FOR_APPLICABILITY_FL => null,
         P_ROUNDING_LEVEL_CODE => null,
         P_ROUNDING_RULE_CODE => null,
         P_WITHHOLDING_START_DATE => null,
         P_INCLUSIVE_TAX_FLAG => null,
         P_ALLOW_AWT_FLAG => null,
         P_USE_LE_AS_SUBSCRIBER_FLAG => null,
         P_LEGAL_ESTABLISHMENT_FLAG => null,
         P_FIRST_PARTY_LE_FLAG => null,
         P_REPORTING_AUTHORITY_FLAG => null,
         X_RETURN_STATUS => l_return_status,
         P_REGISTRATION_TYPE_CODE => null,--4742586
         P_COUNTRY_CODE => null--4742586
         );
        IF l_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;

    ELSE -- p_create_update_flag = 'U'

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug (
          'hz_parties_pkg.Update_Row (+)',l_debug_prefix);
      END IF;
      */
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_parties_pkg.Update_Row (+)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      if (l_party_rec.orig_system is not null
         and l_party_rec.orig_system <>fnd_api.g_miss_char)
        and (l_party_rec.orig_system_reference is not null
         and l_party_rec.orig_system_reference <>fnd_api.g_miss_char)
      then
                l_party_rec.orig_system_reference := null;
                -- In mosr, we have bypassed osr nonupdateable validation
                -- but we should not update existing osr, set it to null
      end if;
      -- call table handler to update the record
      hz_parties_pkg.update_row (
        x_rowid                                 => l_rowid,
        x_party_id                              => l_party_rec.party_id,
        x_party_number                          => l_party_rec.party_number,
        x_party_name                            => l_party_name,
        x_party_type                            => p_party_type,
        x_validated_flag                        => l_party_rec.validated_flag,
        x_attribute_category                    => l_party_rec.attribute_category,
        x_attribute1                            => l_party_rec.attribute1,
        x_attribute2                            => l_party_rec.attribute2,
        x_attribute3                            => l_party_rec.attribute3,
        x_attribute4                            => l_party_rec.attribute4,
        x_attribute5                            => l_party_rec.attribute5,
        x_attribute6                            => l_party_rec.attribute6,
        x_attribute7                            => l_party_rec.attribute7,
        x_attribute8                            => l_party_rec.attribute8,
        x_attribute9                            => l_party_rec.attribute9,
        x_attribute10                           => l_party_rec.attribute10,
        x_attribute11                           => l_party_rec.attribute11,
        x_attribute12                           => l_party_rec.attribute12,
        x_attribute13                           => l_party_rec.attribute13,
        x_attribute14                           => l_party_rec.attribute14,
        x_attribute15                           => l_party_rec.attribute15,
        x_attribute16                           => l_party_rec.attribute16,
        x_attribute17                           => l_party_rec.attribute17,
        x_attribute18                           => l_party_rec.attribute18,
        x_attribute19                           => l_party_rec.attribute19,
        x_attribute20                           => l_party_rec.attribute20,
        x_attribute21                           => l_party_rec.attribute21,
        x_attribute22                           => l_party_rec.attribute22,
        x_attribute23                           => l_party_rec.attribute23,
        x_attribute24                           => l_party_rec.attribute24,
        x_orig_system_reference                 => l_party_rec.orig_system_reference,
        x_sic_code                              => l_party_dup_rec.sic_code,
        x_hq_branch_ind                         => l_party_dup_rec.hq_branch_ind,
        x_customer_key                          => l_customer_key,
        x_tax_reference                         => l_party_dup_rec.tax_reference,
        x_jgzz_fiscal_code                      => l_party_dup_rec.jgzz_fiscal_code,
        x_person_pre_name_adjunct               => l_party_dup_rec.pre_name_adjunct,
        x_person_first_name                     => l_party_dup_rec.first_name,
        x_person_middle_name                    => l_party_dup_rec.middle_name,
        x_person_last_name                      => l_party_dup_rec.last_name,
        x_person_name_suffix                    => l_party_dup_rec.name_suffix,
        x_person_title                          => l_party_dup_rec.title,
        x_person_academic_title                 => l_party_dup_rec.academic_title,
        x_person_previous_last_name             => l_party_dup_rec.previous_last_name,
        x_known_as                              => l_party_dup_rec.known_as,
        x_person_iden_type                      => l_party_dup_rec.person_iden_type,
        x_person_identifier                     => l_party_dup_rec.person_identifier,
        x_group_type                            => p_group_rec.group_type,
        x_country                               => null,
        x_address1                              => null,
        x_address2                              => null,
        x_address3                              => null,
        x_address4                              => null,
        x_city                                  => null,
        x_postal_code                           => null,
        x_state                                 => null,
        x_province                              => null,
        x_status                                => l_party_rec.status,
        x_county                                => null,
        x_sic_code_type                         => l_party_dup_rec.sic_code_type,
        x_url                                   => null,
        x_email_address                         => null,
        x_analysis_fy                           => l_party_dup_rec.analysis_fy,
        x_fiscal_yearend_month                  => l_party_dup_rec.fiscal_yearend_month,
        x_employees_total                       => l_party_dup_rec.employees_total,
        x_curr_fy_potential_revenue             => l_party_dup_rec.curr_fy_potential_revenue,
        x_next_fy_potential_revenue             => l_party_dup_rec.next_fy_potential_revenue,
        x_year_established                      => l_party_dup_rec.year_established,
        x_gsa_indicator_flag                    => l_party_dup_rec.gsa_indicator_flag,
        x_mission_statement                     => l_party_dup_rec.mission_statement,
        x_organization_name_phonetic            => l_party_dup_rec.organization_name_phonetic,
        x_person_first_name_phonetic            => l_party_dup_rec.person_first_name_phonetic,
        x_person_last_name_phonetic             => l_party_dup_rec.person_last_name_phonetic,
        x_language_name                         => null,
        x_category_code                         => l_party_rec.category_code,
        x_salutation                            => l_party_rec.salutation,
        x_known_as2                             => l_party_dup_rec.known_as2,
        x_known_as3                             => l_party_dup_rec.known_as3,
        x_known_as4                             => l_party_dup_rec.known_as4,
        x_known_as5                             => l_party_dup_rec.known_as5,
        x_object_version_number                 => p_party_object_version_number,
        x_duns_number_c                         => l_party_dup_rec.duns_number_c,
        x_created_by_module                     => l_party_dup_rec.created_by_module,
        x_application_id                        => l_party_dup_rec.application_id
      );

      --Bug 1417600: Update party name for parties of type RELATIONSHIP
      --when subject or ojbect party's name has been changed.

      IF l_party_name IS NOT NULL AND
         l_party_name <> FND_API.G_MISS_CHAR AND
         l_party_name <> NVL(db_party_name, FND_API.G_MISS_CHAR)
      THEN
         do_update_party_rel_name(l_party_rec.party_id, l_party_name);
      END IF;

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug (
          'hz_parties_pkg.Update_Row (-)',l_debug_prefix);
      END IF;
      */
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'hz_parties_pkg.Update_Row (-)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

--  Bug 4490715 : If party is PERSON / ORGANIZATION call eTax
--                procedure to populate ZX_PARTY_TAX_PROFILE
--                Call only when tax_reference is not NULL
      IF l_party_dup_rec.tax_reference IS NOT NULL THEN
      IF p_party_type IN ('PERSON', 'ORGANIZATION') THEN
        BEGIN
--  Get PARTY_TAX_PROFILE_ID to pass to update procedure
          SELECT PARTY_TAX_PROFILE_ID INTO L_PARTY_TAX_PROFILE_ID
          FROM ZX_PARTY_TAX_PROFILE
          WHERE PARTY_ID = p_party_id
          AND PARTY_TYPE_CODE = 'THIRD_PARTY'
          AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
            fnd_message.set_token('RECORD', 'ZX_PARTY_TAX_PROFILE');
            fnd_message.set_token('VALUE', to_char(p_party_id) || ', THIRD_PARTY');
            fnd_msg_pub.add;
            RAISE FND_API.G_EXC_ERROR;
        END;

        ZX_PARTY_TAX_PROFILE_PKG.update_row (
         P_PARTY_TAX_PROFILE_ID => L_PARTY_TAX_PROFILE_ID,
         P_COLLECTING_AUTHORITY_FLAG => null,
         P_PROVIDER_TYPE_CODE => null,
         P_CREATE_AWT_DISTS_TYPE_CODE => null,
         P_CREATE_AWT_INVOICES_TYPE_COD => null,
         P_TAX_CLASSIFICATION_CODE => null,
         P_SELF_ASSESS_FLAG => null,
         P_ALLOW_OFFSET_TAX_FLAG => null,
         P_REP_REGISTRATION_NUMBER => l_party_dup_rec.tax_reference,
         P_EFFECTIVE_FROM_USE_LE => null,
         P_RECORD_TYPE_CODE => null,
         P_REQUEST_ID => null,
         P_ATTRIBUTE1 => null,
         P_ATTRIBUTE2 => null,
         P_ATTRIBUTE3 => null,
         P_ATTRIBUTE4 => null,
         P_ATTRIBUTE5 => null,
         P_ATTRIBUTE6 => null,
         P_ATTRIBUTE7 => null,
         P_ATTRIBUTE8 => null,
         P_ATTRIBUTE9 => null,
         P_ATTRIBUTE10 => null,
         P_ATTRIBUTE11 => null,
         P_ATTRIBUTE12 => null,
         P_ATTRIBUTE13 => null,
         P_ATTRIBUTE14 => null,
         P_ATTRIBUTE15 => null,
         P_ATTRIBUTE_CATEGORY => null,
         P_PARTY_ID => null,
         P_PROGRAM_LOGIN_ID => null,
         P_PARTY_TYPE_CODE => null,
         P_SUPPLIER_FLAG => null,
         P_CUSTOMER_FLAG => null,
         P_SITE_FLAG => null,
         P_PROCESS_FOR_APPLICABILITY_FL => null,
         P_ROUNDING_LEVEL_CODE => null,
         P_ROUNDING_RULE_CODE => null,
         P_WITHHOLDING_START_DATE => null,
         P_INCLUSIVE_TAX_FLAG => null,
         P_ALLOW_AWT_FLAG => null,
         P_USE_LE_AS_SUBSCRIBER_FLAG => null,
         P_LEGAL_ESTABLISHMENT_FLAG => null,
         P_FIRST_PARTY_LE_FLAG => null,
         P_REPORTING_AUTHORITY_FLAG => null,
         X_RETURN_STATUS => l_return_status,
         P_REGISTRATION_TYPE_CODE => null,--4742586
         P_COUNTRY_CODE => null--4742586
         );
        IF l_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;
      END IF;
    END IF;
-- Making call to iprocurement if party name is updated for supplier usage. Bug No.4444588
IF p_create_update_flag = 'U' THEN
    DECLARE
       l_party_usage_code VARCHAR2(30);
       l_temp VARCHAR2(2):= '';
       l_return_status VARCHAR2(2000);

     BEGIN
        IF p_party_type = 'ORGANIZATION'
           AND p_organization_rec.organization_name <> p_old_organization_rec.organization_name THEN
              SELECT 'Y' INTO l_temp FROM hz_party_usg_assignments WHERE party_id=p_party_id AND party_usage_code='SUPPLIER'
              AND ROWNUM=1;
              IF l_temp ='Y' THEN
                ICX_CAT_POPULATE_ITEM_GRP.populateVendorNameChanges
                        (
                         P_API_VERSION       => 1.0,
                         P_COMMIT            => FND_API.G_FALSE,
                         P_INIT_MSG_LIST     => FND_API.G_FALSE,
                         P_VALIDATION_LEVEL  => FND_API.G_VALID_LEVEL_FULL,
                         X_RETURN_STATUS     => l_return_status,
                         P_VENDOR_ID          => p_party_id ,
                         P_VENDOR_NAME        => p_organization_rec.organization_name
                         ) ;
              END IF;
        END IF;

     EXCEPTION
        WHEN OTHERS THEN NULL;

     END;
END IF;
------------------------------------------Bug 4444588





    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_update_party_only (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_update_party_only (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


  EXCEPTION
    WHEN g_resource_busy THEN
      fnd_message.set_name('AR', 'HZ_API_RECORD_CHANGED');
      fnd_message.set_token('TABLE', 'hz_parties');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;

  END do_create_update_party_only;

  /**
   * PRIVATE PROCEDURE do_create_party
   *
   * DESCRIPTION
   *     Creates party.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_parties_pkg.Insert_Row
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *     OUT:
   *       x_party_id
   *       x_party_number
   *       x_profile_id
   *     IN/ OUT:
   *       p_person_rec
   *       p_organization_rec
   *       p_group_rec
   *       x_return_status
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *   02-21-2002    Chris Saulit        o Modify to use new name formatting.
   *                                       Base Bug #2221071
   *   04-Mar-2003   Porkodi C           o Bug 2794173, Default value will be assigned to deceased_flag
   *                                       depending on the date_of_death value.
   *   26-Sep-2003   Rajib Ranjan Borah  o Bug Number 3099624.Sensitive HR data will not
   *                                       be inserted into HZ_PERSON_PROFILES table.
   *   02-APR-2004   Rajib Ranjan Borah  o Bug 3317806. If local_activity_code is invalid with respect
   *                                       to the position of the decimal point, replace this with
   *                                       the correct value from fnd_lookup_values provided that the
   *                                       actual_content_source for this record is not 'USER_ENTERED'.
   *   31-DEC-2004   Rajib Ranjan Borah  o SSM SST Integration and Extension.
   *                                       Call HZ_MIXNM_UTILITY.create_exceptions if actual_content_source
   *                                       is some third party content source and no prior profile exists..
   *   10-DEC-2011   Sudhir Gokavarapu   o Bug 13117445 Modified do_create_party_profile calls by adding
   *                                       new parameter p_party_create_update_flag.
   *
   */

  PROCEDURE do_create_party(
    p_party_type                       IN     VARCHAR2,
    p_party_usage_code                 IN     VARCHAR2,
    p_person_rec                       IN OUT NOCOPY PERSON_REC_TYPE,
    p_organization_rec                 IN OUT NOCOPY ORGANIZATION_REC_TYPE,
    p_group_rec                        IN OUT NOCOPY GROUP_REC_TYPE,
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  ) IS

    l_sst_person_rec                   PERSON_REC_TYPE;
    l_new_sst_person_rec               PERSON_REC_TYPE;
    l_sst_organization_rec             ORGANIZATION_REC_TYPE;
    l_new_sst_organization_rec         ORGANIZATION_REC_TYPE;

    l_party_id                         NUMBER;
    l_party_number                     HZ_PARTIES.PARTY_NUMBER%TYPE;
    l_content_source_type              VARCHAR2(30);
    l_actual_content_source            VARCHAR2(30);
    l_data_source_type                 VARCHAR2(30);
    l_data_source_from                 VARCHAR2(30);
    l_profile_id                       NUMBER;
    l_party_object_version_number      NUMBER;

    l_datasource_selected              VARCHAR2(1) := 'N';
    l_mixnmatch_enabled                VARCHAR2(1);
    l_selected_datasources             VARCHAR2(600);
    l_create_update_sst_flag           VARCHAR2(1) := 'C';
    l_party_create_update_flag         VARCHAR2(1);

    l_debug_prefix                     VARCHAR2(30);
    l_party_usg_assignment_rec         HZ_PARTY_USG_ASSIGNMENT_PVT.party_usg_assignment_rec_type;
    l_msg_count                        NUMBER;
    l_msg_data                         VARCHAR2(2000);
  ------------------------Bug No. 4586451
    l_validation_level                 NUMBER;
  ------------------------------Bug No.4586451
  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_party (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_party (+)',
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

    -- assign party record and find the data source.

    IF p_party_type = 'PERSON' THEN

      l_party_id := p_person_rec.party_rec.party_id;

      -- Find the real data source

      l_data_source_type :=
        HZ_MIXNM_UTILITY.FindDataSource (
          p_content_source_type           => p_person_rec.content_source_type,
          p_actual_content_source         => p_person_rec.actual_content_source,
          p_def_actual_content_source     => G_SST_SOURCE_TYPE,
          x_data_source_from              => l_data_source_from );

      --2794173, Setting the default value for the deceased_flag
      IF (p_person_rec.deceased_flag  is NULL or p_person_rec.deceased_flag = fnd_api.g_miss_char) then
         IF (p_person_rec.date_of_death is NULL or p_person_rec.date_of_death = fnd_api.g_miss_date) then
            p_person_rec.deceased_flag := 'N';
         ELSE
            p_person_rec.deceased_flag := 'Y';
         END IF;
      END IF;

    --Bug Number 3099624.
    --If the profile option 'HZ_PROTECT_HR_PERSON_INFO' is set to 'Y',then ,sensitive
    --information like gender,marital status,date of birth and place of birth will not
    --be propagated into HZ_PERSON_PROFILES.
    IF  (p_person_rec.party_rec.orig_system_reference LIKE 'PER%')
                                AND
        (FND_PROFILE.VALUE('HZ_CREATED_BY_MODULE')LIKE '%HR API%')
                                AND
        (fnd_profile.value('HZ_PROTECT_HR_PERSON_INFO')='Y')
    THEN
        p_person_rec.gender         := NULL;
        p_person_rec.marital_status := NULL;
        p_person_rec.date_of_birth  := NULL;
        p_person_rec.place_of_birth := NULL;
    END IF;
    --End of code added for Bug Number 3099624

      -- Validate person record.

      HZ_registry_validate_v2pub.validate_person(
        'C', p_person_rec, G_MISS_PERSON_REC, x_return_status);

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      l_mixnmatch_enabled := g_per_mixnmatch_enabled;
      l_selected_datasources := g_per_selected_datasources;

    ELSIF p_party_type = 'ORGANIZATION' THEN

      l_party_id := p_organization_rec.party_rec.party_id;


      -- Find the real data source

      l_data_source_type :=
        HZ_MIXNM_UTILITY.FindDataSource(
          p_content_source_type           => p_organization_rec.content_source_type,
          p_actual_content_source         => p_organization_rec.actual_content_source,
          p_def_actual_content_source     => G_SST_SOURCE_TYPE,
          x_data_source_from              => l_data_source_from );


      -- Validate organization record.

      HZ_registry_validate_v2pub.validate_organization(
        'C', p_organization_rec, G_MISS_ORGANIZATION_REC, x_return_status);

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;


      -- Bug 3317806 For non user entered data ( actual_content_source <> 'USER_ENTERED' ) ,
      -- if local_activity_code_type = 'NACE' and the local_activity_code is invalid with
      -- respect to the position of the decimal point, then replace this with the valid value.
      IF p_organization_rec.actual_content_source <> 'USER_ENTERED' AND
         p_organization_rec.local_activity_code_type in ( 'NACE' ,'4', '5') AND
         p_organization_rec.local_activity_code IS NOT NULL
      THEN
          SELECT lookup_code
          INTO   p_organization_rec.local_activity_code
          FROM   FND_LOOKUP_VALUES
          WHERE  lookup_type = 'NACE'
            AND  replace (lookup_code,'.','') = replace (p_organization_rec.local_activity_code,'.','')
            AND  rownum = 1;
          -- No need to handle no_data_found as this validation is already done in HZ_REGISTRY_VALIDATE_V2PUB.
      END IF;


      l_mixnmatch_enabled := g_org_mixnmatch_enabled;
      l_selected_datasources := g_org_selected_datasources;

    ELSIF p_party_type = 'GROUP' THEN
      IF p_group_rec.party_rec.party_id IS NOT NULL AND
         p_group_rec.party_rec.party_id <> FND_API.G_MISS_NUM AND
         party_exists(p_party_type, p_group_rec.party_rec.party_id, l_party_number) = 'Y'
      THEN
        fnd_message.set_name('AR', 'HZ_API_DUPLICATE_COLUMN');
        fnd_message.set_token('COLUMN', 'party_id');
        fnd_msg_pub.add;
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- Validate group record.

      HZ_registry_validate_v2pub.validate_group(
        'C', p_group_rec, G_MISS_GROUP_REC, x_return_status);

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- Create group party.

      do_create_update_party_only(
        p_create_update_flag             => 'C',
        p_party_type                     => p_party_type,
        p_group_rec                      => p_group_rec,
        x_party_id                       => x_party_id,
        x_party_number                   => x_party_number,
        p_party_object_version_number    => l_party_object_version_number);
    END IF;

    IF p_party_type IN ('PERSON', 'ORGANIZATION') THEN

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_mixnmatch_enabled = '||l_mixnmatch_enabled);
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_selected_datasources = '||l_selected_datasources);
      END IF;
      */
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_mixnmatch_enabled = '||l_mixnmatch_enabled,
                               p_msg_level=>fnd_log.level_statement);
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_selected_datasources = '||l_selected_datasources,
                               p_msg_level=>fnd_log.level_statement);
      END IF;

      -- If data source is SST or user-entered, we need to check if the party exist.
      -- If party exists, error out. Otherwise, create the SST profile and new party.

      IF l_data_source_type = G_SST_SOURCE_TYPE OR
         l_data_source_type = G_MISS_CONTENT_SOURCE_TYPE
      THEN
        l_data_source_type := G_SST_SOURCE_TYPE;

        IF l_party_id IS NOT NULL AND
           l_party_id <> FND_API.G_MISS_NUM AND
           party_exists(p_party_type, l_party_id, l_party_number) = 'Y'
        THEN
          fnd_message.set_name('AR', 'HZ_API_DUPLICATE_COLUMN');
          fnd_message.set_token('COLUMN', 'party_id');
          fnd_msg_pub.add;
          RAISE FND_API.G_EXC_ERROR;
        END IF;

        -- party does not exist, create new party.

        l_party_create_update_flag := 'C';

        do_create_update_party_only(
          p_create_update_flag             => 'C',
          p_party_type                     => p_party_type,
          p_person_rec                     => p_person_rec,
          p_organization_rec               => p_organization_rec,
          x_party_id                       => x_party_id,
          x_party_number                   => x_party_number,
          p_party_object_version_number    => l_party_object_version_number);

        -- create a SST profile with content_source_type = user entered and
        -- actual_content_source = SST.

        l_actual_content_source := G_SST_SOURCE_TYPE;
        l_content_source_type := G_MISS_CONTENT_SOURCE_TYPE;

        do_create_party_profile(
          p_party_type                     => p_party_type,
          p_party_id                       => x_party_id,
          p_person_rec                     => p_person_rec,
          p_organization_rec               => p_organization_rec,
          p_content_source_type            => l_content_source_type,
          p_actual_content_source          => l_actual_content_source,
          x_profile_id                     => x_profile_id,
          p_party_create_update_flag       => l_party_create_update_flag );
/* Bug 4244112 : do not populate for just UE record
        IF l_mixnmatch_enabled = 'Y' THEN
                HZ_MIXNM_UTILITY.populateMRRExc(
                        'HZ_'||p_party_type||'_PROFILES',
                        l_content_source_type,
                        x_party_id);
        END IF;
*/
      ELSE -- other third party data source

        -- find if data source is selected

        IF l_mixnmatch_enabled = 'Y' THEN
          l_datasource_selected :=
            HZ_MIXNM_UTILITY.isDataSourceSelected(
-- Bug 4376604 : pass entity type
              p_party_type,
              l_data_source_type);
        END IF;

        -- Debug info.
        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_datasource_selected = '||l_datasource_selected);
        END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_datasource_selected = '||l_datasource_selected,
                               p_msg_level=>fnd_log.level_statement);
        END IF;

        -- Error out NOCOPY if the profile with this data source already exists.

        IF l_party_id IS NOT NULL AND
           l_party_id <> FND_API.G_MISS_NUM AND
           party_exists(p_party_type, l_party_id, l_party_number) = 'Y'
        THEN
          IF party_profile_exists(
               p_party_type, l_party_id, l_data_source_type) = 'Y'
          THEN
            fnd_message.set_name('AR', 'HZ_API_DUPLICATE_COLUMN');
            fnd_message.set_token('COLUMN', 'party_id,'||l_data_source_from);
            fnd_msg_pub.add;
            RAISE FND_API.G_EXC_ERROR;
          ELSE
            x_party_id := l_party_id;
            x_party_number := l_party_number;
          END IF;
        ELSE  -- party does not exist

          -- if mix-n-match is enabled and the data source is a ranked
          -- data source, we are going to create 3 profiles: user-entered,
          -- SST and third party profile. We first create a user-entered
          -- profile with content_source_type = 'USER_ENTERED' and
          -- actual_content_source = 'USER_ENTERED' using the third party
          -- record. This is to make sure that a party must have an user-entered
          -- profile. Otherwise, we are going to create 2 profiles: SST and
          -- third party profile. We first create a SST profile with
          -- content_source_type = 'USER_ENTERED' and actual_content_source = 'SST'.

          -- create a new party.

          l_party_create_update_flag := 'C';

          do_create_update_party_only(
            p_create_update_flag             => 'C',
            p_party_type                     => p_party_type,
            p_person_rec                     => p_person_rec,
            p_organization_rec               => p_organization_rec,
            x_party_id                       => x_party_id,
            x_party_number                   => x_party_number,
            p_party_object_version_number    => l_party_object_version_number);

          -- create user-entered / SST profile.

          l_content_source_type := G_MISS_CONTENT_SOURCE_TYPE;
          IF l_mixnmatch_enabled = 'Y' /*AND
             l_datasource_selected = 'Y'*/
          THEN
            l_actual_content_source := G_MISS_CONTENT_SOURCE_TYPE;
          ELSE
            l_actual_content_source := G_SST_SOURCE_TYPE;
          END IF;

          do_create_party_profile(
            p_party_type                     => p_party_type,
            p_party_id                       => x_party_id,
            p_person_rec                     => p_person_rec,
            p_organization_rec               => p_organization_rec,
            p_content_source_type            => l_content_source_type,
            p_actual_content_source          => l_actual_content_source,
            x_profile_id                     => l_profile_id,
            p_party_create_update_flag       => l_party_create_update_flag );

        END IF;

        -- create a third party profile with both content_source_type and
        -- actual_content_source are third party data source.

        l_content_source_type := l_data_source_type;
        l_actual_content_source := l_data_source_type;

        do_create_party_profile (
          p_party_type                       => p_party_type,
          p_party_id                         => x_party_id,
          p_person_rec                       => p_person_rec,
          p_organization_rec                 => p_organization_rec,
          p_content_source_type              => l_content_source_type,
          p_actual_content_source            => l_actual_content_source,
          x_profile_id                       => x_profile_id,
          p_party_create_update_flag       => l_party_create_update_flag );

        -- If mix-n-match is enabled and the third party data source is
        -- ranked, generate SST profile based on the setup.

        IF l_mixnmatch_enabled = 'Y' THEN

          -- The SST profile will have content_source_type = 'USER_ENTERED'
          -- and actual_content_source = 'SST'.

          l_actual_content_source := G_SST_SOURCE_TYPE;
          l_content_source_type := G_MISS_CONTENT_SOURCE_TYPE;

          -- if a new party was created, we do not need to generate SST profile
          -- because the SST = user-entered = third party profile.
          -- We only need to create a SST profile based on the record.

          IF l_party_create_update_flag = 'C' THEN
            do_create_party_profile (
              p_party_type                       => p_party_type,
              p_party_id                         => x_party_id,
              p_person_rec                       => p_person_rec,
              p_organization_rec                 => p_organization_rec,
              p_content_source_type              => l_content_source_type,
              p_actual_content_source            => l_actual_content_source,
              x_profile_id                       => l_profile_id,
              p_party_create_update_flag       => l_party_create_update_flag );

            -- SSM SST Integration and Extension
            HZ_MIXNM_UTILITY.create_exceptions (
              p_party_type                       => p_party_type,
              p_organization_rec                 => p_organization_rec,
              p_person_rec                       => p_person_rec,
              p_third_party_content_source       => l_data_source_type,
              p_party_id                         => x_party_id);

                HZ_MIXNM_UTILITY.populateMRRExc(
                        'HZ_'||p_party_type||'_PROFILES',
                        l_data_source_type,
                        x_party_id);
          ELSE -- need to generate SST profile.

            -- get SST profile

            do_get_party_profile (
              p_party_type                       => p_party_type,
              p_party_id                         => x_party_id,
              p_data_source_type                 => G_SST_SOURCE_TYPE,
              x_person_rec                       => l_sst_person_rec,
              x_organization_rec                 => l_sst_organization_rec );

            -- check if the party has user-entered profile. If the function
            -- return 'Y', means this is the first time we purchase third party
            -- for this party and we should create a SST profile. Otherwise, we
            -- have to update the existing SST.

            IF reset_sst_to_userentered(p_party_type, x_party_id) = 'Y' THEN
              l_create_update_sst_flag := 'C';
              l_new_sst_person_rec := l_sst_person_rec;
              l_new_sst_organization_rec := l_sst_organization_rec;
        -- Bug 4244112 : populate when first third party profile is created
                HZ_MIXNM_UTILITY.populateMRRExc(
                        'HZ_'||p_party_type||'_PROFILES',
                        l_data_source_type,
                        x_party_id);
            ELSE
              l_create_update_sst_flag := 'U';

              -- SSM SST Integration and Extension

              l_new_sst_person_rec.party_rec.party_id := x_party_id;
              l_new_sst_organization_rec.party_rec.party_id := x_party_id;

            END IF;

            IF l_datasource_selected = 'Y' THEN
              -- return SST record which we need to use either
              -- generate a SST profile or update an existing SST profile.

              HZ_MIXNM_UTILITY.updateSSTProfile(
                p_create_update_flag         => 'C',
                p_create_update_sst_flag     => l_create_update_sst_flag,
                p_raise_error_flag           => 'N',
                p_party_type                 => p_party_type,
                p_party_id                   => x_party_id,
                p_new_person_rec             => p_person_rec,
                p_sst_person_rec             => l_sst_person_rec,
                p_new_sst_person_rec         => l_new_sst_person_rec,
                p_new_organization_rec       => p_organization_rec,
                p_sst_organization_rec       => l_sst_organization_rec,
                p_new_sst_organization_rec   => l_new_sst_organization_rec,
                p_data_source_type           => l_data_source_type,
                x_return_status              => x_return_status );

              IF x_return_status <> fnd_api.g_ret_sts_success THEN
                RAISE FND_API.G_EXC_ERROR;
              END IF;
            END IF;
            l_party_create_update_flag := 'U';
            -- Create SST profile.

            IF l_create_update_sst_flag = 'C' THEN
              do_create_party_profile (
                p_party_type                       => p_party_type,
                p_party_id                         => x_party_id,
                p_person_rec                       => l_new_sst_person_rec,
                p_organization_rec                 => l_new_sst_organization_rec,
                p_content_source_type              => l_content_source_type,
                p_actual_content_source            => l_actual_content_source,
                x_profile_id                       => l_profile_id,
                p_party_create_update_flag         => l_party_create_update_flag );

            ELSE  -- update SST profile.
              do_update_party_profile(
                p_party_type                       => p_party_type,
                p_person_rec                       => l_new_sst_person_rec,
                p_old_person_rec                   => l_sst_person_rec,
                p_organization_rec                 => l_new_sst_organization_rec,
                p_old_organization_rec             => l_sst_organization_rec,
                p_data_source_type                 => G_SST_SOURCE_TYPE,
                x_profile_id                       => l_profile_id );

            END IF;

            -- denormalize SST to the party.



            do_create_update_party_only(
              p_create_update_flag             => 'U',
              p_party_type                     => p_party_type,
              p_party_id                       => x_party_id,
              p_person_rec                     => l_new_sst_person_rec,
              p_old_person_rec                 => l_sst_person_rec,
              p_organization_rec               => l_new_sst_organization_rec,
              p_old_organization_rec           => l_sst_organization_rec,
              p_check_object_version_number    => 'N',
              p_party_object_version_number    => l_party_object_version_number,
              x_party_id                       => l_party_id,
              x_party_number                   => l_party_number);
          END IF;
        END IF;
      END IF;
    END IF;

    -- we need to pass some attributes back to person/organization/group record.

    IF p_party_type = 'PERSON' THEN
      p_person_rec.party_rec.party_id := x_party_id;
      p_person_rec.party_rec.party_number := x_party_number;
      p_person_rec.actual_content_source := l_data_source_type;
    ELSIF p_party_type = 'ORGANIZATION' THEN
      p_organization_rec.party_rec.party_id := x_party_id;
      p_organization_rec.party_rec.party_number := x_party_number;
      p_organization_rec.actual_content_source := l_data_source_type;
    ELSE -- group
      p_group_rec.party_rec.party_id := x_party_id;
      p_group_rec.party_rec.party_number := x_party_number;
      l_data_source_type := G_MISS_CONTENT_SOURCE_TYPE;
    END IF;

    -- process classification related attributes.

    do_process_classification(
      p_create_update_flag            => 'C',
      p_party_type                    => p_party_type,
      p_organization_rec              => p_organization_rec,
      p_old_organization_rec          => G_MISS_ORGANIZATION_REC,
      p_person_rec                    => p_person_rec,
      p_old_person_rec                => G_MISS_PERSON_REC,
      p_group_rec                     => p_group_rec,
      p_old_group_rec                 => G_MISS_GROUP_REC,
      p_data_source_type              => l_data_source_type,
      x_return_status                 => x_return_status );

    -- Invoke Business Event System (BES) and DQM
    -- BES and DQM will only be called when SST (i.e. party) is touched).
    -- We will pass SST info. into update event.

    IF l_party_create_update_flag IS NOT NULL THEN
      IF p_party_type = 'ORGANIZATION' THEN


       -- DQM
        --Bug 4866187
        --Bug 5370799
		IF (p_organization_rec.party_rec.orig_system IS NULL OR p_organization_rec.party_rec.orig_system=FND_API.G_MISS_CHAR )  THEN
			HZ_DQM_SYNC.sync_org(x_party_id, l_party_create_update_flag);
		END IF;	  
 -- BES

        IF l_party_create_update_flag = 'C' THEN
          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
            HZ_BUSINESS_EVENT_V2PVT.create_organization_event(p_organization_rec);
          END IF;

          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
            -- populate function for integration service
            HZ_POPULATE_BOT_PKG.pop_hz_organization_profiles(
              p_operation               => 'I',
              p_organization_profile_id => x_profile_id);
          END IF;
        ELSE
          l_new_sst_organization_rec.party_rec.orig_system := p_organization_rec.party_rec.orig_system;
          l_sst_organization_rec.party_rec.orig_system := p_organization_rec.party_rec.orig_system;
          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
            HZ_BUSINESS_EVENT_V2PVT.update_organization_event(
              l_new_sst_organization_rec, l_sst_organization_rec);
          END IF;

          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
            -- populate function for integration service
            HZ_POPULATE_BOT_PKG.pop_hz_organization_profiles(
              p_operation               => 'U',
              p_organization_profile_id => x_profile_id);
          END IF;
        END IF;

 
      ELSIF p_party_type = 'PERSON' THEN

	         -- DQM
	--Bug 4866187
        --Bug 5370799
        IF (p_person_rec.party_rec.orig_system IS NULL OR p_person_rec.party_rec.orig_system=FND_API.G_MISS_CHAR ) THEN
			HZ_DQM_SYNC.sync_person(x_party_id, l_party_create_update_flag);
		END IF;
	  
        -- BES

        IF l_party_create_update_flag = 'C' THEN
          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
            HZ_BUSINESS_EVENT_V2PVT.create_person_event(p_person_rec);
          END IF;

          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
            -- populate function for integration service
            HZ_POPULATE_BOT_PKG.pop_hz_person_profiles(
              p_operation         => 'I',
              p_person_profile_id => x_profile_id);
          END IF;
        ELSE
          l_new_sst_person_rec.party_rec.orig_system := p_person_rec.party_rec.orig_system;
          l_sst_person_rec.party_rec.orig_system := p_person_rec.party_rec.orig_system;
          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
            HZ_BUSINESS_EVENT_V2PVT.update_person_event(
              l_new_sst_person_rec, l_sst_person_rec);
          END IF;

          IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
            -- populate function for integration service
            HZ_POPULATE_BOT_PKG.pop_hz_person_profiles(
              p_operation         => 'U',
              p_person_profile_id => x_profile_id);
          END IF;
        END IF;

 

      END IF;
    END IF;

    --
    -- added for R12 party usage project
    --
    IF p_party_type IN ('PERSON', 'ORGANIZATION') THEN

      -- set party usage code

      IF l_party_create_update_flag = 'C' THEN
        l_party_usg_assignment_rec.party_usage_code :=
            NVL(p_party_usage_code, fnd_profile.value('HZ_PARTY_USAGE_DEFAULT'));
      ELSE
        l_party_usg_assignment_rec.party_usage_code := p_party_usage_code;
      END IF;

      IF l_party_usg_assignment_rec.party_usage_code IS NOT NULL THEN
        l_party_usg_assignment_rec.party_id := x_party_id;

        -- per talk with Maria, we will create an active usage assignment
        -- no matter the party created is inactive or not. this is because
        -- we don't inactivate / reactivate usage assignments in update party
        -- api because we don't know who have end-date the usage assignments.
        -- all of queries should filter out party with status I before it goes
        -- to assignment table.

        -- set created by module
        IF p_party_type = 'PERSON' THEN
          l_party_usg_assignment_rec.created_by_module := p_person_rec.created_by_module;
        ELSE
          l_party_usg_assignment_rec.created_by_module := p_organization_rec.created_by_module;
        END IF;
-------------------------Bug No. 4586451

     IF p_party_type = 'ORGANIZATION' THEN
        IF p_organization_rec.actual_content_source NOT IN (G_SST_SOURCE_TYPE,G_MISS_CONTENT_SOURCE_TYPE) THEN
            l_validation_level  := HZ_PARTY_USG_ASSIGNMENT_PVT.G_VALID_LEVEL_THIRD_MEDIUM ;
        ELSE
            l_validation_level :=HZ_PARTY_USG_ASSIGNMENT_PVT.G_VALID_LEVEL_MEDIUM;
        END IF;
     END IF;
------------------------Bug No. 4586451




        HZ_PARTY_USG_ASSIGNMENT_PVT.assign_party_usage (
          p_validation_level          => l_validation_level,
          p_party_usg_assignment_rec  => l_party_usg_assignment_rec,
          x_return_status             => x_return_status,
          x_msg_count                 => l_msg_count,
          x_msg_data                  => l_msg_data
        );


        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;
    END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_create_party (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_create_party (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_create_party;

  /**
   * PRIVATE PROCEDURE do_update_party
   *
   * DESCRIPTION
   *     Updates party.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_parties_pkg.Update_Row
   *
   * ARGUMENTS
   *     IN:
   *       p_party_type
   *     OUT:
   *       x_profile_id
   *     IN/ OUT:
   *       p_person_rec
   *       p_old_person_rec
   *       p_organization_rec
   *       p_old_organization_rec
   *       p_group_rec
   *       p_party_object_version_number
   *       x_return_status
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *   02-21-2002    Chris Saulit        o Modify to use new name formatting.
   *                                       Base Bug #2221071
   *   04-Mar-2003   Porkodi C           o Bug 2794173, Default value will be assigned to deceased_flag
   *                                       depending on the date_of_death value.
   *   26-Sep-2003   Rajib Ranjan Borah  o Bug Number 3099624.Sensitive HR data will not
   *                                       be updated into HZ_PERSON_PROFILES table.
   *   02-APR-2004   Rajib Ranjan Borah  o Bug 3317806. If local_activity_code is invalid with respect
   *                                       to the position of the decimal point, replace this with
   *                                       the correct value from fnd_lookup_values provided that the
   *                                       actual_content_source for this record is not 'USER_ENTERED'.
   */

  PROCEDURE do_update_party (
    p_party_type                       IN     VARCHAR2,
    p_person_rec                       IN OUT NOCOPY PERSON_REC_TYPE,
    p_old_person_rec                   IN     PERSON_REC_TYPE := G_MISS_PERSON_REC,
    p_organization_rec                 IN OUT NOCOPY ORGANIZATION_REC_TYPE,
    p_old_organization_rec             IN     ORGANIZATION_REC_TYPE := G_MISS_ORGANIZATION_REC,
    p_group_rec                        IN OUT NOCOPY GROUP_REC_TYPE,
    p_old_group_rec                    IN     GROUP_REC_TYPE := G_MISS_GROUP_REC,
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    x_profile_id                       OUT    NOCOPY NUMBER,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  ) IS

    l_sst_person_rec                   PERSON_REC_TYPE;
    l_new_sst_person_rec               PERSON_REC_TYPE;
    l_sst_organization_rec             ORGANIZATION_REC_TYPE;
    l_new_sst_organization_rec         ORGANIZATION_REC_TYPE;
    l_ue_person_rec                    PERSON_REC_TYPE;
    l_ue_organization_rec              ORGANIZATION_REC_TYPE;

    l_party_id                         NUMBER;
    l_party_number                     HZ_PARTIES.PARTY_NUMBER%TYPE;
    l_data_source_type                 VARCHAR2(30);
    l_profile_id                       NUMBER;

    l_user_entered_profile_exists      VARCHAR2(1);
    l_update_sst_profile               VARCHAR2(1) := 'N';
    l_update_party                     VARCHAR2(1) := 'N';
    l_datasource_selected              VARCHAR2(1);
    l_mixnmatch_enabled                VARCHAR2(1);
    l_selected_datasources             VARCHAR2(600);
    l_coming_data_source               VARCHAR2(30);
    l_raise_error                      VARCHAR2(1);
    l_dummy_id                         NUMBER;

    l_debug_prefix                     VARCHAR2(30);

    --Bug No:2771835----------------
    l_old_party_name                   HZ_PARTIES.PARTY_NAME%TYPE;
    l_new_party_name                   HZ_PARTIES.PARTY_NAME%TYPE;
    l_old_tax_reference                HZ_PARTIES.TAX_REFERENCE%TYPE;
    l_new_tax_reference                HZ_PARTIES.TAX_REFERENCE%TYPE;
    -------------Bug 4586451
    l_return_status                    VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
   -------------------------Bug No. 4586451

    CURSOR c_party_name(p_party_id NUMBER) IS
     SELECT party_name,tax_reference FROM HZ_PARTIES
     WHERE PARTY_ID=p_party_id;

    ---End of Bug No:2771835---------

  BEGIN

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_party (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_party (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- assign party record and find the data source.

    IF p_party_type = 'PERSON' THEN

      l_party_id := p_person_rec.party_rec.party_id;
      l_data_source_type := p_old_person_rec.actual_content_source;

      ------Bug No:2771835---------------
      OPEN  c_party_name(l_party_id);
      FETCH c_party_name INTO l_old_party_name,l_old_tax_reference;
      CLOSE c_party_name;
      ------End Bug No:2771835-----------
      -- 2794173, Setting the default value for the deceased_flag
      IF (p_person_rec.deceased_flag is NULL  and p_person_rec.date_of_death is not  NULL) then
          IF p_person_rec.date_of_death= FND_API.G_MISS_DATE then
             p_person_rec.deceased_flag := 'N';

          ELSE
             p_person_rec.deceased_flag := 'Y';
          END IF;
      END IF;

      IF (p_person_rec.deceased_flag = fnd_api.g_miss_char) then
          p_person_rec.deceased_flag := 'N';
      END IF;

      IF (p_person_rec.deceased_flag = 'N' and p_person_rec.date_of_death is null) then
         p_person_rec.date_of_death := fnd_api.g_miss_date;
      end if;


    --Bug Number 3099624.
    --If the profile option 'HZ_PROTECT_HR_PERSON_INFO'  is set to 'Y',then ,sensitive
    --information like gender,marital status,date of birth and place of birth will not
    --be updated into HZ_PERSON_PROFILES and the old values will be retained for these
    --columns.
    IF  (NVL(p_person_rec.party_rec.orig_system_reference,p_old_person_rec.party_rec.orig_system_reference) LIKE 'PER%')
                                AND
        (FND_PROFILE.VALUE('HZ_CREATED_BY_MODULE')LIKE '%HR API%')
                                AND
        (fnd_profile.value('HZ_PROTECT_HR_PERSON_INFO')='Y')
    THEN
        p_person_rec.gender         := NULL;
        p_person_rec.marital_status := NULL;
        p_person_rec.date_of_birth  := NULL;
        p_person_rec.place_of_birth := NULL;
    END IF;
    --End of code added for Bug Number 3099624.



      -- Validate person record.

      HZ_registry_validate_v2pub.validate_person(
        'U', p_person_rec, p_old_person_rec, x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      l_mixnmatch_enabled := g_per_mixnmatch_enabled;
      l_selected_datasources := g_per_selected_datasources;

    ELSIF p_party_type = 'ORGANIZATION' THEN

      l_party_id := p_organization_rec.party_rec.party_id;
      l_data_source_type := p_old_organization_rec.actual_content_source;

      ------Bug No:2771835---------------
      l_old_party_name    := p_old_organization_rec.organization_name;
      l_old_tax_reference := p_old_organization_rec.tax_reference;
      ------End Bug No:2771835-----------

      -- Validate organization record.


      HZ_registry_validate_v2pub.validate_organization(
        'U', p_organization_rec, p_old_organization_rec, x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- Bug 3317806 For non user entered data ( actual_content_source <> 'USER_ENTERED' ) ,
      -- if local_activity_code_type = 'NACE' and the local_activity_code is invalid with
      -- respect to the position of the decimal point, then replace this with the valid value.
      IF NVL(p_organization_rec.actual_content_source,p_old_organization_rec.actual_content_source) <> 'USER_ENTERED' AND
         NVL(p_organization_rec.local_activity_code_type, p_old_organization_rec.local_activity_code) in ( 'NACE' ,'4', '5') AND
         p_organization_rec.local_activity_code IS NOT NULL
         AND p_organization_rec.local_activity_code <> fnd_api.g_miss_char
      THEN
          SELECT lookup_code
          INTO   p_organization_rec.local_activity_code
          FROM   FND_LOOKUP_VALUES
          WHERE  lookup_type = 'NACE'
            AND  replace (lookup_code,'.','') = replace (p_organization_rec.local_activity_code,'.','')
            AND  rownum = 1;
          -- No need to handle no_data_found as this validation is already done in HZ_REGISTRY_VALIDATE_V2PUB.
      END IF;


      l_mixnmatch_enabled := g_org_mixnmatch_enabled;
      l_selected_datasources := g_org_selected_datasources;

    ELSIF p_party_type = 'GROUP' THEN

      l_data_source_type := G_MISS_CONTENT_SOURCE_TYPE;
      ------Bug No:2771835---------------
      l_old_party_name := p_old_group_rec.group_name;
      ------End Bug No:2771835-----------


      -- Validate group record.

      HZ_registry_validate_v2pub.validate_group(
         'U', p_group_rec, p_old_group_rec, x_return_status);

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- update group party.

      do_create_update_party_only(
        p_create_update_flag             => 'U',
        p_party_type                     => p_party_type,
        p_party_id                       => p_group_rec.party_rec.party_id,
        p_party_object_version_number    => p_party_object_version_number,
        p_group_rec                      => p_group_rec,
        p_old_group_rec                  => p_old_group_rec,
        x_party_id                       => l_party_id,
        x_party_number                   => l_party_number );
    END IF;

    IF p_party_type IN ('PERSON', 'ORGANIZATION') THEN

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_mixnmatch_enabled = '||l_mixnmatch_enabled);
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_data_source_type = '||l_data_source_type);
      END IF;
      */
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_mixnmatch_enabled = '||l_mixnmatch_enabled,
                               p_msg_level=>fnd_log.level_statement);
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_data_source_type = '||l_data_source_type,
                               p_msg_level=>fnd_log.level_statement);

      END IF;

      -- if mix-n-match is not enabled or we are updating third party profile or
      -- we are updating SST and SST was not generated, we need to update the
      -- profile.

      l_user_entered_profile_exists :=
        party_profile_exists(p_party_type, l_party_id, G_MISS_CONTENT_SOURCE_TYPE);

      IF l_mixnmatch_enabled = 'N' OR
         (l_data_source_type = G_SST_SOURCE_TYPE AND
          l_user_entered_profile_exists = 'N') OR
         l_data_source_type <> G_SST_SOURCE_TYPE
      THEN
        do_update_party_profile (
          p_party_type                       => p_party_type,
          p_person_rec                       => p_person_rec,
          p_old_person_rec                   => p_old_person_rec,
          p_organization_rec                 => p_organization_rec,
          p_old_organization_rec             => p_old_organization_rec,
          p_data_source_type                 => l_data_source_type,
          x_profile_id                       => x_profile_id );
      END IF;

      -- if user is updating SST profile, we need to update party.
      -- if mix-n-match is enabled and the SST profile was generated
      -- (i.e. has user-entered profile), we need to update SST profile
      -- as well as user-entered profile.

      IF l_data_source_type = G_SST_SOURCE_TYPE THEN
        l_sst_person_rec := p_old_person_rec;
        l_sst_organization_rec := p_old_organization_rec;

        l_update_party := 'Y';

        l_new_sst_person_rec := p_person_rec;
        l_new_sst_organization_rec := p_organization_rec;

        IF l_mixnmatch_enabled = 'Y' AND
           l_user_entered_profile_exists = 'Y'
        THEN
          l_update_sst_profile := 'Y';
          l_raise_error := 'Y';
          l_coming_data_source := G_MISS_CONTENT_SOURCE_TYPE;
        END IF;

      ELSIF l_mixnmatch_enabled = 'Y' THEN

        -- if the data source is selected, we need to check
        -- if we need to propagate the change to SST profile,
        -- and the party.

        l_datasource_selected :=
          HZ_MIXNM_UTILITY.isDataSourceSelected(
-- Bug 4376604 : pass entity type
              p_party_type,
            l_data_source_type);

        -- Debug info.
        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_datasource_selected = '||l_datasource_selected);
        END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_datasource_selected = '||l_datasource_selected,
                               p_msg_level=>fnd_log.level_statement);
        END IF;

        IF l_datasource_selected = 'Y' THEN
          l_update_sst_profile := 'Y';
          l_raise_error := 'N';
          l_coming_data_source := l_data_source_type;

          do_get_party_profile (
            p_party_type                       => p_party_type,
            p_party_id                         => l_party_id,
            p_data_source_type                 => G_SST_SOURCE_TYPE,
            x_person_rec                       => l_sst_person_rec,
            x_organization_rec                 => l_sst_organization_rec);
        END IF;
      END IF;

      IF l_update_sst_profile = 'Y' THEN

        -- return SST record which we need to use to update an existing
        -- SST profile.

        HZ_MIXNM_UTILITY.updateSSTProfile (
          p_create_update_flag                 => 'U',
          p_create_update_sst_flag             => 'U',
          p_raise_error_flag                   => l_raise_error,
          p_party_type                         => p_party_type,
          p_party_id                           => l_party_id,
          p_new_person_rec                     => p_person_rec,
          p_old_person_rec                     => p_old_person_rec,
          p_sst_person_rec                     => l_sst_person_rec,
          p_new_sst_person_rec                 => l_new_sst_person_rec,
          p_new_organization_rec               => p_organization_rec,
          p_old_organization_rec               => p_old_organization_rec,
          p_sst_organization_rec               => l_sst_organization_rec,
          p_new_sst_organization_rec           => l_new_sst_organization_rec,
          p_data_source_type                   => l_data_source_type,
          x_return_status                      => x_return_status );

        IF x_return_status <> fnd_api.g_ret_sts_success THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;

        l_new_sst_person_rec.party_rec.party_id := l_party_id;
        l_new_sst_organization_rec.party_rec.party_id := l_party_id;

        -- update SST profile.

        do_update_party_profile (
          p_party_type                       => p_party_type,
          p_person_rec                       => l_new_sst_person_rec,
          p_old_person_rec                   => l_sst_person_rec,
          p_organization_rec                 => l_new_sst_organization_rec,
          p_old_organization_rec             => l_sst_organization_rec,
          p_data_source_type                 => G_SST_SOURCE_TYPE,
          x_profile_id                       => l_profile_id );

        -- if user is updating SST profile, update user-entered profile too.

        IF l_data_source_type = G_SST_SOURCE_TYPE THEN
          x_profile_id := l_profile_id;

          do_get_party_profile (
            p_party_type                       => p_party_type,
            p_party_id                         => l_party_id,
            p_data_source_type                 => G_MISS_CONTENT_SOURCE_TYPE,
            x_person_rec                       => l_ue_person_rec,
            x_organization_rec                 => l_ue_organization_rec);

          do_update_party_profile (
            p_party_type                       => p_party_type,
            p_person_rec                       => l_new_sst_person_rec,
            p_old_person_rec                   => l_ue_person_rec,
            p_organization_rec                 => l_new_sst_organization_rec,
            p_old_organization_rec             => l_ue_organization_rec,
            p_data_source_type                 => G_MISS_CONTENT_SOURCE_TYPE,
            x_profile_id                       => l_profile_id );
        END IF;

        l_update_party := 'Y';
      END IF;

      IF l_update_party = 'Y' THEN

        -- Debug info.
        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_party_id = '||l_party_id);
        END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_party_id = '||l_party_id,
                               p_msg_level=>fnd_log.level_statement);
        END IF;
---------------Bug 4586451
IF p_party_type ='ORGANIZATION'AND
 p_organization_rec.organization_name <>FND_API.G_MISS_CHAR AND
 p_organization_rec.organization_name IS NOT NULL AND
 p_organization_rec.organization_name<>p_old_organization_rec.organization_name AND
 nvl(p_organization_rec.actual_content_source,p_old_organization_rec.actual_content_source) IN (G_SST_SOURCE_TYPE,G_MISS_CONTENT_SOURCE_TYPE) THEN
         validate_party_name (
                   p_party_id                    => l_party_id,
                   p_party_name                  => p_organization_rec.organization_name,
                   x_return_status               => l_return_status);
END IF;

IF l_return_status <> fnd_api.g_ret_sts_success THEN
      RAISE FND_API.G_EXC_ERROR;
END IF;

----------------Bug4586451

       l_sst_person_rec.party_rec := p_old_person_rec.party_rec;
       l_new_sst_person_rec.party_rec := p_person_rec.party_rec;
       l_sst_organization_rec.party_rec := p_old_organization_rec.party_rec;
       l_new_sst_organization_rec.party_rec := p_organization_rec.party_rec; 

        do_create_update_party_only(
          p_create_update_flag             => 'U',
          p_party_type                     => p_party_type,
          p_party_id                       => l_party_id,
          p_party_object_version_number    => p_party_object_version_number,
          p_person_rec                     => l_new_sst_person_rec,
          p_old_person_rec                 => l_sst_person_rec,
          p_organization_rec               => l_new_sst_organization_rec,
          p_old_organization_rec           => l_sst_organization_rec,
          x_party_id                       => l_dummy_id,
          x_party_number                   => l_party_number );
      END IF;
    END IF;

    -- process classification related attributes.

    do_process_classification(
      p_create_update_flag               => 'U',
      p_party_type                    => p_party_type,
      p_organization_rec                 => p_organization_rec,
      p_old_organization_rec             => p_old_organization_rec,
      p_person_rec                       => p_person_rec,
      p_old_person_rec                   => p_old_person_rec,
      p_group_rec                        => p_group_rec,
      p_old_group_rec                    => p_old_group_rec,
      p_data_source_type                 => l_data_source_type,
      x_return_status                    => x_return_status );

     ---Bug No: 2771835----------
     OPEN  c_party_name(l_party_id);
     FETCH c_party_name INTO l_new_party_name,l_new_tax_reference;
     CLOSE c_party_name;
     --update_party_search(l_party_id,l_old_party_name,l_new_party_name,l_old_tax_reference,l_new_tax_reference);
     IF p_party_type='PERSON' THEN
       --update_rel_person_search(p_old_person_rec,p_person_rec);
       NULL;
     END IF;
     ---End Bug No: 2771835-------

    -- Invoke business event system and DQM
    -- BES and DQM will only be called when SST (i.e. party) is touched).
    -- We will pass SST info. into update event.

    IF l_update_party = 'Y' THEN
      IF p_party_type = 'ORGANIZATION' THEN
   
        -- DQM
        HZ_DQM_SYNC.sync_org(l_party_id, 'U');
		
       l_new_sst_organization_rec.party_rec.orig_system := p_organization_rec.party_rec.orig_system;
        l_sst_organization_rec.party_rec.orig_system := p_organization_rec.party_rec.orig_system;
        -- BES

        IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'Y')) THEN
          HZ_BUSINESS_EVENT_V2PVT.update_organization_event(
            l_new_sst_organization_rec, l_sst_organization_rec);
        END IF;

        IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
          -- populate function for integration service
          HZ_POPULATE_BOT_PKG.pop_hz_organization_profiles(
            p_operation               => 'U',
            p_organization_profile_id => x_profile_id);
        END IF;

   

      ELSIF p_party_type = 'PERSON' THEN

        -- DQM
        HZ_DQM_SYNC.sync_person(l_party_id, 'U');
		
	  l_new_sst_person_rec.party_rec.orig_system := p_person_rec.party_rec.orig_system;
        l_sst_person_rec.party_rec.orig_system := p_person_rec.party_rec.orig_system;
        -- BES

        IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'Y')) THEN
          HZ_BUSINESS_EVENT_V2PVT.update_person_event(
            l_new_sst_person_rec, l_sst_person_rec);
        END IF;

        IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
          -- populate function for integration service
          HZ_POPULATE_BOT_PKG.pop_hz_person_profiles(
            p_operation         => 'U',
            p_person_profile_id => x_profile_id);
        END IF;



      END IF;
    END IF;

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'do_update_party (-)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'do_update_party (-)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


  END do_update_party;

  --------------------------------------
  -- public procedures and functions
  --------------------------------------

  /**
   * PROCEDURE create_person
   *
   * DESCRIPTION
   *     Creates person.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.create_person_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_person_rec         Person record.
   *     p_party_usage_code   Party Usage Code
   *   IN/OUT:
   *   OUT:
   *     x_party_id           Party ID.
   *     x_party_number       Party number.
   *     x_profile_id         Person profile ID.
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *
   */

  PROCEDURE create_person (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_party_usage_code                 IN     VARCHAR2,
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER,
    x_return_status                    OUT    NOCOPY VARCHAR2,
    x_msg_count                        OUT    NOCOPY NUMBER,
    x_msg_data                         OUT    NOCOPY VARCHAR2
  ) IS

    l_context                          VARCHAR2(30);
    l_api_name                         CONSTANT VARCHAR2(30) := 'create_person';
    l_person_rec                       PERSON_REC_TYPE := p_person_rec;

    dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    dss_msg_count     NUMBER := 0;
    dss_msg_data      VARCHAR2(2000):= null;
    l_test_security   VARCHAR2(1):= 'F';
    l_debug_prefix                      VARCHAR2(30) := '';

  BEGIN

    -- standard start of API savepoint
    SAVEPOINT create_person;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_person (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'create_person (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

    -- cache if mix-n-match is enabled

    -- IF g_per_mixnmatch_enabled IS NULL THEN
    HZ_MIXNM_UTILITY.LoadDataSources(
      'HZ_PERSON_PROFILES', g_per_entity_attr_id,
      g_per_mixnmatch_enabled, g_per_selected_datasources);
    -- END IF;

    -- call to business logic.
    do_create_party(
      p_party_type            => 'PERSON',
      p_party_usage_code      => p_party_usage_code,
      p_person_rec            => l_person_rec,
      x_party_id              => x_party_id,
      x_party_number          => x_party_number,
      x_profile_id            => x_profile_id,
      x_return_status         => x_return_status,
      p_organization_rec      => G_MISS_ORGANIZATION_REC,
      p_group_rec             => G_MISS_GROUP_REC );

    -- Bug 2486394 Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance.
    --
    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'INSERT',
                  p_db_object_name     => 'HZ_PARTIES',
                  p_instance_pk1_value => x_party_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
         --
         -- Bug 3835601: replaced the dss message with a more user friendly message
         --
         FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_INSERT_PRIVILEGE');
         FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                               hz_dss_util_pub.get_display_name(null, 'PERSON'));
         FND_MSG_PUB.ADD;
         RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug_return_messages (
        x_msg_count, x_msg_data, 'WARNING');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_person (-)');
    END IF;
    */
    IF  fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'create_person (-)',
                                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      ROLLBACK TO create_person;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_person (-)');
      END IF;*/

      IF fnd_log.level_error >= fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure >= fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_person (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
       END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO create_person;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'UNEXPECTED ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_person (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_person (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_person;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'SQL ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_person (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_person (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END create_person;

  /**
   * PROCEDURE create_person
   *
   * DESCRIPTION
   *     Creates person.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.create_person_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_person_rec         Person record.
   *   IN/OUT:
   *   OUT:
   *     x_party_id           Party ID.
   *     x_party_number       Party number.
   *     x_profile_id         Person profile ID.
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *
   */

  PROCEDURE create_person (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_person_rec                       IN     PERSON_REC_TYPE,
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER,
    x_return_status                    OUT    NOCOPY VARCHAR2,
    x_msg_count                        OUT    NOCOPY NUMBER,
    x_msg_data                         OUT    NOCOPY VARCHAR2
  ) IS

  BEGIN

    create_person (
      p_init_msg_list             => p_init_msg_list,
      p_person_rec                => p_person_rec,
      p_party_usage_code          => null,
      x_party_id                  => x_party_id,
      x_party_number              => x_party_number,
      x_profile_id                => x_profile_id,
      x_return_status             => x_return_status,
      x_msg_count                 => x_msg_count,
      x_msg_data                  => x_msg_data
    );

  END create_person;

  /**
   * PROCEDURE update_person
   *
   * DESCRIPTION
   *     Updates person.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.update_person_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_person_rec         Person record.
   *   IN/OUT:
   *     p_party_object_version_number  Used for locking the being updated record.
   *   OUT:
   *     x_profile_id         Person profile ID.
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *   30-06-2010    Sudhir Gokavarapu   Bug9735521 - When Actual Content Source is NULL
   *                                     then 'USER_ENTERED' is assigned. 
   *
   */

  PROCEDURE update_person (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_person_rec                       IN     PERSON_REC_TYPE,
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    x_profile_id                       OUT NOCOPY    NUMBER,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_api_name                         CONSTANT VARCHAR2(30) := 'update_person';
    l_person_rec                       PERSON_REC_TYPE := p_person_rec;
    l_old_person_rec                   PERSON_REC_TYPE;
    l_data_source_from                 VARCHAR2(30);
    l_context                          VARCHAR2(30);

    dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    dss_msg_count     NUMBER := 0;
    dss_msg_data      VARCHAR2(2000):= null;
    l_test_security   VARCHAR2(1):= 'F';
    l_debug_prefix                     VARCHAR2(30) := '';

  BEGIN

    -- standard start of API savepoint
    SAVEPOINT update_person;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_person (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'update_person (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    
    --Bug9735521 - When Actual Content Source is NULL then 'USER_ENTERED' is assigned. 
    IF l_person_rec.actual_content_source IS NULL THEN
          l_person_rec.actual_content_source := 'USER_ENTERED';
            IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Actual Content Source is NULL so USER_ENTERED is assigned.',
                                      p_msg_level=>fnd_log.level_procedure);
            END IF;
    END IF;

    -- initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;


/**
    get_person_rec is checking if the person party has been
    passed in.

    -- make sure PEROSN party has been passed in
    BEGIN
      SELECT 1 INTO l_count
      FROM   HZ_PARTIES
      WHERE  PARTY_ID = p_person_rec.party_rec.party_id
      AND    PARTY_TYPE = 'PERSON';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
        fnd_message.set_token('RECORD', 'person');
        fnd_message.set_token('VALUE', to_char(p_person_rec.party_rec.party_id));
        fnd_msg_pub.add;
        RAISE FND_API.G_EXC_ERROR;
    END;
**/

     IF (l_person_rec.party_rec.orig_system is not null
         and l_person_rec.party_rec.orig_system <>fnd_api.g_miss_char)
       and (l_person_rec.party_rec.orig_system_reference is not null
         and l_person_rec.party_rec.orig_system_reference <>fnd_api.g_miss_char)
       and (l_person_rec.party_rec.party_id = FND_API.G_MISS_NUM or l_person_rec.party_rec.party_id is null) THEN

        hz_orig_system_ref_pub.get_owner_table_id
                        (p_orig_system => l_person_rec.party_rec.orig_system,
                        p_orig_system_reference => l_person_rec.party_rec.orig_system_reference,
                        p_owner_table_name => 'HZ_PARTIES',
                        x_owner_table_id => l_person_rec.party_rec.party_id,
                        x_return_status => x_return_status);

            IF x_return_status <> fnd_api.g_ret_sts_success THEN
                RAISE FND_API.G_EXC_ERROR;
            END IF;
    END IF;
    -- cache if mix-n-match is enabled

    -- IF g_per_mixnmatch_enabled IS NULL THEN
    HZ_MIXNM_UTILITY.LoadDataSources(
      'HZ_PERSON_PROFILES', g_per_entity_attr_id,
      g_per_mixnmatch_enabled, g_per_selected_datasources);
    -- END IF;

    -- Get old records. Will be used by business event system.
    get_person_rec (
        p_party_id                   => l_person_rec.party_rec.party_id,
        p_content_source_type        => HZ_MIXNM_UTILITY.FindDataSource(
                                          p_content_source_type           => l_person_rec.content_source_type,
                                          p_actual_content_source         => l_person_rec.actual_content_source,
                                          p_def_actual_content_source     => G_SST_SOURCE_TYPE,
                                          x_data_source_from              => l_data_source_from ),
        x_person_rec                 => l_old_person_rec,
        x_return_status              => x_return_status,
        x_msg_count                  => x_msg_count,
        x_msg_data                   => x_msg_data);

    IF x_return_status = fnd_api.g_ret_sts_error THEN
      RAISE FND_API.G_EXC_ERROR;
    ELSIF x_return_status = fnd_api.g_ret_sts_unexp_error THEN
      RAISE FND_API.G_EXC_UNEXPECTED_ERROR;
    END IF;

    -- Bug 2486394 Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance.
    --
    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'UPDATE',
                  p_db_object_name     => 'HZ_PARTIES',
                  p_instance_pk1_value => l_person_rec.party_rec.party_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
         --
         -- Bug 3835601: replaced the dss message with a more user friendly message
         --
         FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_UPDATE_PRIVILEGE');
         FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                               hz_dss_util_pub.get_display_name(null, 'PERSON'));
         FND_MSG_PUB.ADD;
         RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- call to business logic.
    do_update_party(
      p_party_type                   => 'PERSON',
      p_person_rec                   => l_person_rec,
      p_old_person_rec               => l_old_person_rec,
      p_party_object_version_number  => p_party_object_version_number,
      x_profile_id                   => x_profile_id,
      x_return_status                => x_return_status,
      p_organization_rec             => G_MISS_ORGANIZATION_REC,
      p_group_rec                    => G_MISS_GROUP_REC );

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug_return_messages (
        x_msg_count, x_msg_data, 'WARNING');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_person (-)');
    END IF;
    */
    IF  fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'update_person (-)',
                                p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      ROLLBACK TO update_person;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_person (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_person (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO update_person;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'UNEXPECTED ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_person (-)');
      END IF;
      */
       IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
       END IF;
       IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_message=>'update_person (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
       END IF;
      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_person;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'SQL ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_person (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_person (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END update_person;

  /**
   * PROCEDURE create_group
   *
   * DESCRIPTION
   *     Creates group.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.create_group_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_group_rec          Group record.
   *   IN/OUT:
   *   OUT:
   *     x_party_id           Party ID.
   *     x_party_number       Party number.
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *
   */
  PROCEDURE create_group (
    p_init_msg_list                    IN      VARCHAR2 := fnd_api.g_false,
    p_group_rec                        IN      GROUP_REC_TYPE,
    x_party_id                         OUT NOCOPY     NUMBER,
    x_party_number                     OUT NOCOPY     VARCHAR2,
    x_return_status                    OUT NOCOPY     VARCHAR2,
    x_msg_count                        OUT NOCOPY     NUMBER,
    x_msg_data                         OUT NOCOPY     VARCHAR2
  ) IS

    l_context                          VARCHAR2(30);
    l_api_name                         CONSTANT VARCHAR2(30) := 'create_group';
    l_profile_id                       NUMBER;
    l_group_rec                        GROUP_REC_TYPE := p_group_rec;

   dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
   dss_msg_count     NUMBER := 0;
   dss_msg_data      VARCHAR2(2000):= null;
   l_test_security   VARCHAR2(1):= 'F';
   l_debug_prefix                      VARCHAR2(30) := '';
  BEGIN

    -- standard start of API savepoint
    SAVEPOINT create_group;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_group (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'create_group (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

    -- call to business logic.
    do_create_party(
      p_party_type                      => 'GROUP',
      p_party_usage_code                => null,
      p_group_rec                       => l_group_rec,
      x_party_id                        => x_party_id,
      x_party_number                    => x_party_number,
      x_profile_id                      => l_profile_id,
      x_return_status                   => x_return_status,
      p_organization_rec                => G_MISS_ORGANIZATION_REC,
      p_person_rec                      => G_MISS_PERSON_REC );

    -- Bug 2486394 Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance.
    --
    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'INSERT',
                  p_db_object_name     => 'HZ_PARTIES',
                  p_instance_pk1_value => x_party_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
         --
         -- Bug 3835601: replaced the dss message with a more user friendly message
         --
         FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_INSERT_PRIVILEGE');
         FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                               hz_dss_util_pub.get_display_name('HZ_PARTIES', null));
         FND_MSG_PUB.ADD;
         RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- Invoke business event system.
    IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
      HZ_BUSINESS_EVENT_V2PVT.create_group_event (l_group_rec);
    END IF;

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug_return_messages (
        x_msg_count, x_msg_data, 'WARNING');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_group (-)');
    END IF;
    */
    IF  fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'create_group (-)',
                                p_msg_level=>fnd_log.level_procedure);
     END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      ROLLBACK TO create_group;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_group (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_group (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO create_group;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'UNEXPECTED ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_group (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_group (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_group;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'SQL ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_group (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_group (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END create_group;

  /**
   * PROCEDURE update_group
   *
   * DESCRIPTION
   *     Updates group.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.update_group_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_group_rec          Group record.
   *   IN/OUT:
   *     p_party_object_version_number  Used for locking the being updated record.
   *   OUT:
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *
   */

  PROCEDURE update_group (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_group_rec                        IN     GROUP_REC_TYPE,
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_context                          VARCHAR2(30);
    l_api_name                         CONSTANT VARCHAR2(30) := 'update_group';
    l_profile_id                       NUMBER;
    l_group_rec                        GROUP_REC_TYPE := p_group_rec;
    l_old_group_rec                    GROUP_REC_TYPE := p_group_rec;

   dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
   dss_msg_count     NUMBER := 0;
   dss_msg_data      VARCHAR2(2000):= null;
   l_test_security   VARCHAR2(1):= 'F';
   l_debug_prefix                      VARCHAR2(30) := '';

  BEGIN

    -- standard start of API savepoint
    SAVEPOINT update_group;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_group (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'update_group (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

    /**
    get_group_rec is checking if the group party has been
    passed in.

    -- make sure GROUP party has been passed in
    BEGIN
      SELECT 1 INTO l_count
      FROM   HZ_PARTIES
      WHERE  PARTY_ID = p_group_rec.party_rec.party_id
      AND    PARTY_TYPE = 'GROUP';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
        fnd_message.set_token('RECORD', 'group');
        fnd_message.set_token('VALUE', to_char(p_group_rec.party_rec.party_id));
        fnd_msg_pub.add;
        RAISE FND_API.G_EXC_ERROR;
    END;
    **/

      IF (l_group_rec.party_rec.orig_system is not null
         and l_group_rec.party_rec.orig_system <>fnd_api.g_miss_char)
       and (l_group_rec.party_rec.orig_system_reference is not null
         and l_group_rec.party_rec.orig_system_reference <>fnd_api.g_miss_char)
       and (l_group_rec.party_rec.party_id = FND_API.G_MISS_NUM or l_group_rec.party_rec.party_id is null) THEN

        hz_orig_system_ref_pub.get_owner_table_id
                        (p_orig_system => l_group_rec.party_rec.orig_system,
                        p_orig_system_reference => l_group_rec.party_rec.orig_system_reference,
                        p_owner_table_name => 'HZ_PARTIES',
                        x_owner_table_id => l_group_rec.party_rec.party_id,
                        x_return_status => x_return_status);

            IF x_return_status <> fnd_api.g_ret_sts_success THEN
                RAISE FND_API.G_EXC_ERROR;
            END IF;
      END IF;

    -- Get old records. Will be used by validation.
    get_group_rec (
      p_party_id                     => l_group_rec.party_rec.party_id,
      x_group_rec                    => l_old_group_rec,
      x_return_status                => x_return_status,
      x_msg_count                    => x_msg_count,
      x_msg_data                     => x_msg_data);

    IF x_return_status = fnd_api.g_ret_sts_error THEN
      RAISE fnd_api.g_exc_error;
    ELSIF x_return_status = fnd_api.g_ret_sts_unexp_error THEN
      RAISE fnd_api.g_exc_unexpected_error;
    END IF;

    -- Bug 2486394 Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance.
    --
    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'UPDATE',
                  p_db_object_name     => 'HZ_PARTIES',
                  p_instance_pk1_value => l_group_rec.party_rec.party_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
         --
         -- Bug 3835601: replaced the dss message with a more user friendly message
         --
         FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_UPDATE_PRIVILEGE');
         FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                               hz_dss_util_pub.get_display_name('HZ_PARTIES', null));
         FND_MSG_PUB.ADD;
         RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- call to business logic.
    do_update_party(
      p_party_type                      => 'GROUP',
      p_group_rec                       => l_group_rec,
      p_old_group_rec                   => l_old_group_rec,
      p_party_object_version_number     => p_party_object_version_number,
      x_profile_id                      => l_profile_id,
      x_return_status                   => x_return_status,
      p_organization_rec                => G_MISS_ORGANIZATION_REC,
      p_person_rec                      => G_MISS_PERSON_REC );

    -- Invoke business event system.
    IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
      HZ_BUSINESS_EVENT_V2PVT.update_group_event (l_group_rec , l_old_group_rec);
    END IF;

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

    -- Debug info.
    /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
            x_msg_count, x_msg_data, 'WARNING');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_group (-)');
    END IF;
    */
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'update_group (-)',
                                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN FND_API.G_EXC_ERROR THEN
      ROLLBACK TO update_group;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_group (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_group (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN FND_API.G_EXC_UNEXPECTED_ERROR THEN
      ROLLBACK TO update_group;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'UNEXPECTED ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_group (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_group (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_group;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'SQL ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_group (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_group (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END update_group;

  /**
   * PROCEDURE create_organization
   *
   * DESCRIPTION
   *     Creates organization.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.create_organization_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_organization_rec   Organization record.
   *     p_party_usage_code   Party Usage Code.
   *   IN/OUT:
   *   OUT:
   *     x_party_id           Party ID.
   *     x_party_number       Party number.
   *     x_profile_id         Organization profile ID.
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *   26-NOV-2001   Joe del Callar      Bug 2117973: modified to conform to
   *                                     PL/SQL coding standards.
   *                                     Changed select...intos into cursors.
   *
   */

  PROCEDURE create_organization (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_party_usage_code                 IN     VARCHAR2,
    x_return_status                    OUT    NOCOPY VARCHAR2,
    x_msg_count                        OUT    NOCOPY NUMBER,
    x_msg_data                         OUT    NOCOPY VARCHAR2,
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  ) IS

    l_api_name                        CONSTANT VARCHAR2(30)  := 'create_organization';
    l_organization_rec                ORGANIZATION_REC_TYPE := p_organization_rec;
    l_context                         VARCHAR2(30);

   dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
   dss_msg_count     NUMBER := 0;
   dss_msg_data      VARCHAR2(2000):= null;
   l_test_security   VARCHAR2(1):= 'F';
   l_debug_prefix                      VARCHAR2(30) := '';

  BEGIN

    -- standard start of API savepoint
    SAVEPOINT create_organization;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_organization (+)');
    END IF;
    */

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'create_organization (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'before LoadDataSources (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'before LoadDataSources (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

    -- cache if mix-n-match is enabled

    -- IF g_org_mixnmatch_enabled IS NULL THEN
    HZ_MIXNM_UTILITY.LoadDataSources(
      'HZ_ORGANIZATION_PROFILES', g_org_entity_attr_id,
      g_org_mixnmatch_enabled, g_org_selected_datasources);
    -- END IF;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'after LoadDataSources (+)');
    END IF;
    */
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'after LoadDataSources (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call to business logic.
    do_create_party(
      p_party_type                    => 'ORGANIZATION',
      p_party_usage_code              => p_party_usage_code,
      p_organization_rec              => l_organization_rec,
      x_party_id                      => x_party_id,
      x_party_number                  => x_party_number,
      x_profile_id                    => x_profile_id,
      x_return_status                 => x_return_status,
      p_person_rec                    => G_MISS_PERSON_REC,
      p_group_rec                     => G_MISS_GROUP_REC );

    -- call to insert credit related columns to hz_credit_ratings.

    IF l_organization_rec.actual_content_source IN
      (G_MISS_CONTENT_SOURCE_TYPE, G_SST_SOURCE_TYPE)
    THEN
      populate_credit_rating(
        p_create_update_flag      => 'C',
        p_organization_rec        => l_organization_rec,
        x_return_status           => x_return_status );

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE fnd_api.g_exc_error;
      END IF;
    END IF;

    -- Bug 2486394 -Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance.
    --
    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'INSERT',
                  p_db_object_name     => 'HZ_PARTIES',
                  p_instance_pk1_value => x_party_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
         --
         -- Bug 3835601: replaced the dss message with a more user friendly message
         --
         FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_INSERT_PRIVILEGE');
         FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                               hz_dss_util_pub.get_display_name(null, 'ORGANIZATION'));
         FND_MSG_PUB.ADD;
         RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug_return_messages(x_msg_count,
                                             x_msg_data, 'WARNING');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_organization (-)');
    END IF;
    */
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'create_organization (-)',
                                p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_organization;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_organization (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_organization (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_organization;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'UNEXPECTED ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_organization (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_organization (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_organization;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'SQL ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'create_organization (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_organization (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END create_organization;

  /**
   * PROCEDURE create_organization
   *
   * DESCRIPTION
   *     Creates organization.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.create_organization_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_organization_rec   Organization record.
   *   IN/OUT:
   *   OUT:
   *     x_party_id           Party ID.
   *     x_party_number       Party number.
   *     x_profile_id         Organization profile ID.
   *     x_return_status      Return status after the call. The status can
   *                          be FND_API.G_RET_STS_SUCCESS (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *   26-NOV-2001   Joe del Callar      Bug 2117973: modified to conform to
   *                                     PL/SQL coding standards.
   *                                     Changed select...intos into cursors.
   *
   */

  PROCEDURE create_organization (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    x_return_status                    OUT    NOCOPY VARCHAR2,
    x_msg_count                        OUT    NOCOPY NUMBER,
    x_msg_data                         OUT    NOCOPY VARCHAR2,
    x_party_id                         OUT    NOCOPY NUMBER,
    x_party_number                     OUT    NOCOPY VARCHAR2,
    x_profile_id                       OUT    NOCOPY NUMBER
  ) IS

  BEGIN

    create_organization (
      p_init_msg_list             => p_init_msg_list,
      p_organization_rec          => p_organization_rec,
      p_party_usage_code          => null,
      x_return_status             => x_return_status,
      x_msg_count                 => x_msg_count,
      x_msg_data                  => x_msg_data,
      x_party_id                  => x_party_id,
      x_party_number              => x_party_number,
      x_profile_id                => x_profile_id
    );

  END create_organization;

  /**
   * PROCEDURE update_organization
   *
   * DESCRIPTION
   *     Updates organization.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     HZ_BUSINESS_EVENT_V2PVT.update_organization_event
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_organization_rec   Organization record.
   *   IN/OUT:
   *     p_party_object_version_number  Used for locking the being updated record.
   *   OUT:
   *     x_profile_id         Organization profile ID.
   *     x_return_status      Return status after the call. The status can
   *                          be fnd_api.g_ret_sts_success (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *   26-NOV-2001   Joe del Callar      Bug 2117973: modified to conform to
   *                                     PL/SQL coding standards.
   *                                     Changed select...intos into cursors.
   *   09-03-2002    Jyoti Pandey        Added Data security Functionality
   *
   *   30-06-2010    Sudhir Gokavarapu   Bug9735521 - When Actual Content Source is NULL
   *                                     then 'USER_ENTERED' is assigned. 
   */

  PROCEDURE update_organization (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    p_party_object_version_number      IN OUT NOCOPY NUMBER,
    x_profile_id                       OUT NOCOPY    NUMBER,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_api_name                         CONSTANT VARCHAR2(30) := 'update_organization';
    l_organization_rec                 ORGANIZATION_REC_TYPE := p_organization_rec;
    l_old_organization_rec             ORGANIZATION_REC_TYPE;
    l_data_source_from                 VARCHAR2(30);
    l_context                          VARCHAR2(30);
    l_create_update_flag               VARCHAR2(1);

    dss_return_status VARCHAR2(1) := 'F';
    dss_msg_count     NUMBER := 0;
    dss_msg_data      VARCHAR2(2000):= null;
    l_test_security   VARCHAR2(1):= 'F';
    l_debug_prefix                     VARCHAR2(30) := '';
/**
    CURSOR c_orgchk IS
      SELECT 1
      FROM   hz_parties hp
      WHERE  hp.party_id = l_organization_rec.party_rec.party_id
      AND    hp.party_type = 'ORGANIZATION';
**/

  BEGIN
    --Standard start of API savepoint
    SAVEPOINT update_organization;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_organization (+)');
    END IF;
    */

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'update_organization (+)',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    
    --Bug9735521 - When Actual Content Source is NULL then 'USER_ENTERED' is assigned. 
    IF l_organization_rec.actual_content_source IS NULL THEN
          l_organization_rec.actual_content_source := 'USER_ENTERED';
            IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
               hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Actual Content Source is NULL so USER_ENTERED is assigned.',
                                      p_msg_level=>fnd_log.level_procedure);
            END IF;
    END IF;

    -- initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    -- initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

/**
    get_organization_rec is checking if the organization party has been
    passed in.

    -- make sure ORGANIZATION party has been passed in
    OPEN c_orgchk;
    FETCH c_orgchk INTO l_count;
    IF c_orgchk%NOTFOUND THEN
      CLOSE c_orgchk;
      fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
      fnd_message.set_token('RECORD', 'organization');
      fnd_message.set_token('VALUE',TO_CHAR(l_organization_rec.party_rec.party_id));
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;
    CLOSE c_orgchk;
**/

    IF (l_organization_rec.party_rec.orig_system is not null
         and l_organization_rec.party_rec.orig_system <>fnd_api.g_miss_char)
       and (l_organization_rec.party_rec.orig_system_reference is not null
         and l_organization_rec.party_rec.orig_system_reference <>fnd_api.g_miss_char)
       and (l_organization_rec.party_rec.party_id = FND_API.G_MISS_NUM or l_organization_rec.party_rec.party_id is null) THEN

        hz_orig_system_ref_pub.get_owner_table_id
                        (p_orig_system => l_organization_rec.party_rec.orig_system,
                        p_orig_system_reference => l_organization_rec.party_rec.orig_system_reference,
                        p_owner_table_name => 'HZ_PARTIES',
                        x_owner_table_id => l_organization_rec.party_rec.party_id,
                        x_return_status => x_return_status);

            IF x_return_status <> fnd_api.g_ret_sts_success THEN
                RAISE FND_API.G_EXC_ERROR;
            END IF;
      END IF;


    -- cache if mix-n-match is enabled

    -- IF g_org_mixnmatch_enabled IS NULL THEN
    HZ_MIXNM_UTILITY.LoadDataSources(
      'HZ_ORGANIZATION_PROFILES', g_org_entity_attr_id,
      g_org_mixnmatch_enabled, g_org_selected_datasources);
    -- END IF;

    -- Get old records. Will be used by business event system.
    get_organization_rec (
      p_party_id                     => l_organization_rec.party_rec.party_id,
      p_content_source_type          => HZ_MIXNM_UTILITY.FindDataSource(
                                          p_content_source_type           => l_organization_rec.content_source_type,
                                          p_actual_content_source         => l_organization_rec.actual_content_source,
                                          p_def_actual_content_source     => G_SST_SOURCE_TYPE,
                                          x_data_source_from              => l_data_source_from ),
      x_organization_rec             => l_old_organization_rec,
      x_return_status                => x_return_status,
      x_msg_count                    => x_msg_count,
      x_msg_data                     => x_msg_data);

    IF x_return_status = fnd_api.g_ret_sts_error THEN
      RAISE fnd_api.g_exc_error;
    ELSIF x_return_status = fnd_api.g_ret_sts_unexp_error THEN
      RAISE fnd_api.g_exc_unexpected_error;
    END IF;

    --- Bug 2486394 Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance.
    --
    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'UPDATE',
                  p_db_object_name     => 'HZ_PARTIES',
                  p_instance_pk1_value => l_organization_rec.party_rec.party_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
         --
         -- Bug 3835601: replaced the message with a more user friendly message
         --
         FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_UPDATE_PRIVILEGE');
         FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                               hz_dss_util_pub.get_display_name(null, 'ORGANIZATION'));
         FND_MSG_PUB.ADD;
         RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- call to business logic.
    do_update_party(
      p_party_type                   => 'ORGANIZATION',
      p_organization_rec             => l_organization_rec,
      p_old_organization_rec         => l_old_organization_rec,
      p_party_object_version_number  => p_party_object_version_number,
      x_profile_id                   => x_profile_id,
      x_return_status                => x_return_status,
      p_person_rec                   => G_MISS_PERSON_REC,
      p_group_rec                    => G_MISS_GROUP_REC );


    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Before the Supplier Denorm Call',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    AP_TCA_SUPPLIER_SYNC_PKG.SYNC_Supplier(x_return_status => x_return_status,
                                           x_msg_count     => x_msg_count,
                                           x_msg_data      => x_msg_data,
                                           x_party_id      => l_organization_rec.party_rec.party_id);

    IF x_return_status = fnd_api.g_ret_sts_error THEN
      RAISE fnd_api.g_exc_error;
    ELSIF x_return_status = fnd_api.g_ret_sts_unexp_error THEN
      RAISE fnd_api.g_exc_unexpected_error;
    END IF;

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'After the Supplier Denorm Call',
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF l_old_organization_rec.actual_content_source IN
      (G_MISS_CONTENT_SOURCE_TYPE, G_SST_SOURCE_TYPE)
    THEN
       -- Bug 3868940
        BEGIN
        SELECT 'U' INTO l_create_update_flag
        FROM hz_credit_ratings
        WHERE party_id = p_organization_rec.party_rec.party_id
        AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
        AND ROWNUM = 1;
        l_organization_rec.created_by_module:=NULL;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_create_update_flag := 'C';
          l_organization_rec.created_by_module:=l_old_organization_rec.created_by_module;
        END;

        populate_credit_rating(
        p_create_update_flag           => l_create_update_flag,
        p_organization_rec             => l_organization_rec,
        x_return_status                => x_return_status );

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE fnd_api.g_exc_error;
      END IF;
    END IF;


    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

    -- Debug info.
    /*IF g_debug THEN
      hz_utility_v2pub.debug_return_messages (
        x_msg_count, x_msg_data, 'WARNING');
      hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_organization (-)');
    END IF;
    */
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'update_organization (-)',
                                p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_organization;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_organization (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_organization (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_organization;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'UNEXPECTED ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_organization (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_organization (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_organization;

      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

      -- Debug info.
      /*IF g_debug THEN
        hz_utility_v2pub.debug_return_messages (
          x_msg_count, x_msg_data, 'SQL ERROR');
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'update_organization (-)');
      END IF;
      */
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_organization (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END update_organization;

  /**
   * PROCEDURE get_organization_rec
   *
   * DESCRIPTION
   *     Gets organization record.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_organization_profiles_pkg.Select_Row
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_party_id           Party ID.
   *     p_content_source_type Content source type.
   *   IN/OUT:
   *   OUT:
   *     x_organization_rec   Returned organization record.
   *     x_return_status      Return status after the call. The status can
   *                          be fnd_api.g_ret_sts_success (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *   26-NOV-2001   Joe del Callar      o Bug 2116225: modified for
   *                                       consolidated bank support.
   *                                       Bug 2117973: modified to conform to
   *                                       PL/SQL coding standards.
   *                                       Changed select...intos into cursors.
   *
   */

  PROCEDURE get_organization_rec (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_party_id                         IN     NUMBER,
    p_content_source_type              IN     VARCHAR2 := g_miss_content_source_type,
    x_organization_rec                 OUT    NOCOPY ORGANIZATION_REC_TYPE,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_api_name                         CONSTANT VARCHAR2(30) := 'get_organization_rec';

    l_profile_id                       NUMBER;
    l_party_id                         NUMBER;
    l_effective_start_date             DATE;
    l_effective_end_date               DATE;
    
    -- Bug 2116225: added these local dummy variables to fetch the bank data.
    l_bank_code                        VARCHAR2(30) := NULL;
    l_branch_code                      VARCHAR2(30) := NULL;
    l_bank_or_branch_number            VARCHAR2(60) := NULL;
    l_debug_prefix                     VARCHAR2(30) := '';

    CURSOR c_org_ue IS
      SELECT NVL(org2.organization_profile_id,org1.organization_profile_id)
      FROM
        hz_organization_profiles org1,
        (SELECT organization_profile_id, party_id
         FROM hz_organization_profiles
         WHERE party_id = p_party_id
         AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
         AND effective_end_date IS NULL) org2
      WHERE org1.party_id = p_party_id
      AND org1.actual_content_source = 'SST'
      AND org1.effective_end_date IS NULL
      AND org1.party_id = org2.party_id (+);

    CURSOR c_org IS
      SELECT organization_profile_id
      FROM hz_organization_profiles
      WHERE party_id = p_party_id
      AND actual_content_source = p_content_source_type
      AND effective_end_date IS NULL;

    l_error                            BOOLEAN := FALSE;
    l_context                          VARCHAR2(30);

  BEGIN

    --Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    --Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

    --Check whether primary key has been passed in.
    IF p_party_id IS NULL OR
       p_party_id = fnd_api.g_miss_num
    THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'p_party_id');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    IF p_content_source_type IS NULL OR
       p_content_source_type = fnd_api.g_miss_char
    THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'p_content_source_type');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    IF p_content_source_type = G_MISS_CONTENT_SOURCE_TYPE THEN
      OPEN c_org_ue;
      FETCH c_org_ue INTO l_profile_id;

      IF c_org_ue%NOTFOUND THEN
        l_error := TRUE;
      END IF;
      CLOSE c_org_ue;
    ELSE
      OPEN c_org;
      FETCH c_org INTO l_profile_id;

      IF c_org%NOTFOUND THEN
        l_error := TRUE;
      END IF;
      CLOSE c_org;
    END IF;

    IF l_error THEN
      fnd_message.set_name('AR', 'HZ_NO_PROFILE_PRESENT');
      fnd_message.set_token('PARTY_ID', TO_CHAR(p_party_id));
      fnd_message.set_token('CONTENT_SOURCE_TYPE', p_content_source_type);
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;
    

    hz_organization_profiles_pkg.Select_Row (
      x_organization_profile_id      => l_profile_id,
      x_party_id                     => l_party_id,
      x_organization_name            => x_organization_rec.organization_name,
      x_attribute_category           => x_organization_rec.attribute_category,
      x_attribute1                   => x_organization_rec.attribute1,
      x_attribute2                   => x_organization_rec.attribute2,
      x_attribute3                   => x_organization_rec.attribute3,
      x_attribute4                   => x_organization_rec.attribute4,
      x_attribute5                   => x_organization_rec.attribute5,
      x_attribute6                   => x_organization_rec.attribute6,
      x_attribute7                   => x_organization_rec.attribute7,
      x_attribute8                   => x_organization_rec.attribute8,
      x_attribute9                   => x_organization_rec.attribute9,
      x_attribute10                  => x_organization_rec.attribute10,
      x_attribute11                  => x_organization_rec.attribute11,
      x_attribute12                  => x_organization_rec.attribute12,
      x_attribute13                  => x_organization_rec.attribute13,
      x_attribute14                  => x_organization_rec.attribute14,
      x_attribute15                  => x_organization_rec.attribute15,
      x_attribute16                  => x_organization_rec.attribute16,
      x_attribute17                  => x_organization_rec.attribute17,
      x_attribute18                  => x_organization_rec.attribute18,
      x_attribute19                  => x_organization_rec.attribute19,
      x_attribute20                  => x_organization_rec.attribute20,
      x_enquiry_duns                 => x_organization_rec.enquiry_duns,
      x_ceo_name                     => x_organization_rec.ceo_name,
      x_ceo_title                    => x_organization_rec.ceo_title,
      x_principal_name               => x_organization_rec.principal_name,
      x_principal_title              => x_organization_rec.principal_title,
      x_legal_status                 => x_organization_rec.legal_status,
      x_control_yr                   => x_organization_rec.control_yr,
      x_employees_total              => x_organization_rec.employees_total,
      x_hq_branch_ind                => x_organization_rec.hq_branch_ind,
      x_branch_flag                  => x_organization_rec.branch_flag,
      x_oob_ind                      => x_organization_rec.oob_ind,
      x_line_of_business             => x_organization_rec.line_of_business,
      x_cong_dist_code               => x_organization_rec.cong_dist_code,
      x_sic_code                     => x_organization_rec.sic_code,
      x_import_ind                   => x_organization_rec.import_ind,
      x_export_ind                   => x_organization_rec.export_ind,
      x_labor_surplus_ind            => x_organization_rec.labor_surplus_ind,
      x_debarment_ind                => x_organization_rec.debarment_ind,
      x_minority_owned_ind           => x_organization_rec.minority_owned_ind,
      x_minority_owned_type          => x_organization_rec.minority_owned_type,
      x_woman_owned_ind              => x_organization_rec.woman_owned_ind,
      x_disadv_8a_ind                => x_organization_rec.disadv_8a_ind,
      x_small_bus_ind                => x_organization_rec.small_bus_ind,
      x_rent_own_ind                 => x_organization_rec.rent_own_ind,
      x_debarments_count             => x_organization_rec.debarments_count,
      x_debarments_date              => x_organization_rec.debarments_date,
      x_failure_score                => x_organization_rec.failure_score,
      x_failure_score_override_code  => x_organization_rec.failure_score_override_code,
      x_failure_score_commentary     => x_organization_rec.failure_score_commentary,
      x_global_failure_score         => x_organization_rec.global_failure_score,
      x_db_rating                    => x_organization_rec.db_rating,
      x_credit_score                 => x_organization_rec.credit_score,
      x_credit_score_commentary      => x_organization_rec.credit_score_commentary,
      x_paydex_score                 => x_organization_rec.paydex_score,
      x_paydex_three_months_ago      => x_organization_rec.paydex_three_months_ago,
      x_paydex_norm                  => x_organization_rec.paydex_norm,
      x_best_time_contact_begin      => x_organization_rec.best_time_contact_begin,
      x_best_time_contact_end        => x_organization_rec.best_time_contact_end,
      x_organization_name_phonetic   => x_organization_rec.organization_name_phonetic,
      x_tax_reference                => x_organization_rec.tax_reference,
      x_gsa_indicator_flag           => x_organization_rec.gsa_indicator_flag,
      x_jgzz_fiscal_code             => x_organization_rec.jgzz_fiscal_code,
      x_analysis_fy                  => x_organization_rec.analysis_fy,
      x_fiscal_yearend_month         => x_organization_rec.fiscal_yearend_month,
      x_curr_fy_potential_revenue    => x_organization_rec.curr_fy_potential_revenue,
      x_next_fy_potential_revenue    => x_organization_rec.next_fy_potential_revenue,
      x_year_established             => x_organization_rec.year_established,
      x_mission_statement            => x_organization_rec.mission_statement,
      x_organization_type            => x_organization_rec.organization_type,
      x_business_scope               => x_organization_rec.business_scope,
      x_corporation_class            => x_organization_rec.corporation_class,
      x_known_as                     => x_organization_rec.known_as,
      x_local_bus_iden_type          => x_organization_rec.local_bus_iden_type,
      x_local_bus_identifier         => x_organization_rec.local_bus_identifier,
      x_pref_functional_currency     => x_organization_rec.pref_functional_currency,
      x_registration_type            => x_organization_rec.registration_type,
      x_total_employees_text         => x_organization_rec.total_employees_text,
      x_total_employees_ind          => x_organization_rec.total_employees_ind,
      x_total_emp_est_ind            => x_organization_rec.total_emp_est_ind,
      x_total_emp_min_ind            => x_organization_rec.total_emp_min_ind,
      x_parent_sub_ind               => x_organization_rec.parent_sub_ind,
      x_incorp_year                  => x_organization_rec.incorp_year,
      x_content_source_type          => x_organization_rec.content_source_type,
      x_content_source_number        => x_organization_rec.content_source_number,
      x_effective_start_date         => l_effective_start_date,
      x_effective_end_date           => l_effective_end_date,
      x_sic_code_type                => x_organization_rec.sic_code_type,
      x_public_private_ownership     => x_organization_rec.public_private_ownership_flag,
      x_local_activity_code_type     => x_organization_rec.local_activity_code_type,
      x_local_activity_code          => x_organization_rec.local_activity_code,
      x_emp_at_primary_adr           => x_organization_rec.emp_at_primary_adr,
      x_emp_at_primary_adr_text      => x_organization_rec.emp_at_primary_adr_text,
      x_emp_at_primary_adr_est_ind   => x_organization_rec.emp_at_primary_adr_est_ind,
      x_emp_at_primary_adr_min_ind   => x_organization_rec.emp_at_primary_adr_min_ind,
      x_internal_flag                => x_organization_rec.internal_flag,
      x_high_credit                  => x_organization_rec.high_credit,
      x_avg_high_credit              => x_organization_rec.avg_high_credit,
      x_total_payments               => x_organization_rec.total_payments,
      x_known_as2                    => x_organization_rec.known_as2,
      x_known_as3                    => x_organization_rec.known_as3,
      x_known_as4                    => x_organization_rec.known_as4,
      x_known_as5                    => x_organization_rec.known_as5,
      x_credit_score_class           => x_organization_rec.credit_score_class,
      x_credit_score_natl_percentile => x_organization_rec.credit_score_natl_percentile,
      x_credit_score_incd_default    => x_organization_rec.credit_score_incd_default,
      x_credit_score_age             => x_organization_rec.credit_score_age,
      x_credit_score_date            => x_organization_rec.credit_score_date,
      x_failure_score_class          => x_organization_rec.failure_score_class,
      x_failure_score_incd_default   => x_organization_rec.failure_score_incd_default,
      x_failure_score_age            => x_organization_rec.failure_score_age,
      x_failure_score_date           => x_organization_rec.failure_score_date,
      x_failure_score_commentary2    => x_organization_rec.failure_score_commentary2,
      x_failure_score_commentary3    => x_organization_rec.failure_score_commentary3,
      x_failure_score_commentary4    => x_organization_rec.failure_score_commentary4,
      x_failure_score_commentary5    => x_organization_rec.failure_score_commentary5,
      x_failure_score_commentary6    => x_organization_rec.failure_score_commentary6,
      x_failure_score_commentary7    => x_organization_rec.failure_score_commentary7,
      x_failure_score_commentary8    => x_organization_rec.failure_score_commentary8,
      x_failure_score_commentary9    => x_organization_rec.failure_score_commentary9,
      x_failure_score_commentary10   => x_organization_rec.failure_score_commentary10,
      x_credit_score_commentary2     => x_organization_rec.credit_score_commentary2,
      x_credit_score_commentary3     => x_organization_rec.credit_score_commentary3,
      x_credit_score_commentary4     => x_organization_rec.credit_score_commentary4,
      x_credit_score_commentary5     => x_organization_rec.credit_score_commentary5,
      x_credit_score_commentary6     => x_organization_rec.credit_score_commentary6,
      x_credit_score_commentary7     => x_organization_rec.credit_score_commentary7,
      x_credit_score_commentary8     => x_organization_rec.credit_score_commentary8,
      x_credit_score_commentary9     => x_organization_rec.credit_score_commentary9,
      x_credit_score_commentary10    => x_organization_rec.credit_score_commentary10,
      x_maximum_credit_recomm        => x_organization_rec.maximum_credit_recommendation,
      x_maximum_credit_currency_code => x_organization_rec.maximum_credit_currency_code,
      x_displayed_duns_party_id      => x_organization_rec.displayed_duns_party_id,
      x_failure_score_natnl_perc     => x_organization_rec.failure_score_natnl_percentile,
      x_duns_number_c                => x_organization_rec.duns_number_c,
      x_bank_or_branch_number        => l_bank_or_branch_number,
      x_bank_code                    => l_bank_code,
      x_branch_code                  => l_branch_code,
      x_created_by_module            => x_organization_rec.created_by_module,
      x_application_id               => x_organization_rec.application_id,
      x_do_not_confuse_with          => x_organization_rec.do_not_confuse_with,
      x_actual_content_source        => x_organization_rec.actual_content_source,
      x_home_country                 => x_organization_rec.home_country
    );

    --Bug9648645
    --Assigning NULL values to Global bank related varaibles.
      g_bank_code              := NULL;
      g_branch_code            := NULL;
      g_bank_or_branch_number  := NULL;

    --When any one of bank related variable are not null then
    --assigning fetched values to global variables.
    --These values will be used in create_org_profile API while creating new profile record.
    IF l_bank_or_branch_number IS NOT NULL OR l_bank_code IS NOT NULL OR l_branch_code IS NOT NULL THEN
      g_bank_or_branch_number := l_bank_or_branch_number;
      g_bank_code             := l_bank_code;
      g_branch_code           := l_branch_code;
      g_party_id              := l_party_id;
      
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'Bank related variables having values.',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
      
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'g_bank_or_branch_number : '||g_bank_or_branch_number
                                                                  ||' g_bank_code : '||g_bank_code
                                                                  ||' g_branch_code : '||g_branch_code
                                                                  ||' g_party_id : '||g_party_id,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
      
    END IF;

    -- Get the party record component of organization
    get_party_rec(
      p_party_id                     => p_party_id,
      x_party_rec                    => x_organization_rec.party_rec,
      x_return_status                => x_return_status,
      x_msg_count                    => x_msg_count,
      x_msg_data                     => x_msg_data);

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN fnd_api.g_exc_unexpected_error THEN
      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN OTHERS THEN
      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

  END get_organization_rec;

  /**
   * PROCEDURE get_person_rec
   *
   * DESCRIPTION
   *     Gets person record.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *     hz_person_profiles_pkg.Select_Row
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list       Initialize message stack if it is set to
   *                           FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_party_id            Party ID.
   *     p_content_source_type Content source type.
   *   IN/OUT:
   *   OUT:
   *     x_person_rec          Returned person record.
   *     x_return_status       Return status after the call. The status can
   *                           be fnd_api.g_ret_sts_success (success),
   *                           fnd_api.g_ret_sts_error (error),
   *                           fnd_api.g_ret_sts_unexp_error (unexpected error)
   *     x_msg_count           Number of messages in message stack.
   *     x_msg_data            Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *
   */

  PROCEDURE get_person_rec (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_party_id                         IN     NUMBER,
    p_content_source_type              IN     VARCHAR2 := G_MISS_CONTENT_SOURCE_TYPE,
    x_person_rec                       OUT    NOCOPY PERSON_REC_TYPE,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_api_name                         CONSTANT VARCHAR2(30) := 'get_person_profile_rec';

    l_profile_id                       NUMBER;
    l_party_id                         NUMBER;
    l_effective_start_date             DATE;
    l_effective_end_date               DATE;
    l_debug_prefix                     VARCHAR2(30) := '';

    CURSOR c_per_ue IS
      SELECT NVL(per2.person_profile_id,per1.person_profile_id)
      FROM
        hz_person_profiles per1,
        (SELECT person_profile_id, party_id
         FROM hz_person_profiles
         WHERE party_id = p_party_id
         AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
         AND effective_end_date IS NULL) per2
      WHERE per1.party_id = p_party_id
      AND per1.actual_content_source = 'SST'
      AND per1.effective_end_date IS NULL
      AND per1.party_id = per2.party_id (+);

    CURSOR c_per IS
      SELECT person_profile_id
      FROM hz_person_profiles
      WHERE party_id = p_party_id
      AND actual_content_source = p_content_source_type
      AND effective_end_date IS NULL;

    l_error                            BOOLEAN := FALSE;
    l_context                          VARCHAR2(30);

  BEGIN

    --Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    --Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    -- enable policy function if it is disabled.

    l_context := NVL(SYS_CONTEXT('hz', g_apps_context), 'N');
    IF l_context = 'N' THEN
      hz_common_pub.disable_cont_source_security;
    END IF;

    --Check whether primary key has been passed in.
    IF p_party_id IS NULL OR
       p_party_id = fnd_api.g_miss_num
    THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'p_party_id');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    IF p_content_source_type IS NULL OR
       p_content_source_type = FND_API.G_MISS_CHAR
    THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'p_content_source_type');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    IF p_content_source_type = G_MISS_CONTENT_SOURCE_TYPE THEN
      OPEN c_per_ue;
      FETCH c_per_ue INTO l_profile_id;

      IF c_per_ue%NOTFOUND THEN
        l_error := TRUE;
      END IF;
      CLOSE c_per_ue;
    ELSE
      OPEN c_per;
      FETCH c_per INTO l_profile_id;

      IF c_per%NOTFOUND THEN
        l_error := TRUE;
      END IF;
      CLOSE c_per;
    END IF;

    IF l_error THEN
      fnd_message.set_name('AR', 'HZ_NO_PROFILE_PRESENT');
      fnd_message.set_token('PARTY_ID', TO_CHAR(p_party_id));
      fnd_message.set_token('CONTENT_SOURCE_TYPE', p_content_source_type);
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    HZ_person_profiles_pkg.Select_Row (
      x_person_profile_id            => l_profile_id,
      x_party_id                     => l_party_id,
      x_attribute_category           => x_person_rec.attribute_category,
      x_attribute1                   => x_person_rec.attribute1,
      x_attribute2                   => x_person_rec.attribute2,
      x_attribute3                   => x_person_rec.attribute3,
      x_attribute4                   => x_person_rec.attribute4,
      x_attribute5                   => x_person_rec.attribute5,
      x_attribute6                   => x_person_rec.attribute6,
      x_attribute7                   => x_person_rec.attribute7,
      x_attribute8                   => x_person_rec.attribute8,
      x_attribute9                   => x_person_rec.attribute9,
      x_attribute10                  => x_person_rec.attribute10,
      x_attribute11                  => x_person_rec.attribute11,
      x_attribute12                  => x_person_rec.attribute12,
      x_attribute13                  => x_person_rec.attribute13,
      x_attribute14                  => x_person_rec.attribute14,
      x_attribute15                  => x_person_rec.attribute15,
      x_attribute16                  => x_person_rec.attribute16,
      x_attribute17                  => x_person_rec.attribute17,
      x_attribute18                  => x_person_rec.attribute18,
      x_attribute19                  => x_person_rec.attribute19,
      x_attribute20                  => x_person_rec.attribute20,
      x_person_pre_name_adjunct      => x_person_rec.person_pre_name_adjunct,
      x_person_first_name            => x_person_rec.person_first_name,
      x_person_middle_name           => x_person_rec.person_middle_name,
      x_person_last_name             => x_person_rec.person_last_name,
      x_person_name_suffix           => x_person_rec.person_name_suffix,
      x_person_title                 => x_person_rec.person_title,
      x_person_academic_title        => x_person_rec.person_academic_title,
      x_person_previous_last_name    => x_person_rec.person_previous_last_name,
      x_person_initials              => x_person_rec.person_initials,
      x_known_as                     => x_person_rec.known_as,
      x_person_name_phonetic         => x_person_rec.person_name_phonetic,
      x_person_first_name_phonetic   => x_person_rec.person_first_name_phonetic,
      x_person_last_name_phonetic    => x_person_rec.person_last_name_phonetic,
      x_tax_reference                => x_person_rec.tax_reference,
      x_jgzz_fiscal_code             => x_person_rec.jgzz_fiscal_code,
      x_person_iden_type             => x_person_rec.person_iden_type,
      x_person_identifier            => x_person_rec.person_identifier,
      x_date_of_birth                => x_person_rec.date_of_birth,
      x_place_of_birth               => x_person_rec.place_of_birth,
      x_date_of_death                => x_person_rec.date_of_death,
      x_deceased_flag                 => x_person_rec.deceased_flag,
      x_gender                       => x_person_rec.gender,
      x_declared_ethnicity           => x_person_rec.declared_ethnicity,
      x_marital_status               => x_person_rec.marital_status,
      x_marital_status_eff_date      => x_person_rec.marital_status_effective_date,
      x_personal_income              => x_person_rec.personal_income,
      x_head_of_household_flag       => x_person_rec.head_of_household_flag,
      x_household_income             => x_person_rec.household_income,
      x_household_size               => x_person_rec.household_size,
      x_rent_own_ind                 => x_person_rec.rent_own_ind,
      x_last_known_gps               => x_person_rec.last_known_gps,
      x_effective_start_date         => l_effective_start_date,
      x_effective_end_date           => l_effective_end_date,
      x_content_source_type          => x_person_rec.content_source_type,
      x_internal_flag                => x_person_rec.internal_flag,
      x_known_as2                    => x_person_rec.known_as2,
      x_known_as3                    => x_person_rec.known_as3,
      x_known_as4                    => x_person_rec.known_as4,
      x_known_as5                    => x_person_rec.known_as5,
      x_middle_name_phonetic         => x_person_rec.middle_name_phonetic,
      x_created_by_module            => x_person_rec.created_by_module,
      x_application_id               => x_person_rec.application_id,
      x_actual_content_source        => x_person_rec.actual_content_source
    );

    -- Get the party record component of person
    get_party_rec(
      p_party_id                     => p_party_id,
      x_party_rec                    => x_person_rec.party_rec,
      x_return_status                => x_return_status,
      x_msg_count                    => x_msg_count,
      x_msg_data                     => x_msg_data);

    -- enable policy function if it was enabled before calling
    -- this procedure.

    IF l_context = 'N' THEN
      hz_common_pub.enable_cont_source_security;
    END IF;

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN fnd_api.g_exc_unexpected_error THEN
      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN OTHERS THEN
      IF l_context = 'N' THEN
        hz_common_pub.enable_cont_source_security;
      END IF;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

  END get_person_rec;

  /**
   * PROCEDURE get_group_rec
   *
   * DESCRIPTION
   *     Gets group record.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_party_id           Party ID.
   *   IN/OUT:
   *   OUT:
   *     x_group_rec          Returned group record.
   *     x_return_status      Return status after the call. The status can
   *                          be fnd_api.g_ret_sts_success (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   04-25-2002    Jianying Huang    o Created.
   *
   */

  PROCEDURE get_group_rec (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_party_id                         IN     NUMBER,
    x_group_rec                        OUT    NOCOPY GROUP_REC_TYPE,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_api_name                         CONSTANT VARCHAR2(30) := 'get_group_rec';

    x_party_dup_rec                    PARTY_DUP_REC_TYPE;
    l_party_name                       HZ_PARTIES.PARTY_NAME%TYPE;
    l_party_type                       HZ_PARTIES.PARTY_TYPE%TYPE;
    l_customer_key                     HZ_PARTIES.CUSTOMER_KEY%TYPE;
    l_country                          HZ_PARTIES.COUNTRY%TYPE;
    l_address1                         HZ_PARTIES.ADDRESS1%TYPE;
    l_address2                         HZ_PARTIES.ADDRESS2%TYPE;
    l_address3                         HZ_PARTIES.ADDRESS3%TYPE;
    l_address4                         HZ_PARTIES.ADDRESS4%TYPE;
    l_city                             HZ_PARTIES.CITY%TYPE;
    l_state                            HZ_PARTIES.STATE%TYPE;
    l_postal_code                      HZ_PARTIES.POSTAL_CODE%TYPE;
    l_province                         HZ_PARTIES.PROVINCE%TYPE;
    l_county                           HZ_PARTIES.COUNTY%TYPE;
    l_url                              HZ_PARTIES.URL%TYPE;
    l_email_address                    HZ_PARTIES.EMAIL_ADDRESS%TYPE;
    l_language_name                    HZ_PARTIES.LANGUAGE_NAME%TYPE;
    l_debug_prefix                     VARCHAR2(30) := '';

    CURSOR c_group IS
      SELECT 'Y'
      FROM hz_parties
      WHERE party_id = p_party_id
      AND party_type = 'GROUP';

    l_dummy                            VARCHAR2(1);
    l_error                            BOOLEAN := FALSE;

  BEGIN

    --Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    --Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    --Check whether primary key has been passed in.
    IF p_party_id IS NULL OR
       p_party_id = fnd_api.g_miss_num
    THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'party_id');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    OPEN c_group;
    FETCH c_group INTO l_dummy;
    IF c_group%NOTFOUND THEN
      l_error := TRUE;
    END IF;
    CLOSE c_group;

    IF l_error THEN
      fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
      fnd_message.set_token('RECORD', 'group');
      fnd_message.set_token('VALUE', to_char(p_party_id));
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    x_group_rec.party_rec.party_id := p_party_id;

    hz_parties_pkg.Select_Row (
      x_party_id                     => x_group_rec.party_rec.party_id,
      x_party_number                 => x_group_rec.party_rec.party_number,
      x_party_name                   => x_group_rec.group_name,
      x_party_type                   => l_party_type,
      x_validated_flag               => x_group_rec.party_rec.validated_flag,
      x_attribute_category           => x_group_rec.party_rec.attribute_category,
      x_attribute1                   => x_group_rec.party_rec.attribute1,
      x_attribute2                   => x_group_rec.party_rec.attribute2,
      x_attribute3                   => x_group_rec.party_rec.attribute3,
      x_attribute4                   => x_group_rec.party_rec.attribute4,
      x_attribute5                   => x_group_rec.party_rec.attribute5,
      x_attribute6                   => x_group_rec.party_rec.attribute6,
      x_attribute7                   => x_group_rec.party_rec.attribute7,
      x_attribute8                   => x_group_rec.party_rec.attribute8,
      x_attribute9                   => x_group_rec.party_rec.attribute9,
      x_attribute10                  => x_group_rec.party_rec.attribute10,
      x_attribute11                  => x_group_rec.party_rec.attribute11,
      x_attribute12                  => x_group_rec.party_rec.attribute12,
      x_attribute13                  => x_group_rec.party_rec.attribute13,
      x_attribute14                  => x_group_rec.party_rec.attribute14,
      x_attribute15                  => x_group_rec.party_rec.attribute15,
      x_attribute16                  => x_group_rec.party_rec.attribute16,
      x_attribute17                  => x_group_rec.party_rec.attribute17,
      x_attribute18                  => x_group_rec.party_rec.attribute18,
      x_attribute19                  => x_group_rec.party_rec.attribute19,
      x_attribute20                  => x_group_rec.party_rec.attribute20,
      x_attribute21                  => x_group_rec.party_rec.attribute21,
      x_attribute22                  => x_group_rec.party_rec.attribute22,
      x_attribute23                  => x_group_rec.party_rec.attribute23,
      x_attribute24                  => x_group_rec.party_rec.attribute24,
      x_orig_system_reference        => x_group_rec.party_rec.orig_system_reference,
      x_sic_code                     => x_party_dup_rec.sic_code,
      x_hq_branch_ind                => x_party_dup_rec.hq_branch_ind,
      x_customer_key                 => l_customer_key,
      x_tax_reference                => x_party_dup_rec.tax_reference,
      x_jgzz_fiscal_code             => x_party_dup_rec.jgzz_fiscal_code,
      x_person_pre_name_adjunct      => x_party_dup_rec.pre_name_adjunct,
      x_person_first_name            => x_party_dup_rec.first_name,
      x_person_middle_name           => x_party_dup_rec.middle_name,
      x_person_last_name             => x_party_dup_rec.last_name,
      x_person_name_suffix           => x_party_dup_rec.name_suffix,
      x_person_title                 => x_party_dup_rec.title,
      x_person_academic_title        => x_party_dup_rec.academic_title,
      x_person_previous_last_name    => x_party_dup_rec.previous_last_name,
      x_known_as                     => x_party_dup_rec.known_as,
      x_person_iden_type             => x_party_dup_rec.person_iden_type,
      x_person_identifier            => x_party_dup_rec.person_identifier,
      x_group_type                   => x_group_rec.group_type,
      x_country                      => l_country,
      x_address1                     => l_address1,
      x_address2                     => l_address2,
      x_address3                     => l_address3,
      x_address4                     => l_address4,
      x_city                         => l_city,
      x_postal_code                  => l_postal_code,
      x_state                        => l_state,
      x_province                     => l_province,
      x_status                       => x_group_rec.party_rec.status,
      x_county                       => l_county,
      x_sic_code_type                => x_party_dup_rec.sic_code_type,
      x_url                          => l_url,
      x_email_address                => l_email_address,
      x_analysis_fy                  => x_party_dup_rec.analysis_fy,
      x_fiscal_yearend_month         => x_party_dup_rec.fiscal_yearend_month,
      x_employees_total              => x_party_dup_rec.employees_total,
      x_curr_fy_potential_revenue    => x_party_dup_rec.curr_fy_potential_revenue,
      x_next_fy_potential_revenue    => x_party_dup_rec.next_fy_potential_revenue,
      x_year_established             => x_party_dup_rec.year_established,
      x_gsa_indicator_flag           => x_party_dup_rec.gsa_indicator_flag,
      -- Bug 2467872
      x_mission_statement            => x_group_rec.mission_statement,
      x_organization_name_phonetic   => x_party_dup_rec.organization_name_phonetic,
      x_person_first_name_phonetic   => x_party_dup_rec.person_first_name_phonetic,
      x_person_last_name_phonetic    => x_party_dup_rec.person_last_name_phonetic,
      x_language_name                => l_language_name,
      x_category_code                => x_group_rec.party_rec.category_code,
      x_salutation                   => x_group_rec.party_rec.salutation,
      x_known_as2                    => x_party_dup_rec.known_as2,
      x_known_as3                    => x_party_dup_rec.known_as3,
      x_known_as4                    => x_party_dup_rec.known_as4,
      x_known_as5                    => x_party_dup_rec.known_as5,
      x_duns_number_c                => x_party_dup_rec.duns_number_c,
      x_created_by_module            => x_group_rec.created_by_module,
      x_application_id               => x_group_rec.application_id
    );

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

  END get_group_rec;

  /**
   * PROCEDURE get_party_rec
   *
   * DESCRIPTION
   *     Gets party record.
   *
   * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
   *
   * ARGUMENTS
   *   IN:
   *     p_init_msg_list      Initialize message stack if it is set to
   *                          FND_API.G_TRUE. Default is fnd_api.g_false.
   *     p_party_id           Party ID.
   *   IN/OUT:
   *   OUT:
   *     x_party_rec          Returned party record.
   *     x_return_status      Return status after the call. The status can
   *                          be fnd_api.g_ret_sts_success (success),
   *                          fnd_api.g_ret_sts_error (error),
   *                          fnd_api.g_ret_sts_unexp_error (unexpected error).
   *     x_msg_count          Number of messages in message stack.
   *     x_msg_data           Message text if x_msg_count is 1.
   *
   * NOTES
   *
   * MODIFICATION HISTORY
   *
   *   07-23-2001    Indrajit Sen        o Created.
   *
   */

  PROCEDURE get_party_rec (
    p_init_msg_list                    IN     VARCHAR2 := fnd_api.g_false,
    p_party_id                         IN     NUMBER,
    x_party_rec                        OUT    NOCOPY PARTY_REC_TYPE,
    x_return_status                    OUT NOCOPY    VARCHAR2,
    x_msg_count                        OUT NOCOPY    NUMBER,
    x_msg_data                         OUT NOCOPY    VARCHAR2
  ) IS

    l_api_name                         CONSTANT VARCHAR2(30) := 'get_party_rec';

    x_party_dup_rec                    PARTY_DUP_REC_TYPE;
    l_party_name                       HZ_PARTIES.PARTY_NAME%TYPE;
    l_party_type                       HZ_PARTIES.PARTY_TYPE%TYPE;
    l_customer_key                     HZ_PARTIES.CUSTOMER_KEY%TYPE;
    l_group_type                       HZ_PARTIES.GROUP_TYPE%TYPE;
    l_country                          HZ_PARTIES.COUNTRY%TYPE;
    l_address1                         HZ_PARTIES.ADDRESS1%TYPE;
    l_address2                         HZ_PARTIES.ADDRESS2%TYPE;
    l_address3                         HZ_PARTIES.ADDRESS3%TYPE;
    l_address4                         HZ_PARTIES.ADDRESS4%TYPE;
    l_city                             HZ_PARTIES.CITY%TYPE;
    l_state                            HZ_PARTIES.STATE%TYPE;
    l_postal_code                      HZ_PARTIES.POSTAL_CODE%TYPE;
    l_province                         HZ_PARTIES.PROVINCE%TYPE;
    l_county                           HZ_PARTIES.COUNTY%TYPE;
    l_url                              HZ_PARTIES.URL%TYPE;
    l_email_address                    HZ_PARTIES.EMAIL_ADDRESS%TYPE;
    l_language_name                    HZ_PARTIES.LANGUAGE_NAME%TYPE;
    l_created_by_module                HZ_PARTIES.CREATED_BY_MODULE%TYPE;
    l_application_id                   NUMBER;
    l_debug_prefix                     VARCHAR2(30) := '';
  BEGIN

    --Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    --Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    --Check whether primary key has been passed in.
    IF p_party_id IS NULL OR
       p_party_id = fnd_api.g_miss_num
    THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'party_id');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    x_party_rec.party_id := p_party_id;

    hz_parties_pkg.Select_Row (
      x_party_id                     => x_party_rec.party_id,
      x_party_number                 => x_party_rec.party_number,
      x_party_name                   => l_party_name,
      x_party_type                   => l_party_type,
      x_validated_flag               => x_party_rec.validated_flag,
      x_attribute_category           => x_party_rec.attribute_category,
      x_attribute1                   => x_party_rec.attribute1,
      x_attribute2                   => x_party_rec.attribute2,
      x_attribute3                   => x_party_rec.attribute3,
      x_attribute4                   => x_party_rec.attribute4,
      x_attribute5                   => x_party_rec.attribute5,
      x_attribute6                   => x_party_rec.attribute6,
      x_attribute7                   => x_party_rec.attribute7,
      x_attribute8                   => x_party_rec.attribute8,
      x_attribute9                   => x_party_rec.attribute9,
      x_attribute10                  => x_party_rec.attribute10,
      x_attribute11                  => x_party_rec.attribute11,
      x_attribute12                  => x_party_rec.attribute12,
      x_attribute13                  => x_party_rec.attribute13,
      x_attribute14                  => x_party_rec.attribute14,
      x_attribute15                  => x_party_rec.attribute15,
      x_attribute16                  => x_party_rec.attribute16,
      x_attribute17                  => x_party_rec.attribute17,
      x_attribute18                  => x_party_rec.attribute18,
      x_attribute19                  => x_party_rec.attribute19,
      x_attribute20                  => x_party_rec.attribute20,
      x_attribute21                  => x_party_rec.attribute21,
      x_attribute22                  => x_party_rec.attribute22,
      x_attribute23                  => x_party_rec.attribute23,
      x_attribute24                  => x_party_rec.attribute24,
      x_orig_system_reference        => x_party_rec.orig_system_reference,
      x_sic_code                     => x_party_dup_rec.sic_code,
      x_hq_branch_ind                => x_party_dup_rec.hq_branch_ind,
      x_customer_key                 => l_customer_key,
      x_tax_reference                => x_party_dup_rec.tax_reference,
      x_jgzz_fiscal_code             => x_party_dup_rec.jgzz_fiscal_code,
      x_person_pre_name_adjunct      => x_party_dup_rec.pre_name_adjunct,
      x_person_first_name            => x_party_dup_rec.first_name,
      x_person_middle_name           => x_party_dup_rec.middle_name,
      x_person_last_name             => x_party_dup_rec.last_name,
      x_person_name_suffix           => x_party_dup_rec.name_suffix,
      x_person_title                 => x_party_dup_rec.title,
      x_person_academic_title        => x_party_dup_rec.academic_title,
      x_person_previous_last_name    => x_party_dup_rec.previous_last_name,
      x_known_as                     => x_party_dup_rec.known_as,
      x_person_iden_type             => x_party_dup_rec.person_iden_type,
      x_person_identifier            => x_party_dup_rec.person_identifier,
      x_group_type                   => l_group_type,
      x_country                      => l_country,
      x_address1                     => l_address1,
      x_address2                     => l_address2,
      x_address3                     => l_address3,
      x_address4                     => l_address4,
      x_city                         => l_city,
      x_postal_code                  => l_postal_code,
      x_state                        => l_state,
      x_province                     => l_province,
      x_status                       => x_party_rec.status,
      x_county                       => l_county,
      x_sic_code_type                => x_party_dup_rec.sic_code_type,
      x_url                          => l_url,
      x_email_address                => l_email_address,
      x_analysis_fy                  => x_party_dup_rec.analysis_fy,
      x_fiscal_yearend_month         => x_party_dup_rec.fiscal_yearend_month,
      x_employees_total              => x_party_dup_rec.employees_total,
      x_curr_fy_potential_revenue    => x_party_dup_rec.curr_fy_potential_revenue,
      x_next_fy_potential_revenue    => x_party_dup_rec.next_fy_potential_revenue,
      x_year_established             => x_party_dup_rec.year_established,
      x_gsa_indicator_flag           => x_party_dup_rec.gsa_indicator_flag,
      x_mission_statement            => x_party_dup_rec.mission_statement,
      x_organization_name_phonetic   => x_party_dup_rec.organization_name_phonetic,
      x_person_first_name_phonetic   => x_party_dup_rec.person_first_name_phonetic,
      x_person_last_name_phonetic    => x_party_dup_rec.person_last_name_phonetic,
      x_language_name                => l_language_name,
      x_category_code                => x_party_rec.category_code,
      x_salutation                   => x_party_rec.salutation,
      x_known_as2                    => x_party_dup_rec.known_as2,
      x_known_as3                    => x_party_dup_rec.known_as3,
      x_known_as4                    => x_party_dup_rec.known_as4,
      x_known_as5                    => x_party_dup_rec.known_as5,
      x_duns_number_c                => x_party_dup_rec.duns_number_c,
      x_created_by_module            => l_created_by_module,
      x_application_id               => l_application_id
    );

    --Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded                      => fnd_api.g_false,
      p_count                        => x_msg_count,
      p_data                         => x_msg_data);

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR',SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(
        p_encoded                    => fnd_api.g_false,
        p_count                      => x_msg_count,
        p_data                       => x_msg_data);

  END get_party_rec;

  /**
   * The following code might be removed when we stop supporting those
   * obsolete columns.
   */

  /**
   * insert credit related data to hz_credit_rating
   */

/*  24-Sep-2004     V.Ravichandran     o Bug 3868940 : Defaulted the rated_as_of_date to sysdate
 *                                       while creating a credit_rating in populate_credit_rating()
 *                                       procedure and retained its previous value while updating
 *                                       a credit rating populate_credit_rating procedure.
 *                                       Called HZ_PARTY_INFO_V2PUB.create/update_credit_rating
 *                                       from populate_credit_rating() procedure directly
 *                                       instead of calling the V1 APIs
 *                                       HZ_PARTY_INFO_PUB.create/updating_credit_rating
 *                                       Commented out the procedure org_rec_to_cr_rec.
 */


  PROCEDURE  populate_credit_rating(
    p_create_update_flag               IN     VARCHAR2,
    p_organization_rec                 IN     ORGANIZATION_REC_TYPE,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  ) IS

    l_credit_rating_rec                HZ_PARTY_INFO_V2PUB.credit_rating_rec_type;
    l_last_update_date                 DATE := sysdate;
    l_credit_rating_id                 NUMBER;
    l_rated_as_of_date                 DATE;
    l_exist                            VARCHAR2(1);
    l_msg_count                        NUMBER;
    l_msg_data                         VARCHAR2(2000);
    l_debug_prefix                     VARCHAR2(30) := '';
    l_object_version_number              NUMBER;
BEGIN

   IF p_organization_rec.actual_content_source IN
         (G_MISS_CONTENT_SOURCE_TYPE, G_SST_SOURCE_TYPE) AND
       ( p_create_update_flag = 'C' AND
         NOT(
             ( p_organization_rec.AVG_HIGH_CREDIT is null OR
               p_organization_rec.AVG_HIGH_CREDIT = FND_API.G_MISS_NUM ) AND
             ( p_organization_rec.CREDIT_SCORE is null OR
               p_organization_rec.CREDIT_SCORE = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_AGE is null OR
               p_organization_rec.CREDIT_SCORE_AGE = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.CREDIT_SCORE_CLASS is null OR
               p_organization_rec.CREDIT_SCORE_CLASS = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY2 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY2 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY3 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY3 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY4 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY4 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY5 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY5 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY6 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY6 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY7 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY7 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY8 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY8 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY9 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY9 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_COMMENTARY10 is null OR
               p_organization_rec.CREDIT_SCORE_COMMENTARY10 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.CREDIT_SCORE_DATE is null OR
               p_organization_rec.CREDIT_SCORE_DATE = FND_API.G_MISS_DATE) AND
             ( p_organization_rec.CREDIT_SCORE_INCD_DEFAULT is null OR
               p_organization_rec.CREDIT_SCORE_INCD_DEFAULT = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE is null OR
               p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.DB_RATING is null OR
               p_organization_rec.DB_RATING = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.DEBARMENT_IND is null OR
               p_organization_rec.DEBARMENT_IND = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.DEBARMENTS_COUNT is null OR
               p_organization_rec.DEBARMENTS_COUNT = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.DEBARMENTS_DATE is null OR
               p_organization_rec.DEBARMENTS_DATE = FND_API.G_MISS_DATE) AND
             ( p_organization_rec.HIGH_CREDIT is null OR
               p_organization_rec.HIGH_CREDIT = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE is null OR
               p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION is null OR
               p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.PAYDEX_NORM is null OR
               p_organization_rec.PAYDEX_NORM = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.PAYDEX_SCORE is null OR
               p_organization_rec.PAYDEX_SCORE = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.PAYDEX_THREE_MONTHS_AGO  is null OR
               p_organization_rec.PAYDEX_THREE_MONTHS_AGO  = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE is null OR
               p_organization_rec.FAILURE_SCORE = FND_API.G_MISS_CHAR ) AND
             ( p_organization_rec.FAILURE_SCORE_AGE is null OR
               p_organization_rec.FAILURE_SCORE_AGE = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.FAILURE_SCORE_CLASS is null OR
               p_organization_rec.FAILURE_SCORE_CLASS = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY2 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY2 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY3 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY3 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY4 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY4 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY5 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY5 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY6 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY6 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY7 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY7 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY8 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY8 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY9 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY9 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_COMMENTARY10 is null OR
               p_organization_rec.FAILURE_SCORE_COMMENTARY10 = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.FAILURE_SCORE_DATE is null OR
               p_organization_rec.FAILURE_SCORE_DATE = FND_API.G_MISS_DATE) AND
             ( p_organization_rec.FAILURE_SCORE_INCD_DEFAULT is null OR
               p_organization_rec.FAILURE_SCORE_INCD_DEFAULT = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE is null OR
               p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE = FND_API.G_MISS_NUM) AND
             ( p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE is null OR
               p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE = FND_API.G_MISS_CHAR) AND
             ( p_organization_rec.GLOBAL_FAILURE_SCORE is null OR
               p_organization_rec.GLOBAL_FAILURE_SCORE = FND_API.G_MISS_CHAR)
            ) ) OR
       ( p_create_update_flag = 'U' AND
           (   p_organization_rec.AVG_HIGH_CREDIT is not null OR
            p_organization_rec.CREDIT_SCORE  is not null OR
            p_organization_rec.CREDIT_SCORE_AGE is not null OR
            p_organization_rec.CREDIT_SCORE_CLASS is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY2 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY3 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY4 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY5 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY6 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY7 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY8 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY9 is not null OR
            p_organization_rec.CREDIT_SCORE_COMMENTARY10 is not null OR
            p_organization_rec.CREDIT_SCORE_DATE is not null OR
            p_organization_rec.CREDIT_SCORE_INCD_DEFAULT is not null OR
            p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE is not null OR
            p_organization_rec.DB_RATING is not null OR
            p_organization_rec.DEBARMENT_IND is not null OR
            p_organization_rec.DEBARMENTS_COUNT is not null OR
            p_organization_rec.DEBARMENTS_DATE is not null OR
            p_organization_rec.HIGH_CREDIT is not null OR
            p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE is not null OR
            p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION is not null OR
            p_organization_rec.PAYDEX_NORM is not null OR
            p_organization_rec.PAYDEX_SCORE is not null OR
            p_organization_rec.PAYDEX_THREE_MONTHS_AGO is not null OR
            p_organization_rec.FAILURE_SCORE  is not null OR
            p_organization_rec.FAILURE_SCORE_AGE is not null OR
            p_organization_rec.FAILURE_SCORE_CLASS is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY  is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY2 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY3 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY4 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY5 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY6 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY7 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY8 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY9 is not null OR
            p_organization_rec.FAILURE_SCORE_COMMENTARY10 is not null OR
            p_organization_rec.FAILURE_SCORE_DATE         is not null OR
            p_organization_rec.FAILURE_SCORE_INCD_DEFAULT is not null OR
            p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE is not null OR
            p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE is not null OR
            p_organization_rec.GLOBAL_FAILURE_SCORE
           is not null) )
    THEN
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE  (+)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      l_credit_rating_rec.PARTY_ID :=  p_organization_rec.party_rec.PARTY_ID;
      l_credit_rating_rec.AVG_HIGH_CREDIT :=  p_organization_rec.AVG_HIGH_CREDIT;
      l_credit_rating_rec.CREDIT_SCORE := p_organization_rec.CREDIT_SCORE;
      l_credit_rating_rec.CREDIT_SCORE_AGE := p_organization_rec.CREDIT_SCORE_AGE;
      l_credit_rating_rec.CREDIT_SCORE_CLASS := p_organization_rec.CREDIT_SCORE_CLASS;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY := p_organization_rec.CREDIT_SCORE_COMMENTARY;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY2 := p_organization_rec.CREDIT_SCORE_COMMENTARY2;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY3 := p_organization_rec.CREDIT_SCORE_COMMENTARY3;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY4 := p_organization_rec.CREDIT_SCORE_COMMENTARY4;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY5 := p_organization_rec.CREDIT_SCORE_COMMENTARY5;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY6 := p_organization_rec.CREDIT_SCORE_COMMENTARY6;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY7 := p_organization_rec.CREDIT_SCORE_COMMENTARY7;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY8 := p_organization_rec.CREDIT_SCORE_COMMENTARY8;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY9 := p_organization_rec.CREDIT_SCORE_COMMENTARY9;
      l_credit_rating_rec.CREDIT_SCORE_COMMENTARY10 := p_organization_rec.CREDIT_SCORE_COMMENTARY10;
      l_credit_rating_rec.CREDIT_SCORE_DATE := p_organization_rec.CREDIT_SCORE_DATE;
      l_credit_rating_rec.CREDIT_SCORE_INCD_DEFAULT := p_organization_rec.CREDIT_SCORE_INCD_DEFAULT;
      l_credit_rating_rec.CREDIT_SCORE_NATL_PERCENTILE := p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE;
      l_credit_rating_rec.RATING := p_organization_rec.DB_RATING;
      l_credit_rating_rec.DEBARMENT_IND := p_organization_rec.DEBARMENT_IND;
      l_credit_rating_rec.DEBARMENTS_COUNT := p_organization_rec.DEBARMENTS_COUNT;
      l_credit_rating_rec.DEBARMENTS_DATE := p_organization_rec.DEBARMENTS_DATE;
      l_credit_rating_rec.HIGH_CREDIT := p_organization_rec.HIGH_CREDIT;
      l_credit_rating_rec.MAXIMUM_CREDIT_CURRENCY_CODE := p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE;
      l_credit_rating_rec.MAXIMUM_CREDIT_RCMD := p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION;
      l_credit_rating_rec.PAYDEX_NORM := p_organization_rec.PAYDEX_NORM;
      l_credit_rating_rec.PAYDEX_SCORE := p_organization_rec.PAYDEX_SCORE;
      l_credit_rating_rec.PAYDEX_THREE_MONTHS_AGO := p_organization_rec.PAYDEX_THREE_MONTHS_AGO;
      l_credit_rating_rec.FAILURE_SCORE := p_organization_rec.FAILURE_SCORE;
      l_credit_rating_rec.FAILURE_SCORE_AGE := p_organization_rec.FAILURE_SCORE_AGE;
      l_credit_rating_rec.FAILURE_SCORE_CLASS := p_organization_rec.FAILURE_SCORE_CLASS;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY := p_organization_rec.FAILURE_SCORE_COMMENTARY;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY2 := p_organization_rec.FAILURE_SCORE_COMMENTARY2;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY3 := p_organization_rec.FAILURE_SCORE_COMMENTARY3;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY4 := p_organization_rec.FAILURE_SCORE_COMMENTARY4;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY5 := p_organization_rec.FAILURE_SCORE_COMMENTARY5;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY6 := p_organization_rec.FAILURE_SCORE_COMMENTARY6;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY7 := p_organization_rec.FAILURE_SCORE_COMMENTARY7;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY8 := p_organization_rec.FAILURE_SCORE_COMMENTARY8;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY9 := p_organization_rec.FAILURE_SCORE_COMMENTARY9;
      l_credit_rating_rec.FAILURE_SCORE_COMMENTARY10 := p_organization_rec.FAILURE_SCORE_COMMENTARY10;
      l_credit_rating_rec.FAILURE_SCORE_DATE := p_organization_rec.FAILURE_SCORE_DATE;
      l_credit_rating_rec.FAILURE_SCORE_INCD_DEFAULT := p_organization_rec.FAILURE_SCORE_INCD_DEFAULT;
      l_credit_rating_rec.FAILURE_SCORE_NATNL_PERCENTILE := p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE;
      l_credit_rating_rec.FAILURE_SCORE_OVERRIDE_CODE := p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE;
      l_credit_rating_rec.GLOBAL_FAILURE_SCORE := p_organization_rec.GLOBAL_FAILURE_SCORE;
      l_credit_rating_rec.created_by_module := p_organization_rec.created_by_module;

      IF p_create_update_flag='C'
      THEN
      l_credit_rating_rec.rated_as_of_date := sysdate;
      ELSE
      l_credit_rating_rec.rated_as_of_date := to_date(null);
      END IF;

      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE (-)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;



      IF p_create_update_flag='C'  THEN
        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'call to create credit_rating (+)');
        END IF;
        */
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
            hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'call to create credit_rating (+)',
                               p_msg_level=>fnd_log.level_procedure);
        END IF;
        /*
        org_rec_to_cr_rec(
         p_create_update_flag               => 'C',
         p_organization_rec                 => p_organization_rec,
         x_credit_rating_rec                => l_credit_rating_rec );

        HZ_PARTY_INFO_PUB.create_credit_ratings(
          p_api_version           => 1,
          p_credit_ratings_rec    => l_credit_rating_rec,
          x_return_status         => x_return_status,
          x_msg_count             => l_msg_count,
          x_msg_data              => l_msg_data,
          x_credit_rating_id      => l_credit_rating_id
        );
        */
        HZ_PARTY_INFO_V2PUB.create_credit_rating(
           p_init_msg_list      => 'F',
           p_credit_rating_rec  => l_credit_rating_rec,
           x_credit_rating_id   => l_credit_rating_id,
           x_return_status      => x_return_status,
           x_msg_count          => l_msg_count,
           x_msg_data           => l_msg_data
        );


        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'call to create credit_rating (-)');
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'x_return_status = '||x_return_status);
        END IF;
        */
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'call to create credit_rating (-)',
                               p_msg_level=>fnd_log.level_procedure);

        END IF;
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'x_return_status = '||x_return_status,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
        END IF;
      ELSE
        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'call to update credit rating (+)');
        END IF;
        */
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
                hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'call to update credit rating (+)',
                               p_msg_level=>fnd_log.level_procedure);
        END IF;

        -- get the latest record for one party_id

        SELECT MAX(rated_as_of_date)
        INTO l_rated_as_of_date
        FROM hz_credit_ratings
        WHERE party_id = p_organization_rec.party_rec.party_id
        AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE;

        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_rated_as_of_date = ' || l_rated_as_of_date);
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'p_organization_rec.party_rec.party_id = ' ||
                                  p_organization_rec.party_rec.party_id);
        END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_rated_as_of_date = ' || l_rated_as_of_date,
                               p_msg_level=>fnd_log.level_statement);
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'p_organization_rec.party_rec.party_id = ' ||
                                  p_organization_rec.party_rec.party_id,
                               p_msg_level=>fnd_log.level_statement);

        END IF;


        BEGIN
          SELECT credit_rating_id, last_update_date,object_version_number
          INTO l_credit_rating_id, l_last_update_date,l_object_version_number
          FROM hz_credit_ratings
          WHERE party_id = p_organization_rec.party_rec.party_id
          AND actual_content_source =  G_MISS_CONTENT_SOURCE_TYPE
          AND(rated_as_of_date = l_rated_as_of_date OR
              (rated_as_of_date is null AND
               l_rated_as_of_date is null));
        EXCEPTION
          WHEN TOO_MANY_ROWS THEN
            SELECT credit_rating_id, last_update_date,object_version_number
            INTO l_credit_rating_id, l_last_update_date,l_object_version_number
            FROM hz_credit_ratings
            WHERE party_id = p_organization_rec.party_rec.party_id
            AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
            AND (rated_as_of_date = l_rated_as_of_date OR
                 (rated_as_of_date is null AND
                  l_rated_as_of_date is null))
            AND last_update_date = (
              SELECT MAX(last_update_date)
              FROM hz_credit_ratings
              WHERE party_id = p_organization_rec.party_rec.party_id
              AND actual_content_source = G_MISS_CONTENT_SOURCE_TYPE
              AND (rated_as_of_date = l_rated_as_of_date OR
                   (rated_as_of_date is null AND
                    l_rated_as_of_date is null)))
            AND ROWNUM = 1;
        END;

        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_credit_rating_id = ' || l_credit_rating_id);
        END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_credit_rating_id = ' || l_credit_rating_id,
                               p_msg_level=>fnd_log.level_statement);
        END IF;
        /*
        org_rec_to_cr_rec (
          p_create_update_flag               => 'U',
          p_organization_rec                 => p_organization_rec,
          x_credit_rating_rec                => l_credit_rating_rec );
        */
        l_credit_rating_rec.credit_rating_id := l_credit_rating_id;

        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'l_credit_rating_rec.credit_rating_id= ' ||
                                  l_credit_rating_rec.credit_rating_id);
        END IF;
        */
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'l_credit_rating_rec.credit_rating_id= ' ||
                                  l_credit_rating_rec.credit_rating_id,
                               p_msg_level=>fnd_log.level_statement);
        END IF;
        /*
        HZ_PARTY_INFO_PUB.update_credit_ratings(
          p_api_version           => 1,
          p_credit_ratings_rec    => l_credit_rating_rec,
          p_last_update_date      => l_last_update_date,
          x_return_status         => x_return_status,
          x_msg_count             => l_msg_count,
          x_msg_data              => l_msg_data);
        */
        HZ_PARTY_INFO_V2PUB.update_credit_rating(
           p_init_msg_list      => 'F',
           p_credit_rating_rec  => l_credit_rating_rec,
           p_object_version_number=> l_object_version_number,
           x_return_status      => x_return_status,
           x_msg_count          => l_msg_count,
           x_msg_data           => l_msg_data
        );

        /*IF g_debug THEN
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'call to update credit rating (-)');
          hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'x_return_status = '||x_return_status);
        END IF;
        */
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
             hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'call to update credit rating (-)',
                               p_msg_level=>fnd_log.level_procedure);
        END IF;
        IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'x_return_status = '||x_return_status,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
        END IF;
      END IF;

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE fnd_api.g_exc_error;
      END IF;
    END IF;

  END populate_credit_rating;

  /**
   * Convert organization record to v1 credit rating record.
   */

  -- Bug 3868940: Commented out org_rec_to_cr_rec

  /*
  PROCEDURE  org_rec_to_cr_rec(
    p_create_update_flag            IN     VARCHAR2,
    p_organization_rec              IN     ORGANIZATION_REC_TYPE,
    x_credit_rating_rec             OUT    NOCOPY HZ_PARTY_INFO_PUB.CREDIT_RATINGS_REC_TYPE
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    IF p_create_update_flag = 'C' THEN

      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE  for create (+)');
      END IF;
      */
      /*
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE  for create (+)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      x_credit_rating_rec.PARTY_ID :=  p_organization_rec.party_rec.PARTY_ID;
      x_credit_rating_rec.AVG_HIGH_CREDIT :=  p_organization_rec.AVG_HIGH_CREDIT;
      x_credit_rating_rec.CREDIT_SCORE := p_organization_rec.CREDIT_SCORE;
      x_credit_rating_rec.CREDIT_SCORE_AGE := p_organization_rec.CREDIT_SCORE_AGE;
      x_credit_rating_rec.CREDIT_SCORE_CLASS := p_organization_rec.CREDIT_SCORE_CLASS;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY := p_organization_rec.CREDIT_SCORE_COMMENTARY;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY2 := p_organization_rec.CREDIT_SCORE_COMMENTARY2;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY3 := p_organization_rec.CREDIT_SCORE_COMMENTARY3;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY4 := p_organization_rec.CREDIT_SCORE_COMMENTARY4;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY5 := p_organization_rec.CREDIT_SCORE_COMMENTARY5;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY6 := p_organization_rec.CREDIT_SCORE_COMMENTARY6;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY7 := p_organization_rec.CREDIT_SCORE_COMMENTARY7;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY8 := p_organization_rec.CREDIT_SCORE_COMMENTARY8;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY9 := p_organization_rec.CREDIT_SCORE_COMMENTARY9;
      x_credit_rating_rec.CREDIT_SCORE_COMMENTARY10 := p_organization_rec.CREDIT_SCORE_COMMENTARY10;
      x_credit_rating_rec.CREDIT_SCORE_DATE := p_organization_rec.CREDIT_SCORE_DATE;
      x_credit_rating_rec.CREDIT_SCORE_INCD_DEFAULT := p_organization_rec.CREDIT_SCORE_INCD_DEFAULT;
      x_credit_rating_rec.CREDIT_SCORE_NATL_PERCENTILE := p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE;
      x_credit_rating_rec.RATING := p_organization_rec.DB_RATING;
      x_credit_rating_rec.DEBARMENT_IND := p_organization_rec.DEBARMENT_IND;
      x_credit_rating_rec.DEBARMENTS_COUNT := p_organization_rec.DEBARMENTS_COUNT;
      x_credit_rating_rec.DEBARMENTS_DATE := p_organization_rec.DEBARMENTS_DATE;
      x_credit_rating_rec.HIGH_CREDIT := p_organization_rec.HIGH_CREDIT;
      x_credit_rating_rec.MAXIMUM_CREDIT_CURRENCY_CODE := p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE;
      x_credit_rating_rec.MAXIMUM_CREDIT_RCMD := p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION;
      x_credit_rating_rec.PAYDEX_NORM := p_organization_rec.PAYDEX_NORM;
      x_credit_rating_rec.PAYDEX_SCORE := p_organization_rec.PAYDEX_SCORE;
      x_credit_rating_rec.PAYDEX_THREE_MONTHS_AGO := p_organization_rec.PAYDEX_THREE_MONTHS_AGO;
      x_credit_rating_rec.rated_as_of_date := sysdate;
      x_credit_rating_rec.FAILURE_SCORE := p_organization_rec.FAILURE_SCORE;
      x_credit_rating_rec.FAILURE_SCORE_AGE := p_organization_rec.FAILURE_SCORE_AGE;
      x_credit_rating_rec.FAILURE_SCORE_CLASS := p_organization_rec.FAILURE_SCORE_CLASS;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY := p_organization_rec.FAILURE_SCORE_COMMENTARY;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY2 := p_organization_rec.FAILURE_SCORE_COMMENTARY2;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY3 := p_organization_rec.FAILURE_SCORE_COMMENTARY3;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY4 := p_organization_rec.FAILURE_SCORE_COMMENTARY4;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY5 := p_organization_rec.FAILURE_SCORE_COMMENTARY5;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY6 := p_organization_rec.FAILURE_SCORE_COMMENTARY6;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY7 := p_organization_rec.FAILURE_SCORE_COMMENTARY7;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY8 := p_organization_rec.FAILURE_SCORE_COMMENTARY8;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY9 := p_organization_rec.FAILURE_SCORE_COMMENTARY9;
      x_credit_rating_rec.FAILURE_SCORE_COMMENTARY10 := p_organization_rec.FAILURE_SCORE_COMMENTARY10;
      x_credit_rating_rec.FAILURE_SCORE_DATE := p_organization_rec.FAILURE_SCORE_DATE;
      x_credit_rating_rec.FAILURE_SCORE_INCD_DEFAULT := p_organization_rec.FAILURE_SCORE_INCD_DEFAULT;
      x_credit_rating_rec.FAILURE_SCORE_NATNL_PERCENTILE := p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE;
      x_credit_rating_rec.FAILURE_SCORE_OVERRIDE_CODE := p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE;
      x_credit_rating_rec.GLOBAL_FAILURE_SCORE := p_organization_rec.GLOBAL_FAILURE_SCORE;


      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE for create (-)');
      END IF;
      */
      /*
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE for create (-)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    ELSE
      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE for update(+)');
      END IF;
      */
      /*
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE for update(+)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      IF p_organization_rec.AVG_HIGH_CREDIT =  FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.AVG_HIGH_CREDIT := NULL;
      ELSIF p_organization_rec.AVG_HIGH_CREDIT is not null THEN
        x_credit_rating_rec.AVG_HIGH_CREDIT := p_organization_rec.AVG_HIGH_CREDIT;
      END IF;

      IF p_organization_rec.CREDIT_SCORE = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE is not null THEN
        x_credit_rating_rec.CREDIT_SCORE := p_organization_rec.CREDIT_SCORE;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_AGE = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.CREDIT_SCORE_AGE := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_AGE is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_AGE := p_organization_rec.CREDIT_SCORE_AGE;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_CLASS = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.CREDIT_SCORE_CLASS := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_CLASS is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_CLASS := p_organization_rec.CREDIT_SCORE_CLASS;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY := p_organization_rec.CREDIT_SCORE_COMMENTARY;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY2 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY2 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY2 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY2 := p_organization_rec.CREDIT_SCORE_COMMENTARY2;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY3 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY3 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY3 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY3 := p_organization_rec.CREDIT_SCORE_COMMENTARY3;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY4 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY4 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY4 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY4 := p_organization_rec.CREDIT_SCORE_COMMENTARY4;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY5 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY5 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY5 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY5 := p_organization_rec.CREDIT_SCORE_COMMENTARY5;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY6 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY6 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY6 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY6 := p_organization_rec.CREDIT_SCORE_COMMENTARY6;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY7 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY7 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY7 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY7 := p_organization_rec.CREDIT_SCORE_COMMENTARY7;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY8 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY8 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY8 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY8 := p_organization_rec.CREDIT_SCORE_COMMENTARY8;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY9 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY9 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY9 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY9 := p_organization_rec.CREDIT_SCORE_COMMENTARY9;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_COMMENTARY10 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY10 := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_COMMENTARY10 is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_COMMENTARY10 := p_organization_rec.CREDIT_SCORE_COMMENTARY10;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_DATE = FND_API.G_MISS_DATE THEN
        x_credit_rating_rec.CREDIT_SCORE_DATE := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_DATE is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_DATE := p_organization_rec.CREDIT_SCORE_DATE;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_INCD_DEFAULT = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.CREDIT_SCORE_INCD_DEFAULT := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_INCD_DEFAULT is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_INCD_DEFAULT := p_organization_rec.CREDIT_SCORE_INCD_DEFAULT;
      END IF;

      IF p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.CREDIT_SCORE_NATL_PERCENTILE := NULL;
      ELSIF p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE is not null THEN
        x_credit_rating_rec.CREDIT_SCORE_NATL_PERCENTILE := p_organization_rec.CREDIT_SCORE_NATL_PERCENTILE;
      END IF;

      IF p_organization_rec.DB_RATING = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.RATING := NULL;
      ELSIF p_organization_rec.DB_RATING is not null THEN
        x_credit_rating_rec.RATING := p_organization_rec.DB_RATING;
      END IF;

      IF p_organization_rec.DEBARMENT_IND = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.DEBARMENT_IND := NULL;
      ELSIF p_organization_rec.DEBARMENT_IND is not null THEN
        x_credit_rating_rec.DEBARMENT_IND := p_organization_rec.DEBARMENT_IND;
      END IF;

      IF p_organization_rec.DEBARMENTS_COUNT = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.DEBARMENTS_COUNT := NULL;
      ELSIF p_organization_rec.DEBARMENTS_COUNT is not null THEN
        x_credit_rating_rec.DEBARMENTS_COUNT := p_organization_rec.DEBARMENTS_COUNT;
      END IF;

      IF p_organization_rec.DEBARMENTS_DATE = FND_API.G_MISS_DATE THEN
        x_credit_rating_rec.DEBARMENTS_DATE := NULL;
      ELSIF p_organization_rec.DEBARMENTS_DATE is not null THEN
        x_credit_rating_rec.DEBARMENTS_DATE := p_organization_rec.DEBARMENTS_DATE;
      END IF;

      IF p_organization_rec.HIGH_CREDIT = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.HIGH_CREDIT := NULL;
      ELSIF p_organization_rec.HIGH_CREDIT is not null THEN
        x_credit_rating_rec.HIGH_CREDIT := p_organization_rec.HIGH_CREDIT;
      END IF;

      IF p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.MAXIMUM_CREDIT_CURRENCY_CODE := NULL;
      ELSIF p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE is not null THEN
        x_credit_rating_rec.MAXIMUM_CREDIT_CURRENCY_CODE := p_organization_rec.MAXIMUM_CREDIT_CURRENCY_CODE;
      END IF;

      IF p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.MAXIMUM_CREDIT_RCMD := NULL;
      ELSIF p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION is not null THEN
        x_credit_rating_rec.MAXIMUM_CREDIT_RCMD := p_organization_rec.MAXIMUM_CREDIT_RECOMMENDATION;
      END IF;

      IF p_organization_rec.PAYDEX_NORM = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.PAYDEX_NORM := NULL;
      ELSIF p_organization_rec.PAYDEX_NORM is not null THEN
        x_credit_rating_rec.PAYDEX_NORM := p_organization_rec.PAYDEX_NORM;
      END IF;

      IF p_organization_rec.PAYDEX_SCORE = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.PAYDEX_SCORE := NULL;
      ELSIF p_organization_rec.PAYDEX_SCORE is not null THEN
        x_credit_rating_rec.PAYDEX_SCORE := p_organization_rec.PAYDEX_SCORE;
      END IF;

      IF p_organization_rec.PAYDEX_THREE_MONTHS_AGO = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.PAYDEX_THREE_MONTHS_AGO := NULL;
      ELSIF p_organization_rec.PAYDEX_THREE_MONTHS_AGO is not null THEN
        x_credit_rating_rec.PAYDEX_THREE_MONTHS_AGO := p_organization_rec.PAYDEX_THREE_MONTHS_AGO;
      END IF;

      IF p_organization_rec.FAILURE_SCORE = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE is not null THEN
        x_credit_rating_rec.FAILURE_SCORE := p_organization_rec.FAILURE_SCORE;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_AGE = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.FAILURE_SCORE_AGE := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_AGE is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_AGE := p_organization_rec.FAILURE_SCORE_AGE;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_CLASS = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.FAILURE_SCORE_CLASS := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_CLASS is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_CLASS := p_organization_rec.FAILURE_SCORE_CLASS;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY := p_organization_rec.FAILURE_SCORE_COMMENTARY;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY2 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY2 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY2 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY2 := p_organization_rec.FAILURE_SCORE_COMMENTARY2;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY3 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY3 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY3 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY3 := p_organization_rec.FAILURE_SCORE_COMMENTARY3;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY4 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY4 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY4 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY4 := p_organization_rec.FAILURE_SCORE_COMMENTARY4;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY5 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY5 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY5 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY5 := p_organization_rec.FAILURE_SCORE_COMMENTARY5;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY6 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY6 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY6 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY6 := p_organization_rec.FAILURE_SCORE_COMMENTARY6;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY7 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY7 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY7 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY7 := p_organization_rec.FAILURE_SCORE_COMMENTARY7;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY8 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY8 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY8 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY8 := p_organization_rec.FAILURE_SCORE_COMMENTARY8;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY9 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY9 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY9 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY9 := p_organization_rec.FAILURE_SCORE_COMMENTARY9;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_COMMENTARY10 = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY10 := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_COMMENTARY10 is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_COMMENTARY10 := p_organization_rec.FAILURE_SCORE_COMMENTARY10;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_DATE = FND_API.G_MISS_DATE THEN
        x_credit_rating_rec.FAILURE_SCORE_DATE := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_DATE is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_DATE := p_organization_rec.FAILURE_SCORE_DATE;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_INCD_DEFAULT = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.FAILURE_SCORE_INCD_DEFAULT := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_INCD_DEFAULT is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_INCD_DEFAULT := p_organization_rec.FAILURE_SCORE_INCD_DEFAULT;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE = FND_API.G_MISS_NUM THEN
        x_credit_rating_rec.FAILURE_SCORE_NATNL_PERCENTILE := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_NATNL_PERCENTILE := p_organization_rec.FAILURE_SCORE_NATNL_PERCENTILE;
      END IF;

      IF p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.FAILURE_SCORE_OVERRIDE_CODE := NULL;
      ELSIF p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE is not null THEN
        x_credit_rating_rec.FAILURE_SCORE_OVERRIDE_CODE := p_organization_rec.FAILURE_SCORE_OVERRIDE_CODE;
      END IF;

      IF p_organization_rec.GLOBAL_FAILURE_SCORE = FND_API.G_MISS_CHAR THEN
        x_credit_rating_rec.GLOBAL_FAILURE_SCORE := NULL;
      ELSIF p_organization_rec.GLOBAL_FAILURE_SCORE is not null THEN
        x_credit_rating_rec.GLOBAL_FAILURE_SCORE := p_organization_rec.GLOBAL_FAILURE_SCORE;
      END IF;

      x_credit_rating_rec.rated_as_of_date := sysdate;

      /*IF g_debug THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE for update(-)');
      END IF;
      */
      /*
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_prefix=>l_debug_prefix,p_message=>'copy record from ORGANIZATION_REC_TYPE '||
                               'to CREDIT_RATINGS_REC_TYPE for update(-)',
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    END IF;

  END org_rec_to_cr_rec;
*/



   /*----------------------------------------------------------------------------*
 | procedure                                                                   |
 |    update_party_search                                                   |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This procedure updates the address_text column of                       |
 |    hz_cust_acct_sites_all with the NULL value                              |
 |    only to change the address_text column status                           |
 |    so that interMedia index can be created on it to perform text searches. |
 |                                                                            |
 | NOTE :- After Calling this procedure the user has to execute the            |
 |         Customer Text Data Creation concurrent program to see the changes. |
 |                                                                            |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |    p_party_id                                                              |
 |    p_old_party_name                                                        |
 |    p_new_party_name                                                        |
 |    p_old_tax_reference                                                     |
 |    p_new_tax_reference                                                     |
 |                                                                            |
 |   OUTPUT                                                                   |
 |                                                                            |
 |                                                                            |
 | HISTORY                                                                    |
 |    15-Mar-2004    Ramesh Ch   Created                                      |
 *----------------------------------------------------------------------------*/

PROCEDURE update_party_search(p_party_id          IN  NUMBER,
                              p_old_party_name    IN  VARCHAR2,
                              p_new_party_name    IN  VARCHAR2,
                              p_old_tax_reference IN  VARCHAR2,
                              p_new_tax_reference IN  VARCHAR2)
IS
CURSOR c_cust_acct_sites(p_party_id NUMBER) IS
    SELECT ac.CUST_ACCT_SITE_ID
    FROM HZ_PARTIES p, HZ_CUST_ACCOUNTS c,
         HZ_CUST_ACCT_SITES_ALL ac
    WHERE p.party_id=p_party_id
    AND p.party_id = c.party_id
    AND c.cust_account_id = ac.cust_account_id;
TYPE siteidtab IS TABLE OF HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
l_siteidtab siteidtab;

BEGIN
 SAVEPOINT update_party_search;

 IF(    isModified(p_old_party_name,p_new_party_name)
    OR  isModified(p_old_tax_reference,p_new_tax_reference)
 ) THEN
    OPEN c_cust_acct_sites(p_party_id);
    FETCH c_cust_acct_sites BULK COLLECT INTO l_siteidtab;
    CLOSE c_cust_acct_sites;
    IF l_siteidtab.COUNT >0 THEN
     FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
      update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
    END IF;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
   ROLLBACK TO update_party_search;
   RAISE;
END;

FUNCTION isModified(p_old_value IN VARCHAR2,p_new_value IN VARCHAR2) RETURN BOOLEAN
IS
BEGIN
  IF p_new_value IS NOT NULL AND p_new_value <> FND_API.G_MISS_CHAR THEN
     RETURN NVL(NOT (p_old_value=p_new_value),TRUE);
  ELSIF (p_old_value IS NOT NULL AND p_old_value <> FND_API.G_MISS_CHAR)
         AND p_new_value = FND_API.G_MISS_CHAR THEN
     RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;

/*----------------------------------------------------------------------------*
 | procedure                                                                   |
 |    update_rel_person_search                                                |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This procedure updates the address_text column of                       |
 |    hz_cust_acct_sites_all with the NULL value                              |
 |    only to change the address_text column status                           |
 |    so that interMedia index can be created on it to perform text searches. |
 |                                                                            |
 | NOTE :- After Calling this procedure the user has to execute the            |
 |         Customer Text Data Creation concurrent program to see the changes. |
 |                                                                            |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |    p_old_person_rec                                                        |
 |    p_new_person_rec                                                        |
 |                                                                            |
 |   OUTPUT                                                                   |
 |                                                                            |
 |                                                                            |
 | HISTORY                                                                    |
 |    15-Mar-2004    Ramesh Ch   Created                                      |
 *----------------------------------------------------------------------------*/

PROCEDURE update_rel_person_search(p_old_person_rec IN  HZ_PARTY_V2PUB.PERSON_REC_TYPE,
                                   p_new_person_rec IN  HZ_PARTY_V2PUB.PERSON_REC_TYPE)
IS
   ---(Party level relationship )
    CURSOR c_party_cust_acct_sites(p_party_id NUMBER) IS
      SELECT distinct ac.CUST_ACCT_SITE_ID
      FROM HZ_PARTIES p, HZ_CUST_ACCOUNT_ROLES ar,
         HZ_RELATIONSHIPS rel,HZ_CUST_ACCT_SITES_ALL ac
      WHERE rel.subject_id=p_party_id
      AND ar.ROLE_TYPE = 'CONTACT'
      AND rel.party_id=ar.party_id
      AND rel.subject_id=p.party_id
      AND ar.cust_account_id = ac.cust_account_id
      AND (ar.cust_acct_site_id is null);

   ----(Site Level relationship)
    CURSOR c_site_cust_acct_sites(p_party_id NUMBER) IS
      SELECT distinct ac.CUST_ACCT_SITE_ID
      FROM HZ_PARTIES p, HZ_CUST_ACCOUNT_ROLES ar,
          HZ_RELATIONSHIPS rel,HZ_CUST_ACCT_SITES_ALL ac
      WHERE rel.subject_id=p_party_id
      AND ar.ROLE_TYPE = 'CONTACT'
      AND ar.party_id = rel.party_id
      AND p.party_id = rel.subject_id
      AND ar.cust_account_id = ac.cust_account_id
      AND ar.cust_acct_site_id = ac.cust_acct_site_id;

    TYPE siteidtab IS TABLE OF HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
    l_siteidtab siteidtab;

BEGIN
 SAVEPOINT update_rel_person_search;
 IF(    isModified(p_old_person_rec.person_first_name,p_new_person_rec.person_first_name)
    OR  isModified(p_old_person_rec.person_last_name,p_new_person_rec.person_last_name)
 ) THEN
    ---Process party level relationship's records.
    OPEN c_party_cust_acct_sites(p_old_person_rec.party_rec.party_id);
    FETCH c_party_cust_acct_sites BULK COLLECT INTO l_siteidtab;
    CLOSE c_party_cust_acct_sites;
    IF l_siteidtab.COUNT >0 THEN
     FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
       update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
     NULL;
    END IF;
    ---Process site level relationship's records.
    OPEN c_site_cust_acct_sites(p_old_person_rec.party_rec.party_id);
    FETCH c_site_cust_acct_sites BULK COLLECT INTO l_siteidtab;
    CLOSE c_site_cust_acct_sites;
    IF l_siteidtab.COUNT >0 THEN
     FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
       update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
    END IF;
 END IF;
EXCEPTION
 WHEN OTHERS THEN
   ROLLBACK TO update_rel_person_search;
   RAISE;
END;

----------------------------Bug 4586451
/**
 * PRIVATE PROCEDURE validate_party_name
 *
 * DESCRIPTION
 *     Validate party name.
 *
 * EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
 *
 * ARGUMENTS
 *     IN:
 *     OUT:
 *     IN/ OUT:
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 */

PROCEDURE validate_party_name (
    p_party_id                    IN     NUMBER,
    p_party_name                  IN     VARCHAR2,
    x_return_status               IN OUT NOCOPY VARCHAR2
) IS

    c_supplier_code               CONSTANT VARCHAR2(30) := 'SUPPLIER';

    CURSOR c_supplier (
      p_party_id                  NUMBER
    ) IS
    SELECT null
    FROM   hz_party_usg_assignments pu
    WHERE  pu.party_id = p_party_id
    AND    pu.party_usage_code = c_supplier_code
    AND    ROWNUM = 1;

    l_dummy                       VARCHAR2(1);

BEGIN

    IF fnd_log.level_procedure >= fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug (
        p_message                 => 'validate_party_name (+)',
        p_prefix                  => '',
        p_msg_level               => fnd_log.level_procedure
      );
    END IF;

    -- check if the party is supplier


    OPEN c_supplier(p_party_id);
    FETCH c_supplier INTO l_dummy;
    IF c_supplier%FOUND THEN



      -- check uniqueness across supplier parties
      hz_party_usg_assignment_pvt.validate_supplier_name (
        p_party_id                => p_party_id,
        p_party_name              => p_party_name,
        x_return_status           => x_return_status);
    END IF;
    CLOSE c_supplier;

    IF fnd_log.level_procedure >= fnd_log.g_current_runtime_level THEN
      hz_utility_v2pub.debug (
        p_message                 => 'validate_party_name (-)',
        p_prefix                  => '',
        p_msg_level               => fnd_log.level_procedure
      );
    END IF;

END validate_party_name;
-------------------------------Bug No. 4586451

END HZ_PARTY_V2PUB;
/
COMMIT;
EXIT;
