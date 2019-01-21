SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

/* =======================================================================+
 |                       Copyright (c) 2008 Office Depot                  |
 |                       Boca Raton, FL, USA                              |
 |                       All rights reserved.                             |
 +========================================================================+
 |File Name     XXOD_CDH_DF_HIERARCHY_NODES.pks                           |
 |Description                                                             |
 |              Package specification for the datafix that end dates      |
 |              the corrupted hierarchy nodes                             |
 |                                                                        |
 |  Date          Author              Comments                            |
 |  15-JAN-2009   Sreedhar Mohan      Initial version                     |
 |======================================================================= */

create or replace package XXOD_CDH_DF_HIERARCHY_NODES
as
  procedure main(
                    p_errbuf          OUT NOCOPY  varchar2 ,
                    p_retcode         OUT NOCOPY  varchar2 ,
                    p_child_id        IN          number   , 
                    p_parent_id       IN          number   ,
		    p_start_date      IN          varchar2 ,
		    p_creation_date   IN          varchar2
                  );
end XXOD_CDH_DF_HIERARCHY_NODES;
/
