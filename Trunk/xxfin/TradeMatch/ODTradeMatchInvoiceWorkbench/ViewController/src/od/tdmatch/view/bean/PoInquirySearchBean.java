package od.tdmatch.view.bean;

import java.math.BigDecimal;

import java.util.ArrayList;

import java.util.HashMap;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;
import javax.faces.event.ValueChangeEvent;

import od.tdmatch.model.reports.vo.PoInquirySearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.view.rich.component.rich.RichPopup;
import oracle.adf.view.rich.component.rich.data.RichColumn;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputListOfValues;
import oracle.adf.view.rich.component.rich.input.RichSelectBooleanCheckbox;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.nav.RichLink;
import oracle.adf.view.rich.component.rich.output.RichPanelCollection;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

import oracle.jbo.domain.Number;

import org.apache.commons.lang.StringUtils;

public class PoInquirySearchBean {
    private RichInputListOfValues supNameValBind;
    private RichInputListOfValues supNumValBind;
    private RichInputListOfValues supSiteValBind;
    private RichInputListOfValues skuValBind;
    private RichInputListOfValues poNumValBind;
    private RichInputListOfValues poLineValBind;
    private RichInputListOfValues locationValBind;
    private RichInputDate poDateFromValBind;
    private RichInputDate poDateToValBind;
    private RichInputListOfValues poStatusValBind;
    private RichSelectBooleanCheckbox dropshipValBind;
    private RichSelectBooleanCheckbox frontdoorValBind;
    private RichSelectBooleanCheckbox nonCodeValBind;
    private RichSelectBooleanCheckbox consignValBind;
    private RichSelectBooleanCheckbox tradeValBind;
    private RichSelectBooleanCheckbox newStoreValBind;
    private RichSelectBooleanCheckbox replenValBind;
    private RichSelectBooleanCheckbox dirImpValBind;
    private RichPanelCollection resultPanelHdrGrpBind;
    private RichPanelCollection resultPanelLineGrpBind;
    private RichPanelGroupLayout searchAreaBind;
    
    private RichLink poNumbind;
    private RichColumn poHdrIbind;
    private RichColumn poHdrIdbind;
    private BigDecimal poHdrId;
    private Number poLineId;
    private RichLink receiptNumberbind;
    private RichPopup receiptPopBind;
    private RichPopup writeOffPopBind;
    private RichPopup invoicePopBind;
    private RichLink invNumberbind;
    private RichLink writeOffAmtbind;
    private RichPanelCollection viewPoRecPopup;
    private String dropshipVal="N";
    private String frontDoorVal="N";
    private String nonCodeVal="N";
    private String consignmentVal="N";
    private String tradeVal="N";
    private String newStoreVal="N";
    private String replenishmentVal="N";
    private String directImportVal="N";
    private long recordCount;

