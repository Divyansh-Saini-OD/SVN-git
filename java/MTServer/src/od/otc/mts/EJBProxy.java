package od.otc.mts;

import java.util.Properties;

import java.lang.reflect.Method;
import java.lang.reflect.InvocationTargetException;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import javax.ejb.EJBHome;
import javax.ejb.EJBException;

//import javax.rmi.PortableRemoteObject;

public class EJBProxy {
    private Properties oProp = null;

    public EJBProxy() {
    }

    public EJBProxy(String initContextFactory, String providerUrl) {
        setContextProperties(initContextFactory, providerUrl, null, null);
    }

    public void EjbProxy(Properties prop) {
        setContextProperties(prop);
    }

    public void setContextProperties(Properties prop) {
        oProp = prop;
    }

    public void setContextProperties(String initContextFactory, 
                                     String providerUrl, String user, 
                                     String password) {
        oProp = new Properties();
        oProp.put(Context.INITIAL_CONTEXT_FACTORY, initContextFactory);
        oProp.put(Context.PROVIDER_URL, providerUrl);
        if (user != null) {
            oProp.put(Context.SECURITY_PRINCIPAL, user);
            if (password == null)
                password = "";
            oProp.put(Context.SECURITY_CREDENTIALS, password);
        }
    }

    public void setContextUserParam(String user, String password) {
        if (oProp == null) oProp = new Properties();
        
        oProp.put(Context.SECURITY_PRINCIPAL, user);
        oProp.put(Context.SECURITY_CREDENTIALS, password);
    }

    public EJBHome getHome(String beanJndiLookupName) throws EJBException {
        
        EJBHome obHome = null;
        
        try {
            InitialContext ctx = null;

            if (oProp != null) {
                ctx = new InitialContext(oProp);
            }else {
                ctx = new InitialContext();
            }
            System.out.println("config "+MTServer.oAppServer.getInitialContext());            
            try {
                ServiceLocator oLocator = ServiceLocator.getInstance();
                obHome = oLocator.getHome(beanJndiLookupName);
            } catch (Exception oEx) {
                throw new EJBException(oEx);
            }

            //Object home = ctx.lookup(beanJndiLookupName);
            //obHome = (EJBHome)PortableRemoteObject.narrow(home, EJBHome.class);
            return obHome;
            
        } catch (NamingException ne) {
            throw new EJBException(ne);
        }
    }

    public Object getObj(String beanJndiLookupName) throws EJBException {
        try {
            EJBHome obHome = getHome(beanJndiLookupName);
            //get the method of create
            Method m = 
                obHome.getClass().getDeclaredMethod("create", new Class[0]);
            //invoke the create method
            Object obj = m.invoke(obHome, new Object[0]);

            return obj;
        } catch (NoSuchMethodException ne) {
            throw new EJBException(ne);
        } catch (InvocationTargetException ie) {
            throw new EJBException(ie);
        } catch (IllegalAccessException iae) {
            throw new EJBException(iae);
        }
    }

    public Object executeMethod(Object obj, String methodName, 
                                Class[] paramtype, 
                                Object[] paramval) throws EJBException {

        //passing no param value
        //Object[] args = new Object[] { new String("Green") };

        //checking param types
        //Class[] parameterTypes = new Class[] { String.class };
        //more than one param then
        //Class[] intArgsClass = new Class[] { int.class, int.class };

        Method oMethod = null;
        Object oRetObject = null;

        try {

            if (paramtype == null || paramval == null) {
                //get the method to invoke
                oMethod = obj.getClass().getDeclaredMethod(methodName, new Class[0]); 
                oRetObject = oMethod.invoke(obj, new Object[0]); //invoke the method
            } else {
                oMethod = obj.getClass().getDeclaredMethod(methodName, paramtype);
                oRetObject = oMethod.invoke(obj, paramval);
            }

            return oRetObject;

        } catch (NoSuchMethodException ne) {
            throw new EJBException(ne);
        } catch (InvocationTargetException ie) {
            throw new EJBException(ie);
        } catch (IllegalAccessException iae) {
            throw new EJBException(iae);
        }
        
    }   //executeMethod

}   //class
