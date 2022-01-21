create or replace
PACKAGE BODY XX_AR_CREDIT_LIMIT_UPLOAD_PKG AS
-- +============================================================================================+ 
-- |  Office Depot - Project Simplify                                                           | 
-- |  Providge Consulting                                                                       |  
-- +============================================================================================+ 
-- |  Name:  XX_AR_CREDIT_LIMIT_UPLOAD_PKG                                                      | 
-- |                                                                                            | 
-- |  Description:  This package is used by WEB ADI to mass update credit limits.               |
-- |                                                                                            |
-- |  Change Record:                                                                            | 
-- +============================================================================================+ 
-- | Version     Date         Author           Remarks                                          | 
-- | =========   ===========  =============    ===============================================  | 
-- | 1.0         18-Mar-2011  R.Strauss            Initial version                              |
-- +============================================================================================+
PROCEDURE INSERT_CREDIT_LIMIT(P_ACCOUNT_NUMBER  IN VARCHAR2,
                              P_CREDIT_LIMIT    IN NUMBER,
                              P_CURRENCY_CODE   IN VARCHAR2) 
IS

BEGIN
    INSERT INTO XX_AR_CREDIT_LIMIT_UPDATES (ACCOUNT_NUMBER,
                                            CREDIT_LIMIT,
                                            CURRENCY_CODE,
                                            CREATION_DATE,
                                            CREATED_BY,
                                            LAST_UPDATE_DATE,
                                            LAST_UPDATED_BY)
                                     VALUES(P_ACCOUNT_NUMBER,
                                            P_CREDIT_LIMIT,
                                            P_CURRENCY_CODE,
                                            SYSDATE,
                                            fnd_global.user_id,
                                            SYSDATE,
                                            fnd_global.user_id);
     COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error inserting into staging table'||substr(sqlerrm,1,200));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'');

END INSERT_CREDIT_LIMIT;

PROCEDURE UPDATE_CREDIT_LIMIT(errbuf       OUT NOCOPY VARCHAR2,
                              retcode      OUT NOCOPY NUMBER) 
IS

lc_error_message	  VARCHAR2(200);
lc_return_status	  VARCHAR2(1);
lc_account_number         VARCHAR2(30);
lc_currency_code          VARCHAR2(3);
lc_credit_limit           NUMBER;
ln_user_id                fnd_user.user_id%TYPE;

lc_user_name              fnd_user.user_name%TYPE;
lc_cust_account_id        NUMBER;
lc_party_id               NUMBER;
ln_count                  NUMBER;
lc_status                 VARCHAR2(1);
lc_credit_hold            VARCHAR2(1);
lc_temp_credit_flag	  VARCHAR2(1);
lc_cust_acct_prof_amt_id  NUMBER;
ln_obj_ver_num            NUMBER;
ln_msg_count              NUMBER;
lc_msg_data               VARCHAR2(2000);

ln_customer_profile_rec_type    hz_customer_profile_v2pub.cust_profile_amt_rec_type;

E_UPDATE_ERROR          EXCEPTION;


CURSOR cr_updates IS
       SELECT ACCOUNT_NUMBER,
              CURRENCY_CODE,
              CREDIT_LIMIT
       FROM   XX_AR_CREDIT_LIMIT_UPDATES
       WHERE  STATUS IS NULL
       AND    CREATED_BY = ln_user_id;

