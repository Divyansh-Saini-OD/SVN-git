CREATE OR REPLACE PACKAGE APPS.XX_GL_GET_AR_DATA AUTHID CURRENT_USER as
/* $Header: glardrds.pls 115.2 2002/11/11 23:53:45 djogg ship $ */

   Procedure Get_AR_DATA(
     l_reference3               IN  VARCHAR2,
     l_reference10              IN  VARCHAR2,
     l_category                 IN  VARCHAR2,
     l_acct_line_type           OUT NOCOPY VARCHAR2,
     l_acct_line_type_name      OUT NOCOPY VARCHAR2,
     l_trx_line_number          OUT NOCOPY NUMBER,
     l_trx_line_type_name       OUT NOCOPY VARCHAR2,
     l_currency_code            OUT NOCOPY VARCHAR2,
     l_trx_number_displayed     OUT NOCOPY VARCHAR2,
     l_entered_dr               OUT NOCOPY NUMBER,
     l_entered_cr               OUT NOCOPY NUMBER,
     l_accounted_dr             OUT NOCOPY NUMBER,
     l_accounted_cr             OUT NOCOPY NUMBER ,
     l_trx_hdr_id               OUT NOCOPY NUMBER) ;

END XX_GL_GET_AR_DATA;
/