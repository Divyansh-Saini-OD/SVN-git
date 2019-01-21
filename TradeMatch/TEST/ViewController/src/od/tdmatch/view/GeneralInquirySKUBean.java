package od.tdmatch.view;

import java.io.Serializable;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.binding.OperationBinding;

public class GeneralInquirySKUBean implements Serializable{
    
    public String sku;
 //   public boolean formVisible=Boolean.TRUE;
    public GeneralInquirySKUBean() {
        super();
    }

    @SuppressWarnings("oracle.jdeveloper.java.unchecked-conversion-or-cast")
    public void seachSKUAction(ActionEvent actionEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("seachWithSKU");
         //  String abc="ABC";
          // String name="toVA";
              operation.getParamsMap().put("sku", sku);
              String output=null;
              output= (String)operation.execute();
              if(output.equals("N")) {
                  FacesMessage fm = new FacesMessage("Please enter a valid SKU #.");
                          /**
                           * set the type of the message.
                           * Valid types: error, fatal,info,warning
                           */
                          fm.setSeverity(FacesMessage.SEVERITY_INFO);
                          FacesContext context = FacesContext.getCurrentInstance();
                          context.addMessage(null, fm);
              }
           //   setFormVisible(Boolean.TRUE);
    }

    public void setSku(String sku) {
        this.sku = sku;
    }

    public String getSku() {
        return sku;
    }

//    public void setFormVisible(boolean formVisible) {
//        this.formVisible = formVisible;
//    }
//
//    public boolean isFormVisible() {
//        return formVisible;
//    }
    public void clearListener(ActionEvent actionEvent) {
        // Add event code here...
        sku=null;
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("clearSKU");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put("sku", sku);
              operation.execute();
    }
}
