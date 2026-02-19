import { defineStore } from "pinia"
import { ref } from "vue"

export const useThemeStore = defineStore("theme", () => {
  const theme = ref("dark")

  function init() {
    theme.value = localStorage.getItem("theme") || "dark"
    document.documentElement.setAttribute("data-theme", theme.value)
  }

  function setTheme(mode) {
    theme.value = mode
    document.documentElement.setAttribute("data-theme", mode)
    localStorage.setItem("theme", mode)
  }

  function toggle() {
    setTheme(theme.value === "dark" ? "light" : "dark")
  }

  return { 
    theme, 
    setTheme, 
    toggle, 
    init 
  }
})
