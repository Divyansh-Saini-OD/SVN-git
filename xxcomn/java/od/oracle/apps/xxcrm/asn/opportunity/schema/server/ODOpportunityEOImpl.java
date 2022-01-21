/*===========================================================================+
 |   Copyright (c) 2001, 2005 Oracle Corporation, Redwood Shores, CA, USA    |
 |                         All rights reserved.                              |
 +===========================================================================+
 |  HISTORY                                                                  |
 +===========================================================================*/
/*===========================================================================+
 |      		       Office Depot - Project Simplify                       |
 |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization         |
 +===========================================================================+
 |  FILENAME                                                                 |
 |             ODOpportunityEOImpl.java                                      |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |   Entity Object(EO) Implementaion class for Opportunity creation/updation.|
 |                                                                           |
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from Opportunity's create/update page/screen.|
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    09/10/2007 Anirban Chaudhuri   Created                                 |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxcrm.asn.opportunity.schema.server;

import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.Key;
import oracle.apps.asn.opportunity.schema.server.*;
import oracle.apps.fnd.framework.OAFwkConstants;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jbo.server.*;
import oracle.jdbc.OracleTypes;
import oracle.jdbc.driver.OracleCallableStatement;
import oracle.jdbc.driver.OraclePreparedStatement;
import oracle.sql.DATE;
import oracle.sql.NUMBER;
import od.oracle.apps.xxcrm.asn.rosetta.*;
import oracle.jdbc.driver.OracleConnection;
import java.math.BigDecimal;
import java.sql.Types;
//  ---------------------------------------------------------------
//  ---    File generated by Oracle Business Components for Java.
//  ---------------------------------------------------------------

public class ODOpportunityEOImpl extends OpportunityEOImpl
{
  protected static final int MAXATTRCONST = EntityDefImpl.getMaxAttrConst("oracle.apps.asn.opportunity.schema.server.OpportunityEO");
  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   *
   * This is the default constructor (do not remove)
   */
  public ODOpportunityEOImpl()
  {
  }

  /**
   *
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("od.oracle.apps.xxcrm.asn.opportunity.schema.server.ODOpportunityEOImpl");
    }
    return mDefinitionObject;
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    return super.getAttrInvokeAccessor(index, attrDef);
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    super.setAttrInvokeAccessor(index, value, attrDef);
    return;
  }

  public void postChanges(TransactionEvent transactionevent)
  {
   String s = "od.oracle.apps.xxcrm.asn.opportunity.schema.server.ODOpportunityEOImpl.postChanges";
   OADBTransaction oadbtransaction = getOADBTransaction();

   try
      {

       super.postChanges(transactionevent);

	   oadbtransaction.writeDiagnostics(this,"Anirban 1st Oct 07: Inside substituted(OD) ODOpportunityEO", OAFwkConstants.STATEMENT);

       OracleCallableStatement cs = null;
	   int msgCount = -1;
	   OracleConnection conn = (OracleConnection)oadbtransaction.getJdbcConnection();
	   String l_ReturnStatus[] = new String[1];
       BigDecimal l_MessageCount[] = new BigDecimal[1];
       String l_MessageData[] = new String[1];
       XxTmTerritoryUtilPkg.NamTerrLookupOutRec[][] namTerrLookupOutRec = new XxTmTerritoryUtilPkg.NamTerrLookupOutRec[1][4];
       BigDecimal l_ApiVersion =new BigDecimal("1.0");
       String l_InitMessageList = "T";
	   BigDecimal a = null;
	   BigDecimal b = null;
	   BigDecimal c = null;
	   BigDecimal d = null;
	   java.sql.Timestamp timedate = null;

	   BigDecimal nam_terr_id = null;
	   BigDecimal resource_id = null;
	   BigDecimal role_id = null;
	   BigDecimal rsc_group_id = null;
	   BigDecimal entity_id = null;

	   NUMBER nam_terr_id_N  = null;
	   NUMBER resource_id_N  = null;
	   NUMBER role_id_N  = null;
	   NUMBER rsc_group_id_N  = null;
	   NUMBER entity_id_N  = null;
	   NUMBER sourceTerrId  = null;

	   DATE endDate = null;
	   DATE startDate = null;

	   try
       {
       cs = (OracleCallableStatement)conn.prepareCall("begin XX_JTF_SALES_REP_OPPTY_CRTN.create_sales_oppty(:1); end;");
	   cs.setNUMBER(1,new NUMBER(new BigDecimal((super.getLeadId()).toString())));

	   oadbtransaction.writeDiagnostics(this,"Anirban 29Jan08: Inside substituted(OD) ODOpportunityEO, calling Jeevan new api for sales lead id: "+(new Integer((super.getLeadId()).toString())).intValue(), OAFwkConstants.STATEMENT);

	   cs.execute();
       cs.close();
	   }
       catch (java.sql.SQLException sqE)
	   {
        oadbtransaction.writeDiagnostics(this,"Anirban java.sql.SQLException 3rd Oct 07: Inside substituted(OD) ODOpportunityEO", OAFwkConstants.STATEMENT);
		throw OAException.wrapperException(sqE);
	   }

	   /*BigDecimal partySiteId = new BigDecimal("0.0");
	   String l_StrpartySiteId = (super.getAddressId()).toString();

	   if(l_StrpartySiteId != null)
	   {
        if(!(l_StrpartySiteId.equals("")))
	    {
         partySiteId = new BigDecimal(l_StrpartySiteId);
	    }
	   }

       oadbtransaction.writeDiagnostics(this,"Anirban printing the partySiteId of the particular OPPORTUNITY: "+partySiteId, OAFwkConstants.STATEMENT);

       try
       {
		XxTmTerritoryUtilPkg.namTerrLookup(
          conn,
          l_ApiVersion,
          a,b,c,d,
          //"LEAD",
		  "PARTY_SITE",
          partySiteId,
		  //new BigDecimal("167738"),
		  timedate,
		  namTerrLookupOutRec,
          l_ReturnStatus,
          l_MessageData
         );
       }
       catch (Exception _ex)
       {
        oadbtransaction.writeDiagnostics(this,"Anirban ERROR 1st Oct 07: Inside substituted(OD) ODOpportunityEO", OAFwkConstants.STATEMENT);
		throw OAException.wrapperException(_ex);
       }

	   XxTmTerritoryUtilPkg.NamTerrLookupOutRec[] namTerrLookupOutRecCollect = new XxTmTerritoryUtilPkg.NamTerrLookupOutRec[4];

       XxTmTerritoryUtilPkg.NamTerrLookupOutRec namTerrLookupOutRecCollectRecord = new XxTmTerritoryUtilPkg.NamTerrLookupOutRec();

       oadbtransaction.writeDiagnostics(this,"Anirban printing: "+namTerrLookupOutRec[0], OAFwkConstants.STATEMENT);

	   namTerrLookupOutRecCollect = (XxTmTerritoryUtilPkg.NamTerrLookupOutRec[])namTerrLookupOutRec[0];


	  oadbtransaction.writeDiagnostics(this,"Anirban printing: "+namTerrLookupOutRecCollect, OAFwkConstants.STATEMENT);

	  oadbtransaction.writeDiagnostics(this,"Anirban printing l_ReturnStatus: "+l_ReturnStatus[0], OAFwkConstants.STATEMENT);
	  oadbtransaction.writeDiagnostics(this,"Anirban printing l_MessageData: "+l_MessageData[0], OAFwkConstants.STATEMENT);

	  int limit = (new Integer(l_MessageData[0])).intValue();




	   try
	   {

        for (int i=0;i<limit;i++ )
	    {
		   if(namTerrLookupOutRecCollect[i] != null)
		   {
            namTerrLookupOutRecCollectRecord = (XxTmTerritoryUtilPkg.NamTerrLookupOutRec)namTerrLookupOutRecCollect[i];

            cs = (OracleCallableStatement)conn.prepareCall("begin XX_JTF_RS_NAMED_ACC_TERR.Insert_Row(:1,sysdate,null,:2,null,null,null,null,:3,:4,:5,:6,:7,:8,:9,:10); end;");

            nam_terr_id = namTerrLookupOutRecCollectRecord.nam_terr_id;
			resource_id = namTerrLookupOutRecCollectRecord.resource_id;
			role_id = namTerrLookupOutRecCollectRecord.role_id;
			rsc_group_id = namTerrLookupOutRecCollectRecord.rsc_group_id;
			entity_id = namTerrLookupOutRecCollectRecord.entity_id;

			if(nam_terr_id != null)
			{
             nam_terr_id_N = new NUMBER(nam_terr_id);
			}
			if(resource_id != null)
			{
             resource_id_N = new NUMBER(resource_id);
			}
			if(role_id != null)
			{
             role_id_N = new NUMBER(role_id);
			}
			if(rsc_group_id != null)
			{
             rsc_group_id_N = new NUMBER(rsc_group_id);
			}
			if(entity_id != null)
			{
             entity_id_N = new NUMBER(entity_id);
			}

            cs.registerOutParameter(8, Types.VARCHAR, 0, 1000);
            cs.registerOutParameter(9, Types.VARCHAR, 0, 1000);
			cs.registerOutParameter(10, Types.INTEGER);

			cs.setNUMBER(1,new NUMBER(new BigDecimal("1.0")));
			cs.setNUMBER(2,nam_terr_id_N);
			cs.setNUMBER(3,resource_id_N);
			cs.setNUMBER(4,role_id_N);
			cs.setNUMBER(5,rsc_group_id_N);
			cs.setString(6,"OPPORTUNITY");
			cs.setNUMBER(7,new NUMBER(new BigDecimal((super.getLeadId()).toString())));

			oadbtransaction.writeDiagnostics(this,"Anirban inside FOR-IF, calling abhradip's api: nam_terr_id_N is: "+nam_terr_id_N.toString(), OAFwkConstants.STATEMENT);

			oadbtransaction.writeDiagnostics(this,"Anirban inside FOR-IF, calling abhradip's api: resource_id_N is: "+resource_id_N.toString(), OAFwkConstants.STATEMENT);

			oadbtransaction.writeDiagnostics(this,"Anirban inside FOR-IF, calling abhradip's api: role_id_N is: "+role_id_N.toString(), OAFwkConstants.STATEMENT);

			oadbtransaction.writeDiagnostics(this,"Anirban inside FOR-IF, calling abhradip's api: rsc_group_id_N is: "+rsc_group_id_N.toString(), OAFwkConstants.STATEMENT);

			oadbtransaction.writeDiagnostics(this,"Anirban inside FOR-IF, calling abhradip's api: SalesLeadId is: "+(super.getLeadId()).toString(), OAFwkConstants.STATEMENT);

            cs.execute();

            msgCount = cs.getInt(9);

            cs.close();
		   }
	    }
	   }
	   catch (java.sql.SQLException sqE)
	   {
        oadbtransaction.writeDiagnostics(this,"Anirban java.sql.SQLException 3rd Oct 07: Inside substituted(OD) ODOpportunityEO", OAFwkConstants.STATEMENT);
		throw OAException.wrapperException(sqE);
	   }
	   catch (Exception _Ex)
	   {
        oadbtransaction.writeDiagnostics(this,"Anirban java.io.Exception 3rd Oct 07: Inside substituted(OD) ODOpportunityEO", OAFwkConstants.STATEMENT);
		throw OAException.wrapperException(_Ex);
	   }
	   finally
       {
        try
        {
         cs.close();
        }
        catch (Exception e) {}
       }	   */

   }
   finally
   {
     oadbtransaction.writeDiagnostics(this,"Anirban 1st Oct 07: Inside LAST FINALLY substituted(OD) ODOpportunityEO", OAFwkConstants.STATEMENT);
   }
  }

  /**
   *
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(oracle.jbo.domain.Number leadId)
  {
    return new Key(new Object[] {leadId});
  }
}