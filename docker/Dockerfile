FROM node:22-bookworm-slim AS runtime
WORKDIR /app

RUN corepack enable && corepack prepare pnpm@10.19.0 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY web/kostekd-ui/package.json ./web/kostekd-ui/package.json
RUN pnpm install --frozen-lockfile

COPY . .
RUN pnpm nx run kostekd-ui:build

ENV HOST=0.0.0.0
ENV PORT=4321
EXPOSE 4321
CMD ["node", "./web/kostekd-ui/dist/server/entry.mjs"]
