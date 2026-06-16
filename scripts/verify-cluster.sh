#!/usr/bin/env bash
# Verificación funcional del clúster (IE7 - Front → Back)
set -euo pipefail

echo "==> Nodos"
kubectl get nodes

echo ""
echo "==> Pods"
kubectl get pods

FAILED=0

echo ""
echo "==> Servicios"
kubectl get svc

FRONTEND_URL=$(kubectl get svc frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -z "${FRONTEND_URL}" ]; then
  echo "ERROR: LoadBalancer del frontend sin hostname asignado"
  FAILED=1
else
  echo ""
  echo "==> Frontend público: http://${FRONTEND_URL}"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${FRONTEND_URL}/" || echo "000")
  if [ "${HTTP_CODE}" = "200" ]; then
    echo "OK  Frontend responde HTTP ${HTTP_CODE}"
  else
    echo "FAIL Frontend HTTP ${HTTP_CODE}"
    FAILED=1
  fi

  for ENDPOINT in "/api/v1/despachos" "/api/v1/ventas"; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${FRONTEND_URL}${ENDPOINT}" || echo "000")
    if [ "${CODE}" = "200" ]; then
      echo "OK  ${ENDPOINT} → HTTP ${CODE}"
    else
      echo "FAIL ${ENDPOINT} → HTTP ${CODE}"
      FAILED=1
    fi
  done
fi

echo ""
echo "==> HPA"
kubectl get hpa 2>/dev/null || echo "HPA no configurado"

echo ""
echo "==> Métricas (requiere metrics-server)"
kubectl top pods 2>/dev/null || echo "metrics-server no disponible aún"

echo ""
if [ "${FAILED}" -eq 0 ]; then
  echo "RESULTADO: Clúster operativo ✓"
else
  echo "RESULTADO: Hay fallos — revisar logs con kubectl logs"
  exit 1
fi
