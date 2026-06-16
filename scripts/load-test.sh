#!/usr/bin/env bash
# Simula carga HTTP para demostrar autoscaling (HPA)
set -euo pipefail

URL="${1:-}"
REQUESTS="${2:-500}"
CONCURRENCY="${3:-20}"

if [ -z "${URL}" ]; then
  FRONTEND_URL=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -z "${FRONTEND_URL}" ]; then
    echo "Uso: $0 <URL_FRONTEND> [requests] [concurrency]"
    echo "Ejemplo: $0 http://xxx.elb.amazonaws.com 1000 50"
    exit 1
  fi
  URL="http://${FRONTEND_URL}"
fi

echo "==> Generando carga contra ${URL}"
echo "    Requests: ${REQUESTS}, Concurrencia: ${CONCURRENCY}"
echo "    Monitorear HPA en otra terminal: kubectl get hpa -w"
echo ""

if command -v hey >/dev/null 2>&1; then
  hey -n "${REQUESTS}" -c "${CONCURRENCY}" "${URL}/api/v1/despachos"
  hey -n "${REQUESTS}" -c "${CONCURRENCY}" "${URL}/api/v1/ventas"
else
  echo "    (hey no instalado, usando curl en loop)"
  for i in $(seq 1 "${REQUESTS}"); do
    curl -s -o /dev/null "${URL}/api/v1/despachos" &
    curl -s -o /dev/null "${URL}/api/v1/ventas" &
    if [ $((i % CONCURRENCY)) -eq 0 ]; then
      wait
    fi
  done
  wait
fi

echo ""
echo "==> Estado HPA tras la carga:"
kubectl get hpa
kubectl top pods 2>/dev/null || echo "    (metrics-server aún propagando métricas)"
