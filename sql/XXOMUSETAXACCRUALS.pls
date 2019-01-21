/*#################################################################
 *#TAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARETAXWARE#
 *#A                                                             T#
 *#X  Author:  Govind Jayanth                                    A#
 *#W  Company: Smart ERP Solutions, Inc                          X#
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
 *#     $Header: $Twev5ARParmbv2.0            March 30, 2007
 *#     Modification History 
 *#     5/29/2007    Govind      Created : Procedure Request to accrue 
 *#                              use tax for internal sales orders      
 *###############################################################
 *	 Source	File		  :-  XXOMUSETAXACCRUALS.pls 
 *	 ---> Office Depot <---
 *###############################################################
 */

 CREATE OR REPLACE PACKAGE XX_OM_USETAXACCRUAL_PKG AUTHID CURRENT_USER AS
/* Office Depot Custom */

Procedure Request
(ERRBUF OUT NOCOPY VARCHAR2,
 RETCODE OUT NOCOPY VARCHAR2,
 p_order_number_low   IN  NUMBER,
 p_order_number_high  IN  NUMBER,
 p_order_date_low   IN  varchar2,
 p_order_date_high  IN  varchar2
);

END XX_OM_USETAXACCRUAL_PKG;
/
