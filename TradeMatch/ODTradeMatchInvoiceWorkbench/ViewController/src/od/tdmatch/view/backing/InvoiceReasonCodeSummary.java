package od.tdmatch.view.backing;

import javax.faces.application.FacesMessage;
import javax.faces.component.UISelectItems;
import javax.faces.context.FacesContext;

import od.tdmatch.model.reports.vo.XxApReasonCodeSearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.view.rich.component.rich.RichMenu;
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
import oracle.adf.view.rich.component.rich.output.RichSpacer;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

public class InvoiceReasonCodeSummary {
    private RichInputComboboxListOfValues orgidId;
    private RichInputText orgIdNonRendBind;
    private RichInputComboboxListOfValues orgIdBind;
    private RichSelectOneRadio sor1;
    private UISelectItems si1;
    private RichInputListOfValues supplierId;
    private RichInputListOfValues suppliernameId;
    private RichInputListOfValues suppliersitenoId;
    private RichInputListOfValues vendorassistantId;
    private RichInputListOfValues suppName;
    private RichInputListOfValues suppBind;
    private RichInputListOfValues skuId;
    private RichInputListOfValues prdRangeFrm;
    private RichInputDate gldDateFrom;
    private RichInputDate gldDateTo;

     private RichInputListOfValues  prdRangeTo;
    private RichButton b1;
    private RichButton b2;
    private RichInputListOfValues reasoncode1Id;
    private RichSelectBooleanCheckbox dropShip;
    private RichSelectOneRadio reportOptionBind;
    private UISelectItems si2;
    private RichInputListOfValues reasonCode;
    private RichTable resSumm;
    private RichMenu m1;
    private RichCommandMenuItem cmi1;
    private RichTable resDtl;
    private RichPanelGroupLayout pgl9;
    private RichPanelGroupLayout pgl10;

    private RichMenu m2;
    private RichCommandMenuItem cmi2;
   
    private RichPanelGroupLayout searchAreaBind;

    private RichInputListOfValues periodrangefromId;
    private RichInputListOfValues periodrangetoId;
    private RichSelectBooleanCheckbox sbc2;
    private RichTable t1;
    private RichTable t2;
    private RichInputListOfValues ilov2;
    private RichPanelGroupLayout pgl13;
  
    private RichSpacer s19;
    private RichSpacer s20;
    private RichInputText skuInpText;
    private RichInputText it2;

    public void setOrgIdBind(RichInputComboboxListOfValues orgIdBind) {
        this.orgIdBind = orgIdBind;
    }

    public RichInputComboboxListOfValues getOrgIdBind() {
        return orgIdBind;
    }
    public void setOrgidId(RichInputComboboxListOfValues orgidId) {
        this.orgidId = orgidId;
    }

    public RichInputComboboxListOfValues getOrgidId() {
        return orgidId;
    }

    public void setOrgIdNonRendBind(RichInputText orgIdNonRendBind) {
        this.orgIdNonRendBind = orgIdNonRendBind;
    }

    public RichInputText getOrgIdNonRendBind() {
        return orgIdNonRendBind;
    }

    public void setSor1(RichSelectOneRadio sor1) {
        this.sor1 = sor1;
    }

    public RichSelectOneRadio getSor1() {
        return sor1;
    }

    public void setSi1(UISelectItems si1) {
        this.si1 = si1;
    }

    public UISelectItems getSi1() {
        return si1;
    }

  
    public void setSupplierId(RichInputListOfValues supplierId) {
        this.supplierId = supplierId;
    }

    public RichInputListOfValues getSupplierId() {
        return supplierId;
    }


    public void setSuppliernameId(RichInputListOfValues suppliernameId) {
        this.suppliernameId = suppliernameId;
    }

    public RichInputListOfValues getSuppliernameId() {
        return suppliernameId;
    }


    public void setSuppliersitenoId(RichInputListOfValues suppliersitenoId) {
        this.suppliersitenoId = suppliersitenoId;
    }

    public RichInputListOfValues getSuppliersitenoId() {
        return suppliersitenoId;
    }


    public void setVendorassistantId(RichInputListOfValues vendorassistantId) {
        this.vendorassistantId = vendorassistantId;
    }

    public RichInputListOfValues getVendorassistantId() {
        return vendorassistantId;
    }

    public void setSkuId(RichInputListOfValues skuId) {
        this.skuId = skuId;
    }

    public RichInputListOfValues getSkuId() {
        return skuId;
    }

    public void setB1(RichButton b1) {
        this.b1 = b1;
    }

    public RichButton getB1() {
        return b1;
    }

    public void setB2(RichButton b2) {
        this.b2 = b2;
    }

