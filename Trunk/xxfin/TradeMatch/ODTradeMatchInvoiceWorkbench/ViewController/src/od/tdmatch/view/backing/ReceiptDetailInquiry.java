package od.tdmatch.view.backing;

import com.od.external.model.bean.FndUserBean;

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;

import od.tdmatch.model.reports.vo.XxApReceiptDetailInquirySearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.share.ADFContext;
import oracle.adf.view.rich.component.rich.RichDialog;
import oracle.adf.view.rich.component.rich.RichPopup;
import oracle.adf.view.rich.component.rich.data.RichTable;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputText;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.layout.RichPanelLabelAndMessage;
import oracle.adf.view.rich.component.rich.nav.RichButton;
import oracle.adf.view.rich.component.rich.nav.RichLink;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.component.rich.output.RichPanelCollection;
import oracle.adf.view.rich.component.rich.output.RichSpacer;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;

public class ReceiptDetailInquiry {
    private static final Logger logger = Logger.getLogger(ReceiptDetailInquiry.class.getName());
    private RichPanelGroupLayout searchAreaBind;
    private RichPanelLabelAndMessage plam1;
    private RichInputListOfValues suppliernameId;
    private RichPanelLabelAndMessage plam2;
    private RichInputListOfValues suppliersiteId;
    private RichPanelGroupLayout pgl3;
    private RichPanelGroupLayout pg20;
    private RichSpacer s1;
    private RichSpacer s2;
    private RichSpacer s3;
    private RichSpacer s4;
    private RichSpacer s5;
    private RichPanelLabelAndMessage plam3;
    private RichSpacer s6;
    private RichSpacer s7;
    private RichInputListOfValues skuId;
    private RichPanelGroupLayout pgl4;
    private RichPanelLabelAndMessage plam4;
    private RichInputListOfValues invoiceId;
    private RichSpacer s8;
    private RichSpacer s9;
    private RichPanelLabelAndMessage plam5;
    private RichInputListOfValues poId;
    private RichSpacer s10;
    private RichPanelLabelAndMessage plam6;
    private RichPanelLabelAndMessage plam7;
    private RichSpacer s11;
    private RichPanelGroupLayout pgl5;
    private RichPanelGroupLayout pgl6;
    private RichPanelLabelAndMessage plam8;
    private RichInputDate dateFrom;
    private RichInputDate dateTo;
    private RichPanelGroupLayout pgl7;
    private RichPanelLabelAndMessage plam9;
    private RichButton b1;

    private RichSpacer s12;
    private RichButton b2;
    private RichSpacer s13;
    private RichSpacer s14;
    private RichInputListOfValues ilov1;
    private RichSpacer s15;
    private RichSpacer s16;
    private RichSpacer s17;
    private RichSpacer s18;
    private RichSpacer s19;
    private RichSpacer s20;
    private RichInputListOfValues receiptId;
    private RichTable t1;
    private RichTable t2;
    private RichPanelCollection pc1;
    private RichPanelCollection recDtlPC;
    private RichOutputText ot39;
    private RichOutputText ot40;
    private RichPopup p1;
    private RichDialog d1;
    private RichTable t3;
    private RichOutputText ot45;
    private RichLink invNumBind;
    private RichTable t4;
    private RichOutputText ot46;
    private RichOutputText ot49;
    private RichSpacer s21;
    private RichOutputText ot431;
    private RichInputText it1;
    private RichOutputText recordCountOuput;

    public ReceiptDetailInquiry() {
        logger.warning("Calling ReceiptDetailInquiry-------- ");
        Map sessionScope = ADFContext.getCurrent().getSessionScope();
        FndUserBean fndUser = (FndUserBean) sessionScope.get("fndUserBean");
        if (fndUser != null) {

            logger.warning("Calling ReceiptDetailInquiry getUserName: " + fndUser.getUserName());
            System.out.println("Calling ReceiptDetailInquiry getUserName: " + fndUser.getUserName());

            user_id = fndUser.getUserName();


        }

        if ("".equals(user_id) || user_id == null) {
            user_id = "881748";
        }
    }

