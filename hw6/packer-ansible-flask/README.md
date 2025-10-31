# Описание

## Установка зависимостей

```bash
apt-get update
apt-get install -y ansible python3-pip
```

1. токен Yandex Cloud:
```bash
export YC_TOKEN="your_oauth_token_here"
```

2. Сборка образа:
```bash
packer build my-ubuntu-nginx.pkr.hcl
```

## Проверка

После создания VM из образа:

```bash
curl http://<VM_IP>/
# Ответ: Hello, World from Flask!
```
