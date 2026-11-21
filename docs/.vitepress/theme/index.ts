// HERALD docs theme: VitePress default theme + the Sumi family tokens in the Gin-getsu ink (custom.css), and the
// identity's icons in the pages: <HeraldIcon> registered globally, and a page whose frontmatter names an `icon:`
// shows that icon above its title (the doc-before slot). Wide Mermaid diagrams shrink to the column down to 0.75 of their
// size, and scroll past it (floorDiagrams).
import DefaultTheme from 'vitepress/theme'
import { h } from 'vue'
import { onContentUpdated, useData } from 'vitepress'
import HeraldIcon from './HeraldIcon.vue'
import './custom.css'

// Mermaid draws each diagram with width 100% and its natural width as max-width, so a wide one shrinks to the column
// and its labels with it. A floor on the shrink: min-width at MIN_SCALE of the natural width, past which the diagram
// keeps its size and its container scrolls (custom.css). The diagrams are rendered on the client after mount and again
// on a theme change, hence the observer.
const MIN_SCALE = 0.75

function floorDiagrams(root: ParentNode) {
  root.querySelectorAll<SVGSVGElement>('.mermaid svg').forEach((svg) => {
    const natural = svg.viewBox?.baseVal?.width
    if (natural) svg.style.minWidth = `${Math.round(MIN_SCALE * natural)}px`
  })
}

let diagramObserver: MutationObserver | undefined
function watchDiagrams() {
  if (typeof document === 'undefined' || diagramObserver) return
  floorDiagrams(document)
  diagramObserver = new MutationObserver((records) => {
    for (const r of records) r.addedNodes.forEach((n) => { if (n instanceof Element) floorDiagrams(n.parentElement ?? n) })
  })
  diagramObserver.observe(document.body, { childList: true, subtree: true })
}

const Layout = {
  setup() {
    const { frontmatter } = useData()
    onContentUpdated(watchDiagrams)
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
