#!/usr/bin/env bash
# Configuración inicial del clúster EKS para Innovatech Chile (EP3)
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${EKS_CLUSTER_NAME:-innovatech-cluster}"

echo "==> Conectando al clúster EKS: ${CLUSTER} (${REGION})"
aws eks update-kubeconfig --region "${REGION}" --name "${CLUSTER}"
kubectl get nodes

echo "==> Instalando metrics-server (requerido para HPA)"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' \
  || true

echo "==> Creando secret MySQL"
if [ -f k8s/mysql-secret.yaml ]; then
  kubectl apply -f k8s/mysql-secret.yaml
else
  echo "    Usando valores por defecto del lab (crear k8s/mysql-secret.yaml para producción)"
  kubectl create secret generic mysql-secret \
    --from-literal=MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-admin123}" \
    --from-literal=MYSQL_DATABASE=innovatech_db \
    --from-literal=MYSQL_USER="${MYSQL_USER:-admin}" \
    --from-literal=MYSQL_PASSWORD="${MYSQL_PASSWORD:-admin123}" \
    --dry-run=client -o yaml | kubectl apply -f -
fi

echo "==> Desplegando servicios"
kubectl apply -f k8s/mysql-k8s.yaml
sleep 15
kubectl apply -f k8s/backends-k8s.yaml
sleep 15
kubectl apply -f k8s/frontend-k8s.yaml
kubectl apply -f k8s/hpa-config.yaml

echo "==> Esperando pods..."
kubectl rollout status deployment/mysql-deployment --timeout=180s
kubectl rollout status deployment/despachos-api --timeout=180s
kubectl rollout status deployment/ventas-api --timeout=180s
kubectl rollout status deployment/frontend-despacho --timeout=180s

echo ""
echo "==> Estado final"
kubectl get pods
kubectl get svc
kubectl get hpa

FRONTEND_URL=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pendiente")
echo ""
echo "Frontend URL: http://${FRONTEND_URL}"
echo "Verificar APIs:"
echo "  curl http://${FRONTEND_URL}/api/v1/despachos"
echo "  curl http://${FRONTEND_URL}/api/v1/ventas"
