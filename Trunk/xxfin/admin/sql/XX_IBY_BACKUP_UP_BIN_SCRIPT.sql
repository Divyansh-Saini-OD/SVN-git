SET SHOW OFF
SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON
SET SERVEROUTPUT ON

PROMPT Creating SQL Script XX_IBY_BACKUP_UP_BIN_SCRIPT.sql

PROMPT Program exits if the creation is not successful

WHENEVER SQLERROR CONTINUE

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                       WIPRO Technologies                          |
-- +===================================================================+
-- | Name        : Bin Ranges backup script and purge script           |
-- | RICE ID     : I0349   settlement                                  |
-- | Description : Bin Ranges backup script and purge script           |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======  ==========   ==================    =======================|
-- |1.0      27-JAN-2009  Rama Krishna K        Initial version        |
-- |                                            Defect #12949          |
-- +===================================================================+
declare
  Ln_rowcount NUMBER := 0;
begin
dbms_output.put_line('Bin Ranges Back Script Start ==>');
dbms_output.put_line('Taking backup of iby_pcard_bin_range table to xx_iby_pcard_bin_ranges table');

insert into xxfin.xx_iby_pcard_bin_ranges
select * from iby_pcard_bin_range;

select count(1)
into   Ln_rowcount
from   xxfin.xx_iby_pcard_bin_ranges;

dbms_output.put_line('BACKUP TABLE xx_iby_pcard_bin_ranges AS ROWS : ' || Ln_rowcount);

select count(1)
into   Ln_rowcount
from iby_pcard_bin_range;

dbms_output.put_line('DELIVERED BIN RANGE TABLE AS ROWS : ' || Ln_rowcount);

dbms_output.put_line('PURGING DATA IN DELIVERED TABLE IBY_PCARD_BIN_RANGE');

delete from iby_pcard_bin_range;

commit;

select count(1)
into   Ln_rowcount
from iby_pcard_bin_range;

dbms_output.put_line('Purged data in IBY_PCARD_BIN_RANGE. Rows purged : ' || Ln_rowcount);
end;

/
show err
