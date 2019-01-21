SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_PARTY_BO_WRAP_PVT
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_PARTY_BO_WRAP_PVT                                            |
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

PROCEDURE assign_organization_rec(
    p_organization_obj                 IN            HZ_ORGANIZATION_BO,
    p_organization_id                  IN            NUMBER,
    p_organization_os                  IN            VARCHAR2,
    p_organization_osr                 IN            VARCHAR2,
    p_create_or_update                 IN            VARCHAR2 := 'C',
    px_organization_rec                IN OUT NOCOPY HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE
  ) 
IS
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

  PROCEDURE assign_party_site_rec(
    p_party_site_obj             IN            HZ_PARTY_SITE_BO,
    p_party_id                   IN            NUMBER,
    p_location_id                IN            NUMBER,
    p_ps_id                      IN            NUMBER,
    p_ps_os                      IN            VARCHAR2,
    p_ps_osr                     IN            VARCHAR2,
    p_create_or_update           IN            VARCHAR2 := 'C',
    px_party_site_rec            IN OUT NOCOPY HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE
  ) IS
  BEGIN
    px_party_site_rec.party_site_id := p_ps_id;
    px_party_site_rec.party_id := p_party_id;
    px_party_site_rec.location_id := p_location_id;
    px_party_site_rec.party_site_number := p_party_site_obj.party_site_number;
    px_party_site_rec.mailstop := p_party_site_obj.mailstop;
    IF(p_party_site_obj.identifying_address_flag in ('Y','N')) THEN
      px_party_site_rec.identifying_address_flag := p_party_site_obj.identifying_address_flag;
    END IF;
    IF(p_party_site_obj.status in ('A','I')) THEN
      px_party_site_rec.status := p_party_site_obj.status;
    END IF;
    px_party_site_rec.party_site_name := p_party_site_obj.party_site_name;
    px_party_site_rec.attribute_category := p_party_site_obj.attribute_category;
    px_party_site_rec.attribute1 := p_party_site_obj.attribute1;
    px_party_site_rec.attribute2 := p_party_site_obj.attribute2;
    px_party_site_rec.attribute3 := p_party_site_obj.attribute3;
    px_party_site_rec.attribute4 := p_party_site_obj.attribute4;
    px_party_site_rec.attribute5 := p_party_site_obj.attribute5;
    px_party_site_rec.attribute6 := p_party_site_obj.attribute6;
    px_party_site_rec.attribute7 := p_party_site_obj.attribute7;
    px_party_site_rec.attribute8 := p_party_site_obj.attribute8;
    px_party_site_rec.attribute9 := p_party_site_obj.attribute9;
    px_party_site_rec.attribute10 := p_party_site_obj.attribute10;
    px_party_site_rec.attribute11 := p_party_site_obj.attribute11;
    px_party_site_rec.attribute12 := p_party_site_obj.attribute12;
    px_party_site_rec.attribute13 := p_party_site_obj.attribute13;
    px_party_site_rec.attribute14 := p_party_site_obj.attribute14;
    px_party_site_rec.attribute15 := p_party_site_obj.attribute15;
    px_party_site_rec.attribute16 := p_party_site_obj.attribute16;
    px_party_site_rec.attribute17 := p_party_site_obj.attribute17;
    px_party_site_rec.attribute18 := p_party_site_obj.attribute18;
    px_party_site_rec.attribute19 := p_party_site_obj.attribute19;
    px_party_site_rec.attribute20 := p_party_site_obj.attribute20;
    px_party_site_rec.language := p_party_site_obj.language;
    px_party_site_rec.addressee := p_party_site_obj.addressee;
    IF(p_create_or_update = 'C') THEN
      px_party_site_rec.orig_system := p_ps_os;
      px_party_site_rec.orig_system_reference := p_ps_osr;
      px_party_site_rec.created_by_module := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
    END IF;
    px_party_site_rec.global_location_number := p_party_site_obj.global_location_number;
  END assign_party_site_rec;

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
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.create_classifications(+)');

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
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.create_classifications(+)');  

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

PROCEDURE do_create_relationships (
   p_relationship_objs      IN           HZ_RELATIONSHIP_OBJ_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_organization_id        IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2
  )
