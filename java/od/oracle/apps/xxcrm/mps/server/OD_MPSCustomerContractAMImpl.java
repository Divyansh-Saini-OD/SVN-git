package od.oracle.apps.xxcrm.mps.server;

import od.oracle.apps.xxcrm.mps.lov.server.OD_MPSYesNoVOImpl;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.jbo.domain.Number;
import oracle.sql.ARRAY;
import oracle.sql.STRUCT;
import oracle.sql.ArrayDescriptor;
import oracle.sql.StructDescriptor;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleCallableStatement;
import oracle.apps.fnd.framework.server.OADBTransactionImpl;
import java.util.ArrayList;
import oracle.apps.fnd.framework.OAException;
import java.util.Date;
import od.oracle.apps.xxcrm.mps.lov.server.OD_MPSPartyNameLOVVOImpl;
import od.oracle.apps.xxcrm.mps.lov.server.OD_MPSProgramTypeVOImpl;
import od.oracle.apps.xxcrm.mps.lov.server.OD_MPSPaymentMethodVOImpl;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class OD_MPSCustomerContractAMImpl extends OAApplicationModuleImpl {
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public OD_MPSCustomerContractAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxcrm.mps.server", "OD_MPSCustomerContractAMLocal");
  }



  /* Method to Fetch Customer against partyName */
  public void initFetchPartyContact(String partyName, String partyId)
  {
    System.out.println("##### in AM partyId="+partyId);
    OD_MPSCustContactVOImpl mpsCustContViewVO = getOD_MPSCustContactVO();
    mpsCustContViewVO.initFetchPartyContact(partyName, partyId);
  }

  /* Method to Fetch Location Details against Serial No */
  public void initFetchLocationDetails(String serialNo)
  {
    System.out.println("##### in AM initFetchLocationDetails serialNo="+serialNo);
    OD_MPSCustLocationUpdateVOImpl mpsCustLocUpdateSerialVO = getOD_MPSCustLocationUpdateVO();
    mpsCustLocUpdateSerialVO.initFetchLocationDetails(serialNo);
  }

  public void initFetchLocationSerialNo(String serialNo)
  {
    System.out.println("##### in AM serialNo="+serialNo);
    OD_MPSSerialNoVOImpl mpsCustLocUpdateSerialVO = getOD_MPSSerialNoVO();
    mpsCustLocUpdateSerialVO.initFetchLocationDetails(serialNo);
  }
  
  /* Method to Fetch locations */
  public void initFetchLocations(String location)
  {
    OD_MPSCustLocationDetailsVOImpl mpsCustLocatDetailVO = getOD_MPSCustLocationDetailsVO();
    mpsCustLocatDetailVO.initFetchLocations(location);
  }

  /* Method to Fetch address */
  public void initFetchAddress(String address)
  {
    OD_MPSCustLocationDetailsVOImpl mpsCustLocatDetailVO = getOD_MPSCustLocationDetailsVO();
    mpsCustLocatDetailVO.initFetchAddress(address);
  }  

  /*Method to fetch location based on serial No link. */
  public void initFetchSerialNoLink(String serialNo)
  {
    OD_MPSCustLocationDetailsVOImpl mpsCustLocatDetailVO = getOD_MPSCustLocationDetailsVO();
    mpsCustLocatDetailVO.initFetchSerialNoLink(serialNo);
  }

  /* Method to Fetch contact details for update */
  public void initCustContUpdate(String partyId, String location)
  { System.out.println("##### initCustContUpdate in AM");
    OD_MPSCustContactUpdateVOImpl mpsCustContUpdateVO = getOD_MPSCustContactUpdateVO();
    mpsCustContUpdateVO.initCustContUpdate(partyId, location);
  }

  /* Method to Fetch contact details for update */
  //Defect: 23597
  public void initAddressCustContUpdate(String partyId, String serialNo)
  { System.out.println("##### initAddressCustContUpdate in AM partyId="+partyId+" serialNo="+serialNo);
    OD_MPSCustContactUpdateVOImpl mpsCustContUpdateVO = getOD_MPSCustContactUpdateVO();
    mpsCustContUpdateVO.initAddressCustContUpdate(partyId, serialNo);
  }  

  public void initCurrentLevel(String serialNo)
  {
    OD_MPSCurrentLevelsVOImpl mpsCurrLevelVO = getOD_MPSCurrentLevelsVO();
    mpsCurrLevelVO.initCurrentLevel(serialNo);
  }

  public void initCurrentCount(String serialNo)
  {
    OD_MPSCurrentCountVOImpl mpsCurrCountVO = getOD_MPSCurrentCountVO();
    mpsCurrCountVO.initCurrentCount(serialNo);
  }  

  public void initOrderDetails(String serialNo, String customerId)
  {
    OD_MPSOrderDetailsVOImpl mpsOrderDetailsVO = getOD_MPSOrderDetailsVO();
    mpsOrderDetailsVO.initOrderDetails(serialNo,customerId);
  }  

  public void saveCustContact(String partyId, String serialNo, String Contact, String Phone, String Address1, String Address2, String City, String State, String Zip, String CostCenter, String Location, String PoNumber)
  {
    OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getOADBTransaction();
    OracleConnection conn = (OracleConnection)oadbtransactionimpl.getJdbcConnection();
    ARRAY message_display = null;
    ArrayList arow= new ArrayList();
    StructDescriptor voRowStruct = null;
    ArrayDescriptor arrydesc = null;
    ARRAY p_message_list = null;
    OracleCallableStatement cStmt=null;

    OADBTransactionImpl oadbtransactionimpl1 = (OADBTransactionImpl)getOADBTransaction();
    OracleConnection conn1 = (OracleConnection)oadbtransactionimpl1.getJdbcConnection();
    String result = null;
    try{
    cStmt
    =(OracleCallableStatement)conn.prepareCall("{CALL XX_CRM_MPS_PKG.UPDATE_CUSTOMER_CONTACTS(:1,:2,:3,:4,:5,:6,:7,:8,:9,:10,:11,:12,:13)}");
    cStmt.setString(1,partyId);
    cStmt.setString(2,Contact);
    cStmt.setString(3,Phone);
    cStmt.setString(4,Address1);
    cStmt.setString(5,Address2);
    cStmt.setString(6,City);
    cStmt.setString(7,State);
    cStmt.setString(8,Zip);
    cStmt.setString(9,CostCenter);
    cStmt.setString(10,serialNo);
    cStmt.setString(11,Location);
    cStmt.setString(12,PoNumber);
    cStmt.registerOutParameter(13,OracleTypes.CHAR);
    cStmt.execute();
//    cStmt.registerOutParameter(2,OracleTypes.CHAR);
    cStmt.execute();
    result = cStmt.getString(11);
    System.out.println("##### result="+result);

    }
    catch(Exception e)
    {
      System.err.println("##### method exception: " + e.getMessage());
    }
	finally {
               try {
				   if (cStmt!=null)
				     cStmt.close();
				   }
               catch(Exception e) {
				   System.err.println("exception while closing the callable statement: " + e.getMessage());
               }
	}
    if("SUCCESS".equals(result))
    throw new OAException("XXCRM","OD_CRM_MPS_SAVED",null,OAException.INFORMATION,null);
/*
       try{
        // Create descriptors for each Oracle collection type required
        StructDescriptor recDescriptor = 
        StructDescriptor.createDescriptor("RECTYPE",conn);

        // create a callable statement to make the call to the proc
//        CallableStatement stmt = 
//            conn.prepareCall("{ call p_rec(?, ?) }");
        cStmt  =(OracleCallableStatement)conn.prepareCall("{ call p_rec(?, ?) }");
//        cStmt  =(OracleCallableStatement)conn.prepareCall("{CALL XX_OD_MPS_PKG.update_customer_contacts(:1,:2)}");    

        // In java, you stage the values for each field in the Oracle record in an array
        Object[] java_record_array   = new Object[2];
        Object[] return_record_array = new Object[2];

        // put some values in the array

        java_record_array[0] = "Gaurav Agarwal";
        java_record_array[1] = "888-999-777-666";

        // cast the java arrays into the Oracle record type for the input record
        STRUCT oracle_record = new STRUCT(recDescriptor, conn, java_record_array);
        // This struct is used to hold the return record type 
        STRUCT output_oracle_record;

        // Bind the input record
        cStmt.setObject(1, oracle_record);

        // register the output parameter
        cStmt.registerOutParameter(2, OracleTypes.STRUCT, "RECTYPE");
//      cStmt.registerOutParameter(2,OracleTypes.CHAR);
      cStmt.execute();
      output_oracle_record = ((OracleCallableStatement)cStmt).getSTRUCT(2);

        // finally cast the Oracle struct back into a Java array
        return_record_array = output_oracle_record.getAttributes();

        // Show the results:
        System.out.println("First Object is now "+return_record_array[0]+" and "+return_record_array[1]);

//      String result = cStmt.getString(2);
//      System.out.println("##### result="+result);
       }
      catch(Exception e)
      {
      System.err.println("##### method exception: " + e.getMessage());
      }
//        stmt.execute();

        // get the returned record from the callable statement - note the cast on the stmt handle    
//        output_oracle_record = ((OracleCallableStatement)stmt).getSTRUCT(2);

        // finally cast the Oracle struct back into a Java array
//        return_record_array = output_oracle_record.getAttributes();

        // Show the results:
//        System.out.println("First Object is now "+return_record_array[0]+" and "+return_record_array[1]);

    /*
//      LogTrans app = new LogTrans();
      int commit = 1;
      Vector vector = new Vector();


      Object[] attr = new Object[3];
      attr[0] = (Object) new String("Suraj Charan");
      attr[1] = (Object) new String("TEST@TEST.COM");
      attr[2] = (Object) new String("TEST DATA");

      try 
      {
//      app.connect();



      StructDescriptor structdesc = StructDescriptor.createDescriptor("RECTYPE",conn1);
      vector.add((Object)new STRUCT(structdesc, conn1, attr));


      ArrayDescriptor arraydesc = ArrayDescriptor.createDescriptor("RECTAB",conn1);

      Object obj_array[] = vector.toArray();
      ARRAY array = new ARRAY(arraydesc,conn1,obj_array);

      System.out.println("Please check database");
      cStmt
    =(OracleCallableStatement)conn.prepareCall("{CALL XX_OD_MPS_PKG.update_customer_contacts(:1,:2)}");
    cStmt.setArray(1,p_message_list);
//    cStmt.registerOutParameter(2,OracleTypes.CHAR);
//    cStmt.execute();

//      cStmt.setARRAY(1, array);
//      cStmt.setObject(1,array);
      cStmt.registerOutParameter(2,OracleTypes.CHAR);
      cStmt.execute();
      String result = cStmt.getString(2);
      System.out.println("##### result="+result);

      }
      catch(Exception e)
      {
      System.err.println("##### method exception: " + e.getMessage());
      }
 */
    /*
    try
    {
    //initializing object types in java.
    voRowStruct = StructDescriptor.createDescriptor("RECTYPE",conn);
    arrydesc = ArrayDescriptor.createDescriptor("RECTAB",conn);
    }
    catch (Exception e)
    {
    throw OAException.wrapperException(e);
    }

    OD_MPSCustContactUpdateVOImpl mpsCustContUpdateVO = getOD_MPSCustContactUpdateVO();
//    for(OD_MPSCustContactUpdateVORowImpl  row = (OD_MPSCustContactUpdateVORowImpl)mpsCustContUpdateVO.first();    row!=null;    row = (OD_MPSCustContactUpdateVORowImpl)mpsCustContUpdateVO.next())
//    {
    //We have made this method to create struct arraylist
    // from which we will make ARRAY
    //the reason being in java ARRAY length cannot be dynamic
    //see the method defination below.
    OD_MPSCustContactUpdateVORowImpl  row = (OD_MPSCustContactUpdateVORowImpl)mpsCustContUpdateVO.getCurrentRow();
    populateObjectArraylist(row,voRowStruct,arow);
//    }

    STRUCT [] obRows= new STRUCT[arow.size()];
    for(int i=0;i < arow.size();i++)
    {
    obRows[i]=(STRUCT)arow.get(i);
    }

    try
    {
    p_message_list = new ARRAY(arrydesc,conn,obRows);
    }
    catch (Exception e)
    {
    throw OAException.wrapperException(e);
    }

    //jdbc code to execute pl/sql procedure
    try
    {
    cStmt
    =(OracleCallableStatement)conn.prepareCall("{CALL XX_OD_MPS_PKG.update_customer_contacts(:1,:2)}");
    cStmt.setArray(1,p_message_list);
    cStmt.registerOutParameter(2,OracleTypes.CHAR);
    cStmt.execute();

    //getting Array back
//    message_display = cStmt.getARRAY(2);
    String result = cStmt.getString(2);
    System.out.println("##### result="+result);
    //Getting sql data types in oracle.sql.datum array
    //which will typecast the object types
//    Datum[] arrMessage = message_display.getOracleArray();

    //getting data and printing it
    /*
    for (int i = 0; i < arrMessage.length; i++)
    {
    oracle.sql.STRUCT os = (oracle.sql.STRUCT)arrMessage[i];
    Object[] a = os.getAttributes();
    System.out.println("##### a [0 ] >>attribute1=" + a[0]);
    System.out.println("##### a [1 ] >>attribute2=" + a[1]);
    System.out.println("##### a [2 ] >>attribute3=" + a[2]);
    //You can typecast back these objects to java object type


    }
    *//*
    }
    catch (Exception e1)
    {
    throw OAException.wrapperException(e1);
    }
      */
  }


    public void populateObjectArraylist( OD_MPSCustContactUpdateVORowImpl row,StructDescriptor voRowStruct , ArrayList arow)
    {
    OADBTransactionImpl oadbtransactionimpl = (OADBTransactionImpl)getOADBTransaction();
    OracleConnection conn = (OracleConnection)oadbtransactionimpl.getJdbcConnection();
    Object[] attribMessage = new Object[8];
    String attr1 = null;
    Date attr2 = null;
    Number attr3 = null;

    //Get value from Vo row and put in attr1,att2 and attr 3

    //Putting values in object array
    attribMessage[0] = row.getSiteContact();
    attribMessage[1] = row.getSiteContactPhone();
    attribMessage[2] = row.getSiteAddress1();
    attribMessage[3] = row.getSiteCity();
    attribMessage[4] = row.getSiteState();
    attribMessage[5] = row.getSiteZipCode();
    attribMessage[6] = row.getDeviceCostCenter();
    attribMessage[7] = row.getDeviceLocation();;

    

    try
    {
    STRUCT loadedStructTime = new STRUCT(voRowStruct, conn, attribMessage);
    arow.add(loadedStructTime);
    }
    catch (Exception e)
    {
    }

    }  

  public void saveData()
  {
    getOADBTransaction().commit();
  }

  /**
   * 
   * Container's getter for OD_MPSCustContactVO
   */
  public OD_MPSCustContactVOImpl getOD_MPSCustContactVO()
  {
    return (OD_MPSCustContactVOImpl)findViewObject("OD_MPSCustContactVO");
  }

  /**
   * 
   * Container's getter for OD_MPSCustLocationDetailsVO
   */
  public OD_MPSCustLocationDetailsVOImpl getOD_MPSCustLocationDetailsVO()
  {
    return (OD_MPSCustLocationDetailsVOImpl)findViewObject("OD_MPSCustLocationDetailsVO");
  }

  /**
   * 
   * Container's getter for OD_MPSCustContactUpdateVO
   */
  public OD_MPSCustContactUpdateVOImpl getOD_MPSCustContactUpdateVO()
  {
    return (OD_MPSCustContactUpdateVOImpl)findViewObject("OD_MPSCustContactUpdateVO");
  }




  /**
   * 
   * Container's getter for OD_MPSCustLocationUpdateVO
   */
  public OD_MPSCustLocationUpdateVOImpl getOD_MPSCustLocationUpdateVO()
  {
    return (OD_MPSCustLocationUpdateVOImpl)findViewObject("OD_MPSCustLocationUpdateVO");
  }

  /**
   * 
   * Container's getter for OD_MPSPartyNameLOVVO
   */
  public OD_MPSPartyNameLOVVOImpl getOD_MPSPartyNameLOVVO()
  {
    return (OD_MPSPartyNameLOVVOImpl)findViewObject("OD_MPSPartyNameLOVVO");
  }

  /**
   * 
   * Container's getter for OD_MPSSerialNoVO
   */
  public OD_MPSSerialNoVOImpl getOD_MPSSerialNoVO()
  {
    return (OD_MPSSerialNoVOImpl)findViewObject("OD_MPSSerialNoVO");
  }

  /**
   * 
   * Container's getter for OD_MPSCurrentLevelsVO
   */
  public OD_MPSCurrentLevelsVOImpl getOD_MPSCurrentLevelsVO()
  {
    return (OD_MPSCurrentLevelsVOImpl)findViewObject("OD_MPSCurrentLevelsVO");
  }

  /**
   * 
   * Container's getter for OD_MPSCurrentCountVO
   */
  public OD_MPSCurrentCountVOImpl getOD_MPSCurrentCountVO()
  {
    return (OD_MPSCurrentCountVOImpl)findViewObject("OD_MPSCurrentCountVO");
  }

  /**
   * 
   * Container's getter for OD_MPSOrderDetailsVO
   */
  public OD_MPSOrderDetailsVOImpl getOD_MPSOrderDetailsVO()
  {
    return (OD_MPSOrderDetailsVOImpl)findViewObject("OD_MPSOrderDetailsVO");
  }

  /**
   * 
   * Container's getter for OD_MPSProgramTypeVO
   */
  public OD_MPSProgramTypeVOImpl getOD_MPSProgramTypeVO()
  {
    return (OD_MPSProgramTypeVOImpl)findViewObject("OD_MPSProgramTypeVO");
  }

  /**
   * 
   * Container's getter for OD_MPSPaymentMethodVO
   */
  public OD_MPSPaymentMethodVOImpl getOD_MPSPaymentMethodVO()
  {
    return (OD_MPSPaymentMethodVOImpl)findViewObject("OD_MPSPaymentMethodVO");
  }


    /**Container's getter for OD_MPSYesNoVO
     */
    public OD_MPSYesNoVOImpl getOD_MPSYesNoVO() {
        return (OD_MPSYesNoVOImpl)findViewObject("OD_MPSYesNoVO");
    }
}
