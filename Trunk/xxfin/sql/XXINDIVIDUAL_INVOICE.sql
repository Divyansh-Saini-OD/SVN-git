DECLARE
									 
    l_init_msg_list                        VARCHAR2(100) := FND_API.G_FALSE;
    l_customer_profile_rec                 HZ_CUSTOMER_PROFILE_V2PUB.customer_profile_rec_type;
    l_object_version_number                NUMBER ;
    l_return_status                        VARCHAR2(1) := NULL;
    l_msg_count                            NUMBER := 0;
    l_msg_data                             VARCHAR2(2000);	
    l_term_id                              NUMBER;
        
    l_init_msg_list1                       VARCHAR2(100) := FND_API.G_FALSE;
    l_customer_site_rec                    HZ_CUSTOMER_PROFILE_V2PUB.customer_profile_rec_type;
    l_object_version_number1               NUMBER ;
    l_return_status1                       VARCHAR2(1) := NULL;
    l_msg_count1                           NUMBER := 0;
    l_msg_data1                            VARCHAR2(2000);	
    l_standard_terms                       NUMBER;
    l_cust_account_id                      NUMBER;
    l_count_account                        NUMBER :=0;
    l_count_site                           NUMBER :=0;	
    l_count_site_all                       NUMBER :=0;
    l_user_id				   NUMBER :=0;
    l_appilcation_id                       NUMBER :=0;
    l_responsibility_id                    NUMBER :=0;
    l_customer_number                      VARCHAR2(5000);
    l_site_number                          VARCHAR2(5000);
    v_message                               VARCHAR2(5000);
    v_message1                               VARCHAR2(5000);
    v_msg_index_out                     NUMBER;
    v_msg_index_out1                     NUMBER;	

	
CURSOR INV_CUSTOMER IS
SELECT DISTINCT hzcp.cust_account_profile_id
,hzcp.cust_account_id
,hzcp.status
,hzcp.collector_id
,hzcp.credit_analyst_id
,hzcp.credit_checking
,hzcp.next_credit_review_date
,hzcp.tolerance
,hzcp.discount_terms
,hzcp.dunning_letters
,hzcp.interest_charges
,hzcp.send_statements
,hzcp.credit_balance_statements
,hzcp.credit_hold
,hzcp.profile_class_id
,hzcp.site_use_id
,hzcp.credit_rating
,hzcp.risk_code
,rt.term_id
,hzcp.override_terms
,hzcp.dunning_letter_set_id
,hzcp.interest_period_days
,hzcp.payment_grace_days
,hzcp.discount_grace_days
,hzcp.statement_cycle_id
,hzcp.account_status
,hzcp.percent_collectable
,hzcp.autocash_hierarchy_id
,hzcp.attribute_category
,hzcp.attribute1
,hzcp.attribute2
,hzcp.attribute3
,hzcp.attribute4
,hzcp.attribute5
,hzcp.attribute6
,hzcp.attribute7
,hzcp.attribute8
,hzcp.attribute9
,hzcp.attribute10
,hzcp.attribute11
,hzcp.attribute12
,hzcp.attribute13
,hzcp.attribute14
,hzcp.attribute15
,hzcp.auto_rec_incl_disputed_flag
,hzcp.tax_printing_option
,hzcp.charge_on_finance_charge_flag
,hzcp.grouping_rule_id
,hzcp.clearing_days
,hzcp.jgzz_attribute_category
,hzcp.jgzz_attribute1
,hzcp.jgzz_attribute2
,hzcp.jgzz_attribute3
,hzcp.jgzz_attribute4
,hzcp.jgzz_attribute5
,hzcp.jgzz_attribute6
,hzcp.jgzz_attribute7
,hzcp.jgzz_attribute8
,hzcp.jgzz_attribute9
,hzcp.jgzz_attribute10
,hzcp.jgzz_attribute11
,hzcp.jgzz_attribute12
,hzcp.jgzz_attribute13
,hzcp.jgzz_attribute14
,hzcp.jgzz_attribute15
,hzcp.global_attribute1
,hzcp.global_attribute2
,hzcp.global_attribute3
,hzcp.global_attribute4
,hzcp.global_attribute5
,hzcp.global_attribute6
,hzcp.global_attribute7
,hzcp.global_attribute8
,hzcp.global_attribute9
,hzcp.global_attribute10
,hzcp.global_attribute11
,hzcp.global_attribute12
,hzcp.global_attribute13
,hzcp.global_attribute14
,hzcp.global_attribute15
,hzcp.global_attribute16
,hzcp.global_attribute17
,hzcp.global_attribute18
,hzcp.global_attribute19
,hzcp.global_attribute20
,hzcp.global_attribute_category
,hzcp.cons_inv_flag
,hzcp.cons_inv_type
,hzcp.autocash_hierarchy_id_for_adr
,hzcp.lockbox_matching_option      
,hzcp.created_by_module
,hzcp.application_id
,hzcp.review_cycle
,hzcp.last_credit_review_date
,hzcp.party_id
,hzcp.credit_classification
,hzcp.object_version_number     
FROM  apps.hz_customer_profiles hzcp,
      apps.ra_terms rt
