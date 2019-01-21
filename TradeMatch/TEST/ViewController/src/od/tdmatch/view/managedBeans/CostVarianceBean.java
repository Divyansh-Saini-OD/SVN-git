package od.tdmatch.view.managedBeans;

import javax.el.ELContext;
import javax.el.ExpressionFactory;
import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;

import javax.faces.event.ValueChangeEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.view.rich.component.rich.input.RichInputDate;

import oracle.adf.view.rich.context.AdfFacesContext;

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

public class CostVarianceBean {
    private RichInputDate answerDate;
    Boolean load=false;
    public CostVarianceBean() {
        super();
    }

    public String answerAction() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateCostVariance");
        String result=null;
             result=(String) operation.execute();
        FacesMessage fm=new FacesMessage(result);
        fm.setSeverity(FacesMessage.SEVERITY_ERROR);
        FacesContext context=FacesContext.getCurrentInstance();
        if(result!=null && result.startsWith("Please"))
        context.addMessage(null, fm);
        else{
            result="Your changes have been successfully updated.";
            fm=new FacesMessage(result);
            fm.setSeverity(FacesMessage.SEVERITY_INFO);
            context.addMessage(null, fm);
        }
        return null;
    }

    public String costVarianceValidate() {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("costVarinceValidate");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
        String result=null;
             result=(String) operation.execute();
             load=true;
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
             
             
        
        return null;
    }

    public void answerCodeValueChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        if(valueChangeEvent.getNewValue()!=null){
        DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
        DCIteratorBinding dciter =dcb.findIteratorBinding("CostVarianceVO1Iterator");

        ViewObject vo = dciter.getViewObject();
            
        int i = 0;
        Row row = dciter.getRowSetIterator().getCurrentRow();
        java.util.Date datetime=new java.util.Date();
        java.sql.Date currentDate=new java.sql.Date(datetime.getTime());
      //  row.setAttribute("AnswerDate", currentDate);
        AdfFacesContext.getCurrentInstance().addPartialTarget(getAnswerDate());
      //  vo.reset();
//        while (vo.hasNext()) {
//        if (i == 0)
//        row = vo.first();
//        else
//        row = vo.next();
//        //            System.out.println("Changing row 1: " +
//        //              row.getAttribute("Name"));
//        System.out.println("xdebug c2: Changing row 2: " +
//        row.getAttribute("EmployeeSelect"));
//
//        if(isSelected)
//        row.setAttribute("EmployeeSelect", true);
//        else
//        row.setAttribute("EmployeeSelect", false);
//        i++;
//        }
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

    public void setAnswerDate(RichInputDate answerDate) {
        this.answerDate = answerDate;
    }

    public RichInputDate getAnswerDate() {
        return answerDate;
    }
    public void initCostVariance(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initCostVariance");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              operation.execute();
              load=false;
    }

    public void setLoad(Boolean load) {
        this.load = load;
    }

    public Boolean getLoad() {
        return load;
    }
}
