CREATE OR REPLACE
PACKAGE XX_FIN_RELS_CREDIT_UPLOAD_PKG AS 

-- +========================================================================+
-- |                  Office Depot - Project Simplify                       |
-- |                       Oracle AMS                                       |
-- +========================================================================+
-- | Name        : XX_FIN_RELS_CREDIT_UPLOAD_PKG                            |
-- | Description : 1) Bulk import OD_FIN_HIER Relationships and credit Limit|
-- |                  into Oracle.                                          |
-- |                                                                        |
-- | RICE : E3056                                                           |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version   Date          Author              Remarks                     |
-- |=======  ==========   ==================    ============================|
-- |1.0      05-MAY-2013  Dheeraj V            Initial version, QC 22804    |
-- +========================================================================+

  FUNCTION create_rel
  (
    p_parent_party_number IN hz_parties.party_number%TYPE,
    p_relationship_type IN hz_relationships.relationship_code%TYPE,
    p_child_party_number IN hz_parties.party_number%TYPE,
    p_start_date IN VARCHAR2,
    p_end_date IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  FUNCTION remove_rel
  (
    p_parent_party_number IN hz_parties.party_number%TYPE,
    p_relationship_type IN hz_relationships.relationship_code%TYPE,
    p_child_party_number IN hz_parties.party_number%TYPE,
    p_end_date IN VARCHAR2
  )
  RETURN VARCHAR2;
  
  FUNCTION credit_update
  (
    p_account_number IN hz_cust_accounts.account_number%TYPE,
    p_credit_limit IN hz_cust_profile_amts.overall_credit_limit%TYPE,
    p_currency_code IN hz_cust_profile_amts.currency_code%TYPE  
  )
  RETURN VARCHAR2;
  
END XX_FIN_RELS_CREDIT_UPLOAD_PKG;
/