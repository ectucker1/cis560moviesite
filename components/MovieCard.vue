<template>
  <b-col class="mb-2">
    <b-card no-body class="overflow-hidden" style="max-width: 540px;">
      <b-row no-gutters>
        <b-col md="6">
          <b-card-img :src="imageUrl" class="rounded-0"></b-card-img>
        </b-col>
        <b-col md="6">
          <b-card-body :title="title">
            <b-list-group flush>
              <b-list-group-item>{{ releaseDate }}</b-list-group-item>
              <b-list-group-item>{{ rating }}/5</b-list-group-item>
            </b-list-group>
            <b-button href="#" variant="primary" class="mb-2">Add to Watchlist</b-button>
            <b-button :href="movieUrl" variant="secondary" class="mb-2">Read Reviews</b-button>
          </b-card-body>
        </b-col>
      </b-row>
    </b-card>
  </b-col>
</template>

<script>
export default {
  name: 'MovieCard',
  props: ['title', 'releaseDate', 'rating', 'id','imageUrl'],
  data() {
    return {
      movieUrl: "/movies/" + this.id
    }
  }
}
</script>
