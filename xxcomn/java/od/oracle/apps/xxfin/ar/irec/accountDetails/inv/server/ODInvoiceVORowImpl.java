// Decompiled by Jad v1.5.8g. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: packimports(3) 
// Source File Name:   ODInvoiceVORowImpl.java

package od.oracle.apps.xxfin.ar.irec.accountDetails.inv.server;

import oracle.apps.ar.irec.accountDetails.inv.server.InvoiceVORowImpl;
import oracle.jbo.server.AttributeDefImpl;
//import oracle.jbo.domain.Date;
//import oracle.jbo.domain.Number;
//import oracle.jbo.server.ViewDefImpl;

public class ODInvoiceVORowImpl extends InvoiceVORowImpl
{
    protected static final int MAXATTRCONST = oracle.jbo.server.ViewDefImpl.getMaxAttrConst("oracle.apps.ar.irec.accountDetails.inv.server.InvoiceVO");
    protected static final int XXSHIPTONAME = MAXATTRCONST;
    protected static final int XXSHIPTOADDRESS1 = MAXATTRCONST + 1;
    protected static final int XXSHIPTOADDRESS2 = MAXATTRCONST + 2;
    protected static final int XXSHIPTOCOMBINEDADDRESS = MAXATTRCONST + 3;

    public ODInvoiceVORowImpl()
    {
    }

    protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception {
      if (index == XXSHIPTONAME)            return getXXShipToName();
      if (index == XXSHIPTOADDRESS1)        return getXXShipToAddress1();
      if (index == XXSHIPTOADDRESS2)        return getXXShipToAddress2();
      if (index == XXSHIPTOCOMBINEDADDRESS) return getXXShipToCombinedAddress();
      return super.getAttrInvokeAccessor(index, attrDef);
    }

    protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception {
      if (index == XXSHIPTONAME) {
        setXXShipToName((String)value);
        return;
      }
      if (index == XXSHIPTOADDRESS1) {
        setXXShipToAddress1((String)value);
        return;
      }
      if (index == XXSHIPTOADDRESS2) {
        setXXShipToAddress2((String)value);
        return;
      }
      if (index == XXSHIPTOCOMBINEDADDRESS) {
        setXXShipToCombinedAddress((String)value);
        return;
      }
      super.setAttrInvokeAccessor(index, value, attrDef);
    }

    public String getXXShipToName()
    {
       return (String)getAttributeInternal(XXSHIPTONAME);
    }

    public void setXXShipToName(String value)
    {
      setAttributeInternal(XXSHIPTONAME, value);
    }

    public String getXXShipToAddress1()
    {
      return (String)getAttributeInternal(XXSHIPTOADDRESS1);
    }

    public void setXXShipToAddress1(String value)
    {
      setAttributeInternal(XXSHIPTOADDRESS1, value);
    }

    public String getXXShipToAddress2()
    {
      return (String)getAttributeInternal(XXSHIPTOADDRESS2);
    }

    public void setXXShipToAddress2(String value)
    {
      setAttributeInternal(XXSHIPTOADDRESS2, value);
    }

    public String getXXShipToCombinedAddress()
    {
      return (String)getAttributeInternal(XXSHIPTOCOMBINEDADDRESS);
    }

    public void setXXShipToCombinedAddress(String value)
    {
      setAttributeInternal(XXSHIPTOCOMBINEDADDRESS, value);
    }
}
