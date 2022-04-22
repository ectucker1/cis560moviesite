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
          <h1>Write a Review</h1>
          <p>Your review will and rating will be publicly visible.</p>
          <b-form-rating v-model="user.rating" no-border size="lg" class="bg-light"></b-form-rating>
          <b-form-textarea
            id="user-review"
            placeholder="Your review here"
            v-model="user.review"
            rows="10"
          />
          <b-button variant="primary" size="sm" class="mr-1 mt-2">
            Share Review
          </b-button>
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
      // movie: {
      //   title: 'Test Movie',
      //   id: this.$route.params.id,
      //   genre: 'Action',
      //   releaseDate: 2000,
      //   length: 120,
      //   rating: 4,
      //   imageUrl: '/nocover.jpg'
      // },
      user: {
        rating: null,
        review: null
      },
     reviews: [],
      // reviews: [
      //   { rating: 4, author: "Test User A", content: "It's pretty good I guess.", date: '1/2/2022' },
      //   { rating: 2, author: "Test User B", content: "It's not very good.", date: '1/3/2022' },
      //   { rating: 3, author: "Test User C", content: "Lorem ipsum.", date: '1/7/2022' },
      //   { rating: 5, author: "Test User D", content: "I haven't watched it.", date: '2/2/2022' },
      //   { rating: 1, author: "Test User E", content: "Yes.", date: '1/8/2022' }
      // ]
    }
  },
  async fetch() {
    let movieData = await this.$axios.get('/server-middleware/api/movies/' + this.$route.params.id)
    this.movie = await movieData.data["movie"][0]

    let reviewData = await this.$axios.get('/server-middleware/api/reviews/' + this.$route.params.id)
    this.reviews = await reviewData.data["reviews"]
    console.log(this.movie)
  }
}
</script>
