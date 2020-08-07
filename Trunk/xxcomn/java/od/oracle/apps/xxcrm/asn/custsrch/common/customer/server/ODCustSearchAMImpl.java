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
 |             ODCustSearchAMImpl.java                                       |
 |                                                                           |
 |  DESCRIPTION                                                              |
 |             AM Implementation file for the sales customer                 |     
 |             search results region .                                       |           
 |                                                                           |
 |  NOTES                                                                    |
 |                                                                           |
 |                                                                           |
 |  DEPENDENCIES                                                             |
 |    This class file is called from ODCustSearchCO.java                     |
 |                                                                           |
 |  HISTORY                                                                  |
 |                                                                           |
 |    30/11/2007 Anirban Chaudhuri   Created                                 |
 |                                                                           |
 +===========================================================================*/

package od.oracle.apps.xxcrm.asn.custsrch.common.customer.server;

import oracle.apps.asn.common.fwk.server.ASNApplicationModuleImpl;
import oracle.apps.asn.common.fwk.server.ASNViewObjectImpl;
import oracle.apps.asn.common.schema.server.ASNUtil;
import oracle.apps.fnd.framework.OAFwkConstants;
import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.common.VersionInfo;
import oracle.apps.fnd.framework.*;
import oracle.apps.fnd.framework.server.*;
import oracle.jbo.RowIterator;
import oracle.jbo.ViewObject;
import oracle.jbo.server.ApplicationModuleImpl;
import oracle.jbo.server.ViewRowImpl;
import oracle.apps.asn.common.customer.server.*;
import java.io.Serializable;

// Referenced classes of package oracle.apps.asn.common.customer.server:
//            CustSearchPVOImpl, CustSearchPVORowImpl, CustSearchResultsSVOImpl

public class ODCustSearchAMImpl extends ASNApplicationModuleImpl
{

    public ODCustSearchAMImpl()
    {
    }

    public void initQuery(String s)
    {
        String s1 = "asn.common.customer.server.CustSearchAMImpl.initQuery";
        OADBTransaction oadbtransaction = getOADBTransaction();
        boolean flag = oadbtransaction.isLoggingEnabled(2);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s1, "Begin", 2);
            StringBuffer stringbuffer = new StringBuffer();
            stringbuffer.append("Input Parameters: resourceId = ");
            stringbuffer.append(s);
            oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), 2);
        }
        CustSearchResultsSVOImpl custsearchresultssvoimpl = getCustSearchResultsSVO1();
        if(custsearchresultssvoimpl == null)
        {
            MessageToken amessagetoken[] = {
                new MessageToken("NAME", "CustSearchResultsSVO1")
            };
            throw new OAException("ASN", "ASN_CMMN_OBJ_MISS_ERR", amessagetoken);
        }
        if(!custsearchresultssvoimpl.isPreparedForExecution())
            custsearchresultssvoimpl.initQuery(s);
        if(flag)
            oadbtransaction.writeDiagnostics(s1, "End", 2);
    }

    public static void main(String args[])
    {
        ApplicationModuleImpl.launchTester("oracle.apps.asn.common.customer.server", "CustSearchAMLocal");
    }

    public void init()
    {
        OAViewObject oaviewobject = (OAViewObject)findViewObject("CustSearchPVO1");
        if(oaviewobject != null)
        {
            Object obj = null;
            if(oaviewobject.getFetchedRowCount() == 0)
            {
                oaviewobject.setMaxFetchSize(0);
                oaviewobject.insertRow(oaviewobject.createRow());
                CustSearchPVORowImpl custsearchpvorowimpl = (CustSearchPVORowImpl)oaviewobject.first();
                custsearchpvorowimpl.setAttribute("RowKey", "1");
            }
        }
    }

    public void setSearchType(String s)
    {
        OAViewObject oaviewobject = (OAViewObject)findViewObject("CustSearchPVO1");
        if(oaviewobject != null)
        {
            CustSearchPVORowImpl custsearchpvorowimpl = (CustSearchPVORowImpl)oaviewobject.first();
            if("DQM".equals(s))
            {
                custsearchpvorowimpl.setRenderDQMSearch(Boolean.TRUE);
                custsearchpvorowimpl.setRenderNonDQMSearch(Boolean.FALSE);
                return;
            }
            custsearchpvorowimpl.setRenderDQMSearch(Boolean.FALSE);
            custsearchpvorowimpl.setRenderNonDQMSearch(Boolean.TRUE);
        }
    }

    public CustSearchResultsSVOImpl getCustSearchResultsSVO1()
    {
        return (CustSearchResultsSVOImpl)findViewObject("CustSearchResultsSVO1");
    }

    public CustSearchPVOImpl getCustSearchPVO1()
    {
        return (CustSearchPVOImpl)findViewObject("CustSearchPVO1");
    }
    
	//anirban26Nov:Start

	public ODCustSearchResultsSVOImpl getODCustSearchResultsSVO()
    {
        return (ODCustSearchResultsSVOImpl)findViewObject("ODCustSearchResultsSVO");
    }

	public void initQueryForDefault(String loginResourceId)
    {
        String s1 = "od.oracle.apps.xxcrm.asn.custsrch.common.customer.server.ODCustSearchAMImpl.initQueryForDefault()";
		OADBTransaction oadbtransaction = null;
        try
        {
            oadbtransaction = getOADBTransaction();          
        }
        catch(Exception exception)
        {
            exception.printStackTrace();            
        }
        boolean flag = oadbtransaction.isLoggingEnabled(OAFwkConstants.STATEMENT);
        if(flag)
        {
            oadbtransaction.writeDiagnostics(s1, "Begin", OAFwkConstants.STATEMENT);
            StringBuffer stringbuffer = new StringBuffer();
            stringbuffer.append("Input Parameters: resourceId = ");
            stringbuffer.append(loginResourceId);
            oadbtransaction.writeDiagnostics(s1, stringbuffer.toString(), OAFwkConstants.STATEMENT);
        }
        
        try
        {
            Serializable aserializable[] = {
                loginResourceId
            };
            Class aclass[] = {
                Class.forName("java.lang.String")
            };
            if(flag)
            {
              oadbtransaction.writeDiagnostics(this,  "ODAM: In initQueryForDefault calling VO", OAFwkConstants.STATEMENT);
            } 
            getODCustSearchResultsSVO().invokeMethod("initQuery", aserializable, aclass);
        }
        catch(ClassNotFoundException classnotfoundexception)
        {
            oadbtransaction.writeDiagnostics(s1, "Error executing the Search: initQueryForDefault", OAFwkConstants.STATEMENT);
            classnotfoundexception.printStackTrace();
        }        

        if(flag)
            oadbtransaction.writeDiagnostics(s1, "End", 2);
    }

	//anirban26Nov:End

    public static final String RCS_ID = "$Header: ODCustSearchAMImpl.java 115.10 2005/01/04 02:40:16 rramacha ship $";
    public static final boolean RCS_ID_RECORDED = VersionInfo.recordClassVersion("$Header: ODCustSearchAMImpl.java 115.10 2005/01/04 02:40:16 achaudhu ship $", "od.oracle.apps.xxcrm.asn.custsrch.common.customer.server");

}
