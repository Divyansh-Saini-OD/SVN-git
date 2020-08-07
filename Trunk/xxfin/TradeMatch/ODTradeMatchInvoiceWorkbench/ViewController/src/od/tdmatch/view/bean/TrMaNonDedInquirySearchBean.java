package od.tdmatch.view.bean;


/**
 * ==========================================================================================================================================================
 *  Name:  TrMaNonDedInquirySearchBean.java
 *
 *  Description : This TrMaNonDedInquirySearchBean has methods related validations of adjustment criteria jsff for Trade Match chargeback summary report.
 *
 * @Author: Prabeethsoy Nair
 * @version: 1.0
 *
 *
 * ============================================================================================================================================================
 */

import java.io.Serializable;

import java.util.HashMap;

import javax.faces.application.FacesMessage;
import javax.faces.component.UIComponent;
import javax.faces.component.UISelectItems;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;
import javax.faces.event.ValueChangeEvent;
import javax.faces.validator.ValidatorException;

import od.tdmatch.model.reports.vo.XxApNonDedInqSearchVORowImpl;
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
public class TrMaNonDedInquirySearchBean implements Serializable {

    private static ADFLogger logger = ADFLogger.createADFLogger(TrMaNonDedInquirySearchBean.class);

    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelGroupLayout searchAreaBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues venAssBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supNameBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supSitNoBind;
    private RichInputListOfValues bindPoNum;

    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputDate fromDateBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputDate toDateBind;


    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private UISelectItems reporOptSelItemBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable mainSearchResult;
    HashMap searchMap = null;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichLink viewAssistDtlBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelCollection resultAreaPanelColl;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable supResultTabBind;


    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable temTableResult;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputComboboxListOfValues orgIdBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputText orgIdNonRendBind;


    private long recordCount;
    private RichInputListOfValues bindReasonCode;
    private RichInputListOfValues bindSuppNum;


    public TrMaNonDedInquirySearchBean() {
    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void noDedSearch() {

        String errMsg = "";

        FacesContext faceCont = FacesContext.getCurrentInstance();


        if ((fromDateBind.getValue() == null || toDateBind.getValue() == null) && bindPoNum.getValue() == null) {

            errMsg = "Please provide PO # or From and To Date Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);

            return;

        }

        else {


            logger.info("orgIdBind getValue" + orgIdBind.getValue());
            logger.info("orgIdBind getSubmittedValue" + orgIdBind.getSubmittedValue());
            logger.info("orgIdNonRendBind getSubmittedValue" + orgIdNonRendBind.getValue());
            String gorgIVale = (String) ADFUtils.getBoundAttributeValue("OrgIdVal");

            gorgIVale = gorgIVale == null ? "404" : gorgIVale;


            logger.info("exceptionVal>>>>exceptionVal>>>>>>>>");


            searchMap = new HashMap();


            searchMap.put("orgId", gorgIVale);


            OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchTraMatNonDedInq");
            opBindSearchCharBack.getParamsMap().put("trMaNonDedInqSearchMap", searchMap);
            opBindSearchCharBack.execute();


            DCIteratorBinding iteratMainValue = ADFUtils.findIterator("XxApNonDedInqResultVOIterator");
            iteratMainValue.executeQuery();


            recordCount = iteratMainValue.getRowSetIterator().getRowCount();

            if (recordCount == 1) {

                if (iteratMainValue.getCurrentRow().getAttribute("SupplierName") == null) {

                    recordCount = 0;
                }

            }

            
         


            AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);


        }


    }


    public String clearSearch() {


      // bindSuppNum.setSubmittedValue(null);
        supNameBind.setSubmittedValue(null);
        supSitNoBind.setSubmittedValue(null);
        bindPoNum.setSubmittedValue(null);    
        fromDateBind.setSubmittedValue(null);
        toDateBind.setSubmittedValue(null);
        bindReasonCode.setSubmittedValue(null);

      
        DCIteratorBinding orderSearchIterBind = (DCIteratorBinding) getBindings().get("XxApNonDedInqSearchVOIterator");
        XxApNonDedInqSearchVORowImpl row = (XxApNonDedInqSearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApNonDedInqSearchVORowImpl newRow =
            (XxApNonDedInqSearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
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


    public void setReporOptSelItemBind(UISelectItems reporOptSelItemBind) {
        this.reporOptSelItemBind = reporOptSelItemBind;
    }

    public UISelectItems getReporOptSelItemBind() {
        return reporOptSelItemBind;
    }

    public void setMainSearchResult(RichTable mainSearchResult) {
        this.mainSearchResult = mainSearchResult;
    }

    public RichTable getMainSearchResult() {
        return mainSearchResult;
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

        mainSearchResult.setRendered(true);
        supResultTabBind.setRendered(false);

        AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);
        return null;
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


    public void setRecordCount(long recordCount) {
        this.recordCount = recordCount;
    }

    public long getRecordCount() {
        return recordCount;
    }


    public void setBindPoNum(RichInputListOfValues bindPoNum) {
        this.bindPoNum = bindPoNum;
    }

    public RichInputListOfValues getBindPoNum() {
        return bindPoNum;
    }

    public void setBindReasonCode(RichInputListOfValues bindReasonCode) {
        this.bindReasonCode = bindReasonCode;
    }

    public RichInputListOfValues getBindReasonCode() {
        return bindReasonCode;
    }

    public void setBindSuppNum(RichInputListOfValues bindSuppNum) {
        this.bindSuppNum = bindSuppNum;
    }

    public RichInputListOfValues getBindSuppNum() {
        return bindSuppNum;
    }
}
