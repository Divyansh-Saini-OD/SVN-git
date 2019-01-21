package od.tdmatch.model.reports.vo.lov;

import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Sun Dec 03 00:43:30 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class PaymentStatusLOVRowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        PaymentStatus,
        PaymentStatusFlag;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return PaymentStatusLOVRowImpl.AttributesEnum.firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return PaymentStatusLOVRowImpl.AttributesEnum.firstIndex() + PaymentStatusLOVRowImpl.AttributesEnum
                                                                                                .staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = PaymentStatusLOVRowImpl.AttributesEnum.values();
            }
            return vals;
        }
    }

    public static final int PAYMENTSTATUS = AttributesEnum.PaymentStatus.index();
    public static final int PAYMENTSTATUSFLAG = AttributesEnum.PaymentStatusFlag.index();

    /**
     * This is the default constructor (do not remove).
     */
    public PaymentStatusLOVRowImpl() {
    }
}

