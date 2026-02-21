# 🗃️ WebSocket Contract

- Version: 1.0.0

This document defines the WebSocket message contract between
the frontend client and the Elixir backend.

## Front ➡️ Back

### open_chat

Fields:

- chat_id: uuid

<details>
<summary>Example</summary>

```json
{
	"type": "open_chat",
	"chat_id": "uuid",
}
```

</details>

---

### send_message

Fields:

- chat_id: uuid
- msg: Object
  - id: uuid,
  - front_msg_id: uuid,
  - chat_id: null,
  - content: string,
  - state: "sending",
  - sender_user_id: uuid,
  - type: "outgoing",
  - time: ISOTimeString,
  - avatar_url: url,
  - format: "text | image | video | audio | file"

<details>
<summary>Example</summary>

```json
{
	"type": "send_message",
	"chat_id": "uuid",
	"msg": {
		"id": "uuid",
		"front_msg_id": "uuid",
		"chat_id": null,
		"content": "text",
		"state": "sending",
		"sender_user_id": "uuid",
		"type": "outgoing",
		"time": "2026-02-07T22:55:00Z",
		"avatar_url": "url",
		"format": "text | image | video | audio | file"
	}
}
```

</details>

---

### chat_messages_read

Fields:

- chat_id: uuid

<details>
<summary>Example</summary>

```json
{
	"type": "chat_messages_read",
	"chat_id": "uuid"
}
```

</details>

---

### get_contacts

Fields:

- none

<details>
<summary>Example</summary>

```json
{
	"type": "get_contacts"
}
```

</details>

---

### get_person_info

Fields:

- person_id: uuid

<details>
<summary>Example</summary>

```json
{
	"type": "get_person_info",
	"person_id": "uuid"
}
```

</details>

---

### search_people

Fields:

- input: string

<details>
<summary>Example</summary>

```json
{
	"type": "search_people",
	"input": "text"
}
```

</details>

---

### create_private_chat

Fields:

- user_id: uuid
<details>
<summary>Example</summary>

```json
{
	"type": "create_private_chat",
	"user_id": "uuid"
}
```

</details>

---

### change_username

Fields:

- new_username: string

<details>
<summary>Example</summary>

```json
{
	"type": "change_username",
	"new_username": "text"
}
```

</details>

---

### change_name

Fields:

- new_username: string

<details>
<summary>Example</summary>

```json
{
	"type": "change_name",
	"new_name": "text"
}
```

</details>

---

### change_nickname

Fields:

- user_id: uuid
- new_nickname: string

<details>
<summary>Example</summary>

```json
{
	"type": "change_nickname",
	"user_id": "uuid",
	"new_nickname": "text"
}
```

</details>

---

### create_group

Fields:

- name: string
- description: string
- avatar_url: url,
- member_ids: uuid[ ]

<details>
<summary>Example</summary>

```json
{
  "type": "create_group",
  "name": "text",
  "description": "text",
  "avatar_url": "url",
  "member_ids": [
    "uuid-1",
    "uuid-2",
    "uuid-3",
    ...
  ]
}
```

</details>

---
### logout

Fields: none

<details>
<summary>Example</summary>

```json
{
	"type": "logout"
}
```
</details>


---
### change_group_name

Fields: 
- chat_id: uuid,
- new_name: string

<details>
<summary>Example</summary>

```json
{
	"type": "change_group_name",
  "chat_id": "uuid",
  "new_name": "string"
}
```
</details>

---
### change_group_description

Fields: 
- chat_id: uuid,
- new_description: string

<details>
<summary>Example</summary>

```json
{
	"type": "change_group_description",
  "chat_id": "uuid",
  "new_description": "string"
}
```
</details>

---
### give_admin

Fields: 
- chat_id: uuid
- user_id: uuid

<details>
<summary>Example</summary>

```json
{
	"type": "give_admin",
  "chat_id": "uuid",
  "user_id": "uuid"
}
```
</details>




---

---

## Back ➡️ Front

### user_info

Fields:

- user: Object
  - id: uuid,
  - username: string,
  - name: string,
  - email: string,
  - avatar_url: url,
  - last_seen_at: ISOTimeString
