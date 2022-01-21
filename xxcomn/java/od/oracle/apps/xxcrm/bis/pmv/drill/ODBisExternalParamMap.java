// Decompiled by Jad v1.5.8f. Copyright 2001 Pavel Kouznetsov.
// Jad home page: http://www.kpdus.com/jad.html
// Decompiler options: fullnames 
// Source File Name:   ODBisExternalParamMap.java

package od.oracle.apps.xxcrm.bis.pmv.drill;

import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.common.VersionInfo;

public class ODBisExternalParamMap
{

    public ODBisExternalParamMap(java.lang.String s, com.sun.java.util.collections.HashMap hashmap, com.sun.java.util.collections.HashMap hashmap1, com.sun.java.util.collections.HashMap hashmap2)
    {
        m_FunctionName = s;
        m_ParamNameMap = hashmap;
        m_DimLevelMap = hashmap1;
        m_ParamOAEncryptMap = hashmap2;
    }

    public com.sun.java.util.collections.HashMap getParamNameMap()
    {
        return m_ParamNameMap;
    }

    public com.sun.java.util.collections.HashMap getDimLevelMap()
    {
        return m_DimLevelMap;
    }

    public com.sun.java.util.collections.HashMap getParamOAEncryptMap()
    {
        return m_ParamOAEncryptMap;
    }

    public static final java.lang.String RCS_ID = "$Header: ODBisExternalParamMap.java 115.1 2004/12/22 11:07:09 serao noship $";
    public static final boolean RCS_ID_RECORDED = oracle.apps.fnd.common.VersionInfo.recordClassVersion("$Header: ODBisExternalParamMap.java 115.1 2004/12/22 11:07:09 serao noship $", "od.oracle.apps.xxcrm.bis.pmv.drill.ODBisExternalParamMap");
    private java.lang.String m_FunctionName;
    private com.sun.java.util.collections.HashMap m_ParamNameMap;
    private com.sun.java.util.collections.HashMap m_DimLevelMap;
    private com.sun.java.util.collections.HashMap m_ParamOAEncryptMap;

}
