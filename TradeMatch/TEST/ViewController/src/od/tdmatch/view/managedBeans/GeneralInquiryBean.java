package od.tdmatch.view.managedBeans;

import javax.faces.event.ActionEvent;
import java.io.Serializable;

import java.util.HashMap;

import javax.el.ELContext;

import javax.el.ExpressionFactory;

import javax.el.MethodExpression;

import javax.el.ValueExpression;

import javax.faces.application.FacesMessage;

import javax.faces.context.FacesContext;

import javax.faces.event.ValueChangeEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.model.binding.DCIteratorBinding;

import oracle.adf.view.rich.component.rich.input.RichSelectOneChoice;
import oracle.adf.view.rich.event.QueryEvent;

import oracle.binding.OperationBinding;

import oracle.jbo.Row;
import oracle.jbo.ViewObject;

public class GeneralInquiryBean implements Serializable{
    
    Boolean massUpdateDisable=Boolean.FALSE;
    Boolean updateDisable=Boolean.FALSE;
    Boolean selectAll=Boolean.TRUE;
    Boolean load=false;
    private RichSelectOneChoice fromva;
    private RichSelectOneChoice tova;

    public GeneralInquiryBean() {
        super();
    }

    @SuppressWarnings("unchecked")
    public void UpdateVAAction(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("updateVA");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              operation.execute();
        FacesMessage fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
              
    }

    public void massUpdateVAAction(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("submitMassUpdate");
        HashMap map=new HashMap();
        map.put("fromva",getFromva().getValue());
        map.put("tova", getTova().getValue());
        operation.getParamsMap().put("param", map);
        operation.execute();
        FacesMessage fm = new FacesMessage("Your changes have been successfully updated.");
                /**
                 * set the type of the message.
                 * Valid types: error, fatal,info,warning
                 */
                fm.setSeverity(FacesMessage.SEVERITY_INFO);
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(null, fm);
    }
    
    public void createVendorUpdate(){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("initGeneralInquiry");
        operation.execute();
    }
    
    public void employeeValueChange(ValueChangeEvent valueChangeEvent){
        
//        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
//        DCIteratorBinding iter = bindings.findIteratorBinding("GeneralInquiryQueryVO1Iterator");
//        iter.getCurrentRow().setAttribute("EmployeeSelect", true);
//        massUpdateDisable=Boolean.TRUE;
         
    }

    public void setMassUpdateDisable(Boolean massUpdateDisable) {
        this.massUpdateDisable = massUpdateDisable;
    }

    public Boolean getMassUpdateDisable() {
        return massUpdateDisable;
    }