- last_chats: Object[ ]
  - id: uuid,
  - type: "private | group",
  - name: string,
  - avatar_url: url,
  - unread_messages: integer,
  - last_message: Object
    - type: "outgoing | incoming",
    - content: string,
    - state: "sending | sent | delivered | read",
    - time: ISOTimeString,
    - sender_name: string,
    - format: "text | image | video | audio | file",
    - filename: string

<details>
<summary>Example</summary>

```json
{
  "type": "user_info",
  "user": {
    "id": "uuid",
    "username": "text",
    "name": "text",
    "email": "text",
    "avatar_url": "url",
    "last_seen_at": "ISOTimeString"
  },
  "last_chats": [
    {
      "id": "uuid",
      "type": "private | group",
      "name": "text",
      "avatar_url": "url",
      "unread_messages": 0,
      "last_message": {
        "type": "outgoing | incoming",
        "content": "text",
        "state": "sending | sent | delivered | read",
        "time": "ISOTimeString",
        "sender_name": "text",
        "format": "text | image | video | audio | file",
        "filename": "text"
      }
    },
    ...
  ]
}
```

</details>

---

### chat_info

Fields:

- chat: Object
  - id: uuid
  - messages: Object[ ]
    - id: uuid
    - content: string
    - user_id: uuid
    - chat_id: uuid
    - state: "sending | sent | delivered | read"
    - time: ISOTimeString
    - deleted_at: ISOTimeString
    - avatar_url: url
    - format: "text | image | video | audio | file"
    - filename: string
    - type: "outgoing | incoming"
    - sender_name: string
  - name: string
  - description: string (only if group chat)
  - status: "Online | Offline"
  - type: "private | group"
  - avatar_url: url
  - members: Object[ ]
    - user_id: uuid
    - username: string
    - name: string
    - avatar_url: url
    - last_read_at: ISOTimeString
    - last_seen_at: ISOTimeString
    - nickname: string
    - role: "member | admin"
  - unread_messages: Integer

<details>
<summary>Example</summary>

```json
{
  "type": "chat_info",
  "chat": {
    "id": "uuid",
    "messages": [
      {
        "id": "uuid",
        "content": "text",
        "user_id": "uuid",
        "chat_id": "uuid",
        "state": "sending | sent | delivered | read",
        "time": "ISOTimeString",
        "deleted_at": "ISOTimeString" | null,
        "avatar_url": "url",
        "format": "text | image | video | audio | file",
        "filename": "string" | null,
        "type": "outgoing | incoming",
        "sender_name": "string"
      },
      ...
    ],
    "name": "text",
    "description": "text" (only if group chat)
    "status": "Online | Offline",
    "type": "private | group",
    "avatar_url": "url",
    "members": [
      {
        "user_id": "uuid",
        "username": "text",
        "name": "text",
        "avatar_url": "url",
        "last_read_at": "ISOTimeString",
        "nickname": "text" | null,
        "role": "member | admin"
      },
      ...
    ],
    "unread_messages": "integer"
  }
}
```

</details>

---

### new_message

Fields:

- message: Object
  - id: uuid
  - content: string
  - user_id: uuid
  - chat_id: uuid
  - state: "sent | delivered | read"
  - format: "text | image | video | audio | file"
  - filename: string
  - deleted_at: ISOTimeString
  - updated_at: ISOTimeString
  - time: ISOTimeString
  - avatar_url: url
  - front_msg_id: uuid
  - type: "incoming | outgoing"
  - sender_name: string

<details>
<summary>Example</summary>

```json
{
	"type": "new_message",
	"message": {
		"id": "uuid",
		"content": "text",
		"user_id": "uuid",
		"chat_id": "uuid",
		"state": "sent | delivered | read",
		"format": "text | image | video | audio | file",
		"filename": "string",
		"deleted_at": "ISOTimeString",
		"updated_at": "ISOTimeString",
		"time": "ISOTimeString",
		"avatar_url": "url",
		"front_msg_id": "uuid",
		"type": "incoming | outgoing",
		"sender_name": "text"
	}
}
```

</details>

---

### chat_read

Fields:

- chat_id: uuid,
- reader_user_id: uuid

<details>
<summary>Example</summary>

```json
{
	"type": "chat_read",
	"chat_id": "uuid",
	"reader_user_id": "uuid"
}
```

</details>

---

### messages_delivered

Fields:

- message_ids: uuid [ ]

<details>
<summary>Example</summary>

