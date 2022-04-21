<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <h1 class="h3 mb-3 fw-normal">Sign Up for Movie Site</h1>
      <b-form @submit.prevent="userSignup">
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

      <b-alert v-model="showError" variant="danger" dismissible class="mt-4">
        Invalid signup information. That email may be used by another account.
      </b-alert>
    </b-container>
  </div>
</template>

<script>
import { sha256 } from 'js-sha256';

export default {
  name: 'SignupPage',
  data() {
    return {
      signup: {
        email: '',
        username: '',
        password: ''
      },
      showError: false
    }
  },
  methods: {
    async userSignup() {
      try {
        let signupResponse = await this.$axios.$post('/server-middleware/auth/signup', {
          email: this.signup.email,
          displayName: this.signup.username,
          password: sha256(this.signup.password) // A good version of this would do salting, but we're not worrying about that
        })

        let loginResponse = await this.$auth.loginWith('local',{ data: {
          email: this.signup.email,
          password: sha256(this.signup.password)
        }})
        await this.$router.replace('/').catch(()=>{});
      } catch (err) {
        this.showError = true
      }
    }
  }
}
</script>