    public void employeeVLC(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        DCBindingContainer binding=(DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        DCIteratorBinding generalIter=binding.findIteratorBinding("GeneralInquiryQueryVO1Iterator");
        generalIter.getCurrentRow().setAttribute("EmployeeSelect", true);
        generalIter.getCurrentRow().getAttribute("EmployeeName");
        massUpdateDisable=Boolean.TRUE;
        updateDisable=Boolean.FALSE;
    }

    public void setUpdateDisable(Boolean updateDisable) {
        this.updateDisable = updateDisable;
    }

    public Boolean getUpdateDisable() {
        return updateDisable;
    }
    public void selectAllCheckBoxVCL(ValueChangeEvent valueChangeEvent) {
        if(valueChangeEvent.getNewValue()!=null){
    System.out.println("xdebug c1 : In selectAllChoiceBoxLN with value = "+
    valueChangeEvent.getNewValue());

    boolean isSelected = ((Boolean)valueChangeEvent.getNewValue()).booleanValue();
    DCBindingContainer dcb = (DCBindingContainer) evaluateEL("#{bindings}");
    DCIteratorBinding dciter =dcb.findIteratorBinding("GeneralInquiryQueryVO1Iterator");

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
    if(vo.getEstimatedRowCount()==1 ){
      if(isSelected)  
    vo.first().setAttribute("EmployeeSelect", true);
      else
      vo.first().setAttribute("EmployeeSelect", false);
    
    }
    
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

    public void fromVAChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        updateDisable=Boolean.TRUE;
//        if(valueChangeEvent.getNewValue()!=null){
//        
//        DCBindingContainer binding=(DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
//        DCIteratorBinding generalIter=binding.findIteratorBinding("GeneralInquiryQueryVO1Iterator");
//        ViewObject vo = generalIter.getViewObject();
//        boolean isSelected=Boolean.FALSE;
//        String employeeNo=null;
//        int i = 0;
//        Row row = null;
//        vo.reset();
//        while (vo.hasNext()) {
//        if (i == 0)
//        row = vo.first();
//        else
//        row = vo.next();
//        //            System.out.println("Changing row 1: " +
//        //              row.getAttribute("Name"));
//        System.out.println("xdebug c2: Changing row 2: " +
//        row.getAttribute("EmployeeSelect"));
//        employeeNo=(String)row.getAttribute("EmployeeName");
//        if(valueChangeEvent.getNewValue().toString().equals(employeeNo))
//        row.setAttribute("EmployeeSelect", true);
//        else
//        row.setAttribute("EmployeeSelect", false);
//        i++;
//        }
//        }
        
    }

    public void toVAChange(ValueChangeEvent valueChangeEvent) {
        // Add event code here...
        updateDisable=Boolean.TRUE;
    }
    
    public void customQueryListener(QueryEvent queryEvent) {
        massUpdateDisable=Boolean.FALSE;
        updateDisable=Boolean.FALSE;
        selectAll=Boolean.TRUE;
        invokeEL("#{bindings.GeneralInquiryQueryVOCriteriaQuery.processQuery}", new Class[] { QueryEvent.class },
                             new Object[] { queryEvent });
//        DCBindingContainer binding=(DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
//        DCIteratorBinding generalIter=binding.findIteratorBinding("GeneralInquiryQueryVO1Iterator");
//        generalIter.getCurrentRow().setAttribute("EmployeeSelect", true);
//        ViewObject vo = generalIter.getViewObject();
//        boolean isSelected=Boolean.FALSE;
//        String employeeNo=null;
//        int i = 0;
//        Row row = null;
 //       vo.reset();
//        while (vo.hasNext()) {
//        if (i == 0)
//        row = vo.first();
//        else
//        row = vo.next();
//        //            System.out.println("Changing row 1: " +
//        //              row.getAttribute("Name"));
//        System.out.println("xdebug c2: Changing row 2: " +
//        row.getAttribute("EmployeeSelect"));
//        employeeNo=(String)row.getAttribute("EmployeeName");
//        
//        row.setAttribute("EmployeeSelect", true);
//        
//        
//        i++;
//        }
        
    }
    public void searchAction(ActionEvent actionEvent){
        massUpdateDisable=Boolean.FALSE;
        updateDisable=Boolean.FALSE;
        selectAll=Boolean.TRUE;
    DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
    OperationBinding operation = bindings.getOperationBinding("generalInquirySearchValidate");
     //  String abc="ABC";
      // String name="toVA";
        //  operation.getParamsMap().put(name, abc);
    String result=null;
         result=(String) operation.execute();
         load=true;
    }
    public static Object invokeEL(String el, Class[] paramTypes, Object[] params) {
            FacesContext facesContext = FacesContext.getCurrentInstance();
            ELContext elContext = facesContext.getELContext();
            ExpressionFactory expressionFactory = facesContext.getApplication().getExpressionFactory();
            MethodExpression exp = expressionFactory.createMethodExpression(elContext, el, Object.class, paramTypes);

            return exp.invoke(elContext, params);
        }

    public void setSelectAll(Boolean selectAll) {
        this.selectAll = selectAll;
    }

    public Boolean getSelectAll() {
        return selectAll;
    }
    public String DeptContactSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("DeptContactSearchAction");
    
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
    public void clearDeptContactSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearDeptContactSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
              
    }

    public void setLoad(Boolean load) {
        this.load = load;
    }

    public Boolean getLoad() {
        return load;
    }

    public void setFromva(RichSelectOneChoice fromva) {
        this.fromva = fromva;
    }

    public RichSelectOneChoice getFromva() {
        return fromva;
    }

    public void setTova(RichSelectOneChoice tova) {
        this.tova = tova;
    }

    public RichSelectOneChoice getTova() {
        return tova;
    }
}
