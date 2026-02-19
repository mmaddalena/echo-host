import { defineStore } from "pinia"

export const useUIStore = defineStore("ui", {
  state: () => ({
    leftPanel: "chats",
    panelHistory: [],
  }),
  actions: {
    openPanel(panel) {
      if (this.leftPanel === panel) return

      this.panelHistory.push(this.leftPanel)
      this.leftPanel = panel
    },
    closePanel() {
      const previous = this.panelHistory.pop()
      this.leftPanel = previous ?? "chats"
    },
    showChats() {
      this.openPanel("chats")
    },
    showPeople() {
      this.openPanel("people")
    },
    showChatInfo() {
      this.openPanel("chat-info")
    },
    showPersonInfo() {
      this.openPanel("person-info")
    }
  },
})
