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

SELECT f_get_hobby_id('Deporte');