<template>
  <div>
    <Navbar/>

    <b-container>
      <div class="bg-light rounded p-5">
        <h1>Your Watchlist</h1>
        <p class="lead">Keep track of your favorites.</p>
      </div>
      <b-row>
        <b-col sm="12" md="6" class="mt-4">
          <h2>To Watch</h2>
          <!--To watch list-->
          <b-list-group>
            <WatchlistCard
              v-for="movie in toWatch"
              :key="movie.MovieID"
              :title="movie.Title"
              :watchlistId="movie.WatchListID"
              :watched-on="movie.WatchedOn"/>
          </b-list-group>
        </b-col>
        <b-col sm="12" md="6" class="mt-4">
          <!--Watched list-->
          <h2>Watched</h2>
          <b-list-group>
            <WatchlistCard
              v-for="movie in watched"
              :key="movie.MovieID"
              :title="movie.Title"
              :watchlistId="movie.WatchListID"
              :watched-on="movie.WatchedOn"/>
          </b-list-group>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'Watchlist',
  data() {
    return {
      toWatch: [],
      watched: [],
    }
  },
  async fetch() {
    let watchlist = await this.$axios.post('/server-middleware/watchlist/get', { userId: this.$route.params.user })
    this.toWatch = watchlist.data.filter(movie => movie.WatchedOn == null)
    this.watched = watchlist.data.filter(movie => movie.WatchedOn != null)
  }
}
</script>
