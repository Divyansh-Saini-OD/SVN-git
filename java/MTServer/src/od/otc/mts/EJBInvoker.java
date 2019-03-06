package od.otc.mts;

import java.util.ArrayList;
import java.util.Vector;

public class EJBInvoker implements Task {

    /*private String url = "ormi://localhost:23791/EJBTest";
    private String user = "oc4jadmin";
    private String password = "admin135";*/

    private String sCallMethod = "";
    private String sJNDIName = "";
    private Class[] oParamType = null;
    private Object[] oParamValue = null;
    private ArrayList oParamValArr = null;

    private Object oReturnObj = null;

    public EJBInvoker(String sJndiName, String sMethodName, Class[] oPType, 
                      Object[] oPValue) {
        sJNDIName = sJndiName;
        sCallMethod = sMethodName;
        oParamType = oPType;
        oParamValue = oPValue;
    }

    public EJBInvoker(String sJndiName, String sMethodName, Class[] oPType, 
                      ArrayList oPValue) {
        sJNDIName = sJndiName;
        sCallMethod = sMethodName;
        oParamType = oPType;
        oParamValArr = oPValue;
    }

    public void execute() {

        try {

            EJBProxy proxy = new EJBProxy();
            //proxy.setContextProperties("oracle.j2ee.rmi.RMIInitialContextFactory", 
            //                           url, user, password);

            Object oHomeObj = proxy.getObj(sJNDIName);
            if(oParamValue==null) {
                oParamValue = new Object[0];
            }

            if(oParamValArr == null) {
            
                oReturnObj = 
                    proxy.executeMethod(oHomeObj, sCallMethod, oParamType, oParamValue);
                    setReturnObject(oReturnObj);
                    
            } else {
                
                Vector<Object> oReturnObjects = new Vector<Object>();
                Object[] oArrObj = null;
                
                for(int i=0;i<oParamValArr.size();i++) {
                    oArrObj = (Object[])oParamValArr.get(i);
                    oReturnObjects.add(proxy.executeMethod(oHomeObj, sCallMethod, oParamType, oArrObj));
                }
                setReturnObject(oReturnObjects);
            }

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

    }

    public void setReturnObject(Object obj) {
        oReturnObj = obj;
    }


    public Object getReturnObject() {
        return oReturnObj;
    }

}   //class


 /*String var = "java.lang.String";
 Class c = Class.forName(var);

 ArrayList<Class> arr = new ArrayList<Class>();
 //arr.add(String.class);
 arr.add(c);

 Class[] class_array = new Class[arr.size()];
 for (int i = 0; i < arr.size(); i++) {
     class_array[i] = arr.get(i);
 }

 if (obj == null) {
     System.out.println("obj null");
 } else {
     System.out.println("obj not null");
     System.out.println("color " +
                        proxy.executeMethod(obj, "getSKUColor",
                                            class_array,
                                            new Object[] { new String("Red") }));

      Object obj1 = proxy.executeMethod(obj, "getSKUColor",
                          class_array,
                          new Object[] { new String("Red") });



 }*/
