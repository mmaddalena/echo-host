<script setup>
import ChatMessage from "./ChatMessage.vue";
import { computed, watch, ref, nextTick, onMounted } from "vue";
import { formatDayLabel } from "@/utils/formatChatTime";

const props = defineProps({
	messages: {
		type: Array,
		required: true,
	},
	chatType: String,
	unreadMessages: Number,
});
const orderedMessages = computed(() => {
	return [...props.messages].sort((a, b) => {
		const tA = new Date(a.time ?? 0);
		const tB = new Date(b.time ?? 0);
		return tA - tB;
	});
});

watch(orderedMessages, (val) => {
	console.log(val);
});

const enhancedMessages = computed(() => {
	let lastUserId = null;

	return orderedMessages.value.map((message) => {
		const currentUserId = message.user_id;
		const isFirst = currentUserId !== lastUserId;
		lastUserId = currentUserId;

		return {
			...message,
			isFirst,
		};
	});
});

const messagesWithDays = computed(() => {
	let lastDay = null;
	const result = [];

	enhancedMessages.value.forEach((message) => {
		const dayKey = new Date(message.time).toDateString();

		if (dayKey !== lastDay) {
			result.push({
				front_msg_id: `day-${dayKey}`,
				kind: "day",
				label: formatDayLabel(message.time),
			});
			lastDay = dayKey;
		}

		result.push({
			...message,
			kind: "message",
		});
	});

	return result;
});

const messagesCompleteList = computed(() => {
  const base = [...messagesWithDays.value];

  if (!props.unreadMessages || props.unreadMessages <= 0) {
    return base;
  }

  let messageCountFromEnd = 0;
  let insertIndex = null;

  // recorrer desde el final
  for (let i = base.length - 1; i >= 0; i--) {
    if (base[i].kind === "message") {
      messageCountFromEnd++;

      if (messageCountFromEnd === props.unreadMessages + 1) {
        insertIndex = i + 1;
        break;
      }
    }
  }

  // si no encontró posición (ej: todos son unread)
  if (insertIndex === null) {
    insertIndex = 0;
  }

  base.splice(insertIndex, 0, {
    front_msg_id: `unread-${props.unreadMessages}`,
    kind: "unread",
    label: (props.unreadMessages > 1)
		? `${props.unreadMessages} mensajes sin leer`
		: `${props.unreadMessages} mensaje sin leer`
  });

  return base;
});


const messagesContainer = ref(null);
const autoScrollEnabled = ref(true);

function scrollToBottom() {
	nextTick(() => {
		if (messagesContainer.value) {
			messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
		}
	});
}

async function scrollToMessage(messageId) {
	autoScrollEnabled.value = false;

	await nextTick();

	const el = messagesContainer.value?.querySelector(
		`[data-msg-id="${messageId}"]`,
	);

	if (el) {
		el.scrollIntoView({
			behavior: "smooth",
			block: "center",
		});

		// ✨ highlight
		el.classList.add("focused");
		setTimeout(() => el.classList.remove("focused"), 1500);
	}
}

/* Expose to parent */
defineExpose({ scrollToMessage });

// Scroll al final al montar
onMounted(() => {
	scrollToBottom();
});

// Scroll automático al agregar mensajes
watch(
	() => messagesCompleteList.value,
	async () => {
		await nextTick(); // espera que Vue actualice el DOM
		scrollToBottom();
	},
	{ deep: true },
);
</script>

<template>
	<div class="chat-messages" ref="messagesContainer">
		<template v-for="item in messagesCompleteList" :key="item.front_msg_id">
			<div v-if="item.kind === 'day'" class="day-separator">
				{{ item.label }}
			</div>

			<div v-else-if="item.kind === 'unread'" class="unread-wrapper">
				<div class="unread-separator">
					{{ item.label }}
				</div>
			</div>

			<div v-else>
				<ChatMessage 
					:message="item" 
					:chatType="chatType"
					:data-msg-id="item.id"
					/>
			</div>
		</template>
	</div>
</template>

<style scoped>
.chat-messages {
	display: flex;
	flex-direction: column;
	gap: 0.2rem;
	flex: 1;
	padding: 2rem;
	overflow-y: auto;
	background-color: var(--bg-chat);
}
.day-separator {
	align-self: center;
	margin: 1rem 0;

	padding: 0.4rem 1rem;
	border-radius: 999px;

	font-size: 1.2rem;
	opacity: 0.7;
	background: var(--day-label);
	color: var(--text-muted);
}
.unread-wrapper {
	align-self: center;
  width: 80%;
  display: flex;
  justify-content: center;
  background: var(--bg-main); /* nuevo color de fondo */
  padding: 0.4rem 0;
	margin: 0.8rem 0;
	border-radius: 999px;
}
.unread-separator {
  padding: 0.4rem 1rem;
  border-radius: 999px;
  font-size: 1.2rem;
  background: var(--day-label); /* la pill como estaba */
  color: var(--text-muted);
}


.chat-messages::-webkit-scrollbar {
  width: 1rem;
}

.chat-messages::-webkit-scrollbar-track {
  background: transparent; /* rail invisible */
}

.chat-messages::-webkit-scrollbar-thumb {
  background: var(--scroll-bar);
  border-radius: 999px;
}

.chat-messages::-webkit-scrollbar-thumb:hover {
  background: var(--scroll-bar-hover);
}

.chat-messages::-webkit-scrollbar-button {
  display: none; /* saca las flechitas */
}

</style>
