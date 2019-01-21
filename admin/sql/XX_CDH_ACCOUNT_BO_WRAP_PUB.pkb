SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_ACCOUNT_BO_WRAP_PUB
-- +=========================================================================================+
-- |                  Office Depot                                                           |
-- +=========================================================================================+
-- | Name        : XX_CDH_ACCOUNT_BO_WRAP_PUB                                            |
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

function get_orig_system_ref_id(
                                 p_orig_system in varchar2,
                                 p_orig_system_reference in varchar2, 
                                 p_owner_table_name in varchar2) 
return varchar2
is
        cursor get_orig_sys_ref_id_csr 
        is
        SELECT ORIG_SYSTEM_REF_ID
        FROM   HZ_ORIG_SYS_REFERENCES
        WHERE  ORIG_SYSTEM = p_orig_system
        and ORIG_SYSTEM_REFERENCE = p_orig_system_reference
        and owner_table_name = p_owner_table_name
        and status = 'A';

l_orig_system_ref_id number;
begin
        open get_orig_sys_ref_id_csr;
        fetch get_orig_sys_ref_id_csr into l_orig_system_ref_id;
        close get_orig_sys_ref_id_csr;
        return l_orig_system_ref_id;
end get_orig_system_ref_id;

function get_os_owner_table_id(
                                 p_orig_system in varchar2,
                                 p_orig_system_reference in varchar2, 
                                 p_owner_table_name in varchar2) 
return varchar2
is
        cursor get_os_owner_table_id_csr 
        is
        SELECT OWNER_TABLE_ID
        FROM   HZ_ORIG_SYS_REFERENCES
        WHERE  ORIG_SYSTEM = p_orig_system
        and ORIG_SYSTEM_REFERENCE = p_orig_system_reference
        and owner_table_name = p_owner_table_name
        and status = 'A';

l_os_owner_table_id number;
begin
        open get_os_owner_table_id_csr;
        fetch get_os_owner_table_id_csr into l_os_owner_table_id;
        close get_os_owner_table_id_csr;
        return l_os_owner_table_id;
end get_os_owner_table_id;

-- +===================================================================+
-- | Name        : is_account_exists                                   |
-- | Description : Function to checks whether customer account         |
-- |               already exists or not                               |
-- | Parameters  : p_acct_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_account_exists
    (
        p_acct_orig_sys_ref                VARCHAR2
       ,p_acct_orig_sys                    VARCHAR2

    )
RETURN NUMBER
IS

lc_acct_orig_sys_ref    VARCHAR2(2000) := p_acct_orig_sys_ref;
lc_acct_orig_sys        VARCHAR2(2000) := p_acct_orig_sys;
ln_cust_account_id      NUMBER;

BEGIN

   SELECT owner_table_id
   INTO   ln_cust_account_id
   FROM   hz_orig_sys_references
   WHERE  orig_system_reference = lc_acct_orig_sys_ref
   AND    orig_system           = lc_acct_orig_sys
   AND    owner_table_name      = 'HZ_CUST_ACCOUNTS'
   AND    status                = 'A';

   RETURN ln_cust_account_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_account_exists;


-- +===================================================================+
-- | Name        : is_acct_site_exists                                 |
-- | Description : Function to check whether customer account site     |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys                      |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_exists
    (
        p_site_orig_sys_ref  VARCHAR2
       ,p_site_orig_sys      VARCHAR2

    )
RETURN NUMBER
IS

lc_site_orig_sys_ref    VARCHAR2(2000) := p_site_orig_sys_ref;
lc_site_orig_sys        VARCHAR2(2000) := p_site_orig_sys;
ln_acct_site_id         NUMBER;

BEGIN

   SELECT hosr.owner_table_id
   INTO   ln_acct_site_id
   FROM   hz_orig_sys_references hosr,
          hz_cust_acct_sites     hcas
   WHERE  hosr.orig_system_reference  = lc_site_orig_sys_ref
   AND    hosr.orig_system            = lc_site_orig_sys
   AND    hosr.owner_table_name       = 'HZ_CUST_ACCT_SITES_ALL'
   AND    hosr.status                 = 'A'
   AND    hcas.cust_acct_site_id      = hosr.owner_table_id;

   RETURN   ln_acct_site_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;


END is_acct_site_exists ;


-- +===================================================================+
-- | Name        : is_acct_site_use_exists                             |
-- | Description : Function to check whether customer account site use |
-- |               already exists or not                               |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION is_acct_site_use_exists
    (
        p_site_orig_sys_ref                VARCHAR2
       ,p_orig_sys                         VARCHAR2
       ,p_site_code                        VARCHAR2

    )
RETURN NUMBER
IS

lc_site_orig_sys_ref    VARCHAR2(2000) := p_site_orig_sys_ref;
lc_orig_sys             VARCHAR2(2000) := p_orig_sys;
ln_site_use_id          NUMBER;

BEGIN

   SELECT hcsu.site_use_id
   INTO   ln_site_use_id
   FROM   apps.hz_orig_sys_references hosr,
          apps.hz_cust_acct_sites     hcs,
          apps.hz_cust_site_uses      hcsu
   WHERE  hosr.orig_system_reference  = p_site_orig_sys_ref
   AND    hosr.orig_system            = p_orig_sys
   AND    hcs.status                  = 'A'
   AND    hosr.owner_table_name       = 'HZ_CUST_ACCT_SITES_ALL'
   AND    hosr.status                 = 'A'
   AND    hcsu.status                 = 'A'
   AND    hcs.cust_acct_site_id       = hosr.owner_table_id
   AND    hcs.cust_acct_site_id       = hcsu.cust_acct_site_id
   AND    hcsu.site_use_code          = p_site_code;

   RETURN ln_site_use_id;

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN NULL;

END is_acct_site_use_exists;

-- +===================================================================+
-- | Name        : bill_to_use_id_val                                  |
-- | Description : Funtion to get bill_to_use_id                       |
-- |                                                                   |
-- | Parameters  : p_site_orig_sys_ref,p_orig_sys,p_site_code          |
-- |                                                                   |
-- +===================================================================+
FUNCTION bill_to_use_id_val
    (
         p_bill_to_orig_sys                     IN      VARCHAR2
        ,p_bill_to_orig_add_ref                 IN      VARCHAR2
    )

RETURN NUMBER
AS
ln_site_use_id  NUMBER := NULL;
BEGIN

    IF(p_bill_to_orig_sys IS NOT NULL AND p_bill_to_orig_add_ref IS NOT NULL)THEN

        BEGIN
            SELECT hosr.owner_table_id
            INTO   ln_site_use_id
            FROM   hz_orig_sys_references hosr,
                   hz_cust_site_uses      hcsu
            WHERE  hosr.orig_system           = p_bill_to_orig_sys
            AND    hosr.orig_system_reference = p_bill_to_orig_add_ref
            AND    hosr.owner_table_name      = 'HZ_CUST_SITE_USES_ALL'
            AND    hosr.status                = 'A'
            AND    hcsu.site_use_id           = hosr.owner_table_id;

            RETURN ln_site_use_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
            WHEN OTHERS THEN
                RETURN NULL;
        END;

    END IF;

END bill_to_use_id_val;

-- +===================================================================+
-- | Name        : ar_lookup_val                                       |
-- | Description : This procedure checks for the lookup value from     |
-- |               AR_LOOKUPS table                                    |
-- |                                                                   |
-- | Parameters  : p_lookup_type,p_lookup_code                         |
-- |                                                                   |
-- +===================================================================+
FUNCTION ar_lookup_val
    (
         p_lookup_type     IN VARCHAR2
        ,p_lookup_code     IN VARCHAR2

    )

RETURN BOOLEAN

AS
lc_temp_var VARCHAR(1);
BEGIN
    IF (p_lookup_code IS NOT NULL) THEN
        BEGIN
            SELECT  '1'
            INTO    lc_temp_var
            FROM    ar_lookups
            WHERE   lookup_type = p_lookup_type
            AND     lookup_code = p_lookup_code;
            RETURN TRUE;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN FALSE;
        END;
    END IF;
    RETURN TRUE;