    public PoInquirySearchBean() {
    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void searchPO() {
        // Add event code here...
        String errMsg = "";

        FacesContext faceCont = FacesContext.getCurrentInstance();
        System.err.println("PoDateFromValBind getValue" + poDateFromValBind.getValue());
        System.err.println("PoDateToValBind getValue" + poDateToValBind.getValue());
        System.err.println("poNumValBind getValue" + poNumValBind.getValue());
        oracle.jbo.domain.Number gorgIVale = (oracle.jbo.domain.Number) ADFUtils.getBoundAttributeValue("OrgIdValue");
        System.err.println("gorgIVale>>>>" + gorgIVale);
        
        if(gorgIVale == null){
                gorgIVale =new oracle.jbo.domain.Number(404);
            
            }
        
        
        HashMap poTypeMap = new HashMap();
           poTypeMap.put("dropshipVal",dropshipVal);
           poTypeMap.put("frontDoorVal",frontDoorVal);
           poTypeMap.put("nonCodeVal",nonCodeVal);
           poTypeMap.put("consignmentVal",consignmentVal);
           poTypeMap.put("tradeVal",tradeVal);
           poTypeMap.put("newStoreVal",newStoreVal);
           poTypeMap.put("replenishmentVal",replenishmentVal);
           poTypeMap.put("directImportVal",directImportVal);
        if ((poNumValBind.getValue() == null) || "".equals(poNumValBind.getValue()))
            System.err.println("inside nullof PO");
        else
            System.err.println("inside not null of PO");

        if (poDateFromValBind.getValue() == null && poDateToValBind.getValue() == null &&
            ((poNumValBind.getValue() == null) || "".equals(poNumValBind.getValue()))) {
            errMsg = "Please either provide PO Number or PO Date Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;
        } else if ((poNumValBind.getValue() == null || "".equals(poNumValBind.getValue())) &&
                   (poDateFromValBind.getValue() != null && poDateToValBind.getValue() != null)) {
            System.err.println("inside if of  date range proivided, po num is null");
            

            OperationBinding opBindSearchPoInquiry = ADFUtils.findOperation("searchPoInquiry");
            opBindSearchPoInquiry.getParamsMap().put("poTypeMap", poTypeMap);
            opBindSearchPoInquiry.getParamsMap().put("poNum", poNumValBind.getValue());
            opBindSearchPoInquiry.getParamsMap().put("orgId", gorgIVale);
            opBindSearchPoInquiry.execute();
            OperationBinding opBindclearPoLine = ADFUtils.findOperation("clearPoDetails");
            opBindclearPoLine.execute();
        } else if ((poNumValBind.getValue() != null || !"".equals(poNumValBind.getValue())) &&
                   (poDateFromValBind.getValue() == null && poDateToValBind.getValue() == null)) {
            System.err.println("inside if of PO num provided, date is null");
           

            OperationBinding opBindSearchPoInquiry = ADFUtils.findOperation("searchPoInquiry");
            opBindSearchPoInquiry.getParamsMap().put("poTypeMap", poTypeMap);
            opBindSearchPoInquiry.getParamsMap().put("poNum", poNumValBind.getValue());
            opBindSearchPoInquiry.getParamsMap().put("orgId", gorgIVale);
            opBindSearchPoInquiry.execute();
            OperationBinding opBindclearPoLine = ADFUtils.findOperation("clearPoDetails");
            opBindclearPoLine.execute();
        } else if ((poNumValBind.getValue() != null || !"".equals(poNumValBind.getValue())) &&
                   (poDateFromValBind.getValue() != null && poDateToValBind.getValue() != null)) {
            System.err.println("inside if of all 3 provided");
            

            OperationBinding opBindSearchPoInquiry = ADFUtils.findOperation("searchPoInquiry");
            opBindSearchPoInquiry.getParamsMap().put("poTypeMap", poTypeMap);
            opBindSearchPoInquiry.getParamsMap().put("poNum", poNumValBind.getValue());
            opBindSearchPoInquiry.getParamsMap().put("orgId", gorgIVale);
            opBindSearchPoInquiry.execute();
            OperationBinding opBindclearPoLine = ADFUtils.findOperation("clearPoDetails");
            opBindclearPoLine.execute();
        }

        else {
            errMsg = "Please either provide PO Number or PO Date Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);
            return;

        }
        DCIteratorBinding iteratMainValue = ADFUtils.findIterator("PoInquiryMainVO1Iterator");
       
        recordCount= iteratMainValue.getRowSetIterator().getRowCount();
        
        if(recordCount==1){
            
            if(iteratMainValue.getCurrentRow().getAttribute("PoNumber")==null){
                
                    recordCount =0;
                }
            
            }
       
        AdfFacesContext.getCurrentInstance().addPartialTarget(resultPanelHdrGrpBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(resultPanelLineGrpBind);

    }


    public void setSupNameValBind(RichInputListOfValues supNameValBind) {
        this.supNameValBind = supNameValBind;
    }

    public RichInputListOfValues getSupNameValBind() {
        return supNameValBind;
    }

    public void setSupNumValBind(RichInputListOfValues supNumValBind) {
        this.supNumValBind = supNumValBind;
    }

    public RichInputListOfValues getSupNumValBind() {
        return supNumValBind;
    }

    public void setSupSiteValBind(RichInputListOfValues supSiteValBind) {
        this.supSiteValBind = supSiteValBind;
    }

    public RichInputListOfValues getSupSiteValBind() {
        return supSiteValBind;
    }

    public void setSkuValBind(RichInputListOfValues skuValBind) {
        this.skuValBind = skuValBind;
    }

    public RichInputListOfValues getSkuValBind() {
        return skuValBind;
    }

    public void setPoNumValBind(RichInputListOfValues poNumValBind) {
        this.poNumValBind = poNumValBind;
    }

    public RichInputListOfValues getPoNumValBind() {
        return poNumValBind;
    }

    public void setPoLineValBind(RichInputListOfValues poLineValBind) {
        this.poLineValBind = poLineValBind;
    }

    public RichInputListOfValues getPoLineValBind() {
        return poLineValBind;
    }

    public void setLocationValBind(RichInputListOfValues locationValBind) {
        this.locationValBind = locationValBind;
    }

    public RichInputListOfValues getLocationValBind() {
        return locationValBind;
    }

    public void setPoDateFromValBind(RichInputDate poDateFromValBind) {
        this.poDateFromValBind = poDateFromValBind;
    }

    public RichInputDate getPoDateFromValBind() {
        return poDateFromValBind;
    }

    public void setPoDateToValBind(RichInputDate poDateToValBind) {
        this.poDateToValBind = poDateToValBind;
    }

    public RichInputDate getPoDateToValBind() {
        return poDateToValBind;
    }

    public void setPoStatusValBind(RichInputListOfValues poStatusValBind) {
        this.poStatusValBind = poStatusValBind;
    }

    public RichInputListOfValues getPoStatusValBind() {
        return poStatusValBind;
    }

    public void setDropshipValBind(RichSelectBooleanCheckbox dropshipValBind) {
        this.dropshipValBind = dropshipValBind;
    }

    public RichSelectBooleanCheckbox getDropshipValBind() {
        return dropshipValBind;
    }

    public void setFrontdoorValBind(RichSelectBooleanCheckbox frontdoorValBind) {
        this.frontdoorValBind = frontdoorValBind;
    }

    public RichSelectBooleanCheckbox getFrontdoorValBind() {
        return frontdoorValBind;
    }

    public void setNonCodeValBind(RichSelectBooleanCheckbox nonCodeValBind) {
        this.nonCodeValBind = nonCodeValBind;
    }

    public RichSelectBooleanCheckbox getNonCodeValBind() {
        return nonCodeValBind;
    }

    public void setConsignValBind(RichSelectBooleanCheckbox consignValBind) {
        this.consignValBind = consignValBind;
    }

    public RichSelectBooleanCheckbox getConsignValBind() {
        return consignValBind;
    }

    public void setTradeValBind(RichSelectBooleanCheckbox tradeValBind) {
        this.tradeValBind = tradeValBind;
    }

    public RichSelectBooleanCheckbox getTradeValBind() {
        return tradeValBind;
    }

    public void setNewStoreValBind(RichSelectBooleanCheckbox newStoreValBind) {
        this.newStoreValBind = newStoreValBind;
    }

    public RichSelectBooleanCheckbox getNewStoreValBind() {
        return newStoreValBind;
    }

    public void setReplenValBind(RichSelectBooleanCheckbox replenValBind) {
        this.replenValBind = replenValBind;
    }

    public RichSelectBooleanCheckbox getReplenValBind() {
        return replenValBind;
    }

    public void setDirImpValBind(RichSelectBooleanCheckbox dirImpValBind) {
        this.dirImpValBind = dirImpValBind;
    }

    public RichSelectBooleanCheckbox getDirImpValBind() {
        return dirImpValBind;
    }

    public void setResultPanelHdrGrpBind(RichPanelCollection resultPanelHdrGrpBind) {
        this.resultPanelHdrGrpBind = resultPanelHdrGrpBind;
    }

    public RichPanelCollection getResultPanelHdrGrpBind() {
        return resultPanelHdrGrpBind;
    }

    public void setResultPanelLineGrpBind(RichPanelCollection resultPanelLineGrpBind) {
        this.resultPanelLineGrpBind = resultPanelLineGrpBind;
    }

    public RichPanelCollection getResultPanelLineGrpBind() {
        return resultPanelLineGrpBind;
    }

    public void setSearchAreaBind(RichPanelGroupLayout searchAreaBind) {
        this.searchAreaBind = searchAreaBind;
    }

    public RichPanelGroupLayout getSearchAreaBind() {
        return searchAreaBind;
    }

    public void poTypeDropshipValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            dropshipVal="Y";

        } else {

            dropshipVal="N";


        }

    }

