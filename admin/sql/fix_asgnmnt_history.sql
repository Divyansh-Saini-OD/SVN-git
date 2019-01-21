set serverout on size 1000000
spool fix_asgnmnt_history.lst

declare
  cursor c_history is
  select p.party_site_id, 
         p.orig_system_reference, 
         p.creation_date, 
         e.initial_asgn_dt, 
         greatest(g1.start_date, '28-DEC-2008') ps_fiscal_start, 
         g.start_date  asgn_fiscal_start 
  from   (select party_site_id, min(start_date_active) initial_asgn_dt
          from   apps.XX_TM_NAM_TERR_HISTORY_DTLS 
          group by party_site_id
          having min(start_date_active) > '28-DEC-2008'
          ) e,
         apps.gl_periods g,
         apps.hz_party_sites p,
         apps.gl_periods g1       
  where  g.period_type = '41'
    and  trunc(e.initial_asgn_dt) between g.start_date and g.end_date
    and  p.party_site_id = e.party_site_id
    and  g1.period_type = '41'
    and  trunc(p.creation_date) between g1.start_date and g1.end_date
    and  g.start_date <> g1.start_date;

  l_sel_count number := 0;
  l_upd_count number := 0;
begin
  select count(distinct p.party_site_id)
  into   l_sel_count
  from   (select party_site_id, min(start_date_active) initial_asgn_dt
          from   apps.XX_TM_NAM_TERR_HISTORY_DTLS 
          group by party_site_id
          having min(start_date_active) > '28-DEC-2008'
          ) e,
         apps.gl_periods g,
         apps.hz_party_sites p,
         apps.gl_periods g1       
  where  g.period_type = '41'
    and  trunc(e.initial_asgn_dt) between g.start_date and g.end_date
    and  p.party_site_id = e.party_site_id
    and  g1.period_type = '41'
    and  trunc(p.creation_date) between g1.start_date and g1.end_date
    and  g.start_date <> g1.start_date;

  dbms_output.put_line('Records Selected = ' || l_sel_count);

  for history_rec in c_history loop

    update xxcrm.XX_TM_NAM_TERR_HISTORY_DTLS
    set    start_date_active = greatest(history_rec.ps_fiscal_start, '28-DEC-2008')
    where  party_site_id     = history_rec.party_site_id
      and  start_date_active = history_rec.initial_asgn_dt;
    
    l_upd_count := l_upd_count + sql%rowcount;

  end loop;

  dbms_output.put_line('Records Updated = ' || l_upd_count);

  commit;

  select count(distinct p.party_site_id)
  into   l_sel_count
  from   (select party_site_id, min(start_date_active) initial_asgn_dt
          from   apps.XX_TM_NAM_TERR_HISTORY_DTLS 
          group by party_site_id
          having min(start_date_active) > '28-DEC-2008'
          ) e,
         apps.gl_periods g,
         apps.hz_party_sites p,
         apps.gl_periods g1       
  where  g.period_type = '41'
    and  trunc(e.initial_asgn_dt) between g.start_date and g.end_date
    and  p.party_site_id = e.party_site_id
    and  g1.period_type = '41'
    and  trunc(p.creation_date) between g1.start_date and g1.end_date
    and  g.start_date <> g1.start_date;

  dbms_output.put_line('Records Left After Update = ' || l_sel_count);

end;
/

spool off