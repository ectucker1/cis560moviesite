<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <b-row>
        <b-col sm="12" lg="6">
          <b-img :src="movie.Poster" fluid-grow></b-img>
        </b-col>
        <b-col sm="12" lg="6">
          <h1>{{ movie.Title }}</h1>
          <h3 class="pb-2">{{ movie.StarRating }}/5</h3>
          <h3 class="pb-2">{{ movie.Year }}</h3>
          <h3 class="pb-2">{{ movie.Name }}</h3>
          <h3 class="pb-2">{{ movie.Length }} minutes</h3>
          <!--Prompt for user's review-->
          <div v-if="$auth.loggedIn">
            <h1>Write a Review</h1>
            <p>Your review will and rating will be publicly visible.</p>
            <b-form @submit.prevent="submitReview">
              <b-form-rating v-model="userReview.StarRating" no-border size="lg" class="bg-light"></b-form-rating>
              <b-form-textarea
                id="user-review"
                placeholder="Your review here"
                v-model="userReview.Text"
                rows="10"
              />
              <b-button type="submit" variant="primary" size="sm" class="mr-1 mt-2">
                Share Review
              </b-button>
            </b-form>
            <b-alert v-model="showPosted" variant="success" dismissible class="mt-4">
              Review posted!
            </b-alert>
            <b-alert v-model="showError" variant="danger" dismissible class="mt-4">
              Error posting review.
            </b-alert>
          </div>
        </b-col>
      </b-row>
      <h1 class="pt-5">Reviews for {{ movie.Title }}</h1>
      <div class="mt-3">
        <b-row cols="1" cols-sm="1" cols-md="2" cols-lg="2" cols-xl="2">
          <ReviewCard
            v-for="review in reviews"
            :key="review.ReviewID"
            :username="review.DisplayName"
            :content="review.Text"
            :rating="review.StarRating"
            :date="review.PostedOn"/>
        </b-row>
      </div>
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'MoviePage',
  data() {
    return {
      movie: {},
      userReview: {
        StarRating: null,
        Text: null
      },
      reviews: [],
      showPosted: false,
      showError: false
    }
  },
  async fetch() {
    let movieData = await this.$axios.get('/server-middleware/api/movies/' + this.$route.params.id)
    this.movie = await movieData.data["movie"][0]

    let reviewData = await this.$axios.get('/server-middleware/api/reviews/' + this.$route.params.id)
    this.reviews = await reviewData.data["reviews"]
    console.log(this.movie)

    try {
      let userReview = await this.$axios.get('/server-middleware/api/reviews/' + this.$route.params.id + '/me')
      if (userReview.data[0])
        this.userReview = userReview.data[0]
    } catch (err) {}
  },
  methods: {
    async submitReview() {
      try {
        console.log(this.userReview)
        let response = await this.$axios.post('/server-middleware/api/reviews/' + this.$route.params.id + '/post', this.userReview)
        this.showPosted = true
      } catch (err) {
        this.showError = true
      }
    }
  }
}
</script>
