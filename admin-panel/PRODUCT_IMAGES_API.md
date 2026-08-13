# Product Images API Documentation

## Overview
This API provides product image URLs optimized for Flutter app's lazy loading and scrollable animations. No authentication required.

## Base URL
```
/api/product-images
```

---

## Endpoints

### 1. Get Product Images (Detailed)
**GET** `/api/product-images/`

Returns detailed product image data with multiple images per product (main, gallery, variants).

#### Request Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 100 | Number of products to fetch (max: 100) |
| `offset` | integer | No | 0 | Number of products to skip (for pagination) |
| `product_id` | integer | No | - | Fetch images for specific product ID |
| `status` | integer | No | 1 | Product status (0=inactive, 1=active) |

#### Example Requests

```bash
# Get first 100 products with images
GET /api/product-images/

# Get next 100 products (pagination)
GET /api/product-images/?limit=100&offset=100

# Get 50 products
GET /api/product-images/?limit=50&offset=0

# Get images for specific product
GET /api/product-images/?product_id=131
```

#### Response Format

```json
{
  "status": 1,
  "message": "Product images fetched successfully",
  "data": [
    {
      "product_id": 131,
      "product_name": "Tropicana Orange Juice",
      "product_slug": "Tropicana-Orange-Juice",
      "images": [
        {
          "url": "https://yourdomain.com/storage/products/image1.jpg",
          "type": "main",
          "alt_text": "Tropicana Orange Juice"
        },
        {
          "url": "https://yourdomain.com/storage/products/image2.jpg",
          "type": "gallery",
          "alt_text": "Tropicana Orange Juice - Image 1"
        },
        {
          "url": "https://yourdomain.com/storage/products/image3.jpg",
          "type": "variant",
          "alt_text": "Tropicana Orange Juice - Variant"
        }
      ],
      "image_count": 3
    }
  ],
  "total": 230,
  "limit": 100,
  "offset": 0,
  "has_more": true
}
```

#### Response Fields

- `status`: API status (1 = success)
- `message`: Response message
- `data`: Array of product image objects
  - `product_id`: Product ID
  - `product_name`: Product name
  - `product_slug`: Product URL slug
  - `images`: Array of image objects
    - `url`: Full image URL
    - `type`: Image type (`main`, `gallery`, `variant`)
    - `alt_text`: Image alt text for accessibility
  - `image_count`: Total number of images for this product
- `total`: Total number of products with images
- `limit`: Items per page
- `offset`: Current offset
- `has_more`: Boolean indicating if more items exist

---

### 2. Get Flat Image URLs (Simplified)
**GET** `/api/product-images/flat`

Returns a simple flat array of product image URLs (main images only).

#### Request Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | integer | No | 100 | Number of products to fetch (max: 100) |
| `offset` | integer | No | 0 | Number of products to skip |

#### Example Requests

```bash
# Get first 100 product images
GET /api/product-images/flat

# Get next 100 images
GET /api/product-images/flat?limit=100&offset=100
```

#### Response Format

```json
{
  "status": 1,
  "message": "Image URLs fetched successfully",
  "data": [
    {
      "product_id": 131,
      "url": "https://yourdomain.com/storage/products/image1.jpg",
      "name": "Tropicana Orange Juice"
    },
    {
      "product_id": 132,
      "url": "https://yourdomain.com/storage/products/image2.jpg",
      "name": "Fresh Tomato Local"
    }
  ],
  "count": 100
}
```

---

## Flutter Implementation Example

### Using Detailed Endpoint

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductImagesService {
  final String baseUrl = 'https://yourdomain.com/api';

  Future<Map<String, dynamic>> fetchProductImages({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/product-images/?limit=$limit&offset=$offset'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load product images');
    }
  }
}
```

### ListView with Lazy Loading

```dart
class ProductImagesScreen extends StatefulWidget {
  @override
  _ProductImagesScreenState createState() => _ProductImagesScreenState();
}

class _ProductImagesScreenState extends State<ProductImagesScreen> {
  final ProductImagesService _service = ProductImagesService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _products = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMoreImages();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoading && _hasMore) {
        _loadMoreImages();
      }
    }
  }

  Future<void> _loadMoreImages() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _service.fetchProductImages(
        limit: 20,
        offset: _offset,
      );

      setState(() {
        _products.addAll(response['data']);
        _offset += 20;
        _hasMore = response['has_more'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product Images')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _products.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _products.length) {
            return Center(child: CircularProgressIndicator());
          }

          final product = _products[index];
          final images = product['images'] as List;

          return Card(
            child: Column(
              children: [
                Text(product['product_name']),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, imgIndex) {
                      return Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Image.network(
                          images[imgIndex]['url'],
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.error);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### Using cached_network_image for Better Performance

Add dependency to `pubspec.yaml`:
```yaml
dependencies:
  cached_network_image: ^3.3.0
```

```dart
import 'package:cached_network_image/cached_network_image.dart';

// In your widget
CachedNetworkImage(
  imageUrl: images[imgIndex]['url'],
  width: 200,
  fit: BoxFit.cover,
  placeholder: (context, url) => Center(
    child: CircularProgressIndicator(),
  ),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## Performance Recommendations

1. **Pagination**: Use limit=20-50 for smooth scrolling experience
2. **Caching**: Use `cached_network_image` package for image caching
3. **Preloading**: Load next batch when user reaches 80-90% of current list
4. **Image optimization**: Consider using thumbnails for list view
5. **Error handling**: Always provide fallback UI for failed image loads

---

## Error Responses

### No Images Found
```json
{
  "status": 0,
  "message": "No products with images found."
}
```

### Validation Error
```json
{
  "status": 0,
  "message": "The limit must be between 1 and 100."
}
```

---

## Notes

- All images are returned with full URLs (no need to concatenate base URL)
- Only active products with valid images are returned
- Images are ordered by product ID (most recent first)
- No authentication required (public API)
- Maximum limit per request: 100 products
