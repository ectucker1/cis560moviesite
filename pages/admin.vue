<template>
  <div>
    <Navbar/>

    <b-container>
      <div class="bg-light mb-5 rounded">
        <h1 class="p-5">Admin Moderation Queue</h1>
        <b-table striped hover :items="movies" :fields="fields">
          <template #cell(actions)="row">
            <b-button @click="approveMovie(row.item.MovieID)" variant="primary" size="sm" class="mr-1">
              Approve
            </b-button>
            <b-button @click="denyMovie(row.item.MovieID)" size="sm" class="mr-1">
              Delete
            </b-button>
          </template>
        </b-table>
      </div>
    </b-container>
  </div>
</template>

<script>
import {sha256} from "js-sha256";

export default {
  data() {
    return {
      fields: [
        {
          key: 'Title',
          label: 'Title',
          sortable: false
        },
        {
          key: 'Year',
          label: 'Year',
          sortable: true
        },
        {
          key: 'Name',
          label: 'Genre',
          sortable: true
        },
        {
          key: 'Length',
          label: 'Runtime'
        },
        {
          key: 'actions',
          label: 'Actions'
        }
      ],
      // movies: [
      //   { id: '0', title: 'Test Title', releaseDate: '2021', genre: 'Action', length: 120 },
      //   { id: '1', title: 'Test Title 2', releaseDate: '2022', genre: 'Drama', length: 130 },
      //   { id: '2', title: 'Test Title 3', releaseDate: '2022', genre: 'Adventure', length: 125 },
      //   { id: '3', title: 'Test Title 4', releaseDate: '2023', genre: 'Adventure', length: 121 },
      //   { id: '4', title: 'Test Title 5', releaseDate: '2024', genre: 'Drama', length: 164 }
      // ]
      movies: [],
    }
  },
  async fetch() {
    let unverified = await this.$axios.get('/server-middleware/api/movies/unverified/get')
    this.movies = unverified.data
    await console.log(this.movies)
  },
  methods: {
    async approveMovie(id) {
      let verifyResponse = await this.$axios.$post('/server-middleware/api/movies/unverified/verify/', {
        id: id,
      })
    },

    async denyMovie(id) {
      let denyResponse = await this.$axios.$post('/server-middleware/api/movies/unverified/deny/', {
        id: id,
      })
    }
  },
  name: 'AdminPage'
}
</script>