    public RichButton getB2() {
        return b2;
    }

    public void setReasoncode1Id(RichInputListOfValues reasoncode1Id) {
        this.reasoncode1Id = reasoncode1Id;
    }

    public RichInputListOfValues getReasoncode1Id() {
        return reasoncode1Id;
    }

    public void setSi2(UISelectItems si2) {
        this.si2 = si2;
    }

    public UISelectItems getSi2() {
        return si2;
    }
 
    public void setM1(RichMenu m1) {
        this.m1 = m1;
    }

    public RichMenu getM1() {
        return m1;
    }

    public void setCmi1(RichCommandMenuItem cmi1) {
        this.cmi1 = cmi1;
    }

    public RichCommandMenuItem getCmi1() {
        return cmi1;
    }

    public void searchInvoiceReasonCodeAction() {
        String errMsg = "";

        FacesContext faceCont = FacesContext.getCurrentInstance();
        System.out.println("the drop ship valyue is "+dropShip.getValue());
        

        if (reportOptionBind.getValue() == null) {
            errMsg = "Please select Report Option";


            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);
            return;

        } 
        
        if ((gldDateFrom.getValue() == null || gldDateTo.getValue() == null)&&(prdRangeFrm.getValue()== null || prdRangeTo.getValue()==null)){

            errMsg = "Please enter GL Date Range Or Period Range.";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);


            faceCont.addMessage("ERROR", errorMsg);
            
