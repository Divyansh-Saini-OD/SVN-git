package od.tdmatch.view.bean;

/**
 * ==========================================================================================================================================================
 *  Name:  TrMaRTVReconciliationSearchBean.java
 *
 *  Description : This TrMaRTVReconciliationSearchBean has methods related validations of adjustment criteria jsff for Trade Match chargeback summary report.
 *
 * @Author: Prabeethsoy Nair
 * @version: 1.0
 *
 *
 * ============================================================================================================================================================
 */

import java.io.Serializable;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import od.tdmatch.model.reports.vo.XxApRTVReconciliationSearchVORowImpl;
import od.tdmatch.view.utils.ADFUtils;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCIteratorBinding;
import oracle.adf.share.logging.ADFLogger;
import oracle.adf.view.rich.component.rich.input.RichInputComboboxListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputDate;
import oracle.adf.view.rich.component.rich.input.RichInputListOfValues;
import oracle.adf.view.rich.component.rich.input.RichInputText;
import oracle.adf.view.rich.component.rich.layout.RichPanelGroupLayout;
import oracle.adf.view.rich.component.rich.output.RichOutputText;
import oracle.adf.view.rich.component.rich.output.RichPanelCollection;
import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.BindingContainer;
import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.RowSetIterator;

import oracle.sql.NUMBER;

@SuppressWarnings("oracle.jdeveloper.java.serialversionuid-field-missing")
public class TrMaRTVReconciliationSearchBean implements Serializable {
    private static ADFLogger logger = ADFLogger.createADFLogger(TrMaRTVReconciliationSearchBean.class);

    private RichInputComboboxListOfValues orgIdBind;

    private RichInputText orgIdNonRendBind;
    private RichInputDate invDateRageFromBind;
    private RichInputDate invDateRangeToBind;
    private RichInputListOfValues perRangToBind;
    private RichInputListOfValues perRangFromBind;
    private RichPanelGroupLayout searchAreaBind;
    private RichOutputText caRegValuBind;
    private RichOutputText caOptWeekBind;
    private RichOutputText caOtpMonBind;
    private RichOutputText caOptOtrlBind;
    private RichOutputText usRegValBind;
    private RichOutputText usOptWeekBind;
    private RichOutputText usOptMonBind;
    private RichOutputText usOptOtrlBind;
    private RichOutputText totRegValBind;
    private RichOutputText totOptWeekBind;
    private RichOutputText totOptMonBind;
    private RichOutputText totOptOtrBind;
    private RichOutputText caTotalValBind;
    private RichOutputText usTotalVal;
    private RichPanelCollection caPanelGrpBind;
    private RichPanelCollection usPanelGrpBind;
    private RichPanelCollection totPanelGrpBind;
    private RichOutputText totTotalBind;