    public void setPlam1(RichPanelLabelAndMessage plam1) {
        this.plam1 = plam1;
    }

    public RichPanelLabelAndMessage getPlam1() {
        return plam1;
    }

    public void setSuppliernameId(RichInputListOfValues suppliernameId) {
        this.suppliernameId = suppliernameId;
    }

    public RichInputListOfValues getSuppliernameId() {
        return suppliernameId;
    }

    public void setPlam2(RichPanelLabelAndMessage plam2) {
        this.plam2 = plam2;
    }

    public RichPanelLabelAndMessage getPlam2() {
        return plam2;
    }

    public void setSuppliersiteId(RichInputListOfValues suppliersiteId) {
        this.suppliersiteId = suppliersiteId;
    }

    public RichInputListOfValues getSuppliersiteId() {
        return suppliersiteId;
    }

    public void setPgl3(RichPanelGroupLayout pgl3) {
        this.pgl3 = pgl3;
    }

    public RichPanelGroupLayout getPgl3() {
        return pgl3;
    }

    public void setS1(RichSpacer s1) {
        this.s1 = s1;
    }

    public RichSpacer getS1() {
        return s1;
    }

    public void setUser_id(String user_id) {
        this.user_id = user_id;
    }

    public String getUser_id() {
        return user_id;
    }

    public void setS2(RichSpacer s2) {
        this.s2 = s2;
    }

    public RichSpacer getS2() {
        return s2;
    }

    public void setS3(RichSpacer s3) {
        this.s3 = s3;
    }

    public RichSpacer getS3() {
        return s3;
    }

    public void setS4(RichSpacer s4) {
        this.s4 = s4;
    }

    public RichSpacer getS4() {
        return s4;
    }

    public void setS5(RichSpacer s5) {
        this.s5 = s5;
    }

    public RichSpacer getS5() {
        return s5;
    }

    public void setPlam3(RichPanelLabelAndMessage plam3) {
        this.plam3 = plam3;
    }

    public RichPanelLabelAndMessage getPlam3() {
        return plam3;
    }

    public void setS6(RichSpacer s6) {
        this.s6 = s6;
    }

    public RichSpacer getS6() {
        return s6;
    }

    public void setS7(RichSpacer s7) {
        this.s7 = s7;
    }

    public RichSpacer getS7() {
        return s7;
    }

    public void setSkuId(RichInputListOfValues skuId) {
        this.skuId = skuId;
    }

    public RichInputListOfValues getSkuId() {
        return skuId;
    }

    public void setPgl4(RichPanelGroupLayout pgl4) {
        this.pgl4 = pgl4;
    }

    public RichPanelGroupLayout getPgl4() {
        return pgl4;
    }

    public void setPlam4(RichPanelLabelAndMessage plam4) {
        this.plam4 = plam4;
    }

    public RichPanelLabelAndMessage getPlam4() {
        return plam4;
    }

    public void setInvoiceId(RichInputListOfValues invoiceId) {
        this.invoiceId = invoiceId;
    }

    public RichInputListOfValues getInvoiceId() {
        return invoiceId;
    }

    public void setS8(RichSpacer s8) {
        this.s8 = s8;
    }

    public RichSpacer getS8() {
        return s8;
    }

    public void setS9(RichSpacer s9) {
        this.s9 = s9;
    }

    public RichSpacer getS9() {
        return s9;
    }

    public void setPlam5(RichPanelLabelAndMessage plam5) {
        this.plam5 = plam5;
    }

    public RichPanelLabelAndMessage getPlam5() {
        return plam5;
    }

    public void setPoId(RichInputListOfValues poId) {
        this.poId = poId;
    }

    public RichInputListOfValues getPoId() {
        return poId;
    }

    public void setS10(RichSpacer s10) {
        this.s10 = s10;
    }

    public RichSpacer getS10() {
        return s10;
    }

    public void setPlam6(RichPanelLabelAndMessage plam6) {
        this.plam6 = plam6;
    }

