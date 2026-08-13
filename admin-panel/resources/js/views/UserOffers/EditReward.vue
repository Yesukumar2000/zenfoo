<template>
  <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" size="md" scrollable no-close-on-backdrop no-fade static>
    <div slot="modal-footer">
      <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">
        Save
        <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
      </b-button>
      <b-button variant="secondary" @click="hideModal">Cancel</b-button>
    </div>
    <form ref="my-form" @submit.prevent="saveRecord">

      <div class="row">
        <label><span class="text-danger text-xs">*</span> Required fields</label>
        <div class="divider mt-0"><div class="divider-text">Order Reward Details</div></div>

        <div class="form-group col-md-6">
          <label>Order Count<i class="text-danger">*</i></label>
          <input type="number" class="form-control" v-model="order_count" placeholder="e.g., 5" min="1" required />
          <small class="text-muted">Number of orders required</small>
        </div>

        <div class="form-group col-md-6">
          <label>Reward Amount (Rs)<i class="text-danger">*</i></label>
          <input type="number" step="0.01" class="form-control" v-model="amount" placeholder="e.g., 100" min="0" required />
          <small class="text-muted">Amount to reward</small>
        </div>

        <!-- <div class="form-group col-md-12" v-if="id">
          <label>Status<i class="text-danger">*</i></label>
          <div class="col-md-9 text-left mt-1">
            <b-form-radio-group
              v-model="status"
              :options="[
                { text: 'Inactive', 'value': 0 },
                { text: 'Active', 'value': 1 },
              ]"
              buttons
              button-variant="outline-primary"
              required
            ></b-form-radio-group>
          </div>
        </div> -->
      </div>

      <button ref="dummy_submit" style="display:none;"></button>
    </form>
  </b-modal>
</template>

<script>
import axios from "axios";

export default {
  props: ["record"],
  data: function () {
    return {
      isLoading: false,
      id: this.record ? this.record.id : "",
      order_count: this.record ? this.record.order_count : "",
      amount: this.record ? this.record.amount : "",
      status: this.record ? (this.record.status ? 1 : 0) : 1,
    };
  },
  computed: {
    modal_title: function () {
      let title = this.id ? "Edit" : "Add";
      title += " Order Reward";
      return title;
    },
  },
  methods: {
    showModal() {
      this.$refs["my-modal"].show();
    },
    hideModal() {
      this.$refs["my-modal"].hide();
    },
    saveRecord: function () {
      let vm = this;
      this.isLoading = true;

      let postData = {
        order_count: this.order_count,
        amount: this.amount,
        status: this.status,
      };

      let url = this.$apiUrl + "/user_offers/order_rewards/save";
      if (this.id) {
        postData.id = this.id;
        url = this.$apiUrl + "/user_offers/order_rewards/update";
      }

      axios.post(url, postData)
        .then((res) => {
          let data = res.data;

          if (data.status === 1) {
            this.$eventBus.$emit("OrderRewardSaved", data.message);
            this.hideModal();
          } else {
            vm.showError(data.message);
            vm.isLoading = false;
          }
        }).catch((error) => {
          vm.isLoading = false;
          if (error.request && error.request.statusText) {
            this.showError(error.request.statusText);
          } else if (error.message) {
            this.showError(error.message);
          } else {
            this.showError("Something went wrong");
          }
        });
    },
  },
  mounted() {
    this.showModal();
  },
};
</script>
