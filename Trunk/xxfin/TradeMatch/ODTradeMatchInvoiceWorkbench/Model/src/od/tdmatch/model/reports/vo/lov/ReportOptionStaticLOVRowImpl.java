package od.tdmatch.model.reports.vo.lov;

import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Tue Oct 03 18:03:56 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class ReportOptionStaticLOVRowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        Id,
        Value;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return od.tdmatch
                     .model
                     .reports
                     .vo
                     .lov
                     .ReportOptionStaticLOVRowImpl
                     .AttributesEnum
                     .firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return od.tdmatch
                     .model
                     .reports
                     .vo
                     .lov
                     .ReportOptionStaticLOVRowImpl
                     .AttributesEnum
                     .firstIndex() + od.tdmatch
                                       .model
                                       .reports
                                       .vo
                                       .lov
                                       .ReportOptionStaticLOVRowImpl
                                       .AttributesEnum
                                       .staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = od.tdmatch
                         .model
                         .reports
                         .vo
                         .lov
                         .ReportOptionStaticLOVRowImpl
                         .AttributesEnum
                         .values();
            }
            return vals;
        }
    }
    public static final int ID = AttributesEnum.Id.index();
    public static final int VALUE = AttributesEnum.Value.index();

    /**
     * This is the default constructor (do not remove).
     */
    public ReportOptionStaticLOVRowImpl() {
    }
}

