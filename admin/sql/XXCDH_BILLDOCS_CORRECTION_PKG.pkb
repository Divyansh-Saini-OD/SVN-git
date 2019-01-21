SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XXCDH_BILLDOCS_CORRECTION_PKG
as
-- +============================================================================================+
-- |  Name:  XXCDH_BILLDOCS_CORRECTION_PKG                                                      |
-- +============================================================================================+
-- | Version     Date         Author           Remarks                                          |
-- | =========   ===========  =============    ===============================================  |
-- | 1.1         22-OCT-2015  Vasu Raparla      Removed Schema References For R12.2             |
-- +============================================================================================+
procedure ADD_BILLDOCS (
                         p_errbuf    OUT NOCOPY varchar2,
                         p_retcode   OUT NOCOPY varchar2,
                         p_batch_id  number
                       )
as
  l_attr_group_id                 number;
  l_old_attr_group_id             number;
  l_billdoc_exist                 varchar2(1) := 'Y';

cursor c_billdocs_attr_id    
is
SELECT attr_group_id
      FROM ego_attr_groups_v
     WHERE application_id = 222
       AND attr_group_name = 'BILLDOCS'
       AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';

cursor c_direct_ab_customers 
is
select acct.orig_system_reference,
       acct.attribute18,
       acct.cust_account_id
from   hz_cust_accounts acct,
       hz_customer_profiles prof
where  acct.cust_account_id = prof.cust_account_id
and    prof.site_use_id is null
and    prof.attribute3 = 'Y'
and    acct.attribute18 = 'DIRECT';

cursor c_billdoc_exist(p_attr_id number, 
                       p_cust_account_id number)
is
select 'Y'
from  XX_CDH_CUST_ACCT_EXT_B
where  attr_group_id = p_attr_id
and    cust_account_id = p_cust_account_id;

begin

    open c_billdocs_attr_id;
    fetch c_billdocs_attr_id into l_attr_group_id;

    FOR i_rec in c_direct_ab_customers
    LOOP
      open c_billdoc_exist (l_attr_group_id, i_rec.cust_account_id);
      fetch c_billdoc_exist into l_billdoc_exist;
     
      if (l_billdoc_exist <> 'Y') then
        XXCDH_BILLDOCS_PKG.create_billdocs(
                                            p_batch_id,
                                            'A0',
                                            i_rec.orig_system_reference,
                                            i_rec.attribute18
                                           );
      end if;

     close c_billdoc_exist;
    END LOOP;
    close c_billdocs_attr_id;
  exception
    when others then
    dbms_output.put_line('Exception : ' || SQLERRM);

end ADD_BILLDOCS;


procedure MOVE_NON_AB_CONTRACT_BILLDOCS (
                         p_errbuf    OUT NOCOPY varchar2,
                         p_retcode   OUT NOCOPY varchar2
                       )
as
  l_attr_group_id                 number;
  l_old_attr_group_id             number;

begin
  --Remove Old billdocs for contract non-ab customers
    SELECT attr_group_id
     into  l_old_attr_group_id
      FROM ego_attr_groups_v
     WHERE application_id = 222
       AND attr_group_name = 'OLD_BILLDOCS'
       AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';

    SELECT attr_group_id
     into  l_attr_group_id
      FROM ego_attr_groups_v
     WHERE application_id = 222
       AND attr_group_name = 'BILLDOCS'
       AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';

      UPDATE  XX_CDH_CUST_ACCT_EXT_B
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
                               FROM  HZ_CUST_ACCOUNTS acct,
                                     HZ_CUSTOMER_PROFILES prof
                                WHERE acct.cust_account_id = prof.cust_account_id
                                AND   prof.site_use_id is null
                                AND   acct.attribute18 = 'CONTRACT'
                                AND   nvl(prof.attribute3,'N') = 'N'
                               )
      and  attr_group_id=l_attr_group_id;

      dbms_output.put_line('No. of Rows Updated in XX_CDH_CUST_ACCT_EXT_B' || SQL%ROWCOUNT);

      UPDATE   XX_CDH_CUST_ACCT_EXT_TL
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
                               FROM  HZ_CUST_ACCOUNTS acct,
                                     HZ_CUSTOMER_PROFILES prof
                                WHERE acct.cust_account_id = prof.cust_account_id
                                AND   prof.site_use_id is null
                                AND   acct.attribute18 = 'CONTRACT'
                                AND   nvl(prof.attribute3,'N') = 'N'
                               )
      and  attr_group_id=l_attr_group_id;

      dbms_output.put_line('No. of Rows Updated in XX_CDH_CUST_ACCT_EXT_TL' || SQL%ROWCOUNT);

      COMMIT;

  exception
    when others then
    dbms_output.put_line('Exception : ' || SQLERRM);
  end MOVE_NON_AB_CONTRACT_BILLDOCS;

end XXCDH_BILLDOCS_CORRECTION_PKG;
/
SHOW ERRORS;
