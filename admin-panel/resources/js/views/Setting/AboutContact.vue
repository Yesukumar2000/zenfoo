<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>About Us &amp; Contact Us</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item">
                                    <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                                </li>
                                <li class="breadcrumb-item active" aria-current="page">About Us &amp; Contact Us</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <section class="section">
                <form @submit.prevent="saveRecord">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="card-title">About Us</h4>
                        </div>
                        <div class="card-body">
                            <div class="form-group">
                                <label>About Us Content</label>
                                <editor
                                    placeholder="Enter About Us content."
                                    v-model="content.about_us"
                                    :init="{
                                        height: 400,
                                        plugins: this.$editorPlugins,
                                        toolbar: this.$editorToolbar,
                                        font_size_formats: this.$editorFont_size_formats,
                                    }"
                                />
                            </div>
                        </div>
                    </div>

                    <div class="card mt-3">
                        <div class="card-header">
                            <h4 class="card-title">Contact Us</h4>
                        </div>
                        <div class="card-body">
                            <div class="form-group">
                                <label>Contact Us Content</label>
                                <editor
                                    placeholder="Enter Contact Us content."
                                    v-model="content.contact_us"
                                    :init="{
                                        height: 400,
                                        plugins: this.$editorPlugins,
                                        toolbar: this.$editorToolbar,
                                        font_size_formats: this.$editorFont_size_formats,
                                    }"
                                />
                            </div>
                        </div>
                        <div class="card-footer">
                            <b-button type="submit" variant="primary" :disabled="isLoading">
                                {{ __('update') }}
                                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                            </b-button>
                        </div>
                    </div>
                </form>
            </section>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import Editor from "@tinymce/tinymce-vue";

export default {
    components: { editor: Editor },
    data() {
        return {
            isLoading: false,
            content: {
                about_us: "",
                contact_us: "",
            },
        };
    },
    created() {
        this.getContent();
    },
    methods: {
        getContent() {
            axios.get(this.$apiUrl + "/about_contact").then((response) => {
                if (response.data.data) {
                    response.data.data.forEach((item) => {
                        this.content[item.variable] = item.value;
                    });
                }
            });
        },
        saveRecord() {
            this.isLoading = true;
            axios
                .post(this.$apiUrl + "/about_contact/save", this.content)
                .then((res) => {
                    const data = res.data;
                    if (data.status === 1) {
                        this.showMessage("success", data.message);
                    } else {
                        this.showError(data.message);
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.showError(error.message || "Something went wrong!");
                    this.isLoading = false;
                });
        },
    },
};
</script>
