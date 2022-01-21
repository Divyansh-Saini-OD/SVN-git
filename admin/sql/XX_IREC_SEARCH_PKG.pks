create or replace
PACKAGE XX_IREC_SEARCH_PKG AS

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- +===================================================================+
-- | Name :  XX_IREC_SEARCH_PKG                                        |
-- |                                                                   |
-- | Rice id : E2052                                                   |
-- |                                                                   |
-- | Description :This package is used to assist with iReceivables     |
-- |              customer and transaction searches for R1.2 CR 619.   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date          Author              Remarks                |
-- |=======   ==========   =============        =======================|
-- |Draft1A   30-NOV-2009  Bushrod Thomas       Initial version        |
-- +===================================================================+


  TYPE SOFT_SEARCH_TYPE_TBL IS TABLE OF XX_ARI_SOFT_SEARCH_TYPE;


-- +===================================================================+
-- | Name : INSERT_TRX_SEARCH                                          |
-- |                                                                   |
-- | Description : Adds rows to XX_ARI_TRX_SEARCH_GT for use in        |
-- |               multi-transaction search on Account Details page    |
-- |                                                                   |
-- |               p_transactions should be a linefeed delimited       |
-- |               list of trx_numbers                                 |
-- |                                                                   |
-- |               p_purge tells the proc whether or not to delete     |
-- |               existing rows from the table before inserting       |
-- |                                                                   |
-- |               x_success indicates if there was a problem or not.  |
-- +===================================================================+
  PROCEDURE INSERT_TRX_SEARCH (
      p_transactions IN  VARCHAR2
     ,p_purge        IN  VARCHAR2 := 'Y'
     ,x_success      OUT VARCHAR2
  );

-- +===================================================================+
-- | Name : GET_SOFT_HEADERS                                           |
-- |                                                                   |
-- | Description : Returns customer's soft header labels in out parms  |
-- |                                                                   |
-- |               p_customer_id is the custom to get soft headers for |
-- |                                                                   |
-- |               x_department,x_po,x_release,x_desktop will contain  |
-- |               the customer's soft headers                         |
-- |                                                                   |
-- |               x_success indicates if there was a problem.         |
-- +===================================================================+
  PROCEDURE GET_SOFT_HEADERS (
      p_customer_id  IN  VARCHAR2
     ,x_department   OUT VARCHAR2
     ,x_po           OUT VARCHAR2
     ,x_release      OUT VARCHAR2
     ,x_desktop      OUT VARCHAR2
     ,x_success      OUT VARCHAR2
  );
  
-- +===================================================================+
-- | Name : SOFT_HEADERS_SEARCH_TBL                                    |
-- |                                                                   |
-- | Description : Returns a table of the logged-in customer's         |
-- |               soft header labels along with their search type     |
-- |               lookup codes (see ar_lookups where lookup_type=     |
-- |               'ARI_CUSTOMER_SEARCH_TYPE'.                         |
-- |                                                                   |
-- |               This result table is then joined in iRec Customer   |
-- |               Search page for ODTransactionSearchTypeVO           |
-- |                                                                   |
-- +===================================================================+
  FUNCTION SOFT_HEADERS_SEARCH_TBL
  RETURN SOFT_SEARCH_TYPE_TBL PIPELINED;  

END XX_IREC_SEARCH_PKG;
/
