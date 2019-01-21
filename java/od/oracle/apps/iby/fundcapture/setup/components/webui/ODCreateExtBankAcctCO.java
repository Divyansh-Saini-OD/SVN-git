package od.oracle.apps.iby.fundcapture.setup.components.webui;

import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;
import oracle.apps.iby.fundcapture.setup.components.webui.CreateExtBankAcctCO;
import oracle.apps.fnd.framework.webui.beans.message.OAMessageLovInputBean;
import oracle.apps.fnd.framework.webui.beans.form.OAFormValueBean;

public class ODCreateExtBankAcctCO extends CreateExtBankAcctCO {
    public ODCreateExtBankAcctCO() {
    }
    
    public void processRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean)
    {
        super.processRequest(paramOAPageContext, paramOAWebBean);
        paramOAPageContext.writeDiagnostics(this, "Custom Controller BEGIN", OAFwkConstants.STATEMENT);
        OAMessageLovInputBean countryLovBean = (OAMessageLovInputBean)paramOAWebBean.findChildRecursive("Country");
        OAFormValueBean countryCodeFVBean = (OAFormValueBean)paramOAWebBean.findChildRecursive("CountryCode");
        OAFormValueBean bankCountryCodeFVBean = (OAFormValueBean)paramOAWebBean.findChildRecursive("BankCountryCode");
        
        String operatingUnit = paramOAPageContext.getProfile("ORG_ID");
        String country = null;
        String countryCode = null;
        
        if("404".equals(operatingUnit)) {
            paramOAPageContext.writeDiagnostics(this, "Setting the Country value to United States ", OAFwkConstants.STATEMENT);
            country = "United States";
            countryCode = "US";
        }
        else if("403".equals(operatingUnit)) {
            paramOAPageContext.writeDiagnostics(this, "Setting the Country value to Canada ", OAFwkConstants.STATEMENT);
            country = "Canada";
            countryCode = "CA";
        }
        paramOAPageContext.writeDiagnostics(this, "MO: Operating Unit " + operatingUnit, OAFwkConstants.STATEMENT);
        if(countryLovBean!=null) {
            countryLovBean.setValue(paramOAPageContext, country);
        }
        if(countryCodeFVBean!=null){
            countryCodeFVBean.setValue(paramOAPageContext, countryCode);
        }
        if(bankCountryCodeFVBean!=null){
            bankCountryCodeFVBean.setValue(paramOAPageContext, countryCode);
        }
        paramOAPageContext.writeDiagnostics(this, "Custom Controller END", OAFwkConstants.STATEMENT);
    }
    
    public void processFormRequest(OAPageContext paramOAPageContext, OAWebBean paramOAWebBean)
    {
      super.processFormRequest(paramOAPageContext, paramOAWebBean);
    } 
}
