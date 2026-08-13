<template>
    <b-modal
        :visible="visible"
        title="Bulk Product Upload"
        size="lg"
        hide-footer
        @hidden="onHidden"
    >
        <!-- Step 1: Download Template -->
        <div class="mb-4">
            <h6 class="fw-bold">Step 1 — Download Template</h6>
            <p class="text-muted small mb-2">
                Download the pre-filled template for this seller, fill it in, then upload below.
            </p>
            <button
                class="btn btn-info"
                :disabled="isDownloading"
                @click="downloadTemplate"
            >
                <b-spinner v-if="isDownloading" small></b-spinner>
                <i v-else class="fa fa-download"></i>
                {{ isDownloading ? 'Downloading...' : 'Download Template' }}
            </button>
        </div>

        <hr />

        <!-- Step 2: Upload Excel -->
        <div>
            <h6 class="fw-bold">Step 2 — Upload Filled Excel Sheet</h6>

            <!-- Row-level errors table -->
            <div v-if="rowErrors.length" class="alert alert-danger mb-3" ref="errorsAlert">
                <p class="mb-2 fw-bold">
                    <i class="fa fa-exclamation-triangle"></i>
                    Fix the following errors in your Excel sheet and re-upload:
                </p>
                <div class="table-responsive">
                    <table class="table table-sm table-bordered mb-0">
                        <thead>
                            <tr>
                                <th class="text-white" style="width: 80px;">Row #</th>
                                <th class="text-white" style="width: 180px;">Product</th>
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

            <!-- Upload form -->
            <form @submit.prevent="uploadFile" enctype="multipart/form-data">
                <div class="row align-items-end">
                    <div class="col-md-7">
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
                    <div class="col-md-5 mt-3 mt-md-0 d-flex gap-2">
                        <button
                            type="submit"
                            class="btn btn-primary"
                            :disabled="!selectedFile || isUploading"
                        >
                            <b-spinner v-if="isUploading" small></b-spinner>
                            <i v-else class="fa fa-upload"></i>
                            {{ isUploading ? 'Uploading...' : 'Upload' }}
                        </button>
                        <button type="button" class="btn btn-secondary" @click="clearFile">
                            <i class="fa fa-undo"></i> Clear
                        </button>
                    </div>
                </div>
            </form>

            <!-- Instructions -->
            <div class="alert alert-info mt-3 mb-0">
                <ul class="mb-0 small">
                    <li>Download the template above before filling data.</li>
                    <li>Each row represents <strong>one product</strong> — fill in all required (*) fields for every row.</li>
                    <li>Use the dropdowns in the template — do not type custom values in dropdown columns.</li>
                    <li>After upload, errors will appear above — fix the sheet and re-upload.</li>
                </ul>
            </div>
        </div>
    </b-modal>
</template>

<script>
import axios from "axios";

export default {
    name: "SellerBulkUploadModal",
    props: {
        visible: {
            type: Boolean,
            default: false,
        },
        sellerId: {
            type: [String, Number],
            required: true,
        },
    },
    data() {
        return {
            isDownloading: false,
            isUploading: false,
            selectedFile: null,
            rowErrors: [],
        };
    },
    methods: {
        downloadTemplate() {
            this.isDownloading = true;
            axios({
                url: this.$apiUrl + "/admin/bulk-upload/template",
                method: "GET",
                params: { seller_id: this.sellerId },
                responseType: "blob",
            })
                .then((res) => {
                    const filename = `bulk_upload_template_seller_${this.sellerId}.xlsx`;
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
            if (!this.selectedFile) return;

            this.isUploading = true;
            this.rowErrors = [];

            const formData = new FormData();
            formData.append("seller_id", this.sellerId);
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
                        this.$emit("uploaded");
                        this.$emit("update:visible", false);
                    } else {
                        this.showError(data.message || "Validation failed. Fix the errors below.");
                        this.rowErrors = Array.isArray(data.errors) ? data.errors : [];
                        this.$nextTick(() => {
                            if (this.$refs.errorsAlert) {
                                this.$refs.errorsAlert.scrollIntoView({ behavior: "smooth", block: "start" });
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

        onHidden() {
            this.clearFile();
            this.$emit("update:visible", false);
        },
    },
};
</script>
