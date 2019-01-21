// +======================================================================================+
// | Office Depot - Project Simplify                                                      |
// +======================================================================================+
// |  Class:         XdoiRecRequestCP.java                                                |
// |  Description:   This class is extended from the standard Oracle Java Concurrent      |
// |                 Program class which allows it to be called from Oracle Applications  |
// |                 Concurrent Programs.  It is responsible for taken a given XDO        |
// |                 Request Group ID and Request ID to submit the XML Publisher APIs.    |
// |                                                                                      |
// |  Change Record:                                                                      |
// |  ==========================                                                          |
// |Version   Date          Author             Remarks                                    |
// |=======   ===========   ================   ========================================== |
// |1.0       06-APR-2017   Sreedhar Mohan     Copied from XdoRequestCP                   |
// |                                                                                      |
// +======================================================================================+
 
package od.oracle.apps.xxfin.xdo.concprogram; 

import java.io.*;
import java.sql.*;
import oracle.apps.fnd.common.*;
import od.oracle.apps.xxfin.*;
import od.oracle.apps.xxfin.xdo.xdorequest.*;
import oracle.apps.fnd.cp.request.*;
//import oracle.apps.fnd.util.ParameterList;
import oracle.apps.fnd.util.NameValueType;
import oracle.apps.fnd.util.*;

public class XdoiRecRequestCP implements JavaConcurrentProgram {
  
  // ==============================================================================================
  // class constructor
  // ==============================================================================================
  public XdoiRecRequestCP() {
  }
  
  // ==============================================================================================
  // Oracle Applications Java Concurrent Program run method
  // ==============================================================================================
  public void runProgram(CpContext cpcontext)
  {
    System.out.println("public void runProgram(CpContext cpcontext)");
    
    try {
      // ==============================================================================================
      // must set AutoCommit to false when working with BLOBs
      // ==============================================================================================
      cpcontext.getJDBCConnection().setAutoCommit(false);
      
      NameValueType parameter;
      int xdoRequestGroupId = 0;
      int xdoRequestId = 0;
      
      // ==============================================================================================
      // get parameter list from concurrent program
      // ==============================================================================================
      parameter = cpcontext.getParameterList().nextParameter();
        
      // ==============================================================================================
      // get next CP parameter (parameter1 = xdoRequestGroupId)
      // ==============================================================================================
      if (parameter.getName().equals("xdoRequestGroupId")) {
        if (parameter.getValue() != null && parameter.getValue() != "") {
          xdoRequestGroupId = Integer.parseInt(parameter.getValue());
        }
        else {
          xdoRequestGroupId = 0;  //use default xdo request group id
        }
      }
      else {
        throw new Exception("Parameter xdoRequestGroupId should be Parameter 1.");
      }
      
      parameter = cpcontext.getParameterList().nextParameter();
        
      // ==============================================================================================
      // get next CP parameter (parameter2 = xdoRequestId)
      // ==============================================================================================
      if (parameter.getName().equals("xdoRequestId")) {
        if (parameter.getValue() != null && parameter.getValue() != "") {
          xdoRequestId = Integer.parseInt(parameter.getValue());
        }
        else {
          xdoRequestId = -1;  //get all xdo requests in this group
        }
      }
      else {
        throw new Exception("Parameter xdoRequestId should be Parameter 2.");
      }
      
      System.out.println("  XDO Request Group ID  : " + xdoRequestGroupId );
      System.out.println("  XDO Request ID        : " + xdoRequestId );
      System.out.println("  " );
      
      // ==============================================================================================
      // process the XDO Request
      // ==============================================================================================
      XdoRequestManager.processRequests
        ((AppsContext)cpcontext,xdoRequestGroupId,xdoRequestId);     
        
      // ==============================================================================================
      // commit any work
      // ==============================================================================================
      cpcontext.getJDBCConnection().commit();                
      //oac.getJDBCConnection().setAutoCommit(true); 
      
      System.out.println("  Update Completion status to SUCCESS..." );
      System.out.println("  " );
      
      // ==============================================================================================
      // set successful completion
      // ==============================================================================================
      cpcontext.getReqCompletion().setCompletion(0, "SUCCESS");        
    }
    catch (Exception e) {
      // ==============================================================================================
      // set completed with errors
      // ==============================================================================================
      if(cpcontext.getReqCompletion() != null) {
        System.out.println("ERRORS");
        e.printStackTrace();
        cpcontext.getReqCompletion().setCompletion(2, "ERROR");
      }
    }
  }

}
