SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

CREATE OR REPLACE PACKAGE BODY APPS.XXPO_POXPOPAR_XMLP_PKG AS
/* $Header: POXPOPARB.pls 120.2 2007/12/25 11:18:20 krreddy noship $ */
USER_EXIT_FAILURE EXCEPTION;

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

function company(c_company_name_s in varchar2) return character is
begin
      return('glcc.'||c_company_name_s);
end;
function cost_center(c_cost_center_s in varchar2) return character is
begin
      return('glcc.'||c_cost_center_s);
end;

procedure get_precision is
begin
/*srw.attr.mask        :=  SRW.FORMATMASK_ATTR;*/null;
if P_qty_precision = 0 then /*srw.attr.formatmask  := '-NNN,NNN,NNN,NN0';*/null;
else
if P_qty_precision = 1 then /*srw.attr.formatmask  := '-NNN,NNN,NNN,NN0.0';*/null;
else
if P_qty_precision = 3 then /*srw.attr.formatmask  :=  '-NN,NNN,NNN,NN0.000';*/null;
else
if P_qty_precision = 4 then /*srw.attr.formatmask  :=   '-N,NNN,NNN,NN0.0000';*/null;
else
if P_qty_precision = 5 then /*srw.attr.formatmask  :=     '-NNN,NNN,NN0.00000';*/null;
else
if P_qty_precision = 6 then /*srw.attr.formatmask  :=      '-NN,NNN,NN0.000000';*/null;
else /*srw.attr.formatmask  :=  '-NNN,NNN,NNN,NN0.00';*/null;
end if; end if; end if; end if; end if; end if;
/*srw.set_attr(0,srw.attr);*/null;
end;

function orderby_clauseFormula return VARCHAR2 is
begin
if P_ORDERBY = 'COMPANY'
  then return('2');
elsif P_ORDERBY = 'COST CENTER'
  then return('3');
end if;
RETURN NULL; end;

function BeforeReport return boolean is
begin
DECLARE
   l_sort      po_lookup_codes.displayed_field%type;
BEGIN
  FORMAT_MASK:=po_common_XMLp_pkg.GET_PRECISION(P_qty_precision);
  get_boiler_plates;
  /*SRW.USER_EXIT('FND SRWINIT');*/null;
  IF P_ORDERBY IS NOT NULL THEN
     SELECT displayed_field
     INTO l_sort
     FROM po_lookup_codes
     WHERE lookup_code = P_ORDERBY
     AND lookup_type = 'SRS ORDER BY';
     P_ORDERBY_DISPLAYED := l_sort;
  ELSE
     P_ORDERBY_DISPLAYED := '';
  END IF;
 null;
 RETURN(TRUE);
END ;
 return (TRUE);
end ;
function AfterReport return boolean is
begin
/*SRW.USER_EXIT('FND SRWEXIT');*/null;
   return (TRUE);
end;

procedure get_lookup_meaning(p_lookup_type    in varchar2,
                 p_lookup_code    in varchar2,
                 p_lookup_meaning      in out nocopy varchar2)
                is
w_meaning varchar2(80);
begin
select meaning
  into w_meaning
  from fnd_lookups
 where lookup_type = p_lookup_type
   and lookup_code = p_lookup_code ;
p_lookup_meaning := w_meaning ;
exception
   when no_data_found then
                p_lookup_meaning := null ;
end ;
procedure get_boiler_plates is
w_industry_code varchar2(20);
w_industry_stat varchar2(20);
begin
if fnd_installation.get(0, 0,
                        w_industry_stat,
                    w_industry_code) then
   if w_industry_code = 'C' then
      c_company_title := null ;
   else
      get_lookup_meaning('IND_COMPANY',
                            w_industry_code,
             c_company_title);
   end if;
end if;
c_industry_code :=   w_Industry_code ;
end ;

function set_display_for_gov return boolean is
begin
if c_industry_code = 'C' then
   return(FALSE);
else
   if c_company_title is not null then
      return(TRUE);
   else
      return(FALSE);
   end if;
end if;
RETURN NULL; end ;

function set_display_for_core return boolean is
begin
if c_industry_code = 'C' then
   return(TRUE);
else
   if c_company_title is not null then
      return(FALSE);
   else
      return(TRUE);
   end if;
end if;
RETURN NULL; end;

