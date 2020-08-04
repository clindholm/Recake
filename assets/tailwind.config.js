module.exports = {
  theme: {
    fontFamily: {
      'sans': ['Inter', 'sans-serif']
    },
    extend: {},
  },
  variants: {
    backgroundColor: ['responsive', 'hover', 'focus', 'focus-within'],
    borderColor: ['responsive', 'hover', 'focus', 'group-hover'],
    display: ['responsive', 'group-hover'],
    rotate: ['responsive', 'hover', 'focus', 'group-hover'],
  },
  plugins: [
    require('@tailwindcss/custom-forms')
  ],
}
