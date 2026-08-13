<template>
    <div>
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h5 class="mb-0"><i class="fa fa-tags me-2"></i>Manage Categories</h5>
            <button type="button" class="btn btn-primary" @click="refreshCurrentTab()">
                <i class="fa fa-refresh me-1"></i> Refresh
            </button>
        </div>

        <!-- Tabs -->
        <div class="card">
            <div class="card-header">
                <ul class="nav nav-pills">
                    <li class="nav-item">
                        <a
                            class="nav-link"
                            :class="{ active: activeTab === 'categoryGroups' }"
                            href="#"
                            @click.prevent="activeTab = 'categoryGroups'"
                        >
                            <i class="fa fa-layer-group me-1"></i> Category Groups
                        </a>
                    </li>
                    <li class="nav-item">
                        <a
                            class="nav-link"
                            :class="{ active: activeTab === 'subCategoryGroups' }"
                            href="#"
                            @click.prevent="activeTab = 'subCategoryGroups'"
                        >
                            <i class="fa fa-folder-open me-1"></i> Sub Category Groups
                        </a>
                    </li>
                    <li class="nav-item">
                        <a
                            class="nav-link"
                            :class="{ active: activeTab === 'categories' }"
                            href="#"
                            @click.prevent="activeTab = 'categories'"
                        >
                            <i class="fa fa-list me-1"></i> Categories
                        </a>
                    </li>
                </ul>
            </div>
            <div class="card-body">
                <SellerCategoryGroups
                    v-if="activeTab === 'categoryGroups'"
                    ref="categoryGroups"
                    :seller-id="sellerId"
                />
                <SellerSubCategoryGroups
                    v-if="activeTab === 'subCategoryGroups'"
                    ref="subCategoryGroups"
                    :seller-id="sellerId"
                />
                <SellerCategories
                    v-if="activeTab === 'categories'"
                    ref="categories"
                    :seller-id="sellerId"
                />
            </div>
        </div>
    </div>
</template>

<script>
import SellerCategoryGroups from './SellerCategoryGroups.vue';
import SellerSubCategoryGroups from './SellerSubCategoryGroups.vue';
import SellerCategories from './SellerCategories.vue';

export default {
    name: 'SellerManageCategoriesSupermart',
    components: {
        SellerCategoryGroups,
        SellerSubCategoryGroups,
        SellerCategories
    },
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            activeTab: 'categoryGroups'
        }
    },
    methods: {
        refreshCurrentTab() {
            if (this.activeTab === 'categoryGroups' && this.$refs.categoryGroups) {
                this.$refs.categoryGroups.getRecords();
            } else if (this.activeTab === 'subCategoryGroups' && this.$refs.subCategoryGroups) {
                this.$refs.subCategoryGroups.getRecords();
            } else if (this.$refs.categories) {
                this.$refs.categories.getRecords();
            }
        }
    }
};
</script>

<style scoped>
.card-header {
    background-color: #fff;
    border-bottom: 1px solid #dee2e6;
}

.nav-pills .nav-link {
    color: #6c757d;
    border-radius: 0;
    padding: 10px 20px;
}

.nav-pills .nav-link:hover {
    color: #495057;
    background-color: #f8f9fa;
}

.nav-pills .nav-link.active {
    color: #fff;
    background-color: #0d6efd;
}
</style>
