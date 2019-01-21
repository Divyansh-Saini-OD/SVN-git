create or replace package body XX_CRM_INACTIVATE_PROSPECTS
as
  --Procedure for logging debug log
  PROCEDURE log ( 
                  p_debug_msg          IN  VARCHAR2 
                )
  IS
  
    ln_login             PLS_INTEGER  := FND_GLOBAL.Login_Id;
    ln_user_id           PLS_INTEGER  := FND_GLOBAL.User_Id;
  
  BEGIN
  
      XX_COM_ERROR_LOG_PUB.log_error
        (
         p_return_code             => FND_API.G_RET_STS_SUCCESS
        ,p_msg_count               => 1
        ,p_application_name        => 'XXCRM'
        ,p_program_type            => 'DEBUG'              --------index exists on program_type
        ,p_attribute15             => 'XX_CRM_INACTIVATE_PROSPECTS'          --------index exists on attribute15
        ,p_program_id              => 0                    
        ,p_module_name             => 'CDH'                --------index exists on module_name
        ,p_error_message           => p_debug_msg
        ,p_error_message_severity  => 'LOG'
        ,p_error_status            => 'ACTIVE'
        ,p_created_by              => ln_user_id
        ,p_last_updated_by         => ln_user_id
        ,p_last_update_login       => ln_login
        );
  
  END log;

  procedure set_context( errbuf       OUT NOCOPY VARCHAR2
                       , retcode      OUT NOCOPY VARCHAR2
				       , p_debug      IN         VARCHAR2
  )
  as
  l_user_id                       number;
  l_responsibility_id             number;
  l_responsibility_appl_id        number;
  
  begin
	
	if p_debug = 'Y' then
	  log('set_context(+)');
	end if;
	
    select user_id,
           responsibility_id,
           responsibility_application_id
    into   l_user_id,                      
           l_responsibility_id,            
           l_responsibility_appl_id
      from fnd_user_resp_groups 
     where user_id=(select user_id 
                      from fnd_user 
                     where user_name='ODCDH')
     and   responsibility_id=(select responsibility_id 
                                from FND_RESPONSIBILITY 
                               where responsibility_key = 'XX_US_CNV_CDH_CONVERSION');
    FND_GLOBAL.apps_initialize(
                         l_user_id,
                         l_responsibility_id,
                         l_responsibility_appl_id
                       );

	
	if p_debug = 'Y' then
	  log('set_context(-)');
	end if;					   
					   
  exception
    when others then
      log('Exception in initializing : ' || SQLERRM);
      errbuf := SQLERRM;
  end set_context;
    
  procedure create_temp_table (errbuf       OUT NOCOPY VARCHAR2
                             , retcode      OUT NOCOPY VARCHAR2
				             , p_debug      IN         VARCHAR2)
  as
    l_sql varchar2(2000);
  begin  
  
  if p_debug = 'Y' then
	  log('create_temp_table(+)');
  end if;
  
  EXECUTE IMMEDIATE 'DROP table xxcrm.XX_CRM_INACTIVED_PROSPECTS';
  
  if p_debug = 'Y' then
	  log('Before Create Table');
  end if;  
  
  l_sql := 'create table xxcrm.XX_CRM_INACTIVED_PROSPECTS
                      STORAGE ( INITIAL 10K)
                       as    
                       Select /*+ index(p XX_HZ_PARTIES_N18) PARALLEL(P,5)*/
                             party_id
                        FROM hz_parties p
                       WHERE party_id > 100
                         AND attribute13 = ''PROSPECT''
                         AND creation_date between TO_DATE (fnd_profile.value(''XX_CRM_PROSPECT_INACTIVE_FROM_DATE''), ''DD-MON-YYYY HH24:MI:SS'') 
                                               and TO_DATE (fnd_profile.value(''XX_CRM_PROSPECT_INACTIVE_TO_DATE''), ''DD-MON-YYYY HH24:MI:SS'')
                         AND party_type = ''ORGANIZATION''
                         AND status = ''A''
                         AND NOT EXISTS (SELECT 1
                                           FROM hz_cust_accounts_all hca
                                          WHERE hca.party_id = p.party_id)
                         AND NOT EXISTS (SELECT 1
                                           From Xxod_Hz_Summary
                                          WHERE summary_id in (nvl(FND_PROFILE.VALUE(''XX_CRM_PROSPECT_INACTIVE_SUMMARY_ID''),29189)) AND party_id = p.party_id)';
  
  log('Create table SQL: ' || l_sql);
  
  EXECUTE IMMEDIATE l_sql;

  if p_debug = 'Y' then
	  log('Before Create Index');
  end if;
  
  --EXECUTE IMMEDIATE 'DROP INDEX XXCRM.XX_CRM_INACTIVED_PROSPECTS_N1';  
  
  EXECUTE IMMEDIATE 'CREATE INDEX XXCRM.XX_CRM_INACTIVED_PROSPECTS_N1 ON XXCRM.XX_CRM_INACTIVED_PROSPECTS (PARTY_ID) tablespace APPS_TS_TX_IDX_AR_16M parallel 8';

  if p_debug = 'Y' then
  	  log('Before Alter Index');
  end if;
  
  EXECUTE IMMEDIATE 'alter index XXCRM.XX_CRM_INACTIVED_PROSPECTS_N1 noparallel';										  
                    
  if p_debug = 'Y' then
  	  log('create_temp_table(-)');
  end if;
  
  exception
   when others then
     log('Exception in XX_CRM_INACTIVATE_PROSPECTS.create_temp_table:' || SQLERRM);
  end create_temp_table;

  procedure inactivate_party_site_uses (
                                    errbuf       OUT NOCOPY VARCHAR2
                                  , retcode      OUT NOCOPY VARCHAR2
				                  , p_batch_size IN         NUMBER   DEFAULT 10000
				                  , p_debug      IN         VARCHAR2)
  as		
  
  cursor c_party_site_uses
  is  
     SELECT party_site_use_id
     FROM   hz_party_site_uses
    WHERE   party_site_id IN (
                 SELECT party_site_id
                   FROM hz_party_sites
                  WHERE party_id IN (
                                     SELECT party_id
                                       FROM XX_CRM_INACTIVED_PROSPECTS));

  TYPE site_uses_cur_tbl_type IS TABLE OF c_party_site_uses%ROWTYPE INDEX BY BINARY_INTEGER;	
  site_uses_cur_tbl  site_uses_cur_tbl_type;
  
  l_bulk_limit         NUMBER := p_batch_size;
  l_records_updated    NUMBER := 0;
  l_commit_flag        VARCHAR2(1); 
  k                    NUMBER := 1 ;
  lockcounter          NUMBER := 0 ;
  l_status             VARCHAR2(1);
  
  begin  
  
  if p_debug = 'Y' then
  	  log('inactivate_party_site_uses(+)');
  end if;
  
  k := 1;

  OPEN c_party_site_uses;
  LOOP
    FETCH c_party_site_uses BULK COLLECT INTO site_uses_cur_tbl LIMIT l_bulk_limit;
    IF site_uses_cur_tbl.COUNT = 0 THEN
      EXIT;
    END IF;
  
  
    log('...executing bulk update for batch '|| k) ;
           
    FOR ln_counter IN site_uses_cur_tbl.FIRST .. site_uses_cur_tbl.LAST        
    LOOP
    
       BEGIN
           --log('...locking site-use: '|| site_uses_cur_tbl(ln_counter).party_site_use_id ||' from batch '|| k );
		   
           SELECT status into l_status 
           FROM hz_party_site_uses 
           WHERE party_site_use_id  = site_uses_cur_tbl(ln_counter).party_site_use_id 
           FOR UPDATE WAIT 5;

           UPDATE hz_party_site_uses
              SET status = 'I'
            WHERE party_site_use_id = site_uses_cur_tbl(ln_counter).party_site_use_id;
    
           l_records_updated := l_records_updated + SQL%ROWCOUNT;   
    
       EXCEPTION
       WHEN OTHERS THEN 
           lockcounter := lockcounter + 1 ;       
           log( 'Exception in updating hz_party_site_uses: ' || SQLERRM);
       END;
    END LOOP ;  
  
    COMMIT;
    log( '...Committed batch: '|| k);     
    k := k + 1 ;
   
  END LOOP; --moving onto next batch
  
  if p_debug = 'Y' then
  	  log('inactivate_party_site_uses(-)');
  end if;

  exception
   when others then
     log('Exception in XX_CRM_INACTIVATE_PROSPECTS.inactivate_party_site_uses:' || SQLERRM);
  end inactivate_party_site_uses;

  procedure inactivate_party_sites (
                                    errbuf       OUT NOCOPY VARCHAR2
                                  , retcode      OUT NOCOPY VARCHAR2
				                  , p_batch_size IN         NUMBER   DEFAULT 10000
				                  , p_debug      IN         VARCHAR2)
  as								  
  cursor c_party_sites
  is
     SELECT party_site_id
     FROM   hz_party_sites
    WHERE   party_id IN (SELECT party_id
                           FROM XX_CRM_INACTIVED_PROSPECTS);  

  TYPE sites_cur_tbl_type IS TABLE OF c_party_sites%ROWTYPE INDEX BY BINARY_INTEGER;	
  sites_cur_tbl  sites_cur_tbl_type;

  l_bulk_limit         NUMBER := p_batch_size;
  l_records_updated    NUMBER := 0;
  l_commit_flag        VARCHAR2(1); 
  k                    NUMBER := 1 ;
  lockcounter          NUMBER := 0 ;
  l_status             VARCHAR2(1);
  
  begin  
  
  if p_debug = 'Y' then
  	  log('inactivate_party_sites(+)');
  end if;

  
  k := 1;

  OPEN c_party_sites;
  LOOP
    FETCH c_party_sites BULK COLLECT INTO sites_cur_tbl LIMIT l_bulk_limit;
    IF sites_cur_tbl.COUNT = 0 THEN
      EXIT;
    END IF;
  
  
    log('...executing bulk update for batch '|| k) ;
           
    FOR ln_counter IN sites_cur_tbl.FIRST .. sites_cur_tbl.LAST        
    LOOP
    
       BEGIN
           --log('...locking sites: '|| sites_cur_tbl(ln_counter).party_site_id ||' from batch '|| k) ;

           SELECT status into l_status 
           FROM hz_party_sites 
           WHERE party_site_id  = sites_cur_tbl(ln_counter).party_site_id 
           FOR UPDATE WAIT 5;
		   
           UPDATE hz_party_sites
              SET status = 'I'
            WHERE party_site_id = sites_cur_tbl(ln_counter).party_site_id;
    
           l_records_updated := l_records_updated + SQL%ROWCOUNT;   
    
       EXCEPTION
       WHEN OTHERS THEN 
           lockcounter := lockcounter + 1 ;       
           log( 'Exception in updating hz_party_sites: ' || SQLERRM);
       END;
    END LOOP ;  
  
    COMMIT;
    log( '...Committed batch: '|| k);     
    k := k + 1 ;
   
  END LOOP; --moving onto next batch

  if p_debug = 'Y' then
  	  log('inactivate_party_sites(-)');
  end if;
  
  exception
   when others then
     log('Exception in XX_CRM_INACTIVATE_PROSPECTS.inactivate_party_sites:' || SQLERRM);
  end inactivate_party_sites;  
  
  procedure inactivate_parties (
                                    errbuf       OUT NOCOPY VARCHAR2
                                  , retcode      OUT NOCOPY VARCHAR2
				                  , p_batch_size IN         NUMBER   DEFAULT 10000
				                  , p_debug      IN         VARCHAR2)
  as								  
  cursor c_parties
  is
   SELECT party_id
     FROM hz_parties
    WHERE party_id IN (SELECT party_id
                         FROM XX_CRM_INACTIVED_PROSPECTS);  
						 
  TYPE parties_tbl_type IS TABLE OF c_parties%ROWTYPE INDEX BY BINARY_INTEGER;	
  parties_tbl  parties_tbl_type;

  l_bulk_limit         NUMBER := p_batch_size;
  l_records_updated    NUMBER := 0;
  l_commit_flag        VARCHAR2(1); 
  k                    NUMBER := 1 ;
  lockcounter          NUMBER := 0 ;
  l_status             VARCHAR2(1);
  
  begin  
  
  if p_debug = 'Y' then
  	  log('inactivate_parties(+)');
  end if;

  k := 1;

  OPEN c_parties;
  LOOP
    FETCH c_parties BULK COLLECT INTO parties_tbl LIMIT l_bulk_limit;
    IF parties_tbl.COUNT = 0 THEN
      EXIT;
    END IF;
  
  
    log('...executing bulk update for batch '|| k) ;
           
    FOR ln_counter IN parties_tbl.FIRST .. parties_tbl.LAST        
    LOOP
    
       BEGIN
           --log('...locking parties: '|| parties_tbl(ln_counter).party_id ||' from batch '|| k) ;
		   
           SELECT status into l_status 
           FROM hz_parties 
           WHERE party_id  = parties_tbl(ln_counter).party_id 
           FOR UPDATE WAIT 5;
		   
           UPDATE hz_parties
              SET status = 'I'
            WHERE party_id = parties_tbl(ln_counter).party_id;
    
           l_records_updated := l_records_updated + SQL%ROWCOUNT;   
    
       EXCEPTION
       WHEN OTHERS THEN 
           lockcounter := lockcounter + 1 ;       
           log( 'Exception in updating hz_parties: ' || SQLERRM);
       END;
    END LOOP ;  
  
    COMMIT;
    log( '...Committed batch: '|| k);     
    k := k + 1 ;
   
  END LOOP; --moving onto next batch
 
  if p_debug = 'Y' then
  	  log('inactivate_parties(+)');
  end if;
 
  exception
   when others then
     log('Exception in XX_CRM_INACTIVATE_PROSPECTS.inactivate_parties:' || SQLERRM);
  end inactivate_parties;  

  procedure main (
                   errbuf       OUT NOCOPY VARCHAR2
                 , retcode      OUT NOCOPY VARCHAR2
				 , p_batch_size IN         NUMBER   DEFAULT 10000
				 , p_debug      IN         VARCHAR2 DEFAULT 'Y'
				 )
  as
  
  begin  
  
    if p_debug = 'Y' then
	  log('In Main Start: ' || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
	end if;
	
	set_context ( errbuf, retcode, p_debug);
	
    if p_debug = 'Y' then
		  log('In Main Before Create_Temp_Table: ' || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
    end if;

    create_temp_table(errbuf, retcode, p_debug);
	
    if p_debug = 'Y' then
		  log('In Main Before inactivate party site use: ' || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
    end if;
    
	inactivate_party_site_uses(errbuf, retcode, p_batch_size, p_debug);
	
    if p_debug = 'Y' then
		  log('In Main Before inactivate party sites: ' || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
    end if;
    
	inactivate_party_sites (errbuf, retcode, p_batch_size, p_debug);

    if p_debug = 'Y' then
		  log('In Main Before inactivate parties: ' || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
    end if;
    
	inactivate_parties(errbuf, retcode, p_batch_size, p_debug);

	if p_debug = 'Y' then
	  log('In Main End: ' || TO_CHAR (SYSDATE, 'DD-MON-RRRR HH24:MI:SS'));
	end if;
	
  exception
   when others then
     log('Exception in XX_CRM_INACTIVATE_PROSPECTS.main:' || SQLERRM);
  end main;
  
end XX_CRM_INACTIVATE_PROSPECTS;
/
  