package od.tdmatch.view.managedBeans;

import java.io.Serializable;

import javax.faces.application.FacesMessage;
import javax.faces.application.ViewHandler;
import javax.faces.component.UIViewRoot;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;

import od.tdmatch.model.TradeMatchAMImpl;

import oracle.adf.controller.ControllerContext;
import oracle.adf.controller.TaskFlowId;
//import oracle.adf.controller.internal.binding.DCTaskFlowBinding;
import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCDataControl;
import oracle.adf.view.rich.component.rich.fragment.RichRegion;
import oracle.adf.view.rich.component.rich.nav.RichLink;
import oracle.adf.view.rich.context.AdfFacesContext;

//import oracle.adfinternal.view.faces.bi.util.JsfUtils;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;
import java.util.MissingResourceException;
import java.util.ResourceBundle;

import javax.el.ELContext;
import javax.el.ExpressionFactory;
import javax.el.MethodExpression;
import javax.el.ValueExpression;

import javax.faces.application.Application;
import javax.faces.application.FacesMessage;
import javax.faces.component.UIComponent;
import javax.faces.component.UIViewRoot;
import javax.faces.context.ExternalContext;
import javax.faces.context.FacesContext;

import javax.servlet.http.HttpServletRequest;

public class MootSummaryBean implements Serializable {
    private String taskFlowId = "/WEB-INF/emp-vend-summary-btf.xml#emp-vend-summary-btf";
    private String tabTitle = "Match Error Employee's Workable Summary";
    private String EmployeeId = null;
    private RichLink dynamicregion;
    private RichRegion dynamicregionbind;

    public MootSummaryBean() {
    }
    public void executeVAEmpVendorSummaryVO(){
        System.out.println("Executing the Method before navigating!");
    }
    public String getTabTitle(){
        return tabTitle;
    }
    
    public void setTabTitle(){
        tabTitle = "Office Depot-AP Trade - Match Exception - Employee's Vendor Summary";
    }

    public TaskFlowId getDynamicTaskFlowId() {
        return TaskFlowId.parse(taskFlowId);
    }

    public void setDynamicTaskFlowId(String taskFlowId) {
        this.taskFlowId = taskFlowId;
    }
    
    public String setMootSummary(){
        
        taskFlowId = "/WEB-INF/emp-vend-summary-btf.xml#emp-vend-summary-btf";
    
     
        return null;
    }
   
    public String setEmployeeVendorSummary(){
    taskFlowId = "/WEB-INF/emp-vend-summary1-btf.xml#emp-vend-summary1-btf";
        this.setTabTitle();
     return null;    
    }

    public String setVendMootDetail(){
    taskFlowId = "/WEB-INF/vend-moot-detail-btf.xml#vend-moot-detail-btf";
        this.setTabTitle();
     return null;    
    }
    
    public String setVendMootDropShip(){
    taskFlowId = "/WEB-INF/vend-moot-dship-btf.xml#vend-moot-dship-btf";
        this.setTabTitle();
     return null;    
    }
    
    public String setGeneralInquiry(){
        taskFlowId = "/WEB-INF/general-inquiry-btf.xml#general-inquiry-btf";

     return null;    
    }
    
    public String setGeneralInquiryUser(){
        taskFlowId = "/WEB-INF/general-inquiry-info-user-btf.xml#general-inquiry-info-user-btf";

     return null;    
    }
    public String setGeneralInquirySKU(){
        taskFlowId = "/WEB-INF/general-inquiry-sku-btf.xml#general-inquiry-sku-btf";

     return null;    
    }
    public String setInvoicesNotValidated(){
        taskFlowId = "/WEB-INF/invoice-not-validated-btf.xml#invoice-not-validated-btf";

     return null;    
    }
    public String setPaymentAttributes(){
        taskFlowId = "/WEB-INF/payment-attributes-btf.xml#payment-attributes-btf";

     return null;    
    }
    public String setMassReleaseHold(){
        taskFlowId = "/WEB-INF/mass-release-hold-btf.xml#mass-release-hold-btf";

     return null;    
    }
    public String setCostVariance(){
        taskFlowId = "/WEB-INF/cost-variance-btf.xml#cost-variance-btf";

     return null;    
    }
    
    public String setDepartmentCont(){
        taskFlowId = "/WEB-INF/dept-cont-btf.xml#dept-cont-btf";

     return null;    
    }
    
        
    public String setInvoiceDetails(){
           taskFlowId = "/WEB-INF/invoice-detaails-btf.xml#invoice-detaails-btf";

        return null;    
       }
       public String setCostVarianceUser(){
           taskFlowId = "/WEB-INF/cost-variance-user-btf.xml#cost-variance-user-btf";

        return null;    
       }
    
    public void setVendorAssistantForVOQuery(ActionEvent actionEvent) {
        // Add event code here...
        System.out.println("Action Listener is called");
    }

    public void setDynamicregion(RichLink dynamicregion) {
        this.dynamicregion = dynamicregion;
    }

    public RichLink getDynamicregion() {
        return dynamicregion;
    }

    public void setDynamicregionbind(RichRegion dynamicregionbind) {
        this.dynamicregionbind = dynamicregionbind;
    }

    public RichRegion getDynamicregionbind() {
        return dynamicregionbind;
    }
}
