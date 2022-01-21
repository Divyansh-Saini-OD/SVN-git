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

public class DEPTableVORowImpl extends InvoiceTableVORowImpl {

   protected static final int MAXATTRCONST = ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.server.InvoiceTableVO");
   public static final String RCS_ID = "$Header: DEPTableVORowImpl.java 120.1 2003/06/27 13:11:06 yreddy noship $";
   public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: DEPTableVORowImpl.java 120.1 2003/06/27 13:11:06 yreddy noship $", "oracle.apps.ar.irec.accountDetails.server");

 public DEPTableVORowImpl()
    {
    }

  /**
   * 
   * Gets the attribute value for the calculated attribute ShipToName
   */
  public String getShipToName()
  {
    return (String)getAttributeInternal("ShipToName");
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ShipToName
   */
  public void setShipToName(String value)
  {
    setAttributeInternal("ShipToName", value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ShipToId
   */
  public Number getShipToId()
  {
    return (Number)getAttributeInternal("ShipToId");
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ShipToId
   */
  public void setShipToId(Number value)
  {
    setAttributeInternal("ShipToId", value);
  }
}
