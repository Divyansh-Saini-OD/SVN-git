package od.tdmatch.view.managedBeans;
import java.io.Serializable;


public class MootUtilityBean implements Serializable {
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
}
