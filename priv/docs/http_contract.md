# 🌐 HTTP Contract

- Version: 1.0.0

- This document defines the HTTP API contract between the frontend client and the Elixir backend.

- Base URL (development): http://localhost:4000/api

- All responses are JSON unless otherwise specified.

- Some endpoints require authentication via:
`Authorization: Bearer <JWT_TOKEN>`


# 🗃️ Public Endpoints

## 🩺 Health Check

### `GET /api/health`

Returns API status.

### ✅ Response — 200 OK

```json
{
  "status": "ok"
}
```

## 📚 WebSocket Documentation

### `GET /api/docs/ws`

Show the WebSocket contract.

### ✅ Response 200 OK

```
renders WebSocket documentation
```

## 🔐 Login

### `POST /api/login`

Authenticates a user.

### Body (JSON)

```json
{
  "username": "string",
  "password": "string"
}
```

### ✅ Response — 200 OK

```json
{
  "token": "jwt_token"
}
```

### ❌ Errors — 401 Unauthorized

```json
{
  "error": "User not found" / "Invalid password" / "Invalid credentials"
}
```

## 📝 Register

### `POST /api/register`

Registers a new user.

### Body (multipart/form-data)

Fields:

- username: string
- password: string
- name: string
- email: string
- avatar (optional): image file

### ✅ Response — 201 Created
```json
{
  "token": "jwt_token"
}
```

### ❌ Errors:
### 400 Bad Request

```json
{
  "error": "Invalid multipart data" |
           "Invalid avatar type" |
           "Invalid avatar" |
           "Avatar too large" |
           "Avatar upload failed" |
           "Bad request"
} ||
{
  "errors": {
    "username": "can't be blank" |
                "has already been taken" |
                "can only contain letters, numbers, and underscores" |
                "should be at least 3 character(s)" |
                "should be at most 30 character(s)",
    "email": "can't be blank" |
              "has already been taken" |
              "has invalid format",
    "password": "can't be blank" |
                "should be at least 8 character(s)",
    "name": "can't be blank" |
            "should bee at most 30 character(s)"
  }
}
```

### 🔐 Authenticated Endpoints

All endpoints below require:
`Authorization: Bearer <JWT_TOKEN>`

## 👤 Upload User Avatar

### `POST /api/users/me/avatar` 

Upload user avatar

### Body (multipart/form-data)

Fields:

- avatar: image file

### ✅ Response — 200 OK

```json
{
  "avatar_url": "https://..."
}
```

### ❌ Errors — 400 Bad Request

```json
{
  "error": "Avatar upload failed"
}
```

## 👥 Upload Group Avatar

### `POST /api/groups/{group_id}/avatar`

### Path Parameters
- group_id: UUID

Upload group avatar

### Body (multipart/form-data)

Fields:

- avatar: image file

### ✅ Response — 200 OK

```json
{
  "avatar_url": "https://..."
}
```

### ❌ Errors — 400 Bad Request

```json
{
  "error": "Avatar upload failed"
}
```

## 📎 Upload Chat File

### `POST /api/chat/upload`

Uploads a file for chat usage.

### Body (multipart/form-data)

Fields:

- file: any file

### ✅ Response — 200 OK

```json
{
  "url": "https://file-url",
  "mime": "mime/type"
}
```

### ❌ Errors — 400 Bad Request

```json
{
  "error": "Upload failed"
}
```

## 🔍 Search Messages in Chat

### `GET /api/chats/{chat_id}/search?q=query`

Search a message in a chat

### Path Parameters
- chat_id: UUID

### Query Parameters
- q: string (required)

### ✅ Response — 200 OK

```json
[
  {
    "id": "uuid",
    "content": "text",
    "user_id": "uuid",
    "time": "ISOTimeString"
  }
]
```

### ❌ Errors

### 400 Bad Request

```json
{
  "error": "Missing search query"
}
```

### 404 Not Found

```json
{
  "error": "Not found"
}
```

## ➕ Add Members to Chat

### `POST /api/chats/{chat_id}/members`

Add a member to a chat

### Path Parameters
- chat_id: UUID

### Body (JSON)

```json
{
  "member_ids": ["uuid1", "uuid2"]
}
```

### ✅ Response — 204 No Content

### ❌ Errors

### 400 Bad Request

```json
{
    "error": "{reason}"
}
```

### 403 Forbidden

```json
{
  "error": "Not allowed"
}
```

### 404 Not Found

```json
{
  "error": "Chat not found"
}
```

## ➖ Remove Member from Chat

### `DELETE /api/chats/{chat_id}/members/{member_user_id}`

Remove a member from a chat

### Path Parameters
- chat_id: UUID
- member_user_id: UUID

### ✅ Response — 204 No Content

### ❌ Errors

### 400 Bad Request

```json
{
    "error": "{reason}"
}
```

### 403 Forbidden

```json
{
  "error": "Not allowed"
}
```

### 404 Not Found

```json
{
  "error": "Member not found"
}
```


