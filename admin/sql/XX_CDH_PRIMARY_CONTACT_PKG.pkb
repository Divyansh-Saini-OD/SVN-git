CREATE OR REPLACE
PACKAGE BODY XX_CDH_PRIMARY_CONTACT_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CDH_PRIMARY_CONTACT_PKG.pkb                           |
-- | Description :  This package is used to find the the primary contact for |
-- |                an account and chnges to non primary.                    |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |DRAFT 1   12-Mar-2008 Kathirvel          Initial draft version           |
-- |1.1       13-Apr-2008 Kathirvel          Made non primary on Contact     |
-- |                                         Responsibility                  |
-- |1.2       03-Feb-2009 Kalyan             Commented the check on status of|
-- |                                         hz_cust_accounts in cursor      |
-- |                                         c_acct_primary_contact.         |
-- |                                         Commented commit at the end.    |
-- +=========================================================================+
AS


-- +========================================================================+
-- | Name        :  Process_Account_Contact                                 |
-- | Description :  Find the primary account contact and updates on the     |
-- |                table HZ_CUST_ACCOUNT_ROLES.                            |
-- +========================================================================+
PROCEDURE Process_Account_Contact(
p_contact_osr                          IN VARCHAR2,
p_account_osr                          IN VARCHAR2,
x_return_status 		               OUT NOCOPY VARCHAR2,
x_error_message                        OUT NOCOPY VARCHAR2)
IS

ln_acct_role_id         NUMBER;
ln_party_id             NUMBER;
ln_cust_acct_id         NUMBER;
ln_version_no           NUMBER;
lv_return_status        VARCHAR2(1);
lv_error_message        VARCHAR2(2000);
l_account_role_rec      HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
l_role_resp_rec         HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_type;
ln_msg_count            NUMBER;
lv_msg_data             VARCHAR2(2000);
ln_responsibility_id    NUMBER;
ln_objver_no            NUMBER;


CURSOR c_acct_primary_contact IS
SELECT ccr.cust_account_role_id,
       ccr.party_id,
       ccr.cust_account_id,
       ccr.object_version_number
FROM   hz_cust_account_roles ccr,
       hz_cust_accounts_all caa
WHERE  ccr.cust_account_id = caa.cust_account_id 
AND    caa.orig_system_reference = p_account_osr
AND    ccr.primary_flag = 'Y'
AND    ccr.cust_acct_site_id IS NULL
AND    ccr.orig_system_reference <> p_contact_osr
--AND    caa.status = 'A'
AND    ccr.status = 'A';


CURSOR c_acct_contact_resp(role_resp NUMBER) IS
SELECT responsibility_id , 
       object_version_number 
FROM   hz_role_responsibility
WHERE  cust_account_role_id = role_resp
AND    primary_flag = 'Y';

BEGIN

    x_return_status  := 'S';

    FOR acct_cnt_cur IN  c_acct_primary_contact
    LOOP

        l_account_role_rec.cust_account_role_id  := acct_cnt_cur.cust_account_role_id;
        l_account_role_rec.party_id              := acct_cnt_cur.party_id;
        l_account_role_rec.cust_account_id       := acct_cnt_cur.cust_account_id;
        l_account_role_rec.primary_flag          := 'N';
        ln_version_no                            := acct_cnt_cur.object_version_number;


        HZ_CUST_ACCOUNT_ROLE_V2PUB.update_cust_account_role (
               p_init_msg_list           => FND_API.G_FALSE,
               p_cust_account_role_rec   => l_account_role_rec,
               p_object_version_number   => ln_version_no,
               x_return_status           => lv_return_status,
               x_msg_count               => ln_msg_count,
               x_msg_data   		     => lv_msg_data
               );

       IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN

    		x_return_status := lv_return_status;

    		IF(ln_msg_count > 1) THEN
        		FOR I IN 1..FND_MSG_PUB.Count_Msg 
        		LOOP
            		lv_error_message := FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE );
        		END LOOP;
    		ELSE
        		lv_error_message := lv_msg_data;
    		END IF;
       ELSE

          OPEN   c_acct_contact_resp(acct_cnt_cur.cust_account_role_id);
          FETCH  c_acct_contact_resp INTO ln_responsibility_id,ln_objver_no;
          CLOSE  c_acct_contact_resp;

          IF ln_responsibility_id IS NOT NULL THEN

            l_role_resp_rec.responsibility_id     := ln_responsibility_id;
            l_role_resp_rec.cust_account_role_id  := acct_cnt_cur.cust_account_role_id;
            l_role_resp_rec.primary_flag          := 'N';


            HZ_CUST_ACCOUNT_ROLE_V2PUB.update_role_responsibility
                     (  p_init_msg_list            => FND_API.G_FALSE
                     ,  p_role_responsibility_rec  => l_role_resp_rec
                     ,  p_object_version_number    => ln_objver_no
                     ,  x_return_status            => lv_return_status
                     ,  x_msg_count                => ln_msg_count
                     ,  x_msg_data                 => lv_msg_data
                     );
 
       	IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN

    			x_return_status := lv_return_status;

    			IF(ln_msg_count > 1) THEN
        			FOR I IN 1..FND_MSG_PUB.Count_Msg 
        			LOOP
            			lv_error_message := FND_MSG_PUB.Get(I, p_encoded => FND_API.G_FALSE );
        			END LOOP;
    			ELSE
        			lv_error_message := lv_msg_data;
    			END IF;
            END IF;
          END IF;
       END IF;
    END LOOP;

   -- COMMIT;
    x_error_message := lv_error_message;

EXCEPTION
   WHEN OTHERS THEN
    x_return_status  := 'E';  
    x_error_message  := SQLERRM;

 END  Process_Account_Contact;
                      
END XX_CDH_PRIMARY_CONTACT_PKG;
/