BEGIN

	FND_FILE.PUT_LINE(fnd_file.log,'XX_AR_CREDIT_LIMIT_UPLOAD_PKG - begin processing ');
	ln_user_id := fnd_global.user_id;

        SELECT user_name

        INTO lc_user_name

        FROM fnd_user

        WHERE user_id = ln_user_id;


        FND_FILE.PUT_LINE(fnd_file.log,' ');
        FND_FILE.PUT_LINE(fnd_file.log,'Purging old XX_AR_CREDIT_LIMIT_UPDATES for user '||lc_user_name);

        DELETE FROM XX_AR_CREDIT_LIMIT_UPDATES
        WHERE  STATUS IS NOT NULL
        AND    created_by = ln_user_id;
        COMMIT;

        FND_FILE.PUT_LINE(fnd_file.log,' ');
        FND_FILE.PUT_LINE(fnd_file.log,'Purged '||SQL%ROWCOUNT||' records from XX_AR_CREDIT_LIMIT_UPDATES');

        FND_FILE.PUT_LINE(fnd_file.log,' ');
        FND_FILE.PUT_LINE(fnd_file.log,'Processing XX_AR_CREDIT_LIMIT_UPDATES');
        -----------------------------------------------------------------------------------------
        FOR update_rec IN cr_updates LOOP
            BEGIN

               lc_account_number := update_rec.account_number;
               lc_currency_code  := update_rec.currency_code;
               lc_credit_limit   := update_rec.credit_limit;
           ----------------------------------------------------------------------------------------- active account
               BEGIN
                  SELECT CUST_ACCOUNT_ID, PARTY_ID
                  INTO   lc_cust_account_id,
                         lc_party_id
                  FROM   HZ_CUST_ACCOUNTS
                  WHERE  ACCOUNT_NUMBER = lc_account_number
                  AND    STATUS         = 'A';

               EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         lc_error_message := 'Account is not active: '||lc_account_number;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                         RAISE E_UPDATE_ERROR;
                    WHEN OTHERS THEN
                         lc_error_message := 'Unknown error, account: '||lc_account_number||' sqlcode '||sqlcode;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                         RAISE E_UPDATE_ERROR;
               END;
           ----------------------------------------------------------------------------------------- Relationships 
               BEGIN
                  SELECT count(*)  
                  INTO   ln_count
                  FROM   HZ_RELATIONSHIPS R
                  WHERE  R.RELATIONSHIP_TYPE    = 'OD_FIN_HIER'
                  AND    R.RELATIONSHIP_CODE LIKE 'GROUP_SUB_MEMBER_OF'
                  AND    R.SUBJECT_ID           = lc_party_id
                  GROUP BY R.RELATIONSHIP_CODE;

                  IF ln_count = 1 THEN
                     lc_error_message := 'Account is a child: '||lc_account_number;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     RAISE E_UPDATE_ERROR;
                  END IF;

                  IF ln_count > 1 THEN
                     lc_error_message := 'Account is in multiple relationships: '||lc_account_number;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     RAISE E_UPDATE_ERROR;
                  END IF;

               EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         lc_error_message := 'Ok, either parent account or stand alone ';
                    WHEN OTHERS THEN
                         lc_error_message := 'Unknown error, account: '||lc_account_number||' sqlcode '||sqlcode;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                         RAISE E_UPDATE_ERROR;
               END;
           ----------------------------------------------------------------------------------------- Profile credit hold
               BEGIN
                  SELECT A.cust_acct_profile_amt_id, P.status, P.credit_hold, A.object_version_number
                  INTO   lc_cust_acct_prof_amt_id, lc_status, lc_credit_hold, ln_obj_ver_num
                  FROM   HZ_CUSTOMER_PROFILES P,
                         hz_cust_profile_amts A
                  WHERE  P.cust_account_profile_id = A.cust_account_profile_id
                  AND    A.CURRENCY_CODE           = lc_currency_code
                  AND    P.SITE_USE_ID            IS NULL
                  AND    P.CUST_ACCOUNT_ID         = lc_cust_account_id;

                  IF lc_status <> 'A' THEN
                     lc_error_message := 'Account profile is not active '||lc_cust_account_id;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     RAISE E_UPDATE_ERROR;
                  END IF;

                  IF lc_credit_hold <> 'N' THEN
                     lc_error_message := 'Account profile has credit hold '||lc_cust_account_id;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     RAISE E_UPDATE_ERROR;
                  END IF;

               EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         lc_error_message := 'Account profile does not exist '||lc_cust_account_id;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                         RAISE E_UPDATE_ERROR;
                    WHEN OTHERS THEN
                         lc_error_message := 'Unknown error, account: '||lc_account_number||' sqlcode '||sqlcode;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                         RAISE E_UPDATE_ERROR;
               END;
           ----------------------------------------------------------------------------------------- temp credit limit
               BEGIN
                  SELECT 'Y'
                  INTO   lc_temp_credit_flag
                  FROM   XX_CDH_CUST_ACCT_EXT_B E,
                         EGO_ATTR_GROUPS_V      A
                  WHERE  E.attr_group_id         = A.ATTR_GROUP_ID
                  and    E.attr_group_id         = A.ATTR_GROUP_ID
                  and    attr_group_type         = 'XX_CDH_CUST_ACCOUNT' 
                  and    attr_group_name         = 'TEMPORARY_CREDITLIMIT'
                  and    nvl(E.c_ext_attr3,'N') <> 'Y'
                  and    nvl(E.c_ext_attr4,'N') <> 'Y' 
                  AND    E.CUST_ACCOUNT_ID       = lc_cust_account_id
                  AND    SYSDATE BETWEEN E.d_ext_attr1 AND E.d_ext_attr1;

                  IF lc_temp_credit_flag = 'Y' THEN
                     lc_error_message := 'Account already has temporary credit limit '||lc_cust_account_id;
                     FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                     RAISE E_UPDATE_ERROR;
                  END IF;

               EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                         lc_error_message := 'Ok, account has no temporary credit limit';
                    WHEN OTHERS THEN
                         lc_error_message := 'Unknown error, account: '||lc_account_number||' sqlcode '||sqlcode;
                         FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                         RAISE E_UPDATE_ERROR;
               END;
           ----------------------------------------------------------------------------------------- Update credit limit
               BEGIN

                  ln_customer_profile_rec_type := NULL; 
                  ln_customer_profile_rec_type.cust_acct_profile_amt_id := lc_cust_acct_prof_amt_id;
                  ln_customer_profile_rec_type.overall_credit_limit     := lc_credit_limit;
                  ln_customer_profile_rec_type.attribute1               := 'N';


                  HZ_CUSTOMER_PROFILE_V2PUB.update_cust_profile_amt ( p_init_msg_list         => fnd_api.g_true,
                                                                      p_cust_profile_amt_rec  => ln_customer_profile_rec_type,
                                                                      p_object_version_number => ln_obj_ver_num,
                                                                      x_return_status         => lc_return_status ,
                                                                      x_msg_count             => ln_msg_count ,
                                                                      x_msg_data              => lc_msg_data    
                                                                    );

                 IF lc_RETURN_STATUS = FND_API.G_RET_STS_SUCCESS THEN 
                    BEGIN
                         UPDATE XX_AR_CREDIT_LIMIT_UPDATES
                         SET status              = 'C',
                             description         = 'Credit Limit successfully updated',
                             last_update_date    = sysdate
                         WHERE ACCOUNT_NUMBER    = lc_account_number
                         AND   last_update_date is NULL;
                         COMMIT;

                         FND_FILE.PUT_LINE(fnd_file.log,' ');
                         FND_FILE.PUT_LINE(fnd_file.log,'Successfully updated credit limit for account '||lc_account_number);

                    EXCEPTION
                         WHEN OTHERS THEN
                             lc_error_message := 'Error updating XX_AR_CREDIT_LIMIT_UPDATES: '||lc_account_number||' sqlcode '||sqlcode;
                             FND_FILE.PUT_LINE(FND_FILE.LOG,lc_error_message);
                             RAISE E_UPDATE_ERROR;
                    END;
                    COMMIT;
                 ELSE          
                    IF ln_MSG_COUNT > 0 THEN
                       FND_FILE.PUT_LINE(FND_FILE.LOG,'API returned Error while trying to update the credit limit');
                       FOR counter IN 1..ln_MSG_COUNT
                           LOOP
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_TRUE));
                       END LOOP;
                       RAISE E_UPDATE_ERROR;
                    END IF;
                 END IF;

               END;
           -----------------------------------------------------------------------------------------


           EXCEPTION
                WHEN E_UPDATE_ERROR THEN
                     UPDATE XX_AR_CREDIT_LIMIT_UPDATES
                     SET status              = 'E',
                         description         = lc_error_message,
                         last_update_date    = sysdate
                     WHERE ACCOUNT_NUMBER    = lc_account_number
                     AND   last_update_date is NULL;
                     COMMIT;

                     FND_FILE.PUT_LINE(FND_FILE.LOG,'Skipping update, account: '||lc_account_number);
           END;
           END LOOP;

   
EXCEPTION
	WHEN OTHERS THEN
		retcode := 1;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected error '||lc_error_message||substr(sqlerrm,1,200));
		FND_FILE.PUT_LINE(FND_FILE.LOG,'');
		raise FND_API.G_EXC_ERROR;

END UPDATE_CREDIT_LIMIT;

END XX_AR_CREDIT_LIMIT_UPLOAD_PKG;
/