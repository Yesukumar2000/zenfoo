<template>
    <div class="auth-split-container">
        <!-- Left Side - Logo Section -->
        <div class="auth-left-panel" :style="{ backgroundImage: 'url(public/assets/images/panel_login_background_img.jpg)' }">
            <div class="auth-logo-section">
                <a href="javascript:void(0)" class="logo-link">
                    <img v-if="$appLogo != ''" :src="$storageUrl+$appLogo" class="logo-img" alt='Logo'/>
                    <img v-else :src="$baseUrl + '/images/logo.png'" class="logo-img" alt='Logo'/>
                    <!-- <h2 class="logo-text">{{ $appName }}</h2> -->
                    <h2 class="logo-text">Zenfoo</h2>
                </a>
            </div>
        </div>

        <!-- Right Side - Form Section -->
        <div class="auth-right-panel">
            <div class="auth-form-wrapper">
                <h4>Welcome Back!</h4>
                <p class="auth-subtitle text-primary">Please login to your Account</p>
                <form @submit.prevent="loginCheck()">
                    <div class="form-group position-relative has-icon-left mb-4">
                        <input type="email" class="form-control form-control-xl" placeholder="Email Address" required
                               v-model="user.email">
                        <div class="form-control-icon">
                            <i class="bi bi-person"></i>
                        </div>
                    </div>
                    <div class="form-group position-relative has-icon-left">
                        <input :type="showPassword ? 'text' : 'password'" class="form-control form-control-xl" placeholder="Password" required
                               v-model="user.password">
                        <div class="form-control-icon">
                            <i class="bi bi-shield-lock"></i>
                        </div>

                        <button type="button" v-on:click="showPassword = !showPassword"
                                class="btn btn-sm btn-outline-light font-bold text-primary"
                                style="margin-top: -45px;position: absolute; right: 10px;" >
                            {{ showPassword ? 'Hide' : 'Show' }}

                        </button>

                    </div>
                    <!-- <div class="mb-4 text-end" style="margin-top: 35px;">
                        <router-link class="font-bold" to="/forgot-password"><span>Forgot Password?</span></router-link>
                    </div> -->

                    <button class="btn btn-primary btn-block btn-lg shadow-lg mt-5 auth-btn">
                        Login
                        <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                        <span v-else class="bi bi-arrow-right"></span>
                    </button>

                    <hr>
                    <!-- <router-link to="/seller/login" class="btn btn-primary btn-block btn-lg shadow-lg mt-2">
                        Seller Panel</router-link>
                    <router-link to="/delivery_boy/login" class="btn btn-primary btn-block btn-lg shadow-lg mt-2">
                        Delivery Boy Panel</router-link> -->


                </form>
                <div class="auth-copyright">
                    <a href="javascript:void(0)" class="text-primary font-weight-normal" v-html="copyrightDetails"></a>
                </div>
            </div>
        </div>
    </div>
</template>
<script>
import axios from 'axios';
import Auth from '../Auth.js';

export default {
    components: {
    },
    data: function () {
        return {
            isLoading: false,
            user: {
                email: (this.$isDemo === 1 || this.$isDemo === '1') ? 'admin@gmail.com' : '',
                password: (this.$isDemo === 1 || this.$isDemo === '1') ? '123456' : '',
                type:1
            },
            showPassword: false,
            loggedUser: Auth.user,
            setting:"",
            copyrightDetails: window.copyrightDetails,
        };
    },
  
    mounted() {
        if (this.loggedUser) {
            this.$router.push('/dashboard');
        }else{
            this.$router.push('/login').catch(()=>{});
        }
        let user_theme = sessionStorage.getItem("user-theme");
            this.userTheme = user_theme;
            document.body.className = user_theme;
    },
    methods: {

        loginCheck: function () {
            let vm = this;
            this.isLoading = true;

            let url = this.$apiUrl + '/login';
            axios.post(url, this.user).then(res => {
                vm.isLoading = false;
                let data = res.data;
                if (data.status === 1) {
                    Auth.login(data.data.access_token, data.data.user);

                    // Initialize FCM after successful login
                    if (window.initFCM) {
                        window.initFCM();
                    }

                    this.$router.push('/dashboard');

                } else {
                    vm.showError(data.message);
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }

            });
        }
    }
}
</script>
<style scoped>
.auth-split-container {
    display: flex;
    min-height: 100vh;
    width: 100%;
}

.auth-left-panel {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    position: relative;
}

.auth-left-panel::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.4);
}

.auth-logo-section {
    position: relative;
    z-index: 1;
    text-align: center;
}

.logo-link {
    display: flex;
    flex-direction: column;
    align-items: center;
    text-decoration: none;
    color: #fff;
}

.logo-img {
    height: 120px;
    width: 120px;
    margin-bottom: 20px;
}

.logo-text {
    color: #fff;
    font-size: 2rem;
    font-weight: 600;
    margin: 0;
}

.auth-right-panel {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #fff;
    padding: 40px;
}

.auth-form-wrapper {
    width: 100%;
    max-width: 400px;
}

.auth-form-wrapper h4 {
    margin-bottom: 10px;
}

.auth-copyright {
    margin-top: 30px;
    text-align: center;
}

/* Responsive design for smaller screens */
@media (max-width: 768px) {
    .auth-split-container {
        flex-direction: column;
    }

    .auth-left-panel {
        min-height: 200px;
        flex: none;
    }

    .logo-img {
        height: 80px;
        width: 80px;
    }

    .logo-text {
        font-size: 1.5rem;
    }

    .auth-right-panel {
        padding: 20px;
    }
}
</style>
