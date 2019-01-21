package od.oracle.apps.xxfin.ar.irec.billmanagement.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import java.sql.CallableStatement;
import java.sql.Types;

public class landingAMImpl extends OAApplicationModuleImpl
{
  public landingAMImpl()
  {
  }

  public static void main(String[] args)
  {
    launchTester("od.oracle.apps.xxfin.ar.irec.billmanagement.server", "landingAMLocal");
  }
}