    public RichPanelLabelAndMessage getPlam6() {
        return plam6;
    }

    public void setPlam7(RichPanelLabelAndMessage plam7) {
        this.plam7 = plam7;
    }

    public RichPanelLabelAndMessage getPlam7() {
        return plam7;
    }

    public void setS11(RichSpacer s11) {
        this.s11 = s11;
    }

    public RichSpacer getS11() {
        return s11;
    }

    public void setPgl5(RichPanelGroupLayout pgl5) {
        this.pgl5 = pgl5;
    }

    public RichPanelGroupLayout getPgl5() {
        return pgl5;
    }

    public void setPgl6(RichPanelGroupLayout pgl6) {
        this.pgl6 = pgl6;
    }

    public RichPanelGroupLayout getPgl6() {
        return pgl6;
    }

    public void setPlam8(RichPanelLabelAndMessage plam8) {
        this.plam8 = plam8;
    }

    public RichPanelLabelAndMessage getPlam8() {
        return plam8;
    }

    public void setPgl7(RichPanelGroupLayout pgl7) {
        this.pgl7 = pgl7;
    }

    public RichPanelGroupLayout getPgl7() {
        return pgl7;
    }

    public void setPlam9(RichPanelLabelAndMessage plam9) {
        this.plam9 = plam9;
    }

    public RichPanelLabelAndMessage getPlam9() {
        return plam9;
    }


    public void setB1(RichButton b1) {
        this.b1 = b1;
    }

    public RichButton getB1() {
        return b1;
    }


    public void setS12(RichSpacer s12) {
        this.s12 = s12;
    }

    public RichSpacer getS12() {
        return s12;
    }

    public void setB2(RichButton b2) {
        this.b2 = b2;
    }

    public RichButton getB2() {
        return b2;
    }

    public void setS13(RichSpacer s13) {
        this.s13 = s13;
    }

    public RichSpacer getS13() {
        return s13;
    }

    public void setS14(RichSpacer s14) {
        this.s14 = s14;
    }

    public RichSpacer getS14() {
        return s14;
    }

    public void setIlov1(RichInputListOfValues ilov1) {
        this.ilov1 = ilov1;
    }

    public RichInputListOfValues getIlov1() {
        return ilov1;
    }

    public void setS15(RichSpacer s15) {
        this.s15 = s15;
    }

    public RichSpacer getS15() {
        return s15;
    }

    public void setS16(RichSpacer s16) {
        this.s16 = s16;
    }

    public RichSpacer getS16() {
        return s16;
    }

    public void setS17(RichSpacer s17) {
        this.s17 = s17;
    }

    public RichSpacer getS17() {
        return s17;
    }

    public void setS18(RichSpacer s18) {
        this.s18 = s18;
    }

    public RichSpacer getS18() {
        return s18;
    }

    public void setS19(RichSpacer s19) {
        this.s19 = s19;
    }

    public RichSpacer getS19() {
        return s19;
    }

    public void setS20(RichSpacer s20) {
        this.s20 = s20;
    }

    public RichSpacer getS20() {
        return s20;
    }


    public void setReceiptId(RichInputListOfValues receiptId) {
        this.receiptId = receiptId;
    }

    public RichInputListOfValues getReceiptId() {
        return receiptId;
    }

    public void setT1(RichTable t1) {
        this.t1 = t1;
    }

    public RichTable getT1() {
        return t1;
    }
    String user_id = "";
    //    public void getUserID(){
    //        FacesContext fctx = FacesContext.getCurrentInstance();
    //               HttpServletRequest request = (HttpServletRequest)fctx.getExternalContext().getRequest();
    //               HttpSession session1 = request.getSession();
    //               String user_id= (String)session1.getValue("userName");
    //               System.out.println(user_id);
    //
    //    }

