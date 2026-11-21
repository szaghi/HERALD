// HERALD docs theme: VitePress default theme + the Sumi family tokens in the Gin-getsu ink (custom.css), and the
// identity's icons in the pages: <HeraldIcon> registered globally, and a page whose frontmatter names an `icon:`
// shows that icon above its title (the doc-before slot).
import DefaultTheme from 'vitepress/theme'
import { h } from 'vue'
import { useData } from 'vitepress'
import HeraldIcon from './HeraldIcon.vue'
import './custom.css'

const Layout = {
  setup() {
    const { frontmatter } = useData()
    return () => h(DefaultTheme.Layout, null, {
      'doc-before': () => frontmatter.value.icon
        ? h('div', { class: 'herald-page-icon' }, [h(HeraldIcon, { name: frontmatter.value.icon, size: 56 })])
        : null,
    })
  },
}

export default {
  extends: DefaultTheme,
  Layout,
  enhanceApp({ app }) {
    app.component('HeraldIcon', HeraldIcon)
  },
}
