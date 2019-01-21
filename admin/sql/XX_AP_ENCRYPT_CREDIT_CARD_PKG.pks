CREATE OR REPLACE PACKAGE xx_ap_encrypt_credit_card_pkg
AS
    /*+=========================================================================+
    |   Office Depot - Project R12                                              |
    |   Office Depot/Consulting Organization                                    |
    +===========================================================================+
    |Name        : xx_ap_encrypt_credit_card_pkg                                |
    |RICE        : I2168                                                        |
    |Description : This package performs custom encryption on any new credit    |
    |              card account included in JP Morgan Files inbound files.      |
    |                                                                           |
    |              Here are the steps:                                          |
    |               1. Look for credit card account in file.                    |
    |               2. For each credit card account do the below.               |
    |               3. Get or create the credit card.                           |
    |               4. Get the credit card information                          |
    |               5  Check if credit card has been previously encrypted       |
    |                  using custom encryption.                                 |
    |               6. If not previously custom encrypted, encrypt it           |
    |               7. Update the credit card record with the custom encryption |
    |                  information.                                             |
    |               8. Submit seeded program to load and valid file             |
    |Change Record:                                                             |
    |==============                                                             |
    |Version  Date         Author                  Remarks                      |
    |=======  ===========  ======================  =============================|
    |  1.0    24-OCT-2013  Edson Morales            Initial Version.            |
    +==========================================================================*/

    /**********************************************************
    * Main program to be called from concurrent manager.
    *
    *   Steps
    *    1. Look for credit card account in file.
    *    2. For each credit card account do the below.
    *    3. Get or create the credit card.
    *    4. Get the credit card information.
    *    5  Check if credit card has been previously encrypted
    *                  using custom encryption.
    *    6. If not previously custom encrypted, encrypt it
    *    7. Update the credit card record with the custom encryption
    *                  information.
    *    8. Submit seeded program to load and valid file
    **********************************************************/
    PROCEDURE process_file(
        x_retcode                     OUT     NUMBER,
        x_errbuf                      OUT     VARCHAR2,
        p_card_program_id             IN      NUMBER,
        p_file_name                   IN      VARCHAR2,
        p_directory                   IN      VARCHAR2,
        p_file_target_node_path       IN      VARCHAR2,
        p_file_target_node_item_name  IN      VARCHAR2,
        p_all_or_nothing_flag         IN      VARCHAR2,
        p_submit_loader_prog          IN      VARCHAR2,
        p_debug_flag                  IN      VARCHAR2);

    /**********************************************************
    * Main program to be called from concurrent manager.
    *
    *   Steps
    *    1. Look for unencrypted employee credit cards
    *    2. For each credit card do the below.
    *    3. Get the credit card information.
    *    4  Encrypt it.
    *    5. Update the credit card record with the custom encryption
    *                  information.
    **********************************************************/
    PROCEDURE encrypt_employee_cards(
        x_retcode              OUT     NUMBER,
        x_errbuf               OUT     VARCHAR2,
        p_all_or_nothing_flag  IN      VARCHAR2,
        p_debug_flag           IN      VARCHAR2);
END xx_ap_encrypt_credit_card_pkg;
/