-- Hangi kolonları istiyoruz
SELECT

  -- Tarihi sayıdan okunabilir formata çevirir
  TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,
  -- Kullanıcı kimliği 
  user_pseudo_id,

  -- Oturum kimliği içiçe tabloda olduğu için böyle alıyoruz
  (SELECT value.int_value 
   FROM UNNEST(event_params) 
   WHERE key = 'ga_session_id') AS session_id,

  event_name,
  geo.country AS country,
  device.category AS device_category,

  traffic_source.source AS source,
  traffic_source.medium AS medium,
  traffic_source.name AS campaign

--FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021*`

-- events
WHERE event_name IN (
  'session_start',
  'view_item',
  'add_to_cart',
  'begin_checkout',
  'add_shipping_info',
  'add_payment_info',
  'purchase'
)
LIMIT 1000
