package od.oracle.apps.ar.hz.extension.webui;

import oracle.apps.ar.hz.extension.webui.HzExtEntryPageCO;

import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.webui.OAControllerImpl;
import oracle.apps.fnd.framework.webui.OAPageContext;
import oracle.apps.fnd.framework.webui.beans.OAWebBean;

import java.io.Serializable;

import oracle.apps.fnd.framework.OAApplicationModule;

import oracle.jbo.common.Diagnostic;

public class XXHzExEntryPageCO extends HzExtEntryPageCO {
    public XXHzExEntryPageCO() {
    }

    public void processRequest(OAPageContext pageContext, OAWebBean webBean) {
        super.processRequest(pageContext, webBean);
        pageContext.getPageLayoutBean().prepareForRendering(pageContext);
        pageContext.getPageLayoutBean().setStart(null);   
    }

    public void processFormRequest(OAPageContext pageContext, 
                                   OAWebBean webBean) {
      //  super.processFormRequest(pageContext, webBean);
        //      OAApplicationModule am = pageContext.getApplicationModule(webBean); 
        //      OAQueryBean queryBean = (OAQueryBean)webBean.findChildRecursive("QueryRN"); 
        //         
        //Capturing Go Button ID 


        //If its Not NULL which mean user has pressed "Go" Button 
        OAApplicationModule am = 
            (OAApplicationModule)pageContext.getRootApplicationModule();
try
{

        if (pageContext.getParameter("EntityGo") != null) {
            String entity = pageContext.getParameter("EntityChoice");
            System.out.println(entity);

            Serializable[] parameters = { entity };
            String objId = (String)am.invokeMethod("getObjectId", parameters);
            System.out.println(objId);

            String objGroupType = null;

            if (entity.equals("XX_CDH_CUST_ACCT_SITE"))
                objGroupType = "XX_CDH_CUST_ACCT_SITE";
            else if (entity.equals("XX_CDH_ACCT_SITE_USES"))
                objGroupType = "XX_CDH_ACCT_SITE_USES";
            else if (entity.equals("XX_CDH_CUST_ACCOUNT"))
                objGroupType = "XX_CDH_CUST_ACCOUNT";
            if (entity.equals("HZ_ORGANIZATION_PROFILES"))
              objGroupType = "HZ_ORG_PROFILES_GROUP";
            else if (entity.equals("HZ_PERSON_PROFILES"))
              objGroupType = "HZ_PERSON_PROFILES_GROUP";        
            else if (entity.equals("HZ_PARTY_SITES"))
              objGroupType = "HZ_PARTY_SITES_GROUP";        
            else if (entity.equals("HZ_LOCATIONS"))
              objGroupType = "HZ_LOCATIONS_GROUP";        
            else if (entity.equals("HZ_CREDIT_RATINGS"))
              objGroupType = "HZ_CREDIT_RATINGS_GROUP";  
            else if (entity.equals("HZ_FINANCIAL_NUMBERS"))
              objGroupType = "HZ_FIN_NUMBERS_GROUP";  
            else if (entity.equals("HZ_FINANCIAL_REPORTS"))
              objGroupType = "HZ_FIN_REPORTS_GROUP";  


            pageContext.putSessionValue("HzExtObjId", objId);
            pageContext.putSessionValue("HzExtObjGroupType", objGroupType);

            Diagnostic.println("Home page:" + 
                               pageContext.getHomePageMenuName());
            pageContext.forwardImmediately("HZ_EXT_SETUP_GROUP", 
                                           RESET_MENU_CONTEXT, 
                                           pageContext.getHomePageMenuName(), 
                                           null, true, ADD_BREAD_CRUMB_YES);


        }}
        catch (Exception e){
                                       super.processRequest(pageContext, webBean);
        
                                   }
        
                                   }


    }

