SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_PARTY_BO_PVT
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_PARTY_BO_PVT                                                  |
-- | Description :                                                                           |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |Draft 1a   15-Oct-2012     Sreedhar Mohan       Initial draft version                    |
-- +=========================================================================================+
AS

  -- PRIVATE PROCEDURE assign_organization_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from organization business object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_organization_obj   Organization object.
  --     p_organization_id    Organization Id.
  --     p_organization_os    Organization original system.
  --     p_organization_osr   Organization original system reference.
  --     p_create_or_update   Create or update flag.
  --   IN/OUT:
  --     px_organization_rec  Organization plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_organization_rec(
    p_organization_obj                 IN            HZ_ORGANIZATION_BO,
    p_organization_id                  IN            NUMBER,
    p_organization_os                  IN            VARCHAR2,
    p_organization_osr                 IN            VARCHAR2,
    p_create_or_update                 IN            VARCHAR2 := 'C',
    px_organization_rec                IN OUT NOCOPY HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE
  );

  -- PRIVATE PROCEDURE assign_credit_rating_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from credit rating object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_credit_rating_obj  Credit rating object.
  --     p_party_id           Party Id.
  --   IN/OUT:
  --     px_credit_rating_rec Credit rating plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_credit_rating_rec(
    p_credit_rating_obj                IN            HZ_CREDIT_RATING_OBJ,
    p_party_id                         IN            NUMBER,
    px_credit_rating_rec               IN OUT NOCOPY HZ_PARTY_INFO_V2PUB.CREDIT_RATING_REC_TYPE
  );

  -- PRIVATE PROCEDURE assign_financial_report_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from financial report object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_fin_report_obj     Financial report object.
  --     p_party_id           Party Id.
  --   IN/OUT:
  --     px_fin_report_rec    Financial report plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_financial_report_rec(
    p_fin_report_obj                   IN            HZ_FINANCIAL_BO,
    p_party_id                         IN            NUMBER,
    px_fin_report_rec                  IN OUT NOCOPY HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_REPORT_REC_TYPE
  );

  -- PRIVATE PROCEDURE assign_financial_number_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from financial number object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_fin_number_obj     Financial number object.
  --     p_fin_report_id      Financial report Id.
  --   IN/OUT:
  --     px_fin_number_rec    Financial number plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_financial_number_rec(
    p_fin_number_obj                   IN            HZ_FINANCIAL_NUMBER_OBJ,
    p_fin_report_id                    IN            NUMBER,
    px_fin_number_rec                  IN OUT NOCOPY HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_NUMBER_REC_TYPE
  );

  -- PRIVATE PROCEDURE create_credit_ratings
  --
  -- DESCRIPTION
  --     Create credit ratings.
  PROCEDURE create_credit_ratings(
    p_credit_rating_objs   IN OUT NOCOPY HZ_CREDIT_RATING_OBJ_TBL,
    p_organization_id      IN         NUMBER,
    x_return_status        OUT NOCOPY VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2
  );

  -- PRIVATE PROCEDURE save_credit_ratings
  --
  -- DESCRIPTION
  --     Create or update credit ratings.
  PROCEDURE save_credit_ratings(
    p_credit_rating_objs   IN OUT NOCOPY HZ_CREDIT_RATING_OBJ_TBL,
    p_organization_id      IN         NUMBER,
    x_return_status        OUT NOCOPY VARCHAR2,
    x_msg_count            OUT NOCOPY NUMBER,
    x_msg_data             OUT NOCOPY VARCHAR2
  );

  -- PRIVATE PROCEDURE create_financial_reports
  --
  -- DESCRIPTION
  --     Create financial reports.
  PROCEDURE create_financial_reports(
    p_fin_objs          IN OUT NOCOPY HZ_FINANCIAL_BO_TBL,
    p_organization_id   IN         NUMBER,
    x_return_status     OUT NOCOPY VARCHAR2,
    x_msg_count         OUT NOCOPY NUMBER,
    x_msg_data          OUT NOCOPY VARCHAR2
  );

  -- PRIVATE PROCEDURE save_financial_reports
  --
  -- DESCRIPTION
  --     Create or update financial reports.
  PROCEDURE save_financial_reports(
    p_fin_objs          IN OUT NOCOPY HZ_FINANCIAL_BO_TBL,
    p_organization_id   IN         NUMBER,
    x_return_status     OUT NOCOPY VARCHAR2,
    x_msg_count         OUT NOCOPY NUMBER,
    x_msg_data          OUT NOCOPY VARCHAR2
  );
  -- PRIVATE PROCEDURE assign_code_assign_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from classification object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_code_assign_obj    Classification object.
  --     p_owner_table_name   Owner table name.
  --     p_owner_table_id     Owner table Id.
  --   IN/OUT:
  --     px_code_assign_rec   Classification plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.
  --

  PROCEDURE assign_code_assign_rec(
    p_code_assign_obj            IN            HZ_CODE_ASSIGNMENT_OBJ,
    p_owner_table_name           IN            VARCHAR2,
    p_owner_table_id             IN            NUMBER,
    px_code_assign_rec           IN OUT NOCOPY HZ_CLASSIFICATION_V2PUB.code_assignment_rec_type
  ) IS
  l_class_code                    HZ_CODE_ASSIGNMENTS.CLASS_CODE%TYPE := NULL;
  BEGIN
    px_code_assign_rec.code_assignment_id    := p_code_assign_obj.code_assignment_id;
    px_code_assign_rec.owner_table_name      := p_owner_table_name;
    px_code_assign_rec.owner_table_id        := p_owner_table_id;
    px_code_assign_rec.class_category        := p_code_assign_obj.class_category;
    
    --Derive default Segmentation or Loyalty codes from profile option values, when they are null
    CASE
      WHEN p_code_assign_obj.class_category = 'Customer Segmentation' THEN
        l_class_code := nvl(p_code_assign_obj.class_code,fnd_profile.value('XX_CDH_DEF_SEGMENTATION_CD'));
      WHEN p_code_assign_obj.class_category = 'Customer Loyalty' THEN
        l_class_code := nvl(p_code_assign_obj.class_code,fnd_profile.value('XX_CDH_DEF_LOYALTY_CD'));
    END CASE;
    
    px_code_assign_rec.class_code            := l_class_code;
    px_code_assign_rec.primary_flag          := p_code_assign_obj.primary_flag;
    px_code_assign_rec.start_date_active     := p_code_assign_obj.start_date_active;
    px_code_assign_rec.end_date_active       := p_code_assign_obj.end_date_active;
    px_code_assign_rec.status                := p_code_assign_obj.status;
    px_code_assign_rec.actual_content_source := p_code_assign_obj.actual_content_source;
    px_code_assign_rec.created_by_module     := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
    px_code_assign_rec.rank                  := p_code_assign_obj.rank;
  END assign_code_assign_rec;

  -- PRIVATE PROCEDURE assign_organization_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from organization business object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_organization_obj   Organization object.
  --     p_organization_id    Organization Id.
  --     p_organization_os    Organization original system.
  --     p_organization_osr   Organization original system reference.
  --     p_create_or_update   Create or update flag.
  --   IN/OUT:
  --     px_organization_rec  Organization plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_organization_rec(
    p_organization_obj                 IN            HZ_ORGANIZATION_BO,
    p_organization_id                  IN            NUMBER,
    p_organization_os                  IN            VARCHAR2,
    p_organization_osr                 IN            VARCHAR2,
    p_create_or_update                 IN            VARCHAR2 := 'C',
    px_organization_rec                IN OUT NOCOPY HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE
  ) IS
  BEGIN
    px_organization_rec.organization_name:=  p_organization_obj.organization_name;
    px_organization_rec.duns_number_c:=  p_organization_obj.duns_number_c;
    px_organization_rec.enquiry_duns:=  p_organization_obj.enquiry_duns;
    px_organization_rec.ceo_name:=  p_organization_obj.ceo_name;
    px_organization_rec.ceo_title:=  p_organization_obj.ceo_title;
    px_organization_rec.principal_name:=  p_organization_obj.principal_name;
    px_organization_rec.principal_title:=  p_organization_obj.principal_title;
    px_organization_rec.legal_status:=  p_organization_obj.legal_status;
    px_organization_rec.control_yr:=  p_organization_obj.control_yr;
    px_organization_rec.employees_total:=  p_organization_obj.employees_total;
    px_organization_rec.hq_branch_ind:=  p_organization_obj.hq_branch_ind;
    IF(p_organization_obj.branch_flag in ('Y','N')) THEN
      px_organization_rec.branch_flag:=  p_organization_obj.branch_flag;
    END IF;
    IF(p_organization_obj.oob_ind in ('Y','N')) THEN
      px_organization_rec.oob_ind:=  p_organization_obj.oob_ind;
    END IF;
    px_organization_rec.line_of_business:=  p_organization_obj.line_of_business;
    px_organization_rec.cong_dist_code:=  p_organization_obj.cong_dist_code;
    px_organization_rec.sic_code:=  p_organization_obj.sic_code;
    IF(p_organization_obj.import_ind in ('Y','N')) THEN
      px_organization_rec.import_ind:=  p_organization_obj.import_ind;
    END IF;
    IF(p_organization_obj.export_ind in ('Y','N')) THEN
      px_organization_rec.export_ind:=  p_organization_obj.export_ind;
    END IF;
    IF(p_organization_obj.labor_surplus_ind in ('Y','N')) THEN
      px_organization_rec.labor_surplus_ind:=  p_organization_obj.labor_surplus_ind;
    END IF;
    IF(p_organization_obj.debarment_ind in ('Y','N')) THEN
      px_organization_rec.debarment_ind:=  p_organization_obj.debarment_ind;
    END IF;
    IF(p_organization_obj.minority_owned_ind in ('Y','N')) THEN
      px_organization_rec.minority_owned_ind:=  p_organization_obj.minority_owned_ind;
    END IF;
    px_organization_rec.minority_owned_type:=  p_organization_obj.minority_owned_type;
    IF(p_organization_obj.woman_owned_ind in ('Y','N')) THEN
      px_organization_rec.woman_owned_ind:=  p_organization_obj.woman_owned_ind;
    END IF;
    IF(p_organization_obj.disadv_8a_ind in ('Y','N')) THEN
      px_organization_rec.disadv_8a_ind:=  p_organization_obj.disadv_8a_ind;
    END IF;
    IF(p_organization_obj.small_bus_ind in ('Y','N')) THEN
      px_organization_rec.small_bus_ind:=  p_organization_obj.small_bus_ind;
    END IF;
    px_organization_rec.rent_own_ind:=  p_organization_obj.rent_own_ind;
    px_organization_rec.debarments_count:=  p_organization_obj.debarments_count;
    px_organization_rec.debarments_date:=  p_organization_obj.debarments_date;
    px_organization_rec.failure_score:=  p_organization_obj.failure_score;
    px_organization_rec.failure_score_natnl_percentile:=  p_organization_obj.failure_score_natnl_per;
    px_organization_rec.failure_score_override_code:=  p_organization_obj.failure_score_override_code;
    px_organization_rec.failure_score_commentary:=  p_organization_obj.failure_score_commentary;
    px_organization_rec.global_failure_score:=  p_organization_obj.global_failure_score;
    px_organization_rec.db_rating:=  p_organization_obj.db_rating;
    px_organization_rec.credit_score:=  p_organization_obj.credit_score;
    px_organization_rec.credit_score_commentary:=  p_organization_obj.credit_score_commentary;
    px_organization_rec.paydex_score:=  p_organization_obj.paydex_score;
    px_organization_rec.paydex_three_months_ago:=  p_organization_obj.paydex_three_months_ago;
    px_organization_rec.paydex_norm:=  p_organization_obj.paydex_norm;
    px_organization_rec.best_time_contact_begin:=  p_organization_obj.best_time_contact_begin;
    px_organization_rec.best_time_contact_end:=  p_organization_obj.best_time_contact_end;
    px_organization_rec.organization_name_phonetic:=  p_organization_obj.organization_name_phonetic;
    px_organization_rec.tax_reference:=  p_organization_obj.tax_reference;
    IF(p_organization_obj.gsa_indicator_flag in ('Y','N')) THEN
      px_organization_rec.gsa_indicator_flag:=  p_organization_obj.gsa_indicator_flag;
    END IF;
    px_organization_rec.jgzz_fiscal_code:=  p_organization_obj.jgzz_fiscal_code;
    px_organization_rec.analysis_fy:=  p_organization_obj.analysis_fy;
    px_organization_rec.fiscal_yearend_month:=  p_organization_obj.fiscal_yearend_month;
    px_organization_rec.curr_fy_potential_revenue:=  p_organization_obj.curr_fy_potential_revenue;
    px_organization_rec.next_fy_potential_revenue:=  p_organization_obj.next_fy_potential_revenue;
    px_organization_rec.year_established:=  p_organization_obj.year_established;
    px_organization_rec.mission_statement:=  p_organization_obj.mission_statement;
    px_organization_rec.organization_type:=  p_organization_obj.organization_type;
    px_organization_rec.business_scope:=  p_organization_obj.business_scope;
    px_organization_rec.corporation_class:=  p_organization_obj.corporation_class;
    px_organization_rec.known_as:=  p_organization_obj.known_as;
    px_organization_rec.known_as2:=  p_organization_obj.known_as2;
    px_organization_rec.known_as3:=  p_organization_obj.known_as3;
    px_organization_rec.known_as4:=  p_organization_obj.known_as4;
    px_organization_rec.known_as5:=  p_organization_obj.known_as5;
    px_organization_rec.local_bus_iden_type:=  p_organization_obj.local_bus_iden_type;
    px_organization_rec.local_bus_identifier:=  p_organization_obj.local_bus_identifier;
    px_organization_rec.pref_functional_currency:=  p_organization_obj.pref_functional_currency;
    px_organization_rec.registration_type:=  p_organization_obj.registration_type;
    px_organization_rec.total_employees_text:=  p_organization_obj.total_employees_text;
    px_organization_rec.total_employees_ind:=  p_organization_obj.total_employees_ind;
    px_organization_rec.total_emp_est_ind:=  p_organization_obj.total_emp_est_ind;
    px_organization_rec.total_emp_min_ind:=  p_organization_obj.total_emp_min_ind;
    IF(p_organization_obj.parent_sub_ind in ('Y','N')) THEN
      px_organization_rec.parent_sub_ind:=  p_organization_obj.parent_sub_ind;
    END IF;
    px_organization_rec.incorp_year:=  p_organization_obj.incorp_year;
    px_organization_rec.sic_code_type:=  p_organization_obj.sic_code_type;
    IF(p_organization_obj.public_private_owner_flag in ('Y','N')) THEN
      px_organization_rec.public_private_ownership_flag:=  p_organization_obj.public_private_owner_flag;
    END IF;
    IF(p_organization_obj.internal_flag in ('Y','N')) THEN
      px_organization_rec.internal_flag:=  p_organization_obj.internal_flag;
    END IF;
    px_organization_rec.local_activity_code_type:=  p_organization_obj.local_activity_code_type;
    px_organization_rec.local_activity_code:=  p_organization_obj.local_activity_code;
    px_organization_rec.emp_at_primary_adr:=  p_organization_obj.emp_at_primary_adr;
    px_organization_rec.emp_at_primary_adr_text:=  p_organization_obj.emp_at_primary_adr_text;
    px_organization_rec.emp_at_primary_adr_est_ind:=  p_organization_obj.emp_at_primary_adr_est_ind;
    px_organization_rec.emp_at_primary_adr_min_ind:=  p_organization_obj.emp_at_primary_adr_min_ind;
    px_organization_rec.high_credit:=  p_organization_obj.high_credit;
    px_organization_rec.avg_high_credit:=  p_organization_obj.avg_high_credit;
    px_organization_rec.total_payments:=  p_organization_obj.total_payments;
    px_organization_rec.credit_score_class:=  p_organization_obj.credit_score_class;
    px_organization_rec.credit_score_natl_percentile:=  p_organization_obj.credit_score_natl_percentile;
    px_organization_rec.credit_score_incd_default:=  p_organization_obj.credit_score_incd_default;
    px_organization_rec.credit_score_age:=  p_organization_obj.credit_score_age;
    px_organization_rec.credit_score_date:=  p_organization_obj.credit_score_date;
    px_organization_rec.credit_score_commentary2:=  p_organization_obj.credit_score_commentary2;
    px_organization_rec.credit_score_commentary3:=  p_organization_obj.credit_score_commentary3;
    px_organization_rec.credit_score_commentary4:=  p_organization_obj.credit_score_commentary4;
    px_organization_rec.credit_score_commentary5:=  p_organization_obj.credit_score_commentary5;
    px_organization_rec.credit_score_commentary6:=  p_organization_obj.credit_score_commentary6;
    px_organization_rec.credit_score_commentary7:=  p_organization_obj.credit_score_commentary7;
    px_organization_rec.credit_score_commentary8:=  p_organization_obj.credit_score_commentary8;
    px_organization_rec.credit_score_commentary9:=  p_organization_obj.credit_score_commentary9;
    px_organization_rec.credit_score_commentary10:=  p_organization_obj.credit_score_commentary10;
    px_organization_rec.failure_score_class:=  p_organization_obj.failure_score_class;
    px_organization_rec.failure_score_incd_default:=  p_organization_obj.failure_score_incd_default;
    px_organization_rec.failure_score_age:=  p_organization_obj.failure_score_age;
    px_organization_rec.failure_score_date:=  p_organization_obj.failure_score_date;
    px_organization_rec.failure_score_commentary2:=  p_organization_obj.failure_score_commentary2;
    px_organization_rec.failure_score_commentary3:=  p_organization_obj.failure_score_commentary3;
    px_organization_rec.failure_score_commentary4:=  p_organization_obj.failure_score_commentary4;
    px_organization_rec.failure_score_commentary5:=  p_organization_obj.failure_score_commentary5;
    px_organization_rec.failure_score_commentary6:=  p_organization_obj.failure_score_commentary6;
    px_organization_rec.failure_score_commentary7:=  p_organization_obj.failure_score_commentary7;
    px_organization_rec.failure_score_commentary8:=  p_organization_obj.failure_score_commentary8;
    px_organization_rec.failure_score_commentary9:=  p_organization_obj.failure_score_commentary9;
    px_organization_rec.failure_score_commentary10:=  p_organization_obj.failure_score_commentary10;
    px_organization_rec.maximum_credit_recommendation:=  p_organization_obj.maximum_credit_recommend;
    px_organization_rec.maximum_credit_currency_code:=  p_organization_obj.maximum_credit_currency_code;
    px_organization_rec.displayed_duns_party_id:=  p_organization_obj.displayed_duns_party_id;
    IF(p_create_or_update = 'C') THEN
      px_organization_rec.party_rec.orig_system:= p_organization_os;
      px_organization_rec.party_rec.orig_system_reference:= p_organization_osr;
      px_organization_rec.created_by_module:=  HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
    END IF;
    px_organization_rec.do_not_confuse_with:=  p_organization_obj.do_not_confuse_with;
    px_organization_rec.actual_content_source:=  p_organization_obj.actual_content_source;
    px_organization_rec.party_rec.party_id:= p_organization_id;
    px_organization_rec.party_rec.party_number:= p_organization_obj.party_number;
    px_organization_rec.party_rec.validated_flag:= p_organization_obj.validated_flag;
    px_organization_rec.party_rec.status:= p_organization_obj.status;
    px_organization_rec.party_rec.category_code:= p_organization_obj.category_code;
    px_organization_rec.party_rec.salutation:= p_organization_obj.salutation;
    px_organization_rec.party_rec.attribute_category:= p_organization_obj.attribute_category;
    px_organization_rec.party_rec.attribute1:= p_organization_obj.attribute1;
    px_organization_rec.party_rec.attribute2:= p_organization_obj.attribute2;
    px_organization_rec.party_rec.attribute3:= p_organization_obj.attribute3;
    px_organization_rec.party_rec.attribute4:= p_organization_obj.attribute4;
    px_organization_rec.party_rec.attribute5:= p_organization_obj.attribute5;
    px_organization_rec.party_rec.attribute6:= p_organization_obj.attribute6;
    px_organization_rec.party_rec.attribute7:= p_organization_obj.attribute7;
    px_organization_rec.party_rec.attribute8:= p_organization_obj.attribute8;
    px_organization_rec.party_rec.attribute9:= p_organization_obj.attribute9;
    px_organization_rec.party_rec.attribute10:= p_organization_obj.attribute10;
    px_organization_rec.party_rec.attribute11:= p_organization_obj.attribute11;
    px_organization_rec.party_rec.attribute12:= p_organization_obj.attribute12;
    px_organization_rec.party_rec.attribute13:= p_organization_obj.attribute13;
    px_organization_rec.party_rec.attribute14:= p_organization_obj.attribute14;
    px_organization_rec.party_rec.attribute15:= p_organization_obj.attribute15;
    px_organization_rec.party_rec.attribute16:= p_organization_obj.attribute16;
    px_organization_rec.party_rec.attribute17:= p_organization_obj.attribute17;
    px_organization_rec.party_rec.attribute18:= p_organization_obj.attribute18;
    px_organization_rec.party_rec.attribute19:= p_organization_obj.attribute19;
    px_organization_rec.party_rec.attribute20:= p_organization_obj.attribute20;
    px_organization_rec.party_rec.attribute21:= p_organization_obj.attribute21;
    px_organization_rec.party_rec.attribute22:= p_organization_obj.attribute22;
    px_organization_rec.party_rec.attribute23:= p_organization_obj.attribute23;
    px_organization_rec.party_rec.attribute24:= p_organization_obj.attribute24;
  END assign_organization_rec;

  -- PRIVATE PROCEDURE assign_credit_rating_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from credit rating object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_credit_rating_obj  Credit rating object.
  --     p_party_id           Party Id.
  --   IN/OUT:
  --     px_credit_rating_rec Credit rating plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_credit_rating_rec(
    p_credit_rating_obj                IN            HZ_CREDIT_RATING_OBJ,
    p_party_id                         IN            NUMBER,
    px_credit_rating_rec               IN OUT NOCOPY HZ_PARTY_INFO_V2PUB.CREDIT_RATING_REC_TYPE
  ) IS
  BEGIN
    px_credit_rating_rec.credit_rating_id:=  p_credit_rating_obj.credit_rating_id;
    px_credit_rating_rec.description:=  p_credit_rating_obj.description;
    px_credit_rating_rec.party_id:=  p_party_id;
    px_credit_rating_rec.rating:=  p_credit_rating_obj.rating;
    px_credit_rating_rec.rated_as_of_date:=  p_credit_rating_obj.rated_as_of_date;
    px_credit_rating_rec.rating_organization:=  p_credit_rating_obj.rating_organization;
    px_credit_rating_rec.comments:=  p_credit_rating_obj.comments;
    px_credit_rating_rec.det_history_ind:=  p_credit_rating_obj.det_history_ind;
    IF(p_credit_rating_obj.fincl_embt_ind in ('Y','N')) THEN
      px_credit_rating_rec.fincl_embt_ind:=  p_credit_rating_obj.fincl_embt_ind;
    END IF;
    px_credit_rating_rec.criminal_proceeding_ind:=  p_credit_rating_obj.criminal_proceeding_ind;
    px_credit_rating_rec.claims_ind:=  p_credit_rating_obj.claims_ind;
    px_credit_rating_rec.secured_flng_ind:=  p_credit_rating_obj.secured_flng_ind;
    px_credit_rating_rec.fincl_lgl_event_ind:=  p_credit_rating_obj.fincl_lgl_event_ind;
    px_credit_rating_rec.disaster_ind:=  p_credit_rating_obj.disaster_ind;
    px_credit_rating_rec.oprg_spec_evnt_ind:=  p_credit_rating_obj.oprg_spec_evnt_ind;
    px_credit_rating_rec.other_spec_evnt_ind:=  p_credit_rating_obj.other_spec_evnt_ind;
    IF(p_credit_rating_obj.status in ('A','I')) THEN
      px_credit_rating_rec.status:=  p_credit_rating_obj.status;
    END IF;
    px_credit_rating_rec.avg_high_credit:=  p_credit_rating_obj.avg_high_credit;
    px_credit_rating_rec.credit_score:=  p_credit_rating_obj.credit_score;
    px_credit_rating_rec.credit_score_age:=  p_credit_rating_obj.credit_score_age;
    px_credit_rating_rec.credit_score_class:=  p_credit_rating_obj.credit_score_class;
    px_credit_rating_rec.credit_score_commentary:=  p_credit_rating_obj.credit_score_commentary;
    px_credit_rating_rec.credit_score_commentary2:=  p_credit_rating_obj.credit_score_commentary2;
    px_credit_rating_rec.credit_score_commentary3:=  p_credit_rating_obj.credit_score_commentary3;
    px_credit_rating_rec.credit_score_commentary4:=  p_credit_rating_obj.credit_score_commentary4;
    px_credit_rating_rec.credit_score_commentary5:=  p_credit_rating_obj.credit_score_commentary5;
    px_credit_rating_rec.credit_score_commentary6:=  p_credit_rating_obj.credit_score_commentary6;
    px_credit_rating_rec.credit_score_commentary7:=  p_credit_rating_obj.credit_score_commentary7;
    px_credit_rating_rec.credit_score_commentary8:=  p_credit_rating_obj.credit_score_commentary8;
    px_credit_rating_rec.credit_score_commentary9:=  p_credit_rating_obj.credit_score_commentary9;
    px_credit_rating_rec.credit_score_commentary10:=  p_credit_rating_obj.credit_score_commentary10;
    px_credit_rating_rec.credit_score_date:=  p_credit_rating_obj.credit_score_date;
    px_credit_rating_rec.credit_score_incd_default:=  p_credit_rating_obj.credit_score_incd_default;
    px_credit_rating_rec.credit_score_natl_percentile:=  p_credit_rating_obj.credit_score_natl_percentile;
    px_credit_rating_rec.failure_score:=  p_credit_rating_obj.failure_score;
    px_credit_rating_rec.failure_score_age:=  p_credit_rating_obj.failure_score_age;
    px_credit_rating_rec.failure_score_class:=  p_credit_rating_obj.failure_score_class;
    px_credit_rating_rec.failure_score_commentary:=  p_credit_rating_obj.failure_score_commentary;
    px_credit_rating_rec.failure_score_commentary2:=  p_credit_rating_obj.failure_score_commentary2;
    px_credit_rating_rec.failure_score_commentary3:=  p_credit_rating_obj.failure_score_commentary3;
    px_credit_rating_rec.failure_score_commentary4:=  p_credit_rating_obj.failure_score_commentary4;
    px_credit_rating_rec.failure_score_commentary5:=  p_credit_rating_obj.failure_score_commentary5;
    px_credit_rating_rec.failure_score_commentary6:=  p_credit_rating_obj.failure_score_commentary6;
    px_credit_rating_rec.failure_score_commentary7:=  p_credit_rating_obj.failure_score_commentary7;
    px_credit_rating_rec.failure_score_commentary8:=  p_credit_rating_obj.failure_score_commentary8;
    px_credit_rating_rec.failure_score_commentary9:=  p_credit_rating_obj.failure_score_commentary9;
    px_credit_rating_rec.failure_score_commentary10:=  p_credit_rating_obj.failure_score_commentary10;
    px_credit_rating_rec.failure_score_date:=  p_credit_rating_obj.failure_score_date;
    px_credit_rating_rec.failure_score_incd_default:=  p_credit_rating_obj.failure_score_incd_default;
    px_credit_rating_rec.failure_score_natnl_percentile:=  p_credit_rating_obj.failure_score_natnl_per;
    px_credit_rating_rec.failure_score_override_code:=  p_credit_rating_obj.failure_score_override_code;
    px_credit_rating_rec.global_failure_score:=  p_credit_rating_obj.global_failure_score;
    IF(p_credit_rating_obj.debarment_ind in ('Y','N')) THEN
      px_credit_rating_rec.debarment_ind:=  p_credit_rating_obj.debarment_ind;
    END IF;
    px_credit_rating_rec.debarments_count:=  p_credit_rating_obj.debarments_count;
    px_credit_rating_rec.debarments_date:=  p_credit_rating_obj.debarments_date;
    px_credit_rating_rec.high_credit:=  p_credit_rating_obj.high_credit;
    px_credit_rating_rec.maximum_credit_currency_code:=  p_credit_rating_obj.maximum_credit_currency_code;
    px_credit_rating_rec.maximum_credit_rcmd:=  p_credit_rating_obj.maximum_credit_rcmd;
    px_credit_rating_rec.paydex_norm:=  p_credit_rating_obj.paydex_norm;
    px_credit_rating_rec.paydex_score:=  p_credit_rating_obj.paydex_score;
    px_credit_rating_rec.paydex_three_months_ago:=  p_credit_rating_obj.paydex_three_months_ago;
    px_credit_rating_rec.credit_score_override_code:=  p_credit_rating_obj.credit_score_override_code;
    px_credit_rating_rec.cr_scr_clas_expl:=  p_credit_rating_obj.cr_scr_clas_expl;
    px_credit_rating_rec.low_rng_delq_scr:=  p_credit_rating_obj.low_rng_delq_scr;
    px_credit_rating_rec.high_rng_delq_scr:=  p_credit_rating_obj.high_rng_delq_scr;
    px_credit_rating_rec.delq_pmt_rng_prcnt:=  p_credit_rating_obj.delq_pmt_rng_prcnt;
    px_credit_rating_rec.delq_pmt_pctg_for_all_firms:=  p_credit_rating_obj.delq_pmt_pctg_for_all_firms;
    px_credit_rating_rec.num_trade_experiences:=  p_credit_rating_obj.num_trade_experiences;
    px_credit_rating_rec.paydex_firm_days:=  p_credit_rating_obj.paydex_firm_days;
    px_credit_rating_rec.paydex_firm_comment:=  p_credit_rating_obj.paydex_firm_comment;
    px_credit_rating_rec.paydex_industry_days:=  p_credit_rating_obj.paydex_industry_days;
    px_credit_rating_rec.paydex_industry_comment:=  p_credit_rating_obj.paydex_industry_comment;
    px_credit_rating_rec.paydex_comment:=  p_credit_rating_obj.paydex_comment;
    IF(p_credit_rating_obj.suit_ind in ('Y','N')) THEN
      px_credit_rating_rec.suit_ind:=  p_credit_rating_obj.suit_ind;
    END IF;
    IF(p_credit_rating_obj.lien_ind in ('Y','N')) THEN
      px_credit_rating_rec.lien_ind:=  p_credit_rating_obj.lien_ind;
    END IF;
    IF(p_credit_rating_obj.judgement_ind in ('Y','N')) THEN
      px_credit_rating_rec.judgement_ind:=  p_credit_rating_obj.judgement_ind;
    END IF;
    px_credit_rating_rec.bankruptcy_ind:=  p_credit_rating_obj.bankruptcy_ind;
    IF(p_credit_rating_obj.no_trade_ind in ('Y','N')) THEN
      px_credit_rating_rec.no_trade_ind:=  p_credit_rating_obj.no_trade_ind;
    END IF;
    px_credit_rating_rec.prnt_hq_bkcy_ind:=  p_credit_rating_obj.prnt_hq_bkcy_ind;
    px_credit_rating_rec.num_prnt_bkcy_filing:=  p_credit_rating_obj.num_prnt_bkcy_filing;
    px_credit_rating_rec.prnt_bkcy_filg_type:=  p_credit_rating_obj.prnt_bkcy_filg_type;
    px_credit_rating_rec.prnt_bkcy_filg_chapter:=  p_credit_rating_obj.prnt_bkcy_filg_chapter;
    px_credit_rating_rec.prnt_bkcy_filg_date:=  p_credit_rating_obj.prnt_bkcy_filg_date;
    px_credit_rating_rec.num_prnt_bkcy_convs:=  p_credit_rating_obj.num_prnt_bkcy_convs;
    px_credit_rating_rec.prnt_bkcy_conv_date:=  p_credit_rating_obj.prnt_bkcy_conv_date;
    px_credit_rating_rec.prnt_bkcy_chapter_conv:=  p_credit_rating_obj.prnt_bkcy_chapter_conv;
    px_credit_rating_rec.slow_trade_expl:=  p_credit_rating_obj.slow_trade_expl;
    px_credit_rating_rec.negv_pmt_expl:=  p_credit_rating_obj.negv_pmt_expl;
    px_credit_rating_rec.pub_rec_expl:=  p_credit_rating_obj.pub_rec_expl;
    px_credit_rating_rec.business_discontinued:=  p_credit_rating_obj.business_discontinued;
    px_credit_rating_rec.spcl_event_comment:=  p_credit_rating_obj.spcl_event_comment;
    px_credit_rating_rec.num_spcl_event:=  p_credit_rating_obj.num_spcl_event;
    px_credit_rating_rec.spcl_event_update_date:=  p_credit_rating_obj.spcl_event_update_date;
    px_credit_rating_rec.spcl_evnt_txt:=  p_credit_rating_obj.spcl_evnt_txt;
    px_credit_rating_rec.actual_content_source:=  p_credit_rating_obj.actual_content_source;
    px_credit_rating_rec.created_by_module:= HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
  END assign_credit_rating_rec;

  -- PRIVATE PROCEDURE assign_financial_report_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from financial report object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_fin_report_obj     Financial report object.
  --     p_party_id           Party Id.
  --   IN/OUT:
  --     px_fin_report_rec    Financial report plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_financial_report_rec(
    p_fin_report_obj                   IN            HZ_FINANCIAL_BO,
    p_party_id                         IN            NUMBER,
    px_fin_report_rec                  IN OUT NOCOPY HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_REPORT_REC_TYPE
  ) IS
  BEGIN
    px_fin_report_rec.financial_report_id       := p_fin_report_obj.financial_report_id;
    px_fin_report_rec.party_id                  := p_party_id;
    px_fin_report_rec.type_of_financial_report  := p_fin_report_obj.type_of_financial_report;
    px_fin_report_rec.document_reference        := p_fin_report_obj.document_reference;
    px_fin_report_rec.date_report_issued        := p_fin_report_obj.date_report_issued;
    px_fin_report_rec.issued_period             := p_fin_report_obj.issued_period;
    px_fin_report_rec.report_start_date         := p_fin_report_obj.report_start_date;
    px_fin_report_rec.report_end_date           := p_fin_report_obj.report_end_date;
    px_fin_report_rec.requiring_authority       := p_fin_report_obj.requiring_authority;
    IF(p_fin_report_obj.audit_ind in ('Y','N')) THEN
      px_fin_report_rec.audit_ind                 := p_fin_report_obj.audit_ind;
    END IF;
    IF(p_fin_report_obj.consolidated_ind in ('Y','N')) THEN
      px_fin_report_rec.consolidated_ind          := p_fin_report_obj.consolidated_ind;
    END IF;
    IF(p_fin_report_obj.estimated_ind in ('Y','N')) THEN
      px_fin_report_rec.estimated_ind             := p_fin_report_obj.estimated_ind;
    END IF;
    IF(p_fin_report_obj.fiscal_ind in ('Y','N')) THEN
      px_fin_report_rec.fiscal_ind                := p_fin_report_obj.fiscal_ind;
    END IF;
    IF(p_fin_report_obj.final_ind in ('Y','N')) THEN
      px_fin_report_rec.final_ind                 := p_fin_report_obj.final_ind;
    END IF;
    IF(p_fin_report_obj.forecast_ind in ('Y','N')) THEN
      px_fin_report_rec.forecast_ind              := p_fin_report_obj.forecast_ind;
    END IF;
    IF(p_fin_report_obj.opening_ind in ('Y','N')) THEN
      px_fin_report_rec.opening_ind               := p_fin_report_obj.opening_ind;
    END IF;
    IF(p_fin_report_obj.proforma_ind in ('Y','N')) THEN
      px_fin_report_rec.proforma_ind              := p_fin_report_obj.proforma_ind;
    END IF;
    IF(p_fin_report_obj.qualified_ind in ('Y','N')) THEN
      px_fin_report_rec.qualified_ind             := p_fin_report_obj.qualified_ind;
    END IF;
    IF(p_fin_report_obj.restated_ind in ('Y','N')) THEN
      px_fin_report_rec.restated_ind              := p_fin_report_obj.restated_ind;
    END IF;
    IF(p_fin_report_obj.signed_by_principals_ind in ('Y','N')) THEN
      px_fin_report_rec.signed_by_principals_ind  := p_fin_report_obj.signed_by_principals_ind;
    END IF;
    IF(p_fin_report_obj.trial_balance_ind in ('Y','N')) THEN
      px_fin_report_rec.trial_balance_ind         := p_fin_report_obj.trial_balance_ind;
    END IF;
    IF(p_fin_report_obj.unbalanced_ind in ('Y','N')) THEN
      px_fin_report_rec.unbalanced_ind            := p_fin_report_obj.unbalanced_ind;
    END IF;
    IF(p_fin_report_obj.status in ('A','I')) THEN
      px_fin_report_rec.status                    := p_fin_report_obj.status;
    END IF;
    px_fin_report_rec.created_by_module         := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
  END assign_financial_report_rec;

  -- PRIVATE PROCEDURE assign_financial_number_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from financial number object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_fin_number_obj     Financial number object.
  --     p_fin_report_id      Financial report Id.
  --   IN/OUT:
  --     px_fin_number_rec    Financial number plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_financial_number_rec(
    p_fin_number_obj                   IN            HZ_FINANCIAL_NUMBER_OBJ,
    p_fin_report_id                    IN            NUMBER,
    px_fin_number_rec                  IN OUT NOCOPY HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_NUMBER_REC_TYPE
  ) IS
  BEGIN
    px_fin_number_rec.financial_number_id       := p_fin_number_obj.financial_number_id;
    px_fin_number_rec.financial_report_id       := p_fin_report_id;
    px_fin_number_rec.financial_number          := p_fin_number_obj.financial_number;
    px_fin_number_rec.financial_number_name     := p_fin_number_obj.financial_number_name;
    px_fin_number_rec.financial_units_applied   := p_fin_number_obj.financial_units_applied;
    px_fin_number_rec.financial_number_currency := p_fin_number_obj.financial_number_currency;
    px_fin_number_rec.projected_actual_flag     := p_fin_number_obj.projected_actual_flag;
    IF(p_fin_number_obj.status in ('A','I')) THEN
      px_fin_number_rec.status                    := p_fin_number_obj.status;
    END IF;
    px_fin_number_rec.created_by_module         := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
  END assign_financial_number_rec;

  -- PRIVATE PROCEDURE create_credit_ratings
  --
  -- DESCRIPTION
  --     Create credit ratings.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_credit_rating_objs List of credit rating objects.
  --     p_organization_id    Organization Id.
  --   OUT:
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE create_credit_ratings(
    p_credit_rating_objs  IN OUT NOCOPY HZ_CREDIT_RATING_OBJ_TBL,
    p_organization_id     IN         NUMBER,
    x_return_status       OUT NOCOPY VARCHAR2,
    x_msg_count           OUT NOCOPY NUMBER,
    x_msg_data            OUT NOCOPY VARCHAR2
  ) IS
    l_debug_prefix        VARCHAR2(30);
    l_credit_rating_rec   HZ_PARTY_INFO_V2PUB.CREDIT_RATING_REC_TYPE;
    l_dummy_id            NUMBER;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_credit_ratings_pub;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_credit_ratings(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
	
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(+)XX_CDH_PARTY_BO_PVT.create_credit_ratings(+)');

    --------------------------------
    -- Assign credit rating record
    --------------------------------
    FOR i IN 1..p_credit_rating_objs.COUNT LOOP
      assign_credit_rating_rec(
        p_credit_rating_obj         => p_credit_rating_objs(i),
        p_party_id                  => p_organization_id,
        px_credit_rating_rec        => l_credit_rating_rec
      );

      HZ_PARTY_INFO_V2PUB.create_credit_rating(
        p_credit_rating_rec         => l_credit_rating_rec,
        x_credit_rating_id          => l_dummy_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
          hz_utility_v2pub.debug(p_message=>'Error occurred at hz_organization_bo_pub.create_credit_ratings, organization id: '||p_organization_id,
                                 p_prefix=>l_debug_prefix,
                                 p_msg_level=>fnd_log.level_procedure);
        END IF;
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_credit_ratings'              
            , p_bo_table_name          =>  'HZ_CREDIT_RATINGS'        
            , p_bo_column_name         =>  'CREDIT_RATING_ID'       
            , p_bo_column_value        =>  l_dummy_id       
            , p_orig_system            =>  null
            , p_orig_system_reference  =>  null
            , p_exception_log          =>  'Exception in XX_CDH_PARTY_BO_PVT.create_credit_ratings, organization id: '||p_organization_id    
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );		
      END IF;

      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_CREDIT_RATINGS',
           p_bo_table_id            =>  p_organization_id,
           p_orig_system            =>  null,          
           p_orig_system_reference  =>  null
        );
      END IF;

      -- assign credit_rating_id
      p_credit_rating_objs(i).credit_rating_id := l_dummy_id;
    END LOOP;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)XX_CDH_PARTY_BO_PVT.create_credit_ratings(-)');
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_credit_ratings_pub;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
      FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_CREDIT_RATINGS');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_credit_ratings_pub;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
      FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_CREDIT_RATINGS');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN OTHERS THEN
      ROLLBACK TO create_credit_ratings_pub;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
      FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_CREDIT_RATINGS');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END create_credit_ratings;

  -- PRIVATE PROCEDURE save_credit_ratings
  --
  -- DESCRIPTION
  --     Create or update credit ratings.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_credit_rating_objs List of credit rating objects.
  --     p_organization_id    Organization Id.
  --   OUT:
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE save_credit_ratings(
    p_credit_rating_objs  IN OUT NOCOPY HZ_CREDIT_RATING_OBJ_TBL,
    p_organization_id     IN         NUMBER,
    x_return_status       OUT NOCOPY VARCHAR2,
    x_msg_count           OUT NOCOPY NUMBER,
    x_msg_data            OUT NOCOPY VARCHAR2
  ) IS
    l_debug_prefix        VARCHAR2(30);
    l_credit_rating_rec   HZ_PARTY_INFO_V2PUB.CREDIT_RATING_REC_TYPE;
    l_dummy_id            NUMBER;
    l_ovn                 NUMBER := NULL;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT save_credit_ratings_pub;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_credit_ratings(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(+)XX_CDH_PARTY_BO_PVT.save_credit_ratings(+)');
    --------------------------------
    -- Create/Update credit rating
    --------------------------------
    FOR i IN 1..p_credit_rating_objs.COUNT LOOP
      assign_credit_rating_rec(
        p_credit_rating_obj         => p_credit_rating_objs(i),
        p_party_id                  => p_organization_id,
        px_credit_rating_rec        => l_credit_rating_rec
      );

      hz_registry_validate_bo_pvt.check_credit_rating_op(
        p_party_id            => p_organization_id,
        px_credit_rating_id   => l_credit_rating_rec.credit_rating_id,
        p_rating_organization => l_credit_rating_rec.rating_organization,
        p_rated_as_of_date    => l_credit_rating_rec.rated_as_of_date,
        x_object_version_number => l_ovn
      );

      IF(l_ovn = -1) THEN
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
          hz_utility_v2pub.debug(p_message=>'Save Credit Ratings - Error occurred at hz_organization_bo_pub.check_credit_rating_op, organization id: '||p_organization_id||' '||' ovn:'||l_ovn,
                                 p_prefix=>l_debug_prefix,
                                 p_msg_level=>fnd_log.level_procedure);
        END IF;
        FND_MESSAGE.SET_NAME('AR', 'HZ_API_INVALID_ID');
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      IF(l_credit_rating_rec.credit_rating_id IS NULL) THEN
        HZ_PARTY_INFO_V2PUB.create_credit_rating(
          p_credit_rating_rec         => l_credit_rating_rec,
          x_credit_rating_id          => l_dummy_id,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data
        );

        -- assign credit_rating_id
        p_credit_rating_objs(i).credit_rating_id := l_dummy_id;
      ELSE
        -- clean up created_by_module for update
        l_credit_rating_rec.created_by_module := NULL;
        HZ_PARTY_INFO_V2PUB.update_credit_rating(
          p_credit_rating_rec         => l_credit_rating_rec,
          p_object_version_number     => l_ovn,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data
        );

        -- assign credit_rating_id
        p_credit_rating_objs(i).credit_rating_id := l_credit_rating_rec.credit_rating_id;
      END IF;

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
          hz_utility_v2pub.debug(p_message=>'Error occurred at hz_organization_bo_pub.update_credit_rating, organization id: '||p_organization_id,
                                 p_prefix=>l_debug_prefix,
                                 p_msg_level=>fnd_log.level_procedure);
        END IF;
         --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
            , p_procedure_name         =>  'update_credit_rating'              
            , p_bo_table_name          =>  'HZ_CREDIT_RATINGS'        
            , p_bo_column_name         =>  'CREDIT_RATING_ID'       
            , p_bo_column_value        =>  l_dummy_id       
            , p_orig_system            =>  null
            , p_orig_system_reference  =>  null
            , p_exception_log          =>  'Exception in XX_CDH_PARTY_BO_PVT.update_credit_rating, organization id: '||p_organization_id    
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );		
      END IF;

      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_CREDIT_RATINGS',
           p_bo_table_id            =>  p_organization_id,
           p_orig_system            =>  null,          
           p_orig_system_reference  =>  null
        );
      END IF;
    END LOOP;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_credit_rating(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)XX_CDH_PARTY_BO_PVT.save_credit_ratings(-)');
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO save_credit_ratings_pub;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
      FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_CREDIT_RATINGS');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO save_credit_ratings_pub;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
      FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_CREDIT_RATINGS');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN OTHERS THEN
      ROLLBACK TO save_credit_ratings_pub;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
      FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_CREDIT_RATINGS');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_credit_ratings(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END save_credit_ratings;

  -- PRIVATE PROCEDURE create_financial_reports
  --
  -- DESCRIPTION
  --     Create financial reports.
  PROCEDURE create_financial_reports(
    p_fin_objs            IN OUT NOCOPY HZ_FINANCIAL_BO_TBL,
    p_organization_id     IN         NUMBER,
    x_return_status       OUT NOCOPY VARCHAR2,
    x_msg_count           OUT NOCOPY NUMBER,
    x_msg_data            OUT NOCOPY VARCHAR2
  ) IS
    l_debug_prefix        VARCHAR2(30);
    l_fin_report_rec      HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_REPORT_REC_TYPE;
    l_fin_number_rec      HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_NUMBER_REC_TYPE;
    l_dummy_id            NUMBER;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_credit_ratings_pub;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_financial_reports(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(+)XX_CDH_PARTY_BO_PVT.create_financial_reports(+)');

    ---------------------------------
    -- Assign financial report record
    ---------------------------------
    FOR i IN 1..p_fin_objs.COUNT LOOP
      assign_financial_report_rec(
        p_fin_report_obj            => p_fin_objs(i),
        p_party_id                  => p_organization_id,
        px_fin_report_rec           => l_fin_report_rec
      );

      HZ_ORGANIZATION_INFO_V2PUB.create_financial_report(
        p_financial_report_rec      => l_fin_report_rec,
        x_financial_report_id       => l_dummy_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
          hz_utility_v2pub.debug(p_message=>'Error occurred at hz_organization_bo_pub.create_financial_reports, org id: '||p_organization_id,
                                 p_prefix=>l_debug_prefix,
                                 p_msg_level=>fnd_log.level_procedure);
        END IF;
        FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_STRUCT_ERROR');
        FND_MESSAGE.SET_TOKEN('STRUCTURE', 'HZ_FINANCIAL_REPORTS');
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSE
        -- assign financial_number_id
        p_fin_objs(i).financial_report_id := l_dummy_id;

        -- Call financial number v2api if financial report record is created successfully
        -------------------------------------------------
        -- Assign financial number of financial report record
        -------------------------------------------------
        FOR j IN 1..p_fin_objs(i).financial_number_objs.COUNT LOOP
          assign_financial_number_rec(
            p_fin_number_obj            => p_fin_objs(i).financial_number_objs(j),
            p_fin_report_id             => l_dummy_id,
            px_fin_number_rec           => l_fin_number_rec
          );

          HZ_ORGANIZATION_INFO_V2PUB.create_financial_number(
            p_financial_number_rec      => l_fin_number_rec,
            x_financial_number_id       => l_dummy_id,
            x_return_status             => x_return_status,
            x_msg_count                 => x_msg_count,
            x_msg_data                  => x_msg_data
          );

          IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
              hz_utility_v2pub.debug(p_message=>'Error occurred at hz_organization_bo_pub.create_financial_reports, fin_number_id: '||l_dummy_id,
                                     p_prefix=>l_debug_prefix,
                                     p_msg_level=>fnd_log.level_procedure);
            END IF;
            FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
            FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_FINANCIAL_NUMBERS');
            FND_MSG_PUB.ADD;
            --RAISE FND_API.G_EXC_ERROR;
            XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
                  p_bo_process_id          =>  0        
                , p_bpel_process_id        =>  0       
                , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
                , p_log_date               =>  SYSDATE             
                , p_logged_by              =>  FND_GLOBAL.user_id                    
                , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
                , p_procedure_name         =>  'create_financial_reports'              
                , p_bo_table_name          =>  'HZ_FINANCIAL_NUMBERS'        
                , p_bo_column_name         =>  'FINANCIAL_NUMBER_ID'       
                , p_bo_column_value        =>  l_dummy_id       
                , p_orig_system            =>  null
                , p_orig_system_reference  =>  null
                , p_exception_log          =>  'Exception in XX_CDH_PARTY_BO_PVT.create_financial_reports, organization id: '||p_organization_id    
                , p_oracle_error_code      =>  null    
                , p_oracle_error_msg       =>  null 
            );
          END IF;

          IF x_return_status = 'S' THEN     
		    --save p_organization_id into GT table
		    XX_CDH_CUST_UTIL_BO_PVT.save_gt(
		       p_bo_process_id          =>  0,
		       p_bo_entity_name         =>  'HZ_FINANCIAL_NUMBERS',
		       p_bo_table_id            =>  p_organization_id,
		       p_orig_system            =>  null,          
		       p_orig_system_reference  =>  null
		    );
		  END IF;

          -- assign financial_number_id
          p_fin_objs(i).financial_number_objs(j).financial_number_id := l_dummy_id;
        END LOOP;
      END IF;
    END LOOP;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)XX_CDH_PARTY_BO_PVT.create_financial_reports(-)');
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_financial_reports_pub;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_financial_reports_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN OTHERS THEN
      ROLLBACK TO create_financial_reports_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END create_financial_reports;

  -- PRIVATE PROCEDURE save_financial_reports
  --
  -- DESCRIPTION
  --     Create or update financial reports.
  PROCEDURE save_financial_reports(
    p_fin_objs            IN OUT NOCOPY HZ_FINANCIAL_BO_TBL,
    p_organization_id     IN         NUMBER,
    x_return_status       OUT NOCOPY VARCHAR2,
    x_msg_count           OUT NOCOPY NUMBER,
    x_msg_data            OUT NOCOPY VARCHAR2
  ) IS
    l_debug_prefix        VARCHAR2(30);
    l_fin_report_rec      HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_REPORT_REC_TYPE;
    l_fin_number_rec      HZ_ORGANIZATION_INFO_V2PUB.FINANCIAL_NUMBER_REC_TYPE;
    l_dummy_id            NUMBER;
    l_ovn                 NUMBER := NULL;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT save_credit_ratings_pub;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_financial_reports(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -----------------------------------
    -- Create/Update financial reports
    -----------------------------------
    FOR i IN 1..p_fin_objs.COUNT LOOP
      assign_financial_report_rec(
        p_fin_report_obj            => p_fin_objs(i),
        p_party_id                  => p_organization_id,
        px_fin_report_rec           => l_fin_report_rec
      );

      hz_registry_validate_bo_pvt.check_fin_report_op(
        p_party_id            => p_organization_id,
        px_fin_report_id      => l_fin_report_rec.financial_report_id,
        p_type_of_financial_report  => l_fin_report_rec.type_of_financial_report,
        p_document_reference  => l_fin_report_rec.document_reference,
        p_date_report_issued  => l_fin_report_rec.date_report_issued,
        p_issued_period       => l_fin_report_rec.issued_period,
        x_object_version_number => l_ovn
      );

      IF(l_ovn = -1) THEN
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
          hz_utility_v2pub.debug(p_message=>'Save Financial Report - Error occurred at hz_organization_bo_pub.check_fin_report_op, organization id: '||p_organization_id||' '||' ovn:'||l_ovn,
                                 p_prefix=>l_debug_prefix,
                                 p_msg_level=>fnd_log.level_procedure);
        END IF;
        FND_MESSAGE.SET_NAME('AR', 'HZ_API_INVALID_ID');
        FND_MSG_PUB.ADD;
        FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_STRUCT_ERROR');
        FND_MESSAGE.SET_TOKEN('STRUCTURE', 'HZ_FINANCIAL_REPORTS');
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      IF(l_fin_report_rec.financial_report_id IS NULL) THEN
        HZ_ORGANIZATION_INFO_V2PUB.create_financial_report(
          p_financial_report_rec      => l_fin_report_rec,
          x_financial_report_id       => l_dummy_id,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data
        );

        -- assign financial_report_id
        p_fin_objs(i).financial_report_id := l_dummy_id;
      ELSE
        -- clean up created_by_module for update
        l_fin_report_rec.created_by_module := NULL;
        HZ_ORGANIZATION_INFO_V2PUB.update_financial_report(
          p_financial_report_rec      => l_fin_report_rec,
          p_object_version_number     => l_ovn,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data
        );
        l_dummy_id := l_fin_report_rec.financial_report_id;

        -- assign financial_report_id
        p_fin_objs(i).financial_report_id := l_dummy_id;
      END IF;

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
          hz_utility_v2pub.debug(p_message=>'Error occurred at hz_organization_bo_pub.save_financial_reports, org id: '||p_organization_id,
                                 p_prefix=>l_debug_prefix,
                                 p_msg_level=>fnd_log.level_procedure);
        END IF;
        FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_STRUCT_ERROR');
        FND_MESSAGE.SET_TOKEN('STRUCTURE', 'HZ_FINANCIAL_REPORTS');
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      ELSE
        ---------------------------------
        -- Create/Update financial number
        ---------------------------------
        FOR j IN 1..p_fin_objs(i).financial_number_objs.COUNT LOOP
          assign_financial_number_rec(
            p_fin_number_obj            => p_fin_objs(i).financial_number_objs(j),
            p_fin_report_id             => l_dummy_id,
            px_fin_number_rec           => l_fin_number_rec
          );

          hz_registry_validate_bo_pvt.check_fin_number_op(
            p_fin_report_id       => l_dummy_id,
            px_fin_number_id      => l_fin_number_rec.financial_number_id,
            p_financial_number_name => l_fin_number_rec.financial_number_name,
            x_object_version_number => l_ovn
          );

          IF(l_ovn = -1) THEN
            IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
              hz_utility_v2pub.debug(p_message=>'Save Financial Number - Error occurred at hz_organization_bo_pub.check_fin_number_op, organization id: '||p_organization_id||' '||' ovn:'||l_ovn,
                                     p_prefix=>l_debug_prefix,
                                     p_msg_level=>fnd_log.level_procedure);
            END IF;
            FND_MESSAGE.SET_NAME('AR', 'HZ_API_INVALID_ID');
            FND_MSG_PUB.ADD;
            FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
            FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_FINANCIAL_NUMBERS');
            FND_MSG_PUB.ADD;
            RAISE FND_API.G_EXC_ERROR;
          END IF;

          IF(l_fin_number_rec.financial_number_id IS NULL) THEN
            HZ_ORGANIZATION_INFO_V2PUB.create_financial_number(
              p_financial_number_rec      => l_fin_number_rec,
              x_financial_number_id       => l_dummy_id,
              x_return_status             => x_return_status,
              x_msg_count                 => x_msg_count,
              x_msg_data                  => x_msg_data
            );

            -- assign financial_number_id
            p_fin_objs(i).financial_number_objs(j).financial_number_id := l_dummy_id;
          ELSE
            -- clean up created_by_module for update
            l_fin_number_rec.created_by_module := NULL;
            HZ_ORGANIZATION_INFO_V2PUB.update_financial_number(
              p_financial_number_rec      => l_fin_number_rec,
              p_object_version_number     => l_ovn,
              x_return_status             => x_return_status,
              x_msg_count                 => x_msg_count,
              x_msg_data                  => x_msg_data
            );

            -- assign financial_number_id
            p_fin_objs(i).financial_number_objs(j).financial_number_id := l_fin_number_rec.financial_number_id;
          END IF;
          IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
            IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
              hz_utility_v2pub.debug(p_message=>'Error occurred at hz_organization_bo_pub.save_financial_reports, fin_number_id: '||l_dummy_id,
                                     p_prefix=>l_debug_prefix,
                                     p_msg_level=>fnd_log.level_procedure);
            END IF;
            FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_ENTITY_ERROR');
            FND_MESSAGE.SET_TOKEN('ENTITY', 'HZ_FINANCIAL_NUMBERS');
            FND_MSG_PUB.ADD;
            RAISE FND_API.G_EXC_ERROR;
          END IF;
        END LOOP;
      END IF;
    END LOOP;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO save_financial_reports_pub;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO save_financial_reports_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN OTHERS THEN
      ROLLBACK TO save_financial_reports_pub;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'save_financial_reports(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END save_financial_reports;

  -- PROCEDURE create_classifications
  --
  -- DESCRIPTION
  --     Create classifications.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_code_assign_objs   List of classification objects.
  -- PROCEDURE create_classifications
  --
  -- DESCRIPTION
  --     Create classifications.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_code_assign_objs   List of classification objects.
  --     p_owner_table_name   Owner table name.
  --     p_owner_table_id     Owner table Id.
  --   OUT:
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.
  --

PROCEDURE create_classifications(
   p_code_assign_objs       IN           hz_code_assignment_obj_tbl,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,  
   p_owner_table_name       IN           VARCHAR2,
   p_owner_table_id         IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2,
   x_return_status          OUT   NOCOPY VARCHAR2,
   x_msg_count              OUT   NOCOPY NUMBER,
   x_msg_data               OUT   NOCOPY VARCHAR2
)IS
    l_debug_prefix        VARCHAR2(30);
    l_code_assign_id      NUMBER :=0;
    ln_code_assign_id      NUMBER :=0;
    l_code_assign_rec     HZ_CLASSIFICATION_V2PUB.CODE_ASSIGNMENT_REC_TYPE;
    l_return_status            VARCHAR2(30);
    l_msg_count                NUMBER;
    l_msg_data                 VARCHAR2(2000);
    l_create_update_flag       VARCHAR2(1);
    l_debug_prefix             VARCHAR2(30) := '';
    l_orig_system              VARCHAR2(30)  := p_orig_system;
    l_orig_system_reference    VARCHAR2(255) := p_orig_system_reference;
    
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_classifications_pvt;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_PVT.create_classifications(+)');

    -- Create code assignments
    FOR i IN 1..p_code_assign_objs.COUNT LOOP
      
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '--' || i || '--' || p_code_assign_objs(i).class_category || '--' || p_code_assign_objs(i).class_code);
      assign_code_assign_rec(
        p_code_assign_obj    => p_code_assign_objs(i),
        p_owner_table_name   => p_owner_table_name,
        p_owner_table_id     => p_owner_table_id,
        px_code_assign_rec   => l_code_assign_rec
      );
	  l_code_assign_rec.created_by_module := p_created_by_module;
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '--' || i || '--' || l_code_assign_rec.class_category || '--' || l_code_assign_rec.class_code);

      HZ_CLASSIFICATION_V2PUB.create_code_assignment(
        p_code_assignment_rec       => l_code_assign_rec,
        x_code_assignment_id        => l_code_assign_id,
        x_return_status             => l_return_status,
        x_msg_count                 => l_msg_count,
        x_msg_data                  => l_msg_data
      );

      XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '--l_return_status--' || l_return_status);

      IF l_return_status = 'S' THEN

        --save l_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
            p_bo_process_id          =>  p_bo_process_id,
            p_bo_entity_name         =>  'HZ_CODE_ASSIGNMENTS',
            p_bo_table_id            =>  l_code_assign_id,
            p_orig_system            =>  l_orig_system,          
            p_orig_system_reference  =>  l_orig_system_reference
        );
      
      ELSE
        --call exception process
        l_msg_data := null;
        FOR i IN 1 .. l_msg_count
        LOOP
           l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
        END LOOP;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
               p_bo_process_id          =>  p_BO_PROCESS_ID        
             , p_bpel_process_id        =>  p_bpel_process_id       
             , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
             , p_log_date               =>  SYSDATE             
             , p_logged_by              =>  FND_GLOBAL.user_id                    
             , p_package_name           =>  'XX_CDH_PARTY_BO_WRAP_PVT'            
             , p_procedure_name         =>  'save_cust_accounts'              
             , p_bo_table_name          =>  'HZ_CODE_ASSIGNMENTS'        
             , p_bo_column_name         =>  'CODE_ASSIGNMENT_ID'       
             , p_bo_column_value        =>  l_code_assign_id       
             , p_orig_system            =>  l_orig_system
             , p_orig_system_reference  =>  l_orig_system_reference
             , p_exception_log          =>  'Exception in create_classifications '  || l_msg_data      
             , p_oracle_error_code      =>  null    
             , p_oracle_error_msg       =>  null 
         ); 
        RAISE FND_API.G_EXC_ERROR;
      END IF;    

      -- assign code_assignment_id
      --p_code_assign_objs(i).code_assignment_id := ln_code_assign_id;
    END LOOP;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_PVT.create_classifications(-)');  

    EXCEPTION
      WHEN OTHERS THEN
      ROLLBACK to create_classifications_pvt;
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  p_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_PARTY_BO_WRAP_PVT'            
          , p_procedure_name         =>  'create_classifications'              
          , p_bo_table_name          =>  'HZ_CODE_ASSIGNMENTS'        
          , p_bo_column_name         =>  'CODE_ASSIGNMENT_ID'       
          , p_bo_column_value        =>  l_code_assign_id       
          , p_orig_system            =>  l_orig_system
          , p_orig_system_reference  =>  l_orig_system_reference
          , p_exception_log          =>  'Exception in create_classifications '  || SQLERRM       
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      ); 
      L_RETURN_STATUS := 'E';   
      l_msg_data        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts'  || SQLERRM;
    END create_classifications;

  -- PROCEDURE save_classifications
  --
  -- DESCRIPTION
  --     Create or update classifications.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_code_assign_objs   List of classification objects.
  --     p_owner_table_name   Owner table name.
  --     p_owner_table_id     Owner table Id.
  --   OUT:
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.
  --

