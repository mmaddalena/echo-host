<script setup>
  import { computed } from "vue";
  import { onMounted } from "vue";
  import { watch } from "vue"
  import { ref } from "vue";
  import { useRouter } from "vue-router";
  import { useRoute } from 'vue-router';
  import { useSocketStore } from "@/stores/socket";
  import { useUIStore } from "@/stores/ui"
  import { useThemeStore } from "@/stores/theme"

  import IconContacts from '../icons/IconContacts.vue';
  import IconPeople from '../icons/IconPeople.vue';
  import IconThemeMode from '../icons/IconThemeMode.vue';
  import IconSettings from '../icons/IconSettings.vue';
  import IconChats from '../icons/IconChats.vue';


  const router = useRouter();
  const route = useRoute();
  const socketStore = useSocketStore();
  const user = computed(() => socketStore.userInfo);


  const zoomedImage = ref(null);

  function openImage(src) {
    zoomedImage.value = src;
  }

  function closeImage() {
    zoomedImage.value = null;
  }

  const props = defineProps({
    avatarURL: String
  })

  const uiStore = useUIStore()
  const isChatsView = computed(() => route.name === 'chats')
  const showingPeople = computed(() => uiStore.leftPanel === 'people')

  function openPeople() {
    uiStore.showPeople()
    socketStore.requestContactsIfNeeded()
  }

  function openChats() {
    uiStore.showChats()
  }

  
  const themeStore = useThemeStore()
  const theme = computed(() => themeStore.theme)

  function setTheme(mode) {
    themeStore.setTheme(mode)
  }


  // Si vengo desde settings (u otra view), que se mande chats de primera
  watch(
    () => route.name,
    (name) => {
      if (name === 'chats') {
        uiStore.showChats()
      }
    }
  )
</script>

<template>
  <aside class="sidebar">
    <div class="profile-opts">
      <img class="profile content image clickable" :src="avatarURL" loading="lazy" @click="openImage(avatarURL)"></img>
      <button
        v-if="isChatsView && !showingPeople"  
        @click="openPeople"
      >
        <IconPeople class="icon outline"/>
      </button>
      <button
        v-else-if="isChatsView && showingPeople"  
        @click="openChats"
      >
        <IconChats class="icon" />
      </button>
    </div>
    <div class="config_opts">
      <Transition name="theme-toggle" mode="out-in">
      <button
        v-if="theme === 'dark'"
        key="dark"
        @click="setTheme('light')"
      >
        <IconThemeMode class="icon icon-light" variant="light" />
      </button>

      <button
        v-else
        key="light"
        @click="setTheme('dark')"
      >
        <IconThemeMode class="icon icon-dark" variant="dark" />
      </button>
    </Transition>



      <button 
        v-if="route.name === 'chats'"
        @click="router.push('/settings')"
      >
        <IconSettings class="icon" />
      </button>
      <button 
        v-else-if="route.name === 'settings'"
        @click="router.push('/chats')"
      >
        <IconChats class="icon" />
      </button>
    </div>
  </aside>

  <Teleport to="body">
		<Transition name="zoom">
			<div v-if="zoomedImage" class="image-overlay" @click.self="closeImage">
				<img :src="zoomedImage" class="zoomed-image" />
			</div>
		</Transition>
	</Teleport>
</template>

<style scoped>
.sidebar {
  width: 9rem;
  height: 100%;
  background: none;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  flex-shrink: 0;
  align-items: center;
  padding: 16px 0;
  gap: 20px;
}
button {
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
}
.profile-opts {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}
.profile {
  height: 5rem;
  width: 5rem;
  border-radius: 50%;
  background-color: none;
}
.config_opts {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}
.icon {
  height: 4rem;
  color: var(--text-main);
}
.icon-light {
  color: var(--main-app-color-1);
}
.icon-dark{
  color: var(--main-app-color-2);
}
.outline {
  stroke: var(--text-main);
  fill: none;
}

.clickable {
	cursor: zoom-in;
}

/* Overlay */
.image-overlay {
	position: fixed;
	inset: 0;
	background: rgba(0, 0, 0, 0.85);
	display: flex;
	align-items: center;
	justify-content: center;
	z-index: 9999;
	backdrop-filter: blur(4px);
}

/* Zoomed image */
.zoomed-image {
	max-width: 90vw;
	max-height: 90vh;
	border-radius: 1rem;
	object-fit: contain;
	cursor: zoom-out;
}

/* Animation */
.zoom-enter-active,
.zoom-leave-active {
	transition: opacity 0.25s ease;
}
.zoom-enter-from,
.zoom-leave-to {
	opacity: 0;
}


.theme-toggle-enter-active,
.theme-toggle-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.theme-toggle-enter-from {
  opacity: 0;
  transform: scale(0.8) rotate(-80deg);
}

.theme-toggle-leave-to {
  opacity: 0;
  transform: scale(0.8) rotate(80deg);
}

</style>
