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

import oracle.apps.ar.irec.accountDetails.server.InvoiceTableVORowImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jbo.server.ViewDefImpl;

public class DMTableVORowImpl extends InvoiceTableVORowImpl {

 public DMTableVORowImpl()
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

   protected static final int MAXATTRCONST = ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.server.InvoiceTableVO");
   public static final String RCS_ID = "$Header: DMTableVORowImpl.java 120.1 2003/06/27 13:11:25 yreddy noship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: DMTableVORowImpl.java 120.1 2003/06/27 13:11:25 yreddy noship $", "oracle.apps.ar.irec.accountDetails.server");


}
