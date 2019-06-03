CREATE OR REPLACE PACKAGE APPS.pa_security_extn AUTHID CURRENT_USER AS
/* $Header: PAPSECXS.pls 115.9 2004/08/19 04:19:42 bchandra ship $ */
/*#
 * This extension used for implementing Project security.
 * @rep:scope public
 * @rep:product PA
 * @rep:lifecycle active
 * @rep:displayname Project Security.
 * @rep:compatibility S
 * @rep:category BUSINESS_ENTITY PA_PROJECT
 * @rep:doccd 115pjoug.pdf See the Oracle Projects API's, Client Extensions, and Open Interfaces Reference
*/

/*#
 * This API is used to Oracle Projects provides for  the project security extension.
 * @param x_project_id  Identifier of the project or project template.
 * @rep:paraminfo {@rep:required}
 * @param x_person_id Identifier of the person.
 * @rep:paraminfo {@rep:required}
 * @param x_cross_project_user Indicates if the user is a cross project user Y/N.
 * @rep:paraminfo {@rep:required}
 * @param x_calling_module  Module in which the project security extension is called; OracleProjects sets this value for each
 * module in which it calls the security extension. The values are listed below.
 * @rep:paraminfo {@rep:required}
 * @param x_event Type of query level to check up on which you can define specific rules:ALLOW_QUERY ALLOW_UPDATE VIEW_LABOR_ COSTS .
 * @rep:paraminfo {@rep:required}
 * @param x_value Values to specify if result of the event:Y/N.
 * @rep:paraminfo {@rep:required}
 * @param x_cross_project_view Indicates if the user has cross project view access:y/n.
 * @rep:paraminfo {@rep:required}
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Project security .
 * @rep:compatibility S
*/

  PROCEDURE check_project_access ( X_project_id		IN NUMBER
                                 , X_person_id          IN NUMBER
                                 , X_cross_project_user IN VARCHAR2
                                 , X_calling_module	IN VARCHAR2
	                         , X_event              IN VARCHAR2
                                 , X_value              OUT VARCHAR2
                                 , X_cross_project_view IN VARCHAR2 := 'Y' );
  pragma RESTRICT_REFERENCES ( check_project_access, WNDS, WNPS );

END pa_security_extn;
/