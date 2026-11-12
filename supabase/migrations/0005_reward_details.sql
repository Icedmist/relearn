-- ReLearn 0005: richer catalogue records for a marketplace-style shop.
-- Category and description make items easy to browse; image_url already exists
-- from 0004. Existing rows are backfilled by name.

alter table public.rewards add column if not exists category text not null default 'Stationery';
alter table public.rewards add column if not exists description text;

update public.rewards set category = v.category, description = v.description
from (values
  ('Pencil', 'Stationery', 'HB pencil for everyday classwork.'),
  ('Exercise book', 'Books', '80-page ruled exercise book.'),
  ('School backpack', 'Bags', 'Durable backpack with padded straps.'),
  ('Eraser', 'Stationery', 'Soft eraser that does not tear the page.'),
  ('Pencil sharpener', 'Stationery', 'Compact sharpener with a shatter-proof blade.'),
  ('30 cm ruler', 'Maths', 'Clear 30 cm ruler with metric markings.'),
  ('Blue ballpoint pen', 'Stationery', 'Smooth-writing blue ballpoint pen.'),
  ('HB pencil (pack of 3)', 'Stationery', 'Three HB pencils for a full term.'),
  ('Drawing book', 'Art', 'A4 drawing book with 40 blank pages.'),
  ('Crayons (8 colours)', 'Art', 'Eight bright, non-toxic wax crayons.'),
  ('Coloured pencils (12)', 'Art', 'Twelve coloured pencils in a keepsake tin.'),
  ('Geometry set', 'Maths', 'Compass, protractor, set squares and ruler.'),
  ('Lunch box', 'Lunch', 'Insulated lunch box with a secure lid.'),
  ('Water bottle', 'Lunch', '500 ml leak-proof school water bottle.'),
  ('Atlas', 'Books', 'Illustrated world atlas for social studies.'),
  ('Exercise book (pack of 5)', 'Books', 'Five ruled exercise books for the term.'),
  ('Oxford school dictionary', 'Books', 'Oxford school dictionary for class and homework.'),
  ('Scientific calculator', 'Maths', 'Scientific calculator for maths and science.')
) as v(name, category, description)
where public.rewards.name = v.name;
