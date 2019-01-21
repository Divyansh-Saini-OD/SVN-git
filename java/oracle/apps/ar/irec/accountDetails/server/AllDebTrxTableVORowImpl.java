package oracle.apps.ar.irec.accountDetails.server;

/*----------------------------------------------------------
 -- Author: Sridevi Kondoju
 -- Component Id: E1327
 -- Script Location: $CUSTOM_JAVA_TOP/od/oracle/apps/xxfin/ar/irec/accountDetails/server
 -- Description: Considered R12 code and added custom code.
 -- History:
 -- Name            Date         Version    Description
 -- -----           -----        -------    -----------
 -- Sridevi Kondoju 27-Jul-2013   1.0    Retrofitted for R12 Upgrade.
----------------------------------------------------------*/

import oracle.apps.ar.irec.accountDetails.server.InvoiceTableVORowImpl;
import oracle.apps.fnd.common.VersionInfo;
import oracle.jbo.server.ViewDefImpl;
import oracle.jbo.domain.Number; 


public class AllDebTrxTableVORowImpl extends InvoiceTableVORowImpl {

public AllDebTrxTableVORowImpl()
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
   public static final String RCS_ID = "$Header: AllDebTrxTableVORowImpl.java 120.1.1 2006/07/13 12:07:12 abathini noship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: AllDebTrxTableVORowImpl.java 120.1.1 2006/07/13 12:07:12 abathini noship $", "oracle.apps.ar.irec.accountDetails.server");


}
