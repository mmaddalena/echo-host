<script setup>
  import { useThemeStore } from "@/stores/theme"

  const themeStore = useThemeStore()
  themeStore.init()

</script>

<template>
  <router-view />
</template>

<style scoped>
.logo {
  height: 6em;
  padding: 1.5em;
  will-change: filter;
  transition: filter 300ms;
}
.logo:hover {
  filter: drop-shadow(0 0 2em #646cffaa);
}
</style>
