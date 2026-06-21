# Todo API with JWT Auth

A Todo REST API built with Node.js, Express, and PostgreSQL. Users sign up, log in, and get a JWT, which is required for every todo operation. Each user can only see and modify their own todos.

This was built as part of a DevOps practical task. AWS deployment, Terraform, and CI/CD are separate phases of that task and are tracked separately — this README covers the application as it stands right now: built, containerized, and runnable locally.

## Tech stack

- Node.js + Express
- PostgreSQL with Sequelize ORM
- JWT for authentication, bcrypt for password hashing
- Swagger (OpenAPI) for API documentation
- Docker + Docker Compose for local environment

## Project structure

```
.
├── config/           # database connection and sequelize config
├── controllers/       # request handlers for auth and todos
├── middleware/         # JWT verification, validation, error handler
├── migrations/         # sequelize migrations (users, todos tables)
├── models/             # Sequelize models and associations
├── routes/             # route definitions + swagger doc comments
├── Dockerfile
├── docker-compose.yml
└── server.js
```

## Running it locally

You need Docker installed. That's the only hard requirement — Postgres runs inside a container, so you don't need it installed on your machine.

1. Clone the repo and `cd` into it.
2. Run:
   ```
   docker-compose up --build
   ```
   This starts Postgres, runs the migrations automatically, and starts the API on port 3000.
3. The API is now available at `http://localhost:3000`.

If you'd rather run it without Docker (e.g. you already have Postgres running locally):

1. Install dependencies: `npm install`
2. Create a `.env` file in the project root (see Environment variables below)
3. Run migrations: `npx sequelize-cli db:migrate`
4. Start the server: `npm run dev` (uses nodemon) or `npm start`

## Environment variables

| Variable     | Description                                  | Example                                              |
|--------------|-----------------------------------------------|-------------------------------------------------------|
| `PORT`       | Port the server listens on                    | `3000`                                                 |
| `DB_URL`     | Postgres connection string                    | `postgres://postgres:password@localhost:5432/todo_db` |
| `JWT_SECRET` | Secret used to sign JWTs — use a long random value | `your-own-random-secret-string`                   |

When running via `docker-compose up`, these are already set inside `docker-compose.yml` for local use, so you don't need to create a `.env` file separately.

## API endpoints

| Method | Endpoint        | Auth required | Description                          |
|--------|-----------------|----------------|----------------------------------------|
| GET    | `/health`       | No             | Returns `{ "status": "ok" }`            |
| POST   | `/auth/signup`  | No             | Register with `{ email, password }`     |
| POST   | `/auth/login`   | No             | Log in, returns a JWT                   |
| POST   | `/todos`        | Yes            | Create a todo: `{ title, completed }`   |
| GET    | `/todos`        | Yes            | List the logged-in user's todos         |
| PUT    | `/todos/:id`    | Yes            | Update a todo you own                   |
| DELETE | `/todos/:id`    | Yes            | Delete a todo you own                   |

For protected endpoints, send the JWT from login in the request header:
```
Authorization: Bearer <your-token>
```

## API documentation (Swagger)

Once the server is running, full interactive API docs are available at:
```
http://localhost:3000/api-docs
```
You can try every endpoint directly from that page. For protected endpoints, click "Authorize" at the top of the page and paste in the token you got from `/auth/login`.

## Testing with Postman

A Postman collection is included (`Todo-API-JWT-Auth.postman_collection.json`). Import it into Postman, run **Auth → Login** first — it automatically saves the returned token so every request under the **Todos** folder works without manually copying it. The collection's `baseUrl` variable is set to `http://localhost:3000` by default; change it if you're testing against a different environment.

## Notes

- Passwords are hashed with bcrypt before being stored — never saved or logged in plaintext.
- A user can only read, update, or delete their own todos. Every todo query is scoped by the logged-in user's id, enforced at the database query level, not just in the UI.
- Login returns the same error for both "email doesn't exist" and "wrong password," so the API doesn't reveal which one was incorrect.

## Status

The application and Docker setup above are complete and tested locally. AWS deployment (ECS Fargate), Infrastructure as Code (Terraform), and the CI/CD pipeline are the next phase of this task and will be documented here once done.