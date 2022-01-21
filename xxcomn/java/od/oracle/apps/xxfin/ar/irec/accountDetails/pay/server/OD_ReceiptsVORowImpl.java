package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;

public class OD_ReceiptsVORowImpl extends OAViewRowImpl
{

  protected static final int CUSTOMERID = 0;
  protected static final int CASHRECEIPTID = 1;
  protected static final int CUSTOMERNAME = 2;
  protected static final int ACCOUNTNUMBER = 3;
  protected static final int RECEIPTNUMBER = 4;
  protected static final int RECEIPTDATE = 5;
  protected static final int AMOUNT = 6;
  protected static final int ORGID = 7;
  protected static final int CREATEDBY = 8;
  protected static final int USERNAME = 9;
  protected static final int CREATIONDATE = 10;
  protected static final int CREATIONTIME = 11;
  protected static final int REMITBANKNAME = 12;
  protected static final int MASKEDACCOUNTNUMBER = 13;
  protected static final int RECEIPTDATEDISP = 14;
  protected static final int AMOUNTDISP = 15;
  protected static final int MASKEDBANKACCOUNTNUMBER = 16;
  protected static final int CUSTOMERCARENUMBER = 17;
  protected static final int PAYMENTNUMBER = 18;

    public OD_ReceiptsVORowImpl()
    {
    }

    public Number getCustomerId()
    {
        return (Number)getAttributeInternal(0);
    }

    public void setCustomerId(Number value)
    {
        setAttributeInternal(0, value);
    }

    public Number getCashReceiptId()
    {
        return (Number)getAttributeInternal(1);
    }

    public void setCashReceiptId(Number value)
    {
        setAttributeInternal(1, value);
    }

    public String getCustomerName()
    {
        return (String)getAttributeInternal(2);
    }

    public void setCustomerName(String value)
    {
        setAttributeInternal(2, value);
    }

    public String getAccountNumber()
    {
        return (String)getAttributeInternal(3);
    }

    public void setAccountNumber(String value)
    {
        setAttributeInternal(3, value);
    }

    public String getReceiptNumber()
    {
        return (String)getAttributeInternal(4);
    }

    public void setReceiptNumber(String value)
    {
        setAttributeInternal(4, value);
    }

    public Date getReceiptDate()
    {
        return (Date)getAttributeInternal(5);
    }

    public void setReceiptDate(Date value)
    {
        setAttributeInternal(5, value);
    }

    public Number getAmount()
    {
        return (Number)getAttributeInternal(6);
    }

    public void setAmount(Number value)
    {
        setAttributeInternal(6, value);
    }

    public Number getOrgId()
    {
        return (Number)getAttributeInternal(7);
    }

    public void setOrgId(Number value)
    {
        setAttributeInternal(7, value);
    }

    public Number getCreatedBy()
    {
        return (Number)getAttributeInternal(8);
    }

    public void setCreatedBy(Number value)
    {
        setAttributeInternal(8, value);
    }

    public String getUserName()
    {
        return (String)getAttributeInternal(9);
    }

    public void setUserName(String value)
    {
        setAttributeInternal(9, value);
    }

    public Date getCreationDate()
    {
        return (Date)getAttributeInternal(10);
    }

    public void setCreationDate(Date value)
    {
        setAttributeInternal(10, value);
    }

    public String getCreationTime()
    {
        return (String)getAttributeInternal(11);
    }

    public void setCreationTime(String value)
    {
        setAttributeInternal(11, value);
    }

    public String getRemitBankName()
    {
        return (String)getAttributeInternal(12);
    }

    public void setRemitBankName(String value)
    {
        setAttributeInternal(12, value);
    }

    protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef)
        throws Exception
    {
    switch (index)
      {
      case CUSTOMERID:
        return getCustomerId();
      case CASHRECEIPTID:
        return getCashReceiptId();
      case CUSTOMERNAME:
        return getCustomerName();
      case ACCOUNTNUMBER:
        return getAccountNumber();
      case RECEIPTNUMBER:
        return getReceiptNumber();
      case RECEIPTDATE:
        return getReceiptDate();
      case AMOUNT:
        return getAmount();
      case ORGID:
        return getOrgId();
      case CREATEDBY:
        return getCreatedBy();
      case USERNAME:
        return getUserName();
      case CREATIONDATE:
        return getCreationDate();
      case CREATIONTIME:
        return getCreationTime();
      case REMITBANKNAME:
        return getRemitBankName();
      case MASKEDACCOUNTNUMBER:
        return getMaskedAccountNumber();
      case RECEIPTDATEDISP:
        return getReceiptDateDisp();
      case AMOUNTDISP:
        return getAmountDisp();
      case MASKEDBANKACCOUNTNUMBER:
        return getMaskedBankAccountNumber();
      case CUSTOMERCARENUMBER:
        return getCustomerCareNumber();
      case PAYMENTNUMBER:
        return getPaymentNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
    }

    protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef)
        throws Exception
    {
    switch (index)
      {
      case CUSTOMERID:
        setCustomerId((Number)value);
        return;
      case CASHRECEIPTID:
        setCashReceiptId((Number)value);
        return;
      case CUSTOMERNAME:
        setCustomerName((String)value);
        return;
      case ACCOUNTNUMBER:
        setAccountNumber((String)value);
        return;
      case RECEIPTNUMBER:
        setReceiptNumber((String)value);
        return;
      case RECEIPTDATE:
        setReceiptDate((Date)value);
        return;
      case AMOUNT:
        setAmount((Number)value);
        return;
      case ORGID:
        setOrgId((Number)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case USERNAME:
        setUserName((String)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case CREATIONTIME:
        setCreationTime((String)value);
        return;
      case REMITBANKNAME:
        setRemitBankName((String)value);
        return;
      case MASKEDACCOUNTNUMBER:
        setMaskedAccountNumber((String)value);
        return;
      case RECEIPTDATEDISP:
        setReceiptDateDisp((Date)value);
        return;
      case AMOUNTDISP:
        setAmountDisp((String)value);
        return;
      case MASKEDBANKACCOUNTNUMBER:
        setMaskedBankAccountNumber((String)value);
        return;
      case CUSTOMERCARENUMBER:
        setCustomerCareNumber((String)value);
        return;
      case PAYMENTNUMBER:
        setPaymentNumber((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
    }

    public String getMaskedAccountNumber()
    {
        return (String)getAttributeInternal(13);
    }

    public void setMaskedAccountNumber(String value)
    {
        setAttributeInternal(13, value);
    }

    public Date getReceiptDateDisp()
    {
        return (Date)getAttributeInternal(14);
    }

    public void setReceiptDateDisp(Date value)
    {
        setAttributeInternal(14, value);
    }

    public String getAmountDisp()
    {
        return (String)getAttributeInternal(15);
    }

    public void setAmountDisp(String value)
    {
        setAttributeInternal(15, value);
    }

    public String getMaskedBankAccountNumber()
    {
        return (String)getAttributeInternal(16);
    }

    public void setMaskedBankAccountNumber(String value)
    {
        setAttributeInternal(16, value);
    }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomerCareNumber
   */
  public String getCustomerCareNumber()
  {
    return (String)getAttributeInternal(CUSTOMERCARENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomerCareNumber
   */
  public void setCustomerCareNumber(String value)
  {
    setAttributeInternal(CUSTOMERCARENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PaymentNumber
   */
  public String getPaymentNumber()
  {
    return (String)getAttributeInternal(PAYMENTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PaymentNumber
   */
  public void setPaymentNumber(String value)
  {
    setAttributeInternal(PAYMENTNUMBER, value);
  }



}
