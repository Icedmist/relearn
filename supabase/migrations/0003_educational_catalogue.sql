-- ReLearn 0003: educational supplies catalogue.
-- Adds redeemable school items with point costs. Idempotent by item name so it
-- is safe to re-run. Existing point costs are refreshed; stock is only set on
-- first insert so a re-run never overwrites live inventory.

insert into public.rewards (name, points_cost, stock, active)
values
  ('Eraser', 15, 400, true),
  ('Pencil sharpener', 15, 400, true),
  ('30 cm ruler', 25, 350, true),
  ('Blue ballpoint pen', 30, 400, true),
  ('HB pencil (pack of 3)', 50, 300, true),
  ('Drawing book', 90, 150, true),
  ('Crayons (8 colours)', 110, 150, true),
  ('Coloured pencils (12)', 120, 150, true),
  ('Geometry set', 180, 120, true),
  ('Lunch box', 220, 80, true),
  ('Water bottle', 250, 100, true),
  ('Atlas', 300, 50, true),
  ('Exercise book (pack of 5)', 350, 100, true),
  ('Oxford school dictionary', 350, 60, true),
  ('Scientific calculator', 500, 40, true)
on conflict (name) do update set
  points_cost = excluded.points_cost,
  active = excluded.active;
