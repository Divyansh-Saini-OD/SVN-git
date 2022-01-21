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
 -- Vasu Raparla    16-Aug-2016  1.1        Retrofitted for R12.2.5 Upgrade
---------------------------------------------------------------------------*/

import com.sun.java.util.collections.Vector;
import oracle.apps.ar.irec.accountDetails.server.ArPaymentSchedulesVEOImpl;
import oracle.apps.ar.irec.accountDetails.server.InvoiceTableVORowImpl;
import oracle.apps.ar.irec.accountDetails.server.TransactionTableVORowImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jbo.RowIterator;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewDefImpl;

public class CMTableVORowImpl extends InvoiceTableVORowImpl {

   protected static final int MAXATTRCONST = ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.server.InvoiceTableVO");
   public static final String RCS_ID = "$Header: CMTableVORowImpl.java 120.5 2009/12/11 12:47:45 nkanchan ship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CMTableVORowImpl.java 120.5 2009/12/11 12:47:45 nkanchan ship $", "oracle.apps.ar.irec.accountDetails.server");
   private boolean isQueryExecuted = false;
   private String sApplTrxDetailsClass = null;
   private String sAppliedCustomerTrxId = null;
   private Number nAppliedTermsSeqNumber = null;

    public CMTableVORowImpl()
    {
        isQueryExecuted = false;
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



   public ArPaymentSchedulesVEOImpl getArPaymentSchedulesVEO() {
      return (ArPaymentSchedulesVEOImpl)this.getEntity(0);
   }

   public RowIterator getRaCustomerTrxView() {
      return (RowIterator)this.getAttributeInternal("RaCustomerTrxView");
   }

   public String getIrSalesOrderInt() {
      return this.getIrSalesOrderUtility(this.getIRSalesOrderByCustomerTrxId1());
   }

   public void setIrSalesOrderInt(String var1) {
      this.setAttributeInternal("IrSalesOrderInt", var1);
   }

   public RowIterator getIRSalesOrderByCustomerTrxId1() {
      return (RowIterator)this.getAttributeInternal("IRSalesOrderByCustomerTrxId1");
   }

   public ArPaymentSchedulesVEOImpl getArPaymentSchedulesV() {
      return (ArPaymentSchedulesVEOImpl)this.getEntity(0);
   }

   public String getIrCMDetails() {
      return (String)this.getAttributeInternal("IrCMDetails");
   }

   public void setIrCMDetails(String var1) {
      this.setAttributeInternal("IrCMDetails", var1);
   }

   public String getIrSalesOrder() {
      return (String)this.getAttributeInternal("IrSalesOrder");
   }

   public void setIrSalesOrder(String var1) {
      this.setAttributeInternal("IrSalesOrder", var1);
   }

   public String getArStatusLookupType() {
      return (String)this.getAttributeInternal("ArStatusLookupType");
   }

   public void setArStatusLookupType(String var1) {
      this.setAttributeInternal("ArStatusLookupType", var1);
   }

   public String getArLookupCodeStatusMeaning() {
      return (String)this.getAttributeInternal("ArLookupCodeStatusMeaning");
   }

   public void setArLookupCodeStatusMeaning(String var1) {
      this.setAttributeInternal("ArLookupCodeStatusMeaning", var1);
   }

   public String getArLookupCodeStatusMeaning1() {
      return (String)this.getAttributeInternal("ArLookupCodeStatusMeaning1");
   }

   public void setArLookupCodeStatusMeaning1(String var1) {
      this.setAttributeInternal("ArLookupCodeStatusMeaning1", var1);
   }

   public Number getCountAppliedToTrx() {
      return (Number)this.getAttributeInternal("CountAppliedToTrx");
   }

   public String getMultiple() {
      return (String)this.getAttributeInternal("Multiple");
   }

   public String getAppliedToTrxSelection() {
      Number var1 = this.getCountAppliedToTrx();
      if(null != var1 && 1 == var1.compareTo(1)) {
         return "Multiple";
      } else {
         String var2 = this.getShowTrxNumberLink();
         return "N".equals(var2)?"NoTrxNumberLink":"AppliedToTrxNumber";
      }
   }

   public String getAppliedToTrxNumber() {
      return (String)this.getAttributeInternal("AppliedToTrxNumber");
   }

   public String getApplTrxDetailsRegionCode() {
      return TransactionTableVORowImpl.getStaticTransactionDetailsRegionCode(this, this.getApplTrxDetailsClass());
   }

   public String getApplTrxDetailsClass() {
      Number var1 = this.getCountAppliedToTrx();
      if(null != var1 && 1 == var1.compareTo(1)) {
         return null;
      } else if(this.isQueryExecuted) {
         return this.sApplTrxDetailsClass;
      } else {
         Vector var2 = this.executeCMApplicationDetailsQuery(this.getCustomerTrxId());
         this.sApplTrxDetailsClass = (String)var2.get(0);
         this.sAppliedCustomerTrxId = (String)var2.get(1);
         this.nAppliedTermsSeqNumber = (Number)var2.get(2);
         this.isQueryExecuted = true;
         return this.sApplTrxDetailsClass;
      }
   }

   public String getAppliedCustomerTrxId() {
      Number var1 = this.getCountAppliedToTrx();
      if(null != var1 && 1 == var1.compareTo(1)) {
         return null;
      } else if(this.isQueryExecuted) {
         return this.sAppliedCustomerTrxId;
      } else {
         Vector var2 = this.executeCMApplicationDetailsQuery(this.getCustomerTrxId());
         this.sApplTrxDetailsClass = (String)var2.get(0);
         this.sAppliedCustomerTrxId = (String)var2.get(1);
         this.nAppliedTermsSeqNumber = (Number)var2.get(2);
         this.isQueryExecuted = true;
         return this.sAppliedCustomerTrxId;
      }
   }

   public Number getAppliedTermsSeqNumber() {
      Number var1 = this.getCountAppliedToTrx();
      if(null != var1 && 1 == var1.compareTo(1)) {
         return null;
      } else if(this.isQueryExecuted) {
         return this.nAppliedTermsSeqNumber;
      } else {
         Vector var2 = this.executeCMApplicationDetailsQuery(this.getCustomerTrxId());
         this.sApplTrxDetailsClass = (String)var2.get(0);
         this.sAppliedCustomerTrxId = (String)var2.get(1);
         this.nAppliedTermsSeqNumber = (Number)var2.get(2);
         this.isQueryExecuted = true;
         return this.nAppliedTermsSeqNumber;
      }
   }

   public String getShowTrxNumberLink() {
      return (String)this.getAttributeInternal("ShowTrxNumberLink");
   }

   public void setShowTrxNumberLink(String var1) {
      this.setAttributeInternal("ShowTrxNumberLink", var1);
   }

}
