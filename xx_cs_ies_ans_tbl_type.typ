SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name  :    xx_cs_ies_ans_tbl_type                                 |
-- | Description  : This script creates object type 		       |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           	Remarks                |
-- |=======   ==========  =============    	=======================|
-- |DRAFT 1A 23-APR-10  Rajeswari Jagarlamudi   Initial draft version  |
-- |                                                                   |
-- |                                                                   |
-- +===================================================================+

--DROP TYPE xx_cs_ies_ans_tbl_type
--/

SET TERM ON
PROMPT Creating Record type xx_cs_ies_ans_rec_type 
SET TERM OFF

create or replace type xx_cs_ies_ans_rec_type as object 
                        (
                          question_id   number,
                          ans_text      varchar2(3000) 
                        );


/

SET TERM ON
PROMPT Object Type created successfully
SET TERM OFF

SET TERM ON
PROMPT Creating tbl type xx_cs_ies_ans_tbl_type
SET TERM OFF


create or replace TYPE xx_cs_ies_ans_tbl_type AS TABLE OF xx_cs_ies_ans_rec_type;

/

SET TERM ON
PROMPT Type created successfully
SET TERM OFF

SHOW ERROR


