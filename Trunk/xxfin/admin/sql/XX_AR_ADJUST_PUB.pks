REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=pls checkfile:~PROD:~PATH:~FILE
/*=======================================================================+
 |  Copyright (c) 1997 Oracle Corporation Redwood Shores, California, USA|
 |                          All rights reserved.                         |
 +=======================================================================+
 | FILENAME
 |      ARXPADJS.pls
 |
 | DESCRIPTION
 |      PL/SQL specification for package:  XX_AR_ADJUST_PUB
 |      This package creates, modifies, reverses and approves Adjustments
 |
 |
 | PUBLIC OBJECTS
 |	
 |
 | PUBLIC PROCEDURES
 |	
 |	debug
 |	
 | 
 | PUBLIC FUNCTIONS
 |	
 |
 | PRIVATE PROCEDURES
 |	
 | 
 | PRIVATE FUNCTIONS
 |	
 | 
 | KNOWN BUGS
 |
 | NOTES
 |
 | MODIFICATION HISTORY
 |    Vivek Halder 06-JUN-97  Created
 |    Saloni Shah  18-DEC-99  Modified for BOE/BR project
 |                              - Create_Adjusments to have 2 additional
 |                                parameters (p_chk_approval_limits , 
 |                                p_check_amount) 
 |
 |                              - Modify_Adjustments to have 1 additional 
 |                                parameter (p_chk_approval_limits)
 |
 |                              - Approve_Adjustments to have 1 additional 
 |                                parameter (p_chk_approval_limits)
 | 			
 |				- Reverse_Adjustments to have 3 additional
 | 				  parameters (p_chk_approval_limits, 
 |				  p_comments, p_new_adj_id)
 | 
 |    Satheesh Nambiar          - Added p_move_deferred_tax for BOE/BR.The
 |                                new parameter is used to detect whether
 |                                the deferred tax is moved as part of 
 |                                maturity_date event or as a part of activity 
 |                                on the BR (Bug 1290698)
 |    Satheesh Nambiar            Bug 1415964 - Modified the code to avoid
 |                                recelculating the acctd_amount when adjustment
 |                                is being reversed. Instead take the amounts
 |                                from old adjustment and reverse it.
 |                                Added p_called_from,old_adjust_id parameters
 |                                to create and reverse rountine.
 *=======================================================================*/
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE XX_AR_ADJUST_PUB AS
/* $Header: ARXPADJS.pls 120.5.12010000.2 2008/11/13 10:04:48 dgaurab ship $*/
/*#
* Adjustment API allows users to create, approve, update, and reverse  
* adjustments for invoices using simple calls to PL/SQL functions.     
* @rep:scope public 
* @rep:metalink 236938.1 See OracleMetaLink note 236938.1
* @rep:product AR
* @rep:lifecycle active
* @rep:displayname Adjustment API
* @rep:category BUSINESS_ENTITY AR_ADJUSTMENT  
*/

G_START_TIME	number;

/*#
 * Use this procedure to create adjustments to invoices.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Create Adjustment
 */

PROCEDURE Create_Adjustment (
          p_api_name		IN	varchar2,
          p_api_version		IN	number,
          p_init_msg_list	IN	varchar2 := FND_API.G_FALSE,
          p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
          p_validation_level    IN	number   := FND_API.G_VALID_LEVEL_FULL,
          p_msg_count		OUT NOCOPY  	number,
          p_msg_data		OUT NOCOPY	varchar2,
          p_return_status	OUT NOCOPY	varchar2,
          p_adj_rec		IN 	ar_adjustments%rowtype,
          p_chk_approval_limits IN      varchar2 := FND_API.G_TRUE,
          p_check_amount        IN      varchar2 := FND_API.G_TRUE,
          p_move_deferred_tax   IN      varchar2 DEFAULT 'Y',
          p_new_adjust_number	OUT NOCOPY	ar_adjustments.adjustment_number%type,
          p_new_adjust_id	OUT NOCOPY	ar_adjustments.adjustment_id%type,
          p_called_from         IN      varchar2 DEFAULT NULL, 
          p_old_adjust_id	IN	ar_adjustments.adjustment_id%type DEFAULT NULL,
          p_org_id	        IN	NUMBER DEFAULT NULL
           );

/*#
 * Use this procedure to update an adjustment.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Modify Adjustment 
 */ 

PROCEDURE Modify_Adjustment(
          p_api_name		IN	varchar2,
	  p_api_version		IN	number,
	  p_init_msg_list	IN	varchar2 := FND_API.G_FALSE,
	  p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
	  p_validation_level    IN	number   := FND_API.G_VALID_LEVEL_FULL,
          p_msg_count		OUT NOCOPY  	number,
	  p_msg_data		OUT NOCOPY	varchar2,
	  p_return_status	OUT NOCOPY	varchar2 ,
	  p_adj_rec		IN 	ar_adjustments%rowtype,
          p_chk_approval_limits IN      varchar2 := FND_API.G_TRUE,
          p_move_deferred_tax   IN      varchar2 DEFAULT 'Y',
	  p_old_adjust_id	IN	ar_adjustments.adjustment_id%type,
          p_org_id	        IN	NUMBER DEFAULT NULL
	   );

