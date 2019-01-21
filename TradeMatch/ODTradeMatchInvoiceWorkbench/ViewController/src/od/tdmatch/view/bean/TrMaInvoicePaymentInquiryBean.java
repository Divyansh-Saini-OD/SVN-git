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
import java.io.Serializable;

import java.util.ArrayList;
import java.util.HashMap;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import javax.faces.event.ValueChangeEvent;

import od.tdmatch.model.reports.vo.XxApInvoicePaymentInquirySearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.share.logging.ADFLogger;
import oracle.adf.view.rich.component.rich.data.RichTable;
import oracle.adf.view.rich.component.rich.input.RichInputComboboxListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputText;
import oracle.adf.view.rich.component.rich.input.RichSelectBooleanCheckbox;
import oracle.adf.view.rich.component.rich.input.RichSelectOneChoice;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.nav.RichLink;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.component.rich.output.RichPanelCollection;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

import org.apache.commons.lang.StringUtils;

@SuppressWarnings("oracle.jdeveloper.java.serialversionuid-field-missing")
public class TrMaInvoicePaymentInquiryBean implements Serializable {
    private static ADFLogger logger = ADFLogger.createADFLogger(TrMaInvoicePaymentInquiryBean.class);

    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichPanelGroupLayout searchAreaBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues venAssBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supNameBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputListOfValues supSitNoBind;


    HashMap searchMap = null;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichLink viewAssistDtlBind;


    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputComboboxListOfValues orgIdBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichInputText orgIdNonRendBind;
    @SuppressWarnings("oracle.jdeveloper.java.field-not-serializable")
    private RichTable dummyTableBind;

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


    
    private RichInputDate poDateRangeFromBind;
    private RichInputDate poDateRangeToBind;

    private RichInputDate invoiceDateRangFromBind;
    private RichInputDate invoiceDateRangeToBind;

    private RichInputDate glDateRangFromBind;
    private RichSelectBooleanCheckbox drpShipBind;
    private RichSelectBooleanCheckbox fonDoorBind;
    private RichSelectBooleanCheckbox nonCodeBind;
    private RichSelectBooleanCheckbox consigBind;
    private RichSelectBooleanCheckbox tradeBind;
    private RichSelectBooleanCheckbox newStroeBind;
    private RichSelectBooleanCheckbox replenBind;
    private RichSelectBooleanCheckbox direcImBind;
    private RichSelectBooleanCheckbox freightBind;
    private RichSelectBooleanCheckbox taxBind;
    private RichSelectBooleanCheckbox chargeBind;
    private RichSelectBooleanCheckbox priExcBind;
    private RichSelectBooleanCheckbox otyExcBind;
    private RichSelectBooleanCheckbox freighExcBind;
    private RichSelectBooleanCheckbox otherExcBind;


    private String chargebackStatus = "N";
    private RichInputDate glDateRangeToBind;
    private RichTable resultHeaderTabBind;
    private RichPanelCollection headerPanelCollBind;
    private RichPanelCollection itemPanelCollBind;
    private RichTable itemTabBind;
    private RichInputListOfValues poNumBind;
    private RichInputListOfValues invoiceSrcBind;
    private RichInputListOfValues invTypBind;


    private RichSelectOneChoice invValiBind;

    private RichInputListOfValues payNumBind;
    private RichSelectOneChoice payStatusBind;
    private RichOutputText hdrInvoiceAmountBind;
    private RichOutputText hdrFreightAmountBind;
    private RichOutputText hdrTaxAmountBind;
    private RichInputText invNumTextBind;

    private String poTypeDropShip = "N";
    private String poTypeFrontDoor = "N";
    private String poTypeNonCode = "N";
    private String poTypeCons = "N";
    private String poTypeTrade = "N";
    private String poTypeNewStore = "N";
    private String poTypeReplen = "N";
    private String poTypeDirectImport = "N";
    private String freight = "N";
    private String tax = "N";

