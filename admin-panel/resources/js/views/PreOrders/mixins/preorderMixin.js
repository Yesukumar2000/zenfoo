import axios from 'axios';
import moment from 'moment';

export default {
    data() {
        return {
            // Printing related
            port: null,
            writer: null,
            encoder: new TextEncoder(),
        }
    },
    methods: {
        // ============ API CALLS ============

        async fetchPreOrderStats() {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/preorders/stats');
                if (response.data.status === 1) {
                    return response.data.data;
                }
            } catch (error) {
                console.error('Error fetching stats:', error);
                this.$toast.error('Failed to fetch statistics');
            }
            return null;
        },

        async fetchStoreWiseAnalytics(params = {}) {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/preorders/store-wise-analytics', { params });
                if (response.data.status === 1) {
                    return response.data.data;
                }
            } catch (error) {
                console.error('Error fetching store analytics:', error);
                this.$toast.error('Failed to fetch store analytics');
            }
            return [];
        },

        async fetchPreOrders(params) {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/preorders', { params });
                if (response.data.status === 1) {
                    return {
                        orders: response.data.data.orders,
                        total: response.data.data.orders_total,
                        stores: response.data.data.stores
                    };
                }
            } catch (error) {
                console.error('Error fetching preorders:', error);
                this.$toast.error('Failed to fetch preorders');
            }
            return { orders: [], total: 0, stores: [] };
        },

        // ============ PRINTING METHODS ============

        async printThermalInvoice(orderId) {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/preorders/' + orderId);
                if (response.data.status !== 1) {
                    this.$toast.error('Failed to fetch order details');
                    return;
                }

                const order = response.data.data;
                const printContent = this.generateThermalPrintContent(order);

                const printWindow = window.open('', '', 'width=302,height=600');
                printWindow.document.write(`
                    <html>
                    <head>
                        <title>Print Invoice - Order #${order.id}</title>
                        <style>
                            @page {
                                size: 80mm auto;
                                margin: 0;
                            }
                            * {
                                margin: 0;
                                padding: 0;
                                box-sizing: border-box;
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                                color-adjust: exact !important;
                            }
                            body {
                                font-family: 'Courier New', monospace;
                                font-size: 11px;
                                width: 80mm;
                                padding: 5mm;
                                background: white;
                            }
                            .center { text-align: center; }
                            .bold { font-weight: bold; font-size: 13px; }
                            .divider { border-top: 1px dashed #000; margin: 5px 0; }
                            .row { display: flex; justify-content: space-between; margin: 2px 0; }
                            .total-row { font-weight: bold; font-size: 12px; margin-top: 5px; }
                            h2 { font-size: 16px; margin: 5px 0; }
                            h3 { font-size: 14px; margin: 3px 0; }
                            @media print {
                                body { padding: 0; }
                            }
                        </style>
                    </head>
                    <body>${printContent}</body>
                    </html>
                `);
                printWindow.document.close();
                printWindow.focus();

                setTimeout(() => {
                    printWindow.print();
                    printWindow.close();
                }, 250);
            } catch (error) {
                console.error('Print error:', error);
                this.$toast.error('Failed to print invoice');
            }
        },

        generateThermalPrintContent(order) {
            let content = `
                <div class="center">
                    <h2 class="bold">ZENFOO</h2>
                    <p>Pre Order Invoice</p>
                </div>
                <div class="divider"></div>
                <div class="row">
                    <span>Order #:</span>
                    <span class="bold">${order.id}</span>
                </div>
                <div class="row">
                    <span>Customer:</span>
                    <span>${order.user ? order.user.name : 'Guest'}</span>
                </div>
                <div class="row">
                    <span>Mobile:</span>
                    <span>${order.mobile || 'N/A'}</span>
                </div>
                <div class="row">
                    <span>Placed At:</span>
                    <span>${order.preorder_placed_at_formatted || order.created_at}</span>
                </div>
                <div class="row">
                    <span>Process Date:</span>
                    <span>${order.preorder_process_date_formatted || 'N/A'}</span>
                </div>
                <div class="divider"></div>
                <h3 class="center bold">ORDER ITEMS</h3>
                <div class="divider"></div>
            `;

            if (order.items && order.items.length > 0) {
                order.items.forEach(item => {
                    content += `
                        <div class="row">
                            <span>${item.name || item.product_name}</span>
                        </div>
                        <div class="row" style="padding-left: 10px;">
                            <span>${item.quantity} x ₹${item.price}</span>
                            <span>₹${item.sub_total}</span>
                        </div>
                    `;
                });
            }

            content += `
                <div class="divider"></div>
                <div class="row">
                    <span>Subtotal:</span>
                    <span>₹${order.total || 0}</span>
                </div>
                <div class="row">
                    <span>Delivery Charge:</span>
                    <span>₹${order.delivery_charge || 0}</span>
                </div>
            `;

            if (order.wallet_balance && order.wallet_balance > 0) {
                content += `
                    <div class="row">
                        <span>Wallet Used:</span>
                        <span>-₹${order.wallet_balance}</span>
                    </div>
                `;
            }

            content += `
                <div class="divider"></div>
                <div class="row total-row">
                    <span>TOTAL:</span>
                    <span>₹${order.final_total || 0}</span>
                </div>
                <div class="divider"></div>
                <div class="row">
                    <span>Payment:</span>
                    <span>${order.payment_method || 'N/A'}</span>
                </div>
                <div class="divider"></div>
                <div class="center" style="margin-top: 10px;">
                    <p>Thank you for your order!</p>
                    <p style="font-size: 9px; margin-top: 5px;">This is a pre-order invoice</p>
                </div>
            `;

            return content;
        },

        async printDirectUSB(orderId) {
            try {
                if (!('serial' in navigator)) {
                    this.$toast.error('Web Serial API not supported in this browser. Please use Chrome/Edge.');
                    return;
                }

                const response = await axios.get(this.$apiUrl + '/admin/preorders/' + orderId);
                if (response.data.status !== 1) {
                    this.$toast.error('Failed to fetch order details');
                    return;
                }

                const order = response.data.data;

                if (!this.port) {
                    try {
                        this.port = await navigator.serial.requestPort();
                        await this.port.open({ baudRate: 9600 });
                        this.writer = this.port.writable.getWriter();
                    } catch (error) {
                        console.error('Port access error:', error);
                        this.$toast.error('Failed to connect to printer');
                        return;
                    }
                }

                const commands = this.generateESCPOSCommands(order);
                await this.writer.write(commands);

                this.$toast.success('Print sent to USB printer');
            } catch (error) {
                console.error('USB print error:', error);
                this.$toast.error('Failed to print via USB');

                if (this.writer) {
                    this.writer.releaseLock();
                    this.writer = null;
                }
                if (this.port) {
                    await this.port.close();
                    this.port = null;
                }
            }
        },

        generateESCPOSCommands(order) {
            const ESC = 0x1B;
            const GS = 0x1D;
            const LF = 0x0A;
            const commands = [];

            commands.push(ESC, 0x40);
            commands.push(ESC, 0x61, 0x01);
            commands.push(ESC, 0x21, 0x30);
            commands.push(...this.encoder.encode('ZENFOO\n'));
            commands.push(ESC, 0x21, 0x00);
            commands.push(...this.encoder.encode('Pre Order Invoice\n'));
            commands.push(...this.encoder.encode('--------------------------------\n'));
            commands.push(ESC, 0x61, 0x00);
            commands.push(...this.encoder.encode(`Order #: ${order.id}\n`));
            commands.push(...this.encoder.encode(`Customer: ${order.user ? order.user.name : 'Guest'}\n`));
            commands.push(...this.encoder.encode(`Mobile: ${order.mobile || 'N/A'}\n`));
            commands.push(...this.encoder.encode(`Placed: ${order.preorder_placed_at_formatted || order.created_at}\n`));
            commands.push(...this.encoder.encode(`Process: ${order.preorder_process_date_formatted || 'N/A'}\n`));
            commands.push(...this.encoder.encode('--------------------------------\n'));
            commands.push(ESC, 0x21, 0x08);
            commands.push(...this.encoder.encode('ORDER ITEMS\n'));
            commands.push(ESC, 0x21, 0x00);
            commands.push(...this.encoder.encode('--------------------------------\n'));

            if (order.items && order.items.length > 0) {
                order.items.forEach(item => {
                    commands.push(...this.encoder.encode(`${item.name || item.product_name}\n`));
                    commands.push(...this.encoder.encode(`  ${item.quantity} x Rs.${item.price}     Rs.${item.sub_total}\n`));
                });
            }

            commands.push(...this.encoder.encode('--------------------------------\n'));
            commands.push(...this.encoder.encode(`Subtotal:          Rs.${order.total || 0}\n`));
            commands.push(...this.encoder.encode(`Delivery:          Rs.${order.delivery_charge || 0}\n`));

            if (order.wallet_balance && order.wallet_balance > 0) {
                commands.push(...this.encoder.encode(`Wallet Used:      -Rs.${order.wallet_balance}\n`));
            }

            commands.push(...this.encoder.encode('--------------------------------\n'));
            commands.push(ESC, 0x21, 0x08);
            commands.push(...this.encoder.encode(`TOTAL:            Rs.${order.final_total || 0}\n`));
            commands.push(ESC, 0x21, 0x00);
            commands.push(...this.encoder.encode('--------------------------------\n'));
            commands.push(...this.encoder.encode(`Payment: ${order.payment_method || 'N/A'}\n`));
            commands.push(...this.encoder.encode('--------------------------------\n'));
            commands.push(ESC, 0x61, 0x01);
            commands.push(...this.encoder.encode('\nThank you for your order!\n'));
            commands.push(...this.encoder.encode('This is a pre-order invoice\n'));
            commands.push(LF, LF, LF);
            commands.push(GS, 0x56, 0x00);

            return new Uint8Array(commands);
        },

        async downloadOrderPDF(orderId) {
            this.$toast.info('Opening print dialog - Select "Save as PDF" as printer');
            await this.printThermalInvoice(orderId);
        },

        // ============ STORE-WISE ACTIONS ============

        async printStorePDF(storeId, storeName, filters = {}) {
            try {
                this.$toast.info(`Generating PDF for ${storeName}...`);

                const params = {
                    store_id: storeId,
                    per_page: 1000,
                    ...filters
                };

                const response = await axios.get(this.$apiUrl + '/admin/preorders/store-orders', { params });

                if (response.data.status === 1) {
                    const orders = response.data.data.orders;

                    if (orders.length === 0) {
                        this.$toast.warning(`No orders found for ${storeName}`);
                        return;
                    }

                    const totalAmount = orders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);
                    const totalOrders = orders.length;

                    const printContent = this.generateStorePrintContent(orders, totalAmount, totalOrders, storeName);

                    const printWindow = window.open('', '', 'width=800,height=600');
                    printWindow.document.write(printContent);
                    printWindow.document.close();
                    printWindow.focus();

                    setTimeout(() => {
                        printWindow.print();
                    }, 250);

                    this.$toast.info('Print dialog opened - Select "Save as PDF" to download');
                }
            } catch (error) {
                console.error('Store PDF error:', error);
                this.$toast.error('Failed to generate PDF');
            }
        },

        generateStorePrintContent(orders, totalAmount, totalOrders, storeName) {
            const statusMap = {
                12: 'Preorder Pending',
                2: 'Processed',
                3: 'In Progress',
                5: 'Out For Delivery',
                6: 'Delivered'
            };

            let ordersHTML = '';
            orders.forEach(order => {
                let itemsHTML = '';
                if (order.items && order.items.length > 0) {
                    order.items.forEach(item => {
                        itemsHTML += `
                            <tr>
                                <td>${item.name || item.product_name}</td>
                                <td class="text-center">${item.quantity}</td>
                                <td class="text-right">₹${parseFloat(item.price).toFixed(2)}</td>
                                <td class="text-right"><strong>₹${parseFloat(item.sub_total).toFixed(2)}</strong></td>
                            </tr>
                        `;
                    });
                }

                const status = statusMap[order.active_status] || `Status ${order.active_status}`;
                const statusClass = order.active_status == 12 ? 'status-pending' : 'status-processed';

                ordersHTML += `
                    <div class="order-section">
                        <div class="order-header-print">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <div>
                                    <h3>Order #${order.id}</h3>
                                    <p><strong>Customer:</strong> ${order.user_name || order.user?.name || 'Guest'} | <strong>Mobile:</strong> ${order.mobile}</p>
                                    <p><strong>Placed:</strong> ${order.preorder_placed_at_formatted || 'N/A'} | <strong>Process:</strong> ${order.preorder_process_date_formatted || 'N/A'}</p>
                                </div>
                                <div style="text-align: right;">
                                    <span class="status-badge ${statusClass}">${status}</span>
                                    <p style="font-size: 16px; margin-top: 5px;"><strong>₹${parseFloat(order.final_total).toFixed(2)}</strong></p>
                                </div>
                            </div>
                        </div>
                        <table class="items-table">
                            <thead>
                                <tr>
                                    <th style="width: 50%;">Item</th>
                                    <th class="text-center" style="width: 15%;">Qty</th>
                                    <th class="text-right" style="width: 17.5%;">Price</th>
                                    <th class="text-right" style="width: 17.5%;">Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${itemsHTML || '<tr><td colspan="4" class="text-center">No items</td></tr>'}
                            </tbody>
                        </table>
                        <div class="order-totals">
                            <div style="display: flex; justify-content: space-between;">
                                <span><strong>Payment:</strong> ${order.payment_method}</span>
                                <div style="text-align: right;">
                                    <div>Subtotal: ₹${parseFloat(order.total || 0).toFixed(2)}</div>
                                    <div>Delivery: ₹${parseFloat(order.delivery_charge || 0).toFixed(2)}</div>
                                    ${order.wallet_balance > 0 ? `<div>Wallet: -₹${parseFloat(order.wallet_balance).toFixed(2)}</div>` : ''}
                                    <div style="font-size: 14px; margin-top: 5px;"><strong>Total: ₹${parseFloat(order.final_total).toFixed(2)}</strong></div>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });

            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>${storeName} - Pre Orders</title>
                    <style>
                        @page { size: A4; margin: 1cm; }
                        @media print {
                            * {
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                                color-adjust: exact !important;
                                forced-color-adjust: none !important;
                            }
                            body { padding: 10px; }
                        }
                        * {
                            margin: 0;
                            padding: 0;
                            box-sizing: border-box;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        html { -webkit-print-color-adjust: exact !important; }
                        body { font-family: Arial, sans-serif; font-size: 11px; color: #000 !important; padding: 20px; background: white !important; }
                        .header { text-align: center; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 3px solid #3498db !important; }
                        .header h1 { font-size: 24px; color: #2c3e50 !important; margin-bottom: 5px; }
                        .header h2 { font-size: 18px; color: #3498db !important; margin-bottom: 10px; }
                        .header p { font-size: 11px; color: #666 !important; }
                        .order-section {
                            margin-bottom: 30px;
                            page-break-inside: avoid;
                            border: 2px solid #ccc !important;
                            padding: 15px;
                            background: #f5f5f5 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-header-print {
                            margin-bottom: 15px;
                            padding-bottom: 10px;
                            border-bottom: 2px solid #ddd !important;
                            background: white !important;
                            padding: 10px;
                        }
                        .order-header-print h3 { font-size: 16px; color: #000 !important; margin-bottom: 8px; font-weight: bold; }
                        .order-header-print p { font-size: 10px; margin-bottom: 3px; color: #333 !important; }
                        .items-table {
                            width: 100%;
                            border-collapse: collapse;
                            margin-bottom: 10px;
                            background: white !important;
                            border: 2px solid #000 !important;
                        }
                        .items-table thead {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table th {
                            padding: 8px 5px;
                            text-align: left;
                            font-size: 10px;
                            background-color: #34495e !important;
                            color: white !important;
                            border: 1px solid #000 !important;
                            font-weight: bold;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table td {
                            padding: 6px 5px;
                            border: 1px solid #ddd !important;
                            font-size: 10px;
                            color: #000 !important;
                        }
                        .items-table tbody tr:nth-child(even) {
                            background-color: #f0f0f0 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table tbody tr:nth-child(odd) {
                            background-color: white !important;
                        }
                        .text-center { text-align: center; }
                        .text-right { text-align: right; }
                        .status-badge {
                            display: inline-block;
                            padding: 4px 8px;
                            font-size: 9px;
                            font-weight: bold;
                            border: 2px solid #000 !important;
                        }
                        .status-pending {
                            background-color: #fff3cd !important;
                            color: #856404 !important;
                            border: 2px solid #856404 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-processed {
                            background-color: #d4edda !important;
                            color: #155724 !important;
                            border: 2px solid #155724 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-totals {
                            padding-top: 10px;
                            border-top: 2px solid #000 !important;
                            font-size: 10px;
                            background: white !important;
                            padding: 10px;
                        }
                        .summary-box {
                            margin-top: 20px;
                            padding: 15px;
                            background-color: #e3f2fd !important;
                            border: 3px solid #2196f3 !important;
                            page-break-inside: avoid;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .summary-row {
                            display: flex;
                            justify-content: space-between;
                            margin-bottom: 8px;
                            font-size: 12px;
                            color: #000 !important;
                        }
                        .summary-row strong { font-weight: bold; color: #000 !important; }
                        .footer {
                            margin-top: 30px;
                            text-align: center;
                            font-size: 9px;
                            color: #666 !important;
                            padding-top: 10px;
                            border-top: 1px solid #ddd !important;
                        }
                    </style>
                </head>
                <body>
                    <div class="header">
                        <h1>ZENFOO - PRE ORDERS</h1>
                        <h2>${storeName}</h2>
                        <p>Order-wise Items Breakdown | Generated on ${moment().format('D MMM YYYY, h:mm A')}</p>
                    </div>
                    ${ordersHTML}
                    <div class="summary-box">
                        <div class="summary-row">
                            <span>Total Orders (${storeName}):</span>
                            <strong>${totalOrders}</strong>
                        </div>
                        <div class="summary-row">
                            <span>Total Items:</span>
                            <strong>${orders.reduce((sum, order) => sum + (order.items?.length || 0), 0)}</strong>
                        </div>
                        <div class="summary-row">
                            <span>Total Amount:</span>
                            <strong>₹${parseFloat(totalAmount).toFixed(2)}</strong>
                        </div>
                        <div class="summary-row">
                            <span>Average Order Value:</span>
                            <strong>₹${totalOrders > 0 ? (totalAmount / totalOrders).toFixed(2) : '0.00'}</strong>
                        </div>
                    </div>
                    <div class="footer">
                        <p><strong>Thank you for your business!</strong></p>
                        <p>This is a computer-generated document. No signature is required.</p>
                        <p>&copy; ${new Date().getFullYear()} Zenfoo. All rights reserved.</p>
                    </div>
                </body>
                </html>
            `;
        },

        async printStoreInvoice(storeId, storeName, filters = {}) {
            this.$toast.info(`Fetching orders for ${storeName}...`);

            try {
                const params = {
                    store_id: storeId,
                    per_page: 1000,
                    ...filters
                };

                const response = await axios.get(this.$apiUrl + '/admin/preorders', { params });

                if (response.data.status === 1 && response.data.data.orders.length > 0) {
                    const storeOrders = response.data.data.orders;
                    this.$toast.info(`Printing ${storeOrders.length} thermal invoices from ${storeName}...`);

                    for (let i = 0; i < storeOrders.length; i++) {
                        await this.printThermalInvoice(storeOrders[i].id);
                        await new Promise(resolve => setTimeout(resolve, 1000));
                    }

                    this.$toast.success(`All invoices from ${storeName} sent to printer`);
                } else {
                    this.$toast.warning(`No orders found for ${storeName}`);
                }
            } catch (error) {
                console.error('Store invoice print error:', error);
                this.$toast.error('Failed to print store invoices');
            }
        }
    }
};