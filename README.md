# Inertia Rails React Starter Kit

A modern full-stack starter application with Rails backend and React frontend using Inertia.js based on the [Laravel Starter Kit](https://github.com/laravel/react-starter-kit).

## Features

- [Inertia Rails](https://inertia-rails.dev) & [Vite Rails](https://vite-ruby.netlify.app) setup
- [React](https://react.dev) frontend with TypeScript & [shadcn/ui](https://ui.shadcn.com) component library
- User authentication system (based on [Authentication Zero](https://github.com/lazaronixon/authentication-zero))
- [Kamal](https://kamal-deploy.org/) for deployment
- Optional SSR support

See also:
- [Svelte Starter Kit](https://github.com/inertia-rails/svelte-starter-kit) for Inertia Rails with Svelte
- [Vue Starter Kit](https://github.com/inertia-rails/vue-starter-kit) for Inertia Rails with Vue

<a href="https://evilmartians.com/?utm_source=inertia-rails-react-starter-kit&utm_campaign=project_page">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Built by Evil Martians" width="236" height="54">
</a>

## Setup

1. Clone this repository
2. Setup dependencies & run the server:
   ```bash
   bin/setup
   ```
3. Open http://localhost:3000

## Docker (Development)

Use Docker Compose for a local dev environment with Rails, Vite, and Postgres.

1. Build and start the containers:
  ```bash
  docker compose -f docker-compose.dev.yml up --build
  ```
2. Open http://localhost:3000 (the Vite dev server on port 3036 serves assets and HMR behind the scenes — you don't need to open it directly).

Notes:
- The database runs in a `postgres:15` container and persists in a named volume.
- If you need to run Rails tasks, use `docker compose -f docker-compose.dev.yml exec web <command>`.
  Example:
  ```bash
  docker compose -f docker-compose.dev.yml exec web bin/rails db:migrate
  ```

## Docker (Production-like)

The production Dockerfile builds a single image and runs the app on port 80.

```bash
docker build -t react_starter_kit .
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  --name react_starter_kit react_starter_kit
```

## Enabling SSR

This starter kit comes with optional SSR support. To enable it, follow these steps:

1. Open `app/frontend/entrypoints/inertia.ts` and uncomment part of the `setup` function:
   ```ts
   // Uncomment the following to enable SSR hydration:
   // if (el.hasChildNodes()) {
   //   hydrateRoot(el, createElement(App, props))
   //   return
   // }
   ```
2. Open `config/deploy.yml` and uncomment several lines:
   ```yml
   servers:
     # Uncomment to enable SSR:
     # vite_ssr:
     #   hosts:
     #     - 192.168.0.1
     #   cmd: bundle exec vite ssr
     #   options:
     #     network-alias: vite_ssr
      
   # ...
      
   env:
     clear:
       # Uncomment to enable SSR:
       # INERTIA_SSR_ENABLED: true
       # INERTIA_SSR_URL: "http://vite_ssr:13714"
      
   # ...
      
   builder:
     # Uncomment to enable SSR:
     # dockerfile: Dockerfile-ssr
   ```
   
That's it! Now you can deploy your app with SSR support.

## License

The project is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
