package ejbtest;

import java.rmi.RemoteException;

import javax.ejb.CreateException;
import javax.ejb.EJBHome;

public interface SPSessionEJBHome extends EJBHome {
    SPSessionEJB create() throws RemoteException, CreateException;
}
