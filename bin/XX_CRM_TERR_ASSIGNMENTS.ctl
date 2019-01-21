-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

load data

into table xx_jtf_terr_resource_xref

replace

when territory_name != 'Territory ID'

fields terminated by ',' optionally enclosed by '"'
trailing nullcols

(
territory_name,
rep_id,
employee_number   "lpad(:employee_number,6,'0')",
employee_name,
creation_date     sysdate,
created_by        "-1",
last_update_date  sysdate,
last_updated_by   "-1",
region_name       constant "OD_NORTH_AMERICA"
)
