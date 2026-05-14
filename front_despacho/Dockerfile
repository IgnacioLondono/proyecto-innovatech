FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG VITE_VENTAS_API_BASE=/api/ventas
ARG VITE_DESPACHOS_API_BASE=/api/despachos
ENV VITE_VENTAS_API_BASE=$VITE_VENTAS_API_BASE
ENV VITE_DESPACHOS_API_BASE=$VITE_DESPACHOS_API_BASE
RUN npm run build

FROM nginx:alpine
ARG BACKEND_HOST=127.0.0.1
COPY nginx.conf.template /tmp/nginx.conf.template
RUN sed "s/__BACKEND_IP__/${BACKEND_HOST}/g" /tmp/nginx.conf.template > /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