            return;

        }
        else{
        System.out.println("the radio button value : : "+reportOptionBind.getValue());
        String reportOption = (String) reportOptionBind.getValue();
            String skuVal = null;
            skuVal = (String) getSkuInpText().getValue();
            System.out.println("the sku value is : : "+getSkuInpText().getValue());
        if("Summary".equals(reportOption)){
            System.out.println("this method is called Reason Code page");          
            OperationBinding opBindSearchReasonCode = ADFUtils.findOperation("searchReasonCodeSumm");
            opBindSearchReasonCode.getParamsMap().put("sku", skuVal);
            opBindSearchReasonCode.execute();
            DCIteratorBinding iteratMainValue = ADFUtils.findIterator("XxApReasonCodeSummaryVO1Iterator");
            iteratMainValue.executeQuery();
            
            getPgl9().setVisible(true);
          //  getPgl9().setRendered(true);
            getPgl10().setVisible(false);
          //  getPgl10().setRendered(false);
          AdfFacesContext.getCurrentInstance().addPartialTarget(pgl9);
            AdfFacesContext.getCurrentInstance().addPartialTarget(pgl10);
        }else{
            System.out.println("this method is called Reason Code Detail page");
            OperationBinding opBindSearchReasonCode = ADFUtils.findOperation("searchReasonCodeDtl");
            opBindSearchReasonCode.getParamsMap().put("sku", skuVal);
            opBindSearchReasonCode.execute();
            DCIteratorBinding iteratMainValue = ADFUtils.findIterator("XxApReasonCodeDetailVO1Iterator");
            iteratMainValue.executeQuery();
            
            getPgl9().setVisible(false);
           // getPgl9().setRendered(false);
            getPgl10().setVisible(true);
           // getPgl10().setRendered(true);
           AdfFacesContext.getCurrentInstance().addPartialTarget(pgl9);
           AdfFacesContext.getCurrentInstance().addPartialTarget(pgl10);
        }
        }
    }
    
    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }
    public String ClearInvoiceReasonCodeAction(){
        System.out.println("the clear method is called//");
     
     
     reportOptionBind.setSubmittedValue(null);
       suppBind.setSubmittedValue(null);
          suppName.setSubmittedValue(null);
          suppliersitenoId.setSubmittedValue(null);
         vendorassistantId.setSubmittedValue(null);
        skuInpText.setSubmittedValue(null);
    
        gldDateFrom.setSubmittedValue(null);
        gldDateTo.setSubmittedValue(null);
       prdRangeFrm.setSubmittedValue(null);
       prdRangeTo.setSubmittedValue(null);
        dropShip.setSubmittedValue(false);
        reasonCode.setSubmittedValue(null);
        DCIteratorBinding orderSearchIterBind = (DCIteratorBinding) getBindings().get("XxApReasonCodeSearchVO1Iterator");
        XxApReasonCodeSearchVORowImpl row = (XxApReasonCodeSearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApReasonCodeSearchVORowImpl newRow =
            (XxApReasonCodeSearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
        orderSearchIterBind.getRowSetIterator().insertRow(newRow);

        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);

       return null;
    }

    public void setReportOptionBind(RichSelectOneRadio reportOptionBind) {
        this.reportOptionBind = reportOptionBind;
    }

    public RichSelectOneRadio getReportOptionBind() {
        return reportOptionBind;
    }

    public void setSuppBind(RichInputListOfValues suppBind) {
        this.suppBind = suppBind;
    }

    public RichInputListOfValues getSuppBind() {
        return suppBind;
    }

    public void setSuppName(RichInputListOfValues suppName) {
        this.suppName = suppName;
    }

    public RichInputListOfValues getSuppName() {
        return suppName;
    }

    public void setGldDateFrom(RichInputDate gldDateFrom) {
        this.gldDateFrom = gldDateFrom;
    }

    public RichInputDate getGldDateFrom() {
        return gldDateFrom;
    }

    public void setGldDateTo(RichInputDate gldDateTo) {
        this.gldDateTo = gldDateTo;
    }

    public RichInputDate getGldDateTo() {
        return gldDateTo;
    }


    public void setReasonCode(RichInputListOfValues reasonCode) {
        this.reasonCode = reasonCode;
    }

    public RichInputListOfValues getReasonCode() {
        return reasonCode;
    }

    public void setDropShip(RichSelectBooleanCheckbox dropShip) {
        this.dropShip = dropShip;
    }

    public RichSelectBooleanCheckbox getDropShip() {
        return dropShip;
    }

    public void setResDtl(RichTable resDtl) {
        this.resDtl = resDtl;
    }

    public RichTable getResDtl() {
        return resDtl;
    }

    public void setResSumm(RichTable resSumm) {
        this.resSumm = resSumm;
    }

    public RichTable getResSumm() {
        return resSumm;
    }

    public void setPgl9(RichPanelGroupLayout pgl9) {
        this.pgl9 = pgl9;
    }

    public RichPanelGroupLayout getPgl9() {
        return pgl9;
    }

    public void setPgl10(RichPanelGroupLayout pgl10) {
        this.pgl10 = pgl10;
    }

    public RichPanelGroupLayout getPgl10() {
        return pgl10;
    }

    
    public void setM2(RichMenu m2) {
        this.m2 = m2;
    }

    public RichMenu getM2() {
        return m2;
    }

    public void setCmi2(RichCommandMenuItem cmi2) {
        this.cmi2 = cmi2;
    }

    public RichCommandMenuItem getCmi2() {
        return cmi2;
    }

  

    public void setSearchAreaBind(RichPanelGroupLayout searchAreaBind) {
        this.searchAreaBind = searchAreaBind;
    }

    public RichPanelGroupLayout getSearchAreaBind() {
        return searchAreaBind;
    }

   
    public void setPrdRangeFrm(RichInputListOfValues prdRangeFrm) {
        this.prdRangeFrm = prdRangeFrm;
    }

    public RichInputListOfValues getPrdRangeFrm() {
        return prdRangeFrm;
    }

    public void setPrdRangeTo(RichInputListOfValues prdRangeTo) {
        this.prdRangeTo = prdRangeTo;
    }

    public RichInputListOfValues getPrdRangeTo() {
        return prdRangeTo;
    }

    public void setPeriodrangefromId(RichInputListOfValues periodrangefromId) {
        this.periodrangefromId = periodrangefromId;
    }

    public RichInputListOfValues getPeriodrangefromId() {
        return periodrangefromId;
    }

    public void setPeriodrangetoId(RichInputListOfValues periodrangetoId) {
        this.periodrangetoId = periodrangetoId;
    }

    public RichInputListOfValues getPeriodrangetoId() {
        return periodrangetoId;
    }

    public void setSbc2(RichSelectBooleanCheckbox sbc2) {
        this.sbc2 = sbc2;
    }

    public RichSelectBooleanCheckbox getSbc2() {
        return sbc2;
    }

    public void setT1(RichTable t1) {
        this.t1 = t1;
    }

    public RichTable getT1() {
        return t1;
    }


    public void setT2(RichTable t2) {
        this.t2 = t2;
    }

    public RichTable getT2() {
        return t2;
    }

    public void setIlov2(RichInputListOfValues ilov2) {
        this.ilov2 = ilov2;
    }

    public RichInputListOfValues getIlov2() {
        return ilov2;
    }

    public void setPgl13(RichPanelGroupLayout pgl13) {
        this.pgl13 = pgl13;
    }

    public RichPanelGroupLayout getPgl13() {
        return pgl13;
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

    public void setSkuInpText(RichInputText skuInpText) {
        this.skuInpText = skuInpText;
    }

    public RichInputText getSkuInpText() {
        return skuInpText;
    }

    public void setIt2(RichInputText it2) {
        this.it2 = it2;
    }

    public RichInputText getIt2() {
        return it2;
    }
}
