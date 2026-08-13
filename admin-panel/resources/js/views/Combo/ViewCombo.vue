<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>{{ combo.name }}</h3>
          <p class="text-muted mb-0">View Combo Details</p>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
              </li>
              <li class="breadcrumb-item">
                <router-link to="/manage_combos">{{ __('manage_combos') }}</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                {{ combo.name }}
              </li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <div class="mb-3">
      <router-link to="/manage_combos" class="btn btn-secondary btn-sm">
        <i class="fa fa-arrow-left me-1"></i> Back to List
      </router-link>
    </div>

    <!-- Combo Details Card -->
    <div class="card">
      <div class="card-header">
        <h4>Combo Information</h4>
      </div>
      <div class="card-body" v-if="combo">
        <div class="row mb-3">
          <div class="col-md-4 text-center">
            <img
              v-if="combo.image_url"
              :src="combo.image_url"
              alt="Combo Image"
              class="img-fluid rounded shadow-sm"
              style="max-height: 220px; object-fit: cover;"
            />
            <div v-else class="text-muted">No Image Available</div>
          </div>

          <div class="col-md-8">
            <h4 class="mb-2">{{ combo.name }}</h4>
            <p class="text-muted">{{ combo.description }}</p>

            <ul class="list-group list-group-flush">
              <li class="list-group-item">
                <strong>Price:</strong> ₹{{ combo.price }}
              </li>
              <li class="list-group-item">
                <strong>Type:</strong> {{ combo.type }}
              </li>
              <li class="list-group-item">
                <strong>Categories:</strong>
                <span v-if="combo.categories && combo.categories.length">
                  <span
                    v-for="cat in combo.categories"
                    :key="cat.id"
                    class="badge bg-primary me-1"
                  >
                    {{ cat.name }}
                  </span>
                </span>
                <span v-else class="text-muted">No categories</span>
              </li>
            </ul>
          </div>
        </div>

        <!-- Products Table -->
        <div v-if="combo.products && combo.products.length">
          <h5 class="mt-4">Included Products</h5>
          <table class="table table-striped table-bordered mt-2">
            <thead>
              <tr>
                <th>#</th>
                <th>Product Name</th>
                <th>Image</th>
                <th>Price</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(product, index) in combo.products" :key="product.id">
                <td>{{ index + 1 }}</td>
                <td>{{ product.name }}</td>
                <td>
                  <img
                    v-if="product.image_url"
                    :src="product.image_url"
                    height="50"
                    width="50"
                    class="rounded"
                  />
                </td>
                <td>₹{{ product.price }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-else class="text-muted mt-3">
          <i>No products added to this combo.</i>
        </div>
      </div>

      <div class="card-body" v-else>
        <div class="text-center">
          <b-spinner label="Loading..."></b-spinner>
          <p>Loading combo details...</p>
        </div>
      </div>
    </div>

    <!-- Back Button -->
    <div class="mt-3">
      <router-link to="/manage_combos" class="btn btn-secondary">
        <i class="fa fa-arrow-left"></i> Back to Combos
      </router-link>
    </div>
  </div>
</template>

<script>
export default {
  name: "ViewCombo",
  data() {
    return {
      combo: null,
      isLoading: false,
    };
  },
  created() {
    this.fetchCombo();
  },
  methods: {
    async fetchCombo() {
      const id = this.$route.params.id;
      if (!id) return;

      this.isLoading = true;
      try {
        const response = await axios.get(`${this.$apiUrl}/combos/${id}`);
        this.combo = response.data.data;
      } catch (error) {
        console.error("Error loading combo:", error);
        this.showMessage("error", "Failed to load combo details");
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<style scoped>
.table td,
.table th {
  vertical-align: middle;
}
</style>
