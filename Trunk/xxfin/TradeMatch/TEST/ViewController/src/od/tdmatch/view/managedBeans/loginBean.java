package od.tdmatch.view.managedBeans;

//package view;

import java.io.IOException;

import java.security.Principal;

import java.util.Set;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import weblogic.security.URLCallbackHandler;
import javax.security.auth.Subject;
import javax.security.auth.login.FailedLoginException;
import javax.security.auth.login.LoginException;
import weblogic.security.services.Authentication;
import weblogic.security.principal.WLSGroupImpl;

import weblogic.servlet.security.ServletAuthentication;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.myfaces.trinidad.render.ExtendedRenderKitService;


public class loginBean {
    private String _username;
    private String _password;
    public loginBean() {
        super();
    }

    public void setUsername(String _username) {
        this._username = _username;
    }

    public String getUsername() {
        return _username;
    }

    public void setPassword(String _password) {
        this._password = _password;
    }

    public String getPassword() {
        return _password;
    }
    
    public String doLogin() {
        String un = _username;
        byte[] pw = _password.getBytes();
        FacesContext ctx = FacesContext.getCurrentInstance();
        HttpServletRequest request = (HttpServletRequest)ctx.getExternalContext().getRequest();
        try {
            Subject mySubject = Authentication.login(new URLCallbackHandler(un, pw));
            ServletAuthentication.runAs(mySubject, request);
//            String loginUrl = "/adfAuthentication?success_url=/faces/Home.jspx";
            String loginUrl = "/faces/Home.jspx";

            ServletAuthentication.generateNewSessionID(request);

            int renderPage = isSufficientRolesApplied(mySubject);
            if (renderPage == 1) {
                HttpServletResponse response = (HttpServletResponse)ctx.getExternalContext().getResponse();
                sendForward(request, response, loginUrl);
            } else {
                FacesContext ctx1 = FacesContext.getCurrentInstance();
                FacesMessage msg =
                    new FacesMessage(FacesMessage.SEVERITY_ERROR, "Not Authorized", "You are not authorized to Login!!");
                ctx1.addMessage(null, msg);
            }

        } catch (FailedLoginException fle) {
            FacesMessage msg =
                new FacesMessage(FacesMessage.SEVERITY_ERROR, "Incorrect Username or Password", "An incorrect Username or Password" +
                                 " was specified");
            ctx.addMessage(null, msg);
            fle.printStackTrace();
            return null;


        } catch (LoginException le) {
            reportUnexpectedLoginError("LoginException", le);
            return null;

        }
        return null;
    }

    private int isSufficientRolesApplied(Subject subject) {
        int returnVal = 0;
        try {
            if ((subject != null) && (subject.getPrincipals() != null)) {
                Set<Principal> allPrincipals = subject.getPrincipals();
                for (Principal principal : allPrincipals) {
                    if ((principal instanceof WLSGroupImpl)) {
                        if ((principal.getName().equalsIgnoreCase("UMX|CDR_DEFINER"))) {
                            returnVal = 1;
                            break;
                        } else {
                            returnVal = 2;
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return returnVal;
    }
    
    
    
    private void sendForward(HttpServletRequest request, HttpServletResponse response, String forwardUrl) {
        FacesContext ctx = FacesContext.getCurrentInstance();
        RequestDispatcher dispatcher = request.getRequestDispatcher(forwardUrl);
        try {
            dispatcher.forward(request, response);
        } catch (ServletException se) {
            reportUnexpectedLoginError("ServletException", se);
        } catch (IOException ie) {
            reportUnexpectedLoginError("IOException", ie);
        }
        ctx.responseComplete();
    }

    private void reportUnexpectedLoginError(String errType, Exception e) {
        StringBuilder script = new StringBuilder();
        script.append("alert('Service Unavailable. Please try again');");
        String finalscript = script.toString();
        FacesContext fctx = FacesContext.getCurrentInstance();
        ExtendedRenderKitService erks = null;
        erks = org.apache.myfaces.trinidad.util.Service.getRenderKitService(fctx, ExtendedRenderKitService.class);
        erks.addScript(fctx, finalscript);
        FacesMessage msg =
            new FacesMessage(FacesMessage.SEVERITY_ERROR, "Unexpected error during login", "Unexpected error during login (" +
                             errType + "), please consult logs for detail");
        FacesContext.getCurrentInstance().addMessage(null, msg);
        e.printStackTrace();
    }
}