END ar_lookup_val;

  -- PRIVATE PROCEDURE assign_payment_method_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from payment method object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_payment_method_obj Payment method object.
  --     p_cust_acct_id       Customer account Id.
  --     p_site_use_id        Customer account site use Id.
  --   IN/OUT:
  --     px_payment_method_rec Payment method plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_payment_method_rec(
    p_payment_method_obj         IN            HZ_PAYMENT_METHOD_OBJ,
    p_cust_acct_id               IN            NUMBER,
    p_site_use_id                IN            NUMBER,
    px_payment_method_rec        IN OUT NOCOPY HZ_PAYMENT_METHOD_PUB.PAYMENT_METHOD_REC_TYPE
  ) IS
  BEGIN
    px_payment_method_rec.cust_receipt_method_id := p_payment_method_obj.payment_method_id;
    px_payment_method_rec.cust_account_id := p_cust_acct_id;
    px_payment_method_rec.receipt_method_id := p_payment_method_obj.receipt_method_id;
    px_payment_method_rec.primary_flag := p_payment_method_obj.primary_flag;
    px_payment_method_rec.site_use_id := p_site_use_id;
    px_payment_method_rec.start_date := p_payment_method_obj.start_date;
    px_payment_method_rec.end_date := p_payment_method_obj.end_date;
    px_payment_method_rec.attribute_category := p_payment_method_obj.attribute_category;
    px_payment_method_rec.attribute1 := p_payment_method_obj.attribute1;
    px_payment_method_rec.attribute2 := p_payment_method_obj.attribute2;
    px_payment_method_rec.attribute3 := p_payment_method_obj.attribute3;
    px_payment_method_rec.attribute4 := p_payment_method_obj.attribute4;
    px_payment_method_rec.attribute5 := p_payment_method_obj.attribute5;
    px_payment_method_rec.attribute6 := p_payment_method_obj.attribute6;
    px_payment_method_rec.attribute7 := p_payment_method_obj.attribute7;
    px_payment_method_rec.attribute8 := p_payment_method_obj.attribute8;
    px_payment_method_rec.attribute9 := p_payment_method_obj.attribute9;
    px_payment_method_rec.attribute10 := p_payment_method_obj.attribute10;
    px_payment_method_rec.attribute11 := p_payment_method_obj.attribute11;
    px_payment_method_rec.attribute12 := p_payment_method_obj.attribute12;
    px_payment_method_rec.attribute13 := p_payment_method_obj.attribute13;
    px_payment_method_rec.attribute14 := p_payment_method_obj.attribute14;
    px_payment_method_rec.attribute15 := p_payment_method_obj.attribute15;
  END assign_payment_method_rec;

  -- PRIVATE PROCEDURE assign_cust_profile_amt_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from customer profile amount object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_cust_profile_amt_obj Customer profile amount object.
  --     p_cust_profile_id    Customer profile Id.
  --     p_cust_acct_id       Customer account Id.
  --     p_site_use_id        Customer account site use Id.
  --   IN/OUT:
  --     px_cust_profile_amt_rec  Customer profile amount plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_cust_profile_amt_rec(
    p_cust_profile_amt_obj       IN            HZ_CUST_PROFILE_AMT_OBJ,
    p_cust_profile_id            IN            NUMBER,
    p_cust_acct_id               IN            NUMBER,
    p_site_use_id                IN            NUMBER,
    px_cust_profile_amt_rec      IN OUT NOCOPY HZ_CUSTOMER_PROFILE_V2PUB.CUST_PROFILE_AMT_REC_TYPE
  ) IS
  BEGIN
    px_cust_profile_amt_rec.cust_acct_profile_amt_id := p_cust_profile_amt_obj.cust_acct_profile_amt_id;
    px_cust_profile_amt_rec.cust_account_profile_id  := p_cust_profile_id;
    px_cust_profile_amt_rec.cust_account_id       := p_cust_acct_id;
    px_cust_profile_amt_rec.currency_code         := p_cust_profile_amt_obj.currency_code;
    px_cust_profile_amt_rec.trx_credit_limit := p_cust_profile_amt_obj.trx_credit_limit;
    px_cust_profile_amt_rec.overall_credit_limit  := p_cust_profile_amt_obj.overall_credit_limit;
    px_cust_profile_amt_rec.min_dunning_amount    := p_cust_profile_amt_obj.min_dunning_amount;
    px_cust_profile_amt_rec.min_dunning_invoice_amount  := p_cust_profile_amt_obj.min_dunning_invoice_amount;
    px_cust_profile_amt_rec.max_interest_charge   := p_cust_profile_amt_obj.max_interest_charge;
    px_cust_profile_amt_rec.min_statement_amount  := p_cust_profile_amt_obj.min_statement_amount;
    px_cust_profile_amt_rec.auto_rec_min_receipt_amount := p_cust_profile_amt_obj.auto_rec_min_receipt_amount;
    px_cust_profile_amt_rec.interest_rate  := p_cust_profile_amt_obj.interest_rate;
    px_cust_profile_amt_rec.min_fc_balance_amount := p_cust_profile_amt_obj.min_fc_balance_amount;
    px_cust_profile_amt_rec.min_fc_invoice_amount := p_cust_profile_amt_obj.min_fc_invoice_amount;
    px_cust_profile_amt_rec.site_use_id           := p_site_use_id;
    px_cust_profile_amt_rec.expiration_date       := p_cust_profile_amt_obj.expiration_date;
    px_cust_profile_amt_rec.attribute_category    := p_cust_profile_amt_obj.attribute_category;
    px_cust_profile_amt_rec.attribute1            := p_cust_profile_amt_obj.attribute1;
    px_cust_profile_amt_rec.attribute2            := p_cust_profile_amt_obj.attribute2;
    px_cust_profile_amt_rec.attribute3            := p_cust_profile_amt_obj.attribute3;
    px_cust_profile_amt_rec.attribute4            := p_cust_profile_amt_obj.attribute4;
    px_cust_profile_amt_rec.attribute5            := p_cust_profile_amt_obj.attribute5;
    px_cust_profile_amt_rec.attribute6            := p_cust_profile_amt_obj.attribute6;
    px_cust_profile_amt_rec.attribute7            := p_cust_profile_amt_obj.attribute7;
    px_cust_profile_amt_rec.attribute8            := p_cust_profile_amt_obj.attribute8;
    px_cust_profile_amt_rec.attribute9            := p_cust_profile_amt_obj.attribute9;
    px_cust_profile_amt_rec.attribute10           := p_cust_profile_amt_obj.attribute10;
    px_cust_profile_amt_rec.attribute11           := p_cust_profile_amt_obj.attribute11;
    px_cust_profile_amt_rec.attribute12           := p_cust_profile_amt_obj.attribute12;
    px_cust_profile_amt_rec.attribute13           := p_cust_profile_amt_obj.attribute13;
    px_cust_profile_amt_rec.attribute14           := p_cust_profile_amt_obj.attribute14;
    px_cust_profile_amt_rec.attribute15           := p_cust_profile_amt_obj.attribute15;
    px_cust_profile_amt_rec.jgzz_attribute_category    := p_cust_profile_amt_obj.jgzz_attribute_category;
    px_cust_profile_amt_rec.jgzz_attribute1    := p_cust_profile_amt_obj.jgzz_attribute1;
    px_cust_profile_amt_rec.jgzz_attribute2    := p_cust_profile_amt_obj.jgzz_attribute2;
    px_cust_profile_amt_rec.jgzz_attribute3    := p_cust_profile_amt_obj.jgzz_attribute3;
    px_cust_profile_amt_rec.jgzz_attribute4    := p_cust_profile_amt_obj.jgzz_attribute4;
    px_cust_profile_amt_rec.jgzz_attribute5    := p_cust_profile_amt_obj.jgzz_attribute5;
    px_cust_profile_amt_rec.jgzz_attribute6    := p_cust_profile_amt_obj.jgzz_attribute6;
    px_cust_profile_amt_rec.jgzz_attribute7    := p_cust_profile_amt_obj.jgzz_attribute7;
    px_cust_profile_amt_rec.jgzz_attribute8    := p_cust_profile_amt_obj.jgzz_attribute8;
    px_cust_profile_amt_rec.jgzz_attribute9    := p_cust_profile_amt_obj.jgzz_attribute9;
    px_cust_profile_amt_rec.jgzz_attribute10   := p_cust_profile_amt_obj.jgzz_attribute10;
    px_cust_profile_amt_rec.jgzz_attribute11   := p_cust_profile_amt_obj.jgzz_attribute11;
    px_cust_profile_amt_rec.jgzz_attribute12   := p_cust_profile_amt_obj.jgzz_attribute12;
    px_cust_profile_amt_rec.jgzz_attribute13   := p_cust_profile_amt_obj.jgzz_attribute13;
    px_cust_profile_amt_rec.jgzz_attribute14   := p_cust_profile_amt_obj.jgzz_attribute14;
    px_cust_profile_amt_rec.jgzz_attribute15   := p_cust_profile_amt_obj.jgzz_attribute15;
    px_cust_profile_amt_rec.global_attribute_category    := p_cust_profile_amt_obj.global_attribute_category;
    px_cust_profile_amt_rec.global_attribute1  := p_cust_profile_amt_obj.global_attribute1;
    px_cust_profile_amt_rec.global_attribute2  := p_cust_profile_amt_obj.global_attribute2;
    px_cust_profile_amt_rec.global_attribute3  := p_cust_profile_amt_obj.global_attribute3;
    px_cust_profile_amt_rec.global_attribute4  := p_cust_profile_amt_obj.global_attribute4;
    px_cust_profile_amt_rec.global_attribute5  := p_cust_profile_amt_obj.global_attribute5;
    px_cust_profile_amt_rec.global_attribute6  := p_cust_profile_amt_obj.global_attribute6;
    px_cust_profile_amt_rec.global_attribute7  := p_cust_profile_amt_obj.global_attribute7;
    px_cust_profile_amt_rec.global_attribute8  := p_cust_profile_amt_obj.global_attribute8;
    px_cust_profile_amt_rec.global_attribute9  := p_cust_profile_amt_obj.global_attribute9;
    px_cust_profile_amt_rec.global_attribute10 := p_cust_profile_amt_obj.global_attribute10;
    px_cust_profile_amt_rec.global_attribute11 := p_cust_profile_amt_obj.global_attribute11;
    px_cust_profile_amt_rec.global_attribute12 := p_cust_profile_amt_obj.global_attribute12;
    px_cust_profile_amt_rec.global_attribute13 := p_cust_profile_amt_obj.global_attribute13;
    px_cust_profile_amt_rec.global_attribute14 := p_cust_profile_amt_obj.global_attribute14;
    px_cust_profile_amt_rec.global_attribute15 := p_cust_profile_amt_obj.global_attribute15;
    px_cust_profile_amt_rec.global_attribute16 := p_cust_profile_amt_obj.global_attribute16;
    px_cust_profile_amt_rec.global_attribute17 := p_cust_profile_amt_obj.global_attribute17;
    px_cust_profile_amt_rec.global_attribute18 := p_cust_profile_amt_obj.global_attribute18;
    px_cust_profile_amt_rec.global_attribute19 := p_cust_profile_amt_obj.global_attribute19;
    px_cust_profile_amt_rec.global_attribute20 := p_cust_profile_amt_obj.global_attribute20;
    px_cust_profile_amt_rec.created_by_module  := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
  END assign_cust_profile_amt_rec;

  -- PROCEDURE assign_cust_profile_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from customer profile object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_cust_profile_obj   Customer profile object.
  --     p_cust_acct_id       Customer account Id.
  --     p_site_use_id        Customer account site use Id.
  --   IN/OUT:
  --     px_cust_profile_rec  Customer profile plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_cust_profile_rec(
    p_cust_profile_obj           IN            HZ_CUSTOMER_PROFILE_BO,
    p_cust_acct_id               IN            NUMBER,
    p_site_use_id                IN            NUMBER,
    px_cust_profile_rec          IN OUT NOCOPY HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE
  ) IS
    l_customer_type VARCHAR2(30) := NULL;
  BEGIN
  
    px_cust_profile_rec.cust_account_profile_id :=p_cust_profile_obj.cust_acct_profile_id;
    px_cust_profile_rec.cust_account_id :=p_cust_acct_id;
    IF(p_cust_profile_obj.status in ('A','I')) THEN
      px_cust_profile_rec.status :=p_cust_profile_obj.status;
    END IF;
    px_cust_profile_rec.collector_id :=p_cust_profile_obj.collector_id;
    px_cust_profile_rec.credit_analyst_id :=p_cust_profile_obj.credit_analyst_id;
    px_cust_profile_rec.credit_checking :=p_cust_profile_obj.credit_checking;
    px_cust_profile_rec.next_credit_review_date :=p_cust_profile_obj.next_credit_review_date;
    px_cust_profile_rec.tolerance :=p_cust_profile_obj.tolerance;
    IF(p_cust_profile_obj.discount_terms in ('Y','N')) THEN
      px_cust_profile_rec.discount_terms :=p_cust_profile_obj.discount_terms;
    END IF;
    px_cust_profile_rec.dunning_letters :=p_cust_profile_obj.dunning_letters;
    IF(p_cust_profile_obj.interest_charges in ('Y','N')) THEN
      px_cust_profile_rec.interest_charges :=p_cust_profile_obj.interest_charges;
    END IF;
    IF(p_cust_profile_obj.send_statements in ('Y','N')) THEN
      px_cust_profile_rec.send_statements :=p_cust_profile_obj.send_statements;
    END IF;
    IF(p_cust_profile_obj.credit_balance_statements in ('Y','N')) THEN
      px_cust_profile_rec.credit_balance_statements :=p_cust_profile_obj.credit_balance_statements;
    END IF;
    IF(p_cust_profile_obj.credit_hold in ('Y','N')) THEN
      px_cust_profile_rec.credit_hold :=p_cust_profile_obj.credit_hold;
    END IF;
    px_cust_profile_rec.profile_class_id :=p_cust_profile_obj.profile_class_id;
    px_cust_profile_rec.site_use_id :=p_site_use_id;
    px_cust_profile_rec.credit_rating :=p_cust_profile_obj.credit_rating;
    px_cust_profile_rec.risk_code :=p_cust_profile_obj.risk_code;
    px_cust_profile_rec.standard_terms :=p_cust_profile_obj.standard_terms;
    px_cust_profile_rec.override_terms :=p_cust_profile_obj.override_terms;
    px_cust_profile_rec.dunning_letter_set_id :=p_cust_profile_obj.dunning_letter_set_id;
    px_cust_profile_rec.interest_period_days :=p_cust_profile_obj.interest_period_days;
    px_cust_profile_rec.payment_grace_days :=p_cust_profile_obj.payment_grace_days;
    px_cust_profile_rec.discount_grace_days :=p_cust_profile_obj.discount_grace_days;
    px_cust_profile_rec.statement_cycle_id :=p_cust_profile_obj.statement_cycle_id;
    px_cust_profile_rec.account_status :=p_cust_profile_obj.account_status;
    px_cust_profile_rec.percent_collectable :=p_cust_profile_obj.percent_collectable;
    px_cust_profile_rec.autocash_hierarchy_id :=p_cust_profile_obj.autocash_hierarchy_id;
    px_cust_profile_rec.attribute_category :=p_cust_profile_obj.attribute_category;
    px_cust_profile_rec.attribute1 :=p_cust_profile_obj.attribute1;
    px_cust_profile_rec.attribute2 :=p_cust_profile_obj.attribute2;
    px_cust_profile_rec.attribute3 :=p_cust_profile_obj.attribute3;
    px_cust_profile_rec.attribute4 :=p_cust_profile_obj.attribute4;
    px_cust_profile_rec.attribute5 :=p_cust_profile_obj.attribute5;
    px_cust_profile_rec.attribute6 :=p_cust_profile_obj.attribute6;
    px_cust_profile_rec.attribute7 :=p_cust_profile_obj.attribute7;
    px_cust_profile_rec.attribute8 :=p_cust_profile_obj.attribute8;
    px_cust_profile_rec.attribute9 :=p_cust_profile_obj.attribute9;
    px_cust_profile_rec.attribute10 :=p_cust_profile_obj.attribute10;
    px_cust_profile_rec.attribute11 :=p_cust_profile_obj.attribute11;
    px_cust_profile_rec.attribute12 :=p_cust_profile_obj.attribute12;
    px_cust_profile_rec.attribute13 :=p_cust_profile_obj.attribute13;
    px_cust_profile_rec.attribute14 :=p_cust_profile_obj.attribute14;
    px_cust_profile_rec.attribute15 :=p_cust_profile_obj.attribute15;
    px_cust_profile_rec.auto_rec_incl_disputed_flag :=p_cust_profile_obj.auto_rec_incl_disputed_flag;
    px_cust_profile_rec.tax_printing_option :=p_cust_profile_obj.tax_printing_option;
    IF(p_cust_profile_obj.charge_on_fin_charge_flag in ('Y','N')) THEN
      px_cust_profile_rec.charge_on_finance_charge_flag :=p_cust_profile_obj.charge_on_fin_charge_flag;
    END IF;
    px_cust_profile_rec.grouping_rule_id :=p_cust_profile_obj.grouping_rule_id;
    px_cust_profile_rec.clearing_days :=p_cust_profile_obj.clearing_days;
    px_cust_profile_rec.jgzz_attribute_category :=p_cust_profile_obj.jgzz_attribute_category;
    px_cust_profile_rec.jgzz_attribute1 :=p_cust_profile_obj.jgzz_attribute1;
    px_cust_profile_rec.jgzz_attribute2 :=p_cust_profile_obj.jgzz_attribute2;
    px_cust_profile_rec.jgzz_attribute3 :=p_cust_profile_obj.jgzz_attribute3;
    px_cust_profile_rec.jgzz_attribute4 :=p_cust_profile_obj.jgzz_attribute4;
    px_cust_profile_rec.jgzz_attribute5 :=p_cust_profile_obj.jgzz_attribute5;
    px_cust_profile_rec.jgzz_attribute6 :=p_cust_profile_obj.jgzz_attribute6;
    px_cust_profile_rec.jgzz_attribute7 :=p_cust_profile_obj.jgzz_attribute7;
    px_cust_profile_rec.jgzz_attribute8 :=p_cust_profile_obj.jgzz_attribute8;
    px_cust_profile_rec.jgzz_attribute9 :=p_cust_profile_obj.jgzz_attribute9;
    px_cust_profile_rec.jgzz_attribute10 :=p_cust_profile_obj.jgzz_attribute10;
    px_cust_profile_rec.jgzz_attribute11 :=p_cust_profile_obj.jgzz_attribute11;
    px_cust_profile_rec.jgzz_attribute12 :=p_cust_profile_obj.jgzz_attribute12;
    px_cust_profile_rec.jgzz_attribute13 :=p_cust_profile_obj.jgzz_attribute13;
    px_cust_profile_rec.jgzz_attribute14 :=p_cust_profile_obj.jgzz_attribute14;
    px_cust_profile_rec.jgzz_attribute15 :=p_cust_profile_obj.jgzz_attribute15;
    px_cust_profile_rec.global_attribute1 :=p_cust_profile_obj.global_attribute1;
    px_cust_profile_rec.global_attribute2 :=p_cust_profile_obj.global_attribute2;
    px_cust_profile_rec.global_attribute3 :=p_cust_profile_obj.global_attribute3;
    px_cust_profile_rec.global_attribute4 :=p_cust_profile_obj.global_attribute4;
    px_cust_profile_rec.global_attribute5 :=p_cust_profile_obj.global_attribute5;
    px_cust_profile_rec.global_attribute6 :=p_cust_profile_obj.global_attribute6;
    px_cust_profile_rec.global_attribute7 :=p_cust_profile_obj.global_attribute7;
    px_cust_profile_rec.global_attribute8 :=p_cust_profile_obj.global_attribute8;
    px_cust_profile_rec.global_attribute9 :=p_cust_profile_obj.global_attribute9;
    px_cust_profile_rec.global_attribute10 :=p_cust_profile_obj.global_attribute10;
    px_cust_profile_rec.global_attribute11 :=p_cust_profile_obj.global_attribute11;
    px_cust_profile_rec.global_attribute12 :=p_cust_profile_obj.global_attribute12;
    px_cust_profile_rec.global_attribute13 :=p_cust_profile_obj.global_attribute13;
    px_cust_profile_rec.global_attribute14 :=p_cust_profile_obj.global_attribute14;
    px_cust_profile_rec.global_attribute15 :=p_cust_profile_obj.global_attribute15;
    px_cust_profile_rec.global_attribute16 :=p_cust_profile_obj.global_attribute16;
    px_cust_profile_rec.global_attribute17 :=p_cust_profile_obj.global_attribute17;
    px_cust_profile_rec.global_attribute18 :=p_cust_profile_obj.global_attribute18;
    px_cust_profile_rec.global_attribute19 :=p_cust_profile_obj.global_attribute19;
    px_cust_profile_rec.global_attribute20 :=p_cust_profile_obj.global_attribute20;
    px_cust_profile_rec.global_attribute_category :=p_cust_profile_obj.global_attribute_category;
    IF(p_cust_profile_obj.cons_inv_flag in ('Y','N')) THEN
      px_cust_profile_rec.cons_inv_flag :=p_cust_profile_obj.cons_inv_flag;
    END IF;
    px_cust_profile_rec.cons_inv_type :=p_cust_profile_obj.cons_inv_type;
    px_cust_profile_rec.autocash_hierarchy_id_for_adr :=p_cust_profile_obj.autocash_hier_id_for_adr;
    px_cust_profile_rec.lockbox_matching_option :=p_cust_profile_obj.lockbox_matching_option;
    px_cust_profile_rec.created_by_module :=HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
    px_cust_profile_rec.review_cycle :=p_cust_profile_obj.review_cycle;
    px_cust_profile_rec.last_credit_review_date :=p_cust_profile_obj.last_credit_review_date;
    --px_cust_profile_rec.party_id :=p_cust_profile_obj.party_id;
    px_cust_profile_rec.credit_classification :=p_cust_profile_obj.credit_classification;

  END assign_cust_profile_rec;

  -- PRIVATE PROCEDURE assign_cust_acct_relate_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from customer account relationship object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_cust_acct_relate_obj   Customer account relationship object.
  --     p_cust_acct_id           Customer account Id.
  --     p_related_cust_acct_id   Related customer account Id.
  --   IN/OUT:
  --     px_cust_acct_relate_rec  Customer account relationship plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_cust_acct_relate_rec(
    p_cust_acct_relate_obj       IN            HZ_CUST_ACCT_RELATE_OBJ,
    p_cust_acct_id               IN            NUMBER,
    p_related_cust_acct_id       IN            NUMBER,
    px_cust_acct_relate_rec      IN OUT NOCOPY HZ_CUST_ACCOUNT_V2PUB.CUST_ACCT_RELATE_REC_TYPE
  ) IS
  BEGIN
    px_cust_acct_relate_rec.cust_account_id := p_cust_acct_id;
    px_cust_acct_relate_rec.related_cust_account_id := p_related_cust_acct_id;
    px_cust_acct_relate_rec.relationship_type := p_cust_acct_relate_obj.relationship_type;
    px_cust_acct_relate_rec.comments := p_cust_acct_relate_obj.comments;
    IF(p_cust_acct_relate_obj.customer_reciprocal_flag in ('Y','N')) THEN
      px_cust_acct_relate_rec.customer_reciprocal_flag := p_cust_acct_relate_obj.customer_reciprocal_flag;
    END IF;
    px_cust_acct_relate_rec.attribute_category := p_cust_acct_relate_obj.attribute_category;
    px_cust_acct_relate_rec.attribute1 := p_cust_acct_relate_obj.attribute1;
    px_cust_acct_relate_rec.attribute2 := p_cust_acct_relate_obj.attribute2;
    px_cust_acct_relate_rec.attribute3 := p_cust_acct_relate_obj.attribute3;
    px_cust_acct_relate_rec.attribute4 := p_cust_acct_relate_obj.attribute4;
    px_cust_acct_relate_rec.attribute5 := p_cust_acct_relate_obj.attribute5;
    px_cust_acct_relate_rec.attribute6 := p_cust_acct_relate_obj.attribute6;
    px_cust_acct_relate_rec.attribute7 := p_cust_acct_relate_obj.attribute7;
    px_cust_acct_relate_rec.attribute8 := p_cust_acct_relate_obj.attribute8;
    px_cust_acct_relate_rec.attribute9 := p_cust_acct_relate_obj.attribute9;
    px_cust_acct_relate_rec.attribute10 := p_cust_acct_relate_obj.attribute10;
    px_cust_acct_relate_rec.attribute11 := p_cust_acct_relate_obj.attribute11;
    px_cust_acct_relate_rec.attribute12 := p_cust_acct_relate_obj.attribute12;
    px_cust_acct_relate_rec.attribute13 := p_cust_acct_relate_obj.attribute13;
    px_cust_acct_relate_rec.attribute14 := p_cust_acct_relate_obj.attribute14;
    px_cust_acct_relate_rec.attribute15 := p_cust_acct_relate_obj.attribute15;
    IF(p_cust_acct_relate_obj.status in ('A','I')) THEN
      px_cust_acct_relate_rec.status := p_cust_acct_relate_obj.status;
    END IF;
    px_cust_acct_relate_rec.bill_to_flag := p_cust_acct_relate_obj.bill_to_flag;
    px_cust_acct_relate_rec.ship_to_flag := p_cust_acct_relate_obj.ship_to_flag;
    px_cust_acct_relate_rec.created_by_module := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

  END assign_cust_acct_relate_rec;

  -- PRIVATE PROCEDURE assign_cust_acct_rec
  --
  -- DESCRIPTION
  --     Assign attribute value from customer account object to plsql record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_cust_acct_obj      Customer account object.
  --     p_cust_acct_id       Customer account Id.
  --     p_cust_acct_os       Customer account original system.
  --     p_cust_acct_osr      Customer account original system reference.
  --     p_create_or_update   Create or update flag.
  --   IN/OUT:
  --     px_cust_acct_rec     Customer Account plsql record.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   26-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE assign_cust_acct_rec(
    p_cust_acct_obj           IN            HZ_CUST_ACCT_BO,
    p_cust_acct_id            IN            NUMBER,
    p_cust_acct_os            IN            VARCHAR2,
    p_cust_acct_osr           IN            VARCHAR2,
    p_create_or_update        IN            VARCHAR2 := 'C',
    px_cust_acct_rec          IN OUT NOCOPY HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE
  ) IS
  BEGIN
    px_cust_acct_rec.cust_account_id        := p_cust_acct_id;
    px_cust_acct_rec.account_number         := p_cust_acct_obj.account_number;
    IF(p_cust_acct_obj.status in ('A','I')) THEN
      px_cust_acct_rec.status                 := p_cust_acct_obj.status;
    END IF;
    px_cust_acct_rec.customer_type          := p_cust_acct_obj.customer_type;
    px_cust_acct_rec.customer_class_code    := p_cust_acct_obj.customer_class_code;
    px_cust_acct_rec.primary_salesrep_id    := p_cust_acct_obj.primary_salesrep_id;
    px_cust_acct_rec.sales_channel_code     := p_cust_acct_obj.sales_channel_code;
    px_cust_acct_rec.order_type_id          := p_cust_acct_obj.order_type_id;
    px_cust_acct_rec.price_list_id          := p_cust_acct_obj.price_list_id;
    px_cust_acct_rec.tax_code               := p_cust_acct_obj.tax_code;
    px_cust_acct_rec.fob_point              := p_cust_acct_obj.fob_point;
    px_cust_acct_rec.freight_term           := p_cust_acct_obj.freight_term;
    px_cust_acct_rec.ship_partial           := p_cust_acct_obj.ship_partial;
    px_cust_acct_rec.ship_via               := p_cust_acct_obj.ship_via;
    px_cust_acct_rec.warehouse_id           := p_cust_acct_obj.warehouse_id;
    IF(p_cust_acct_obj.tax_header_level_flag in ('Y','N')) THEN
      px_cust_acct_rec.tax_header_level_flag  := p_cust_acct_obj.tax_header_level_flag;
    END IF;
    px_cust_acct_rec.tax_rounding_rule      := p_cust_acct_obj.tax_rounding_rule;
    px_cust_acct_rec.coterminate_day_month  := p_cust_acct_obj.coterminate_day_month;
    px_cust_acct_rec.primary_specialist_id  := p_cust_acct_obj.primary_specialist_id;
    px_cust_acct_rec.secondary_specialist_id := p_cust_acct_obj.secondary_specialist_id;
    IF(p_cust_acct_obj.account_liable_flag in ('Y','N')) THEN
      px_cust_acct_rec.account_liable_flag    := p_cust_acct_obj.account_liable_flag;
    END IF;
    px_cust_acct_rec.current_balance        := p_cust_acct_obj.current_balance;
    px_cust_acct_rec.account_established_date := p_cust_acct_obj.account_established_date;
    px_cust_acct_rec.account_termination_date := p_cust_acct_obj.account_termination_date;
    px_cust_acct_rec.account_activation_date  := p_cust_acct_obj.account_activation_date;
    px_cust_acct_rec.department               := p_cust_acct_obj.department;
    px_cust_acct_rec.held_bill_expiration_date:= p_cust_acct_obj.held_bill_expiration_date;
    IF(p_cust_acct_obj.hold_bill_flag in ('Y','N')) THEN
      px_cust_acct_rec.hold_bill_flag := p_cust_acct_obj.hold_bill_flag;
    END IF;
    px_cust_acct_rec.realtime_rate_flag := p_cust_acct_obj.realtime_rate_flag;
    px_cust_acct_rec.acct_life_cycle_status := p_cust_acct_obj.acct_life_cycle_status;
    px_cust_acct_rec.account_name := p_cust_acct_obj.account_name;
    px_cust_acct_rec.deposit_refund_method := p_cust_acct_obj.deposit_refund_method;
    IF(p_cust_acct_obj.dormant_account_flag in ('Y','N')) THEN
      px_cust_acct_rec.dormant_account_flag := p_cust_acct_obj.dormant_account_flag;
    END IF;
    px_cust_acct_rec.npa_number := p_cust_acct_obj.npa_number;
    px_cust_acct_rec.suspension_date := p_cust_acct_obj.suspension_date;
    px_cust_acct_rec.source_code := p_cust_acct_obj.source_code;
    px_cust_acct_rec.comments := p_cust_acct_obj.comments;
    px_cust_acct_rec.dates_negative_tolerance := p_cust_acct_obj.dates_negative_tolerance;
    px_cust_acct_rec.dates_positive_tolerance := p_cust_acct_obj.dates_positive_tolerance;
    px_cust_acct_rec.date_type_preference := p_cust_acct_obj.date_type_preference;
    px_cust_acct_rec.over_shipment_tolerance := p_cust_acct_obj.over_shipment_tolerance;
    px_cust_acct_rec.under_shipment_tolerance := p_cust_acct_obj.under_shipment_tolerance;
    px_cust_acct_rec.over_return_tolerance := p_cust_acct_obj.over_return_tolerance;
    px_cust_acct_rec.under_return_tolerance := p_cust_acct_obj.under_return_tolerance;
    px_cust_acct_rec.item_cross_ref_pref := p_cust_acct_obj.item_cross_ref_pref;
    IF(p_cust_acct_obj.ship_sets_include_lines_flag in ('Y','N')) THEN
      px_cust_acct_rec.ship_sets_include_lines_flag := p_cust_acct_obj.ship_sets_include_lines_flag;
    END IF;
    IF(p_cust_acct_obj.arrivalsets_incl_lines_flag in ('Y','N')) THEN
      px_cust_acct_rec.arrivalsets_include_lines_flag := p_cust_acct_obj.arrivalsets_incl_lines_flag;
    END IF;
    IF(p_cust_acct_obj.sched_date_push_flag in ('Y','N')) THEN
      px_cust_acct_rec.sched_date_push_flag := p_cust_acct_obj.sched_date_push_flag;
    END IF;
    px_cust_acct_rec.invoice_quantity_rule := p_cust_acct_obj.invoice_quantity_rule;
    px_cust_acct_rec.pricing_event := p_cust_acct_obj.pricing_event;
    px_cust_acct_rec.status_update_date := p_cust_acct_obj.status_update_date;
    IF(p_cust_acct_obj.autopay_flag in ('Y','N')) THEN
      px_cust_acct_rec.autopay_flag := p_cust_acct_obj.autopay_flag;
    END IF;
    IF(p_cust_acct_obj.notify_flag in ('Y','N')) THEN
      px_cust_acct_rec.notify_flag := p_cust_acct_obj.notify_flag;
    END IF;
    px_cust_acct_rec.last_batch_id := p_cust_acct_obj.last_batch_id;
    px_cust_acct_rec.selling_party_id := p_cust_acct_obj.selling_party_id;
    IF(p_create_or_update = 'C') THEN
      px_cust_acct_rec.orig_system            := p_cust_acct_os;
      px_cust_acct_rec.orig_system_reference  := p_cust_acct_osr;
      px_cust_acct_rec.created_by_module := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;
    END IF;
    px_cust_acct_rec.attribute_category   := p_cust_acct_obj.attribute_category;
    px_cust_acct_rec.attribute1           := p_cust_acct_obj.attribute1;
    px_cust_acct_rec.attribute2           := p_cust_acct_obj.attribute2;
    px_cust_acct_rec.attribute3           := p_cust_acct_obj.attribute3;
    px_cust_acct_rec.attribute4           := p_cust_acct_obj.attribute4;
    px_cust_acct_rec.attribute5           := p_cust_acct_obj.attribute5;
    px_cust_acct_rec.attribute6           := p_cust_acct_obj.attribute6;
    px_cust_acct_rec.attribute7           := p_cust_acct_obj.attribute7;
    px_cust_acct_rec.attribute8           := p_cust_acct_obj.attribute8;
    px_cust_acct_rec.attribute9           := p_cust_acct_obj.attribute9;
    px_cust_acct_rec.attribute10          := p_cust_acct_obj.attribute10;
    px_cust_acct_rec.attribute11          := p_cust_acct_obj.attribute11;
    px_cust_acct_rec.attribute12          := p_cust_acct_obj.attribute12;
    px_cust_acct_rec.attribute13          := p_cust_acct_obj.attribute13;
    px_cust_acct_rec.attribute14          := p_cust_acct_obj.attribute14;
    px_cust_acct_rec.attribute15          := p_cust_acct_obj.attribute15;
    px_cust_acct_rec.attribute16          := p_cust_acct_obj.attribute16;
    px_cust_acct_rec.attribute17          := p_cust_acct_obj.attribute17;
    px_cust_acct_rec.attribute18          := p_cust_acct_obj.attribute18;
    px_cust_acct_rec.attribute19          := p_cust_acct_obj.attribute19;
    px_cust_acct_rec.attribute20          := p_cust_acct_obj.attribute20;
    px_cust_acct_rec.global_attribute_category   := p_cust_acct_obj.global_attribute_category;
    px_cust_acct_rec.global_attribute1    := p_cust_acct_obj.global_attribute1;
    px_cust_acct_rec.global_attribute2    := p_cust_acct_obj.global_attribute2;
    px_cust_acct_rec.global_attribute3    := p_cust_acct_obj.global_attribute3;
    px_cust_acct_rec.global_attribute4    := p_cust_acct_obj.global_attribute4;
    px_cust_acct_rec.global_attribute5    := p_cust_acct_obj.global_attribute5;
    px_cust_acct_rec.global_attribute6    := p_cust_acct_obj.global_attribute6;
    px_cust_acct_rec.global_attribute7    := p_cust_acct_obj.global_attribute7;
    px_cust_acct_rec.global_attribute8    := p_cust_acct_obj.global_attribute8;
    px_cust_acct_rec.global_attribute9    := p_cust_acct_obj.global_attribute9;
    px_cust_acct_rec.global_attribute10   := p_cust_acct_obj.global_attribute10;
    px_cust_acct_rec.global_attribute11   := p_cust_acct_obj.global_attribute11;
    px_cust_acct_rec.global_attribute12   := p_cust_acct_obj.global_attribute12;
    px_cust_acct_rec.global_attribute13   := p_cust_acct_obj.global_attribute13;
    px_cust_acct_rec.global_attribute14   := p_cust_acct_obj.global_attribute14;
    px_cust_acct_rec.global_attribute15   := p_cust_acct_obj.global_attribute15;
    px_cust_acct_rec.global_attribute16   := p_cust_acct_obj.global_attribute16;
    px_cust_acct_rec.global_attribute17   := p_cust_acct_obj.global_attribute17;
    px_cust_acct_rec.global_attribute18   := p_cust_acct_obj.global_attribute18;
    px_cust_acct_rec.global_attribute19   := p_cust_acct_obj.global_attribute19;
    px_cust_acct_rec.global_attribute20   := p_cust_acct_obj.global_attribute20;
  END assign_cust_acct_rec;

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

