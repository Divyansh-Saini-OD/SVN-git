package od.tdmatch.view.bean;

import java.io.Serializable;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import od.tdmatch.model.reports.vo.ConsignmentRTVSearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputText;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.component.rich.output.RichPanelCollection;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

@SuppressWarnings("oracle.jdeveloper.java.serialversionuid-field-missing")
public class ConsignmentRTVSearchBean  implements Serializable{
    private RichInputText orgIdValBind;
    private RichInputListOfValues supNameValuebind;
    private RichInputListOfValues supNameValBind;
    private RichInputListOfValues supSiteValBind;
    private RichInputListOfValues skuValBind;
    private RichInputListOfValues rtvValBind;
  
    private RichInputDate transDateFromValBind;
    private RichInputDate transDateToValueBind;
  
    private RichInputListOfValues rgaValueBind;
    private RichInputListOfValues locationValueBind;
    private RichInputListOfValues perDateFromValueBind;
    private RichInputListOfValues perToValueBind;
    private RichInputDate transDateToValBind;
    private RichPanelGroupLayout searchAreaBind;
    private RichPanelCollection resultPanelGrpBind;
    private RichInputText skUValueInput;
    private RichOutputText totalExtendVal;


    public ConsignmentRTVSearchBean() {
        super();
    }

    public void setOrgIdValBind(RichInputText orgIdValBind) {
        this.orgIdValBind = orgIdValBind;
    }

    public RichInputText getOrgIdValBind() {
        return orgIdValBind;
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

    public void setRtvValBind(RichInputListOfValues rtvValBind) {
        this.rtvValBind = rtvValBind;
    }

    public RichInputListOfValues getRtvValBind() {
        return rtvValBind;
    }


    public void setTransDateFromValBind(RichInputDate transDateFromValBind) {
        this.transDateFromValBind = transDateFromValBind;
    }

    public RichInputDate getTransDateFromValBind() {
        return transDateFromValBind;
    }

    public void setTransDateToValueBind(RichInputDate transDateToValueBind) {
        this.transDateToValueBind = transDateToValueBind;
    }

    public RichInputDate getTransDateToValueBind() {
        return transDateToValueBind;
    }

 

    public void setRgaValueBind(RichInputListOfValues rgaValueBind) {
        this.rgaValueBind = rgaValueBind;
    }

    public RichInputListOfValues getRgaValueBind() {
        return rgaValueBind;
    }

    public void setLocationValueBind(RichInputListOfValues locationValueBind) {
        this.locationValueBind = locationValueBind;
    }

    public RichInputListOfValues getLocationValueBind() {
        return locationValueBind;
    }


    
    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void consiRTVSearchAction() {
       
        String errMsg = "";

        FacesContext faceCont = FacesContext.getCurrentInstance();
        System.err.println("transDateFromValBind getValue" + transDateFromValBind.getValue());
        System.err.println("transDateToValueBind getValue" + transDateToValueBind.getValue());
        String skuVal = null;
        skuVal = (String) getSkUValueInput().getValue(); 
        if (((transDateFromValBind.getValue() != null && transDateToValueBind.getValue() != null) &&
             (perDateFromValueBind.getValue() == null && perToValueBind.getValue() ==null))
        ||((transDateFromValBind.getValue() == null && transDateToValueBind.getValue() == null) &&
             (perDateFromValueBind.getValue() != null && perToValueBind.getValue() !=null)))
        {
            
            OperationBinding opBindSearchConsignRTV = ADFUtils.findOperation("searchConsignRTV");
            opBindSearchConsignRTV.getParamsMap().put("sku", skuVal); 
            opBindSearchConsignRTV.execute();   
            DCIteratorBinding consgnRTVIterator = ADFUtils.findIterator("ConsgnmntRTVVO1Iterator");
            totalExtendVal.setValue(ADFUtils.totalAmount(consgnRTVIterator, "ExtendedCost"));
           
           
        }
        else
        {
            errMsg = "Please enter Date Range OR Period Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);            
            return; 
           
        }
        
        AdfFacesContext.getCurrentInstance().addPartialTarget(resultPanelGrpBind);
        
    }
    
    public String clearConsignRTVSearch() {


        //supNameValBind.setSubmittedValue(null);
        supSiteValBind.setSubmittedValue(null);
        //skuValBind.setSubmittedValue(null);
        skUValueInput.setSubmittedValue(null);
      //  rtvValBind.setSubmittedValue(null);
        transDateFromValBind.setSubmittedValue(null);
        
        transDateToValueBind.setSubmittedValue(null);
        perDateFromValueBind.setSubmittedValue(null);
        perToValueBind.setSubmittedValue(null);
        rgaValueBind.setSubmittedValue(null);
        locationValueBind.setSubmittedValue(null);
        //  repOptBind.setSubmittedValue(null);
        DCIteratorBinding orderSearchIterBind = (DCIteratorBinding) getBindings().get("ConsignmentRTVSearchVO1Iterator");
        ConsignmentRTVSearchVORowImpl row = (ConsignmentRTVSearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        ConsignmentRTVSearchVORowImpl newRow =
            (ConsignmentRTVSearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
        orderSearchIterBind.getRowSetIterator().insertRow(newRow);

        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);

        return null;
    }

    public void setTransDateToValBind(RichInputDate transDateToValBind) {
        this.transDateToValBind = transDateToValBind;
    }

    public RichInputDate getTransDateToValBind() {
        return transDateToValBind;
    }

    public void setSupNameValuebind(RichInputListOfValues supNameValuebind) {
        this.supNameValuebind = supNameValuebind;
    }

    public RichInputListOfValues getSupNameValuebind() {
        return supNameValuebind;
    }

    public void setSupNameValBind(RichInputListOfValues supNameValBind) {
        this.supNameValBind = supNameValBind;
    }

    public RichInputListOfValues getSupNameValBind() {
        return supNameValBind;
    }

    public void setSearchAreaBind(RichPanelGroupLayout searchAreaBind) {
        this.searchAreaBind = searchAreaBind;
    }

    public RichPanelGroupLayout getSearchAreaBind() {
        return searchAreaBind;
    }

    public void setResultPanelGrpBind(RichPanelCollection resultPanelGrpBind) {
        this.resultPanelGrpBind = resultPanelGrpBind;
    }

    public RichPanelCollection getResultPanelGrpBind() {
        return resultPanelGrpBind;
    }

    public void setPerDateFromValueBind(RichInputListOfValues perDateFromValueBind) {
        this.perDateFromValueBind = perDateFromValueBind;
    }

    public RichInputListOfValues getPerDateFromValueBind() {
        return perDateFromValueBind;
    }

    public void setPerToValueBind(RichInputListOfValues perToValueBind) {
        this.perToValueBind = perToValueBind;
    }

    public RichInputListOfValues getPerToValueBind() {
        return perToValueBind;
    }

    public void setSkUValueInput(RichInputText skUValueInput) {
        this.skUValueInput = skUValueInput;
    }

    public RichInputText getSkUValueInput() {
        return skUValueInput;
    }

    public void setTotalExtendVal(RichOutputText totalExtendVal) {
        this.totalExtendVal = totalExtendVal;
    }

    public RichOutputText getTotalExtendVal() {
        return totalExtendVal;
    }
}
