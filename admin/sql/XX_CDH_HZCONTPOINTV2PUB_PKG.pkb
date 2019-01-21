/*
 *  Copyright (c) 2001 Oracle Corporation Redwood Shores, California, USA
 *                          All rights reserved.
 *=======================================================================
 * FILE       ARH2CPSB.pls
 *
 * PACKAGE    hz_contact_point_v2pub
 *
 * DESCRIPTION
 *     This package contains public API for contact points.
 *
 * RELATED PACKAGES
 *
 * PUBLIC VARIABLES
 *
 * PUBLIC PROCEDURES
 *     create_contact_point (old)
 *     create_edi_contact_point
 *     create_eft_contact_point
 *     create_web_contact_point
 *     create_phone_contact_point
 *     create_email_contact_point
 *     create_telex_contact_point
 *     update_contact_point (old)
 *     update_edi_contact_point
 *     update_eft_contact_point
 *     update_web_contact_point
 *     update_phone_contact_point
 *     update_email_contact_point
 *     update_telex_contact_point
 *     get_contact_point_rec (old)
 *     get_edi_contact_point
 *     get_eft_contact_point
 *     get_web_contact_point
 *     get_phone_contact_point
 *     get_email_contact_point
 *     get_telex_contact_point
 *     phone_format
 *
 * PUBLIC FUNCTIONS
 *
 * NOTES
 *
 * MODIFICATION HISTORY
 *
 *   07-23-2001    Jianying Huang      o Created.
 *   08-07-2001    Jianying Huang      o Bug 1934796: Reset x_return_status after
 *                                       call phone_format if content_source_type
 *                                       is not 'USER_ENTERED'.
 *   08-15-2001    Jianying Huang      o Bug 1940146: Commented BES callout.
 *   19-NOV-2001   Joe del Callar      o Bug 2116225: Consolidated bank support
 *                                       added.
 *   04-DEC-2001   Joe del Callar      o Bug 2136283: Added support for
 *                                       enhanced backward compatibility.
 *   02-05-2002    Jyoti Pandey        o Bug: 2223636 Modified the parsing and formatting
 *                                       logic for Phone Normalization and Parsing
 *                                       project in version 115.9
 *   04-FEB-2001   Joe del Callar      o Bug 2211876: Fixed issue with error
 *                                       status and message data getting set
 *                                       incorrectly in update and create contact
 *                                       point APIs.
 *   14-FEB-02    Jyoti Pandey         o Bug: 2223636 Changed logic for Phone country_code
 *                                       being passed to phone_format
 *   29-APR-02    Rashmi Goyal         o Bug 2197181: Added new column
 *                                       actual_content_source.
 *   03-JUL-02    Jianying Huang       o Bug 2444678: Removed caching.
 *   04-SEP-02    Jyoti Pandey         o Bug 2486394 Data Sharing and security
 *   19-AUG-03    Ramesh Ch            o Bug 1695595.Changed the signature of
 *                                       do_denormalize_contact_point procdure
 *                                       and logic to update denormalized primary phone number
 *                                       columns.Changed the code in do_create_contact_point
 *                                       and do_update_contact_point to call
 *                                       do_denormalize_contact_point procdure.
 *   26-AUG-03   Ramesh Ch             o Bug 3113908.Modified the
 *                                       do_denormalize_contact_point procedure
 *                                       to update the renamed primary phone number
 *                                       columns(prefixed with "primary_").
 *   30-SEP-03   Rajib Ranjan Borah    o Bug Number 2914238.Updated the who columns
 *                                       in the do_unset_prim_contact_point procedure.
 *   28-OCT-03  Ramesh Ch              o Bug#2914238. Updated the who columns in
 *                                       do_unset_primary_by_purpose and also removed
 *                                       created_by and creation_date columns during update
 *                                       in do_unset_prim_contact_point procedure.
 *   13-DEC-2003    Ramesh Ch.         o Commented out the g_debug,enable_debug,disable_debug &
 *                                       modified calls to hz_utility_pub's
 *                                       debug & debug_return_messages as part of
 *                                       Common Logging Infrastructure uptake.
 *   05-MAR-2004    Ramesh Ch.         o Bug No:3131865.Moved the denormalize contact point
 *                                       logic after call to hz_contact_points_pkg.insert_row.
 *   29-Mar-2004    Ramesh Ch.         o Bug No: 2771835. Modified the code to
 *                                       make address text column in
 *                                       hz_cust_acct_sites_all as dirty.
 *   06-Jul-2004    Rajib Ranjan Borah o Bug 3711740.In update_contact_point_main, if the
 *                                       user passed value(s) for phone_area_code /
 *                                       phone_country_code is/are null, then do not assign
 *                                       the database value before calling hz_timezone_pub.
 *                                       get_phone_timezone_id.
 *                                     o In do_update_contact_point, set phone_number and
 *                                       phone_area_code to fnd_api.g_miss_char if
 *                                       phone_format returns null for these columns.
 *   06-JUL-2004    Rajib Ranjan Borah o Bug 3520843. In do_create_contact_point,
 *                                       raw_phone_number will not be
 *                                       re-created if passed initially.
 *   06-AUG-2004    Jianying Huang     o Bug 3818648: check dss profile before call test_instance
 *   01-SEP-2004    Jianying Huang     o Bug 3867562: check dss only in party context
 *   02-SEP-2004    Jianying Huang     o Bug 3835601: replaced the dss message with a more user
 *                                       friendly message.
 *   01-03-2005     Rajib Ranjan Borah o SSM SST Integration and Extension.
 *                                       For non-profile entities, the concept of select 
 *                                       /de-select data-sources is obsoleted.
 */

REM Added for ARU db drv auto generation
REM dbdrv: sql ~PROD ~PATH ~FILE none none none package &phase=plb \
REM dbdrv: checkfile:~PROD:~PATH:~FILE

SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY hz_contact_point_v2pub AS
/*Original Header (Modified Version): ARH2CPSB.pls 115.46 2006/12/13 00:06:04 nsinghai ship $ */

  --------------------------------------
  -- declaration of private global varibles
  --------------------------------------

  g_debug_count                        NUMBER := 0;
  --g_debug                              BOOLEAN := FALSE;

  -- Bug 2197181: added for mix-n-match project.

  g_cpt_mixnmatch_enabled              VARCHAR2(1);
  g_cpt_selected_datasources           VARCHAR2(255);
  g_cpt_is_datasource_selected         VARCHAR2(1) := 'N';
  g_cpt_entity_attr_id                 NUMBER;

  --------------------------------------
  -- declaration of private procedures and functions
  --------------------------------------

  /*PROCEDURE enable_debug;

  PROCEDURE disable_debug;
  */


  PROCEDURE do_create_contact_point (
    p_contact_point_rec                IN OUT NOCOPY contact_point_rec_type,
    p_edi_rec                          IN OUT NOCOPY edi_rec_type,
    p_eft_rec                          IN OUT NOCOPY eft_rec_type,
    p_email_rec                        IN OUT NOCOPY email_rec_type,
    p_phone_rec                        IN OUT NOCOPY phone_rec_type,
    p_telex_rec                        IN OUT NOCOPY telex_rec_type,
    p_web_rec                          IN OUT NOCOPY web_rec_type,
    x_contact_point_id                 OUT NOCOPY    NUMBER,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  );

  PROCEDURE do_update_contact_point (
    p_contact_point_rec                IN OUT NOCOPY contact_point_rec_type,
    p_edi_rec                          IN OUT NOCOPY edi_rec_type,
    p_eft_rec                          IN OUT NOCOPY eft_rec_type,
    p_email_rec                        IN OUT NOCOPY email_rec_type,
    p_phone_rec                        IN OUT NOCOPY phone_rec_type,
    p_telex_rec                        IN OUT NOCOPY telex_rec_type,
    p_web_rec                          IN OUT NOCOPY web_rec_type,
    p_object_version_number            IN OUT NOCOPY NUMBER,
    x_return_status                    IN OUT NOCOPY VARCHAR2
  );


  PROCEDURE do_denormalize_contact_point (
    p_party_id                         IN     NUMBER,
    p_contact_point_type               IN     VARCHAR2,
    p_url                              IN     VARCHAR2,
    p_email_address                    IN     VARCHAR2,
    p_phone_contact_pt_id              IN     NUMBER,
    p_phone_purpose                    IN     VARCHAR2,
    p_phone_line_type                  IN     VARCHAR2,
    p_phone_country_code               IN     VARCHAR2,
    p_phone_area_code                  IN     VARCHAR2,
    p_phone_number                     IN     VARCHAR2,
    p_phone_extension                  IN     VARCHAR2
  );

  PROCEDURE do_unset_prim_contact_point (
    p_owner_table_name                 IN     VARCHAR2,
    p_owner_table_id                   IN     NUMBER,
    p_contact_point_type               IN     VARCHAR2,
    p_contact_point_id                 IN     NUMBER
  );

  PROCEDURE do_unset_primary_by_purpose (
    p_owner_table_name                 IN     VARCHAR2,
    p_owner_table_id                   IN     NUMBER,
    p_contact_point_type               IN     VARCHAR2,
    p_contact_point_purpose            IN     VARCHAR2,
    p_contact_point_id                 IN     NUMBER
  );

  FUNCTION filter_phone_number (
    p_phone_number                     IN     VARCHAR2,
    p_isformat                         IN     NUMBER := 0
  ) RETURN VARCHAR2;

  PROCEDURE get_phone_format (
    p_raw_phone_number                 IN     VARCHAR2 := fnd_api.g_miss_char,
    p_territory_code                   IN     VARCHAR2 := fnd_api.g_miss_char,
    p_area_code                        IN     VARCHAR2,
    x_phone_country_code               OUT NOCOPY    VARCHAR2,
    x_phone_format_style               OUT NOCOPY    VARCHAR2,
    x_area_code_size                   OUT NOCOPY    VARCHAR2,
    x_include_country_code             OUT NOCOPY    BOOLEAN,
    x_msg                              OUT NOCOPY    VARCHAR2
  );

  PROCEDURE translate_raw_phone_number (
    p_raw_phone_number                 IN     VARCHAR2 := fnd_api.g_miss_char,
    p_phone_format_style               IN     VARCHAR2 := fnd_api.g_miss_char,
    p_area_code_size                   IN     NUMBER := 0,
    x_formatted_phone_number           OUT NOCOPY    VARCHAR2,
    x_phone_area_code                  OUT NOCOPY    VARCHAR2,
    x_phone_number                     OUT NOCOPY    VARCHAR2
  );

  PROCEDURE update_contact_point_search(
       p_cp_rec        IN HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE,
       p_old_phone_rec IN HZ_CONTACT_POINT_V2PUB.phone_rec_type,
       p_new_phone_rec IN HZ_CONTACT_POINT_V2PUB.phone_rec_type,
       p_old_email_rec IN HZ_CONTACT_POINT_V2PUB.email_rec_type,
       p_new_email_rec IN HZ_CONTACT_POINT_V2PUB.email_rec_type
   );
  FUNCTION isModified(p_old_value IN VARCHAR2,
                      p_new_value IN VARCHAR2
                      ) RETURN BOOLEAN;
  --------------------------------------
  -- private procedures and functions
  --------------------------------------

  --
  -- PRIVATE PROCEDURE enable_debug
  --
  -- DESCRIPTION
  --     Turn on debug mode.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     HZ_UTILITY_V2PUB.enable_debug
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --
  --

  /*PROCEDURE enable_debug IS
  BEGIN
    g_debug_count := g_debug_count + 1;

    IF g_debug_count = 1 THEN
      IF fnd_profile.value('HZ_API_FILE_DEBUG_ON') = 'Y' OR
         fnd_profile.value('HZ_API_DBMS_DEBUG_ON') = 'Y'
      THEN
        hz_utility_v2pub.enable_debug;
        g_debug := TRUE;
      END IF;
    END IF;
  END enable_debug;
  */

  --
  -- PRIVATE PROCEDURE disable_debug
  --
  -- DESCRIPTION
  --     Turn off debug mode.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     HZ_UTILITY_V2PUB.disable_debug
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --
  --

  /*PROCEDURE disable_debug IS
  BEGIN
    IF g_debug THEN
      g_debug_count := g_debug_count - 1;

      IF g_debug_count = 0 THEN
        hz_utility_v2pub.disable_debug;
        g_debug := FALSE;
      END IF;
    END IF;
  END disable_debug;
  */


  --
  -- PRIVATE PROCEDURE do_create_contact_point
  --
  -- DESCRIPTION
  --     Private procedure to create contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     hz_registry_validate_v2pub.validate_contact_point
  --     hz_registry_validate_v2pub.validate_edi_contact_point
  --     hz_registry_validate_v2pub.validate_eft_contact_point
  --     hz_registry_validate_v2pub.validate_web_contact_point
  --     hz_registry_validate_v2pub.validate_phone_contact_point
  --     hz_registry_validate_v2pub.validate_telex_contact_point
  --     hz_registry_validate_v2pub.validate_email_contact_point
  --     hz_contact_points_pkg.insert_row
  --     hz_phone_number_pkg.transpose
  --
  -- ARGUMENTS
  --   IN/OUT:
  --     p_contact_point_rec  Contact point record.
  --     p_edi_rec            EDI record.
  --     p_email_rec          Email record.
  --     p_phone_rec          Phone record.
  --     p_telex_rec          Telex record.
  --     p_web_rec            Web record.
  --     x_return_status      Return status after the call. The status can
  --                          be FND_API.G_RET_STS_SUCCESS (success),
  --                          FND_API.G_RET_STS_ERROR (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   15-NOV-2001   Joe del Callar      Bug 2116225: Modified for consolidated
  --                                     bank support (EFT record support).
  --   05-DEC-2001   Joe del Callar      Bug 2136283: Modified to use new
  --                                     validation procedures.
  --   06-JUL-2004   Rajib Ranjan Borah  Bug 3520843.raw_phone_number will not be
  --                                     re-created if passed initially.
  --   01-03-2005    Rajib Ranjan Borah  SSM SST Integration and Extension.   
  --                                     For non-profile entities, the concept of
  --                                     select/de-select data-sources is obsoleted.

  PROCEDURE do_create_contact_point (
    p_contact_point_rec         IN OUT NOCOPY contact_point_rec_type,
    p_edi_rec                   IN OUT NOCOPY edi_rec_type,
    p_eft_rec                   IN OUT NOCOPY eft_rec_type,
    p_email_rec                 IN OUT NOCOPY email_rec_type,
    p_phone_rec                 IN OUT NOCOPY phone_rec_type,
    p_telex_rec                 IN OUT NOCOPY telex_rec_type,
    p_web_rec                   IN OUT NOCOPY web_rec_type,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             IN OUT NOCOPY VARCHAR2
  ) IS
    l_debug_prefix              VARCHAR2(30) := ''; -- do_create_contact_point

    l_dummy                     VARCHAR2(1);
    l_return_status             VARCHAR2(1);
    l_message_count             NUMBER;
    l_msg_count                 NUMBER;
    l_msg_data                  VARCHAR2(2000);

    l_formatted_phone_number    VARCHAR2(100);
    l_country_code              hz_locations.country%TYPE;
    l_transposed_phone_number   hz_contact_points.transposed_phone_number%TYPE;

    l_edi_rec                   edi_rec_type;
    l_email_rec                 email_rec_type;
    l_phone_rec                 phone_rec_type;
    l_telex_rec                 telex_rec_type;
    l_web_rec                   web_rec_type;
    l_eft_rec                   eft_rec_type;
    l_orig_sys_reference_rec  HZ_ORIG_SYSTEM_REF_PUB.ORIG_SYS_REFERENCE_REC_TYPE;

    l_phone_line_type           VARCHAR2(30);
    l_phone_country_code        VARCHAR2(10);
    l_phone_area_code           VARCHAR2(10);
    l_phone_number              VARCHAR2(40);
    l_phone_extension           VARCHAR2(20);
    l_contact_point_purpose     VARCHAR2(30);

    -- Bug 2117973: added following cursors for retrofit to conform to
    -- Applications PL/SQL standards.

    CURSOR c_country (p_site_id IN NUMBER) IS
      SELECT country
      FROM   hz_locations
      WHERE  location_id = (SELECT location_id
                            FROM   hz_party_sites
                            WHERE  party_site_id = p_site_id);

    -- Bug 2197181: added for mix-n-match project: the contact point
    -- must be visible.
    
    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
    -- There is no need to check if the data-source is selected.

    CURSOR c_cp (p_owner_table_name   IN VARCHAR2,
                 p_owner_table_id     IN NUMBER,
                 p_contact_point_type IN VARCHAR2) IS
      SELECT 'Y'
      FROM   hz_contact_points
      WHERE  owner_table_name = p_owner_table_name
      AND owner_table_id = p_owner_table_id
      AND contact_point_type = p_contact_point_type
/*      AND HZ_MIXNM_UTILITY.isDataSourceSelected (
            g_cpt_selected_datasources, actual_content_source ) = 'Y'*/
      AND status = 'A'
      AND rownum = 1;

  BEGIN
    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_contact_point_rec.contact_point_type = 'EDI' THEN
      l_edi_rec := p_edi_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_edi_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_edi_rec               => l_edi_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    ELSIF p_contact_point_rec.contact_point_type = 'EFT' THEN
      l_eft_rec := p_eft_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_eft_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_eft_rec               => l_eft_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    ELSIF p_contact_point_rec.contact_point_type = 'EMAIL' THEN
      l_email_rec := p_email_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_email_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_email_rec             => l_email_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    ELSIF p_contact_point_rec.contact_point_type = 'PHONE' THEN
      l_phone_rec := p_phone_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_phone_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_phone_rec             => l_phone_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    ELSIF p_contact_point_rec.contact_point_type = 'TLX' THEN
      l_telex_rec := p_telex_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_telex_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_telex_rec             => l_telex_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    ELSIF p_contact_point_rec.contact_point_type = 'WEB' THEN
      l_web_rec := p_web_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_web_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_web_rec               => l_web_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    ELSE
      l_edi_rec := p_edi_rec;
      l_email_rec := p_email_rec;
      l_phone_rec := p_phone_rec;
      l_telex_rec := p_telex_rec;
      l_web_rec := p_web_rec;
      l_eft_rec := p_eft_rec;

      -- Validate the contact point record - call the old routine and the
      -- EFT validation routine.
      hz_registry_validate_v2pub.validate_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_edi_rec               => l_edi_rec,
        p_email_rec             => l_email_rec,
        p_phone_rec             => l_phone_rec,
        p_telex_rec             => l_telex_rec,
        p_web_rec               => l_web_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE fnd_api.g_exc_error;
      END IF;

      hz_registry_validate_v2pub.validate_eft_contact_point (
        p_create_update_flag    => 'C',
        p_contact_point_rec     => p_contact_point_rec,
        p_eft_rec               => l_eft_rec,
        p_rowid                 => NULL,
        x_return_status         => x_return_status);
    END IF;

    -- Raise an error if any of the validations failed.
    IF x_return_status <> fnd_api.g_ret_sts_success THEN
      RAISE fnd_api.g_exc_error;
    END IF;

    -- If raw_phone_number is passed in, call procedure phone_format.
    -- either raw_phone_number or phone_number should be passed in
    -- but can not be both. If raw_phone_number does not have a value,
    -- it will be set by phone_number and phone_area_code.

    -- Debug info.
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'contact_point_type = ' || p_contact_point_rec.contact_point_type,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    --To get territory code to pass to phone_format, first check if country code
    --was passed in else get it from hz_locations for owner_table_name HZ_PARTY_SITES

    IF p_contact_point_rec.contact_point_type = 'PHONE' THEN
      IF l_phone_rec.raw_phone_number IS NOT NULL AND
         l_phone_rec.raw_phone_number <> fnd_api.g_miss_char
      THEN
         IF l_phone_rec.phone_country_code is not null AND
            l_phone_rec.phone_country_code <> fnd_api.g_miss_char
         THEN
            BEGIN
              select territory_code into l_country_code
              from hz_phone_country_codes
              where phone_country_code = l_phone_rec.phone_country_code
              and rownum = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
               NULL;
            END;
         ELSIF p_contact_point_rec.owner_table_name = 'HZ_PARTY_SITES' AND
           (l_phone_rec.phone_country_code IS NULL OR
            l_phone_rec.phone_country_code = fnd_api.g_miss_char)
         THEN
           -- Bug 2117973: modified to conform to Applications PL/SQL standards.
           OPEN c_country(p_contact_point_rec.owner_table_id);
           FETCH c_country INTO l_country_code;
           IF c_country%NOTFOUND THEN
             CLOSE c_country;
             RAISE NO_DATA_FOUND;
           END IF;
           CLOSE c_country;
         ELSE
           l_country_code := NULL;
         END IF;

         l_message_count := fnd_msg_pub.count_msg();

         -- Since phone_format cannot format raw_phone_number and phone_number
         -- at same time, the input value of phone_number and phone_area_code
         -- should be NULL or G_MISS before the call.

         phone_format (
           p_raw_phone_number                => l_phone_rec.raw_phone_number,
           p_territory_code                  => l_country_code,
           x_formatted_phone_number          => l_formatted_phone_number,
           x_phone_country_code              => l_phone_rec.phone_country_code,
           x_phone_area_code                 => l_phone_rec.phone_area_code,
           x_phone_number                    => l_phone_rec.phone_number,
           x_return_status                   => x_return_status,
           x_msg_count                       => l_msg_count,
           x_msg_data                        => l_msg_data);

         -- Raise exception only if content_source_type = G_MISS_CONTENT_SOURCE_TYPE.
         -- For other sources, we do not want to error out, but simply store the
         -- Raw Phone Number.

         -- Bug 2197181 : content_source_type is obsolete and replaced by
         -- actual_content_source

         IF x_return_status <> fnd_api.g_ret_sts_success THEN
           IF p_contact_point_rec.actual_content_source = g_miss_content_source_type
           THEN
             IF x_return_status = fnd_api.g_ret_sts_error THEN
               RAISE fnd_api.g_exc_error;
             ELSE
               RAISE fnd_api.g_exc_unexpected_error;
             END IF;
           ELSE
             FOR i IN 1..(l_msg_count - l_message_count) LOOP
               fnd_msg_pub.delete_msg(l_msg_count - l_message_count + 1 - i);
             END LOOP;
             x_return_status := fnd_api.g_ret_sts_success;
           END IF;
         END IF;

    --  END IF; Bug 3520843
       ELSE
          -- raw_phone_number must always have value.
          IF l_phone_rec.phone_area_code IS NULL OR
             l_phone_rec.phone_area_code = fnd_api.g_miss_char
          THEN
             l_phone_rec.raw_phone_number := l_phone_rec.phone_number;
          ELSE
             l_phone_rec.raw_phone_number := l_phone_rec.phone_area_code || '-' ||
                                        l_phone_rec.phone_number;
          END IF;
       END IF;

      -- Debug info.
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'phone_number = ' || l_phone_rec.phone_number || ' ' ||
          'raw_phone_number = ' || l_phone_rec.raw_phone_number,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
     END IF;

      -- Populate transposed_phone_number
      IF l_phone_rec.phone_country_code IS NOT NULL AND
         l_phone_rec.phone_country_code <> fnd_api.g_miss_char
      THEN
        l_transposed_phone_number := l_phone_rec.phone_country_code;
      END IF;

      IF l_phone_rec.phone_area_code IS NOT NULL AND
         l_phone_rec.phone_area_code <> fnd_api.g_miss_char
      THEN
        l_transposed_phone_number := l_transposed_phone_number ||
                                     l_phone_rec.phone_area_code;
      END IF;

      -- phone_number is mandatory
      l_transposed_phone_number := hz_phone_number_pkg.transpose(
        l_transposed_phone_number || l_phone_rec.phone_number);

      -- Debug info.
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'transposed_phone_number = ' || l_transposed_phone_number,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
      END IF;
    END IF;

    -- If this is the first active contact point for the combination of
    -- owner_table_name, owner_table_id, contact_point_type, we need to
    -- mark it as primary no matter the value of primary_flag,
    -- If primary_flag = 'Y', we need to unmark the previous primary.
    -- Please note, if status is NULL or MISSING, we treat it as 'A'
    -- and in validation part, we already checked that primary_flag = 'Y'
    -- and status = 'I' can not both be set.

    -- Bug 2197181: added for mix-n-match project: the primary flag
    -- can be set to 'Y' only if the contact point will be visible. If
    -- it is not visible, the flag must be reset to 'N'.

    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data sources is obsoleted. 
    -- There is no need to check if the data-source is selected.

    IF p_contact_point_rec.status IS NULL OR
       p_contact_point_rec.status = fnd_api.g_miss_char OR
       p_contact_point_rec.status = 'A'
    THEN
      IF p_contact_point_rec.primary_flag = 'Y' THEN
        -- Bug 2197181: added for mix-n-match project
     -- IF g_cpt_is_datasource_selected = 'Y' THEN
          -- Unmark previous primary contact point.
          do_unset_prim_contact_point (p_contact_point_rec.owner_table_name,
                                       p_contact_point_rec.owner_table_id,
                                       p_contact_point_rec.contact_point_type,
                                       p_contact_point_rec.contact_point_id);
     -- ELSE
     --   p_contact_point_rec.primary_flag := 'N';
     -- END IF;
      ELSE
        -- Bug 2117973: modified to conform to Applications PL/SQL standards.
        OPEN c_cp (p_contact_point_rec.owner_table_name,
                    p_contact_point_rec.owner_table_id,
                    p_contact_point_rec.contact_point_type);
        FETCH c_cp INTO l_dummy;

        -- SSM SST Integration and Extension
   -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
   -- There is no need to check if the data-source is selected.

        IF c_cp%NOTFOUND /*AND
           -- Bug 2197181: added for mix-n-match project
           g_cpt_is_datasource_selected = 'Y'*/
        THEN
          -- First active and visible contact point per type for this entity
          p_contact_point_rec.primary_flag := 'Y';
        ELSE
          p_contact_point_rec.primary_flag := 'N';
        END IF;
        CLOSE c_cp;
      END IF;


    END IF;

    -- There is only one primary per purpose contact point exist for
    -- the combination of owner_table_name, owner_table_id, contact_point_type
    -- and contact_point_purpose. If primary_by_purpose is set to 'Y',
    -- we need to unset the previous primary per purpose contact point to
    -- non-primary. Since setting primary_by_purpose is only making
    -- sense when contact_point_purpose has some value, we ignore
    -- the primary_by_purpose (setting it to 'N') if contact_point_purpose
    -- is NULL.

    -- Bug 2197181: added for mix-n-match project: the primary by purpose
    -- flag can be set to 'Y' only if the contact point will be visible.
    -- If it is not visible, the flag must be reset to 'N'.

    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data sources is obsoleted.
    -- There is no need to check if the data-source is selected.

    IF p_contact_point_rec.contact_point_purpose IS NOT NULL AND
       p_contact_point_rec.contact_point_purpose <> fnd_api.g_miss_char
    THEN
      IF p_contact_point_rec.primary_by_purpose = 'Y' THEN
        -- Bug 2197181: added for mix-n-match project
     -- IF g_cpt_is_datasource_selected = 'Y' THEN
          do_unset_primary_by_purpose (p_contact_point_rec.owner_table_name,
                                       p_contact_point_rec.owner_table_id,
                                       p_contact_point_rec.contact_point_type,
                                       p_contact_point_rec.contact_point_purpose,
                                       p_contact_point_rec.contact_point_id);
     -- ELSE
     --     p_contact_point_rec.primary_by_purpose := 'N';
     -- END IF;
      END IF;
    ELSE
      p_contact_point_rec.primary_by_purpose := 'N';
    END IF;

    if l_phone_rec.timezone_id is null or
           l_phone_rec.timezone_id = fnd_api.g_miss_num
    then

        if l_phone_rec.phone_country_code IS NOT NULL AND
        l_phone_rec.phone_country_code <> fnd_api.g_miss_char
        then
                l_message_count := fnd_msg_pub.count_msg();
                hz_timezone_pub.get_phone_timezone_id(
                        p_api_version => 1.0,
                        p_init_msg_list => FND_API.G_FALSE,
                        p_phone_country_code => l_phone_rec.phone_country_code,
                        p_area_code => l_phone_rec.phone_area_code,
                        p_phone_prefix => null,
                        p_country_code => null,-- don't need to pass in this
                        x_timezone_id => l_phone_rec.timezone_id,
                        x_return_status => l_return_status ,
                        x_msg_count =>l_msg_count ,
                        x_msg_data => l_msg_data);
                        if l_return_status <> fnd_api.g_ret_sts_success
                        then  -- we don't raise error
                                l_phone_rec.timezone_id := null;
                                FOR i IN 1..(l_msg_count - l_message_count) LOOP
                                    fnd_msg_pub.delete_msg(l_msg_count - l_message_count + 1 - i);
                                END LOOP;
                                l_return_status := FND_API.G_RET_STS_SUCCESS;
                        end if;
        end if;
    end if;


    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'HZ_CONTACT_POINTS_PKG.Insert_Row (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call table-handler.
    hz_contact_points_pkg.insert_row (
      x_contact_point_id                => p_contact_point_rec.contact_point_id,
      x_contact_point_type              => p_contact_point_rec.contact_point_type,
      x_status                          => p_contact_point_rec.status,
      x_owner_table_name                => p_contact_point_rec.owner_table_name,
      x_owner_table_id                  => p_contact_point_rec.owner_table_id,
      x_primary_flag                    => p_contact_point_rec.primary_flag,
      x_orig_system_reference           => p_contact_point_rec.orig_system_reference,
      x_attribute_category              => p_contact_point_rec.attribute_category,
      x_attribute1                      => p_contact_point_rec.attribute1,
      x_attribute2                      => p_contact_point_rec.attribute2,
      x_attribute3                      => p_contact_point_rec.attribute3,
      x_attribute4                      => p_contact_point_rec.attribute4,
      x_attribute5                      => p_contact_point_rec.attribute5,
      x_attribute6                      => p_contact_point_rec.attribute6,
      x_attribute7                      => p_contact_point_rec.attribute7,
      x_attribute8                      => p_contact_point_rec.attribute8,
      x_attribute9                      => p_contact_point_rec.attribute9,
      x_attribute10                     => p_contact_point_rec.attribute10,
      x_attribute11                     => p_contact_point_rec.attribute11,
      x_attribute12                     => p_contact_point_rec.attribute12,
      x_attribute13                     => p_contact_point_rec.attribute13,
      x_attribute14                     => p_contact_point_rec.attribute14,
      x_attribute15                     => p_contact_point_rec.attribute15,
      x_attribute16                     => p_contact_point_rec.attribute16,
      x_attribute17                     => p_contact_point_rec.attribute17,
      x_attribute18                     => p_contact_point_rec.attribute18,
      x_attribute19                     => p_contact_point_rec.attribute19,
      x_attribute20                     => p_contact_point_rec.attribute20,
      x_edi_transaction_handling        => l_edi_rec.edi_transaction_handling,
      x_edi_id_number                   => l_edi_rec.edi_id_number,
      x_edi_payment_method              => l_edi_rec.edi_payment_method,
      x_edi_payment_format              => l_edi_rec.edi_payment_format,
      x_edi_remittance_method           => l_edi_rec.edi_remittance_method,
      x_edi_remittance_instruction      => l_edi_rec.edi_remittance_instruction,
      x_edi_tp_header_id                => l_edi_rec.edi_tp_header_id,
      x_edi_ece_tp_location_code        => l_edi_rec.edi_ece_tp_location_code,
      x_eft_transmission_program_id     => l_eft_rec.eft_transmission_program_id,
      x_eft_printing_program_id         => l_eft_rec.eft_printing_program_id,
      x_eft_user_number                 => l_eft_rec.eft_user_number,
      x_eft_swift_code                  => l_eft_rec.eft_swift_code,
      x_email_format                    => l_email_rec.email_format,
      x_email_address                   => l_email_rec.email_address,
      x_phone_calling_calendar          => l_phone_rec.phone_calling_calendar,
      x_last_contact_dt_time            => l_phone_rec.last_contact_dt_time,
      x_timezone_id                     => l_phone_rec.timezone_id,
      x_phone_area_code                 => l_phone_rec.phone_area_code,
      x_phone_country_code              => l_phone_rec.phone_country_code,
      x_phone_number                    => l_phone_rec.phone_number,
      x_phone_extension                 => l_phone_rec.phone_extension,
      x_phone_line_type                 => l_phone_rec.phone_line_type,
      x_telex_number                    => l_telex_rec.telex_number,
      x_web_type                        => l_web_rec.web_type,
      x_url                             => l_web_rec.url,
      x_content_source_type             => p_contact_point_rec.content_source_type,
      x_raw_phone_number                => l_phone_rec.raw_phone_number,
      x_object_version_number           => 1,
      x_contact_point_purpose           => p_contact_point_rec.contact_point_purpose,
      x_primary_by_purpose              => p_contact_point_rec.primary_by_purpose,
      x_created_by_module               => p_contact_point_rec.created_by_module,
      x_application_id                  => p_contact_point_rec.application_id,
      x_transposed_phone_number         => l_transposed_phone_number,
      x_actual_content_source           => p_contact_point_rec.actual_content_source
   );

    x_contact_point_id := p_contact_point_rec.contact_point_id;

---Bug No: 3131865
     -- De-normalize primary contact point to HZ_PARTIES.
      -- url is mandatory if contact_point_type = 'WEB'.
      -- email_address is mandatory if contact_point_type = 'EMAIL'.

      -- Debug info.
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'primary_flag = ' || p_contact_point_rec.primary_flag || ' ' ||
                                          'owner_table_name = '||p_contact_point_rec.owner_table_name||' '||
                                          'contact_point_type = '||p_contact_point_rec.contact_point_type||' '||
                                          'actual_content_source = ' || p_contact_point_rec.actual_content_source,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
      END IF;

      -- Bug 2197181: commented out NOCOPY the data source checking. We will denormalize
      -- to hz_parties as long as it's a primary contact point regardless of data
      -- source.
    IF p_contact_point_rec.status IS NULL OR
       p_contact_point_rec.status = fnd_api.g_miss_char OR
       p_contact_point_rec.status = 'A'
    THEN
      IF p_contact_point_rec.primary_flag = 'Y' AND
         p_contact_point_rec.owner_table_name = 'HZ_PARTIES' AND
         (p_contact_point_rec.contact_point_type IN ('WEB','EMAIL','PHONE'))
         /* AND
         (p_contact_point_rec.content_source_type IS NULL OR
           p_contact_point_rec.content_source_type = fnd_api.g_miss_char OR
           p_contact_point_rec.content_source_type =
             hz_party_v2pub.g_miss_content_source_type)
         */
      THEN
        IF l_phone_rec.phone_line_type = fnd_api.g_miss_char then
           l_phone_line_type := NULL;
        ELSE
           l_phone_line_type := l_phone_rec.phone_line_type;
        END IF;
        IF l_phone_rec.phone_country_code = fnd_api.g_miss_char then
           l_phone_country_code := NULL;
        ELSE
           l_phone_country_code := l_phone_rec.phone_country_code;
        END IF;
        IF l_phone_rec.phone_area_code = fnd_api.g_miss_char then
           l_phone_area_code := NULL;
        ELSE
           l_phone_area_code := l_phone_rec.phone_area_code;
        END IF;
        IF l_phone_rec.phone_number = fnd_api.g_miss_char then
           l_phone_number := NULL;
        ELSE
           l_phone_number := l_phone_rec.phone_number;
        END IF;
        IF l_phone_rec.phone_extension = fnd_api.g_miss_char then
           l_phone_extension := NULL;
        ELSE
           l_phone_extension := l_phone_rec.phone_extension;
        END IF;
        IF p_contact_point_rec.contact_point_purpose = fnd_api.g_miss_char then
           l_contact_point_purpose := NULL;
        ELSE
           l_contact_point_purpose := p_contact_point_rec.contact_point_purpose;
        END IF;


        do_denormalize_contact_point (p_contact_point_rec.owner_table_id,
                                      p_contact_point_rec.contact_point_type,
                                      l_web_rec.url,
                                      l_email_rec.email_address,
                                      p_contact_point_rec.contact_point_id,
                                      l_contact_point_purpose,
                                      l_phone_line_type,
                                      l_phone_country_code,
                                      l_phone_area_code,
                                      l_phone_number,
                                      l_phone_extension
                                      );
      END IF;
    END IF;
--End of Bug No: 3131865.

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'HZ_CONTACT_POINTS_PKG.Insert_Row (-) ' ||
        'x_contact_point_id = ' ||p_contact_point_rec.contact_point_id,
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

     if p_contact_point_rec.orig_system is not null
         and p_contact_point_rec.orig_system <>fnd_api.g_miss_char
      then
                l_orig_sys_reference_rec.orig_system := p_contact_point_rec.orig_system;
                l_orig_sys_reference_rec.orig_system_reference := p_contact_point_rec.orig_system_reference;
                l_orig_sys_reference_rec.owner_table_name := 'HZ_CONTACT_POINTS';
                l_orig_sys_reference_rec.owner_table_id := p_contact_point_rec.contact_point_id;
                l_orig_sys_reference_rec.created_by_module := p_contact_point_rec.created_by_module;

                hz_orig_system_ref_pub.create_orig_system_reference(
                        FND_API.G_FALSE,
                        l_orig_sys_reference_rec,
                        x_return_status,
                        l_msg_count,
                        l_msg_data);
                 IF x_return_status <> fnd_api.g_ret_sts_success THEN
                        RAISE FND_API.G_EXC_ERROR;
                END IF;
      end if;


    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_create_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_create_contact_point;

  --
  -- PRIVATE PROCEDURE do_update_contact_point
  --
  -- DESCRIPTION
  --     Private procedure to update contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     hz_registry_validate_v2pub.validate_contact_point
  --     hz_registry_validate_v2pub.validate_edi_contact_point
  --     hz_registry_validate_v2pub.validate_eft_contact_point
  --     hz_registry_validate_v2pub.validate_web_contact_point
  --     hz_registry_validate_v2pub.validate_phone_contact_point
  --     hz_registry_validate_v2pub.validate_telex_contact_point
  --     hz_registry_validate_v2pub.validate_email_contact_point
  --     hz_contact_points_pkg.update_row
  --     hz_phone_number_pkg.transpose
  --
  -- ARGUMENTS
  --   IN/OUT:
  --     p_contact_point_rec      Contact point record.
  --     p_edi_rec                EDI record.
  --     p_eft_rec                Electronic File Transfer record.
  --     p_email_rec              Email record.
  --     p_phone_rec              Phone record.
  --     p_telex_rec              Telex record.
  --     p_web_rec                Web record.
  --     p_object_version_number  Used for locking the being updated record.
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   15-NOV-2001   Joe del Callar      Bug 2116225: Modified for consolidated
  --                                     bank support (EFT record support).
  --   05-DEC-2001   Joe del Callar      Bug 2136283: Modified to use new
  --                                     validation procedures.
  --   06-JUL-2004   Rajib Ranjan Borah  Bug 3711740. If phone_format returns
  --                                     NULL for phone_area_code,phone_country_code
  --                                     and/or phone_number, then set these to
  --                                     FND_API.G_MISS_CHAR as otherwise, the old
  --                                     value will be retained.
  --  01-03-2005  Rajib Ranjan Borah   o SSM SST Integration and Extension.
  --                                     For non-profile entities, the concept of
  --                                     select/de-select data-sources is obsoleted.
  

  PROCEDURE do_update_contact_point (
    p_contact_point_rec                   IN OUT NOCOPY contact_point_rec_type,
    p_edi_rec                             IN OUT NOCOPY edi_rec_type,
    p_eft_rec                             IN OUT NOCOPY eft_rec_type,
    p_email_rec                           IN OUT NOCOPY email_rec_type,
    p_phone_rec                           IN OUT NOCOPY phone_rec_type,
    p_telex_rec                           IN OUT NOCOPY telex_rec_type,
    p_web_rec                             IN OUT NOCOPY web_rec_type,
    p_object_version_number               IN OUT NOCOPY NUMBER,
    x_return_status                       IN OUT NOCOPY VARCHAR2
  ) IS

    l_debug_prefix              VARCHAR2(30) := ''; -- do_update_contact_point

    l_rowid                     ROWID := NULL;
    l_contact_point_rowid       ROWID := NULL;
    l_dummy                     VARCHAR2(1);
    l_object_version_number     NUMBER;
    l_message_count             NUMBER;
    l_msg_count                 NUMBER;
    l_msg_data                  VARCHAR2(2000);

    l_formatted_phone_number    VARCHAR2(100);
    l_country_code              hz_locations.country%TYPE;
    l_owner_table_name          hz_contact_points.owner_table_name%TYPE;
    l_owner_table_id            NUMBER;
    l_contact_point_type        hz_contact_points.contact_point_type%TYPE :=
                                  p_contact_point_rec.contact_point_type;
    l_primary_flag              hz_contact_points.primary_flag%TYPE;
    l_status                    hz_contact_points.status%TYPE;
    l_phone_area_code           hz_contact_points.phone_area_code%TYPE;
    l_phone_number              hz_contact_points.phone_number%TYPE;
    l_phone_country_code        hz_contact_points.phone_country_code%TYPE;
    l_url                       hz_contact_points.url%TYPE;
    l_email_address             hz_contact_points.email_address%TYPE;
    l_contact_point_purpose     hz_contact_points.contact_point_purpose%TYPE;
    l_primary_by_purpose        hz_contact_points.primary_by_purpose%TYPE;
    l_transposed_phone_number   hz_contact_points.transposed_phone_number%TYPE;

    --BugNo:1695595.Added local variables to hold denormalized column values----
    l_contact_point_id          hz_contact_points.contact_point_id%TYPE;
    l_phone_line_type           hz_contact_points.phone_line_type%TYPE;
    l_phone_extension           hz_contact_points.phone_extension%TYPE;
    -----------------------------------------------------------------
    l_edi_rec                   edi_rec_type;
    l_eft_rec                   eft_rec_type;
    l_email_rec                 email_rec_type;
    l_phone_rec                 phone_rec_type;
    l_telex_rec                 telex_rec_type;
    l_web_rec                   web_rec_type;

    -- Bug 2197181: added for mix-n-match project.
    db_actual_content_source    hz_contact_points.actual_content_source%TYPE;

    -- Bug 2117973: defined the following cursors for PL/SQL coding standards
    -- compliance.
    CURSOR c_country (p_owner_table_id IN NUMBER) IS
      SELECT country
      FROM   hz_locations
      WHERE  location_id = (SELECT location_id
                            FROM   hz_party_sites
                            WHERE  party_site_id = p_owner_table_id);

    -- Bug 2197181: added for mix-n-match project: the contact point
    -- must be visible.

    -- SSM SST Integration and Extension
    -- Modified the cursors c_setpf and c_chkdenorm
    -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
    -- There is no need to check if the data-source is selected.


    CURSOR c_setpf (
      p_owner_table_name   IN VARCHAR2,
      p_owner_table_id     IN NUMBER,
      p_contact_point_type IN VARCHAR2
    ) IS
      SELECT 'Y'
      FROM   hz_contact_points
      WHERE  owner_table_name = p_owner_table_name
      AND owner_table_id = p_owner_table_id
      AND contact_point_type = p_contact_point_type
      AND contact_point_id <> p_contact_point_rec.contact_point_id
   /*   AND HZ_MIXNM_UTILITY.isDataSourceSelected (
            g_cpt_selected_datasources, actual_content_source ) = 'Y'*/
      AND status = 'A'
      AND rownum = 1;

    -- Bug 2197181: added for mix-n-match project: the contact point
    -- must be visible.
    
    CURSOR c_chkdenorm (
      p_owner_table_name   IN VARCHAR2,
      p_owner_table_id     IN NUMBER,
      p_contact_point_type IN VARCHAR2,
      p_contact_point_id   IN NUMBER
    ) IS
      SELECT rowid, url, email_address,contact_point_id,contact_point_purpose,
             phone_line_type,phone_area_code,phone_country_code,phone_number,phone_extension
      FROM   hz_contact_points
      WHERE  contact_point_id = (
               SELECT MIN(contact_point_id)
               FROM   hz_contact_points
               WHERE  owner_table_name = p_owner_table_name
                      AND owner_table_id = p_owner_table_id
                      AND contact_point_type = p_contact_point_type
                    /*  AND HZ_MIXNM_UTILITY.isDataSourceSelected (
                            g_cpt_selected_datasources, actual_content_source ) = 'Y'*/
                      AND status = 'A'
                      AND contact_point_id <> p_contact_point_id);

  BEGIN
    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_update_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Lock record.

    -- Bug 2197181: selecting actual_content_source for  mix-n-match project.

    BEGIN
    --Bug 1695595 added phone_line_type,phone_extension columns to the select caluse.


      SELECT rowid, object_version_number,
             owner_table_name, owner_table_id,
             contact_point_type, phone_line_type,phone_country_code, phone_area_code,
             phone_number,phone_extension,primary_flag, status, contact_point_purpose,
             url, email_address, primary_by_purpose, actual_content_source
      INTO   l_rowid, l_object_version_number,
             l_owner_table_name, l_owner_table_id,
             l_contact_point_type,l_phone_line_type,
             l_phone_country_code, l_phone_area_code, l_phone_number,l_phone_extension,
             l_primary_flag, l_status, l_contact_point_purpose,
             l_url, l_email_address, l_primary_by_purpose, db_actual_content_source
      FROM   hz_contact_points
      WHERE  contact_point_id = p_contact_point_rec.contact_point_id
      FOR UPDATE NOWAIT;

      IF NOT ((p_object_version_number IS NULL AND
                l_object_version_number IS NULL) OR
              (p_object_version_number IS NOT NULL AND
                l_object_version_number IS NOT NULL AND
                p_object_version_number = l_object_version_number))
      THEN
        fnd_message.set_name('AR', 'HZ_API_RECORD_CHANGED');
        fnd_message.set_token('TABLE', 'hz_contact_points');
        fnd_msg_pub.add;
        RAISE fnd_api.g_exc_error;
      END IF;

      p_object_version_number := NVL(l_object_version_number, 1) + 1;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        fnd_message.set_name('AR', 'HZ_API_NO_RECORD');
        fnd_message.set_token('RECORD', 'contact point');
        fnd_message.set_token('VALUE',
          NVL(TO_CHAR(p_contact_point_rec.contact_point_id), 'null'));
        fnd_msg_pub.add;
        RAISE fnd_api.g_exc_error;
    END;

    -- Debug info.
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'l_contact_point_type = ' || l_contact_point_type,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;


    IF l_contact_point_type = 'EDI' THEN
      l_edi_rec := p_edi_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_edi_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_edi_rec               => l_edi_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    ELSIF l_contact_point_type = 'EFT' THEN
      l_eft_rec := p_eft_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_eft_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_eft_rec               => l_eft_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    ELSIF l_contact_point_type = 'EMAIL' THEN
      l_email_rec := p_email_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_email_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_email_rec             => l_email_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    ELSIF l_contact_point_type = 'PHONE' THEN
      l_phone_rec := p_phone_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_phone_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_phone_rec             => l_phone_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    ELSIF l_contact_point_type = 'TLX' THEN
      l_telex_rec := p_telex_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_telex_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_telex_rec             => l_telex_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    ELSIF l_contact_point_type = 'WEB' THEN
      l_web_rec := p_web_rec;

      -- Validate the contact point record
      hz_registry_validate_v2pub.validate_web_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_web_rec               => l_web_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    ELSE
      l_edi_rec := p_edi_rec;
      l_email_rec := p_email_rec;
      l_phone_rec := p_phone_rec;
      l_telex_rec := p_telex_rec;
      l_web_rec := p_web_rec;

      -- Validate the contact point record - call the old routine and the
      -- EFT validation routine.
      hz_registry_validate_v2pub.validate_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_edi_rec               => l_edi_rec,
        p_email_rec             => l_email_rec,
        p_phone_rec             => l_phone_rec,
        p_telex_rec             => l_telex_rec,
        p_web_rec               => l_web_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);

      IF x_return_status <> fnd_api.g_ret_sts_success THEN
        RAISE fnd_api.g_exc_error;
      END IF;

      hz_registry_validate_v2pub.validate_eft_contact_point (
        p_create_update_flag    => 'U',
        p_contact_point_rec     => p_contact_point_rec,
        p_eft_rec               => l_eft_rec,
        p_rowid                 => l_rowid,
        x_return_status         => x_return_status);
    END IF;

    IF x_return_status <> fnd_api.g_ret_sts_success THEN
      RAISE fnd_api.g_exc_error;
    END IF;

    -- If raw_phone_number is passed in, call procedure phone_format.
    -- either raw_phone_number or phone_number should be passed in
    -- but can not be both. If raw_phone_number does not have a value,
    -- it will be set by phone_number and phone_area_code.
    -- We cannot re-format raw_phone_number if only phone_country_code
    -- is changed because raw_phone_number might not have been formatted
    -- and created by concat phone_area_code and phone_number.

    -- contact_point_type, owner_table_name, owner_table_id,
    -- actual_content_source are non-updateable columns.

    IF l_contact_point_type = 'PHONE' THEN
      IF l_phone_rec.phone_country_code IS NOT NULL THEN
        IF l_phone_rec.phone_country_code = fnd_api.g_miss_char THEN
          l_phone_country_code := NULL;
        ELSE
          l_phone_country_code := l_phone_rec.phone_country_code;
        END IF;
      END IF;

      IF l_phone_rec.phone_area_code IS NOT NULL THEN
        IF l_phone_rec.phone_area_code = fnd_api.g_miss_char THEN
          l_phone_area_code := NULL;
        ELSE
          l_phone_area_code := l_phone_rec.phone_area_code;
        END IF;
      END IF;

      IF l_phone_rec.phone_number IS NOT NULL THEN
        IF l_phone_rec.phone_number = fnd_api.g_miss_char THEN
          l_phone_number := NULL;
        ELSE
          l_phone_number := l_phone_rec.phone_number;
        END IF;
      END IF;

      IF l_phone_rec.raw_phone_number IS NOT NULL AND
         l_phone_rec.raw_phone_number <> fnd_api.g_miss_char THEN

         IF l_phone_rec.phone_country_code is not null AND
            l_phone_rec.phone_country_code <> fnd_api.g_miss_char
         THEN
            BEGIN
              select territory_code into l_country_code
              from hz_phone_country_codes
              where phone_country_code = l_phone_rec.phone_country_code
              and rownum = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
               NULL;
            END;
         ELSIF l_owner_table_name = 'HZ_PARTY_SITES' AND
               l_phone_country_code IS NULL THEN
               OPEN c_country (l_owner_table_id);
               FETCH c_country INTO l_country_code;

               IF c_country%NOTFOUND THEN
                 CLOSE c_country;
                 RAISE NO_DATA_FOUND;
               ELSE
                 CLOSE c_country;
               END IF;
         ELSE
           l_country_code := NULL;
         END IF;

         -- Since phone_format cannot format raw_phone_number and phone_number
         -- at same time, the input value of phone_number and phone_area_code
         -- shoule be NULL or G_MISS before the call.

         l_message_count := fnd_msg_pub.count_msg();

         phone_format (
           p_raw_phone_number                  => l_phone_rec.raw_phone_number,
           p_territory_code                    => l_country_code,
           x_formatted_phone_number            => l_formatted_phone_number,
           x_phone_country_code                => l_phone_country_code,
           x_phone_area_code                   => l_phone_rec.phone_area_code,
           x_phone_number                      => l_phone_rec.phone_number,
           x_return_status                     => x_return_status,
           x_msg_count                         => l_msg_count,
           x_msg_data                          => l_msg_data);

         -- Raise exception only if content_source_type = G_MISS_CONTENT_SOURCE_TYPE.
         -- For other sources, we do not want to error out, but simply store the
         -- Raw Phone Number.

         /* Bug 3711740 */
         IF l_phone_rec.phone_area_code IS NULL THEN
             l_phone_rec.phone_area_code := fnd_api.g_miss_char;
         END IF;

         IF l_phone_rec.phone_number IS NULL THEN
             l_phone_rec.phone_number := fnd_api.g_miss_char;
         END IF;

         -- Bug 2197181 : content_source_type is obsolete and replaced by
         -- actual_content_source

         IF x_return_status <> fnd_api.g_ret_sts_success THEN
           IF db_actual_content_source = g_miss_content_source_type
           THEN
             IF x_return_status = fnd_api.g_ret_sts_error THEN
               RAISE fnd_api.g_exc_error;
             ELSE
               RAISE fnd_api.g_exc_unexpected_error;
             END IF;
           ELSE
             FOR i IN 1..(l_msg_count - l_message_count) LOOP
               fnd_msg_pub.delete_msg(l_msg_count - l_message_count + 1 - i);
             END LOOP;
             x_return_status := fnd_api.g_ret_sts_success;
           END IF;
         ELSE
           l_phone_number := l_phone_rec.phone_number;
           l_phone_area_code := l_phone_rec.phone_area_code;

           IF l_phone_country_code IS NOT NULL THEN
             l_phone_rec.phone_country_code := l_phone_country_code;
           ELSE
             l_phone_rec.phone_country_code := FND_API.G_MISS_CHAR; /*Bug 3711740*/
           END IF;
         END IF;
      ELSE
        -- raw_phone_number must always have value.

        IF l_phone_area_code IS NULL THEN
          l_phone_rec.raw_phone_number := l_phone_number;
        ELSE
          l_phone_rec.raw_phone_number :=
            l_phone_area_code || '-' || l_phone_number;
        END IF;
      END IF;

      -- Debug info.
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'phone_number = ' || l_phone_rec.phone_number || ' ' ||
          'raw_phone_number = ' || l_phone_rec.raw_phone_number,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
      END IF;


      -- Populate transposed_phone_number
      IF l_phone_country_code IS NOT NULL THEN
        l_transposed_phone_number := l_phone_country_code;
      END IF;

      IF l_phone_area_code IS NOT NULL THEN
        l_transposed_phone_number := l_transposed_phone_number ||
                                     l_phone_area_code;
      END IF;

      IF l_phone_number IS NOT NULL THEN
        l_transposed_phone_number := l_transposed_phone_number ||
                                     l_phone_number;
      END IF;

      IF l_transposed_phone_number IS NOT NULL THEN
        l_transposed_phone_number :=
          hz_phone_number_pkg.transpose(l_transposed_phone_number);
      END IF;

      -- Debug info.
      IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'transposed_phone_number = ' || l_transposed_phone_number,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;

    END IF;

    -- Cannot set an inactive contact point as primary. This validation
    -- has been checked in validate_contact_point procedure.

    -- Ignore the value of primary contact flag if the flag has been set
    -- to 'N' or fnd_api.g_miss_char by setting primary flag to NULL.
    -- User can not unset primary flag by passing value. To unset a
    -- primary contact, he/she needs to select another contact as priamry
    -- or set the current one to Inactive.

    IF p_contact_point_rec.primary_flag = 'N' OR
       p_contact_point_rec.primary_flag = fnd_api.g_miss_char
    THEN
      p_contact_point_rec.primary_flag := NULL;
    END IF;

    -- Bug 2197181: added for mix-n-match project: the primary flag
    -- can be set to 'Y' only if the contact point will be visible. If
    -- it is not visible, the flag must be reset to 'N'.

    -- Set the first, visible, active contact point as primary.

    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
    -- There is no need to check if the data-source is selected.

    IF (p_contact_point_rec.status IS NULL AND
        l_status = 'A') OR
        p_contact_point_rec.status = 'A'
    THEN
      IF p_contact_point_rec.primary_flag = 'Y' AND
         l_primary_flag <> 'Y'
      THEN
        -- Bug 2197181: added for mix-n-match project
     -- IF g_cpt_is_datasource_selected = 'Y' THEN
          -- Unmark previous primary contact point.
          do_unset_prim_contact_point (
            l_owner_table_name,
            l_owner_table_id,
            l_contact_point_type,
            p_contact_point_rec.contact_point_id);
     -- ELSE
     --   p_contact_point_rec.primary_flag := 'N';
     -- END IF;
      ELSIF l_primary_flag <> 'Y' THEN
        -- Bug 2117973: changed to use a cursor instead of select...into.
        OPEN c_setpf(l_owner_table_name,
                     l_owner_table_id,
                     l_contact_point_type);
        FETCH c_setpf INTO l_dummy;

        -- SSM SST Integration and Extension
   -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
   -- There is no need to check if the data-source is selected.

        IF c_setpf%NOTFOUND /*AND
           -- Bug 2197181: added for mix-n-match project
           g_cpt_is_datasource_selected = 'Y'*/
        THEN
          -- First visible, active contact point per type for this entity
          p_contact_point_rec.primary_flag := 'Y';
        ELSE
          p_contact_point_rec.primary_flag := 'N';
        END IF;

        CLOSE c_setpf;
      END IF;

      -- De-normalize primary contact point to HZ_PARTIES.
      -- url is mandatory if contact_point_type = 'WEB'.
      -- email_address is mandatory if contact_point_type = 'EMAIL'.

      -- Bug 2197181: commented out NOCOPY the data source checking. We will
      -- denormalize to hz_parties as long as it's a primary contact
      -- point regardless of data source.

      IF (p_contact_point_rec.primary_flag = 'Y' OR
          l_primary_flag = 'Y') AND
         l_owner_table_name = 'HZ_PARTIES' AND
         (l_contact_point_type IN ('WEB','EMAIL','PHONE'))
         /*  AND
         l_content_source_type = hz_party_v2pub.g_miss_content_source_type
         */
      THEN
        IF l_web_rec.url IS NOT NULL THEN
          l_url := l_web_rec.url;
        END IF;

        IF l_email_rec.email_address IS NOT NULL THEN
          l_email_address := l_email_rec.email_address;
        END IF;

        --BugNo:1695595.Initialized the local variables with the passed values after validations--

        l_contact_point_id:=p_contact_point_rec.contact_point_id;

        IF p_contact_point_rec.contact_point_purpose=FND_API.G_MISS_CHAR THEN
          l_contact_point_purpose := NULL;
        ELSIF p_contact_point_rec.contact_point_purpose IS NOT NULL THEN
          l_contact_point_purpose := p_contact_point_rec.contact_point_purpose;
        END IF;

        IF l_phone_rec.phone_line_type=FND_API.G_MISS_CHAR THEN
          l_phone_line_type :=NULL;
        ELSIF l_phone_rec.phone_line_type IS NOT NULL THEN
          l_phone_line_type := l_phone_rec.phone_line_type;
        END IF;

        IF l_phone_rec.phone_country_code=FND_API.G_MISS_CHAR THEN
          l_phone_country_code :=NULL;
        ELSIF l_phone_rec.phone_country_code IS NOT NULL THEN
          l_phone_country_code := l_phone_rec.phone_country_code;
        END IF;

        IF l_phone_rec.phone_area_code=FND_API.G_MISS_CHAR THEN
          l_phone_area_code :=NULL;
        ELSIF l_phone_rec.phone_area_code IS NOT NULL THEN
          l_phone_area_code := l_phone_rec.phone_area_code;
        END IF;

        IF l_phone_rec.phone_number=FND_API.G_MISS_CHAR THEN
          l_phone_number := NULL;
        ELSIF l_phone_rec.phone_number IS NOT NULL THEN
          l_phone_number := l_phone_rec.phone_number;
        END IF;

        IF l_phone_rec.phone_extension=FND_API.G_MISS_CHAR THEN
          l_phone_extension :=NULL;
        ELSIF l_phone_rec.phone_extension IS NOT NULL THEN
          l_phone_extension := l_phone_rec.phone_extension;
        END IF;

        ----------------------------------------------------------
        do_denormalize_contact_point(l_owner_table_id,
                                     l_contact_point_type,
                                     l_url,
                                     l_email_address,
                                     l_contact_point_id,
                                     l_contact_point_purpose,
                                     l_phone_line_type,
                                     l_phone_country_code,
                                     l_phone_area_code,
                                     l_phone_number,
                                     l_phone_extension
                                    );
      END IF;
    ELSE
      -- If a primary contact is being marked as inactive then
      -- set the current one as non-primary and mark the next
      -- active contact as primary

      IF l_status = 'A' AND
         p_contact_point_rec.status = 'I' AND
         l_primary_flag = 'Y'
      THEN

        -- set the current one as non-primary
        p_contact_point_rec.primary_flag := 'N';

        -- Bug 2117973: changed to use cursor instead of select...into.
        OPEN c_chkdenorm(l_owner_table_name,
                         l_owner_table_id,
                         l_contact_point_type,
                         p_contact_point_rec.contact_point_id);
        FETCH c_chkdenorm INTO l_contact_point_rowid, l_url, l_email_address,l_contact_point_id,
                               l_contact_point_purpose,l_phone_line_type,l_phone_area_code,
                               l_phone_country_code,l_phone_number,l_phone_extension;

        IF c_chkdenorm%NOTFOUND THEN
          -- no active contact point of this type left.
          -- clear denormalized field in hz_parties.

          IF l_owner_table_name = 'HZ_PARTIES' AND
             (l_contact_point_type IN('WEB','EMAIL','PHONE'))
             /*AND
             l_content_source_type = hz_party_v2pub.g_miss_content_source_type */
          THEN
            l_url                   :=NULL;
            l_email_address         :=NULL;
            --Bugno:1695595. Updated the denormalized columns to NULL.
            l_contact_point_id      :=NULL;
            l_contact_point_purpose :=NULL;
            l_phone_line_type       :=NULL;
            l_phone_country_code    :=NULL;
            l_phone_area_code       :=NULL;
            l_phone_number          :=NULL;
            l_phone_extension       :=NULL;


            do_denormalize_contact_point(l_owner_table_id,
                                         l_contact_point_type,
                                         l_url,
                                         l_email_address,
                                         l_contact_point_id,
                                         l_contact_point_purpose,
                                         l_phone_line_type,
                                         l_phone_country_code,
                                         l_phone_area_code,
                                         l_phone_number,
                                         l_phone_extension
                                        );
          END IF;
        ELSE
          UPDATE hz_contact_points
          SET    primary_flag = 'Y'
          WHERE  rowid = l_contact_point_rowid;

          -- De-normalize primary contact point to HZ_PARTIES.

          IF l_owner_table_name = 'HZ_PARTIES' AND
             (l_contact_point_type IN ('WEB','EMAIL','PHONE'))
             /*
             l_content_source_type = hz_party_v2pub.g_miss_content_source_type */
          THEN
            do_denormalize_contact_point(l_owner_table_id,
                                         l_contact_point_type,
                                         l_url,
                                         l_email_address,
                                         l_contact_point_id,
                                         l_contact_point_purpose,
                                         l_phone_line_type,
                                         l_phone_country_code,
                                         l_phone_area_code,
                                         l_phone_number,
                                         l_phone_extension
                                        );
          END IF;
        END IF;
        CLOSE c_chkdenorm;
      END IF;
    END IF;

    -- There is only one primary per purpose contact point exist for
    -- the combination of owner_table_name, owner_table_id, contact_point_type
    -- and contact_point_purpose. If primary_by_purpose is set to 'Y',
    -- we need to unset the previous primary per purpose contact point to
    -- non-primary. Since setting primary_by_purpose is only making
    -- sense when contact_point_purpose has some value, we ignore
    -- the primary_by_purpose (setting it to 'N') if contact_point_purpose
    -- is NULL.

    -- Bug 2197181: added for mix-n-match project: the primary by purpose
    -- flag can be set to 'Y' only if the contact point will be visible.
    -- If it is not visible, the flag must be reset to 'N'.

    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
    -- There is no need to check if the data-source is selected.
    
    IF (p_contact_point_rec.contact_point_purpose IS NOT NULL AND
         p_contact_point_rec.contact_point_purpose <> fnd_api.g_miss_char) OR
       (p_contact_point_rec.contact_point_purpose IS NULL AND
         l_contact_point_purpose IS NOT NULL)
    THEN
      IF p_contact_point_rec.contact_point_purpose IS NOT NULL AND
         p_contact_point_rec.contact_point_purpose <> fnd_api.g_miss_char
      THEN
         l_contact_point_purpose := p_contact_point_rec.contact_point_purpose;
      END IF;

      IF (p_contact_point_rec.primary_by_purpose = 'Y' AND
          NVL(l_primary_by_purpose,'N') = 'N') /*AND
          -- Bug 2197181: added for mix-n-match project
          g_cpt_is_datasource_selected = 'Y') *//*OR
         (p_contact_point_rec.primary_by_purpose IS NULL AND
          l_primary_by_purpose = 'Y')*/
      THEN
        do_unset_primary_by_purpose(l_owner_table_name,
                                     l_owner_table_id,
                                     l_contact_point_type,
                                     l_contact_point_purpose,
                                     p_contact_point_rec.contact_point_id);
      ELSIF NVL(l_primary_by_purpose,'N') = 'N' THEN
        p_contact_point_rec.primary_by_purpose := 'N';
      ELSE
        p_contact_point_rec.primary_by_purpose := NULL;
      END IF;
    ELSE
      p_contact_point_rec.primary_by_purpose := 'N';
    END IF;

     if (p_contact_point_rec.orig_system is not null
         and p_contact_point_rec.orig_system <>fnd_api.g_miss_char)
        and (p_contact_point_rec.orig_system_reference is not null
         and p_contact_point_rec.orig_system_reference <>fnd_api.g_miss_char)
      then
                p_contact_point_rec.orig_system_reference := null;
                -- In mosr, we have bypassed osr nonupdateable validation
                -- but we should not update existing osr, set it to null
      end if;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'hz_contact_points_pkg.update_row (+) ',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call table-handler.
    hz_contact_points_pkg.update_row (
      x_rowid                           => l_rowid,
      x_contact_point_id                => p_contact_point_rec.contact_point_id,
      x_contact_point_type              => p_contact_point_rec.contact_point_type,
      x_status                          => p_contact_point_rec.status,
      x_owner_table_name                => p_contact_point_rec.owner_table_name,
      x_owner_table_id                  => p_contact_point_rec.owner_table_id,
      x_primary_flag                    => p_contact_point_rec.primary_flag,
      x_orig_system_reference           => p_contact_point_rec.orig_system_reference,
      x_attribute_category              => p_contact_point_rec.attribute_category,
      x_attribute1                      => p_contact_point_rec.attribute1,
      x_attribute2                      => p_contact_point_rec.attribute2,
      x_attribute3                      => p_contact_point_rec.attribute3,
      x_attribute4                      => p_contact_point_rec.attribute4,
      x_attribute5                      => p_contact_point_rec.attribute5,
      x_attribute6                      => p_contact_point_rec.attribute6,
      x_attribute7                      => p_contact_point_rec.attribute7,
      x_attribute8                      => p_contact_point_rec.attribute8,
      x_attribute9                      => p_contact_point_rec.attribute9,
      x_attribute10                     => p_contact_point_rec.attribute10,
      x_attribute11                     => p_contact_point_rec.attribute11,
      x_attribute12                     => p_contact_point_rec.attribute12,
      x_attribute13                     => p_contact_point_rec.attribute13,
      x_attribute14                     => p_contact_point_rec.attribute14,
      x_attribute15                     => p_contact_point_rec.attribute15,
      x_attribute16                     => p_contact_point_rec.attribute16,
      x_attribute17                     => p_contact_point_rec.attribute17,
      x_attribute18                     => p_contact_point_rec.attribute18,
      x_attribute19                     => p_contact_point_rec.attribute19,
      x_attribute20                     => p_contact_point_rec.attribute20,
      x_edi_transaction_handling        => l_edi_rec.edi_transaction_handling,
      x_edi_id_number                   => l_edi_rec.edi_id_number,
      x_edi_payment_method              => l_edi_rec.edi_payment_method,
      x_edi_payment_format              => l_edi_rec.edi_payment_format,
      x_edi_remittance_method           => l_edi_rec.edi_remittance_method,
      x_edi_remittance_instruction      => l_edi_rec.edi_remittance_instruction,
      x_edi_tp_header_id                => l_edi_rec.edi_tp_header_id,
      x_edi_ece_tp_location_code        => l_edi_rec.edi_ece_tp_location_code,
      x_eft_transmission_program_id     => l_eft_rec.eft_transmission_program_id,
      x_eft_printing_program_id         => l_eft_rec.eft_printing_program_id,
      x_eft_user_number                 => l_eft_rec.eft_user_number,
      x_eft_swift_code                  => l_eft_rec.eft_swift_code,
      x_email_format                    => l_email_rec.email_format,
      x_email_address                   => l_email_rec.email_address,
      x_phone_calling_calendar          => l_phone_rec.phone_calling_calendar,
      x_last_contact_dt_time            => l_phone_rec.last_contact_dt_time,
      x_timezone_id                     => l_phone_rec.timezone_id,
      x_phone_area_code                 => l_phone_rec.phone_area_code,
      x_phone_country_code              => l_phone_rec.phone_country_code,
      x_phone_number                    => l_phone_rec.phone_number,
      x_phone_extension                 => l_phone_rec.phone_extension,
      x_phone_line_type                 => l_phone_rec.phone_line_type,
      x_telex_number                    => l_telex_rec.telex_number,
      x_web_type                        => l_web_rec.web_type,
      x_url                             => l_web_rec.url,
      -- Bug 2197181 : content_source_type is obsolete and it is non-updateable.
      x_content_source_type             => NULL,
      x_raw_phone_number                => l_phone_rec.raw_phone_number,
      x_object_version_number           => p_object_version_number,
      x_contact_point_purpose           => p_contact_point_rec.contact_point_purpose,
      x_primary_by_purpose              => p_contact_point_rec.primary_by_purpose,
      x_created_by_module               => p_contact_point_rec.created_by_module,
      x_application_id                  => p_contact_point_rec.application_id,
      x_transposed_phone_number         => l_transposed_phone_number,
      x_actual_content_source           => p_contact_point_rec.actual_content_source
    );

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'hz_contact_points_PKG.Update_Row (-) ',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
        hz_utility_v2pub.debug(p_message=>'do_update_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_update_contact_point;

  --
  -- PRIVATE PROCEDURE do_unset_prim_contact_point
  --
  -- DESCRIPTION
  --     Private procedure to unset previous primary flag.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_owner_table_name             Owner table name.
  --     p_owner_table_id               Owner table ID.
  --     p_contact_point_type           Contact point type.
  --     p_contact_point_id             Contact point id.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   09-30-2003    Rajib Ranjan Borah  o Bug 2914238.Updated the who columns
  --                                       while updating the HZ_CONTACT_POINT record.
  --  28-OCT-2003   Ramesh Ch           Bug#2914238.Removed  created_by and creation_date
  --                                    columns during update.

  PROCEDURE do_unset_prim_contact_point (
    p_owner_table_name                      IN     VARCHAR2,
    p_owner_table_id                        IN     NUMBER,
    p_contact_point_type                    IN     VARCHAR2,
    p_contact_point_id                      IN     NUMBER
  ) IS

    l_contact_point_id                      NUMBER;
    l_debug_prefix                         VARCHAR2(30) := '';

  BEGIN

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_unset_prim_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check during insert.
    IF p_contact_point_id IS NULL THEN
      l_contact_point_id := fnd_api.g_miss_num;
    ELSE
      l_contact_point_id := p_contact_point_id;
    END IF;

    UPDATE hz_contact_points
    SET    primary_flag         = 'N',
      --Bug number 2914238 .Updated the who columns.
           last_update_date     = hz_utility_v2pub.last_update_date,
           last_updated_by      = hz_utility_v2pub.last_updated_by,
           last_update_login    = hz_utility_v2pub.last_update_login,
           request_id           = hz_utility_v2pub.request_id,
           program_id           = hz_utility_v2pub.program_id,
           program_application_id = hz_utility_v2pub.program_application_id,
           program_update_date  = hz_utility_v2pub.program_update_date
    WHERE  owner_table_name = p_owner_table_name
    AND owner_table_id = p_owner_table_id
    AND contact_point_type = p_contact_point_type
    AND contact_point_id <> l_contact_point_id
    -- AND content_source_type = hz_party_v2pub.g_miss_content_source_type
    AND primary_flag = 'Y';

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_unset_prim_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_unset_prim_contact_point;

  --
  -- PRIVATE PROCEDURE do_denormalize_contact_point
  --
  -- DESCRIPTION
  --   Private procedure to denormalize some type of contact point to hz_parties.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_party_id                     Party ID.
  --     p_contact_point_type           Contact point type.
  --     p_url                          URL.
  --     p_email_address                Email address.
  --   BugNo:1695595
  --     p_phone_contact_pt_id          Contact point id.
  --     p_phone_purpose                Contact Point Purpose.
  --     p_phone_line_type              Phone line type.
  --     p_phone_country_code           Phone country code.
  --     p_phone_area_code              Phone area code.
  --     p_phone_number                 Phone Number.
  --     p_phone_extension              Phone extension.
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   08-19-2003    Ramesh.Ch           o Modified the
  --                                       Signature and logic.
  --

  PROCEDURE do_denormalize_contact_point (
    p_party_id                              IN     NUMBER,
    p_contact_point_type                    IN     VARCHAR2,
    p_url                                   IN     VARCHAR2,
    p_email_address                         IN     VARCHAR2,
    p_phone_contact_pt_id                   IN     NUMBER,
    p_phone_purpose                         IN     VARCHAR2,
    p_phone_line_type                       IN     VARCHAR2,
    p_phone_country_code                    IN     VARCHAR2,
    p_phone_area_code                       IN     VARCHAR2,
    p_phone_number                          IN     VARCHAR2,
    p_phone_extension                       IN     VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN
    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_denormalize_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
    IF fnd_log.level_statement>=fnd_log.g_current_runtime_level THEN
           hz_utility_v2pub.debug(p_message=>'party_id = ' || p_party_id || ' ' ||
                                        'contact_point_type = ' || p_contact_point_type || ' ' ||
                                        'url = ' || p_url || ' ' ||
                                        'email_address = ' || p_email_address||
                                        'primary_phone_contact_pt_id = ' || p_phone_contact_pt_id || ' ' ||
                                        'primary_phone_purpose = ' || p_phone_purpose || ' ' ||
                                        'primary_phone_line_type = ' || p_phone_line_type || ' ' ||
                                        'primary_phone_country_code = ' || p_phone_country_code || ' ' ||
                                        'primary_phone_area_code = ' || p_phone_area_code || ' ' ||
                                        'primary_phone_number = ' || p_phone_number || ' ' ||
                                        'primary_phone_extension = ' || p_phone_extension  ,
                                  p_prefix =>l_debug_prefix,
                                  p_msg_level=>fnd_log.level_statement);
    END IF;


    IF p_contact_point_type = 'WEB' THEN
      UPDATE hz_parties
      SET    url                       = p_url,
             last_update_date          = hz_utility_v2pub.last_update_date,
             last_updated_by           = hz_utility_v2pub.last_updated_by,
             last_update_login         = hz_utility_v2pub.last_update_login,
             request_id                = hz_utility_v2pub.request_id,
             program_application_id    = hz_utility_v2pub.program_application_id,
             program_id                = hz_utility_v2pub.program_id,
             program_update_date       = sysdate
      WHERE  party_id = p_party_id;
    ELSIF p_contact_point_type = 'EMAIL' THEN
      UPDATE hz_parties
      SET    email_address             = p_email_address,
             last_update_date          = hz_utility_v2pub.last_update_date,
             last_updated_by           = hz_utility_v2pub.last_updated_by,
             last_update_login         = hz_utility_v2pub.last_update_login,
             request_id                = hz_utility_v2pub.request_id,
             program_application_id    = hz_utility_v2pub.program_application_id,
             program_id                = hz_utility_v2pub.program_id,
             program_update_date       = sysdate
      WHERE  party_id = p_party_id;
    ELSIF p_contact_point_type = 'PHONE' THEN
      UPDATE hz_parties
      SET    primary_phone_contact_pt_id       = p_phone_contact_pt_id,
             primary_phone_purpose             = p_phone_purpose,
             primary_phone_line_type           = p_phone_line_type,
             primary_phone_country_code        = p_phone_country_code,
             primary_phone_area_code           = p_phone_area_code,
             primary_phone_number              = p_phone_number,
             primary_phone_extension           = p_phone_extension,
             last_update_date          = hz_utility_v2pub.last_update_date,
             last_updated_by           = hz_utility_v2pub.last_updated_by,
             last_update_login         = hz_utility_v2pub.last_update_login,
             request_id                = hz_utility_v2pub.request_id,
             program_application_id    = hz_utility_v2pub.program_application_id,
             program_id                = hz_utility_v2pub.program_id,
             program_update_date       = sysdate
      WHERE  party_id = p_party_id;
    END IF;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_denormalize_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_denormalize_contact_point;

  --
  -- PRIVATE PROCEDURE do_unset_primary_by_purpose
  --
  -- DESCRIPTION
  --     Private procedure to unset previous primary by purpose flag.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_owner_table_name             Owner table name.
  --     p_owner_table_id               Owner table ID.
  --     p_contact_point_type           Contact point type.
  --     p_contact_point_purpose        Contact point purpose.
  --     p_contact_point_id             Contact point id.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   28-OCT-2003   Ramesh Ch           Bug#2914238. Updated the who columns in
  --                                     do_unset_primary_by_purpose
  --
  --

  PROCEDURE do_unset_primary_by_purpose (
    p_owner_table_name                      IN     VARCHAR2,
    p_owner_table_id                        IN     NUMBER,
    p_contact_point_type                    IN     VARCHAR2,
    p_contact_point_purpose                 IN     VARCHAR2,
    p_contact_point_id                      IN     NUMBER
  ) IS

    l_contact_point_id                      NUMBER;
    l_debug_prefix                     VARCHAR2(30) := '';
  BEGIN

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_unset_primary_by_purpose (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check during insert.
    IF p_contact_point_id IS NULL THEN
      l_contact_point_id := FND_API.G_MISS_NUM;
    ELSE
      l_contact_point_id := p_contact_point_id;
    END IF;

    UPDATE hz_contact_points
    SET   primary_by_purpose = 'N',
          last_update_date     = hz_utility_v2pub.last_update_date,
          last_updated_by      = hz_utility_v2pub.last_updated_by,
          last_update_login    = hz_utility_v2pub.last_update_login,
          request_id           = hz_utility_v2pub.request_id,
          program_id           = hz_utility_v2pub.program_id,
          program_application_id = hz_utility_v2pub.program_application_id,
          program_update_date  = hz_utility_v2pub.program_update_date
    WHERE  owner_table_name = p_owner_table_name
    AND owner_table_id = p_owner_table_id
    AND contact_point_type = p_contact_point_type
    AND contact_point_purpose = p_contact_point_purpose
    AND contact_point_id <> l_contact_point_id
    -- AND content_source_type = hz_party_v2pub.g_miss_content_source_type
    AND primary_by_purpose = 'Y';

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'do_unset_primary_by_purpose (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END do_unset_primary_by_purpose;

  --
  -- PRIVATE FUNCTION filter_phone_number
  --
  -- DESCRIPTION
  --     Private funcation to filter phone number. It returns filtered phone number
  --     based on some translation rule.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_phone_number                 Phone number.
  --     p_isformat                     Use different translation rule.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --
  --

  FUNCTION filter_phone_number (
    p_phone_number                          IN     VARCHAR2,
    p_isformat                              IN     NUMBER := 0
  ) RETURN VARCHAR2 IS

    l_filtered_number                       VARCHAR2(100);
    l_debug_prefix                         VARCHAR2(30) := '';

  BEGIN

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'filter_phone_number (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    IF p_isformat = 0 THEN
      l_filtered_number := TRANSLATE (
        p_phone_number,
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ()- .+''~`\/@#$%^&*_,|}{[]?<>=";:',
        '0123456789');
    ELSE
      l_filtered_number := TRANSLATE (
        p_phone_number,
        '9012345678ABCDEFGHIJKLMNOPQRSTUVWXYZ()- .+''~`\/@#$%^&*_,|}{[]?<>=";:',
        '9');
    END IF;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'filter_phone_number (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    RETURN l_filtered_number;

  END filter_phone_number;

  --
  -- PRIVATE PROCEDURE get_phone_format
  --
  -- DESCRIPTION
  --     Private procedure to get phone format.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_phone_number                 Phone number.
  --     p_isformat                     Use different translation rule.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --
  --

  PROCEDURE get_phone_format (
    p_raw_phone_number          IN     VARCHAR2 := fnd_api.g_miss_char,
    p_territory_code            IN     VARCHAR2 := fnd_api.g_miss_char,
    p_area_code                 IN     VARCHAR2,
    x_phone_country_code        OUT NOCOPY    VARCHAR2,
    x_phone_format_style        OUT NOCOPY    VARCHAR2,
    x_area_code_size            OUT NOCOPY    VARCHAR2,
    x_include_country_code      OUT NOCOPY    BOOLEAN,
    x_msg                       OUT NOCOPY    VARCHAR2
  ) IS

    l_defaut_prefix             VARCHAR2(30) := ''; -- get_phone_format

    l_empty                     BOOLEAN;

    -- Query all the format styles along with other flags
    CURSOR c_formats IS
      SELECT pf.phone_format_style, pf.country_code_display_flag,
             pf.area_code_size, pcc.phone_country_code
      FROM   hz_phone_country_codes pcc, hz_phone_formats pf
      WHERE  pcc.territory_code = p_territory_code
             AND pcc.territory_code = pf.territory_code;

    l_phone_format_style        hz_phone_formats.phone_format_style%TYPE;
    l_area_code_size            NUMBER;
    l_phone_country_code        hz_phone_country_codes.phone_country_code%TYPE;
    l_country_code_display_flag hz_phone_formats.country_code_display_flag%TYPE;
    l_debug_prefix                     VARCHAR2(30) := '';

  BEGIN

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_format (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Initialize return variables
    x_phone_format_style := fnd_api.g_miss_char;
    x_phone_country_code := fnd_api.g_miss_char;
    x_include_country_code := FALSE;

    -- No territory code passed
    IF p_territory_code = fnd_api.g_miss_char THEN
      x_msg := 'HZ_COUNTRY_CODE_NOT_DEFINED';
      RETURN;
    END IF;

    -- Open the cursor and check if format styles exist
    l_empty := TRUE;

    OPEN c_formats;
    LOOP
      FETCH c_formats
      INTO  l_phone_format_style, l_country_code_display_flag,
            l_area_code_size, l_phone_country_code;
      IF c_formats%NOTFOUND THEN
        IF l_empty THEN
          x_msg := 'HZ_COUNTRY_CODE_NOT_DEFINED';
          CLOSE c_formats;
          RETURN;
        ELSE
          EXIT;
        END IF;
      END IF;

      -- Loop through format styles and select the correct one based on
      -- the length of the raw phone number

      IF l_empty THEN
        l_empty := FALSE;
      END IF;

      IF LENGTHB(filter_phone_number(l_phone_format_style, 1)) =
         LENGTHB(p_raw_phone_number)
      THEN
        IF p_area_code IS NULL OR
           (p_area_code IS NOT NULL AND
             LENGTHB(p_area_code) = l_area_code_size)
        THEN
          x_phone_format_style := l_phone_format_style;
          IF l_country_code_display_flag = 'Y' THEN
            x_include_country_code := TRUE;
          END IF;

          x_area_code_size := l_area_code_size;
          x_phone_country_code := l_phone_country_code;
          EXIT;

        END IF;
      END IF;

    END LOOP;
    CLOSE c_formats;

    -- No appropriate format mask found
    IF x_phone_format_style = fnd_api.g_miss_char THEN
      x_msg := 'HZ_PHONE_FORMAT_NOT_DEFINED';
    END IF;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_format (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE fnd_api.g_exc_unexpected_error;

  END get_phone_format;

  --
  -- PRIVATE PROCEDURE translate_raw_phone_number
  --
  -- DESCRIPTION
  --     Private procedure to translate raw phone number.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_raw_phone_number             Raw phone number.
  --     p_phone_format_style           Phone format style.
  --     p_area_code_size               Phone area code size.
  --   OUT:
  --     x_formatted_phone_number       Formatted phone number.
  --     x_phone_area_code              Phone area code.
  --     x_phone_number                 Phone number.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --
  --

  PROCEDURE translate_raw_phone_number (
    p_raw_phone_number        IN     VARCHAR2 := fnd_api.g_miss_char,
    p_phone_format_style      IN     VARCHAR2 := fnd_api.g_miss_char,
    p_area_code_size          IN     NUMBER := 0,
    x_formatted_phone_number  OUT NOCOPY    VARCHAR2,
    x_phone_area_code         OUT NOCOPY    VARCHAR2,
    x_phone_number            OUT NOCOPY    VARCHAR2
  ) IS

    l_debug_prefix            VARCHAR2(30) := ''; -- translate_raw_phone_number

    l_phone_counter           NUMBER := 1;
    l_format_length           NUMBER;
    l_format_char             VARCHAR2(1);

  BEGIN

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'translate_raw_phone_number (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    l_format_length := LENGTHB(p_phone_format_style);
    x_formatted_phone_number := '';

    -- Loop through each character of the phone format string
    -- and construct the formatted phone number

    FOR i IN 1..l_format_length LOOP
      l_format_char := SUBSTRB(p_phone_format_style, i, 1);

      IF l_format_char = '9' THEN
        x_formatted_phone_number := x_formatted_phone_number ||
                                    SUBSTRB(p_raw_phone_number,
                                            l_phone_counter, 1);
        l_phone_counter := l_phone_counter + 1;
      ELSE
        x_formatted_phone_number := x_formatted_phone_number || l_format_char;
      END IF;
    END LOOP;

    -- Parse out NOCOPY the area code and phone number components
    x_phone_area_code := SUBSTRB(p_raw_phone_number, 1, p_area_code_size);
    x_phone_number := SUBSTRB(p_raw_phone_number, p_area_code_size + 1);

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'translate_raw_phone_number (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

  END translate_raw_phone_number;

  --
  -- PROCEDURE get_contact_point_main
  --
  -- DESCRIPTION
  --     Cets contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     hz_contact_points_PKG.Select_Row
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_edi_rec            Returned EDI record.
  --     x_eft_rec            Returned EFT record.
  --     x_email_rec          Returned email record.
  --     x_phone_rec          Returned phone record.
  --     x_telex_rec          Returned telex record.
  --     x_web_rec            Returned web record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   19-NOV-2001   Joe del Callar      Bug 2116225: Added support for
  --                                     Bank Consolidation.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_contact_point_main (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_edi_rec                   OUT    NOCOPY edi_rec_type,
    x_eft_rec                   OUT    NOCOPY eft_rec_type,
    x_email_rec                 OUT    NOCOPY email_rec_type,
    x_phone_rec                 OUT    NOCOPY phone_rec_type,
    x_telex_rec                 OUT    NOCOPY telex_rec_type,
    x_web_rec                   OUT    NOCOPY web_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS

    l_transposed_phone_number   hz_contact_points.transposed_phone_number%TYPE;
    l_contact_point_rec         hz_contact_points%ROWTYPE;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN
    -- Debug info.

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_main (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    -- Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    -- Check whether primary key has been passed in.
    IF p_contact_point_id IS NULL OR
       p_contact_point_id = fnd_api.g_miss_num THEN
      fnd_message.set_name('AR', 'HZ_API_MISSING_COLUMN');
      fnd_message.set_token('COLUMN', 'contact_point_id');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    x_contact_point_rec.contact_point_id := p_contact_point_id;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'hz_contact_points_PKG.Select_Row (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call table-handler
    hz_contact_points_pkg.select_row (
      x_contact_point_id                => x_contact_point_rec.contact_point_id,
      x_contact_point_type              => x_contact_point_rec.contact_point_type,
      x_status                          => x_contact_point_rec.status,
      x_owner_table_name                => x_contact_point_rec.owner_table_name,
      x_owner_table_id                  => x_contact_point_rec.owner_table_id,
      x_primary_flag                    => x_contact_point_rec.primary_flag,
      x_orig_system_reference           => x_contact_point_rec.orig_system_reference,
      x_attribute_category              => x_contact_point_rec.attribute_category,
      x_attribute1                      => x_contact_point_rec.attribute1,
      x_attribute2                      => x_contact_point_rec.attribute2,
      x_attribute3                      => x_contact_point_rec.attribute3,
      x_attribute4                      => x_contact_point_rec.attribute4,
      x_attribute5                      => x_contact_point_rec.attribute5,
      x_attribute6                      => x_contact_point_rec.attribute6,
      x_attribute7                      => x_contact_point_rec.attribute7,
      x_attribute8                      => x_contact_point_rec.attribute8,
      x_attribute9                      => x_contact_point_rec.attribute9,
      x_attribute10                     => x_contact_point_rec.attribute10,
      x_attribute11                     => x_contact_point_rec.attribute11,
      x_attribute12                     => x_contact_point_rec.attribute12,
      x_attribute13                     => x_contact_point_rec.attribute13,
      x_attribute14                     => x_contact_point_rec.attribute14,
      x_attribute15                     => x_contact_point_rec.attribute15,
      x_attribute16                     => x_contact_point_rec.attribute16,
      x_attribute17                     => x_contact_point_rec.attribute17,
      x_attribute18                     => x_contact_point_rec.attribute18,
      x_attribute19                     => x_contact_point_rec.attribute19,
      x_attribute20                     => x_contact_point_rec.attribute20,
      x_edi_transaction_handling        => x_edi_rec.edi_transaction_handling,
      x_edi_id_number                   => x_edi_rec.edi_id_number,
      x_edi_payment_method              => x_edi_rec.edi_payment_method,
      x_edi_payment_format              => x_edi_rec.edi_payment_format,
      x_edi_remittance_method           => x_edi_rec.edi_remittance_method,
      x_edi_remittance_instruction      => x_edi_rec.edi_remittance_instruction,
      x_edi_tp_header_id                => x_edi_rec.edi_tp_header_id,
      x_edi_ece_tp_location_code        => x_edi_rec.edi_ece_tp_location_code,
      x_eft_transmission_program_id     => x_eft_rec.eft_transmission_program_id,
      x_eft_printing_program_id         => x_eft_rec.eft_printing_program_id,
      x_eft_user_number                 => x_eft_rec.eft_user_number,
      x_eft_swift_code                  => x_eft_rec.eft_swift_code,
      x_email_format                    => x_email_rec.email_format,
      x_email_address                   => x_email_rec.email_address,
      x_phone_calling_calendar          => x_phone_rec.phone_calling_calendar,
      x_last_contact_dt_time            => x_phone_rec.last_contact_dt_time,
      x_timezone_id                     => x_phone_rec.timezone_id,
      x_phone_area_code                 => x_phone_rec.phone_area_code,
      x_phone_country_code              => x_phone_rec.phone_country_code,
      x_phone_number                    => x_phone_rec.phone_number,
      x_phone_extension                 => x_phone_rec.phone_extension,
      x_phone_line_type                 => x_phone_rec.phone_line_type,
      x_telex_number                    => x_telex_rec.telex_number,
      x_web_type                        => x_web_rec.web_type,
      x_url                             => x_web_rec.url,
      x_content_source_type             => x_contact_point_rec.content_source_type,
      x_raw_phone_number                => x_phone_rec.raw_phone_number,
      x_contact_point_purpose           => x_contact_point_rec.contact_point_purpose,
      x_primary_by_purpose              => x_contact_point_rec.primary_by_purpose,
      x_created_by_module               => x_contact_point_rec.created_by_module,
      x_application_id                  => x_contact_point_rec.application_id,
      x_transposed_phone_number         => l_transposed_phone_number,
      x_actual_content_source           => x_contact_point_rec.actual_content_source
    );

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'HZ_CONTACT_POINTS_PKG.Select_Row (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded => fnd_api.g_false,
      p_count => x_msg_count,
      p_data  => x_msg_data);

    -- Debug info.

    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_main (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
  END get_contact_point_main;

  --
  -- PROCEDURE create_contact_point_main
  --
  -- DESCRIPTION
  --     Creates contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     HZ_BUSINESS_EVENT_V2PVT.create_contact_point_event
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_edi_rec            EDI record.
  --     p_eft_rec            EFT record.
  --     p_email_rec          Email record.
  --     p_phone_rec          Phone record.
  --     p_telex_rec          Telex record.
  --     p_web_rec            Web record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      Created.
  --   19-NOV-2001   Joe del Callar      Bug 2116225: Added support for
  --                                     Bank Consolidation.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   01-03-2005  Rajib Ranjan Borah   o SSM SST Integration and Extension.  
  --                                      For non-profile entities, the concept of
  --                                      select/de-select data-sources is obsoleted.

  PROCEDURE create_contact_point_main (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_edi_rec                   IN     edi_rec_type := g_miss_edi_rec,
    p_eft_rec                   IN     eft_rec_type := g_miss_eft_rec,
    p_email_rec                 IN     email_rec_type := g_miss_email_rec,
    p_phone_rec                 IN     phone_rec_type := g_miss_phone_rec,
    p_telex_rec                 IN     telex_rec_type := g_miss_telex_rec,
    p_web_rec                   IN     web_rec_type := g_miss_web_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS

    l_contact_point_rec         contact_point_rec_type := p_contact_point_rec;
    l_edi_rec                   edi_rec_type := p_edi_rec;
    l_email_rec                 email_rec_type := p_email_rec;
    l_phone_rec                 phone_rec_type := p_phone_rec;
    l_telex_rec                 telex_rec_type := p_telex_rec;
    l_web_rec                   web_rec_type := p_web_rec;
    l_eft_rec                   eft_rec_type := p_eft_rec;

    dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    dss_msg_count     NUMBER := 0;
    dss_msg_data      VARCHAR2(2000):= null;
    l_test_security   VARCHAR2(1):= 'F';
    l_debug_prefix    VARCHAR2(30) := '';

  BEGIN
    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point_main (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
       fnd_msg_pub.initialize;
    END IF;

    -- Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    -- Bug 2197181: added for mix-n-match project. first load data
    -- sources for this entity. Then assign the actual_content_source
    -- to the real data source. The value of content_source_type is
    -- depended on if data source is seleted. If it is selected, we reset
    -- content_source_type to user-entered. We also check if user
    -- has the privilege to create user-entered data if mix-n-match
    -- is enabled.

    -- Bug 2444678: Removed caching.

    -- IF g_cpt_mixnmatch_enabled IS NULL THEN
    /*
     * SSM SST Integration and Extension  
     * For non-profile entities, the concept of select/de-select data sources is obsoleted.  
    HZ_MIXNM_UTILITY.LoadDataSources(
      p_entity_name                    => 'HZ_CONTACT_POINTS',
      p_entity_attr_id                 => g_cpt_entity_attr_id,
      p_mixnmatch_enabled              => g_cpt_mixnmatch_enabled,
      p_selected_datasources           => g_cpt_selected_datasources );
    -- END IF;
    */
    HZ_MIXNM_UTILITY.AssignDataSourceDuringCreation (
      p_entity_name                    => 'HZ_CONTACT_POINTS',
      p_entity_attr_id                 => g_cpt_entity_attr_id,
      p_mixnmatch_enabled              => g_cpt_mixnmatch_enabled,
      p_selected_datasources           => g_cpt_selected_datasources,
      p_content_source_type            => l_contact_point_rec.content_source_type,
      p_actual_content_source          => l_contact_point_rec.actual_content_source,
      x_is_datasource_selected         => g_cpt_is_datasource_selected,
      x_return_status                  => x_return_status );

    IF x_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      RAISE FND_API.G_EXC_ERROR;
    END IF;

    -- Call to business logic.
    do_create_contact_point(l_contact_point_rec,
                            l_edi_rec,
                            l_eft_rec,
                            l_email_rec,
                            l_phone_rec,
                            l_telex_rec,
                            l_web_rec,
                            x_contact_point_id,
                            x_return_status);

    -- Bug 2486394 -Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance
    -- Bug 3867562: check dss only in party context

    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' AND
       l_contact_point_rec.owner_table_name IN ('HZ_PARTIES', 'HZ_PARTY_SITES')
    THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'INSERT',
                  p_db_object_name     => 'HZ_CONTACT_POINTS',
                  p_instance_pk1_value => x_contact_point_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
        --
        -- Bug 3835601: replaced the dss message with a more user friendly message
        --
        FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_INSERT_PRIVILEGE');
        IF l_contact_point_rec.owner_table_name = 'HZ_PARTIES' THEN
          FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                                hz_dss_util_pub.get_display_name(null, 'PARTY_CONTACT_POINTS'));
        ELSIF l_contact_point_rec.owner_table_name = 'HZ_PARTY_SITES' THEN
          FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                                hz_dss_util_pub.get_display_name(null, 'PARTY_SITE_CONTACT_POINTS'));
        END IF;
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;
     
    -- Invoke business event system.

    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data sources is obsoleted.
    -- There is no need to check if the data-source is selected.

    IF x_return_status = fnd_api.g_ret_sts_success /*AND
       -- Bug 2197181: Added below condition for Mix-n-Match
      g_cpt_is_datasource_selected = 'Y'*/
    THEN
      IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
        hz_business_event_v2pvt.create_contact_point_event(
          l_contact_point_rec,
          l_edi_rec,
          l_eft_rec,
          l_email_rec,
          l_phone_rec,
          l_telex_rec,
          l_web_rec);
      END IF;

      IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
       -- Add BEGIN, EXCEPTION and END so that regular flow is not
       -- broken if there is nay issue in HZ_POPULATE_BOT_PKG call
       -- Done to facilitate release of GENESIS (11-DEC-2006)
       BEGIN
         HZ_POPULATE_BOT_PKG.pop_hz_contact_points(
           p_operation        => 'I',
           p_contact_point_id => x_contact_point_id);
       EXCEPTION
         WHEN OTHERS THEN
         NULL;
       END;
      END IF;
      -- Call to indicate contact point creation to DQM
      hz_dqm_sync.sync_contact_point(l_contact_point_rec.contact_point_id, 'C');

    END IF;

    -- Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded => fnd_api.g_false,
      p_count => x_msg_count,
      p_data  => x_msg_data);

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point_main (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
  END create_contact_point_main;

  --
  -- PRIVATE PROCEDURE update_contact_point_main
  --
  -- DESCRIPTION
  --     Updates the given contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --     HZ_BUSINESS_EVENT_V2PVT.update_contact_point_main_event
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_edi_rec                EDI record.
  --     p_email_rec              Email record.
  --     p_phone_rec              Phone record.
  --     p_telex_rec              Telex record.
  --     p_web_rec                Web record.
  --     p_eft_rec                EFT record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      Created.
  --   19-NOV-2001   Joe del Callar      Bug 2116225: Added support for
  --                                     Bank Consolidation.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   06-JUL-2004   Rajib Ranjan Borah  Bug 3711740.If phone_area_code/
  --                                     phone_country_code is null, then do
  --                                     not assign the old value before calling
  --                                     hz_timezone_pub.get_phone_timezone_id.

  PROCEDURE update_contact_point_main (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_edi_rec                   IN     edi_rec_type := g_miss_edi_rec,
    p_eft_rec                   IN     eft_rec_type := g_miss_eft_rec,
    p_email_rec                 IN     email_rec_type := g_miss_email_rec,
    p_phone_rec                 IN     phone_rec_type := g_miss_phone_rec,
    p_telex_rec                 IN     telex_rec_type := g_miss_telex_rec,
    p_web_rec                   IN     web_rec_type := g_miss_web_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS

    l_contact_point_rec         contact_point_rec_type := p_contact_point_rec;
    l_edi_rec                   edi_rec_type := p_edi_rec;
    l_email_rec                 email_rec_type := p_email_rec;
    l_phone_rec                 phone_rec_type := p_phone_rec;
    l_telex_rec                 telex_rec_type := p_telex_rec;
    l_web_rec                   web_rec_type := p_web_rec;
    l_eft_rec                   eft_rec_type := p_eft_rec;

    l_old_contact_point_rec     contact_point_rec_type;
    l_old_edi_rec               edi_rec_type;
    l_old_email_rec             email_rec_type;
    l_old_phone_rec             phone_rec_type;
    l_old_telex_rec             telex_rec_type;
    l_old_web_rec               web_rec_type;
    l_old_eft_rec               eft_rec_type;
    l_phone_country_code        HZ_CONTACT_POINTS.phone_country_code%type;
    l_phone_area_code           HZ_CONTACT_POINTS.phone_area_code%type;

    l_data_source_from          VARCHAR2(30);

    dss_return_status VARCHAR2(1) := FND_API.G_RET_STS_SUCCESS;
    dss_msg_count     NUMBER := 0;
    dss_msg_data      VARCHAR2(2000):= null;
    l_test_security   VARCHAR2(1):= 'F';

    l_return_status             VARCHAR2(1);
    l_msg_count                 NUMBER;
    l_message_count number;
    l_msg_data                  VARCHAR2(2000);
    l_changed_flag varchar2(1) := 'N';
    l_debug_prefix              VARCHAR2(30) := '';

  BEGIN
    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point_main (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    -- Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

        -- if contact_point_id is not passed in, but orig system parameters are passed in
    -- get contact_point_id

      IF (p_contact_point_rec.orig_system is not null
         and p_contact_point_rec.orig_system <>fnd_api.g_miss_char)
       and (p_contact_point_rec.orig_system_reference is not null
         and p_contact_point_rec.orig_system_reference <>fnd_api.g_miss_char)
       and (p_contact_point_rec.contact_point_id = FND_API.G_MISS_NUM or p_contact_point_rec.contact_point_id is null) THEN
           hz_orig_system_ref_pub.get_owner_table_id
                        (p_orig_system => p_contact_point_rec.orig_system,
                        p_orig_system_reference => p_contact_point_rec.orig_system_reference,
                        p_owner_table_name => 'HZ_CONTACT_POINTS',
                        x_owner_table_id => l_contact_point_rec.contact_point_id,
                        x_return_status => x_return_status);
            IF x_return_status <> fnd_api.g_ret_sts_success THEN
                RAISE FND_API.G_EXC_ERROR;
            END IF;
      END IF;


    -- Get old records. Will be used by business event system.
    get_contact_point_main (
      p_contact_point_id               => l_contact_point_rec.contact_point_id,
      x_contact_point_rec              => l_old_contact_point_rec,
      x_edi_rec                        => l_old_edi_rec,
      x_eft_rec                        => l_old_eft_rec,
      x_email_rec                      => l_old_email_rec,
      x_phone_rec                      => l_old_phone_rec,
      x_telex_rec                      => l_old_telex_rec,
      x_web_rec                        => l_old_web_rec,
      x_return_status                  => x_return_status,
      x_msg_count                      => x_msg_count,
      x_msg_data                       => x_msg_data);

    IF x_return_status = fnd_api.g_ret_sts_error THEN
      RAISE fnd_api.g_exc_error;
    ELSIF x_return_status = fnd_api.g_ret_sts_unexp_error THEN
      RAISE fnd_api.g_exc_unexpected_error;
    END IF;

    -- Bug 2486394 -Check if the DSS security is granted to the user
    -- Bug 3818648: check dss profile before call test_instance
    -- Bug 3867562: check dss only in party context

    IF NVL(fnd_profile.value('HZ_DSS_ENABLED'), 'N') = 'Y' AND
       l_old_contact_point_rec.owner_table_name IN ('HZ_PARTIES', 'HZ_PARTY_SITES')
    THEN
      l_test_security :=
           hz_dss_util_pub.test_instance(
                  p_operation_code     => 'UPDATE',
                  p_db_object_name     => 'HZ_CONTACT_POINTS',
                  p_instance_pk1_value => l_contact_point_rec.contact_point_id,
                  p_user_name          => fnd_global.user_name,
                  x_return_status      => dss_return_status,
                  x_msg_count          => dss_msg_count,
                  x_msg_data           => dss_msg_data);

      if dss_return_status <> fnd_api.g_ret_sts_success THEN
         RAISE FND_API.G_EXC_ERROR;
      end if;

      if (l_test_security <> 'T' OR l_test_security <> FND_API.G_TRUE) then
        --
        -- Bug 3835601: replaced the dss message with a more user friendly message
        --
        FND_MESSAGE.SET_NAME('AR', 'HZ_DSS_NO_UPDATE_PRIVILEGE');
        IF l_old_contact_point_rec.owner_table_name = 'HZ_PARTIES' THEN
          FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                                hz_dss_util_pub.get_display_name(null, 'PARTY_CONTACT_POINTS'));
        ELSIF l_old_contact_point_rec.owner_table_name = 'HZ_PARTY_SITES' THEN
          FND_MESSAGE.SET_TOKEN('ENTITY_NAME',
                                hz_dss_util_pub.get_display_name(null, 'PARTY_SITE_CONTACT_POINTS'));
        END IF;
        FND_MSG_PUB.ADD;
        RAISE FND_API.G_EXC_ERROR;
      end if;
    END IF;

    -- Bug 2197181: added for mix-n-match project. first load data
    -- sources for this entity.

    -- Bug 2444678: Removed caching.

    /* SSM SST Integration and Extension
     * For non-profile entities, the concept of select/de-select data-sources is obsoleted.
     * There is no need to check if the data-source is selected.

    -- IF g_cpt_mixnmatch_enabled IS NULL THEN
    HZ_MIXNM_UTILITY.LoadDataSources(
      p_entity_name                    => 'HZ_CONTACT_POINTS',
      p_entity_attr_id                 => g_cpt_entity_attr_id,
      p_mixnmatch_enabled              => g_cpt_mixnmatch_enabled,
      p_selected_datasources           => g_cpt_selected_datasources );
    -- END IF;
    */
    
    -- Bug 2197181: added for mix-n-match project.
    -- check if the data source is seleted.
    /* SSM SST Integration and Extension
     * For non-profile entities, the concept of select/de-select data-sources is obsoleted.
     * There is no need to check if the data-source is selected. 
     
    g_cpt_is_datasource_selected :=
      HZ_MIXNM_UTILITY.isDataSourceSelected (
        p_selected_datasources           => g_cpt_selected_datasources,
        p_actual_content_source          => l_old_contact_point_rec.actual_content_source );
    */   
    if (l_phone_rec.phone_country_code IS NOT NULL
           and l_phone_rec.phone_country_code <> nvl(l_old_phone_rec.phone_country_code,fnd_api.g_miss_char))
           or (l_phone_rec.phone_area_code is NOT NULL and l_phone_rec.phone_area_code <> nvl(l_old_phone_rec.phone_area_code,fnd_api.g_miss_char))
    then
        l_changed_flag := 'Y';
    end if;

    if l_changed_flag = 'Y' and ( l_phone_rec.timezone_id is null or l_phone_rec.timezone_id = fnd_api.g_miss_num)
    then
                if l_phone_rec.phone_country_code IS NULL
                then
                        l_phone_country_code := l_old_phone_rec.phone_country_code;
                else
                        l_phone_country_code := l_phone_rec.phone_country_code;
                end if;

                if l_phone_rec.phone_area_code IS NULL
                then
                        l_phone_area_code := l_old_phone_rec.phone_area_code;
                else
                        l_phone_area_code := l_phone_rec.phone_area_code;
                end if;
                 l_message_count := fnd_msg_pub.count_msg();
                 hz_timezone_pub.get_phone_timezone_id(
                        p_api_version => 1.0,
                        p_init_msg_list => FND_API.G_FALSE,
                        p_phone_country_code => l_phone_country_code,
                        p_area_code => l_phone_area_code,
                        p_phone_prefix => null,
                        p_country_code => null,-- don't need to pass in this
                        x_timezone_id => l_phone_rec.timezone_id,
                        x_return_status => l_return_status ,
                        x_msg_count =>l_msg_count ,
                        x_msg_data => l_msg_data);
                        if l_return_status <> fnd_api.g_ret_sts_success
                        then  -- we don't raise error
                                l_phone_rec.timezone_id := fnd_api.g_miss_num;
                                FOR i IN 1..(l_msg_count - l_message_count) LOOP
                                    fnd_msg_pub.delete_msg(l_msg_count - l_message_count + 1 - i);
                                END LOOP;
                                l_return_status := FND_API.G_RET_STS_SUCCESS;
                        end if;
     end if;

    -- Call to business logic.
    do_update_contact_point (
      l_contact_point_rec,
      l_edi_rec,
      l_eft_rec,
      l_email_rec,
      l_phone_rec,
      l_telex_rec,
      l_web_rec,
      p_object_version_number,
      x_return_status);

    IF x_return_status = fnd_api.g_ret_sts_success THEN
      update_contact_point_search(l_old_contact_point_rec,
                                  l_old_phone_rec,
                                  l_phone_rec,
                                  l_old_email_rec,
                                  l_email_rec
                                 );
    END IF;

    -- SSM SST Integration and Extension
    -- For non-profile entities, the concept of select/de-select data-sources is obsoleted.
    -- There is no need to check if the data-source is selected.
    
    -- Invoke business event system.
    IF x_return_status = fnd_api.g_ret_sts_success /*AND
       -- Bug 2197181: Added below condition for Mix-n-Match
      g_cpt_is_datasource_selected = 'Y'*/
    THEN
      l_old_contact_point_rec.orig_system := p_contact_point_rec.orig_system;
      IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('Y', 'EVENTS_ENABLED')) THEN
        hz_business_event_v2pvt.update_contact_point_event (
          l_contact_point_rec,
          l_old_contact_point_rec,
          l_edi_rec,
          l_old_edi_rec,
          l_eft_rec,
          l_old_eft_rec,
          l_email_rec,
          l_old_email_rec,
          l_phone_rec,
          l_old_phone_rec,
          l_telex_rec,
          l_old_telex_rec,
          l_web_rec,
          l_old_web_rec);
      END IF;

      IF(HZ_UTILITY_V2PUB.G_EXECUTE_API_CALLOUTS in ('EVENTS_ENABLED', 'BO_EVENTS_ENABLED')) THEN
       -- Add BEGIN, EXCEPTION and END so that regular flow is not
       -- broken if there is nay issue in HZ_POPULATE_BOT_PKG call
       -- Done to facilitate release of GENESIS (11-DEC-2006)
       BEGIN
         HZ_POPULATE_BOT_PKG.pop_hz_contact_points(
           p_operation        => 'U',
           p_contact_point_id => l_contact_point_rec.contact_point_id);
       EXCEPTION
         WHEN OTHERS THEN
         NULL;
       END;
      END IF;
      -- Call to indicate contact point update to DQM
      hz_dqm_sync.sync_contact_point(l_contact_point_rec.contact_point_id, 'U');

    END IF;

    -- Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(
      p_encoded => fnd_api.g_false,
      p_count => x_msg_count,
      p_data  => x_msg_data);

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point_main (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;
  END update_contact_point_main;

  --------------------------------------
  -- public procedures and functions
  --------------------------------------

  --
  -- PROCEDURE create_contact_point
  --
  -- DESCRIPTION
  --     Creates a contact point.  Still here for backward compatibility.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_edi_rec            EDI record.
  --     p_email_rec          Email record.
  --     p_phone_rec          Phone record.
  --     p_telex_rec          Telex record.
  --     p_web_rec            Web record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --
  --   28-NOV-2006   Nabarun Ghosh       OD Enhancment: Added custom business logic
  --                                     to validate email address format being
  --                                     created / updated as contact points.
  --
  --   31-Jul-2007   Prem Kumar B        Condition to check for profile value before calling
  --                                     the email validation procedure.
  --
  

  PROCEDURE create_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_edi_rec                   IN     edi_rec_type := g_miss_edi_rec,
    p_email_rec                 IN     email_rec_type := g_miss_email_rec,
    p_phone_rec                 IN     phone_rec_type := g_miss_phone_rec,
    p_telex_rec                 IN     telex_rec_type := g_miss_telex_rec,
    p_web_rec                   IN     web_rec_type := g_miss_web_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  
  --Declared local variables needed for OD custom code
  l_return_status    VARCHAR2(10);
  l_msg_count        NUMBER;   
  l_msg_data      VARCHAR2(100);
  l_contact_points_rec  CONTACT_POINT_REC_TYPE  := p_contact_point_rec;
  l_edi_rec             EDI_REC_TYPE      := p_edi_rec;
  l_email_rec           EMAIL_REC_TYPE       := p_email_rec;
  l_phone_rec           PHONE_REC_TYPE    := p_phone_rec;
  l_telex_rec           TELEX_REC_TYPE    := p_telex_rec;
  l_web_rec             WEB_REC_TYPE      := p_web_rec; 

  
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_contact_point;


    -- Call to the OD Custom package to implement Custom business logic to validate 
    -- the email addresses format.
    
    -- Commented on 25-Apr-07,Prem. Redundant as this is done in the custom package
    -- IF l_contact_points_rec.contact_point_type = 'EMAIL' THEN
    
      IF ( NVL( FND_PROFILE.VALUE('XX_CDH_CUST_EMAIL_FORMAT'),'N') = 'Y' ) THEN    
   
         XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => l_contact_points_rec,
               p_edi_rec            => l_edi_rec,
               p_email_rec          => l_email_rec,
               p_phone_rec          => l_phone_rec,
               p_telex_rec          => l_telex_rec,
               p_web_rec            => l_web_rec,
               x_return_status      => l_return_status,
               x_msg_count          => l_msg_count,
               x_msg_data           => l_msg_data);

         IF NVL(l_return_status,'X') = FND_API.G_RET_STS_ERROR THEN
            FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
            --FND_MESSAGE.SET_TOKEN ('ERROR', l_msg_data);
            FND_MSG_PUB.ADD;
            RAISE FND_API.G_EXC_ERROR;
         END IF;
      
      END IF;
      
   --END IF;   

    -- End of call to the OD custom package   



    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_edi_rec                 => p_edi_rec,
      p_email_rec               => p_email_rec,
      p_phone_rec               => p_phone_rec,
      p_telex_rec               => p_telex_rec,
      p_web_rec                 => p_web_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_contact_point;

  --
  -- PROCEDURE create_edi_contact_point
  --
  -- DESCRIPTION
  --     Creates an EDI contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_edi_rec            EDI record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE create_edi_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_edi_rec                   IN     edi_rec_type := g_miss_edi_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_edi_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_edi_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_edi_rec                 => p_edi_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_edi_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_edi_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_edi_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_edi_contact_point;

  --
  -- PROCEDURE create_web_contact_point
  --
  -- DESCRIPTION
  --     Creates a Web contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_web_rec            Web record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE create_web_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_web_rec                   IN     web_rec_type := g_miss_web_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_web_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_web_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_web_rec                 => p_web_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_web_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_web_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_web_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_web_contact_point;

  --
  -- PROCEDURE create_eft_contact_point
  --
  -- DESCRIPTION
  --     Creates an EFT contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_eft_rec            EFT record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --                                     Bug 2100992: Added for bank
  --                                     consolidation support.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE create_eft_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_eft_rec                   IN     eft_rec_type := g_miss_eft_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_eft_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_eft_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_eft_rec                 => p_eft_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_eft_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_eft_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_eft_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_eft_contact_point;

  --
  -- PROCEDURE create_phone_contact_point
  --
  -- DESCRIPTION
  --     Creates a phone contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_phone_rec          Phone record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE create_phone_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_phone_rec                 IN     phone_rec_type := g_miss_phone_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_phone_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_phone_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_phone_rec               => p_phone_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_phone_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_phone_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_phone_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_phone_contact_point;

  --
  -- PROCEDURE create_telex_contact_point
  --
  -- DESCRIPTION
  --     Creates a telex contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_telex_rec          Telex record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE create_telex_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_telex_rec                 IN     telex_rec_type := g_miss_telex_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_telex_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_telex_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_telex_rec               => p_telex_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_telex_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_telex_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_telex_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_telex_contact_point;

  --
  -- PROCEDURE create_email_contact_point
  --
  -- DESCRIPTION
  --     Creates a email contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is FND_API.G_FALSE.
  --     p_contact_point_rec  Contact point record.
  --     p_email_rec          Email record.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_id   Contact point ID.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE create_email_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_email_rec                 IN     email_rec_type := g_miss_email_rec,
    x_contact_point_id          OUT NOCOPY    NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT create_email_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_email_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Call to the main business logic.
    create_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_email_rec               => p_email_rec,
      x_contact_point_id        => x_contact_point_id,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO create_email_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO create_email_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO create_email_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'create_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END create_email_contact_point;

  --
  -- PRIVATE PROCEDURE update_contact_point
  --
  -- DESCRIPTION
  --     Updates the given contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_edi_rec                EDI record.
  --     p_email_rec              Email record.
  --     p_phone_rec              Phone record.
  --     p_telex_rec              Telex record.
  --     p_web_rec                Web record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --   28-NOV-2006   Nabarun Ghosh       OD Enhancment: Added custom business logic
  --                                     to validate email address format being
  --                                     created / updated as contact points.
  --
  --   31-Jul-2007   Prem Kumar B        Condition to check for profile value before calling
  --                                     the email validation procedure.
  --

  PROCEDURE update_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_edi_rec                   IN     edi_rec_type := g_miss_edi_rec,
    p_email_rec                 IN     email_rec_type := g_miss_email_rec,
    p_phone_rec                 IN     phone_rec_type := g_miss_phone_rec,
    p_telex_rec                 IN     telex_rec_type := g_miss_telex_rec,
    p_web_rec                   IN     web_rec_type := g_miss_web_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';

  --Declared local variables needed for OD custom code
  l_return_status       VARCHAR2(10);
  l_msg_count           NUMBER;   
  l_msg_data            VARCHAR2(100);
  l_contact_points_rec  CONTACT_POINT_REC_TYPE  := p_contact_point_rec;
  l_edi_rec             EDI_REC_TYPE            := p_edi_rec;
  l_email_rec           EMAIL_REC_TYPE          := p_email_rec;
  l_phone_rec           PHONE_REC_TYPE          := p_phone_rec;
  l_telex_rec           TELEX_REC_TYPE          := p_telex_rec;
  l_web_rec             WEB_REC_TYPE            := p_web_rec; 
  
  BEGIN

    -- Standard start of API savepoint
    SAVEPOINT update_contact_point;

    -- Call to the OD Custom package to implement Custom business logic to validate 
    -- the email addresses format.
    
      IF ( NVL( FND_PROFILE.VALUE('XX_CDH_CUST_EMAIL_FORMAT'),'N') = 'Y' ) THEN
   
         XX_CDH_CUSTEMAILFMT_PKG.Validate_Customer_Email_Format (
               p_contact_points_rec => l_contact_points_rec,
               p_edi_rec            => l_edi_rec,
               p_email_rec          => l_email_rec,
               p_phone_rec          => l_phone_rec,
               p_telex_rec          => l_telex_rec,
               p_web_rec            => l_web_rec,
               x_return_status      => l_return_status,
               x_msg_count          => l_msg_count,
               x_msg_data           => l_msg_data);

         IF NVL(l_return_status,'X') = FND_API.G_RET_STS_ERROR THEN
            FND_MESSAGE.SET_NAME('XXCRM','XXOD_INVALID_EMAIL');
            --FND_MESSAGE.SET_TOKEN ('ERROR', l_msg_data);
            FND_MSG_PUB.ADD;
            RAISE FND_API.G_EXC_ERROR;
         END IF;
      
      END IF;

    -- End of call to the OD custom package 
 
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_edi_rec                 => p_edi_rec,
      p_email_rec               => p_email_rec,
      p_phone_rec               => p_phone_rec,
      p_telex_rec               => p_telex_rec,
      p_web_rec                 => p_web_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_contact_point;

  --
  -- PROCEDURE update_edi_contact_point
  --
  -- DESCRIPTION
  --     Updates the given EDI contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_edi_rec                EDI record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE update_edi_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_edi_rec                   IN     edi_rec_type := g_miss_edi_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_edi_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_edi_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_edi_rec                 => p_edi_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_edi_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
     IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
     END IF;
     IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
     END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_edi_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_edi_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_edi_contact_point;

  --
  -- PROCEDURE update_web_contact_point
  --
  -- DESCRIPTION
  --     Updates the given Web contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_web_rec                WEB record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE update_web_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_web_rec                   IN     web_rec_type := g_miss_web_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                VARCHAR2(30) := '';
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_web_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_web_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_web_rec                 => p_web_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_web_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_web_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_web_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_web_contact_point;

  --
  -- PROCEDURE update_eft_contact_point
  --
  -- DESCRIPTION
  --     Updates the given EFT contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_eft_rec                EFT record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   19-NOV-2001   Joe del Callar      Bug 2116225: Added to support
  --                                     Bank Consolidation.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE update_eft_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_eft_rec                   IN     eft_rec_type := g_miss_eft_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_eft_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_eft_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_eft_rec                 => p_eft_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_eft_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_eft_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_eft_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_eft_contact_point;

  --
  -- PROCEDURE update_phone_contact_point
  --
  -- DESCRIPTION
  --     Updates the given phone contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_phone_rec              Phone record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE update_phone_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_phone_rec                   IN     phone_rec_type := g_miss_phone_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_phone_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_phone_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_phone_rec               => p_phone_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_phone_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_phone_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_phone_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_phone_contact_point;

  --
  -- PROCEDURE update_telex_contact_point
  --
  -- DESCRIPTION
  --     Updates the given telex contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_telex_rec              Telex record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE update_telex_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_telex_rec                   IN     telex_rec_type := g_miss_telex_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_telex_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_telex_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_telex_rec               => p_telex_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_telex_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;



      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_telex_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_telex_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_telex_contact_point;

  --
  -- PROCEDURE update_email_contact_point
  --
  -- DESCRIPTION
  --     Updates the given email contact point.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_rec      Contact point record.
  --     p_email_rec              Email record.
  --   IN/OUT:
  --     p_object_version_number  Used for locking the being updated record.
  --   OUT:
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              FND_API.G_RET_STS_UNEXP_ERROR (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added to support
  --                                     enhanced backward compatibility.
  --   04-FEB-2001   Joe del Callar      Bug 2211876: Fixed issue with error
  --                                     status and message data getting set
  --                                     incorrectly in update and create
  --                                     contact point APIs.
  --

  PROCEDURE update_email_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_rec         IN     contact_point_rec_type,
    p_email_rec                 IN     email_rec_type := g_miss_email_rec,
    p_object_version_number     IN OUT NOCOPY NUMBER,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
  l_debug_prefix                       VARCHAR2(30) := '';
  BEGIN
    -- Standard start of API savepoint
    SAVEPOINT update_email_contact_point;

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_email_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- call main business logic.
    update_contact_point_main(
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_rec       => p_contact_point_rec,
      p_email_rec               => p_email_rec,
      p_object_version_number   => p_object_version_number,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      ROLLBACK TO update_email_contact_point;
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      ROLLBACK TO update_email_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      ROLLBACK TO update_email_contact_point;
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'update_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END update_email_contact_point;

  --
  -- PROCEDURE phone_format
  --
  -- DESCRIPTION
  --      formats a phone number
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list          Initialize message stack if it is set to
  --                              FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_raw_phone_number       Raw phone number.
  --     p_territory_code         Territory code.
  --   IN/OUT:
  --     x_phone_country_code     Phone country code.
  --     x_phone_area_code        Phone area code.
  --     x_phone_number           Phone number.
  --   OUT:
  --     x_formatted_phone_number Formatted phone number.
  --     x_return_status          Return status after the call. The status can
  --                              be fnd_api.g_ret_sts_success (success),
  --                              fnd_api.g_ret_sts_error (error),
  --                              fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count              Number of messages in message stack.
  --     x_msg_data               Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   02-05-2002    Jyoti Pandey        o Modified the parsing and formatting
  --                                       logic for Phone Normalization and Parsing
  --                                       project in version 115.9
  --
  --

  PROCEDURE phone_format (
    p_init_msg_list                     IN     VARCHAR2 := fnd_api.g_false,
    p_raw_phone_number                  IN     VARCHAR2 := fnd_api.g_miss_char,
    p_territory_code                    IN     VARCHAR2 := fnd_api.g_miss_char,
    x_formatted_phone_number            OUT NOCOPY    VARCHAR2,
    x_phone_country_code                IN OUT NOCOPY VARCHAR2,
    x_phone_area_code                   IN OUT NOCOPY VARCHAR2,
    x_phone_number                      IN OUT NOCOPY VARCHAR2,
    x_return_status                     OUT NOCOPY    VARCHAR2,
    x_msg_count                         OUT NOCOPY    NUMBER,
    x_msg_data                          OUT NOCOPY    VARCHAR2
  ) IS
    l_formatted_phone_number            VARCHAR2(100);
    l_phone_area_code                   VARCHAR2(30);
    l_phone_number                      VARCHAR2(30);
    l_phone_format_style                VARCHAR2(100);
    l_raw_phone_number                  VARCHAR2(100);
    l_phone_country_code                VARCHAR2(100);
    l_format_raw_phone                  BOOLEAN := FALSE;
    l_format_area_phone                 BOOLEAN := FALSE;
    l_include_country_code              BOOLEAN;
    l_area_code_size                    NUMBER;
    l_msg_name                          VARCHAR2(50) := NULL;
    l_territory_code                    VARCHAR2(30) := NULL;
    x_mobile_flag                       VARCHAR2(1)  := NULL;

    CURSOR c_territory(p_country_code VARCHAR2) IS
      SELECT territory_code
      FROM   hz_phone_country_codes
      WHERE  phone_country_code = p_country_code;

    l_debug_prefix                     VARCHAR2(30) := '';

  BEGIN
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'phone_format (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Initialize message list if p_init_msg_list is set to TRUE.
    IF fnd_api.to_boolean(p_init_msg_list) THEN
      fnd_msg_pub.initialize;
    END IF;

    -- Initialize API return status to success.
    x_return_status := fnd_api.g_ret_sts_success;

    -- Check if raw phone number is to be formatted
    IF p_raw_phone_number IS NOT NULL AND
       p_raw_phone_number <> fnd_api.g_miss_char THEN
      l_format_raw_phone := TRUE;
    END IF;

    -- Or Check if the area_code/phone number combination is to be formatted
    IF ((x_phone_number IS NOT NULL AND
           x_phone_number <> fnd_api.g_miss_char) OR
         (x_phone_area_code IS NOT NULL AND
           x_phone_area_code <> fnd_api.g_miss_char))
    THEN
      l_format_area_phone := TRUE;
    END IF;

    -- If neither need to be formatted or both need to be
    -- formatted, error out NOCOPY
    IF (l_format_raw_phone AND l_format_area_phone) OR
       (NOT l_format_raw_phone AND NOT l_format_area_phone)
    THEN
      fnd_message.set_name('AR', 'HZ_INVALID_PHONE_PARAMETER');
      fnd_msg_pub.add;
      RAISE fnd_api.g_exc_error;
    END IF;

    -- If not format a raw phone number, then create a raw phone
    -- number by appending the area code and phone number. This will
    -- allow use of common logic for both

    IF l_format_raw_phone THEN
       l_raw_phone_number := p_raw_phone_number;
    ELSIF l_format_area_phone THEN
      IF x_phone_area_code IS NULL OR
         x_phone_area_code = fnd_api.g_miss_char THEN
        l_raw_phone_number := filter_phone_number(x_phone_number);
      ELSE
        l_raw_phone_number := filter_phone_number(x_phone_area_code ||
                                                   x_phone_number);
      END IF;
    END IF;

    -- If Country code has been passed query the territory code for the
    -- country. If country code has not been passed, use territory_code.

    IF x_phone_country_code IS NOT NULL AND
       x_phone_country_code <> fnd_api.g_miss_char
    THEN
      OPEN c_territory(x_phone_country_code);
      FETCH c_territory INTO l_territory_code;
      IF c_territory%NOTFOUND THEN
        l_territory_code := NULL;
      END IF;
      CLOSE c_territory;
    ELSIF p_territory_code IS NOT NULL AND
          p_territory_code <> fnd_api.g_miss_char THEN
      l_territory_code := p_territory_code;
    ELSE
      l_territory_code := NULL;
    END IF;

   --Following commented code is replaced by parsing and displaying logic in
   --HZ_FORMAT_PHONE_V2PUB's phone_parse and phone_display. This was done in
   -- version 115.9 for Phone normalization and parsing project

   --Call to phone_parse to get parsed components
    HZ_FORMAT_PHONE_V2PUB.phone_parse (
    fnd_api.g_true      ,
    l_raw_phone_number  ,
    p_territory_code ,
    x_phone_country_code  ,
    x_phone_area_code    ,
    x_phone_number  ,
    x_mobile_flag ,
    x_return_status,
    x_msg_count,
    x_msg_data);

    --Parsed components are i/p to phone_display to get formateed number
    HZ_FORMAT_PHONE_V2PUB.phone_display(
    fnd_api.g_true                   ,
    p_territory_code,
    x_phone_country_code     ,
    x_phone_area_code        ,
    x_phone_number           ,
    x_formatted_phone_number ,
    x_return_status                  ,
    x_msg_count                 ,
    x_msg_data                  );

   /* -- Cannot get territory code, error out NOCOPY
   | IF l_territory_code IS NULL THEN
   |   fnd_message.set_name('AR', 'HZ_COUNTRY_CODE_NOT_DEFINED');
   |   fnd_msg_pub.add;
   |   RAISE fnd_api.g_exc_error;
   | END IF;
   |
   | -- Call subroutine to get the format style to be applied for the given
   | -- raw phone number and territory
   | get_phone_format(
   |   p_raw_phone_number                      => l_raw_phone_number,
   |   p_territory_code                        => l_territory_code,
   |   p_area_code                             => x_phone_area_code,
   |   x_phone_country_code                    => l_phone_country_code,
   |   x_phone_format_style                    => l_phone_format_style,
   |   x_area_code_size                        => l_area_code_size,
   |   x_include_country_code                  => l_include_country_code,
   |   x_msg                                   => l_msg_name);
   |
   | -- Check for errors in identifying format style
   | IF l_msg_name IS NOT NULL THEN
   |   fnd_message.set_name('AR', l_msg_name);
   |   fnd_msg_pub.add;
   |   RAISE fnd_api.g_exc_error;
   | END IF;
   |
   | -- Apply the format style and get translated number
   | translate_raw_phone_number (
   |   p_raw_phone_number                     => l_raw_phone_number,
   |   p_phone_format_style                   => l_phone_format_style,
   |   p_area_code_size                       => l_area_code_size,
   |   x_formatted_phone_number               => l_formatted_phone_number,
   |   x_phone_area_code                      => l_phone_area_code,
   |   x_phone_number                         => l_phone_number);
   |
   | -- Append country code if desired
   | IF l_include_country_code THEN
   |   x_formatted_phone_number := '+' || l_phone_country_code ||
   |                               ' ' || l_formatted_phone_number;
   | ELSE
   |   x_formatted_phone_number := l_formatted_phone_number;
   | END IF;
   |
   | -- Set the seperated area code and phone number for return
   | IF l_format_raw_phone THEN
   |   x_phone_area_code := l_phone_area_code;
   |   x_phone_number := l_phone_number;
   | END IF;
   |
   | x_phone_country_code := l_phone_country_code; */

    -- Standard call to get message count and if count is 1, get message info.
    fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                              p_count => x_msg_count,
                              p_data  => x_msg_data);

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'phone_format (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'phone_format (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'phone_format (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'phone_format (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

  END phone_format;

  --
  -- PROCEDURE get_contact_point_rec
  --
  -- DESCRIPTION
  --     Gets contact point record.  Still here for backward compatibility.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_edi_rec            Returned EDI record.
  --     x_email_rec          Returned email record.
  --     x_phone_rec          Returned phone record.
  --     x_telex_rec          Returned telex record.
  --     x_web_rec            Returned web record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   19-NOV-2001   Joe del Callar      Bug 2116225: Added support for
  --                                     Bank Consolidation.
  --

  PROCEDURE get_contact_point_rec (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_edi_rec                   OUT    NOCOPY edi_rec_type,
    x_email_rec                 OUT    NOCOPY email_rec_type,
    x_phone_rec                 OUT    NOCOPY phone_rec_type,
    x_telex_rec                 OUT    NOCOPY telex_rec_type,
    x_web_rec                   OUT    NOCOPY web_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_eft_rec                   eft_rec_type := g_miss_eft_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_rec (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => x_edi_rec,
      x_eft_rec                 => l_eft_rec,
      x_email_rec               => x_email_rec,
      x_phone_rec               => x_phone_rec,
      x_telex_rec               => x_telex_rec,
      x_web_rec                 => x_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_rec (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_rec (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_rec (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_contact_point_rec (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_contact_point_rec;

  --
  -- PROCEDURE get_edi_contact_point
  --
  -- DESCRIPTION
  --     Gets EDI contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_edi_rec            Returned EDI record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_edi_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_edi_rec                   OUT    NOCOPY edi_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_eft_rec                   eft_rec_type := g_miss_eft_rec;
    l_web_rec                   web_rec_type := g_miss_web_rec;
    l_phone_rec                 phone_rec_type := g_miss_phone_rec;
    l_telex_rec                 telex_rec_type := g_miss_telex_rec;
    l_email_rec                 email_rec_type := g_miss_email_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_edi_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => x_edi_rec,
      x_eft_rec                 => l_eft_rec,
      x_email_rec               => l_email_rec,
      x_phone_rec               => l_phone_rec,
      x_telex_rec               => l_telex_rec,
      x_web_rec                 => l_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_edi_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_edi_contact_point;

  --
  -- PROCEDURE get_eft_contact_point
  --
  -- DESCRIPTION
  --     Gets EFT contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_eft_rec            Returned EFT record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_eft_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_eft_rec                   OUT    NOCOPY eft_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_edi_rec                   edi_rec_type := g_miss_edi_rec;
    l_web_rec                   web_rec_type := g_miss_web_rec;
    l_phone_rec                 phone_rec_type := g_miss_phone_rec;
    l_telex_rec                 telex_rec_type := g_miss_telex_rec;
    l_email_rec                 email_rec_type := g_miss_email_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_eft_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => l_edi_rec,
      x_eft_rec                 => x_eft_rec,
      x_email_rec               => l_email_rec,
      x_phone_rec               => l_phone_rec,
      x_telex_rec               => l_telex_rec,
      x_web_rec                 => l_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );


    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_eft_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_eft_contact_point;

  --
  -- PROCEDURE get_web_contact_point
  --
  -- DESCRIPTION
  --     Gets Web contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_web_rec            Returned Web record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_web_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_web_rec                   OUT    NOCOPY web_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_edi_rec                   edi_rec_type := g_miss_edi_rec;
    l_eft_rec                   eft_rec_type := g_miss_eft_rec;
    l_phone_rec                 phone_rec_type := g_miss_phone_rec;
    l_telex_rec                 telex_rec_type := g_miss_telex_rec;
    l_email_rec                 email_rec_type := g_miss_email_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN

    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_web_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => l_edi_rec,
      x_eft_rec                 => l_eft_rec,
      x_email_rec               => l_email_rec,
      x_phone_rec               => l_phone_rec,
      x_telex_rec               => l_telex_rec,
      x_web_rec                 => x_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;


      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_web_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_web_contact_point;

  --
  -- PROCEDURE get_phone_contact_point
  --
  -- DESCRIPTION
  --     Gets phone contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_phone_rec          Returned phone record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_phone_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_phone_rec                   OUT    NOCOPY phone_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_edi_rec                   edi_rec_type := g_miss_edi_rec;
    l_eft_rec                   eft_rec_type := g_miss_eft_rec;
    l_web_rec                   web_rec_type := g_miss_web_rec;
    l_telex_rec                 telex_rec_type := g_miss_telex_rec;
    l_email_rec                 email_rec_type := g_miss_email_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => l_edi_rec,
      x_eft_rec                 => l_eft_rec,
      x_email_rec               => l_email_rec,
      x_phone_rec               => x_phone_rec,
      x_telex_rec               => l_telex_rec,
      x_web_rec                 => l_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_phone_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_phone_contact_point;

  --
  -- PROCEDURE get_telex_contact_point
  --
  -- DESCRIPTION
  --     Gets telex contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_telex_rec          Returned telex record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_telex_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_telex_rec                   OUT    NOCOPY telex_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_edi_rec                   edi_rec_type := g_miss_edi_rec;
    l_eft_rec                   eft_rec_type := g_miss_eft_rec;
    l_web_rec                   web_rec_type := g_miss_web_rec;
    l_phone_rec                 phone_rec_type := g_miss_phone_rec;
    l_email_rec                 email_rec_type := g_miss_email_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_telex_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => l_edi_rec,
      x_eft_rec                 => l_eft_rec,
      x_email_rec               => l_email_rec,
      x_phone_rec               => l_phone_rec,
      x_telex_rec               => x_telex_rec,
      x_web_rec                 => l_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_telex_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_telex_contact_point;

  --
  -- PROCEDURE get_email_contact_point
  --
  -- DESCRIPTION
  --     Gets email contact point record.
  --
  -- EXTERNAL PROCEDURES/FUNCTIONS ACCESSED
  --
  -- ARGUMENTS
  --   IN:
  --     p_init_msg_list      Initialize message stack if it is set to
  --                          FND_API.G_TRUE. Default is fnd_api.g_false.
  --     p_contact_point_id   Contact point ID.
  --   IN/OUT:
  --   OUT:
  --     x_contact_point_rec  Returned contact point record.
  --     x_email_rec          Returned email record.
  --     x_return_status      Return status after the call. The status can
  --                          be fnd_api.g_ret_sts_success (success),
  --                          fnd_api.g_ret_sts_error (error),
  --                          fnd_api.g_ret_sts_unexp_error (unexpected error).
  --     x_msg_count          Number of messages in message stack.
  --     x_msg_data           Message text if x_msg_count is 1.
  --
  -- NOTES
  --
  -- MODIFICATION HISTORY
  --
  --   07-23-2001    Jianying Huang      o Created.
  --   04-DEC-2001   Joe del Callar      Bug 2136283: Added support for
  --                                     enhanced backward compatibility.
  --

  PROCEDURE get_email_contact_point (
    p_init_msg_list             IN     VARCHAR2 := fnd_api.g_false,
    p_contact_point_id          IN     NUMBER,
    x_contact_point_rec         OUT    NOCOPY contact_point_rec_type,
    x_email_rec                   OUT    NOCOPY email_rec_type,
    x_return_status             OUT NOCOPY    VARCHAR2,
    x_msg_count                 OUT NOCOPY    NUMBER,
    x_msg_data                  OUT NOCOPY    VARCHAR2
  ) IS
    l_edi_rec                   edi_rec_type := g_miss_edi_rec;
    l_eft_rec                   eft_rec_type := g_miss_eft_rec;
    l_web_rec                   web_rec_type := g_miss_web_rec;
    l_phone_rec                 phone_rec_type := g_miss_phone_rec;
    l_telex_rec                 telex_rec_type := g_miss_telex_rec;
    l_debug_prefix              VARCHAR2(30) := '';
  BEGIN
    -- Check if API is called in debug mode. If yes, enable debug.
    --enable_debug;

    -- Debug info.
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_email_contact_point (+)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;


    -- Execute main procedure
    get_contact_point_main (
      p_init_msg_list           => p_init_msg_list,
      p_contact_point_id        => p_contact_point_id,
      x_contact_point_rec       => x_contact_point_rec,
      x_edi_rec                 => l_edi_rec,
      x_eft_rec                 => l_eft_rec,
      x_email_rec               => x_email_rec,
      x_phone_rec               => l_phone_rec,
      x_telex_rec               => l_telex_rec,
      x_web_rec                 => l_web_rec,
      x_return_status           => x_return_status,
      x_msg_count               => x_msg_count,
      x_msg_data                => x_msg_data
    );

    -- Debug info.
    IF fnd_log.level_exception>=fnd_log.g_current_runtime_level THEN
         hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'WARNING',
                               p_msg_level=>fnd_log.level_exception);
    END IF;
    IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
    END IF;

    -- Check if API is called in debug mode. If yes, disable debug.
    --disable_debug;

  EXCEPTION
    WHEN fnd_api.g_exc_error THEN
      x_return_status := fnd_api.g_ret_sts_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN fnd_api.g_exc_unexpected_error THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'UNEXPECTED ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;

    WHEN OTHERS THEN
      x_return_status := fnd_api.g_ret_sts_unexp_error;

      fnd_message.set_name('AR', 'HZ_API_OTHERS_EXCEP');
      fnd_message.set_token('ERROR' ,SQLERRM);
      fnd_msg_pub.add;

      fnd_msg_pub.count_and_get(p_encoded => fnd_api.g_false,
                                p_count => x_msg_count,
                                p_data  => x_msg_data);

      -- Debug info.
      IF fnd_log.level_error>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug_return_messages(p_msg_count=>x_msg_count,
                               p_msg_data=>x_msg_data,
                               p_msg_type=>'SQL ERROR',
                               p_msg_level=>fnd_log.level_error);
      END IF;
      IF fnd_log.level_procedure>=fnd_log.g_current_runtime_level THEN
        hz_utility_v2pub.debug(p_message=>'get_email_contact_point (-)',
                               p_prefix=>l_debug_prefix,
                               p_msg_level=>fnd_log.level_procedure);
      END IF;

      -- Check if API is called in debug mode. If yes, disable debug.
      --disable_debug;
  END get_email_contact_point;

  /*----------------------------------------------------------------------------*
 | procedure                                                                  |
 |    update_contact_point_search                                             |
 |                                                                            |
 | DESCRIPTION                                                                |
 |    This procedure updates the address_text column of                       |
 |    hz_cust_acct_sites_all with the NULL value                              |
 |    only to change the address_text column status                           |
 |    so that interMedia index can be created on it to perform text searches. |
 |                                                                            |
 | NOTE :- After Calling this procedure the user has to execute the           |
 |         Customer Text Data Creation concurrent program to see the changes. |
 |                                                                            |
 | PARAMETERS                                                                 |
 |   INPUT                                                                    |
 |    p_cp_rec                                                                |
 |    p_old_phone_rec                                                         |
 |    p_new_phone_rec                                                         |
 |    p_old_email_rec                                                         |
 |    p_new_email_rec                                                         |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 |   OUTPUT                                                                   |
 |                                                                            |
 |                                                                            |
 | HISTORY                                                                    |
 |    15-Mar-2004    Ramesh Ch   Created                                       |
 *----------------------------------------------------------------------------*/

PROCEDURE update_contact_point_search(p_cp_rec        IN HZ_CONTACT_POINT_V2PUB.CONTACT_POINT_REC_TYPE,
                                      p_old_phone_rec IN HZ_CONTACT_POINT_V2PUB.phone_rec_type,
                                      p_new_phone_rec IN HZ_CONTACT_POINT_V2PUB.phone_rec_type,
                                      p_old_email_rec IN HZ_CONTACT_POINT_V2PUB.email_rec_type,
                                      p_new_email_rec IN HZ_CONTACT_POINT_V2PUB.email_rec_type
                                     )
IS

  ----(Party level Contact Point)
 CURSOR c_pl_cp(p_party_id NUMBER) IS
  SELECT ac.CUST_ACCT_SITE_ID
    FROM HZ_CUST_ACCOUNTS c,HZ_CUST_ACCT_SITES_ALL ac
    WHERE c.party_id=p_party_id
    AND c.cust_account_id = ac.cust_account_id;

  ----(Site level contact point)
CURSOR c_sl_cp(p_party_site_id NUMBER) IS
    SELECT ac.CUST_ACCT_SITE_ID
    FROM HZ_PARTY_SITES ps,
         HZ_CUST_ACCT_SITES_ALL ac
    WHERE ps.PARTY_SITE_ID=p_party_site_id
    AND ps.PARTY_SITE_ID=ac.PARTY_SITE_ID;

 ----(Party level relationship's contact point )
 CURSOR c_pl_rel_cp(p_party_id NUMBER) IS
  SELECT distinct ac.CUST_ACCT_SITE_ID
    FROM HZ_PARTIES p, HZ_CUST_ACCOUNT_ROLES ar,
         HZ_RELATIONSHIPS rel,HZ_CUST_ACCT_SITES_ALL ac
    WHERE rel.party_id=p_party_id
    AND ar.ROLE_TYPE = 'CONTACT'
    AND rel.party_id=ar.party_id
    AND rel.subject_id=p.party_id
    AND ar.cust_account_id = ac.cust_account_id
    AND (ar.cust_acct_site_id is null);

 -----(Site Level relationship's contact point )
 CURSOR c_sl_rel_cp(p_party_id NUMBER) IS
  SELECT distinct ac.CUST_ACCT_SITE_ID
     FROM HZ_PARTIES p, HZ_CUST_ACCOUNT_ROLES ar,
          HZ_RELATIONSHIPS rel,HZ_CUST_ACCT_SITES_ALL ac
     WHERE rel.party_id=p_party_id
     AND ar.ROLE_TYPE = 'CONTACT'
     AND ar.party_id = rel.party_id
     AND p.party_id = rel.subject_id
     AND ar.cust_account_id = ac.cust_account_id
     AND ar.cust_acct_site_id = ac.cust_acct_site_id;

 CURSOR c_party_type(p_party_id NUMBER) IS
  SELECT party_type
  FROM HZ_PARTIES
  WHERE party_id=p_party_id;

l_owner_table_name   HZ_CONTACT_POINTS.OWNER_TABLE_NAME%TYPE;
l_contact_point_type HZ_CONTACT_POINTS.CONTACT_POINT_TYPE%TYPE;
TYPE siteidtab IS TABLE OF HZ_CUST_ACCT_SITES_ALL.CUST_ACCT_SITE_ID%TYPE;
l_siteidtab siteidtab;
l_party_type       HZ_PARTIES.PARTY_TYPE%TYPE;
BEGIN
 savepoint update_contact_point_search;
/*
 l_owner_table_name   := p_cp_rec.owner_table_name;
 l_contact_point_type := p_cp_rec.contact_point_type;

 IF (l_owner_table_name='HZ_PARTY_SITES' AND l_contact_point_type NOT IN ('EDI', 'EMAIL', 'WEB'))
    OR (l_owner_table_name='HZ_PARTIES' AND l_contact_point_type NOT IN  ('EDI','WEB'))
 THEN
      IF(  isModified(   p_old_phone_rec.phone_number       ,p_new_phone_rec.phone_number)
           OR isModified(p_old_phone_rec.phone_area_code    ,p_new_phone_rec.phone_area_code)
           OR isModified(p_old_phone_rec.phone_country_code ,p_new_phone_rec.phone_country_code)
           OR isModified(p_old_email_rec.email_address      ,p_new_email_rec.email_address)
         ) THEN
              IF  l_owner_table_name ='HZ_PARTY_SITES'
              THEN
                  OPEN c_sl_cp(p_cp_rec.owner_table_id);
                  FETCH c_sl_cp BULK COLLECT INTO l_siteidtab;
                  CLOSE c_sl_cp;
                  IF l_siteidtab.COUNT >0 THEN
                     FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
                        update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
                  END IF;
              ELSE  ---l_owner_table_name ='HZ_PARTIES'
                 OPEN c_party_type(p_cp_rec.owner_table_id);
                 FETCH c_party_type INTO l_party_type;
                 CLOSE c_party_type;
                 IF l_party_type='PARTY_RELATIONSHIP' THEN
                    --Process party level relationship's records
                    OPEN  c_pl_rel_cp(p_cp_rec.owner_table_id);
                    FETCH c_pl_rel_cp BULK COLLECT INTO l_siteidtab;
                    CLOSE c_pl_rel_cp;
                    IF l_siteidtab.COUNT >0 THEN
                       FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
                         update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
                    END IF;
                    --Process site level relationship's records
                    OPEN  c_sl_rel_cp(p_cp_rec.owner_table_id);
                    FETCH c_sl_rel_cp BULK COLLECT INTO l_siteidtab;
                    CLOSE c_sl_rel_cp;
                    IF l_siteidtab.COUNT >0 THEN
                      FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
                        update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
                    END IF;
                 ELSE
                   OPEN c_pl_cp(p_cp_rec.owner_table_id);
                   FETCH c_pl_cp BULK COLLECT INTO l_siteidtab;
                   CLOSE c_pl_cp;
                   IF l_siteidtab.COUNT >0 THEN
                      FORALL i IN l_siteidtab.FIRST..l_siteidtab.LAST
                        update HZ_CUST_ACCT_SITES_ALL set address_text=NULL where cust_acct_site_id=l_siteidtab(i);
                   END IF;
                 END IF;
              END IF;
      END IF;
 END IF;*/ NULL;
EXCEPTION
 WHEN OTHERS THEN
   ROLLBACK TO update_contact_point_search;
   RAISE;
END;
FUNCTION isModified(p_old_value IN VARCHAR2,p_new_value IN VARCHAR2) RETURN BOOLEAN
IS
BEGIN
  IF p_new_value IS NOT NULL AND p_new_value <> FND_API.G_MISS_CHAR THEN
     RETURN NVL(NOT (p_old_value=p_new_value),TRUE);
  ELSIF (p_old_value IS NOT NULL AND p_old_value <> FND_API.G_MISS_CHAR)
         AND p_new_value = FND_API.G_MISS_CHAR THEN
     RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;

END hz_contact_point_v2pub;
/
COMMIT;
SHOW ERRORS;
EXIT;
