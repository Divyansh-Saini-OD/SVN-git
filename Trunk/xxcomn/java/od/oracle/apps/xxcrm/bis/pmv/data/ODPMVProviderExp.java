// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames
// Source File Name:   ODPMVProviderExp.java

package od.oracle.apps.xxcrm.bis.pmv.data;

import java.util.Vector;
import oracle.apps.bis.pmv.data.*;
import oracle.apps.bis.data.DataObject;
import oracle.apps.bis.data.DataProvider;
import oracle.apps.bis.metadata.MetadataNode;
import oracle.apps.bis.pmv.PMVException;
import oracle.apps.bis.pmv.parameters.ParameterHelper;
import oracle.apps.bis.pmv.session.UserSession;
import oracle.apps.fnd.common.VersionInfo;
import od.oracle.apps.xxcrm.bis.pmv.data.ODPMVDataProviderExp;

// Referenced classes of package oracle.apps.bis.pmv.data:
//            ODPMVDataProvider, PMVMetadataProvider

public class ODPMVProviderExp
    implements oracle.apps.bis.data.DataProvider
{

    public ODPMVProviderExp(oracle.apps.bis.pmv.session.UserSession usersession, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper, java.util.Vector vector, boolean flag)
        throws oracle.apps.bis.pmv.PMVException
    {
        _metadataProvider = new PMVMetadataProvider(usersession, parameterhelper);
        if(flag)
        {
            _dataProvider = new ODPMVDataProviderExp(vector);
            return;
        } else
        {
            _dataProvider = new ODPMVDataProviderExp(usersession, parameterhelper, vector);
            return;
        }
    }

    public ODPMVProviderExp(oracle.apps.bis.pmv.session.UserSession usersession, oracle.apps.bis.pmv.parameters.ParameterHelper parameterhelper, java.util.Vector vector)
        throws oracle.apps.bis.pmv.PMVException
    {
        this(usersession, parameterhelper, vector, false);
    }

    public oracle.apps.bis.metadata.MetadataNode getPMVMetadata()
    {
        return _metadataProvider.getPMVMetadata();
    }

    public oracle.apps.bis.data.DataObject getDataObject(java.lang.Object obj)
    {
        return _dataProvider.getDataObject(obj);
    }

    public static final java.lang.String RCS_ID = "$Header: ODPMVProvider.java 115.5 2005/04/07 16:52:44 aleung noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODPMVProvider.java 115.5 2005/04/07 16:52:44 aleung noship $", "oracle.apps.bis.pmv.data");
    oracle.apps.bis.pmv.data.PMVMetadataProvider _metadataProvider;
    od.oracle.apps.xxcrm.bis.pmv.data.ODPMVDataProviderExp _dataProvider;

}
