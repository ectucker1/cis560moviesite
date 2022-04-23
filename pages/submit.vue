<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <b-form @submit.prevent="movieSubmission">
        <h1>Submit a New Movie</h1>
        <p class="lead">Make sure we always have your niche favorites.<br>An admin will review yor submission before it's displayed publically.</p>
        <!--Title input-->
        <b-form-group
          label="Title:"
          label-for="submission-title"
        >
          <b-form-input id="submission-title" v-model="submission.title" type="text" required/>
        </b-form-group>
        <!--Genre input-->
        <b-form-group
          label="Genre:"
          label-for="submission-genre"
        >
          <b-form-select id="submission-genre" v-model="submission.genre" :options="genreOptions"></b-form-select>
        </b-form-group>
        <!--Release date input-->
        <b-form-group
          label="Release Year:"
          label-for="submission-release-date"
        >
          <b-input id="submission-release-date" v-model="submission.releaseDate" type="number" required></b-input>
        </b-form-group>
        <!--Length input-->
        <b-form-group
          label="Runtime (minutes):"
          label-for="submission-length"
        >
            <b-input id="submission-length" v-model="submission.length" type="number" required></b-input>
        </b-form-group>
        <!--Submission button-->
        <b-form-row class="pt-4">
        <b-button type="submit" variant="primary">Submit</b-button>
        </b-form-row>
      </b-form>
      <b-alert v-model="showSuccess" variant="success" dismissible class="mt-4">
        You have successfully submitted a movie for approval!
      </b-alert>
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'SubmitPage',
  data() {
    return {
      showSuccess: false,
      submission: {
        title: '',
        genre: 1,
        releaseDate: 2000,
        length: 120
      },
      genreOptions: [
        { value: 1, text: 'Action' },
        { value: 2, text: 'Adult' },
        { value: 3, text: 'Adventure' },
        { value: 5, text: 'Animation' },
        { value: 6, text: 'Biography' },
        { value: 7, text: 'Comedy' },
        { value: 8, text: 'Crime' },
        { value: 9, text: 'Documentary' },
        { value: 10, text: 'Drama' },
        { value: 11, text: 'Family' },
        { value: 12, text: 'Fantasy' },
        { value: 13, text: 'Film-Noir' },
        { value: 14, text: 'Game-Show' },
        { value: 15, text: 'History' },
        { value: 16, text: 'Horror' },
        { value: 17, text: 'Music' },
        { value: 18, text: 'Musical' },
        { value: 19, text: 'Mystery' },
        { value: 20, text: 'News' },
        { value: 21, text: 'Reality-TV' },
        { value: 22, text: 'Romance' },
        { value: 23, text: 'Sci-FI' },
        { value: 24, text: 'Short' },
        { value: 25, text: 'Sport' },
        { value: 26, text: 'Talk-Show' },
        { value: 27, text: 'Thriller' },
        { value: 28, text: 'War' },
        { value: 29, text: 'Western' }
      ]
    }
  },
  methods: {
    async movieSubmission() {
      try {
        let submissionResponse = await this.$axios.$post('/server-middleware/api/movies/submit', { data: {
          title: this.submission.title,
          genre: this.submission.genre,
          releaseDate: this.submission.releaseDate,
          length: this.submission.length
        }})
        this.showSuccess = true
      } catch (error) {
        this.showError = true
      }
    }
  }
}
</script>
