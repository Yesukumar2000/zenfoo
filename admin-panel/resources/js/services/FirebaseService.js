import { initializeApp, getApps } from 'firebase/app';
import { getFirestore, collection, doc, onSnapshot, query, orderBy } from 'firebase/firestore';
import axios from 'axios';

let firebaseApp = null;
let firestoreDb = null;
let firebaseConfig = null;

/**
 * Fetch Firebase config from the API
 */
async function fetchFirebaseConfig() {
    if (firebaseConfig) {
        return firebaseConfig;
    }

    try {
        const apiUrl = window.apiUrl || '/api';
        const response = await axios.get(`${apiUrl}/firebase`);

        if (response.data.data) {
            const config = {};
            response.data.data.forEach(item => {
                if (item.variable !== 'file_exists') {
                    config[item.variable] = item.value;
                }
            });
            firebaseConfig = config;
            return firebaseConfig;
        }
    } catch (error) {
        console.error('Failed to fetch Firebase config:', error);
        throw error;
    }
}

/**
 * Initialize Firebase app
 */
async function initializeFirebase() {
    if (firebaseApp) {
        return firebaseApp;
    }

    // Check if already initialized
    if (getApps().length > 0) {
        firebaseApp = getApps()[0];
        firestoreDb = getFirestore(firebaseApp);
        return firebaseApp;
    }

    const config = await fetchFirebaseConfig();

    firebaseApp = initializeApp({
        apiKey: config.apiKey,
        authDomain: config.authDomain,
        projectId: config.projectId,
        storageBucket: config.storageBucket,
        messagingSenderId: config.messagingSenderId,
        appId: config.appId,
        measurementId: config.measurementId
    });

    firestoreDb = getFirestore(firebaseApp);
    return firebaseApp;
}

/**
 * Get Firestore instance
 */
async function getFirestoreDb() {
    if (!firestoreDb) {
        await initializeFirebase();
    }
    return firestoreDb;
}

/**
 * Subscribe to seller chat messages (real-time)
 * @param {string|number} sellerId - The seller ID
 * @param {function} callback - Callback function that receives messages array
 * @returns {function} Unsubscribe function
 */
async function subscribeToSellerChatMessages(sellerId, callback) {
    const db = await getFirestoreDb();

    const messagesRef = collection(db, 'admin_seller_chatting', String(sellerId), 'messages');
    const messagesQuery = query(messagesRef, orderBy('time', 'asc'));

    const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
        const messages = [];
        snapshot.forEach((doc) => {
            messages.push({
                id: doc.id,
                ...doc.data()
            });
        });
        callback(messages);
    }, (error) => {
        console.error('Error listening to seller chat messages:', error);
        callback([], error);
    });

    return unsubscribe;
}

/**
 * Subscribe to delivery boy chat messages (real-time)
 * @param {string|number} deliveryBoyId - The delivery boy ID
 * @param {function} callback - Callback function that receives messages array
 * @returns {function} Unsubscribe function
 */
async function subscribeToDeliveryBoyChatMessages(deliveryBoyId, callback) {
    const db = await getFirestoreDb();

    const messagesRef = collection(db, 'admin_delivery_boy_chatting', String(deliveryBoyId), 'messages');
    const messagesQuery = query(messagesRef, orderBy('time', 'asc'));

    const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
        const messages = [];
        snapshot.forEach((doc) => {
            messages.push({
                id: doc.id,
                ...doc.data()
            });
        });
        callback(messages);
    }, (error) => {
        console.error('Error listening to delivery boy chat messages:', error);
        callback([], error);
    });

    return unsubscribe;
}

/**
 * Subscribe to customer chat messages (real-time)
 * @param {string|number} customerId - The customer ID
 * @param {function} callback - Callback function that receives messages array
 * @returns {function} Unsubscribe function
 */
async function subscribeToCustomerChatMessages(customerId, callback) {
    const db = await getFirestoreDb();

    const messagesRef = collection(db, 'admin_customer_chatting', String(customerId), 'messages');
    const messagesQuery = query(messagesRef, orderBy('time', 'asc'));

    const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
        const messages = [];
        snapshot.forEach((doc) => {
            messages.push({
                id: doc.id,
                ...doc.data()
            });
        });
        callback(messages);
    }, (error) => {
        console.error('Error listening to customer chat messages:', error);
        callback([], error);
    });

    return unsubscribe;
}

/**
 * Subscribe to order chat messages (real-time)
 * Collection: order_chats/{order_id}/{chat_type}
 * chat_type can be: customer, driver, seller_{seller_id}
 * @param {string|number} orderId - The order ID
 * @param {string} chatType - The chat type (customer, driver, seller_*)
 * @param {function} callback - Callback function that receives messages array
 * @returns {function} Unsubscribe function
 */
async function subscribeToOrderChatMessages(orderId, chatType, callback) {
    const db = await getFirestoreDb();

    const messagesRef = collection(db, 'order_chats', String(orderId), chatType);
    const messagesQuery = query(messagesRef, orderBy('timestamp', 'asc'));

    const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
        const messages = [];
        snapshot.forEach((doc) => {
            messages.push({
                id: doc.id,
                ...doc.data()
            });
        });
        callback(messages);
    }, (error) => {
        console.error('Error listening to order chat messages:', error);
        callback([], error);
    });

    return unsubscribe;
}

export {
    initializeFirebase,
    getFirestoreDb,
    subscribeToSellerChatMessages,
    subscribeToDeliveryBoyChatMessages,
    subscribeToCustomerChatMessages,
    subscribeToOrderChatMessages
};
