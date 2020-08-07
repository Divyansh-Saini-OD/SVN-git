package od.tdmatch.view.managedBeans;

import java.io.Serializable;

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

public class PaymentAttributesBean implements Serializable{
    String invoicesum="$ 0.00";
    public PaymentAttributesBean() {
        super();
    }
    
    public String invoicesSearchAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("paymentSearchValidate");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
        String result=null;
             result=(String) operation.execute();
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
             if(result!=null)
             context.addMessage(null, fm);
        return null;
    }

    public void paymentSearch(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("paymentAttributeValidate");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
        String result=null;
             result=(String) operation.execute();
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
             else if(result !=null){
                 invoicesum="$ "+result+".00";
             }
        
    }
    public void selectAllCheckBoxVCL(ValueChangeEvent valueChangeEvent) {

    System.out.println("xdebug c1 : In selectAllChoiceBoxLN with value = "+
    valueChangeEvent.getNewValue());

    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("PaymentAttributeVO1Iterator");

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
    public String updateAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updatePaymentAttributes");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              String update=(String)operation.execute();
        FacesMessage fm=null;
              if(update!=null)
              fm=new FacesMessage(update);
              else
         fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
                invoicesum="$ 0.00";
        return null;
    }
    public void initPaymentSearch(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initPaymentTerms");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              operation.execute();
    }

    public void setInvoicesum(String invoicesum) {
        this.invoicesum = invoicesum;
    }

    public String getInvoicesum() {
        return invoicesum;
    }
    
    public void clearPayment(ActionEvent actionEvent){
        
    }
}
