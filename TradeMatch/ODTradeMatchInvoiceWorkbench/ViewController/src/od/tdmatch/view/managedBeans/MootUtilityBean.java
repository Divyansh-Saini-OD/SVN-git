package od.tdmatch.view.managedBeans;

import com.od.external.model.bean.FndUserBean;

import java.io.Serializable;

import java.util.Map;

import java.util.logging.Logger;

import oracle.adf.model.BindingContext;
import oracle.adf.model.binding.DCBindingContainer;

import oracle.adf.share.ADFContext;

import oracle.binding.OperationBinding;

import org.apache.myfaces.trinidad.event.PollEvent;


public class MootUtilityBean implements Serializable {
    private static final Logger logger = Logger.getLogger(MootUtilityBean.class.getName());
    
    private String taskFlowId = "/WEB-INF/moot-summary-btf.xml#moot-summary-btf";
    private String tabTitle = "Match Error Employee's Workable Summary";
    private String EmployeeId = null;
    private String CurrentDate = "Default Date";

    public MootUtilityBean() {
          }
    public void executeVAEmpVendorSummaryVO(){
        System.out.println("Executing the Method before navigating!");
    }
    public String getTabTitle(){
        return tabTitle;
    }
    
    public void setTabTitle(){
        tabTitle = "Title2";
    }


    public void setEmployeeId(String EmployeeId) {
        this.EmployeeId = EmployeeId;
    }

    public String getEmployeeId() {
        return EmployeeId;
    }
    
    public String getCurrentDate(){
        return "Today's date";
    }

    public void autosave(PollEvent pollEvent) {
        // Add event code here...
        DCBindingContainer bindings = (DCBindingContainer)BindingContext.getCurrent().getCurrentBindingsEntry();
        OperationBinding operation = bindings.getOperationBinding("autoSave");
         //  String abc="ABC";
          // String name="toVA";
            //  operation.getParamsMap().put(name, abc);
              operation.execute();
    }
}
