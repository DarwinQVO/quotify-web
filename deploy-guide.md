# 🚀 Deploy Quotify - Hosting Real

## Opción 1: Vercel (Gratis + Fácil)

### Paso 1: Preparar para Vercel
```bash
# En tu proyecto
npm run build
```

### Paso 2: Deploy en Vercel
```bash
# Instalar Vercel CLI
npm i -g vercel

# Deploy (primera vez)
vercel

# Deploys futuros
vercel --prod
```

### Resultado:
- ✅ Tu app en: `https://quotify-tu-usuario.vercel.app`
- ✅ Users instalan desde esa URL
- ✅ Auto-actualizaciones cuando haces push
- ✅ Gratis para siempre

---

## Opción 2: Netlify (También Gratis)

### Drag & Drop Deploy:
1. `npm run build`
2. Ir a netlify.com
3. Arrastar carpeta `dist` 
4. ¡Listo!

### Resultado:
- ✅ URL como: `https://quotify-abc123.netlify.app`
- ✅ Users instalan desde ahí
- ✅ Auto-updates con Git

---

## Opción 3: GitHub Pages (Gratis)

### Setup:
```bash
# Instalar gh-pages
npm install --save-dev gh-pages

# Agregar script
"deploy": "npm run build && gh-pages -d dist"

# Deploy
npm run deploy
```

### Resultado:
- ✅ URL: `https://tu-usuario.github.io/quotify`
- ✅ Gratis con tu cuenta GitHub

---

## ¿Cuál Elegir?

| Opción | Facilidad | Costo | Auto-updates | Custom Domain |
|--------|-----------|-------|--------------|---------------|
| **Vercel** | 🟢 Muy fácil | 🟢 Gratis | 🟢 Sí | 🟢 Sí |
| **Netlify** | 🟢 Fácil | 🟢 Gratis | 🟢 Sí | 🟢 Sí |
| **GitHub Pages** | 🟡 Medio | 🟢 Gratis | 🟡 Con setup | 🟡 Con pro |

**Recomendación: Vercel** (más fácil para React)