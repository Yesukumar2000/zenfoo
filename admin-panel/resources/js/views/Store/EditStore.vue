<template>
    <div>
        <!-- Page Heading with Breadcrumbs -->
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ storeId ? 'Edit Store' : 'Add Store' }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/manage_store">Manage Store</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                {{ storeId ? 'Edit' : 'Add' }}
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
        </div>

        <div class="row mb-3">
            <div class="col-12">
                <router-link to="/manage_store" class="btn btn-secondary btn-sm">
                    <i class="fa fa-arrow-left me-1"></i> Back to List
                </router-link>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <form @submit.prevent="saveStore">
                    <div class="card">
                        <div class="card-body">
                            <div class="row">
                                <div class="form-group col-md-6">
                                    <label>Store Name</label>
                                    <input
                                        v-model="name"
                                        class="form-control"
                                        required
                                    />
                                </div>

                               <div class="form-group col-md-6">
                                    <label>Store Description</label>
                                    <input
                                        v-model="description"
                                        class="form-control"
                                        required
                                    />
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Managed by Admin</label>
                                    <div class="form-check form-switch">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            v-model="managed_by_admin"
                                            true-value="1"
                                            false-value="0"
                                            id="managedByAdminToggle"
                                        />
                                        <label class="form-check-label" for="managedByAdminToggle">
                                            {{ managed_by_admin == 1 ? "Yes" : "No" }}
                                        </label>
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Is Meat Store</label>
                                    <div class="form-check form-switch">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            v-model="is_meat"
                                            true-value="1"
                                            false-value="0"
                                            id="isMeatToggle"
                                        />
                                        <label class="form-check-label" for="isMeatToggle">
                                            {{ is_meat == 1 ? "Yes" : "No" }}
                                        </label>
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Is Food</label>
                                    <div class="form-check form-switch">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            v-model="is_food"
                                            true-value="1"
                                            false-value="0"
                                            id="isFoodToggle"
                                        />
                                        <label class="form-check-label" for="isFoodToggle">
                                            {{ is_food == 1 ? "Yes" : "No" }}
                                        </label>
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Is Vegetable</label>
                                    <div class="form-check form-switch">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            v-model="is_vegetable"
                                            true-value="1"
                                            false-value="0"
                                            id="isVegetableToggle"
                                        />
                                        <label class="form-check-label" for="isVegetableToggle">
                                            {{ is_vegetable == 1 ? "Yes" : "No" }}
                                        </label>
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Is Super Mart</label>
                                    <div class="form-check form-switch">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            v-model="is_super_mart"
                                            true-value="1"
                                            false-value="0"
                                            id="isSuperMartToggle"
                                        />
                                        <label class="form-check-label" for="isSuperMartToggle">
                                            {{ is_super_mart == 1 ? "Yes" : "No" }}
                                        </label>
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Icon</label>
                                    <input
                                        type="file"
                                        @change="onIconChange"
                                        class="form-control"
                                    />
                                    <div
                                        v-if="iconPreview || iconUrl"
                                        class="mb-2"
                                    >
                                        <img
                                            :src="iconPreview || iconUrl"
                                            alt="icon"
                                            style="max-width: 48px"
                                        />
                                    </div>
                                </div>
                                <div class="form-group col-md-6">
                                    <label>Image</label>
                                    <input
                                        type="file"
                                        @change="onImageChange"
                                        class="form-control"
                                    />
                                    <div
                                        v-if="imagePreview || imageUrl"
                                        class="mb-2"
                                    >
                                        <img
                                            :src="imagePreview || imageUrl"
                                            alt="image"
                                            style="max-width: 110px"
                                        />
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Vendor Image</label>
                                    <input
                                        type="file"
                                        @change="onVendorImageChange"
                                        class="form-control"
                                    />
                                    <div v-if="vendorImagePreview || vendorImageUrl" class="mb-2">
                                        <img
                                            :src="vendorImagePreview || vendorImageUrl"
                                            alt="vendor image"
                                            style="max-width: 110px"
                                        />
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>Color Palette</label>
                                    <input
                                        type="color"
                                        class="form-control"
                                        v-model="color"
                                    />
                                </div>
                                <div class="form-group col-12">
                                    <label>Select Category Groups</label>
                                    <div
                                        v-for="group in categoryGroups"
                                        :key="group.id"
                                        class="form-check"
                                    >
                                        <input
                                            type="checkbox"
                                            class="form-check-input"
                                            :id="'group-' + group.id"
                                            :value="group.id"
                                            v-model="selectedGroups"
                                        />
                                        <label
                                            :for="'group-' + group.id"
                                            class="form-check-label"
                                            >{{ group.name }}</label
                                        >
                                    </div>
                                </div>
                                <div class="col-12">
                                    <button
                                        type="submit"
                                        class="btn btn-primary"
                                        style="margin-top: 10px"
                                    >
                                        Save Store
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    props: ["id"],
    data() {
        return {
            name: "",
            description: "",
            managed_by_admin: 0,
            is_meat: 0,
            is_food: 0,
            is_vegetable: 0,
            is_super_mart: 0,
            color: "#000000",
            icon: null,
            iconUrl: "", // For loaded preview (edit mode)
            iconPreview: "", // For new selection
            image: null,
            imageUrl: "", // For loaded preview (edit mode)
            imagePreview: "",
            selectedGroups: [],
            categoryGroups: [],

            vendorImage: null,
            vendorImageUrl: "",
            vendorImagePreview: "",

        };
    },
    created() {
        if (this.id) {
            this.fetchCategoryGroups().then(() => {
                this.fetchStore();
            });
        } else {
            this.fetchCategoryGroups();
        }
    },
    methods: {
        // Fires when an icon is selected via file input
        onIconChange(event) {
            this.icon = event.target.files[0] || null; // assign file or null
            this.iconPreview = this.icon ? URL.createObjectURL(this.icon) : "";
        },
        // Fires when an image is selected via file input
        onImageChange(event) {
            this.image = event.target.files[0] || null; // assign file or null
            this.imagePreview = this.image
                ? URL.createObjectURL(this.image)
                : "";
        },

        onVendorImageChange(event) {
            this.vendorImage = event.target.files[0] || null;
            this.vendorImagePreview = this.vendorImage
                ? URL.createObjectURL(this.vendorImage)
                : "";
        },

        // Load category groups for both add/edit
        fetchCategoryGroups() {
            return axios
                .get(`${this.$apiUrl}/group-category`)
                .then((res) => {
                    this.categoryGroups = res.data.data || [];
                })
                .catch(() =>
                    this.$swal.fire(
                        "Error",
                        "Failed to load category groups",
                        "error"
                    )
                );
        },
        // Load store for editing
        fetchStore() {
            axios
                .get(`${this.$apiUrl}/stores/${this.id}/edit`)
                .then((res) => {
                    // change here:
                    const payload = res.data.total || {};
                    const store = payload.store || {};
                    this.name = store.name || "";
                    this.description = store.description || "";
                    this.managed_by_admin = store.managed_by_admin ? "1" : "0";
                    this.is_meat = store.is_meat ? "1" : "0";
                    this.is_food = store.is_food ? "1" : "0";
                    this.is_vegetable = store.is_vegetable ? "1" : "0";
                    this.is_super_mart = store.is_super_mart ? "1" : "0";
                    this.color = store.color || "#000000";
                    this.iconUrl = store.icon_url || "";
                    this.imageUrl = store.image_url || "";
                    this.vendorImageUrl = store.vendor_img_url || "";
                    this.vendorImagePreview = "";
                    this.iconPreview = "";
                    this.imagePreview = "";
                    // Set selected group IDs
                    if (Array.isArray(store.category_groups)) {
                        this.selectedGroups = store.category_groups.map(
                            (g) => g.id
                        );
                    }
                })
                .catch(() =>
                    this.$swal.fire(
                        "Error",
                        "Failed to load store data",
                        "error"
                    )
                );
        },

        // Save or update store
        saveStore() {
            const formData = new FormData();
            if (this.id) formData.append("id", this.id);
            formData.append("name", this.name);
            formData.append("color", this.color);
            formData.append("description", this.description);
            formData.append("managed_by_admin", this.managed_by_admin);
            formData.append("is_meat", this.is_meat);
            formData.append("is_food", this.is_food);
            formData.append("is_vegetable", this.is_vegetable);
            formData.append("is_super_mart", this.is_super_mart);

            // Only send if changed/selected
            if (this.icon) formData.append("icon", this.icon);
            if (this.image) formData.append("image", this.image);
            if (this.vendorImage) formData.append("vendor_img", this.vendorImage);

            this.selectedGroups.forEach((id) =>
                formData.append("category_group_ids[]", id)
            );
            const url = this.id
                ? `${this.$apiUrl}/stores/update/${this.id}`
                : `${this.$apiUrl}/stores/save`;
            axios
                .post(url, formData)
                .then((res) => {
                    if (res.data.status === 1) {
                        this.$swal.fire("Success", res.data.message, "success");
                        this.$router.push({ path: "/manage_store" });
                    } else {
                        this.$swal.fire("Error", res.data.message, "error");
                    }
                })
                .catch((err) => {
                    const data = err.response?.data;
                    let errorMsg = data?.message || err.message;
                    if (data?.errors) {
                        const messages = Object.values(data.errors).flat();
                        errorMsg = messages.join('\n');
                    }
                    this.$swal.fire("Error", errorMsg, "error");
                });
        },
    },
};
</script>