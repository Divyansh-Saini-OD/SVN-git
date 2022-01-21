package od.oracle.apps.xxfin.ap.idms.traitmaster.schema.server;

import oracle.apps.fnd.framework.server.OAEntityDefImpl;
import oracle.apps.fnd.framework.server.OAEntityImpl;

import oracle.jbo.Key;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.EntityDefImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class XxApSupTraitsEOImpl extends OAEntityImpl {


    public static final int SUPTRAIT = 0;
    public static final int DESCRIPTION = 1;
    public static final int MASTERSUPIND = 2;
    public static final int MASTERSUP = 3;
    public static final int ATTRIBUTE1 = 4;
    public static final int ATTRIBUTE2 = 5;
    public static final int ATTRIBUTE3 = 6;
    public static final int ATTRIBUTE4 = 7;
    public static final int ATTRIBUTE5 = 8;
    public static final int ATTRIBUTE6 = 9;
    public static final int CREATIONDATE = 10;
    public static final int CREATEDBY = 11;
    public static final int LASTUPDATEDATE = 12;
    public static final int LASTUPDATEDBY = 13;
    public static final int LASTUPDATELOGIN = 14;
    public static final int ENABLEFLAG = 15;
    public static final int SUPTRAITID = 16;
    private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

    /**Gets the attribute value for SupTraitId, using the alias name SupTraitId
     */
    public Number getSupTraitId() {
        return (Number)getAttributeInternal(SUPTRAITID);
    }

    /**Sets <code>value</code> as the attribute value for SupTraitId
     */
    public void setSupTraitId(Number value) {
        setAttributeInternal(SUPTRAITID, value);
    }

    /**Creates a Key object based on given key constituents
     */
    public static Key createPrimaryKey(Number supTrait) {
        return new Key(new Object[]{supTrait});
    }


    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. Do not modify.
     */
    public enum AttributesEnum {
        SupTrait {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getSupTrait();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setSupTrait((Number)value);
            }
        }
        ,
        Description {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getDescription();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setDescription((String)value);
            }
        }
        ,
        MasterSupInd {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getMasterSupInd();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setMasterSupInd((String)value);
            }
        }
        ,
        MasterSup {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getMasterSup();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setMasterSup((String)value);
            }
        }
        ,
        Attribute1 {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getAttribute1();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setAttribute1((String)value);
            }
        }
        ,
        Attribute2 {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getAttribute2();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setAttribute2((String)value);
            }
        }
        ,
        Attribute3 {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getAttribute3();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setAttribute3((String)value);
            }
        }
        ,
        Attribute4 {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getAttribute4();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setAttribute4((String)value);
            }
        }
        ,
        Attribute5 {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getAttribute5();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setAttribute5((String)value);
            }
        }
        ,
        Attribute6 {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getAttribute6();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setAttribute6((String)value);
            }
        }
        ,
        CreationDate {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getCreationDate();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setCreationDate((Date)value);
            }
        }
        ,
        CreatedBy {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getCreatedBy();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setCreatedBy((Number)value);
            }
        }
        ,
        LastUpdateDate {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getLastUpdateDate();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setLastUpdateDate((Date)value);
            }
        }
        ,
        LastUpdatedBy {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getLastUpdatedBy();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setLastUpdatedBy((Number)value);
            }
        }
        ,
        LastUpdateLogin {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getLastUpdateLogin();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setLastUpdateLogin((Number)value);
            }
        }
        ,
        EnableFlag {
            public Object get(XxApSupTraitsEOImpl obj) {
                return obj.getEnableFlag();
            }

            public void put(XxApSupTraitsEOImpl obj, Object value) {
                obj.setEnableFlag((String)value);
            }
        }
        ;
        private static AttributesEnum[] vals = null;
        private static int firstIndex = 0;

        public abstract Object get(XxApSupTraitsEOImpl object);

        public abstract void put(XxApSupTraitsEOImpl object, Object value);

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
    public XxApSupTraitsEOImpl() {
    }


    /**Retrieves the definition object for this instance class.
     */
    public static synchronized EntityDefImpl getDefinitionObject() {
        if (mDefinitionObject == null) {
            mDefinitionObject = 
                    (OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxfin.ap.idms.traitmaster.schema.server.XxApSupTraitsEO");
        }
        return mDefinitionObject;
    }

    /**Gets the attribute value for SupTrait, using the alias name SupTrait
     */
    public Number getSupTrait() {
        return (Number)getAttributeInternal(SUPTRAIT);
    }

    /**Sets <code>value</code> as the attribute value for SupTrait
     */
    public void setSupTrait(Number value) {
        setAttributeInternal(SUPTRAIT, value);
    }

    /**Gets the attribute value for Description, using the alias name Description
     */
    public String getDescription() {
        return (String)getAttributeInternal(DESCRIPTION);
    }

    /**Sets <code>value</code> as the attribute value for Description
     */
    public void setDescription(String value) {
        setAttributeInternal(DESCRIPTION, value);
    }

    /**Gets the attribute value for MasterSupInd, using the alias name MasterSupInd
     */
    public String getMasterSupInd() {
        return (String)getAttributeInternal(MASTERSUPIND);
    }

    /**Sets <code>value</code> as the attribute value for MasterSupInd
     */
    public void setMasterSupInd(String value) {
        setAttributeInternal(MASTERSUPIND, value);
    }

    /**Gets the attribute value for MasterSup, using the alias name MasterSup
     */
    public String getMasterSup() {
        return (String)getAttributeInternal(MASTERSUP);
    }

    /**Sets <code>value</code> as the attribute value for MasterSup
     */
    public void setMasterSup(String value) {
        setAttributeInternal(MASTERSUP, value);
    }

    /**Gets the attribute value for Attribute1, using the alias name Attribute1
     */
    public String getAttribute1() {
        return (String)getAttributeInternal(ATTRIBUTE1);
    }

    /**Sets <code>value</code> as the attribute value for Attribute1
     */
    public void setAttribute1(String value) {
        setAttributeInternal(ATTRIBUTE1, value);
    }

    /**Gets the attribute value for Attribute2, using the alias name Attribute2
     */
    public String getAttribute2() {
        return (String)getAttributeInternal(ATTRIBUTE2);
    }

    /**Sets <code>value</code> as the attribute value for Attribute2
     */
    public void setAttribute2(String value) {
        setAttributeInternal(ATTRIBUTE2, value);
    }

    /**Gets the attribute value for Attribute3, using the alias name Attribute3
     */
    public String getAttribute3() {
        return (String)getAttributeInternal(ATTRIBUTE3);
    }

    /**Sets <code>value</code> as the attribute value for Attribute3
     */
    public void setAttribute3(String value) {
        setAttributeInternal(ATTRIBUTE3, value);
    }

    /**Gets the attribute value for Attribute4, using the alias name Attribute4
     */
    public String getAttribute4() {
        return (String)getAttributeInternal(ATTRIBUTE4);
    }

    /**Sets <code>value</code> as the attribute value for Attribute4
     */
    public void setAttribute4(String value) {
        setAttributeInternal(ATTRIBUTE4, value);
    }

    /**Gets the attribute value for Attribute5, using the alias name Attribute5
     */
    public String getAttribute5() {
        return (String)getAttributeInternal(ATTRIBUTE5);
    }

    /**Sets <code>value</code> as the attribute value for Attribute5
     */
    public void setAttribute5(String value) {
        setAttributeInternal(ATTRIBUTE5, value);
    }

    /**Gets the attribute value for Attribute6, using the alias name Attribute6
     */
    public String getAttribute6() {
        return (String)getAttributeInternal(ATTRIBUTE6);
    }

    /**Sets <code>value</code> as the attribute value for Attribute6
     */
    public void setAttribute6(String value) {
        setAttributeInternal(ATTRIBUTE6, value);
    }

    /**Gets the attribute value for CreationDate, using the alias name CreationDate
     */
    public Date getCreationDate() {
        return (Date)getAttributeInternal(CREATIONDATE);
    }

    /**Sets <code>value</code> as the attribute value for CreationDate
     */
    public void setCreationDate(Date value) {
        setAttributeInternal(CREATIONDATE, value);
    }

    /**Gets the attribute value for CreatedBy, using the alias name CreatedBy
     */
    public Number getCreatedBy() {
        return (Number)getAttributeInternal(CREATEDBY);
    }

    /**Sets <code>value</code> as the attribute value for CreatedBy
     */
    public void setCreatedBy(Number value) {
        setAttributeInternal(CREATEDBY, value);
    }

    /**Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
     */
    public Date getLastUpdateDate() {
        return (Date)getAttributeInternal(LASTUPDATEDATE);
    }

    /**Sets <code>value</code> as the attribute value for LastUpdateDate
     */
    public void setLastUpdateDate(Date value) {
        setAttributeInternal(LASTUPDATEDATE, value);
    }

    /**Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
     */
    public Number getLastUpdatedBy() {
        return (Number)getAttributeInternal(LASTUPDATEDBY);
    }

    /**Sets <code>value</code> as the attribute value for LastUpdatedBy
     */
    public void setLastUpdatedBy(Number value) {
        setAttributeInternal(LASTUPDATEDBY, value);
    }

    /**Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
     */
    public Number getLastUpdateLogin() {
        return (Number)getAttributeInternal(LASTUPDATELOGIN);
    }

    /**Sets <code>value</code> as the attribute value for LastUpdateLogin
     */
    public void setLastUpdateLogin(Number value) {
        setAttributeInternal(LASTUPDATELOGIN, value);
    }

    /**Gets the attribute value for EnableFlag, using the alias name EnableFlag
     */
    public String getEnableFlag() {
        return (String)getAttributeInternal(ENABLEFLAG);
    }

    /**Sets <code>value</code> as the attribute value for EnableFlag
     */
    public void setEnableFlag(String value) {
        setAttributeInternal(ENABLEFLAG, value);
    }

    /**getAttrInvokeAccessor: generated method. Do not modify.
     */
    protected Object getAttrInvokeAccessor(int index, 
                                           AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case SUPTRAIT:
            return getSupTrait();
        case DESCRIPTION:
            return getDescription();
        case MASTERSUPIND:
            return getMasterSupInd();
        case MASTERSUP:
            return getMasterSup();
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
        case CREATIONDATE:
            return getCreationDate();
        case CREATEDBY:
            return getCreatedBy();
        case LASTUPDATEDATE:
            return getLastUpdateDate();
        case LASTUPDATEDBY:
            return getLastUpdatedBy();
        case LASTUPDATELOGIN:
            return getLastUpdateLogin();
        case ENABLEFLAG:
            return getEnableFlag();
        case SUPTRAITID:
            return getSupTraitId();
        default:
            return super.getAttrInvokeAccessor(index, attrDef);
        }
    }

    /**setAttrInvokeAccessor: generated method. Do not modify.
     */
    protected void setAttrInvokeAccessor(int index, Object value, 
                                         AttributeDefImpl attrDef) throws Exception {
        switch (index) {
        case SUPTRAIT:
            setSupTrait((Number)value);
            return;
        case DESCRIPTION:
            setDescription((String)value);
            return;
        case MASTERSUPIND:
            setMasterSupInd((String)value);
            return;
        case MASTERSUP:
            setMasterSup((String)value);
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
        case CREATIONDATE:
            setCreationDate((Date)value);
            return;
        case CREATEDBY:
            setCreatedBy((Number)value);
            return;
        case LASTUPDATEDATE:
            setLastUpdateDate((Date)value);
            return;
        case LASTUPDATEDBY:
            setLastUpdatedBy((Number)value);
            return;
        case LASTUPDATELOGIN:
            setLastUpdateLogin((Number)value);
            return;
        case ENABLEFLAG:
            setEnableFlag((String)value);
            return;
        case SUPTRAITID:
            setSupTraitId((Number)value);
            return;
        default:
            super.setAttrInvokeAccessor(index, value, attrDef);
            return;
        }
    }


}
