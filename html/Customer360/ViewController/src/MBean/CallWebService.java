package MBean;

import javax.faces.context.FacesContext;

import oracle.adf.model.BindingContext;

import oracle.adf.model.binding.DCBindingContainer;
import oracle.adf.view.rich.component.rich.input.RichInputText;

import oracle.adf.view.rich.component.rich.layout.RichShowDetail;
import oracle.adf.view.rich.component.rich.nav.RichCommandLink;
import oracle.adf.view.rich.component.rich.nav.RichCommandToolbarButton;
import oracle.adf.view.rich.component.rich.output.RichInlineFrame;

import oracle.adf.view.rich.component.rich.output.RichMessage;
import oracle.adf.view.rich.component.rich.output.RichOutputText;

import oracle.binding.BindingContainer;
import oracle.binding.ControlBinding;
import oracle.binding.OperationBinding;

import oracle.jbo.uicli.binding.JUCtrlAttrsBinding;

public class CallWebService {
    private RichInputText order_CustID;
    private RichInputText aoPS_CustID;
    private RichInputText loyalty_ID;
    private RichInlineFrame dnbframe;
    private RichInlineFrame weatherframe;
    private RichShowDetail infoshowdetail;
    private RichInlineFrame gmap;
    private RichInputText cases_custid;
    private RichCommandLink loySegNext;
    private RichCommandToolbarButton submitB;
    private RichOutputText loyV;
    private RichOutputText segV;
    private RichMessage reportConfirmMsg;

    public CallWebService() {
        super();
    }

    public BindingContainer getBindings() {
        return BindingContext.getCurrent().getCurrentBindingsEntry();
    }

    public String ServiceProcess() {
        
      DCBindingContainer dcbindings =
                  (DCBindingContainer)JSFUtils.resolveExpression("#{bindings}");
      
     /*Begin - Set Values for Order Info Process*/  
    
      JUCtrlAttrsBinding orderinfo_custid =
                 (JUCtrlAttrsBinding)dcbindings.findNamedObject("AOPS_CustID");
      
      JUCtrlAttrsBinding orderinfo_lid =
                 (JUCtrlAttrsBinding)dcbindings.findNamedObject("LoyaltyID");

      orderinfo_custid.setAttributeValue(aoPS_CustID.getValue());
      orderinfo_lid.setAttributeValue(loyalty_ID.getValue());
      
      /*End - Set Values for Order Info Process*/   
      
      
      /*Begin - Set Values for Cases Process*/  
      
       JUCtrlAttrsBinding cases_custid =
                  (JUCtrlAttrsBinding)dcbindings.findNamedObject("AOPS_CustID1");
       
       JUCtrlAttrsBinding cases_lid =
                  (JUCtrlAttrsBinding)dcbindings.findNamedObject("LoyaltyID1");

       cases_custid.setAttributeValue(aoPS_CustID.getValue());
       cases_lid.setAttributeValue(loyalty_ID.getValue());
       
       /*End - Set Values for Cases Process*/   
       
       
       /*Begin - Set Values for Contract Process*/  
       
        JUCtrlAttrsBinding contract_custid =
                   (JUCtrlAttrsBinding)dcbindings.findNamedObject("AOPS_CustID2");
        
        JUCtrlAttrsBinding contract_lid =
                   (JUCtrlAttrsBinding)dcbindings.findNamedObject("LoyaltyID2");

        contract_custid.setAttributeValue(aoPS_CustID.getValue());
        contract_lid.setAttributeValue(loyalty_ID.getValue());
        
        /*End - Set Values for Contract Process*/   
        
        BindingContainer bindings = getBindings();
  
        OperationBinding operationBinding = bindings.getOperationBinding("process");
        
        
        /*Begin -  Execute Order Info*/ 
        OperationBinding operationOrderInfo = bindings.getOperationBinding("process1");
        operationOrderInfo.execute();
        /*End -  Execute Order Info*/
        
        /*Begin -  Execute cases Info*/ 
        OperationBinding operationcasesInfo = bindings.getOperationBinding("process2");
        operationcasesInfo.execute();
        /*End -  Execute cases Info*/
        
        /*Begin -  Execute contract Info*/ 
        OperationBinding operationcontractInfo = bindings.getOperationBinding("process3");
        operationcontractInfo.execute();
        /*End -  Execute contract Info*/
        
      
      Object result = operationBinding.execute();
      
      //System.out.println("Deepak:" + JSFUtils.resolveExpression("#{bindings.CustInfoBusinessName.inputValue}"));
      
      //dnbframe.setSource("http://www.google.com/search?q=" + JSFUtils.resolveExpression("#{bindings.CustInfoBusinessName.inputValue}"));
      String pcode = (String)JSFUtils.resolveExpression("#{bindings.CustInfoZip.inputValue}");
      if (pcode != null) pcode=pcode.substring(0,5);
       weatherframe.setSource("http://voap.weather.com/weather/oap/" + pcode + "?template=TRVLH&par=3000000007&unit=0&key=twciweatherwidget");
       gmap.setSource("http://www.geocodezip.com/example_geo2.asp?geocode=1&addr1=" + pcode);
      
      /* Code To Set Loyalty and Segmentation Values*/
        loyV.setValue(JSFUtils.resolveExpression("#{bindings.meaning.inputValue}"));
        OperationBinding loysegN = bindings.getOperationBinding("Next");
        loysegN.execute();
        segV.setValue(JSFUtils.resolveExpression("#{bindings.meaning.inputValue}"));
      /* Code To Set Loyalty and Segmentation Values*/  
      
       infoshowdetail.setDisclosed(true); 
       
      
       
        if (!operationBinding.getErrors().isEmpty()) {
            return null;
        }
        return null;
    }

