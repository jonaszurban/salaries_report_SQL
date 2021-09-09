-- RAPORT PŁACOWY NR 1
/* W pierwszej części raportu płacowego chcemy porównać zarobki w zależności od płci oraz departamentu - w tym celu porównamy
całkowitą ilość osób, całkowitą sumę zarobków oraz średnią zarobków w obrębie najpierw danej płci, a następnie departamentu.
Dzięki temu pozyskamy informacje czy występuje nierówność płacowa oraz w których departamentach ludzie zarabiają najwięcej. */

-- Sprawdzamy co mamy w trzech tabelach, które mogą posiadać potrzebne informacje.
SELECT * FROM employee.salaries;
SELECT * FROM employee.employees;
SELECT * FROM employee.departments;
/* Wiemy już, że aktualne wynagrodzenie jest tym gdzie kolumna to_date posiada wartośc '9999-01-01'. Prawdopodobnie wcześniejsze
wynagrodzenia obowiązywały do danej daty, a ta wartość pokazuje, że jest to aktualne wynagrodzenie bez zdefiniowanej daty końcowej.
Tak samo wygląda sytuacja w dept_emp - kolumna rekordy w kolumnie to_date muszą mieć wartość '9999-01-01'.*/

/* Wyciągamy zatem id pracowników i ich wynagrodzenia z tabeli salaries - dzięki temu będziemy wiedzieć ile obecnie zarabia dany pracownik. */
SELECT e.emp_no, s.salary FROM employee.salaries s
JOIN employee.dept_emp de on s.emp_no = de.emp_no
JOIN employee.employees e ON e.emp_no = s.emp_no
WHERE s.to_date = '9999-01-01' AND de.to_date='9999-01-01';

/* Grupujemy w podziale na płeć - wyznaczymy średnią, sumę wynagrodzeń dla płci oraz liczbę osób w każdej grupie. */
SELECT e.gender, COUNT(s.salary) AS number_of_people_in_gender,
SUM(s.salary) AS total_salary_in_gender, AVG(s.salary) AS average_salary_in_gender
FROM employee.salaries s
JOIN employee.employees e ON e.emp_no=s.emp_no
JOIN employee.dept_emp de on e.emp_no = de.emp_no
WHERE s.to_date = '9999-01-01' AND de.to_date = '9999-01-01'
GROUP BY e.gender;

/* Grupujemy w podziale na departamenty - będziemy wiedzieć, który departament najbardziej obciąża budżet wynagrodzeń, gdzie pracuje najwięcej osób
oraz gdzie średnio pracownicy zarabiają najlepiej. */
SELECT d.dept_name, COUNT(s.salary) AS number_of_people,
SUM(s.salary) AS total_salary, AVG(s.salary) AS average_salary
FROM employee.salaries s
JOIN employee.employees e ON e.emp_no=s.emp_no
JOIN employee.dept_emp de ON de.emp_no=e.emp_no
JOIN employee.departments d ON d.dept_no=de.dept_no
WHERE s.to_date = '9999-01-01' AND de.to_date='9999-01-01'
GROUP BY d.dept_name;


-- RAPORT PŁACOWY NR 2
/* W tej części wykonamy raport zarobków w podziale ze względu na płeć i departamenty, następnie ze względu na płeć oraz bez zróżnicowania. */
SELECT e.gender, d.dept_name, COUNT(s.salary) AS number_of_people,
SUM(s.salary) AS total_salary, AVG(s.salary) AS average_salary FROM employee.employees e
JOIN employee.salaries s USING(emp_no)
JOIN employee.dept_emp de USING(emp_no)
JOIN employee.departments d USING(dept_no)
WHERE s.to_date='9999-01-01' AND de.to_date='9999-01-01'
GROUP BY e.gender, d.dept_name WITH ROLLUP
ORDER BY d.dept_name;


