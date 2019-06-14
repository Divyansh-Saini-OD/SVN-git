create or replace PACKAGE BODY XX_AR_FIN_READ_CSV_FORMAT 
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                          	  |
  -- +============================================================================================+
  -- |  Name:  XX_AR_FIN_READ_CSV_FORMAT                                                      	  |
  -- |                                                                                            |
  -- |  Description:  This package is used to process CSV comma separated file.                   |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         13-JUNE-2019  Thejaswini Rajula    Initial version                             |
  -- +============================================================================================+

  
FUNCTION read_next_element(p_data IN OUT VARCHAR2
                          , p_delimiter IN VARCHAR2
                          , p_encapsulator IN VARCHAR2)
      RETURN VARCHAR2
IS 
      l_sqlerrm       VARCHAR2 (4096);
      l_element       VARCHAR2 (32767);
      l_char          VARCHAR2 (6);
      l_length        INTEGER          := NVL (LENGTH (p_data), 0);
      l_idx           INTEGER          := 1;
      l_encap_count   INTEGER          := 0;
   BEGIN
      WHILE (l_idx <= l_length)
      LOOP
         l_char := SUBSTR (p_data, l_idx, 1);

         IF (    (ASCII (l_char) < 32)
             AND (l_char <> p_delimiter)
             AND (l_char <> NVL (p_encapsulator, 'X')))
         THEN
            NULL; -- skip the character
         ELSIF (l_char = p_delimiter)
         THEN
            IF (l_encap_count = 0)
            THEN
               EXIT; -- this is the end of the element
            ELSE
               l_element := l_element || l_char;
            END IF;
         ELSIF (p_encapsulator IS NOT NULL)
         THEN
            IF (l_char = p_encapsulator)
            THEN
               IF (l_idx = 1)
               THEN
                  l_encap_count := 1;
               ELSIF (SUBSTR (p_data, l_idx + 1, 1) = p_encapsulator)
               THEN
                  l_element := l_element || l_char;
                  l_idx := l_idx + 1;
               ELSE
                  l_encap_count := 0;
               END IF;
            ELSE
               l_element := l_element || l_char;
            END IF;
         ELSE
            l_element := l_element || l_char;
         END IF;

         l_idx := l_idx + 1;
      END LOOP;

      p_data := SUBSTR (p_data, l_idx + 1);
      RETURN (RTRIM (LTRIM (l_element)));
   EXCEPTION
      WHEN OTHERS
      THEN
         l_sqlerrm := SQLERRM;
         raise_application_error (-20001, fnd_message.get);
   END read_next_element;
END XX_AR_FIN_READ_CSV_FORMAT;