function round_amount_list_subtotal_rep(c_amount_open_inv_sum in number, c_currency_precision in number) return number is
begin
  /*srw.reference(c_amount_open_inv_sum);*/null;
  /*srw.reference(c_currency_precision);*/null;
  return(round(c_amount_open_inv_sum, c_currency_precision));
end;
function AfterPForm return boolean is
lex_cost_center  varchar2(30);
lex_company_name varchar2(30);
begin
/*SRW.USER_EXIT('FND SRWINIT');*/null;
SELECT   fsa1.application_column_name , fsa2.application_column_name  into
           lex_cost_center,lex_company_name
FROM     --gl_sets_of_books            gsb           --Commented/Added by Shruthi on 10-Sept-13 for R12 Retrofit
         gl_ledgers                     gl
,        financials_system_parameters  fsp
,        fnd_segment_attribute_values  fsa1
,        fnd_segment_attribute_values  fsa2
WHERE    --gsb.set_of_books_id         = fsp.set_of_books_id
         gl.ledger_id                  = fsp.set_of_books_id
AND      fsa1.id_flex_code             = 'GL#'
--AND    fsa1.id_flex_num              = gsb.chart_of_accounts_id
AND      fsa1.id_flex_num              = gl.chart_of_accounts_id
AND      fsa1.segment_attribute_type   = 'FA_COST_CTR'
AND      fsa1.attribute_value          = 'Y'
AND      fsa2.id_flex_code             = 'GL#'
--AND    fsa2.id_flex_num              = gsb.chart_of_accounts_id
AND      fsa2.id_flex_num              = gl.chart_of_accounts_id
AND      fsa2.segment_attribute_type   = 'GL_BALANCING'
AND      fsa2.attribute_value          = 'Y' ;

 if  p_company_from is not null and p_company_to is not null then
    if p_company_from = p_company_to then
       where_clause :=  'glcc.'||lex_company_name||'= :p_company_from ' ;
    else
       where_clause :=  'glcc.'||lex_company_name||' >= :p_company_from  and  ';
       where_clause :=   where_clause||'glcc.'||lex_company_name||' <= :p_company_to  ';
    end if;
elsif p_company_from is not null and p_company_to is null then
        where_clause := 'glcc.'||lex_company_name||' >= :p_company_from ';
elsif p_company_from is null and p_company_to is not null then
        where_clause := 'glcc.'||lex_company_name||' <= :p_company_to  ' ;
elsif  p_company_from is null and p_company_to is null then
         where_clause := '1 = 1 ' ;
end if;
if  p_costcenter_from is not null and p_costcenter_to is not null then
    if p_costcenter_from = p_costcenter_to then
       where_clause :=  where_clause||' and glcc.'||lex_cost_center||'= :p_costcenter_from  ';
    else
       where_clause :=  where_clause||'and glcc.'||lex_cost_center||' >= :p_costcenter_from  and ';
       where_clause :=   where_clause||'glcc.'||lex_cost_center||' <= :p_costcenter_to  ';
    end if;
elsif p_costcenter_from is not null and p_costcenter_to is null then
        where_clause := where_clause||'and glcc.'||lex_cost_center||' >= :p_costcenter_from  ';
elsif p_costcenter_from is null and p_costcenter_to is not null then
        where_clause := where_clause||'and  glcc.'||lex_cost_center||'<= :p_costcenter_to  ';
elsif  p_costcenter_from is null and p_costcenter_to is null then
         where_clause := where_clause||'and 1 = 1' ;
end if;
  if WHERE_CLAUSE is null then WHERE_CLAUSE:='and 1=1'; end if;
  return (TRUE);
end;

--Function po_type Added by Shruthi on 10-Sept-13 for R12 Retrofit
function po_type return varchar2 is  
lp_po_type         varchar2(200);
begin
if P_PO_TYPE = 'Trade' then
    lp_po_type := 'AND poh.attribute_category = ''Trade''';
elsif P_PO_TYPE = 'Non-Trade' then
    lp_po_type := 'AND poh.attribute_category = ''Non-Trade''';
else
    lp_po_type := 'AND poh.attribute_category in (''Trade'',''Non-Trade'')';
    end if;
return(lp_po_type);
end;

--Functions to refer Oracle report placeholders--
 Function C_industry_code_p return varchar2 is
    Begin
     return C_industry_code;
     END;
 Function C_company_title_p return varchar2 is
    Begin
     return C_company_title;
     END;
END XXPO_POXPOPAR_XMLP_PKG ;
/
SHOW ERRORS;
