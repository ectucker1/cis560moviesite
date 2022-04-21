<template>
  <div>
    <Navbar/>

    <b-container class="bg-light rounded p-5">
      <h1 class="h3 mb-3 fw-normal">Sign In to Movie Site</h1>
      <b-form @submit.prevent="userLogin">
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

      <b-alert v-model="showError" variant="danger" dismissible class="mt-4">
        Invalid login information.
      </b-alert>
    </b-container>
  </div>
</template>

<script>
import {sha256} from "js-sha256";

export default {
  name: 'LoginPage',
  data() {
    return {
      login: {
        email: '',
        password: ''
      },
      showError: false
    }
  },
  methods: {
    async userLogin() {
      try {
        let loginResponse = await this.$auth.loginWith('local',{ data: {
          email: this.login.email,
          password: sha256(this.login.password)  // A good version of this would do salting, but we're not worrying about that
        }})
        await this.$router.replace('/').catch(()=>{});
      } catch (err) {
        this.showError = true
      }
    }
  }
}
</script>
