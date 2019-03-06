package ejbtest;

import java.sql.CallableStatement;

import javax.ejb.EJBException;
import javax.ejb.SessionBean;
import javax.ejb.SessionContext;

import javax.naming.Context;
import javax.naming.InitialContext;

import javax.sql.DataSource;

import oracle.jdbc.driver.*;
import oracle.jdbc.pool.OracleDataSource;

import java.sql.Connection;

import java.util.Vector;

public class SPSessionEJBBean implements SessionBean {
    private SessionContext oContext;

    public void ejbCreate() {
    }

    public void setSessionContext(SessionContext context) throws EJBException {
        oContext = context;
    }

    public void ejbRemove() throws EJBException {
    }

    public void ejbActivate() throws EJBException {
    }

    public void ejbPassivate() throws EJBException {
    }

    public Object callStoredProc(String sParam) {

        DataSource oDSConn = null;
        Connection oCon = null;
        CallableStatement oOrclStmt = null;
        String sReturnObj = null;

        try {

            Context ctx = new InitialContext();
            String val = (String)ctx.lookup("java:comp/env/ejb/theParam");
            System.out.println("Param val "+val);           

            //ctx.bind("jdbc/o2c",oDS);

            oDSConn = (DataSource)ctx.lookup("jdbc/o2c");
            oCon = oDSConn.getConnection();

            oOrclStmt = oCon.prepareCall("{call XX_OM_GETITEMNAME(?,?,?,?)}");

            oOrclStmt.setString(1, sParam);
            oOrclStmt.registerOutParameter(2, OracleTypes.VARCHAR);
            oOrclStmt.registerOutParameter(3, OracleTypes.VARCHAR);
            oOrclStmt.registerOutParameter(4, OracleTypes.VARCHAR);

            oOrclStmt.execute();
            System.out.println("param 1" + oOrclStmt.getString(2));
            //System.out.println("param 1" + oOrclStmt.getString(3));
            //System.out.println("param 1" + oOrclStmt.getString(4));

            sReturnObj = oOrclStmt.getString(2);
            
            //sReturnObj = 
            //        "Item " + oOrclStmt.getString(2) + " Status " + oOrclStmt.getString(3);

        } catch (Exception oEx) {
            oEx.printStackTrace();
        } finally {
            try {
                oCon.close();
            } catch (Exception oEx1) {
            }
        }

        return sReturnObj;
    }

    public String testMethod() {
        return new String("Return from TestMethod");
    }

    public Object callStoredProcThruMTS(Vector<String> oItems, String sExec) {

        Object oReturnObj = null;

        try {

            StringBuffer oSB = 
                new StringBuffer("<?xml version=\"1.0\"?><MTSRequest xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"MTSRequest.xsd\">" + 
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


            //form the xml string for SPSessionEJB
            oSB.append("<ParamValues>");
            for (String str: oItems) {
                oSB.append("<ParamValue><paramname>itemid</paramname>");
                oSB.append("<value>" + str + "</value></ParamValue>");
            }
            oSB.append("</ParamValues></MethodCall></BeanCall></MTSRequest>");

            System.out.println("xml " + oSB.toString());

            //write to the socket
            oReturnObj = 
                    (Object)MTSSocketWriter.readWriteObject("localhost", 7779, oSB.toString());


        } catch (Exception oEx) {
            oEx.printStackTrace();
        }
        return oReturnObj;
        
    }

}
