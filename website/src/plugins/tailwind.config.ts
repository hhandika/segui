module.exports = function tailwindPlugin(_context: any, _options: any) {
    return {
        name: "tailwind-plugin",
        configurePostCss(postcssOptions: any) {
            postcssOptions.plugins.push(require("@tailwindcss/postcss"));
            return postcssOptions;
        },
    };
};
