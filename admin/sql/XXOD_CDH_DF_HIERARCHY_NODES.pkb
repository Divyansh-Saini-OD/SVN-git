/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_DF_HIERARCHY_NODES.pkb                           |
 |Description                                                             |
 |              Package body for the datafix that end dates               |
 |              the corrupted hierarchy nodes                             |
 |                                                                        |
 |  Date          Author              Comments                            |
 |  15-JAN-2009   Sreedhar Mohan      Initial version                     |
 |  12-NOV-2015   Havish Kasina       Removed the Schema References as per|
 |                                    R12.2 Retrofit Changes              |
 |======================================================================= */

create or replace package body XXOD_CDH_DF_HIERARCHY_NODES
as
  procedure main(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_child_id        IN          number   , 
                    p_parent_id       IN          number   ,
		            p_start_date      IN          varchar2 ,
		            p_creation_date   IN          varchar2
                  )
  is
  begin
    update  HZ_HIERARCHY_NODES
     set    effective_end_date = (sysdate-1),
            status = 'I',
	    last_updated_by = fnd_global.user_id,
	    last_update_date = sysdate
    where   child_id = p_child_id
      and   parent_id = p_parent_id
      and   trunc(effective_start_date) = trunc(to_date(p_start_date, 'DD-MON-YYYY'))
      and   trunc(creation_date) = trunc(to_date(p_creation_date, 'DD-MON-YYYY'))
      and   level_number=2;
    
    commit;
  exception
    when others then
      rollback;
  end main;
end XXOD_CDH_DF_HIERARCHY_NODES;
/
