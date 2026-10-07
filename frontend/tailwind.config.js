/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'ui-sans-serif', 'system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
      },
      colors: {
        brand: {
          50: '#eff5ff',
          100: '#dbe8ff',
          200: '#bcd3ff',
          300: '#8fb3ff',
          400: '#5b8cf7',
          500: '#3a6df0',
          600: '#2757d6',
          700: '#2045ad',
          800: '#1e3a8a',
        },
        accent: {
          400: '#fbbf24',
          500: '#f59e0b',
          600: '#d97706',
        },
        ink: {
          700: '#1e293b',
          800: '#152033',
          900: '#0e1626',
          950: '#080d18',
        },
      },
      boxShadow: {
        soft: '0 1px 2px rgba(10,16,32,.04), 0 10px 28px -14px rgba(10,16,32,.14)',
        lift: '0 2px 4px rgba(10,16,32,.05), 0 18px 40px -16px rgba(10,16,32,.28)',
        glow: '0 10px 26px -8px rgba(58,109,240,.6)',
      },
      keyframes: {
        'gauge-sweep': {
          '0%': { transform: 'rotate(135deg)' },
          '55%': { transform: 'rotate(392deg)' },
          '100%': { transform: 'rotate(192deg)' },
        },
        'fade-up': {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'fade-in': {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        'scale-in': {
          '0%': { opacity: '0', transform: 'scale(0.95) translateY(6px)' },
          '100%': { opacity: '1', transform: 'scale(1) translateY(0)' },
        },
        'drop-in': {
          '0%': { opacity: '0', transform: 'translateY(-6px) scale(0.98)' },
          '100%': { opacity: '1', transform: 'translateY(0) scale(1)' },
        },
        'slide-down': {
          '0%': { opacity: '0', transform: 'translateY(-8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'pop': {
          '0%': { transform: 'scale(0.6)', opacity: '0' },
          '60%': { transform: 'scale(1.12)', opacity: '1' },
          '100%': { transform: 'scale(1)' },
        },
        'bar-grow': {
          '0%': { transform: 'scaleX(0)' },
          '100%': { transform: 'scaleX(1)' },
        },
        'float': {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-6px)' },
        },
      },
      animation: {
        'fade-up': 'fade-up .45s cubic-bezier(.22,.8,.3,1) both',
        'fade-in': 'fade-in .3s ease-out both',
        'scale-in': 'scale-in .22s cubic-bezier(.22,.8,.3,1) both',
        'drop-in': 'drop-in .16s ease-out both',
        'slide-down': 'slide-down .25s ease-out both',
        'pop': 'pop .35s cubic-bezier(.34,1.56,.64,1) both',
        'float': 'float 4s ease-in-out infinite',
        'gauge': 'gauge-sweep 2.8s cubic-bezier(.25,.8,.25,1) .35s both',
      },
    },
  },
  plugins: [],
};