    public TrMaRTVReconciliationSearchBean() {
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

    public void rtvReconSearch() {
        
        
        String errMsg = "";

        FacesContext faceCont = FacesContext.getCurrentInstance();
            
        
        if (((invDateRageFromBind.getValue() != null && invDateRangeToBind.getValue() != null) &&
             (perRangFromBind.getValue() == null && perRangToBind.getValue() ==null))
        ||((invDateRageFromBind.getValue() == null && invDateRangeToBind.getValue() == null) &&
             (perRangFromBind.getValue() != null && perRangToBind.getValue() !=null)))
        {

            OperationBinding opBindSearchRTVRcon = ADFUtils.findOperation("searchRTVRecon");
            opBindSearchRTVRcon.execute();
           
        }
        else
        {
            errMsg = "Please enter Invoice Date Range OR Period Range";
            FacesMessage errorMsg = new FacesMessage(FacesMessage.SEVERITY_ERROR, errMsg, null);
            faceCont.addMessage("ERROR", errorMsg);            
            return; 
           
        }

   


        DCIteratorBinding caValIter = ADFUtils.findIterator("XxApRTVReconCAVOIterator");
        DCIteratorBinding usValIter = ADFUtils.findIterator("XxApRTVReconUSVOIterator");

        DCIteratorBinding totalValIter = ADFUtils.findIterator("XxApRTVReconTotalVOIterator");


        usRegValBind .setValue(diffCal(usValIter,"Regular"));
        usOptWeekBind.setValue(diffCal(usValIter,"Opt73Weekly"));
        usOptMonBind.setValue(diffCal(usValIter,"Opt73Monthly"));
        usOptOtrlBind.setValue(diffCal(usValIter,"Opt73Qtrly"));
        usTotalVal.setValue(diffCal(usValIter,"TotalVal"));
        
        
       
        
        caRegValuBind .setValue(diffCal(caValIter,"Regular"));
        caOptWeekBind.setValue(diffCal(caValIter,"Opt73Weekly"));
        caOtpMonBind.setValue(diffCal(caValIter,"Opt73Monthly"));
        caOptOtrlBind.setValue(diffCal(caValIter,"Opt73Qtrly"));
        caTotalValBind.setValue(diffCal(caValIter,"Total"));
        
        
        totRegValBind .setValue(diffCal(totalValIter,"Regular"));
        totOptWeekBind.setValue(diffCal(totalValIter,"Opt73Weekly"));
        totOptMonBind.setValue(diffCal(totalValIter,"Opt73Monthly"));
        totOptOtrBind.setValue(diffCal(totalValIter,"Opt73Qtrly"));
        totTotalBind.setValue(diffCal(totalValIter,"Total"));

        AdfFacesContext.getCurrentInstance().addPartialTarget(usPanelGrpBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(caPanelGrpBind);
        AdfFacesContext.getCurrentInstance().addPartialTarget(totPanelGrpBind);
     
    }

    /**
     * @param iteratValue
     * @param attributeName
     * @return
     */
    private Float diffCal(DCIteratorBinding iteratValue,String attributeName){
            NUMBER usWeeklyFirst = new NUMBER();
            NUMBER usWeeklySec = new NUMBER();
            Float usWeeklyDiff = new Float(0.0);
            int i = 0;
            RowSetIterator usValIterRow = iteratValue.getViewObject().createRowSetIterator(null);
            while (usValIterRow.hasNext()) {
                Row usRowVal = usValIterRow.next();
                if (i == 0) {

                    usWeeklyFirst = (NUMBER) usRowVal.getAttribute(attributeName);
                  
                }

                if (i == 1) {
                    usWeeklySec = (NUMBER) usRowVal.getAttribute(attributeName);
                 
                }
              
                i++;
            }
            try {
                
                float ju = usWeeklyFirst.sub(usWeeklySec).floatValue();
                logger.info("Ju... "+ju);
                usWeeklyDiff = usWeeklyFirst.floatValue() - usWeeklySec.floatValue();
            } catch (Exception e) {
                e.printStackTrace();
            }
            logger.info("0  usWeeklyDiff>>>>"+usWeeklyDiff);
        
        return usWeeklyDiff;
        
        }


    public String clearSearch() {


        invDateRageFromBind.setSubmittedValue(null);
        invDateRangeToBind.setSubmittedValue(null);
        perRangToBind.setSubmittedValue(null);
        perRangFromBind.setSubmittedValue(null);

        DCIteratorBinding orderSearchIterBind = ADFUtils.findIterator("XxApRTVReconciliationSearchVOIterator");
        XxApRTVReconciliationSearchVORowImpl row = (XxApRTVReconciliationSearchVORowImpl) orderSearchIterBind.getCurrentRow();
        row.remove();
        XxApRTVReconciliationSearchVORowImpl newRow =
            (XxApRTVReconciliationSearchVORowImpl) orderSearchIterBind.getRowSetIterator().createRow();
        orderSearchIterBind.getRowSetIterator().insertRow(newRow);

        AdfFacesContext.getCurrentInstance().addPartialTarget(searchAreaBind);

        return null;
    }


    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public void setInvDateRageFromBind(RichInputDate invDateRageFromBind) {
        this.invDateRageFromBind = invDateRageFromBind;
    }

    public RichInputDate getInvDateRageFromBind() {
        return invDateRageFromBind;
    }

    public void setInvDateRangeToBind(RichInputDate invDateRangeToBind) {
        this.invDateRangeToBind = invDateRangeToBind;
    }

    public RichInputDate getInvDateRangeToBind() {
        return invDateRangeToBind;
    }

    public void setPerRangToBind(RichInputListOfValues perRangToBind) {
        this.perRangToBind = perRangToBind;
    }

    public RichInputListOfValues getPerRangToBind() {
        return perRangToBind;
    }

    public void setPerRangFromBind(RichInputListOfValues perRangFromBind) {
        this.perRangFromBind = perRangFromBind;
    }

    public RichInputListOfValues getPerRangFromBind() {
        return perRangFromBind;
    }

    public void setSearchAreaBind(RichPanelGroupLayout searchAreaBind) {
        this.searchAreaBind = searchAreaBind;
    }

    public RichPanelGroupLayout getSearchAreaBind() {
        return searchAreaBind;
    }

    public void setCaRegValuBind(RichOutputText caRegValuBind) {
        this.caRegValuBind = caRegValuBind;
    }

    public RichOutputText getCaRegValuBind() {
        return caRegValuBind;
    }

    public void setCaOptWeekBind(RichOutputText caOptWeekBind) {
        this.caOptWeekBind = caOptWeekBind;
    }

    public RichOutputText getCaOptWeekBind() {
        return caOptWeekBind;
    }

    public void setCaOtpMonBind(RichOutputText caOtpMonBind) {
        this.caOtpMonBind = caOtpMonBind;
    }

    public RichOutputText getCaOtpMonBind() {
        return caOtpMonBind;
    }

    public void setCaOptOtrlBind(RichOutputText caOptOtrlBind) {
        this.caOptOtrlBind = caOptOtrlBind;
    }

    public RichOutputText getCaOptOtrlBind() {
        return caOptOtrlBind;
    }

    public void setUsRegValBind(RichOutputText usRegValBind) {
        this.usRegValBind = usRegValBind;
    }

    public RichOutputText getUsRegValBind() {
        return usRegValBind;
    }

    public void setUsOptWeekBind(RichOutputText usOptWeekBind) {
        this.usOptWeekBind = usOptWeekBind;
    }

    public RichOutputText getUsOptWeekBind() {
        return usOptWeekBind;
    }

    public void setUsOptMonBind(RichOutputText usOptMonBind) {
        this.usOptMonBind = usOptMonBind;
    }

    public RichOutputText getUsOptMonBind() {
        return usOptMonBind;
    }

    public void setUsOptOtrlBind(RichOutputText usOptOtrlBind) {
        this.usOptOtrlBind = usOptOtrlBind;
    }

    public RichOutputText getUsOptOtrlBind() {
        return usOptOtrlBind;
    }

    public void setTotRegValBind(RichOutputText totRegValBind) {
        this.totRegValBind = totRegValBind;
    }

    public RichOutputText getTotRegValBind() {
        return totRegValBind;
    }

    public void setTotOptWeekBind(RichOutputText totOptWeekBind) {
        this.totOptWeekBind = totOptWeekBind;
    }

    public RichOutputText getTotOptWeekBind() {
        return totOptWeekBind;
    }

    public void setTotOptMonBind(RichOutputText totOptMonBind) {
        this.totOptMonBind = totOptMonBind;
    }

    public RichOutputText getTotOptMonBind() {
        return totOptMonBind;
    }

    public void setTotOptOtrBind(RichOutputText totOptOtrBind) {
        this.totOptOtrBind = totOptOtrBind;
    }

    public RichOutputText getTotOptOtrBind() {
        return totOptOtrBind;
    }

    public void setCaTotalValBind(RichOutputText caTotalValBind) {
        this.caTotalValBind = caTotalValBind;
    }

    public RichOutputText getCaTotalValBind() {
        return caTotalValBind;
    }

    public void setUsTotalVal(RichOutputText usTotalVal) {
        this.usTotalVal = usTotalVal;
    }

    public RichOutputText getUsTotalVal() {
        return usTotalVal;
    }

    public void setCaPanelGrpBind(RichPanelCollection caPanelGrpBind) {
        this.caPanelGrpBind = caPanelGrpBind;
    }

    public RichPanelCollection getCaPanelGrpBind() {
        return caPanelGrpBind;
    }

    public void setUsPanelGrpBind(RichPanelCollection usPanelGrpBind) {
        this.usPanelGrpBind = usPanelGrpBind;
    }

    public RichPanelCollection getUsPanelGrpBind() {
        return usPanelGrpBind;
    }

    public void setTotPanelGrpBind(RichPanelCollection totPanelGrpBind) {
        this.totPanelGrpBind = totPanelGrpBind;
    }

    public RichPanelCollection getTotPanelGrpBind() {
        return totPanelGrpBind;
    }

    public void setTotTotalBind(RichOutputText totTotalBind) {
        this.totTotalBind = totTotalBind;
    }

    public RichOutputText getTotTotalBind() {
        return totTotalBind;
    }
}
