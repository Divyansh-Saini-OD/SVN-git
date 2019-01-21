package com.od.external.view.bean;

import javax.faces.application.FacesMessage;
import javax.faces.context.FacesContext;
import javax.faces.event.PhaseId;

import oracle.adf.view.rich.context.ExceptionHandler;

public class XxControllerExpHandler extends ExceptionHandler{
    public XxControllerExpHandler() {
        super();
    }
    public void handleException(FacesContext facesContext,
                                  Throwable throwable, PhaseId phaseId)
        throws Throwable
      {
        
      }
}
