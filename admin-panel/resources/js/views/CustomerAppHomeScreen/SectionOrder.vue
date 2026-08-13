<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Section Order</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Section Order</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/customer-app-home-screen/sections" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>Section Order List</h4>
                        </div>
                        <div class="card-body">
                            <b-row>
                                <b-col md="6">
                                    <div class="mb-2 d-flex justify-content-between align-items-center">
                                        <div class="form-check form-switch">
                                            <label> <input type="checkbox" v-model="editable" class="form-check-input">
                                                Enable Drag and Drop</label>
                                        </div>
                                    </div>
                                </b-col>
                            </b-row>
                            <b-row>
                                <b-col md="6" style="overflow-y:scroll;height:600px;">
                                    <div v-if="list.length === 0 && !isLoading" class="alert alert-info">
                                        No sections available. Please add sections first.
                                    </div>
                                    <div v-else-if="isLoading" class="text-center">
                                        <b-spinner label="Loading..."></b-spinner>
                                    </div>
                                    <ul v-else id="sortable-row" class="list-group">
                                        <draggable class="list-group" tag="ul" v-model="list" v-bind="dragOptions" :move="onMove" animation="200"
                                                   @start="isDragging=true" @end="isDragging=false" @change="updateSectionOrder()">
                                            <li v-for="(item, index) in list" :key="item.id" class="list-group-item d-flex justify-content-between align-items-center">
                                                <span>
                                                    <span class="text-left mr-2">{{ index + 1 }}</span>
                                                    <span class="text-left mr-2">-</span>
                                                    <span class="text-left mr-2">ID: {{ item.id }}</span>
                                                    <span class="text-left mr-2">{{ item.name }}</span>
                                                </span>
                                                <span><i class="fas fa-arrows-alt"></i></span>
                                            </li>
                                        </draggable>
                                    </ul>
                                </b-col>
                            </b-row>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import draggable from 'vuedraggable';

export default {
    components: {
        draggable,
    },
    data() {
        return {
            list: [],
            editable: true,
            isDragging: false,
            onDragEnd: false,
            delayedDragging: false,
            isLoading: false,
        }
    },
    computed: {
        dragOptions() {
            return {
                animation: 0,
                group: "description",
                disabled: !this.editable,
                ghostClass: "ghost"
            };
        },
    },
    watch: {
        isDragging(newValue) {
            if (newValue) {
                this.delayedDragging = true;
                return;
            }
            this.$nextTick(() => {
                this.delayedDragging = false;
            });
        },
    },
    mounted() {
        this.getSections();
    },
    methods: {
        onMove({ relatedContext, draggedContext }) {
            const relatedElement = relatedContext.element;
            const draggedElement = draggedContext.element;
            return (
                (!relatedElement || !relatedElement.fixed) && !draggedElement.fixed
            );
        },
        updateList() {
            this.list.map((item, index) => {
                item.row_order = index + 1;
            });
        },
        getSections() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/products/customer-app-sections/row_order')
                .then((response) => {
                    this.isLoading = false;
                    let data = response.data;
                    this.list = data.data.map((item, index) => {
                        return {
                            id: item.id,
                            name: item.name,
                            row_order: item.order || index + 1,
                            fixed: false
                        };
                    });
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error("Failed to load sections", error);
                    this.showMessage('error', 'Failed to load sections');
                });
        },
        updateSectionOrder() {
            this.updateList();

            this.isLoading = true;
            let formData = {
                sections: this.list
            };
            let url = this.$apiUrl + '/products/customer-app-sections/updateOrder';
            axios.post(url, formData).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.showMessage("success", data.message);
                    this.isLoading = false;
                    this.getSections();
                } else {
                    this.showMessage('error', data.message);
                    this.isLoading = false;
                }
            }).catch(error => {
                this.isLoading = false;
                if (error.request && error.request.statusText) {
                    this.showMessage('error', error.request.statusText);
                } else if (error.message) {
                    this.showMessage('error', error.message);
                } else {
                    this.showMessage('error', 'Something went wrong');
                }
            });
        },
    }
};
</script>

<style scoped>
.flip-list-move {
    transition: transform 0.5s;
}

.no-move {
    transition: transform 0s;
}

.ghost {
    opacity: 0.5;
    background: #c8ebfb;
}

.list-group {
    min-height: 20px;
}

.list-group-item {
    cursor: move;
}

.list-group-item i {
    cursor: pointer;
}
</style>