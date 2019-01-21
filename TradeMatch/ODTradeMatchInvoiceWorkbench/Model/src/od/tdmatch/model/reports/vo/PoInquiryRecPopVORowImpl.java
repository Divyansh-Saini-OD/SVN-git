package od.tdmatch.model.reports.vo;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.ViewRowImpl;
// ---------------------------------------------------------------------
// ---    File generated by Oracle ADF Business Components Design Time.
// ---    Sun Dec 03 16:44:16 IST 2017
// ---    Custom code may be added to this class.
// ---    Warning: Do not modify method signatures of generated methods.
// ---------------------------------------------------------------------
public class PoInquiryRecPopVORowImpl extends ViewRowImpl {
    /**
     * AttributesEnum: generated enum for identifying attributes and accessors. DO NOT MODIFY.
     */
    protected enum AttributesEnum {
        ReceiptNumber,
        ReceiptDate,
        Qty;
        private static AttributesEnum[] vals = null;
        private static final int firstIndex = 0;

        protected int index() {
            return PoInquiryRecPopVORowImpl.AttributesEnum.firstIndex() + ordinal();
        }

        protected static final int firstIndex() {
            return firstIndex;
        }

        protected static int count() {
            return PoInquiryRecPopVORowImpl.AttributesEnum.firstIndex() + PoInquiryRecPopVORowImpl.AttributesEnum
                                                                                                  .staticValues().length;
        }

        protected static final AttributesEnum[] staticValues() {
            if (vals == null) {
                vals = PoInquiryRecPopVORowImpl.AttributesEnum.values();
            }
            return vals;
        }
    }


    public static final int RECEIPTNUMBER = AttributesEnum.ReceiptNumber.index();
    public static final int RECEIPTDATE = AttributesEnum.ReceiptDate.index();
    public static final int QTY = AttributesEnum.Qty.index();

    /**
     * This is the default constructor (do not remove).
     */
    public PoInquiryRecPopVORowImpl() {
    }
}

