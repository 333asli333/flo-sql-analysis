use floveri;
 
SELECT TOP 5 * FROM flo_data_20K;

-- kaç farklý kiþi alýþveriþ yapmýþ?
SELECT COUNT(DISTINCT(master_id))  as musteri_sayisi FROM flo_data_20K;

-- toplam sipariþ sayýsý ve ciro
SELECT 
	SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis,
	ROUND(sum(customer_value_total_ever_online + customer_value_total_ever_offline) , 2) as toplam_ciro
	FROM flo_data_20K;

-- alýþveriþ baþýna düþen ciro
select
ROUND(SUM(customer_value_total_ever_online + customer_value_total_ever_offline) / SUM(order_num_total_ever_online + order_num_total_ever_offline), 2)  as alisveris_basi_ciro
from flo_data_20K;

-- last order channel e göre alýþveriþ ve ciro
SELECT 
	last_order_channel as son_alisveris_kanali,
	SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis,
	sum(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro
FROM flo_data_20K
GROUP BY last_order_channel;

-- store type kýrýlýmýnda elde edilen toplam ciro
SELECT 
	store_type as magaza_turu,
	sum(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro
FROM flo_data_20K
GROUP BY store_type;

-- yýl kýrýlýmda alýþveriþ sayýlarý first order date göre

SELECT 
YEAR(first_order_date) as yýl,
SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis
FROM  flo_data_20K
GROUP BY YEAR(first_order_date)
ORDER BY 1 DESC

-- en son alýsveris yapýlan kanaþ kýrýlýmýnda alýþveriþ baþýna olan ortalama ciro

SELECT
last_order_channel as son_alisveris_kanali,
SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_siparis,
sum(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro,
ROUND(SUM(customer_value_total_ever_online + customer_value_total_ever_offline) / SUM(order_num_total_ever_online + order_num_total_ever_offline), 2)  as verimlilik
FROM flo_data_20K
GROUP BY last_order_channel;

-- son 12 ayda en çok ilgi gören kategori

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

-- en son alýþveriþ yapýlan kanaþ bazýnda, en çok ilgi gören kategoriyi ve
-- ne kadar alýþveriþ yapýldý?

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

-- en cok alýþveriþ yapan kiþinin idsi
SELECT TOP 5
master_id,
 SUM(customer_value_total_ever_online + customer_value_total_ever_offline) AS toplam_alisveris
FROM flo_data_20K
GROUP BY master_id
ORDER BY toplam_alisveris DESC

-- en cok alýþveriþ yapan kiþinin alýþveriþ baþýna düþen ciro ve alýþveriþ yapma gün ortalmasý

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
		DATEDIFF(DAY, ilk_gun, son_gun) * 1.0 / toplam_alisveris as gun_ortalamasý
	FROM toplamlar
	ORDER BY toplam_alisveris DESC


-- en çok alýþveriþ yapan ÝLK 100 kiþinin ciro bazýnda ilk 100 kiþinin alýþveriþ sýklýðý

WITH toplamlar as (
	SELECT
		master_id,
		SUM(customer_value_total_ever_online + customer_value_total_ever_offline) as toplam_ciro,
		SUM(order_num_total_ever_online + order_num_total_ever_offline) as toplam_alisveris,
		MIN(first_order_date) as ilk_gun,
		MAX(last_order_date) as son_gun,
		DATEDIFF(DAY, MIN(first_order_date), MAX(last_order_date)) as ilk_son_gun_farký
	FROM flo_data_20K
	GROUP BY master_id)

	SELECT TOP 100
	master_id,
	toplam_ciro,
	ilk_gun,
	son_gun,
	ilk_son_gun_farký,
	toplam_ciro * 1.0 / toplam_alisveris as alisveris_basina_ciro,
	DATEDIFF(DAY, ilk_gun, son_gun)*1.0  / toplam_alisveris as gun_ortalamasi
FROM toplamlar
ORDER BY toplam_ciro

-- en son alýþveriþ yapýlan kanal kýrýlýmýnda en çok alýsveriþ yapan müþteri

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

-- en son alýþveriþ yapan kiþinin idsi ve son tarihte birden fazla alýþveriþ yapan kiþi

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



















