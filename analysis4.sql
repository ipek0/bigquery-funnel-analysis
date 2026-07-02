WITH tablo AS (
  SELECT
    user_pseudo_id,

    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS session_id,
    
    --Kullanıcı etkileşim yaptı mı
    MAX(IF((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'session_engaged') = '1', 1, 0)) AS is_engaged,
    --Aktif etkileşim süresi
    SUM(IFNULL((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec'), 0)) AS engagement_time,

    --satın alım yapıldı mı
    MAX(IF(event_name = 'purchase', 1, 0)) AS has_purchase
    
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131`
  GROUP BY 1, 2
)

SELECT

  -- Etkileşim ile satın alma korelasyonu 
  (AVG(is_engaged * has_purchase)  - AVG(is_engaged) * AVG(has_purchase))
  / (STDDEV(is_engaged) * STDDEV(has_purchase)) AS engaged_vs_purchase_corr,

  -- Aktif süre ile satın alma korelasyonu 
  (AVG(engagement_time * has_purchase)  - AVG(engagement_time) * AVG(has_purchase))
  / (STDDEV(engagement_time) * STDDEV(has_purchase)) AS time_vs_purchase_corr


  ---CORR(is_engaged, has_purchase) AS engaged_vs_purchase_corr,
  ---CORR(engagement_time, has_purchase) AS time_vs_purchase_corr


FROM tablo

