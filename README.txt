# cis560moviesite

## Setup and Run Application

1. Install NodeJS
2. Install SQL server
3. Run the scripts in the `SQL` directory to initialize the database
4. Create a `.env` file in the project directory in the following format, describing how to connect to your database

```
SQL_SERVER_USER=<probably sa>
SQL_SERVER_PASSWORD=<account password>
SQL_SERVER_DATABASE=<probably master>
SQL_SERVER_URL=<probably localhost>
SQL_SERVER_PORT=<probably 1433>
JWT_KEY=<secret key for login system; could be any random sequence>
```

5. Start the server with

```bash
# install dependencies
$ npm install

# serve with hot reload at localhost:3000
$ npm run dev
```

6. Go to `localhost:3000` in your webbrowser.

See also the [documentation for NuxtJS](https://nuxtjs.org).

## Project Structure

### `SQL`

This directory contains scripts to create the SQL Tables, Procedures, and initial test data.

### `server-middleware`

The server-middleware directory contains the application API code, which forms the interface between the website and the database.
All the code which interacts with SQL Server is in `server-middleware/rest.js`.

### `components`

The components directory contains Vue.js components. Components make up different parts of pages reused throughout the site.

### `pages`

This directory contains the application views and routes.
Nuxt will read all the `*.vue` files inside this directory and setup page routing automatically.

### `nuxt.config.js`

The `nuxt.config.js` file provides the primary configuration for the Nuxt webserver.
