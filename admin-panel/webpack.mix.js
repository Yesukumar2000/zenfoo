const mix = require('laravel-mix');
const webpack = require('webpack');

/*
 |--------------------------------------------------------------------------
 | Mix Asset Management
 |--------------------------------------------------------------------------
 |
 | Mix provides a clean, fluent API for defining some Webpack build steps
 | for your Laravel applications. By default, we are compiling the CSS
 | file for the application as well as bundling up all the JS files.
 |
 */

mix.js('resources/js/app.js', 'public/js').vue();
//.postCss('resources/css/app.css', 'public/css', []
//mix.sass('resources/sass/app.scss', 'public/css/app.css');
mix.sass('resources/sass/app.scss', 'public/css');

// Single self-contained bundle (no async route chunks) so the live site
// needs only ONE js file -- /public/js was wiped and the disk is tight.
mix.webpackConfig({
    plugins: [
        new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),
    ],
});

if (mix.inProduction()) {
    mix.version();
}
