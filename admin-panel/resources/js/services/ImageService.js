/**
 * Get the dimensions (width and height) of an image file
 * @param {File|Blob} file - The image file
 * @returns {Promise<{width: number, height: number}>}
 */
export function getImageDimensions(file) {
    return new Promise((resolve, reject) => {
        if (!file) {
            reject(new Error('No file provided'));
            return;
        }

        const img = new Image();
        const objectUrl = URL.createObjectURL(file);

        img.onload = function () {
            const dimensions = {
                width: this.width,
                height: this.height
            };
            URL.revokeObjectURL(objectUrl);
            resolve(dimensions);
        };

        img.onerror = function () {
            URL.revokeObjectURL(objectUrl);
            reject(new Error('Failed to load image'));
        };

        img.src = objectUrl;
    });
}

/**
 * Get the dimensions (width and height) of an image from URL
 * @param {string} url - The image URL
 * @returns {Promise<{width: number, height: number}>}
 */
export function getImageDimensionsFromUrl(url) {
    return new Promise((resolve, reject) => {
        if (!url) {
            reject(new Error('No URL provided'));
            return;
        }

        const img = new Image();

        img.onload = function () {
            resolve({
                width: this.width,
                height: this.height
            });
        };

        img.onerror = function () {
            reject(new Error('Failed to load image from URL'));
        };

        img.src = url;
    });
}

export default {
    getImageDimensions,
    getImageDimensionsFromUrl
};