is

  l_relationship_objs      HZ_RELATIONSHIP_OBJ_TBL := p_relationship_objs;
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_id        number(15) := p_organization_id;
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
  
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_relationships;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_relationships(+)'); 
    
    IF((p_relationship_objs IS NOT NULL) AND
       (p_relationship_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.create_relationships(
        p_rel_objs                  => l_relationship_objs,
        p_subject_id                => l_organization_id,
        p_subject_type              => 'ORGANIZATION',
        x_return_status             => l_return_status,
        x_msg_count                 => l_msg_count,
        x_msg_data                  => l_msg_data
      );    
  
    IF l_return_status = 'S' THEN     
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_RELATIONSHIPS',
         p_bo_table_id            =>  l_organization_id,
         p_orig_system            =>  p_orig_system,          
         p_orig_system_reference  =>  p_orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_RELATIONSHIP_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_BO_PVT'         
        , p_procedure_name         =>  'do_create_relationships'       
        , p_bo_table_name          =>  'HZ_RELATIONSHIPS'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
  END IF;  

--debug msg
XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_relationships(-)'); 
  
exception
  when others then
    ROLLBACK to do_create_relationships;  
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_RELATIONSHIP_OBJ_TBL'
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id       
        , p_package_name           =>  'HZ_PARTY_BO_PVT'        
        , p_procedure_name         =>  'do_create_relationships'
        , p_bo_table_name          =>  'HZ_RELATIONSHIPS'       
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  'Exception in do_create_relationships '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END do_create_relationships;  

PROCEDURE do_save_relationships (
   p_relationship_objs      IN           HZ_RELATIONSHIP_OBJ_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_organization_id        IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2
  )
is

  l_relationship_objs      HZ_RELATIONSHIP_OBJ_TBL := p_relationship_objs;
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_id        number(15) := p_organization_id;
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
  
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_relationships;  
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_relationships(+)');   
    
    IF((p_relationship_objs IS NOT NULL) AND
       (p_relationship_objs.COUNT > 0)) THEN
      HZ_PARTY_BO_PVT.save_relationships(
        p_rel_objs                  => l_relationship_objs,
        p_subject_id                => l_organization_id,
        p_subject_type              => 'ORGANIZATION',
        x_return_status             => l_return_status,
        x_msg_count                 => l_msg_count,
        x_msg_data                  => l_msg_data
      );    
  
    IF l_return_status = 'S' THEN     
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_RELATIONSHIPS',
         p_bo_table_id            =>  l_organization_id,
         p_orig_system            =>  p_orig_system,          
         p_orig_system_reference  =>  p_orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_RELATIONSHIP_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_BO_PVT'         
        , p_procedure_name         =>  'do_save_relationships'       
        , p_bo_table_name          =>  'HZ_RELATIONSHIPS'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
  END IF;  

--debug msg
XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_relationships(-)');   
  
exception
  when others then
    ROLLBACK to do_save_relationships;  
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_RELATIONSHIP_OBJ_TBL'
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id       
        , p_package_name           =>  'HZ_PARTY_BO_PVT'        
        , p_procedure_name         =>  'do_save_relationships'
        , p_bo_table_name          =>  'HZ_RELATIONSHIPS'       
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  'Exception in do_save_relationships '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END do_save_relationships;  

PROCEDURE do_save_org_contacts(
   p_oc_objs                IN           HZ_ORG_CONTACT_BO_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_organization_id        IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2
)
IS    

  l_oc_objs                HZ_ORG_CONTACT_BO_TBL := p_oc_objs;
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_id        number(15) := p_organization_id;
  l_organization_os        varchar2(30) := p_orig_system;
  l_organization_osr       varchar2(255) := p_orig_system_reference;
  
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_org_contacts;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_org_contacts(+)'); 
    
    IF((p_oc_objs IS NOT NULL) AND
       (p_oc_objs.COUNT > 0)) THEN
      HZ_ORG_CONTACT_BO_PVT.save_org_contacts(
        p_oc_objs            => l_oc_objs,
        p_create_update_flag => p_create_update_flag,
        p_obj_source         => NULL,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_org_id      => l_organization_id,
        p_parent_org_os      => l_organization_os,
        p_parent_org_osr     => l_organization_osr
      );    
  
    IF l_return_status = 'S' THEN     
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_ORG_CONTACTS',
         p_bo_table_id            =>  l_organization_id,
         p_orig_system            =>  p_orig_system,          
         p_orig_system_reference  =>  p_orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORG_CONTACT_BO_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_BO_PVT'         
        , p_procedure_name         =>  'do_save_org_contacts'       
        , p_bo_table_name          =>  'HZ_ORG_CONTACTS'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
  END IF;    

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_org_contacts(-)'); 

exception
  when others then
    ROLLBACK to do_save_org_contacts;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORG_CONTACT_BO_TBL'  
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id       
        , p_package_name           =>  'HZ_PARTY_BO_PVT'        
        , p_procedure_name         =>  'do_save_org_contacts' 
        , p_bo_table_name          =>  'HZ_ORG_CONTACTS'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  'Exception in do_save_org_contacts '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );  
END do_save_org_contacts;   

PROCEDURE do_save_org_contact_points(
   p_phone_objs             IN           HZ_PHONE_CP_BO_TBL, 
   p_telex_objs             IN           HZ_TELEX_CP_BO_TBL, 
   p_email_objs             IN           HZ_EMAIL_CP_BO_TBL, 
   p_web_objs               IN           HZ_WEB_CP_BO_TBL,   
   p_edi_objs               IN           HZ_EDI_CP_BO_TBL,   
   p_eft_objs               IN           HZ_EFT_CP_BO_TBL,   
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_organization_id        IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2
)
IS    

  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_id        number(15) := p_organization_id;
  l_organization_os        varchar2(30) := p_orig_system;
  l_organization_osr       varchar2(255) := p_orig_system_reference;
  l_sms_objs               HZ_SMS_CP_BO_TBL := null;
  l_create_update_flag     VARCHAR2(1) := p_create_update_flag;
  
  l_phone_objs             HZ_PHONE_CP_BO_TBL   :=  p_phone_objs; 
  l_telex_objs             HZ_TELEX_CP_BO_TBL   :=  p_telex_objs;
  l_email_objs             HZ_EMAIL_CP_BO_TBL   :=  p_email_objs;
  l_web_objs               HZ_WEB_CP_BO_TBL     :=  p_web_objs  ;
  l_edi_objs               HZ_EDI_CP_BO_TBL     :=  p_edi_objs  ;
  l_eft_objs               HZ_EFT_CP_BO_TBL     :=  p_eft_objs  ;  

BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_org_contact_points;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_org_contact_points(+)'); 
    
    IF(((l_phone_objs IS NOT NULL) AND (l_phone_objs.COUNT > 0)) OR
       ((l_telex_objs IS NOT NULL) AND (l_telex_objs.COUNT > 0)) OR
       ((l_email_objs IS NOT NULL) AND (l_email_objs.COUNT > 0)) OR
       ((l_web_objs IS NOT NULL)   AND (l_web_objs.COUNT > 0)) OR
       ((l_edi_objs IS NOT NULL)   AND (l_edi_objs.COUNT > 0)) OR
       ((l_eft_objs IS NOT NULL)   AND (l_eft_objs.COUNT > 0))) THEN      
           
      HZ_CONTACT_POINT_BO_PVT.save_contact_points(
        p_phone_objs         => l_phone_objs,
        p_telex_objs         => l_telex_objs,
        p_email_objs         => l_email_objs,
        p_web_objs           => l_web_objs,
        p_edi_objs           => l_edi_objs,
        p_eft_objs           => l_eft_objs,
        p_sms_objs           => l_sms_objs,
        p_owner_table_id     => l_organization_id,
        p_owner_table_os     => l_organization_os,
        p_owner_table_osr    => l_organization_osr,
        p_parent_obj_type    => 'ORG',
        p_create_update_flag => l_create_update_flag,
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );          
    
    IF l_return_status = 'S' THEN     
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
        p_bo_process_id          =>  p_bo_process_id,
        p_bo_entity_name         =>  'HZ_CONTACT_POINTS',
        p_bo_table_id            =>  l_organization_id,
        p_orig_system            =>  p_orig_system,          
        p_orig_system_reference  =>  p_orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_CONTACT_POINT_BO_PVT'         
        , p_procedure_name         =>  'do_save_org_contact_points'       
        , p_bo_table_name          =>  'HZ_CONTACT_POINTS'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
  END IF;    

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_org_contact_points(-)'); 
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK to do_save_org_contact_points;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_CONTACT_POINT_BO_PVT'     
        , p_procedure_name         =>  'do_save_org_contact_points'
        , p_bo_table_name          =>  'HZ_CONTACT_POINTS'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_orig_system          
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  'Exception in do_save_org_contact_points '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );  
END do_save_org_contact_points;    

PROCEDURE do_create_location ( 
    p_location_obj          IN            HZ_LOCATION_OBJ,
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,
    p_created_by_module     IN            VARCHAR2,
    x_location_id           OUT NOCOPY    NUMBER
   )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_location_id            number(15) :=0;
  l_location_os            varchar2(30);
  l_location_osr           varchar2(255);
BEGIN
  -- Standard start of API savepoint
  SAVEPOINT do_create_location;    
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_location(+)'); 

  HZ_LOCATION_BO_PUB.create_location_bo(
    p_init_msg_list       => fnd_api.g_false,
    p_validate_bo_flag    => fnd_api.g_true,
    p_location_obj        => p_location_obj,
    p_created_by_module   => p_location_obj.created_by_module,
    x_return_status       => l_return_status,   
    x_msg_count           => l_msg_count,       
    x_msg_data            => l_msg_data,        
    x_location_id         => l_location_id, 
    x_location_os         => l_location_os,
    x_location_osr        => l_location_osr
  );
  
  --call XX_CDH_CUST_UTIL_BO_PVT.save_gt
  IF l_return_status = 'S' THEN
    --save l_organization_id into GT table
    x_location_id := l_location_id;
    XX_CDH_CUST_UTIL_BO_PVT.save_gt(
       p_bo_process_id          =>  p_bo_process_id,
       p_bo_entity_name         =>  'HZ_LOCATIONS',
       p_bo_table_id            =>  l_location_id, 
       p_orig_system            =>  l_location_os,
       p_orig_system_reference  =>  l_location_osr
    );
 
  ELSE
    --call exception process
    l_msg_data := null;
    FOR i IN 1 .. l_msg_count
    LOOP
       l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
    END LOOP;
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
        p_bo_process_id          =>  p_bo_process_id        
      , p_bpel_process_id        =>  p_bpel_process_id      
      , p_bo_object_name         =>  'HZ_LOCATION_OBJ'       
      , p_log_date               =>  SYSDATE             
      , p_logged_by              =>  FND_GLOBAL.user_id            
      , p_package_name           =>  'HZ_LOCATION_BO_PUB'         
      , p_procedure_name         =>  'do_create_location'       
      , p_bo_table_name          =>  'HZ_LOCATIONS'        
      , p_bo_column_name         =>  'LOCATION_ID'       
      , p_bo_column_value        =>  l_location_id
      , p_orig_system            =>  l_location_os
      , p_orig_system_reference  =>  l_location_osr
      , p_exception_log          =>  l_msg_data        
      , p_oracle_error_code      =>  null    
      , p_oracle_error_msg       =>  null 
    );
  END IF;    

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_location(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_create_location;
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
        p_bo_process_id          =>  p_bo_process_id        
      , p_bpel_process_id        =>  p_bpel_process_id      
      , p_bo_object_name         =>  'HZ_LOCATION_OBJ'       
      , p_log_date               =>  SYSDATE             
      , p_logged_by              =>  FND_GLOBAL.user_id            
      , p_package_name           =>  'HZ_LOCATION_BO_PUB'         
      , p_procedure_name         =>  'do_create_location'       
      , p_bo_table_name          =>  'HZ_LOCATIONS'        
      , p_bo_column_name         =>  'LOCATION_ID'       
      , p_bo_column_value        =>  l_location_id
      , p_orig_system            =>  l_location_os
      , p_orig_system_reference  =>  l_location_osr
      , p_exception_log          =>  'Exception in create_location '  || SQLERRM              
      , p_oracle_error_code      =>  SQLCODE    
      , p_oracle_error_msg       =>  SQLERRM 
    );
END do_create_location; 
    
