package od.tdmatch.model.reports.vo;

import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Fri Nov 03 00:45:19 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class XxApRTVReconTotalVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        System,
        Regular,
        Opt73Weekly,
        Opt73Monthly,
        Opt73Qtrly,
        Total;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return XxApRTVReconTotalVORowImpl.AttributesEnum.firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return XxApRTVReconTotalVORowImpl.AttributesEnum.firstIndex() + XxApRTVReconTotalVORowImpl.AttributesEnum
                                                                                                      .staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = XxApRTVReconTotalVORowImpl.AttributesEnum.values();
            }
            return vals;
        }
    }
    public static final int SYSTEM = AttributesEnum.System.index();
    public static final int REGULAR = AttributesEnum.Regular.index();
    public static final int OPT73WEEKLY = AttributesEnum.Opt73Weekly.index();
    public static final int OPT73MONTHLY = AttributesEnum.Opt73Monthly.index();
    public static final int OPT73QTRLY = AttributesEnum.Opt73Qtrly.index();
    public static final int TOTAL = AttributesEnum.Total.index();

    /**
     * This is the default constructor (do not remove).
     */
    public XxApRTVReconTotalVORowImpl() {
    }
}

