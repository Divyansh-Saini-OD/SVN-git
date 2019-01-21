-- $Id$
-- $Rev$
-- $HeadURL$
-- $Author$
-- $Date$

alter table xxcrm.XX_JTF_TERR_QUALIFIERS_INT add created_by       number;
alter table xxcrm.XX_JTF_TERR_QUALIFIERS_INT add creation_date    date   default sysdate;
alter table xxcrm.XX_JTF_TERR_QUALIFIERS_INT add last_updated_by  number;
alter table xxcrm.XX_JTF_TERR_QUALIFIERS_INT add last_update_date date   default sysdate;

-- The program that creates records in XX_JTF_TERR_QUALIFIERS_INT hasn't
-- been modified to use the "who" columns yet so no need to initialize
-- created_by and creation_date.


update xxcrm.XX_JTF_TERR_QUALIFIERS_INT
   set creation_date    = to_date('01-JAN-1980','DD-MON-YYYY'),
       last_update_date = to_date('01-JAN-1980','DD-MON-YYYY');

commit;
