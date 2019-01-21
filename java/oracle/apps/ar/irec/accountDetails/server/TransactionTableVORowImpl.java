package oracle.apps.ar.irec.accountDetails.server;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327 and E2052
 -- Script Location: $CUSTOM_JAVA_TOP/oracle/apps/ar/irec/accountDetails/server
 -- Description: Considered R12 code version and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013  1.0        Retrofitted for R12 Upgrade.
 -- Vasu Raparla    16-Aug-2016  1.1        Retrofitted for R12.2.5 Upgrade.
---------------------------------------------------------------------------*/

import oracle.apps.ar.irec.accountDetails.server.InvoiceTableVORowImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jbo.RowIterator;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.ViewDefImpl;

public class TransactionTableVORowImpl extends InvoiceTableVORowImpl {

    public static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.server.InvoiceTableVO");
    protected static final int IRSALESORDERBYCUSTOMERTRXID1 = MAXATTRCONST;
    public static final String RCS_ID = "$Header: TransactionTableVORowImpl.java 120.3 2011/02/23 06:11:19 nkanchan ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: TransactionTableVORowImpl.java 120.3 2011/02/23 06:11:19 nkanchan ship $", "oracle.apps.ar.irec.accountDetails.server");

   //Start -R12 upgrade retrofit
public TransactionTableVORowImpl()
    {
    }

    public String getShipToName()
    {
        return (String)getAttributeInternal("ShipToName");
    }

    public void setShipToName(String s)
    {
        setAttributeInternal("ShipToName", s);
    }

    public Number getShipToId()
    {
        return (Number)getAttributeInternal("ShipToId");
    }

    public void setShipToId(Number s)
    {
        setAttributeInternal("ShipToId", s);
    }
   //End -R12 upgrade retrofit
   public RowIterator getIRSalesOrderByCustomerTrxId1() {
      return (RowIterator)this.getAttributeInternal("IRSalesOrderByCustomerTrxId1");
   }

   public String getIrSalesOrder1() {
      return this.getIrSalesOrderUtility(this.getIRSalesOrderByCustomerTrxId1());
   }

   public String getCashReceiptId() {
      return (String)this.getAttributeInternal("CashReceiptId");
   }

   public void setCashReceiptId(String var1) {
      this.setAttributeInternal("CashReceiptId", var1);
   }

   public String getTransactionDetailsRegionCode() {
      return getStaticTransactionDetailsRegionCode(this, (String)this.getAttributeInternal("Class1"));
   }

   public static String getStaticTransactionDetailsRegionCode(InvoiceTableVORowImpl var0, String var1) {
      String var2 = null;
      if(!"INV".equals(var1) && !"GUAR".equals(var1) && !"CB".equals(var1) && !"DM".equals(var1) && !"DEP".equals(var1)) {
         if("CM".equals(var1)) {
            var2 = "ARITEMPCMDETAILSPAGE";
         } else if("PMT".equals(var1)) {
            var2 = "ARI_PAYMENT_DETAILS_PAGE";
         } else if("REQ".equals(var1)) {
            var2 = "ARITEMPCMREQUESTDETAILSPAGE";
         }
      } else {
         var2 = "ARITRANSACTIONDETAILSPAGE";
      }

      return var2;
   }

   public void setTransactionDetailsRegionCode(String var1) {
      this.setAttributeInternal("TransactionDetailsRegionCode", var1);
   }

   public String getAcctDtlsViewTrxType() {
      return (String)this.getAttributeInternal("AcctDtlsViewTrxType");
   }

   public Number getAmountInClaim() {
      return (Number)this.getAttributeInternal("AmountInClaim");
   }

   public Number getOnAccountAmount() {
      return (Number)this.getAttributeInternal("OnAccountAmount");
   }

   public String getAmountInClaimFormatted() {
      return this.getAmountFormatted(this, this.getAmountInClaim(), this.getInvoiceCurrencyCode());
   }

   public String getAmountOnAccountFormatted() {
      return this.getAmountFormatted(this, this.getOnAccountAmount(), this.getInvoiceCurrencyCode());
   }

}
