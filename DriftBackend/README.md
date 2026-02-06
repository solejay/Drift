# Drift Backend

Vapor 4 Swift backend for the **Drift** spending awareness app. Provides RESTful APIs for user authentication, Plaid bank integration, transaction management, spending summaries, and push notification support.

---

## Table of Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [Architecture](#architecture)
- [API Reference](#api-reference)
  - [Health Check](#health-check)
  - [Authentication](#authentication)
  - [Plaid Integration](#plaid-integration)
  - [Accounts](#accounts)
  - [Transactions](#transactions)
  - [Spending Summaries](#spending-summaries)
  - [Preferences](#preferences)
  - [Notifications](#notifications)
  - [Export](#export)
- [Security](#security)
- [Database Schema](#database-schema)
- [Testing](#testing)
- [Deployment Notes](#deployment-notes)

---

## Requirements

| Dependency     | Minimum Version |
|----------------|-----------------|
| Swift          | 5.9+            |
| macOS          | 13+ (Ventura)   |
| PostgreSQL     | 14+             |
| Xcode          | 15+ (optional, for IDE support) |

### Swift Package Dependencies

| Package                  | Version  | Purpose                   |
|--------------------------|----------|---------------------------|
| vapor/vapor              | 4.89.0+  | Web framework             |
| vapor/fluent             | 4.9.0+   | ORM / database toolkit    |
| vapor/fluent-postgres-driver | 2.8.0+ | PostgreSQL driver       |
| vapor/jwt                | 4.2.0+   | JSON Web Token signing    |

---

## Quick Start

### 1. Clone the repository

```bash
git clone <repository-url>
cd DriftBackend
```

### 2. Install dependencies

Swift Package Manager resolves dependencies automatically on first build:

```bash
swift package resolve
```

### 3. Set up PostgreSQL

```bash
# Create the database and user
createuser drift
createdb drift_db -O drift

# Or via psql
psql -c "CREATE USER drift WITH PASSWORD 'password';"
psql -c "CREATE DATABASE drift_db OWNER drift;"
```

### 4. Configure environment variables

Create a `.env` file or export the required variables (see [Environment Variables](#environment-variables) below).

### 5. Run the server

```bash
swift run App serve --env development
```

In development mode, migrations run automatically via `app.autoMigrate()`. The server starts on `http://localhost:8080` by default.

### 6. Verify

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected"
}
```

---

## Environment Variables

| Variable          | Required | Default       | Description                                           |
|-------------------|----------|---------------|-------------------------------------------------------|
| `DATABASE_URL`    | No*      | --            | Full Postgres connection URL (overrides individual DB vars) |
| `DB_HOST`         | No*      | `localhost`   | Database hostname                                     |
| `DB_PORT`         | No*      | `5432`        | Database port                                         |
| `DB_USER`         | No*      | `drift`       | Database username                                     |
| `DB_PASSWORD`     | No*      | `password`    | Database password                                     |
| `DB_NAME`         | No*      | `drift_db`    | Database name                                         |
| `JWT_SECRET`      | **Yes**  | --            | Secret key for HS256 JWT signing (fatal if missing)   |
| `PLAID_CLIENT_ID` | **Yes**  | `""`          | Plaid API client ID                                   |
| `PLAID_SECRET`    | **Yes**  | `""`          | Plaid API secret key                                  |
| `PLAID_ENV`       | No       | `sandbox`     | Plaid environment: `sandbox`, `development`, or `production` |

*Either `DATABASE_URL` or the individual `DB_*` variables must be provided for database connectivity.

---

## Architecture

### Project Structure

```
Sources/App/
  Controllers/        # Route handlers grouped by feature
    AuthController.swift
    PlaidController.swift
    AccountController.swift
    TransactionController.swift
    SummaryController.swift
    PreferencesController.swift
    NotificationController.swift
    ExportController.swift
  DTOs/               # Data Transfer Objects for request/response bodies
    AuthDTOs.swift
    AccountDTOs.swift
    TransactionDTOs.swift
    SummaryDTOs.swift
    PreferenceDTOs.swift
    NotificationDTOs.swift
    PlaidDTOs.swift
  Middleware/          # Request pipeline middleware
    JWTAuthMiddleware.swift
    RateLimitMiddleware.swift
    InputValidation.swift
  Migrations/          # Fluent database migrations
    CreateUser.swift
    CreateRefreshToken.swift
    CreatePlaidItem.swift
    CreateAccount.swift
    CreateTransaction.swift
    CreateUserPreference.swift
    CreateDeviceToken.swift
  Models/              # Fluent ORM models
    User.swift
    RefreshToken.swift
    PlaidItem.swift
    Account.swift
    Transaction.swift
    UserPreference.swift
    DeviceToken.swift
  Services/            # Business logic and external API integrations
    PlaidAPIService.swift
    JWTPayload.swift
  configure.swift      # Application configuration (DB, JWT, middleware, migrations)
  routes.swift         # Route registration
```

### Design Patterns

- **MVC with Service Layer**: Controllers handle HTTP concerns, services encapsulate business logic and external API calls.
- **JWT Authentication**: Stateless authentication using HS256-signed JWTs with a 1-hour access token and 30-day refresh token.
- **Actor-based Services**: `PlaidAPIService` and `RateLimiter` use Swift's actor model for thread-safe concurrent access.
- **DTO Pattern**: Request and response bodies are separated from database models using dedicated DTO structs.
- **Fluent ORM**: All database access uses Fluent's async query builder with PostgreSQL.
- **snake_case JSON**: All API responses use snake_case keys via global JSON encoder/decoder configuration.

---

## API Reference

All API endpoints are prefixed with `/api/v1` unless otherwise noted. Authenticated endpoints require a valid JWT in the `Authorization: Bearer <token>` header.

### Health Check

#### `GET /health`

Returns server and database status.

| Property     | Details          |
|-------------|------------------|
| Auth Required | No             |

**Response:**

```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected"
}
```

**Example:**

```bash
curl http://localhost:8080/health
```

---

### Authentication

#### `POST /api/v1/auth/register`

Register a new user account.

| Property     | Details          |
|-------------|------------------|
| Auth Required | No             |

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "MySecure1",
  "display_name": "Jane Doe",
  "timezone": "America/New_York"
}
```

| Field          | Type   | Required | Validation                                              |
|----------------|--------|----------|---------------------------------------------------------|
| `email`        | String | Yes      | Valid email format, HTML stripped, trimmed               |
| `password`     | String | Yes      | 8+ chars, at least 1 uppercase letter, at least 1 digit |
| `display_name` | String | No       | HTML stripped, trimmed                                  |
| `timezone`     | String | No       | Defaults to `"UTC"`                                     |

**Response (201):**

```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "Jane Doe",
    "timezone": "America/New_York",
    "created_at": "2025-01-15T10:30:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "base64-encoded-random-token"
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"MySecure1","display_name":"Jane Doe"}'
```

---

#### `POST /api/v1/auth/login`

Authenticate an existing user.

| Property     | Details          |
|-------------|------------------|
| Auth Required | No             |

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "MySecure1",
  "device_id": "optional-device-identifier"
}
```

| Field       | Type   | Required | Description                     |
|-------------|--------|----------|---------------------------------|
| `email`     | String | Yes      | Registered email address        |
| `password`  | String | Yes      | Account password                |
| `device_id` | String | No       | Device identifier for token mgmt |

**Response (200):**

```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "Jane Doe",
    "timezone": "America/New_York",
    "created_at": "2025-01-15T10:30:00Z"
  },
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "base64-encoded-random-token"
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"MySecure1"}'
```

---

#### `POST /api/v1/auth/refresh`

Refresh an expired access token.

| Property     | Details          |
|-------------|------------------|
| Auth Required | No             |

**Request Body:**

```json
{
  "refresh_token": "base64-encoded-random-token"
}
```

**Response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": null
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"your-refresh-token-here"}'
```

---

#### `POST /api/v1/auth/logout`

Revoke refresh tokens. Can revoke a single token or all tokens for the user.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "refresh_token": "optional-specific-token",
  "all_devices": false
}
```

| Field           | Type    | Required | Description                                  |
|-----------------|---------|----------|----------------------------------------------|
| `refresh_token` | String  | No       | Specific token to revoke                     |
| `all_devices`   | Boolean | Yes      | If `true`, revokes all tokens for the user   |

**Response:** `200 OK`

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"all_devices":true}'
```

---

#### `DELETE /api/v1/auth/account`

Permanently delete user account and all associated data (CCPA/PIPEDA compliance). Requires password confirmation.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "password": "MySecure1"
}
```

**Cascade Deletion Order:**
1. Device tokens
2. User preferences
3. Transactions
4. Accounts
5. Plaid items
6. Refresh tokens
7. User record

**Response:** `200 OK`

**Example:**

```bash
curl -X DELETE http://localhost:8080/api/v1/auth/account \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"password":"MySecure1"}'
```

---

### Plaid Integration

#### `POST /api/v1/plaid/link-token`

Generate a Plaid Link token to initiate the bank connection flow in the iOS app.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:** None

**Response (200):**

```json
{
  "link_token": "link-sandbox-12345..."
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/plaid/link-token \
  -H "Authorization: Bearer <access_token>"
```

---

#### `POST /api/v1/plaid/exchange`

Exchange a Plaid public token for an access token, create accounts, and trigger initial transaction sync.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "public_token": "public-sandbox-12345..."
}
```

**Response (200):**

```json
{
  "accounts": [
    {
      "id": "uuid",
      "plaid_account_id": "plaid-acc-123",
      "name": "Checking Account",
      "official_name": "Personal Checking",
      "type": "depository",
      "mask": "1234",
      "current_balance": 1500.50,
      "available_balance": 1450.00,
      "institution_name": null,
      "is_hidden": false
    }
  ]
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/plaid/exchange \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"public_token":"public-sandbox-12345"}'
```

---

#### `POST /api/v1/plaid/sync`

Manually trigger a transaction sync for all linked Plaid items.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:** None

**Response (200):**

```json
{
  "added": 15,
  "modified": 2,
  "removed": 1
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/plaid/sync \
  -H "Authorization: Bearer <access_token>"
```

---

#### `POST /api/v1/plaid/webhook`

Receive Plaid webhook events. This endpoint is **not** behind JWT authentication but checks for the `Plaid-Verification` header.

| Property     | Details          |
|-------------|------------------|
| Auth Required | No (webhook verification) |

**Handled Webhook Types:**

| Webhook Type   | Code                      | Action                         |
|----------------|---------------------------|--------------------------------|
| TRANSACTIONS   | SYNC_UPDATES_AVAILABLE    | Triggers transaction sync      |
| TRANSACTIONS   | DEFAULT_UPDATE            | Triggers transaction sync      |
| ITEM           | ERROR                     | Logs error                     |
| ITEM           | PENDING_EXPIRATION        | Logs warning                   |

**Response:** `200 OK`

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/plaid/webhook \
  -H "Content-Type: application/json" \
  -H "Plaid-Verification: <verification-token>" \
  -d '{"webhook_type":"TRANSACTIONS","webhook_code":"SYNC_UPDATES_AVAILABLE","item_id":"item-123"}'
```

---

### Accounts

#### `GET /api/v1/accounts`

List all visible (non-hidden) accounts for the authenticated user.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Response (200):**

```json
{
  "accounts": [
    {
      "id": "uuid",
      "plaid_account_id": "plaid-acc-123",
      "name": "Checking Account",
      "official_name": "Personal Checking",
      "type": "depository",
      "mask": "1234",
      "current_balance": 1500.50,
      "available_balance": 1450.00,
      "institution_name": null,
      "is_hidden": false
    }
  ]
}
```

**Example:**

```bash
curl http://localhost:8080/api/v1/accounts \
  -H "Authorization: Bearer <access_token>"
```

---

#### `PUT /api/v1/accounts/:id`

Update account properties (e.g., hide/show an account).

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "is_hidden": true
}
```

| Field       | Type    | Required | Description                    |
|-------------|---------|----------|--------------------------------|
| `is_hidden` | Boolean | No       | Whether to hide this account   |

**Response (200):** Updated `AccountDTO` object.

**Example:**

```bash
curl -X PUT http://localhost:8080/api/v1/accounts/<account-uuid> \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"is_hidden":true}'
```

---

#### `DELETE /api/v1/accounts/:id`

Delete an account and all associated transactions. If this was the last account linked to a Plaid item, the Plaid item is also deleted.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Response:** `200 OK`

**Example:**

```bash
curl -X DELETE http://localhost:8080/api/v1/accounts/<account-uuid> \
  -H "Authorization: Bearer <access_token>"
```

---

### Transactions

#### `GET /api/v1/transactions`

List transactions with pagination, date filtering, account filtering, and category filtering. Excluded transactions are not returned.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Query Parameters:**

| Parameter    | Type   | Default | Description                                      |
|-------------|--------|---------|--------------------------------------------------|
| `page`       | Int    | 1       | Page number (1-indexed)                          |
| `per_page`   | Int    | 50      | Items per page (max 100)                         |
| `start_date` | Date   | --      | Filter transactions on or after this date (ISO 8601) |
| `end_date`   | Date   | --      | Filter transactions on or before this date (ISO 8601) |
| `account_ids`| String | --      | Comma-separated list of account UUIDs            |
| `categories` | String | --      | Comma-separated list of category names           |

**Response (200):**

```json
{
  "transactions": [
    {
      "id": "uuid",
      "account_id": "uuid",
      "plaid_transaction_id": "plaid-txn-123",
      "amount": 25.99,
      "date": "2025-01-15T00:00:00Z",
      "merchant_name": "Starbucks",
      "category": "food",
      "description": null,
      "is_pending": false,
      "is_excluded": false
    }
  ],
  "total": 150,
  "page": 1,
  "per_page": 50,
  "has_more": true
}
```

**Example:**

```bash
curl "http://localhost:8080/api/v1/transactions?page=1&per_page=20&categories=food,shopping" \
  -H "Authorization: Bearer <access_token>"
```

---

#### `PUT /api/v1/transactions/:id`

Update a transaction's category or exclusion status.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "category": "entertainment",
  "is_excluded": false
}
```

| Field         | Type    | Required | Description                            |
|---------------|---------|----------|----------------------------------------|
| `category`    | String  | No       | Override the transaction category       |
| `is_excluded` | Boolean | No       | Exclude from summaries and calculations |

**Response (200):** Updated `TransactionDTO` object.

**Example:**

```bash
curl -X PUT http://localhost:8080/api/v1/transactions/<transaction-uuid> \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"category":"entertainment"}'
```

---

### Spending Summaries

#### `GET /api/v1/summary/daily`

Get a daily spending summary with category breakdown, top transactions, and comparison to yesterday.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Query Parameters:**

| Parameter | Type | Default | Description                       |
|-----------|------|---------|-----------------------------------|
| `date`    | Date | Today   | The date to summarize (ISO 8601)  |

**Response (200):**

```json
{
  "date": "2025-01-15T00:00:00Z",
  "total_spent": 85.50,
  "total_income": 0,
  "transaction_count": 5,
  "category_breakdown": [
    {
      "id": "uuid",
      "category": "food",
      "amount": 45.00,
      "transaction_count": 3,
      "percentage_of_total": 0.526
    }
  ],
  "top_transactions": [
    {
      "id": "uuid",
      "account_id": "uuid",
      "amount": 25.99,
      "date": "2025-01-15T00:00:00Z",
      "merchant_name": "Restaurant",
      "category": "food",
      "is_pending": false,
      "is_excluded": false
    }
  ],
  "comparison_to_yesterday": 0.15
}
```

**Example:**

```bash
curl "http://localhost:8080/api/v1/summary/daily?date=2025-01-15T00:00:00Z" \
  -H "Authorization: Bearer <access_token>"
```

---

#### `GET /api/v1/summary/weekly`

Get a weekly spending summary with daily breakdown, category analysis, top merchants, and comparison to last week.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Query Parameters:**

| Parameter | Type | Default | Description                                  |
|-----------|------|---------|----------------------------------------------|
| `date`    | Date | Today   | Any date within the desired week (ISO 8601)  |

**Response (200):**

```json
{
  "week_start_date": "2025-01-13T00:00:00Z",
  "week_end_date": "2025-01-19T00:00:00Z",
  "total_spent": 450.00,
  "total_income": 2000.00,
  "transaction_count": 25,
  "category_breakdown": [ ... ],
  "daily_spending": [
    {
      "id": "uuid",
      "date": "2025-01-13T00:00:00Z",
      "amount": 65.00,
      "transaction_count": 4
    }
  ],
  "top_merchants": [
    {
      "id": "uuid",
      "merchant_name": "Starbucks",
      "amount": 35.00,
      "transaction_count": 5,
      "category": "food"
    }
  ],
  "comparison_to_last_week": -0.08
}
```

**Example:**

```bash
curl "http://localhost:8080/api/v1/summary/weekly?date=2025-01-15T00:00:00Z" \
  -H "Authorization: Bearer <access_token>"
```

---

#### `GET /api/v1/summary/monthly`

Get a monthly spending summary with weekly breakdown, daily heatmap, category analysis, top merchants, and comparison to last month.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Query Parameters:**

| Parameter | Type | Default        | Description       |
|-----------|------|----------------|-------------------|
| `month`   | Int  | Current month  | Month (1-12)      |
| `year`    | Int  | Current year   | Year (e.g. 2025)  |

**Response (200):**

```json
{
  "month": 1,
  "year": 2025,
  "total_spent": 2100.00,
  "total_income": 5000.00,
  "transaction_count": 120,
  "category_breakdown": [ ... ],
  "weekly_spending": [
    {
      "id": "uuid",
      "week_number": 1,
      "start_date": "2025-01-01T00:00:00Z",
      "end_date": "2025-01-07T00:00:00Z",
      "amount": 520.00,
      "transaction_count": 30
    }
  ],
  "daily_heatmap": [ ... ],
  "top_merchants": [ ... ],
  "comparison_to_last_month": 0.05
}
```

**Example:**

```bash
curl "http://localhost:8080/api/v1/summary/monthly?month=1&year=2025" \
  -H "Authorization: Bearer <access_token>"
```

---

### Preferences

#### `GET /api/v1/preferences`

Get user preferences. If no preferences exist, default preferences are created and returned.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Response (200):**

```json
{
  "id": "uuid",
  "notification_time": "20:00",
  "selected_categories": [],
  "notification_enabled": true,
  "weekly_summary_enabled": true,
  "daily_summary_enabled": true,
  "timezone": "UTC",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z"
}
```

**Example:**

```bash
curl http://localhost:8080/api/v1/preferences \
  -H "Authorization: Bearer <access_token>"
```

---

#### `PUT /api/v1/preferences`

Update user preferences. Only include the fields you want to change.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "notification_time": "09:00",
  "selected_categories": ["food", "shopping"],
  "notification_enabled": true,
  "weekly_summary_enabled": true,
  "daily_summary_enabled": false,
  "timezone": "America/New_York"
}
```

| Field                    | Type     | Required | Description                        |
|--------------------------|----------|----------|------------------------------------|
| `notification_time`      | String   | No       | Daily notification time (HH:mm)    |
| `selected_categories`    | [String] | No       | Categories to track                |
| `notification_enabled`   | Boolean  | No       | Enable push notifications          |
| `weekly_summary_enabled` | Boolean  | No       | Enable weekly summary notifications|
| `daily_summary_enabled`  | Boolean  | No       | Enable daily summary notifications |
| `timezone`               | String   | No       | User timezone (IANA format)        |

**Response (200):** Updated `PreferenceResponse` object.

**Example:**

```bash
curl -X PUT http://localhost:8080/api/v1/preferences \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"notification_time":"09:00","daily_summary_enabled":false}'
```

---

### Notifications

#### `POST /api/v1/notifications/register-device`

Register a device token for push notifications.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "token": "device-push-token-string",
  "platform": "ios"
}
```

| Field      | Type   | Required | Validation                       |
|------------|--------|----------|----------------------------------|
| `token`    | String | Yes      | APNs/FCM device token            |
| `platform` | String | Yes      | Must be `"ios"` or `"android"`   |

**Response (200):**

```json
{
  "id": "uuid",
  "token": "device-push-token-string",
  "platform": "ios",
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/notifications/register-device \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"token":"apns-device-token","platform":"ios"}'
```

---

#### `DELETE /api/v1/notifications/unregister-device`

Remove a device token from push notification registration.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:**

```json
{
  "token": "device-push-token-string"
}
```

**Response:** `200 OK`

**Example:**

```bash
curl -X DELETE http://localhost:8080/api/v1/notifications/unregister-device \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"token":"apns-device-token"}'
```

---

#### `POST /api/v1/notifications/test`

Send a test push notification to all registered devices for the authenticated user.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Request Body:** None

**Response (200):**

```json
{
  "success": true,
  "message": "Test notification queued for 2 device(s)."
}
```

**Example:**

```bash
curl -X POST http://localhost:8080/api/v1/notifications/test \
  -H "Authorization: Bearer <access_token>"
```

---

### Export

#### `GET /api/v1/export/transactions`

Export transactions as a CSV file. Excluded transactions are not included. Limited to 10,000 records.

| Property     | Details          |
|-------------|------------------|
| Auth Required | **Yes**        |

**Query Parameters:**

| Parameter    | Type | Required | Description                                      |
|-------------|------|----------|--------------------------------------------------|
| `start_date` | Date | No       | Filter transactions on or after this date        |
| `end_date`   | Date | No       | Filter transactions on or before this date       |

**Response:** CSV file download (`text/csv`) with the following columns:

```
date,merchant_name,category,amount,description,is_pending,account_id
```

**Example:**

```bash
curl "http://localhost:8080/api/v1/export/transactions?start_date=2025-01-01T00:00:00Z" \
  -H "Authorization: Bearer <access_token>" \
  -o transactions.csv
```

---

## Security

### JWT Authentication Flow

1. User registers or logs in and receives an **access token** (1-hour expiry) and a **refresh token** (30-day expiry).
2. Access tokens are signed using HS256 with the `JWT_SECRET` environment variable.
3. Refresh tokens are random 256-bit values, hashed with Bcrypt before storage.
4. The JWT payload contains: `sub` (subject), `exp` (expiration), `iat` (issued at), and `user_id`.
5. Protected routes require a valid access token in the `Authorization: Bearer <token>` header.

### Password Security

- Passwords are hashed with **Bcrypt** before storage.
- Password requirements: minimum 8 characters, at least 1 uppercase letter, at least 1 digit.

### Rate Limiting

Per-user and per-IP rate limiting is enforced via `RateLimitMiddleware`:

| Context          | Limit              |
|------------------|--------------------|
| Authenticated    | 100 requests/minute (per user ID) |
| Unauthenticated  | 20 requests/minute (per IP)       |

Exceeding the limit returns `429 Too Many Requests`.

### CORS Configuration

CORS is configured to allow:

| Setting           | Value                                    |
|-------------------|------------------------------------------|
| Allowed Origins   | All (`*`)                                |
| Allowed Methods   | GET, POST, PUT, DELETE, OPTIONS          |
| Allowed Headers   | Accept, Authorization, Content-Type, Origin |

For production, restrict `allowedOrigin` to your specific frontend domains.

### Input Validation and Sanitization

The `InputValidation` utility provides:

- **Email validation**: Regex-based email format checking.
- **Password validation**: Minimum length, uppercase, and digit requirements.
- **HTML sanitization**: Strips HTML tags and trims whitespace from user inputs.

### Plaid Webhook Verification

The webhook endpoint (`POST /api/v1/plaid/webhook`) is publicly accessible but checks for the `Plaid-Verification` header. A warning is logged if the header is absent. For production, implement full Plaid webhook signature verification.

### Account Deletion (CCPA/PIPEDA Compliance)

The `DELETE /api/v1/auth/account` endpoint performs a complete cascade deletion of all user data, including device tokens, preferences, transactions, accounts, Plaid items, and refresh tokens, before deleting the user record itself. Password confirmation is required.

---

## Database Schema

### users

| Column        | Type      | Constraints      | Description               |
|---------------|-----------|------------------|---------------------------|
| id            | UUID      | PK               | Primary key               |
| email         | String    | NOT NULL, UNIQUE | User email (lowercase)    |
| password_hash | String    | NOT NULL         | Bcrypt password hash      |
| display_name  | String    | NULLABLE         | User display name         |
| timezone      | String    | NULLABLE         | IANA timezone string      |
| created_at    | Timestamp | Auto-set         | Record creation time      |
| updated_at    | Timestamp | Auto-set         | Last update time          |

### refresh_tokens

| Column       | Type      | Constraints     | Description                |
|--------------|-----------|-----------------|----------------------------|
| id           | UUID      | PK              | Primary key                |
| user_id      | UUID      | FK -> users     | Owner user                 |
| token_hash   | String    | NOT NULL        | Bcrypt hash of token       |
| device_id    | String    | NULLABLE        | Device identifier          |
| is_revoked   | Boolean   | NOT NULL        | Whether token is revoked   |
| expires_at   | Timestamp | NOT NULL        | Token expiration (30 days) |
| created_at   | Timestamp | Auto-set        | Record creation time       |
| last_used_at | Timestamp | NULLABLE        | Last usage timestamp       |

### plaid_items

| Column           | Type      | Constraints     | Description                  |
|------------------|-----------|-----------------|------------------------------|
| id               | UUID      | PK              | Primary key                  |
| user_id          | UUID      | FK -> users     | Owner user                   |
| plaid_item_id    | String    | NOT NULL        | Plaid item identifier        |
| access_token     | String    | NOT NULL        | Plaid access token           |
| institution_id   | String    | NULLABLE        | Plaid institution ID         |
| institution_name | String    | NULLABLE        | Bank/institution name        |
| cursor           | String    | NULLABLE        | Transaction sync cursor      |
| created_at       | Timestamp | Auto-set        | Record creation time         |
| updated_at       | Timestamp | Auto-set        | Last update time             |

### accounts

| Column            | Type      | Constraints          | Description                |
|-------------------|-----------|----------------------|----------------------------|
| id                | UUID      | PK                   | Primary key                |
| plaid_item_id     | UUID      | FK -> plaid_items    | Parent Plaid item          |
| user_id           | UUID      | FK -> users          | Owner user                 |
| plaid_account_id  | String    | NOT NULL             | Plaid account identifier   |
| name              | String    | NOT NULL             | Account name               |
| official_name     | String    | NULLABLE             | Official account name      |
| type              | String    | NOT NULL             | Account type (e.g. depository) |
| subtype           | String    | NULLABLE             | Account subtype (e.g. checking) |
| mask              | String    | NULLABLE             | Last 4 digits              |
| current_balance   | Decimal   | NULLABLE             | Current balance            |
| available_balance | Decimal   | NULLABLE             | Available balance          |
| is_hidden         | Boolean   | NOT NULL             | Hidden from UI             |
| created_at        | Timestamp | Auto-set             | Record creation time       |
| updated_at        | Timestamp | Auto-set             | Last update time           |

### transactions

| Column               | Type      | Constraints        | Description                     |
|----------------------|-----------|--------------------|---------------------------------|
| id                   | UUID      | PK                 | Primary key                     |
| account_id           | UUID      | FK -> accounts     | Parent account                  |
| user_id              | UUID      | FK -> users        | Owner user                      |
| plaid_transaction_id | String    | NULLABLE           | Plaid transaction identifier    |
| amount               | Decimal   | NOT NULL           | Transaction amount (positive = expense, negative = income) |
| date                 | Timestamp | NOT NULL           | Transaction date                |
| merchant_name        | String    | NOT NULL           | Merchant or payee name          |
| category             | String    | NOT NULL           | Transaction category            |
| description          | String    | NULLABLE           | Additional description          |
| is_pending           | Boolean   | NOT NULL           | Whether transaction is pending  |
| is_excluded          | Boolean   | NOT NULL           | Excluded from summaries         |
| created_at           | Timestamp | Auto-set           | Record creation time            |
| updated_at           | Timestamp | Auto-set           | Last update time                |

### user_preferences

| Column                 | Type      | Constraints     | Description                          |
|------------------------|-----------|-----------------|--------------------------------------|
| id                     | UUID      | PK              | Primary key                          |
| user_id                | UUID      | FK -> users     | Owner user                           |
| notification_time      | String    | NOT NULL        | Daily notification time (default: "20:00") |
| selected_categories    | [String]  | NOT NULL        | Categories to track (default: [])    |
| notification_enabled   | Boolean   | NOT NULL        | Push notifications enabled (default: true) |
| weekly_summary_enabled | Boolean   | NOT NULL        | Weekly summary enabled (default: true) |
| daily_summary_enabled  | Boolean   | NOT NULL        | Daily summary enabled (default: true) |
| timezone               | String    | NOT NULL        | User timezone (default: "UTC")       |
| created_at             | Timestamp | Auto-set        | Record creation time                 |
| updated_at             | Timestamp | Auto-set        | Last update time                     |

### device_tokens

| Column     | Type      | Constraints     | Description                    |
|------------|-----------|-----------------|--------------------------------|
| id         | UUID      | PK              | Primary key                    |
| user_id    | UUID      | FK -> users     | Owner user                     |
| token      | String    | NOT NULL        | APNs or FCM device token       |
| platform   | String    | NOT NULL        | `"ios"` or `"android"`         |
| created_at | Timestamp | Auto-set        | Record creation time           |

---

## Testing

Run the test suite with:

```bash
swift test
```

Tests use Vapor's `XCTVapor` testing framework. Ensure a test database is available or configure the test environment accordingly.

```bash
# Run with verbose output
swift test --verbose

# Run a specific test
swift test --filter AppTests.SomeTestClass
```

---

## Deployment Notes

### Production Configuration

1. **Set `JWT_SECRET`** to a strong, random secret (256+ bits recommended).
2. **Configure Plaid** with production credentials (`PLAID_ENV=production`).
3. **Use `DATABASE_URL`** with SSL/TLS enabled for database connections.
4. **Restrict CORS**: Change `allowedOrigin` from `.all` to specific domains.
5. **Run migrations manually** in production (auto-migrate is development-only):
   ```bash
   swift run App migrate --env production
   ```
6. **Enable database encryption at rest** -- Plaid access tokens are stored in plaintext (encryption TODO noted in codebase).
7. **Implement full Plaid webhook verification** for production security.
8. **Configure reverse proxy** (e.g., Nginx) with TLS termination.
9. **Set up health check monitoring** against `GET /health`.

### Running in Production

```bash
swift run App serve --env production --hostname 0.0.0.0 --port 8080
```

### Docker (Optional)

A standard Vapor Dockerfile can be used:

```dockerfile
FROM swift:5.9-jammy as build
WORKDIR /app
COPY . .
RUN swift build -c release

FROM swift:5.9-jammy-slim
WORKDIR /app
COPY --from=build /app/.build/release/App .
ENTRYPOINT ["./App", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
```
