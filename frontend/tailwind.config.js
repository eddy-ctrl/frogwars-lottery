module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        customFont: ['"Pixelify Sans"', "sans-serif"],
        // Add more custom font families as needed
      },
    },
  },
  plugins: [],
}