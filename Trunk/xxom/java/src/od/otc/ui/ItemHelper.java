package od.otc.ui;

import ejbtest.SPSessionEJB;
import ejbtest.SPSessionEJBHome;

import java.util.*;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.rmi.PortableRemoteObject;

import java.text.SimpleDateFormat;
import java.util.Calendar;


public class ItemHelper {
    
    private Vector<String> oItems = new Vector<String>();
    private String sExec = "";
    
    public ItemHelper(Vector<String> oArr, String sEx) {
        oItems = oArr;
        sExec = sEx;
    }
    
    public Vector getItemName()  {
        Vector oReturnVec = null;
        
        try {
        
            if(sExec.equals("S")) { //serial call
                oReturnVec = callItemNameEJB();
            }else {
                oReturnVec = callMTSForItem();
            }
             
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        
        return oReturnVec;
    }

    private Vector callItemNameEJB()  {
    
        Vector oReturnVec = new Vector();
        
        try {
        
            //final Context context = getInitialContext();
            ServiceLocator oLocator = ServiceLocator.getInstance();
            final SPSessionEJBHome sPSessionEJBHome = 
                (SPSessionEJBHome) PortableRemoteObject.narrow( oLocator.getHome( "SPSessionEJB" ), SPSessionEJBHome.class );
            SPSessionEJB sPSessionEJB;
            sPSessionEJB = sPSessionEJBHome.create(  );
            // Call any of the Remote methods below to access the EJB
            
             String str1 = "";
             for(String item: oItems) {
                 str1 = (String)sPSessionEJB.callStoredProc(item);
                 System.out.println(str1);
                 oReturnVec.add(str1);
             }
             
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        
        return oReturnVec;
    }

    private static Context getInitialContext() throws NamingException {
        Hashtable env = new Hashtable();
        //  Standalone OC4J connection details
        /*env.put( Context.INITIAL_CONTEXT_FACTORY, "oracle.j2ee.rmi.RMIInitialContextFactory" );
        env.put( Context.SECURITY_PRINCIPAL, "oc4jadmin" );
        env.put( Context.SECURITY_CREDENTIALS, "admin135" );
        env.put(Context.PROVIDER_URL, "ormi://localhost:23791/EJBTest");*/
        
        env.put( Context.INITIAL_CONTEXT_FACTORY, POCControllerServlet.sInitialContext );
        env.put( Context.SECURITY_PRINCIPAL, POCControllerServlet.sPrincipal );
        env.put( Context.SECURITY_CREDENTIALS, POCControllerServlet.sCredential );
        env.put(Context.PROVIDER_URL, POCControllerServlet.sProviderURL);
        
        return new InitialContext(env);
    }
    
    
    private Vector callMTSForItem() {
        
        Vector oReturnVector = new Vector();

        StringBuffer oSB = new StringBuffer("<?xml version=\"1.0\"?><MTSRequest xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"MTSRequest.xsd\">" +
        "    <SessionID>23232323</SessionID>" + 
        "    <CallType>EJBSessionBean</CallType>" + 
        "    <BeanCall>" + 
        "        <JNDIName>SPSessionEJB</JNDIName>" + 
        "        <MethodCall>" + 
        "            <MethodName>callStoredProc</MethodName>" + 
        "            <ParamTypes>" + 
        "                <ParamType>" + 
        "                    <paramname>itemid</paramname>" + 
        "                    <javaclass>java.lang.String</javaclass>" + 
        "                </ParamType>" + 
        "            </ParamTypes>");
        
        try {
        
            //form the xml string for SPSessionEJB
            /*oSB.append("<ParamValues>");
            for(String str: oItems) {
                oSB.append("<ParamValue><paramname>itemid</paramname>");
                oSB.append("<value>"+str+"</value></ParamValue>");
            }
            oSB.append("</ParamValues></MethodCall></BeanCall></MTSRequest>");

//System.out.println("xml "+oSB.toString());

            //write to the socket
            oReturnVector = (Vector)MTSSocketWriter.readWriteObject(POCControllerServlet.sMTServerIP,
                                                                    POCControllerServlet.iMTServerPort,
                                                                    oSB.toString());
        
        */

             ServiceLocator oLocator = ServiceLocator.getInstance();
             final SPSessionEJBHome sPSessionEJBHome = 
                 (SPSessionEJBHome) PortableRemoteObject.narrow( oLocator.getHome( "SPSessionEJB" ), SPSessionEJBHome.class );
             SPSessionEJB sPSessionEJB;
             sPSessionEJB = sPSessionEJBHome.create(  );
             // Call any of the Remote methods below to access the EJB
             
              oReturnVector = (Vector)sPSessionEJB.callStoredProcThruMTS(oItems,sExec);

        
        } catch (Exception ex) {
            ex.printStackTrace();
        }

        if(oReturnVector != null)   {
            for(int i=0;i<oReturnVector.size();i++) {
                System.out.println("val "+(String)oReturnVector.elementAt(i));
            }
        } else {
            System.out.println("return obj null ***********");
        }
        return oReturnVector;        
        
    }
    
}   //class
