<template>
  <div>
    <Navbar/>

    <b-container>
      <div class="bg-light mb-5 rounded">
        <h1 class="p-5">Most Watchlisted Films</h1>
        <b-table striped hover :items="reviewers" :fields="fields"></b-table>
      </div>
    </b-container>
  </div>
</template>

<script>
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
          key: 'TimesWatchlisted',
          label: 'Watchlists',
          sortable: true
        },
        {
          key: 'WatchlistedRank',
          label: 'Rank',
          sortable: true
        },
      ],
      reviewers: [],
    }
  },
  async fetch() {
    let reviewers = await this.$axios.get('/server-middleware/mostwatchlisted')
    this.reviewers = reviewers.data
  },
  name: 'MostWatchlistedPage'
}
</script>
