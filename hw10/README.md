# Практическая работа №10 - Managed Kubernetes

## Выбранное приложение
- **Docker образ**: nginx:1.25-alpine

## Файлы
- `namespace.yml` - манифест для создания namespace
- `deployment.yml` - манифест для развертывания nginx приложения

## Порядок выполнения

1. Создайте в кластере Namespace и Deployment для этого приложения:
```bash
kubectl apply -f namespace.yml
kubectl apply -f deployment.yml
```

2. Получите описание состояния конкретного Pod:
```bash
kubectl describe pod <POD_NAME> -n hw9-app
```

3. Получить список всех объектов в Namespace
```bash
kubectl get all -n hw9-app
```

4. Измените количество реплик в Deployment
```bash
kubectl scale deployment nginx-deployment --replicas=4 -n hw9-app
```

5. Получить список всех объектов в Namespace
```bash
kubectl get all -n hw9-app
```

6. Выведите логи приложения
```bash
kubectl logs <POD_NAME> -n hw9-app
# или для всех подов
kubectl logs -l app=nginx -n hw9-app
```

7. Удалите Deployment и Namespace
```bash
kubectl delete deployment nginx-deployment -n hw9-app
kubectl delete namespace hw9-app
```
