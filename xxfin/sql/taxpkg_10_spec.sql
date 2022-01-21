/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  ADP Taxware                                       A#
 *#W  Address: 401 Edgewater Place, Suite 260                    X#
 *#A           Wakefield, MA 01880-6210                          W#
 *#R           www.taxware.com                                   A#
 *#E  Contact: Tel Main # 781-557-2600                           R#
 *#T                                                             E#
 *#A  THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED  T#
 *#X  WITHOUT WRITTEN PERMISSION FROM govONE Solutions, LP       A#
 *#W                                                             X#
 *#A       Copyright © 2007 ADP Taxware                          W#
 *#R   THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL          A#
 *#E                     ALL RIGHTS RESERVED                     R#
 *#T                                                             E#
 *#AXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE##
 *#################################################################
 *#     $Header: $Twev5ARTaxpsv2.0             July 13, 2006
 *###############################################################
 *   Source File          :-taxpkg_10_spec.sql
 *###############################################################
 */
create or replace
PACKAGE TAXPKG_10 /* $Header: $Twev5ARTaxpsv2.0 */  AUTHID CURRENT_USER AS

   /********** OLD API TAXFN_TAX010 **************/
    /*** GLOBAL VARIABLES ***/

       OraLink                     TAXPKG_GEN.t_OraParm;
       TaxLink                     TAXPKG_GEN.TaxParm;

       JurLink                     TAXPKG_GEN.JurParm;
       TaxSelParm                  TAXPKG_GEN.SELPARMTYP%TYPE;

       TaxFlags                    TAXPKG_GEN.TaxFlagsType;
       JurFlags                    TAXPKG_GEN.JurFlagsType;

       Federal_Record              TAXPKG_GEN.TFTaxMst;
       County_Record               TAXPKG_GEN.TCTaxMst;
       Secondary_County_Record     TAXPKG_GEN.TCTaxMst;
       Local_Record                TAXPKG_GEN.TLTaxMst;
       Secondary_Local_Record      TAXPKG_GEN.TLTaxMst;

       SFCounty                    TAXPKG_GEN.TCTaxMst;
       SFLocal                     TAXPKG_GEN.TLTaxMst;
       STCounty                    TAXPKG_GEN.TCTaxMst;
       STLocal                     TAXPKG_GEN.TLTaxMst;
       POOCounty                   TAXPKG_GEN.TCTaxMst;
       POOLocal                    TAXPKG_GEN.TLTaxMst;
       POACounty                   TAXPKG_GEN.TCTaxMst;
       POALocal                    TAXPKG_GEN.TLTaxMst;


       STState                     NUMBER := 0;
       SFState                     NUMBER := 0;
       POOState                    NUMBER := 0;
       POAState                    NUMBER := 0;
       StateCodeN                  NUMBER;
       UseStep                     BOOLEAN;
       UseNexpro                   BOOLEAN;
       UseProduct                  BOOLEAN;
       UseError                    BOOLEAN ;
       ZeroOvAmt                   BOOLEAN := TRUE;
       Sys_Date                    DATE;
       g_trx_id                    NUMBER;
   PROCEDURE NullParameters;

   FUNCTION  TAXFN_TAX010(OraParm   IN OUT NOCOPY TAXPKG_GEN.t_OraParm,
                          TxParm    IN OUT NOCOPY TAXPKG_GEN.TaxParm,
                          TSelParm  IN OUT NOCOPY CHAR,
                          JrParm    IN OUT NOCOPY TAXPKG_GEN.JurParm) RETURN  BOOLEAN;


   FUNCTION TAXFN_release_number RETURN VARCHAR2 ;

   FUNCTION  TAXFN910_ValidErr( GenCmplCd     IN CHAR
                               ) RETURN BOOLEAN  ;


 PROCEDURE TRANSLATE_JURIS_INFO(AllTaxChorizo  IN  VARCHAR2,
                                  CountryRate    OUT NUMBER,
                                  CountryAmnt    OUT NUMBER,
                                  StateRate      OUT NUMBER,
                                  StateAmnt      OUT NUMBER,
                                  CountyRate     OUT NUMBER,
                                  CountyAmnt     OUT NUMBER,
                                  CityRate       OUT NUMBER,
                                  CityAmnt       OUT NUMBER,
                                  DistrictRate   OUT NUMBER,
                                  DistrictAmnt   OUT NUMBER) ;

 PROCEDURE PrintOut(Message IN VARCHAR2);
 FUNCTION go_calculate( TxParm   IN OUT NOCOPY TAXPKG_GEN.TaxParm,
                        JrParm   IN OUT NOCOPY TAXPKG_GEN.JurParm) RETURN BOOLEAN;
                        
--DP forced calculation
  FUNCTION OD_force_legacy_tax(TxParm IN OUT NOCOPY TAXPKG_GEN.TaxParm,
                        JrParm IN OUT NOCOPY TAXPKG_GEN.JurParm,
                        TotalTax IN NUMBER) RETURN BOOLEAN;
    
END TAXPKG_10;
/

