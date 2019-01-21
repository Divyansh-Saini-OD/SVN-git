package od.tdmatch.view.managedBeans;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

//import javax.faces.el.ValueBinding;

import javax.faces.event.ActionEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.OperationBinding;

import oracle.jbo.ApplicationModule;

import oracle.jbo.ViewCriteria;
import oracle.jbo.ViewCriteriaRow;
import oracle.jbo.ViewObject;

import org.apache.myfaces.trinidad.bean.ValueExpressionValueBinding;

public class InvWkBenchCommonBean {
    private boolean showAllVA = true;
    public InvWkBenchCommonBean() {
        super();
    }
    
    public void toggleQryPanel(){
        System.out.println("in toggleQryPanel");
    }
        
    public void executeVAEmpVendorSummaryVO(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeVAEmpVendorSummary");
          String abc=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pEmployeeId").toString();//"213305";//

           System.out.println("The Vendor Assistant selected is: "+abc);

              operation.getParamsMap().put("pEmployeeId", abc);
              operation.execute();              
        
    }
    
    public void executeVendorMootDtVO(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeVendorMootDtVO");
            String mSuppName=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppName").toString();
            String mSuppSite=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite").toString();
        
            String pMoot = null;
            String pNrf = null;
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pMoot")!=null){
            pMoot=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pMoot").toString();
            }
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pNrf")!=null){
            pNrf=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pNrf").toString();
            }
            if (AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite")!=null){
            mSuppSite=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppSite").toString();
            }
//        String vaName=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("pVAName").toString();
    //           String bca = null;
           System.out.println("The Supplier selected is: "+mSuppName);
          // String name="toVA";
            operation.getParamsMap().put("pSupplierName", mSuppName);
            operation.getParamsMap().put("pSupplierSite", mSuppSite);
            operation.getParamsMap().put("pMoot", pMoot);
            operation.getParamsMap().put("pNrf", pNrf);
//              operation.getParamsMap().put("pVAName", vaName);
              operation.execute();
    }
    
    public void executeSupplerSiteVO(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("executeSupplerSiteVO");
          String abc=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("mSuppName").toString();
    //           String bca = null;
           System.out.println("(executeSupplerSiteVO) The Supplier selected is: "+abc);
          // String name="toVA";
              operation.getParamsMap().put("pSupplierName", abc);
              operation.execute();
    }
    
    public void invoiceDetails(){
        
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initInvoiceDetails");
        System.out.println("inside the method invoiceDetails");
         //  String abc="ABC";
          // String name="toVA";
        String invoiceNo=AdfFacesContext.getCurrentInstance().getPageFlowScope().get("invoiceNo").toString();
        System.out.println("The invoiceNo selected is: "+invoiceNo);
              operation.getParamsMap().put("invoiceNum", invoiceNo);
              operation.execute();
        
    }
    
    public String EmpVendSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("EmpVendSearchAction");
    
            String result=null;
                 result=(String) operation.execute();
//                 load=true;
    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    
    public String EmpVendSearchAction1() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("EmpVendSearchAction1");
    
            String result=null;
                 result=(String) operation.execute();
    //                 load=true;
    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    
    public void clearEmpVendSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearEmpVendSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
              
    }

    
}