    private String priceExce = "Y";
    private String qtyExce = "Y";
    private String freightExce = "Y";
    private String otherExce = "Y";
    private RichOutputText recordCountOuptput;
    private RichOutputText recordCountLineVal;

    public TrMaInvoicePaymentInquiryBean() {


    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void trMatchSearch() {

        String errMsg = "";


        FacesContext faceCont = FacesContext.getCurrentInstance();


        itemPanelCollBind.setRendered(false);
        AdfFacesContext.getCurrentInstance().addPartialTarget(itemPanelCollBind);


        logger.info("glDateRangFromBind" + glDateRangFromBind.getValue());
        logger.info("glDateRangeToBind" + glDateRangeToBind.getValue());
        logger.info("poDateRangeFromBind" + poDateRangeFromBind.getValue());
        logger.info("poDateRangeToBind" + poDateRangeToBind.getValue());
        logger.info("invoiceDateRangFromBind" + invoiceDateRangFromBind.getValue());
        logger.info("invoiceDateRangeToBind" + invoiceDateRangeToBind.getValue());

        if (((poDateRangeFromBind.getValue() != null && poDateRangeToBind.getValue() != null) &&
             (invoiceDateRangFromBind.getValue() == null && invoiceDateRangeToBind.getValue() == null) &&
             (glDateRangFromBind.getValue() == null && glDateRangeToBind.getValue() == null)) ||
            ((poDateRangeFromBind.getValue() == null && poDateRangeToBind.getValue() == null) &&
             (glDateRangFromBind.getValue() == null && glDateRangeToBind.getValue() == null) &&
             (invoiceDateRangFromBind.getValue() != null && invoiceDateRangeToBind.getValue() != null)) ||
            ((poDateRangeFromBind.getValue() == null && poDateRangeToBind.getValue() == null) &&
             (glDateRangFromBind.getValue() != null && glDateRangeToBind.getValue() != null) &&
             (invoiceDateRangFromBind.getValue() == null && invoiceDateRangeToBind.getValue() == null))) {


            oracle.jbo.domain.Number gorgIVale = (oracle.jbo.domain.Number) ADFUtils.getBoundAttributeValue("OrgId");
           
            
            if(gorgIVale == null){
                    gorgIVale =new oracle.jbo.domain.Number(404);
                
                }


           


            logger.info("gorgIVale>>>" + gorgIVale);


            searchMap = new HashMap();


            searchMap.put("orgId", gorgIVale);
            searchMap.put("chargebackStatus", chargebackStatus);
            searchMap.put("poTypeDropShip", poTypeDropShip);
            searchMap.put("poTypeFrontDoor", poTypeFrontDoor);
            searchMap.put("poTypeNonCode", poTypeNonCode);
            searchMap.put("poTypeCons", poTypeCons);
            searchMap.put("poTypeTrade", poTypeTrade);
            searchMap.put("poTypeNewStore", poTypeNewStore);
            searchMap.put("poTypeReplen", poTypeReplen);
            searchMap.put("poTypeDirectImport", poTypeDirectImport);
            searchMap.put("freight", freight);
            searchMap.put("tax", tax);
            searchMap.put("priceExce", priceExce);
            searchMap.put("qtyExce", qtyExce);
            searchMap.put("freightExce", freightExce);
            searchMap.put("otherExce", otherExce);


            OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchInvoicePaymentInq");
            opBindSearchCharBack.getParamsMap().put("trMaInvoicePaymentMap", searchMap);
            Object result = opBindSearchCharBack.execute();
            logger.info("Result " + result);
            if ("success".equals(result)) {
                dummyTableBind.setRendered(false);
                resultHeaderTabBind.setRendered(true);
                itemTabBind.setRendered(false);
                


                DCIteratorBinding venMathEmpIte = ADFUtils.findIterator("XxApInvoicePaymentInquiryHeaderVOIterator");
                
                venMathEmpIte.executeQuery();
               
              
                hdrInvoiceAmountBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "InvoiceAmount"));
                hdrFreightAmountBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "FreightAmount"));
                hdrTaxAmountBind.setValue(ADFUtils.totalAmount(venMathEmpIte, "TaxAmount"));

