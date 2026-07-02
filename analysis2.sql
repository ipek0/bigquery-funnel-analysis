-- Önce her kullanıcının her oturumda ne yaptığını buluyoruz
WITH tablo AS (
  SELECT
    -- Tarih
    event_date,

    -- Kullanıcı kimliği
    user_pseudo_id,

    -- Oturum kimliği (iç içe tabloda olduğu için böyle alıyoruz)
    (SELECT value.int_value 
     FROM UNNEST(event_params) 
     WHERE key = 'ga_session_id') AS session_id,

    -- Trafik kaynağı bilgileri
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    traffic_source.name AS campaign,

    -- Bu oturumda session_start olayı var mı? (1=evet, 0=hayır)
    MAX(IF(event_name = 'session_start',  1, 0)) AS session_var,

    -- Bu oturumda sepete ekleme var mı? (1=evet, 0=hayır)
    MAX(IF(event_name = 'add_to_cart',    1, 0)) AS cart_var,

    -- Bu oturumda ödeme başlangıcı var mı? (1=evet, 0=hayır)
    MAX(IF(event_name = 'begin_checkout', 1, 0)) AS checkout_var,

    -- Bu oturumda satın alma var mı? (1=evet, 0=hayır)
    MAX(IF(event_name = 'purchase',       1, 0)) AS purchase_var

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`

  -- Her kullanıcı + oturum kombinasyonu için grupla
  GROUP BY 1,2,3,4,5,6
)

-- Şimdi dönüşüm oranlarını hesaplıyoruz
SELECT
  -- Tarih ve trafik bilgileri
  event_date,
  source,
  medium,
  campaign,

  -- Kaç benzersiz oturum var?
  COUNT(DISTINCT CONCAT(user_pseudo_id, session_id)) AS user_sessions_count,

  -- Siteye gelenlerin kaçı sepete ekledi? (oran)
  ROUND(
    COUNT(DISTINCT IF(cart_var = 1, CONCAT(user_pseudo_id, session_id), NULL))
    / COUNT(DISTINCT CONCAT(user_pseudo_id, session_id))
  , 2) AS visit_to_cart,

  -- Siteye gelenlerin kaçı ödemeye başladı? (oran)
  ROUND(
    COUNT(DISTINCT IF(checkout_var = 1, CONCAT(user_pseudo_id, session_id), NULL))
    / COUNT(DISTINCT CONCAT(user_pseudo_id, session_id))
  , 2) AS visit_to_checkout,

  -- Siteye gelenlerin kaçı satın aldı? (oran)
  ROUND(
    COUNT(DISTINCT IF(purchase_var = 1, CONCAT(user_pseudo_id, session_id), NULL))
    / COUNT(DISTINCT CONCAT(user_pseudo_id, session_id))
  , 2) AS visit_to_purchase

FROM tablo

-- Sadece oturum başlatan kullanıcıları al
WHERE session_var = 1

-- Tarih ve trafik bilgilerine göre grupla
GROUP BY 1,2,3,4
