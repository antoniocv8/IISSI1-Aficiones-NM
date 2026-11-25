USE hobbies_nm_db;

-- función 1

DELIMITER //

CREATE OR REPLACE FUNCTION f_get_hobby_id(
p_hobby_name VARCHAR(30)
) RETURNS INT
READS SQL DATA
BEGIN
	DECLARE v_hobby_id INT;
	
	SELECT MIN(h.hobby_id) INTO v_hobby_id
	FROM hobbies h
	WHERE h.hobby_name = p_hobby_name;
	
	RETURN v_hobby_id;
END //

DELIMITER ;

SELECT f_get_hobby_id('Cine') AS cine, f_get_hobby_id('Ajedrez') AS ajedrez, f_get_hobby_id('Deporte') AS deporte;

-- función 2

DELIMITER //

CREATE OR REPLACE FUNCTION f_hobby_users(p_hobby_id INT)
RETURNS INT 
READS SQL DATA 
BEGIN 
	DECLARE v_users INT;
	
	SELECT COUNT(*) INTO v_users
	FROM users_hobbies uh
	WHERE uh.hobby_id = p_hobby_id;
	
	RETURN v_users;
END //

DELIMITER ;

SELECT h.hobby_id, h.hobby_name, f_hobby_users(h.hobby_id) AS users
FROM hobbies h
ORDER BY users DESC, h.hobby_id;

