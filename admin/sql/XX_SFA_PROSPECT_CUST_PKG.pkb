SET SHOW          OFF;
SET VERIFY        OFF;
SET ECHO          OFF;
SET TAB           OFF;
SET FEEDBACK      OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_SFA_PROSPECT_CUST_PKG AS
 -- +===============================================================================+
 -- |                  Office Depot - Project Simplify                              |
 -- |                       WIPRO Technologies                                      |
 -- +===============================================================================+
 -- | Name        : XX_SFA_PROSPECT_CUST_PKG                                        |
 -- | Description : Adding Prospect/Customer column to Lead and Opportunity pages   |
 -- |                                                                               |
 -- |$HeadURL$                                                                    |
 -- |$Rev    : $                                                                    |
 -- |$Date   : $                                                                    |
 -- |                                                                               |
 -- |Change Record:                                                                 |
 -- |===============                                                                |
 -- |Version   Date          Author              Remarks                            |
 -- |=======   ==========   =============        ===================================|
 -- |Draft     13-JAN-2010  Annapoorani Rajaguru Defect 2264 Add Prospect/Customer  |
 -- |                                            Column                             |
 -- +===============================================================================+

     FUNCTION XX_PROSPECT_CUST_FUNC(
                                    p_party_id HZ_CUST_ACCOUNTS.party_id%type
                                   )
     RETURN VARCHAR2
     IS
             lc_prosCust VARCHAR2(20);
             ln_count NUMBER;
     BEGIN
             SELECT count(1)
             INTO ln_count
             FROM hz_cust_accounts
             WHERE party_id = p_party_id ;

             IF NVL(ln_count,0) = 0
             THEN
                  lc_prosCust := 'Prospect';
             ELSE
                  lc_prosCust := 'Customer';
             END IF;
             RETURN lc_prosCust;
     EXCEPTION 
            WHEN OTHERS THEN
                 RETURN 'Error';
     END XX_PROSPECT_CUST_FUNC;

END XX_SFA_PROSPECT_CUST_PKG;

/
SHOW ERRORS;







