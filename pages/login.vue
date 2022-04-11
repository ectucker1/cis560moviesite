<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <h1 class="h3 mb-3 fw-normal">Sign In to Movie Site</h1>
      <b-form>
        <!--Email-->
        <b-form-group
          label="Email Address:"
          label-for="login-email"
        >
          <b-form-input
            id="login-email"
            v-model="login.email"
            type="email"
            placeholder="Enter your account email address"
            required
          />
        </b-form-group>
        <!--Password-->
        <b-form-group
          label="Password:"
          label-for="login-password"
        >
          <b-form-input
            id="login-email"
            v-model="login.password"
            type="password"
            placeholder="Enter your account password"
            required
          />
        </b-form-group>

        <b-button type="submit" variant="primary">Sign In</b-button>
      </b-form>
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'LoginPage',
  data() {
    return {
      login: {
        email: '',
        password: ''
      },
    }
  }
}
</script>
