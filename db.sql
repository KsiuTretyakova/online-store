-- Створіть таблиці для товарів, клієнтів, замовлень і позицій у замовленнях.
-- products: товари
-- customers: клієнти
-- orders: замовлення
-- order_items: позиції у замовленні

-- таблиця товарів
CREATE TABLE products (
  id SERIAL PRIMARY KEY, -- унікальний ідентифікатор
  name TEXT NOT NULL, -- назва товару
  category TEXT NOT NULL, -- категорія (наприклад, "Електроніка")
  price NUMERIC(10,2) CHECK (price >= 0) -- ціна з перевіркою
);

-- таблиця клієнтів
CREATE TABLE customers (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE, -- унікальний email
  city TEXT
);

-- таблиця замовлень
-- ON DELETE CASCADE гарантує цілісність: якщо видалити клієнта, його замовлення теж зникнуть
CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  customer_id INTEGER 
  REFERENCES customers(id) ON DELETE CASCADE,
  order_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- таблиця позицій у замовленні
-- order_items реалізує зв’язок “багато‑до‑багатьох” між замовленнями та товарами
CREATE TABLE order_items (
  order_id INTEGER 
  REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER 
  REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER CHECK (quantity > 0),
  PRIMARY KEY (order_id, product_id)
);

-- Заповніть їх тестовими даними (мінімум 5 товарів, 3 клієнти, 3 замовлення)

-- Додаємо товари
INSERT INTO products (name, category, price) VALUES
('Notebook', 'Electronics', 1200.00),
('Mouse', 'Electronics', 25.50),
('T-shirt', 'Clothing', 10.00),
('Chair', 'Furniture', 15.25),
('Water', 'Food', 2.00);

-- Додаємо клієнтів
INSERT INTO customers (name, email, city) VALUES
('Svitlana', 'svitlana@example.com', 'Kyiv'),
('Taras', 'taras@example.com', 'Lviv'),
('Iryna', 'iryna@example.com', 'Kharkiv');

-- Створюємо замовлення
INSERT INTO orders (customer_id) VALUES (1); -- Svitlana (1)
INSERT INTO orders (customer_id) VALUES (3); -- Iryna (2)
INSERT INTO orders (customer_id) VALUES (3); -- Iryna (3)

-- Додаємо товари у замовлення
INSERT INTO order_items (order_id, product_id, quantity)
VALUES
(1, 1, 1), -- Svitlana, Notebook, 1
(1, 2, 1), -- Svitlana, Mouse, 1
(2, 3, 1), -- Iryna (2), T-shirt, 1
(3, 5, 2); -- Iryna (3), Water, 2


-- Реалізуйте CRUD‑операції для таблиці products

-- CRUD операції для таблиці products
-- CREATE: додати новий товар
INSERT INTO products (name, category, price) VALUES ('Keyboard', 'Electronics', 15.00);

-- READ: вибрати всі товари
SELECT * FROM products;

-- UPDATE: змінити ціну товару
UPDATE products SET price = 14.99 WHERE name = 'Keyboard';

-- DELETE: видалити товар
DELETE FROM products WHERE name = 'Keyboard';


-- Побудуйте звіти:

-- Кількість замовлень по клієнтах
SELECT c.name, COUNT(o.id) AS orders_count
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY orders_count DESC;


-- Сумарна вартість кожного замовлення
SELECT 
  o.id AS order_id, 
  SUM(oi.quantity * p.price) AS order_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON p.id = oi.product_id
GROUP BY o.id
ORDER BY order_total DESC;


-- Топ‑3 найдорожчі товари
SELECT name, price
FROM products
ORDER BY price DESC
LIMIT 3;

-- ----------------------------
-- Топ‑3 найдорожчі товари в кожній категорії
-- Використовуємо віконну функцію ROW_NUMBER() для ранжування товарів у кожній категорії
-- Потім вибираємо лише ті з них, які мають ранг 3 або менше
-- 
-- Внутрішній запит створює тимчасову таблицю з рангами товарів
-- Зовнішній запит фільтрує ці дані
-- 
-- PARTITION BY category означає, що нумерація починається заново для кожної категорії
-- ORDER BY price DESC визначає порядок нумерації (від найдорожчих до найдешевших)
-- 
-- Результат сортуємо за категорією і ціною у спадному порядку
-- Таким чином отримуємо топ‑3 товари в кожній категорії
-- Використання віконних функцій дозволяє ефективно виконувати складні аналітичні запити
-- без необхідності складних підзапитів або тимчасових таблиць

SELECT category, name, price
FROM (
  SELECT category, name, price,
  ROW_NUMBER() OVER -- віконна функція для нумерації рядків
  (PARTITION BY category ORDER BY price DESC) -- розділяємо нумерацію за категоріями
  AS rank_in_category
  FROM products1
) ranked -- ranked - це псевдонім для тимчасової таблиці, створеної всередині підзапиту
WHERE rank_in_category <= 3 -- вибираємо лише топ‑3
ORDER BY category, price DESC;
-- ----------------------------

-- Використайте транзакцію для створення замовлення з кількома товарами
-- Транзакція гарантує, що всі операції будуть виконані разом
-- або жодна з них не буде виконана (у разі помилки)
-- Якщо щось піде не так - можна зробити ROLLBACK
-- Починаємо транзакцію
BEGIN;
-- Створюємо нове замовлення для Taras (id=2)
INSERT INTO orders (customer_id) VALUES (2); -- Taras
-- Додаємо товари до цього замовлення
INSERT INTO order_items (order_id, product_id, quantity)
VALUES 
(4, 2, 3),
(4, 5, 2),
(4, 4, 1);
-- Фіксуємо транзакцію
COMMIT;

-- Створіть view, яке показує кількість замовлень і витрати клієнтів
-- View дозволяє швидко отримати звіт без повторного написання складного запиту
-- Використовуйте це view для отримання списку клієнтів, відсортованого за витратами