                recordCountOuptput.setRendered(true);
                recordCountLineVal.setRendered(true);

            }
            AdfFacesContext.getCurrentInstance().addPartialTarget(headerPanelCollBind);

            AdfFacesContext.getCurrentInstance().addPartialTarget(resultCountRegion);


        } else {


            errMsg = "Please enter PO Date Range OR Invoice Date Range OR GL Date Range	";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;


        }
    }


    public String clearSearch() {

        supNameBind.resetValue();
        supNo.resetValue();
        supSitNoBind.resetValue();
        venAssBind.resetValue();
        poNumBind.resetValue();
        invoiceSrcBind.resetValue();
        invTypBind.resetValue();
        invNumTextBind.resetValue();
        invoiceDateRangeToBind.resetValue();
        invoiceDateRangFromBind.resetValue();
        glDateRangeToBind.resetValue();
        glDateRangFromBind.resetValue();
        poDateRangeFromBind.resetValue();
        poDateRangeToBind.resetValue();
        payStatusBind.resetValue();
        payNumBind.resetValue();
        drpShipBind.resetValue();
        fonDoorBind.resetValue();
        nonCodeBind.resetValue();
        consigBind.resetValue();
        tradeBind.resetValue();
        newStroeBind.resetValue();
        replenBind.resetValue();
        direcImBind.resetValue();
        freightBind.resetValue();
        taxBind.resetValue();
        chargeBind.resetValue();
        priExcBind.setValue(true);
        otyExcBind.setValue(true);
        freighExcBind.setValue(true);
        otherExcBind.setValue(true);
        invValiBind.resetValue();

        DCIteratorBinding orderSearchIterBind =
            (DCIteratorBinding) getBindings().get("XxApInvoicePaymentInquirySearchVOIterator");
        XxApInvoicePaymentInquirySearchVORowImpl row =
            (XxApInvoicePaymentInquirySearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApInvoicePaymentInquirySearchVORowImpl newRow =
            (XxApInvoicePaymentInquirySearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
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


    public void setViewAssistDtlBind(RichLink viewAssistDtlBind) {
        this.viewAssistDtlBind = viewAssistDtlBind;
    }

    public RichLink getViewAssistDtlBind() {
        return viewAssistDtlBind;
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


 

    public void setPoDateRangeFromBind(RichInputDate poDateRangeFromBind) {
        this.poDateRangeFromBind = poDateRangeFromBind;
    }

    public RichInputDate getPoDateRangeFromBind() {
        return poDateRangeFromBind;
    }

    public void setPoDateRangeToBind(RichInputDate poDateRangeToBind) {
        this.poDateRangeToBind = poDateRangeToBind;
    }

    public RichInputDate getPoDateRangeToBind() {
        return poDateRangeToBind;
    }


    public void setInvoiceDateRangFromBind(RichInputDate invoiceDateRangFromBind) {
        this.invoiceDateRangFromBind = invoiceDateRangFromBind;
    }

    public RichInputDate getInvoiceDateRangFromBind() {
        return invoiceDateRangFromBind;
    }

    public void setInvoiceDateRangeToBind(RichInputDate invoiceDateRangeToBind) {
        this.invoiceDateRangeToBind = invoiceDateRangeToBind;
    }

    public RichInputDate getInvoiceDateRangeToBind() {
        return invoiceDateRangeToBind;
    }


    public void setGlDateRangFromBind(RichInputDate glDateRangFromBind) {
        this.glDateRangFromBind = glDateRangFromBind;
    }

    public RichInputDate getGlDateRangFromBind() {
        return glDateRangFromBind;
    }

    public void setDrpShipBind(RichSelectBooleanCheckbox drpShipBind) {
        this.drpShipBind = drpShipBind;
    }

    public RichSelectBooleanCheckbox getDrpShipBind() {
        return drpShipBind;
    }

    public void setFonDoorBind(RichSelectBooleanCheckbox fonDoorBind) {
        this.fonDoorBind = fonDoorBind;
    }

    public RichSelectBooleanCheckbox getFonDoorBind() {
        return fonDoorBind;
    }

    public void setNonCodeBind(RichSelectBooleanCheckbox nonCodeBind) {
        this.nonCodeBind = nonCodeBind;
    }

    public RichSelectBooleanCheckbox getNonCodeBind() {
        return nonCodeBind;
    }

    public void setConsigBind(RichSelectBooleanCheckbox consigBind) {
        this.consigBind = consigBind;
    }

    public RichSelectBooleanCheckbox getConsigBind() {
        return consigBind;
    }

    public void setTradeBind(RichSelectBooleanCheckbox tradeBind) {
        this.tradeBind = tradeBind;
    }

    public RichSelectBooleanCheckbox getTradeBind() {
        return tradeBind;
    }

    public void setNewStroeBind(RichSelectBooleanCheckbox newStroeBind) {
        this.newStroeBind = newStroeBind;
    }

    public RichSelectBooleanCheckbox getNewStroeBind() {
        return newStroeBind;
    }

    public void setReplenBind(RichSelectBooleanCheckbox replenBind) {
        this.replenBind = replenBind;
    }

    public RichSelectBooleanCheckbox getReplenBind() {
        return replenBind;
    }

    public void setDirecImBind(RichSelectBooleanCheckbox direcImBind) {
        this.direcImBind = direcImBind;
    }

    public RichSelectBooleanCheckbox getDirecImBind() {
        return direcImBind;
    }

    public void setFreightBind(RichSelectBooleanCheckbox freightBind) {
        this.freightBind = freightBind;
    }

    public RichSelectBooleanCheckbox getFreightBind() {
        return freightBind;
    }

    public void setTaxBind(RichSelectBooleanCheckbox taxBind) {
        this.taxBind = taxBind;
    }

    public RichSelectBooleanCheckbox getTaxBind() {
        return taxBind;
    }

    public void setChargeBind(RichSelectBooleanCheckbox chargeBind) {
        this.chargeBind = chargeBind;
    }

    public RichSelectBooleanCheckbox getChargeBind() {
        return chargeBind;
    }

    public void setPriExcBind(RichSelectBooleanCheckbox priExcBind) {
        this.priExcBind = priExcBind;
    }

    public RichSelectBooleanCheckbox getPriExcBind() {
        return priExcBind;
    }

    public void setOtyExcBind(RichSelectBooleanCheckbox otyExcBind) {
        this.otyExcBind = otyExcBind;
    }

    public RichSelectBooleanCheckbox getOtyExcBind() {
        return otyExcBind;
    }

    public void setFreighExcBind(RichSelectBooleanCheckbox freighExcBind) {
        this.freighExcBind = freighExcBind;
    }

    public RichSelectBooleanCheckbox getFreighExcBind() {
        return freighExcBind;
    }

    public void setOtherExcBind(RichSelectBooleanCheckbox otherExcBind) {
        this.otherExcBind = otherExcBind;
    }

    public RichSelectBooleanCheckbox getOtherExcBind() {
        return otherExcBind;
    }


    public void poTypeDropShipValueChange(ValueChangeEvent valueChangeEvent) {

        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeDropShip = "Y";

        } else {

            poTypeDropShip = "N";


        }

    }

    public void poTypeFrontDoorValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeFrontDoor = "Y";

        } else {

            poTypeFrontDoor = "N";


        }
    }

    public void poTypeNonCodeValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeNonCode = "Y";

        } else {

            poTypeNonCode = "N";


        }
    }

    public void poTypeConsValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeCons = "Y";

        } else {

            poTypeCons = "N";


        }
    }

    public void poTypeTradeValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeTrade = "Y";

        } else {

            poTypeTrade = "N";


        }
    }

    public void poTypeNewStoreValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeNewStore = "Y";

        } else {

            poTypeNewStore = "N";


        }
    }

    public void poTypeReplenValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeReplen = "Y";

        } else {

            poTypeReplen = "N";


        }
    }

    public void poTypeDirectImportValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            poTypeDirectImport = "Y";

        } else {

            poTypeDirectImport = "N";


        }
    }

    public void freightValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            freight = "Y";

        } else {

            freight = "N";

        }
    }

    public void taxValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            tax = "Y";

        } else {

            tax = "N";

        }


    }

    public void chargebackValueChange(ValueChangeEvent valueChangeEvent) {


        if ((Boolean) valueChangeEvent.getNewValue()) {
            chargebackStatus = "Y";

        } else {

            chargebackStatus = "N";
        }
    }

    public void priceExcValueChange(ValueChangeEvent valueChangeEvent) {

        if ((Boolean) valueChangeEvent.getNewValue()) {
            priceExce = "Y";

        } else {

            priceExce = "N";

        }
    }

    public void qtyExcValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            qtyExce = "Y";

        } else {

            qtyExce = "N";

        }
    }

    public void freightExcValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            freightExce = "Y";

        } else {

            freightExce = "N";
        }
    }

    public void otherExcValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            otherExce = "Y";

        } else {

            otherExce = "N";

        }
    }


    public void setChargebackStatus(String chargebackStatus) {
        this.chargebackStatus = chargebackStatus;
    }

    public String getChargebackStatus() {
        return chargebackStatus;
    }

    public void setGlDateRangeToBind(RichInputDate glDateRangeToBind) {
        this.glDateRangeToBind = glDateRangeToBind;
    }

    public RichInputDate getGlDateRangeToBind() {
        return glDateRangeToBind;
    }

    public void setResultHeaderTabBind(RichTable resultHeaderTabBind) {
        this.resultHeaderTabBind = resultHeaderTabBind;
    }

    public RichTable getResultHeaderTabBind() {
        return resultHeaderTabBind;
    }

    public void setHeaderPanelCollBind(RichPanelCollection headerPanelCollBind) {
        this.headerPanelCollBind = headerPanelCollBind;
    }

    public RichPanelCollection getHeaderPanelCollBind() {
        return headerPanelCollBind;
    }

    public void setItemPanelCollBind(RichPanelCollection itemPanelCollBind) {
        this.itemPanelCollBind = itemPanelCollBind;
    }

    public RichPanelCollection getItemPanelCollBind() {
        return itemPanelCollBind;
    }

    public void setItemTabBind(RichTable itemTabBind) {
        this.itemTabBind = itemTabBind;
    }

    public RichTable getItemTabBind() {
        return itemTabBind;
    }


    public void invoicNumDetailsListener(javax.faces.event.ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();
        FacesContext faceCont = FacesContext.getCurrentInstance();
        oracle.jbo.domain.Number invNum = (oracle.jbo.domain.Number) sourceLink.getAttributes().get("InvoiceId");

        String errMsg = "";

        if (((poDateRangeFromBind.getValue() != null && poDateRangeToBind.getValue() != null) &&
             (invoiceDateRangFromBind.getValue() == null && invoiceDateRangeToBind.getValue() == null) &&
             (glDateRangFromBind.getValue() == null && glDateRangeToBind.getValue() == null)) ||
            ((poDateRangeFromBind.getValue() == null && poDateRangeToBind.getValue() == null) &&
             (glDateRangFromBind.getValue() == null && glDateRangeToBind.getValue() == null) &&
             (invoiceDateRangFromBind.getValue() != null && invoiceDateRangeToBind.getValue() != null)) ||
            ((poDateRangeFromBind.getValue() == null && poDateRangeToBind.getValue() == null) &&
             (glDateRangFromBind.getValue() != null && glDateRangeToBind.getValue() != null) &&
             (invoiceDateRangFromBind.getValue() == null && invoiceDateRangeToBind.getValue() == null))) {

            
            searchMap.put("invNum", invNum);
            searchMap.put("chargebackStatus", chargebackStatus);

            OperationBinding opBindSearchCharBack = ADFUtils.findOperation("searchInvoicePaymentInqItem");
            opBindSearchCharBack.getParamsMap().put("trMaInvoicePaymentMap", searchMap);

            Object result = opBindSearchCharBack.execute();
            logger.info("Result " + result);
            if ("success".equals(result)) {

                dummyTableBind.setRendered(false);
                itemPanelCollBind.setRendered(true);
                itemTabBind.setRendered(true);


            }
        } else {


            errMsg = "Please enter PO Date Range OR Invoice Date Range OR GL Date Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;


        }


        AdfFacesContext.getCurrentInstance().addPartialTarget(itemPanelCollBind);
    }

    public void setPoNumBind(RichInputListOfValues poNumBind) {
        this.poNumBind = poNumBind;
    }

    public RichInputListOfValues getPoNumBind() {
        return poNumBind;
    }

    public void setInvoiceSrcBind(RichInputListOfValues invoiceSrcBind) {
        this.invoiceSrcBind = invoiceSrcBind;
    }

    public RichInputListOfValues getInvoiceSrcBind() {
        return invoiceSrcBind;
    }

    public void setInvTypBind(RichInputListOfValues invTypBind) {
        this.invTypBind = invTypBind;
    }

    public RichInputListOfValues getInvTypBind() {
        return invTypBind;
    }


    public void setInvValiBind(RichSelectOneChoice invValiBind) {
        this.invValiBind = invValiBind;
    }

    public RichSelectOneChoice getInvValiBind() {
        return invValiBind;
    }


    public void setPayNumBind(RichInputListOfValues payNumBind) {
        this.payNumBind = payNumBind;
    }

    public RichInputListOfValues getPayNumBind() {
        return payNumBind;
    }

    public void setPayStatusBind(RichSelectOneChoice payStatusBind) {
        this.payStatusBind = payStatusBind;
    }

    public RichSelectOneChoice getPayStatusBind() {
        return payStatusBind;
    }

    public void setHdrInvoiceAmountBind(RichOutputText hdrInvoiceAmountBind) {
        this.hdrInvoiceAmountBind = hdrInvoiceAmountBind;
    }

    public RichOutputText getHdrInvoiceAmountBind() {
        return hdrInvoiceAmountBind;
    }

    public void setHdrFreightAmountBind(RichOutputText hdrFreightAmountBind) {
        this.hdrFreightAmountBind = hdrFreightAmountBind;
    }

    public RichOutputText getHdrFreightAmountBind() {
        return hdrFreightAmountBind;
    }

    public void setHdrTaxAmountBind(RichOutputText hdrTaxAmountBind) {
        this.hdrTaxAmountBind = hdrTaxAmountBind;
    }

    public RichOutputText getHdrTaxAmountBind() {
        return hdrTaxAmountBind;
    }

    public void setInvNumTextBind(RichInputText invNumTextBind) {
        this.invNumTextBind = invNumTextBind;
    }

    public RichInputText getInvNumTextBind() {
        return invNumTextBind;
    }

    public void setRecordCountOuptput(RichOutputText recordCountOuptput) {
        this.recordCountOuptput = recordCountOuptput;
    }

    public RichOutputText getRecordCountOuptput() {
        return recordCountOuptput;
    }

    public void setRecordCountLineVal(RichOutputText recordCountLineVal) {
        this.recordCountLineVal = recordCountLineVal;
    }

    public RichOutputText getRecordCountLineVal() {
        return recordCountLineVal;
    }
}