PROCEDURE do_save_location ( 
    p_location_obj          IN            HZ_LOCATION_OBJ,
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,
    p_created_by_module     IN            VARCHAR2,
    p_create_update_flag    IN            VARCHAR2,
    x_location_id           OUT NOCOPY    NUMBER
   )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_location_id            number(15) :=0;
  l_location_os            varchar2(30);
  l_location_osr           varchar2(255);
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_location;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_location(+)'); 

    HZ_LOCATION_BO_PUB.save_location_bo(
      p_init_msg_list       => fnd_api.g_false,
      p_validate_bo_flag    => fnd_api.g_true,
      p_location_obj        => p_location_obj,
      p_created_by_module   => p_location_obj.created_by_module,
      x_return_status       => l_return_status,   
      x_msg_count           => l_msg_count,       
      x_msg_data            => l_msg_data,        
      x_location_id         => l_location_id, 
      x_location_os         => l_location_os,
      x_location_osr        => l_location_osr
    );
  
    --call XX_CDH_CUST_UTIL_BO_PVT.save_gt
    IF l_return_status = 'S' THEN
      --save l_organization_id into GT table
      x_location_id := l_location_id;
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_LOCATIONS',
         p_bo_table_id            =>  l_location_id, 
         p_orig_system            =>  l_location_os,
         p_orig_system_reference  =>  l_location_osr
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_LOCATION_OBJ'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_LOCATION_BO_PUB'         
        , p_procedure_name         =>  'do_save_location'       
        , p_bo_table_name          =>  'HZ_LOCATIONS'        
        , p_bo_column_name         =>  'LOCATION_ID'       
        , p_bo_column_value        =>  l_location_id
        , p_orig_system            =>  l_location_os
        , p_orig_system_reference  =>  l_location_osr
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.save_location(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to save_location;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_LOCATION_OBJ'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_LOCATION_BO_PUB'         
        , p_procedure_name         =>  'do_save_location'       
        , p_bo_table_name          =>  'HZ_LOCATIONS'        
        , p_bo_column_name         =>  'LOCATION_ID'       
        , p_bo_column_value        =>  l_location_id
        , p_orig_system            =>  l_location_os
        , p_orig_system_reference  =>  l_location_osr
        , p_exception_log          =>  'Exception in save_location '  || SQLERRM              
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
      );
END do_save_location;       

PROCEDURE do_create_party_site (
   p_party_site_obj         IN           HZ_PARTY_SITE_BO,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_party_id               IN           NUMBER,
   p_location_id            IN           NUMBER,
   p_created_by_module      IN           VARCHAR2,
   x_party_site_id          OUT  NOCOPY  NUMBER
  )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_party_site_rec           HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
  l_location_id              NUMBER(15);
  l_party_site_id            NUMBER(15);
  l_party_id                 NUMBER(15);
  l_party_site_number        VARCHAR2(30);

BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_party_site;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_party_site(+)'); 

      assign_party_site_rec(
      p_party_site_obj  => p_party_site_obj,
      p_party_id        => p_party_id,
      p_location_id     => p_location_id,
      p_ps_id           => l_party_site_id,
      p_ps_os           => p_party_site_obj.orig_system,
      p_ps_osr          => p_party_site_obj.orig_system_reference,
      px_party_site_rec => l_party_site_rec
    );
    l_party_site_rec.created_by_module := 'BO_API';
    HZ_PARTY_SITE_V2PUB.create_party_site(
      p_party_site_rec            => l_party_site_rec,
      x_party_site_id             => l_party_site_id,
      x_party_site_number         => l_party_site_number,
      x_return_status             => l_return_status,
      x_msg_count                 => l_msg_count,
      x_msg_data                  => l_msg_data
    );

  --call XX_CDH_CUST_UTIL_BO_PVT.save_gt
    IF l_return_status = 'S' THEN
      --save l_organization_id into GT table
      x_party_site_id := l_party_site_id;
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_PARTY_SITES',
         p_bo_table_id            =>  l_party_site_id, 
         p_orig_system            =>  p_party_site_obj.orig_system,
         p_orig_system_reference  =>  p_party_site_obj.orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITE_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PUB'         
        , p_procedure_name         =>  'do_create_party_site'       
        , p_bo_table_name          =>  'HZ_PARTY_SITES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  l_party_site_id
        , p_orig_system            =>  p_party_site_obj.orig_system
        , p_orig_system_reference  =>  p_party_site_obj.orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_party_site(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_create_party_site;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  p_bo_process_id        
          , p_bpel_process_id        =>  p_bpel_process_id      
          , p_bo_object_name         =>  'HZ_PARTY_SITE_BO'       
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id            
          , p_package_name           =>  'HZ_PARTY_SITE_BO_PUB'         
          , p_procedure_name         =>  'do_create_party_site'       
          , p_bo_table_name          =>  'HZ_PARTY_SITES'        
          , p_bo_column_name         =>  'PARTY_SITE_ID'       
          , p_bo_column_value        =>  l_party_site_id
          , p_orig_system            =>  p_party_site_obj.orig_system
          , p_orig_system_reference  =>  p_party_site_obj.orig_system_reference
          , p_exception_log          =>  'Exception in do_create_party_site '  || SQLERRM              
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      );

  
END do_create_party_site;   

PROCEDURE do_save_party_site (
   p_party_site_obj         IN           HZ_PARTY_SITE_BO,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_party_id               IN           NUMBER,
   p_location_id            IN           NUMBER,
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2,
   x_party_site_id          OUT  NOCOPY  NUMBER
  )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_party_site_rec         HZ_PARTY_SITE_V2PUB.PARTY_SITE_REC_TYPE;
  l_location_id            NUMBER(15);
  l_party_site_id          NUMBER(15);
  l_party_id               NUMBER(15);
  l_party_site_number      VARCHAR2(30);
  l_ps_ovn                 NUMBER;
  l_loc_ovn                NUMBER;  

  CURSOR get_ovn(l_ps_id  NUMBER) IS
  SELECT ps.object_version_number, loc.object_version_number, ps.party_id, loc.location_id
  FROM HZ_PARTY_SITES ps, HZ_LOCATIONS loc
  WHERE ps.party_site_id = l_ps_id
  AND ps.location_id = loc.location_id
  AND ps.status in ('A','I');
    
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_party_site;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_site(+)');

    OPEN get_ovn(x_party_site_id);
    FETCH get_ovn INTO l_ps_ovn, l_loc_ovn, l_party_id, l_location_id;
    CLOSE get_ovn;
    
    assign_party_site_rec(
      p_party_site_obj  => p_party_site_obj,
      p_party_id        => p_party_id,
      p_location_id     => p_location_id,
      p_ps_id           => l_party_site_id,
      p_ps_os           => p_party_site_obj.orig_system,
      p_ps_osr          => p_party_site_obj.orig_system_reference,
      px_party_site_rec => l_party_site_rec
    );

    HZ_PARTY_SITE_V2PUB.update_party_site(
      p_party_site_rec            => l_party_site_rec,
      p_object_version_number     => l_ps_ovn,
      x_return_status             => l_return_status,
      x_msg_count                 => l_msg_count,
      x_msg_data                  => l_msg_data
    );

  --call XX_CDH_CUST_UTIL_BO_PVT.save_gt
    IF l_return_status = 'S' THEN
      --save l_organization_id into GT table
      x_party_site_id := l_party_site_id;
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_PARTY_SITES',
         p_bo_table_id            =>  l_party_site_id, 
         p_orig_system            =>  p_party_site_obj.orig_system,
         p_orig_system_reference  =>  p_party_site_obj.orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITE_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PUB'         
        , p_procedure_name         =>  'do_save_party_site'       
        , p_bo_table_name          =>  'HZ_PARTY_SITES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  l_party_site_id
        , p_orig_system            =>  p_party_site_obj.orig_system
        , p_orig_system_reference  =>  p_party_site_obj.orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    

    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_site(-)');

EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_save_party_site;
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
        p_bo_process_id          =>  p_bo_process_id        
      , p_bpel_process_id        =>  p_bpel_process_id      
      , p_bo_object_name         =>  'HZ_PARTY_SITE_BO'       
      , p_log_date               =>  SYSDATE             
      , p_logged_by              =>  FND_GLOBAL.user_id            
      , p_package_name           =>  'HZ_PARTY_SITE_BO_PUB'         
      , p_procedure_name         =>  'do_save_party_site'       
      , p_bo_table_name          =>  'HZ_PARTY_SITES'        
      , p_bo_column_name         =>  'PARTY_SITE_ID'       
      , p_bo_column_value        =>  l_party_site_id
      , p_orig_system            =>  p_party_site_obj.orig_system
      , p_orig_system_reference  =>  p_party_site_obj.orig_system_reference
      , p_exception_log          =>  'Exception in do_save_party_site '  || SQLERRM              
      , p_oracle_error_code      =>  SQLCODE    
      , p_oracle_error_msg       =>  SQLERRM 
    );

