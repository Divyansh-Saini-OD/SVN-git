 CREATE OR REPLACE PACKAGE XX_SFA_PROSPECT_CUST_PKG AS
 -- +===============================================================================+
 -- |                  Office Depot - Project Simplify                              |
 -- |                       WIPRO Technologies                                      |
 -- +===============================================================================+
 -- | Name        : XX_SFA_PROSPECT_CUST_PKG                                        |
 -- | Description : Adding Prospect/Customer column to Lead and Opportunity pages   |
 -- |                                                                               |
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
     RETURN VARCHAR2;

END XX_SFA_PROSPECT_CUST_PKG;
/
SHOW ERRORS;