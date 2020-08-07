SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

CREATE OR REPLACE PACKAGE APPS.XXPO_POXPOPAR_XMLP_PKG AUTHID CURRENT_USER AS
/* $Header: POXPOPARS.pls 120.2 2007/12/25 11:19:04 krreddy noship $ */

-- +===========================================================================+
-- |                  Office Depot - Project Simplify                          |
-- +===========================================================================+
-- |Package Name : XXPO_POXPOPAR_XMLP_PKG                                      |
-- |Purpose      : This package contains the functions required                |
-- |               to get values in XXPOXPOPAR_XML report  .                   |
-- |                                                                           |
-- |                                                                           |
-- |Change History                                                             |
-- |                                                                           |
-- |Ver   Date          Author             Description                         |
-- |---   -----------   -----------------  ------------------------------------|
-- |1.0   10-Sept-2013  Shruthi Vasisht   R0277 - This is a copy of the standard package |
-- |                                      PO_POXPOPAR_XMLP_PKG with the custom changes|
-- |                                      included as part of the R12 upgrade. |
-- +===========================================================================+
    P_title    varchar2(52);
    P_conc_request_id    number;
    FORMAT_MASK varchar2(100);
    P_qty_precision    number;
    P_COMPANY_FROM    varchar2(40);
    P_COMPANY_TO    varchar2(40);
    P_COSTCENTER_FROM    varchar2(40);
    P_COSTCENTER_TO    varchar2(40);
    P_PO_TYPE    varchar2(40);
    P_ORDERBY    varchar2(40);
    P_ITEM_STRUCT_NUM    varchar2(40);
    P_FLEX_ITEM    varchar2(800);
    P_ORDERBY_DISPLAYED    varchar2(80);
    where_clause    varchar2(1000) := '1 = 1';
    C_industry_code    varchar2(32767);
    C_company_title    varchar2(30);
    function company(c_company_name_s in varchar2) return character  ;
    function cost_center(c_cost_center_s in varchar2) return character  ;
    function po_type return VARCHAR2   ;
    procedure get_precision  ;
    function orderby_clauseFormula return VARCHAR2  ;
    function BeforeReport return boolean  ;
    function AfterReport return boolean  ;
    procedure get_lookup_meaning(p_lookup_type    in varchar2,
                 p_lookup_code    in varchar2,
                 p_lookup_meaning      in out nocopy varchar2)
                 ;
    procedure get_boiler_plates  ;
    function set_display_for_gov return boolean  ;
    function set_display_for_core return boolean  ;
    function round_amount_list_subtotal_rep(c_amount_open_inv_sum in number, c_currency_precision in number) return number  ;
    function AfterPForm return boolean  ;
    Function C_industry_code_p return varchar2;
    Function C_company_title_p return varchar2;
END XXPO_POXPOPAR_XMLP_PKG;
/
SHOW ERRORS;
