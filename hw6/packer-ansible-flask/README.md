# Packer + Ansible: Flask App with Nginx

Автоматизированное создание образа VM с Flask приложением и Nginx.

## Структура проекта

```
.
├── my-ubuntu-nginx.pkr.hcl    # Конфигурация Packer
├── ansible/
│   ├── playbook.yml           # Ansible playbook (основной)
│   ├── files/
│   │   ├── app.py             # Flask приложение
│   │   ├── flask-app.service  # Systemd service
│   │   └── nginx.conf         # Конфигурация Nginx
│   └── inventory.ini          # Inventory файл (не используется, Packer передает хост)
└── README.md
```

## Требования

- Packer >= 1.14
- Ansible >= 2.9
- Yandex Cloud аккаунт с настроенными:
  - folder_id
  - subnet_id
  - OAuth token

## Установка зависимостей

```bash
apt-get update
apt-get install -y ansible python3-pip
```

## Как использовать

1. Экспортируйте токен Yandex Cloud:
```bash
export YC_TOKEN="your_oauth_token_here"
```

2. Запустите сборку образа:
```bash
./packer_1.14.2_linux_arm64/packer build my-ubuntu-nginx.pkr.hcl
```

3. Packer создаст временную VM, выполнит Ansible playbook, создаст образ.

## Проверка работы

После создания VM из образа:

```bash
curl http://<VM_IP>/
# Ответ: Hello, World from Flask!
```

## Что происходит внутри?

1. **Packer** создает временную VM в Yandex Cloud
2. **Ansible** выполняет playbook:
   - Устанавливает Python 3, pip, virtualenv
   - Копирует Flask приложение в `/opt/flask-app/`
   - Устанавливает Flask в virtualenv
   - Создает systemd service для автозапуска Flask
   - Устанавливает и настраивает Nginx как reverse proxy
3. **Packer** создает образ и удаляет временную VM
