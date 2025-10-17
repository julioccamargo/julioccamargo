4.2. Dockerfile Seguro para um Serviço Frontend (/apps/<pasta-do-servico>/Dockerfile)
Este exemplo usa um build multi-stage para criar uma imagem Nginx mínima e segura para uma aplicação frontend (e.g., Vue.js), incluindo melhorias de segurança e confiabilidade.

# --- Estágio 1: Ambiente de Build ---
# Usa uma imagem Node.js completa para instalar dependências e construir a aplicação.
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# --- Estágio 2: Ambiente de Produção ---
# Começa a partir de uma imagem Nginx limpa e leve.
FROM nginx:stable-alpine

# Adiciona o curl para as verificações de saúde (health checks).
RUN apk add --no-cache curl

# Copia apenas os arquivos da aplicação compilada do estágio 'builder'.
COPY --from=builder /app/dist /usr/share/nginx/html

# Copia o arquivo de configuração do Nginx.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Define a posse dos arquivos para o usuário não-root 'nginx' para maior segurança.
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid && \
    chown -R nginx:nginx /var/cache/nginx

# Muda para o usuário não-root.
USER nginx

# Expõe a porta HTTP padrão.
EXPOSE 80

# Define uma verificação de saúde para permitir que a plataforma monitore o estado do serviço.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# Comando para iniciar o servidor Nginx.
CMD ["nginx", "-g", "daemon off;"]
