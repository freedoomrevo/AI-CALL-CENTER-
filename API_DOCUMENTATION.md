# 📚 Aetherium API Documentation

Complete API reference for the Aetherium platform.

## 🔗 Base URLs

| Environment | Base URL |
|-------------|----------|
| Development | `http://localhost:8000` |
| Staging | `https://staging-api.aetherium.ai` |
| Production | `https://api.aetherium.ai` |

## 🔐 Authentication

Aetherium uses JWT (JSON Web Tokens) for authentication.

### Getting a Token

```http
POST /api/auth/login
Content-Type: application/json

{
  "login_identifier": "user@example.com",
  "password": "your_password"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user_id": 1,
  "email": "user@example.com",
  "company_number": "+1234567890",
  "is_first_login": false
}
```

### Using the Token

Include the token in the Authorization header:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 📋 API Endpoints

### 🔑 Authentication Endpoints

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secure_password",
  "confirm_password": "secure_password",
  "phone_number": "+1234567890"
}
```

**Response:**
```json
{
  "message": "Registration successful. Please verify your phone number with the SMS code.",
  "user_id": 1,
  "verification_required": true
}
```

#### Verify Phone Number
```http
POST /api/auth/verify-sms
Content-Type: application/json

{
  "email": "user@example.com",
  "verification_code": "123456"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "login_identifier": "user@example.com",
  "password": "your_password"
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Authorization: Bearer <token>
```

### 👤 User Management

#### Get User Profile
```http
GET /api/users/{user_id}
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "phone_number": "+1234567890",
  "full_name": "John Doe",
  "is_active": true,
  "is_verified": true,
  "created_at": "2024-01-01T00:00:00Z",
  "subscription": {
    "tier": "premium",
    "status": "active",
    "expires_at": "2024-12-31T23:59:59Z"
  }
}
```

#### Update User Profile
```http
PUT /api/users/{user_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "full_name": "John Smith",
  "phone_number": "+1987654321"
}
```

#### Change Password
```http
POST /api/users/{user_id}/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "current_password": "old_password",
  "new_password": "new_password",
  "confirm_password": "new_password"
}
```

### 🔄 Workflow Management

#### List Workflows
```http
GET /api/workflows/
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Customer Support",
    "description": "Handle customer inquiries",
    "prompt_template": "You are a helpful customer support agent...",
    "voice_settings": {
      "voice": "en-US-AriaNeural",
      "rate": "+0%",
      "pitch": "+0Hz"
    },
    "is_active": true,
    "created_at": "2024-01-01T00:00:00Z"
  }
]
```

#### Create Workflow
```http
POST /api/workflows/
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Sales Assistant",
  "description": "Handle sales inquiries and lead qualification",
  "prompt_template": "You are a knowledgeable sales representative...",
  "voice_settings": {
    "voice": "en-US-DavisNeural",
    "rate": "+5%",
    "pitch": "+2Hz"
  }
}
```

#### Update Workflow
```http
PUT /api/workflows/{workflow_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Workflow Name",
  "description": "Updated description",
  "is_active": false
}
```

#### Delete Workflow
```http
DELETE /api/workflows/{workflow_id}
Authorization: Bearer <token>
```

### 📞 Communication Sessions

#### List Sessions
```http
GET /api/sessions/
Authorization: Bearer <token>
```

**Query Parameters:**
- `status`: Filter by status (pending, active, completed, failed)
- `limit`: Number of results (default: 50)
- `offset`: Pagination offset (default: 0)
- `start_date`: Filter sessions from date (ISO format)
- `end_date`: Filter sessions to date (ISO format)

**Response:**
```json
{
  "sessions": [
    {
      "id": 1,
      "workflow_id": 1,
      "phone_number": "+1555123456",
      "session_type": "outbound",
      "status": "completed",
      "started_at": "2024-01-01T10:00:00Z",
      "ended_at": "2024-01-01T10:05:30Z",
      "duration_seconds": 330,
      "transcript": "Customer: Hello...",
      "ai_response": "I helped the customer with...",
      "metadata": {
        "call_quality": "excellent",
        "customer_satisfaction": 5
      }
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

#### Create Session
```http
POST /api/sessions/
Authorization: Bearer <token>
Content-Type: application/json

{
  "workflow_id": 1,
  "phone_number": "+1555123456",
  "session_type": "outbound",
  "metadata": {
    "priority": "high",
    "campaign": "summer_sale"
  }
}
```

#### Get Session Details
```http
GET /api/sessions/{session_id}
Authorization: Bearer <token>
```

#### Update Session
```http
PUT /api/sessions/{session_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "completed",
  "transcript": "Full conversation transcript...",
  "ai_response": "Summary of AI actions..."
}
```

### 📊 Statistics & Analytics

#### Get User Statistics
```http
GET /api/statistics/user/{user_id}
Authorization: Bearer <token>
```

**Query Parameters:**
- `period`: Time period (day, week, month, year)
- `start_date`: Start date for custom period
- `end_date`: End date for custom period

**Response:**
```json
{
  "period": "month",
  "total_sessions": 150,
  "successful_sessions": 142,
  "failed_sessions": 8,
  "total_duration_minutes": 2850,
  "average_duration_minutes": 19.0,
  "success_rate": 94.7,
  "daily_breakdown": [
    {
      "date": "2024-01-01",
      "sessions": 5,
      "duration_minutes": 95
    }
  ]
}
```

#### Get System Statistics
```http
GET /api/statistics/system
Authorization: Bearer <token>
```

**Response:**
```json
{
  "total_users": 1250,
  "active_users_today": 89,
  "total_sessions_today": 456,
  "system_uptime": "15 days, 4 hours",
  "average_response_time": 0.245,
  "modem_status": {
    "total": 10,
    "active": 8,
    "inactive": 2
  }
}
```

### 💳 Subscription Management

#### Get Subscription Tiers
```http
GET /api/subscriptions/tiers
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "free",
    "display_name": "Free Tier",
    "description": "Basic access to Aetherium platform",
    "price_monthly": 0.0,
    "price_yearly": 0.0,
    "max_sessions_per_month": 10,
    "max_session_duration_minutes": 5,
    "features": ["basic_ai", "limited_sessions"]
  }
]
```

#### Get User Subscription
```http
GET /api/subscriptions/user/{user_id}
Authorization: Bearer <token>
```

#### Update Subscription
```http
POST /api/subscriptions/upgrade
Authorization: Bearer <token>
Content-Type: application/json

{
  "tier_id": 2,
  "payment_period": "monthly"
}
```

### 💰 Payment Management

#### Create Payment Session
```http
POST /api/payments/create-session
Authorization: Bearer <token>
Content-Type: application/json

{
  "subscription_tier_id": 2,
  "payment_period": "monthly"
}
```

**Response:**
```json
{
  "session_id": "pay_session_123",
  "amount": 29.99,
  "currency": "USD",
  "bank_details": {
    "card_number": "8600123456789012",
    "bank_name": "Xalq Banki",
    "cardholder_name": "Aetherium LLC"
  },
  "expires_at": "2024-01-01T12:00:00Z"
}
```

#### Verify Payment
```http
POST /api/payments/verify
Authorization: Bearer <token>
Content-Type: application/json

{
  "session_id": "pay_session_123",
  "bank_card_number": "1234567890123456",
  "cardholder_name": "John Doe"
}
```

### 📱 Telegram Integration

#### Link Telegram Account
```http
POST /api/telegram/link
Authorization: Bearer <token>
Content-Type: application/json

{
  "telegram_user_id": 123456789,
  "telegram_username": "johndoe"
}
```

#### Get Telegram Settings
```http
GET /api/telegram/settings
Authorization: Bearer <token>
```

#### Update Telegram Settings
```http
PUT /api/telegram/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "notifications_enabled": true,
  "session_updates": true,
  "daily_reports": false
}
```

### 🎧 Support System

#### Create Support Ticket
```http
POST /api/support/tickets
Authorization: Bearer <token>
Content-Type: application/json

{
  "subject": "Unable to make outbound calls",
  "description": "I'm experiencing issues when trying to make calls...",
  "category": "technical",
  "priority": "high"
}
```

#### List Support Tickets
```http
GET /api/support/tickets
Authorization: Bearer <token>
```

#### Get Ticket Details
```http
GET /api/support/tickets/{ticket_id}
Authorization: Bearer <token>
```

### 🔧 Admin Endpoints

#### Get System Health
```http
GET /api/admin/health
Authorization: Bearer <admin_token>
```

#### Manage GSM Modems
```http
GET /api/admin/modems
Authorization: Bearer <admin_token>
```

```http
POST /api/admin/modems/{modem_id}/assign
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "user_id": 1
}
```

#### Manage API Keys
```http
GET /api/admin/api-keys
Authorization: Bearer <admin_token>
```

```http
POST /api/admin/api-keys
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "key": "new_gemini_api_key",
  "provider": "gemini",
  "daily_limit": 1000
}
```

## 📡 WebSocket Endpoints

### Real-time Session Updates

```javascript
const ws = new WebSocket('ws://localhost:8000/ws/session/{session_id}');

ws.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Session update:', data);
};

// Send message to session
ws.send(JSON.stringify({
  type: 'user_message',
  content: 'Hello, how can I help you?'
}));
```

**Message Types:**
- `session_started`: Session has begun
- `session_ended`: Session completed
- `transcript_update`: New transcript data
- `status_change`: Session status changed
- `error`: Error occurred

## 🚨 Error Handling

### Error Response Format

```json
{
  "detail": "Error description",
  "error_code": "VALIDATION_ERROR",
  "timestamp": "2024-01-01T00:00:00Z",
  "request_id": "req_123456"
}
```

### Common Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `VALIDATION_ERROR` | Request validation failed | 400 |
| `AUTHENTICATION_REQUIRED` | Missing or invalid token | 401 |
| `PERMISSION_DENIED` | Insufficient permissions | 403 |
| `RESOURCE_NOT_FOUND` | Requested resource not found | 404 |
| `RATE_LIMIT_EXCEEDED` | Too many requests | 429 |
| `INTERNAL_ERROR` | Server error | 500 |

## 📊 Rate Limiting

- **Default**: 120 requests per minute per user
- **Burst**: Up to 10 requests in quick succession
- **Headers**: Rate limit info in response headers

```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 115
X-RateLimit-Reset: 1640995200
```

## 🔍 Filtering & Pagination

### Query Parameters

- `limit`: Number of results (max: 100)
- `offset`: Pagination offset
- `sort`: Sort field (e.g., `created_at`, `-created_at` for desc)
- `filter`: JSON filter object

### Example

```http
GET /api/sessions/?limit=20&offset=40&sort=-created_at&filter={"status":"completed"}
```

## 📝 Request/Response Examples

### Complete Session Creation Flow

1. **Create Session**
```http
POST /api/sessions/
Authorization: Bearer <token>
Content-Type: application/json

{
  "workflow_id": 1,
  "phone_number": "+1555123456",
  "session_type": "outbound"
}
```

2. **Monitor via WebSocket**
```javascript
const ws = new WebSocket('ws://localhost:8000/ws/session/123');
ws.onmessage = (event) => {
  const update = JSON.parse(event.data);
  if (update.type === 'session_ended') {
    console.log('Session completed:', update.data);
  }
};
```

3. **Get Final Results**
```http
GET /api/sessions/123
Authorization: Bearer <token>
```

## 🛠️ SDK & Libraries

### Python SDK Example

```python
from aetherium_sdk import AetheriumClient

client = AetheriumClient(
    base_url="http://localhost:8000",
    api_key="your_api_key"
)

# Create a session
session = client.sessions.create(
    workflow_id=1,
    phone_number="+1555123456",
    session_type="outbound"
)

# Monitor session
for update in client.sessions.stream(session.id):
    print(f"Status: {update.status}")
    if update.status == "completed":
        break
```

### JavaScript SDK Example

```javascript
import { AetheriumClient } from '@aetherium/sdk';

const client = new AetheriumClient({
  baseUrl: 'http://localhost:8000',
  apiKey: 'your_api_key'
});

// Create and monitor session
const session = await client.sessions.create({
  workflowId: 1,
  phoneNumber: '+1555123456',
  sessionType: 'outbound'
});

const stream = client.sessions.stream(session.id);
stream.on('update', (update) => {
  console.log('Session update:', update);
});
```

## 📞 Support

For API support:
- 📧 Email: api-support@aetherium.ai
- 📚 Documentation: [docs.aetherium.ai](https://docs.aetherium.ai)
- 💬 Discord: [discord.gg/aetherium](https://discord.gg/aetherium)
- 🐛 Issues: [GitHub Issues](https://github.com/Asilbekov/Ozodbek-/issues)