PROCEDURE do_copy_cust_profiles (
                                  p_bo_process_id           IN         NUMBER,
                                  p_bpel_process_id         IN         NUMBER,
                                  p_cust_account_profile_id IN         NUMBER,
                                  p_cust_account_id         IN         NUMBER,
                                  x_return_status           OUT NOCOPY VARCHAR2,
                                  x_msg_count               OUT NOCOPY VARCHAR2,
                                  x_msg_data                OUT NOCOPY VARCHAR2
                                 )
AS
  --
    prof_rec        hz_customer_profile_v2pub.customer_profile_rec_type;
    l_check         varchar2(1);
    l_count         number;

    l_return_status            varchar2(1)     := 'S';
    l_msg_count                number          := 0;
    l_msg_data                 varchar2(2000)  := null;
    l_cust_account_profile_id  number          := 0;
    l_object_version_number    number;

    --pick all the 'BILL_TO' site uses for the given cust_account_id
    CURSOR c_site_uses (p_cust_account_id number)
    is
    select csu.site_use_id , csu.org_id
    from   hz_cust_accounts_all   ca,
           hz_cust_acct_sites_all cas,
           hz_cust_site_uses_all  csu
   where   ca.cust_account_id=cas.cust_account_id and
           cas.cust_acct_site_id=csu.cust_acct_site_id and
           csu.site_use_code='BILL_TO' and
           ca.cust_account_id = p_cust_account_id;

    cursor c_is_site_use_exist (p_cust_account_id in number,
                              p_site_use_id in number)
    is
    select 'Y',
           cust_account_profile_id
    from   hz_customer_profiles
    where  cust_account_id = p_cust_account_id and
           site_use_id = p_site_use_id;

  --
  BEGIN
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_copy_cust_profiles(+)');
  
    x_return_status := 'S';
    l_count := 0;
    for c_rec in c_site_uses(p_cust_account_id)
    loop
       --
       fnd_client_info.set_org_context(c_rec.org_id);
       l_count := l_count + 1;
       l_check := null;
       l_cust_account_profile_id := null;

       prof_rec  := NULL;
       HZ_CUSTOMER_PROFILE_V2PUB.get_customer_profile_rec (
            p_init_msg_list                         => 'T',
            p_cust_account_profile_id               => p_cust_account_profile_id,
            x_customer_profile_rec                  => prof_rec,
            x_return_status                         => l_return_status,
            x_msg_count                             => l_msg_count,
            x_msg_data                              => l_msg_data
          );

        if( l_return_status = 'S') then

             --check if profile exist at site level
            open c_is_site_use_exist(p_cust_account_id, c_rec.site_use_id);
            fetch c_is_site_use_exist into l_check, l_cust_account_profile_id;

            if (c_is_site_use_exist%ROWCOUNT <1) then
              --site_use_id do not exist create profile at site level
              --
              -- we are sending p_create_profile_amt as null, as we indend to copy
              -- customer profile from account level to site level only.
              --
              prof_rec.cust_account_profile_id := null;
              prof_rec.site_use_id := c_rec.site_use_id;
              l_return_status  := null;
              l_msg_count      := 0;
              l_msg_data       := null;
              --
              HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile (
               p_init_msg_list                      => 'T',
               p_customer_profile_rec               => prof_rec,
               x_cust_account_profile_id            => l_cust_account_profile_id,
               x_return_status                      => l_return_status,
               x_msg_count                          => l_msg_count,
               x_msg_data                           => l_msg_data
              );
              --
              XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'do_copy_cust_profiles after create_customer_profile, l_return_status: ' || l_return_status);
              --
              if l_return_status != 'S' THEN
                  if l_msg_count > 0 THEN
                    begin
                      FOR I IN 1..l_msg_count
                      LOOP
                         l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                      END LOOP;
                    end;
                      XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'do_copy_cust_profiles after create_customer_profile, l_msg_data: ' || l_msg_data);
                  end if;
                  x_return_status := l_return_status;
                  x_msg_count     := l_msg_count;
                  x_msg_data      := l_msg_data;
                  RETURN;
              END IF;
              --
              commit;
      else
        --customer profile at site exist. Now go for updating the profile
        select object_version_number
        into   l_object_version_number
        from   hz_customer_profiles
        where  cust_account_profile_id = l_cust_account_profile_id;

              prof_rec.cust_account_profile_id := l_cust_account_profile_id;
              prof_rec.site_use_id := null;
              prof_rec.created_by_module := null;
              l_return_status  := null;
              l_msg_count      := 0;
              l_msg_data       := null;
              --
              HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile (
               p_init_msg_list                      => 'T',
               p_customer_profile_rec               => prof_rec,
               p_object_version_number              => l_object_version_number,
               x_return_status                      => l_return_status,
               x_msg_count                          => l_msg_count,
               x_msg_data                           => l_msg_data
              );
              --
              XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'do_copy_cust_profiles after update_customer_profile, l_return_status: ' || l_return_status);
              --
              if l_return_status != 'S' THEN
                  if l_msg_count > 0 THEN
                    begin
                      FOR I IN 1..l_msg_count
                      LOOP
                         l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                      END LOOP;
                    end;
                      XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'do_copy_cust_profiles after update_customer_profile, l_msg_data: ' || l_msg_data);
                  end if;
                  x_return_status := l_return_status;
                  x_msg_count     := l_msg_count;
                  x_msg_data      := l_msg_data;
                  RETURN;
              END IF;
              --
              commit;

      end if;
      close c_is_site_use_exist;
     ELSE
            x_return_status := l_return_status;
            x_msg_count     := l_msg_count;
            x_msg_data      := l_msg_data;
            RETURN ;
     end if;
    
    end loop;
    
      x_return_status := l_return_status;
      x_msg_count     := l_msg_count;
      x_msg_data      := l_msg_data;
  
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_copy_cust_profiles(-)');

EXCEPTION
  WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_copy_cust_profiles'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_profile_id       
                                              , P_ORIG_SYSTEM            =>  null
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null
                                              , P_EXCEPTION_LOG          =>  'Exception in do_copy_cust_profiles '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      X_RETURN_STATUS := 'E';   
      --X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_copy_cust_profiles'   || SQLERRM;
