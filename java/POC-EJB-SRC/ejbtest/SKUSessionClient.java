package ejbtest;

import java.util.Hashtable;

import javax.naming.Context;
import javax.naming.InitialContext;

import javax.naming.NamingException;

import javax.rmi.PortableRemoteObject;

public class SKUSessionClient {
    public static void main(String [] args) {
        try {
            final Context context = getInitialContext();
            final SKUSessionHome sKUSessionHome = 
                (SKUSessionHome) PortableRemoteObject.narrow( context.lookup( "SKUSession" ), SKUSessionHome.class );
            SKUSession sKUSession;
            sKUSession = sKUSessionHome.create();
            // Call any of the Remote methods below to access the EJB
            System.out.println( sKUSession.getSKUColor("Red" ) );
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
        env.put(Context.PROVIDER_URL, "ormi://localhost:23791/EJBTest");
        return new InitialContext( env );
    }
}
