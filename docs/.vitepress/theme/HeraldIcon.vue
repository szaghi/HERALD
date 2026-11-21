<!-- docs/.vitepress/theme/HeraldIcon.vue: one icon of the identity (docs/public/icons/<name>.svg and <name>-dark.svg,
     Kari no tsukai in Gin-getsu), drawn in the theme of the page. Used inline in Markdown (<HeraldIcon name="peak" />,
     registered globally by index.ts; alone on a line before a paragraph with `float`, the paragraph wraps around it)
     and as the page icon (frontmatter `icon: <name>`, the doc-before slot). -->
<script setup lang="ts">
import { withBase } from 'vitepress'

const props = withDefaults(defineProps<{ name: string; size?: number; label?: string; float?: boolean }>(),
                           { size: 28, label: '', float: false })
</script>

<template>
  <span :class="['herald-icon', { 'herald-icon-float': props.float }]" :style="{ width: props.size + 'px', height: props.size + 'px' }"
        :role="props.label ? 'img' : undefined" :aria-label="props.label || undefined" :aria-hidden="props.label ? undefined : 'true'">
    <img class="herald-icon-light" :src="withBase(`/icons/${props.name}.svg`)" alt="" :width="props.size" :height="props.size" />
    <img class="herald-icon-dark" :src="withBase(`/icons/${props.name}-dark.svg`)" alt="" :width="props.size" :height="props.size" />
  </span>
</template>
