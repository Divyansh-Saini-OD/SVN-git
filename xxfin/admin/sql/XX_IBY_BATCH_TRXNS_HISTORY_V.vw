-- +==============================================================================+
-- |                                  Office Depot                                |
-- |                                                                              |
-- +==============================================================================+
-- | Script Name: XX_IBY_BATCH_TRXNS_HISTORY_V.vw                                 |
-- | View Name  : xx_iby_batch_trxns_history_v                                    |
-- | RICE #     : E3084 - EBS_Database_Roles                                      |
-- | Description: View created to hide senstive data in table                     |
-- |                IBY_BATCH_TRXNS_HISTORY                                       |
-- |                                                                              |
-- |                  Columns excluded: ixaccount, ixswipe, ixps2000              |
-- |                                                                              |
-- |Change Record:                                                                |
-- |===============                                                               |
-- |Version  Date         Author                 Comments                         |
-- |=======  ===========  =====================  =================================|
-- |  1.0    16-MAR-2014  R.Aldridge             Initial version                  |
-- |  1.1    21-OCT-2015  P.Suresh               Added token_flag and cc code.    |
-- |  1.2    04-JAN-2017  Avinash B		 R12.2 GSCC Changes               |
-- |                                                                              |
-- +==============================================================================+
CREATE OR REPLACE FORCE VIEW XX_IBY_BATCH_TRXNS_HISTORY_V
AS
SELECT pre1
      ,pre2
      ,pre3
      ,ixrecordtype
      ,ixreserved2
      ,ixreserved3
      ,ixactioncode
      ,ixreserved5
      ,ixmessagetype
      ,ixreserved7
      ,ixstorenumber
      ,ixregisternumber
      ,ixtransactiontype
      ,ixreserved11
      ,ixreserved12
      ,ixexpdate
      ,ixamount
      ,ixinvoice
      ,ixreserved18
      ,ixreserved19
      ,ixreserved20
      ,ixoptions
      ,ixbankuserdata
      ,ixreserved23
      ,ixreserved24
      ,ixissuenumber
      ,ixtotalsalestaxamount
      ,ixtotalsalestaxcollind
      ,ixreserved28
      ,ixreserved29
      ,ixreserved30
      ,ixreserved31
      ,ixreserved32
      ,ixreserved33
      ,ixreceiptnumber
      ,ixreserved35
      ,ixreserved36
      ,ixauthorizationnumber
      ,ixreserved38
      ,ixreserved39
      ,ixreserved40
      ,ixreserved41
      ,ixreserved42
      ,ixreserved43
      ,ixreference
      ,ixreserved46
      ,ixipaymentbatchnumber
      ,ixreserved48
      ,ixreserved49
      ,ixdate
      ,ixtime
      ,ixreserved52
      ,ixreserved53
      ,ixreserved54
      ,ixreserved55
      ,ixreserved56
      ,ixreserved57
      ,ixreserved58
      ,ixreserved59
      ,ixcustomerreferenceid
      ,ixnationaltaxcollindicator
      ,ixnationaltaxamount
      ,ixothertaxamount
      ,ixdiscountamount
      ,ixshippingamount
      ,ixtaxableamount
      ,ixdutyamount
      ,ixshipfromzipcode
      ,ixshiptocompany
      ,ixshiptoname
      ,ixshiptostreet
      ,ixshiptocity
      ,ixshiptostate
      ,ixshiptocountry
      ,ixshiptozipcode
      ,ixpurchasername
      ,ixorderdate
      ,ixmerchantvatnumber
      ,ixcustomervatnumber
      ,ixvatinvoice
      ,ixvatamount
      ,ixvatrate
      ,ixmerchandiseshipped
      ,ixcustcountrycode
      ,ixcustaccountno
      ,ixcostcenter
      ,ixdesktoplocation
      ,ixreleasenumber
      ,ixoriginalinvoiceno
      ,ixothertaxamount2
      ,ixothertaxamount3
      ,ixmisccharge
      ,ixccnumber
      ,last_update_date
      ,last_updated_by
      ,creation_date
      ,created_by
      ,last_update_login
      ,ixinstrsubtype
      ,attribute1
      ,attribute2
      ,attribute3
      ,attribute4
      ,attribute5
      ,attribute6
      ,attribute7
      ,attribute8
      ,attribute9
      ,attribute10
      ,attribute11
      ,attribute12
      ,attribute13
      ,attribute14
      ,attribute15
      ,ixmerchantnumber
      ,ixsettlementdate
      ,ixtransnumber
      ,ixrecptnumber
      ,org_id
      ,is_deposit
      ,is_custom_refund
      ,is_amex
      ,process_indicator
      ,attribute16
      ,attribute17
      ,attribute18
      ,attribute19
      ,attribute20
      ,attribute21
      ,attribute22
      ,attribute23
      ,attribute24
      ,attribute25
      ,attribute26
      ,attribute27
      ,attribute28
      ,attribute29
      ,attribute30
      ,order_payment_id
	  ,ixcreditcardcode
	  ,ixtokenflag
 FROM xx_iby_batch_trxns_history;