WHERE   hzcp.standard_terms = rt.term_id
        AND rt.attribute1 IS NOT NULL
        AND hzcp.status = 'A'
        AND hzcp.cons_inv_flag NOT IN ('Y')
        AND hzcp.site_use_id IS NULL;
        
                
                
CURSOR INV_CUST_SITE(p_cust_account_id NUMBER) IS
SELECT DISTINCT hzcp.cust_account_profile_id
       ,hzcp.cust_account_id
       ,hzcp.status
       ,hzcp.collector_id
       ,hzcp.credit_analyst_id
       ,hzcp.credit_checking
       ,hzcp.next_credit_review_date
       ,hzcp.tolerance
       ,hzcp.discount_terms
       ,hzcp.dunning_letters
       ,hzcp.interest_charges
       ,hzcp.send_statements
       ,hzcp.credit_balance_statements
       ,hzcp.credit_hold
       ,hzcp.profile_class_id
       ,hzcp.site_use_id
       ,hzcp.credit_rating
              ,hzcp.risk_code
              ,hzcp.STANDARD_TERMS
              ,hzcp.override_terms
              ,hzcp.dunning_letter_set_id
              ,hzcp.interest_period_days
              ,hzcp.payment_grace_days
              ,hzcp.discount_grace_days
              ,hzcp.statement_cycle_id
              ,hzcp.account_status
              ,hzcp.percent_collectable
              ,hzcp.autocash_hierarchy_id
              ,hzcp.attribute_category
              ,hzcp.attribute1
              ,hzcp.attribute2
              ,hzcp.attribute3
              ,hzcp.attribute4
              ,hzcp.attribute5
              ,hzcp.attribute6
              ,hzcp.attribute7
              ,hzcp.attribute8
              ,hzcp.attribute9
              ,hzcp.attribute10
              ,hzcp.attribute11
              ,hzcp.attribute12
              ,hzcp.attribute13
              ,hzcp.attribute14
              ,hzcp.attribute15
              ,hzcp.auto_rec_incl_disputed_flag
              ,hzcp.tax_printing_option
              ,hzcp.charge_on_finance_charge_flag
              ,hzcp.grouping_rule_id
              ,hzcp.clearing_days
              ,hzcp.jgzz_attribute_category
              ,hzcp.jgzz_attribute1
              ,hzcp.jgzz_attribute2
              ,hzcp.jgzz_attribute3
              ,hzcp.jgzz_attribute4
              ,hzcp.jgzz_attribute5
              ,hzcp.jgzz_attribute6
              ,hzcp.jgzz_attribute7
              ,hzcp.jgzz_attribute8
              ,hzcp.jgzz_attribute9
              ,hzcp.jgzz_attribute10
              ,hzcp.jgzz_attribute11
              ,hzcp.jgzz_attribute12
              ,hzcp.jgzz_attribute13
              ,hzcp.jgzz_attribute14
              ,hzcp.jgzz_attribute15
              ,hzcp.global_attribute1
              ,hzcp.global_attribute2
              ,hzcp.global_attribute3
              ,hzcp.global_attribute4
              ,hzcp.global_attribute5
              ,hzcp.global_attribute6
              ,hzcp.global_attribute7
              ,hzcp.global_attribute8
              ,hzcp.global_attribute9
              ,hzcp.global_attribute10
              ,hzcp.global_attribute11
              ,hzcp.global_attribute12
              ,hzcp.global_attribute13
              ,hzcp.global_attribute14
              ,hzcp.global_attribute15
              ,hzcp.global_attribute16
              ,hzcp.global_attribute17
              ,hzcp.global_attribute18
              ,hzcp.global_attribute19
              ,hzcp.global_attribute20
              ,hzcp.global_attribute_category
              ,hzcp.cons_inv_flag
              ,hzcp.cons_inv_type
              ,hzcp.autocash_hierarchy_id_for_adr
              ,hzcp.lockbox_matching_option      
              ,hzcp.created_by_module
              ,hzcp.application_id
              ,hzcp.review_cycle
              ,hzcp.last_credit_review_date
              ,hzcp.party_id
              ,hzcp.credit_classification
              ,hzcp.object_version_number     
