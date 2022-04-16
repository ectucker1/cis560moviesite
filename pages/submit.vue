<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <b-form>
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
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'SubmitPage',
  data() {
    return {
      submission: {
        title: '',
        genre: 1,
        releaseDate: 2000,
        length: 120
      },
      genreOptions: [
        { value: 1, text: 'Action' },
        { value: 2, text: 'Adventure' },
        { value: 3, text: 'Drama' }
      ]
    }
  }
}
</script>