    public void poTypeFrontDoorValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            frontDoorVal ="Y";

        } else {

            frontDoorVal ="N";


        }
    }

    public void poTypeNonCodeValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            nonCodeVal="Y";

        } else {

            nonCodeVal="N";

        }
    }

    public void poTypeConsignmentValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            consignmentVal="Y";

        } else {

                consignmentVal="N";


        }
    }

    public void poTypeTradeValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            tradeVal="Y";

        } else {

            tradeVal="N";


        }
    }

    public void poTypeNewStoreValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            newStoreVal="Y";

        } else {

            newStoreVal="N";


        }
    }

    public void poTypeReplenishmentValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
          replenishmentVal="Y";

        } else {

                replenishmentVal="N";


        }
    }

    public void poTypeDirectImportValueChange(ValueChangeEvent valueChangeEvent) {
        if ((Boolean) valueChangeEvent.getNewValue()) {
            directImportVal="Y";

        } else {

                directImportVal="N";


        }
    }

    public void viewPOLinesListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();

        //   this.setpoHdrId((Number) sourceLink.getAttributes().get("PoHeaderId"));


        System.err.println(">>>setpoHdrId" + sourceLink.getAttributes().get("PoHeaderId"));
        if (sourceLink.getAttributes().get("PoHeaderId") != null) {

            java.math.BigDecimal hdrId = (java.math.BigDecimal) sourceLink.getAttributes().get("PoHeaderId");
            this.setpoHdrId((hdrId));
        }
        
        String poNum=(String)sourceLink.getAttributes().get("PoNum");;


        // String poHdrId = this.poHdrId; //poHdrIbind.toString();
        if (poHdrId == null) {
            System.err.println("po header id is null");
        } else {
            //passpotype = new String();
            OperationBinding opBindPoLines = ADFUtils.findOperation("getPoLines");
            opBindPoLines.getParamsMap().put("poHdrId", poHdrId);
            opBindPoLines.getParamsMap().put("poNum", poNum);
            opBindPoLines.execute();
        }
    }

    public void setpoHdrId(BigDecimal poHdrId) {
        this.poHdrId = poHdrId;
    }

    public BigDecimal getpoHdrId() {
        return poHdrId;
    }

    public void setpoLineId(Number poLineId) {
        this.poLineId = poLineId;
    }

    public Number getpoLineId() {
        return poLineId;
    }


    public void setPoNumbind(RichLink poNumbind) {
        this.poNumbind = poNumbind;
    }

    public RichLink getPoNumbind() {
        return poNumbind;
    }

    public void setPoHdrIbind(RichColumn poHdrIbind) {
        this.poHdrIbind = poHdrIbind;
    }

    public RichColumn getPoHdrIbind() {
        return poHdrIbind;
    }

    public void setPoHdrIdbind(RichColumn poHdrIdbind) {
        this.poHdrIdbind = poHdrIdbind;
    }

    public RichColumn getPoHdrIdbind() {
        return poHdrIdbind;
    }

    public void viewPORecPopUpListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();

        this.setpoLineId((Number) sourceLink.getAttributes().get("PoLineId"));


        System.err.println(">>>setpoHdrId" + poLineId);

        // String poHdrId = this.poHdrId; //poHdrIbind.toString();
        if (poLineId == null) {
            System.err.println("po line id is null");
        } else {
            //passpotype = new String();
            OperationBinding opBindPoLines = ADFUtils.findOperation("getRecPopUp");
            opBindPoLines.getParamsMap().put("poLineId", poLineId);
            String ouputVal = (String) opBindPoLines.execute();
            if ("SUCCESS".equals(ouputVal)) {
                RichPopup.PopupHints hints = new RichPopup.PopupHints();
                receiptPopBind.show(hints);
            } else {
                FacesContext faceCont = FacesContext.getCurrentInstance();
                String displayMsg = "There is Single Receipt for this PO Line ";
                FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_INFO, displayMsg, null);
                faceCont.addMessage("INFO", errorMsg);
                return;
            }
            AdfFacesContext.getCurrentInstance().addPartialTarget(viewPoRecPopup);
        }
    }

    public void setReceiptNumberbind(RichLink receiptNumberbind) {
        this.receiptNumberbind = receiptNumberbind;
    }

    public RichLink getReceiptNumberbind() {
        return receiptNumberbind;
    }

    public void setReceiptPopBind(RichPopup receiptPopBind) {
        this.receiptPopBind = receiptPopBind;
    }

    public RichPopup getReceiptPopBind() {
        return receiptPopBind;
    }

    public void setWriteOffPopBind(RichPopup writeOffPopBind) {
        this.writeOffPopBind = writeOffPopBind;
    }

    public RichPopup getWriteOffPopBind() {
        return writeOffPopBind;
    }

    public void setInvoicePopBind(RichPopup invoicePopBind) {
        this.invoicePopBind = invoicePopBind;
    }

    public RichPopup getInvoicePopBind() {
        return invoicePopBind;
    }

    public void viewPOInvPopUpListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();
        
      oracle.jbo.domain.Number hdrId = (oracle.jbo.domain.Number) sourceLink.getAttributes().get("PoHeaderId");
        
        

        this.setpoLineId((Number) sourceLink.getAttributes().get("PoLineId"));
       // poHdrId

        System.err.println(">>>setpoHdrId" + poHdrId);
        System.err.println(">>>setpoLineId" + poLineId);

        // String poHdrId = this.poHdrId; //poHdrIbind.toString();
        if (poLineId == null) {
            System.err.println("po line id is null");
        } else {
            //passpotype = new String();
            OperationBinding opBindPoLines = ADFUtils.findOperation("getInvPopUp");
            opBindPoLines.getParamsMap().put("poHdrId", hdrId);
            opBindPoLines.getParamsMap().put("poLineId", poLineId);
            String ouputVal = (String) opBindPoLines.execute();
            if ("SUCCESS".equals(ouputVal)) {
                RichPopup.PopupHints hints = new RichPopup.PopupHints();
                invoicePopBind.show(hints);
            } else {
                FacesContext faceCont = FacesContext.getCurrentInstance();
                String displayMsg = "There is Single Invoice for this PO Line ";
                FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_INFO, displayMsg, null);
                faceCont.addMessage("INFO", errorMsg);
                return;
            }
        }
    }

    public void setInvNumberbind(RichLink invNumberbind) {
        this.invNumberbind = invNumberbind;
    }

    public RichLink getInvNumberbind() {
        return invNumberbind;
    }

    public void viewPOWrtoffPopUpListener(ActionEvent actionEvent) {
        RichLink sourceLink = (RichLink) actionEvent.getSource();

        this.setpoLineId((Number) sourceLink.getAttributes().get("PoLineId"));
        oracle.jbo.domain.Number hdrId = (oracle.jbo.domain.Number) sourceLink.getAttributes().get("PoHeaderId");

        System.err.println(">>>setpoHdrId" + poHdrId);
        System.err.println(">>>setpoLineId" + poLineId);

        // String poHdrId = this.poHdrId; //poHdrIbind.toString();
        if (poLineId == null) {
            System.err.println("po line id is null");
        } else {
            //passpotype = new String();
            OperationBinding opBindPoLines = ADFUtils.findOperation("getWriteoffPopUp");
            opBindPoLines.getParamsMap().put("poHdrId", hdrId);
            opBindPoLines.getParamsMap().put("poLineId", poLineId);
            String ouputVal = (String) opBindPoLines.execute();
            if ("SUCCESS".equals(ouputVal)) {
                RichPopup.PopupHints hints = new RichPopup.PopupHints();
                writeOffPopBind.show(hints);
            } else {
                FacesContext faceCont = FacesContext.getCurrentInstance();
                String displayMsg = "There is Single Write off Amount for this PO Line ";
                FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_INFO, displayMsg, null);
                faceCont.addMessage("INFO", errorMsg);
                return;
            }
        }
    }

    public void setWriteOffAmtbind(RichLink writeOffAmtbind) {
        this.writeOffAmtbind = writeOffAmtbind;
    }

    public RichLink getWriteOffAmtbind() {
        return writeOffAmtbind;
    }

    public void clearPoInquirySearch(ActionEvent actionEvent) {
        supNameValBind.setSubmittedValue(null);
        supNumValBind.setSubmittedValue(null);
        supSiteValBind.setSubmittedValue(null);
        skuValBind.setSubmittedValue(null);
        poNumValBind.setSubmittedValue(null);
     //   poLineValBind.setSubmittedValue(null);
        locationValBind.setSubmittedValue(null);
        poDateFromValBind.setSubmittedValue(null);
        poDateToValBind.setSubmittedValue(null);
        //perDateFromValueBind.setSubmittedValue(null);
        //perToValueBind.setSubmittedValue(null);
        poStatusValBind.setSubmittedValue(null);
      
        dropshipValBind.setSubmittedValue("N");
        frontdoorValBind.setSubmittedValue("N");
        nonCodeValBind.setSubmittedValue("N");
        consignValBind.setSubmittedValue("N");
        tradeValBind.setSubmittedValue("N");
        newStoreValBind.setSubmittedValue("N");
        replenValBind.setSubmittedValue("N");
        dirImpValBind.setSubmittedValue("N");

        DCIteratorBinding orderSearchIterBind = (DCIteratorBinding) getBindings().get("PoInquirySearchVO1Iterator");
        PoInquirySearchVORowImpl row = (PoInquirySearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        PoInquirySearchVORowImpl newRow =
            (PoInquirySearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
        orderSearchIterBind.getRowSetIterator().insertRow(newRow);

        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);


    }

    public void setViewPoRecPopup(RichPanelCollection viewPoRecPopup) {
        this.viewPoRecPopup = viewPoRecPopup;
    }

    public RichPanelCollection getViewPoRecPopup() {

        return viewPoRecPopup;
    }

    public void setRecordCount(long recordCount) {
        this.recordCount = recordCount;
    }

    public long getRecordCount() {
        return recordCount;
    }
}