```json
{
  "type": "messages_delivered",
  "message_ids": [
    "uuid-1",
    "uuid-2",
    "uuid-3",
    ...
  ]
}

```

</details>

---

### contacts

Fields:

- contacts: Object [ ]
  - id: uuid
  - username: string
  - name: string
  - avatar_url: url
  - last_seen_at: ISOTimeString
  - contact_info: Object
  - owner_user_id: uuid
  - nickname: string
  - added_at: ISOTimeString

<details>
<summary>Example</summary>

```json
{
  "type": "contacts",
  "contacts": [
    {
      "id": "uuid",
      "username": "text",
      "name": "text",
      "avatar_url": "url",
      "last_seen_at": "ISOTimeString",
      "contact_info": {
        "owner_user_id": "uuid",
        "nickname": "text",
        "added_at": "ISOTimeString"
      }
    },
    ...
  ]
}

```

</details>

---

### person_info

Fields:

- person_info: Object
  - id: uuid
  - username: string
  - name: string
  - avatar_url: url
  - status: "Online | Offline"
  - last_seen_at: ISOTimeString
  - private_chat_id: uuid
  - contact_info: Object | null
    - owner_user_id: uuid
    - nickname: string
    - added_at: ISOTimeString

<details>
<summary>Example</summary>

```json
{
  "type": "person_info",
  "person_info": [
    {
      "id": "uuid",
      "username": "text",
      "name": "text",
      "avatar_url": "url",
      "status": "Online | Offline",
      "last_seen_at": "ISOTimeString",
      "private_chat_id": "uuid",
      "contact_info": {
        "owner_user_id": "uuid",
        "nickname": "text",
        "added_at": "ISOTimeString"
      } | null
    },
    ...
  ]
}

```

</details>

---
### search_people_results

Fields:

<details>
<summary>Example</summary>

```json
{
  "type": "search_people_results",
  "search_people_results": {
    "id": "uuid",
    "username": "text",
    "name": "text",
    "avatar_url": "url",
    "last_seen_at": "ISOTimeString",
    "contact_info": {
      "owner_user_id": "uuid",
      "nickname": "text"
    } | null
  }
}
```
</details>

---

### private_chat_created

Fields:

- chat: Object (only sent to chat creator)
  - id: uuid
  - messages: Object [ ]
    - id: uuid
    - content: string
    - user_id: uuid
    - chat_id: uuid
    - state: sending | sent | delivered | read
    - time: ISOTimeString
    - deleted_at: ISOTimeString | null
    - avatar_url: url
    - format: text | image | video | audio | file
    - filename: string | null
  - name: string
  - status: Online | Offline
  - type: private | group
  - avatar_url: url
  - members: Object [ ]
    - user_id: uuid
    - username: string
    - name: string
    - avatar_url: url
    - last_read_at: ISOTimeString
    - nickname: string | null
    - role: "member | admin"

- chat_item: Object
  - id: uuid
  - type: private | group
  - name: string
  - avatar_url: url
  - status: Online | Offline | null
  - unread_messages: integer
  - last_message: null

<details>
<summary>Example</summary>

```json
{
  "type": "private_chat_created",
  "chat": {
    "id": "uuid",
    "messages": [
      {
        "id": "uuid",
        "content": "text",
        "user_id": "uuid",
        "chat_id": "uuid",
        "state": "sending | sent | delivered | read",
        "time": "ISOTimeString",
        "deleted_at": "ISOTimeString" | null,
        "avatar_url": "url",
        "format": "text | image | video | audio | file",
        "filename": "string" | null
      },
      ...
    ],
    "name": "text",
    "status": "Online | Offline",
    "type": "private",
    "avatar_url": "url",
    "members": [
      {
        "user_id": "uuid",
        "username": "text",
        "name": "text",
        "avatar_url": "url",
        "last_read_at": "ISOTimeString",
        "nickname": "text" | null,
        "role": "member | admin"
      },
      ...
    ]
  } | null,
  "chat_item": {
    "id": "uuid",
    "type": "private",
    "name": "text",
    "avatar_url": "url",
    "status": "Online | Offline" | null,
    "unread_messages": 0,
    "last_message": null
  }

}

```

</details>

---

### username_change_result