END do_save_party_site; 

PROCEDURE do_create_party_site_uses (  
   p_party_site_use_objs    IN           HZ_PARTY_SITE_USE_OBJ_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_party_site_id          IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,
   p_created_by_module      IN           VARCHAR2
  )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_party_site_use_objs_t  HZ_PARTY_SITE_USE_OBJ_TBL;
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_party_site_uses;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_party_site_uses(+)'); 

   l_party_site_use_objs_t := p_party_site_use_objs;
   -- IF((p_party_site_use_objs IS NOT NULL) AND (p_party_site_use_objs.count > 0)) THEN
   
      HZ_PARTY_SITE_BO_PVT.create_party_site_uses(
        p_psu_objs           => l_party_site_use_objs_t,
        p_ps_id              => p_party_site_id,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );
      
    IF l_return_status = 'S' THEN

      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
        p_bo_process_id          =>  p_bo_process_id,
        p_bo_entity_name         =>  'HZ_PARTY_SITE_USES',
        p_bo_table_id            =>  p_party_site_id,
        p_orig_system            =>  p_orig_system,
        p_orig_system_reference  =>  p_orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITE_USE_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PVT'         
        , p_procedure_name         =>  'do_create_party_site_uses'       
        , p_bo_table_name          =>  'HZ_PARTY_SITE_USES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  p_party_site_id      
        , p_orig_system            =>  p_orig_system
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
  --END IF;    
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_party_site_uses(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_create_party_site_uses;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
         p_bo_process_id          =>  p_bo_process_id        
       , p_bpel_process_id        =>  p_bpel_process_id      
       , p_bo_object_name         =>  'HZ_PARTY_SITE_USE_OBJ_TBL'       
       , p_log_date               =>  SYSDATE             
       , p_logged_by              =>  FND_GLOBAL.user_id            
       , p_package_name           =>  'HZ_PARTY_SITE_BO_PVT'         
       , p_procedure_name         =>  'do_create_party_site_uses'       
       , p_bo_table_name          =>  'HZ_PARTY_SITE_USES'        
       , p_bo_column_name         =>  'PARTY_SITE_ID'       
       , p_bo_column_value        =>  p_party_site_id      
       , p_orig_system            =>  p_orig_system
       , p_orig_system_reference  =>  p_orig_system_reference
       , p_exception_log          =>  'Exception in do_create_party_site_uses '  || SQLERRM      
       , p_oracle_error_code      =>  SQLCODE    
       , p_oracle_error_msg       =>  SQLERRM 
    );          
END do_create_party_site_uses;                                  

PROCEDURE do_save_party_site_uses (  
   p_party_site_use_objs    IN           HZ_PARTY_SITE_USE_OBJ_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_party_site_id          IN           NUMBER,
   p_orig_system            IN           VARCHAR2,
   p_orig_system_reference  IN           VARCHAR2,   
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2
  )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_party_site_use_objs_t  HZ_PARTY_SITE_USE_OBJ_TBL;
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_party_site_uses;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_site_uses(+)'); 

    l_party_site_use_objs_t := p_party_site_use_objs;
    -- IF((p_party_site_use_objs IS NOT NULL) AND (p_party_site_use_objs.count > 0)) THEN
   
    HZ_PARTY_SITE_BO_PVT.save_party_site_uses(
        p_psu_objs           => l_party_site_use_objs_t,
        p_ps_id              => p_party_site_id,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
    );
      
    IF l_return_status = 'S' THEN

      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_PARTY_SITE_USES',
         p_bo_table_id            =>  p_party_site_id,
         p_orig_system            =>  p_orig_system,
         p_orig_system_reference  =>  p_orig_system_reference
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITE_USE_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PVT'         
        , p_procedure_name         =>  'do_save_party_site_uses'       
        , p_bo_table_name          =>  'HZ_PARTY_SITE_USES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  p_party_site_id      
        , p_orig_system            =>  p_orig_system
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_site_uses(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_save_party_site_uses;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITE_USE_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PVT'         
        , p_procedure_name         =>  'do_save_party_site_uses'       
        , p_bo_table_name          =>  'HZ_PARTY_SITE_USES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  p_party_site_id      
        , p_orig_system            =>  p_orig_system
        , p_orig_system_reference  =>  p_orig_system_reference
        , p_exception_log          =>  'Exception in do_save_party_site_uses '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );          
END do_save_party_site_uses;                                    

/*
PROCEDURE do_create_ps_ext_attribs ( 
  p_ext_attributes_objs  IN          HZ_EXT_ATTRIBUTE_OBJ_TBL,
  p_bo_process_id        IN          NUMBER,
  p_bpel_process_id      IN          NUMBER,
  p_party_site_id        OUT NOCOPY  NUMBER
)
is
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_party_site_id           number(15) :=0;
  l_party_site_os            varchar2(30) := null;
  l_party_site_osr           varchar2(255) := null;
  l_ext_attributes_objs    p_ext_attributes_objs;
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_ps_ext_attribs;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_ps_ext_attribs(+)'); 

    IF((p_ext_attributes_objs IS NOT NULL) AND
       (p_ext_attributes_objs.COUNT > 0)) THEN
      HZ_EXT_ATTRIBUTE_BO_PVT.save_ext_attributes(
        p_ext_attr_objs             => l_ext_attributes_objs,
        p_parent_obj_id             => l_party_site_id,
        p_parent_obj_type           => 'PARTY_SITE',
        p_create_or_update          => 'C',
        x_return_status             => l_return_status,
        x_errorcode                 => l_errorcode,
        x_msg_count                 => l_msg_count,
        x_msg_data                  => l_msg_data
      );
  
    --call XX_CDH_CUST_UTIL_BO_PVT.save_gt
    IF l_return_status = 'S' THEN
      --save l_organization_id into GT table
      x_location_id := l_location_id;
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'PS_HZ_EXT_ATTRIBUTE',
         p_bo_table_id            =>  l_party_site_id, 
         p_orig_system            =>  l_party_site_os,
         p_orig_system_reference  =>  l_party_site_osr
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_EXT_ATTRIBUTE_BO_PVT'         
        , p_procedure_name         =>  'do_create_ps_ext_attribs'       
        , p_bo_table_name          =>  'PS_HZ_EXT_ATTRIBUTE'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  l_party_site_id
        , p_orig_system            =>  l_party_site_os
        , p_orig_system_reference  =>  l_party_site_osr
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;   
  END IF;   
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_ps_ext_attribs(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_create_ps_ext_attribs;
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
        p_bo_process_id          =>  p_bo_process_id        
      , p_bpel_process_id        =>  p_bpel_process_id      
      , p_bo_object_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL'     
      , p_log_date               =>  SYSDATE             
      , p_logged_by              =>  FND_GLOBAL.user_id                   
      , p_package_name           =>  'HZ_EXT_ATTRIBUTE_BO_PVT'           
      , p_procedure_name         =>  'do_create_ps_ext_attribs'      
      , p_bo_table_name          =>  'PS_HZ_EXT_ATTRIBUTE'        
      , p_bo_column_name         =>  'PARTY_SITE_ID'       
      , p_bo_column_value        =>  l_party_site_id
      , p_orig_system            =>  l_party_site_os
      , p_orig_system_reference  =>  l_party_site_osr
      , p_exception_log          =>  'Exception in do_create_ps_ext_attribs '  || SQLERRM              
      , p_oracle_error_code      =>  SQLCODE    
      , p_oracle_error_msg       =>  SQLERRM 
    );
END do_create_ps_ext_attribs;       


PROCEDURE do_save_ps_ext_attribs (   
  p_ext_attributes_objs  IN          HZ_EXT_ATTRIBUTE_OBJ_TBL,
  p_create_update_flag   IN          VARCHAR2,
  p_bo_process_id        IN          NUMBER,
  p_bpel_process_id      IN          NUMBER,
  p_party_site_id        OUT NOCOPY  NUMBER
)
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_party_site_id           number(15) :=0;
  l_party_site_os            varchar2(30) := null;
  l_party_site_osr           varchar2(255) := null;
  l_ext_attributes_objs    p_ext_attributes_objs;
  l_create_update_flag     varchar2(1) := p_create_update_flag;

BEGIN

    -- Standard start of API savepoint
    SAVEPOINT do_save_ps_ext_attribs;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_ps_ext_attribs(+)'); 

    IF((p_ext_attributes_objs IS NOT NULL) AND
       (p_ext_attributes_objs.COUNT > 0)) THEN
      HZ_EXT_ATTRIBUTE_BO_PVT.save_ext_attributes(
        p_ext_attr_objs             => l_ext_attributes_objs,
        p_parent_obj_id             => l_party_site_id,
        p_parent_obj_type           => 'PARTY_SITE',
        p_create_or_update          => 'U',
        x_return_status             => l_return_status,
        x_errorcode                 => l_errorcode,
        x_msg_count                 => l_msg_count,
        x_msg_data                  => l_msg_data
      );
  
  --call XX_CDH_CUST_UTIL_BO_PVT.save_gt
    IF l_return_status = 'S' THEN
      --save l_organization_id into GT table
      x_location_id := l_location_id;
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'PS_HZ_EXT_ATTRIBUTE',
         p_bo_table_id            =>  l_party_site_id, 
         p_orig_system            =>  l_party_site_os,
         p_orig_system_reference  =>  l_party_site_osr
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_EXT_ATTRIBUTE_BO_PVT'         
        , p_procedure_name         =>  'do_save_ps_ext_attribs'       
        , p_bo_table_name          =>  'PS_HZ_EXT_ATTRIBUTE'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  l_party_site_id
        , p_orig_system            =>  l_party_site_os
        , p_orig_system_reference  =>  l_party_site_osr
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;   
  END IF;   
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_ps_ext_attribs(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_save_ps_ext_attribs;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
           p_bo_process_id          =>  p_bo_process_id        
         , p_bpel_process_id        =>  p_bpel_process_id      
         , p_bo_object_name         =>  'HZ_EXT_ATTRIBUTE_OBJ_TBL'     
         , p_log_date               =>  SYSDATE             
         , p_logged_by              =>  FND_GLOBAL.user_id                   
         , p_package_name           =>  'HZ_EXT_ATTRIBUTE_BO_PVT'           
         , p_procedure_name         =>  'do_save_ps_ext_attribs'      
         , p_bo_table_name          =>  'PS_HZ_EXT_ATTRIBUTE'        
         , p_bo_column_name         =>  'PARTY_SITE_ID'       
         , p_bo_column_value        =>  l_party_site_id
         , p_orig_system            =>  l_party_site_os
         , p_orig_system_reference  =>  l_party_site_osr
         , p_exception_log          =>  'Exception in do_save_ps_ext_attribs '  || SQLERRM              
         , p_oracle_error_code      =>  SQLCODE    
         , p_oracle_error_msg       =>  SQLERRM 
      );
END do_save_ps_ext_attribs;

*/

