package od.tdmatch.model.reports.vo.lov;

import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Sat Dec 02 22:33:18 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class SourceLOVRowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        LookupCode;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return SourceLOVRowImpl.AttributesEnum.firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return SourceLOVRowImpl.AttributesEnum.firstIndex() + SourceLOVRowImpl.AttributesEnum
                                                                                  .staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = SourceLOVRowImpl.AttributesEnum.values();
            }
            return vals;
        }
    }

    public static final int LOOKUPCODE = AttributesEnum.LookupCode.index();

    /**
     * This is the default constructor (do not remove).
     */
    public SourceLOVRowImpl() {
    }
}

