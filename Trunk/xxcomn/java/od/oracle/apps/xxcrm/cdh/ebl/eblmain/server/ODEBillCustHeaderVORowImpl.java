package od.oracle.apps.xxcrm.cdh.ebl.eblmain.server;

/*
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        :  ODEBillCustHeaderVORowImpl                                 |
  -- | Description :                                                             |
  -- | This is the View Object for Customer Header Details                       |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |DRAFT 1A 15-JAN-2010 Devi Viswanathan     Initial draft version            |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |===========================================================================|
  -- | Subversion Info:                                                          |
  -- | $HeadURL: http://svn.na.odcorp.net/svn/od/common/trunk/xxcomn/java/od/oracle/apps/xxcrm/cdh/ebl/eblmain/server/ODEBillCustHeaderVORowImpl.java $                                                               |
  -- | $Rev: 101121 $                                                                   |
  -- | $Date: 2010-05-04 05:30:49 -0400 (Tue, 04 May 2010) $                                                                  |
  -- |                                                                           |
  -- +===========================================================================+
*/

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODEBillCustHeaderVORowImpl extends OAViewRowImpl 
{


  protected static final int CUSTOMERNAME = 0;
  protected static final int CUSTOMERNUMBER = 1;
  protected static final int AOPSNUMBER = 2;
  protected static final int CUSTACCOUNTID = 3;
  protected static final int CUSTDOCID = 4;
  protected static final int PARENTDOCID = 5;
  protected static final int DOCTYPE = 6;
  protected static final int PAYDOCIND = 7;
  protected static final int DELIVERYMETHOD = 8;
  protected static final int DIRECTDOC = 9;
  protected static final int STATUS = 10;
  protected static final int ISPARENT = 11;
  protected static final int PARTYID = 12;
  protected static final int PARTYNAME = 13;
  protected static final int PAYDOCINDDISP = 14;
  protected static final int STATUSCODE = 15;
  protected static final int DIRECTDOCDISP = 16;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODEBillCustHeaderVORowImpl()
  {
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
   * Gets the attribute value for the calculated attribute CustomerNumber
   */
  public String getCustomerNumber()
  {
    return (String)getAttributeInternal(CUSTOMERNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerNumber
   */
  public void setCustomerNumber(String value)
  {
    setAttributeInternal(CUSTOMERNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute AopsNumber
   */
  public String getAopsNumber()
  {
    return (String)getAttributeInternal(AOPSNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AopsNumber
   */
  public void setAopsNumber(String value)
  {
    setAttributeInternal(AOPSNUMBER, value);
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
   * Gets the attribute value for the calculated attribute CustDocId
   */
  public Number getCustDocId()
  {
    return (Number)getAttributeInternal(CUSTDOCID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustDocId
   */
  public void setCustDocId(Number value)
  {
    setAttributeInternal(CUSTDOCID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ParentDocId
   */
  public Number getParentDocId()
  {
    return (Number)getAttributeInternal(PARENTDOCID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ParentDocId
   */
  public void setParentDocId(Number value)
  {
    setAttributeInternal(PARENTDOCID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DocType
   */
  public String getDocType()
  {
    return (String)getAttributeInternal(DOCTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DocType
   */
  public void setDocType(String value)
  {
    setAttributeInternal(DOCTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PayDocInd
   */
  public String getPayDocInd()
  {
    return (String)getAttributeInternal(PAYDOCIND);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PayDocInd
   */
  public void setPayDocInd(String value)
  {
    setAttributeInternal(PAYDOCIND, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DeliveryMethod
   */
  public String getDeliveryMethod()
  {
    return (String)getAttributeInternal(DELIVERYMETHOD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DeliveryMethod
   */
  public void setDeliveryMethod(String value)
  {
    setAttributeInternal(DELIVERYMETHOD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DirectDoc
   */
  public String getDirectDoc()
  {
    return (String)getAttributeInternal(DIRECTDOC);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DirectDoc
   */
  public void setDirectDoc(String value)
  {
    setAttributeInternal(DIRECTDOC, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CUSTOMERNAME:
        return getCustomerName();
      case CUSTOMERNUMBER:
        return getCustomerNumber();
      case AOPSNUMBER:
        return getAopsNumber();
      case CUSTACCOUNTID:
        return getCustAccountId();
      case CUSTDOCID:
        return getCustDocId();
      case PARENTDOCID:
        return getParentDocId();
      case DOCTYPE:
        return getDocType();
      case PAYDOCIND:
        return getPayDocInd();
      case DELIVERYMETHOD:
        return getDeliveryMethod();
      case DIRECTDOC:
        return getDirectDoc();
      case STATUS:
        return getStatus();
      case ISPARENT:
        return getIsParent();
      case PARTYID:
        return getPartyId();
      case PARTYNAME:
        return getPartyName();
      case PAYDOCINDDISP:
        return getPayDocIndDisp();
      case STATUSCODE:
        return getStatusCode();
      case DIRECTDOCDISP:
        return getDirectDocDisp();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CUSTOMERNAME:
        setCustomerName((String)value);
        return;
      case CUSTOMERNUMBER:
        setCustomerNumber((String)value);
        return;
      case AOPSNUMBER:
        setAopsNumber((String)value);
        return;
      case CUSTACCOUNTID:
        setCustAccountId((Number)value);
        return;
      case CUSTDOCID:
        setCustDocId((Number)value);
        return;
      case PARENTDOCID:
        setParentDocId((Number)value);
        return;
      case DOCTYPE:
        setDocType((String)value);
        return;
      case PAYDOCIND:
        setPayDocInd((String)value);
        return;
      case DELIVERYMETHOD:
        setDeliveryMethod((String)value);
        return;
      case DIRECTDOC:
        setDirectDoc((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case ISPARENT:
        setIsParent((Number)value);
        return;
      case PARTYID:
        setPartyId((Number)value);
        return;
      case PARTYNAME:
        setPartyName((String)value);
        return;
      case PAYDOCINDDISP:
        setPayDocIndDisp((String)value);
        return;
      case STATUSCODE:
        setStatusCode((String)value);
        return;
      case DIRECTDOCDISP:
        setDirectDocDisp((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute IsParent
   */
  public Number getIsParent()
  {
    return (Number)getAttributeInternal(ISPARENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute IsParent
   */
  public void setIsParent(Number value)
  {
    setAttributeInternal(ISPARENT, value);
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
   * Gets the attribute value for the calculated attribute PartyName
   */
  public String getPartyName()
  {
    return (String)getAttributeInternal(PARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PartyName
   */
  public void setPartyName(String value)
  {
    setAttributeInternal(PARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PayDocIndDisp
   */
  public String getPayDocIndDisp()
  {
    return (String)getAttributeInternal(PAYDOCINDDISP);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PayDocIndDisp
   */
  public void setPayDocIndDisp(String value)
  {
    setAttributeInternal(PAYDOCINDDISP, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute StatusCode
   */
  public String getStatusCode()
  {
    return (String)getAttributeInternal(STATUSCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute StatusCode
   */
  public void setStatusCode(String value)
  {
    setAttributeInternal(STATUSCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DirectDocDisp
   */
  public String getDirectDocDisp()
  {
    return (String)getAttributeInternal(DIRECTDOCDISP);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DirectDocDisp
   */
  public void setDirectDocDisp(String value)
  {
    setAttributeInternal(DIRECTDOCDISP, value);
  }
}