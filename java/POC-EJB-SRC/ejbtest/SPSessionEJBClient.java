package ejbtest;

import java.util.Hashtable;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.rmi.PortableRemoteObject;


import java.text.SimpleDateFormat;
import java.util.Calendar;

public class SPSessionEJBClient {
    public static void main(String [] args) {
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy hh:mm:ssss a");
            System.out.println("Request recd at "+sdf.format(new java.util.Date()));
            
            final Context context = getInitialContext();
            final SPSessionEJBHome sPSessionEJBHome = 
                (SPSessionEJBHome) PortableRemoteObject.narrow( context.lookup( "SPSessionEJB" ), SPSessionEJBHome.class );
            SPSessionEJB sPSessionEJB;
            sPSessionEJB = sPSessionEJBHome.create(  );
            
            // Call any of the Remote methods below to access the EJB

             String str1 = "";
             str1 = (String)sPSessionEJB.callStoredProc( "22001"  );
             System.out.println(str1);
             
            str1 = sPSessionEJB.testMethod();
            System.out.println(str1);
            
            /*str1 = (String)sPSessionEJB.callStoredProc( "11001"  );
            System.out.println(str1);

            str1 = (String)sPSessionEJB.callStoredProc( "24003"  );
            System.out.println(str1);

            str1 = (String)sPSessionEJB.callStoredProc( "25011"  );
            System.out.println(str1);

            str1 = (String)sPSessionEJB.callStoredProc( "12016"  );
            System.out.println(str1);
             */
            System.out.println("Request serviced at "+sdf.format(new java.util.Date()));
             
             
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    private static Context getInitialContext() throws NamingException {
        Hashtable env = new Hashtable();
        //  Standalone OC4J connection details
        env.put( Context.INITIAL_CONTEXT_FACTORY, "oracle.j2ee.rmi.RMIInitialContextFactory" );
        env.put( Context.SECURITY_PRINCIPAL, "oc4jadmin" );
        env.put( Context.SECURITY_CREDENTIALS, "admin135" );
        env.put(Context.PROVIDER_URL, "ormi://localhost:23791/POCEJB");

         /*env.put( Context.INITIAL_CONTEXT_FACTORY, "oracle.j2ee.rmi.RMIInitialContextFactory" );
         env.put( Context.SECURITY_PRINCIPAL, "omadmin" );
         env.put( Context.SECURITY_CREDENTIALS, "omadmin123" );
         env.put(Context.PROVIDER_URL, "opmn:ormi://chilsoa02d.na.odcorp.net:6003:oc4j_om/POCEJB");*/
         return new InitialContext( env );

    }
}