    public void searchReceiptAction() {
        String errMsg = "";
        FacesContext faceCont = FacesContext.getCurrentInstance();
        //        if( suppliernameId.getValue()==null){
        //
        //            errMsg = "Please enter Supplier Name.";
        //            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
        //
        //
        //            faceCont.addMessage("ERROR", errorMsg);
        //        }else{

        int userVal = 0;

        if (user_id != null) {
            userVal = Integer.parseInt(user_id);
        }


        if ((dateFrom.getValue() == null || dateTo.getValue() == null) && poId.getValue() == null &&
            invoiceId.getValue() == null && receiptId.getValue() == null) {


            errMsg = "Please enter Date Range Or  PO Number";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);

            return;

        } else {

            oracle.jbo.domain.Date toDateUtil = (oracle.jbo.domain.Date) dateFrom.getValue();
            oracle.jbo.domain.Date fromDateUtil = (oracle.jbo.domain.Date) dateTo.getValue();
           System.err.println("getDifferenceDaysBetweenTwoDates>>>>>"+getDifferenceDaysBetweenTwoDates(fromDateUtil,toDateUtil));
            System.err.println(" suppliersiteId.getValue()"+ suppliersiteId.getValue());
            System.err.println(" skuId.getValue()"+ skuId.getValue());
            System.err.println(" poId.getValue()"+ poId.getValue());
        
            System.err.println(" invoiceId.getValue()"+ invoiceId.getValue());
            System.err.println(" receiptId.getValue()"+ receiptId.getValue());
           
            

            if (getDifferenceDaysBetweenTwoDates(fromDateUtil,toDateUtil)!=0 && suppliersiteId.getValue() == null &&  skuId.getValue()==""  && poId.getValue() == null &&
            invoiceId.getValue() == null && receiptId.getValue() == null) {

                errMsg = "Date Range is more than one day, please enter Supplier Site or SKU";
                FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);

                faceCont.addMessage("ERROR", errorMsg);

                return;
            }
                 

            if (getDifferenceDaysBetweenTwoDates(fromDateUtil,toDateUtil)>30 && (suppliersiteId.getValue() != null ||  skuId.getValue()!="") &&   poId.getValue() == null &&
            invoiceId.getValue() == null && receiptId.getValue() == null) {

                errMsg = "Date Range is more than 31 Days, Please give lesser date range";
                FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);

                faceCont.addMessage("ERROR", errorMsg);

