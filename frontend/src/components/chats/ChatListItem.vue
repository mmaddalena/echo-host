<script setup>
import { computed, onMounted } from "vue";
import IconMessageState from "../icons/IconMessageState.vue";
import IconFile from "../icons/IconFile.vue";
import IconImage from "../icons/IconImage.vue";
import { formatChatTime } from "@/utils/formatChatTime";

const { chat } = defineProps({
	chat: Object,
});

const isMuted = computed(() => {
	const last = chat.last_message;
	if (!last) return false;

	return (
		last.type === "outgoing" ||
		(last.type === "incoming" && 	chat.unread_messages == 0)
	);
});

const emit = defineEmits(["open"]);

function handleClick() {
	emit("open", chat.id);
}

onMounted(() => {
	console.log(`ID del chat con ${chat.name}: ${chat.id}`)
});
</script>

<template>
	<div class="chat-item" @click="handleClick">
		<img class="avatar" :src="chat.avatar_url" alt="Avatar" />
		<div class="info">
			<div class="up">
				<div class="texto">
					<p class="name">{{ chat.name }}</p>
					<p class="status">{{ chat.status }}</p>
				</div>
				<div v-if="chat.unread_messages != 0" class="unread-messages">
					{{ chat.unread_messages }}
				</div>
			</div>
			<div class="down">
				<div class="last-message">
					<Transition name="msg-state" mode="out-in">
						<IconMessageState
							v-if="chat.last_message?.type === 'outgoing'"
							:key="chat.last_message?.state"
							class="icon"
							:state="chat.last_message.state"
						/>
					</Transition>

					<span v-if="chat.last_message?.format === 'image'" class="media-span">
						<IconImage class="icon-media" :class="{ muted: isMuted }" />
						<p class="text" :class="{ muted: isMuted }">Imagen</p>
					</span>
					<span
						v-else-if="chat.last_message?.format === 'file'"
						class="media-span"
					>
						<IconFile class="icon-media" :class="{ muted: isMuted }" />
						<p class="text" :class="{ muted: isMuted }">Archivo</p>
					</span>
					<span v-else>
						<p class="text" :class="{ muted: isMuted }">
							{{ chat.last_message?.content }}
						</p>
					</span>
				</div>
				<span class="time" :class="{ muted: isMuted }">
					{{ formatChatTime(chat.last_message?.time) }}
				</span>
			</div>
		</div>
	</div>
</template>

<style scoped>
.chat-item {
	display: flex;
	gap: 12px;
	padding: 12px;
	cursor: pointer;
}
.chat-item:hover {
	background: var(--bg-chatlist-hover);
	border-radius: 1.5rem;
}
.avatar {
	height: 5rem;
	width: 5rem;
	background-color: none;
	border-radius: 50%;
}
.info {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-width: 0;
}
.up {
	display: flex;
	flex-direction: row;
	justify-content: space-between;
	align-items: center;
	flex: 1;
}
.texto {
	margin-right: 1.5rem;
	display: flex;
	align-items: flex-end;
	line-height: 1;
}
.name {
	color: var(--text-main);
	font-weight: 600;
	margin-right: 1.5rem;
}
.status {
	font-size: 1.4rem;
	color: var(--text-muted);
}
.last-message .text {
	font-size: 1.4rem;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
	flex: 1;
	min-width: 0;
	color: var(--text-main);
}
.unread-messages {
	height: 2.4rem;
	width: 2.4rem;
	border-radius: 50%;
	display: flex;
	justify-content: center;
	align-items: center;
	background-color: var(--msg-out);
	color: var(--text-main);
}

.down {
	display: flex;
	justify-content: space-between;
}
.last-message {
	display: flex;
	margin-right: 1.5rem;
	overflow: hidden;
	flex: 1;
	min-width: 0;
}
.icon {
	height: 2.2rem;
	margin-right: 0.5rem;
	color: var(--main-app-color-2);
}
.time {
	font-size: 1.2rem;
	color: var(--text-main);
}

.msg-state-enter-active,
.msg-state-leave-active {
	transition:
		opacity 0.25s ease,
		transform 0.25s ease;
}

.msg-state-enter-from,
.msg-state-leave-to {
	opacity: 0;
	transform: scale(0.85);
}

.icon-media {
	height: 1.8rem;
	margin: 0 0 0 0.2rem;
	color: var(--text-main);
}
.media-span {
	display: flex;
	gap: 0.5rem;
}

.muted {
	color: var(--text-muted) !important;
}
</style>
