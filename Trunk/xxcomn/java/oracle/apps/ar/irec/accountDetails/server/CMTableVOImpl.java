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
---------------------------------------------------------------------------*/

import oracle.apps.ar.irec.accountDetails.server.InvoiceTableVOImpl;
import oracle.apps.fnd.common.VersionInfo;

public class CMTableVOImpl extends InvoiceTableVOImpl {

   public static final String RCS_ID = "$Header: CMTableVOImpl.java 120.1 2005/08/04 11:38:11 vgundlap noship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: CMTableVOImpl.java 120.1 2005/08/04 11:38:11 vgundlap noship $", "oracle.apps.ar.irec.accountDetails.server");


 public CMTableVOImpl()
    {
    }

    protected boolean containsBindVariablesForShipTo()
    {
      return true;
    }

    protected boolean containsConsolidatedBillColumn()
    {
      return true;
    }

    protected boolean containsSoftColumns()
    {
      return true;
    }

   protected String statusForWhereClause(String var1) {
      String var2 = new String("");
      if(null != var1) {
         if(var1.equals("CLOSED")) {
            var2 = "CL";
         } else if(var1.equals("OPEN")) {
            var2 = "OP";
         }
      }

      return var2;
   }

   protected String amountRemainingClause(String var1) {
      String var2 = new String("");
      if(null != var1) {
         if(var1.equals("PAST_DUE_INVOICE")) {
            var2 = "AND ( amount_due_remaining > 0 ) ";
         } else if(var1.equals("CL")) {
            var2 = "AND ( amount_due_remaining = 0 ) ";
         } else if(var1.equals("OP")) {
            var2 = "AND ( amount_due_remaining <> 0 ) ";
         }
      }

      return var2;
   }

   protected int handleKeywordExtraClauses(StringBuffer var1, String var2, String var3, int var4) {
      var1.append(" OR ( EXISTS ( SELECT rctl.trx_number from ra_customer_trx rctl ");
      var1.append(" WHERE customer_trx_id = rctl.customer_trx_id ");
      var1.append(" AND rctl.trx_number = :" + var4++ + " ) )");
      this.setWhereClause(var1.append(var3).toString());
      --var4;
      --var4;
      this.setWhereClauseParam(var4, var2);
      --var4;
      return var4;
   }

}
