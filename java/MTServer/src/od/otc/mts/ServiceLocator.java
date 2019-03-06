package od.otc.mts;

import javax.ejb.*;
import javax.naming.*;
import java.util.Map;
import java.util.HashMap;
import java.util.Collections;
import java.util.Properties;


public class ServiceLocator {

       private Context ctx;
       private Map<String,EJBHome>cache;
       private static ServiceLocator instance=null;

       static {
              try {
                  instance=new ServiceLocator();
              }catch(Exception oEx) {
                oEx.printStackTrace();
              }
       }

       private ServiceLocator() throws Exception {
               try {
                      Properties env=new Properties();
                      //env.put(Context.INITIAL_CONTEXT_FACTORY,"com.sun.jndi.cosnaming.CNCtxFactory");
                      //env.put(Context.PROVIDER_URL,"iiop://10.145.6.159:1050");
                      
                      env.put(Context.INITIAL_CONTEXT_FACTORY,MTServer.oAppServer.getInitialContext());
                      env.put(Context.PROVIDER_URL,MTServer.oAppServer.getProviderUrl());
                      env.put( Context.SECURITY_PRINCIPAL, MTServer.oAppServer.getUserName());
                      env.put( Context.SECURITY_CREDENTIALS, MTServer.oAppServer.getPassword());
                      
                      ctx=new InitialContext(env);
                      cache = Collections.synchronizedMap(new HashMap<String,EJBHome>());
               } catch(Exception oEx) {
                     oEx.printStackTrace();
                     throw oEx;
               }
       }

       public static ServiceLocator getInstance() throws Exception {
              return instance;
       }

       public EJBHome getHome(String jndiName) throws Exception {
              EJBHome oHome=null;
              try {
                  if(cache.containsKey(jndiName)) {
                      oHome=cache.get(jndiName);
System.out.println("---------from the cache");                      
                  } else {
                       oHome =(EJBHome)ctx.lookup(jndiName);
                       if(oHome != null) {
                          cache.put(jndiName,oHome);
                       }
System.out.println("*********NOT from the cache");                                             
                  }
              }catch(Exception oEx) {
                    oEx.printStackTrace();
                    throw oEx;
              }
              return oHome;
       }


}      //class