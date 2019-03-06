package od.oracle.apps.xxom.atp.exception;

public class ATPNotApplicableException extends Exception {
    public static final String RCS_ID = 
        "$Header: AtpNotApplicableException.java 1.2 2007/20/06 09:52:41 smani $";
    private static final String ERROR_KEY = "XXOMATP-101";

    public ATPNotApplicableException() {
        super(ERROR_KEY);
    }

    public ATPNotApplicableException(String s) {
        super(ERROR_KEY + s);
    }


}