END do_copy_cust_profiles;

  -- PROCEDURE create_cust_acct_relates
  --
  -- DESCRIPTION
  --     Create customer account relationships.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_car_objs           List of customer account relationship objects.
  --     p_ca_id              Customer account Id.
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

  PROCEDURE create_cust_acct_relates(
    p_car_objs                IN OUT NOCOPY HZ_CUST_ACCT_RELATE_OBJ_TBL,
    p_ca_id                   IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  ) IS
    l_return_status           VARCHAR2(1) := x_return_status;
    l_msg_count              number;
    l_msg_data               varchar2(2000) := x_errbuf;    
    l_debug_prefix            VARCHAR2(30) := '';
    l_car_rec                 HZ_CUST_ACCOUNT_V2PUB.CUST_ACCT_RELATE_REC_TYPE;
    l_rca_id                  NUMBER;
    l_rca_os                  VARCHAR2(30);
    l_rca_osr                 VARCHAR2(255);
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_car_pvt;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.create_cust_acct_relates(+)');

    -- Create cust account relates
    FOR i IN 1..p_car_objs.COUNT LOOP
      -- get related cust account id
      -- check if related cust account os and osr is valid
      l_rca_id := p_car_objs(i).related_cust_acct_id;
      l_rca_os := p_car_objs(i).related_cust_acct_os;
      l_rca_osr := p_car_objs(i).related_cust_acct_osr;

      -- check cust_account_id and os+osr
      hz_registry_validate_bo_pvt.validate_ssm_id(
        px_id              => l_rca_id,
        px_os              => l_rca_os,
        px_osr             => l_rca_osr,
        p_obj_type         => 'HZ_CUST_ACCOUNTS',
        p_create_or_update => 'U',
        x_return_status    => x_return_status,
        x_msg_count        => x_msg_count,
        x_msg_data         => x_msg_data);

      -- proceed if cust_account_id and os+osr are valid
      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
        assign_cust_acct_relate_rec(
          p_cust_acct_relate_obj      => p_car_objs(i),
          p_cust_acct_id              => p_ca_id,
          p_related_cust_acct_id      => l_rca_id,
          px_cust_acct_relate_rec     => l_car_rec
        );

        HZ_CUST_ACCOUNT_V2PUB.create_cust_acct_relate(
          p_cust_acct_relate_rec      => l_car_rec,
          x_return_status             => x_return_status,
          x_msg_count                 => x_msg_count,
          x_msg_data                  => x_msg_data
        );

        IF l_return_status = 'S' THEN
        
          XX_CDH_CUST_UTIL_BO_PUB.save_gt(
                        P_BO_PROCESS_ID          =>  p_bo_process_id,
                        P_BO_ENTITY_NAME         =>  'HZ_CUST_ACCOUNT_RELATES',
                        P_BO_TABLE_ID            =>  l_rca_id,
                        P_ORIG_SYSTEM            =>  l_rca_os,
                        P_ORIG_SYSTEM_REFERENCE  =>  l_rca_osr
                    );
        
        ELSE
          --call exception process
          l_msg_data := null;
          FOR i IN 1 .. l_msg_count
          LOOP
             l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
          END LOOP;
          XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                    P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                                  , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                                  , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_RELATE_OBJ'            
                                                  , P_LOG_DATE               =>  SYSDATE             
                                                  , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                                  , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                                  , P_PROCEDURE_NAME         =>  'create_cust_acct_relates'              
                                                  , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCT_RELATE'        
                                                  , P_BO_COLUMN_NAME         =>  'RELATED_CUST_ACCOUNT_ID'       
                                                  , P_BO_COLUMN_VALUE        =>  l_rca_id       
                                                  , P_ORIG_SYSTEM            =>  l_rca_os
                                                  , P_ORIG_SYSTEM_REFERENCE  =>  l_rca_osr
                                                  , P_EXCEPTION_LOG          =>  l_msg_data        
                                                  , P_ORACLE_ERROR_CODE      =>  null    
                                                  , P_ORACLE_ERROR_MSG       =>  null 
                                                );
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;       
    END LOOP;
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.create_cust_acct_relates(-)');  
    
  EXCEPTION
      WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_RELATE_OBJ'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'create_cust_acct_relates'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCT_RELATE'        
                                              , P_BO_COLUMN_NAME         =>  'RELATED_CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_rca_id       
                                              , P_ORIG_SYSTEM            =>  l_rca_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_rca_osr
                                              , P_EXCEPTION_LOG          =>  'Exception in create_cust_acct_relates '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      X_RETURN_STATUS := 'E';   
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.create_cust_acct_relates'  || SQLERRM;
  END create_cust_acct_relates;

  -- PROCEDURE save_cust_acct_relates
  --
  -- DESCRIPTION
  --     Create or update customer account relationships.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_car_objs           List of customer account relationship objects.
  --     p_ca_id              Customer account Id.
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

  PROCEDURE save_cust_acct_relates(
    p_car_objs                IN OUT NOCOPY HZ_CUST_ACCT_RELATE_OBJ_TBL,
    p_ca_id                   IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  ) IS
    l_return_status           VARCHAR2(1) := x_return_status;
    l_msg_count              number;
    l_msg_data               varchar2(2000) := x_errbuf;    
    l_debug_prefix             VARCHAR2(30) := '';
    l_car_rec                  HZ_CUST_ACCOUNT_V2PUB.CUST_ACCT_RELATE_REC_TYPE;
    l_rca_id                   NUMBER;
    l_rca_os                   VARCHAR2(30);
    l_rca_osr                  VARCHAR2(255);
    l_ovn                      NUMBER;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT save_car_pvt;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_acct_relates(+)');

    -- Create/Update cust account relate
    FOR i IN 1..p_car_objs.COUNT LOOP
      -- get related cust account id
      -- check if related cust account os and osr is valid
      l_rca_id := p_car_objs(i).related_cust_acct_id;
      l_rca_os := p_car_objs(i).related_cust_acct_os;
      l_rca_osr := p_car_objs(i).related_cust_acct_osr;

      -- check related cust_account_id and os+osr
      hz_registry_validate_bo_pvt.validate_ssm_id(
        px_id              => l_rca_id,
        px_os              => l_rca_os,
        px_osr             => l_rca_osr,
        p_obj_type         => 'HZ_CUST_ACCOUNTS',
        p_create_or_update => 'U',
        x_return_status    => x_return_status,
        x_msg_count        => x_msg_count,
        x_msg_data         => x_msg_data);

      -- proceed if cust_account_id and os+osr are valid
      IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
        assign_cust_acct_relate_rec(
          p_cust_acct_relate_obj        => p_car_objs(i),
          p_cust_acct_id                => p_ca_id,
          p_related_cust_acct_id        => l_rca_id,
          px_cust_acct_relate_rec       => l_car_rec
        );

        -- check if the role resp record is create or update
        hz_registry_validate_bo_pvt.check_cust_acct_relate_op(
          p_cust_acct_id             => p_ca_id,
          p_related_cust_acct_id     => l_rca_id,
          x_object_version_number => l_ovn
        );

        IF(l_ovn IS NULL) THEN
          HZ_CUST_ACCOUNT_V2PUB.create_cust_acct_relate(
            p_cust_acct_relate_rec      => l_car_rec,
            x_return_status             => x_return_status,
            x_msg_count                 => x_msg_count,
            x_msg_data                  => x_msg_data
          );
        ELSE
          -- clean up created_by_module for update
          l_car_rec.created_by_module := NULL;
          HZ_CUST_ACCOUNT_V2PUB.update_cust_acct_relate(
            p_cust_acct_relate_rec      => l_car_rec,
            p_object_version_number     => l_ovn,
            x_return_status             => x_return_status,
            x_msg_count                 => x_msg_count,
            x_msg_data                  => x_msg_data
          );
        END IF;

        IF l_return_status = 'S' THEN
        
          XX_CDH_CUST_UTIL_BO_PUB.save_gt(
                        P_BO_PROCESS_ID          =>  p_bo_process_id,
                        P_BO_ENTITY_NAME         =>  'HZ_CUST_ACCOUNT_RELATES',
                        P_BO_TABLE_ID            =>  l_rca_id,
                        P_ORIG_SYSTEM            =>  l_rca_os,
                        P_ORIG_SYSTEM_REFERENCE  =>  l_rca_osr
                    );
        
        ELSE
          --call exception process
          l_msg_data := null;
          FOR i IN 1 .. l_msg_count
          LOOP
             l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
          END LOOP;
          XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                    P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                                  , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                                  , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_RELATE_OBJ'            
                                                  , P_LOG_DATE               =>  SYSDATE             
                                                  , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                                  , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                                  , P_PROCEDURE_NAME         =>  'save_cust_acct_relates'              
                                                  , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCT_RELATE'        
                                                  , P_BO_COLUMN_NAME         =>  'RELATED_CUST_ACCOUNT_ID'       
                                                  , P_BO_COLUMN_VALUE        =>  l_rca_id       
                                                  , P_ORIG_SYSTEM            =>  l_rca_os
                                                  , P_ORIG_SYSTEM_REFERENCE  =>  l_rca_osr
                                                  , P_EXCEPTION_LOG          =>  l_msg_data        
                                                  , P_ORACLE_ERROR_CODE      =>  null    
                                                  , P_ORACLE_ERROR_MSG       =>  null 
                                                );
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;       
    END LOOP;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_acct_relates(-)');
    
  EXCEPTION
      WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_RELATE_OBJ'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'save_cust_acct_relates'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCT_RELATE'        
                                              , P_BO_COLUMN_NAME         =>  'RELATED_CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_rca_id       
                                              , P_ORIG_SYSTEM            =>  l_rca_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_rca_osr
                                              , P_EXCEPTION_LOG          =>  'Exception in save_cust_acct_relates '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      X_RETURN_STATUS := 'E';   
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_acct_relates'    || SQLERRM;
END save_cust_acct_relates;

  -- PROCEDURE create_payment_method
  --
  -- DESCRIPTION
  --     Create payment method.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_payment_method_obj Payment method object.
  --     p_ca_id              Customer account Id.
  --     p_casu_id            Customer account site use Id.
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

  PROCEDURE create_payment_method(
    p_payment_method_obj      IN OUT NOCOPY HZ_PAYMENT_METHOD_OBJ,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  ) IS
    l_return_status           VARCHAR2(1) := x_return_status;
    l_msg_count              number;
    l_msg_data               varchar2(2000) := x_errbuf;    
    l_payment_method_rec           HZ_PAYMENT_METHOD_PUB.PAYMENT_METHOD_REC_TYPE;
    l_pm_id                        NUMBER;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_pm_pvt;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.create_payment_method(+)');

    assign_payment_method_rec(
      p_payment_method_obj         => p_payment_method_obj,
      p_cust_acct_id               => p_ca_id,
      p_site_use_id                => p_casu_id,
      px_payment_method_rec        => l_payment_method_rec
    );

    HZ_PAYMENT_METHOD_PUB.create_payment_method(
      p_payment_method_rec         => l_payment_method_rec,
      x_cust_receipt_method_id     => l_pm_id,
      x_return_status              => x_return_status,
      x_msg_count                  => x_msg_count,
      x_msg_data                   => x_msg_data
    );

    IF l_return_status = 'S' THEN
    
      XX_CDH_CUST_UTIL_BO_PUB.save_gt(
                    P_BO_PROCESS_ID          =>  p_bo_process_id,
                    P_BO_ENTITY_NAME         =>  'HZ_PAYMENT_METHODS',
                    P_BO_TABLE_ID            =>  l_pm_id,
                    P_ORIG_SYSTEM            =>  null,
                    P_ORIG_SYSTEM_REFERENCE  =>  null
                );
    
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_PAYMENT_METHOD_OBJ'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'create_paymentmethods'              
                                              , P_BO_TABLE_NAME          =>  'HZ_PAYMENT_METHOD'        
                                              , P_BO_COLUMN_NAME         =>  'PAYMENT_METHOD_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_pm_id       
                                              , P_ORIG_SYSTEM            =>  null
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null
                                              , P_EXCEPTION_LOG          =>  l_msg_data        
                                              , P_ORACLE_ERROR_CODE      =>  null    
                                              , P_ORACLE_ERROR_MSG       =>  null 
                                            );
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- assign payment_method_id
     p_payment_method_obj.payment_method_id := l_pm_id;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.create_payment_method(-)'); 
    
  EXCEPTION
    WHEN OTHERS THEN
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_PAYMENT_METHOD_OBJ'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'create_paymentmethods'              
                                              , P_BO_TABLE_NAME          =>  'HZ_PAYMENT_METHOD'        
                                              , P_BO_COLUMN_NAME         =>  'PAYMENT_METHOD_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_pm_id       
                                              , P_ORIG_SYSTEM            =>  null
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null
                                              , P_EXCEPTION_LOG          =>  'Exception in create_payment_method: ' || SQLERRM
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE   
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                            );  
      X_RETURN_STATUS := 'E';   
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts'    || SQLERRM;  
  END create_payment_method;

  -- PROCEDURE save_payment_method
  --
  -- DESCRIPTION
  --     Create or update payment method.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_payment_method_obj Payment method object.
  --     p_ca_id              Customer account Id.
  --     p_casu_id            Customer account site use Id.
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

  PROCEDURE save_payment_method(
    p_payment_method_obj      IN OUT NOCOPY HZ_PAYMENT_METHOD_OBJ,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  ) IS
    l_return_status           VARCHAR2(1) := x_return_status;
    l_msg_count              number;
    l_msg_data               varchar2(2000) := x_errbuf;    
    l_payment_method_rec           HZ_PAYMENT_METHOD_PUB.PAYMENT_METHOD_REC_TYPE;
    l_lud                          DATE;
    l_pm_id                        NUMBER;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT save_pm_pvt;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.save_payment_method(+)');

    assign_payment_method_rec(
      p_payment_method_obj         => p_payment_method_obj,
      p_cust_acct_id               => p_ca_id,
      p_site_use_id                => p_casu_id,
      px_payment_method_rec        => l_payment_method_rec
    );

    hz_registry_validate_bo_pvt.check_payment_method_op(
      p_cust_receipt_method_id     => l_payment_method_rec.cust_receipt_method_id,
      x_last_update_date           => l_lud
    );

    IF(l_lud IS NULL) THEN
      HZ_PAYMENT_METHOD_PUB.create_payment_method(
        p_payment_method_rec         => l_payment_method_rec,
        x_cust_receipt_method_id     => l_pm_id,
        x_return_status              => x_return_status,
        x_msg_count                  => x_msg_count,
        x_msg_data                   => x_msg_data
      );

      -- assign payment_method_id
      p_payment_method_obj.payment_method_id := l_pm_id;
    ELSE
      HZ_PAYMENT_METHOD_PUB.update_payment_method(
        p_payment_method_rec         => l_payment_method_rec,
        px_last_update_date          => l_lud,
        x_return_status              => x_return_status,
        x_msg_count                  => x_msg_count,
        x_msg_data                   => x_msg_data
      );

      -- assign payment_method_id
      p_payment_method_obj.payment_method_id := l_payment_method_rec.cust_receipt_method_id;
    END IF;

    IF l_return_status = 'S' THEN
    
      XX_CDH_CUST_UTIL_BO_PUB.save_gt(
                    P_BO_PROCESS_ID          =>  p_bo_process_id,
                    P_BO_ENTITY_NAME         =>  'HZ_PAYMENT_METHODS',
                    P_BO_TABLE_ID            =>  l_pm_id,
                    P_ORIG_SYSTEM            =>  null,
                    P_ORIG_SYSTEM_REFERENCE  =>  null
                );
    
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_PAYMENT_METHOD_OBJ'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'save_payment_method'              
                                              , P_BO_TABLE_NAME          =>  'HZ_PAYMENT_METHOD'        
                                              , P_BO_COLUMN_NAME         =>  'PAYMENT_METHOD_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_pm_id       
                                              , P_ORIG_SYSTEM            =>  null
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null
                                              , P_EXCEPTION_LOG          =>  l_msg_data        
                                              , P_ORACLE_ERROR_CODE      =>  null    
                                              , P_ORACLE_ERROR_MSG       =>  null 
                                            );
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.save_payment_method(-)');

  EXCEPTION
    WHEN OTHERS THEN
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_PAYMENT_METHOD_OBJ'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'save_payment_method'              
                                              , P_BO_TABLE_NAME          =>  'HZ_PAYMENT_METHOD'        
                                              , P_BO_COLUMN_NAME         =>  'PAYMENT_METHOD_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_pm_id       
                                              , P_ORIG_SYSTEM            =>  null
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null
                                              , P_EXCEPTION_LOG          =>  'Exception in save_payment_method: ' || SQLERRM
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE   
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                            );  
      X_RETURN_STATUS := 'E';   
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts'    || SQLERRM;  
END save_payment_method;

  -- PROCEDURE create_cust_profile
  --
  -- DESCRIPTION
  --     Create customer profile.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_cp_obj             Customer profile object.
  --     p_ca_id              Customer account Id.
  --     p_casu_id            Customer account site use Id.
  --   OUT:
  --     x_cp_id              Customer profile Id.
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
  PROCEDURE create_cust_profile(
    p_cp_obj                  IN OUT NOCOPY HZ_CUSTOMER_PROFILE_BO,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    x_cp_id                   OUT NOCOPY    NUMBER,
    p_acct_osr                IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_cust_type               IN            VARCHAR2,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  ) IS
    l_return_status           VARCHAR2(1) := x_return_status;
    l_msg_count               number;
    l_msg_data                varchar2(2000) := x_errbuf;    
    l_cp_rec                  HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;

    lc_ab_flag                VARCHAR2(1);
    lc_customer_status        VARCHAR2(1) := 'A';
    lc_customer_type          HZ_CUST_ACCOUNTS.ATTRIBUTE18%TYPE := p_cust_type;
    lc_prof_class_name        HZ_CUST_PROFILE_CLASSES.NAME%TYPE := p_cust_prof_cls_name; 
    
    l_prof_class_modify      VARCHAR2(1);  
    l_prof_class_id          HZ_CUST_PROFILE_CLASSES.PROFILE_CLASS_ID%TYPE;  
    l_prof_class_name        HZ_CUST_PROFILE_CLASSES.NAME%TYPE;      
    l_retain_collect_cd      VARCHAR2(1); 
    l_collector_code         HZ_CUSTOMER_PROFILES.COLLECTOR_ID%TYPE; 
    l_collector_name         AR_COLLECTORS.NAME%TYPE;


