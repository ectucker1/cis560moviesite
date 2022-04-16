<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <b-row>
        <b-col sm="6">
          <b-img :src="movie.imageUrl" fluid-grow></b-img>
        </b-col>
        <b-col sm="6">
          <h1>{{ movie.title }}</h1>
          <p>{{ movie.rating }}/5</p>
          <p>{{ movie.releaseDate }}</p>
          <p>{{ movie.genre }}</p>
          <p>{{ movie.length }} minutes</p>
        </b-col>
      </b-row>
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'MoviePage',
  data() {
    return {
      movie: {
        title: 'Test Movie',
        id: this.$route.params.id,
        genre: 'Action',
        releaseDate: 2000,
        length: 120,
        rating: 4,
        imageUrl: '/nocover.jpg'
      },
      reviews: [
        {
            rating: 4,
            author: "Test User",
            content: "It's pretty good I guess"
        }
      ]
    }
  }
}
</script>
