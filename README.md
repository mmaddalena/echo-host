# Echo

**Chat Application**


TP FINAL - Taller de Programación - Universidad de Buenos Aires<br>

__Alumnos:__ 
- Lucas Facundo Couttulenc (109726)
- Martín Maddalena (107610)

__Profesores:__ 
- Manuel Camejo
- Matías Onorato

## Diseño general de la app
**Core Stack**

![Elixir](https://img.shields.io/badge/Elixir-4B275F?logo=elixir&logoColor=white)
![Erlang](https://img.shields.io/badge/Erlang-A90533?logo=erlang&logoColor=white)
![Vue](https://img.shields.io/badge/Vue.js-35495E?logo=vue.js&logoColor=4FC08D)
![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)
![Postgres](https://img.shields.io/badge/PostgreSQL-316192?logo=postgresql&logoColor=white)

**Backend Stack**

![Plug](https://img.shields.io/badge/Plug-Elixir-blueviolet?style=for-the-badge&logo=elixir)
![Cowboy](https://img.shields.io/badge/Cowboy-WebSocket%20%2B%20HTTP-orange?style=for-the-badge)
![Ecto](https://img.shields.io/badge/Ecto-Database%20Toolkit-4B275F?style=for-the-badge&logo=postgresql)


### Backend
- **Elixir (sobre Erlang/OTP)**: Concurrencia, tolerancia a fallos y arquitectura basada en 
procesos.
- **Cowboy**: Servidor HTTP + WebSocket.

- **Plug**: Pipeline HTTP y ruteo de APIs.

- **PostgreSQL**: Base de datos relacional (persistencia de usuarios, chats, mensajes, relaciones, etc.).

- **Ecto**: Capa de persistencia de datos en Elixir que gestiona schemas, validaciones, consultas y transacciones, actuando como abstracción sobre PostgreSQL mediante su driver nativo.

- **OAuth (Goth + Google Cloud)**: Autenticación para servicios de media.

### Frontend
- **Vue 3**: SPA basada en componentes.
- **Vue Router**: Sistema de vistas y guards de autenticación.
- **State stores**: Socket, UI, theme. (JavaScript).

### Infraestructura
- **Docker**: Contenedorización del backend, base de datos y entorno de ejecución.
- **PostgreSQL**: Motor de base de datos principal.
- **Makefile**: Orquestación de entorno, dependencias, setup y ejecución.


<br><br>

## Backend - Compilación, Empaquetación y Ejecución
Instalar previamente:

- **Docker + Docker Desktop**
- **make (MSYS2)**

En **Windows**, además instalar **Visual Studio Build Tools**:
- En la instalación, incluir mínimamente:
	- C++ Build Tools
	- MSVC
	- Windows SDK
	
	<br>

1. Abrir ``Docker Desktop``.
2. (En Windows) `$env:PATH = "C:\msys64\usr\bin;C:\msys64\mingw64\bin;" + $env:PATH` -> para que make, gcc y sh funcionen correctamente.
3. `make up` -> Para levantar el contenedor de Docker.
4. `make deps` -> Para instalar las dependencias necesarias.
5. `make setup` -> Para preparar la DB. (o `make reset` si tiene datos y se quieren borrar).
6. `make seed` -> Para cargar datos de prueba en la DB.
7. `make run` -> Buildear y correr la app.


Windows ENV local:
`$env:DATABASE_URL="ecto://postgres:postgres@db:5432/echo_dev"` -> 
`$env:DATABASE_URL="ecto://postgres:postgres@localhost:5432/echo_dev"`


`$env:GOOGLE_APPLICATION_CREDENTIALS="/app/priv/gcp/service-account.json"`

## Frontend - Ejecución

1. Entrar a la carpeta `frontend` desde la terminal (otra a la del back).
2. Ejecutar `make deps`
3. Ejecutar `make run`.

<br><br>



## Backend - Arquitectura de Procesos y DB

### Funcionamiento general de la aplicación (a nivel de datos)

La aplicación está modelada como un sistema de mensajería en tiempo real centrado en usuarios, chats y mensajes, con relaciones explícitas para membresía, contactos y estados de lectura.

El núcleo del sistema gira alrededor de los chats, que pueden ser privados o grupales, y de los mensajes enviados dentro de esos chats por los usuarios.

---
#### **Usuarios como entidad central**

El sistema está completamente centrado en la entidad User, que representa tanto la identidad como el perfil social del usuario dentro de la aplicación.

Cada usuario contiene:
- Credenciales (``username``, ``email``, ``password hash``).
- Información de perfil (``name``, ``avatar``).
- Estado de presencia (``last_seen_at``).
- Relaciones con todos los componentes sociales.

Lógicamente se handlean verificaciones en el backend para que los usernames e emails sean únicos.

---
#### **Chats**

Un chat representa una conversación y puede ser de dos tipos:

- **private** → conversación uno a uno (sin nombre).

- **group** → conversación grupal (requiere nombre y avatar).

Cada chat:
- Tiene un creador (``creator_id``).
- Tiene muchos miembros (``chat_members``) (inicialmente, pues al poder abandonar un grupo o ser expulsado de uno, puede terminar habiendo sólo 1 integrante).
- Tiene mensajes.

En el schema, se decidieron reglas de negocio importantes:
- Los chats privados no pueden tener nombre.
- Los chats grupales sí deben tener nombre.

---
#### **Membresía de Chats (ChatMember)**

Esta tabla intermedia define la relación usuario ↔ chat. Esta relación se enriquece con:
- Rol dentro del chat (`member` o `admin`).
- Última vez que se leyó el chat.

---
#### **Mensajes **

Cada mensaje:
- Pertenece a un chat.
- Pertenece a un usuario (el emisor).
- Tiene contenido (``content``) y formato (`text`, `image`, `file`, etc.).
- Maneja estado (`sent`, `delivered`, `read`)

---
#### **Contactos**

Cada contacto:
- Relaciona un usuario con otro usuario.
- Permite un apodo (`nickname`) propio.

Además: 
- No se pueden duplicar contactos.
- Cada usuario maneja su propia lista de contactos.
- No es una relación bidireccional, sino que unilateral (userA puede agregar como contacto a userB y no necesariamente viceversa).

---
#### **Bloqueo de Contactos**

El schema ``BlockedContact`` ya está preparado para:

-Bloqueos entre usuarios.
-Clave compuesta (blocker + blocked).
-Evitar bloquearse a uno mismo.
-Evitar duplicados.

Y aunque no esté implementado aún, está listo para:
- Ocultar mensajes.
- Evitar nuevos chats.
- Restringir interacción.

---



### Árbol OTP (supervisado)

![Árbol de supervisión](/priv/docs/readme/supervision_tree.png)

- **``Application``**: Supervisor padre de la app.

- **`UserSessionSup`**: Supervisor dinámico encargado de iniciar nuevos `UserSession` cuando se requieran.
	- **``UserSession``**: Proceso que vive únicamente para un usuario concreto. Éste resuelve mensajes de WS o deriva su resolución a `ChatSession` si es que la acción requiere la intervención de un chat.

- **``ChatSessionSup``**: Supervisor dinámico encargado de iniciar nuevos `ChatSession` cuando se requieran.
	- **``ChatSession``**: Proceso que vive únicamente para un chat concreto. Éste resuelve todas las acciones que se tengan que realizar sobre ese chat.

- **``ProcessRegistry``**: Proceso que usa el módulo OTP `Registry` para almacenar en su estado a cada `UserSession` y `ChatSession` mediante las _via tuples_.

- **``Repo``**: Administra la pool de conexiones a Postgres. Es el intermediario entre el back y la DB.

- **``Goth``**: Se encarga de la autenticación OAuth con Google Cloud. Administra tokens de acceso, su renovación automática y su disponibilidad para servicios de media, evitando autenticación manual en cada request.

### Componentes no OTP

**``Cowboy Listener``**:
Atiende conexiones HTTP y WebSocket. Rutea:
<br>\- **WebSocket** hacia `UserSocket`
<br>\- **HTTP** hacia *Plug* `Router`

- **``UserSocket``**: Al igual que UserSession, hay uno por conexión Cliente-Servidor. Es el que funciona como intermediario entre los mensajes ``front 🠚 back`` y ``back 🠚 front``. Delega cada mensaje del cliente a una función pública del `UserSession` correspondiente, y envía cada mensaje del `UserSession` al cliente.

- **``Router``**: Pipeline HTTP basado en Plug que procesa requests y delega en los módulos de dominio correspondientes.


### Módulos de dominio interno

- **``Echo.Auth.Accounts``**: Lógica de autenticación y cuentas de usuario.

- **``Echo.Auth.Auth``**: Lógica concreta de autenticación y cuentas de usuario, utilizada por `Accounts`.

- **``Echo.Auth.Jwt``**: Gestiona la creación y validación de tokens para el cliente.

- **``Echo.Users.User``**: Gestión de usuarios. Utiliza `Repo` para accionar sobre la DB. Es utilizada principalemente por  `UserSession` y `ChatSession`.

- **``Echo.Chats.Chat``**: Gestión de chats. Utiliza `Repo` para accionar sobre la DB. Es utilizada principalemente por `ChatSession`.

- **``Echo.Messages.Messages``**: Gestión de mensajes. Utiliza `Repo` para accionar sobre la DB. Es utilizada principalemente por `Chat`.

- **``Echo.Contacts.Contacts``**: Gestión de contactos. Utiliza `Repo` para accionar sobre la DB. Es utilizada principalemente por `User` y `Chat`.


## Flujo de autenticación

![Diagrama de flujo de login](/priv/docs/readme/login_flow_chart.png)

### 1. Login request vía HTTP

1. El cliente envía credenciales a: ``POST /api/login``

2. El Router:
	- Parsea JSON.
	- Llama a `Echo.Auth.Accounts.login/2`.

3. Accounts:
	- Busca usuario en DB con ``Repo``.
	- Verifica la contraseña.
	- Genera el token JWT.

4. El backend responde:

```json
{ "token": "JWT_TOKEN" }
```

### 2. Creación del WebSocket

1. El cliente quiere iniciar el WebSocket con: `/ws?token=token`

2. Al ser ``/ws``, Cowboy lo handlea con ``UserSocket`` en lugar de ``Router``.

3. Se llama a `Echo.WS.UserSocket.init/2` donde se verifica el token.

4. Una vez validado, la conexión HTTP se actualiza a WebSocket, derivando en llamar a `Echo.WS.UserSocket.websocket_init/2`.

5. Ésta le pide el *process id* (pid) a ``UserSessionSup``, se lo guarda en su *state* y luego llama a `UserSession.login/1`.

6. Allí, ``UserSession`` se guarda el *pid* del socket en su *state* y linkea los procesos.

7. Por último, ``UserSession`` envía la información del usuario al cliente mediante el socket.

Con esto definimos la conexión via WebSocket desde el cliente hasta el UserSession.



## Flujo de enviar un mensaje

![Diagrama de flujo de enviar un mensaje](/priv/docs/readme/send_message_flow_chart.png)

### 1. Intención del cliente

1. El cliente envía un mensaje con la estructura definida en el contrato.

2. UserSocket lo despacha a `UserSession.send_message/2`.

3. UserSession lo delega a `ChatSession.send_message/3`.

4. Éste handlea la acción utilizando ``User``, ``Chat``, ``Message``, etc.

### 2. Acknowledgement (retorno)

1. El ``ChatSession`` le envía un mensaje a cada ``UserSession`` correspondiente a cada miembro de ese chat. Y cada ``UserSession`` se lo envía al cliente mediante ``UserSocket``.

2. El cliente le llega una estructura determinada en el contrato, de tipo `new_message`.

3. Éste determina si es un mensaje entrante (`incoming`) o saliente (`outgoing`).

Observación: En el caso de que sea `outgoing`, el mensaje de vuelta sería como una 'confirmación' o *acknowledgement* de que el mensaje se envió correctamente al backend. (Además de que trae campos actualizados, entre ellos, el id que le asignó el backend a ese mensaje).
<br>
<br>
<br>



## Frontend - Arquitectura

### ``App.vue``
Funciona como contenedor principal de la aplicación.
Responsabilidades:
- Inicicalizar el estado global (theme).
- Delegar render al ``router``.

### ``Routing Layer``
Views principales (estados generales de la app):
- ``LoginView``
- ``RegisterView``
- ``ChatsView``
- ``SettingsView``

### Guards de autenticación
En el `router` se determinan dos valores `requiresAuth:bool` y `guestOnly:bool` para redireccionar al usuario a distintas views dependiendo de su autorización.<br>
Ésta depende de si tiene almacenado en el _SessionStorage_ el token enviado desde el backend.

### Stores
- **socket.js**
	- Conexión websocket.
	- Envío de eventos al backend.
	- Recepción de mensajes.

- **theme.js**
	- Cambio de tema oscuro/claro.

- **ui.js**
	- Paneles abiertos.
	- Selección de chat.
	- Estados de interfaz.

### ChatsView - Orquestador
Es el centro de coordinación.
- Los componentes:
	- No conocen websocket.
	- No conocen el backend.
	- Solamente muestran los datos que les pasa ChatsView y emiten intenciones del cliente.

### ChatsView - Orquestador
Funciona como una sub-view dentro de ChatsView, ya que accede al socket, maneja estado real de los usuarios y dispara eventos importantes.<br>
Su función principal es la de mostrar los contactos y la búsqueda de usuarios.