BEGIN
    -- Standard start of API savepoint
    SAVEPOINT create_cp_pvt;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.create_cust_profile(+)');

    -- Create cust profile
    -- ***Incorporate CR 655 logic (Customer Credit authoization from AOPS) in assign_cust_profile_rec

    assign_cust_profile_rec(
      p_cust_profile_obj            => p_cp_obj,
      p_cust_acct_id                => p_ca_id,
      p_site_use_id                 => p_casu_id,
      px_cust_profile_rec           => l_cp_rec
    );


    XX_OD_CUST_PROF_CLASS_MAP_PKG.derive_prof_class_dtls (
                p_customer_osr          => p_acct_osr,
                p_reactivated_flag      => l_cp_rec.attribute4,
                p_ab_flag               => l_cp_rec.attribute3,
                p_status                => lc_customer_status, --Since this is create profile, status 'A' 
                p_customer_type         => lc_customer_type,
                p_cust_template         => lc_prof_class_name,
                x_prof_class_modify     => l_prof_class_modify,
                x_prof_class_name       => l_prof_class_name  ,
                x_prof_class_id         => l_prof_class_id    ,
                x_retain_collect_cd     => l_retain_collect_cd,
                x_collector_code        => l_collector_code   ,
                x_collector_name        => l_collector_name   ,
                x_errbuf                => X_ERRBUF           ,
                x_return_status         => l_return_status    
              );        

    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_customer_osr      :' || p_acct_osr);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_reactivated_flag  :' || l_cp_rec.attribute4);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_ab_flag           :' || l_cp_rec.attribute3);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_status            :' || l_cp_rec.status);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_customer_type     :' || lc_customer_type   );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_cust_template     :' || lc_prof_class_name );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_prof_class_modify :' || l_prof_class_modify);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_prof_class_name   :' || l_prof_class_name  );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_prof_class_id     :' || l_prof_class_id    );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_retain_collect_cd :' || l_retain_collect_cd);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_collector_code    :' || l_collector_code   );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_collector_name    :' || l_collector_name   );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_errbuf            :' || X_ERRBUF           );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_return_status     :' || l_return_status    );
                                                              
    IF l_return_status = 'S' THEN

      l_cp_rec.profile_class_id := l_prof_class_id;
          l_cp_rec.collector_id := l_collector_code;
          
      HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile (
        p_customer_profile_rec        => l_cp_rec,
        p_create_profile_amt          => FND_API.G_FALSE,
        x_cust_account_profile_id     => x_cp_id,
        x_return_status               => x_return_status,
        x_msg_count                   => x_msg_count,
        x_msg_data                    => x_msg_data
      );
        
      IF l_return_status = 'S' THEN
	  
          do_copy_cust_profiles (
            p_bo_process_id            => p_bo_process_id,
            p_bpel_process_id          => p_bpel_process_id,
            p_cust_account_profile_id  => x_cp_id,
            p_cust_account_id          => p_ca_id,      
            x_return_status            => x_return_status,
            x_msg_count                => x_msg_count,
            x_msg_data                 => x_msg_data       
          );
    
        XX_CDH_CUST_UTIL_BO_PUB.save_gt(
                    P_BO_PROCESS_ID          =>  p_bo_process_id,
                    P_BO_ENTITY_NAME         =>  'HZ_CUSTOMER_PROFILES',
                    P_BO_TABLE_ID            =>  x_cp_id,
                    P_ORIG_SYSTEM            =>  null,
                    P_ORIG_SYSTEM_REFERENCE  =>  null
                );
    
      ELSE
        --call exception process
        l_msg_data := null;
        FOR i IN 1 .. l_msg_count
        LOOP
           l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
        END LOOP;
        XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                  P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                                , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                                , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'           
                                                , P_LOG_DATE               =>  SYSDATE             
                                                , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                                , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                                , P_PROCEDURE_NAME         =>  'create_cust_profile'              
                                                , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'      
                                                , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'   
                                                , P_BO_COLUMN_VALUE        =>  x_cp_id       
                                                , P_ORIG_SYSTEM            =>  null
                                                , P_ORIG_SYSTEM_REFERENCE  =>  null
                                                , P_EXCEPTION_LOG          =>  l_msg_data        
                                                , P_ORACLE_ERROR_CODE      =>  null    
                                                , P_ORACLE_ERROR_MSG       =>  null 
                                              );
        RAISE FND_API.G_EXC_ERROR;
          END IF;
        ELSE
        XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                  P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                                , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                                , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'           
                                                , P_LOG_DATE               =>  SYSDATE             
                                                , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                                , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                                , P_PROCEDURE_NAME         =>  'create_cust_profile'              
                                                , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'      
                                                , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'   
                                                , P_BO_COLUMN_VALUE        =>  x_cp_id       
                                                , P_ORIG_SYSTEM            =>  null
                                                , P_ORIG_SYSTEM_REFERENCE  =>  null
                                                , P_EXCEPTION_LOG          =>  l_msg_data        
                                                , P_ORACLE_ERROR_CODE      =>  null    
                                                , P_ORACLE_ERROR_MSG       =>  null 
                                              );
        X_RETURN_STATUS := 'E';   
        X_ERRBUF        := 'Error in deriving the XX_OD_CUST_PROF_CLASS_MAP_PKG.derive_prof_class_dtls'   || SQLERRM;    
    END IF;

    -- assign profile_id
    p_cp_obj.cust_acct_profile_id := x_cp_id;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.create_cust_profile(-)');   

    EXCEPTION
      WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'update_cust_profile'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'       
                                              , P_BO_COLUMN_VALUE        =>  x_cp_id       
                                              , P_ORIG_SYSTEM            =>  null -- check what should we pass
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null -- check what should we pass
                                              , P_EXCEPTION_LOG          =>  'Exception in create_cust_profile '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      X_RETURN_STATUS := 'E';   
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.create_cust_profile'   || SQLERRM;    
END create_cust_profile;

  -- PROCEDURE update_cust_profile
  --
  -- DESCRIPTION
  --     Update customer profile.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_cp_obj             Customer profile object.
  --     p_ca_id              Customer account Id.
  --     p_casu_id            Customer account site use Id.
  --   OUT:
  --     x_cp_id              Customer profile Id.
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

  PROCEDURE update_cust_profile(
    p_cp_obj                  IN OUT NOCOPY HZ_CUSTOMER_PROFILE_BO,
    p_ca_id                   IN            NUMBER,
    p_casu_id                 IN            NUMBER,
    x_cp_id                   OUT NOCOPY    NUMBER,
    p_acct_osr                IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_cust_type               IN            VARCHAR2,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER,
    x_return_status           OUT NOCOPY    VARCHAR2,
    x_msg_count               OUT NOCOPY    NUMBER,
    x_msg_data                OUT NOCOPY    VARCHAR2,
    x_errbuf                  OUT NOCOPY    VARCHAR2    
  ) IS
    l_return_status           VARCHAR2(1) := x_return_status;
    l_msg_count              number;
    l_msg_data               varchar2(2000) := x_errbuf;    
    l_cp_rec                  HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
    l_cp_ovn                  NUMBER;
    l_ca_id                   NUMBER;
    l_casu_id                 NUMBER;

    lc_ab_flag                VARCHAR2(1);
    lc_customer_status        VARCHAR2(1) := 'A';
    lc_customer_type          HZ_CUST_ACCOUNTS.ATTRIBUTE18%TYPE := p_cust_type;
    lc_prof_class_name        HZ_CUST_PROFILE_CLASSES.NAME%TYPE := p_cust_prof_cls_name; 
    
    l_prof_class_modify      VARCHAR2(1);  
    l_prof_class_id       HZ_CUST_PROFILE_CLASSES.PROFILE_CLASS_ID%TYPE;  
    l_prof_class_name        HZ_CUST_PROFILE_CLASSES.NAME%TYPE;   
    l_retain_collect_cd      VARCHAR2(1); 
    l_collector_code           HZ_CUSTOMER_PROFILES.COLLECTOR_ID%TYPE; 
    l_collector_name         AR_COLLECTORS.NAME%TYPE;

    CURSOR get_ovn(l_ca_id NUMBER, l_casu_id NUMBER) IS
    SELECT cp.cust_account_profile_id, cp.object_version_number
    FROM HZ_CUSTOMER_PROFILES cp
    WHERE cp.cust_account_id = l_ca_id
    AND nvl(cp.site_use_id, -99) = nvl(l_casu_id, -99);

    CURSOR get_ovn_by_cpid(l_cp_id NUMBER) IS
    SELECT cp.cust_account_profile_id, cp.object_version_number, cp.cust_account_id, cp.site_use_id
    FROM HZ_CUSTOMER_PROFILES cp
    WHERE cp.cust_account_profile_id = l_cp_id;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_cp_pvt;

    -- initialize API return status to success.
    x_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.update_cust_profile(+)');

    -- check if user pass in cust profile id but with different cust account id
    -- and/or site use id
    IF(p_cp_obj.cust_acct_profile_id IS NOT NULL) THEN
      OPEN get_ovn_by_cpid(p_cp_obj.cust_acct_profile_id);
      FETCH get_ovn_by_cpid INTO x_cp_id, l_cp_ovn, l_ca_id, l_casu_id;
      CLOSE get_ovn_by_cpid;
      IF(nvl(l_ca_id, -99) <> nvl(p_ca_id, -99)) THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'cust_account_id');
        FND_MSG_PUB.ADD();
        RAISE fnd_api.g_exc_error;
      END IF;
      IF(nvl(l_casu_id, -99) <> nvl(p_casu_id, -99)) THEN
        FND_MESSAGE.SET_NAME( 'AR', 'HZ_API_NONUPDATEABLE_COLUMN' );
        FND_MESSAGE.SET_TOKEN( 'COLUMN', 'site_use_id');
        FND_MSG_PUB.ADD();
        RAISE fnd_api.g_exc_error;
      END IF;
    ELSE
      OPEN get_ovn(p_ca_id, p_casu_id);
      FETCH get_ovn INTO x_cp_id, l_cp_ovn;
          p_cp_obj.cust_acct_profile_id := x_cp_id;
      CLOSE get_ovn;
    END IF;

    -- Create cust profile
    -- ***Incorporate CR 655 logic (Customer Credit authoization from AOPS) in assign_cust_profile_rec

    assign_cust_profile_rec(
      p_cust_profile_obj            => p_cp_obj,
      p_cust_acct_id                => p_ca_id,
      p_site_use_id                 => p_casu_id,
      px_cust_profile_rec           => l_cp_rec
    );

    l_cp_rec.cust_account_profile_id := x_cp_id;
    l_cp_rec.created_by_module := 'BO_API';
    XX_OD_CUST_PROF_CLASS_MAP_PKG.derive_prof_class_dtls (
                p_customer_osr          => p_acct_osr,
                p_reactivated_flag      => l_cp_rec.attribute4,
                p_ab_flag               => l_cp_rec.attribute3,
                p_status                => 'A', --Since this is create profile, status 'A' 
                p_customer_type         => lc_customer_type,
                p_cust_template         => lc_prof_class_name,
                x_prof_class_modify     => l_prof_class_modify,
                x_prof_class_name       => l_prof_class_name  ,
                x_prof_class_id         => l_prof_class_id    ,
                x_retain_collect_cd     => l_retain_collect_cd,
                x_collector_code        => l_collector_code   ,
                x_collector_name        => l_collector_name   ,
                x_errbuf                => X_ERRBUF           ,
                x_return_status         => l_return_status    
              );        

    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_customer_osr      :' || p_acct_osr);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_reactivated_flag  :' || l_cp_rec.attribute4);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_ab_flag           :' || l_cp_rec.attribute3);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_status            :' || 'A');
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_customer_type     :' || lc_customer_type   );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'p_cust_template     :' || lc_prof_class_name );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_prof_class_modify :' || l_prof_class_modify);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_prof_class_name   :' || l_prof_class_name  );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_prof_class_id     :' || l_prof_class_id    );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_retain_collect_cd :' || l_retain_collect_cd);
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_collector_code    :' || l_collector_code   );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_collector_name    :' || l_collector_name   );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_errbuf            :' || X_ERRBUF           );
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, 'x_return_status     :' || l_return_status    );
                                                              
    IF l_return_status = 'S' THEN

      l_cp_rec.profile_class_id := l_prof_class_id;
          IF l_retain_collect_cd = 'Y' THEN
            l_cp_rec.collector_id := l_collector_code;
          END IF;

      IF l_prof_class_modify = 'Y' THEN
        HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile (
          p_customer_profile_rec        => l_cp_rec,
          p_object_version_number       => l_cp_ovn,
          x_return_status               => x_return_status,
          x_msg_count                   => x_msg_count,
          x_msg_data                    => x_msg_data
        );

        IF l_return_status = 'S' THEN
          do_copy_cust_profiles (
            p_bo_process_id            => p_bo_process_id,
            p_bpel_process_id          => p_bpel_process_id,
            p_cust_account_profile_id  => x_cp_id,
            p_cust_account_id          => p_ca_id,      
            x_return_status            => x_return_status,
            x_msg_count                => x_msg_count,
            x_msg_data                 => x_msg_data       
          );
        
          XX_CDH_CUST_UTIL_BO_PUB.save_gt(
                      P_BO_PROCESS_ID          =>  p_bo_process_id,
                      P_BO_ENTITY_NAME         =>  'HZ_CUSTOMER_PROFILES',
                      P_BO_TABLE_ID            =>  x_cp_id,
                      P_ORIG_SYSTEM            =>  null,
                      P_ORIG_SYSTEM_REFERENCE  =>  null
                  );
        
        ELSE
          --call exception process
          l_msg_data := null;
          FOR i IN 1 .. l_msg_count
          LOOP
             l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
          END LOOP;
          XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                    P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                                  , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                                  , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'           
                                                  , P_LOG_DATE               =>  SYSDATE             
                                                  , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                                  , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                                  , P_PROCEDURE_NAME         =>  'update_cust_profile'              
                                                  , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'      
                                                  , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'   
                                                  , P_BO_COLUMN_VALUE        =>  x_cp_id       
                                                  , P_ORIG_SYSTEM            =>  null
                                                  , P_ORIG_SYSTEM_REFERENCE  =>  null
                                                  , P_EXCEPTION_LOG          =>  l_msg_data        
                                                  , P_ORACLE_ERROR_CODE      =>  null    
                                                  , P_ORACLE_ERROR_MSG       =>  null 
                                                );
          RAISE FND_API.G_EXC_ERROR;
            END IF;--end of API return status
      END IF;--end of l_prof_class_modify
        ELSE
        XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                  P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                                , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                                , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'           
                                                , P_LOG_DATE               =>  SYSDATE             
                                                , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                                , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                                , P_PROCEDURE_NAME         =>  'update_cust_profile'              
                                                , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'      
                                                , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'   
                                                , P_BO_COLUMN_VALUE        =>  x_cp_id       
                                                , P_ORIG_SYSTEM            =>  null
                                                , P_ORIG_SYSTEM_REFERENCE  =>  null
                                                , P_EXCEPTION_LOG          =>  l_msg_data        
                                                , P_ORACLE_ERROR_CODE      =>  null    
                                                , P_ORACLE_ERROR_MSG       =>  null 
                                              );
        X_RETURN_STATUS := 'E';   
        X_ERRBUF        := 'Error in deriving the XX_OD_CUST_PROF_CLASS_MAP_PKG.derive_prof_class_dtls'   || SQLERRM;    
    END IF;--end of derive_profile_details l_return_status
    
    -- assign profile_id
    p_cp_obj.cust_acct_profile_id := x_cp_id;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.update_cust_profile(-)');
    
EXCEPTION
  WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUSTOMER_PROFILE_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'update_cust_profile'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUSTOMER_PROFILES'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_PROFILE_ID'       
                                              , P_BO_COLUMN_VALUE        =>  x_cp_id       
                                              , P_ORIG_SYSTEM            =>  null
                                              , P_ORIG_SYSTEM_REFERENCE  =>  null
                                              , P_EXCEPTION_LOG          =>  'Exception in update_cust_profile '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      X_RETURN_STATUS := 'E';   
      --X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.update_cust_profile'   || SQLERRM;                                          
END update_cust_profile;

procedure do_create_cust_account (
    p_cust_acct_obj       IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,
    x_cust_account_id     OUT  NOCOPY   NUMBER,
    x_party_id            IN OUT NOCOPY NUMBER
  )
is

  l_init_msg_list          boolean := TRUE;
  l_created_by_module      varchar2(30) := 'BO_API';
  l_debug_prefix           varchar2(30) := '';
  l_validate_bo_flag       boolean := TRUE;
  
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);

  l_cust_account_id        number(15) :=0;
  l_cust_account_os        varchar2(30);
  l_cust_account_osr       varchar2(255);
  l_party_id               number := x_party_id;
  l_cust_acct_rec          HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
  l_organization_rec       HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
  l_profile_rec            HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
  l_party_number           VARCHAR2(30);
  l_profile_id             NUMBER;
  
  l_cust_acct_profile_id    NUMBER;
  l_account_number          VARCHAR2(30);
  l_valid_obj               BOOLEAN;
  l_bus_object              HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
  l_cbm                     VARCHAR2(30);

  CURSOR get_cust_acct_profile_id(p_cust_acct_id NUMBER) IS
  SELECT cust_account_profile_id
  FROM HZ_CUSTOMER_PROFILES
  WHERE cust_account_id = p_cust_acct_id;  
  
begin
    -- Standard start of API savepoint
    SAVEPOINT do_create_cust_account;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_created_by_module;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_cust_account(+)');
    
    ---------------------------------------
    -- Assign Cust Account Record
    ---------------------------------------
    assign_cust_acct_rec(
      p_cust_acct_obj          => p_cust_acct_obj,
      p_cust_acct_id           => l_cust_account_id,
      p_cust_acct_os           => l_cust_account_os,
      p_cust_acct_osr          => l_cust_account_osr,
      px_cust_acct_rec         => l_cust_acct_rec
    );

    l_organization_rec.party_rec.party_id := x_party_id;
    HZ_CUST_ACCOUNT_V2PUB.create_cust_account (
      p_cust_account_rec        => l_cust_acct_rec,
      p_organization_rec        => l_organization_rec,
      p_customer_profile_rec    => NULL,                  --Create Account without profile first
      p_create_profile_amt      => FND_API.G_FALSE,
      x_cust_account_id         => l_cust_account_id,
      x_account_number          => l_account_number,
      x_party_id                => l_party_id,
      x_party_number            => l_party_number,
      x_profile_id              => l_profile_id,
      x_return_status           => l_return_status,
      x_msg_count               => l_msg_count,
      x_msg_data                => l_msg_data
    );      
  
    IF l_return_status = 'S' THEN      
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PUB.SAVE_GT(
                      P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID,
                      P_BO_ENTITY_NAME         =>  'HZ_CUST_ACCOUNTS',
                      P_BO_TABLE_ID            =>  l_cust_account_id,
                      P_ORIG_SYSTEM            =>  p_cust_acct_obj.ORIG_SYSTEM,
                      P_ORIG_SYSTEM_REFERENCE  =>  p_cust_acct_obj.ORIG_SYSTEM_REFERENCE
                );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id      
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'       
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id            
                                              , P_PACKAGE_NAME           =>  'HZ_CUST_ACCOUNT_V2PUB'         
                                              , P_PROCEDURE_NAME         =>  'do_create_cust_account'       
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id      
                                              , P_ORIG_SYSTEM            =>  p_cust_acct_obj.ORIG_SYSTEM
                                              , P_ORIG_SYSTEM_REFERENCE  =>  p_cust_acct_obj.ORIG_SYSTEM_REFERENCE
                                              , P_EXCEPTION_LOG          =>  l_msg_data        
                                              , P_ORACLE_ERROR_CODE      =>  null    
                                              , P_ORACLE_ERROR_MSG       =>  null 
                                            );
      RAISE FND_API.G_EXC_ERROR;
    END IF;    

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_cust_account(-)');
    
exception
  when others then
    ROLLBACK to do_create_cust_account;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id      
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'       
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id            
                                              , P_PACKAGE_NAME           =>  'HZ_CUST_ACCOUNT_V2PUB'         
                                              , P_PROCEDURE_NAME         =>  'do_create_cust_account'       
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id      
                                              , P_ORIG_SYSTEM            =>  p_cust_acct_obj.ORIG_SYSTEM
                                              , P_ORIG_SYSTEM_REFERENCE  =>  p_cust_acct_obj.ORIG_SYSTEM_REFERENCE
                                              , P_EXCEPTION_LOG          =>  'Exception in do_create_cust_account '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );    
