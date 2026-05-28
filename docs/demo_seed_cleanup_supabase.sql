-- BoostDrive demo cleanup (run in Supabase SQL Editor)
-- Removes the connected demo dataset created for:
-- - Carlos Mechanical Services
-- - Saya Mubiana
-- - BaTLorriH Logistics
--
-- Safe order: child rows first, then parent rows.

begin;

-- Stable demo IDs used by the seed script
-- provider: 11111111-1111-4111-8111-111111111111
-- saya:     22222222-2222-4222-8222-222222222222
-- logistics:33333333-3333-4333-8333-333333333333

-- 1) Child rows tied to demo parent rows
delete from public.customer_cart_push_items
where push_id in (
  select id from public.customer_cart_pushes
  where job_card_id = '66666666-6666-4666-8666-666666666666'::uuid
);

delete from public.customer_cart_pushes
where job_card_id = '66666666-6666-4666-8666-666666666666'::uuid;

delete from public.provider_job_card_parts
where job_card_id = '66666666-6666-4666-8666-666666666666'::uuid;

delete from public.provider_job_card_invoices
where job_card_id = '66666666-6666-4666-8666-666666666666'::uuid;

delete from public.order_items
where service_request_id = '77777777-7777-4777-8777-777777777777'::uuid;

delete from public.order_job_photos
where service_request_id = '77777777-7777-4777-8777-777777777777'::uuid;

delete from public.order_signatures
where service_request_id = '77777777-7777-4777-8777-777777777777'::uuid;

delete from public.sos_provider_responding
where sos_request_id = '55555555-5555-4555-8555-555555555555'::uuid;

delete from public.sos_provider_reviews
where sos_request_id = '55555555-5555-4555-8555-555555555555'::uuid
   or source_id = '66666666-6666-4666-8666-666666666666'::uuid;

-- 2) Core demo rows
delete from public.delivery_orders
where id = '99999999-9999-4999-8999-999999999999'::uuid;

delete from public.service_requests
where id = '77777777-7777-4777-8777-777777777777'::uuid;

delete from public.provider_job_cards
where id = '66666666-6666-4666-8666-666666666666'::uuid;

delete from public.sos_requests
where id = '55555555-5555-4555-8555-555555555555'::uuid;

delete from public.products
where id = '88888888-8888-4888-8888-888888888888'::uuid;

delete from public.provider_services
where id in (
  '44444444-4444-4444-8444-444444444441'::uuid,
  '44444444-4444-4444-8444-444444444442'::uuid,
  '44444444-4444-4444-8444-444444444443'::uuid
);

-- 3) Optional profile cleanup (comment out if you want to keep accounts)
delete from public.profiles
where id in (
  '11111111-1111-4111-8111-111111111111'::uuid,
  '22222222-2222-4222-8222-222222222222'::uuid,
  '33333333-3333-4333-8333-333333333333'::uuid
);

commit;

