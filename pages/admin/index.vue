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
        <h1 class="pt-5 pl-5">Other Admin Links</h1>
        <b-link href="/admin/topreviewers" class="pl-5">Top Reviewers</b-link>
        <br>
        <b-link href="/admin/mostwatchlisted" class="pl-5">Most Watchlisted</b-link>
      </div>
    </b-container>
    <b-alert v-model="showApproveMessage" variant="success" dismissible class="mt-4">
      You have successfully approved a movie in queue!
    </b-alert>
    <b-alert v-model="showDeleteMessage" variant="success" dismissible class="mt-4">
      You have successfully deleted a movie from the queue!
    </b-alert>
  </div>
</template>

<script>

export default {
  data() {
    return {
      showApproveMessage: false,
      showDeleteMessage: false,
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
      movies: [],
    }
  },
  async fetch() {
    let unverified = await this.$axios.get('/server-middleware/api/movies/unverified/get')
    this.movies = unverified.data
  },
  methods: {
    async approveMovie(id) {
      try {
        await this.$axios.$post('/server-middleware/api/movies/unverified/verify/', {
          id: id,
        })
        this.showApproveMessage = true
        window.location.reload()
      } catch (e) {
        console.log(e)
      }
    },

    async denyMovie(id) {
      try {
        await this.$axios.$post('/server-middleware/api/movies/unverified/deny/', {
          id: id,
        })
        this.showDeleteMessage = true
        window.location.reload()
      } catch (e) {
        console.log(e)
      }
    }
  },
  name: 'AdminPage'
}
</script>
