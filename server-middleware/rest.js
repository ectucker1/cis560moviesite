const bodyParser = require('body-parser')
const app = require('express')()
const sql = require('mssql')

const sqlConfig = {
  user: '',
  password: '',
  database: 'master',
  server: 'localhost',
  port: 1401,
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

app.use(bodyParser.json())
app.all('/getJSON', (req, res) => {
  res.json({ data: 'data' })
})

app.all('/movies', async (req, res) => {
  await sql.connect(sqlConfig)
  const result = await sql.query`SELECT * FROM MovieDatabase.Movies`
  await res.send(result.recordsets[0])
})

module.exports = app
