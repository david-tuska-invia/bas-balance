package main

import (
	"fmt"
	"log"
	"github.com/david-tuska-invia/bas-balance/internal/pkg/store/mysql/db"

)

func init() {
	// Initialize database connection
	err := db.Connect()
	if err != nil {
		log.Fatalf("Failed to connect to the database: %v", err)
	}
}

func main() {
	transactions, err := db.ListBasTransactions()
	if err != nil {
		log.Fatalf("Failed to list transactions: %v", err)
	}

	for _, transaction := range transactions {
		fmt.Printf("Transaction: %+v\n", transaction)
	}

	fmt.Println("Hello, World!")
}