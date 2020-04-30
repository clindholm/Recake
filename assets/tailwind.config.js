module.exports = {
  theme: {
    extend: {},
  },
  variants: {
    borderColor: ['responsive', 'hover', 'focus', 'group-hover'],
    display: ['responsive', 'group-hover']
  },
  plugins: [
    require('@tailwindcss/custom-forms')
  ],
}