Fields:
- type: "username_change_result"
- status: "success | failure"
- data: Object (contiene new_username || reason)
  - new_username: text
  - reason:
    - not_found
    - username:
      - can't be blank
      - should be at least 3 character(s)
      - should be at most 30 character(s)
      - can only contain letters, numbers, and underscores
      - has already been taken


<details>
<summary>Example</summary>

```json
{
  "type": "username_change_result",
  "status": "success | failure",
  "data": {
    "new_username": "text"
  } || {
    "reason": "not_found" ||
    {
      "username": "can't be blank" ||
                  "should be at least 3 character(s)" ||
                  "should be at most 30 character(s)" ||
                  "can only contain letters, numbers, and underscores" ||
                  "has already been taken"
    }
  }
}

```

</details>

---

### name_change_result

Fields:
- type: "name_change_result"
- status: "success | failure"
- data: Object (contiene new_name || reason)
  - new_name: Object
    - new_name: text
  - reason:
    - not_found
    - name:
      - can't be blank
      - should be at least 1 character(s)
      - should be at most 50 character(s)


<details>
<summary>Example</summary>

```json
{
  "type": "name_change_result",
  "status": "success | failure",
  "data": {
    "new_name": "text"
  } || {
    "reason": "not_found" ||
    {
      "name": "can't be blank" ||
              "should be at least 1 character(s)" ||
              "should be at most 50 character(s)"
    }
  }
}

```

</details>

---

### nickname_change_result

Fields:
- type: "nickname_change_result"
- status: "success | failure"
- data: Object (contiene new_name || reason)
  - new_name: Object
    - contact_id: uuid
    - new_name: text
  - reason:
    - not_found
    - name:
      - can't be blank
      - should be at least 1 character(s)
      - should be at most 50 character(s)


<details>
<summary>Example</summary>

```json
{
  "type": "nickname_change_result",
  "status": "success | failure",
  "data": {
    "contact_id": "uuid",
    "new_name": "text"
  } || {
    "reason": "not_found" ||
    {
      "name": "can't be blank" ||
              "should be at least 1 character(s)" ||
              "should be at most 50 character(s)"
    }
  }


}
```

</details>

---

### group_chat_created

Fields:

- chat: Object (only sent to chat creator)
  - id: uuid
  - messages: Object [ ]
    - id: uuid
    - content: string
    - user_id: uuid
    - chat_id: uuid
    - state: sending | sent | delivered | read
    - time: ISOTimeString
    - deleted_at: ISOTimeString | null
    - avatar_url: url
    - format: text | image | video | audio | file
    - filename: string | null
  - name: string
  - status: Online | Offline
  - type: private | group
  - avatar_url: url
  - members: Object [ ]
    - user_id: uuid
    - username: string
    - name: string
    - avatar_url: url
    - last_read_at: ISOTimeString
    - nickname: string | null
    - role: "member | admin"

- chat_item: Object
  - id: uuid
  - type: private | group
  - name: string
  - avatar_url: url
  - status: Online | Offline | null
  - unread_messages: integer
  - last_message: null

<details>
<summary>Example</summary>

```json
{
  "type": "group_chat_created",
  "chat": {
    "id": "uuid",
    "messages": [
      {
        "id": "uuid",
        "content": "text",
        "user_id": "uuid",
        "chat_id": "uuid",
        "state": "sending | sent | delivered | read",
        "time": "ISOTimeString",
        "deleted_at": "ISOTimeString" | null,
        "avatar_url": "url",
        "format": "text | image | video | audio | file",
        "filename": "string" | null
      },
      ...
    ],
    "name": "text",
    "description": "text"
    "status": "Online | Offline",
    "type": "private | group",
    "avatar_url": "url",
    "members": [
      {
        "user_id": "uuid",
        "username": "text",
        "name": "text",
        "avatar_url": "url",
        "last_read_at": "ISOTimeString",
        "nickname": "text" | null,
        "role": "member | admin"
      },
      ...
    ]
  } | null,
  "chat_item": {
    "id": "uuid",
    "type": "private | group",
    "name": "text",
    "avatar_url": "url",
    "status": null,
    "unread_messages": 0,
    "last_message": null
  }

}

```

</details>


---

### contact_addition

Fields:
- type: "contact_addition"
- status: "success | failure"
- data: Object (contiene contact_info || reason)
  - contact_info: Object
    - owner_user_id: uuid
    - nickname: null
    - added_at: ISOTimeString
  - reason:
    - user_id:
      - can't be blank
      - has already been taken
      - does not exist
    - contact_id:
      - can't be blank
      - does not exist