    public void setOrder_CustID(RichInputText order_CustID) {
        this.order_CustID = order_CustID;
    }

    public RichInputText getOrder_CustID() {
        return order_CustID;
    }

    public void setAoPS_CustID(RichInputText aoPS_CustID) {
        this.aoPS_CustID = aoPS_CustID;
    }

    public RichInputText getAoPS_CustID() {
        return aoPS_CustID;
    }

    public void setLoyalty_ID(RichInputText loyalty_ID) {
        this.loyalty_ID = loyalty_ID;
    }

    public RichInputText getLoyalty_ID() {
        return loyalty_ID;
    }

    public void setDnbframe(RichInlineFrame dnbframe) {
        this.dnbframe = dnbframe;
    }

    public RichInlineFrame getDnbframe() {
        return dnbframe;
    }

    public void setWeatherframe(RichInlineFrame weatherframe) {
        this.weatherframe = weatherframe;
    }

    public RichInlineFrame getWeatherframe() {
        return weatherframe;
    }

    public void setInfoshowdetail(RichShowDetail infoshowdetail) {
        this.infoshowdetail = infoshowdetail;
    }

    public RichShowDetail getInfoshowdetail() {
        return infoshowdetail;
    }

    public void setGmap(RichInlineFrame gmap) {
        this.gmap = gmap;
    }

    public RichInlineFrame getGmap() {
        return gmap;
    }

    public void setCases_custid(RichInputText cases_custid) {
        this.cases_custid = cases_custid;
    }

    public RichInputText getCases_custid() {
        return cases_custid;
    }

    public void setLoySegNext(RichCommandLink loySegNext) {
        this.loySegNext = loySegNext;
    }

    public RichCommandLink getLoySegNext() {
        return loySegNext;
    }

    public void setSubmitB(RichCommandToolbarButton submitB) {
        this.submitB = submitB;
    }

    public RichCommandToolbarButton getSubmitB() {
        return submitB;
    }

    public void setLoyV(RichOutputText loyV) {
        this.loyV = loyV;
    }

    public RichOutputText getLoyV() {
        return loyV;
    }

    public void setSegV(RichOutputText segV) {
        this.segV = segV;
    }

    public RichOutputText getSegV() {
        return segV;
    }

    public void setReportConfirmMsg(RichMessage reportConfirmMsg) {
        this.reportConfirmMsg = reportConfirmMsg;
    }

    public RichMessage getReportConfirmMsg() {
        return reportConfirmMsg;
    }

    public String reportExecute() {
        reportConfirmMsg.setRendered(true);
        return null;
    }
}
