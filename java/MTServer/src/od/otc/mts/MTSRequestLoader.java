package od.otc.mts;

import od.otc.mts.request.*;

import java.io.*;

import java.util.ArrayList;
import java.util.List;

import java.util.ListIterator;

import java.util.Vector;

import javax.xml.bind.*;
import javax.xml.XMLConstants;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.*;

import od.otc.mts.config.*;

import org.xml.sax.InputSource;

public class MTSRequestLoader {

    private String sReqSchema = MTServer.MTSConfigPath + File.separator + "MTSRequest.xsd";
    private MTSRequest oMTSRequest = null;

    public MTSRequestLoader(String sXML) {

        StringReader oSReader = null;

        try {

            oSReader = new StringReader(sXML);

            SchemaFactory oSFactory = 
                SchemaFactory.newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);
            Schema oSchema = oSFactory.newSchema(new File(sReqSchema));
            JAXBContext oJCtx = JAXBContext.newInstance("od.otc.mts.request");
            Unmarshaller oUM = oJCtx.createUnmarshaller();
            oUM.setSchema(oSchema); //validate the config xml
            oMTSRequest = (MTSRequest)oUM.unmarshal(new StreamSource(oSReader));
            //oMTSRequest = 
            //        (MTSRequest)oUM.unmarshal(new File("C:\\OTC-FEC\\MTServer\\config\\MTSRequest.xml"));

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }
    }

    public String getSessionID() {
        return oMTSRequest.getSessionID();
    }

    public String getCallType() {
        return oMTSRequest.getCallType();
    }

    public List getBeanCall() {
        return oMTSRequest.getBeanCall();
    }

    /*public int getMethodCallNumber() {
        return 0;
    }*/
    
    
    public ArrayList<EJBCallStruct> getEJBCallStructures() {

        ArrayList<EJBCallStruct> oEJBArr = new ArrayList<EJBCallStruct>();
        EJBCallStruct oCallStruct = null;
        
        try {

            List<BeanCall> oBeans = oMTSRequest.getBeanCall();
            ListIterator<BeanCall> oBItr = oBeans.listIterator();
            BeanCall oBean = null;
            boolean bAddStruct = true;
            Class[] oParamTypeClass = null;
            ArrayList<Object[]> oParamValueArr = new ArrayList<Object[]>();

            List<MethodCall> oMethods = null;
            ListIterator<MethodCall> oMItr = null;
            MethodCall oMethod = null;

            while (oBItr.hasNext()) { //loop thru the beancalls
                oBean = oBItr.next();
                oMethods = oBean.getMethodCall(); //get the methodcalls      
                
                if(bAddStruct) {
                    oCallStruct = new EJBCallStruct();
                    bAddStruct = false;
                }
                
                oCallStruct.setJNDIName(oBean.getJNDIName());

                oMItr = oMethods.listIterator(); //loop thru the method calls
                while (oMItr.hasNext()) {
                
                    if(bAddStruct) {
                        oCallStruct = new EJBCallStruct();
                        oCallStruct.setJNDIName(oBean.getJNDIName());
                        oParamTypeClass = new Class[0];
                        oParamValueArr = new ArrayList<Object[]>();
                        bAddStruct = false;
                    }

                    oMethod = oMItr.next();
                    oCallStruct.setMethodName(oMethod.getMethodName());

                    ParamTypes oPTypes = oMethod.getParamTypes();
                    oParamTypeClass = getParamTypes1(oPTypes.getParamType());
                    if(oParamTypeClass==null) {
                        oParamTypeClass = new Class[0];                      
                    }
                    oCallStruct.setParamType(oParamTypeClass);

                    ParamValues oPValues = oMethod.getParamValues();
                    oParamValueArr = getParamValues1(oPValues.getParamValue());
                    
                    if(oParamValueArr.size()==0) {
                    System.out.println("param array zero size");
                        oParamValueArr.add(new Object[0]);
                    }
                    
                    oCallStruct.setParamVal(oParamValueArr);

                    oEJBArr.add(oCallStruct);
                    bAddStruct = true;

                }
            }

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }
        
        System.out.println("arr size "+oEJBArr.size());
        return oEJBArr;

    }

    private Class[] getParamTypes1(List<ParamType> oPTypes) {

        ArrayList<Class> oArr = new ArrayList<Class>();
        String sJavaClass = "";
        Class[] oClassArr = null;

        try {

            ListIterator<ParamType> oPItr = oPTypes.listIterator();
            ParamType oPType = null;

            while (oPItr.hasNext()) {
                oPType = oPItr.next();
                sJavaClass = oPType.getJavaclass();
                if (sJavaClass.trim().length() > 0) {
                    System.out.println("classs " + sJavaClass);
                    oArr.add(Class.forName(sJavaClass));
                }
            }

            int iArrSize = oArr.size();
            if (iArrSize > 0) {
                oClassArr = new Class[iArrSize];
                for (int iCtr = 0; iCtr < iArrSize; iCtr++) {
                    oClassArr[iCtr] = oArr.get(iCtr);
                }
            }

        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

        return oClassArr;

    }


    private ArrayList<Object[]> getParamValues1(List<ParamValue> oPValues) {

        String sParamVal = "";
        ArrayList<Object[]> oArr = new ArrayList<Object[]>();

        try {

            ListIterator<ParamValue> oPVItr = oPValues.listIterator();
            ParamValue oPVal = null;

            List oList = null;
            ListIterator oItr = null;
            JAXBElement oJE = null;
            StringBuilder oStrBuild = new StringBuilder();

            //int k = 0;
            while (oPVItr.hasNext()) {
                //k++;
                //System.out.println("k val " + k);
                //get the Param name & value here
                oPVal = oPVItr.next();
                oList = oPVal.getParamnameAndValue();
                oItr = oList.listIterator();
                while (oItr.hasNext()) {
                    oJE = (JAXBElement)oItr.next();
                    //System.out.println("param name "+je.getName().toString());
                    //System.out.println("param val "+je.getValue());

                    if (oStrBuild.length() > 0 && 
                        oJE.getName().toString().equals("value")) {
                        oStrBuild.append(",");
                    }
                    if (oJE.getName().toString().equals("value")) {
                        oStrBuild.append(oJE.getValue());
                    }
                }
                //System.out.println("val " + sb.toString());
                if(oStrBuild.toString().trim().length()>0) {
                    oArr.add(new Object[] { oStrBuild.toString() });
                }else {
                    oArr.add(new Object[0]);
                }
                oStrBuild = new StringBuilder();
            }

            //System.out.println("val " + oStrBuild.toString());


        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

        return oArr;

    }
    
    public int getMaxParamValue() {
        
        int iMaxVal = -1;
        ArrayList<Integer> oArr = new ArrayList<Integer>();
        int iCount = 0;
        
        try {        
        
            List<BeanCall> oBeans = oMTSRequest.getBeanCall();    
            ListIterator<BeanCall> oLItr = oBeans.listIterator();
            BeanCall oBean = null;
            
            List<MethodCall> oMethods = null;
            ListIterator<MethodCall> oMLItr = null;
            MethodCall oMethod = null;

            ParamValues oPValues = null;

            //get the beancalls --> Methodcalls --> paramvalues --> paramvalue count            
            //loop thru the beancall
            while(oLItr.hasNext()) {
                oBean = oLItr.next();        
                oMethods = oBean.getMethodCall();
                
                oMLItr = oMethods.listIterator();
                //loop thru the method call
                while(oMLItr.hasNext()) {
                    oMethod = oMLItr.next();
                    oPValues = oMethod.getParamValues();

                    //get the Paramvalue count
                    iCount = oPValues.getParamValue().size();
                    
                    //compare and store the count. the first element in oArr
                    //will have the max count
                    if(oArr.size()>0) {
                        if(iCount > oArr.get(0)) {
                            oArr.remove(0);
                            oArr.add(iCount);
                        }
                    } else {
                        oArr.add(iCount);
                    }
                    
                }
                
            }
            
            if(oArr.size() > 0) {
                iMaxVal = oArr.get(0);
            }
        
        } catch (Exception oEx) {
            oEx.printStackTrace();
        }

System.out.println("iMaxVal "+iMaxVal);        
        return iMaxVal;
    }

    public static void main(String[] args) {

            
            Vector<String> oItems =new Vector<String>();
            oItems.add("11001");
            oItems.add("24003");
        
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
                oSB.append("<ParamValues>");
                for(String str: oItems) {
                    oSB.append("<ParamValue><paramname>itemid</paramname>");
                    oSB.append("<value>"+str+"</value></ParamValue>");
                }
                oSB.append("</ParamValues></MethodCall></BeanCall></MTSRequest>");

            MTSRequestLoader rl = new MTSRequestLoader(oSB.toString());
            ArrayList al = rl.getEJBCallStructures();
            
        } catch (Exception oEx) {
            oEx.printStackTrace();
        }


    }
    
}   //class