PROCEDURE save_classifications(
   p_code_assign_objs       IN           hz_code_assignment_obj_tbl,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,  
   p_owner_table_name       IN           VARCHAR2,
   p_owner_table_id         IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2,
   x_return_status          OUT   NOCOPY VARCHAR2,
   x_msg_count              OUT   NOCOPY NUMBER,
   x_msg_data               OUT   NOCOPY VARCHAR2
) IS

    l_debug_prefix             VARCHAR2(30);
    l_code_assign_rec          HZ_CLASSIFICATION_V2PUB.CODE_ASSIGNMENT_REC_TYPE;
    l_return_status            VARCHAR2(30);
    l_msg_count                NUMBER;
    l_msg_data                 VARCHAR2(2000);
    l_create_update_flag       VARCHAR2(1);
                               
    l_code_assign_id           NUMBER := 0;
    ln_code_assign_id          NUMBER := 0;
    l_ovn                      NUMBER := NULL;
    l_orig_system              VARCHAR2(30)  := p_orig_system;
    l_orig_system_reference    VARCHAR2(255) := p_orig_system_reference;
    
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT save_classifications_pvt;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.save_classifications(+)');

    -- Create/Update classification
    FOR i IN 1..p_code_assign_objs.COUNT LOOP
      
      assign_code_assign_rec(
        p_code_assign_obj    => p_code_assign_objs(i),
        p_owner_table_name   => p_owner_table_name,
        p_owner_table_id     => p_owner_table_id,
        px_code_assign_rec   => l_code_assign_rec
      );

      -- check if the code assignment record is create or update
      hz_registry_validate_bo_pvt.check_code_assign_op(
        p_owner_table_name    => p_owner_table_name,
        p_owner_table_id      => p_owner_table_id,
        px_code_assignment_id => l_code_assign_rec.code_assignment_id,
        p_class_category      => l_code_assign_rec.class_category,
        p_class_code          => l_code_assign_rec.class_code,
        x_object_version_number => l_ovn
      );

      IF (l_ovn = -1) THEN

        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  p_BO_PROCESS_ID        
            , p_bpel_process_id        =>  p_bpel_process_id       
            , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_WRAP_PVT'            
            , p_procedure_name         =>  'save_classifications'              
            , p_bo_table_name          =>  'HZ_CODE_ASSIGNMENTS'        
            , p_bo_column_name         =>  'CODE_ASSIGNMENT_ID'       
            , p_bo_column_value        =>  l_code_assign_id       
            , p_orig_system            =>  l_orig_system
            , p_orig_system_reference  =>  l_orig_system_reference
            , p_exception_log          =>  'Exception in save_classifications - Object Version Number is -1'  || l_msg_data      
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );    
        RAISE FND_API.G_EXC_ERROR;
      END IF;
      l_code_assign_rec.created_by_module := p_created_by_module;
      IF(l_code_assign_rec.code_assignment_id IS NULL) THEN
        HZ_CLASSIFICATION_V2PUB.create_code_assignment(
          p_code_assignment_rec       => l_code_assign_rec,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data,
          x_code_assignment_id        => l_code_assign_id
        );

        -- assign code_assignment_id
        --p_code_assign_objs(i).code_assignment_id := l_code_assign_id;
      ELSE
        -- clean up created_by_module for update
        l_code_assign_rec.created_by_module := NULL;
        HZ_CLASSIFICATION_V2PUB.update_code_assignment(
          p_code_assignment_rec       => l_code_assign_rec,
          p_object_version_number     => l_ovn,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data
        );

        -- assign code_assignment_id
        --p_code_assign_objs(i).code_assignment_id := l_code_assign_rec.code_assignment_id;
      END IF;

      IF l_return_status = 'S' THEN

        --save l_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
            p_bo_process_id          =>  p_bo_process_id,
            p_bo_entity_name         =>  'HZ_CODE_ASSIGNMENTS',
            p_bo_table_id            =>  l_code_assign_id,
            p_orig_system            =>  l_orig_system,          
            p_orig_system_reference  =>  l_orig_system_reference
        );
      
      ELSE
        --call exception process
        l_msg_data := null;
        FOR i IN 1 .. l_msg_count
        LOOP
           l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
        END LOOP;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  p_BO_PROCESS_ID        
            , p_bpel_process_id        =>  p_bpel_process_id       
            , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_WRAP_PVT'            
            , p_procedure_name         =>  'save_classifications'              
            , p_bo_table_name          =>  'HZ_CODE_ASSIGNMENTS'        
            , p_bo_column_name         =>  'CODE_ASSIGNMENT_ID'       
            , p_bo_column_value        =>  l_code_assign_id       
            , p_orig_system            =>  l_orig_system
            , p_orig_system_reference  =>  l_orig_system_reference
            , p_exception_log          =>  'Exception in save_classifications '  || l_msg_data      
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        ); 
        RAISE FND_API.G_EXC_ERROR;
      END IF;    

    END LOOP;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.save_classifications(-)');
    
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK to save_classifications;
      --call exception process
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  p_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_PARTY_BO_WRAP_PVT'            
          , p_procedure_name         =>  'save_classifications'              
          , p_bo_table_name          =>  'HZ_CODE_ASSIGNMENTS'        
          , p_bo_column_name         =>  'CODE_ASSIGNMENT_ID'       
          , p_bo_column_value        =>  l_code_assign_id       
          , p_orig_system            =>  l_orig_system
          , p_orig_system_reference  =>  l_orig_system_reference
          , p_exception_log          =>  'Exception in save_classifications '  || SQLERRM       
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      ); 
      L_RETURN_STATUS := 'E';   
      l_msg_data        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts'  || SQLERRM;    
    WHEN OTHERS THEN
      --call exception process
      ROLLBACK to save_classifications;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  p_BO_PROCESS_ID        
          , p_bpel_process_id        =>  p_bpel_process_id       
          , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'XX_CDH_PARTY_BO_WRAP_PVT'            
          , p_procedure_name         =>  'save_classifications'              
          , p_bo_table_name          =>  'HZ_CODE_ASSIGNMENTS'        
          , p_bo_column_name         =>  'CODE_ASSIGNMENT_ID'       
          , p_bo_column_value        =>  l_code_assign_id       
          , p_orig_system            =>  l_orig_system
          , p_orig_system_reference  =>  l_orig_system_reference
          , p_exception_log          =>  'Exception in save_classifications '  || SQLERRM       
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      ); 
      L_RETURN_STATUS := 'E';   
      l_msg_data        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts'  || SQLERRM;
  END save_classifications;


  -- PROCEDURE create_organization_bo
  --
  -- DESCRIPTION
  --     Create organization business object.
  PROCEDURE do_create_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN OUT NOCOPY HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  ) IS
    l_debug_prefix             VARCHAR2(30);
    l_organization_rec         HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    l_profile_id               NUMBER;
    l_party_number             VARCHAR2(30);
    l_dummy_id                 NUMBER;
    l_valid_obj                BOOLEAN;
    l_bus_object               HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
    l_errorcode                NUMBER;
    l_raise_event              BOOLEAN := FALSE;
    l_cbm                      VARCHAR2(30);
    l_event_id                 NUMBER;
    l_sms_objs                 HZ_SMS_CP_BO_TBL;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_organization_bo_pub;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    IF(p_created_by_module IS NULL) THEN
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := 'BO_API';
    ELSE
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := p_created_by_module;
    END IF;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_organization_bo(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(+)XX_CDH_PARTY_BO_PVT.do_create_organization_bo(-)');

    -- Base on p_validate_bo_flag to check completeness of business object
    IF(p_validate_bo_flag = FND_API.G_TRUE) THEN
      HZ_REGISTRY_VALIDATE_BO_PVT.get_bus_obj_struct(
        p_bus_object_code         => 'ORG',
        x_bus_object              => l_bus_object
      );
      l_valid_obj := HZ_REGISTRY_VALIDATE_BO_PVT.is_org_bo_comp(
                       p_organization_obj => p_organization_obj,
                       p_bus_object       => l_bus_object
                     );
      IF NOT(l_valid_obj) THEN
        RAISE fnd_api.g_exc_error;
      END IF;

      -- find out if raise event at the end
      l_raise_event := HZ_PARTY_BO_PVT.is_raising_create_event(
                         p_obj_complete_flag => l_valid_obj );

      IF(l_raise_event) THEN
        -- get event_id and set global variable to event_id for
        -- BOT populate function
        SELECT HZ_BUS_OBJ_TRACKING_S.nextval
        INTO l_event_id
        FROM DUAL;
      END IF;
    ELSE
      l_raise_event := FALSE;
    END IF;

    x_organization_id := p_organization_obj.organization_id;
    x_organization_os := p_organization_obj.orig_system;
    x_organization_osr:= p_organization_obj.orig_system_reference;

    -- check input person party id and os+osr
    hz_registry_validate_bo_pvt.validate_ssm_id(
      px_id              => x_organization_id,
      px_os              => x_organization_os,
      px_osr             => x_organization_osr,
      p_obj_type         => 'ORGANIZATION',
      p_create_or_update => 'C',
      x_return_status    => x_return_status,
      x_msg_count        => x_msg_count,
      x_msg_data         => x_msg_data);

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    ---------------------------------------
    -- Assign organization and party record
    ---------------------------------------
    assign_organization_rec(
      p_organization_obj  => p_organization_obj,
      p_organization_id   => x_organization_id,
      p_organization_os   => x_organization_os,
      p_organization_osr  => x_organization_osr,
      px_organization_rec => l_organization_rec
    );

    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after assign_organization_rec(=)');

    HZ_PARTY_V2PUB.create_organization(
      p_organization_rec          => l_organization_rec,
      x_party_id                  => x_organization_id,
      x_party_number              => l_party_number,
      x_profile_id                => l_profile_id,
      x_return_status             => x_return_status,
      x_msg_count                 => x_msg_count,
      x_msg_data                  => x_msg_data
    );

    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after create_organization, x_return_status:' || x_return_status);

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      --RAISE FND_API.G_EXC_ERROR;

      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  0        
          , p_bpel_process_id        =>  0       
          , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'HZ_PARTY_V2PUB'            
          , p_procedure_name         =>  'create_organization'              
          , p_bo_table_name          =>  'HZ_PARTIES'        
          , p_bo_column_name         =>  'PARTY_ID'       
          , p_bo_column_value        =>  x_organization_id       
          , p_orig_system            =>  x_organization_os
          , p_orig_system_reference  =>  x_organization_osr
          , p_exception_log          =>  'Exception in calling HZ_PARTY_V2PUB.create_organization from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
          , p_oracle_error_code      =>  null    
          , p_oracle_error_msg       =>  null 
      );

    END IF;

    IF x_return_status = 'S' THEN     
      --save p_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  0,
         p_bo_entity_name         =>  'HZ_PARTIES',
         p_bo_table_id            =>  x_organization_id,
         p_orig_system            =>  x_organization_os,          
         p_orig_system_reference  =>  x_organization_osr
      );
    END IF;

    -- assign organization party_id
    p_organization_obj.organization_id := x_organization_id;
    p_organization_obj.party_number := l_party_number;
    --------------------------
    -- Create Org Ext Attrs
    --------------------------
    IF((p_organization_obj.ext_attributes_objs IS NOT NULL) AND
       (p_organization_obj.ext_attributes_objs.COUNT > 0)) THEN
      HZ_EXT_ATTRIBUTE_BO_PVT.save_ext_attributes(
        p_ext_attr_objs             => p_organization_obj.ext_attributes_objs,
        p_parent_obj_id             => l_profile_id,
        p_parent_obj_type           => 'ORG',
        p_create_or_update          => 'C',
        x_return_status             => x_return_status,
        x_errorcode                 => l_errorcode,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      --xx debug info
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after save_ext_attributes, x_return_status:' || x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_EXT_ATTRIBUTE_BO_PVT'            
            , p_procedure_name         =>  'save_ext_attributes'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_EXT_ATTRIBUTE_BO_PVT.save_ext_attributes from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Party Preferences
    ----------------------------
    IF((p_organization_obj.preference_objs IS NOT NULL) AND
       (p_organization_obj.preference_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.save_party_preferences(
        p_party_pref_objs           => p_organization_obj.preference_objs,
        p_party_id                  => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_PARTY_PREF_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_party_preferences'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.save_party_preferences from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_PARTY_PREF_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Contact Preferences
    ----------------------------
    IF((p_organization_obj.contact_pref_objs IS NOT NULL) AND
       (p_organization_obj.contact_pref_objs.COUNT > 0)) THEN
      HZ_CONTACT_PREFERENCE_BO_PVT.create_contact_preferences(
        p_cp_pref_objs           => p_organization_obj.contact_pref_objs,
        p_contact_level_table_id => x_organization_id,
        p_contact_level_table    => 'HZ_PARTIES',
        x_return_status          => x_return_status,
        x_msg_count              => x_msg_count,
        x_msg_data               => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CONTACT_PREF_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_CONTACT_PREFERENCE_BO_PVT'            
            , p_procedure_name         =>  'create_contact_preferences'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_CONTACT_PREFERENCE_BO_PVT.create_contact_preferences from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_CONTACT_PREF_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Relationship api
    ----------------------------
    IF((p_organization_obj.relationship_objs IS NOT NULL) AND
       (p_organization_obj.relationship_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.create_relationships(
        p_rel_objs                  => p_organization_obj.relationship_objs,
        p_subject_id                => x_organization_id,
        p_subject_type              => 'ORGANIZATION',
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      --xx debug info
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after create_relationships, x_return_status:' || x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_RELATIONSHIP_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_relationships'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.create_relationships from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_RELATIONSHIP_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Classification api
    ----------------------------
    IF((p_organization_obj.class_objs IS NOT NULL) AND
       (p_organization_obj.class_objs.COUNT > 0)) THEN
      /*
      HZ_PARTY_BO_PVT.create_classifications(
        p_code_assign_objs          => p_organization_obj.class_objs,
        p_owner_table_name          => 'HZ_PARTIES',
        p_owner_table_id            => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );
      */

      --create code assignments for segmentation and loyalty
      create_classifications(
          p_code_assign_objs         =>  p_organization_obj.class_objs,           
          p_bo_process_id            =>  0,                         
          p_bpel_process_id          =>  0,                       
          p_owner_table_name         =>  'HZ_PARTIES',
          p_owner_table_id           =>  x_organization_id,   
          p_orig_system              =>  x_organization_os,          
          p_orig_system_reference    =>  x_organization_osr,
          p_created_by_module        =>  p_created_by_module,
          x_return_status            =>  x_return_status,                          
          x_msg_count                =>  x_msg_count,                              
          x_msg_data                 =>  x_msg_data                               
      );

      --xx debug info
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after create_classifications, x_return_status:' || x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
		null;
        /* Not needed as this log_exception code is in local procedure
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CODE_ASSIGNMENT_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_classifications'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling create_classifications from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
        --Also, save_gt call is in local procedure
        */
      END IF;
    END IF;

    l_cbm := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

    -----------------------------
    -- Create logical org contact
    -----------------------------
    IF((p_organization_obj.contact_objs IS NOT NULL) AND
       (p_organization_obj.contact_objs.COUNT > 0)) THEN
      HZ_ORG_CONTACT_BO_PVT.save_org_contacts(
        p_oc_objs            => p_organization_obj.contact_objs,
        p_create_update_flag => 'C',
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data,
        p_parent_org_id      => x_organization_id,
        p_parent_org_os      => x_organization_os,
        p_parent_org_osr     => x_organization_osr
      );

      --xx debug info
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after save_org_contacts, x_return_status:' || x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_ORG_CONTACT_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_ORG_CONTACT_BO_PVT'            
            , p_procedure_name         =>  'save_org_contacts'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_ORG_CONTACT_BO_PVT.save_org_contacts from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_ORG_CONTACT_BO_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    ----------------------------
    -- Create logical party site
    ----------------------------
    IF((p_organization_obj.party_site_objs IS NOT NULL) AND
       (p_organization_obj.party_site_objs.COUNT > 0)) THEN
      HZ_PARTY_SITE_BO_PVT.save_party_sites(
        p_ps_objs            => p_organization_obj.party_site_objs,
        p_create_update_flag => 'C',
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data,
        p_parent_id          => x_organization_id,
        p_parent_os          => x_organization_os,
        p_parent_osr         => x_organization_osr,
        p_parent_obj_type    => 'ORG'
      );

      --xx debug info
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after save_party_sites, x_return_status:' || x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_PARTY_SITE_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_SITE_BO_PVT'            
            , p_procedure_name         =>  'save_party_sites'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_SITE_BO_PVT.save_party_sites from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, x_msg_data: '||x_msg_data 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_PARTY_SITE_BO_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    ------------------------
    -- Create contact points
    ------------------------
    IF(((p_organization_obj.phone_objs IS NOT NULL) AND (p_organization_obj.phone_objs.COUNT > 0)) OR
       ((p_organization_obj.telex_objs IS NOT NULL) AND (p_organization_obj.telex_objs.COUNT > 0)) OR
       ((p_organization_obj.email_objs IS NOT NULL) AND (p_organization_obj.email_objs.COUNT > 0)) OR
       ((p_organization_obj.web_objs IS NOT NULL) AND (p_organization_obj.web_objs.COUNT > 0)) OR
       ((p_organization_obj.edi_objs IS NOT NULL) AND (p_organization_obj.edi_objs.COUNT > 0)) OR
       ((p_organization_obj.eft_objs IS NOT NULL) AND (p_organization_obj.eft_objs.COUNT > 0))) THEN
      HZ_CONTACT_POINT_BO_PVT.save_contact_points(
        p_phone_objs         => p_organization_obj.phone_objs,
        p_telex_objs         => p_organization_obj.telex_objs,
        p_email_objs         => p_organization_obj.email_objs,
        p_web_objs           => p_organization_obj.web_objs,
        p_edi_objs           => p_organization_obj.edi_objs,
        p_eft_objs           => p_organization_obj.eft_objs,
        p_sms_objs           => l_sms_objs,
        p_owner_table_id     => x_organization_id,
        p_owner_table_os     => x_organization_os,
        p_owner_table_osr    => x_organization_osr,
        p_parent_obj_type    => 'ORG',
        p_create_update_flag => 'C',
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data
      );

      --xx debug info
      XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(=)XX_CDH_PARTY_BO_PVT.do_create_organization_bo, after save_contact_points, x_return_status:' || x_return_status);

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_ORG_CONTACT_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_CONTACT_POINT_BO_PVT'            
            , p_procedure_name         =>  'save_contact_points'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_CONTACT_POINT_BO_PVT.save_contact_points from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_ORG_CONTACT_BO_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    ----------------------------
    -- Certifications
    ----------------------------
    IF((p_organization_obj.certification_objs IS NOT NULL) AND
       (p_organization_obj.certification_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.create_certifications(
        p_cert_objs                 => p_organization_obj.certification_objs,
        p_party_id                  => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CERTIFICATION_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_certifications'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.create_certifications from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_CERTIFICATION_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Financial Profiles
    ----------------------------
    IF((p_organization_obj.financial_prof_objs IS NOT NULL) AND
       (p_organization_obj.financial_prof_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.create_financial_profiles(
        p_fin_prof_objs             => p_organization_obj.financial_prof_objs,
        p_party_id                  => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_FINANCIAL_PROF_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_financial_profiles'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.create_financial_profiles from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_FINANCIAL_PROF_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Credit Ratings
    ----------------------------
    IF((p_organization_obj.credit_rating_objs IS NOT NULL) AND
       (p_organization_obj.credit_rating_objs.COUNT > 0)) THEN
      create_credit_ratings(
        p_credit_rating_objs        => p_organization_obj.credit_rating_objs,
        p_organization_id           => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CREDIT_RATING_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_credit_ratings'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling create_credit_ratings from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_CREDIT_RATING_OBJ_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    ----------------------------
    -- Financial Reports
    ----------------------------
    IF((p_organization_obj.financial_report_objs IS NOT NULL) AND
       (p_organization_obj.financial_report_objs.COUNT > 0)) THEN
      create_financial_reports(
        p_fin_objs                  => p_organization_obj.financial_report_objs,
        p_organization_id           => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_FINANCIAL_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
            , p_procedure_name         =>  'create_financial_reports'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling create_financial_reports from XX_CDH_PARTY_BO_PVT.do_create_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
      IF x_return_status = 'S' THEN     
        --save p_organization_id into GT table
        XX_CDH_CUST_UTIL_BO_PVT.save_gt(
           p_bo_process_id          =>  0,
           p_bo_entity_name         =>  'HZ_FINANCIAL_BO_TBL',
           p_bo_table_id            =>  x_organization_id,
           p_orig_system            =>  x_organization_os,          
           p_orig_system_reference  =>  x_organization_osr
        );
      END IF;
    END IF;

    -- raise event
    IF(l_raise_event) THEN
      HZ_PARTY_BO_PVT.call_bes(
        p_party_id         => x_organization_id,
        p_bo_code          => 'ORG',
        p_create_or_update => 'C',
        p_obj_source       => p_obj_source,
        p_event_id         => l_event_id,
        p_child_event_id   => NULL
      );
    END IF;

    -- reset Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)XX_CDH_PARTY_BO_PVT.do_create_organization_bo(-)');

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_create_organization_bo_pub;

      -- reset Global variable
      HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO do_create_organization_bo_pub;

      -- reset Global variable
      HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

    WHEN OTHERS THEN
      ROLLBACK TO do_create_organization_bo_pub;

      -- reset Global variable
      HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END do_create_organization_bo;

  -- PROCEDURE do_update_organization_bo
  --
  -- DESCRIPTION
  --     Update organization business object.
  PROCEDURE do_update_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_organization_obj    IN OUT NOCOPY HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  )IS
    l_debug_prefix             VARCHAR2(30);
    l_organization_rec         HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    l_create_update_flag       VARCHAR2(1) := 'U';
    l_ovn                      NUMBER;
    l_dummy_id                 NUMBER;
    l_profile_id               NUMBER;
    l_errorcode                NUMBER;
    l_org_raise_event          BOOLEAN := FALSE;
    l_oc_raise_event           BOOLEAN := FALSE;
    l_cbm                      VARCHAR2(30);
    l_org_event_id             NUMBER;
    l_oc_event_id              NUMBER;
    l_sms_objs                 HZ_SMS_CP_BO_TBL;
    l_party_number             VARCHAR2(30);

    CURSOR get_ovn(l_party_id  NUMBER) IS
    SELECT p.object_version_number, p.party_number
    FROM HZ_PARTIES p
    WHERE p.party_id = l_party_id
    AND p.party_type = 'ORGANIZATION'
    AND p.status in ('A','I');

  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_update_organization_bo_pub;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    IF(p_created_by_module IS NULL) THEN
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := 'BO_API';
    ELSE
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := p_created_by_module;
    END IF;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_update_organization_bo(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(+)XX_CDH_PARTY_BO_PVT.do_update_organization_bo(+)');

    x_organization_id := p_organization_obj.organization_id;
    x_organization_os := p_organization_obj.orig_system;
    x_organization_osr:= p_organization_obj.orig_system_reference;

    -- check input party_id and os+osr
    hz_registry_validate_bo_pvt.validate_ssm_id(
      px_id              => x_organization_id,
      px_os              => x_organization_os,
      px_osr             => x_organization_osr,
      p_obj_type         => 'ORGANIZATION',
      p_create_or_update => 'U',
      x_return_status    => x_return_status,
      x_msg_count        => x_msg_count,
      x_msg_data         => x_msg_data);

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- must check after calling validate_ssm_id because
    -- if user pass os+osr and no id, validate_ssm_id will
    -- populate x_organization_id based on os+osr
    -- find out if raise event at the end

    -- if this procedure is called from org cust bo, set l_raise_event to false
    -- otherwise, call is_raising_update_event
    IF(HZ_PARTY_BO_PVT.G_CALL_UPDATE_CUST_BO IS NOT NULL) THEN
      l_org_raise_event := FALSE;
      l_oc_raise_event := FALSE;
    ELSE
      l_org_raise_event := HZ_PARTY_BO_PVT.is_raising_update_event(
                             p_party_id          => x_organization_id,
                             p_bo_code           => 'ORG'
                           );

      l_oc_raise_event := HZ_PARTY_BO_PVT.is_raising_update_event(
                            p_party_id          => x_organization_id,
                            p_bo_code           => 'ORG_CUST'
                          );

      IF(l_org_raise_event) THEN
        -- Get event_id for org
        SELECT HZ_BUS_OBJ_TRACKING_S.nextval
        INTO l_org_event_id
        FROM DUAL;
      END IF;

      IF(l_oc_raise_event) THEN
        -- Get event_id for org customer
        SELECT HZ_BUS_OBJ_TRACKING_S.nextval
        INTO l_oc_event_id
        FROM DUAL;
      END IF;
    END IF;

    OPEN get_ovn(x_organization_id);
    FETCH get_ovn INTO l_ovn, l_party_number;
    CLOSE get_ovn;

    --------------------------
    -- For Update Organization
    --------------------------
    -- Assign organization record
    assign_organization_rec(
      p_organization_obj  => p_organization_obj,
      p_organization_id   => x_organization_id,
      p_organization_os   => x_organization_os,
      p_organization_osr  => x_organization_osr,
      p_create_or_update  => 'U',
      px_organization_rec => l_organization_rec
    );

    HZ_PARTY_V2PUB.update_organization(
      p_organization_rec          => l_organization_rec,
      p_party_object_version_number  => l_ovn,
      x_profile_id                => l_profile_id,
      x_return_status             => x_return_status,
      x_msg_count                 => x_msg_count,
      x_msg_data                  => x_msg_data
    );

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      --RAISE FND_API.G_EXC_ERROR;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  0        
          , p_bpel_process_id        =>  0       
          , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'            
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id                    
          , p_package_name           =>  'HZ_PARTY_V2PUB'            
          , p_procedure_name         =>  'update_organization'              
          , p_bo_table_name          =>  'HZ_PARTIES'        
          , p_bo_column_name         =>  'PARTY_ID'       
          , p_bo_column_value        =>  x_organization_id       
          , p_orig_system            =>  x_organization_os
          , p_orig_system_reference  =>  x_organization_osr
          , p_exception_log          =>  'Exception in calling HZ_PARTY_V2PUB.update_organization from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
          , p_oracle_error_code      =>  null    
          , p_oracle_error_msg       =>  null 
      );
    END IF;

    -- assign organization party_id
    p_organization_obj.organization_id := x_organization_id;
    p_organization_obj.party_number := l_party_number;
    -----------------------------
    -- For Organization Ext Attrs
    -----------------------------
    IF((p_organization_obj.ext_attributes_objs IS NOT NULL) AND
       (p_organization_obj.ext_attributes_objs.COUNT > 0)) THEN
      HZ_EXT_ATTRIBUTE_BO_PVT.save_ext_attributes(
        p_ext_attr_objs             => p_organization_obj.ext_attributes_objs,
        p_parent_obj_id             => l_profile_id,
        p_parent_obj_type           => 'ORG',
        p_create_or_update          => 'U',
        x_return_status             => x_return_status,
        x_errorcode                 => l_errorcode,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_EXT_ATTRIBUTE_BO_PVT'            
            , p_procedure_name         =>  'save_ext_attributes'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_EXT_ATTRIBUTE_BO_PVT.save_ext_attributes from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ----------------------------
    -- Party Preferences
    ----------------------------
    IF((p_organization_obj.preference_objs IS NOT NULL) AND
       (p_organization_obj.preference_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.save_party_preferences(
        p_party_pref_objs           => p_organization_obj.preference_objs,
        p_party_id                  => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_PARTY_PREF_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_party_preferences'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.save_party_preferences from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ----------------------------
    -- Contact Preferences
    ----------------------------
    IF((p_organization_obj.contact_pref_objs IS NOT NULL) AND
       (p_organization_obj.contact_pref_objs.COUNT > 0)) THEN
      HZ_CONTACT_PREFERENCE_BO_PVT.save_contact_preferences(
        p_cp_pref_objs           => p_organization_obj.contact_pref_objs,
        p_contact_level_table_id => x_organization_id,
        p_contact_level_table    => 'HZ_PARTIES',
        x_return_status          => x_return_status,
        x_msg_count              => x_msg_count,
        x_msg_data               => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CONTACT_PREF_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_CONTACT_PREFERENCE_BO_PVT'            
            , p_procedure_name         =>  'save_contact_preferences'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_CONTACT_PREFERENCE_BO_PVT.create_contact_preferences from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ----------------------------
    -- Relationship api
    ----------------------------
    IF((p_organization_obj.relationship_objs IS NOT NULL) AND
       (p_organization_obj.relationship_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.save_relationships(
        p_rel_objs                  => p_organization_obj.relationship_objs,
        p_subject_id                => x_organization_id,
        p_subject_type              => 'ORGANIZATION',
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_RELATIONSHIP_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_relationships'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.save_relationships from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ----------------------------
    -- Classification api
    ----------------------------
    IF((p_organization_obj.class_objs IS NOT NULL) AND
       (p_organization_obj.class_objs.COUNT > 0)) THEN
      /*
      HZ_PARTY_BO_PVT.save_classifications(
        p_code_assign_objs          => p_organization_obj.class_objs,
        p_owner_table_name          => 'HZ_PARTIES',
        p_owner_table_id            => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );
      */

      save_classifications(
        p_code_assign_objs         =>  p_organization_obj.class_objs,           
        p_bo_process_id            =>  0,                         
        p_bpel_process_id          =>  0,                       
        p_owner_table_name         =>  'HZ_PARTIES',
        p_owner_table_id           =>  x_organization_id,  
        p_orig_system              =>  x_organization_os,  
        p_orig_system_reference    =>  x_organization_osr,
        p_created_by_module        =>  p_created_by_module,
        p_create_update_flag       =>  l_create_update_flag,    
        x_return_status            =>  x_return_status,     
        x_msg_count                =>  x_msg_count,         
        x_msg_data                 =>  x_msg_data      
      );

      --Log_Exception and Save_GT are taken care in the above procedure
      --IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      --  RAISE FND_API.G_EXC_ERROR;
      --END IF;
	  
    END IF;

    l_cbm := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

    -----------------------------
    -- Create logical org contact
    -----------------------------
    IF((p_organization_obj.contact_objs IS NOT NULL) AND
       (p_organization_obj.contact_objs.COUNT > 0)) THEN
      HZ_ORG_CONTACT_BO_PVT.save_org_contacts(
        p_oc_objs            => p_organization_obj.contact_objs,
        p_create_update_flag => 'U',
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data,
        p_parent_org_id      => x_organization_id,
        p_parent_org_os      => x_organization_os,
        p_parent_org_osr     => x_organization_osr
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_ORG_CONTACT_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_ORG_CONTACT_BO_PVT'            
            , p_procedure_name         =>  'save_org_contacts'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_ORG_CONTACT_BO_PVT.save_org_contacts from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    -----------------
    -- For Party Site
    -----------------
    IF((p_organization_obj.party_site_objs IS NOT NULL) AND
       (p_organization_obj.party_site_objs.COUNT > 0)) THEN
      HZ_PARTY_SITE_BO_PVT.save_party_sites(
        p_ps_objs            => p_organization_obj.party_site_objs,
        p_create_update_flag => 'U',
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data,
        p_parent_id          => x_organization_id,
        p_parent_os          => x_organization_os,
        p_parent_osr         => x_organization_osr,
        p_parent_obj_type    => 'ORG'
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_PARTY_SITE_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_SITE_BO_PVT'            
            , p_procedure_name         =>  'save_party_sites'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_SITE_BO_PVT.save_party_sites from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    ---------------------
    -- For Contact Points
    ---------------------
    IF(((p_organization_obj.phone_objs IS NOT NULL) AND (p_organization_obj.phone_objs.COUNT > 0)) OR
       ((p_organization_obj.telex_objs IS NOT NULL) AND (p_organization_obj.telex_objs.COUNT > 0)) OR
       ((p_organization_obj.email_objs IS NOT NULL) AND (p_organization_obj.email_objs.COUNT > 0)) OR
       ((p_organization_obj.web_objs IS NOT NULL) AND (p_organization_obj.web_objs.COUNT > 0)) OR
       ((p_organization_obj.edi_objs IS NOT NULL) AND (p_organization_obj.edi_objs.COUNT > 0)) OR
       ((p_organization_obj.eft_objs IS NOT NULL) AND (p_organization_obj.eft_objs.COUNT > 0))) THEN
      HZ_CONTACT_POINT_BO_PVT.save_contact_points(
        p_phone_objs         => p_organization_obj.phone_objs,
        p_telex_objs         => p_organization_obj.telex_objs,
        p_email_objs         => p_organization_obj.email_objs,
        p_web_objs           => p_organization_obj.web_objs,
        p_edi_objs           => p_organization_obj.edi_objs,
        p_eft_objs           => p_organization_obj.eft_objs,
        p_sms_objs           => l_sms_objs,
        p_owner_table_id     => x_organization_id,
        p_owner_table_os     => x_organization_os,
        p_owner_table_osr    => x_organization_osr,
        p_parent_obj_type    => 'ORG',
        p_create_update_flag => 'U',
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_ORG_CONTACT_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_CONTACT_POINT_BO_PVT'            
            , p_procedure_name         =>  'save_contact_points'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_CONTACT_POINT_BO_PVT.save_contact_points from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    ---------------------
    -- Certifications
    ---------------------
    IF((p_organization_obj.certification_objs IS NOT NULL) AND
       (p_organization_obj.certification_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.save_certifications(
        p_cert_objs          => p_organization_obj.certification_objs,
        p_party_id           => x_organization_id,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CERTIFICATION_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_certifications'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.save_certifications from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ---------------------
    -- Financial Profiles
    ---------------------
    IF((p_organization_obj.financial_prof_objs IS NOT NULL) AND
       (p_organization_obj.financial_prof_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.save_financial_profiles(
        p_fin_prof_objs      => p_organization_obj.financial_prof_objs,
        p_party_id           => x_organization_id,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_FINANCIAL_PROF_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'HZ_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_financial_profiles'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling HZ_PARTY_BO_PVT.save_financial_profiles from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ----------------------------
    -- Credit Ratings
    ----------------------------
    IF((p_organization_obj.credit_rating_objs IS NOT NULL) AND
       (p_organization_obj.credit_rating_objs.COUNT > 0)) THEN
      save_credit_ratings(
        p_credit_rating_objs        => p_organization_obj.credit_rating_objs,
        p_organization_id           => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_CREDIT_RATING_OBJ_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_credit_ratings'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling save_credit_ratings from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    ----------------------------
    -- Financial Reports
    ----------------------------
    IF((p_organization_obj.financial_report_objs IS NOT NULL) AND
       (p_organization_obj.financial_report_objs.COUNT > 0)) THEN
      save_financial_reports(
        p_fin_objs                  => p_organization_obj.financial_report_objs,
        p_organization_id           => x_organization_id,
        x_return_status             => x_return_status,
        x_msg_count                 => x_msg_count,
        x_msg_data                  => x_msg_data
      );

      IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        --RAISE FND_API.G_EXC_ERROR;
        XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
              p_bo_process_id          =>  0        
            , p_bpel_process_id        =>  0       
            , p_bo_object_name         =>  'HZ_FINANCIAL_BO_TBL'            
            , p_log_date               =>  SYSDATE             
            , p_logged_by              =>  FND_GLOBAL.user_id                    
            , p_package_name           =>  'XX_CDH_PARTY_BO_PVT'            
            , p_procedure_name         =>  'save_financial_reports'              
            , p_bo_table_name          =>  'HZ_PARTIES'        
            , p_bo_column_name         =>  'PARTY_ID'       
            , p_bo_column_value        =>  x_organization_id       
            , p_orig_system            =>  x_organization_os
            , p_orig_system_reference  =>  x_organization_osr
            , p_exception_log          =>  'Exception in calling save_financial_reports from XX_CDH_PARTY_BO_PVT.do_update_organization_bo, organization id: '||x_organization_id 
            , p_oracle_error_code      =>  null    
            , p_oracle_error_msg       =>  null 
        );
      END IF;
    END IF;

    -- raise update org event
    IF(l_org_raise_event) THEN
      HZ_PARTY_BO_PVT.call_bes(
        p_party_id         => x_organization_id,
        p_bo_code          => 'ORG',
        p_create_or_update => 'U',
        p_obj_source       => p_obj_source,
        p_event_id         => l_org_event_id,
        p_child_event_id   => NULL
      );
    END IF;

    -- raise update org cust event
    IF(l_oc_raise_event) THEN
      HZ_PARTY_BO_PVT.call_bes(
        p_party_id         => x_organization_id,
        p_bo_code          => 'ORG_CUST',
        p_create_or_update => 'U',
        p_obj_source       => p_obj_source,
        p_event_id         => l_oc_event_id,
        p_child_event_id   => l_org_event_id
      );
    END IF;

    -- reset Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_update_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    --xx debug info
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(0, '(-)XX_CDH_PARTY_BO_PVT.do_update_organization_bo(-)');
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_update_organization_bo_pub;

      -- reset Global variable
      HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_update_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO do_update_organization_bo_pub;

      -- reset Global variable
      HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_update_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN OTHERS THEN
      ROLLBACK TO do_update_organization_bo_pub;

      -- reset Global variable
      HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
      HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;

      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_update_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END do_update_organization_bo;

  PROCEDURE create_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  ) IS
    l_org_obj             HZ_ORGANIZATION_BO;
  BEGIN
    l_org_obj := p_organization_obj;
    do_create_organization_bo(
      p_init_msg_list       => p_init_msg_list,
      p_validate_bo_flag    => p_validate_bo_flag,
      p_organization_obj    => l_org_obj,
      p_created_by_module   => p_created_by_module,
      p_obj_source          => null,
      x_return_status       => x_return_status,
      x_msg_count           => x_msg_count,
      x_msg_data            => x_msg_data,
      x_organization_id     => x_organization_id,
      x_organization_os     => x_organization_os,
      x_organization_osr    => x_organization_osr
    );
  END create_organization_bo;

  -- PROCEDURE do_save_organization_bo
  --
  -- DESCRIPTION
  --     Save - Create or update organization business object.
  PROCEDURE do_save_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN OUT NOCOPY HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    p_obj_source          IN            VARCHAR2 := null,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  ) IS
    l_return_status            VARCHAR2(30);
    l_msg_count                NUMBER;
    l_msg_data                 VARCHAR2(2000);
    l_create_update_flag       VARCHAR2(1);
    l_debug_prefix             VARCHAR2(30);
  BEGIN
    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF FND_API.to_Boolean(p_init_msg_list) THEN
      FND_MSG_PUB.initialize;
    END IF;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_save_organization_bo(+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    x_organization_id := p_organization_obj.organization_id;
    x_organization_os := p_organization_obj.orig_system;
    x_organization_osr:= p_organization_obj.orig_system_reference;

    -- check root business object to determine that it should be
    -- create or update, call HZ_REGISTRY_VALIDATE_BO_PVT
    l_create_update_flag := HZ_REGISTRY_VALIDATE_BO_PVT.check_bo_op(
                              p_entity_id      => x_organization_id,
                              p_entity_os      => x_organization_os,
                              p_entity_osr     => x_organization_osr,
                              p_entity_type    => 'HZ_PARTIES',
                              p_parent_id      => NULL,
                              p_parent_obj_type=> NULL );

    IF(l_create_update_flag = 'E') THEN
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_INVALID_ID');
      FND_MSG_PUB.ADD;
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'ORG');
      FND_MSG_PUB.ADD;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF(l_create_update_flag = 'C') THEN
      do_create_organization_bo(
        p_init_msg_list      => fnd_api.g_false,
        p_validate_bo_flag   => p_validate_bo_flag,
        p_organization_obj   => p_organization_obj,
        p_created_by_module  => p_created_by_module,
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data,
        x_organization_id    => x_organization_id,
        x_organization_os    => x_organization_os,
        x_organization_osr   => x_organization_osr
      );
    ELSIF(l_create_update_flag = 'U') THEN
      do_update_organization_bo(
        p_init_msg_list      => fnd_api.g_false,
        p_organization_obj   => p_organization_obj,
        p_created_by_module  => p_created_by_module,
        p_obj_source         => p_obj_source,
        x_return_status      => x_return_status,
        x_msg_count          => x_msg_count,
        x_msg_data           => x_msg_data,
        x_organization_id    => x_organization_id,
        x_organization_os    => x_organization_os,
        x_organization_osr   => x_organization_osr
      );
    ELSE
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_save_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_save_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_save_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_save_organization_bo(-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;
  END do_save_organization_bo;

  PROCEDURE save_organization_bo(
    p_init_msg_list       IN            VARCHAR2 := fnd_api.g_false,
    p_validate_bo_flag    IN            VARCHAR2 := fnd_api.g_true,
    p_organization_obj    IN            HZ_ORGANIZATION_BO,
    p_created_by_module   IN            VARCHAR2,
    x_return_status       OUT NOCOPY    VARCHAR2,
    x_msg_count           OUT NOCOPY    NUMBER,
    x_msg_data            OUT NOCOPY    VARCHAR2,
    x_organization_id     OUT NOCOPY    NUMBER,
    x_organization_os     OUT NOCOPY    VARCHAR2,
    x_organization_osr    OUT NOCOPY    VARCHAR2
  ) IS
    l_org_obj             HZ_ORGANIZATION_BO;
  BEGIN
    l_org_obj := p_organization_obj;
    do_save_organization_bo(
      p_init_msg_list       => p_init_msg_list,
      p_validate_bo_flag    => p_validate_bo_flag,
      p_organization_obj    => l_org_obj,
      p_created_by_module   => p_created_by_module,
      p_obj_source          => null,
      x_return_status       => x_return_status,
      x_msg_count           => x_msg_count,
      x_msg_data            => x_msg_data,
      x_organization_id     => x_organization_id,
      x_organization_os     => x_organization_os,
      x_organization_osr    => x_organization_osr
    );
  END save_organization_bo;

END XX_CDH_PARTY_BO_PVT;
/
SHOW ERRORS;