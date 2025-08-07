# Kong API Gateway Configuration

This directory contains the declarative configuration (`kong.yml`) for the Kong API Gateway used in the **FitRang** backend system. Kong acts as a reverse proxy for routing, securing, and managing requests between clients and microservices.

---

## 🧠 Overview

Kong sits at the edge of the system and forwards traffic to internal services such as:

- Email Verifier
- Profile Service
- Notification Service (REST and WebSocket)
- Analysis Service
- Keycloak (auth server)
- Elasticsearch (optionally protected)
- Token Login and Refresh endpoints

Kong also enforces authentication and CORS policies.

---

## 📄 Configuration File: `kong.yml`

This file is a **declarative configuration** written in YAML using `_format_version: "3.0"` and defines:

- **Services**: Internal backend services
- **Routes**: Public paths through which services are exposed
- **Plugins**:
  - Global CORS plugin
  - Custom `token-introspect-plugin` for auth enforcement
  - `kong-plugin-keycloak-login` and `token-refresh-plugin` for authentication workflows

---

## 🧩 Key Plugins Used

### ✅ Global Plugins

- **CORS Plugin**: Allows access from:
  - `http://localhost:3000`
  - `http://127.0.0.1:3000`
  - Chrome extension `chrome-extension-id`

### 🔒 Auth-Related Plugins

- `token-introspect-plugin`: Validates access tokens by introspecting them via Keycloak.
- `kong-plugin-keycloak-login`: Handles user login by forwarding to Keycloak’s token endpoint.
- `token-refresh-plugin`: Handles token refresh requests.

---

## 🔗 Services and Routes

| Service Name               | URL                          | Public Route      | Plugins                 |
|---------------------------|------------------------------|-------------------|--------------------------|
| `email-verifier-service`  | `http://email-verifier:8081` | `/register`       | None                    |
| `profile-service`         | `http://profile-service:8083`| `/profile`        | `token-introspect`      |
| `notification-service`    | `http://notification-service:8085` | `/notification` | `token-introspect` |
| `notification-service-ws` | `http://notification-service:8085` | `/notification-ws` | None              |
| `analysis-service`        | `http://analysis-service:8086` | `/analysis`     | `token-introspect`      |
| `keycloak-service`        | `http://keycloak:8080`       | `/keycloak`       | None                    |
| `elastic-search-service`  | `http://elasticsearch:9200`  | `/elastic`        | `token-introspect` *(disabled)* |
| `keycloak-login-service`  | `http://keycloak:8080/realms/FitRang/protocol/openid-connect/token` | `/login` | `kong-plugin-keycloak-login` |
| `token-refresh-service`   | Same as above                | `/refresh`        | `token-refresh-plugin`  |

