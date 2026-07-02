
WITH oturum AS ( -- her oturumun başladığı sayfayı buluyoruz
  SELECT
    -- Kullanıcı kimliği
    user_pseudo_id,

    -- Oturum kimliği
    (SELECT value.int_value 
     FROM UNNEST(event_params) 
     WHERE key = 'ga_session_id') AS session_id,



    -- Sayfanın URL'inden sadece path'i alıyoruz
    -- Örnek: https://shop.google.com/kategori/urun → /kategori/urun
    REGEXP_EXTRACT(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'),
      r'https?://[^/]+(/[^?#]*)'

    ) AS page_path

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`
  
  --0131`

  -- Sadece oturum başlangıçlarına bak
  WHERE event_name = 'session_start'
),

-- Satın alma yapan oturumları buluyoruz
satin_alma AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value 
     FROM UNNEST(event_params) 
     WHERE key = 'ga_session_id') AS session_id

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*` --
  --0131`

  -- Sadece satın almalara bak
  WHERE event_name = 'purchase'
)

-- Şimdi ikisini birleştirip dönüşüm oranını hesaplıyoruz
SELECT
  -- Hangi sayfadan başlamış?
  o.page_path,

  -- Kaç benzersiz oturum var?
  COUNT(DISTINCT CONCAT(o.user_pseudo_id, o.session_id)) AS unique_sessions,

  -- Kaç satın alma var?
  COUNT(DISTINCT IF(s.session_id IS NOT NULL, 
    CONCAT(o.user_pseudo_id, o.session_id), NULL)) AS purchase_count,

  -- Dönüşüm oranı (satın alma / toplam oturum)
  ROUND(
    COUNT(DISTINCT IF(s.session_id IS NOT NULL, 
      CONCAT(o.user_pseudo_id, o.session_id), NULL))
    / COUNT(DISTINCT CONCAT(o.user_pseudo_id, o.session_id))
  , 2) AS conversion_rate

FROM oturum o

-- Oturumu satın almayla eşleştir (aynı kullanıcı + aynı oturum)
LEFT JOIN satin_alma s 
  ON o.user_pseudo_id = s.user_pseudo_id 
  AND o.session_id = s.session_id

GROUP BY 1
ORDER BY unique_sessions DESC