end do_create_cust_account;  

procedure do_update_cust_account (
    p_cust_acct_obj       IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id       IN            NUMBER,
    p_bpel_process_id     IN            NUMBER,
    x_cust_account_id     OUT  NOCOPY   NUMBER,
    x_party_id            IN OUT NOCOPY NUMBER
)
is
  l_init_msg_list          boolean := TRUE;
  l_created_by_module      varchar2(30) := 'BO_API';
  l_debug_prefix           varchar2(30) := '';
  l_validate_bo_flag       boolean := TRUE;
  
  l_return_status          varchar2(1);
  l_msg_count              number;
  l_msg_data               varchar2(2000);

  l_cust_account_id        number(15) :=0;
  l_cust_account_os        varchar2(30);
  l_cust_account_osr       varchar2(255);
  l_party_id               number := x_party_id;
  l_cust_acct_rec          HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
  l_organization_rec       HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
  l_profile_rec            HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;
  l_party_number           VARCHAR2(30);
  l_profile_id             NUMBER;
  
  l_cust_acct_profile_id    NUMBER;
  l_account_number          VARCHAR2(30);
  l_valid_obj               BOOLEAN;
  l_bus_object              HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
  l_cbm                     VARCHAR2(30);

  CURSOR get_cust_acct_profile_id(p_cust_acct_id NUMBER) IS
  SELECT cust_account_profile_id
  FROM HZ_CUSTOMER_PROFILES
  WHERE cust_account_id = p_cust_acct_id;  

begin
    -- Standard start of API savepoint
    SAVEPOINT do_update_cust_account;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_created_by_module;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_cust_account(+)');
    
    ---------------------------------------
    -- Assign Cust Account Record
    ---------------------------------------
    assign_cust_acct_rec(
      p_cust_acct_obj          => p_cust_acct_obj,
      p_cust_acct_id           => l_cust_account_id,
      p_cust_acct_os           => l_cust_account_os,
      p_cust_acct_osr          => l_cust_account_osr,
      px_cust_acct_rec         => l_cust_acct_rec
    );
	
	--Call Update Cust Account
	
    IF l_return_status = 'S' THEN      
      --save l_organization_id into GT table
      XX_CDH_CUST_UTIL_BO_PUB.SAVE_GT(
                      P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID,
                      P_BO_ENTITY_NAME         =>  'HZ_CUST_ACCOUNTS',
                      P_BO_TABLE_ID            =>  l_cust_account_id,
                      P_ORIG_SYSTEM            =>  p_cust_acct_obj.ORIG_SYSTEM,
                      P_ORIG_SYSTEM_REFERENCE  =>  p_cust_acct_obj.ORIG_SYSTEM_REFERENCE
                );
 
    ELSE
      --call exception process
      l_msg_data := null;
      FOR i IN 1 .. l_msg_count
      LOOP
         l_msg_data := l_msg_data || fnd_msg_pub.get (p_encoded      => fnd_api.g_false);
      END LOOP;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id      
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'       
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id            
                                              , P_PACKAGE_NAME           =>  'HZ_CUST_ACCOUNT_V2PUB'         
                                              , P_PROCEDURE_NAME         =>  'do_update_cust_account'       
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id      
                                              , P_ORIG_SYSTEM            =>  p_cust_acct_obj.ORIG_SYSTEM
                                              , P_ORIG_SYSTEM_REFERENCE  =>  p_cust_acct_obj.ORIG_SYSTEM_REFERENCE
                                              , P_EXCEPTION_LOG          =>  l_msg_data        
                                              , P_ORACLE_ERROR_CODE      =>  null    
                                              , P_ORACLE_ERROR_MSG       =>  null 
                                            );
      RAISE FND_API.G_EXC_ERROR;
    END IF;    

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_cust_account(-)');
    
exception
  when others then
    ROLLBACK to do_update_cust_account;
    --call exception process
    XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id      
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'       
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id            
                                              , P_PACKAGE_NAME           =>  'HZ_CUST_ACCOUNT_V2PUB'         
                                              , P_PROCEDURE_NAME         =>  'do_update_cust_account'       
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id      
                                              , P_ORIG_SYSTEM            =>  p_cust_acct_obj.ORIG_SYSTEM
                                              , P_ORIG_SYSTEM_REFERENCE  =>  p_cust_acct_obj.ORIG_SYSTEM_REFERENCE
                                              , P_EXCEPTION_LOG          =>  'Exception in do_update_cust_account '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );    
