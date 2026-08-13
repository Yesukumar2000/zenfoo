<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Seller Bulk Product Upload</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Seller Bulk Upload
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <!-- Step 1: Select Seller -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>Step 1 — Select Seller</h4>
                        </div>
                        <div class="card-body">
                            <div class="row align-items-end">
                                <div class="col-md-6">
                                    <div class="form-group mb-0">
                                        <label>Seller <span class="text-danger">*</span></label>
                                        <select v-model="selectedSellerId" class="form-control" @change="onSellerChange">
                                            <option value="">-- Select a Seller --</option>
                                            <option v-for="s in sellers" :key="s.id" :value="s.id">
                                                {{ s.name }}
                                            </option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-4 mt-3 mt-md-0">
                                    <button
                                        class="btn btn-info"
                                        :disabled="!selectedSellerId || isDownloading"
                                        @click="downloadTemplate"
                                    >
                                        <b-spinner v-if="isDownloading" small label="Spinning"></b-spinner>
                                        <i v-else class="fa fa-download"></i>
                                        {{ isDownloading ? 'Downloading...' : 'Download Template' }}
                                    </button>
                                </div>
                            </div>
                            <div class="mt-2" v-if="selectedSellerId">
                                <small class="text-muted">
                                    Template will be pre-filled with the categories and food types assigned to this seller.
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Step 2: Upload Excel -->
            <div class="row mt-3" v-if="selectedSellerId">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>Step 2 — Upload Filled Excel Sheet</h4>
                        </div>
                        <div class="card-body">

                            <!-- Validation errors table -->
                            <div class="row mb-3" v-if="rowErrors.length">
                                <div class="col-12">
                                    <div class="alert alert-danger" ref="rowErrorsAlert">
                                        <p class="mb-2 fw-bold">
                                            <i class="fa fa-exclamation-triangle"></i>
                                            Please fix the following issues in your Excel sheet and re-upload:
                                        </p>
                                        <div class="table-responsive">
                                            <table class="table table-sm table-bordered mb-0">
                                                <thead>
                                                    <tr>
                                                        <th style="width:80px;" class="text-white">Row #</th>
                                                        <th style="width:180px;" class="text-white">Product</th>
                                                        <th class="text-white">Errors</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <tr v-for="(item, idx) in rowErrors" :key="idx">
                                                        <td class="text-white">{{ item.row }}</td>
                                                        <td class="text-white">{{ item.product || '—' }}</td>
                                                        <td class="text-white">{{ item.message }}</td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Upload form -->
                            <form @submit.prevent="uploadFile" enctype="multipart/form-data">
                                <div class="row align-items-end">
                                    <div class="col-md-6">
                                        <div class="form-group mb-0">
                                            <label>Excel File (.xlsx) <span class="text-danger">*</span></label>
                                            <input
                                                type="file"
                                                ref="fileInput"
                                                class="form-control"
                                                accept=".xlsx,.xls"
                                                @change="onFileChange"
                                                required
                                            />
                                        </div>
                                    </div>
                                    <div class="col-md-6 mt-3 mt-md-0 d-flex gap-2">
                                        <button
                                            type="submit"
                                            class="btn btn-primary"
                                            :disabled="!selectedFile || isUploading"
                                        >
                                            <b-spinner v-if="isUploading" small label="Spinning"></b-spinner>
                                            <i v-else class="fa fa-upload"></i>
                                            {{ isUploading ? 'Uploading...' : 'Upload' }}
                                        </button>
                                        <button
                                            type="button"
                                            class="btn btn-secondary"
                                            @click="clearFile"
                                        >
                                            <i class="fa fa-undo"></i> Clear
                                        </button>
                                    </div>
                                </div>
                            </form>

                            <!-- Instructions -->
                            <div class="alert alert-info mt-3 mb-0">
                                <ul class="mb-0">
                                    <li>Download the template for the selected seller before filling data.</li>
                                    <li>Each row represents <strong>one product</strong> — fill in all required (*) fields for every row.</li>
                                    <li>Use the dropdowns in the template — do not type custom values in dropdown columns.</li>
                                    <li>After upload, errors will appear above — fix the sheet and re-upload.</li>
                                </ul>
                            </div>

                        </div>
                    </div>
                </div>
            </div>

        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    data() {
        return {
            sellers: [],
            selectedSellerId: "",
            selectedFile: null,
            isDownloading: false,
            isUploading: false,
            rowErrors: [],
        };
    },

    created() {
        this.fetchSellers();
    },

    methods: {
        fetchSellers() {
            axios.get(this.$apiUrl + "/admin/bulk-upload/sellers-list")
                .then((res) => {
                    if (res.data.status === 1) {
                        this.sellers = res.data.data;
                    }
                })
                .catch(() => {
                    this.showError("Failed to load sellers list.");
                });
        },

        onSellerChange() {
            this.rowErrors = [];
            this.clearFile();
        },

        downloadTemplate() {
            if (!this.selectedSellerId) return;
            this.isDownloading = true;

            axios({
                url: this.$apiUrl + "/admin/bulk-upload/template",
                method: "GET",
                params: { seller_id: this.selectedSellerId },
                responseType: "blob",
            })
                .then((res) => {
                    const sellerName = (this.sellers.find(s => s.id == this.selectedSellerId)?.name || "seller")
                        .replace(/\s+/g, "_");
                    const filename = `bulk_upload_template_${sellerName}.xlsx`;
                    const url = window.URL.createObjectURL(new Blob([res.data]));
                    const link = document.createElement("a");
                    link.href = url;
                    link.setAttribute("download", filename);
                    document.body.appendChild(link);
                    link.click();
                    link.parentNode.removeChild(link);
                    this.isDownloading = false;
                })
                .catch(() => {
                    this.showError("Failed to download template.");
                    this.isDownloading = false;
                });
        },

        onFileChange(e) {
            this.selectedFile = e.target.files[0] || null;
            this.rowErrors = [];
        },

        clearFile() {
            this.selectedFile = null;
            this.rowErrors = [];
            if (this.$refs.fileInput) {
                this.$refs.fileInput.value = "";
            }
        },

        uploadFile() {
            if (!this.selectedFile || !this.selectedSellerId) return;

            this.isUploading = true;
            this.rowErrors = [];

            const formData = new FormData();
            formData.append("seller_id", this.selectedSellerId);
            formData.append("file", this.selectedFile);

            axios
                .post(this.$apiUrl + "/admin/bulk-upload/products", formData, {
                    headers: { "Content-Type": "multipart/form-data" },
                })
                .then((res) => {
                    const data = res.data;
                    if (data.status === 1) {
                        this.showMessage("success", data.message);
                        this.clearFile();
                    } else {
                        this.showError(data.message || "Validation failed. Please fix the errors below.");
                        this.rowErrors = Array.isArray(data.errors) ? data.errors : [];
                        this.$nextTick(() => {
                            if (this.$refs.rowErrorsAlert) {
                                this.$refs.rowErrorsAlert.scrollIntoView({ behavior: "smooth", block: "start" });
                            } else {
                                window.scrollTo({ top: 0, behavior: "smooth" });
                            }
                        });
                    }
                    this.isUploading = false;
                })
                .catch((err) => {
                    this.showError(err?.response?.data?.message || err.message || "Upload failed.");
                    this.isUploading = false;
                });
        },
    },
};
</script>