<details>
<summary>Example</summary>

```json
{
  "type": "contact_addition",
  "status": "success | failure",
  "data": {
    "contact": {
      "id": "uuid",
      "username": "text",
      "name": "text",
      "avatar_url": "url",
      "last_seen_at": "ISOTimeString",
      "contact_info": {
        "owner_user_id": "uuid",
        "nickname": "text",
        "added_at": "ISOTimeString"
      }
    }
  } || {
    "reason": {
      "user_id": "can't be blank" || 
                 "has already been taken" ||
                 "does not exist",
      "contact_id": "can't be blank" ||
                    "does not exist"
    }
  }


}
```

</details>


---
### contact_deletion

Fields:
- type: "contact_deletion"
- status: "success | failure"
- data: Object (contiene contact_info || reason)
  - contact_info: Object
    - owner_user_id: uuid
    - nickname: null
    - added_at: ISOTimeString
  - reason: "not_found" ||
    - user_id:
      - can't be blank
      - has already been taken
      - does not exist
    - contact_id:
      - can't be blank
      - does not exist

<details>
<summary>Example</summary>

```json
{
  "type": "contact_deletion",
  "status": "success | failure",
  "data": {
    "user_id": "uuid"
  } || {
    "reason": "not_found" ||
    {
      "user_id": "can't be blank" || 
                 "has already been taken" ||
                 "does not exist",
      "contact_id": "can't be blank" ||
                    "does not exist"
    }
  }


}
```
</details>


---
### group_name_change_result

Fields:
- type: "group_name_change_result"
- status: "success | failure"
- chat_id: uuid
- new_name: string (solo si status es success)
- changer_user_id: uuid (solo si status es success)
- reason: (solo si status es failure)
  - "not_found"
  - "unauthorized"
  - name:
    - can't be blank
    - should be at least 1 character(s)
    - should be at most 50 character(s)

<details>
<summary>Example</summary>

caso `status == "success`
```json
{
  "type": "group_name_change_result",
  "status": "success",
  "chat_id": "uuid",
  "new_name": "text",
  "changer_user_id": "uuid"
}
```
caso `status == "failure`
```json
{
  "type": "group_name_change_result",
  "status": "failure",
  "chat_id": "uuid",
  "reason": "not_found" | "unauthorized" |
  {
    "name": 
      "can't be blank" ||
      "should be at least 1 character(s)" ||
      "should be at most 50 character(s)"
  }
}

```
</details>


---
### group_description_change_result

Fields:
- type: "group_description_change_result"
- status: "success | failure"
- chat_id: uuid
- new_description: string (solo si status es success)
- changer_user_id: uuid (solo si status es success)
- reason: (solo si status es failure)
  - "not_found"
  - "unauthorized"
  - description:
    - can't be blank
    - should be at least 1 character(s)
    - should be at most 50 character(s)

<details>
<summary>Example</summary>

caso `status == "success`
```json
{
  "type": "group_description_change_result",
  "status": "success",
  "chat_id": "uuid",
  "new_description": "text",
  "changer_user_id": "uuid"
}
```
caso `status == "failure`
```json
{
  "type": "group_description_change_result",
  "status": "failure",
  "chat_id": "uuid",
  "reason": "not_found" | "unauthorized" | 
  {
    "description": 
      "can't be blank" ||
      "should be at least 1 character(s)" ||
      "should be at most 50 character(s)"
  }
}

```
</details>


---
### admin_given_to_member

Fields:
- type: admin_given_to_member,
- chat_id: uuid,
- member: Object:
  - user_id: uuid
  - username: string
  - name: string
  - avatar_url: url
  - last_read_at: ISOTimeString
  - nickname: string | null
  - role: "member | admin"
- giving_user_id: uuid

<details>
<summary>Example</summary>

```json
{
  "type": "admin_given_to_member",
  "chat_id": "uuid",
  "member": {
    "user_id": "uuid",
    "username": "text",
    "name": "text",
    "avatar_url": "url",
    "last_read_at": "ISOTimeString",
    "nickname": "text" | null,
    "role": "member | admin"
  },
  "giving_user_id": "uuid"
}
```
</details>