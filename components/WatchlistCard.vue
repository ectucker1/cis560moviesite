<template>
  <b-list-group-item class="flex-column align-items-start">
    <div class="d-flex w-100 justify-content-between">
      <h5 class="mb-1">{{ title }}</h5>
      <small v-if="watchedOn != null" class="text-muted">{{ watchedOn }}</small>
    </div>

    <div class="mb-1">
      <b-button-group class="mt-2">
        <b-button @click="markWatched" v-if="watchedOn == null" variant="primary">Mark Watched</b-button>
        <b-button @click="unmarkWatched" v-if="watchedOn != null" variant="secondary">Unmark Watched</b-button>
        <b-button @click="remove" variant="danger">Delete</b-button>
      </b-button-group>
    </div>
  </b-list-group-item>
</template>

<script>
export default {
  name: 'WatchlistCard',
  props: ['title', 'id', 'watchedOn', 'watchlistId'],
  methods: {
    async markWatched() {
      await this.$axios.post("/server-middleware/watchlist/update", { watchlistId: this.watchlistId, watched: true })
      window.location.reload()
    },
    async unmarkWatched() {
      await this.$axios.post("/server-middleware/watchlist/update", { watchlistId: this.watchlistId, watched: false })
      window.location.reload()
    },
    async remove() {
      await this.$axios.post("/server-middleware/watchlist/remove", { watchlistId: this.watchlistId })
      window.location.reload()
    }
  }
}
</script>