FROM  APPS.hz_customer_profiles hzcp
     ,apps.hz_cust_site_uses_all hzus
WHERE hzcp.cons_inv_flag not in 'Y'
      AND hzcp.site_use_id is not null
      AND hzcp.status = 'A'
      and hzus.site_use_id = hzcp.site_use_id
      and hzus.site_use_code = 'BILL_TO'  
      AND hzcp.cust_account_id = p_cust_account_id;
                

BEGIN

SELECT user_id
INTO l_user_id from apps.fnd_user
where user_name = 'CONVERSION';

SELECT application_id, responsibility_id 
INTO l_appilcation_id, l_responsibility_id
FROM apps.fnd_responsibility
WHERE responsibility_key = 'OD_US_AR_MANAGER';

Fnd_global.apps_initialize(l_user_id, l_responsibility_id, l_appilcation_id);

SELECT term_id 
INTO l_term_id 
FROM apps.ra_terms
WHERE name = 'NET 30';

FOR inv_cust_rec IN INV_CUSTOMER
LOOP

SELECT account_number 
INTO l_customer_number
FROM hz_cust_accounts
WHERE cust_account_id = inv_cust_rec.cust_account_id;

l_customer_profile_rec.cust_account_profile_id    :=   inv_cust_rec.cust_account_profile_id;
l_customer_profile_rec.cust_account_id    :=   inv_cust_rec.cust_account_id;
l_customer_profile_rec.status    :=   inv_cust_rec.status;
l_customer_profile_rec.collector_id    :=   inv_cust_rec.collector_id;
l_customer_profile_rec.credit_analyst_id    :=   inv_cust_rec.credit_analyst_id;
l_customer_profile_rec.credit_checking    :=   inv_cust_rec.credit_checking;
l_customer_profile_rec.next_credit_review_date    :=   inv_cust_rec.next_credit_review_date;
l_customer_profile_rec.tolerance    :=   inv_cust_rec.tolerance;
l_customer_profile_rec.discount_terms    :=   inv_cust_rec.discount_terms;
l_customer_profile_rec.dunning_letters    :=   inv_cust_rec.dunning_letters;
l_customer_profile_rec.interest_charges    :=   inv_cust_rec.interest_charges;
l_customer_profile_rec.send_statements    :=   inv_cust_rec.send_statements;
l_customer_profile_rec.credit_balance_statements    :=   inv_cust_rec.credit_balance_statements;
l_customer_profile_rec.credit_hold    :=   inv_cust_rec.credit_hold;
l_customer_profile_rec.profile_class_id    :=   inv_cust_rec.profile_class_id;
l_customer_profile_rec.site_use_id    :=   inv_cust_rec.site_use_id;
l_customer_profile_rec.credit_rating    :=   inv_cust_rec.credit_rating;
l_customer_profile_rec.risk_code    :=   inv_cust_rec.risk_code;
l_customer_profile_rec.standard_terms    :=   l_term_id;
l_customer_profile_rec.override_terms    :=   inv_cust_rec.override_terms;
l_customer_profile_rec.dunning_letter_set_id    :=   inv_cust_rec.dunning_letter_set_id;
l_customer_profile_rec.interest_period_days    :=   inv_cust_rec.interest_period_days;
l_customer_profile_rec.payment_grace_days    :=   inv_cust_rec.payment_grace_days;
l_customer_profile_rec.discount_grace_days    :=   inv_cust_rec.discount_grace_days;
l_customer_profile_rec.statement_cycle_id    :=   inv_cust_rec.statement_cycle_id;
l_customer_profile_rec.account_status    :=   inv_cust_rec.account_status;
l_customer_profile_rec.percent_collectable    :=   inv_cust_rec.percent_collectable;
l_customer_profile_rec.autocash_hierarchy_id    :=   inv_cust_rec.autocash_hierarchy_id;
l_customer_profile_rec.attribute_category    :=   inv_cust_rec.attribute_category;
l_customer_profile_rec.attribute1    :=   inv_cust_rec.attribute1;
l_customer_profile_rec.attribute2    :=   inv_cust_rec.attribute2;
l_customer_profile_rec.attribute3    :=   inv_cust_rec.attribute3;
l_customer_profile_rec.attribute4    :=   inv_cust_rec.attribute4;
l_customer_profile_rec.attribute5    :=   inv_cust_rec.attribute5;
l_customer_profile_rec.attribute6    :=   inv_cust_rec.attribute6;
l_customer_profile_rec.attribute7    :=   inv_cust_rec.attribute7;
l_customer_profile_rec.attribute8    :=   inv_cust_rec.attribute8;
l_customer_profile_rec.attribute9    :=   inv_cust_rec.attribute9;
l_customer_profile_rec.attribute10    :=   inv_cust_rec.attribute10;
l_customer_profile_rec.attribute11    :=   inv_cust_rec.attribute11;
l_customer_profile_rec.attribute12    :=   inv_cust_rec.attribute12;
l_customer_profile_rec.attribute13    :=   inv_cust_rec.attribute13;
l_customer_profile_rec.attribute14    :=   inv_cust_rec.attribute14;
l_customer_profile_rec.attribute15    :=   inv_cust_rec.attribute15;
l_customer_profile_rec.auto_rec_incl_disputed_flag    :=   inv_cust_rec.auto_rec_incl_disputed_flag;
l_customer_profile_rec.tax_printing_option    :=   inv_cust_rec.tax_printing_option;
l_customer_profile_rec.charge_on_finance_charge_flag    :=   inv_cust_rec.charge_on_finance_charge_flag;
l_customer_profile_rec.grouping_rule_id    :=   inv_cust_rec.grouping_rule_id;
l_customer_profile_rec.clearing_days    :=   inv_cust_rec.clearing_days;
l_customer_profile_rec.jgzz_attribute_category    :=   inv_cust_rec.jgzz_attribute_category;
l_customer_profile_rec.jgzz_attribute1    :=   inv_cust_rec.jgzz_attribute1;
l_customer_profile_rec.jgzz_attribute2    :=   inv_cust_rec.jgzz_attribute2;
l_customer_profile_rec.jgzz_attribute3    :=   inv_cust_rec.jgzz_attribute3;
l_customer_profile_rec.jgzz_attribute4    :=   inv_cust_rec.jgzz_attribute4;
l_customer_profile_rec.jgzz_attribute5    :=   inv_cust_rec.jgzz_attribute5;
l_customer_profile_rec.jgzz_attribute6    :=   inv_cust_rec.jgzz_attribute6;
l_customer_profile_rec.jgzz_attribute7    :=   inv_cust_rec.jgzz_attribute7;
l_customer_profile_rec.jgzz_attribute8    :=   inv_cust_rec.jgzz_attribute8;
l_customer_profile_rec.jgzz_attribute9    :=   inv_cust_rec.jgzz_attribute9;
l_customer_profile_rec.jgzz_attribute10    :=   inv_cust_rec.jgzz_attribute10;
l_customer_profile_rec.jgzz_attribute11    :=   inv_cust_rec.jgzz_attribute11;
l_customer_profile_rec.jgzz_attribute12    :=   inv_cust_rec.jgzz_attribute12;
l_customer_profile_rec.jgzz_attribute13    :=   inv_cust_rec.jgzz_attribute13;
l_customer_profile_rec.jgzz_attribute14    :=   inv_cust_rec.jgzz_attribute14;
l_customer_profile_rec.jgzz_attribute15    :=   inv_cust_rec.jgzz_attribute15;
l_customer_profile_rec.global_attribute1    :=   inv_cust_rec.global_attribute1;
l_customer_profile_rec.global_attribute2    :=   inv_cust_rec.global_attribute2;
l_customer_profile_rec.global_attribute3    :=   inv_cust_rec.global_attribute3;
l_customer_profile_rec.global_attribute4    :=   inv_cust_rec.global_attribute4;
l_customer_profile_rec.global_attribute5    :=   inv_cust_rec.global_attribute5;
l_customer_profile_rec.global_attribute6    :=   inv_cust_rec.global_attribute6;
l_customer_profile_rec.global_attribute7    :=   inv_cust_rec.global_attribute7;
l_customer_profile_rec.global_attribute8    :=   inv_cust_rec.global_attribute8;
l_customer_profile_rec.global_attribute9    :=   inv_cust_rec.global_attribute9;
l_customer_profile_rec.global_attribute10    :=   inv_cust_rec.global_attribute10;
l_customer_profile_rec.global_attribute11    :=   inv_cust_rec.global_attribute11;
l_customer_profile_rec.global_attribute12    :=   inv_cust_rec.global_attribute12;
l_customer_profile_rec.global_attribute13    :=   inv_cust_rec.global_attribute13;
l_customer_profile_rec.global_attribute14    :=   inv_cust_rec.global_attribute14;
l_customer_profile_rec.global_attribute15    :=   inv_cust_rec.global_attribute15;
l_customer_profile_rec.global_attribute16    :=   inv_cust_rec.global_attribute16;
l_customer_profile_rec.global_attribute17    :=   inv_cust_rec.global_attribute17;
l_customer_profile_rec.global_attribute18    :=   inv_cust_rec.global_attribute18;
l_customer_profile_rec.global_attribute19    :=   inv_cust_rec.global_attribute19;
l_customer_profile_rec.global_attribute20    :=   inv_cust_rec.global_attribute20;
l_customer_profile_rec.global_attribute_category    :=   inv_cust_rec.global_attribute_category;
l_customer_profile_rec.cons_inv_flag                :=   inv_cust_rec.cons_inv_flag;
l_customer_profile_rec.cons_inv_type                :=   inv_cust_rec.cons_inv_type;
l_customer_profile_rec.autocash_hierarchy_id_for_adr    :=   inv_cust_rec.autocash_hierarchy_id_for_adr;
l_customer_profile_rec.lockbox_matching_option      :=   inv_cust_rec.lockbox_matching_option;
l_customer_profile_rec.created_by_module            :=   inv_cust_rec.created_by_module;
l_customer_profile_rec.application_id               :=   inv_cust_rec.application_id;
l_customer_profile_rec.review_cycle                 :=   inv_cust_rec.review_cycle;
l_customer_profile_rec.last_credit_review_date      :=   inv_cust_rec.last_credit_review_date;
l_customer_profile_rec.party_id                     :=   inv_cust_rec.party_id;
l_customer_profile_rec.credit_classification        :=   inv_cust_rec.credit_classification;
l_object_version_number                             :=   inv_cust_rec.object_version_number;
l_standard_terms                                    :=   inv_cust_rec.term_id;
l_cust_account_id                                   :=   inv_cust_rec.cust_account_id;



HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile(
    FND_API.G_FALSE                       ,
    l_customer_profile_rec              ,
    l_object_version_number                ,
    l_return_status                       ,
    l_msg_count                         ,
    l_msg_data                             
);
IF l_msg_count > 0
THEN
    dbms_output.put_line('The Payment Term Update failed for Customer Number: '||l_customer_number);

      

         FOR v_index IN 1 .. l_msg_count

         LOOP

            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => v_msg_index_out);

            v_message := SUBSTR (l_msg_data, 1, 200);

            DBMS_OUTPUT.put_line (l_msg_data);

            DBMS_OUTPUT.put_line ('============================================================');

         END LOOP;

 

         DBMS_OUTPUT.put_line (SUBSTR (v_message, 1, 2000));
         DBMS_OUTPUT.put_line ('============================================================');

ELSE 

l_count_account := l_count_account+1;

      END IF;


l_count_site := 0;

FOR cust_site_rec IN INV_CUST_SITE(l_cust_account_id)
LOOP



l_customer_site_rec.cust_account_profile_id    :=   cust_site_rec.cust_account_profile_id;
l_customer_site_rec.cust_account_id    :=   cust_site_rec.cust_account_id;
l_customer_site_rec.status    :=   cust_site_rec.status;
l_customer_site_rec.collector_id    :=   cust_site_rec.collector_id;
l_customer_site_rec.credit_analyst_id    :=   cust_site_rec.credit_analyst_id;
l_customer_site_rec.credit_checking    :=   cust_site_rec.credit_checking;
l_customer_site_rec.next_credit_review_date    :=   cust_site_rec.next_credit_review_date;
l_customer_site_rec.tolerance    :=   cust_site_rec.tolerance;
l_customer_site_rec.discount_terms    :=   cust_site_rec.discount_terms;
l_customer_site_rec.dunning_letters    :=   cust_site_rec.dunning_letters;
l_customer_site_rec.interest_charges    :=   cust_site_rec.interest_charges;
l_customer_site_rec.send_statements    :=   cust_site_rec.send_statements;
l_customer_site_rec.credit_balance_statements    :=   cust_site_rec.credit_balance_statements;
l_customer_site_rec.credit_hold    :=   cust_site_rec.credit_hold;
l_customer_site_rec.profile_class_id    :=   cust_site_rec.profile_class_id;
l_customer_site_rec.site_use_id    :=   cust_site_rec.site_use_id;
l_customer_site_rec.credit_rating    :=   cust_site_rec.credit_rating;
l_customer_site_rec.risk_code    :=   cust_site_rec.risk_code;
l_customer_site_rec.standard_terms    :=   l_term_id;
l_customer_site_rec.override_terms    :=   cust_site_rec.override_terms;
l_customer_site_rec.dunning_letter_set_id    :=   cust_site_rec.dunning_letter_set_id;
l_customer_site_rec.interest_period_days    :=   cust_site_rec.interest_period_days;
l_customer_site_rec.payment_grace_days    :=   cust_site_rec.payment_grace_days;
l_customer_site_rec.discount_grace_days    :=   cust_site_rec.discount_grace_days;
l_customer_site_rec.statement_cycle_id    :=   cust_site_rec.statement_cycle_id;
l_customer_site_rec.account_status    :=   cust_site_rec.account_status;
l_customer_site_rec.percent_collectable    :=   cust_site_rec.percent_collectable;
l_customer_site_rec.autocash_hierarchy_id    :=   cust_site_rec.autocash_hierarchy_id;
l_customer_site_rec.attribute_category    :=   cust_site_rec.attribute_category;
l_customer_site_rec.attribute1    :=   cust_site_rec.attribute1;
l_customer_site_rec.attribute2    :=   cust_site_rec.attribute2;
l_customer_site_rec.attribute3    :=   cust_site_rec.attribute3;
l_customer_site_rec.attribute4    :=   cust_site_rec.attribute4;
l_customer_site_rec.attribute5    :=   cust_site_rec.attribute5;
l_customer_site_rec.attribute6    :=   cust_site_rec.attribute6;
l_customer_site_rec.attribute7    :=   cust_site_rec.attribute7;
l_customer_site_rec.attribute8    :=   cust_site_rec.attribute8;
l_customer_site_rec.attribute9    :=   cust_site_rec.attribute9;
l_customer_site_rec.attribute10    :=   cust_site_rec.attribute10;
l_customer_site_rec.attribute11    :=   cust_site_rec.attribute11;
l_customer_site_rec.attribute12    :=   cust_site_rec.attribute12;
l_customer_site_rec.attribute13    :=   cust_site_rec.attribute13;
l_customer_site_rec.attribute14    :=   cust_site_rec.attribute14;
l_customer_site_rec.attribute15    :=   cust_site_rec.attribute15;
l_customer_site_rec.auto_rec_incl_disputed_flag    :=   cust_site_rec.auto_rec_incl_disputed_flag;
l_customer_site_rec.tax_printing_option    :=   cust_site_rec.tax_printing_option;
l_customer_site_rec.charge_on_finance_charge_flag    :=   cust_site_rec.charge_on_finance_charge_flag;
l_customer_site_rec.grouping_rule_id    :=   cust_site_rec.grouping_rule_id;
l_customer_site_rec.clearing_days    :=   cust_site_rec.clearing_days;
l_customer_site_rec.jgzz_attribute_category    :=   cust_site_rec.jgzz_attribute_category;
l_customer_site_rec.jgzz_attribute1    :=   cust_site_rec.jgzz_attribute1;
l_customer_site_rec.jgzz_attribute2    :=   cust_site_rec.jgzz_attribute2;
l_customer_site_rec.jgzz_attribute3    :=   cust_site_rec.jgzz_attribute3;
l_customer_site_rec.jgzz_attribute4    :=   cust_site_rec.jgzz_attribute4;
l_customer_site_rec.jgzz_attribute5    :=   cust_site_rec.jgzz_attribute5;
l_customer_site_rec.jgzz_attribute6    :=   cust_site_rec.jgzz_attribute6;
l_customer_site_rec.jgzz_attribute7    :=   cust_site_rec.jgzz_attribute7;
l_customer_site_rec.jgzz_attribute8    :=   cust_site_rec.jgzz_attribute8;
l_customer_site_rec.jgzz_attribute9    :=   cust_site_rec.jgzz_attribute9;
l_customer_site_rec.jgzz_attribute10    :=   cust_site_rec.jgzz_attribute10;
l_customer_site_rec.jgzz_attribute11    :=   cust_site_rec.jgzz_attribute11;
l_customer_site_rec.jgzz_attribute12    :=   cust_site_rec.jgzz_attribute12;
l_customer_site_rec.jgzz_attribute13    :=   cust_site_rec.jgzz_attribute13;
l_customer_site_rec.jgzz_attribute14    :=   cust_site_rec.jgzz_attribute14;
l_customer_site_rec.jgzz_attribute15    :=   cust_site_rec.jgzz_attribute15;
l_customer_site_rec.global_attribute1    :=   cust_site_rec.global_attribute1;
l_customer_site_rec.global_attribute2    :=   cust_site_rec.global_attribute2;
l_customer_site_rec.global_attribute3    :=   cust_site_rec.global_attribute3;
l_customer_site_rec.global_attribute4    :=   cust_site_rec.global_attribute4;
l_customer_site_rec.global_attribute5    :=   cust_site_rec.global_attribute5;
l_customer_site_rec.global_attribute6    :=   cust_site_rec.global_attribute6;
l_customer_site_rec.global_attribute7    :=   cust_site_rec.global_attribute7;
l_customer_site_rec.global_attribute8    :=   cust_site_rec.global_attribute8;
l_customer_site_rec.global_attribute9    :=   cust_site_rec.global_attribute9;
l_customer_site_rec.global_attribute10    :=   cust_site_rec.global_attribute10;
l_customer_site_rec.global_attribute11    :=   cust_site_rec.global_attribute11;
l_customer_site_rec.global_attribute12    :=   cust_site_rec.global_attribute12;
l_customer_site_rec.global_attribute13    :=   cust_site_rec.global_attribute13;
l_customer_site_rec.global_attribute14    :=   cust_site_rec.global_attribute14;
l_customer_site_rec.global_attribute15    :=   cust_site_rec.global_attribute15;
l_customer_site_rec.global_attribute16    :=   cust_site_rec.global_attribute16;
l_customer_site_rec.global_attribute17    :=   cust_site_rec.global_attribute17;
l_customer_site_rec.global_attribute18    :=   cust_site_rec.global_attribute18;
l_customer_site_rec.global_attribute19    :=   cust_site_rec.global_attribute19;
l_customer_site_rec.global_attribute20    :=   cust_site_rec.global_attribute20;
l_customer_site_rec.global_attribute_category    :=   cust_site_rec.global_attribute_category;
l_customer_site_rec.cons_inv_flag    :=   cust_site_rec.cons_inv_flag;
l_customer_site_rec.cons_inv_type    :=   cust_site_rec.cons_inv_type;
l_customer_site_rec.autocash_hierarchy_id_for_adr    :=   cust_site_rec.autocash_hierarchy_id_for_adr;
l_customer_site_rec.lockbox_matching_option    :=   cust_site_rec.lockbox_matching_option;
l_customer_site_rec.created_by_module    :=   cust_site_rec.created_by_module;
l_customer_site_rec.application_id    :=   cust_site_rec.application_id;
l_customer_site_rec.review_cycle    :=   cust_site_rec.review_cycle;
l_customer_site_rec.last_credit_review_date    :=   cust_site_rec.last_credit_review_date;
l_customer_site_rec.party_id    :=   cust_site_rec.party_id;
l_customer_site_rec.credit_classification    :=   cust_site_rec.credit_classification;
l_object_version_number1    :=   cust_site_rec.object_version_number;



HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile(
    FND_API.G_FALSE                       ,
    l_customer_site_rec              ,
    l_object_version_number1                ,
    l_return_status1                       ,
    l_msg_count1                         ,
    l_msg_data1                             );

IF l_msg_count1 > 0
  THEN
    dbms_output.put_line('The Payment Term Update failed for Customer Number: '||l_customer_number);

    

         FOR v_index IN 1 .. l_msg_count1

         LOOP

            fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => l_msg_data1, p_msg_index_out => v_msg_index_out1);

            v_message1 := SUBSTR (l_msg_data1, 1, 200);

            DBMS_OUTPUT.put_line (l_msg_data1);

            DBMS_OUTPUT.put_line ('============================================================');

         END LOOP;

 

         DBMS_OUTPUT.put_line (SUBSTR (v_message1, 1, 2000));
         DBMS_OUTPUT.put_line ('============================================================');

ELSE 

l_count_site := l_count_site+1;

      END IF;

END LOOP;

l_count_site_all := l_count_site_all+l_count_site;


END LOOP;


dbms_output.put_line('Total Number Of Customer Accounts Updated  = '||l_count_account);
dbms_output.put_line('Total Number Of Customer Sites Updated  = '||l_count_site_all);



END;
		