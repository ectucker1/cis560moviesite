const bodyParser = require('body-parser')
const app = require('express')()
const sql = require('mssql')
const jwt = require('jsonwebtoken');

const sqlConfig = {
  user: process.env.SQL_SERVER_USER,
  password: process.env.SQL_SERVER_PASSWORD,
  database: process.env.SQL_SERVER_DATABASE,
  server: process.env.SQL_SERVER_URL,
  port: parseInt(process.env.SQL_SERVER_PORT),
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  },
  options: {
    encrypt: false, // for azure
    trustServerCertificate: false // change to true for local dev / self-signed certs
  }
}

const jwtKey = process.env.JWT_KEY
const jwtDuration = '3 days'

app.use(bodyParser.json())

app.all('/getJSON', (req, res) => {
  res.json({ data: 'data' })
})

app.all('/movies', async (req, res) => {
  await sql.connect(sqlConfig)
  const result = await sql.query`SELECT * FROM MovieDatabase.Movies`
  await res.send(result.recordsets[0])
})

app.all('/auth/login', async (req, res) => {
  // Search for user in database
  let pool = await sql.connect(sqlConfig)
  let userID = await pool.request()
    .input('Email', sql.NVarChar(128), req.body.email)
    .input('PasswordHash', sql.NVarChar(128), req.body.password)
    .execute('CheckLogin')

  // User not found; removing
  if (userID == null)
    return res.status(401).end()

  // Create and send token with UserID
  let token = jwt.sign({ id: userID }, jwtKey, { algorithm: 'RS256', expiresIn: jwtDuration })
  res.send({ token: token })
})

app.all('/auth/logout', async (req, res) => {
  // Don't need to handle logout on server - the token is already gone
  res.status(400).send()
})

app.all('/auth/user', async (req, res) => {
  try {
    // Extract UserID from token
    let user = jwt.verify(token, jwtKey);

    // Search for user in database
    let pool = await sql.connect(sqlConfig)
    let userData = await pool.request()
      .input('UserID', sql.Int, user.id)
      .output('UserID', sql.Int)
      .output('DisplayName', sql.Int)
      .output('IsAdmin', sql.Int)
      .execute('GetUser')

    res.send({
      id: userData.UserId,
      name: userData.DisplayName,
      admin: userData.IsAdmin > 0
    })
  } catch(err) {
    res.status(401).end()
  }
})

module.exports = app
