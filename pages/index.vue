<template>
  <div>
    <Navbar/>

    <b-container>
      <!--Search form-->
      <div class="bg-light p-5 mb-5 rounded">
        <b-form @submit.prevent="doSearch">
          <h1>Search for a Movie</h1>
          <p class="lead">Find exactly the thing to watch tonight.</p>
          <!--Title input-->
          <b-form-row class="pt-2">
            <b-col sm="2">
              <label class="col-form-label">Title</label>
            </b-col>
            <b-col sm="10">
              <b-input id="search-title" v-model="searchMovie.title" type="text"></b-input>
            </b-col>
          </b-form-row>
          <!--Genre input-->
          <b-form-row class="pt-2">
            <b-col sm="2">
              <label class="col-form-label">Genre</label>
            </b-col>
            <b-col sm="10">
              <b-form-select id="search-genre" v-model="searchMovie.genre" :options="genreOptions"></b-form-select>
            </b-col>
          </b-form-row>
          <!--Sort by input-->
          <b-form-row class="pt-2">
            <b-col sm="2">
              <label class="col-form-label">Sort By</label>
            </b-col>
            <b-col sm="10">
              <b-form-group>
                <b-form-radio v-model="searchMovie.sortBy" value="Year">Date</b-form-radio>
                <b-form-radio v-model="searchMovie.sortBy" value="Rating">Rating</b-form-radio>
              </b-form-group>
            </b-col>
          </b-form-row>
          <!--Sort type input-->
          <b-form-row class="pt-2">
            <b-col sm="2">
              <label class="col-form-label">Sort Order</label>
            </b-col>
            <b-col sm="10">
              <b-form-group>
                <b-form-radio v-model="searchMovie.sortDir" value="ASC">Ascending</b-form-radio>
                <b-form-radio v-model="searchMovie.sortDir" value="DESC">Descending</b-form-radio>
              </b-form-group>
            </b-col>
          </b-form-row>
          <!--Search button-->
          <b-form-row class="pt-4">
            <b-button type="submit" variant="primary">Search</b-button>
          </b-form-row>
        </b-form>
      </div>

      <b-row cols="1" cols-sm="1" cols-md="2" cols-lg="2" cols-xl="2">
        <MovieCard
          v-for="movie in movies"
          :key="movie.MovieID"
          :title="movie.Title"
          :release-date="movie.Year"
          :rating="movie.rating"
          :id="movie.MovieID"
          :image-url="movie.Poster"/>
      </b-row>
    </b-container>
  </div>
</template>

<script>
export default {
  data() {
    return {
      searchMovie: {
        title: '',
        genre: null,
        sortBy: 'Year',
        sortDir: 'ASC',
        page: 1
      },
      genreOptions: [
        { value: null, text: 'Any' },
        { value: 1, text: 'Action' },
        { value: 2, text: 'Adventure' },
        { value: 3, text: 'Drama' }
      ],

      movies: [],

      // movies: [
      //   { id: '0', title: 'Test Title', releaseDate: '2021', rating: '4', imageUrl: 'nocover.jpg'},
      //   { id: '1', title: 'Test Title 2', releaseDate: '2022', rating: '4', imageUrl: 'nocover.jpg'},
      //   { id: '2', title: 'Test Title 3', releaseDate: '2022', rating: '3', imageUrl: 'nocover.jpg'},
      //   { id: '3', title: 'Test Title 4', releaseDate: '2023', rating: '2', imageUrl: 'nocover.jpg'},
      //   { id: '4', title: 'Test Title 5', releaseDate: '2024', rating: '2', imageUrl: 'nocover.jpg'}
      // ]
    }
  },
  async fetch() {
    if (this.$route.query.title)
      this.searchMovie.title = this.$route.query.title
    if (this.$route.query.genre)
      this.searchMovie.genre = this.$route.query.genre
    if (this.$route.query.sortBy)
      this.searchMovie.sortBy = this.$route.query.sortBy
    if (this.$route.query.sortDir)
      this.searchMovie.sortDir = this.$route.query.sortDir
    if (this.$route.query.page)
      this.searchMovie.page = this.$route.query.page
    let response = await this.$axios.post('/server-middleware/search', this.searchMovie)
    this.movies = response.data
  },
  methods: {
    async doSearch() {
      await this.$router.push({ path: this.$route.path, query: this.searchMovie })
    }
  },
  watch: {
    '$route.query': '$fetch'
  },
  name: 'IndexPage'
}
</script>
