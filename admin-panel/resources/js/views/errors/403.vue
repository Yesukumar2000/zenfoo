<template>
    <div>
        <div id="error" class="py-0" style="height: 77vh;">
            <div class="error-page container">
                <div class="col-md-8 col-12 offset-md-2">
                    <div class="text-center">
                        <img :src="img_url" alt="Not Found" style="height: 200px;">
                        <h1 class="error-title mt-0">Forbidden</h1>
                        <p class="fs-5 text-gray-600">You are unauthorized to see this page.</p>
                        <button type="button" class="btn btn-lg btn-outline-primary mt-3" @click="$router.go(-1)">Go Back</button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
<script>
import router from "../../router/index";
import Auth from "../../Auth";

export default {
    data : function(){
        return {
            img_url: this.$baseUrl + '/images/error-403.png'
        };
    },
    created() {
        setTimeout(
            function() {
                if(!UserPermissions || !Auth.check()){
                    router.push("/login")
                }else{
                    router.push("/dashboard")
                }
            }, 2000);

    }
};
</script>
