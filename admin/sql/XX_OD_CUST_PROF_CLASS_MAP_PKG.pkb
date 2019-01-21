create or replace PACKAGE BODY XX_OD_CUST_PROF_CLASS_MAP_PKG AS
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- +=========================================================================================+
-- | Name        : XX_OD_CUST_PROF_CLASS_MAP_PKG                                             |
-- | Description : Custom package for data migration.                                        |
-- |                                                                                         |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |1.0        25-Sep-2009     Kalyan               Initial version                          |
-- |1.1        16-Oct-2009     Yusuf Ali            Added DO_COPY_CUST_PROFILES procedure    |
-- |1.2        16-Nov-2009     Kalyan               l_return_status initialized to 'S' in    |
---|                                                DO_COPY_CUST_PROFILES.                   |
---|1.3        10-Nov-2015     Havish Kasina        Removed the schema references as per     |
---|                                                R12.2 Retrofit Changes                   |
---|1.4        11-JAN-2018     Theja Rajula         Added Default SFA20 for AB Y 			 |
-- +=========================================================================================+

PROCEDURE DO_COPY_CUST_PROFILES (
                                    p_cust_account_profile_id  IN         VARCHAR2,
                                    p_cust_account_id          IN         NUMBER,
                                    x_return_status            OUT NOCOPY VARCHAR2,
                                    x_msg_count                OUT NOCOPY VARCHAR2,
                                    x_msg_data                 OUT NOCOPY VARCHAR2
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
  --  fnd_file.put_line(FND_FILE.LOG,'Cust_account_id: ' || p_cust_account_id);
  --  fnd_file.put_line(FND_FILE.OUTPUT,'Cust_account_id: ' || p_cust_account_id);
    x_return_status := 'S';
    l_count := 0;
    for c_rec in c_site_uses(p_cust_account_id)
    loop
       --
       fnd_client_info.set_org_context(c_rec.org_id);
       l_count := l_count + 1;
       l_check := null;
       l_cust_account_profile_id := null;

   --    fnd_file.put_line(FND_FILE.LOG,'  site_use_id' || l_count ||': ' || c_rec.site_use_id);
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
      --       fnd_file.put_line(FND_FILE.OUTPUT,'    new rec, site_use_id: ' || c_rec.site_use_id);
      --       fnd_file.put_line(FND_FILE.LOG,'    new rec, site_use_id: ' || c_rec.site_use_id);

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
          --    fnd_file.put_line(FND_FILE.LOG,'      create_customer_profile, x_return_status: ' || l_return_status);
          --    fnd_file.put_line(FND_FILE.LOG,'      l_msg_count: ' || l_msg_count);
              --
              if l_return_status != 'S' THEN
                  if l_msg_count > 0 THEN
                    begin
                      FOR I IN 1..l_msg_count
                      LOOP
                         l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                      END LOOP;
                    end;
              --    fnd_file.put_line(FND_FILE.LOG,'      l_msg_data: ' || l_msg_data);
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
       --       fnd_file.put_line(FND_FILE.LOG,'      update_customer_profile, x_return_status: ' || l_return_status);
       --       fnd_file.put_line(FND_FILE.LOG,'      l_msg_count: ' || l_msg_count);
              --
              if l_return_status != 'S' THEN
                  if l_msg_count > 0 THEN
                    begin
                      FOR I IN 1..l_msg_count
                      LOOP
                         l_msg_data:= l_msg_data || SubStr(FND_MSG_PUB.Get(p_encoded => FND_API.G_FALSE ), 1, 255);
                      END LOOP;
                    end;
               --   fnd_file.put_line(FND_FILE.LOG,'      l_msg_data: ' || l_msg_data);
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

  EXCEPTION
    WHEN OTHERS THEN
   --   fnd_file.put_line(FND_FILE.OUTPUT,SQLERRM);
      x_return_status := 'E';
      x_msg_data := 'Failed in DO_COPY_CUST_PROFILES with error ' || sqlerrm ;
  END DO_COPY_CUST_PROFILES;




PROCEDURE 	derive_prof_class_dtls (
		            p_customer_osr          IN	        hz_cust_accounts.orig_system_reference%TYPE,
                p_reactivated_flag      IN	        hz_customer_profiles.attribute4%TYPE,
                p_ab_flag               IN	        hz_customer_profiles.attribute3%TYPE,
                p_status	              IN	        hz_cust_accounts.status%TYPE,
                p_customer_type         IN	        hz_cust_accounts.attribute18%TYPE,
                p_cust_template         IN	        varchar2,
--		p_aops_col_code		IN	hz_customer_profiles.collector_id%TYPE,
		            x_prof_class_modify   	OUT	NOCOPY	varchar2,
                x_prof_class_name      	OUT NOCOPY	hz_cust_profile_classes.name%TYPE,
                x_prof_class_id      	  OUT NOCOPY	hz_cust_profile_classes.profile_class_id%TYPE,
                x_retain_collect_cd 	  OUT	NOCOPY	varchar2,
                x_collector_code    	  OUT	NOCOPY	hz_customer_profiles.collector_id%TYPE,
                x_collector_name    	  OUT	NOCOPY	ar_collectors.name%TYPE,
                x_errbuf       		      OUT NOCOPY 	VARCHAR2,
                x_return_status      	  OUT NOCOPY 	VARCHAR2
		)  IS

        l_cust_account_id	       hz_cust_accounts.cust_account_id%TYPE;
        l_status		             hz_cust_accounts.status%TYPE;
        l_classification         varchar2(50);
        l_cust_template          varchar2(50);
        l_cust_type		           varchar2(50);
        l_profile_class          hz_cust_profile_classes.name%TYPE;
        l_collector_cd   	       varchar2(1);
        l_ab_flag                hz_customer_profiles.attribute3%TYPE;
        l_retain_collector_cd    varchar2(1);
        l_fixed_collector_cd     varchar2(100);
        l_fixed_collector_id     hz_customer_profiles.collector_id%TYPE;
        l_enabled                varchar2(1);
        l_existing_abf           varchar2(1);
        l_payment_term		       ra_terms.name%TYPE;
        l_party_id		           hz_cust_accounts.party_id%TYPE;
        l_existing_collect_id    hz_customer_profiles.collector_id%TYPE;
        l_customer_type          hz_cust_accounts.attribute18%TYPE;
        l_collector_name         ar_collectors.name%TYPE;


BEGIN
	x_return_status := 'S';

            BEGIN
                    select  cust_account_id, status, party_id , attribute18 into l_cust_account_id , l_status , l_party_id , l_customer_type
                    from    hz_cust_accounts
                    where   orig_system_reference = p_customer_osr;

                    select  nvl(hcp.attribute3,'N'), rat.name , collector_id into
                            l_existing_abf , l_payment_term , l_existing_collect_id
                    from    hz_customer_profiles hcp,
                            ra_terms  rat
                    where   hcp.status = 'A'
                    and	    hcp.cust_account_id= l_cust_account_id
                    and	    hcp.standard_terms    = rat.term_id
                    and	    site_use_id is null;

                    IF p_reactivated_flag = 'R'	AND l_status = 'I' THEN
                        l_classification := 'REACTIVE';

                        BEGIN
                              select  name into l_collector_name
                              from    ar_collectors
                              where   collector_id = l_existing_collect_id;
                        EXCEPTION
                           WHEN OTHERS THEN
                                     NULL;
                        END;

                        IF substr(l_collector_name,1,1) = '8' THEN
                          l_collector_cd := '8';
                        END IF;
                    ELSIF l_status = 'A' AND p_status = 'I' THEN
                        l_classification := 'DEACTIVE';
                    --    DBMS_OUTPUT.PUT_LINE('inside deactivate');
                        IF check_fin_parent(l_party_id) THEN
                                    x_prof_class_modify := 'N';
                                   -- DBMS_OUTPUT.PUT_LINE('inside check_fin_parent');
                                    return ;
							ELSE  /* Start Added by Theja Rajula for SOA 12c Upgrade 01/27/2018 */
                          l_ab_flag := 'N';
                        END IF; /* END Added by Theja Rajula for SOA 12c Upgrade 01/27/2018 */
                    ELSIF l_status = 'I' AND p_status = 'A' THEN
                            l_classification := 'REACTIVE';
                            BEGIN
                              select  name into l_collector_name
                              from    ar_collectors
                              where   collector_id = l_existing_collect_id;
                        EXCEPTION WHEN OTHERS THEN
                                     NULL;
                        END;

                        IF substr(l_collector_name,1,1) = '8' THEN
                          l_collector_cd := '8';
                          x_collector_name := l_collector_name;
                        END IF;
                    ELSIF l_status = 'A' AND nvl(p_status,l_status) = 'A'  AND p_ab_flag = 'Y' AND l_payment_term = 'IMMEDIATE' THEN
                            l_classification := 'NEW';
                    ELSE
                            -- No changes to profiles
                            x_prof_class_modify := 'N';
                            return ;
                    END IF;

            EXCEPTION
                    WHEN  NO_DATA_FOUND THEN
                          -- Reactive Case if record not found in CDH
                          IF p_reactivated_flag = 'R' THEN
                            l_classification := 'REACTIVE';
                          ELSE
                            l_classification := 'NEW';
                            l_cust_template  := p_cust_template;
                          END IF;
                    WHEN  OTHERS THEN
                       --   fnd_file.put_line(fnd_file.log, 'Error in check_fin_parent s' || sqlerrm );
                          x_errbuf := 'Error in check_fin_parents' || sqlerrm ;
                          x_return_status := 'E';
                          return ;
            END;

         l_cust_type := nvl(p_customer_type,l_customer_type);
        if l_classification <> 'DEACTIVE' THEN  /* Start Added by Theja Rajula for SOA 12c Upgrade 01/27/2018 */
            l_ab_flag   := nvl(p_ab_flag,l_existing_abf);
          else
             l_ab_flag   := 'N'; /* End Added by Theja Rajula for SOA 12c Upgrade 01/27/2018 */
        end if;

		IF l_ab_flag = 'Y' THEN
            select  TARGET_VALUE1, TARGET_VALUE2, TARGET_VALUE3, TARGET_VALUE4       INTO
                    l_profile_class , l_retain_collector_cd , l_fixed_collector_cd , l_enabled
            from    XX_FIN_TRANSLATEVALUES
            where   translate_id IN (
                    select  translate_id
                    from    XX_FIN_TRANSLATEDEFINITION
                    where   translation_name = 'XX_OD_CUST_PROF_CLASS_MAP' )
            and     source_value1 = l_classification
            and     source_value2 = l_cust_type
            and     source_value3 = l_ab_flag
                  and     nvl(source_value6,'Y') = 'Y'
                  and     nvl(source_value5,'SFA20') = nvl(l_cust_template,'SFA20') -- Added by 1/12/2018 Theja Rajula DSO Project 
            and     source_value7 = FND_GLOBAL.ORG_ID
            and     NVL(source_value4,'-1') = NVL(l_collector_cd,'-1') ;
        ELSE
            select  TARGET_VALUE1, TARGET_VALUE2, TARGET_VALUE3, TARGET_VALUE4       INTO
                    l_profile_class , l_retain_collector_cd , l_fixed_collector_cd , l_enabled
            from    XX_FIN_TRANSLATEVALUES
            where   translate_id IN (
                    select  translate_id
                    from    XX_FIN_TRANSLATEDEFINITION
                    where   translation_name = 'XX_OD_CUST_PROF_CLASS_MAP' )
            and     source_value1 = l_classification
            and     source_value2 = l_cust_type
            and     source_value3 = l_ab_flag
                  and     nvl(source_value6,'Y') = 'Y'
                  and     nvl(source_value5,'SFA') = nvl(l_cust_template,'SFA') 
            and     NVL(source_value4,'-1') = NVL(l_collector_cd,'-1') ;
        END IF;

	-- set the profile class ID
            select	profile_class_id into x_prof_class_id
              from	hz_cust_profile_classes hcpc
              where	name = l_profile_class;

            BEGIN
                IF l_fixed_collector_cd IS NOT NULL THEN
                    select  collector_id into l_fixed_collector_id
                    from    ar_collectors
                    where   name = l_fixed_collector_cd;
                END IF;
            EXCEPTION
              WHEN OTHERS THEN
               --NULL;
               --print exception here
               x_errbuf := ' Error in deriving collector code ' || SQLERRM;
            END;

	      x_prof_class_modify   	:= 'Y';
        x_prof_class_name      	:= l_profile_class;
        x_retain_collect_cd 	  := l_retain_collector_cd ;
        x_collector_code    	  := nvl(l_fixed_collector_id,l_existing_collect_id);


EXCEPTION
  WHEN NO_DATA_FOUND THEN
     --NULL;
     IF l_classification = 'NEW' THEN
         x_prof_class_modify := 'N';
         --When no data found, it seems this is a customer with CREDIT_CARD, hence
         x_prof_class_name := 'CREDIT_CARD';

         select profile_class_id
           into x_prof_class_id
           from hz_cust_profile_classes hcpc
          where name = 'CREDIT_CARD';

         x_retain_collect_cd := 'N';
         x_collector_code := null;
         x_collector_name := null;
      ELSE
         x_errbuf := ' Error in derive_prof_class_dtls ' || sqlerrm ;
         x_return_status := 'E';
      END IF;
  WHEN OTHERS THEN
   --fnd_file.put_line(fnd_file.log, ' Error in derive_prof_class_dtls ' || sqlerrm );
   x_errbuf := ' Error in derive_prof_class_dtls ' || sqlerrm ;
   x_return_status := 'E';
END derive_prof_class_dtls;


FUNCTION  check_fin_parent(
          p_party_id	        IN	hz_cust_accounts.party_id%TYPE
          )  return boolean IS
l_exists	varchar2(1);
BEGIN

	select 	'Y' into l_exists
	from  	hz_relationships
	where 	relationship_type = 'OD_FIN_HIER'
	and   	direction_code = 'P'
	and	status = 'A'
	and	subject_id = p_party_id
        and     sysdate between start_date and end_date
        AND     rownum = 1;

	return true;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		return false;
	WHEN OTHERS THEN
               -- DBMS_OUTPUT.PUT_LINE('ERROR IS ' || sqlerrm);
		RAISE;
END check_fin_parent;

procedure save_cust_profile (
                p_cust_account_id       IN            hz_cust_accounts.cust_account_id%TYPE,
                p_prof_class_id      	IN	      hz_cust_profile_classes.profile_class_id%TYPE,
                p_collector_id          IN            hz_customer_profiles.collector_id%TYPE,
                x_return_status         OUT NOCOPY    VARCHAR2,
                x_msg_count             OUT NOCOPY    NUMBER,
                x_msg_data              OUT NOCOPY    VARCHAR2 )
IS

l_cust_prof_rec       HZ_CUSTOMER_PROFILE_V2PUB.customer_profile_rec_type;
l_ovn                 HZ_CUSTOMER_PROFILES.object_version_number%TYPE;
l_cust_acct_prof_id   hz_customer_profiles.cust_account_profile_id%TYPE;
l_profile_class_id    hz_cust_profile_classes.profile_class_id%TYPE;
l_attribute3          hz_customer_profiles.attribute3%TYPE;
l_attribute4          hz_customer_profiles.attribute4%TYPE;

l_return_status   VARCHAR2(1) := null;
l_msg_count       NUMBER;
l_msg_data        VARCHAR2(2000) := null;
BEGIN

x_return_status := 'S';
l_cust_prof_rec.cust_account_id   := p_cust_account_id;
l_cust_prof_rec.profile_class_id := p_prof_class_id;
l_cust_prof_rec.collector_id  := p_collector_id;

  BEGIN
        select  object_version_number, cust_account_profile_id, profile_class_id, attribute3 , attribute4 into
                l_ovn , l_cust_acct_prof_id,l_profile_class_id , l_attribute3 , l_attribute4
        from    hz_customer_profiles
        where   cust_account_id = p_cust_account_id
	and     site_use_id is null
        and     status = 'A';

      IF l_profile_class_id = p_prof_class_id AND l_profile_class_id = 0 THEN
          update    hz_customer_profiles
          set       profile_class_id = -1
          where   cust_account_id = p_cust_account_id
          and     site_use_id is null
          and     status = 'A';
      END IF;

    l_cust_prof_rec.cust_account_profile_id   := l_cust_acct_prof_id;
    l_cust_prof_rec.attribute3                := l_attribute3;
    l_cust_prof_rec.attribute4                := l_attribute4;

    HZ_CUSTOMER_PROFILE_V2PUB.update_customer_profile (
    p_init_msg_list           => FND_API.G_TRUE,
    p_customer_profile_rec    => l_cust_prof_rec,
    p_object_version_number   => l_ovn,
    x_return_status  => x_return_status,
    x_msg_count  =>x_msg_count,
    x_msg_data =>x_msg_data
  );
  EXCEPTION WHEN NO_DATA_FOUND THEN

  HZ_CUSTOMER_PROFILE_V2PUB.create_customer_profile (
    p_init_msg_list           => FND_API.G_TRUE,
    p_customer_profile_rec    => l_cust_prof_rec,
    p_create_profile_amt      => FND_API.G_TRUE,
    x_cust_account_profile_id  => l_cust_acct_prof_id,
    x_return_status  => x_return_status,
    x_msg_count  =>x_msg_count,
    x_msg_data =>x_msg_data
  );

  END;

  IF x_return_status = 'S'  THEN
      DO_COPY_CUST_PROFILES(p_cust_account_profile_id  => l_cust_acct_prof_id,
                            p_cust_account_id => p_cust_account_id,
                            x_return_status => l_return_status,
                            x_msg_count => l_msg_count,
                            x_msg_data => l_msg_data);
    x_return_status  := l_return_status;
    x_msg_count      := l_msg_count;
    x_msg_data       := l_msg_data;
      IF (x_return_status = 'S') THEN
        COMMIT;
      END IF;

  END IF;

EXCEPTION WHEN OTHERS THEN
    x_return_status := 'E';
END save_cust_profile;

END XX_OD_CUST_PROF_CLASS_MAP_PKG;
/