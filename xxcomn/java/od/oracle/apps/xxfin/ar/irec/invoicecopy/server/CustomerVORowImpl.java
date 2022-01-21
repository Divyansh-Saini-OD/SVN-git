// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// | Providge Consulting                                                                  |
// +======================================================================================+
// |  Class:         CustomerVORowImpl.java                                               |
// |  Description:   This class is view object row implementation class for CustomerVO    |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       26-JUN-2007   BLooman            Initial version                            |
// |                                                                                      |
// +======================================================================================+
package od.oracle.apps.xxfin.ar.irec.invoicecopy.server; 

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class CustomerVORowImpl extends OAViewRowImpl 
{
  public static final String RCS_ID="$Header$ CustomerVORowImpl.java 115.10 2007/07/18 03:00:00 bjl noship ";
  public static final boolean RCS_ID_RECORDED =
        VersionInfo.recordClassVersion(RCS_ID, "od.oracle.apps.xxfin.ar.irec.invoicecopy.server");

  protected static final int PARTYID = 0;


  protected static final int CUSTOMERNAME = 1;
  protected static final int CUSTACCOUNTID = 2;
  protected static final int ACCOUNTNUMBER = 3;
  protected static final int CUSTOMERTYPE = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public CustomerVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PartyId
   */
  public Number getPartyId()
  {
    return (Number)getAttributeInternal(PARTYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyId
   */
  public void setPartyId(Number value)
  {
    setAttributeInternal(PARTYID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerName
   */
  public String getCustomerName()
  {
    return (String)getAttributeInternal(CUSTOMERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerName
   */
  public void setCustomerName(String value)
  {
    setAttributeInternal(CUSTOMERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustAccountId
   */
  public Number getCustAccountId()
  {
    return (Number)getAttributeInternal(CUSTACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustAccountId
   */
  public void setCustAccountId(Number value)
  {
    setAttributeInternal(CUSTACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AccountNumber
   */
  public String getAccountNumber()
  {
    return (String)getAttributeInternal(ACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AccountNumber
   */
  public void setAccountNumber(String value)
  {
    setAttributeInternal(ACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerType
   */
  public String getCustomerType()
  {
    return (String)getAttributeInternal(CUSTOMERTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerType
   */
  public void setCustomerType(String value)
  {
    setAttributeInternal(CUSTOMERTYPE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PARTYID:
        return getPartyId();
      case CUSTOMERNAME:
        return getCustomerName();
      case CUSTACCOUNTID:
        return getCustAccountId();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case CUSTOMERTYPE:
        return getCustomerType();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case PARTYID:
        setPartyId((Number)value);
        return;
      case CUSTOMERNAME:
        setCustomerName((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case CUSTOMERTYPE:
        setCustomerType((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}