<script setup>
import { computed } from "vue";
import ChatListItem from "./ChatListItem.vue";

const emit = defineEmits(["open-chat"]);

const props = defineProps({
	chats: {
		type: Array,
		required: true,
	},
});

function openChat(chatId) {
	emit("open-chat", chatId);
}

const orderedChats = computed(() => {
	return [...(props.chats ?? [])].sort((a, b) => {
		const tA = new Date(a.last_message?.time ?? 0);
		const tB = new Date(b.last_message?.time ?? 0);
		return tB - tA;
	});
});
</script>

<template>
	<TransitionGroup name="chat" tag="div" class="chat-list">
		<ChatListItem
			v-for="chat in orderedChats"
			:key="chat.id"
			:chat="chat"
			@open="openChat"
		/>
	</TransitionGroup>
</template>

<style scoped>
.chat-list {
	height: 100%;
	flex: 1;
	min-height: 0;
	background: var(--bg-chatlist-panel);
	overflow-y: scroll;
	padding: 1rem;
	scroll-padding-top: 2rem;
}
.chat-move {
	transition: transform 0.25s ease;
}


.chat-list::-webkit-scrollbar {
  width: 0.8rem;
}

.chat-list::-webkit-scrollbar-track {
  background: transparent; /* rail invisible */
}

.chat-list::-webkit-scrollbar-thumb {
  background: var(--scroll-bar);
  border-radius: 999px;
}

.chat-list::-webkit-scrollbar-thumb:hover {
  background: var(--scroll-bar-hover);
}

.chat-list::-webkit-scrollbar-button {
  display: none; /* saca las flechitas */
}

</style>
