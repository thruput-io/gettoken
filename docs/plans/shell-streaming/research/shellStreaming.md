# Shell Streaming & Microservices Tooling Reference

A comprehensive guide to the utilities, commands, and design patterns used for building streaming, contract-first, privilege-separated architectures using Unix shell pipelines.

---

## 🧰 Core Utilities & Tools

| Tool | Core Purpose in Microservices | Common Installation Command |
| :--- | :--- | :--- |
| **`socat`** | Network & Unix Socket streaming wrapper (bidirectional IPC). | `sudo apt install socat` |
| **`nc` (Netcat)** | Unidirectional data piping over TCP/UDP network connections. | `sudo apt install netcat-openbsd` |
| **`jq`** | Advanced JSON parsing, formatting, and secure variable execution (`@sh`). | `sudo apt install jq` |
| **`jo`** | Fast, punchy JSON object and array creation via short key-value paths. | `sudo apt install jo` |
| **`gron`** | Transforms JSON into discrete path-assignments (and back again). | `sudo apt install gron` |
| **`check-jsonschema`** | CLI contract verification engine leveraging standard JSON Schema. | `pip install check-jsonschema` |
| **`pv` (Pipe Viewer)** | Stream monitoring, throughput metric logging, and line throttling. | `sudo apt install pv` |

---

## 📜 Command Reference Guide

### 1. Core Streaming & Throttling
* **Live data tailing (unbuffered grep):**
  ```bash
  tail -f /var/log/nginx/access.log | grep --line-buffered "HTTP/1.1\" 5"
  ```
* **Bandwidth throttling (e.g., limit stream throughput to 2 MB/s):**
  ```bash
  cat massive_dump.csv | pv -q -L 2m | nc data-sink.internal 8080
  ```

### 2. Network & Socket Listening (`socat`)
* **Create a persistent network service (forks a child per request):**
  ```bash
  socat TCP4-LISTEN:8080,fork,reuseaddr SYSTEM:'tr "[a-z]" "[A-Z]"'
  ```
* **Create a secured Unix Domain Socket for privilege separation:**
  ```bash
  sudo socat UNIX-LISTEN:/run/priv_ops.sock,fork,reuseaddr,mode=0660,group=www-data SYSTEM:'...'
  ```
* **Stream data into a Unix Domain Socket from an unprivileged client:**
  ```bash
  echo '{"action":"ping"}' | socat - UNIX-CONNECT:/run/priv_ops.sock
  ```

### 3. Contract Validation
* **Validate a streamed line of JSON against a strict schema contract:**
  ```bash
  echo "$line" | check-jsonschema --schemafile "schema.json" -
  ```

### 4. JSON Generation & Manipulation
* **Generate complex JSON via native key paths (`jo`):**
  ```bash
  jo id=usr_102 user=$(jo name=Alice roles=$(jo -a admin billing))
  ```
* **Construct JSON blocks using JSONPath-style syntax (`gron`):**
  ```bash
  cat <<EOF | gron --ungron
  json.id = "usr_102"
  json.user.name = "Alice"
  EOF
  ```

### 5. Streaming Data Parsing
* **Parse a specific value out of a JSON stream using path matching (`gron`):**
  ```bash
  USER_NAME=$(echo "$json_input" | gron | grep "json.user.name" | cut -d'"' -f2)
  ```
* **Bulk-extract JSON attributes safely straight into native Shell Variables (`jq`):**
  ```bash
  eval $(echo "$request" | jq -r '@sh "ID=\(.id) NAME=\(.user.name) ROLE=\(.user.meta.role)"')
  ```

---

## 🚀 Architectural Blueprint: Privilege-Separated Microservice

### 🛡️ The Privileged Core (`privileged_root_daemon.sh`)
Runs as `root` and handles incoming Unix socket streams. It acts as an orchestrator, strictly enforcing the JSON schema before performing any sensitive operation.

```bash
#!/usr/bin/env bash
SOCKET_PATH="/run/priv_ops.sock"
SCHEMA_PATH="/opt/microservices/schema_priv_ops.json"

rm -f "$SOCKET_PATH"

socat UNIX-LISTEN:"$SOCKET_PATH",fork,reuseaddr,mode=0660,group=www-data SYSTEM:'
    read -r request
    
    if ! echo "$request" | check-jsonschema --schemafile "'"$SCHEMA_PATH"'" - > /dev/null 2>&1; then
        jo status="error" error="Forbidden: Request payload violated JSON contract."
        exit 0
    fi
    
    ACTION=$(echo "$request" | gron | grep "json.action" | cut -d"\"" -f2)
    TARGET=$(echo "$request" | gron | grep "json.target" | cut -d"\"" -f2)
    
    case "$ACTION" in
        "RESTART_SERVICE")
            if [[ "$TARGET" =~ ^(nginx|memcached|redis)$ ]]; then
                systemctl restart "$TARGET"
                jo status="success" action="$ACTION" target="$TARGET" message="Service restarted successfully."
            else
                jo status="error" error="Unauthorized target service specified."
            fi
            ;;
    esac
'
```

### 👥 The Unprivileged Producer (`unprivileged_app.sh`)
Mimics your main application space (e.g., a web server worker running under `www-data`). It cannot execute system commands directly but can securely stream payloads over the IPC interface.

```bash
#!/usr/bin/env bash
SOCKET_PATH="/run/priv_ops.sock"

request_payload=$(jo action="RESTART_SERVICE" target="nginx")
response=$(echo "$request_payload" | socat - UNIX-CONNECT:"$SOCKET_PATH")

eval $(echo "$response" | jq -r '@sh "STATUS=\(.status) MSG=\(.message) ERR=\(.error)"')

if [ "$STATUS" == "success" ]; then
    echo "Root Execution Succeeded: $MSG"
else
    echo "Root Execution Failed: $ERR"
fi
```