PROCEDURE do_create_party_sites (
   p_party_site_objs        IN           HZ_PARTY_SITE_BO_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_party_id               IN           NUMBER,
   p_created_by_module      IN           VARCHAR2
)
IS
l_location_id    NUMBER(15);
l_party_site_id    NUMBER(15);
l_party_site_os    varchar2(30);
l_party_site_osr   varchar2(255);
i                  number;
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_party_sites;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_party_sites(+)'); 

    --create site related objects
    FOR i in 1..p_party_site_objs.COUNT LOOP
    
      l_party_site_os := p_party_site_objs(i).ORIG_SYSTEM;
      l_party_site_osr := p_party_site_objs(i).ORIG_SYSTEM_REFERENCE;      
     --create location
     do_create_location ( p_party_site_objs(i).location_obj, p_bo_process_id, p_bpel_process_id, p_created_by_module, l_location_id);
     
     --create party site
     do_create_party_site ( p_party_site_objs(i), p_bo_process_id, p_bpel_process_id, p_party_id, l_location_id, p_created_by_module, l_party_site_id);
      
     --create part site uses
     do_create_party_site_uses ( p_party_site_objs(i).party_site_use_objs, p_bo_process_id, p_bpel_process_id, l_party_site_id, l_party_site_os, l_party_site_osr, p_created_by_module);
     
     --create party site extensibles
     --FOR k in 1..ext_attributes_objs.COUNT LOOP
       --Call do_create_extensible_attr
    --   do_create_ps_ext_attribs ( p_party_site_objs(k).ext_attributes_objs, p_bpel_process_id);
    -- END LOOP;    
   
   END LOOP; 
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_party_sites(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_create_party_sites;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_ORGANIZATION_BO_PUB'         
        , p_procedure_name         =>  'create_organization_bo'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_party_site_id      
        , p_orig_system            =>  l_party_site_os 
        , p_orig_system_reference  =>  l_party_site_osr
        , p_exception_log          =>  'Exception in do_create_party_sites '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END do_create_party_sites;

PROCEDURE do_save_party_sites (
   p_party_site_objs        IN           HZ_PARTY_SITE_BO_TBL,
   p_bo_process_id          IN           NUMBER,
   p_bpel_process_id        IN           NUMBER,
   p_party_id               IN           NUMBER,
   p_created_by_module      IN           VARCHAR2,
   p_create_update_flag     IN           VARCHAR2
  )
IS
l_location_id    NUMBER(15);
l_party_site_id    NUMBER(15);
l_party_site_os    varchar2(30);
l_party_site_osr   varchar2(255);
i                  number;
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_party_sites;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_sites(+)'); 

    --save site related objects
    FOR i in 1..p_party_site_objs.COUNT LOOP
    
      l_party_site_os := p_party_site_objs(i).ORIG_SYSTEM;
      l_party_site_osr := p_party_site_objs(i).ORIG_SYSTEM_REFERENCE;      
     --save location
    -- do_save_location ( p_party_site_objs(i).location_obj, p_bo_process_id, p_bpel_process_id, l_location_id);
     
     --save party site
    -- do_save_party_site ( p_party_site_objs(i), p_bo_process_id, p_bpel_process_id, p_party_id, l_location_id, l_party_site_id);
      
     --save part site uses
     do_save_party_site_uses ( p_party_site_objs(i).party_site_use_objs, p_bo_process_id, p_bpel_process_id, l_party_site_id, l_party_site_os, l_party_site_osr, p_created_by_module, p_create_update_flag);
     
     --save party site extensibles
     --FOR k in 1..ext_attributes_objs.COUNT LOOP
       --Call do_create_extensible_attr
      -- do_save_ps_ext_attribs ( p_party_site_objs(k).ext_attributes_objs, p_bo_process_id, p_bpel_process_id);
    -- END LOOP;    
   
   END LOOP; 
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_sites(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_save_party_sites;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_ORGANIZATION_BO_PUB'         
        , p_procedure_name         =>  'save_organization_bo'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_party_site_id      
        , p_orig_system            =>  l_party_site_os 
        , p_orig_system_reference  =>  l_party_site_osr
        , p_exception_log          =>  'Exception in do_save_party_sites '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END do_save_party_sites;

PROCEDURE do_save_party_site_bo (   
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,   
    p_validate_bo_flag      IN            VARCHAR2 := fnd_api.g_true,
    p_party_site_obj        IN            HZ_PARTY_SITE_BO,
    p_created_by_module     IN            VARCHAR2,
    p_obj_source            IN            VARCHAR2 := null,
    p_return_obj_flag       IN            VARCHAR2 := fnd_api.g_true,
    p_create_update_flag    IN            VARCHAR2,
    x_return_status         OUT NOCOPY    VARCHAR2,
    x_messages              OUT NOCOPY    HZ_MESSAGE_OBJ_TBL,
    x_return_obj            OUT NOCOPY    HZ_PARTY_SITE_BO,
    x_party_site_id         OUT NOCOPY    NUMBER,
    x_party_site_os         OUT NOCOPY    VARCHAR2,
    x_party_site_osr        OUT NOCOPY    VARCHAR2,
    px_parent_id            IN OUT NOCOPY NUMBER,
    px_parent_os            IN OUT NOCOPY VARCHAR2,
    px_parent_osr           IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type      IN OUT NOCOPY VARCHAR2
   )
IS
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_messages               HZ_MESSAGE_OBJ_TBL := NULL;
  l_parent_id              NUMBER   := px_parent_id;      
  l_parent_os              VARCHAR2(30) := px_parent_os;      
  l_parent_osr             VARCHAR2(255) := px_parent_osr;     
  l_parent_obj_type        VARCHAR2(255) := px_parent_obj_type;  
  
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_party_site_bo;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_site_bo(+)'); 

   
    HZ_PARTY_SITE_BO_PUB.save_party_site_bo(
      p_validate_bo_flag    =>  fnd_api.g_true,
      p_party_site_obj      =>  p_party_site_obj,
      p_created_by_module   =>  p_created_by_module,
      p_obj_source          =>  null,
      p_return_obj_flag     =>  fnd_api.g_true,
      x_return_status       =>  l_return_status,
      x_messages            =>  l_messages,
      x_return_obj          =>  x_return_obj,
      x_party_site_id       =>  x_party_site_id, 
      x_party_site_os       =>  x_party_site_os,
      x_party_site_osr      =>  x_party_site_osr,
      px_parent_id          =>  l_parent_id,      
      px_parent_os          =>  l_parent_os,      
      px_parent_osr         =>  l_parent_osr,     
      px_parent_obj_type    =>  l_parent_obj_type
    );
      
    IF l_return_status = 'S' THEN

      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bo_process_id,
         p_bo_entity_name         =>  'HZ_PARTY_SITES',
         p_bo_table_id            =>  x_party_site_id,
         p_orig_system            =>  l_parent_os,
         p_orig_system_reference  =>  l_parent_osr
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITES_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PUB'         
        , p_procedure_name         =>  'do_save_party_site_bo'       
        , p_bo_table_name          =>  'HZ_PARTY_SITES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  x_party_site_id      
        , p_orig_system            =>  l_parent_os
        , p_orig_system_reference  =>  l_parent_osr
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_save_party_site_bo(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_save_party_site_bo;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_PARTY_SITES_BO'           
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id        
        , p_package_name           =>  'HZ_PARTY_SITE_BO_PUB'     
        , p_procedure_name         =>  'do_save_party_site_bo'   
        , p_bo_table_name          =>  'HZ_PARTY_SITES'        
        , p_bo_column_name         =>  'PARTY_SITE_ID'       
        , p_bo_column_value        =>  x_party_site_id      
        , p_orig_system            =>  l_parent_os
        , p_orig_system_reference  =>  l_parent_osr
        , p_exception_log          =>  'Exception in do_save_party_site_bo '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );          
END do_save_party_site_bo;                                    

PROCEDURE do_create_organization_party (
    p_organization_obj      IN            HZ_ORGANIZATION_BO,
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,
    p_created_by_module     IN            VARCHAR2,
    x_organization_id       OUT  NOCOPY   NUMBER
  )
IS
  
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  x_organization_os        VARCHAR2(30);
  x_organization_osr       VARCHAR2(255);
  
  l_init_msg_list          VARCHAR2(30)  := null;
  l_validate_bo_flag       VARCHAR2(200) := null;
  --l_organization_obj       HZ_ORGANIZATION_BO;
  l_created_by_module      VARCHAR2(30)  := p_created_by_module; --check this whether we can take this from profiles
  
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_organization_party;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_create_organization_party(+)');     
    
    HZ_ORGANIZATION_BO_PUB.create_organization_bo(
      p_init_msg_list       => l_init_msg_list,
      p_validate_bo_flag    => l_validate_bo_flag,
      p_organization_obj    => p_organization_obj,
      p_created_by_module   => l_created_by_module,
      x_return_status       => l_return_status,
      x_msg_count           => l_msg_count,
      x_msg_data            => l_msg_data,
      x_organization_id     => x_organization_id,
      x_organization_os     => x_organization_os,
      x_organization_osr    => x_organization_osr
    );    
  
    IF l_return_status = 'S' THEN

      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
         p_bo_process_id          =>  p_bpel_process_id,
         p_bo_entity_name         =>  'HZ_PARTIES',
         p_bo_table_id            =>  x_organization_id,
         p_orig_system            =>  x_organization_os,
         p_orig_system_reference  =>  x_organization_osr
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_V2PUB'         
        , p_procedure_name         =>  'do_create_organization_party'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  x_organization_id
        , p_orig_system            =>  x_organization_os
        , p_orig_system_reference  =>  x_organization_osr
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
    
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.do_create_organization_party(-)'); 
	
EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_create_contr_cust_acct_bo;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
            p_bo_process_id          =>  p_bo_process_id        
          , p_bpel_process_id        =>  p_bpel_process_id      
          , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
          , p_log_date               =>  SYSDATE             
          , p_logged_by              =>  FND_GLOBAL.user_id            
          , p_package_name           =>  'HZ_PARTY_V2PUB'         
          , p_procedure_name         =>  'do_create_organization_party'           
          , p_bo_table_name          =>  'HZ_PARTIES'        
          , p_bo_column_name         =>  'PARTY_ID'       
          , p_bo_column_value        =>  x_organization_id
          , p_orig_system            =>  x_organization_os
          , p_orig_system_reference  =>  x_organization_osr
          , p_exception_log          =>  'Exception in XX_CDH_PARTY_BO_WRAP_PVT.do_create_organization_party '  || SQLERRM      
          , p_oracle_error_code      =>  SQLCODE    
          , p_oracle_error_msg       =>  SQLERRM 
      ); 
      --L_RETURN_STATUS := 'E';	
      --X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_contr_cust_acct_bo'	 || SQLERRM;										  
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to do_create_organization_party;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_PARTY_V2PUB'         
        , p_procedure_name         =>  'do_create_organization_party'
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  x_organization_id
        , p_orig_system            =>  x_organization_os
        , p_orig_system_reference  =>  x_organization_osr
        , p_exception_log          =>  'Exception in do_create_organization_party '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END do_create_organization_party;  

PROCEDURE do_save_organization_party (
    p_organization_obj      IN            HZ_ORGANIZATION_BO,
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,
    p_created_by_module     IN            VARCHAR2,
    p_create_update_flag    IN            VARCHAR2,
    x_organization_id       OUT  NOCOPY   NUMBER
  )
IS

  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_id        number(15) :=0;
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_save_organization_party;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.do_save_organization_party(+)'); 
      
    HZ_ORGANIZATION_BO_PUB.save_organization_bo (
        p_init_msg_list       => fnd_api.g_false,
        p_validate_bo_flag    => fnd_api.g_true,
        p_organization_obj    => p_organization_obj,
        p_created_by_module   => 'BO_API',
        x_return_status       => l_return_status  ,  
        x_msg_count           => l_msg_count      ,  
        x_msg_data            => l_msg_data       ,  
        x_organization_id     => l_organization_id, 
        x_organization_os     => l_organization_os, 
        x_organization_osr    => l_organization_osr  
    );
  
    IF l_return_status = 'S' THEN
      x_organization_id := l_organization_id;
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PVT.save_gt(
          p_bo_process_id          =>  p_bo_process_id,
          p_bo_entity_name         =>  'HZ_PARTIES',
          p_bo_table_id            =>  l_organization_id,
          p_orig_system            =>  p_organization_obj.ORIG_SYSTEM,
          p_orig_system_reference  =>  p_organization_obj.ORIG_SYSTEM_REFERENCE
      );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_ORGANIZATION_BO_PUB'         
        , p_procedure_name         =>  'save_organization_party'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_organization_obj.ORIG_SYSTEM
        , p_orig_system_reference  =>  p_organization_obj.ORIG_SYSTEM_REFERENCE
        , p_exception_log          =>  l_msg_data        
        , p_oracle_error_code      =>  null    
        , p_oracle_error_msg       =>  null 
      );
    END IF;    
    
  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.save_organization_party(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to save_organization_party;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_ORGANIZATION_BO_PUB'         
        , p_procedure_name         =>  'save_organization_party'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_organization_obj.ORIG_SYSTEM
        , p_orig_system_reference  =>  p_organization_obj.ORIG_SYSTEM_REFERENCE
        , p_exception_log          =>  'Exception in save_organization_party '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END do_save_organization_party;  

PROCEDURE create_organization (
    p_organization_obj      IN            HZ_ORGANIZATION_BO,
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,
    p_created_by_module     IN            VARCHAR2,
    x_organization_id       OUT  NOCOPY   NUMBER,
    x_return_status         OUT  NOCOPY   VARCHAR2,
    x_errbuf                OUT  NOCOPY   VARCHAR2
)
IS
  l_orig_system_ref_id     number := 0;
 
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_id        number(15);
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
  l_create_update_flag     varchar2(1) := 'C';
  l_organization_obj       HZ_ORGANIZATION_BO := p_organization_obj;
  
  --Copy all nested collection objects into local collection objects
  l_orig_sys_objs                   HZ_ORIG_SYS_REF_OBJ_TBL      :=  l_organization_obj.orig_sys_objs        ;  
  l_ext_attributes_objs             HZ_EXT_ATTRIBUTE_OBJ_TBL     :=  l_organization_obj.ext_attributes_objs  ;
  l_contact_objs                    HZ_ORG_CONTACT_BO_TBL        :=  l_organization_obj.contact_objs         ;
  l_party_site_objs                 HZ_PARTY_SITE_BO_TBL         :=  l_organization_obj.party_site_objs      ;
  l_preference_objs                 HZ_PARTY_PREF_OBJ_TBL        :=  l_organization_obj.preference_objs      ;
  l_phone_objs                      HZ_PHONE_CP_BO_TBL           :=  l_organization_obj.phone_objs           ;
  l_telex_objs                      HZ_TELEX_CP_BO_TBL           :=  l_organization_obj.telex_objs           ;
  l_email_objs                      HZ_EMAIL_CP_BO_TBL           :=  l_organization_obj.email_objs           ;
  l_web_objs                        HZ_WEB_CP_BO_TBL             :=  l_organization_obj.web_objs             ;
  l_edi_objs                        HZ_EDI_CP_BO_TBL             :=  l_organization_obj.edi_objs             ;
  l_eft_objs                        HZ_EFT_CP_BO_TBL             :=  l_organization_obj.eft_objs             ;
  l_relationship_objs               HZ_RELATIONSHIP_OBJ_TBL      :=  l_organization_obj.relationship_objs    ;
  l_class_objs                      HZ_CODE_ASSIGNMENT_OBJ_TBL   :=  l_organization_obj.class_objs           ;
  l_financial_report_objs           HZ_FINANCIAL_BO_TBL          :=  l_organization_obj.financial_report_objs;
  l_credit_rating_objs              HZ_CREDIT_RATING_OBJ_TBL     :=  l_organization_obj.credit_rating_objs   ;
  l_certification_objs              HZ_CERTIFICATION_OBJ_TBL     :=  l_organization_obj.certification_objs   ;
  l_financial_prof_objs             HZ_FINANCIAL_PROF_OBJ_TBL    :=  l_organization_obj.financial_prof_objs  ;
  l_contact_pref_objs               HZ_CONTACT_PREF_OBJ_TBL      :=  l_organization_obj.contact_pref_objs    ;  
BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_organization;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.create_organization(+)'); 
	
	--Assign null values to organization_bo's nested objects so that it creates/saves only organization 
	l_organization_obj.orig_sys_objs           := null; 
	l_organization_obj.ext_attributes_objs     := null;
	l_organization_obj.contact_objs            := null;
	l_organization_obj.party_site_objs         := null;
	l_organization_obj.preference_objs         := null;
	l_organization_obj.phone_objs              := null;
	l_organization_obj.telex_objs              := null;
	l_organization_obj.email_objs              := null;
	l_organization_obj.web_objs                := null;
	l_organization_obj.edi_objs                := null;
	l_organization_obj.eft_objs                := null;
	l_organization_obj.relationship_objs       := null;
	l_organization_obj.class_objs              := null;
	l_organization_obj.financial_report_objs   := null;
	l_organization_obj.credit_rating_objs      := null;
	l_organization_obj.certification_objs      := null;
	l_organization_obj.financial_prof_objs     := null;
	l_organization_obj.contact_pref_objs       := null;
	
	--Now call create Organization party
    do_create_organization_party (
      p_organization_obj    => l_organization_obj,
      p_bo_process_id       => p_bo_process_id,
      p_bpel_process_id     => p_bpel_process_id,
	  p_created_by_module   => p_created_by_module,
      x_organization_id     => l_organization_id
    );
    
    --create party sites from p_XX_CDH_CUSTOMER_BO.HZ_ORGANIZATION_BO.party_site_objs
    do_create_party_sites (
      p_party_site_objs     => l_party_site_objs,
      p_bo_process_id       => p_bo_process_id,
      p_bpel_process_id     => p_bpel_process_id, 
	  p_created_by_module   => p_created_by_module,
      p_party_id            => l_organization_id
    );  

    --create party relationship
    do_create_relationships (
      p_relationship_objs       => l_relationship_objs,
      p_bo_process_id           => p_bo_process_id,
      p_bpel_process_id         => p_bpel_process_id,
      p_organization_id         => l_organization_id,
      p_orig_system             => l_organization_os,
      p_orig_system_reference   => l_organization_osr,
	  p_created_by_module       => p_created_by_module
    );
    
    --create org contact (create contact points associated with org contacts embeds in create org contacts)
    do_save_org_contacts(
        p_oc_objs                 =>  l_contact_objs,
        p_bo_process_id           =>  p_bo_process_id,
        p_bpel_process_id         =>  p_bpel_process_id,
        p_organization_id         =>  l_organization_id, 
        p_orig_system             =>  l_organization_os, 
        p_orig_system_reference   =>  l_organization_osr,
        p_created_by_module       =>  p_created_by_module,
		p_create_update_flag      =>  l_create_update_flag
    );

    --create org contact points (contact points of org object only - rare cases)
    do_save_org_contact_points(
		p_phone_objs              =>  l_phone_objs,                                    
		p_telex_objs              =>  l_telex_objs,
		p_email_objs              =>  l_email_objs,
		p_web_objs                =>  l_web_objs,  
		p_edi_objs                =>  l_edi_objs,  
		p_eft_objs                =>  l_eft_objs,  
        p_bo_process_id           =>  p_bo_process_id,
        p_bpel_process_id         =>  p_bpel_process_id,
        p_organization_id         =>  l_organization_id, 
        p_orig_system             =>  l_organization_os, 
        p_orig_system_reference   =>  l_organization_osr,
        p_created_by_module       =>  p_created_by_module,
		p_create_update_flag      =>  l_create_update_flag
    );

    --create code assignments for segmentation and loyalty
    create_classifications(
        p_code_assign_objs         =>  l_class_objs,           
        p_bo_process_id            =>  p_bo_process_id,                         
        p_bpel_process_id          =>  p_bpel_process_id,                       
        p_owner_table_name         =>  'HZ_PARTIES',
        p_owner_table_id           =>  l_organization_id,   
        p_orig_system              =>  p_organization_obj.orig_system,          
        p_orig_system_reference    =>   p_organization_obj.orig_system_reference,
        p_created_by_module        =>  p_created_by_module,
        x_return_status            =>  l_return_status,                          
        x_msg_count                =>  l_msg_count,                              
        x_msg_data                 =>  l_msg_data                               
    );

	--debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.create_organization(-)'); 
	
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to create_organization;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_ORGANIZATION_BO_PUB'         
        , p_procedure_name         =>  'create_organization'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_organization_obj.ORIG_SYSTEM
        , p_orig_system_reference  =>  p_organization_obj.ORIG_SYSTEM_REFERENCE
        , p_exception_log          =>  'Exception in create_organization '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    

END create_organization;

PROCEDURE save_organization (
    p_organization_obj      IN            HZ_ORGANIZATION_BO,
    p_bo_process_id         IN            NUMBER,
    p_bpel_process_id       IN            NUMBER,
    p_created_by_module     IN            VARCHAR2,
    p_create_update_flag    IN            VARCHAR2,
    x_organization_id       OUT  NOCOPY   NUMBER,
    x_return_status         OUT  NOCOPY   VARCHAR2,
    x_errbuf                OUT  NOCOPY   VARCHAR2    
)
IS
   l_organization_id  NUMBER := x_organization_id;
   l_create_update_flag   varchar2(1) := p_create_update_flag;
   l_orig_system_ref_id     number := 0;
 
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);
  l_organization_os        varchar2(30);
  l_organization_osr       varchar2(255);
  l_organization_obj       HZ_ORGANIZATION_BO := p_organization_obj;
  
  --Copy all nested collection objects into local collection objects
  l_orig_sys_objs                   HZ_ORIG_SYS_REF_OBJ_TBL      :=  l_organization_obj.orig_sys_objs        ;  
  l_ext_attributes_objs             HZ_EXT_ATTRIBUTE_OBJ_TBL     :=  l_organization_obj.ext_attributes_objs  ;
  l_contact_objs                    HZ_ORG_CONTACT_BO_TBL        :=  l_organization_obj.contact_objs         ;
  l_party_site_objs                 HZ_PARTY_SITE_BO_TBL         :=  l_organization_obj.party_site_objs      ;
  l_preference_objs                 HZ_PARTY_PREF_OBJ_TBL        :=  l_organization_obj.preference_objs      ;
  l_phone_objs                      HZ_PHONE_CP_BO_TBL           :=  l_organization_obj.phone_objs           ;
  l_telex_objs                      HZ_TELEX_CP_BO_TBL           :=  l_organization_obj.telex_objs           ;
  l_email_objs                      HZ_EMAIL_CP_BO_TBL           :=  l_organization_obj.email_objs           ;
  l_web_objs                        HZ_WEB_CP_BO_TBL             :=  l_organization_obj.web_objs             ;
  l_edi_objs                        HZ_EDI_CP_BO_TBL             :=  l_organization_obj.edi_objs             ;
  l_eft_objs                        HZ_EFT_CP_BO_TBL             :=  l_organization_obj.eft_objs             ;
  l_relationship_objs               HZ_RELATIONSHIP_OBJ_TBL      :=  l_organization_obj.relationship_objs    ;
  l_class_objs                      HZ_CODE_ASSIGNMENT_OBJ_TBL   :=  l_organization_obj.class_objs           ;
  l_financial_report_objs           HZ_FINANCIAL_BO_TBL          :=  l_organization_obj.financial_report_objs;
  l_credit_rating_objs              HZ_CREDIT_RATING_OBJ_TBL     :=  l_organization_obj.credit_rating_objs   ;
  l_certification_objs              HZ_CERTIFICATION_OBJ_TBL     :=  l_organization_obj.certification_objs   ;
  l_financial_prof_objs             HZ_FINANCIAL_PROF_OBJ_TBL    :=  l_organization_obj.financial_prof_objs  ;
  l_contact_pref_objs               HZ_CONTACT_PREF_OBJ_TBL      :=  l_organization_obj.contact_pref_objs    ;  

