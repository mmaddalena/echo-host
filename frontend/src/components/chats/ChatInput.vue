<script setup>
import { ref } from "vue";

import IconSend from "../icons/IconSend.vue";
import IconMedia from "../icons/IconMedia.vue";

const emit = defineEmits(["send-message", "send-attachment"]);
const text = ref("");
const fileInput = ref(null);
const inputRef = ref(null);

function send() {
	if (!text.value.trim()) return;

	emit("send-message", text.value);
	text.value = "";
}

function pickFile() {
	fileInput.value.click();
}

async function onFileSelected(e) {
	const file = e.target.files[0];
	if (!file) return;

	emit("send-attachment", file);
	e.target.value = "";
}

function focusInput() {
	inputRef.value?.focus();
}
function clear() {
	text.value = ""
}
defineExpose({focusInput, clear});

</script>

<template>
	<div class="chat-input">
		<div class="main">
			<button @click="pickFile">
				<IconMedia class="icon"/>
			</button>

			<input
				ref="inputRef"
				v-model="text"
				placeholder="Escribe un mensaje..."
				@keydown.enter="send"
			/>
			<button @click="send">
				<IconSend class="icon"/>
			</button>

			<input
				ref="fileInput"
				type="file"
				hidden
				accept="image/*,application/pdf"
				@change="onFileSelected"
			/>
		</div>
	</div>
</template>

<style scoped>
.chat-input {
	height: fit-content;
	background-color: var(--bg-chat);
	padding: 0 2rem 2rem 2rem;
}
.main {
	height: fit-content;
	padding: 0rem 1rem;
	display: flex;
	justify-content: space-between;
	background: var(--bg-input);
	border-radius: 3rem;
	align-items: center;
}
input {
	flex: 1;
	height: 5rem;
	border: none;
	background: none;
	color: var(--text-main);
	outline: none;
	font-size: 1.5rem;
	margin-left: 1rem;
}
button {
	display: flex;
	align-items: center;
	justify-content: center;
	background-color: var(--msg-out);
	border: none;
	border-radius: 50%;
	width: 4rem;
	height: 4rem;
	color: white;
	cursor: pointer;
}
.icon {
	color: var(--text-main);
	max-height: 2.5rem;
	max-width: 2.5rem;
}
</style>
