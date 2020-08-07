package od.otc.mts;

import java.util.ArrayList;

public class EJBCallStruct {

    private String sJNDIName;
    private String sMethodName;
    private Class oParamType[];
    private ArrayList<Object[]> oParamVal;

    public EJBCallStruct() {
    }

    public void setJNDIName(String sJNDIName) {
        this.sJNDIName = sJNDIName;
    }

    public String getJNDIName() {
        return sJNDIName;
    }

    public void setMethodName(String sMethodName) {
        this.sMethodName = sMethodName;
    }

    public String getMethodName() {
        return sMethodName;
    }

    public void setParamType(Class[] oParamType) {
        this.oParamType = oParamType;
    }

    public Class[] getParamType() {
        return oParamType;
    }

    public void setParamVal(ArrayList<Object[]> oParamVal) {
        this.oParamVal = oParamVal;
    }

    public ArrayList<Object[]> getParamVal() {
        return oParamVal;
    }
    
} //class
