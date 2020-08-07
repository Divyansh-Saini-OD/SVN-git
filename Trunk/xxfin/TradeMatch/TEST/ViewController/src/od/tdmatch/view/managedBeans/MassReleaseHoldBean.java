package od.tdmatch.view.managedBeans;

import javax.el.ELContext;
import javax.el.ExpressionFactory;
import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import javax.faces.event.ActionEvent;
import javax.faces.event.ValueChangeEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

public class MassReleaseHoldBean {
    
    String invoiceSum ="$ 0.00";
    String quantityHoldSum="$ 0.00";
    String priceHoldSum="$ 0.00";
    
    public MassReleaseHoldBean() {
        super();
    }

    public String massReleaseAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("massReleaseValidate");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
        String result=null;
             result=(String) operation.execute();
           //  load=true;
        //        FacesMessage fm = new FacesMessage("Your changes haveen been successfully updated.");
        //                /**
        //                 * set the type of the message.
        //                 * Valid types: error, fatal,info,warning
        //                 */
        //                fm.setSeverity(FacesMessage.SEVERITY_INFO);
        //                FacesContext context = FacesContext.getCurrentInstance();
        //                context.addMessage(null, fm);
             
             
             FacesMessage fm=new FacesMessage(result);
             fm.setSeverity(FacesMessage.SEVERITY_ERROR);
             FacesContext context=FacesContext.getCurrentInstance();
             if(result!=null && result.startsWith("Please"))
             context.addMessage(null, fm);
             
             if(result!=null){
                 String sum[]=result.split(",");
                 invoiceSum="$ "+sum[0];
                 quantityHoldSum="$ "+sum[1];
                 priceHoldSum="$ "+sum[2];
             }
        
        return null;
    }

    public void setInvoiceSum(String invoiceSum) {
        this.invoiceSum = invoiceSum;
    }

    public String getInvoiceSum() {
        return invoiceSum;
    }

    public void setQuantityHoldSum(String quantityHoldSum) {
        this.quantityHoldSum = quantityHoldSum;
    }

    public String getQuantityHoldSum() {
        return quantityHoldSum;
    }

    public void setPriceHoldSum(String priceHoldSum) {
        this.priceHoldSum = priceHoldSum;
    }

    public String getPriceHoldSum() {
        return priceHoldSum;
    }
    
    public void initMassRelease(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initMassRelease");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
        String result=null;
             result=(String) operation.execute();
     //   DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
     //   OperationBinding operationInvoice = bindings.getOperationBinding("massReleaseValidate");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
       // String result=null;
        //     result=(String) operationInvoice.execute();
           //  load=true;
        //        FacesMessage fm = new FacesMessage("Your changes haveen been successfully updated.");
        //                /**
        //                 * set the type of the message.
        //                 * Valid types: error, fatal,info,warning
        //                 */
        //                fm.setSeverity(FacesMessage.SEVERITY_INFO);
        //                FacesContext context = FacesContext.getCurrentInstance();
        //                context.addMessage(null, fm);
             
             
//             FacesMessage fm=new FacesMessage(result);
//             fm.setSeverity(FacesMessage.SEVERITY_ERROR);
//             FacesContext context=FacesContext.getCurrentInstance();
//             if(result!=null && result.startsWith("Please"))
//             context.addMessage(null, fm);
             
             if(result!=null){
                 String sum[]=result.split(",");
                 if(sum[0].contains("."))
                 invoiceSum="$ "+sum[0];
                 else
                     invoiceSum="$ "+sum[0]+".00";
                 
                 if(sum[1].contains("."))
                 quantityHoldSum="$ "+sum[1];
                 else
                     quantityHoldSum="$ "+sum[1]+".00";
                 
                 if(sum[2].contains("."))
                 priceHoldSum="$ "+sum[2];
                 else
                     priceHoldSum="$ "+sum[2]+".00";
             }

    }
    
    public String updateAction(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateMassReleaseSelectRow");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              String result=(String)operation.execute();
        FacesMessage fm=null;
        if(result!=null && result.startsWith("Please"))
            fm = new FacesMessage(result);
        else
        
         fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
        return null;

    }
    public void selectAllCheckBoxVCL(ValueChangeEvent valueChangeEvent) {

    System.out.println("xdebug c1 : In selectAllChoiceBoxLN with value = "+
    valueChangeEvent.getNewValue());

    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("MassReleaseHoldVO1Iterator");

    ViewObject vo = dciter.getViewObject();
    int i = 0;
    Row row = null;
    vo.reset();
    while (vo.hasNext()) {
    if (i == 0)
    row = vo.first();
    else
    row = vo.next();
    //            System.out.println("Changing row 1: " +
    //              row.getAttribute("Name"));
    System.out.println("xdebug c2: Changing row 2: " +
    row.getAttribute("EmployeeSelect"));

    if(isSelected)
    row.setAttribute("EmployeeSelect", true);
    else
    row.setAttribute("EmployeeSelect", false);
    i++;
    }
    }
    private static Object evaluateEL(String el) {
    FacesContext facesContext = FacesContext.getCurrentInstance();
    ELContext elContext = facesContext.getELContext();
    ExpressionFactory expressionFactory =
    facesContext.getApplication().getExpressionFactory();
    ValueExpression exp =
    expressionFactory.createValueExpression(elContext, el,
              Object.class);
    return exp.getValue(elContext);
    }
    
    public void clearMassRelease(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("clearMassReleaseHold");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              String result=(String)operation.execute();
              
    }

}
