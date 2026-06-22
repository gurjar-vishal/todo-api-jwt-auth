# Todo API with JWT Auth

A Todo REST API built with Node.js, Express, and PostgreSQL, deployed on AWS ECS Fargate with a full CI/CD pipeline.

**Live URL:** http://todo-api-alb-430959870.us-east-1.elb.amazonaws.com  
**Swagger Docs:** http://todo-api-alb-430959870.us-east-1.elb.amazonaws.com/api-docs  
**Health Check:** http://todo-api-alb-430959870.us-east-1.elb.amazonaws.com/health  
**GitHub:** https://github.com/gurjar-vishal/todo-api-jwt-auth

---

## Tech Stack

- **Runtime:** Node.js + Express
- **Database:** PostgreSQL (AWS RDS) with Sequelize ORM
- **Auth:** JWT (jsonwebtoken) + bcrypt password hashing
- **Docs:** Swagger UI (OpenAPI 3.0)
- **Container:** Docker + Docker Compose
- **Cloud:** AWS ECS Fargate, ECR, RDS, ALB, CloudWatch
- **IaC:** Terraform
- **CI/CD:** GitHub Actions

---

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml        # GitHub Actions CI/CD pipeline
├── config/                   # Database and Sequelize config
├── controllers/              # Auth and Todo request handlers
├── middleware/               # JWT auth, validation, error handler
├── migrations/               # Sequelize migrations (users, todos)
├── models/                   # Sequelize models and associations
├── routes/                   # Route definitions with Swagger comments
├── terraform/                # IaC — ECS, ALB, Security Groups, ECR
├── Dockerfile
├── docker-compose.yml
└── server.js
```

---

## Running Locally

Only requirement is Docker Desktop.

```bash
git clone https://github.com/gurjar-vishal/todo-api-jwt-auth.git
cd todo-api-jwt-auth
docker-compose up --build
```

API available at `http://localhost:3000`. Postgres starts automatically inside a container, migrations run on boot.

**Without Docker** (if you have Postgres installed locally):

```bash
npm install
# create .env file (see Environment Variables below)
npx sequelize-cli db:migrate
npm run dev
```

---

## Environment Variables

| Variable     | Description                        |
|--------------|------------------------------------|
| `PORT`       | Server port (default: 3000)        |
| `DB_URL`     | PostgreSQL connection string        |
| `JWT_SECRET` | Secret for signing JWTs            |
| `BASE_URL`   | Public URL (used by Swagger UI)    |

---

## API Endpoints

| Method | Endpoint       | Auth | Description                        |
|--------|----------------|------|------------------------------------|
| GET    | `/health`      | No   | Returns `{ "status": "ok" }`       |
| POST   | `/auth/signup` | No   | Register `{ email, password }`     |
| POST   | `/auth/login`  | No   | Login, returns JWT                 |
| POST   | `/todos`       | Yes  | Create todo `{ title, completed }` |
| GET    | `/todos`       | Yes  | List logged-in user's todos        |
| PUT    | `/todos/:id`   | Yes  | Update a todo                      |
| DELETE | `/todos/:id`   | Yes  | Delete a todo                      |

Protected endpoints require:
```
Authorization: Bearer <token>
```

---

## AWS Deployment (ECS Fargate)

### Architecture

```
Internet → ALB (port 80) → ECS Fargate Task (port 3000) → RDS PostgreSQL
```

**Security groups:**
- `alb-sg` — allows HTTP 80 from internet only
- `ecs-sg` — allows port 3000 from `alb-sg` only
- `rds-sg` — allows port 5432 from `ecs-sg` only

Nothing is directly internet-exposed except the ALB.

### Manual Deployment Steps

1. Push Docker image to ECR:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker build -t todo-api .
docker tag todo-api:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/todo-api:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/todo-api:latest
```

2. Create RDS PostgreSQL instance (Free tier, `db.t3.micro`)
3. Run migrations against RDS:
```bash
export DB_URL="postgres://postgres:<password>@<rds-endpoint>:5432/todo_db"
npx sequelize-cli db:migrate
```
4. Create ECS Cluster (Fargate), Task Definition, and Service
5. Create ALB → Target Group → Listener (port 80 → port 3000)
6. Set health check path to `/health`

### Terraform (IaC)

The `terraform/` folder provisions the same infrastructure from code.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# fill in your actual DB_URL and JWT_SECRET
terraform init
terraform plan
terraform apply
```

Resources provisioned: ECR repository, ECS cluster, task definition, service, ALB, target group, listener, security groups, CloudWatch log group.

---

## CI/CD Pipeline

GitHub Actions workflow at `.github/workflows/deploy.yml` triggers on every push to `main`.

**Pipeline stages:**
1. Checkout code
2. Configure AWS credentials (from GitHub Secrets)
3. Login to Amazon ECR
4. Build Docker image and push to ECR (tagged with git SHA)
5. Update ECS task definition with new image
6. Deploy to ECS and wait for stability

**Required GitHub Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## Logging & Monitoring

### Application Logs (CloudWatch)

All container logs stream to CloudWatch automatically via the `awslogs` driver configured in the ECS task definition.

**Log group:** `/ecs/todo-api`

To view logs:
- AWS Console → CloudWatch → Log groups → `/ecs/todo-api`
- Each ECS task creates a log stream under `ecs/todo-api/<task-id>`

### CPU & Memory Monitoring

ECS publishes CPU and memory utilization metrics to CloudWatch automatically for every running task.

To view:
- AWS Console → CloudWatch → Metrics → ECS → ClusterName, ServiceName
- Metrics available: `CPUUtilization`, `MemoryUtilization`
- Set alarms: CloudWatch → Alarms → Create alarm → pick the ECS metric → set threshold (e.g. alert if CPU > 80% for 5 minutes)

### Debugging Application Issues

If a request fails or the app crashes, this is the order I follow:

1. **Check ALB target health** — EC2 → Target Groups → `todo-api-tg` → Targets tab. If the target shows unhealthy, the container isn't responding to `/health` — the issue is in the app, not networking.

2. **Check CloudWatch logs** — CloudWatch → Log groups → `/ecs/todo-api`. Filter by the task's log stream to see exact error messages and stack traces from the running container.

3. **Check ECS task stopped reason** — if the task keeps stopping, go to ECS → Clusters → `todo-cluster` → Tasks tab → click a stopped task → scroll to "Stopped reason." Common causes: wrong environment variables, database connection failure, container port mismatch.

4. **Check RDS connectivity** — if logs show a DB connection error, verify the `ecs-sg` inbound rule on `rds-sg` is set correctly and that the `DB_URL` environment variable in the task definition points to the correct RDS endpoint.

---

## Security Notes

- Passwords are hashed with bcrypt before storage — never logged or stored in plaintext
- JWT tokens expire after 1 hour
- Login returns the same error message whether the email doesn't exist or the password is wrong — prevents account enumeration
- Every todo query is scoped by `user_id` at the database level — one user cannot access another user's data
- RDS is in a private subnet with no public access — only reachable from ECS tasks via security group rules
- Secrets (DB credentials, JWT secret) are passed as environment variables, not baked into the Docker image