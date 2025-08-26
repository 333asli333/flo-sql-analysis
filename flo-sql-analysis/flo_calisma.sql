use floveri;
 
SELECT TOP 5 * FROM flo_data_20K;

-- ka� farkl� ki�i al��veri� yapm��?
SELECT COUNT(DISTINCT(master_id))  as musteri_sayisi FROM flo_data_20K;

-- toplam sipari� say�s� ve ciro
SELECT 
	SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis,
	ROUND(sum(customer_value_total_ever_online + customer_value_total_ever_offline) , 2) as toplam_ciro
	FROM flo_data_20K;

-- al��veri� ba��na d��en ciro
select
ROUND(SUM(customer_value_total_ever_online + customer_value_total_ever_offline) / SUM(order_num_total_ever_online + order_num_total_ever_offline), 2)  as alisveris_basi_ciro
from flo_data_20K;

-- last order channel e g�re al��veri� ve ciro
SELECT 
	last_order_channel as son_alisveris_kanali,
	SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis,
	sum(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro
FROM flo_data_20K
GROUP BY last_order_channel;

-- store type k�r�l�m�nda elde edilen toplam ciro
SELECT 
	store_type as magaza_turu,
	sum(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro
FROM flo_data_20K
GROUP BY store_type;

-- y�l k�r�l�mda al��veri� say�lar� first order date g�re

SELECT 
YEAR(first_order_date) as y�l,
SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis
FROM  flo_data_20K
GROUP BY YEAR(first_order_date)
ORDER BY 1 DESC

-- en son al�sveris yap�lan kana� k�r�l�m�nda al��veri� ba��na olan ortalama ciro

SELECT
last_order_channel as son_alisveris_kanali,
SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis,
sum(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro,
ROUND(SUM(customer_value_total_ever_online + customer_value_total_ever_offline) / SUM(order_num_total_ever_online + order_num_total_ever_offline), 2)  as verimlilik
FROM flo_data_20K
GROUP BY last_order_channel;

-- son 12 ayda en �ok ilgi g�ren kategori

SELECT
	interested_in_categories_12,
	COUNT(*) as frekans_bilgi
FROM flo_data_20K
GROUP BY interested_in_categories_12
ORDER BY 2 DESC;

-- en cok tercih edilen store type bilgisi

SELECT TOP 1
	store_type,
	COUNT (*) as frekans
FROM flo_data_20K
GROUP BY store_type
ORDER BY 2 DESC

-- en son al��veri� yap�lan kana� baz�nda, en �ok ilgi g�ren kategoriyi ve
-- ne kadar al��veri� yap�ld�?

 WITH kategori_skorlari AS(
	SELECT
		last_order_channel,
		interested_in_categories_12,
		SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_alisveris
	FROM flo_data_20K
	GROUP BY last_order_channel, interested_in_categories_12 ),
	en_populer_kategoriler AS( 
	select
	last_order_channel,
	interested_in_categories_12 AS en_populer_kategori,
	toplam_alisveris,
	ROW_NUMBER() OVER ( PARTITION BY last_order_channel ORDER BY toplam_alisveris DESC) as sira
	FROM kategori_skorlari)
SELECT
	last_order_channel as son_alisveris_kanali,
	en_populer_kategori,
	toplam_alisveris as alisveris_sayisi
FROM en_populer_kategoriler
WHERE sira = 1

-- en cok al��veri� yapan ki�inin idsi
SELECT TOP 5
master_id,
 SUM(customer_value_total_ever_online + customer_value_total_ever_offline) AS toplam_alisveris
FROM flo_data_20K
GROUP BY master_id
ORDER BY toplam_alisveris DESC

-- en cok al��veri� yapan ki�inin al��veri� ba��na d��en ciro ve al��veri� yapma g�n ortalmas�

WITH toplamlar AS(
	SELECT 
		master_id,
		SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_alisveris,
        SUM(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro,
		MIN(first_order_date) AS ilk_gun,
		MAX(last_order_date) AS son_gun
	FROM flo_data_20K
	GROUP BY master_id
	)

	SELECT TOP 1
		master_id,
		toplam_alisveris,
		toplam_ciro,
		toplam_ciro * 1.0 / toplam_alisveris AS alisveris_basina_ciro,
		DATEDIFF(DAY, ilk_gun, son_gun) * 1.0 / toplam_alisveris as gun_ortalamas�
	FROM toplamlar
	ORDER BY toplam_alisveris DESC


-- en �ok al��veri� yapan �LK 100 ki�inin ciro baz�nda ilk 100 ki�inin al��veri� s�kl���

WITH toplamlar as (
	SELECT
		master_id,
		SUM(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro,
		SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_alisveris,
		MIN(first_order_date) as ilk_gun,
		MAX(last_order_date) as son_gun,
		DATEDIFF(DAY, MIN(first_order_date), MAX(last_order_date)) as ilk_son_gun_fark�
	FROM flo_data_20K
	GROUP BY master_id)

	SELECT TOP 100
	master_id,
	toplam_ciro,
	ilk_gun,
	son_gun,
	ilk_son_gun_fark�,
	toplam_ciro * 1.0 / toplam_alisveris as alisveris_basina_ciro,
	DATEDIFF(DAY, ilk_gun, son_gun)*1.0  / toplam_alisveris as gun_ortalamasi
FROM toplamlar
ORDER BY toplam_ciro

-- en son al��veri� yap�lan kanal k�r�l�m�nda en �ok al�sveri� yapan m��teri

WITH kanal_musteri_skorlari as(
	SELECT
		last_order_channel,
		master_id,
		SUM(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro,
		ROW_NUMBER() OVER( PARTITION BY  last_order_channel
		ORDER BY SUM(customer_value_total_ever_online + customer_value_total_ever_offline) DESC
		) AS sira
	FROM flo_data_20K
	GROUP BY last_order_channel, master_id)


SELECT 
	last_order_channel,
	master_id,
	toplam_ciro
FROM kanal_musteri_skorlari
WHERE sira = 1

-- en son al��veri� yapan ki�inin idsi ve son tarihte birden fazla al��veri� yapan ki�i

SELECT TOP 1
	last_order_date,
	master_id
FROM flo_data_20K
ORDER BY last_order_date DESC

SELECT 
	master_id,
	last_order_date,
	order_num_total_ever_online + order_num_total_ever_offline as toplam_alisveris
FROM flo_data_20K
WHERE last_order_date = (
	SELECT MAX(last_order_date) FROM flo_data_20K)
	AND order_num_total_ever_online + order_num_total_ever_offline > 1



















