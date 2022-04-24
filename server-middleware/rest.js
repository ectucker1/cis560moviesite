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
  },
  parseJSON: true
}

const jwtKey = process.env.JWT_KEY
const jwtDuration = '3 days'

app.use(bodyParser.json())

// Returns the user from the given request, based on the authorization token
async function getUser(req) {
  try {
    // Extract UserID from token
    let token = req.header('Authorization').split(' ')[1]
    let user = jwt.verify(token, jwtKey);

    // Search for user in database
    let pool = await sql.connect(sqlConfig)
    let userData = await pool.request()
      .input('UserID', sql.Int, user.id)
      .execute('MovieDatabase.GetUser')

    return {
      loggedIn: true,
      id: userData.recordsets[0][0].UserID,
      name: userData.recordsets[0][0].DisplayName,
      admin: userData.recordsets[0][0].IsAdmin > 0
    }
  } catch {
    return {
      loggedIn: false,
      id: -1,
      name: '',
      admin: false
    }
  }
}

app.post('/auth/signup', async (req, res) => {
  try {
    // Search for user in database
    let pool = await sql.connect(sqlConfig)
    let result = await pool.request()
      .input('Email', sql.NVarChar(128), req.body.email)
      .input('DisplayName', sql.NVarChar(64), req.body.displayName)
      .input('PasswordHash', sql.NVarChar(128), req.body.password)
      .execute('MovieDatabase.CreateUser')

    return res.status(200).end()
  } catch (e) {
    return res.status(500).end()
  }
})

app.get('/api/movies/unverified/get', async (req, res) => {
  let pool = await sql.connect(sqlConfig)
  let result = await pool.request()
    .execute('MovieDatabase.GetUnverifiedMovies')

  res.send(result.recordsets[0])
})

app.post('/api/movies/unverified/verify', async (req, res) => {
  try {
    let user = await getUser(req)
    let pool = await sql.connect(sqlConfig)
    let result = await pool.request()
      .input('MovieID', sql.Int, req.body.id)
      .input('IsAdmin', sql.Int, user.admin ? 1 : 0)
      .execute('MovieDatabase.VerifyMovie')

    return res.status(200).end()
  } catch (e) {
    console.log(e)
    return res.status(500).end()
  }
})

// Post method to deny a movie from being verified
app.post('/api/movies/unverified/deny', async (req, res) => {
  try {
    let user = await getUser(req)
    let pool = await sql.connect(sqlConfig)
    let result = await pool.request()
      .input('MovieID', sql.Int, req.body.id)
      .input('IsAdmin', sql.Int, user.admin ? 1 : 0)
      .execute('MovieDatabase.DeleteMovie')

    return res.status(200).end()
  } catch (e) {
    console.log(e)
    return res.status(500).end()
  }
})

// Sends a post request to the backend to create a new movie that is not verified
app.post('/api/movies/submit', async (req, res) => {
  try {
    // Extract UserID from token
    let token = req.header('Authorization').split(' ')[1]
    let user = jwt.verify(token, jwtKey);

    // Search for user in database
    let pool = await sql.connect(sqlConfig)
    console.log(req.body.data)
    let result = await pool.request()
      .input('Title', sql.NVarChar(128), req.body.data.title)
      .input('Length', sql.Int, req.body.data.length)
      .input('Year', sql.Int, req.body.data.releaseDate)
      .input('UserID', sql.Int, user.id)
      .input("IMDBID", sql.Int, null)
      .input("GenreId", sql.Int, req.body.data.genre)
      .execute('MovieDatabase.CreateMovie')

    return res.status(200).end()
  } catch (e) {
    console.log(e)
    return res.status(500).end()
  }
})

app.all('/auth/login', async (req, res) => {
  // Search for user in database
  let pool = await sql.connect(sqlConfig)
  let userID = await pool.request()
    .input('Email', sql.NVarChar(128), req.body.email)
    .input('PasswordHash', sql.NVarChar(128), req.body.password)
    .execute('MovieDatabase.CheckLogin')

  // User not found; removing
  if (userID.recordsets[0][0]['UserID'] == null)
    return res.status(401).end()

  // Create and send token with UserID
  let token = jwt.sign({ id: userID.recordsets[0][0]['UserID'] }, jwtKey, { algorithm: 'HS256', expiresIn: jwtDuration })
  await res.send({ token: token })
})

