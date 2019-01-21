package oracle.apps.ar.irec.accountDetails.server;

/*----------------------------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327
 -- Script Location: $CUSTOM_JAVA_TOP/od/oracle/apps/xxfin/ar/irec/accountDetails/server
 -- Description: Considered R12 code and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013  1.0        Retrofitted for R12 Upgrade.
---------------------------------------------------------------------------*/

import oracle.apps.ar.irec.accountDetails.server.InvoiceTableVOImpl;
import oracle.apps.fnd.common.VersionInfo;

public class AllDebTrxTableVOImpl extends InvoiceTableVOImpl {

	public AllDebTrxTableVOImpl()
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

   public static final String RCS_ID = "$Header: AllDebTrxTableVOImpl.java 120.1.1 2006/07/13 12:06:49 abathini noship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: AllDebTrxTableVOImpl.java 120.1.1 2006/07/13 12:06:49 abathini noship $", "oracle.apps.ar.irec.accountDetails.server");


}