-- RAPORT PŁACOWY NR 3
/* W tej części skupiamy się na wyznaczeniu różnicy zarobków w poszczególnych grupach - dla płci, departamentów oraz osób konkretnych płci w
 poszczególnych departamentach (zarówno klasycznej różnicy jak i stosunku). */
 
 /* W pierwszej części skupiamy się na płci. Wyznaczamy całkowitą liczbę osób danej płci, całkowitą sumę wynagrodzeń osób danej płci, średnie
 wynagrodzenie osób danej płci oraz stosunek (udział) wyznaczonych wartości do odpowiednio całkowtej liczby osób,
 całkowitej sumy wynagrodzeń oraz w stosunku do średniego wynagrodzenia pracownika danej firmy. */
WITH cte AS(SELECT e.gender,
COUNT(s.salary) AS total_number_of_people_of_gender,
SUM(s.salary) AS salary_of_gender,
AVG(s.salary) AS average_salary_of_gender
FROM employee.employees e
JOIN employee.salaries s USING(emp_no)
JOIN employee.dept_emp de on e.emp_no = de.emp_no
WHERE s.to_date='9999-01-01' AND de.to_date='9999-01-01'
GROUP BY e.gender)
SELECT *, total_number_of_people_of_gender/SUM(total_number_of_people_of_gender) OVER() AS gender_share_in_total_number_of_people,
salary_of_gender/SUM(salary_of_gender) OVER() AS gender_share_in_total_salary,
average_salary_of_gender/AVG(average_salary_of_gender) OVER() AS avg_salary_of_gender_vs_avg_salary
FROM cte;

/* Teraz wyznaczamy taki sam raport, ale zamiast analizować płeć, będziemy analizować departamenty. Także wykorzystamy w tym celu funkcje okna. */
WITH cte AS (SELECT d.dept_name,
COUNT(s.salary) AS total_number_of_people_in_dept,
SUM(s.salary) AS salary_of_dept,
AVG(s.salary) AS average_salary_of_dept
FROM employee.employees e
JOIN employee.salaries s USING (emp_no)
JOIN employee.dept_emp de USING(emp_no)
JOIN employee.departments d USING(dept_no)
WHERE s.to_date='9999-01-01' AND de.to_date='9999-01-01'
GROUP BY d.dept_name)
SELECT *, total_number_of_people_in_dept/SUM(total_number_of_people_in_dept) OVER() AS dept_share_in_total_number_of_people,
salary_of_dept/SUM(salary_of_dept) OVER() AS dept_share_in_total_salary,
average_salary_of_dept/AVG(average_salary_of_dept) OVER() AS avg_salary_of_dept_vs_avg_salary
FROM cte;

-- Sprawdźmy, w którym departamencie zarabia się średnio najwięcej, a w którym średnio najmniej - w tym celu posortujemy wyniki.
WITH cte AS (SELECT d.dept_name,
COUNT(s.salary) AS total_number_of_people_in_dept,
SUM(s.salary) AS salary_of_dept,
AVG(s.salary) AS average_salary_of_dept
FROM employee.employees e
JOIN employee.salaries s USING (emp_no)
JOIN employee.dept_emp de USING(emp_no)
JOIN employee.departments d USING(dept_no)
WHERE s.to_date='9999-01-01' AND de.to_date='9999-01-01'
GROUP BY d.dept_name)
SELECT *, total_number_of_people_in_dept/SUM(total_number_of_people_in_dept) OVER() AS dept_share_in_total_number_of_people,
salary_of_dept/SUM(salary_of_dept) OVER() AS dept_share_in_total_salary,
average_salary_of_dept/AVG(average_salary_of_dept) OVER() AS avg_salary_of_dept_vs_avg_salary
FROM cte
ORDER BY average_salary_of_dept DESC;