BEGIN
    -- Standard start of API savepoint
    SAVEPOINT save_organization;    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(+)XX_CDH_PARTY_BO_WRAP_PVT.save_organization(+)'); 

	--Assign null values to organization_bo's nested objects so that it creates/saves only organization 
	l_organization_obj.orig_sys_objs           := null; 
	l_organization_obj.ext_attributes_objs     := null;
	l_organization_obj.contact_objs            := null;
	l_organization_obj.party_site_objs         := null;
	l_organization_obj.preference_objs         := null;
	l_organization_obj.phone_objs              := null;
	l_organization_obj.telex_objs              := null;
	l_organization_obj.email_objs              := null;
	l_organization_obj.web_objs                := null;
	l_organization_obj.edi_objs                := null;
	l_organization_obj.eft_objs                := null;
	l_organization_obj.relationship_objs       := null;
	l_organization_obj.class_objs              := null;
	l_organization_obj.financial_report_objs   := null;
	l_organization_obj.credit_rating_objs      := null;
	l_organization_obj.certification_objs      := null;
	l_organization_obj.financial_prof_objs     := null;
	l_organization_obj.contact_pref_objs       := null;

    --create Organization party
    do_save_organization_party (
      p_organization_obj    => l_organization_obj,
      p_bo_process_id       => p_bo_process_id,
      p_bpel_process_id     => p_bpel_process_id,
      p_created_by_module   => p_created_by_module,
      p_create_update_flag  => p_create_update_flag,
      x_organization_id     => l_organization_id
    );

    --create party sites from p_XX_CDH_CUSTOMER_BO.HZ_ORGANIZATION_BO.party_site_objs
    do_save_party_sites (
      p_party_site_objs     => l_party_site_objs,
      p_bo_process_id       => p_bo_process_id,
      p_bpel_process_id     => p_bpel_process_id, 
      p_party_id            => l_organization_id,
      p_created_by_module   => p_created_by_module,
      p_create_update_flag  => p_create_update_flag
    );  

    --create party relationship
    do_save_relationships (
      p_relationship_objs       => l_relationship_objs,
      p_bo_process_id           => p_bo_process_id,
      p_bpel_process_id         => p_bpel_process_id,
      p_organization_id         => l_organization_id,
      p_orig_system             => l_organization_os,
      p_orig_system_reference   => l_organization_osr,
      p_created_by_module       => p_created_by_module,
      p_create_update_flag      => p_create_update_flag
    );
    
    --create org contact (create contact points associated with org contacts embeds in create org contacts)
    do_save_org_contacts(
      p_oc_objs                 =>  l_contact_objs,
      p_bo_process_id           =>  p_bo_process_id,
      p_bpel_process_id         =>  p_bpel_process_id,
      p_organization_id         =>  l_organization_id, 
      p_orig_system             =>  l_organization_os, 
      p_orig_system_reference   => l_organization_osr,
      p_created_by_module       => p_created_by_module,
      p_create_update_flag      => p_create_update_flag
    );

    --create org contact points (contact points of org object only - rare cases)
    do_save_org_contact_points(
      p_phone_objs              =>  l_phone_objs,                                    
      p_telex_objs              =>  l_telex_objs,
      p_email_objs              =>  l_email_objs,
      p_web_objs                =>  l_web_objs,  
      p_edi_objs                =>  l_edi_objs,  
      p_eft_objs                =>  l_eft_objs,  
      p_bo_process_id           =>  p_bo_process_id,
      p_bpel_process_id         =>  p_bpel_process_id,
      p_organization_id         =>  l_organization_id, 
      p_orig_system             =>  l_organization_os, 
      p_orig_system_reference   => l_organization_osr,
      p_created_by_module       => p_created_by_module,
      p_create_update_flag      => p_create_update_flag
    );
    --create code assignments for segmentation and loyalty
    save_classifications(
      p_code_assign_objs         =>  l_class_objs,           
      p_bo_process_id            =>  p_bo_process_id,                         
      p_bpel_process_id          =>  p_bpel_process_id,                       
      p_owner_table_name         =>  'HZ_PARTIES',
      p_owner_table_id           =>  l_organization_id,   
      p_orig_system              =>  p_organization_obj.orig_system,          
      p_orig_system_reference    =>  p_organization_obj.orig_system_reference,
      p_created_by_module        =>  p_created_by_module,
      p_create_update_flag       =>  p_create_update_flag,
      x_return_status            =>  l_return_status,                          
      x_msg_count                =>  l_msg_count,                              
      x_msg_data                 =>  l_msg_data                               
    );

  --debug msg
  XX_CDH_CUST_UTIL_BO_PVT.log_msg(p_bo_process_id, '(-)XX_CDH_PARTY_BO_WRAP_PVT.save_organization(-)'); 
    
