SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;


CREATE OR REPLACE PACKAGE XX_CDH_PARTY_REPT
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
----------------------------
--Declaring Variables
----------------------------
P_PARTY_NUMBER  VARCHAR2(30);
P_INACT         VARCHAR2(30);
P_ACCT          VARCHAR2(30);
P_PARTY         VARCHAR2(30);
P_FIRST_NAME    VARCHAR2(200);
P_LAST_NAME     VARCHAR2(200);
P_TITLE         VARCHAR2(200);
V_CLAUSE_PERSON VARCHAR2(2000) := 'person_first_name,person_last_name,person_title';
V_CLAUSE_ORG    VARCHAR2(2000) := 'organization_name,NULL,NULL';

-- +===================================================================+
-- | Name  : GET_WHERE_CLAUSE                                          |
-- |                                                                   |
-- | Description: This is the public function                          |
-- |                                                                   |
-- +===================================================================+
FUNCTION get_where_clause(p_party_type VARCHAR2) 
RETURN VARCHAR2;

END XX_CDH_PARTY_REPT;
/
SHOW ERRORS;
EXIT;