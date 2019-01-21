-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- +=========================================================================+
-- | Name        :  XX_CDH_ACCTCONTACT_CLEANUP.sql                           |
-- | Description :  This script gets the inactive account contacts and       |
-- |                compare with party relation. If the party relation is    |
-- |                active, activates the account contacts. Since the avtive |
-- |                contact got inactvated by the wrong version of the code, |
-- |                this clean up is required to make active the account     |
-- |                contacts.                                                |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version   Date        Author             Remarks                         |
-- |========  =========== ================== ================================|
-- |DRAFT 1   18-Sep-2008 Kathirvel          Initial draft version           |
-- +=========================================================================+

DECLARE

   CURSOR l_inactive_contacts IS
   SELECT /* parallel (a,8) */ cust_account_role_id,party_id,cust_account_id,object_version_number 
   from   HZ_CUST_ACCOUNT_ROLES a
   where  a.status = 'I';

   CURSOR l_active_party(vur_party_id NUMBER) IS
   SELECT /* parallel (b,8) */ b.party_id 
   from   HZ_PARTIES b
   where  party_id = vur_party_id
   and    b.status = 'A';

   l_party_id             NUMBER;
   l_role_object_version  NUMBER;
   l_role_rec_type        HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
   l_msg_data              VARCHAR2(4000);
   l_msg_count             NUMBER;
   l_return_status         VARCHAR2(5);

BEGIN

FOR I IN l_inactive_contacts
LOOP
    l_party_id := NULL;

    OPEN  l_active_party(I.party_id);
    FETCH l_active_party INTO l_party_id;
    CLOSE l_active_party ;

    IF l_party_id = I.party_id
    THEN

	 l_role_rec_type.cust_account_role_id  := I.cust_account_role_id;
	 l_role_rec_type.cust_account_id       := I.cust_account_id;
	 l_role_rec_type.status                := 'A';
	 l_role_object_version                 := I.object_version_number;

	 hz_cust_account_role_v2pub.update_cust_account_role(
		       p_init_msg_list                  => FND_API.G_FALSE
		     , p_cust_account_role_rec          => l_role_rec_type
		     , p_object_version_number          => l_role_object_version
		     , x_return_status                  => l_return_status
		     , x_msg_count                      => l_msg_count
		     , x_msg_data                       => l_msg_data
		     );

         IF l_return_status <> 'S'
	 THEN
	    dbms_output.put_line('Error Message : '||l_msg_data);

	 END IF;
    END IF;

END LOOP;

COMMIT;

dbms_output.put_line('Updated Successfully');

EXCEPTION
	WHEN OTHERS
	THEN
	    dbms_output.put_line('Error Message : '||SQLERRM);
END;