/*#
 * Use this procedure to reverse an adjustment.
 * @rep:scope public
 * @rep:lifecycle active
 * @rep:displayname Reverse Adjustment
 */

PROCEDURE Reverse_Adjustment(
          p_api_name		IN	varchar2,
          p_api_version		IN	number,
          p_init_msg_list	IN	varchar2 := FND_API.G_FALSE,
	  p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
	  p_validation_level   	IN	number   := FND_API.G_VALID_LEVEL_FULL,
	  p_msg_count		OUT NOCOPY  	number,
	  p_msg_data		OUT NOCOPY	varchar2,
	  p_return_status	OUT NOCOPY	varchar2,
	  p_old_adjust_id	IN	ar_adjustments.adjustment_id%type,
          p_reversal_gl_date	IN	date,
          p_reversal_date	IN	date,
	  p_comments            IN      ar_adjustments.comments%type,
          p_chk_approval_limits IN      varchar2 := FND_API.G_TRUE,
          p_move_deferred_tax   IN      varchar2 DEFAULT 'Y',
          p_new_adj_id          OUT NOCOPY     ar_adjustments.adjustment_id%type,
          p_called_from         IN      varchar2 DEFAULT NULL ,
          p_org_id	        IN	NUMBER DEFAULT NULL
	   );

/*#
 * Use this procedure to approve an adjustment.
 * @rep:scope public
 * @rep:lifecycle active 
 * @rep:displayname Approve Adjustment
 */

PROCEDURE Approve_Adjustment (
	  p_api_name		IN	varchar2,
	  p_api_version		IN	number,
	  p_init_msg_list	IN	varchar2 := FND_API.G_FALSE,
	  p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
	  p_validation_level    IN	number   := FND_API.G_VALID_LEVEL_FULL,
	  p_msg_count		OUT NOCOPY  	number,
	  p_msg_data		OUT NOCOPY	varchar2,
	  p_return_status	OUT NOCOPY	varchar2,
	  p_adj_rec		IN 	ar_adjustments%rowtype,
          p_chk_approval_limits IN      varchar2 := FND_API.G_TRUE,
          p_move_deferred_tax   IN      varchar2 DEFAULT 'Y',
	  p_old_adjust_id	IN	ar_adjustments.adjustment_id%type,
          p_org_id	        IN	NUMBER DEFAULT NULL
     	  );


-- Added for Line level Adjustment

TYPE llca_adj_trx_line_rec_type  IS RECORD (
      customer_trx_line_id         NUMBER DEFAULT NULL,
      line_amount                  NUMBER DEFAULT NULL,
      receivables_trx_id           NUMBER DEFAULT NULL
                                       );

TYPE llca_adj_trx_line_tbl_type IS TABLE OF llca_adj_trx_line_rec_type
        INDEX BY BINARY_INTEGER;


TYPE llca_adj_create_rec_type  IS RECORD (
      adjustment_number            NUMBER DEFAULT NULL,
      adjustment_id                NUMBER DEFAULT NULL,
      customer_trx_line_id         NUMBER DEFAULT NULL
                                       );

TYPE llca_adj_create_tbl_type IS TABLE OF llca_adj_create_rec_type
        INDEX BY BINARY_INTEGER;


PROCEDURE create_linelevel_adjustment (
p_api_name		IN	varchar2,
p_api_version		IN	number,
p_init_msg_list		IN	varchar2 := FND_API.G_FALSE,
p_commit_flag		IN	varchar2 := FND_API.G_FALSE,
p_validation_level     	IN	number := FND_API.G_VALID_LEVEL_FULL,
p_msg_count		OUT NOCOPY  	number,
p_msg_data		OUT NOCOPY	varchar2,
p_return_status		OUT NOCOPY	varchar2 ,
p_adj_rec		IN 	ar_adjustments%rowtype,
p_chk_approval_limits   IN      varchar2 := FND_API.G_TRUE,
p_llca_adj_trx_lines_tbl IN llca_adj_trx_line_tbl_type, 
p_check_amount          IN      varchar2 := FND_API.G_TRUE,
p_move_deferred_tax     IN      varchar2,
p_llca_adj_create_tbl_type OUT NOCOPY llca_adj_create_tbl_type,
p_called_from		IN	varchar2, 
p_old_adjust_id 	IN	ar_adjustments.adjustment_id%type,
p_org_id              IN      NUMBER DEFAULT NULL
);

-- Added for Line level Adjustment [End]


END XX_AR_ADJUST_PUB;

/
COMMIT;
EXIT;


