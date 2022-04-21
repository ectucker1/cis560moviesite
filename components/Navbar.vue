<template>
  <div>
    <b-navbar toggleable="lg" type="dark" variant="dark">
      <b-navbar-brand href="/">Movie Site</b-navbar-brand>

      <b-navbar-toggle target="nav-collapse"></b-navbar-toggle>

      <b-collapse id="nav-collapse" is-nav>
        <b-navbar-nav>
          <b-nav-item href="/">Search</b-nav-item>
          <b-nav-item v-if="loggedIn" href="/submit">Submit</b-nav-item>
          <b-nav-item v-if="loggedIn" :href="watchlistUrl">Watchlist</b-nav-item>
          <b-nav-item v-if="loggedIn && admin" href="/admin">Admin</b-nav-item>
        </b-navbar-nav>

        <!-- Right aligned nav items -->
        <b-navbar-nav class="ml-auto">
          <b-nav-item v-if="!loggedIn" href="/signup">Sign Up</b-nav-item>
          <b-nav-item v-if="!loggedIn" href="/login">Sign In</b-nav-item>
          <b-nav-item v-if="loggedIn">{{ displayName }}</b-nav-item>
          <b-nav-item v-if="loggedIn" @click="userSignout">Sign Out</b-nav-item>
        </b-navbar-nav>
      </b-collapse>
    </b-navbar>
  </div>
</template>

<script>
export default {
  name: 'Navbar',
  data() {
    return {
      loggedIn: this.$auth.loggedIn,
      watchlistUrl: '/watchlist/' + this.$auth.user?.id,
      admin: this.$auth.user?.admin,
      displayName: this.$auth.user?.name,
      signup: {
        email: '',
        username: '',
        password: ''
      },
    }
  },
  methods: {
    async userSignout() {
      await this.$auth.logout()
      window.location.reload()
    }
  }
}
</script>

