package od.oracle.apps.xxcrm.cdh.ebl.ebltxtmain.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;

import oracle.jbo.server.AttributeDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ODEBillTxtHdrFieldsVORowImpl extends OAViewRowImpl {
    public static final int FIELDID = 0;
    public static final int FIELDNAME = 1;
    public static final int SOURCETABLE = 2;
    public static final int SOURCECOLUMN = 3;
    public static final int FUNCTION1 = 4;
    public static final int AGGEGATABLE = 5;
    public static final int SORTABLE = 6;
    public static final int INCLUDEINSTANDARD = 7;
    public static final int INCLUDEINCORE = 8;
    public static final int INCLUDEINDETAIL = 9;
    public static final int DATATYPE = 10;
    public static final int DATAFORMAT = 11;
    public static final int FIELDLENGTH = 12;
    public static final int NONSTDRECORDLEVEL = 13;
    public static final int USEINFILENAME = 14;
    public static final int COMMENTS = 15;
    public static final int NDTRECTYPECONST1 = 16;
    public static final int NDTRECTYPECONST2 = 17;
    public static final int NDTRECTYPECONST3 = 18;
    public static final int NDTRECTYPECONST4 = 19;
    public static final int NDTRECTYPECONST5 = 20;
    public static final int NDTRECTYPECONST6 = 21;
    public static final int RECORDER = 22;
    public static final int TARGETVALUE14 = 23;
    public static final int TARGETVALUE15 = 24;
    public static final int TARGETVALUE16 = 25;
    public static final int HEADERDETAIL = 26;
    public static final int AVAIINDATAEXTRACT = 27;
    public static final int RECTYPE = 28;
    public static final int STAGINGTABLE = 29;
    public static final int DEFAULTSEQ = 30;
    public static final int FUNCTION1_1 = 31;

    /**This is the default constructor (do not remove)
     */
    public ODEBillTxtHdrFieldsVORowImpl() {
    }

    /**Gets the attribute value for the calculated attribute FieldId
     */
    public String getFieldId() {
        return (String) getAttributeInternal(FIELDID);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FieldId
     */
    public void setFieldId(String value) {
        setAttributeInternal(FIELDID, value);
    }

    /**Gets the attribute value for the calculated attribute FieldName
     */
    public String getFieldName() {
        return (String) getAttributeInternal(FIELDNAME);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FieldName
     */
    public void setFieldName(String value) {
        setAttributeInternal(FIELDNAME, value);
    }

    /**Gets the attribute value for the calculated attribute IncludeInCore
     */
    public String getIncludeInCore() {
        return (String) getAttributeInternal(INCLUDEINCORE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute IncludeInCore
     */
    public void setIncludeInCore(String value) {
        setAttributeInternal(INCLUDEINCORE, value);
    }

    /**Gets the attribute value for the calculated attribute IncludeInDetail
     */
    public String getIncludeInDetail() {
        return (String) getAttributeInternal(INCLUDEINDETAIL);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute IncludeInDetail
     */
    public void setIncludeInDetail(String value) {
        setAttributeInternal(INCLUDEINDETAIL, value);
    }

    /**Gets the attribute value for the calculated attribute DataFormat
     */
    public String getDataFormat() {
        return (String) getAttributeInternal(DATAFORMAT);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute DataFormat
     */
    public void setDataFormat(String value) {
        setAttributeInternal(DATAFORMAT, value);
    }

    /**Gets the attribute value for the calculated attribute DefaultSeq
     */
    public String getDefaultSeq() {
        return (String) getAttributeInternal(DEFAULTSEQ);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute DefaultSeq
     */
    public void setDefaultSeq(String value) {
        setAttributeInternal(DEFAULTSEQ, value);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case FIELDID:
            return getFieldId();
        case FIELDNAME:
            return getFieldName();
        case SOURCETABLE:
            return getSourceTable();
        case SOURCECOLUMN:
            return getSourceColumn();
        case FUNCTION1:
            return getFunction1();
        case AGGEGATABLE:
            return getAggegatable();
        case SORTABLE:
            return getSortable();
        case INCLUDEINSTANDARD:
            return getIncludeInStandard();
        case INCLUDEINCORE:
            return getIncludeInCore();
        case INCLUDEINDETAIL:
            return getIncludeInDetail();
        case DATATYPE:
            return getDataType();
        case DATAFORMAT:
            return getDataFormat();
        case FIELDLENGTH:
            return getFieldLength();
        case NONSTDRECORDLEVEL:
            return getNonStdRecordLevel();
        case USEINFILENAME:
            return getUseInFileName();
        case COMMENTS:
            return getComments();
        case NDTRECTYPECONST1:
            return getNdtRecTypeConst1();
        case NDTRECTYPECONST2:
            return getNdtRecTypeConst2();
        case NDTRECTYPECONST3:
            return getNdtRecTypeConst3();
        case NDTRECTYPECONST4:
            return getNdtRecTypeConst4();
        case NDTRECTYPECONST5:
            return getNdtRecTypeConst5();
        case NDTRECTYPECONST6:
            return getNdtRecTypeConst6();
        case RECORDER:
            return getRecOrder();
        case TARGETVALUE14:
            return getTargetValue14();
        case TARGETVALUE15:
            return getTargetValue15();
        case TARGETVALUE16:
            return getTargetValue16();
        case HEADERDETAIL:
            return getHeaderDetail();
        case AVAIINDATAEXTRACT:
            return getAvaiInDataExtract();
        case RECTYPE:
            return getRecType();
        case STAGINGTABLE:
            return getStagingTable();
        case DEFAULTSEQ:
            return getDefaultSeq();
        case FUNCTION1_1:
            return getFunction1_1();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case FIELDID:
            setFieldId((String)value);
            return;
        case FIELDNAME:
            setFieldName((String)value);
            return;
        case SOURCETABLE:
            setSourceTable((String)value);
            return;
        case SOURCECOLUMN:
            setSourceColumn((String)value);
            return;
        case FUNCTION1:
            setFunction1((String)value);
            return;
        case AGGEGATABLE:
            setAggegatable((String)value);
            return;
        case SORTABLE:
            setSortable((String)value);
            return;
        case INCLUDEINSTANDARD:
            setIncludeInStandard((String)value);
            return;
        case INCLUDEINCORE:
            setIncludeInCore((String)value);
            return;
        case INCLUDEINDETAIL:
            setIncludeInDetail((String)value);
            return;
        case DATATYPE:
            setDataType((String)value);
            return;
        case DATAFORMAT:
            setDataFormat((String)value);
            return;
        case FIELDLENGTH:
            setFieldLength((String)value);
            return;
        case NONSTDRECORDLEVEL:
            setNonStdRecordLevel((String)value);
            return;
        case USEINFILENAME:
            setUseInFileName((String)value);
            return;
        case COMMENTS:
            setComments((String)value);
            return;
        case NDTRECTYPECONST1:
            setNdtRecTypeConst1((String)value);
            return;
        case NDTRECTYPECONST2:
            setNdtRecTypeConst2((String)value);
            return;
        case NDTRECTYPECONST3:
            setNdtRecTypeConst3((String)value);
            return;
        case NDTRECTYPECONST4:
            setNdtRecTypeConst4((String)value);
            return;
        case NDTRECTYPECONST5:
            setNdtRecTypeConst5((String)value);
            return;
        case NDTRECTYPECONST6:
            setNdtRecTypeConst6((String)value);
            return;
        case RECORDER:
            setRecOrder((String)value);
            return;
        case TARGETVALUE14:
            setTargetValue14((String)value);
            return;
        case TARGETVALUE15:
            setTargetValue15((String)value);
            return;
        case TARGETVALUE16:
            setTargetValue16((String)value);
            return;
        case HEADERDETAIL:
            setHeaderDetail((String)value);
            return;
        case AVAIINDATAEXTRACT:
            setAvaiInDataExtract((String)value);
            return;
        case RECTYPE:
            setRecType((String)value);
            return;
        case STAGINGTABLE:
            setStagingTable((String)value);
            return;
        case DEFAULTSEQ:
            setDefaultSeq((String)value);
            return;
        case FUNCTION1_1:
            setFunction1_1((String)value);
            return;
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }

    /**Gets the attribute value for the calculated attribute SourceTable
     */
    public String getSourceTable() {
        return (String) getAttributeInternal(SOURCETABLE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute SourceTable
     */
    public void setSourceTable(String value) {
        setAttributeInternal(SOURCETABLE, value);
    }

    /**Gets the attribute value for the calculated attribute SourceColumn
     */
    public String getSourceColumn() {
        return (String) getAttributeInternal(SOURCECOLUMN);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute SourceColumn
     */
    public void setSourceColumn(String value) {
        setAttributeInternal(SOURCECOLUMN, value);
    }

    /**Gets the attribute value for the calculated attribute Function1
     */
    public String getFunction1() {
        return (String) getAttributeInternal(FUNCTION1);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Function1
     */
    public void setFunction1(String value) {
        setAttributeInternal(FUNCTION1, value);
    }

    /**Gets the attribute value for the calculated attribute Aggegatable
     */
    public String getAggegatable() {
        return (String) getAttributeInternal(AGGEGATABLE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Aggegatable
     */
    public void setAggegatable(String value) {
        setAttributeInternal(AGGEGATABLE, value);
    }

    /**Gets the attribute value for the calculated attribute Sortable
     */
    public String getSortable() {
        return (String) getAttributeInternal(SORTABLE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Sortable
     */
    public void setSortable(String value) {
        setAttributeInternal(SORTABLE, value);
    }

    /**Gets the attribute value for the calculated attribute IncludeInStandard
     */
    public String getIncludeInStandard() {
        return (String) getAttributeInternal(INCLUDEINSTANDARD);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute IncludeInStandard
     */
    public void setIncludeInStandard(String value) {
        setAttributeInternal(INCLUDEINSTANDARD, value);
    }

    /**Gets the attribute value for the calculated attribute DataType
     */
    public String getDataType() {
        return (String) getAttributeInternal(DATATYPE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute DataType
     */
    public void setDataType(String value) {
        setAttributeInternal(DATATYPE, value);
    }

    /**Gets the attribute value for the calculated attribute FieldLength
     */
    public String getFieldLength() {
        return (String) getAttributeInternal(FIELDLENGTH);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute FieldLength
     */
    public void setFieldLength(String value) {
        setAttributeInternal(FIELDLENGTH, value);
    }

    /**Gets the attribute value for the calculated attribute NonStdRecordLevel
     */
    public String getNonStdRecordLevel() {
        return (String) getAttributeInternal(NONSTDRECORDLEVEL);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NonStdRecordLevel
     */
    public void setNonStdRecordLevel(String value) {
        setAttributeInternal(NONSTDRECORDLEVEL, value);
    }

    /**Gets the attribute value for the calculated attribute UseInFileName
     */
    public String getUseInFileName() {
        return (String) getAttributeInternal(USEINFILENAME);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute UseInFileName
     */
    public void setUseInFileName(String value) {
        setAttributeInternal(USEINFILENAME, value);
    }

    /**Gets the attribute value for the calculated attribute Comments
     */
    public String getComments() {
        return (String) getAttributeInternal(COMMENTS);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Comments
     */
    public void setComments(String value) {
        setAttributeInternal(COMMENTS, value);
    }

    /**Gets the attribute value for the calculated attribute NdtRecTypeConst1
     */
    public String getNdtRecTypeConst1() {
        return (String) getAttributeInternal(NDTRECTYPECONST1);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NdtRecTypeConst1
     */
    public void setNdtRecTypeConst1(String value) {
        setAttributeInternal(NDTRECTYPECONST1, value);
    }

    /**Gets the attribute value for the calculated attribute NdtRecTypeConst2
     */
    public String getNdtRecTypeConst2() {
        return (String) getAttributeInternal(NDTRECTYPECONST2);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NdtRecTypeConst2
     */
    public void setNdtRecTypeConst2(String value) {
        setAttributeInternal(NDTRECTYPECONST2, value);
    }

    /**Gets the attribute value for the calculated attribute NdtRecTypeConst3
     */
    public String getNdtRecTypeConst3() {
        return (String) getAttributeInternal(NDTRECTYPECONST3);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NdtRecTypeConst3
     */
    public void setNdtRecTypeConst3(String value) {
        setAttributeInternal(NDTRECTYPECONST3, value);
    }

    /**Gets the attribute value for the calculated attribute NdtRecTypeConst4
     */
    public String getNdtRecTypeConst4() {
        return (String) getAttributeInternal(NDTRECTYPECONST4);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NdtRecTypeConst4
     */
    public void setNdtRecTypeConst4(String value) {
        setAttributeInternal(NDTRECTYPECONST4, value);
    }

    /**Gets the attribute value for the calculated attribute NdtRecTypeConst5
     */
    public String getNdtRecTypeConst5() {
        return (String) getAttributeInternal(NDTRECTYPECONST5);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NdtRecTypeConst5
     */
    public void setNdtRecTypeConst5(String value) {
        setAttributeInternal(NDTRECTYPECONST5, value);
    }

    /**Gets the attribute value for the calculated attribute NdtRecTypeConst6
     */
    public String getNdtRecTypeConst6() {
        return (String) getAttributeInternal(NDTRECTYPECONST6);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute NdtRecTypeConst6
     */
    public void setNdtRecTypeConst6(String value) {
        setAttributeInternal(NDTRECTYPECONST6, value);
    }

    /**Gets the attribute value for the calculated attribute RecOrder
     */
    public String getRecOrder() {
        return (String) getAttributeInternal(RECORDER);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute RecOrder
     */
    public void setRecOrder(String value) {
        setAttributeInternal(RECORDER, value);
    }

    /**Gets the attribute value for the calculated attribute TargetValue14
     */
    public String getTargetValue14() {
        return (String) getAttributeInternal(TARGETVALUE14);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute TargetValue14
     */
    public void setTargetValue14(String value) {
        setAttributeInternal(TARGETVALUE14, value);
    }

    /**Gets the attribute value for the calculated attribute TargetValue15
     */
    public String getTargetValue15() {
        return (String) getAttributeInternal(TARGETVALUE15);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute TargetValue15
     */
    public void setTargetValue15(String value) {
        setAttributeInternal(TARGETVALUE15, value);
    }

    /**Gets the attribute value for the calculated attribute TargetValue16
     */
    public String getTargetValue16() {
        return (String) getAttributeInternal(TARGETVALUE16);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute TargetValue16
     */
    public void setTargetValue16(String value) {
        setAttributeInternal(TARGETVALUE16, value);
    }

    /**Gets the attribute value for the calculated attribute HeaderDetail
     */
    public String getHeaderDetail() {
        return (String) getAttributeInternal(HEADERDETAIL);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute HeaderDetail
     */
    public void setHeaderDetail(String value) {
        setAttributeInternal(HEADERDETAIL, value);
    }

    /**Gets the attribute value for the calculated attribute AvaiInDataExtract
     */
    public String getAvaiInDataExtract() {
        return (String) getAttributeInternal(AVAIINDATAEXTRACT);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute AvaiInDataExtract
     */
    public void setAvaiInDataExtract(String value) {
        setAttributeInternal(AVAIINDATAEXTRACT, value);
    }

    /**Gets the attribute value for the calculated attribute RecType
     */
    public String getRecType() {
        return (String) getAttributeInternal(RECTYPE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute RecType
     */
    public void setRecType(String value) {
        setAttributeInternal(RECTYPE, value);
    }

    /**Gets the attribute value for the calculated attribute StagingTable
     */
    public String getStagingTable() {
        return (String) getAttributeInternal(STAGINGTABLE);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute StagingTable
     */
    public void setStagingTable(String value) {
        setAttributeInternal(STAGINGTABLE, value);
    }

    /**Gets the attribute value for the calculated attribute Function1_1
     */
    public String getFunction1_1() {
        return (String) getAttributeInternal(FUNCTION1_1);
    }

    /**Sets <code>value</code> as the attribute value for the calculated attribute Function1_1
     */
    public void setFunction1_1(String value) {
        setAttributeInternal(FUNCTION1_1, value);
    }
}
