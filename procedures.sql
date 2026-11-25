--
-- Autor: David Ruiz
-- Fecha: Octubre de 2026
-- Descripción: Procedimiento para insertar usuarios en Aficiones dinámicas
--

USE hobbies_nm_db;

-- Insertar usuario
DELIMITER //
CREATE OR REPLACE PROCEDURE p_insert_user(
    IN p_full_name VARCHAR(64),
    IN p_gender ENUM('MASCULINO','FEMENINO','OTRO'),
    IN p_age INT,
    IN p_email VARCHAR(255)
)
BEGIN
    INSERT INTO users (full_name, gender, age, email)
    VALUES (p_full_name, p_gender, p_age, p_email);
END //
DELIMITER ;

DELIMITER //
CREATE OR REPLACE PROCEDURE p_add_hobby_to_user(
	IN p_user_id INT,
	IN p_hobby_name VARCHAR(128)
)
BEGIN
	DECLARE v_hobby_id INT;
	SET v_hobby_id = f_get_hobby_id(p_hobby_name);
	IF EXISTS (
		SELECT *
		FROM users_hobbies uh 
		WHERE uh.user_id =p_user_id
			AND uh.hobby_id = v_hobby_id
		) THEN
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'RN03: El usuario ya tiene esa afición';
		END IF;
		IF v_hobby_id IS NULL THEN
			INSERT INTO hobbies (hobby_name) VALUES (p_hobby_name);
			SET v_hobby_id = LAST_INSERT_ID();
		END IF;
		INSERT INTO users_hobbies (user_id, hobby_id) VALUES (p_user_id, v_hobby_id);
END //
DELIMITER ;

SELECT uh.user_id, h.hobby_name
FROM users_hobbies uh
JOIN hobbies h ON h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;

CALL p_add_hobby_to_user(1, 'Ajedrez');

SELECT uh.user_id, h.hobby_name
FROM users_hobbies uh
JOIN hobbies h ON h.hobby_id = uh.hobby_id
WHERE uh.user_id = 1;

SELECT COUNT(*) AS hobbies_in_catalog
FROM hobbies h;


DELIMITER //

CREATE OR REPLACE PROCEDURE p_add_hobby_to_user_tx(
	IN p_user_id INT,
	IN p_hobby_name VARCHAR(128)
)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;
	
	START TRANSACTION;
		CALL p_add_hobby_to_user(p_user_id, p_hobby_name);
	COMMIT;
END //

DELIMITER ;

CALL p_add_hobby_to_user_tx(3, 'Ajedrez');

SELECT uh.user_id, h.hobby_id, h.hobby_name
FROM users_hobbies uh
JOIN hobbies h ON h.hobby_id = uh.hobby_id
WHERE uh.user_id = 3;


DELIMITER //
CREATE OR REPLACE PROCEDURE p_merge_hobbies(
	IN p_old_hobby_id INT,
	IN p_new_hobby_id INT 
)
BEGIN 
	IF p_old_hobby_id = p_new_hobby_id THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'RI02: No se puede fusionar una afición consigo misma';
	END IF;
	IF NOT EXISTS (SELECT * FROM hobbies h WHERE h.hobby_id = p_old_hobby_id)
		OR NOT EXISTS(SELECT * FROM hobbies h WHERE h.hobby_id = p_new_hobby_id) THEN 
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT= 'RI02: Las dos aficiones deben estar en el catálogo';
	END IF;
	DELETE FROM users_hobbies
	WHERE hobby_id = p_old_hobby_id
		AND user_id IN ( 
			SELECT users_hobbies uh
			WHERE uh.hobby_id = p_new_hobby_id
		);
	UPDATE users_hobbies SET hobby_id = p_new_hobby_id WHERE hobby_id = p_old_hobby_id;
END // 

DELIMITER ;

DELIMITER //

CREATE OR REPLACE PROCEDURE p_merge_hobbies_tx(
	IN p_old_hobby_id INT,
	IN p_new_hobby_id INT 
)
BEGIN
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		ROLLBACK;
		RESIGNAL;
	END;
	
	START TRANSACTION;
		CALL p_merge_hobbies(p_old_hobby_id, p_new_hobby_id);
	COMMIT;
END //

DELIMITER ;
	
CALL p_populate();

SELECT h.hobby_id, h.hobby_name, f_hobby_users(h.hobby_id) AS users
FROM hobbies h
ORDER BY users DESC, h.hobby_id;

CALL p_merge_hobbies_tx(3,2);

SELECT h.hobby_id, h.hobby_name, f_hobby_users(h.hobby_id) AS users
FROM hobbies h
ORDER BY users DESC, h.hobby_id;

SELECT uh.user_id
FROM users_hobbies uh
WHERE uh.hobby_id = 2
ORDER BY uh.user_id;

CALL p_populate();