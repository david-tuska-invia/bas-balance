-- +goose Up
-- +goose StatementBegin
SELECT 'up SQL query';
-- +goose StatementEnd

CREATE TABLE BasTransation (
	bas_transaction_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(255) NOT NULL
);


-- +goose Down
-- +goose StatementBegin
SELECT 'down SQL query';
-- +goose StatementEnd


DROP TABLE IF EXISTS BasTransation;