<script setup>
import ChatTabs from "./ChatTabs.vue";
import ChatList from "./ChatList.vue";
import ChatInfoPanel from "./ChatInfoPanel.vue";
// import ChatSearchBar from "./ChatSearchBar.vue";
import CreateGroupPanel from "../groups/CreateGroupPanel.vue";
import { useSocketStore } from "@/stores/socket";
import { storeToRefs } from "pinia";
import { ref, computed } from "vue";
import { onUnmounted } from "vue";
import { watch } from "vue";

const socketStore = useSocketStore();

const activeTab = ref("all");
const { chats } = storeToRefs(socketStore);

const contactSearchText = ref(null);

const filteredChats = computed(() => {
	if (activeTab.value === "groups") {
		return chats.value.filter((chat) => chat.type === "group");
	}
	return chats.value;
});

function handleChangeTab(newTab) {
	activeTab.value = newTab;
}

watch(
	() => activeTab.value,
	(tab) => {
		console.log(`La tab activa es: ${tab}`);
		socketStore.deletePeopleSearchResults();
		contactSearchText.value = null;
	},
);
watch(
	() => socketStore.contacts,
	(val) => {
		console.log(`CONTACTS EN STORE DESDE EL PANEL: ${val}`);
	},
);

function getPersonInfo(person_id) {
	socketStore.getPersonInfo(person_id);
}

function closePersonInfoPanel() {
	socketStore.deletePersonInfo();
	contactSearchText.value = null;
	socketStore.deletePeopleSearchResults();
}

onUnmounted(() => {
	closePersonInfoPanel();
});

function searchChat(input) {
	if (activeTab.value === "people") socketStore.searchPeople(input);
	else if (activeTab.value === "contacts") contactSearchText.value = input;
}

function handleOpenChat(chatId) {
	socketStore.openChat(chatId);
}

const rightPanel = ref("list");

function openCreateGroup() {
	socketStore.requestContactsIfNeeded(); // important
	rightPanel.value = "create-group";
}

function closeCreateGroup() {
	rightPanel.value = "list";
}
</script>

<template>
	<div class="panel">
		<ChatTabs
			v-if="rightPanel === 'list'"
			:activeTab="activeTab"
			@change-to-tab="handleChangeTab"
		/>

		<div
			class="chat-list-header"
			v-if="activeTab === 'groups' && rightPanel === 'list'"
		>
			<button class="create-group-btn" @click="openCreateGroup">
				Crear grupo
			</button>
		</div>

		<!-- MAIN CONTENT AREA -->
		<div class="panel-content">
			<ChatList
				v-if="rightPanel === 'list'"
				:chats="filteredChats"
				@open-chat="handleOpenChat"
			/>

			<CreateGroupPanel
				v-else-if="rightPanel === 'create-group'"
				@close="closeCreateGroup"
			/>
		</div>
	</div>
</template>

<style scoped>
.panel {
	min-width: 0;
	display: flex;
	flex: 1;
	flex-direction: column;

	height: 100%;
	min-height: 0;
}

.create-group-btn {
	padding: 6px 14px;
	border-radius: 20px;
	border: none;
	background-color: var(--main-app-color-2);
	color: white;
	font-weight: 500;
	cursor: pointer;
	margin: 1rem 2rem 0 auto
}

.chat-list-header {
	display: flex;
	justify-content: center;
	align-items: center;
	padding: 10px 10px 0px 10px;
	background: var(--bg-chatlist-panel);
}

.panel-content {
	flex: 1;
	min-height: 0;
	display: flex;
	flex-direction: column;

	overflow: hidden;
}
</style>
