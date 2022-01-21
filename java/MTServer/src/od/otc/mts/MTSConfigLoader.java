package od.otc.mts;

import com.sun.org.apache.xerces.internal.dom.ElementNSImpl;

import java.io.*;
import javax.xml.bind.*;
import javax.xml.XMLConstants;
import javax.xml.validation.*;

import od.otc.mts.config.*;
import od.otc.mts.config.Parent;

public class MTSConfigLoader {

    private od.otc.mts.config.MTServer oMTServer = null;
    
    public MTSConfigLoader(String sConfigPath) {
    
        try {

            //File oConfigFile = new File(sConfigPath);
            SchemaFactory oSFactory = 
                SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
            Schema oSchema = oSFactory.newSchema(new File(sConfigPath+File.separator+"MTServer.xsd"));
            //Schema oSchema = oSFactory.newSchema(new File("C:\\OTC-FEC\\MTServer\\config\\MTServer.xsd"));
            JAXBContext oJCtx = JAXBContext.newInstance("od.otc.mts.config");
            Unmarshaller oUM = oJCtx.createUnmarshaller();
            oUM.setSchema(oSchema); //validate the config xml
            oMTServer = (od.otc.mts.config.MTServer)oUM.unmarshal(new File(sConfigPath+File.separator+"MTServer.xml"));

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }
    }

    public int getPort() {
        //validate the port value and return
        return Integer.parseInt(oMTServer.getListenToPort());
    }

    public Parent getParentThread() {
        //validate the min & max value and return
        return oMTServer.getThread().getParent();
    }

    public Worker getWorkerThread() {
        //validate the min & max value and return
        return oMTServer.getThread().getWorker();
    }

    public AppServerConfig getAppServerConfig() {
        //validate for non empty value and return
        return oMTServer.getAppServerConfig();
    }

    public int getMinParent() {
    
        JAXBElement je=null;
        ElementNSImpl oElement = null;
        int iMin = -1;
            
        try {
            Parent oParent = oMTServer.getThread().getParent();    
            oElement = (com.sun.org.apache.xerces.internal.dom.ElementNSImpl)oParent.getMin();
            System.out.println("val "+oElement.getFirstChild().getNodeValue());
            iMin = Integer.parseInt(oElement.getFirstChild().getNodeValue());
                        
        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

        return iMin; //Integer.parseInt(e.toString());        
        
    }

         public int getMaxWorker() {
         
             JAXBElement je=null;
             ElementNSImpl oElement = null;
             int iMin = -1;
                 
             try {
                 Worker oWorker = oMTServer.getThread().getWorker();
                 oElement = (com.sun.org.apache.xerces.internal.dom.ElementNSImpl)oWorker.getMax();
                 System.out.println("val "+oElement.getFirstChild().getNodeValue());
                 iMin = Integer.parseInt(oElement.getFirstChild().getNodeValue());
                             
             } catch (Exception oEx) {
                 oEx.printStackTrace();
             }

             return iMin; //Integer.parseInt(e.toString());        
             
         }

    public static void main(String[] args) {

        try {

            MTSConfigLoader cl = new MTSConfigLoader("C:\\OTC-FEC\\MTServer\\config");
            cl.getMinParent();
            
            //to create a xml doc from jaxb objects
            /*Marshaller ms = jc.createMarshaller();
            ObjectFactory factory = new ObjectFactory();
            MTSRequest mts = factory.createMTSRequest();
            mts.setJNDIName("JNDITest");
            // and set values for other xml elements
            ms.marshal(mts,new FileOutputStream("output.xml"));*/

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

    }

}   //class
