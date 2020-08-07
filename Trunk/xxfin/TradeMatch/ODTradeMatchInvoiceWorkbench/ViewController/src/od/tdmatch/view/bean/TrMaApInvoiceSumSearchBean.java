package od.tdmatch.view.bean;
/**
 * ==========================================================================================================================================================
 *  Name:  TrMaApInvoiceSumSearchBean.java
 *
 *  Description : This TrMaApInvoiceSumSearchBean has methods related validations of adjustment criteria jsff for Trade Match Invoice summary report.
 *
 * @Author: Prabeethsoy Nair
 * @version: 1.0
 *
 *
 * ============================================================================================================================================================
 */
import java.awt.event.ActionEvent;

import java.io.Serializable;

import java.util.HashMap;

import javax.faces.application.FacesMessage;
import javax.faces.component.UIComponent;
import javax.faces.component.UISelectItems;
import javax.faces.context.FacesContext;
import javax.faces.event.ValueChangeEvent;
import javax.faces.validator.ValidatorException;

import od.tdmatch.model.reports.vo.XxApTradeMatchSearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.share.logging.ADFLogger;
import oracle.adf.view.rich.component.rich.RichPopup;
import oracle.adf.view.rich.component.rich.data.RichTable;
import oracle.adf.view.rich.component.rich.input.RichInputComboboxListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputText;
import oracle.adf.view.rich.component.rich.input.RichSelectBooleanCheckbox;
import oracle.adf.view.rich.component.rich.input.RichSelectOneRadio;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.nav.RichButton;
import oracle.adf.view.rich.component.rich.nav.RichCommandMenuItem;
import oracle.adf.view.rich.component.rich.nav.RichLink;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.component.rich.output.RichPanelCollection;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

@SuppressWarnings("oracle.jdeveloper.java.serialversionuid-field-missing")
public class TrMaApInvoiceSumSearchBean implements Serializable {
    private static ADFLogger logger = ADFLogger.createADFLogger(TrMaApInvoiceSumSearchBean.class);
    String drpShpExcStatus = "N";
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelGroupLayout searchAreaBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues venAssBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supNameBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supSitNoBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supNoBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputDate fromDateBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputDate toDateBind;


    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichSelectOneRadio repOptBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private UISelectItems reporOptSelItemBind;

    HashMap searchMap = null;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichLink viewAssistDtlBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelCollection resultAreaPanelColl;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable supResultTabBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichButton bkToSumBind;
    private String vendAssValue;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPopup chargBkDtlPopBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable temTableResult;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputComboboxListOfValues orgIdBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputText orgIdNonRendBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable dummyTableBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable bindEmpTab;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable bindVendTab;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelGroupLayout resultCountRegion;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supNo;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues periodFromBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues periodToBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichSelectBooleanCheckbox drpShpBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichCommandMenuItem venExportBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichCommandMenuItem venAssExportBind;
    private long recordCount;

    private RichOutputText totManulInvBind;
    private RichOutputText totTdmInvBind;
    private RichOutputText totEdiInvBind;
    private RichOutputText totOtherInvBind;
    private RichOutputText totTotalInvoiceBind;

    private RichOutputText totEmpManualInvBind;
    private RichOutputText totEmpTdmInvBind;
    private RichOutputText totEmpEdiInvBind;
    private RichOutputText totEmpOtherInvBind;
    private RichOutputText totEmpTotalInvoiceBind;
    private RichOutputText totEmpManualMatchedBind;
    private RichOutputText totManualMatchedBind;


