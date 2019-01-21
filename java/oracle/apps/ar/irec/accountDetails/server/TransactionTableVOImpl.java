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

public class TransactionTableVOImpl extends InvoiceTableVOImpl {

public TransactionTableVOImpl()
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
   public static final String RCS_ID = "$Header: TransactionTableVOImpl.java 120.1 2005/08/04 11:37:25 vgundlap noship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: TransactionTableVOImpl.java 120.1 2005/08/04 11:37:25 vgundlap noship $", "oracle.apps.ar.irec.accountDetails.server");


}
