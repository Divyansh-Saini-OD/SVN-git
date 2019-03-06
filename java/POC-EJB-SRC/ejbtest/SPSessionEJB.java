package ejbtest;

import java.rmi.RemoteException;

import java.util.Vector;

import javax.ejb.EJBObject;

public interface SPSessionEJB extends EJBObject {
    Object callStoredProc(String sParam) throws RemoteException;

    String testMethod() throws RemoteException;

    Object callStoredProcThruMTS(Vector oItems, 
                                 String sExec) throws RemoteException;
}