    public TrMaApInvoiceSumSearchBean() {
        super();
    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void trMatchSearch() {

        String errMsg = "";
        
     

        bkToSumBind.setRendered(false);

        FacesContext faceCont = FacesContext.getCurrentInstance();

        if (repOptBind.getValue() == null) {
            errMsg = "Please select Report Option";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;
        }

        if (((fromDateBind.getValue() != null && toDateBind.getValue() != null) &&
             (periodFromBind.getValue() == null && periodToBind.getValue() == null)) ||
            ((fromDateBind.getValue() == null && toDateBind.getValue() == null) &&
             (periodFromBind.getValue() != null && periodToBind.getValue() != null))) {


            logger.info("repOptBind getValue" + repOptBind.getValue());
            logger.info("orgIdBind getValue" + orgIdBind.getValue());
            logger.info("orgIdBind getSubmittedValue" + orgIdBind.getSubmittedValue());

            oracle.jbo.domain.Number gorgIVale = (oracle.jbo.domain.Number) ADFUtils.getBoundAttributeValue("OrgIdVal");
            System.err.println("gorgIVale>>>>"+gorgIVale);

                       
            if(gorgIVale == null){
                    gorgIVale =new oracle.jbo.domain.Number(404);
                
                }
            

            String exceptionVal = "";


            logger.info(ADFUtils.getBoundAttributeValue("Suppliername") + "  ");


            logger.info("exceptionVal>>>>exceptionVal>>>>>>>>");
            logger.info("exceptionVal>>>>>>>>>>>>" + exceptionVal);

            logger.info(">>>>Suppliername>>>>>>>>" + ADFUtils.getBoundAttributeValue("Suppliername"));
            logger.info("Supplier>>>>>>>>>>>>" + ADFUtils.getBoundAttributeValue("Supplier"));
            logger.info(">>>>Periodrangefrom>>>>>>>>" + ADFUtils.getBoundAttributeValue("Periodrangefrom"));
            logger.info("Periodrangeto>>>>>>>>>>>>" + ADFUtils.getBoundAttributeValue("Periodrangeto"));
            logger.info(">>>>gorgIVale>>>>>>>>" + gorgIVale);
            logger.info("fromDateBind>>>>>>>>>>>>" + fromDateBind.getValue());
            logger.info("toDateBind>>>>>>>>>>>>" + toDateBind.getValue());
            searchMap = new HashMap();


            searchMap.put("Suppliername", ADFUtils.getBoundAttributeValue("Suppliername"));
            searchMap.put("Supplier", ADFUtils.getBoundAttributeValue("Supplier"));
            searchMap.put("Daterangefrom", fromDateBind.getValue());
            searchMap.put("Daterangeto", toDateBind.getValue());
            searchMap.put("Periodrangefrom", ADFUtils.getBoundAttributeValue("Periodrangefrom"));
            searchMap.put("Periodrangeto", ADFUtils.getBoundAttributeValue("Periodrangeto"));
            searchMap.put("orgId", gorgIVale);
            searchMap.put("VendorAssistant", null);
            searchMap.put("DropShip", drpShpExcStatus);


            if ("VENDOR_ASSISTANT".equals(repOptBind.getValue())) {
                
                searchMap.put("ReportOption", "A");

                OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchMatchAnalysisEmp");
                opBindSearchCharBack.getParamsMap().put("trMaMatchAnalysisMap", searchMap);
                Object result = opBindSearchCharBack.execute();
                logger.info("Result " + result);
                if ("success".equals(result)) {
                    DCIteratorBinding venMathEmpIte = ADFUtils.findIterator("XxApVendorMatchAnaEmpVO1Iterator");
                    venMathEmpIte.executeQuery();
                    recordCount= venMathEmpIte.getRowSetIterator().getRowCount();
                    
                    if(recordCount==1){
                        
                        if(venMathEmpIte.getCurrentRow().getAttribute("Vendorasistant")==null){
                            
                                recordCount =0;
                            }
                        
                        }
                    
                    
                    dummyTableBind.setRendered(false);
                    bindVendTab.setRendered(false);
                    bindEmpTab.setRendered(true);
                    venAssExportBind.setRendered(true);
                    venExportBind.setRendered(false);
                  


                    totEmpManualInvBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "ManualInv"));
                    totEmpTdmInvBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "TdmInv"));
                    totEmpEdiInvBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "EdiInv"));
                    totEmpOtherInvBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "OtherInv"));
                    totEmpManualMatchedBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "ManualyMatched"));
                    totEmpTotalInvoiceBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "TotalInvoice"));


                }
                AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);

                AdfFacesContext.getCurrentInstance().addPartialTarget(resultCountRegion);

            }
            if ("VENDOR".equals(repOptBind.getValue())) {
                
                searchMap.put("ReportOption", "V");


                OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchMatchAnalysis");
                opBindSearchCharBack.getParamsMap().put("trMaMatchAnalysisMap", searchMap);
                Object result = opBindSearchCharBack.execute();
                logger.info("Result " + result);
                if ("success".equals(result)) {
                    DCIteratorBinding venMathVendIte = ADFUtils.findIterator("XxApVendorMatchAnaVendVO1Iterator");   
                    venMathVendIte.executeQuery();
                    recordCount= venMathVendIte.getRowSetIterator().getRowCount();
                    
                    if(recordCount==1){
                        
                        if(venMathVendIte.getCurrentRow().getAttribute("Vendorasistant")==null){
                            
                                recordCount =0;
                            }
                        
                        }
                    dummyTableBind.setRendered(false);
                    bindVendTab.setRendered(true);
                    bindEmpTab.setRendered(false);
                    venAssExportBind.setRendered(false);
                    venExportBind.setRendered(true);
                  
                  
                    
                    
                    totManulInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "ManualInv"));
                    totTdmInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "TdmInv"));
                    totEdiInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "EdiInv"));
                    totOtherInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "OtherInv"));
                    totManualMatchedBind.setValue(ADFUtils.totalAmount(venMathVendIte, "ManualyMatched"));
                    totTotalInvoiceBind.setValue(ADFUtils.totalAmount(venMathVendIte, "TotalInvoice"));

                                     
                                    
                }
                AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);

                AdfFacesContext.getCurrentInstance().addPartialTarget(resultCountRegion);

            }
        } else {


            errMsg = "Please enter Invoice Date Range OR Period Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;


        }
    }


    public void drpShpValueChange(ValueChangeEvent valueChangeEvent) {
        logger.info("drpShpValueChange >>>valueChangeEvent" + valueChangeEvent.getNewValue());
        if ((Boolean) valueChangeEvent.getNewValue()) {
            drpShpExcStatus = "Y";

        } else {

            drpShpExcStatus = "N";

        }

    }

    public String clearSearch() {

        bkToSumBind.setRendered(false);

        supNameBind.setSubmittedValue(null);
        supNo.setSubmittedValue(null);
        fromDateBind.setSubmittedValue(null);
        toDateBind.setSubmittedValue(null);
        periodFromBind.setSubmittedValue(null);
        periodToBind.setSubmittedValue(null);
        // drpShpBind.setSubmittedValue(false);

        repOptBind.setSubmittedValue(null);
        reporOptSelItemBind.setValue(null);
        DCIteratorBinding orderSearchIterBind =
            (DCIteratorBinding) getBindings().get("XxApTradeMatchSearchVO1Iterator");
        XxApTradeMatchSearchVORowImpl row = (XxApTradeMatchSearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApTradeMatchSearchVORowImpl newRow =
            (XxApTradeMatchSearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
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

    public void setVenAssBind(RichInputListOfValues venAssBind) {
        this.venAssBind = venAssBind;
    }

    public RichInputListOfValues getVenAssBind() {
        return venAssBind;
    }

    public void setSupNameBind(RichInputListOfValues supNameBind) {
        this.supNameBind = supNameBind;
    }

    public RichInputListOfValues getSupNameBind() {
        return supNameBind;
    }

    public void setSupSitNoBind(RichInputListOfValues supSitNoBind) {
        this.supSitNoBind = supSitNoBind;
    }

    public RichInputListOfValues getSupSitNoBind() {
        return supSitNoBind;
    }

    public void setFromDateBind(RichInputDate fromDateBind) {
        this.fromDateBind = fromDateBind;
    }

    public RichInputDate getFromDateBind() {
        return fromDateBind;
    }

    public void setToDateBind(RichInputDate toDateBind) {
        this.toDateBind = toDateBind;
    }

    public RichInputDate getToDateBind() {
        return toDateBind;
    }


    public void setRepOptBind(RichSelectOneRadio repOptBind) {
        this.repOptBind = repOptBind;
    }

    public RichSelectOneRadio getRepOptBind() {
        return repOptBind;
    }

    public void setReporOptSelItemBind(UISelectItems reporOptSelItemBind) {
        this.reporOptSelItemBind = reporOptSelItemBind;
    }

    public UISelectItems getReporOptSelItemBind() {
        return reporOptSelItemBind;
    }


    public void setViewAssistDtlBind(RichLink viewAssistDtlBind) {
        this.viewAssistDtlBind = viewAssistDtlBind;
    }

    public RichLink getViewAssistDtlBind() {
        return viewAssistDtlBind;
    }

    public void setResultAreaPanelColl(RichPanelCollection resultAreaPanelColl) {
        this.resultAreaPanelColl = resultAreaPanelColl;
    }

    public RichPanelCollection getResultAreaPanelColl() {
        return resultAreaPanelColl;
    }

    public void setSupResultTabBind(RichTable supResultTabBind) {
        this.supResultTabBind = supResultTabBind;
    }

    public RichTable getSupResultTabBind() {
        return supResultTabBind;
    }

    public String backToSummaryResultAct() {


        bindVendTab.setRendered(false);
        bindEmpTab.setRendered(true);
        bkToSumBind.setRendered(false);
        venAssExportBind.setRendered(true);
        venExportBind.setRendered(false);

        AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);
        return null;
    }

    public void setBkToSumBind(RichButton bkToSumBind) {
        this.bkToSumBind = bkToSumBind;
    }

    public RichButton getBkToSumBind() {
        return bkToSumBind;
    }

    public void setVendAssValue(String vendAssValue) {
        this.vendAssValue = vendAssValue;
    }

    public String getVendAssValue() {
        return vendAssValue;
    }

    public void fromDateValidator(FacesContext facesContext, UIComponent uIComponent, Object object) {
        if (toDateBind.getValue() == null) {
            return;
        }

        java.util.Date toDate = (java.util.Date) toDateBind.getValue();
        java.util.Date fromDate = (java.util.Date) object;

        if (toDate.before(fromDate)) {

            throw new ValidatorException(new FacesMessage(FacesMessage.SEVERITY_ERROR,
                                                          "To date may not be before From date.", null));

        }


    }

    public void toDateValidator(FacesContext facesContext, UIComponent uIComponent, Object object) {
        logger.info(">>>From date>>" + fromDateBind.getValue());

        if (fromDateBind.getValue() == null) {
            return;
        }

        java.util.Date toDate = (java.util.Date) object;
        java.util.Date fromDate = (java.util.Date) fromDateBind.getValue();

        if (fromDate.after(toDate)) {

            throw new ValidatorException(new FacesMessage(FacesMessage.SEVERITY_ERROR,
                                                          "From date may not be after to date.", null));

        }


    }

    public void viewChargeBkDtlActListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();
        String supplierName = (String) sourceLink.getAttributes().get("supplierName");
        searchMap.put("supName", supplierName);

        OperationBinding opBindsearchDtlChargebk = ADFUtils.findOperation("<ARG>");
        opBindsearchDtlChargebk.getParamsMap().put("<>", searchMap);
        String ouputVal = (String) opBindsearchDtlChargebk.execute();
        if ("SUCCESS".equals(ouputVal)) {
            RichPopup.PopupHints hints = new RichPopup.PopupHints();
            chargBkDtlPopBind.show(hints);
        }

    }

    public void setChargBkDtlPopBind(RichPopup chargBkDtlPopBind) {
        this.chargBkDtlPopBind = chargBkDtlPopBind;
    }

    public RichPopup getChargBkDtlPopBind() {
        return chargBkDtlPopBind;
    }

    public void setTemTableResult(RichTable temTableResult) {
        this.temTableResult = temTableResult;
    }

    public RichTable getTemTableResult() {
        return temTableResult;
    }

    public void setOrgIdBind(RichInputComboboxListOfValues orgIdBind) {
        this.orgIdBind = orgIdBind;
    }

    public RichInputComboboxListOfValues getOrgIdBind() {
        return orgIdBind;
    }

    public void setOrgIdNonRendBind(RichInputText orgIdNonRendBind) {
        this.orgIdNonRendBind = orgIdNonRendBind;
    }

    public RichInputText getOrgIdNonRendBind() {
        return orgIdNonRendBind;
    }

    public void reportOptionValueChange(ValueChangeEvent valueChangeEvent) {
        logger.info("valueChangeEvent.getNewValue()" + valueChangeEvent.getNewValue());
        if ("VENDOR_ASSISTANT".equals(valueChangeEvent.getNewValue())) {
            supNameBind.setValue(null);
            supSitNoBind.setValue(null);
            supNameBind.setDisabled(true);
            supSitNoBind.setDisabled(true);
            venAssBind.setDisabled(false);
        }
        if ("VENDOR".equals(valueChangeEvent.getNewValue())) {
            venAssBind.setValue(null);
            venAssBind.setDisabled(true);
            supNameBind.setDisabled(false);
            supSitNoBind.setDisabled(false);
        }
        AdfFacesContext.getCurrentInstance().addPartialTarget(supNameBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(supSitNoBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(venAssBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);
    }

    public void setDummyTableBind(RichTable dummyTableBind) {
        this.dummyTableBind = dummyTableBind;
    }

    public RichTable getDummyTableBind() {
        return dummyTableBind;
    }

    public void setBindEmpTab(RichTable bindEmpTab) {
        this.bindEmpTab = bindEmpTab;
    }

    public RichTable getBindEmpTab() {
        return bindEmpTab;
    }

    public void setBindVendTab(RichTable bindVendTab) {
        this.bindVendTab = bindVendTab;
    }

    public RichTable getBindVendTab() {
        return bindVendTab;
    }

    public void viewAssistDetailsListener(javax.faces.event.ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();
        FacesContext faceCont = FacesContext.getCurrentInstance();
        this.setVendAssValue((String) sourceLink.getAttributes().get("vendorAssistant"));
        String errMsg = "";

        if (((fromDateBind.getValue() != null && toDateBind.getValue() != null) &&
             (periodFromBind.getValue() == null && periodToBind.getValue() == null)) ||
            ((fromDateBind.getValue() == null && toDateBind.getValue() == null) &&
             (periodFromBind.getValue() != null && periodToBind.getValue() != null))) {


            logger.info(">>>vendorAssistant" + vendAssValue);

            venAssExportBind.setRendered(false);
            venExportBind.setRendered(true);
            searchMap.put("VendorAssistant", (String) sourceLink.getAttributes().get("vendorAssistant"));
            searchMap.put("ReportOption", "V");

            OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchMatchAnalysisVendAss");
            opBindSearchCharBack.getParamsMap().put("trMaMatchAnalysisMap", searchMap);

            Object result = opBindSearchCharBack.execute();
            logger.info("Result " + result);
            if ("success".equals(result)) {

                dummyTableBind.setRendered(false);
                bindVendTab.setRendered(true);
                bindEmpTab.setRendered(false);
                bkToSumBind.setRendered(true);
                DCIteratorBinding venMathVendIte = ADFUtils.findIterator("XxApVendorMatchAnaVendVO1Iterator");
                
             
                recordCount= venMathVendIte.getRowSetIterator().getRowCount();
                
                if(recordCount==1){
                    
                    if(venMathVendIte.getCurrentRow().getAttribute("Vendorasistant")==null){
                        
                            recordCount =0;
                        }
                    
                    }
                totManulInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "ManualInv"));
                totTdmInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "TdmInv"));
                totEdiInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "EdiInv"));
                totOtherInvBind.setValue(ADFUtils.totalAmount(venMathVendIte, "OtherInv"));
                totManualMatchedBind.setValue(ADFUtils.totalAmount(venMathVendIte, "ManualyMatched"));
                totTotalInvoiceBind.setValue(ADFUtils.totalAmount(venMathVendIte, "TotalInvoice"));
            }
        } else {


            errMsg = "Please enter Invoice Date Range OR Period Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;


        }

        AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);
        AdfFacesContext.getCurrentInstance().addPartialTarget(resultCountRegion);
    }

    public void setResultCountRegion(RichPanelGroupLayout resultCountRegion) {
        this.resultCountRegion = resultCountRegion;
    }

    public RichPanelGroupLayout getResultCountRegion() {
        return resultCountRegion;
    }

    public void setSupNo(RichInputListOfValues supNo) {
        this.supNo = supNo;
    }

    public RichInputListOfValues getSupNo() {
        return supNo;
    }

    public void setPeriodFromBind(RichInputListOfValues periodFromBind) {
        this.periodFromBind = periodFromBind;
    }

    public RichInputListOfValues getPeriodFromBind() {
        return periodFromBind;
    }

    public void setPeriodToBind(RichInputListOfValues periodToBind) {
        this.periodToBind = periodToBind;
    }

    public RichInputListOfValues getPeriodToBind() {
        return periodToBind;
    }

    public void setDrpShpBind(RichSelectBooleanCheckbox drpShpBind) {
        this.drpShpBind = drpShpBind;
    }

    public RichSelectBooleanCheckbox getDrpShpBind() {
        return drpShpBind;
    }

    public void setVenExportBind(RichCommandMenuItem venExportBind) {
        this.venExportBind = venExportBind;
    }

    public RichCommandMenuItem getVenExportBind() {
        return venExportBind;
    }

    public void setVenAssExportBind(RichCommandMenuItem venAssExportBind) {
        this.venAssExportBind = venAssExportBind;
    }

    public RichCommandMenuItem getVenAssExportBind() {
        return venAssExportBind;
    }


    public void setRecordCount(long recordCount) {
        this.recordCount = recordCount;
    }

    public long getRecordCount() {
        return recordCount;
    }


    public void setTotManulInvBind(RichOutputText totManulInvBind) {
        this.totManulInvBind = totManulInvBind;
    }

    public RichOutputText getTotManulInvBind() {
        return totManulInvBind;
    }

    public void setTotTdmInvBind(RichOutputText totTdmInvBind) {
        this.totTdmInvBind = totTdmInvBind;
    }

    public RichOutputText getTotTdmInvBind() {
        return totTdmInvBind;
    }

    public void setTotEdiInvBind(RichOutputText totEdiInvBind) {
        this.totEdiInvBind = totEdiInvBind;
    }

    public RichOutputText getTotEdiInvBind() {
        return totEdiInvBind;
    }

    public void setTotOtherInvBind(RichOutputText totOtherInvBind) {
        this.totOtherInvBind = totOtherInvBind;
    }

    public RichOutputText getTotOtherInvBind() {
        return totOtherInvBind;
    }

    public void setTotTotalInvoiceBind(RichOutputText totTotalInvoiceBind) {
        this.totTotalInvoiceBind = totTotalInvoiceBind;
    }

    public RichOutputText getTotTotalInvoiceBind() {
        return totTotalInvoiceBind;
    }

   

    public void setTotEmpManualInvBind(RichOutputText totEmpManualInvBind) {
        this.totEmpManualInvBind = totEmpManualInvBind;
    }

    public RichOutputText getTotEmpManualInvBind() {
        return totEmpManualInvBind;
    }

    public void setTotEmpTdmInvBind(RichOutputText totEmpTdmInvBind) {
        this.totEmpTdmInvBind = totEmpTdmInvBind;
    }

    public RichOutputText getTotEmpTdmInvBind() {
        return totEmpTdmInvBind;
    }

    public void setTotEmpEdiInvBind(RichOutputText totEmpEdiInvBind) {
        this.totEmpEdiInvBind = totEmpEdiInvBind;
    }

    public RichOutputText getTotEmpEdiInvBind() {
        return totEmpEdiInvBind;
    }

    public void setTotEmpOtherInvBind(RichOutputText totEmpOtherInvBind) {
        this.totEmpOtherInvBind = totEmpOtherInvBind;
    }

    public RichOutputText getTotEmpOtherInvBind() {
        return totEmpOtherInvBind;
    }

    public void setTotEmpTotalInvoiceBind(RichOutputText totEmpTotalInvoiceBind) {
        this.totEmpTotalInvoiceBind = totEmpTotalInvoiceBind;
    }

    public RichOutputText getTotEmpTotalInvoiceBind() {
        return totEmpTotalInvoiceBind;
    }

    public void setTotEmpManualMatchedBind(RichOutputText totEmpManualMatchedBind) {
        this.totEmpManualMatchedBind = totEmpManualMatchedBind;
    }

    public RichOutputText getTotEmpManualMatchedBind() {
        return totEmpManualMatchedBind;
    }

    public void setTotManualMatchedBind(RichOutputText totManualMatchedBind) {
        this.totManualMatchedBind = totManualMatchedBind;
    }

    public RichOutputText getTotManualMatchedBind() {
        return totManualMatchedBind;
    }
}
