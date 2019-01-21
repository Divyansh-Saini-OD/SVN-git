select *
from   dba_sequences
where sequence_name like 'XX_TM_NAM_TERR%'; 

SHOW ERRORS;
EXIT;
