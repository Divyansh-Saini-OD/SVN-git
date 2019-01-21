package od.oracle.apps.xxcrm.cdh.ebl.eblmain.server;

/*
  -- +===========================================================================+
  -- |                  Office Depot - eBilling Project                          |
  -- |                         WIPRO/Office Depot                                |
  -- +===========================================================================+
  -- | Name        :  ODEBillPPRVORowImpl                                        |
  -- | Description :                                                             |
  -- | This is the View Object Class for PPR transient attributes                |
  -- |                                                                           |
  -- |                                                                           |
  -- |                                                                           |
  -- |Change Record:                                                             |
  -- |===============                                                            |
  -- |Version  Date        Author               Remarks                          |
  -- |======== =========== ================     ================================ |
  -- |DRAFT 1A 15-JAN-2010 Devi Viswanathan     Initial draft version            |
  -- |1.0   19-Nov-2015    Sridevi Kondoju      Modified for MOD 4B R3           |
  -- |2.0   18-Mar-2017    Bhagwan Rao          Modified for Defect 38962        |
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
import oracle.apps.fnd.framework.OAApplicationModule;
import od.oracle.apps.xxcrm.cdh.ebl.server.ODUtil;

// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODEBillPPRVORowImpl extends OAViewRowImpl {

    public static final int ROWKEY = 0;
    public static final int EMAIL = 1;
    public static final int CD = 2;
    public static final int FTP = 3;
    public static final int STD = 4;
    public static final int NONSTD = 5;
    public static final int SPLIT = 6;
    public static final int COMPRESS = 7;
    public static final int FILECREATIONTYPE = 8;
    public static final int FIELDSELECTION = 9;
    public static final int LOGOREQ = 10;
    public static final int COMPLETE = 11;
    public static final int CSSCLASS = 12;
    public static final int COMPLETEDELBTN = 13;
    public static final int FTPNOTIFYCUSTOMER = 14;
    public static final int FTPSENDZEROBYTEFILE = 15;
    public static final int ENABLEXLSSUBTOTAL = 16;
    public static final int CONCATSPLIT = 17;
    public static final int CONCATSPLITMSG = 18;
    public static final int SUMBILL = 19;
    public static final int PARENTDOCIDDISABLED = 20;

    /**Gets the attribute value for the calculated attribute parentDocIDDisabled
     */
    public Boolean getparentDocIDDisabled() {
        return (Boolean) getAttributeInternal(PARENTDOCIDDISABLED);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute parentDocIDDisabled
     */
    public void setparentDocIDDisabled(Boolean value) {
        setAttributeInternal(PARENTDOCIDDISABLED, value);
    }

    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. Do not modify.
     */
    public enum AttributesEnum {
        RowKey {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getRowKey();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setRowKey((Number)value);
            }
        }
        ,
        Email {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getEmail();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setEmail((Boolean)value);
            }
        }
        ,
        CD {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getCD();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setCD((Boolean)value);
            }
        }
        ,
        FTP {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getFTP();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setFTP((Boolean)value);
            }
        }
        ,
        Std {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getStd();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setStd((Boolean)value);
            }
        }
        ,
        NonStd {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getNonStd();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setNonStd((Boolean)value);
            }
        }
        ,
        Split {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getSplit();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setSplit((Boolean)value);
            }
        }
        ,
        Compress {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getCompress();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setCompress((Boolean)value);
            }
        }
        ,
        FileCreationType {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getFileCreationType();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setFileCreationType((Boolean)value);
            }
        }
        ,
        FieldSelection {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getFieldSelection();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setFieldSelection((Boolean)value);
            }
        }
        ,
        LogoReq {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getLogoReq();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setLogoReq((Boolean)value);
            }
        }
        ,
        Complete {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getComplete();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setComplete((Boolean)value);
            }
        }
        ,
        CSSClass {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getCSSClass();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setCSSClass((String)value);
            }
        }
        ,
        CompleteDelBtn {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getCompleteDelBtn();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setCompleteDelBtn((Boolean)value);
            }
        }
        ,
        FtpNotifyCustomer {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getFtpNotifyCustomer();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setFtpNotifyCustomer((Boolean)value);
            }
        }
        ,
        FtpSendZeroByteFile {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getFtpSendZeroByteFile();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setFtpSendZeroByteFile((Boolean)value);
            }
        }
        ,
        EnableXlsSubtotal {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getEnableXlsSubtotal();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setEnableXlsSubtotal((Boolean)value);
            }
        }
        ,
        ConcatSplit {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getConcatSplit();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setConcatSplit((Boolean)value);
            }
        }
        ,
        ConcatSplitMsg {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getConcatSplitMsg();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setConcatSplitMsg((Boolean)value);
            }
        }
        ,
        SumBill {
            public Object get(ODEBillPPRVORowImpl obj) {
                return obj.getSumBill();
            }

            public void put(ODEBillPPRVORowImpl obj, Object value) {
                obj.setSumBill((Boolean)value);
            }
        }
        ;
        private static AttributesEnum[] vals = null;
        private static int firstIndex = 0;

        public abstract Object get(ODEBillPPRVORowImpl object);

        public abstract void put(ODEBillPPRVORowImpl object, Object value);

        public int index() {
            return AttributesEnum.firstIndex() + ordinal();
        }

        public static int firstIndex() {
            return firstIndex;
        }

        public static int count() {
            return AttributesEnum.firstIndex() + AttributesEnum.staticValues().length;
        }

        public static AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = AttributesEnum.values();
            }
            return vals;
        }
    }

    /**This is the default constructor (do not remove)
     */
    public ODEBillPPRVORowImpl() {
    }

    /**Gets the attribute value for the calculated attribute RowKey
     */
    public Number getRowKey() {
        return (Number) getAttributeInternal(ROWKEY);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute RowKey
     */
    public void setRowKey(Number value) {
        setAttributeInternal(ROWKEY, value);
    }

    /**Gets the attribute value for the calculated attribute Email
     */
    public Boolean getEmail() {
        return (Boolean) getAttributeInternal(EMAIL);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Email
     */
    public void setEmail(Boolean value) {
        setAttributeInternal(EMAIL, value);
    }

    /**Gets the attribute value for the calculated attribute CD
     */
    public Boolean getCD() {
        return (Boolean) getAttributeInternal(CD);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CD
     */
    public void setCD(Boolean value) {
        setAttributeInternal(CD, value);
    }

    /**Gets the attribute value for the calculated attribute FTP
     */
    public Boolean getFTP() {
        return (Boolean) getAttributeInternal(FTP);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FTP
     */
    public void setFTP(Boolean value) {
        setAttributeInternal(FTP, value);
    }

    /**Gets the attribute value for the calculated attribute Std
     */
    public Boolean getStd() {
        return (Boolean) getAttributeInternal(STD);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Std
     */
    public void setStd(Boolean value) {
        setAttributeInternal(STD, value);
    }

    /**Gets the attribute value for the calculated attribute NonStd
     */
    public Boolean getNonStd() {
        return (Boolean) getAttributeInternal(NONSTD);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NonStd
     */
    public void setNonStd(Boolean value) {
        setAttributeInternal(NONSTD, value);
    }

    /**Gets the attribute value for the calculated attribute Split
     */
    public Boolean getSplit() {
        return (Boolean) getAttributeInternal(SPLIT);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Split
     */
    public void setSplit(Boolean value) {
        setAttributeInternal(SPLIT, value);
    }

    /**Gets the attribute value for the calculated attribute Compress
     */
    public Boolean getCompress() {
        return (Boolean) getAttributeInternal(COMPRESS);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Compress
     */
    public void setCompress(Boolean value) {
        setAttributeInternal(COMPRESS, value);
    }

    /**Gets the attribute value for the calculated attribute FileCreationType
     */
    public Boolean getFileCreationType() {
        return (Boolean) getAttributeInternal(FILECREATIONTYPE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FileCreationType
     */
    public void setFileCreationType(Boolean value) {
        setAttributeInternal(FILECREATIONTYPE, value);
    }

    /**Gets the attribute value for the calculated attribute FieldSelection
     */
    public Boolean getFieldSelection() {
        return (Boolean) getAttributeInternal(FIELDSELECTION);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FieldSelection
     */
    public void setFieldSelection(Boolean value) {
        setAttributeInternal(FIELDSELECTION, value);
    }

    /**Gets the attribute value for the calculated attribute LogoReq
     */
    public Boolean getLogoReq() {
        return (Boolean) getAttributeInternal(LOGOREQ);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute LogoReq
     */
    public void setLogoReq(Boolean value) {
        setAttributeInternal(LOGOREQ, value);
    }

    /**Gets the attribute value for the calculated attribute Complete
     */
    public Boolean getComplete() {
        return (Boolean) getAttributeInternal(COMPLETE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Complete
     */
    public void setComplete(Boolean value) {
        setAttributeInternal(COMPLETE, value);
    }

    /**Gets the attribute value for the calculated attribute CSSClass
     */
    public String getCSSClass() {
        return (String) getAttributeInternal(CSSCLASS);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CSSClass
     */
    public void setCSSClass(String value) {
        setAttributeInternal(CSSCLASS, value);
    }

    /**Gets the attribute value for the calculated attribute CompleteDelBtn
     */
    public Boolean getCompleteDelBtn() {
        return (Boolean) getAttributeInternal(COMPLETEDELBTN);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute CompleteDelBtn
     */
    public void setCompleteDelBtn(Boolean value) {
        setAttributeInternal(COMPLETEDELBTN, value);
    }

    /**Gets the attribute value for the calculated attribute FtpNotifyCustomer
     */
    public Boolean getFtpNotifyCustomer() {
        return (Boolean) getAttributeInternal(FTPNOTIFYCUSTOMER);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FtpNotifyCustomer
     */
    public void setFtpNotifyCustomer(Boolean value) {
        setAttributeInternal(FTPNOTIFYCUSTOMER, value);
    }

    /**Gets the attribute value for the calculated attribute FtpSendZeroByteFile
     */
    public Boolean getFtpSendZeroByteFile() {
        return (Boolean) getAttributeInternal(FTPSENDZEROBYTEFILE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FtpSendZeroByteFile
     */
    public void setFtpSendZeroByteFile(Boolean value) {
        setAttributeInternal(FTPSENDZEROBYTEFILE, value);
    }

    /**Gets the attribute value for the calculated attribute EnableXlsSubtotal
     */
    public Boolean getEnableXlsSubtotal() {
        return (Boolean) getAttributeInternal(ENABLEXLSSUBTOTAL);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute EnableXlsSubtotal
     */
    public void setEnableXlsSubtotal(Boolean value) {
        setAttributeInternal(ENABLEXLSSUBTOTAL, value);
    }

    /**Gets the attribute value for the calculated attribute ConcatSplit
     */
    public Boolean getConcatSplit() {
        return (Boolean) getAttributeInternal(CONCATSPLIT);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ConcatSplit
     */
    public void setConcatSplit(Boolean value) {
        setAttributeInternal(CONCATSPLIT, value);
    }

    /**Gets the attribute value for the calculated attribute ConcatSplitMsg
     */
    public Boolean getConcatSplitMsg() {
        return (Boolean) getAttributeInternal(CONCATSPLITMSG);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute ConcatSplitMsg
     */
    public void setConcatSplitMsg(Boolean value) {
        setAttributeInternal(CONCATSPLITMSG, value);
    }

    /**Gets the attribute value for the calculated attribute SumBill
     */
    public Boolean getSumBill() {
        return (Boolean) getAttributeInternal(SUMBILL);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute SumBill
     */
    public void setSumBill(Boolean value) {
        setAttributeInternal(SUMBILL, value);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case ROWKEY:
            return getRowKey();
        case EMAIL:
            return getEmail();
        case CD:
            return getCD();
        case FTP:
            return getFTP();
        case STD:
            return getStd();
        case NONSTD:
            return getNonStd();
        case SPLIT:
            return getSplit();
        case COMPRESS:
            return getCompress();
        case FILECREATIONTYPE:
            return getFileCreationType();
        case FIELDSELECTION:
            return getFieldSelection();
        case LOGOREQ:
            return getLogoReq();
        case COMPLETE:
            return getComplete();
        case CSSCLASS:
            return getCSSClass();
        case COMPLETEDELBTN:
            return getCompleteDelBtn();
        case FTPNOTIFYCUSTOMER:
            return getFtpNotifyCustomer();
        case FTPSENDZEROBYTEFILE:
            return getFtpSendZeroByteFile();
        case ENABLEXLSSUBTOTAL:
            return getEnableXlsSubtotal();
        case CONCATSPLIT:
            return getConcatSplit();
        case CONCATSPLITMSG:
            return getConcatSplitMsg();
        case SUMBILL:
            return getSumBill();
        case PARENTDOCIDDISABLED:
            return getparentDocIDDisabled();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case ROWKEY:
            setRowKey((Number)value);
            return;
        case EMAIL:
            setEmail((Boolean)value);
            return;
        case CD:
            setCD((Boolean)value);
            return;
        case FTP:
            setFTP((Boolean)value);
            return;
        case STD:
            setStd((Boolean)value);
            return;
        case NONSTD:
            setNonStd((Boolean)value);
            return;
        case SPLIT:
            setSplit((Boolean)value);
            return;
        case COMPRESS:
            setCompress((Boolean)value);
            return;
        case FILECREATIONTYPE:
            setFileCreationType((Boolean)value);
            return;
        case FIELDSELECTION:
            setFieldSelection((Boolean)value);
            return;
        case LOGOREQ:
            setLogoReq((Boolean)value);
            return;
        case COMPLETE:
            setComplete((Boolean)value);
            return;
        case CSSCLASS:
            setCSSClass((String)value);
            return;
        case COMPLETEDELBTN:
            setCompleteDelBtn((Boolean)value);
            return;
        case FTPNOTIFYCUSTOMER:
            setFtpNotifyCustomer((Boolean)value);
            return;
        case FTPSENDZEROBYTEFILE:
            setFtpSendZeroByteFile((Boolean)value);
            return;
        case ENABLEXLSSUBTOTAL:
            setEnableXlsSubtotal((Boolean)value);
            return;
        case CONCATSPLIT:
            setConcatSplit((Boolean)value);
            return;
        case CONCATSPLITMSG:
            setConcatSplitMsg((Boolean)value);
            return;
        case SUMBILL:
            setSumBill((Boolean)value);
            return;
        case PARENTDOCIDDISABLED:
            setparentDocIDDisabled((Boolean)value);
            return;
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }
}
