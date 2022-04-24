<template>
  <div>
    <Navbar/>

    <b-container>
      <div class="bg-light mb-5 rounded">
        <h1 class="p-5">Top 50 Reviewers</h1>
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
          key: 'DisplayName',
          label: 'Title',
          sortable: false
        },
        {
          key: 'UserReviewCount',
          label: 'Review Count',
          sortable: true
        },
        {
          key: 'AverageRating',
          label: 'Average Rating',
          sortable: true
        }
      ],
      reviewers: [],
    }
  },
  async fetch() {
    let reviewers = await this.$axios.get('/server-middleware/topreviewers')
    this.reviewers = reviewers.data
  },
  name: 'TopReviewersPage'
}
</script>
