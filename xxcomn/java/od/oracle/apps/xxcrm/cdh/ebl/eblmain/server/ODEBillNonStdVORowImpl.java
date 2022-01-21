package od.oracle.apps.xxcrm.cdh.ebl.eblmain.server;
/*
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        :  ODEBillContactsLOVVORowImpl                                |
  -- | Description :                                                             |
  -- | This is the package for Contacts LOV VO                                   |
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
  -- | $HeadURL$                                                               |
  -- | $Rev$                                                                   |
  -- | $Date$                                                                  |
  -- |                                                                           |
  -- +===========================================================================+
*/
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODEBillNonStdVORowImpl extends OAViewRowImpl 
{


  protected static final int EBLTEMPLID = 0;
  protected static final int CUSTDOCID = 1;
  protected static final int RECORDTYPE = 2;
  protected static final int SEQ = 3;
  protected static final int FIELDID = 4;
  protected static final int LABEL = 5;
  protected static final int STARTPOS = 6;
  protected static final int FIELDLEN = 7;
  protected static final int DATAFORMAT = 8;
  protected static final int STRINGFUN = 9;
  protected static final int SORTORDER = 10;
  protected static final int SORTTYPE = 11;
  protected static final int MANDATORY = 12;
  protected static final int SEQSTARTVAL = 13;
  protected static final int SEQINCVAL = 14;
  protected static final int SEQRESETFIELD = 15;
  protected static final int CONSTANTVALUE = 16;
  protected static final int ALIGNMENT = 17;
  protected static final int PADDINGCHAR = 18;
  protected static final int DEFAULTIFNULL = 19;
  protected static final int COMMENTS = 20;
  protected static final int ATTRIBUTE1 = 21;
  protected static final int ATTRIBUTE2 = 22;
  protected static final int ATTRIBUTE3 = 23;
  protected static final int ATTRIBUTE4 = 24;
  protected static final int ATTRIBUTE5 = 25;
  protected static final int ATTRIBUTE6 = 26;
  protected static final int ATTRIBUTE7 = 27;
  protected static final int ATTRIBUTE8 = 28;
  protected static final int ATTRIBUTE9 = 29;
  protected static final int ATTRIBUTE10 = 30;
  protected static final int ATTRIBUTE11 = 31;
  protected static final int ATTRIBUTE12 = 32;
  protected static final int ATTRIBUTE13 = 33;
  protected static final int ATTRIBUTE14 = 34;
  protected static final int ATTRIBUTE15 = 35;
  protected static final int ATTRIBUTE16 = 36;
  protected static final int ATTRIBUTE17 = 37;
  protected static final int ATTRIBUTE18 = 38;
  protected static final int ATTRIBUTE19 = 39;
  protected static final int ATTRIBUTE20 = 40;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public ODEBillNonStdVORowImpl()
  {
  }

  /**
   * 
   * Gets ODEBillNonStdEO entity object.
   */
  public od.oracle.apps.xxcrm.cdh.ebl.eblmain.schema.server.ODEBillNonStdEOImpl getODEBillNonStdEO()
  {
    return (od.oracle.apps.xxcrm.cdh.ebl.eblmain.schema.server.ODEBillNonStdEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for EBL_TEMPL_ID using the alias name EblTemplId
   */
  public Number getEblTemplId()
  {
    return (Number)getAttributeInternal(EBLTEMPLID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EBL_TEMPL_ID using the alias name EblTemplId
   */
  public void setEblTemplId(Number value)
  {
    setAttributeInternal(EBLTEMPLID, value);
  }

  /**
   * 
   * Gets the attribute value for CUST_DOC_ID using the alias name CustDocId
   */
  public Number getCustDocId()
  {
    return (Number)getAttributeInternal(CUSTDOCID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CUST_DOC_ID using the alias name CustDocId
   */
  public void setCustDocId(Number value)
  {
    setAttributeInternal(CUSTDOCID, value);
  }

  /**
   * 
   * Gets the attribute value for RECORD_TYPE using the alias name RecordType
   */
  public String getRecordType()
  {
    return (String)getAttributeInternal(RECORDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for RECORD_TYPE using the alias name RecordType
   */
  public void setRecordType(String value)
  {
    setAttributeInternal(RECORDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for SEQ using the alias name Seq
   */
  public Number getSeq()
  {
    return (Number)getAttributeInternal(SEQ);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SEQ using the alias name Seq
   */
  public void setSeq(Number value)
  {
    setAttributeInternal(SEQ, value);
  }

  /**
   * 
   * Gets the attribute value for FIELD_ID using the alias name FieldId
   */
  public Number getFieldId()
  {
    return (Number)getAttributeInternal(FIELDID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FIELD_ID using the alias name FieldId
   */
  public void setFieldId(Number value)
  {
    setAttributeInternal(FIELDID, value);
  }

  /**
   * 
   * Gets the attribute value for LABEL using the alias name Label
   */
  public String getLabel()
  {
    return (String)getAttributeInternal(LABEL);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LABEL using the alias name Label
   */
  public void setLabel(String value)
  {
    setAttributeInternal(LABEL, value);
  }

  /**
   * 
   * Gets the attribute value for START_POS using the alias name StartPos
   */
  public Number getStartPos()
  {
    return (Number)getAttributeInternal(STARTPOS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for START_POS using the alias name StartPos
   */
  public void setStartPos(Number value)
  {
    setAttributeInternal(STARTPOS, value);
  }

  /**
   * 
   * Gets the attribute value for FIELD_LEN using the alias name FieldLen
   */
  public Number getFieldLen()
  {
    return (Number)getAttributeInternal(FIELDLEN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FIELD_LEN using the alias name FieldLen
   */
  public void setFieldLen(Number value)
  {
    setAttributeInternal(FIELDLEN, value);
  }

  /**
   * 
   * Gets the attribute value for DATA_FORMAT using the alias name DataFormat
   */
  public String getDataFormat()
  {
    return (String)getAttributeInternal(DATAFORMAT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DATA_FORMAT using the alias name DataFormat
   */
  public void setDataFormat(String value)
  {
    setAttributeInternal(DATAFORMAT, value);
  }

  /**
   * 
   * Gets the attribute value for STRING_FUN using the alias name StringFun
   */
  public String getStringFun()
  {
    return (String)getAttributeInternal(STRINGFUN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for STRING_FUN using the alias name StringFun
   */
  public void setStringFun(String value)
  {
    setAttributeInternal(STRINGFUN, value);
  }

  /**
   * 
   * Gets the attribute value for SORT_ORDER using the alias name SortOrder
   */
  public Number getSortOrder()
  {
    return (Number)getAttributeInternal(SORTORDER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SORT_ORDER using the alias name SortOrder
   */
  public void setSortOrder(Number value)
  {
    setAttributeInternal(SORTORDER, value);
  }

  /**
   * 
   * Gets the attribute value for SORT_TYPE using the alias name SortType
   */
  public String getSortType()
  {
    return (String)getAttributeInternal(SORTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SORT_TYPE using the alias name SortType
   */
  public void setSortType(String value)
  {
    setAttributeInternal(SORTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for MANDATORY using the alias name Mandatory
   */
  public String getMandatory()
  {
    return (String)getAttributeInternal(MANDATORY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for MANDATORY using the alias name Mandatory
   */
  public void setMandatory(String value)
  {
    setAttributeInternal(MANDATORY, value);
  }

  /**
   * 
   * Gets the attribute value for SEQ_START_VAL using the alias name SeqStartVal
   */
  public Number getSeqStartVal()
  {
    return (Number)getAttributeInternal(SEQSTARTVAL);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SEQ_START_VAL using the alias name SeqStartVal
   */
  public void setSeqStartVal(Number value)
  {
    setAttributeInternal(SEQSTARTVAL, value);
  }

  /**
   * 
   * Gets the attribute value for SEQ_INC_VAL using the alias name SeqIncVal
   */
  public Number getSeqIncVal()
  {
    return (Number)getAttributeInternal(SEQINCVAL);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SEQ_INC_VAL using the alias name SeqIncVal
   */
  public void setSeqIncVal(Number value)
  {
    setAttributeInternal(SEQINCVAL, value);
  }

  /**
   * 
   * Gets the attribute value for SEQ_RESET_FIELD using the alias name SeqResetField
   */
  public Number getSeqResetField()
  {
    return (Number)getAttributeInternal(SEQRESETFIELD);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SEQ_RESET_FIELD using the alias name SeqResetField
   */
  public void setSeqResetField(Number value)
  {
    setAttributeInternal(SEQRESETFIELD, value);
  }

  /**
   * 
   * Gets the attribute value for CONSTANT_VALUE using the alias name ConstantValue
   */
  public String getConstantValue()
  {
    return (String)getAttributeInternal(CONSTANTVALUE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CONSTANT_VALUE using the alias name ConstantValue
   */
  public void setConstantValue(String value)
  {
    setAttributeInternal(CONSTANTVALUE, value);
  }

  /**
   * 
   * Gets the attribute value for ALIGNMENT using the alias name Alignment
   */
  public String getAlignment()
  {
    return (String)getAttributeInternal(ALIGNMENT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ALIGNMENT using the alias name Alignment
   */
  public void setAlignment(String value)
  {
    setAttributeInternal(ALIGNMENT, value);
  }

  /**
   * 
   * Gets the attribute value for PADDING_CHAR using the alias name PaddingChar
   */
  public String getPaddingChar()
  {
    return (String)getAttributeInternal(PADDINGCHAR);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PADDING_CHAR using the alias name PaddingChar
   */
  public void setPaddingChar(String value)
  {
    setAttributeInternal(PADDINGCHAR, value);
  }

  /**
   * 
   * Gets the attribute value for DEFAULT_IF_NULL using the alias name DefaultIfNull
   */
  public String getDefaultIfNull()
  {
    return (String)getAttributeInternal(DEFAULTIFNULL);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DEFAULT_IF_NULL using the alias name DefaultIfNull
   */
  public void setDefaultIfNull(String value)
  {
    setAttributeInternal(DEFAULTIFNULL, value);
  }

  /**
   * 
   * Gets the attribute value for COMMENTS using the alias name Comments
   */
  public String getComments()
  {
    return (String)getAttributeInternal(COMMENTS);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for COMMENTS using the alias name Comments
   */
  public void setComments(String value)
  {
    setAttributeInternal(COMMENTS, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE1 using the alias name Attribute1
   */
  public String getAttribute1()
  {
    return (String)getAttributeInternal(ATTRIBUTE1);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE1 using the alias name Attribute1
   */
  public void setAttribute1(String value)
  {
    setAttributeInternal(ATTRIBUTE1, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE2 using the alias name Attribute2
   */
  public String getAttribute2()
  {
    return (String)getAttributeInternal(ATTRIBUTE2);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE2 using the alias name Attribute2
   */
  public void setAttribute2(String value)
  {
    setAttributeInternal(ATTRIBUTE2, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE3 using the alias name Attribute3
   */
  public String getAttribute3()
  {
    return (String)getAttributeInternal(ATTRIBUTE3);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE3 using the alias name Attribute3
   */
  public void setAttribute3(String value)
  {
    setAttributeInternal(ATTRIBUTE3, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE4 using the alias name Attribute4
   */
  public String getAttribute4()
  {
    return (String)getAttributeInternal(ATTRIBUTE4);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE4 using the alias name Attribute4
   */
  public void setAttribute4(String value)
  {
    setAttributeInternal(ATTRIBUTE4, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE5 using the alias name Attribute5
   */
  public String getAttribute5()
  {
    return (String)getAttributeInternal(ATTRIBUTE5);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE5 using the alias name Attribute5
   */
  public void setAttribute5(String value)
  {
    setAttributeInternal(ATTRIBUTE5, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE6 using the alias name Attribute6
   */
  public String getAttribute6()
  {
    return (String)getAttributeInternal(ATTRIBUTE6);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE6 using the alias name Attribute6
   */
  public void setAttribute6(String value)
  {
    setAttributeInternal(ATTRIBUTE6, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE7 using the alias name Attribute7
   */
  public String getAttribute7()
  {
    return (String)getAttributeInternal(ATTRIBUTE7);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE7 using the alias name Attribute7
   */
  public void setAttribute7(String value)
  {
    setAttributeInternal(ATTRIBUTE7, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE8 using the alias name Attribute8
   */
  public String getAttribute8()
  {
    return (String)getAttributeInternal(ATTRIBUTE8);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE8 using the alias name Attribute8
   */
  public void setAttribute8(String value)
  {
    setAttributeInternal(ATTRIBUTE8, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE9 using the alias name Attribute9
   */
  public String getAttribute9()
  {
    return (String)getAttributeInternal(ATTRIBUTE9);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE9 using the alias name Attribute9
   */
  public void setAttribute9(String value)
  {
    setAttributeInternal(ATTRIBUTE9, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE10 using the alias name Attribute10
   */
  public String getAttribute10()
  {
    return (String)getAttributeInternal(ATTRIBUTE10);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE10 using the alias name Attribute10
   */
  public void setAttribute10(String value)
  {
    setAttributeInternal(ATTRIBUTE10, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE11 using the alias name Attribute11
   */
  public String getAttribute11()
  {
    return (String)getAttributeInternal(ATTRIBUTE11);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE11 using the alias name Attribute11
   */
  public void setAttribute11(String value)
  {
    setAttributeInternal(ATTRIBUTE11, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE12 using the alias name Attribute12
   */
  public String getAttribute12()
  {
    return (String)getAttributeInternal(ATTRIBUTE12);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE12 using the alias name Attribute12
   */
  public void setAttribute12(String value)
  {
    setAttributeInternal(ATTRIBUTE12, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE13 using the alias name Attribute13
   */
  public String getAttribute13()
  {
    return (String)getAttributeInternal(ATTRIBUTE13);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE13 using the alias name Attribute13
   */
  public void setAttribute13(String value)
  {
    setAttributeInternal(ATTRIBUTE13, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE14 using the alias name Attribute14
   */
  public String getAttribute14()
  {
    return (String)getAttributeInternal(ATTRIBUTE14);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE14 using the alias name Attribute14
   */
  public void setAttribute14(String value)
  {
    setAttributeInternal(ATTRIBUTE14, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE15 using the alias name Attribute15
   */
  public String getAttribute15()
  {
    return (String)getAttributeInternal(ATTRIBUTE15);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE15 using the alias name Attribute15
   */
  public void setAttribute15(String value)
  {
    setAttributeInternal(ATTRIBUTE15, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE16 using the alias name Attribute16
   */
  public String getAttribute16()
  {
    return (String)getAttributeInternal(ATTRIBUTE16);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE16 using the alias name Attribute16
   */
  public void setAttribute16(String value)
  {
    setAttributeInternal(ATTRIBUTE16, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE17 using the alias name Attribute17
   */
  public String getAttribute17()
  {
    return (String)getAttributeInternal(ATTRIBUTE17);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE17 using the alias name Attribute17
   */
  public void setAttribute17(String value)
  {
    setAttributeInternal(ATTRIBUTE17, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE18 using the alias name Attribute18
   */
  public String getAttribute18()
  {
    return (String)getAttributeInternal(ATTRIBUTE18);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE18 using the alias name Attribute18
   */
  public void setAttribute18(String value)
  {
    setAttributeInternal(ATTRIBUTE18, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE19 using the alias name Attribute19
   */
  public String getAttribute19()
  {
    return (String)getAttributeInternal(ATTRIBUTE19);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE19 using the alias name Attribute19
   */
  public void setAttribute19(String value)
  {
    setAttributeInternal(ATTRIBUTE19, value);
  }

  /**
   * 
   * Gets the attribute value for ATTRIBUTE20 using the alias name Attribute20
   */
  public String getAttribute20()
  {
    return (String)getAttributeInternal(ATTRIBUTE20);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for ATTRIBUTE20 using the alias name Attribute20
   */
  public void setAttribute20(String value)
  {
    setAttributeInternal(ATTRIBUTE20, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EBLTEMPLID:
        return getEblTemplId();
      case CUSTDOCID:
        return getCustDocId();
      case RECORDTYPE:
        return getRecordType();
      case SEQ:
        return getSeq();
      case FIELDID:
        return getFieldId();
      case LABEL:
        return getLabel();
      case STARTPOS:
        return getStartPos();
      case FIELDLEN:
        return getFieldLen();
      case DATAFORMAT:
        return getDataFormat();
      case STRINGFUN:
        return getStringFun();
      case SORTORDER:
        return getSortOrder();
      case SORTTYPE:
        return getSortType();
      case MANDATORY:
        return getMandatory();
      case SEQSTARTVAL:
        return getSeqStartVal();
      case SEQINCVAL:
        return getSeqIncVal();
      case SEQRESETFIELD:
        return getSeqResetField();
      case CONSTANTVALUE:
        return getConstantValue();
      case ALIGNMENT:
        return getAlignment();
      case PADDINGCHAR:
        return getPaddingChar();
      case DEFAULTIFNULL:
        return getDefaultIfNull();
      case COMMENTS:
        return getComments();
      case ATTRIBUTE1:
        return getAttribute1();
      case ATTRIBUTE2:
        return getAttribute2();
      case ATTRIBUTE3:
        return getAttribute3();
      case ATTRIBUTE4:
        return getAttribute4();
      case ATTRIBUTE5:
        return getAttribute5();
      case ATTRIBUTE6:
        return getAttribute6();
      case ATTRIBUTE7:
        return getAttribute7();
      case ATTRIBUTE8:
        return getAttribute8();
      case ATTRIBUTE9:
        return getAttribute9();
      case ATTRIBUTE10:
        return getAttribute10();
      case ATTRIBUTE11:
        return getAttribute11();
      case ATTRIBUTE12:
        return getAttribute12();
      case ATTRIBUTE13:
        return getAttribute13();
      case ATTRIBUTE14:
        return getAttribute14();
      case ATTRIBUTE15:
        return getAttribute15();
      case ATTRIBUTE16:
        return getAttribute16();
      case ATTRIBUTE17:
        return getAttribute17();
      case ATTRIBUTE18:
        return getAttribute18();
      case ATTRIBUTE19:
        return getAttribute19();
      case ATTRIBUTE20:
        return getAttribute20();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EBLTEMPLID:
        setEblTemplId((Number)value);
        return;
      case CUSTDOCID:
        setCustDocId((Number)value);
        return;
      case RECORDTYPE:
        setRecordType((String)value);
        return;
      case SEQ:
        setSeq((Number)value);
        return;
      case FIELDID:
        setFieldId((Number)value);
        return;
      case LABEL:
        setLabel((String)value);
        return;
      case STARTPOS:
        setStartPos((Number)value);
        return;
      case FIELDLEN:
        setFieldLen((Number)value);
        return;
      case DATAFORMAT:
        setDataFormat((String)value);
        return;
      case STRINGFUN:
        setStringFun((String)value);
        return;
      case SORTORDER:
        setSortOrder((Number)value);
        return;
      case SORTTYPE:
        setSortType((String)value);
        return;
      case MANDATORY:
        setMandatory((String)value);
        return;
      case SEQSTARTVAL:
        setSeqStartVal((Number)value);
        return;
      case SEQINCVAL:
        setSeqIncVal((Number)value);
        return;
      case SEQRESETFIELD:
        setSeqResetField((Number)value);
        return;
      case CONSTANTVALUE:
        setConstantValue((String)value);
        return;
      case ALIGNMENT:
        setAlignment((String)value);
        return;
      case PADDINGCHAR:
        setPaddingChar((String)value);
        return;
      case DEFAULTIFNULL:
        setDefaultIfNull((String)value);
        return;
      case COMMENTS:
        setComments((String)value);
        return;
      case ATTRIBUTE1:
        setAttribute1((String)value);
        return;
      case ATTRIBUTE2:
        setAttribute2((String)value);
        return;
      case ATTRIBUTE3:
        setAttribute3((String)value);
        return;
      case ATTRIBUTE4:
        setAttribute4((String)value);
        return;
      case ATTRIBUTE5:
        setAttribute5((String)value);
        return;
      case ATTRIBUTE6:
        setAttribute6((String)value);
        return;
      case ATTRIBUTE7:
        setAttribute7((String)value);
        return;
      case ATTRIBUTE8:
        setAttribute8((String)value);
        return;
      case ATTRIBUTE9:
        setAttribute9((String)value);
        return;
      case ATTRIBUTE10:
        setAttribute10((String)value);
        return;
      case ATTRIBUTE11:
        setAttribute11((String)value);
        return;
      case ATTRIBUTE12:
        setAttribute12((String)value);
        return;
      case ATTRIBUTE13:
        setAttribute13((String)value);
        return;
      case ATTRIBUTE14:
        setAttribute14((String)value);
        return;
      case ATTRIBUTE15:
        setAttribute15((String)value);
        return;
      case ATTRIBUTE16:
        setAttribute16((String)value);
        return;
      case ATTRIBUTE17:
        setAttribute17((String)value);
        return;
      case ATTRIBUTE18:
        setAttribute18((String)value);
        return;
      case ATTRIBUTE19:
        setAttribute19((String)value);
        return;
      case ATTRIBUTE20:
        setAttribute20((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}