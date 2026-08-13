<template>
  <b-modal 
    visible
    title="Store Details"
    size="xl"
    @hide="$emit('close')"
    hide-footer
  >
    <div class="container-fluid">

      <!-- Header -->
      <div class="text-center mb-3">
        <img 
          :src="storeData.logo_url" 
          alt="Store Logo" 
          class="rounded mb-2"
          style="height: 100px;"
        />
        <h3>{{ storeData.store_name }}</h3>
        <p class="text-muted">{{ storeData.store_description }}</p>
      </div>

      <hr>

      <!-- Basic Info -->
      <div class="row mb-3">
        <div class="col-md-6">
          <h5>Basic Information</h5>
          <ul class="list-unstyled">
            <li><b>Name:</b> {{ storeData.name }}</li>
            <li><b>Email:</b> {{ storeData.email }}</li>
            <!-- <li><b>Store URL:</b> {{ storeData.store_url }}</li> -->
            <li><b>Location:</b> {{ storeData.store_location }}</li>
            <li><b>City:</b> {{ storeData.store_city }}</li>
            <!-- <li><b>Categories:</b> {{ storeData.categories_ids }}</li> -->
          </ul>
        </div>

        <div class="col-md-6">
          <h5>Additional Details</h5>
          <ul class="list-unstyled">
            <li><b>GST Business Name:</b> {{ storeData.tax_name }}</li>
            <li><b>GSTIN Number:</b> {{ storeData.tax_number }}</li>
            <li><b>PAN Number:</b> {{ storeData.pan_number }}</li>
            <!-- <li><b>Commission:</b> {{ storeData.commission }}</li> -->
            <li><b>Latitude / Longitude:</b> {{ storeData.lat_long }}</li>
            <li><b>Store ID:</b> {{ storeData.store_id }}</li>

            <li>
              <b>Status:</b>
              <span 
                v-if="storeData.is_approved == 1" 
                class="badge bg-success"
              >Approved</span>
              <span 
                v-else 
                class="badge bg-warning"
              >Pending</span>
            </li>
          </ul>
        </div>
      </div>

      <hr>

      <!-- PAN & FSSAI Images -->
      <div class="row mb-3">
        <div class="col-md-6">
          <h5>PAN Card</h5>
          <img 
            v-if="storeData.pan_img_url" 
            :src="storeData.pan_img_url" 
            class="img-fluid rounded shadow-sm"
          />
        </div>

        <div class="col-md-6">
          <h5>FSSAI Certificate</h5>
          <img 
            v-if="storeData.fssai_img_url" 
            :src="storeData.fssai_img_url" 
            class="img-fluid rounded shadow-sm"
          />
        </div>
      </div>

      <hr>

      <!-- Store Images -->
      <div>
        <h5>Store Images</h5>
        <div class="d-flex flex-wrap">
          <img
            v-for="(img, i) in storeData.store_images" 
            :key="i"
            :src="img"
            class="rounded shadow-sm m-2"
            style="height: 120px; width: auto;"
          />
        </div>
      </div>

      <hr>

      <!-- National ID Card -->
      <div class="mb-3">
        <h5>National ID Card</h5>
        <img 
          v-if="storeData.national_id_card"
          :src="storeData.national_id_card"
          class="img-fluid rounded shadow-sm"
          style="max-height: 200px"
        />
      </div>

      <hr>

      <!-- Address Proof -->
      <div class="mb-3">
        <h5>Address Proof</h5>
        <img 
          v-if="storeData.address_proof"
          :src="storeData.address_proof"
          class="img-fluid rounded shadow-sm"
          style="max-height: 200px"
        />
      </div>

    </div>
  </b-modal>
</template>

<script>
export default {
  props: ["storeData"]
}
</script>

<style scoped>
img {
  object-fit: cover;
}
</style>