app.all('/auth/logout', async (req, res) => {
  // Don't need to handle logout on server - the token is already gone
  res.status(200).send()
})

app.all('/auth/user', async (req, res) => {
  let user = await getUser(req)

  if (user.loggedIn) {
    res.send({
      user: user
    })
  } else {
    res.status(401).end()
  }
})

// Returns all the reviews for a movie given its ID
app.get('/api/reviews/:movieID', async (req, res) => {
  // Search for movie in database
  let pool = await sql.connect(sqlConfig)
  let reviews = await pool.request()
    .input('MovieID', sql.Int, req.params.movieID)
    .execute('MovieDatabase.GetReviews')

  await res.send({
    reviews: reviews.recordset
  })
})

// Returns all the information about a movie given its ID
app.get('/api/movies/:movieID', async (req, res) => {
  // Search for movie in database
  let pool = await sql.connect(sqlConfig)
  let movie = await pool.request()
    .input('MovieID', sql.Int, req.params.movieID)
    .execute('MovieDatabase.GetMovieData')

  await res.send({
    movie: movie.recordset
  })
})

app.all('/movies', async (req, res) => {
  await sql.connect(sqlConfig)
  const result = await sql.query`SELECT * FROM MovieDatabase.Movies WHERE VerifiedOn IS NOT NULL`
  await res.send(result.recordsets[0])
})

app.all('/watchlist/get', async (req, res) => {
  let pool = await sql.connect(sqlConfig)
  let result = await pool.request()
    .input('UserID', sql.Int, req.body.userId)
    .execute('MovieDatabase.GetWatchlist')
  await res.send(result.recordsets[0])
})

app.all('/watchlist/add', async (req, res) => {
  let user = await getUser(req)

  if (user.loggedIn) {
    let pool = await sql.connect(sqlConfig)
    let result = await pool.request()
      .input('UserID', sql.Int, user.id)
      .input('MovieID', sql.Int, req.body.movieId)
      .execute('MovieDatabase.CreateWatchlist')
    res.status(200).end()
  } else {
    res.status(401).end()
  }
})

app.all('/watchlist/update', async (req, res) => {
  let user = await getUser(req)

  if (user.loggedIn) {
    console.log(req.body)
    if (req.body.watched) {
      let pool = await sql.connect(sqlConfig)
      let result = await pool.request()
        .input('WatchListID', sql.Int, req.body.watchlistId)
        .input('WatchedOn', sql.DateTimeOffset, new Date())
        .execute('MovieDatabase.UpdateWatchlist')
      res.status(200).end()
    } else {
      let pool = await sql.connect(sqlConfig)
      let result = await pool.request()
        .input('WatchListID', sql.Int, req.body.watchlistId)
        .input('WatchedOn', sql.DateTimeOffset, null)
        .execute('MovieDatabase.UpdateWatchlist')
      res.status(200).end()
    }
  } else {
    res.status(401).end()
  }
})

app.all('/watchlist/remove', async (req, res) => {
  let user = await getUser(req)

  if (user.loggedIn) {
    console.log(req.body)
    let pool = await sql.connect(sqlConfig)
    let result = await pool.request()
      .input('WatchListID', sql.Int, req.body.watchlistId)
      .execute('MovieDatabase.DeleteWatchlist')
    res.status(200).end()
  } else {
    res.status(401).end()
  }
})

app.all('/search/', async (req, res) => {
  let pool = await sql.connect(sqlConfig)
  let result = await pool.request()
    .input('Title', sql.NVarChar(128), req.body.title)
    .input('SortOrder', sql.NVarChar(64), req.body.sortDir)
    .input('SortBy', sql.NVarChar(64), req.body.sortBy)
    .input('GenreID', sql.Int, req.body.genre)
    .input('Page', sql.Int, req.body.page)
    .execute('MovieDatabase.SearchForMovie')
  await res.send(result.recordsets[0])
})

app.all('/getgenres/', async (req, res) => {
  let pool = await sql.connect(sqlConfig)
  let result = await pool.request()
    .execute('MovieDatabase.GetGenres')
  await res.send(result.recordsets[0])
})

module.exports = app
