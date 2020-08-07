package ejbtest;

import java.util.Vector;

import javax.ejb.EJBLocalObject;

public interface SPSessionEJBLocal extends EJBLocalObject {
    Object callStoredProc(String sParam);

    String testMethod();

    Object callStoredProcThruMTS(Vector oItems, String sExec);
}
