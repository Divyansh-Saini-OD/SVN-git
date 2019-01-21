package od.tdmatch.view.bean;


/**
 * ==========================================================================================================================================================
 *  Name:  TrMaChargebackSumSearchBean.java
 *
 *  Description : This TrMaChargebackSumSearchBean has methods related validations of adjustment criteria jsff for Trade Match chargeback summary report.
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

import od.tdmatch.model.reports.vo.XxApChargeBackSearchVORowImpl;
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
public class TrMaChargebackSumSearchBean  implements Serializable{
    
    private static ADFLogger logger = ADFLogger.createADFLogger(TrMaChargebackSumSearchBean.class);
    private Boolean priceExcStatus =true;
    private Boolean qtyExcStatus=true;
    private Boolean othExcStatus=true;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelGroupLayout searchAreaBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues venAssBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supNameBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supSitNoBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues bindSKUBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputDate fromDateBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputDate toDateBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichSelectBooleanCheckbox excPricBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichSelectBooleanCheckbox excQtyBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichSelectBooleanCheckbox excOtherBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichSelectOneRadio repOptBind;
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
    private RichCommandMenuItem vendAssMenuItem;
    private RichCommandMenuItem venMenuItemBind;
    private RichOutputText totPricingAmtBind;
    private RichOutputText totPricingCountBind;
    private RichOutputText totPricingVchrCountBind;
    private RichOutputText totShortageAmtBind;
    private RichOutputText totShortageCountBind;
   
    private RichOutputText totOtherAmtBind;
    private RichOutputText totOtherCountBind;
    private RichOutputText totOtherVchrCountBind;
    private RichOutputText totshortageVchrCountBind;
    private RichOutputText totSupPricingAmtBind;
    private RichOutputText totSupPricingCountBind;
    private RichOutputText totSupPricingVchrCountBind;
    private RichOutputText totSupShortageAmtBind;
    private RichOutputText totSupShortageCountBind;
    private RichOutputText totSupShortageVchrCountBind;
    private RichOutputText totSupOtherAmtBind;
    private RichOutputText totSupOtherCountBind;
    private RichOutputText totSupOtherVchrCountBind;
    private String prcExce ="Y";
    private String qtyExce ="Y";
    private String othExce ="Y";
    
    private long recordCount;
    private RichOutputText totTotalAmt;
    private RichOutputText totSubTotalAmt;


    public TrMaChargebackSumSearchBean() {
    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void chgBackSearch() {

        String errMsg = "";

        FacesContext faceCont = FacesContext.getCurrentInstance();
        
      

        if (repOptBind.getValue() == null) {
            errMsg = "Please select Report Option";


            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);
            return;


        } 
        
        
        if (fromDateBind.getValue() == null || toDateBind.getValue() == null) {

            errMsg = "Please enter Invoice Date From and To Date.";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);
            
            return;

        }
      
        else {

         
       
          
           logger.info("repOptBind getValue" + repOptBind.getValue());
           logger.info("orgIdBind getValue" + orgIdBind.getValue());
           logger.info("orgIdBind getSubmittedValue" + orgIdBind.getSubmittedValue());
           logger.info("orgIdNonRendBind getSubmittedValue" + orgIdNonRendBind.getValue());
            String gorgIVale=(String)ADFUtils.getBoundAttributeValue("OrgIdVal");
            
            gorgIVale = gorgIVale==null?"404":gorgIVale;

           
           logger.info("exceptionVal>>>>exceptionVal>>>>>>>>");
         

            searchMap = new HashMap();


            searchMap.put("VendorAssistant", ADFUtils.getBoundAttributeValue("Vendorassistant"));
            searchMap.put("Suppliername", ADFUtils.getBoundAttributeValue("Suppliername"));
            searchMap.put("Suppliersiteno", ADFUtils.getBoundAttributeValue("Suppliersiteno"));
            searchMap.put("Sku", ADFUtils.getBoundAttributeValue("Sku"));
            searchMap.put("InvoiceDateFrom", ADFUtils.getBoundAttributeValue("Invoicedatefrom"));
            searchMap.put("InvoiceDateTo", ADFUtils.getBoundAttributeValue("Invoicedateto"));
            searchMap.put("prcExce", prcExce);
            searchMap.put("qtyExce", qtyExce);
            searchMap.put("othExce", othExce);
            searchMap.put("orgId",  gorgIVale);
         

           
            if ("VENDOR_ASSISTANT".equals(repOptBind.getValue())){
                
                    OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchTraMatChargebk");
                    opBindSearchCharBack.getParamsMap().put("trMaCashBkSearchMap", searchMap);
                    opBindSearchCharBack.execute();
                  
                  
                    DCIteratorBinding iteratMainValue = ADFUtils.findIterator("XxApChargeBackMainVOIterator");
                    iteratMainValue.executeQuery();
                  
                    
                    recordCount= iteratMainValue.getRowSetIterator().getRowCount();
                    
                    if(recordCount==1){
                        
                        if(iteratMainValue.getCurrentRow().getAttribute("VendorAssistant")==null){
                            
                                recordCount =0;
                            }
                        
                        }
                    
                    mainSearchResult.setRendered(true);
                    supResultTabBind.setRendered(false);
                    vendAssMenuItem.setRendered(true);
                    venMenuItemBind.setRendered(false);
                   
                    
                    
                        totPricingAmtBind.setValue( ADFUtils.totalAmount(iteratMainValue, "PricingAmt"));
                        totPricingCountBind.setValue( ADFUtils.totalAmount(iteratMainValue, "PricingCount"));
                        totPricingVchrCountBind.setValue( ADFUtils.totalAmount(iteratMainValue, "PricingVchrCount"));
                        totShortageAmtBind.setValue( ADFUtils.totalAmount(iteratMainValue, "ShortageAmt"));
                        totShortageCountBind.setValue( ADFUtils.totalAmount(iteratMainValue, "ShortageCount"));
                        totOtherAmtBind.setValue( ADFUtils.totalAmount(iteratMainValue, "OtherAmt"));
                        totOtherCountBind.setValue( ADFUtils.totalAmount(iteratMainValue, "OtherCount"));
                        totOtherVchrCountBind.setValue( ADFUtils.totalAmount(iteratMainValue, "OtherVchrCount"));
                        totshortageVchrCountBind.setValue( ADFUtils.totalAmount(iteratMainValue, "ShortageVchrCount"));
                        totTotalAmt.setValue( ADFUtils.totalAmount(iteratMainValue, "TotalAmt"));
                    AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);
                }
            if("VENDOR".equals(repOptBind.getValue())){
                
                    

                    OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchDrillDownChargebk");
                    opBindSearchCharBack.getParamsMap().put("trMaCashBkSearchMap", searchMap);
                    opBindSearchCharBack.execute();
                    
                    DCIteratorBinding iteratSubValue = ADFUtils.findIterator("XxApChargeBackSupVOIterator");
                    iteratSubValue.executeQuery();
                    recordCount= iteratSubValue.getRowSetIterator().getRowCount();
                    
                    if(recordCount==1){
                        
                        if(iteratSubValue.getCurrentRow().getAttribute("VendorAssistant")==null){
                            
                                recordCount =0;
                            }
                        
                        }
                    mainSearchResult.setRendered(false);
                    supResultTabBind.setRendered(true);
                    vendAssMenuItem.setRendered(false);
                    venMenuItemBind.setRendered(true);
                    totSupPricingAmtBind.setValue( ADFUtils.totalAmount(iteratSubValue, "PricingAmt"));
                    totSupPricingCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "PricingCount"));
                    totSupPricingVchrCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "PricingVchrCount"));
                    totSupShortageAmtBind.setValue( ADFUtils.totalAmount(iteratSubValue, "ShortageAmt"));
                    totSupShortageCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "ShortageCount"));
                    totSupOtherAmtBind.setValue( ADFUtils.totalAmount(iteratSubValue, "OtherAmt"));
                    totSupOtherCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "OtherCount"));
                    totSupOtherVchrCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "OtherVchrCount"));
                    totSupShortageVchrCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "ShortageVchrCount"));
                    totSubTotalAmt.setValue( ADFUtils.totalAmount(iteratSubValue, "TotalAmt"));
                    AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);
                
                }
            
         
         

         

        }
      

    }

    public void setPriceExcStatus(Boolean priceExcStatus) {
        this.priceExcStatus = priceExcStatus;
    }
   
    public Boolean getPriceExcStatus() {
        return priceExcStatus;
    }

    public void pricExtValueChange(ValueChangeEvent valueChangeEvent) {
       logger.info("pricExtValueChange >>>valueChangeEvent" + valueChangeEvent.getNewValue());
        if ((Boolean) valueChangeEvent.getNewValue()) {
            prcExce ="Y";
            priceExcStatus = true;
            

        } else {
            prcExce ="N";

            priceExcStatus = false;

        }

    }

    public void qtyExcValueChange(ValueChangeEvent valueChangeEvent) {
       logger.info("qtyExcValueChange >>>valueChangeEvent" + valueChangeEvent.getNewValue());
        if ((Boolean) valueChangeEvent.getNewValue()) {
            qtyExcStatus = true;
            qtyExce ="Y";
            

        } else {

            qtyExcStatus = false;
            qtyExce ="N";

        }
    }

    public void othExcValueChange(ValueChangeEvent valueChangeEvent) {
       logger.info("othExcValueChange >>>valueChangeEvent" + valueChangeEvent.getNewValue());
        if ((Boolean) valueChangeEvent.getNewValue()) {
            othExcStatus = true;
            othExce ="Y";

        } else {
            othExce ="N";
            othExcStatus = false;

        }
    }

    public String clearSearch() {


        venAssBind.setSubmittedValue(null);
        supNameBind.setSubmittedValue(null);
        supSitNoBind.setSubmittedValue(null);
        bindSKUBind.setSubmittedValue(null);
        fromDateBind.setSubmittedValue(null);
        toDateBind.setSubmittedValue(null);
       excPricBind.setSubmittedValue(true);
      excQtyBind.setSubmittedValue(true);
      excOtherBind.setSubmittedValue(true);
        //  repOptBind.setSubmittedValue(null);
        reporOptSelItemBind.setValue(null);
        DCIteratorBinding orderSearchIterBind = (DCIteratorBinding) getBindings().get("XxApChargeBackSearchVOIterator");
        XxApChargeBackSearchVORowImpl row = (XxApChargeBackSearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApChargeBackSearchVORowImpl newRow =
            (XxApChargeBackSearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
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

    public void setBindSKUBind(RichInputListOfValues bindSKUBind) {
        this.bindSKUBind = bindSKUBind;
    }

    public RichInputListOfValues getBindSKUBind() {
        return bindSKUBind;
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

    public void setExcPricBind(RichSelectBooleanCheckbox excPricBind) {
        this.excPricBind = excPricBind;
    }

    public RichSelectBooleanCheckbox getExcPricBind() {
        return excPricBind;
    }

    public void setExcQtyBind(RichSelectBooleanCheckbox excQtyBind) {
        this.excQtyBind = excQtyBind;
    }

    public RichSelectBooleanCheckbox getExcQtyBind() {
        return excQtyBind;
    }

    public void setExcOtherBind(RichSelectBooleanCheckbox excOtherBind) {
        this.excOtherBind = excOtherBind;
    }

    public RichSelectBooleanCheckbox getExcOtherBind() {
        return excOtherBind;
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

    public void setMainSearchResult(RichTable mainSearchResult) {
        this.mainSearchResult = mainSearchResult;
    }

    public RichTable getMainSearchResult() {
        return mainSearchResult;
    }

    @SuppressWarnings("unchecked")
    public void viewAssistDetailsListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();
        
        this.setVendAssValue((String) sourceLink.getAttributes().get("vendorAssistant"));


     
       logger.info(">>>vendorAssistant" + vendAssValue);
        


        searchMap.put("VendorAssistant", (String) sourceLink.getAttributes().get("vendorAssistant"));
        searchMap.put("VendorAssistantCode", (String) sourceLink.getAttributes().get("VendorAssistantCode"));

        OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchDrillDownChargebk");
        opBindSearchCharBack.getParamsMap().put("trMaCashBkSearchMap", searchMap);
        opBindSearchCharBack.execute();

        mainSearchResult.setRendered(false);
        supResultTabBind.setRendered(true);
        bkToSumBind.setRendered(true);
        vendAssMenuItem.setRendered(false);
        venMenuItemBind.setRendered(true);
        
        DCIteratorBinding iteratSubValue  = ADFUtils.findIterator("XxApChargeBackSupVOIterator");
        
        recordCount =iteratSubValue.getEstimatedRowCount();
        
        
        totSupPricingAmtBind.setValue( ADFUtils.totalAmount(iteratSubValue, "PricingAmt"));
        totSupPricingCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "PricingCount"));
        totSupPricingVchrCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "PricingVchrCount"));
        totSupShortageAmtBind.setValue( ADFUtils.totalAmount(iteratSubValue, "ShortageAmt"));
        totSupShortageCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "ShortageCount"));
        totSupOtherAmtBind.setValue( ADFUtils.totalAmount(iteratSubValue, "OtherAmt"));
        totSupOtherCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "OtherCount"));
        totSupOtherVchrCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "OtherVchrCount"));
        totSupShortageVchrCountBind.setValue( ADFUtils.totalAmount(iteratSubValue, "ShortageVchrCount"));
        totSubTotalAmt.setValue( ADFUtils.totalAmount(iteratSubValue, "TotalAmt"));
        AdfFacesContext.getCurrentInstance().addPartialTarget(resultAreaPanelColl);

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
        bkToSumBind.setRendered(false);
        vendAssMenuItem.setRendered(true);
        venMenuItemBind.setRendered(false);
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
       
        oracle.jbo.domain.Number supplierId = (oracle.jbo.domain.Number) sourceLink.getAttributes().get("VendorIdVal");
        oracle.jbo.domain.Number supplierSiteId = (oracle.jbo.domain.Number) sourceLink.getAttributes().get("VendorSiteIdVal");
        searchMap.put("supId", supplierId);
        searchMap.put("supSiteId", supplierSiteId);
        
        OperationBinding opBindsearchDtlChargebk = ADFUtils.findOperation("searchDtlChargebk");
        opBindsearchDtlChargebk.getParamsMap().put("trMaCashBkSearchMap", searchMap);
        String ouputVal =(String)opBindsearchDtlChargebk.execute();
        if("SUCCESS".equals(ouputVal)){
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
            vendAssMenuItem.setRendered(true);
            venMenuItemBind.setRendered(false);
        }
        if ("VENDOR".equals(valueChangeEvent.getNewValue())) {
            venAssBind.setValue(null);
            venAssBind.setDisabled(true);
            supNameBind.setDisabled(false);
            supSitNoBind.setDisabled(false);
            vendAssMenuItem.setRendered(false);
            venMenuItemBind.setRendered(true);
        }
        AdfFacesContext.getCurrentInstance().addPartialTarget(supNameBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(supSitNoBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(venAssBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);
    }

    public void setVendAssMenuItem(RichCommandMenuItem vendAssMenuItem) {
        this.vendAssMenuItem = vendAssMenuItem;
    }

    public RichCommandMenuItem getVendAssMenuItem() {
        return vendAssMenuItem;
    }

    public void setVenMenuItemBind(RichCommandMenuItem venMenuItemBind) {
        this.venMenuItemBind = venMenuItemBind;
    }

    public RichCommandMenuItem getVenMenuItemBind() {
        return venMenuItemBind;
    }

    public void setTotPricingAmtBind(RichOutputText totPricingAmtBind) {
        this.totPricingAmtBind = totPricingAmtBind;
    }

    public RichOutputText getTotPricingAmtBind() {
        return totPricingAmtBind;
    }

    public void setTotPricingCountBind(RichOutputText totPricingCountBind) {
        this.totPricingCountBind = totPricingCountBind;
    }

    public RichOutputText getTotPricingCountBind() {
        return totPricingCountBind;
    }

    public void setTotPricingVchrCountBind(RichOutputText totPricingVchrCountBind) {
        this.totPricingVchrCountBind = totPricingVchrCountBind;
    }

    public RichOutputText getTotPricingVchrCountBind() {
        return totPricingVchrCountBind;
    }

    public void setTotShortageAmtBind(RichOutputText totShortageAmtBind) {
        this.totShortageAmtBind = totShortageAmtBind;
    }

    public RichOutputText getTotShortageAmtBind() {
        return totShortageAmtBind;
    }

    public void setTotShortageCountBind(RichOutputText totShortageCountBind) {
        this.totShortageCountBind = totShortageCountBind;
    }

    public RichOutputText getTotShortageCountBind() {
        return totShortageCountBind;
    }

 

    public void setTotOtherAmtBind(RichOutputText totOtherAmtBind) {
        this.totOtherAmtBind = totOtherAmtBind;
    }

    public RichOutputText getTotOtherAmtBind() {
        return totOtherAmtBind;
    }

    public void setTotOtherCountBind(RichOutputText totOtherCountBind) {
        this.totOtherCountBind = totOtherCountBind;
    }

    public RichOutputText getTotOtherCountBind() {
        return totOtherCountBind;
    }

    public void setTotOtherVchrCountBind(RichOutputText totOtherVchrCountBind) {
        this.totOtherVchrCountBind = totOtherVchrCountBind;
    }

    public RichOutputText getTotOtherVchrCountBind() {
        return totOtherVchrCountBind;
    }

    public void setTotshortageVchrCountBind(RichOutputText totshortageVchrCountBind) {
        this.totshortageVchrCountBind = totshortageVchrCountBind;
    }

    public RichOutputText getTotshortageVchrCountBind() {
        return totshortageVchrCountBind;
    }

    public void setTotSupPricingAmtBind(RichOutputText totSupPricingAmtBind) {
        this.totSupPricingAmtBind = totSupPricingAmtBind;
    }

    public RichOutputText getTotSupPricingAmtBind() {
        return totSupPricingAmtBind;
    }


    public void setTotSupPricingCountBind(RichOutputText totSupPricingCountBind) {
        this.totSupPricingCountBind = totSupPricingCountBind;
    }

    public RichOutputText getTotSupPricingCountBind() {
        return totSupPricingCountBind;
    }

    public void setTotSupPricingVchrCountBind(RichOutputText totSupPricingVchrCountBind) {
        this.totSupPricingVchrCountBind = totSupPricingVchrCountBind;
    }

    public RichOutputText getTotSupPricingVchrCountBind() {
        return totSupPricingVchrCountBind;
    }

    public void setTotSupShortageAmtBind(RichOutputText totSupShortageAmtBind) {
        this.totSupShortageAmtBind = totSupShortageAmtBind;
    }

    public RichOutputText getTotSupShortageAmtBind() {
        return totSupShortageAmtBind;
    }

    public void setTotSupShortageCountBind(RichOutputText totSupShortageCountBind) {
        this.totSupShortageCountBind = totSupShortageCountBind;
    }

    public RichOutputText getTotSupShortageCountBind() {
        return totSupShortageCountBind;
    }

    public void setTotSupShortageVchrCountBind(RichOutputText totSupShortageVchrCountBind) {
        this.totSupShortageVchrCountBind = totSupShortageVchrCountBind;
    }

    public RichOutputText getTotSupShortageVchrCountBind() {
        return totSupShortageVchrCountBind;
    }

    public void setTotSupOtherAmtBind(RichOutputText totSupOtherAmtBind) {
        this.totSupOtherAmtBind = totSupOtherAmtBind;
    }

    public RichOutputText getTotSupOtherAmtBind() {
        return totSupOtherAmtBind;
    }

    public void setTotSupOtherCountBind(RichOutputText totSupOtherCountBind) {
        this.totSupOtherCountBind = totSupOtherCountBind;
    }

    public RichOutputText getTotSupOtherCountBind() {
        return totSupOtherCountBind;
    }

    public void setTotSupOtherVchrCountBind(RichOutputText totSupOtherVchrCountBind) {
        this.totSupOtherVchrCountBind = totSupOtherVchrCountBind;
    }

    public RichOutputText getTotSupOtherVchrCountBind() {
        return totSupOtherVchrCountBind;
    }

    public void setQtyExcStatus(Boolean qtyExcStatus) {
        this.qtyExcStatus = qtyExcStatus;
    }

    public Boolean getQtyExcStatus() {
        return qtyExcStatus;
    }

    public void setOthExcStatus(Boolean othExcStatus) {
        this.othExcStatus = othExcStatus;
    }

    public Boolean getOthExcStatus() {
        return othExcStatus;
    }

    public void setRecordCount(long recordCount) {
        this.recordCount = recordCount;
    }

    public long getRecordCount() {
        return recordCount;
    }

    public void setTotTotalAmt(RichOutputText totTotalAmt) {
        this.totTotalAmt = totTotalAmt;
    }

    public RichOutputText getTotTotalAmt() {
        return totTotalAmt;
    }

    public void setTotSubTotalAmt(RichOutputText totSubTotalAmt) {
        this.totSubTotalAmt = totSubTotalAmt;
    }

    public RichOutputText getTotSubTotalAmt() {
        return totSubTotalAmt;
    }
}