/* Teraz porównamy ilości osób danej płci, całkowite wynagrodzenia osób danej płci oraz średnie wynagrodzenia osób danej płci w konkretnych departamentach.
Dzięki temu dowiemy się czy przykładowo w dziale marketingu osoby płci męskiej zarabiają średnio więcej od osób płci żeńskiej. */
WITH cte as (SELECT e.gender, d.dept_name,
COUNT(s.salary) AS number_of_people_over_gender_dept,
SUM(s.salary) AS total_salary_over_gender_dept,
AVG(s.salary) AS average_salary_over_gender_dept
FROM employee.employees e
JOIN employee.salaries s USING(emp_no)
JOIN employee.dept_emp de USING(emp_no)
JOIN employee.departments d USING(dept_no)
WHERE s.to_date='9999-01-01' AND de.to_date='9999-01-01'
GROUP BY d.dept_name, e.gender)
SELECT *, number_of_people_over_gender_dept/SUM(number_of_people_over_gender_dept) OVER(PARTITION BY dept_name) AS number_of_people_by_gender_vs_total_number_of_people_in_dept,
total_salary_over_gender_dept/SUM(total_salary_over_gender_dept) OVER(PARTITION BY dept_name) AS total_salary_by_gender_vs_total_salary_in_dept,
average_salary_over_gender_dept/AVG(average_salary_over_gender_dept) OVER(PARTITION BY dept_name) AS avg_salary_by_gender_vs_avg_salary_in_dept
FROM cte
ORDER BY dept_name, gender;


-- RAPORT PŁACOWY NR 4
/* W czwartej części raportu skupiamy się na automatyzacji naszej - stworzeniu procedury. Na początek prostsza wersja procedury - generuje raport dot.
wynagrodzeń i ilości osób w podziale na płeć w danym departamencie. Procedura nie przyjmuje żadnych argumentów - generowany jest raport dot. wszystkich
osób obecnie pracujących (zakładamy tutaj że, wszystkie te osoby mają wartości w kolumnie to_date ustawione na '9999-01-01', a przy ewentualnym odejściu
pracownika wartość jest aktualizowana na datę odejścia. */

DELIMITER $$
CREATE PROCEDURE equal_pay()
BEGIN
	WITH cte AS (SELECT e.gender, d.dept_name, avg(s.salary) AS avg_salary, COUNT(*) AS number_of_people
	FROM employee.employees e
	JOIN employee.salaries s on e.emp_no = s.emp_no
	JOIN employee.dept_emp de on e.emp_no = de.emp_no
	JOIN employee.departments d on de.dept_no = d.dept_no
	WHERE de.to_date='9999-01-01' AND s.to_date='9999-01-01'
	GROUP BY d.dept_name, e.gender)
	SELECT *, avg_salary/AVG(avg_salary) OVER(PARTITION BY dept_name) AS avg_salary_by_dept_gender_vs_avg_salary_in_general FROM cte
	-- GROUP BY gender, dept_name
	ORDER BY dept_name;
    END $$

DELIMITER ;

/* Druga wersja procedury jest nieco bardziej zaawansowana. Wyciąga te same dane dotyczące wynagrodzeń dla wszystkich osób, które w momencie generowania
raportu są jeszcze zatrudnione. Pod uwagę jest brany fakt, że jeżeli osoba kończy pracę przykładowo 15.07 to będzie się liczyła jeszcze w obecnym raporcie -
stąd kolumna report_to, która oznacza do kiedy dany raport obowiązuje. */

DROP PROCEDURE IF EXISTS equal_pay2;

DELIMITER $$
CREATE PROCEDURE equal_pay2(IN report_date DATE)
BEGIN
	WITH cte AS (SELECT e.gender, d.dept_name, avg(s.salary) AS avg_salary, COUNT(*) AS amount_of_people, LAST_DAY(report_date) AS report_to, report_date
	FROM employee.employees e
	JOIN employee.salaries s on e.emp_no = s.emp_no
	JOIN employee.dept_emp de on e.emp_no = de.emp_no
	JOIN employee.departments d on de.dept_no = d.dept_no
	WHERE de.to_date>DATE_ADD(DATE_SUB(LAST_DAY(report_date), INTERVAL 1 MONTH), INTERVAL 1 DAY) AND s.to_date>DATE_ADD(DATE_SUB(LAST_DAY(report_date), INTERVAL 1 MONTH), INTERVAL 1 DAY)
	GROUP BY d.dept_name, e.gender)
	SELECT *, avg_salary/AVG(avg_salary) OVER (PARTITION BY dept_name) AS avg_salary_by_dept_gender_vs_avg_salary_in_dept FROM cte
	-- GROUP BY gender, dept_name
	ORDER BY dept_name, gender DESC;
END $$
DELIMITER ;

 -- Wywołanie procedury.
call equal_pay2('2000-01-01');
