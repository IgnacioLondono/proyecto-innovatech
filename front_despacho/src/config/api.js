const trimSlash = (s) => String(s || "").replace(/\/+$/, "");

/** Base pública bajo Nginx: /api/ventas → proxy a :8082/api/v1/ventas */
export const ventasBase = trimSlash(
  import.meta.env.VITE_VENTAS_API_BASE ?? "/api/ventas"
);

/** Base pública bajo Nginx: /api/despachos → proxy a :8081/api/v1/despachos */
export const despachosBase = trimSlash(
  import.meta.env.VITE_DESPACHOS_API_BASE ?? "/api/despachos"
);
