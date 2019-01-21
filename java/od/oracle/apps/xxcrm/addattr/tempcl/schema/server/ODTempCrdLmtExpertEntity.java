package od.oracle.apps.xxcrm.addattr.tempcl.schema.server;
import oracle.jbo.domain.Date;
import oracle.apps.fnd.common.AppsLog;
import oracle.apps.fnd.framework.server.OAEntityExpert;

import oracle.jbo.domain.Number;

public class ODTempCrdLmtExpertEntity extends OAEntityExpert {
    public ODTempCrdLmtExpertEntity() {
    }
    //Validation for insert
    public boolean TmpClExists(Number CustAcctID,Number AcctProfileId,Number AcctProfileAmtId
               ,Number AttrGroupId,Date StartDate,Date EndDate)
             {
                 AppsLog myAppsLog = new AppsLog();
                 if (myAppsLog.isEnabled(1)) {
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: TmpClExists Begin", 1);    
                 }
                 boolean climit_exists = false;
                 ODTempcrdLmtVVOImpl crdlmtvo = (ODTempcrdLmtVVOImpl)findValidationViewObject("ODTempcrdLmtVVO");
                 if (myAppsLog.isEnabled(1)) {
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: Before Init Query", 1);
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: CustAcctID :"+CustAcctID, 1);
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: AcctProfileId :"+AcctProfileId, 1);
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: AcctProfileAmtId: "+AcctProfileAmtId, 1);
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: AttrGroupId :"+AttrGroupId, 1);
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: StartDate :"+StartDate, 1); 
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: EndDate :"+EndDate, 1);  
                 }
                crdlmtvo.initQuery(CustAcctID,AcctProfileId,AcctProfileAmtId,AttrGroupId,StartDate,EndDate);
                
                 if (myAppsLog.isEnabled(1)) {
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: After Init Query", 1);
                   }
                 // Verifying if records exist for given values.
                    if (crdlmtvo.hasNext())
                       {
                           climit_exists = true;
                        }
                 if (myAppsLog.isEnabled(1)) {
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: Credit limit Exists :"+climit_exists, 1);
                 myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: TmpClExists End", 1);    
                 }
                //System.out.println("climit_exists:"+climit_exists);
               return climit_exists;
             } //TmpClExists
             
             // Validation for Update
              public boolean TmpClExists(Number CustAcctID,Number AcctProfileId,Number AcctProfileAmtId
                         ,Number AttrGroupId,Date StartDate,Date EndDate,Number Extid)
                       {
                           AppsLog myAppsLog = new AppsLog();
                           if (myAppsLog.isEnabled(1)) {
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: TmpClExists Begin", 1);    
                           }
                           boolean climit_exists = false;
                           ODTempcrdLmtupdVVOImpl crdlmtvo = (ODTempcrdLmtupdVVOImpl)findValidationViewObject("ODTempcrdLmtupdVVO");
                           if (myAppsLog.isEnabled(1)) {
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: Before Init Query", 1);
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: CustAcctID :"+CustAcctID, 1);
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: AcctProfileId :"+AcctProfileId, 1);
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: AcctProfileAmtId: "+AcctProfileAmtId, 1);
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: AttrGroupId :"+AttrGroupId, 1);
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: StartDate :"+StartDate, 1); 
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: EndDate :"+EndDate, 1);  
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: Extid :"+Extid, 1);
                           }
                          crdlmtvo.initQuery(CustAcctID,AcctProfileId,AcctProfileAmtId,AttrGroupId,StartDate,EndDate,Extid);
                          
                           if (myAppsLog.isEnabled(1)) {
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: After Init Query", 1);
                             }
                           // Verifying if records exist for given values.
                              if (crdlmtvo.hasNext())
                                 {
                                     climit_exists = true;   
                                  }
                           if (myAppsLog.isEnabled(1)) {
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: Credit limit Exists :"+climit_exists, 1);
                           myAppsLog.write("ODTempCrdLmtExpertEntity", "XXOD: TmpClExists End", 1);    
                           }
                          //System.out.println("climit_exists:"+climit_exists);
                         return climit_exists;
                       } //TmpClExists
}
