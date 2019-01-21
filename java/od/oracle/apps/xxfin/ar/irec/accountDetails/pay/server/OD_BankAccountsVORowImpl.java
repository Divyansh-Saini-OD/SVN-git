package od.oracle.apps.xxfin.ar.irec.accountDetails.pay.server;

import oracle.apps.ar.irec.accountDetails.pay.server.BankAccountsVORowImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.ViewDefImpl;

public class OD_BankAccountsVORowImpl extends BankAccountsVORowImpl
{

  protected static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.pay.server.BankAccountsVO");;
  protected static final int CUSTOMACCOUNTHOLDERNAME = MAXATTRCONST;
  protected static final int CUSTOMACCOUNTTYPE = MAXATTRCONST + 1;
  protected static final int CUSTOMEMAILADDRESS = MAXATTRCONST + 2;
    public OD_BankAccountsVORowImpl()
    {
    }

    public String getBankAccountNumMasked()
    {
        return (String)getAttributeInternal("BankAccountNumMasked");
    }

    public void setBankAccountNumMasked(String value)
    {
        setAttributeInternal("BankAccountNumMasked", value);
    }

    public String getAccountHolder()
    {
        return (String)getAttributeInternal("AccountHolder");
    }

    public void setAccountHolder(String value)
    {
        setAttributeInternal("AccountHolder", value);
    }

    public Number getBankAccountId()
    {
        return (Number)getAttributeInternal("BankAccountId");
    }

    public void setBankAccountId(Number value)
    {
        setAttributeInternal("BankAccountId", value);
    }

    public String getAccountNumber()
    {
        return (String)getAttributeInternal("AccountNumber");
    }

    public void setAccountNumber(String value)
    {
        setAttributeInternal("AccountNumber", value);
    }

    public String getAccountType()
    {
        return (String)getAttributeInternal("AccountType");
    }

    public void setAccountType(String value)
    {
        setAttributeInternal("AccountType", value);
    }

    public String getSelectedAccount()
    {
        return (String)getAttributeInternal("SelectedAccount");
    }

    public void setSelectedAccount(String value)
    {
        setAttributeInternal("SelectedAccount", value);
    }

    public Number getBankBranchId()
    {
        return (Number)getAttributeInternal("BankBranchId");
    }

    public void setBankBranchId(Number value)
    {
        setAttributeInternal("BankBranchId", value);
    }

    public String getBankNum()
    {
        return (String)getAttributeInternal("BankNum");
    }

    public void setBankNum(String value)
    {
        setAttributeInternal("BankNum", value);
    }

    public String getBankNumber()
    {
        return (String)getAttributeInternal("BankNumber");
    }

    public void setBankNumber(String value)
    {
        setAttributeInternal("BankNumber", value);
    }

    public String getBankName()
    {
        return (String)getAttributeInternal("BankName");
    }

    public void setBankName(String value)
    {
        setAttributeInternal("BankName", value);
    }

    public String getBankBranchName()
    {
        return (String)getAttributeInternal("BankBranchName");
    }

    public void setBankBranchName(String value)
    {
        setAttributeInternal("BankBranchName", value);
    }

    public String getBankBranchType()
    {
        return (String)getAttributeInternal("BankBranchType");
    }

    public void setBankBranchType(String value)
    {
        setAttributeInternal("BankBranchType", value);
    }

    public String getInstitutionType()
    {
        return (String)getAttributeInternal("InstitutionType");
    }

    public void setInstitutionType(String value)
    {
        setAttributeInternal("InstitutionType", value);
    }

    public Number getClearingHouseId()
    {
        return (Number)getAttributeInternal("ClearingHouseId");
    }

    public void setClearingHouseId(Number value)
    {
        setAttributeInternal("ClearingHouseId", value);
    }

    public String getEftUserNumber()
    {
        return (String)getAttributeInternal("EftUserNumber");
    }

    public void setEftUserNumber(String value)
    {
        setAttributeInternal("EftUserNumber", value);
    }

    public String getEftSwiftCode()
    {
        return (String)getAttributeInternal("EftSwiftCode");
    }

    public void setEftSwiftCode(String value)
    {
        setAttributeInternal("EftSwiftCode", value);
    }

    public String getEdiIdNumber()
    {
        return (String)getAttributeInternal("EdiIdNumber");
    }

    public void setEdiIdNumber(String value)
    {
        setAttributeInternal("EdiIdNumber", value);
    }

    public Date getActiveDate()
    {
        return (Date)getAttributeInternal("ActiveDate");
    }

    public void setActiveDate(Date value)
    {
        setAttributeInternal("ActiveDate", value);
    }

    public Date getEndDate()
    {
        return (Date)getAttributeInternal("EndDate");
    }

    public void setEndDate(Date value)
    {
        setAttributeInternal("EndDate", value);
    }

    public Number getTpHeaderId()
    {
        return (Number)getAttributeInternal("TpHeaderId");
    }

    public void setTpHeaderId(Number value)
    {
        setAttributeInternal("TpHeaderId", value);
    }

    public String getEceTpLocationCode()
    {
        return (String)getAttributeInternal("EceTpLocationCode");
    }

    public void setEceTpLocationCode(String value)
    {
        setAttributeInternal("EceTpLocationCode", value);
    }

    public Number getPayrollBankAccountId()
    {
        return (Number)getAttributeInternal("PayrollBankAccountId");
    }

    public void setPayrollBankAccountId(Number value)
    {
        setAttributeInternal("PayrollBankAccountId", value);
    }

    protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef)
        throws Exception
    {
    if (index == CUSTOMACCOUNTHOLDERNAME)
    {
      return getCustomAccountHolderName();
    }
    if (index == CUSTOMACCOUNTTYPE)
    {
      return getCustomAccountType();
    }
	if (index == CUSTOMEMAILADDRESS)
    {
      return getCustomEmailAddress();
    }
    return super.getAttrInvokeAccessor(index, attrDef);
    }

    protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef)
        throws Exception
    {
    if (index == CUSTOMACCOUNTTYPE)
    {
      setCustomAccountType((String)value);
      return;
    }
    super.setAttrInvokeAccessor(index, value, attrDef);
    return;
    }

  /**
   * 
   * Gets the attribute value for the calculated attribute Customaccountholdername
   */
  public String getCustomaccountholdername()
  {
    return (String)getAttributeInternal(CUSTOMACCOUNTHOLDERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Customaccountholdername
   */
  public void setCustomaccountholdername(String value)
  {
    setAttributeInternal(CUSTOMACCOUNTHOLDERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomAccountHolderName
   */
  public String getCustomAccountHolderName()
  {
    return (String)getAttributeInternal(CUSTOMACCOUNTHOLDERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomAccountHolderName
   */
  public void setCustomAccountHolderName(String value)
  {
    setAttributeInternal(CUSTOMACCOUNTHOLDERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CustomAccountType
   */
  public String getCustomAccountType()
  {
    return (String)getAttributeInternal(CUSTOMACCOUNTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomAccountType
   */
  public void setCustomAccountType(String value)
  {
    setAttributeInternal(CUSTOMACCOUNTTYPE, value);
  }


/**
   * 
   * Gets the attribute value for the calculated attribute CustomAccountType
   */
  public String getCustomEmailAddress()
  {
    return (String)getAttributeInternal(CUSTOMEMAILADDRESS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CustomAccountType
   */
  public void setCustomEmailAddress(String value)
  {
    setAttributeInternal(CUSTOMEMAILADDRESS, value);
  }


}
