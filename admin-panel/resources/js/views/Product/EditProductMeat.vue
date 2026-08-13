<script>
import axios from "axios";
import EditProductBase from './EditProduct.vue';

export default {
    extends: EditProductBase,
    computed: {
        manageProductsPath() {
            return '/manage_meat_products';
        },
    },
    methods: {
        afterSaveRedirect() {
            this.$router.push({path: '/manage_meat_products'});
        },

        getStores() {
            this.isLoading = true;
            return axios.get(this.$apiUrl + '/get-all-stores-data')
                .then((response) => {
                    this.isLoading = false;
                    this.stores = response.data;

                    // Only show is_meat = 1 stores
                    this.storeOptions = `<option value="">--Select Meat Store--</option>`;
                    this.stores.forEach(store => {
                        if (store.is_meat == 1) {
                            this.storeOptions += `<option value="${store.id}">${store.name}</option>`;
                        }
                    });
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error("Store fetch error", error);
                });
        }
    }
};
</script>
