// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.28.0

package mysql

type Bastransation struct {
	BasTransactionID uint32 `db:"bas_transaction_id"`
	Name             string `db:"name"`
}
