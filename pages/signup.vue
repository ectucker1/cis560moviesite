<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <h1 class="h3 mb-3 fw-normal">Sign Up for Movie Site</h1>
      <b-form>
        <!--Email-->
        <b-form-group
          label="Email Address:"
          label-for="signup-email"
        >
          <b-form-input
            id="signup-email"
            v-model="signup.email"
            type="email"
            placeholder="Enter your email address"
            required
          />
        </b-form-group>
        <!--Username-->
        <b-form-group
          label="Display Name:"
          label-for="signup-username"
        >
          <b-form-input
            id="signup-username"
            v-model="signup.username"
            type="text"
            placeholder="Enter your name"
            required
          />
        </b-form-group>
        <!--Password-->
        <b-form-group
          label="Password:"
          label-for="signup-password"
        >
          <b-form-input
            id="signup-email"
            v-model="signup.password"
            type="password"
            placeholder="Enter a password"
            required
          />
        </b-form-group>

        <b-button type="submit" variant="primary">Sign Up</b-button>
      </b-form>
    </b-container>
  </div>
</template>

<script>
export default {
  name: 'SignupPage',
  data() {
    return {
      signup: {
        email: '',
        username: '',
        password: ''
      },
    }
  }
}
</script>