end do_update_cust_account;
  -- PROCEDURE do_create_contr_cust_acct_bo
  --
  -- DESCRIPTION
  --     Create customer account business object for CONTRACT type customer.
    
  PROCEDURE do_create_contr_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
	p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2
  ) IS
  
    l_debug_prefix            VARCHAR2(30) := '';
    l_cust_acct_rec           HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    l_person_rec              HZ_PARTY_V2PUB.PERSON_REC_TYPE;
    l_organization_rec        HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    l_profile_rec             HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;

    l_party_id                NUMBER;
    l_party_number            VARCHAR2(30);
    l_created_by_module       VARCHAR2(30) := p_created_by_module;
    l_profile_id              NUMBER;
    l_cust_acct_profile_id    NUMBER;
    l_cust_account_id            NUMBER;
    l_account_number          VARCHAR2(30);
    l_valid_obj               BOOLEAN;
    l_bus_object              HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
    l_cbm                     VARCHAR2(30);
    
    l_return_status          varchar2(1);
    l_msg_count              number;
    l_msg_data               varchar2(2000);
        x_errbuf                 varchar2(2000);
    
    l_parent_id         NUMBER         := px_parent_id;        
    l_parent_os         VARCHAR2(30)   := px_parent_os;       
    l_parent_osr        VARCHAR2(255)  := px_parent_osr;      
    l_parent_obj_type   VARCHAR2(60)   := px_parent_obj_type;     
    
    --customer profile id out
    x_cp_id             number;
  
    CURSOR get_cust_acct_profile_id(p_cust_acct_id NUMBER) IS
    SELECT cust_account_profile_id
    FROM HZ_CUSTOMER_PROFILES
    WHERE cust_account_id = p_cust_acct_id;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_contr_cust_acct_bo;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;
        
    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_created_by_module;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_contr_cust_acct_bo(+)');

    x_cust_acct_id := p_cust_acct_obj.cust_acct_id;
    x_cust_acct_os := p_cust_acct_obj.orig_system;
    x_cust_acct_osr := p_cust_acct_obj.orig_system_reference;

    -- check if pass in cust_acct_id and os+osr
    hz_registry_validate_bo_pvt.validate_ssm_id(
      px_id              => x_cust_acct_id,
      px_os              => x_cust_acct_os,
      px_osr             => x_cust_acct_osr,
      p_obj_type         => 'HZ_CUST_ACCOUNTS',
      p_create_or_update => 'C',
      x_return_status    => l_return_status,
      x_msg_count        => l_msg_count,
      x_msg_data         => l_msg_data);

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- set party_id to party record
    -- profile amount will be created after creating cust account
    -- therefore set p_create_profile_amt to FND_API.G_FALSE
    IF(px_parent_obj_type = 'ORG') THEN
      l_organization_rec.party_rec.party_id := px_parent_id;
      do_create_cust_account (
        p_cust_acct_obj       =>  p_cust_acct_obj,
        p_bo_process_id       =>  p_bo_process_id,
        p_bpel_process_id     =>  p_bpel_process_id,
        x_cust_account_id     =>  l_cust_account_id,
        x_party_id            =>  px_parent_id
      );
    ELSE
      --We are not creating any ACCOUNT record for PERSON type party for CONTRACT customer
      --Evaluate whether we get person type customers
      l_person_rec.party_rec.party_id := px_parent_id;
      HZ_CUST_ACCOUNT_V2PUB.create_cust_account (
        p_cust_account_rec        => l_cust_acct_rec,
        p_person_rec              => l_person_rec,
        p_customer_profile_rec    => null,
        p_create_profile_amt      => FND_API.G_FALSE,
        x_cust_account_id         => x_cust_acct_id,
        x_account_number          => l_account_number,
        x_party_id                => l_party_id,
        x_party_number            => l_party_number,
        x_profile_id              => l_profile_id,
        x_return_status           => l_return_status,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data
      );
    END IF;

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -------------------------------------
    -- Create cust acct relate
    -------------------------------------
    IF((p_cust_acct_obj.acct_relate_objs IS NOT NULL) AND
       (p_cust_acct_obj.acct_relate_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.create_cust_acct_relates(
        p_car_objs                => p_cust_acct_obj.acct_relate_objs,
        p_ca_id                   => x_cust_acct_id,
        x_return_status           => l_return_status,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    l_cbm := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

    -------------------------------------
    -- Call cust account contact
    -------------------------------------
    -- Parent of cust account contact is cust account site
    -- so pass x_cust_acct_id, x_cust_acct_os and x_cust_acct_osr
    IF((p_cust_acct_obj.cust_acct_contact_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_contact_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_CONTACT_BO_PVT.save_cust_acct_contacts(
        p_cac_objs           => p_cust_acct_obj.cust_acct_contact_objs,
        p_create_update_flag => 'C',
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_id          => x_cust_acct_id,
        p_parent_os          => x_cust_acct_os,
        p_parent_osr         => x_cust_acct_osr,
        p_parent_obj_type    => 'CUST_ACCT'
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    -------------------------------------
    -- Call cust account site
    -------------------------------------
    -- create cust account site uses will include cust acct site use plus site use profile
    -- need to put customer account id and customer account site id
    IF((p_cust_acct_obj.cust_acct_site_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_site_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_SITE_BO_PVT.save_cust_acct_sites(
        p_cas_objs           => p_cust_acct_obj.cust_acct_site_objs,
        p_create_update_flag => 'C',
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_acct_id     => x_cust_acct_id,
        p_parent_acct_os     => x_cust_acct_os,
        p_parent_acct_osr    => x_cust_acct_osr
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;
    
    ------------------------------
    --call create customer profile
    ------------------------------
    --Customer Profile Object will be null coming from AOPS
    --So instatiate profile record and derive the profile
    --values from map package. After that create profile.
    --Also, in the create profile, call copy cust profile from acct to sites
    create_cust_profile(
      p_cp_obj                  => p_cust_acct_obj.cust_profile_obj,
      p_ca_id                   => x_cust_acct_id,
      p_casu_id                 => null,
      x_cp_id                   => x_cp_id,
      p_acct_osr                => p_cust_acct_obj.ORIG_SYSTEM_REFERENCE,
      p_cust_prof_cls_name      => p_cust_prof_cls_name,
      p_cust_type               => p_cust_acct_obj.customer_type,	  
      p_bo_process_id           => p_bo_process_id,
      p_bpel_process_id         => p_bpel_process_id,
      x_return_status           => l_return_status, 
      x_msg_count               => l_msg_count,     
      x_msg_data                => l_msg_data,      
      x_errbuf                  => x_errbuf           
    );
    
    -- assign cust_acct_id
    p_cust_acct_obj.cust_acct_id := x_cust_acct_id;
    p_cust_acct_obj.cust_profile_obj.cust_acct_profile_id := x_cp_id;
    -----------------------------
    -- Create cust profile amount
    -----------------------------
    IF((p_cust_acct_obj.cust_profile_obj.cust_profile_amt_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_profile_obj.cust_profile_amt_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.create_cust_profile_amts(
        p_cpa_objs                => p_cust_acct_obj.cust_profile_obj.cust_profile_amt_objs,
        p_cp_id                   => x_cp_id,
        p_ca_id                   => x_cust_acct_id,
        p_casu_id                 => NULL,
        x_return_status           => l_return_status,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;


    ------------------------
    -- Call bank account use
    ------------------------
    IF((p_cust_acct_obj.bank_acct_use_objs IS NOT NULL) AND
       (p_cust_acct_obj.bank_acct_use_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.save_bank_acct_uses(
        p_bank_acct_use_objs => p_cust_acct_obj.bank_acct_use_objs,
        p_party_id           => l_party_id,
        p_ca_id              => x_cust_acct_id,
        p_casu_id            => NULL,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    ------------------------
    -- Call payment method
    ------------------------
    IF(p_cust_acct_obj.payment_method_obj IS NOT NULL) THEN
      HZ_CUST_ACCT_BO_PVT.create_payment_method(
        p_payment_method_obj => p_cust_acct_obj.payment_method_obj,
        p_ca_id              => x_cust_acct_id,
        p_casu_id            => NULL,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    -- reset Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_contr_cust_acct_bo(-)');
    
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_create_contr_cust_acct_bo;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_create_contr_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_create_contr_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_contr_cust_acct_bo'         || SQLERRM;                                                                                  
    WHEN OTHERS THEN
      ROLLBACK TO do_create_contr_cust_acct_bo;        
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_create_contr_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_create_contr_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );  
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_contr_cust_acct_bo'         || SQLERRM;                                                                                  
  END do_create_contr_cust_acct_bo;
  
  -- PROCEDURE do_create_dir_cust_acct_bo
  --
  -- DESCRIPTION
  --     Create customer account business object for DIRECT type customer.
  PROCEDURE do_create_dir_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2
  ) IS
    l_debug_prefix            VARCHAR2(30) := '';
    l_cust_acct_rec           HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    l_person_rec              HZ_PARTY_V2PUB.PERSON_REC_TYPE;
    l_organization_rec        HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    l_profile_rec             HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;

    l_party_id                NUMBER;
    l_party_number            VARCHAR2(30);
    l_created_by_module       VARCHAR2(30) := p_created_by_module;
    l_profile_id              NUMBER;
    l_cust_acct_profile_id    NUMBER;
    l_cust_account_id            NUMBER;
    l_account_number          VARCHAR2(30);
    l_valid_obj               BOOLEAN;
    l_bus_object              HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
    l_cbm                     VARCHAR2(30);
    
    l_return_status          varchar2(1);
    l_msg_count              number;
    l_msg_data               varchar2(2000);
        x_errbuf                 varchar2(2000);
    
    l_parent_id         NUMBER         := px_parent_id;        
    l_parent_os         VARCHAR2(30)   := px_parent_os;       
    l_parent_osr        VARCHAR2(255)  := px_parent_osr;      
    l_parent_obj_type   VARCHAR2(60)   := px_parent_obj_type;     
    
    --customer profile id out
    x_cp_id             number;
  
    CURSOR get_cust_acct_profile_id(p_cust_acct_id NUMBER) IS
    SELECT cust_account_profile_id
    FROM HZ_CUSTOMER_PROFILES
    WHERE cust_account_id = p_cust_acct_id;
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_create_dir_cust_acct_bo;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;
        
    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_created_by_module;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_dir_cust_acct_bo(+)');

    x_cust_acct_id := p_cust_acct_obj.cust_acct_id;
    x_cust_acct_os := p_cust_acct_obj.orig_system;
    x_cust_acct_osr := p_cust_acct_obj.orig_system_reference;

    -- check if pass in cust_acct_id and os+osr
    hz_registry_validate_bo_pvt.validate_ssm_id(
      px_id              => x_cust_acct_id,
      px_os              => x_cust_acct_os,
      px_osr             => x_cust_acct_osr,
      p_obj_type         => 'HZ_CUST_ACCOUNTS',
      p_create_or_update => 'C',
      x_return_status    => l_return_status,
      x_msg_count        => l_msg_count,
      x_msg_data         => l_msg_data);

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- set party_id to party record
    -- profile amount will be created after creating cust account
    -- therefore set p_create_profile_amt to FND_API.G_FALSE
    IF(px_parent_obj_type = 'ORG') THEN
      l_organization_rec.party_rec.party_id := px_parent_id;
      do_create_cust_account (
        p_cust_acct_obj       =>  p_cust_acct_obj,
        p_bo_process_id       =>  p_bo_process_id,
        p_bpel_process_id     =>  p_bpel_process_id,
        x_cust_account_id     =>  l_cust_account_id,
        x_party_id            =>  px_parent_id
      );
    ELSE
      --We are not creating any ACCOUNT record for PERSON type party for CONTRACT customer
      --Evaluate whether we get person type customers
      l_person_rec.party_rec.party_id := px_parent_id;
      HZ_CUST_ACCOUNT_V2PUB.create_cust_account (
        p_cust_account_rec        => l_cust_acct_rec,
        p_person_rec              => l_person_rec,
        p_customer_profile_rec    => null,
        p_create_profile_amt      => FND_API.G_FALSE,
        x_cust_account_id         => x_cust_acct_id,
        x_account_number          => l_account_number,
        x_party_id                => l_party_id,
        x_party_number            => l_party_number,
        x_profile_id              => l_profile_id,
        x_return_status           => l_return_status,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data
      );
    END IF;

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -------------------------------------
    -- Create cust acct relate
    -------------------------------------
    IF((p_cust_acct_obj.acct_relate_objs IS NOT NULL) AND
       (p_cust_acct_obj.acct_relate_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.create_cust_acct_relates(
        p_car_objs                => p_cust_acct_obj.acct_relate_objs,
        p_ca_id                   => x_cust_acct_id,
        x_return_status           => l_return_status,
        x_msg_count               => l_msg_count,
        x_msg_data                => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    l_cbm := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

    -------------------------------------
    -- Call cust account contact
    -------------------------------------
    -- Parent of cust account contact is cust account site
    -- so pass x_cust_acct_id, x_cust_acct_os and x_cust_acct_osr
    IF((p_cust_acct_obj.cust_acct_contact_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_contact_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_CONTACT_BO_PVT.save_cust_acct_contacts(
        p_cac_objs           => p_cust_acct_obj.cust_acct_contact_objs,
        p_create_update_flag => 'C',
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_id          => x_cust_acct_id,
        p_parent_os          => x_cust_acct_os,
        p_parent_osr         => x_cust_acct_osr,
        p_parent_obj_type    => 'CUST_ACCT'
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    -------------------------------------
    -- Call cust account site
    -------------------------------------
    -- create cust account site uses will include cust acct site use plus site use profile
    -- need to put customer account id and customer account site id
    IF((p_cust_acct_obj.cust_acct_site_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_site_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_SITE_BO_PVT.save_cust_acct_sites(
        p_cas_objs           => p_cust_acct_obj.cust_acct_site_objs,
        p_create_update_flag => 'C',
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_acct_id     => x_cust_acct_id,
        p_parent_acct_os     => x_cust_acct_os,
        p_parent_acct_osr    => x_cust_acct_osr
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;
    
    ------------------------------
    --call create customer profile
    ------------------------------
    --Customer Profile Object will be null coming from AOPS
    --So instatiate profile record and assign CREDIT_CARD
    --customer profile or FOS profile by using the map package
    create_cust_profile(
      p_cp_obj                  => p_cust_acct_obj.cust_profile_obj,
      p_ca_id                   => x_cust_acct_id,
      p_casu_id                 => null,
      x_cp_id                   => x_cp_id,
      p_acct_osr                => p_cust_acct_obj.ORIG_SYSTEM_REFERENCE,
      p_cust_prof_cls_name      => p_cust_prof_cls_name,
      p_cust_type               => p_cust_acct_obj.customer_type,	  
      p_bo_process_id           => p_bo_process_id,
      p_bpel_process_id         => p_bpel_process_id,
      x_return_status           => l_return_status, 
      x_msg_count               => l_msg_count,     
      x_msg_data                => l_msg_data,      
      x_errbuf                  => x_errbuf                     
    );
    
    -- reset Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_dir_cust_acct_bo(-)');
    
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_create_dir_cust_acct_bo;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_create_dir_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_create_dir_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_dir_cust_acct_bo'         || SQLERRM;                                                                                  
    WHEN OTHERS THEN
      ROLLBACK TO do_create_dir_cust_acct_bo;        
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_create_dir_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_create_dir_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );  
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_create_dir_cust_acct_bo'         || SQLERRM;                                                                                  
  END do_create_dir_cust_acct_bo;


  -- PROCEDURE do_update_contr_cust_acct_bo
  --
  -- DESCRIPTION
  --     Update customer account business object for CONTRACT type customer.
    
  PROCEDURE do_update_contr_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
	p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2
  ) IS
  
    l_debug_prefix            VARCHAR2(30) := '';
    l_cust_acct_rec           HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    l_person_rec              HZ_PARTY_V2PUB.PERSON_REC_TYPE;
    l_organization_rec        HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    l_profile_rec             HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;

    l_party_id                NUMBER;
    l_party_number            VARCHAR2(30);
    l_created_by_module       VARCHAR2(30) := p_created_by_module;
    l_profile_id              NUMBER;
    l_cust_acct_profile_id    NUMBER;
    l_cust_account_id            NUMBER;
    l_account_number          VARCHAR2(30);
    l_valid_obj               BOOLEAN;
    l_bus_object              HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
    l_cbm                     VARCHAR2(30);
    l_ovn                      NUMBER;
    
    l_return_status          varchar2(1);
    l_msg_count              number;
    l_msg_data               varchar2(2000);
        x_errbuf                 varchar2(2000);
    
    l_parent_id         NUMBER         := px_parent_id;        
    l_parent_os         VARCHAR2(30)   := px_parent_os;       
    l_parent_osr        VARCHAR2(255)  := px_parent_osr;      
    l_parent_obj_type   VARCHAR2(60)   := px_parent_obj_type;     
    
    --customer profile id out
    x_cp_id             number;
  
    CURSOR get_cust_acct_profile_id(p_cust_acct_id NUMBER) IS
    SELECT cust_account_profile_id
    FROM HZ_CUSTOMER_PROFILES
    WHERE cust_account_id = p_cust_acct_id;
        
    CURSOR get_ovn(l_ca_id NUMBER) IS
    SELECT a.object_version_number, a.party_id
    FROM HZ_CUST_ACCOUNTS a
    WHERE a.cust_account_id = l_ca_id;        
        
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_update_contr_cust_acct_bo;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;
        
    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_created_by_module;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_contr_cust_acct_bo(+)');
        
    -------------------------------
    -- For Update cust accts
    -------------------------------
    x_cust_acct_id := p_cust_acct_obj.cust_acct_id;
    x_cust_acct_os := p_cust_acct_obj.orig_system;
    x_cust_acct_osr := p_cust_acct_obj.orig_system_reference;

    -- validate ssm of cust account site
    hz_registry_validate_bo_pvt.validate_ssm_id(
      px_id              => x_cust_acct_id,
      px_os              => x_cust_acct_os,
      px_osr             => x_cust_acct_osr,
      p_obj_type         => 'HZ_CUST_ACCOUNTS',
      p_create_or_update => 'U',
      x_return_status    => l_return_status,
      x_msg_count        => l_msg_count,
      x_msg_data         => l_msg_data);

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- get object version number of customer acct
    OPEN get_ovn(x_cust_acct_id);
    FETCH get_ovn INTO l_ovn, l_party_id;
    CLOSE get_ovn;

        assign_cust_acct_rec(
      p_cust_acct_obj          => p_cust_acct_obj,
      p_cust_acct_id           => x_cust_acct_id,
      p_cust_acct_os           => x_cust_acct_os,
      p_cust_acct_osr          => x_cust_acct_osr,
      p_create_or_update       => 'U',
      px_cust_acct_rec         => l_cust_acct_rec
    );
    HZ_CUST_ACCOUNT_V2PUB.update_cust_account(
      p_cust_account_rec            => l_cust_acct_rec,
      p_object_version_number       => l_ovn,
      x_return_status               => l_return_status,
      x_msg_count                   => l_msg_count,
      x_msg_data                    => l_msg_data
    );

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -----------------------------
    -- For Update account profile
    -----------------------------
    IF(p_cust_acct_obj.cust_profile_obj IS NOT NULL) THEN
      update_cust_profile(
        p_cp_obj                  => p_cust_acct_obj.cust_profile_obj,
        p_ca_id                   => x_cust_acct_id,
        p_casu_id                 => null,
        x_cp_id                   => x_cp_id,
        p_acct_osr                => p_cust_acct_obj.ORIG_SYSTEM_REFERENCE,
        p_cust_prof_cls_name      => p_cust_prof_cls_name,
        p_cust_type               => p_cust_acct_obj.customer_type,	  
        p_bo_process_id           => p_bo_process_id,
        p_bpel_process_id         => p_bpel_process_id,
        x_return_status           => l_return_status, 
        x_msg_count               => l_msg_count,     
        x_msg_data                => l_msg_data,      
        x_errbuf                  => x_errbuf                    
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- assign cust_acct_profile_id
      p_cust_acct_obj.cust_profile_obj.cust_acct_profile_id := l_cust_acct_profile_id;
      ---------------------------------
      -- For Update account profile amt
      ---------------------------------
      IF((p_cust_acct_obj.cust_profile_obj.cust_profile_amt_objs IS NOT NULL) AND
         (p_cust_acct_obj.cust_profile_obj.cust_profile_amt_objs.COUNT > 0)) THEN
        HZ_CUST_ACCT_BO_PVT.save_cust_profile_amts(
          p_cpa_objs                => p_cust_acct_obj.cust_profile_obj.cust_profile_amt_objs,
          p_cp_id                   => l_cust_acct_profile_id,
          p_ca_id                   => x_cust_acct_id,
          p_casu_id                 => NULL,
          x_return_status           => l_return_status,
          x_msg_count               => l_msg_count,
          x_msg_data                => l_msg_data
        );

        IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
          RAISE FND_API.G_EXC_ERROR;
        END IF;
      END IF;
    END IF;

    l_cbm := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

    -----------------------------------
    -- For cust account contact
    -----------------------------------
    IF((p_cust_acct_obj.cust_acct_contact_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_contact_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_CONTACT_BO_PVT.save_cust_acct_contacts(
        p_cac_objs            => p_cust_acct_obj.cust_acct_contact_objs,
        p_create_update_flag  => 'U',
        p_obj_source         => null,
        x_return_status       => l_return_status,
        x_msg_count           => l_msg_count,
        x_msg_data            => l_msg_data,
        p_parent_id           => x_cust_acct_id,
        p_parent_os           => x_cust_acct_os,
        p_parent_osr          => x_cust_acct_osr,
        p_parent_obj_type     => 'CUST_ACCT'
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    -------------------------------
    -- For Update account acct relate
    -------------------------------
    IF((p_cust_acct_obj.acct_relate_objs IS NOT NULL) AND
       (p_cust_acct_obj.acct_relate_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.save_cust_acct_relates(
        p_car_objs           => p_cust_acct_obj.acct_relate_objs,
        p_ca_id              => x_cust_acct_id,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    -------------------------------------
    -- Call cust account site
    -------------------------------------
    -- create cust account site uses will include cust acct site use plus site use profile
    -- need to put customer account id and customer account site id
    IF((p_cust_acct_obj.cust_acct_site_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_site_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_SITE_BO_PVT.save_cust_acct_sites(
        p_cas_objs           => p_cust_acct_obj.cust_acct_site_objs,
        p_create_update_flag => 'U',
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_acct_id     => x_cust_acct_id,
        p_parent_acct_os     => x_cust_acct_os,
        p_parent_acct_osr    => x_cust_acct_osr
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    ------------------------
    -- Call bank account use
    ------------------------
    IF((p_cust_acct_obj.bank_acct_use_objs IS NOT NULL) AND
       (p_cust_acct_obj.bank_acct_use_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.save_bank_acct_uses(
        p_bank_acct_use_objs => p_cust_acct_obj.bank_acct_use_objs,
        p_party_id           => l_party_id,
        p_ca_id              => x_cust_acct_id,
        p_casu_id            => NULL,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    ------------------------
    -- Call payment method
    ------------------------
    IF(p_cust_acct_obj.payment_method_obj IS NOT NULL) THEN
      HZ_CUST_ACCT_BO_PVT.save_payment_method(
        p_payment_method_obj => p_cust_acct_obj.payment_method_obj,
        p_ca_id              => x_cust_acct_id,
        p_casu_id            => NULL,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    -- reset Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_contr_cust_acct_bo(-)');
    
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_update_contr_cust_acct_bo;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_update_contr_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_update_contr_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_contr_cust_acct_bo'         || SQLERRM;                                                                                  
    WHEN OTHERS THEN
      ROLLBACK TO do_update_contr_cust_acct_bo;        
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_update_contr_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_update_contr_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );  
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_contr_cust_acct_bo'         || SQLERRM;                                                                                  
  END do_update_contr_cust_acct_bo;  

  -- PROCEDURE do_update_dir_cust_acct_bo
  --
  -- DESCRIPTION
  --     Update customer account business object for DIRECT type customer.
    
  PROCEDURE do_update_dir_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
	p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2
  ) IS
  
    l_debug_prefix            VARCHAR2(30) := '';
    l_cust_acct_rec           HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
    l_person_rec              HZ_PARTY_V2PUB.PERSON_REC_TYPE;
    l_organization_rec        HZ_PARTY_V2PUB.ORGANIZATION_REC_TYPE;
    l_profile_rec             HZ_CUSTOMER_PROFILE_V2PUB.CUSTOMER_PROFILE_REC_TYPE;

    l_party_id                NUMBER;
    l_party_number            VARCHAR2(30);
    l_created_by_module       VARCHAR2(30) := p_created_by_module;
    l_profile_id              NUMBER;
    l_cust_acct_profile_id    NUMBER;
    l_cust_account_id            NUMBER;
    l_account_number          VARCHAR2(30);
    l_valid_obj               BOOLEAN;
    l_bus_object              HZ_REGISTRY_VALIDATE_BO_PVT.COMPLETENESS_REC_TYPE;
    l_cbm                     VARCHAR2(30);
    l_ovn                      NUMBER;
    
    l_return_status          varchar2(1);
    l_msg_count              number;
    l_msg_data               varchar2(2000);
        x_errbuf                 varchar2(2000);
    
    l_parent_id         NUMBER         := px_parent_id;        
    l_parent_os         VARCHAR2(30)   := px_parent_os;       
    l_parent_osr        VARCHAR2(255)  := px_parent_osr;      
    l_parent_obj_type   VARCHAR2(60)   := px_parent_obj_type;     
    
    --customer profile id out
    x_cp_id             number;
  
    CURSOR get_cust_acct_profile_id(p_cust_acct_id NUMBER) IS
    SELECT cust_account_profile_id
    FROM HZ_CUSTOMER_PROFILES
    WHERE cust_account_id = p_cust_acct_id;
        
    CURSOR get_ovn(l_ca_id NUMBER) IS
    SELECT a.object_version_number, a.party_id
    FROM HZ_CUST_ACCOUNTS a
    WHERE a.cust_account_id = l_ca_id;        
        
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT do_update_dir_cust_acct_bo;

    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;
        
    -- initialize Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := 'BO_API';
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_created_by_module;
    
    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_dir_cust_acct_bo(+)');
        
    -------------------------------
    -- For Update cust accts
    -------------------------------
    x_cust_acct_id := p_cust_acct_obj.cust_acct_id;
    x_cust_acct_os := p_cust_acct_obj.orig_system;
    x_cust_acct_osr := p_cust_acct_obj.orig_system_reference;

    -- validate ssm of cust account site
    hz_registry_validate_bo_pvt.validate_ssm_id(
      px_id              => x_cust_acct_id,
      px_os              => x_cust_acct_os,
      px_osr             => x_cust_acct_osr,
      p_obj_type         => 'HZ_CUST_ACCOUNTS',
      p_create_or_update => 'U',
      x_return_status    => l_return_status,
      x_msg_count        => l_msg_count,
      x_msg_data         => l_msg_data);

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- get object version number of customer acct
    OPEN get_ovn(x_cust_acct_id);
    FETCH get_ovn INTO l_ovn, l_party_id;
    CLOSE get_ovn;

        assign_cust_acct_rec(
      p_cust_acct_obj          => p_cust_acct_obj,
      p_cust_acct_id           => x_cust_acct_id,
      p_cust_acct_os           => x_cust_acct_os,
      p_cust_acct_osr          => x_cust_acct_osr,
      p_create_or_update       => 'U',
      px_cust_acct_rec         => l_cust_acct_rec
    );
    HZ_CUST_ACCOUNT_V2PUB.update_cust_account(
      p_cust_account_rec            => l_cust_acct_rec,
      p_object_version_number       => l_ovn,
      x_return_status               => l_return_status,
      x_msg_count                   => l_msg_count,
      x_msg_data                    => l_msg_data
    );

    IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -----------------------------
    -- For Update account profile
    -----------------------------
    IF(p_cust_acct_obj.cust_profile_obj IS NOT NULL) THEN
      update_cust_profile(
        p_cp_obj                  => p_cust_acct_obj.cust_profile_obj,
        p_ca_id                   => x_cust_acct_id,
        p_casu_id                 => null,
        x_cp_id                   => x_cp_id,
        p_acct_osr                => p_cust_acct_obj.ORIG_SYSTEM_REFERENCE,
        p_cust_prof_cls_name      => p_cust_prof_cls_name,
        p_cust_type               => p_cust_acct_obj.customer_type,	  
        p_bo_process_id           => p_bo_process_id,
        p_bpel_process_id         => p_bpel_process_id,
        x_return_status           => l_return_status, 
        x_msg_count               => l_msg_count,     
        x_msg_data                => l_msg_data,      
        x_errbuf                  => x_errbuf                      
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;

      -- assign cust_acct_profile_id
      p_cust_acct_obj.cust_profile_obj.cust_acct_profile_id := l_cust_acct_profile_id;
    END IF;
    -----------------------------------
    -- For cust account contact
    -----------------------------------
    IF((p_cust_acct_obj.cust_acct_contact_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_contact_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_CONTACT_BO_PVT.save_cust_acct_contacts(
        p_cac_objs            => p_cust_acct_obj.cust_acct_contact_objs,
        p_create_update_flag  => 'U',
        p_obj_source         => null,
        x_return_status       => l_return_status,
        x_msg_count           => l_msg_count,
        x_msg_data            => l_msg_data,
        p_parent_id           => x_cust_acct_id,
        p_parent_os           => x_cust_acct_os,
        p_parent_osr          => x_cust_acct_osr,
        p_parent_obj_type     => 'CUST_ACCT'
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    -------------------------------
    -- For Update account acct relate
    -------------------------------
    IF((p_cust_acct_obj.acct_relate_objs IS NOT NULL) AND
       (p_cust_acct_obj.acct_relate_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_BO_PVT.save_cust_acct_relates(
        p_car_objs           => p_cust_acct_obj.acct_relate_objs,
        p_ca_id              => x_cust_acct_id,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    -------------------------------------
    -- Call cust account site
    -------------------------------------
    -- create cust account site uses will include cust acct site use plus site use profile
    -- need to put customer account id and customer account site id
    IF((p_cust_acct_obj.cust_acct_site_objs IS NOT NULL) AND
       (p_cust_acct_obj.cust_acct_site_objs.COUNT > 0)) THEN
      HZ_CUST_ACCT_SITE_BO_PVT.save_cust_acct_sites(
        p_cas_objs           => p_cust_acct_obj.cust_acct_site_objs,
        p_create_update_flag => 'U',
        p_obj_source         => null,
        x_return_status      => l_return_status,
        x_msg_count          => l_msg_count,
        x_msg_data           => l_msg_data,
        p_parent_acct_id     => x_cust_acct_id,
        p_parent_acct_os     => x_cust_acct_os,
        p_parent_acct_osr    => x_cust_acct_osr
      );

      IF l_return_status <> FND_API.G_RET_STS_SUCCESS THEN
        RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF;

    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;

    -- reset Global variable
    HZ_UTILITY_V2PUB.G_CALLING_API := NULL;
    HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := NULL;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_dir_cust_acct_bo(-)');
    
  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO do_update_dir_cust_acct_bo;
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_update_dir_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_update_dir_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_dir_cust_acct_bo'         || SQLERRM;                                                                                  
    WHEN OTHERS THEN
      ROLLBACK TO do_update_dir_cust_acct_bo;        
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_update_dir_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_cust_account_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_update_dir_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );  
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_update_dir_cust_acct_bo'         || SQLERRM;                                                                                  
  END do_update_dir_cust_acct_bo;  

  -- PROCEDURE do_save_contr_cust_acct_bo
  --
  -- DESCRIPTION
  --     Create or update CONTRACT customer account business object.
  PROCEDURE do_save_contr_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
	p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2,
    x_errbuf                  OUT    NOCOPY VARCHAR2
  ) IS
    l_return_status            VARCHAR2(30);
    l_msg_count                NUMBER;
    l_msg_data                 VARCHAR2(2000);
    l_create_update_flag       VARCHAR2(1);
    l_debug_prefix             VARCHAR2(30) := '';
  BEGIN
    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_contr_cust_acct_bo(+)');

    x_cust_acct_id := p_cust_acct_obj.cust_acct_id;
    x_cust_acct_os := p_cust_acct_obj.orig_system;
    x_cust_acct_osr := p_cust_acct_obj.orig_system_reference;

    -- check root business object to determine that it should be
    -- create or update, call HZ_REGISTRY_VALIDATE_BO_PVT
    l_create_update_flag := HZ_REGISTRY_VALIDATE_BO_PVT.check_bo_op(
                              p_entity_id      => x_cust_acct_id,
                              p_entity_os      => x_cust_acct_os,
                              p_entity_osr     => x_cust_acct_osr,
                              p_entity_type    => 'HZ_CUST_ACCOUNTS',
                              p_parent_id      => px_parent_id,
                              p_parent_obj_type => px_parent_obj_type
                            );

    IF(l_create_update_flag = 'E') THEN
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'CUST_ACCT');
      FND_MSG_PUB.ADD;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF(l_create_update_flag = 'C') THEN
      do_create_contr_cust_acct_bo(
        p_cust_acct_obj       => p_cust_acct_obj,
        p_bo_process_id       => p_bo_process_id,
        p_bpel_process_id     => p_bpel_process_id,
        p_created_by_module   => p_created_by_module,
        p_cust_prof_cls_name  => p_cust_prof_cls_name,
        x_cust_acct_id        => x_cust_acct_id,
        x_cust_acct_os        => x_cust_acct_os,
        x_cust_acct_osr       => x_cust_acct_osr,
        px_parent_id          => px_parent_id,
        px_parent_os          => px_parent_os,
        px_parent_osr         => px_parent_osr,
        px_parent_obj_type    => px_parent_obj_type
      );
    ELSIF(l_create_update_flag = 'U') THEN
      do_update_contr_cust_acct_bo(
        p_cust_acct_obj       => p_cust_acct_obj,
        p_bo_process_id       => p_bo_process_id,
        p_bpel_process_id     => p_bpel_process_id,
        p_cust_prof_cls_name  => p_cust_prof_cls_name,
        p_created_by_module   => p_created_by_module,
        x_cust_acct_id        => x_cust_acct_id,
        x_cust_acct_os        => x_cust_acct_os,
        x_cust_acct_osr       => x_cust_acct_osr,
        px_parent_id          => px_parent_id,
        px_parent_os          => px_parent_os,
        px_parent_osr         => px_parent_osr,
        px_parent_obj_type    => px_parent_obj_type
      );
    ELSE
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_contr_cust_acct_bo(-)');

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_save_contr_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  x_cust_acct_id       
                                              , P_ORIG_SYSTEM            =>  px_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  px_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_save_contr_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_contr_cust_acct_bo'         || SQLERRM;                                                                                  
    WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_save_contr_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  x_cust_acct_id       
                                              , P_ORIG_SYSTEM            =>  px_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  px_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_save_contr_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );  
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_contr_cust_acct_bo'         || SQLERRM;                                                                                  
  END do_save_contr_cust_acct_bo;
  
  -- PROCEDURE do_save_dir_cust_acct_bo
  --
  -- DESCRIPTION
  --     Create or update DIRECT customer account business object.
  PROCEDURE do_save_dir_cust_acct_bo(
    p_cust_acct_obj           IN OUT NOCOPY HZ_CUST_ACCT_BO,
    p_bo_process_id           IN            NUMBER, 
    p_bpel_process_id         IN            NUMBER, 
    p_created_by_module       IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    x_cust_acct_id            OUT NOCOPY    NUMBER,
    x_cust_acct_os            OUT NOCOPY    VARCHAR2,
    x_cust_acct_osr           OUT NOCOPY    VARCHAR2,
    px_parent_id              IN OUT NOCOPY NUMBER,
    px_parent_os              IN OUT NOCOPY VARCHAR2,
    px_parent_osr             IN OUT NOCOPY VARCHAR2,
    px_parent_obj_type        IN OUT NOCOPY VARCHAR2,
    x_errbuf                  OUT    NOCOPY VARCHAR2
  ) IS
    l_return_status            VARCHAR2(30);
    l_msg_count                NUMBER;
    l_msg_data                 VARCHAR2(2000);
    l_create_update_flag       VARCHAR2(1);
    l_debug_prefix             VARCHAR2(30) := '';
  BEGIN
    -- initialize API return status to success.
    l_return_status := FND_API.G_RET_STS_SUCCESS;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_dir_cust_acct_bo(+)');

    x_cust_acct_id := p_cust_acct_obj.cust_acct_id;
    x_cust_acct_os := p_cust_acct_obj.orig_system;
    x_cust_acct_osr := p_cust_acct_obj.orig_system_reference;

    -- check root business object to determine that it should be
    -- create or update, call HZ_REGISTRY_VALIDATE_BO_PVT
    l_create_update_flag := HZ_REGISTRY_VALIDATE_BO_PVT.check_bo_op(
                              p_entity_id      => x_cust_acct_id,
                              p_entity_os      => x_cust_acct_os,
                              p_entity_osr     => x_cust_acct_osr,
                              p_entity_type    => 'HZ_CUST_ACCOUNTS',
                              p_parent_id      => px_parent_id,
                              p_parent_obj_type => px_parent_obj_type
                            );

    IF(l_create_update_flag = 'E') THEN
      FND_MESSAGE.SET_NAME('AR', 'HZ_API_PROPAGATE_OBJECT_ERROR');
      FND_MESSAGE.SET_TOKEN('OBJECT', 'CUST_ACCT');
      FND_MSG_PUB.ADD;
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    IF(l_create_update_flag = 'C') THEN
      do_create_dir_cust_acct_bo(
        p_cust_acct_obj       => p_cust_acct_obj,
        p_cust_prof_cls_name  => p_cust_prof_cls_name,
        p_bo_process_id       => p_bo_process_id,
        p_bpel_process_id     => p_bpel_process_id,
        p_created_by_module   => p_created_by_module,
        x_cust_acct_id        => x_cust_acct_id,
        x_cust_acct_os        => x_cust_acct_os,
        x_cust_acct_osr       => x_cust_acct_osr,
        px_parent_id          => px_parent_id,
        px_parent_os          => px_parent_os,
        px_parent_osr         => px_parent_osr,
        px_parent_obj_type    => px_parent_obj_type
      );
    ELSIF(l_create_update_flag = 'U') THEN
      do_update_dir_cust_acct_bo(
        p_cust_acct_obj       => p_cust_acct_obj,
        p_cust_prof_cls_name  => p_cust_prof_cls_name,
        p_bo_process_id       => p_bo_process_id,
        p_bpel_process_id     => p_bpel_process_id,
        p_created_by_module   => p_created_by_module,
        x_cust_acct_id        => x_cust_acct_id,
        x_cust_acct_os        => x_cust_acct_os,
        x_cust_acct_osr       => x_cust_acct_osr,
        px_parent_id          => px_parent_id,
        px_parent_os          => px_parent_os,
        px_parent_osr         => px_parent_osr,
        px_parent_obj_type    => px_parent_obj_type
      );
    ELSE
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_dir_cust_acct_bo(-)');

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_save_dir_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  x_cust_acct_id       
                                              , P_ORIG_SYSTEM            =>  px_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  px_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_save_dir_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          ); 
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_dir_cust_acct_bo'         || SQLERRM;                                                                                  
    WHEN OTHERS THEN
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'do_save_dir_cust_acct_bo'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  x_cust_acct_id       
                                              , P_ORIG_SYSTEM            =>  px_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  px_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in XX_CDH_CUSTOMER_MASTER_BO_PUB.do_save_dir_cust_acct_bo '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );  
      L_RETURN_STATUS := 'E';        
      X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.do_save_dir_cust_acct_bo'         || SQLERRM;                                                                                  
  END do_save_dir_cust_acct_bo;  
  
  -- PROCEDURE save_cust_accounts
  --
  -- DESCRIPTION
  --     Create or update customer accounts.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_account_objs       List of customer account objects.
  --     p_create_update_flag Create or update flag.
  --     p_parent_id          Parent Id.
  --     p_parent_os          Parent original system.
  --     p_parent_osr         Parent original system reference.
  --     p_parent_obj_type    Parent object type.
  --   OUT:
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   18-OCT-2012    Sreedhar Mohan          Created.

  PROCEDURE save_cust_accounts(
    p_account_objs            IN OUT NOCOPY HZ_CUST_ACCT_BO_TBL,
    p_bo_process_id           IN            NUMBER,
    p_bpel_process_id         IN            NUMBER, 
    p_create_update_flag      IN            VARCHAR2,
    p_cust_prof_cls_name      IN            VARCHAR2,
    p_parent_id               IN            NUMBER,
    p_parent_os               IN            VARCHAR2,
    p_parent_osr              IN            VARCHAR2,
    p_parent_obj_type         IN            VARCHAR2,
    x_return_status              OUT NOCOPY VARCHAR2,
    x_errbuf                     OUT NOCOPY VARCHAR2
  ) IS
    l_validate_bo_flag        VARCHAR2(30) := FND_API.G_TRUE;
    l_debug_prefix            VARCHAR2(30) := '';
    l_ca_id                   NUMBER;
    l_ca_os                   VARCHAR2(30);
    l_ca_osr                  VARCHAR2(255);
    l_parent_id               NUMBER;
    l_parent_os               VARCHAR2(30);
    l_parent_osr              VARCHAR2(255);
    l_parent_obj_type         VARCHAR2(30);
    l_cbm                     VARCHAR2(30);
    l_obj_source              VARCHAR2(60) := null;
    
    l_return_status          varchar2(1) := x_return_status;
    l_msg_count              number;
    l_msg_data               varchar2(2000) := x_errbuf;
  
  BEGIN
    -- initialize API return status to success
    l_return_status := FND_API.G_RET_STS_SUCCESS;
    l_msg_data      := NULL;

    --debug msg
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(+)In XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts(+)');
    
    --validate business object (evaluate)
    /*
    IF(l_validate_bo_flag = FND_API.G_TRUE) THEN
      HZ_REGISTRY_VALIDATE_BO_PVT.get_bus_obj_struct(
        p_bus_object_code         => 'CUST_ACCT',
        x_bus_object              => l_bus_object
      );
      l_valid_obj := HZ_REGISTRY_VALIDATE_BO_PVT.is_ca_bo_comp(
                       p_account_objs    => HZ_CUST_ACCT_BO_TBL(p_cust_acct_obj),
                       p_bus_object => l_bus_object
                     );
      IF NOT(l_valid_obj) THEN
        XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  P_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id      
                                              , P_BO_OBJECT_NAME         =>  'HZ_ORGANIZATION_BO'       
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id            
                                              , P_PACKAGE_NAME           =>  'HZ_PARTY_V2PUB'         
                                              , P_PROCEDURE_NAME         =>  'do_create_cust_account'       
                                              , P_BO_TABLE_NAME          =>  'HZ_PARTIES'        
                                              , P_BO_COLUMN_NAME         =>  'PARTY_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_organization_id      
                                              , P_ORIG_SYSTEM            =>  p_organization_obj.ORIG_SYSTEM
                                              , P_ORIG_SYSTEM_REFERENCE  =>  p_organization_obj.ORIG_SYSTEM_REFERENCE
                                              , P_EXCEPTION_LOG          =>  'Invalid Object'        
                                              , P_ORACLE_ERROR_CODE      =>  null    
                                              , P_ORACLE_ERROR_MSG       =>  null 
                                            );
         RAISE FND_API.G_EXC_ERROR;
      END IF;
    END IF; 
    */

    l_parent_id := p_parent_id;
    l_parent_os := p_parent_os;
    l_parent_osr := p_parent_osr;
    l_parent_obj_type := p_parent_obj_type;

    l_cbm := HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE;

    IF(p_create_update_flag = 'C') THEN
      -- Create cust accounts
      FOR i IN 1..p_account_objs.COUNT LOOP
        IF (p_account_objs(i).customer_type = 'CONTRACT') THEN
          do_create_contr_cust_acct_bo(     
            p_cust_acct_obj      => p_account_objs(i),
            p_cust_prof_cls_name => p_cust_prof_cls_name,
            p_bo_process_id      => p_bo_process_id,
            p_bpel_process_id    => p_bpel_process_id,
            p_created_by_module  => p_account_objs(i).created_by_module,
            x_cust_acct_id       => l_parent_id,
            x_cust_acct_os       => l_ca_os,
            x_cust_acct_osr      => l_ca_osr,
            px_parent_id         => l_parent_id,
            px_parent_os         => l_parent_os,
            px_parent_osr        => l_parent_osr,
            px_parent_obj_type   => l_parent_obj_type
          );
        ELSE
          do_create_dir_cust_acct_bo(       
            p_cust_acct_obj      => p_account_objs(i),
            p_cust_prof_cls_name => p_cust_prof_cls_name,
            p_bo_process_id      => p_bo_process_id,
            p_bpel_process_id    => p_bpel_process_id,
            p_created_by_module  => p_account_objs(i).created_by_module,
            x_cust_acct_id       => l_parent_id,
            x_cust_acct_os       => l_ca_os,
            x_cust_acct_osr      => l_ca_osr,
            px_parent_id         => l_parent_id,
            px_parent_os         => l_parent_os,
            px_parent_osr        => l_parent_osr,
            px_parent_obj_type   => l_parent_obj_type
          );        
        END IF;

        HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;
      END LOOP;
    ELSE
      -- Create/update cust accounts
      FOR i IN 1..p_account_objs.COUNT LOOP
      
        IF (p_account_objs(i).customer_type = 'CONTRACT') THEN
          do_save_contr_cust_acct_bo(     
            p_cust_acct_obj      => p_account_objs(i),
            p_bo_process_id      => p_bo_process_id,
            p_bpel_process_id    => p_bpel_process_id,
            p_created_by_module  => p_account_objs(i).created_by_module,
            p_cust_prof_cls_name => p_cust_prof_cls_name,
            x_cust_acct_id       => l_parent_id,
            x_cust_acct_os       => l_ca_os,
            x_cust_acct_osr      => l_ca_osr,
            px_parent_id         => l_parent_id,
            px_parent_os         => l_parent_os,
            px_parent_osr        => l_parent_osr,
            px_parent_obj_type   => l_parent_obj_type,
                        x_errbuf             => x_errbuf
          );
        ELSE
          do_save_dir_cust_acct_bo(       
            p_cust_acct_obj      => p_account_objs(i),
            p_bo_process_id      => p_bo_process_id,
            p_bpel_process_id    => p_bpel_process_id,
            p_created_by_module  => p_account_objs(i).created_by_module,
            p_cust_prof_cls_name => p_cust_prof_cls_name,
            x_cust_acct_id       => l_parent_id,
            x_cust_acct_os       => l_ca_os,
            x_cust_acct_osr      => l_ca_osr,
            px_parent_id         => l_parent_id,
            px_parent_os         => l_parent_os,
            px_parent_osr        => l_parent_osr,
            px_parent_obj_type   => l_parent_obj_type,
                        x_errbuf             => x_errbuf
          );         
        END IF;

        HZ_UTILITY_V2PUB.G_CREATED_BY_MODULE := l_cbm;
      END LOOP;
    END IF;

    -- Debug info.
    XX_CDH_CUST_UTIL_BO_PUB.log_msg(p_bo_process_id, '(-)In XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts(-)');

  EXCEPTION
    when others then
      --call exception process
      XX_CDH_CUST_UTIL_BO_PUB.LOG_EXCEPTION (
                                                P_BO_PROCESS_ID          =>  p_BO_PROCESS_ID        
                                              , P_BPEL_PROCESS_ID        =>  p_bpel_process_id       
                                              , P_BO_OBJECT_NAME         =>  'HZ_CUST_ACCT_BO'            
                                              , P_LOG_DATE               =>  SYSDATE             
                                              , P_LOGGED_BY              =>  FND_GLOBAL.user_id                    
                                              , P_PACKAGE_NAME           =>  'XX_CDH_ACCOUNT_BO_WRAP_PUB'            
                                              , P_PROCEDURE_NAME         =>  'save_cust_accounts'              
                                              , P_BO_TABLE_NAME          =>  'HZ_CUST_ACCOUNTS'        
                                              , P_BO_COLUMN_NAME         =>  'CUST_ACCOUNT_ID'       
                                              , P_BO_COLUMN_VALUE        =>  l_ca_id       
                                              , P_ORIG_SYSTEM            =>  l_parent_os
                                              , P_ORIG_SYSTEM_REFERENCE  =>  l_parent_osR
                                              , P_EXCEPTION_LOG          =>  'Exception in save_cust_accounts '  || SQLERRM      
                                              , P_ORACLE_ERROR_CODE      =>  SQLCODE    
                                              , P_ORACLE_ERROR_MSG       =>  SQLERRM 
                                          );                                  
    X_RETURN_STATUS := 'E'; 
    X_ERRBUF        := 'Error in XX_CDH_ACCOUNT_BO_WRAP_PUB.save_cust_accounts'  || SQLERRM;
END save_cust_accounts;
  
  
END XX_CDH_ACCOUNT_BO_WRAP_PUB;
/
SHOW ERRORS;
