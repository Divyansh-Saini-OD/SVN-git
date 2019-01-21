package od.oracle.apps.xxcomn.common.fileUpload.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OAException;
import java.sql.CallableStatement;
import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class fileUploadAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public fileUploadAMImpl()
  {
  }


  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcomn.common.fileUpload.server", "fileUploadAMLocal");
  }


  
  public void getOutputURL(String requestId)
  {
      OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getDBTransaction();
      String s1 = oadbtransactionimpl.getAppsContext().getEnvStore().getEnv("TWO_TASK");
      System.out.println("s1="+s1);
      String s2 = oadbtransactionimpl.getAppsContext().getEnvStore().getEnv("GWYUID");
            System.out.println("s2="+s2);
      String s3 = "BEGIN :1 := fnd_webfile.get_url(fnd_webfile.request_out, :2, :3, :4, 1); end;";
            System.out.println("s3="+s3);
                  System.out.println("requestId="+requestId);
      CallableStatement callablestatement = getOADBTransaction().createCallableStatement(s3, 1);
      if(requestId != null)
      {
          try
          {
              Number number = new Number(requestId);
              callablestatement.registerOutParameter(1, 1);
              
              callablestatement.setInt(2, number.intValue());
              callablestatement.setString(3, s2);
              callablestatement.setString(4, s1);
              System.out.println("number="+number);
              System.out.println("Callable stmt="+callablestatement);
              callablestatement.execute();
              String s4 = callablestatement.getString(1);
            
              oadbtransactionimpl.putValue("OutputURL", s4);
              System.out.println("OutputURL in AM = "+s4);
          }
          catch(Exception exception1)
          {
              throw OAException.wrapperException(exception1);
          }
          finally
          {
              try
              {
                  callablestatement.close();
              }
              catch(Exception exception2)
              {
                  throw OAException.wrapperException(exception2);
              }
          }
          return;
      } else
      {
          return;
      }
  } // ends method getOutputURL()

  /**
   * 
   * Container's getter for xxConcProgDetailVO
   */
  public xxConcProgDetailVOImpl getxxConcProgDetailVO()
  {
    return (xxConcProgDetailVOImpl)findViewObject("xxConcProgDetailVO");
  }

  /**
   * 
   * Container's getter for FndFlexValuesVO
   */
  public OAViewObjectImpl getFndFlexValuesVO()
  {
    return (OAViewObjectImpl)findViewObject("FndFlexValuesVO");
  }

  /**
   * 
   * Container's getter for xxGetAppsNameVO1
   */
  public xxGetAppsNameVOImpl getxxGetAppsNameVO1()
  {
    return (xxGetAppsNameVOImpl)findViewObject("xxGetAppsNameVO1");
  }



}