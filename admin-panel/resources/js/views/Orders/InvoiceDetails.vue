<template>
    <div class="invoice-details">
        <!-- Print Button -->
        <div class="print-button-container no-print mb-3">
            <button @click="printInvoice" class="btn btn-primary me-2">
                <i class="fas fa-print me-2"></i> Print Invoice
            </button>
            <button @click="printDirect" class="btn btn-success" title="Direct print to thermal printer (no driver needed)">
                <i class="fas fa-usb me-2"></i> Direct Print (USB)
            </button>
            <button @click="printBluetooth" class="btn btn-info" :disabled="isBluetoothPrinting" title="Print via Bluetooth thermal printer">
                <template v-if="isBluetoothPrinting"><b-spinner small label="Printing..."></b-spinner></template>
                <i v-else class="fab fa-bluetooth-b me-2"></i> Bluetooth Print
            </button>
        </div>

        <div v-if="isLoading" class="text-center py-5">
            <b-spinner label="Loading..."></b-spinner>
            <p class="mt-2">Loading invoice details...</p>
        </div>

        <div v-else-if="invoiceData" class="invoice-container" id="printable-invoice">
            <!-- Invoice Header -->
            <div class="invoice-header">
                <div class="row">
                    <div class="col-6">
                        <h4>INVOICE</h4>
                        <p class="mb-0">Order {{ invoiceData.order.order_number || ('#' + invoiceData.order.order_id) }}</p>
                        <p class="mb-0">Date: {{ formatDateTime(invoiceData.order.created_at) }}</p>
                    </div>
                    <div class="col-6 text-end">
                        <p class="mb-0"><strong>Status:</strong> {{ invoiceData.order.status_name }}</p>
                        <p class="mb-0"><strong>Payment:</strong> {{ invoiceData.order.payment_method }}</p>
                    </div>
                </div>
            </div>

            <hr class="my-3">

            <!-- Customer & Delivery Info -->
            <div class="row mb-4">
                <div class="col-6">
                    <h6 class="section-title">CUSTOMER DETAILS</h6>
                    <p class="mb-0">{{ invoiceData.order.user_name || '-' }}</p>
                    <p class="mb-0">{{ invoiceData.order.mobile }}</p>
                    <p class="mb-0">{{ invoiceData.order.user_email || '-' }}</p>
                </div>
                <div class="col-6">
                    <h6 class="section-title">DELIVERY ADDRESS</h6>
                    <p class="mb-0">{{ invoiceData.order.order_address || '-' }}</p>
                    <p class="mb-0" v-if="invoiceData.order.delivery_boy_name">
                        <strong>Delivery Boy:</strong> {{ invoiceData.order.delivery_boy_name }}
                    </p>
                </div>
            </div>

            <hr class="my-3">

            <!-- Store-wise Items -->
            <div v-for="(store, storeIndex) in invoiceData.store_wise_items" :key="store.store_id" class="mb-4">
                <h6 class="section-title">{{ getStoreName(store) }}</h6>
                <table class="table table-bordered table-sm">
                    <thead>
                        <tr>
                            <th width="50">#</th>
                            <th>Item</th>
                            <th width="80" class="text-center">Qty</th>
                            <th width="100" class="text-end">Price</th>
                            <th width="100" class="text-end">Total</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="(item, itemIndex) in store.items" :key="item.id">
                            <td>{{ itemIndex + 1 }}</td>
                            <td>
                                {{ item.product_name }}
                                <span v-if="item.variant_measurement" class="text-muted">
                                    ({{ item.variant_measurement }})
                                </span>
                            </td>
                            <td class="text-center">{{ item.quantity }}</td>
                            <td class="text-end">{{ $currency }}{{ item.price }}</td>
                            <td class="text-end">{{ $currency }}{{ item.sub_total }}</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr>
                            <td colspan="4" class="text-end"><strong>Store Subtotal:</strong></td>
                            <td class="text-end"><strong>{{ $currency }}{{ calculateStoreTotal(store.items) }}</strong></td>
                        </tr>
                    </tfoot>
                </table>
            </div>

            <!-- Combo Items -->
            <div v-if="invoiceData.combo_items && invoiceData.combo_items.length > 0" class="mb-4">
                <h6 class="section-title">COMBO ITEMS</h6>
                <div v-for="(combo, comboIndex) in invoiceData.combo_items" :key="combo.id" class="mb-3">
                    <p class="mb-1"><strong>{{ combo.combo_name || 'Combo Pack' }}</strong> (Qty: {{ combo.combo_quantity || 1 }}) - {{ $currency }}{{ combo.sub_total }}</p>
                    <table class="table table-bordered table-sm">
                        <thead>
                            <tr>
                                <th width="50">#</th>
                                <th>Item</th>
                                <th width="80" class="text-center">Qty</th>
                                <th width="100" class="text-end">Price</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(product, pIndex) in combo.products" :key="pIndex">
                                <td>{{ pIndex + 1 }}</td>
                                <td>{{ product.product_name }}</td>
                                <td class="text-center">{{ product.quantity }}</td>
                                <td class="text-end">{{ $currency }}{{ product.price }}</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>

            <hr class="my-3">

            <!-- Billing Summary -->
            <div class="row">
                <div class="col-md-6 offset-md-6">
                    <h6 class="section-title">BILLING SUMMARY</h6>
                    <table class="table table-sm billing-table">
                        <tbody>
                            <!-- Use billing_breakdown from cart_metadata if available -->
                            <template v-if="billingBreakdown && billingBreakdown.length > 0">
                                <tr v-for="(item, index) in billingBreakdown" :key="index" :class="{ 'total-row': item.is_total }">
                                    <td>{{ item.label }}:</td>
                                    <td class="text-end">
                                        <span v-if="item.is_credit">- </span>
                                        {{ item.currency || $currency }}{{ item.amount }}
                                    </td>
                                </tr>
                            </template>

                            <!-- Fallback to order fields if cart_metadata not available -->
                            <template v-else>
                                <tr>
                                    <td>Items Total:</td>
                                    <td class="text-end">{{ $currency }}{{ invoiceData.order.total }}</td>
                                </tr>
                                <tr v-if="invoiceData.order.discount > 0">
                                    <td>Discount ({{ invoiceData.order.discount }}%):</td>
                                    <td class="text-end">- {{ $currency }}{{ calculateDiscountAmount() }}</td>
                                </tr>
                                <tr v-if="invoiceData.order.promo_discount > 0">
                                    <td>Promo Discount <span v-if="invoiceData.order.promo_code">({{ invoiceData.order.promo_code }})</span>:</td>
                                    <td class="text-end">- {{ $currency }}{{ invoiceData.order.promo_discount }}</td>
                                </tr>
                                <tr v-if="invoiceData.order.wallet_balance > 0">
                                    <td>Wallet Used:</td>
                                    <td class="text-end">- {{ $currency }}{{ invoiceData.order.wallet_balance }}</td>
                                </tr>
                                <tr>
                                    <td>Delivery Charge:</td>
                                    <td class="text-end">{{ $currency }}{{ invoiceData.order.delivery_charge || 0 }}</td>
                                </tr>
                                <tr v-if="deliveryTip > 0">
                                    <td>Delivery Tip:</td>
                                    <td class="text-end">{{ $currency }}{{ deliveryTip }}</td>
                                </tr>
                                <tr class="total-row">
                                    <td><strong>Total Payable:</strong></td>
                                    <td class="text-end"><strong>{{ $currency }}{{ invoiceData.order.remaining_final }}</strong></td>
                                </tr>
                            </template>
                        </tbody>
                    </table>
                </div>
            </div>

            <hr class="my-3">

            <!-- Delivery Instructions (from cart_metadata) -->
            <div v-if="cartInfo && cartInfo.delivery_instructions" class="mb-3">
                <h6 class="section-title">DELIVERY INSTRUCTIONS</h6>
                <p class="mb-0">{{ cartInfo.delivery_instructions }}</p>
            </div>

            <!-- Contact Details (from cart_metadata) -->
            <div v-if="cartInfo && (cartInfo.contact_name || cartInfo.contact_phone)" class="mb-3">
                <h6 class="section-title">CONTACT DETAILS</h6>
                <p class="mb-0" v-if="cartInfo.contact_name"><strong>Name:</strong> {{ cartInfo.contact_name }}</p>
                <p class="mb-0" v-if="cartInfo.contact_phone"><strong>Phone:</strong> {{ cartInfo.contact_phone }}</p>
                <p class="mb-0" v-if="cartInfo.contact_email"><strong>Email:</strong> {{ cartInfo.contact_email }}</p>
            </div>

            <!-- Seller Notes (from cart_metadata) -->
            <!-- <div v-if="cartInfo && cartInfo.seller_notes && Object.keys(cartInfo.seller_notes).length > 0" class="mb-3">
                <h6 class="section-title">SELLER NOTES</h6>
                <div v-for="(note, sellerId) in cartInfo.seller_notes" :key="sellerId">
                    <p class="mb-0"><strong>Seller {{ sellerId }}:</strong> {{ note }}</p>
                </div>
            </div> -->

            <hr class="my-3">

            <!-- Delivery Partner Details -->
            <div v-if="invoiceData.delivery_boy_details" class="mb-3">
                <h6 class="section-title">DELIVERY PARTNER</h6>
                <table class="table table-sm table-bordered">
                    <tr>
                        <td width="200">Name:</td>
                        <td>{{ invoiceData.delivery_boy_details.name }}</td>
                    </tr>
                    <tr>
                        <td>Bonus Type:</td>
                        <td>{{ invoiceData.delivery_boy_details.bonus_type }}</td>
                    </tr>
                    <tr>
                        <td>Bonus Amount:</td>
                        <td>{{ $currency }}{{ invoiceData.order.delivery_boy_bonus_amount || 0 }}</td>
                    </tr>
                    <tr v-if="invoiceData.order.payment_method === 'COD'">
                        <td>Cash Collected:</td>
                        <td>{{ $currency }}{{ invoiceData.order.remaining_final || 0 }}</td>
                    </tr>
                </table>
            </div>

            <!-- Settlement Summary -->
            <!-- <div v-if="invoiceData.admin_settlement" class="mb-3">
                <h6 class="section-title">SETTLEMENT SUMMARY</h6>
                <table class="table table-sm table-bordered">
                    <tr>
                        <td width="200">Order Total:</td>
                        <td>{{ $currency }}{{ invoiceData.admin_settlement.order_total }}</td>
                    </tr>
                    <tr>
                        <td>Delivery Boy Bonus:</td>
                        <td>{{ $currency }}{{ invoiceData.admin_settlement.delivery_boy_bonus }}</td>
                    </tr>
                    <tr>
                        <td>Platform Earning:</td>
                        <td>{{ $currency }}{{ invoiceData.admin_settlement.platform_earning }}</td>
                    </tr>
                    <tr v-if="invoiceData.admin_settlement.cash_collected > 0">
                        <td>Cash Collected (COD):</td>
                        <td>{{ $currency }}{{ invoiceData.admin_settlement.cash_collected }}</td>
                    </tr>
                </table>
            </div> -->

        </div>

        <div v-else class="text-center py-5">
            <p>No invoice data available</p>
        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    name: "InvoiceDetails",
    props: {
        orderId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            isBluetoothPrinting: false,
            invoiceData: null
        };
    },
    computed: {
        cartMetadata() {
            if (!this.invoiceData || !this.invoiceData.order || !this.invoiceData.order.cart_metadata) {
                return null;
            }
            let metadata = this.invoiceData.order.cart_metadata;
            if (typeof metadata === 'string') {
                try {
                    metadata = JSON.parse(metadata);
                } catch (e) {
                    return null;
                }
            }
            return metadata;
        },
        cartInfo() {
            return this.cartMetadata ? this.cartMetadata.cart_info : null;
        },
        billingBreakdown() {
            return this.cartMetadata ? this.cartMetadata.billing_breakdown : null;
        },
        billingSummary() {
            return this.cartMetadata ? this.cartMetadata.billing_summary : null;
        },
        deliveryTip() {
            if (this.cartInfo && this.cartInfo.delivery_tip) {
                return parseFloat(this.cartInfo.delivery_tip) || 0;
            }
            return 0;
        }
    },
    created() {
        this.fetchInvoiceDetails();
    },
    watch: {
        orderId() {
            this.fetchInvoiceDetails();
        }
    },
    methods: {
        fetchInvoiceDetails() {
            if (!this.orderId) return;

            this.isLoading = true;
            axios.get(this.$apiUrl + '/orders/invoice-details/' + this.orderId)
                .then((response) => {
                    if (response.data.status === 1) {
                        this.invoiceData = response.data.data;
                    } else {
                        this.showError(response.data.message || 'Failed to load invoice details');
                    }
                })
                .catch((error) => {
                    console.error('Error fetching invoice details:', error);
                    this.showError('Failed to load invoice details');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        },

        formatDateTime(dateTime) {
            if (!dateTime) return '-';
            const date = new Date(dateTime);
            const day = date.getDate().toString().padStart(2, '0');
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const year = date.getFullYear();
            const hours = date.getHours();
            const minutes = date.getMinutes().toString().padStart(2, '0');
            const ampm = hours >= 12 ? 'PM' : 'AM';
            const hour12 = hours % 12 || 12;
            return `${day}-${month}-${year} ${hour12}:${minutes} ${ampm}`;
        },

        getStoreName(store) {
            // For store_id 12, show "Zenfoo Store" instead of actual store name
            if (store.store_id === 12) {
                return 'ZENFOO STORE';
            }
            return (store.store_name || 'Unknown Store').toUpperCase();
        },

        calculateStoreTotal(items) {
            if (!items || !items.length) return 0;
            return items.reduce((total, item) => total + parseFloat(item.sub_total || 0), 0).toFixed(2);
        },

        calculateDiscountAmount() {
            if (!this.invoiceData || !this.invoiceData.order) return 0;
            const total = parseFloat(this.invoiceData.order.total) || 0;
            const discount = parseFloat(this.invoiceData.order.discount) || 0;
            return ((total * discount) / 100).toFixed(2);
        },

        printInvoice() {
            // Create a new window for printing
            const printWindow = window.open('', '_blank', 'width=400,height=600');

            // Generate thermal printer friendly HTML
            const printContent = this.generateThermalPrintHTML();

            printWindow.document.write(printContent);
            printWindow.document.close();

            // Wait for content to load then print
            printWindow.onload = function() {
                printWindow.focus();
                printWindow.print();
                // Close after print dialog closes
                printWindow.onafterprint = function() {
                    printWindow.close();
                };
            };
        },

        generateESCPOSCommands() {
            // ESC/POS Commands
            const ESC = '\x1B';
            const GS = '\x1D';
            const INIT = ESC + '@';
            const ALIGN_CENTER = ESC + 'a' + '\x01';
            const ALIGN_LEFT = ESC + 'a' + '\x00';
            const BOLD_ON = ESC + 'E' + '\x01';
            const BOLD_OFF = ESC + 'E' + '\x00';
            const DOUBLE_HEIGHT = GS + '!' + '\x10';
            const NORMAL_SIZE = GS + '!' + '\x00';
            const CUT = GS + 'V' + '\x00';

            const W = 42;
            const LINE = '-'.repeat(W) + '\n';
            const DOUBLE_LINE = '='.repeat(W) + '\n';
            const NAME_W = 24;
            const QTY_W = 6;
            const PRICE_W = 12;

            const wrapToWidth = (text, maxLen) => {
                if (!text) return [''];
                const lines = [];
                let remaining = text;
                while (remaining.length > 0) {
                    if (remaining.length <= maxLen) { lines.push(remaining); break; }
                    let breakPoint = remaining.lastIndexOf(' ', maxLen);
                    if (breakPoint <= 0) breakPoint = maxLen;
                    lines.push(remaining.substring(0, breakPoint).trim());
                    remaining = remaining.substring(breakPoint).trim();
                }
                return lines;
            };

            const padRight = (str, len) => {
                const s = String(str);
                return s.length >= len ? s.substring(0, len) : s + ' '.repeat(len - s.length);
            };

            const padLeft = (str, len) => {
                const s = String(str);
                return s.length >= len ? s.substring(0, len) : ' '.repeat(len - s.length) + s;
            };

            const formatItem = (name, qty, price) => {
                const qtyStr = qty + 'x';
                const priceStr = 'Rs.' + price;
                const nameLines = wrapToWidth(name, NAME_W - 1);
                let result = '';
                nameLines.forEach((line, idx) => {
                    if (idx === 0) {
                        result += padRight(line, NAME_W) + padLeft(qtyStr, QTY_W) + padLeft(priceStr, PRICE_W) + '\n';
                    } else {
                        result += '  ' + line + '\n';
                    }
                });
                return result;
            };

            const formatRow = (label, value) => {
                const valStr = String(value);
                const maxLabelLen = W - valStr.length - 1;
                const truncLabel = label.length > maxLabelLen ? label.substring(0, maxLabelLen) : label;
                const spaces = W - truncLabel.length - valStr.length;
                return truncLabel + ' '.repeat(Math.max(1, spaces)) + valStr + '\n';
            };

            const wrapText = (text, maxLen) => {
                const lines = wrapToWidth(text, maxLen);
                return lines.join('\n') + '\n';
            };

            const order = this.invoiceData.order;
            const currency = 'Rs.';

            let r = '';
            r += INIT;
            r += ALIGN_CENTER;
            r += DOUBLE_HEIGHT + BOLD_ON;
            r += 'ZENFOO\n';
            r += NORMAL_SIZE + BOLD_OFF;
            r += DOUBLE_LINE;
            r += BOLD_ON + 'INVOICE\n' + BOLD_OFF;
            r += DOUBLE_LINE;

            r += ALIGN_LEFT;
            r += 'Order #: ' + (order.order_number || order.order_id) + '\n';
            r += 'Date: ' + this.formatDateTime(order.created_at) + '\n';
            r += 'Payment: ' + (order.payment_method || '-') + '\n';
            r += LINE;

            r += BOLD_ON + 'CUSTOMER\n' + BOLD_OFF;
            r += (order.user_name || '-') + '\n';
            r += (order.mobile || '-') + '\n';
            r += LINE;

            r += BOLD_ON + 'DELIVERY ADDRESS\n' + BOLD_OFF;
            r += wrapText(order.order_address || '-', W);
            if (order.delivery_boy_name) {
                r += 'Driver: ' + order.delivery_boy_name + '\n';
            }
            r += LINE;

            r += BOLD_ON;
            r += padRight('ITEM', NAME_W) + padLeft('QTY', QTY_W) + padLeft('PRICE', PRICE_W) + '\n';
            r += BOLD_OFF;
            r += LINE;

            if (this.invoiceData.store_wise_items) {
                this.invoiceData.store_wise_items.forEach(store => {
                    store.items.forEach(item => {
                        const variant = item.variant_measurement ? ' (' + item.variant_measurement + ')' : '';
                        const itemName = item.product_name + variant;
                        r += formatItem(itemName, item.quantity, item.sub_total);
                    });
                });
            }

            if (this.invoiceData.combo_items && this.invoiceData.combo_items.length > 0) {
                r += BOLD_ON + 'COMBO ITEMS\n' + BOLD_OFF;
                this.invoiceData.combo_items.forEach(combo => {
                    r += formatItem(combo.combo_name || 'Combo', combo.combo_quantity || 1, combo.sub_total);
                });
                r += '\n';
            }

            r += LINE;
            r += BOLD_ON + 'BILLING\n' + BOLD_OFF;

            if (this.billingBreakdown && this.billingBreakdown.length > 0) {
                this.billingBreakdown.forEach(item => {
                    const prefix = item.is_credit ? '-' : '';
                    r += formatRow(item.label, prefix + currency + item.amount);
                });
            } else {
                r += formatRow('Items Total', currency + order.total);
                if (order.discount > 0) {
                    r += formatRow('Discount(' + order.discount + '%)', '-' + currency + this.calculateDiscountAmount());
                }
                if (order.promo_discount > 0) {
                    r += formatRow('Promo', '-' + currency + order.promo_discount);
                }
                if (order.wallet_balance > 0) {
                    r += formatRow('Wallet', '-' + currency + order.wallet_balance);
                }
                r += formatRow('Delivery', currency + (order.delivery_charge || 0));
                if (this.deliveryTip > 0) {
                    r += formatRow('Tip', currency + this.deliveryTip);
                }
            }

            r += DOUBLE_LINE;
            r += BOLD_ON;
            r += formatRow('TOTAL', currency + order.remaining_final);
            r += BOLD_OFF;
            r += DOUBLE_LINE;

            if (this.invoiceData.delivery_boy_details) {
                const db = this.invoiceData.delivery_boy_details;
                r += 'Driver: ' + db.name + '\n';
                if (order.payment_method === 'COD') {
                    r += 'Cash Collected: ' + currency + (order.remaining_final || 0) + '\n';
                }
            }

            r += '\n';
            r += ALIGN_CENTER;
            r += 'Thank you for your order!\n';
            r += 'www.zenfoo.in\n';
            r += '\n\n\n';

            return { commands: r, cutCommand: CUT };
        },

        async printDirect() {
            if (!('serial' in navigator)) {
                alert('Direct USB printing is not supported in this browser. Please use Chrome or Edge.');
                return;
            }

            try {
                const port = await navigator.serial.requestPort();
                await port.open({ baudRate: 9600 });

                const writer = port.writable.getWriter();
                const encoder = new TextEncoder();
                const { commands, cutCommand } = this.generateESCPOSCommands();

                await writer.write(encoder.encode(commands));
                await writer.write(encoder.encode(cutCommand));

                writer.releaseLock();
                await port.close();

                console.log('USB Print successful!');
            } catch (error) {
                console.error('Print error:', error);
                if (error.name === 'NotFoundError') {
                    alert('No printer selected. Please select your thermal printer.');
                } else {
                    alert('Print failed: ' + error.message);
                }
            }
        },

        async printBluetooth() {
            if (!('bluetooth' in navigator)) {
                alert('Web Bluetooth is not supported in this browser. Please use Chrome or Edge on HTTPS.');
                return;
            }

            this.isBluetoothPrinting = true;

            // Common BLE thermal printer service UUIDs
            const PRINTER_SERVICE_UUIDS = [
                '000018f0-0000-1000-8000-00805f9b34fb',
                'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
                '0000ff00-0000-1000-8000-00805f9b34fb',
                '49535343-fe7d-4ae5-8fa9-9fafd205e455',
            ];

            // Common BLE thermal printer write characteristic UUIDs
            const WRITE_CHARACTERISTIC_UUIDS = [
                '00002af1-0000-1000-8000-00805f9b34fb',
                'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f',
                '0000ff02-0000-1000-8000-00805f9b34fb',
                '49535343-8841-43f4-a8d4-ecbe34729bb3',
            ];

            let device = null;
            let server = null;

            try {
                // Request Bluetooth device - show all printers
                device = await navigator.bluetooth.requestDevice({
                    filters: PRINTER_SERVICE_UUIDS.map(uuid => ({ services: [uuid] })),
                    optionalServices: PRINTER_SERVICE_UUIDS,
                });

                if (!device) {
                    this.isBluetoothPrinting = false;
                    return;
                }

                // Connect to GATT server
                server = await device.gatt.connect();

                // Try to find a writable characteristic from known service/characteristic pairs
                let writeCharacteristic = null;

                for (const serviceUUID of PRINTER_SERVICE_UUIDS) {
                    try {
                        const service = await server.getPrimaryService(serviceUUID);
                        for (const charUUID of WRITE_CHARACTERISTIC_UUIDS) {
                            try {
                                const char = await service.getCharacteristic(charUUID);
                                if (char.properties.write || char.properties.writeWithoutResponse) {
                                    writeCharacteristic = char;
                                    break;
                                }
                            } catch (e) {
                                // This characteristic doesn't exist on this service, try next
                            }
                        }
                        if (writeCharacteristic) break;

                        // If none of the known characteristics matched, try to find any writable one
                        if (!writeCharacteristic) {
                            try {
                                const chars = await service.getCharacteristics();
                                for (const char of chars) {
                                    if (char.properties.write || char.properties.writeWithoutResponse) {
                                        writeCharacteristic = char;
                                        break;
                                    }
                                }
                            } catch (e) {
                                // Could not enumerate characteristics
                            }
                        }
                        if (writeCharacteristic) break;
                    } catch (e) {
                        // This service doesn't exist on this device, try next
                    }
                }

                if (!writeCharacteristic) {
                    alert('Could not find a writable characteristic on this Bluetooth printer. Make sure it is a BLE thermal printer.');
                    if (server && server.connected) server.disconnect();
                    this.isBluetoothPrinting = false;
                    return;
                }

                // Generate ESC/POS commands
                const { commands, cutCommand } = this.generateESCPOSCommands();
                const fullData = commands + cutCommand;
                const encoder = new TextEncoder();
                const data = encoder.encode(fullData);

                // BLE has MTU limit, send in chunks (default safe size: 20 bytes, most negotiate higher)
                const CHUNK_SIZE = 100;
                for (let i = 0; i < data.length; i += CHUNK_SIZE) {
                    const chunk = data.slice(i, i + CHUNK_SIZE);
                    if (writeCharacteristic.properties.writeWithoutResponse) {
                        await writeCharacteristic.writeValueWithoutResponse(chunk);
                    } else {
                        await writeCharacteristic.writeValue(chunk);
                    }
                    // Small delay between chunks to avoid buffer overflow
                    await new Promise(resolve => setTimeout(resolve, 50));
                }

                console.log('Bluetooth Print successful!');
                alert('Print sent to Bluetooth printer successfully!');

            } catch (error) {
                console.error('Bluetooth print error:', error);
                if (error.name === 'NotFoundError') {
                    alert('No Bluetooth printer selected. Please pair your printer and try again.');
                } else if (error.name === 'SecurityError') {
                    alert('Bluetooth access denied. Make sure you are on HTTPS and have granted Bluetooth permissions.');
                } else if (error.name === 'NetworkError') {
                    alert('Could not connect to Bluetooth printer. Make sure the printer is turned on and in range.');
                } else {
                    alert('Bluetooth print failed: ' + error.message);
                }
            } finally {
                // Disconnect Bluetooth
                if (server && server.connected) {
                    server.disconnect();
                }
                this.isBluetoothPrinting = false;
            }
        },

        generateThermalPrintHTML() {
            const order = this.invoiceData.order;
            const currency = this.$currency || '₹';

            let html = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Invoice ${order.order_number || ('#' + order.order_id)}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Courier New', 'Lucida Console', monospace;
            font-size: 12px;
            line-height: 1.4;
            color: #000;
            width: 100%;
            max-width: 80mm;
            margin: 0 auto;
            padding: 5px;
        }
        .center { text-align: center; }
        .right { text-align: right; }
        .bold { font-weight: bold; }
        .divider {
            border-top: 1px dashed #000;
            margin: 8px 0;
        }
        .double-divider {
            border-top: 2px solid #000;
            margin: 8px 0;
        }
        .header {
            text-align: center;
            margin-bottom: 10px;
        }
        .header h1 {
            font-size: 18px;
            margin-bottom: 5px;
        }
        .section-title {
            font-weight: bold;
            margin: 8px 0 4px 0;
            text-transform: uppercase;
            font-size: 11px;
        }
        .row {
            display: flex;
            justify-content: space-between;
            margin: 2px 0;
        }
        .row .label {
            flex: 1;
        }
        .row .value {
            text-align: right;
        }
        .item-row {
            margin: 4px 0;
        }
        .item-name {
            font-weight: bold;
        }
        .item-details {
            display: flex;
            justify-content: space-between;
            padding-left: 10px;
            font-size: 11px;
        }
        .total-section {
            margin-top: 10px;
        }
        .total-row {
            display: flex;
            justify-content: space-between;
            font-weight: bold;
            font-size: 14px;
            margin-top: 5px;
            padding-top: 5px;
            border-top: 1px solid #000;
        }
        .footer {
            text-align: center;
            margin-top: 15px;
            font-size: 10px;
        }
        @media print {
            body {
                width: 100%;
                max-width: none;
            }
            @page {
                margin: 0;
                size: auto;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>ZENFOO</h1>
        <div class="double-divider"></div>
        <div class="bold">INVOICE</div>
    </div>

    <div class="row">
        <span class="label">Order #:</span>
        <span class="value bold">${order.order_number || ('#' + order.order_id)}</span>
    </div>
    <div class="row">
        <span class="label">Date:</span>
        <span class="value">${this.formatDateTime(order.created_at)}</span>
    </div>
    <div class="row">
        <span class="label">Status:</span>
        <span class="value">${order.status_name || '-'}</span>
    </div>
    <div class="row">
        <span class="label">Payment:</span>
        <span class="value">${order.payment_method || '-'}</span>
    </div>

    <div class="divider"></div>

    <div class="section-title">Customer</div>
    <div>${order.user_name || '-'}</div>
    <div>${order.mobile || '-'}</div>
    ${order.user_email ? `<div>${order.user_email}</div>` : ''}

    <div class="divider"></div>

    <div class="section-title">Delivery Address</div>
    <div>${order.order_address || '-'}</div>
    ${order.delivery_boy_name ? `<div>Driver: ${order.delivery_boy_name}</div>` : ''}

    <div class="divider"></div>

    <div class="section-title">Items</div>
`;

            // Store-wise items
            if (this.invoiceData.store_wise_items) {
                this.invoiceData.store_wise_items.forEach(store => {
                    html += `<div class="bold" style="margin-top:5px;">${this.getStoreName(store)}</div>`;
                    store.items.forEach((item, index) => {
                        const variant = item.variant_measurement ? ` (${item.variant_measurement})` : '';
                        html += `
                        <div class="item-row">
                            <div class="item-name">${index + 1}. ${item.product_name}${variant}</div>
                            <div class="item-details">
                                <span>${item.quantity} x ${currency}${item.price}</span>
                                <span>${currency}${item.sub_total}</span>
                            </div>
                        </div>`;
                    });
                    html += `
                    <div class="row" style="margin-top:3px;">
                        <span class="label">Store Total:</span>
                        <span class="value bold">${currency}${this.calculateStoreTotal(store.items)}</span>
                    </div>`;
                });
            }

            // Combo items
            if (this.invoiceData.combo_items && this.invoiceData.combo_items.length > 0) {
                html += `<div class="section-title" style="margin-top:8px;">Combo Items</div>`;
                this.invoiceData.combo_items.forEach(combo => {
                    html += `<div class="bold">${combo.combo_name || 'Combo Pack'} (Qty: ${combo.combo_quantity || 1}) - ${currency}${combo.sub_total}</div>`;
                    if (combo.products) {
                        combo.products.forEach((product, pIndex) => {
                            html += `<div class="item-details">${pIndex + 1}. ${product.product_name} x ${product.quantity}</div>`;
                        });
                    }
                });
            }

            html += `<div class="divider"></div>`;
            html += `<div class="section-title">Billing Summary</div>`;

            // Billing breakdown
            if (this.billingBreakdown && this.billingBreakdown.length > 0) {
                this.billingBreakdown.forEach(item => {
                    const prefix = item.is_credit ? '- ' : '';
                    const boldClass = item.is_total ? 'bold' : '';
                    html += `
                    <div class="row ${boldClass}">
                        <span class="label">${item.label}:</span>
                        <span class="value">${prefix}${item.currency || currency}${item.amount}</span>
                    </div>`;
                });
            } else {
                // Fallback billing
                html += `
                <div class="row">
                    <span class="label">Items Total:</span>
                    <span class="value">${currency}${order.total}</span>
                </div>`;

                if (order.discount > 0) {
                    html += `
                    <div class="row">
                        <span class="label">Discount (${order.discount}%):</span>
                        <span class="value">- ${currency}${this.calculateDiscountAmount()}</span>
                    </div>`;
                }

                if (order.promo_discount > 0) {
                    html += `
                    <div class="row">
                        <span class="label">Promo${order.promo_code ? ' (' + order.promo_code + ')' : ''}:</span>
                        <span class="value">- ${currency}${order.promo_discount}</span>
                    </div>`;
                }

                if (order.wallet_balance > 0) {
                    html += `
                    <div class="row">
                        <span class="label">Wallet Used:</span>
                        <span class="value">- ${currency}${order.wallet_balance}</span>
                    </div>`;
                }

                html += `
                <div class="row">
                    <span class="label">Delivery Charge:</span>
                    <span class="value">${currency}${order.delivery_charge || 0}</span>
                </div>`;

                if (this.deliveryTip > 0) {
                    html += `
                    <div class="row">
                        <span class="label">Delivery Tip:</span>
                        <span class="value">${currency}${this.deliveryTip}</span>
                    </div>`;
                }

                html += `
                <div class="total-row">
                    <span>TOTAL:</span>
                    <span>${currency}${order.remaining_final}</span>
                </div>`;
            }

            // Delivery instructions
            if (this.cartInfo && this.cartInfo.delivery_instructions) {
                html += `
                <div class="divider"></div>
                <div class="section-title">Delivery Instructions</div>
                <div>${this.cartInfo.delivery_instructions}</div>`;
            }

            // Contact details
            if (this.cartInfo && (this.cartInfo.contact_name || this.cartInfo.contact_phone)) {
                html += `<div class="divider"></div><div class="section-title">Contact</div>`;
                if (this.cartInfo.contact_name) html += `<div>Name: ${this.cartInfo.contact_name}</div>`;
                if (this.cartInfo.contact_phone) html += `<div>Phone: ${this.cartInfo.contact_phone}</div>`;
                if (this.cartInfo.contact_email) html += `<div>Email: ${this.cartInfo.contact_email}</div>`;
            }

            // Delivery partner details
            if (this.invoiceData.delivery_boy_details) {
                const db = this.invoiceData.delivery_boy_details;
                html += `
                <div class="divider"></div>
                <div class="section-title">Delivery Partner</div>
                <div class="row"><span class="label">Name:</span><span class="value">${db.name}</span></div>
                <div class="row"><span class="label">Bonus Type:</span><span class="value">${db.bonus_type}</span></div>
                <div class="row"><span class="label">Bonus Amount:</span><span class="value">${currency}${order.delivery_boy_bonus_amount || 0}</span></div>`;

                if (order.payment_method === 'COD') {
                    html += `<div class="row"><span class="label">Cash Collected:</span><span class="value">${currency}${order.remaining_final || 0}</span></div>`;
                }
            }

            html += `
    <div class="double-divider"></div>
    <div class="footer">
        <div>Thank you for your order!</div>
        <div>www.zenfoo.in</div>
    </div>
</body>
</html>`;

            return html;
        }
    }
};
</script>

<style scoped>
.invoice-details {
    padding: 20px;
    background: #fff;
}

.invoice-container {
    max-width: 800px;
    margin: 0 auto;
    font-family: 'Courier New', monospace;
    font-size: 14px;
    color: #000;
}

.invoice-header h4 {
    font-weight: bold;
    margin-bottom: 10px;
}

.section-title {
    font-weight: bold;
    margin-bottom: 10px;
    border-bottom: 1px solid #000;
    padding-bottom: 5px;
}

.table {
    border-color: #000;
}

.table th {
    background-color: #f5f5f5;
    font-weight: bold;
    border-color: #000;
}

.table td {
    border-color: #000;
}

.billing-table {
    border: none;
}

.billing-table td {
    border: none;
    padding: 5px 0;
}

.billing-table .total-row td {
    border-top: 1px solid #000;
    padding-top: 10px;
    font-weight: bold;
}

hr {
    border-color: #000;
}

.text-muted {
    color: #666 !important;
}

.print-button-container {
    text-align: right;
}

/* Hide print button when printing */
@media print {
    .no-print {
        display: none !important;
    }
}

</style>

<style>
/* Dark mode support for invoice (unscoped so .theme-dark parent selector works) */
.theme-dark .invoice-details {
    background: #1a1d21;
}

.theme-dark .invoice-container {
    color: #e0e0e0;
}

.theme-dark .invoice-details .section-title {
    border-bottom-color: #444;
}

.theme-dark .invoice-details .table {
    border-color: #444;
    color: #e0e0e0;
}

.theme-dark .invoice-details .table th {
    background-color: #2a2d31;
    border-color: #444;
    color: #e0e0e0;
}

.theme-dark .invoice-details .table td {
    border-color: #444;
    color: #e0e0e0;
}

.theme-dark .invoice-details .billing-table .total-row td {
    border-top-color: #444;
}

.theme-dark .invoice-details hr {
    border-color: #444;
}

.theme-dark .invoice-details .text-muted {
    color: #999 !important;
}
</style>
