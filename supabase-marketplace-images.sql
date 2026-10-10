-- Trainer Marktplaats: kaartafbeeldingen (voer eenmaal uit).
alter table public.market_listings
add column if not exists image_url text;

alter table public.market_listings
drop constraint if exists market_listings_image_url_check;

alter table public.market_listings
add constraint market_listings_image_url_check
check (
 image_url is null or
 (char_length(image_url)<=500 and image_url ~ '^https://(images[.]scrydex[.]com|assets[.]tcgdex[.]net|cdn[.]tcgdex[.]net)/')
);
