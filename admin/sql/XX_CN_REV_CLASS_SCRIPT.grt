-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                Oracle NAIO Consulting Organization                |
-- +===================================================================+
-- | Name        : XX_CN_REV_CLASS_SCRIPT.sql                          |
-- | Rice ID     : E1004_CustomCollections                             |
-- | Description : XX_CN_REV_CLASS Table-Static Data Population Script |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======  ===========  =============    ============================|
-- |Draft 1a 16-Nov-2007  Vidhya Valantina Initial draft version       |
-- |1.0      16-Nov-2007  Vidhya Valantina Baselined after testing     |
-- |                                                                   |
-- +===================================================================+

DECLARE

    ld_sysdate  DATE := SYSDATE;

    ln_login    NUMBER := FND_GLOBAL.Login_Id;
    ln_user_id  NUMBER := FND_GLOBAL.User_Id;

BEGIN

    DELETE
    FROM   xx_cn_rev_class;

    COMMIT;

    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '760',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '762',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '988',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '993',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '995',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '299',   'Any',   'Any',   'N',   'DPS',   'DPS - Promo -NonPvt',   6,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '59',   '349',   'Any',   'Any',   'N',   'DPS',   'DPS - Promo -NonPvt',   6,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '759',   'Any',   'Any',   'N',   'DPS',   'DPS - Promo -NonPvt',   6,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '659',   'Any',   'Any',   'N',   'DPS',   'DPS - Promo -NonPvt',   6,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   'Any',   'Any',   'Any',   'N',   'BSD',   'BSD-Non Private',   1,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   'Any',   'Any',   'Any',   'Y',   'BSD',   'BSD-Private',   2,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '1',   'Any',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '8',   'Any',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '23',   'Any',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '25',   'Any',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '27',   'Any',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '37',   'Any',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '113',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '650',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '654',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '660',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '672',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '697',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '705',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '777',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '900',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '909',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '917',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '927',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '938',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '964',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '966',   'Any',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   'Any',   'Hedberg',   'Any',   'Y',   'Furniture',   'Furniture-Private',   8,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   'Any',   'Any',   'Fanatic',   'Y',   'Technology',   'Technology',   9,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '10',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '11',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '14',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '16',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '19',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '31',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '32',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '34',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '38',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '38',   '318',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '36',   '479',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '500',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '655',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '658',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '753',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '756',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '757',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '760',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '762',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '988',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '993',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '995',   'Any',   'Any',   'Y',   'DPS',   'DPS - Printing - Pvt',   4,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '299',   'Any',   'Any',   'Y',   'DPS',   'DPS - Promo - Pvt',   5,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '59',   '349',   'Any',   'Any',   'Y',   'DPS',   'DPS - Promo - Pvt',   5,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '759',   'Any',   'Any',   'Y',   'DPS',   'DPS - Promo - Pvt',   5,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '659',   'Any',   'Any',   'Y',   'DPS',   'DPS - Promo - Pvt',   5,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '1',   'Any',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '8',   'Any',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '23',   'Any',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '25',   'Any',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '27',   'Any',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '37',   'Any',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '113',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '650',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '654',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '660',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '672',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '697',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '705',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '777',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '900',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '909',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '917',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '927',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '938',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '964',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   '966',   'Any',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   'Any',   'Any',   'Hedberg',   'Any',   'N',   'Furniture',   'Furniture-Non Private',   7,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '10',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '11',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '14',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '16',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '19',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '31',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '32',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '34',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '38',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '38',   '318',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '36',   '479',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '32',   '500',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '655',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '40',   '658',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '753',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '756',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);
    INSERT
    INTO xxcrm.xx_cn_rev_class(rev_class_id,   item_number,   department,   class,   order_source,   collection_source,   private_brand_flag,   division,   rev_class,   revenue_class_id,   created_by,   creation_date,   last_updated_by,   last_update_date,   last_update_login)
    VALUES(xxcrm.xx_cn_rev_class_s.nextval,   'Any',   '29',   '757',   'Any',   'Any',   'N',   'DPS',   'DPS - Printing - NonPvt',   3,   ln_user_id,   ld_sysdate,   ln_user_id,   ld_sysdate,   ln_login);

    COMMIT;

END;
/

SHOW ERRORS;