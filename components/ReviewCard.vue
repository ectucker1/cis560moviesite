<template>
  <b-col class="mb-2">
    <b-card :title="username" footer-tag="footer">
      <b-card-text>{{ content }}</b-card-text>
      <b-form-rating v-model="rating" no-border readonly size="md" inline></b-form-rating>
      <template #footer>
        <h6 class="mb-0">Posted {{ date }}</h6>
      </template>
    </b-card>
  </b-col>
</template>

<script>
export default {
  name: 'ReviewCard',
  props: ['username', 'content', 'rating', 'date']
}
</script>
