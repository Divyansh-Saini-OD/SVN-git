SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_PARTY_REPT
-- +===================================================================================+
-- |                  Office Depot - Project Simplify                                  |
-- |      Oracle NAIO/WIPRO//Office Depot/Consulting Organization                      |
-- +===================================================================================+
-- |                                                                                   |
-- | Name             :  XX_CDH_PARTY_REPT                                             |
-- |                                                                                   |
-- | Description      :                                                                |
-- |                                                                                   |
-- | This package contains the following sub programs:                                 |
-- | =================================================                                 |
-- |Type         Name                    Description                                   |
-- |=========    ===============         ==============================================|
-- |FUNCTION     Get_Where_Clause        This is the public function                   |
-- |                                                                                   |
-- |Change Record:                                                                     |
-- |===============                                                                    |
-- |Version   Date        Author                       Remarks                         |
-- |=======   ==========  ====================         ================================|
-- |Draft 1a  18-Jul-08   Abhradip Ghosh               Initial draft version           |
-- +===================================================================================+
AS

-- +===================================================================+
-- | Name  : GET_WHERE_CLAUSE                                          |
-- |                                                                   |
-- | Description: This is the public function                          |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_where_clause(p_party_type VARCHAR2) 
RETURN VARCHAR2
IS
BEGIN
   
   HZ_COMMON_PUB.disable_cont_source_security;
   
   IF TRIM(UPPER(p_party_type)) = 'PERSON' THEN
      p_first_name := SUBSTR(v_clause_person,1,INSTR(v_clause_person,',',1,1)-1);
      p_last_name  := SUBSTR(v_clause_person,INSTR(v_clause_person,',',1,1)+1,(INSTR(v_clause_person,',',1,2))-(INSTR(v_clause_person,',',1,1)+1));
      p_title      := SUBSTR(v_clause_person,INSTR(v_clause_person,',',1,2)+1);   
      RETURN 'HZ_PERSON_PROFILES';
   ELSE 
      p_first_name := SUBSTR(v_clause_org,1,INSTR(v_clause_org,',',1,1)-1);
      p_last_name  := SUBSTR(v_clause_org,INSTR(v_clause_org,',',1,1)+1,(INSTR(v_clause_org,',',1,2))-(INSTR(v_clause_org,',',1,1)+1));
      p_title      := SUBSTR(v_clause_org,INSTR(v_clause_org,',',1,2)+1);
      RETURN 'HZ_ORGANIZATION_PROFILES';
   END IF;   
EXCEPTION
WHEN OTHERS THEN
    RETURN 'Error'||SQLERRM;
END;

END XX_CDH_PARTY_REPT;
/
SHOW ERRORS;
EXIT;