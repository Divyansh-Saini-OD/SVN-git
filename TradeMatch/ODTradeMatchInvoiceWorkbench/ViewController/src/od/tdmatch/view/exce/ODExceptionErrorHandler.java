package od.tdmatch.view.exce;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;
import oracle.adf.model.binding.DCErrorHandlerImpl;

public class ODExceptionErrorHandler extends DCErrorHandlerImpl {
    public ODExceptionErrorHandler(boolean b) {
        super(b);
    }

    public ODExceptionErrorHandler() {
        super();
    }
    
    
    @Override    
      public void reportException(DCBindingContainer dCBindingContainer,Exception exception) {    
    //  super.reportException(dCBindingContainer, exception);    
    }    
      
    public String getDisplayMessage(BindingContext ctx, Exception ex) {    
        
    String message="";    
        
    if (ex instanceof java.sql.SQLDataException) {    
    String msg = ex.getMessage();    
    int i=msg.indexOf("ORA-0184");    
    
    System.err.println("ODExceptionErrorHandler>>>>>>");
    
    
        
    if(i>0) {    
      message= "";    
     }    
    System.out.println("ODExceptionErrorHandler");
  //   message= getDisplayMessage(ctx,ex);    
     }
    return message;    
    }    
}
