-- 1) Основи таблиць і запитів

-- Створюємо таблицю students
-- Таблиця - це як "Excel-аркуш": у ній є колонки (поля) і рядки (записи)
-- PRIMARY KEY гарантує, що кожен студент має унікальний id
-- SERIAL автоматично генерує значення id (1, 2, 3...)
-- CHECK (age >= 0) - проста перевірка, щоб не було від’ємного віку
CREATE TABLE students (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER CHECK (age >= 0)
);

-- Додаємо кілька студентів
-- INSERT додає нові рядки у таблицю
INSERT INTO students (name, age) VALUES
('Anna', 19),
('Daryna', 20),
('Natalii', 18),
('Dmytro', 24),
('Halyna', 15);

-- Вибираємо студентів старших за 20 років
-- SELECT витягує дані, WHERE задає умову
SELECT * FROM students WHERE age > 20;

-- Сортуємо студентів за віком у спадному порядку
-- ORDER BY дозволяє впорядкувати результати
SELECT id, name, age 
FROM students ORDER BY age DESC;

-- Вибираємо лише імена студентів
-- Це показує, що можна брати окремі колонки, а не всі дані
SELECT name FROM students;

-- ------------------------------------------
-- 2) Агрегатні функції та групування

-- Підрахунок кількості студентів
-- COUNT(*) рахує кількість рядків у таблиці
SELECT COUNT(*) AS total_students FROM students;

-- Середній вік студентів
-- AVG обчислює середнє значення по колонці
SELECT AVG(age) AS avg_age FROM students;

-- Найстарший студент
-- MAX знаходить найбільше значення
SELECT MAX(age) AS max_age FROM students;

-- Додаємо нову колонку city (місто)
-- ALTER TABLE змінює структуру таблиці
ALTER TABLE students ADD COLUMN city TEXT;

-- Оновлюємо дані про міста
-- UPDATE змінює існуючі записи
UPDATE students 
SET city = 'Kharkiv' 
WHERE name IN ('Anna', 'Dmytro');

UPDATE students 
SET city = 'Lviv' 
WHERE name IN ('Daryna', 'Natalii');

UPDATE students 
SET city = 'Kyiv' 
WHERE name IN ('Halyna');
UPDATE students 
SET name = 'Nataliia' 
WHERE id = 3;

-- Підрахунок студентів у кожному місті
-- GROUP BY групує дані за колонкою city
SELECT city, COUNT(*) AS students_per_city
FROM students
GROUP BY city
ORDER BY students_per_city DESC;

-- ------------------------------------------
-- 3) Зв’язки між таблицями

-- Створюємо таблицю courses (курси)
-- Тут зберігатимемо список курсів
CREATE TABLE courses (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL
);

-- Додаємо кілька курсів
INSERT INTO courses (title) VALUES
('PostgreSQL'),
('Python'),
('Data Analytic');

-- Створюємо таблицю enrollments (записи про відвідування)
-- Вона пов’язує студентів і курси (зв’язок багато-до-багатьох)
-- REFERENCES створює зовнішній ключ, який вказує на іншу таблицю
-- ON DELETE CASCADE означає: якщо видалити студента або курс,
-- то записи про відвідування теж видаляться
CREATE TABLE enrollments (
  student_id INTEGER 
  REFERENCES students(id) ON DELETE CASCADE,
  course_id INTEGER 
  REFERENCES courses(id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id)
);

-- Додаємо приклади відвідувань
INSERT INTO enrollments (student_id, course_id) 
VALUES
(1, 1), -- Anna відвідує два курси (1)
(1, 3), -- Anna відвідує два курси (2)
(5, 2), -- Halyna відвідує один курс
(4, 1); -- Dmytro відвідує один курс

-- Вибираємо студентів із назвами курсів
-- JOIN об’єднує таблиці за ключами
SELECT s.name, c.title
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.id = e.course_id
ORDER BY s.name, c.title;

-- Виводимо всіх студентів, навіть тих, хто не має курсів
-- LEFT JOIN показує всі записи з лівої таблиці (students),
-- навіть якщо у правій (courses) немає відповідності
SELECT s.name, c.title
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
LEFT JOIN courses c ON c.id = e.course_id
ORDER BY s.name;

-- ------------------------------------------
-- 4) Індекси, уявлення, транзакції

-- Створюємо індекс на колонці name
-- Індекс прискорює пошук студентів за ім’ям
CREATE INDEX idx_students_name ON students(name);

-- Створюємо уявлення (view)
-- View - це "збережений запит", який можна викликати як таблицю
CREATE VIEW vw_student_course_count AS
SELECT s.id, s.name, COUNT(e.course_id) AS course_count
FROM students s
LEFT JOIN enrollments e ON e.student_id = s.id
GROUP BY s.id, s.name;

-- Використовуємо view
SELECT * FROM vw_student_course_count ORDER BY course_count DESC;

-- Транзакція: група операцій, які виконуються разом
-- BEGIN починає транзакцію
-- COMMIT зберігає зміни
-- ROLLBACK відміняє зміни
BEGIN;
INSERT INTO students (name, age, city) 
VALUES ('TestUser', 18, 'Odesa');
ROLLBACK; -- відміняємо, запис не збережеться

BEGIN;
INSERT INTO students (name, age, city)
VALUES ('CommitedUser', 20, 'Lyzk');
COMMIT; -- зберігаємо назавжди

-- Вибираємо студентів щоб перевірити зміни
-- SELECT витягує дані з таблиці
-- * означає "всі колонки"
SELECT * FROM students;