EXCEPTION
  --write exception process
  WHEN OTHERS THEN
    ROLLBACK to save_organization;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PVT.LOG_EXCEPTION (
          p_bo_process_id          =>  p_bo_process_id        
        , p_bpel_process_id        =>  p_bpel_process_id      
        , p_bo_object_name         =>  'HZ_ORGANIZATION_BO'       
        , p_log_date               =>  SYSDATE             
        , p_logged_by              =>  FND_GLOBAL.user_id            
        , p_package_name           =>  'HZ_ORGANIZATION_BO_PUB'         
        , p_procedure_name         =>  'save_organization'       
        , p_bo_table_name          =>  'HZ_PARTIES'        
        , p_bo_column_name         =>  'PARTY_ID'       
        , p_bo_column_value        =>  l_organization_id      
        , p_orig_system            =>  p_organization_obj.ORIG_SYSTEM
        , p_orig_system_reference  =>  p_organization_obj.ORIG_SYSTEM_REFERENCE
        , p_exception_log          =>  'Exception in save_organization '  || SQLERRM      
        , p_oracle_error_code      =>  SQLCODE    
        , p_oracle_error_msg       =>  SQLERRM 
    );    
END save_organization;

END XX_CDH_PARTY_BO_WRAP_PVT;
/
SHOW ERRORS;
