#!make
-include .env

BINARY_NAME=bas-balance
GOCMD=go
#DOCKER_IMAGE ?= git.invia.io/cee-nbc/nbc-reviews/review-service
# data source name
DSN := ${DB_USER}:${DB_PASS}@tcp(${DB_HOST})/${DB_NAME}?parseTime=true&tls=${DB_SSL}

.DEFAULT_GOAL := help

GO_GAPPIT_VERSION=latest
GO_LINT_VERSION=latest
GO_SQLC_VERSION=v1.28

MAKEFLAGS += --no-print-directory

## Test:
.PHONY: test
test: audit lint lint-proto test-cover ## Audit && Lint && Test.

.PHONY: lint
lint: ## Lint the source files.
	golangci-lint run ./... 

.PHONY: lint-proto
lint-proto: ## Lint the proto files.
	buf lint

.PHONY: test-cover 
test-cover: ## Run tests and show coverage.
	$(GOCMD) test -v -race -coverprofile cp.out ./...
	$(GOCMD) tool cover -html=cp.out -o cp.html
	goverreport -coverprofile=cp.out

.PHONY: audit
audit: ## Run quality control check.
	govulncheck ./...

.PHONY: exhaustruct
exhaustruct: ## Check if all fields are set in the struct.
	exhaustruct ./... 2>&1 | grep -Ev "(_test|\.gen)\.go" | grep -Ev "(aws.Config|http.Client|cobra.Command|redis.Options|oapi.StdHTTPServerOptions|cors.Options|openapi3filter.Options|filedesc.Builder|filetype.Builder|s3.GetObjectInput|ses.SendRawEmailInput|nethttpmiddleware.Options|ssh.ClientConfig) is missing fields " | sort

## Build:
.PHONY: build
build: ## Build application.
	mkdir -p ./dist
	CGO_ENABLED=0 $(GOCMD) build -o ./dist/$(BINARY_NAME) -v ./cmd/bas-balance/main.go

#.PHONY: build-image
#build-image: build ## Build docker image.
#	docker build -t ${DOCKER_IMAGE} .

.PHONY: clean
clean: ## Remove build related files.
	rm -rf ./dist

## Run:
.PHONY: run
run: ## Run server.
	go run ./cmd/bas-balance/... serve

#.PHONY: watch
#watch: ## Run code with cosmtrek/air (automatic reload).
#	@air \
#		--build.cmd "make build" --build.bin "./dist/${BINARY_NAME}" --build.delay "100" \
#		--build.args_bin "serve" \
#		--build.exclude_dir "" \
#		--build.include_ext "go, tpl, tmpl, html, css, scss, js, ts, sql, jpeg, jpg, gif, png, bmp, svg, webp, ico" \
#		--misc.clean_on_exit "true"

#.PHONY: import
#import: ## Import data from Amadeus Trusted Reviews
#	go run ./cmd/reviews/... import

#.PHONY: import-ownama
#import-ownama: ## Import own Amadeus Trusted Reviews
#	go run ./cmd/reviews/... import ownama

#.PHONY: import-allama
#import-allama: ## Import all Amadeus Trusted Reviews
#	go run ./cmd/reviews/... import allama

#.PHONY: hotelstats-recalculate
#hotelstats-recalculate: ## Publish hotel stats to the queue.
#	go run ./cmd/hotelstats/recalculate.go $(id)

## Development:
.PHONY: services-start
services-start: ## Start needed additional services.
	docker compose up -d

.PHONY: services-stop
services-stop: ## Stop needed additional services.
	docker compose down

.PHONY: dep
dep: ## Download the dependencies.
	go mod download

.PHONY: gen
gen: ## Run Code generators.
	go generate ./...

.PHONY: tools
tools: tools-basic tools-db tools-oapi ## Install all tools.

.PHONY: tools-basic
tools-basic: ## Install basic tools.
	$(GOCMD) install git.invia.io/book/go-packages/gappit/cmd/gappit@$(GO_GAPPIT_VERSION)
	$(GOCMD) install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GO_LINT_VERSION)
	$(GOCMD) install github.com/mcubik/goverreport@v1.0.0
	$(GOCMD) install github.com/matryer/moq@latest
	$(GOCMD) install golang.org/x/vuln/cmd/govulncheck@latest
	$(GOCMD) install github.com/GaijinEntertainment/go-exhaustruct/v3/cmd/exhaustruct@latest

.PHONY: tools-db
tools-db: ## Install DB tools.
	$(GOCMD) install github.com/sqlc-dev/sqlc/cmd/sqlc@$(GO_SQLC_VERSION)
	$(GOCMD) install github.com/pressly/goose/v3/cmd/goose@latest

.PHONY: tools-oapi
tools-oapi: ## Install oapi tools.
	$(GOCMD) install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest

#.PHONY: tools-protobuf
#tools-protobuf: ## Install protobuf tools.
#	$(GOCMD) install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v2.16.0
#	$(GOCMD) install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.16.0
#	$(GOCMD) install google.golang.org/protobuf/cmd/protoc-gen-go@v1.30.0
#	$(GOCMD) install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
#	$(GOCMD) install github.com/envoyproxy/protoc-gen-validate@v1.0.2
#	$(GOCMD) install github.com/bufbuild/buf/cmd/buf@v1.47.2

## Database
.PHONY: migst
migst: ## Dump the migration status for the current db.
	@goose -dir db/migrations -table _db_version mysql '$(DSN)' status

.PHONY: migup
migup: ## Migrate the DB to the most recent version available.
	@goose -dir db/migrations -table _db_version mysql '$(DSN)' up

.PHONY: migdown
migdown: ## Roll back the version by 1.
	@goose -dir db/migrations -table _db_version mysql '$(DSN)' down

.PHONY: migcreate
migcreate: ## Create a new migration.
	@goose -dir db/migrations create $(name) sql

GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

## Help:
help: ## Show this help.
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-23s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)