                return;
            }

            if (getDifferenceDaysBetweenTwoDates(fromDateUtil,toDateUtil) > 6 &&getDifferenceDaysBetweenTwoDates(fromDateUtil,toDateUtil)<=30 && (suppliersiteId.getValue() != null ||  skuId.getValue()!="")  && poId.getValue() == null &&
            invoiceId.getValue() == null && receiptId.getValue() == null) {
                
                
                OperationBinding opBindSearchReasonCode = ADFUtils.findOperation("searchReceiptDetInqConReq");
                opBindSearchReasonCode.getParamsMap().put("userId", userVal);
                opBindSearchReasonCode.execute();
                String value = (String) opBindSearchReasonCode.getResult();
                System.out.println("the value of value is : : " + value);

               
              
                FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_INFO, value, null);

                faceCont.addMessage("INFO", errorMsg);
                
                return;

            }            
            
          
            
            
            else {

                OperationBinding opBindSearchReasonCode = ADFUtils.findOperation("searchReceiptDetailInquiry");
                opBindSearchReasonCode.getParamsMap().put("userId", userVal);
                opBindSearchReasonCode.execute();
                String value = (String) opBindSearchReasonCode.getResult();
                System.out.println("the value of value is : : " + value);

                DCIteratorBinding iteratValue = ADFUtils.findIterator("XxApReceiptDetailSummaryVO3Iterator");

                if ("Y".equals(value)) {
                    t2.setRendered(false);
                    t4.setRendered(true);

                    iteratValue.executeQuery();


                } else {
                    t2.setRendered(true);
                    t4.setRendered(false);

                }
            }
            AdfFacesContext.getCurrentInstance().addPartialTarget(pg20);
            AdfFacesContext.getCurrentInstance().addPartialTarget(recDtlPC);

        }
        //  }
    }

    public void setT2(RichTable t2) {
        this.t2 = t2;
    }

    public RichTable getT2() {
        return t2;
    }


    public void setPg20(RichPanelGroupLayout pg20) {
        this.pg20 = pg20;
    }

    public RichPanelGroupLayout getPg20() {
        return pg20;
    }

    public void setPc1(RichPanelCollection pc1) {
        this.pc1 = pc1;
    }

    public RichPanelCollection getPc1() {
        return pc1;
    }

    public void setRecDtlPC(RichPanelCollection recDtlPC) {
        this.recDtlPC = recDtlPC;
    }

    public RichPanelCollection getRecDtlPC() {
        return recDtlPC;
    }

    public void setOt39(RichOutputText ot39) {
        this.ot39 = ot39;
    }

    public RichOutputText getOt39() {
        return ot39;
    }

    public void setOt40(RichOutputText ot40) {
        this.ot40 = ot40;
    }

    public RichOutputText getOt40() {
        return ot40;
    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public String ClearReceiptDetailAction() {
        System.out.println("the clear method is called//");


        //suppBind.setSubmittedValue(null);
        suppliernameId.setSubmittedValue(null);
        suppliersiteId.setSubmittedValue(null);
        invoiceId.setSubmittedValue(null);
        skuId.setSubmittedValue(null);
        dateFrom.setSubmittedValue(null);
        dateTo.setSubmittedValue(null);
        poId.setSubmittedValue(null);
        receiptId.setSubmittedValue(null);
        DCIteratorBinding orderSearchIterBind =
            (DCIteratorBinding) getBindings().get("XxApReceiptDetailInquirySearchVO1Iterator");
        XxApReceiptDetailInquirySearchVORowImpl row =
            (XxApReceiptDetailInquirySearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApReceiptDetailInquirySearchVORowImpl newRow =
            (XxApReceiptDetailInquirySearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
        orderSearchIterBind.getRowSetIterator().insertRow(newRow);

        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);

        return null;
    }

    public void setSearchAreaBind(RichPanelGroupLayout searchAreaBind) {
        this.searchAreaBind = searchAreaBind;
    }

    public RichPanelGroupLayout getSearchAreaBind() {
        return searchAreaBind;
    }

    public void setDateFrom(RichInputDate dateFrom) {
        this.dateFrom = dateFrom;
    }

    public RichInputDate getDateFrom() {
        return dateFrom;
    }

    public void setDateTo(RichInputDate dateTo) {
        this.dateTo = dateTo;
    }

    public RichInputDate getDateTo() {
        return dateTo;
    }

    public void setP1(RichPopup p1) {
        this.p1 = p1;
    }

    public RichPopup getP1() {
        return p1;
    }

    public void setD1(RichDialog d1) {
        this.d1 = d1;
    }

    public RichDialog getD1() {
        return d1;
    }

    public void setT3(RichTable t3) {
        this.t3 = t3;
    }

    public RichTable getT3() {
        return t3;
    }

    public void setOt45(RichOutputText ot45) {
        this.ot45 = ot45;
    }

    public RichOutputText getOt45() {
        return ot45;
    }

    public void setInvNumBind(RichLink invNumBind) {
        this.invNumBind = invNumBind;
    }

    public RichLink getInvNumBind() {
        return invNumBind;
    }


    HashMap searchMap = null;

    @SuppressWarnings("unchecked")
    public void invNumListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();
        searchMap = new HashMap();

        //  this.setVendAssValue((String) sourceLink.getAttributes().get("InvoiceNum"));
        String invNumer = (String) sourceLink.getAttributes().get("InvoiceNum");
        System.err.println(" invNumer pluse status >>>>>>>" + invNumer.contains("+"));
        if (invNumer.contains("+")) {
            System.out.println("InvoiceNum value is :: " + (String) sourceLink.getAttributes().get("InvoiceNum"));
            System.out.println("Receipt Number value is :: " + (String) sourceLink.getAttributes().get("ReceiptNum"));
            searchMap.put("ReceiptNum",  sourceLink.getAttributes().get("ReceiptNum"));
            searchMap.put("userIdVal", user_id);
            searchMap.put("invNumer", sourceLink.getAttributes().get("PoLineId"));

            OperationBinding opBindSearchInv = ADFUtils.findOperation("searchInvoiceNum");
            opBindSearchInv.getParamsMap().put("invNumMap", searchMap);
            String ouputVal = (String) opBindSearchInv.execute();
            if ("SUCCESS".equals(ouputVal)) {
                RichPopup.PopupHints hints = new RichPopup.PopupHints();
                p1.show(hints);

            }
        } else {

            FacesContext faceCont = FacesContext.getCurrentInstance();
            String displayMsg = "There is Single Invoice for this Receipt";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_INFO, displayMsg, null);
            faceCont.addMessage("INFO", errorMsg);
            return;


        }
    }

    public void setT4(RichTable t4) {
        this.t4 = t4;
    }

    public RichTable getT4() {
        return t4;
    }


    public void setOt46(RichOutputText ot46) {
        this.ot46 = ot46;
    }

    public RichOutputText getOt46() {
        return ot46;
    }

    public void setOt49(RichOutputText ot49) {
        this.ot49 = ot49;
    }

    public RichOutputText getOt49() {
        return ot49;
    }

    public void setS21(RichSpacer s21) {
        this.s21 = s21;
    }

    public RichSpacer getS21() {
        return s21;
    }


    public void setOt431(RichOutputText ot431) {
        this.ot431 = ot431;
    }

    public RichOutputText getOt431() {
        return ot431;
    }

    public void setIt1(RichInputText it1) {
        this.it1 = it1;
    }

    public RichInputText getIt1() {
        return it1;
    }


    /**
     * @param iteratValue
     * @param attributeName
     * @return
     */
    private Float totalAmount(DCIteratorBinding iteratValue, String attributeName) {

        Float grandTotal = new Float(0.0);
        int i = 0;
        RowSetIterator usValIterRow = iteratValue.getViewObject().createRowSetIterator(null);
        while (usValIterRow.hasNext()) {
            Row usRowVal = usValIterRow.next();
            logger.info(">>>>totalAmount attributeName>>>>" + usRowVal.getAttribute(attributeName));
            oracle.jbo.domain.Number value = (oracle.jbo.domain.Number) usRowVal.getAttribute(attributeName);
            grandTotal = grandTotal + value.floatValue();
        }

        logger.info(">>>>grandTotal>>>>" + grandTotal);

        return grandTotal;

    }


    public void setRecordCountOuput(RichOutputText recordCountOuput) {
        this.recordCountOuput = recordCountOuput;
    }

    public RichOutputText getRecordCountOuput() {
        return recordCountOuput;
    }
    
    
    public static long getDifferenceDaysBetweenTwoDates(oracle.jbo.domain.Date d1, oracle.jbo.domain.Date d2)
     {
       if(d1 != null && d2 != null)
       {
         return (d1.getValue().getTime() - d2.getValue().getTime())/(24 * 60 * 60 * 1000);
       }
       return 0;
     }

    public void submitConcurrentRequest() {
        String errMsg = "";
        FacesContext faceCont = FacesContext.getCurrentInstance();


        int userVal = 0;

        if (user_id != null) {
            userVal = Integer.parseInt(user_id);
        }


        if ((dateFrom.getValue() == null || dateTo.getValue() == null)) {


            errMsg = "Please enter Date Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);

            return;

        } else {
            OperationBinding opBindSearchReasonCode = ADFUtils.findOperation("searchReceiptDetInqConReq");
            opBindSearchReasonCode.getParamsMap().put("userId", userVal);
            opBindSearchReasonCode.execute();
            String value = (String) opBindSearchReasonCode.getResult();
            System.out.println("the value of value is : : " + value);


            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_INFO, value, null);

            faceCont.addMessage("INFO", errorMsg);


        }
        AdfFacesContext.getCurrentInstance().addPartialTarget(pg20);
        AdfFacesContext.getCurrentInstance().addPartialTarget(recDtlPC);


        //  }
    }
}
