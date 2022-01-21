package od.oracle.apps.xxptp.inv.setup.cp;

import java.io.PrintWriter;
import java.io.StringWriter;
import oracle.apps.fnd.common.*;
import oracle.apps.fnd.cp.request.OutFile;


public class ShipNetOut
{

    private OutFile mOut;
    boolean isStatement;
    private String module;

    public ShipNetOut(OutFile outfile, int i)
    {
        isStatement = false;
        module = "inv.setup.cp.CopyLoader";
        mOut = outfile;
        if(i == 1)
        {
            isStatement = true;
        }
    }

    public void writeToOut(String s)
    {
        if(isStatement)
        {
            mOut.writeln(s);
        }
    }

}
