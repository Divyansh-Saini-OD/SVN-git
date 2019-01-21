package od.tdmatch.view.managedBeans;

import javax.faces.application.FacesMessage;
import javax.faces.component.UIComponent;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;

import oracle.adf.model.binding.DCBindingContainer;
import oracle.adf.model.BindingContext;
import oracle.binding.OperationBinding;

//import org.apache.myfaces.trinidadinternal.taglib.listener.ResetActionListener;

public class vendorMootBean {
    Boolean load=false;
    public vendorMootBean() {
        super();
    }
    public String vendMootSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("vendMootSearchAction");
    
            String result=null;
                 result=(String) operation.execute();
                 load=true;
    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    public void clearVendMootSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearVendMootSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
              
    }
    
    public String vendMootDshipSearchAction() {
            // Add event code here...
            DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
            OperationBinding operation = bindings.getOperationBinding("vendMootDshipSearchAction");
    
            String result=null;
                 result=(String) operation.execute();
                 load=true;
    
                 FacesMessage fm=new FacesMessage(result);
                 fm.setSeverity(FacesMessage.SEVERITY_ERROR);
                 FacesContext context=FacesContext.getCurrentInstance();
                 if(result!=null)
                 context.addMessage(null, fm);
            return null;
        }
    public void clearVendMootDShipSearch(ActionEvent actionEvent){
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        System.out.println("Clear button is clicked");
        OperationBinding operation = bindings.getOperationBinding("clearVendMootDShipSearch");
        
              operation.execute();
        System.out.println("Clear button logic is executed");
        /*UIComponent myForm = actionEvent.getComponent();
        oracle.adf.view.rich.util.ResetUtils.reset(myForm);*/
        /*ResetActionListener ral = new ResetActionListener();
        ral.processAction(actionEvent);*/
              
    }
    
}
